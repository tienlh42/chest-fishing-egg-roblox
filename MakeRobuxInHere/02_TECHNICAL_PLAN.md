# Kế hoạch kỹ thuật

> Mô tả cách nhận tiền và cấp đồ an toàn. Chưa code. Tham khảo thêm tài liệu Roblox về `MarketplaceService`, `ProcessReceipt`, Game Pass và Experience Subscriptions trên Creator Docs khi làm (API có thể đổi).

## 1. Kiến trúc

```
Client (MainUI)                    Server                                   Roblox
Bảng Store  --Action("BuyProduct", key)-->  Monetization.Buy(player, key)
                                            kiểm tra key hợp lệ, giới hạn  --PromptProductPurchase--> hộp thoại mua
                                                                           <--ProcessReceipt-- (sau khi trả tiền)
                                            Monetization.Grant(player, key)
                                            ghi profile, Data.Save, Data.Update
                                            return PurchaseGranted
```

- Module mới `ServerScriptService/Modules/Monetization.lua`, nối vào `Main.server.lua` giống các module khác.
- **Một `ProcessReceipt` duy nhất** trong cả game (Roblox chỉ cho một callback), tra `productId` ra `key` rồi gọi hàm cấp.
- Client chỉ gửi "tôi muốn mua `key`". Server tự gọi `PromptProductPurchase` / `PromptGamePassPurchase`. Server không bao giờ tin client nói đã mua.

## 2. Cấu hình trong `Config.lua`

```lua
Config.Monetization = {
	Products = { -- Developer Product: id lấy từ Creator Hub, điền sau
		CoinsPouch = { Id = 0, Minutes = 30 },
		CoinsChest = { Id = 0, Minutes = 120 },
		CoinsVault = { Id = 0, Minutes = 480 },
		InstantHatch = { Id = 0 },
	},
	Passes = { -- Game Pass
		AutoCollect = { Id = 0, Name = "Auto-Collect" },
		FreeTeleports = { Id = 0, Name = "Free Teleports" },
	},
	CoinPackDailyLimit = 3,
	CoinPackDailyMinutes = 480,
}
```

Id = 0 nghĩa là chưa tạo, nút Store ẩn món đó. Giá Robux **không** để trong code (giá nằm ở Creator Hub), chỉ có phần quyền lợi.

## 3. Dữ liệu (thêm vào `profile`, nhớ `reconcile`)

| Trường | Kiểu | Dùng cho |
|---|---|---|
| `Purchases` | `{ [PurchaseId] = timestamp }` | Chống cấp hai lần. Giữ khoảng 200 id gần nhất |
| `Passes` | `{ [key] = true }` | Bản sao quyền Game Pass đã kiểm tra (làm nguội, vẫn kiểm lại khi vào game) |
| `Cosmetics` | `{ Owned = {...}, Equipped = { Rod, Pet, House, Tag } }` | Đồ trang trí, tách khỏi `Rods` / `Pets` |
| `CoinPackDay`, `CoinPackCount`, `CoinPackMinutes` | số | Giới hạn gói coins mỗi ngày (ngày theo UTC như hộp thư quà) |
| `Subscribed`, `SubscribedChecked` | bool, số | Trạng thái hội viên |

## 4. Luồng cấp đồ (Developer Product) và các bẫy

```lua
-- phác thảo, không phải code cuối
MarketplaceService.ProcessReceipt = function(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- người chơi đã thoát: Roblox gọi lại khi họ vào lại
	end
	local profile = Data.Get(player)
	if not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- profile chưa tải xong
	end
	if profile.Purchases[receipt.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- đã cấp rồi, báo lại cho Roblox
	end
	local key = keyOfProductId[receipt.ProductId]
	if not key or not grant(player, profile, key) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	profile.Purchases[receipt.PurchaseId] = os.time()
	if not Data.Save(player) then
		profile.Purchases[receipt.PurchaseId] = nil -- hoàn tác phần cấp nếu được
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	Data.Update(player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
```

Các bẫy phải xử lý:

1. **Cấp rồi mới lưu, lưu lỗi thì phải hoàn tác.** Tương tự cách `Bag.Deposit` của game đã làm. Nếu hoàn tác khó (vd. đã cộng coins), dùng `Data.Save` trước khi trả `PurchaseGranted` và chấp nhận có thể `NotProcessedYet` rồi Roblox gọi lại: nhờ `Purchases[PurchaseId]` nên lần sau không cấp thêm.
2. **Hai server cùng xử lý một receipt** (người chơi đổi server đúng lúc): `Purchases` nằm trong profile nên chỉ server giữ phiên mới thấy, đây là giới hạn của `DataStore` hiện tại (`SetAsync`, không khóa phiên). Nếu muốn an toàn tuyệt đối cần chuyển sang `UpdateAsync` với khóa phiên. Ghi vào rủi ro.
3. **Người chơi thoát giữa chừng:** `NotProcessedYet`, lần vào sau Roblox gọi lại.
4. **Dữ liệu tải lỗi (`canSave[player] == false` trong `Data.lua`):** không cấp, trả `NotProcessedYet`, báo người chơi.
5. **Studio:** có công tắc `Config.Dev` để giả lập mua (cấp thẳng không qua Roblox) cho tiện test; **tắt khi publish**.

## 5. Game Pass

- Khi người chơi vào: `UserOwnsGamePassAsync` cho từng pass trong `Config.Monetization.Passes`, ghi `profile.Passes`. Bọc `pcall` (có thể lỗi mạng), lỗi thì giữ giá trị cũ.
- Khi vừa mua: nghe `MarketplaceService.PromptGamePassPurchaseFinished`, kiểm tra lại bằng `UserOwnsGamePassAsync` ở server (không tin tham số `wasPurchased` từ client).
- Hàm dùng chung `Monetization.Has(player, "AutoCollect")` để các module khác hỏi, không đọc profile trực tiếp.

## 6. Chỗ cắm vào code hiện có

| Quyền lợi | Sửa ở đâu |
|---|---|
| Free Teleports | `Teleports.lua` (3 chỗ trừ tiền: Lake, Shop, Home) hỏi `Monetization.Has` |
| Auto-Collect | `Plots.Assign` / `Plots.Refresh`: gọi `AutoFishers.Collect` cho từng ổ khi chủ vào nhà |
| Quick Hatch / Instant Hatch | `Hatchery.lua` (`entry.Start + egg.HatchTime`): giảm `HatchTime` theo pass, hoặc đặt `Start` về quá khứ |
| Gói coins | `Monetization.lua` tự tính thu nhập ròng; dùng `Config.Rods`, `Config.AutoFisher.Tiers`, hàm mô phỏng chuyển sang Luau |
| Bonus Pedestal / Extra Incubator | `Config.AutoFisher.PedestalPrices`, `Config.Incubators.MaxSlots`, `HouseBuilder.lua` (thêm Part ổ thứ 6, máy ấp thứ 5) |
| Cosmetics | Module mới đọc `profile.Cosmetics`, `Models.lua` (biến thể model), `Pets.lua` (hiệu ứng pet) |
| Hộp thư quà (hội viên) | `House.lua` (`Daily` đang tắt) |

## 7. UI: bảng Store

- Thêm nút **STORE** vào dock bên phải (cạnh HOME / LAKE / SHOP) trong `MainUI.client.lua`, bảng mới `renderers.Store`, cùng phong cách hàng và nút hiện có.
- Mỗi sản phẩm hiện: tên, mô tả ngắn **bằng tiếng Anh**, hình, giá lấy từ Roblox (`MarketplaceService:GetProductInfoAsync`) để khỏi lệch giá.
- Gói coins hiện **số coins sẽ nhận** tính ra từ thu nhập của chính người chơi.
- **Song ngữ Anh và Việt** (đã chốt): mô tả sản phẩm, số coins nhận được, quyền lợi và điều kiện đều có cả hai ngôn ngữ. Đặt bảng chữ trong `Config.Monetization.Text = { [key] = { En = ..., Vi = ... } }`, chọn theo `LocalizationService` / `player.LocaleId` (mặc định tiếng Anh nếu không rõ). Chỉ phạm vi Store, không dịch phần còn lại của game.
- Vật phẩm ngẫu nhiên (nếu có): hiện bảng tỉ lệ ngay trong thẻ sản phẩm.

## 8. Theo dõi và vận hành

- Ghi log mỗi lần mua và cấp (`print` ở Studio, và `AnalyticsService` hay `DataStore` log nếu cần). Dùng để đối soát khiếu nại "mua mà không nhận".
- Nút công cụ quản trị tạm thời: lệnh trong Studio để cấp lại sản phẩm theo `PurchaseId` khi cần hỗ trợ khách (chỉ chạy ở server, chỉ tài khoản chủ game).
- Theo dõi tỉ lệ mua, món nào bán chạy, người chơi bỏ giữa chừng trước khi trả tiền.
- Mọi thay đổi giá trị sản phẩm đã bán phải **thêm** chứ không sửa bớt quyền lợi của người đã mua.

## 9. Kiểm thử

| Việc | Cách test |
|---|---|
| Luồng cấp, chống cấp hai lần | Gọi `ProcessReceipt` giả hai lần cùng `PurchaseId` trong Studio, kỳ vọng chỉ cấp một lần |
| Lưu lỗi | Giả lập `Data.Save` trả `false`, kỳ vọng `NotProcessedYet` và không mất tiền người chơi |
| Người chơi thoát giữa chừng | Giả lập `GetPlayerByUserId` trả `nil` |
| Giới hạn gói coins | Mua đủ 3 gói, gói thứ 4 bị từ chối kèm thông báo |
| Game Pass | Dùng tài khoản test thật trên experience chưa công khai, mua bằng Robux thật rồi hoàn lại nếu cần |
| Cân bằng | Chạy lại `tools/sim_economy.py` với quyền lợi mới (ổ thứ 6, ấp nhanh) trước khi bật bán |
