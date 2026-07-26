// Pmpaddr0Module UT: golden vs 可读 primitive(_xs 变体)逐拍比对。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 8;   // 跳过复位后未稳定的若干拍
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic        w_wen;
  logic [63:0] w_wdata;
  logic [63:0] addrRData_0;

  logic [63:0] g_rdata, i_rdata;
  logic [45:0] g_regOut, i_regOut;

  Pmpaddr0Module    u_g (
    .clock(clk), .reset(rst), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(g_rdata), .regOut_ADDRESS(g_regOut), .addrRData_0(addrRData_0));
  Pmpaddr0Module_xs u_i (
    .clock(clk), .reset(rst), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(i_rdata), .regOut_ADDRESS(i_regOut), .addrRData_0(addrRData_0));

  // 随机激励：驱动写、宽 w_wdata(测 [45:0] 截断)、独立 addrRData 读值。
  always @(negedge clk) begin
    if (rst) begin
      w_wen       <= '0;
      w_wdata     <= '0;
      addrRData_0 <= '0;
    end else begin
      w_wen       <= ($urandom_range(0,2)!=0);   // ~67% 写(充分翻转 reg)
      w_wdata     <= {$urandom, $urandom};        // 全 64 位随机(高位应被丢弃)
      addrRData_0 <= {$urandom, $urandom};        // 读口独立随机
    end
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
