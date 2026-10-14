-- ModuleScript: ServerScriptService > Modules > SafeZone
-- Vùng an toàn: ngỗng không vào, pet hồi HP, được cất đồ ở Stash.
-- Nếu map có sẵn Part tên "SafeZone" thì dùng đúng những Part đó. Không có thì tự tạo (vô hình) bao quanh
-- từng Plot (+ quanh điểm hồi sinh nếu map không có Plaza). Stash nằm trong từng nhà (HouseBuilder dựng, Plots gắn nút [E] cho chủ nhà).

local SafeZone = {}

local zones = {} -- các Part vô hình, dùng kích thước + CFrame làm hộp kiểm tra
local ZONE_HEIGHT = 80
local ZONE_MARGIN = 6 -- nới thêm quanh mỗi Plot cho thoải mái

local function addZone(parent, cframe, size)
	local part = Instance.new("Part")
	part.Name = "SafeZone"
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Parent = parent
	table.insert(zones, part)
end

local function addZoneAround(model)
	-- Giữ hướng xoay của model (các nhà xếp vòng tròn nên nằm nghiêng)
	local cf, size = model:GetBoundingBox()
	addZone(model, cf, Vector3.new(size.X + ZONE_MARGIN, ZONE_HEIGHT, size.Z + ZONE_MARGIN))
end

function SafeZone.Contains(position)
	for _, part in ipairs(zones) do
		local p = part.CFrame:PointToObjectSpace(position)
		local half = part.Size / 2
		if math.abs(p.X) <= half.X and math.abs(p.Y) <= half.Y and math.abs(p.Z) <= half.Z then
			return true
		end
	end
	return false
end

function SafeZone.IsSafe(player)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	return hrp ~= nil and SafeZone.Contains(hrp.Position)
end

function SafeZone.Init(map)
	for _, d in ipairs(map:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "SafeZone" then
			table.insert(zones, d)
		end
	end

	local spawn = map:FindFirstChild("Spawn", true)
	local plaza = map:FindFirstChild("Plaza")
	if #zones == 0 then
		if plaza and plaza:IsA("Model") then
			addZoneAround(plaza)
		elseif spawn then
			addZone(map, CFrame.new(spawn.Position), Vector3.new(60, ZONE_HEIGHT, 60))
		end
		local plots = map:FindFirstChild("Plots")
		for _, plot in ipairs(plots and plots:GetChildren() or {}) do
			if plot:IsA("Model") then
				addZoneAround(plot)
			end
		end
	end
end

return SafeZone
