# Lối chơi chính: hồ thót tim, nhà dễ chịu, ngỗng sống, kéo căng thẳng, dụng cụ và coop

> Dành cho dev và người làm thiết kế. Cập nhật lần cuối 16/10/2026. **Chỉ là kế hoạch, chưa code.**
> Đọc kèm `SYSTEM_DESIGN.md` (ngỗng, cướp nhà), `../Economy/ECONOMY_DESIGN.md` (kinh tế), `../Overview/PROJECT_OVERVIEW.md` (code hiện tại).
> Số liệu kinh tế lấy từ `tools/sim_economy.py` (mô hình mới: `CATCH_PER_CAST`, `POND_HIT`).

## 0. Nhãn và điều đã chốt

| Nhãn | Nghĩa |
|---|---|
| **[ĐÃ CHỐT]** | Anh Scott đã quyết, chưa code |
| **[ĐỀ XUẤT]** | AI đề xuất, số chưa kiểm chứng |

**Đã chốt (16/10/2026):**
1. Làm cả 3 hướng nâng cấp: **B ngỗng sống**, **A kéo căng thẳng**, **C dụng cụ, kỹ năng pet và coop**.
2. **Ở hồ là thót tim, ở nhà là farm dễ chịu.**
3. **Nhà (ao):** an toàn, nhưng **chỉ 20% lần câu trúng rương**.
4. **Hồ:** **20% số lần câu bị bắt.** Câu **gần ngỗng thì bị bắt ngay.**
5. **Hồ có "câu tự do":** không cần ném vào các điểm câu riêng, nhưng **chỉ lên được ít tiền**.
6. **Coop là lựa chọn**, chơi đơn vẫn hoàn chỉnh.
7. Giữ **hai luồng riêng**: thu hút người mới và giữ chân người cũ (mục 6).

## 1. Hai không gian, hai cảm giác

| | **Hồ chính** | **Nhà (ao riêng)** |
|---|---|---|
| Cảm giác | Thót tim, tính toán từng giây | Thư giãn, farm đều tay |
| Rủi ro | Bị ngỗng bắt, mất cả túi | Không có |
| Phần thưởng | Đủ 5 loại rương, trứng, kỹ năng | Chỉ rương Wooden, tỉ lệ thấp |
| Nhịp độ | Ngắn, dồn dập, theo ngỗng | Dài, chờ phao, không áp lực |
| Vai trò | Nguồn tiền và tiến độ chính | Chỗ luyện, kiếm lúc ngỗng quá nguy hiểm, chỗ người mới bắt đầu |
| Hợp với | Người thích thử thách, chơi cùng bạn | Người thích thư giãn, người chơi trên điện thoại ngắn |

## 2. Luật đã chốt, chi tiết

### 2.1 Hồ: 20% lần câu bị bắt [ĐÃ CHỐT, cách đạt là ĐỀ XUẤT]

- **Chỉ số mục tiêu đo được:** trong tất cả lần **câu ở hồ** (kể cả câu tự do), **khoảng 20% kết thúc bằng bị ngỗng bắt** (mất đồ trong túi, về nhà).
- Đây là **kết quả cuối cùng** sau khi tính cả pet chặn và nước rút, không phải xác suất ngẫu nhiên rút ra mỗi lần. Đạt bằng cách chỉnh độ khó của ngỗng (mục 3), **không** bằng xúc xắc "20% bị bắt vô lý".
- Phải có **log đo thật** (mục 7) trước khi chỉnh. Hiện chưa có số đo nào về tỉ lệ bị bắt.

### 2.2 Câu gần ngỗng là bị bắt ngay [ĐÃ CHỐT, bán kính là ĐỀ XUẤT]

- Câu (ném phao hoặc đang kéo) khi ngỗng trong **bán kính nguy hiểm** (đề xuất **12 stud**, nhìn thấy hay không đều tính) thì **bị bắt ngay**, pet không chặn được.
- Giữ cơ chế **ngỗng quay lại** đang có (`Guard.Recall`): câu trong 20 giây sau khi ngỗng vừa đi ngang mà ngỗng còn trong 70 stud thì ngỗng quay lại đuổi.
- Hiển thị: vòng cảnh báo đỏ dưới chân ngỗng khi người chơi cầm cần câu, cho người chơi thấy "vùng cấm" (không phải bẫy ẩn).

### 2.3 Câu tự do ở hồ [ĐÃ CHỐT]

Em hiểu: ở hồ có **hai kiểu câu**.

| | **Câu ở điểm câu** (đang có) | **Câu tự do** (mới) |
|---|---|---|
| Ném phao | Phải gần phao CHEST (≤ 7 stud) | **Ném vào chỗ nước nào cũng được** |
| Loại rương | Theo bảng tỉ lệ của cần | Chỉ **Wooden**, **không có trứng** |
| Coins | Theo rương | **2 đến 4 coins** (ít) |
| Thời gian kéo | 6 đến 18 giây x Speed | **~3 giây** |
| Tiếng ồn | Bán kính 45, bắt đầu sau 3 giây | **Bán kính ~22** (nhỏ hơn) |
| Nguy hiểm | 20% bị bắt | **~10% bị bắt** (ồn ít hơn), vẫn bị bắt ngay nếu gần ngỗng |
| Chiếm ô túi | Có | Có (đã chốt) |
| Vai trò | Thu nhập chính | Dự phòng khi 3 rương đã bị lấy hết, và cách người mới tập câu ở hồ |

Thu nhập câu tự do em tính tay: **~9 coins/phút**, khoảng 40% câu điểm bằng Duckling và dưới 10% khi cầm Dragon. Mục đích không phải kiếm tiền mà là **không bao giờ phải đứng chờ** và **tập kỹ năng** mà ít rủi ro. Cần chạy lại bằng `tools/sim_economy.py` khi code.

### 2.4 Nhà (ao): 20% lần câu trúng rương [ĐÃ CHỐT, số khác là ĐỀ XUẤT]

- Mỗi lần ném phao ở ao: chờ cắn ~5 giây, **20% có rương Wooden** (rồi kéo 6 giây x Speed), **80% "không có gì cắn"** và tự thu phao.
- Vẫn an toàn tuyệt đối: không ngỗng, không bắt, vào thẳng tài khoản, **không hao cần**.
- Thay `PondTimeMult = 5` hiện tại bằng `PondHitChance = 0.2` và `PondWait = 5` trong `Config.Fishing`.
- Thu nhập ao: **~15 coins/phút với mọi cần** (cần tốt chỉ rút ngắn lúc kéo, không đổi tỉ lệ cắn). Bằng 69% hồ ở đầu game, còn 11% khi cầm Dragon, nên **người chơi giỏi sẽ tự lên hồ**.

### 2.5 Tác động kinh tế (em tính bằng `tools/sim_economy.py`)

| Cần | Hồ (mô hình cũ, 18% mất túi mỗi chuyến) | Hồ (mới, 20% bị bắt mỗi lần câu) | Mới/cũ | Ao cũ (luôn có rương) | Ao mới (20% trúng) |
|---|---|---|---|---|---|
| Duckling | 36.6 | 22.1 | 60% | 22.9 | 15.3 |
| Catfish | 43.2 | 26.0 | 60% | 24.7 | 15.4 |
| Turtle | 65.2 | 39.2 | 60% | 27.9 | 15.7 |
| Fox | 103.8 | 62.3 | 60% | 31.2 | 15.9 |
| Lucky Cat | 156.7 | 93.6 | 60% | 36.4 | 16.1 |
| Rainbow Dragon | 251.3 | 149.3 | 59% | 44.6 | 16.4 |

(Đơn vị: coins ròng mỗi phút, đã trừ hao mòn cần.)

**Vì sao giảm 40%:** túi 4 rương, bị bắt 20% mỗi lần câu nghĩa là chỉ khoảng 41% chuyến cất được đủ 4 rương, tính trung bình mỗi lần câu cất được **0.49 rương** thay vì 0.82 như mô hình cũ.

**Ba cách bù (đã chọn cách 1, mục 9):**

| Cách | Hệ quả |
|---|---|
| 1. Giảm **giá** cần, máy, ổ máy khoảng **40%** | Tiến độ giữ nguyên (cần Dragon ~6 giờ). Sửa `Config.Rods`, `Config.AutoFisher` |
| 2. Tăng **giá trị rương** (coins và giá bán trứng) khoảng **x1.65** | Tiến độ giữ nguyên, nhưng ảnh hưởng cả pet, giá bán, và mọi sink khác |
| 3. **Không bù**, chấp nhận chậm hơn | Cần Dragon khoảng 10 giờ thay vì 6, người chơi nghỉ lâu hơn ở mỗi bậc |

Đã chọn **cách 1** vì ít file hơn và dễ đảo lại. **Không chỉnh gì trước khi có số đo bị bắt thật** (mục 7), vì 20% là mục tiêu, kết quả thật có thể khác.

## 3. Hướng B: Ngỗng sống [ĐỀ XUẤT]

Mục tiêu: ngỗng không học thuộc được, và nguy hiểm tăng theo phần thưởng, để đạt ~20% bị bắt mà vẫn thấy công bằng.

### 3.1 Tuyến tuần tra không cố định

Hiện ngỗng đi 12 điểm cố định theo thứ tự (`Config.Guard.Patrol`, vòng ~43 giây). Đề xuất:

- Mỗi vòng **xáo thứ tự** các điểm kế tiếp (không quay đầu quá gấp), vẫn đi theo lối gạch.
- **Hành vi ngẫu nhiên** mỗi vài điểm: dừng 2 đến 4 giây, quay đầu nhìn sang bên, đổi tốc độ (đi chậm 7, đi thường 10, đi nhanh 13 stud/s).
- Giữ ngỗng vẫn **đọc được**: có "báo hiệu" trước khi đổi hướng (ngẩng đầu, kêu "honk" nhỏ) để người chơi có cơ hội phản ứng.

### 3.2 Ngỗng thứ hai khi có rương hiếm

| Rương trên hồ | Hậu quả |
|---|---|
| Wooden, Blue | Không đổi |
| Purple | Ngỗng nghe tiếng từ xa hơn (+20% bán kính tiếng ồn) |
| Golden | **Ngỗng thứ hai** xuất hiện ở phía đối diện hồ khi bắt đầu kéo, biến mất sau khi xong |
| Rainbow | Ngỗng thứ hai, đồng thời cả hai **đi nhanh hơn 15%** |

Cần `Config.Guard.Count` cho phép nhiều ngỗng, và `Guard.lua` quản lý nhiều đối tượng. SYSTEM_DESIGN đã dự định tổng quát hóa `Guard.lua` cho nhiều ngỗng.

### 3.3 Thời gian trong ngày (tùy chọn, làm sau)

Chu kỳ ~10 phút có "đêm": ngỗng nhìn xa 40 xuống 28 stud nhưng nghe tiếng động xa 45 lên 60 stud. Câu đêm lợi hơn nếu biết đi chậm. Chỉ làm nếu B cơ bản đã ổn.

### 3.4 Cách chỉnh để đạt ~20% bị bắt

Vòng lặp chỉnh (không đoán):
1. Ghi log mỗi lần câu ở hồ: kết quả (cất được / bị bắt / hụt), loại rương, có pet không, khoảng cách tới ngỗng.
2. Chơi thử đủ nhiều lượt (ít nhất 100 lượt câu), tính tỉ lệ bị bắt.
3. Chỉnh các tham số: `SightRange`, `SuspiciousTime`, `ChaseSpeed`, `NoiseRadius`, thời gian dừng của ngỗng.
4. Lặp lại tới khi nằm trong khoảng **15 đến 25%**.

## 4. Hướng A: Kéo căng thẳng [ĐỀ XUẤT]

Mục tiêu: nhả nút không còn là lựa chọn miễn phí, và rương hiếm cho cảm giác "đang giằng co".

### 4.1 Nhịp giãy của rương

Rương hiếm **giãy** vài lần trong lúc kéo. Mỗi lần giãy kéo dài **1.5 giây**, có báo hiệu trực quan (thanh kéo rung, âm thanh).

| Rương | Số lần giãy |
|---|---|
| Wooden, Blue | 0 |
| Purple | 1 |
| Golden | 2 |
| Rainbow | 3 |

Trong lúc giãy:
- **Đang giữ nút:** phát ra **tiếng động mạnh** (bán kính x1.5, ~68 stud). Ngỗng ở xa vẫn có thể nghe thấy.
- **Đang nhả nút:** an toàn về tiếng động, nhưng **mất 1 giây tiến độ**.

→ Người chơi phải **nhìn ngỗng** rồi quyết định: chịu ồn để giữ tiến độ, hay nhả và mất chút thời gian. Quyết định này thay đổi theo từng lần.

### 4.2 Giật cuối (tùy chọn)

Ở 90% tiến độ có cửa sổ **0.6 giây** để nhả và bấm lại ("giật"): đúng thì **+20% coins** của rương đó và không có tiếng ồn cuối. Trượt thì không mất gì. Mục đích là thưởng cho kỹ năng, không phải bắt buộc. Nếu thấy rối cho điện thoại thì bỏ.

### 4.3 Tác động lên độ khó

Rương hiếm càng hiếm càng khó. Cộng thêm với hướng B (ngỗng thứ hai khi Golden, Rainbow) để **phần thưởng lớn đi cùng rủi ro lớn** như thiết kế gốc.

## 5. Hướng C: Dụng cụ, kỹ năng pet và coop [ĐỀ XUẤT]

### 5.1 Kỹ năng chủ động của pet

Pet hiện chỉ là thanh máu. Thêm **một kỹ năng bấm nút**, thời gian hồi 45 giây (hiện ở HUD, dùng được cả khi chơi đơn):

| Pet | Kỹ năng | Hiệu quả |
|---|---|---|
| Baker Dog | Rải vụn bánh | Ngỗng dừng ăn 3 giây |
| Muscle Duck | Khiên | Chặn hộ 50% sát thương 5 giây |
| Magician Cat | Phân thân | Tạo mồi nhử, ngỗng đuổi mồi 4 giây |
| K9 Dog | Sủa | Ngỗng choáng 2.5 giây, bán kính 12 stud |
| Office Dragon | Khói | Ngỗng mất dấu, quên người chơi |

Kỹ năng **không** đổi độ bền hay HP, **không** làm người chơi miễn nhiễm. Dùng đúng lúc là tăng thêm vài giây.

### 5.2 Dụng cụ dùng một lần (mua bằng coins ở Tool Shop)

| Dụng cụ | Giá đề xuất | Hiệu quả |
|---|---|---|
| Decoy (mồi) | 80 | Ném ra, ngỗng đi kiểm tra mồi 5 giây |
| Smoke (khói) | 150 | Ngỗng mất dấu trong 3 giây |

Mang tối đa 3 mỗi loại, **không chiếm ô túi**. Là chỗ tiêu coins lặp lại, và mở ra "chơi thông minh". Chỉ mua bằng coins (xem `MakeRobuxInHere/` mục không bán).

### 5.3 Coop (đội 2 đến 4 người) [chơi tùy chọn]

Nguyên tắc: **chơi đơn không bị phạt**, coop chỉ nhanh hơn và vui hơn. Không có phần thưởng nào chỉ có trong coop (tránh ép chơi nhóm).

| Cơ chế | Cách chơi | Ghi chú |
|---|---|---|
| **Đội** | Mời bạn vào đội bằng bảng đội trong Bag (dùng danh sách bạn Roblox). Tối đa 4 | Không bắt buộc, rời đội bất cứ lúc nào |
| **Cảnh báo chung** | Mọi người trong đội thấy vị trí ngỗng bằng chấm trên HUD | Giảm khó cho người thiếu kinh nghiệm |
| **Dụ ngỗng** | Một người ném Decoy hoặc dùng kỹ năng pet để kéo ngỗng ra xa, người kia kéo rương | Vai trò tự nhiên, không phải chức vụ cứng |
| **Kéo chung** | Hai người cùng móc một rương (cùng điểm câu): tốc độ kéo x1.6, nhưng **tiếng ồn tính một lần** và **cả hai cùng bị bắt** nếu gần ngỗng | Cần server cho phép 2 người một điểm khi cùng đội |
| **Chạy tiếp sức** | Người này đưa túi cho người kia ngay tại hồ để người kia chạy về cất | **Hoãn**: cần luật chuyển đồ an toàn, dễ gây lỗi sao chép đồ |
| **Chia thưởng** | Rương kéo chung chia **70% cho người kéo chính, 30% cho người còn lại** (tổng lớn hơn rương đơn một chút) | Đảm bảo cả hai đều lời |

Làm **đội, cảnh báo chung, dụ ngỗng, kéo chung** trước. **Chạy tiếp sức** để sau cùng.

## 6. Hai luồng: thu hút người mới và giữ chân người cũ

| | **Thu hút (người mới)** | **Giữ chân (người cũ)** |
|---|---|---|
| Mục tiêu | 5 phút đầu phải có khoảnh khắc đáng quay clip, và có lý do rủ bạn | Có việc mới học, có mục tiêu, có lý do quay lại |
| Từ lối chơi chính | Ngỗng sống (B) tạo tình huống bất ngờ, buồn cười. Câu tự do (2.3) cho người mới tập ở hồ ít rủi ro. Ao nhà (2.4) là chỗ an toàn để học | Kéo căng thẳng (A) có kỹ năng để luyện. Ngỗng thứ hai, đêm (B). Dụng cụ và kỹ năng pet (C) có thể làm chủ |
| Coop | Rủ bạn vào đội, cảnh báo chung giúp người mới sống sót | Phối hợp dụ ngỗng, kéo chung rương hiếm |
| Việc cần làm ngoài lối chơi chính | Kịch bản 5 phút đầu: ấp trứng, câu ao, ra hồ lần đầu có người dẫn | Nhiệm vụ hằng ngày, nhật ký sưu tập, bảng xếp hạng (đã đề xuất ở lần tư vấn trước) |

## 7. Số liệu cần đo (làm trước khi chỉnh)

| Số liệu | Vì sao |
|---|---|
| Tỉ lệ bị bắt trên mỗi lần câu ở hồ (theo điểm câu / câu tự do, có pet / không pet) | Mục tiêu 20%, hiện chưa có số đo |
| Thời gian từ vào game tới lần câu hồ đầu tiên | Thu hút: mục tiêu dưới 3 phút |
| Số rương cất được mỗi chuyến, thời gian mỗi chuyến | Kiểm chứng mô hình kinh tế |
| Số lần nhả nút trong một lượt kéo | Kéo căng thẳng có thực sự tạo quyết định không |
| Tỉ lệ người chơi ở lại sau 1 ngày, 7 ngày (khi đã release) | Giữ chân |
| Số người chơi trong đội, tỉ lệ coop | Coop có được dùng không |

Cách ghi: log trên server (`print` ở Studio, sau đó `AnalyticsService` hay `DataStore` log khi release). Chưa làm.

## 8. Thứ tự làm [ĐỀ XUẤT]

| Giai đoạn | Việc | File chính | Xong khi |
|---|---|---|---|
| 0 | **Ghi log** lần câu, bắt, rương (không đổi gameplay) | `Fishing.lua`, `Guard.lua` | Có số đo bị bắt thật ở Studio |
| 1 | **Ao 20%** và **câu gần ngỗng bị bắt ngay** (vòng đỏ) | `Fishing.lua`, `Guard.lua`, `Config.lua` | Ao có "không có gì cắn", gần ngỗng bị bắt, có vòng cảnh báo |
| 2 | **Câu tự do** ở hồ | `Fishing.lua`, `FishingSpots.lua`, `Config.lua` | Ném chỗ nào cũng được, ra Wooden 2 đến 4 coins |
| 3 | **Hướng B**: tuyến ngẫu nhiên và hành vi dừng, quay đầu | `Guard.lua`, `Config.Guard` | Ngỗng không lặp lại, tỉ lệ bị bắt nằm 15 đến 25% |
| 4 | **Chỉnh kinh tế** theo số đo (cách 1, 2 hoặc 3 trong mục 2.5) | `Config.lua`, `tools/sim_economy.py` | Tiến độ cần Dragon ~6 giờ như thiết kế |
| 5 | **Ngỗng thứ hai** cho rương Golden và Rainbow | `Guard.lua`, `Fishing.lua` | Nhiều ngỗng chạy ổn, biến mất đúng lúc |
| 6 | **Hướng A**: rương giãy, tiếng ồn mạnh, mất tiến độ khi nhả | `Fishing.lua`, `MainUI.client.lua` (thanh kéo rung) | Purple, Golden, Rainbow giãy đúng số lần |
| 7 | **Hướng C**: kỹ năng pet và dụng cụ | `Pets.lua`, `Shop.lua`, `Data.lua`, `MainUI.client.lua` | Kỹ năng có thời gian hồi, dụng cụ mua và dùng được |
| 8 | **Coop**: đội, cảnh báo chung, dụ ngỗng, kéo chung | Module mới `Crews.lua`, `Fishing.lua`, `FishingSpots.lua` | 2 người chơi cùng đội kéo chung một rương |
| 9 | Đêm, giật cuối, chạy tiếp sức (tùy chọn) | | |

Bước 0 đến 4 chỉ đụng vào code hiện có. Bước 5 trở đi cần thêm hệ thống.

## 9. Các điểm đã chốt (16/10/2026, anh đồng ý theo đề xuất)

| # | Câu hỏi | Quyết định |
|---|---|---|
| 1 | Hiểu về câu tự do | **Đúng**: ném bất kỳ đâu ở hồ, chỉ Wooden, 2 đến 4 coins, ~3 giây, tiếng ồn bán kính ~22, bị bắt ~10% |
| 2 | Câu tự do chiếm ô túi | **Có** (giữ đơn giản, không làm loại "túi tiền" riêng) |
| 3 | Cách bù thu nhập sau khi 20% bị bắt | **Cách 1: giảm giá cần, máy, ổ máy khoảng 40%**, chỉ làm sau khi có số đo thật (GĐ4) |
| 4 | Bắt ngay khi pet còn khỏe | **Có**, pet không chặn được trong bán kính nguy hiểm |
| 5 | Mời coop | **Bằng danh sách bạn Roblox** (đội tự tìm người lạ để sau) |
| 6 | Đêm ở hồ | **Tùy chọn, làm sau cùng (GĐ9)**, chỉ khi B cơ bản đã ổn |

Danh sách việc cụ thể nằm ở `../ProjectManagement/TASKS.md` mục "Lối chơi chính".
