#!/usr/bin/env python3
"""生成本目录 tb.sv（双例化：golden vs 重写）。用法：python3 gen.py [--check]
A/C 地址全随机（bank = address[7:6] 自然均匀）；size 全随机，带数据的 opcode 配 size>=6 就是两拍消息，
让仲裁器的锁定路径被打到；D 应答 source 偏向三个主口的前缀（0x0x/0x5x/0x4x）；B 的 source[6] 一半为 0；
分相里从口/主口 ready 降到 1/8。
所有寄存器都异步复位，但 tb 的 reset 在第一个时钟沿之后才拉起，那一拍两侧状态初值不同就会分叉，
所以 0 时刻之后把重写侧八个仲裁器的状态 force 成 golden 对应寄存器再 release。
"""
import os
import sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '../../../scripts'))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

T = 'TLXbar_5'
g = 'x_u_gold'
i = 'x_u_impl.u_core'
# golden 内联仲裁器编号 j -> (impl 实例, 路数)：0..3 = A 从口 0..3（3 路），4 = B 主口 0（4 路），5..7 = D 主口 0..2（4 路）
ARBS = [(0, 'g_out_a[0].u_arb', 3), (1, 'g_out_a[1].u_arb', 3), (2, 'g_out_a[2].u_arb', 3), (3, 'g_out_a[3].u_arb', 3),
        (4, 'u_arb_b', 4), (5, 'g_in_d[0].u_arb', 4), (6, 'g_in_d[1].u_arb', 4), (7, 'g_in_d[2].u_arb', 4)]
F, R = [], []
for j, inst, n in ARBS:
    sfx = '' if j == 0 else '_%d' % j
    F.append(f'  force {i}.{inst}.beats_left = {g}.beatsLeft{sfx};')
    F.append(f'  force {i}.{inst}.mask = {g}.readys_mask{sfx};')
    F.append(f'  force {i}.{inst}.state = {{' + ', '.join(
        f'{g}.state_{k}' if j == 0 else f'{g}.state_{j}_{k}' for k in reversed(range(n))) + '};')
    R += [f'  release {i}.{inst}.beats_left;', f'  release {i}.{inst}.mask;', f'  release {i}.{inst}.state;']
decls = "initial begin\n  #1;\n" + "\n".join(F) + "\n  #0;\n" + "\n".join(R) + "\nend\n"

SRC = "7'({3'($urandom_range(0, 7) < 4 ? $urandom_range(0, 3) : ($urandom_range(0, 1) ? 5 : 4)), 4'($urandom)})"
stim = "\n".join(f"if ($urandom_range(0, 3)) @auto_out_{o}_d_bits_source = {SRC};" for o in range(4)) + "\n" + """
if (@mode >= 10) begin
  @auto_out_0_a_ready = ($urandom_range(0, 7) == 0);
  @auto_out_1_a_ready = ($urandom_range(0, 7) == 0);
  @auto_out_2_a_ready = ($urandom_range(0, 7) == 0);
  @auto_out_3_a_ready = ($urandom_range(0, 7) == 0);
  @auto_in_0_d_ready  = ($urandom_range(0, 7) == 0);
  @auto_in_1_d_ready  = ($urandom_range(0, 7) == 0);
  @auto_in_2_d_ready  = ($urandom_range(0, 7) == 0);
  @auto_in_0_b_ready  = ($urandom_range(0, 7) == 0);
end
""".replace('@mode', 'x_mode')
cov = [('a_lock', 'x_u_gold.beatsLeft || x_u_gold.beatsLeft_1 || x_u_gold.beatsLeft_2 || x_u_gold.beatsLeft_3'),
       ('d_lock', 'x_u_gold.beatsLeft_5 || x_u_gold.beatsLeft_6 || x_u_gold.beatsLeft_7'),
       ('a0_fire', '@auto_out_0_a_valid && @auto_out_0_a_ready'),
       ('a3_from_ptw', '@auto_out_3_a_valid && @auto_out_3_a_ready && @auto_out_3_a_bits_source[6:4] == 3\'h4'),
       ('a_contend', '@auto_in_0_a_valid && @auto_in_1_a_valid && @auto_in_2_a_valid && @auto_in_0_a_bits_address[7:6] == @auto_in_1_a_bits_address[7:6] && @auto_in_1_a_bits_address[7:6] == @auto_in_2_a_bits_address[7:6]'),
       ('b_fire', '@auto_in_0_b_valid && @auto_in_0_b_ready'),
       ('c_fire', '@auto_in_0_c_valid && @auto_in_0_c_ready'),
       ('d0_fire', '@auto_in_0_d_valid && @auto_in_0_d_ready'),
       ('d1_fire', '@auto_in_1_d_valid && @auto_in_1_d_ready'),
       ('d2_fire', '@auto_in_2_d_valid && @auto_in_2_d_ready'),
       ('e_fire', '@auto_in_0_e_valid && @auto_in_0_e_ready'),
       ('rr_flip', '@auto_in_0_d_valid && !x_u_gold.readys_mask_5[0]')]
# C 只有 in0（source 前缀 0）在发，从口 C 的 source[6] 结构性恒 0
exempt = ['auto_out_%d_c_bits_source[6]' % o for o in range(4)]
pairs = [Pair(T, 'x_', clocked=True, stim=stim, cov=cov, decls=decls, exempt=exempt, reset_period=20000, cov_min=200)]
txt = render(pairs, header="TLXbar_5 双例化 UT（由 gen.py 生成，勿手改）")
sys.exit(write_or_check(os.path.join(HERE, 'tb.sv'), txt, check='--check' in sys.argv))
