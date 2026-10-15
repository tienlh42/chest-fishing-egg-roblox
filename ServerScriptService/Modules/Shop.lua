-- ModuleScript: ServerScriptService > Modules > Shop
-- Tool Shop: CHỈ MUA ĐỒ (cần câu, túi lớn hơn, Chìa vạn năng, Dép Tên Lửa) + chọn cần / pet đang dùng.
-- Mở máy ấp, ổ máy, mua / nâng cấp máy câu, khóa cửa làm Ở NHÀ (bấm [E] / [G] trên bệ, máy, biển tên nhà: Plots.lua), phải đứng trong sân nhà mình.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local Bag = require(script.Parent.Bag)
local Data = require(script.Parent.Data)
local Fishing = require(script.Parent.Fishing)
local Guard = require(script.Parent.Guard)
local Plots = require(script.Parent.Plots)
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
	profile.Rods[rod.Id] = rod.Durability or true
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

-- Chọn pet đi theo (pet nào cũng được, kể cả pet đang kiệt sức). Không đổi pet giữa lúc bị ngỗng đuổi
function Shop.EquipPet(player, id)
	local profile = Data.Get(player)
	local pet = typeof(id) == "number" and Data.FindPet(profile, id)
	if not pet then
		return false, "You don't own this pet."
	end
	if profile.EquippedPet == id then
		return false, ("%s is already following you."):format(pet.Name)
	end
	if Guard.IsChasing(player) then
		return false, "You can't swap pets while the goose is chasing you!"
	end
	profile.EquippedPet = id
	Data.Update(player)
	return true, ("%s is now following you."):format(pet.Name)
end

function Shop.BuyIncubator(player)
	if not Plots.IsHome(player) then
		return false, "Go to your house to unlock an incubator."
	end
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

-- Nâng cấp túi: 4 -> 5 -> 6 ô (Config.Bag.Upgrades)
function Shop.BuyBagUpgrade(player)
	local profile = Data.Get(player)
	local upgrade = Config.Bag.Upgrades[(profile.BagLevel or 0) + 1]
	if not upgrade then
		return false, "Your bag is already the biggest!"
	end
	if not Data.Spend(player, upgrade.Price) then
		return false, ("Not enough coins (need %d)."):format(upgrade.Price)
	end
	profile.BagLevel = (profile.BagLevel or 0) + 1
	Data.Update(player)
	Bag.Sync(player)
	return true, ("Bag upgraded! It now holds %d chests."):format(upgrade.Capacity)
end

-- Mua Chìa vạn năng (Config.Robbery.KeyPrice) để cướp nhà người khác
function Shop.BuyKey(player, amount)
	local profile = Data.Get(player)
	amount = typeof(amount) == "number" and amount % 1 == 0 and math.clamp(amount, 1, 20) or 1
	local price = Config.Robbery.KeyPrice * amount
	if not Data.Spend(player, price) then
		return false, ("Not enough coins (need %d)."):format(price)
	end
	profile.Keys += amount
	Data.Update(player)
	return true, ("Bought %d Master Key%s! You have %d."):format(amount, amount == 1 and "" or "s", profile.Keys)
end

-- Nâng khóa cửa nhà lên cấp kế tiếp (Config.Robbery.Locks): giảm tỉ lệ mở của Chìa vạn năng khi người khác cướp nhà mình
function Shop.BuyLock(player)
	if not Plots.IsHome(player) then
		return false, "Go to your house to install a lock."
	end
	local profile = Data.Get(player)
	local nextLock = Config.LockInfo(profile.LockLevel + 1)
	if not nextLock then
		return false, "Your door lock is already the strongest!"
	end
	if not Data.Spend(player, nextLock.Price) then
		return false, ("Not enough coins (need %d)."):format(nextLock.Price)
	end
	profile.LockLevel += 1
	Data.Update(player)
	Plots.UpdateLock(player) -- ổ khóa ở cửa to dần
	return true, ("%s installed! Thieves now open your door only %d%% of the time."):format(nextLock.Name, math.floor(nextLock.OpenChance * 100 + 0.5))
end

-- Trang bị (Config.Gear): mua 1 lần, có là dùng luôn. Tốc chạy áp ở Sprint.client.lua (đọc profile.Gear)
function Shop.BuyGear(player, id)
	local profile = Data.Get(player)
	local gear = typeof(id) == "string" and Config.Gear[id]
	if not gear then
		return false, "Unknown item."
	end
	profile.Gear = profile.Gear or {}
	if profile.Gear[id] then
		return false, ("You already own %s."):format(gear.Name)
	end
	if not Data.Spend(player, gear.Price) then
		return false, ("Not enough coins (need %d)."):format(gear.Price)
	end
	profile.Gear[id] = true
	Data.Update(player)
	return true, ("Bought %s! You move %d%% faster."):format(gear.Name, math.floor(gear.SpeedBonus * 100 + 0.5))
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
