# Hướng dẫn cho AI làm việc trong repo này

Roblox game "Chest Fishing & Eggs / Hồ Không Cho Câu", đang ở bản **MVP**. Code Luau đồng bộ vào Studio bằng **Rojo**.

## Đọc trước khi làm
1. `PROJECT_OVERVIEW.md`: kiến trúc, module, remote, luật game hiện tại
2. `DEVLOG.md`: đã làm gì, theo thứ tự thời gian (mới nhất ở trên)
3. Khi đụng tới map: `MAP_LEVEL1.md`, `PARK_REDESIGN.md` (có các bẫy kỹ thuật của Terrain)
4. Khi đụng tới độ hiếm, rương / Stash, trứng, pet, ngỗng, vùng an toàn, cướp nhà: `SYSTEM_DESIGN.md` (thiết kế đích, có nhãn phần đã code / đã chốt / chưa chốt)
5. Khi đụng tới giá, thu nhập, tỉ lệ rương, máy câu, perk cần / pet, luật cướp: `ECONOMY_DESIGN.md` (kinh tế farm, số liệu từ `tools/sim_economy.py`)

## Quy tắc
- Chữ hiện cho người chơi bằng **tiếng Anh**. Comment code và tài liệu bằng **tiếng Việt**. Trả lời người dùng bằng tiếng Việt.
- **Server quyết định mọi kết quả**, client chỉ gửi yêu cầu. Luôn kiểm tra dữ liệu client gửi lên.
- Mọi con số đặt trong `ReplicatedStorage/Config.lua`. Sửa profile xong phải gọi `Data.Update(player)`.
- Sửa script thì sửa file `.lua`, **không** sửa trong Studio (Rojo ghi đè). Studio MCP chỉ dùng cho model / map / Output / chơi thử.
- Model, animation và map đều là đồ tạm. Thêm tính năng thì dùng `Models.Get` + `CustomModels`, không chờ có model thật.
- Chạy `selene .` trước khi báo xong.
- Studio MCP: chụp màn hình có đặt camera trong lúc **Play** sẽ khoá camera của người chơi. Chụp xong phải Stop rồi Play lại.
- **Làm xong mỗi việc: thêm 1 mục ở TRÊN CÙNG `DEVLOG.md`** (theo mẫu cuối file) và cập nhật tài liệu liên quan (`PROJECT_OVERVIEW.md`...).
- **Tự test và tự đưa code vào Studio** sau mỗi việc, không chờ người dùng. So `Source` trong Studio với file repo (bỏ qua CRLF). Rojo mất kết nối thì chép nguyên văn file vào script trong Studio qua MCP (Edit mode). Test bằng Stop/Play, `execute_luau`, `user_keyboard_input`.
- Commit, push hoặc publish lên Roblox chỉ khi người dùng yêu cầu.
