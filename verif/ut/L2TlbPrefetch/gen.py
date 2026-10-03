#!/usr/bin/env python3
"""生成本目录 tb.sv（双例化：golden L2TlbPrefetch vs 重写 L2TlbPrefetch_xs）。用法：python3 gen.py [--check]

激励偏置（全随机会让 5 个 flush 源几乎每拍有一个为 1，预取永远举不起来）：
  * flush 五项各 1/256；
  * vpn 只在一个 64 行的小窗口里取（高位固定在每 4000 拍换一次的 base 上），让"下一行已在去重窗口"
    频繁命中；mode 低 2 位调 in.valid / out.ready 的密度，制造"举着不被接走 / 一来就接走"两种节奏。
arm：next_req 不复位，第一次 in.valid 之前两侧初值可能不同（+vcs+initreg+random 各摇各的），
  所以等第一次 in.valid 之后再比。
"""
import os
import sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '../../../scripts'))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

stim = """
@io_sfence_valid          = ($urandom_range(0, 255) == 0);
@io_csr_satp_changed      = ($urandom_range(0, 255) == 0);
@io_csr_vsatp_changed     = ($urandom_range(0, 255) == 0);
@io_csr_hgatp_changed     = ($urandom_range(0, 255) == 0);
@io_csr_priv_virt_changed = ($urandom_range(0, 255) == 0);
if (cyc % 4000 == 0) p_base = {$urandom, $urandom};
@io_in_bits_vpn = {p_base[37:9], 6'($urandom_range(0, 63)), 3'($urandom)};
case (p_mode[1:0])
  2'd0: begin @io_in_valid = ($urandom_range(0, 3) == 0); @io_out_ready = ($urandom_range(0, 7) == 0); end
  2'd1: begin @io_in_valid = ($urandom_range(0, 1) == 0); @io_out_ready = 1'b1; end
  2'd2: begin @io_in_valid = 1'b1;                      @io_out_ready = ($urandom_range(0, 1) == 0); end
  default: ;
endcase
"""
cov = [
    ('fire', '@io_out_valid && @io_out_ready'),
    ('held', '@io_out_valid && !@io_out_ready'),
    ('dedup_hit', '@io_in_valid && p_u_gold.input_valid_probe == 1\'b0 && !p_u_gold.flush'),
    ('flush_while_valid', '@io_out_valid && p_u_gold.flush'),
    ('window_full', '&{p_u_gold.old_v_0, p_u_gold.old_v_1, p_u_gold.old_v_2, p_u_gold.old_v_3}'),
    ('s2x_all', '@io_out_bits_req_info_s2xlate == 2\'d3'),
    ('s2x_s1', '@io_out_bits_req_info_s2xlate == 2\'d1'),
    ('s2x_s2', '@io_out_bits_req_info_s2xlate == 2\'d2'),
    ('s2x_none', '@io_out_bits_req_info_s2xlate == 2\'d0'),
]
pairs = [Pair('L2TlbPrefetch', 'p_', clocked=True, stim=stim, cov=cov, cov_min=200,
              arm=['@io_in_valid'], decls="logic [37:0] p_base = '0;",
              # next_req 的 sector 位按构造恒 0（next_line 补 0），arm 之后不可能见到 1
              exempt=['io_out_bits_req_info_vpn[0]', 'io_out_bits_req_info_vpn[1]',
                      'io_out_bits_req_info_vpn[2]'])]
txt = render(pairs, header="L2TlbPrefetch 双例化 UT（由 gen.py 生成，勿手改）")
sys.exit(write_or_check(os.path.join(HERE, 'tb.sv'), txt, check='--check' in sys.argv))
