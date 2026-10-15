-- ModuleScript: ServerScriptService > Modules > Tutorial
-- Hướng dẫn người mới 3 bước, tiến độ lưu trong profile.Tutorial (Data.Load đặt 1 cho người mới, 99 cho người cũ):
--   1. Hatch   ấp Reed Egg được tặng ở chuồng ấp sau nhà (Hatchery.lua gọi khi nở pet)
--   2. Lake    kéo được 1 rương ở hồ cấm        (Fishing.lua gọi khi câu xong ở hồ)
--   3. Deposit cất đồ vào Stash ở sân trước       (Bag.lua gọi khi cất thành công)
-- Chữ hướng dẫn hiện trên màn hình nằm ở MainUI.client.lua (đọc profile.Tutorial từ Sync).

local Data = require(script.Parent.Data)
local Remote = require(script.Parent.Remote)

local Tutorial = {}

local STEP_OF = { Hatch = 1, Lake = 2, Deposit = 3 }
Tutorial.LastStep = 3

-- Báo 1 sự kiện đã xảy ra; nếu đúng là bước đang chờ thì sang bước tiếp
function Tutorial.Complete(player, event)
	local profile = Data.Get(player)
	if not profile or STEP_OF[event] ~= profile.Tutorial then
		return
	end
	profile.Tutorial += 1
	if profile.Tutorial > Tutorial.LastStep then
		profile.Tutorial = 99
		Remote.Notify(player, "Tutorial complete! Now upgrade your rod and bag at the Tool Shop.")
	end
	Data.Update(player)
end

return Tutorial
