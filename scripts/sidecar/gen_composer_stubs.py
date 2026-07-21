#!/usr/bin/env python3
"""从 canonical G0 golden RTL 重建 Composer 的预测器接口桩 predictor_stubs.sv。

Composer FM 目标把 5 个预测器子模块(FTB/FauFTB/Tage_SC/RAS/ITTage)替换为**端口
空模块桩**(只有端口声明、无逻辑),两侧(ref 与 impl)同读——这样 Composer 的验证边界
干净落在 Composer 本体,预测器子模块作为对称桩在两侧相消(assembly 手法)。

canonical 依据: 桩端口逐字取自 golden-rtl/<M>.sv 的模块头(module M( ... );),
provenance = G0,不借用 implementation RTL(满足 FM_REF_DEPS 只引 canonical G0)。

用法: gen_composer_stubs.py <golden-rtl-dir> <out.sv>
"""
import sys, os, re

MODS = ["FTB", "FauFTB", "Tage_SC", "RAS", "ITTage"]


def extract_header(src_path, mod):
    """取 `module <mod>(` 起到首个行首 `);` 的模块头(含端口声明与闭合括号)。"""
    lines = open(src_path).read().splitlines()
    start = None
    pat = re.compile(r"^module\s+" + re.escape(mod) + r"\s*\(")
    for i, ln in enumerate(lines):
        if pat.match(ln):
            start = i
            break
    if start is None:
        raise SystemExit(f"golden 未找到 module {mod} in {src_path}")
    out = []
    for ln in lines[start:]:
        out.append(ln)
        if re.match(r"^\);", ln):
            return out
    raise SystemExit(f"module {mod} 头未闭合 (无行首 ');')")


def main():
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    golden_dir, out_path = sys.argv[1], sys.argv[2]
    blocks = []
    for m in MODS:
        src = os.path.join(golden_dir, m + ".sv")
        hdr = extract_header(src, m)
        nport = sum(1 for l in hdr if re.match(r"\s*(input|output)\b", l))
        blocks.append((m, hdr, nport))
    with open(out_path, "w") as f:
        f.write("// predictor_stubs.sv —— Composer FM 接口桩(端口空模块, 两侧同读)\n")
        f.write("// 自动生成: gen_composer_stubs.py, 端口逐字取自 canonical G0 golden-rtl/<M>.sv\n")
        f.write("// provenance=G0, 不含 implementation RTL; 修改请改生成器并重跑, 勿手改。\n")
        f.write("//\n")
        for m, _, n in blocks:
            f.write(f"//   {m}: {n} ports\n")
        f.write("\n")
        for m, hdr, _ in blocks:
            f.write("\n".join(hdr))
            f.write("\nendmodule\n\n")
    total = sum(n for _, _, n in blocks)
    print(f"生成 {out_path}: {len(MODS)} 模块, {total} 端口总计")
    for m, _, n in blocks:
        print(f"  {m}: {n}")


if __name__ == "__main__":
    main()
