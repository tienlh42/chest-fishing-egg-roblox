-- ModuleScript: ServerScriptService > Modules > Market
-- Bán trứng và pet cho NPC lấy coins.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local Data = require(script.Parent.Data)
local Remote = require(script.Parent.Remote)

local Market = {}

-- sellAll = true: bán hết loại đó; false: bán 1
function Market.SellEgg(player, tier, sellAll)
	local profile = Data.Get(player)
	if typeof(tier) ~= "string" or not Config.Eggs[tier] then
		return false, "Invalid egg."
	end
	if not Config.SellPrices.Eggs[tier] then
		return false, ("%s Eggs can't be sold. Hatch it instead!"):format(tier) -- trứng không có giá bán
	end
	local have = profile.Eggs[tier] or 0
	if have < 1 then
		return false, ("You don't have any %s Eggs."):format(tier)
	end
	local amount = sellAll == true and have or 1
	local coins = amount * (Config.SellPrices.Eggs[tier] or 0)
	profile.Eggs[tier] = have - amount
	profile.Coins += coins
	Data.Update(player)
	return true, ("Sold %d %s Egg for %d coins."):format(amount, tier, coins)
end

-- Bán 1 pet theo Id. Giá = giá gốc x tỉ lệ độ bền còn lại (Config.PetSellPrice). Bán pet đang equip thì không còn pet đi theo
function Market.SellPet(player, id)
	local profile = Data.Get(player)
	local pet, index = nil, nil
	if typeof(id) == "number" then
		pet, index = Data.FindPet(profile, id)
	end
	if not pet then
		return false, "You don't have this pet."
	end
	local coins = Config.PetSellPrice(pet)
	table.remove(profile.Pets, index)
	if profile.EquippedPet == id then
		profile.EquippedPet = nil
	end
	profile.Coins += coins
	Data.Update(player)
	return true, ("Sold %s for %d coins."):format(pet.Name, coins)
end

function Market.Init(map)
	local market = map:FindFirstChild("Market", true)
	local part = market and market:FindFirstChild("PromptPart", true)
	if not part then
		warn("Map is missing Market > PromptPart")
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Sell"
	prompt.ObjectText = "Market"
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 12
	prompt.Triggered:Connect(function(player)
		Remote.Effect(player, "OpenPanel", { Panel = "Market" })
	end)
	prompt.Parent = part
end

return Market
