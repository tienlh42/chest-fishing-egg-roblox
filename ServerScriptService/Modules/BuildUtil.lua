-- ModuleScript: ServerScriptService > Modules > BuildUtil
-- Các hàm dựng Part dùng chung cho MapBuilder / ParkBuilder / HouseBuilder.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Models = require(ReplicatedStorage.Models)

local BuildUtil = {}

BuildUtil.Colors = {
	Stone = Color3.fromRGB(170, 170, 175),
	Wood = Color3.fromRGB(120, 80, 45),
	DarkWood = Color3.fromRGB(90, 60, 35),
	Brick = Color3.fromRGB(200, 120, 80), -- gạch lát lối đi màu cam đất
	Asphalt = Color3.fromRGB(70, 72, 78),
	Concrete = Color3.fromRGB(190, 190, 185),
	Iron = Color3.fromRGB(45, 45, 50),
	White = Color3.fromRGB(245, 245, 240),
	Leaf = Color3.fromRGB(70, 150, 70),
}

-- Part khối cơ bản (neo cố định)
function BuildUtil.block(parent, name, size, cframe, color, material)
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

function BuildUtil.ball(parent, name, diameter, position, color, material)
	local p = BuildUtil.block(parent, name, Vector3.one * diameter, CFrame.new(position), color, material)
	p.Shape = Enum.PartType.Ball
	return p
end

-- Trụ đứng thẳng: cframe = tâm trụ
function BuildUtil.cylinder(parent, name, height, diameter, cframe, color, material)
	local p = BuildUtil.block(parent, name, Vector3.new(height, diameter, diameter), cframe * CFrame.Angles(0, 0, math.rad(90)), color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- WedgePart: mặt dốc quay về -Z, mặt đứng cao nhất ở +Z
function BuildUtil.wedge(parent, name, size, cframe, color, material)
	local p = Instance.new("WedgePart")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.Parent = parent
	return p
end

-- Part vô hình, không va chạm (dùng làm vùng đánh dấu cho code, vd. "Water")
function BuildUtil.marker(parent, name, size, cframe)
	local p = BuildUtil.block(parent, name, size, cframe, Color3.new(1, 1, 1))
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	return p
end

-- Đồ trang trí nhỏ: không cản đường
function BuildUtil.decor(part)
	part.CanCollide = false
	return part
end

-- Chữ in lên 2 mặt trước/sau của 1 tấm bảng
function BuildUtil.surfaceText(part, text, color)
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
function BuildUtil.billboard(part, text, height, width)
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

function BuildUtil.light(part, color, range, brightness)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness or 1
	light.Parent = part
	return light
end

function BuildUtil.placeModel(parent, name, cframe)
	local model = Models.Anchor(Models.Get(name))
	model:PivotTo(cframe)
	model.Parent = parent
	return model
end

-- Cây tán tròn
function BuildUtil.tree(parent, position, scale)
	scale = scale or 1
	BuildUtil.block(parent, "Trunk", Vector3.new(1.5, 8, 1.5) * scale, CFrame.new(position + Vector3.new(0, 4 * scale, 0)), BuildUtil.Colors.DarkWood, Enum.Material.Wood)
	BuildUtil.ball(parent, "Leaves", 8 * scale, position + Vector3.new(0, 9.5 * scale, 0), Color3.fromRGB(60, 140, 60), Enum.Material.Grass)
end

-- Ghế công viên. cframe: -Z = hướng người ngồi nhìn ra
function BuildUtil.bench(parent, cframe)
	local seat = Color3.fromRGB(150, 100, 55)
	BuildUtil.block(parent, "BenchSeat", Vector3.new(5, 0.4, 1.6), cframe * CFrame.new(0, 1.6, 0), seat, Enum.Material.WoodPlanks)
	BuildUtil.block(parent, "BenchBack", Vector3.new(5, 1.4, 0.3), cframe * CFrame.new(0, 2.6, 0.7), seat, Enum.Material.WoodPlanks)
	for _, x in ipairs({ -2.2, 2.2 }) do
		BuildUtil.block(parent, "BenchLeg", Vector3.new(0.3, 1.6, 1.6), cframe * CFrame.new(x, 0.8, 0), BuildUtil.Colors.Iron, Enum.Material.Metal)
	end
end

-- Đèn đường
function BuildUtil.lamp(parent, position)
	BuildUtil.block(parent, "LampPole", Vector3.new(0.4, 9, 0.4), CFrame.new(position + Vector3.new(0, 4.5, 0)), Color3.fromRGB(40, 40, 45), Enum.Material.Metal)
	local head = BuildUtil.ball(parent, "LampHead", 1.4, position + Vector3.new(0, 9.4, 0), Color3.fromRGB(255, 230, 170), Enum.Material.Neon)
	BuildUtil.light(head, Color3.fromRGB(255, 210, 150), 18, 1.2)
end

return BuildUtil
