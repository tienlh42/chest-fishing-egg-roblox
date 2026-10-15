-- ModuleScript: ServerScriptService > Modules > Robbery
-- Cướp nhà (ECONOMY_DESIGN mục 7, SYSTEM_DESIGN mục 9). Luồng:
--   1. Người khác bấm [F] "Pick lock" ở Stash / máy câu của chủ nhà đang ONLINE -> tiêu 1 Chìa vạn năng, mở với xác suất theo khóa cửa chủ nhà.
--   2. Mở được thì hiện bảng Rob: tự chọn từng món, giữ GrabTime giây (server đợi, phải đứng gần) rồi món vào TÚI của kẻ cướp (có Owner).
--   3. Lần thử đầu tiên báo động: chủ nhà nhận tin, ngỗng đồn cảnh sát được gọi (thêm 1 con mỗi lần lấy được món, tối đa Config.Guard.Police.MaxPerHeist).
--      Ở trong sân người khác quá TrespassTime giây thì ngỗng nhà rượt (hết giờ = "bị truy nã", xem Robbery.IsWanted).
--   4. Bị bắt / chết / thoát game: món cướp trả về kho chủ nhà (Bag.lua). Về nhà mình cất vào Stash thì thành của mình.
-- Mọi thứ chạy trên server; client chỉ gửi yêu cầu. Khóa theo plot (grabbing) để hai người không lấy trùng một món.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local Bag = require(script.Parent.Bag)
local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)
local Remote = require(script.Parent.Remote)
local SafeZone = require(script.Parent.SafeZone)

local Robbery = {}

local R = Config.Robbery
local MAX_GRAB_DISTANCE = 60 -- đứng xa Stash của chủ nhà quá số stud này lúc lấy thì hụt (plot 90x90, máy câu nằm mép ao)
local TICK = 0.5

local unlocked = {} -- [thief] = { [ownerUserId .. target] = true } mục tiêu đã mở khóa trong lượt này
local visits = {} -- [thief] = { OwnerId, Left (giây còn lại), Tries, Alerted } lượt vào sân hiện tại
local grabbing = {} -- [plot] = true khi đang có người lấy đồ (khóa theo plot)
local onAlarm = nil -- hàm(thief, owner) gọi khi báo động / lấy được món: Main nối với Guard.CallPolice

function Robbery.SetAlarmHandler(fn)
	onAlarm = fn
end

-- Ngỗng nhà có được rượt `player` trong sân của `owner` không: đã báo động (thử khóa) hoặc hết giờ trong sân
function Robbery.IsWanted(player, owner)
	local visit = visits[player]
	return visit ~= nil and visit.OwnerId == owner.UserId and (visit.Alerted or visit.Left <= 0)
end

-- Kẻ cướp bị bắt / kết thúc vụ: xóa trạng thái lượt vào sân và mở khóa
function Robbery.Reset(player)
	visits[player] = nil
	unlocked[player] = nil
	Remote.Effect(player, "Trespass", { Left = nil })
end

-- Lý do chủ nhà không bị cướp được lúc này, nil nếu cướp được
local function protectedReason(owner)
	local profile = Data.Get(owner)
	if not profile then
		return "That player is not here anymore."
	end
	if (profile.Tutorial or 99) < 99 then
		return "This player is still learning the game. Leave them alone!"
	end
	if profile.ShieldUntil > os.time() then
		return "This house was just robbed. It is shielded for now."
	end
	return nil
end

-- Danh sách món lấy được ở mục tiêu: { { Key, Label, Count } }
local function listItems(owner, target)
	local profile = Data.Get(owner)
	local list = {}
	if not profile then
		return list
	end
	if target == "Stash" then
		for i = #Config.Chests, 1, -1 do
			local name = Config.Chests[i].Name
			local count = profile.Chests[name] or 0
			if count > 0 then
				table.insert(list, { Key = "C:" .. name, Label = name, Count = count })
			end
		end
		for i = #Config.EggOrder, 1, -1 do
			local tier = Config.EggOrder[i]
			local count = profile.Eggs[tier] or 0
			if count > 0 then
				table.insert(list, { Key = "E:" .. tier, Label = tier .. " Egg", Count = count })
			end
		end
	else
		local slot = target:match("^Fisher(%d+)$")
		local entry = slot and profile.AutoFishers[slot]
		if entry then
			local stored = Config.AutoFisherStored(entry, os.time())
			if stored > 0 then
				local tier = Config.AutoFisher.Tiers[entry.Tier]
				table.insert(list, { Key = "M", Label = tier.Name .. " Auto-Fisher chest", Count = stored })
			end
		end
	end
	return list
end

local function openRobPanel(thief, owner, target, kind)
	Remote.Effect(thief, kind or "OpenPanel", {
		Panel = "Rob",
		Owner = owner.DisplayName,
		OwnerId = owner.UserId,
		Target = target,
		Items = listItems(owner, target),
	})
end

-- Báo động lần thử đầu tiên (dù mở được hay không)
local function alarm(thief, owner, visit)
	if visit.Alerted then
		return
	end
	visit.Alerted = true
	Remote.Notify(owner, ("ALERT! %s is trying to break into your house!"):format(thief.DisplayName))
	if onAlarm then
		onAlarm(thief, owner)
	end
end

-- Lượt vào sân hiện tại của kẻ cướp ở nhà của owner (tạo nếu chưa có, tick sẽ tự quản)
local function visitFor(thief, owner)
	local visit = visits[thief]
	if not visit or visit.OwnerId ~= owner.UserId then
		visit = { OwnerId = owner.UserId, Left = R.TrespassTime, Tries = 0, Alerted = false }
		visits[thief] = visit
	end
	return visit
end

-- Nút [F] ở Stash / máy câu của owner
function Robbery.OnPrompt(thief, owner, target)
	if thief == owner or not Data.Get(thief) then
		return
	end
	local reason = protectedReason(owner)
	if reason then
		Remote.Notify(thief, reason)
		return
	end
	-- phải đứng trong sân nhà đó (chống bấm từ xa)
	local hrp = thief.Character and thief.Character:FindFirstChild("HumanoidRootPart")
	local plot = Plots.PlotOf(owner)
	if not (hrp and plot and SafeZone.PlotAt(hrp.Position) == plot) then
		return
	end

	local lockKey = owner.UserId .. ":" .. target
	unlocked[thief] = unlocked[thief] or {}
	if unlocked[thief][lockKey] then
		openRobPanel(thief, owner, target)
		return
	end

	local visit = visitFor(thief, owner)
	local profile = Data.Get(thief)
	if visit.Tries >= R.MaxTries then
		Remote.Notify(thief, "Too many failed tries here. Come back later!")
		return
	end
	if profile.Keys < 1 then
		Remote.Notify(thief, "You need a Master Key! Buy one at the Tool Shop.")
		return
	end

	profile.Keys -= 1
	visit.Tries += 1
	Data.Update(thief)
	alarm(thief, owner, visit)

	local lock = Config.LockInfo(Data.Get(owner).LockLevel) or Config.LockInfo(0)
	if math.random() < lock.OpenChance then
		unlocked[thief][lockKey] = true
		Remote.Notify(thief, "Click! The lock opened.")
		openRobPanel(thief, owner, target)
	else
		Remote.Notify(thief, ("The lock held! (%d%% chance, %d key%s left)"):format(math.floor(lock.OpenChance * 100 + 0.5), profile.Keys, profile.Keys == 1 and "" or "s"))
	end
end

-- Lấy 1 món (Action "RobTake"(ownerUserId, target, itemKey)). Đợi GrabTime giây trên server
function Robbery.Take(thief, ownerId, target, itemKey)
	if typeof(ownerId) ~= "number" or typeof(target) ~= "string" or typeof(itemKey) ~= "string" then
		return false, "Invalid request."
	end
	local owner = Players:GetPlayerByUserId(ownerId)
	local plot = owner and Plots.PlotOf(owner)
	if not (owner and plot and owner ~= thief) then
		return false, "That player is not here anymore."
	end
	if not (unlocked[thief] and unlocked[thief][ownerId .. ":" .. target]) then
		return false, "The lock is still closed."
	end
	if grabbing[plot] then
		return false, "Someone is already grabbing loot here!"
	end
	if Bag.IsFull(thief) then
		return false, "Your bag is full! Run home and stash your loot first."
	end

	local function near()
		local hrp = thief.Character and thief.Character:FindFirstChild("HumanoidRootPart")
		local humanoid = thief.Character and thief.Character:FindFirstChildOfClass("Humanoid")
		return hrp and humanoid and humanoid.Health > 0 and (hrp.Position - (Plots.StashPosition(owner) or hrp.Position)).Magnitude <= MAX_GRAB_DISTANCE
			and SafeZone.PlotAt(hrp.Position) == plot
	end

	grabbing[plot] = true
	Remote.Notify(thief, "Grabbing... stay close!")
	task.wait(R.GrabTime)
	grabbing[plot] = nil

	if not (owner.Parent and Plots.PlotOf(owner) == plot and thief.Parent) then
		return false, "The owner left!"
	end
	if not near() then
		return false, "You moved away. The grab failed."
	end
	if Bag.IsFull(thief) then
		return false, "Your bag is full!"
	end

	-- Lấy thật: trừ khỏi chủ nhà, đưa vào túi kẻ cướp (kiểm tra còn hàng NGAY LÚC này)
	local profile = Data.Get(owner)
	local item = nil
	if itemKey:sub(1, 2) == "C:" and target == "Stash" then
		local name = itemKey:sub(3)
		if Config.FindChest(name) and (profile.Chests[name] or 0) > 0 then
			profile.Chests[name] -= 1
			item = { Chest = name, Owner = owner }
		end
	elseif itemKey:sub(1, 2) == "E:" and target == "Stash" then
		local tier = itemKey:sub(3)
		if Config.Eggs[tier] and (profile.Eggs[tier] or 0) > 0 then
			profile.Eggs[tier] -= 1
			item = { Egg = tier, Owner = owner }
		end
	elseif itemKey == "M" then
		local slot = target:match("^Fisher(%d+)$")
		local entry = slot and profile.AutoFishers[slot]
		if entry then
			entry.Stored, entry.Last = Config.AutoFisherStored(entry, os.time()) -- chốt kho theo thời gian rồi mới trừ
			if entry.Stored > 0 then
				entry.Stored -= 1
				item = { Chest = Config.RollChest(Config.AutoFisher.Tiers[entry.Tier].Odds).Name, Owner = owner }
			end
		end
	end
	if not item then
		openRobPanel(thief, owner, target, "RobUpdate")
		return false, "Too late, it's gone!"
	end
	Bag.Add(thief, item)
	if onAlarm then
		onAlarm(thief, owner) -- thêm 1 ngỗng đồn mỗi món lấy được (Guard giới hạn tối đa)
	end

	-- bị cướp: khiên cho chủ nhà (chặn những lần thử mới)
	if profile.ShieldUntil <= os.time() then
		profile.ShieldUntil = os.time() + R.ShieldTime
		Remote.Notify(owner, ("%s stole from your house! Your house is shielded for %d minutes."):format(thief.DisplayName, R.ShieldTime // 60))
	end
	Data.Update(owner)
	Plots.UpdateLabels(owner)
	openRobPanel(thief, owner, target, "RobUpdate")
	return true, "Got it! Run home and stash it before the goose catches you!"
end

-- Mỗi nửa giây: ai đứng trong sân người khác thì đếm ngược; ra ngoài thì hồi dần (1 giây mỗi 2 giây ở ngoài)
local function tick()
	for _, thief in ipairs(Players:GetPlayers()) do
		local hrp = thief.Character and thief.Character:FindFirstChild("HumanoidRootPart")
		local plot = hrp and SafeZone.PlotAt(hrp.Position)
		local plotOwner = plot and Plots.OwnerOf(plot)
		local inside = plotOwner ~= nil and plotOwner ~= thief
		local visit = visits[thief]

		if inside then
			if not visit or visit.OwnerId ~= plotOwner.UserId then
				visit = visitFor(thief, plotOwner)
			end
			visit.Left -= TICK
			Remote.Effect(thief, "Trespass", { Left = math.max(visit.Left, 0), Owner = plotOwner.DisplayName })
			if visit.Left <= 0 and not visit.Expired then
				visit.Expired = true -- hết giờ: ngỗng nhà bắt đầu rượt (Robbery.IsWanted)
				Remote.Notify(thief, ("Time's up! %s's goose is after you!"):format(plotOwner.DisplayName))
			end
		elseif visit then
			visit.Left = math.min(R.TrespassTime, visit.Left + TICK / 2)
			if visit.Left > 0 then
				visit.Expired = false
			end
			if Players:GetPlayerByUserId(visit.OwnerId) == nil or visit.Left >= R.TrespassTime then
				visits[thief] = nil
				unlocked[thief] = nil
				Remote.Effect(thief, "Trespass", { Left = nil })
			else
				Remote.Effect(thief, "Trespass", { Left = visit.Left, Owner = nil, Outside = true })
			end
		end
	end
end

function Robbery.Init()
	task.spawn(function()
		while true do
			task.wait(TICK)
			tick()
		end
	end)
end

function Robbery.RemovePlayer(player)
	visits[player] = nil
	unlocked[player] = nil
end

return Robbery
