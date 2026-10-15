-- ModuleScript: ServerScriptService > Modules > AutoFishers
-- Máy câu tự động (Config.AutoFisher): mỗi tier có tốc độ, kho, độ bền và tỉ lệ rương riêng, tích rương cả lúc offline.
-- Mở ổ máy bằng coins, mua máy (tier tùy chọn) vào ổ trống, nâng tier tại chỗ, bấm [E] ở máy để mở hết rương.
-- Máy làm ra đủ số rương của độ bền thì biến mất sau lần thu cuối (ổ còn lại), không sửa được.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local Data = require(script.Parent.Data)
local Fishing = require(script.Parent.Fishing)
local Plots = require(script.Parent.Plots)
local Remote = require(script.Parent.Remote)

local AutoFishers = {}

function AutoFishers.Collect(player, slot)
	local profile = Data.Get(player)
	local key = tostring(slot)
	local entry = profile and profile.AutoFishers[key]
	if not entry then
		return
	end
	local tier = Config.AutoFisher.Tiers[entry.Tier]

	local stored, last = Config.AutoFisherStored(entry, os.time())
	entry.Last = last
	if stored <= 0 then
		entry.Stored = 0
		Remote.Notify(player, "Nothing caught yet. Come back soon!")
		return
	end

	local totalCoins, eggs = 0, {}
	for _ = 1, stored do
		local coins, egg = Fishing.GiveChest(player, Config.RollChest(tier.Odds))
		totalCoins += coins
		if egg then
			eggs[egg] = (eggs[egg] or 0) + 1
		end
	end
	entry.Stored = 0

	-- Độ bền = số rương máy làm ra. Hết thì máy biến mất (ổ còn lại)
	local warnAt = tier.Durability * Config.DurabilityWarnRatio
	local before = entry.Durability
	entry.Durability -= stored
	local broken = entry.Durability <= 0
	if broken then
		profile.AutoFishers[key] = nil
	end
	Data.Update(player)
	if broken then
		Plots.Refresh(player)
	else
		Plots.UpdateLabels(player)
		Plots.PlayMachineCollect(player, slot)
	end

	local msg = ("Opened %d chests: +%d coins"):format(stored, totalCoins)
	for eggTier, count in pairs(eggs) do
		msg ..= (", +%d %s Egg"):format(count, eggTier)
	end
	Remote.Notify(player, msg)
	if broken then
		Remote.Notify(player, ("Your %s Auto-Fisher is worn out and fell apart! Buy a new one at its pedestal."):format(tier.Name))
	elseif before > warnAt and entry.Durability <= warnAt then
		Remote.Notify(player, ("Your %s Auto-Fisher is almost worn out! (%d left)"):format(tier.Name, entry.Durability))
	end
	Remote.Effect(player, "Collect", {
		Coins = totalCoins,
		Eggs = eggs,
		Position = Plots.SlotPosition(player, "FisherSlot" .. slot),
	})
end

-- Mở ổ máy tiếp theo (mở một lần, không hỏng)
function AutoFishers.UnlockSlot(player)
	if not Plots.IsHome(player) then
		return false, "Go to your house to unlock a pedestal."
	end
	local profile = Data.Get(player)
	local nextSlot = profile.FisherSlots + 1
	local price = Config.AutoFisher.PedestalPrices[nextSlot]
	if not price then
		return false, "All machine pedestals are already unlocked."
	end
	if not Data.Spend(player, price) then
		return false, ("Not enough coins (need %d)."):format(price)
	end
	profile.FisherSlots = nextSlot
	Data.Update(player)
	Plots.Refresh(player)
	return true, "New machine pedestal unlocked at your plot!"
end

-- Mua thẳng máy tier `tierIndex`, lắp vào ổ `wantedSlot` (đang trống, đã mở) hoặc ô trống đầu tiên. Phải đứng ở nhà mình
function AutoFishers.Buy(player, tierIndex, wantedSlot)
	if not Plots.IsHome(player) then
		return false, "Go to your house to buy a machine."
	end
	local profile = Data.Get(player)
	local tier = typeof(tierIndex) == "number" and Config.AutoFisher.Tiers[tierIndex]
	if not tier then
		return false, "Unknown machine."
	end
	local slot = nil
	if typeof(wantedSlot) == "number" and wantedSlot % 1 == 0 and wantedSlot >= 1 and wantedSlot <= profile.FisherSlots and not profile.AutoFishers[tostring(wantedSlot)] then
		slot = wantedSlot
	else
		for i = 1, profile.FisherSlots do
			if not profile.AutoFishers[tostring(i)] then
				slot = i
				break
			end
		end
	end
	if not slot then
		return false, "No free pedestal. Unlock a new one, or wait for a machine to wear out."
	end
	if not Data.Spend(player, tier.Price) then
		return false, ("Not enough coins (need %d)."):format(tier.Price)
	end
	profile.AutoFishers[tostring(slot)] = { Tier = tierIndex, Durability = tier.Durability, Last = os.time(), Stored = 0 }
	Data.Update(player)
	Plots.Refresh(player)
	return true, ("%s Auto-Fisher installed at your plot!"):format(tier.Name)
end

-- Nâng máy ở ổ `slot` lên tier kế tiếp: trả chênh lệch giá, độ bền về đầy (cách duy nhất để "sửa" máy)
function AutoFishers.Upgrade(player, slot)
	if not Plots.IsHome(player) then
		return false, "Go to your house to upgrade a machine."
	end
	local profile = Data.Get(player)
	local entry = typeof(slot) == "number" and profile.AutoFishers[tostring(slot)]
	if not entry then
		return false, "There is no machine there."
	end
	local nextTier = Config.AutoFisher.Tiers[entry.Tier + 1]
	if not nextTier then
		return false, "This machine is already the best!"
	end
	local price = nextTier.Price - Config.AutoFisher.Tiers[entry.Tier].Price
	if not Data.Spend(player, price) then
		return false, ("Not enough coins (need %d)."):format(price)
	end
	-- chốt số rương đã tích theo tier cũ trước khi đổi tier
	entry.Stored, entry.Last = Config.AutoFisherStored(entry, os.time())
	entry.Tier += 1
	entry.Durability = nextTier.Durability
	Data.Update(player)
	Plots.Refresh(player)
	return true, ("Upgraded to a %s Auto-Fisher! Durability restored."):format(nextTier.Name)
end

return AutoFishers
