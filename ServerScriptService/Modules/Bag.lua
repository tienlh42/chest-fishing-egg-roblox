-- ModuleScript: ServerScriptService > Modules > Bag
-- Túi tạm: rương kéo từ hồ cấm nằm ở đây (CHƯA an toàn, không lưu DataStore).
-- Cất vào Stash ở vùng an toàn thì mới cộng vào profile + lưu. Bị bắt hoặc chết ngoài vùng an toàn = mất hết.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local Data = require(script.Parent.Data)
local Remote = require(script.Parent.Remote)
local SafeZone = require(script.Parent.SafeZone)
local Tutorial = require(script.Parent.Tutorial)

local Bag = {}

local items = {} -- [player] = { { Chest, Coins, Egg } }
local depositing = {} -- [player] = true khi đang lưu, chặn bấm 2 lần

-- Sức chứa túi của người chơi (cấp 0 = Config.Bag.Capacity, nâng cấp ở Tool Shop: Config.Bag.Upgrades)
function Bag.Capacity(player)
	local profile = Data.Get(player)
	local upgrade = profile and Config.Bag.Upgrades[profile.BagLevel or 0]
	return upgrade and upgrade.Capacity or Config.Bag.Capacity
end

local function sync(player)
	Remote.Effect(player, "Bag", { Count = #(items[player] or {}), Capacity = Bag.Capacity(player) })
end
Bag.Sync = sync

function Bag.Count(player)
	return #(items[player] or {})
end

function Bag.IsFull(player)
	return Bag.Count(player) >= Bag.Capacity(player)
end

function Bag.Add(player, item)
	local list = items[player]
	if not list or #list >= Bag.Capacity(player) then
		return false
	end
	table.insert(list, item)
	sync(player)
	return true
end

-- Mất hết đồ chưa cất. Trả về số món bị mất.
function Bag.Clear(player)
	local lost = Bag.Count(player)
	items[player] = {}
	sync(player)
	return lost
end

-- Cất đồ: cộng vào profile rồi lưu. Lưu thất bại thì hoàn lại, đồ vẫn nằm trong túi để thử lại.
function Bag.Deposit(player)
	local profile = Data.Get(player)
	local list = items[player]
	if not (profile and list) or depositing[player] then
		return
	end
	if #list == 0 then
		Remote.Notify(player, "Your bag is empty.")
		return
	end

	depositing[player] = true
	local coins, eggs = 0, {}
	for _, item in ipairs(list) do
		coins += item.Coins
		if item.Egg then
			eggs[item.Egg] = (eggs[item.Egg] or 0) + 1
		end
	end
	profile.Coins += coins
	for tier, count in pairs(eggs) do
		profile.Eggs[tier] = (profile.Eggs[tier] or 0) + count
	end

	local saved = Data.Save(player)
	depositing[player] = nil
	if not saved then
		profile.Coins -= coins
		for tier, count in pairs(eggs) do
			profile.Eggs[tier] -= count
		end
		Remote.Notify(player, "Could not save your loot. Try again in a moment!")
		return
	end

	local count = #list
	items[player] = {}
	Data.Update(player)
	sync(player)

	local msg = ("Stashed %d chest(s): +%d coins"):format(count, coins)
	for tier, n in pairs(eggs) do
		msg ..= (", +%d %s Egg"):format(n, tier)
	end
	Remote.Notify(player, msg)

	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	Remote.Effect(player, "Deposit", { Coins = coins, Eggs = eggs, Position = hrp and hrp.Position + Vector3.new(0, 4, 0) })
	Tutorial.Complete(player, "Deposit")
end

local function watchCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not (humanoid and hrp) then
		return
	end
	humanoid.Died:Connect(function()
		if not SafeZone.Contains(hrp.Position) and Bag.Count(player) > 0 then
			local lost = Bag.Clear(player)
			Remote.Notify(player, ("You went down! Lost %d unsealed chest(s)."):format(lost))
		end
	end)
end

function Bag.SetupPlayer(player)
	items[player] = {}
	player.CharacterAdded:Connect(function(character)
		watchCharacter(player, character)
	end)
	if player.Character then
		task.spawn(watchCharacter, player, player.Character)
	end
	-- Gửi lại định kỳ phòng khi UI người chơi chưa kịp nghe lần đầu
	task.spawn(function()
		while items[player] do
			sync(player)
			task.wait(3)
		end
	end)
end

function Bag.RemovePlayer(player)
	items[player] = nil
	depositing[player] = nil
end

return Bag
