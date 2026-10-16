-- ModuleScript: ServerScriptService > Modules > ParkBuilder
-- Công viên hồ trong khu dân cư (xem docs/World/PARK_REDESIGN.md):
--   nền Terrain cỏ thấp, hồ nước thật hình chữ nhật bo góc, bờ kè, lối gạch + lan can + đèn ôm quanh hồ,
--   4 lối phụ, đường vòng quanh công viên, 2 quảng trường, cây non có cọc chống, cây tán lớn, nhà bảo vệ.
-- Hồ là "Lake" (hồ cấm, ngỗng tuần tra) – KHÔNG phải vùng an toàn.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local BuildUtil = require(script.Parent.BuildUtil)

local block, ball, cylinder, marker, decor = BuildUtil.block, BuildUtil.ball, BuildUtil.cylinder, BuildUtil.marker, BuildUtil.decor
local C = BuildUtil.Colors

local ParkBuilder = {}

-- ===== Kích thước =====
local LAKE_CENTER = Vector3.zero -- hồ nằm chính giữa map, các nhà xếp vòng tròn quanh hồ
local HX, HZ, R = 65, 45, 22 -- nửa chiều rộng (x), nửa chiều dài (z), bán kính bo góc
local PARK_MIN, PARK_MAX = Vector2.new(-110, -80), Vector2.new(110, 80) -- vùng công viên (x, z)
local RING_R, RING_W = 150, 10 -- đường vòng quanh công viên (bán kính tâm đường, bề rộng)

-- Lớp quanh hồ, tính từ mép nước ra ngoài (stud)
local WALL_D, WALL_W = 0.6, 1.2 -- bờ kè
local RAIL_D = 1.8 -- lan can
local WALK_D, WALK_W = 4.2, 6 -- tâm + bề rộng lối gạch
local LAMP_D = 9.5 -- đèn, ghế

-- Độ cao mặt trên của từng loại nền (khác nhau để không nhấp nháy khi chồng lên nhau)
local LAWN = Enum.Material.LeafyGrass -- nền cỏ toàn map
-- Terrain làm tròn theo ô 4 stud nên mặt ĐẤT hiện cao hơn vùng fill 2 stud (mặt NƯỚC thì không).
-- Fill đất thấp xuống 2 stud để mặt cỏ nằm đúng y = 0. Nước giữ nguyên (mặt nước = đỉnh vùng fill = 0).
local TERRAIN_SHIFT = -2
ParkBuilder.TerrainShift = TERRAIN_SHIFT

local TOP_ROAD, TOP_PATH, TOP_WALK, TOP_SQUARE, TOP_SIDEWALK = 0.25, 0.3, 0.35, 0.4, 0.45

ParkBuilder.LakeCenter = LAKE_CENTER
ParkBuilder.RingRadius = RING_R

-- ===== Hình học chữ nhật bo góc =====

-- Khoảng cách có dấu từ (x, z) tới mép hồ: âm = trong hồ
local function lakeSdf(x, z)
	local qx = math.abs(x - LAKE_CENTER.X) - (HX - R)
	local qz = math.abs(z - LAKE_CENTER.Z) - (HZ - R)
	local outside = Vector2.new(math.max(qx, 0), math.max(qz, 0)).Magnitude
	return outside + math.min(math.max(qx, qz), 0) - R
end

-- Các điểm của đường viền hồ dời ra ngoài d stud (vòng khép kín)
local function outline(d, cornerSteps)
	local ax, az = HX - R, HZ - R
	local rr = R + d
	local pts = {}
	for _, c in ipairs({ { ax, az, 0 }, { -ax, az, 90 }, { -ax, -az, 180 }, { ax, -az, 270 } }) do
		for s = 0, cornerSteps do
			local a = math.rad(c[3] + 90 * s / cornerSteps)
			table.insert(pts, Vector3.new(LAKE_CENTER.X + c[1] + math.cos(a) * rr, 0, LAKE_CENTER.Z + c[2] + math.sin(a) * rr))
		end
	end
	return pts
end

-- Dải Part chạy theo đường viền (lối đi, bờ kè...). skip(mid) = true thì bỏ đoạn đó
local function band(parent, name, pts, width, height, topY, color, material, skip)
	for i = 1, #pts do
		local a, b = pts[i], pts[i % #pts + 1]
		local mid = (a + b) / 2
		local len = (b - a).Magnitude
		if len > 0.05 and not (skip and skip(mid)) then
			local y = topY - height / 2
			local cf = CFrame.lookAt(Vector3.new(mid.X, y, mid.Z), Vector3.new(b.X, y, b.Z))
			block(parent, name, Vector3.new(width, height, len + 0.8), cf, color, material)
		end
	end
end

-- Lấy điểm cách đều nhau dọc đường viền. Trả về { Pos, Dir }
local function sample(pts, spacing, startAt)
	local out = {}
	local t = startAt or 0
	for i = 1, #pts do
		local a, b = pts[i], pts[i % #pts + 1]
		local seg = b - a
		local len = seg.Magnitude
		if len > 0.001 then
			while t < len do
				table.insert(out, { Pos = a + seg.Unit * t, Dir = seg.Unit })
				t += spacing
			end
			t -= len
		end
	end
	return out
end

-- ===== Vùng chừa trống (lối vào, quảng trường, nhà bảo vệ) =====
local SQUARE_EAST = Vector3.new(92, 0, 0)
local SQUARE_SOUTH = Vector3.new(0, 0, 66)
local GUARD_HOUSE = Vector3.new(-92, 0, -64)

-- 6 điểm câu (trong nước, cách bờ ~10 stud, đứng trên lối gạch nhắm vào là trúng). Không đặt ở 4 lối vào trục chính.
local SPOTS = {
	Vector3.new(-30, 0, -34.5),
	Vector3.new(30, 0, -34.5),
	Vector3.new(-30, 0, 34.5),
	Vector3.new(30, 0, 34.5),
	Vector3.new(54.5, 0, 15),
	Vector3.new(-54.5, 0, -15),
}

local function onPathOrSquare(x, z, margin)
	margin = margin or 0
	if math.abs(x) < 6 + margin and math.abs(z) > HZ then
		return true -- lối Bắc, Nam
	end
	if math.abs(z) < 6 + margin and math.abs(x) > HX then
		return true -- lối Đông, Tây
	end
	for _, sq in ipairs({ SQUARE_EAST, SQUARE_SOUTH }) do
		if math.abs(x - sq.X) < 13 + margin and math.abs(z - sq.Z) < 13 + margin then
			return true -- quảng trường
		end
	end
	if math.abs(x - GUARD_HOUSE.X) < 9 + margin and math.abs(z - GUARD_HOUSE.Z) < 8 + margin then
		return true -- nhà bảo vệ
	end
	return false
end

-- ===== Terrain: nền cỏ thấp + hồ =====
local function buildTerrain()
	local terrain = workspace.Terrain
	-- Cỏ thấp phẳng: dùng LeafyGrass thay vì Grass (Roblox chỉ mọc cỏ cao lay động trên chất liệu Grass,
	-- và script không được tắt Terrain.Decoration).
	terrain:FillBlock(CFrame.new(0, -8 + TERRAIN_SHIFT, 0), Vector3.new(720, 16, 720), LAWN)

	-- Lòng hồ = 1 chữ thập + 4 trụ ở góc, nới thêm 1.5 stud (phần thừa nằm dưới bờ kè)
	local pad = 1.5
	local hx, hz, r = HX + pad, HZ + pad, R + pad
	local function fillShape(y, height, material)
		terrain:FillBlock(CFrame.new(LAKE_CENTER.X, y, LAKE_CENTER.Z), Vector3.new(hx * 2, height, (hz - r) * 2), material)
		terrain:FillBlock(CFrame.new(LAKE_CENTER.X, y, LAKE_CENTER.Z), Vector3.new((hx - r) * 2, height, hz * 2), material)
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				terrain:FillCylinder(CFrame.new(LAKE_CENTER.X + sx * (hx - r), y, LAKE_CENTER.Z + sz * (hz - r)), height, r, material)
			end
		end
	end
	fillShape(-9 + TERRAIN_SHIFT, 2, Enum.Material.Sand) -- đáy cát
	-- Nước không ghi đè được lên đất đặc -> đào trống (Air) trước rồi mới đổ nước
	fillShape(-4, 8, Enum.Material.Air)
	fillShape(-4, 8, Enum.Material.Water)

	-- Nước xanh ngọc, có sóng và phản chiếu
	terrain.WaterColor = Color3.fromRGB(25, 150, 190)
	terrain.WaterTransparency = 0.35
	terrain.WaterReflectance = 0.6
	terrain.WaterWaveSize = 0.2
	terrain.WaterWaveSpeed = 12
	terrain:SetMaterialColor(LAWN, Color3.fromRGB(105, 170, 75))
	terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(235, 215, 160))
end

-- ===== Hồ: bờ kè, lối gạch, lan can, đèn, ghế, cầu tàu =====
local function buildLake(map)
	local lake = Instance.new("Model")
	lake.Name = "Lake"

	-- Part vô hình đánh dấu vùng nước cho logic câu cá (nước thật là Terrain)
	marker(lake, "Water", Vector3.new(HX * 2, 1, HZ * 2), CFrame.new(LAKE_CENTER.X, -0.5, LAKE_CENTER.Z))

	-- Bờ kè đá + lối gạch
	band(lake, "Embankment", outline(WALL_D, 8), WALL_W, 2.2, 0.5, Color3.fromRGB(150, 150, 150), Enum.Material.Concrete)
	band(lake, "Walkway", outline(WALK_D, 12), WALK_W, 0.5, TOP_WALK, C.Brick, Enum.Material.Pavement)

	-- Lan can liền một vòng: cột mỗi 4 stud + 2 thanh ngang. Người chơi đứng trên lối gạch câu qua lan can.
	local rail = Instance.new("Folder")
	rail.Name = "Railing"
	local posts = sample(outline(RAIL_D, 12), 4)
	for i, p in ipairs(posts) do
		block(rail, "RailPost", Vector3.new(0.25, 2.6, 0.25), CFrame.new(p.Pos + Vector3.new(0, TOP_WALK + 1.3, 0)), C.Iron, Enum.Material.Metal)
		local a, b = p.Pos, posts[i % #posts + 1].Pos
		for _, h in ipairs({ 1.3, 2.5 }) do
			local y = TOP_WALK + h
			local mid = (a + b) / 2
			block(rail, "Rail", Vector3.new(0.15, 0.15, (b - a).Magnitude), CFrame.lookAt(Vector3.new(mid.X, y, mid.Z), Vector3.new(b.X, y, b.Z)), C.Iron, Enum.Material.Metal)
		end
	end
	rail.Parent = lake

	-- Đèn và ghế xen kẽ ở mép ngoài lối đi, ghế nhìn ra hồ
	local park = Instance.new("Folder")
	park.Name = "Park"
	for i, p in ipairs(sample(outline(LAMP_D, 12), 12, 6)) do
		local pos = p.Pos
		if not onPathOrSquare(pos.X, pos.Z, 1) then
			if i % 2 == 1 then
				BuildUtil.lamp(park, pos)
			else
				BuildUtil.bench(park, CFrame.lookAt(pos, Vector3.new(LAKE_CENTER.X, 0, LAKE_CENTER.Z)))
			end
		end
	end

	-- Điểm câu (marker vô hình, FishingSpots.lua dựng phao + logic)
	for i, pos in ipairs(SPOTS) do
		local spotMarker = marker(lake, "FishingSpot", Vector3.new(2, 1, 2), CFrame.new(pos + Vector3.new(0, 0.25, 0)))
		spotMarker:SetAttribute("Index", i)
	end

	park.Parent = lake
	lake.Parent = map
end

-- ===== Cây =====

-- Cây non: thân mảnh, tán nhỏ, 3 cọc chống nghiêng
local function youngTree(parent, pos, rng)
	block(parent, "Trunk", Vector3.new(0.5, 6, 0.5), CFrame.new(pos + Vector3.new(0, 3, 0)), C.DarkWood, Enum.Material.Wood)
	decor(ball(parent, "Leaves", rng:NextNumber(4, 5.5), pos + Vector3.new(0, 6.5, 0), Color3.fromRGB(110, 180, 80), Enum.Material.Grass))
	for k = 0, 2 do
		local a = math.rad(k * 120 + 30)
		local foot = pos + Vector3.new(math.cos(a) * 1.2, 0, math.sin(a) * 1.2)
		local top = pos + Vector3.new(0, 3.5, 0)
		local mid = (foot + top) / 2
		decor(block(parent, "Stake", Vector3.new(0.15, 0.15, (top - foot).Magnitude), CFrame.lookAt(mid, top), Color3.fromRGB(190, 160, 110), Enum.Material.Wood))
	end
end

-- Cây tán lớn dọc vỉa hè
local function shadeTree(parent, pos)
	block(parent, "Trunk", Vector3.new(1.6, 9, 1.6), CFrame.new(pos + Vector3.new(0, 4.5, 0)), C.DarkWood, Enum.Material.Wood)
	ball(parent, "Leaves", 11, pos + Vector3.new(0, 11, 0), Color3.fromRGB(55, 130, 60), Enum.Material.Grass)
	ball(parent, "Leaves", 8, pos + Vector3.new(2.5, 13, 1.5), Color3.fromRGB(65, 145, 65), Enum.Material.Grass)
end

-- ===== Lối phụ, quảng trường, vỉa hè, nhà bảo vệ =====
local function flowerBed(parent, cframe, rng)
	block(parent, "Planter", Vector3.new(4, 1, 4), cframe * CFrame.new(0, 0.5, 0), Color3.fromRGB(160, 90, 60), Enum.Material.Brick)
	block(parent, "Soil", Vector3.new(3.4, 0.2, 3.4), cframe * CFrame.new(0, 1.05, 0), Color3.fromRGB(90, 60, 40), Enum.Material.Ground)
	local colors = { Color3.fromRGB(255, 120, 160), Color3.fromRGB(255, 220, 80), Color3.fromRGB(180, 130, 255), Color3.fromRGB(255, 255, 255) }
	for _ = 1, 5 do
		local offset = Vector3.new(rng:NextNumber(-1.2, 1.2), 1.5, rng:NextNumber(-1.2, 1.2))
		decor(ball(parent, "Flower", 0.8, (cframe * CFrame.new(offset)).Position, colors[rng:NextInteger(1, #colors)], Enum.Material.Neon))
	end
end

local function trashBin(parent, pos)
	cylinder(parent, "TrashBin", 2.4, 1.4, CFrame.new(pos + Vector3.new(0, 1.2, 0)), Color3.fromRGB(40, 100, 60), Enum.Material.Metal)
end

local function square(parent, center, rng)
	block(parent, "Square", Vector3.new(22, 0.5, 22), CFrame.new(center + Vector3.new(0, TOP_SQUARE - 0.25, 0)), Color3.fromRGB(215, 145, 105), Enum.Material.Pavement)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			flowerBed(parent, CFrame.new(center + Vector3.new(sx * 8, TOP_SQUARE, sz * 8)), rng)
		end
		-- 2 ghế nhìn vào giữa quảng trường
		local seat = center + Vector3.new(sx * 6, TOP_SQUARE, 0)
		BuildUtil.bench(parent, CFrame.lookAt(seat, center + Vector3.new(0, TOP_SQUARE, 0)))
	end
	trashBin(parent, center + Vector3.new(0, TOP_SQUARE, 9))
	BuildUtil.lamp(parent, center + Vector3.new(0, TOP_SQUARE, -9))
end

local function guardHouse(parent, center)
	local white = Color3.fromRGB(235, 240, 245)
	block(parent, "GuardFloor", Vector3.new(12, 0.6, 10), CFrame.new(center + Vector3.new(0, 0.3, 0)), C.Concrete, Enum.Material.Concrete)
	block(parent, "GuardWallBack", Vector3.new(12, 7, 0.6), CFrame.new(center + Vector3.new(0, 4.1, -4.7)), white, Enum.Material.Plaster)
	for _, x in ipairs({ -5.7, 5.7 }) do
		block(parent, "GuardWallSide", Vector3.new(0.6, 7, 10), CFrame.new(center + Vector3.new(x, 4.1, 0)), white, Enum.Material.Plaster)
	end
	block(parent, "GuardWallFront", Vector3.new(4, 7, 0.6), CFrame.new(center + Vector3.new(-4, 4.1, 4.7)), white, Enum.Material.Plaster)
	block(parent, "GuardWallFront", Vector3.new(4, 7, 0.6), CFrame.new(center + Vector3.new(4, 4.1, 4.7)), white, Enum.Material.Plaster)
	local window = block(parent, "GuardWindow", Vector3.new(6, 2.5, 0.2), CFrame.new(center + Vector3.new(0, 5, -5.05)), Color3.fromRGB(170, 210, 240), Enum.Material.Glass)
	window.Transparency = 0.3
	local roof = block(parent, "GuardRoof", Vector3.new(14, 0.8, 12), CFrame.new(center + Vector3.new(0, 8, 0)), Color3.fromRGB(60, 160, 170), Enum.Material.Metal)
	BuildUtil.billboard(roof, "GOOSE SECURITY", 2.5, 12)
end

local function buildGrounds(map)
	local grounds = Instance.new("Folder")
	grounds.Name = "ParkGrounds"
	local rng = Random.new(7)
	local walkOuter = WALK_D + WALK_W / 2

	-- Vỉa hè bao quanh công viên
	local sx, sz = PARK_MAX.X + 1.5, (PARK_MIN.Y + PARK_MAX.Y) / 2
	block(grounds, "Sidewalk", Vector3.new(PARK_MAX.X * 2 + 6, 0.5, 3), CFrame.new(0, TOP_SIDEWALK - 0.25, PARK_MIN.Y - 1.5), C.Concrete, Enum.Material.Concrete)
	block(grounds, "Sidewalk", Vector3.new(PARK_MAX.X * 2 + 6, 0.5, 3), CFrame.new(0, TOP_SIDEWALK - 0.25, PARK_MAX.Y + 1.5), C.Concrete, Enum.Material.Concrete)
	for _, side in ipairs({ -1, 1 }) do
		block(grounds, "Sidewalk", Vector3.new(3, 0.5, PARK_MAX.Y - PARK_MIN.Y), CFrame.new(side * sx, TOP_SIDEWALK - 0.25, sz), C.Concrete, Enum.Material.Concrete)
	end

	-- 4 lối phụ từ lối gạch quanh hồ ra vỉa hè (Bắc, Nam, Đông, Tây)
	local northEdge = LAKE_CENTER.Z - HZ - walkOuter
	local southEdge = LAKE_CENTER.Z + HZ + walkOuter
	local eastEdge = LAKE_CENTER.X + HX + walkOuter
	local westEdge = LAKE_CENTER.X - HX - walkOuter
	local y = TOP_PATH - 0.25
	block(grounds, "Path", Vector3.new(6, 0.5, northEdge - PARK_MIN.Y), CFrame.new(0, y, (northEdge + PARK_MIN.Y) / 2), C.Brick, Enum.Material.Pavement)
	block(grounds, "Path", Vector3.new(6, 0.5, PARK_MAX.Y - southEdge), CFrame.new(0, y, (southEdge + PARK_MAX.Y) / 2), C.Brick, Enum.Material.Pavement)
	block(grounds, "Path", Vector3.new(PARK_MAX.X - eastEdge, 0.5, 6), CFrame.new((eastEdge + PARK_MAX.X) / 2, y, 0), C.Brick, Enum.Material.Pavement)
	block(grounds, "Path", Vector3.new(westEdge - PARK_MIN.X, 0.5, 6), CFrame.new((westEdge + PARK_MIN.X) / 2, y, 0), C.Brick, Enum.Material.Pavement)

	square(grounds, SQUARE_EAST, rng)
	square(grounds, SQUARE_SOUTH, rng)
	guardHouse(grounds, GUARD_HOUSE)

	-- 4 điểm đáp VÔ HÌNH "LakeArrival" ở 4 lối vào: bấm nút "Lake" thì đáp xuống điểm gần nhà mình nhất
	for _, pos in ipairs({ Vector3.new(0, 0, -62), SQUARE_SOUTH, SQUARE_EAST, Vector3.new(-84, 0, 0) }) do
		marker(grounds, "LakeArrival", Vector3.new(4, 1, 4), CFrame.new(pos + Vector3.new(0, 0.5, 0)))
	end

	local signZ = PARK_MIN.Y + 1
	local sign = block(grounds, "ParkSign", Vector3.new(14, 3, 0.6), CFrame.new(10, 3.5, signZ), C.DarkWood, Enum.Material.Wood)
	BuildUtil.surfaceText(sign, "LAKE PARK", Color3.fromRGB(255, 235, 170))
	BuildUtil.billboard(sign, "No fishing! (chests are fine)", 3, 16)
	for _, x in ipairs({ 4.5, 15.5 }) do
		block(grounds, "SignPost", Vector3.new(0.6, 5, 0.6), CFrame.new(x, 2.5, signZ), C.DarkWood, Enum.Material.Wood)
	end

	-- Cây tán lớn dọc vỉa hè (chừa 4 lối vào)
	for x = -100, 100, 25 do
		if math.abs(x) > 12 then
			shadeTree(grounds, Vector3.new(x, 0, PARK_MIN.Y + 5))
			shadeTree(grounds, Vector3.new(x, 0, PARK_MAX.Y - 5))
		end
	end
	for z = PARK_MIN.Y + 22, PARK_MAX.Y - 22, 22 do
		if math.abs(z) > 12 then
			shadeTree(grounds, Vector3.new(PARK_MIN.X + 5, 0, z))
			shadeTree(grounds, Vector3.new(PARK_MAX.X - 5, 0, z))
		end
	end

	-- Cây non rải trên bãi cỏ
	local placed = {}
	for _ = 1, 600 do
		local x = rng:NextNumber(PARK_MIN.X + 12, PARK_MAX.X - 12)
		local z = rng:NextNumber(PARK_MIN.Y + 12, PARK_MAX.Y - 12)
		local ok = lakeSdf(x, z) > LAMP_D + 4 and not onPathOrSquare(x, z, 3)
		for _, p in ipairs(placed) do
			if ok and (p - Vector2.new(x, z)).Magnitude < 11 then
				ok = false
			end
		end
		if ok then
			table.insert(placed, Vector2.new(x, z))
			youngTree(grounds, Vector3.new(x, 0, z), rng)
			if #placed >= 40 then
				break
			end
		end
	end

	grounds.Parent = map
end

-- ===== Đường vòng quanh công viên + lối vào từng nhà / cửa hàng =====
-- driveways: danh sách { Angle (radian, đo từ trục +X sang +Z), To (bán kính điểm cuối) }
function ParkBuilder.BuildRoads(roads, driveways)
	local y = TOP_ROAD + 0.01
	-- đường vòng: 48 đoạn thẳng ghép thành vòng tròn, vạch vàng đứt quãng ở giữa
	local steps = 48
	for i = 0, steps - 1 do
		local a0, a1 = i / steps * math.pi * 2, (i + 1) / steps * math.pi * 2
		local p0 = Vector3.new(math.cos(a0), 0, math.sin(a0)) * RING_R
		local p1 = Vector3.new(math.cos(a1), 0, math.sin(a1)) * RING_R
		local mid = (p0 + p1) / 2
		local len = (p1 - p0).Magnitude
		block(roads, "Road", Vector3.new(RING_W, 0.5, len + 1.2), CFrame.lookAt(mid + Vector3.new(0, TOP_ROAD - 0.25, 0), p1 + Vector3.new(0, TOP_ROAD - 0.25, 0)), C.Asphalt, Enum.Material.Asphalt)
		decor(block(roads, "LaneMark", Vector3.new(0.4, 0.05, 3), CFrame.lookAt(mid + Vector3.new(0, y, 0), p1 + Vector3.new(0, y, 0)), Color3.fromRGB(240, 220, 120)))
	end

	local function spoke(angle, from, to, width)
		local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local a, b = dir * from, dir * to
		local mid = (a + b) / 2
		block(roads, "Path", Vector3.new(width, 0.5, (b - a).Magnitude), CFrame.lookAt(mid + Vector3.new(0, TOP_PATH - 0.25, 0), b + Vector3.new(0, TOP_PATH - 0.25, 0)), C.Brick, Enum.Material.Pavement)
	end
	-- 4 lối từ cổng công viên ra đường vòng
	local inner = RING_R - RING_W / 2
	spoke(0, PARK_MAX.X + 3, inner, 6)
	spoke(math.pi, -PARK_MIN.X + 3, inner, 6)
	spoke(math.pi / 2, PARK_MAX.Y + 3, inner, 6)
	spoke(-math.pi / 2, -PARK_MIN.Y + 3, inner, 6)
	-- lối từ đường vòng vào từng nhà / cửa hàng
	for _, d in ipairs(driveways or {}) do
		spoke(d.Angle, RING_R + RING_W / 2, d.To, 8)
	end
end

-- Sông khép kín chạy VÒNG QUANH 8 nhà (nằm ngoài vòng nhà, sau lưng mỗi plot): các đoạn Terrain nước nối nhau theo elip Config.River.
-- Mỗi đoạn: lòng cát, đào không khí, đổ nước (cùng thứ tự với ao cũ). Nước chỉ để ngắm + câu ở bến (marker "Water" của từng plot).
function ParkBuilder.BuildRiver()
	local terrain = workspace.Terrain
	local river = Config.River
	local segments = river.Segments
	for i = 0, segments - 1 do
		local a0, a1 = i / segments * math.pi * 2, (i + 1) / segments * math.pi * 2
		local p0 = Vector3.new(river.Rx * math.cos(a0), 0, river.Rz * math.sin(a0))
		local p1 = Vector3.new(river.Rx * math.cos(a1), 0, river.Rz * math.sin(a1))
		local mid = (p0 + p1) / 2
		local length = (p1 - p0).Magnitude + 3 -- chồng lên đoạn kế 3 stud để không hở ở chỗ cong
		local cf = CFrame.lookAt(mid, mid + (p1 - p0))
		terrain:FillBlock(cf * CFrame.new(0, -5 + TERRAIN_SHIFT, 0), Vector3.new(river.Width + 2, 2, length), Enum.Material.Sand)
		terrain:FillBlock(cf * CFrame.new(0, -2, 0), Vector3.new(river.Width, 4, length), Enum.Material.Air)
		terrain:FillBlock(cf * CFrame.new(0, -2, 0), Vector3.new(river.Width, 4, length), Enum.Material.Water)
		if i % 8 == 7 then
			task.wait() -- chia nhỏ để không treo server lúc dựng map
		end
	end
end

function ParkBuilder.Build(map)
	buildTerrain()
	buildLake(map)
	buildGrounds(map)
end

return ParkBuilder
