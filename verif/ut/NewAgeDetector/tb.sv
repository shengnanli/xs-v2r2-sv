// =============================================================================
// NewAgeDetector 家族 UT：golden NewAgeDetector / NewAgeDetector_6 与重写
// NewAgeDetector_xs / NewAgeDetector_6_xs 同激励双例化，逐拍比全部 io_out。
//
// 激励按事件造（均匀随机碰不全这几种）：
//   * 两个条目同拍进队（次态规则 (1) 压过 (2)：同拍时 0 号条目算更老）
//   * 只有 0 号 / 只有 1 号进队、都不进队（时钟使能关，保持）
//   * canIssue 两位全亮（out 直接暴露 age_0_1）、单亮、全灭
//   * 1% 的拍中途拉复位（异步复位臂）
// 覆盖计数任一为 0 判 TEST FAILED，不让 errors=0 在空激励上成立。
// =============================================================================
`timescale 1ns/1ps
module tb;
  logic clk = 0;
  logic rst = 1;
  always #5 clk = ~clk;

  int NCYCLES = 200000;

  logic       enq0, enq1;
  logic [1:0] ci0, ci1;
  wire  [1:0] g_out0, g_out1, i_out0, i_out1;   // NewAgeDetector（2 发射口）
  wire  [1:0] g6_out0, i6_out0;                 // NewAgeDetector_6（1 发射口）

  NewAgeDetector      g_a (.clock(clk), .reset(rst), .io_enq_0(enq0), .io_enq_1(enq1),
                           .io_canIssue_0(ci0), .io_canIssue_1(ci1),
                           .io_out_0(g_out0), .io_out_1(g_out1));
  NewAgeDetector_xs   i_a (.clock(clk), .reset(rst), .io_enq_0(enq0), .io_enq_1(enq1),
                           .io_canIssue_0(ci0), .io_canIssue_1(ci1),
                           .io_out_0(i_out0), .io_out_1(i_out1));
  NewAgeDetector_6    g_b (.clock(clk), .reset(rst), .io_enq_0(enq0), .io_enq_1(enq1),
                           .io_canIssue_0(ci0), .io_out_0(g6_out0));
  NewAgeDetector_6_xs i_b (.clock(clk), .reset(rst), .io_enq_0(enq0), .io_enq_1(enq1),
                           .io_canIssue_0(ci0), .io_out_0(i6_out0));

  longint checks = 0;
  longint errors = 0;
  longint cov_enq_both = 0, cov_enq_0 = 0, cov_enq_1 = 0, cov_enq_none = 0;
  longint cov_pair_age0 = 0, cov_pair_age1 = 0;   // canIssue=11 时选中 0 号 / 1 号
  longint cov_midreset = 0;

  function automatic logic [1:0] rand_ci();
    int r;
    r = $urandom_range(0, 99);
    if (r < 50)      return 2'b11;
    else if (r < 70) return 2'b01;
    else if (r < 90) return 2'b10;
    else             return 2'b00;
  endfunction

  // 激励在下降沿给；复位是异步的，也在下降沿翻
  always @(negedge clk) begin
    int r;
    r = $urandom_range(0, 99);
    enq0 = (r < 30) || (r >= 60 && r < 80);
    enq1 = (r < 30) || (r >= 30 && r < 60);
    ci0 = rand_ci();
    ci1 = rand_ci();
  end

  // 比对：在上升沿前 1ns 采（组合输出已稳）
  always @(posedge clk) begin
    #4;
    if (!rst) begin
      checks++;
      if (g_out0 !== i_out0 || g_out1 !== i_out1 || g6_out0 !== i6_out0) begin
        errors++;
        if (errors <= 10)
          $display("[%0t] MISMATCH enq=%b%b ci0=%b ci1=%b  g=%b/%b/%b i=%b/%b/%b", $time,
                   enq1, enq0, ci0, ci1, g_out0, g_out1, g6_out0, i_out0, i_out1, i6_out0);
      end
      if (enq0 && enq1)        cov_enq_both++;
      else if (enq0)           cov_enq_0++;
      else if (enq1)           cov_enq_1++;
      else                     cov_enq_none++;
      if (ci0 == 2'b11 && g_out0 == 2'b01) cov_pair_age0++;
      if (ci0 == 2'b11 && g_out0 == 2'b10) cov_pair_age1++;
    end
  end

  initial begin
    int bad;
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    rst = 1; repeat (4) @(posedge clk); @(negedge clk); rst = 0;
    for (int c = 0; c < NCYCLES; c++) begin
      @(negedge clk);
      #1;
      if ($urandom_range(0, 99) == 0) begin rst = 1; cov_midreset++; end
      else rst = 0;
    end
    bad = (errors != 0);
    if (cov_enq_both == 0 || cov_enq_0 == 0 || cov_enq_1 == 0 || cov_enq_none == 0 ||
        cov_pair_age0 == 0 || cov_pair_age1 == 0 || cov_midreset == 0) bad = 1;
    $display("COVER enq_both=%0d enq_0=%0d enq_1=%0d enq_none=%0d pair_age0=%0d pair_age1=%0d midreset=%0d",
             cov_enq_both, cov_enq_0, cov_enq_1, cov_enq_none, cov_pair_age0, cov_pair_age1, cov_midreset);
    $display("checks=%0d errors=%0d", checks, errors);
    if (!bad) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
