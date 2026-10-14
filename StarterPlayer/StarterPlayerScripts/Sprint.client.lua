-- LocalScript: StarterPlayer > StarterPlayerScripts > Sprint
-- Giữ Shift (máy tính), L3 (tay cầm) hoặc nút "Sprint" (điện thoại) để chạy nhanh.
-- Tốc độ chỉnh trong Config.Movement. Trang bị (Config.Gear, vd. Dép Tên Lửa) cộng thêm % tốc độ.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local movement = Config.Movement

local player = Players.LocalPlayer
local sprinting = false
local NORMAL_FOV = 70
local speedBonus = 0 -- tổng % tốc độ từ trang bị đã mua (cập nhật qua Remotes.Sync)

local function apply()
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	-- Đang câu (server đặt attribute "Fishing") thì đứng im, bỏ qua Shift
	local running = sprinting and not (humanoid and humanoid:GetAttribute("Fishing"))
	if humanoid and not humanoid:GetAttribute("Fishing") then
		local base = running and movement.SprintSpeed or movement.WalkSpeed
		humanoid.WalkSpeed = base * (1 + speedBonus)
	end
	local camera = workspace.CurrentCamera
	if camera then
		TweenService:Create(camera, TweenInfo.new(0.25), { FieldOfView = running and movement.SprintFov or NORMAL_FOV }):Play()
	end
end

local function onSprint(_, state)
	if state == Enum.UserInputState.Begin then
		sprinting = true
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		sprinting = false
	end
	apply()
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction("Sprint", onSprint, true, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift, Enum.KeyCode.ButtonL3)
ContextActionService:SetTitle("Sprint", "Sprint")

-- Server bật/tắt "Fishing" thì áp lại tốc độ (hết câu -> trả về đi / chạy bình thường)
local function watch(humanoid)
	humanoid:GetAttributeChangedSignal("Fishing"):Connect(apply)
end

-- Hồi sinh: nhân vật mới về tốc độ thường
player.CharacterAdded:Connect(function(character)
	watch(character:WaitForChild("Humanoid"))
	sprinting = false
	apply()
end)
if player.Character then
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		watch(humanoid)
	end
	apply()
end

-- Trang bị đã mua (profile.Gear) -> cộng dồn SpeedBonus
local function onProfile(profile)
	local bonus = 0
	for id, owned in pairs(profile and profile.Gear or {}) do
		local gear = owned and Config.Gear[id]
		if gear and gear.SpeedBonus then
			bonus += gear.SpeedBonus
		end
	end
	if bonus ~= speedBonus then
		speedBonus = bonus
		apply()
	end
end

local remotes = ReplicatedStorage:WaitForChild("Remotes")
remotes:WaitForChild("Sync").OnClientEvent:Connect(onProfile)
task.spawn(function()
	local ok, _, profile = pcall(remotes.Action.InvokeServer, remotes.Action, "GetData")
	if ok then
		onProfile(profile)
	end
end)
