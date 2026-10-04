#!/usr/bin/env python3
"""生成本目录 tb.sv（双例化：golden MMIOBridge vs 重写 MMIOBridge_xs）。用法：python3 gen.py [--check]

激励（全部输出逐拍逐位 !== 比较）：
  * A 通道 opcode 偏向 Get / PutFull / PutPartial，留 1/8 给别的编码；a_valid 1/2；
  * RXRSP / RXDAT 的 txnID：3/4 时间挑一个正在等该通道的槽（看 golden 侧槽的 rx ready），其余 7/8 落在
    0..15、1/8 给更大的值（两边都落空）；
    RXRSP opcode 偏向槽认得的六种（RetryAck / Comp / CompDBIDResp / DBIDResp / ReadReceipt / DBIDRespOrd）；
  * RXDAT dataCheck 7/8 给正确的逐字节奇校验；respErr / poison 大多为 0；
  * 16 路 io_pCrd_<i>_grant 各 1/8；
  * 分相：mode>=12 时 TXREQ / TXDAT / D 通道下游很少 ready，让槽堆满（选槽兜底到槽 15 的那条路要靠它）。
16 个槽里不复位的寄存器（锁存请求、rdata、srcID、dbID、pCrdType、denied、corrupt、traceTag 与复位前的
状态标志）：0 时刻之后把重写侧拷成 golden 侧的值（force 后立即 release，只对齐上电初值），同 MMIOBridgeLeaves。
"""
import os
import sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '../../../scripts'))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

UNRESET = ['s_txreq', 's_ncbwrdata', 's_resp', 'w_comp', 'w_dbidresp', 'w_compdata', 'w_pcrdgrant',
           'w_readreceipt', 'allowRetry',
           'req_opcode', 'req_size', 'req_source', 'req_address', 'req_user_memBackType_MM',
           'req_user_memPageType_NC', 'req_mask', 'req_data', 'req_corrupt', 'rdata', 'srcID', 'dbID',
           'pCrdType', 'denied', 'corrupt', 'traceTag']
P = 'mb_'

STIM = """
case ($urandom_range(0, 7))
  0, 1, 2: @auto_mmio_in_a_bits_opcode = 4'h4;
  3, 4:    @auto_mmio_in_a_bits_opcode = 4'h0;
  5, 6:    @auto_mmio_in_a_bits_opcode = 4'h1;
  default: ;
endcase
// txnID：3/4 时间挑一个正在等 RXRSP / RXDAT 的槽（golden 侧槽的 ready），其余在 0..15 随机，1/8 给落空的大值
begin
  int n; int pick [16];
  n = 0;
  for (int k = 0; k < 16; k++) if (mb_rsp_rdy[k]) begin pick[n] = k; n++; end
  if (n != 0 && $urandom_range(0, 3) != 0) @io_rx_rsp_bits_txnID = 12'(pick[$urandom_range(0, n - 1)]);
  else if ($urandom_range(0, 7) != 0) @io_rx_rsp_bits_txnID = 12'($urandom_range(0, 15));
  n = 0;
  for (int k = 0; k < 16; k++) if (mb_dat_rdy[k]) begin pick[n] = k; n++; end
  if (n != 0 && $urandom_range(0, 3) != 0) @io_rx_dat_bits_txnID = 12'(pick[$urandom_range(0, n - 1)]);
  else if ($urandom_range(0, 7) != 0) @io_rx_dat_bits_txnID = 12'($urandom_range(0, 15));
end
case ($urandom_range(0, 15))
  0, 1:       @io_rx_rsp_bits_opcode = 5'h03;
  2, 3, 4:    @io_rx_rsp_bits_opcode = 5'h04;
  5, 6, 7:    @io_rx_rsp_bits_opcode = 5'h05;
  8, 9:       @io_rx_rsp_bits_opcode = 5'h06;
  10, 11, 12: @io_rx_rsp_bits_opcode = 5'h08;
  13:         @io_rx_rsp_bits_opcode = 5'h0E;
  default: ;
endcase
if ($urandom_range(0, 7) != 0)
  for (int b = 0; b < 32; b++)
    @io_rx_dat_bits_dataCheck[b] = ~(^@io_rx_dat_bits_data[8*b +: 8]);
if ($urandom_range(0, 3) != 0) @io_rx_dat_bits_respErr = 2'h0;
if ($urandom_range(0, 3) != 0) @io_rx_rsp_bits_respErr = 2'h0;
if ($urandom_range(0, 7) != 0) @io_rx_dat_bits_poison = 4'h0;
""" + "".join("@io_pCrd_%d_grant = ($urandom_range(0, 7) == 0);\n" % i for i in range(16)) + """
if (@mode >= 12) begin
  @io_tx_req_ready      = ($urandom_range(0, 7) == 0);
  @io_tx_dat_ready      = ($urandom_range(0, 7) == 0);
  @auto_mmio_in_d_ready = ($urandom_range(0, 7) == 0);
end
""".replace('@mode', P + 'mode')

decls = "wire [15:0] mb_rsp_rdy = {%s};\n" % ", ".join("%su_gold._entries_%d_io_chi_rx_rsp_ready" % (P, i) for i in range(15, -1, -1))
decls += "wire [15:0] mb_dat_rdy = {%s};\n" % ", ".join("%su_gold._entries_%d_io_chi_rx_dat_ready" % (P, i) for i in range(15, -1, -1))
decls += "initial begin\n  #1;\n"
for i in range(16):
    decls += "".join(f"  force {P}u_impl.entries_{i}.u_core.{r} = {P}u_gold.entries_{i}.{r};\n" for r in UNRESET)
decls += "  #0;\n"
for i in range(16):
    decls += "".join(f"  release {P}u_impl.entries_{i}.u_core.{r};\n" for r in UNRESET)
decls += "end\n"

G = P + 'u_gold'
COV = [
    ('a_fire',       '@auto_mmio_in_a_valid && @auto_mmio_in_a_ready'),
    ('a_full',       '@auto_mmio_in_a_valid && !@auto_mmio_in_a_ready'),
    ('slot15_used',  '%s._entries_15_io_resp_valid' % G),
    ('d_read',       '@auto_mmio_in_d_valid && @auto_mmio_in_d_ready && @auto_mmio_in_d_bits_opcode == 4\'h1'),
    ('d_write',      '@auto_mmio_in_d_valid && @auto_mmio_in_d_ready && @auto_mmio_in_d_bits_opcode == 4\'h0'),
    ('txreq_fire',   '@io_tx_req_valid && @io_tx_req_ready'),
    ('txdat_fire',   '@io_tx_dat_valid && @io_tx_dat_ready'),
    ('read_blocked', '%s.block | %s.block_7 | %s.block_15' % (G, G, G)),
    ('wait_rr',      '|%s._waitOnReadReceipt_T' % G),
    ('rxdat_ready',  '@io_rx_dat_valid && @io_rx_dat_ready'),
    ('rxdat_miss',   '@io_rx_dat_valid && !@io_rx_dat_ready'),
    ('pcrd_query',   '@io_pCrd_9_query_valid'),
]
EXEMPT = ['auto_mmio_in_d_bits_opcode[%d]' % b for b in (1, 2, 3)]
EXEMPT += ['io_tx_req_bits_txnID[%d]' % b for b in range(4, 12)]
EXEMPT += ['io_tx_req_bits_opcode[%d]' % b for b in (0, 1, 5, 6)]
EXEMPT += ['io_tx_req_bits_size[2]', 'io_tx_req_bits_order[1]',
           'io_tx_dat_bits_respErr[0]', 'io_tx_dat_bits_dataID[0]']
# 常量字段（golden 里 assign 常量）
EXEMPT += ['auto_mmio_in_d_bits_param', 'auto_mmio_in_d_bits_sink', 'io_rx_rsp_ready',
           'io_tx_req_bits_qos', 'io_tx_req_bits_tgtID', 'io_tx_req_bits_srcID', 'io_tx_req_bits_returnNID',
           'io_tx_req_bits_stashNIDValid', 'io_tx_req_bits_returnTxnID', 'io_tx_req_bits_ns',
           'io_tx_req_bits_likelyshared', 'io_tx_req_bits_memAttr_allocate', 'io_tx_req_bits_memAttr_cacheable',
           'io_tx_req_bits_snpAttr', 'io_tx_req_bits_lpIDWithPadding', 'io_tx_req_bits_snoopMe',
           'io_tx_req_bits_expCompAck', 'io_tx_req_bits_tagOp', 'io_tx_req_bits_traceTag',
           'io_tx_req_bits_mpam_perfMonGroup', 'io_tx_req_bits_mpam_partID', 'io_tx_req_bits_mpam_mpamNS',
           'io_tx_req_bits_rsvdc', 'io_tx_dat_bits_qos', 'io_tx_dat_bits_srcID', 'io_tx_dat_bits_homeNID',
           'io_tx_dat_bits_opcode', 'io_tx_dat_bits_resp', 'io_tx_dat_bits_dataSource', 'io_tx_dat_bits_cBusy',
           'io_tx_dat_bits_dbID', 'io_tx_dat_bits_tagOp', 'io_tx_dat_bits_tag', 'io_tx_dat_bits_tu',
           'io_tx_dat_bits_rsvdc']

pairs = [Pair('MMIOBridge', P, clocked=True, stim=STIM, cov=COV, exempt=EXEMPT, decls=decls,
              reset_period=20000, cov_min=50)]
txt = render(pairs, header="MMIOBridge 双例化 UT（由 gen.py 生成，勿手改）")
sys.exit(write_or_check(os.path.join(HERE, 'tb.sv'), txt, check='--check' in sys.argv))
