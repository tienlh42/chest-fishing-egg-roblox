# Hồ Không Cho Câu

Tài liệu thiết kế cốt truyện và cơ chế chơi

Roblox Studio | Solo developer | Phiên bản 2.0 | 13/10/2026

Hồ Không Cho Câu là game câu trộm rương và trứng tại một hồ được các linh thú kỳ quặc canh gác. Người chơi giữ nút câu để kéo đồ lên, trong khi pet chống đỡ bảo vệ. Khi pet kiệt sức, người chơi phải bỏ món đang câu và chạy về nơi an toàn để hồi phục.

Tên và hướng cốt truyện hài đã được chốt. Tài liệu này cụ thể hóa hướng đó thành một vòng chơi đơn giản, có thể thử nghiệm. Phạm vi MVP, chỉ số, thời lượng và danh sách nội dung là đề xuất triển khai; cần điều chỉnh sau khi chơi thử.

## 1. Các quyết định cốt lõi

| Thành phần | Hướng đã chọn |
| --- | --- |
| Cốt truyện | Một người câu cá hiểu biển CẤM CÂU theo nghĩa cấm câu cá, nên tiếp tục câu rương và trứng. |
| Phần thưởng | Rương chứa vật phẩm, tiền hoặc trang bị tăng tốc. Trứng chứa pet. |
| Thao tác | Một nút tương tác với ba trạng thái Kéo, Giữ và Hụt. |
| Áp lực | Pet giữ chân bảo vệ trong thời gian câu; HP pet giảm khi bị tấn công. |
| Nhịp chơi | Lén tiếp cận, câu, quyết định lấy thêm hoặc rút lui, cất đồ và hồi pet. |

## 2. Mục tiêu của bản đầu

Hoàn thành một chuyến câu từ nơi an toàn đến hồ rồi trở về. Người mới hiểu thao tác sau một lần hướng dẫn, nhận biết khi pet gặp nguy hiểm và chủ động quyết định rút lui.

Thiết kế kế thừa pet vĩnh viễn, kho an toàn và luật rủi ro trong GDD WILDBOUND trước đó. Hoạt động chính chuyển sang câu trộm; phòng thủ căn cứ theo đợt được hoãn khỏi bản thử nghiệm này.

## 3. Cốt truyện và nhân vật

### Đoạn mở đầu

Nhân vật chính là người câu cá chưa từng câu được cá. Một hôm, anh đến hồ có tấm biển CẤM CÂU. Anh đọc rất kỹ, kết luận rằng biển chỉ cấm câu cá, rồi thả cần. Thứ nổi lên là một cái rương chứa tiền, đôi dép chạy nhanh và tờ giấy: “Nếu bị phát hiện, chúng tôi không quen bạn.”

Quả trứng tiếp theo nở ra một pet đội nồi cơm điện. Nó nhìn rương, nhìn ngỗng bảo vệ đang chạy tới, rồi nói: “Anh câu đi. Nhưng đừng lâu quá.” Từ đó, hai nhân vật cùng câu trộm đồ và chạy về quầy nghỉ mỗi khi bảo vệ nổi giận.

### Cách phát triển câu chuyện

Mục tiêu dài hạn là mở thêm điểm câu, thu thập pet kỳ quặc và tìm xem hồ còn giấu thứ gì. Mỗi khu mới có một lý do vô lý để tồn tại: bảo vệ đổi ca, rồng thất lạc tiền ăn trưa hoặc bộ phận kiểm kê chuyển rương sang hồ bên cạnh. Game không cần một câu đố lịch sử hay một kết thúc bắt buộc.

| Nhân vật | Vai trò | Mẫu thoại |
| --- | --- | --- |
| Người câu | Chủ động gây chuyện và mang đồ về. | “Tôi có câu cá đâu?” |
| Pet đồng hành | Giữ chân bảo vệ và báo nguy hiểm. | “Anh câu xong chưa?!” |
| Ngỗng bảo vệ | Kẻ đuổi bắt đầu tiên. | “Đứng lại để tôi cắn!” |
| Rồng kế toán | Bảo vệ rương ở khu sau. | “Đó là tiền ăn trưa!” |
| Cô bán mồi | Hướng dẫn và chăm pet tại nơi an toàn. | “Ở đây nghỉ được. Trả nợ thì tính sau.” |

### Hài qua hành động

Bảo vệ thổi còi trước khi đuổi. Khi đến ranh giới nơi an toàn, nó giơ biển “Hết phạm vi trách nhiệm” rồi quay về. Câu hụt làm rương bật nắp như đang cười trước khi chìm. Các đoạn này ngắn, không che thanh tiến độ hoặc trì hoãn việc bỏ chạy.

## 4. Vòng chơi và bố cục hồ

Mỗi chuyến đi bắt đầu ở quầy nghỉ. Người chơi chọn pet, kiểm tra HP rồi đi đến một điểm câu. Sau khi lấy đồ, họ quyết định quay về cất hoặc tiếp tục mạo hiểm. Chuyến đi thành công khi chiến lợi phẩm được gửi vào kho.

| Bước | Hoạt động | Quyết định của người chơi |
| --- | --- | --- |
| 1 Chuẩn bị | Pet hồi phục; kiểm tra túi và chọn đường. | Mang pet nào, còn bao nhiêu chỗ? |
| 2 Tiếp cận | Quan sát ngỗng và đi qua nơi che khuất. | Đi ngay hay đợi bảo vệ quay lưng? |
| 3 Câu | Giữ nút; theo dõi tiến độ và HP pet. | Cố hoàn tất hay nhả nút để chạy? |
| 4 Rút lui | Mang đồ về qua đường ngắn hoặc đường kín. | Cất đồ ngay hay câu thêm một món? |
| 5 Cất và hồi | Đồ được bảo vệ; mở rương, nở trứng. | Dùng phần thưởng và chuẩn bị lượt tiếp. |

### Bản đồ thử nghiệm

Một hồ nhỏ có ba điểm câu và một nơi an toàn. Điểm gần bờ dễ tiếp cận, điểm giữa có đường tuần tra đi ngang, điểm xa có phần thưởng hấp dẫn hơn. Hai đường về gồm cầu gỗ ngắn nhưng dễ bị thấy và đường lau sậy dài hơn nhưng có chỗ nấp.

Mỗi điểm câu hiển thị trước loại mục tiêu là rương hoặc trứng. Phần thưởng bên trong chưa biết. Khi một món được lấy hoặc câu hụt, điểm đó tạm nghỉ trước khi xuất hiện mục tiêu mới. Khoảng nghỉ phải được báo bằng hình ảnh hoặc đồng hồ ngắn.

### Luật lén lút đơn giản

Trong MVP, ngỗng đi theo các mốc tuần tra cố định. Nó phát hiện người chơi khi có đường nhìn rõ ở cự ly gần hoặc nghe tiếng câu trong phạm vi quy định. Đá và lau sậy là nơi che khuất đã được đánh dấu rõ trên bản đồ.

Thao tác câu tạo tiếng động sau một khoảng ngắn. Khi chưa có bảo vệ đến, pet đứng cạnh người chơi. Khi bảo vệ áp sát, pet tự chặn; người chơi không phải bấm thêm lệnh chiến đấu.

## 5. Thao tác Kéo Giữ và Hụt

Dùng một nút trên PC và một nút lớn trên điện thoại. Ở điểm câu hợp lệ, người chơi nhấn và giữ để bắt đầu. Động tác kéo mở đầu chuyển thẳng sang trạng thái giữ, nên không cần bấm hai lần.

| Trạng thái | Thao tác | Kết quả |
| --- | --- | --- |
| Kéo | Nhấn nút khi đứng tại điểm câu. | Cần thả ra, móc mục tiêu; hiện thanh tiến độ. |
| Giữ | Tiếp tục giữ nguyên nút. | Thanh tăng đều; vật phẩm từ từ lên bờ. |
| Thành công | Giữ đến khi thanh đầy. | Máy chủ đưa một món vào túi và kết thúc câu. |
| Hụt | Nhả sớm, rời điểm, nhân vật bị hạ hoặc pet kiệt sức. | Món đang câu rơi xuống nước; tiến độ bị hủy. |

### Các quy tắc cần thống nhất

- Nhả nút luôn hủy lượt đang câu; không có trạng thái tạm dừng giữ lại tiến độ.
- Nhả nút sau khi đã thành công không xóa vật phẩm vừa nhận.
- Pet về 0 HP trong lúc câu làm lượt câu thất bại. Các món đã lấy trong túi vẫn còn cho đến khi người chơi bị hạ hoặc cất chúng.
- Túi đầy thì không được bắt đầu lượt mới; hiện thông báo quay về cất đồ.
- Mỗi người chỉ có một lượt câu đang hoạt động. Mỗi mục tiêu chỉ được một người móc tại một thời điểm.
- Bấm lặp không tăng tốc, không tạo nhiều phần thưởng. Nếu HP pet về 0 cùng lúc thanh đầy, máy chủ ưu tiên hủy lượt; giao diện báo Hụt.

### Phản hồi trên màn hình

Thanh câu đặt gần trung tâm; HP pet nằm ngay cạnh. Khi pet yếu, thêm biểu tượng cảnh báo và tiếng gọi ngắn. Vật phẩm càng gần bờ càng hiện rõ. Hụt có tiếng “tõm”; thành công có âm thanh ngắn và biểu tượng món vừa nhận.

Không có kim chạy để căn, thanh độ căng dây hay chuỗi bấm nhanh trong MVP. Sự căng thẳng đến từ thời gian kéo, HP pet và khoảng cách về nơi an toàn.

## 6. Pet và thú canh gác

### Pet tự động bảo vệ

Người chơi mới nhận trứng khởi đầu miễn phí từ cô bán mồi và nở pet tại quầy trước chuyến đi nguy hiểm. Đề xuất MVP cho trang bị một pet tại một thời điểm; giới hạn ba pet trong GDD cũ được hoãn. Bộ sưu tập vẫn chứa nhiều pet.

Khi ngỗng đến gần, pet tự chặn và tấn công bằng động tác đơn giản. Đòn pet khiến ngỗng khựng lại ngắn, nhưng ngỗng không bị tiêu diệt trong MVP. Người chơi vẫn phải rút về để hồi pet.

HP là chỉ số duy nhất của pet ở bản đầu. Về 0 HP, pet thu vào hiệu ứng bong bóng và tự trở về quầy nghỉ. Người chơi mất lớp bảo vệ nhưng vẫn điều khiển nhân vật để chạy hoặc trốn. Pet không bị mất vĩnh viễn.

### Hồi phục ở nơi an toàn

Pet bắt đầu hồi khi chủ trở về quầy nghỉ; chỉ đứng ngoài hồ không hồi HP. Rời quầy sớm thì hồi dừng ở mức hiện tại. Pet còn 0 HP không thể đi câu. Khi HP lớn hơn 0 nhưng chưa đầy, giao diện báo nguy hiểm và cho phép quay lại.

| Pet đề xuất | Vai trò sau prototype | Tình huống hài |
| --- | --- | --- |
| Mèo đội nồi | Pet đầu tiên, chống đỡ cơ bản. | Gõ nồi báo động khi yếu. |
| Vịt cơ bắp | Chịu đòn lâu hơn. | Tạo dáng rồi bị ngỗng đẩy. |
| Chó bánh mì | Hỗ trợ rút về ở bản sau. | Làm rơi vụn bánh lúc chạy. |

### Hành vi ngỗng bảo vệ

Ngỗng tuần tra, dựng cổ báo nghi ngờ, chạy đến vị trí vừa phát hiện rồi tấn công pet. Khi pet không còn bảo vệ, nó đuổi người chơi. Mất dấu thì tìm ở vị trí cuối cùng trước khi quay lại tuần tra. Tại nơi an toàn, nó dừng ở ranh giới và không gây sát thương.

Sau khi người chơi thoát, ngỗng còn kiểm tra điểm câu cũ trong một khoảng ngắn. Việc quay lại ngay vì thế có rủi ro. Ngỗng không đứng chặn cửa quầy nghỉ và không kéo mục tiêu khác vào trong nơi an toàn.

## 7. Rương Trứng và tiến trình

Rương và trứng vừa câu nằm trong túi ở trạng thái chưa an toàn. Người chơi mang về quầy nghỉ và bấm Cất đồ; sau khi lưu thành công, rương có thể mở và trứng có thể nở. Cách này giúp luật mất đồ dễ hiểu và tránh cộng tiền hoặc tăng tốc giữa lúc đang bị đuổi.

| Loại | Nội dung đề xuất | Cách sử dụng |
| --- | --- | --- |
| Rương tiền | Một lượng tiền trong game. | Cộng vào ví sau khi mở tại quầy. |
| Rương đồ | Đồ hồi pet hoặc vật phẩm vui. | Cất vào kho, dùng khi chuẩn bị. |
| Rương tốc chạy | Trang bị như Dép Tên Lửa. | Trang bị tại quầy, áp dụng ở lượt sau. |
| Trứng | Một pet từ nhóm kết quả đã cấu hình. | Nở tại quầy, ghi vào bộ sưu tập. |

### Tốc chạy và sức mạnh

Trang bị tốc chạy là tài sản lâu dài sau khi đã cất. Chỉ trang bị một món tăng tốc; các món không cộng dồn vô hạn. Đề xuất bản đầu giới hạn tăng khoảng 10 phần trăm và kiểm tra lại đường chạy để không làm mất cảm giác bị đuổi.

Trong MVP, tiền dùng cho một hoặc hai nâng cấp rõ ràng, chẳng hạn tăng số ô túi hoặc mua một trang bị biết trước công dụng. Giá mua chỉ chốt sau khi đo lượng tiền kiếm được qua chơi thử. Người chơi không cần trả tiền để có lại cần câu hay pet đầu tiên.

### Trứng và pet trùng

Trứng chỉ kiếm từ gameplay trong MVP. Quả đầu tiên cho pet cố định để hướng dẫn; các quả sau dùng bảng kết quả cấu hình. Xác suất chưa chốt trong tài liệu này. Một pet trùng trở thành bản sao riêng trong bộ sưu tập, không tự bị xóa hay đổi thành tiền.

### Luật mất đồ

Đề xuất bản đầu dùng luật bắt đơn giản: ngỗng chạm được người chơi khi pet không còn chặn thì người chơi bị bắt và trở lại quầy nghỉ. Không cần thêm thanh HP nhân vật trong prototype.

- Nhân vật bị hạ ngoài nơi an toàn: mất rương và trứng chưa cất trong túi.
- Pet kiệt sức: chỉ làm mất món đang câu; người chơi còn cơ hội mang các món đã lấy về.
- Pet sở hữu, ví tiền đã cộng, trang bị đã cất và đồ trong kho được giữ.
- Thoát hoặc mất kết nối ngoài nơi an toàn không tự chuyển đồ trong túi thành đồ trong kho.

## 8. Giao diện và thông số thử nghiệm

Giao diện cần giúp người chơi nhìn được ba điều cùng lúc: món đang câu, tiến độ kéo và HP pet. Túi đồ cùng hướng về quầy nghỉ hiển thị ở cạnh màn hình. Có cả chữ, biểu tượng và âm thanh để tín hiệu nguy hiểm không phụ thuộc riêng vào màu.

| Thông số | Giá trị khởi điểm | Cần kiểm tra |
| --- | --- | --- |
| Thời gian rương thường | 6 giây | Người mới hoàn tất được lượt đầu. |
| Thời gian trứng | 10 giây | Có áp lực nhưng đủ cơ hội rút. |
| Thời gian rương lớn | 14 giây | Phần thưởng xứng với rủi ro. |
| HP pet | 100 | Dễ đọc và dễ so sánh. |
| Mức gây hại lên pet | 5 HP mỗi giây khi ngỗng đánh | Khoảng 20 giây chống đỡ nếu không có ngắt đòn. |
| Cảnh báo pet yếu | 30 HP | Còn khoảng 6 giây trước khi kiệt sức. |
| Hồi pet từ 0 đến đầy | 40 giây tại quầy | Có hoạt động trong lúc hồi. |
| Túi ban đầu | 4 ô; mỗi rương hoặc trứng 1 ô | Không phải về sau mọi món. |
| Đường về | Khoảng 6 đến 10 giây chạy | Vẫn có cơ hội thoát khi pet yếu. |
| Tốc chạy từ trang bị | Tối đa cộng 10 phần trăm ở bản đầu | Đuổi bắt vẫn tạo áp lực. |

Đây là thông số thiết kế để thử, không phải dữ liệu người chơi hoặc cân bằng đã xác nhận. Thời gian thú di chuyển, đòn pet gây khựng và đường chạy làm kết quả thực tế khác phép tính đơn giản trên.

### Một tình huống để kiểm tra cảm giác chơi

Người chơi lấy được rương thường, rồi thấy trứng ở điểm gần đó. HP pet còn ít nhưng người chơi giữ nút thêm. Thanh câu gần đầy thì pet kêu báo nguy hiểm. Người chơi có thể nhả nút để giữ rương đã lấy, hoặc cố kéo trứng và chấp nhận phải tự chạy khi pet gục. Quay về quầy, họ cất đồ, mở rương và chăm pet trước lượt tiếp.

## 9. Phạm vi MVP và cách triển khai

MVP là phiên bản nhỏ nhất đủ chơi trọn một chuyến câu. Ưu tiên chơi một người trước; kiểm thử nhiều người để phát hiện lỗi tranh điểm câu, phần thưởng lặp hoặc mục tiêu ngỗng đổi sai. Kế hoạch dưới đây là thứ tự công việc, không phải cam kết thời gian hoàn thành.

| Giai đoạn | Làm trước | Kết quả cần thấy |
| --- | --- | --- |
| 1 Vòng câu | Một hồ, một quầy nghỉ, ba điểm câu, Kéo Giữ Hụt và túi. | Lấy một rương và mang về cất. |
| 2 Nguy hiểm | Một ngỗng, tuần tra, pet chặn, HP và rút về. | Có lựa chọn hoàn tất hoặc bỏ chạy. |
| 3 Tiến trình | Mở rương, nở trứng, bộ sưu tập, tiền và lưu dữ liệu. | Vào lại vẫn còn đồ đã cất. |
| 4 Chơi thử | PC và mobile, cân bằng, mất kết nối, nhiều người. | Không còn lỗi chặn vòng chơi. |

### Tổ chức từ GDD hiện có

Giữ PlayerDataService, InventoryService và PetService làm điểm xuất phát. Bổ sung FishingService cho lượt câu, GuardianService cho ngỗng và SafeZoneService cho việc cất đồ và hồi pet. Cấu hình pet, rương, trứng và thời lượng tách thành các bảng dễ chỉnh. Các tên này là cấu trúc đề xuất, chưa phải mã đã triển khai.

Dùng một Place với quầy nghỉ và hồ trong cùng bản đồ. Tạm hoãn chu kỳ phòng thủ theo đợt, boss, xây căn cứ, đói khát, giao dịch, nhiều hồ và mở trứng bằng Robux. Sau prototype, chỉ thêm một hệ thống khi nó cải thiện chuyến câu hoặc tiến trình sưu tầm.

### Các hành động do máy chủ quyết định

- Xác nhận vị trí, túi còn chỗ, pet hợp lệ và quyền chiếm điểm câu trước khi bắt đầu.
- Tính tiến độ, sát thương và điều kiện thành công; client chỉ gửi nhấn hoặc nhả nút.
- Mỗi lượt câu và mỗi lần mở đồ chỉ cấp phần thưởng một lần.
- Chỉ báo đã cất sau khi dữ liệu được lưu; lưu thất bại phải giữ trạng thái để thử lại.
- Nếu tải dữ liệu thất bại, không ghi dữ liệu rỗng đè lên bộ sưu tập cũ.

## 10. Chơi thử và hướng mở rộng

### Checklist trước khi mời người khác chơi

- Người mới nhận pet và hoàn tất hướng dẫn mà không cần người phát triển giải thích.
- PC và mobile đều nhấn giữ, nhả để hủy và chạy khỏi điểm câu được.
- Thành công cấp đúng một món; bấm lặp hoặc hai người dùng một điểm không nhân đôi đồ.
- Pet về 0 hủy món đang câu; người chơi vẫn có thể chạy mang đồ cũ về.
- Bị hạ mất đồ chưa cất nhưng không mất pet, tiền hoặc trang bị đã bảo vệ.
- Quầy nghỉ chặn sát thương; pet hồi đúng và dừng hồi khi chủ rời quầy.
- Thoát rồi vào lại giữ đồ đã cất; không dùng thoát game để biến đồ chưa cất thành đồ an toàn.

### Những điều cần ghi khi thử

Ghi số người hoàn tất lượt đầu, số lượt câu thành công và hụt, thời điểm pet kiệt sức, số người trở về với chiến lợi phẩm và số lần quay lại hồ sau khi nghỉ. Hỏi người chơi vì sao họ nhả nút hoặc cố câu tiếp. Đây là dữ liệu cần thu; tài liệu chưa đặt một tỷ lệ thành công chuẩn.

Nếu người chơi luôn câu được mà không nhìn HP pet, tăng áp lực hoặc thời gian kéo. Nếu luôn thất bại ở lượt đầu, giảm áp lực gần bờ. Nếu họ đứng yên chờ pet quá lâu, rút thời gian hồi và làm rõ hoạt động mở rương, nở trứng tại quầy.

### Mở rộng khi vòng chơi đã ổn

| Nội dung sau MVP | Tác dụng |
| --- | --- |
| Rồng kế toán và hồ mới | Thêm cách canh gác và phần thưởng mới. |
| Pet trinh sát hoặc tạo khói | Cho thêm cách tiếp cận và thoát. |
| Nhiệm vụ của cô bán mồi | Tạo mục tiêu ngắn để quay lại. |
| Bảo vệ ngủ gật hoặc đổi ca | Thêm thời điểm thuận lợi, không đổi thao tác câu. |
| Chơi hợp tác có chia vai | Một người câu, một người đánh lạc hướng; cần thiết kế chia thưởng riêng. |

### Cơ sở của tài liệu

Tài liệu được viết từ GDD WILDBOUND Hatch and Survive phiên bản 1.0 và các quyết định trong cuộc trao đổi ngày 13/10/2026. Cốt truyện, nhân vật và chỉ số là nội dung thiết kế sáng tạo. Pháp lý, chính sách phát hành và thiết kế kiếm tiền cần một lần rà soát riêng trước khi triển khai các tính năng đó.
