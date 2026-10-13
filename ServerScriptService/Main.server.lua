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

local map = MapBuilder.Build()
Plots.Init(map, {
	OnIncubator = Hatchery.OnPrompt,
	OnFisher = AutoFishers.Collect,
})
Fishing.Init(map)
Shop.Init(map)
Market.Init(map)

-- ===== Yêu cầu từ client (RemoteFunction "Action") =====
-- Mỗi hàm trả về: ok (bool), message (string hiện lên màn hình)
local actions = {
	GetData = function(player)
		return true, Data.Get(player)
	end,
	BuyRod = Shop.BuyRod,
	EquipRod = Shop.EquipRod,
	BuyAutoFisher = Shop.BuyAutoFisher,
	BuyIncubator = Shop.BuyIncubator,
	StartHatch = Hatchery.StartHatch,
	SellEgg = Market.SellEgg,
	SellPet = Market.SellPet,
	Teleport = function(player, where)
		if where == "Plot" then
			return Plots.TeleportHome(player)
		elseif where == "Plaza" then
			return Plots.TeleportPlaza(player)
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
	Pets.RemovePlayer(player)
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
