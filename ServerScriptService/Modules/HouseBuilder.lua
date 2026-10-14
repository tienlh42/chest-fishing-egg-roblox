-- ModuleScript: ServerScriptService > Modules > HouseBuilder
-- Dựng 1 plot = lô nhà dân: nhà gỗ vào được bên trong (có nội thất), hàng rào gỗ trắng, hộp thư ghi tên,
-- chuồng ấp trứng gỗ, ao vườn nước thật (Terrain) + 4 ô máy câu.
-- Toạ độ trong file là toạ độ CỤC BỘ của plot: tâm (0,0,0), cổng ở -Z (quay ra đường), sân sau ở +Z.
--
-- Tên mà code khác cần (KHÔNG đổi): Home, Sign, Stash, PetBed, TrophyShelf, TrophySlot1..6,
-- IncubatorSlot1..4, FisherSlot1..5, Water (ao).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Models = require(ReplicatedStorage.Models)
local BuildUtil = require(script.Parent.BuildUtil)
local TERRAIN_SHIFT = require(script.Parent.ParkBuilder).TerrainShift

local block, ball, cylinder, wedge, marker, decor = BuildUtil.block, BuildUtil.ball, BuildUtil.cylinder, BuildUtil.wedge, BuildUtil.marker, BuildUtil.decor
local C = BuildUtil.Colors

local HouseBuilder = {}

local SIZE = 90 -- cạnh plot
local HALF = SIZE / 2

local WALL = Color3.fromRGB(205, 150, 90) -- ván gỗ màu mật ong
local ROOF = Color3.fromRGB(130, 85, 50) -- mái gỗ (mọi nhà giống nhau)
local FLOOR = Color3.fromRGB(165, 115, 70)
local TRIM = C.White

-- Kích thước nhà (to hơn bản đầu ~1.35 lần). Mặt sau z = 4: phía sau là chuồng ấp (z >= 10) và ô máy câu (z >= 5.5)
local HX0, HX1, HZ0, HZ1 = -16, 16, -20, 4 -- tường ngoài: x -16..16, z -20..4
local FLOOR_TOP = 1
local WALL_H = 12
local WALL_TOP = FLOOR_TOP + WALL_H
local RIDGE = WALL_TOP + 7

-- ===== Hàng rào gỗ trắng =====
local function fenceLine(parent, cf, from, to, gapCenter, gapWidth)
	local dir = (to - from).Unit
	local len = (to - from).Magnitude
	local function inGap(p)
		return gapCenter and (p - gapCenter).Magnitude < gapWidth / 2
	end
	-- cọc nhọn mỗi 3 stud
	for t = 0, len, 3 do
		local p = from + dir * t
		if not inGap(p) then
			block(parent, "Picket", Vector3.new(0.5, 3.2, 0.3), cf * CFrame.lookAt(p + Vector3.new(0, 1.6, 0), p + dir + Vector3.new(0, 1.6, 0)), TRIM, Enum.Material.Wood)
		end
	end
	-- 2 thanh ngang, chia đoạn quanh cổng
	local pieces = { { from, to } }
	if gapCenter then
		pieces = { { from, gapCenter - dir * gapWidth / 2 }, { gapCenter + dir * gapWidth / 2, to } }
	end
	for _, piece in ipairs(pieces) do
		local a, b = piece[1], piece[2]
		local mid = (a + b) / 2
		for _, h in ipairs({ 1, 2.4 }) do
			block(parent, "FenceRail", Vector3.new(0.2, 0.3, (b - a).Magnitude), cf * CFrame.lookAt(mid + Vector3.new(0, h, 0), b + Vector3.new(0, h, 0)), TRIM, Enum.Material.Wood)
		end
	end
end

local function buildFence(plot, cf)
	local fence = Instance.new("Folder")
	fence.Name = "Fence"
	local e = HALF - 0.5
	fenceLine(fence, cf, Vector3.new(-e, 0, -e), Vector3.new(e, 0, -e), Vector3.new(0, 0, -e), 10) -- trước (có cổng)
	fenceLine(fence, cf, Vector3.new(e, 0, -e), Vector3.new(e, 0, e))
	fenceLine(fence, cf, Vector3.new(e, 0, e), Vector3.new(-e, 0, e))
	fenceLine(fence, cf, Vector3.new(-e, 0, e), Vector3.new(-e, 0, -e))
	for _, x in ipairs({ -5.4, 5.4 }) do
		block(fence, "GatePost", Vector3.new(0.9, 4, 0.9), cf * CFrame.new(x, 2, -e), TRIM, Enum.Material.Wood)
	end
	fence.Parent = plot
end

-- ===== Cửa sổ (nhìn từ ngoài) =====
-- cframe: tâm cửa sổ trên mặt ngoài tường, -Z hướng ra ngoài
local WIN = 4.4 -- cạnh khung cửa sổ

local function window(parent, cframe, rng)
	local inner = WIN - 0.6
	block(parent, "WindowFrame", Vector3.new(WIN, WIN, 0.3), cframe, TRIM, Enum.Material.Wood)
	local glass = block(parent, "WindowGlass", Vector3.new(inner, inner, 0.32), cframe, Color3.fromRGB(170, 215, 240), Enum.Material.Glass)
	glass.Transparency = 0.35
	block(parent, "WindowBar", Vector3.new(0.2, inner, 0.36), cframe, TRIM, Enum.Material.Wood)
	block(parent, "WindowBar", Vector3.new(inner, 0.2, 0.36), cframe, TRIM, Enum.Material.Wood)
	-- chậu hoa bên dưới
	block(parent, "FlowerBox", Vector3.new(WIN + 0.2, 0.8, 0.9), cframe * CFrame.new(0, -WIN / 2 - 0.5, -0.5), C.Wood, Enum.Material.WoodPlanks)
	local colors = { Color3.fromRGB(255, 120, 160), Color3.fromRGB(255, 220, 80), Color3.fromRGB(255, 255, 255) }
	for x = -1.5, 1.5, 1 do
		decor(ball(parent, "Flower", 0.7, (cframe * CFrame.new(x, -WIN / 2 + 0.1, -0.5)).Position, colors[rng:NextInteger(1, #colors)], Enum.Material.Neon))
	end
end

-- ===== Nhà gỗ =====
local function buildHouse(plot, cf, rng)
	local house = Instance.new("Model")
	house.Name = "House"
	local function at(x, y, z)
		return cf * CFrame.new(x, y, z)
	end
	local cx, cz = (HX0 + HX1) / 2, (HZ0 + HZ1) / 2
	local width, depth = HX1 - HX0, HZ1 - HZ0
	local wallY = FLOOR_TOP + WALL_H / 2

	-- Móng + sàn
	block(house, "Foundation", Vector3.new(width + 1, FLOOR_TOP - 0.1, depth + 1), at(cx, (FLOOR_TOP - 0.1) / 2, cz), C.Stone, Enum.Material.Cobblestone)
	block(house, "Floor", Vector3.new(width - 1, 0.1, depth - 1), at(cx, FLOOR_TOP - 0.05, cz), FLOOR, Enum.Material.WoodPlanks)

	-- Tường: sau, 2 bên, trước (chừa cửa ra vào rộng 5, cao 7)
	block(house, "Wall", Vector3.new(width, WALL_H, 1), at(cx, wallY, HZ1 - 0.5), WALL, Enum.Material.WoodPlanks)
	for _, x in ipairs({ HX0 + 0.5, HX1 - 0.5 }) do
		block(house, "Wall", Vector3.new(1, WALL_H, depth - 2), at(x, wallY, cz), WALL, Enum.Material.WoodPlanks)
	end
	local doorW, doorH = 6, 8
	local sideW = (width - doorW) / 2
	for _, side in ipairs({ -1, 1 }) do
		block(house, "Wall", Vector3.new(sideW, WALL_H, 1), at(side * (doorW / 2 + sideW / 2), wallY, HZ0 + 0.5), WALL, Enum.Material.WoodPlanks)
	end
	block(house, "Wall", Vector3.new(doorW, WALL_H - doorH, 1), at(0, FLOOR_TOP + doorH + (WALL_H - doorH) / 2, HZ0 + 0.5), WALL, Enum.Material.WoodPlanks)
	-- viền cửa + cánh cửa mở hé vào trong
	block(house, "DoorTrim", Vector3.new(doorW + 1, 0.5, 1.2), at(0, FLOOR_TOP + doorH + 0.25, HZ0 + 0.5), TRIM, Enum.Material.Wood)
	block(house, "Door", Vector3.new(0.3, doorH - 0.2, doorW - 0.4), at(-doorW / 2 + 0.3, FLOOR_TOP + doorH / 2, HZ0 + 1 + (doorW - 0.4) / 2), Color3.fromRGB(170, 70, 55), Enum.Material.Wood)
	-- cột góc
	for _, x in ipairs({ HX0 + 0.5, HX1 - 0.5 }) do
		for _, z in ipairs({ HZ0 + 0.5, HZ1 - 0.5 }) do
			block(house, "CornerPost", Vector3.new(1.3, WALL_H, 1.3), at(x, wallY, z), TRIM, Enum.Material.Wood)
		end
	end

	-- Hồi nhà (tam giác) trước + sau bằng 2 WedgePart
	local rise = RIDGE - WALL_TOP
	for _, z in ipairs({ HZ0 + 0.5, HZ1 - 0.5 }) do
		wedge(house, "Gable", Vector3.new(1, rise, width / 2), at(-width / 4, WALL_TOP + rise / 2, z) * CFrame.Angles(0, math.rad(90), 0), WALL, Enum.Material.WoodPlanks)
		wedge(house, "Gable", Vector3.new(1, rise, width / 2), at(width / 4, WALL_TOP + rise / 2, z) * CFrame.Angles(0, math.rad(-90), 0), WALL, Enum.Material.WoodPlanks)
	end
	-- cửa sổ tròn nhỏ trên hồi nhà trước (trụ nằm ngang, trục quay ra phía trước)
	local attic = cylinder(house, "AtticWindow", 0.4, 2.6, at(0, WALL_TOP + rise * 0.4, HZ0 - 0.1) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(170, 215, 240), Enum.Material.Glass)
	attic.Transparency = 0.3

	-- Mái 2 dốc (nóc chạy dọc trục X), chìa ra 1.5 stud
	local overhang = 1.5
	local halfDepth = depth / 2
	local angle = math.atan2(rise, halfDepth)
	local run = halfDepth + overhang
	local slope = run / math.cos(angle)
	local midY = RIDGE - (run / 2) * math.tan(angle) + 0.35
	block(house, "Roof", Vector3.new(width + 2, 0.6, slope), at(cx, midY, cz - run / 2) * CFrame.Angles(-angle, 0, 0), ROOF, Enum.Material.Wood)
	block(house, "Roof", Vector3.new(width + 2, 0.6, slope), at(cx, midY, cz + run / 2) * CFrame.Angles(angle, 0, 0), ROOF, Enum.Material.Wood)
	block(house, "Ridge", Vector3.new(width + 2, 0.7, 1), at(cx, RIDGE + 0.6, cz), C.DarkWood, Enum.Material.Wood)
	-- ống khói
	block(house, "Chimney", Vector3.new(3, 9, 3), at(10, RIDGE - 1, cz + 5), Color3.fromRGB(150, 80, 60), Enum.Material.Brick)
	block(house, "ChimneyCap", Vector3.new(3.6, 0.6, 3.6), at(10, RIDGE + 3.8, cz + 5), C.Stone, Enum.Material.Concrete)

	-- Cửa sổ: 2 trước, 2 mỗi bên, 2 sau
	local winY = FLOOR_TOP + 6
	window(house, at(-10, winY, HZ0 - 0.15), rng)
	window(house, at(10, winY, HZ0 - 0.15), rng)
	for _, z in ipairs({ cz - 5, cz + 5 }) do
		window(house, at(HX0 - 0.15, winY, z) * CFrame.Angles(0, math.rad(90), 0), rng)
		window(house, at(HX1 + 0.15, winY, z) * CFrame.Angles(0, math.rad(-90), 0), rng)
	end
	for _, x in ipairs({ -9, 9 }) do
		window(house, at(x, winY, HZ1 + 0.15) * CFrame.Angles(0, math.pi, 0), rng)
	end

	-- Hiên trước: sàn, bậc, 2 cột, mái nhỏ, đèn treo
	block(house, "Porch", Vector3.new(20, FLOOR_TOP, 6), at(0, FLOOR_TOP / 2, HZ0 - 3), FLOOR, Enum.Material.WoodPlanks)
	block(house, "Step", Vector3.new(8, FLOOR_TOP / 2, 1.5), at(0, FLOOR_TOP / 4, HZ0 - 6.75), FLOOR, Enum.Material.WoodPlanks)
	for _, x in ipairs({ -9.4, 9.4 }) do
		block(house, "PorchPost", Vector3.new(0.7, 9.6, 0.7), at(x, FLOOR_TOP + 4.8, HZ0 - 5.6), TRIM, Enum.Material.Wood)
	end
	block(house, "PorchRoof", Vector3.new(21, 0.4, 7), at(0, FLOOR_TOP + 9.8, HZ0 - 3.1), ROOF, Enum.Material.Wood)
	local porchLamp = ball(house, "PorchLamp", 1, at(0, FLOOR_TOP + 9, HZ0 - 3.1).Position, Color3.fromRGB(255, 225, 160), Enum.Material.Neon)
	BuildUtil.light(porchLamp, Color3.fromRGB(255, 210, 150), 16, 1)

	-- ===== Nội thất =====
	local f = FLOOR_TOP
	block(house, "Rug", Vector3.new(12, 0.1, 8), at(0, f + 0.05, -9), Color3.fromRGB(190, 80, 80), Enum.Material.Fabric)
	-- giường + tủ đầu giường (góc sau trái)
	local bx, bz = -11.5, -1.6
	block(house, "BedFrame", Vector3.new(6, 1.4, 9), at(bx, f + 0.7, bz), C.Wood, Enum.Material.Wood)
	block(house, "Mattress", Vector3.new(5.6, 0.6, 8.6), at(bx, f + 1.7, bz), Color3.fromRGB(245, 245, 245), Enum.Material.Fabric)
	block(house, "Blanket", Vector3.new(5.8, 0.3, 5.5), at(bx, f + 2.1, bz - 1.9), Color3.fromRGB(80, 130, 200), Enum.Material.Fabric)
	block(house, "Pillow", Vector3.new(3.6, 0.6, 1.6), at(bx, f + 2.2, bz + 3.4), Color3.fromRGB(255, 255, 255), Enum.Material.Fabric)
	block(house, "Headboard", Vector3.new(6, 3, 0.4), at(bx, f + 1.5, 2.7), C.DarkWood, Enum.Material.Wood)
	block(house, "Nightstand", Vector3.new(2, 2, 2), at(-7.3, f + 1, 1.8), C.DarkWood, Enum.Material.Wood)
	local nightLamp = decor(ball(house, "NightLamp", 0.9, at(-7.3, f + 2.5, 1.8).Position, Color3.fromRGB(255, 230, 170), Enum.Material.Neon))
	BuildUtil.light(nightLamp, Color3.fromRGB(255, 210, 150), 8, 0.8)
	-- bàn + 2 ghế
	local tx, tz = 5, -9
	block(house, "TableTop", Vector3.new(4, 0.3, 3), at(tx, f + 2.5, tz), C.Wood, Enum.Material.Wood)
	for _, x in ipairs({ tx - 1.7, tx + 1.7 }) do
		for _, z in ipairs({ tz - 1.2, tz + 1.2 }) do
			block(house, "TableLeg", Vector3.new(0.3, 2.35, 0.3), at(x, f + 1.175, z), C.DarkWood, Enum.Material.Wood)
		end
	end
	for _, side in ipairs({ -1, 1 }) do
		block(house, "ChairSeat", Vector3.new(1.6, 0.3, 1.6), at(tx, f + 1.5, tz + side * 2.6), C.Wood, Enum.Material.Wood)
		block(house, "ChairBack", Vector3.new(1.6, 2, 0.3), at(tx, f + 2.6, tz + side * 3.3), C.Wood, Enum.Material.Wood)
		block(house, "ChairBase", Vector3.new(1, 1.35, 1), at(tx, f + 0.675, tz + side * 2.6), C.DarkWood, Enum.Material.Wood)
	end
	-- kệ sách (góc sau phải)
	block(house, "Bookshelf", Vector3.new(6, 8, 1.4), at(11.5, f + 4, 2.2), C.DarkWood, Enum.Material.Wood)
	local bookColors = { Color3.fromRGB(200, 60, 60), Color3.fromRGB(60, 120, 200), Color3.fromRGB(80, 170, 90) }
	for i, y in ipairs({ 1.6, 4, 6.4 }) do
		block(house, "Books", Vector3.new(5.4, 1.4, 1), at(11.5, f + y, 1.8), bookColors[i], Enum.Material.SmoothPlastic)
	end
	-- lò sưởi (tường phải)
	block(house, "Fireplace", Vector3.new(1.8, 7, 6), at(HX1 - 1.9, f + 3.5, -10), C.Stone, Enum.Material.Cobblestone)
	local fire = decor(block(house, "Fire", Vector3.new(0.4, 1.6, 3), at(HX1 - 2.9, f + 1, -10), Color3.fromRGB(255, 140, 40), Enum.Material.Neon))
	BuildUtil.light(fire, Color3.fromRGB(255, 150, 70), 14, 1.5)
	-- đèn trần
	decor(block(house, "LampCord", Vector3.new(0.1, 2, 0.1), at(0, WALL_TOP - 1, -8), C.Iron, Enum.Material.Metal))
	local bulb = decor(ball(house, "CeilingLamp", 1.4, at(0, WALL_TOP - 2.5, -8).Position, Color3.fromRGB(255, 240, 200), Enum.Material.Neon))
	BuildUtil.light(bulb, Color3.fromRGB(255, 230, 190), 26, 1.2)
	-- ===== Đồ chức năng (House.lua gắn logic) =====
	-- Ổ nằm cho pet (góc trái phía trước): chủ đứng gần thì pet hồi HP nhanh hơn
	cylinder(house, "PetBedRim", 0.8, 5, at(-11, f + 0.4, -15), Color3.fromRGB(150, 90, 60), Enum.Material.Fabric)
	local bed = cylinder(house, "PetBed", 0.5, 4.2, at(-11, f + 0.6, -15), Color3.fromRGB(240, 170, 190), Enum.Material.Fabric)
	BuildUtil.billboard(bed, "PET BED\nfaster healing", 2.5, 6)
	-- Kệ trưng bày pet trên tường trước, phải cửa: 3 tầng x 2 chỗ, mặt kệ quay vào phòng (+Z)
	local shelfX, shelfZ = 10, HZ0 + 1.7
	block(house, "TrophyShelf", Vector3.new(7, 6.6, 0.3), at(shelfX, f + 3.3, HZ0 + 1.15), C.DarkWood, Enum.Material.Wood)
	for _, x in ipairs({ shelfX - 3.5, shelfX + 3.5 }) do
		block(house, "ShelfSide", Vector3.new(0.25, 6.6, 1.4), at(x, f + 3.3, shelfZ), C.DarkWood, Enum.Material.Wood)
	end
	local slot = 1
	for _, y in ipairs({ 0.6, 2.8, 5.0 }) do
		block(house, "ShelfBoard", Vector3.new(7, 0.25, 1.4), at(shelfX, f + y, shelfZ), C.Wood, Enum.Material.Wood)
		for _, dx in ipairs({ -1.75, 1.75 }) do
			-- chỗ đặt pet: mặt trên tấm kệ, -Z quay vào phòng
			marker(house, "TrophySlot" .. slot, Vector3.new(2, 0.1, 1.2), at(shelfX + dx, f + y + 0.175, shelfZ) * CFrame.Angles(0, math.pi, 0))
			slot += 1
		end
	end

	house.Parent = plot
end

-- ===== Chuồng ấp trứng (gỗ, mái nghiêng, mở mặt trước) =====
local function buildHatchery(plot, cf)
	local shed = Instance.new("Model")
	shed.Name = "Hatchery"
	local cx, cz = -28, 25 -- x -42..-14, z 10..40
	local w, d = 28, 30
	block(shed, "Straw", Vector3.new(w, 0.4, d), cf * CFrame.new(cx, 0.2, cz), Color3.fromRGB(225, 195, 115), Enum.Material.Fabric)
	block(shed, "BackWall", Vector3.new(w, 8, 0.8), cf * CFrame.new(cx, 4, cz + d / 2 - 0.4), C.Wood, Enum.Material.WoodPlanks)
	for _, s in ipairs({ -1, 1 }) do
		block(shed, "SideWall", Vector3.new(0.8, 8, d), cf * CFrame.new(cx + s * (w / 2 - 0.4), 4, cz), C.Wood, Enum.Material.WoodPlanks)
		block(shed, "FrontPost", Vector3.new(0.8, 9.6, 0.8), cf * CFrame.new(cx + s * (w / 2 - 0.4), 4.8, cz - d / 2 + 0.4), C.DarkWood, Enum.Material.Wood)
	end
	-- mái dốc nhẹ từ trước (cao) ra sau (thấp)
	local roof = block(shed, "Roof", Vector3.new(w + 2, 0.5, d + 2), cf * CFrame.new(cx, 9, cz) * CFrame.Angles(math.rad(2.7), 0, 0), ROOF, Enum.Material.Wood)
	BuildUtil.billboard(roof, "HATCHERY", 3)
	-- 4 bệ máy ấp (2 hàng)
	local slot = 1
	for _, z in ipairs({ 18, 31 }) do
		for _, x in ipairs({ -35, -21 }) do
			block(shed, "IncubatorSlot" .. slot, Vector3.new(6, 0.4, 6), cf * CFrame.new(x, 0.6, z), Color3.fromRGB(200, 200, 210), Enum.Material.Metal)
			slot += 1
		end
	end
	-- vài kiện rơm trang trí
	for _, p in ipairs({ { -40, 12 }, { -16, 37 } }) do
		block(shed, "HayBale", Vector3.new(2.5, 1.6, 1.6), cf * CFrame.new(p[1], 1.2, p[2]), Color3.fromRGB(230, 200, 110), Enum.Material.Fabric)
	end
	shed.Parent = plot
end

-- ===== Ao vườn (nước thật) + 5 ô máy câu =====
local function buildPond(plot, cf)
	local area = Instance.new("Model")
	area.Name = "FishingArea"
	local px, pz, pw, pd = 28, 27, 28, 26 -- tâm + kích thước ao (x 14..42, z 14..40)

	local terrain = workspace.Terrain
	local shift = TERRAIN_SHIFT -- chỉ hạ đất (xem ParkBuilder); nước fill tới y = 0
	terrain:FillBlock(cf * CFrame.new(px, -5 + shift, pz), Vector3.new(pw + 2, 2, pd + 2), Enum.Material.Sand)
	terrain:FillBlock(cf * CFrame.new(px, -2, pz), Vector3.new(pw, 4, pd), Enum.Material.Air)
	terrain:FillBlock(cf * CFrame.new(px, -2, pz), Vector3.new(pw, 4, pd), Enum.Material.Water)
	marker(area, "Water", Vector3.new(pw, 1, pd), cf * CFrame.new(px, -0.5, pz))

	-- viền đá cuội
	local stone = Color3.fromRGB(140, 140, 135)
	block(area, "PondRim", Vector3.new(pw + 3, 1, 1.5), cf * CFrame.new(px, 0, pz - pd / 2 - 0.75), stone, Enum.Material.Slate)
	block(area, "PondRim", Vector3.new(pw + 3, 1, 1.5), cf * CFrame.new(px, 0, pz + pd / 2 + 0.75), stone, Enum.Material.Slate)
	for _, s in ipairs({ -1, 1 }) do
		block(area, "PondRim", Vector3.new(1.5, 1, pd), cf * CFrame.new(px + s * (pw / 2 + 0.75), 0, pz), stone, Enum.Material.Slate)
	end
	-- lá sen
	for _, p in ipairs({ { 22, 32 }, { 35, 22 }, { 31, 36 } }) do
		decor(cylinder(area, "LilyPad", 0.1, 2.2, cf * CFrame.new(p[1], 0.05, p[2]), Color3.fromRGB(70, 160, 70), Enum.Material.Grass))
	end

	-- 5 ô máy câu ở mép trước ao (máy asset thu nhỏ còn ~5.4 stud rộng, xem Plots.MACHINE_SCALE), -Z của bệ quay ra mặt nước
	for i, x in ipairs({ 16, 22, 28, 34, 40 }) do
		block(area, "FisherSlot" .. i, Vector3.new(5, 0.4, 5), cf * CFrame.new(x, 0.2, 8) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(120, 120, 130), Enum.Material.DiamondPlate)
	end
	local post = block(area, "SignPost", Vector3.new(0.6, 5, 0.6), cf * CFrame.new(28, 2.5, 3), C.DarkWood, Enum.Material.Wood)
	BuildUtil.billboard(post, "AUTO-FISHING", 3.5)
	area.Parent = plot
end

-- ===== Sân trước: lối đá, hộp thư, thảm chùi chân, cây, luống hoa =====
local function buildYard(plot, cf, rng)
	local yard = Instance.new("Folder")
	yard.Name = "Yard"
	for z = -43, HZ0 - 10, 3 do
		block(yard, "SteppingStone", Vector3.new(2.6, 0.3, 1.8), cf * CFrame.new(rng:NextNumber(-0.3, 0.3), 0.15, z), Color3.fromRGB(165, 160, 150), Enum.Material.Slate)
	end
	-- Rương cất đồ (Stash) NGOÀI SÂN TRƯỚC: bên trái lối đá, gần cổng => chạy từ hồ về vào cổng là cất được ngay.
	-- Đặt trên bục gỗ, mặt rương quay ra lối đi (+X). Plots gắn nút [E] cho chủ nhà.
	-- Phóng 1.8 lần rồi đặt ĐÁY rương (theo hộp bao thật) chạm mặt bục, nên model thật trong CustomModels cũng đứng đúng.
	local deckTop = 0.3
	local spot = cf * CFrame.new(-10, 0, -32)
	block(yard, "StashDeck", Vector3.new(7, deckTop, 9), spot * CFrame.new(0, deckTop / 2, 0), C.Wood, Enum.Material.WoodPlanks)
	local stash = Models.Anchor(Models.Get("Wooden Chest"))
	stash.Name = "Stash"
	stash:ScaleTo(stash:GetScale() * 1.8)
	stash:PivotTo(spot * CFrame.new(0, 3, 0) * CFrame.Angles(0, math.rad(-90), 0))
	local box, size = stash:GetBoundingBox()
	stash:PivotTo(stash:GetPivot() + Vector3.new(0, (spot.Y + deckTop) - (box.Position.Y - size.Y / 2), 0))
	stash.Parent = plot
	BuildUtil.billboard(stash.PrimaryPart or stash:FindFirstChildWhichIsA("BasePart", true), "STASH\nDeposit your loot", 5, 10)
	-- hộp thư = biển tên chủ nhà (Plots gắn tên lên Part "Sign")
	block(yard, "MailboxPost", Vector3.new(0.4, 3.4, 0.4), cf * CFrame.new(8, 1.7, -42), C.DarkWood, Enum.Material.Wood)
	block(plot, "Sign", Vector3.new(1.4, 1.2, 2.2), cf * CFrame.new(8, 3.9, -42), Color3.fromRGB(70, 120, 200), Enum.Material.Metal)
	-- cây ăn quả hai bên sân trước
	for _, x in ipairs({ -30, 30 }) do
		local pos = (cf * CFrame.new(x, 0, -28)).Position
		BuildUtil.tree(yard, pos, 0.9)
		for _ = 1, 4 do
			local off = Vector3.new(rng:NextNumber(-3, 3), rng:NextNumber(7, 10), rng:NextNumber(-3, 3))
			decor(ball(yard, "Fruit", 0.8, pos + off, Color3.fromRGB(220, 50, 50), Enum.Material.SmoothPlastic))
		end
	end
	-- luống hoa 2 bên hiên
	for _, x in ipairs({ -13, 13 }) do
		block(yard, "FlowerBed", Vector3.new(4, 0.6, 3), cf * CFrame.new(x, 0.3, HZ0 - 3), Color3.fromRGB(100, 70, 45), Enum.Material.Ground)
		for _ = 1, 4 do
			local p = cf * CFrame.new(x + rng:NextNumber(-1.5, 1.5), 1, HZ0 - 3 + rng:NextNumber(-1, 1))
			decor(ball(yard, "Flower", 0.8, p.Position, Color3.fromRGB(255, 140, 180), Enum.Material.Neon))
		end
	end
	yard.Parent = plot
end

-- Dựng 1 plot. cf: tâm plot, -Z = cổng
function HouseBuilder.Build(parent, index, cf)
	local plot = Instance.new("Model")
	plot.Name = "Plot" .. index
	local rng = Random.new(index)

	-- Nền vô hình 90x90 làm PrimaryPart + định khung vùng an toàn (nền thật là cỏ Terrain)
	local base = marker(plot, "Base", Vector3.new(SIZE, 1, SIZE), cf * CFrame.new(0, -0.5, 0))
	plot.PrimaryPart = base

	buildFence(plot, cf)
	buildHouse(plot, cf, rng)
	buildHatchery(plot, cf)
	buildPond(plot, cf)
	buildYard(plot, cf, rng)

	-- Điểm về nhà = thảm chùi chân trước hiên, quay mặt vào nhà
	block(plot, "Home", Vector3.new(4, 0.2, 2.5), cf * CFrame.new(0, 0.1, HZ0 - 8) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(180, 60, 60), Enum.Material.Fabric)

	plot.Parent = parent
	return plot
end

return HouseBuilder
