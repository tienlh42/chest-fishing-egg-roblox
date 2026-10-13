-- TỰ ĐỘNG lấy model free từ Marketplace -> làm sạch -> bỏ vào ReplicatedStorage > CustomModels.
-- CÁCH DÙNG: Studio -> View -> Command Bar -> dán TOÀN BỘ file này -> Enter. Xem kết quả ở Output.
--            Xong nhớ File > Save. Ctrl+Z để hoàn tác.
--
-- Với mỗi tên trong danh sách MODELS:
--   - Id > 0  : tải đúng model đó (Toolbox: chuột phải model -> "Copy Asset ID")
--   - Id = 0  : tự tìm theo Search, lấy kết quả thứ Pick (đổi Pick để thử model khác)
-- Sau đó: XOÁ mọi script trong model (model free hay chứa virus), đặt PrimaryPart,
-- chỉnh kích thước, đặt pivot, máy ấp thêm "EggPoint", cần câu thành Tool có "Handle" + "Tip".
-- Chạy lại nhiều lần được: đã có model thì bỏ qua (trừ khi REPLACE_EXISTING = true).
-- Model nào đã có sẵn trong CustomModels (bạn tự kéo vào) cũng được làm sạch luôn.

local REPLACE_EXISTING = false

local MODELS = {
	{ Name = "Basic Rod", Id = 0, Search = "fishing rod", Pick = 1 },
	{ Name = "Sturdy Rod", Id = 0, Search = "fishing rod", Pick = 2 },
	{ Name = "Pro Rod", Id = 0, Search = "fishing rod", Pick = 3 },
	{ Name = "Legend Rod", Id = 0, Search = "fishing rod", Pick = 4 },
	{ Name = "Incubator", Id = 0, Search = "egg incubator", Pick = 1 },
	{ Name = "AutoFisher", Id = 0, Search = "fishing machine", Pick = 1 },
	{ Name = "Bobber", Id = 0, Search = "fishing bobber", Pick = 1 },
	{ Name = "Common Egg", Id = 0, Search = "pet egg", Pick = 1 },
	{ Name = "Rare Egg", Id = 0, Search = "pet egg", Pick = 2 },
	{ Name = "Wooden Chest", Id = 0, Search = "wooden chest", Pick = 1 },
	{ Name = "Golden Chest", Id = 0, Search = "golden chest", Pick = 1 },
	{ Name = "Diamond Chest", Id = 0, Search = "diamond chest", Pick = 1 },
	{ Name = "Cat", Id = 0, Search = "cat pet", Pick = 1 },
	{ Name = "Dog", Id = 0, Search = "dog pet", Pick = 1 },
	{ Name = "Fox", Id = 0, Search = "fox pet", Pick = 1 },
	{ Name = "Dragon", Id = 0, Search = "dragon pet", Pick = 1 },
	{ Name = "Phoenix", Id = 0, Search = "phoenix pet", Pick = 1 },
	{ Name = "Shopkeeper", Id = 0, Search = "shopkeeper npc", Pick = 1 },
	{ Name = "Merchant", Id = 0, Search = "merchant npc", Pick = 1 },
}

-- Chiều cao mong muốn (stud)
local TARGET_HEIGHT = {
	Incubator = 5,
	AutoFisher = 5,
	Shopkeeper = 5,
	Merchant = 5,
	Bobber = 0.8,
	["Common Egg"] = 2.6,
	["Rare Egg"] = 2.6,
	["Wooden Chest"] = 2.4,
	["Golden Chest"] = 2.4,
	["Diamond Chest"] = 2.4,
	Cat = 2.5,
	Dog = 2.5,
	Fox = 2.5,
	Dragon = 3,
	Phoenix = 3,
}
-- Các model đặt lên mặt bệ/sàn -> pivot ở đáy
local BOTTOM_PIVOT = { Incubator = true, AutoFisher = true, Shopkeeper = true, Merchant = true }
local RODS = { ["Basic Rod"] = true, ["Sturdy Rod"] = true, ["Pro Rod"] = true, ["Legend Rod"] = true }
local MAX_TRIES = 5 -- thử tối đa bao nhiêu kết quả tìm kiếm cho 1 model

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local InsertService = game:GetService("InsertService")
local CustomModels = game:GetService("ReplicatedStorage"):FindFirstChild("CustomModels")
assert(CustomModels, "Missing ReplicatedStorage > CustomModels (connect Rojo first)")

-- ===== Tải model =====
local searchCache = {}

local function searchFree(keyword)
	if searchCache[keyword] == nil then
		local ok, pages = pcall(InsertService.GetFreeModels, InsertService, keyword, 0)
		local results = ok and pages and pages[1] and pages[1].Results
		searchCache[keyword] = results or false
		if not results then
			warn(("Search failed for %q. Fill Id manually (Toolbox: right click -> Copy Asset ID)."):format(keyword))
		end
	end
	return searchCache[keyword] or {}
end

local function loadAsset(id)
	local ok, objects = pcall(function()
		return game:GetObjects("rbxassetid://" .. id)
	end)
	if ok and objects and objects[1] then
		return objects[1]
	end
	local ok2, container = pcall(InsertService.LoadAsset, InsertService, id)
	if ok2 and container then
		local child = container:GetChildren()[1]
		if child then
			child.Parent = nil
		end
		container:Destroy()
		return child
	end
	return nil
end

local function hasParts(inst)
	return inst:IsA("BasePart") or inst:FindFirstChildWhichIsA("BasePart", true) ~= nil
end

local function fetch(entry)
	if entry.Id and entry.Id > 0 then
		local obj = loadAsset(entry.Id)
		return obj, entry.Id
	end
	local results = searchFree(entry.Search)
	local start = entry.Pick or 1
	for i = start, math.min(start + MAX_TRIES - 1, #results) do
		local id = results[i].AssetId
		local obj = id and loadAsset(id)
		if obj and hasParts(obj) then
			return obj, id
		elseif obj then
			obj:Destroy()
		end
	end
	return nil, nil
end

-- ===== Làm sạch & chuẩn hoá =====
local function stripScripts(root)
	local removed = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("LuaSourceContainer") and d.Parent then
			d:Destroy()
			removed += 1
		end
	end
	return removed
end

local function largestPart(root)
	local best, bestVolume = nil, -1
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			local volume = d.Size.X * d.Size.Y * d.Size.Z
			if volume > bestVolume then
				best, bestVolume = d, volume
			end
		end
	end
	return best
end

-- Gói mọi thứ vào 1 Model (vật tải về có thể là Part, Tool, Folder...)
local function asModel(obj, name)
	if obj:IsA("Model") then
		obj.Name = name
		return obj
	end
	local model = Instance.new("Model")
	model.Name = name
	if obj:IsA("BasePart") then
		obj.Parent = model
	else
		for _, child in ipairs(obj:GetChildren()) do
			child.Parent = model
		end
		obj:Destroy()
	end
	return model
end

-- Cần câu phải là Tool
local function asTool(obj, name)
	local tool = obj:IsA("Tool") and obj or obj:FindFirstChildWhichIsA("Tool", true)
	if tool then
		if tool ~= obj then
			tool.Parent = nil
			obj:Destroy()
		end
		tool.Name = name
		return tool
	end
	tool = Instance.new("Tool")
	tool.Name = name
	if obj:IsA("BasePart") then
		obj.Parent = tool
	else
		for _, child in ipairs(obj:GetChildren()) do
			child.Parent = tool
		end
		obj:Destroy()
	end
	return tool
end

local function prepModel(model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
		end
	end
	model.PrimaryPart = model.PrimaryPart or largestPart(model)
	if not model.PrimaryPart then
		warn(model.Name .. ": has no parts")
		return
	end

	local target = TARGET_HEIGHT[model.Name]
	if target then
		local _, size = model:GetBoundingBox()
		if size.Y > 0 then
			model:ScaleTo(model:GetScale() * target / size.Y)
		end
	end

	local box, size = model:GetBoundingBox()
	local pivotPos = BOTTOM_PIVOT[model.Name] and box.Position - Vector3.new(0, size.Y / 2, 0) or box.Position
	local pivot = CFrame.new(pivotPos) * model:GetPivot().Rotation
	model.PrimaryPart.PivotOffset = model.PrimaryPart.CFrame:ToObjectSpace(pivot)

	if model.Name == "Incubator" and not model:FindFirstChild("EggPoint", true) then
		local point = Instance.new("Attachment")
		point.Name = "EggPoint"
		point.Parent = model.PrimaryPart
		point.WorldCFrame = CFrame.new(box.Position) -- giữa thân máy, chỉnh tay nếu lệch
	end
end

local function prepRod(tool)
	tool.CanBeDropped = false
	tool.RequiresHandle = true

	local handle = tool:FindFirstChild("Handle")
	if not (handle and handle:IsA("BasePart")) then
		handle = largestPart(tool)
		if not handle then
			warn(tool.Name .. ": has no parts")
			return
		end
		handle.Name = "Handle"
		handle.Parent = tool
	end

	-- Hàn mọi Part vào Handle, Part xa Handle nhất = đầu cần
	local farthest, farDist = handle, 0
	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.Massless = true
			if d ~= handle then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = handle
				weld.Part1 = d
				weld.Parent = d
				local dist = (d.Position - handle.Position).Magnitude
				if dist > farDist then
					farthest, farDist = d, dist
				end
			end
		end
	end

	if not tool:FindFirstChild("Tip", true) then
		local tip = Instance.new("Attachment")
		tip.Name = "Tip"
		tip.Parent = handle
		tip.WorldCFrame = CFrame.new(farthest.Position) -- chỉnh tay ra đúng đầu cần nếu lệch
	end
end

-- Làm sạch + chuẩn hoá 1 vật, trả về vật cuối cùng (có thể đã được gói lại)
local function prepare(obj, name)
	local removed = stripScripts(obj)
	if removed > 0 then
		print(("  [%s] removed %d script(s)"):format(name, removed))
	end
	if RODS[name] then
		local tool = asTool(obj, name)
		prepRod(tool)
		return tool
	end
	local model = asModel(obj, name)
	prepModel(model)
	return model
end

-- ===== Chạy =====
ChangeHistoryService:SetWaypoint("Before SetupFreeModels")
local added, skipped, failed = 0, 0, {}

for _, entry in ipairs(MODELS) do
	local existing = CustomModels:FindFirstChild(entry.Name)
	if existing and not REPLACE_EXISTING then
		-- Đã có (vd. bạn tự kéo vào): chỉ làm sạch, chỉ chạy 1 lần
		if not existing:GetAttribute("Prepared") then
			existing.Parent = nil
			local result = prepare(existing, entry.Name)
			result:SetAttribute("Prepared", true)
			result.Parent = CustomModels
			print(("[%s] cleaned existing model"):format(entry.Name))
		end
		skipped += 1
	else
		local obj, assetId = fetch(entry)
		if obj then
			local result = prepare(obj, entry.Name)
			result:SetAttribute("Prepared", true)
			result:SetAttribute("SourceAssetId", assetId) -- để biết sau này cần thay model nào
			if existing then
				existing:Destroy()
			end
			result.Parent = CustomModels
			added += 1
			print(("[%s] added from asset %d"):format(entry.Name, assetId))
		else
			table.insert(failed, entry.Name)
		end
	end
end

ChangeHistoryService:SetWaypoint("After SetupFreeModels")
print(("SetupFreeModels done: %d added, %d already there, %d failed"):format(added, skipped, #failed))
if #failed > 0 then
	warn("Failed: " .. table.concat(failed, ", ") .. " -> set Id manually or change Search/Pick, then run again.")
end
print("Press Play to check, then File > Save. Delete a model in CustomModels to go back to the placeholder.")
