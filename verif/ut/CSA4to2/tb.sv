// =============================================================================
// tb —— CSA4to2 UT：golden CSA4to2 与重写件 CSA4to2_xs 双例化，同激励逐"拍"比两个 107 位输出，
//   外加独立 oracle（不看任何一侧实现）：(a+b+c+d) mod 2^107 == (out_sum + out_car) mod 2^107。
// 覆盖判据（写进 PASS）：输出第 j 列只依赖第 j 列的 a/b/c/d 与第 j-1 列的 a/b/c（进位入），
//   所以按列统计 7 位局部输入组合 {a,b,c,d}[j] × {a,b,c}[j-1]：第 1..106 列每列 128 种都要出现，
//   第 0 列 16 种都要出现 —— 对这种局部函数，这就是逐列穷举。
// 激励：随机 / 全 0 / 全 1 / 交替 / 稀疏 / 互补（a+b 全 1 进位链）混合。
// =============================================================================
`timescale 1ns/1ps
module tb;
  localparam int W = 107;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0, oracle_checks = 0;
  bit clk = 0; always #5 clk = ~clk;

  logic [W-1:0] a, b, c, d;
  logic [W-1:0] g_sum, g_car, i_sum, i_car;

  CSA4to2    u_g (.io_in_a(a), .io_in_b(b), .io_in_c(c), .io_in_d(d), .io_out_sum(g_sum), .io_out_car(g_car));
  CSA4to2_xs u_i (.io_in_a(a), .io_in_b(b), .io_in_c(c), .io_in_d(d), .io_out_sum(i_sum), .io_out_car(i_car));

  bit seen [W][128];

  function automatic logic [W-1:0] pick();
    logic [W-1:0] v;
    for (int k = 0; k < (W + 31) / 32; k++) v[k*32 +: 32] = $urandom;   // 越界部分被截掉
    case ($urandom_range(0, 9))
      0: v = '0;
      1: v = '1;
      2: v = {W{2'b10}};
      3: v = v & {W{$urandom_range(0,1) == 1}} & (v >> 3);              // 稀疏
      default: ;
    endcase
    return v;
  endfunction

  initial begin
    int cyc;
    logic [W:0] lhs, rhs;
    int missing;
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      a = pick(); b = pick(); c = pick(); d = pick();
      if ($urandom_range(0, 7) == 0) b = ~a;          // a^b 全 1：第一级每列都选 c
      if ($urandom_range(0, 7) == 0) d = a ^ b ^ c;   // 四输入奇偶全 0：第二级每列都选 d
      #1;
      checks++;
      if (g_sum !== i_sum || g_car !== i_car) begin
        errors++;
        if (errors <= 20) $display("[%0d] MISMATCH sum g=%h i=%h car g=%h i=%h", cyc, g_sum, i_sum, g_car, i_car);
      end
      // 独立 oracle：算术不变式（取模 2^W）
      lhs = (W+1)'(a) + (W+1)'(b) + (W+1)'(c) + (W+1)'(d);
      rhs = (W+1)'(i_sum) + (W+1)'(i_car);
      oracle_checks++;
      if (lhs[W-1:0] !== rhs[W-1:0]) begin
        errors++;
        if (errors <= 20) $display("[%0d] ORACLE MISMATCH a+b+c+d=%h sum+car=%h", cyc, lhs[W-1:0], rhs[W-1:0]);
      end
      // 逐列局部输入组合
      seen[0][{a[0], b[0], c[0], d[0], 3'b000}] = 1;
      for (int j = 1; j < W; j++) seen[j][{a[j], b[j], c[j], d[j], a[j-1], b[j-1], c[j-1]}] = 1;
      @(posedge clk);
    end
    missing = 0;
    for (int k = 0; k < 16; k++) if (!seen[0][k << 3]) missing++;
    for (int j = 1; j < W; j++) for (int k = 0; k < 128; k++) if (!seen[j][k]) missing++;
    $display("checks=%0d oracle_checks=%0d errors=%0d coverage_missing_combos=%0d (of %0d)",
             checks, oracle_checks, errors, missing, 16 + (W - 1) * 128);
    if (errors == 0 && missing == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
