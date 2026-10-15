# Thiết kế kinh tế: kiếm tiền bằng farm (câu, máy câu, cướp) + độ bền

> Dành cho dev đọc sau. Mô tả **tiền từ đâu ra, tiêu vào đâu, và vì sao con số như vậy**. Cập nhật lần cuối 15/10/2026 (bản 2: thêm độ bền, chìa vạn năng, kho vô hạn).
> Đọc kèm `SYSTEM_DESIGN.md` (rương, trứng, pet, ngỗng, cướp nhà) và `PROJECT_OVERVIEW.md` (code hiện tại).
> Số liệu lấy từ `tools/sim_economy.py` (mô phỏng giá trị kỳ vọng). Muốn đổi số: sửa script, chạy lại, rồi chép vào `Config.lua`.

## 0. Nhãn trạng thái và các điều đã chốt

| Nhãn | Nghĩa |
|---|---|
| **[ĐÃ CÓ]** | Đã code |
| **[ĐÃ CHỐT]** | Người dùng đã quyết, chưa code |
| **[ĐỀ XUẤT]** | AI đề xuất, số lấy từ mô phỏng, chưa test với người chơi thật |

**Đã chốt (anh Scott, 15/10/2026):**
1. Người chơi **equip cần câu và pet tự do**.
2. **Mọi nâng cấp chỉ bằng coins.** Không có nguyên liệu phụ.
3. **Chưa tính Robux.** Tiền kiếm bằng farm trong game: câu, máy câu, cướp.
4. **Mọi vật phẩm có độ bền; hết bền thì biến mất:** cần câu, máy câu, pet.
5. **Cướp cần Chìa vạn năng (Master Key), tỉ lệ mở 50% mỗi lần dùng.**
6. **Mỗi vụ cướp, kẻ cướp tự chọn số rương tối đa bằng số ô túi trống.** Cướp được ở **máy câu** và **kho**.
7. **Ô mang trên người (túi) có giới hạn, phải về nhà cất vào kho. Kho không giới hạn số ô.**
8. **Không cho sửa chữa.** Hết bền là mất, không có ngoại lệ trả phí. Chỉ có cách mua lại (cần, máy) hoặc tìm trứng mới (pet).
9. **Mọi pet như nhau về độ bền.** **Không còn Chef Cat và Starter Egg** (đã bỏ khỏi game).
10. **Người chơi mới chỉ có 1 cần mặc định (Duckling) và 1 Reed Egg (trứng cơ bản):** không có pet, không có máy câu, 0 coins, 0 chìa. (Giữ 1 máy ấp sẵn vì là hạ tầng nhà.)

### 0.1 Hệ quả của việc "ban đầu chỉ có cần mặc định + 1 Reed Egg" [ĐÃ CÓ từ 15/10/2026]

- **Có pet ngay:** Reed Egg tặng ấp 10 giây ra Baker Dog (tự equip). Có pet rồi thì ra hồ được ngay (hồ ~37 coins/phút, ao ~23 coins/phút), nên mốc tiến độ vẫn như mô phỏng gốc (Catfish ~phút 4). Ao nhà là chỗ an toàn khi chưa dám ra hồ.
- **Đã bỏ Chef Cat và Starter Egg** khỏi `Config` (Eggs, EggOrder, Pet.Stats, SellPrices). Còn 5 pet: Baker Dog (Common), Muscle Duck (Rare), Magician Cat (Epic), K9 Dog (Legendary), Office Dragon (Mythic). Asset `Egg_Starter`, `Pet_CatPot` vẫn nằm trong `Assets/Models` nhưng không dùng.
- **`Tutorial.lua`:** bước 1 giờ là "ấp Reed Egg được tặng" (`Data.Load` tặng 1 Reed thay vì Starter), nên 3 bước hướng dẫn giữ nguyên.
- **Mô phỏng tiến độ:** giữ nguyên bảng ở mục 9 (người mới có pet gần như ngay từ đầu).

## 1. Vòng kiếm tiền

```
                  COINS ◄────────────────────────────────────────────────┐
                    │ mua / mua lại khi hỏng                               │
   ┌────────────────┼────────────────┬───────────────┐                    │
   ▼                ▼                ▼               ▼                    │
 Cần câu (6)    Máy câu          Máy ấp (4)     Túi / Giày / Khóa cửa / Chìa vạn năng
 HAO MÒN        (5 ổ, mỗi máy                                               │
 (Duckling      5 tier) HAO MÒN                                             │
 không hỏng)         │                                                      │
   │ kéo ở hồ        │ tích kho máy (đầy sau ~30 phút, kể cả offline)       │
   └───────┬─────────┘                                                      │
           ▼                                                                │
     RƯƠNG 5 cấp ──Túi (4-6 ô)──► KHO nhà (vô hạn) ──mở──► Coins ───────────┤
           │                                                                │
           └──► Trứng ──ấp──► Pet (equip tự do, HAO MÒN khi chặn ngỗng)     │
                  │ bán ───────────────────────────────────────────────────┘
                  ▼
   Rương trong KHO / trong MÁY CÂU / trứng chưa ấp ◄── CƯỚP NHÀ (kẻ cướp dùng Chìa vạn năng, tự chọn món, chuyển vế)
```

| Nguồn | Vai trò | Rủi ro | Mức so với câu hồ cùng cấp |
|---|---|---|---|
| **Câu hồ** | Nguồn chính, làm nên nhịp chơi | Ngỗng bắt, mất túi, cần hao mòn | 100% |
| **Câu ao nhà** | An toàn, không hao cần, để luyện tay | Không | 63% (đầu game) giảm còn 18% (cuối game) |
| **Máy câu** | Thu nhập khi vắng mặt | Hao mòn, kho bị cướp | ~30% tổng thu nhập ròng cuối game |
| **Cướp nhà** | Thưởng lớn khi nhắm người giàu | Tốn chìa, mất túi, bị bắt | Lỗ với người mới / giữa game, 2 đến 3 lần câu hồ với người giàu không khóa (mục 7) |

## 2. Nguyên tắc cân bằng

1. **Mỗi tier đắt gấp 3-4 lần, thu nhập tăng khoảng 1.5 lần.** Thời gian chờ mua món kế tiếp dài dần (4 phút, 22 phút, 1.2 giờ, 2.9 giờ, 6.2 giờ).
2. **Độ bền là khoản chi định kỳ**, đặt để món hao mòn **khoảng 12-13% thu nhập cần mang lại, ~20% với máy câu**. Đủ đau để phải mua lại, không đủ để mua món xịn thành lỗ.
3. **Rủi ro tỉ lệ với phần thưởng.** Hồ hơn ao. Rương Golden và Rainbow chỉ có từ hồ (máy chặn ở Purple).
4. **Cướp là chuyển vế**, không tạo coins mới. Cân bằng cướp = cân bằng cảm giác.
5. **Đừng đo giá trị rương bằng cột Coins.** Trứng chiếm phần lớn. Giá trị kỳ vọng mỗi rương (coins + trứng bán ra): **Wooden 13, Blue 50, Purple 136, Golden 343, Rainbow 822.**

## 3. Câu hồ và cần câu

### 3.1 Bỏ công thức Luck, dùng bảng tỉ lệ cho từng cần [ĐÃ CÓ từ 15/10/2026: `Odds`, giá mới; độ bền chưa code]

Công thức hiện tại `weight × luck^(i-1)` (`Config.WeightedRoll`) không dùng được: mô phỏng cho thấy cần Duckling ở hồ đã có 3.7% Rainbow và ~164 coins/phút, mọi giá quá rẻ. Thử thêm trần thì quá phẳng (Dragon chỉ hơn Duckling 1.8 lần). **Mỗi cần có bảng tỉ lệ ra rương (`Odds`) viết thẳng trong Config.** Dễ đọc, dễ chỉnh, có thể hiện cho người chơi xem.

| Cần | Giá | Speed | Độ bền (rương) | Wooden | Blue | Purple | Golden | Rainbow | EV/rương | Gộp/phút | Hao/phút | **Ròng/phút** | Sống (phút) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Duckling | 0 | 1.00 | **không hỏng** | 88% | 10% | 1.8% | 0.2% | 0.02% | 20 | 37 | 0 | **37** | |
| Catfish | 150 | 0.92 | 50 | 78% | 18% | 3.4% | 0.55% | 0.05% | 26 | 49 | 6 | **43** | 27 |
| Turtle | 500 | 0.80 | 100 | 66% | 25% | 7% | 1.7% | 0.3% | 39 | 75 | 10 | **65** | 52 |
| Fox | 1800 | 0.70 | 250 | 52% | 30% | 13% | 4.2% | 0.8% | 60 | 118 | 14 | **104** | 128 |
| Lucky Cat | 6000 | 0.58 | 500 | 40% | 31% | 19% | 8.2% | 1.8% | 89 | 181 | 24 | **157** | 247 |
| Rainbow Dragon | 18000 | 0.45 | 1000 | 26% | 28% | 28% | 14% | 4% | 136 | 290 | 38 | **251** | 471 |

Độ bền tính bằng **số rương kéo lên được ở hồ cấm**. Giá so với `Config.Rods` hiện tại: Turtle 600 xuống 500, Fox 2500 xuống 1800, Cat 8000 xuống 6000, Dragon 25000 xuống 18000.

### 3.2 Ao nhà [ĐÃ CÓ từ 15/10/2026: Wooden, x5, không hao cần]

Ao không có ngỗng, không phải chạy về, không tranh rương. Giữ luật cũ (`PondTimeMult = 1.5`, cùng bảng tỉ lệ với hồ) thì ao lời hơn hồ ở đầu game. Đề xuất: **ao chỉ ra Wooden Chest, `PondTimeMult = 5`, và không làm hao cần.** Thu nhập ao: 23 đến 45 coins/phút tùy cần (do Speed), bằng 63% hồ ở đầu game và 18% ở cuối.

### 3.3 Giả định của mô phỏng (cần đo khi chơi thật)

| Giả định | Giá trị |
|---|---|
| Ngắm + ném + chờ phao mỗi rương | 4 giây |
| Nhả nút trốn ngỗng làm kéo lâu thêm | ×1.3 |
| Chạy về nhà cất + quay lại, mỗi chuyến | 25 giây, 4 rương một chuyến |
| Tranh rương với người chơi khác | còn 70% lượt |
| Xác suất mất cả túi mỗi chuyến | 28% - 0.0006 × HP pet (pet 170 HP thì 18%) |

## 4. Máy câu

### 4.1 Ổ và máy tách nhau [ĐÃ CÓ từ 15/10/2026]

- **Ổ máy** (5 ổ, mở một lần, **không hỏng**): **0 / 400 / 1200 / 3000 / 7000**.
- **Máy** là món tiêu hao, **mua thẳng tier muốn** vào ổ trống, hết bền thì biến mất, ổ còn lại.
- **Nâng tier tại chỗ** = trả chênh lệch giá, **độ bền về đầy** của tier mới (cũng là cách "sửa" duy nhất).
- Kho máy đầy sau khoảng 30 phút ở mọi tier. Tier cao sản xuất nhiều rương hơn và tốt hơn, không phải kho to hơn. Offline lâu hơn thì kho ngừng (không cộng dồn vô hạn).
- **Rương máy ra tối đa Purple.**
- Độ bền = số rương máy sản xuất. Máy **không hao khi kho đầy** (không sản xuất), cũng không hao khi chưa thu nhưng đã đầy.

| Tier | Giá mua | Interval | Capacity | Độ bền (rương) | Sống (giờ sản xuất) | Wooden | Blue | Purple | EV/rương | Gộp/phút | Hao/phút | **Ròng/phút** | Hoàn vốn (giờ) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Common | 300 | 180s | 10 | 120 | 6.0 | 100% | | | 13 | 4.3 | 0.8 | **3.5** | 1.4 |
| Rare | 1000 | 160s | 11 | 200 | 8.9 | 70% | 30% | | 24 | 9.0 | 1.9 | **7.1** | 2.3 |
| Epic | 3500 | 140s | 13 | 450 | 17.5 | 55% | 35% | 10% | 38 | 16.4 | 3.3 | **13.0** | 4.5 |
| Legendary | 10000 | 120s | 15 | 1000 | 33.3 | 45% | 38% | 17% | 48 | 23.9 | 5.0 | **18.9** | 8.8 |
| Mythic | 30000 | 100s | 18 | 2500 | 69.4 | 35% | 40% | 25% | 59 | 35.1 | 7.2 | **27.9** | 17.9 |

(Giả định người chơi thu máy mỗi 25 phút.) Hoàn vốn của Mythic dài (~18 giờ) nên đó là món xa xỉ cuối game, không phải món tối ưu. **Cần theo dõi:** nếu máy lấn át câu hồ thì giảm `Capacity` hoặc tăng giá.

## 5. Pet: độ bền và equip

### 5.1 Độ bền pet [ĐỀ XUẤT]

- Độ bền = **tổng HP pet chịu được trong đời** = **20 × HP tối đa**. Mỗi 1 HP ngỗng đánh mất, độ bền mất 1. Hồi HP ở nhà **không** hồi độ bền.
- Hết bền: pet **biến mất** (không thể cứu, không có sửa). Pet gục (HP 0) vẫn là cơ chế cũ (rút về, hồi ở nhà).
- Chỉ pet **đang equip** bị hao.
- Chọn "HP ngỗng đánh" làm đơn vị vì code `Pets.lua` đã tính sát thương mỗi tick, thêm một dòng trừ độ bền.

| Pet | HP | Độ bền | Giây bị ngỗng đánh (5 HP/s) | Sống (giờ, ~6×HP/giờ) | Giá bán pet |
|---|---|---|---|---|---|
| Baker Dog | 130 | 2600 | 520 | 3.3 | 25 |
| Muscle Duck | 220 | 4400 | 880 | 3.3 | 80 |
| Magician Cat | 170 | 3400 | 680 | 3.3 | 250 |
| K9 Dog | 240 | 4800 | 960 | 3.3 | 800 |
| Office Dragon | 300 | 6000 | 1200 | 3.3 | 3000 |

Pet không có giá mua. Giá trị thay thế = tìm lại trứng (bán trứng được 10 đến 1500). Người giỏi trốn ngỗng ít bị đánh nên pet sống lâu hơn nhiều: giả định "6×HP mỗi giờ" ứng với tỉ lệ mất túi 18% mỗi chuyến, **cần đo thật**.

### 5.2 Equip pet [ĐÃ CÓ từ 15/10/2026]

Hiện `Pets.lua` hàm `currentPetName` luôn lấy pet cuối danh sách. Vì giờ mỗi pet có độ bền riêng, **pet phải là bản ghi riêng**, không còn là danh sách tên:
- `profile.Pets = { { Id, Name, Durability }, ... }` (chuyển đổi dữ liệu cũ: mỗi tên cũ thành 1 bản ghi đầy bền).
- `profile.EquippedPet = Id`. Rỗng hoặc pet đã hỏng thì không có pet đi theo (hoặc rơi về pet cuối danh sách).
- `Action("EquipPet", id)` trên server, kiểm tra thuộc sở hữu. Không cho đổi khi đang bị ngỗng đuổi.
- UI Bag: nút Equip trên ô pet, thanh độ bền, nhãn EQUIPPED.
- `Market.SellPet` đổi sang bán theo bản ghi, **giá bán nhân theo % độ bền còn lại** (tránh bán pet sắp hỏng bằng giá đầy).

## 6. Độ bền chung

| | Cần câu | Máy câu | Pet |
|---|---|---|---|
| Hao khi nào | Mỗi rương **kéo lên ở hồ cấm** (ao không hao, hụt không hao) | Mỗi rương **máy sản xuất** | Mỗi HP **ngỗng đánh** pet |
| Hao khi không dùng? | Không (chỉ cần đang cầm) | Có khi đang sản xuất, kể cả offline | Không (chỉ pet đang equip) |
| Hết bền | Biến mất khỏi kho đồ, tự cầm lại Duckling | Biến mất, ổ còn lại | Biến mất |
| Mua lại | Giá gốc ở Tool Shop | Giá gốc tier đó | Tìm trứng mới |
| Sửa | Không | Không, trừ **nâng tier tại chỗ** (độ bền đầy) | Không |
| Ngoại lệ | **Duckling Rod không hỏng** (khỏi kẹt không có cần) | Ổ máy không hỏng | |

Chi tiết cần quyết định:
- **Cảnh báo:** thanh độ bền trên ô cần / pet / nhãn máy, toast khi còn ≤ 20% ("Your Fox Rod is almost broken!").
- **Món cất trong kho không hao.** Chỉ món đang dùng bị hao.
- **Sinh ra dữ liệu mới:** `Rods = { [id] = độ bền }` (thay `true`), `AutoFishers[slot] = { Tier, Durability, Last, Stored }`, `Pets` là danh sách bản ghi (mục 5.2).

## 7. Cướp nhà

Luồng chung (đột nhập sân, đồng hồ 60 giây, ngỗng nhà, đồn cảnh sát) ở `SYSTEM_DESIGN.md` mục 8, 9. Phần này chốt **luật kinh tế đã sửa** theo các điều anh đã chốt.

### 7.1 Chìa vạn năng và khóa [ĐÃ CHỐT chìa 50%, giá và khóa là ĐỀ XUẤT]

- **Master Key:** mua ở Tool Shop, **200 coins/chiếc**, cất trong profile (`Keys`), **không chiếm ô túi**. Mỗi lần dùng **tiêu 1 chìa** dù mở được hay không.
- Dùng chìa trên **một mục tiêu** (Stash/kho hoặc **một máy câu**): **50% mở**. Không mở được thì thử lại bằng chìa khác, tối đa ~4 lần trong 60 giây sân.
- **Lần thử đầu tiên (dù mở hay không) báo động**: chủ nhà nhận thông báo, ngỗng nhà nhập cuộc, đồn cảnh sát sinh ngỗng.
- **Khóa cửa** (chủ nhà mua bằng coins, thêm chỗ tiêu tiền): giảm tỉ lệ mở của chìa.

| Cấp khóa | Giá | Tỉ lệ mở |
|---|---|---|
| Không khóa | 0 | 50% |
| Khóa 1 | 3,000 | 40% |
| Khóa 2 | 10,000 | 30% |
| Khóa 3 | 30,000 | 20% |

### 7.2 Mở được thì lấy gì, lấy thế nào [ĐÃ CHỐT]

- Mục tiêu cướp được: **kho nhà (rương chưa mở, trứng chưa ấp)** và **kho trong máy câu**. Không cướp được: coins, pet, trứng đang ở máy ấp.
- Khi mục tiêu đã mở, kẻ cướp **xem danh sách và tự chọn** món (rương theo hạng, trứng), **tối đa bằng số ô túi còn trống** của mình (4 mặc định, nâng được 5, 6).
- Mỗi món giữ [E] khoảng 3 giây; việc lấy chạy trên server, **khóa theo plot** để hai người không lấy cùng một món.
- Món lấy được vào **túi tạm của kẻ cướp**. Về nhà mình **cất vào kho (không giới hạn ô)** thì thuộc về họ. **Bị ngỗng bắt thì món cướp trả về chủ nhà**, kẻ cướp mất luôn đồ trong túi (luật cũ).

### 7.3 Vì sao chìa đắt và khóa phải có [ĐỀ XUẤT]

Kẻ cướp **tự chọn món xịn nhất** là rất mạnh. Mô phỏng ban đầu (lấy ngẫu nhiên): 0.45 đến 0.75 lần câu hồ. **Tự chọn: gấp 5 đến 10 lần**, nên phải có giá chìa và khóa để chặn.

Lời ròng kỳ vọng mỗi vụ, **đã gồm thất bại**, túi 4 ô, chìa 200 coins, thoát được 40% sau khi mở (giả định, cần đo). Trong ngoặc: bội số so với câu hồ cùng thời gian của kẻ cướp (cùng cấp).

| Nạn nhân | Món lấy được (top 4) | Không khóa | Khóa 1 | Khóa 2 | Khóa 3 |
|---|---|---|---|---|---|
| Đầu game: Catfish, 1 máy Common | 106 | -335 (lỗ) | -398 | -474 | -565 |
| Giữa: Fox, 3 máy Rare/Epic | 876 | -46 (-0.3x) | -130 | -240 | -383 |
| Muộn: Cat, 4 máy Legendary | 3096 | 786 (3.1x) | 643 (2.5x) | 434 (1.7x) | 141 (0.6x) |
| Cuối: Dragon, 5 máy Mythic | 3117 | 794 (2.0x) | 650 (1.6x) | 441 (1.1x) | 146 (0.4x) |

**Kết luận của bảng:**
- **Người mới và giữa game gần như không bị cướp** vì cướp họ lỗ tiền chìa. Không cần luật "bảo vệ người mới" riêng (vẫn nên có khiên khi đang hướng dẫn).
- **Người giàu (nhiều trứng và rương chưa mở) mới là mục tiêu.** Hợp lý: giữ nhiều đồ lâu thì rủi ro.
- **Khóa 2-3 làm cướp hết lời**, nên chủ nhà có việc để tiêu coins cuối game. Khóa 3 (30,000) gần như miễn dịch.
- Túi 6 ô chỉ tăng ~4%: món thứ 5, 6 giá trị thấp. Nên túi lớn không phá cân bằng.
- Nếu muốn cướp hấp dẫn hơn ở giữa game: hạ giá chìa (em tính tay với chìa 100 coins, không khóa: Fox ~0.8x, Cat ~3.8x).

### 7.4 Giới hạn thiệt hại cho nạn nhân [ĐỀ XUẤT]

- Mỗi vụ mất tối đa số ô túi của kẻ cướp (4 đến 6 món).
- **Khiên 10 phút** sau khi bị cướp, không bị cướp tiếp.
- Hết 60 giây trong sân mà chưa ra thì ngỗng nhà đuổi (đã chốt).
- **Chỉ cướp được người đang online** (plot chỉ có chủ khi online).

### 7.5 Nguồn tồn kho để cướp

Nếu kho mở rương tức thì và người chơi mở hết ngay, kho luôn trống. Hàng để cướp còn lại là: **kho máy câu** (đầy dần lúc chủ ở hồ), rương chưa mở, trứng chưa ấp. Nếu thử thấy kho vẫn trống quá, thêm thời gian mở rương (Purple ~10 giây, Rainbow ~60 giây, mở song song vài rương) để rương nằm trong kho lâu hơn. Chưa làm.

## 8. Perk cần và pet (làm cho "equip theo ý thích" có nghĩa) [ĐỀ XUẤT]

Perk là chỉ số số học đọc qua `Loadout.Get(player)` (gộp cần + pet + giày), không viết script riêng cho từng perk.

| Cần | Perk | Chỉ số |
|---|---|---|
| Duckling | Không (mốc chuẩn, không hỏng) | |
| Catfish | Quiet Reel: tiếng động trễ hơn | NoiseDelay +2s |
| Turtle | Steady Line: nhả nút lâu không đứt dây | Leash +6, PauseTimeout +20s |
| Fox | Sly Fox: ngỗng nhìn xa kém hơn | SightMult ×0.75 |
| Lucky Cat | Lucky Paw: rương nhiều coins hơn | CoinMult ×1.2 |
| Rainbow Dragon | Hoard: rương dễ ra trứng hơn | EggChanceMult ×1.1 |
| Pet | Perk (chỉ phòng thủ) | Chỉ số |
|---|---|---|
| Baker Dog | Crumbs: ngỗng khựng thường xuyên hơn | StunEvery 4s |
| Muscle Duck | Tank | DamageTaken ×0.8, HP 220 |
| Magician Cat | Hat Trick: ngỗng choáng lâu | StunTime 2.2s |
| K9 Dog | Sniff: báo khi ngỗng tới gần | WarnRange 50, StunEvery 4s |
| Office Dragon | Smoke: ngỗng bỏ cuộc nhanh | LoseTime ×0.5, HP 300 |

`DamageTaken ×0.8` của Muscle Duck cũng **làm độ bền hao chậm hơn** (độ bền tính theo HP thật bị mất). Perk loot của cần (CoinMult, EggChanceMult) **chưa tính** trong bảng thu nhập mục 3.1, đã giữ nhỏ (+7 đến +8%).

## 9. Chỗ tiêu coins và tiến độ

| Chỗ tiêu | Tổng |
|---|---|
| Cần câu (5 cần trả phí, **mua lại khi hỏng**) | 26,450 |
| 5 ổ máy | 11,600 |
| 5 máy Mythic (**mua lại khi hỏng**, ~69 giờ sản xuất mỗi máy) | 150,000 |
| Máy ấp 2, 3, 4 (**đã có**) | 7,800 |
| Nâng túi (**đã có**) | 1,500 |
| Dép Tên Lửa (**đã có**) | 2,000 |
| Khóa cửa 3 cấp | 43,000 |
| Chìa vạn năng (lặp lại) | 200 / chiếc |
| Dịch chuyển (lặp lại): Lake 20, Shop 10, Home 10 | |
| **Tổng một lần** | **~242,000** |

Hao mòn lúc cuối game: cần Dragon ~38 coins/phút, máy ~20% sản lượng, pet Dragon ~900 coins/giờ (giá trị thay thế). Tổng khoảng 15-20% thu nhập gộp.

**Tiến độ mô phỏng** (chơi liên tục, mua theo thứ tự cố định, thu nhập **ròng** đã trừ hao mòn):

| Mốc | Phút | Thu nhập ròng lúc đó |
|---|---|---|
| Cần Catfish | 4 | 37/phút |
| Máy Common #1 | 11 | 43/phút |
| Cần Turtle | 22 | 47/phút |
| Cần Fox | 74 (1.2 giờ) | 80/phút |
| Cần Lucky Cat | 177 (2.9 giờ) | 137/phút |
| Cần Rainbow Dragon | 369 (6.2 giờ) | 221/phút |
| Hết kế hoạch mô phỏng (5 máy tier cao) | 563 (9.4 giờ) | 358/phút (máy ~30%) |

## 10. Thay đổi so với Config và dữ liệu hiện tại

| Thứ | Hiện tại | Đề xuất |
|---|---|---|
| `Config.Chests[].Weight` | Trọng số chung | Bỏ. Dùng `Odds` của cần / tier máy |
| `Config.WeightedRoll(list, luck)` | Luck dạng lũy thừa | Hàm mới `Config.RollChest(odds)` |
| `Config.Rods[].Luck` | 1 đến 4.5 | Bỏ. Thêm `Odds`, `Durability`, `Perk` |
| Giá cần | 150 / 600 / 2500 / 8000 / 25000 | 150 / 500 / 1800 / 6000 / 18000 |
| `Config.Fishing.LakeLuck`, `PondTimeMult` | 1.5 và 1.5 | Bỏ LakeLuck; `PondTimeMult` = 5, ao chỉ Wooden, ao không hao cần |
| `Config.AutoFisher` | `Prices`, `Tiers` theo thứ tự ổ | `PedestalPrices`, `Tiers = { Price, Interval, Capacity, Durability, Odds }` |
| `Config.Pet.Stats[].HP` | HP | Thêm `Durability = 20 × HP` |
| Mới | | `Config.Robbery` (KeyPrice, SuccessByLock, LockPrices, Shield, MaxTries) |
| `profile.Rods` | `{ id = true }` | `{ id = độ bền }` |
| `profile.Pets` | Danh sách tên | Danh sách bản ghi `{ Id, Name, Durability }` + `EquippedPet` |
| `profile.AutoFishers[slot]` | `{ Last, Stored }` | Thêm `Tier`, `Durability` |
| `profile` mới | | `Keys`, `LockLevel`, `ShieldUntil` |

Mọi thay đổi `profile` cần bước chuyển đổi dữ liệu đã lưu (tham khảo `migrateV1` trong `Data.lua`).

## 11. Thứ tự làm [ĐỀ XUẤT]

1. ~~**Bảng tỉ lệ rương thay Luck** (`Config.RollChest`), giá cần mới, ao Wooden~~ **XONG 15/10/2026** (máy câu tạm chỉ ra Wooden đến bước 4).
2. ~~**Độ bền cần câu:** `profile.Rods` có độ bền, hao khi kéo rương hồ, hết bền thì biến mất, UI thanh bền.~~ **XONG 15/10/2026** (từ #38 độ bền hiện bằng thanh).
3. ~~**Pet thành bản ghi + equip pet + độ bền pet** (chuyển đổi dữ liệu, `Market.SellPet` theo bản ghi).~~ **XONG 15/10/2026** (xem DEVLOG #35).
4. ~~**Máy câu:** tách ổ và tier, độ bền, nâng tier tại chỗ.~~ **XONG 15/10/2026** (xem DEVLOG #37).
5. **Kho nhà vô hạn giữ rương chưa mở** (SYSTEM_DESIGN mục 5.2), hành động mở rương.
6. **Cướp nhà:** Master Key, mở mục tiêu, tự chọn món, báo động, trả đồ khi bị bắt.
7. Khóa cửa, khiên, perk qua `Loadout.lua`.
8. Chơi thử, đo 3 số thật (xem mục 12), chỉnh lại bằng `tools/sim_economy.py`.

Bước 3, 5, 6 phụ thuộc nhau, làm gần nhau.

## 12. Điều còn mở

1. ~~Sửa chữa~~ **Đã chốt: không sửa.**
2. ~~Chef Cat có hỏng không~~ **Đã chốt: mọi pet như nhau, có hỏng; và Chef Cat đã bỏ hẳn (người mới được tặng 1 Reed Egg).**
3. **Ao có làm hao cần không?** Đề xuất **không** (ao là chỗ an toàn, tránh bẫy cho người mới). Nếu có hao thì cầm Dragon ra ao còn lỗ 17 coins/phút.
4. **Thời gian mở rương** có thêm để kho có hàng cho cướp không (mục 7.5)?
5. **Cần đo ngoài game:** tỉ lệ mất túi mỗi chuyến, xác suất kẻ cướp thoát về nhà (đang giả định 40%), rương/phút thật ở hồ khi 4 đến 8 người, HP pet bị mất mỗi giờ (đang giả định 6×HP). Bốn số này quyết định bảng tiến độ, hao mòn pet và mức lời của cướp.
6. Gộp pet trùng (đã chốt "bán hoặc gộp", điều kiện chưa chốt). Vì chỉ nâng cấp bằng coins, đề xuất gộp = N pet trùng + coins, và gộp **làm độ bền về đầy**.
7. Rương từ ao nhà (chỉ Wooden) vẫn vào thẳng tài khoản (đề xuất) hay vào kho?
