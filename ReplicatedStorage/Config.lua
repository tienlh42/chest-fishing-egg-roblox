-- ModuleScript: ReplicatedStorage > Config
-- Toàn bộ số liệu game nằm ở đây. Muốn cân bằng game chỉ cần sửa file này.

local Config = {}

-- Rương: Weight càng cao càng dễ câu được.
-- Xếp từ thường -> hiếm: cần câu có Luck cao sẽ tăng tỉ lệ các rương ở cuối danh sách.
Config.Chests = {
	{ Name = "Wooden Chest", Weight = 70, Coins = { 5, 15 }, EggTier = "Common", EggChance = 0.30 },
	{ Name = "Golden Chest", Weight = 25, Coins = { 20, 60 }, EggTier = "Common", EggChance = 0.70 },
	{ Name = "Diamond Chest", Weight = 5, Coins = { 100, 300 }, EggTier = "Rare", EggChance = 1.00 },
}

-- Trứng: HatchTime tính bằng giây (trứng vẫn nở khi người chơi offline)
Config.Eggs = {
	Common = {
		HatchTime = 10,
		Pets = {
			{ Name = "Cat", Weight = 60 },
			{ Name = "Dog", Weight = 35 },
			{ Name = "Fox", Weight = 5 },
		},
	},
	Rare = {
		HatchTime = 20,
		Pets = {
			{ Name = "Fox", Weight = 60 },
			{ Name = "Dragon", Weight = 35 },
			{ Name = "Phoenix", Weight = 5 },
		},
	},
}

Config.CastTime = { Min = 3, Max = 6 } -- giây chờ cá cắn câu (nhân với Speed của cần)

-- Animation nhân vật (dạng "rbxassetid://123456"). Để "" = chỉ dùng hoạt ảnh tạm.
-- Cách lấy ID: làm animation bằng Animation Editor -> Publish to Roblox -> copy ID.
Config.Animations = {
	Cast = "", -- vung cần ném câu
	Reel = "", -- kéo cần khi cá cắn
}

-- ===== TOOL SHOP =====
-- Cần câu. Luck: nhân tỉ lệ rương hiếm. Speed: nhân thời gian chờ (nhỏ hơn = nhanh hơn).
-- Name cũng là tên model trong CustomModels. Color/Length chỉ dùng cho model tạm.
Config.Rods = {
	{ Id = "Basic", Name = "Basic Rod", Price = 0, Luck = 1, Speed = 1, Color = Color3.fromRGB(110, 70, 35), Length = 7 },
	{ Id = "Sturdy", Name = "Sturdy Rod", Price = 250, Luck = 1.5, Speed = 0.85, Color = Color3.fromRGB(70, 110, 160), Length = 8 },
	{ Id = "Pro", Name = "Pro Rod", Price = 1500, Luck = 2.5, Speed = 0.7, Color = Color3.fromRGB(40, 40, 45), Length = 9 },
	{ Id = "Legend", Name = "Legend Rod", Price = 8000, Luck = 4, Speed = 0.5, Color = Color3.fromRGB(255, 190, 40), Length = 10 },
}

-- Máy câu tự động: Prices[i] = giá máy thứ i (số máy tối đa = số phần tử)
Config.AutoFisher = {
	Prices = { 500, 1500, 4000, 10000 },
	Interval = 30, -- giây câu được 1 rương
	Capacity = 20, -- kho chứa tối đa (đầy thì ngừng, kể cả khi offline)
	Luck = 1,
}

-- Máy ấp trứng trên plot
Config.Incubators = {
	StartSlots = 1,
	MaxSlots = 4,
	Prices = { [2] = 300, [3] = 1500, [4] = 6000 }, -- giá mở máy thứ 2, 3, 4
}

-- ===== MARKET =====
Config.SellPrices = {
	Eggs = { Common = 10, Rare = 75 },
	Pets = { Cat = 15, Dog = 20, Fox = 60, Dragon = 250, Phoenix = 1200 },
}

-- ===== DI CHUYỂN =====
Config.Movement = {
	WalkSpeed = 16, -- tốc độ đi bình thường (mặc định Roblox = 16)
	SprintSpeed = 30, -- tốc độ khi giữ Shift
	SprintFov = 80, -- góc camera khi chạy (bình thường 70) cho cảm giác nhanh
}

-- ===== DEV =====
-- Chỉ có tác dụng khi chạy trong Roblox Studio (game đã publish không bị ảnh hưởng).
-- Nhớ đặt Enabled = false nếu muốn test cân bằng kinh tế thật.
Config.Dev = {
	Enabled = true,
	Coins = 1000000000, -- mỗi lần vào game, coins được nạp lên ít nhất mức này
}

-- ===== Hàm dùng chung =====

function Config.GetRod(id)
	for _, rod in ipairs(Config.Rods) do
		if rod.Id == id then
			return rod
		end
	end
	return Config.Rods[1]
end

-- Chọn ngẫu nhiên 1 phần tử theo trọng số.
-- luck > 1 tăng trọng số các phần tử càng về cuối danh sách (hiếm hơn).
function Config.WeightedRoll(list, luck)
	luck = luck or 1
	local total = 0
	for i, item in ipairs(list) do
		total += item.Weight * luck ^ (i - 1)
	end
	local roll = math.random() * total
	for i, item in ipairs(list) do
		roll -= item.Weight * luck ^ (i - 1)
		if roll <= 0 then
			return item
		end
	end
	return list[#list]
end

-- Số rương đang có trong 1 máy câu tại thời điểm `now` (os.time)
-- entry = { Last = thời điểm tính gần nhất, Stored = số rương đã tích }
function Config.AutoFisherStored(entry, now)
	local cfg = Config.AutoFisher
	local ticks = math.max(math.floor((now - entry.Last) / cfg.Interval), 0)
	local stored = math.min(cfg.Capacity, entry.Stored + ticks)
	local last = entry.Last + ticks * cfg.Interval
	if stored >= cfg.Capacity then
		last = now -- đầy kho: ngừng đếm
	end
	return stored, last
end

return Config
