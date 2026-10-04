#!/usr/bin/env python3
"""生成 ProbeEntry 的双例化 UT testbench（tb.sv，scripts/dual_tb_lib.py）。

golden ProbeEntry vs 重写 ProbeEntry_xs，全部输出逐拍逐位比较。
激励偏置（让状态机三态都走满）：
  * 3/4 时间地址只在 4 条 cacheline 里取，lrsc_locked_block 也从这 4 条里取 ⇒ LR/SC 阻塞常发生；
    其余时间地址全随机（每个地址位都翻过）；
  * pipe_resp_bits_id 一半概率等于 io_id ⇒ S_WAIT_RESP 能按时释放；io_id 每 2000 拍换一次；
  * req_valid / pipe_req_ready / pipe_resp_valid 各约一半。
req 字段寄存器不复位：第一次 req 握手之后才开始比（arm）。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

DECLS = """
logic [2:0] p_id_q = 3'd0;
function automatic logic [47:0] pick_line(input int unsigned r);
  return {40'h80_0000_00, 2'b00, 2'(r), 6'(r >> 2)};
endfunction
"""

STIM = """
if (cyc % 2000 == 0) p_id_q = 3'($urandom);
@io_id = p_id_q;
if (p_mode < 12) begin   // 3/4 时间地址挤在 4 条行里；其余时间全随机（覆盖每个地址位）
  @io_req_bits_addr = pick_line($urandom);
  @io_lrsc_locked_block_bits = pick_line($urandom);
end
@io_lrsc_locked_block_valid = ($urandom_range(0, 3) != 0);
if ($urandom_range(0, 1)) @io_pipe_resp_bits_id = p_id_q;
"""

COV = [
    ("req_fire", "@io_req_valid && @io_req_ready"),
    ("pipe_fire", "@io_pipe_req_valid && @io_pipe_req_ready"),
    ("pipe_stall", "@io_pipe_req_valid && !@io_pipe_req_ready"),
    ("lrsc_blocked", "p_u_gold.state == 2'd1 && !@io_pipe_req_valid"),
    ("resp_release", "p_u_gold.state == 2'd2 && @io_pipe_resp_valid && @io_pipe_resp_bits_id == @io_id"),
    ("resp_other_id", "p_u_gold.state == 2'd2 && @io_pipe_resp_valid && @io_pipe_resp_bits_id != @io_id"),
    ("reset_mid", "@reset && cyc > 100"),
]

PAIRS = [
    Pair("ProbeEntry", "p_", clocked=True, stim=STIM, cov=COV, decls=DECLS,
         reset_period=2000, cov_min=50,
         # id 高 3 位是常量 0（{3'h0, io_id}），结构上翻不动
         exempt=["io_pipe_req_bits_id[3]", "io_pipe_req_bits_id[4]", "io_pipe_req_bits_id[5]"],
         arm=["@io_req_valid && @io_req_ready"], arm_delay=1),
]

HEADER = """自动生成：verif/ut/ProbeEntry/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
ProbeEntry 双例化逐拍比对，全部输出逐位 !==。"""

if __name__ == "__main__":
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), render(PAIRS, HEADER), "--check" in sys.argv))
