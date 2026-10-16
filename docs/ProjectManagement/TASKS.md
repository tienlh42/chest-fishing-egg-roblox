# TASKS: Danh sách việc cần làm

> Claude tick `[x]` và ghi chú ngay sau mỗi việc xong. Chi tiết từng việc xem `docs/ProjectManagement/DEVLOG.md`. Cập nhật lần cuối: 15/10/2026.
> Thứ tự lấy từ `docs/Economy/ECONOMY_DESIGN.md` mục 11 và `docs/GameDesign/SYSTEM_DESIGN.md` mục 15.

## Phòng nhỏ: bảng điểm và thông báo (CHƯA LÀM, anh sẽ làm sau): thiết kế ở `docs/GameDesign/SERVER_BOARD.md`

> Chốt: server là phòng 4-8 người, có bảng điểm riêng và thông báo toàn phòng; giá pet biến thể Shiny x1.5, Golden x3. Dữ liệu chỉ trong bộ nhớ server (không DataStore). Chạy `selene .`, test Studio, ghi DEVLOG sau mỗi việc.

### B0: Hạ tầng
- [ ] `Config.Board` (RoundMinutes 30, bảng điểm, thưởng, cooldown thông báo, danh sách bật / tắt sự kiện)
- [ ] `ServerBoard.lua`: `AddScore(player, points, reason)`, `Announce(kind, data)` (hàng đợi, 1 thông báo / 6 giây, ưu tiên), `Snapshot()`, đồng hồ vòng 30 phút
- [ ] Vào / ra phòng: thêm / bỏ người chơi, giữ điểm nếu vào lại trong 2 phút
- [ ] Đặt `MaxPlayers = 8` ở Game Settings của Roblox (kiểm tra khi publish)
- **Xong khi:** gọi `AddScore` trong Studio thấy bảng cập nhật, hết vòng thì reset

### B1: Nguồn điểm
- [ ] `Bag.Deposit`: cộng điểm theo loại rương cất thành công (câu tự do 0)
- [ ] `Hatchery.lua`: cộng điểm khi nở pet, cộng thêm Shiny / Golden (sau khi có biến thể pet R5)
- [ ] `Guard.lua`: +2 mỗi lần thoát ngỗng khi đang mang rương; ghi nhận bị bắt
- **Xong khi:** điểm chỉ cộng khi cất an toàn, client không gửi được điểm

### B2: Bảng điểm trên UI
- [ ] `MainUI.client.lua`: bảng góc trên phải thu gọn (top 3 + dòng của mình), bấm mở đủ 8 người, đồng hồ vòng, dòng của mình tô sáng
- [ ] Nhận `Remote.Effect` kind `"Board"`, vẽ lại tối đa mỗi giây, nhẹ trên điện thoại
- **Xong khi:** bảng đúng với 2-8 người, không che nút Fish

### B3: Thông báo toàn phòng
- [ ] Banner giữa trên (4 giây, màu theo loại), lịch sử 20 thông báo trong tab nhỏ
- [ ] Nối sự kiện: nở Golden / Shiny (`Hatchery.lua`), cất Rainbow (`Bag.lua`), bị bắt khi mang Rainbow / Golden (`Guard.lua`), đổi người đứng đầu và cuối vòng (`ServerBoard.lua`)
- [ ] Tắt / bật âm thanh thông báo
- **Xong khi:** mẫu chữ do server tạo, không có chữ người chơi nhập, không quá 1 thông báo mỗi 6 giây

### B4: Thưởng cuối vòng (phụ thuộc R0 `IncomePerMinute`)
- [ ] Top 3 nhận 3 / 2 / 1 phút thu nhập (chỉ xu), điều kiện ≥ 2 người có điểm và ≥ 10 điểm
- [ ] Thông báo kết quả và hiệu ứng nhận xu
- **Xong khi:** phòng 1 người không nhận thưởng, thưởng đúng theo thu nhập từng người

### B5: Tùy chọn
- [ ] Tab "Escapes" (số lần thoát ngỗng khi mang rương), chỉ làm nếu người mới nản khi chơi thử (đã chốt: chưa làm ở đầu)
- [ ] Điểm đội (khi có coop CORE_GAMEPLAY GĐ8)
- [ ] Điểm cướp nhà (khi có cướp)
- [ ] Thông báo toàn cầu qua `MessagingService` (nếu muốn nhiều phòng, chưa cần)

## Giữ chân (CHƯA LÀM, anh sẽ làm sau): thiết kế ở `docs/GameDesign/RETENTION.md`

> Chốt: nhiệm vụ lặp lại, chỉ thưởng xu, không bắt buộc; phiên ≤ 30 phút nên rút ngắn thu hoạch; không Rebirth; cosmetic để sau. Chạy `selene .`, test Studio, ghi DEVLOG sau mỗi việc. Giai đoạn R độc lập với GĐ của lối chơi chính, trừ chỗ ghi phụ thuộc.

### R0: Hạ tầng dùng chung
- [ ] `Economy.lua` (server): hàm `IncomePerMinute(profile)` port từ `tools/sim_economy.py` (cần đang cầm + máy đang có, dùng bảng `Odds`, `Speed`, tỉ lệ bắt hiện hành); có sàn và trần hợp lý
- [ ] Hàm dùng chung `Day()` (ngày theo UTC) để dùng cho giới hạn nhiệm vụ và hộp thư quà
- [ ] Kiểm tra bằng bản Python tương đương: kết quả khớp `tools/sim_economy.py` ở mọi cần
- **Xong khi:** `IncomePerMinute` đúng ở 6 cần, `selene .` sạch

### R1: Quest Board (nhiệm vụ lặp lại)
- [ ] `Config.Quests`: kho 12-15 nhiệm vụ (loại sự kiện, số lượng, số phút thưởng 1 / 1.5 / 2, điều kiện hiện); `Config.QuestBoard = { Slots = 3, DailyFull = 12, OverCapRatio = 0.25, SwapCooldown = 120 }`
- [ ] `Data.lua`: `profile.Quests = { Active, DoneToday, Day, NextSwapAt }`, thêm qua `reconcile`
- [ ] Module `Quests.lua`: chọn nhiệm vụ theo giai đoạn người chơi, nhận sự kiện tiến độ, nhận xu (`IncomePerMinute x phút`, hệ số sau mức 12/ngày), thay nhiệm vụ mới sau khi nhận, đổi nhiệm vụ (chờ 2 phút)
- [ ] Nối sự kiện: `Fishing.lua` (kéo, câu tự do, câu ao, thoát ngỗng), `Bag.lua` (cất rương), `Stash.lua` (mở rương), `AutoFishers.lua` (thu máy), `Hatchery.lua` (ấp, nở)
- [ ] Action `ClaimQuest(slot)`, `SwapQuest(slot)` trong `Main.server.lua`, kiểm tra dữ liệu client
- [ ] UI `MainUI.client.lua`: nút QUESTS ở dock với huy hiệu, bảng 3 hàng (thanh tiến độ, nút Claim, nút Swap), dòng nhỏ trên HUD, hiệu ứng nhận xu
- **Xong khi:** hoàn thành → nhận xu → nhiệm vụ mới xuất hiện, chơi đơn đủ 3 ô, sau 12 nhiệm vụ thưởng còn 25%

### R2: Rút ngắn thời gian thu hoạch
- [ ] Chạy lại `tools/sim_economy.py` (`COLLECT_EVERY` = 10 phút, `Capacity` mới 3 / 4 / 5 / 8 / 12), ghi số vào `docs/Economy/ECONOMY_DESIGN.md` mục 4
- [ ] `Config.AutoFisher.Tiers[].Capacity` đổi theo bảng trong RETENTION mục 3 (Interval và Durability giữ nguyên)
- [ ] `Plots.lua`: bảng chữ, thanh Fill, animation Full theo kho mới
- [ ] Chấp nhận giảm ~7% (đã chốt), chỉ bù nếu mô phỏng cho thấy lệch quá nhiều
- **Xong khi:** kho máy đầy sau 9 đến 20 phút, tổng thu nhập mô phỏng giảm không quá ~7%

### R3: Thanh mục tiêu, tổng kết cuối phiên, quà đăng nhập
- [ ] `Economy.lua`: hàm `NextGoal(profile)` trả về món rẻ nhất chưa có (cần, máy, ổ máy) và giá
- [ ] HUD: thanh "Catfish Rod 62/150", bấm mở Shop
- [ ] Sau mỗi lần thu máy, toast "Next machine full in X min; egg hatching Y min"
- [ ] Bật lại `Config.House.Daily`: đổi thành chỉ xu, chuỗi 7 ngày, lỡ ngày chỉ lùi 1 bậc (đã chốt)
- **Xong khi:** thanh đúng ở mọi giai đoạn, toast hiện đúng thời gian, quà nhận được 1 lần mỗi ngày

### R4: Nhật ký sưu tập và thành tựu
- [ ] `profile.Collection` (rương đã kéo, pet đã có), `profile.Titles`
- [ ] Bag: mục Nhật ký (màu / bóng đen), bảng thành tựu, chọn danh hiệu hiển thị trên bảng tên
- [ ] Dùng lại sự kiện của Quest Board
- **Xong khi:** thành tựu mở đúng, danh hiệu không đổi sức mạnh

### R5: Biến thể pet (đổi màu và hiệu ứng): thiết kế ở `docs/Art/PET_VARIANTS.md`
- [ ] **V0 thử trong Studio** (Command Bar): chạy thử đổi màu Shiny và Golden cho 5 pet, chụp ảnh, chốt danh sách part bỏ qua và hue shift từng pet; chụp lại ảnh cho tài liệu
- [ ] **V1 cấu hình và dữ liệu:** `Config.PetVariants` (Shiny 1%, bảo hiểm 150; Golden 0.1%); `pet.Variant` trong bản ghi pet; `profile.PityShiny`; `Data.NewPet(profile, name, variant)`
- [ ] **V2 đổi màu:** `Models.ApplyVariant(model, variant)` dùng ở `Pets.spawnPet`, kệ trưng bày (`House.lua`), viewport Bag (`MainUI.client.lua`); đặt attribute `Variant`
- [ ] **V3 tung biến thể khi nở:** `Hatchery.lua` tung Shiny / Golden (có bảo hiểm), gửi `Variant` trong `Effect "Hatched"`; `Effects.client.lua` hiệu ứng nở riêng (chữ SHINY! / GOLDEN!, lóe sáng, âm thanh); thông báo toàn phòng khi Golden / Shiny qua `ServerBoard.Announce` (đã chốt, xem mục B3)
- [ ] **V4 hiệu ứng:** `PetVariantEffects.client.lua` (đổi màu Highlight sẵn có, hạt, vầng hào quang, vệt Golden); ngân sách ≤ 8 pet trong 60 stud
- [ ] **V5 UI:** nhãn SHINY / GOLDEN và viền màu trong Bag, 3 chấm biến thể trong nhật ký sưu tập, tên "Shiny ...", hệ số giá bán Shiny x1.5, Golden x3 trong `Config.PetSellPrice` (đã chốt)
- [ ] **V6 (sau, cosmetic Robux):** skin pet dùng lại hàm đổi màu (xem `MakeRobuxInHere/`)
- **Xong khi:** 5 pet x 3 biến thể nhìn đúng, hiệu ứng không làm nặng khi có nhiều pet, biến thể không đổi HP hay độ bền

### R5b: Tiến hóa pet theo loài: thiết kế ở `docs/GameDesign/PET_EVOLUTION.md`
> Làm **sau GĐ0 (đo) và GĐ3 (ngỗng sống)** để đo được tỉ lệ bị bắt theo Stage pet. Kỹ năng (`Skill`) gắn vào lúc làm GĐ7.
- [ ] **E0 thử trong Studio:** `ScaleTo` x1.2 / x1.4 trên 5 pet đang chạy animation (Idle, Walk, Run, Attack); xem có méo / nhún sai không; nếu méo thì vá `PetAnimator` qua `tools/prepare_assets.py` (nhân phần dịch chuyển với attribute `Scale`)
- [ ] **E1 cấu hình và dữ liệu:** `Config.PetEvolution` (Copies, HP, Size, Skill), `Config.PetStage(name, copies)`, `Config.PetMaxHP(name, stage)` và `Config.PetDurability(name, stage)` (tham số Stage mặc định 1); `profile.PetStages`; chuyển đổi dữ liệu cũ trong `reconcile` (số con đang có trừ 1)
- [ ] **E2 nở trứng:** `Hatchery.lua` cộng bản trùng cho loài (lần nở đầu chỉ tạo khóa = 0); lên Stage thì cộng phần tăng độ bền cho mọi con cùng loài (không đầy lại); `Data.NewPet` dùng độ bền đầy của Stage hiện tại
- [ ] **E3 `Pets.lua`:** HP tối đa theo Stage (giữ tỉ lệ HP khi đổi Stage), `ScaleTo` khi dựng pet, `OFFSET` và `SHIELD_DISTANCE` nhân theo kích thước
- [ ] **E4 UI:** sao cạnh tên pet (Bag, HUD), Sổ loài (Pet Dex) có Stage + thanh bản trùng + chấm biến thể, hiệu ứng và chữ khi nở trùng / lên Stage, thông báo toàn phòng khi lên Stage 3 của K9 Dog và Office Dragon (đã chốt)
- [ ] **E5 cân bằng:** đo tỉ lệ bị bắt theo Stage pet (log GĐ0), chỉnh hệ số hoặc ngỗng nếu Stage 3 làm game quá dễ; cập nhật `docs/Economy/ECONOMY_DESIGN.md` mục 5 (pet)
- **Xong khi:** nở trùng làm loài lên Stage đúng mốc, pet to đúng kích thước không méo, pet hỏng không mất Stage, lên Stage không hồi đầy độ bền

### R6: Bảng xếp hạng tuần và sự kiện theo giờ (phụ thuộc CORE_GAMEPLAY GĐ5)
- [ ] `OrderedDataStore` cho điểm tuần (rương hiếm nhất, tổng rương), reset theo tuần UTC
- [ ] Bảng xếp hạng trong UI
- [ ] Sự kiện Ngỗng Vàng / rương Mythic rơi, lặp nhiều lần mỗi ngày
- **Xong khi:** bảng xếp hạng cập nhật đúng, sự kiện bắt đầu và kết thúc đúng giờ

### R7: Season và cosmetic (SAU, khi đã có người chơi và số liệu)
- [ ] Đường thưởng miễn phí 4-6 tuần, thưởng cosmetic (cosmetic làm sau, xem `MakeRobuxInHere/`)

## Lối chơi chính (CHƯA LÀM, anh sẽ làm sau): thiết kế ở `docs/GameDesign/CORE_GAMEPLAY.md`

> Làm theo thứ tự GĐ0 đến GĐ9. Mỗi GĐ chạy được độc lập, dừng sau GĐ nào cũng được. Sau mỗi việc: `selene .`, test Studio (Stop/Play), thêm mục DEVLOG, cập nhật `docs/Overview/PROJECT_OVERVIEW.md`.
> Chốt: ao 20% trúng rương; hồ 20% lần câu bị bắt; câu gần ngỗng (12 stud) bị bắt ngay kể cả pet khỏe; câu tự do chiếm ô túi; bù kinh tế bằng cách giảm giá ~40% sau khi đo; coop mời bằng bạn Roblox; đêm để sau cùng.

### GĐ0: Ghi log để đo (không đổi gameplay)
- [ ] `Config.Telemetry = { Enabled }` (bật trong Studio, tắt khi publish)
- [ ] Module `Telemetry.lua`: hàm `Log(player, event, data)`, lưu bộ đếm trong phiên, in tổng kết khi người chơi thoát
- [ ] `Fishing.lua`: log mỗi lần câu ở hồ: kiểu (điểm câu / tự do), loại rương, có pet, khoảng cách tới ngỗng lúc ném, kết quả (cất được / bị bắt / hụt)
- [ ] `Guard.lua`: log mỗi lần ngỗng chuyển sang Chase và mỗi lần bắt được người
- [ ] `Bag.lua`: log số rương cất mỗi chuyến, thời gian chuyến
- [ ] Lệnh Studio in bảng: tỉ lệ bị bắt trên mỗi lần câu, rương mỗi chuyến
- [ ] Chơi thử ≥ 100 lượt câu ở hồ, ghi số vào DEVLOG (tỉ lệ bị bắt thật, thời gian chạy về thật)
- **Xong khi:** có số đo tỉ lệ bị bắt thật, `selene .` sạch

### GĐ1: Ao 20% và câu gần ngỗng bị bắt ngay
- [ ] `Config.Fishing`: thay `PondTimeMult` bằng `PondHitChance = 0.2`, `PondWait = 5`; thêm `DangerRange = 12`
- [ ] `Fishing.lua` (ao): mỗi lần ném chờ `PondWait` giây, 20% ra Wooden (rồi kéo `HoldTime x Speed`), 80% báo "Nothing bites" và thu phao
- [ ] `Fishing.lua` (hồ): ném phao hoặc đang kéo khi ngỗng trong `DangerRange` thì bị bắt ngay (pet không chặn)
- [ ] `Guard.lua`: hàm `Guard.NearestDistance(position)` để `Fishing.lua` hỏi; giữ nguyên `Guard.Recall`
- [ ] Client: vòng đỏ dưới chân ngỗng khi cầm cần (cho thấy vùng cấm)
- [ ] Chạy lại `tools/sim_economy.py` với `POND_HIT = 0.2`, ghi vào `docs/Economy/ECONOMY_DESIGN.md` mục 3.2
- **Xong khi:** ao có "không có gì cắn", gần ngỗng bị bắt ngay, có vòng cảnh báo

### GĐ2: Câu tự do ở hồ
- [ ] `Config.Fishing.FreeCast = { Coins = { 2, 4 }, HoldTime = 3, NoiseRadius = 22, ChestIndex = 1 }`
- [ ] `Fishing.lua`: ném phao vào nước hồ nhưng ngoài điểm câu thì chạy chế độ câu tự do (chỉ Wooden, không trứng, coins 2-4, chiếm 1 ô túi)
- [ ] `FishingSpots.lua`: câu tự do không cần `Claim` điểm câu, không giới hạn người
- [ ] `Bag.lua`: lưu loại rương câu tự do (Wooden không trứng) để `Stash.lua` mở ra đúng 2-4 coins
- [ ] Client: thanh kéo ngắn hơn, ghi "Free cast"
- [ ] Chạy `tools/sim_economy.py` kiểm tra ~9 coins/phút
- **Xong khi:** ném chỗ nào cũng được, lên Wooden 2-4 coins, bị bắt ~10%

### GĐ3: Hướng B, ngỗng sống
- [ ] `Config.Guard`: thêm `PatrolShuffle`, `PauseChance`, `PauseTime = { 2, 4 }`, `SpeedChoices = { 7, 10, 13 }`, `TurnChance`
- [ ] `Guard.lua`: xáo thứ tự điểm kế tiếp mỗi vòng (không quay đầu gấp)
- [ ] `Guard.lua`: hành vi dừng, quay đầu nhìn sang bên, đổi tốc độ; có báo hiệu (ngẩng đầu, "honk" nhỏ) trước khi đổi hướng
- [ ] Animation `Alert` / `Idle` cho các hành vi mới
- [ ] Chỉnh tham số (`SightRange`, `SuspiciousTime`, `ChaseSpeed`, `NoiseRadius`) tới khi tỉ lệ bị bắt nằm **15-25%** (đo bằng GĐ0)
- **Xong khi:** ngỗng không lặp lại, tỉ lệ bị bắt 15-25% trên ≥ 100 lượt

### GĐ4: Chỉnh kinh tế theo số đo
- [ ] Đặt `CATCH_PER_CAST` và `LOSS` trong `tools/sim_economy.py` theo số đo thật, chạy lại toàn bộ
- [ ] Giảm giá cần, máy, ổ máy khoảng 40% (cách 1) trong `Config.Rods`, `Config.AutoFisher`; chạy sim kiểm tra cần Dragon ~6 giờ
- [ ] Cập nhật `docs/Economy/ECONOMY_DESIGN.md` mục 3, 4, 9
- **Xong khi:** tiến độ mô phỏng khớp thiết kế, bảng giá trong tài liệu khớp `Config.lua`

### GĐ5: Ngỗng thứ hai cho rương Golden và Rainbow
- [ ] `Config.Guard`: `Count` cho nhiều ngỗng, bảng `ExtraGoose = { Golden = 1, Rainbow = 1 }`, `RainbowSpeedBonus = 1.15`, `PurpleNoiseBonus = 1.2`
- [ ] `Guard.lua`: quản lý nhiều ngỗng (danh sách, Chase riêng từng con), sinh ngỗng thứ hai ở phía đối diện hồ khi bắt đầu kéo, biến mất khi xong
- [ ] `Fishing.lua`: báo `Guard` khi bắt đầu / xong kéo rương Purple, Golden, Rainbow
- **Xong khi:** nhiều ngỗng chạy ổn, ngỗng thứ hai xuất hiện và biến mất đúng lúc, không rò ngỗng

### GĐ6: Hướng A, kéo căng thẳng
- [ ] `Config.Chests[].Thrash` (0, 0, 1, 2, 3) và `Config.Fishing.Thrash = { Duration = 1.5, LoudRadius = 68, ReleasePenalty = 1 }`
- [ ] `Fishing.lua`: chia thời gian kéo thành các nhịp giãy; giữ nút trong lúc giãy thì gây tiếng ồn mạnh; nhả thì trừ 1 giây tiến độ
- [ ] Client: thanh kéo rung và âm thanh báo trước khi giãy
- [ ] (Tùy chọn) giật cuối ở 90% (cửa sổ 0.6 giây, +20% coins), bỏ nếu rối trên điện thoại
- **Xong khi:** Purple 1 lần, Golden 2, Rainbow 3, người chơi thấy rõ lúc nào giãy

### GĐ7: Hướng C, kỹ năng pet và dụng cụ
- [ ] `Config.Pet.Stats[].Skill = { Name, Cooldown = 45, ... }` cho 5 pet
- [ ] `Pets.lua`: nhận lệnh dùng kỹ năng từ client, kiểm tra hồi chiêu, áp hiệu ứng lên ngỗng
- [ ] `Config.Gadgets = { Decoy, Smoke }`, `profile.Gadgets` (tối đa 3 mỗi loại, không chiếm ô túi), mua ở `Shop.lua`
- [ ] `Guard.lua`: ngỗng bị dụ (Decoy), mất dấu (Smoke, Office Dragon)
- [ ] Client: nút kỹ năng pet có thanh hồi, nút dụng cụ, hiển thị số lượng
- **Xong khi:** kỹ năng có thời gian hồi, dụng cụ mua và dùng được, không đổi HP hay độ bền

### GĐ8: Coop
- [ ] Module `Crews.lua`: tạo đội, mời bạn Roblox (`Players:GetFriendsAsync` hay `IsFriendsWith`), tối đa 4, rời đội
- [ ] Client: bảng đội trong Bag, thông báo lời mời
- [ ] Cảnh báo chung: chấm vị trí ngỗng trên HUD cho cả đội
- [ ] `FishingSpots.lua`, `Fishing.lua`: kéo chung (2 người cùng đội một điểm, tốc độ x1.6, tiếng ồn tính một lần, cả hai bị bắt nếu gần ngỗng)
- [ ] Chia thưởng 70/30, tổng lớn hơn rương đơn một chút
- [ ] Kiểm tra server: chỉ cùng đội mới kéo chung, chống sao chép đồ
- [ ] (Hoãn) chạy tiếp sức, cần luật chuyển đồ an toàn
- **Xong khi:** 2 người cùng đội kéo chung được một rương, chơi đơn không đổi gì

### GĐ9: Tùy chọn
- [ ] Đêm ở hồ (chu kỳ ~10 phút, ngỗng nhìn kém nhưng nghe rõ hơn)
- [ ] Giật cuối (nếu chưa làm ở GĐ6)
- [ ] Chạy tiếp sức (coop)

## Bước 5: Kho nhà giữ rương chưa mở + mở rương (XONG)

- [x] `Config.Stash` (OpenRange) và `Config.FindChest(name)`
- [x] `Data.lua`: `profile.Chests = { [tên rương] = số lượng }`, tự bổ sung cho người cũ (`reconcile`)
- [x] `Bag.Deposit`: cất vào Stash chỉ chuyển rương vào kho (lưu xong mới tính, lỗi thì hoàn lại)
- [x] `Fishing.lua`: rương hồ cấm vào túi chỉ giữ tên rương, chưa tung coins / trứng
- [x] Module mới `Stash.lua`: `OnPrompt` (túi có đồ thì cất, rồi mở bảng Stash), `OpenChest(name, all)`, `OpenAll()`; tung nội dung lúc mở, kiểm tra tên rương + số lượng + đứng gần Stash. Thêm `Plots.StashPosition`, nút [E] đổi thành "Open"
- [x] `Main.server.lua`: nối `OnStash = Stash.OnPrompt`, thêm Action `OpenChest`, `OpenAllChests`
- [x] UI `MainUI.client.lua`: bảng "Stash" liệt kê rương theo cấp, nút Open / Open all; Bag có dòng "chest đang chờ trong Stash"
- [x] `Effects.client.lua`: hiệu ứng `Deposit` hiện "N chests stashed" thay vì "+0 coins", `Collect` dùng cho mở rương
- [x] Tutorial: chữ bước 3 nhắc mở rương ở Stash
- [x] Chạy `selene .` (0 lỗi). Studio đang chạy bản code CŨ hơn repo nhiều (Rojo không nối) nên đã đồng bộ cả 18 script qua MCP
- [x] Test server trong Play: cất 3 rương → kho đúng; mở xa Stash bị chặn; tên rương sai / hết rương bị chặn; Open một, Open all, mở kho trống đều đúng
- [x] Test UI bảng Stash trong Play: `Stash.OnPrompt` mở bảng đúng, bảng hiện rương + nút, gọi Action từ client rồi bảng cập nhật. (Chưa bấm chuột thật / [E] thật, chưa câu thật rồi cất)
- [x] Ghi `docs/ProjectManagement/DEVLOG.md` #39 + cập nhật `docs/Overview/PROJECT_OVERVIEW.md`, `docs/GameDesign/SYSTEM_DESIGN.md` (mục 5.2), `docs/Economy/ECONOMY_DESIGN.md` (mục 11)

**BƯỚC 5 XONG (15/10/2026).** Còn lại nên làm tay: câu thật một lần ở hồ, về cất, bấm [E] mở, xem hình hiệu ứng.

## Bước 6: Cướp nhà (ECONOMY_DESIGN mục 7)

- [x] **6.1** `Config.Robbery` (KeyPrice 200, MaxTries 4, Shield 600s, `LockOdds` 50/40/30/20%, `LockPrices` 3000/10000/30000) + profile `Keys`, `LockLevel`, `ShieldUntil` (+ `reconcile`)
- [x] **6.2** Mua Chìa vạn năng ở Tool Shop (Action `BuyKey`, mục "Robbery" trong Shop; số chìa hiện ở đầu bảng Bag, chưa có trên HUD chính)
- [x] **6.3** Vùng an toàn theo từng người: `SafeZone.Contains(position, player)` chỉ tính nhà mình + điểm hồi sinh; sửa 5 chỗ gọi (`Bag`, `Fishing`, `Guard` x2, `Pets`)
- [x] **6.4** Module `Robbery.lua`: nút [E] ở Stash người khác và máy câu người khác, kiểm tra chủ online, khiên, số lần thử; dùng chìa (50% mở), tiêu chìa mỗi lần
- [x] **6.5** Bảng cướp trên client: danh sách rương / trứng / kho máy, tự chọn món, tối đa bằng ô túi trống; giữ [E] ~3 giây mỗi món
- [x] **6.6** Lấy đồ trên server: khóa theo plot chống nhân đôi, món vào túi kẻ cướp, về nhà cất thì thuộc về họ
- [x] **6.7** Báo động lần thử đầu: thông báo chủ nhà (kèm tên kẻ cướp), đồng hồ 60 giây trong sân người khác (hiện trên client). Hết giờ tạm xử như bị bắt, ngỗng nhà thật ở 7.2
- [x] **6.8** Bị ngỗng bắt thì món cướp trả về kho chủ nhà; chủ thoát game giữa vụ (thu hồi plot, đưa người trong sân ra)
- [x] **6.9** Khiên 10 phút sau khi bị cướp; người đang hướng dẫn không bị cướp
- [x] **6.10** Test Play (tự cướp nhà mình bằng bản Robbery vá tạm trong Studio vì chỉ có 1 người), selene, đồng bộ Studio, DEVLOG #41
- [ ] **6.11** NHỜ ANH: test thật 2 người (Studio > Test > 2 Players): người B mua chìa, đứng sân A bấm [F] ở Stash, lấy món, chạy về cất / để hết giờ

## Bước 7: Ngỗng nhà, khóa cửa, perk (ECONOMY_DESIGN mục 7.1, 8; SYSTEM_DESIGN mục 8)

- [x] **7.1** Tổng quát hóa `Guard.lua` thành nhiều ngỗng (ngỗng hồ + ngỗng nhà mỗi plot có chủ, trần ~16)
- [x] **7.2** Ngỗng nhà đi vòng quanh plot, bỏ qua chủ, hết 60 giây thì rượt kẻ lạ
- [x] **7.3** Ngỗng đồn cảnh sát (sinh khi có cướp, tối đa 3). Đồn tạm = điểm cạnh Spawn, CHƯA có công trình đồn trên map
- [x] **7.4** Mua khóa cửa 3 cấp ở Tool Shop (Action `BuyLock`), tỉ lệ mở của chìa theo cấp khóa
- [x] **7.5** `Loadout.lua`: gộp perk cần + pet + giày (NoiseDelay, Leash, SightMult, CoinMult, EggChanceMult, StunEvery, DamageTaken...) và nối vào Fishing / Guard / Pets
- [x] **7.6** selene, đồng bộ Studio, Play thử khói (ngỗng nhà / đồn sinh ra, perk, khóa), DEVLOG #42, docs
- [ ] **7.7** (chưa làm) Thang nghi ngờ đầy đủ (SYSTEM_DESIGN 8.3); hiện ngỗng nhà chỉ rượt người "bị truy nã" (đã thử khóa hoặc hết 60 giây)
- [ ] **7.8** (chưa làm) Perk K9 `WarnRange`, công trình đồn cảnh sát, hiện perk trên HUD, hiện số chìa / khóa trên HUD
- [ ] **7.9** NHỜ ANH: chơi thử toàn bộ luồng rồi báo chỗ cần chỉnh (xem DEVLOG #42 mục "Anh nên test")

## Bước 8: Chơi thử và cân bằng

- [ ] Đo 4 số thật (tỉ lệ mất túi, xác suất kẻ cướp thoát, rương/phút ở hồ, HP pet mất mỗi giờ)
- [ ] Chỉnh lại bằng `tools/sim_economy.py`

## Việc tồn từ các đợt trước

- [ ] Chạy `selene .` và Play thử các đợt #34 đến #38 (độ bền cần / pet / máy, thanh progress bar) chưa test trong Studio
- [ ] Gộp pet trùng (điều kiện chưa chốt)
- [ ] Rương từ ao nhà và máy câu: vào kho (bị cướp được) hay mở ngay? (đang mở ngay)
- [ ] Bật lại quà hằng ngày (`Config.House.Daily.Enabled`) khi tới lúc

## Khu chợ (Tool Shop + Market sát nhau) (15/10/2026)

- [x] `ShopBuilder.lua`: quảng trường 2 gian sát nhau ở khe góc 225° (Tool Shop trái, Market phải), Market cũ ở 45° đã bỏ
- [x] Người bán: Bác Vịt Câu Cá (Tool Shop), Cô Mèo Thu Mua (Market), dựng bằng Part, nhún nhẹ (tag Bobbing)
- [x] Tool Shop: biển cá há miệng, tường trưng bày 6 cần theo thứ tự, 2 máy câu Common / Mythic, xô cá. Market: biển đồng xu tai mèo, rổ trứng 5 loại
- [ ] Anh xem trong Play và chỉnh (kích thước, màu, vị trí). Cần xem: tường trưng bày cần, tủ máy, hướng mặt người bán
- [ ] (chưa làm) Người bán phản ứng khi mở shop (vẫy tay, tim / sao), cần sáng theo cần đã mua (client), animation Idle riêng

## Shop chỉ mua đồ, nâng cấp ở nhà (15/10/2026)

- [x] Toast hệ thống luôn trên cùng (ScreenGui riêng DisplayOrder 100)
- [x] Shop chỉ còn cần, túi, chìa, giày; máy ấp / ổ máy / máy câu / khóa cửa chuyển về nhà (bảng Build, [E] / [G] trên bệ, máy, biển tên)
- [x] Server chặn mua / nâng cấp khi không đứng trong sân nhà mình
- [ ] Anh test thật: bấm [E] ở bệ máy ấp khóa, ổ máy, [G] ở máy, [E] ở biển tên

## Thiết kế lại nhà (15/10/2026, docs/World/HOME_DESIGN.md)

- [x] Máy ấp "Tổ Ấm": model + hoạt ảnh lặp + hoạt ảnh nở / vỡ vòm
- [x] Biển tên to (ảnh avatar + tên) trên nóc nhà
- [x] Phòng rương trong nhà (Stash + giá trưng bày theo hạng), khóa cửa to dần
- [x] Sông vòng quanh các nhà + bến gỗ 5 bệ máy câu + hiên kính 4 bệ ấp
- [ ] Anh xem trong Play: hoạt ảnh nở, đi từ hồ về cất rương (xa hơn trước), câu tay ở bến, ngỗng nhà
- [ ] (chưa làm) Âm thanh máy ấp, bờ sông trang trí, cầu, cửa chặn vật lý
