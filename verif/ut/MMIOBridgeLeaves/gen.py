#!/usr/bin/env python3
"""生成本目录 tb.sv（双例化：golden vs 重写）。用法：python3 gen.py [--check]

MMIOBridgeEntry 四个变体同一套激励（只差 io_id 位宽）：
  * 请求 opcode 偏向 Get / PutFull / PutPartial，留 1/8 给别的编码（Hint 之类：槽只欠 TXREQ 与回包）；
  * RXRSP opcode 偏向槽认得的六种（RetryAck / Comp / CompDBIDResp / DBIDResp / ReadReceipt / DBIDRespOrd）；
  * RXDAT 的 dataCheck 7/8 的时候给正确的逐字节奇校验（否则 corrupt 几乎恒 1，看不到 0）；
  * respErr / poison 大多为 0；io_pCrd_grant 1/8。
不复位的寄存器（锁存的请求、rdata、srcID、dbID、pCrdType、denied、corrupt、traceTag）在 +vcs+initreg+random
下两个实例各摇各的初值，而它们在第一次被写之前就能从输出口看到 —— 所以 0 时刻之后把重写侧的这些寄存器
拷成 golden 侧的值（force 后立即 release；只对齐上电初值，不碰之后的任何一拍）。
"""
import os
import sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '../../../scripts'))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

# 不复位的寄存器 + 复位标志：复位标志虽会在 reset 时归位，但 tb 的 reset 在第一个时钟沿（t=5）之后才拉起
# （t=10），这一拍两侧若标志初值不同就会一侧 rxdat_fire 一侧不 fire，锁进不同的 rdata（seed 7 × initreg 7017 实测）。
UNRESET = ['s_txreq', 's_ncbwrdata', 's_resp', 'w_comp', 'w_dbidresp', 'w_compdata', 'w_pcrdgrant',
           'w_readreceipt', 'allowRetry',
           'req_opcode', 'req_size', 'req_source', 'req_address', 'req_user_memBackType_MM',
           'req_user_memPageType_NC', 'req_mask', 'req_data', 'req_corrupt', 'rdata', 'srcID', 'dbID',
           'pCrdType', 'denied', 'corrupt', 'traceTag']

ENTRY_STIM = """
case ($urandom_range(0, 7))
  0, 1, 2: @io_req_bits_opcode = 4'h4;
  3, 4:    @io_req_bits_opcode = 4'h0;
  5, 6:    @io_req_bits_opcode = 4'h1;
  default: ;
endcase
case ($urandom_range(0, 15))
  0, 1:       @io_chi_rx_rsp_bits_opcode = 5'h03;
  2, 3, 4:    @io_chi_rx_rsp_bits_opcode = 5'h04;
  5, 6, 7:    @io_chi_rx_rsp_bits_opcode = 5'h05;
  8, 9:       @io_chi_rx_rsp_bits_opcode = 5'h06;
  10, 11, 12: @io_chi_rx_rsp_bits_opcode = 5'h08;
  13:         @io_chi_rx_rsp_bits_opcode = 5'h0E;
  default: ;
endcase
if ($urandom_range(0, 7) != 0)
  for (int b = 0; b < 32; b++)
    @io_chi_rx_dat_bits_dataCheck[b] = ~(^@io_chi_rx_dat_bits_data[8*b +: 8]);
if ($urandom_range(0, 3) != 0) @io_chi_rx_dat_bits_respErr = 2'h0;
if ($urandom_range(0, 3) != 0) @io_chi_rx_rsp_bits_respErr = 2'h0;
if ($urandom_range(0, 7) != 0) @io_chi_rx_dat_bits_poison = 4'h0;
@io_pCrd_grant = ($urandom_range(0, 7) == 0);
// 分相：慢相里下游与上游都很少 ready，让槽在每个中间状态多停几拍
if (@mode >= 12) begin
  @io_chi_tx_req_ready = ($urandom_range(0, 7) == 0);
  @io_chi_tx_dat_ready = ($urandom_range(0, 7) == 0);
  @io_resp_ready       = ($urandom_range(0, 7) == 0);
end
"""


def entry_pair(top, pfx):
    g = f'{pfx}u_gold'
    i = f'{pfx}u_impl.u_core'
    # always_ff 变量不许有第二个过程驱动 -> force 之后立刻 release：变量保持被 force 的值，直到自己的时钟沿赋值
    decls = ("initial begin\n  #1;\n" + "".join(f"  force {i}.{r} = {g}.{r};\n" for r in UNRESET)
             + "  #0;\n" + "".join(f"  release {i}.{r};\n" for r in UNRESET) + "end\n")
    cov = [
        ('read_resp',  '@io_resp_valid && @io_resp_ready && @io_resp_bits_opcode == 4\'h1'),
        ('write_resp', '@io_resp_valid && @io_resp_ready && @io_resp_bits_opcode == 4\'h0'),
        ('txreq_fire', '@io_chi_tx_req_valid && @io_chi_tx_req_ready'),
        ('txdat_fire', '@io_chi_tx_dat_valid && @io_chi_tx_dat_ready'),
        ('retry',      '@io_chi_rx_rsp_ready && @io_chi_rx_rsp_valid && @io_chi_rx_rsp_bits_opcode == 5\'h03'),
        ('resend',     '@io_chi_tx_req_valid && @io_chi_tx_req_ready && !@io_chi_tx_req_bits_allowRetry'),
        ('crd_wait',   '@io_pCrd_query_valid && !@io_pCrd_grant'),
        ('receipt',    '@io_chi_rx_rsp_ready && @io_chi_rx_rsp_valid && @io_chi_rx_rsp_bits_opcode == 5\'h08'),
        ('wait_rr',    '@io_waitOnReadReceipt'),
        ('other_op',   '@io_chi_tx_req_valid && @io_chi_tx_req_bits_opcode == 7\'h0'),
        ('denied',     '@io_resp_valid && @io_resp_bits_denied'),
        ('corrupt',    '@io_resp_valid && @io_resp_bits_corrupt'),
        ('clean_read', '@io_resp_valid && @io_resp_bits_opcode == 4\'h1 && !@io_resp_bits_corrupt && !@io_resp_bits_denied'),
    ]
    idw = [w for d, w, n in Pair(top, pfx, clocked=True).ports if n == 'io_id'][0]
    exempt = ['io_resp_bits_opcode[%d]' % b for b in (1, 2, 3)]
    exempt += ['io_chi_tx_req_bits_txnID[%d]' % b for b in range(idw, 12)]
    exempt += ['io_chi_tx_req_bits_opcode[%d]' % b for b in (0, 1, 5, 6)]
    exempt += ['io_chi_tx_req_bits_size[2]', 'io_chi_tx_req_bits_order[1]',
               'io_chi_tx_dat_bits_respErr[0]', 'io_chi_tx_dat_bits_dataID[0]']
    return Pair(top, pfx, clocked=True, stim=ENTRY_STIM.replace('@mode', f'{pfx}mode'), cov=cov,
                exempt=exempt, decls=decls, reset_period=20000, cov_min=200)


ARB_STIM = "\n".join(
    f"@io_in_{k}_valid = ((cyc / 3000) % 2) ? ($urandom_range(0, 15) == 0) : ($urandom_range(0, 1) == 0);"
    for k in range(16)) + "\n"
ARB_COV = [('none', '!@io_out_valid'),
           ('only_last', '@io_out_valid && @io_in_15_ready && @io_in_15_valid'),
           ('first', '@io_in_0_valid'),
           ('blocked', '@io_out_valid && !@io_out_ready')]
for k in (3, 7, 12):
    ARB_COV.append((f'win{k}', f'@io_in_{k}_valid && @io_in_{k}_ready'))

pairs = [entry_pair('MMIOBridgeEntry', 'e1_'), entry_pair('MMIOBridgeEntry_2', 'e2_'),
         entry_pair('MMIOBridgeEntry_4', 'e4_'), entry_pair('MMIOBridgeEntry_8', 'e8_'),
         Pair('Arbiter16_CHIDAT', 'arb_', stim=ARB_STIM, cov=ARB_COV, cov_min=200)]
txt = render(pairs, header="MMIOBridgeLeaves 双例化 UT（由 gen.py 生成，勿手改）")
sys.exit(write_or_check(os.path.join(HERE, 'tb.sv'), txt, check='--check' in sys.argv))
