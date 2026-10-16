-- ModuleScript: ServerScriptService > Modules > ShopBuilder
-- Khu CHỢ: Tool Shop (bán cần / máy, người bán là Bác Vịt Câu Cá) và Market (thu mua trứng / pet, người bán là Cô Mèo Thu Mua)
-- dựng SÁT NHAU thành một quảng trường, theo docs/Art/STYLE_GUIDE.md (chunky, màu tươi, nét hài, vật phẩm có "linh hồn thú vật").
-- Tool Shop: biển cá khổng lồ há miệng, tường trưng bày 6 cần câu (đủ thứ tự trong Config.Rods), tủ máy câu.
-- Market: biển đồng xu có tai mèo, rổ trứng trên quầy.
-- Mọi thứ dựng bằng Part (đồ tạm, sau thay model thật). Tên Part cần cho code khác (KHÔNG đổi): "ToolShop" / "Market" (Model) có "PromptPart".
-- Hoạt ảnh đứng nhún nhẹ: gắn tag "Bobbing" (Effects.client.lua).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local Models = require(ReplicatedStorage.Models)
local BuildUtil = require(script.Parent.BuildUtil)

local block, ball, cylinder, decor, surfaceText = BuildUtil.block, BuildUtil.ball, BuildUtil.cylinder, BuildUtil.decor, BuildUtil.surfaceText
local C = BuildUtil.Colors

local ShopBuilder = {}

-- Bảng màu theo STYLE_GUIDE mục 2
local PALETTE = {
	Milk = Color3.fromRGB(245, 245, 240),
	Ink = Color3.fromRGB(28, 28, 30),
	Silver = Color3.fromRGB(205, 208, 215),
	Navy = Color3.fromRGB(31, 58, 104),
	Orange = Color3.fromRGB(255, 140, 26),
	Yellow = Color3.fromRGB(242, 194, 48),
	Pink = Color3.fromRGB(255, 111, 181),
	Sky = Color3.fromRGB(61, 184, 245),
	Green = Color3.fromRGB(92, 214, 107),
	Coral = Color3.fromRGB(255, 90, 77),
	Wood = Color3.fromRGB(181, 115, 60),
	DarkWood = Color3.fromRGB(122, 74, 36),
	Cream = Color3.fromRGB(240, 230, 205),
}

-- Màu viền theo thứ hạng (trùng RARITY_COLORS của UI)
local RANK_COLORS = {
	Color3.fromRGB(235, 235, 245),
	Color3.fromRGB(110, 210, 130),
	Color3.fromRGB(90, 170, 255),
	Color3.fromRGB(190, 120, 255),
	Color3.fromRGB(255, 205, 70),
	Color3.fromRGB(255, 130, 200),
}

local W, D = 26, 22 -- rộng x sâu mỗi gian
local SHOP_OFFSET = 15 -- 2 gian cách tâm quảng trường ±15 (hở 4 stud ở giữa)

-- ===== Tiện ích =====
-- Khối cầu / elip (Part + SpecialMesh Sphere), không cản đường
local function ellipsoid(parent, name, size, cframe, color, material)
	local p = block(parent, name, size, cframe, color, material)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return decor(p)
end

-- Đĩa tròn trục Z (mặt quay -Z): đồng xu, tròng kính
local function disc(parent, name, thickness, diameter, cframe, color, material)
	local p = block(parent, name, Vector3.new(thickness, diameter, diameter), cframe * CFrame.Angles(0, math.rad(90), 0), color, material)
	p.Shape = Enum.PartType.Cylinder
	return decor(p)
end

-- Mắt to có đốm sáng (STYLE_GUIDE 4.1): tròng trắng, đồng tử đen, 1 đốm sáng
local function addEyes(parent, cf, spacing, size)
	for _, side in ipairs({ -1, 1 }) do
		local x = side * spacing
		ellipsoid(parent, "EyeWhite", Vector3.new(size, size * 1.15, size * 0.5), cf * CFrame.new(x, 0, 0), PALETTE.Milk)
		ellipsoid(parent, "Pupil", Vector3.new(size * 0.55, size * 0.65, size * 0.3), cf * CFrame.new(x, -size * 0.05, -size * 0.22), PALETTE.Ink)
		ellipsoid(parent, "EyeShine", Vector3.new(size * 0.2, size * 0.2, size * 0.1), cf * CFrame.new(x + size * 0.12, size * 0.12, -size * 0.38), PALETTE.Milk)
	end
end

-- Cho model đứng nhún nhẹ (client chạy tag Bobbing)
local function bob(model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			CollectionService:AddTag(d, "Bobbing")
		end
	end
end

-- Tỏa sáng viền nhẹ cho người bán (STYLE_GUIDE mục 3: vật tương tác có viền)
local function outline(model)
	local h = Instance.new("Highlight")
	h.FillTransparency = 1
	h.OutlineColor = PALETTE.Ink
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = model
end

-- ===== Người bán =====
-- Bác Vịt Câu Cá: mũ vành nhỏ hơn đầu, tuột lệch, cắm 3 cần câu; ghi-lê navy, thắt lưng móc câu.
local function buildDuck(parent, cf)
	local npc = Instance.new("Model")
	npc.Name = "Shopkeeper"
	ellipsoid(npc, "Body", Vector3.new(4.8, 4.8, 4.2), cf * CFrame.new(0, 3.1, 0), PALETTE.Yellow)
	ellipsoid(npc, "Belly", Vector3.new(3.4, 3.2, 1.4), cf * CFrame.new(0, 2.9, -1.6), PALETTE.Milk)
	block(npc, "Vest", Vector3.new(3.6, 2.2, 0.4), cf * CFrame.new(0, 3.4, -2.0), PALETTE.Navy)
	block(npc, "Belt", Vector3.new(4.4, 0.4, 0.5), cf * CFrame.new(0, 2.0, -1.95), PALETTE.DarkWood)
	for i, x in ipairs({ -1.4, 0, 1.4 }) do
		ball(npc, "Hook" .. i, 0.4, cf:PointToWorldSpace(Vector3.new(x, 1.6, -2.1)), PALETTE.Silver, Enum.Material.Metal)
	end
	ellipsoid(npc, "Head", Vector3.new(4.0, 3.8, 3.6), cf * CFrame.new(0, 6.5, -0.3), PALETTE.Yellow)
	ellipsoid(npc, "Beak", Vector3.new(2.4, 1.0, 2.0), cf * CFrame.new(0, 6.1, -2.3), PALETTE.Orange)
	addEyes(npc, cf * CFrame.new(0, 7.1, -1.75), 0.9, 1.1)
	-- Nét hài: mũ nhỏ hơn đầu, tụt lệch về một bên
	local hat = cf * CFrame.new(0.5, 8.3, -0.3) * CFrame.Angles(0, 0, math.rad(-11))
	cylinder(npc, "HatBrim", 0.3, 4.6, hat, PALETTE.Cream)
	cylinder(npc, "HatCrown", 1.5, 2.8, hat * CFrame.new(0, 0.9, 0), PALETTE.Cream)
	cylinder(npc, "HatBand", 0.4, 2.9, hat * CFrame.new(0, 0.45, 0), PALETTE.Coral)
	-- 3 cần câu cắm trên mũ (đọc được nghề từ silhouette)
	for i, angle in ipairs({ -32, 4, 36 }) do
		local rod = hat * CFrame.new(angle * 0.05, 1.5, 0) * CFrame.Angles(0, 0, math.rad(-angle)) * CFrame.new(0, 2.8, 0)
		decor(block(npc, "HatRod" .. i, Vector3.new(0.18, 5.6, 0.18), rod, PALETTE.Silver, Enum.Material.Metal))
		ball(npc, "HatBobber" .. i, 0.55, rod:PointToWorldSpace(Vector3.new(0, 2.9, 0)), PALETTE.Coral)
	end
	for _, side in ipairs({ -1, 1 }) do
		ellipsoid(npc, "Wing", Vector3.new(1.3, 2.8, 1.8), cf * CFrame.new(side * 2.8, 3.3, 0) * CFrame.Angles(0, 0, math.rad(side * 14)), PALETTE.Yellow)
		ellipsoid(npc, "Foot", Vector3.new(1.8, 0.5, 2.4), cf * CFrame.new(side * 1.0, 0.45, -0.7), PALETTE.Orange)
	end
	for _, d in ipairs(npc:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanCollide = false
		end
	end
	bob(npc)
	outline(npc)
	npc.PrimaryPart = npc:FindFirstChild("Body")
	npc.Parent = parent
	return npc
end

-- Cô Mèo Thu Mua: kính tròn, mũ lưỡi trai xanh của kế toán, đuôi cong, cà vạt đỏ.
local function buildCat(parent, cf)
	local npc = Instance.new("Model")
	npc.Name = "Merchant"
	local fur = PALETTE.Silver
	ellipsoid(npc, "Body", Vector3.new(4.6, 4.8, 4.0), cf * CFrame.new(0, 3.1, 0), fur)
	ellipsoid(npc, "Belly", Vector3.new(3.2, 3.2, 1.4), cf * CFrame.new(0, 2.9, -1.5), PALETTE.Milk)
	block(npc, "Shirt", Vector3.new(3.4, 2.2, 0.4), cf * CFrame.new(0, 3.4, -1.95), PALETTE.Green)
	block(npc, "Tie", Vector3.new(0.7, 1.6, 0.3), cf * CFrame.new(0, 3.6, -2.25), PALETTE.Coral)
	ellipsoid(npc, "Head", Vector3.new(4.2, 3.8, 3.6), cf * CFrame.new(0, 6.5, -0.3), fur)
	for _, side in ipairs({ -1, 1 }) do
		local ear = cf * CFrame.new(side * 1.5, 8.6, -0.3) * CFrame.Angles(0, 0, math.rad(45))
		decor(block(npc, "Ear", Vector3.new(1.5, 1.5, 0.8), ear, fur))
		decor(block(npc, "EarInner", Vector3.new(0.8, 0.8, 0.3), ear * CFrame.new(0, 0, -0.35), PALETTE.Pink))
		for i = -1, 1 do
			decor(block(npc, "Whisker", Vector3.new(1.8, 0.07, 0.07), cf * CFrame.new(side * 2.4, 6.2 + i * 0.3, -1.6) * CFrame.Angles(0, 0, math.rad(side * i * -12)), PALETTE.Ink))
		end
		ellipsoid(npc, "Paw", Vector3.new(1.3, 2.8, 1.8), cf * CFrame.new(side * 2.7, 3.3, 0) * CFrame.Angles(0, 0, math.rad(side * 14)), fur)
		ellipsoid(npc, "Foot", Vector3.new(1.8, 0.5, 2.4), cf * CFrame.new(side * 1.0, 0.45, -0.7), PALETTE.Milk)
	end
	addEyes(npc, cf * CFrame.new(0, 7.0, -1.7), 0.95, 1.1)
	ellipsoid(npc, "Nose", Vector3.new(0.6, 0.45, 0.4), cf * CFrame.new(0, 6.4, -1.85), PALETTE.Pink)
	-- kính tròn (tròng mờ) + mũ lưỡi trai xanh
	for _, side in ipairs({ -1, 1 }) do
		local lens = disc(npc, "Lens", 0.12, 1.7, cf * CFrame.new(side * 0.95, 7.0, -2.05), PALETTE.Sky)
		lens.Transparency = 0.65
	end
	block(npc, "VisorBand", Vector3.new(4.0, 0.4, 3.0), cf * CFrame.new(0, 8.3, -0.5) * CFrame.Angles(math.rad(-6), 0, 0), PALETTE.Green)
	block(npc, "VisorBrim", Vector3.new(3.6, 0.2, 1.8), cf * CFrame.new(0, 8.2, -2.1) * CFrame.Angles(math.rad(14), 0, 0), PALETTE.Green)
	-- đuôi cong
	for i = 1, 3 do
		ellipsoid(npc, "Tail" .. i, Vector3.new(0.9, 1.4, 0.9), cf * CFrame.new(0, 1.6 + i * 1.1, 2.2 + math.sin(i) * 0.5), fur)
	end
	for _, d in ipairs(npc:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanCollide = false
		end
	end
	bob(npc)
	outline(npc)
	npc.PrimaryPart = npc:FindFirstChild("Body")
	npc.Parent = parent
	return npc
end

-- ===== Bộ khung gian hàng =====
-- cf: tâm sàn gian, -Z = mặt trước. Trả về Model.
local function buildShell(parent, name, cf, roofColor, titleText)
	local stall = Instance.new("Model")
	stall.Name = name
	block(stall, "Floor", Vector3.new(W, 1, D), cf, PALETTE.Wood, Enum.Material.WoodPlanks)
	block(stall, "BackWall", Vector3.new(W, 10, 1), cf * CFrame.new(0, 5.5, D / 2 - 0.5), PALETTE.Cream, Enum.Material.Brick)
	for _, x in ipairs({ -(W / 2 - 0.5), W / 2 - 0.5 }) do
		block(stall, "SideWall", Vector3.new(1, 10, D), cf * CFrame.new(x, 5.5, 0), PALETTE.Cream, Enum.Material.Brick)
	end
	block(stall, "Roof", Vector3.new(W + 2, 1, D + 2), cf * CFrame.new(0, 11, 0), roofColor)
	-- mép mái cuốn sóng: dãy bóng tròn xen kẽ trắng / màu mái dọc mép trước (mái hình rèm cuốn)
	local count = 7
	for i = 0, count do
		local x = -W / 2 + 1 + i * ((W - 2) / count)
		ball(stall, "Scallop", 3.8, cf:PointToWorldSpace(Vector3.new(x, 10.3, -D / 2 - 0.4)), i % 2 == 0 and roofColor or PALETTE.Milk)
	end
	-- quầy có nút [E]
	local counter = block(stall, "PromptPart", Vector3.new(14, 3, 3), cf * CFrame.new(0, 2, -2.5), PALETTE.DarkWood, Enum.Material.Wood)
	block(stall, "CounterTop", Vector3.new(15, 0.4, 3.6), cf * CFrame.new(0, 3.7, -2.5), PALETTE.Wood, Enum.Material.Wood)
	-- bảng tên treo dưới mái
	local board = block(stall, "SignBoard", Vector3.new(16, 2.4, 0.6), cf * CFrame.new(0, 12.9, -D / 2 - 1.4), PALETTE.Navy)
	surfaceText(board, titleText, PALETTE.Yellow)
	stall.Parent = parent
	return stall, counter
end

-- Đặt model (Tool hay Model) đứng thẳng, cao `height` stud, đáy chạm cframe. pcall: thiếu asset thì bỏ qua
local function placeUpright(parent, name, cframe, height)
	local ok, model = pcall(Models.Get, name)
	if not ok or not model then
		return nil
	end
	if model:IsA("Tool") then
		local wrap = Instance.new("Model")
		wrap.Name = name
		for _, child in ipairs(model:GetChildren()) do
			child.Parent = wrap
		end
		model:Destroy()
		model = wrap
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("LuaSourceContainer") or d:IsA("Humanoid") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
		end
	end
	-- đưa về hướng chuẩn, dựng đứng nếu model nằm ngang, co về đúng chiều cao, xoay theo gian hàng rồi đặt đáy xuống cframe
	model:PivotTo(CFrame.new(model:GetPivot().Position))
	local _, size = model:GetBoundingBox()
	if size.Y < math.max(size.X, size.Z) then
		model:PivotTo(model:GetPivot() * CFrame.Angles(0, 0, math.rad(90)))
		_, size = model:GetBoundingBox()
	end
	model:ScaleTo(model:GetScale() * height / math.max(size.Y, 0.1))
	model:PivotTo(CFrame.new(model:GetPivot().Position) * cframe.Rotation * model:GetPivot().Rotation)
	local box, boxSize = model:GetBoundingBox()
	model:PivotTo(model:GetPivot() + (cframe.Position - (box.Position - Vector3.new(0, boxSize.Y / 2, 0))))
	model.Parent = parent
	return model
end

-- ===== Tool Shop =====
local function buildToolShop(parent, cf)
	local stall = buildShell(parent, "ToolShop", cf, PALETTE.Sky, "TOOL SHOP")

	-- Biển cá khổng lồ há miệng trên mái (nét hài + linh hồn thú vật): thân xanh, đuôi cam, mắt to có đốm sáng
	local fishCf = cf * CFrame.new(0, 19, -D / 2 - 1)
	ellipsoid(stall, "FishBody", Vector3.new(14, 9, 3.4), fishCf, PALETTE.Sky)
	ellipsoid(stall, "FishBelly", Vector3.new(11, 4, 3.0), fishCf * CFrame.new(0.3, -2.4, -0.3), PALETTE.Milk)
	decor(block(stall, "FishTail", Vector3.new(5, 5, 1.2), fishCf * CFrame.new(-8.4, 0, 0) * CFrame.Angles(0, 0, math.rad(45)), PALETTE.Orange))
	decor(block(stall, "FishFin", Vector3.new(3, 3, 1), fishCf * CFrame.new(0, 5, 0) * CFrame.Angles(0, 0, math.rad(45)), PALETTE.Orange))
	ellipsoid(stall, "FishMouth", Vector3.new(3.2, 2.6, 1.4), fishCf * CFrame.new(6.6, -0.8, -1.4), PALETTE.Ink)
	ellipsoid(stall, "FishTongue", Vector3.new(1.8, 1.0, 1.0), fishCf * CFrame.new(6.5, -1.5, -1.8), PALETTE.Pink)
	addEyes(stall, fishCf * CFrame.new(3.6, 1.8, -1.55), 0, 2.6)
	for _, x in ipairs({ -3, 3 }) do
		block(stall, "FishPost", Vector3.new(0.8, 4.2, 0.8), fishCf * CFrame.new(x, -5.6, 0), PALETTE.DarkWood, Enum.Material.Wood)
	end

	-- Tường trưng bày 6 cần câu đúng thứ tự trong Config.Rods, dưới mỗi cần có đèn màu hạng
	block(stall, "RodRack", Vector3.new(24, 0.8, 0.8), cf * CFrame.new(0, 3.2, D / 2 - 1.4), PALETTE.DarkWood, Enum.Material.Wood)
	for i, rod in ipairs(Config.Rods) do
		local x = (i - 3.5) * 4
		placeUpright(stall, rod.Name, cf * CFrame.new(x, 3.6, D / 2 - 1.6), 7.5)
		local lamp = block(stall, "RodLight" .. i, Vector3.new(2.4, 0.3, 0.9), cf * CFrame.new(x, 2.7, D / 2 - 1.4), RANK_COLORS[math.min(i, #RANK_COLORS)], Enum.Material.Neon)
		decor(lamp)
	end

	-- Tủ máy câu: máy Common và Mythic đứng 2 bên cho thấy "máy càng xịn càng lớn"
	for _, spec in ipairs({ { Tier = "Common", X = -10.2, Z = 3.4 }, { Tier = "Mythic", X = 10.2, Z = 3.4 } }) do
		local model = placeUpright(stall, "AutoFisher_" .. spec.Tier, cf * CFrame.new(spec.X, 0.5, spec.Z), 5.2)
		if model then
			model:SetAttribute("Slots", 3)
			Models.SetAnim(model, "Work")
		end
	end

	-- Trang trí vui: xô cá có đuôi cá ngoi ra, phao cứu sinh mặt cười
	for _, x in ipairs({ 8.6 }) do
		cylinder(stall, "Bucket", 1.6, 2.0, cf * CFrame.new(x, 1.3, -6), PALETTE.Coral)
		decor(block(stall, "FishInBucket", Vector3.new(0.4, 1.4, 0.9), cf * CFrame.new(x, 2.6, -6) * CFrame.Angles(0, 0, math.rad(20)), PALETTE.Sky))
	end
	return stall
end

-- ===== Market =====
local function buildMarket(parent, cf)
	local stall = buildShell(parent, "Market", cf, PALETTE.Coral, "MARKET")

	-- Biển đồng xu vàng có tai mèo, dấu $ ở giữa
	local coinCf = cf * CFrame.new(0, 19, -D / 2 - 1)
	for _, side in ipairs({ -1, 1 }) do
		decor(block(stall, "CoinEar", Vector3.new(3.6, 3.6, 1.2), coinCf * CFrame.new(side * 4.2, 5.4, 0) * CFrame.Angles(0, 0, math.rad(45)), PALETTE.Yellow))
		decor(block(stall, "CoinEarInner", Vector3.new(1.8, 1.8, 0.6), coinCf * CFrame.new(side * 4.2, 5.4, -0.5) * CFrame.Angles(0, 0, math.rad(45)), PALETTE.Pink))
	end
	for _, x in ipairs({ -3, 3 }) do
		block(stall, "CoinPost", Vector3.new(0.8, 3.0, 0.8), coinCf * CFrame.new(x, -5.7, 0), PALETTE.DarkWood, Enum.Material.Wood)
	end
	disc(stall, "Coin", 1.8, 12, coinCf, PALETTE.Yellow, Enum.Material.Metal)
	disc(stall, "CoinRim", 0.4, 9.6, coinCf * CFrame.new(0, 0, -0.95), Color3.fromRGB(201, 154, 18), Enum.Material.Metal)
	local label = block(stall, "CoinFace", Vector3.new(7, 7, 0.2), coinCf * CFrame.new(0, 0, -1.15), Color3.fromRGB(201, 154, 18))
	label.Transparency = 1
	surfaceText(label, "$", PALETTE.Navy)

	-- Rổ trứng trên quầy (đủ 5 loại, trứng Dragon to nhất hợp nét "hiếm thì nổi")
	block(stall, "EggCrate", Vector3.new(6, 1.4, 3), cf * CFrame.new(-9.5, 0.7, -5), PALETTE.DarkWood, Enum.Material.Wood)
	for i, tier in ipairs(Config.EggOrder) do
		local egg = placeUpright(stall, tier .. " Egg", cf * CFrame.new(-11.6 + (i - 1) * 1.1, 1.4, -5), 1.5)
		if egg then
			egg:SetAttribute("Anim", "Idle")
		end
	end
	-- Bảng giá trứng nhỏ cạnh rổ
	local price = block(stall, "PriceBoard", Vector3.new(5, 2.6, 0.3), cf * CFrame.new(9.5, 3.6, -7.5), PALETTE.Navy)
	surfaceText(price, "WE BUY\nEGGS & PETS", PALETTE.Yellow)
	return stall
end

-- Dựng cả quảng trường. cf: tâm quảng trường (-Z quay vào tâm hồ). Trả về Model "TradePlaza"
function ShopBuilder.Build(map, cf)
	local plaza = Instance.new("Model")
	plaza.Name = "TradePlaza"

	-- nền lát gạch phía trước 2 gian + đèn đường 2 đầu
	block(plaza, "PlazaFloor", Vector3.new(66, 0.3, 36), cf * CFrame.new(0, 0.15, -22), C.Brick, Enum.Material.Brick)
	for _, x in ipairs({ -31, 31 }) do
		BuildUtil.lamp(plaza, cf:PointToWorldSpace(Vector3.new(x, 0, -17)))
	end

	local toolShop = buildToolShop(plaza, cf * CFrame.new(-SHOP_OFFSET, 0, 0))
	local market = buildMarket(plaza, cf * CFrame.new(SHOP_OFFSET, 0, 0))
	buildDuck(toolShop, cf * CFrame.new(-SHOP_OFFSET, 0.5, 2.5))
	buildCat(market, cf * CFrame.new(SHOP_OFFSET, 0.5, 2.5))
	plaza.Parent = map
	return plaza
end

return ShopBuilder
