-- ModuleScript: ServerScriptService > Modules > Plots
-- Cấp plot cho người chơi, dựng máy ấp + máy câu trên plot theo dữ liệu, cập nhật bảng chữ mỗi giây.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local Models = require(ReplicatedStorage.Models)
local Data = require(script.Parent.Data)
local IncubatorBuilder = require(script.Parent.IncubatorBuilder)
local Remote = require(script.Parent.Remote)
local SafeZone = require(script.Parent.SafeZone)

local Plots = {}

local plotList = {} -- các Model plot theo thứ tự
local ownerOf = {} -- [plot] = player
local plotOf = {} -- [player] = plot
local labels = {} -- [plot] = { Incubators = {[i] = TextLabel}, IncubatorModels = {[i] = Model máy ấp}, Fishers = {[i] = TextLabel}, Eggs = {[i] = Model}, Machines = {[i] = Model}, Bars = {[i] = Frame phần đầy của thanh độ bền máy} }
local EGG_SCALE = 0.75 -- trứng trong máy ấp thu nhỏ cho vừa vòm kính
local MACHINE_SCALE = 0.7 -- máy câu asset cao ~6.6 stud, rộng 7.7: thu nhỏ cho 5 máy vừa hàng ở mép ao (xem HouseBuilder)
local callbacks = {} -- OnIncubator(player, slot), OnFisher(player, slot), OnBuild(player, kind, slot): mua / nâng cấp đồ ở nhà
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

-- Thanh độ bền dưới bảng chữ của máy câu: thu bảng chữ lại, thanh nằm ở đáy. Trả về phần đầy của thanh (đổi Size / màu khi cập nhật)
local function addDurabilityBar(label)
	label.Size = UDim2.fromScale(1, 0.72)
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(0.8, 0.16)
	back.Position = UDim2.fromScale(0.1, 0.78)
	back.BackgroundColor3 = Color3.fromRGB(35, 28, 80)
	back.BorderSizePixel = 0
	back.Parent = label.Parent
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Config.DurabilityColor(1)
	fill.BorderSizePixel = 0
	fill.Parent = back
	for _, frame in ipairs({ back, fill }) do
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = frame
	end
	return fill
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

-- Nút mua / nâng cấp đồ ở NHÀ (máy ấp, ổ máy, máy câu, khóa cửa): gắn lên bệ / máy / biển, thay nút cũ cùng tên
-- (Refresh dựng lại nhiều lần). kind = nil thì chỉ xóa nút cũ. Bấm thì gọi callbacks.OnBuild(player, kind, slot)
local function setBuildPrompt(part, name, actionText, objectText, plot, key, kind, slot)
	local old = part:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	if not kind then
		return
	end
	local prompt = makePrompt(part, actionText, objectText, plot, function(player)
		if callbacks.OnBuild then
			callbacks.OnBuild(player, kind, slot)
		end
	end)
	prompt.Name = name
	if key then
		prompt.KeyboardKeyCode = key
	end
end

-- Nút [E] "Pick lock" cho người KHÁC chủ plot (cướp nhà). Client chỉ bật nút này với người không phải chủ (RobOwnerId)
local function makeRobPrompt(part, objectText, plot, target)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RobPrompt"
	prompt.ActionText = "Pick lock"
	prompt.ObjectText = objectText
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 10
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt:SetAttribute("RobOwnerId", plot:GetAttribute("OwnerId"))
	prompt.Triggered:Connect(function(player)
		local owner = ownerOf[plot]
		if owner and owner ~= player and callbacks.OnRob then
			callbacks.OnRob(player, owner, target)
		end
	end)
	prompt.Parent = part
	return prompt
end

-- Biển tên TO trên nóc nhà (Part "Sign", HouseBuilder.buildRoofSign): hiện tên chủ nhà + ảnh avatar (userId); không userId = "FOR RENT"
local function setSign(plot, text, userId)
	local sign = find(plot, "Sign")
	if not sign then
		return
	end
	for _, gui in ipairs(sign:GetChildren()) do
		local panel = gui:IsA("SurfaceGui") and gui:FindFirstChild("Panel")
		if panel then
			panel.NameLabel.Text = text
			panel.Avatar.Visible = userId ~= nil
			if userId then
				panel.Avatar.Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(userId)
			end
		end
	end
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
				local incubator = IncubatorBuilder.Make() -- máy ấp "Tổ Ấm" (hoạt ảnh: IncubatorAnimator.client.lua)
				incubator:PivotTo(padTop(pad))
				incubator.Parent = dynamic
				lab.IncubatorModels[i] = incubator

				local entry = profile.Incubators[tostring(i)]
				if entry then
					local egg = Models.Anchor(Models.Get(entry.Tier .. " Egg"))
					local tag = egg:FindFirstChild("NameTag", true)
					if tag then
						tag:Destroy()
					end
					egg:ScaleTo(egg:GetScale() * EGG_SCALE) -- trứng thu nhỏ cho vừa vòm kính
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
				setBuildPrompt(pad, "BuildPrompt") -- bệ đã mở: bỏ nút mở khóa cũ
			else
				lab.Incubators[i] = makeLabel(pad, 3)
				setBuildPrompt(pad, "BuildPrompt", "Unlock", "Incubator #" .. i, plot, nil, "Incubator", i)
			end
		end
	end
end

local function buildFishers(plot, dynamic, profile, lab)
	for i = 1, #Config.AutoFisher.PedestalPrices do
		local pad = find(plot, "FisherSlot" .. i)
		if pad then
			local entry = profile.AutoFishers[tostring(i)]
			if entry then
				clearLabel(pad) -- bệ đã có máy: bỏ chữ "Empty slot" cũ
				local tierName = Config.AutoFisher.Tiers[entry.Tier].Name
				local machine = Models.Anchor(Models.Get("AutoFisher_" .. tierName))
				machine:ScaleTo(MACHINE_SCALE)
				Models.PlaceOnGround(machine, padTop(pad)) -- ô máy đã xoay sẵn trong HouseBuilder: mặt trước (-Z) ra mặt nước
				machine:SetAttribute("Slots", 3) -- cả 3 cần đều mở
				machine.Parent = dynamic
				lab.Machines[i] = machine
				makePrompt(machine.PrimaryPart, "Collect", tierName .. " Auto-Fisher", plot, function(player)
					callbacks.OnFisher(player, i)
				end)
				makeRobPrompt(machine.PrimaryPart, tierName .. " Auto-Fisher", plot, "Fisher" .. i)
				setBuildPrompt(machine.PrimaryPart, "UpgradePrompt", "Upgrade", tierName .. " Auto-Fisher", plot, Enum.KeyCode.G, "Machine", i)
				setBuildPrompt(pad, "BuildPrompt")
				lab.Fishers[i] = makeLabel(machine.PrimaryPart, 6)
				lab.Bars[i] = addDurabilityBar(lab.Fishers[i])
			else
				lab.Fishers[i] = makeLabel(pad, 3)
				setBuildPrompt(pad, "BuildPrompt", i <= profile.FisherSlots and "Buy machine" or "Unlock", "Machine pedestal #" .. i, plot, nil, "Pedestal", i)
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
	local profile = { IncubatorSlots = Config.Incubators.MaxSlots, Incubators = {}, FisherSlots = #Config.AutoFisher.PedestalPrices, AutoFishers = {} }
	for i = 1, Config.Incubators.MaxSlots do
		profile.Incubators[tostring(i)] = { Tier = DEMO_EGGS[(i - 1) % #DEMO_EGGS + 1], Start = os.time() - 100000 }
	end
	for i, tier in ipairs(Config.AutoFisher.Tiers) do
		profile.AutoFishers[tostring(i)] = { Tier = i, Durability = tier.Durability, Last = os.time(), Stored = tier.Capacity }
	end
	local lab = { Incubators = {}, IncubatorModels = {}, Fishers = {}, Eggs = {}, Machines = {}, Bars = {} }
	buildIncubators(plot, dynamic, profile, lab)
	buildFishers(plot, dynamic, profile, lab)
	for i, label in pairs(lab.Incubators) do
		label.Text = ("%s Egg\nReady!"):format(profile.Incubators[tostring(i)].Tier)
		Models.SetAnim(lab.Eggs[i], "Incubate")
		lab.IncubatorModels[i]:SetAttribute("State", "Ready")
	end
	for i, label in pairs(lab.Fishers) do
		local tier = Config.AutoFisher.Tiers[i]
		label.Text = ("%s  %d/%d chests"):format(tier.Name, tier.Capacity, tier.Capacity)
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

	local lab = { Incubators = {}, IncubatorModels = {}, Fishers = {}, Eggs = {}, Machines = {}, Bars = {} }
	buildIncubators(plot, dynamic, profile, lab)
	buildFishers(plot, dynamic, profile, lab)
	labels[plot] = lab
	dynamic.Parent = plot
	Plots.UpdateLock(player)
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

-- Chồng rương trên giá của phòng rương: mỗi hạng 1 chỗ (VaultSlot1..5), tối đa 3 rương chồng + nhãn số lượng. Chỉ dựng lại khi kho đổi
local VAULT_CHEST_SCALE = 0.5
local function renderVault(plot, profile, lab)
	local parts = {}
	for i, chest in ipairs(Config.Chests) do
		table.insert(parts, i .. "=" .. (profile.Chests[chest.Name] or 0))
	end
	local key = table.concat(parts, ",")
	if lab.VaultKey == key then
		return
	end
	lab.VaultKey = key
	if lab.VaultFolder then
		lab.VaultFolder:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "VaultDisplay"
	for i, chest in ipairs(Config.Chests) do
		local slot = find(plot, "VaultSlot" .. i)
		local count = profile.Chests[chest.Name] or 0
		if slot and count > 0 then
			local top = slot.Position
			for k = 1, math.min(count, 3) do
				local model = Models.Anchor(Models.Get(chest.Name))
				model:ScaleTo(model:GetScale() * VAULT_CHEST_SCALE)
				Models.PlaceOnGround(model, CFrame.new(top + Vector3.new(0, 0.05, 0)) * slot.CFrame.Rotation)
				local _, size = model:GetBoundingBox()
				model:PivotTo(model:GetPivot() + Vector3.new(0, (k - 1) * size.Y * 0.92, 0))
				Models.SetAnim(model, "Idle")
				model.Parent = folder
			end
			local tag = Instance.new("Part")
			tag.Name = "CountTag"
			tag.Anchored = true
			tag.CanCollide = false
			tag.CanQuery = false
			tag.Transparency = 1
			tag.Size = Vector3.one
			tag.Position = top + Vector3.new(0, 3.4, 0)
			tag.Parent = folder
			local gui = Instance.new("BillboardGui")
			gui.Size = UDim2.fromOffset(60, 26)
			gui.MaxDistance = 60
			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.GothamBlack
			label.TextScaled = true
			label.Text = "x" .. count
			label.TextColor3 = Color3.fromRGB(255, 225, 120)
			label.TextStrokeTransparency = 0
			label.Parent = gui
			gui.Parent = tag
		end
	end
	folder.Parent = plot:FindFirstChild("Dynamic")
	lab.VaultFolder = folder
end

function Plots.UpdateLabels(player)
	local plot = plotOf[player]
	local profile = Data.Get(player)
	local lab = plot and labels[plot]
	if not (profile and lab) then
		return
	end
	local now = os.time()
	renderVault(plot, profile, lab)

	for i, label in pairs(lab.Incubators) do
		local entry = profile.Incubators[tostring(i)]
		local egg = entry and Config.Eggs[entry.Tier]
		local model = lab.IncubatorModels[i]
		if model and model:GetAttribute("State") == "Hatching" then
			label.Text = "" -- đang chạy hoạt ảnh nở: không đụng vào
		elseif i > profile.IncubatorSlots then
			label.Text = "Locked\n[E] Unlock"
		elseif not entry then
			label.Text = "Empty\n[E] Hatch an egg"
			if model then
				model:SetAttribute("State", "Empty")
			end
		elseif egg and entry.Start + egg.HatchTime > now then
			label.Text = ("%s Egg\n%s"):format(entry.Tier, formatTime(entry.Start + egg.HatchTime - now))
			local progress = math.clamp((now - entry.Start) / egg.HatchTime, 0, 1)
			Models.SetAnim(lab.Eggs[i], "Incubate")
			if lab.Eggs[i] then
				lab.Eggs[i]:SetAttribute("Progress", progress)
			end
			if model then
				model:SetAttribute("State", "Incubating")
				model:SetAttribute("Progress", progress)
			end
		else
			label.Text = "Ready!\n[E] Claim pet"
			Models.SetAnim(lab.Eggs[i], "Incubate") -- nở xong: trứng rung mạnh trong vòm nứt, chờ chủ nhận (nở thật ở Hatchery.OnPrompt)
			if lab.Eggs[i] then
				lab.Eggs[i]:SetAttribute("Progress", 1)
			end
			if model then
				model:SetAttribute("State", "Ready")
				model:SetAttribute("Progress", 1)
			end
		end
	end

	for i, label in pairs(lab.Fishers) do
		local entry = profile.AutoFishers[tostring(i)]
		if entry then
			local tier = Config.AutoFisher.Tiers[entry.Tier]
			local stored = Config.AutoFisherStored(entry, now)
			local limit = math.min(tier.Capacity, entry.Durability) -- máy sắp hỏng chỉ còn làm ra được bấy nhiêu rương
			label.Text = ("%s  %d/%d chests"):format(tier.Name, stored, tier.Capacity)
			local bar = lab.Bars[i]
			if bar then
				local ratio = entry.Durability / tier.Durability
				bar.Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1)
				bar.BackgroundColor3 = Config.DurabilityColor(ratio)
			end
			local machine = lab.Machines[i]
			if machine and not machine:GetAttribute("Collecting") then
				machine:SetAttribute("Fill", math.min(3, math.ceil(stored / limit * 3)))
				Models.SetAnim(machine, stored >= limit and "Full" or "Work")
			end
		elseif i <= profile.FisherSlots then
			label.Text = "Empty pedestal\n[E] Buy a machine"
		else
			label.Text = "Locked\n[E] Unlock"
		end
	end
end

-- Nút [E] cất đồ ở Stash của nhà. Tạo lúc cấp plot (để mang OwnerId), xoá lúc thu hồi.
local function addStashPrompt(plot)
	local stash = find(plot, "Stash")
	local part = stash and (stash:IsA("BasePart") and stash or stash.PrimaryPart or stash:FindFirstChildWhichIsA("BasePart", true))
	if part and callbacks.OnStash then
		local prompt = makePrompt(part, "Open", "Stash", plot, callbacks.OnStash)
		prompt.Name = "StashPrompt"
		prompt.MaxActivationDistance = 12
		if callbacks.OnRob then
			makeRobPrompt(part, "Stash", plot, "Stash")
		end
	end
end

local function removeStashPrompt(plot)
	local stash = find(plot, "Stash")
	for _, name in ipairs({ "StashPrompt", "RobPrompt" }) do
		local prompt = stash and stash:FindFirstChild(name, true)
		if prompt then
			prompt:Destroy()
		end
	end
end

-- Nút nâng cấp nhà (khóa cửa) gắn lên ổ khóa ở cửa (Part "DoorLock")
local function addHousePrompt(plot)
	local lock = find(plot, "DoorLock")
	if lock and lock:IsA("BasePart") then
		setBuildPrompt(lock, "BuildPrompt", "Upgrade lock", "Door lock", plot, nil, "House", 0)
	end
end

-- Ổ khóa cửa to dần, đổi vật liệu theo cấp khóa (profile.LockLevel) cho ai nhìn cũng thấy nhà này phòng thủ tới đâu
local LOCK_LOOKS = {
	[0] = { Size = Vector3.new(0.9, 0.9, 0.5), Color = Color3.fromRGB(181, 115, 60), Material = Enum.Material.Wood },
	[1] = { Size = Vector3.new(1.3, 1.4, 0.7), Color = Color3.fromRGB(205, 208, 215), Material = Enum.Material.Metal },
	[2] = { Size = Vector3.new(1.8, 2.0, 0.9), Color = Color3.fromRGB(242, 194, 48), Material = Enum.Material.Metal },
	[3] = { Size = Vector3.new(2.4, 2.8, 1.2), Color = Color3.fromRGB(255, 90, 77), Material = Enum.Material.Neon },
}

function Plots.UpdateLock(player)
	local plot = plotOf[player]
	local profile = Data.Get(player)
	local lock = plot and find(plot, "DoorLock")
	local shackle = plot and find(plot, "DoorLockShackle")
	if not (lock and profile) then
		return
	end
	local look = LOCK_LOOKS[math.clamp(profile.LockLevel or 0, 0, 3)]
	local base = lock.Position - Vector3.new(0, lock.Size.Y / 2, 0) -- đáy ổ khóa giữ nguyên khi đổi cỡ
	lock.Size = look.Size
	lock.Color = look.Color
	lock.Material = look.Material
	lock.Position = base + Vector3.new(0, look.Size.Y / 2, 0)
	if shackle then
		shackle.Size = Vector3.new(look.Size.Y * 0.8, look.Size.X * 0.6, look.Size.X * 0.6)
		shackle.Position = lock.Position + Vector3.new(0, look.Size.Y / 2 + shackle.Size.X / 2 - 0.1, 0)
	end
end

-- Xóa mọi nút mua / nâng cấp trên plot (lúc thu hồi plot)
local function clearBuildPrompts(plot)
	for _, d in ipairs(plot:GetDescendants()) do
		if d:IsA("ProximityPrompt") and (d.Name == "BuildPrompt" or d.Name == "UpgradePrompt") then
			d:Destroy()
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
			setSign(plot, player.DisplayName, player.UserId)
			addStashPrompt(plot)
			addHousePrompt(plot)
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
	clearBuildPrompts(plot)
	local dynamic = plot:FindFirstChild("Dynamic")
	if dynamic then
		dynamic:Destroy()
	end
	setSign(plot, "FOR RENT")
	dressDemo(plot) -- DEV: trả lại nhà đầy đồ cho người khác "cướp"
end

-- Vị trí thế giới của 1 bệ trên plot (dùng cho hiệu ứng)
function Plots.SlotPosition(player, slotName)
	local plot = plotOf[player]
	local pad = plot and find(plot, slotName)
	return pad and pad.Position + Vector3.new(0, 3, 0)
end

-- Người chơi đang đứng trong sân nhà MÌNH không (mua / nâng cấp máy, máy ấp, khóa phải làm ở nhà)
function Plots.IsHome(player)
	local plot = plotOf[player]
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return plot ~= nil and hrp ~= nil and SafeZone.PlotAt(hrp.Position) == plot
end

-- Chủ của plot (Model plot), nil nếu chưa có chủ
function Plots.OwnerOf(plot)
	return ownerOf[plot]
end

-- Plot của người chơi, nil nếu chưa có
function Plots.PlotOf(player)
	return plotOf[player]
end

-- Model máy ấp và trứng đang trong máy ở bệ `slot` của người chơi (để chạy hoạt ảnh nở), nil nếu không có
function Plots.IncubatorParts(player, slot)
	local plot = plotOf[player]
	local lab = plot and labels[plot]
	return lab and lab.IncubatorModels[slot], lab and lab.Eggs[slot]
end

-- Vị trí Stash (Model) của nhà người chơi, nil nếu chưa có plot
function Plots.StashPosition(player)
	local plot = plotOf[player]
	local stash = plot and find(plot, "Stash")
	if not stash then
		return nil
	end
	return stash:IsA("Model") and stash:GetPivot().Position or stash.Position
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
		setSign(plot, "FOR RENT")
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
