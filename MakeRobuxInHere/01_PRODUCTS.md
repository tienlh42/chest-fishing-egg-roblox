# Danh mục sản phẩm đề xuất

> Mọi giá và số lượng là **[ĐỀ XUẤT]**, cần chỉnh khi có số liệu bán thật. Giá Robux nên chọn trong các mức quen thuộc (25, 49, 99, 199, 399, 799, 1499...).
> Cột "Rủi ro P2W" = rủi ro trả tiền để thắng người khác: **Không** (chỉ trang trí) / **Thấp** (tiện lợi, không đổi sức mạnh) / **Trung bình** (đổi tiến độ) / **Cao** (đổi kết quả đối đầu, không bán).

## 1. Kiểu sản phẩm trên Roblox và dùng cho gì

| Kiểu | Mua được mấy lần | Hợp với | Ghi chú kỹ thuật |
|---|---|---|---|
| **Developer Product** | Nhiều lần | Gói coins, tăng tốc ấp, vật phẩm tiêu hao | Cấp qua `ProcessReceipt` |
| **Game Pass** | 1 lần, vĩnh viễn | Tiện ích vĩnh viễn, VIP | Kiểm tra bằng `UserOwnsGamePassAsync` |
| **Subscription** | Gia hạn theo tháng | Gói hội viên | Đăng ký ở Creator Hub, kiểm tra trạng thái ở server |
| **Premium Payouts** | Không bán | Roblox trả theo thời gian người chơi Premium chơi | Không cần code, chỉ cần game hấp dẫn người Premium |

## 2. Gói coins (Developer Product) [rủi ro P2W: Trung bình]

Vấn đề: gói cố định ví dụ "5,000 coins" quá lớn lúc đầu và vô nghĩa lúc cuối. Đề xuất **gói tính theo phút thu nhập**, server tính tại lúc mua:

```
coins nhận = số phút của gói x thu nhập ròng mỗi phút hiện tại của người chơi
```

Thu nhập ròng lấy từ cần đang có và máy câu đang có (cùng công thức `tools/sim_economy.py`), có **sàn** (để người mới không nhận quá ít) và **trần** (để người sắp có cần Dragon không nhảy cóc quá xa).

| Gói | Số phút | Giá | Nhận ở thu nhập 37 coins/phút (đầu game) | Nhận ở 250 coins/phút (cuối game) |
|---|---|---|---|---|
| Pouch | 30 phút | 49 R$ | ~1,100 | ~7,500 |
| Chest | 120 phút | 149 R$ | ~4,400 | ~30,000 |
| Vault | 480 phút | 399 R$ | ~17,800 | ~120,000 |

Giới hạn đề xuất: tối đa **3 gói mỗi ngày**, tổng không quá **8 giờ thu nhập** mỗi ngày. Phải hiện rõ số coins sẽ nhận **trước khi** người chơi bấm mua.

## 3. Tiện lợi và tăng tốc

| Sản phẩm | Kiểu | Giá | Làm gì | Rủi ro P2W |
|---|---|---|---|---|
| **Instant Hatch** | Developer Product | 29 R$ | Xong ngay mọi trứng đang ấp | Thấp (chỉ bỏ thời gian chờ, nhưng nhớ trứng đã ấp vào máy ấp thì an toàn khỏi cướp) |
| **Auto-Collect** | Game Pass | 249 R$ | Thu rương máy câu tự động khi vào nhà, khỏi bấm [E] từng máy | Thấp |
| **Free Teleports** | Game Pass | 149 R$ | Không tốn phí dịch chuyển Lake 20, Shop 10, Home 10 | Thấp |
| **Quick Hatch** | Game Pass | 199 R$ | Thời gian ấp giảm 25% | Thấp |

## 4. Mở rộng nhà

| Sản phẩm | Kiểu | Giá | Làm gì | Rủi ro P2W |
|---|---|---|---|---|
| **Bonus Pedestal** | Game Pass | 399 R$ | Thêm ổ máy câu thứ 6 (chỉ ổ trống, vẫn phải mua máy bằng coins) | Trung bình: thêm thu nhập thụ động, nhưng máy vẫn hao mòn và vẫn phải trả coins |
| **Extra Incubator** | Game Pass | 249 R$ | Thêm máy ấp thứ 5 | Thấp |

Cần chạy lại `tools/sim_economy.py` với ổ thứ 6 trước khi bán, vì ECONOMY_DESIGN đang tính 5 ổ.

## 5. Trang trí (an toàn nhất, nên bán nhiều nhất)

| Sản phẩm | Kiểu | Giá | Ghi chú |
|---|---|---|---|
| **Rod skins** | Developer Product (mua 1 lần, lưu `OwnedCosmetics`) | 99 đến 299 R$ | Đổi màu / hiệu ứng cho 6 cần hiện có (vd. "Gilded Catfish"). Không đổi chỉ số |
| **Pet skins, hat, aura** | Developer Product | 99 đến 399 R$ | Chỉ đổi hình. Không đổi HP, perk, độ bền |
| **House themes** | Developer Product | 149 đến 499 R$ | Đổi màu nhà gỗ, hàng rào, kệ trưng bày (đã có kệ trưng bày pet trong `House.lua`) |
| **Name tag, trail, honk sound** | Developer Product | 49 đến 149 R$ | Nhỏ, rẻ, dễ làm |
| **Starter Cosmetic Bundle** | Developer Product | 299 R$ | Gói 3 món rẻ hơn mua lẻ |

Cần có **bản vật phẩm trang trí độc lập** với dữ liệu đồ chơi (`profile.Cosmetics = { Owned, Equipped }`) để không đụng tới `Rods`, `Pets`.

## 6. Hội viên tháng (Subscription) [rủi ro P2W: Thấp]

**Fisher's Club**, khoảng 99 R$ mỗi tháng (giá do Roblox cho phép chọn trong khoảng cho gói đăng ký). Quyền lợi đề xuất:

- Bật **hộp thư quà hằng ngày** (đã có sẵn trong `Config.House.Daily`, đang tắt): 100 coins + 1 Reed Egg mỗi ngày, quy đổi thành "30 phút thu nhập" nếu muốn tự co giãn theo giai đoạn.
- 1 skin độc quyền theo tháng.
- Name tag "Club".
- **Không có** lợi thế cướp nhà, không giảm độ bền, không tăng tỉ lệ rương.

## 7. Vật phẩm ngẫu nhiên (Mystery Egg) [rủi ro pháp lý và P2W: Cao]

Chỉ làm sau cùng, và chỉ khi anh đã chốt câu hỏi 4 trong README.

- **Bắt buộc công bố tỉ lệ** từng kết quả ngay tại nơi mua (xem `03_COMPLIANCE_AND_RISKS.md`).
- Đề xuất chỉ chứa **đồ trang trí** (skin pet, aura, house theme), **không chứa pet thật hay trứng chơi được**, vì pet quyết định khả năng chống ngỗng và chạy thoát khi cướp.
- Tuyệt đối không cho "trúng" rương Rainbow hay trứng Dragon bằng Robux ngẫu nhiên.

## 8. Không bán (danh sách cấm)

| Thứ | Vì sao không |
|---|---|
| Chìa vạn năng, khóa cửa | Quyết định thắng thua của cướp nhà (xem ECONOMY_DESIGN mục 7) |
| Sửa chữa độ bền | Anh đã chốt không sửa chữa |
| Trứng hay pet hiếm (Gold, Dragon) trực tiếp | Pet quyết định khả năng sống sót trước ngỗng |
| Rương Golden, Rainbow | Phá cân bằng hồ cấm là nguồn tiền chính |
| Khiên sau khi bị cướp | Bán miễn nhiễm cho người trả tiền |
| Cần câu cao cấp trực tiếp | Cần có độ bền và giá coins đã cân bằng; bán trực tiếp bỏ qua nhịp 6 giờ |

## 10. Điều chỉnh cho người chơi Việt Nam và khu vực quanh đó [ĐỀ XUẤT]

- **Sức mua thấp hơn:** thêm mức giá **thấp** (25 R$ và 49 R$ là mức bán chạy nhất, 399 R$ trở lên bán chậm). Mỗi nhóm sản phẩm nên có ít nhất một món dưới 50 R$. Gói coins thêm **Mini 15 phút, 25 R$**.
- **Chủ yếu chơi bằng điện thoại:** nút Store, thẻ sản phẩm, nút mua phải đủ lớn cho cảm ứng (đang có `IS_TOUCH` trong `MainUI.client.lua`). Bảng giá không quá nhiều dòng.
- **Cách người chơi nạp Robux** (thẻ quà tặng, ví điện tử) do Roblox và đối tác quyết định, game không can thiệp; em đề xuất không giả định có thẻ tín dụng.
- **Ngôn ngữ:** chữ hiện cho người chơi vẫn là tiếng Anh theo quy tắc repo. Nên cân nhắc thêm **bản tiếng Việt cho mô tả sản phẩm** (có thể dùng `LocalizationService` của Roblox) vì người mua cần đọc rõ mình mua gì, đặc biệt gói coins và tỉ lệ ngẫu nhiên. Cần anh duyệt vì đổi quy tắc.
- **Mốc thời gian:** nhiều người chơi Việt Nam chơi buổi tối giờ Việt Nam; ngày reset gói coins đang theo UTC (7 giờ sáng giờ VN), nên chọn giờ reset không rơi giữa lúc cao điểm.
- **Roblox Premium** ít phổ biến hơn ở vùng này, nên Premium Payouts không nên là nguồn doanh thu chính.
- **Mô hình doanh thu:** dựa vào nhiều giao dịch nhỏ (trang trí, gói coins nhỏ, gói nhanh ấp) hơn vài giao dịch lớn.

## 9. Gợi ý thứ tự ưu tiên bán (theo rủi ro tăng dần, doanh thu thường giảm dần)

1. Trang trí (an toàn nhất)
2. Tiện lợi vĩnh viễn (Game Pass)
3. Instant Hatch và hội viên tháng
4. Gói coins (cẩn thận cân bằng)
5. Mở rộng nhà (Bonus Pedestal)
6. Vật phẩm ngẫu nhiên (cuối cùng, nếu có)
