// 自动生成: SnapshotGenerator_14 UT: golden vs 可读核 _xs 逐拍逐输出比对。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic reset;
  logic io_enq;
  logic io_enqData_robIdx_0_flag;
  logic [7:0] io_enqData_robIdx_0_value;
  logic io_enqData_robIdx_1_flag;
  logic [7:0] io_enqData_robIdx_1_value;
  logic io_enqData_robIdx_2_flag;
  logic [7:0] io_enqData_robIdx_2_value;
  logic io_enqData_robIdx_3_flag;
  logic [7:0] io_enqData_robIdx_3_value;
  logic io_enqData_robIdx_4_flag;
  logic [7:0] io_enqData_robIdx_4_value;
  logic io_enqData_robIdx_5_flag;
  logic [7:0] io_enqData_robIdx_5_value;
  logic io_enqData_isCFI_0;
  logic io_enqData_isCFI_1;
  logic io_enqData_isCFI_2;
  logic io_enqData_isCFI_3;
  logic io_enqData_isCFI_4;
  logic io_enqData_isCFI_5;
  logic io_deq;
  logic io_redirect;
  logic io_flushVec_0;
  logic io_flushVec_1;
  logic io_flushVec_2;
  logic io_flushVec_3;
  logic g_io_snapshots_0_robIdx_0_flag;
  logic [7:0] g_io_snapshots_0_robIdx_0_value;
  logic g_io_snapshots_0_robIdx_1_flag;
  logic [7:0] g_io_snapshots_0_robIdx_1_value;
  logic g_io_snapshots_0_robIdx_2_flag;
  logic [7:0] g_io_snapshots_0_robIdx_2_value;
  logic g_io_snapshots_0_robIdx_3_flag;
  logic [7:0] g_io_snapshots_0_robIdx_3_value;
  logic g_io_snapshots_0_robIdx_4_flag;
  logic [7:0] g_io_snapshots_0_robIdx_4_value;
  logic g_io_snapshots_0_robIdx_5_flag;
  logic [7:0] g_io_snapshots_0_robIdx_5_value;
  logic g_io_snapshots_0_isCFI_0;
  logic g_io_snapshots_0_isCFI_1;
  logic g_io_snapshots_0_isCFI_2;
  logic g_io_snapshots_0_isCFI_3;
  logic g_io_snapshots_0_isCFI_4;
  logic g_io_snapshots_0_isCFI_5;
  logic g_io_snapshots_1_robIdx_0_flag;
  logic [7:0] g_io_snapshots_1_robIdx_0_value;
  logic g_io_snapshots_1_robIdx_1_flag;
  logic [7:0] g_io_snapshots_1_robIdx_1_value;
  logic g_io_snapshots_1_robIdx_2_flag;
  logic [7:0] g_io_snapshots_1_robIdx_2_value;
  logic g_io_snapshots_1_robIdx_3_flag;
  logic [7:0] g_io_snapshots_1_robIdx_3_value;
  logic g_io_snapshots_1_robIdx_4_flag;
  logic [7:0] g_io_snapshots_1_robIdx_4_value;
  logic g_io_snapshots_1_robIdx_5_flag;
  logic [7:0] g_io_snapshots_1_robIdx_5_value;
  logic g_io_snapshots_1_isCFI_0;
  logic g_io_snapshots_1_isCFI_1;
  logic g_io_snapshots_1_isCFI_2;
  logic g_io_snapshots_1_isCFI_3;
  logic g_io_snapshots_1_isCFI_4;
  logic g_io_snapshots_1_isCFI_5;
  logic g_io_snapshots_2_robIdx_0_flag;
  logic [7:0] g_io_snapshots_2_robIdx_0_value;
  logic g_io_snapshots_2_robIdx_1_flag;
  logic [7:0] g_io_snapshots_2_robIdx_1_value;
  logic g_io_snapshots_2_robIdx_2_flag;
  logic [7:0] g_io_snapshots_2_robIdx_2_value;
  logic g_io_snapshots_2_robIdx_3_flag;
  logic [7:0] g_io_snapshots_2_robIdx_3_value;
  logic g_io_snapshots_2_robIdx_4_flag;
  logic [7:0] g_io_snapshots_2_robIdx_4_value;
  logic g_io_snapshots_2_robIdx_5_flag;
  logic [7:0] g_io_snapshots_2_robIdx_5_value;
  logic g_io_snapshots_2_isCFI_0;
  logic g_io_snapshots_2_isCFI_1;
  logic g_io_snapshots_2_isCFI_2;
  logic g_io_snapshots_2_isCFI_3;
  logic g_io_snapshots_2_isCFI_4;
  logic g_io_snapshots_2_isCFI_5;
  logic g_io_snapshots_3_robIdx_0_flag;
  logic [7:0] g_io_snapshots_3_robIdx_0_value;
  logic g_io_snapshots_3_robIdx_1_flag;
  logic [7:0] g_io_snapshots_3_robIdx_1_value;
  logic g_io_snapshots_3_robIdx_2_flag;
  logic [7:0] g_io_snapshots_3_robIdx_2_value;
  logic g_io_snapshots_3_robIdx_3_flag;
  logic [7:0] g_io_snapshots_3_robIdx_3_value;
  logic g_io_snapshots_3_robIdx_4_flag;
  logic [7:0] g_io_snapshots_3_robIdx_4_value;
  logic g_io_snapshots_3_robIdx_5_flag;
  logic [7:0] g_io_snapshots_3_robIdx_5_value;
  logic g_io_snapshots_3_isCFI_0;
  logic g_io_snapshots_3_isCFI_1;
  logic g_io_snapshots_3_isCFI_2;
  logic g_io_snapshots_3_isCFI_3;
  logic g_io_snapshots_3_isCFI_4;
  logic g_io_snapshots_3_isCFI_5;
  logic g_io_enqPtr_flag;
  logic [1:0] g_io_enqPtr_value;
  logic g_io_deqPtr_flag;
  logic [1:0] g_io_deqPtr_value;
  logic g_io_valids_0;
  logic g_io_valids_1;
  logic g_io_valids_2;
  logic g_io_valids_3;
  logic i_io_snapshots_0_robIdx_0_flag;
  logic [7:0] i_io_snapshots_0_robIdx_0_value;
  logic i_io_snapshots_0_robIdx_1_flag;
  logic [7:0] i_io_snapshots_0_robIdx_1_value;
  logic i_io_snapshots_0_robIdx_2_flag;
  logic [7:0] i_io_snapshots_0_robIdx_2_value;
  logic i_io_snapshots_0_robIdx_3_flag;
  logic [7:0] i_io_snapshots_0_robIdx_3_value;
  logic i_io_snapshots_0_robIdx_4_flag;
  logic [7:0] i_io_snapshots_0_robIdx_4_value;
  logic i_io_snapshots_0_robIdx_5_flag;
  logic [7:0] i_io_snapshots_0_robIdx_5_value;
  logic i_io_snapshots_0_isCFI_0;
  logic i_io_snapshots_0_isCFI_1;
  logic i_io_snapshots_0_isCFI_2;
  logic i_io_snapshots_0_isCFI_3;
  logic i_io_snapshots_0_isCFI_4;
  logic i_io_snapshots_0_isCFI_5;
  logic i_io_snapshots_1_robIdx_0_flag;
  logic [7:0] i_io_snapshots_1_robIdx_0_value;
  logic i_io_snapshots_1_robIdx_1_flag;
  logic [7:0] i_io_snapshots_1_robIdx_1_value;
  logic i_io_snapshots_1_robIdx_2_flag;
  logic [7:0] i_io_snapshots_1_robIdx_2_value;
  logic i_io_snapshots_1_robIdx_3_flag;
  logic [7:0] i_io_snapshots_1_robIdx_3_value;
  logic i_io_snapshots_1_robIdx_4_flag;
  logic [7:0] i_io_snapshots_1_robIdx_4_value;
  logic i_io_snapshots_1_robIdx_5_flag;
  logic [7:0] i_io_snapshots_1_robIdx_5_value;
  logic i_io_snapshots_1_isCFI_0;
  logic i_io_snapshots_1_isCFI_1;
  logic i_io_snapshots_1_isCFI_2;
  logic i_io_snapshots_1_isCFI_3;
  logic i_io_snapshots_1_isCFI_4;
  logic i_io_snapshots_1_isCFI_5;
  logic i_io_snapshots_2_robIdx_0_flag;
  logic [7:0] i_io_snapshots_2_robIdx_0_value;
  logic i_io_snapshots_2_robIdx_1_flag;
  logic [7:0] i_io_snapshots_2_robIdx_1_value;
  logic i_io_snapshots_2_robIdx_2_flag;
  logic [7:0] i_io_snapshots_2_robIdx_2_value;
  logic i_io_snapshots_2_robIdx_3_flag;
  logic [7:0] i_io_snapshots_2_robIdx_3_value;
  logic i_io_snapshots_2_robIdx_4_flag;
  logic [7:0] i_io_snapshots_2_robIdx_4_value;
  logic i_io_snapshots_2_robIdx_5_flag;
  logic [7:0] i_io_snapshots_2_robIdx_5_value;
  logic i_io_snapshots_2_isCFI_0;
  logic i_io_snapshots_2_isCFI_1;
  logic i_io_snapshots_2_isCFI_2;
  logic i_io_snapshots_2_isCFI_3;
  logic i_io_snapshots_2_isCFI_4;
  logic i_io_snapshots_2_isCFI_5;
  logic i_io_snapshots_3_robIdx_0_flag;
  logic [7:0] i_io_snapshots_3_robIdx_0_value;
  logic i_io_snapshots_3_robIdx_1_flag;
  logic [7:0] i_io_snapshots_3_robIdx_1_value;
  logic i_io_snapshots_3_robIdx_2_flag;
  logic [7:0] i_io_snapshots_3_robIdx_2_value;
  logic i_io_snapshots_3_robIdx_3_flag;
  logic [7:0] i_io_snapshots_3_robIdx_3_value;
  logic i_io_snapshots_3_robIdx_4_flag;
  logic [7:0] i_io_snapshots_3_robIdx_4_value;
  logic i_io_snapshots_3_robIdx_5_flag;
  logic [7:0] i_io_snapshots_3_robIdx_5_value;
  logic i_io_snapshots_3_isCFI_0;
  logic i_io_snapshots_3_isCFI_1;
  logic i_io_snapshots_3_isCFI_2;
  logic i_io_snapshots_3_isCFI_3;
  logic i_io_snapshots_3_isCFI_4;
  logic i_io_snapshots_3_isCFI_5;
  logic i_io_enqPtr_flag;
  logic [1:0] i_io_enqPtr_value;
  logic i_io_deqPtr_flag;
  logic [1:0] i_io_deqPtr_value;
  logic i_io_valids_0;
  logic i_io_valids_1;
  logic i_io_valids_2;
  logic i_io_valids_3;

  SnapshotGenerator_14 u_g (
    .clock(clk),
    .reset(reset),
    .io_enq(io_enq),
    .io_enqData_robIdx_0_flag(io_enqData_robIdx_0_flag),
    .io_enqData_robIdx_0_value(io_enqData_robIdx_0_value),
    .io_enqData_robIdx_1_flag(io_enqData_robIdx_1_flag),
    .io_enqData_robIdx_1_value(io_enqData_robIdx_1_value),
    .io_enqData_robIdx_2_flag(io_enqData_robIdx_2_flag),
    .io_enqData_robIdx_2_value(io_enqData_robIdx_2_value),
    .io_enqData_robIdx_3_flag(io_enqData_robIdx_3_flag),
    .io_enqData_robIdx_3_value(io_enqData_robIdx_3_value),
    .io_enqData_robIdx_4_flag(io_enqData_robIdx_4_flag),
    .io_enqData_robIdx_4_value(io_enqData_robIdx_4_value),
    .io_enqData_robIdx_5_flag(io_enqData_robIdx_5_flag),
    .io_enqData_robIdx_5_value(io_enqData_robIdx_5_value),
    .io_enqData_isCFI_0(io_enqData_isCFI_0),
    .io_enqData_isCFI_1(io_enqData_isCFI_1),
    .io_enqData_isCFI_2(io_enqData_isCFI_2),
    .io_enqData_isCFI_3(io_enqData_isCFI_3),
    .io_enqData_isCFI_4(io_enqData_isCFI_4),
    .io_enqData_isCFI_5(io_enqData_isCFI_5),
    .io_deq(io_deq),
    .io_redirect(io_redirect),
    .io_flushVec_0(io_flushVec_0),
    .io_flushVec_1(io_flushVec_1),
    .io_flushVec_2(io_flushVec_2),
    .io_flushVec_3(io_flushVec_3),
    .io_snapshots_0_robIdx_0_flag(g_io_snapshots_0_robIdx_0_flag),
    .io_snapshots_0_robIdx_0_value(g_io_snapshots_0_robIdx_0_value),
    .io_snapshots_0_robIdx_1_flag(g_io_snapshots_0_robIdx_1_flag),
    .io_snapshots_0_robIdx_1_value(g_io_snapshots_0_robIdx_1_value),
    .io_snapshots_0_robIdx_2_flag(g_io_snapshots_0_robIdx_2_flag),
    .io_snapshots_0_robIdx_2_value(g_io_snapshots_0_robIdx_2_value),
    .io_snapshots_0_robIdx_3_flag(g_io_snapshots_0_robIdx_3_flag),
    .io_snapshots_0_robIdx_3_value(g_io_snapshots_0_robIdx_3_value),
    .io_snapshots_0_robIdx_4_flag(g_io_snapshots_0_robIdx_4_flag),
    .io_snapshots_0_robIdx_4_value(g_io_snapshots_0_robIdx_4_value),
    .io_snapshots_0_robIdx_5_flag(g_io_snapshots_0_robIdx_5_flag),
    .io_snapshots_0_robIdx_5_value(g_io_snapshots_0_robIdx_5_value),
    .io_snapshots_0_isCFI_0(g_io_snapshots_0_isCFI_0),
    .io_snapshots_0_isCFI_1(g_io_snapshots_0_isCFI_1),
    .io_snapshots_0_isCFI_2(g_io_snapshots_0_isCFI_2),
    .io_snapshots_0_isCFI_3(g_io_snapshots_0_isCFI_3),
    .io_snapshots_0_isCFI_4(g_io_snapshots_0_isCFI_4),
    .io_snapshots_0_isCFI_5(g_io_snapshots_0_isCFI_5),
    .io_snapshots_1_robIdx_0_flag(g_io_snapshots_1_robIdx_0_flag),
    .io_snapshots_1_robIdx_0_value(g_io_snapshots_1_robIdx_0_value),
    .io_snapshots_1_robIdx_1_flag(g_io_snapshots_1_robIdx_1_flag),
    .io_snapshots_1_robIdx_1_value(g_io_snapshots_1_robIdx_1_value),
    .io_snapshots_1_robIdx_2_flag(g_io_snapshots_1_robIdx_2_flag),
    .io_snapshots_1_robIdx_2_value(g_io_snapshots_1_robIdx_2_value),
    .io_snapshots_1_robIdx_3_flag(g_io_snapshots_1_robIdx_3_flag),
    .io_snapshots_1_robIdx_3_value(g_io_snapshots_1_robIdx_3_value),
    .io_snapshots_1_robIdx_4_flag(g_io_snapshots_1_robIdx_4_flag),
    .io_snapshots_1_robIdx_4_value(g_io_snapshots_1_robIdx_4_value),
    .io_snapshots_1_robIdx_5_flag(g_io_snapshots_1_robIdx_5_flag),
    .io_snapshots_1_robIdx_5_value(g_io_snapshots_1_robIdx_5_value),
    .io_snapshots_1_isCFI_0(g_io_snapshots_1_isCFI_0),
    .io_snapshots_1_isCFI_1(g_io_snapshots_1_isCFI_1),
    .io_snapshots_1_isCFI_2(g_io_snapshots_1_isCFI_2),
    .io_snapshots_1_isCFI_3(g_io_snapshots_1_isCFI_3),
    .io_snapshots_1_isCFI_4(g_io_snapshots_1_isCFI_4),
    .io_snapshots_1_isCFI_5(g_io_snapshots_1_isCFI_5),
    .io_snapshots_2_robIdx_0_flag(g_io_snapshots_2_robIdx_0_flag),
    .io_snapshots_2_robIdx_0_value(g_io_snapshots_2_robIdx_0_value),
    .io_snapshots_2_robIdx_1_flag(g_io_snapshots_2_robIdx_1_flag),
    .io_snapshots_2_robIdx_1_value(g_io_snapshots_2_robIdx_1_value),
    .io_snapshots_2_robIdx_2_flag(g_io_snapshots_2_robIdx_2_flag),
    .io_snapshots_2_robIdx_2_value(g_io_snapshots_2_robIdx_2_value),
    .io_snapshots_2_robIdx_3_flag(g_io_snapshots_2_robIdx_3_flag),
    .io_snapshots_2_robIdx_3_value(g_io_snapshots_2_robIdx_3_value),
    .io_snapshots_2_robIdx_4_flag(g_io_snapshots_2_robIdx_4_flag),
    .io_snapshots_2_robIdx_4_value(g_io_snapshots_2_robIdx_4_value),
    .io_snapshots_2_robIdx_5_flag(g_io_snapshots_2_robIdx_5_flag),
    .io_snapshots_2_robIdx_5_value(g_io_snapshots_2_robIdx_5_value),
    .io_snapshots_2_isCFI_0(g_io_snapshots_2_isCFI_0),
    .io_snapshots_2_isCFI_1(g_io_snapshots_2_isCFI_1),
    .io_snapshots_2_isCFI_2(g_io_snapshots_2_isCFI_2),
    .io_snapshots_2_isCFI_3(g_io_snapshots_2_isCFI_3),
    .io_snapshots_2_isCFI_4(g_io_snapshots_2_isCFI_4),
    .io_snapshots_2_isCFI_5(g_io_snapshots_2_isCFI_5),
    .io_snapshots_3_robIdx_0_flag(g_io_snapshots_3_robIdx_0_flag),
    .io_snapshots_3_robIdx_0_value(g_io_snapshots_3_robIdx_0_value),
    .io_snapshots_3_robIdx_1_flag(g_io_snapshots_3_robIdx_1_flag),
    .io_snapshots_3_robIdx_1_value(g_io_snapshots_3_robIdx_1_value),
    .io_snapshots_3_robIdx_2_flag(g_io_snapshots_3_robIdx_2_flag),
    .io_snapshots_3_robIdx_2_value(g_io_snapshots_3_robIdx_2_value),
    .io_snapshots_3_robIdx_3_flag(g_io_snapshots_3_robIdx_3_flag),
    .io_snapshots_3_robIdx_3_value(g_io_snapshots_3_robIdx_3_value),
    .io_snapshots_3_robIdx_4_flag(g_io_snapshots_3_robIdx_4_flag),
    .io_snapshots_3_robIdx_4_value(g_io_snapshots_3_robIdx_4_value),
    .io_snapshots_3_robIdx_5_flag(g_io_snapshots_3_robIdx_5_flag),
    .io_snapshots_3_robIdx_5_value(g_io_snapshots_3_robIdx_5_value),
    .io_snapshots_3_isCFI_0(g_io_snapshots_3_isCFI_0),
    .io_snapshots_3_isCFI_1(g_io_snapshots_3_isCFI_1),
    .io_snapshots_3_isCFI_2(g_io_snapshots_3_isCFI_2),
    .io_snapshots_3_isCFI_3(g_io_snapshots_3_isCFI_3),
    .io_snapshots_3_isCFI_4(g_io_snapshots_3_isCFI_4),
    .io_snapshots_3_isCFI_5(g_io_snapshots_3_isCFI_5),
    .io_enqPtr_flag(g_io_enqPtr_flag),
    .io_enqPtr_value(g_io_enqPtr_value),
    .io_deqPtr_flag(g_io_deqPtr_flag),
    .io_deqPtr_value(g_io_deqPtr_value),
    .io_valids_0(g_io_valids_0),
    .io_valids_1(g_io_valids_1),
    .io_valids_2(g_io_valids_2),
    .io_valids_3(g_io_valids_3)
  );
  SnapshotGenerator_14_xs u_i (
    .clock(clk),
    .reset(reset),
    .io_enq(io_enq),
    .io_enqData_robIdx_0_flag(io_enqData_robIdx_0_flag),
    .io_enqData_robIdx_0_value(io_enqData_robIdx_0_value),
    .io_enqData_robIdx_1_flag(io_enqData_robIdx_1_flag),
    .io_enqData_robIdx_1_value(io_enqData_robIdx_1_value),
    .io_enqData_robIdx_2_flag(io_enqData_robIdx_2_flag),
    .io_enqData_robIdx_2_value(io_enqData_robIdx_2_value),
    .io_enqData_robIdx_3_flag(io_enqData_robIdx_3_flag),
    .io_enqData_robIdx_3_value(io_enqData_robIdx_3_value),
    .io_enqData_robIdx_4_flag(io_enqData_robIdx_4_flag),
    .io_enqData_robIdx_4_value(io_enqData_robIdx_4_value),
    .io_enqData_robIdx_5_flag(io_enqData_robIdx_5_flag),
    .io_enqData_robIdx_5_value(io_enqData_robIdx_5_value),
    .io_enqData_isCFI_0(io_enqData_isCFI_0),
    .io_enqData_isCFI_1(io_enqData_isCFI_1),
    .io_enqData_isCFI_2(io_enqData_isCFI_2),
    .io_enqData_isCFI_3(io_enqData_isCFI_3),
    .io_enqData_isCFI_4(io_enqData_isCFI_4),
    .io_enqData_isCFI_5(io_enqData_isCFI_5),
    .io_deq(io_deq),
    .io_redirect(io_redirect),
    .io_flushVec_0(io_flushVec_0),
    .io_flushVec_1(io_flushVec_1),
    .io_flushVec_2(io_flushVec_2),
    .io_flushVec_3(io_flushVec_3),
    .io_snapshots_0_robIdx_0_flag(i_io_snapshots_0_robIdx_0_flag),
    .io_snapshots_0_robIdx_0_value(i_io_snapshots_0_robIdx_0_value),
    .io_snapshots_0_robIdx_1_flag(i_io_snapshots_0_robIdx_1_flag),
    .io_snapshots_0_robIdx_1_value(i_io_snapshots_0_robIdx_1_value),
    .io_snapshots_0_robIdx_2_flag(i_io_snapshots_0_robIdx_2_flag),
    .io_snapshots_0_robIdx_2_value(i_io_snapshots_0_robIdx_2_value),
    .io_snapshots_0_robIdx_3_flag(i_io_snapshots_0_robIdx_3_flag),
    .io_snapshots_0_robIdx_3_value(i_io_snapshots_0_robIdx_3_value),
    .io_snapshots_0_robIdx_4_flag(i_io_snapshots_0_robIdx_4_flag),
    .io_snapshots_0_robIdx_4_value(i_io_snapshots_0_robIdx_4_value),
    .io_snapshots_0_robIdx_5_flag(i_io_snapshots_0_robIdx_5_flag),
    .io_snapshots_0_robIdx_5_value(i_io_snapshots_0_robIdx_5_value),
    .io_snapshots_0_isCFI_0(i_io_snapshots_0_isCFI_0),
    .io_snapshots_0_isCFI_1(i_io_snapshots_0_isCFI_1),
    .io_snapshots_0_isCFI_2(i_io_snapshots_0_isCFI_2),
    .io_snapshots_0_isCFI_3(i_io_snapshots_0_isCFI_3),
    .io_snapshots_0_isCFI_4(i_io_snapshots_0_isCFI_4),
    .io_snapshots_0_isCFI_5(i_io_snapshots_0_isCFI_5),
    .io_snapshots_1_robIdx_0_flag(i_io_snapshots_1_robIdx_0_flag),
    .io_snapshots_1_robIdx_0_value(i_io_snapshots_1_robIdx_0_value),
    .io_snapshots_1_robIdx_1_flag(i_io_snapshots_1_robIdx_1_flag),
    .io_snapshots_1_robIdx_1_value(i_io_snapshots_1_robIdx_1_value),
    .io_snapshots_1_robIdx_2_flag(i_io_snapshots_1_robIdx_2_flag),
    .io_snapshots_1_robIdx_2_value(i_io_snapshots_1_robIdx_2_value),
    .io_snapshots_1_robIdx_3_flag(i_io_snapshots_1_robIdx_3_flag),
    .io_snapshots_1_robIdx_3_value(i_io_snapshots_1_robIdx_3_value),
    .io_snapshots_1_robIdx_4_flag(i_io_snapshots_1_robIdx_4_flag),
    .io_snapshots_1_robIdx_4_value(i_io_snapshots_1_robIdx_4_value),
    .io_snapshots_1_robIdx_5_flag(i_io_snapshots_1_robIdx_5_flag),
    .io_snapshots_1_robIdx_5_value(i_io_snapshots_1_robIdx_5_value),
    .io_snapshots_1_isCFI_0(i_io_snapshots_1_isCFI_0),
    .io_snapshots_1_isCFI_1(i_io_snapshots_1_isCFI_1),
    .io_snapshots_1_isCFI_2(i_io_snapshots_1_isCFI_2),
    .io_snapshots_1_isCFI_3(i_io_snapshots_1_isCFI_3),
    .io_snapshots_1_isCFI_4(i_io_snapshots_1_isCFI_4),
    .io_snapshots_1_isCFI_5(i_io_snapshots_1_isCFI_5),
    .io_snapshots_2_robIdx_0_flag(i_io_snapshots_2_robIdx_0_flag),
    .io_snapshots_2_robIdx_0_value(i_io_snapshots_2_robIdx_0_value),
    .io_snapshots_2_robIdx_1_flag(i_io_snapshots_2_robIdx_1_flag),
    .io_snapshots_2_robIdx_1_value(i_io_snapshots_2_robIdx_1_value),
    .io_snapshots_2_robIdx_2_flag(i_io_snapshots_2_robIdx_2_flag),
    .io_snapshots_2_robIdx_2_value(i_io_snapshots_2_robIdx_2_value),
    .io_snapshots_2_robIdx_3_flag(i_io_snapshots_2_robIdx_3_flag),
    .io_snapshots_2_robIdx_3_value(i_io_snapshots_2_robIdx_3_value),
    .io_snapshots_2_robIdx_4_flag(i_io_snapshots_2_robIdx_4_flag),
    .io_snapshots_2_robIdx_4_value(i_io_snapshots_2_robIdx_4_value),
    .io_snapshots_2_robIdx_5_flag(i_io_snapshots_2_robIdx_5_flag),
    .io_snapshots_2_robIdx_5_value(i_io_snapshots_2_robIdx_5_value),
    .io_snapshots_2_isCFI_0(i_io_snapshots_2_isCFI_0),
    .io_snapshots_2_isCFI_1(i_io_snapshots_2_isCFI_1),
    .io_snapshots_2_isCFI_2(i_io_snapshots_2_isCFI_2),
    .io_snapshots_2_isCFI_3(i_io_snapshots_2_isCFI_3),
    .io_snapshots_2_isCFI_4(i_io_snapshots_2_isCFI_4),
    .io_snapshots_2_isCFI_5(i_io_snapshots_2_isCFI_5),
    .io_snapshots_3_robIdx_0_flag(i_io_snapshots_3_robIdx_0_flag),
    .io_snapshots_3_robIdx_0_value(i_io_snapshots_3_robIdx_0_value),
    .io_snapshots_3_robIdx_1_flag(i_io_snapshots_3_robIdx_1_flag),
    .io_snapshots_3_robIdx_1_value(i_io_snapshots_3_robIdx_1_value),
    .io_snapshots_3_robIdx_2_flag(i_io_snapshots_3_robIdx_2_flag),
    .io_snapshots_3_robIdx_2_value(i_io_snapshots_3_robIdx_2_value),
    .io_snapshots_3_robIdx_3_flag(i_io_snapshots_3_robIdx_3_flag),
    .io_snapshots_3_robIdx_3_value(i_io_snapshots_3_robIdx_3_value),
    .io_snapshots_3_robIdx_4_flag(i_io_snapshots_3_robIdx_4_flag),
    .io_snapshots_3_robIdx_4_value(i_io_snapshots_3_robIdx_4_value),
    .io_snapshots_3_robIdx_5_flag(i_io_snapshots_3_robIdx_5_flag),
    .io_snapshots_3_robIdx_5_value(i_io_snapshots_3_robIdx_5_value),
    .io_snapshots_3_isCFI_0(i_io_snapshots_3_isCFI_0),
    .io_snapshots_3_isCFI_1(i_io_snapshots_3_isCFI_1),
    .io_snapshots_3_isCFI_2(i_io_snapshots_3_isCFI_2),
    .io_snapshots_3_isCFI_3(i_io_snapshots_3_isCFI_3),
    .io_snapshots_3_isCFI_4(i_io_snapshots_3_isCFI_4),
    .io_snapshots_3_isCFI_5(i_io_snapshots_3_isCFI_5),
    .io_enqPtr_flag(i_io_enqPtr_flag),
    .io_enqPtr_value(i_io_enqPtr_value),
    .io_deqPtr_flag(i_io_deqPtr_flag),
    .io_deqPtr_value(i_io_deqPtr_value),
    .io_valids_0(i_io_valids_0),
    .io_valids_1(i_io_valids_1),
    .io_valids_2(i_io_valids_2),
    .io_valids_3(i_io_valids_3)
  );

  task automatic drive_inputs();
    reset = ($urandom_range(0,99) < 3);
    io_enq = $urandom;
    io_enqData_robIdx_0_flag = $urandom;
    io_enqData_robIdx_0_value = $urandom;
    io_enqData_robIdx_1_flag = $urandom;
    io_enqData_robIdx_1_value = $urandom;
    io_enqData_robIdx_2_flag = $urandom;
    io_enqData_robIdx_2_value = $urandom;
    io_enqData_robIdx_3_flag = $urandom;
    io_enqData_robIdx_3_value = $urandom;
    io_enqData_robIdx_4_flag = $urandom;
    io_enqData_robIdx_4_value = $urandom;
    io_enqData_robIdx_5_flag = $urandom;
    io_enqData_robIdx_5_value = $urandom;
    io_enqData_isCFI_0 = $urandom;
    io_enqData_isCFI_1 = $urandom;
    io_enqData_isCFI_2 = $urandom;
    io_enqData_isCFI_3 = $urandom;
    io_enqData_isCFI_4 = $urandom;
    io_enqData_isCFI_5 = $urandom;
    io_deq = $urandom;
    io_redirect = $urandom;
    io_flushVec_0 = $urandom;
    io_flushVec_1 = $urandom;
    io_flushVec_2 = $urandom;
    io_flushVec_3 = $urandom;
  endtask
  task automatic check_outputs();
    if (!$isunknown(g_io_snapshots_0_robIdx_0_flag) && (g_io_snapshots_0_robIdx_0_flag) !== (i_io_snapshots_0_robIdx_0_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_robIdx_0_flag g=%h i=%h",$time,g_io_snapshots_0_robIdx_0_flag,i_io_snapshots_0_robIdx_0_flag); end checks++;
    if (!$isunknown(g_io_snapshots_0_robIdx_0_value) && (g_io_snapshots_0_robIdx_0_value) !== (i_io_snapshots_0_robIdx_0_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_robIdx_0_value g=%h i=%h",$time,g_io_snapshots_0_robIdx_0_value,i_io_snapshots_0_robIdx_0_value); end checks++;
    if (!$isunknown(g_io_snapshots_0_robIdx_1_flag) && (g_io_snapshots_0_robIdx_1_flag) !== (i_io_snapshots_0_robIdx_1_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_robIdx_1_flag g=%h i=%h",$time,g_io_snapshots_0_robIdx_1_flag,i_io_snapshots_0_robIdx_1_flag); end checks++;
    if (!$isunknown(g_io_snapshots_0_robIdx_1_value) && (g_io_snapshots_0_robIdx_1_value) !== (i_io_snapshots_0_robIdx_1_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_robIdx_1_value g=%h i=%h",$time,g_io_snapshots_0_robIdx_1_value,i_io_snapshots_0_robIdx_1_value); end checks++;
    if (!$isunknown(g_io_snapshots_0_robIdx_2_flag) && (g_io_snapshots_0_robIdx_2_flag) !== (i_io_snapshots_0_robIdx_2_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_robIdx_2_flag g=%h i=%h",$time,g_io_snapshots_0_robIdx_2_flag,i_io_snapshots_0_robIdx_2_flag); end checks++;
    if (!$isunknown(g_io_snapshots_0_robIdx_2_value) && (g_io_snapshots_0_robIdx_2_value) !== (i_io_snapshots_0_robIdx_2_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_robIdx_2_value g=%h i=%h",$time,g_io_snapshots_0_robIdx_2_value,i_io_snapshots_0_robIdx_2_value); end checks++;
    if (!$isunknown(g_io_snapshots_0_robIdx_3_flag) && (g_io_snapshots_0_robIdx_3_flag) !== (i_io_snapshots_0_robIdx_3_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_robIdx_3_flag g=%h i=%h",$time,g_io_snapshots_0_robIdx_3_flag,i_io_snapshots_0_robIdx_3_flag); end checks++;
    if (!$isunknown(g_io_snapshots_0_robIdx_3_value) && (g_io_snapshots_0_robIdx_3_value) !== (i_io_snapshots_0_robIdx_3_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_robIdx_3_value g=%h i=%h",$time,g_io_snapshots_0_robIdx_3_value,i_io_snapshots_0_robIdx_3_value); end checks++;
    if (!$isunknown(g_io_snapshots_0_robIdx_4_flag) && (g_io_snapshots_0_robIdx_4_flag) !== (i_io_snapshots_0_robIdx_4_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_robIdx_4_flag g=%h i=%h",$time,g_io_snapshots_0_robIdx_4_flag,i_io_snapshots_0_robIdx_4_flag); end checks++;
    if (!$isunknown(g_io_snapshots_0_robIdx_4_value) && (g_io_snapshots_0_robIdx_4_value) !== (i_io_snapshots_0_robIdx_4_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_robIdx_4_value g=%h i=%h",$time,g_io_snapshots_0_robIdx_4_value,i_io_snapshots_0_robIdx_4_value); end checks++;
    if (!$isunknown(g_io_snapshots_0_robIdx_5_flag) && (g_io_snapshots_0_robIdx_5_flag) !== (i_io_snapshots_0_robIdx_5_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_robIdx_5_flag g=%h i=%h",$time,g_io_snapshots_0_robIdx_5_flag,i_io_snapshots_0_robIdx_5_flag); end checks++;
    if (!$isunknown(g_io_snapshots_0_robIdx_5_value) && (g_io_snapshots_0_robIdx_5_value) !== (i_io_snapshots_0_robIdx_5_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_robIdx_5_value g=%h i=%h",$time,g_io_snapshots_0_robIdx_5_value,i_io_snapshots_0_robIdx_5_value); end checks++;
    if (!$isunknown(g_io_snapshots_0_isCFI_0) && (g_io_snapshots_0_isCFI_0) !== (i_io_snapshots_0_isCFI_0)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_isCFI_0 g=%h i=%h",$time,g_io_snapshots_0_isCFI_0,i_io_snapshots_0_isCFI_0); end checks++;
    if (!$isunknown(g_io_snapshots_0_isCFI_1) && (g_io_snapshots_0_isCFI_1) !== (i_io_snapshots_0_isCFI_1)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_isCFI_1 g=%h i=%h",$time,g_io_snapshots_0_isCFI_1,i_io_snapshots_0_isCFI_1); end checks++;
    if (!$isunknown(g_io_snapshots_0_isCFI_2) && (g_io_snapshots_0_isCFI_2) !== (i_io_snapshots_0_isCFI_2)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_isCFI_2 g=%h i=%h",$time,g_io_snapshots_0_isCFI_2,i_io_snapshots_0_isCFI_2); end checks++;
    if (!$isunknown(g_io_snapshots_0_isCFI_3) && (g_io_snapshots_0_isCFI_3) !== (i_io_snapshots_0_isCFI_3)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_isCFI_3 g=%h i=%h",$time,g_io_snapshots_0_isCFI_3,i_io_snapshots_0_isCFI_3); end checks++;
    if (!$isunknown(g_io_snapshots_0_isCFI_4) && (g_io_snapshots_0_isCFI_4) !== (i_io_snapshots_0_isCFI_4)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_isCFI_4 g=%h i=%h",$time,g_io_snapshots_0_isCFI_4,i_io_snapshots_0_isCFI_4); end checks++;
    if (!$isunknown(g_io_snapshots_0_isCFI_5) && (g_io_snapshots_0_isCFI_5) !== (i_io_snapshots_0_isCFI_5)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_0_isCFI_5 g=%h i=%h",$time,g_io_snapshots_0_isCFI_5,i_io_snapshots_0_isCFI_5); end checks++;
    if (!$isunknown(g_io_snapshots_1_robIdx_0_flag) && (g_io_snapshots_1_robIdx_0_flag) !== (i_io_snapshots_1_robIdx_0_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_robIdx_0_flag g=%h i=%h",$time,g_io_snapshots_1_robIdx_0_flag,i_io_snapshots_1_robIdx_0_flag); end checks++;
    if (!$isunknown(g_io_snapshots_1_robIdx_0_value) && (g_io_snapshots_1_robIdx_0_value) !== (i_io_snapshots_1_robIdx_0_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_robIdx_0_value g=%h i=%h",$time,g_io_snapshots_1_robIdx_0_value,i_io_snapshots_1_robIdx_0_value); end checks++;
    if (!$isunknown(g_io_snapshots_1_robIdx_1_flag) && (g_io_snapshots_1_robIdx_1_flag) !== (i_io_snapshots_1_robIdx_1_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_robIdx_1_flag g=%h i=%h",$time,g_io_snapshots_1_robIdx_1_flag,i_io_snapshots_1_robIdx_1_flag); end checks++;
    if (!$isunknown(g_io_snapshots_1_robIdx_1_value) && (g_io_snapshots_1_robIdx_1_value) !== (i_io_snapshots_1_robIdx_1_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_robIdx_1_value g=%h i=%h",$time,g_io_snapshots_1_robIdx_1_value,i_io_snapshots_1_robIdx_1_value); end checks++;
    if (!$isunknown(g_io_snapshots_1_robIdx_2_flag) && (g_io_snapshots_1_robIdx_2_flag) !== (i_io_snapshots_1_robIdx_2_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_robIdx_2_flag g=%h i=%h",$time,g_io_snapshots_1_robIdx_2_flag,i_io_snapshots_1_robIdx_2_flag); end checks++;
    if (!$isunknown(g_io_snapshots_1_robIdx_2_value) && (g_io_snapshots_1_robIdx_2_value) !== (i_io_snapshots_1_robIdx_2_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_robIdx_2_value g=%h i=%h",$time,g_io_snapshots_1_robIdx_2_value,i_io_snapshots_1_robIdx_2_value); end checks++;
    if (!$isunknown(g_io_snapshots_1_robIdx_3_flag) && (g_io_snapshots_1_robIdx_3_flag) !== (i_io_snapshots_1_robIdx_3_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_robIdx_3_flag g=%h i=%h",$time,g_io_snapshots_1_robIdx_3_flag,i_io_snapshots_1_robIdx_3_flag); end checks++;
    if (!$isunknown(g_io_snapshots_1_robIdx_3_value) && (g_io_snapshots_1_robIdx_3_value) !== (i_io_snapshots_1_robIdx_3_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_robIdx_3_value g=%h i=%h",$time,g_io_snapshots_1_robIdx_3_value,i_io_snapshots_1_robIdx_3_value); end checks++;
    if (!$isunknown(g_io_snapshots_1_robIdx_4_flag) && (g_io_snapshots_1_robIdx_4_flag) !== (i_io_snapshots_1_robIdx_4_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_robIdx_4_flag g=%h i=%h",$time,g_io_snapshots_1_robIdx_4_flag,i_io_snapshots_1_robIdx_4_flag); end checks++;
    if (!$isunknown(g_io_snapshots_1_robIdx_4_value) && (g_io_snapshots_1_robIdx_4_value) !== (i_io_snapshots_1_robIdx_4_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_robIdx_4_value g=%h i=%h",$time,g_io_snapshots_1_robIdx_4_value,i_io_snapshots_1_robIdx_4_value); end checks++;
    if (!$isunknown(g_io_snapshots_1_robIdx_5_flag) && (g_io_snapshots_1_robIdx_5_flag) !== (i_io_snapshots_1_robIdx_5_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_robIdx_5_flag g=%h i=%h",$time,g_io_snapshots_1_robIdx_5_flag,i_io_snapshots_1_robIdx_5_flag); end checks++;
    if (!$isunknown(g_io_snapshots_1_robIdx_5_value) && (g_io_snapshots_1_robIdx_5_value) !== (i_io_snapshots_1_robIdx_5_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_robIdx_5_value g=%h i=%h",$time,g_io_snapshots_1_robIdx_5_value,i_io_snapshots_1_robIdx_5_value); end checks++;
    if (!$isunknown(g_io_snapshots_1_isCFI_0) && (g_io_snapshots_1_isCFI_0) !== (i_io_snapshots_1_isCFI_0)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_isCFI_0 g=%h i=%h",$time,g_io_snapshots_1_isCFI_0,i_io_snapshots_1_isCFI_0); end checks++;
    if (!$isunknown(g_io_snapshots_1_isCFI_1) && (g_io_snapshots_1_isCFI_1) !== (i_io_snapshots_1_isCFI_1)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_isCFI_1 g=%h i=%h",$time,g_io_snapshots_1_isCFI_1,i_io_snapshots_1_isCFI_1); end checks++;
    if (!$isunknown(g_io_snapshots_1_isCFI_2) && (g_io_snapshots_1_isCFI_2) !== (i_io_snapshots_1_isCFI_2)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_isCFI_2 g=%h i=%h",$time,g_io_snapshots_1_isCFI_2,i_io_snapshots_1_isCFI_2); end checks++;
    if (!$isunknown(g_io_snapshots_1_isCFI_3) && (g_io_snapshots_1_isCFI_3) !== (i_io_snapshots_1_isCFI_3)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_isCFI_3 g=%h i=%h",$time,g_io_snapshots_1_isCFI_3,i_io_snapshots_1_isCFI_3); end checks++;
    if (!$isunknown(g_io_snapshots_1_isCFI_4) && (g_io_snapshots_1_isCFI_4) !== (i_io_snapshots_1_isCFI_4)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_isCFI_4 g=%h i=%h",$time,g_io_snapshots_1_isCFI_4,i_io_snapshots_1_isCFI_4); end checks++;
    if (!$isunknown(g_io_snapshots_1_isCFI_5) && (g_io_snapshots_1_isCFI_5) !== (i_io_snapshots_1_isCFI_5)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_1_isCFI_5 g=%h i=%h",$time,g_io_snapshots_1_isCFI_5,i_io_snapshots_1_isCFI_5); end checks++;
    if (!$isunknown(g_io_snapshots_2_robIdx_0_flag) && (g_io_snapshots_2_robIdx_0_flag) !== (i_io_snapshots_2_robIdx_0_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_robIdx_0_flag g=%h i=%h",$time,g_io_snapshots_2_robIdx_0_flag,i_io_snapshots_2_robIdx_0_flag); end checks++;
    if (!$isunknown(g_io_snapshots_2_robIdx_0_value) && (g_io_snapshots_2_robIdx_0_value) !== (i_io_snapshots_2_robIdx_0_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_robIdx_0_value g=%h i=%h",$time,g_io_snapshots_2_robIdx_0_value,i_io_snapshots_2_robIdx_0_value); end checks++;
    if (!$isunknown(g_io_snapshots_2_robIdx_1_flag) && (g_io_snapshots_2_robIdx_1_flag) !== (i_io_snapshots_2_robIdx_1_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_robIdx_1_flag g=%h i=%h",$time,g_io_snapshots_2_robIdx_1_flag,i_io_snapshots_2_robIdx_1_flag); end checks++;
    if (!$isunknown(g_io_snapshots_2_robIdx_1_value) && (g_io_snapshots_2_robIdx_1_value) !== (i_io_snapshots_2_robIdx_1_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_robIdx_1_value g=%h i=%h",$time,g_io_snapshots_2_robIdx_1_value,i_io_snapshots_2_robIdx_1_value); end checks++;
    if (!$isunknown(g_io_snapshots_2_robIdx_2_flag) && (g_io_snapshots_2_robIdx_2_flag) !== (i_io_snapshots_2_robIdx_2_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_robIdx_2_flag g=%h i=%h",$time,g_io_snapshots_2_robIdx_2_flag,i_io_snapshots_2_robIdx_2_flag); end checks++;
    if (!$isunknown(g_io_snapshots_2_robIdx_2_value) && (g_io_snapshots_2_robIdx_2_value) !== (i_io_snapshots_2_robIdx_2_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_robIdx_2_value g=%h i=%h",$time,g_io_snapshots_2_robIdx_2_value,i_io_snapshots_2_robIdx_2_value); end checks++;
    if (!$isunknown(g_io_snapshots_2_robIdx_3_flag) && (g_io_snapshots_2_robIdx_3_flag) !== (i_io_snapshots_2_robIdx_3_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_robIdx_3_flag g=%h i=%h",$time,g_io_snapshots_2_robIdx_3_flag,i_io_snapshots_2_robIdx_3_flag); end checks++;
    if (!$isunknown(g_io_snapshots_2_robIdx_3_value) && (g_io_snapshots_2_robIdx_3_value) !== (i_io_snapshots_2_robIdx_3_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_robIdx_3_value g=%h i=%h",$time,g_io_snapshots_2_robIdx_3_value,i_io_snapshots_2_robIdx_3_value); end checks++;
    if (!$isunknown(g_io_snapshots_2_robIdx_4_flag) && (g_io_snapshots_2_robIdx_4_flag) !== (i_io_snapshots_2_robIdx_4_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_robIdx_4_flag g=%h i=%h",$time,g_io_snapshots_2_robIdx_4_flag,i_io_snapshots_2_robIdx_4_flag); end checks++;
    if (!$isunknown(g_io_snapshots_2_robIdx_4_value) && (g_io_snapshots_2_robIdx_4_value) !== (i_io_snapshots_2_robIdx_4_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_robIdx_4_value g=%h i=%h",$time,g_io_snapshots_2_robIdx_4_value,i_io_snapshots_2_robIdx_4_value); end checks++;
    if (!$isunknown(g_io_snapshots_2_robIdx_5_flag) && (g_io_snapshots_2_robIdx_5_flag) !== (i_io_snapshots_2_robIdx_5_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_robIdx_5_flag g=%h i=%h",$time,g_io_snapshots_2_robIdx_5_flag,i_io_snapshots_2_robIdx_5_flag); end checks++;
    if (!$isunknown(g_io_snapshots_2_robIdx_5_value) && (g_io_snapshots_2_robIdx_5_value) !== (i_io_snapshots_2_robIdx_5_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_robIdx_5_value g=%h i=%h",$time,g_io_snapshots_2_robIdx_5_value,i_io_snapshots_2_robIdx_5_value); end checks++;
    if (!$isunknown(g_io_snapshots_2_isCFI_0) && (g_io_snapshots_2_isCFI_0) !== (i_io_snapshots_2_isCFI_0)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_isCFI_0 g=%h i=%h",$time,g_io_snapshots_2_isCFI_0,i_io_snapshots_2_isCFI_0); end checks++;
    if (!$isunknown(g_io_snapshots_2_isCFI_1) && (g_io_snapshots_2_isCFI_1) !== (i_io_snapshots_2_isCFI_1)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_isCFI_1 g=%h i=%h",$time,g_io_snapshots_2_isCFI_1,i_io_snapshots_2_isCFI_1); end checks++;
    if (!$isunknown(g_io_snapshots_2_isCFI_2) && (g_io_snapshots_2_isCFI_2) !== (i_io_snapshots_2_isCFI_2)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_isCFI_2 g=%h i=%h",$time,g_io_snapshots_2_isCFI_2,i_io_snapshots_2_isCFI_2); end checks++;
    if (!$isunknown(g_io_snapshots_2_isCFI_3) && (g_io_snapshots_2_isCFI_3) !== (i_io_snapshots_2_isCFI_3)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_isCFI_3 g=%h i=%h",$time,g_io_snapshots_2_isCFI_3,i_io_snapshots_2_isCFI_3); end checks++;
    if (!$isunknown(g_io_snapshots_2_isCFI_4) && (g_io_snapshots_2_isCFI_4) !== (i_io_snapshots_2_isCFI_4)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_isCFI_4 g=%h i=%h",$time,g_io_snapshots_2_isCFI_4,i_io_snapshots_2_isCFI_4); end checks++;
    if (!$isunknown(g_io_snapshots_2_isCFI_5) && (g_io_snapshots_2_isCFI_5) !== (i_io_snapshots_2_isCFI_5)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_2_isCFI_5 g=%h i=%h",$time,g_io_snapshots_2_isCFI_5,i_io_snapshots_2_isCFI_5); end checks++;
    if (!$isunknown(g_io_snapshots_3_robIdx_0_flag) && (g_io_snapshots_3_robIdx_0_flag) !== (i_io_snapshots_3_robIdx_0_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_robIdx_0_flag g=%h i=%h",$time,g_io_snapshots_3_robIdx_0_flag,i_io_snapshots_3_robIdx_0_flag); end checks++;
    if (!$isunknown(g_io_snapshots_3_robIdx_0_value) && (g_io_snapshots_3_robIdx_0_value) !== (i_io_snapshots_3_robIdx_0_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_robIdx_0_value g=%h i=%h",$time,g_io_snapshots_3_robIdx_0_value,i_io_snapshots_3_robIdx_0_value); end checks++;
    if (!$isunknown(g_io_snapshots_3_robIdx_1_flag) && (g_io_snapshots_3_robIdx_1_flag) !== (i_io_snapshots_3_robIdx_1_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_robIdx_1_flag g=%h i=%h",$time,g_io_snapshots_3_robIdx_1_flag,i_io_snapshots_3_robIdx_1_flag); end checks++;
    if (!$isunknown(g_io_snapshots_3_robIdx_1_value) && (g_io_snapshots_3_robIdx_1_value) !== (i_io_snapshots_3_robIdx_1_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_robIdx_1_value g=%h i=%h",$time,g_io_snapshots_3_robIdx_1_value,i_io_snapshots_3_robIdx_1_value); end checks++;
    if (!$isunknown(g_io_snapshots_3_robIdx_2_flag) && (g_io_snapshots_3_robIdx_2_flag) !== (i_io_snapshots_3_robIdx_2_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_robIdx_2_flag g=%h i=%h",$time,g_io_snapshots_3_robIdx_2_flag,i_io_snapshots_3_robIdx_2_flag); end checks++;
    if (!$isunknown(g_io_snapshots_3_robIdx_2_value) && (g_io_snapshots_3_robIdx_2_value) !== (i_io_snapshots_3_robIdx_2_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_robIdx_2_value g=%h i=%h",$time,g_io_snapshots_3_robIdx_2_value,i_io_snapshots_3_robIdx_2_value); end checks++;
    if (!$isunknown(g_io_snapshots_3_robIdx_3_flag) && (g_io_snapshots_3_robIdx_3_flag) !== (i_io_snapshots_3_robIdx_3_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_robIdx_3_flag g=%h i=%h",$time,g_io_snapshots_3_robIdx_3_flag,i_io_snapshots_3_robIdx_3_flag); end checks++;
    if (!$isunknown(g_io_snapshots_3_robIdx_3_value) && (g_io_snapshots_3_robIdx_3_value) !== (i_io_snapshots_3_robIdx_3_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_robIdx_3_value g=%h i=%h",$time,g_io_snapshots_3_robIdx_3_value,i_io_snapshots_3_robIdx_3_value); end checks++;
    if (!$isunknown(g_io_snapshots_3_robIdx_4_flag) && (g_io_snapshots_3_robIdx_4_flag) !== (i_io_snapshots_3_robIdx_4_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_robIdx_4_flag g=%h i=%h",$time,g_io_snapshots_3_robIdx_4_flag,i_io_snapshots_3_robIdx_4_flag); end checks++;
    if (!$isunknown(g_io_snapshots_3_robIdx_4_value) && (g_io_snapshots_3_robIdx_4_value) !== (i_io_snapshots_3_robIdx_4_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_robIdx_4_value g=%h i=%h",$time,g_io_snapshots_3_robIdx_4_value,i_io_snapshots_3_robIdx_4_value); end checks++;
    if (!$isunknown(g_io_snapshots_3_robIdx_5_flag) && (g_io_snapshots_3_robIdx_5_flag) !== (i_io_snapshots_3_robIdx_5_flag)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_robIdx_5_flag g=%h i=%h",$time,g_io_snapshots_3_robIdx_5_flag,i_io_snapshots_3_robIdx_5_flag); end checks++;
    if (!$isunknown(g_io_snapshots_3_robIdx_5_value) && (g_io_snapshots_3_robIdx_5_value) !== (i_io_snapshots_3_robIdx_5_value)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_robIdx_5_value g=%h i=%h",$time,g_io_snapshots_3_robIdx_5_value,i_io_snapshots_3_robIdx_5_value); end checks++;
    if (!$isunknown(g_io_snapshots_3_isCFI_0) && (g_io_snapshots_3_isCFI_0) !== (i_io_snapshots_3_isCFI_0)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_isCFI_0 g=%h i=%h",$time,g_io_snapshots_3_isCFI_0,i_io_snapshots_3_isCFI_0); end checks++;
    if (!$isunknown(g_io_snapshots_3_isCFI_1) && (g_io_snapshots_3_isCFI_1) !== (i_io_snapshots_3_isCFI_1)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_isCFI_1 g=%h i=%h",$time,g_io_snapshots_3_isCFI_1,i_io_snapshots_3_isCFI_1); end checks++;
    if (!$isunknown(g_io_snapshots_3_isCFI_2) && (g_io_snapshots_3_isCFI_2) !== (i_io_snapshots_3_isCFI_2)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_isCFI_2 g=%h i=%h",$time,g_io_snapshots_3_isCFI_2,i_io_snapshots_3_isCFI_2); end checks++;
    if (!$isunknown(g_io_snapshots_3_isCFI_3) && (g_io_snapshots_3_isCFI_3) !== (i_io_snapshots_3_isCFI_3)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_isCFI_3 g=%h i=%h",$time,g_io_snapshots_3_isCFI_3,i_io_snapshots_3_isCFI_3); end checks++;
    if (!$isunknown(g_io_snapshots_3_isCFI_4) && (g_io_snapshots_3_isCFI_4) !== (i_io_snapshots_3_isCFI_4)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_isCFI_4 g=%h i=%h",$time,g_io_snapshots_3_isCFI_4,i_io_snapshots_3_isCFI_4); end checks++;
    if (!$isunknown(g_io_snapshots_3_isCFI_5) && (g_io_snapshots_3_isCFI_5) !== (i_io_snapshots_3_isCFI_5)) begin errors++; if (errors<=60) $display("[%0t] io_snapshots_3_isCFI_5 g=%h i=%h",$time,g_io_snapshots_3_isCFI_5,i_io_snapshots_3_isCFI_5); end checks++;
    if (!$isunknown(g_io_enqPtr_flag) && (g_io_enqPtr_flag) !== (i_io_enqPtr_flag)) begin errors++; if (errors<=60) $display("[%0t] io_enqPtr_flag g=%h i=%h",$time,g_io_enqPtr_flag,i_io_enqPtr_flag); end checks++;
    if (!$isunknown(g_io_enqPtr_value) && (g_io_enqPtr_value) !== (i_io_enqPtr_value)) begin errors++; if (errors<=60) $display("[%0t] io_enqPtr_value g=%h i=%h",$time,g_io_enqPtr_value,i_io_enqPtr_value); end checks++;
    if (!$isunknown(g_io_deqPtr_flag) && (g_io_deqPtr_flag) !== (i_io_deqPtr_flag)) begin errors++; if (errors<=60) $display("[%0t] io_deqPtr_flag g=%h i=%h",$time,g_io_deqPtr_flag,i_io_deqPtr_flag); end checks++;
    if (!$isunknown(g_io_deqPtr_value) && (g_io_deqPtr_value) !== (i_io_deqPtr_value)) begin errors++; if (errors<=60) $display("[%0t] io_deqPtr_value g=%h i=%h",$time,g_io_deqPtr_value,i_io_deqPtr_value); end checks++;
    if (!$isunknown(g_io_valids_0) && (g_io_valids_0) !== (i_io_valids_0)) begin errors++; if (errors<=60) $display("[%0t] io_valids_0 g=%h i=%h",$time,g_io_valids_0,i_io_valids_0); end checks++;
    if (!$isunknown(g_io_valids_1) && (g_io_valids_1) !== (i_io_valids_1)) begin errors++; if (errors<=60) $display("[%0t] io_valids_1 g=%h i=%h",$time,g_io_valids_1,i_io_valids_1); end checks++;
    if (!$isunknown(g_io_valids_2) && (g_io_valids_2) !== (i_io_valids_2)) begin errors++; if (errors<=60) $display("[%0t] io_valids_2 g=%h i=%h",$time,g_io_valids_2,i_io_valids_2); end checks++;
    if (!$isunknown(g_io_valids_3) && (g_io_valids_3) !== (i_io_valids_3)) begin errors++; if (errors<=60) $display("[%0t] io_valids_3 g=%h i=%h",$time,g_io_valids_3,i_io_valids_3); end checks++;
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
