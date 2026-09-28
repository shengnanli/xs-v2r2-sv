// 自动生成：scripts/gen_l2slice_ut.py —— 勿手改（命令行见同目录 Makefile 的 gentb）
// 目标：MbistClockGateCell_93 ClockMux
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

  // ======================= MbistClockGateCell_93 =======================
  logic MbistClockGateCell_93__mbist_writeen;
  logic MbistClockGateCell_93__mbist_readen;
  logic MbistClockGateCell_93__mbist_req;
  logic MbistClockGateCell_93__E;
  logic MbistClockGateCell_93__dft_ram_mcp_hold;
  logic MbistClockGateCell_93__dft_ram_aux_clk;
  logic MbistClockGateCell_93__dft_ram_aux_ckbp;
  logic MbistClockGateCell_93__dft_cgen;
  wire  g_MbistClockGateCell_93__out_clock;
  wire  i_MbistClockGateCell_93__out_clock;
  logic p_MbistClockGateCell_93__out_clock;
  bit   t_MbistClockGateCell_93__out_clock;
  MbistClockGateCell_93 u_g_MbistClockGateCell_93 (
    .clock (clock),
    .mbist_writeen (MbistClockGateCell_93__mbist_writeen),
    .mbist_readen (MbistClockGateCell_93__mbist_readen),
    .mbist_req (MbistClockGateCell_93__mbist_req),
    .E (MbistClockGateCell_93__E),
    .dft_ram_mcp_hold (MbistClockGateCell_93__dft_ram_mcp_hold),
    .dft_ram_aux_clk (MbistClockGateCell_93__dft_ram_aux_clk),
    .dft_ram_aux_ckbp (MbistClockGateCell_93__dft_ram_aux_ckbp),
    .dft_cgen (MbistClockGateCell_93__dft_cgen),
    .out_clock (g_MbistClockGateCell_93__out_clock)
  );
  MbistClockGateCell_93_xs u_i_MbistClockGateCell_93 (
    .clock (clock),
    .mbist_writeen (MbistClockGateCell_93__mbist_writeen),
    .mbist_readen (MbistClockGateCell_93__mbist_readen),
    .mbist_req (MbistClockGateCell_93__mbist_req),
    .E (MbistClockGateCell_93__E),
    .dft_ram_mcp_hold (MbistClockGateCell_93__dft_ram_mcp_hold),
    .dft_ram_aux_clk (MbistClockGateCell_93__dft_ram_aux_clk),
    .dft_ram_aux_ckbp (MbistClockGateCell_93__dft_ram_aux_ckbp),
    .dft_cgen (MbistClockGateCell_93__dft_cgen),
    .out_clock (i_MbistClockGateCell_93__out_clock)
  );
  task automatic drive_MbistClockGateCell_93();
    MbistClockGateCell_93__mbist_writeen = $urandom % 2;
    MbistClockGateCell_93__mbist_readen = $urandom % 2;
    MbistClockGateCell_93__mbist_req = $urandom % 2;
    MbistClockGateCell_93__E = $urandom % 2;
    MbistClockGateCell_93__dft_ram_mcp_hold = $urandom % 2;
    MbistClockGateCell_93__dft_ram_aux_clk = $urandom % 2;
    MbistClockGateCell_93__dft_ram_aux_ckbp = $urandom % 2;
    MbistClockGateCell_93__dft_cgen = $urandom % 2;
  endtask
  task automatic check_MbistClockGateCell_93();
    checks++;
    if (g_MbistClockGateCell_93__out_clock !== i_MbistClockGateCell_93__out_clock) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH MbistClockGateCell_93.out_clock g=%h i=%h", cyc, g_MbistClockGateCell_93__out_clock, i_MbistClockGateCell_93__out_clock);
    end
    if (g_MbistClockGateCell_93__out_clock !== p_MbistClockGateCell_93__out_clock) t_MbistClockGateCell_93__out_clock = 1'b1;
    p_MbistClockGateCell_93__out_clock = g_MbistClockGateCell_93__out_clock;
  endtask
  longint cov_MbistClockGateCell_93_bypass = 0;
  task automatic cover_MbistClockGateCell_93();
    if (MbistClockGateCell_93__dft_ram_aux_ckbp) cov_MbistClockGateCell_93_bypass++;
  endtask
  task automatic sync_MbistClockGateCell_93();
  endtask

  // ======================= ClockMux =======================
  logic ClockMux__clk0;
  logic ClockMux__clk1;
  logic ClockMux__sel;
  wire  g_ClockMux__clkout;
  wire  i_ClockMux__clkout;
  logic p_ClockMux__clkout;
  bit   t_ClockMux__clkout;
  ClockMux u_g_ClockMux (
    .clk0 (ClockMux__clk0),
    .clk1 (ClockMux__clk1),
    .sel (ClockMux__sel),
    .clkout (g_ClockMux__clkout)
  );
  ClockMux_xs u_i_ClockMux (
    .clk0 (ClockMux__clk0),
    .clk1 (ClockMux__clk1),
    .sel (ClockMux__sel),
    .clkout (i_ClockMux__clkout)
  );
  task automatic drive_ClockMux();
    ClockMux__clk0 = $urandom % 2;
    ClockMux__clk1 = $urandom % 2;
    ClockMux__sel = $urandom % 2;
  endtask
  task automatic check_ClockMux();
    checks++;
    if (g_ClockMux__clkout !== i_ClockMux__clkout) begin
      errors++;
      if (errors <= 40) $display("[cyc %0d] MISMATCH ClockMux.clkout g=%h i=%h", cyc, g_ClockMux__clkout, i_ClockMux__clkout);
    end
    if (g_ClockMux__clkout !== p_ClockMux__clkout) t_ClockMux__clkout = 1'b1;
    p_ClockMux__clkout = g_ClockMux__clkout;
  endtask
  longint cov_ClockMux_sel = 0;
  task automatic cover_ClockMux();
    if (ClockMux__sel) cov_ClockMux_sel++;
  endtask
  task automatic sync_ClockMux();
  endtask

  bit covfail = 0;
  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    reset = 1'b1;
    drive_MbistClockGateCell_93();
    drive_ClockMux();
    #1;
    sync_MbistClockGateCell_93();
    sync_ClockMux();
    repeat (5) @(posedge clock);
    @(negedge clock) reset = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (reset) reset = 1'b0; else if (($urandom % 5000) == 0) reset = 1'b1;
      drive_MbistClockGateCell_93();
      drive_ClockMux();
      #1;
      check_MbistClockGateCell_93();
      cover_MbistClockGateCell_93();
      check_ClockMux();
      cover_ClockMux();
      @(posedge clock); #1;
      check_MbistClockGateCell_93();
      check_ClockMux();
    end
    begin int tg; tg = 0;
      if (t_MbistClockGateCell_93__out_clock) tg++; else $display("COV: MbistClockGateCell_93.out_clock never toggled");
      $display("MbistClockGateCell_93: toggled=%0d/1 (need >= 1)", tg);
      if (tg < 1) covfail = 1;
      $display("MbistClockGateCell_93: cover bypass = %0d", cov_MbistClockGateCell_93_bypass);
      if (cov_MbistClockGateCell_93_bypass == 0) covfail = 1;
    end
    begin int tg; tg = 0;
      if (t_ClockMux__clkout) tg++; else $display("COV: ClockMux.clkout never toggled");
      $display("ClockMux: toggled=%0d/1 (need >= 1)", tg);
      if (tg < 1) covfail = 1;
      $display("ClockMux: cover sel = %0d", cov_ClockMux_sel);
      if (cov_ClockMux_sel == 0) covfail = 1;
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0 || covfail) begin $display("TEST FAILED (coverage)"); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
