-- ModuleScript: ServerScriptService > Modules > House
-- Đồ chức năng trong nhà mỗi người chơi (HouseBuilder dựng model, file này gắn logic):
--   PetBed      ổ pet: chủ đứng gần thì pet hồi HP nhanh hơn (Pets.lua hỏi House.HealMultiplier)
--   TrophyShelf kệ trưng bày: tự đặt model các loại pet đã có, hiếm nhất trước
--   Sign        hộp thư: quà hằng ngày (Config.House.Daily) – ĐANG TẮT (Daily.Enabled = false)
-- (Nâng cấp túi đã chuyển sang Tool Shop: Shop.BuyBagUpgrade)
-- Nút [E] chỉ chủ nhà thấy/dùng được (Plots.MakeOwnerPrompt). Tạo khi cấp plot, xoá khi thu hồi.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Config)
local Models = require(ReplicatedStorage.Models)
local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)
local Remote = require(script.Parent.Remote)

local cfg = Config.House
local DAY = 86400

local House = {}

local prompts = {} -- [player] = { Daily = ProximityPrompt }
local shownTrophies = {} -- [player] = "Cat|Dog" danh sách đang trưng, để khỏi dựng lại khi không đổi

local function find(plot, name)
	return plot and plot:FindFirstChild(name, true)
end

local function today()
	return os.time() // DAY
end

-- ===== 1. Ổ pet =====
-- Hệ số hồi HP pet: đứng gần ổ pet nhà mình thì PetBedHealMult, không thì 1
function House.HealMultiplier(player)
	local bed = find(Plots.Get(player), "PetBed")
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if bed and hrp and (hrp.Position - bed.Position).Magnitude <= cfg.PetBedRange then
		return cfg.PetBedHealMult
	end
	return 1
end

-- ===== 4. Kệ trưng bày =====
-- Các loại pet đã có (mỗi loại 1 lần), hiếm nhất (giá bán cao nhất) trước
local function petKinds(profile)
	local seen, kinds = {}, {}
	for _, pet in ipairs(profile.Pets) do
		local name = pet.Name
		if not seen[name] then
			seen[name] = true
			table.insert(kinds, name)
		end
	end
	table.sort(kinds, function(a, b)
		return (Config.SellPrices.Pets[a] or 0) > (Config.SellPrices.Pets[b] or 0)
	end)
	return kinds
end

local function totalPetKinds()
	local all = {}
	for _, egg in pairs(Config.Eggs) do
		for _, pet in ipairs(egg.Pets) do
			all[pet.Name] = true
		end
	end
	local n = 0
	for _ in pairs(all) do
		n += 1
	end
	return n
end

-- Đặt 1 model nhỏ đứng lên mặt trên của chỗ trưng
local function placeTrophy(folder, slot, petName)
	local model = Models.Anchor(Models.Get(petName))
	local tag = model:FindFirstChild("NameTag", true)
	if tag then
		tag.StudsOffset = Vector3.new(0, 1.4, 0)
		tag.Size = UDim2.fromScale(2.5, 0.6)
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
		end
	end
	-- thu nhỏ cho vừa tầng kệ (cao ~1.8 stud)
	local _, size = model:GetBoundingBox()
	if size.Y > 0 then
		model:ScaleTo(model:GetScale() * 1.8 / size.Y)
	end
	model:PivotTo(slot.CFrame)
	local box, boxSize = model:GetBoundingBox()
	local bottom = box.Position.Y - boxSize.Y / 2
	model:PivotTo(model:GetPivot() + Vector3.new(0, slot.Position.Y + slot.Size.Y / 2 - bottom, 0))
	model.Parent = folder
end

local function refreshTrophies(player)
	local plot = Plots.Get(player)
	local profile = Data.Get(player)
	local shelf = find(plot, "TrophyShelf")
	if not (plot and profile and shelf) then
		return
	end
	local kinds = petKinds(profile)
	local key = table.concat(kinds, "|")
	if shownTrophies[player] == key then
		return
	end
	shownTrophies[player] = key

	local folder = plot:FindFirstChild("Trophies")
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "Trophies"
	for i = 1, math.min(#kinds, cfg.TrophySlots) do
		local slot = find(plot, "TrophySlot" .. i)
		if slot then
			placeTrophy(folder, slot, kinds[i])
		end
	end
	folder.Parent = plot

	local gui = shelf:FindFirstChild("TrophyLabel")
	if not gui then
		gui = Instance.new("BillboardGui")
		gui.Name = "TrophyLabel"
		gui.Size = UDim2.fromScale(6, 1.2)
		gui.StudsOffset = Vector3.new(0, 4, 0)
		gui.MaxDistance = 40
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Font = Enum.Font.GothamBlack
		label.TextColor3 = Color3.fromRGB(255, 225, 120)
		label.TextStrokeTransparency = 0
		label.Parent = gui
		gui.Parent = shelf
	end
	gui.TextLabel.Text = ("PET COLLECTION %d/%d"):format(#kinds, totalPetKinds())
end

-- ===== 6. Quà hằng ngày =====
function House.ClaimDaily(player)
	local profile = Data.Get(player)
	if not profile or not cfg.Daily.Enabled then
		return
	end
	if (profile.LastDaily or 0) >= today() then
		local left = (today() + 1) * DAY - os.time()
		Remote.Notify(player, ("Already claimed! Next gift in %dh %dm."):format(left // 3600, left % 3600 // 60))
		return
	end
	profile.LastDaily = today()
	profile.Coins += cfg.Daily.Coins
	local parts = { ("+%d coins"):format(cfg.Daily.Coins) }
	for tier, count in pairs(cfg.Daily.Eggs) do
		profile.Eggs[tier] = (profile.Eggs[tier] or 0) + count
		table.insert(parts, ("+%d %s Egg"):format(count, tier))
	end
	Data.Update(player)
	Remote.Notify(player, "Daily gift: " .. table.concat(parts, ", ") .. "!")
end

-- ===== Chữ trên nút [E] theo dữ liệu hiện tại =====
local function refreshPrompts(player)
	local p = prompts[player]
	local profile = Data.Get(player)
	if not (p and profile) then
		return
	end
	if p.Daily then
		local claimed = (profile.LastDaily or 0) >= today()
		p.Daily.ActionText = claimed and "Gift claimed (come back tomorrow)" or "Open Daily Gift"
	end
end

function House.Refresh(player)
	refreshPrompts(player)
	refreshTrophies(player)
end

-- ===== Cấp / thu hồi nhà (Plots gọi) =====
function House.OnAssign(player, plot)
	prompts[player] = {}
	local mailbox = find(plot, "Mailbox")
	if mailbox and cfg.Daily.Enabled then
		prompts[player].Daily = Plots.MakeOwnerPrompt(plot, mailbox, "Open Daily Gift", "Mailbox", House.ClaimDaily)
		prompts[player].Daily.Name = "HousePrompt"
	end
	shownTrophies[player] = nil
	House.Refresh(player)
end

function House.OnRelease(player, plot)
	for _, prompt in pairs(prompts[player] or {}) do
		prompt:Destroy()
	end
	prompts[player] = nil
	shownTrophies[player] = nil
	local folder = plot:FindFirstChild("Trophies")
	if folder then
		folder:Destroy()
	end
	local label = find(plot, "TrophyLabel")
	if label then
		label:Destroy()
	end
end

-- Profile đổi (mua, nở pet, bán pet...) -> cập nhật nút + kệ
Data.Updated:Connect(House.Refresh)

-- Qua ngày mới thì nút quà đổi chữ lại (kiểm tra mỗi phút)
task.spawn(function()
	while true do
		task.wait(60)
		for player in pairs(prompts) do
			refreshPrompts(player)
		end
	end
end)

return House
