// 自动生成：scripts/gen_l2slice_ut.py —— 勿手改（命令行见同目录 Makefile 的 gentb）
// 目标：MbistClockGateCell
// golden <T> 与派生 <T>_xs 双例化，同激励逐拍 4 态比全部输出；覆盖闸见文件尾。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  always #5 clock = ~clock;
  logic reset;
  longint checks = 0, errors = 0;
  longint cyc = 0;   // 复位释放后的拍号（--narrow 表达式可用它做分相激励）
  function automatic logic [4095:0] rnd(input int w);
    logic [4095:0] v;
    v = '0;
    for (int i = 0; i < w; i += 32) v[i+:32] = $urandom;
    return v;
  endfunction

  // ======================= MbistClockGateCell =======================
  logic MbistClockGateCell__mbist_writeen;
  logic MbistClockGateCell__mbist_readen;
  logic MbistClockGateCell__mbist_req;
  logic MbistClockGateCell__E;
  logic MbistClockGateCell__dft_cgen;
  wire  g_MbistClockGateCell__out_clock;
  wire  i_MbistClockGateCell__out_clock;
  logic p_MbistClockGateCell__out_clock;
  bit   t_MbistClockGateCell__out_clock;
  MbistClockGateCell u_g_MbistClockGateCell (
    .clock (clock),
    .mbist_writeen (MbistClockGateCell__mbist_writeen),
    .mbist_readen (MbistClockGateCell__mbist_readen),
    .mbist_req (MbistClockGateCell__mbist_req),
    .E (MbistClockGateCell__E),
    .dft_cgen (MbistClockGateCell__dft_cgen),
    .out_clock (g_MbistClockGateCell__out_clock)
  );
  MbistClockGateCell_xs u_i_MbistClockGateCell (
    .clock (clock),
    .mbist_writeen (MbistClockGateCell__mbist_writeen),
    .mbist_readen (MbistClockGateCell__mbist_readen),
    .mbist_req (MbistClockGateCell__mbist_req),
    .E (MbistClockGateCell__E),
    .dft_cgen (MbistClockGateCell__dft_cgen),
    .out_clock (i_MbistClockGateCell__out_clock)
  );
  task automatic drive_MbistClockGateCell();
    MbistClockGateCell__mbist_writeen = $urandom % 2;
    MbistClockGateCell__mbist_readen = $urandom % 2;
    MbistClockGateCell__mbist_req = $urandom % 2;
    MbistClockGateCell__E = $urandom % 2;
    MbistClockGateCell__dft_cgen = $urandom % 2;
  endtask
  task automatic check_MbistClockGateCell();
    checks++;
    if (g_MbistClockGateCell__out_clock !== i_MbistClockGateCell__out_clock) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH MbistClockGateCell.out_clock g=%h i=%h", cyc, g_MbistClockGateCell__out_clock, i_MbistClockGateCell__out_clock);
    end
    if (g_MbistClockGateCell__out_clock !== p_MbistClockGateCell__out_clock) t_MbistClockGateCell__out_clock = 1'b1;
    p_MbistClockGateCell__out_clock = g_MbistClockGateCell__out_clock;
  endtask
  longint cov_MbistClockGateCell_mbist = 0;
  longint cov_MbistClockGateCell_te = 0;
  task automatic cover_MbistClockGateCell();
    if (MbistClockGateCell__mbist_req) cov_MbistClockGateCell_mbist++;
    if (MbistClockGateCell__dft_cgen) cov_MbistClockGateCell_te++;
  endtask
  task automatic preinit_MbistClockGateCell();
  endtask
  task automatic sync_MbistClockGateCell();
  endtask

  bit covfail = 0;
  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    reset = 1'b1;
    drive_MbistClockGateCell();
    #1;
    preinit_MbistClockGateCell();
    sync_MbistClockGateCell();
    repeat (5) @(posedge clock);
    @(negedge clock) reset = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (reset) reset = 1'b0; else if (($urandom % 5000) == 0) reset = 1'b1;
      drive_MbistClockGateCell();
      #1;
      check_MbistClockGateCell();
      cover_MbistClockGateCell();
      @(posedge clock); #1;
      check_MbistClockGateCell();
    end
    begin int tg; tg = 0;
      if (t_MbistClockGateCell__out_clock) tg++; else $display("COV: MbistClockGateCell.out_clock never toggled");
      $display("MbistClockGateCell: toggled=%0d/1 (need >= 1)", tg);
      if (tg < 1) covfail = 1;
      $display("MbistClockGateCell: cover mbist = %0d", cov_MbistClockGateCell_mbist);
      if (cov_MbistClockGateCell_mbist == 0) covfail = 1;
      $display("MbistClockGateCell: cover te = %0d", cov_MbistClockGateCell_te);
      if (cov_MbistClockGateCell_te == 0) covfail = 1;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0 || covfail) begin $display("TEST FAILED (coverage)"); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
