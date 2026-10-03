#!/usr/bin/env python3
"""生成本目录 tb.sv（双例化：golden vs 重写）。用法：python3 gen.py [--check]
flush 源（sfence / satp 等）各 1/64，valid / ready 各 1/2，分相里下游很少 ready 让请求/应答在手里多停几拍。
锁存的 req / resp 不复位：0 时刻之后把重写侧向量 force 成 golden 侧各字段的拼接（只对齐上电初值）。sent / recv 虽有复位，但 tb 的 reset 在第一个时钟沿之后才拉起，
那一拍两侧标志初值不同就会分叉，所以也一并对齐。
"""
import os
import sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '../../../scripts'))
from dual_tb_lib import Pair, render, write_or_check, golden_ports  # noqa: E402

T = 'PTWRepeaterNB'
P = golden_ports(T)
req = [n for d, w, n in P if n.startswith('io_tlb_req_0_bits_')]
resp = [n for d, w, n in P if n.startswith('io_ptw_resp_bits_')]
g = 'r_u_gold'
i = 'r_u_impl.u_core'
decls = ("initial begin\n  #1;\n"
         + "  force %s.req = {%s};\n" % (i, ', '.join(g + '.' + 'req_' + n[len('io_tlb_req_0_bits_'):] for n in req))
         + "  force %s.resp = {%s};\n" % (i, ', '.join(g + '.resp_' + n[len('io_ptw_resp_bits_'):] for n in resp))
         + "  force %s.sent = %s.sent;\n  force %s.recv = %s.recv;\n" % (i, g, i, g)
         + "  #0;\n  release %s.req;\n  release %s.resp;\n  release %s.sent;\n  release %s.recv;\nend\n" % (i, i, i, i))
stim = """
@io_sfence_valid          = ($urandom_range(0, 63) == 0);
@io_csr_satp_changed      = ($urandom_range(0, 63) == 0);
@io_csr_vsatp_changed     = ($urandom_range(0, 63) == 0);
@io_csr_hgatp_changed     = ($urandom_range(0, 63) == 0);
@io_csr_priv_virt_changed = ($urandom_range(0, 63) == 0);
if (@mode >= 12) begin
  @io_ptw_req_0_ready = ($urandom_range(0, 7) == 0);
  @io_tlb_resp_ready  = ($urandom_range(0, 7) == 0);
end
""".replace('@mode', 'r_mode')
cov = [('req_fire',  '@io_tlb_req_0_valid && @io_tlb_req_0_ready'),
       ('req_sent',  '@io_ptw_req_0_valid && @io_ptw_req_0_ready'),
       ('resp_recv', '@io_ptw_resp_valid && @io_ptw_resp_ready'),
       ('resp_out',  '@io_tlb_resp_valid && @io_tlb_resp_ready'),
       ('flush_sent', 'r_u_gold._delay_io_out && r_u_gold.sent'),
       ('flush_recv', 'r_u_gold._delay_io_out && r_u_gold.recv'),
       ('sent_and_recv', 'r_u_gold.sent && r_u_gold.recv')]
pairs = [Pair(T, 'r_', clocked=True, stim=stim, cov=cov, decls=decls, reset_period=20000, cov_min=200)]
txt = render(pairs, header="PTWRepeaterNB 双例化 UT（由 gen.py 生成，勿手改）")
sys.exit(write_or_check(os.path.join(HERE, 'tb.sv'), txt, check='--check' in sys.argv))
