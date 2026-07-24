// Hpmcounter3Module UT: golden vs 可读 primitive(_xs 变体)逐拍比对。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 8;   // 跳过复位后未稳定的若干拍
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic [63:0] mHPM_hpmcounters_0;
  logic        debugModeStopCount;
  logic        unprivCountUpdate;

  logic [63:0] g_rdata, i_rdata;

  Hpmcounter3Module    u_g (
    .clock(clk), .reset(rst), .rdata(g_rdata),
    .mHPM_hpmcounters_0(mHPM_hpmcounters_0),
    .debugModeStopCount(debugModeStopCount),
    .unprivCountUpdate(unprivCountUpdate));
  Hpmcounter3Module_xs u_i (
    .clock(clk), .reset(rst), .rdata(i_rdata),
    .mHPM_hpmcounters_0(mHPM_hpmcounters_0),
    .debugModeStopCount(debugModeStopCount),
    .unprivCountUpdate(unprivCountUpdate));

  // 随机激励
  always @(negedge clk) begin
    if (rst) begin
      mHPM_hpmcounters_0 <= '0;
      debugModeStopCount <= '0;
      unprivCountUpdate  <= '0;
    end else begin
      mHPM_hpmcounters_0 <= {$urandom, $urandom};
      debugModeStopCount <= 1'($urandom);
      unprivCountUpdate  <= ($urandom_range(0,1)==0);
    end
  end

  // 逐拍比对
  always @(negedge clk) if (!rst) begin
    cyc++;
    if (cyc > WARMUP) begin
      #4; checks++;
      if (g_rdata !== i_rdata) begin errors++;
        if (errors<=30) $display("[%0t] rdata g=%h i=%h", $time, g_rdata, i_rdata); end
    end
  end

  initial begin
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
