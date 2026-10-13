-- ModuleScript: ServerScriptService > Modules > Fishing
-- Câu tay + phát cần câu. Server quyết định MỌI kết quả, client chỉ gửi yêu cầu.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local Models = require(ReplicatedStorage.Models)
local Data = require(script.Parent.Data)
local Remote = require(script.Parent.Remote)

local WATER_RANGE = 25 -- đứng cách nước tối đa bao nhiêu stud thì được câu

local Fishing = {}

local busy = {} -- [player] = true khi đang chờ cá cắn
local waterParts = {}

local function nearWater(position)
	for _, part in ipairs(waterParts) do
		local p = part.CFrame:PointToObjectSpace(position)
		local dx = math.max(math.abs(p.X) - part.Size.X / 2, 0)
		local dz = math.max(math.abs(p.Z) - part.Size.Z / 2, 0)
		if dx * dx + dz * dz <= WATER_RANGE * WATER_RANGE and math.abs(p.Y) < 20 then
			return true
		end
	end
	return false
end

-- Cộng phần thưởng của 1 rương vào profile (chưa gọi Data.Update). Trả về coins, egg tier (hoặc nil)
function Fishing.GiveChest(player, chest)
	local profile = Data.Get(player)
	local coins = math.random(chest.Coins[1], chest.Coins[2])
	profile.Coins += coins
	local egg = nil
	if math.random() < chest.EggChance then
		egg = chest.EggTier
		profile.Eggs[egg] = (profile.Eggs[egg] or 0) + 1
	end
	return coins, egg
end

function Fishing.Cast(player)
	if busy[player] then
		Remote.Notify(player, "You're already fishing!")
		return
	end
	local profile = Data.Get(player)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (profile and hrp) then
		return
	end
	if not nearWater(hrp.Position) then
		Remote.Notify(player, "Get closer to the water to fish!")
		return
	end
	busy[player] = true

	local rod = Config.GetRod(profile.EquippedRod)
	Remote.Notify(player, "Waiting for a bite...")
	Remote.Effect(player, "CastStart")
	task.wait(math.random(Config.CastTime.Min, Config.CastTime.Max) * rod.Speed)

	if player.Parent and Data.Get(player) then
		local chest = Config.WeightedRoll(Config.Chests, rod.Luck)
		local coins, egg = Fishing.GiveChest(player, chest)
		Data.Update(player)

		local msg = ("Caught a %s! +%d coins"):format(chest.Name, coins)
		if egg then
			msg ..= (" and a %s Egg!"):format(egg)
		end
		Remote.Effect(player, "Catch", { Chest = chest.Name, Coins = coins, Egg = egg })
		Remote.Notify(player, msg)
	end

	busy[player] = nil
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
	if not rod:IsA("Tool") then
		warn(("CustomModels.%s must be a Tool"):format(spec.Name))
		rod:Destroy()
		return
	end
	rod.Name = "FishingRod"
	rod:SetAttribute("RodId", spec.Id)
	rod.Activated:Connect(function()
		Fishing.Cast(player)
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
	busy[player] = nil
end

function Fishing.Init(map)
	for _, d in ipairs(map:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "Water" then
			table.insert(waterParts, d)
		end
	end
	Remote.Folder.Cast.OnServerEvent:Connect(Fishing.Cast)
end

return Fishing
