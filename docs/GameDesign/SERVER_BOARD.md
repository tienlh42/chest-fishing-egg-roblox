# Phòng nhỏ: bảng điểm và thông báo toàn server

> Dành cho dev và người làm thiết kế. Cập nhật lần cuối 16/10/2026. **Chỉ là kế hoạch, chưa code.**
> Đọc kèm `RETENTION.md` (giữ chân), `CORE_GAMEPLAY.md` (lối chơi chính), `../Art/PET_VARIANTS.md` (Shiny, Golden).
> Chưa release nên **chưa có số liệu**; mọi con số là **[ĐỀ XUẤT]**.

## 0. Nhãn và điều đã chốt

| Nhãn | Nghĩa |
|---|---|
| **[ĐÃ CHỐT]** | Anh Scott đã quyết, chưa code |
| **[ĐỀ XUẤT]** | AI đề xuất, cần chỉnh khi chơi thử |

**Đã chốt (16/10/2026):**
1. **Một server là một phòng nhỏ 4 đến 8 người** (khớp 8 plot nhà hiện có).
2. Mỗi phòng có **bảng điểm riêng** để xem ai đang đứng đầu.
3. Có **thông báo toàn server** (toàn phòng) khi có sự kiện đáng chú ý, ví dụ nở pet Golden.
4. Giá bán pet biến thể được **nhân lên** (Shiny x1.5, Golden x3).

Phần này **không phải** bảng xếp hạng tuần toàn cầu (`RETENTION.md` R6). Bảng ở đây chỉ nằm trong bộ nhớ của server, mất khi server đóng.

## 1. Phòng nhỏ

- Số người tối đa mỗi server: **8** (một plot mỗi người). Đặt ở Game Settings của Roblox (`MaxPlayers`), không có trong code. Cần kiểm tra khi publish.
- "Toàn server" nghĩa là **cả phòng đó**, không cần `MessagingService` hay DataStore. Đơn giản, rẻ, và đúng cảm giác phòng nhỏ.
- Phòng chỉ 1 người: bảng điểm vẫn hiện, nhưng **không có thưởng** (mục 4), để không farm thưởng một mình.

## 2. Bảng điểm [ĐỀ XUẤT]

### 2.1 Hiển thị

- Góc trên bên phải, thu gọn mặc định: hiện **top 3 và dòng của chính mình**. Bấm để mở đủ 4 đến 8 người.
- Mỗi dòng: hạng, tên hiển thị, điểm, biểu tượng cần đang cầm. Dòng của mình tô sáng.
- Điện thoại: chữ lớn, không che nút Fish, tự thu gọn sau vài giây không có thay đổi.
- Đồng hồ vòng ở đầu bảng: "Round ends in 14:20".

### 2.2 Vòng chơi 30 phút

Phù hợp phiên chơi tối đa ~30 phút đã chốt. Mỗi **vòng 30 phút** (theo đồng hồ server) bảng reset về 0. Cuối vòng thông báo kết quả, rồi vòng mới bắt đầu. Người vào giữa vòng bắt đầu từ 0 và vẫn có thể lên top vì điểm tính theo từng lần cất đồ an toàn.

### 2.3 Cách tính điểm (chỉ tính khi cất an toàn về nhà)

Điểm chỉ cộng khi rương **cất vào Stash thành công** (không phải lúc kéo lên), để cạnh tranh gắn với rủi ro chạy về nhà.

| Việc | Điểm |
|---|---|
| Cất rương Wooden | 1 |
| Cất rương Blue | 3 |
| Cất rương Purple | 8 |
| Cất rương Golden | 20 |
| Cất rương Rainbow | 50 |
| Rương câu tự do | 0 (để câu tự do không thành cách cày điểm) |
| Nở pet (Reed → Dragon) | 1 / 3 / 8 / 20 / 50 (cùng thang với rương) |
| Pet Shiny / Golden (cộng thêm) | +15 / +60 |
| Thoát ngỗng khi đang mang rương | +2 mỗi lần |
| Bị ngỗng bắt | 0, điểm đã cộng trước đó giữ nguyên, chỉ mất rương chưa cất |

(Sau này có cướp nhà: +10 mỗi món cướp được, ghi chú để sau.)

Thang điểm cùng tỉ lệ với giá trị rương (tăng khoảng x2.5 mỗi bậc) nên cân với kinh tế.

### 2.4 Công bằng giữa người mới và người cũ

Người cầm cần tốt ra nhiều rương hiếm hơn, nên thắng bảng nhiều hơn. Em đề xuất:
- **Bắt đầu chỉ có một bảng "Score"** như trên (đơn giản).
- Nếu thử thấy người mới luôn đứng cuối và nản, thêm **tab "Escapes"** (số lần thoát ngỗng khi mang rương), nơi kỹ năng quan trọng hơn cần câu.
- Không dùng điểm có hệ số bù theo cần ở giai đoạn đầu (khó giải thích với người chơi 13 đến 19 tuổi).

### 2.5 Thưởng cuối vòng (chỉ xu, không bắt buộc) [ĐỀ XUẤT]

Hợp với nguyên tắc nhiệm vụ: chỉ thưởng xu, tính theo phút thu nhập hiện tại của từng người.

| Hạng | Thưởng |
|---|---|
| 1 | 3 phút thu nhập |
| 2 | 2 phút |
| 3 | 1 phút |

Điều kiện: phòng có **ít nhất 2 người** có điểm và người nhận có **từ 10 điểm** trở lên. Thưởng nhỏ nên không đáng cho tài khoản phụ gian lận. Cần `IncomePerMinute(profile)` (RETENTION R0). Chưa có thì tạm dùng bảng tĩnh.

## 3. Thông báo toàn server [ĐÃ CHỐT ý, danh sách sự kiện là ĐỀ XUẤT]

### 3.1 Sự kiện nào được thông báo

Chỉ thông báo thứ **hiếm hoặc vui**, để không thành tiếng ồn.

| Sự kiện | Mẫu chữ (tiếng Anh) | Màu |
|---|---|---|
| Nở pet **Golden** | `<tên> hatched a Golden <pet>!` | Vàng |
| Nở pet **Shiny** | `<tên> hatched a Shiny <pet>!` | Xanh sáng |
| Cất rương **Rainbow** | `<tên> deposited a Rainbow Chest!` | Cầu vồng |
| **Bị bắt** khi đang mang rương Rainbow hoặc Golden | `The goose got <tên> with a <rương>!` | Đỏ (vui, không châm chọc) |
| Lên **Stage 3** của K9 Dog hoặc Office Dragon (`PET_EVOLUTION.md`) | `<tên>'s <pet> evolved to Stage 3!` | Vàng |
| Đổi người **đứng đầu** bảng điểm | `<tên> took 1st place!` | Cam |
| **Cuối vòng** | `Round over! 1st <tên> (<điểm>)` | Xanh lá |
| Người mới vào phòng | không thông báo (ồn) | |

### 3.2 Chống ồn và lạm dụng

- Tối đa **1 thông báo mỗi 6 giây**, xếp hàng, ưu tiên: Golden > Rainbow > đổi hạng > bắt > Shiny.
- Mỗi sự kiện cùng loại của cùng người cách nhau tối thiểu 30 giây.
- Chữ **do server tạo từ mẫu**, không có chữ người chơi tự nhập, nên không cần lọc chat. Tên dùng `DisplayName` của Roblox.
- Thông báo **không châm biếm** người bị bắt (tuổi 13 đến 19, tránh bắt nạt); mẫu đã trung tính.
- Có công tắc `Config.Board.Announce[tênSựKiện] = true/false` để tắt từng loại.

### 3.3 Hiển thị

- **Banner** giữa trên, hiện 4 giây, màu theo bảng trên, bấm bỏ qua.
- **Lịch sử** 20 thông báo gần nhất trong một tab nhỏ cạnh bảng điểm, để ai vừa vào cũng đọc được.
- Âm thanh ngắn cho Golden và Rainbow, **tắt được** (cài đặt âm thanh).

## 4. Kỹ thuật [ĐỀ XUẤT]

Module mới `ServerScriptService/Modules/ServerBoard.lua`:

```lua
Board.AddScore(player, points, reason)   -- cộng điểm, cập nhật bảng
Board.Announce(kind, data)               -- đưa thông báo vào hàng đợi (có giới hạn tốc độ)
Board.Snapshot()                         -- bản chụp bảng gửi xuống client
```

- **Dữ liệu chỉ nằm trong bộ nhớ**: `scores[player] = { Score, Chests, Escapes, BestChest }`, đồng hồ vòng, hàng đợi thông báo. Không lưu DataStore.
- **Nguồn điểm** (đã có sẵn chỗ gọi): `Bag.Deposit` (rương cất thành công), `Hatchery.lua` (nở pet, kèm biến thể), `Guard.lua` (thoát ngỗng, bắt người).
- **Gửi xuống client:** dùng `Remote.Effect` với `kind = "Board"` (bản chụp, 1 lần mỗi giây, hoặc ngay khi có thay đổi lớn) và `kind = "Announce"` (một thông báo). Không cần RemoteEvent mới.
- **Client** (`MainUI.client.lua`): vẽ bảng điểm và banner theo phong cách hiện có; hàm `progressBar` có thể dùng cho đồng hồ vòng.
- **Người vào / ra:** thêm vào bảng khi vào, bỏ khi ra (giữ điểm trong vòng nếu họ vào lại trong 2 phút).
- **Chống gian lận:** điểm cộng ở server, từ sự kiện thật, client không gửi điểm.

`Config.Board` (đề xuất):

```lua
Config.Board = {
	RoundMinutes = 30,
	Points = { Chest = { 1, 3, 8, 20, 50 }, Pet = { 1, 3, 8, 20, 50 }, ShinyBonus = 15, GoldenBonus = 60, Escape = 2 },
	RewardMinutes = { 3, 2, 1 },
	MinPlayersForReward = 2,
	MinScoreForReward = 10,
	AnnounceCooldown = 6,
	HistorySize = 20,
	Announce = { GoldenPet = true, ShinyPet = true, RainbowChest = true, CaughtRare = true, NewLeader = true, RoundEnd = true },
}
```

## 5. Giá pet biến thể [ĐÃ CHỐT]

Giá bán pet nhân thêm hệ số cho người sưu tầm (`Config.PetSellPrice` nhân `SellMult`): **Shiny x1.5, Golden x3**. Giá vẫn thấp hơn một bậc trứng cao hơn nên không phá kinh tế; cần xem lại khi có tần suất nở thật (xem `PET_VARIANTS.md`).

## 6. Rủi ro

| Rủi ro | Giảm thiểu |
|---|---|
| Phòng chỉ 1 hoặc 2 người, bảng buồn tẻ | Vẫn hiện, thưởng cần ≥ 2 người; mục tiêu vẫn là điểm bản thân |
| Người cũ luôn thắng, người mới nản | Tab "Escapes", thưởng chỉ top 3 nhỏ, vòng ngắn 30 phút để cơ hội mới |
| Tài khoản phụ nhường điểm | Thưởng nhỏ, cần ≥ 10 điểm và ≥ 2 người; ghi log để xem |
| Thông báo làm người khác ghen tị / bị chọc | Mẫu chữ trung tính, tắt được âm thanh |
| Banner che màn hình trên điện thoại | Nhỏ, tự tắt 4 giây, một cái một lần |
| Thông báo làm lộ người giàu cho kẻ cướp (khi có cướp nhà) | Thông báo Rainbow chỉ nói "cất rương", không nói nhà ở đâu; cân nhắc khi làm cướp nhà |
| Server đóng giữa vòng | Bảng mất theo server, không phạt; không ảnh hưởng dữ liệu |

## 7. Các điểm đã chốt (16/10/2026, anh đồng ý theo đề xuất)

| # | Câu hỏi | Quyết định |
|---|---|---|
| 1 | Độ dài vòng | **30 phút** |
| 2 | Thưởng top 3 | **Có**, chỉ xu: 3 / 2 / 1 phút thu nhập, cần ≥ 2 người có điểm và ≥ 10 điểm |
| 3 | Tab "Escapes" | **Chưa làm ở đầu**, chỉ thêm (B5) nếu người mới nản khi chơi thử |
| 4 | Prismatic | **Để sau** (sự kiện, season) |
