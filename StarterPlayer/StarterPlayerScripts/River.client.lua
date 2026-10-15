-- LocalScript: StarterPlayerScripts > River
-- Làm sông vòng quanh các nhà "chảy": lá và vịt cao su trôi chậm dọc dòng (theo Config.River). Terrain Water không tự chảy,
-- nên đây là hoạt ảnh giả chạy hoàn toàn ở client (không tốn server). Mọi thứ chỉ là Part nhỏ, không va chạm.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Config)

local river = Config.River
local LEAF_COUNT, DUCK_COUNT = 40, 8
local WATER_Y = 0.1

local folder = Instance.new("Folder")
folder.Name = "RiverFlow"
folder.Parent = workspace

local rng = Random.new(7)
local items = {} -- { Angle, Offset, Speed, Parts = { { Part, Rel CFrame } }, Bob }

local function newPart(shape, size, color, material)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Shape = shape
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = folder
	return p
end

local LEAF_COLORS = { Color3.fromRGB(92, 214, 107), Color3.fromRGB(70, 160, 70), Color3.fromRGB(255, 140, 26), Color3.fromRGB(242, 194, 48) }

local function addLeaf(index)
	local leaf = newPart(Enum.PartType.Cylinder, Vector3.new(0.12, 1.4, 1.4), LEAF_COLORS[index % #LEAF_COLORS + 1])
	table.insert(items, { Angle = rng:NextNumber(0, math.pi * 2), Offset = rng:NextNumber(-1, 1) * (river.Width / 2 - 1.2), Speed = rng:NextNumber(0.85, 1.15), Parts = { { leaf, CFrame.Angles(0, 0, math.rad(90)) } }, Bob = rng:NextNumber(0, 6) })
end

local function addDuck()
	local body = newPart(Enum.PartType.Ball, Vector3.new(1.7, 1.2, 2.2), Color3.fromRGB(242, 194, 48))
	Instance.new("SpecialMesh", body).MeshType = Enum.MeshType.Sphere
	local head = newPart(Enum.PartType.Ball, Vector3.new(1.0, 1.0, 1.0), Color3.fromRGB(242, 194, 48))
	local beak = newPart(Enum.PartType.Block, Vector3.new(0.5, 0.2, 0.6), Color3.fromRGB(255, 140, 26))
	local eyeL = newPart(Enum.PartType.Ball, Vector3.new(0.18, 0.18, 0.18), Color3.fromRGB(28, 28, 30))
	local eyeR = newPart(Enum.PartType.Ball, Vector3.new(0.18, 0.18, 0.18), Color3.fromRGB(28, 28, 30))
	table.insert(items, {
		Angle = rng:NextNumber(0, math.pi * 2),
		Offset = rng:NextNumber(-1, 1) * (river.Width / 2 - 2),
		Speed = rng:NextNumber(0.9, 1.05),
		Bob = rng:NextNumber(0, 6),
		Duck = true,
		Parts = {
			{ body, CFrame.new(0, 0.55, 0) },
			{ head, CFrame.new(0, 1.5, -0.7) },
			{ beak, CFrame.new(0, 1.4, -1.3) },
			{ eyeL, CFrame.new(-0.28, 1.65, -1.1) },
			{ eyeR, CFrame.new(0.28, 1.65, -1.1) },
		},
	})
end

for i = 1, LEAF_COUNT do
	addLeaf(i)
end
for _ = 1, DUCK_COUNT do
	addDuck()
end

local omegaBase = river.FlowSpeed / ((river.Rx + river.Rz) / 2) -- rad/giây, gần đúng theo chu vi trung bình

RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	for _, item in ipairs(items) do
		item.Angle += omegaBase * item.Speed * dt
		local a = item.Angle
		local x, z = river.Rx * math.cos(a), river.Rz * math.sin(a)
		-- pháp tuyến elip (hướng ra ngoài) để lệch ngang dòng, tiếp tuyến để quay mặt theo chiều trôi
		local nx, nz = x / river.Rx ^ 2, z / river.Rz ^ 2
		local nlen = math.sqrt(nx * nx + nz * nz)
		nx, nz = nx / nlen, nz / nlen
		local pos = Vector3.new(x + nx * item.Offset, WATER_Y + math.sin(t * 1.6 + item.Bob) * 0.06, z + nz * item.Offset)
		local forward = Vector3.new(-river.Rx * math.sin(a), 0, river.Rz * math.cos(a)).Unit -- chiều tăng góc (ngược kim đồng hồ nhìn từ trên)
		local base = CFrame.lookAt(pos, pos + forward)
		if item.Duck then
			base *= CFrame.Angles(0, 0, math.sin(t * 1.3 + item.Bob) * 0.06)
		else
			base *= CFrame.Angles(0, math.sin(t * 0.6 + item.Bob) * 0.5, 0)
		end
		for _, pair in ipairs(item.Parts) do
			pair[1].CFrame = base * pair[2]
		end
	end
end)
