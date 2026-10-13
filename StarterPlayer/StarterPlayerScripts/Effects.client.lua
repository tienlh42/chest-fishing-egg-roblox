-- LocalScript: StarterPlayer > StarterPlayerScripts > Effects
-- Hoạt ảnh TẠM, chỉ chạy trên máy người chơi: vung cần, phao bay + nhấp nhô,
-- rương bay lên mở nắp, pet bật ra khi nở, thu rương máy câu, trứng/phao lắc lư trên plot.
-- Server báo qua RemoteEvent "Effect"; muốn dùng animation thật thì điền ID vào Config.Animations.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Models = require(ReplicatedStorage:WaitForChild("Models"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer

local CAST_DISTANCE = 15 -- phao rơi cách người bao xa (stud)
local WATER_COLOR = Color3.fromRGB(150, 200, 255)

local fxFolder = Instance.new("Folder")
fxFolder.Name = "LocalEffects"
fxFolder.Parent = workspace

-- ===== Tiện ích =====

-- Chạy step(alpha) mỗi khung hình, alpha đi từ 0 -> 1 trong `duration` giây
local function animate(duration, step, easingStyle)
	local start = os.clock()
	repeat
		local a = math.min((os.clock() - start) / duration, 1)
		step(easingStyle and TweenService:GetValue(a, easingStyle, Enum.EasingDirection.Out) or a)
		if a < 1 then
			RunService.RenderStepped:Wait()
		end
	until a >= 1
end

-- Đường cong parabol từ a qua đỉnh peak tới b
local function arc(a, peak, b, t)
	return a:Lerp(peak, t):Lerp(peak:Lerp(b, t), t)
end

-- Model chỉ để trang trí: neo cố định, không va chạm
local function spawnVisual(name)
	local model = Models.Get(name)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
		end
	end
	model.Parent = fxFolder
	return model
end

local function burst(position, color, count)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.Position = position
	p.Parent = fxFolder
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.Speed = NumberRange.new(8, 14)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Lifetime = NumberRange.new(0.5, 1)
	e.Size = NumberSequence.new(0.4, 0)
	e.Acceleration = Vector3.new(0, -20, 0)
	e.Rate = 0
	e.Parent = p
	e:Emit(count)
	Debris:AddItem(p, 2)
end

local function floatingText(part, text, color)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(6, 1.5)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Parent = bb
	bb.Parent = part
end

local function getRoot()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

-- Vị trí trước mặt người chơi + CFrame quay mặt về phía người chơi
local function inFront(distance)
	local hrp = getRoot()
	local look = hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
	local pos = hrp.Position + look.Unit * distance
	return pos, CFrame.lookAt(pos, Vector3.new(hrp.Position.X, pos.Y, hrp.Position.Z))
end

-- Tìm mặt đất/mặt nước bên dưới 1 điểm
local function groundBelow(pos)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character, fxFolder }
	local hit = workspace:Raycast(pos + Vector3.new(0, 20, 0), Vector3.new(0, -100, 0), params)
	return hit and hit.Position or pos - Vector3.new(0, 3, 0)
end

local function playCharacterAnim(key)
	local id = Config.Animations[key]
	if not id or id == "" then
		return
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if animator then
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		animator:LoadAnimation(anim):Play()
	end
end

-- ===== Cần câu =====
local baseGrip = {} -- [rod] = Grip gốc

local function getRod()
	local character = player.Character
	return character and character:FindFirstChild("FishingRod")
end

-- Nghiêng cần: góc dương = ngả ra sau, âm = chúc về trước
local function tiltRod(angle, duration)
	local rod = getRod()
	if not rod then
		return
	end
	baseGrip[rod] = baseGrip[rod] or rod.Grip
	local tween = TweenService:Create(rod, TweenInfo.new(duration, Enum.EasingStyle.Quad), {
		Grip = baseGrip[rod] * CFrame.Angles(math.rad(angle), 0, 0),
	})
	tween:Play()
	tween.Completed:Wait()
end

-- Điểm bắt đầu dây câu: Attachment "Tip" của cần, không có thì dùng người chơi
local function lineStart()
	local rod = getRod()
	local tip = rod and rod:FindFirstChild("Tip", true)
	if tip and tip:IsA("Attachment") then
		return tip
	end
	local hrp = getRoot()
	return hrp and hrp:FindFirstChild("RootAttachment")
end

-- ===== Câu cá =====
local cast = nil -- phiên câu hiện tại { Bobber, Landing }

local function onCastStart()
	if cast then
		cast.Bobber:Destroy()
		cast = nil
	end
	local start = lineStart()
	if not (getRoot() and start) then
		return
	end

	local landing = groundBelow(inFront(CAST_DISTANCE))
	local bobber = spawnVisual("Bobber")
	local state = { Bobber = bobber, Landing = landing }
	cast = state

	-- Dây câu
	local a1 = Instance.new("Attachment")
	a1.Parent = bobber.PrimaryPart
	local line = Instance.new("Beam")
	line.Attachment0 = start
	line.Attachment1 = a1
	line.Width0 = 0.05
	line.Width1 = 0.05
	line.FaceCamera = true
	line.Color = ColorSequence.new(Color3.new(1, 1, 1))
	line.Parent = bobber

	-- Vung cần ra sau rồi quăng tới trước
	playCharacterAnim("Cast")
	bobber:PivotTo(CFrame.new(start.WorldPosition))
	tiltRod(50, 0.25)
	task.spawn(tiltRod, -25, 0.15)

	local from = start.WorldPosition
	local peak = (from + landing) / 2 + Vector3.new(0, 8, 0)
	animate(0.6, function(a)
		bobber:PivotTo(CFrame.new(arc(from, peak, landing, a)))
	end)
	if cast ~= state then
		return
	end
	burst(landing, WATER_COLOR, 12)

	-- Phao nhấp nhô trong lúc chờ
	local t0 = os.clock()
	while cast == state do
		local bob = math.sin((os.clock() - t0) * 4) * 0.15
		bobber:PivotTo(CFrame.new(landing + Vector3.new(0, bob, 0)))
		RunService.RenderStepped:Wait()
	end
end

local function showChest(data, fromPos)
	if not getRoot() then
		return
	end
	local chest = spawnVisual(data.Chest)
	local target, goal = inFront(6)
	target = groundBelow(target) + Vector3.new(0, 1, 0)
	local rotation = goal.Rotation

	-- Rương bay từ dưới nước lên, xoay 1 vòng rồi đáp trước mặt
	local from = fromPos - Vector3.new(0, 2, 0)
	local peak = (from + target) / 2 + Vector3.new(0, 10, 0)
	animate(1, function(a)
		chest:PivotTo(CFrame.new(arc(from, peak, target, a)) * rotation * CFrame.Angles(0, (1 - a) * math.pi * 2, 0))
	end, Enum.EasingStyle.Quad)

	-- Mở nắp quanh mép sau
	local lid = chest:FindFirstChild("Lid", true)
	if lid and lid:IsA("BasePart") then
		local closed = lid.CFrame
		local hinge = closed * CFrame.new(0, -lid.Size.Y / 2, lid.Size.Z / 2)
		animate(0.4, function(a)
			lid.CFrame = hinge * CFrame.Angles(math.rad(110) * a, 0, 0) * hinge:Inverse() * closed
		end, Enum.EasingStyle.Back)
	end

	burst(target + Vector3.new(0, 1.5, 0), Color3.fromRGB(255, 215, 0), 30)
	local text = ("+%d coins"):format(data.Coins)
	if data.Egg then
		text ..= (" + %s Egg"):format(data.Egg)
	end
	floatingText(chest.PrimaryPart, text, Color3.fromRGB(255, 225, 80))

	task.wait(1.5)
	animate(0.3, function(a)
		chest:ScaleTo(math.max(1 - a, 0.01))
	end)
	chest:Destroy()
end

local function onCatch(data)
	local state = cast
	cast = nil -- dừng vòng nhấp nhô
	if not state then
		return
	end
	local bobber = state.Bobber

	-- Giật cần, kéo phao về
	playCharacterAnim("Reel")
	burst(state.Landing, WATER_COLOR, 20)
	task.spawn(function()
		tiltRod(40, 0.2)
		tiltRod(0, 0.3)
	end)
	local start = lineStart()
	local to = start and start.WorldPosition or state.Landing
	animate(0.4, function(a)
		bobber:PivotTo(CFrame.new(state.Landing:Lerp(to, a)))
	end)
	bobber:Destroy()

	showChest(data, state.Landing)
end

-- ===== Trứng nở (tại máy ấp) =====
local function onHatched(data)
	local hrp = getRoot()
	local pos = data.Position or (hrp and inFront(6))
	if not pos then
		return
	end
	local base = hrp and CFrame.lookAt(pos, Vector3.new(hrp.Position.X, pos.Y, hrp.Position.Z)) or CFrame.new(pos)
	burst(pos, Color3.new(1, 1, 1), 40)

	-- Pet bật lên, xoay vòng rồi biến mất (sau đó pet thật bay theo người)
	local pet = spawnVisual(data.Pet)
	pet:ScaleTo(0.05)
	pet:PivotTo(base)
	animate(1.2, function(a)
		pet:ScaleTo(math.max(a, 0.05) * 1.5)
		pet:PivotTo(base * CFrame.new(0, a * 3, 0) * CFrame.Angles(0, a * math.pi * 4, 0))
	end, Enum.EasingStyle.Back)
	floatingText(pet.PrimaryPart, data.Pet .. "!", Color3.fromRGB(120, 255, 140))
	task.wait(1)
	animate(0.3, function(a)
		pet:ScaleTo(math.max(1.5 * (1 - a), 0.01))
	end)
	pet:Destroy()
end

-- ===== Thu rương từ máy câu tự động =====
local function onCollect(data)
	if not data.Position then
		return
	end
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = data.Position
	anchor.Parent = fxFolder

	local text = ("+%d coins"):format(data.Coins)
	for tier, count in pairs(data.Eggs or {}) do
		text ..= ("\n+%d %s Egg"):format(count, tier)
	end
	floatingText(anchor, text, Color3.fromRGB(255, 225, 80))
	burst(data.Position, Color3.fromRGB(255, 215, 0), 40)
	animate(1.5, function(a)
		anchor.Position = data.Position + Vector3.new(0, a * 3, 0)
	end, Enum.EasingStyle.Quad)
	anchor:Destroy()
end

-- ===== Nhận lệnh từ server =====
local handlers = {
	CastStart = onCastStart,
	Catch = onCatch,
	Hatched = onHatched,
	Collect = onCollect,
}

remotes:WaitForChild("Effect").OnClientEvent:Connect(function(kind, data)
	local handler = handlers[kind]
	if handler then
		handler(data)
	end
end)

-- Chết/hồi sinh thì dọn phao đang câu dở
player.CharacterAdded:Connect(function()
	if cast then
		cast.Bobber:Destroy()
		cast = nil
	end
end)

-- ===== Hoạt ảnh lặp trên map =====
-- Tag "Bobbing": phao máy câu nhấp nhô. Tag "Spin": trống cuốn dây quay. Tag "Wobble": trứng trong máy ấp lắc lư.
local baseCFrames = setmetatable({}, { __mode = "k" })

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, part in ipairs(CollectionService:GetTagged("Bobbing")) do
		if part:IsA("BasePart") then
			baseCFrames[part] = baseCFrames[part] or part.CFrame
			local phase = part.Position.X * 0.7 -- mỗi phao lệch nhịp một chút
			part.CFrame = baseCFrames[part] + Vector3.new(0, math.sin(t * 3 + phase) * 0.15, 0)
		end
	end
	for _, part in ipairs(CollectionService:GetTagged("Spin")) do
		if part:IsA("BasePart") then
			baseCFrames[part] = baseCFrames[part] or part.CFrame
			part.CFrame = baseCFrames[part] * CFrame.Angles(t * 2, 0, 0) -- quay quanh trục X
		end
	end
	for _, model in ipairs(CollectionService:GetTagged("Wobble")) do
		if model:IsA("Model") then
			baseCFrames[model] = baseCFrames[model] or model:GetPivot()
			model:PivotTo(baseCFrames[model] * CFrame.Angles(0, 0, math.sin(t * 5) * math.rad(8)))
		end
	end
end)

-- ===== Ẩn nút [E] trên plot của người khác =====
local function filterPrompt(prompt)
	if prompt:IsA("ProximityPrompt") then
		local ownerId = prompt:GetAttribute("OwnerId")
		if ownerId then
			prompt.Enabled = ownerId == player.UserId
		end
	end
end

for _, d in ipairs(workspace:GetDescendants()) do
	filterPrompt(d)
end
workspace.DescendantAdded:Connect(filterPrompt)
