-- ModuleScript: ServerScriptService > Modules > Fishing
-- Câu tay kiểu GIỮ NÚT: nhấn giữ để kéo, thanh tiến độ đầy thì được rương.
-- CÂU LÉN: nhả nút = TẠM DỪNG (giữ tiến độ, phao vẫn dưới nước, đi lại được). Giữ lại để kéo tiếp.
--   Hụt khi: đi xa quá Leash, tạm dừng quá PauseTimeout, pet gục, chết / bị bắt.
-- Server tính toàn bộ tiến độ, kết quả và ĐIỂM RƠI PHAO (chỉ được rơi xuống nước), client chỉ báo "nhấn" hoặc "nhả".
-- Đang KÉO thì nhân vật bị khoá đứng im (WalkSpeed = 0, không nhảy); tạm dừng là đi lại được.
--   Hồ chung ("Lake", cấm câu): rương vào TÚI TẠM (Bag), phải mang về Stash. Gây tiếng động làm ngỗng chú ý.
--   Ao riêng trên plot ("Pond"): an toàn, rương vào thẳng tài khoản nhưng kéo chậm hơn, ít may mắn hơn.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local Models = require(ReplicatedStorage.Models)
local Bag = require(script.Parent.Bag)
local Data = require(script.Parent.Data)
local Guard = require(script.Parent.Guard)
local Pets = require(script.Parent.Pets)
local Remote = require(script.Parent.Remote)
local SafeZone = require(script.Parent.SafeZone)
local Tutorial = require(script.Parent.Tutorial)
local FishingSpots = require(script.Parent.FishingSpots)

local TICK = 0.1
local NOISE_EVERY = 1 -- giây giữa 2 lần báo tiếng động cho ngỗng

local Fishing = {}

-- [player] = { Spot, Chest, Duration, Origin, HadPet, NextNoise,
--              Progress (giây đã kéo trước lần kéo hiện tại), ReelStart, Paused, PausedAt }
local sessions = {}
local lakeWater = {}
local pondWater = {}

-- Điểm (x, z) nằm trong Part nước nào đó của list (dung sai 1.5 stud ở mép)?
local function inWater(list, position)
	for _, part in ipairs(list) do
		local p = part.CFrame:PointToObjectSpace(position)
		if math.abs(p.X) <= part.Size.X / 2 + 1.5 and math.abs(p.Z) <= part.Size.Z / 2 + 1.5 and math.abs(p.Y) < 20 then
			return true
		end
	end
	return false
end

-- Điểm rơi phao: CastDistance stud phía trước mặt, và PHẢI là mặt nước thật (Terrain Water).
-- Trả về điểm rơi, hoặc nil + lý do
local function landingPoint(character, hrp)
	local look = hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
	if look.Magnitude < 0.1 then
		return nil, "Face the water and cast your line!"
	end
	local probe = hrp.Position + look.Unit * Config.Fishing.CastDistance

	local ignore = { character }
	local pets = workspace:FindFirstChild("PlayerPets")
	if pets then
		table.insert(ignore, pets)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = false
	local hit = workspace:Raycast(Vector3.new(probe.X, hrp.Position.Y + 20, probe.Z), Vector3.new(0, -100, 0), params)
	if not (hit and (hit.Material == Enum.Material.Water or hit.Instance.Name == "Water")) then
		return nil, "You can only cast into the water!"
	end
	return Vector3.new(probe.X, hit.Position.Y, probe.Z)
end

-- Phao rơi vào đâu thì câu kiểu đó: "Pond" (ao plot), "Lake" (hồ cấm, ngoài vùng an toàn), hoặc nil + lý do
local function spotFor(landing, position)
	if inWater(pondWater, landing) then
		return "Pond"
	end
	if inWater(lakeWater, landing) then
		if SafeZone.Contains(position) then
			return nil, "You are still at home! Walk to the lake to fish."
		end
		return "Lake"
	end
	return nil, "You can only cast into the water!"
end

-- ===== Khoá nhân vật đứng im khi câu =====
local function freeze(humanoid)
	humanoid.WalkSpeed = 0
	humanoid.JumpHeight = 0
	humanoid.JumpPower = 0
	humanoid:SetAttribute("Fishing", true) -- Sprint.client thấy thì không ghi đè tốc độ
end

local function unfreeze(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid:SetAttribute("Fishing", nil)
	humanoid.WalkSpeed = Config.Movement.WalkSpeed
	humanoid.JumpHeight = 7.2 -- mặc định Roblox
	humanoid.JumpPower = 50
end

-- Tung xúc xắc phần thưởng của 1 rương (chưa cộng vào đâu). Trả về coins, egg tier (hoặc nil)
function Fishing.RollReward(chest)
	local coins = math.random(chest.Coins[1], chest.Coins[2])
	local egg = Config.RollChestEgg(chest) -- rương hiếm dễ ra trứng xịn (Config.Chests[].Eggs)
	return coins, egg
end

-- Cộng phần thưởng của 1 rương vào profile (chưa gọi Data.Update). Trả về coins, egg tier (hoặc nil)
function Fishing.GiveChest(player, chest)
	local profile = Data.Get(player)
	local coins, egg = Fishing.RollReward(chest)
	profile.Coins += coins
	if egg then
		profile.Eggs[egg] = (profile.Eggs[egg] or 0) + 1
	end
	return coins, egg
end

-- ===== Animation cần câu asset (attribute "Anim" trên Tool; RodAnimator chạy ở client, thấy được với mọi người chơi) =====
-- Idle -> Cast (1.2s) -> Reel (lặp) -> Catch (1.6s) hoặc Miss (1.4s) -> Idle. Cần tạm (không có attribute Anim) thì bỏ qua.
local function findRod(player)
	local character = player.Character
	return (character and character:FindFirstChild("FishingRod")) or (player:FindFirstChildOfClass("Backpack") and player.Backpack:FindFirstChild("FishingRod"))
end

-- Đổi animation; `backToIdleAfter` (giây) > 0 thì tự về Idle nếu animation đó chưa bị đổi
local function rodAnim(player, anim, backToIdleAfter)
	local rod = findRod(player)
	if not rod or rod:GetAttribute("Anim") == nil then
		return
	end
	if rod:GetAttribute("Anim") ~= anim then
		rod:SetAttribute("Anim", anim)
	end
	if backToIdleAfter then
		task.delay(backToIdleAfter, function()
			if rod.Parent and rod:GetAttribute("Anim") == anim then
				rod:SetAttribute("Anim", "Idle")
			end
		end)
	end
end

-- ===== Kết thúc lượt câu =====
local function fail(player, message)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player] = nil
	unfreeze(player)
	rodAnim(player, "Miss", 1.4)
	FishingSpots.Release(session.Target) -- hụt: điểm câu nghỉ rồi ra mục tiêu mới
	Remote.Effect(player, "CastFail", { Chest = session.Chest.Name })
	if message then
		Remote.Notify(player, message)
	end
end

-- Hao 1 độ bền của cần đang cầm sau mỗi rương kéo lên ở hồ. Hết bền thì cần biến mất, quay về cần đầu tiên (không bao giờ hỏng)
local function wearRod(player)
	local profile = Data.Get(player)
	local rod = Config.GetRod(profile.EquippedRod)
	if not rod.Durability then
		return
	end
	local left = profile.Rods[rod.Id] - 1
	if left > 0 then
		profile.Rods[rod.Id] = left
		if left == math.floor(rod.Durability * Config.DurabilityWarnRatio) then
			Remote.Notify(player, ("Your %s is almost broken! (%d left)"):format(rod.Name, left))
		end
		Data.Update(player)
		return
	end
	local fallback = Config.Rods[1]
	profile.Rods[rod.Id] = nil
	profile.EquippedRod = fallback.Id
	Data.Update(player)
	Fishing.GiveRod(player)
	Remote.Notify(player, ("Your %s broke! You are back to the %s."):format(rod.Name, fallback.Name))
end

local function succeed(player, session)
	sessions[player] = nil
	unfreeze(player)
	rodAnim(player, "Catch", 1.6)
	FishingSpots.Release(session.Target) -- lấy được: điểm câu nghỉ rồi ra mục tiêu mới
	local chest = session.Chest

	if session.Spot == "Lake" then
		local coins, egg = Fishing.RollReward(chest)
		Bag.Add(player, { Chest = chest.Name, Coins = coins, Egg = egg })
		Remote.Effect(player, "Catch", { Chest = chest.Name, Unsealed = true })
		Remote.Notify(player, ("Hauled up a %s! Bag %d/%d. Carry it home to your Stash to open it."):format(chest.Name, Bag.Count(player), Bag.Capacity(player)))
		Tutorial.Complete(player, "Lake")
		wearRod(player)
		return
	end

	local coins, egg = Fishing.GiveChest(player, chest)
	Data.Update(player)
	local msg = ("Caught a %s! +%d coins"):format(chest.Name, coins)
	if egg then
		msg ..= (" and a %s Egg!"):format(egg)
	end
	Remote.Effect(player, "Catch", { Chest = chest.Name, Coins = coins, Egg = egg })
	Remote.Notify(player, msg)
end

-- Số giây đã kéo được (cộng dồn qua các lần tạm dừng)
local function progressOf(session)
	if session.Paused then
		return session.Progress
	end
	return session.Progress + (os.clock() - session.ReelStart)
end

-- Mỗi TICK giây: kiểm tra từng lượt câu
local function step(player, session)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (hrp and humanoid and humanoid.Health > 0) then
		fail(player)
		return
	end
	-- Pet gục cùng lúc thanh đầy thì ưu tiên hủy lượt (kiểm tra trước thành công). Chỉ hồ cấm: ao nhà không có ngỗng
	if session.Spot == "Lake" and session.HadPet and Pets.Status(player).Down then
		fail(player, "Your pet is exhausted! The chest slipped away.")
		return
	end

	local moved = (hrp.Position - session.Origin).Magnitude
	if session.Paused then
		if moved > Config.Fishing.Leash then
			fail(player, "You walked too far! The line snapped.")
		elseif os.clock() - session.PausedAt > Config.Fishing.PauseTimeout then
			fail(player, "You waited too long! The chest slipped off the hook.")
		end
		return -- tạm dừng: không tiến độ, không tiếng động
	end

	if moved > Config.Fishing.MaxMove then
		fail(player, "You got pushed away! The chest sank.")
		return
	end
	local progress = progressOf(session)
	if session.Spot == "Lake" and progress >= Config.Fishing.NoiseDelay and os.clock() >= session.NextNoise then
		session.NextNoise = os.clock() + NOISE_EVERY
		Guard.Noise(hrp.Position, Config.Fishing.NoiseRadius)
	end
	if progress >= session.Duration then
		succeed(player, session)
	end
end

task.spawn(function()
	while true do
		task.wait(TICK)
		for player, session in pairs(sessions) do
			step(player, session)
		end
	end
end)

-- ===== Điều khiển từ người chơi =====

-- Đang tạm dừng mà nhấn lại: kéo tiếp từ chỗ cũ
local function resume(player, session, hrp, humanoid)
	if (hrp.Position - session.Origin).Magnitude > Config.Fishing.Leash then
		return -- step() sẽ báo đứt dây
	end
	session.Paused = false
	session.ReelStart = os.clock()
	freeze(humanoid)
	rodAnim(player, "Reel")
	-- quay mặt lại phía phao cho tự nhiên
	local look = Vector3.new(session.Landing.X, hrp.Position.Y, session.Landing.Z)
	if (look - hrp.Position).Magnitude > 0.5 then
		hrp.CFrame = CFrame.lookAt(hrp.Position, look)
	end
	Remote.Effect(player, "CastResume", {
		Chest = session.Chest.Name,
		Progress = session.Progress,
		Duration = session.Duration,
		StartTime = workspace:GetServerTimeNow(),
		Spot = session.Spot,
	})
end

function Fishing.Press(player)
	local profile = Data.Get(player)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (profile and hrp and humanoid and humanoid.Health > 0) then
		return
	end
	local current = sessions[player]
	if current then
		if current.Paused then
			resume(player, current, hrp, humanoid)
		end
		return -- bấm lặp khi đang kéo không tạo thêm lượt
	end

	local landing, landReason = landingPoint(character, hrp)
	if not landing then
		Remote.Notify(player, landReason)
		return
	end
	local spot, reason = spotFor(landing, hrp.Position)
	if not spot then
		Remote.Notify(player, reason)
		return
	end
	local pet = Pets.Status(player)
	if spot == "Lake" then
		if Bag.IsFull(player) then
			Remote.Notify(player, "Your bag is full! Run home and deposit your loot in your Stash.")
			return
		end
		if pet.HasPet and pet.Down then
			Remote.Notify(player, "Your pet is exhausted! Let it rest at home first.")
			return
		end
	end

	-- Hồ cấm: phải ném gần 1 điểm câu còn trống (FishingSpots), phao bám vào đúng điểm đó
	local target = nil
	if spot == "Lake" then
		local claimReason
		target, claimReason = FishingSpots.Claim(player, landing)
		if not target then
			Remote.Notify(player, claimReason)
			return
		end
		local p = target.Part.Position
		landing = Vector3.new(p.X, landing.Y, p.Z)
	end

	local rod = Config.GetRod(profile.EquippedRod)
	local chest = Config.RollChest(spot == "Lake" and rod.Odds or Config.Fishing.PondOdds)
	local duration = chest.HoldTime * rod.Speed * (spot == "Pond" and Config.Fishing.PondTimeMult or 1)

	sessions[player] = {
		Spot = spot,
		Target = target, -- điểm câu ở hồ (nil nếu câu ở ao nhà)
		Chest = chest,
		Duration = duration,
		Origin = hrp.Position,
		Landing = landing,
		HadPet = pet.HasPet,
		NextNoise = 0,
		Progress = 0,
		ReelStart = os.clock(),
		Paused = false,
	}
	freeze(humanoid)
	Remote.Effect(player, "CastStart", {
		Chest = chest.Name,
		Duration = duration,
		StartTime = workspace:GetServerTimeNow(),
		Spot = spot,
		Landing = landing,
	})

	-- Cần asset: vung cần (Cast 1.2s) rồi kéo (Reel lặp)
	rodAnim(player, "Cast")
	local session = sessions[player]
	task.delay(1.2, function()
		if sessions[player] == session and not session.Paused then
			rodAnim(player, "Reel")
		end
	end)
end

-- Nhả nút: TẠM DỪNG, giữ tiến độ
function Fishing.Release(player)
	local session = sessions[player]
	if not session or session.Paused then
		return
	end
	session.Progress = progressOf(session)
	session.Paused = true
	session.PausedAt = os.clock()
	unfreeze(player)
	rodAnim(player, "Idle")
	Remote.Effect(player, "CastPause", {
		Chest = session.Chest.Name,
		Progress = session.Progress,
		Duration = session.Duration,
		Timeout = Config.Fishing.PauseTimeout,
		Leash = Config.Fishing.Leash,
	})
end

-- Đang KÉO thật sự (không tính lúc tạm dừng) – ngỗng dùng để biết ai khả nghi
function Fishing.IsReeling(player)
	local session = sessions[player]
	return session ~= nil and not session.Paused
end

-- Hủy lượt câu không báo gì (bị bắt, dịch chuyển...)
function Fishing.Cancel(player)
	fail(player)
end

-- Cần asset là Model rig (HumanoidRootPart + Motor6D + script RodAnimator / RodEffects, attribute Anim / Rarity).
-- Bọc thành Tool: HumanoidRootPart thành Handle, mọi Part thả neo, giữ nguyên rig; ẩn móc câu của cần
-- (dây + phao do Effects.client.lua vẽ tại điểm rơi server tính, nên móc của cần không cần hiện).
local GRIP = CFrame.Angles(math.rad(20), 0, 0) -- cầm cần chếch lên phía trước (~50 độ so với phương thẳng đứng)
local function toolFromRig(model)
	local tool = Instance.new("Tool")
	tool.CanBeDropped = false
	tool.Grip = GRIP
	local root = model.PrimaryPart
	root.Name = "Handle"
	for key, value in pairs(model:GetAttributes()) do
		tool:SetAttribute(key, value)
	end
	for _, child in ipairs(model:GetChildren()) do
		child.Parent = tool
	end
	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.Massless = d ~= root
			if d.Name == "LineEnd" or d.Name:match("^Hook") then
				d.Transparency = 1
			end
		end
	end
	model:Destroy()
	return tool
end

-- Phát (hoặc đổi) cần câu theo EquippedRod. Tool luôn tên "FishingRod".
function Fishing.GiveRod(player)
	local profile = Data.Get(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not (profile and backpack) then
		return
	end

	local character = player.Character
	local wasHolding = false
	local old = backpack:FindFirstChild("FishingRod")
	if old then
		old:Destroy()
	end
	old = character and character:FindFirstChild("FishingRod")
	if old then
		wasHolding = true
		old:Destroy()
	end

	local spec = Config.GetRod(profile.EquippedRod)
	local rod = Models.Get(spec.Name)
	if rod:IsA("Model") and rod.PrimaryPart and rod:FindFirstChildWhichIsA("Motor6D", true) then
		rod = toolFromRig(rod) -- cần asset: Model rig -> Tool
	end
	if not rod:IsA("Tool") then
		warn(("CustomModels.%s must be a Tool (or a rigged Model)"):format(spec.Name))
		rod:Destroy()
		return
	end
	rod.Name = "FishingRod"
	rod.ToolTip = "Hold to reel in, let go to pause"
	rod:SetAttribute("RodId", spec.Id)
	rod.Activated:Connect(function()
		Fishing.Press(player)
	end)
	rod.Deactivated:Connect(function()
		Fishing.Release(player)
	end)
	rod.Unequipped:Connect(function()
		fail(player, "You put your rod away. The chest sank.")
	end)
	rod.Parent = backpack

	local humanoid = wasHolding and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:EquipTool(rod)
	end
end

function Fishing.SetupPlayer(player)
	player.CharacterAdded:Connect(function()
		player:WaitForChild("Backpack")
		Fishing.GiveRod(player)
	end)
	if player.Character then
		Fishing.GiveRod(player)
	end
end

function Fishing.RemovePlayer(player)
	local session = sessions[player]
	sessions[player] = nil -- người chơi đã rời, không cần mở khoá
	if session then
		FishingSpots.Release(session.Target)
	end
end

function Fishing.Init(map)
	local plots = map:FindFirstChild("Plots")
	for _, d in ipairs(map:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "Water" then
			table.insert(plots and d:IsDescendantOf(plots) and pondWater or lakeWater, d)
		end
	end
	Remote.Folder.Cast.OnServerEvent:Connect(function(player, state)
		if state == "Down" then
			Fishing.Press(player)
		elseif state == "Up" then
			Fishing.Release(player)
		end
	end)
end

return Fishing
