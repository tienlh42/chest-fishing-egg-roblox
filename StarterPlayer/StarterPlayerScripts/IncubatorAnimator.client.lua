-- LocalScript: StarterPlayerScripts > IncubatorAnimator
-- Hoạt ảnh máy ấp (model dựng ở IncubatorBuilder.lua, tag "Incubator"). Chỉ chạy ở client, server chỉ đặt attribute:
--   State "Empty" | "Incubating" | "Ready" | "Hatching", Progress 0..1.
-- Vòng lặp: thở, chớp mắt, mắt nhìn theo camera, đèn sưởi nhấp nháy, hơi ấm bay lên (Incubating), vòm rung + dấu "!" (Ready), "Zzz" (Empty).
-- Sự kiện lớn Effect "IncubatorHatch" (dài Config.Incubators.HatchAnim.Duration giây, theo STYLE_GUIDE 4.5):
--   dồn nhịp (rung mạnh dần, nứt dần, nén / giãn) -> BÙNG NỔ (chớp sáng, vòm kính vỡ thành mảnh, vỏ trứng vỡ, hạt lấp lánh)
--   -> đế chóng mặt (mắt xoáy, sao) -> vòm mới phồng lên (overshoot).

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local camera = workspace.CurrentCamera

local PART_NAMES = { "Nest", "Dome", "DomeRing", "Lamp", "LampPost", "EyeL", "EyeR", "PupilL", "PupilR", "LidL", "LidR", "Mouth", "Crack1", "Crack2", "Crack3" }
local VIEW_DISTANCE = 170 -- xa hơn thì không cập nhật hoạt ảnh lặp
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"

local EGG_COLORS = {
	Reed = Color3.fromRGB(245, 235, 200),
	Bubble = Color3.fromRGB(110, 200, 255),
	Crystal = Color3.fromRGB(190, 140, 255),
	Gold = Color3.fromRGB(255, 205, 70),
	Dragon = Color3.fromRGB(255, 120, 190),
}

local fx = workspace:FindFirstChild("IncubatorFx") or Instance.new("Folder")
fx.Name = "IncubatorFx"
fx.Parent = workspace

local states = {} -- [model] = { part tham chiếu, CFrame gốc, trạng thái hoạt ảnh }

local function backOut(k)
	local c1, c3 = 1.70158, 2.70158
	return 1 + c3 * (k - 1) ^ 3 + c1 * (k - 1) ^ 2
end

-- ===== Chuẩn bị mỗi model =====
local function setup(model)
	if states[model] then
		return
	end
	local s = { Model = model, Busy = false, Last = "", BlinkAt = os.clock() + 1 + math.random() * 3, Seed = math.random() * 10 }
	states[model] = s
	for _, name in ipairs(PART_NAMES) do
		s[name] = model:WaitForChild(name, 8)
	end
	if not (s.Dome and s.Lamp and s.PupilL) then
		states[model] = nil
		return
	end
	s.DomeCF = s.Dome.CFrame
	s.DomeSize = s.Dome.Size
	s.PupilBase = { L = s.PupilL.CFrame, R = s.PupilR.CFrame }
	s.LampCF = s.Lamp.CFrame
	s.PostCF = s.LampPost.CFrame
	s.Light = s.Lamp:FindFirstChildOfClass("PointLight")

	-- Biển báo nổi trên vòm: "Zzz" khi trống, "!" khi nở xong
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(70, 44)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 5.2, 0)
	gui.MaxDistance = 90
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextStrokeTransparency = 0
	label.Parent = gui
	gui.Parent = s.Dome
	s.Notice, s.NoticeLabel = gui, label

	-- Hơi ấm bay lên từ đèn khi đang ấp
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = SPARKLE
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(1.2, 1.8)
	emitter.Speed = NumberRange.new(2, 3.5)
	emitter.SpreadAngle = Vector2.new(25, 25)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 150, 200))
	emitter.LightEmission = 0.8
	emitter.Parent = s.Lamp
	s.Steam = emitter
	s.Ready = true -- đủ dữ liệu: vòng lặp hoạt ảnh mới được chạy
end

-- ===== Hoạt ảnh lặp =====
local function idle(s, now)
	local model = s.Model
	local state = model:GetAttribute("State") or "Empty"
	local t = now + s.Seed

	if state ~= s.Last then
		s.Last = state
		s.Dome.Transparency = state == "Empty" and 0.82 or (state == "Ready" and 0.4 or 0.55)
		s.Steam.Rate = state == "Incubating" and 4 or 0
		if s.Light then
			s.Light.Enabled = state ~= "Empty"
		end
		s.Lamp.Material = state == "Empty" and Enum.Material.SmoothPlastic or Enum.Material.Neon
		s.NoticeLabel.Text = state == "Empty" and "Zzz" or (state == "Ready" and "!" or "")
		s.NoticeLabel.TextColor3 = state == "Ready" and Color3.fromRGB(255, 220, 80) or Color3.fromRGB(190, 215, 255)
		local crack = state == "Ready" and 0.15 or 1
		s.Crack1.Transparency, s.Crack2.Transparency, s.Crack3.Transparency = crack, crack, 1
	end

	-- thở: vòm + đèn nhún nhẹ (ngủ thì chậm)
	local rate = state == "Empty" and 1.3 or 2.6
	local lift = Vector3.new(0, math.sin(t * rate) * 0.07, 0)
	local shake = CFrame.identity
	if state == "Ready" then
		shake = CFrame.Angles(0, 0, math.rad(math.sin(t * 34) * 1.3))
		lift += Vector3.new(0, 0.08 + math.abs(math.sin(t * 5)) * 0.25, 0) -- dấu "!" nảy
	end
	s.Dome.CFrame = (s.DomeCF + lift) * shake
	s.Lamp.CFrame = s.LampCF + lift
	s.LampPost.CFrame = s.PostCF + lift
	if s.Light then
		s.Light.Brightness = 0.6 + math.sin(t * 5) * 0.25
		local progress = model:GetAttribute("Progress") or 0
		s.Light.Color = Color3.fromRGB(255, 230 - math.floor(progress * 110), 150 - math.floor(progress * 90)) -- vàng -> cam khi gần nở
		s.Lamp.Color = s.Light.Color
	end
	s.Notice.StudsOffsetWorldSpace = Vector3.new(0, 5.2 + math.sin(t * 2.2) * 0.3, 0)

	-- chớp mắt (trống = nhắm hẳn) và mắt nhìn theo camera
	local closed = state == "Empty"
	if now >= s.BlinkAt then
		if now >= s.BlinkAt + 0.14 then
			s.BlinkAt = now + 2.5 + math.random() * 2.5
		else
			closed = true
		end
	end
	s.LidL.Transparency = closed and 0 or 1
	s.LidR.Transparency = closed and 0 or 1
	local look = s.Nest.CFrame:PointToObjectSpace(camera.CFrame.Position)
	local dx = math.clamp(look.X / 60, -0.3, 0.3)
	local dy = math.clamp((look.Y - 2) / 60, -0.2, 0.25)
	s.PupilL.CFrame = s.PupilBase.L * CFrame.new(dx, dy, 0)
	s.PupilR.CFrame = s.PupilBase.R * CFrame.new(dx, dy, 0)
end

-- ===== Mảnh vỡ bay tỏa =====
local function flyingPiece(position, size, color, material, speedMin, speedMax)
	local piece = Instance.new("Part")
	piece.Size = size
	piece.Color = color
	piece.Material = material
	piece.Transparency = material == Enum.Material.Glass and 0.25 or 0
	piece.CanCollide = false
	piece.CanQuery = false
	piece.CanTouch = false
	piece.CFrame = CFrame.new(position) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
	piece.Parent = fx
	local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8 + 0.2, math.random() - 0.5).Unit
	piece.AssemblyLinearVelocity = dir * (speedMin + math.random() * (speedMax - speedMin)) + Vector3.new(0, 16, 0)
	piece.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 24
	Debris:AddItem(piece, 2.4)
	task.delay(0.9, function()
		if piece.Parent then
			TweenService:Create(piece, TweenInfo.new(1.3), { Transparency = 1 }):Play()
		end
	end)
end

local function sparkleBurst(position, colors, count)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = position
	anchor.Parent = fx
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = SPARKLE
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.9, 1.6)
	emitter.Speed = NumberRange.new(18, 38)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, -14, 0)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
	emitter.Color = colors
	emitter.LightEmission = 1
	emitter.Parent = anchor
	emitter:Emit(count)
	Debris:AddItem(anchor, 2)
end

local function doBurst(s, data)
	local center = s.Dome.Position
	local tier = data.Tier
	local glass = s.Dome.Color
	-- chớp sáng: quả cầu neon nở nhanh rồi tan
	local flash = Instance.new("Part")
	flash.Shape = Enum.PartType.Ball
	flash.Anchored = true
	flash.CanCollide = false
	flash.CanQuery = false
	flash.Material = Enum.Material.Neon
	flash.Color = Color3.new(1, 1, 1)
	flash.Size = Vector3.one * 2
	flash.Position = center
	flash.Parent = fx
	local light = Instance.new("PointLight")
	light.Range = 34
	light.Brightness = 7
	light.Color = Color3.new(1, 1, 0.9)
	light.Parent = flash
	TweenService:Create(flash, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Size = Vector3.one * 15, Transparency = 1 }):Play()
	TweenService:Create(light, TweenInfo.new(0.5), { Brightness = 0 }):Play()
	Debris:AddItem(flash, 0.7)

	-- vòm kính vỡ: mảnh kính + vỏ trứng
	for _ = 1, 16 do
		local sz = 0.5 + math.random() * 0.8
		flyingPiece(center + Vector3.new(math.random() - 0.5, math.random() - 0.2, math.random() - 0.5) * 4, Vector3.new(sz, sz * (0.4 + math.random() * 0.6), 0.2), glass, Enum.Material.Glass, 16, 32)
	end
	local shell = EGG_COLORS[tier] or Color3.new(1, 1, 1)
	for _ = 1, 9 do
		local sz = 0.6 + math.random() * 0.7
		flyingPiece(center, Vector3.new(sz, sz * 0.5, sz), shell, Enum.Material.SmoothPlastic, 12, 26)
	end
	sparkleBurst(center, ColorSequence.new(Color3.fromRGB(255, 235, 140), Color3.new(1, 1, 1)), 46)
	if tier == "Gold" or tier == "Dragon" then
		sparkleBurst(center + Vector3.new(0, 1, 0), ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 120)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 220, 80)),
			ColorSequenceKeypoint.new(0.66, Color3.fromRGB(90, 220, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 120, 255)),
		}), tier == "Dragon" and 110 or 60)
	end

	-- ẩn vòm / vành / đèn / vết nứt, ẩn trứng thật (vỏ đã bay ra thành mảnh)
	for _, name in ipairs({ "Dome", "DomeRing", "Lamp", "LampPost", "Crack1", "Crack2", "Crack3" }) do
		s[name].Transparency = 1
	end
	if s.Light then
		s.Light.Enabled = false
	end
	s.NoticeLabel.Text = ""
	if data.Egg then
		for _, d in ipairs(data.Egg:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Transparency = 1
			elseif d:IsA("ParticleEmitter") or d:IsA("Light") then
				d.Enabled = false
			end
		end
	end
end

-- ===== Sự kiện nở =====
local function playHatch(data)
	local model = data.Model
	if not (model and model.Parent) then
		return
	end
	task.spawn(setup, model)
	local waited = 0
	while not (states[model] and states[model].Ready) and waited < 3 and model.Parent do
		waited += task.wait(0.1)
	end
	local s = states[model]
	if not s or not s.Ready or s.Busy then
		return
	end
	s.Busy = true

	local pivot0 = model:GetPivot()
	local scale0 = model:GetScale()
	local pupilRel = { L = pivot0:ToObjectSpace(s.PupilBase.L), R = pivot0:ToObjectSpace(s.PupilBase.R) }
	local burstAt, duration = data.BurstAt, data.Duration
	local popLength = 0.7
	local start = os.clock()
	local burst = false
	local steamed = 0
	s.Steam.Rate = 0
	s.LidL.Transparency, s.LidR.Transparency = 1, 1
	s.Dome.CFrame = s.DomeCF
	s.Lamp.CFrame = s.LampCF
	s.LampPost.CFrame = s.PostCF

	while model.Parent do
		local t = os.clock() - start
		if t >= duration then
			break
		end
		if t < burstAt then
			-- dồn nhịp: rung mạnh dần, nén / giãn, nứt dần, hơi bốc lên
			local k = t / burstAt
			local amp = 0.03 + 0.34 * k * k
			model:PivotTo(pivot0 * CFrame.new((math.random() - 0.5) * 2 * amp, math.abs(math.random() - 0.5) * amp, (math.random() - 0.5) * 2 * amp) * CFrame.Angles(0, 0, math.rad((math.random() - 0.5) * 9 * k)))
			model:ScaleTo(scale0 * (1 + math.sin(t * 15) * 0.035 * (1 + k)))
			s.Crack1.Transparency = k > 0.25 and 0.05 or 1
			s.Crack2.Transparency = k > 0.5 and 0.05 or 1
			s.Crack3.Transparency = k > 0.75 and 0.05 or 1
			s.Dome.Transparency = 0.55 - 0.25 * k
			if k > 0.45 and steamed < 2 and k * 10 > steamed * 3 + 4 then
				steamed += 1
				sparkleBurst(s.Dome.Position + Vector3.new(0, 2, 0), ColorSequence.new(Color3.fromRGB(255, 200, 230)), 12)
			end
		else
			if not burst then
				burst = true
				model:PivotTo(pivot0)
				model:ScaleTo(scale0 * 1.12) -- giật nở ra rồi bật lại
				doBurst(s, data)
			end
			local u = t - burstAt
			model:ScaleTo(scale0 * (1 + 0.12 * math.max(0, 1 - u * 4)))
			-- đế chóng mặt: lắc nhẹ, mắt xoáy tròn
			model:PivotTo(pivot0 * CFrame.Angles(0, math.sin(u * 9) * 0.14, math.sin(u * 6) * 0.04))
			local pivot = model:GetPivot()
			for _, side in ipairs({ "L", "R" }) do
				local pupil = side == "L" and s.PupilL or s.PupilR
				pupil.CFrame = pivot * pupilRel[side] * CFrame.new(math.cos(u * 9 + (side == "L" and 0 or 2)) * 0.26, math.sin(u * 9 + (side == "L" and 0 or 2)) * 0.26, 0)
			end
			-- vòm mới phồng lên ở cuối (overshoot)
			local popK = (t - (duration - popLength)) / popLength
			if popK > 0 then
				local scale = math.max(backOut(math.min(popK, 1)), 0.01)
				s.Dome.Size = s.DomeSize * scale
				s.Dome.CFrame = pivot * pivot0:ToObjectSpace(s.DomeCF)
				s.Dome.Transparency = 0.82
				s.DomeRing.Transparency = 0
				s.Lamp.Transparency = 0
				s.LampPost.Transparency = 0
				s.Lamp.Material = Enum.Material.SmoothPlastic
			end
		end
		RunService.RenderStepped:Wait()
	end

	-- trả về trạng thái trống bình thường
	if model.Parent then
		model:PivotTo(pivot0)
		model:ScaleTo(scale0)
		s.Dome.Size = s.DomeSize
		s.Dome.CFrame = s.DomeCF
		s.Dome.Transparency = 0.82
		s.DomeRing.Transparency = 0
		s.Lamp.Transparency = 0
		s.LampPost.Transparency = 0
		s.PupilL.CFrame, s.PupilR.CFrame = s.PupilBase.L, s.PupilBase.R
		s.Last = ""
	end
	s.Busy = false
end

-- ===== Nối sự kiện =====
for _, model in ipairs(CollectionService:GetTagged("Incubator")) do
	task.spawn(setup, model)
end
CollectionService:GetInstanceAddedSignal("Incubator"):Connect(function(model)
	task.spawn(setup, model)
end)

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	local camPos = camera.CFrame.Position
	for model, s in pairs(states) do
		if not model.Parent then
			states[model] = nil
		elseif s.Ready and not s.Busy and (model:GetPivot().Position - camPos).Magnitude <= VIEW_DISTANCE then
			local ok, err = pcall(idle, s, now)
			if not ok then
				warn("IncubatorAnimator:", err)
			end
		end
	end
end)

remotes:WaitForChild("Effect").OnClientEvent:Connect(function(kind, data)
	if kind == "IncubatorHatch" then
		task.spawn(playHatch, data)
	end
end)
