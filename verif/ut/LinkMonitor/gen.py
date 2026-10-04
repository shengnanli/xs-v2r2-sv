#!/usr/bin/env python3
"""生成 LinkMonitor 的双例化 UT testbench（tb.sv）：golden LinkMonitor vs 重写 LinkMonitor_xs
（scripts/dual_tb_lib.py），每拍逐位比较全部输出。
impl 侧闭包 = rtl/uncore/LinkMonitor.sv + 6 个已签重写 child（Decoupled2LCredit{,_1,_2}、
LCredit2Decoupled{,_1,_2}）+ Queue4_CHISNP / xs_ChiselQueuePipe_core；ram_4x115 两侧同源。

激励偏置（按 mode）：
  0  链路 RUN：tx_linkactiveack=1、rx_linkactivereq=1 占 15/16，信用/flit 随机 —— 让 6 个子模块真收发；
  1  去激活：rx_linkactivereq 多为 0，rx flitv 稀疏 —— 走"等 3 个 RX 子模块 reclaim 完才撤 ack"；
  2  全随机。
rx rsp flit 的 opcode 字段 [42:38] 1/8 取 RetryAck(3)、1/8 取 PCrdGrant(7)、1/8 取 0（LCrdReturn）；
tx req 的 allowRetry 半数为 0 —— 让 3 个（无输出的）性能计数器真的在数（FM vmucp 比的就是它们）。
复位：reset_period=1000，约 200 次随机再复位，覆盖"复位撤销后第一拍"的 txsactive / linkactivereq。
arm：不复位的存储要先写过一次两侧才同值 —— 3 个 TX 子模块的 out_flit_r（flitv 时写）、
rxsnp 队列 ram_4x115 的 4 个表项。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

U = "lm_u_gold."
STIM = """
case (@mode % 3)
  0: begin
    @io_out_tx_linkactiveack = ($urandom_range(0, 15) != 0);
    @io_out_rx_linkactivereq = ($urandom_range(0, 15) != 0);
  end
  1: begin
    @io_out_rx_linkactivereq = ($urandom_range(0, 7) == 0);
    @io_out_rx_rsp_flitv = ($urandom_range(0, 7) == 0);
    @io_out_rx_dat_flitv = ($urandom_range(0, 7) == 0);
    @io_out_rx_snp_flitv = ($urandom_range(0, 7) == 0);
  end
  default: ;
endcase
case ($urandom_range(0, 7))
  0: @io_out_rx_rsp_flit[42:38] = 5'h3;
  1: @io_out_rx_rsp_flit[42:38] = 5'h7;
  2: @io_out_rx_rsp_flit[42:38] = 5'h0;
  default: ;
endcase
"""
ARM = [
    f"{U}Decoupled2LCredit_txreqLink.flitv",
    f"{U}Decoupled2LCredit_txrspLink.flitv",
    f"{U}Decoupled2LCredit_txdatLink.flitv",
] + [f"{U}LCredit2Decoupled_rxsnp.queue.do_enq && {U}LCredit2Decoupled_rxsnp.queue.enq_ptr_value == 2'd{k}"
     for k in range(4)]
COV = [
    ("tx_run", f"{U}txState == 2'h2"),
    ("rx_run", f"{U}rxState == 2'h2"),
    ("rx_deact_wait", f"!@io_out_rx_linkactivereq && @io_out_rx_linkactiveack && !{U}_LCredit2Decoupled_rxrsp_io_reclaimLCredit"),
    ("first_cycle_after_reset", f"!@reset && !{U}exitcoDone_REG"),
    ("retry_ack", f"@io_in_rx_rsp_valid && @io_in_rx_rsp_ready && @io_in_rx_rsp_bits_opcode == 5'h3"),
    ("pcrd_grant", f"@io_in_rx_rsp_valid && @io_in_rx_rsp_ready && @io_in_rx_rsp_bits_opcode == 5'h7"),
    ("no_allow_retry_req", f"@io_in_tx_req_valid && @io_in_tx_req_ready && !@io_in_tx_req_bits_allowRetry"),
    ("tx_dat_flit", "@io_out_tx_dat_flitv"),
    ("rx_snp_out", "@io_in_rx_snp_valid && @io_in_rx_snp_ready"),
    ("rx_dat_out", "@io_in_rx_dat_valid && @io_in_rx_dat_ready"),
]
# 结构上恒定的输出：flitpend 复位后恒 1；syscoreq 复位后恒 1（exitco 恒 0）。它们见过 0（复位期）
# 也见过 1，不需要豁免。srcID 由 io_nodeID 注入，随机即可翻转。无豁免。
PAIRS = [Pair("LinkMonitor", "lm_", clocked=True, stim=STIM, cov=COV, arm=ARM, reset_period=1000)]
HEADER = """
tb —— LinkMonitor：L2 的 CHI 链路层（链路激活握手 + L-Credit 流控 + flit 打包/解包）双例化 UT。
本文件由 gen.py 生成（scripts/dual_tb_lib.py），勿手改。
"""

if __name__ == "__main__":
    txt = render(PAIRS, header=HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, check="--check" in sys.argv))
