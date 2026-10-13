-- ModuleScript: ServerScriptService > Modules > Plots
-- Cấp plot cho người chơi, dựng máy ấp + máy câu trên plot theo dữ liệu, cập nhật bảng chữ mỗi giây.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local Models = require(ReplicatedStorage.Models)
local Data = require(script.Parent.Data)
local Remote = require(script.Parent.Remote)

local Plots = {}

local plotList = {} -- các Model plot theo thứ tự
local ownerOf = {} -- [plot] = player
local plotOf = {} -- [player] = plot
local labels = {} -- [plot] = { Incubators = {[i] = TextLabel}, Fishers = {[i] = TextLabel} }
local callbacks = {} -- OnIncubator(player, slot), OnFisher(player, slot)
local map

-- ===== Tiện ích =====
local function find(plot, name)
	return plot:FindFirstChild(name, true)
end

local function makeLabel(part, height)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(7, 2.2)
	gui.StudsOffset = Vector3.new(0, height, 0)
	gui.MaxDistance = 70
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Parent = gui
	gui.Parent = part
	return label
end

-- Nút [E] chỉ chủ plot dùng được (client tự ẩn nút của plot người khác)
local function makePrompt(part, actionText, objectText, plot, onTrigger)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 10
	prompt:SetAttribute("OwnerId", plot:GetAttribute("OwnerId"))
	prompt.Triggered:Connect(function(player)
		if ownerOf[plot] == player then
			onTrigger(player)
		end
	end)
	prompt.Parent = part
	return prompt
end

local function setSign(plot, text)
	local sign = find(plot, "Sign")
	if not sign then
		return
	end
	local gui = sign:FindFirstChild("OwnerLabel")
	if not gui then
		gui = Instance.new("BillboardGui")
		gui.Name = "OwnerLabel"
		gui.Size = UDim2.fromScale(16, 3)
		gui.StudsOffset = Vector3.new(0, 3, 0)
		gui.MaxDistance = 250
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Font = Enum.Font.GothamBlack
		label.TextColor3 = Color3.fromRGB(255, 230, 120)
		label.TextStrokeTransparency = 0
		label.Parent = gui
		gui.Parent = sign
	end
	gui.TextLabel.Text = text
end

local function formatTime(seconds)
	return ("%d:%02d"):format(seconds // 60, seconds % 60)
end

-- Mặt trên của bệ
local function padTop(pad)
	return pad.CFrame * CFrame.new(0, pad.Size.Y / 2, 0)
end

-- ===== Dựng đồ trên plot =====
local function buildIncubators(plot, dynamic, profile, lab)
	for i = 1, Config.Incubators.MaxSlots do
		local pad = find(plot, "IncubatorSlot" .. i)
		if pad then
			if i <= profile.IncubatorSlots then
				local incubator = Models.Anchor(Models.Get("Incubator"))
				incubator:PivotTo(padTop(pad))
				incubator.Parent = dynamic

				local entry = profile.Incubators[tostring(i)]
				if entry then
					local egg = Models.Anchor(Models.Get(entry.Tier .. " Egg"))
					local tag = egg:FindFirstChild("NameTag", true)
					if tag then
						tag:Destroy()
					end
					local point = incubator:FindFirstChild("EggPoint", true)
					egg:PivotTo(point and point.WorldCFrame or padTop(pad) * CFrame.new(0, 3, 0))
					CollectionService:AddTag(egg, "Wobble") -- client làm trứng lắc lư
					egg.Parent = dynamic
				end

				makePrompt(incubator.PrimaryPart, "Use", "Incubator", plot, function(player)
					callbacks.OnIncubator(player, i)
				end)
				lab.Incubators[i] = makeLabel(incubator.PrimaryPart, 6)
			else
				lab.Incubators[i] = makeLabel(pad, 3)
			end
		end
	end
end

local function buildFishers(plot, dynamic, profile, lab)
	for i = 1, #Config.AutoFisher.Prices do
		local pad = find(plot, "FisherSlot" .. i)
		if pad then
			if profile.AutoFishers[tostring(i)] then
				local machine = Models.Anchor(Models.Get("AutoFisher"))
				machine:PivotTo(padTop(pad))
				machine.Parent = dynamic
				makePrompt(machine.PrimaryPart, "Collect", "Auto-Fisher", plot, function(player)
					callbacks.OnFisher(player, i)
				end)
				lab.Fishers[i] = makeLabel(machine.PrimaryPart, 5)
			else
				lab.Fishers[i] = makeLabel(pad, 3)
			end
		end
	end
end

-- Dựng lại toàn bộ đồ động trên plot (gọi sau khi mua/ấp/nhận)
function Plots.Refresh(player)
	local plot = plotOf[player]
	local profile = Data.Get(player)
	if not (plot and profile) then
		return
	end
	local dynamic = plot:FindFirstChild("Dynamic")
	if dynamic then
		dynamic:Destroy()
	end
	dynamic = Instance.new("Folder")
	dynamic.Name = "Dynamic"

	local lab = { Incubators = {}, Fishers = {} }
	buildIncubators(plot, dynamic, profile, lab)
	buildFishers(plot, dynamic, profile, lab)
	labels[plot] = lab
	dynamic.Parent = plot
	Plots.UpdateLabels(player)
end

function Plots.UpdateLabels(player)
	local plot = plotOf[player]
	local profile = Data.Get(player)
	local lab = plot and labels[plot]
	if not (profile and lab) then
		return
	end
	local now = os.time()

	for i, label in pairs(lab.Incubators) do
		local entry = profile.Incubators[tostring(i)]
		local egg = entry and Config.Eggs[entry.Tier]
		if i > profile.IncubatorSlots then
			label.Text = "Locked\nBuy at Tool Shop"
		elseif not entry then
			label.Text = "Empty\n[E] Hatch an egg"
		elseif egg and entry.Start + egg.HatchTime > now then
			label.Text = ("%s Egg\n%s"):format(entry.Tier, formatTime(entry.Start + egg.HatchTime - now))
		else
			label.Text = "Ready!\n[E] Claim pet"
		end
	end

	for i, label in pairs(lab.Fishers) do
		local entry = profile.AutoFishers[tostring(i)]
		if entry then
			local stored = Config.AutoFisherStored(entry, now)
			label.Text = ("Auto-Fisher\n%d/%d chests"):format(stored, Config.AutoFisher.Capacity)
		else
			label.Text = "Empty slot\nBuy at Tool Shop"
		end
	end
end

-- ===== Cấp / thu hồi plot =====
function Plots.Assign(player)
	for _, plot in ipairs(plotList) do
		if not ownerOf[plot] then
			ownerOf[plot] = player
			plotOf[player] = plot
			plot:SetAttribute("OwnerId", player.UserId)
			setSign(plot, player.DisplayName .. "'s Plot")
			Plots.Refresh(player)
			return plot
		end
	end
	Remote.Notify(player, "No free plot on this server!")
	return nil
end

function Plots.Release(player)
	local plot = plotOf[player]
	if not plot then
		return
	end
	plotOf[player] = nil
	ownerOf[plot] = nil
	labels[plot] = nil
	plot:SetAttribute("OwnerId", nil)
	local dynamic = plot:FindFirstChild("Dynamic")
	if dynamic then
		dynamic:Destroy()
	end
	setSign(plot, "Empty Plot")
end

-- Vị trí thế giới của 1 bệ trên plot (dùng cho hiệu ứng)
function Plots.SlotPosition(player, slotName)
	local plot = plotOf[player]
	local pad = plot and find(plot, slotName)
	return pad and pad.Position + Vector3.new(0, 3, 0)
end

-- ===== Dịch chuyển =====
local function teleport(player, cframe)
	local character = player.Character
	if not (character and cframe and character:FindFirstChild("HumanoidRootPart")) then
		return false
	end
	character:PivotTo(cframe)
	return true
end

function Plots.TeleportHome(player)
	local plot = plotOf[player]
	local home = plot and find(plot, "Home")
	if not home then
		return false, "You don't have a plot."
	end
	return teleport(player, home.CFrame * CFrame.new(0, 4, 0))
end

function Plots.TeleportPlaza(player)
	local spawn = map:FindFirstChild("Spawn", true)
	return teleport(player, spawn and spawn.CFrame * CFrame.new(0, 4, 0))
end

function Plots.Init(mapFolder, cb)
	map = mapFolder
	callbacks = cb
	for _, plot in ipairs(map:WaitForChild("Plots"):GetChildren()) do
		table.insert(plotList, plot)
		setSign(plot, "Empty Plot")
	end
	table.sort(plotList, function(a, b)
		return (tonumber(a.Name:match("%d+")) or 0) < (tonumber(b.Name:match("%d+")) or 0)
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			for player in pairs(plotOf) do
				Plots.UpdateLabels(player)
			end
		end
	end)
end

return Plots
