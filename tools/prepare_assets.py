"""Chép model từ repo roblox-assets vào Assets/Models (Rojo đồng bộ vào ReplicatedStorage/CustomModels).

Chạy: python tools/prepare_assets.py [đường dẫn repo roblox-assets]
Mỗi file .rbxmx được sửa nhẹ:
  - Script (RunContext=Client) trong bản mẫu bị TẮT (Disabled=true). Models.Get bật lại trên bản sao,
    nên chỉ model đang hiện trong game mới chạy animation / hiệu ứng.
  - RodEffects: tắt Beam dây câu và hạt nước ở móc (game tự vẽ dây + phao tại điểm rơi do server tính).
"""
import re
import shutil
import sys
from pathlib import Path

SRC = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(r"C:\Roblox\roblox-assets")
DST = Path(__file__).resolve().parent.parent / "Assets" / "Models"
FOLDERS = ["FishingRod", "Pet", "Egg", "TreasureChest", "AutoFisher", "PoliceGoose"]

DISABLE = re.compile(r'(<Item class="Script"[^>]*><Properties>(?:(?!</Properties>).)*?<token name="RunContext">\d+</token>)', re.S)


def patch_rod_effects(text):
    # Beam dây câu của cần: tắt (dây do Effects.client.lua vẽ tới phao)
    text = text.replace("line.Parent = tip", "line.Enabled = false\nline.Parent = tip")
    # Giọt nước ở móc của cần: bỏ (nước bắn tại điểm rơi do game tự làm)
    text = text.replace("local function flash(peak)", "splash.Parent = nil\n\nlocal function flash(peak)")
    return text


def main():
    DST.mkdir(parents=True, exist_ok=True)
    count = 0
    for folder in FOLDERS:
        for path in sorted((SRC / folder).glob("*.rbxmx")):
            text = path.read_text(encoding="utf-8")
            if folder == "FishingRod":
                text = patch_rod_effects(text)
            text = DISABLE.sub(lambda m: m.group(1) + '<bool name="Disabled">true</bool>', text)
            (DST / path.name).write_text(text, encoding="utf-8", newline="")
            count += 1
    print(f"Da chep {count} model vao {DST}")


if __name__ == "__main__":
    main()
