#!/usr/bin/env python3
"""生成 ExuBlock_2 的双例化 UT testbench（照 verif/ut/ExuBlock_1/gen.py，只换 TOP；下文激励说明沿用其通用部分）（tb.sv，scripts/dual_tb_lib.py）。

golden ExuBlock_2 vs ExuBlock_2_xs（5 个 ExeUnit 两侧各用各的：golden 侧 golden 子树，重写侧本仓重写子树），
全部输出逐拍逐位 !==。

激励（每个发射口按它所接 ExeUnit 的结构自动推出，与 scripts/gen_exeunits_ut.py 的 ExeUnit 激励同一套路）：
  * fuType：85% 取该 ExeUnit 某个 FU 的编码（Dispatcher 的 acceptVec 常量，从 golden 解析），其余全随机
    （多数不命中任何 FU，Dispatcher 吞掉 —— 两侧也必须一致）；valid 60%；
  * 有 out.ready 口的（ExeUnit_9 = FDivSqrt，不定延迟）10% 反压；
  * robIdx 3/4 与冲刷 robIdx 取窄范围 0..15（冲刷比较两种结果都常见），冲刷 10%；
  * FDivSqrt 口 1/8 除数为 0（除零标志 DZ）；
  * frm 每拍随机（本层打一拍再送 ExeUnit）；DFT 时钟门控 cg_bore_*_cgen 1/20 强开；
  * 暖机：复位撤销后 WARM 拍内每个发射口轮流给本 ExeUnit 每个 FU 发有效指令、不反压不冲刷，
    把各级不复位的寄存器写成确定值；之后才开始比（warmup）。
恒值输出位（无 busy 外壳的 in.ready、无 FDivSqrt 外壳的 fflags[3]、golden 写成 {64'h0, ..} 的数据高 64 位）
不要求见过 0/1，但照样逐拍比。
覆盖（每项 >= cov_min，否则 TEST FAILED）：每个发射口 fire、每个 FU 写回、每个可反压口的反压、冲刷、busy。

用法：python3 gen.py [--check]
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check, G as GOLDEN  # noqa: E402
import gen_exeunit  # noqa: E402

TOP = "ExuBlock_2"
X = "eb_"
G = X + "u_gold"
WARM_END = 8 + 48      # RESET_CYC 之后 48 拍暖机


def golden_insts():
    txt = open(os.path.join(GOLDEN, TOP + ".sv")).read()
    out = []
    for m in re.finditer(r"^  (ExeUnit_\d+) (\w+) \(\n(.*?)^  \);", txt, re.S | re.M):
        cm = dict((c.group(1), " ".join(c.group(2).split()))
                  for c in re.finditer(r"\.(\w+)\s*\((.*?)\)\s*(?:,|$)", m.group(3), re.S))
        out.append((m.group(1), m.group(2), cm["io_in_valid"][:-len("_valid")], cm["io_out_valid"][:-len("_valid")]))
    return out


def fu_codes(typ):
    v = gen_exeunit.Variant(typ)
    disp = open(os.path.join(GOLDEN, v.disp[0] + ".sv")).read()
    codes = []
    for k in range(len(v.fus)):
        m = re.search(r"wire\s+(?:acceptVec_%d|data_0_probe) = io_in_bits_fuType == 35'h([0-9A-F]+);" % k, disp)
        if not m:
            raise SystemExit("%s: 找不到 Dispatcher 出口 %d 的 fuType 编码" % (typ, k))
        codes.append(m.group(1))
    return v, codes



# ExuBlock_2 额外的恒值输出位（不要求见过 0/1，照样逐拍比），逐条有依据：
#   * exus_1（ExeUnit_14）的 data_5：golden ExeUnit_14 写 {64'h0, VSetRvfWvf.res_data}（上面通用规则已豁免 [127:64]），而
#     golden VSetRvfWvf.res_data = {56'h0, vl 或 src_4[7:0]} —— [63:8] 结构上恒 0；
#   * exus_3（ExeUnit_16，只有 VFAlu）的 fflags[1]（UF 下溢）：VFAlu 只做同格式/加宽的加减、比较、min/max、符号注入，
#     IEEE 754 下这些运算结果落入次正规区时都是精确的，不会报下溢 —— 语义上不可能为 1，激励无法覆盖。
EXTRA_EXEMPT = (["io_out_0_1_bits_data_5[%d]" % b for b in range(8, 64)] + ["io_out_1_1_bits_fflags[1]"])

INSTS = golden_insts()
ports = {n for _, _, n in Pair(TOP, X).ports}
DECLS, STIM, COV, EXEMPT = [], [], [], []
STIM += ["@io_flush_valid = (cyc >= %d) && ($urandom_range(0, 9) == 0);" % WARM_END,
         "@io_flush_bits_robIdx_value = 8'($urandom_range(0, 15));"]
for n in sorted(ports):
    if re.fullmatch(r"cg_bore(_\d+)?_cgen", n):
        STIM.append("@%s = ($urandom_range(0, 19) == 0);" % n)
COV += [("flush", "@io_flush_valid")]
for typ, iname, pin, pout in INSTS:
    v, codes = fu_codes(typ)
    tbl = "%s%s_code" % (X, iname)
    DECLS.append("logic [34:0] %s [%d] = '{%s};" % (tbl, len(codes), ", ".join("35'h" + c for c in codes)))
    STIM += [
        "if ($urandom_range(0, 99) < 85) @%s_bits_fuType = %s[$urandom_range(0, %d)];" % (pin, tbl, len(codes) - 1),
        "@%s_valid = ($urandom_range(0, 9) < 6);" % pin,
        "if ($urandom_range(0, 3) != 0) @%s_bits_robIdx_value = 8'($urandom_range(0, 15));" % pin,
    ]
    if v.has_busy:   # FDivSqrt：1/8 除数为 0（DZ 标志）
        STIM.append("if ($urandom_range(0, 7) == 0) @%s_bits_src_1 = '0;" % pin)
    # 恒值输出位（不要求见过 0/1，照样逐拍比）：
    #   无 busy 的 ExeUnit 的 in.ready 恒 1；没有 FDivSqrt 的 ExeUnit fflags[3]（DZ）恒 0；
    #   golden ExeUnit 里写成 {64'h0, ...} 的数据口高 64 位恒 0
    if not v.has_busy:
        EXEMPT.append(pin + "_ready")
    if not any(t == "FDivSqrt" for t, _, _ in v.fus):
        EXEMPT.append(pout + "_bits_fflags[3]")
    etxt = open(os.path.join(GOLDEN, typ + ".sv")).read()
    for m in re.finditer(r"assign io_out_bits_(data_\d+) = \{64'h0,", etxt):
        EXEMPT += ["%s_bits_%s[%d]" % (pout, m.group(1), b) for b in range(64, 128)]
    has_ready = (pout + "_ready") in ports
    if has_ready:
        STIM.append("@%s_ready = ($urandom_range(0, 9) != 0);" % pout)
    STIM += ["if (cyc >= 8 && cyc < %d) begin" % WARM_END,
             "  @%s_valid = 1'b1;" % pin,
             "  @%s_bits_fuType = %s[cyc %% %d];" % (pin, tbl, len(codes))]
    if has_ready:
        STIM.append("  @%s_ready = 1'b1;" % pout)
    STIM.append("end")
    COV.append(("%s_fire" % iname, "@%s_valid && @%s_ready" % (pin, pin)))
    for _, fu, _ in v.fus:
        COV.append(("%s_%s_out" % (iname, fu), "%s.%s._%s_io_out_valid" % (G, iname, fu)))
    if has_ready:
        COV.append(("%s_stall" % iname, "@%s_valid && !@%s_ready" % (pout, pout)))
    if v.has_busy:
        COV.append(("%s_busy" % iname, "%s.%s.busy" % (G, iname)))

EXEMPT += EXTRA_EXEMPT
PAIRS = [Pair(TOP, X, clocked=True, stim="\n".join(STIM), cov=COV, decls="\n".join(DECLS), exempt=EXEMPT,
              warmup=WARM_END - 8, reset_period=20000, mode_period=2000, cov_min=1000)]

HEADER = """自动生成：verif/ut/ExuBlock_2/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
ExuBlock_2 双例化逐拍比对，全部输出逐位 !==。"""

if __name__ == "__main__":
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), render(PAIRS, HEADER), "--check" in sys.argv))
