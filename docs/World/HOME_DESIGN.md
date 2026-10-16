# Thiết kế nhà (plot) mới: sông, bến, hiên ấp, phòng rương, biển tên

> Chốt 15/10/2026 theo đề xuất (anh đồng ý "làm theo đề xuất"). Code: `HouseBuilder.lua`, `IncubatorBuilder.lua`, `IncubatorAnimator.client.lua`, `ParkBuilder.BuildRiver`, `River.client.lua`, `Plots.lua`. Lịch sử: `docs/ProjectManagement/DEVLOG.md` #46.

## 1. Quyết định đã chốt

| Câu hỏi | Chọn |
|---|---|
| Vị trí sông | **Ngoài vòng nhà**, sau lưng mỗi plot (cách mép sau plot khoảng 2 stud), chảy khép kín |
| Máy ấp sau khi vỡ vòm | **Tự mọc vòm mới miễn phí** (không phải đồ tiêu hao) |
| Cướp rương | **Phải vào trong nhà** (Stash nằm trong phòng rương); khóa cửa nhìn thấy được |
| Biển tên | **Có ảnh avatar** (headshot) cùng tên chủ nhà |

## 2. Bố cục plot (90x90, tọa độ cục bộ: cổng ở -Z, sân sau ở +Z)

```
 z=-45  cổng · lối đá · hộp thư (trang trí)
        nhà gỗ x -16..16, z -20..4 (biển tên TO trên nóc, ổ khóa ở cửa)
        phòng rương ở tường sau trong nhà (Stash + giá 5 hạng rương)
 z 10..40  bên trái (x -42..-14): hiên kính ấp trứng, 4 bệ máy ấp
 z 14..40  bên phải (x 14..42): vườn sau (cây, bàn dã ngoại, luống hoa)
 z 40..48  bến gỗ vắt ngang x -42..42: 5 bệ máy câu, ghế ngắm sông, đèn
 z 47..63  SÔNG (Terrain nước thật, bề rộng 16)
```

- Sông là elip `Config.River` (Rx 283, Rz 267, rộng 16) dựng bằng 96 đoạn Terrain; lá và vịt cao su trôi theo dòng là hiệu ứng client giả (`River.client.lua`).
- Ao riêng đã bỏ. Marker `Water` của từng plot (đoạn sông trước bến) là chỗ **câu tay** (vẫn là loại "Pond": chỉ ra rương Wooden, kéo chậm). Sông ngoài các đoạn đó không câu được.
- Hàng rào chỉ còn 3 cạnh (trước, hai bên); cạnh sau là sông.

## 3. Biển tên trên nóc

Part `Sign` 30x8 stud trên hai trụ ở sống mái, hai mặt đều đọc được. Mỗi nhà một màu viền (8 màu). `Plots.setSign(plot, tên, userId)` điền tên và ảnh `rbxthumb://type=AvatarHeadShot`; nhà trống hiện "FOR RENT".

## 4. Phòng rương trong nhà

- Rương lớn `Stash` đứng giữa bục vàng ở tường sau. [E] cất rương trong túi và mở bảng Stash (như trước).
- Giá trưng bày 5 chỗ `VaultSlot1..5` (theo thứ hạng rương): `Plots.renderVault` dựng chồng tối đa 3 rương mỗi hạng (model thật) kèm nhãn "xN", cập nhật mỗi khi kho `profile.Chests` đổi. Ai nhìn qua cửa cũng biết nhà này giàu hay nghèo.
- **Khóa cửa nhìn thấy được:** ổ khóa `DoorLock` ở cửa to dần và đổi vật liệu theo cấp (gỗ, bạc, vàng, đỏ neon). Nút nâng khóa ([E]) nằm trên ổ khóa.
- Vì Stash ở trong nhà nên cất rương cần vào tận phòng rương (thêm ~30 stud so với sân trước). Tutorial và nhãn đã đổi theo.

## 5. Khu ấp trứng và máy ấp "Tổ Ấm"

- Hiên kính 4 bệ (`IncubatorSlot1..4`, mở dần như cũ, nút [E] mở khóa trên bệ).
- **Model `IncubatorBuilder.Make()`:** vòm kính tròn trên đế tổ rơm có hai mắt (đốm sáng) và miệng, đèn sưởi ở đỉnh. Pivot ở đáy. Attribute `State` (`Empty` / `Incubating` / `Ready` / `Hatching`) và `Progress`.
- **Hoạt ảnh lặp (client):** trống = mắt nhắm, "Zzz", vòm mờ; đang ấp = đèn sưởi nhấp nháy (vàng sang cam khi gần nở), hơi ấm bay lên, trứng rung; nở xong = vòm nứt, rung, dấu "!" nảy; mắt luôn nhìn theo camera, chớp mắt, thở.
- **Hoạt ảnh nở (5 giây, `Config.Incubators.HatchAnim`):** 0 đến 2.4s dồn nhịp (rung mạnh dần, nén giãn, nứt dần, hơi bốc lên); 2.4s **bùng nổ** (chớp sáng, vòm kính vỡ thành mảnh bay tỏa, vỏ trứng vỡ, hạt lấp lánh; trứng Gold / Dragon thêm hạt cầu vồng), pet bật ra đúng lúc; sau đó đế chóng mặt (mắt xoáy); cuối cùng vòm mới phồng lên (overshoot). Chạy ở client của mọi người chơi (`Remote.EffectAll`), server chỉ chốt dữ liệu ngay lúc nhận và dựng lại máy sau 5 giây.

## 6. Chưa làm / ý định sau

- Cướp rương: nút "Pick lock" vẫn nằm ở rương Stash (trong nhà) và máy câu; chưa có cửa chặn vật lý.
- Âm thanh máy ấp, tia sáng riêng theo độ hiếm cao hơn, model thật thay đồ tạm.
- Bờ sông trang trí (sậy, đá), cầu qua sông, cá nhảy.
- Ngỗng nhà đi vòng bán kính 36 quanh tâm plot, có thể vướng bàn / cây mới: cần chơi thử.
