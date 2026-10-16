# Sound guide: vui nhộn, mềm tai, an toàn cho trẻ em

Áp dụng cho mọi âm thanh trong repo (nhân vật, quái, vật phẩm, phần thưởng, giao diện). Đi cùng [docs/Art/STYLE_GUIDE.md](../Art/STYLE_GUIDE.md): hình ảnh chunky cartoon thì âm thanh cũng phải "tròn, nảy, ngố". Đối tượng: bé nam và nữ 13-17 tuổi, nhiều bé chơi bằng tai nghe hoặc loa điện thoại.

## 1. Nguyên tắc tone

- **Cartoon, không thật:** ưu tiên tiếng kiểu hoạt hình như "bốp", "boing", "pop", "tõm", "quác", "ting", chuông, kèn đồ chơi. Tránh âm thanh thật của va đập, đánh đấm hoặc đồ vật vỡ.
- **Dữ dữ dễ thương:** quái và NPC "dữ" chỉ gầm gừ ngố, quác to kiểu hài. Boss được trầm hơn một chút, vẫn không đáng sợ.
- **Cấm hẳn:** tiếng la hét hoặc khóc thật, tiếng súng, nổ lớn, máu, tiếng kinh dị (rít, thì thầm rợn người), còi hú hay báo động kéo dài.
- **Trúng đòn:** dùng "bốp" ngắn kèm tiếng chuông xoay xoay hoặc quác méo. Không dùng tiếng đấm nặng hay tiếng xương.
- **Thất bại là chuyện vui:** ngất, trượt, hụt thì dùng tiếng tụt dốc hài ("wah-wah", "tõm"), không phạt tai người chơi.

## 2. Độ to và độ gắt

Mục tiêu: không bao giờ làm bé giật mình, kể cả khi đeo tai nghe.

| Hạng mục | Quy ước |
| --- | --- |
| Peak của file | Chuẩn hóa về khoảng **0,5 (-6 dBFS)**, không đẩy sát 1. Độ to khi chơi chỉnh bằng `Sound.Volume`, không chỉnh trong file |
| Volume trần | **Không vượt 0,8** cho mọi sound. Còi, cảnh báo, đòn mạnh dùng 0,7-0,8 |
| Tần số | Phần lớn năng lượng nằm trong **200 Hz - 2,5 kHz**. Tiếng cao chói (trên 3 kHz) chỉ dùng cho ting hoặc chuông và phải ngắn dưới 0,3 giây, không kéo dài như còi hú |
| Bass | Không dùng trầm sâu dưới 80 Hz (loa điện thoại không phát được, tai nghe thì nặng ngực) |
| Mở đầu và kết | Fade-out tối thiểu 20 ms để không bị "tách" khi cắt. Không bắt đầu bằng đỉnh to đột ngột kéo dài |
| Độ méo | Không dùng âm bị vỡ, rè hoặc clip. Nếu cần "quác" cho hài thì rè nhẹ, peak vẫn dưới 0,5 |

## 3. Phân cấp độ to theo vai trò

Âm quan trọng nghe rõ hơn, âm nền thì nhẹ. Đây là `Volume` đặt trong script.

| Vai trò | Ví dụ | Volume |
| --- | --- | --- |
| Nền, lặp | Bước chân, vỗ cánh, ngáy, lẩm bẩm chờ | 0,3 - 0,5 |
| Hành động thường | Mổ, mở rương, nhặt đồ | 0,5 - 0,6 |
| Biểu cảm, phản ứng | Giật mình, ngạc nhiên, ngất | 0,6 - 0,7 |
| Cảnh báo, đòn | Còi, trúng đòn, dọa | 0,7 - 0,8 |
| Phần thưởng | Chuông nhận đồ | 0,5 (Thường) tăng dần tới 0,8 (Thần thoại) |

Tín hiệu nguy hiểm (còi, cảnh báo) vẫn phải nổi lên giữa các hiệu ứng hài, như GDD yêu cầu. Cách làm nổi là **tông riêng và nhịp riêng**, không phải to hơn. Tiếng còi dùng một tông trung đặc trưng, hai hồi ngắn, không dùng tông rít cao.

## 4. Độ dài

| Loại | Độ dài |
| --- | --- |
| Bước chân, vỗ cánh (lặp) | ≤ 0,15 giây mỗi tiếng, lặp theo nhịp animation |
| Hành động, phản ứng | 0,3 - 1,2 giây |
| Biểu cảm dài (ngất, dọa) | ≤ 2,5 giây |
| Âm lặp theo chu kỳ (ngáy, đánh hơi) | Đúng bằng chu kỳ animation, đuôi tắt hẳn trước khi lặp lại |
| Phần thưởng | 1 - 2 giây, độ hiếm càng cao càng dài |

Âm chỉ cần đủ để người chơi hiểu chuyện gì vừa xảy ra, tránh kéo dài hơn animation.

## 5. Phần thưởng

- Dùng chuông, ting, nốt **thang ngũ cung** (nghe vui, khó bị lạc tông).
- Độ hiếm càng cao thì càng **nhiều nốt và đuôi vang dài hơn**, không phải to hơn nhiều:

| Độ hiếm | Gợi ý |
| --- | --- |
| Thường | 1 nốt, ngắn |
| Hiếm | 2 nốt |
| Sử thi | 3 nốt |
| Huyền thoại | 4 nốt và thêm 1 nốt cao nhỏ |
| Thần thoại | 6 nốt chạy lên, đuôi vang dài nhất |

- Phần thưởng luôn nghe "ấm" và tích cực. Không dùng chuông nhạc chói hay nốt lệch tông.

## 6. Cách đặt trong Roblox

- Âm trong thế giới phải là âm 3D: `Sound` đặt trong Part của model, `RollOffMaxDistance` khoảng 60-80 stud. Âm giao diện (UI) thì phát 2D, đặt trong `SoundService` hoặc GUI.
- Mỗi model có một script client `<Model>Sounds.client.luau` với bảng id ở đầu file, id trống thì im lặng (mẫu: `PoliceGoose/GooseSounds.client.luau`).
- Âm lặp phải dừng khi animation đổi, không chồng tiếng chính nó.
- Mobile: nhiều NPC cùng chạy thì dễ thành "mưa tiếng". Âm nền (bước chân, vỗ cánh) chỉ phát khi người chơi ở gần, còn âm hành động quan trọng mới phát xa hơn.
- Định dạng: `.wav` mono 44,1 kHz 16-bit, hoặc `.ogg` nếu cần nhẹ. Đặt tên `<model>_<action>.wav`, ví dụ `goose_whistle.wav`.

## 7. Nguồn âm thanh

- Âm tự tổng hợp bằng code (`Sounds/build_sounds.py`) dùng cho bản nháp và các tiếng đơn giản. Muốn tiếng hay hơn thì thay bằng âm thu sẵn.
- Âm tải về phải **cho dùng thương mại** (CC0, hoặc gói SFX mua có license). Không lấy âm từ phim, game, nhạc có bản quyền.
- Mỗi file âm thu sẵn ghi lại nguồn và license vào bảng cuối `README.md` của model đó, để khi Roblox kiểm duyệt hay bị khiếu nại thì tra được.
- Mọi âm đều được kiểm duyệt khi upload lên Creator Hub, nên chuẩn tone ở mục 1 cũng giúp qua duyệt dễ hơn.

## 8. Checklist cho mỗi sound mới

- [ ] Nghe là thấy vui hoặc ngố, không giật mình, không đáng sợ
- [ ] Peak của file khoảng 0,5, `Volume` trong script không quá 0,8
- [ ] Phần lớn năng lượng trong 200 Hz - 2,5 kHz, tiếng cao chói dưới 0,3 giây
- [ ] Độ dài đúng bảng mục 4 và khớp thời điểm animation
- [ ] Có fade-out, không bị tách hay clip
- [ ] Âm lặp có đuôi tắt hẳn trước khi lặp lại và dừng khi đổi animation
- [ ] Âm quan trọng được làm nổi bằng tông và nhịp, không bằng độ to
- [ ] Có nguồn và license rõ ràng (nếu không phải tự tổng hợp)
- [ ] Đã nghe thử cả bằng tai nghe lẫn loa điện thoại, cả khi có nhạc nền
