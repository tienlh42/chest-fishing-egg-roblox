# Biến thể pet: đổi màu và hiệu ứng (không cần model mới)

> Dành cho dev và người làm hình ảnh. Cập nhật lần cuối 16/10/2026. **Chỉ là kế hoạch, chưa code.**
> Đọc kèm `STYLE_GUIDE.md` (phong cách), `../GameDesign/RETENTION.md` (lý do làm), `../GameDesign/SYSTEM_DESIGN.md` mục 6 (pet).
> Chưa xem model trong Studio phiên này; mô tả cấu trúc lấy từ file `.rbxmx` trong `Assets/Models` và script `PetEffects` bên trong.

## 0. Nhãn và điều đã chốt

| Nhãn | Nghĩa |
|---|---|
| **[ĐÃ CHỐT]** | Anh Scott đã quyết, chưa code |
| **[ĐỀ XUẤT]** | AI đề xuất, cần xem trong Studio rồi chỉnh |

**Đã chốt (16/10/2026):**
1. Pet mới trong mục giữ chân được làm bằng **đổi màu và hiệu ứng trên 5 model có sẵn**, không đợi model mới.
2. Biến thể **chỉ đổi hình**, không đổi HP, độ bền, kỹ năng hay giá trị chiến đấu (đã chốt ở RETENTION).
3. Có **cosmetic**, nhưng làm sau (Robux, xem `MakeRobuxInHere/`). Hệ thống này làm sao để cosmetic dùng lại được.

## 1. Model pet hiện có (từ file `.rbxmx`)

| Đặc điểm | Nội dung |
|---|---|
| Cấu tạo | ~39 `Part`, mỗi part có `SpecialMesh` (không dùng `MeshPart`, không có texture hay `SurfaceAppearance`) |
| Khung xương | `Motor6D` nối các part (HumanoidRootPart, Body, Head, EarL, EarR, ArmL, ArmR, LegL, LegR, Tail, Hat, Tool...) |
| Animation | Script `PetAnimator` ghi `Motor6D.Transform` từ thư mục `Animations`, đổi theo attribute `Anim` |
| Hiệu ứng | Script `PetEffects` (chạy ở client): đọc attribute `Rarity`, tạo **`Highlight`** viền theo màu độ hiếm, hạt lấp lánh nhàn rỗi, hạt khi nhảy mừng, vầng hào quang xoay; Mythic có cầu vồng |
| Màu | Mỗi part đặt `Color3` trực tiếp, nên **đổi màu bằng code là đủ** |
| Chi tiết khuôn mặt | Mắt (`EyeL/R`), ánh sáng (`Shine*`), mũi, má hồng (`Blush*`), lưỡi, miệng, vài vật phụ theo từng pet (bánh mì, mũ...) |

Hệ quả:
- **Đổi màu không cần model mới.** Chỉ cần đổi `Color3` (và có thể `Material`) của các part thân.
- **Hiệu ứng thêm bằng particle và `Highlight` built-in**, đã quen ở `PetEffects`, không cần upload âm thanh hay texture.
- Cần chú ý **giới hạn `Highlight`** (Roblox chỉ vẽ một số lượng hạn chế cùng lúc, em nhớ khoảng 31): đã có 1 Highlight mỗi pet. Biến thể **đổi màu Highlight sẵn có**, không thêm cái mới.

## 2. Các biến thể [ĐỀ XUẤT]

| Biến thể | Cách có | Màu | Hiệu ứng | Cảm giác |
|---|---|---|---|---|
| **Normal** | Mặc định | Màu gốc | Như hiện tại | |
| **Shiny** | 1% mỗi lần nở | **Xoay màu** (hue shift ~ +0.45, tăng sáng), mắt giữ nguyên | Viền sáng thêm, hạt lấp lánh nhàn rỗi tăng, 1 vệt sao khi chạy | "Pet đổi màu độc, nổi bật" |
| **Golden** | 0.1% mỗi lần nở | **Ánh vàng** (pha 75% vàng), vật liệu kim loại nhẹ | Viền vàng, hào quang xoay, vệt vàng phía sau khi chạy, tiếng "ting" khi nở | "Hiếm, đáng khoe" |
| **Prismatic** (sự kiện, sau) | Sự kiện hoặc phần thưởng đặc biệt | Cầu vồng chuyển động | Cầu vồng như Mythic, nhưng cho mọi pet | Dành cho sự kiện và season |

- **Bảo hiểm xui:** sau **150 trứng liên tiếp** không ra Shiny thì quả tiếp theo chắc chắn Shiny (bộ đếm lưu trong profile). Golden không có bảo hiểm.
- **Thời gian kỳ vọng:** mỗi giờ chơi nở khoảng 30 đến 60 trứng (ước lượng từ kinh tế), nên Shiny ~ 1 con mỗi 1.5 đến 3 giờ, Golden ~ 1 con mỗi 15 đến 30 giờ.
- **Giá bán pet:** nhân thêm hệ số cho người sưu tầm (Shiny x1.5, Golden x3), vẫn nhỏ so với bậc trứng. Cần cân lại sau khi xem tần suất thật.
- **Không** đổi độ hiếm hay tên pet, chỉ thêm tiền tố "Shiny", "Golden" khi hiển thị.

## 3. Cách đổi màu

Hàm dùng chung `Models.ApplyVariant(model, variantName)` trong `Models.lua` (có cả ở server và client):

```
cho mỗi BasePart trong model
  bỏ qua: HumanoidRootPart, mắt (Eye*), ánh (Shine*), mũi (Nose), má (Blush*), lưỡi (Tongue), miệng (Smile)
  Shiny:  Color3 -> HSV, cộng Hue, tăng nhẹ Saturation/Value
  Golden: Color3 = Color3:Lerp(vàng, 0.75), Material = Metal (hoặc Foil), Reflectance 0.1
```

Cấu hình trong `Config.PetVariants` (một bảng, không viết code riêng cho từng pet):

```lua
Config.PetVariants = {
	Shiny = { Chance = 0.01, Pity = 150, Recolor = { Mode = "Hue", Shift = 0.45, Value = 1.1 }, OutlineColor = ..., IdleSparkle = 4, SellMult = 1.5 },
	Golden = { Chance = 0.001, Recolor = { Mode = "Tint", Color = ..., Strength = 0.75, Material = "Metal" }, OutlineColor = ..., IdleSparkle = 6, Trail = true, SellMult = 3 },
}
```

- Đổi màu chạy **phía server** khi pet được dựng (`Pets.spawnPet`): `Color3` tự lan tới mọi client, không cần thêm Remote.
- Cũng gọi ở nơi khác vẽ pet: **kệ trưng bày** (`House.lua`), **ô Bag và hộp xem trước** (`MainUI.client.lua`, viewport), **hiệu ứng nở** (`Effects.client.lua`).
- Đặt **attribute `Variant`** trên model để các script biết (cùng kiểu `Rarity`, `Anim`).

## 4. Cách thêm hiệu ứng

**Không sửa 6 bản `PetEffects` trong từng model** (mỗi bản chép riêng, khó đồng bộ, và `tools/prepare_assets.py` còn vá chúng). Thay vào đó thêm **một LocalScript trung tâm** `PetVariantEffects.client.lua`:

- Nghe `workspace.PlayerPets` (thư mục chứa pet đang đi theo); khi có pet mới mang attribute `Variant`, đọc `Config.PetVariants[Variant]`.
- Đổi `OutlineColor` của `Highlight` có sẵn trong pet (do `PetEffects` tạo) thay vì tạo thêm.
- Thêm hạt lấp lánh nhàn rỗi (nhịp cao hơn), vầng hào quang xoay (Golden), vệt (`Trail`) khi chạy (Golden), dùng texture hạt có sẵn của Roblox giống `PetEffects`.
- **Ngân sách hiệu ứng:** chỉ bật cho pet **trong 60 stud** của camera và tối đa **8 pet** cùng lúc, còn lại chỉ đổi màu. Nhiều pet trên điện thoại sẽ nặng (đã có cảnh báo ở README của asset).
- Tắt hiệu ứng thêm khi người chơi chọn chế độ đồ họa thấp (nếu sau này có cài đặt).

**Khoảnh khắc nở trứng** (quan trọng nhất cho cảm giác may rủi):
- Shiny: lóe sáng ngắn, chữ "SHINY!" bay lên, tiếng chuông, pet nhảy mừng lâu hơn.
- Golden: lóe vàng, chữ "GOLDEN!", **thông báo toàn server** ("<tên> hatched a Golden Baker Dog!"), tiếng "ting".
- Dùng sự kiện `Hatched` đang có (`Hatchery.lua` gửi `Effect "Hatched"`), thêm trường `Variant`.

## 5. Dữ liệu

| Trường | Nội dung |
|---|---|
| `profile.Pets[i].Variant` | `nil` (Normal), `"Shiny"`, `"Golden"`. Thêm vào bản ghi pet `{ Id, Name, Durability, Variant }`, **không cần chuyển đổi dữ liệu cũ** (nil = Normal) |
| `profile.PityShiny` | Số trứng nở liên tiếp chưa ra Shiny |
| `profile.Collection` (RETENTION R4) | Ghi nhận pet đã có theo cả biến thể, để nhật ký sưu tập hiện "đã có Shiny Baker Dog" |

## 6. Giao diện

- **Bag:** ô pet có nhãn nhỏ "SHINY" hay "GOLDEN" và viền màu tương ứng. Model trong ô dùng cùng hàm đổi màu.
- **Nhật ký sưu tập:** mỗi pet hiện 3 chấm (Normal, Shiny, Golden), sáng khi đã có.
- **Tên hiển thị:** "Shiny Baker Dog", "Golden K9 Dog".
- **Market:** giá bán hiển thị kèm hệ số.

## 7. Cosmetic (làm sau, bán Robux) dùng lại hệ thống này [ĐỀ XUẤT]

Phân biệt hai loại để không lẫn:
- **Biến thể (Variant):** **nhận được khi nở trứng** bằng may mắn, gắn với từng con pet.
- **Skin (cosmetic):** **mua bằng Robux**, gắn với người chơi và có thể đổi qua lại giữa mọi pet.

Hai thứ dùng chung hàm đổi màu, nhưng skin được áp **sau** biến thể và có `Config.PetSkins` riêng. Chưa làm bây giờ. Lưu ý chính sách: nếu sau này bán trứng hay hộp ngẫu nhiên bằng Robux thì phải **công bố tỉ lệ** Shiny và Golden (xem `MakeRobuxInHere/03_COMPLIANCE_AND_RISKS.md`).

## 8. Rủi ro

| Rủi ro | Giảm thiểu |
|---|---|
| Đổi `Color3` làm chi tiết khuôn mặt (mắt, má) lệch màu | Danh sách bỏ qua theo tên; kiểm tra bằng ảnh chụp 5 pet x 3 biến thể trong Studio |
| Vài pet có phụ kiện cần giữ màu gốc (bánh mì của Baker Dog, nồi...) | Thêm danh sách `Keep` riêng từng pet trong `Config.PetVariants` nếu cần |
| Quá nhiều hiệu ứng làm nặng điện thoại | Ngân sách hiệu ứng ở mục 4, chỉ pet gần camera |
| `Highlight` vượt giới hạn | Đổi màu cái sẵn có, không tạo thêm |
| Shiny quá dễ hay quá khó | 1% và bảo hiểm 150 là điểm xuất phát, chỉnh sau khi có số liệu nở thật |
| Hiệu ứng đẹp trên máy mạnh nhưng không ai thấy trên điện thoại | Màu (Shiny, Golden) vẫn nhận ra ngay dù không có hiệu ứng |
| Chính sách ngẫu nhiên nếu bán Robux | Chỉ nhận qua trứng bằng coins ở giai đoạn này; công bố tỉ lệ nếu đổi |

## 9. Điều cần xem trong Studio trước khi code

Nên làm một bản thử nhanh (script trong Command Bar) để chọn màu thật:
1. Với từng pet trong `CustomModels`, thử `ApplyVariant` Shiny và Golden, chụp ảnh.
2. Kiểm tra tên part thật của 5 pet để chốt danh sách bỏ qua (`Eye*`, `Shine*`...).
3. Xem Shiny (xoay hue) có hợp từng pet không (Baker Dog nâu có thể xoay ra xanh dương đẹp, Office Dragon đã nhiều màu có thể không đổi được nhiều).
4. Chọn 1 đến 2 hue shift cho mỗi pet nếu một giá trị chung không hợp.

## 10. Các điểm đã chốt (16/10/2026)

| # | Câu hỏi | Quyết định |
|---|---|---|
| 1 | Giá bán biến thể | **Nhân lên:** Shiny x1.5, Golden x3 |
| 2 | Thông báo toàn server khi nở Golden | **Có**, làm trong hệ thống thông báo phòng: xem `../GameDesign/SERVER_BOARD.md` |
| 3 | Prismatic | **Để sau** (sự kiện, season), chưa trả lời nên em giữ mặc định |
