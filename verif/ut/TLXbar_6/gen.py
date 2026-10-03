#!/usr/bin/env python3
"""生成本目录 tb.sv（双例化：golden vs 重写）。用法：python3 gen.py [--check]
A 地址三分：BEU 区 / 缓存控制区 / 其余各约 1/3；D 应答的 source 偏向 16（回 in0）与 0..15（回 in1）；
valid/ready 各 1/2，分相里从口 ready 降到 1/8 让仲裁器锁定与轮转都被打到。
所有寄存器都异步复位，但 tb 的 reset 在第一个时钟沿之后才拉起，那一拍两侧状态初值不同就会分叉，
所以 0 时刻之后把重写侧五个仲裁器的状态 force 成 golden 对应寄存器再 release。
"""
import os
import sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '../../../scripts'))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

T = 'TLXbar_6'
g = 'x_u_gold'
i = 'x_u_impl.u_core'
# golden 内联仲裁器编号 j -> (impl 实例, 路数)：0..2 = A 从口 0..2（2 路），3..4 = D 主口 0..1（3 路）
ARBS = [(0, 'g_out_a[0].u_arb', 2), (1, 'g_out_a[1].u_arb', 2), (2, 'g_out_a[2].u_arb', 2),
        (3, 'g_in_d[0].u_arb', 3), (4, 'g_in_d[1].u_arb', 3)]
F, R = [], []
for j, inst, n in ARBS:
    sfx = '' if j == 0 else '_%d' % j
    F.append(f'  force {i}.{inst}.beats_left = {g}.beatsLeft{sfx};')
    F.append(f'  force {i}.{inst}.mask = {g}.readys_mask{sfx};')
    F.append(f'  force {i}.{inst}.state = {{' + ', '.join(
        f'{g}.state_{k}' if j == 0 else f'{g}.state_{j}_{k}' for k in reversed(range(n))) + '};')
    R += [f'  release {i}.{inst}.beats_left;', f'  release {i}.{inst}.mask;', f'  release {i}.{inst}.state;']
decls = "initial begin\n  #1;\n" + "\n".join(F) + "\n  #0;\n" + "\n".join(R) + "\nend\n"

ADDR = """
case ($urandom_range(0, 5))
  0, 1: @io_ADDR = {18'h0, 18'h38010, @io_ADDR[11:0]};
  2, 3: @io_ADDR = {18'h0, 22'h380220, @io_ADDR[7:0]};
  4:    @io_ADDR = {18'h0, 22'h380221, @io_ADDR[7:0]};
  default: ;
endcase
"""
stim = (ADDR.replace('@io_ADDR', '@auto_in_0_a_bits_address') + ADDR.replace('@io_ADDR', '@auto_in_1_a_bits_address') + """
if ($urandom_range(0, 1)) @auto_out_0_d_bits_source = ($urandom_range(0, 1)) ? 5'h10 : 5'($urandom_range(0, 15));
if ($urandom_range(0, 1)) @auto_out_1_d_bits_source = ($urandom_range(0, 1)) ? 5'h10 : 5'($urandom_range(0, 15));
if ($urandom_range(0, 1)) @auto_out_2_d_bits_source = ($urandom_range(0, 1)) ? 5'h10 : 5'($urandom_range(0, 15));
if (@mode >= 10) begin
  @auto_out_0_a_ready = ($urandom_range(0, 7) == 0);
  @auto_out_1_a_ready = ($urandom_range(0, 7) == 0);
  @auto_out_2_a_ready = ($urandom_range(0, 7) == 0);
  @auto_in_0_d_ready  = ($urandom_range(0, 7) == 0);
  @auto_in_1_d_ready  = ($urandom_range(0, 7) == 0);
end
""").replace('@mode', 'x_mode')
cov = [('a0_in0', '@auto_out_0_a_valid && @auto_out_0_a_ready && @auto_out_0_a_bits_source[4]'),
       ('a0_in1', '@auto_out_0_a_valid && @auto_out_0_a_ready && !@auto_out_0_a_bits_source[4]'),
       ('a1_fire', '@auto_out_1_a_valid && @auto_out_1_a_ready'),
       ('a2_fire', '@auto_out_2_a_valid && @auto_out_2_a_ready'),
       ('a_contend', '@auto_in_0_a_valid && @auto_in_1_a_valid && @auto_in_0_a_bits_address[29:12] == @auto_in_1_a_bits_address[29:12]'),
       ('d0_fire', '@auto_in_0_d_valid && @auto_in_0_d_ready'),
       ('d1_fire', '@auto_in_1_d_valid && @auto_in_1_d_ready'),
       ('d_contend', '@auto_out_0_d_valid && @auto_out_1_d_valid && @auto_out_2_d_valid'),
       ('rr_flip', '@auto_in_1_d_valid && !x_u_gold.readys_mask_4[0]')]
# out0/out1 只在地址落进各自区间时才被选中（否则 Mux1H 给 0），所以地址里"区间 base 为 0 的高位"永远是 0
exempt = ['auto_out_0_a_bits_address[%d]' % b for b in range(12, 30) if not (0x38010000 >> b) & 1]
exempt += ['auto_out_1_a_bits_address[%d]' % b for b in range(8, 30) if not (0x38022000 >> b) & 1]
pairs = [Pair(T, 'x_', clocked=True, stim=stim, cov=cov, decls=decls, exempt=exempt, reset_period=20000, cov_min=200)]
txt = render(pairs, header="TLXbar_6 双例化 UT（由 gen.py 生成，勿手改）")
sys.exit(write_or_check(os.path.join(HERE, 'tb.sv'), txt, check='--check' in sys.argv))
