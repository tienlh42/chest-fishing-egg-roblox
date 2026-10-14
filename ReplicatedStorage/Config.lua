-- ModuleScript: ReplicatedStorage > Config
-- Toàn bộ số liệu game nằm ở đây. Muốn cân bằng game chỉ cần sửa file này.

local Config = {}

-- Rương: Weight càng cao càng dễ câu được.
-- Xếp từ thường -> hiếm: cần câu có Luck cao sẽ tăng tỉ lệ các rương ở cuối danh sách.
-- Model = tên asset trong CustomModels (Assets/Models, từ repo roblox-assets). Asset có sẵn animation Spawn / Idle / Open / Vanish.
-- HoldTime: số giây phải giữ nút để kéo rương lên (nhân với Speed của cần). Rương càng hiếm càng lâu = càng rủi ro.
-- Eggs: mỗi rương ra tối đa 1 quả trứng. Xét lần lượt từ trên xuống (trứng xịn trước): trúng tỉ lệ nào thì ra loại đó.
--   Tier là khoá trong Config.Eggs. Rương càng hiếm càng dễ ra trứng xịn.
Config.Chests = {
	{ Name = "Wooden Chest", Model = "TreasureChest_Common", Weight = 60, Coins = { 5, 15 }, HoldTime = 6, Eggs = {
		{ Tier = "Reed", Chance = 0.30 },
	} },
	{ Name = "Blue Chest", Model = "TreasureChest_Rare", Weight = 25, Coins = { 20, 60 }, HoldTime = 9, Eggs = {
		{ Tier = "Bubble", Chance = 0.12 },
		{ Tier = "Reed", Chance = 0.55 },
	} },
	{ Name = "Purple Chest", Model = "TreasureChest_Epic", Weight = 10, Coins = { 60, 150 }, HoldTime = 12, Eggs = {
		{ Tier = "Crystal", Chance = 0.12 },
		{ Tier = "Bubble", Chance = 0.35 },
		{ Tier = "Reed", Chance = 0.80 },
	} },
	{ Name = "Golden Chest", Model = "TreasureChest_Legendary", Weight = 4, Coins = { 150, 300 }, HoldTime = 15, Eggs = {
		{ Tier = "Gold", Chance = 0.15 },
		{ Tier = "Crystal", Chance = 0.35 },
		{ Tier = "Bubble", Chance = 1.00 },
	} },
	{ Name = "Rainbow Chest", Model = "TreasureChest_Mythic", Weight = 1, Coins = { 300, 600 }, HoldTime = 18, Eggs = {
		{ Tier = "Dragon", Chance = 0.12 },
		{ Tier = "Gold", Chance = 0.35 },
		{ Tier = "Crystal", Chance = 1.00 },
	} },
}

-- Tung trứng của 1 rương. Trả về tier (khoá trong Config.Eggs) hoặc nil (không có trứng)
function Config.RollChestEgg(chest)
	for _, egg in ipairs(chest.Eggs or {}) do
		if math.random() < egg.Chance then
			return egg.Tier
		end
	end
	return nil
end

-- Trứng: HatchTime tính bằng giây (trứng vẫn nở khi người chơi offline). Mỗi trứng nở đúng 1 loại pet (asset Egg_* <-> Pet_*).
-- Model = tên asset trong CustomModels. Tên hiện cho người chơi: "<Tier> Egg".
Config.Eggs = {
	-- Trứng khởi đầu: người mới được tặng 1 quả (Data.Load), nở nhanh. Không bán được, không câu được.
	Starter = { Model = "Egg_Starter", HatchTime = 5, Pets = { { Name = "Chef Cat", Weight = 1 } } },
	Reed = { Model = "Egg_Reed", HatchTime = 10, Pets = { { Name = "Baker Dog", Weight = 1 } } },
	Bubble = { Model = "Egg_Bubble", HatchTime = 20, Pets = { { Name = "Muscle Duck", Weight = 1 } } },
	Crystal = { Model = "Egg_Crystal", HatchTime = 40, Pets = { { Name = "Magician Cat", Weight = 1 } } },
	Gold = { Model = "Egg_Gold", HatchTime = 70, Pets = { { Name = "K9 Dog", Weight = 1 } } },
	Dragon = { Model = "Egg_Dragon", HatchTime = 120, Pets = { { Name = "Office Dragon", Weight = 1 } } },
}

-- Thứ tự hiển thị trứng (từ thường -> hiếm)
Config.EggOrder = { "Starter", "Reed", "Bubble", "Crystal", "Gold", "Dragon" }

-- ===== CÂU CÁ: GIỮ NÚT ĐỂ KÉO =====
-- Hồ chung ("Lake") là hồ CẤM CÂU: rương kéo được vào túi tạm, phải mang về Stash ở nơi an toàn mới giữ được.
-- Ao riêng trên plot ("Pond"): an toàn, rương vào thẳng tài khoản nhưng kéo chậm hơn và ít may mắn hơn.
Config.Fishing = {
	CastDistance = 15, -- phao rơi cách người bao nhiêu stud về phía trước mặt (phải rơi trúng nước mới câu được)
	MaxMove = 3, -- đang KÉO mà bị đẩy/trượt xa chỗ bắt đầu quá số stud này thì hụt (1.5 quá chặt: trượt nhẹ trên cỏ cũng hụt)
	-- Câu lén: NHẢ nút = tạm dừng, giữ nguyên tiến độ (phao vẫn dưới nước). Giữ lại để kéo tiếp.
	Leash = 12, -- đang tạm dừng mà đi xa chỗ câu quá số stud này thì đứt dây
	PauseTimeout = 40, -- tạm dừng lâu quá số giây này thì rương tuột khỏi lưỡi
	LakeLuck = 1.5, -- hồ cấm nhân thêm Luck (dễ ra rương hiếm hơn)
	PondTimeMult = 1.5, -- ao riêng: thời gian kéo nhân hệ số này
	NoiseDelay = 3, -- kéo được tổng cộng bao nhiêu giây thì bắt đầu gây tiếng động
	NoiseRadius = 45, -- ngỗng trong bán kính này nghe thấy tiếng câu (≈ 1/3 vòng tuần tra quanh hồ)
}

-- Điểm câu trên hồ cấm (FishingSpots.lua): phao CHEST, phải ném phao gần phao mới móc được.
-- Mỗi điểm chỉ 1 người câu. Rương KHÔNG có sẵn: nó hiện ngẫu nhiên ở điểm câu nằm phía TRƯỚC ngỗng (ngỗng sắp đi tới),
-- tối đa MaxActive rương cùng lúc. Lấy được hoặc hụt thì điểm nghỉ RespawnTime giây mới có thể ra rương lại.
Config.Spots = {
	Radius = 7, -- phao rơi cách điểm câu tối đa bấy nhiêu stud thì móc được
	RespawnTime = 20, -- sau khi câu xong, điểm này chưa ra rương lại trong bấy nhiêu giây
	MaxActive = 3, -- số rương tối đa cùng hiện trên hồ
	SpawnAhead = 80, -- chỉ ra rương ở điểm cách ngỗng không quá bấy nhiêu stud (ngỗng ~10 stud/s: còn ~8 giây là ngỗng tới)
	SpawnMinDist = 25, -- không ra rương ngay sát chân ngỗng
	SpawnChance = 0.3, -- xác suất ra rương mỗi 0.5 giây cho 1 điểm hợp lệ (ngẫu nhiên thời điểm / điểm nào)
	Lifetime = 40, -- rương hiện mà không ai câu thì biến mất sau bấy nhiêu giây
	PassRadius = 22, -- ngỗng đi qua điểm trong bán kính này = "đã đi ngang qua điểm"
	ReturnWindow = 20, -- câu trong vòng bấy nhiêu giây sau khi ngỗng vừa đi ngang (và chưa đi xa, xem Guard.ReturnRange) thì ngỗng quay lại đuổi
}

-- Túi tạm: đồ kéo từ hồ cấm nằm ở đây cho tới khi cất vào Stash. Bị bắt/chết ngoài vùng an toàn = mất hết.
Config.Bag = {
	Capacity = 4,
	-- Nâng cấp túi: mua ở TOOL SHOP (bảng Shop > Upgrades). Cấp 0 = Capacity ở trên
	Upgrades = {
		{ Capacity = 5, Price = 300 },
		{ Capacity = 6, Price = 1200 },
	},
}

-- Pet bảo vệ: chặn ngỗng, mất HP, kiệt sức (0 HP) thì rút về. Hồi HP khi chủ đứng trong vùng an toàn.
Config.Pet = {
	MaxHP = 100, -- HP mặc định nếu pet không có trong Stats
	WarnRatio = 0.3, -- HP dưới 30% máu tối đa thì pet kêu báo nguy
	HealTime = 40, -- giây để hồi từ 0 đến đầy (pet nào cũng vậy)
	-- Chỉ số riêng từng pet: HP càng cao càng chặn ngỗng được lâu (ngỗng đánh Guard.PetDamage HP/giây)
	-- Model = tên asset trong CustomModels (Assets/Models); animation đổi bằng attribute "Anim" (Pets.lua)
	Stats = {
		["Chef Cat"] = { Model = "Pet_CatPot", HP = 100 }, -- ~20s
		["Baker Dog"] = { Model = "Pet_DogBaker", HP = 130 }, -- ~26s
		["Muscle Duck"] = { Model = "Pet_DuckMuscle", HP = 220 }, -- ~44s, chịu đòn lâu nhất
		["Magician Cat"] = { Model = "Pet_CatMagician", HP = 170 }, -- ~34s
		["K9 Dog"] = { Model = "Pet_DogK9", HP = 240 }, -- ~48s
		["Office Dragon"] = { Model = "Pet_DragonOffice", HP = 300 }, -- ~60s
	},
}

-- Máu tối đa của 1 loại pet
function Config.PetMaxHP(petName)
	local stats = petName and Config.Pet.Stats[petName]
	return stats and stats.HP or Config.Pet.MaxHP
end

-- Ngỗng bảo vệ. Patrol = các điểm tuần tra quanh hồ (toạ độ thế giới, tự bám xuống mặt đất).
-- Đổi Patrol nếu bạn tự build map khác.
-- Cân bằng (xem BALANCE trong PARK_REDESIGN.md):
--   đường từ hồ về nhà ≈ 110-130 stud: đi bộ ~8s, chạy nước rút ~4s.
--   ngỗng đuổi 21 stud/s: đi bộ (16) bị đuổi kịp, chạy (30) thoát. Pet chặn được ~20s trước khi kiệt sức.
Config.Guard = {
	Enabled = true,
	Model = "PoliceGoose", -- asset trong CustomModels (rig Motor6D + animation Idle / Walk / Run / Alert / Whistle / Attack / Stunned / Search...)
	Count = 1,
	PatrolSpeed = 10, -- 1 vòng quanh hồ ≈ 430 stud ≈ 43 giây
	ChaseSpeed = 21, -- đi bộ (16) bị bắt kịp, chạy nước rút (30) thoát được
	SightRange = 40, -- thấy người đang KÉO câu trong bán kính này (trong góc nhìn)
	SightAngle = 140, -- tổng góc nhìn (độ)
	ShortSight = 8, -- gần hơn mức này thì thấy cả khi đứng sau lưng (vẫn cần đường nhìn thông)
	SuspiciousTime = 2, -- giây dựng cổ "Honk?" trước khi đuổi. Nhả nút câu kịp trong lúc này thì ngỗng chỉ ra xem rồi bỏ qua
	-- Ngỗng chỉ để ý người "khả nghi": đang KÉO câu -> thấy xa (SightRange); đang mang đồ trong túi -> chỉ thấy rất gần (LootSightRange).
	-- Người đứng im (đã nhả nút, túi rỗng) = người qua đường, ngỗng bỏ qua. Đã bị đuổi (Chase) thì nhả nút cũng không thoát.
	LootSightRange = 10,
	LoseTime = 4, -- giây không thấy người chơi thì bỏ cuộc, ra chỗ cuối cùng thấy
	SearchTime = 3, -- giây đứng tìm ở chỗ cuối cùng / chỗ nghe tiếng động
	AttackRange = 6, -- cách người chơi bao xa thì dừng lại đánh pet
	CatchRange = 4, -- cách người chơi bao xa thì bắt được (khi pet không còn chặn)
	PetDamage = 5, -- HP pet mất mỗi giây khi ngỗng đánh
	ReturnRange = 70, -- người chơi thả phao câu khi ngỗng vừa đi ngang mà còn trong bán kính này (chưa đi xa) -> ngỗng quay lại đuổi
	ReturnGrace = 6, -- ngỗng quay lại được thêm bấy nhiêu giây "coi như còn thấy" để kịp chạy tới (khỏi bỏ cuộc vì khuất tầm nhìn)
	StunEvery = 5, -- cứ mỗi bấy nhiêu giây pet làm ngỗng khựng lại 1 lần
	StunTime = 1.2,
	Patrol = { -- chạy dọc giữa lối gạch quanh hồ (tâm hồ = gốc toạ độ, cách mép nước 4.2 stud), xem ParkBuilder.lua
		Vector3.new(-25, 0, -49.2),
		Vector3.new(25, 0, -49.2),
		Vector3.new(61.5, 0, -41.5),
		Vector3.new(69.2, 0, -15),
		Vector3.new(69.2, 0, 15),
		Vector3.new(61.5, 0, 41.5),
		Vector3.new(25, 0, 49.2),
		Vector3.new(-25, 0, 49.2),
		Vector3.new(-61.5, 0, 41.5),
		Vector3.new(-69.2, 0, 15),
		Vector3.new(-69.2, 0, -15),
		Vector3.new(-61.5, 0, -41.5),
	},
}

-- Animation nhân vật (dạng "rbxassetid://123456"). Để "" = chỉ dùng hoạt ảnh tạm.
-- Cách lấy ID: làm animation bằng Animation Editor -> Publish to Roblox -> copy ID.
Config.Animations = {
	Cast = "", -- vung cần ném câu
	Reel = "", -- kéo cần khi cá cắn
}

-- ===== TOOL SHOP =====
-- Cần câu. Luck: nhân tỉ lệ rương hiếm. Speed: nhân thời gian chờ (nhỏ hơn = nhanh hơn).
-- Model = tên asset trong CustomModels (Assets/Models, rig Motor6D + animation Idle / Cast / Reel / Catch / Miss).
-- Color/Length chỉ dùng cho model tạm khi thiếu asset.
Config.Rods = {
	{ Id = "Basic", Name = "Duckling Rod", Model = "Rod_Starter", Price = 0, Luck = 1, Speed = 1, Color = Color3.fromRGB(230, 200, 110), Length = 7 },
	{ Id = "Catfish", Name = "Catfish Rod", Model = "Rod_Catfish", Price = 150, Luck = 1.25, Speed = 0.92, Color = Color3.fromRGB(110, 130, 150), Length = 7 },
	{ Id = "Turtle", Name = "Turtle Rod", Model = "Rod_Turtle", Price = 600, Luck = 1.8, Speed = 0.8, Color = Color3.fromRGB(60, 120, 200), Length = 8 },
	{ Id = "Fox", Name = "Fox Rod", Model = "Rod_Fox", Price = 2500, Luck = 2.5, Speed = 0.7, Color = Color3.fromRGB(150, 100, 220), Length = 8 },
	{ Id = "Cat", Name = "Lucky Cat Rod", Model = "Rod_Cat", Price = 8000, Luck = 3.3, Speed = 0.58, Color = Color3.fromRGB(255, 190, 40), Length = 9 },
	{ Id = "Dragon", Name = "Rainbow Dragon Rod", Model = "Rod_Dragon", Price = 25000, Luck = 4.5, Speed = 0.45, Color = Color3.fromRGB(240, 240, 250), Length = 10 },
}

-- Máy câu tự động: Prices[i] = giá máy thứ i (số máy tối đa = số phần tử)
-- Tiers[i] = độ hiếm (tên asset AutoFisher_<Tier>) của máy thứ i: máy càng mua sau càng xịn (chỉ khác hình, cùng sản lượng)
Config.AutoFisher = {
	Prices = { 500, 1500, 4000, 10000, 25000 },
	Tiers = { "Common", "Rare", "Epic", "Legendary", "Mythic" },
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
	Eggs = { Reed = 10, Bubble = 40, Crystal = 120, Gold = 400, Dragon = 1500 }, -- Starter không bán được
	Pets = { ["Chef Cat"] = 15, ["Baker Dog"] = 25, ["Muscle Duck"] = 80, ["Magician Cat"] = 250, ["K9 Dog"] = 800, ["Office Dragon"] = 3000 },
}

-- ===== DI CHUYỂN =====
Config.Movement = {
	WalkSpeed = 16, -- tốc độ đi bình thường (mặc định Roblox = 16)
	SprintSpeed = 30, -- tốc độ khi giữ Shift
	SprintFov = 80, -- góc camera khi chạy (bình thường 70) cho cảm giác nhanh
}

-- ===== NHÀ (đồ trong nhà mỗi người chơi, xem House.lua) =====
Config.House = {
	PetBedRange = 10, -- đứng cách ổ pet trong bán kính này thì pet hồi HP nhanh hơn
	PetBedHealMult = 2.5, -- hồi nhanh gấp bấy nhiêu lần (bình thường đầy sau Config.Pet.HealTime giây)
	-- Quà hằng ngày ở hộp thư (ngày tính theo giờ UTC = 7h sáng giờ VN).
	-- TẠM TẮT theo yêu cầu (14/10/2026) – bật lại: Enabled = true
	Daily = { Enabled = false, Coins = 100, Eggs = { Reed = 1 } },
	TrophySlots = 6, -- số chỗ trên kệ trưng bày pet
}

-- ===== TRANG BỊ (mua ở Tool Shop, có là dùng luôn) =====
Config.Gear = {
	RocketSandals = { Name = "Rocket Sandals", Price = 2000, SpeedBonus = 0.10 }, -- +10% tốc đi và chạy
}

-- ===== ÂM THANH (asset âm thanh public trên Creator Store, đã test tải được) =====
Config.Sounds = {
	GooseHonk = "rbxassetid://138096010", -- ngỗng nghi ngờ "Honk?"
	Whistle = "rbxassetid://9118113825", -- ngỗng bắt đầu đuổi
	Splash = "rbxassetid://9117942768", -- "tõm": hụt rương
	Catch = "rbxassetid://93529351909119", -- kéo được rương
	Coins = "rbxassetid://9113849492", -- cất đồ / mở rương máy câu
	Pop = "rbxassetid://109359226723492", -- trứng nở
	PetWarn = "rbxassetid://134699420140804", -- pet yếu / kiệt sức
}

-- ===== DỊCH CHUYỂN =====
-- Bệ dịch chuyển trước nhà -> hồ (tốn tiền), bệ ở hồ / nút My Plot -> về nhà (miễn phí).
-- Về nhà bị CHẶN khi túi có đồ chưa cất hoặc đang bị ngỗng đuổi (phải tự chạy về).
Config.Teleport = {
	LakeCost = 20, -- coins mỗi lần dịch chuyển ra hồ (rương gỗ cho 5-15 coins => phải câu được hơn 1 rương mới lời)
	ShopCost = 10, -- dịch chuyển tới Tool Shop (bị chặn khi túi có đồ / đang bị đuổi)
	HomeCost = 10, -- nút My Plot (bị chặn khi túi có đồ / đang bị đuổi). Bị bắt / hồi sinh / mới vào game vẫn về nhà MIỄN PHÍ
	Cooldown = 3, -- giây giữa 2 lần dịch chuyển
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
