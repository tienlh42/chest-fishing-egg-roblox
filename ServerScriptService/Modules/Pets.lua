-- ModuleScript: ServerScriptService > Modules > Pets
-- Pet mới nhất của người chơi bay theo cạnh người, chặn ngỗng thay người chơi.
-- HP pet chỉ tồn tại trong phiên chơi (không lưu): về 0 thì kiệt sức, hồi khi chủ đứng trong vùng an toàn.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local Models = require(ReplicatedStorage.Models)
local Data = require(script.Parent.Data)
local Remote = require(script.Parent.Remote)
local House = require(script.Parent.House)
local SafeZone = require(script.Parent.SafeZone)

local OFFSET = Vector3.new(3, 1, 2) -- bên phải, cao hơn, hơi lùi về sau
local SHIELD_DISTANCE = 3.5 -- khi chặn ngỗng, pet đứng cách chủ bấy nhiêu stud về phía ngỗng
local TICK = 0.25 -- giây giữa 2 lần hồi HP / gửi HP xuống client
local RESEND = 3 -- giây gửi lại HP dù không đổi (phòng client chưa kịp nghe)

local Pets = {}

local folder = Instance.new("Folder")
folder.Name = "PlayerPets"
folder.Parent = workspace

local spawned = {} -- [player] = model đang hiện
local shownName = {} -- [player] = tên pet đang hiện
local pending = {} -- [player] = token để gộp nhiều lần gọi liên tiếp
local hp = {} -- [player] = HP hiện tại
local down = {} -- [player] = true khi kiệt sức
local lastSent = {} -- [player] = { Key, At } để không gửi thừa
local shielding = {} -- [player] = true khi pet đang chạy ra chặn ngỗng (animation Attack)
local happyUntil = {} -- [player] = os.clock() tới khi pet mới nở còn "Happy"

local function despawn(player)
	if spawned[player] then
		spawned[player]:Destroy()
		spawned[player] = nil
	end
end

local function currentPetName(player)
	local profile = Data.Get(player)
	return profile and profile.Pets[#profile.Pets]
end

local function resetTarget(player)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local target = hrp and hrp:FindFirstChild("PetTarget")
	if target then
		target.Position = OFFSET
	end
end

local function spawnPet(player)
	despawn(player)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local petName = currentPetName(player)
	shownName[player] = petName
	if not (petName and hrp) or down[player] then
		return
	end

	local model = Models.Get(petName)
	local root = model.PrimaryPart
	if not root then
		model:Destroy()
		return
	end

	-- Model asset đã có rig Motor6D / Weld sẵn (animation ghi vào Motor6D): không hàn lại, bỏ Humanoid (pet bay bằng AlignPosition)
	local rigged = model:FindFirstChildWhichIsA("Motor6D", true) ~= nil
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Humanoid") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.Massless = true
			if d ~= root and not rigged then
				-- Hàn mọi Part vào PrimaryPart để cả model di chuyển cùng nhau (model tạm)
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
	model:SetAttribute("Anim", "Happy") -- vừa hiện ra: nhảy mừng, sau đó petAnimTick đổi sang Idle / Walk / Run
	happyUntil[player] = os.clock() + 1.6
end

-- Chọn animation theo việc pet đang làm: chặn ngỗng > mừng > chạy / đi theo chủ > đứng
local function petAnimTick(player)
	local model = spawned[player]
	if not model then
		return
	end
	local anim
	if shielding[player] then
		anim = "Attack"
	elseif happyUntil[player] and os.clock() < happyUntil[player] then
		return -- đang Happy (animation không lặp, giữ khung cuối)
	else
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local velocity = hrp and hrp.AssemblyLinearVelocity or Vector3.zero
		local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		anim = speed > 20 and "Run" or speed > 2 and "Walk" or "Idle"
	end
	if model:GetAttribute("Anim") ~= anim then
		model:SetAttribute("Anim", anim)
	end
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

-- ===== HP + chặn ngỗng =====

-- { HasPet, Name, HP, Max, Down }
function Pets.Status(player)
	local name = currentPetName(player)
	return {
		HasPet = name ~= nil,
		Name = name,
		HP = hp[player] or Config.PetMaxHP(name),
		Max = Config.PetMaxHP(name),
		Down = down[player] == true,
	}
end

-- Pet còn khả năng chặn ngỗng (có pet và chưa kiệt sức)
function Pets.IsShielding(player)
	return currentPetName(player) ~= nil and not down[player]
end

local function setDown(player)
	down[player] = true
	hp[player] = 0
	local model = spawned[player]
	Remote.Effect(player, "PetDown", { Position = model and model.PrimaryPart and model.PrimaryPart.Position })
	Remote.Notify(player, "Your pet is exhausted and ran back home!")
	despawn(player)
	shielding[player] = nil
	resetTarget(player)
end

-- Ngỗng đánh pet: trừ HP, về 0 thì pet kiệt sức
function Pets.Hit(player, amount)
	if not Pets.IsShielding(player) then
		return
	end
	local max = Config.PetMaxHP(currentPetName(player))
	local before = hp[player] or max
	local after = math.max(before - amount, 0)
	hp[player] = after
	local warnAt = max * Config.Pet.WarnRatio
	if before > warnAt and after <= warnAt then
		Remote.Notify(player, ('%s: "Are you done yet?!"'):format(currentPetName(player)))
	end
	if after <= 0 then
		setDown(player)
	end
end

-- Pet chạy ra đứng giữa chủ và ngỗng
function Pets.Shield(player, guardPosition)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local target = hrp and hrp:FindFirstChild("PetTarget")
	if not (target and spawned[player]) then
		return
	end
	local flat = Vector3.new(guardPosition.X - hrp.Position.X, 0, guardPosition.Z - hrp.Position.Z)
	if flat.Magnitude < 0.1 then
		return
	end
	shielding[player] = true
	target.Position = hrp.CFrame:VectorToObjectSpace(flat.Unit * SHIELD_DISTANCE) + Vector3.new(0, 1, 0)
end

function Pets.Unshield(player)
	shielding[player] = nil
	resetTarget(player)
end

local function pushStatus(player, force)
	local s = Pets.Status(player)
	local key = ("%s|%d|%s"):format(tostring(s.HasPet), math.floor(s.HP), tostring(s.Down))
	local last = lastSent[player]
	local now = os.clock()
	if force or not last or last.Key ~= key or now - last.At >= RESEND then
		lastSent[player] = { Key = key, At = now }
		Remote.Effect(player, "PetHP", s)
	end
end

local function healTick()

	for _, player in ipairs(Players:GetPlayers()) do
		if Data.Get(player) then
			-- pet nào cũng hồi đầy sau HealTime giây (pet nhiều HP thì hồi nhiều HP/giây hơn)
			local max = Config.PetMaxHP(currentPetName(player))
			local perTick = max / Config.Pet.HealTime * TICK
			local current = hp[player] or max
			if current < max and currentPetName(player) and SafeZone.IsSafe(player) then
				-- đứng gần ổ pet trong nhà thì hồi nhanh hơn (Config.House.PetBedHealMult)
				hp[player] = math.min(current + perTick * House.HealMultiplier(player), max)
				if down[player] and hp[player] > 0 then
					down[player] = nil
					Remote.Notify(player, "Your pet is back on its feet!")
					schedule(player, 0.3)
				end
			end
			pushStatus(player)
			petAnimTick(player)
		end
	end
end

task.spawn(function()
	while true do
		task.wait(TICK)
		healTick()
	end
end)

-- ===== Theo dõi người chơi =====

-- Gọi khi profile đổi: chỉ dựng lại nếu pet mới nhất khác pet đang hiện
local function onProfileUpdated(player)
	local petName = currentPetName(player)
	if petName ~= shownName[player] then
		shownName[player] = petName
		hp[player] = Config.PetMaxHP(petName) -- pet mới = HP đầy (theo chỉ số pet đó)
		down[player] = nil
		schedule(player, 2.5) -- đợi hoạt ảnh nở trứng xong
	end
end

function Pets.SetupPlayer(player)
	hp[player] = Config.PetMaxHP(currentPetName(player))
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
	hp[player] = nil
	down[player] = nil
	lastSent[player] = nil
	shielding[player] = nil
	happyUntil[player] = nil
	despawn(player)
end

Data.Updated:Connect(onProfileUpdated)

return Pets
