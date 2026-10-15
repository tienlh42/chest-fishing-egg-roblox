-- ModuleScript: ServerScriptService > Modules > MapBuilder
-- Dựng map màn 1 TẠM bằng Part + Terrain (xem MAP_LEVEL1.md và PARK_REDESIGN.md).
-- Nếu Workspace đã có Folder "Map" (map bạn tự build) thì KHÔNG dựng gì, dùng luôn map đó.
--   Bố cục: công viên hồ ở CHÍNH GIỮA, 8 nhà xếp VÒNG TRÒN quanh hồ (nhà nào ra hồ cũng xa như nhau),
--           Tool Shop + Market dựng SÁT NHAU thành 1 quảng trường ở khe giữa 2 nhà (góc 225°). Không có sảnh chính.
--   Điểm hồi sinh                       : ở file này
--   Tool Shop / Market (quảng trường)   : ShopBuilder
--   Hồ + công viên + đường vòng        : ParkBuilder
--   8 plot nhà gỗ                       : HouseBuilder

local BuildUtil = require(script.Parent.BuildUtil)
local HouseBuilder = require(script.Parent.HouseBuilder)
local ParkBuilder = require(script.Parent.ParkBuilder)
local ShopBuilder = require(script.Parent.ShopBuilder)


local MapBuilder = {}

-- Nhà xếp theo hình ELIP (khớp dáng hồ chữ nhật rộng 130 x dài 90) để nhà nào cũng cách lối đi quanh hồ
-- ~130 stud (đi bộ ~8s, chạy ~4s). Đổi kích thước hồ thì tính lại 2 số này.
local PLOT_RX, PLOT_RZ = 228, 212
local SHOP_R = 192

-- Điểm trên vòng tròn bán kính r, góc angle (radian), quay mặt (-Z) vào tâm hồ
local function ringCFrame(angle, r)
	local pos = Vector3.new(math.cos(angle), 0, math.sin(angle)) * r
	return CFrame.lookAt(pos, Vector3.zero)
end

-- ===== 8 nhà xếp vòng quanh hồ =====
-- Mỗi nhà: { CFrame (cổng -Z quay vào hồ), Angle (góc thật nhìn từ tâm), Dist (tâm hồ -> tâm nhà) }
local PLOTS = {}
for i = 0, 7 do
	local a = math.rad(22.5 + i * 45)
	local pos = Vector3.new(math.cos(a) * PLOT_RX, 0, math.sin(a) * PLOT_RZ)
	PLOTS[i + 1] = { CFrame = CFrame.lookAt(pos, Vector3.zero), Angle = math.atan2(pos.Z, pos.X), Dist = pos.Magnitude }
end
local PLAZA_ANGLE = math.rad(225) -- khe giữa 2 nhà: quảng trường Tool Shop + Market

local function buildPlots(map)
	local plots = Instance.new("Folder")
	plots.Name = "Plots"
	for index, info in ipairs(PLOTS) do
		HouseBuilder.Build(plots, index, info.CFrame) -- cổng (-Z) quay về phía hồ
	end
	plots.Parent = map
end

-- Điểm hồi sinh khi mới vào game (sau đó server đưa về nhà ngay). Đặt trước Tool Shop.
local function buildSpawn(map)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = ringCFrame(PLAZA_ANGLE, SHOP_R - 20) * CFrame.new(0, 0.1, 0)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = Color3.fromRGB(255, 255, 255)
	spawn.Material = Enum.Material.Marble
	spawn.Parent = map
end

local function build()
	local map = Instance.new("Folder")
	map.Name = "Map"

	-- Nền đất là Terrain (để đào được hồ/ao nước thật). Baseplate sẽ cắt ngang lòng hồ nên bỏ đi khi chạy game.
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end

	ParkBuilder.Build(map) -- terrain + hồ + công viên (phải chạy trước mọi thứ vì là nền đất)
	ParkBuilder.BuildRiver() -- sông vòng quanh các nhà (sau lưng mỗi plot)

	local driveways = {}
	for _, info in ipairs(PLOTS) do
		table.insert(driveways, { Angle = info.Angle, To = info.Dist - 45 })
	end
	table.insert(driveways, { Angle = PLAZA_ANGLE, To = SHOP_R - 12 })
	local roads = Instance.new("Folder")
	roads.Name = "Roads"
	ParkBuilder.BuildRoads(roads, driveways)
	roads.Parent = map

	ShopBuilder.Build(map, ringCFrame(PLAZA_ANGLE, SHOP_R)) -- Tool Shop (trái) + Market (phải) sát nhau
	buildSpawn(map)
	-- Điểm đáp VÔ HÌNH giữa quảng trường khi bấm nút "Tool Shop" (Teleports.lua)
	BuildUtil.marker(map, "ShopArrival", Vector3.new(4, 1, 4), ringCFrame(PLAZA_ANGLE, SHOP_R) * CFrame.new(0, 0.5, -20))
	buildPlots(map)

	map.Parent = workspace
	return map
end

function MapBuilder.Build()
	local map = workspace:FindFirstChild("Map") or build()

	-- Xoá các SpawnLocation nằm ngoài Map (vd. spawn mặc định của template Baseplate ở (0,0,0)
	-- nằm lơ lửng giữa hồ). Chỉ xoá lúc chạy game, place trong Studio không đổi.
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("SpawnLocation") and not d:IsDescendantOf(map) then
			d:Destroy()
		end
	end
	return map
end

return MapBuilder
