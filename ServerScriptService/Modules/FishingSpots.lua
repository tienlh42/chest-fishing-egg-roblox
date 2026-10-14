-- ModuleScript: ServerScriptService > Modules > FishingSpots
-- Điểm câu trên hồ cấm:
--   - Map có các Part "FishingSpot" (ParkBuilder đặt 6 cái). File này dựng phao nổi + bảng chữ cho từng điểm.
--   - Rương KHÔNG có sẵn. Cứ mỗi 0.5 giây, điểm nằm phía TRƯỚC ngỗng đang tuần tra (còn <= SpawnAhead stud) có xác suất
--     SpawnChance hiện rương, tối đa MaxActive rương cùng lúc; rương không ai câu thì biến mất sau Lifetime giây.
--   - Ném phao cách điểm <= Config.Spots.Radius mới móc được. Mỗi điểm chỉ 1 người móc (Claim).
--   - Ngỗng đi ngang điểm nào thì ghi lại (PassedAt). Câu ở điểm vừa được ngỗng đi ngang (<= ReturnWindow giây) mà ngỗng chưa
--     đi xa (Guard.ReturnRange) thì ngỗng quay lại đuổi (Guard.Recall).
--   - Lấy được hoặc hụt -> điểm nghỉ Config.Spots.RespawnTime giây rồi mới được ra rương lại.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local BuildUtil = require(script.Parent.BuildUtil)
local Guard = require(script.Parent.Guard)

local cfg = Config.Spots

local FishingSpots = {}

local spots = {} -- { Part, Active, SpawnedAt, PassedAt, Owner, RestUntil, Ring, Pole, Gui, Label, Bubbles }

local STYLE = { Text = "CHEST", Color = Color3.fromRGB(255, 200, 60) }

local function flatDistance(a, b)
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- Cập nhật phao theo trạng thái: chưa có rương thì ẩn hẳn, có rương thì hiện phao + chữ
local function render(spot)
	local on = spot.Active
	spot.Ring.Transparency = on and 0 or 1
	spot.Pole.Transparency = on and 0 or 1
	spot.Bubbles.Enabled = on
	spot.Gui.Enabled = on
	if on then
		spot.Label.Text = spot.Owner and (STYLE.Text .. "\n(being reeled)") or STYLE.Text
		spot.Label.TextColor3 = STYLE.Color
		spot.Ring.Color = STYLE.Color
	end
end

local function buildBuoy(part)
	local folder = Instance.new("Folder")
	folder.Name = "SpotBuoy"
	local pos = part.Position
	-- vòng phao nổi trên mặt nước + cọc giữa
	local ring = BuildUtil.cylinder(folder, "SpotRing", 0.4, 3.2, CFrame.new(pos.X, 0.15, pos.Z), Color3.new(1, 1, 1), Enum.Material.Neon)
	ring.CanCollide = false
	ring.CanQuery = false
	local pole = BuildUtil.block(folder, "SpotPole", Vector3.new(0.3, 2.2, 0.3), CFrame.new(pos.X, 1.2, pos.Z), Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic)
	pole.CanCollide = false
	pole.CanQuery = false
	-- bong bóng nổi lên khi có mục tiêu
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Color = ColorSequence.new(Color3.fromRGB(220, 245, 255))
	bubbles.Size = NumberSequence.new(0.4, 0)
	bubbles.Lifetime = NumberRange.new(0.6, 1.2)
	bubbles.Speed = NumberRange.new(2, 4)
	bubbles.SpreadAngle = Vector2.new(25, 25)
	bubbles.Rate = 8
	bubbles.Parent = ring
	-- bảng chữ CHEST / Resting
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(6, 2.2)
	gui.StudsOffset = Vector3.new(0, 3.5, 0)
	gui.MaxDistance = 140
	gui.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextStrokeTransparency = 0
	label.Parent = gui
	gui.Parent = pole
	folder.Parent = part.Parent
	return ring, pole, gui, label, bubbles
end

-- Điểm có rương gần điểm rơi phao nhất. Trả về spot, hoặc nil + lý do (tiếng Anh, hiện cho người chơi)
function FishingSpots.Claim(player, landing)
	local best, bestDist
	for _, spot in ipairs(spots) do
		local d = flatDistance(spot.Part.Position, landing)
		if spot.Active and d <= cfg.Radius and (not bestDist or d < bestDist) then
			best, bestDist = spot, d
		end
	end
	if not best then
		return nil, "Nothing bites here. Cast near a bubbling CHEST spot!"
	end
	if best.Owner and best.Owner ~= player then
		return nil, "Someone else is reeling this spot!"
	end
	best.Owner = player
	render(best)
	-- Ngỗng vừa đi ngang điểm này mà chưa đi xa: nó quay lại đuổi
	if best.PassedAt and os.clock() - best.PassedAt <= cfg.ReturnWindow then
		Guard.Recall(player, best.Part.Position)
	end
	return best
end

-- Hết lượt câu (lấy được hoặc hụt): rương biến mất, điểm nghỉ rồi mới ra rương lại
function FishingSpots.Release(spot)
	if not spot then
		return
	end
	spot.Owner = nil
	spot.Active = false
	spot.PassedAt = nil
	spot.RestUntil = os.clock() + cfg.RespawnTime
	render(spot)
end

-- Điểm này nằm phía trước một con ngỗng đang tuần tra (trong góc ~60 độ trước mặt, cách SpawnMinDist..SpawnAhead stud)?
local function aheadOfGoose(position, geese)
	for _, g in ipairs(geese) do
		if g.State == "Patrol" then
			local offset = Vector3.new(position.X - g.Position.X, 0, position.Z - g.Position.Z)
			local look = Vector3.new(g.Look.X, 0, g.Look.Z)
			if offset.Magnitude >= cfg.SpawnMinDist and offset.Magnitude <= cfg.SpawnAhead and look.Magnitude > 0.1 then
				if look.Unit:Dot(offset.Unit) >= 0.5 then
					return true
				end
			end
		end
	end
	return false
end

-- Mỗi 0.5 giây: ghi nhận ngỗng đi ngang, cho rương hết hạn biến mất, ra rương ngẫu nhiên phía trước ngỗng
local function update()
	local now = os.clock()
	local geese = Guard.Positions()
	local activeCount = 0
	for _, spot in ipairs(spots) do
		if spot.Active then
			activeCount += 1
		end
	end
	for _, spot in ipairs(spots) do
		local position = spot.Part.Position
		for _, g in ipairs(geese) do
			if flatDistance(g.Position, position) <= cfg.PassRadius then
				spot.PassedAt = now
			end
		end
		if spot.Active then
			if not spot.Owner and now - spot.SpawnedAt > cfg.Lifetime then
				spot.Active = false
				spot.PassedAt = nil
				activeCount -= 1
				render(spot)
			end
		elseif activeCount < cfg.MaxActive and not (spot.RestUntil and now < spot.RestUntil) then
			if aheadOfGoose(position, geese) and math.random() < cfg.SpawnChance then
				spot.Active = true
				spot.SpawnedAt = now
				spot.PassedAt = nil -- rương mới: chưa có ngỗng nào "vừa đi ngang"
				activeCount += 1
				render(spot)
			end
		end
	end
end

function FishingSpots.Init(map)
	for _, d in ipairs(map:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "FishingSpot" then
			local ring, pole, gui, label, bubbles = buildBuoy(d)
			local spot = { Part = d, Active = false, Ring = ring, Pole = pole, Gui = gui, Label = label, Bubbles = bubbles }
			table.insert(spots, spot)
			render(spot)
		end
	end
	if #spots == 0 then
		warn("FishingSpots: map has no Part named FishingSpot (lake fishing disabled)")
	end
	task.spawn(function()
		while true do
			task.wait(0.5)
			local ok, err = pcall(update)
			if not ok then
				warn("FishingSpots:", err)
			end
		end
	end)
end

-- Người chơi rời game giữa chừng: trả điểm (Fishing.Cancel đã gọi Release; đây là lưới an toàn)
function FishingSpots.RemovePlayer(player)
	for _, spot in ipairs(spots) do
		if spot.Owner == player then
			FishingSpots.Release(spot)
		end
	end
end

return FishingSpots
