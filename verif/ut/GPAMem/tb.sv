// 自动生成: GPAMem UT: golden vs 可读核 _xs 逐拍逐输出比对(共享 golden 存储子模块)。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic reset;
  logic io_fromIFU_gpaddrMem_wen;
  logic [5:0] io_fromIFU_gpaddrMem_waddr;
  logic [55:0] io_fromIFU_gpaddrMem_wdata_gpaddr;
  logic io_fromIFU_gpaddrMem_wdata_isForVSnonLeafPTE;
  logic io_exceptionReadAddr_valid;
  logic [5:0] io_exceptionReadAddr_bits_ftqPtr_value;
  logic [3:0] io_exceptionReadAddr_bits_ftqOffset;
  logic [55:0] g_io_exceptionReadData_gpaddr;
  logic g_io_exceptionReadData_isForVSnonLeafPTE;
  logic [55:0] i_io_exceptionReadData_gpaddr;
  logic i_io_exceptionReadData_isForVSnonLeafPTE;

  GPAMem u_g (
    .clock(clk),
    .reset(reset),
    .io_fromIFU_gpaddrMem_wen(io_fromIFU_gpaddrMem_wen),
    .io_fromIFU_gpaddrMem_waddr(io_fromIFU_gpaddrMem_waddr),
    .io_fromIFU_gpaddrMem_wdata_gpaddr(io_fromIFU_gpaddrMem_wdata_gpaddr),
    .io_fromIFU_gpaddrMem_wdata_isForVSnonLeafPTE(io_fromIFU_gpaddrMem_wdata_isForVSnonLeafPTE),
    .io_exceptionReadAddr_valid(io_exceptionReadAddr_valid),
    .io_exceptionReadAddr_bits_ftqPtr_value(io_exceptionReadAddr_bits_ftqPtr_value),
    .io_exceptionReadAddr_bits_ftqOffset(io_exceptionReadAddr_bits_ftqOffset),
    .io_exceptionReadData_gpaddr(g_io_exceptionReadData_gpaddr),
    .io_exceptionReadData_isForVSnonLeafPTE(g_io_exceptionReadData_isForVSnonLeafPTE)
  );
  GPAMem_xs u_i (
    .clock(clk),
    .reset(reset),
    .io_fromIFU_gpaddrMem_wen(io_fromIFU_gpaddrMem_wen),
    .io_fromIFU_gpaddrMem_waddr(io_fromIFU_gpaddrMem_waddr),
    .io_fromIFU_gpaddrMem_wdata_gpaddr(io_fromIFU_gpaddrMem_wdata_gpaddr),
    .io_fromIFU_gpaddrMem_wdata_isForVSnonLeafPTE(io_fromIFU_gpaddrMem_wdata_isForVSnonLeafPTE),
    .io_exceptionReadAddr_valid(io_exceptionReadAddr_valid),
    .io_exceptionReadAddr_bits_ftqPtr_value(io_exceptionReadAddr_bits_ftqPtr_value),
    .io_exceptionReadAddr_bits_ftqOffset(io_exceptionReadAddr_bits_ftqOffset),
    .io_exceptionReadData_gpaddr(i_io_exceptionReadData_gpaddr),
    .io_exceptionReadData_isForVSnonLeafPTE(i_io_exceptionReadData_isForVSnonLeafPTE)
  );

  task automatic drive_inputs();
    reset = ($urandom_range(0,99) < 3);
    io_fromIFU_gpaddrMem_wen = $urandom;
    io_fromIFU_gpaddrMem_waddr = $urandom;
    io_fromIFU_gpaddrMem_wdata_gpaddr = $urandom;
    io_fromIFU_gpaddrMem_wdata_isForVSnonLeafPTE = $urandom;
    io_exceptionReadAddr_valid = $urandom;
    io_exceptionReadAddr_bits_ftqPtr_value = $urandom;
    io_exceptionReadAddr_bits_ftqOffset = $urandom;
  endtask
  task automatic check_outputs();
    if (!$isunknown(g_io_exceptionReadData_gpaddr) && (g_io_exceptionReadData_gpaddr) !== (i_io_exceptionReadData_gpaddr)) begin errors++; if (errors<=60) $display("[%0t] io_exceptionReadData_gpaddr g=%h i=%h",$time,g_io_exceptionReadData_gpaddr,i_io_exceptionReadData_gpaddr); end checks++;
    if (!$isunknown(g_io_exceptionReadData_isForVSnonLeafPTE) && (g_io_exceptionReadData_isForVSnonLeafPTE) !== (i_io_exceptionReadData_isForVSnonLeafPTE)) begin errors++; if (errors<=60) $display("[%0t] io_exceptionReadData_isForVSnonLeafPTE g=%h i=%h",$time,g_io_exceptionReadData_isForVSnonLeafPTE,i_io_exceptionReadData_isForVSnonLeafPTE); end checks++;
  endtask

  initial begin
    drive_inputs(); reset = 1;
    repeat (5) @(negedge clk);
    repeat (NCYCLES) begin
      drive_inputs();
      @(posedge clk);
      #1 check_outputs();
      @(negedge clk);
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
