// =============================================================================
// indexedLSUopTable 家族 UT —— 7 个变体各一对 DUT（golden indexedLSUopTable_N
// 对重写 indexedLSUopTable_N_xs），把 src 的 **16 种取值全部穷举**，逐个比对
// outOffsetVs2 / outOffsetVd。
//
// ★ 为什么是穷举而不是随机 ★
// 本模块是纯组合的 4 入 6 出查找表，输入空间只有 16 个点。随机跑 200k 拍与
// 穷举 16 个点证明力完全相同，而穷举还额外保证「每个点都验到了」是事实而不是
// 概率。tb 仍按 +ncycles 跑满要求的拍数（每拍换一个 src，循环遍历），并在结束
// 时报告每个 (变体, src) 组合各被验了多少次 —— 任何一格为 0 即判失败。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  bit  clk = 0;
  int  errors = 0;
  longint checks = 0;
  always #5 clk = ~clk;

  logic [3:0] src;
  longint cov [7][16];

  logic [2:0] g1_vs2, g1_vd, x1_vs2, x1_vd;
  indexedLSUopTable_1    u_g1 (.src(src), .outOffsetVs2(g1_vs2), .outOffsetVd(g1_vd));
  indexedLSUopTable_1_xs u_x1 (.src(src), .outOffsetVs2(x1_vs2), .outOffsetVd(x1_vd));
  logic [2:0] g2_vs2, g2_vd, x2_vs2, x2_vd;
  indexedLSUopTable_2    u_g2 (.src(src), .outOffsetVs2(g2_vs2), .outOffsetVd(g2_vd));
  indexedLSUopTable_2_xs u_x2 (.src(src), .outOffsetVs2(x2_vs2), .outOffsetVd(x2_vd));
  logic [2:0] g3_vs2, g3_vd, x3_vs2, x3_vd;
  indexedLSUopTable_3    u_g3 (.src(src), .outOffsetVs2(g3_vs2), .outOffsetVd(g3_vd));
  indexedLSUopTable_3_xs u_x3 (.src(src), .outOffsetVs2(x3_vs2), .outOffsetVd(x3_vd));
  logic [2:0] g4_vs2, g4_vd, x4_vs2, x4_vd;
  indexedLSUopTable_4    u_g4 (.src(src), .outOffsetVs2(g4_vs2), .outOffsetVd(g4_vd));
  indexedLSUopTable_4_xs u_x4 (.src(src), .outOffsetVs2(x4_vs2), .outOffsetVd(x4_vd));
  logic [2:0] g5_vs2, g5_vd, x5_vs2, x5_vd;
  indexedLSUopTable_5    u_g5 (.src(src), .outOffsetVs2(g5_vs2), .outOffsetVd(g5_vd));
  indexedLSUopTable_5_xs u_x5 (.src(src), .outOffsetVs2(x5_vs2), .outOffsetVd(x5_vd));
  logic [2:0] g6_vs2, g6_vd, x6_vs2, x6_vd;
  indexedLSUopTable_6    u_g6 (.src(src), .outOffsetVs2(g6_vs2), .outOffsetVd(g6_vd));
  indexedLSUopTable_6_xs u_x6 (.src(src), .outOffsetVs2(x6_vs2), .outOffsetVd(x6_vd));
  logic [2:0] g7_vs2, g7_vd, x7_vs2, x7_vd;
  indexedLSUopTable_7    u_g7 (.src(src), .outOffsetVs2(g7_vs2), .outOffsetVd(g7_vd));
  indexedLSUopTable_7_xs u_x7 (.src(src), .outOffsetVs2(x7_vs2), .outOffsetVd(x7_vd));

  task automatic check_one(input int v, input logic [2:0] gv, gd, xv, xd);
    cov[v - 1][src]++;
    checks++;
    if (gv !== xv || gd !== xd) begin
      errors++;
      if (errors < 20)
        $display("MISMATCH variant=%0d src=%01h gold=(%0d,%0d) xs=(%0d,%0d)",
                 v, src, gv, gd, xv, xd);
    end
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int v = 0; v < 7; v++) for (int s = 0; s < 16; s++) cov[v][s] = 0;
    @(negedge clk);
    for (longint c = 0; c < NCYCLES; c++) begin
      src = 4'(c % 16);
      #1;
      check_one(1, g1_vs2, g1_vd, x1_vs2, x1_vd);
      check_one(2, g2_vs2, g2_vd, x2_vs2, x2_vd);
      check_one(3, g3_vs2, g3_vd, x3_vs2, x3_vd);
      check_one(4, g4_vs2, g4_vd, x4_vs2, x4_vd);
      check_one(5, g5_vs2, g5_vd, x5_vs2, x5_vd);
      check_one(6, g6_vs2, g6_vd, x6_vs2, x6_vd);
      check_one(7, g7_vs2, g7_vd, x7_vs2, x7_vd);
      @(negedge clk);
    end

    $display("=== COVERAGE (indexedLSUopTable) ===");
    begin
      int holes = 0;
      for (int v = 0; v < 7; v++)
        for (int s = 0; s < 16; s++)
          if (cov[v][s] == 0) begin
            holes++;
            $display("  UNCOVERED variant=%0d src=%01h", v + 1, s);
          end
      $display("  variants=7 x src=16 = 112 格，未覆盖 %0d 格，checks=%0d", holes, checks);
      if (holes != 0) begin
        $display("COVERAGE INSUFFICIENT: 输入空间没穷举完");
        errors++;
      end
    end

    if (errors == 0) $display("TEST PASSED (checks=%0d)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end

endmodule
