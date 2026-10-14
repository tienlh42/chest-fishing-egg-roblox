# Kế hoạch sửa lỗi đợt 1 (chờ duyệt, CHƯA sửa code)

> Trạng thái: **ĐÃ LÀM, chưa test trong Studio** (13/10/2026). Đã chốt: cấm bơi (dịch về chỗ đứng vững), bị bắt về nhà, Stash góc phải gần cửa, phao rơi cố định 15 stud, mọi toast 3 giây. Mỗi mục có: nguyên nhân tìm được trong code, cách sửa, file đụng tới.
> Mục 6 là các lỗi khác tôi mò ra thêm. Đánh dấu cái nào làm / bỏ, và trả lời mục 7.
> Chữ hiển thị cho người chơi vẫn là tiếng Anh, comment trong code là tiếng Việt.

---

## 1. Ngỗng rơi xuống hồ và không bắt được nhân vật

**Nguyên nhân (trong `Guard.lua`):**

| # | Chỗ | Vì sao hỏng |
|---|---|---|
| a | `stepChase`: `g.Direct = visible and distance < 40` rồi `humanoid:MoveTo(dest)` | Khi đuổi gần, ngỗng đi **đường thẳng** tới người chơi, không theo pathfinding. Lối gạch quanh hồ là đường cong lồi nên dây cung nối 2 điểm trên lối **cắt qua mặt nước**, ngỗng lao xuống hồ. |
| b | `follow`: khi chưa tính xong đường (hoặc `ComputeAsync` lỗi) thì `MoveTo(dest)` đi thẳng | Cũng cắt qua hồ. Hay gặp ở trạng thái Search, vì điểm tiếng động nằm ngay trên cầu tàu hoặc bờ. |
| c | Ngỗng có `CanCollide = false` toàn thân, nên bờ kè và lan can **không chặn** được | Ngỗng đi xuyên lan can rồi rơi xuống nước sâu 8 stud. |
| d | Rơi xuống rồi không có cơ chế cứu | Ngỗng chuyển sang bơi và kẹt dưới hồ, `Dest` vẫn ở trên bờ nên không bắt được ai. |
| e | Người chơi bơi giữa hồ | Pathfinding đặt `Water = math.huge` nên ngỗng không bao giờ tới được. Người chơi bơi là **thoát hẳn**. |

**Cách sửa:**
1. Thêm hàm `crossesWater(a, b)`: lấy mẫu mỗi 2 stud dọc đoạn a-b, kiểm tra điểm đó có phải nước không. Kiểm tra bằng raycast thẳng xuống với `IgnoreWater = false`, trúng Terrain chất liệu `Water` là nước. Cách này cũng đúng ở góc bo tròn, không phụ thuộc Part `Water`.
2. `Direct` chỉ bật khi `not crossesWater(ngỗng, đích)`. Nếu cắt nước thì dùng waypoint pathfinding, và chạy lại đường mỗi 0.5s khi đang Chase.
3. Trong `follow`, nhánh dự phòng "đi thẳng tạm" cũng phải qua `crossesWater`. Nếu cắt nước thì đứng yên chờ đường, không đi bừa.
4. **Lưới an toàn:** mỗi tick lưu `g.LastGround` (vị trí đang đứng trên đất, không bơi). Nếu `Humanoid:GetState() == Swimming` hoặc root thấp hơn mặt đất quá 2 stud thì dịch ngỗng về `LastGround` rồi chuyển Search hoặc Patrol.
5. (Tuỳ chọn) Cho ngỗng một nhóm va chạm riêng "Geese": va chạm với thế giới (bờ kè, lan can chặn được) nhưng không va người chơi và pet.
6. **Người chơi bơi:** nếu mục tiêu đang ở trong nước (hoặc trên cầu tàu mà ngỗng không tới được) thì ngỗng đứng ở bờ gần nhất. Người chơi ở trong nước quá N giây sẽ bị coi là bị bắt. Xem câu hỏi 7.1.

File đụng tới: `Guard.lua`, `Config.lua` (thêm vài số vào `Config.Guard`).

---

## 2. Cần câu thả lên bờ vẫn câu được: chỉ được thả xuống nước

**Nguyên nhân:**
- `Fishing.spotAt` / `nearWater` chỉ kiểm tra **người đứng cách Part `Water` ≤ 25 stud** (`Config.Fishing.WaterRange`). Đứng ở lối gạch, bãi cỏ, hoặc trong sân plot đều câu được.
- Điểm phao rơi do **client** tự tính (`Effects.client.lua`: `CAST_DISTANCE = 15` phía trước người, rồi raycast xuống). Server không biết, không kiểm tra. Phao có thể rơi trên cỏ mà vẫn có rương.
- Part `Water` là hình chữ nhật 130x90 nên 4 góc bo tròn của hồ bị tính là nước dù thực ra là đất.

**Cách sửa:**
1. **Server quyết định điểm rơi.** Khi `Fishing.Press`:
   - Điểm rơi = vị trí người + hướng nhìn của `HumanoidRootPart` × `Config.Fishing.CastDistance` (15).
   - Raycast thẳng xuống từ trên cao với `IgnoreWater = false`. Điểm hợp lệ khi **trúng Terrain chất liệu `Water`** (hoặc Part `Water` nếu bạn tự build map riêng, dùng cho cả hồ lẫn ao plot).
   - Không hợp lệ thì **không bắt đầu câu**, báo `"Cast your line into the water!"`, không gửi `CastStart`.
2. Hồ hay ao do điểm rơi nằm trong Part `Water` nào quyết định, không do vị trí người đứng nữa. Nhờ vậy bỏ được `WaterRange = 25`. Ao plot không thể câu từ trong nhà.
3. Giữ kiểm tra "vùng an toàn": đứng trong vùng an toàn không được câu hồ cấm (như hiện tại).
4. Server gửi `Landing` (điểm rơi đã kiểm) trong `CastStart`. Client dùng đúng điểm đó, bỏ `groundBelow(inFront(...))`. Phao luôn rơi trên mặt nước, không còn lệch giữa 2 máy.
5. Hướng nhìn: người chơi phải quay mặt về phía nước. Cầu tàu chữ T vẫn câu được ở mọi phía vì điểm rơi 15 stud phía trước luôn ở trên nước.

File đụng tới: `Fishing.lua`, `Effects.client.lua`, `Config.lua` (`WaterRange` đổi thành `CastDistance`).

---

## 3. Thanh thông báo chỉ hiện tối đa 3 giây

**Nguyên nhân:** `MainUI.client.lua`, hàm `toast` chỉ gán `status.Text = message` rồi để nguyên mãi. Câu chào đầu game cũng nằm lì ở đó.

**Cách sửa:**
- `status` mặc định **ẩn**. `toast(message)`: hiện, đổi chữ, đặt token. Sau **3 giây** ẩn đi (fade ra), trừ khi có thông báo mới đến thay (token khác thì không ẩn).
- Hằng số `TOAST_TIME = 3` ở đầu file.
- Áp dụng cho mọi nguồn: `Notify` từ server và phản hồi của `request` (mua đồ, ấp trứng...).
- Câu chào đầu game hiện 3 giây rồi ẩn như các thông báo khác.

File đụng tới: `MainUI.client.lua`.

---

## 4. Đang câu phải đứng im

**Hiện tại:** người chơi vẫn đi được, chỉ bị huỷ khi đi xa hơn `MaxMove = 6` stud. Đi nhích 5 stud vẫn câu tiếp được.

**Cách sửa (hai lớp):**
1. **Khoá di chuyển khi bắt đầu câu** (`Fishing.Press` khi tạo session):
   - Server đặt `humanoid.WalkSpeed = 0`, `humanoid.JumpHeight = 0` (nhớ giá trị cũ) và đặt attribute `Fishing = true` trên Humanoid.
   - `Sprint.client.lua` kiểm tra attribute này: đang câu thì **bỏ qua Shift** và không ghi đè `WalkSpeed`. Hết câu (attribute false) thì gọi lại `apply()` để trả tốc độ.
   - Khôi phục ở mọi đường kết thúc: `succeed`, `fail`, `Cancel`, `RemovePlayer`, nhân vật chết hoặc respawn. Gom lại một hàm `endSession` để không sót.
2. **Lớp dự phòng ở server:** hạ `MaxMove` từ 6 xuống **1.5** để chống client gian tắt khoá. Ra khỏi ngưỡng thì huỷ như cũ.
3. Hiển thị: `Hold to Fish` đổi nhãn thành `Keep still!` trong lúc câu (tuỳ chọn). Thanh kéo hiện sẵn có thể thêm dòng nhắc.
4. Thả nút là nhả và huỷ lượt câu, nhân vật được đi lại ngay. Không bị kẹt khi ngỗng đến.

File đụng tới: `Fishing.lua`, `Sprint.client.lua`, `Config.lua` (`MaxMove`).

---

## 5. Bỏ rương Stash ở sảnh, mỗi nhà có rương riêng

**Hiện tại:** `SafeZone.buildStash` đặt 1 rương `Stash` cạnh Spawn ở Plaza. Mọi người chơi cùng cất ở đó. Mũi tên chỉ đường trong `MainUI` cũng trỏ về rương đó.

**Cách sửa:**
1. `HouseBuilder`: dựng 1 model `Stash` (dùng model "Wooden Chest", scale 2.5 như cũ) **trong nhà** của từng plot, kèm bảng chữ `STASH`. Vị trí đề xuất: tọa độ cục bộ (7.5, sàn, -11.5), góc phải gần cửa. Chỗ này đang trống: lò sưởi nằm ở z -7, cây ở x -9.5, bàn ở x 3.
2. `Plots.lua`: gắn `ProximityPrompt` "Deposit" cho Stash của plot, dùng lại `makePrompt` (chỉ **chủ nhà** dùng được, client tự ẩn nút của nhà người khác, đúng cơ chế `OwnerId` sẵn có). Callback `OnStash = Bag.Deposit` truyền vào `Plots.Init` từ `Main.server.lua`.
3. `SafeZone.lua`: **bỏ `buildStash` ở Plaza** và đoạn `Init` đi tìm Stash đơn. Nếu bạn tự build map có sẵn Stash ngoài `Plots` thì vẫn dùng như cũ.
4. `MainUI.client.lua`: `findStash` tìm Stash **trong plot của chính mình** (plot có `OwnerId == UserId`). Mũi tên và dòng `Stash X studs` chỉ về nhà mình. Chưa có plot thì ẩn.
5. Cập nhật text: câu chào đầu game, `Stash` trong thông báo kéo rương ("Carry it home to your Stash").
6. Cập nhật doc: `MAP_LEVEL1.md`, `HUONG_DAN.md` (Stash ở Plaza đổi thành trong nhà).
7. Hệ quả cần quyết định (câu hỏi 7.2): bị ngỗng bắt hiện đang đưa về Plaza. Nếu Stash ở nhà thì nên đưa về **nhà**.

File đụng tới: `HouseBuilder.lua`, `Plots.lua`, `SafeZone.lua`, `Main.server.lua`, `MainUI.client.lua`, `Fishing.lua` (text), `Bag.lua` (text nếu có), 2 file doc.

---

## 6. Lỗi khác tôi mò được (đề xuất, chưa làm)

Tick vào mục nào bạn muốn tôi làm cùng đợt.

- [ ] **6.1 Nút Teleport về nhà làm mất rủi ro khi đang mang rương.** `Main.server.lua` chỉ chặn teleport khi ngỗng đang đuổi. Kéo rương xong bấm Teleport > Plot là về nhà an toàn ngay, không cần chạy. Đề xuất: chặn teleport khi `Bag.Count > 0`, hoặc thêm cooldown dài.
- [ ] **6.2 Người chơi bơi vào hồ để thoát ngỗng** (chi tiết ở mục 1e).
- [ ] **6.3 Pond plot câu được từ ngoài ao** vì dùng chung `WaterRange`. Tự hết khi làm mục 2. Ghi lại để kiểm tra sau khi sửa.
- [ ] **6.4 Câu ở ao plot vẫn bị huỷ khi pet gục.** `step` kiểm tra `HadPet and Pets.Status.Down` cho cả ao. Pet gục chỉ liên quan hồ cấm (ao an toàn, không có ngỗng). Đề xuất: chỉ áp dụng khi `Spot == "Lake"`.
- [ ] **6.5 Chết khi đang câu để lại trạng thái cũ.** `Fishing.step` có xử lý chết, nhưng nếu chết đúng lúc `Press` chưa xong thì không dọn. Dọn trong `endSession` (mục 4).
- [ ] **6.6 `Fishing.Release` bắn `CastFail` kể cả khi nhả nút sau lúc câu thành công.** Hiện có `if not session then return` nên an toàn. Chỉ ghi nhận, không cần sửa.
- [ ] **6.7 Hộp `SafeZone` quanh Plot theo bounding box của cả model.** Cây, hàng rào, ao đều nằm trong bounding box nên vùng an toàn có thể rộng hơn hàng rào vài stud. Chấp nhận được, ghi lại để biết.
- [ ] **6.8 Chỉ có 1 ngỗng (`Count = 1`).** Một ngỗng kẹt hoặc đi sai là cả hồ không còn bảo vệ. Sau khi sửa mục 1 nên chạy thử `Count = 2`.
- [ ] **6.9 Thông báo trùng, dồn dập.** Một lượt câu hồ cấm có thể bắn 2 thông báo gần nhau (ví dụ "Hauled up..." rồi cảnh báo ngỗng). Với toast 3 giây, cái sau đè cái trước. Chấp nhận, hoặc làm hàng đợi nhỏ.

---

## 7. Câu hỏi cần bạn chốt

1. **Người chơi bơi trong hồ:** (A) ngỗng đứng ở bờ, bơi quá 5 giây thì **bị bắt** (đề xuất), (B) cấm bơi bằng tường vô hình, (C) bỏ qua?
2. **Bị ngỗng bắt:** về **nhà mình** (đề xuất, vì Stash ở nhà) hay vẫn về **Plaza**?
3. **Vị trí Stash:** trong nhà, góc phải gần cửa (đề xuất), hay ngoài sân trước nhà?
4. **Điểm rơi phao:** cố định 15 stud trước mặt (đề xuất), hay cho người chơi **ngắm** (giữ nút để chỉnh xa gần)?
5. **Toast:** 3 giây cho mọi thông báo (đề xuất), hay thông báo quan trọng (bị ngỗng bắt, mất rương) hiện lâu hơn một chút?

---

## 8. Thứ tự làm đề xuất (sau khi bạn duyệt)

- [ ] **B1.** Toast 3 giây (nhỏ, độc lập).
- [ ] **B2.** Đứng im khi câu: khoá di chuyển + `endSession` gom dọn.
- [ ] **B3.** Điểm rơi do server quyết định, chỉ cho phép trên nước. Bỏ `WaterRange`.
- [ ] **B4.** Ngỗng: `crossesWater`, pathfinding thay đường thẳng, lưới an toàn, (tuỳ chọn) nhóm va chạm.
- [ ] **B5.** Stash theo nhà: dựng trong nhà, prompt chủ nhà, bỏ Stash Plaza, sửa mũi tên và text, sửa doc.
- [ ] **B6.** Các mục mục 6 bạn chọn.
- [ ] **B7.** Kiểm tra trong Studio (Play): câu trên bờ bị từ chối, câu từ cầu tàu và bờ hồ được, đang câu không đi được, ngỗng đuổi quanh góc hồ không rơi, cất rương ở nhà mình, thông báo tự ẩn sau 3 giây.

Lưu ý: toàn bộ vẫn là đồ tạm (MVP), dựng bằng code.
