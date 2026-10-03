#!/usr/bin/env python3
"""生成本目录 tb.sv（双例化：golden L2TlbMissQueue vs 重写 L2TlbMissQueue_xs）。用法：python3 gen.py [--check]

激励偏置（全随机会让 5 个 flush 源几乎每拍有一个为 1，队列永远攒不起来）：
  * flush 五项各 1/2048（约每 400 拍一次，留出攒满 40 项的时间）；
  * mode（每 1000 拍重抽）低 2 位调进/出密度：只进不出（攒满 40 项、io_in_ready=0）、只出不进（排空）、进出各半、
    进多出少 —— 走到满、空、同拍进出、指针在 39 回绕。
arm：ram_40x47 不复位，+vcs+initreg+random 下两侧初值各摇各的；队列空时出口载荷照样是 ram[deq_ptr]，
  所以等 golden 侧 40 个槽全被写过一次再比（m_written）。
运行期地址复核（codex 0158 §1 M3 的逐拍复核）：两侧 ram 的读/写地址任何一拍 > 39 都记 errors。
"""
import os
import sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '../../../scripts'))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

G_Q = 'm_u_gold.io_out_q'
I_Q = 'm_u_impl.u_core'
decls = f"""
logic [39:0] m_written = '0;
always @(posedge clk) if ({G_Q}.do_enq) m_written[{G_Q}.enq_ptr_value] <= 1'b1;
always @(negedge clk) begin
  if ({G_Q}.ram_ext.R0_addr > 6'd39 || {G_Q}.ram_ext.W0_addr > 6'd39 ||
      {I_Q}.ram_ext.R0_addr > 6'd39 || {I_Q}.ram_ext.W0_addr > 6'd39) begin
    errors++;
    $display("[ADDR] cyc=%0d ram_40x47 地址越界 g=%0d/%0d i=%0d/%0d", cyc,
             {G_Q}.ram_ext.R0_addr, {G_Q}.ram_ext.W0_addr, {I_Q}.ram_ext.R0_addr, {I_Q}.ram_ext.W0_addr);
  end
end
"""
stim = """
@io_sfence_valid          = ($urandom_range(0, 2047) == 0);
@io_csr_satp_changed      = ($urandom_range(0, 2047) == 0);
@io_csr_vsatp_changed     = ($urandom_range(0, 2047) == 0);
@io_csr_hgatp_changed     = ($urandom_range(0, 2047) == 0);
@io_csr_priv_virt_changed = ($urandom_range(0, 2047) == 0);
case (m_mode[1:0])
  2'd0: begin @io_in_valid = ($urandom_range(0, 3) != 0); @io_out_ready = ($urandom_range(0, 15) == 0); end
  2'd1: begin @io_in_valid = ($urandom_range(0, 7) == 0); @io_out_ready = ($urandom_range(0, 3) != 0); end
  default: ;
endcase
"""
cov = [
    ('full', '!@io_in_ready'),
    ('empty', '!@io_out_valid'),
    ('enq_deq_same_cycle', '@io_in_valid && @io_in_ready && @io_out_valid && @io_out_ready'),
    ('enq_wrap', f'{G_Q}.do_enq && {G_Q}.enq_ptr_value == 6\'d39'),
    ('deq_wrap', f'{G_Q}.do_deq && {G_Q}.deq_ptr_value == 6\'d39'),
    ('flush_nonempty', f'{G_Q}.io_flush && @io_out_valid'),
    ('flush_with_enq', f'{G_Q}.io_flush && {G_Q}.do_enq'),
]
pairs = [Pair('L2TlbMissQueue', 'm_', clocked=True, stim=stim, cov=cov, cov_min=50,
              arm=['&m_written'], decls=decls, mode_period=1000,
              # isHptwReq / hptwId 入队恒 0（firtool 删了入口端口），出口按构造不会出现 1
              exempt=['io_out_bits_isHptwReq', 'io_out_bits_hptwId'])]
txt = render(pairs, header="L2TlbMissQueue 双例化 UT（由 gen.py 生成，勿手改）")
sys.exit(write_or_check(os.path.join(HERE, 'tb.sv'), txt, check='--check' in sys.argv))
