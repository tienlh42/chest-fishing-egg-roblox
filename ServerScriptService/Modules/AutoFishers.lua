-- ModuleScript: ServerScriptService > Modules > AutoFishers
-- Máy câu tự động: cứ Interval giây được 1 rương, tối đa Capacity (tính cả lúc offline).
-- Người chơi đến máy bấm [E] để mở hết rương.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local Data = require(script.Parent.Data)
local Fishing = require(script.Parent.Fishing)
local Plots = require(script.Parent.Plots)
local Remote = require(script.Parent.Remote)

local AutoFishers = {}

function AutoFishers.Collect(player, slot)
	local profile = Data.Get(player)
	local entry = profile and profile.AutoFishers[tostring(slot)]
	if not entry then
		return
	end

	local stored, last = Config.AutoFisherStored(entry, os.time())
	entry.Last = last
	if stored <= 0 then
		entry.Stored = 0
		Remote.Notify(player, "Nothing caught yet. Come back soon!")
		return
	end

	local totalCoins, eggs = 0, {}
	for _ = 1, stored do
		local chest = Config.WeightedRoll(Config.Chests, Config.AutoFisher.Luck)
		local coins, egg = Fishing.GiveChest(player, chest)
		totalCoins += coins
		if egg then
			eggs[egg] = (eggs[egg] or 0) + 1
		end
	end
	entry.Stored = 0
	Data.Update(player)
	Plots.UpdateLabels(player)
	Plots.PlayMachineCollect(player, slot)

	local msg = ("Opened %d chests: +%d coins"):format(stored, totalCoins)
	for tier, count in pairs(eggs) do
		msg ..= (", +%d %s Egg"):format(count, tier)
	end
	Remote.Notify(player, msg)
	Remote.Effect(player, "Collect", {
		Coins = totalCoins,
		Eggs = eggs,
		Position = Plots.SlotPosition(player, "FisherSlot" .. slot),
	})
end

-- Mua máy mới, tự lắp vào ô trống đầu tiên
function AutoFishers.Buy(player)
	local profile = Data.Get(player)
	for i, price in ipairs(Config.AutoFisher.Prices) do
		local key = tostring(i)
		if not profile.AutoFishers[key] then
			if not Data.Spend(player, price) then
				return false, ("Not enough coins (need %d)."):format(price)
			end
			profile.AutoFishers[key] = { Last = os.time(), Stored = 0 }
			Data.Update(player)
			Plots.Refresh(player)
			return true, "Auto-Fisher installed at your plot!"
		end
	end
	return false, "All Auto-Fisher slots are full."
end

return AutoFishers
