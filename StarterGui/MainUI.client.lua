-- LocalScript: StarterGui > MainUI
-- Giao diện tạm dựng bằng code: HUD (coins, nút), thông báo, và các bảng Shop / Market / Hatch / Bag.
-- Dữ liệu người chơi được server gửi xuống qua RemoteEvent "Sync".
-- Sau này có thể tự vẽ UI trong Studio cho đẹp, chỉ cần giữ cách gọi remotes như dưới.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local COLORS = {
	Panel = Color3.fromRGB(30, 32, 45),
	Row = Color3.fromRGB(48, 52, 70),
	Green = Color3.fromRGB(60, 170, 90),
	Blue = Color3.fromRGB(60, 120, 220),
	Red = Color3.fromRGB(210, 70, 60),
	Grey = Color3.fromRGB(100, 100, 110),
	Gold = Color3.fromRGB(255, 210, 80),
}

local profile = nil -- bản sao dữ liệu mới nhất từ server
local current = nil -- bảng đang mở { Kind, Data }

-- ===== Tiện ích =====
local function make(className, props, parent)
	local inst = Instance.new(className)
	for key, value in pairs(props) do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end

local function corner(inst, radius)
	make("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, inst)
end

local function button(parent, text, color, size, position, onClick)
	local b = make("TextButton", {
		Size = size,
		Position = position,
		BackgroundColor3 = color,
		Text = text,
		TextScaled = true,
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.new(1, 1, 1),
	}, parent)
	corner(b)
	make("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
	}, b)
	if onClick then
		b.MouseButton1Click:Connect(onClick)
	end
	return b
end

local function commas(n)
	local s = tostring(math.floor(n))
	local count
	repeat
		s, count = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
	until count == 0
	return s
end

local function sortedTiers()
	local tiers = {}
	for tier in pairs(Config.Eggs) do
		table.insert(tiers, tier)
	end
	table.sort(tiers)
	return tiers
end

-- ===== Khung chính =====
local gui = make("ScreenGui", { Name = "MainUI", ResetOnSpawn = false }, player:WaitForChild("PlayerGui"))

local status = make("TextLabel", {
	Size = UDim2.new(0.6, 0, 0, 40),
	Position = UDim2.new(0.2, 0, 0, 20),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.4,
	TextScaled = true,
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.new(1, 1, 1),
	Text = "Welcome! Go to the water and press Cast to fish.",
}, gui)
corner(status)

local function toast(message)
	status.Text = message
end

-- Gửi yêu cầu lên server, hiện câu trả lời. Trả về true nếu thành công.
local function request(action, ...)
	local okCall, ok, message = pcall(remotes.Action.InvokeServer, remotes.Action, action, ...)
	if not okCall then
		toast("Something went wrong, try again.")
		return false
	end
	if typeof(message) == "string" then
		toast(message)
	end
	return ok == true
end

-- ===== HUD =====
local coinsLabel = make("TextLabel", {
	Size = UDim2.fromOffset(220, 46),
	Position = UDim2.fromOffset(20, 80),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.4,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
	TextColor3 = COLORS.Gold,
	Text = "Coins: 0",
}, gui)
corner(coinsLabel)

button(gui, "Cast", COLORS.Blue, UDim2.fromOffset(180, 60), UDim2.new(0.5, -90, 1, -90), function()
	-- Tự cầm cần câu lên nếu đang để trong túi
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local rod = player.Backpack:FindFirstChild("FishingRod")
	if humanoid and rod then
		humanoid:EquipTool(rod)
	end
	remotes.Cast:FireServer()
end)

-- ===== Bảng (panel) =====
local panel = make("Frame", {
	Size = UDim2.fromOffset(460, 480),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = COLORS.Panel,
	Visible = false,
}, gui)
corner(panel, 12)

local title = make("TextLabel", {
	Size = UDim2.new(1, -80, 0, 40),
	Position = UDim2.fromOffset(16, 10),
	BackgroundTransparency = 1,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.GothamBlack,
	TextColor3 = Color3.new(1, 1, 1),
}, panel)

local list = make("ScrollingFrame", {
	Size = UDim2.new(1, -24, 1, -72),
	Position = UDim2.fromOffset(12, 60),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, panel)
make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)

local rowCount = 0

local function header(text)
	rowCount += 1
	make("TextLabel", {
		Size = UDim2.new(1, -8, 0, 28),
		BackgroundTransparency = 1,
		LayoutOrder = rowCount,
		Text = text,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBlack,
		TextColor3 = COLORS.Gold,
	}, list)
end

-- buttons: { { Text, Color, OnClick, Disabled } }
local function addRow(text, buttons)
	rowCount += 1
	local row = make("Frame", {
		Size = UDim2.new(1, -8, 0, 58),
		BackgroundColor3 = COLORS.Row,
		LayoutOrder = rowCount,
	}, list)
	corner(row)
	local width = 92
	make("TextLabel", {
		Size = UDim2.new(1, -(#buttons * (width + 6)) - 18, 1, -8),
		Position = UDim2.fromOffset(10, 4),
		BackgroundTransparency = 1,
		RichText = true,
		Text = text,
		TextSize = 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Gotham,
		TextColor3 = Color3.new(1, 1, 1),
	}, row)
	for i, spec in ipairs(buttons) do
		local b = button(row, spec.Text, spec.Disabled and COLORS.Grey or spec.Color, UDim2.fromOffset(width, 38), UDim2.new(1, -i * (width + 6), 0.5, -19), not spec.Disabled and spec.OnClick or nil)
		b.AutoButtonColor = not spec.Disabled
	end
end

local function countPets()
	local counts, names = {}, {}
	for _, name in ipairs(profile.Pets) do
		if not counts[name] then
			counts[name] = 0
			table.insert(names, name)
		end
		counts[name] += 1
	end
	table.sort(names, function(a, b)
		return (Config.SellPrices.Pets[a] or 0) > (Config.SellPrices.Pets[b] or 0)
	end)
	return counts, names
end

local function closePanel()
	panel.Visible = false
	current = nil
end

button(panel, "X", COLORS.Red, UDim2.fromOffset(40, 40), UDim2.new(1, -52, 0, 10), closePanel)

-- ===== Nội dung từng bảng =====
local renderers = {}

renderers.Shop = function()
	header("Fishing Rods")
	for _, rod in ipairs(Config.Rods) do
		local text = ("<b>%s</b>\nLuck x%.1f   Speed x%.1f"):format(rod.Name, rod.Luck, 1 / rod.Speed)
		local spec
		if profile.EquippedRod == rod.Id then
			spec = { Text = "Equipped", Disabled = true }
		elseif profile.Rods[rod.Id] then
			spec = { Text = "Equip", Color = COLORS.Blue, OnClick = function()
				request("EquipRod", rod.Id)
			end }
		else
			spec = { Text = commas(rod.Price), Color = COLORS.Green, OnClick = function()
				request("BuyRod", rod.Id)
			end }
		end
		addRow(text, { spec })
	end

	header("Plot Upgrades")
	local fisherCfg = Config.AutoFisher
	local owned, nextPrice = 0, nil
	for i, price in ipairs(fisherCfg.Prices) do
		if profile.AutoFishers[tostring(i)] then
			owned += 1
		elseif not nextPrice then
			nextPrice = price
		end
	end
	addRow(
		("<b>Auto-Fisher</b> (%d/%d)\n1 chest every %ds, holds %d"):format(owned, #fisherCfg.Prices, fisherCfg.Interval, fisherCfg.Capacity),
		{ nextPrice and { Text = commas(nextPrice), Color = COLORS.Green, OnClick = function()
			request("BuyAutoFisher")
		end } or { Text = "Max", Disabled = true } }
	)

	local slots, maxSlots = profile.IncubatorSlots, Config.Incubators.MaxSlots
	local price = slots < maxSlots and (Config.Incubators.Prices[slots + 1] or 0)
	addRow(
		("<b>Incubator</b> (%d/%d)\nHatch more eggs at the same time"):format(slots, maxSlots),
		{ price and { Text = commas(price), Color = COLORS.Green, OnClick = function()
			request("BuyIncubator")
		end } or { Text = "Max", Disabled = true } }
	)
end

renderers.Market = function()
	header("Eggs")
	local any = false
	for _, tier in ipairs(sortedTiers()) do
		local count = profile.Eggs[tier] or 0
		if count > 0 then
			any = true
			addRow(("<b>%s Egg</b> x%d\n%s coins each"):format(tier, count, commas(Config.SellPrices.Eggs[tier] or 0)), {
				{ Text = "Sell All", Color = COLORS.Red, OnClick = function()
					request("SellEgg", tier, true)
				end },
				{ Text = "Sell 1", Color = COLORS.Green, OnClick = function()
					request("SellEgg", tier, false)
				end },
			})
		end
	end
	if not any then
		addRow("No eggs to sell.", {})
	end

	header("Pets")
	local counts, names = countPets()
	for _, name in ipairs(names) do
		addRow(("<b>%s</b> x%d\n%s coins each"):format(name, counts[name], commas(Config.SellPrices.Pets[name] or 0)), {
			{ Text = "Sell All", Color = COLORS.Red, OnClick = function()
				request("SellPet", name, true)
			end },
			{ Text = "Sell 1", Color = COLORS.Green, OnClick = function()
				request("SellPet", name, false)
			end },
		})
	end
	if #names == 0 then
		addRow("No pets to sell.", {})
	end
end

renderers.Hatch = function(data)
	header(("Incubator #%d: choose an egg"):format(data.Slot))
	local any = false
	for _, tier in ipairs(sortedTiers()) do
		local count = profile.Eggs[tier] or 0
		if count > 0 then
			any = true
			addRow(("<b>%s Egg</b> x%d\nHatch time: %ds"):format(tier, count, Config.Eggs[tier].HatchTime), {
				{ Text = "Hatch", Color = COLORS.Green, OnClick = function()
					if request("StartHatch", data.Slot, tier) then
						closePanel()
					end
				end },
			})
		end
	end
	if not any then
		addRow("You have no eggs. Go fishing to find some!", {})
	end
end

renderers.Bag = function()
	header(("Coins: %s"):format(commas(profile.Coins)))
	header("Eggs")
	for _, tier in ipairs(sortedTiers()) do
		addRow(("<b>%s Egg</b> x%d"):format(tier, profile.Eggs[tier] or 0), {})
	end
	header("Pets")
	local counts, names = countPets()
	for _, name in ipairs(names) do
		addRow(("<b>%s</b> x%d"):format(name, counts[name]), {})
	end
	if #names == 0 then
		addRow("No pets yet. Hatch eggs at your plot!", {})
	end
	header("Rods")
	for _, rod in ipairs(Config.Rods) do
		if profile.Rods[rod.Id] then
			addRow(("<b>%s</b>%s"):format(rod.Name, profile.EquippedRod == rod.Id and "  (equipped)" or ""), {})
		end
	end
end

local TITLES = { Shop = "Tool Shop", Market = "Market", Hatch = "Hatchery", Bag = "My Bag" }

local function render()
	for _, child in ipairs(list:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	rowCount = 0
	if current and profile then
		renderers[current.Kind](current.Data)
	end
end

local function openPanel(kind, data)
	if not renderers[kind] then
		return
	end
	current = { Kind = kind, Data = data }
	title.Text = TITLES[kind]
	panel.Visible = true
	render()
end

-- Nút bên phải màn hình
local sideButtons = {
	{ "My Plot", COLORS.Green, function()
		request("Teleport", "Plot")
	end },
	{ "Plaza", COLORS.Blue, function()
		request("Teleport", "Plaza")
	end },
	{ "Bag", COLORS.Grey, function()
		if current and current.Kind == "Bag" then
			closePanel()
		else
			openPanel("Bag")
		end
	end },
}
for i, spec in ipairs(sideButtons) do
	button(gui, spec[1], spec[2], UDim2.fromOffset(150, 50), UDim2.new(1, -170, 0.35, (i - 1) * 60), spec[3])
end

-- ===== Nhận dữ liệu từ server =====
local function onSync(data)
	profile = data
	coinsLabel.Text = "Coins: " .. commas(profile.Coins)
	if current then
		render()
	end
end

remotes.Sync.OnClientEvent:Connect(onSync)
remotes.Notify.OnClientEvent:Connect(toast)
remotes.Effect.OnClientEvent:Connect(function(kind, data)
	if kind == "OpenPanel" then
		openPanel(data.Panel, data)
	end
end)

-- Xin dữ liệu lần đầu (đợi server tải xong)
task.spawn(function()
	while not profile do
		local okCall, ok, data = pcall(remotes.Action.InvokeServer, remotes.Action, "GetData")
		if okCall and ok and data and not profile then
			onSync(data)
		end
		if not profile then
			task.wait(1)
		end
	end
end)
