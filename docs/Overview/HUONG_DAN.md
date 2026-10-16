# Game "Câu Rương & Ấp Trứng" – Hướng dẫn cho người mới

## Ý tưởng game (vòng lặp cốt lõi)
```
Câu rương  ->  nhận xu + trứng  ->  ấp trứng (chờ giờ)  ->  nở pet  ->  (sau này) pet tăng xu/may mắn
```
Làm nhỏ trước, chạy được rồi mới thêm. Đừng làm tất cả cùng lúc.

---

## Bước 0: Cài đặt (10 phút)
1. Tạo tài khoản Roblox, tải **Roblox Studio** tại create.roblox.com.
2. Đăng nhập Studio -> **New** -> template **Baseplate**.
3. **File > Save to File** -> lưu vào `C:\Roblox\ChestFishingEggGame\Game.rbxl`.
4. Bật các cửa sổ cần thiết: tab **View** -> bấm **Explorer** và **Properties**.
5. Bật lưu dữ liệu khi test: **File > Game Settings > Security** -> bật **Enable Studio Access to API Services**.

## Bước 1: Làm quen Studio (15 phút)
- Chuột phải kéo = xoay camera, `W A S D` = di chuyển camera, `Q/E` lên xuống.
- Tab **Home**: công cụ **Move / Scale / Rotate** (phím `Ctrl+2/3/4`).
- Tab **Model**: **Part** (tạo khối). Thử tạo 1 Part, đổi màu/kích thước trong **Properties**.
- Nhấn **F5** (Play) để chơi thử, **Shift+F5** để dừng.
- Hiểu **Explorer**: cây thư mục của game. Quan trọng nhất:
  - `Workspace`: những thứ nhìn thấy trong thế giới 3D
  - `ReplicatedStorage`: dữ liệu/Module dùng chung server + client
  - `ServerScriptService`: script chạy trên server (an toàn, người chơi không sửa được)
  - `StarterGui`: giao diện của người chơi

## Bước 2: Map
Map màn 1 (công viên hồ ở giữa, 8 nhà gỗ xếp vòng quanh, Tool Shop, Market) được code **tự dựng** khi bấm Play.
Xem bố cục, quy ước tên và cách thay bằng map thật trong **`docs/World/MAP_LEVEL1.md`**.

## Bước 3: Đồng bộ code bằng Rojo
Code nằm trong thư mục này và được Rojo đồng bộ vào Studio (không cần copy tay):
1. Chạy `rojo serve` trong thư mục dự án.
2. Studio -> tab **Plugins** -> **Rojo** -> **Connect** -> **Accept**.

### Lệnh terminal hay dùng
Chạy trong thư mục dự án (`C:\Roblox\ChestFishingEggGame`), công cụ cài bằng Rokit (`rojo` 7.7.1, `selene` 0.32.0):

| Lệnh | Việc |
|---|---|
| `rojo serve` | Mở server đồng bộ code vào Studio (rồi Studio > Plugins > Rojo > **Connect**). Để cửa sổ này chạy suốt, sửa file `.lua` là Studio cập nhật |
| `selene .` | Kiểm tra lỗi / cảnh báo toàn bộ code Luau (phải ra `0 errors, 0 warnings` trước khi báo xong) |
| `rojo build -o build.rbxl` | Đóng gói thành file place để mở thử (không cần Studio đang chạy) |
| `rojo sourcemap default.project.json -o sourcemap.json` | Cập nhật `sourcemap.json` cho VS Code gợi ý code |
| `python tools/sim_economy.py` | Mô phỏng kinh tế (thu nhập, tiến độ, lời cướp nhà), xem `docs/Economy/ECONOMY_DESIGN.md` |
| `python tools/prepare_assets.py` | Chép model từ repo `roblox-assets` vào `Assets/Models` |

**Chạy thử 2 người chơi (để test cướp nhà):** trong Studio, tab **Test** > **Clients and Servers** > đặt **Players = 2** > **Start**. Người A làm xong hướng dẫn trước (nhà người đang hướng dẫn không bị cướp). Người B đứng trong sân nhà A, bấm **F** ở Stash hoặc máy câu.

## Bước 4: Chạy thử
1. Nhấn **F5**. Bạn xuất hiện trước nhà mình (thảm đỏ trước hiên).
2. Chạy ra hồ ở giữa map (giữ **Shift** để chạy) -> đứng trên lối gạch, quay mặt ra hồ -> **GIỮ** nút **Fish** tròn to ở góc dưới phải (hoặc phím **F**).
   Nhả nút = tạm dừng (giữ tiến độ). Thanh đầy -> rương vào **túi tạm** (Bag x/4).
3. Coi chừng **ngỗng bảo vệ**: nó kêu "Honk?" thì nhả nút ngay. Bị đuổi thì chạy về nhà. Bị bắt = mất đồ trong túi, về nhà.
4. Về nhà -> bấm **E** ở rương **Stash** trước nhà: rương trong túi chuyển vào kho nhà, bảng **Stash** hiện ra để **Open** rương (ra coins / trứng). Đang có đồ trong túi thì không bấm **My Plot** được.
5. Ấp trứng: chuồng ấp sau nhà -> **E** ở máy ấp -> chọn trứng -> đợi -> **E** nhận pet.
6. **Tool Shop** / **Market** nằm giữa các nhà trên đường vòng: mua cần câu, máy câu tự động, máy ấp / bán trứng, pet.
7. Máy câu tự động ở ao sau nhà tích rương cả khi offline; đến máy bấm **E** để mở.
8. Xem lỗi ở **View > Output** (chữ đỏ = lỗi, đọc dòng đầu tiên).

## Bước 5: Hiểu code (đọc theo thứ tự)
> Danh sách đầy đủ và mới nhất các module (Bag, Guard, SafeZone, ParkBuilder, HouseBuilder...) xem **`docs/Overview/PROJECT_OVERVIEW.md`**. Lịch sử thay đổi xem **`docs/ProjectManagement/DEVLOG.md`**.

| File | Vai trò |
|---|---|
| `ReplicatedStorage/Config.lua` | **Mọi con số**: rương, trứng, pet, giá cần câu, máy câu, máy ấp, giá bán |
| `ReplicatedStorage/Models.lua` | Model tạm + lấy model thật từ `CustomModels` |
| `ServerScriptService/Main.server.lua` | Điểm khởi động server, nối các module, nhận yêu cầu từ client |
| `Modules/Data.lua` | Dữ liệu người chơi, lưu/tải DataStore |
| `Modules/MapBuilder.lua` | Dựng map tạm |
| `Modules/Plots.lua` | Cấp plot, dựng máy ấp/máy câu trên plot, dịch chuyển |
| `Modules/Fishing.lua` | Câu tay, phát cần câu |
| `Modules/Hatchery.lua` | Ấp trứng / nhận pet |
| `Modules/AutoFishers.lua` | Máy câu tự động |
| `Modules/Shop.lua`, `Modules/Market.lua` | Mua / bán |
| `Modules/Pets.lua` | Pet bay theo người chơi |
| `StarterGui/MainUI.client.lua` | Giao diện |
| `StarterPlayer/StarterPlayerScripts/Effects.client.lua` | Hoạt ảnh |

Khái niệm cần nhớ:
- **Server vs Client**: Server = máy chủ quyết định. Client = máy người chơi, không được tin. Mọi giao dịch đều được server kiểm tra.
- **RemoteEvent / RemoteFunction**: "đường dây" giữa client và server. `Action` là RemoteFunction: client hỏi, server trả lời (ok, thông báo).
- **ModuleScript**: file dùng chung, gọi bằng `require`.

---

## Lộ trình mở rộng
Đã xong: cần câu + hoạt ảnh, rương nổi lên, pet theo người, cửa hàng cần câu, nhiều slot ấp + ấp offline, map màn 1, máy câu tự động, chợ bán.
Tiếp theo:
1. **Pet có tác dụng**: mỗi pet cộng % xu hoặc may mắn (đọc từ `Config`).
2. **UI đẹp**: tự vẽ ScreenGui trong Studio.
3. **Âm thanh & hiệu ứng** (Sound, ParticleEmitter).
4. **Monetization**: Game Pass (x2 xu, thêm slot ấp), Developer Product.
5. **Publish**: **File > Publish to Roblox**, test với bạn bè, thu thập phản hồi.

## Thay model & animation tạm bằng đồ thật
Hiện tại game dùng **model tạm** dựng bằng Part (`ReplicatedStorage/Models.lua`) và **hoạt ảnh tạm** bằng tween (`StarterPlayer/StarterPlayerScripts/Effects.client.lua`).

**Model asset (đã ghép sẵn):** 29 model từ repo `roblox-assets` (cần, pet, trứng, rương, máy câu, ngỗng) nằm ở `Assets/Models/*.rbxmx`, Rojo đồng bộ vào `ReplicatedStorage > CustomModels`. Tên game -> tên asset khai trong trường `Model` của `Config.lua`:

| Trong game | Asset (`Assets/Models`) |
|---|---|
| Cần: Duckling / Catfish / Turtle / Fox / Lucky Cat / Rainbow Dragon | `Rod_Starter`, `Rod_Catfish`, `Rod_Turtle`, `Rod_Fox`, `Rod_Cat`, `Rod_Dragon` |
| Rương: Wooden / Blue / Purple / Golden / Rainbow | `TreasureChest_Common` ... `TreasureChest_Mythic` |
| Trứng: Reed / Bubble / Crystal / Gold / Dragon | `Egg_Reed` ... `Egg_Dragon` |
| Pet: Baker Dog / Muscle Duck / Magician Cat / K9 Dog / Office Dragon | `Pet_DogBaker`, `Pet_DuckMuscle`, `Pet_CatMagician`, `Pet_DogK9`, `Pet_DragonOffice` |
| Máy câu thứ 1..5 | `AutoFisher_Common` ... `AutoFisher_Mythic` |
| Ngỗng bảo vệ | `PoliceGoose` |

Cập nhật asset khi repo `roblox-assets` có bản mới: `python tools/prepare_assets.py [đường dẫn repo]` (chép + tắt script bản mẫu + vá `RodEffects`). Asset là Model rig Motor6D, animation đổi bằng attribute `Anim` (`Models.SetAnim`); sound của asset chưa có ID (cần upload `.wav`, điền vào bảng đầu script `*Sounds`).

**Thay model khác:** trong Studio, kéo model của bạn vào `ReplicatedStorage > CustomModels` và đặt **đúng tên** (hoặc tên khai ở trường `Model` trong Config):

| Tên | Là gì | Ghi chú |
|---|---|---|
| Tên trong `Config.Rods` | Cần câu | **Tool** có Part `Handle` (thêm Attachment `Tip` để buộc dây), hoặc Model rig có `HumanoidRootPart` + `Tip` (game tự bọc thành Tool) |
| `Bobber` | Phao | Model, đặt PrimaryPart |
| Tên trong `Config.Chests` | Rương | Part tên `Lid` sẽ tự mở nắp (model tạm) |
| `<Tier> Egg` (khoá trong `Config.Eggs`) | Trứng | |
| Tên trong `Config.Pet.Stats` | Pet | Mặt trước quay về hướng -Z |
| `Incubator` | Máy ấp | Pivot ở đáy; Attachment `EggPoint` = chỗ đặt trứng |
| `AutoFisher_<Tier>` | Máy câu tự động | Pivot ở đáy; mặt trước (-Z) quay ra nước |
| `Shopkeeper`, `Merchant` | NPC ở Tool Shop / Market | Pivot ở đáy |

Có model thật thì game dùng ngay, không cần sửa code. Rojo sẽ không xoá những gì bạn bỏ vào `CustomModels`.

### Tự động lấy model free (cho MVP)
1. Mở file `tools/SetupFreeModels.lua`, copy **toàn bộ**.
2. Studio -> **View > Command Bar** -> dán -> **Enter**. Xem kết quả trong **Output**.
3. Script tự tìm model free trên Marketplace theo từ khoá, tải về, **xoá mọi script ẩn** (model free hay chứa virus), chỉnh kích thước/pivot, biến cần câu thành Tool có `Handle` + `Tip`, rồi bỏ vào `ReplicatedStorage > CustomModels` đúng tên.
4. Bấm **Play** xem thử, ưng thì **File > Save**. Ctrl+Z để hoàn tác.

Không ưng 1 model:
- Đổi `Pick` (lấy kết quả tìm kiếm thứ mấy) hoặc `Search` trong bảng `MODELS` ở đầu script, hoặc
- Tìm trong **Toolbox**, chuột phải model -> **Copy Asset ID** -> dán vào `Id`,
- Xoá model đó trong `CustomModels` rồi chạy lại script (model đã có sẽ được giữ nguyên).

Tự kéo model từ Toolbox vào `CustomModels` (đặt đúng tên) rồi chạy script cũng được: nó sẽ làm sạch model đó.
Mỗi model tải về có attribute `SourceAssetId` để biết nguồn, sau này thay bằng model thật.

⚠️ Nếu Output báo "Search failed" (Roblox đôi khi chặn tìm kiếm từ script): điền `Id` bằng tay như trên.

**Thay animation nhân vật:** làm animation bằng Animation Editor -> Publish -> dán ID vào `Config.Animations` (`Cast`, `Reel`).

**Thay map:** xem `docs/World/MAP_LEVEL1.md`.

## Lỗi hay gặp
| Triệu chứng | Nguyên nhân |
|---|---|
| `Infinite yield possible on WaitForChild("Remotes")` | Rojo chưa kết nối (bấm Connect trong plugin) |
| Không thấy map / plot | Xem Output; nếu `Workspace` có sẵn Folder `Map` thì code dùng map đó thay vì dựng map tạm |
| Nút bấm không phản hồi | `MainUI` phải là **LocalScript**, nằm trong **StarterGui** |
| `attempt to index nil` | Sai tên Script/Module (hoa thường) |
| Không lưu được dữ liệu | Chưa bật **Studio Access to API Services** |
| Script không chạy | Script server phải ở `ServerScriptService`, không phải `StarterGui` |

## Tài liệu học thêm
- create.roblox.com/docs (có tiếng Anh, rất đầy đủ; mục *Education > Get started*)
- Kênh YouTube: AlvinBlox, TheDevKing (có phụ đề, dễ theo dõi)
- DevForum: devforum.roblox.com để hỏi khi bị kẹt
- Ngôn ngữ dùng là **Luau** (giống Lua, dễ học)
