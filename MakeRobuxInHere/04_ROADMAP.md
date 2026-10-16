# Lộ trình xây dựng

> Mỗi giai đoạn chạy được độc lập, có thể dừng sau bất kỳ giai đoạn nào. Thời gian là ước lượng số buổi làm việc của một người, không phải lịch cố định.

## Phụ thuộc vào phần game

| Phần bán | Cần xong trước |
|---|---|
| Hạ tầng mua (giai đoạn 1) | Không phụ thuộc, làm được ngay |
| Trang trí | Không phụ thuộc kinh tế |
| Tiện lợi (Auto-Collect, Free Teleports, Quick Hatch) | Bước 1 đến 4 của ECONOMY_DESIGN (**đã xong**, nhưng chưa test trong Studio) |
| Gói coins | **Cần đo thu nhập thật ngoài game** (3 số em đang giả định: tỉ lệ mất túi, rương/phút khi 4 đến 8 người, thời gian chạy về nhà). Đừng bán trước khi có số đo |
| Bonus Pedestal | Chạy lại `tools/sim_economy.py` với 6 ổ |
| Hội viên (hộp thư quà) | Bật lại `Config.House.Daily` |
| Mọi thứ liên quan cướp nhà | **Không bán gì liên quan cướp.** Chỉ cần cướp nhà xong khi muốn kiểm tra xem Auto-Collect có làm mất lý do vào nhà không |

## Giai đoạn 0: Chuẩn bị (1 buổi, không code)

- Chốt các quyết định trong `README.md`.
- Kiểm tra chính sách (`03_COMPLIANCE_AND_RISKS.md` mục 1), ghi vào nhật ký.
- **Game chưa publish:** publish experience bản riêng tư (không công khai), tạo sản phẩm giữ chỗ trên Creator Hub, lấy id. Chưa có universe id thì không test mua thật được.
- Chốt bảng chữ song ngữ Anh và Việt cho Store và quy tắc cho tuổi 13 đến 19 (`03_COMPLIANCE_AND_RISKS.md` mục 7).
- Thêm mức giá thấp cho người chơi Việt Nam (`01_PRODUCTS.md` mục 10).
- Chọn giá khởi điểm theo `01_PRODUCTS.md`.

**Xong khi:** có danh sách sản phẩm với id, giá, và nhật ký chính sách có ngày.

## Giai đoạn 1: Hạ tầng mua (2 đến 3 buổi)

- `Monetization.lua` với một `ProcessReceipt` duy nhất, `Purchases` trong profile, chống cấp hai lần, hoàn tác khi lưu lỗi.
- `Config.Monetization`, `Monetization.Has`, kiểm tra Game Pass khi vào game.
- Bảng **Store** rỗng trong `MainUI.client.lua`, công tắc giả lập mua ở Studio.
- Một sản phẩm thử đơn giản nhất: **Instant Hatch**.
- Kiểm thử theo `02_TECHNICAL_PLAN.md` mục 9.

**Xong khi:** mua Instant Hatch thật bằng tài khoản test thành công một lần, giả lập mua hai lần không cấp hai lần, `selene .` sạch, test trong Studio xong.

## Giai đoạn 2: Tiện lợi vĩnh viễn (2 buổi)

- Free Teleports, Quick Hatch, Auto-Collect, Extra Incubator (xem `01_PRODUCTS.md` mục 3, 4).
- Mỗi cái là một Game Pass; chỗ cắm ở `02_TECHNICAL_PLAN.md` mục 6.

**Xong khi:** từng pass có và không có đều chơi được, quyền lợi áp ngay sau khi mua (không phải vào lại game).

## Giai đoạn 3: Trang trí (3 đến 6 buổi, tùy số skin)

- `profile.Cosmetics` (`Owned`, `Equipped`), bảng chọn trang trí trong Bag.
- 6 skin cần (recolor bằng code từ model hiện có), vài skin pet, name tag, honk sound.
- Chuyển sang model riêng khi `roblox-assets` có sẵn.

**Xong khi:** mua, trang bị, cất, đổi, và trang trí giữ nguyên sau khi vào lại game.

## Giai đoạn 4: Gói coins có giới hạn (2 buổi)

- Có thêm gói Mini 15 phút, 25 R$ (đã chốt bán gói coins).
- Chuyển công thức thu nhập ròng từ `tools/sim_economy.py` sang Luau (server).
- Sàn, trần, giới hạn mỗi ngày; hiện số coins sẽ nhận trước khi mua.
- Chỉ làm sau khi đã đo 3 số thật ngoài game.

**Xong khi:** gói không bao giờ cho nhiều hơn trần, không bao giờ ít hơn sàn, giới hạn ngày hoạt động theo UTC.

## Giai đoạn 5: Hội viên tháng và quà hằng ngày (2 buổi)

- Bật lại `Config.House.Daily` cho hội viên; xử lý trạng thái hết hạn.
- Skin độc quyền mỗi tháng, name tag Club.

**Xong khi:** đăng ký, nhận quà, hủy, quà dừng đúng lúc.

## Giai đoạn 6 (tùy chọn): Vật phẩm ngẫu nhiên

- Chỉ làm khi đã chốt câu hỏi 4 trong README và đã kiểm tra chính sách.
- Bảng tỉ lệ công bố, chỉ chứa trang trí, giới hạn theo quốc gia nếu cần.

## Giai đoạn 7: Vận hành

- Theo dõi doanh thu, tỉ lệ mua, món bán chạy, khiếu nại "mua mà không nhận".
- Hàng tuần xem lại `tools/sim_economy.py` và dữ liệu thật, chỉnh giá và giới hạn.
- Sự kiện theo mùa và sản phẩm giới hạn (sau khi có người chơi quay lại đều).

## Thứ tự đề xuất theo giá trị

Giai đoạn 0 → 1 → 3 (trang trí, an toàn nhất) → 2 → 5 → 4 → 6.

Gói coins đứng sau trang trí và tiện lợi vì rủi ro lệch cân bằng cao nhất và cần số đo thật.
