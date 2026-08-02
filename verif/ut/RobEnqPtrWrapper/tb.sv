// 自动生成: RobEnqPtrWrapper UT: golden vs 可读核 _xs 逐拍逐输出比对。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic reset;
  logic io_redirect_valid;
  logic io_redirect_bits_robIdx_flag;
  logic [7:0] io_redirect_bits_robIdx_value;
  logic io_redirect_bits_level;
  logic io_allowEnqueue;
  logic io_hasBlockBackward;
  logic io_enq_0;
  logic io_enq_1;
  logic io_enq_2;
  logic io_enq_3;
  logic io_enq_4;
  logic io_enq_5;

  logic g_io_out_0_flag;
  logic [7:0] g_io_out_0_value;
  logic [7:0] g_io_out_1_value;
  logic [7:0] g_io_out_2_value;
  logic [7:0] g_io_out_3_value;
  logic [7:0] g_io_out_4_value;
  logic [7:0] g_io_out_5_value;

  logic i_io_out_0_flag;
  logic [7:0] i_io_out_0_value;
  logic [7:0] i_io_out_1_value;
  logic [7:0] i_io_out_2_value;
  logic [7:0] i_io_out_3_value;
  logic [7:0] i_io_out_4_value;
  logic [7:0] i_io_out_5_value;

  RobEnqPtrWrapper u_g (
    .clock(clk),
    .reset(reset),
    .io_redirect_valid(io_redirect_valid),
    .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(io_redirect_bits_level),
    .io_allowEnqueue(io_allowEnqueue),
    .io_hasBlockBackward(io_hasBlockBackward),
    .io_enq_0(io_enq_0),
    .io_enq_1(io_enq_1),
    .io_enq_2(io_enq_2),
    .io_enq_3(io_enq_3),
    .io_enq_4(io_enq_4),
    .io_enq_5(io_enq_5),
    .io_out_0_flag(g_io_out_0_flag),
    .io_out_0_value(g_io_out_0_value),
    .io_out_1_value(g_io_out_1_value),
    .io_out_2_value(g_io_out_2_value),
    .io_out_3_value(g_io_out_3_value),
    .io_out_4_value(g_io_out_4_value),
    .io_out_5_value(g_io_out_5_value)
  );

  RobEnqPtrWrapper_xs u_i (
    .clock(clk),
    .reset(reset),
    .io_redirect_valid(io_redirect_valid),
    .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(io_redirect_bits_level),
    .io_allowEnqueue(io_allowEnqueue),
    .io_hasBlockBackward(io_hasBlockBackward),
    .io_enq_0(io_enq_0),
    .io_enq_1(io_enq_1),
    .io_enq_2(io_enq_2),
    .io_enq_3(io_enq_3),
    .io_enq_4(io_enq_4),
    .io_enq_5(io_enq_5),
    .io_out_0_flag(i_io_out_0_flag),
    .io_out_0_value(i_io_out_0_value),
    .io_out_1_value(i_io_out_1_value),
    .io_out_2_value(i_io_out_2_value),
    .io_out_3_value(i_io_out_3_value),
    .io_out_4_value(i_io_out_4_value),
    .io_out_5_value(i_io_out_5_value)
  );

  task automatic drive_inputs();
    reset = ($urandom_range(0,99) < 3);
    io_redirect_valid = $urandom;
    io_redirect_bits_robIdx_flag = $urandom;
    // robIdx.value ∈ [0,160): 覆盖合法 RobPtr 取值(含近绕圈边界)。
    io_redirect_bits_robIdx_value = $urandom_range(0, 159);
    io_redirect_bits_level = $urandom;
    io_allowEnqueue = $urandom;
    io_hasBlockBackward = $urandom;
    io_enq_0 = $urandom;
    io_enq_1 = $urandom;
    io_enq_2 = $urandom;
    io_enq_3 = $urandom;
    io_enq_4 = $urandom;
    io_enq_5 = $urandom;
  endtask

  task automatic check_outputs();
    if (!$isunknown(g_io_out_0_flag)  && (g_io_out_0_flag)  !== (i_io_out_0_flag))  begin errors++; if (errors<=60) $display("[%0t] io_out_0_flag g=%h i=%h",$time,g_io_out_0_flag,i_io_out_0_flag); end checks++;
    if (!$isunknown(g_io_out_0_value) && (g_io_out_0_value) !== (i_io_out_0_value)) begin errors++; if (errors<=60) $display("[%0t] io_out_0_value g=%h i=%h",$time,g_io_out_0_value,i_io_out_0_value); end checks++;
    if (!$isunknown(g_io_out_1_value) && (g_io_out_1_value) !== (i_io_out_1_value)) begin errors++; if (errors<=60) $display("[%0t] io_out_1_value g=%h i=%h",$time,g_io_out_1_value,i_io_out_1_value); end checks++;
    if (!$isunknown(g_io_out_2_value) && (g_io_out_2_value) !== (i_io_out_2_value)) begin errors++; if (errors<=60) $display("[%0t] io_out_2_value g=%h i=%h",$time,g_io_out_2_value,i_io_out_2_value); end checks++;
    if (!$isunknown(g_io_out_3_value) && (g_io_out_3_value) !== (i_io_out_3_value)) begin errors++; if (errors<=60) $display("[%0t] io_out_3_value g=%h i=%h",$time,g_io_out_3_value,i_io_out_3_value); end checks++;
    if (!$isunknown(g_io_out_4_value) && (g_io_out_4_value) !== (i_io_out_4_value)) begin errors++; if (errors<=60) $display("[%0t] io_out_4_value g=%h i=%h",$time,g_io_out_4_value,i_io_out_4_value); end checks++;
    if (!$isunknown(g_io_out_5_value) && (g_io_out_5_value) !== (i_io_out_5_value)) begin errors++; if (errors<=60) $display("[%0t] io_out_5_value g=%h i=%h",$time,g_io_out_5_value,i_io_out_5_value); end checks++;
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
