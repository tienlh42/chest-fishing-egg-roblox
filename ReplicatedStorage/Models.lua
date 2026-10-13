-- ModuleScript: ReplicatedStorage > Models
-- Cung cấp model cho game. Thứ tự ưu tiên:
--   1. Model thật bạn đặt trong ReplicatedStorage > CustomModels (đúng tên)
--   2. Nếu không có -> tự dựng model TẠM (placeholder) bằng Part
--
-- Tên model cần có (thêm pet/rương/trứng/cần mới trong Config thì đặt model cùng tên):
--   Cần câu: "Basic Rod", "Sturdy Rod", "Pro Rod", "Legend Rod"
--            (phải là Tool, có Part "Handle", nên có Attachment "Tip" ở đầu cần)
--   Phao:    "Bobber"
--   Rương:   "Wooden Chest", "Golden Chest", "Diamond Chest"  (Part tên "Lid" sẽ được mở nắp)
--   Trứng:   "Common Egg", "Rare Egg"
--   Pet:     "Cat", "Dog", "Fox", "Dragon", "Phoenix"
--   Plot:    "Incubator" (nên có Attachment "EggPoint" = chỗ đặt trứng), "AutoFisher"
--   NPC:     "Shopkeeper", "Merchant"
-- Mặt trước của model = hướng -Z (LookVector). Nhớ đặt PrimaryPart cho Model.
-- Incubator / AutoFisher / NPC: đặt Pivot ở ĐÁY model (vì được đặt lên mặt bệ/sàn).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(script.Parent.Config)

local Models = {}

-- ===== Thông số model tạm =====
local CHESTS = {
	["Wooden Chest"] = { Color = Color3.fromRGB(140, 90, 45), Material = Enum.Material.Wood },
	["Golden Chest"] = { Color = Color3.fromRGB(255, 195, 40), Material = Enum.Material.Metal },
	["Diamond Chest"] = { Color = Color3.fromRGB(110, 220, 255), Material = Enum.Material.Neon },
}

local EGGS = {
	["Common Egg"] = { Color = Color3.fromRGB(245, 235, 200) },
	["Rare Egg"] = { Color = Color3.fromRGB(170, 90, 255), Glow = true },
}

local PETS = {
	Cat = { Color = Color3.fromRGB(255, 170, 60) },
	Dog = { Color = Color3.fromRGB(160, 110, 70) },
	Fox = { Color = Color3.fromRGB(230, 90, 30) },
	Dragon = { Color = Color3.fromRGB(60, 180, 80) },
	Phoenix = { Color = Color3.fromRGB(255, 80, 40), Material = Enum.Material.Neon, Fire = true },
}

local NPCS = {
	Shopkeeper = { Shirt = Color3.fromRGB(60, 110, 200) },
	Merchant = { Shirt = Color3.fromRGB(200, 70, 60) },
}

-- ===== Hàm dựng =====
local function newPart(parent, name, size, cframe, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cframe or CFrame.identity
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function nameTag(part, text, height)
	local bb = Instance.new("BillboardGui")
	bb.Name = "NameTag"
	bb.Size = UDim2.fromScale(4, 1)
	bb.StudsOffset = Vector3.new(0, height, 0)
	bb.MaxDistance = 80
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Parent = bb
	bb.Parent = part
end

-- Part gốc vô hình nằm sát đáy, pivot của model = đáy
local function bottomRoot(model, width)
	local root = newPart(model, "Root", Vector3.new(width, 0.2, width), CFrame.new(0, 0.1, 0), Color3.new(1, 1, 1))
	root.Transparency = 1
	root.PivotOffset = CFrame.new(0, -0.1, 0)
	model.PrimaryPart = root
	return root
end

local function buildRod(spec)
	local length = spec.Length or 7
	local tool = Instance.new("Tool")
	tool.Name = spec.Name
	tool.ToolTip = "Click to cast"
	tool.CanBeDropped = false
	-- Tay cầm ở giữa Handle (cán bọc cork), thân cần dựng lên trên theo hướng +Z của Handle
	tool.Grip = CFrame.new(0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0)

	local color = spec.Color or Color3.fromRGB(110, 70, 35)
	local metal = Color3.fromRGB(70, 70, 75)
	local handle = newPart(tool, "Handle", Vector3.new(0.32, 0.32, 1.6), nil, Color3.fromRGB(200, 160, 110), Enum.Material.Fabric)
	local parts = {
		newPart(tool, "ButtCap", Vector3.new(0.4, 0.4, 0.2), CFrame.new(0, 0, -0.9), Color3.fromRGB(30, 30, 30), Enum.Material.Metal),
		newPart(tool, "ReelSeat", Vector3.new(0.28, 0.28, 0.6), CFrame.new(0, 0, 1.1), metal, Enum.Material.Metal),
		-- Máy quay (reel) treo dưới cán, phía trước tay
		newPart(tool, "ReelStem", Vector3.new(0.1, 0.35, 0.1), CFrame.new(0, -0.3, 1.1), metal, Enum.Material.Metal),
		newPart(tool, "Reel", Vector3.new(0.4, 0.75, 0.75), CFrame.new(0, -0.7, 1.1), Color3.fromRGB(40, 40, 45), Enum.Material.Metal, Enum.PartType.Cylinder),
		newPart(tool, "ReelSpool", Vector3.new(0.42, 0.45, 0.45), CFrame.new(0, -0.7, 1.1), color, Enum.Material.Neon, Enum.PartType.Cylinder),
		newPart(tool, "Crank", Vector3.new(0.35, 0.08, 0.08), CFrame.new(0.35, -0.7, 1.1), metal, Enum.Material.Metal),
		newPart(tool, "Knob", Vector3.new(0.16, 0.16, 0.16), CFrame.new(0.55, -0.85, 1.1), Color3.fromRGB(30, 30, 30), nil, Enum.PartType.Ball),
	}
	-- Thân cần 3 đoạn thon dần
	local z = 1.4
	for i, seg in ipairs({ { 0.45, 0.2 }, { 0.35, 0.15 }, { 0.2, 0.09 } }) do
		local len = length * seg[1]
		table.insert(parts, newPart(tool, "Blank" .. i, Vector3.new(seg[2], seg[2], len), CFrame.new(0, 0, z + len / 2), color, Enum.Material.SmoothPlastic))
		-- khoen dẫn dây ở cuối mỗi đoạn
		table.insert(parts, newPart(tool, "Guide" .. i, Vector3.new(0.06, 0.3, 0.06), CFrame.new(0, -0.15 - seg[2] / 2, z + len - 0.1), metal, Enum.Material.Metal))
		z += len
	end

	handle.Anchored = false
	handle.Massless = true
	for _, p in ipairs(parts) do
		p.Anchored = false
		p.Massless = true
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = p
		weld.Parent = p
	end

	local tip = Instance.new("Attachment")
	tip.Name = "Tip"
	tip.Position = Vector3.new(0, 0, z)
	tip.Parent = handle
	return tool
end

local function buildBobber()
	local m = Instance.new("Model")
	m.Name = "Bobber"
	local float = newPart(m, "Float", Vector3.new(0.7, 0.7, 0.7), nil, Color3.fromRGB(230, 40, 40), nil, Enum.PartType.Ball)
	newPart(m, "Stick", Vector3.new(0.12, 0.5, 0.12), CFrame.new(0, 0.5, 0), Color3.new(1, 1, 1))
	m.PrimaryPart = float
	return m
end

local function buildChest(name, spec)
	local m = Instance.new("Model")
	m.Name = name
	local base = newPart(m, "Base", Vector3.new(3, 1.8, 2), nil, spec.Color, spec.Material)
	newPart(m, "Lid", Vector3.new(3, 0.6, 2), CFrame.new(0, 1.2, 0), spec.Color:Lerp(Color3.new(0, 0, 0), 0.15), spec.Material)
	newPart(m, "Lock", Vector3.new(0.5, 0.6, 0.2), CFrame.new(0, 0.8, -1.05), Color3.fromRGB(70, 70, 80), Enum.Material.Metal)
	m.PrimaryPart = base
	return m
end

local function buildEgg(name, spec)
	local m = Instance.new("Model")
	m.Name = name
	local shell = newPart(m, "Shell", Vector3.new(2, 2.6, 2), nil, spec.Color)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = shell
	if spec.Glow then
		local light = Instance.new("PointLight")
		light.Color = spec.Color
		light.Range = 8
		light.Parent = shell
	end
	nameTag(shell, name, 2.2)
	m.PrimaryPart = shell
	return m
end

local function buildPet(name, spec)
	local m = Instance.new("Model")
	m.Name = name
	local body = newPart(m, "Body", Vector3.new(2, 2, 2), nil, spec.Color, spec.Material, Enum.PartType.Ball)
	for _, x in ipairs({ -0.45, 0.45 }) do
		newPart(m, "Eye", Vector3.new(0.35, 0.35, 0.35), CFrame.new(x, 0.3, -0.85), Color3.fromRGB(25, 25, 25), nil, Enum.PartType.Ball)
		newPart(m, "Ear", Vector3.new(0.5, 0.6, 0.3), CFrame.new(x * 1.3, 1, 0) * CFrame.Angles(0, 0, -x), spec.Color, spec.Material)
	end
	if spec.Fire then
		local fire = Instance.new("Fire")
		fire.Size = 3
		fire.Parent = body
	end
	nameTag(body, name, 2)
	m.PrimaryPart = body
	return m
end

local UPRIGHT = CFrame.Angles(0, 0, math.rad(90)) -- xoay Part Cylinder (trục X) cho đứng thẳng

local function buildIncubator()
	local m = Instance.new("Model")
	m.Name = "Incubator"
	local root = bottomRoot(m, 4.4)
	local metal = Color3.fromRGB(85, 90, 105)
	local glow = Color3.fromRGB(80, 230, 255)

	-- Bệ tròn + vòng đèn
	newPart(m, "Base", Vector3.new(1, 4.4, 4.4), CFrame.new(0, 0.5, 0) * UPRIGHT, metal, Enum.Material.Metal, Enum.PartType.Cylinder)
	newPart(m, "Ring", Vector3.new(0.15, 4.6, 4.6), CFrame.new(0, 1.05, 0) * UPRIGHT, glow, Enum.Material.Neon, Enum.PartType.Cylinder)
	-- Ổ rơm cho trứng nằm
	newPart(m, "Nest", Vector3.new(0.4, 2.6, 2.6), CFrame.new(0, 1.2, 0) * UPRIGHT, Color3.fromRGB(220, 185, 100), Enum.Material.Fabric, Enum.PartType.Cylinder)
	-- Lồng kính
	local dome = newPart(m, "Dome", Vector3.new(3.8, 3.8, 3.8), CFrame.new(0, 2.7, 0), Color3.fromRGB(200, 240, 255), Enum.Material.Glass, Enum.PartType.Ball)
	dome.Transparency = 0.75
	for i = 0, 3 do
		local angle = math.rad(45 + i * 90)
		newPart(m, "Pillar", Vector3.new(0.22, 3.6, 0.22), CFrame.new(math.cos(angle) * 1.9, 2.8, math.sin(angle) * 1.9), metal, Enum.Material.Metal)
	end
	-- Nắp + đèn sưởi
	newPart(m, "Cap", Vector3.new(0.4, 2, 2), CFrame.new(0, 4.6, 0) * UPRIGHT, metal, Enum.Material.Metal, Enum.PartType.Cylinder)
	local lamp = newPart(m, "Lamp", Vector3.new(0.7, 0.7, 0.7), CFrame.new(0, 4.95, 0), Color3.fromRGB(255, 160, 60), Enum.Material.Neon, Enum.PartType.Ball)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 170, 80)
	light.Range = 10
	light.Brightness = 1.5
	light.Parent = lamp
	-- Bảng điều khiển phía trước
	newPart(m, "Panel", Vector3.new(1.4, 0.8, 0.3), CFrame.new(0, 0.55, -2.25), metal, Enum.Material.Metal)
	newPart(m, "Screen", Vector3.new(1, 0.45, 0.05), CFrame.new(0, 0.6, -2.42), Color3.fromRGB(90, 255, 140), Enum.Material.Neon)

	local eggPoint = Instance.new("Attachment")
	eggPoint.Name = "EggPoint"
	eggPoint.Position = Vector3.new(0, 2.6, 0) -- so với Root (tâm Root cao 0.1)
	eggPoint.Parent = root
	return m
end

local function buildAutoFisher()
	local m = Instance.new("Model")
	m.Name = "AutoFisher"
	bottomRoot(m, 3)
	local dark = Color3.fromRGB(55, 58, 65)
	local body = Color3.fromRGB(255, 170, 40)

	-- Đế + thân máy
	newPart(m, "Platform", Vector3.new(3, 0.4, 3), CFrame.new(0, 0.2, 0), dark, Enum.Material.DiamondPlate)
	newPart(m, "Housing", Vector3.new(2.2, 1.8, 2), CFrame.new(0, 1.3, 0.3), body, Enum.Material.Metal)
	newPart(m, "Stripe", Vector3.new(2.25, 0.25, 2.05), CFrame.new(0, 1.95, 0.3), Color3.fromRGB(25, 25, 25), Enum.Material.Metal)
	newPart(m, "Screen", Vector3.new(1.3, 0.6, 0.05), CFrame.new(0, 1.2, -0.72), Color3.fromRGB(80, 220, 255), Enum.Material.Neon)
	newPart(m, "Light", Vector3.new(0.4, 0.4, 0.4), CFrame.new(0.85, 2.3, -0.4), Color3.fromRGB(90, 255, 120), Enum.Material.Neon, Enum.PartType.Ball)

	-- Trống cuốn dây trên nóc (client quay nó qua tag "Spin")
	local drum = newPart(m, "Drum", Vector3.new(1.4, 0.9, 0.9), CFrame.new(0, 2.65, 0.3), Color3.fromRGB(150, 150, 160), Enum.Material.Metal, Enum.PartType.Cylinder)
	CollectionService:AddTag(drum, "Spin")
	for _, x in ipairs({ -0.8, 0.8 }) do
		newPart(m, "DrumMount", Vector3.new(0.15, 0.7, 0.4), CFrame.new(x, 2.5, 0.3), dark, Enum.Material.Metal)
	end

	-- Cột + cần câu chĩa ra trước (-Z), nghiêng lên 20 độ
	newPart(m, "Mast", Vector3.new(0.3, 2.6, 0.3), CFrame.new(0, 3.5, 1.05), dark, Enum.Material.Metal)
	local pole = newPart(m, "Pole", Vector3.new(0.2, 0.2, 7), CFrame.new(0, 4.6, 1.05) * CFrame.Angles(math.rad(20), 0, 0) * CFrame.new(0, 0, -3.5), Color3.fromRGB(40, 40, 45), Enum.Material.Metal)
	local tip = Instance.new("Attachment")
	tip.Name = "Tip"
	tip.Position = Vector3.new(0, 0, -3.5)
	tip.Parent = pole

	-- Phao nổi trên mặt nước phía trước máy (client làm nó nhấp nhô qua tag "Bobbing")
	local bobber = newPart(m, "Bobber", Vector3.new(0.6, 0.6, 0.6), CFrame.new(0, 0, -8.5), Color3.fromRGB(230, 40, 40), nil, Enum.PartType.Ball)
	CollectionService:AddTag(bobber, "Bobbing")
	local a1 = Instance.new("Attachment")
	a1.Parent = bobber
	local line = Instance.new("Beam")
	line.Attachment0 = tip
	line.Attachment1 = a1
	line.Width0 = 0.05
	line.Width1 = 0.05
	line.FaceCamera = true
	line.Color = ColorSequence.new(Color3.new(1, 1, 1))
	line.Parent = pole
	return m
end

local function buildNpc(name, spec)
	local m = Instance.new("Model")
	m.Name = name
	local skin = Color3.fromRGB(255, 205, 150)
	local torso = newPart(m, "Torso", Vector3.new(2, 2, 1), CFrame.new(0, 3, 0), spec.Shirt)
	torso.PivotOffset = CFrame.new(0, -3, 0)
	newPart(m, "Head", Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 4.6, 0), skin)
	for _, x in ipairs({ -0.25, 0.25 }) do
		newPart(m, "Eye", Vector3.new(0.2, 0.2, 0.1), CFrame.new(x, 4.7, -0.6), Color3.fromRGB(25, 25, 25))
	end
	for _, x in ipairs({ -1.5, 1.5 }) do
		newPart(m, "Arm", Vector3.new(1, 2, 1), CFrame.new(x, 3, 0), skin)
	end
	for _, x in ipairs({ -0.5, 0.5 }) do
		newPart(m, "Leg", Vector3.new(1, 2, 1), CFrame.new(x, 1, 0), Color3.fromRGB(50, 50, 70))
	end
	nameTag(torso, name, 3)
	m.PrimaryPart = torso
	return m
end

local function buildUnknown(name)
	local m = Instance.new("Model")
	m.Name = name
	local box = newPart(m, "Box", Vector3.new(2, 2, 2), nil, Color3.fromRGB(200, 200, 200))
	nameTag(box, name .. " (?)", 2)
	m.PrimaryPart = box
	return m
end

local builders = {
	Bobber = buildBobber,
	Incubator = buildIncubator,
	AutoFisher = buildAutoFisher,
}
local function register(specs, build)
	for name, spec in pairs(specs) do
		builders[name] = function()
			return build(name, spec)
		end
	end
end
register(CHESTS, buildChest)
register(EGGS, buildEgg)
register(PETS, buildPet)
register(NPCS, buildNpc)
for _, rod in ipairs(Config.Rods) do
	builders[rod.Name] = function()
		return buildRod(rod)
	end
end

-- Trả về 1 bản sao MỚI của model (chưa có Parent)
function Models.Get(name)
	local folder = ReplicatedStorage:FindFirstChild("CustomModels")
	local custom = folder and folder:FindFirstChild(name)

	local model
	if custom then
		model = custom:Clone()
	elseif builders[name] then
		model = builders[name]()
	else
		warn(("Models: no model named %q, using a grey box"):format(name))
		model = buildUnknown(name)
	end

	if model:IsA("Model") and not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
	end
	return model
end

-- Neo cố định toàn bộ Part (dùng cho đồ trang trí đặt trên map)
function Models.Anchor(model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	return model
end

return Models
