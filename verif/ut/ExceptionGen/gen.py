#!/usr/bin/env python3
"""生成 ExceptionGen 的双例化 UT testbench（tb.sv）。

golden ExceptionGen vs 重写 ExceptionGen_xs（scripts/dual_tb_lib.py，端口表读 G1 golden），逐拍比全部
io_state_* 输出。

激励：robIdx 多数取在一个 8 项的小窗口里（翻转位也随机）——制造"谁更老 / 同一条指令"的各种比较；
  1/8 的拍全随机。enq / 写回各口约 1/3 的拍有效，异常标志按比例置位（hasException、flushPipe、
  replayInst、singleStep、trigger==1 断点），vstart / vuopIdx 多取小值以制造同指令合并时的大小比较。
  redirect 约 1/8 的拍有效（level 随机、robIdx 同窗口），flush 约 1/64。
初态：寄存器除 currentValid 外都不复位。开头 RESET_CYC+3 拍强制 flush=1，把各级有效位冲成 0；
  比较窗口在 golden 第一次 io_state_valid=1 之后打开（arm）——那一拍 current 整条被写入，
  此前 current 的内容是两侧各自的上电随机值。
覆盖闸（golden 内部信号）：s1 比 current 老整条替换、同一条指令合并、空 current 收 enq、
  current 被冲掉，各 >= 200 次；每个输出位见过 0 和 1。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check, golden_ports  # noqa: E402

DECLS = """
logic       eg_win_flag = 1'b0;
logic [7:0] eg_win_base = 8'd0;
function automatic logic [8:0] eg_rob();
  logic [7:0] v;
  if ($urandom_range(0, 7) == 0) return 9'($urandom);
  v = eg_win_base + 8'($urandom_range(0, 7));
  return {eg_win_flag ^ ($urandom_range(0, 15) == 0), v};
endfunction
"""

stim = []
stim.append("if ($urandom_range(0, 999) == 0) begin eg_win_flag = $urandom; eg_win_base = $urandom; end")
stim.append("@io_flush = (cyc < RESET_CYC + 3) || ($urandom_range(0, 63) == 0);")
stim.append("@io_redirect_valid = ($urandom_range(0, 7) == 0);")
stim.append("{@io_redirect_bits_robIdx_flag, @io_redirect_bits_robIdx_value} = eg_rob();")
for d, w, n in golden_ports("ExceptionGen"):
    if d != "input":
        continue
    if n.endswith("_valid") and (n.startswith("io_enq_") or n.startswith("io_wb_")):
        stim.append("@%s = ($urandom_range(0, 2) == 0);" % n)
    elif n.endswith("_robIdx_flag") and not n.startswith("io_redirect"):
        base = n[:-len("_flag")]
        stim.append("{@%s_flag, @%s_value} = eg_rob();" % (base, base))
    elif n.endswith("_hasException"):
        stim.append("@%s = ($urandom_range(0, 2) == 0);" % n)
    elif n.endswith(("_flushPipe", "_replayInst", "_singleStep", "_satpFlushPipe")):
        stim.append("@%s = ($urandom_range(0, 7) == 0);" % n)
    elif n.endswith("_trigger"):
        stim.append("@%s = ($urandom_range(0, 7) == 0) ? 4'h1 : 4'($urandom);" % n)
    elif n.endswith("_vstart"):
        stim.append("@%s = ($urandom_range(0, 3) == 0) ? {$urandom, $urandom} : 64'($urandom_range(0, 7));" % n)
    elif n.endswith("_vuopIdx"):
        stim.append("@%s = ($urandom_range(0, 3) == 0) ? 7'($urandom) : 7'($urandom_range(0, 3));" % n)
    elif "_exceptionVec_" in n:
        stim.append("@%s = ($urandom_range(0, 3) == 0);" % n)
STIM = "\n".join(stim)

G = "eg_u_gold."
COV = [
    ("s1_older_replace", G + "currentValid & " + G + "_GEN_2"),
    ("s1_same_merge", G + "currentValid & " + G + "_GEN & " + G + "_GEN_3"),
    ("enq_into_empty", "~" + G + "currentValid & ~" + G + "_GEN & " + G + "_GEN_0"),
    ("current_flushed", G + "currentValid & @io_redirect_valid"),
]

PAIRS = [
    Pair("ExceptionGen", "eg_", clocked=True, stim=STIM, decls=DECLS, cov=COV,
         arm=["@io_state_valid"], cov_min=200, reset_period=20000),
]

HEADER = """自动生成：verif/ut/ExceptionGen/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
ExceptionGen 双例化逐拍比对：golden vs 重写 ExceptionGen_xs，全部 io_state_* 逐位 !==。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
