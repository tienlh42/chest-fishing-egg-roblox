-- ModuleScript: ServerScriptService > Modules > Bag
-- Túi tạm: rương kéo từ hồ cấm nằm ở đây (CHƯA an toàn, không lưu DataStore).
-- Cất vào Stash ở vùng an toàn thì rương chuyển vào kho profile.Chests + lưu (chưa mở). Bị bắt hoặc chết ngoài vùng an toàn = mất hết.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local Data = require(script.Parent.Data)
local Remote = require(script.Parent.Remote)
local SafeZone = require(script.Parent.SafeZone)
local Tutorial = require(script.Parent.Tutorial)

local Bag = {}

-- Món trong túi: { Chest = tên rương } hoặc { Egg = tier trứng }. Món CƯỚP được có thêm Owner = người chơi (chủ nhà bị cướp):
-- bị bắt / chết / thoát game thì món đó trả về kho của Owner (Robbery.lua), cất ở nhà mình thì thành của mình.
local items = {} -- [player] = { món... }
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

-- Trả món cướp được về kho chủ nhà (nếu chủ còn trong game). Món của mình thì bỏ
local function returnStolen(list)
	local owners = {}
	for _, item in ipairs(list or {}) do
		local owner = item.Owner
		local profile = owner and owner.Parent and Data.Get(owner)
		if profile then
			if item.Chest then
				profile.Chests[item.Chest] = (profile.Chests[item.Chest] or 0) + 1
			elseif item.Egg then
				profile.Eggs[item.Egg] = (profile.Eggs[item.Egg] or 0) + 1
			end
			owners[owner] = (owners[owner] or 0) + 1
		end
	end
	for owner, count in pairs(owners) do
		Data.Update(owner)
		Remote.Notify(owner, ("The thief was caught! %d stolen item(s) went back to your Stash."):format(count))
	end
end

-- Mất hết đồ chưa cất (món cướp được trả về chủ nhà). Trả về số món bị mất.
function Bag.Clear(player)
	local lost = Bag.Count(player)
	returnStolen(items[player])
	items[player] = {}
	sync(player)
	return lost
end

-- Cất đồ: chuyển rương vào kho profile rồi lưu. Lưu thất bại thì hoàn lại, đồ vẫn nằm trong túi để thử lại. Trả về true nếu đã cất
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

	-- Chỉ chuyển rương vào kho (chưa mở, nội dung tung lúc mở ở Stash.lua)
	depositing[player] = true
	local chests, eggs = {}, {}
	for _, item in ipairs(list) do
		if item.Chest then
			chests[item.Chest] = (chests[item.Chest] or 0) + 1
		elseif item.Egg then
			eggs[item.Egg] = (eggs[item.Egg] or 0) + 1
		end
	end
	for name, count in pairs(chests) do
		profile.Chests[name] = (profile.Chests[name] or 0) + count
	end
	for tier, count in pairs(eggs) do
		profile.Eggs[tier] = (profile.Eggs[tier] or 0) + count
	end

	local saved = Data.Save(player)
	depositing[player] = nil
	if not saved then
		for name, count in pairs(chests) do
			profile.Chests[name] -= count
		end
		for tier, count in pairs(eggs) do
			profile.Eggs[tier] -= count
		end
		Remote.Notify(player, "Could not save your loot. Try again in a moment!")
		return false
	end

	local count = #list
	items[player] = {}
	Data.Update(player)
	sync(player)

	Remote.Notify(player, ("Stashed %d item(s)! Open your chests at the Stash."):format(count))
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	Remote.Effect(player, "Deposit", { Chests = count, Position = hrp and hrp.Position + Vector3.new(0, 4, 0) })
	Tutorial.Complete(player, "Deposit")
	return true
end

local function watchCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not (humanoid and hrp) then
		return
	end
	humanoid.Died:Connect(function()
		if not SafeZone.Contains(hrp.Position, player) and Bag.Count(player) > 0 then
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
	returnStolen(items[player])
	items[player] = nil
	depositing[player] = nil
end

return Bag
