# Map màn 1: Thiết kế & cách thay bằng build thật

Map hiện tại do code **tự dựng bằng Part tạm** (`ServerScriptService/Modules/MapBuilder.lua`) khi bấm Play.
Code chỉ dựa vào **tên** của các Part/Model, nên sau này bạn tự build map thật trong Studio, đặt đúng tên là game chạy y nguyên.

---

## 1. Bố cục tổng thể (nhìn từ trên xuống, phía trên = hướng -Z)

```
 x=-180                                                   x=+180
 [Plot1] z=-150      [Tool Shop]          [Market]      [Plot5] z=-150
 [Plot2] z=-50     (-73,-28)   [Plaza]   (73,-28)       [Plot6] z=-50
   ‖ đường dọc ════ đường ngang ══ (0,0) ══ đường ngang ════ ‖
 [Plot3] z=+50                    ║ Dock                [Plot7] z=+50
 [Plot4] z=+150             [ Hồ chung ]                [Plot8] z=+150
                             (0, 95) 100x70
```

| Khu | Vị trí tâm | Kích thước | Chức năng |
|---|---|---|---|
| Plaza (quảng trường) | (0, 0, 0) | 50 x 50 | Điểm hồi sinh chung, đài phun nước |
| Tool Shop | (-73.5, 0, -28) | 30 x 24 | Mua/chọn cần câu, mua máy câu tự động, mua thêm máy ấp |
| Market | (73.5, 0, -28) | 30 x 24 | Bán trứng và pet cho NPC |
| Hồ chung + Dock | (0, 0, 95) | 100 x 70 | Câu tay (đứng trên cầu tàu) |
| 8 Plot | x = ±180, z = -150 / -50 / 50 / 150 | 90 x 90 | Mảnh đất riêng của từng người chơi |

Đường đi: đường ngang z = 0 nối Plaza với 2 cột plot, 2 đường dọc x = ±128 chạy dọc cổng các plot.

## 2. Bên trong 1 Plot (90 x 90)

Cổng plot quay về phía đường (hướng -Z của Model plot).

```
            (phía sau plot, +Z)
 ┌─────────────────────────────────────────┐
 │  HATCHERY (mái che)   │  Ao riêng        │
 │  [Inc3]   [Inc4]      │  (Water 36x40)   │
 │                       │                  │
 │  [Inc1]   [Inc2]      │                  │
 │                       │ [F1][F2][F3][F4] │  <- ô máy câu, quay mặt ra ao
 │                                          │
 │               [Home]                     │  <- điểm dịch chuyển về plot
 └──────────────┤ Cổng + biển tên ├────────┘
            (phía trước, -Z, ra đường)
```

- **Hatchery**: tối đa 4 máy ấp. Ban đầu mở 1, mua thêm ở Tool Shop. Các slot chưa mở hiện chữ "Locked".
- **Ao + ô máy câu**: tối đa 4 máy câu tự động, mua ở Tool Shop (tự lắp vào ô trống kế tiếp). Người chơi cũng có thể câu tay ở ao nhà mình.
- **Home**: khi hồi sinh hoặc bấm nút **My Plot** sẽ được đưa về đây.

## 3. Quy ước tên (QUAN TRỌNG khi tự build)

Toàn bộ map nằm trong `Workspace > Map` (Folder). **Nếu `Workspace` đã có `Map` thì code KHÔNG dựng map tạm nữa** mà dùng map của bạn.

| Đường dẫn / Tên | Loại | Bắt buộc | Ghi chú |
|---|---|---|---|
| `Map > ... > Spawn` | SpawnLocation | Có | Điểm hồi sinh ở Plaza, nút **Plaza** dịch chuyển tới đây |
| `Map > ... > Water` | Part (bao nhiêu cũng được) | Có | Mọi Part tên `Water` = nơi được phép câu (đứng trong vòng 25 stud) |
| `Map > ToolShop > ... > PromptPart` | Part | Có | Chỗ hiện nút "[E] Shop" |
| `Map > Market > ... > PromptPart` | Part | Có | Chỗ hiện nút "[E] Sell" |
| `Map > Plots > Plot1` ... `Plot8` | Model | Có | Số trong tên = thứ tự cấp plot |
| `Plot > ... > Home` | Part | Có | Điểm dịch chuyển về plot; hướng -Z của Part = hướng nhân vật nhìn |
| `Plot > ... > Sign` | Part | Nên có | Hiện tên chủ plot |
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

Model đặt lên map (máy ấp, máy câu, NPC, rương, pet...) thay ở `ReplicatedStorage > CustomModels`, xem `HUONG_DAN.md`.

## 5. Checklist giai đoạn tạo map

- [x] Map tạm: Plaza, Tool Shop, Market, hồ chung + dock, 8 plot
- [x] Mỗi plot có Hatchery (4 bệ), ao + 4 ô máy câu, Home, biển tên
- [x] Cấp plot khi người chơi vào, dọn plot khi rời
- [x] Nút **My Plot** / **Plaza** để dịch chuyển
- [x] Chỉ câu được khi đứng gần nước
- [ ] *(Bạn)* Copy map tạm vào place và trang trí
- [ ] *(Bạn)* Thay model thật vào `CustomModels`
- [ ] *(Bạn)* Chỉnh **Game Settings > Places > Max Players = 8** (bằng số plot)
- [ ] *(Sau)* Thêm Lighting, âm thanh nền, hiệu ứng nước
