# Chính sách và rủi ro

> **Em không xác minh được chính sách Roblox mới nhất trong phiên làm việc này.** Các mục dưới đây là điều em nhớ và **phải kiểm tra lại trên Creator Docs và trang Chính sách của Roblox trước khi bán**. Chính sách thay đổi theo thời gian và theo quốc gia.

## 1. Việc phải kiểm tra trước khi bán

| # | Việc | Vì sao |
|---|---|---|
| 1 | **Chính sách vật phẩm ngẫu nhiên trả tiền** (paid random items): phải công bố tỉ lệ trước khi mua, và một số quốc gia bị hạn chế hoặc cấm | Áp dụng nếu làm Mystery Egg (`01_PRODUCTS.md` mục 7). Repo `roblox-assets` cũng đã nhắc ở `ITEM_SYSTEM_WORKFLOW.md` |
| 2 | **Quy tắc cho game dành cho trẻ em và nhãn độ tuổi** (Maturity / Content Labels) | Quyết định được bán gì và hiển thị thế nào |
| 3 | **Quy định bán tiền tệ trong game** | Gói coins có được không, cách mô tả |
| 4 | **Quy định nội dung quảng cáo trong game**, không dẫn người chơi ra ngoài nền tảng | Tránh bị gỡ |
| 5 | **Thuế, rút tiền (DevEx), điều kiện nhận Robux** | Quyết định kế hoạch doanh thu thực tế |
| 6 | **Điều kiện tạo Subscription** (Experience Subscriptions) | Không phải tài khoản nào cũng đủ điều kiện |

Em đề xuất **anh (hoặc người đứng tên game) đọc các trang này** và ghi lại ngày đã kiểm tra vào cuối file này.

**Theo khu vực của anh (Việt Nam và quanh đó):** em chưa biết rõ từng nước có hạn chế riêng nào với vật phẩm ngẫu nhiên hay độ tuổi. Cần kiểm tra các trang chính sách và danh sách nước bị hạn chế, ghi vào nhật ký mục 6. Nếu không chắc, bỏ giai đoạn 6 (vật phẩm ngẫu nhiên) là cách an toàn nhất. Gói coins có tỉ lệ cố định nên không thuộc diện ngẫu nhiên.

## 2. Vì sao có danh sách không bán

| Không bán | Rủi ro nếu bán |
|---|---|
| Chìa vạn năng | Người trả tiền cướp dễ hơn, người chơi thường bị cướp mà không có cách đối trọng. Dễ gây bỏ game và tố cáo "pay to win" |
| Khóa cửa, khiên, két sắt | Đảo ngược: người trả tiền bất khả xâm phạm, kẻ cướp không còn mục tiêu, cân bằng cướp sụp đổ |
| Sửa chữa độ bền | Anh đã chốt không sửa; bán sửa chữa biến thứ phải mua lại bằng coins thành sink dành cho tiền thật, mâu thuẫn thiết kế |
| Trứng, pet Gold và Dragon | Pet là phòng thủ chống ngỗng và chặn ngỗng khi chạy thoát; bán pet tốt nhất là bán lợi thế sống sót |
| Rương Golden, Rainbow | Phá hồ cấm là nguồn tiền chính và là nơi chịu rủi ro nhiều nhất |

## 3. Rủi ro cân bằng

| Rủi ro | Mô tả | Giảm thiểu |
|---|---|---|
| Gói coins làm lệch tiến độ | Người trả tiền nhảy cóc qua các bậc cần câu, mất cảm giác tiến triển | Tính theo phút thu nhập, trần mỗi ngày, ghi rõ trước khi mua |
| Gói coins và cướp nhà | Người giàu coins nhưng ít rương sẽ không bị cướp nhiều; coins không bị cướp, chỉ rương và trứng bị | Giữ luật coins an toàn như hiện tại |
| Bonus Pedestal thêm thu nhập thụ động | Thu nhập máy là ~30% cuối game | Chạy lại mô phỏng trước khi bán; nếu lệch, giảm tier hoặc tăng giá mua máy |
| Hội viên, Auto-Collect làm mất lý do vào nhà | Nhà là nơi bị cướp, mất tương tác | Giữ Auto-Collect chỉ khi người chơi đang online trong game, vẫn phải tới nhà ít nhất khi cất rương |
| Instant Hatch bỏ khoảng thời gian trứng nằm trong kho | Rút ngắn khoảng "dễ bị cướp" (đã ấp thì an toàn) | Chấp nhận, đó là lợi ích nhỏ, không phải sức mạnh |

## 4. Rủi ro kỹ thuật

| Rủi ro | Giảm thiểu |
|---|---|
| Cấp hai lần hoặc không cấp | `Purchases[PurchaseId]`, lưu trước khi trả `PurchaseGranted`, kiểm thử giả lập (xem `02_TECHNICAL_PLAN.md` mục 4, 9) |
| `DataStore` hiện dùng `SetAsync`, không khóa phiên | Với giao dịch tiền thật nên nâng lên `UpdateAsync` và khóa phiên trước khi mở bán thật |
| Mất dữ liệu cosmetic khi đổi cấu trúc profile | Mọi trường mới thêm qua `reconcile`; có chuyển đổi như đã làm với `Pets`, `Rods` |
| Lộ id sản phẩm trên client | Id không phải bí mật, nhưng mọi quyền lợi phải kiểm ở server |
| Chargeback / hoàn tiền | Roblox xử lý ở nền tảng; có thể cần thu hồi quyền lợi. Chưa xử lý ở giai đoạn đầu, ghi nhận để sau |

## 5. Rủi ro sản phẩm

| Rủi ro | Giảm thiểu |
|---|---|
| Bán quá sớm khi game chưa có đủ người chơi và nội dung | Chỉ bật các sản phẩm ở `04_ROADMAP.md` giai đoạn 2 trở đi khi đã có người chơi thật và số liệu giữ chân |
| Người chơi mới thấy cửa hàng Robux che nhịp chơi đầu | Ẩn nút Store trong 10 phút đầu / trước khi xong hướng dẫn |
| Trang trí phụ thuộc asset chưa có | Làm trước bản recolor bằng code từ model hiện có; skin cần model mới thì giao `roblox-assets` làm |

## 7. Người chơi 13 đến 19 tuổi [ĐỀ XUẤT]

Nhóm tuổi này hay mua theo cảm hứng và thường dùng tiền của người lớn. Quy tắc thiết kế cho Store:

- **Giá và nhận gì phải rõ trước khi bấm mua**, cả hai ngôn ngữ. Không giá ẩn, không "đếm ngược giả" để ép mua.
- **Không bán thứ làm người chơi sợ mất đồ** (ví dụ khiên, khóa) bằng tiền thật, đã nằm trong danh sách không bán.
- **Giới hạn mỗi ngày** cho gói coins (đã có), thêm **nhắc nhẹ** khi mua nhiều lần liên tiếp, và **không có** gói mua lặp tự động ngoài Subscription chính thức của Roblox.
- **Không bán lúc người chơi đang yếu thế** (vừa bị ngỗng bắt hoặc bị cướp): không hiện cửa sổ mua ngay sau sự kiện đó.
- **Không khuyến khích mua bằng áp lực bạn bè** (không so sánh "bạn đã mua").
- Kiểm tra quy định về nội dung và quảng cáo cho nhóm thanh thiếu niên trên trang chính sách Roblox (mục 1 việc 2), và nhớ rằng người dưới 18 có thể cần người lớn đồng ý khi nạp Robux, do Roblox xử lý.

## 6. Nhật ký kiểm tra chính sách

| Ngày | Người kiểm tra | Nội dung đã xác nhận |
|---|---|---|
| (chưa kiểm tra) | | |
