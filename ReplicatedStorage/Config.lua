-- ModuleScript: ReplicatedStorage > Config
-- Toàn bộ số liệu game nằm ở đây. Muốn cân bằng game chỉ cần sửa file này.

local Config = {}

-- Rương: xếp từ thường -> hiếm. Tỉ lệ ra từng loại KHÔNG nằm ở đây mà nằm ở nơi tạo ra rương (Odds của cần câu, của ao, của máy câu):
-- Odds là bảng 5 số, mỗi số ứng với 1 rương theo đúng thứ tự dưới đây (xem Config.RollChest).
-- Model = tên asset trong CustomModels (Assets/Models, từ repo roblox-assets). Asset có sẵn animation Spawn / Idle / Open / Vanish.
-- HoldTime: số giây phải giữ nút để kéo rương lên (nhân với Speed của cần). Rương càng hiếm càng lâu = càng rủi ro.
-- Eggs: mỗi rương ra tối đa 1 quả trứng. Xét lần lượt từ trên xuống (trứng xịn trước): trúng tỉ lệ nào thì ra loại đó.
--   Tier là khoá trong Config.Eggs. Rương càng hiếm càng dễ ra trứng xịn.
Config.Chests = {
	{ Name = "Wooden Chest", Model = "TreasureChest_Common", Coins = { 5, 15 }, HoldTime = 6, Eggs = {
		{ Tier = "Reed", Chance = 0.30 },
	} },
	{ Name = "Blue Chest", Model = "TreasureChest_Rare", Coins = { 20, 60 }, HoldTime = 9, Eggs = {
		{ Tier = "Bubble", Chance = 0.12 },
		{ Tier = "Reed", Chance = 0.55 },
	} },
	{ Name = "Purple Chest", Model = "TreasureChest_Epic", Coins = { 60, 150 }, HoldTime = 12, Eggs = {
		{ Tier = "Crystal", Chance = 0.12 },
		{ Tier = "Bubble", Chance = 0.35 },
		{ Tier = "Reed", Chance = 0.80 },
	} },
	{ Name = "Golden Chest", Model = "TreasureChest_Legendary", Coins = { 150, 300 }, HoldTime = 15, Eggs = {
		{ Tier = "Gold", Chance = 0.15 },
		{ Tier = "Crystal", Chance = 0.35 },
		{ Tier = "Bubble", Chance = 1.00 },
	} },
	{ Name = "Rainbow Chest", Model = "TreasureChest_Mythic", Coins = { 300, 600 }, HoldTime = 18, Eggs = {
		{ Tier = "Dragon", Chance = 0.12 },
		{ Tier = "Gold", Chance = 0.35 },
		{ Tier = "Crystal", Chance = 1.00 },
	} },
}

-- Chọn 1 rương theo bảng tỉ lệ `odds` (5 số ứng với Config.Chests, tổng không cần bằng 100)
function Config.RollChest(odds)
	local total = 0
	for _, weight in ipairs(odds) do
		total += weight
	end
	local roll = math.random() * total
	for i, weight in ipairs(odds) do
		roll -= weight
		if roll <= 0 and weight > 0 then
			return Config.Chests[i]
		end
	end
	return Config.Chests[#Config.Chests]
end

-- % rương từ Purple trở lên trong bảng tỉ lệ (để hiện cho người chơi thấy cần nào ra rương xịn hơn)
function Config.TopChestPercent(odds)
	local total, top = 0, 0
	for i, weight in ipairs(odds) do
		total += weight
		if i >= 3 then
			top += weight
		end
	end
	return top / total * 100
end

-- Tung trứng của 1 rương (chanceMult: perk EggChanceMult của cần). Trả về tier (khoá trong Config.Eggs) hoặc nil (không có trứng)
function Config.RollChestEgg(chest, chanceMult)
	for _, egg in ipairs(chest.Eggs or {}) do
		if math.random() < egg.Chance * (chanceMult or 1) then
			return egg.Tier
		end
	end
	return nil
end

-- Trứng: HatchTime tính bằng giây (trứng vẫn nở khi người chơi offline). Mỗi trứng nở đúng 1 loại pet (asset Egg_* <-> Pet_*).
-- Model = tên asset trong CustomModels. Tên hiện cho người chơi: "<Tier> Egg".
Config.Eggs = {
	-- Reed là trứng cơ bản nhất: người mới được tặng 1 quả (Data.Load)
	Reed = { Model = "Egg_Reed", HatchTime = 10, Pets = { { Name = "Baker Dog", Weight = 1 } } },
	Bubble = { Model = "Egg_Bubble", HatchTime = 20, Pets = { { Name = "Muscle Duck", Weight = 1 } } },
	Crystal = { Model = "Egg_Crystal", HatchTime = 40, Pets = { { Name = "Magician Cat", Weight = 1 } } },
	Gold = { Model = "Egg_Gold", HatchTime = 70, Pets = { { Name = "K9 Dog", Weight = 1 } } },
	Dragon = { Model = "Egg_Dragon", HatchTime = 120, Pets = { { Name = "Office Dragon", Weight = 1 } } },
}

-- Thứ tự hiển thị trứng (từ thường -> hiếm)
Config.EggOrder = { "Reed", "Bubble", "Crystal", "Gold", "Dragon" }

-- ===== CÂU CÁ: GIỮ NÚT ĐỂ KÉO =====
-- Hồ chung ("Lake") là hồ CẤM CÂU: rương kéo được vào túi tạm, phải mang về Stash ở nơi an toàn mới giữ được.
-- Ao riêng trên plot ("Pond"): an toàn, rương vào thẳng tài khoản nhưng kéo chậm hơn và ít may mắn hơn.
Config.Fishing = {
	CastDistance = 15, -- phao rơi cách người bao nhiêu stud về phía trước mặt (phải rơi trúng nước mới câu được)
	MaxMove = 3, -- đang KÉO mà bị đẩy/trượt xa chỗ bắt đầu quá số stud này thì hụt (1.5 quá chặt: trượt nhẹ trên cỏ cũng hụt)
	-- Câu lén: NHẢ nút = tạm dừng, giữ nguyên tiến độ (phao vẫn dưới nước). Giữ lại để kéo tiếp.
	Leash = 12, -- đang tạm dừng mà đi xa chỗ câu quá số stud này thì đứt dây
	PauseTimeout = 40, -- tạm dừng lâu quá số giây này thì rương tuột khỏi lưỡi
	-- Ao riêng: chỉ ra rương gỗ, kéo chậm gấp 5 để luôn kém hồ cấm (ao không ngỗng, không phải chạy về, không tranh rương)
	PondOdds = { 100, 0, 0, 0, 0 },
	PondTimeMult = 5, -- ao riêng: thời gian kéo nhân hệ số này
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

-- Stash (kho nhà): rương cất vào đây KHÔNG tự mở. Kho không giới hạn ô. Nội dung rương (coins / trứng) tung LÚC MỞ.
-- Mở rương phải đứng gần Stash của mình (OpenRange stud) nên không mang rương đi mở ở chỗ khác.
Config.Stash = {
	OpenRange = 40,
}

-- Cướp nhà (ECONOMY_DESIGN mục 7). Cướp cần Chìa vạn năng (mua ở Tool Shop, cất trong profile.Keys, KHÔNG chiếm ô túi).
-- Mỗi lần thử mở một mục tiêu (Stash hoặc một máy câu) tiêu 1 chìa dù mở được hay không; tỉ lệ mở giảm theo cấp khóa cửa của chủ nhà.
Config.Robbery = {
	KeyPrice = 200,
	MaxTries = 4, -- số lần thử chìa tối đa của 1 kẻ cướp trong 1 nhà mỗi lượt vào sân
	TrespassTime = 60, -- giây được ở trong sân người khác trước khi ngỗng nhà rượt
	GrabTime = 3, -- giữ [E] bấy nhiêu giây để lấy 1 món
	ShieldTime = 600, -- giây không bị cướp tiếp sau khi vừa bị cướp
	-- Khóa cửa của chủ nhà (profile.LockLevel = 0..3, phần tử thứ level + 1; dùng Config.LockInfo): tỉ lệ mở của chìa theo cấp, giá mua cấp đó
	Locks = {
		{ Name = "No lock", OpenChance = 0.50, Price = 0 },
		{ Name = "Lock I", OpenChance = 0.40, Price = 3000 },
		{ Name = "Lock II", OpenChance = 0.30, Price = 10000 },
		{ Name = "Lock III", OpenChance = 0.20, Price = 30000 },
	},
}

-- Thông tin khóa cửa cấp `level` (0 = không khóa), nil nếu không có cấp đó
function Config.LockInfo(level)
	return Config.Robbery.Locks[level + 1]
end

-- Tìm rương theo tên hiện cho người chơi (chuỗi do client gửi lên phải khớp đúng). Trả về cấu hình rương và thứ hạng (1 = thường)
function Config.FindChest(name)
	for rank, chest in ipairs(Config.Chests) do
		if chest.Name == name then
			return chest, rank
		end
	end
	return nil
end

-- Pet bảo vệ: chặn ngỗng, mất HP, kiệt sức (0 HP) thì rút về. Hồi HP khi chủ đứng trong vùng an toàn.
Config.Pet = {
	MaxHP = 100, -- HP mặc định nếu pet không có trong Stats
	WarnRatio = 0.3, -- HP dưới 30% máu tối đa thì pet kêu báo nguy
	HealTime = 40, -- giây để hồi từ 0 đến đầy (pet nào cũng vậy)
	-- Độ bền pet = tổng HP pet chịu được trong đời = HP tối đa x hệ số này. Mỗi 1 HP ngỗng đánh mất, độ bền mất 1.
	-- Hồi HP ở nhà KHÔNG hồi độ bền. Hết bền thì pet biến mất, không sửa được. Mọi pet như nhau.
	DurabilityMult = 20,
	-- Chỉ số riêng từng pet: HP càng cao càng chặn ngỗng được lâu (ngỗng đánh Guard.PetDamage HP/giây)
	-- Model = tên asset trong CustomModels (Assets/Models); animation đổi bằng attribute "Anim" (Pets.lua)
	Stats = {
		["Baker Dog"] = { Model = "Pet_DogBaker", HP = 130, Perk = { Name = "Crumbs", Info = "Goose stalls more often", StunEvery = 4 } }, -- ~26s
		["Muscle Duck"] = { Model = "Pet_DuckMuscle", HP = 220, Perk = { Name = "Tank", Info = "Takes 20% less damage", DamageTaken = 0.8 } }, -- ~44s, chịu đòn lâu nhất
		["Magician Cat"] = { Model = "Pet_CatMagician", HP = 170, Perk = { Name = "Hat Trick", Info = "Goose stays stunned longer", StunTime = 2.2 } }, -- ~34s
		["K9 Dog"] = { Model = "Pet_DogK9", HP = 240, Perk = { Name = "Sniff", Info = "Goose stalls more often", StunEvery = 4 } }, -- ~48s
		["Office Dragon"] = { Model = "Pet_DragonOffice", HP = 300, Perk = { Name = "Smoke", Info = "Geese give up twice as fast", LoseTimeMult = 0.5 } }, -- ~60s
	},
}

-- Máu tối đa của 1 loại pet
function Config.PetMaxHP(petName)
	local stats = petName and Config.Pet.Stats[petName]
	return stats and stats.HP or Config.Pet.MaxHP
end

-- Độ bền tối đa của 1 loại pet
function Config.PetDurability(petName)
	return Config.PetMaxHP(petName) * Config.Pet.DurabilityMult
end

-- Giá bán 1 pet (bản ghi { Name, Durability }): giá gốc nhân tỉ lệ độ bền còn lại, pet sắp hỏng bán rẻ
function Config.PetSellPrice(pet)
	local base = Config.SellPrices.Pets[pet.Name] or 0
	return math.floor(base * math.clamp(pet.Durability / Config.PetDurability(pet.Name), 0, 1) + 0.5)
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
	-- Ngỗng NHÀ (mỗi plot có chủ có 1 con): đi vòng tròn bán kính Radius quanh tâm plot, bỏ qua chủ nhà.
	-- Chỉ rượt người "bị truy nã" trong sân nhà đó (đã thử khóa / hết giờ trong sân). Không bám quá Leash stud tính từ tâm plot.
	House = { Radius = 36, Points = 12, PatrolSpeed = 10, Leash = 60 },
	-- Ngỗng ĐỒN CẢNH SÁT: sinh khi có người bị báo động cướp nhà (tối đa MaxPerHeist con đuổi cùng 1 kẻ cướp), xuất phát từ điểm hồi sinh,
	-- hết giờ Lifetime hoặc mất dấu thì biến mất.
	Police = { MaxPerHeist = 3, Lifetime = 45 },
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

-- Sông vòng quanh 8 nhà (ParkBuilder.BuildRiver, hoạt ảnh lá / vịt trôi: River.client.lua). Elip tâm gốc toạ độ, đường giữa dòng.
-- Rx / Rz = bán kính nhà (228 / 212, xem MapBuilder) + 55: mép nước trong cách mép sau plot khoảng 2 stud. Width = bề rộng dòng nước.
Config.River = {
	Rx = 283,
	Rz = 267,
	Width = 16,
	Segments = 96, -- số đoạn Terrain dựng vòng sông (nhiều hơn = tròn hơn, dựng lâu hơn)
	FlowSpeed = 6, -- stud / giây lá và vịt trôi theo dòng (chỉ là hiệu ứng)
}

-- Animation nhân vật (dạng "rbxassetid://123456"). Để "" = chỉ dùng hoạt ảnh tạm.
-- Cách lấy ID: làm animation bằng Animation Editor -> Publish to Roblox -> copy ID.
Config.Animations = {
	Cast = "", -- vung cần ném câu
	Reel = "", -- kéo cần khi cá cắn
}

-- ===== TOOL SHOP =====
-- Cần câu. Odds: tỉ lệ ra 5 loại rương ở HỒ CẤM (Wooden / Blue / Purple / Golden / Rainbow, xem Config.RollChest). Speed: nhân thời gian chờ (nhỏ hơn = nhanh hơn).
-- Mỗi cần cho thu nhập gấp ~1.3-1.6 lần cần trước, giá mỗi bậc ~3-4 lần (xem ECONOMY_DESIGN.md, tools/sim_economy.py).
-- Durability: số rương kéo lên được Ở HỒ CẤM trước khi cần hỏng và BIẾN MẤT (ao không hao, hụt không hao). Không có = không bao giờ hỏng (cần mặc định).
-- Không sửa được: hỏng thì mua lại giá gốc. Cần đang cầm hỏng thì tự quay về cần đầu tiên.
-- Model = tên asset trong CustomModels (Assets/Models, rig Motor6D + animation Idle / Cast / Reel / Catch / Miss).
-- Color/Length chỉ dùng cho model tạm khi thiếu asset.
Config.Rods = {
	{ Id = "Basic", Name = "Duckling Rod", Model = "Rod_Starter", Price = 0, Odds = { 88, 10, 1.8, 0.2, 0.02 }, Speed = 1, Color = Color3.fromRGB(230, 200, 110), Length = 7 },
	{ Id = "Catfish", Name = "Catfish Rod", Model = "Rod_Catfish", Price = 150, Odds = { 78, 18, 3.4, 0.55, 0.05 }, Speed = 0.92, Durability = 50, Perk = { Name = "Quiet Reel", Info = "Noise starts 2s later", NoiseDelay = 2 }, Color = Color3.fromRGB(110, 130, 150), Length = 7 },
	{ Id = "Turtle", Name = "Turtle Rod", Model = "Rod_Turtle", Price = 500, Odds = { 66, 25, 7, 1.7, 0.3 }, Speed = 0.8, Durability = 100, Perk = { Name = "Steady Line", Info = "Line holds longer when paused", Leash = 6, PauseTimeout = 20 }, Color = Color3.fromRGB(60, 120, 200), Length = 8 },
	{ Id = "Fox", Name = "Fox Rod", Model = "Rod_Fox", Price = 1800, Odds = { 52, 30, 13, 4.2, 0.8 }, Speed = 0.7, Durability = 250, Perk = { Name = "Sly Fox", Info = "Geese see you from 25% less far", SightMult = 0.75 }, Color = Color3.fromRGB(150, 100, 220), Length = 8 },
	{ Id = "Cat", Name = "Lucky Cat Rod", Model = "Rod_Cat", Price = 6000, Odds = { 40, 31, 19, 8.2, 1.8 }, Speed = 0.58, Durability = 500, Perk = { Name = "Lucky Paw", Info = "+20% coins from chests", CoinMult = 1.2 }, Color = Color3.fromRGB(255, 190, 40), Length = 9 },
	{ Id = "Dragon", Name = "Rainbow Dragon Rod", Model = "Rod_Dragon", Price = 18000, Odds = { 26, 28, 28, 14, 4 }, Speed = 0.45, Durability = 1000, Perk = { Name = "Hoard", Info = "+10% egg chance from chests", EggChanceMult = 1.1 }, Color = Color3.fromRGB(240, 240, 250), Length = 10 },
}

-- Báo "sắp hỏng" (cần câu, pet) khi độ bền còn bằng bấy nhiêu phần của độ bền tối đa
Config.DurabilityWarnRatio = 0.2

-- Màu thanh độ bền (HUD, Bag, bảng trên máy câu): xanh dương, cam khi dưới nửa, đỏ khi sắp hỏng
function Config.DurabilityColor(ratio)
	if ratio <= Config.DurabilityWarnRatio then
		return Color3.fromRGB(255, 90, 90)
	end
	return ratio <= 0.5 and Color3.fromRGB(255, 150, 50) or Color3.fromRGB(60, 150, 255)
end

-- Máy câu tự động (xem ECONOMY_DESIGN.md mục 4, tools/sim_economy.py).
-- Ổ máy (PedestalPrices[i] = giá mở ổ thứ i, ổ 1 miễn phí) mở một lần, không hỏng. Số ổ tối đa = số phần tử.
-- Máy là món tiêu hao: MUA THẲNG tier muốn vào ổ trống, hết độ bền thì biến mất (ổ còn lại), không sửa được.
-- Nâng tier tại chỗ = trả chênh lệch giá, độ bền về đầy của tier mới.
-- Mỗi tier: Name = tên asset AutoFisher_<Name>; Price = giá mua thẳng; Interval = giây ra 1 rương; Capacity = kho tối đa
--   (đầy sau ~30 phút, đầy thì ngừng kể cả khi offline); Durability = số rương làm ra được trước khi hỏng;
--   Odds = tỉ lệ ra 5 rương (Config.RollChest). Máy chỉ ra tối đa rương Purple: Golden và Rainbow chỉ có từ câu ở hồ.
Config.AutoFisher = {
	PedestalPrices = { 0, 400, 1200, 3000, 7000 },
	Tiers = {
		{ Name = "Common", Price = 300, Interval = 180, Capacity = 10, Durability = 120, Odds = { 100, 0, 0, 0, 0 } },
		{ Name = "Rare", Price = 1000, Interval = 160, Capacity = 11, Durability = 200, Odds = { 70, 30, 0, 0, 0 } },
		{ Name = "Epic", Price = 3500, Interval = 140, Capacity = 13, Durability = 450, Odds = { 55, 35, 10, 0, 0 } },
		{ Name = "Legendary", Price = 10000, Interval = 120, Capacity = 15, Durability = 1000, Odds = { 45, 38, 17, 0, 0 } },
		{ Name = "Mythic", Price = 30000, Interval = 100, Capacity = 18, Durability = 2500, Odds = { 35, 40, 25, 0, 0 } },
	},
}

-- Máy ấp trứng trên plot
Config.Incubators = {
	StartSlots = 1,
	MaxSlots = 4,
	Prices = { [2] = 300, [3] = 1500, [4] = 6000 }, -- giá mở máy thứ 2, 3, 4
	-- Hoạt ảnh nở (IncubatorAnimator.client.lua): tổng Duration giây; BurstAt giây thứ mấy vòm kính vỡ và pet bật ra
	HatchAnim = { Duration = 5, BurstAt = 2.4 },
}

-- ===== MARKET =====
Config.SellPrices = {
	Eggs = { Reed = 10, Bubble = 40, Crystal = 120, Gold = 400, Dragon = 1500 },
	Pets = { ["Baker Dog"] = 25, ["Muscle Duck"] = 80, ["Magician Cat"] = 250, ["K9 Dog"] = 800, ["Office Dragon"] = 3000 },
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

-- Chọn ngẫu nhiên 1 phần tử theo trọng số (Weight)
function Config.WeightedRoll(list)
	local total = 0
	for _, item in ipairs(list) do
		total += item.Weight
	end
	local roll = math.random() * total
	for _, item in ipairs(list) do
		roll -= item.Weight
		if roll <= 0 then
			return item
		end
	end
	return list[#list]
end

-- Số rương đang có trong 1 máy câu tại thời điểm `now` (os.time)
-- entry = { Tier = số thứ tự trong Config.AutoFisher.Tiers, Durability = số rương còn làm ra được,
--           Last = thời điểm tính gần nhất, Stored = số rương đã tích }
-- Kho tối đa = Capacity của tier, và không quá độ bền còn lại (máy không làm ra nhiều hơn số rương nó còn bền)
function Config.AutoFisherStored(entry, now)
	local tier = Config.AutoFisher.Tiers[entry.Tier]
	local limit = math.min(tier.Capacity, entry.Durability)
	local ticks = math.max(math.floor((now - entry.Last) / tier.Interval), 0)
	local stored = math.min(limit, entry.Stored + ticks)
	local last = entry.Last + ticks * tier.Interval
	if stored >= limit then
		last = now -- đầy kho: ngừng đếm
	end
	return stored, last
end

return Config
