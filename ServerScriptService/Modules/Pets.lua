-- ModuleScript: ServerScriptService > Modules > Pets
-- Pet mới nhất của người chơi bay theo cạnh người.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Models = require(ReplicatedStorage.Models)
local Data = require(script.Parent.Data)

local OFFSET = Vector3.new(3, 1, 2) -- bên phải, cao hơn, hơi lùi về sau

local Pets = {}

local folder = Instance.new("Folder")
folder.Name = "PlayerPets"
folder.Parent = workspace

local spawned = {} -- [player] = model đang hiện
local shownName = {} -- [player] = tên pet đang hiện
local pending = {} -- [player] = token để gộp nhiều lần gọi liên tiếp

local function despawn(player)
	if spawned[player] then
		spawned[player]:Destroy()
		spawned[player] = nil
	end
end

local function spawnPet(player)
	despawn(player)
	local profile = Data.Get(player)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local petName = profile and profile.Pets[#profile.Pets]
	shownName[player] = petName
	if not (petName and hrp) then
		return
	end

	local model = Models.Get(petName)
	local root = model.PrimaryPart
	if not root then
		model:Destroy()
		return
	end

	-- Hàn mọi Part vào PrimaryPart để cả model di chuyển cùng nhau
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.Massless = true
			if d ~= root then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = root
				weld.Part1 = d
				weld.Parent = d
			end
		end
	end
	model:PivotTo(hrp.CFrame * CFrame.new(OFFSET))

	local target = hrp:FindFirstChild("PetTarget") or Instance.new("Attachment")
	target.Name = "PetTarget"
	target.Position = OFFSET
	target.Parent = hrp

	local a0 = Instance.new("Attachment")
	a0.Parent = root
	local alignPos = Instance.new("AlignPosition")
	alignPos.Attachment0 = a0
	alignPos.Attachment1 = target
	alignPos.MaxForce = 1e6
	alignPos.Responsiveness = 20
	alignPos.Parent = root
	local alignRot = Instance.new("AlignOrientation")
	alignRot.Attachment0 = a0
	alignRot.Attachment1 = target
	alignRot.MaxTorque = 1e6
	alignRot.Responsiveness = 20
	alignRot.Parent = root

	model.Parent = folder
	root:SetNetworkOwner(player) -- máy người chơi tính vật lý -> pet bám mượt
	spawned[player] = model
end

local function schedule(player, delay)
	local token = {}
	pending[player] = token
	task.delay(delay, function()
		if pending[player] == token then
			pending[player] = nil
			spawnPet(player)
		end
	end)
end

-- Gọi khi profile đổi: chỉ dựng lại nếu pet mới nhất khác pet đang hiện
local function onProfileUpdated(player)
	local profile = Data.Get(player)
	local petName = profile and profile.Pets[#profile.Pets]
	if petName ~= shownName[player] then
		shownName[player] = petName
		schedule(player, 2.5) -- đợi hoạt ảnh nở trứng xong
	end
end

function Pets.SetupPlayer(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart")
		schedule(player, 0.5)
	end)
	player.CharacterRemoving:Connect(function()
		despawn(player)
	end)
	if player.Character then
		schedule(player, 0.5)
	end
end

function Pets.RemovePlayer(player)
	pending[player] = nil
	shownName[player] = nil
	despawn(player)
end

Data.Updated:Connect(onProfileUpdated)

return Pets
