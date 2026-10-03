#!/usr/bin/env python3
"""生成 PredChecker 的双例化 UT testbench（tb.sv）。

golden PredChecker vs 重写 PredChecker_xs（scripts/dual_tb_lib.py，端口表读 G1 golden），
每拍逐位比较全部 stage1 / stage2 输出。
PredChecker 有 clock 没有 reset：dual_tb_lib 的 clocked 模式要求两者都有，所以这里按
非 clocked 生成、再把两处 `.clock(pc_clock)` 机械替换成 tb 的 clk（替换数必须正好 2，否则失败）。
stage2 寄存器全部不复位：arm 条件 = 见过一次 fire_in（之后两侧寄存器同值）。
激励：pc[i] = pc[0] + 2*i；brType 压向 notCFI（3/4），让「漏跳」稀疏、fixedRange 的截断点分散；
  mode 为偶数时是「干净包」（只有预测跳的那条是 br/jal），专门走第二步检查；
  instrRange 多数拍是「低位连续 1」的真实形态；预测目标一半的拍取 pc[takenIdx] + offset[takenIdx]
  （目标正确），另一半随机（目标错）；offset 一半小范围、一半全随机。
覆盖：六种 faultType、无错、remask 截断、fixedTaken、stage2 各类 fault 位、fire_in 为 0 时保持。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

N = 16
DECLS = """
logic [49:0] pc_pc0;
logic [49:0] pc_tgt [16];
int unsigned pc_rng_end;
"""

L = ["pc_pc0 = 50'({$urandom, $urandom});",
     "pc_rng_end = $urandom_range(0, 15);"]
for i in range(N):
    L += [
        "@io_in_pc_%d = pc_pc0 + 50'd%d;" % (i, 2 * i),
        "if ($urandom_range(0, 3) != 0) @io_in_pds_%d_brType = 2'd0;" % i,
        "@io_in_pds_%d_isRet = (@io_in_pds_%d_brType == 2'd3) ? 1'($urandom) : ($urandom_range(0, 31) == 0);" % (i, i),
        "if ($urandom_range(0, 1)) @io_in_jumpOffset_%d = 64'($signed(32'($urandom_range(0, 4096)) - 32'd2048));" % i,
        "if ($urandom_range(0, 3) != 0) @io_in_instrRange_%d = (%d <= pc_rng_end);" % (i, i),
        "if ($urandom_range(0, 7) != 0) @io_in_instrValid_%d = 1'b1;" % i,
        "pc_tgt[%d] = @io_in_pc_%d + @io_in_jumpOffset_%d[49:0];" % (i, i, i),
    ]
# 「干净包」档（mode 为偶数）：只有预测跳的那条是 br/jal，其余全是非控制流 —— 没有漏跳，
# 第二步检查（目标对 / 目标错 / notCFI / invalidTaken）才大量走到
L += ["if (@mode % 2 == 0) begin"]
for i in range(N):
    L += ["  @io_in_pds_%d_isRet = 1'b0;" % i,
          "  @io_in_pds_%d_brType = (@io_in_ftqOffset_bits == 4'd%d && $urandom_range(0, 7) != 0) ? 2'($urandom_range(1, 2)) : 2'd0;" % (i, i),
          "  if ($urandom_range(0, 7) != 0) @io_in_instrRange_%d = 1'b1;" % i]
L += ["  @io_in_ftqOffset_valid = ($urandom_range(0, 7) != 0);", "end"]
L += [
    "if ($urandom_range(0, 1)) @io_in_target = pc_tgt[@io_in_ftqOffset_bits];",
    "@io_in_fire_in = ($urandom_range(0, 3) != 0);",
]
STIM = "\n".join(L)

COV = [("ft_%d" % v, "@io_out_stage2Out_faultType_3_value == 3'd%d" % v) for v in range(7)]
COV += [
    ("remask_cut", "@io_in_instrRange_9 && !@io_out_stage1Out_fixedRange_9"),
    ("remask_first0", "@io_in_instrRange_1 && !@io_out_stage1Out_fixedRange_1"),
    ("no_remask_full", "&{" + ", ".join("@io_out_stage1Out_fixedRange_%d" % i for i in range(N)) + "}"),
    ("fixed_taken", "@io_out_stage1Out_fixedTaken_7"),
    ("taken_by_pred", "@io_out_stage1Out_fixedTaken_7 && @io_in_pds_7_brType == 2'd1"),
    ("misspred15", "@io_out_stage2Out_fixedMissPred_15"),
    ("tgt_fault15", "@io_out_stage2Out_faultType_15_value == 3'd3"),
    ("tgt_ok", "pc_u_gold.predTakenNext && pc_u_gold.takenIdxNext == 4'd3 && pc_u_gold.instrValidNext_3 && pc_u_gold.fixedRangeNext[3] && pc_u_gold.pdsNext_3_brType == 2'd1 && !pc_u_gold.targetFault_3"),
    ("hold", "!@io_in_fire_in"),
]

PAIRS = [
    Pair("PredChecker", "pc_", clocked=False, stim=STIM, cov=COV, decls=DECLS,
         arm=["@io_in_fire_in"], cov_min=100),
]

HEADER = """自动生成：verif/ut/PredChecker/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
PredChecker 双例化逐拍比对：golden PredChecker vs 重写 PredChecker_xs，全部输出逐位 !==。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    n = txt.count(".clock(pc_clock)")
    if n != 2:
        raise SystemExit("PredChecker tb: 期望 2 处 .clock(pc_clock)，实际 %d" % n)
    txt = txt.replace(".clock(pc_clock)", ".clock(clk)")
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
