-- LocalScript: StarterPlayer > StarterPlayerScripts > Sprint
-- Giữ Shift (máy tính), L3 (tay cầm) hoặc nút "Sprint" (điện thoại) để chạy nhanh.
-- Tốc độ chỉnh trong Config.Movement.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local movement = Config.Movement

local player = Players.LocalPlayer
local sprinting = false
local NORMAL_FOV = 70

local function apply()
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = sprinting and movement.SprintSpeed or movement.WalkSpeed
	end
	local camera = workspace.CurrentCamera
	if camera then
		TweenService:Create(camera, TweenInfo.new(0.25), { FieldOfView = sprinting and movement.SprintFov or NORMAL_FOV }):Play()
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

-- Hồi sinh: nhân vật mới về tốc độ thường
player.CharacterAdded:Connect(function(character)
	character:WaitForChild("Humanoid")
	sprinting = false
	apply()
end)
if player.Character then
	apply()
end
