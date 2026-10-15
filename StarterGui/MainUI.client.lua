-- LocalScript: StarterGui > MainUI
-- Giao diện tạm dựng bằng code: HUD (coins, nút), thông báo, và các bảng Shop / Market / Hatch / Bag.
-- Dữ liệu người chơi được server gửi xuống qua RemoteEvent "Sync".
-- Sau này có thể tự vẽ UI trong Studio cho đẹp, chỉ cần giữ cách gọi remotes như dưới.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Models = require(ReplicatedStorage:WaitForChild("Models"))

-- Theme "Sunny Park + Egg Pop": màu rực, viền tối dày, nút phồng như kẹo.
-- Quy ước màu: Gold = tiền, Green = mua/xác nhận/về nhà, Blue = hành động chính, Red = bán/đóng/nguy hiểm, Grey = không bấm được.
local COLORS = {
	Panel = Color3.fromRGB(62, 52, 128),
	Row = Color3.fromRGB(86, 76, 162),
	Outline = Color3.fromRGB(35, 28, 80),
	Green = Color3.fromRGB(70, 200, 100),
	Blue = Color3.fromRGB(60, 150, 255),
	Orange = Color3.fromRGB(255, 150, 50),
	Red = Color3.fromRGB(255, 90, 90),
	Grey = Color3.fromRGB(130, 130, 150),
	Gold = Color3.fromRGB(255, 210, 60),
	Pink = Color3.fromRGB(255, 130, 190),
}

local IS_TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local BOUNCE = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local profile = nil -- bản sao dữ liệu mới nhất từ server
local current = nil -- bảng đang mở { Kind, Data }

-- ===== Tiện ích =====
local function make(className, props, parent)
	local inst = Instance.new(className)
	if className == "UIStroke" then
		-- Mặc định viền áp lên cả chữ (gây loang); chỉ viền khung thôi
		inst.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	end
	for key, value in pairs(props) do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end

local function corner(inst, radius)
	make("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, inst)
end

-- Thanh tiến độ cho HP và độ bền: nền tối + phần đầy. Trả về (nền, phần đầy). label = chữ trong thanh (bỏ trống nếu thanh quá nhỏ)
local function progressBar(parent, size, position, ratio, color, label)
	local back = make("Frame", { Size = size, Position = position, BackgroundColor3 = COLORS.Outline, BorderSizePixel = 0 }, parent)
	corner(back, 6)
	local fill = make("Frame", { Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1), BackgroundColor3 = color, BorderSizePixel = 0 }, back)
	corner(fill, 6)
	if label then
		local text = make("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			TextScaled = true,
			Font = Enum.Font.GothamBold,
			TextColor3 = Color3.new(1, 1, 1),
			TextStrokeTransparency = 0.4,
			Text = label,
			ZIndex = 2,
		}, back)
		make("UITextSizeConstraint", { MaxTextSize = 11 }, text)
	end
	return back, fill
end

-- Màu thanh HP: xanh lá, đỏ khi gần cạn (màu thanh độ bền: Config.DurabilityColor)
local function hpColor(ratio)
	return ratio <= Config.Pet.WarnRatio and COLORS.Red or COLORS.Green
end

-- Viền tối + bóng sáng phía trên: dùng cho mọi nút / thẻ để cùng một phong cách
local function candy(inst, color)
	inst.BackgroundColor3 = color
	make("UIStroke", { Color = COLORS.Outline, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, inst)
	make("UIGradient", {
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(215, 215, 215)),
		Rotation = 90,
	}, inst)
end

-- Hiệu ứng nút: rê chuột thì phóng to, nhấn thì co lại, nhả thì nảy về
local function addFx(b)
	local fx = make("UIScale", {}, b)
	local hovering = false
	b.MouseEnter:Connect(function()
		hovering = true
		TweenService:Create(fx, BOUNCE, { Scale = 1.08 }):Play()
	end)
	b.MouseLeave:Connect(function()
		hovering = false
		TweenService:Create(fx, BOUNCE, { Scale = 1 }):Play()
	end)
	b.MouseButton1Down:Connect(function()
		TweenService:Create(fx, TweenInfo.new(0.08), { Scale = 0.9 }):Play()
	end)
	b.MouseButton1Up:Connect(function()
		TweenService:Create(fx, BOUNCE, { Scale = hovering and 1.08 or 1 }):Play()
	end)
	return fx
end

local function button(parent, text, color, size, position, onClick)
	local b = make("TextButton", {
		Size = size,
		Position = position,
		Text = text,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeColor3 = COLORS.Outline,
		TextStrokeTransparency = 0.3,
		AutoButtonColor = false,
	}, parent)
	corner(b, 12)
	candy(b, color)
	make("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
	}, b)
	make("UITextSizeConstraint", { MaxTextSize = 20 }, b)
	if onClick then
		addFx(b)
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

-- Các loại trứng theo thứ tự thường -> hiếm (Config.EggOrder)
local function sortedTiers()
	return table.clone(Config.EggOrder)
end

-- ===== Khung chính =====
local gui = make("ScreenGui", { Name = "MainUI", ResetOnSpawn = false }, player:WaitForChild("PlayerGui"))

local status = make("TextLabel", {
	Size = UDim2.fromScale(0.44, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	Position = UDim2.new(0.5, 0, 0, 12),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundColor3 = COLORS.Panel,
	BackgroundTransparency = 0.05,
	TextSize = 20,
	TextWrapped = true,
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.new(1, 1, 1),
	Text = "",
	Visible = false,
}, gui)
corner(status, 23)
make("UIStroke", { Color = COLORS.Gold, Thickness = 3 }, status)
make("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, status)
make("UISizeConstraint", { MinSize = Vector2.new(260, 0), MaxSize = Vector2.new(620, 200) }, status)
local statusScale = make("UIScale", {}, status)

local TOAST_TIME = 3 -- mọi thông báo tự ẩn sau bấy nhiêu giây
local toastToken = nil

local function toast(message)
	local token = {}
	toastToken = token
	status.Text = message
	status.Visible = true
	statusScale.Scale = 0.7
	TweenService:Create(statusScale, BOUNCE, { Scale = 1 }):Play()
	task.delay(TOAST_TIME, function()
		if toastToken == token then
			status.Visible = false
		end
	end)
end

toast("Welcome! Sneak to the lake, HOLD the fish button, and bring your loot back to the Stash in your house.")

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
-- Cột thông tin góc trên trái (né nút menu của Roblox): Coins, Bag, mũi tên Stash, Tutorial xếp tự động
local topLeft = make("Frame", {
	Size = UDim2.fromOffset(280, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	Position = UDim2.fromOffset(16, 70),
	BackgroundTransparency = 1,
}, gui)
make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, topLeft)

-- Thẻ thông tin dạng viên thuốc: nền tối trong, viền màu theo loại
-- Icon nằm riêng bên trái, số căn phải với cỡ chữ cố định (không TextScaled nên không bị nhoè)
local function pill(order, strokeColor, icon)
	local label = make("TextLabel", {
		Size = UDim2.fromOffset(264, 44),
		LayoutOrder = order,
		BackgroundColor3 = Color3.fromRGB(30, 24, 70),
		BackgroundTransparency = 0.1,
		TextSize = 26,
		TextXAlignment = Enum.TextXAlignment.Right,
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeColor3 = COLORS.Outline,
		TextStrokeTransparency = 0.6,
	}, topLeft)
	corner(label, 22)
	make("UIStroke", { Color = strokeColor, Thickness = 3 }, label)
	make("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 16) }, label)
	make("TextLabel", {
		Size = UDim2.fromOffset(32, 32),
		Position = UDim2.new(0, 0, 0.5, -16),
		BackgroundTransparency = 1,
		TextScaled = true,
		Text = icon,
	}, label)
	return label
end

-- Ngăn nhóm nghìn bằng dấu cách cho thoáng: 1 234 567
local function spaced(n)
	return (commas(n):gsub(",", " "))
end

local coinsLabel = pill(1, COLORS.Gold, "💰")
coinsLabel.TextColor3 = COLORS.Gold
coinsLabel.Text = "0"
local coinsScale = make("UIScale", {}, coinsLabel)

-- ===== Câu cá: GIỮ nút để kéo, NHẢ là tạm dừng (giữ tiến độ, câu lén khi ngỗng tới) =====
-- Nhấn giữ nút này (hoặc phím F, hoặc click giữ khi đang cầm cần). Server tính tiến độ, client chỉ báo nhấn/nhả.
local holding = false
local refreshCastButton -- gán sau khi dựng nút (bên dưới)

local function pressFish()
	if holding then
		return
	end
	holding = true
	refreshCastButton()
	-- Tự cầm cần câu lên nếu đang để trong túi
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local rod = player.Backpack:FindFirstChild("FishingRod")
	if humanoid and rod then
		humanoid:EquipTool(rod)
	end
	remotes.Cast:FireServer("Down")
end

local function releaseFish()
	if not holding then
		return
	end
	holding = false
	refreshCastButton()
	remotes.Cast:FireServer("Up")
end

-- Nút tròn to ở góc dưới phải (vùng ngón cái). Trên điện thoại dời sang trái để chừa chỗ cho nút nhảy của Roblox.
local castButton = make("TextButton", {
	Name = "FishButton",
	AnchorPoint = Vector2.new(1, 1),
	Size = UDim2.fromOffset(128, 128),
	Position = IS_TOUCH and UDim2.new(1, -200, 1, -24) or UDim2.new(1, -28, 1, -28),
	Text = "",
	AutoButtonColor = false,
}, gui)
corner(castButton, 64)
candy(castButton, COLORS.Blue)
castButton:FindFirstChildOfClass("UIStroke").Thickness = 5
local castIcon = make("TextLabel", {
	Size = UDim2.fromScale(1, 0.62),
	Position = UDim2.fromScale(0, 0.06),
	BackgroundTransparency = 1,
	TextScaled = true,
	Text = "🎣",
}, castButton)
local castText = make("TextLabel", {
	Size = UDim2.fromScale(0.8, 0.22),
	Position = UDim2.fromScale(0.1, 0.68),
	BackgroundTransparency = 1,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
	TextColor3 = Color3.new(1, 1, 1),
	TextStrokeColor3 = COLORS.Outline,
	TextStrokeTransparency = 0.2,
	Text = "HOLD",
}, castButton)
if not IS_TOUCH then
	-- Huy hiệu phím tắt
	local badge = make("TextLabel", {
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.new(1, -26, 0, -2),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBlack,
		TextSize = 18,
		TextColor3 = COLORS.Outline,
		Text = "F",
	}, castButton)
	corner(badge, 15)
	make("UIStroke", { Color = COLORS.Outline, Thickness = 2 }, badge)
end
local castScale = make("UIScale", {}, castButton)

refreshCastButton = function()
	castButton.BackgroundColor3 = holding and COLORS.Orange or COLORS.Blue
	castText.Text = holding and "REELING" or "HOLD"
end

-- Hiệu ứng sống: nút "thở" khi chờ, co lại khi đang giữ; cần câu lắc nhẹ
local t0 = os.clock()
RunService.Heartbeat:Connect(function()
	local t = os.clock() - t0
	castScale.Scale = holding and 0.9 or 1 + 0.04 * math.sin(t * 3)
	castIcon.Rotation = holding and math.sin(t * 25) * 8 or math.sin(t * 2) * 10
end)

castButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		pressFish()
	end
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.F then
		pressFish()
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.F then
		releaseFish()
	end
end)
UserInputService.WindowFocusReleased:Connect(releaseFish)

-- ===== HUD: thanh kéo, HP pet, túi, hướng về Stash, cảnh báo ngỗng =====
-- Giữa đáy màn hình: thanh kéo cá (dưới) và HP pet (trên), cách xa nút Fish ở góc phải
local reelFrame = make("Frame", {
	Size = UDim2.fromOffset(380, 66),
	Position = UDim2.new(0.5, -190, 1, -100),
	BackgroundColor3 = Color3.fromRGB(30, 24, 70),
	BackgroundTransparency = 0.1,
	Visible = false,
}, gui)
corner(reelFrame, 16)
make("UIStroke", { Color = COLORS.Gold, Thickness = 3 }, reelFrame)
local reelName = make("TextLabel", {
	Size = UDim2.new(1, -20, 0, 24),
	Position = UDim2.fromOffset(10, 5),
	BackgroundTransparency = 1,
	TextScaled = true,
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.new(1, 1, 1),
	Text = "",
}, reelFrame)
local reelBack = make("Frame", {
	Size = UDim2.new(1, -20, 0, 20),
	Position = UDim2.fromOffset(10, 36),
	BackgroundColor3 = Color3.fromRGB(70, 62, 120),
}, reelFrame)
corner(reelBack, 10)
local reelFill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = COLORS.Gold }, reelBack)
corner(reelFill, 10)

local petFrame = make("Frame", {
	Size = UDim2.fromOffset(380, 32),
	Position = UDim2.new(0.5, -190, 1, -144),
	BackgroundColor3 = Color3.fromRGB(70, 62, 120),
	Visible = false,
}, gui)
corner(petFrame, 16)
make("UIStroke", { Color = COLORS.Outline, Thickness = 3 }, petFrame)
local petFill = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = COLORS.Green }, petFrame)
corner(petFill, 16)
local petText = make("TextLabel", {
	Size = UDim2.new(1, -12, 1, -6),
	Position = UDim2.fromOffset(6, 3),
	BackgroundTransparency = 1,
	TextScaled = true,
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.new(1, 1, 1),
	TextStrokeTransparency = 0.5,
}, petFrame)
-- Thanh độ bền của pet đang đi theo, mỏng, ngay dưới thanh HP
local _, petDurabilityFill = progressBar(petFrame, UDim2.new(1, -40, 0, 8), UDim2.new(0, 20, 1, 4), 1, COLORS.Blue)

local bagLabel = pill(2, COLORS.Blue, "🎒")

local stashFrame = make("Frame", {
	Size = UDim2.fromOffset(264, 44),
	LayoutOrder = 3,
	BackgroundColor3 = Color3.fromRGB(30, 24, 70),
	BackgroundTransparency = 0.1,
	Visible = false,
}, topLeft)
corner(stashFrame, 22)
make("UIStroke", { Color = COLORS.Green, Thickness = 3 }, stashFrame)
local stashArrow = make("TextLabel", {
	Size = UDim2.fromOffset(36, 36),
	Position = UDim2.fromOffset(4, 2),
	BackgroundTransparency = 1,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
	TextColor3 = COLORS.Gold,
	Text = "▲",
}, stashFrame)
local stashText = make("TextLabel", {
	Size = UDim2.new(1, -48, 1, -8),
	Position = UDim2.fromOffset(44, 4),
	BackgroundTransparency = 1,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.new(1, 1, 1),
}, stashFrame)

local alertLabel = make("TextLabel", {
	Size = UDim2.fromOffset(380, 44),
	Position = UDim2.new(0.5, -190, 0, 76),
	BackgroundColor3 = COLORS.Red,
	TextScaled = true,
	Font = Enum.Font.GothamBlack,
	TextColor3 = Color3.new(1, 1, 1),
	Visible = false,
}, gui)
corner(alertLabel, 22)
make("UIStroke", { Color = COLORS.Outline, Thickness = 3 }, alertLabel)
make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, alertLabel)

local reel = nil -- { Start, Duration, Base, Paused, PausedAt, Timeout } khi đang có lượt câu
local petState = nil -- bản mới nhất của Pets.Status
local petHPs = {} -- [Id pet] = HP cuối cùng thấy được. Pet không equip thì HP không đổi nên con số này vẫn đúng; chưa thấy lần nào = đầy máu
local bagCount = 0
local stashPart = nil

local function startReel(data)
	-- Base = số giây đã kéo trước đó (kéo tiếp sau khi tạm dừng)
	reel = { Start = data.StartTime, Duration = data.Duration, Base = data.Progress or 0, Paused = false, Spot = data.Spot }
	reelName.Text = ("%s  -  keep holding! (let go to pause)"):format(data.Chest)
	reelFill.BackgroundColor3 = data.Spot == "Lake" and COLORS.Gold or COLORS.Blue
	reelFill.Size = UDim2.fromScale(math.clamp(reel.Base / reel.Duration, 0, 1), 1)
	reelFrame.Visible = true
end

-- Nhả nút: thanh đứng yên, màu xám, đếm ngược thời gian còn được tạm dừng
local function pauseReel(data)
	reel = {
		Duration = data.Duration,
		Base = data.Progress,
		Paused = true,
		PausedAt = os.clock(),
		Timeout = data.Timeout,
		Chest = data.Chest,
	}
	reelFill.BackgroundColor3 = COLORS.Grey
	reelFill.Size = UDim2.fromScale(math.clamp(reel.Base / reel.Duration, 0, 1), 1)
	reelFrame.Visible = true
end

local function endReel(success)
	if not reel then
		return
	end
	reel = nil
	reelFill.BackgroundColor3 = success and COLORS.Green or COLORS.Red
	if success then
		reelFill.Size = UDim2.fromScale(1, 1)
	end
	task.delay(0.5, function()
		if not reel then
			reelFrame.Visible = false
		end
	end)
end

local function refreshPet()
	if not (petState and petState.HasPet) then
		petFrame.Visible = false
		return
	end
	petFrame.Visible = true
	local name = petState.Name or "Pet"
	local low = petState.Down or petState.HP <= petState.Max * Config.Pet.WarnRatio
	petFill.Size = UDim2.fromScale(math.clamp(petState.HP / petState.Max, 0, 1), 1)
	petFill.BackgroundColor3 = low and COLORS.Red or COLORS.Green
	if petState.Down then
		petText.Text = ("%s is exhausted! Rest at home"):format(name)
	elseif low then
		petText.Text = ("[!] %s  %d/%d"):format(name, math.ceil(petState.HP), petState.Max)
	else
		petText.Text = ("%s  %d/%d"):format(name, math.ceil(petState.HP), petState.Max)
	end

	for _, pet in ipairs(profile and profile.Pets or {}) do
		if pet.Id == petState.Id then
			local ratio = pet.Durability / Config.PetDurability(pet.Name)
			petDurabilityFill.Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1)
			petDurabilityFill.BackgroundColor3 = Config.DurabilityColor(ratio)
			break
		end
	end
end

local function refreshBag(data)
	bagCount = data.Count
	bagLabel.Text = ("%d / %d%s"):format(data.Count, data.Capacity, data.Count >= data.Capacity and "  FULL" or "")
	bagLabel.TextColor3 = data.Count >= data.Capacity and COLORS.Red or Color3.new(1, 1, 1)
	stashFrame.Visible = data.Count > 0
end

local function setAlert(state)
	if state == "Chase" then
		alertLabel.Text = "⚠️ THE GOOSE IS CHASING YOU! ⚠️"
		alertLabel.BackgroundColor3 = COLORS.Red
		alertLabel.Visible = true
	elseif state == "Suspicious" then
		alertLabel.Text = "👀 The goose noticed something..."
		alertLabel.BackgroundColor3 = Color3.fromRGB(200, 140, 30)
		alertLabel.Visible = true
	else
		alertLabel.Visible = false
	end
end

local function findStash()
	if stashPart and stashPart.Parent then
		return stashPart
	end
	local map = workspace:FindFirstChild("Map")
	local plots = map and map:FindFirstChild("Plots")
	local stash
	for _, plot in ipairs(plots and plots:GetChildren() or {}) do
		if plot:GetAttribute("OwnerId") == player.UserId then
			stash = plot:FindFirstChild("Stash", true)
		end
	end
	stash = stash or (map and not plots and map:FindFirstChild("Stash", true))
	if stash and stash:IsA("BasePart") then
		stashPart = stash
	elseif stash and stash:IsA("Model") then
		stashPart = stash.PrimaryPart or stash:FindFirstChildWhichIsA("BasePart", true)
	end
	return stashPart
end

refreshBag({ Count = 0, Capacity = Config.Bag.Capacity })

RunService.RenderStepped:Connect(function()
	if alertLabel.Visible then
		alertLabel.Rotation = math.sin(os.clock() * 14) * 1.5 -- cảnh báo rung nhẹ cho dễ chú ý
	end
	if reel and reel.Paused then
		local left = math.max(0, math.ceil(reel.Timeout - (os.clock() - reel.PausedAt)))
		reelName.Text = ("%s  -  PAUSED %ds  (hold to keep reeling, don't walk away!)"):format(reel.Chest, left)
		if os.clock() - reel.PausedAt > reel.Timeout + 3 then
			endReel(false) -- server không trả lời kịp: dọn thanh cho khỏi kẹt
		end
	elseif reel then
		local progress = reel.Base + (workspace:GetServerTimeNow() - reel.Start)
		reelFill.Size = UDim2.fromScale(math.clamp(progress / reel.Duration, 0, 1), 1)
		if progress > reel.Duration + 3 then
			endReel(false) -- server không trả lời kịp: dọn thanh cho khỏi kẹt
		end
	end

	-- Mũi tên chỉ về Stash khi đang mang đồ chưa cất
	if bagCount > 0 then
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local stash = findStash()
		local camera = workspace.CurrentCamera
		if hrp and stash and camera then
			local toStash = stash.Position - hrp.Position
			local look = camera.CFrame.LookVector
			local cross = look.Z * toStash.X - look.X * toStash.Z
			local dot = look.X * toStash.X + look.Z * toStash.Z
			stashArrow.Rotation = -math.deg(math.atan2(cross, dot))
			stashText.Text = ("🏠 Stash %d studs"):format(math.floor(Vector3.new(toStash.X, 0, toStash.Z).Magnitude))
		end
	end
end)

-- ===== Bảng (panel) =====
local panel = make("Frame", {
	Size = UDim2.fromOffset(460, 480),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = COLORS.Panel,
	Visible = false,
}, gui)
corner(panel, 20)
make("UIStroke", { Color = COLORS.Outline, Thickness = 5 }, panel)
-- Bảng co theo cỡ màn hình (điện thoại nhỏ thì thu lại), mở ra thì nảy lên
local panelScale = make("UIScale", {}, panel)
local function panelBaseScale()
	local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	return math.clamp(math.min(view.X / 560, view.Y / 560), 0.55, 1.15)
end

-- Dải tiêu đề màu hồng phía trên
local titleBar = make("Frame", {
	Size = UDim2.new(1, 0, 0, 60),
	BackgroundColor3 = COLORS.Pink,
}, panel)
corner(titleBar, 20)
make("Frame", { -- che góc bo phía dưới của dải để chỉ bo góc trên
	Size = UDim2.new(1, 0, 0, 20),
	Position = UDim2.new(0, 0, 1, -20),
	BackgroundColor3 = COLORS.Pink,
	BorderSizePixel = 0,
}, titleBar)

local title = make("TextLabel", {
	Size = UDim2.new(1, -80, 0, 44),
	Position = UDim2.fromOffset(16, 8),
	BackgroundTransparency = 1,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.GothamBlack,
	TextColor3 = Color3.new(1, 1, 1),
	TextStrokeColor3 = COLORS.Outline,
	TextStrokeTransparency = 0.2,
}, panel)

local list = make("ScrollingFrame", {
	Size = UDim2.new(1, -24, 1, -76),
	Position = UDim2.fromOffset(12, 68),
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
-- bar (tùy chọn): { Ratio, Color, Label } = thanh HP / độ bền dưới chữ của hàng
local function addRow(text, buttons, bar)
	rowCount += 1
	local row = make("Frame", {
		Size = UDim2.new(1, -8, 0, 64),
		BackgroundColor3 = COLORS.Row,
		LayoutOrder = rowCount,
	}, list)
	corner(row, 14)
	local width = 100
	local textWidth = -(#buttons * (width + 6)) - 18
	if bar then
		progressBar(row, UDim2.new(1, textWidth, 0, 13), UDim2.fromOffset(10, 47), bar.Ratio, bar.Color, bar.Label)
	end
	make("TextLabel", {
		Size = UDim2.new(1, textWidth, 1, bar and -26 or -8),
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
		local b = button(row, spec.Text, spec.Disabled and COLORS.Grey or spec.Color, UDim2.fromOffset(width, 42), UDim2.new(1, -i * (width + 6), 0.5, -21), not spec.Disabled and spec.OnClick or nil)
		if spec.Disabled then
			b.TextTransparency = 0.35
		end
	end
end

-- Pet đang có (bản ghi { Id, Name, Durability }), hiếm nhất (giá bán gốc cao nhất) trước
local function sortedPets()
	local pets = table.clone(profile.Pets)
	table.sort(pets, function(a, b)
		local priceA, priceB = Config.SellPrices.Pets[a.Name] or 0, Config.SellPrices.Pets[b.Name] or 0
		if priceA ~= priceB then
			return priceA > priceB
		end
		return a.Id < b.Id
	end)
	return pets
end

local function closePanel()
	panel.Visible = false
	current = nil
end

button(panel, "✖", COLORS.Red, UDim2.fromOffset(46, 46), UDim2.new(1, -56, 0, 7), closePanel)

-- ===== Lưới đồ có hình (bảng Bag) =====
-- Hình món đồ = ViewportFrame chiếu model 3D thật (Models.Get), bỏ script / Humanoid cho nhẹ. Bản gốc cache lại, mỗi ô chỉ Clone.
local RARITY_COLORS = {
	Color3.fromRGB(235, 235, 245), -- 1 thường
	Color3.fromRGB(110, 210, 130), -- 2
	Color3.fromRGB(90, 170, 255), -- 3
	Color3.fromRGB(190, 120, 255), -- 4
	Color3.fromRGB(255, 205, 70), -- 5
	Color3.fromRGB(255, 130, 200), -- 6
}
local iconCache = {}

local function iconModel(name)
	local cached = iconCache[name]
	if cached == nil then
		local ok, model = pcall(Models.Get, name)
		cached = ok and model or false
		if cached then
			for _, d in ipairs(cached:GetDescendants()) do
				if d:IsA("LuaSourceContainer") or d:IsA("Humanoid") or d:IsA("BillboardGui") or d:IsA("Highlight") then
					d:Destroy()
				elseif d:IsA("BasePart") then
					d.Anchored = true
				end
			end
			if cached:IsA("Tool") then
				-- cần câu dạng Tool: cho vào Model tạm để lấy bounding box
				local wrap = Instance.new("Model")
				for _, child in ipairs(cached:GetChildren()) do
					child.Parent = wrap
				end
				cached = wrap
			end
		end
		iconCache[name] = cached
	end
	return cached or nil
end

-- Hình model trong khung `parent`. silhouette = true: hiện bóng đen (chưa sở hữu)
local function modelIcon(parent, modelName, silhouette)
	local vp = make("ViewportFrame", {
		Size = UDim2.new(1, -8, 0, 68),
		Position = UDim2.fromOffset(4, 4),
		BackgroundTransparency = 1,
		LightColor = Color3.new(1, 1, 1),
		Ambient = Color3.fromRGB(150, 150, 160),
	}, parent)
	local source = iconModel(modelName)
	if not source then
		return vp
	end
	local model = source:Clone()
	model.Parent = vp
	local boxCf, size = model:GetBoundingBox()
	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	local distance = size.Magnitude / 2 / math.tan(math.rad(camera.FieldOfView / 2)) * 1.1
	-- đồ asset quay mặt về -Z: nhìn từ phía trước, lệch nhẹ + hơi cao cho có chiều sâu
	local offset = Vector3.new(0.55, 0.3, -1).Unit * distance
	camera.CFrame = CFrame.lookAt(boxCf.Position + offset, boxCf.Position)
	camera.Parent = vp
	vp.CurrentCamera = camera
	if silhouette then
		vp.ImageColor3 = Color3.new(0, 0, 0)
		vp.ImageTransparency = 0.45
	end
	return vp
end

local function addGrid()
	rowCount += 1
	local grid = make("Frame", {
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = rowCount,
	}, list)
	make("UIGridLayout", {
		CellSize = UDim2.fromOffset(100, 118),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)
	return grid
end

-- spec: { Model | Emoji, Name, Sub, Bars ({ { Ratio, Color } }, thay cho Sub), Count, Rank (1..6 màu viền), Dim (chưa có), Tag ("EQUIPPED"...), OnClick (bấm vào ô) }
local function addCell(grid, spec)
	local cell = make("Frame", { BackgroundColor3 = COLORS.Row, BackgroundTransparency = spec.Dim and 0.45 or 0 }, grid)
	corner(cell, 14)
	local color = RARITY_COLORS[spec.Rank or 1]
	make("UIStroke", { Color = spec.Dim and COLORS.Grey or color, Thickness = spec.Tag and 4 or 2.5 }, cell)
	if spec.Model then
		modelIcon(cell, spec.Model, spec.Dim)
	else
		make("TextLabel", {
			Size = UDim2.new(1, -8, 0, 68),
			Position = UDim2.fromOffset(4, 4),
			BackgroundTransparency = 1,
			TextScaled = true,
			Text = spec.Emoji or "?",
			TextTransparency = spec.Dim and 0.6 or 0,
		}, cell)
	end
	local nameLabel = make("TextLabel", {
		Size = UDim2.new(1, -8, 0, 18),
		Position = UDim2.fromOffset(4, 74),
		BackgroundTransparency = 1,
		TextScaled = true,
		Font = Enum.Font.GothamBold,
		TextColor3 = spec.Dim and COLORS.Grey or Color3.new(1, 1, 1),
		Text = spec.Name,
	}, cell)
	make("UITextSizeConstraint", { MaxTextSize = 14 }, nameLabel)
	if spec.Bars then
		-- thanh HP / độ bền thay cho dòng chữ phụ: mỗi thanh cao 8, xếp từ trên xuống
		for i, bar in ipairs(spec.Bars) do
			progressBar(cell, UDim2.new(1, -16, 0, 8), UDim2.fromOffset(8, 95 + (i - 1) * 11), bar.Ratio, bar.Color)
		end
	elseif spec.Sub then
		local subLabel = make("TextLabel", {
			Size = UDim2.new(1, -8, 0, 16),
			Position = UDim2.fromOffset(4, 94),
			BackgroundTransparency = 1,
			TextScaled = true,
			Font = Enum.Font.Gotham,
			TextColor3 = Color3.fromRGB(220, 220, 235),
			Text = spec.Sub,
		}, cell)
		make("UITextSizeConstraint", { MaxTextSize = 12 }, subLabel)
	end
	if spec.Count and not spec.Dim then
		local badge = make("TextLabel", {
			Size = UDim2.fromOffset(34, 22),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 2, 0, -6),
			BackgroundColor3 = COLORS.Gold,
			Font = Enum.Font.GothamBlack,
			TextSize = 14,
			TextColor3 = COLORS.Outline,
			Text = "x" .. spec.Count,
			ZIndex = 3,
		}, cell)
		corner(badge, 11)
		make("UIStroke", { Color = COLORS.Outline, Thickness = 2 }, badge)
	end
	if spec.Tag then
		local tag = make("TextLabel", {
			Size = UDim2.fromOffset(84, 18),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, -8),
			BackgroundColor3 = COLORS.Green,
			Font = Enum.Font.GothamBlack,
			TextSize = 11,
			TextColor3 = Color3.new(1, 1, 1),
			Text = spec.Tag,
			ZIndex = 3,
		}, cell)
		corner(tag, 9)
		make("UIStroke", { Color = COLORS.Outline, Thickness = 2 }, tag)
	end
	if spec.OnClick then
		local hit = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5 }, cell)
		hit.Activated:Connect(spec.OnClick)
	end
end

-- ===== Nội dung từng bảng =====
local renderers = {}

-- Rương hiếm nhất mà bảng tỉ lệ ra rương này có thể ra (vd. "Purple")
local function topChestName(odds)
	for i = #odds, 1, -1 do
		if odds[i] > 0 then
			return (Config.Chests[i].Name:gsub(" Chest", ""))
		end
	end
end

renderers.Shop = function()
	header("Fishing Rods")
	for _, rod in ipairs(Config.Rods) do
		-- Cần đang có thì hiện thanh độ bền; chưa mua thì ghi dùng được bao nhiêu rương
		local left = profile.Rods[rod.Id]
		local note = ""
		if not rod.Durability then
			note = "  (never breaks)"
		elseif not left then
			note = ("  (lasts %d chests)"):format(rod.Durability)
		end
		local text = ("<b>%s</b>%s\nPurple+ chests %.1f%%   Speed x%.1f"):format(rod.Name, note, Config.TopChestPercent(rod.Odds), 1 / rod.Speed)
		local bar = nil
		if rod.Durability and left then
			bar = { Ratio = left / rod.Durability, Color = Config.DurabilityColor(left / rod.Durability), Label = ("%d/%d"):format(left, rod.Durability) }
		end
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
		addRow(text, { spec }, bar)
	end

	header("Plot Upgrades")
	local fisherCfg = Config.AutoFisher
	local pedestals = profile.FisherSlots
	local nextPedestal = fisherCfg.PedestalPrices[pedestals + 1]
	addRow(
		("<b>Machine Pedestal</b> (%d/%d)\nA place for one Auto-Fisher"):format(pedestals, #fisherCfg.PedestalPrices),
		{ nextPedestal and { Text = commas(nextPedestal), Color = COLORS.Green, OnClick = function()
			request("BuyFisherSlot")
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

	-- Nâng cấp túi tạm (Config.Bag.Upgrades)
	local level = profile.BagLevel or 0
	local bagNow = level > 0 and Config.Bag.Upgrades[level].Capacity or Config.Bag.Capacity
	local nextBag = Config.Bag.Upgrades[level + 1]
	addRow(
		("<b>Bigger Bag</b> (%d chests)\nCarry more loot from the lake"):format(bagNow),
		{ nextBag and { Text = commas(nextBag.Price), Color = COLORS.Green, OnClick = function()
			request("BuyBagUpgrade")
		end } or { Text = "Max", Disabled = true } }
	)

	-- Máy câu: mua thẳng tier tùy chọn vào ổ trống (máy hỏng thì mua lại), rồi nâng tier tại chỗ
	header("Auto-Fishers (wear out, buy again)")
	for tierIndex, tier in ipairs(fisherCfg.Tiers) do
		addRow(
			("<b>%s Auto-Fisher</b>  (up to %s)\n%ds / chest, holds %d, lasts %d chests"):format(tier.Name, topChestName(tier.Odds), tier.Interval, tier.Capacity, tier.Durability),
			{ { Text = commas(tier.Price), Color = COLORS.Green, OnClick = function()
				request("BuyAutoFisher", tierIndex)
			end } }
		)
	end
	for slot = 1, pedestals do
		local entry = profile.AutoFishers[tostring(slot)]
		if entry then
			local tier = fisherCfg.Tiers[entry.Tier]
			local nextTier = fisherCfg.Tiers[entry.Tier + 1]
			local ratio = entry.Durability / tier.Durability
			addRow(
				("<b>Machine #%d: %s</b>\n%s"):format(slot, tier.Name, nextTier and ("Upgrade to %s restores durability"):format(nextTier.Name) or "Best machine"),
				{ nextTier and { Text = commas(nextTier.Price - tier.Price), Color = COLORS.Green, OnClick = function()
					request("UpgradeAutoFisher", slot)
				end } or { Text = "Max", Disabled = true } },
				{ Ratio = ratio, Color = Config.DurabilityColor(ratio), Label = ("%d/%d"):format(entry.Durability, tier.Durability) }
			)
		end
	end

	-- Trang bị (Config.Gear)
	header("Gear")
	for id, gear in pairs(Config.Gear) do
		local hasGear = profile.Gear and profile.Gear[id]
		addRow(
			("<b>%s</b>\nMove %d%% faster (walk and sprint)"):format(gear.Name, math.floor(gear.SpeedBonus * 100 + 0.5)),
			{ hasGear and { Text = "Owned", Disabled = true } or { Text = commas(gear.Price), Color = COLORS.Green, OnClick = function()
				request("BuyGear", id)
			end } }
		)
	end
end

renderers.Market = function()
	header("Eggs")
	local any = false
	for _, tier in ipairs(sortedTiers()) do
		local count = profile.Eggs[tier] or 0
		if count > 0 and Config.SellPrices.Eggs[tier] then -- trứng không có giá thì không bán
			any = true
			addRow(("<b>%s Egg</b> x%d\n%s coins each"):format(tier, count, commas(Config.SellPrices.Eggs[tier])), {
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

	header("Pets (worn pets sell for less)")
	local pets = sortedPets()
	for _, pet in ipairs(pets) do
		local following = profile.EquippedPet == pet.Id and "  [following you]" or ""
		local maxDurability = Config.PetDurability(pet.Name)
		local ratio = pet.Durability / maxDurability
		addRow(("<b>%s</b>%s\n%d max HP"):format(pet.Name, following, Config.PetMaxHP(pet.Name)), {
			{ Text = "Sell " .. commas(Config.PetSellPrice(pet)), Color = COLORS.Green, OnClick = function()
				request("SellPet", pet.Id)
			end },
		}, { Ratio = ratio, Color = Config.DurabilityColor(ratio), Label = ("%d/%d"):format(math.ceil(pet.Durability), maxDurability) })
	end
	if #pets == 0 then
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

-- Hạng màu viền của pet = thứ tự trứng nở ra nó (Config.EggOrder)
local function petRank(petName)
	for rank, tier in ipairs(Config.EggOrder) do
		for _, pet in ipairs(Config.Eggs[tier].Pets) do
			if pet.Name == petName then
				return rank
			end
		end
	end
	return 1
end

renderers.Bag = function()
	header(("💰 Coins: %s"):format(commas(profile.Coins)))
	if bagCount > 0 then
		addRow(("🎒 <b>Carrying %d chest(s)</b>\nDeposit them at your Stash or the goose may take them!"):format(bagCount), {})
	end

	-- Trứng: đủ mọi loại, loại chưa có hiện bóng đen
	header("🥚 Eggs")
	local eggs = addGrid()
	for rank, tier in ipairs(sortedTiers()) do
		local count = profile.Eggs[tier] or 0
		addCell(eggs, {
			Model = Config.Eggs[tier].Model and (tier .. " Egg"),
			Name = tier .. " Egg",
			Sub = ("hatch %ds"):format(Config.Eggs[tier].HatchTime),
			Count = count,
			Rank = rank,
			Dim = count == 0,
		})
	end

	-- Pet: mỗi con 1 ô với 2 thanh (HP xanh lá, độ bền xanh dương), bấm để cho đi theo; loại chưa có hiện bóng đen
	header("🐾 Pets (tap to equip)")
	addRow("Green bar: HP (refills at home)\nBlue bar: durability (never refills)", {})
	local pets = addGrid()
	local seen = {}
	for _, pet in ipairs(sortedPets()) do
		seen[pet.Name] = true
		local hpRatio = (petHPs[pet.Id] or Config.PetMaxHP(pet.Name)) / Config.PetMaxHP(pet.Name)
		local durabilityRatio = pet.Durability / Config.PetDurability(pet.Name)
		addCell(pets, {
			Model = pet.Name,
			Name = pet.Name,
			Bars = {
				{ Ratio = hpRatio, Color = hpColor(hpRatio) },
				{ Ratio = durabilityRatio, Color = Config.DurabilityColor(durabilityRatio) },
			},
			Rank = petRank(pet.Name),
			Tag = profile.EquippedPet == pet.Id and "EQUIPPED" or nil,
			OnClick = function()
				request("EquipPet", pet.Id)
			end,
		})
	end
	for _, tier in ipairs(Config.EggOrder) do
		for _, pet in ipairs(Config.Eggs[tier].Pets) do
			if not seen[pet.Name] then
				seen[pet.Name] = true
				addCell(pets, { Model = pet.Name, Name = pet.Name, Sub = "not found", Rank = petRank(pet.Name), Dim = true })
			end
		end
	end

	-- Cần câu: cần đang dùng có nhãn EQUIPPED, cần chưa mua hiện bóng đen
	header("🎣 Rods")
	local rods = addGrid()
	for rank, rod in ipairs(Config.Rods) do
		local owned = profile.Rods[rod.Id]
		addCell(rods, {
			Model = rod.Name,
			Name = rod.Name,
			Sub = owned and not rod.Durability and "never breaks" or not owned and "in Tool Shop" or nil,
			Bars = owned and rod.Durability and { { Ratio = owned / rod.Durability, Color = Config.DurabilityColor(owned / rod.Durability) } } or nil,
			Rank = rank,
			Dim = not owned,
			Tag = profile.EquippedRod == rod.Id and "EQUIPPED" or nil,
			OnClick = owned and function()
				request("EquipRod", rod.Id)
			end or nil,
		})
	end

	-- Trang bị
	header("👟 Gear")
	local gears = addGrid()
	for id, gear in pairs(Config.Gear) do
		local owned = profile.Gear and profile.Gear[id]
		addCell(gears, {
			Emoji = "👟",
			Name = gear.Name,
			Sub = owned and ("+%d%% speed"):format(math.floor(gear.SpeedBonus * 100 + 0.5)) or "in Tool Shop",
			Rank = 5,
			Dim = not owned,
		})
	end
end

local TITLES = { Shop = "🛒 Tool Shop", Market = "💰 Market", Hatch = "🥚 Hatchery", Bag = "🎒 My Bag" }

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
	local base = panelBaseScale()
	panelScale.Scale = base * 0.8
	panel.Visible = true
	TweenService:Create(panelScale, BOUNCE, { Scale = base }):Play()
	render()
end

-- Dock bên phải: nút vuông icon to + nhãn ngắn. Nhóm 1 = đi lại (có chip giá), đường kẻ, nhóm 2 = menu.
local dock = make("Frame", {
	Size = UDim2.fromOffset(72, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -14, 0.45, 0),
	BackgroundTransparency = 1,
}, gui)
make("UIListLayout", {
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
}, dock)

local dockIcons = {} -- icon lắc nhẹ cho sống động (xem Heartbeat bên dưới)

local function dockButton(order, icon, label, color, cost, onClick)
	local b = button(dock, "", color, UDim2.fromOffset(68, 68), nil, onClick)
	b.LayoutOrder = order
	b:FindFirstChildOfClass("UIPadding"):Destroy()
	local iconLabel = make("TextLabel", {
		Size = UDim2.fromScale(1, 0.6),
		Position = UDim2.fromScale(0, 0.04),
		BackgroundTransparency = 1,
		TextScaled = true,
		Text = icon,
	}, b)
	table.insert(dockIcons, iconLabel)
	make("TextLabel", {
		Size = UDim2.fromScale(0.9, 0.26),
		Position = UDim2.fromScale(0.05, 0.68),
		BackgroundTransparency = 1,
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeColor3 = COLORS.Outline,
		TextStrokeTransparency = 0.2,
		Text = label,
	}, b)
	if cost and cost > 0 then
		local chip = make("TextLabel", {
			Size = UDim2.fromOffset(46, 22),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 6, 0, -8),
			BackgroundColor3 = COLORS.Gold,
			Font = Enum.Font.GothamBlack,
			TextSize = 15,
			TextColor3 = COLORS.Outline,
			Text = tostring(cost),
			ZIndex = 2,
		}, b)
		corner(chip, 11)
		make("UIStroke", { Color = COLORS.Outline, Thickness = 2 }, chip)
	end
	return b
end

dockButton(1, "🏠", "HOME", COLORS.Green, Config.Teleport.HomeCost, function()
	request("Teleport", "Plot")
end)
-- Ra hồ tốn tiền (Config.Teleport.LakeCost), giống bệ dịch chuyển trước nhà
dockButton(2, "🌊", "LAKE", COLORS.Blue, Config.Teleport.LakeCost, function()
	request("Teleport", "Lake")
end)
-- Tới Tool Shop (Config.Teleport.ShopCost, 0 = miễn phí)
dockButton(3, "🛒", "SHOP", COLORS.Orange, Config.Teleport.ShopCost, function()
	request("Teleport", "Shop")
end)
make("Frame", { -- đường kẻ ngăn nhóm đi lại và nhóm menu
	Size = UDim2.fromOffset(50, 4),
	LayoutOrder = 4,
	BackgroundColor3 = COLORS.Outline,
	BorderSizePixel = 0,
}, dock)
dockButton(5, "🎒", "BAG", COLORS.Pink, nil, function()
	if current and current.Kind == "Bag" then
		closePanel()
	else
		openPanel("Bag")
	end
end)

RunService.Heartbeat:Connect(function()
	local t = os.clock()
	for i, icon in ipairs(dockIcons) do
		icon.Rotation = math.sin(t * 2.2 + i * 1.3) * 7
	end
end)

-- ===== Hướng dẫn người mới (profile.Tutorial: 1..3 đang làm, 99 = xong; xem Tutorial.lua) =====
local TUTORIAL_STEPS = {
	"Hatch your free Reed Egg: go to the Hatchery behind your house and press E on the incubator.",
	"Go to the lake. Stand on the path facing a bubbling CHEST spot and HOLD the big FISH button. If the goose honks, let go!",
	"Run your loot home and press E at your Stash (front yard) to keep it.",
}
local tutorialFrame = make("Frame", {
	Size = UDim2.fromOffset(280, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	LayoutOrder = 4,
	BackgroundColor3 = Color3.fromRGB(40, 90, 170),
	BackgroundTransparency = 0.05,
	Visible = false,
}, topLeft)
corner(tutorialFrame, 16)
make("UIStroke", { Color = COLORS.Gold, Thickness = 3 }, tutorialFrame)
make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10) }, tutorialFrame)
make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, tutorialFrame)
local tutorialTitle = make("TextLabel", {
	Size = UDim2.new(1, 0, 0, 22),
	LayoutOrder = 1,
	BackgroundTransparency = 1,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.GothamBlack,
	TextColor3 = COLORS.Gold,
}, tutorialFrame)
local tutorialText = make("TextLabel", {
	Size = UDim2.fromScale(1, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	LayoutOrder = 2,
	BackgroundTransparency = 1,
	TextWrapped = true,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.new(1, 1, 1),
}, tutorialFrame)

local function refreshTutorial()
	local step = profile and profile.Tutorial
	local text = step and TUTORIAL_STEPS[step]
	tutorialFrame.Visible = text ~= nil
	if text then
		tutorialTitle.Text = ("⭐ TUTORIAL %d/%d"):format(step, #TUTORIAL_STEPS)
		tutorialText.Text = text
	end
end

-- ===== Nhận dữ liệu từ server =====
local lastCoins = nil
local function onSync(data)
	profile = data
	if lastCoins and profile.Coins > lastCoins then
		-- Có thêm tiền: số nảy lên cho vui
		coinsScale.Scale = 1.25
		TweenService:Create(coinsScale, BOUNCE, { Scale = 1 }):Play()
	end
	lastCoins = profile.Coins
	coinsLabel.Text = spaced(profile.Coins)
	refreshTutorial()
	refreshPet() -- độ bền pet đổi theo profile
	if current then
		render()
	end
end

remotes.Sync.OnClientEvent:Connect(onSync)
remotes.Notify.OnClientEvent:Connect(toast)
remotes.Effect.OnClientEvent:Connect(function(kind, data)
	if kind == "OpenPanel" then
		openPanel(data.Panel, data)
	elseif kind == "CastStart" or kind == "CastResume" then
		startReel(data)
	elseif kind == "CastPause" then
		pauseReel(data)
	elseif kind == "CastFail" then
		endReel(false)
	elseif kind == "Catch" then
		endReel(true)
	elseif kind == "PetHP" then
		petState = data
		if data.Id then
			petHPs[data.Id] = data.HP
		end
		refreshPet()
	elseif kind == "Bag" then
		refreshBag(data)
	elseif kind == "Alert" then
		setAlert(data.State)
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
