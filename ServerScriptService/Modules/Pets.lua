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
local SYNC_EVERY = 2 -- giây tối thiểu giữa 2 lần gửi profile vì độ bền pet đổi (ngỗng đánh pet liên tục)

local Pets = {}

local folder = Instance.new("Folder")
folder.Name = "PlayerPets"
folder.Parent = workspace

local spawned = {} -- [player] = model đang hiện
local shownId = {} -- [player] = Id pet đang hiện
local pending = {} -- [player] = token để gộp nhiều lần gọi liên tiếp
local hp = {} -- [player] = { [Id pet] = HP hiện tại }. Mỗi pet giữ HP riêng nên đổi pet qua lại không "hồi máu miễn phí"
local dirty = {} -- [player] = true khi độ bền pet đã đổi mà chưa gửi xuống client
local lastSync = {} -- [player] = os.clock() lần gần nhất gửi profile vì độ bền pet đổi
local lastSent = {} -- [player] = { Key, At } để không gửi thừa
local shielding = {} -- [player] = true khi pet đang chạy ra chặn ngỗng (animation Attack)
local happyUntil = {} -- [player] = os.clock() tới khi pet mới nở còn "Happy"

local function despawn(player)
	if spawned[player] then
		spawned[player]:Destroy()
		spawned[player] = nil
	end
end

-- Bản ghi pet đang equip { Id, Name, Durability }, hoặc nil nếu không có pet đi theo
local function equippedPet(player)
	local profile = Data.Get(player)
	return profile and profile.EquippedPet and (Data.FindPet(profile, profile.EquippedPet))
end

-- HP hiện tại của pet đang equip (pet chưa bị đánh lần nào thì đầy máu)
local function getHP(player, pet)
	return hp[player] and hp[player][pet.Id] or Config.PetMaxHP(pet.Name)
end

local function setHP(player, pet, value)
	hp[player] = hp[player] or {}
	hp[player][pet.Id] = value
end

-- Pet đang equip đã kiệt sức (HP 0) và chưa được nghỉ ở nhà
local function isDown(player)
	local pet = equippedPet(player)
	return pet ~= nil and getHP(player, pet) <= 0
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
	local pet = equippedPet(player)
	local petName = pet and pet.Name
	shownId[player] = pet and pet.Id
	if not (petName and hrp) or isDown(player) then
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

-- { HasPet, Id, Name, HP, Max, Down }
function Pets.Status(player)
	local pet = equippedPet(player)
	local max = Config.PetMaxHP(pet and pet.Name)
	return {
		HasPet = pet ~= nil,
		Id = pet and pet.Id,
		Name = pet and pet.Name,
		HP = pet and getHP(player, pet) or max,
		Max = max,
		Down = isDown(player),
	}
end

-- Pet còn khả năng chặn ngỗng (có pet và chưa kiệt sức)
function Pets.IsShielding(player)
	return equippedPet(player) ~= nil and not isDown(player)
end

local function setDown(player, pet)
	setHP(player, pet, 0)
	local model = spawned[player]
	Remote.Effect(player, "PetDown", { Position = model and model.PrimaryPart and model.PrimaryPart.Position })
	Remote.Notify(player, "Your pet is exhausted and ran back home!")
	despawn(player)
	shielding[player] = nil
	resetTarget(player)
end

-- Pet hết bền: biến mất khỏi danh sách, không có pet nào đi theo nữa (phải equip pet khác trong Bag)
local function breakPet(player, pet)
	local profile = Data.Get(player)
	local _, index = Data.FindPet(profile, pet.Id)
	table.remove(profile.Pets, index)
	profile.EquippedPet = nil
	if hp[player] then
		hp[player][pet.Id] = nil
	end
	local model = spawned[player]
	Remote.Effect(player, "PetDown", { Position = model and model.PrimaryPart and model.PrimaryPart.Position })
	Remote.Notify(player, ("Your %s broke and is gone for good! Equip another pet in your Bag."):format(pet.Name))
	despawn(player)
	shielding[player] = nil
	resetTarget(player)
	dirty[player] = nil
	Data.Update(player)
end

-- Gửi profile xuống client khi độ bền pet đổi: tối đa mỗi SYNC_EVERY giây trong lúc bị đuổi, phần còn lại gửi khi hết đuổi (healTick)
local function syncDurability(player)
	local now = os.clock()
	if now - (lastSync[player] or 0) >= SYNC_EVERY then
		lastSync[player] = now
		dirty[player] = nil
		Data.Update(player)
	else
		dirty[player] = true
	end
end

-- Ngỗng đánh pet: trừ HP (về 0 thì pet kiệt sức) và trừ độ bền đúng bằng số HP vừa mất (hết bền thì pet biến mất)
function Pets.Hit(player, amount)
	if not Pets.IsShielding(player) then
		return
	end
	local pet = equippedPet(player)
	local max = Config.PetMaxHP(pet.Name)
	local before = getHP(player, pet)
	local after = math.max(before - amount, 0)
	setHP(player, pet, after)
	local warnAt = max * Config.Pet.WarnRatio
	if before > warnAt and after <= warnAt then
		Remote.Notify(player, ('%s: "Are you done yet?!"'):format(pet.Name))
	end

	local durabilityBefore = pet.Durability
	pet.Durability = durabilityBefore - (before - after)
	if pet.Durability <= 0 then
		breakPet(player, pet)
		return
	end
	local durabilityWarn = Config.PetDurability(pet.Name) * Config.DurabilityWarnRatio
	if durabilityBefore > durabilityWarn and pet.Durability <= durabilityWarn then
		Remote.Notify(player, ("Your %s is almost broken! (%d left)"):format(pet.Name, math.ceil(pet.Durability)))
	end

	if after <= 0 then
		setDown(player, pet)
	end
	syncDurability(player)
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
	local key = ("%s|%s|%d|%s"):format(tostring(s.HasPet), tostring(s.Id), math.floor(s.HP), tostring(s.Down))
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
			-- pet nào cũng hồi đầy sau HealTime giây (pet nhiều HP thì hồi nhiều HP/giây hơn). Chỉ pet đang equip mới hồi
			local pet = equippedPet(player)
			local max = Config.PetMaxHP(pet and pet.Name)
			local perTick = max / Config.Pet.HealTime * TICK
			local current = pet and getHP(player, pet) or max
			if pet and current < max and SafeZone.IsSafe(player) then
				-- đứng gần ổ pet trong nhà thì hồi nhanh hơn (Config.House.PetBedHealMult)
				setHP(player, pet, math.min(current + perTick * House.HealMultiplier(player), max))
				if current <= 0 then
					Remote.Notify(player, "Your pet is back on its feet!")
					schedule(player, 0.3)
				end
			end
			if dirty[player] and not shielding[player] then
				dirty[player] = nil
				lastSync[player] = os.clock()
				Data.Update(player) -- hết đuổi: gửi độ bền pet mới nhất xuống client
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

-- Gọi khi profile đổi: chỉ dựng lại nếu pet đang equip khác pet đang hiện
local function onProfileUpdated(player)
	local pet = equippedPet(player)
	local id = pet and pet.Id
	if id ~= shownId[player] then
		local first = shownId[player] == nil
		shownId[player] = id
		schedule(player, first and 2.5 or 0.4) -- chưa có pet nào hiện (vừa nở trứng): đợi hoạt ảnh nở xong. Đổi pet: hiện gần như ngay
	end
end

function Pets.SetupPlayer(player)
	hp[player] = {}
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
	shownId[player] = nil
	hp[player] = nil
	dirty[player] = nil
	lastSync[player] = nil
	lastSent[player] = nil
	shielding[player] = nil
	happyUntil[player] = nil
	despawn(player)
end

Data.Updated:Connect(onProfileUpdated)

return Pets
