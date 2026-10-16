# TASKS: Danh sách việc cần làm

> Claude tick `[x]` và ghi chú ngay sau mỗi việc xong. Chi tiết từng việc xem `docs/ProjectManagement/DEVLOG.md`. Cập nhật lần cuối: 15/10/2026.
> Thứ tự lấy từ `docs/Economy/ECONOMY_DESIGN.md` mục 11 và `docs/GameDesign/SYSTEM_DESIGN.md` mục 15.

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
