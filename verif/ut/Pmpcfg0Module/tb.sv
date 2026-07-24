// Pmpcfg0Module UT: golden vs 可读 primitive(_xs 变体)逐拍比对(纯组合)。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 2;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic [127:0] cfgRData;

  logic [63:0] g_rdata, i_rdata;
  logic [63:0] g_regOut, i_regOut;

  Pmpcfg0Module    u_g (.rdata(g_rdata), .regOut_ALL(g_regOut), .cfgRData(cfgRData));
  Pmpcfg0Module_xs u_i (.rdata(i_rdata), .regOut_ALL(i_regOut), .cfgRData(cfgRData));

  // 随机激励：全宽 128 位驱动，覆盖高低半区。
  always @(negedge clk) begin
    if (rst)
      cfgRData <= '0;
    else
      cfgRData <= {$urandom, $urandom, $urandom, $urandom};
  end

  // 逐拍比对
  always @(negedge clk) if (!rst) begin
    cyc++;
    if (cyc > WARMUP) begin
      #4; checks++;
      if (g_rdata !== i_rdata || g_regOut !== i_regOut) begin
        errors++;
        if (errors<=30) $display("[%0t] rdata g=%h i=%h | regOut g=%h i=%h",
                                 $time, g_rdata, i_rdata, g_regOut, i_regOut);
      end
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
