"""Mô phỏng kinh tế (giá trị kỳ vọng, không ngẫu nhiên) cho ECONOMY_DESIGN.md.

Chạy: python tools/sim_economy.py   (Windows: đặt PYTHONIOENCODING=utf-8)
Mọi tham số nằm ở đầu file. Muốn thử số mới: sửa ở đây, chạy lại, rồi chép số tốt nhất vào Config.lua.
Mô hình thô: người chơi chơi đều tay, mua theo thứ tự cố định. Dùng để SO SÁNH giữa các phương án
và kiểm tra nhịp tiến độ, không phải để dự đoán chính xác.
"""

# ===== Rương: (tên, coins trung bình, HoldTime, [(trứng, xác suất)] xét từ trên xuống) =====
CHESTS = [
    ("Wooden", 10, 6, [("Reed", 0.30)]),
    ("Blue", 40, 9, [("Bubble", 0.12), ("Reed", 0.55)]),
    ("Purple", 105, 12, [("Crystal", 0.12), ("Bubble", 0.35), ("Reed", 0.80)]),
    ("Golden", 225, 15, [("Gold", 0.15), ("Crystal", 0.35), ("Bubble", 1.00)]),
    ("Rainbow", 450, 18, [("Dragon", 0.12), ("Gold", 0.35), ("Crystal", 1.00)]),
]
EGG_SELL = {"Reed": 10, "Bubble": 40, "Crystal": 120, "Gold": 400, "Dragon": 1500}
EGG_ORDER = ["Reed", "Bubble", "Crystal", "Gold", "Dragon"]

# ===== Cần: (tên, giá, Speed, độ bền tính bằng số rương kéo được (None = không hỏng), tỉ lệ % ra Wooden/Blue/Purple/Golden/Rainbow ở hồ) =====
RODS = [
    ("Duckling", 0, 1.00, None, (88, 10, 1.8, 0.2, 0.02)),
    ("Catfish", 150, 0.92, 50, (78, 18, 3.4, 0.55, 0.05)),
    ("Turtle", 500, 0.80, 100, (66, 25, 7, 1.7, 0.3)),
    ("Fox", 1800, 0.70, 250, (52, 30, 13, 4.2, 0.8)),
    ("Lucky Cat", 6000, 0.58, 500, (40, 31, 19, 8.2, 1.8)),
    ("Rainbow Dragon", 18000, 0.45, 1000, (26, 28, 28, 14, 4)),
]

# ===== Giả định hành vi người chơi (chỉnh được) =====
CAST_OVERHEAD = 4.0  # giây ngắm + ném + chờ phao mỗi rương
SNEAK_FACTOR = 1.3  # nhả nút trốn ngỗng làm kéo lâu hơn bấy nhiêu lần
TRIP_OVERHEAD = 25.0  # giây chạy về nhà + cất + quay lại hồ, mỗi chuyến
BAG = 4  # số rương mỗi chuyến
SUPPLY_SHARE = 0.7  # tranh rương với người chơi khác (1 = vắng người)
LOSS_BASE, LOSS_PER_HP = 0.28, 0.0006  # xác suất mất cả túi mỗi chuyến = LOSS_BASE - LOSS_PER_HP * HP pet
PET_HP = 170  # pet trung bình lúc giữa game
PET_DURABILITY_X = 20  # độ bền pet = 20 x HP tối đa (tổng HP chịu được trong đời)


def eggs_ev(chest):
    ev, remain = 0.0, 1.0
    for tier, chance in chest[3]:
        ev += remain * chance * EGG_SELL[tier]
        remain *= 1 - chance
    return ev


def chest_value(i):
    return CHESTS[i][1] + eggs_ev(CHESTS[i])


def mix_stats(odds):
    total = sum(odds)
    p = [o / total for o in odds]
    ev = sum(pi * chest_value(i) for i, pi in enumerate(p))
    hold = sum(pi * CHESTS[i][2] for i, pi in enumerate(p))
    return p, ev, hold


def lake_income(rod_i):
    """(EV/rương, rương/phút, thu nhập gộp/phút, chi phí hao mòn cần/phút, thu nhập ròng/phút)"""
    rod = RODS[rod_i]
    _, ev, hold = mix_stats(rod[4])
    per_chest = hold * rod[2] * SNEAK_FACTOR + CAST_OVERHEAD + TRIP_OVERHEAD / BAG
    survive = 1 - (LOSS_BASE - LOSS_PER_HP * PET_HP)
    cpm = 60 / per_chest * survive * SUPPLY_SHARE
    wear = rod[1] / rod[3] * cpm if rod[3] else 0.0
    return ev, cpm, ev * cpm, wear, ev * cpm - wear


POND_ODDS = (100, 0, 0, 0, 0)  # ao nhà: chỉ ra rương gỗ
POND_TIME_MULT = 5.0


def pond_income(rod_i):
    rod = RODS[rod_i]
    _, ev, hold = mix_stats(POND_ODDS)
    per_chest = hold * POND_TIME_MULT * rod[2] + CAST_OVERHEAD
    return ev * 60 / per_chest  # ao KHÔNG làm hao cần (chỉ kéo rương ở hồ cấm mới hao)


def table_rods():
    print("\n=== Cần câu: thu nhập hồ, hao mòn, ao ===")
    print("Cần             Giá   Bền(rương) Sống(phút)  Gộp/ph  Hao mòn/ph  Hao/gộp  Ròng/ph | Ao/ph (không hao cần)  Ao/hồ ròng")
    for i, rod in enumerate(RODS):
        ev, cpm, gross, wear, net = lake_income(i)
        life = f"{rod[3] / cpm:7.0f}" if rod[3] else "    inf"
        dur = f"{rod[3]:7}" if rod[3] else "    inf"
        share = f"{wear / gross:7.0%}" if rod[3] else "     0%"
        print(f"{rod[0]:<15} {rod[1]:6} {dur:>10} {life:>11} {gross:7.1f} {wear:10.1f} {share:>8} {net:8.1f} | {pond_income(i):17.1f} {pond_income(i) / net:10.0%}")


# ===== Máy câu: giá MUA THẲNG từng tier, độ bền = số rương sản xuất được, tỉ lệ rương =====
# Capacity ~ 30 phút sản xuất: vào game là có sẵn một phiên thu hoạch, offline lâu hơn thì kho ngừng.
# (tier, giá mua thẳng, Interval giây, Capacity, độ bền (rương), tỉ lệ % Wooden/Blue/Purple)
MACHINES = [
    ("Common", 300, 180, 10, 120, (100, 0, 0)),
    ("Rare", 1000, 160, 11, 200, (70, 30, 0)),
    ("Epic", 3500, 140, 13, 450, (55, 35, 10)),
    ("Legendary", 10000, 120, 15, 1000, (45, 38, 17)),
    ("Mythic", 30000, 100, 18, 2500, (35, 40, 25)),
]
PEDESTAL_PRICES = [0, 400, 1200, 3000, 7000]  # mở ổ máy (vĩnh viễn, không hỏng)
COLLECT_EVERY = 25 * 60  # giây giữa 2 lần người chơi quay về thu máy


def machine_income(tier):
    """(EV/rương, thu nhập gộp/phút, hao mòn/phút, ròng/phút)"""
    name, price, interval, cap, dur, odds = MACHINES[tier]
    _, ev, _ = mix_stats(tuple(odds) + (0, 0))
    stored = min(cap, COLLECT_EVERY / interval)
    chests_per_min = stored / (COLLECT_EVERY / 60)
    gross = ev * chests_per_min
    wear = price / dur * chests_per_min
    return ev, gross, wear, gross - wear


def table_machines():
    print(f"\n=== Máy câu (thu mỗi {COLLECT_EVERY // 60} phút) ===")
    print("Tier       Giá mua  Interval Cap  Bền(rương) Sống(giờ)  EV/rương  Gộp/ph  Hao/ph  Hao/gộp  Ròng/ph  Hoàn vốn(giờ)")
    for i, m in enumerate(MACHINES):
        ev, gross, wear, net = machine_income(i)
        life_h = m[4] * m[2] / 3600
        print(f"{m[0]:<10} {m[1]:7} {m[2]:7}s {m[3]:4} {m[4]:9} {life_h:9.1f} {ev:9.1f} {gross:7.2f} {wear:7.2f} {wear / gross:8.0%} {net:8.2f} {m[1] / net / 60:13.1f}")


def pet_table():
    print("\n=== Pet: độ bền = 20 x HP (tổng HP chịu được), giá trị thay thế = giá bán trứng ===")
    pets = [("Baker Dog", 130, 25), ("Muscle Duck", 220, 80), ("Magician Cat", 170, 250), ("K9 Dog", 240, 800), ("Office Dragon", 300, 3000)]
    print("Pet              HP  Độ bền  Giây bị đánh(5HP/s)  Sống(giờ, ~6xHP/giờ)  Giá bán pet  Hao/giờ")
    for name, hp, price in pets:
        dur = hp * PET_DURABILITY_X
        hours = dur / (6 * hp)
        print(f"{name:<15} {hp:4} {dur:7} {dur / 5:19.0f} {hours:21.1f} {price:12} {price / hours:8.0f}")


# ===== Tiến độ (thu nhập RÒNG, trừ hao mòn) =====
def progression():
    # (loại, đối tượng). 'ped' mở ổ, 'mach' mua máy tier 0 vào ổ, 'up' nâng máy (trả chênh lệch)
    plan = [
        ("rod", 1), ("mach", 0), ("rod", 2), ("ped", 1), ("mach", 1), ("up", (0, 1)), ("rod", 3), ("ped", 2), ("mach", 2),
        ("up", (0, 2)), ("rod", 4), ("ped", 3), ("mach", 3), ("up", (1, 2)), ("up", (0, 3)),
        ("rod", 5), ("ped", 4), ("mach", 4), ("up", (1, 3)), ("up", (0, 4)),
    ]
    rod_i, machines, t = 0, [], 0.0
    owned_pedestals = 1
    print("\n=== Tiến độ mua (phút chơi liên tục, thu nhập RÒNG đã trừ hao mòn) ===")
    for kind, arg in plan:
        if kind == "rod":
            cost, label = RODS[arg][1], f"Cần {RODS[arg][0]}"
        elif kind == "ped":
            cost, label = PEDESTAL_PRICES[arg], f"Mở ổ máy #{arg + 1}"
            owned_pedestals = arg + 1
        elif kind == "mach":
            cost, label = MACHINES[arg][1], f"Mua máy Common vào ổ #{len(machines) + 1}" if arg == 0 else f"Mua máy {MACHINES[arg][0]} vào ổ #{len(machines) + 1}"
        else:
            idx, tier = arg
            cost, label = MACHINES[tier][1] - MACHINES[machines[idx]][1], f"Nâng máy #{idx + 1} lên {MACHINES[tier][0]}"
        income = lake_income(rod_i)[4] + sum(machine_income(ti)[3] for ti in machines)
        dt = cost / income
        t += dt
        if kind == "rod":
            rod_i = arg
        elif kind == "mach":
            machines.append(arg)
        elif kind == "up":
            machines[arg[0]] = arg[1]
        print(f"  {t:7.1f} phút ({t / 60:4.1f}h)  {label:<30} giá {cost:>6}  ròng trước khi mua {income:6.1f}/phút (mất {dt:5.1f} phút)")
    lake, mach = lake_income(rod_i)[4], sum(machine_income(ti)[3] for ti in machines)
    print(f"  Cuối: hồ {lake:.0f}/phút ròng, máy {mach:.0f}/phút ròng ({mach / (lake + mach) * 100:.0f}% tổng)")


# ===== Cướp nhà: kẻ cướp TỰ CHỌN món (tối đa = số ô túi trống), mua chìa vạn năng, mỗi lần mở 50% =====
def stock_for(rod_i, machines):
    """Đồ có thể bị cướp của nạn nhân: rương trong máy (đầy kho) + 2 rương chưa mở trong kho + 2 trứng chưa ấp."""
    items = []
    for tier in machines:
        _, ev, _ = mix_stats(tuple(MACHINES[tier][5]) + (0, 0))
        items += [ev] * MACHINES[tier][3]
    _, lake_ev, _, _, _ = lake_income(rod_i)
    items += [lake_ev * 2.2] * 2
    items += [EGG_SELL[EGG_ORDER[min(rod_i, 4)]]] * 2
    return sorted(items, reverse=True)


KEY_PRICE = 200  # giá 1 chìa vạn năng
MAX_TRIES = 4  # số lần thử khóa tối đa trong 1 vụ (còn bị giới hạn bởi 60 giây trong sân)
ESCAPE = 0.4  # xác suất kẻ cướp mang đồ về tới nhà mình sau khi mở được (giả định, cần đo)
LOCKS = [("Không khóa", 0.5), ("Khóa 1", 0.4), ("Khóa 2", 0.3), ("Khóa 3", 0.2)]  # tỉ lệ mở của chìa theo khóa của chủ nhà


def raid_value(loot, p_open):
    """Lời ròng kỳ vọng của 1 lần cướp (đã trừ chìa dùng hết, kể cả khi bị bắt)."""
    p_ok = 1 - (1 - p_open) ** MAX_TRIES
    keys = p_ok / p_open
    return p_ok * ESCAPE * loot - keys * KEY_PRICE, keys


def table_robbery():
    RAID_SECONDS = 20 + 5 * 2 + 3 * 4 + 25 + 30  # chạy tới + thử khóa + giữ [E] lấy + quanh sân + chạy về
    cases = [
        ("Đầu game: Catfish, 1 máy Common", 1, [0]),
        ("Giữa: Fox, 3 máy Rare/Epic", 3, [1, 1, 2]),
        ("Muộn: Cat, 4 máy Legendary", 4, [3, 3, 3, 3]),
        ("Cuối: Dragon, 5 máy Mythic", 5, [4, 4, 4, 4, 4]),
    ]
    print(f"\n=== Cướp nhà: tự chọn món xịn nhất, chìa {KEY_PRICE} coins, thoát được {ESCAPE:.0%}, tối đa {MAX_TRIES} lần thử ===")
    print("Lời ròng KỲ VỌNG mỗi vụ (đã gồm thất bại). Cột cuối: câu hồ ròng của kẻ cướp (cùng cấp) trong cùng thời gian.")
    for bag in (4, 6):
        print(f"\n  Túi {bag} ô")
        print("  Nạn nhân                        Món lấy | " + " | ".join(f"{n:>10}" for n, _ in LOCKS) + " | Câu hồ cùng thời gian")
        for name, rod_i, machines in cases:
            stock = stock_for(rod_i, machines)
            loot = sum(stock[:bag])
            fishing = lake_income(rod_i)[4] * RAID_SECONDS / 60
            cells = []
            for _, p_open in LOCKS:
                ev, _ = raid_value(loot, p_open)
                cells.append(f"{ev:6.0f} ({ev / fishing:3.1f}x)")
            print(f"  {name:<30} {loot:8.0f} | " + " | ".join(cells) + f" | {fishing:8.0f}")


if __name__ == "__main__":
    table_rods()
    table_machines()
    pet_table()
    progression()
    table_robbery()
