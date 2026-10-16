# Tiến hóa pet theo loài: nở trùng thì loài đó lớn lên

> Dành cho dev và người làm thiết kế. Cập nhật lần cuối 16/10/2026. **Chỉ là kế hoạch, chưa code.**
> Đọc kèm `SYSTEM_DESIGN.md` mục 6 (pet), `../Art/PET_VARIANTS.md` (biến thể màu), `CORE_GAMEPLAY.md` (kỹ năng pet, tỉ lệ bị bắt), `RETENTION.md`.
> Số kinh tế lấy từ `tools/sim_economy.py` (mô hình hồ mới: bắt 20% mỗi lần câu), **ước lượng, chưa có số đo thật**.

## 0. Nhãn và điều đã chốt

| Nhãn | Nghĩa |
|---|---|
| **[ĐÃ CHỐT]** | Anh Scott đã quyết, chưa code |
| **[ĐỀ XUẤT]** | AI đề xuất, cần chỉnh khi chơi thử |

**Đã chốt (16/10/2026):**
1. Mở ra **pet trùng thì nâng cấp pet và phóng to kích thước**.
2. **Cách B: tiến độ theo loài**, không gắn vào từng con. Pet hỏng không làm mất cấp.
3. **Phóng to vừa đủ** (tối đa ×1.4) và **đổi cả sức mạnh** (HP và độ mạnh kỹ năng), không chỉ để đẹp.
4. Làm theo đề xuất của em cho phần còn lại (số bản trùng, độ bền, giao diện).

## 1. Cách chạy

- Mỗi **loài** (Baker Dog, Muscle Duck, Magician Cat, K9 Dog, Office Dragon) có bộ đếm **bản trùng**: số lần nở loài đó **sau lần đầu tiên**.
- Bộ đếm đạt mốc thì **loài lên Stage** (1 → 2 → 3). Mọi con cùng loài, đang có hay nở sau này, đều ở Stage đó.
- **Mỗi lần nở vẫn nhận một con pet** như bình thường. Pet trùng không bị tiêu: giữ làm **dự phòng** khi con đang dùng hỏng, hoặc bán.
- Pet hỏng hay bán đi **không làm mất Stage** (Stage thuộc về loài, không thuộc về con pet).
- Bộ đếm tính ở lúc **nở**, bán pet sau đó không trừ lại.

## 2. Bảng số [ĐỀ XUẤT]

### 2.1 Số bản trùng để lên Stage (cộng dồn)

Pet càng hiếm càng ít trứng nên cần ít bản trùng hơn. Cột cuối là **thời gian ước lượng** từ số trứng mỗi giờ ở hồ.

| Loài (trứng) | Trứng/giờ (cần Duckling → Dragon) | Stage 2 | Stage 3 | Thời gian Stage 3 ở cần phù hợp |
|---|---|---|---|---|
| Baker Dog (Reed) | 21 → 26 | **8** bản trùng | **30** | ~1.5 giờ |
| Muscle Duck (Bubble) | 1.3 → 15 (7 ở Fox) | **5** | **14** | ~2 giờ ở Fox |
| Magician Cat (Crystal) | 0.2 → 7.4 (2.3 ở Fox) | **4** | **10** | ~4.5 giờ ở Fox |
| K9 Dog (Gold) | 0.02 → 2.5 (1.3 ở Lucky Cat) | **3** | **7** | ~5 giờ ở Lucky Cat |
| Office Dragon (Dragon) | 0.00 → 0.36 (0.16 ở Lucky Cat) | **2** | **4** | ~11 giờ ở cần Dragon |

Máy câu cũng ra thêm trứng Reed, Bubble, Crystal (Wooden, Blue, Purple), nên loài thường sẽ nhanh hơn bảng. Stage 3 của Office Dragon là **mục tiêu dài hạn** (hơn 10 giờ), phù hợp với việc không có Rebirth.

### 2.2 Hệ số theo Stage

| Stage | Kích thước | HP tối đa | Độ bền tối đa | Độ mạnh kỹ năng |
|---|---|---|---|---|
| 1 | ×1.0 | ×1.0 | ×1.0 | ×1.0 |
| 2 | **×1.2** | ×1.25 | ×1.25 | ×1.25 |
| 3 | **×1.4** | ×1.5 | ×1.5 | ×1.5 |

HP sau tiến hóa: Baker Dog 130 → 195, Muscle Duck 220 → 330, Magician Cat 170 → 255, K9 Dog 240 → 360, Office Dragon 300 → 450. Độ bền tối đa vẫn bằng 20 × HP tối đa (`Config.Pet.DurabilityMult`), nên Office Dragon Stage 3 có 9,000.

**Độ mạnh kỹ năng** áp cho các kỹ năng làm ở `CORE_GAMEPLAY.md` GĐ7 (thời gian choáng, thời gian dụ, bán kính). Chưa có kỹ năng nào được code, nên hệ số này gắn vào lúc làm GĐ7.

## 3. Độ bền khi lên Stage (không phải sửa chữa) [ĐỀ XUẤT]

Anh đã chốt không sửa chữa. Để tiến hóa không biến thành cách sửa:
- Khi loài lên Stage, **độ bền tối đa** của mọi con thuộc loài đó tăng, và **độ bền hiện tại cộng đúng phần tăng thêm**. Không đầy lại.
- Ví dụ: Baker Dog tối đa 2,600, còn 1,000. Lên Stage 2: tối đa 3,250 (+650), còn 1,650.
- Pet nở **sau** khi lên Stage bắt đầu với độ bền đầy **của Stage hiện tại**.
- **HP trong phiên** giữ nguyên tỉ lệ (HP hiện tại nhân theo HP tối đa mới), không hồi đầy miễn phí.

Hệ quả cân bằng: pet Stage cao chịu đòn lâu hơn **×1.5** (HP và độ bền cùng tăng). Thời gian chặn ngỗng của Office Dragon Stage 3: 450 HP / 5 HP mỗi giây = 90 giây, so với 60 giây hiện tại.

## 4. Cân bằng với tỉ lệ bị bắt [ĐỀ XUẤT]

Pet chặn lâu hơn thì ngỗng khó bắt hơn, nên tỉ lệ bị bắt mục tiêu 20% (`CORE_GAMEPLAY.md`) sẽ tụt khi người chơi có pet Stage cao. Cách xử lý:
- **Đo tỉ lệ bị bắt theo Stage pet** ở bước ghi log (GĐ0), không đoán.
- **Ngỗng sống** (GĐ3) là chỗ chỉnh độ khó chính; nên **làm tiến hóa sau GĐ0 và GĐ3** để có số đo.
- Nếu pet Stage 3 làm game quá dễ, giảm hệ số (×1.4 HP thay vì ×1.5) hoặc để ngỗng hiếm có thêm ngỗng thứ hai (GĐ5).

## 5. Dữ liệu

| Trường | Nội dung |
|---|---|
| `profile.PetStages` | `{ ["Baker Dog"] = số bản trùng, ... }`. Có khóa = loài từng nở. Stage tính ra từ số này, không lưu riêng |
| Bản ghi pet `{ Id, Name, Durability, Variant }` | Giữ nguyên, không thêm Stage vào từng con |

**Chuyển đổi dữ liệu cũ:** với mỗi loài đang sở hữu, `PetStages[loài] = max(số con đang có - 1, 0)` (không cộng thêm từ trứng đã bán). Chạy trong `reconcile`.

Cấu hình `Config.PetEvolution`:

```lua
Config.PetEvolution = {
	Copies = { -- số bản trùng để lên Stage 2 và Stage 3 (cộng dồn)
		["Baker Dog"] = { 8, 30 },
		["Muscle Duck"] = { 5, 14 },
		["Magician Cat"] = { 4, 10 },
		["K9 Dog"] = { 3, 7 },
		["Office Dragon"] = { 2, 4 },
	},
	HP = { 1, 1.25, 1.5 },
	Size = { 1, 1.2, 1.4 },
	Skill = { 1, 1.25, 1.5 },
}
```

Hàm dùng chung (đặt trong `Config.lua`, dùng ở cả client và server):
- `Config.PetStage(name, copies)` trả về 1, 2 hoặc 3.
- `Config.PetMaxHP(name, stage)` (thêm tham số Stage, mặc định 1 để các chỗ gọi cũ vẫn chạy).
- `Config.PetDurability(name, stage)`.

## 6. Đổi kích thước

- Server áp `model:ScaleTo(Size[stage])` khi dựng pet trong `Pets.spawnPet`; kích thước tự lan tới mọi client.
- Điều chỉnh theo kích thước: `OFFSET` (chỗ pet bay cạnh người) và `SHIELD_DISTANCE` nhân với hệ số, để pet to không đè lên người chơi hay che màn hình.
- **Kệ trưng bày** (`House.lua`) đã tự co pet vừa tầng kệ, nên **không** phóng to ở đó (hiện nhãn sao thay thế).
- **Ô Bag và hộp xem trước** dùng kích thước chuẩn (không phóng to), chỉ hiện sao.
- `PetEffects` trong model **tự co theo `root.Size.Y`** (viền, hạt, vầng hào quang), nên hiệu ứng đi theo kích thước mới.

### Rủi ro kỹ thuật chưa kiểm chứng

Pet là rig `Motor6D` và script `PetAnimator` ghi trực tiếp `Motor6D.Transform` từ keyframe. `ScaleTo` co các `Part` và vị trí nối, nhưng **phần dịch chuyển (nhảy, nhún) trong keyframe không tự co theo kích thước**, nên pet to có thể nhún nhỏ hoặc méo. Cần thử trong Studio (bước E0). Nếu méo, hai cách:
1. Vá `PetAnimator` (qua `tools/prepare_assets.py`, vì script này nằm bên trong từng model) để nhân phần dịch chuyển của pose với attribute `Scale` của model.
2. Giảm bớt hoạt ảnh dịch chuyển cho pet Stage cao.

Cũng cần kiểm tra `Humanoid` (pet có Humanoid khi dựng, `Pets.lua` hủy nó), nên `HipHeight` không phải lo ở đây (khác với kế hoạch gốc của repo assets).

## 7. Giao diện [ĐỀ XUẤT]

- **Bag, mục Pets:** tên có sao ("Baker Dog ★★") và thanh vàng tiến độ tới Stage tiếp theo.
- **Sổ loài (Pet Dex)** trong Bag (cũng là phần nhật ký sưu tập RETENTION R4): mỗi loài một hàng, có Stage, thanh "bản trùng 9/30", các chấm biến thể (Normal, Shiny, Golden).
- **Khi nở trùng:** dòng "Baker Dog +1 copy (9/30)". **Khi lên Stage:** hiệu ứng phóng to, chữ "Baker Dog evolved to Stage 2!", âm thanh.
- **Thông báo toàn phòng** (`SERVER_BOARD.md`) khi ai đó lên **Stage 3** của loài hiếm (K9, Dragon).
- **HUD:** pet hiện sao cạnh tên.
- Chữ hiện bằng tiếng Anh theo quy tắc repo.

## 8. Quan hệ với các hệ thống khác

| Hệ thống | Quan hệ |
|---|---|
| Độ bền, không sửa | Stage không sửa chữa (mục 3) |
| Biến thể Shiny, Golden | Biến thể gắn với từng con; Stage gắn với loài; hai thứ độc lập |
| Giá bán pet | Giữ theo giá gốc và tỉ lệ độ bền, **không** nhân theo Stage (tránh bán pet lớn kiếm lời) |
| Bảng điểm phòng | Có thể thêm điểm khi lên Stage (tùy chọn) |
| Kỹ năng pet (GĐ7) | Dùng hệ số `Skill` của Stage |
| Cướp nhà | Pet không bị cướp, Stage không bị mất khi bị cướp |
| Robux | Không bán Stage hay bản trùng (xem danh sách không bán ở `MakeRobuxInHere/`) |

## 9. Rủi ro

| Rủi ro | Giảm thiểu |
|---|---|
| Pet to che màn hình, nhất là điện thoại | Tối đa ×1.4, đẩy `OFFSET` theo kích thước, kiểm tra trên điện thoại |
| Hoạt ảnh méo khi `ScaleTo` | Thử ở bước E0 trước khi code |
| Stage cao làm game quá dễ | Đo tỉ lệ bị bắt theo Stage, chỉnh ngỗng, hạ hệ số nếu cần |
| Reed lên Stage 3 quá nhanh | Nếu thực tế nhanh hơn ~1.5 giờ thì tăng số bản trùng Baker Dog |
| Office Dragon Stage 3 quá lâu (hơn 10 giờ) | Chấp nhận (mục tiêu dài hạn); nếu người chơi bỏ cuộc thì giảm còn 3 |
| Dữ liệu cũ sai bộ đếm | Chuyển đổi thận trọng (số con đang có trừ 1) |
| Người chơi thấy bản trùng "vô dụng" khi đã đủ Stage 3 | Vẫn là dự phòng và bán được |

## 10. Các điểm đã chốt (16/10/2026, anh đồng ý theo đề xuất)

| # | Câu hỏi | Quyết định |
|---|---|---|
| 1 | Số bản trùng mục 2.1 | **Dùng ước lượng hiện tại**, chỉnh sau khi có số đo nở trứng thật |
| 2 | Thông báo toàn phòng khi lên Stage 3 loài hiếm (K9 Dog, Office Dragon) | **Có** (qua `ServerBoard.Announce`, `SERVER_BOARD.md`) |
