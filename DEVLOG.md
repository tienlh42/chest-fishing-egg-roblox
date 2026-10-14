# DEVLOG: Nhật ký thay đổi

> **Quy tắc:** làm xong mỗi việc (code, map, cân bằng...) thì **thêm 1 mục mới ở TRÊN CÙNG**, theo mẫu ở cuối file.
> Ai cũng đọc được: người mới, người làm chung, AI. Muốn biết dự án hiện có gì thì đọc `PROJECT_OVERVIEW.md`.
> "Claude" = AI Claude Code làm việc trong repo. "Phiên khác" = phần do người/AI khác làm song song (chỉ tóm tắt).

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
**Yêu cầu:** import các asset trong repo `assets-roblox` (thực tế là `C:\Robloxoblox-assets`) vào game, ghép đủ, mở rộng Config theo asset.

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
