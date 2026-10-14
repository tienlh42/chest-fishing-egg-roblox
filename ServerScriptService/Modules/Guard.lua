-- ModuleScript: ServerScriptService > Modules > Guard
-- Ngỗng bảo vệ hồ cấm. Máy trạng thái:
--   Patrol      đi qua các điểm tuần tra (Config.Guard.Patrol)
--   Suspicious  thấy người chơi KHẢ NGHI -> dựng cổ nghi ngờ một chút. Hết giờ mà người đó thôi khả nghi
--               (đã nhả nút câu) thì chỉ ra chỗ đó xem rồi bỏ qua; vẫn khả nghi thì đuổi
--   Chase       đuổi. Pet còn HP thì ngỗng dừng lại đánh pet; pet gục thì bắt người chơi
--   Search      nghe tiếng động / mất dấu -> ra chỗ cuối cùng rồi tìm
--   Pause       đứng im sau khi bắt được hoặc người chơi chạy vào vùng an toàn
-- Ngỗng KHÔNG đuổi / bắt người chơi đang trong vùng an toàn.

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local Models = require(ReplicatedStorage.Models)
local Data = require(script.Parent.Data)
local Pets = require(script.Parent.Pets)
local Remote = require(script.Parent.Remote)
local SafeZone = require(script.Parent.SafeZone)

local cfg = Config.Guard

local TICK = 0.1
local HIP_HEIGHT = 1.5 -- chân ngỗng cách đáy HumanoidRootPart 1.5 stud (khớp model trong Models.lua)
local PAUSE_TIME = 2.5
local AGENT = { AgentRadius = 2.2, AgentHeight = 6, AgentCanJump = false, Costs = { Water = math.huge } }

local Guard = {}

local geese = {}
local patrolPoints = {}
local hooks = {} -- OnCaught(player), Suspicion(player) -> "Reeling" | "Loot" | nil

-- ===== Tiện ích =====
local function flatDistance(a, b)
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function groundAt(position)
	local params = RaycastParams.new()
	params.IgnoreWater = true
	local hit = workspace:Raycast(Vector3.new(position.X, 200, position.Z), Vector3.new(0, -400, 0), params)
	return hit and hit.Position or Vector3.new(position.X, 0, position.Z)
end

-- Điểm (x, z) là mặt nước? (raycast thẳng xuống, không bỏ qua nước: trúng Terrain Water thì là nước)
local waterParams = RaycastParams.new()
waterParams.IgnoreWater = false
local function isWaterAt(position)
	local hit = workspace:Raycast(Vector3.new(position.X, position.Y + 10, position.Z), Vector3.new(0, -60, 0), waterParams)
	return hit ~= nil and hit.Material == Enum.Material.Water
end

-- Đường thẳng a -> b có cắt qua nước không? (lấy mẫu mỗi 2 stud, thêm đoạn cuối)
local function crossesWater(a, b)
	local offset = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local steps = math.max(math.ceil(offset.Magnitude / 2), 1)
	for i = 1, steps do
		if isWaterAt(a + offset * (i / steps)) then
			return true
		end
	end
	return false
end

-- Chỗ này và 4 hướng quanh nó (3 stud) đều không phải nước -> chỗ an toàn để đặt lại ngỗng
local function solidGround(position)
	if isWaterAt(position) then
		return false
	end
	for _, d in ipairs({ Vector3.new(3, 0, 0), Vector3.new(-3, 0, 0), Vector3.new(0, 0, 3), Vector3.new(0, 0, -3) }) do
		if isWaterAt(position + d) then
			return false
		end
	end
	return true
end

-- Người chơi có thể bị ngỗng nhắm tới không? Trả về HumanoidRootPart nếu có.
local function targetRoot(player)
	if not (player and player.Parent and Data.Get(player)) then
		return nil
	end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (hrp and humanoid and humanoid.Health > 0) or SafeZone.Contains(hrp.Position) then
		return nil
	end
	return hrp
end

local function say(g, text, seconds)
	g.Sign.Text = text
	g.SignGui.Enabled = true
	local token = {}
	g.SignToken = token
	task.delay(seconds or 1.5, function()
		if g.SignToken == token then
			g.SignGui.Enabled = false
		end
	end)
end

local function face(g, position)
	local root = g.Root
	root.CFrame = CFrame.lookAt(root.Position, Vector3.new(position.X, root.Position.Y, position.Z))
end

local function alertClient(player, kind)
	if player and player.Parent then
		Remote.Effect(player, "Alert", { State = kind })
	end
end

-- Đổi trạng thái. target = người chơi đang bị nhắm (nil nếu không)
local function setState(g, state, target)
	local old = g.Target
	if old and old ~= target then
		Pets.Unshield(old)
		alertClient(old, "None")
	end
	g.Fighting = false
	g.Target = target
	g.State = state
	g.StateAt = os.clock()
	g.Arrived = false
	if target and (state == "Suspicious" or state == "Chase") then
		alertClient(target, state)
	end
end

local function nearestPatrolIndex(position)
	local best, bestDist = 1, math.huge
	for i, point in ipairs(patrolPoints) do
		local d = flatDistance(point, position)
		if d < bestDist then
			best, bestDist = i, d
		end
	end
	return best
end

local function toPatrol(g)
	setState(g, "Patrol", nil)
	g.PatrolIndex = nearestPatrolIndex(g.Root.Position)
	g.PointAt = os.clock()
	g.WaitUntil = nil
end

-- ===== Thị giác =====
local function canSee(g, hrp, range)
	local eye = g.Root.Position + Vector3.new(0, 3, 0)
	local offset = hrp.Position - eye
	local distance = offset.Magnitude
	if distance > (range or cfg.SightRange) then
		return false
	end
	local flat = Vector3.new(offset.X, 0, offset.Z)
	if distance > cfg.ShortSight and flat.Magnitude > 0.1 then
		local cosine = math.clamp(g.Root.CFrame.LookVector:Dot(flat.Unit), -1, 1)
		if math.deg(math.acos(cosine)) > cfg.SightAngle / 2 then
			return false
		end
	end

	-- Cây, đá, tường chắn tầm nhìn; người chơi, pet và chính ngỗng thì không
	local ignore = { g.Model }
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end
	local pets = workspace:FindFirstChild("PlayerPets")
	if pets then
		table.insert(ignore, pets)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = true
	return workspace:Raycast(eye, offset, params) == nil
end

-- Ngỗng thấy người này từ bao xa? nil = người qua đường, ngỗng bỏ qua
local function suspicionRange(player)
	if not hooks.Suspicion then
		return cfg.SightRange
	end
	local level = hooks.Suspicion(player)
	if level == "Reeling" then
		return cfg.SightRange
	elseif level == "Loot" then
		return cfg.LootSightRange
	end
	return nil
end

local function findVisiblePlayer(g)
	local best, bestDist
	for _, player in ipairs(Players:GetPlayers()) do
		local hrp = targetRoot(player)
		local range = hrp and suspicionRange(player)
		if range and canSee(g, hrp, range) then
			local d = (hrp.Position - g.Root.Position).Magnitude
			if not bestDist or d < bestDist then
				best, bestDist = player, d
			end
		end
	end
	return best
end

-- ===== Di chuyển (PathfindingService chạy ở thread riêng để không chặn AI) =====
local function repath(g, dest)
	g.Pathing = true
	local path = PathfindingService:CreatePath(AGENT)
	local ok = pcall(path.ComputeAsync, path, g.Root.Position, dest)
	g.Pathing = false
	g.PathFor = dest
	g.PathAt = os.clock()
	if ok and path.Status == Enum.PathStatus.Success then
		g.Waypoints = path:GetWaypoints()
		g.WpIndex = 2
	else
		g.Waypoints = nil
	end
end

local function follow(g)
	local humanoid, root = g.Humanoid, g.Root
	local dest = g.Dest
	humanoid.WalkSpeed = g.StunUntil > os.clock() and 0 or g.Speed
	if not dest then
		humanoid:MoveTo(root.Position)
		return
	end
	-- Đi thẳng chỉ khi đường thẳng không cắt qua hồ (lối quanh hồ cong nên dây cung chui xuống nước)
	if g.Direct and not crossesWater(root.Position, dest) then
		humanoid:MoveTo(dest)
		return
	end

	local now = os.clock()
	local repathEvery = g.State == "Chase" and 0.5 or 2
	if not g.Pathing and (not g.PathFor or (g.PathFor - dest).Magnitude > 4 or now - g.PathAt > repathEvery) then
		task.spawn(repath, g, dest)
	end
	local waypoints = g.Waypoints
	if waypoints and g.PathFor and (g.PathFor - dest).Magnitude <= 6 then
		local wp = waypoints[g.WpIndex]
		while wp and flatDistance(root.Position, wp.Position) < 2.5 do
			g.WpIndex += 1
			wp = waypoints[g.WpIndex]
		end
		humanoid:MoveTo(wp and wp.Position or dest)
	elseif not crossesWater(root.Position, dest) then
		humanoid:MoveTo(dest) -- chưa có đường đi (hoặc tính lỗi): đi thẳng tạm nếu không phải qua nước
	else
		humanoid:MoveTo(root.Position) -- chờ có đường, không lao xuống hồ
	end
end

-- Lưới an toàn: ngỗng rơi xuống nước thì đặt lại về chỗ đứng vững gần nhất
local function rescueFromWater(g)
	local root = g.Root
	local swimming = g.Humanoid:GetState() == Enum.HumanoidStateType.Swimming
	if swimming or (root.Position.Y < 0 and isWaterAt(root.Position)) then
		if g.LastGround then
			g.Model:PivotTo(CFrame.new(g.LastGround + Vector3.new(0, 2, 0)))
			root.AssemblyLinearVelocity = Vector3.zero
			g.Waypoints = nil
			g.PathFor = nil
			g.Dest = nil
		end
	elseif solidGround(Vector3.new(root.Position.X, 5, root.Position.Z)) then
		g.LastGround = root.Position -- ngỗng đang đứng vững ở đây (không dùng groundAt: raycast có thể trúng tán cây)
	end
end

-- ===== Từng trạng thái =====
local function stepPatrol(g, now)
	g.Speed = cfg.PatrolSpeed
	g.Direct = false
	local seen = findVisiblePlayer(g)
	if seen then
		local hrp = targetRoot(seen)
		g.LastSeen = hrp.Position
		say(g, "Honk?", 1.5)
		setState(g, "Suspicious", seen)
		return
	end

	if g.WaitUntil then
		g.Dest = nil
		if now >= g.WaitUntil then
			g.WaitUntil = nil
			g.PatrolIndex = g.PatrolIndex % #patrolPoints + 1
			g.PointAt = now
		end
		return
	end
	local point = patrolPoints[g.PatrolIndex]
	g.Dest = point
	-- Tới nơi, hoặc đi quá lâu mà chưa tới (điểm bị cây chắn) thì nghỉ rồi sang điểm khác
	if flatDistance(g.Root.Position, point) < 4 or now - g.PointAt > 30 then
		g.WaitUntil = now + 1.5
	end
end

local function stepSuspicious(g, now)
	g.Speed = 0
	g.Dest = nil
	local hrp = targetRoot(g.Target)
	if hrp then
		face(g, hrp.Position)
	end
	if now - g.StateAt < cfg.SuspiciousTime then
		return
	end
	local range = g.Target and suspicionRange(g.Target)
	if hrp and range and canSee(g, hrp, range) then
		g.LastSeen = hrp.Position
		g.LastSeenAt = now
		say(g, "STOP RIGHT THERE!", 2)
		setState(g, "Chase", g.Target)
	else
		-- Người đó thôi khả nghi (đã nhả nút câu) hoặc khuất tầm nhìn: ra chỗ đó xem rồi bỏ qua
		say(g, "...Hmm? Must be nothing.", 2)
		g.SearchPos = g.LastSeen
		setState(g, "Search", nil)
	end
end

-- Ngỗng dừng lại đánh pet. Cứ mỗi StunEvery giây pet làm ngỗng khựng StunTime giây.
local function fight(g, player, hrp, dt, now)
	g.Fighting = true
	g.Dest = nil
	face(g, hrp.Position)
	Pets.Shield(player, g.Root.Position)
	if g.StunUntil > now then
		return
	end
	g.FightTime += dt
	if g.FightTime >= cfg.StunEvery then
		g.FightTime = 0
		g.StunUntil = now + cfg.StunTime
		say(g, "Honk!!", 1)
		return
	end
	Pets.Hit(player, cfg.PetDamage * dt)
end

local function stepChase(g, now, dt)
	g.Speed = cfg.ChaseSpeed
	local player = g.Target
	local hrp = targetRoot(player)
	if not hrp then
		-- Mất mục tiêu: chạy vào vùng an toàn, chết, hoặc thoát game
		if player and player.Parent and SafeZone.IsSafe(player) then
			say(g, "Not my jurisdiction.", PAUSE_TIME)
			setState(g, "Pause", nil)
		else
			toPatrol(g)
		end
		g.Dest = nil
		return
	end

	local distance = (hrp.Position - g.Root.Position).Magnitude
	local visible = distance <= cfg.AttackRange or canSee(g, hrp)
	if visible then
		g.LastSeen = hrp.Position
		g.LastSeenAt = now
	elseif now - g.LastSeenAt > cfg.LoseTime then
		g.SearchPos = g.LastSeen
		setState(g, "Search", nil)
		return
	end

	local shielded = Pets.IsShielding(player)
	if shielded and distance <= cfg.AttackRange then
		fight(g, player, hrp, dt, now)
		return
	end
	if g.Fighting then
		g.Fighting = false
		Pets.Unshield(player)
	end

	if not shielded and distance <= cfg.CatchRange then
		say(g, "Gotcha!", PAUSE_TIME)
		setState(g, "Pause", nil)
		g.Dest = nil
		if hooks.OnCaught then
			hooks.OnCaught(player)
		end
		return
	end
	g.Dest = visible and hrp.Position or g.LastSeen
	g.Direct = visible and distance < 40
end

local function stepSearch(g, now)
	g.Speed = cfg.PatrolSpeed
	g.Direct = false
	local seen = findVisiblePlayer(g)
	if seen then
		g.LastSeen = targetRoot(seen).Position
		say(g, "Honk?", 1.5)
		setState(g, "Suspicious", seen)
		return
	end

	if not g.Arrived then
		g.Dest = g.SearchPos
		if flatDistance(g.Root.Position, g.SearchPos) < 4 or now - g.StateAt > 20 then
			g.Arrived = true
			g.ArrivedAt = now
		end
	else
		g.Dest = nil
		if now - g.ArrivedAt >= cfg.SearchTime then
			toPatrol(g)
		end
	end
end

local function stepPause(g, now)
	g.Speed = 0
	g.Dest = nil
	if now - g.StateAt >= PAUSE_TIME then
		toPatrol(g)
	end
end

-- Animation của model asset (attribute "Anim" trên model, script GooseAnimator chạy ở client) theo trạng thái ngỗng
local function animFor(g, now)
	if g.State == "Chase" then
		if g.Fighting then
			return g.StunUntil > now and "Stunned" or "Attack"
		end
		return now - g.StateAt < 1 and "Whistle" or "Run"
	elseif g.State == "Suspicious" then
		return "Alert"
	elseif g.State == "Search" then
		return g.Arrived and "Search" or "Walk"
	elseif g.State == "Patrol" then
		return g.WaitUntil and "Idle" or "Walk"
	end
	return "Idle" -- Pause
end

local function updateAnim(g, now)
	local anim = animFor(g, now)
	if g.Model:GetAttribute("Anim") ~= nil and g.Model:GetAttribute("Anim") ~= anim then
		g.Model:SetAttribute("Anim", anim)
	end
end

local steps = {
	Patrol = stepPatrol,
	Suspicious = stepSuspicious,
	Chase = stepChase,
	Search = stepSearch,
	Pause = stepPause,
}

-- ===== Dựng ngỗng =====
local function spawnGoose(position, patrolIndex)
	local model = Models.Get("Goose")
	local root = model.PrimaryPart
	root.Name = "HumanoidRootPart"
	-- Model asset (PoliceGoose) đã có rig Motor6D / Weld + Humanoid sẵn: không hàn lại. Model tạm thì hàn mọi Part vào root.
	local rigged = model:FindFirstChildWhichIsA("Motor6D", true) ~= nil
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.Massless = d ~= root
			if d ~= root and not rigged then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = root
				weld.Part1 = d
				weld.Parent = d
			end
		end
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = Instance.new("Humanoid")
		humanoid.HipHeight = HIP_HEIGHT
	end
	humanoid.RigType = Enum.HumanoidRigType.R15 -- R15 mới tự nâng thân lên theo HipHeight; R6 sẽ rơi xuyên đất
	humanoid.WalkSpeed = cfg.PatrolSpeed
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.Parent = model

	-- Bảng thoại nổi trên đầu
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(9, 1.8)
	gui.StudsOffset = Vector3.new(0, 5.5, 0)
	gui.AlwaysOnTop = true
	gui.Enabled = false
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.fromRGB(255, 235, 120)
	label.TextStrokeTransparency = 0
	label.Parent = gui
	gui.Parent = root

	model.Name = "Guard Goose"
	model:PivotTo(CFrame.new(position + Vector3.new(0, 3, 0)))
	model.Parent = workspace
	root:SetNetworkOwner(nil) -- server tự tính vật lý cho ngỗng

	local g = {
		Model = model,
		Root = root,
		Humanoid = humanoid,
		Sign = label,
		SignGui = gui,
		State = "Patrol",
		StateAt = os.clock(),
		PatrolIndex = patrolIndex,
		PointAt = os.clock(),
		Speed = cfg.PatrolSpeed,
		StunUntil = 0,
		FightTime = 0,
		LastSeenAt = 0,
	}
	table.insert(geese, g)
	return g
end

-- ===== API =====

-- Tiếng động tại `position`: ngỗng đang rảnh trong bán kính sẽ ra kiểm tra
function Guard.Noise(position, radius)
	for _, g in ipairs(geese) do
		if (g.State == "Patrol" or g.State == "Search") and (g.Root.Position - position).Magnitude <= radius then
			if g.State == "Patrol" then
				say(g, "Honk?", 1.5)
				setState(g, "Search", nil)
			end
			g.SearchPos = position
			g.Arrived = false
		end
	end
end

-- Vị trí + hướng nhìn + trạng thái từng ngỗng (FishingSpots dùng để chọn điểm ra rương phía trước ngỗng)
function Guard.Positions()
	local list = {}
	for _, g in ipairs(geese) do
		table.insert(list, { Position = g.Root.Position, Look = g.Root.CFrame.LookVector, State = g.State })
	end
	return list
end

-- Người chơi vừa thả phao câu ở `position` khi ngỗng vừa đi ngang: ngỗng nào chưa đi xa (trong cfg.ReturnRange)
-- quay lại đuổi luôn, dù đang quay lưng / khuất tầm nhìn. Trả về true nếu có ngỗng quay lại.
function Guard.Recall(player, position)
	local hrp = targetRoot(player)
	if not hrp then
		return false
	end
	local called = false
	local now = os.clock()
	for _, g in ipairs(geese) do
		local idle = g.State == "Patrol" or g.State == "Search" or g.State == "Suspicious"
		if idle and flatDistance(g.Root.Position, position) <= cfg.ReturnRange then
			g.LastSeen = hrp.Position
			g.LastSeenAt = now + cfg.ReturnGrace
			say(g, "Hey! Come back here!", 2)
			setState(g, "Chase", player)
			called = true
		end
	end
	return called
end

function Guard.IsChasing(player)
	for _, g in ipairs(geese) do
		if g.Target == player and g.State == "Chase" then
			return true
		end
	end
	return false
end

-- hooks.OnCaught(player): gọi khi ngỗng bắt được người chơi
-- hooks.Suspicion(player): "Reeling" (đang kéo câu) | "Loot" (túi có đồ) | nil (người qua đường)
function Guard.Init(_, callbacks)
	hooks = callbacks or {}
	if not cfg.Enabled or #cfg.Patrol == 0 then
		return
	end
	task.spawn(function()
		-- Đợi terrain vừa dựng xong sẵn sàng cho vật lý, không thì ngỗng rơi xuyên đất ngay lúc sinh ra
		task.wait(2)
		for i, point in ipairs(cfg.Patrol) do
			patrolPoints[i] = groundAt(point)
		end
		for i = 1, cfg.Count do
			local index = math.floor((i - 1) * #patrolPoints / cfg.Count) + 1
			spawnGoose(patrolPoints[index], index)
		end

		local last = os.clock()
		while true do
			task.wait(TICK)
			local now = os.clock()
			local dt = now - last
			last = now
			for _, g in ipairs(geese) do
				local ok, err = pcall(function()
					rescueFromWater(g)
					steps[g.State](g, now, dt)
					follow(g)
					updateAnim(g, now)
				end)
				if not ok then
					warn("Guard:", err)
				end
			end
		end
	end)
end

return Guard
