-- ModuleScript: ServerScriptService > Modules > Shop
-- Tool Shop: mua/chọn cần câu, mua máy câu tự động, mở thêm máy ấp.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local Data = require(script.Parent.Data)
local Fishing = require(script.Parent.Fishing)
local Plots = require(script.Parent.Plots)
local AutoFishers = require(script.Parent.AutoFishers)
local Remote = require(script.Parent.Remote)

local Shop = {}

local function findRod(id)
	for _, rod in ipairs(Config.Rods) do
		if rod.Id == id then
			return rod
		end
	end
	return nil
end

function Shop.BuyRod(player, id)
	local profile = Data.Get(player)
	local rod = findRod(id)
	if not rod then
		return false, "Unknown rod."
	end
	if profile.Rods[rod.Id] then
		return false, "You already own this rod."
	end
	if not Data.Spend(player, rod.Price) then
		return false, ("Not enough coins (need %d)."):format(rod.Price)
	end
	profile.Rods[rod.Id] = true
	profile.EquippedRod = rod.Id
	Data.Update(player)
	Fishing.GiveRod(player)
	return true, ("Bought %s!"):format(rod.Name)
end

function Shop.EquipRod(player, id)
	local profile = Data.Get(player)
	local rod = findRod(id)
	if not (rod and profile.Rods[rod.Id]) then
		return false, "You don't own this rod."
	end
	profile.EquippedRod = rod.Id
	Data.Update(player)
	Fishing.GiveRod(player)
	return true, ("Equipped %s."):format(rod.Name)
end

function Shop.BuyAutoFisher(player)
	return AutoFishers.Buy(player)
end

function Shop.BuyIncubator(player)
	local profile = Data.Get(player)
	local nextSlot = profile.IncubatorSlots + 1
	if nextSlot > Config.Incubators.MaxSlots then
		return false, "You already have the maximum number of incubators."
	end
	local price = Config.Incubators.Prices[nextSlot] or 0
	if not Data.Spend(player, price) then
		return false, ("Not enough coins (need %d)."):format(price)
	end
	profile.IncubatorSlots = nextSlot
	Data.Update(player)
	Plots.Refresh(player)
	return true, "New incubator unlocked at your plot!"
end

-- Nút [E] ở quầy -> mở bảng Shop trên client
function Shop.Init(map)
	local shop = map:FindFirstChild("ToolShop", true)
	local part = shop and shop:FindFirstChild("PromptPart", true)
	if not part then
		warn("Map is missing ToolShop > PromptPart")
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Shop"
	prompt.ObjectText = "Tool Shop"
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 12
	prompt.Triggered:Connect(function(player)
		Remote.Effect(player, "OpenPanel", { Panel = "Shop" })
	end)
	prompt.Parent = part
end

return Shop
