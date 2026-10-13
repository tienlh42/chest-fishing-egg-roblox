-- ModuleScript: ServerScriptService > Modules > MapBuilder
-- Dựng map màn 1 TẠM bằng Part (xem MAP_LEVEL1.md).
-- Nếu Workspace đã có Folder "Map" (map bạn tự build) thì KHÔNG dựng gì, dùng luôn map đó.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Models = require(ReplicatedStorage.Models)

local MapBuilder = {}

local GRASS = Color3.fromRGB(90, 160, 70)
local STONE = Color3.fromRGB(170, 170, 175)
local ROAD = Color3.fromRGB(200, 185, 150)
local WOOD = Color3.fromRGB(120, 80, 45)
local DARK_WOOD = Color3.fromRGB(90, 60, 35)
local WATER = Color3.fromRGB(40, 120, 200)

local PLOT_COLORS = {
	Color3.fromRGB(120, 190, 100), Color3.fromRGB(110, 180, 120), Color3.fromRGB(130, 185, 95), Color3.fromRGB(105, 175, 105),
	Color3.fromRGB(125, 195, 110), Color3.fromRGB(115, 185, 95), Color3.fromRGB(135, 190, 105), Color3.fromRGB(110, 170, 100),
}

-- ===== Tiện ích =====
local function block(parent, name, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function water(parent, size, cframe)
	local w = block(parent, "Water", size, cframe, WATER, Enum.Material.SmoothPlastic)
	w.Transparency = 0.35
	w.CanCollide = false
	return w
end

-- Chữ in lên 2 mặt trước/sau của 1 tấm bảng
local function surfaceText(part, text, color)
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextScaled = true
		label.Font = Enum.Font.GothamBlack
		label.TextColor3 = color or Color3.new(1, 1, 1)
		label.Parent = gui
		gui.Parent = part
	end
end

-- Chữ nổi luôn quay về phía camera
local function billboard(part, text, height, width)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromScale(width or 12, 3)
	gui.StudsOffset = Vector3.new(0, height, 0)
	gui.MaxDistance = 200
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Parent = gui
	gui.Parent = part
end

local function tree(parent, position)
	block(parent, "Trunk", Vector3.new(1.5, 8, 1.5), CFrame.new(position + Vector3.new(0, 4.5, 0)), DARK_WOOD, Enum.Material.Wood)
	local leaves = block(parent, "Leaves", Vector3.new(8, 8, 8), CFrame.new(position + Vector3.new(0, 10, 0)), Color3.fromRGB(60, 140, 60), Enum.Material.Grass)
	leaves.Shape = Enum.PartType.Ball
end

local function placeModel(parent, name, cframe)
	local model = Models.Anchor(Models.Get(name))
	model:PivotTo(cframe)
	model.Parent = parent
	return model
end

-- ===== Các khu =====
local function buildPlaza(map)
	local plaza = Instance.new("Model")
	plaza.Name = "Plaza"
	block(plaza, "Floor", Vector3.new(50, 1, 50), CFrame.new(0, 0, 0), STONE, Enum.Material.Cobblestone)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(0, 0.6, 12)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = Color3.fromRGB(255, 255, 255)
	spawn.Material = Enum.Material.Marble
	spawn.Parent = plaza

	-- Đài phun nước trang trí
	local upright = CFrame.Angles(0, 0, math.rad(90))
	local basin = block(plaza, "Fountain", Vector3.new(2, 12, 12), CFrame.new(0, 1, -10) * upright, STONE, Enum.Material.Marble)
	basin.Shape = Enum.PartType.Cylinder
	local pool = block(plaza, "FountainWater", Vector3.new(0.2, 10.5, 10.5), CFrame.new(0, 2.05, -10) * upright, WATER, Enum.Material.Neon)
	pool.Shape = Enum.PartType.Cylinder
	pool.CanCollide = false
	billboard(basin, "Chest Fishing & Eggs", 7, 16)

	for _, x in ipairs({ -20, 20 }) do
		for _, z in ipairs({ -20, 20 }) do
			tree(plaza, Vector3.new(x, 0.5, z))
		end
	end
	plaza.Parent = map
end

local function buildRoads(map)
	local roads = Instance.new("Folder")
	roads.Name = "Roads"
	for _, side in ipairs({ -1, 1 }) do
		-- đường ngang từ plaza ra cột plot
		block(roads, "Road", Vector3.new(97, 1, 12), CFrame.new(side * 73.5, 0, 0), ROAD, Enum.Material.Sand)
		-- đường dọc chạy ngang cổng các plot
		block(roads, "Road", Vector3.new(12, 1, 390), CFrame.new(side * 128, 0, 0), ROAD, Enum.Material.Sand)
		-- lối vào Shop / Market
		block(roads, "Path", Vector3.new(8, 1, 10), CFrame.new(side * 73.5, 0, -11), ROAD, Enum.Material.Sand)
	end
	roads.Parent = map
end

local function buildLake(map)
	local lake = Instance.new("Model")
	lake.Name = "Lake"
	water(lake, Vector3.new(100, 1, 70), CFrame.new(0, 0, 95))
	block(lake, "LakeBed", Vector3.new(100, 0.2, 70), CFrame.new(0, 0.05, 95), Color3.fromRGB(30, 60, 110))

	-- Cầu tàu từ plaza ra giữa hồ
	block(lake, "Dock", Vector3.new(8, 1, 60), CFrame.new(0, 1, 55), WOOD, Enum.Material.WoodPlanks)
	block(lake, "DockEnd", Vector3.new(30, 1, 10), CFrame.new(0, 1, 90), WOOD, Enum.Material.WoodPlanks)
	for _, z in ipairs({ 65, 75, 85 }) do
		for _, x in ipairs({ -3.5, 3.5 }) do
			block(lake, "Post", Vector3.new(0.8, 4, 0.8), CFrame.new(x, 0, z), DARK_WOOD, Enum.Material.Wood)
		end
	end
	local signPost = block(lake, "SignPost", Vector3.new(0.8, 6, 0.8), CFrame.new(5, 3.5, 28), DARK_WOOD, Enum.Material.Wood)
	billboard(signPost, "FISHING DOCK", 4)

	for _, pos in ipairs({ Vector3.new(-60, 0, 70), Vector3.new(60, 0, 80), Vector3.new(-55, 0, 125), Vector3.new(58, 0, 128) }) do
		tree(lake, pos)
	end
	lake.Parent = map
end

-- Gian hàng (Tool Shop / Market): mặt trước quay về đường (+Z)
local function buildStall(map, name, title, center, roofColor, npcName)
	local stall = Instance.new("Model")
	stall.Name = name
	local cf = CFrame.new(center) * CFrame.Angles(0, math.pi, 0) -- -Z của gian hàng = hướng +Z thế giới

	block(stall, "Floor", Vector3.new(30, 1, 24), cf, WOOD, Enum.Material.WoodPlanks)
	block(stall, "BackWall", Vector3.new(30, 10, 1), cf * CFrame.new(0, 5.5, 11.5), Color3.fromRGB(230, 220, 200), Enum.Material.Brick)
	for _, x in ipairs({ -14.5, 14.5 }) do
		block(stall, "SideWall", Vector3.new(1, 10, 24), cf * CFrame.new(x, 5.5, 0), Color3.fromRGB(230, 220, 200), Enum.Material.Brick)
	end
	block(stall, "Roof", Vector3.new(32, 1, 26), cf * CFrame.new(0, 11, 0), roofColor)

	block(stall, "PromptPart", Vector3.new(14, 3, 3), cf * CFrame.new(0, 2, -2), DARK_WOOD, Enum.Material.Wood) -- quầy, có nút [E]
	placeModel(stall, npcName, cf * CFrame.new(0, 0.5, 2))

	local board = block(stall, "SignBoard", Vector3.new(20, 4, 0.6), cf * CFrame.new(0, 13.5, -12), roofColor)
	surfaceText(board, title)
	stall.Parent = map
end

-- 1 plot 90x90. cf: tâm plot, hướng -Z = cổng (quay ra đường)
local function buildPlot(parent, index, cf)
	local plot = Instance.new("Model")
	plot.Name = "Plot" .. index
	local base = block(plot, "Base", Vector3.new(90, 1, 90), cf, PLOT_COLORS[index], Enum.Material.Grass)
	plot.PrimaryPart = base

	-- Hàng rào (chừa cổng rộng 12 ở giữa mặt trước)
	local fence = Color3.fromRGB(240, 240, 240)
	block(plot, "Fence", Vector3.new(90, 3, 1), cf * CFrame.new(0, 2, 44.5), fence, Enum.Material.Wood)
	for _, x in ipairs({ -44.5, 44.5 }) do
		block(plot, "Fence", Vector3.new(1, 3, 90), cf * CFrame.new(x, 2, 0), fence, Enum.Material.Wood)
	end
	for _, x in ipairs({ -25.5, 25.5 }) do
		block(plot, "Fence", Vector3.new(39, 3, 1), cf * CFrame.new(x, 2, -44.5), fence, Enum.Material.Wood)
	end

	-- Cổng + biển tên chủ plot
	for _, x in ipairs({ -7, 7 }) do
		block(plot, "GatePost", Vector3.new(1, 8, 1), cf * CFrame.new(x, 4.5, -44.5), DARK_WOOD, Enum.Material.Wood)
	end
	block(plot, "Sign", Vector3.new(16, 3, 1), cf * CFrame.new(0, 9, -44.5), DARK_WOOD, Enum.Material.Wood)

	-- Điểm về nhà (quay mặt vào trong plot)
	block(plot, "Home", Vector3.new(6, 0.4, 6), cf * CFrame.new(0, 0.7, -35) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(255, 240, 150), Enum.Material.Neon)

	-- Hatchery: sàn, 4 cột, mái, 4 bệ máy ấp
	local hatchery = Instance.new("Model")
	hatchery.Name = "Hatchery"
	block(hatchery, "Floor", Vector3.new(36, 0.4, 30), cf * CFrame.new(-22, 0.6, 0), Color3.fromRGB(235, 225, 200), Enum.Material.Marble)
	for _, x in ipairs({ -39.5, -4.5 }) do
		for _, z in ipairs({ -14.5, 14.5 }) do
			block(hatchery, "Pillar", Vector3.new(1, 10, 1), cf * CFrame.new(x, 5.8, z), Color3.new(1, 1, 1), Enum.Material.Marble)
		end
	end
	local roof = block(hatchery, "Roof", Vector3.new(38, 1, 32), cf * CFrame.new(-22, 11.3, 0), Color3.fromRGB(240, 150, 170))
	billboard(roof, "HATCHERY", 3)
	local slot = 1
	for _, z in ipairs({ -6, 8 }) do
		for _, x in ipairs({ -31, -13 }) do
			block(hatchery, "IncubatorSlot" .. slot, Vector3.new(6, 0.4, 6), cf * CFrame.new(x, 1, z), Color3.fromRGB(200, 200, 210), Enum.Material.Metal)
			slot += 1
		end
	end
	hatchery.Parent = plot

	-- Ao riêng + 4 ô máy câu (quay mặt ra ao)
	local fishing = Instance.new("Model")
	fishing.Name = "FishingArea"
	water(fishing, Vector3.new(36, 1, 40), cf * CFrame.new(24, 0.15, 10))
	block(fishing, "PondBed", Vector3.new(36, 0.1, 40), cf * CFrame.new(24, 0.55, 10), Color3.fromRGB(30, 60, 110))
	for i, x in ipairs({ 10, 19, 28, 37 }) do
		block(fishing, "FisherSlot" .. i, Vector3.new(5, 0.4, 5), cf * CFrame.new(x, 0.7, -15) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(120, 120, 130), Enum.Material.DiamondPlate)
	end
	local post = block(fishing, "SignPost", Vector3.new(0.8, 6, 0.8), cf * CFrame.new(24, 3.5, -22), DARK_WOOD, Enum.Material.Wood)
	billboard(post, "AUTO-FISHING", 4)
	fishing.Parent = plot

	plot.Parent = parent
end

local function buildPlots(map)
	local plots = Instance.new("Folder")
	plots.Name = "Plots"
	local index = 1
	for _, side in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -150, -50, 50, 150 }) do
			local center = Vector3.new(side * 180, 0, z)
			-- cổng (-Z) quay về phía trục giữa map
			buildPlot(plots, index, CFrame.lookAt(center, Vector3.new(0, 0, z)))
			index += 1
		end
	end
	plots.Parent = map
end

local function build()
	local map = Instance.new("Folder")
	map.Name = "Map"

	if not workspace:FindFirstChild("Baseplate") then
		block(map, "Ground", Vector3.new(700, 2, 700), CFrame.new(0, -1, 0), GRASS, Enum.Material.Grass)
	end
	buildPlaza(map)
	buildRoads(map)
	buildLake(map)
	buildStall(map, "ToolShop", "TOOL SHOP", Vector3.new(-73.5, 0, -28), Color3.fromRGB(60, 110, 200), "Shopkeeper")
	buildStall(map, "Market", "MARKET", Vector3.new(73.5, 0, -28), Color3.fromRGB(200, 70, 60), "Merchant")
	buildPlots(map)

	map.Parent = workspace
	return map
end

function MapBuilder.Build()
	local map = workspace:FindFirstChild("Map") or build()

	-- Tắt các SpawnLocation nằm ngoài Map (vd. spawn mặc định của template Baseplate)
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("SpawnLocation") and not d:IsDescendantOf(map) then
			d.Enabled = false
		end
	end
	return map
end

return MapBuilder
