-- ModuleScript: ServerScriptService > Modules > Remote
-- Gửi tin từ server xuống client cho gọn.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("Remotes")

local Remote = {}
Remote.Folder = remotes

-- Dòng chữ thông báo trên màn hình
function Remote.Notify(player, message)
	remotes.Notify:FireClient(player, message)
end

-- Báo client chạy hoạt ảnh / mở bảng UI
function Remote.Effect(player, kind, data)
	remotes.Effect:FireClient(player, kind, data)
end

-- Như Effect nhưng gửi cho MỌI người chơi (để hàng xóm cũng thấy hoạt ảnh ở nhà người khác)
function Remote.EffectAll(kind, data)
	remotes.Effect:FireAllClients(kind, data)
end

return Remote
