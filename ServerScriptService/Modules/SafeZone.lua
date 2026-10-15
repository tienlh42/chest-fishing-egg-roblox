-- ModuleScript: ServerScriptService > Modules > SafeZone
-- Vùng an toàn: ngỗng không vào, pet hồi HP, được cất đồ ở Stash.
-- THEO TỪNG NGƯỜI: hộp quanh mỗi nhà chỉ an toàn cho CHỦ nhà đó (attribute OwnerId của Plot). Sân người khác, kể cả nhà chưa có chủ,
-- không an toàn (kẻ cướp đứng trong sân nạn nhân vẫn bị ngỗng đuổi). Vùng chung (điểm hồi sinh / Plaza) an toàn cho mọi người.
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

-- Plot (Model con trực tiếp của folder "Plots") chứa vùng này, nil nếu là vùng chung
local function plotOfZone(part)
	local node = part.Parent
	while node and node.Parent do
		if node.Parent.Name == "Plots" then
			return node
		end
		node = node.Parent
	end
	return nil
end

-- `position` có an toàn cho `player` không: trong vùng chung, hoặc trong hộp quanh nhà CỦA player
function SafeZone.Contains(position, player)
	for _, part in ipairs(zones) do
		local plot = plotOfZone(part)
		if plot and not (player and plot:GetAttribute("OwnerId") == player.UserId) then
			continue
		end
		local p = part.CFrame:PointToObjectSpace(position)
		local half = part.Size / 2
		if math.abs(p.X) <= half.X and math.abs(p.Y) <= half.Y and math.abs(p.Z) <= half.Z then
			return true
		end
	end
	return false
end

-- Plot (Model) có hộp vùng chứa `position`, nil nếu đứng ngoài mọi plot (không phân biệt chủ)
function SafeZone.PlotAt(position)
	for _, part in ipairs(zones) do
		local plot = plotOfZone(part)
		if plot then
			local p = part.CFrame:PointToObjectSpace(position)
			local half = part.Size / 2
			if math.abs(p.X) <= half.X and math.abs(p.Y) <= half.Y and math.abs(p.Z) <= half.Z then
				return plot
			end
		end
	end
	return nil
end

function SafeZone.IsSafe(player)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	return hrp ~= nil and SafeZone.Contains(hrp.Position, player)
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
