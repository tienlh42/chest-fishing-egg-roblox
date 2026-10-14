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
		return false, ("%s Eggs can't be sold. Hatch it instead!"):format(tier) -- vd. Starter Egg
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

function Market.SellPet(player, petName, sellAll)
	local profile = Data.Get(player)
	if typeof(petName) ~= "string" then
		return false, "Invalid pet."
	end
	local sold = 0
	-- Duyệt ngược để xoá an toàn; bán 1 thì bán con mới nhất
	for i = #profile.Pets, 1, -1 do
		if profile.Pets[i] == petName then
			table.remove(profile.Pets, i)
			sold += 1
			if sellAll ~= true then
				break
			end
		end
	end
	if sold == 0 then
		return false, ("You don't have a %s."):format(petName)
	end
	local coins = sold * (Config.SellPrices.Pets[petName] or 0)
	profile.Coins += coins
	Data.Update(player)
	return true, ("Sold %d %s for %d coins."):format(sold, petName, coins)
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
