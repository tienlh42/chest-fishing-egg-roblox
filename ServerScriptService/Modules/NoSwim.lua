-- ModuleScript: ServerScriptService > Modules > NoSwim
-- Cấm bơi: người chơi rớt/nhảy xuống hồ hay ao thì bị đưa về chỗ đứng vững gần nhất.
-- (Ngỗng không với tới được người đang bơi nên bơi sẽ thành cách trốn.)

local Players = game:GetService("Players")
local Remote = require(script.Parent.Remote)

local TICK = 0.2
local CELL = 4 -- Terrain làm tròn theo ô 4 stud

local NoSwim = {}

local safeSpot = {} -- [player] = { Character, CFrame } chỗ cuối cùng đứng trên đất / cầu tàu

-- Điểm này nằm trong khối nước của Terrain?
local function inWater(position)
	local region = Region3.new(position - Vector3.one, position + Vector3.one):ExpandToGrid(CELL)
	local materials, occupancy = workspace.Terrain:ReadVoxels(region, CELL)
	local size = materials.Size
	for x = 1, size.X do
		for y = 1, size.Y do
			for z = 1, size.Z do
				if materials[x][y][z] == Enum.Material.Water and occupancy[x][y][z] > 0.5 then
					return true
				end
			end
		end
	end
	return false
end

-- Bên dưới chân là vật rắn (đất, cầu tàu) trong tầm gần, không phải mặt nước?
local function standingOnSolid(character, hrp)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = false
	local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -8, 0), params)
	return hit ~= nil and hit.Material ~= Enum.Material.Water
end

local function check(player)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (hrp and humanoid and humanoid.Health > 0) then
		return
	end

	if inWater(hrp.Position) then
		local spot = safeSpot[player]
		if spot and spot.Character == character then
			character:PivotTo(spot.CFrame + Vector3.new(0, 3, 0))
			hrp.AssemblyLinearVelocity = Vector3.zero
			Remote.Notify(player, "No swimming! Stay out of the water.")
		end
	elseif standingOnSolid(character, hrp) then
		safeSpot[player] = { Character = character, CFrame = hrp.CFrame }
	end
end

function NoSwim.Init()
	task.spawn(function()
		while true do
			task.wait(TICK)
			for _, player in ipairs(Players:GetPlayers()) do
				local ok, err = pcall(check, player)
				if not ok then
					warn("NoSwim:", err)
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		safeSpot[player] = nil
	end)
end

return NoSwim
