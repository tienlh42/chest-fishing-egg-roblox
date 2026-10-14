-- ModuleScript: ServerScriptService > Modules > Teleports
-- Dịch chuyển bằng NÚT BẤM trên màn hình (không có bệ). Client gọi Action "Teleport":
--   "Lake" -> ToLake: tốn Config.Teleport.LakeCost coins, đáp xuống điểm vô hình "LakeArrival"
--            ở lối vào công viên GẦN NHÀ MÌNH NHẤT, quay mặt ra hồ. Không dùng được khi đang bị đuổi.
--   "Shop" -> ToShop: Config.Teleport.ShopCost (0 = miễn phí), đáp xuống điểm vô hình "ShopArrival" trước Tool Shop.
--   "Plot" -> ToHome: Config.Teleport.HomeCost coins, về thảm Home. (Bị bắt / hồi sinh thì Main tự đưa về nhà, miễn phí.)
--   Shop và Home BỊ CHẶN khi túi có đồ chưa cất hoặc đang bị ngỗng đuổi (phải tự chạy về, giữ rủi ro của game).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local Bag = require(script.Parent.Bag)
local Data = require(script.Parent.Data)
local Fishing = require(script.Parent.Fishing)
local Guard = require(script.Parent.Guard)
local Plots = require(script.Parent.Plots)

local Teleports = {}

local lakePads = {} -- các điểm đáp "LakeArrival" quanh hồ
local shopPad = nil -- điểm đáp "ShopArrival" trước Tool Shop
local shopFace = nil -- vị trí quầy Tool Shop (để quay mặt vào khi tới nơi)
local lastUse = {} -- [player] = os.clock() lần dịch chuyển gần nhất

local function onCooldown(player)
	local last = lastUse[player]
	return last ~= nil and os.clock() - last < Config.Teleport.Cooldown
end

-- Điểm đáp ở hồ gần nhà người chơi nhất
local function nearestLakePad(player)
	local home = Plots.HomePart(player)
	local from = home and home.Position or Vector3.zero
	local best, bestDist
	for _, pad in ipairs(lakePads) do
		local d = (pad.Position - from).Magnitude
		if not bestDist or d < bestDist then
			best, bestDist = pad, d
		end
	end
	return best
end

function Teleports.ToLake(player)
	if not Data.Get(player) then
		return false
	end
	if onCooldown(player) then
		return false, "Please wait a moment before teleporting again."
	end
	if Guard.IsChasing(player) then
		return false, "The goose is after you!"
	end
	local pad = nearestLakePad(player)
	if not pad then
		return false, "No teleporter at the lake."
	end
	local cost = Config.Teleport.LakeCost
	if not Data.Spend(player, cost) then
		return false, ("You need %d coins to teleport to the lake."):format(cost)
	end
	Fishing.Cancel(player)
	-- Đáp xuống, quay mặt ra giữa hồ
	local look = Vector3.new(0, pad.Position.Y, 0)
	local ok = Plots.Teleport(player, CFrame.lookAt(pad.Position, look) + Vector3.new(0, 4, 0))
	if not ok then
		Data.Get(player).Coins += cost -- dịch chuyển hỏng thì trả lại tiền
		Data.Update(player)
		return false
	end
	Data.Update(player)
	lastUse[player] = os.clock()
	return true, ("Teleported to the lake! (-%d coins)"):format(cost)
end

function Teleports.ToShop(player)
	if not Data.Get(player) then
		return false
	end
	if onCooldown(player) then
		return false, "Please wait a moment before teleporting again."
	end
	if Guard.IsChasing(player) then
		return false, "The goose is after you. Run home!"
	end
	if Bag.Count(player) > 0 then
		return false, "You're carrying loot! Run it home on foot."
	end
	if not shopPad then
		return false, "No teleporter at the Tool Shop."
	end
	local cost = Config.Teleport.ShopCost
	if cost > 0 and not Data.Spend(player, cost) then
		return false, ("You need %d coins to teleport to the Tool Shop."):format(cost)
	end
	Fishing.Cancel(player)
	local look = shopFace and Vector3.new(shopFace.X, shopPad.Position.Y, shopFace.Z) or Vector3.new(0, shopPad.Position.Y, 0)
	local ok = Plots.Teleport(player, CFrame.lookAt(shopPad.Position, look) + Vector3.new(0, 4, 0))
	if not ok then
		if cost > 0 then
			Data.Get(player).Coins += cost
		end
		return false
	end
	if cost > 0 then
		Data.Update(player)
	end
	lastUse[player] = os.clock()
	return true, cost > 0 and ("Teleported to the Tool Shop! (-%d coins)"):format(cost) or "Welcome to the Tool Shop!"
end

function Teleports.ToHome(player)
	if not Data.Get(player) then
		return false
	end
	if onCooldown(player) then
		return false, "Please wait a moment before teleporting again."
	end
	if Guard.IsChasing(player) then
		return false, "The goose is after you. Run home!"
	end
	if Bag.Count(player) > 0 then
		return false, "You're carrying loot! Run it home on foot."
	end
	local cost = Config.Teleport.HomeCost
	if cost > 0 and not Data.Spend(player, cost) then
		return false, ("You need %d coins to teleport home."):format(cost)
	end
	Fishing.Cancel(player)
	local ok, msg = Plots.TeleportHome(player)
	if not ok then
		if cost > 0 then
			Data.Get(player).Coins += cost -- dịch chuyển hỏng thì trả lại tiền
		end
		return false, msg
	end
	if cost > 0 then
		Data.Update(player)
	end
	lastUse[player] = os.clock()
	return true, cost > 0 and ("Welcome home! (-%d coins)"):format(cost) or nil
end

function Teleports.RemovePlayer(player)
	lastUse[player] = nil
end

function Teleports.Init(map)
	for _, d in ipairs(map:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "LakeArrival" then
			table.insert(lakePads, d)
		elseif d:IsA("BasePart") and d.Name == "ShopArrival" then
			shopPad = d
		end
	end
	local shop = map:FindFirstChild("ToolShop", true)
	local counter = shop and shop:FindFirstChild("PromptPart", true)
	shopFace = counter and counter.Position
	if #lakePads == 0 then
		warn("Teleports: map has no Part named LakeArrival")
	end
end

return Teleports
