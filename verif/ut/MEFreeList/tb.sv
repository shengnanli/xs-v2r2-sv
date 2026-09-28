// ★本文件由 gen_tb.py 生成，改请改生成器★
// MEFreeList(整数 move-elimination 空闲列表)双例化逐拍比对。
// 快照暖机窗口(WARM_CYCLES)的理由见 verif/ut/StdFreeList/tb.sv 文件头：
//   快照槽 payload 寄存器不复位，+vcs+initreg+random 下两侧初值各异，先把 4 槽写满再随机读。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  localparam int WARM_CYCLES = 8;
  int cyc = 0;
  always @(negedge clk) if (!rst) cyc <= cyc + 1;
  always #5 clk = ~clk;

  logic io_redirect;
  logic io_walk;
  logic io_allocateReq_0;
  logic io_allocateReq_1;
  logic io_allocateReq_2;
  logic io_allocateReq_3;
  logic io_allocateReq_4;
  logic io_allocateReq_5;
  logic io_walkReq_0;
  logic io_walkReq_1;
  logic io_walkReq_2;
  logic io_walkReq_3;
  logic io_walkReq_4;
  logic io_walkReq_5;
  logic io_doAllocate;
  logic io_freeReq_0;
  logic io_freeReq_1;
  logic io_freeReq_2;
  logic io_freeReq_3;
  logic io_freeReq_4;
  logic io_freeReq_5;
  logic [7:0] io_freePhyReg_0;
  logic [7:0] io_freePhyReg_1;
  logic [7:0] io_freePhyReg_2;
  logic [7:0] io_freePhyReg_3;
  logic [7:0] io_freePhyReg_4;
  logic [7:0] io_freePhyReg_5;
  logic io_commit_isCommit;
  logic io_commit_commitValid_0;
  logic io_commit_commitValid_1;
  logic io_commit_commitValid_2;
  logic io_commit_commitValid_3;
  logic io_commit_commitValid_4;
  logic io_commit_commitValid_5;
  logic io_commit_info_0_rfWen;
  logic io_commit_info_0_isMove;
  logic io_commit_info_1_rfWen;
  logic io_commit_info_1_isMove;
  logic io_commit_info_2_rfWen;
  logic io_commit_info_2_isMove;
  logic io_commit_info_3_rfWen;
  logic io_commit_info_3_isMove;
  logic io_commit_info_4_rfWen;
  logic io_commit_info_4_isMove;
  logic io_commit_info_5_rfWen;
  logic io_commit_info_5_isMove;
  logic io_snpt_snptEnq;
  logic io_snpt_snptDeq;
  logic io_snpt_useSnpt;
  logic [1:0] io_snpt_snptSelect;
  logic io_snpt_flushVec_0;
  logic io_snpt_flushVec_1;
  logic io_snpt_flushVec_2;
  logic io_snpt_flushVec_3;
  logic [7:0] io_debug_rat_0;
  logic [7:0] io_debug_rat_1;
  logic [7:0] io_debug_rat_2;
  logic [7:0] io_debug_rat_3;
  logic [7:0] io_debug_rat_4;
  logic [7:0] io_debug_rat_5;
  logic [7:0] io_debug_rat_6;
  logic [7:0] io_debug_rat_7;
  logic [7:0] io_debug_rat_8;
  logic [7:0] io_debug_rat_9;
  logic [7:0] io_debug_rat_10;
  logic [7:0] io_debug_rat_11;
  logic [7:0] io_debug_rat_12;
  logic [7:0] io_debug_rat_13;
  logic [7:0] io_debug_rat_14;
  logic [7:0] io_debug_rat_15;
  logic [7:0] io_debug_rat_16;
  logic [7:0] io_debug_rat_17;
  logic [7:0] io_debug_rat_18;
  logic [7:0] io_debug_rat_19;
  logic [7:0] io_debug_rat_20;
  logic [7:0] io_debug_rat_21;
  logic [7:0] io_debug_rat_22;
  logic [7:0] io_debug_rat_23;
  logic [7:0] io_debug_rat_24;
  logic [7:0] io_debug_rat_25;
  logic [7:0] io_debug_rat_26;
  logic [7:0] io_debug_rat_27;
  logic [7:0] io_debug_rat_28;
  logic [7:0] io_debug_rat_29;
  logic [7:0] io_debug_rat_30;
  logic [7:0] io_debug_rat_31;
  logic [7:0] g_io_allocatePhyReg_0;
  logic [7:0] i_io_allocatePhyReg_0;
  logic [7:0] g_io_allocatePhyReg_1;
  logic [7:0] i_io_allocatePhyReg_1;
  logic [7:0] g_io_allocatePhyReg_2;
  logic [7:0] i_io_allocatePhyReg_2;
  logic [7:0] g_io_allocatePhyReg_3;
  logic [7:0] i_io_allocatePhyReg_3;
  logic [7:0] g_io_allocatePhyReg_4;
  logic [7:0] i_io_allocatePhyReg_4;
  logic [7:0] g_io_allocatePhyReg_5;
  logic [7:0] i_io_allocatePhyReg_5;
  logic g_io_canAllocate;
  logic i_io_canAllocate;
  logic [5:0] g_io_perf_0_value;
  logic [5:0] i_io_perf_0_value;
  logic [5:0] g_io_perf_1_value;
  logic [5:0] i_io_perf_1_value;
  logic [5:0] g_io_perf_2_value;
  logic [5:0] i_io_perf_2_value;
  logic [5:0] g_io_perf_3_value;
  logic [5:0] i_io_perf_3_value;
  MEFreeList g_u (.clock(clk), .reset(rst), .io_redirect(io_redirect), .io_walk(io_walk), .io_allocateReq_0(io_allocateReq_0), .io_allocateReq_1(io_allocateReq_1), .io_allocateReq_2(io_allocateReq_2), .io_allocateReq_3(io_allocateReq_3), .io_allocateReq_4(io_allocateReq_4), .io_allocateReq_5(io_allocateReq_5), .io_walkReq_0(io_walkReq_0), .io_walkReq_1(io_walkReq_1), .io_walkReq_2(io_walkReq_2), .io_walkReq_3(io_walkReq_3), .io_walkReq_4(io_walkReq_4), .io_walkReq_5(io_walkReq_5), .io_doAllocate(io_doAllocate), .io_freeReq_0(io_freeReq_0), .io_freeReq_1(io_freeReq_1), .io_freeReq_2(io_freeReq_2), .io_freeReq_3(io_freeReq_3), .io_freeReq_4(io_freeReq_4), .io_freeReq_5(io_freeReq_5), .io_freePhyReg_0(io_freePhyReg_0), .io_freePhyReg_1(io_freePhyReg_1), .io_freePhyReg_2(io_freePhyReg_2), .io_freePhyReg_3(io_freePhyReg_3), .io_freePhyReg_4(io_freePhyReg_4), .io_freePhyReg_5(io_freePhyReg_5), .io_commit_isCommit(io_commit_isCommit), .io_commit_commitValid_0(io_commit_commitValid_0), .io_commit_commitValid_1(io_commit_commitValid_1), .io_commit_commitValid_2(io_commit_commitValid_2), .io_commit_commitValid_3(io_commit_commitValid_3), .io_commit_commitValid_4(io_commit_commitValid_4), .io_commit_commitValid_5(io_commit_commitValid_5), .io_commit_info_0_rfWen(io_commit_info_0_rfWen), .io_commit_info_0_isMove(io_commit_info_0_isMove), .io_commit_info_1_rfWen(io_commit_info_1_rfWen), .io_commit_info_1_isMove(io_commit_info_1_isMove), .io_commit_info_2_rfWen(io_commit_info_2_rfWen), .io_commit_info_2_isMove(io_commit_info_2_isMove), .io_commit_info_3_rfWen(io_commit_info_3_rfWen), .io_commit_info_3_isMove(io_commit_info_3_isMove), .io_commit_info_4_rfWen(io_commit_info_4_rfWen), .io_commit_info_4_isMove(io_commit_info_4_isMove), .io_commit_info_5_rfWen(io_commit_info_5_rfWen), .io_commit_info_5_isMove(io_commit_info_5_isMove), .io_snpt_snptEnq(io_snpt_snptEnq), .io_snpt_snptDeq(io_snpt_snptDeq), .io_snpt_useSnpt(io_snpt_useSnpt), .io_snpt_snptSelect(io_snpt_snptSelect), .io_snpt_flushVec_0(io_snpt_flushVec_0), .io_snpt_flushVec_1(io_snpt_flushVec_1), .io_snpt_flushVec_2(io_snpt_flushVec_2), .io_snpt_flushVec_3(io_snpt_flushVec_3), .io_debug_rat_0(io_debug_rat_0), .io_debug_rat_1(io_debug_rat_1), .io_debug_rat_2(io_debug_rat_2), .io_debug_rat_3(io_debug_rat_3), .io_debug_rat_4(io_debug_rat_4), .io_debug_rat_5(io_debug_rat_5), .io_debug_rat_6(io_debug_rat_6), .io_debug_rat_7(io_debug_rat_7), .io_debug_rat_8(io_debug_rat_8), .io_debug_rat_9(io_debug_rat_9), .io_debug_rat_10(io_debug_rat_10), .io_debug_rat_11(io_debug_rat_11), .io_debug_rat_12(io_debug_rat_12), .io_debug_rat_13(io_debug_rat_13), .io_debug_rat_14(io_debug_rat_14), .io_debug_rat_15(io_debug_rat_15), .io_debug_rat_16(io_debug_rat_16), .io_debug_rat_17(io_debug_rat_17), .io_debug_rat_18(io_debug_rat_18), .io_debug_rat_19(io_debug_rat_19), .io_debug_rat_20(io_debug_rat_20), .io_debug_rat_21(io_debug_rat_21), .io_debug_rat_22(io_debug_rat_22), .io_debug_rat_23(io_debug_rat_23), .io_debug_rat_24(io_debug_rat_24), .io_debug_rat_25(io_debug_rat_25), .io_debug_rat_26(io_debug_rat_26), .io_debug_rat_27(io_debug_rat_27), .io_debug_rat_28(io_debug_rat_28), .io_debug_rat_29(io_debug_rat_29), .io_debug_rat_30(io_debug_rat_30), .io_debug_rat_31(io_debug_rat_31), .io_allocatePhyReg_0(g_io_allocatePhyReg_0), .io_allocatePhyReg_1(g_io_allocatePhyReg_1), .io_allocatePhyReg_2(g_io_allocatePhyReg_2), .io_allocatePhyReg_3(g_io_allocatePhyReg_3), .io_allocatePhyReg_4(g_io_allocatePhyReg_4), .io_allocatePhyReg_5(g_io_allocatePhyReg_5), .io_canAllocate(g_io_canAllocate), .io_perf_0_value(g_io_perf_0_value), .io_perf_1_value(g_io_perf_1_value), .io_perf_2_value(g_io_perf_2_value), .io_perf_3_value(g_io_perf_3_value));
  MEFreeList_xs i_u (.clock(clk), .reset(rst), .io_redirect(io_redirect), .io_walk(io_walk), .io_allocateReq_0(io_allocateReq_0), .io_allocateReq_1(io_allocateReq_1), .io_allocateReq_2(io_allocateReq_2), .io_allocateReq_3(io_allocateReq_3), .io_allocateReq_4(io_allocateReq_4), .io_allocateReq_5(io_allocateReq_5), .io_walkReq_0(io_walkReq_0), .io_walkReq_1(io_walkReq_1), .io_walkReq_2(io_walkReq_2), .io_walkReq_3(io_walkReq_3), .io_walkReq_4(io_walkReq_4), .io_walkReq_5(io_walkReq_5), .io_doAllocate(io_doAllocate), .io_freeReq_0(io_freeReq_0), .io_freeReq_1(io_freeReq_1), .io_freeReq_2(io_freeReq_2), .io_freeReq_3(io_freeReq_3), .io_freeReq_4(io_freeReq_4), .io_freeReq_5(io_freeReq_5), .io_freePhyReg_0(io_freePhyReg_0), .io_freePhyReg_1(io_freePhyReg_1), .io_freePhyReg_2(io_freePhyReg_2), .io_freePhyReg_3(io_freePhyReg_3), .io_freePhyReg_4(io_freePhyReg_4), .io_freePhyReg_5(io_freePhyReg_5), .io_commit_isCommit(io_commit_isCommit), .io_commit_commitValid_0(io_commit_commitValid_0), .io_commit_commitValid_1(io_commit_commitValid_1), .io_commit_commitValid_2(io_commit_commitValid_2), .io_commit_commitValid_3(io_commit_commitValid_3), .io_commit_commitValid_4(io_commit_commitValid_4), .io_commit_commitValid_5(io_commit_commitValid_5), .io_commit_info_0_rfWen(io_commit_info_0_rfWen), .io_commit_info_0_isMove(io_commit_info_0_isMove), .io_commit_info_1_rfWen(io_commit_info_1_rfWen), .io_commit_info_1_isMove(io_commit_info_1_isMove), .io_commit_info_2_rfWen(io_commit_info_2_rfWen), .io_commit_info_2_isMove(io_commit_info_2_isMove), .io_commit_info_3_rfWen(io_commit_info_3_rfWen), .io_commit_info_3_isMove(io_commit_info_3_isMove), .io_commit_info_4_rfWen(io_commit_info_4_rfWen), .io_commit_info_4_isMove(io_commit_info_4_isMove), .io_commit_info_5_rfWen(io_commit_info_5_rfWen), .io_commit_info_5_isMove(io_commit_info_5_isMove), .io_snpt_snptEnq(io_snpt_snptEnq), .io_snpt_snptDeq(io_snpt_snptDeq), .io_snpt_useSnpt(io_snpt_useSnpt), .io_snpt_snptSelect(io_snpt_snptSelect), .io_snpt_flushVec_0(io_snpt_flushVec_0), .io_snpt_flushVec_1(io_snpt_flushVec_1), .io_snpt_flushVec_2(io_snpt_flushVec_2), .io_snpt_flushVec_3(io_snpt_flushVec_3), .io_debug_rat_0(io_debug_rat_0), .io_debug_rat_1(io_debug_rat_1), .io_debug_rat_2(io_debug_rat_2), .io_debug_rat_3(io_debug_rat_3), .io_debug_rat_4(io_debug_rat_4), .io_debug_rat_5(io_debug_rat_5), .io_debug_rat_6(io_debug_rat_6), .io_debug_rat_7(io_debug_rat_7), .io_debug_rat_8(io_debug_rat_8), .io_debug_rat_9(io_debug_rat_9), .io_debug_rat_10(io_debug_rat_10), .io_debug_rat_11(io_debug_rat_11), .io_debug_rat_12(io_debug_rat_12), .io_debug_rat_13(io_debug_rat_13), .io_debug_rat_14(io_debug_rat_14), .io_debug_rat_15(io_debug_rat_15), .io_debug_rat_16(io_debug_rat_16), .io_debug_rat_17(io_debug_rat_17), .io_debug_rat_18(io_debug_rat_18), .io_debug_rat_19(io_debug_rat_19), .io_debug_rat_20(io_debug_rat_20), .io_debug_rat_21(io_debug_rat_21), .io_debug_rat_22(io_debug_rat_22), .io_debug_rat_23(io_debug_rat_23), .io_debug_rat_24(io_debug_rat_24), .io_debug_rat_25(io_debug_rat_25), .io_debug_rat_26(io_debug_rat_26), .io_debug_rat_27(io_debug_rat_27), .io_debug_rat_28(io_debug_rat_28), .io_debug_rat_29(io_debug_rat_29), .io_debug_rat_30(io_debug_rat_30), .io_debug_rat_31(io_debug_rat_31), .io_allocatePhyReg_0(i_io_allocatePhyReg_0), .io_allocatePhyReg_1(i_io_allocatePhyReg_1), .io_allocatePhyReg_2(i_io_allocatePhyReg_2), .io_allocatePhyReg_3(i_io_allocatePhyReg_3), .io_allocatePhyReg_4(i_io_allocatePhyReg_4), .io_allocatePhyReg_5(i_io_allocatePhyReg_5), .io_canAllocate(i_io_canAllocate), .io_perf_0_value(i_io_perf_0_value), .io_perf_1_value(i_io_perf_1_value), .io_perf_2_value(i_io_perf_2_value), .io_perf_3_value(i_io_perf_3_value));

  // 回收的物理号取整数池全域 [0, 223]
  function automatic logic [7:0] rnd_preg(); return 8'($urandom_range(0,223)); endfunction
  always @(negedge clk) begin
    if (rst) begin
      io_redirect <= 0;
      io_walk <= 0;
      io_allocateReq_0 <= 0;
      io_allocateReq_1 <= 0;
      io_allocateReq_2 <= 0;
      io_allocateReq_3 <= 0;
      io_allocateReq_4 <= 0;
      io_allocateReq_5 <= 0;
      io_walkReq_0 <= 0;
      io_walkReq_1 <= 0;
      io_walkReq_2 <= 0;
      io_walkReq_3 <= 0;
      io_walkReq_4 <= 0;
      io_walkReq_5 <= 0;
      io_doAllocate <= 0;
      io_freeReq_0 <= 0;
      io_freeReq_1 <= 0;
      io_freeReq_2 <= 0;
      io_freeReq_3 <= 0;
      io_freeReq_4 <= 0;
      io_freeReq_5 <= 0;
      io_freePhyReg_0 <= 0;
      io_freePhyReg_1 <= 0;
      io_freePhyReg_2 <= 0;
      io_freePhyReg_3 <= 0;
      io_freePhyReg_4 <= 0;
      io_freePhyReg_5 <= 0;
      io_commit_isCommit <= 0;
      io_commit_commitValid_0 <= 0;
      io_commit_commitValid_1 <= 0;
      io_commit_commitValid_2 <= 0;
      io_commit_commitValid_3 <= 0;
      io_commit_commitValid_4 <= 0;
      io_commit_commitValid_5 <= 0;
      io_commit_info_0_rfWen <= 0;
      io_commit_info_0_isMove <= 0;
      io_commit_info_1_rfWen <= 0;
      io_commit_info_1_isMove <= 0;
      io_commit_info_2_rfWen <= 0;
      io_commit_info_2_isMove <= 0;
      io_commit_info_3_rfWen <= 0;
      io_commit_info_3_isMove <= 0;
      io_commit_info_4_rfWen <= 0;
      io_commit_info_4_isMove <= 0;
      io_commit_info_5_rfWen <= 0;
      io_commit_info_5_isMove <= 0;
      io_snpt_snptEnq <= 0;
      io_snpt_snptDeq <= 0;
      io_snpt_useSnpt <= 0;
      io_snpt_snptSelect <= 0;
      io_snpt_flushVec_0 <= 0;
      io_snpt_flushVec_1 <= 0;
      io_snpt_flushVec_2 <= 0;
      io_snpt_flushVec_3 <= 0;
      io_debug_rat_0 <= 0;
      io_debug_rat_1 <= 0;
      io_debug_rat_2 <= 0;
      io_debug_rat_3 <= 0;
      io_debug_rat_4 <= 0;
      io_debug_rat_5 <= 0;
      io_debug_rat_6 <= 0;
      io_debug_rat_7 <= 0;
      io_debug_rat_8 <= 0;
      io_debug_rat_9 <= 0;
      io_debug_rat_10 <= 0;
      io_debug_rat_11 <= 0;
      io_debug_rat_12 <= 0;
      io_debug_rat_13 <= 0;
      io_debug_rat_14 <= 0;
      io_debug_rat_15 <= 0;
      io_debug_rat_16 <= 0;
      io_debug_rat_17 <= 0;
      io_debug_rat_18 <= 0;
      io_debug_rat_19 <= 0;
      io_debug_rat_20 <= 0;
      io_debug_rat_21 <= 0;
      io_debug_rat_22 <= 0;
      io_debug_rat_23 <= 0;
      io_debug_rat_24 <= 0;
      io_debug_rat_25 <= 0;
      io_debug_rat_26 <= 0;
      io_debug_rat_27 <= 0;
      io_debug_rat_28 <= 0;
      io_debug_rat_29 <= 0;
      io_debug_rat_30 <= 0;
      io_debug_rat_31 <= 0;
    end else begin
      io_redirect <= (cyc < WARM_CYCLES) ? 1'b0 : ($urandom_range(0,99) < 3);
      io_walk     <= ($urandom_range(0,99) < 25);
      io_doAllocate <= $urandom_range(0,1);
      io_allocateReq_0 <= $urandom_range(0,1);
      io_walkReq_0 <= $urandom_range(0,1);
      io_freeReq_0 <= ($urandom_range(0,99)<30);
      io_freePhyReg_0 <= rnd_preg();
      io_commit_commitValid_0 <= $urandom_range(0,1);
      io_commit_info_0_rfWen <= $urandom_range(0,1);
      io_commit_info_0_isMove <= ($urandom_range(0,99)<30);
      io_allocateReq_1 <= $urandom_range(0,1);
      io_walkReq_1 <= $urandom_range(0,1);
      io_freeReq_1 <= ($urandom_range(0,99)<30);
      io_freePhyReg_1 <= rnd_preg();
      io_commit_commitValid_1 <= $urandom_range(0,1);
      io_commit_info_1_rfWen <= $urandom_range(0,1);
      io_commit_info_1_isMove <= ($urandom_range(0,99)<30);
      io_allocateReq_2 <= $urandom_range(0,1);
      io_walkReq_2 <= $urandom_range(0,1);
      io_freeReq_2 <= ($urandom_range(0,99)<30);
      io_freePhyReg_2 <= rnd_preg();
      io_commit_commitValid_2 <= $urandom_range(0,1);
      io_commit_info_2_rfWen <= $urandom_range(0,1);
      io_commit_info_2_isMove <= ($urandom_range(0,99)<30);
      io_allocateReq_3 <= $urandom_range(0,1);
      io_walkReq_3 <= $urandom_range(0,1);
      io_freeReq_3 <= ($urandom_range(0,99)<30);
      io_freePhyReg_3 <= rnd_preg();
      io_commit_commitValid_3 <= $urandom_range(0,1);
      io_commit_info_3_rfWen <= $urandom_range(0,1);
      io_commit_info_3_isMove <= ($urandom_range(0,99)<30);
      io_allocateReq_4 <= $urandom_range(0,1);
      io_walkReq_4 <= $urandom_range(0,1);
      io_freeReq_4 <= ($urandom_range(0,99)<30);
      io_freePhyReg_4 <= rnd_preg();
      io_commit_commitValid_4 <= $urandom_range(0,1);
      io_commit_info_4_rfWen <= $urandom_range(0,1);
      io_commit_info_4_isMove <= ($urandom_range(0,99)<30);
      io_allocateReq_5 <= $urandom_range(0,1);
      io_walkReq_5 <= $urandom_range(0,1);
      io_freeReq_5 <= ($urandom_range(0,99)<30);
      io_freePhyReg_5 <= rnd_preg();
      io_commit_commitValid_5 <= $urandom_range(0,1);
      io_commit_info_5_rfWen <= $urandom_range(0,1);
      io_commit_info_5_isMove <= ($urandom_range(0,99)<30);
      io_commit_isCommit <= $urandom_range(0,1);
      io_debug_rat_0 <= rnd_preg();
      io_debug_rat_1 <= rnd_preg();
      io_debug_rat_2 <= rnd_preg();
      io_debug_rat_3 <= rnd_preg();
      io_debug_rat_4 <= rnd_preg();
      io_debug_rat_5 <= rnd_preg();
      io_debug_rat_6 <= rnd_preg();
      io_debug_rat_7 <= rnd_preg();
      io_debug_rat_8 <= rnd_preg();
      io_debug_rat_9 <= rnd_preg();
      io_debug_rat_10 <= rnd_preg();
      io_debug_rat_11 <= rnd_preg();
      io_debug_rat_12 <= rnd_preg();
      io_debug_rat_13 <= rnd_preg();
      io_debug_rat_14 <= rnd_preg();
      io_debug_rat_15 <= rnd_preg();
      io_debug_rat_16 <= rnd_preg();
      io_debug_rat_17 <= rnd_preg();
      io_debug_rat_18 <= rnd_preg();
      io_debug_rat_19 <= rnd_preg();
      io_debug_rat_20 <= rnd_preg();
      io_debug_rat_21 <= rnd_preg();
      io_debug_rat_22 <= rnd_preg();
      io_debug_rat_23 <= rnd_preg();
      io_debug_rat_24 <= rnd_preg();
      io_debug_rat_25 <= rnd_preg();
      io_debug_rat_26 <= rnd_preg();
      io_debug_rat_27 <= rnd_preg();
      io_debug_rat_28 <= rnd_preg();
      io_debug_rat_29 <= rnd_preg();
      io_debug_rat_30 <= rnd_preg();
      io_debug_rat_31 <= rnd_preg();
      if (cyc < WARM_CYCLES) begin
        io_snpt_snptEnq <= 1'b1; io_snpt_snptDeq <= 1'b0;
        io_snpt_useSnpt <= 1'b0; io_snpt_snptSelect <= 2'd0;
      end else begin
        io_snpt_snptEnq <= ($urandom_range(0,99)<15); io_snpt_snptDeq <= ($urandom_range(0,99)<15);
        io_snpt_useSnpt <= $urandom_range(0,1); io_snpt_snptSelect <= $urandom_range(0,3);
      end
      io_snpt_flushVec_0 <= ($urandom_range(0,99)<5);
      io_snpt_flushVec_1 <= ($urandom_range(0,99)<5);
      io_snpt_flushVec_2 <= ($urandom_range(0,99)<5);
      io_snpt_flushVec_3 <= ($urandom_range(0,99)<5);
    end
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_io_allocatePhyReg_0) && g_io_allocatePhyReg_0 !== i_io_allocatePhyReg_0) begin errors++;
      if(errors<=80) $display("[%0t] io_allocatePhyReg_0 g=%h i=%h", $time, g_io_allocatePhyReg_0, i_io_allocatePhyReg_0); end
    if (!$isunknown(g_io_allocatePhyReg_1) && g_io_allocatePhyReg_1 !== i_io_allocatePhyReg_1) begin errors++;
      if(errors<=80) $display("[%0t] io_allocatePhyReg_1 g=%h i=%h", $time, g_io_allocatePhyReg_1, i_io_allocatePhyReg_1); end
    if (!$isunknown(g_io_allocatePhyReg_2) && g_io_allocatePhyReg_2 !== i_io_allocatePhyReg_2) begin errors++;
      if(errors<=80) $display("[%0t] io_allocatePhyReg_2 g=%h i=%h", $time, g_io_allocatePhyReg_2, i_io_allocatePhyReg_2); end
    if (!$isunknown(g_io_allocatePhyReg_3) && g_io_allocatePhyReg_3 !== i_io_allocatePhyReg_3) begin errors++;
      if(errors<=80) $display("[%0t] io_allocatePhyReg_3 g=%h i=%h", $time, g_io_allocatePhyReg_3, i_io_allocatePhyReg_3); end
    if (!$isunknown(g_io_allocatePhyReg_4) && g_io_allocatePhyReg_4 !== i_io_allocatePhyReg_4) begin errors++;
      if(errors<=80) $display("[%0t] io_allocatePhyReg_4 g=%h i=%h", $time, g_io_allocatePhyReg_4, i_io_allocatePhyReg_4); end
    if (!$isunknown(g_io_allocatePhyReg_5) && g_io_allocatePhyReg_5 !== i_io_allocatePhyReg_5) begin errors++;
      if(errors<=80) $display("[%0t] io_allocatePhyReg_5 g=%h i=%h", $time, g_io_allocatePhyReg_5, i_io_allocatePhyReg_5); end
    if (!$isunknown(g_io_canAllocate) && g_io_canAllocate !== i_io_canAllocate) begin errors++;
      if(errors<=80) $display("[%0t] io_canAllocate g=%h i=%h", $time, g_io_canAllocate, i_io_canAllocate); end
    if (!$isunknown(g_io_perf_0_value) && g_io_perf_0_value !== i_io_perf_0_value) begin errors++;
      if(errors<=80) $display("[%0t] io_perf_0_value g=%h i=%h", $time, g_io_perf_0_value, i_io_perf_0_value); end
    if (!$isunknown(g_io_perf_1_value) && g_io_perf_1_value !== i_io_perf_1_value) begin errors++;
      if(errors<=80) $display("[%0t] io_perf_1_value g=%h i=%h", $time, g_io_perf_1_value, i_io_perf_1_value); end
    if (!$isunknown(g_io_perf_2_value) && g_io_perf_2_value !== i_io_perf_2_value) begin errors++;
      if(errors<=80) $display("[%0t] io_perf_2_value g=%h i=%h", $time, g_io_perf_2_value, i_io_perf_2_value); end
    if (!$isunknown(g_io_perf_3_value) && g_io_perf_3_value !== i_io_perf_3_value) begin errors++;
      if(errors<=80) $display("[%0t] io_perf_3_value g=%h i=%h", $time, g_io_perf_3_value, i_io_perf_3_value); end
    // 内部指针探针：golden 展平名 vs 核里的 struct(golden 的 shiftAmount 就是 headPtr.value)
    if (!$isunknown(g_u.headPtr_flag)) begin
      if (g_u.headPtr_flag !== i_u.u_core.headPtr.flag) begin errors++;
        if(errors<=80) $display("[%0t] headPtr.flag g=%h i=%h", $time, g_u.headPtr_flag, i_u.u_core.headPtr.flag); end
      if (g_u.shiftAmount !== i_u.u_core.headPtr.value) begin errors++;
        if(errors<=80) $display("[%0t] headPtr.value g=%h i=%h", $time, g_u.shiftAmount, i_u.u_core.headPtr.value); end
    end
    if (!$isunknown(g_u.archHeadPtr_flag)) begin
      if (g_u.archHeadPtr_flag !== i_u.u_core.archHeadPtr.flag) begin errors++;
        if(errors<=80) $display("[%0t] archHeadPtr.flag g=%h i=%h", $time, g_u.archHeadPtr_flag, i_u.u_core.archHeadPtr.flag); end
      if (g_u.archHeadPtr_value !== i_u.u_core.archHeadPtr.value) begin errors++;
        if(errors<=80) $display("[%0t] archHeadPtr.value g=%h i=%h", $time, g_u.archHeadPtr_value, i_u.u_core.archHeadPtr.value); end
    end
    if (!$isunknown(g_u.tailPtr_flag)) begin
      if (g_u.tailPtr_flag !== i_u.u_core.tailPtr.flag) begin errors++;
        if(errors<=80) $display("[%0t] tailPtr.flag g=%h i=%h", $time, g_u.tailPtr_flag, i_u.u_core.tailPtr.flag); end
      if (g_u.tailPtr_value !== i_u.u_core.tailPtr.value) begin errors++;
        if(errors<=80) $display("[%0t] tailPtr.value g=%h i=%h", $time, g_u.tailPtr_value, i_u.u_core.tailPtr.value); end
    end
    // debug 影子 head 指针(死位，核里为对齐 golden 展平名拆成 _flag/_value 标量)
    if (!$isunknown(g_u.debugArchHeadPtr_flag) && g_u.debugArchHeadPtr_flag !== i_u.u_core.debugArchHeadPtr_flag) begin errors++;
      if(errors<=80) $display("[%0t] debugArchHeadPtr_flag g=%h i=%h", $time, g_u.debugArchHeadPtr_flag, i_u.u_core.debugArchHeadPtr_flag); end
    if (!$isunknown(g_u.debugArchHeadPtr_value) && g_u.debugArchHeadPtr_value !== i_u.u_core.debugArchHeadPtr_value) begin errors++;
      if(errors<=80) $display("[%0t] debugArchHeadPtr_value g=%h i=%h", $time, g_u.debugArchHeadPtr_value, i_u.u_core.debugArchHeadPtr_value); end
    // debug 影子 RAT(死位，只有探针能看见)：32 项逐拍比
    if (!$isunknown(g_u.debugArchRAT_0) && g_u.debugArchRAT_0 !== i_u.u_core.debugArchRAT[0]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_0 g=%h i=%h", $time, g_u.debugArchRAT_0, i_u.u_core.debugArchRAT[0]); end
    if (!$isunknown(g_u.debugArchRAT_1) && g_u.debugArchRAT_1 !== i_u.u_core.debugArchRAT[1]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_1 g=%h i=%h", $time, g_u.debugArchRAT_1, i_u.u_core.debugArchRAT[1]); end
    if (!$isunknown(g_u.debugArchRAT_2) && g_u.debugArchRAT_2 !== i_u.u_core.debugArchRAT[2]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_2 g=%h i=%h", $time, g_u.debugArchRAT_2, i_u.u_core.debugArchRAT[2]); end
    if (!$isunknown(g_u.debugArchRAT_3) && g_u.debugArchRAT_3 !== i_u.u_core.debugArchRAT[3]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_3 g=%h i=%h", $time, g_u.debugArchRAT_3, i_u.u_core.debugArchRAT[3]); end
    if (!$isunknown(g_u.debugArchRAT_4) && g_u.debugArchRAT_4 !== i_u.u_core.debugArchRAT[4]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_4 g=%h i=%h", $time, g_u.debugArchRAT_4, i_u.u_core.debugArchRAT[4]); end
    if (!$isunknown(g_u.debugArchRAT_5) && g_u.debugArchRAT_5 !== i_u.u_core.debugArchRAT[5]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_5 g=%h i=%h", $time, g_u.debugArchRAT_5, i_u.u_core.debugArchRAT[5]); end
    if (!$isunknown(g_u.debugArchRAT_6) && g_u.debugArchRAT_6 !== i_u.u_core.debugArchRAT[6]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_6 g=%h i=%h", $time, g_u.debugArchRAT_6, i_u.u_core.debugArchRAT[6]); end
    if (!$isunknown(g_u.debugArchRAT_7) && g_u.debugArchRAT_7 !== i_u.u_core.debugArchRAT[7]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_7 g=%h i=%h", $time, g_u.debugArchRAT_7, i_u.u_core.debugArchRAT[7]); end
    if (!$isunknown(g_u.debugArchRAT_8) && g_u.debugArchRAT_8 !== i_u.u_core.debugArchRAT[8]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_8 g=%h i=%h", $time, g_u.debugArchRAT_8, i_u.u_core.debugArchRAT[8]); end
    if (!$isunknown(g_u.debugArchRAT_9) && g_u.debugArchRAT_9 !== i_u.u_core.debugArchRAT[9]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_9 g=%h i=%h", $time, g_u.debugArchRAT_9, i_u.u_core.debugArchRAT[9]); end
    if (!$isunknown(g_u.debugArchRAT_10) && g_u.debugArchRAT_10 !== i_u.u_core.debugArchRAT[10]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_10 g=%h i=%h", $time, g_u.debugArchRAT_10, i_u.u_core.debugArchRAT[10]); end
    if (!$isunknown(g_u.debugArchRAT_11) && g_u.debugArchRAT_11 !== i_u.u_core.debugArchRAT[11]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_11 g=%h i=%h", $time, g_u.debugArchRAT_11, i_u.u_core.debugArchRAT[11]); end
    if (!$isunknown(g_u.debugArchRAT_12) && g_u.debugArchRAT_12 !== i_u.u_core.debugArchRAT[12]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_12 g=%h i=%h", $time, g_u.debugArchRAT_12, i_u.u_core.debugArchRAT[12]); end
    if (!$isunknown(g_u.debugArchRAT_13) && g_u.debugArchRAT_13 !== i_u.u_core.debugArchRAT[13]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_13 g=%h i=%h", $time, g_u.debugArchRAT_13, i_u.u_core.debugArchRAT[13]); end
    if (!$isunknown(g_u.debugArchRAT_14) && g_u.debugArchRAT_14 !== i_u.u_core.debugArchRAT[14]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_14 g=%h i=%h", $time, g_u.debugArchRAT_14, i_u.u_core.debugArchRAT[14]); end
    if (!$isunknown(g_u.debugArchRAT_15) && g_u.debugArchRAT_15 !== i_u.u_core.debugArchRAT[15]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_15 g=%h i=%h", $time, g_u.debugArchRAT_15, i_u.u_core.debugArchRAT[15]); end
    if (!$isunknown(g_u.debugArchRAT_16) && g_u.debugArchRAT_16 !== i_u.u_core.debugArchRAT[16]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_16 g=%h i=%h", $time, g_u.debugArchRAT_16, i_u.u_core.debugArchRAT[16]); end
    if (!$isunknown(g_u.debugArchRAT_17) && g_u.debugArchRAT_17 !== i_u.u_core.debugArchRAT[17]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_17 g=%h i=%h", $time, g_u.debugArchRAT_17, i_u.u_core.debugArchRAT[17]); end
    if (!$isunknown(g_u.debugArchRAT_18) && g_u.debugArchRAT_18 !== i_u.u_core.debugArchRAT[18]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_18 g=%h i=%h", $time, g_u.debugArchRAT_18, i_u.u_core.debugArchRAT[18]); end
    if (!$isunknown(g_u.debugArchRAT_19) && g_u.debugArchRAT_19 !== i_u.u_core.debugArchRAT[19]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_19 g=%h i=%h", $time, g_u.debugArchRAT_19, i_u.u_core.debugArchRAT[19]); end
    if (!$isunknown(g_u.debugArchRAT_20) && g_u.debugArchRAT_20 !== i_u.u_core.debugArchRAT[20]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_20 g=%h i=%h", $time, g_u.debugArchRAT_20, i_u.u_core.debugArchRAT[20]); end
    if (!$isunknown(g_u.debugArchRAT_21) && g_u.debugArchRAT_21 !== i_u.u_core.debugArchRAT[21]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_21 g=%h i=%h", $time, g_u.debugArchRAT_21, i_u.u_core.debugArchRAT[21]); end
    if (!$isunknown(g_u.debugArchRAT_22) && g_u.debugArchRAT_22 !== i_u.u_core.debugArchRAT[22]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_22 g=%h i=%h", $time, g_u.debugArchRAT_22, i_u.u_core.debugArchRAT[22]); end
    if (!$isunknown(g_u.debugArchRAT_23) && g_u.debugArchRAT_23 !== i_u.u_core.debugArchRAT[23]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_23 g=%h i=%h", $time, g_u.debugArchRAT_23, i_u.u_core.debugArchRAT[23]); end
    if (!$isunknown(g_u.debugArchRAT_24) && g_u.debugArchRAT_24 !== i_u.u_core.debugArchRAT[24]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_24 g=%h i=%h", $time, g_u.debugArchRAT_24, i_u.u_core.debugArchRAT[24]); end
    if (!$isunknown(g_u.debugArchRAT_25) && g_u.debugArchRAT_25 !== i_u.u_core.debugArchRAT[25]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_25 g=%h i=%h", $time, g_u.debugArchRAT_25, i_u.u_core.debugArchRAT[25]); end
    if (!$isunknown(g_u.debugArchRAT_26) && g_u.debugArchRAT_26 !== i_u.u_core.debugArchRAT[26]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_26 g=%h i=%h", $time, g_u.debugArchRAT_26, i_u.u_core.debugArchRAT[26]); end
    if (!$isunknown(g_u.debugArchRAT_27) && g_u.debugArchRAT_27 !== i_u.u_core.debugArchRAT[27]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_27 g=%h i=%h", $time, g_u.debugArchRAT_27, i_u.u_core.debugArchRAT[27]); end
    if (!$isunknown(g_u.debugArchRAT_28) && g_u.debugArchRAT_28 !== i_u.u_core.debugArchRAT[28]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_28 g=%h i=%h", $time, g_u.debugArchRAT_28, i_u.u_core.debugArchRAT[28]); end
    if (!$isunknown(g_u.debugArchRAT_29) && g_u.debugArchRAT_29 !== i_u.u_core.debugArchRAT[29]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_29 g=%h i=%h", $time, g_u.debugArchRAT_29, i_u.u_core.debugArchRAT[29]); end
    if (!$isunknown(g_u.debugArchRAT_30) && g_u.debugArchRAT_30 !== i_u.u_core.debugArchRAT[30]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_30 g=%h i=%h", $time, g_u.debugArchRAT_30, i_u.u_core.debugArchRAT[30]); end
    if (!$isunknown(g_u.debugArchRAT_31) && g_u.debugArchRAT_31 !== i_u.u_core.debugArchRAT[31]) begin errors++;
      if(errors<=80) $display("[%0t] debugArchRAT_31 g=%h i=%h", $time, g_u.debugArchRAT_31, i_u.u_core.debugArchRAT[31]); end
  end

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
