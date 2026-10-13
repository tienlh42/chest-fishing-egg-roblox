-- ModuleScript: ServerScriptService > Modules > Data
-- Giữ dữ liệu của từng người chơi (profile), lưu/tải bằng DataStore, gửi bản sao xuống client.
--
-- Profile:
--   Coins, Eggs = { Common = 2 }, Pets = { "Cat", "Dog" },
--   Rods = { Basic = true }, EquippedRod = "Basic",
--   IncubatorSlots = 1, Incubators = { ["1"] = { Tier = "Common", Start = os.time() } },
--   AutoFishers = { ["1"] = { Last = os.time(), Stored = 0 } }

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
		Pets = {},
		Rods = { [Config.Rods[1].Id] = true },
		EquippedRod = Config.Rods[1].Id,
		IncubatorSlots = Config.Incubators.StartSlots,
		Incubators = {},
		AutoFishers = {},
	}
	for tier in pairs(Config.Eggs) do
		profile.Eggs[tier] = 0
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

function Data.Save(player)
	local profile = profiles[player]
	if not (profile and canSave[player]) then
		return
	end
	local ok, err = pcall(store.SetAsync, store, tostring(player.UserId), profile)
	if not ok then
		warn("Không lưu được dữ liệu của", player.Name, err)
	end
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
