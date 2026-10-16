# Lối chơi giữ chân: phiên ngắn, nhiều việc nhỏ, nhiệm vụ lặp lại

> Dành cho dev và người làm thiết kế. Cập nhật lần cuối 16/10/2026. **Chỉ là kế hoạch, chưa code.**
> Đọc kèm `CORE_GAMEPLAY.md` (lối chơi chính), `../Economy/ECONOMY_DESIGN.md` (kinh tế), `../../MakeRobuxInHere/README.md` (Robux, cosmetic).
> Chưa release nên **chưa có số liệu người chơi**; mọi con số là **[ĐỀ XUẤT]** từ mô hình và nguyên tắc chung.

## 0. Nhãn và điều đã chốt

| Nhãn | Nghĩa |
|---|---|
| **[ĐÃ CHỐT]** | Anh Scott đã quyết, chưa code |
| **[ĐỀ XUẤT]** | AI đề xuất, số chưa kiểm chứng |

**Đã chốt (16/10/2026):**
1. **Nhiệm vụ hoàn thành xong thì lặp lại**, chỉ thưởng **xu (coins)**, **không bắt buộc** phải làm.
2. **Phiên chơi ngắn, tối đa ~30 phút, nhưng chơi nhiều lần.** Vì vậy **rút ngắn thời gian thu hoạch** để trong mỗi phiên luôn có việc nhỏ để làm.
3. **Không làm Rebirth.**
4. **Có cosmetic, nhưng chưa làm bây giờ.**
5. **Có đội làm game** (nên có thể làm sự kiện và season, nhưng để sau các việc rẻ hơn).
6. Giữ nguyên các điều đã chốt ở `CORE_GAMEPLAY.md` (coop tùy chọn, chơi đơn đầy đủ, không phần thưởng chỉ có trong coop).

## 1. Nhịp một phiên 30 phút [ĐỀ XUẤT]

Mục tiêu: không có lúc nào người chơi phải "chờ hết thời gian mới có việc".

| Phút | Việc có thể làm | Nguồn việc |
|---|---|---|
| 0 | Vào game: thu máy câu (đã đầy), nhận trứng nở, xem bảng nhiệm vụ | Máy, ấp trứng, nhiệm vụ |
| 1 đến 8 | Ra hồ kéo rương, mang về cất, mở rương | Lối chơi chính |
| 8 đến 10 | Máy câu Common/Rare đầy lần nữa, thu lần hai | Thu hoạch ngắn (mục 3) |
| 10 đến 20 | Thêm vài chuyến, hoàn thành 1 đến 2 nhiệm vụ nhận xu | Nhiệm vụ lặp lại (mục 2) |
| 20 đến 28 | Mua nâng cấp (đã gần đủ tiền nhờ thanh mục tiêu), ấp trứng mới | Thanh mục tiêu (mục 5) |
| 28 đến 30 | Thu máy lần cuối, thấy "máy đầy sau 8 phút", rời đi | Tổng kết cuối phiên (mục 5) |

Nguyên tắc: **mỗi 5 đến 10 phút có ít nhất một thứ "xong" để thu**.

## 2. Nhiệm vụ lặp lại (Quest Board) [ĐÃ CHỐT luật, số là ĐỀ XUẤT]

### 2.1 Luật

- Bảng nhiệm vụ luôn có **3 nhiệm vụ đang mở**. Hoàn thành một cái, bấm nhận xu, **một nhiệm vụ mới tự xuất hiện** thay thế. Cứ thế lặp lại không giới hạn.
- **Chỉ thưởng xu.** Không trứng, không rương, không thứ gì khác (đã chốt).
- **Không bắt buộc:** bỏ qua nhiệm vụ không mất gì, không hết hạn, không phạt. Có thể **đổi một nhiệm vụ không thích** (không tốn gì, chờ 2 phút mới đổi được cái tiếp theo).
- Nhiệm vụ **chọn theo giai đoạn** của người chơi (ví dụ cần Duckling không bị giao "kéo rương Golden").
- Nhiệm vụ **coop** chỉ hiện khi người chơi đang trong đội, và **không bao giờ chiếm cả 3 ô** (đảm bảo chơi đơn).

### 2.2 Thưởng tính theo thu nhập hiện tại

Cùng ý tưởng với gói coins trong `MakeRobuxInHere`: thưởng tính theo **số phút thu nhập hiện tại** của người chơi, để không vô nghĩa cuối game hay quá lớn đầu game.

```
xu thưởng = số phút của nhiệm vụ x thu nhập ròng mỗi phút hiện tại (cần đang cầm + máy đang có)
```

| Nhiệm vụ | Phút thưởng | Thưởng ở thu nhập 22 xu/phút (đầu game) | Thưởng ở 149 xu/phút (cuối game) |
|---|---|---|---|
| Nhỏ (làm trong ~3 phút) | 1 | ~22 | ~149 |
| Vừa (~6 phút) | 1.5 | ~33 | ~224 |
| Lớn (~10 phút) | 2 | ~44 | ~298 |

(Thu nhập lấy từ mô hình hồ mới trong `tools/sim_economy.py`, bắt 20% mỗi lần câu.)

**Giới hạn chống cày:** sau **12 nhiệm vụ mỗi ngày** (theo giờ UTC, như hộp thư quà), thưởng còn **25%**. Nhiệm vụ vẫn hiện, vẫn làm được, chỉ thưởng ít hơn. Mỗi ngày tối đa khoảng **15 đến 20 phút thu nhập** từ nhiệm vụ, tức khoảng **+15% thu nhập** so với không làm nhiệm vụ (vì chính nhiệm vụ cũng là lúc đang farm). Cần chạy lại mô phỏng khi code.

Cần hàm dùng chung `IncomePerMinute(profile)` ở server (port từ `tools/sim_economy.py`), cũng dùng cho gói coins của Robux sau này.

### 2.3 Kho nhiệm vụ (pool) [ĐỀ XUẤT]

| Nhóm | Ví dụ | Điều kiện hiện |
|---|---|---|
| Hồ | Kéo 3 rương ở hồ; câu tự do 10 lần; mang 3 rương về nhà không bị bắt; thoát ngỗng khi đang mang rương | Luôn |
| Ao nhà | Câu 10 lần ở ao; có rương từ ao | Luôn |
| Nhà | Thu máy câu 2 lần; mở 5 rương trong Stash | Có máy câu / kho |
| Ấp trứng | Ấp 2 trứng; nở 1 pet | Có máy ấp |
| Pet | Dùng kỹ năng pet 3 lần | Sau khi làm kỹ năng pet (CORE_GAMEPLAY GĐ7) |
| Dụng cụ | Dùng 2 Decoy | Sau khi làm dụng cụ |
| Coop | Kéo chung 1 rương với bạn; cùng đội mang 6 rương về nhà | Đang trong đội, sau CORE_GAMEPLAY GĐ8 |
| Sưu tập | Kéo rương Purple lần đầu; có đủ 3 loại pet | Nhật ký sưu tập (mục 4) |

Mỗi nhiệm vụ là bảng trong `Config.Quests` (loại sự kiện, số lượng, số phút thưởng, điều kiện hiện). Server đếm tiến độ từ **sự kiện thật** (`Fishing.lua`, `Bag.lua`, `Stash.lua`, `AutoFishers.lua`, `Hatchery.lua`), không tin client.

### 2.4 Dữ liệu và UI

- `profile.Quests = { Active = { {Id, Progress} x3 }, DoneToday, Day, NextSwapAt }`, thêm qua `reconcile`.
- Nút **QUESTS** ở dock (cạnh HOME / LAKE / SHOP), huy hiệu số nhiệm vụ đã xong chưa nhận.
- HUD: một dòng nhỏ "Haul 3 chests 2/3", bấm mở bảng. Bảng song ngữ khi làm Store; nhiệm vụ hiện **tiếng Anh** (theo quy tắc repo, chỉ Store là song ngữ).
- Nhận xu có hiệu ứng ngắn (số bay lên như khi thu rương), không bật cửa sổ chặn.

## 3. Rút ngắn thời gian thu hoạch [ĐÃ CHỐT hướng, số là ĐỀ XUẤT]

Hiện kho máy câu đầy sau **~30 phút** ở mọi tier. Với phiên chơi tối đa 30 phút, người chơi chỉ thu máy **1 lần** mỗi phiên. Đề xuất **kho đầy sau 8 đến 20 phút**, tier cao hơn kho dài hơn:

| Tier | Interval (giữ nguyên) | Capacity cũ | Capacity mới | Kho đầy sau (cũ → mới) |
|---|---|---|---|---|
| Common | 180s | 10 | **3** | 30 phút → 9 phút |
| Rare | 160s | 11 | **4** | 29 phút → ~11 phút |
| Epic | 140s | 13 | **5** | 30 phút → ~12 phút |
| Legendary | 120s | 15 | **8** | 30 phút → 16 phút |
| Mythic | 100s | 18 | **12** | 30 phút → 20 phút |

- **Interval và độ bền giữ nguyên**, nên tốc độ sản xuất mỗi phút và tuổi thọ máy không đổi. Chỉ đổi kho.
- **Hiệu ứng phụ cần biết:** người chơi quay lại sau nhiều giờ sẽ thu được ít hơn trước (kho chỉ 9 đến 20 phút). Em tính nhanh: với phiên 30 phút nghỉ 30 phút, thu nhập thụ động giảm khoảng **30%**, tức tổng thu nhập giảm khoảng **7%** (máy chiếm 22 đến 30% thu nhập). Chấp nhận được, nhưng **phải chạy lại `tools/sim_economy.py`** (đổi `COLLECT_EVERY` thành 10 phút và `Capacity`) trước khi sửa `Config.lua`.
- Người chơi giỏi sẽ **thu 2 đến 3 lần mỗi phiên**, đúng mục tiêu "luôn có việc".
- Trứng: `HatchTime` hiện 10 đến 120 giây đã ngắn, giữ nguyên.
- Ao: chờ 5 giây mỗi lần ném (CORE_GAMEPLAY 2.4), giữ nguyên.

Không tăng hay giảm giá máy khi đổi kho (giá theo sản lượng mỗi phút).

## 4. Nhật ký sưu tập và thành tựu [ĐỀ XUẤT]

- **Nhật ký sưu tập** trong Bag: 5 loại rương đã kéo lần đầu, 5 pet, 6 cần, 5 tier máy. Mục đã có hiện màu, chưa có hiện bóng (Bag đã làm kiểu bóng đen).
- **Thành tựu** nhỏ (ví dụ "Kéo rương Rainbow đầu tiên", "Thoát ngỗng 10 lần liên tiếp"): thưởng **danh hiệu** hiển thị trên bảng tên, **không** thưởng thứ có sức mạnh. Thưởng xu đã dành cho nhiệm vụ.
- Dùng lại sự kiện đếm tiến độ của nhiệm vụ.

## 5. Mục tiêu tiếp theo và tổng kết cuối phiên [ĐỀ XUẤT]

- **Thanh "món tiếp theo"** trên HUD: "Catfish Rod 62/150", tính từ món rẻ nhất trong chuỗi cần, máy, ổ máy mà người chơi chưa có. Bấm mở Shop đúng chỗ.
- **Tổng kết cuối phiên:** mỗi lần người chơi thu máy xong, hiện dòng "Next machine full in 9 min; Gold Egg hatching: 8 min". Roblox không có thông báo đẩy, nên đây là chỗ duy nhất để đặt "hẹn quay lại".
- **Quà đăng nhập (bật lại hộp thư):** `Config.House.Daily` đang tắt, đang tặng 100 coins + 1 Reed Egg. Nếu bật, nên **chỉ tặng xu** cho nhất quán với nhiệm vụ, và chuỗi 7 ngày **lỡ một ngày chỉ lùi 1 bậc, không reset** (tuổi 13 đến 19 hay bị bài thi, đi học thêm).

## 6. Dài hạn (không có Rebirth) [ĐỀ XUẤT]

| Việc | Ghi chú |
|---|---|
| **Gộp và tiến hóa pet** (theo loài) | Đã có thiết kế ở `PET_EVOLUTION.md` |
| **Biến thể pet** (Shiny, Golden: chỉ đổi màu và hiệu ứng) | Đã có kế hoạch ở `../Art/PET_VARIANTS.md` |
| **Thêm pet** mỗi bậc (hiện 1 trứng một pet) | Chưa làm; hiện dùng biến thể màu để kéo dài sưu tập, pet mới cần model mới từ `roblox-assets` |
| **Bảng xếp hạng tuần** (toàn cầu) | `OrderedDataStore`, thưởng cosmetic (khi có), không thưởng thứ có sức mạnh. **Khác** bảng điểm phòng 4-8 người ở `SERVER_BOARD.md` (chỉ trong bộ nhớ server) |
| **Sự kiện theo giờ** (Ngỗng Vàng, rương Mythic rơi toàn server) | Có đội làm game nên khả thi; nên lặp nhiều lần mỗi ngày để người chơi giới hạn giờ vẫn tham gia được |
| **Season 4 đến 6 tuần** với đường thưởng miễn phí | Chỉ khi đã có người chơi và số liệu; cosmetic làm sau |
| **Khu hồ mới** | Tốn công nhất, để cuối |

## 7. Giữ chân và đội (coop tùy chọn)

- Nhiệm vụ đội chỉ **một phần** trong kho nhiệm vụ.
- Rủ bạn: đội có bảng "nhiệm vụ đội" chung (cùng nhận xu), không phần thưởng riêng của coop.
- Mục tiêu tuần của đội: dùng bảng xếp hạng tuần (mục 6).

## 8. Số liệu cần đo

| Số liệu | Vì sao |
|---|---|
| Số nhiệm vụ hoàn thành mỗi phiên | Kiểm tra "việc nhỏ" có thực sự được làm không |
| Số lần thu máy mỗi phiên | Kiểm tra thu hoạch ngắn có tạo nhịp không |
| Độ dài phiên (phút), số phiên mỗi ngày | Kiểm tra giả định phiên ≤ 30 phút |
| Thời gian từ vào game tới nhiệm vụ đầu tiên hoàn thành | Thu hút: dưới 5 phút |
| Tỉ lệ người chơi quay lại sau 1 ngày, 7 ngày | Giữ chân (khi đã release) |
| Tỉ lệ người chơi dùng "đổi nhiệm vụ" | Kho nhiệm vụ có nhàm không |

## 9. Các điểm đã chốt (16/10/2026, anh đồng ý theo đề xuất)

| # | Câu hỏi | Quyết định |
|---|---|---|
| 1 | Quà đăng nhập | **Bật lại hộp thư, chỉ tặng xu**, chuỗi 7 ngày, lỡ một ngày chỉ lùi 1 bậc |
| 2 | Giới hạn nhiệm vụ | **12 nhiệm vụ mỗi ngày, sau đó thưởng còn 25%** |
| 3 | Kho máy ngắn hơn | **Chấp nhận giảm ~7% tổng thu nhập**, chưa bù; chạy lại `tools/sim_economy.py` khi làm R2 rồi mới quyết có bù không |
| 4 | Pet mới, biến thể pet | **Làm bằng đổi màu và hiệu ứng trên model có sẵn**: xem `../Art/PET_VARIANTS.md` |
