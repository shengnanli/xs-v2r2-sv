#!/usr/bin/env python3
# =====================================================================
# gen_rob_fieldmap.py — Rob packed rob_entries[N] ↔ golden robEntries_N_<field>
#                       精确 per-field bit-slice field-map 生成器
# ---------------------------------------------------------------------
# codex 0095 首选路线 (field-map first): 不把可读 packed 实现退化成 4320
# 个 scalar。改用 per-field 精确 field-map pinning——在 FM `match` 之前对
# 每个 (entry N, field F, bit b) 显式 set_user_match:
#     ref : r:/WORK/<TOP>/robEntries_<N>_<goldsuf>_reg[b]   (1 位可无 [b])
#     impl: i:/WORK/<TOP>/u_rob/u_core/rob_entries_reg[N][lo+b]
# 使 FM 无需在 4320 golden scalar vs 1 个 packed 数组之间做签名匹配
# (=Route B 命中的 45min+ 不收敛的 compute 墙)。
#
# 纪律:
#   - 纯 set_user_match(FM pinning), 不改 RTL, 不 dont_verify, 不删点。
#   - 严格 bijection: 每 golden bit 恰配 1 impl bit, 等宽, 无重叠/遗漏。
#   - 只映射 impl rob_entry_t 里真实存在的 25 个字段。golden 的
#     debug_ldest / debug_pdest (2 字段) impl 核不存(wrapper 常 0 驱动,
#     difftest 黑盒承担)→ 不映射, 由 cone-pruning / matched-unread 处理。
#   - 跨 entry / 跨 field 启发式配对一律禁止: 映射完全由结构布局决定。
#
# 输出:
#   1) <out>/rob_field_map.txt      —— "<goldsuf> <lo> <width>" (供 FM_FIELD_MAP)
#   2) <out>/rob_entry_pins.tcl     —— 完整 4000 (25×160) set_user_match (供 FM_ENTRY_PINS)
#   3) <out>/rob_fieldmap_manifest.json —— bijection 校验 + root hash
# =====================================================================
import argparse, hashlib, json, os, re, sys

# ---- impl rob_entry_t 打包布局 (rob_pkg.sv 声明顺序; 首字段=MSB) ----
# (impl_field, width, golden_suffix)。golden_suffix=None 表示无 golden 对应。
IMPL_FIELDS = [
    ("valid",            1, "valid"),
    ("uop_num",          7, "uopNum"),
    ("std_writebacked",  1, "stdWritebacked"),
    ("real_dest_size",   7, "realDestSize"),
    ("need_flush",       1, "needFlush"),
    ("interrupt_safe",   1, "interrupt_safe"),
    ("mmio",             1, "mmio"),
    ("vls",              1, "vls"),
    ("fflags",           5, "fflags"),
    ("vxsat",            1, "vxsat"),
    ("rf_wen",           1, "rfWen"),
    ("fp_wen",           1, "fpWen"),
    ("wflags",           1, "wflags"),
    ("dirty_vs",         1, "dirtyVs"),
    ("commit_type",      3, "commitType"),
    ("is_rvc",           1, "isRVC"),
    ("is_vset",          1, "isVset"),
    ("is_hls",           1, "isHls"),
    ("instr_size",       3, "instrSize"),
    ("ftq_idx_value",    6, "ftqIdx_value"),
    ("ftq_idx_flag",     1, "ftqIdx_flag"),
    ("ftq_offset",       4, "ftqOffset"),
    ("itype",            4, "traceBlockInPipe_itype"),
    ("iretire",          4, "traceBlockInPipe_iretire"),
    ("ilastsize",        1, "traceBlockInPipe_ilastsize"),
]

# golden-only 字段 (impl 核不存, wrapper 常 0/黑盒): 不映射, 记录以供审计。
GOLDEN_ONLY = {"debug_ldest": 6, "debug_pdest": 8}

ROB_SIZE = 160  # 有效条目数 (golden robEntries_0..159)

def compute_layout():
    """返回 [(impl_field, gold_suf, width, lo, hi)]，MSB-first 打包。"""
    W = sum(w for _, w, _ in IMPL_FIELDS)
    hi = W - 1
    out = []
    for name, w, gold in IMPL_FIELDS:
        lo = hi - w + 1
        out.append((name, gold, w, lo, hi))
        hi = lo - 1
    assert hi == -1, f"layout leftover hi={hi}, W={W}"
    return out, W

def parse_golden(rob_sv):
    """从 golden Rob.sv 提所有 robEntries_<N>_<field> reg 名+宽度。
    返回 dict[(N, gold_suffix)] = width。"""
    pat = re.compile(r'^\s*reg\s+(?:\[(\d+):(\d+)\]\s+)?robEntries_(\d+)_([A-Za-z_][A-Za-z_0-9]*)\s*;')
    regs = {}
    with open(rob_sv) as fh:
        for ln in fh:
            m = pat.match(ln)
            if not m:
                continue
            hi_s, lo_s, n_s, suf = m.groups()
            w = 1 if hi_s is None else (int(hi_s) - int(lo_s) + 1)
            regs[(int(n_s), suf)] = w
    return regs

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--golden", default="/home/eda/xs-env/G0-canonical/golden-rtl/Rob.sv")
    ap.add_argument("--out", required=True, help="output dir")
    ap.add_argument("--top", default="Rob", help="FM top module name (partition module)")
    ap.add_argument("--impl-prefix", default="u_rob/u_core",
                    help="impl hier prefix under i:/WORK/<top> to rob_entries_reg")
    ap.add_argument("--impl-arr", default="rob_entries_reg",
                    help="impl FM register array leaf name for rob_entries")
    ap.add_argument("--gold-prefix", default="u_rob",
                    help="golden hier prefix under r:/WORK/<top> to robEntries_N_<field>")
    ap.add_argument("--gold-suffix", default="",
                    help="FM leaf suffix appended to golden robEntries_N_<field> "
                         "(FM names golden per-field regs WITHOUT _reg suffix — verified vs route B)")
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)

    layout, W = compute_layout()
    golden = parse_golden(args.golden)

    # ---- bijection 校验前置: 逐字段核对 golden 宽度 == impl 布局宽度 ----
    errors = []
    mapped_gold_keys = set()
    # 覆盖位账本: impl 每 bit 命中次数(应恰 1); golden 每 (N,suf,bit) 命中次数(应恰 1)
    impl_bit_hits = {}   # (N, bit) -> count
    gold_bit_hits = {}   # (N, suf, bit) -> count

    for N in range(ROB_SIZE):
        for impl_f, gold_suf, w, lo, hi in layout:
            key = (N, gold_suf)
            if key not in golden:
                errors.append(f"MISSING golden reg robEntries_{N}_{gold_suf}")
                continue
            gw = golden[key]
            if gw != w:
                errors.append(
                    f"WIDTH MISMATCH robEntries_{N}_{gold_suf}: golden={gw} impl={w}")
            mapped_gold_keys.add(key)
            for b in range(w):
                impl_bit_hits[(N, lo + b)] = impl_bit_hits.get((N, lo + b), 0) + 1
                gold_bit_hits[(N, gold_suf, b)] = gold_bit_hits.get((N, gold_suf, b), 0) + 1

    # golden-only 字段审计: 确认它们真是 impl 核不存的 debug 字段
    unmapped_gold = []
    for (N, suf), gw in golden.items():
        if (N, suf) not in mapped_gold_keys:
            unmapped_gold.append((N, suf, gw))
    # 期望: 全部落在 GOLDEN_ONLY
    for N, suf, gw in unmapped_gold:
        if suf not in GOLDEN_ONLY:
            errors.append(f"UNEXPECTED unmapped golden reg robEntries_{N}_{suf} (w={gw})")
        elif GOLDEN_ONLY[suf] != gw:
            errors.append(f"GOLDEN_ONLY width mismatch {suf}: decl={gw} expect={GOLDEN_ONLY[suf]}")

    # 重叠/多重命中检查
    for k, c in impl_bit_hits.items():
        if c != 1:
            errors.append(f"IMPL bit reused: entry {k[0]} bit {k[1]} hit {c}x")
    for k, c in gold_bit_hits.items():
        if c != 1:
            errors.append(f"GOLD bit reused: {k} hit {c}x")

    # impl 每条目应恰覆盖 [0..W-1]
    for N in range(ROB_SIZE):
        covered = sorted(b for (nn, b) in impl_bit_hits if nn == N)
        if covered != list(range(W)):
            errors.append(f"IMPL entry {N} coverage != [0..{W-1}]: {covered[:5]}...")

    n_map_bits = sum(w for _, _, w, _, _ in layout) * ROB_SIZE
    n_map_regs = len(layout) * ROB_SIZE

    # ---- 输出 1: field map (per-field, entry-agnostic — lo/width 对每 entry 相同) ----
    fm_lines = []
    for impl_f, gold_suf, w, lo, hi in layout:
        fm_lines.append(f"{gold_suf} {lo} {w}")
    with open(os.path.join(args.out, "rob_field_map.txt"), "w") as fh:
        fh.write("# golden_suffix  lo  width  (impl rob_entries_reg[N] packed bit slice)\n")
        fh.write("\n".join(fm_lines) + "\n")

    # ---- 输出 2: 完整 entry pins tcl (per-bit set_user_match, bijection) ----
    top = args.top
    pre = args.impl_prefix
    arr = args.impl_arr
    gpre = args.gold_prefix
    gsuf = args.gold_suffix
    gp = f"{gpre}/" if gpre else ""
    pin_lines = []
    pin_lines.append(f"# AUTO-GENERATED by gen_rob_fieldmap.py — DO NOT EDIT")
    pin_lines.append(f"# Rob packed rob_entries[N] field-map pins for FM (codex 0095 field-map-first).")
    pin_lines.append(f"# {n_map_regs} field regs / {n_map_bits} bits, strict bijection (per-entry×field).")
    pin_lines.append(f"# ref  {gp}robEntries_<N>_<field>{gsuf}[b]  <->  impl {pre}/{arr}[N][lo+b]")
    pin_lines.append(f"# golden per-field regs named WITHOUT _reg suffix; 1-bit regs have NO [0]")
    pin_lines.append(f"# (verified against agent/rob-routeB Rob_pVecExcp_entry_pins.tcl: "
                     f"needFlush->bit43, fflags[0]->bit35 — matches this layout).")
    pin_lines.append(f"# NO dont_verify / NO ref constraint / pure set_user_match.")
    pin_lines.append(f"set ROB_FM_TOP \"{top}\"")
    pin_lines.append(f"set _rob_pin_n 0")
    pin_lines.append(f"set _rob_pin_fail 0")
    pin_lines.append("proc _rob_pin {rp ip} {")
    pin_lines.append("  global _rob_pin_n _rob_pin_fail")
    pin_lines.append("  if {[catch {set_user_match $rp $ip} m]} {")
    pin_lines.append("    incr _rob_pin_fail")
    pin_lines.append("    if {$_rob_pin_fail <= 40} { puts \"ROB_PIN_FAIL: $rp <-> $ip : $m\" }")
    pin_lines.append("  } else { incr _rob_pin_n }")
    pin_lines.append("}")
    for N in range(ROB_SIZE):
        for impl_f, gold_suf, w, lo, hi in layout:
            for b in range(w):
                ip = f"i:/WORK/{top}/{pre}/{arr}\\[{N}\\]\\[{lo + b}\\]"
                if w == 1:
                    # 1 位 golden reg 无 [0] 下标 (route B 已验证: robEntries_N_needFlush)
                    rp = f"r:/WORK/{top}/{gp}robEntries_{N}_{gold_suf}{gsuf}"
                else:
                    rp = f"r:/WORK/{top}/{gp}robEntries_{N}_{gold_suf}{gsuf}\\[{b}\\]"
                pin_lines.append(f"_rob_pin {rp} {ip}")
    pin_lines.append('puts "ROB_ENTRY_PINS: pinned $_rob_pin_n (fail $_rob_pin_fail) of '
                     + str(n_map_bits) + ' bits"')
    with open(os.path.join(args.out, "rob_entry_pins.tcl"), "w") as fh:
        fh.write("\n".join(pin_lines) + "\n")

    # ---- 输出 3: manifest (bijection 结果 + root hash) ----
    # root hash = 稳定序列化所有 (N, gold_suf, b, lo+b) 三元组
    hasher = hashlib.sha256()
    for N in range(ROB_SIZE):
        for impl_f, gold_suf, w, lo, hi in layout:
            for b in range(w):
                hasher.update(f"{N}|{gold_suf}|{b}|{lo+b}\n".encode())
    root_hash = hasher.hexdigest()

    manifest = {
        "generator": "gen_rob_fieldmap.py",
        "top": top,
        "impl_reg_array": f"i:/WORK/{top}/{pre}/{arr}",
        "rob_entry_t_width": W,
        "rob_size": ROB_SIZE,
        "impl_fields_mapped": len(layout),
        "golden_regs_total": len(golden),
        "golden_regs_mapped": len(mapped_gold_keys),
        "golden_only_regs": len(unmapped_gold),
        "golden_only_fields": sorted(GOLDEN_ONLY.keys()),
        "map_entries": n_map_regs,
        "map_bits": n_map_bits,
        "bijection_ok": len(errors) == 0,
        "errors": errors[:50],
        "field_map_root_sha256": root_hash,
        "layout": [
            {"impl_field": f, "golden_suffix": g, "width": w, "lo": lo, "hi": hi}
            for f, g, w, lo, hi in layout
        ],
    }
    with open(os.path.join(args.out, "rob_fieldmap_manifest.json"), "w") as fh:
        json.dump(manifest, fh, indent=2)

    # ---- 打印摘要 ----
    print(f"rob_entry_t width       : {W} bits, {len(layout)} impl fields")
    print(f"golden robEntries regs  : {len(golden)} (mapped {len(mapped_gold_keys)}, "
          f"golden-only {len(unmapped_gold)})")
    print(f"map entries / bits      : {n_map_regs} / {n_map_bits}")
    print(f"field-map root sha256   : {root_hash}")
    print(f"bijection_ok            : {manifest['bijection_ok']}")
    if errors:
        print(f"ERRORS ({len(errors)}):")
        for e in errors[:30]:
            print("  " + e)
        return 1
    # golden-only sanity
    go_by_field = {}
    for N, suf, gw in unmapped_gold:
        go_by_field.setdefault(suf, 0)
        go_by_field[suf] += 1
    print(f"golden-only fields      : {go_by_field} (expected debug_ldest/debug_pdest ×160)")
    return 0

if __name__ == "__main__":
    sys.exit(main())
