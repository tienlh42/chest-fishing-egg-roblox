-- ModuleScript: ServerScriptService > Modules > Hatchery
-- Ấp trứng tại máy ấp trên plot. Lưu thời điểm bắt đầu (os.time) nên trứng vẫn nở khi offline.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)
local Remote = require(script.Parent.Remote)
local Tutorial = require(script.Parent.Tutorial)

local Hatchery = {}

local animating = {} -- [player] = { [slot] = true } bệ đang chạy hoạt ảnh nở (chặn bấm lại / ấp mới trong lúc đó)

-- Người chơi bấm [E] ở máy ấp số `slot`
function Hatchery.OnPrompt(player, slot)
	local profile = Data.Get(player)
	if not profile or slot > profile.IncubatorSlots then
		return
	end
	local key = tostring(slot)
	local entry = profile.Incubators[key]
	if animating[player] and animating[player][slot] then
		return -- đang nở
	end

	-- Máy trống -> mở bảng chọn trứng
	if not entry then
		Remote.Effect(player, "OpenPanel", { Panel = "Hatch", Slot = slot })
		return
	end

	local egg = Config.Eggs[entry.Tier]
	local left = egg and entry.Start + egg.HatchTime - os.time() or 0
	if left > 0 then
		Remote.Notify(player, ("Still hatching... %ds left"):format(left))
		return
	end

	-- Nở xong -> nhận pet NGAY (dữ liệu chốt luôn), còn hoạt ảnh nở / vỡ vòm chạy ở client (IncubatorAnimator) trong HatchAnim.Duration giây
	profile.Incubators[key] = nil
	local petName = egg and Config.WeightedRoll(egg.Pets).Name
	if petName then
		Data.NewPet(profile, petName)
	end
	Data.Update(player)

	local anim = Config.Incubators.HatchAnim
	local model, eggModel = Plots.IncubatorParts(player, slot)
	if not model then
		Plots.Refresh(player)
	else
		animating[player] = animating[player] or {}
		animating[player][slot] = true
		model:SetAttribute("State", "Hatching")
		Remote.EffectAll("IncubatorHatch", { Model = model, Egg = eggModel, Tier = entry.Tier, Pet = petName, BurstAt = anim.BurstAt, Duration = anim.Duration })
	end

	-- Pet bật ra đúng lúc vòm kính vỡ
	task.delay(model and anim.BurstAt or 0, function()
		if petName and player.Parent then
			Remote.Effect(player, "Hatched", { Pet = petName, Position = Plots.SlotPosition(player, "IncubatorSlot" .. slot) })
			Remote.Notify(player, ("You hatched a %s!"):format(petName))
			Tutorial.Complete(player, "Hatch")
		end
	end)
	-- Hết hoạt ảnh: dựng lại máy (trống, vòm mới)
	if model then
		task.delay(anim.Duration, function()
			if animating[player] then
				animating[player][slot] = nil
			end
			if player.Parent then
				Plots.Refresh(player)
			end
		end)
	end
end

function Hatchery.RemovePlayer(player)
	animating[player] = nil
end

-- Client chọn trứng trong bảng Hatch
function Hatchery.StartHatch(player, slot, tier)
	local profile = Data.Get(player)
	-- LUÔN kiểm tra dữ liệu client gửi lên (chống hack)
	if typeof(slot) ~= "number" or slot % 1 ~= 0 or slot < 1 or slot > profile.IncubatorSlots then
		return false, "Invalid incubator."
	end
	if typeof(tier) ~= "string" or not Config.Eggs[tier] then
		return false, "Invalid egg."
	end
	local key = tostring(slot)
	if profile.Incubators[key] or (animating[player] and animating[player][slot]) then
		return false, "This incubator is busy."
	end
	if (profile.Eggs[tier] or 0) < 1 then
		return false, ("You don't have any %s Eggs."):format(tier)
	end

	profile.Eggs[tier] -= 1
	profile.Incubators[key] = { Tier = tier, Start = os.time() }
	Data.Update(player)
	Plots.Refresh(player)
	return true, ("Hatching a %s Egg... (%ds)"):format(tier, Config.Eggs[tier].HatchTime)
end

return Hatchery
