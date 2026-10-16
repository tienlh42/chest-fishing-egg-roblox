# Kế hoạch: Công viên hồ trong khu dân cư + Nhà gỗ cho Plot

> Trạng thái: **ĐÃ LÀM (13/10/2026)**. Code: `ServerScriptService/Modules/ParkBuilder.lua`, `HouseBuilder.lua`, `BuildUtil.lua`.
> Đã chốt: nước xanh ngọc · nhà gỗ **vào được bên trong** (có nội thất) · mái gỗ giống nhau mọi nhà · **không** làm dãy nhà phông nền · ~~1 cầu tàu~~ → **bỏ cầu tàu** (13/10): câu từ lối gạch qua lan can, ở bất kỳ đâu quanh hồ.
> Ảnh tham khảo: công viên hồ giữa khu dân cư (hồ bo góc, lối đi lát gạch màu cam đất ôm sát bờ, lan can, đèn, bãi cỏ thấp, cây non, đường phố và nhà dân bao quanh).

---

## 1. Mục tiêu

| # | Yêu cầu | Cách làm |
|---|---|---|
| 1 | **Hạ hết cỏ xuống** | Tắt cỏ cao lay động của Terrain (`Terrain.Decoration = false`), để mặt cỏ phẳng và gọn như sân cỏ được cắt. Chỉnh lại màu cỏ cho xanh tươi, đồng đều. |
| 2 | **Công viên hồ kiểu khu dân cư** | Làm lại hồ thành hình **chữ nhật bo góc lớn** (thay cho hình "đám mây" hiện tại). Có **lối đi lát gạch** ôm sát bờ, **lan can thấp**, **đèn đường** đều nhau, bãi cỏ, cây non có cọc chống, 2 quảng trường nhỏ. Bao quanh là **đường phố và dãy nhà dân**. |
| 3 | **My Plot → nhà gỗ dễ thương** | Mỗi plot thành một **lô nhà dân**: nhà gỗ mái nhọn, hiên, cửa sổ có chậu hoa, hàng rào gỗ trắng, sân sau có chuồng ấp trứng và ao nhỏ. |

Nguyên tắc: **không phá gameplay đang có** (câu giữ nút, ngỗng, túi, Stash, vùng an toàn, ấp trứng, máy câu). Chỉ đổi phần hình ảnh và bố cục.

---

## 2. Bố cục tổng thể mới (nhìn từ trên xuống, phía trên = -Z)

```
          x=-180                     x=0                      x=+180
 Plot1 ┃                [Tool Shop]  [Plaza]  [Market]               ┃ Plot5
       ┃ ════════════════════ đường z=0 ═══════════════════════     ┃
 Plot2 ┃                             ║ (lối vào)                     ┃ Plot6
       ┃ ═════════════════ đường công viên z=34 ════════════════    ┃
       ┃ ║  ┌──────── CÔNG VIÊN (x -110..110, z 40..200) ───────┐ ║  ┃
 Plot3 ┃ ║  │   cây   ┌────── lối gạch + lan can ──────┐  cây  │ ║  ┃ Plot7
       ┃ ║  │ [QT Tây]│        HỒ (bo góc)             │[QT Đông]│ ║  ┃
       ┃ ║  │   đèn   │   ▓ cầu tàu (bờ Bắc)            │  đèn  │ ║  ┃
 Plot4 ┃ ║  │         └─────────────────────────────────┘        │ ║  ┃ Plot8
       ┃ ║  └──────────────── [cổng Nam + QT Nam] ───────────────┘ ║  ┃
       ┃ ═════════════════ đường z=206 ══════════════════════════    ┃
         [nhà dân] [nhà dân] [nhà dân] [nhà dân] [nhà dân] [nhà dân]   (phông nền)
```

| Khu | Vị trí / kích thước | Ghi chú |
|---|---|---|
| Plaza, Tool Shop, Market | giữ nguyên chỗ cũ | Plaza vẫn là **vùng an toàn**, Stash vẫn cạnh điểm hồi sinh |
| Đường bao công viên | Bắc z=34, Nam z=206, Tây/Đông dùng 2 đường dọc x=±128 sẵn có (kéo dài tới z=206) | Mặt nhựa xám đậm + **vỉa hè** màu xám nhạt 2 bên |
| Công viên | x -110..110, z 40..200 | **KHÔNG phải vùng an toàn**, là sân của ngỗng |
| Hồ | tâm (0, 120), **130 x 90**, bo góc bán kính 22 | Nước thật (Terrain), sâu 8, đáy cát |
| Dãy nhà dân phông nền | phía Nam đường z=206, chen thêm giữa các plot | Chỉ để trang trí, không vào được |

---

## 3. Chi tiết công viên

### 3.1 Hồ
- Hình chữ nhật bo góc, ghép từ 1 khối chữ nhật và 4 hình trụ ở góc (Terrain).
- Mép hồ là **bờ kè thẳng đứng** (dải Part đá xám thấp), không dùng bãi cát loang như bây giờ. Nhờ vậy viền hồ sắc nét như ảnh.
- Màu nước: **giữ xanh ngọc** như hiện tại cho vui mắt (ảnh thật màu xanh rêu, không hợp game). *(xem câu hỏi ở mục 7)*

### 3.2 Lối đi quanh hồ
- Lối **gạch màu cam đất** rộng 6 stud, chạy sát bờ kè suốt vòng hồ. Dựng bằng Part (đoạn thẳng + các đoạn ngắn xoay theo cung ở góc) để **mép sắc nét**, vì Terrain làm mép bị nhoè.
- **Lan can** cao khoảng 2.5 stud giữa lối đi và mặt nước: cột mảnh, cứ 4 stud một cột, kèm 2 thanh ngang. Người chơi **vẫn câu qua lan can được** (câu tính theo khoảng cách tới nước, không cần chạm nước).
- Lan can **chừa khe** ở đầu cầu tàu.
- **Đèn đường** cứ khoảng 20 stud một cây, đặt ở mép ngoài lối đi, có ánh sáng ấm.

### 3.3 Bãi cỏ, lối phụ, quảng trường
- Cỏ thấp phẳng. Có các **lối phụ thẳng** cùng màu gạch, nối lối quanh hồ ra 3 cổng: Bắc (về Plaza), Nam, Đông.
- **Quảng trường Đông** và **Quảng trường Nam**: sân gạch vuông 20x20, có ghế đá, bồn hoa và thùng rác.
- **Nhà bảo vệ nhỏ** mái xanh (giống ngôi nhà mái xanh trong ảnh) ở góc Tây Bắc. Đây là "trạm của ngỗng" để trang trí, hợp cốt truyện "Ngỗng bảo vệ".

### 3.4 Cây
- **Cây non có 3 cọc chống**, trồng thưa trên bãi cỏ, khoảng 40 cây (giống ảnh).
- **Cây tán lớn** dọc vỉa hè đường bao, khoảng 20 cây.
- Bỏ cây thông vuông và bụi tròn hiện tại.

### 3.5 Cầu tàu (ĐÃ BỎ – câu từ lối gạch)
- Cầu gỗ chữ T ở **bờ Bắc**, nối từ lối đi ra giữa hồ. Đây là điểm câu chính, đi từ Plaza xuống gần nhất.
- Thêm **2 bến câu nhỏ** ở bờ Đông và bờ Tây, khớp với GDD "3 điểm câu": điểm gần, điểm giữa, điểm xa.

---

## 4. Plot → Nhà gỗ dễ thương

Plot vẫn rộng 90 x 90, cổng quay ra đường, vẫn là **vùng an toàn**.

```
              (phía sau, +Z)
 ┌──────────────────────────────────────────────┐
 │  CHUỒNG ẤP TRỨNG (gỗ, mái nghiêng)  │ AO VƯỜN │
 │  [Inc1] [Inc2] [Inc3] [Inc4]         │ (nước   │
 │                                      │  thật)  │
 │  ~ luống hoa ~    cây ăn quả         │F1 F2 F3 F4  <- máy câu quay ra ao
 │         ┌────────────────────┐                 │
 │         │   NHÀ GỖ (24x18)   │  ống khói        │
 │         │  cửa sổ + chậu hoa │                  │
 │         └──────[hiên]────────┘                  │
 │                [Home]   hộp thư = biển tên       │
 └────────────┤ cổng gỗ trắng ├──────────────────┘
              (phía trước, -Z, ra đường)
```

| Thành phần | Mô tả |
|---|---|
| **Nhà gỗ** | Tường ván gỗ màu mật ong, **mái nhọn** màu đỏ gạch hoặc nâu (mỗi plot một màu mái để dễ nhận nhà mình), cửa ra vào, 4 cửa sổ có **chậu hoa**, hiên có 2 cột và bậc thềm, ống khói. Nhà chỉ để trang trí, **không vào trong** ở bản này. |
| **Hàng rào** | Rào gỗ trắng kiểu "picket" thay cho tường bê tông xám, cổng gỗ trắng ở giữa. |
| **Biển tên** | Đổi cổng vòm thành **hộp thư** cạnh cổng, có bảng tên "Tên's House". Vẫn dùng Part tên `Sign`. |
| **Home** | Điểm hồi sinh đặt trước hiên, thay tấm neon vàng bằng **thảm chùi chân**. |
| **Chuồng ấp trứng** | Thay mái hồng bằng chuồng gỗ mái nghiêng, nền rơm. Giữ 4 bệ `IncubatorSlot1..4`. |
| **Ao vườn** | Đổi tấm Part xanh thành **nước thật** (Terrain), viền đá cuội. Giữ 4 ô `FisherSlot1..4` quay mặt ra ao. |
| **Trang trí** | Luống hoa, 1–2 cây ăn quả, lối đá dẫn từ cổng vào hiên, đèn treo ở hiên. |

> Để ao trong plot thành nước thật, nền plot phải đổi từ tấm Part sang **Terrain** (giống cả map). Viền lô đất được vẽ bằng hàng rào.

---

## 5. Ràng buộc kỹ thuật (để không làm hỏng gameplay)

| Hệ thống | Phụ thuộc vào | Việc cần làm |
|---|---|---|
| Câu cá (Fishing) | Part vô hình `Water` trong model `Lake` = hồ cấm; `Water` trong Plot = ao an toàn | Đặt lại `Water` phủ đúng hồ mới (130x90) và ao mới trong từng plot |
| Ngỗng (Guard) | `Config.Guard.Patrol` (11 điểm quanh hồ cũ), pathfinding tránh nước | **Viết lại điểm tuần tra** chạy theo lối gạch quanh hồ mới. Lan can không được chặn đường đi của ngỗng (ngỗng đi trên lối gạch, lan can nằm phía trong). |
| Vùng an toàn (SafeZone) | Hộp bao quanh model `Plaza` và từng `Plot` | Giữ tên model. Lưu ý cây/nhà trang trí **không được** nằm trong model `Plaza` (hộp bao sẽ phình to, lấn sang công viên). |
| Stash | Tự đặt cạnh `Spawn` | Không đổi |
| Plot | Tên `Plot1..8`, `Home`, `Sign`, `IncubatorSlot1..4`, `FisherSlot1..4`, `Water` | Giữ nguyên toàn bộ tên |
| Hiệu năng | Số Part | Ước tính thêm khoảng 2.500 Part (lan can và hàng rào chiếm nhiều nhất). Ổn với Roblox. Nếu lag sẽ gộp cột lan can thành ít Part dài hơn. |

---

## 6. Thứ tự làm (mỗi bước Play và chụp ảnh kiểm tra)

- [x] **B1. Cỏ + nền:** tắt cỏ cao, chỉnh màu cỏ, làm lại hồ bo góc và bờ kè.
- [x] **B2. Lối đi:** lối gạch quanh hồ, lan can, đèn, cầu tàu Bắc và 2 bến câu Đông/Tây.
- [x] **B3. Bãi cỏ:** lối phụ, 2 quảng trường, ghế, bồn hoa, cây non và cây tán lớn, nhà bảo vệ.
- [x] **B4. Phố:** đường bao công viên có vỉa hè, dãy nhà dân làm phông nền.
- [x] **B5. Plot:** nhà gỗ, hàng rào, hộp thư, chuồng ấp trứng, ao nước thật, trang trí sân.
- [x] **B6. Gameplay:** cập nhật điểm tuần tra của ngỗng, kiểm tra câu ở 3 điểm, kiểm tra ngỗng đuổi và dừng ở vùng an toàn, kiểm tra cất đồ ở Stash. Cập nhật `docs/World/MAP_LEVEL1.md`.

Toàn bộ vẫn là **đồ tạm dựng bằng code** (MVP). Sau này thay bằng build thật theo `docs/World/MAP_LEVEL1.md`.

---

## 7. Ghi chú kỹ thuật khi làm (đọc trước khi sửa map)

- **Cỏ thấp:** script KHÔNG được đổi `Terrain.Decoration`, nên nền cỏ dùng chất liệu **LeafyGrass** (Roblox chỉ mọc cỏ cao trên chất liệu `Grass`).
- **Độ cao Terrain:** Terrain làm tròn theo ô 4 stud nên mặt **đất** hiện cao hơn vùng fill 2 stud (mặt **nước** thì không).
  Vì vậy đất được fill thấp xuống 2 stud (`TERRAIN_SHIFT = -2` trong `ParkBuilder`), nước fill tới đúng y = 0.
  Nếu không làm vậy, mọi Part sát đất (đường, vỉa hè, nền plot) bị cỏ phủ mất.
- **Nước không đè lên đất đặc:** phải fill `Air` trước rồi mới fill `Water`.
- Độ cao mặt trên các lớp nền (khác nhau để không nhấp nháy): đường 0.25 · lối phụ 0.3 · lối quanh hồ 0.35 · quảng trường 0.4 · vỉa hè 0.45.
- Ngỗng tuần tra theo `Config.Guard.Patrol` (12 điểm giữa lối gạch quanh hồ). Đổi hình hồ thì phải sửa lại danh sách này.

## 8. Bố cục vòng tròn + cân bằng (13/10/2026)

- **Bỏ sảnh chính (Plaza).** Hồ dời về **chính giữa map**, 8 nhà xếp vòng quanh theo elip (Rx 228, Rz 212) để
  quãng đường **lối gạch quanh hồ → thảm Home của mọi nhà ≈ 129–131 stud** (đi bộ ~8s, chạy ~4s).
- Bị ngỗng bắt → **về thẳng nhà**, mất đồ chưa cất. Đang mang đồ trong túi thì **không được bấm My Plot** (phải tự chạy về).
- Câu lén: nhả nút = tạm dừng giữ tiến độ (xem `Fishing.lua`). Ngỗng chỉ để ý người khả nghi.

### BALANCE (số trong `Config.lua`)

| Thông số | Cũ | Mới | Vì sao |
|---|---|---|---|
| `Guard.SightRange` (thấy người đang KÉO) | 50 | **40** | Bớt bị phát hiện từ quá xa |
| `Guard.LootSightRange` (thấy người mang đồ) | 22 | **10** | Đã nhả nút mà túi có đồ vẫn bị đuổi → quá khó. Giờ chỉ khi đứng sát ngỗng |
| `Guard.ShortSight` (thấy cả sau lưng) | 12 | **8** | Lén sau lưng ngỗng được |
| `Guard.SuspiciousTime` ("Honk?" trước khi đuổi) | 1.5 | **2** | Đủ thời gian phản xạ nhả nút |
| `Guard.SearchTime` | 4 | **3** | Ngỗng đứng soi ít hơn rồi đi |
| `Guard.LoseTime` | 5 | **4** | Chạy khuất tầm nhìn thì dễ cắt đuôi hơn chút |
| `Fishing.NoiseRadius` | 70 | **45** | Ngỗng chỉ nghe thấy trong ~1/3 vòng tuần tra |
| `Fishing.NoiseDelay` | 2 | **3** | 3 giây kéo đầu tiên không gây tiếng động |
| `Fishing.Leash` (đi xa khi tạm dừng) | 10 | **12** | Có chỗ lùi ra núp |
| `Fishing.PauseTimeout` | 30 | **40** | Đợi ngỗng đi qua cho thong thả |
| `Fishing.MaxMove` (bị đẩy khi đang kéo) | 1.5 | **3** | 1.5 làm hụt oan khi trượt nhẹ |
| Giữ nguyên | | | `ChaseSpeed 21` (đi bộ 16 bị bắt, chạy 30 thoát), `CatchRange 4`, pet chặn ~20s |

Vẫn **không quá dễ**: kéo câu trong tầm nhìn 40 stud quá 2 giây là bị đuổi; đã bị đuổi thì phải chạy ~130 stud về nhà;
đi bộ (không Shift) sẽ bị bắt kịp; pet chỉ cầm chân ~20 giây.

## 9. Các câu hỏi đã chốt (lưu lại)

1. **Màu nước hồ:** giữ **xanh ngọc** như hiện tại (đề xuất), hay đổi sang **xanh rêu** như ảnh thật?
2. **Nhà gỗ có vào trong được không?** Đề xuất bản này là **không** (chỉ mặt ngoài). Có nội thất thì tốn thêm 1 bước.
3. **Màu mái nhà:** mỗi plot **một màu** (đề xuất: đỏ, xanh dương, xanh lá, vàng... dễ nhận nhà mình), hay **tất cả giống nhau**?
4. **Dãy nhà dân phông nền:** có cần không? Có thì map đẹp hơn nhưng nhiều Part hơn.
5. **3 điểm câu** (cầu Bắc, bến Đông, bến Tây) hay chỉ **1 cầu tàu** như hiện tại?
