#!/usr/bin/env python3
"""gen.py —— 生成 CSA3_2 位宽变体家族的 9 个薄 wrapper + 本 UT 的 tb。

家族规矩（CONVENTIONS「变体家族」）：一个参数化核文件 + 每变体一个薄文件，
核体绝不复制。核 = rtl/backend/CSA3_2.sv 里的 `xs_CSA3_2_core #(.WIDTH)`，
本脚本只产出「设参数 + 端口对位」的薄壳，以及一份逐变体双例化的 tb。

★为什么放在 verif/ut/*/gen.py 而不是 scripts/gen_*.py★
scripts/gate_all.sh 里的生成器幂等闸是**手工逐个列**的（我不拥有那个文件），
而 scripts/test_gen_idempotent.py 会**自动扫** verif/ut/*/gen.py 并在 detached
worktree 里重跑、要求产物逐字不变。放这里等于自动进闸，不用改 gate_all.sh，
也不会重演本仓「生成物进库却没有闸看着它」的老毛病。

用法: python3 gen.py        （幂等：内容不变不碰文件）
"""
import os
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = pathlib.Path(os.environ.get('XSSV_HOME') or HERE.parents[2])

# ---------------------------------------------------------------------------
# 变体表：位宽与例化点**逐个从 golden 实测**得到，不是照抄记忆里的清单。
#   位宽    : sed -n '/^module <名>(/,/^endmodule/p' golden/<名>.sv 的 input [W-1:0]
#   例化点  : grep -lE '^  <名> ' golden/*.sv
# 另有一道更强的核对（见本 UT README）：把「逐位独立全加器」模板按位宽重建成文本，
# 与 golden 模块体**逐字节**比较，9/9 全等 —— 对角线错位/移位/跨位耦合都会当场暴露。
# ---------------------------------------------------------------------------
VARIANTS = [
    # (名字,             位宽, 例化者与处数)
    ('CSA3_2_3956',      10, 'SRT16DividerDataModule ×4'),
    ('CSA3_2_3960',      68, 'SRT16DividerDataModule ×2'),
    ('CSA3_2_3962',      13, 'SRT16DividerDataModule ×25'),
    ('CSA3_2_3987',      22, 'IterBlock_v4 ×2'),
    ('CSA3_2_3988',       8, 'SelBlock_v4 ×4'),
    ('CSA3_2_3992',       9, 'SpecBlock_v4 ×24'),
    ('CSA3_2_4017',      11, 'IterBlock_v4 / IterBlock_v4_4 / IterBlock_v4_6 各 ×1'),
    ('CSA3_2_4111',      38, 'IterBlock_v4_4 ×2'),
    ('CSA3_2_4173',      70, 'IterBlock_v4_6 ×2'),
]


def wrapper(name, w, users):
    return f"""// =============================================================================
// {name}.sv —— 3:2 进位保留加法器（全加器）阵列，**本变体位宽 {w}**
//
// 在哪一层：后端 DivUnit 的 Radix-16 SRT 除法器数据通路。除法每轮迭代要把
//   「上一轮余数 + 若干个商位对应的除数倍数」压成冗余形式再送下一轮，用的就是
//   进位保留加法（不传播进位，延迟与位宽无关）。本变体被 {users} 例化。
//
// 核心机制：{w} 条**互不相干**的全加器并排 —— 第 i 位只吃三个输入的第 i 位，
//   位与位之间没有任何进位链：
//     out_0[i] = in_0[i] ^ in_1[i] ^ in_2[i]          （和位，留在本位）
//     out_1[i] = in_0[i]&in_1[i] | (in_0[i]^in_1[i])&in_2[i]  （进位，权重高一位）
//   注意进位**没有**在本模块里左移——移位由使用者按自己的权重约定处理。
//
// 规模与复位域：{w}×3 入 / {w}×2 出，★纯组合，零寄存器、零子实例、零 always 块★
//   （golden {name}.sv 实测 always=0 / reg=0 / 实例=0，无 clock 无 reset 端口）。
//
// 本文件是家族薄 wrapper，只设参数与对位端口；逻辑核在 rtl/backend/CSA3_2.sv
// （模块 xs_CSA3_2_core），核体全家族共一份。本文件由
// verif/ut/CSA3_2Variants/gen.py 生成，勿手改。
//
// 设计源：src/main/scala/xiangshan/backend/fu/util/CSA.scala (class CSA3_2)
// golden 对照：G1-canonical/golden-rtl/{name}.sv
// =============================================================================
module {name}(
  input  [{w-1}:0] io_in_0,
  input  [{w-1}:0] io_in_1,
  input  [{w-1}:0] io_in_2,
  output [{w-1}:0] io_out_0,
  output [{w-1}:0] io_out_1
);
  xs_CSA3_2_core #(.WIDTH({w})) u_core (
    .in_0  (io_in_0),
    .in_1  (io_in_1),
    .in_2  (io_in_2),
    .out_0 (io_out_0),
    .out_1 (io_out_1)
  );
endmodule
"""


def tb():
    maxw = max(w for _, w, _ in VARIANTS)
    L = []
    L.append('// =============================================================================')
    L.append('// tb —— CSA3_2 位宽变体家族 UT：9 个 golden 变体与重写件逐个双例化比对。')
    L.append('//')
    L.append('// 变体全是「逐位独立的全加器阵列」，位与位之间无进位链，所以**每个位位置的')
    L.append('// 输入空间只有 8 种**(a,b,c)。本 tb 因此不追求向量级穷举（W=70 时 2^210 不可能），')
    L.append('// 而是逐位统计：每个变体的每一个位位置都必须把 8 种组合走遍 —— 对逐位独立的')
    L.append('// 函数来说，这就是**穷举证明**，不是抽样。判据写进了 TEST PASSED。')
    L.append('//')
    L.append('// 激励：全 0 / 全 1 / 交替 / 单点游走 / 随机，覆盖进位链边界（虽然本族无进位链，')
    L.append('// 但同样的激励形状能直接暴露"误加了移位或跨位耦合"这类错误）。')
    L.append('// 本文件由 verif/ut/CSA3_2Variants/gen.py 生成，勿手改。')
    L.append('// =============================================================================')
    L.append('`timescale 1ns/1ps')
    L.append('module tb;')
    L.append(f'  localparam int NV = {len(VARIANTS)};')
    L.append(f'  localparam int MAXW = {maxw};')
    L.append('  int unsigned NCYCLES = 200000;')
    L.append('  bit clk = 0; always #5 clk = ~clk;')
    L.append('  longint errors = 0, checks = 0;')
    L.append('')
    L.append('  logic [MAXW-1:0] a, b, c;')
    L.append('  // 每个变体的两侧输出')
    for n, w, _ in VARIANTS:
        L.append(f'  logic [{w-1}:0] g_{n}_0, g_{n}_1, i_{n}_0, i_{n}_1;')
    L.append('')
    for n, w, _ in VARIANTS:
        L.append(f'  {n}    u_g_{n} (.io_in_0(a[{w-1}:0]), .io_in_1(b[{w-1}:0]), .io_in_2(c[{w-1}:0]),')
        L.append(f'                  .io_out_0(g_{n}_0), .io_out_1(g_{n}_1));')
        L.append(f'  {n}_xs u_i_{n} (.io_in_0(a[{w-1}:0]), .io_in_1(b[{w-1}:0]), .io_in_2(c[{w-1}:0]),')
        L.append(f'                  .io_out_0(i_{n}_0), .io_out_1(i_{n}_1));')
    L.append('')
    L.append('  // cov[v][i] 的第 k 位 = 变体 v 的第 i 位见过输入组合 k={a,b,c}')
    L.append('  logic [7:0] cov [NV][MAXW];')
    L.append('  int W [NV];')
    L.append('')
    L.append('  task automatic drive();')
    L.append('    case ($urandom_range(0, 5))')
    L.append("      0: begin a = '0;      b = '0;      c = '0;      end")
    L.append("      1: begin a = '1;      b = '1;      c = '1;      end")
    L.append('      2: begin a = {MAXW{1\'b1}} & {MAXW/2{2\'b01}}; b = ~a; c = a; end')
    L.append('      3: begin a = 1 << $urandom_range(0, MAXW-1);')
    L.append('               b = 1 << $urandom_range(0, MAXW-1);')
    L.append('               c = 1 << $urandom_range(0, MAXW-1); end')
    L.append('      4: begin a = $urandom & $urandom; b = $urandom; c = ~$urandom; end')
    L.append('      default: begin')
    L.append('        for (int k = 0; k < MAXW; k += 32) begin')
    L.append('          a[k+:1] = $urandom; b[k+:1] = $urandom; c[k+:1] = $urandom; end')
    L.append('        a = {$urandom,$urandom,$urandom}; b = {$urandom,$urandom,$urandom};')
    L.append('        c = {$urandom,$urandom,$urandom};')
    L.append('      end')
    L.append('    endcase')
    L.append('  endtask')
    L.append('')
    L.append('  `define CK(g,i,nm) \\')
    L.append('    begin checks++; if ((g) !== (i)) begin errors++; \\')
    L.append('      if (errors <= 40) $display("[%0t] MISMATCH %s golden=%h impl=%h", $time, nm, (g), (i)); \\')
    L.append('    end end')
    L.append('')
    L.append('  task automatic check();')
    for vi, (n, w, _) in enumerate(VARIANTS):
        L.append(f'    `CK(g_{n}_0, i_{n}_0, "{n}.out0")')
        L.append(f'    `CK(g_{n}_1, i_{n}_1, "{n}.out1")')
        L.append(f'    for (int i = 0; i < {w}; i++) cov[{vi}][i][{{a[i],b[i],c[i]}}] = 1\'b1;')
    L.append('  endtask')
    L.append('')
    L.append('  initial begin')
    L.append('    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;')
    for vi, (n, w, _) in enumerate(VARIANTS):
        L.append(f'    W[{vi}] = {w};')
    L.append('    for (int v = 0; v < NV; v++) for (int i = 0; i < MAXW; i++) cov[v][i] = 8\'h0;')
    L.append('    drive();')
    L.append('    repeat (NCYCLES) begin @(posedge clk); #1; check(); drive(); end')
    L.append('    report();')
    L.append('    $finish;')
    L.append('  end')
    L.append('')
    L.append('  task automatic report();')
    L.append('    int bad_cov = 0;')
    L.append('    $display("--- coverage: 每个变体每一位是否见过全部 8 种 (a,b,c) ---");')
    L.append('    for (int v = 0; v < NV; v++) begin')
    L.append('      int full = 0;')
    L.append('      for (int i = 0; i < W[v]; i++) if (cov[v][i] == 8\'hFF) full++;')
    L.append('      if (full != W[v]) bad_cov++;')
    L.append('      $display("  variant[%0d] W=%0d : %0d/%0d 位达成 8/8 组合", v, W[v], full, W[v]);')
    L.append('    end')
    L.append('    $display("checks=%0d errors=%0d", checks, errors);')
    L.append('    if (errors == 0 && checks > 1000 && bad_cov == 0) $display("TEST PASSED");')
    L.append('    else $display("TEST FAILED");')
    L.append('  endtask')
    L.append('endmodule')
    return "\n".join(L) + "\n"


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists() or path.read_text() != text:
        path.write_text(text)
        return True
    return False


def main():
    n = 0
    for name, w, users in VARIANTS:
        if write(REPO / 'rtl' / 'backend' / f'{name}.sv', wrapper(name, w, users)):
            n += 1
    if write(HERE / 'tb.sv', tb()):
        n += 1
    print(f'gen.py: {len(VARIANTS)} 个薄 wrapper + tb，已更新 {n} 个文件'
          if n else 'gen.py: 全部已是最新')
    return 0


if __name__ == '__main__':
    sys.exit(main())
