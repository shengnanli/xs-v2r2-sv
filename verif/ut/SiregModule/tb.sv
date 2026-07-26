// Indirect-register family UT: golden vs 可读 primitive(_xs)逐拍比对。
// 覆盖两形态: base SiregModule(写锁存+外部 rdata 透传+regOut_ALL) 与
// numbered Sireg2Module(写锁存+regOut_ALL)。golden 无 reset —— clock-only 写锁存;
// tb 仍产复位相位仅用于对齐初值/统计, 不驱动 DUT reset(DUT 无 reset 端口)。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic        w_wen;
  logic [63:0] w_wdata;
  logic [63:0] iregRead_sireg;

  logic [63:0] g_rdata, i_rdata, g_regOut, i_regOut;   // base
  logic [63:0] g2_regOut, i2_regOut;                    // numbered

  SiregModule    u_g (.clock(clk),.w_wen(w_wen),.w_wdata(w_wdata),
                      .rdata(g_rdata),.regOut_ALL(g_regOut),.iregRead_sireg(iregRead_sireg));
  SiregModule_xs u_i (.clock(clk),.w_wen(w_wen),.w_wdata(w_wdata),
                      .rdata(i_rdata),.regOut_ALL(i_regOut),.iregRead_sireg(iregRead_sireg));

  Sireg2Module    u_g2 (.clock(clk),.w_wen(w_wen),.w_wdata(w_wdata),.regOut_ALL(g2_regOut));
  Sireg2Module_xs u_i2 (.clock(clk),.w_wen(w_wen),.w_wdata(w_wdata),.regOut_ALL(i2_regOut));

  always @(negedge clk) begin
    if (rst) begin
      w_wen <= '0; w_wdata <= '0; iregRead_sireg <= '0;
    end else begin
      w_wen          <= ($urandom_range(0,1)==0);
      w_wdata        <= {$urandom, $urandom};
      iregRead_sireg <= {$urandom, $urandom};
    end
  end

  always @(negedge clk) if (!rst) begin
    cyc++;
    if (cyc > WARMUP) begin
      #4; checks++;
      if (g_rdata!==i_rdata || g_regOut!==i_regOut || g2_regOut!==i2_regOut) begin
        errors++;
        if (errors<=30) $display("[%0t] base rd g=%h i=%h reg g=%h i=%h | n2 reg g=%h i=%h",
                                 $time, g_rdata,i_rdata, g_regOut,i_regOut, g2_regOut,i2_regOut);
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
