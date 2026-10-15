-- ModuleScript: ServerScriptService > Modules > Data
-- Giữ dữ liệu của từng người chơi (profile), lưu/tải bằng DataStore, gửi bản sao xuống client.
--
-- Profile:
--   Coins, Eggs = { Reed = 2 }, Chests = { ["Wooden Chest"] = 3 } (rương chưa mở trong Stash), Pets = { { Id = 1, Name = "Baker Dog", Durability = 2600 } }, EquippedPet = 1, NextPetId = 2,
--   Rods = { Basic = true, Catfish = 37 } (số = độ bền còn lại, Config.Rods[].Durability), EquippedRod = "Basic",
--   IncubatorSlots = 1, Incubators = { ["1"] = { Tier = "Common", Start = os.time() } },
--   FisherSlots = 1 (số ổ máy câu đã mở), AutoFishers = { ["1"] = { Tier = 1, Durability = 120, Last = os.time(), Stored = 0 } } (chỉ ổ có máy)

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Config)
local Remote = require(script.Parent.Remote)

local store = DataStoreService:GetDataStore("PlayerData_v2")
local oldStore = DataStoreService:GetDataStore("PlayerData_v1")

local Data = {}

local profiles = {} -- [player] = profile
local canSave = {} -- [player] = true nếu tải thành công (tải lỗi thì không lưu đè)

local updated = Instance.new("BindableEvent")
Data.Updated = updated.Event -- (player) bắn ra mỗi khi profile thay đổi

local function defaultProfile()
	local profile = {
		Coins = 0,
		Eggs = {},
		Chests = {}, -- kho rương chưa mở trong Stash: [tên rương Config.Chests[].Name] = số lượng (mở ở Stash.lua)
		Pets = {}, -- danh sách bản ghi { Id, Name, Durability }, tạo bằng Data.NewPet
		NextPetId = 1, -- Id của pet kế tiếp (chỉ tăng, không dùng lại)
		-- EquippedPet: Id pet đang đi theo (không có = không pet)
		Rods = { [Config.Rods[1].Id] = true },
		EquippedRod = Config.Rods[1].Id,
		IncubatorSlots = Config.Incubators.StartSlots,
		Incubators = {},
		FisherSlots = 1, -- số ổ máy câu đã mở (Config.AutoFisher.PedestalPrices, ổ 1 miễn phí)
		AutoFishers = {}, -- [ổ] = { Tier, Durability, Last, Stored }, chỉ ổ đang có máy
		BagLevel = 0, -- số lần đã nâng cấp túi (Config.Bag.Upgrades, mua ở Tool Shop)
		Keys = 0, -- số Chìa vạn năng (Config.Robbery), mua ở Tool Shop
		LockLevel = 0, -- cấp khóa cửa nhà (Config.Robbery.Locks), giảm tỉ lệ mở của chìa
		ShieldUntil = 0, -- os.time() đến khi hết khiên chống cướp (sau khi bị cướp)
		LastDaily = 0, -- ngày (os.time // 86400) đã nhận quà hằng ngày gần nhất
		Gear = {}, -- trang bị đã mua: { RocketSandals = true } (Config.Gear)
		-- Tutorial, StarterGiven: đặt trong Data.Load (người cũ / người mới xử lý khác nhau)
	}
	for tier in pairs(Config.Eggs) do
		profile.Eggs[tier] = 0
	end
	for _, chest in ipairs(Config.Chests) do
		profile.Chests[chest.Name] = 0
	end
	return profile
end

-- Bổ sung trường còn thiếu (khi bạn thêm tính năng mới vào profile)
local function reconcile(profile)
	for key, value in pairs(defaultProfile()) do
		if profile[key] == nil then
			profile[key] = value
		end
	end
	for tier in pairs(Config.Eggs) do
		profile.Eggs[tier] = profile.Eggs[tier] or 0
	end
	for _, chest in ipairs(Config.Chests) do
		profile.Chests[chest.Name] = profile.Chests[chest.Name] or 0
	end
	-- Pet lưu từ trước là tên (chuỗi): đổi thành bản ghi đầy bền. Trước đây pet MỚI NHẤT đi theo nên cho nó đi theo tiếp
	local convertedPet = false
	for i, pet in ipairs(profile.Pets) do
		if typeof(pet) == "string" then
			profile.Pets[i] = { Id = profile.NextPetId, Name = pet, Durability = Config.PetDurability(pet) }
			profile.NextPetId += 1
			convertedPet = true
		end
	end
	if convertedPet then
		profile.EquippedPet = profile.Pets[#profile.Pets].Id
	end
	-- Máy câu lưu từ trước khi có tier riêng: máy ở ổ i là tier i, đầy bền; mở sẵn các ổ đã có máy
	for key, entry in pairs(profile.AutoFishers) do
		if entry.Tier == nil then
			local index = tonumber(key)
			entry.Tier = index
			entry.Durability = Config.AutoFisher.Tiers[index].Durability
			profile.FisherSlots = math.max(profile.FisherSlots, index)
		end
	end
	-- Cần lưu từ trước khi có độ bền là `true`: coi như còn đầy bền
	for _, rod in ipairs(Config.Rods) do
		if rod.Durability and profile.Rods[rod.Id] == true then
			profile.Rods[rod.Id] = rod.Durability
		end
	end
	return profile
end

-- Chuyển dữ liệu kiểu cũ (v1: Coins, Eggs, Pets) sang profile mới
local function migrateV1(old)
	local profile = defaultProfile()
	profile.Coins = old.Coins or 0
	for tier, count in pairs(old.Eggs or {}) do
		profile.Eggs[tier] = count
	end
	for _, petName in ipairs(old.Pets or {}) do
		table.insert(profile.Pets, petName)
	end
	return profile
end

function Data.Load(player)
	local key = tostring(player.UserId)
	-- Lưu ý: pcall lỗi thì giá trị thứ 2 là CHUỖI thông báo lỗi, không phải dữ liệu
	local ok, result = pcall(store.GetAsync, store, key)
	local saved = ok and result or nil
	if ok and saved == nil then
		local okOld, old = pcall(oldStore.GetAsync, oldStore, key)
		ok = okOld
		if okOld and typeof(old) == "table" then
			saved = migrateV1(old)
		elseif not okOld then
			result = old
		end
	end
	if not player.Parent then
		return nil -- người chơi đã thoát trong lúc tải
	end

	profiles[player] = reconcile(typeof(saved) == "table" and saved or defaultProfile())
	canSave[player] = ok

	-- Người mới: tặng 1 Reed Egg (nở ra Baker Dog) + bật hướng dẫn. Người cũ đã có pet thì bỏ qua hướng dẫn.
	local profile = profiles[player]
	if profile.Tutorial == nil then
		profile.Tutorial = #profile.Pets > 0 and 99 or 1 -- bước hướng dẫn đang làm (Tutorial.lua), 99 = xong
	end
	if not profile.StarterGiven then
		profile.StarterGiven = true
		if #profile.Pets == 0 then
			profile.Eggs.Reed = (profile.Eggs.Reed or 0) + 1
		end
	end

	-- Bản dev: chạy trong Studio thì cho đầy tiền để test
	if Config.Dev.Enabled and RunService:IsStudio() then
		profiles[player].Coins = math.max(profiles[player].Coins, Config.Dev.Coins)
	end
	if not ok then
		warn("Không tải được dữ liệu của", player.Name, result)
		Remote.Notify(player, "Could not load your data. Progress will NOT be saved this session.")
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats
	leaderstats.Parent = player

	Data.Update(player)
	return profiles[player]
end

-- Thêm 1 pet mới (đầy bền) vào profile (chưa gọi Data.Update). Chưa có pet nào đang đi theo thì cho nó đi theo luôn
function Data.NewPet(profile, name)
	local pet = { Id = profile.NextPetId, Name = name, Durability = Config.PetDurability(name) }
	profile.NextPetId += 1
	table.insert(profile.Pets, pet)
	if profile.EquippedPet == nil then
		profile.EquippedPet = pet.Id
	end
	return pet
end

-- Tìm pet theo Id. Trả về bản ghi và vị trí trong danh sách (nil nếu không có)
function Data.FindPet(profile, id)
	for i, pet in ipairs(profile.Pets) do
		if pet.Id == id then
			return pet, i
		end
	end
	return nil
end

function Data.Get(player)
	return profiles[player]
end

-- Gọi sau MỖI lần sửa profile: cập nhật leaderstats + gửi bản mới xuống client
function Data.Update(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Coins.Value = profile.Coins
	end
	Remote.Folder.Sync:FireClient(player, profile)
	updated:Fire(player)
end

-- Trừ tiền nếu đủ (chưa gọi Update, để hàm gọi tự Update sau khi sửa xong)
function Data.Spend(player, amount)
	local profile = profiles[player]
	if not profile or profile.Coins < amount then
		return false
	end
	profile.Coins -= amount
	return true
end

-- Trả về true nếu lưu xong (hoặc phiên này không lưu được: đã cảnh báo lúc tải, không chặn gameplay)
function Data.Save(player)
	local profile = profiles[player]
	if not profile then
		return false
	end
	if not canSave[player] then
		return true
	end
	local ok, err = pcall(store.SetAsync, store, tostring(player.UserId), profile)
	if not ok then
		warn("Không lưu được dữ liệu của", player.Name, err)
	end
	return ok
end

function Data.Release(player)
	Data.Save(player)
	profiles[player] = nil
	canSave[player] = nil
end

function Data.SaveAll()
	for player in pairs(profiles) do
		Data.Save(player)
	end
end

-- Tự lưu mỗi 2 phút phòng server sập
task.spawn(function()
	while true do
		task.wait(120)
		Data.SaveAll()
	end
end)

return Data
