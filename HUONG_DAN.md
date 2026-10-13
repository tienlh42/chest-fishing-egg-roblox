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
Map màn 1 (Plaza, Tool Shop, Market, hồ chung, 8 plot riêng) được code **tự dựng** khi bấm Play.
Xem bố cục, quy ước tên và cách thay bằng map thật trong **`MAP_LEVEL1.md`**.

## Bước 3: Đồng bộ code bằng Rojo
Code nằm trong thư mục này và được Rojo đồng bộ vào Studio (không cần copy tay):
1. Chạy `rojo serve` trong thư mục dự án.
2. Studio -> tab **Plugins** -> **Rojo** -> **Connect** -> **Accept**.

## Bước 4: Chạy thử
1. Nhấn **F5**. Bạn xuất hiện ở plot của mình.
2. Bấm **Plaza** -> đi theo cầu tàu ra hồ -> bấm **Cast** (hoặc cầm cần và click) -> nhận rương.
3. Về plot (**My Plot**) -> đến máy ấp trong Hatchery -> bấm **E** -> chọn trứng -> đợi -> **E** để nhận pet.
4. **Tool Shop** (trái Plaza): mua cần câu, máy câu tự động, thêm máy ấp. **Market** (phải Plaza): bán trứng, pet.
5. Máy câu tự động trên plot tích rương cả khi offline; đến máy bấm **E** để mở.
6. Xem lỗi ở **View > Output** (chữ đỏ = lỗi, đọc dòng đầu tiên).

## Bước 5: Hiểu code (đọc theo thứ tự)
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

**Thay model:** trong Studio, kéo model của bạn vào `ReplicatedStorage > CustomModels` và đặt **đúng tên**:

| Tên | Là gì | Ghi chú |
|---|---|---|
| `Basic Rod`, `Sturdy Rod`, `Pro Rod`, `Legend Rod` | Cần câu | Phải là **Tool** có Part `Handle`; thêm Attachment `Tip` ở đầu cần để buộc dây |
| `Bobber` | Phao | Model, đặt PrimaryPart |
| `Wooden Chest`, `Golden Chest`, `Diamond Chest` | Rương | Part tên `Lid` sẽ tự mở nắp |
| `Common Egg`, `Rare Egg` | Trứng | |
| `Cat`, `Dog`, `Fox`, `Dragon`, `Phoenix` | Pet | Mặt trước quay về hướng -Z |
| `Incubator` | Máy ấp | Pivot ở đáy; Attachment `EggPoint` = chỗ đặt trứng |
| `AutoFisher` | Máy câu tự động | Pivot ở đáy; mặt trước (-Z) quay ra nước |
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

**Thay map:** xem `MAP_LEVEL1.md`.

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
