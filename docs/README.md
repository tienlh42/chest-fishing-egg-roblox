# Tài liệu dự án

> Mỗi thư mục là một **module** của một game Roblox tiêu chuẩn. `CLAUDE.md` (hướng dẫn cho AI) nằm ở gốc repo. Kế hoạch bán Robux nằm riêng ở `../MakeRobuxInHere/`.

| Thư mục | Module | Chứa |
|---|---|---|
| `Overview/` | Tổng quan và hướng dẫn | `PROJECT_OVERVIEW.md` (kiến trúc, remote, luật hiện tại, đọc đầu tiên), `HUONG_DAN.md` (cài đặt, thay model) |
| `GameDesign/` | Thiết kế game | `GDD_Ho_Khong_Cho_Cau_v2.md`, `GDD_Ho_Khong_Cho_Cau_One_Page.md`, `SYSTEM_DESIGN.md` (rương, trứng, pet, ngỗng, cướp nhà), `PET_EVOLUTION.md` (nở trùng thì loài lớn lên), `CORE_GAMEPLAY.md` (hồ thót tim, nhà dễ chịu, ngỗng sống, kéo căng thẳng, dụng cụ, coop), `RETENTION.md` (phiên ngắn, nhiệm vụ lặp lại, thu hoạch ngắn), `SERVER_BOARD.md` (phòng 4-8 người: bảng điểm, thông báo toàn server) |
| `Economy/` | Kinh tế và tiến độ | `ECONOMY_DESIGN.md` (nguồn tiền, chỗ tiêu, độ bền, số liệu từ `tools/sim_economy.py`) |
| `World/` | Bản đồ và nhà | `MAP_LEVEL1.md`, `PARK_REDESIGN.md`, `HOME_DESIGN.md` |
| `Art/` | Hình ảnh | `STYLE_GUIDE.md`, `PET_VARIANTS.md` (biến thể pet: đổi màu và hiệu ứng) |
| `Audio/` | Âm thanh | `SOUND_GUIDE.md` |
| `QA/` | Chất lượng | `BUGFIX_PLAN.md` |
| `ProjectManagement/` | Quản lý dự án | `DEVLOG.md` (nhật ký, mới nhất ở trên), `TASKS.md` (việc cần làm) |

Khi thêm tài liệu mới: đặt vào thư mục đúng module, tạo thư mục mới nếu là module mới (UI, Security, Monetization, LiveOps...) rồi thêm một dòng vào bảng này.
