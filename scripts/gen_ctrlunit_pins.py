#!/usr/bin/env python3
"""gen_ctrlunit_pins.py —— 生成 verif/ut/CtrlUnit/fm_pins_pre.tcl（FM「匹配前」钉点）。

对象：CtrlUnit 的两级出口打拍 NewPipelineConnectPipe_27（CtrlUnitPseudoErrorPipelineConnect0/1）
的 payload 寄存器。golden 每字段一个寄存器 data_<c>_valid_reg / data_<c>_mask_reg[b]；
重写件（rtl/uncore/NewPipelineConnectPipe_27.sv）把 8 条通道 ×(1 valid + 64 mask) 存在一个
扁平的 u_core/data_reg[519:0]，通道 c 占 [(7-c)*65 +: 65]，valid 在该段最高位。

为什么要钉：Connect0（tag 通道）只有通道 0 的输出被 CtrlUnit 用到，通道 1..7 的 455 位
payload 寄存器两侧都无人读（unread）。FM 不给无扇出的点做签名配对 ⇒ 实测
（2026-09-28 非正式试跑）它们成了 455(455) 个 unmatched unread，strict 判 PARTIAL。
钉上之后它们成为 matched-unread，再由 vmucp（verif/fm_target_config/CtrlUnit.tcl）真比较。
两个 Connect 用同一条规则全部钉（2 × 520 = 1040 对），不为死位单独人工强配。

布局事实不靠手抄：生成时从 golden NewPipelineConnectPipe_27.sv 读出全部 data_* 寄存器
（名字与位宽），与本脚本的布局规则逐个核对（数量、位宽、无遗漏），不一致即失败。
钉点 tcl fail-closed：每次 set_user_match 必须返回 1，计数必须 == 1040。

用法：python3 scripts/gen_ctrlunit_pins.py [--check]
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
OUT = os.path.join(REPO, "verif", "ut", "CtrlUnit", "fm_pins_pre.tcl")

LANES, MASK_W = 8, 64
LANE_W = 1 + MASK_W
PIPES = ["CtrlUnitPseudoErrorPipelineConnect0", "CtrlUnitPseudoErrorPipelineConnect1"]


def golden_data_regs():
    txt = open(os.path.join(G, "NewPipelineConnectPipe_27.sv")).read()
    regs = {}
    for m in re.finditer(r'^\s*reg\s+(?:\[(\d+):0\]\s+)?(data_\w+)\s*;', txt, re.M):
        regs[m.group(2)] = int(m.group(1)) + 1 if m.group(1) else 1
    return regs


def layout():
    """[(golden 寄存器名, 位宽, impl 起始位)]"""
    out = []
    for c in range(LANES):
        base = (LANES - 1 - c) * LANE_W
        out.append((f"data_{c}_valid", 1, base + MASK_W))
        out.append((f"data_{c}_mask", MASK_W, base))
    return out


def gen():
    regs = golden_data_regs()
    lay = layout()
    want = {n: w for n, w, _ in lay}
    if regs != want:
        raise SystemExit(f"golden data_* 寄存器与布局规则不一致:\n golden={regs}\n rule={want}")
    bits = sum(w for _, w, _ in lay)
    if bits != LANES * LANE_W:
        raise SystemExit(f"布局位数 {bits} != {LANES * LANE_W}")
    expect = bits * len(PIPES)
    L = []
    L.append("# CtrlUnit FM「匹配前」钉点 —— 由 scripts/gen_ctrlunit_pins.py 生成，勿手改。")
    L.append("# 只消命名鸿沟：不约束 ref、不放宽 appvar、不扩黑盒、不 dont_verify。")
    L.append("# 对象与依据见生成器文件头。ref  r:/WORK/CtrlUnit/<pipe>/data_<c>_{valid,mask}_reg[b]")
    L.append("#                          impl i:/WORK/CtrlUnit/<pipe>/u_core/data_reg[(7-c)*65 + (valid ? 64 : b)]")
    L.append(f"# fail-closed：每次 set_user_match 必须返回 1；配对数必须 == {expect}。")
    L.append("# 本目录只有 CtrlUnit 一个 FM 目标；防御性地按 $top 限定。")
    L.append('if {$top ne "CtrlUnit"} { error "CU_PREPIN_WRONG_TOP=$top" }')
    L.append("set _cu_n 0")
    L.append("set _cu_fields {")
    for n, w, lo in lay:
        L.append(f"    {{{n} {w} {lo}}}")
    L.append("}")
    L.append("foreach _cu_pipe {" + " ".join(PIPES) + "} {")
    L.append("    foreach _cu_f $_cu_fields {")
    L.append("        lassign $_cu_f _cu_name _cu_w _cu_lo")
    L.append("        for {set _cu_b 0} {$_cu_b < $_cu_w} {incr _cu_b} {")
    L.append("            if {$_cu_w == 1} {")
    L.append('                set _cu_r "r:/WORK/CtrlUnit/$_cu_pipe/${_cu_name}_reg"')
    L.append("            } else {")
    L.append('                set _cu_r "r:/WORK/CtrlUnit/$_cu_pipe/${_cu_name}_reg\\[$_cu_b\\]"')
    L.append("            }")
    L.append('            set _cu_i "i:/WORK/CtrlUnit/$_cu_pipe/u_core/data_reg\\[[expr {$_cu_lo + $_cu_b}]\\]"')
    L.append("            if {![set_user_match $_cu_r $_cu_i]} {")
    L.append('                puts "CU_PREPIN_FAIL: set_user_match returned 0 for $_cu_r <-> $_cu_i"')
    L.append('                error "CU_PREPIN_MISS=$_cu_r"')
    L.append("            }")
    L.append("            incr _cu_n")
    L.append("        }")
    L.append("    }")
    L.append("}")
    L.append(f'puts "CU_PREPIN_END n=$_cu_n expect={expect}"')
    L.append(f'if {{$_cu_n != {expect}}} {{ error "CU_PREPIN_COUNT=$_cu_n" }}')
    return "\n".join(L) + "\n"


def main():
    txt = gen()
    old = open(OUT).read() if os.path.exists(OUT) else None
    if "--check" in sys.argv:
        if old != txt:
            print(f"[gencheck] {OUT} 与生成结果不一致")
            return 1
        print(f"[gencheck] {OUT} OK")
        return 0
    if old != txt:
        open(OUT, "w").write(txt)
        print(f"wrote {OUT}")
    else:
        print(f"unchanged {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
