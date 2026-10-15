-- ModuleScript: ServerScriptService > Modules > Loadout
-- Gộp perk của cần câu đang cầm + pet đang đi theo thành MỘT bảng chỉ số, để Fishing / Guard / Pets chỉ cần hỏi Loadout.Get(player)
-- (không viết script riêng cho từng perk). Perk khai báo trong Config.Rods[].Perk và Config.Pet.Stats[].Perk (xem ECONOMY_DESIGN mục 8).
-- Chỉ số: NoiseDelay, Leash, PauseTimeout (cộng thêm), SightMult, CoinMult, EggChanceMult, DamageTaken, LoseTimeMult (nhân),
-- StunEvery (lấy nhỏ nhất), StunTime (lấy lớn nhất). Không có perk thì trả về mặc định (không đổi gì).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local Data = require(script.Parent.Data)

local Loadout = {}

local ADD = { "NoiseDelay", "Leash", "PauseTimeout" }
local MULT = { "SightMult", "CoinMult", "EggChanceMult", "DamageTaken", "LoseTimeMult" }

local function defaults()
	return {
		NoiseDelay = 0,
		Leash = 0,
		PauseTimeout = 0,
		SightMult = 1,
		CoinMult = 1,
		EggChanceMult = 1,
		DamageTaken = 1,
		LoseTimeMult = 1,
		StunEvery = Config.Guard.StunEvery,
		StunTime = Config.Guard.StunTime,
	}
end

local function apply(stats, perk)
	if not perk then
		return
	end
	for _, key in ipairs(ADD) do
		stats[key] += perk[key] or 0
	end
	for _, key in ipairs(MULT) do
		stats[key] *= perk[key] or 1
	end
	stats.StunEvery = math.min(stats.StunEvery, perk.StunEvery or math.huge)
	stats.StunTime = math.max(stats.StunTime, perk.StunTime or 0)
end

function Loadout.Get(player)
	local stats = defaults()
	local profile = Data.Get(player)
	if not profile then
		return stats
	end
	local rod = Config.GetRod(profile.EquippedRod)
	apply(stats, rod and rod.Perk)
	local pet = profile.EquippedPet and Data.FindPet(profile, profile.EquippedPet)
	local petStats = pet and Config.Pet.Stats[pet.Name]
	apply(stats, petStats and petStats.Perk)
	return stats
end

return Loadout
