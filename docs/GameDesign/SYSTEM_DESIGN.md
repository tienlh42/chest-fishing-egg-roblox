# Thiết kế hệ thống: vật phẩm hiếm, nhà, ngỗng, cướp nhà

> Dành cho dev đọc sau. Mô tả **game có những thành phần gì và cơ chế từng thành phần ra sao**, gồm cả phần đã code và phần đã chốt thiết kế nhưng chưa code.
> Đọc kèm `docs/Overview/PROJECT_OVERVIEW.md` (kiến trúc code hiện tại) và `docs/ProjectManagement/DEVLOG.md` (lịch sử). File này là bản thiết kế đích, cập nhật lần cuối 14/10/2026.

## 0. Cách đọc file này

Mỗi mục có nhãn trạng thái:

| Nhãn | Nghĩa |
|---|---|
| **[ĐÃ CÓ]** | Đã code, đã chạy trong game. Số liệu lấy từ `Config.lua` và code lúc viết |
| **[ĐÃ CHỐT]** | Người dùng đã quyết, chưa code. Làm đúng như mô tả |
| **[ĐỀ XUẤT]** | Gợi ý của AI, người dùng chưa duyệt chi tiết (thường là con số). Có thể đổi khi cân bằng |
| **[CHƯA CHỐT]** | Còn câu hỏi mở, xem mục 12 |

Nếu code và file này khác nhau, **code là sự thật về hiện trạng**, còn file này là sự thật về hướng đi. Làm xong phần nào thì đổi nhãn phần đó và ghi `docs/ProjectManagement/DEVLOG.md`.

---

## 1. Tóm tắt vòng chơi

**Hiện tại [ĐÃ CÓ]:** lẻn ra hồ cấm, giữ nút kéo rương (ngỗng đi tuần) → rương vào túi tạm → chạy về nhà cất vào Stash → **coins và trứng được cộng thẳng vào tài khoản** → ấp trứng ra pet → pet đi theo, chặn ngỗng → coins mua cần câu, máy câu, máy ấp, nâng túi.

**Mục tiêu [ĐÃ CHỐT]:**

```
Cần câu --kéo--> Rương (5 cấp) --túi tạm, có thể bị ngỗng bắt--> Stash ở nhà (kho rương)
   Stash --mở rương--> Coins hoặc Trứng (5 cấp) --cất--> Kho trứng --đặt vào máy ấp--> Pet (5 cấp)
   Pet đi theo, chặn ngỗng ---> câu tiếp, kiếm coins ---> mua đồ tốt hơn
   Người khác (khi chủ online) có thể vào nhà lấy rương/trứng trong kho ---> ngỗng nhà + đồn cảnh sát chặn
```

Điểm khác lớn nhất so với hiện tại:
1. Cất Stash **không còn tự mở rương**. Rương nằm trong kho, mở là hành động riêng.
2. Đồ trong kho của người chơi **có thể bị người khác cướp**.
3. Ngỗng không chỉ ở hồ: mỗi nhà có ngỗng riêng, và có đồn cảnh sát.

---

## 2. Bản đồ thành phần

| Thành phần | File chính | Trạng thái | Vai trò |
|---|---|---|---|
| Config số liệu | `ReplicatedStorage/Config.lua` | [ĐÃ CÓ] | Mọi con số game |
| Model | `ReplicatedStorage/Models.lua` | [ĐÃ CÓ] | `Models.Get(name)`: model thật trong `CustomModels`, không có thì dựng model tạm |
| Profile / lưu trữ | `Modules/Data.lua` | [ĐÃ CÓ] | Dữ liệu người chơi, DataStore |
| Câu cá | `Modules/Fishing.lua` | [ĐÃ CÓ] | Giữ nút kéo, chọn rương theo Luck |
| Điểm câu hồ | `Modules/FishingSpots.lua` | [ĐÃ CÓ] | 6 phao CHEST, rương ra trước ngỗng |
| Túi tạm | `Modules/Bag.lua` | [ĐÃ CÓ], **sẽ đổi** | Đồ chưa cất, tối đa 4 món (nâng được 5, 6) |
| Stash | `Plots.lua` + `Bag.lua` | [ĐÃ CÓ], **sẽ đổi** | Hiện cộng thẳng vào profile. Sẽ thành kho rương |
| Mở rương | (chưa có) | [ĐÃ CHỐT] | Hành động riêng ở nhà |
| Ấp trứng | `Modules/Hatchery.lua` | [ĐÃ CÓ] | Ấp bằng `os.time`, nở cả khi offline |
| Pet | `Modules/Pets.lua` | [ĐÃ CÓ], **sẽ đổi** | Đi theo, chặn ngỗng, HP, hồi ở nhà |
| Gộp / tiến hóa pet | (chưa có) | [ĐÃ CHỐT] | Xem mục 7 |
| Máy câu tự động | `Modules/AutoFishers.lua` | [ĐÃ CÓ], **sẽ đổi** | Tích rương cả khi offline |
| Cần câu / Shop / Market | `Shop.lua`, `Market.lua` | [ĐÃ CÓ], **sẽ đổi** | Mua cần, bán trứng và pet |
| Ngỗng | `Modules/Guard.lua` | [ĐÃ CÓ], **sẽ mở rộng** | Hiện 1 ngỗng quanh hồ |
| Vùng an toàn | `Modules/SafeZone.lua` | [ĐÃ CÓ], **sẽ đổi** | Hiện là vùng chung. Sẽ theo từng người |
| Nhà | `HouseBuilder.lua`, `House.lua`, `Plots.lua` | [ĐÃ CÓ] | Plot 90x90, nhà gỗ, Stash, ổ pet, kệ, máy ấp |
| Dịch chuyển | `Modules/Teleports.lua` | [ĐÃ CÓ] | Có phí, bị chặn khi túi có đồ |
| Cướp nhà | (chưa có) | [ĐÃ CHỐT] | Xem mục 9 |
| Ngỗng nhà, ngỗng đồn | (chưa có) | [ĐÃ CHỐT] | Xem mục 8 |
| Đồn cảnh sát (công trình) | `MapBuilder.lua` | [ĐÃ CHỐT] | Chưa có vị trí chính thức |
| Độ hiếm 5 cấp | `Config.Rarity` (chưa có) | [ĐÃ CHỐT] | Xem mục 3 |
| Model đẹp | repo `roblox-assets` | Có sẵn, **chưa thử trong Studio** | Xem mục 10 |

---

## 3. Thang độ hiếm 5 cấp [ĐÃ CHỐT]

Một thang dùng chung cho **rương, trứng, pet, cần câu, máy câu**. Thứ tự và màu theo `roblox-assets/STYLE_GUIDE.md`.

| Cấp (`Rarity`) | Tên hiển thị | Màu | Hiệu ứng |
|---|---|---|---|
| `Common` | Common | Trắng `#F5F5F0` | Không |
| `Rare` | Rare | Xanh `#3DB8F5` | Viền sáng |
| `Epic` | Epic | Tím `#9B6BFF` | Viền sáng, vài hạt |
| `Legendary` | Legendary | Vàng `#F2C230` | Hào quang xoay, tia sáng |
| `Mythic` | Mythic | Cầu vồng | Hào quang cầu vồng, tia sáng, hạt bay |

Code cần có một bảng `Config.Rarity` (thứ tự, màu, tên) để mọi nơi tra, không rải chuỗi `"Common"`, `"Rare"` khắp code.

**Ghi chú tương thích:** hiện `Config.Eggs` đã dùng khoá `Common`, `Rare` (và `Starter`) và profile lưu số trứng theo các khoá đó. Giữ nguyên các khoá cũ, thêm `Epic`, `Legendary`, `Mythic`. Không đổi tên khoá cũ, nếu không dữ liệu đã lưu bị hỏng.

### 3.1 Ánh xạ vật phẩm sang model của `roblox-assets`

| Cấp | Rương | Trứng | Pet | Cần câu | Máy câu |
|---|---|---|---|---|---|
| Common | Wooden | Starter, Reed | CatPot, DogBaker | Starter, Catfish | Common |
| Rare | Golden | Bubble | DuckMuscle | Turtle | Rare |
| Epic | Diamond (**tên chưa chốt**) | Crystal | CatMagician | Fox | Epic |
| Legendary | (mới) | Gold | DogK9 | Cat | Legendary |
| Mythic | (mới) | Dragon | DragonOffice | Dragon | Mythic |

Tên rương Epic, Legendary, Mythic và tên các cần mới là **[CHƯA CHỐT]**. Config hiện có `Wooden / Golden / Diamond Chest`, 4 cần `Basic / Sturdy / Pro / Legend`, 5 pet `Cat / Dog / Fox / Dragon / Phoenix`. Các tên này là đồ tạm của MVP và sẽ được thay theo bảng trên (kèm chuyển đổi dữ liệu đã lưu).

---

## 4. Câu cá và rương

### 4.1 Hiện tại [ĐÃ CÓ]

Chi tiết cơ chế câu (giữ nút, câu lén, điểm rơi phao, hụt) xem `docs/Overview/PROJECT_OVERVIEW.md` mục 5. Phần liên quan độ hiếm:

- `Fishing.lua` chọn rương bằng `Config.WeightedRoll(Config.Chests, luck)` với `luck = rod.Luck × (Lake ? Config.Fishing.LakeLuck : 1)`. Thời gian kéo = `chest.HoldTime × rod.Speed × (Pond ? PondTimeMult : 1)`.
- **Rương tung sẵn nội dung ngay lúc câu:** `Fishing.RollReward` ra `coins` và `egg` (qua `Config.RollChestEgg`), túi giữ `{ Chest, Coins, Egg }`.
- Hồ cấm (`Lake`): rương vào túi tạm. Ao nhà (`Pond`): rương vào thẳng tài khoản, kéo chậm hơn, ít may mắn hơn.

Số liệu rương hiện tại:

| Rương | Weight | Coins | HoldTime | Trứng (xét từ trên xuống) |
|---|---|---|---|---|
| Wooden | 70 | 5-15 | 6 | Common 30% |
| Golden | 25 | 20-60 | 10 | Rare 15%, rồi Common 60% |
| Diamond | 5 | 100-300 | 14 | Rare 60%, rồi Common 100% |

### 4.2 Công thức Luck cần thiết kế lại [ĐÃ CHỐT là phải sửa, công thức mới CHƯA CHỐT]

> **Cập nhật 15/10/2026:** đề xuất thay công thức Luck bằng **bảng tỉ lệ rương riêng cho từng cần và từng máy câu**, kèm giá, thu nhập và luật cướp: xem `docs/Economy/ECONOMY_DESIGN.md` mục 3, 4, 5. Phần dưới giữ lại để biết vì sao phải sửa.

`WeightedRoll` nhân trọng số thứ `i` với `luck^(i-1)`. Với Legend Rod (Luck 4) ở hồ (×1.5 = 6) và 3 rương, trọng số thành 70 / 150 / 180, tức Diamond chiếm khoảng 45%. Khi lên 5 rương, rương cuối bị nhân 6⁴ = 1296 và trở thành loại phổ biến nhất.

Cần công thức có trần (ví dụ tăng tuyến tính theo vị trí, hoặc giới hạn hệ số tối đa). Con số mục tiêu em đề xuất để tinh chỉnh, **[ĐỀ XUẤT]**:

| | Common | Rare | Epic | Legendary | Mythic |
|---|---|---|---|---|---|
| Cần Basic, hồ | ~60% | ~28% | ~10% | ~2% | ~0.2% |
| Cần tốt nhất, hồ | ~15% | ~25% | ~30% | ~22% | ~8% |

### 4.3 Rương 5 cấp [ĐÃ CHỐT số cấp, số liệu ĐỀ XUẤT]

| Cấp | Thời gian kéo | Coins (trung bình) |
|---|---|---|
| Common | 6s | ~10 |
| Rare | 10s | ~40 |
| Epic | 14s | ~150 |
| Legendary | 18s | ~600 |
| Mythic | 22s | ~2500 |

Nguyên tắc thiết kế: rương hiếm kéo lâu hơn, nên **gây tiếng động lâu hơn** (`NoiseDelay` 3s, `NoiseRadius` 45), tức rủi ro cao hơn phần thưởng. Giá trị tăng khoảng 4 lần mỗi cấp.

---

## 5. Túi tạm, Stash và mở rương

### 5.1 Túi tạm

- **[ĐÃ CÓ]** `Bag.lua`: `items[player] = { { Chest, Coins, Egg } }`, sức chứa 4, nâng lên 5 rồi 6 ở Tool Shop (300 / 1200 coins), **không lưu DataStore**. Chết ngoài vùng an toàn thì mất hết.
- **[ĐÃ CHỐT]** Túi chứa **rương và trứng**, tối đa 4 món. Túi có đồ nghĩa là "khả nghi", ngỗng nhìn thấy sẽ rượt. Túi rỗng thì ngỗng bỏ qua.
- **[ĐÃ CHỐT]** Ngỗng bắt = mất hết đồ trong túi (giữ luật hiện tại).
- **[ĐỀ XUẤT]** Giữ nâng cấp túi (5, 6 ô) nếu người dùng không bảo bỏ. Túi cũng là giới hạn số món cướp được trong một lượt.

### 5.2 Stash thành kho rương [ĐÃ CÓ từ 15/10/2026, DEVLOG #39]

> Đã code: `profile.Chests = { [tên rương] = số lượng }`, `Bag.Deposit` chỉ chuyển rương vào kho, `Stash.lua` mở rương (tung lúc mở, mở tức thì, phải đứng gần Stash). Rương từ ao và máy câu vẫn mở ngay. Phần mô tả dưới là thiết kế gốc.

Hiện `Bag.Deposit` cộng ngay `coins` và `eggs` vào profile rồi lưu (nếu lưu lỗi thì hoàn lại). Thiết kế mới:

- Profile thêm **kho rương** theo cấp, ví dụ `Chests = { Common = 3, Rare = 1 }`, và **kho trứng** (đã có `Eggs`, mở rộng 5 cấp).
- Cất vào Stash chỉ **chuyển rương từ túi vào kho**, chưa tung nội dung. Giữ cơ chế "lưu xong mới coi là cất" như hiện tại.
- Chỉ **chủ nhà** cất được (prompt Stash đã gắn `OwnerId`, xem `Plots.MakeOwnerPrompt`).

### 5.3 Mở rương [ĐÃ CHỐT hành động, thời điểm tung kết quả là ĐỀ XUẤT]

- Mở là hành động riêng ở nhà, ra **coins hoặc trứng**. Trứng vào kho trứng để đem đi ấp.
- **[ĐỀ XUẤT]** Tung nội dung **lúc mở**, không tung lúc câu như hiện tại. Lý do: kẻ cướp lấy rương mà không biết bên trong, và người chơi không thể thoát game để dò kết quả.
- **[ĐỀ XUẤT]** Mở tức thì kèm animation `Open` của model rương. Nếu thêm thời gian chờ thì phải cân nhắc vì rương nằm kho càng lâu càng dễ bị cướp.
- **[CHƯA CHỐT]** Rương từ **ao nhà** và từ **máy câu tự động** hiện vào thẳng tài khoản. Sau khi đổi, chúng có vào kho rương (và bị cướp được) hay vẫn mở ngay thì chưa quyết.

---

## 6. Trứng, ấp trứng, pet

### 6.1 Trứng và ấp

- **[ĐÃ CÓ]** `Config.Eggs`: Common (ấp 10s), Rare (20s), (Starter Egg đã bỏ 15/10/2026: người mới được tặng 1 Reed Egg). `Hatchery.lua` lưu `profile.Incubators[slot] = { Tier, Start = os.time() }` nên **nở được cả khi offline**. Nở xong tung pet bằng `Config.WeightedRoll(egg.Pets)`.
- Máy ấp: bắt đầu 1, tối đa 4 (mua máy 2, 3, 4 giá 300 / 1500 / 6000).
- **[ĐÃ CHỐT]** Trứng 5 cấp. Trứng **cất được** trong kho rồi đem đi ấp. Trứng **đã đặt vào máy ấp thì không bị cướp** (**[ĐỀ XUẤT]**: khuyến khích người chơi ấp ngay).
- **[ĐỀ XUẤT]** Trứng cấp X nở ra pet **cấp X** (cấp Common có 2 pet), kèm một xác suất nhỏ nở ra pet cấp X+1. Hiện mỗi trứng có pool 3 pet.

### 6.2 Pet

- **[ĐÃ CÓ]** `Pets.lua`: pet mới nhất đi theo người chơi. HP chỉ tồn tại trong phiên, hồi đầy sau 40s khi đứng ở nhà (nhanh gấp 2.5 lần cạnh ổ pet). Ngỗng đánh 5 HP/s. Pet cứ 5 giây làm ngỗng khựng 1.2s. Pet gục thì ngỗng bắt người.
- **[ĐÃ CHỐT]** **Pet chỉ để bảo vệ.** Không cộng Luck, không cộng coins.
- **[ĐÃ CHỐT]** Pet 6 loại theo model assets (xem mục 3.1). Vai trò chống ngỗng theo gợi ý của repo assets, đều là phòng thủ **[ĐỀ XUẤT số]**:

| Pet | Cấp | Vai trò | Tham số có thể chỉnh |
|---|---|---|---|
| CatPot (đã bỏ 15/10/2026) | Common | Chống đỡ cơ bản, gõ nồi báo động khi yếu | HP |
| DogBaker | Common | Rơi vụn bánh, ngỗng dừng ngắn | `StunTime` |
| DuckMuscle | Rare | Chịu đòn lâu nhất | HP cao nhất |
| CatMagician | Epic | Ngỗng choáng lâu hơn | `StunTime` |
| DogK9 | Legendary | Ngỗng khựng lâu, chào kiểu cảnh sát | `StunTime`, `StunEvery` |
| DragonOffice | Mythic | Phun khói làm ngỗng lạc hướng | `LoseTime` ngắn hơn |

- **[ĐÃ CHỐT]** Pet trùng: **bán** hoặc **gộp**.

### 6.3 Gộp và tiến hóa pet [ĐÃ CHỐT hướng, điều kiện CHƯA CHỐT]

Theo `roblox-assets/Pet/PLAN_EVOLUTION.md`:
- Tối đa **3 dạng** (`Stage` 1, 2, 3). Cùng một model, size nhân 1.0 / 1.2 / 1.4 (nhân trên hệ số độ hiếm), phụ kiện cộng dồn.
- Game đặt attribute `Stage` trên model pet. Muốn đổi size phải `ScaleTo` và nhân `HipHeight` (chưa kiểm chứng với rig tự dựng này).
- Gộp pet trùng để lên dạng. **[CHƯA CHỐT]** cần mấy pet trùng cho mỗi bậc và tăng bao nhiêu HP.
- Giá bán pet phải thấp hơn giá trị giữ lại, tránh bán hết pet lấy tiền.

---

## 7. Cần câu, máy câu, kinh tế

### 7.1 Cần câu

- **[ĐÃ CÓ]** 4 cần (`Config.Rods`): Basic (miễn phí), Sturdy 250, Pro 1500, Legend 8000, với `Luck` 1 / 1.5 / 2.5 / 4 và `Speed` 1 / 0.85 / 0.7 / 0.5. Dép Tên Lửa 2000 coins (+10% tốc độ).
- **[ĐÃ CHỐT]** 6 cần theo model assets (Starter, Catfish, Turtle, Fox, Cat, Dragon), mỗi cấp một cây trừ Common có hai. Giá và `Luck`, `Speed` là **[ĐỀ XUẤT]**, cần mô phỏng cân bằng sau khi sửa công thức Luck.

### 7.2 Máy câu tự động

- **[ĐÃ CÓ]** Tối đa 4 máy (giá 500 / 1500 / 4000 / 10000), 30 giây ra 1 rương, kho 20, `Luck` cố định 1, tích cả khi offline.
- **[ĐÃ CHỐT]** Máy 5 cấp theo model assets. Model hỗ trợ 3 ổ cần (`Slots` 1-3) và túi cá phồng (`Fill` 0-3).
- **[ĐỀ XUẤT]** Hai trục nâng cấp: cấp của máy (đổi `Luck`, `Interval`) và số ổ cần (mua từng ổ). `Fill = ceil(stored / capacity × 3)`.

### 7.3 Nguồn tiền và chỗ tiêu (định hướng "mua nhiều thứ về sau")

Chỗ tiêu hiện có: cần câu, máy câu, máy ấp, nâng túi, Dép Tên Lửa, dịch chuyển (Lake 20, Shop 10, Home 10).
Chỗ tiêu dự kiến **[ĐỀ XUẤT]**: cần cấp cao, nâng cấp máy câu, khóa cửa nhà (chống cướp), gộp pet, các vật phẩm trang trí về sau.

---

## 8. Ngỗng

> **15/10/2026 (DEVLOG #42):** đã code ngỗng nhà (vòng sân, chỉ rượt kẻ bị truy nã), ngỗng đồn (gọi khi báo động, tối đa 3). Chưa code: thang nghi ngờ đầy đủ (8.3), công trình đồn.

### 8.1 Ba loại ngỗng [ĐÃ CHỐT]

| Loại | Số lượng | Tuần tra | Khi nào hành động |
|---|---|---|---|
| **Ngỗng hồ** [ĐÃ CÓ] | 1 | 12 điểm quanh lối gạch quanh hồ | Thấy người **đang kéo** (nhìn xa 40 stud) hoặc người **túi có đồ** (nhìn gần 10 stud) |
| **Ngỗng nhà** | 1 cho mỗi người chơi đang có nhà | **Đi vòng tròn quanh nhà** (bên trong hàng rào) | Thấy người lạ có hành vi bất thường (mục 8.3), hoặc hết giờ ở nhà người khác (mục 8.4) |
| **Ngỗng đồn cảnh sát** | Sinh khi có người cướp, tối đa 3 mỗi vụ **[ĐỀ XUẤT]** | Không tuần, chỉ xuất hiện khi có cướp | Truy đuổi kẻ cướp, xong thì về đồn và biến mất |

Tổng số ngỗng cố định = **số người chơi + 1** (mỗi người một ngỗng nhà, cộng một ngỗng hồ). Thay cho `Config.Guard.Count = 1` hiện tại. Plot có 8 chỗ nên tối đa 8 người chơi và 9 ngỗng cố định. Nên có trần tổng số ngỗng cùng lúc (**[ĐỀ XUẤT]** khoảng 16).

### 8.2 Vòng tuần của ngỗng nhà [ĐÃ CHỐT hình thức, số ĐỀ XUẤT]

- Plot 90x90, hàng rào ở cách tâm 44.5 stud, cổng ở mặt trước (`HouseBuilder.lua`).
- Ngỗng đi **vòng tròn bán kính khoảng 35-38 stud** quanh tâm plot, tốc độ 10 stud/s (khoảng 22 giây một vòng). Điểm tuần sinh bằng toán từ tâm plot nên không cần pathfinding dài. Cần kiểm tra bố cục sân (ao, kệ, cây) xem có vật cản trên vòng không.
- Ngỗng nhà **bỏ qua chủ nhà**.
- Ngỗng nhà **không bám theo xa** quá khoảng 60 stud tính từ plot. Quá thì quay về vòng, và ngỗng đồn cảnh sát tiếp quản.
- Chỉ dựng ngỗng nhà cho plot đang có chủ (plot chỉ có chủ khi người đó online).

### 8.3 Theo dõi hành động bất thường: thang nghi ngờ [ĐÃ CHỐT ý tưởng, trọng số ĐỀ XUẤT]

Hiện `Guard.lua` chỉ có trạng thái `Suspicious` 2 giây rồi `Chase` (hoặc bỏ qua nếu người đó thôi khả nghi). Thiết kế mới: mỗi người chơi có **điểm nghi ngờ** trên server. Điểm **chỉ tăng khi có ngỗng thấy** (dùng lại `canSee`: tầm nhìn, góc nhìn, đường nhìn thông), nhiều ngỗng thấy thì cộng dồn. Điểm giảm dần khi hành vi bình thường.

| Hành vi | Mức tăng |
|---|---|
| Đang kéo câu | Đuổi ngay như hiện tại |
| Túi có đồ, đang ở sân người khác | Nhanh |
| Giữ [E] ở Stash người khác | Tối đa ngay, báo động đồn cảnh sát |
| Đứng gần Stash người khác (≤ 10 stud) | Khá nhanh |
| Chạy nước rút trong sân người khác | Vừa |
| Lảng vảng ở sân người khác quá lâu (túi rỗng) | Chậm |
| Ra vào cùng một sân nhiều lần | Vừa (tùy chọn) |

Ngưỡng: dưới ngưỡng 1 bình thường; qua ngưỡng 1 ngỗng "Honk?", nhìn theo và đi lại gần; qua ngưỡng 2 thì đuổi. Chủ nhà không bao giờ tăng điểm trong sân mình. Client nhận thông báo để hiện biểu tượng "bị theo dõi" (chữ tiếng Anh).

Phát hiện gian lận kỹ thuật (dịch chuyển bất thường, tốc độ giả) là việc khác, kiểm tra riêng trên server, không dùng ngỗng.

### 8.4 Đồng hồ 60 giây khi vào nhà người khác [ĐÃ CHỐT]

1. Người không phải chủ bước vào **sân** nhà người khác thì đếm ngược **60 giây**. (Tính theo sân vì Stash nằm ở sân trước. Nếu người dùng muốn tính riêng bên trong nhà gỗ thì sửa lại, xem mục 12.)
2. Client hiện đồng hồ (chữ tiếng Anh, ví dụ "Leave in 45s"). **[ĐỀ XUẤT]** còn khoảng 20 giây thì chuyển đỏ và ngỗng nhà "Honk?".
3. Ra khỏi sân kịp thì dừng. Hết giờ mà chưa ra thì **ngỗng nhà rời vòng, chui vào rượt và đánh**.
4. Pet chặn bình thường. Pet gục thì bị bắt: mất đồ trong túi, về nhà mình miễn phí (như luật bị bắt hiện tại).
5. Đồng hồ **độc lập** với thang nghi ngờ: người túi rỗng, không khả nghi vẫn bị đuổi sau 60 giây.
6. **[ĐỀ XUẤT]** Chống lách bằng ra rồi vào lại: thời gian đã đếm **giảm dần** (khoảng 1 giây mỗi 2 giây ở ngoài), không về 0 ngay.
7. Số 60 đặt trong `Config.Guard.House` (ví dụ `TrespassTime = 60`).

---

## 9. Cướp nhà [ĐÃ CHỐT]

> **Cập nhật 15/10/2026 (đè lên phần dưới khi khác nhau):** cướp phải dùng **Chìa vạn năng** (tỉ lệ mở 50%, tiêu mỗi lần thử, chủ nhà mua khóa để giảm tỉ lệ). Mục tiêu cướp được là **kho nhà** và **kho trong máy câu**. Kẻ cướp **tự chọn** món, tối đa bằng số ô túi trống (không còn "giữ [E] lấy 1 món"). **Kho nhà không giới hạn ô**, túi mang trên người thì có giới hạn và phải về nhà cất. Chi tiết và số liệu: `docs/Economy/ECONOMY_DESIGN.md` mục 7. Mọi vật phẩm (cần, máy câu, pet) cũng có **độ bền** và biến mất khi hết (`docs/Economy/ECONOMY_DESIGN.md` mục 6).

**Điều kiện:** chỉ cướp được nhà của người **đang online**. Plot chỉ có chủ khi người đó trong game, nên khớp với `Plots.lua` hiện có (thu hồi plot khi chủ thoát).

**Lấy được gì:** rương và trứng trong kho. **Không** lấy được coins, pet. **[ĐỀ XUẤT]** trứng đã đặt vào máy ấp cũng an toàn.

**Luồng:**
1. Người lạ vào sân (đồng hồ 60s bắt đầu).
2. Giữ [E] ở Stash người khác vài giây để lấy 1 món. Món lấy được vào **Túi tạm của kẻ cướp**, không vào kho của họ ngay. Túi 4 ô nên tối đa 4 món mỗi lượt (có thể ít hơn nếu túi đã có đồ).
3. Lấy **món đầu tiên** thì báo động: chủ nhà nhận thông báo kèm tên kẻ cướp, **đồn cảnh sát sinh ngỗng** (thêm ngỗng khi lấy thêm món, tối đa 3), ngỗng nhà nhập cuộc.
4. Kẻ cướp phải chạy về **nhà mình** để cất. Pet của họ chặn ngỗng như bình thường. Dịch chuyển bị chặn khi túi có đồ nên không trốn bằng teleport được.
5. Về tới nhà mình và cất vào Stash của mình: món cướp thuộc về họ.
6. **Bị ngỗng bắt:** đồ cướp được **trả về Stash chủ nhà** (**[ĐÃ CHỐT]** mặc định), kẻ cướp về nhà mình.

**Chống phá game:**
- **[ĐỀ XUẤT]** "Khiên" khoảng 5-10 phút sau khi bị cướp.
- **[ĐỀ XUẤT]** Người mới còn trong hướng dẫn không bị cướp.
- **[ĐỀ XUẤT]** Khóa cửa nhà nâng cấp bằng coins (thêm chỗ tiêu tiền).

**Yêu cầu kỹ thuật:**
- Lấy đồ chạy hoàn toàn trên server, có **khoá theo plot** để hai người không lấy cùng một món (chống sao chép đồ).
- Lấy xong phải lưu cả hai profile theo cách không để lệch (một bên mất, một bên chưa có).
- Chủ nhà thoát game giữa lúc đang có người trong sân: plot bị thu hồi, người trong sân cần được đưa ra ngoài. Đồ đã lấy vẫn thuộc kẻ cướp, ngỗng đồn vẫn đuổi tiếp. Cần kiểm tra hàm thu hồi plot hiện có.

---

## 10. Vùng an toàn theo từng người [ĐÃ CHỐT phải đổi]

**Hiện tại [ĐÃ CÓ]:** `SafeZone.Contains(position)` kiểm tra toàn map: nằm trong **bất kỳ** hộp an toàn nào (quanh mỗi nhà và quanh Spawn) là an toàn. Dùng ở 5 chỗ: `Bag.lua` (chết có mất đồ không), `Fishing.lua` (không câu trong vùng an toàn), `Guard.lua` (ngỗng không vào, có 2 chỗ), `Pets.lua` (hồi HP).

**Vấn đề với cướp nhà:** kẻ cướp đứng trong sân nạn nhân vẫn được coi là an toàn, ngỗng không vào được, pet hồi máu, đồ không mất khi chết.

**Thiết kế mới:** "an toàn" chỉ áp dụng cho **nhà của chính mình** (và điểm hồi sinh), không phải mọi nhà. Ngỗng được vào sân người khác (nhưng không vào sân của người mà chúng đang đuổi khi họ về tới nhà mình). Prompt cất đồ tiếp tục chỉ dành cho chủ.

---

## 11. Dữ liệu (profile)

**Hiện tại [ĐÃ CÓ]** (`Data.lua`):

```
Coins, Eggs = { Common = n, Rare = n, Starter = n }, Pets = { "Cat", "Dog", ... },
Rods = { Basic = true }, EquippedRod,
IncubatorSlots, Incubators = { ["1"] = { Tier, Start } },
AutoFishers = { ["1"] = { Last, Stored } },
BagLevel, LastDaily, Gear = { RocketSandals = true },
Tutorial, StarterGiven
```

`Data.Get`, `Data.Update(player)` (sửa profile xong phải gọi), `Data.Save`, `Data.Spend`. DataStore `PlayerData_v2` (tự chuyển từ v1). `reconcile` tự bổ sung trường mới còn thiếu nên thêm trường vào `defaultProfile()` là đủ.

**Dự kiến thêm [ĐỀ XUẤT]:**
- `Chests = { Common = n, Rare = n, Epic = n, Legendary = n, Mythic = n }`: kho rương chưa mở.
- `Eggs`: thêm khoá `Epic`, `Legendary`, `Mythic`.
- `Pets`: hiện là danh sách tên. Khi có `Stage` và gộp, cần đổi thành bản ghi có `Name` và `Stage`. Cần chuyển đổi dữ liệu cũ.
- `ShieldUntil` (khiên sau khi bị cướp), thông tin khóa cửa.
- Mọi đổi tên pet, cần câu, rương cần bước chuyển đổi dữ liệu đã lưu (tham khảo `migrateV1`).

**Không lưu DataStore:** túi tạm, HP pet, điểm nghi ngờ, đồng hồ 60 giây, ngỗng.

---

## 12. Điều còn mở [CHƯA CHỐT]

1. Tên rương Epic, Legendary, Mythic và các cần câu mới.
2. Rương từ ao nhà và máy câu tự động có vào kho rương (bị cướp được) hay mở ngay?
3. "Nhà người khác" trong luật 60 giây là cả sân hay chỉ bên trong nhà gỗ? (Hiện tài liệu này lấy cả sân.)
4. Gộp pet: cần mấy pet trùng, tăng bao nhiêu.
5. Công thức Luck mới và toàn bộ con số cân bằng (cần chạy mô phỏng thời gian kiếm tiền).
6. Vị trí đồn cảnh sát (đề xuất một góc trống trên đường vòng như 135° hoặc 315°, chưa kiểm tra `MapBuilder.lua`).
7. Bạn bè đến thăm: hiện coi như người lạ. Về sau có thể thêm "chủ nhà cho phép khách".
8. Nếu rương hoặc trứng ngẫu nhiên bán bằng Robux (hoặc bằng coins mua được bằng Robux), phải hiện tỉ lệ từng kết quả (chính sách Paid Random Items, xem `roblox-assets/ITEM_SYSTEM_WORKFLOW.md` mục 3). Game hiện chỉ dùng coins kiếm trong game nên chưa vướng, nhưng nên làm bảng tỉ lệ ở UI từ đầu.

---

## 13. Model và assets

Nguồn: repo `roblox-assets` (cạnh repo game). Repo đó **chỉ làm model, animation, hiệu ứng, sound**, không có logic game.

**Hợp đồng giữa game và model (attribute trên model):**

| Loại | Attribute game đặt | Giá trị `Anim` |
|---|---|---|
| Chung | `Rarity` đã đặt sẵn trong model | |
| Rương | `Anim` | `Spawn`, `Idle`, `Open`, `Vanish` |
| Trứng | `Anim`, `Progress` (0-1) | `Idle`, `Incubate`, `Hatch` |
| Pet | `Anim`, `Stage` (1-3) | `Idle`, `Walk`, `Run`, `Attack`, `Hurt`, `Exhausted`, `Happy`, `Job`, `Evolve` (sắp có) |
| Cần câu | `Anim` | `Idle`, `Cast`, `Reel`, `Catch`, `Miss` |
| Máy câu | `Anim`, `Slots` (1-3), `Fill` (0-3) | `Idle`, `Work`, `Catch`, `Full`, `Collect` |

- Tên model: `TreasureChest_<Tier>`, `Egg_<Tên>`, `Pet_<Tên>`, `Rod_<Tên>`, `AutoFisher_<Tier>`. Game tra bằng `Models.Get`.
- Muốn phát lại animation không lặp thì đổi `Anim` sang tên khác trước rồi đặt lại.
- Pet là rig R15 có `Humanoid` (đi theo bằng `MoveTo`). `Models.lua` đang yêu cầu `HumanoidRootPart` cách chân 2.5 stud, cần kiểm tra rig pet mới có khớp không.

**Rủi ro tích hợp:**
- README của mọi loại model đều ghi **"chưa mở thử trong Roblox Studio"**. Phải thử mỗi loại trước khi đổi sang dùng.
- Repo assets khuyên để bản mẫu trong `ServerStorage` (script hiệu ứng chạy phía client), còn game đang lấy từ `ReplicatedStorage > CustomModels`. Chưa xác minh script có chạy trên bản mẫu không.
- Âm thanh chưa upload, id trong các script `*Sounds.client.luau` còn trống nên model vẫn chạy nhưng im lặng.
- Model Thần thoại nhiều part (rương Mythic 134, trứng Gold 183). Khi nhiều model cùng hiện trên mobile chỉ bật hiệu ứng cho cái ở gần.

---

## 14. Quy tắc dev (nhắc lại)

- **Server quyết định mọi kết quả.** Client chỉ gửi yêu cầu. Mọi hành động mới (mở rương, lấy đồ cướp, gộp pet) là `Action` trên server, kiểm tra dữ liệu client gửi lên.
- Mọi con số nằm trong `ReplicatedStorage/Config.lua`. Sửa profile xong gọi `Data.Update(player)`.
- Chữ hiện cho người chơi **tiếng Anh**. Comment code và tài liệu **tiếng Việt**.
- Sửa script ở file `.lua`, không sửa trong Studio (Rojo ghi đè). Chạy `selene .` trước khi báo xong.
- Thêm tính năng dùng `Models.Get` + `CustomModels`, không chờ có model thật.
- Làm xong mỗi việc: thêm mục trên cùng `docs/ProjectManagement/DEVLOG.md` và cập nhật tài liệu liên quan, kể cả file này.

---

## 15. Thứ tự triển khai đề xuất

1. Thử 1 model mỗi loại (rương, trứng, pet, cần, máy) trong Studio.
2. `Config.Rarity` và sửa công thức Luck có trần.
3. Rương 5 cấp, Stash thành kho rương, hành động mở rương.
4. Trứng, pet (6 loại), cần câu (6), máy câu (5 cấp), kèm chuyển đổi dữ liệu cũ.
5. Vùng an toàn theo từng người.
6. Tổng quát hóa `Guard.lua` (nhiều ngỗng, nhiều loại, thang nghi ngờ).
7. Cướp nhà, ngỗng nhà, đồng hồ 60 giây, đồn cảnh sát.
8. Gộp pet và tiến hóa.
9. Bảng tỉ lệ ở UI và mô phỏng cân bằng kinh tế.

Bước 5, 6, 7 phụ thuộc nhau nên làm gần nhau.
