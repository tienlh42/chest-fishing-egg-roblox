# DEVLOG: Nhật ký thay đổi

> **Quy tắc:** làm xong mỗi việc (code, map, cân bằng...) thì **thêm 1 mục mới ở TRÊN CÙNG**, theo mẫu ở cuối file.
> Ai cũng đọc được: người mới, người làm chung, AI. Muốn biết dự án hiện có gì thì đọc `PROJECT_OVERVIEW.md`.
> "Claude" = AI Claude Code làm việc trong repo. "Phiên khác" = phần do người/AI khác làm song song (chỉ tóm tắt).

---

## #46 · 15/10/2026 · Thiết kế lại nhà: sông vòng quanh, bến máy câu, hiên ấp, máy ấp có hoạt ảnh, biển tên trên nóc, rương trong nhà
**Yêu cầu:** thiết kế lại home theo đề xuất (xem `HOME_DESIGN.md`): sông chảy vòng quanh các nhà, bệ máy câu ráp mặt sông trong khuôn viên, khu ấp trứng có slot ấp, dựng model máy ấp + animation nở và vỡ máy ấp, tên người chơi là biển to trên nóc, rương nằm trong nhà.

**Đã làm:**
- **Sông (`ParkBuilder.BuildRiver`, `Config.River`):** elip ngoài vòng nhà (Rx 283, Rz 267, rộng 16), 96 đoạn Terrain nước thật; `River.client.lua` cho lá + 8 vịt cao su trôi theo dòng. Ao riêng bỏ.
- **Plot mới (`HouseBuilder.lua`):** bến gỗ sát sông với 5 bệ máy câu (`FisherSlot1..5`) và marker `Water` (đoạn sông trước bến = câu tay "Pond"), vườn sau nhà, hàng rào bỏ cạnh sau, hiên kính 4 bệ ấp (`IncubatorSlot1..4`), hộp thư trang trí.
- **Biển tên trên nóc:** Part `Sign` 30x8 hai mặt, ảnh avatar + tên chủ nhà, mỗi nhà một màu viền, nhà trống "FOR RENT" (`Plots.setSign`).
- **Phòng rương trong nhà:** Stash (rương lớn) ở tường sau, giá `VaultSlot1..5` trưng chồng rương theo hạng kèm "xN" (`Plots.renderVault`, cập nhật theo `profile.Chests`). Ổ khóa `DoorLock` ở cửa to dần theo cấp khóa (`Plots.UpdateLock`), nút nâng khóa chuyển lên ổ khóa. Tutorial đổi chữ.
- **Máy ấp "Tổ Ấm" (`IncubatorBuilder.lua`) + hoạt ảnh (`IncubatorAnimator.client.lua`):** vòm kính, đế tổ rơm có mắt / miệng, đèn sưởi. Hoạt ảnh lặp theo `State` / `Progress`; **hoạt ảnh nở 5 giây**: dồn nhịp, bùng nổ làm vòm kính vỡ thành mảnh + vỏ trứng vỡ + hạt lấp lánh (cầu vồng cho Gold / Dragon), đế chóng mặt, vòm mới phồng lên. `Hatchery.lua`: chốt pet ngay lúc nhận, `Remote.EffectAll("IncubatorHatch")`, pet bật ra lúc `BurstAt`, dựng lại máy sau `Duration`, chặn bấm / ấp lại trong lúc nở.

**File:** `HouseBuilder.lua`, `IncubatorBuilder.lua` (mới), `IncubatorAnimator.client.lua` (mới), `River.client.lua` (mới), `ParkBuilder.lua`, `MapBuilder.lua`, `Plots.lua`, `Hatchery.lua`, `House.lua`, `Shop.lua`, `BuildUtil.lua`, `Remote.lua`, `Config.lua`, `MainUI.client.lua`. Docs: `HOME_DESIGN.md` (mới), `PROJECT_OVERVIEW.md`, `TASKS.md`.

**Đã kiểm tra:** `selene .` 0 lỗi. Play: biển tên hiện đúng (avatar + tên, đọc được từ xa), sông + bến + bệ máy câu đúng chỗ, hiên kính với máy ấp có trứng (Dragon, Gold) đứng thẳng, hoạt ảnh nở chạy (vòm biến mất, pet bật ra), phòng rương trưng đúng chồng rương và số lượng, mở hết rương thì giá trống, mua khóa làm ổ khóa to và đổi vật liệu, các nút [E] / [G] trên bệ đúng chỗ. Sửa lỗi gặp: pivot máy ấp, tranh chấp khởi tạo của animator.
**Chưa kiểm tra:** từng khung hình hoạt ảnh nở (chỉ thấy kết quả), mảnh kính bay (chụp màn hình không bắt được), ngỗng nhà đi vòng có vướng bàn / cây mới không, cảm giác câu tay ở bến, hiệu năng mobile, 2 người chơi.

**Lưu ý:** Stash vào trong nhà nên cất rương xa hơn ~30 stud (có thể chỉnh vị trí phòng rương). Không còn model `Hatched` asset của trứng chạy (đã bỏ animation Hatch của egg, dùng hiệu ứng riêng).

---

## #45 · 15/10/2026 · Thông báo luôn trên cùng; Shop chỉ mua đồ, máy câu / máy ấp / khóa mua và nâng cấp ở nhà
**Yêu cầu:** thông báo hệ thống phải overlay trên cùng; shop chỉ cho mua đồ, không nâng cấp; máy câu mua và nâng cấp ở nhà, máy ấp cũng vậy.

**Đã làm:**
- **Toast trên cùng (`MainUI.client.lua`):** thông báo hệ thống nằm trong ScreenGui riêng `MainUIOverlay` (`DisplayOrder = 100`), nên luôn đè lên mọi bảng (Shop, Bag, Stash, Build...).
- **Shop chỉ còn:** cần câu, túi lớn hơn, Chìa vạn năng, Dép Tên Lửa. Đã bỏ khỏi Shop: ổ máy, máy ấp, máy câu (mua và nâng tier), khóa cửa.
- **Mua / nâng cấp ở nhà (`Plots.lua`, bảng "Build" mới, `Main.server.lua` `OnBuild`):**
  - Bệ máy ấp đang khóa: nút [E] "Unlock" (mở theo thứ tự).
  - Ổ máy đang khóa: [E] "Unlock"; ổ đã mở mà trống: [E] "Buy machine" mở danh sách 5 tier để mua **đúng vào ổ đó** (`BuyAutoFisher(tier, slot)`).
  - Máy đang có: giữ [E] thu rương như cũ, thêm [G] "Upgrade" mở bảng nâng tier.
  - Biển tên nhà (Part `Sign`): [E] "Upgrade house" mở bảng khóa cửa.
  - Nhãn trên bệ đổi thành "[E] Unlock" / "[E] Buy a machine".
- **Chặn ở server:** `Plots.IsHome(player)` (phải đứng trong sân nhà mình): `Shop.BuyIncubator`, `Shop.BuyLock`, `AutoFishers.UnlockSlot / Buy / Upgrade` từ chối khi ở xa nhà ("Go to your house...").

**File:** `MainUI.client.lua`, `Plots.lua`, `AutoFishers.lua`, `Shop.lua`, `Main.server.lua`. Docs: `PROJECT_OVERVIEW.md`, `TASKS.md`.

**Đã kiểm tra:** `selene .` 0 lỗi. Play: có 9 nút mua / nâng cấp trên plot; ở xa nhà mua máy ấp / máy / khóa đều bị từ chối; ở nhà mua máy ấp, mở ổ, mua máy vào ổ 2, nâng tier đều chạy; Refresh nhiều lần không nhân đôi nút; bảng Build hiện đúng, toast hiện đè trên bảng. **Chưa test:** bấm [E] / [G] thật trên bệ, bảng Incubator / Machine / House, hình ổ khóa khi tắt Play.

**Lưu ý:** Bigger Bag vẫn ở Shop (coi như đồ mang theo); nếu muốn chuyển về nhà thì báo em. Tutorial / thông báo cũ nhắc "Tool Shop" cho máy đã đổi (nhãn bệ, thông báo máy hỏng).

---

## #44 · 15/10/2026 · Khu chợ: Tool Shop và Market sát nhau, người bán vịt / mèo
**Yêu cầu:** dựng mô hình shop và người bán theo style game (đồng ý đề xuất), gom 2 cửa hàng bán và mua gần nhau.

**Đã làm:**
- **`ShopBuilder.lua` (mới)** dựng **quảng trường** 2 gian 26x22 sát nhau (cách tâm ±15) ở khe góc 225° (chỗ Tool Shop cũ, trước điểm hồi sinh). **Bỏ Market cũ ở góc 45°** (và lối vào riêng). `MapBuilder.lua`: bỏ `buildStall`, `PLAZA_ANGLE` thay `TOOLSHOP_ANGLE` / `MARKET_ANGLE`; điểm đáp `ShopArrival` giờ ở giữa quảng trường. Tên Model `ToolShop` / `Market` và Part `PromptPart` giữ nguyên nên `Shop.lua`, `Market.lua`, `Teleports.lua` không đổi.
- **Tool Shop** (mái xanh biển): biển **cá khổng lồ há miệng** có mắt đốm sáng trên mái, tường sau trưng bày **6 cần** đúng thứ tự `Config.Rods` (model thật qua `Models.Get`, đèn dưới mỗi cần theo màu hạng), 2 máy câu Common / Mythic hai bên, xô cá.
- **Market** (mái đỏ): biển **đồng xu vàng có tai mèo**, rổ trứng 5 loại trên quầy, bảng "WE BUY EGGS & PETS".
- **Người bán:** **Bác Vịt Câu Cá** (mũ nhỏ tụt lệch cắm 3 cần, ghi-lê navy, thắt lưng móc câu) và **Cô Mèo Thu Mua** (kính tròn, mũ lưỡi trai xanh, cà vạt đỏ, đuôi cong). Màu theo STYLE_GUIDE, mắt có đốm sáng, viền `Highlight`, đứng nhún nhẹ bằng tag `Bobbing`.
- Quảng trường lát gạch, 2 đèn đường, mép mái cuốn sóng (bóng tròn xen màu).

**Đã kiểm tra:** `selene .` 0 lỗi; Play: map dựng, không lỗi script, chụp màn hình thấy quảng trường, 2 biển, mèo và rổ trứng. Chưa xem kỹ: vịt và tường trưng bày cần (chụp bị timeout).

**Chưa làm:** người bán phản ứng khi mở shop; cần trên tường sáng theo cần đã mua (phải làm phía client); animation Idle riêng. Người bán nhỏ và nằm sau quầy nên chỉ thấy nửa thân: có thể kê cao bục hoặc đổi vị trí khi anh xem.

---

## #43 · 15/10/2026 · Tool Shop rộng hơn, thẻ có hình model như Bag
**Yêu cầu:** UI Shop hiển thị rộng ra và kèm model giống Bag.

**Đã làm (`MainUI.client.lua`):** bảng Shop rộng 800x580 (`PANEL_SIZES`, bảng khác vẫn 460x480, tự co theo màn hình). Mỗi món là **thẻ** trong lưới 3 cột (`addShopGrid` / `addShopCard`): hình model 3D (cùng `modelIcon` / `iconModel` của Bag, thêm tham số chiều cao), tên, mô tả, thanh độ bền (cần / máy đang có), nút mua / Equip / Upgrade, viền màu theo hạng. Nhóm: Fishing Rods (model cần, perk hiện trong mô tả), Plot Upgrades (ổ máy, máy ấp có model `Incubator`, túi), Auto-Fishers (model `AutoFisher_<tier>`, kèm thẻ máy đang có để nâng tier), Robbery (khóa cửa, chìa), Gear. Ổ máy, túi, khóa, chìa, giày dùng emoji vì chưa có model.

**Đã kiểm tra:** `selene .` 0 lỗi; chụp màn hình Play: phần Fishing Rods, Plot Upgrades và Auto-Fishers hiển thị đúng (model, chữ, nút). Chưa xem phần Robbery, Gear và thẻ máy đang có.

---

## #42 · 15/10/2026 · Ngỗng nhà, ngỗng đồn, khóa cửa, perk (bước 7)
**Yêu cầu:** "làm hết luồng", anh test và chỉnh từng phần sau.

**Đã làm:**
- **`Guard.lua` nhiều loại ngỗng (`g.Kind`):** `Lake` (như cũ), `House`, `Police`. `Noise`, `Positions`, `Recall` chỉ dành cho ngỗng hồ.
  - **Ngỗng nhà** (`Guard.SpawnHouse` / `RemoveHouse`, nối qua `OnAssign` / `OnRelease` trong `Main`): mỗi plot có chủ 1 con, đi vòng tròn bán kính 36 quanh tâm plot (12 điểm, `Config.Guard.House`), bỏ qua chủ nhà. Chỉ rượt người **bị truy nã** (`Robbery.IsWanted`: đã thử khóa, hoặc hết 60 giây trong sân), không cần nhìn thấy. Không bám quá 60 stud tính từ tâm plot.
  - **Ngỗng đồn** (`Guard.CallPolice`): sinh ở điểm cạnh Spawn khi có báo động, tối đa 3 con đuổi cùng 1 kẻ cướp (thêm 1 con mỗi lần lấy được món), biến mất sau `Police.Lifetime` 45 giây hoặc khi mất dấu / người đó vào vùng an toàn.
  - Bị bắt (`OnCaught`) gọi thêm `Robbery.Reset`. Hết 60 giây trong sân không còn tự dịch về nhà (thay cho xử tạm ở #41): ngỗng nhà lo.
- **Khóa cửa:** `Shop.BuyLock` (Action `BuyLock`) nâng `profile.LockLevel` lên cấp kế (3000 / 10000 / 30000), Tool Shop có hàng "Door Lock". Tỉ lệ mở của chìa đã đọc `LockLevel` của chủ nhà từ #41.
- **Perk (`Loadout.lua`, `Perk` trong `Config.Rods` và `Config.Pet.Stats`):** `Loadout.Get(player)` gộp perk cần + pet. Đã nối: `NoiseDelay`, `Leash`, `PauseTimeout` (Fishing), `CoinMult`, `EggChanceMult` (`Fishing.RollReward` / `GiveChest`, tức khi mở rương, kể cả ao và máy câu), `SightMult` (Guard), `StunEvery`, `StunTime`, `DamageTaken`, `LoseTimeMult` (Guard.fight / chase). Cần: Catfish +2s tiếng động, Turtle dây dài, Fox ngỗng nhìn kém 25%, Lucky Cat +20% coins, Dragon +10% xác suất trứng. Pet: Baker Dog / K9 Dog khựng 4s, Muscle Duck chịu đòn -20%, Magician Cat khựng 2.2s, Office Dragon ngỗng bỏ cuộc nhanh gấp đôi. UI: Shop hiện perk cần, Bag hiện tên perk pet.

**File:** `Guard.lua`, `Robbery.lua`, `Loadout.lua` (mới), `Fishing.lua`, `Shop.lua`, `Config.lua`, `Main.server.lua`, `MainUI.client.lua`. Docs: `PROJECT_OVERVIEW.md`, `ECONOMY_DESIGN.md`, `SYSTEM_DESIGN.md`, `TASKS.md`.

**Đã kiểm tra:** `selene .` 0 lỗi; Play thử khói: ngỗng hồ x1 + ngỗng nhà x1 sinh ra, không lỗi script; `Loadout` trả đúng (Fox + Muscle Duck: tầm nhìn 0.75, sát thương 0.8); `CallPolice` gọi 5 lần chỉ ra 3 ngỗng đồn. **Chưa test:** ngỗng nhà / đồn thật sự đuổi kẻ cướp, pathfinding quanh ao và đồ trong sân, mua khóa, nhìn UI.

**Anh nên test (và chỉnh số trong `Config.lua`):**
1. 2 người chơi: B mua chìa, vào sân A, bấm [F] ở Stash: ngỗng đồn có xuất hiện từ gần Spawn và chạy tới không, ngỗng nhà có rượt không, A có nhận thông báo không.
2. Ngỗng nhà đi vòng có bị kẹt ở ao / kệ / cây không (đổi `Config.Guard.House.Radius`).
3. B lấy món rồi chạy về nhà B: thoát được không (`Police.Lifetime`, `ChaseSpeed`), bị bắt thì đồ có về kho A không.
4. Cảm giác perk: Fox, Turtle, Dragon, Muscle Duck.

**Chưa làm / quyết định:**
- **Thang nghi ngờ đầy đủ** (SYSTEM_DESIGN 8.3) chưa làm: ngỗng nhà chỉ rượt khi bị truy nã. Người lảng vảng sân người khác mà không thử khóa chỉ bị rượt sau 60 giây.
- Perk K9 `WarnRange` chưa làm. Chưa có công trình đồn cảnh sát trên map (ngỗng đồn xuất phát gần Spawn). Chưa hiện số chìa / cấp khóa trên HUD chính.
- Ngỗng nhà dùng cùng model ngỗng hồ (đặt tên khác để phân biệt trong Explorer). Tổng số ngỗng chưa có trần cứng (8 nhà + 1 hồ + tối đa 3 đồn mỗi kẻ cướp).

---

## #41 · 15/10/2026 · Cướp nhà, phần 2: Robbery.lua, bảng cướp, đồng hồ sân, trả đồ (6.4 đến 6.9)
**Yêu cầu:** "tiếp" bước 6 (cướp nhà).

**Đã làm:**
- **`Robbery.lua` (mới):** nút [F] "Pick lock" ở **Stash** và **từng máy câu** của chủ nhà đang online (`Plots.makeRobPrompt`, attribute `RobOwnerId`, client chỉ bật nút này với người khác chủ). Bấm thì kiểm tra (không phải chủ, chủ online, hướng dẫn xong, không có khiên, đứng trong sân đó, còn chìa, chưa quá `MaxTries`), **tiêu 1 chìa**, mở với xác suất theo `Config.LockInfo(chủ.LockLevel)`. Mở rồi thì bấm lại nút không tốn chìa nữa trong lượt vào sân đó.
- **Lấy đồ (`Robbery.Take`, Action `RobTake(ownerUserId, target, itemKey)`):** kẻ cướp tự chọn rương (theo hạng) / trứng ở Stash, hoặc 1 rương ở kho máy câu (rương tung theo `Odds` của tier lúc lấy). Server **đợi `GrabTime` 3 giây**, kiểm tra còn đứng gần và chủ còn ở đó, rồi mới trừ khỏi chủ nhà và bỏ vào **túi kẻ cướp** (`Bag` giờ chứa cả trứng, món cướp có `Owner`). **Khóa theo plot** (`grabbing[plot]`) chống hai người lấy cùng lúc; kiểm tra hàng còn ngay lúc lấy.
- **Báo động:** lần thử khóa đầu tiên thông báo chủ nhà kèm tên kẻ cướp. Lấy được món đầu tiên thì chủ nhà có **khiên 10 phút** (chặn những lần thử khóa MỚI, người đã mở khóa vẫn lấy tiếp trong lượt đó). Người đang hướng dẫn (`Tutorial < 99`) không bị cướp.
- **Đồng hồ sân:** mỗi 0.5 giây server đếm ngược 60 giây cho người đứng trong sân người khác (`SafeZone.PlotAt`), ra ngoài thì hồi 1 giây mỗi 2 giây; client hiện nhãn đỏ/cam "X's yard: leave in Ns!". **Hết giờ tạm xử như bị bắt** (mất túi, về nhà): chờ ngỗng nhà thật ở bước 7.
- **Trả đồ:** `Bag.Clear` (bị bắt / chết / hết giờ) và `Bag.RemovePlayer` (thoát game) trả món cướp về kho chủ nhà (rương / trứng; rương lấy từ máy câu thành rương trong Stash) và báo chủ nhà. Cất ở Stash nhà mình thì thành của mình (`Bag.Deposit` giờ cất cả trứng).
- **UI:** bảng "🔑 Break-in" (danh sách món + nút Take, cập nhật sau mỗi lần lấy qua Effect `RobUpdate`), nhãn đồng hồ sân.

**File:** `Robbery.lua` (mới), `Bag.lua`, `Plots.lua`, `SafeZone.lua` (`PlotAt`), `Main.server.lua`, `MainUI.client.lua`, `Effects.client.lua`. Docs: `PROJECT_OVERVIEW.md`, `ECONOMY_DESIGN.md`, `TASKS.md`.

**Đã kiểm tra:** `selene .` 0 lỗi. Studio chỉ có 1 người chơi nên test bằng bản `Robbery` **vá tạm trong Studio** (bỏ chặn tự cướp, đã khôi phục bản thật): mở khóa tiêu đúng 1 chìa; lấy rương Rainbow / trứng Reed / rương máy câu đúng (kho chủ trừ đúng, túi tăng); món lạ báo "gone"; mục tiêu chưa mở bị từ chối; khiên chặn thử khóa mới; `Bag.Clear` trả đủ 3 món về kho; đồng hồ sân đếm ngược trên client, hết giờ thì mất túi và đồ trả về. **Chưa test:** 2 người thật (việc 6.11 nhờ anh), chủ thoát game giữa vụ, hình bảng Break-in.

**Lưu ý / quyết định:**
- Cướp từ máy câu **không trừ độ bền** máy (có lợi cho chủ nhà), kho máy chỉ giảm số rương.
- Phím cướp là **F** để khỏi trùng [E] của chủ nhà.
- Cướp được cả trứng ở kho (`profile.Eggs`); trứng đang trong máy ấp không bị cướp.
- Chưa có khóa cửa để mua (7.4): `LockLevel` luôn 0 nên tỉ lệ mở 50%.

---

## #40 · 15/10/2026 · Cướp nhà, phần 1: Config.Robbery, chìa, vùng an toàn theo người (6.1 đến 6.3)
**Yêu cầu:** làm tiếp bước 6 (cướp nhà) theo `TASKS.md`.

**Đã làm:**
- **`Config.Robbery`:** `KeyPrice` 200, `MaxTries` 4, `TrespassTime` 60, `GrabTime` 3, `ShieldTime` 600, `Locks` (4 cấp: 50 / 40 / 30 / 20% mở, giá 0 / 3000 / 10000 / 30000) và `Config.LockInfo(level)`. Profile thêm `Keys`, `LockLevel`, `ShieldUntil` (`reconcile` tự bổ sung cho người cũ). Chưa có code dùng `Locks` / `MaxTries` / `ShieldTime` (làm ở 6.4 trở đi, 7.4).
- **Mua chìa:** `Shop.BuyKey(số lượng)` (Action `BuyKey`, 1 đến 20 chiếc, số không hợp lệ thì mua 1). Tool Shop có mục "Robbery" với nút x1 / x5; đầu bảng Bag hiện số chìa.
- **Vùng an toàn theo từng người (`SafeZone.lua`):** `SafeZone.Contains(position, player)`: hộp quanh nhà chỉ an toàn cho **chủ nhà** (attribute `OwnerId` của plot), nhà người khác và nhà chưa có chủ **không** an toàn; vùng chung (Spawn / Plaza) an toàn cho mọi người. Gọi không truyền player thì chỉ tính vùng chung. Sửa 4 chỗ gọi: `Guard.targetRoot`, `Fishing.spotFor`, `Bag` (chết có mất túi không); `SafeZone.IsSafe(player)` (Guard, Pets) tự dùng player.

**File:** `Config.lua`, `Data.lua`, `Shop.lua`, `Main.server.lua`, `SafeZone.lua`, `Guard.lua`, `Fishing.lua`, `Bag.lua`, `MainUI.client.lua`.

**Đã kiểm tra:** `selene .` 0 lỗi. Play: nhà mình an toàn, nhà người khác / giữa hồ không, Spawn có; đứng trong nhà người khác thì `IsSafe` = false; mua 5 chìa tốn 1000 coins; Action `BuyKey` từ client chạy. **Chưa Play thử** việc ngỗng thật sự đuổi người đứng trong sân nhà người khác, và chưa xem hình hàng "Robbery" trong Shop.

**Lưu ý:** ngỗng hồ tuần quanh hồ nên chưa tự vào sân người khác để đuổi; đó là việc của ngỗng nhà (bước 7). Đồng bộ Studio bằng HTTP như #39.

---

## #39 · 15/10/2026 · Kho nhà giữ rương chưa mở + mở rương (bước 5 kinh tế)
**Yêu cầu:** "code các module chơi, đề xuất bước đầu". Chọn bước 5 trong `ECONOMY_DESIGN.md` mục 11 (kho nhà + mở rương) vì cướp nhà (bước 6) cần có kho rương để cướp. Kèm `TASKS.md` (danh sách việc, tick sau mỗi việc).

**Đã làm:**
- **Cất Stash không còn tự mở rương.** Túi tạm chỉ giữ tên rương (`{ Chest = tên }`), nội dung coins / trứng **tung lúc mở** (`Fishing.lua` bỏ `RollReward` ở hồ cấm). `Bag.Deposit` chuyển rương vào `profile.Chests = { [tên rương] = số lượng }` (kho không giới hạn ô), lưu xong mới tính, lưu lỗi thì hoàn lại, trả về true / false.
- **`Stash.lua` (module mới):** `OnPrompt` (nút [E] ở Stash: túi có đồ thì cất, rồi mở bảng Stash), `OpenChest(name, all)`, `OpenAll()`. Server kiểm tra tên rương (`Config.FindChest`), số lượng, và người chơi đứng trong `Config.Stash.OpenRange` (40 stud) quanh Stash của mình. Mở dùng `Fishing.GiveChest` nên cùng luật trứng như cũ.
- **Action mới:** `OpenChest(tên, all)`, `OpenAllChests`. `Plots.StashPosition(player)`; nút [E] Stash đổi chữ thành "Open".
- **Data:** `profile.Chests` có trong `defaultProfile`, `reconcile` bổ sung cho người cũ.
- **UI:** bảng "📦 Stash" (rương hiếm trước, nút Open / Open all, disable Open all khi chỉ có 1); Bag có dòng "N chest(s) waiting in your Stash". Hiệu ứng `Deposit` hiện "N chests stashed" (không còn "+0 coins"), mở rương dùng hiệu ứng `Collect`. Chữ Tutorial bước 3 nhắc mở rương.
- **Giữ nguyên:** rương từ ao nhà và máy câu vẫn mở ngay vào tài khoản (còn trong mục "chưa chốt" `SYSTEM_DESIGN.md` mục 12).

**File:** `Config.lua`, `Data.lua`, `Bag.lua`, `Fishing.lua`, `Stash.lua` (mới), `Plots.lua`, `HouseBuilder.lua`, `Main.server.lua`, `MainUI.client.lua`, `Effects.client.lua`. Docs: `PROJECT_OVERVIEW.md`, `SYSTEM_DESIGN.md`, `ECONOMY_DESIGN.md`, `TASKS.md`.

**Đã kiểm tra:** `selene .` 0 lỗi. Play trong Studio: cất 3 rương vào kho đúng số lượng; mở khi ở xa Stash bị chặn; tên rương sai, rương không có, kho trống đều báo lỗi đúng; Open một, Open all, OpenAllChests chạy đúng và cộng coins (393 coins từ 3 rương); bảng Stash trên client hiện đúng và cập nhật sau mỗi lần mở (gọi Action từ client).
**Chưa kiểm tra:** bấm chuột thật vào nút / [E] (chỉ gọi hàm và Action), chưa câu thật ngoài hồ rồi cất, chưa kiểm tra hình hiệu ứng.

**Đồng bộ Studio:** Rojo không nối và **Studio đang chứa bản script cũ hơn repo khá nhiều** (ví dụ `Data.lua` chưa có pet dạng bản ghi), nên đã chép toàn bộ 18 script khác nhau từ repo vào Studio. Cách làm: bật tạm `HttpService.HttpEnabled`, chạy `python -m http.server` trong repo, `execute_luau` tải từng file bằng `GetAsync`; xong đã tắt lại HttpEnabled và dừng server.

**Chưa xong / lưu ý:**
- Mở rương tức thì, chưa có animation `Open` của model rương và chưa có thời gian chờ (`ECONOMY_DESIGN.md` mục 12.4).
- Người chơi đã lưu: rương đã cất trước bản này đã được cộng thẳng coins / trứng, không có rương trong kho (chuyển đổi không cần).
- Bước tiếp theo: bước 6 cướp nhà (xem `TASKS.md`).

---

## #42 · 16/10/2026 · Cấu trúc lại tài liệu theo module (thư mục `docs/`)
**Yêu cầu:** tách các file .md vào thư mục đại diện cho từng module của một game Roblox tiêu chuẩn.

**Đã làm:** `git mv` 14 file vào `docs/Overview`, `GameDesign`, `Economy`, `World`, `Art`, `Audio`, `QA`, `ProjectManagement` (mục lục ở `docs/README.md`). Sửa đường dẫn nhắc trong `CLAUDE.md`, các tài liệu, `MakeRobuxInHere`, và comment trong 5 file Lua và `tools/sim_economy.py`. `CLAUDE.md` giữ ở gốc, `MakeRobuxInHere/` giữ nguyên tên. Không đổi logic code, `default.project.json` không đổi.

**Lưu ý:** các mục DEVLOG cũ vẫn ghi tên file không kèm đường dẫn (nhật ký lịch sử, tên file là duy nhất). Link cũ tới các file .md ở gốc (nếu có ngoài repo) sẽ hỏng.

---

## #41 · 16/10/2026 · Chốt: tuổi 13-19, Store song ngữ Anh và Việt
**Đã làm:** ghi vào `MakeRobuxInHere` (README bảng "Đã chốt", `02` mục 7 song ngữ, `03` mục 7 quy tắc cho tuổi 13 đến 19, `04` giai đoạn 0). Đổi quy tắc trong `CLAUDE.md`: chữ cho người chơi vẫn tiếng Anh, **riêng Store và mô tả sản phẩm có thêm tiếng Việt**. Không sửa code.

**Lưu ý:** quy tắc cho thanh thiếu niên là đề xuất của em, chưa đối chiếu chính sách Roblox mới nhất.

---

## #40 · 16/10/2026 · Chốt: chưa publish, có bán coins, người chơi Việt Nam và quanh đó
**Đã làm:** ghi 3 câu trả lời vào `MakeRobuxInHere/README.md` (bảng "Đã chốt"); thêm `01_PRODUCTS.md` mục 10 (giá thấp, ưu tiên điện thoại, tiếng Việt cho mô tả, giờ reset ngày, Premium ít phổ biến); `03` ghi chú theo khu vực; `04` giai đoạn 0 (publish riêng tư) và gói Mini 25 R$. Không sửa code.

**Chưa xong / lưu ý:** còn thiếu độ tuổi chính và việc có thêm tiếng Việt cho mô tả sản phẩm (đổi quy tắc "chữ hiện cho người chơi bằng tiếng Anh"). Chưa kiểm tra chính sách từng nước.

---

## #39 · 16/10/2026 · Kế hoạch bán vật phẩm bằng Robux (thư mục MakeRobuxInHere)
**Yêu cầu:** lên kế hoạch xây hệ thống vật phẩm bán bằng Robux, đặt trong thư mục `MakeRobuxInHere`.

**Đã làm:** tạo 5 file tài liệu: `README.md` (mục tiêu, nguyên tắc, 7 quyết định cần chốt), `01_PRODUCTS.md` (danh mục, giá đề xuất, mức rủi ro trả tiền để thắng, danh sách không bán), `02_TECHNICAL_PLAN.md` (`ProcessReceipt`, dữ liệu profile, chống cấp hai lần, chỗ cắm vào code hiện có, bảng Store, kiểm thử), `03_COMPLIANCE_AND_RISKS.md`, `04_ROADMAP.md` (giai đoạn 0 đến 7). Thêm tham chiếu ở `CLAUDE.md`, `PROJECT_OVERVIEW.md`.

**Điểm chính:** không bán thứ ảnh hưởng cướp nhà (Chìa vạn năng, khóa, sửa chữa, pet / trứng hiếm, rương Golden và Rainbow); gói coins tính theo phút thu nhập hiện tại, có giới hạn ngày; ưu tiên trang trí và tiện lợi trước; vật phẩm ngẫu nhiên để sau cùng.

**File:** `MakeRobuxInHere/*` (mới), `CLAUDE.md`, `PROJECT_OVERVIEW.md`, `DEVLOG.md`. Không sửa code.

**Chưa xong / lưu ý:** em **không xác minh được chính sách Roblox mới nhất**, `03_COMPLIANCE_AND_RISKS.md` mục 1 là danh sách việc phải kiểm tra, nhật ký kiểm tra còn trống. Giá và quyền lợi là đề xuất. `DataStore` hiện dùng `SetAsync` không khóa phiên, nên nâng lên trước khi bán thật.

---

## #38 · 15/10/2026 · Thanh progress bar cho HP và độ bền
**Yêu cầu:** độ bền, HP thì làm thanh progress bar (thay cho chữ).

**Đã làm:**
- **`MainUI.client.lua`:** hàm `progressBar` dùng chung. Bag: ô pet có 2 thanh (xanh lá = HP, xanh dương = độ bền), ô cần có thanh độ bền (thay chữ "37/50 left"); thêm dòng chú thích màu. Shop: hàng cần đang có và hàng "Machine #n" có thanh độ bền kèm số. Market: hàng pet có thanh độ bền kèm số. HUD: thêm thanh độ bền mỏng dưới thanh HP của pet đang đi theo.
- **HP từng pet trong Bag:** server gửi thêm `Id` pet trong `Pets.Status` (`Pets.lua`); client nhớ HP cuối cùng của từng pet (`petHPs`). Pet không equip thì HP không đổi nên con số đó đúng; pet chưa thấy lần nào hiện đầy máu.
- **`Config.DurabilityColor(ratio)`:** màu thanh độ bền dùng chung client và server (xanh dương, cam dưới 50%, đỏ dưới `DurabilityWarnRatio`).
- **`Plots.lua`:** bảng trên máy câu ngoài sân thêm thanh độ bền ở đáy (`addDurabilityBar`), bỏ dòng chữ "Durability x/y" (còn "Epic  7/13 chests").

**File:** `MainUI.client.lua`, `Pets.lua`, `Config.lua`, `Plots.lua`. Docs: `PROJECT_OVERVIEW.md`, `ECONOMY_DESIGN.md`.

**Đã kiểm tra:** VS Code không báo lỗi ở toàn bộ file Lua đã sửa (gồm `Plots.lua`, `MainUI.client.lua`). **Chưa chạy `selene .`** và **chưa Play thử** (máy không có selene / Studio MCP), nên chưa xem thanh có vừa khung / đẹp chưa.

**Chưa xong / lưu ý:**
- Cần xem trong Studio: hàng Shop / Market (thanh cao 13 px dưới 2 dòng chữ có vừa hàng 64 px không), ô Bag (2 thanh ở đáy ô), bảng trên máy có đủ chỗ không (chữ thu còn 72% chiều cao).
- Thanh trong ô Bag không có số (quá nhỏ), số xem ở Shop / Market. Cần câu chưa có thanh trên HUD.
- HP trong Bag chỉ đúng trong phiên (HP không lưu), pet chưa từng equip hiện đầy máu.

---

## #37 · 15/10/2026 · Máy câu tách ổ và tier, có độ bền, nâng tier tại chỗ (bước 4 kinh tế)
**Yêu cầu:** làm bước 4 trong `ECONOMY_DESIGN.md` mục 11.

**Đã làm:**
- **`Config.AutoFisher`** viết lại: `PedestalPrices` (0 / 400 / 1200 / 3000 / 7000) và `Tiers` (5 tier, mỗi tier có `Name`, `Price`, `Interval`, `Capacity`, `Durability`, `Odds`). Bỏ `Prices`, `Interval`, `Capacity`, `Odds` chung. `Config.AutoFisherStored` tính kho theo tier và không quá độ bền còn lại.
- **Dữ liệu (`Data.lua`):** `profile.FisherSlots` (số ổ đã mở, mặc định 1) và `profile.AutoFishers[ổ] = { Tier, Durability, Last, Stored }`. `reconcile` đổi máy cũ: máy ở ổ i thành tier i đầy bền, mở sẵn các ổ đã có máy.
- **`AutoFishers.lua`:** `UnlockSlot` (mở ổ), `Buy(tierIndex)` (mua thẳng tier vào ổ trống đầu tiên), `Upgrade(slot)` (trả chênh lệch giá, chốt kho cũ, độ bền về đầy), `Collect` trừ độ bền bằng số rương thu; hết bền thì xóa máy, ổ còn lại; còn 20% thì báo. Rương ra theo `Odds` của tier.
- **Action mới:** `BuyFisherSlot`, `BuyAutoFisher(tierIndex)`, `UpgradeAutoFisher(slot)` (`Main.server.lua`). Bỏ `Shop.BuyAutoFisher`.
- **`Plots.lua`:** máy dựng theo tier của từng ổ (asset `AutoFisher_<Tier>`), bảng chữ hiện "Epic  7/13 chests / Durability 380/450", ổ trống ghi "Empty pedestal", ổ chưa mở ghi "Locked". Nhà dev trống bày đủ 5 tier.
- **UI (`MainUI.client.lua`, Tool Shop):** hàng "Machine Pedestal", mục "Auto-Fishers" liệt kê 5 tier để mua, mỗi máy đang có một hàng "Machine #n" với nút nâng tier.

**File:** `Config.lua`, `Data.lua`, `AutoFishers.lua`, `Plots.lua`, `Shop.lua`, `Main.server.lua`, `MainUI.client.lua`. Docs: `PROJECT_OVERVIEW.md`, `ECONOMY_DESIGN.md`.

**Đã kiểm tra:** VS Code không báo lỗi ở các file Lua đã mở (không gồm `Plots.lua`, chưa mở). Bản Python của `Config.AutoFisherStored` chạy thử: kho dừng ở mức đầy khi offline 1 ngày, máy Common thu đúng tổng 120 rương rồi hỏng, máy sắp hỏng (bền 3) chỉ tích tối đa 3, nâng tier giữ kho và hồi bền. **Chưa chạy `selene .`** và **chưa Play thử** (máy không có selene / Studio MCP).

**Sự cố khi làm (đã xử lý):** một lệnh thay thế dùng sai điểm kết thúc đã làm `Config.lua` phình ra 13.8 triệu ký tự (hàm mới bị chèn giữa mọi ký tự). Em gỡ đúng đoạn chèn, khôi phục lại 17,850 ký tự, kiểm tra từng khối cấu hình (cần câu, máy, pet, trứng) còn nguyên rồi mới sửa tiếp. Nếu anh thấy `Config.lua` có gì lạ thì báo em.

**Chưa xong / lưu ý:**
- Cần test trong Studio: vào game tài khoản mới (không có máy, ổ 1 mở sẵn, ổ 2-5 ghi "Locked"); mua máy Common, đợi / chỉnh `Last` để có rương, bấm [E] thu; mở ổ 2; nâng tier; đặt `Durability = 1` thử cảnh máy hỏng. Tài khoản cũ có máy: máy giữ nguyên tier theo ổ.
- Thu nhập máy giờ thấp hơn nhiều so với trước (180 giây / rương thay vì 30 giây, chỉ Wooden ở tier Common) theo thiết kế.
- Máy câu hỏng lúc chủ offline: hiện máy chỉ biến mất khi chủ thu lần cuối, không tự biến khi offline.
- Chưa có thanh độ bền, chỉ có chữ.

---

## #36 · 15/10/2026 · Bỏ Starter Egg và Chef Cat, người mới được tặng 1 Reed Egg
**Yêu cầu:** ban đầu chỉ tặng trứng cơ bản, không cần Chef Cat.

**Đã làm:**
- `Config.lua`: bỏ trứng `Starter`, pet `Chef Cat` (`Config.Pet.Stats`, `Config.SellPrices.Pets`) và `"Starter"` trong `Config.EggOrder`. Còn 5 trứng ↔ 5 pet (Reed → Baker Dog ... Dragon → Office Dragon).
- `Data.lua`: người mới được tặng `Eggs.Reed = 1` thay vì Starter (cờ `StarterGiven` giữ nguyên tên để không đổi dữ liệu đã lưu).
- Chữ và chú thích: `Tutorial.lua`, `MainUI.client.lua` ("Hatch your free Reed Egg"), `Market.lua`, `Models.lua`. Tài liệu: `ECONOMY_DESIGN.md` (mục 0, 0.1, 5.1, 8, 12), `PROJECT_OVERVIEW.md`, `HUONG_DAN.md`, `SYSTEM_DESIGN.md`, `tools/sim_economy.py`.

**File:** `Config.lua`, `Data.lua`, `Tutorial.lua`, `Market.lua`, `Models.lua`, `MainUI.client.lua`.

**Đã kiểm tra:** VS Code không báo lỗi ở các file Lua đã sửa; không còn chỗ nào trong `.lua` / `.py` nhắc `Starter` egg hay `Chef Cat` (grep). **Chưa chạy `selene .`** và **chưa Play thử** (máy không có selene / Studio MCP).

**Chưa xong / lưu ý:**
- Người đã lưu dữ liệu với Starter Egg hoặc pet Chef Cat sẽ có mục không còn trong `Config` (bản Studio không lưu DataStore nên chưa ảnh hưởng; bản đã publish thì cần chuyển đổi nếu có người chơi thật).
- Reed Egg bán được (10 coins) nên người mới có thể bán luôn trứng tặng.
- Asset `Egg_Starter`, `Pet_CatPot` vẫn trong `Assets/Models`, chưa xóa.
- Tutorial và `ECONOMY_DESIGN.md` 0.1: người mới có pet từ ~10 giây nên mốc tiến độ vẫn như mô phỏng gốc.

---

## #35 · 15/10/2026 · Pet thành bản ghi, equip pet, độ bền pet (bước 3 kinh tế)
**Yêu cầu:** làm bước 3 trong `ECONOMY_DESIGN.md` mục 11.

**Đã làm:**
- **Dữ liệu (`Data.lua`):** `profile.Pets` đổi từ danh sách tên sang danh sách bản ghi `{ Id, Name, Durability }`; thêm `NextPetId` (chỉ tăng) và `EquippedPet` (Id). `Data.NewPet(profile, name)` tạo pet đầy bền (tự equip nếu chưa có pet nào), `Data.FindPet(profile, id)`. `reconcile` đổi pet cũ (chuỗi) thành bản ghi, pet mới nhất của người cũ được equip.
- **Config:** `Config.Pet.DurabilityMult = 20`, `Config.PetDurability(name)`, `Config.PetSellPrice(pet)`; đổi tên `RodWarnRatio` thành `DurabilityWarnRatio` (dùng chung cần và pet).
- **`Pets.lua`:** pet đi theo là pet `EquippedPet`. HP lưu **theo từng pet** (đổi pet qua lại không hồi máu miễn phí), chỉ pet đang equip mới hồi. `Pets.Hit` trừ độ bền đúng bằng số HP pet mất; còn 20% thì báo "almost broken"; hết bền thì pet biến mất (`breakPet`), không còn pet đi theo. Profile gửi xuống client tối đa mỗi 2 giây trong lúc bị đuổi, phần còn lại gửi khi hết đuổi.
- **`Shop.EquipPet(id)`** (Action `EquipPet`): kiểm tra sở hữu, chặn đổi pet khi `Guard.IsChasing`.
- **`Market.SellPet(id)`:** bán từng pet, giá nhân tỉ lệ độ bền còn lại. Đổi từ "bán theo tên, Sell 1 / Sell All".
- **`Hatchery.lua`, `House.lua`:** dùng `Data.NewPet`, kệ trưng bày đọc `pet.Name`.
- **UI (`MainUI.client.lua`):** Bag hiện mỗi pet 1 ô (độ bền còn lại, nhãn EQUIPPED), **bấm ô để equip**; ô cần câu đã có cũng bấm để equip. Market liệt kê từng pet với nút "Sell <giá>".

**File:** `Data.lua`, `Config.lua`, `Pets.lua`, `Shop.lua`, `Market.lua`, `Hatchery.lua`, `House.lua`, `Fishing.lua`, `Main.server.lua`, `MainUI.client.lua`. Docs: `PROJECT_OVERVIEW.md`, `ECONOMY_DESIGN.md`.

**Đã kiểm tra:** VS Code không báo lỗi ở các file Lua đã sửa. **Chưa chạy `selene .`** (máy không có selene / rojo / luau) và **chưa Play thử trong Studio** (không có Studio MCP).

**Chưa xong / lưu ý:**
- Cần test trong Studio: (1) tài khoản cũ có pet dạng tên: vào game thấy pet cũ đi theo, Bag hiện đủ pet; (2) nở trứng khi chưa có pet: tự equip; (3) có 2 pet: bấm ô pet trong Bag đổi pet, thử đổi lúc ngỗng đuổi (phải bị chặn); (4) để ngỗng đánh pet, xem độ bền trong Bag giảm; set `Durability = 1` trong profile để thử cảnh pet hỏng (pet biến mất, ngỗng bắt được người); (5) Market bán 1 pet, giá theo độ bền.
- **Starter Egg vẫn còn** (chưa làm phần "khởi đầu chỉ có cần mặc định", `ECONOMY_DESIGN.md` mục 0.1), nên người mới vẫn được tặng trứng Chef Cat.
- Đổi pet chỉ hiện ngay sau ~0.4 giây; pet đang kiệt sức (HP 0) vẫn equip được nhưng chỉ hồi lại khi equip và đứng ở nhà.
- Chưa có thanh độ bền, chỉ có chữ "đã dùng / tối đa".

---

## #34 · 15/10/2026 · Độ bền cần câu (bước 2 kinh tế)
**Yêu cầu:** làm tiếp bước 2: cần câu có độ bền, hết thì biến mất, không sửa được.

**Đã làm:**
- `Config.lua`: `Durability` cho 5 cần trả phí (Catfish 50, Turtle 100, Fox 250, Cat 500, Dragon 1000 rương); Duckling không có = không hỏng. `Config.RodWarnRatio = 0.2`.
- `Data.lua`: `profile.Rods[id]` là số độ bền còn lại (Duckling vẫn `true`). `reconcile` đổi cần cũ lưu `true` thành đầy bền.
- `Shop.BuyRod`: mua cần được độ bền đầy. Cần hỏng thì không còn trong `profile.Rods` nên mua lại được giá gốc.
- `Fishing.lua`: hàm `wearRod` gọi sau mỗi rương kéo lên **ở hồ cấm** (ao, lượt hụt không hao). Còn 20% thì báo "almost broken", hết bền thì xóa cần, đặt `EquippedRod` về cần đầu tiên, phát lại cần (`GiveRod`), báo "broke".
- `MainUI.client.lua`: Shop hiện "Catfish Rod (37/50 left)" hoặc "(lasts 50 chests)", Duckling "(never breaks)". Bag hiện "37/50 left" dưới tên cần.

**File:** `Config.lua`, `Data.lua`, `Shop.lua`, `Fishing.lua`, `MainUI.client.lua`. Docs: `PROJECT_OVERVIEW.md`, `ECONOMY_DESIGN.md`.

**Đã kiểm tra:** VS Code không báo lỗi ở 6 file Lua đã sửa (kể cả `MainUI.client.lua`). **Chưa chạy `selene .`** (máy không có selene / rojo / luau) và **chưa Play thử trong Studio** (phiên này không có Studio MCP).

**Chưa xong / lưu ý:**
- Cần test trong Studio: câu ở hồ nhiều lần, xem độ bền giảm và Shop / Bag cập nhật; set `profile.Rods.Catfish = 1` để thử cảnh hỏng (cần biến mất, về Duckling, tool được phát lại); ao không hao.
- Cần hỏng lúc đang cầm: `GiveRod` hủy Tool đang cầm rồi cầm cái mới, chưa kiểm tra có giật animation Catch không.
- UI mới chỉ hiện chữ, chưa có thanh độ bền. Dữ liệu đã lưu: cần cũ được coi là đầy bền.
- Bước tiếp: pet thành bản ghi + equip pet + độ bền pet.

---

## #33 · 15/10/2026 · Bảng tỉ lệ rương thay Luck, giá cần mới, ao chỉ ra Wooden (bước 1 kinh tế)
**Yêu cầu:** làm bảng tỉ lệ (`ECONOMY_DESIGN.md` mục 11 bước 1). Cướp, két sắt để sau cùng.

**Đã làm:**
- `Config.lua`: bỏ `Weight` của rương và `Luck` của cần; mỗi cần có `Odds` (5 số); thêm `Config.RollChest(odds)` và `Config.TopChestPercent(odds)`; `WeightedRoll` bỏ tham số luck (chỉ còn dùng cho pool pet ở `Hatchery`). Giá cần: Catfish 150, Turtle 500, Fox 1800, Cat 6000, Dragon 18000.
- Ao: `Config.Fishing.PondOdds` chỉ Wooden, `PondTimeMult` 1.5 thành 5; bỏ `LakeLuck`.
- `Fishing.lua` tung rương bằng `RollChest(rod.Odds)` ở hồ, `PondOdds` ở ao. `AutoFishers.lua` dùng `Config.AutoFisher.Odds` (**tạm chỉ Wooden**, đến bước 4 mới tách theo tier).
- `MainUI.client.lua`: bảng Shop và Bag hiện "Purple+ x%" thay vì "Luck x".

**File:** `Config.lua`, `Fishing.lua`, `AutoFishers.lua`, `MainUI.client.lua`. Docs: `PROJECT_OVERVIEW.md`, `ECONOMY_DESIGN.md`.

**Đã kiểm tra:**
- VS Code không báo lỗi ở `Config.lua`, `Fishing.lua`, `AutoFishers.lua`.
- Tung thử 200,000 lần mỗi cần bằng bản Python của `RollChest` đọc đúng `Odds` từ `Config.lua`: tỉ lệ thực tế khớp bảng (vd. Duckling 87.98 / 10.07 / 1.75 / 0.19 / 0.02; Dragon 25.97 / 28.02 / 28.05 / 13.91 / 4.06), ao luôn ra Wooden.
- **Chưa chạy `selene .`** (máy này không có selene / rojo / luau), **chưa test trong Studio** (phiên này không có Studio MCP).

**Chưa xong / lưu ý:**
- Cần chạy `selene .`, chép 4 file vào Studio, Play: câu thử ở hồ và ao, mở Shop và Bag xem dòng "Purple+".
- Máy câu hiện chỉ ra Wooden (trước đây ra đủ 5 loại) nên thu nhập máy giảm cho tới bước 4.
- Người chơi đã lưu: giá cần đổi không ảnh hưởng cần đã mua.

---

## #32 · 15/10/2026 · Chốt: không sửa chữa, mọi pet như nhau, khởi đầu chỉ có cần mặc định
**Yêu cầu:** anh Scott trả lời câu hỏi mở: không cho sửa; mọi pet như nhau (Chef Cat cũng hỏng); người chơi mới chỉ có 1 cần mặc định và không có gì thêm. Hỏi em đề xuất gì về cướp.

**Đã làm:** ghi 3 điều trên vào `ECONOMY_DESIGN.md` mục 0, thêm mục 0.1 (hệ quả: vòng đầu là ao nhà, Chef Cat mất nguồn khi bỏ Starter Egg, `Tutorial.lua` / `Data.Load` phải đổi, Catfish đến chậm hơn ~2.5 phút), cập nhật mục 12. Không sửa code.

**Chưa xong / lưu ý:** đề xuất về cướp trả lời trong chat, chưa ghi vào tài liệu cho tới khi anh duyệt.

---

## #31 · 15/10/2026 · Thiết kế: độ bền vật phẩm, Chìa vạn năng, kho vô hạn
**Yêu cầu:** mọi vật phẩm (cần, máy câu, pet) có độ bền, hết thì biến mất. Cướp phải mua Chìa vạn năng (mở 50%), mỗi vụ chọn tối đa số rương túi mang được, cướp ở máy câu và kho. Ô mang trên người có giới hạn, về nhà cất vào kho (vô hạn ô).

**Đã làm:**
- Viết lại `ECONOMY_DESIGN.md` (bản 2) và mở rộng `tools/sim_economy.py`: độ bền + hao mòn, máy câu tách ổ / giá mua thẳng từng tier, độ bền pet, tiến độ theo thu nhập ròng, cướp có chìa + cấp khóa cửa.
- Cập nhật `SYSTEM_DESIGN.md` mục 9 (ghi chú luật cướp mới), `PROJECT_OVERVIEW.md`.

**Phát hiện từ mô phỏng:**
- Hao mòn đặt ~12-13% thu nhập với cần, ~20% với máy câu. Cần Dragon sống ~471 phút, cần Catfish ~27 phút. Giữ **Duckling không hỏng** để không kẹt không có cần.
- Ao làm hao cần thì cầm Dragon ra ao lỗ 17 coins/phút, nên đề xuất ao **không hao cần**.
- Máy câu cần giá mua thẳng từng tier (300 / 1000 / 3500 / 10000 / 30000) vì máy hỏng phải mua lại; ổ máy tách riêng (không hỏng). Hoàn vốn máy từ 1.4 giờ (Common) đến 17.9 giờ (Mythic).
- Kẻ cướp **tự chọn** món thì lời gấp 5-10 lần câu hồ nếu không có giá. Với chìa 200 coins: người mới và giữa game cướp lỗ, người giàu không khóa lời 2-3 lần câu hồ, khóa cửa 3 (30,000 coins) làm cướp hết lời. Nên không cần luật bảo vệ người mới riêng.
- Túi 6 ô chỉ tăng lời cướp ~4% (món thứ 5, 6 giá trị thấp).

**File:** `ECONOMY_DESIGN.md`, `tools/sim_economy.py`, `SYSTEM_DESIGN.md`, `PROJECT_OVERVIEW.md`, `DEVLOG.md`. **Không sửa code Luau, không đụng Studio.**

**Đã kiểm tra:** chạy `python tools/sim_economy.py`, đối chiếu từng bảng với số trong `ECONOMY_DESIGN.md`.

**Chưa xong / lưu ý:**
- Toàn bộ là [ĐỀ XUẤT]. Cần đo ngoài game: tỉ lệ mất túi mỗi chuyến, xác suất kẻ cướp thoát về nhà (giả định 40%), rương/phút thật khi 4-8 người, HP pet bị mất mỗi giờ (giả định 6 x HP).
- Câu hỏi mở ở `ECONOMY_DESIGN.md` mục 12: có cho sửa chữa không, Chef Cat có hỏng không, ao có hao cần không, có thêm thời gian mở rương để kho có hàng cho cướp không.
- Pet phải đổi từ danh sách tên sang bản ghi `{ Id, Name, Durability }`, cần chuyển đổi dữ liệu cũ khi code.

---

## #30 · 15/10/2026 · Thiết kế kinh tế farm (câu, máy câu, cướp) + script mô phỏng
**Yêu cầu:** thiết kế hệ thống kiếm tiền và cây vật phẩm. Anh Scott chốt: equip cần và pet tự do; nâng cấp chỉ bằng coins (bỏ Pearl, Essence); chưa tính Robux; tiền kiếm bằng farm (câu, máy câu, cướp).

**Đã làm:**
- Viết `tools/sim_economy.py`: mô phỏng giá trị kỳ vọng thu nhập câu hồ, ao, máy câu, tiến độ mua và lời của cướp nhà.
- Viết `ECONOMY_DESIGN.md`: vòng kiếm tiền, bảng tỉ lệ rương riêng từng cần (thay công thức Luck), ao nhà, máy câu tách slot và tier, luật kinh tế cướp nhà, equip cần / pet, perk, chỗ tiêu, tiến độ, bảng thay đổi so với Config.
- Cập nhật tham chiếu ở `CLAUDE.md`, `PROJECT_OVERVIEW.md`, `SYSTEM_DESIGN.md` (mục 4.2).

**Phát hiện từ mô phỏng (đáng nhớ):**
- Công thức `luck^(i-1)` hiện tại quá hào phóng: cần Duckling ở hồ (Luck 1 × LakeLuck 1.5) đã ra 3.7% Rainbow, ~164 coins/phút, nên mọi giá hiện tại quá rẻ. Thêm trần thì quá phẳng (cần Dragon chỉ hơn Duckling 1.8 lần).
- Giá trị rương bị tiền bán trứng chi phối (Rainbow ~822 coins kỳ vọng, 450 là coins).
- Ao nhà theo luật cũ lời hơn hồ ở đầu game (không ngỗng, không chạy về, không tranh rương).
- Cướp mà cho tự chọn món xịn nhất thì lời gấp 5 đến 10 lần câu hồ; lấy ngẫu nhiên 4 món thì 0.45 đến 0.75 lần.
- Nếu Stash mở rương tức thì thì kho luôn trống, cướp vô nghĩa. Kho trong máy câu và trứng chờ ấp là thứ cướp được.

**File:** `tools/sim_economy.py` (mới), `ECONOMY_DESIGN.md` (mới), `CLAUDE.md`, `PROJECT_OVERVIEW.md`, `SYSTEM_DESIGN.md`, `DEVLOG.md`. **Không sửa code Luau, không đụng Studio.**

**Đã kiểm tra:** chạy `python tools/sim_economy.py` ra các bảng đúng với số trong `ECONOMY_DESIGN.md`.

**Chưa xong / lưu ý:**
- Toàn bộ là [ĐỀ XUẤT]: số lấy từ mô hình thô, cần đo ngoài game 3 thứ (tỉ lệ mất túi mỗi chuyến, rương/phút thật khi 4-8 người, thời gian chạy về nhà).
- Chưa code: bảng `Odds`, `EquippedPet`, tier máy câu, perk (`Loadout.lua`), kho rương, cướp nhà. Thứ tự làm ở `ECONOMY_DESIGN.md` mục 9.
- Perk loot của cần (CoinMult, EggChanceMult) chưa được tính trong bảng thu nhập.

---

## #29 · 14/10/2026 · Bag dạng lưới có hình, nhà trống đầy đồ để test cướp (dev)
**Yêu cầu:** bảng Bag dạng grid, phân loại, kèm hình đồ; trong môi trường dev cho các nhà khác đầy đồ, máy câu, trứng để đi cướp.

**Đã làm:**
- **Bag (`MainUI.client.lua`):** 4 mục có tiêu đề: 🥚 Eggs, 🐾 Pets, 🎣 Rods, 👟 Gear, mỗi mục là lưới ô 100x118 (4 cột). Mỗi ô có hình model 3D thật (ViewportFrame, `Models.Get`, bỏ script / Humanoid, cache bản gốc), tên, dòng phụ (thời gian ấp / HP / Luck / tốc độ), huy hiệu số lượng `xN`, viền màu theo hạng (6 bậc). Món **chưa có** hiện bóng đen mờ (trứng, pet, cần chưa mua) nên thấy được bộ sưu tập; cần đang dùng có nhãn EQUIPPED. Đang mang rương trong túi tạm thì hiện dòng nhắc cất Stash.
- **Thứ tự trứng** lấy từ `Config.EggOrder` (đã đổi ở #28).
- **Nhà chưa có chủ (chỉ trong Studio khi `Config.Dev.Enabled`):** `Plots.lua` bày sẵn 5 máy câu (kho đầy, animation Full) và 4 máy ấp, mỗi máy một trứng đã nở xong (Gold / Dragon / Crystal / Bubble, animation Hatch), không có nút [E]. Khi người chơi rời game thì plot trả lại trạng thái đầy đồ.

**File:** `StarterGui/MainUI.client.lua`, `ServerScriptService/Modules/Plots.lua`. Docs: `PROJECT_OVERVIEW.md`.

**Đã kiểm tra:** `selene .` 0 lỗi; Play: mở Bag thấy lưới trứng / pet / cần / giày với hình và bóng đen đúng; 7 plot trống đều có 13 đối tượng (4 máy ấp, 4 trứng, 5 máy câu), nhìn thấy trứng "Ready!" trong Hatchery plot 2. Nhớ đồng bộ `GRIP` cần câu (+20 độ) vào Studio ở lần này.

**Chưa xong / lưu ý:**
- **Cơ chế cướp nhà chưa được code** (chỉ có thiết kế ở `SYSTEM_DESIGN.md` mục cướp nhà): hiện các nhà đầy đồ chỉ để xem, chưa lấy được gì.
- Hình trong ô hiện chậm ~1 giây lần đầu mở (ViewportFrame nạp); cần câu mảnh nên hơi nhỏ trong ô.

---

## #28 · 14/10/2026 · Import asset từ repo roblox-assets (cần, pet, trứng, rương, máy câu, ngỗng)
**Yêu cầu:** import các asset trong repo `assets-roblox` (thực tế là `C:\Roblox
oblox-assets`) vào game, ghép đủ, mở rộng Config theo asset.

**Đã làm:**
- **Import:** `tools/prepare_assets.py` chép 29 file `.rbxmx` vào `Assets/Models/` (đồng bộ vào `ReplicatedStorage/CustomModels` qua Rojo: `default.project.json` có `$path`). Script chỉnh nhẹ: tắt script client trên bản mẫu (Models.Get bật lại trên bản sao), vá `RodEffects` (bỏ Beam dây + giọt nước ở móc, vì game tự vẽ dây và phao).
- **Config mở rộng:** 5 rương (Wooden / Blue / Purple / Golden / Rainbow), 6 trứng ↔ 6 pet (1 trứng nở 1 pet), 6 cần, 5 máy câu theo độ hiếm, `Config.EggOrder`, trường `Model` trỏ tên asset. Giá / HP / tỉ lệ ở `PROJECT_OVERVIEW.md` là số đề xuất, cần cân bằng lại.
- **`Models.lua`:** ánh xạ tên game -> asset, bật script trên bản sao, `Anchor` chỉ neo PrimaryPart cho model rig (neo hết thì animation Motor6D không chạy), `PlaceOnGround`, `SetAnim`.
- **Rương:** Effects dùng animation Spawn / Open / Vanish của asset (model tạm vẫn dùng tween cũ). Stash trong nhà là rương Common.
- **Trứng:** trong máy ấp phát `Incubate`, ấp xong phát `Hatch` (vỏ vỡ, ngôi sao chui ra).
- **Pet:** không hàn lại rig, bỏ Humanoid, animation theo việc: Idle / Walk / Run (theo tốc độ chủ), Attack (chặn ngỗng), Happy (vừa hiện).
- **Ngỗng:** dùng `PoliceGoose` (Humanoid có sẵn), animation theo trạng thái: Patrol = Walk / Idle, Suspicious = Alert, Chase = Whistle rồi Run, đánh pet = Attack / Stunned, Search.
- **Máy câu:** máy thứ i dùng `AutoFisher_<Tier i>`, thu nhỏ 0.7 cho 5 máy vừa hàng (HouseBuilder đổi sang 5 ô, x = 16..40). Animation Work / Full (theo kho đầy) / Collect, `Fill` theo số rương tích. Sửa lỗi cũ: chữ "Empty slot" của bệ còn lại sau khi đã có máy.
- **Cần câu:** Model rig được bọc thành Tool (HumanoidRootPart thành Handle). Server đổi animation theo lượt câu: Cast (1.2s) rồi Reel, tạm dừng thì Idle, lấy được Catch, hụt Miss. Móc của cần bị ẩn, dây buộc vào Part `Tip`.

**File:** `Config.lua`, `Models.lua`, `Fishing.lua`, `Pets.lua`, `Guard.lua`, `Plots.lua`, `AutoFishers.lua`, `HouseBuilder.lua`, `Effects.client.lua`, `MainUI.client.lua` (thứ tự trứng), `default.project.json`, `tools/prepare_assets.py`, `Assets/Models/*`. Docs: `PROJECT_OVERVIEW.md`, `HUONG_DAN.md`.

**Đã kiểm tra:**
- `selene .`: 0 lỗi. Rojo không chạy nên nạp file rbxmx bằng `GetObjects` (copy vào thư mục content của Studio) và chép code qua HTTP cục bộ tạm (đã tắt).
- Play: 29 model nạp được, script bản mẫu tắt. Dựng thử rương / trứng / pet / ngỗng qua `Models.Get`: tên game ánh xạ đúng asset, hiệu ứng và animation chạy. 5 máy câu hiện đúng 5 màu độ hiếm, pet Chef Cat chạy theo chủ, ngỗng cảnh sát đuổi người chơi, cần Fox cầm trên tay, lượt câu hụt phát Miss rồi về Idle. Output không có lỗi script.

**Chưa xong / lưu ý:**
- **Sound:** asset có 30+ file `.wav` nhưng cần upload lên Creator Hub rồi điền ID vào bảng đầu script `*Sounds` (chưa làm, đang im lặng).
- **Góc cầm cần** (`GRIP` trong `Fishing.lua`) vừa chỉnh sang +20 độ, chưa xem lại trong Studio (bản đang chạy còn -55).
- Chưa test hết: animation Cast / Reel / Catch của cần trong 1 lượt câu hoàn chỉnh, hiệu ứng trứng `Hatch` khi ấp xong, pet nở (`Hatched`) trong máy ấp, nhiều người chơi cùng lúc.
- Máy câu thu nhỏ 0.7, 5 máy hơi sát nhau; Pet asset có `Highlight` + hạt, nhiều pet cùng lúc có thể nặng trên điện thoại (asset README cũng cảnh báo).
- Model free cũ trong `CustomModels` (Cat, Dog, Basic Rod...) không còn dùng, để nguyên (Rojo không xoá).
- Dữ liệu người chơi cũ (Eggs Common / Rare, pet Cat...) không tương thích tên mới; bản Studio không lưu DataStore nên chưa ảnh hưởng.

---

## #27 · 14/10/2026 · Tài liệu thiết kế hệ thống vật phẩm hiếm, nhà, ngỗng, cướp nhà
**Yêu cầu:** viết docs về cấu trúc thành phần hệ thống để dev sau đọc hiểu game có gì, cơ chế ra sao.

**Đã làm:**
- Tạo `SYSTEM_DESIGN.md`: bản đồ thành phần, thang độ hiếm 5 cấp, ánh xạ sang model của repo `roblox-assets`, cơ chế rương / túi / Stash / mở rương / trứng / pet / cần / máy câu, 3 loại ngỗng (hồ, nhà, đồn cảnh sát), thang nghi ngờ, đồng hồ 60 giây, cướp nhà, vùng an toàn theo từng người, dữ liệu profile, hợp đồng attribute với model, việc còn mở, thứ tự triển khai.
- Mỗi mục có nhãn **[ĐÃ CÓ] / [ĐÃ CHỐT] / [ĐỀ XUẤT] / [CHƯA CHỐT]** để phân biệt code hiện tại với thiết kế chưa làm.
- Thêm `SYSTEM_DESIGN.md` vào bảng tài liệu của `PROJECT_OVERVIEW.md` và danh sách "Đọc trước khi làm" của `CLAUDE.md`.

**File:** `SYSTEM_DESIGN.md` (mới), `PROJECT_OVERVIEW.md`, `CLAUDE.md`, `DEVLOG.md`. Không sửa code.

**Đã kiểm tra:** đối chiếu số liệu với `Config.lua`, `Data.lua`, `Bag.lua`, `Fishing.lua`, `Hatchery.lua`, `HouseBuilder.lua` (plot 90x90, hàng rào 44.5). Xác nhận `SafeZone.Contains` là vùng chung dùng ở 5 chỗ, và công thức Luck `luck^(i-1)` đúng như mô tả.

**Chưa xong / lưu ý:**
- Toàn bộ phần [ĐÃ CHỐT] chưa code. Số liệu [ĐỀ XUẤT] cần cân bằng bằng mô phỏng.
- Chưa kiểm tra `MapBuilder.lua` để chọn vị trí đồn cảnh sát, chưa kiểm tra bố cục sân cho vòng tuần của ngỗng nhà.
- Các điều còn mở nằm ở mục 12 của `SYSTEM_DESIGN.md`.

---

## #26 · 14/10/2026 · Rương hồ ra ngẫu nhiên trước ngỗng, câu sau khi ngỗng đi qua thì bị quay lại đuổi
**Yêu cầu:** rương ở hồ spawn ngẫu nhiên trước khi ngỗng bước tới; nếu ngỗng đi chưa xa mà người chơi câu thì ngỗng quay lại đuổi.

**Đã làm:**
- **Rương không còn có sẵn.** `FishingSpots.lua` chạy vòng 0.5 giây: điểm nằm phía trước ngỗng đang tuần tra (cách 25-80 stud, trong góc ~60 độ) có 30% hiện phao CHEST. Tối đa 3 rương cùng lúc, rương không ai câu biến mất sau 40 giây. Điểm chưa có rương thì ẩn phao, ném vào đó báo "Nothing bites here".
- **Câu xong / hụt:** phao biến mất, điểm nghỉ 20 giây mới ra lại (bỏ chữ "Resting").
- **Ngỗng quay lại:** ngỗng đi ngang điểm trong 22 stud thì điểm ghi `PassedAt`. Câu ở điểm đó trong 20 giây sau khi ngỗng vừa đi ngang, và ngỗng còn trong 70 stud, thì `Guard.Recall` chuyển ngỗng sang Chase ngay (nói "Hey! Come back here!", cho thêm 6 giây "coi như còn thấy" để kịp chạy tới).
- `Guard.Positions()` mới: trả vị trí / hướng nhìn / trạng thái từng ngỗng cho FishingSpots.
- Số mới trong `Config.Spots`: `MaxActive 3, SpawnAhead 80, SpawnMinDist 25, SpawnChance 0.3, Lifetime 40, PassRadius 22, ReturnWindow 20`; trong `Config.Guard`: `ReturnRange 70, ReturnGrace 6`.

**File:** `Config.lua`, `Guard.lua`, `FishingSpots.lua`. Docs: `PROJECT_OVERVIEW.md`.

**Đã kiểm tra:**
- `selene .`: 0 lỗi. Rojo không chạy nên chép 3 file vào Studio qua HTTP cục bộ tạm (đã tắt).
- Chạy 40 giây: sau ~7 giây đã có 3 rương, đều nằm phía trước ngỗng, không có rương nào ở sau lưng.
- Đưa người chơi tới điểm vừa bị ngỗng đi ngang (cách ngỗng 34 stud), giả lập bấm câu: ngỗng nói "Hey! Come back here!", chạy lại và "Gotcha!".

**Chưa xong / lưu ý:**
- Chưa test trường hợp ngẫu nhiên nhiều người cùng lúc, và chưa test lúc ngỗng đã đi xa hơn 70 stud (đoán là an toàn theo điều kiện khoảng cách).
- Hướng dẫn người chơi (Tutorial) chưa nhắc "rương chỉ hiện trước khi ngỗng đến".
- Cân bằng: 3 rương / 40 giây / 70 stud là số khởi điểm, cần chơi thử để chỉnh.

---

## #25 · 14/10/2026 · Làm lại UI/UX: theme "Sunny Park + Egg Pop" cho trẻ em
**Yêu cầu:** thanh công cụ và các nút dễ thao tác cho trẻ em, thiết kế nhất quán, nút có hiệu ứng và icon rực rỡ.

**Đã làm (chỉ `MainUI.client.lua`, không đổi luật game):**
- **Bảng màu mới** (`COLORS`): tím đậm làm nền, viền tối dày, màu rực. Quy ước: vàng = tiền, xanh lá = mua / về nhà, xanh dương = hành động chính, cam = Shop, hồng = Bag, đỏ = bán / đóng, xám = không bấm được.
- **Hàm nút chung** `button()` + `candy()` + `addFx()`: bo tròn, viền, bóng sáng; rê chuột phóng to, nhấn co lại, nhả thì nảy. Mọi nút trong bảng dùng chung, cỡ chữ tối đa 20.
- **Nút Fish tròn 128px ở góc dưới phải** (trước: giữa đáy màn hình, dễ đè thanh kéo). Nút "thở" khi chờ, đổi cam + chữ REELING + cần câu lắc khi đang giữ. PC có huy hiệu phím F. Điện thoại dời sang trái 200px để chừa chỗ cho nút nhảy.
- **Dock bên phải**: nút vuông 68px, icon emoji lắc nhẹ + nhãn (HOME / LAKE / SHOP, đường kẻ, BAG). Giá teleport là chip vàng ở góc nút.
- **Cột góc trên trái** xếp tự động bằng UIListLayout (né menu Roblox): Coins, Bag (hiện FULL khi đầy), mũi tên Stash, Tutorial. Số coins nảy lên khi tăng.
- Toast hình viên thuốc, nảy khi hiện; cảnh báo ngỗng có emoji và rung nhẹ; thanh kéo cá / HP pet ở giữa đáy.
- **Bảng (Shop / Market / Hatch / Bag)**: tiêu đề hồng + icon, hàng cao 64, nút 100x42, nút đóng ✖ 46px, co theo cỡ màn hình, nảy khi mở.
- Hướng dẫn bước 2 đổi chữ thành "HOLD the big FISH button".
- **Sửa số bị loang:** `UIStroke` mặc định áp lên cả chữ (quầng vàng quanh chữ). `make()` giờ luôn đặt `ApplyStrokeMode = Border` cho UIStroke. Thẻ Coins / Bag dùng cỡ chữ cố định 26 (không `TextScaled`), icon tách riêng bên trái, số căn phải, ngăn nhóm nghìn bằng dấu cách (`1 000 000`).

**File:** `StarterGui/MainUI.client.lua`. Docs: `PROJECT_OVERVIEW.md`, `HUONG_DAN.md`.

**Đã kiểm tra:**
- `selene`: 0 lỗi. Rojo không chạy nên chép file vào Studio qua HTTP cục bộ tạm (đã tắt).
- Play: HUD, dock, nút Fish, toast, bảng Tool Shop hiển thị đúng; Output không có lỗi mới.
- Emoji 🪙 không hiện trong Roblox (ô vuông), đã đổi sang 💰.

**Chưa xong / lưu ý:**
- Chưa thử trên giả lập điện thoại: vị trí nút Fish và nút Sprint của Roblox (`ContextActionService`) có thể chồng nhau, cần xem lại.
- Icon là emoji tạm; sau này thay bằng ImageLabel khi có bộ icon thật.
- Chưa thử bấm nhả nút Fish để xem hiệu ứng REELING trong lúc thật sự kéo cá.

---

## #24 · 14/10/2026 · Gộp điểm câu thành CHEST, trứng theo độ hiếm rương, bỏ chỗ nấp
**Yêu cầu:** không tách điểm câu rương / trứng riêng; rương hiếm thì có tỉ lệ ra trứng xịn; xoá chỗ ẩn nấp.

**Đã làm:**
- **Bỏ điểm EGG:** cả 6 phao trên hồ đều là **CHEST**. Bỏ `Config.Spots.EggChance / EggHoldTime / EggTiers`, bỏ `Kind` trong `FishingSpots.lua`.
- **Trứng theo rương** (`Config.Chests[].Eggs` + hàm `Config.RollChestEgg`): mỗi rương ra tối đa 1 trứng, xét trứng xịn trước.
  - Wooden: Common 30% (trước: Common 30%).
  - Golden: Rare 15%, không thì Common 60% → tổng Common 51%, Rare 15% (trước: Common 70%).
  - Diamond: Rare 60%, không thì chắc chắn Common → Common 40%, Rare 60% (trước: Rare 100%).
  - Áp dụng cho mọi nguồn rương (hồ, ao nhà, máy câu tự động) vì đều qua `Fishing.RollReward`.
- **Xoá chỗ nấp:** xoá `Cover.lua`, bụi lau sậy + `HideZone` trong `ParkBuilder`, hook `IsHidden` trong `Guard`, chữ "HIDDEN" trên HUD.
- Hướng dẫn bước 2 bỏ chữ "EGG" và "hide in the reeds".

**File:** `Config.lua`, `Fishing.lua`, `FishingSpots.lua`, `ParkBuilder.lua`, `Guard.lua`, `Main.server.lua`, `MainUI.client.lua`, `Cover.lua` (xoá). Docs: `PROJECT_OVERVIEW.md`, `MAP_LEVEL1.md`.

**Đã kiểm tra:**
- `selene .`: 0 lỗi.
- Rojo không chạy nên chép code vào Studio qua MCP (tạm bật HttpEnabled để đọc file, xong tắt lại). Kích thước `Source` khớp repo, đã xoá `Cover` trong Studio.
- Tung 20.000 lần mỗi rương: Wooden 30/0/70, Golden 51/15/34, Diamond 40/60/0 (Common/Rare/không), đúng như tính.
- Map: 6 `FishingSpot`, 6 bảng CHEST, 0 EGG, 0 Reeds, 0 HideZone.
- Câu ở điểm: phao bám đúng điểm, ra Golden Chest; lần sau kéo hết ra Wooden Chest vào túi (Bag 1/4). Output không có lỗi.

**Chưa xong / lưu ý:** không có chỗ nấp nữa, nên cách tránh ngỗng chỉ còn nhả nút (tạm dừng) và pet đỡ đòn. Nếu thấy quá khó thì có thể giảm `Guard.SightRange` hoặc `SuspiciousTime`.

---

## #23 · 14/10/2026 · Điểm câu CHEST/EGG (B3) + bụi lau sậy để nấp (B2)
**Yêu cầu:** làm B2, B3 và test hết các chức năng vừa làm.

**Đã làm:**
- **B3 · Điểm câu** (module mới `FishingSpots.lua`, `Config.Spots`):
  - 6 điểm cố định trong hồ (Part `FishingSpot`, ParkBuilder đặt), mỗi bờ có điểm câu.
  - Mỗi điểm có **phao nổi** (vòng neon, bong bóng) và bảng chữ **CHEST** (vàng) hoặc **EGG** (tím). Bên trong ra gì thì chưa biết trước.
  - Phải ném phao cách điểm ≤ 7 stud mới móc được, phao bám đúng vào điểm. Ném ra nước trống thì báo "Nothing bites here".
  - **Mỗi điểm chỉ 1 người câu** (`Claim`), bảng hiện "(being reeled)". Tạm dừng vẫn giữ điểm.
  - Lấy được hoặc hụt thì điểm **nghỉ 20 giây** (bảng "Resting Ns"), rồi ra mục tiêu mới (EGG 30%).
  - **Điểm EGG:** kéo 10 giây, ra trứng Common 85% hoặc Rare 15% (luck của cần tăng tỉ lệ Rare), không có coins.
  - Ao ở nhà vẫn câu tự do như cũ.
- **B2 · Bụi lau sậy** (module mới `Cover.lua`):
  - 6 bụi (ngọn lau + bông nâu, không va chạm), mỗi bụi nằm sau một chỗ đứng câu, cách khoảng 8–9 stud, tức trong tầm `Leash` 12.
  - Kèm Part vô hình `HideZone`. **Đứng trong bụi và không kéo câu thì ngỗng không thấy**, kể cả khi túi có đồ. Chỉ lộ khi ngỗng sát bên (`AttackRange` 6).
  - Đang bị đuổi mà nấp được thì ngỗng mất dấu.
  - Server đặt attribute `Hidden` trên Humanoid, HUD hiện **"HIDDEN in the reeds"**.
  - `Guard`: thêm hook `IsHidden` (trong `suspicionRange` và khi đang Chase).
  - Cây non tránh các bụi lau sậy, đèn và ghế cũng tránh.
- Hướng dẫn bước 2 đổi chữ: đứng trên lối gạch, nhắm vào phao CHEST / EGG, ngỗng kêu thì nhả nút và nấp vào lau sậy.

**File:** `FishingSpots.lua` (mới), `Cover.lua` (mới), `ParkBuilder.lua`, `Fishing.lua`, `Guard.lua`, `Main.server.lua`, `MainUI.client.lua`, `Config.lua`.

**Đã test (Studio qua MCP):**
- Map có 6 `FishingSpot` và 6 `HideZone`. Các phao hiện CHEST / EGG.
- **B3:**
  - Ném ra nước trống bị từ chối.
  - Câu điểm CHEST: bảng hiện "(being reeled)"; tạm dừng rồi kéo tiếp được Wooden Chest; điểm chuyển "Resting 20s"; câu lại thì bị từ chối "resting".
  - Điểm EGG: kéo 10 giây, ra Common Egg vào túi.
- **B2:**
  - Trên lối gạch: Hidden=false. Trong bụi: Hidden=true, HUD hiện chữ.
  - Có đồ, đứng **ngoài** bụi trước mặt ngỗng 7 stud: Suspicious rồi Chase (người mới chưa có pet nên bị bắt).
  - Có đồ, nấp **trong** bụi khi ngỗng đi tới 8.8 stud: ngỗng nghi ngờ (vì vừa thấy lúc còn ngoài bụi) rồi **bỏ qua**, không đuổi, túi còn nguyên.
- Nhóm B1, B4, B5, B6 đã test ở #22.

**Chưa test:** 2 người tranh 1 điểm câu (cần nhiều người chơi), tiếng pet yếu.

---

## #22 · 14/10/2026 · Trứng khởi đầu + hướng dẫn, âm thanh, chỉ số pet, Dép Tên Lửa
**Yêu cầu:** làm nhóm B trong đề xuất, trừ B2 (bụi lau sậy) và B3 (điểm câu hiện mục tiêu).

**Đã làm:**
- **B1 · Người mới:**
  - `Data.Load` tặng **1 Starter Egg** cho ai chưa có pet (`profile.StarterGiven`). Trứng nở trong 5 giây, luôn ra **Cat**, không bán được.
  - Module mới **`Tutorial.lua`**: 3 bước lưu ở `profile.Tutorial` (người cũ đã có pet = 99, coi như xong):
    1. Ấp trứng: `Hatchery` gọi khi nở pet.
    2. Câu được rương ở hồ: `Fishing` gọi khi câu xong ở hồ.
    3. Cất đồ vào Stash: `Bag` gọi khi cất thành công.
  - `MainUI` có khung **"TUTORIAL x/3"** ở bên trái màn hình, làm xong thì ẩn.
- **B4 · Âm thanh** (`Config.Sounds`, phát ở `Effects.client.lua`). 7 asset free, đã test tải được:
  - Ngỗng "Honk?" khi nghi ngờ, **còi** khi bắt đầu đuổi.
  - "Tõm" khi hụt, tiếng nhận rương, tiếng xu khi cất đồ hoặc mở máy câu, tiếng "pop" khi trứng nở.
  - Pet kêu khi HP tụt dưới 30% hoặc khi kiệt sức.
- **B5 · Chỉ số pet** (`Config.Pet.Stats`, `Config.PetMaxHP`): Cat 100, Dog 130, Fox 120, Dragon 200, Phoenix 260 HP.
  - Ngưỡng báo nguy đổi thành `WarnRatio` = 30%. Pet nào cũng hồi đầy sau 40 giây.
  - Bảng Bag và Market hiện HP, cùng số giây pet chặn được ngỗng.
- **B6 · Dép Tên Lửa** (`Config.Gear.RocketSandals`): **2000 coins, +10% tốc đi và chạy**.
  - Bán ở Tool Shop, mục "Gear". Thêm `Shop.BuyGear`, action `BuyGear`, profile thêm `Gear`.
  - `Sprint.client.lua` đọc `profile.Gear` qua `Sync` rồi nhân tốc độ.

**File:** `Tutorial.lua` (mới), `Config.lua`, `Models.lua`, `Data.lua`, `Hatchery.lua`, `Fishing.lua`, `Bag.lua`, `Market.lua`, `Pets.lua`, `Shop.lua`, `Main.server.lua`, `MainUI.client.lua`, `Sprint.client.lua`, `Effects.client.lua`.

**Đã test (Studio qua MCP, người chơi mới):**
- Có Starter=1, Tutorial=1, UI hiện "TUTORIAL 1/3". Bán Starter bị từ chối.
- Mua dép: tốc độ đi 17.6 (= 16 × 1.1), mua lần hai bị từ chối.
- Ấp Starter rồi bấm E (giả lập phím): ra **Cat**, Tutorial=2, pet đi theo.
- Câu ở lối gạch: được Diamond Chest, Tutorial=3. Lúc đó ngỗng đuổi: có tiếng Honk và còi, dịch chuyển bị chặn.
- Cất đồ ở Stash: Tutorial=99, UI ẩn, +1 Rare Egg.
- Âm thanh đã phát: Catch, Coins, Splash, Pop, GooseHonk, Whistle.

**Ghi chú test:**
- `ProximityPrompt:InputHoldBegin()` không ổn định khi người dùng đang chơi cùng lúc, nên dùng `user_keyboard_input` phím E thì chắc hơn.
- Điểm đáp `LakeArrival` cách mặt nước khoảng 27 stud, phải đi bộ ra lối gạch mới câu được. Đây là hành vi cố ý.

**Chưa test:** tiếng pet yếu (PetWarn). Thông báo riêng "túi có đồ" khi dịch chuyển cũng chưa thấy, vì lúc đó đang bị đuổi nên game báo lỗi bị đuổi trước.

---

## #21 · 14/10/2026 · Nhà to hơn + rương Stash ra sân trước
**Yêu cầu:** chỉnh nhà nhìn to hơn; rương để chỗ khác, ngoài nhà.

**Đã làm (`HouseBuilder.lua`):**
- **Nhà:** 24×18 tường cao 10 → **32×24 tường cao 12**. Mái dốc cao hơn (`RIDGE = WALL_TOP + 7`).
  - Cửa 6×8, hiên rộng 20 có mái và đèn.
  - Cửa sổ to hơn (`WIN = 4.4`), giờ có 2 trước, 2 mỗi bên, 2 sau. Thêm cửa sổ tròn trên hồi nhà, ống khói to hơn.
  - Mặt sau nhà vẫn ở z = 4 nên không đè chuồng ấp (z ≥ 10) và ô máy câu (z ≥ 5.5).
- **Nội thất xếp lại theo nhà mới:** giường có tủ đầu giường và đèn ngủ, bàn ghế, kệ sách, lò sưởi, đèn trần. Ổ pet ở góc trái phía trước (-11, -15). Kệ trưng bày ở tường trước, bên phải cửa.
- **Stash ra sân trước:** bên trái lối đá, gần cổng (-10, -32), đặt trên bục gỗ `StashDeck`, mặt rương quay ra lối đi.
  - Phóng 1.8 lần (trước là 2.5 lần, model free trong `CustomModels` bị quá to và chắn cổng).
  - Đặt **đáy rương theo hộp bao thật** chạm mặt bục, nên thay model nào cũng đứng đúng.
- Luống hoa 2 bên hiên dời ra x = ±13.

**Đã test (Studio qua MCP):**
- Nhà 34×33×24 tính cả hiên và mái chìa. Không đè chuồng ấp.
- Stash 4.2×4.3×6, đáy ở y = 0.30 (đúng mặt bục), có nút [E].
- Chụp ảnh xong đã Stop/Play lại, camera = Custom. Không có lỗi trong Output.

---

## #20 · 14/10/2026 · Dịch chuyển về nhà và tới Tool Shop cũng tốn tiền
**Yêu cầu:** nút My Plot và Tool Shop cũng tốn tiền.

**Đã làm:**
- `Config.Teleport`: `ShopCost` 0 → **10**, thêm `HomeCost` = **10**. `LakeCost` vẫn là 20.
- `Teleports.ToHome`: trừ tiền, dịch chuyển lỗi thì hoàn lại, báo "Welcome home! (-10 coins)".
- Nút hiện giá: **My Plot (10)**, **Lake (20)**, **Tool Shop (10)**.
- **Vẫn miễn phí:** bị ngỗng bắt, hồi sinh, mới vào game. Những trường hợp này `Main` gọi thẳng `Plots.TeleportHome`, không qua `Teleports`.

**File:** `Config.lua`, `Teleports.lua`, `MainUI.client.lua`.

**Đã test (Studio qua MCP):**
- Shop −10, Plot −10, Lake −20, Plot −10, mỗi lần đều có thông báo đúng.
- 3 nút hiện đúng giá. Không có lỗi trong Output.

---

## #19 · 14/10/2026 · Tự test #15–#18 trong Studio + báo cooldown dịch chuyển
**Yêu cầu:** "Từ giờ tự test và tự triển khai code."

**Cách triển khai:**
- So mã băm `Source` của từng script trong Studio với file trong repo, bỏ qua khác biệt CRLF/LF.
- Kết quả: **25/25 khớp**, Rojo đã kết nối lại. Nếu Rojo mất kết nối thì chép nội dung file vào Studio qua MCP.

**Kết quả test (Play qua MCP, đã đạt):**
- **Map:**
  - Không còn bệ dịch chuyển. Có 4 `LakeArrival` và 1 `ShopArrival`.
  - **0 SpawnLocation thừa** (vật lạ giữa hồ đã mất).
  - Stash nằm ở toạ độ cục bộ (0, 3.8, 0.4), tức giữa tường sau.
  - 8 nhà đều có `PetBed` và `TrophyShelf`. Hộp thư không có nút [E] (quà hằng ngày đang tắt).
- **Dịch chuyển:**
  - Lake: −20 coins, đáp xuống lối vào phía Đông (gần Plot1 nhất).
  - Tool Shop: miễn phí, đáp trước shop.
  - My Plot: về nhà.
  - Bấm lại ngay thì bị chặn vì cooldown.
- **Nâng túi ở Tool Shop:** −300 lên 5 ô, −1200 lên 6 ô, lần thứ ba báo "already the biggest". HUD hiện Capacity = 6.
- **Câu ở ao nhà:** được rương, 2 lần thì ra 1 Common Egg.
- **Ấp và kệ trưng bày:** `StartHatch(1, "Common")`, sau 10 giây bấm [E] thì nhận "You hatched a Dog!". Kệ bày Dog, bảng "PET COLLECTION 1/5", pet đi theo người.
- **Ngỗng:**
  - Đứng cạnh ngỗng mà không câu: ngỗng bỏ qua (đúng luật câu lén).
  - Giữ nút câu 2.6 giây: bị đuổi. Ngỗng đánh pet, HP 100 → 69.
- **Ổ pet:** đứng ngoài sân hồi ~2.3 HP/s (chuẩn 2.5). Cạnh ổ hồi ≥ 3.8 HP/s (số đo chạm trần 100 HP; cấu hình là 6.25 HP/s).

**Sửa thêm:** dịch chuyển khi đang cooldown trước đây im lặng, giờ báo "Please wait a moment before teleporting again." (`Teleports.lua`). Đã test.

**Chưa test:** dịch chuyển khi túi có đồ (bị chặn). Logic chỉ là 1 điều kiện `Bag.Count > 0`.

---

## #18 · 14/10/2026 · Dịch chuyển chỉ bằng nút bấm (bỏ hết bệ)
**Yêu cầu:** dịch chuyển không dùng bệ, chỉ dùng nút bấm giống nút "My Plot".

**Đã làm:**
- Xoá toàn bộ bệ dịch chuyển và nút [E] của chúng:
  - `LakeTeleporter` và `ShopTeleporter` ở sân mỗi nhà.
  - 4 bệ `LakePad` ở hồ và bệ `ShopPad` trước Tool Shop.
  - Hàm `BuildUtil.teleportPad`.
- Thay bằng **điểm đáp vô hình** (`BuildUtil.marker`, không va chạm):
  - `LakeArrival`: 4 điểm ở 4 lối vào công viên. Nút Lake đáp xuống điểm gần nhà nhất.
  - `ShopArrival`: 1 điểm trước Tool Shop.
- Dịch chuyển giờ chỉ qua 3 nút bên phải màn hình (đã có từ #15 / #17): **My Plot**, **Lake (20)**, **Tool Shop**. Luật giữ nguyên (xem `Teleports.lua`).
- `Teleports.lua` chỉ còn tìm điểm đáp, không tạo nút [E] nữa.

**File:** `Teleports.lua`, `BuildUtil.lua`, `HouseBuilder.lua`, `ParkBuilder.lua`, `MapBuilder.lua`.

**Đã kiểm tra:** `selene` không có lỗi.

**Đã test trong Studio ở #19.**

---

## #17 · 14/10/2026 · Nâng túi chuyển sang Tool Shop + dịch chuyển tới Tool Shop + tạm tắt quà hằng ngày
**Yêu cầu:** nâng balo nên mua ở Tool Shop; thêm dịch chuyển tới Tool Shop; quà hằng ngày tạm bỏ, nhắc lại sau.

**Đã làm:**
- **Nâng túi chuyển sang Tool Shop:**
  - Bảng Shop có thêm dòng **"Bigger Bag"** (túi 5 giá 300, túi 6 giá 1200).
  - Thêm `Shop.BuyBagUpgrade` và action `BuyBagUpgrade`.
  - `Config.House.BagUpgrades` đổi thành **`Config.Bag.Upgrades`**.
  - Xoá móc balo (`BagHook`) trong nhà cùng toàn bộ code nâng túi trong `House.lua`.
- **Dịch chuyển tới Tool Shop** (`Teleports.ToShop`, `Config.Teleport.ShopCost` = 0, miễn phí):
  - Bệ **`ShopTeleporter`** ở sân trước mỗi nhà, **bên phải** lối đi, đối xứng với bệ ra hồ.
  - Nút UI **"Tool Shop"**, action `Teleport("Shop")`.
  - Đáp xuống bệ **`ShopPad`** trước Tool Shop, quay mặt vào quầy. Đứng trên `ShopPad` bấm [E] để về nhà.
  - **Bị chặn khi túi có đồ hoặc đang bị đuổi.** Lý do: trước Tool Shop là vùng an toàn quanh `Spawn`, nếu không chặn thì người chơi dùng shop để né ngỗng.
- **Quà hằng ngày tạm tắt:** `Config.House.Daily.Enabled = false`. Code vẫn giữ, hộp thư không có nút [E].
  - **Việc chờ:** nhắc người dùng bật lại khi vòng chơi chính đã ổn, hoặc khi tính tới publish / giữ chân người chơi.

**File:** `Config.lua`, `Shop.lua`, `Bag.lua`, `Data.lua`, `House.lua`, `HouseBuilder.lua`, `MapBuilder.lua`, `Teleports.lua`, `Main.server.lua`, `MainUI.client.lua`.

**Đã kiểm tra:** `selene` không có lỗi.

**Đã test trong Studio ở #19.**

---

## #16 · 14/10/2026 · Đồ chức năng trong nhà + xoá vật lạ giữa hồ
**Yêu cầu:** làm đề xuất 1 (ổ pet), 2 (nâng cấp túi), 4 (kệ trưng bày), 6 (quà hằng ngày); xoá cái bệ trắng ở giữa hồ.

**Đã làm:**
- **Vật lạ giữa hồ** = SpawnLocation mặc định của template Baseplate ở (0,0,0). Từ khi hồ dời về tâm map, nó nằm ngay giữa hồ.
  `MapBuilder.Build` giờ **xoá** mọi SpawnLocation nằm ngoài `Map` lúc chạy game (trước đây chỉ tắt `Enabled`).
- Module mới `House.lua` gắn logic cho đồ trong nhà. Nút [E] chỉ chủ nhà dùng được, tạo khi cấp plot và xoá khi thu hồi.
  1. **Ổ pet** (`PetBed`, góc trái phía trước, thay chậu cây): chủ đứng trong `PetBedRange` = 10 stud thì pet hồi HP nhanh gấp `PetBedHealMult` = **2.5 lần**. Hồi đầy giảm từ 40 giây xuống khoảng 16 giây. `Pets.lua` gọi `House.HealMultiplier`.
  2. **Móc balo** (`BagHook`, tường trước, trái cửa): nâng cấp túi 4 → **5 (300 coins)** → **6 (1200 coins)**.
     - Profile thêm `BagLevel`.
     - `Bag.Capacity(player)` thay cho `Config.Bag.Capacity` ở mọi chỗ, HUD "Bag x/y" tự cập nhật.
  4. **Kệ trưng bày** (`TrophyShelf`, tường trước, phải cửa, 3 tầng x 2 chỗ `TrophySlot1..6`):
     - Tự đặt model thu nhỏ của mỗi **loại** pet đã có, hiếm nhất trước.
     - Bảng chữ "PET COLLECTION x/5". Cập nhật khi profile đổi (nở pet, bán pet).
  6. **Quà hằng ngày** ở hộp thư (`Sign`): **100 coins + 1 Common Egg** mỗi ngày (theo giờ UTC).
     - Profile thêm `LastDaily`.
     - Nút đổi chữ "Gift claimed" khi đã nhận. Bấm lại thì báo còn mấy giờ.
- `Plots`: thêm hook `OnAssign` / `OnRelease`, `Plots.MakeOwnerPrompt`, `Plots.Get`.
- `Config.House`: `PetBedRange`, `PetBedHealMult`, `BagUpgrades`, `Daily`, `TrophySlots`.

**File:** `House.lua` (mới), `HouseBuilder.lua`, `Plots.lua`, `Pets.lua`, `Bag.lua`, `Fishing.lua`, `Data.lua`, `Main.server.lua`, `MapBuilder.lua`, `Config.lua`.

**Đã kiểm tra:** `selene` không có lỗi. Đồ thị require không có vòng.

**Đã test trong Studio ở #19.**

---

## #15 · 14/10/2026 · Dịch chuyển nhà ↔ hồ (ra hồ tốn tiền) + dời rương Stash
**Yêu cầu:** có bệ dịch chuyển ra chỗ câu rương (tốn tiền) và về My Plot; đặt rương Stash ở chỗ hợp lý; đề xuất thêm chức năng cho nhà.

**Đã làm:**
- Module mới `ServerScriptService/Modules/Teleports.lua` gom mọi luật dịch chuyển:
  - **ToLake:** tốn `Config.Teleport.LakeCost` = **20 coins**. Đáp xuống bệ `LakePad` **gần nhà mình nhất**, quay mặt ra hồ.
    - Không cho dùng khi đang bị ngỗng đuổi.
    - Dịch chuyển lỗi thì trả lại tiền.
    - Đang có lượt câu thì huỷ lượt câu.
  - **ToHome:** miễn phí. **Bị chặn** khi túi có đồ chưa cất hoặc đang bị đuổi (giữ nguyên luật cũ).
  - Hai lần dịch chuyển cách nhau ít nhất `Config.Teleport.Cooldown` = 3 giây.
- **Bệ dịch chuyển trên map** (`BuildUtil.teleportPad`, đĩa neon xanh, bấm [E] giữ 0.3 giây):
  - `LakeTeleporter` đặt ở sân trước **mỗi nhà**, bên trái lối đi gần cổng, có bảng "TO THE LAKE 20 coins".
  - 4 bệ `LakePad` ở 4 lối vào công viên: Bắc (0,-62), Tây (-84,0), giữa quảng trường Đông và Nam. Bảng "TELEPORT HOME".
- Nút UI mới **"Lake (20)"** cạnh "My Plot". `Action Teleport` nhận `"Lake"` hoặc `"Plot"`; `Main` chỉ chuyển tiếp sang `Teleports`.
- `Plots`: thêm `Plots.Teleport` và `Plots.HomePart`.
- **Dời rương Stash:** chỗ cũ ở góc phải trước, rương phóng to 2.5 lần nên **cắm xuyên tường trước và đè lên lò sưởi**. Chỗ mới ở **giữa tường sau, đối diện cửa ra vào** (x -3.75..3.75, z -2..3), nằm giữa giường và kệ sách, vào nhà là thấy ngay.

**File:** `Teleports.lua` (mới), `Main.server.lua`, `Plots.lua`, `BuildUtil.lua`, `ParkBuilder.lua`, `HouseBuilder.lua`, `MainUI.client.lua`, `Config.lua`.

**Đã kiểm tra:** `selene` không có lỗi.

**Đã test trong Studio ở #19.**

---

## #14 · 14/10/2026 · Viết tài liệu cho người và AI đọc
**Yêu cầu:** "Mỗi lần code xong luôn viết md để người khác và AI biết đã làm gì."
**Đã làm:**
- Tạo `DEVLOG.md` (file này), `PROJECT_OVERVIEW.md` (bản đồ toàn bộ dự án) và `CLAUDE.md` (hướng dẫn ngắn cho AI).
- Sửa các chỗ cũ trong `HUONG_DAN.md` và `MAP_LEVEL1.md` còn nhắc Plaza, cầu tàu, nút Cast.

**Từ nay:** việc nào làm xong cũng phải có mục DEVLOG.

---

## #13 · 13–14/10/2026 · Bỏ sảnh chính, hồ ở giữa, nhà xếp vòng, cân bằng ngỗng
**Yêu cầu:** bỏ sảnh chính; bị ngỗng bắt thì về thẳng nhà; hồ ở giữa để quãng đường các nhà bằng nhau; nhả cần mà vẫn bị bắt thì quá khó, chỉnh lại nhưng đừng quá dễ.

**Đã làm:**
- **Bố cục mới:** hồ tâm = (0,0,0). Công viên x -110..110, z -80..80, có 4 lối ra. Đường vòng bán kính 150.
- **8 nhà xếp elip** Rx 228, Rz 212 (vì hồ rộng 130, dài 90). Xếp tròn thì lệch 117 vs 135 stud; xếp elip thì **mọi nhà cách lối gạch quanh hồ 129–131 stud** (đo trong Studio).
- **Tool Shop** đặt ở góc 225°, **Market** ở góc 45°, mỗi cái cách tâm 192 stud. `Spawn` đặt trước Tool Shop, chỉ dùng lúc mới vào game.
- **Bỏ Plaza** và nút **Plaza**. Bị bắt thì `Plots.TeleportHome`. Xoá `Plots.TeleportPlaza`.
- **Chặn dịch chuyển về nhà khi túi có đồ:** "You're carrying loot! Run it home on foot." Nếu không chặn, bấm My Plot là thoát ngỗng.
- `SafeZone.addZoneAround` giữ hướng xoay của model, vì nhà giờ nằm nghiêng.
- Đổi các câu thông báo "rest area / safe zone" thành "home".
- **Cân bằng** (số cũ → mới, lý do ở `PARK_REDESIGN.md` mục 8):
  - `SightRange` 50 → 40, `LootSightRange` 22 → 10, `ShortSight` 12 → 8
  - `SuspiciousTime` 1.5 → 2, `SearchTime` 4 → 3, `LoseTime` 5 → 4
  - `NoiseRadius` 70 → 45, `NoiseDelay` 2 → 3
  - `Leash` 10 → 12, `PauseTimeout` 30 → 40, `MaxMove` 1.5 → 3
- Dời `Config.Guard.Patrol` (12 điểm) về quanh tâm mới.

**File:** `MapBuilder.lua`, `ParkBuilder.lua`, `SafeZone.lua`, `Plots.lua`, `Main.server.lua`, `Fishing.lua`, `Pets.lua`, `MainUI.client.lua`, `Config.lua`, `MAP_LEVEL1.md`, `PARK_REDESIGN.md`.

**Đã kiểm tra:** Play bằng MCP. Map dựng đúng, không có lỗi Output, ngỗng tuần tra, người chơi về nhà.

**Chưa kiểm tra:** cảm giác né ngỗng sau khi chỉnh số (cần người chơi thật).

---

## #12 · 13/10/2026 · Bỏ cầu tàu chữ T + câu lén (nhả nút giữ tiến độ)
**Yêu cầu:** bỏ cầu chữ T; thả nút mà vẫn giữ vạch đang câu dở, để khi ngỗng ra kiểm tra thì đỡ bị bắt.

**Đã làm:**
- `ParkBuilder`: xoá cầu tàu và cột, lan can liền một vòng. Câu từ lối gạch qua lan can.
- `Fishing.lua`:
  - **Nhả = tạm dừng** (`CastPause`): giữ `Progress`, bỏ khoá đứng im, không gây tiếng động. **Giữ lại = kéo tiếp** (`CastResume`), quay mặt về phao.
  - Hụt khi: đi xa quá `Leash`, dừng quá `PauseTimeout`, pet gục, cất cần (`Unequipped`), bị bắt.
  - Thêm `Fishing.IsReeling(player)`.
- `Guard.lua`: thêm hook `Suspicion(player)`, trả về `"Reeling"` (thấy xa), `"Loot"` (thấy gần) hoặc nil (bỏ qua).
  - Hết thời gian "Honk?" mà người chơi không còn khả nghi thì ngỗng nói "...Hmm? Must be nothing." rồi chuyển sang Search.
  - Đã vào Chase thì vẫn đuổi tiếp dù người chơi nhả nút.
- `Main.server.lua`: truyền `Suspicion` vào `Guard.Init`.
- `MainUI.client.lua`: thanh kéo có trạng thái **PAUSED** (màu xám, đếm ngược giây còn lại).
- `Config`: thêm `Fishing.Leash`, `Fishing.PauseTimeout`, `Guard.LootSightRange`.

**Đã kiểm tra:** log có `CastStart → CastPause(1.0/6.0) → "line snapped"` khi đi xa. Kéo tiếp thì khoá đứng im lại (WalkSpeed 0).

---

## #11 · 13/10/2026 · Sửa "không điều khiển được nhân vật"
**Nguyên nhân:** `screen_capture` của MCP (có đặt vị trí camera) khi đang Play đã đổi camera sang `Scriptable` và không trả lại. Không phải lỗi code game.

**Cách sửa:** Stop rồi Play lại.

**Bài học:** chụp màn hình có đặt camera thì làm ở Edit, hoặc chụp xong phải Stop/Play và báo người đang chơi.

---

## #10 · 13/10/2026 · Công viên hồ khu dân cư + nhà gỗ vào được
**Yêu cầu:** hạ cỏ thấp; công viên hồ kiểu khu dân cư (ảnh tham khảo); My Plot thành nhà gỗ dễ thương. Chốt: nước xanh ngọc, nhà vào được, mái gỗ giống nhau, không làm nhà phông nền, 1 cầu tàu (sau đó bỏ ở #12).

**Đã làm:**
- Tách module: `BuildUtil.lua` (hàm dựng chung), `ParkBuilder.lua` (hồ + công viên + đường), `HouseBuilder.lua` (plot).
- **Hồ chữ nhật bo góc** 130x90, bờ kè, lối gạch cam đất, lan can, đèn và ghế xen kẽ, 2 quảng trường, cây non có cọc, cây tán lớn, nhà bảo vệ "GOOSE SECURITY".
- **Nhà gỗ:** mái gỗ 2 dốc, hồi tam giác (WedgePart), ống khói, hiên có đèn, cửa sổ có chậu hoa, cửa mở vào được. Bên trong có giường, bàn ghế, kệ sách, lò sưởi, đèn trần. Hàng rào gỗ trắng, hộp thư (`Sign`), thảm `Home`. Phía sau có chuồng ấp trứng gỗ (`IncubatorSlot1..4`) và ao nước thật (`FisherSlot1..4`, `Water`).
- **Bẫy Terrain đã gặp và sửa:**
  - Script không đổi được `Terrain.Decoration` nên dùng `LeafyGrass` để cỏ thấp.
  - Mặt đất hiện cao hơn vùng fill 2 stud, làm Part sát đất bị cỏ phủ. Đã bù bằng `TERRAIN_SHIFT = -2`, chỉ áp cho đất, không áp cho nước.
  - Nước không đổ đè lên đất đặc được, phải fill `Air` trước.
- Viết lại `Config.Guard.Patrol` theo lối gạch.

**Tài liệu:** `PARK_REDESIGN.md`.

---

## #9 · 13/10/2026 · (Phiên khác) Gameplay theo GDD "Hồ Không Cho Câu"
Do phiên/người khác làm song song. Tóm tắt để biết là đã có:
- **Câu giữ nút** (Kéo/Giữ/Hụt), điểm rơi phao do server tính và phải trúng nước, khoá đứng im khi câu.
- **Túi tạm 4 ô** (`Bag.lua`) và **Stash trong mỗi nhà**. Cất xong thì lưu. Bị bắt hoặc chết thì mất đồ.
- **Ngỗng bảo vệ** (`Guard.lua`) có pathfinding, chống rơi xuống hồ.
- **Vùng an toàn** (`SafeZone.lua`), **HP pet** và pet chặn ngỗng (`Pets.lua`), **cấm bơi** (`NoSwim.lua`).
- Toast 3 giây, UI thanh kéo, HP pet, mũi tên chỉ Stash, cảnh báo ngỗng.

Chi tiết: `BUGFIX_PLAN.md`.

---

## #8 · 13/10/2026 · Hồ nước thật đầu tiên + công viên (đã được thay ở #10)
- Đổi mặt hồ từ Part xanh sang **Terrain Water** (xanh ngọc, có sóng, phản chiếu).
- Bờ cát, đường đất, cây, ghế, đèn. Baseplate bị xoá lúc chạy game.

---

## #7 · 13/10/2026 · Dev coins, chạy nhanh, sửa lỗi tải dữ liệu
- **Lỗi:** DataStore bị chặn (Studio chưa bật API) thì `pcall` trả chuỗi lỗi, mà code lại dùng chuỗi đó làm profile. Kết quả: người chơi không có plot, không có gì. Đã sửa trong `Data.Load`.
- **Dev mode:** `Config.Dev`. Chạy trong Studio có 1.000.000.000 coins, game đã publish thì không.
- **Shift chạy nhanh:** `Sprint.client.lua`, `Config.Movement` (16 → 30, FOV 70 → 80). Tắt Shift Lock (`EnableMouseLockOption = false`).
- Xoá 28 model bị trùng trong `CustomModels`.

---

## #6 · 13/10/2026 · Kết nối Roblox Studio MCP
- Repo MCP cũ của Roblox đã ngừng. Dùng **MCP có sẵn trong Studio** (Assistant → Manage MCP Servers → Enable Studio as MCP server).
- Đăng ký trong Claude Code ở **phạm vi user**: `cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`. Phạm vi local lỗi vì lệch `c:\` và `C:\`.

---

## #5 · 13/10/2026 · Đưa code lên GitHub
- `git init`, `.gitignore` (bỏ `sourcemap.json`, `*.rbxl`).
- Commit đầu `fff0eb4`, push lên `tienlh42/chest-fishing-egg-roblox`.
- **Các thay đổi từ #7 trở đi CHƯA được commit.**

---

## #4 · 13/10/2026 · Model tạm đẹp hơn + script lấy model free
- Dựng lại cần câu (cán cork, máy quay, thân 3 đoạn), máy ấp (lồng kính, đèn sưởi), máy câu tự động (trống quay, phao nhấp nhô).
- `tools/SetupFreeModels.lua`: tìm hoặc tải model free, **xoá script ẩn**, chỉnh kích thước và pivot, bỏ vào `CustomModels`.

---

## #3 · 13/10/2026 · Map màn 1 + plot + shop + ấp trứng + máy câu (giai đoạn 0–6)
- Data v2 (tự chuyển dữ liệu v1, kèm `Data.Spend` trừ tiền), Plots, MapBuilder, Fishing, Hatchery (ấp offline), AutoFishers (offline, có giới hạn kho), Shop (4 cần câu), Market (bán NPC), Pets (đi theo).
- UI: HUD và các bảng Shop / Market / Hatch / Bag.
- **Tài liệu:** `MAP_LEVEL1.md`.

---

## #2 · 13/10/2026 · UI tiếng Anh + model và animation tạm
- Toàn bộ chữ trong game đổi sang tiếng Anh.
- `Models.lua`: `Models.Get(name)` ưu tiên `CustomModels`, không có thì dựng model tạm.
- `Effects.client.lua`: hoạt ảnh tween (vung cần, phao, rương bay lên mở nắp, trứng lắc nở pet).

---

## #1 · 13/10/2026 · Kết nối Rojo
- `rojo serve default.project.json` (port 34872). Studio: Plugins → Rojo → Connect.

---

## Mẫu cho mục mới (copy lên trên cùng)

```
## #N · dd/mm/yyyy · Tiêu đề ngắn
**Yêu cầu:** người dùng muốn gì
**Đã làm:** gạch đầu dòng, có số liệu cũ → mới nếu là cân bằng
**File:** các file đã sửa / tạo
**Đã kiểm tra:** chạy thử thế nào, kết quả
**Chưa xong / lưu ý:** việc còn lại, rủi ro
```
