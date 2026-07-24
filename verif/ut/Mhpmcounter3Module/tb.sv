// Mhpmcounter3Module UT: golden vs 可读 primitive(_xs 变体)逐拍比对。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 8;   // 跳过复位后未稳定的若干拍
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic        w_wen;
  logic [63:0] w_wdata;
  logic        mcountinhibit_CY;
  logic        mcountinhibit_IR;
  logic [28:0] mcountinhibit_HPM3;
  logic        countingEn;
  logic [5:0]  perf_value;

  logic [63:0] g_rdata, i_rdata;
  logic [63:0] g_regOut, i_regOut;
  logic        g_of, i_of;

  Mhpmcounter3Module    u_g (
    .clock(clk), .reset(rst),
    .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(g_rdata), .regOut_ALL(g_regOut),
    .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR),
    .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn),
    .perf_value(perf_value), .toMhpmeventOF(g_of));
  Mhpmcounter3Module_xs u_i (
    .clock(clk), .reset(rst),
    .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(i_rdata), .regOut_ALL(i_regOut),
    .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR),
    .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn),
    .perf_value(perf_value), .toMhpmeventOF(i_of));

  // 随机激励：偏置 perf_value 使其常有增量以触发溢出路径；偶尔全宽写。
  always @(negedge clk) begin
    if (rst) begin
      w_wen              <= '0;
      w_wdata            <= '0;
      mcountinhibit_CY   <= '0;
      mcountinhibit_IR   <= '0;
      mcountinhibit_HPM3 <= '0;
      countingEn         <= '0;
      perf_value         <= '0;
    end else begin
      w_wen              <= ($urandom_range(0,7)==0);          // ~12% 显式写
      // 偶尔写接近满值以驱动溢出
      w_wdata            <= ($urandom_range(0,3)==0) ? 64'hFFFF_FFFF_FFFF_FFF0 + $urandom_range(0,15)
                                                     : {$urandom, $urandom};
      mcountinhibit_CY   <= 1'($urandom);
      mcountinhibit_IR   <= 1'($urandom);
      mcountinhibit_HPM3 <= {$urandom};                        // 低位含 [0]
      countingEn         <= ($urandom_range(0,3)!=0);          // ~75% 使能
      perf_value         <= 6'($urandom);                      // 0..63 增量
    end
  end

  // 逐拍比对
  always @(negedge clk) if (!rst) begin
    cyc++;
    if (cyc > WARMUP) begin
      #4; checks++;
      if (g_rdata !== i_rdata || g_regOut !== i_regOut || g_of !== i_of) begin
        errors++;
        if (errors<=30) $display("[%0t] rdata g=%h i=%h | regOut g=%h i=%h | OF g=%b i=%b",
                                 $time, g_rdata, i_rdata, g_regOut, i_regOut, g_of, i_of);
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
