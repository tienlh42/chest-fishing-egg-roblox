-- ModuleScript: ServerScriptService > Modules > Plots
-- Cấp plot cho người chơi, dựng máy ấp + máy câu trên plot theo dữ liệu, cập nhật bảng chữ mỗi giây.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local Models = require(ReplicatedStorage.Models)
local Data = require(script.Parent.Data)
local Remote = require(script.Parent.Remote)

local Plots = {}

local plotList = {} -- các Model plot theo thứ tự
local ownerOf = {} -- [plot] = player
local plotOf = {} -- [player] = plot
local labels = {} -- [plot] = { Incubators = {[i] = TextLabel}, Fishers = {[i] = TextLabel}, Eggs = {[i] = Model}, Machines = {[i] = Model} }
local MACHINE_SCALE = 0.7 -- máy câu asset cao ~6.6 stud, rộng 7.7: thu nhỏ cho 5 máy vừa hàng ở mép ao (xem HouseBuilder)
local callbacks = {} -- OnIncubator(player, slot), OnFisher(player, slot)
local map

-- ===== Tiện ích =====
local function find(plot, name)
	return plot:FindFirstChild(name, true)
end

-- Bỏ bảng chữ cũ gắn trên part (bảng của bệ để lại khi bệ đã có máy / máy ấp)
local function clearLabel(part)
	local old = part and part:FindFirstChild("SlotLabel")
	if old then
		old:Destroy()
	end
end

local function makeLabel(part, height)
	clearLabel(part)
	local gui = Instance.new("BillboardGui")
	gui.Name = "SlotLabel"
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
				clearLabel(pad) -- bệ đã mở máy ấp: bỏ chữ "Locked" cũ
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
					Models.PlaceOnGround(egg, point and point.WorldCFrame or padTop(pad) * CFrame.new(0, 3, 0))
					if egg:GetAttribute("Anim") == nil then
						CollectionService:AddTag(egg, "Wobble") -- trứng tạm: client làm lắc lư (trứng asset có animation Incubate riêng)
					end
					egg.Parent = dynamic
					lab.Eggs[i] = egg
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
				clearLabel(pad) -- bệ đã có máy: bỏ chữ "Empty slot" cũ
				local machine = Models.Anchor(Models.Get("AutoFisher_" .. (Config.AutoFisher.Tiers[i] or "Common")))
				machine:ScaleTo(MACHINE_SCALE)
				Models.PlaceOnGround(machine, padTop(pad)) -- ô máy đã xoay sẵn trong HouseBuilder: mặt trước (-Z) ra mặt nước
				machine:SetAttribute("Slots", 3) -- cả 3 cần đều mở
				machine.Parent = dynamic
				lab.Machines[i] = machine
				makePrompt(machine.PrimaryPart, "Collect", "Auto-Fisher", plot, function(player)
					callbacks.OnFisher(player, i)
				end)
				lab.Fishers[i] = makeLabel(machine.PrimaryPart, 6)
			else
				lab.Fishers[i] = makeLabel(pad, 3)
			end
		end
	end
end

-- DEV (chỉ trong Studio, Config.Dev.Enabled): nhà CHƯA CÓ CHỦ được bày đầy đồ để test đi "cướp":
-- đủ 5 máy câu (kho đầy) và 4 máy ấp, mỗi máy một trứng xịn đã nở xong. Chỉ để xem, không tương tác được.
local DEMO_EGGS = { "Gold", "Dragon", "Crystal", "Bubble" }
local function dressDemo(plot)
	if not (Config.Dev.Enabled and RunService:IsStudio()) then
		return
	end
	local old = plot:FindFirstChild("Dynamic")
	if old then
		old:Destroy()
	end
	local dynamic = Instance.new("Folder")
	dynamic.Name = "Dynamic"
	local profile = { IncubatorSlots = Config.Incubators.MaxSlots, Incubators = {}, AutoFishers = {} }
	for i = 1, Config.Incubators.MaxSlots do
		profile.Incubators[tostring(i)] = { Tier = DEMO_EGGS[(i - 1) % #DEMO_EGGS + 1], Start = os.time() - 100000 }
	end
	for i = 1, #Config.AutoFisher.Prices do
		profile.AutoFishers[tostring(i)] = { Last = os.time(), Stored = Config.AutoFisher.Capacity }
	end
	local lab = { Incubators = {}, Fishers = {}, Eggs = {}, Machines = {} }
	buildIncubators(plot, dynamic, profile, lab)
	buildFishers(plot, dynamic, profile, lab)
	for i, label in pairs(lab.Incubators) do
		label.Text = ("%s Egg\nReady!"):format(profile.Incubators[tostring(i)].Tier)
		Models.SetAnim(lab.Eggs[i], "Hatch")
	end
	for _, label in pairs(lab.Fishers) do
		label.Text = ("Auto-Fisher\n%d/%d chests"):format(Config.AutoFisher.Capacity, Config.AutoFisher.Capacity)
	end
	for _, machine in pairs(lab.Machines) do
		machine:SetAttribute("Fill", 3)
		Models.SetAnim(machine, "Full")
	end
	for _, d in ipairs(dynamic:GetDescendants()) do
		if d:IsA("ProximityPrompt") then
			d:Destroy() -- chưa có chủ nên không có nút [E]
		end
	end
	dynamic.Parent = plot
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

	local lab = { Incubators = {}, Fishers = {}, Eggs = {}, Machines = {} }
	buildIncubators(plot, dynamic, profile, lab)
	buildFishers(plot, dynamic, profile, lab)
	labels[plot] = lab
	dynamic.Parent = plot
	Plots.UpdateLabels(player)
end

-- Máy câu vừa được thu rương: phát animation Collect ~1.8 giây rồi để UpdateLabels đặt lại Work / Full
function Plots.PlayMachineCollect(player, slot)
	local plot = plotOf[player]
	local lab = plot and labels[plot]
	local machine = lab and lab.Machines[slot]
	if not machine then
		return
	end
	machine:SetAttribute("Collecting", true)
	machine:SetAttribute("Fill", 0)
	machine:SetAttribute("Anim", "Collect")
	task.delay(1.8, function()
		if machine.Parent then
			machine:SetAttribute("Collecting", nil)
		end
	end)
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
			Models.SetAnim(lab.Eggs[i], "Incubate")
		else
			label.Text = "Ready!\n[E] Claim pet"
			Models.SetAnim(lab.Eggs[i], "Hatch") -- nở xong: vỏ vỡ, ngôi sao chui ra chờ chủ nhận
		end
	end

	for i, label in pairs(lab.Fishers) do
		local entry = profile.AutoFishers[tostring(i)]
		if entry then
			local stored = Config.AutoFisherStored(entry, now)
			label.Text = ("Auto-Fisher\n%d/%d chests"):format(stored, Config.AutoFisher.Capacity)
			local machine = lab.Machines[i]
			if machine and not machine:GetAttribute("Collecting") then
				machine:SetAttribute("Fill", math.min(3, math.ceil(stored / Config.AutoFisher.Capacity * 3)))
				Models.SetAnim(machine, stored >= Config.AutoFisher.Capacity and "Full" or "Work")
			end
		else
			label.Text = "Empty slot\nBuy at Tool Shop"
		end
	end
end

-- Nút [E] cất đồ ở Stash của nhà. Tạo lúc cấp plot (để mang OwnerId), xoá lúc thu hồi.
local function addStashPrompt(plot)
	local stash = find(plot, "Stash")
	local part = stash and (stash:IsA("BasePart") and stash or stash.PrimaryPart or stash:FindFirstChildWhichIsA("BasePart", true))
	if part and callbacks.OnStash then
		local prompt = makePrompt(part, "Deposit", "Stash", plot, callbacks.OnStash)
		prompt.Name = "StashPrompt"
		prompt.MaxActivationDistance = 12
	end
end

local function removeStashPrompt(plot)
	local stash = find(plot, "Stash")
	local prompt = stash and stash:FindFirstChild("StashPrompt", true)
	if prompt then
		prompt:Destroy()
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
			addStashPrompt(plot)
			Plots.Refresh(player)
			if callbacks.OnAssign then
				callbacks.OnAssign(player, plot) -- đồ trong nhà (House.lua): ổ pet, móc balo, kệ trưng bày, hộp thư
			end
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
	if callbacks.OnRelease then
		callbacks.OnRelease(player, plot)
	end
	plotOf[player] = nil
	ownerOf[plot] = nil
	labels[plot] = nil
	plot:SetAttribute("OwnerId", nil)
	removeStashPrompt(plot)
	local dynamic = plot:FindFirstChild("Dynamic")
	if dynamic then
		dynamic:Destroy()
	end
	setSign(plot, "Empty Plot")
	dressDemo(plot) -- DEV: trả lại nhà đầy đồ cho người khác "cướp"
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

-- Dịch chuyển nhân vật tới cframe (dùng chung cho module Teleports)
Plots.Teleport = teleport

-- Nút [E] chỉ chủ plot dùng được (dùng chung cho House.lua)
function Plots.MakeOwnerPrompt(plot, part, actionText, objectText, onTrigger)
	return makePrompt(part, actionText, objectText, plot, onTrigger)
end

-- Model plot của người chơi, hoặc nil
function Plots.Get(player)
	return plotOf[player]
end

-- Part "Home" (thảm trước hiên) của nhà người chơi, hoặc nil
function Plots.HomePart(player)
	local plot = plotOf[player]
	return plot and find(plot, "Home")
end

function Plots.TeleportHome(player)
	local plot = plotOf[player]
	local home = plot and find(plot, "Home")
	if not home then
		return false, "You don't have a plot."
	end
	return teleport(player, home.CFrame * CFrame.new(0, 4, 0))
end

function Plots.Init(mapFolder, cb)
	map = mapFolder
	callbacks = cb
	for _, plot in ipairs(map:WaitForChild("Plots"):GetChildren()) do
		table.insert(plotList, plot)
		setSign(plot, "Empty Plot")
		dressDemo(plot)
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
