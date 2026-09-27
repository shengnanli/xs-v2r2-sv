// ★本文件由 gen_variants.py 生成，改请改生成器★
// StdFreeList_1/_2/_3 三个参数变体的双例化逐拍比对；每个变体一套独立随机激励。
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

  // ================= StdFreeList_1 (SIZE=81, NUM_LOGIC=47, Wen=vecWen) =================
  logic v1_io_redirect;
  logic v1_io_walk;
  logic v1_io_allocateReq_0;
  logic v1_io_allocateReq_1;
  logic v1_io_allocateReq_2;
  logic v1_io_allocateReq_3;
  logic v1_io_allocateReq_4;
  logic v1_io_allocateReq_5;
  logic v1_io_walkReq_0;
  logic v1_io_walkReq_1;
  logic v1_io_walkReq_2;
  logic v1_io_walkReq_3;
  logic v1_io_walkReq_4;
  logic v1_io_walkReq_5;
  logic v1_io_doAllocate;
  logic v1_io_freeReq_0;
  logic v1_io_freeReq_1;
  logic v1_io_freeReq_2;
  logic v1_io_freeReq_3;
  logic v1_io_freeReq_4;
  logic v1_io_freeReq_5;
  logic [7:0] v1_io_freePhyReg_0;
  logic [7:0] v1_io_freePhyReg_1;
  logic [7:0] v1_io_freePhyReg_2;
  logic [7:0] v1_io_freePhyReg_3;
  logic [7:0] v1_io_freePhyReg_4;
  logic [7:0] v1_io_freePhyReg_5;
  logic v1_io_commit_isCommit;
  logic v1_io_commit_commitValid_0;
  logic v1_io_commit_commitValid_1;
  logic v1_io_commit_commitValid_2;
  logic v1_io_commit_commitValid_3;
  logic v1_io_commit_commitValid_4;
  logic v1_io_commit_commitValid_5;
  logic v1_io_commit_info_0_vecWen;
  logic v1_io_commit_info_1_vecWen;
  logic v1_io_commit_info_2_vecWen;
  logic v1_io_commit_info_3_vecWen;
  logic v1_io_commit_info_4_vecWen;
  logic v1_io_commit_info_5_vecWen;
  logic v1_io_snpt_snptEnq;
  logic v1_io_snpt_snptDeq;
  logic v1_io_snpt_useSnpt;
  logic [1:0] v1_io_snpt_snptSelect;
  logic v1_io_snpt_flushVec_0;
  logic v1_io_snpt_flushVec_1;
  logic v1_io_snpt_flushVec_2;
  logic v1_io_snpt_flushVec_3;
  logic [7:0] v1_g_io_allocatePhyReg_0;
  logic [7:0] v1_i_io_allocatePhyReg_0;
  logic [7:0] v1_g_io_allocatePhyReg_1;
  logic [7:0] v1_i_io_allocatePhyReg_1;
  logic [7:0] v1_g_io_allocatePhyReg_2;
  logic [7:0] v1_i_io_allocatePhyReg_2;
  logic [7:0] v1_g_io_allocatePhyReg_3;
  logic [7:0] v1_i_io_allocatePhyReg_3;
  logic [7:0] v1_g_io_allocatePhyReg_4;
  logic [7:0] v1_i_io_allocatePhyReg_4;
  logic [7:0] v1_g_io_allocatePhyReg_5;
  logic [7:0] v1_i_io_allocatePhyReg_5;
  logic v1_g_io_canAllocate;
  logic v1_i_io_canAllocate;
  logic [5:0] v1_g_io_perf_0_value;
  logic [5:0] v1_i_io_perf_0_value;
  logic [5:0] v1_g_io_perf_1_value;
  logic [5:0] v1_i_io_perf_1_value;
  logic [5:0] v1_g_io_perf_2_value;
  logic [5:0] v1_i_io_perf_2_value;
  logic [5:0] v1_g_io_perf_3_value;
  logic [5:0] v1_i_io_perf_3_value;
  StdFreeList_1 v1_g (.clock(clk), .reset(rst), .io_redirect(v1_io_redirect), .io_walk(v1_io_walk), .io_allocateReq_0(v1_io_allocateReq_0), .io_allocateReq_1(v1_io_allocateReq_1), .io_allocateReq_2(v1_io_allocateReq_2), .io_allocateReq_3(v1_io_allocateReq_3), .io_allocateReq_4(v1_io_allocateReq_4), .io_allocateReq_5(v1_io_allocateReq_5), .io_walkReq_0(v1_io_walkReq_0), .io_walkReq_1(v1_io_walkReq_1), .io_walkReq_2(v1_io_walkReq_2), .io_walkReq_3(v1_io_walkReq_3), .io_walkReq_4(v1_io_walkReq_4), .io_walkReq_5(v1_io_walkReq_5), .io_doAllocate(v1_io_doAllocate), .io_freeReq_0(v1_io_freeReq_0), .io_freeReq_1(v1_io_freeReq_1), .io_freeReq_2(v1_io_freeReq_2), .io_freeReq_3(v1_io_freeReq_3), .io_freeReq_4(v1_io_freeReq_4), .io_freeReq_5(v1_io_freeReq_5), .io_freePhyReg_0(v1_io_freePhyReg_0), .io_freePhyReg_1(v1_io_freePhyReg_1), .io_freePhyReg_2(v1_io_freePhyReg_2), .io_freePhyReg_3(v1_io_freePhyReg_3), .io_freePhyReg_4(v1_io_freePhyReg_4), .io_freePhyReg_5(v1_io_freePhyReg_5), .io_commit_isCommit(v1_io_commit_isCommit), .io_commit_commitValid_0(v1_io_commit_commitValid_0), .io_commit_commitValid_1(v1_io_commit_commitValid_1), .io_commit_commitValid_2(v1_io_commit_commitValid_2), .io_commit_commitValid_3(v1_io_commit_commitValid_3), .io_commit_commitValid_4(v1_io_commit_commitValid_4), .io_commit_commitValid_5(v1_io_commit_commitValid_5), .io_commit_info_0_vecWen(v1_io_commit_info_0_vecWen), .io_commit_info_1_vecWen(v1_io_commit_info_1_vecWen), .io_commit_info_2_vecWen(v1_io_commit_info_2_vecWen), .io_commit_info_3_vecWen(v1_io_commit_info_3_vecWen), .io_commit_info_4_vecWen(v1_io_commit_info_4_vecWen), .io_commit_info_5_vecWen(v1_io_commit_info_5_vecWen), .io_snpt_snptEnq(v1_io_snpt_snptEnq), .io_snpt_snptDeq(v1_io_snpt_snptDeq), .io_snpt_useSnpt(v1_io_snpt_useSnpt), .io_snpt_snptSelect(v1_io_snpt_snptSelect), .io_snpt_flushVec_0(v1_io_snpt_flushVec_0), .io_snpt_flushVec_1(v1_io_snpt_flushVec_1), .io_snpt_flushVec_2(v1_io_snpt_flushVec_2), .io_snpt_flushVec_3(v1_io_snpt_flushVec_3), .io_allocatePhyReg_0(v1_g_io_allocatePhyReg_0), .io_allocatePhyReg_1(v1_g_io_allocatePhyReg_1), .io_allocatePhyReg_2(v1_g_io_allocatePhyReg_2), .io_allocatePhyReg_3(v1_g_io_allocatePhyReg_3), .io_allocatePhyReg_4(v1_g_io_allocatePhyReg_4), .io_allocatePhyReg_5(v1_g_io_allocatePhyReg_5), .io_canAllocate(v1_g_io_canAllocate), .io_perf_0_value(v1_g_io_perf_0_value), .io_perf_1_value(v1_g_io_perf_1_value), .io_perf_2_value(v1_g_io_perf_2_value), .io_perf_3_value(v1_g_io_perf_3_value));
  StdFreeList_1_xs v1_i (.clock(clk), .reset(rst), .io_redirect(v1_io_redirect), .io_walk(v1_io_walk), .io_allocateReq_0(v1_io_allocateReq_0), .io_allocateReq_1(v1_io_allocateReq_1), .io_allocateReq_2(v1_io_allocateReq_2), .io_allocateReq_3(v1_io_allocateReq_3), .io_allocateReq_4(v1_io_allocateReq_4), .io_allocateReq_5(v1_io_allocateReq_5), .io_walkReq_0(v1_io_walkReq_0), .io_walkReq_1(v1_io_walkReq_1), .io_walkReq_2(v1_io_walkReq_2), .io_walkReq_3(v1_io_walkReq_3), .io_walkReq_4(v1_io_walkReq_4), .io_walkReq_5(v1_io_walkReq_5), .io_doAllocate(v1_io_doAllocate), .io_freeReq_0(v1_io_freeReq_0), .io_freeReq_1(v1_io_freeReq_1), .io_freeReq_2(v1_io_freeReq_2), .io_freeReq_3(v1_io_freeReq_3), .io_freeReq_4(v1_io_freeReq_4), .io_freeReq_5(v1_io_freeReq_5), .io_freePhyReg_0(v1_io_freePhyReg_0), .io_freePhyReg_1(v1_io_freePhyReg_1), .io_freePhyReg_2(v1_io_freePhyReg_2), .io_freePhyReg_3(v1_io_freePhyReg_3), .io_freePhyReg_4(v1_io_freePhyReg_4), .io_freePhyReg_5(v1_io_freePhyReg_5), .io_commit_isCommit(v1_io_commit_isCommit), .io_commit_commitValid_0(v1_io_commit_commitValid_0), .io_commit_commitValid_1(v1_io_commit_commitValid_1), .io_commit_commitValid_2(v1_io_commit_commitValid_2), .io_commit_commitValid_3(v1_io_commit_commitValid_3), .io_commit_commitValid_4(v1_io_commit_commitValid_4), .io_commit_commitValid_5(v1_io_commit_commitValid_5), .io_commit_info_0_vecWen(v1_io_commit_info_0_vecWen), .io_commit_info_1_vecWen(v1_io_commit_info_1_vecWen), .io_commit_info_2_vecWen(v1_io_commit_info_2_vecWen), .io_commit_info_3_vecWen(v1_io_commit_info_3_vecWen), .io_commit_info_4_vecWen(v1_io_commit_info_4_vecWen), .io_commit_info_5_vecWen(v1_io_commit_info_5_vecWen), .io_snpt_snptEnq(v1_io_snpt_snptEnq), .io_snpt_snptDeq(v1_io_snpt_snptDeq), .io_snpt_useSnpt(v1_io_snpt_useSnpt), .io_snpt_snptSelect(v1_io_snpt_snptSelect), .io_snpt_flushVec_0(v1_io_snpt_flushVec_0), .io_snpt_flushVec_1(v1_io_snpt_flushVec_1), .io_snpt_flushVec_2(v1_io_snpt_flushVec_2), .io_snpt_flushVec_3(v1_io_snpt_flushVec_3), .io_allocatePhyReg_0(v1_i_io_allocatePhyReg_0), .io_allocatePhyReg_1(v1_i_io_allocatePhyReg_1), .io_allocatePhyReg_2(v1_i_io_allocatePhyReg_2), .io_allocatePhyReg_3(v1_i_io_allocatePhyReg_3), .io_allocatePhyReg_4(v1_i_io_allocatePhyReg_4), .io_allocatePhyReg_5(v1_i_io_allocatePhyReg_5), .io_canAllocate(v1_i_io_canAllocate), .io_perf_0_value(v1_i_io_perf_0_value), .io_perf_1_value(v1_i_io_perf_1_value), .io_perf_2_value(v1_i_io_perf_2_value), .io_perf_3_value(v1_i_io_perf_3_value));

  // 回收的物理号取本变体池的合法域 [47, 127]
  function automatic logic [7:0] v1_rnd_preg(); return 8'(47 + $urandom_range(0,80)); endfunction
  always @(negedge clk) begin
    if (rst) begin
      v1_io_redirect <= 0;
      v1_io_walk <= 0;
      v1_io_allocateReq_0 <= 0;
      v1_io_allocateReq_1 <= 0;
      v1_io_allocateReq_2 <= 0;
      v1_io_allocateReq_3 <= 0;
      v1_io_allocateReq_4 <= 0;
      v1_io_allocateReq_5 <= 0;
      v1_io_walkReq_0 <= 0;
      v1_io_walkReq_1 <= 0;
      v1_io_walkReq_2 <= 0;
      v1_io_walkReq_3 <= 0;
      v1_io_walkReq_4 <= 0;
      v1_io_walkReq_5 <= 0;
      v1_io_doAllocate <= 0;
      v1_io_freeReq_0 <= 0;
      v1_io_freeReq_1 <= 0;
      v1_io_freeReq_2 <= 0;
      v1_io_freeReq_3 <= 0;
      v1_io_freeReq_4 <= 0;
      v1_io_freeReq_5 <= 0;
      v1_io_freePhyReg_0 <= 0;
      v1_io_freePhyReg_1 <= 0;
      v1_io_freePhyReg_2 <= 0;
      v1_io_freePhyReg_3 <= 0;
      v1_io_freePhyReg_4 <= 0;
      v1_io_freePhyReg_5 <= 0;
      v1_io_commit_isCommit <= 0;
      v1_io_commit_commitValid_0 <= 0;
      v1_io_commit_commitValid_1 <= 0;
      v1_io_commit_commitValid_2 <= 0;
      v1_io_commit_commitValid_3 <= 0;
      v1_io_commit_commitValid_4 <= 0;
      v1_io_commit_commitValid_5 <= 0;
      v1_io_commit_info_0_vecWen <= 0;
      v1_io_commit_info_1_vecWen <= 0;
      v1_io_commit_info_2_vecWen <= 0;
      v1_io_commit_info_3_vecWen <= 0;
      v1_io_commit_info_4_vecWen <= 0;
      v1_io_commit_info_5_vecWen <= 0;
      v1_io_snpt_snptEnq <= 0;
      v1_io_snpt_snptDeq <= 0;
      v1_io_snpt_useSnpt <= 0;
      v1_io_snpt_snptSelect <= 0;
      v1_io_snpt_flushVec_0 <= 0;
      v1_io_snpt_flushVec_1 <= 0;
      v1_io_snpt_flushVec_2 <= 0;
      v1_io_snpt_flushVec_3 <= 0;
    end else begin
      v1_io_redirect <= (cyc < WARM_CYCLES) ? 1'b0 : ($urandom_range(0,99) < 3);
      v1_io_walk     <= ($urandom_range(0,99) < 25);
      v1_io_doAllocate <= $urandom_range(0,1);
      v1_io_allocateReq_0 <= $urandom_range(0,1);
      v1_io_walkReq_0 <= $urandom_range(0,1);
      v1_io_freeReq_0 <= ($urandom_range(0,99)<30);
      v1_io_freePhyReg_0 <= v1_rnd_preg();
      v1_io_commit_commitValid_0 <= $urandom_range(0,1);
      v1_io_commit_info_0_vecWen <= $urandom_range(0,1);
      v1_io_allocateReq_1 <= $urandom_range(0,1);
      v1_io_walkReq_1 <= $urandom_range(0,1);
      v1_io_freeReq_1 <= ($urandom_range(0,99)<30);
      v1_io_freePhyReg_1 <= v1_rnd_preg();
      v1_io_commit_commitValid_1 <= $urandom_range(0,1);
      v1_io_commit_info_1_vecWen <= $urandom_range(0,1);
      v1_io_allocateReq_2 <= $urandom_range(0,1);
      v1_io_walkReq_2 <= $urandom_range(0,1);
      v1_io_freeReq_2 <= ($urandom_range(0,99)<30);
      v1_io_freePhyReg_2 <= v1_rnd_preg();
      v1_io_commit_commitValid_2 <= $urandom_range(0,1);
      v1_io_commit_info_2_vecWen <= $urandom_range(0,1);
      v1_io_allocateReq_3 <= $urandom_range(0,1);
      v1_io_walkReq_3 <= $urandom_range(0,1);
      v1_io_freeReq_3 <= ($urandom_range(0,99)<30);
      v1_io_freePhyReg_3 <= v1_rnd_preg();
      v1_io_commit_commitValid_3 <= $urandom_range(0,1);
      v1_io_commit_info_3_vecWen <= $urandom_range(0,1);
      v1_io_allocateReq_4 <= $urandom_range(0,1);
      v1_io_walkReq_4 <= $urandom_range(0,1);
      v1_io_freeReq_4 <= ($urandom_range(0,99)<30);
      v1_io_freePhyReg_4 <= v1_rnd_preg();
      v1_io_commit_commitValid_4 <= $urandom_range(0,1);
      v1_io_commit_info_4_vecWen <= $urandom_range(0,1);
      v1_io_allocateReq_5 <= $urandom_range(0,1);
      v1_io_walkReq_5 <= $urandom_range(0,1);
      v1_io_freeReq_5 <= ($urandom_range(0,99)<30);
      v1_io_freePhyReg_5 <= v1_rnd_preg();
      v1_io_commit_commitValid_5 <= $urandom_range(0,1);
      v1_io_commit_info_5_vecWen <= $urandom_range(0,1);
      v1_io_commit_isCommit <= $urandom_range(0,1);
      if (cyc < WARM_CYCLES) begin
        v1_io_snpt_snptEnq <= 1'b1; v1_io_snpt_snptDeq <= 1'b0;
        v1_io_snpt_useSnpt <= 1'b0; v1_io_snpt_snptSelect <= 2'd0;
      end else begin
        v1_io_snpt_snptEnq <= ($urandom_range(0,99)<15); v1_io_snpt_snptDeq <= ($urandom_range(0,99)<15);
        v1_io_snpt_useSnpt <= $urandom_range(0,1); v1_io_snpt_snptSelect <= $urandom_range(0,3);
      end
      v1_io_snpt_flushVec_0 <= ($urandom_range(0,99)<5);
      v1_io_snpt_flushVec_1 <= ($urandom_range(0,99)<5);
      v1_io_snpt_flushVec_2 <= ($urandom_range(0,99)<5);
      v1_io_snpt_flushVec_3 <= ($urandom_range(0,99)<5);
    end
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(v1_g_io_allocatePhyReg_0) && v1_g_io_allocatePhyReg_0 !== v1_i_io_allocatePhyReg_0) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_1 io_allocatePhyReg_0 g=%h i=%h", $time, v1_g_io_allocatePhyReg_0, v1_i_io_allocatePhyReg_0); end
    if (!$isunknown(v1_g_io_allocatePhyReg_1) && v1_g_io_allocatePhyReg_1 !== v1_i_io_allocatePhyReg_1) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_1 io_allocatePhyReg_1 g=%h i=%h", $time, v1_g_io_allocatePhyReg_1, v1_i_io_allocatePhyReg_1); end
    if (!$isunknown(v1_g_io_allocatePhyReg_2) && v1_g_io_allocatePhyReg_2 !== v1_i_io_allocatePhyReg_2) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_1 io_allocatePhyReg_2 g=%h i=%h", $time, v1_g_io_allocatePhyReg_2, v1_i_io_allocatePhyReg_2); end
    if (!$isunknown(v1_g_io_allocatePhyReg_3) && v1_g_io_allocatePhyReg_3 !== v1_i_io_allocatePhyReg_3) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_1 io_allocatePhyReg_3 g=%h i=%h", $time, v1_g_io_allocatePhyReg_3, v1_i_io_allocatePhyReg_3); end
    if (!$isunknown(v1_g_io_allocatePhyReg_4) && v1_g_io_allocatePhyReg_4 !== v1_i_io_allocatePhyReg_4) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_1 io_allocatePhyReg_4 g=%h i=%h", $time, v1_g_io_allocatePhyReg_4, v1_i_io_allocatePhyReg_4); end
    if (!$isunknown(v1_g_io_allocatePhyReg_5) && v1_g_io_allocatePhyReg_5 !== v1_i_io_allocatePhyReg_5) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_1 io_allocatePhyReg_5 g=%h i=%h", $time, v1_g_io_allocatePhyReg_5, v1_i_io_allocatePhyReg_5); end
    if (!$isunknown(v1_g_io_canAllocate) && v1_g_io_canAllocate !== v1_i_io_canAllocate) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_1 io_canAllocate g=%h i=%h", $time, v1_g_io_canAllocate, v1_i_io_canAllocate); end
    if (!$isunknown(v1_g_io_perf_0_value) && v1_g_io_perf_0_value !== v1_i_io_perf_0_value) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_1 io_perf_0_value g=%h i=%h", $time, v1_g_io_perf_0_value, v1_i_io_perf_0_value); end
    if (!$isunknown(v1_g_io_perf_1_value) && v1_g_io_perf_1_value !== v1_i_io_perf_1_value) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_1 io_perf_1_value g=%h i=%h", $time, v1_g_io_perf_1_value, v1_i_io_perf_1_value); end
    if (!$isunknown(v1_g_io_perf_2_value) && v1_g_io_perf_2_value !== v1_i_io_perf_2_value) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_1 io_perf_2_value g=%h i=%h", $time, v1_g_io_perf_2_value, v1_i_io_perf_2_value); end
    if (!$isunknown(v1_g_io_perf_3_value) && v1_g_io_perf_3_value !== v1_i_io_perf_3_value) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_1 io_perf_3_value g=%h i=%h", $time, v1_g_io_perf_3_value, v1_i_io_perf_3_value); end
    // 内部指针探针：golden 展平名 vs 核里的 struct(golden 的 shiftAmount 就是 headPtr.value)
    if (!$isunknown(v1_g.headPtr_flag)) begin
      if (v1_g.headPtr_flag !== v1_i.u_core.headPtr.flag) begin errors++;
        if(errors<=80) $display("[%0t] StdFreeList_1 headPtr.flag g=%h i=%h", $time, v1_g.headPtr_flag, v1_i.u_core.headPtr.flag); end
      if (v1_g.shiftAmount !== v1_i.u_core.headPtr.value) begin errors++;
        if(errors<=80) $display("[%0t] StdFreeList_1 headPtr.value g=%h i=%h", $time, v1_g.shiftAmount, v1_i.u_core.headPtr.value); end
    end
    if (!$isunknown(v1_g.archHeadPtr_flag)) begin
      if (v1_g.archHeadPtr_flag !== v1_i.u_core.archHeadPtr.flag) begin errors++;
        if(errors<=80) $display("[%0t] StdFreeList_1 archHeadPtr.flag g=%h i=%h", $time, v1_g.archHeadPtr_flag, v1_i.u_core.archHeadPtr.flag); end
      if (v1_g.archHeadPtr_value !== v1_i.u_core.archHeadPtr.value) begin errors++;
        if(errors<=80) $display("[%0t] StdFreeList_1 archHeadPtr.value g=%h i=%h", $time, v1_g.archHeadPtr_value, v1_i.u_core.archHeadPtr.value); end
    end
    if (!$isunknown(v1_g.lastTailPtr_flag)) begin
      if (v1_g.lastTailPtr_flag !== v1_i.u_core.lastTailPtr.flag) begin errors++;
        if(errors<=80) $display("[%0t] StdFreeList_1 lastTailPtr.flag g=%h i=%h", $time, v1_g.lastTailPtr_flag, v1_i.u_core.lastTailPtr.flag); end
      if (v1_g.lastTailPtr_value !== v1_i.u_core.lastTailPtr.value) begin errors++;
        if(errors<=80) $display("[%0t] StdFreeList_1 lastTailPtr.value g=%h i=%h", $time, v1_g.lastTailPtr_value, v1_i.u_core.lastTailPtr.value); end
    end
  end

  // ================= StdFreeList_2 (SIZE=21, NUM_LOGIC=1, Wen=v0Wen) =================
  logic v2_io_redirect;
  logic v2_io_walk;
  logic v2_io_allocateReq_0;
  logic v2_io_allocateReq_1;
  logic v2_io_allocateReq_2;
  logic v2_io_allocateReq_3;
  logic v2_io_allocateReq_4;
  logic v2_io_allocateReq_5;
  logic v2_io_walkReq_0;
  logic v2_io_walkReq_1;
  logic v2_io_walkReq_2;
  logic v2_io_walkReq_3;
  logic v2_io_walkReq_4;
  logic v2_io_walkReq_5;
  logic v2_io_doAllocate;
  logic v2_io_freeReq_0;
  logic v2_io_freeReq_1;
  logic v2_io_freeReq_2;
  logic v2_io_freeReq_3;
  logic v2_io_freeReq_4;
  logic v2_io_freeReq_5;
  logic [7:0] v2_io_freePhyReg_0;
  logic [7:0] v2_io_freePhyReg_1;
  logic [7:0] v2_io_freePhyReg_2;
  logic [7:0] v2_io_freePhyReg_3;
  logic [7:0] v2_io_freePhyReg_4;
  logic [7:0] v2_io_freePhyReg_5;
  logic v2_io_commit_isCommit;
  logic v2_io_commit_commitValid_0;
  logic v2_io_commit_commitValid_1;
  logic v2_io_commit_commitValid_2;
  logic v2_io_commit_commitValid_3;
  logic v2_io_commit_commitValid_4;
  logic v2_io_commit_commitValid_5;
  logic v2_io_commit_info_0_v0Wen;
  logic v2_io_commit_info_1_v0Wen;
  logic v2_io_commit_info_2_v0Wen;
  logic v2_io_commit_info_3_v0Wen;
  logic v2_io_commit_info_4_v0Wen;
  logic v2_io_commit_info_5_v0Wen;
  logic v2_io_snpt_snptEnq;
  logic v2_io_snpt_snptDeq;
  logic v2_io_snpt_useSnpt;
  logic [1:0] v2_io_snpt_snptSelect;
  logic v2_io_snpt_flushVec_0;
  logic v2_io_snpt_flushVec_1;
  logic v2_io_snpt_flushVec_2;
  logic v2_io_snpt_flushVec_3;
  logic [7:0] v2_g_io_allocatePhyReg_0;
  logic [7:0] v2_i_io_allocatePhyReg_0;
  logic [7:0] v2_g_io_allocatePhyReg_1;
  logic [7:0] v2_i_io_allocatePhyReg_1;
  logic [7:0] v2_g_io_allocatePhyReg_2;
  logic [7:0] v2_i_io_allocatePhyReg_2;
  logic [7:0] v2_g_io_allocatePhyReg_3;
  logic [7:0] v2_i_io_allocatePhyReg_3;
  logic [7:0] v2_g_io_allocatePhyReg_4;
  logic [7:0] v2_i_io_allocatePhyReg_4;
  logic [7:0] v2_g_io_allocatePhyReg_5;
  logic [7:0] v2_i_io_allocatePhyReg_5;
  logic v2_g_io_canAllocate;
  logic v2_i_io_canAllocate;
  logic [5:0] v2_g_io_perf_0_value;
  logic [5:0] v2_i_io_perf_0_value;
  logic [5:0] v2_g_io_perf_1_value;
  logic [5:0] v2_i_io_perf_1_value;
  logic [5:0] v2_g_io_perf_2_value;
  logic [5:0] v2_i_io_perf_2_value;
  logic [5:0] v2_g_io_perf_3_value;
  logic [5:0] v2_i_io_perf_3_value;
  StdFreeList_2 v2_g (.clock(clk), .reset(rst), .io_redirect(v2_io_redirect), .io_walk(v2_io_walk), .io_allocateReq_0(v2_io_allocateReq_0), .io_allocateReq_1(v2_io_allocateReq_1), .io_allocateReq_2(v2_io_allocateReq_2), .io_allocateReq_3(v2_io_allocateReq_3), .io_allocateReq_4(v2_io_allocateReq_4), .io_allocateReq_5(v2_io_allocateReq_5), .io_walkReq_0(v2_io_walkReq_0), .io_walkReq_1(v2_io_walkReq_1), .io_walkReq_2(v2_io_walkReq_2), .io_walkReq_3(v2_io_walkReq_3), .io_walkReq_4(v2_io_walkReq_4), .io_walkReq_5(v2_io_walkReq_5), .io_doAllocate(v2_io_doAllocate), .io_freeReq_0(v2_io_freeReq_0), .io_freeReq_1(v2_io_freeReq_1), .io_freeReq_2(v2_io_freeReq_2), .io_freeReq_3(v2_io_freeReq_3), .io_freeReq_4(v2_io_freeReq_4), .io_freeReq_5(v2_io_freeReq_5), .io_freePhyReg_0(v2_io_freePhyReg_0), .io_freePhyReg_1(v2_io_freePhyReg_1), .io_freePhyReg_2(v2_io_freePhyReg_2), .io_freePhyReg_3(v2_io_freePhyReg_3), .io_freePhyReg_4(v2_io_freePhyReg_4), .io_freePhyReg_5(v2_io_freePhyReg_5), .io_commit_isCommit(v2_io_commit_isCommit), .io_commit_commitValid_0(v2_io_commit_commitValid_0), .io_commit_commitValid_1(v2_io_commit_commitValid_1), .io_commit_commitValid_2(v2_io_commit_commitValid_2), .io_commit_commitValid_3(v2_io_commit_commitValid_3), .io_commit_commitValid_4(v2_io_commit_commitValid_4), .io_commit_commitValid_5(v2_io_commit_commitValid_5), .io_commit_info_0_v0Wen(v2_io_commit_info_0_v0Wen), .io_commit_info_1_v0Wen(v2_io_commit_info_1_v0Wen), .io_commit_info_2_v0Wen(v2_io_commit_info_2_v0Wen), .io_commit_info_3_v0Wen(v2_io_commit_info_3_v0Wen), .io_commit_info_4_v0Wen(v2_io_commit_info_4_v0Wen), .io_commit_info_5_v0Wen(v2_io_commit_info_5_v0Wen), .io_snpt_snptEnq(v2_io_snpt_snptEnq), .io_snpt_snptDeq(v2_io_snpt_snptDeq), .io_snpt_useSnpt(v2_io_snpt_useSnpt), .io_snpt_snptSelect(v2_io_snpt_snptSelect), .io_snpt_flushVec_0(v2_io_snpt_flushVec_0), .io_snpt_flushVec_1(v2_io_snpt_flushVec_1), .io_snpt_flushVec_2(v2_io_snpt_flushVec_2), .io_snpt_flushVec_3(v2_io_snpt_flushVec_3), .io_allocatePhyReg_0(v2_g_io_allocatePhyReg_0), .io_allocatePhyReg_1(v2_g_io_allocatePhyReg_1), .io_allocatePhyReg_2(v2_g_io_allocatePhyReg_2), .io_allocatePhyReg_3(v2_g_io_allocatePhyReg_3), .io_allocatePhyReg_4(v2_g_io_allocatePhyReg_4), .io_allocatePhyReg_5(v2_g_io_allocatePhyReg_5), .io_canAllocate(v2_g_io_canAllocate), .io_perf_0_value(v2_g_io_perf_0_value), .io_perf_1_value(v2_g_io_perf_1_value), .io_perf_2_value(v2_g_io_perf_2_value), .io_perf_3_value(v2_g_io_perf_3_value));
  StdFreeList_2_xs v2_i (.clock(clk), .reset(rst), .io_redirect(v2_io_redirect), .io_walk(v2_io_walk), .io_allocateReq_0(v2_io_allocateReq_0), .io_allocateReq_1(v2_io_allocateReq_1), .io_allocateReq_2(v2_io_allocateReq_2), .io_allocateReq_3(v2_io_allocateReq_3), .io_allocateReq_4(v2_io_allocateReq_4), .io_allocateReq_5(v2_io_allocateReq_5), .io_walkReq_0(v2_io_walkReq_0), .io_walkReq_1(v2_io_walkReq_1), .io_walkReq_2(v2_io_walkReq_2), .io_walkReq_3(v2_io_walkReq_3), .io_walkReq_4(v2_io_walkReq_4), .io_walkReq_5(v2_io_walkReq_5), .io_doAllocate(v2_io_doAllocate), .io_freeReq_0(v2_io_freeReq_0), .io_freeReq_1(v2_io_freeReq_1), .io_freeReq_2(v2_io_freeReq_2), .io_freeReq_3(v2_io_freeReq_3), .io_freeReq_4(v2_io_freeReq_4), .io_freeReq_5(v2_io_freeReq_5), .io_freePhyReg_0(v2_io_freePhyReg_0), .io_freePhyReg_1(v2_io_freePhyReg_1), .io_freePhyReg_2(v2_io_freePhyReg_2), .io_freePhyReg_3(v2_io_freePhyReg_3), .io_freePhyReg_4(v2_io_freePhyReg_4), .io_freePhyReg_5(v2_io_freePhyReg_5), .io_commit_isCommit(v2_io_commit_isCommit), .io_commit_commitValid_0(v2_io_commit_commitValid_0), .io_commit_commitValid_1(v2_io_commit_commitValid_1), .io_commit_commitValid_2(v2_io_commit_commitValid_2), .io_commit_commitValid_3(v2_io_commit_commitValid_3), .io_commit_commitValid_4(v2_io_commit_commitValid_4), .io_commit_commitValid_5(v2_io_commit_commitValid_5), .io_commit_info_0_v0Wen(v2_io_commit_info_0_v0Wen), .io_commit_info_1_v0Wen(v2_io_commit_info_1_v0Wen), .io_commit_info_2_v0Wen(v2_io_commit_info_2_v0Wen), .io_commit_info_3_v0Wen(v2_io_commit_info_3_v0Wen), .io_commit_info_4_v0Wen(v2_io_commit_info_4_v0Wen), .io_commit_info_5_v0Wen(v2_io_commit_info_5_v0Wen), .io_snpt_snptEnq(v2_io_snpt_snptEnq), .io_snpt_snptDeq(v2_io_snpt_snptDeq), .io_snpt_useSnpt(v2_io_snpt_useSnpt), .io_snpt_snptSelect(v2_io_snpt_snptSelect), .io_snpt_flushVec_0(v2_io_snpt_flushVec_0), .io_snpt_flushVec_1(v2_io_snpt_flushVec_1), .io_snpt_flushVec_2(v2_io_snpt_flushVec_2), .io_snpt_flushVec_3(v2_io_snpt_flushVec_3), .io_allocatePhyReg_0(v2_i_io_allocatePhyReg_0), .io_allocatePhyReg_1(v2_i_io_allocatePhyReg_1), .io_allocatePhyReg_2(v2_i_io_allocatePhyReg_2), .io_allocatePhyReg_3(v2_i_io_allocatePhyReg_3), .io_allocatePhyReg_4(v2_i_io_allocatePhyReg_4), .io_allocatePhyReg_5(v2_i_io_allocatePhyReg_5), .io_canAllocate(v2_i_io_canAllocate), .io_perf_0_value(v2_i_io_perf_0_value), .io_perf_1_value(v2_i_io_perf_1_value), .io_perf_2_value(v2_i_io_perf_2_value), .io_perf_3_value(v2_i_io_perf_3_value));

  // 回收的物理号取本变体池的合法域 [1, 21]
  function automatic logic [7:0] v2_rnd_preg(); return 8'(1 + $urandom_range(0,20)); endfunction
  always @(negedge clk) begin
    if (rst) begin
      v2_io_redirect <= 0;
      v2_io_walk <= 0;
      v2_io_allocateReq_0 <= 0;
      v2_io_allocateReq_1 <= 0;
      v2_io_allocateReq_2 <= 0;
      v2_io_allocateReq_3 <= 0;
      v2_io_allocateReq_4 <= 0;
      v2_io_allocateReq_5 <= 0;
      v2_io_walkReq_0 <= 0;
      v2_io_walkReq_1 <= 0;
      v2_io_walkReq_2 <= 0;
      v2_io_walkReq_3 <= 0;
      v2_io_walkReq_4 <= 0;
      v2_io_walkReq_5 <= 0;
      v2_io_doAllocate <= 0;
      v2_io_freeReq_0 <= 0;
      v2_io_freeReq_1 <= 0;
      v2_io_freeReq_2 <= 0;
      v2_io_freeReq_3 <= 0;
      v2_io_freeReq_4 <= 0;
      v2_io_freeReq_5 <= 0;
      v2_io_freePhyReg_0 <= 0;
      v2_io_freePhyReg_1 <= 0;
      v2_io_freePhyReg_2 <= 0;
      v2_io_freePhyReg_3 <= 0;
      v2_io_freePhyReg_4 <= 0;
      v2_io_freePhyReg_5 <= 0;
      v2_io_commit_isCommit <= 0;
      v2_io_commit_commitValid_0 <= 0;
      v2_io_commit_commitValid_1 <= 0;
      v2_io_commit_commitValid_2 <= 0;
      v2_io_commit_commitValid_3 <= 0;
      v2_io_commit_commitValid_4 <= 0;
      v2_io_commit_commitValid_5 <= 0;
      v2_io_commit_info_0_v0Wen <= 0;
      v2_io_commit_info_1_v0Wen <= 0;
      v2_io_commit_info_2_v0Wen <= 0;
      v2_io_commit_info_3_v0Wen <= 0;
      v2_io_commit_info_4_v0Wen <= 0;
      v2_io_commit_info_5_v0Wen <= 0;
      v2_io_snpt_snptEnq <= 0;
      v2_io_snpt_snptDeq <= 0;
      v2_io_snpt_useSnpt <= 0;
      v2_io_snpt_snptSelect <= 0;
      v2_io_snpt_flushVec_0 <= 0;
      v2_io_snpt_flushVec_1 <= 0;
      v2_io_snpt_flushVec_2 <= 0;
      v2_io_snpt_flushVec_3 <= 0;
    end else begin
      v2_io_redirect <= (cyc < WARM_CYCLES) ? 1'b0 : ($urandom_range(0,99) < 3);
      v2_io_walk     <= ($urandom_range(0,99) < 25);
      v2_io_doAllocate <= $urandom_range(0,1);
      v2_io_allocateReq_0 <= $urandom_range(0,1);
      v2_io_walkReq_0 <= $urandom_range(0,1);
      v2_io_freeReq_0 <= ($urandom_range(0,99)<30);
      v2_io_freePhyReg_0 <= v2_rnd_preg();
      v2_io_commit_commitValid_0 <= $urandom_range(0,1);
      v2_io_commit_info_0_v0Wen <= $urandom_range(0,1);
      v2_io_allocateReq_1 <= $urandom_range(0,1);
      v2_io_walkReq_1 <= $urandom_range(0,1);
      v2_io_freeReq_1 <= ($urandom_range(0,99)<30);
      v2_io_freePhyReg_1 <= v2_rnd_preg();
      v2_io_commit_commitValid_1 <= $urandom_range(0,1);
      v2_io_commit_info_1_v0Wen <= $urandom_range(0,1);
      v2_io_allocateReq_2 <= $urandom_range(0,1);
      v2_io_walkReq_2 <= $urandom_range(0,1);
      v2_io_freeReq_2 <= ($urandom_range(0,99)<30);
      v2_io_freePhyReg_2 <= v2_rnd_preg();
      v2_io_commit_commitValid_2 <= $urandom_range(0,1);
      v2_io_commit_info_2_v0Wen <= $urandom_range(0,1);
      v2_io_allocateReq_3 <= $urandom_range(0,1);
      v2_io_walkReq_3 <= $urandom_range(0,1);
      v2_io_freeReq_3 <= ($urandom_range(0,99)<30);
      v2_io_freePhyReg_3 <= v2_rnd_preg();
      v2_io_commit_commitValid_3 <= $urandom_range(0,1);
      v2_io_commit_info_3_v0Wen <= $urandom_range(0,1);
      v2_io_allocateReq_4 <= $urandom_range(0,1);
      v2_io_walkReq_4 <= $urandom_range(0,1);
      v2_io_freeReq_4 <= ($urandom_range(0,99)<30);
      v2_io_freePhyReg_4 <= v2_rnd_preg();
      v2_io_commit_commitValid_4 <= $urandom_range(0,1);
      v2_io_commit_info_4_v0Wen <= $urandom_range(0,1);
      v2_io_allocateReq_5 <= $urandom_range(0,1);
      v2_io_walkReq_5 <= $urandom_range(0,1);
      v2_io_freeReq_5 <= ($urandom_range(0,99)<30);
      v2_io_freePhyReg_5 <= v2_rnd_preg();
      v2_io_commit_commitValid_5 <= $urandom_range(0,1);
      v2_io_commit_info_5_v0Wen <= $urandom_range(0,1);
      v2_io_commit_isCommit <= $urandom_range(0,1);
      if (cyc < WARM_CYCLES) begin
        v2_io_snpt_snptEnq <= 1'b1; v2_io_snpt_snptDeq <= 1'b0;
        v2_io_snpt_useSnpt <= 1'b0; v2_io_snpt_snptSelect <= 2'd0;
      end else begin
        v2_io_snpt_snptEnq <= ($urandom_range(0,99)<15); v2_io_snpt_snptDeq <= ($urandom_range(0,99)<15);
        v2_io_snpt_useSnpt <= $urandom_range(0,1); v2_io_snpt_snptSelect <= $urandom_range(0,3);
      end
      v2_io_snpt_flushVec_0 <= ($urandom_range(0,99)<5);
      v2_io_snpt_flushVec_1 <= ($urandom_range(0,99)<5);
      v2_io_snpt_flushVec_2 <= ($urandom_range(0,99)<5);
      v2_io_snpt_flushVec_3 <= ($urandom_range(0,99)<5);
    end
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(v2_g_io_allocatePhyReg_0) && v2_g_io_allocatePhyReg_0 !== v2_i_io_allocatePhyReg_0) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_2 io_allocatePhyReg_0 g=%h i=%h", $time, v2_g_io_allocatePhyReg_0, v2_i_io_allocatePhyReg_0); end
    if (!$isunknown(v2_g_io_allocatePhyReg_1) && v2_g_io_allocatePhyReg_1 !== v2_i_io_allocatePhyReg_1) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_2 io_allocatePhyReg_1 g=%h i=%h", $time, v2_g_io_allocatePhyReg_1, v2_i_io_allocatePhyReg_1); end
    if (!$isunknown(v2_g_io_allocatePhyReg_2) && v2_g_io_allocatePhyReg_2 !== v2_i_io_allocatePhyReg_2) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_2 io_allocatePhyReg_2 g=%h i=%h", $time, v2_g_io_allocatePhyReg_2, v2_i_io_allocatePhyReg_2); end
    if (!$isunknown(v2_g_io_allocatePhyReg_3) && v2_g_io_allocatePhyReg_3 !== v2_i_io_allocatePhyReg_3) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_2 io_allocatePhyReg_3 g=%h i=%h", $time, v2_g_io_allocatePhyReg_3, v2_i_io_allocatePhyReg_3); end
    if (!$isunknown(v2_g_io_allocatePhyReg_4) && v2_g_io_allocatePhyReg_4 !== v2_i_io_allocatePhyReg_4) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_2 io_allocatePhyReg_4 g=%h i=%h", $time, v2_g_io_allocatePhyReg_4, v2_i_io_allocatePhyReg_4); end
    if (!$isunknown(v2_g_io_allocatePhyReg_5) && v2_g_io_allocatePhyReg_5 !== v2_i_io_allocatePhyReg_5) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_2 io_allocatePhyReg_5 g=%h i=%h", $time, v2_g_io_allocatePhyReg_5, v2_i_io_allocatePhyReg_5); end
    if (!$isunknown(v2_g_io_canAllocate) && v2_g_io_canAllocate !== v2_i_io_canAllocate) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_2 io_canAllocate g=%h i=%h", $time, v2_g_io_canAllocate, v2_i_io_canAllocate); end
    if (!$isunknown(v2_g_io_perf_0_value) && v2_g_io_perf_0_value !== v2_i_io_perf_0_value) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_2 io_perf_0_value g=%h i=%h", $time, v2_g_io_perf_0_value, v2_i_io_perf_0_value); end
    if (!$isunknown(v2_g_io_perf_1_value) && v2_g_io_perf_1_value !== v2_i_io_perf_1_value) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_2 io_perf_1_value g=%h i=%h", $time, v2_g_io_perf_1_value, v2_i_io_perf_1_value); end
    if (!$isunknown(v2_g_io_perf_2_value) && v2_g_io_perf_2_value !== v2_i_io_perf_2_value) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_2 io_perf_2_value g=%h i=%h", $time, v2_g_io_perf_2_value, v2_i_io_perf_2_value); end
    if (!$isunknown(v2_g_io_perf_3_value) && v2_g_io_perf_3_value !== v2_i_io_perf_3_value) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_2 io_perf_3_value g=%h i=%h", $time, v2_g_io_perf_3_value, v2_i_io_perf_3_value); end
    // 内部指针探针：golden 展平名 vs 核里的 struct(golden 的 shiftAmount 就是 headPtr.value)
    if (!$isunknown(v2_g.headPtr_flag)) begin
      if (v2_g.headPtr_flag !== v2_i.u_core.headPtr.flag) begin errors++;
        if(errors<=80) $display("[%0t] StdFreeList_2 headPtr.flag g=%h i=%h", $time, v2_g.headPtr_flag, v2_i.u_core.headPtr.flag); end
      if (v2_g.shiftAmount !== v2_i.u_core.headPtr.value) begin errors++;
        if(errors<=80) $display("[%0t] StdFreeList_2 headPtr.value g=%h i=%h", $time, v2_g.shiftAmount, v2_i.u_core.headPtr.value); end
    end
    if (!$isunknown(v2_g.archHeadPtr_flag)) begin
      if (v2_g.archHeadPtr_flag !== v2_i.u_core.archHeadPtr.flag) begin errors++;
        if(errors<=80) $display("[%0t] StdFreeList_2 archHeadPtr.flag g=%h i=%h", $time, v2_g.archHeadPtr_flag, v2_i.u_core.archHeadPtr.flag); end
      if (v2_g.archHeadPtr_value !== v2_i.u_core.archHeadPtr.value) begin errors++;
        if(errors<=80) $display("[%0t] StdFreeList_2 archHeadPtr.value g=%h i=%h", $time, v2_g.archHeadPtr_value, v2_i.u_core.archHeadPtr.value); end
    end
    if (!$isunknown(v2_g.lastTailPtr_flag)) begin
      if (v2_g.lastTailPtr_flag !== v2_i.u_core.lastTailPtr.flag) begin errors++;
        if(errors<=80) $display("[%0t] StdFreeList_2 lastTailPtr.flag g=%h i=%h", $time, v2_g.lastTailPtr_flag, v2_i.u_core.lastTailPtr.flag); end
      if (v2_g.lastTailPtr_value !== v2_i.u_core.lastTailPtr.value) begin errors++;
        if(errors<=80) $display("[%0t] StdFreeList_2 lastTailPtr.value g=%h i=%h", $time, v2_g.lastTailPtr_value, v2_i.u_core.lastTailPtr.value); end
    end
  end

  // ================= StdFreeList_3 (SIZE=31, NUM_LOGIC=1, Wen=vlWen) =================
  logic v3_io_redirect;
  logic v3_io_walk;
  logic v3_io_allocateReq_0;
  logic v3_io_allocateReq_1;
  logic v3_io_allocateReq_2;
  logic v3_io_allocateReq_3;
  logic v3_io_allocateReq_4;
  logic v3_io_allocateReq_5;
  logic v3_io_walkReq_0;
  logic v3_io_walkReq_1;
  logic v3_io_walkReq_2;
  logic v3_io_walkReq_3;
  logic v3_io_walkReq_4;
  logic v3_io_walkReq_5;
  logic v3_io_doAllocate;
  logic v3_io_freeReq_0;
  logic v3_io_freeReq_1;
  logic v3_io_freeReq_2;
  logic v3_io_freeReq_3;
  logic v3_io_freeReq_4;
  logic v3_io_freeReq_5;
  logic [7:0] v3_io_freePhyReg_0;
  logic [7:0] v3_io_freePhyReg_1;
  logic [7:0] v3_io_freePhyReg_2;
  logic [7:0] v3_io_freePhyReg_3;
  logic [7:0] v3_io_freePhyReg_4;
  logic [7:0] v3_io_freePhyReg_5;
  logic v3_io_commit_isCommit;
  logic v3_io_commit_commitValid_0;
  logic v3_io_commit_commitValid_1;
  logic v3_io_commit_commitValid_2;
  logic v3_io_commit_commitValid_3;
  logic v3_io_commit_commitValid_4;
  logic v3_io_commit_commitValid_5;
  logic v3_io_commit_info_0_vlWen;
  logic v3_io_commit_info_1_vlWen;
  logic v3_io_commit_info_2_vlWen;
  logic v3_io_commit_info_3_vlWen;
  logic v3_io_commit_info_4_vlWen;
  logic v3_io_commit_info_5_vlWen;
  logic v3_io_snpt_snptEnq;
  logic v3_io_snpt_snptDeq;
  logic v3_io_snpt_useSnpt;
  logic [1:0] v3_io_snpt_snptSelect;
  logic v3_io_snpt_flushVec_0;
  logic v3_io_snpt_flushVec_1;
  logic v3_io_snpt_flushVec_2;
  logic v3_io_snpt_flushVec_3;
  logic [7:0] v3_g_io_allocatePhyReg_0;
  logic [7:0] v3_i_io_allocatePhyReg_0;
  logic [7:0] v3_g_io_allocatePhyReg_1;
  logic [7:0] v3_i_io_allocatePhyReg_1;
  logic [7:0] v3_g_io_allocatePhyReg_2;
  logic [7:0] v3_i_io_allocatePhyReg_2;
  logic [7:0] v3_g_io_allocatePhyReg_3;
  logic [7:0] v3_i_io_allocatePhyReg_3;
  logic [7:0] v3_g_io_allocatePhyReg_4;
  logic [7:0] v3_i_io_allocatePhyReg_4;
  logic [7:0] v3_g_io_allocatePhyReg_5;
  logic [7:0] v3_i_io_allocatePhyReg_5;
  logic v3_g_io_canAllocate;
  logic v3_i_io_canAllocate;
  logic [5:0] v3_g_io_perf_0_value;
  logic [5:0] v3_i_io_perf_0_value;
  logic [5:0] v3_g_io_perf_1_value;
  logic [5:0] v3_i_io_perf_1_value;
  logic [5:0] v3_g_io_perf_2_value;
  logic [5:0] v3_i_io_perf_2_value;
  logic [5:0] v3_g_io_perf_3_value;
  logic [5:0] v3_i_io_perf_3_value;
  StdFreeList_3 v3_g (.clock(clk), .reset(rst), .io_redirect(v3_io_redirect), .io_walk(v3_io_walk), .io_allocateReq_0(v3_io_allocateReq_0), .io_allocateReq_1(v3_io_allocateReq_1), .io_allocateReq_2(v3_io_allocateReq_2), .io_allocateReq_3(v3_io_allocateReq_3), .io_allocateReq_4(v3_io_allocateReq_4), .io_allocateReq_5(v3_io_allocateReq_5), .io_walkReq_0(v3_io_walkReq_0), .io_walkReq_1(v3_io_walkReq_1), .io_walkReq_2(v3_io_walkReq_2), .io_walkReq_3(v3_io_walkReq_3), .io_walkReq_4(v3_io_walkReq_4), .io_walkReq_5(v3_io_walkReq_5), .io_doAllocate(v3_io_doAllocate), .io_freeReq_0(v3_io_freeReq_0), .io_freeReq_1(v3_io_freeReq_1), .io_freeReq_2(v3_io_freeReq_2), .io_freeReq_3(v3_io_freeReq_3), .io_freeReq_4(v3_io_freeReq_4), .io_freeReq_5(v3_io_freeReq_5), .io_freePhyReg_0(v3_io_freePhyReg_0), .io_freePhyReg_1(v3_io_freePhyReg_1), .io_freePhyReg_2(v3_io_freePhyReg_2), .io_freePhyReg_3(v3_io_freePhyReg_3), .io_freePhyReg_4(v3_io_freePhyReg_4), .io_freePhyReg_5(v3_io_freePhyReg_5), .io_commit_isCommit(v3_io_commit_isCommit), .io_commit_commitValid_0(v3_io_commit_commitValid_0), .io_commit_commitValid_1(v3_io_commit_commitValid_1), .io_commit_commitValid_2(v3_io_commit_commitValid_2), .io_commit_commitValid_3(v3_io_commit_commitValid_3), .io_commit_commitValid_4(v3_io_commit_commitValid_4), .io_commit_commitValid_5(v3_io_commit_commitValid_5), .io_commit_info_0_vlWen(v3_io_commit_info_0_vlWen), .io_commit_info_1_vlWen(v3_io_commit_info_1_vlWen), .io_commit_info_2_vlWen(v3_io_commit_info_2_vlWen), .io_commit_info_3_vlWen(v3_io_commit_info_3_vlWen), .io_commit_info_4_vlWen(v3_io_commit_info_4_vlWen), .io_commit_info_5_vlWen(v3_io_commit_info_5_vlWen), .io_snpt_snptEnq(v3_io_snpt_snptEnq), .io_snpt_snptDeq(v3_io_snpt_snptDeq), .io_snpt_useSnpt(v3_io_snpt_useSnpt), .io_snpt_snptSelect(v3_io_snpt_snptSelect), .io_snpt_flushVec_0(v3_io_snpt_flushVec_0), .io_snpt_flushVec_1(v3_io_snpt_flushVec_1), .io_snpt_flushVec_2(v3_io_snpt_flushVec_2), .io_snpt_flushVec_3(v3_io_snpt_flushVec_3), .io_allocatePhyReg_0(v3_g_io_allocatePhyReg_0), .io_allocatePhyReg_1(v3_g_io_allocatePhyReg_1), .io_allocatePhyReg_2(v3_g_io_allocatePhyReg_2), .io_allocatePhyReg_3(v3_g_io_allocatePhyReg_3), .io_allocatePhyReg_4(v3_g_io_allocatePhyReg_4), .io_allocatePhyReg_5(v3_g_io_allocatePhyReg_5), .io_canAllocate(v3_g_io_canAllocate), .io_perf_0_value(v3_g_io_perf_0_value), .io_perf_1_value(v3_g_io_perf_1_value), .io_perf_2_value(v3_g_io_perf_2_value), .io_perf_3_value(v3_g_io_perf_3_value));
  StdFreeList_3_xs v3_i (.clock(clk), .reset(rst), .io_redirect(v3_io_redirect), .io_walk(v3_io_walk), .io_allocateReq_0(v3_io_allocateReq_0), .io_allocateReq_1(v3_io_allocateReq_1), .io_allocateReq_2(v3_io_allocateReq_2), .io_allocateReq_3(v3_io_allocateReq_3), .io_allocateReq_4(v3_io_allocateReq_4), .io_allocateReq_5(v3_io_allocateReq_5), .io_walkReq_0(v3_io_walkReq_0), .io_walkReq_1(v3_io_walkReq_1), .io_walkReq_2(v3_io_walkReq_2), .io_walkReq_3(v3_io_walkReq_3), .io_walkReq_4(v3_io_walkReq_4), .io_walkReq_5(v3_io_walkReq_5), .io_doAllocate(v3_io_doAllocate), .io_freeReq_0(v3_io_freeReq_0), .io_freeReq_1(v3_io_freeReq_1), .io_freeReq_2(v3_io_freeReq_2), .io_freeReq_3(v3_io_freeReq_3), .io_freeReq_4(v3_io_freeReq_4), .io_freeReq_5(v3_io_freeReq_5), .io_freePhyReg_0(v3_io_freePhyReg_0), .io_freePhyReg_1(v3_io_freePhyReg_1), .io_freePhyReg_2(v3_io_freePhyReg_2), .io_freePhyReg_3(v3_io_freePhyReg_3), .io_freePhyReg_4(v3_io_freePhyReg_4), .io_freePhyReg_5(v3_io_freePhyReg_5), .io_commit_isCommit(v3_io_commit_isCommit), .io_commit_commitValid_0(v3_io_commit_commitValid_0), .io_commit_commitValid_1(v3_io_commit_commitValid_1), .io_commit_commitValid_2(v3_io_commit_commitValid_2), .io_commit_commitValid_3(v3_io_commit_commitValid_3), .io_commit_commitValid_4(v3_io_commit_commitValid_4), .io_commit_commitValid_5(v3_io_commit_commitValid_5), .io_commit_info_0_vlWen(v3_io_commit_info_0_vlWen), .io_commit_info_1_vlWen(v3_io_commit_info_1_vlWen), .io_commit_info_2_vlWen(v3_io_commit_info_2_vlWen), .io_commit_info_3_vlWen(v3_io_commit_info_3_vlWen), .io_commit_info_4_vlWen(v3_io_commit_info_4_vlWen), .io_commit_info_5_vlWen(v3_io_commit_info_5_vlWen), .io_snpt_snptEnq(v3_io_snpt_snptEnq), .io_snpt_snptDeq(v3_io_snpt_snptDeq), .io_snpt_useSnpt(v3_io_snpt_useSnpt), .io_snpt_snptSelect(v3_io_snpt_snptSelect), .io_snpt_flushVec_0(v3_io_snpt_flushVec_0), .io_snpt_flushVec_1(v3_io_snpt_flushVec_1), .io_snpt_flushVec_2(v3_io_snpt_flushVec_2), .io_snpt_flushVec_3(v3_io_snpt_flushVec_3), .io_allocatePhyReg_0(v3_i_io_allocatePhyReg_0), .io_allocatePhyReg_1(v3_i_io_allocatePhyReg_1), .io_allocatePhyReg_2(v3_i_io_allocatePhyReg_2), .io_allocatePhyReg_3(v3_i_io_allocatePhyReg_3), .io_allocatePhyReg_4(v3_i_io_allocatePhyReg_4), .io_allocatePhyReg_5(v3_i_io_allocatePhyReg_5), .io_canAllocate(v3_i_io_canAllocate), .io_perf_0_value(v3_i_io_perf_0_value), .io_perf_1_value(v3_i_io_perf_1_value), .io_perf_2_value(v3_i_io_perf_2_value), .io_perf_3_value(v3_i_io_perf_3_value));

  // 回收的物理号取本变体池的合法域 [1, 31]
  function automatic logic [7:0] v3_rnd_preg(); return 8'(1 + $urandom_range(0,30)); endfunction
  always @(negedge clk) begin
    if (rst) begin
      v3_io_redirect <= 0;
      v3_io_walk <= 0;
      v3_io_allocateReq_0 <= 0;
      v3_io_allocateReq_1 <= 0;
      v3_io_allocateReq_2 <= 0;
      v3_io_allocateReq_3 <= 0;
      v3_io_allocateReq_4 <= 0;
      v3_io_allocateReq_5 <= 0;
      v3_io_walkReq_0 <= 0;
      v3_io_walkReq_1 <= 0;
      v3_io_walkReq_2 <= 0;
      v3_io_walkReq_3 <= 0;
      v3_io_walkReq_4 <= 0;
      v3_io_walkReq_5 <= 0;
      v3_io_doAllocate <= 0;
      v3_io_freeReq_0 <= 0;
      v3_io_freeReq_1 <= 0;
      v3_io_freeReq_2 <= 0;
      v3_io_freeReq_3 <= 0;
      v3_io_freeReq_4 <= 0;
      v3_io_freeReq_5 <= 0;
      v3_io_freePhyReg_0 <= 0;
      v3_io_freePhyReg_1 <= 0;
      v3_io_freePhyReg_2 <= 0;
      v3_io_freePhyReg_3 <= 0;
      v3_io_freePhyReg_4 <= 0;
      v3_io_freePhyReg_5 <= 0;
      v3_io_commit_isCommit <= 0;
      v3_io_commit_commitValid_0 <= 0;
      v3_io_commit_commitValid_1 <= 0;
      v3_io_commit_commitValid_2 <= 0;
      v3_io_commit_commitValid_3 <= 0;
      v3_io_commit_commitValid_4 <= 0;
      v3_io_commit_commitValid_5 <= 0;
      v3_io_commit_info_0_vlWen <= 0;
      v3_io_commit_info_1_vlWen <= 0;
      v3_io_commit_info_2_vlWen <= 0;
      v3_io_commit_info_3_vlWen <= 0;
      v3_io_commit_info_4_vlWen <= 0;
      v3_io_commit_info_5_vlWen <= 0;
      v3_io_snpt_snptEnq <= 0;
      v3_io_snpt_snptDeq <= 0;
      v3_io_snpt_useSnpt <= 0;
      v3_io_snpt_snptSelect <= 0;
      v3_io_snpt_flushVec_0 <= 0;
      v3_io_snpt_flushVec_1 <= 0;
      v3_io_snpt_flushVec_2 <= 0;
      v3_io_snpt_flushVec_3 <= 0;
    end else begin
      v3_io_redirect <= (cyc < WARM_CYCLES) ? 1'b0 : ($urandom_range(0,99) < 3);
      v3_io_walk     <= ($urandom_range(0,99) < 25);
      v3_io_doAllocate <= $urandom_range(0,1);
      v3_io_allocateReq_0 <= $urandom_range(0,1);
      v3_io_walkReq_0 <= $urandom_range(0,1);
      v3_io_freeReq_0 <= ($urandom_range(0,99)<30);
      v3_io_freePhyReg_0 <= v3_rnd_preg();
      v3_io_commit_commitValid_0 <= $urandom_range(0,1);
      v3_io_commit_info_0_vlWen <= $urandom_range(0,1);
      v3_io_allocateReq_1 <= $urandom_range(0,1);
      v3_io_walkReq_1 <= $urandom_range(0,1);
      v3_io_freeReq_1 <= ($urandom_range(0,99)<30);
      v3_io_freePhyReg_1 <= v3_rnd_preg();
      v3_io_commit_commitValid_1 <= $urandom_range(0,1);
      v3_io_commit_info_1_vlWen <= $urandom_range(0,1);
      v3_io_allocateReq_2 <= $urandom_range(0,1);
      v3_io_walkReq_2 <= $urandom_range(0,1);
      v3_io_freeReq_2 <= ($urandom_range(0,99)<30);
      v3_io_freePhyReg_2 <= v3_rnd_preg();
      v3_io_commit_commitValid_2 <= $urandom_range(0,1);
      v3_io_commit_info_2_vlWen <= $urandom_range(0,1);
      v3_io_allocateReq_3 <= $urandom_range(0,1);
      v3_io_walkReq_3 <= $urandom_range(0,1);
      v3_io_freeReq_3 <= ($urandom_range(0,99)<30);
      v3_io_freePhyReg_3 <= v3_rnd_preg();
      v3_io_commit_commitValid_3 <= $urandom_range(0,1);
      v3_io_commit_info_3_vlWen <= $urandom_range(0,1);
      v3_io_allocateReq_4 <= $urandom_range(0,1);
      v3_io_walkReq_4 <= $urandom_range(0,1);
      v3_io_freeReq_4 <= ($urandom_range(0,99)<30);
      v3_io_freePhyReg_4 <= v3_rnd_preg();
      v3_io_commit_commitValid_4 <= $urandom_range(0,1);
      v3_io_commit_info_4_vlWen <= $urandom_range(0,1);
      v3_io_allocateReq_5 <= $urandom_range(0,1);
      v3_io_walkReq_5 <= $urandom_range(0,1);
      v3_io_freeReq_5 <= ($urandom_range(0,99)<30);
      v3_io_freePhyReg_5 <= v3_rnd_preg();
      v3_io_commit_commitValid_5 <= $urandom_range(0,1);
      v3_io_commit_info_5_vlWen <= $urandom_range(0,1);
      v3_io_commit_isCommit <= $urandom_range(0,1);
      if (cyc < WARM_CYCLES) begin
        v3_io_snpt_snptEnq <= 1'b1; v3_io_snpt_snptDeq <= 1'b0;
        v3_io_snpt_useSnpt <= 1'b0; v3_io_snpt_snptSelect <= 2'd0;
      end else begin
        v3_io_snpt_snptEnq <= ($urandom_range(0,99)<15); v3_io_snpt_snptDeq <= ($urandom_range(0,99)<15);
        v3_io_snpt_useSnpt <= $urandom_range(0,1); v3_io_snpt_snptSelect <= $urandom_range(0,3);
      end
      v3_io_snpt_flushVec_0 <= ($urandom_range(0,99)<5);
      v3_io_snpt_flushVec_1 <= ($urandom_range(0,99)<5);
      v3_io_snpt_flushVec_2 <= ($urandom_range(0,99)<5);
      v3_io_snpt_flushVec_3 <= ($urandom_range(0,99)<5);
    end
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(v3_g_io_allocatePhyReg_0) && v3_g_io_allocatePhyReg_0 !== v3_i_io_allocatePhyReg_0) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_3 io_allocatePhyReg_0 g=%h i=%h", $time, v3_g_io_allocatePhyReg_0, v3_i_io_allocatePhyReg_0); end
    if (!$isunknown(v3_g_io_allocatePhyReg_1) && v3_g_io_allocatePhyReg_1 !== v3_i_io_allocatePhyReg_1) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_3 io_allocatePhyReg_1 g=%h i=%h", $time, v3_g_io_allocatePhyReg_1, v3_i_io_allocatePhyReg_1); end
    if (!$isunknown(v3_g_io_allocatePhyReg_2) && v3_g_io_allocatePhyReg_2 !== v3_i_io_allocatePhyReg_2) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_3 io_allocatePhyReg_2 g=%h i=%h", $time, v3_g_io_allocatePhyReg_2, v3_i_io_allocatePhyReg_2); end
    if (!$isunknown(v3_g_io_allocatePhyReg_3) && v3_g_io_allocatePhyReg_3 !== v3_i_io_allocatePhyReg_3) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_3 io_allocatePhyReg_3 g=%h i=%h", $time, v3_g_io_allocatePhyReg_3, v3_i_io_allocatePhyReg_3); end
    if (!$isunknown(v3_g_io_allocatePhyReg_4) && v3_g_io_allocatePhyReg_4 !== v3_i_io_allocatePhyReg_4) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_3 io_allocatePhyReg_4 g=%h i=%h", $time, v3_g_io_allocatePhyReg_4, v3_i_io_allocatePhyReg_4); end
    if (!$isunknown(v3_g_io_allocatePhyReg_5) && v3_g_io_allocatePhyReg_5 !== v3_i_io_allocatePhyReg_5) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_3 io_allocatePhyReg_5 g=%h i=%h", $time, v3_g_io_allocatePhyReg_5, v3_i_io_allocatePhyReg_5); end
    if (!$isunknown(v3_g_io_canAllocate) && v3_g_io_canAllocate !== v3_i_io_canAllocate) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_3 io_canAllocate g=%h i=%h", $time, v3_g_io_canAllocate, v3_i_io_canAllocate); end
    if (!$isunknown(v3_g_io_perf_0_value) && v3_g_io_perf_0_value !== v3_i_io_perf_0_value) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_3 io_perf_0_value g=%h i=%h", $time, v3_g_io_perf_0_value, v3_i_io_perf_0_value); end
    if (!$isunknown(v3_g_io_perf_1_value) && v3_g_io_perf_1_value !== v3_i_io_perf_1_value) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_3 io_perf_1_value g=%h i=%h", $time, v3_g_io_perf_1_value, v3_i_io_perf_1_value); end
    if (!$isunknown(v3_g_io_perf_2_value) && v3_g_io_perf_2_value !== v3_i_io_perf_2_value) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_3 io_perf_2_value g=%h i=%h", $time, v3_g_io_perf_2_value, v3_i_io_perf_2_value); end
    if (!$isunknown(v3_g_io_perf_3_value) && v3_g_io_perf_3_value !== v3_i_io_perf_3_value) begin errors++;
      if(errors<=80) $display("[%0t] StdFreeList_3 io_perf_3_value g=%h i=%h", $time, v3_g_io_perf_3_value, v3_i_io_perf_3_value); end
    // 内部指针探针：golden 展平名 vs 核里的 struct(golden 的 shiftAmount 就是 headPtr.value)
    if (!$isunknown(v3_g.headPtr_flag)) begin
      if (v3_g.headPtr_flag !== v3_i.u_core.headPtr.flag) begin errors++;
        if(errors<=80) $display("[%0t] StdFreeList_3 headPtr.flag g=%h i=%h", $time, v3_g.headPtr_flag, v3_i.u_core.headPtr.flag); end
      if (v3_g.shiftAmount !== v3_i.u_core.headPtr.value) begin errors++;
        if(errors<=80) $display("[%0t] StdFreeList_3 headPtr.value g=%h i=%h", $time, v3_g.shiftAmount, v3_i.u_core.headPtr.value); end
    end
    if (!$isunknown(v3_g.archHeadPtr_flag)) begin
      if (v3_g.archHeadPtr_flag !== v3_i.u_core.archHeadPtr.flag) begin errors++;
        if(errors<=80) $display("[%0t] StdFreeList_3 archHeadPtr.flag g=%h i=%h", $time, v3_g.archHeadPtr_flag, v3_i.u_core.archHeadPtr.flag); end
      if (v3_g.archHeadPtr_value !== v3_i.u_core.archHeadPtr.value) begin errors++;
        if(errors<=80) $display("[%0t] StdFreeList_3 archHeadPtr.value g=%h i=%h", $time, v3_g.archHeadPtr_value, v3_i.u_core.archHeadPtr.value); end
    end
    if (!$isunknown(v3_g.lastTailPtr_flag)) begin
      if (v3_g.lastTailPtr_flag !== v3_i.u_core.lastTailPtr.flag) begin errors++;
        if(errors<=80) $display("[%0t] StdFreeList_3 lastTailPtr.flag g=%h i=%h", $time, v3_g.lastTailPtr_flag, v3_i.u_core.lastTailPtr.flag); end
      if (v3_g.lastTailPtr_value !== v3_i.u_core.lastTailPtr.value) begin errors++;
        if(errors<=80) $display("[%0t] StdFreeList_3 lastTailPtr.value g=%h i=%h", $time, v3_g.lastTailPtr_value, v3_i.u_core.lastTailPtr.value); end
    end
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
