#!/usr/bin/env python3
"""生成 CsrDebugTime4 的双例化 UT testbench（tb.sv）。

4 对 golden <M> vs 重写 <M>_xs（scripts/dual_tb_lib.py，端口表读 G1 golden），每拍逐位比较全部输出：
  * Debug            —— 进 debug 模式的五种原因 + 4 个 mcontrol6 触发器分发。golden 只有 clock
                        没有 reset（两级打拍寄存器不复位）：clocked=True + has_reset=False，clock 接 tb clk；
                        warmup=8 冲刷两级不复位打拍寄存器。（随机驱动 clock 的做法试过：数据与时钟沿同一
                        时刻变化，always_ff 读连续赋值网线与 golden 内联表达式之间有调度竞争，是 tb 假失配。）
                        偏置：tdata1 TYPE 75% 取合法值 6（否则所有使能恒 0）；trigger 动作偏向 0/1/15。
  * MieModule        —— 三路 sideband（sie/hie/vsie）与 CSR 写的优先级。sideband valid 分"稀疏/全随机"两档，
                        否则 CSR 写几乎永远被 sideband 压住。
  * timeModule       —— 不复位的 time 副本：arm 条件 = 一次未被 STOPTIME 挡住的 tick（下一拍两侧同值）。
  * XRetPermitModule —— 纯组合。
覆盖闸：每个输出位都见过 0 和 1 + 各 pair 的事件计数。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

DEBUG_STIM = """
if ($urandom_range(0, 3) != 0) @io_in_tdata1Vec_0_TYPE = 4'd6;
if ($urandom_range(0, 3) != 0) @io_in_tdata1Vec_1_TYPE = 4'd6;
if ($urandom_range(0, 3) != 0) @io_in_tdata1Vec_2_TYPE = 4'd6;
if ($urandom_range(0, 3) != 0) @io_in_tdata1Vec_3_TYPE = 4'd6;
if ($urandom_range(0, 3) != 0) @io_in_tdata1Wdata_TYPE = 4'd6;
case ($urandom_range(0, 3))
  0: @io_in_trapInfo_bits_trigger = 4'd0;
  1: @io_in_trapInfo_bits_trigger = 4'd1;
  2: @io_in_trapInfo_bits_trigger = 4'd15;
  default: ;
endcase
if (@mode % 2 == 0) begin
  @io_in_tdata1Vec_0_DATA[11] = ($urandom_range(0, 3) == 0);
  @io_in_tdata1Vec_1_DATA[11] = ($urandom_range(0, 3) == 0);
  @io_in_tdata1Vec_2_DATA[11] = ($urandom_range(0, 3) == 0);
  @io_in_tdata1Vec_3_DATA[11] = ($urandom_range(0, 3) == 0);
end
"""
DEBUG_COV = [
    ("ebreak_dbg", "@io_out_hasDebugEbreakException"),
    ("trig_dmode", "@io_out_triggerEnterDebugMode"),
    ("single_step", "@io_out_hasSingleStep"),
    ("debug_intr", "@io_out_hasDebugIntr"),
    ("crit_err", "@io_out_criticalErrorStateEnterDebug"),
    ("chain_legal", "@io_out_newTriggerChainIsLegal"),
    ("chain_illegal", "!@io_out_newTriggerChainIsLegal"),
    ("fe_upd_valid", "@io_out_frontendTrigger_tUpdate_valid"),
    ("mem_upd_valid", "@io_out_memTrigger_tUpdate_valid"),
    ("fe_enable", "@io_out_frontendTrigger_tEnableVec_3"),
    ("mem_enable", "@io_out_memTrigger_tEnableVec_0"),
]

MIE_SIDE = ["fromHie_VSSIE", "fromHie_VSTIE", "fromHie_VSEIE", "fromHie_SGEIE",
            "fromSie_SSIE", "fromSie_STIE", "fromSie_SEIE", "fromSie_LCOFIE",
            "fromVSie_VSSIE", "fromVSie_VSTIE", "fromVSie_VSEIE", "fromVSie_LCOFIE"]
MIE_STIM = ("if (@mode % 2 == 0) begin\n"
            + "".join("  if ($urandom_range(0, 7) != 0) @%s_valid = 1'b0;\n" % s for s in MIE_SIDE)
            + "end\n")
MIE_COV = [
    ("csr_wr_only", "@w_wen && !@fromSie_SSIE_valid"),
    ("sie_wr", "@fromSie_SSIE_valid"),
    ("hie_vsie_both", "@fromHie_VSSIE_valid && @fromVSie_VSSIE_valid"),
    ("vsie_lcofi", "@fromVSie_LCOFIE_valid && !@fromSie_LCOFIE_valid"),
    ("m_bit_set", "@regOut_MEIE"),
]
# rdata 只有 1/2/3/5/6/7/9..13 是寄存器，其余位 golden 硬零。
MIE_EXEMPT = ["rdata[%d]" % b for b in range(64) if b not in (1, 2, 3, 5, 6, 7, 9, 10, 11, 12, 13)]

TIME_COV = [
    ("tick", "@mHPM_time_valid && !@debugModeStopTime"),
    ("stopped_tick", "@mHPM_time_valid && @debugModeStopTime"),
    ("v_change", "@nextV != @v"),
    ("guest_view", "@v"),
]

XRET_COV = [
    ("ex_ii", "@io_out_Xret_EX_II"),
    ("ex_vi", "@io_out_Xret_EX_VI"),
    ("legal_sret", "@io_out_hasLegalSret"),
    ("legal_mnret", "@io_out_hasLegalMNret"),
]

PAIRS = [
    Pair("Debug", "dbg_", clocked=True, has_reset=False, stim=DEBUG_STIM, cov=DEBUG_COV, warmup=8),
    Pair("MieModule", "mie_", clocked=True, stim=MIE_STIM, cov=MIE_COV, exempt=MIE_EXEMPT),
    Pair("timeModule", "tm_", clocked=True, cov=TIME_COV,
         arm=["@mHPM_time_valid && !@debugModeStopTime"]),
    Pair("XRetPermitModule", "xr_", clocked=False, cov=XRET_COV),
]

HEADER = """
tb —— CsrDebugTime4：NewCSR 下 4 个叶（Debug / MieModule / timeModule / XRetPermitModule）的双例化 UT。
本文件由 gen.py 生成（scripts/dual_tb_lib.py），勿手改。
"""

if __name__ == "__main__":
    txt = render(PAIRS, header=HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, check="--check" in sys.argv))
