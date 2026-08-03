// 自动生成: SnapshotGenerator_2 UT: golden vs 可读核 _xs 逐拍逐输出比对。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic reset;
  logic io_enq;
  logic io_enqData_illegal;
  logic io_enqData_vma;
  logic io_enqData_vta;
  logic [1:0] io_enqData_vsew;
  logic [2:0] io_enqData_vlmul;
  logic io_deq;
  logic io_redirect;
  logic io_flushVec_0;
  logic io_flushVec_1;
  logic io_flushVec_2;
  logic io_flushVec_3;

  logic g_io_snapshots_0_illegal;
  logic g_io_snapshots_0_vma;
  logic g_io_snapshots_0_vta;
  logic [1:0] g_io_snapshots_0_vsew;
  logic [2:0] g_io_snapshots_0_vlmul;
  logic g_io_snapshots_1_illegal;
  logic g_io_snapshots_1_vma;
  logic g_io_snapshots_1_vta;
  logic [1:0] g_io_snapshots_1_vsew;
  logic [2:0] g_io_snapshots_1_vlmul;
  logic g_io_snapshots_2_illegal;
  logic g_io_snapshots_2_vma;
  logic g_io_snapshots_2_vta;
  logic [1:0] g_io_snapshots_2_vsew;
  logic [2:0] g_io_snapshots_2_vlmul;
  logic g_io_snapshots_3_illegal;
  logic g_io_snapshots_3_vma;
  logic g_io_snapshots_3_vta;
  logic [1:0] g_io_snapshots_3_vsew;
  logic [2:0] g_io_snapshots_3_vlmul;

  logic i_io_snapshots_0_illegal;
  logic i_io_snapshots_0_vma;
  logic i_io_snapshots_0_vta;
  logic [1:0] i_io_snapshots_0_vsew;
  logic [2:0] i_io_snapshots_0_vlmul;
  logic i_io_snapshots_1_illegal;
  logic i_io_snapshots_1_vma;
  logic i_io_snapshots_1_vta;
  logic [1:0] i_io_snapshots_1_vsew;
  logic [2:0] i_io_snapshots_1_vlmul;
  logic i_io_snapshots_2_illegal;
  logic i_io_snapshots_2_vma;
  logic i_io_snapshots_2_vta;
  logic [1:0] i_io_snapshots_2_vsew;
  logic [2:0] i_io_snapshots_2_vlmul;
  logic i_io_snapshots_3_illegal;
  logic i_io_snapshots_3_vma;
  logic i_io_snapshots_3_vta;
  logic [1:0] i_io_snapshots_3_vsew;
  logic [2:0] i_io_snapshots_3_vlmul;

  SnapshotGenerator_2 u_g (
    .clock(clk),
    .reset(reset),
    .io_enq(io_enq),
    .io_enqData_illegal(io_enqData_illegal),
    .io_enqData_vma(io_enqData_vma),
    .io_enqData_vta(io_enqData_vta),
    .io_enqData_vsew(io_enqData_vsew),
    .io_enqData_vlmul(io_enqData_vlmul),
    .io_deq(io_deq),
    .io_redirect(io_redirect),
    .io_flushVec_0(io_flushVec_0),
    .io_flushVec_1(io_flushVec_1),
    .io_flushVec_2(io_flushVec_2),
    .io_flushVec_3(io_flushVec_3),
    .io_snapshots_0_illegal(g_io_snapshots_0_illegal),
    .io_snapshots_0_vma(g_io_snapshots_0_vma),
    .io_snapshots_0_vta(g_io_snapshots_0_vta),
    .io_snapshots_0_vsew(g_io_snapshots_0_vsew),
    .io_snapshots_0_vlmul(g_io_snapshots_0_vlmul),
    .io_snapshots_1_illegal(g_io_snapshots_1_illegal),
    .io_snapshots_1_vma(g_io_snapshots_1_vma),
    .io_snapshots_1_vta(g_io_snapshots_1_vta),
    .io_snapshots_1_vsew(g_io_snapshots_1_vsew),
    .io_snapshots_1_vlmul(g_io_snapshots_1_vlmul),
    .io_snapshots_2_illegal(g_io_snapshots_2_illegal),
    .io_snapshots_2_vma(g_io_snapshots_2_vma),
    .io_snapshots_2_vta(g_io_snapshots_2_vta),
    .io_snapshots_2_vsew(g_io_snapshots_2_vsew),
    .io_snapshots_2_vlmul(g_io_snapshots_2_vlmul),
    .io_snapshots_3_illegal(g_io_snapshots_3_illegal),
    .io_snapshots_3_vma(g_io_snapshots_3_vma),
    .io_snapshots_3_vta(g_io_snapshots_3_vta),
    .io_snapshots_3_vsew(g_io_snapshots_3_vsew),
    .io_snapshots_3_vlmul(g_io_snapshots_3_vlmul)
  );
  SnapshotGenerator_2_xs u_i (
    .clock(clk),
    .reset(reset),
    .io_enq(io_enq),
    .io_enqData_illegal(io_enqData_illegal),
    .io_enqData_vma(io_enqData_vma),
    .io_enqData_vta(io_enqData_vta),
    .io_enqData_vsew(io_enqData_vsew),
    .io_enqData_vlmul(io_enqData_vlmul),
    .io_deq(io_deq),
    .io_redirect(io_redirect),
    .io_flushVec_0(io_flushVec_0),
    .io_flushVec_1(io_flushVec_1),
    .io_flushVec_2(io_flushVec_2),
    .io_flushVec_3(io_flushVec_3),
    .io_snapshots_0_illegal(i_io_snapshots_0_illegal),
    .io_snapshots_0_vma(i_io_snapshots_0_vma),
    .io_snapshots_0_vta(i_io_snapshots_0_vta),
    .io_snapshots_0_vsew(i_io_snapshots_0_vsew),
    .io_snapshots_0_vlmul(i_io_snapshots_0_vlmul),
    .io_snapshots_1_illegal(i_io_snapshots_1_illegal),
    .io_snapshots_1_vma(i_io_snapshots_1_vma),
    .io_snapshots_1_vta(i_io_snapshots_1_vta),
    .io_snapshots_1_vsew(i_io_snapshots_1_vsew),
    .io_snapshots_1_vlmul(i_io_snapshots_1_vlmul),
    .io_snapshots_2_illegal(i_io_snapshots_2_illegal),
    .io_snapshots_2_vma(i_io_snapshots_2_vma),
    .io_snapshots_2_vta(i_io_snapshots_2_vta),
    .io_snapshots_2_vsew(i_io_snapshots_2_vsew),
    .io_snapshots_2_vlmul(i_io_snapshots_2_vlmul),
    .io_snapshots_3_illegal(i_io_snapshots_3_illegal),
    .io_snapshots_3_vma(i_io_snapshots_3_vma),
    .io_snapshots_3_vta(i_io_snapshots_3_vta),
    .io_snapshots_3_vsew(i_io_snapshots_3_vsew),
    .io_snapshots_3_vlmul(i_io_snapshots_3_vlmul)
  );

  task automatic drive_inputs();
    reset = ($urandom_range(0,99) < 3);
    io_enq = $urandom;
    io_enqData_illegal = $urandom;
    io_enqData_vma = $urandom;
    io_enqData_vta = $urandom;
    io_enqData_vsew = $urandom;
    io_enqData_vlmul = $urandom;
    io_deq = $urandom;
    io_redirect = $urandom;
    io_flushVec_0 = $urandom;
    io_flushVec_1 = $urandom;
    io_flushVec_2 = $urandom;
    io_flushVec_3 = $urandom;
  endtask
  task automatic check_outputs();
    if (!$isunknown(g_io_snapshots_0_illegal) && (g_io_snapshots_0_illegal) !== (i_io_snapshots_0_illegal)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_illegal g=%h i=%h",$time,g_io_snapshots_0_illegal,i_io_snapshots_0_illegal); end checks++;
    if (!$isunknown(g_io_snapshots_0_vma) && (g_io_snapshots_0_vma) !== (i_io_snapshots_0_vma)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_vma g=%h i=%h",$time,g_io_snapshots_0_vma,i_io_snapshots_0_vma); end checks++;
    if (!$isunknown(g_io_snapshots_0_vta) && (g_io_snapshots_0_vta) !== (i_io_snapshots_0_vta)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_vta g=%h i=%h",$time,g_io_snapshots_0_vta,i_io_snapshots_0_vta); end checks++;
    if (!$isunknown(g_io_snapshots_0_vsew) && (g_io_snapshots_0_vsew) !== (i_io_snapshots_0_vsew)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_vsew g=%h i=%h",$time,g_io_snapshots_0_vsew,i_io_snapshots_0_vsew); end checks++;
    if (!$isunknown(g_io_snapshots_0_vlmul) && (g_io_snapshots_0_vlmul) !== (i_io_snapshots_0_vlmul)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_vlmul g=%h i=%h",$time,g_io_snapshots_0_vlmul,i_io_snapshots_0_vlmul); end checks++;
    if (!$isunknown(g_io_snapshots_1_illegal) && (g_io_snapshots_1_illegal) !== (i_io_snapshots_1_illegal)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_illegal g=%h i=%h",$time,g_io_snapshots_1_illegal,i_io_snapshots_1_illegal); end checks++;
    if (!$isunknown(g_io_snapshots_1_vma) && (g_io_snapshots_1_vma) !== (i_io_snapshots_1_vma)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_vma g=%h i=%h",$time,g_io_snapshots_1_vma,i_io_snapshots_1_vma); end checks++;
    if (!$isunknown(g_io_snapshots_1_vta) && (g_io_snapshots_1_vta) !== (i_io_snapshots_1_vta)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_vta g=%h i=%h",$time,g_io_snapshots_1_vta,i_io_snapshots_1_vta); end checks++;
    if (!$isunknown(g_io_snapshots_1_vsew) && (g_io_snapshots_1_vsew) !== (i_io_snapshots_1_vsew)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_vsew g=%h i=%h",$time,g_io_snapshots_1_vsew,i_io_snapshots_1_vsew); end checks++;
    if (!$isunknown(g_io_snapshots_1_vlmul) && (g_io_snapshots_1_vlmul) !== (i_io_snapshots_1_vlmul)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_vlmul g=%h i=%h",$time,g_io_snapshots_1_vlmul,i_io_snapshots_1_vlmul); end checks++;
    if (!$isunknown(g_io_snapshots_2_illegal) && (g_io_snapshots_2_illegal) !== (i_io_snapshots_2_illegal)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_illegal g=%h i=%h",$time,g_io_snapshots_2_illegal,i_io_snapshots_2_illegal); end checks++;
    if (!$isunknown(g_io_snapshots_2_vma) && (g_io_snapshots_2_vma) !== (i_io_snapshots_2_vma)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_vma g=%h i=%h",$time,g_io_snapshots_2_vma,i_io_snapshots_2_vma); end checks++;
    if (!$isunknown(g_io_snapshots_2_vta) && (g_io_snapshots_2_vta) !== (i_io_snapshots_2_vta)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_vta g=%h i=%h",$time,g_io_snapshots_2_vta,i_io_snapshots_2_vta); end checks++;
    if (!$isunknown(g_io_snapshots_2_vsew) && (g_io_snapshots_2_vsew) !== (i_io_snapshots_2_vsew)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_vsew g=%h i=%h",$time,g_io_snapshots_2_vsew,i_io_snapshots_2_vsew); end checks++;
    if (!$isunknown(g_io_snapshots_2_vlmul) && (g_io_snapshots_2_vlmul) !== (i_io_snapshots_2_vlmul)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_vlmul g=%h i=%h",$time,g_io_snapshots_2_vlmul,i_io_snapshots_2_vlmul); end checks++;
    if (!$isunknown(g_io_snapshots_3_illegal) && (g_io_snapshots_3_illegal) !== (i_io_snapshots_3_illegal)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_illegal g=%h i=%h",$time,g_io_snapshots_3_illegal,i_io_snapshots_3_illegal); end checks++;
    if (!$isunknown(g_io_snapshots_3_vma) && (g_io_snapshots_3_vma) !== (i_io_snapshots_3_vma)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_vma g=%h i=%h",$time,g_io_snapshots_3_vma,i_io_snapshots_3_vma); end checks++;
    if (!$isunknown(g_io_snapshots_3_vta) && (g_io_snapshots_3_vta) !== (i_io_snapshots_3_vta)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_vta g=%h i=%h",$time,g_io_snapshots_3_vta,i_io_snapshots_3_vta); end checks++;
    if (!$isunknown(g_io_snapshots_3_vsew) && (g_io_snapshots_3_vsew) !== (i_io_snapshots_3_vsew)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_vsew g=%h i=%h",$time,g_io_snapshots_3_vsew,i_io_snapshots_3_vsew); end checks++;
    if (!$isunknown(g_io_snapshots_3_vlmul) && (g_io_snapshots_3_vlmul) !== (i_io_snapshots_3_vlmul)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_vlmul g=%h i=%h",$time,g_io_snapshots_3_vlmul,i_io_snapshots_3_vlmul); end checks++;
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
