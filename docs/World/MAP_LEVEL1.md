# Map màn 1: Thiết kế & cách thay bằng build thật

Map hiện tại do code **tự dựng bằng Part tạm** (`ServerScriptService/Modules/MapBuilder.lua`) khi bấm Play.
Code chỉ dựa vào **tên** của các Part/Model, nên sau này bạn tự build map thật trong Studio, đặt đúng tên là game chạy y nguyên.

---

## 1. Bố cục tổng thể (nhìn từ trên xuống, phía trên = hướng -Z)

Hồ ở **chính giữa** (tâm = gốc toạ độ), **8 nhà xếp vòng quanh** theo hình elip khớp dáng hồ, nên nhà nào ra hồ cũng xa như nhau (~130 stud).
**Không có sảnh chính**: hồi sinh / bị ngỗng bắt đều về thẳng nhà mình.

```
                 Plot6        Plot7
        Plot5   ╭──── đường vòng (R=150) ────╮   Plot8
       (ToolShop)│  ┌─── công viên ───────┐  │
                 │  │   ┌── HỒ 130x90 ──┐  │  │
        Plot4  ──┼──┼── │    (0,0,0)    │ ─┼──┼──  Plot1
                 │  │   └───────────────┘  │  │
                 │  └──────────────────────┘  │   (Market)
        Plot3   ╰────────────────────────────╯   Plot2
```

| Khu | Vị trí | Ghi chú |
|---|---|---|
| Công viên hồ (Lake Park) | hồ tâm (0,0,0) 130x90 bo góc; công viên x -110..110, z -80..80 | Hồ cấm câu (ngỗng tuần tra). Lối gạch + lan can + đèn quanh hồ (câu từ lối gạch qua lan can), 4 lối ra, 2 quảng trường, nhà bảo vệ. Chi tiết: `docs/World/PARK_REDESIGN.md` |
| Đường vòng | bán kính 150, rộng 10 | Có lối gạch vào từng nhà và 2 cửa hàng |
| 8 Plot (nhà gỗ) | elip Rx = 228, Rz = 212 (`PLOT_RX/RZ` trong `MapBuilder.lua`), góc 22.5° + k·45° | Cổng quay về phía hồ. Là vùng an toàn |
| Tool Shop | góc 225°, cách tâm 192 | Có điểm hồi sinh `Spawn` phía trước (chỉ dùng lúc mới vào, sau đó về nhà) |
| Market | góc 45°, cách tâm 192 | Bán trứng, pet |

### Nền đất và hồ (Terrain)
- Cả map nằm trên **Terrain** cỏ LeafyGrass (mặt đất y = 0) do code tạo (`ParkBuilder.lua`). **Baseplate bị xoá khi chạy game** (nếu không nó cắt ngang lòng hồ).
- Hồ hình chữ nhật bo góc (`HX, HZ, R` trong `ParkBuilder.lua`), sâu 8 stud, đáy cát. Màu/sóng nước chỉnh ở `terrain.Water*` trong `buildTerrain()`.
- Câu cá dựa vào Part vô hình tên `Water` phủ vùng hồ (Terrain không có tên để code tìm).
- Lưu ý kỹ thuật: xem mục 7 của `docs/World/PARK_REDESIGN.md` (fill Air trước Water, lệch 2 stud của Terrain, LeafyGrass).

## 2. Bên trong 1 Plot = lô nhà gỗ (90 x 90)

Cổng quay về phía đường (hướng -Z của Model plot). Code: `ServerScriptService/Modules/HouseBuilder.lua`.

```
            (phía sau plot, +Z)
 ┌──────────────────────────────────────────────┐
 │  CHUỒNG ẤP TRỨNG (gỗ)     │  AO VƯỜN (nước thật) │
 │  [Inc3]   [Inc4]          │                      │
 │  [Inc1]   [Inc2]          │ [F1][F2][F3][F4]     │  <- ô máy câu, quay mặt ra ao
 │          ┌──────────────┐                        │
 │          │  NHÀ GỖ 32x24│ (vào được: giường, bàn,│
 │          │  24 x 18     │  kệ sách, lò sưởi)     │
 │          └───[hiên]─────┘                        │
 │ cây [STASH]  [Home]=thảm      cây   hộp thư=Sign  │
 └──────────────┤ cổng rào trắng ├────────────────┘
            (phía trước, -Z, ra đường)
```

- **Nhà gỗ**: vào được qua cửa trước, có nội thất. Mái gỗ giống nhau mọi nhà.
- **Chuồng ấp trứng**: tối đa 4 máy ấp, ban đầu mở 1, mua thêm ở Tool Shop.
- **Ao vườn**: 4 ô máy câu tự động + câu tay an toàn (rương vào thẳng tài khoản).
- **Home**: tấm thảm trước hiên – hồi sinh / bấm **My Plot** sẽ về đây.
- **Hộp thư** (Part `Sign`): hiện tên chủ nhà.

## 3. Quy ước tên (QUAN TRỌNG khi tự build)

Toàn bộ map nằm trong `Workspace > Map` (Folder). **Nếu `Workspace` đã có `Map` thì code KHÔNG dựng map tạm nữa** mà dùng map của bạn.

| Đường dẫn / Tên | Loại | Bắt buộc | Ghi chú |
|---|---|---|---|
| `Map > ... > Spawn` | SpawnLocation | Có | Điểm xuất hiện lúc mới vào game (sau đó server đưa về nhà). Có vùng an toàn 60x60 quanh nó |
| `Map > ... > Water` | Part (bao nhiêu cũng được) | Có | Mọi Part tên `Water` = nơi được phép câu (đứng trong vòng 25 stud) |
| `Map > ToolShop > ... > PromptPart` | Part | Có | Chỗ hiện nút "[E] Shop" |
| `Map > Market > ... > PromptPart` | Part | Có | Chỗ hiện nút "[E] Sell" |
| `Map > Plots > Plot1` ... `Plot8` | Model | Có | Số trong tên = thứ tự cấp plot |
| `Plot > ... > Home` | Part | Có | Điểm dịch chuyển về plot; hướng -Z của Part = hướng nhân vật nhìn |
| `Plot > ... > Sign` | Part | Nên có | Hiện tên chủ plot |
| `Plot > ... > Stash` | Model/Part | Có | Rương cất đồ ngoài sân trước, cạnh lối đá (code gắn nút [E] cho chủ nhà) |
| `Plot > ... > PetBed` | Part | Nên có | Ổ pet: chủ đứng gần thì pet hồi HP nhanh hơn |
| `Map > ... > ShopArrival` | Part vô hình | Nên có | Điểm đáp khi bấm nút **Tool Shop** |
| `Plot > ... > TrophyShelf` + `TrophySlot1..6` | Part | Nên có | Kệ trưng bày pet; mỗi TrophySlot là chỗ đặt 1 pet (-Z quay ra phía người xem) |
| `Map > ... > FishingSpot` | Part vô hình (≥1) | Có | Điểm câu trên hồ cấm (code dựng phao CHEST). Không có thì không câu được ở hồ |
| `Map > ... > LakeArrival` | Part vô hình (≥1) | Có | Điểm đáp khi bấm nút **Lake** (chọn điểm gần nhà người chơi nhất) |
| `Plot > ... > IncubatorSlot1..4` | Part | Có | Bệ đặt máy ấp (máy ấp đặt lên mặt trên) |
| `Plot > ... > FisherSlot1..4` | Part | Có | Bệ đặt máy câu; **hướng -Z của Part phải quay ra mặt nước** |
| `Plot > ... > Water` | Part | Nên có | Ao riêng |

Ghi chú:
- "`...`" nghĩa là có thể nằm sâu bên trong Model/Folder con, code tìm theo tên.
- Code sẽ tự tạo thêm folder `Dynamic` trong mỗi plot để chứa máy ấp, máy câu, trứng. Đừng đặt gì vào đó.
- Các SpawnLocation nằm ngoài `Map` sẽ bị tắt khi chạy game.

## 4. Cách chuyển sang map thật (khuyên làm)

1. Bấm **Play** (F5). Map tạm được dựng trong `Workspace > Map`.
2. Trong Explorer, chuột phải `Map` -> **Copy**.
3. Bấm **Stop**, chuột phải `Workspace` -> **Paste Into**. Giờ map tạm đã nằm hẳn trong place.
4. **File > Save**. Từ đây code sẽ dùng map này, bạn tự do trang trí: thay Part bằng model đẹp, thêm cây, đá, ánh sáng...
   Chỉ cần **giữ đúng tên** các mục ở bảng trên.
5. Muốn dùng lại map tạm: xoá `Workspace > Map`.

⚠️ Terrain (hồ, đất, cát) **không nằm trong folder `Map`** nên copy `Map` sẽ không mang theo terrain. Khi tự build map: dùng **Terrain Editor** (tab Home > Editor) để vẽ hồ/đất, nhớ giữ Part vô hình tên `Water` phủ vùng được câu.

Model đặt lên map (máy ấp, máy câu, NPC, rương, pet...) thay ở `ReplicatedStorage > CustomModels`, xem `docs/Overview/HUONG_DAN.md`.

## 5. Checklist giai đoạn tạo map

- [x] Map tạm: công viên hồ ở giữa, Tool Shop, Market, 8 nhà gỗ xếp vòng quanh (bỏ Plaza + cầu tàu)
- [x] Mỗi plot có Hatchery (4 bệ), ao + 4 ô máy câu, Home, biển tên
- [x] Cấp plot khi người chơi vào, dọn plot khi rời
- [x] Nút **My Plot** để về nhà (bị chặn khi túi có đồ / đang bị đuổi)
- [x] Chỉ câu được khi đứng gần nước
- [ ] *(Bạn)* Copy map tạm vào place và trang trí
- [ ] *(Bạn)* Thay model thật vào `CustomModels`
- [ ] *(Bạn)* Chỉnh **Game Settings > Places > Max Players = 8** (bằng số plot)
- [ ] *(Sau)* Thêm Lighting, âm thanh nền, hiệu ứng nước
