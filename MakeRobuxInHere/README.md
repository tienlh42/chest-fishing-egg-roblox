# Kế hoạch bán vật phẩm bằng Robux

> Dành cho dev và người làm sản phẩm. Cập nhật lần cuối 16/10/2026. **Chỉ là kế hoạch, chưa có dòng code nào.**
> Đọc kèm `../docs/Economy/ECONOMY_DESIGN.md` (kinh tế coins, độ bền, cướp nhà) và `../docs/Overview/PROJECT_OVERVIEW.md` (code hiện tại).

## Các file

| File | Nội dung |
|---|---|
| `README.md` | Mục tiêu, nguyên tắc, quyết định cần chốt (file này) |
| `01_PRODUCTS.md` | Danh mục thứ có thể bán, giá đề xuất, mức rủi ro "trả tiền để thắng" |
| `02_TECHNICAL_PLAN.md` | Cách làm kỹ thuật: nhận tiền, cấp đồ, lưu, chống lỗi |
| `03_COMPLIANCE_AND_RISKS.md` | Chính sách Roblox cần kiểm tra, rủi ro cân bằng, rủi ro pháp lý |
| `04_ROADMAP.md` | Thứ tự làm, từng giai đoạn làm gì, khi nào xong |

## Mục tiêu

Bán Robux **mà không làm hỏng vòng chơi gốc**: lẻn ra hồ, kéo rương trước mũi ngỗng, mang về nhà, ấp trứng, nâng cấp bằng coins kiếm được. Mọi món bán Robux phải trả lời "có" cho cả 3 câu:

1. Người không trả tiền vẫn chơi trọn vẹn và vẫn có thể có món đó bằng coins (hoặc món đó chỉ là đồ trang trí).
2. Món đó **không làm người trả tiền thắng người khác trong cướp nhà**.
3. Món đó **không phá nhịp tiến độ** đã chỉnh trong `docs/Economy/ECONOMY_DESIGN.md` (ví dụ cần Dragon ở khoảng 6 giờ chơi).

## Nguyên tắc

- **Server cấp mọi thứ.** Client chỉ xin mở cửa sổ mua. Không bao giờ tin client nói "tôi đã mua".
- **Chỉ ghi nhận mua khi đã lưu xong.** Lưu lỗi thì báo Roblox thử lại sau, không cấp hai lần.
- **Mọi con số nằm trong `ReplicatedStorage/Config.lua`**, id sản phẩm cũng ở đó (mục `Config.Monetization`).
- **Chữ hiện cho người chơi bằng tiếng Anh**, riêng **bảng Store và mô tả sản phẩm có thêm tiếng Việt** (anh đã duyệt 16/10/2026). Tài liệu bằng tiếng Việt.
- **Không bán những thứ này, kể cả khi người dùng đề nghị sau này mà chưa cân nhắc lại:** Chìa vạn năng, khóa cửa, vật phẩm bảo vệ nhà, sửa chữa độ bền, trứng và pet hiếm nhất trực tiếp. Lý do ở `03_COMPLIANCE_AND_RISKS.md` mục 2.

## Đã chốt (anh Scott, 16/10/2026)

| Câu hỏi | Trả lời | Hệ quả |
|---|---|---|
| Đã publish chưa? | **Chưa** | Giai đoạn 0 phải publish bản riêng tư và tạo sản phẩm giữ chỗ trước khi test mua thật |
| Bán gói coins? | **Có** | Giữ gói theo phút thu nhập, trần mỗi ngày (xem `01_PRODUCTS.md` mục 2) |
| Độ tuổi chính | **13 đến 19 tuổi** | Phải theo quy tắc cho thanh thiếu niên (xem `03_COMPLIANCE_AND_RISKS.md` mục 7) |
| Tiếng Việt cho mô tả sản phẩm | **Có** | Store song ngữ Anh và Việt (xem `02_TECHNICAL_PLAN.md` mục 7) |
| Người chơi chính | **Việt Nam và khu vực quanh đó** | Giá thấp hơn, ưu tiên điện thoại, chọn chính sách theo vùng (xem `01_PRODUCTS.md` mục 10, `03_COMPLIANCE_AND_RISKS.md` mục 1) |

## Quyết định còn lại / ban đầu cần chốt

| # | Câu hỏi | Em đề xuất |
|---|---|---|
| 1 | ~~Đã publish chưa~~ **Chưa, publish bản riêng tư ở giai đoạn 0** | Xong khi có universe id |
| 2 | ~~Bán gói coins~~ **Có** | Gói tính theo số phút thu nhập hiện tại, giới hạn mỗi ngày |
| 3 | Có bán "sửa chữa" không? Anh đã chốt không sửa chữa, nên mặc định không. | Không |
| 4 | Có làm vật phẩm ngẫu nhiên bán bằng Robux (trứng bí ẩn) không? Cần công bố tỉ lệ và bị giới hạn ở một số nước. | Để sau cùng, chỉ chứa đồ trang trí |
| 5 | Có bán gói đăng ký tháng (`Experience Subscriptions`) không? Hợp với hộp thư quà hằng ngày đang tắt trong `Config.House.Daily`. | Có, làm sau gói đơn lẻ |
| 6 | ~~Quốc gia và độ tuổi~~ **Việt Nam và quanh đó, 13 đến 19 tuổi** | Đã chốt |
| 7 | Giá theo Robux, hay muốn mục tiêu doanh thu để em suy ngược lại? | Em đưa giá khởi điểm ở `01_PRODUCTS.md`, chỉnh sau khi có số liệu |

## Tình trạng hệ thống hiện tại (để biết cần chuẩn bị gì)

- **Chưa có** `MarketplaceService`, `ProcessReceipt`, hay mục `Purchases` trong profile.
- **Đã có** khung để gắn vào: `Data.lua` (profile + `Data.Save`), `Remote.Folder.Action` (cách client xin server làm việc), `MainUI.client.lua` (các bảng Shop, Market, Bag), hộp thư quà hằng ngày đang tắt (`Config.House.Daily`).
- **Chưa xong và nên xong trước khi bán thứ liên quan:** kho nhà vô hạn, cướp nhà, ngỗng nhà. Xem `04_ROADMAP.md` phần phụ thuộc.
