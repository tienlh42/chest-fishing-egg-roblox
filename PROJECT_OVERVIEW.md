# Tổng quan dự án: Chest Fishing & Eggs ("Hồ Không Cho Câu")

> Đọc file này **đầu tiên** (người mới / AI mới). Cập nhật lần cuối: 15/10/2026 (#39). Việc cần làm: `TASKS.md`.
> Lịch sử thay đổi xem `DEVLOG.md`. Thiết kế game xem 2 file `GDD_*.md`.

---

## 1. Game là gì

Game Roblox kiểu **câu lén**: người chơi lẻn ra **hồ cấm** ở giữa công viên, **giữ nút** để kéo rương lên trong khi **ngỗng bảo vệ** đi tuần.
Rương kéo được nằm trong **túi tạm** (chưa an toàn). Phải chạy về **nhà gỗ** của mình, cất vào **Stash**, rương mới được mở (coins + trứng).
Trứng ấp thành **pet**. Pet đi theo và **chặn ngỗng**. Coins mua cần câu tốt hơn, máy câu tự động, thêm máy ấp.

**Vòng chơi:** ở nhà → lẻn ra hồ → giữ nút kéo (nhả để trốn ngỗng) → chạy về nhà cất đồ → mở rương, ấp trứng, nâng cấp → lặp lại.

**Trạng thái:** **MVP**. Mọi model, animation và map đều là **đồ tạm dựng bằng code**, sẽ thay bằng đồ thật sau (xem mục 7).

---

## 2. Công cụ & quy tắc làm việc

| Việc | Công cụ | Ghi chú |
|---|---|---|
| Code | **VS Code + Rojo** (`default.project.json`) | Sửa file `.lua`, Rojo đồng bộ vào Studio. **Không sửa script trong Studio** vì Rojo sẽ ghi đè. |
| Model, map, đọc Output, chơi thử | **Roblox Studio MCP** (`Roblox_Studio`) | `ReplicatedStorage > CustomModels` và `Workspace` không do Rojo quản lý nên sửa qua MCP an toàn. |
| Lint | `selene .` (cấu hình `selene.toml`, std = roblox) | Chạy trước khi báo xong. |

Quy tắc bắt buộc:
- **Chữ hiện cho người chơi: tiếng Anh.** Comment code và tài liệu viết tiếng Việt.
- **Server quyết định mọi kết quả.** Client chỉ gửi "nhấn / nhả / yêu cầu". Server luôn kiểm tra dữ liệu client gửi lên.
- Sửa profile xong phải gọi `Data.Update(player)` (cập nhật leaderstats + gửi `Sync` xuống client).
- **Làm xong mỗi việc thì ghi vào `DEVLOG.md`** và cập nhật tài liệu liên quan.
- **AI tự test và tự đưa code vào Studio** (Stop/Play, chạy Luau, giả lập bàn phím qua MCP). Kiểm tra code đã vào Studio bằng cách so `Source` với file repo (bỏ qua CRLF). Rojo mất kết nối thì chép file vào Studio qua MCP. Git push / publish lên Roblox vẫn phải hỏi người dùng.
- Chụp màn hình MCP có đặt vị trí camera khi đang **Play** sẽ khoá camera của người chơi. Chụp xong phải Stop rồi Play lại.

---

## 3. Cấu trúc thư mục

```
ReplicatedStorage/
  Config.lua            MỌI con số của game (rương, trứng, pet, giá, ngỗng, câu, dev mode...)
  Models.lua            Models.Get(name): lấy model thật trong CustomModels (tên game -> tên asset theo Config), không có thì dựng model tạm. Anchor / PlaceOnGround / SetAnim
ServerScriptService/
  Main.server.lua       Điểm khởi động DUY NHẤT của server: dựng map, nối module, Action, người chơi vào/ra
  Modules/
    Data.lua            Profile người chơi, DataStore (PlayerData_v2, tự chuyển v1), dev coins
    Remote.lua          Notify / Effect gửi xuống client
    MapBuilder.lua      Điều phối dựng map: Tool Shop, Market, Spawn, 8 nhà xếp elip quanh hồ
    ParkBuilder.lua     Terrain + hồ + lối gạch/lan can/đèn + công viên + đường vòng
    HouseBuilder.lua    1 plot = nhà gỗ (vào được) + Stash + ổ pet + kệ trưng bày + hàng rào + chuồng ấp + ao
    BuildUtil.lua       Hàm dựng Part dùng chung (block, wedge, tree, bench, lamp...)
    IncubatorBuilder.lua  Model máy ấp "Tổ Ấm" (hoạt ảnh: IncubatorAnimator.client.lua)
    ShopBuilder.lua     Quảng trường Tool Shop + Market sát nhau, người bán vịt / mèo
    Plots.lua           Cấp plot, dựng máy ấp/máy câu theo dữ liệu, nút [E], dịch chuyển về nhà
    Tutorial.lua        Hướng dẫn người mới 3 bước (profile.Tutorial), Reed Egg tặng trong Data.Load
    House.lua           Đồ chức năng trong nhà: ổ pet (hồi nhanh), kệ trưng bày pet, quà hằng ngày (đang tắt)
    Teleports.lua       Dịch chuyển bằng nút (đều tốn tiền): Lake 20, Tool Shop 10, My Plot 10 (chặn khi có đồ / bị đuổi)
    SafeZone.lua        Vùng an toàn (hộp quanh từng nhà + quanh Spawn)
    FishingSpots.lua    6 điểm câu trên hồ: rương ra ngẫu nhiên phía trước ngỗng (tối đa 3), 1 người/điểm, ngỗng quay lại đuổi nếu câu ngay sau khi nó đi ngang
    Fishing.lua         Câu giữ nút + câu lén (tạm dừng), điểm rơi phao do server tính, phát cần câu
    Bag.lua             Túi tạm 4 ô (chỉ tên rương), cất vào kho nhà (lưu xong mới tính), mất khi bị bắt/chết
    Loadout.lua         Gộp perk cần + pet thành 1 bảng chỉ số (Loadout.Get): Fishing, Guard đọc từ đây
    Robbery.lua         Cướp nhà: [F] Pick lock, chìa, lấy món có khóa theo plot, đồng hồ 60 giây trong sân người khác
    Stash.lua           Kho nhà: nút [E] Stash, mở rương (tung coins / trứng lúc mở), Action OpenChest / OpenAllChests
    Guard.lua           Ngỗng bảo vệ: Patrol / Suspicious / Chase / Search / Pause, pathfinding
    Pets.lua            Pet đi theo, HP pet, chặn ngỗng, hồi HP ở nhà
    NoSwim.lua          Cấm bơi: rơi xuống nước thì đưa về chỗ đứng vững gần nhất
    Hatchery.lua        Ấp trứng (os.time, nở cả khi offline)
    AutoFishers.lua     Máy câu tự động (tích rương cả khi offline)
    Shop.lua / Market.lua  Mua / bán
StarterGui/MainUI.client.lua                     Toàn bộ UI (HUD, thanh kéo, HP pet, túi, cảnh báo, các bảng)
StarterPlayer/StarterPlayerScripts/Effects.client.lua  Hoạt ảnh tạm (phao, rương, pet nở, lắc lư...)
StarterPlayer/StarterPlayerScripts/Sprint.client.lua   Giữ Shift chạy nhanh (khoá khi đang kéo câu)
tools/SetupFreeModels.lua   Script dán Command Bar: lấy model free -> làm sạch -> CustomModels
tools/prepare_assets.py     Chép model từ repo roblox-assets vào Assets/Models (tắt script bản mẫu, vá RodEffects)
Assets/Models/*.rbxmx       29 model asset (cần, pet, trứng, rương, máy câu, ngỗng); Rojo đồng bộ vào ReplicatedStorage/CustomModels
```

---

## 4. Giao tiếp client ↔ server (`ReplicatedStorage > Remotes`)

| Remote | Hướng | Dùng cho |
|---|---|---|
| `Cast` (RemoteEvent) | client → server | `"Down"` = nhấn giữ câu / kéo tiếp, `"Up"` = nhả (tạm dừng) |
| `Action` (RemoteFunction) | client → server, trả `(ok, message)` | `GetData`, `BuyRod`, `EquipRod`, `EquipPet(id)`, `BuyAutoFisher`, `OpenChest(tên, all)`, `OpenAllChests`, `BuyKey(n)`, `BuyLock`, `RobTake(ownerId, target, key)`, `BuyIncubator`, `StartHatch`, `SellEgg`, `SellPet(id)`, `BuyBagUpgrade`, `BuyGear`, `Teleport("Lake" | "Shop" | "Plot")` |
| `Sync` (RemoteEvent) | server → client | Gửi nguyên profile sau mỗi `Data.Update` |
| `Notify` (RemoteEvent) | server → client | Dòng thông báo (toast 3 giây) |
| `Effect` (RemoteEvent) | server → client | `CastStart`, `CastPause`, `CastResume`, `CastFail`, `Catch`, `Bag`, `Deposit`, `Alert` (ngỗng nghi ngờ/đuổi), `PetHP`, `PetDown`, `Hatched`, `Collect`, `OpenPanel` (client phát âm thanh theo các sự kiện này) |

---

## 5. Các hệ thống chính (tóm tắt luật)

**Câu (`Fishing.lua`, `Config.Fishing`)**
- Server tính điểm rơi phao 15 stud trước mặt, **phải trúng nước** mới được câu.
- **Độ bền cần:** mỗi rương kéo lên ở **hồ cấm** làm cần đang cầm mất 1 độ bền (`Config.Rods[].Durability`, lưu `profile.Rods[id]` = số còn lại). Hết bền thì cần **biến mất**, tự cầm lại Duckling (không bao giờ hỏng); không sửa được, mua lại giá gốc. Ao và lượt hụt không hao. Báo "sắp hỏng" khi còn 20%.
- Phao rơi vào hồ cấm (`Lake`) thì rương vào túi tạm. Rơi vào ao nhà (`Pond`) thì vào thẳng tài khoản (**chỉ ra rương Wooden**, kéo chậm gấp 5: `Config.Fishing.PondOdds`, `PondTimeMult`).
- **Giữ nút:** kéo, nhân vật đứng im, sau 3 giây kéo thì bắt đầu gây tiếng động gọi ngỗng (bán kính 45).
- **Nhả nút: tạm dừng**, giữ tiến độ, đi lại được, không gây tiếng động. Hụt khi đi xa quá 12 stud, dừng quá 40 giây, pet gục, cất cần, bị bắt.

**Điểm câu (`FishingSpots.lua`, `Config.Spots`):** có 6 điểm nhưng rương **không có sẵn**. Cứ 0.5 giây, điểm nằm phía **trước ngỗng** (cách 25-80 stud, trong góc ~60 độ) có 30% hiện phao **CHEST**, tối đa 3 rương cùng lúc; rương không ai câu biến mất sau 40 giây. Ném phao cách phao ≤ 7 stud mới móc được, mỗi phao 1 người; câu xong hoặc hụt thì phao biến mất và nghỉ 20 giây mới ra lại.

**Ngỗng quay lại (`Guard.Recall`, `Config.Guard.ReturnRange / ReturnGrace`):** ngỗng đi ngang điểm nào (trong 22 stud) thì điểm đó ghi lại thời điểm. Người chơi thả câu ở điểm đó trong 20 giây sau khi ngỗng vừa đi ngang, mà ngỗng còn trong 70 stud (chưa đi xa) thì ngỗng quay lại **đuổi luôn**, dù đang quay lưng. Chờ ngỗng đi xa quá 70 stud (hoặc quá 20 giây) mới câu thì an toàn hơn.

**Rương & trứng (`Config.Chests`, `Config.Eggs`, `Config.RollChestEgg`):** 5 loại rương (asset `TreasureChest_*`), mỗi rương ra tối đa 1 trứng, rương càng hiếm càng dễ ra trứng xịn. Mỗi trứng nở đúng 1 pet.

**Loại rương nào ra:** không còn Luck / Weight. Mỗi cần câu có bảng `Odds` (5 số ứng với 5 rương theo thứ tự trong `Config.Chests`, ví dụ Duckling `{ 88, 10, 1.8, 0.2, 0.02 }`), tung bằng `Config.RollChest(odds)`. Ao dùng `Config.Fishing.PondOdds`, máy câu dùng `Odds` của từng tier (`Config.AutoFisher.Tiers`, tối đa rương Purple).

| Rương | Không trứng | Trứng có thể ra (xác suất) |
|---|---|---|
| Wooden (60) | 70% | Reed 30% |
| Blue (25) | 40% | Reed 48%, Bubble 12% |
| Purple (10) | 11% | Reed 46%, Bubble 31%, Crystal 12% |
| Golden (4) | 0% | Bubble 55%, Crystal 30%, Gold 15% |
| Rainbow (1) | 0% | Crystal 57%, Gold 31%, Dragon 12% |

| Trứng (ấp) | Pet | HP | Giá bán trứng / pet |
|---|---|---|---|
| Reed (10s) | Baker Dog | 130 | 10 / 25 |
| Bubble (20s) | Muscle Duck | 220 | 40 / 80 |
| Crystal (40s) | Magician Cat | 170 | 120 / 250 |
| Gold (70s) | K9 Dog | 240 | 400 / 800 |
| Dragon (120s) | Office Dragon | 300 | 1500 / 3000 |

**Ngỗng (`Guard.lua`, `Config.Guard`)**
- Chỉ để ý người khả nghi: **đang kéo** (thấy trong 40 stud) hoặc **túi có đồ** (thấy trong 10 stud). Người đứng im thì bỏ qua.
- Thấy thì kêu "Honk?" trong 2 giây. Nếu lúc đó người chơi không còn khả nghi thì nó chỉ ra xem rồi đi. Còn khả nghi thì **đuổi** (21 stud/s).
- Pet chặn được khoảng 20 giây (5 HP/s). Pet gục rồi thì ngỗng bắt người: mất đồ trong túi, về thẳng nhà.
- Không vào vùng an toàn. Tuần tra theo 12 điểm `Config.Guard.Patrol` quanh lối gạch.

**Dịch chuyển (`Teleports.lua`, `Config.Teleport`):** chỉ bằng **nút bấm** trong dock bên phải màn hình (HOME / LAKE / SHOP), **đều tốn tiền**: **Lake (20)** đáp xuống `LakeArrival` gần nhà nhất; **Tool Shop (10)** đáp xuống `ShopArrival`; **My Plot (10)** về thảm Home. Tool Shop và My Plot bị chặn khi túi có đồ hoặc đang bị đuổi; Lake bị chặn khi đang bị đuổi. Cooldown 3 giây. Bị bắt, hồi sinh, mới vào game thì về nhà miễn phí.

**Túi & Stash (`Bag.lua`):** 4 món (nâng lên 5, rồi 6 ở **Tool Shop**: 300 / 1200 coins), không lưu DataStore. Túi chỉ giữ **tên rương** (chưa tung coins / trứng). Bấm [E] ở Stash (ngoài sân trước, cạnh lối đá gần cổng): rương trong túi chuyển vào **kho nhà** `profile.Chests = { [tên rương] = số lượng }` (không giới hạn ô) và **lưu**, lưu lỗi thì hoàn lại, đồ vẫn trong túi. Túi có đồ thì không được dịch chuyển về nhà.

**Cướp nhà (`Robbery.lua`, `Config.Robbery`):** người khác bấm [F] "Pick lock" ở Stash / máy câu của chủ nhà online, tiêu 1 Chìa vạn năng (mua ở Tool Shop, `profile.Keys`), mở 50% (giảm theo khóa cửa). Mở được thì chọn món (rương / trứng / rương của máy), giữ 3 giây (server đợi), món vào túi kẻ cướp. Lần thử đầu báo động chủ nhà; ở trong sân người khác quá 60 giây thì bị xử như bị bắt (tạm, chờ ngỗng nhà); bị bắt / chết / thoát game thì món cướp trả về kho chủ nhà; lấy được món đầu thì chủ nhà có khiên 10 phút. Vùng an toàn chỉ tính nhà của chính mình. **Ngỗng:** ngoài ngỗng hồ, mỗi nhà có chủ có 1 **ngỗng nhà** (đi vòng sân, chỉ rượt kẻ bị truy nã: đã thử khóa hoặc quá 60 giây trong sân), và báo động cướp gọi tối đa 3 **ngỗng đồn** đuổi kẻ cướp. **Khóa cửa** 3 cấp (Tool Shop, `BuyLock`) giảm tỉ lệ mở của chìa. **Perk** của cần / pet (`Config.Rods[].Perk`, `Config.Pet.Stats[].Perk`) áp qua `Loadout.lua`.

**Kho nhà & mở rương (`Stash.lua`, `Config.Stash`):** sau khi cất, bảng **Stash** hiện rương theo cấp với nút Open / Open all (Action `OpenChest(tên, all)`, `OpenAllChests`). Coins và trứng **tung lúc mở** (`Fishing.GiveChest`), phải đứng trong 40 stud quanh Stash của mình. Rương từ ao nhà và máy câu vẫn mở ngay vào tài khoản.

**Pet (`Pets.lua`, `Config.Pet.Stats`):** mỗi loại pet có HP riêng (bảng trên). Mỗi pet là **bản ghi riêng** `profile.Pets = { { Id, Name, Durability } }` (tạo bằng `Data.NewPet`), pet đi theo là `profile.EquippedPet` (Id); chọn pet trong **Bag** (bấm ô pet, Action `EquipPet`, không đổi được khi đang bị ngỗng đuổi). Nở pet đầu tiên khi chưa equip gì thì tự equip. Animation đổi theo việc đang làm (Idle / Walk / Run, Attack khi chặn ngỗng, Happy khi vừa hiện). HP chỉ tồn tại trong phiên chơi (mỗi pet giữ HP riêng), hồi đầy sau 40 giây khi đứng ở nhà, nhanh gấp 2.5 lần khi đứng cạnh **ổ pet**; chỉ pet đang equip mới hồi.

**Độ bền pet (`Config.Pet.DurabilityMult`):** độ bền tối đa = HP x 20 (`Config.PetDurability`). Mỗi 1 HP ngỗng đánh mất, pet mất 1 độ bền; hồi HP không hồi độ bền. Hết bền thì pet **biến mất**, không có pet đi theo (equip pet khác trong Bag); không sửa được. Bán pet (Market, `SellPet(id)`) được giá gốc x tỉ lệ độ bền còn lại (`Config.PetSellPrice`). Pet cũ lưu dạng tên được đổi thành bản ghi đầy bền trong `Data.lua` (`reconcile`), pet mới nhất của người cũ được equip.

**Nhà (`House.lua`, `Config.House`):** ổ pet (hồi nhanh), kệ trưng bày các loại pet đã có. Hộp thư quà hằng ngày (100 coins + 1 Reed Egg) **đang tắt**: `Daily.Enabled = false`, sẽ bật lại sau.

**Người mới:** chỉ có cần Duckling, 1 Reed Egg tặng (nở ra Baker Dog) và khung hướng dẫn 3 bước: ấp trứng → câu ở hồ → cất Stash (`Tutorial.lua`).

**Bag (bảng UI):** lưới 4 cột chia mục Eggs / Pets / Rods / Gear, mỗi ô có hình model 3D (ViewportFrame); món chưa có hiện bóng đen. **Thanh HP / độ bền** (`progressBar` trong `MainUI.client.lua`): ô pet có 2 thanh (xanh lá = HP, xanh dương = độ bền), ô cần có thanh độ bền, bấm ô pet / cần để equip. Shop (cần, máy), Market (pet) hiện thanh độ bền có số; HUD pet có thanh độ bền mỏng dưới thanh HP; bảng trên máy câu ngoài sân có thanh độ bền. Màu độ bền: xanh dương, cam dưới 50%, đỏ dưới 20% (`Config.DurabilityColor`). Chạy trong Studio (`Config.Dev.Enabled`) thì nhà chưa có chủ được bày đầy đồ (5 máy câu đầy kho, 4 máy ấp có trứng xịn) để test cướp nhà; cơ chế cướp chưa code.

**Âm thanh (`Config.Sounds`, `Effects.client.lua`):** ngỗng Honk / còi, tõm khi hụt, nhận rương, tiếng xu, trứng nở, pet yếu.

**Máy câu tự động (`AutoFishers.lua`, `Config.AutoFisher`):** **ổ** và **máy** tách nhau. 5 ổ (`PedestalPrices` 0 / 400 / 1200 / 3000 / 7000, mở một lần, `profile.FisherSlots`). Máy là món tiêu hao: **mua thẳng tier** vào ổ trống (Common 300, Rare 1000, Epic 3500, Legendary 10000, Mythic 30000; asset `AutoFisher_<Tier>`). Mỗi tier có `Interval` (180 / 160 / 140 / 120 / 100 giây ra 1 rương), `Capacity` (kho 10 / 11 / 13 / 15 / 18, đầy sau ~30 phút, tích cả offline), `Durability` (số rương làm ra được: 120 / 200 / 450 / 1000 / 2500) và `Odds` (chỉ ra tới rương Purple). Dữ liệu: `profile.AutoFishers[ổ] = { Tier, Durability, Last, Stored }`. Bấm [E] ở máy để mở hết rương; độ bền trừ đúng số rương thu, hết thì máy biến mất (ổ còn lại), còn 20% thì báo. **Nâng tier tại chỗ** (Action `UpgradeAutoFisher`) = trả chênh lệch giá, giữ kho đã tích, độ bền về đầy (cách duy nhất để "sửa"). Máy sắp hỏng (độ bền < kho) chỉ tích tối đa bằng độ bền còn lại. Mua / mở ổ / nâng **ở nhà** (nút [E] trên bệ, [G] trên máy: bảng Build; Action `BuyFisherSlot`, `BuyAutoFisher(tierIndex, slot)`, `UpgradeAutoFisher(slot)`, phải đứng trong sân nhà mình `Plots.IsHome`). Tool Shop chỉ bán đồ (cần, túi, chìa, giày).

**Kinh tế:** 6 cần câu (asset `Rod_*`: Duckling 0, Catfish 150, Turtle 500, Fox 1800, Lucky Cat 6000, Rainbow Dragon 18000; `Odds` và `Speed` trong `Config.Rods`), **Dép Tên Lửa** (2000 coins, +10% tốc độ, `Config.Gear`), **máy câu tự động** (xem mục dưới: 5 ổ + 5 tier, mua thẳng tier, có độ bền), máy ấp (tối đa 4), bán trứng và pet. **Dev mode:** chạy trong Studio có 1 tỷ coins (`Config.Dev`).

---

## 6. Bản đồ (chi tiết: `MAP_LEVEL1.md`, `PARK_REDESIGN.md`)

- **Hồ ở chính giữa** (tâm = gốc toạ độ, 130x90 bo góc, Terrain Water), có lối gạch, lan can và đèn quanh hồ. Công viên x -110..110, z -80..80.
- Đường vòng bán kính 150. **8 nhà gỗ xếp elip** (Rx 228, Rz 212), nên nhà nào cũng cách lối gạch quanh hồ khoảng 130 stud.
- Tool Shop ở góc 225°, Market ở góc 45°. Không có sảnh chính. Hồi sinh và bị bắt đều về nhà.
- Bẫy kỹ thuật Terrain: fill `Air` trước `Water`; mặt đất hiện cao hơn vùng fill 2 stud (đã bù `TERRAIN_SHIFT`); dùng `LeafyGrass` để cỏ thấp.

---

## 7. Đồ tạm cần thay sau (MVP)

| Thứ | Cách thay |
|---|---|
| Model (phao, máy ấp, NPC còn tạm) | Cần, rương, trứng, pet, máy câu, ngỗng đã dùng asset từ `Assets/Models`. Cái còn lại: đặt model đúng tên vào `ReplicatedStorage > CustomModels` (bảng tên trong `HUONG_DAN.md`). |
| Animation nhân vật | Điền ID vào `Config.Animations` |
| Map | Copy `Workspace > Map` vào place rồi trang trí (giữ đúng tên Part, xem `MAP_LEVEL1.md` mục 3). Terrain vẽ bằng Terrain Editor. |
| UI | Dựng bằng code trong `MainUI.client.lua`, theme "Sunny Park + Egg Pop" (nút Fish tròn góc dưới phải, dock icon bên phải, cột Coins/Bag góc trên trái) |

---

## 8. Tài liệu khác

| File | Nội dung |
|---|---|
| `DEVLOG.md` | **Nhật ký thay đổi** theo thời gian (mới nhất ở trên) |
| `SYSTEM_DESIGN.md` | **Thiết kế đích:** độ hiếm 5 cấp, kho rương và mở rương ở nhà, ngỗng nhà + đồn cảnh sát, cướp nhà. Có nhãn phần nào đã code, phần nào mới chốt thiết kế |
| `ECONOMY_DESIGN.md` | **Thiết kế kinh tế farm:** tiền từ câu hồ / ao / máy câu / cướp nhà, bảng tỉ lệ rương theo cần, máy câu 5 tier, **độ bền cần / máy / pet**, **Chìa vạn năng + khóa cửa**, perk cần và pet, giá, tiến độ. Số liệu chạy từ `tools/sim_economy.py`. **Chưa code**, Config hiện tại vẫn là số cũ |
| `HUONG_DAN.md` | Hướng dẫn cho người mới: cài đặt, chạy thử, thay model |
| `MAP_LEVEL1.md` | Bố cục map, quy ước tên Part, cách chuyển sang map thật |
| `PARK_REDESIGN.md` | Thiết kế công viên + nhà gỗ, ghi chú Terrain, bảng cân bằng |
| `BUGFIX_PLAN.md` | Đợt sửa lỗi 1 (ngỗng rơi hồ, câu trên bờ, toast, đứng im khi câu) |
| `GDD_Ho_Khong_Cho_Cau_v2.md` / `_One_Page.md` | Thiết kế game gốc |
| `CLAUDE.md` | Hướng dẫn ngắn cho AI làm việc trong repo |
