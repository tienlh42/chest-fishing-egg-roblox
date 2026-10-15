-- ModuleScript: ServerScriptService > Modules > Stash
-- Kho nhà: rương cất vào (Bag.Deposit) nằm trong profile.Chests, CHƯA mở. Ở đây mở rương: tung coins / trứng LÚC MỞ
-- (kẻ cướp lấy rương không biết bên trong, người chơi không dò kết quả bằng cách thoát game).
-- Mở rương phải đứng gần Stash của mình (Config.Stash.OpenRange).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local Bag = require(script.Parent.Bag)
local Data = require(script.Parent.Data)
local Fishing = require(script.Parent.Fishing)
local Plots = require(script.Parent.Plots)
local Remote = require(script.Parent.Remote)

local Stash = {}

-- Tổng số rương chưa mở trong kho
local function totalChests(profile)
	local total = 0
	for _, count in pairs(profile.Chests) do
		total += count
	end
	return total
end

-- Người chơi có đang đứng gần Stash của mình không
local function nearStash(player)
	local stashPos = Plots.StashPosition(player)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return stashPos ~= nil and hrp ~= nil and (hrp.Position - stashPos).Magnitude <= Config.Stash.OpenRange
end

-- Nút [E] ở Stash: túi có đồ thì cất vào kho trước, rồi mở bảng Stash
function Stash.OnPrompt(player)
	if Bag.Count(player) > 0 and not Bag.Deposit(player) then
		return
	end
	Remote.Effect(player, "OpenPanel", { Panel = "Stash" })
end

-- Mở tối đa `want` rương tên `name` (nil = hết). Trả về số rương đã mở, tổng coins, bảng trứng { [tier] = n }
local function openChests(profile, player, chest, want)
	local count = math.min(profile.Chests[chest.Name] or 0, want or math.huge)
	local coins, eggs = 0, {}
	for _ = 1, count do
		local gotCoins, egg = Fishing.GiveChest(player, chest)
		coins += gotCoins
		if egg then
			eggs[egg] = (eggs[egg] or 0) + 1
		end
	end
	profile.Chests[chest.Name] -= count
	return count, coins, eggs
end

local function report(player, opened, coins, eggs)
	local msg = ("Opened %d chest%s: +%d coins"):format(opened, opened == 1 and "" or "s", coins)
	for tier, n in pairs(eggs) do
		msg ..= (", +%d %s Egg"):format(n, tier)
	end
	Remote.Notify(player, msg)
	Remote.Effect(player, "Collect", { Coins = coins, Eggs = eggs, Position = Plots.StashPosition(player) + Vector3.new(0, 6, 0) })
end

-- Action "OpenChest"(name, all): mở 1 rương loại `name`, hoặc hết rương loại đó nếu all == true
function Stash.OpenChest(player, name, all)
	local profile = Data.Get(player)
	local chest = typeof(name) == "string" and Config.FindChest(name)
	if not chest then
		return false, "Unknown chest."
	end
	if not nearStash(player) then
		return false, "Go to your Stash to open chests."
	end
	if (profile.Chests[chest.Name] or 0) < 1 then
		return false, ("You have no %s in your Stash."):format(chest.Name)
	end
	local opened, coins, eggs = openChests(profile, player, chest, all == true and nil or 1)
	Data.Update(player)
	report(player, opened, coins, eggs)
	return true
end

-- Action "OpenAllChests": mở hết mọi rương trong kho
function Stash.OpenAll(player)
	local profile = Data.Get(player)
	if not nearStash(player) then
		return false, "Go to your Stash to open chests."
	end
	if totalChests(profile) < 1 then
		return false, "Your Stash has no chests."
	end
	local opened, coins, eggs = 0, 0, {}
	for _, chest in ipairs(Config.Chests) do
		local n, c, e = openChests(profile, player, chest, nil)
		opened += n
		coins += c
		for tier, count in pairs(e) do
			eggs[tier] = (eggs[tier] or 0) + count
		end
	end
	Data.Update(player)
	report(player, opened, coins, eggs)
	return true
end

return Stash
