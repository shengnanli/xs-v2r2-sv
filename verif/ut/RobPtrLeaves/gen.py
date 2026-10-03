#!/usr/bin/env python3
"""生成 RobPtrLeaves 的双例化 UT testbench（tb.sv）。

三对 golden vs 重写 <名>_xs（scripts/dual_tb_lib.py，端口表读 G1 golden），每拍全部输出逐位 !==：
  * CommitStuckCounter：io_stuck 按 mode 偏置成长串 1；每 4000 拍把两侧 count 同时
    force 到 2^21-32 再放开，让溢出（&count）在 200k 拍内真的发生（自然计满要 2M 拍）。
  * RobEnqPtrWrapper：redirect 稀疏（1/16），robIdx 多数合法（<160）、少量非法（>=160，golden
    同式计算，照比）；allowEnqueue/hasBlockBackward 偏置让大多数拍真入队，指针绕圈翻 flag。
  * NewRobDeqPtrWrapper：state 多数 0；deq_v/deq_w/hasCommitted 按 mode 在"全能提交 /
    前缀能提交 / 随机"间切换；exception_state.robIdx 有一半时间对准队头，让 redirectOutValid 真触发。
覆盖：溢出、redirect 两种 level、指针回绕、allowOnlyOneCommit 两态、冲刷判定、提交使能。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

# ---------------- CommitStuckCounter ----------------
CS_DECLS = """
always @(negedge clk) if (cyc % 4000 == 1000) begin
  force cs_u_gold.count = 21'h1FFFE0;
  force cs_u_impl.u_core.count = 21'h1FFFE0;
  #1;
  release cs_u_gold.count;
  release cs_u_impl.u_core.count;
end
"""
CS_STIM = """
case (@mode % 4)
  0: @io_stuck = 1'b1;
  1: @io_stuck = ($urandom_range(0, 63) != 0);
  2: @io_stuck = ($urandom_range(0, 3) != 0);
  3: ;
endcase
if (cyc % 4000 >= 990 && cyc % 4000 < 1100) @io_stuck = 1'b1;
"""
CS_COV = [
    ("overflow", "@io_overflow"),
    ("stuck_run", "cs_u_gold.count > 21'd100"),
]

# ---------------- RobEnqPtrWrapper ----------------
EQ_STIM = """
@io_redirect_valid = ($urandom_range(0, 15) == 0);
@io_redirect_bits_robIdx_value = ($urandom_range(0, 31) == 0) ? 8'($urandom_range(160, 255))
                                                               : 8'($urandom_range(0, 159));
@io_allowEnqueue = ($urandom_range(0, 7) != 0);
@io_hasBlockBackward = ($urandom_range(0, 15) == 0);
if (@mode % 3 == 0) {@io_enq_5, @io_enq_4, @io_enq_3, @io_enq_2, @io_enq_1, @io_enq_0} = 6'h3F;
"""
EQ_COV = [
    ("redirect_lvl1", "@io_redirect_valid && @io_redirect_bits_level"),
    ("redirect_lvl0", "@io_redirect_valid && !@io_redirect_bits_level"),
    ("redirect_illegal", "@io_redirect_valid && @io_redirect_bits_robIdx_value >= 8'd160"),
    ("enq6", "!@io_redirect_valid && @io_allowEnqueue && !@io_hasBlockBackward && "
             "({@io_enq_5, @io_enq_4, @io_enq_3, @io_enq_2, @io_enq_1, @io_enq_0} == 6'h3F)"),
    ("wrap0", "@io_out_0_value >= 8'd155"),
    ("flag5", "@io_out_5_flag"),
]

# ---------------- NewRobDeqPtrWrapper ----------------
DQ_STIM = """
@io_state = ($urandom_range(0, 7) == 0) ? 2'($urandom) : 2'd0;
case (@mode % 4)
  0: begin  // 整行都能提交
    {@io_deq_v_7, @io_deq_v_6, @io_deq_v_5, @io_deq_v_4, @io_deq_v_3, @io_deq_v_2, @io_deq_v_1, @io_deq_v_0} = 8'hFF;
    {@io_deq_w_7, @io_deq_w_6, @io_deq_w_5, @io_deq_w_4, @io_deq_w_3, @io_deq_w_2, @io_deq_w_1, @io_deq_w_0} = 8'hFF;
  end
  1: begin  // 前缀能提交
    automatic int k = $urandom_range(0, 8);
    automatic logic [7:0] m = 8'((16'h1 << k) - 1);
    {@io_deq_v_7, @io_deq_v_6, @io_deq_v_5, @io_deq_v_4, @io_deq_v_3, @io_deq_v_2, @io_deq_v_1, @io_deq_v_0} = m | 8'($urandom);
    {@io_deq_w_7, @io_deq_w_6, @io_deq_w_5, @io_deq_w_4, @io_deq_w_3, @io_deq_w_2, @io_deq_w_1, @io_deq_w_0} = m;
    {@io_hasCommitted_7, @io_hasCommitted_6, @io_hasCommitted_5, @io_hasCommitted_4, @io_hasCommitted_3, @io_hasCommitted_2, @io_hasCommitted_1, @io_hasCommitted_0} = 8'($urandom) & 8'($urandom) & 8'($urandom);
  end
  default: ;
endcase
@io_blockCommit = ($urandom_range(0, 7) == 0);
@io_allowOnlyOneCommit = ($urandom_range(0, 3) == 0);
@io_intrBitSetReg = ($urandom_range(0, 15) == 0);
@io_exception_state_valid = ($urandom_range(0, 3) == 0);
if ($urandom_range(0, 1)) begin  // 对准队头，让 exceptionEnable 能成立
  @io_exception_state_bits_robIdx_flag = dq_u_gold.deqPtrVec_0_flag;
  @io_exception_state_bits_robIdx_value = dq_u_gold.deqPtrVec_0_value;
end
@io_exception_state_bits_trigger = ($urandom_range(0, 3) == 0) ? 4'd1 : 4'($urandom);
@io_exception_state_bits_hasException = ($urandom_range(0, 3) == 0);
@io_exception_state_bits_replayInst = ($urandom_range(0, 7) == 0);
@io_exception_state_bits_singleStep = ($urandom_range(0, 7) == 0);
"""
DQ_COV = [
    ("redirect_out", "dq_u_gold.redirectOutValid"),
    ("commit_en", "dq_u_gold._deqPtrVec_next_T_4"),
    ("only_one", "@io_allowOnlyOneCommit && dq_u_gold._deqPtrVec_next_T_4"),
    ("full_line", "!@io_allowOnlyOneCommit && dq_u_gold._deqPtrVec_next_T_4 && @io_canCommitPriorityCond_8 && "
                  "!@io_canCommitPriorityCond_0 && !@io_canCommitPriorityCond_7"),
    ("wrap", "@io_next_out_7_flag != @io_out_7_flag"),
    ("trigger_dbg", "dq_u_gold.redirectOutValid && @io_exception_state_bits_trigger == 4'd1"),
]

PAIRS = [
    Pair("CommitStuckCounter", "cs_", clocked=True, stim=CS_STIM, cov=CS_COV, decls=CS_DECLS,
         mode_period=3000, reset_period=50000, cov_min=40),
    Pair("RobEnqPtrWrapper", "eq_", clocked=True, stim=EQ_STIM, cov=EQ_COV,
         mode_period=500, reset_period=40000, cov_min=100),
    Pair("NewRobDeqPtrWrapper", "dq_", clocked=True, stim=DQ_STIM, cov=DQ_COV,
         mode_period=500, reset_period=40000, cov_min=100),
]

HEADER = """自动生成：verif/ut/RobPtrLeaves/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
Rob 的三个指针/计数子模块双例化逐拍比对：golden <名> vs 重写 <名>_xs，全部输出逐位 !==。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
