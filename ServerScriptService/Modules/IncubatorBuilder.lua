-- ModuleScript: ServerScriptService > Modules > IncubatorBuilder
-- Dựng model "Máy Ấp Tổ Ấm" bằng Part (đồ tạm, sau thay model thật): vòm kính tròn trên đế tổ rơm có hai mắt và cái miệng
-- (linh hồn thú vật, STYLE_GUIDE 1.1), đèn sưởi vàng ở đỉnh. Pivot ở ĐÁY model (đặt lên bệ). Mặt trước = -Z.
-- Hoạt ảnh chạy ở client (IncubatorAnimator.client.lua) theo attribute trên model:
--   State    "Empty" (ngủ, vòm mờ) | "Incubating" (đang ấp, đèn sáng) | "Ready" (nở xong chờ nhận, vòm nứt) | "Hatching" (đang nở / vỡ vòm)
--   Progress 0..1 tiến độ ấp (chỉ khi Incubating)
-- Tên Part cần cho animator (KHÔNG đổi): Nest, Dome, DomeRing, Lamp, LampPost, EyeL, EyeR, PupilL, PupilR, LidL, LidR, Mouth, Crack1..3, EggAnchor (Attachment EggPoint).

local CollectionService = game:GetService("CollectionService")
local BuildUtil = require(script.Parent.BuildUtil)

local block, cylinder, ellipsoid = BuildUtil.block, BuildUtil.cylinder, BuildUtil.ellipsoid

local IncubatorBuilder = {}

local PALETTE = {
	Nest = Color3.fromRGB(181, 115, 60),
	Straw = Color3.fromRGB(242, 194, 48),
	Glass = Color3.fromRGB(180, 225, 255),
	Silver = Color3.fromRGB(205, 208, 215),
	Ink = Color3.fromRGB(28, 28, 30),
	Milk = Color3.fromRGB(245, 245, 240),
	Cream = Color3.fromRGB(240, 230, 205),
	Pink = Color3.fromRGB(255, 111, 181),
	Lamp = Color3.fromRGB(255, 230, 150),
}

local DOME_R = 3.3
local DOME_Y = 4.2

function IncubatorBuilder.Make()
	local model = Instance.new("Model")
	model.Name = "Incubator"

	-- Đế tổ rơm
	local nest = cylinder(model, "Nest", 1.4, 7.4, CFrame.new(0, 0.7, 0), PALETTE.Nest, Enum.Material.Wood)
	cylinder(model, "NestRim", 0.5, 7.9, CFrame.new(0, 1.55, 0), PALETTE.Straw, Enum.Material.Fabric).CanCollide = false
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2
		ellipsoid(model, "Straw", Vector3.new(1.4, 0.5, 0.5), CFrame.new(math.cos(a) * 3.8, 1.85, math.sin(a) * 3.8) * CFrame.Angles(0, -a + math.pi / 2, math.rad(10)), PALETTE.Straw, Enum.Material.Fabric)
	end

	-- Mặt trên đế: hai mắt (có đốm sáng), mí mắt khi ngủ, miệng
	for _, side in ipairs({ -1, 1 }) do
		local tag = side < 0 and "L" or "R"
		local x = side * 1.35
		local eye = CFrame.new(x, 0.85, -3.55)
		ellipsoid(model, "Eye" .. tag, Vector3.new(1.5, 1.7, 0.5), eye, PALETTE.Milk)
		ellipsoid(model, "Pupil" .. tag, Vector3.new(0.85, 1.0, 0.3), eye * CFrame.new(0, -0.05, -0.18), PALETTE.Ink)
		ellipsoid(model, "Shine" .. tag, Vector3.new(0.3, 0.3, 0.12), eye * CFrame.new(0.2, 0.2, -0.3), PALETTE.Milk)
		local lid = ellipsoid(model, "Lid" .. tag, Vector3.new(1.65, 1.85, 0.55), eye * CFrame.new(0, 0.05, -0.04), PALETTE.Cream)
		lid.Transparency = 1
	end
	ellipsoid(model, "Mouth", Vector3.new(1.4, 0.35, 0.4), CFrame.new(0, 0.3, -3.6), PALETTE.Ink)

	-- Vòm kính + vành bạc
	local dome = ellipsoid(model, "Dome", Vector3.one * (DOME_R * 2), CFrame.new(0, DOME_Y, 0), PALETTE.Glass, Enum.Material.Glass)
	dome.Transparency = 0.55
	cylinder(model, "DomeRing", 0.35, 7.0, CFrame.new(0, 1.95, 0), PALETTE.Silver, Enum.Material.Metal).CanCollide = false

	-- Đèn sưởi trên đỉnh
	local top = DOME_Y + DOME_R
	BuildUtil.decor(block(model, "LampPost", Vector3.new(0.3, 1.1, 0.3), CFrame.new(0, top + 0.4, 0), PALETTE.Silver, Enum.Material.Metal))
	local lamp = ellipsoid(model, "Lamp", Vector3.one * 1.1, CFrame.new(0, top + 1.15, 0), PALETTE.Lamp, Enum.Material.Neon)
	BuildUtil.light(lamp, PALETTE.Lamp, 10, 0.6)

	-- Vết nứt trên mặt trước vòm (ẩn, hiện khi nở xong / đang nở)
	local cracks = {
		{ x = -0.8, y = DOME_Y + 1.6, rot = 20, len = 2.4 },
		{ x = 0.9, y = DOME_Y + 0.2, rot = -35, len = 2.8 },
		{ x = -0.2, y = DOME_Y - 1.2, rot = 8, len = 2.2 },
	}
	for i, c in ipairs(cracks) do
		local dy = c.y - DOME_Y
		local z = -math.sqrt(math.max(DOME_R * DOME_R - c.x * c.x - dy * dy, 0.5))
		local crack = BuildUtil.decor(block(model, "Crack" .. i, Vector3.new(0.14, c.len, 0.14), CFrame.new(c.x, c.y, z) * CFrame.Angles(0, 0, math.rad(c.rot)), PALETTE.Ink))
		crack.Transparency = 1
	end

	-- Chỗ đặt trứng (Plots đặt trứng tại đây)
	local anchor = BuildUtil.marker(model, "EggAnchor", Vector3.new(0.4, 0.4, 0.4), CFrame.new(0, 1.9, 0))
	local attachment = Instance.new("Attachment")
	attachment.Name = "EggPoint"
	attachment.Parent = anchor

	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d ~= nest then
			d.CanCollide = false
		end
	end
	model.PrimaryPart = nest
	nest.PivotOffset = nest.CFrame:Inverse() -- pivot của model = gốc (0,0,0) ở ĐÁY, không xoay (nest là trụ đã xoay 90 độ), để PivotTo đặt đáy lên mặt bệ
	model:SetAttribute("State", "Empty")
	model:SetAttribute("Progress", 0)
	CollectionService:AddTag(model, "Incubator")
	return model
end

return IncubatorBuilder
