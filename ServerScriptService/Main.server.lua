-- Script: ServerScriptService > Main
-- Điểm khởi động DUY NHẤT của server: dựng map, nối các module, xử lý người chơi vào/ra.
-- Logic từng phần nằm trong ServerScriptService > Modules.

local Players = game:GetService("Players")

local Modules = script.Parent:WaitForChild("Modules")
local Data = require(Modules.Data)
local Remote = require(Modules.Remote)
local MapBuilder = require(Modules.MapBuilder)
local Plots = require(Modules.Plots)
local Fishing = require(Modules.Fishing)
local Hatchery = require(Modules.Hatchery)
local AutoFishers = require(Modules.AutoFishers)
local Shop = require(Modules.Shop)
local Market = require(Modules.Market)
local Pets = require(Modules.Pets)
local Bag = require(Modules.Bag)
local Stash = require(Modules.Stash)
local Robbery = require(Modules.Robbery)
local SafeZone = require(Modules.SafeZone)
local Guard = require(Modules.Guard)
local NoSwim = require(Modules.NoSwim)
local Teleports = require(Modules.Teleports)
local House = require(Modules.House)
local FishingSpots = require(Modules.FishingSpots)

local map = MapBuilder.Build()
Plots.Init(map, {
	OnIncubator = Hatchery.OnPrompt,
	OnFisher = AutoFishers.Collect,
	-- Nút mua / nâng cấp ở nhà (bệ máy ấp, ổ máy, máy câu, biển tên): mở bảng "Build" trên client
	OnBuild = function(player, kind, slot)
		Remote.Effect(player, "OpenPanel", { Panel = "Build", Kind = kind, Slot = slot })
	end,
	OnRob = Robbery.OnPrompt, -- người khác bấm [F] ở Stash / máy câu: mở khóa bằng chìa, bảng cướp
	OnStash = Stash.OnPrompt, -- cất rương trong túi vào kho, rồi mở bảng Stash
	OnAssign = function(player, plot)
		House.OnAssign(player, plot) -- ổ pet, móc balo, kệ trưng bày, hộp thư quà hằng ngày
		Guard.SpawnHouse(player, plot) -- ngỗng nhà
	end,
	OnRelease = function(player, plot)
		House.OnRelease(player, plot)
		Guard.RemoveHouse(player)
	end,
})
SafeZone.Init(map)
Fishing.Init(map)
FishingSpots.Init(map) -- 6 điểm câu (phao CHEST) trên hồ
Teleports.Init(map)
NoSwim.Init()
Shop.Init(map)
Market.Init(map)

-- Ngỗng bắt được người chơi: mất đồ chưa cất, về nhà mình
Guard.Init(map, {
	-- Ngỗng chỉ để ý người khả nghi: đang kéo câu (thấy xa) hoặc túi đang có đồ chưa cất (chỉ thấy gần)
	Suspicion = function(player)
		if Fishing.IsReeling(player) then
			return "Reeling"
		elseif Bag.Count(player) > 0 then
			return "Loot"
		end
		return nil
	end,
	-- Kẻ cướp bị truy nã trong sân nhà người đó: ngỗng nhà của chủ đó được rượt
	Wanted = Robbery.IsWanted,
	OnCaught = function(player)
		Fishing.Cancel(player)
		Robbery.Reset(player)
		local lost = Bag.Clear(player)
		Plots.TeleportHome(player) -- bị bắt: về thẳng nhà mình
		if lost > 0 then
			Remote.Notify(player, ("The goose got you! You lost %d unsealed chest(s)."):format(lost))
		else
			Remote.Notify(player, "The goose got you! Sent back home.")
		end
	end,
})

-- Báo động cướp nhà: gọi ngỗng đồn cảnh sát đuổi kẻ cướp
Robbery.SetAlarmHandler(function(thief)
	Guard.CallPolice(thief)
end)
Robbery.Init()

-- ===== Yêu cầu từ client (RemoteFunction "Action") =====
-- Mỗi hàm trả về: ok (bool), message (string hiện lên màn hình)
local actions = {
	GetData = function(player)
		return true, Data.Get(player)
	end,
	BuyRod = Shop.BuyRod,
	EquipRod = Shop.EquipRod,
	EquipPet = Shop.EquipPet,
	BuyFisherSlot = AutoFishers.UnlockSlot, -- mở ổ máy câu
	BuyAutoFisher = AutoFishers.Buy, -- (tierIndex) mua thẳng máy vào ổ trống
	UpgradeAutoFisher = AutoFishers.Upgrade, -- (slot) nâng tier tại chỗ
	BuyIncubator = Shop.BuyIncubator,
	BuyBagUpgrade = Shop.BuyBagUpgrade,
	BuyGear = Shop.BuyGear,
	RobTake = Robbery.Take, -- (ownerUserId, target, itemKey) lấy 1 món sau khi mở khóa
	BuyLock = Shop.BuyLock, -- nâng khóa cửa nhà lên cấp kế tiếp
	BuyKey = Shop.BuyKey, -- (số lượng) mua Chìa vạn năng
	StartHatch = Hatchery.StartHatch,
	OpenChest = Stash.OpenChest, -- (tên rương, all) mở 1 rương trong kho nhà, all = true thì mở hết loại đó
	OpenAllChests = Stash.OpenAll,
	SellEgg = Market.SellEgg,
	SellPet = Market.SellPet,
	-- "Lake": ra hồ (tốn tiền) / "Shop": tới Tool Shop / "Plot": về nhà (miễn phí, chặn khi có đồ hoặc bị đuổi). Luật ở Teleports.lua
	Teleport = function(player, where)
		if where == "Lake" then
			return Teleports.ToLake(player)
		elseif where == "Shop" then
			return Teleports.ToShop(player)
		elseif where == "Plot" then
			return Teleports.ToHome(player)
		end
		return false
	end,
}

Remote.Folder.Action.OnServerInvoke = function(player, action, ...)
	local handler = typeof(action) == "string" and actions[action]
	if not handler or not Data.Get(player) then
		return false, "Please wait..."
	end
	return handler(player, ...)
end

-- ===== Người chơi vào / ra =====
local function onPlayerAdded(player)
	if not Data.Load(player) then
		return
	end
	Plots.Assign(player)
	Fishing.SetupPlayer(player)
	Pets.SetupPlayer(player)
	Bag.SetupPlayer(player)

	-- Mỗi lần hồi sinh: về plot của mình
	local function goHome(character)
		character:WaitForChild("HumanoidRootPart")
		task.wait(0.1)
		Plots.TeleportHome(player)
	end
	player.CharacterAdded:Connect(goHome)
	if player.Character then
		task.spawn(goHome, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	Fishing.RemovePlayer(player)
	FishingSpots.RemovePlayer(player)
	Teleports.RemovePlayer(player)
	Pets.RemovePlayer(player)
	Bag.RemovePlayer(player)
	Hatchery.RemovePlayer(player)
	Robbery.RemovePlayer(player)
	Plots.Release(player)
	Data.Release(player)
end)

-- Lưu tất cả khi server tắt
game:BindToClose(function()
	Data.SaveAll()
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end
