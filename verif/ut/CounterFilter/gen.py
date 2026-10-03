#!/usr/bin/env python3
"""生成 CounterFilter 的双例化 UT testbench（tb.sv）。

golden CounterFilter vs 重写 CounterFilter_xs（scripts/dual_tb_lib.py，端口表读 G1 golden），
每拍逐位比较 3 个 query resp。
激励：ld_in / query 的 idx 压到 0..3、way 随机，让查询大量命中 FIFO 里的项；
  ld_in valid 按 mode 分"稀疏 / 半数 / 全满（3 口全 valid，逼出 canAlloc=0 的满队列）"三档。
覆盖：各口 canAlloc、满拒（needAlloc & !canAlloc）、出队 1/2/3 项、指针回绕翻 flag、各 query 命中。
全部寄存器（除 allocNum 的三级 RegNext）异步复位；RegNext 链在上电复位的 8 拍内被写满。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

STIM = """
@io_ld_in_0_bits_idx = 8'($urandom_range(0, 3));
@io_ld_in_1_bits_idx = 8'($urandom_range(0, 3));
@io_ld_in_2_bits_idx = 8'($urandom_range(0, 3));
@io_query_0_req_bits_idx = 8'($urandom_range(0, 3));
@io_query_1_req_bits_idx = 8'($urandom_range(0, 3));
@io_query_2_req_bits_idx = 8'($urandom_range(0, 3));
case (@mode % 3)
  0: begin  // 稀疏
    @io_ld_in_0_valid = ($urandom_range(0, 7) == 0);
    @io_ld_in_1_valid = ($urandom_range(0, 7) == 0);
    @io_ld_in_2_valid = ($urandom_range(0, 7) == 0);
  end
  1: ;      // 半数
  2: begin  // 全满
    @io_ld_in_0_valid = 1'b1; @io_ld_in_1_valid = 1'b1; @io_ld_in_2_valid = 1'b1;
  end
endcase
"""

G = "cf_u_gold."
COV = [
    ("alloc0", G + "canAlloc_0"),
    ("alloc1", G + "canAlloc_1"),
    ("alloc2", G + "canAlloc_2"),
    ("reject", "(@io_ld_in_0_valid && !%scanAlloc_0) || (@io_ld_in_2_valid && !%scanAlloc_2)" % (G, G)),
    ("deq1", G + "last3CycleAlloc == 2'd1"),
    ("deq2", G + "last3CycleAlloc == 2'd2"),
    ("deq3", G + "last3CycleAlloc == 2'd3"),
    ("enq_wrap", "(|%s_GEN_64) && %senqPtrExt_0_reverse_flag" % (G, G)),
    ("deq_wrap", G + "deqPtrExt_0_reverse_flag && (|%slast3CycleAlloc)" % G),
    ("hit0", "@io_query_0_resp"),
    ("hit2", "@io_query_2_resp"),
    ("miss0", "@io_query_0_req_valid && !@io_query_0_resp"),
]

PAIRS = [
    Pair("CounterFilter", "cf_", clocked=True, stim=STIM, cov=COV,
         mode_period=500, reset_period=30000, cov_min=500),
]

HEADER = """自动生成：verif/ut/CounterFilter/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
CounterFilter 双例化逐拍比对：golden CounterFilter vs 重写 CounterFilter_xs，全部输出逐位 !==。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
