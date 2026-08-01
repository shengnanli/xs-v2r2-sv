// 自动生成: SnapshotGenerator_3 UT: golden vs 可读核 _xs 逐拍逐输出比对。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic reset;
  logic io_enq;
  logic io_enqData_0_flag;
  logic [7:0] io_enqData_0_value;
  logic io_deq;
  logic io_redirect;
  logic io_flushVec_0;
  logic io_flushVec_1;
  logic io_flushVec_2;
  logic io_flushVec_3;

  logic g_io_snapshots_0_0_flag;
  logic [7:0] g_io_snapshots_0_0_value;
  logic g_io_snapshots_1_0_flag;
  logic [7:0] g_io_snapshots_1_0_value;
  logic g_io_snapshots_2_0_flag;
  logic [7:0] g_io_snapshots_2_0_value;
  logic g_io_snapshots_3_0_flag;
  logic [7:0] g_io_snapshots_3_0_value;

  logic i_io_snapshots_0_0_flag;
  logic [7:0] i_io_snapshots_0_0_value;
  logic i_io_snapshots_1_0_flag;
  logic [7:0] i_io_snapshots_1_0_value;
  logic i_io_snapshots_2_0_flag;
  logic [7:0] i_io_snapshots_2_0_value;
  logic i_io_snapshots_3_0_flag;
  logic [7:0] i_io_snapshots_3_0_value;

  SnapshotGenerator_3 u_g (
    .clock(clk),
    .reset(reset),
    .io_enq(io_enq),
    .io_enqData_0_flag(io_enqData_0_flag),
    .io_enqData_0_value(io_enqData_0_value),
    .io_deq(io_deq),
    .io_redirect(io_redirect),
    .io_flushVec_0(io_flushVec_0),
    .io_flushVec_1(io_flushVec_1),
    .io_flushVec_2(io_flushVec_2),
    .io_flushVec_3(io_flushVec_3),
    .io_snapshots_0_0_flag(g_io_snapshots_0_0_flag),
    .io_snapshots_0_0_value(g_io_snapshots_0_0_value),
    .io_snapshots_1_0_flag(g_io_snapshots_1_0_flag),
    .io_snapshots_1_0_value(g_io_snapshots_1_0_value),
    .io_snapshots_2_0_flag(g_io_snapshots_2_0_flag),
    .io_snapshots_2_0_value(g_io_snapshots_2_0_value),
    .io_snapshots_3_0_flag(g_io_snapshots_3_0_flag),
    .io_snapshots_3_0_value(g_io_snapshots_3_0_value)
  );
  SnapshotGenerator_3_xs u_i (
    .clock(clk),
    .reset(reset),
    .io_enq(io_enq),
    .io_enqData_0_flag(io_enqData_0_flag),
    .io_enqData_0_value(io_enqData_0_value),
    .io_deq(io_deq),
    .io_redirect(io_redirect),
    .io_flushVec_0(io_flushVec_0),
    .io_flushVec_1(io_flushVec_1),
    .io_flushVec_2(io_flushVec_2),
    .io_flushVec_3(io_flushVec_3),
    .io_snapshots_0_0_flag(i_io_snapshots_0_0_flag),
    .io_snapshots_0_0_value(i_io_snapshots_0_0_value),
    .io_snapshots_1_0_flag(i_io_snapshots_1_0_flag),
    .io_snapshots_1_0_value(i_io_snapshots_1_0_value),
    .io_snapshots_2_0_flag(i_io_snapshots_2_0_flag),
    .io_snapshots_2_0_value(i_io_snapshots_2_0_value),
    .io_snapshots_3_0_flag(i_io_snapshots_3_0_flag),
    .io_snapshots_3_0_value(i_io_snapshots_3_0_value)
  );

  task automatic drive_inputs();
    reset = ($urandom_range(0,99) < 3);
    io_enq = $urandom;
    io_enqData_0_flag = $urandom;
    io_enqData_0_value = $urandom;
    io_deq = $urandom;
    io_redirect = $urandom;
    io_flushVec_0 = $urandom;
    io_flushVec_1 = $urandom;
    io_flushVec_2 = $urandom;
    io_flushVec_3 = $urandom;
  endtask
  task automatic check_outputs();
    if (!$isunknown(g_io_snapshots_0_0_flag) && (g_io_snapshots_0_0_flag) !== (i_io_snapshots_0_0_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_0_flag g=%h i=%h",$time,g_io_snapshots_0_0_flag,i_io_snapshots_0_0_flag); end checks++;
    if (!$isunknown(g_io_snapshots_0_0_value) && (g_io_snapshots_0_0_value) !== (i_io_snapshots_0_0_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_0_value g=%h i=%h",$time,g_io_snapshots_0_0_value,i_io_snapshots_0_0_value); end checks++;
    if (!$isunknown(g_io_snapshots_1_0_flag) && (g_io_snapshots_1_0_flag) !== (i_io_snapshots_1_0_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_0_flag g=%h i=%h",$time,g_io_snapshots_1_0_flag,i_io_snapshots_1_0_flag); end checks++;
    if (!$isunknown(g_io_snapshots_1_0_value) && (g_io_snapshots_1_0_value) !== (i_io_snapshots_1_0_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_0_value g=%h i=%h",$time,g_io_snapshots_1_0_value,i_io_snapshots_1_0_value); end checks++;
    if (!$isunknown(g_io_snapshots_2_0_flag) && (g_io_snapshots_2_0_flag) !== (i_io_snapshots_2_0_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_0_flag g=%h i=%h",$time,g_io_snapshots_2_0_flag,i_io_snapshots_2_0_flag); end checks++;
    if (!$isunknown(g_io_snapshots_2_0_value) && (g_io_snapshots_2_0_value) !== (i_io_snapshots_2_0_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_0_value g=%h i=%h",$time,g_io_snapshots_2_0_value,i_io_snapshots_2_0_value); end checks++;
    if (!$isunknown(g_io_snapshots_3_0_flag) && (g_io_snapshots_3_0_flag) !== (i_io_snapshots_3_0_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_0_flag g=%h i=%h",$time,g_io_snapshots_3_0_flag,i_io_snapshots_3_0_flag); end checks++;
    if (!$isunknown(g_io_snapshots_3_0_value) && (g_io_snapshots_3_0_value) !== (i_io_snapshots_3_0_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_0_value g=%h i=%h",$time,g_io_snapshots_3_0_value,i_io_snapshots_3_0_value); end checks++;
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
