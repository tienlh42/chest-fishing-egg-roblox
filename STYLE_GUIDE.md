# Style guide: Chunky Cartoon vui nhộn + hiệu ứng kiểu anime

Áp dụng cho mọi model (nhân vật, quái, vật phẩm tương tác, phần thưởng) và animation trong repo. Đối tượng: bé nam và nữ 13-17 tuổi. Thể loại: tycoon, simulator, nhập vai, thiên về vui nhộn.

`PoliceGoose/` là model mẫu đã theo guide này.

## 1. Nguyên tắc hình khối

- **Chunky:** đầu to (khoảng 1/3 chiều cao), thân tròn, tay chân ngắn. Bo tròn là chính, góc cạnh chỉ dùng cho chi tiết nhấn.
- **Nhìn bóng là nhận ra:** mỗi nhân vật hoặc quái có 1 đặc điểm lớn nhất định (cổ trắng dài, mũ kê-pi...). Kiểm tra bằng cách tô đen toàn bộ model, vẫn phải phân biệt được.
- **Ít chi tiết nhỏ:** chi tiết nhỏ hơn 0,3 stud thì bỏ hoặc gộp. Mỗi model tối đa 3 màu chủ đạo cộng 1 màu nhấn.
- **Nét hài:** mỗi model có ít nhất 1 chi tiết ngố (đội mũ sai kích cỡ, dép lê, lông mày cau có...).
- **Quái:** vui nhộn, "dữ dữ dễ thương". Boss mới được dùng tông tối hơn, vẫn giữ mặt ngố.
- **Kỹ thuật:** dựng từ Part và SpecialMesh khi được, nếu dùng mesh thì low-poly, texture đơn giản, ít vật liệu để chạy mượt trên mobile. Vật liệu mặc định `SmoothPlastic`, kim loại dùng `Metal`.

### 1.1 Yếu tố nhập vai

Mỗi model thuộc đúng một trong hai nhóm dưới đây, để thế giới game có chung một mạch hài: thú thì làm việc như người, đồ vật thì sống như thú.

| Nhóm | Yếu tố bắt buộc | Cách thể hiện |
| --- | --- | --- |
| Pet, thú, quái | **Ngành nghề** mang tính con người | Trang phục hoặc đồ nghề đặc trưng (mũ, đồng phục, dụng cụ) nhìn ra được từ silhouette, và ít nhất 1 animation thể hiện công việc (đứng gác, thổi còi, gõ dùi cui, khoe cơ bắp...) |
| Vật phẩm (rương, trứng, phần thưởng, đồ trang trí, đồ dùng) | **Linh hồn thú vật** | Có vài đặc điểm của thú (mắt, miệng, lưỡi, tai, đuôi, cánh, lông, vảy, móng) và cử chỉ của thú (thở, rùng mình, thè lưỡi, vẫy đuôi, liếc nhìn), nhưng vẫn nhận ra ngay là đồ vật |

- **Nghề phải vui và đời thường:** cảnh sát, đầu bếp, vận động viên, thợ làm bánh, nhân viên văn phòng, bảo vệ ngủ gật... Tránh nghề hoặc đồ nghề nhạy cảm với lứa 13-17 tuổi (vũ khí thật, rượu, thuốc lá...). Đồ nghề có thể phóng đại cho ngố (dùi cui đen, còng tay, nắp nồi cơm điện).
- **Nghề phải đọc được:** người chơi nhìn bóng đen cũng đoán ra nghề nhờ đồ nghề lớn nhất (mũ kê-pi, nắp nồi, còi). Một nghề chính, thêm tối đa 1 đồ phụ.
- **Linh hồn thú ở mức vừa đủ:** tối đa 2-3 đặc điểm hoặc cử chỉ thú trên một vật phẩm. Chọn loài hợp với vật (rương có răng và lưỡi như thú ăn tham, trứng có tai hoặc đuôi của pet bên trong).
- **Dễ thương hoặc ngố, không ghê rợn:** mắt to, răng cười, lưỡi dài kiểu hoạt hình. Không có máu, răng nanh dọa người hay biểu cảm đáng sợ. Boss được nghiêm hơn nhưng vẫn giữ nét ngố.
- **Độ hiếm càng cao thì nét nhập vai càng rõ:** vật phẩm hiếm có thêm cử chỉ thú sinh động, pet hiếm có đồ nghề cầu kỳ hơn.

## 2. Bảng màu

Màu tươi, bão hòa vừa. Mỗi khu vực hoặc phe lấy 1 màu chủ đạo.

### Màu nền (dùng chung)

| Tên | Hex | Dùng cho |
| --- | --- | --- |
| Trắng sữa | `#F5F5F0` | Lông, da sáng, mảng sáng |
| Đen mực | `#1C1C1E` | Viền, đồng tử, đồ đen |
| Bạc | `#CDD0D7` | Kim loại, dụng cụ |
| Navy | `#1F3A68` | Đồng phục, phe trật tự |
| Cam | `#FF8C1A` | Mỏ, chân, điểm nhấn ấm |
| Vàng | `#F2C230` | Huy hiệu, tiền, điểm nhấn |

### Màu mở rộng (cho quái, khu vực, vật phẩm)

| Tên | Hex | Gợi ý |
| --- | --- | --- |
| Hồng kẹo | `#FF6FB5` | Dễ thương, phụ kiện, hiệu ứng tim |
| Tím mộng | `#9B6BFF` | Phép thuật, quái đặc biệt |
| Xanh biển | `#3DB8F5` | Nước, băng, tiền tệ phụ |
| Xanh lá | `#5CD66B` | Thiên nhiên, hồi máu, thành công |
| Đỏ cam | `#FF5A4D` | Nguy hiểm, trúng đòn, cảnh báo |
| Mint | `#7FF0D0` | Nền sáng, UI |
| Gỗ | `#B5733C` | Đồ gỗ, rương, thùng |
| Gỗ tối | `#7A4A24` | Lòng rương, lông mày, viền gỗ |
| Vàng đậm | `#C99A12` | Bóng của vàng, viền kim loại vàng |
| Tím nhạt | `#D6BEFF` | Tinh thể, đá quý tím |

### Độ hiếm phần thưởng

Màu dùng cho viền, hào quang và hiệu ứng nền của vật phẩm.

| Độ hiếm | Màu | Hex | Hiệu ứng |
| --- | --- | --- | --- |
| Thường | Trắng | `#F5F5F0` | Không có |
| Hiếm | Xanh | `#3DB8F5` | Viền sáng |
| Sử thi | Tím | `#9B6BFF` | Viền sáng và vài hạt lấp lánh |
| Huyền thoại | Vàng | `#F2C230` | Hào quang xoay và tia sáng |
| Thần thoại | Cầu vồng | đổi màu liên tục | Hào quang cầu vồng, tia sáng, hạt bay |

## 3. Tô bóng và viền

- **Cel-shading:** chia 2 tầng sáng-tối rõ ràng, không gradient mượt. Roblox không có shader tùy chỉnh nên dùng `SmoothPlastic`, ánh sáng gắt vừa (`Lighting.Brightness` 2-3, `EnvironmentDiffuseScale` thấp) và đừng dùng texture đổ bóng.
- **Viền:** model quan trọng (nhân vật, quái, vật phẩm bấm được) dùng `Highlight` với `FillTransparency = 1`, `OutlineColor` đen mực hoặc màu độ hiếm. Mô hình lớn như nhà, đảo hoặc địa hình thì không cần viền.
- **Vật phẩm tương tác:** viền sáng hơn nền, nảy nhẹ lên xuống (biên độ khoảng 0,3 stud, chu kỳ 1,5 giây) để người chơi biết bấm vào đâu.

## 4. Hiệu ứng kiểu anime

Bộ hiệu ứng này là điểm nhận diện chung của game. Dùng vừa đủ ở khoảnh khắc quan trọng, đừng bật liên tục.

### 4.1 Mắt và biểu cảm

- Mắt to, có **đốm sáng** (highlight trắng 1-2 chấm) ở đồng tử. Đây là thứ làm model "ra chất anime" nhất.
- Biểu tượng cảm xúc nổi trên đầu bằng `BillboardGui` hoặc `ParticleEmitter`:

| Cảm xúc | Biểu tượng |
| --- | --- |
| Giận | Gân nổi (ký hiệu `#`) màu đỏ cam |
| Ngạc nhiên | Dấu `!` |
| Bối rối | Dấu `?` hoặc vòng xoáy |
| Mệt hoặc xấu hổ | Giọt mồ hôi xanh nhạt |
| Vui hoặc được thưởng | Tim, sao, hoa lấp lánh |

### 4.2 Chuyển động

- **Squash & stretch:** ép dẹt khi chạm đất, kéo dài khi nhảy, phóng đại hơn mức thực tế.
- **Anticipation:** luôn có 1 nhịp lùi hoặc nén lại (0,1-0,2 giây) trước đòn mạnh hoặc cú nhảy.
- **Hit-stop:** khi trúng đòn, đóng băng 0,05-0,1 giây rồi mới bật ra, tăng cảm giác lực.
- **Smear:** khung chuyển động nhanh thì kéo giãn part theo hướng di chuyển.

### 4.3 Hiệu ứng khi hành động

| Khoảnh khắc | Hiệu ứng |
| --- | --- |
| Chạy, đuổi nhanh | **Speed lines**: vệt trắng chạy dọc theo hướng di chuyển (`Trail` hoặc `ParticleEmitter` dạng vệt), bụi nhỏ ở chân |
| Trúng đòn | **Impact frame**: nháy trắng-đen hoặc đỏ khoảng 2-3 khung hình, kèm hạt "sao nổ" và rung camera nhẹ |
| Đòn mạnh hoặc boss | Hào quang màu phe dưới chân, khói hoặc tia sáng bốc lên, nền hơi tối đi (vignette) |
| Nhận phần thưởng | Chớp sáng, **tia sáng tỏa ra**, hạt lấp lánh và cánh hoa bay. Độ hiếm càng cao thì hiệu ứng càng dài và rực |
| Thăng cấp hoặc nâng cấp | Vòng sáng lan ra từ chân, chữ cấp mới phóng to rồi bật lại (overshoot) |
| Biến hình hoặc xuất hiện boss | Nền tối đột ngột, tia sáng quét, tên boss hiện lên kiểu tiêu đề tập phim |

### 4.4 Môi trường và hậu kỳ

- `Lighting` có `Bloom` nhẹ (Intensity 0,3-0,5) để phần sáng bừng như phim.
- `ColorCorrection` tăng `Saturation` khoảng 0,1-0,2 và `Contrast` nhẹ.
- `Atmosphere` mỏng, bầu trời nhiều màu kiểu hoàng hôn anime.
- Hạt ngoài trời: cánh hoa, lá, bụi sáng bay chậm trong khu thư giãn. Đừng đặt trong khu cần tập trung.

### 4.5 Thời lượng animation tiêu chuẩn

Đủ chậm để mắt kịp theo dõi, đủ nhanh để không chán. Dùng làm mặc định, chỉ lệch khi có lý do.

| Loại | Thời lượng |
| --- | --- |
| Idle lặp | 2,4 giây mỗi vòng, biên độ nhỏ, đầu và cuối trùng tư thế |
| Trạng thái chờ có nhịp (đang ấp, đang cảnh giác) | 2,4 giây mỗi vòng, mỗi nhịp rung 0,2 đến 0,3 giây |
| Hành động ngắn (mổ, thổi còi, dọa) | 0,7 đến 2,4 giây |
| Sự kiện lớn (nở trứng, mở rương, xuất hiện boss) | 4 đến 5 giây (trứng: 5,0 giây) |

- Khoảng cách giữa hai keyframe chính: 0,3 đến 0,5 giây. Không để keyframe nào ngắn hơn 0,15 giây, trừ hit-stop.
- Sự kiện lớn chia nhịp: dồn nhịp khoảng 40 đến 50% thời lượng (rung, nén, nứt dần), bùng nổ trong 0,2 đến 0,4 giây, phần còn lại là bay, đáp và giữ tư thế cuối cho người chơi kịp nhìn.
- Easing mặc định `Cubic` vào ra. Vật rơi và đáp xuống nảy nhẹ một lần rồi nằm yên.
- Hiệu ứng và sound của sự kiện bám đúng mốc giây của animation, và ghi mốc đó vào README của model.

## 5. Giới hạn hiệu năng

Game chạy trên mobile, nên:

- Mỗi hiệu ứng `ParticleEmitter` giữ `Rate` thấp và `Lifetime` ngắn, dùng `Enabled = false` khi ở xa hoặc không thấy.
- `Bloom`, `ColorCorrection` chỉ đặt 1 lần ở `Lighting`, không đặt theo từng khu vực.
- Hiệu ứng của vật phẩm thường và hiếm phải nhẹ, chỉ độ hiếm cao mới được dùng tia sáng và hạt dày.
- `Highlight` bị giới hạn số lượng cùng lúc của Roblox, nên chỉ bật cho vật phẩm gần người chơi.

## 6. Checklist cho mỗi model mới

- [ ] Silhouette nhận ra được khi tô đen
- [ ] Màu lấy từ bảng ở mục 2, tối đa 3 màu chủ đạo cộng 1 màu nhấn
- [ ] Có 1 nét hài rõ ràng
- [ ] Pet, thú, quái: có ngành nghề đọc được từ silhouette (đồ nghề) và ít nhất 1 animation thể hiện công việc
- [ ] Vật phẩm: có linh hồn thú vật (2-3 đặc điểm hoặc cử chỉ thú) nhưng vẫn nhận ra là đồ vật, không ghê rợn
- [ ] Mắt có đốm sáng (nếu có mắt)
- [ ] Phần thưởng có màu và hiệu ứng đúng độ hiếm
- [ ] Animation có anticipation và squash & stretch ở các động tác chính
- [ ] Đặt tên part, khớp theo kiểu `PoliceGoose` để script dùng lại được
