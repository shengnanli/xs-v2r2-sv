// 自动生成: RedirectGenerator UT: golden vs 可读核 _xs 逐拍逐输出比对。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic reset;
  logic io_oldestExuRedirect_valid;
  logic io_oldestExuRedirect_bits_robIdx_flag;
  logic [7:0] io_oldestExuRedirect_bits_robIdx_value;
  logic io_oldestExuRedirect_bits_ftqIdx_flag;
  logic [5:0] io_oldestExuRedirect_bits_ftqIdx_value;
  logic [3:0] io_oldestExuRedirect_bits_ftqOffset;
  logic io_oldestExuRedirect_bits_level;
  logic [49:0] io_oldestExuRedirect_bits_cfiUpdate_pc;
  logic [49:0] io_oldestExuRedirect_bits_cfiUpdate_target;
  logic io_oldestExuRedirect_bits_cfiUpdate_taken;
  logic io_oldestExuRedirect_bits_cfiUpdate_isMisPred;
  logic io_oldestExuRedirect_bits_cfiUpdate_backendIGPF;
  logic io_oldestExuRedirect_bits_cfiUpdate_backendIPF;
  logic io_oldestExuRedirect_bits_cfiUpdate_backendIAF;
  logic [63:0] io_oldestExuRedirect_bits_fullTarget;
  logic io_oldestExuRedirect_bits_debugIsCtrl;
  logic io_oldestExuRedirectIsCSR;
  logic io_instrAddrTransType_bare;
  logic io_instrAddrTransType_sv39;
  logic io_instrAddrTransType_sv39x4;
  logic io_instrAddrTransType_sv48;
  logic io_instrAddrTransType_sv48x4;
  logic io_loadReplay_valid;
  logic io_loadReplay_bits_robIdx_flag;
  logic [7:0] io_loadReplay_bits_robIdx_value;
  logic io_loadReplay_bits_ftqIdx_flag;
  logic [5:0] io_loadReplay_bits_ftqIdx_value;
  logic [3:0] io_loadReplay_bits_ftqOffset;
  logic io_loadReplay_bits_level;
  logic [49:0] io_loadReplay_bits_cfiUpdate_pc;
  logic [49:0] io_loadReplay_bits_cfiUpdate_target;
  logic io_robFlush_valid;
  logic io_robFlush_bits_robIdx_flag;
  logic [7:0] io_robFlush_bits_robIdx_value;
  logic io_robFlush_bits_level;
  logic [49:0] io_memPredPcRead_data;
  logic g_io_stage2Redirect_valid;
  logic g_io_stage2Redirect_bits_robIdx_flag;
  logic [7:0] g_io_stage2Redirect_bits_robIdx_value;
  logic g_io_stage2Redirect_bits_ftqIdx_flag;
  logic [5:0] g_io_stage2Redirect_bits_ftqIdx_value;
  logic [3:0] g_io_stage2Redirect_bits_ftqOffset;
  logic g_io_stage2Redirect_bits_level;
  logic [49:0] g_io_stage2Redirect_bits_cfiUpdate_pc;
  logic [49:0] g_io_stage2Redirect_bits_cfiUpdate_target;
  logic g_io_stage2Redirect_bits_cfiUpdate_taken;
  logic g_io_stage2Redirect_bits_cfiUpdate_isMisPred;
  logic g_io_stage2Redirect_bits_cfiUpdate_backendIGPF;
  logic g_io_stage2Redirect_bits_cfiUpdate_backendIPF;
  logic g_io_stage2Redirect_bits_cfiUpdate_backendIAF;
  logic [63:0] g_io_stage2Redirect_bits_fullTarget;
  logic g_io_stage2Redirect_bits_debugIsCtrl;
  logic g_io_stage2Redirect_bits_debugIsMemVio;
  logic g_io_memPredUpdate_valid;
  logic [9:0] g_io_memPredUpdate_waddr;
  logic [9:0] g_io_memPredUpdate_ldpc;
  logic [9:0] g_io_memPredUpdate_stpc;
  logic [1:0] g_io_stage2oldestOH;
  logic i_io_stage2Redirect_valid;
  logic i_io_stage2Redirect_bits_robIdx_flag;
  logic [7:0] i_io_stage2Redirect_bits_robIdx_value;
  logic i_io_stage2Redirect_bits_ftqIdx_flag;
  logic [5:0] i_io_stage2Redirect_bits_ftqIdx_value;
  logic [3:0] i_io_stage2Redirect_bits_ftqOffset;
  logic i_io_stage2Redirect_bits_level;
  logic [49:0] i_io_stage2Redirect_bits_cfiUpdate_pc;
  logic [49:0] i_io_stage2Redirect_bits_cfiUpdate_target;
  logic i_io_stage2Redirect_bits_cfiUpdate_taken;
  logic i_io_stage2Redirect_bits_cfiUpdate_isMisPred;
  logic i_io_stage2Redirect_bits_cfiUpdate_backendIGPF;
  logic i_io_stage2Redirect_bits_cfiUpdate_backendIPF;
  logic i_io_stage2Redirect_bits_cfiUpdate_backendIAF;
  logic [63:0] i_io_stage2Redirect_bits_fullTarget;
  logic i_io_stage2Redirect_bits_debugIsCtrl;
  logic i_io_stage2Redirect_bits_debugIsMemVio;
  logic i_io_memPredUpdate_valid;
  logic [9:0] i_io_memPredUpdate_waddr;
  logic [9:0] i_io_memPredUpdate_ldpc;
  logic [9:0] i_io_memPredUpdate_stpc;
  logic [1:0] i_io_stage2oldestOH;

  RedirectGenerator u_g (
    .clock(clk),
    .reset(reset),
    .io_oldestExuRedirect_valid(io_oldestExuRedirect_valid),
    .io_oldestExuRedirect_bits_robIdx_flag(io_oldestExuRedirect_bits_robIdx_flag),
    .io_oldestExuRedirect_bits_robIdx_value(io_oldestExuRedirect_bits_robIdx_value),
    .io_oldestExuRedirect_bits_ftqIdx_flag(io_oldestExuRedirect_bits_ftqIdx_flag),
    .io_oldestExuRedirect_bits_ftqIdx_value(io_oldestExuRedirect_bits_ftqIdx_value),
    .io_oldestExuRedirect_bits_ftqOffset(io_oldestExuRedirect_bits_ftqOffset),
    .io_oldestExuRedirect_bits_level(io_oldestExuRedirect_bits_level),
    .io_oldestExuRedirect_bits_cfiUpdate_pc(io_oldestExuRedirect_bits_cfiUpdate_pc),
    .io_oldestExuRedirect_bits_cfiUpdate_target(io_oldestExuRedirect_bits_cfiUpdate_target),
    .io_oldestExuRedirect_bits_cfiUpdate_taken(io_oldestExuRedirect_bits_cfiUpdate_taken),
    .io_oldestExuRedirect_bits_cfiUpdate_isMisPred(io_oldestExuRedirect_bits_cfiUpdate_isMisPred),
    .io_oldestExuRedirect_bits_cfiUpdate_backendIGPF(io_oldestExuRedirect_bits_cfiUpdate_backendIGPF),
    .io_oldestExuRedirect_bits_cfiUpdate_backendIPF(io_oldestExuRedirect_bits_cfiUpdate_backendIPF),
    .io_oldestExuRedirect_bits_cfiUpdate_backendIAF(io_oldestExuRedirect_bits_cfiUpdate_backendIAF),
    .io_oldestExuRedirect_bits_fullTarget(io_oldestExuRedirect_bits_fullTarget),
    .io_oldestExuRedirect_bits_debugIsCtrl(io_oldestExuRedirect_bits_debugIsCtrl),
    .io_oldestExuRedirectIsCSR(io_oldestExuRedirectIsCSR),
    .io_instrAddrTransType_bare(io_instrAddrTransType_bare),
    .io_instrAddrTransType_sv39(io_instrAddrTransType_sv39),
    .io_instrAddrTransType_sv39x4(io_instrAddrTransType_sv39x4),
    .io_instrAddrTransType_sv48(io_instrAddrTransType_sv48),
    .io_instrAddrTransType_sv48x4(io_instrAddrTransType_sv48x4),
    .io_loadReplay_valid(io_loadReplay_valid),
    .io_loadReplay_bits_robIdx_flag(io_loadReplay_bits_robIdx_flag),
    .io_loadReplay_bits_robIdx_value(io_loadReplay_bits_robIdx_value),
    .io_loadReplay_bits_ftqIdx_flag(io_loadReplay_bits_ftqIdx_flag),
    .io_loadReplay_bits_ftqIdx_value(io_loadReplay_bits_ftqIdx_value),
    .io_loadReplay_bits_ftqOffset(io_loadReplay_bits_ftqOffset),
    .io_loadReplay_bits_level(io_loadReplay_bits_level),
    .io_loadReplay_bits_cfiUpdate_pc(io_loadReplay_bits_cfiUpdate_pc),
    .io_loadReplay_bits_cfiUpdate_target(io_loadReplay_bits_cfiUpdate_target),
    .io_robFlush_valid(io_robFlush_valid),
    .io_robFlush_bits_robIdx_flag(io_robFlush_bits_robIdx_flag),
    .io_robFlush_bits_robIdx_value(io_robFlush_bits_robIdx_value),
    .io_robFlush_bits_level(io_robFlush_bits_level),
    .io_memPredPcRead_data(io_memPredPcRead_data),
    .io_stage2Redirect_valid(g_io_stage2Redirect_valid),
    .io_stage2Redirect_bits_robIdx_flag(g_io_stage2Redirect_bits_robIdx_flag),
    .io_stage2Redirect_bits_robIdx_value(g_io_stage2Redirect_bits_robIdx_value),
    .io_stage2Redirect_bits_ftqIdx_flag(g_io_stage2Redirect_bits_ftqIdx_flag),
    .io_stage2Redirect_bits_ftqIdx_value(g_io_stage2Redirect_bits_ftqIdx_value),
    .io_stage2Redirect_bits_ftqOffset(g_io_stage2Redirect_bits_ftqOffset),
    .io_stage2Redirect_bits_level(g_io_stage2Redirect_bits_level),
    .io_stage2Redirect_bits_cfiUpdate_pc(g_io_stage2Redirect_bits_cfiUpdate_pc),
    .io_stage2Redirect_bits_cfiUpdate_target(g_io_stage2Redirect_bits_cfiUpdate_target),
    .io_stage2Redirect_bits_cfiUpdate_taken(g_io_stage2Redirect_bits_cfiUpdate_taken),
    .io_stage2Redirect_bits_cfiUpdate_isMisPred(g_io_stage2Redirect_bits_cfiUpdate_isMisPred),
    .io_stage2Redirect_bits_cfiUpdate_backendIGPF(g_io_stage2Redirect_bits_cfiUpdate_backendIGPF),
    .io_stage2Redirect_bits_cfiUpdate_backendIPF(g_io_stage2Redirect_bits_cfiUpdate_backendIPF),
    .io_stage2Redirect_bits_cfiUpdate_backendIAF(g_io_stage2Redirect_bits_cfiUpdate_backendIAF),
    .io_stage2Redirect_bits_fullTarget(g_io_stage2Redirect_bits_fullTarget),
    .io_stage2Redirect_bits_debugIsCtrl(g_io_stage2Redirect_bits_debugIsCtrl),
    .io_stage2Redirect_bits_debugIsMemVio(g_io_stage2Redirect_bits_debugIsMemVio),
    .io_memPredUpdate_valid(g_io_memPredUpdate_valid),
    .io_memPredUpdate_waddr(g_io_memPredUpdate_waddr),
    .io_memPredUpdate_ldpc(g_io_memPredUpdate_ldpc),
    .io_memPredUpdate_stpc(g_io_memPredUpdate_stpc),
    .io_stage2oldestOH(g_io_stage2oldestOH)
  );

  RedirectGenerator_xs u_i (
    .clock(clk),
    .reset(reset),
    .io_oldestExuRedirect_valid(io_oldestExuRedirect_valid),
    .io_oldestExuRedirect_bits_robIdx_flag(io_oldestExuRedirect_bits_robIdx_flag),
    .io_oldestExuRedirect_bits_robIdx_value(io_oldestExuRedirect_bits_robIdx_value),
    .io_oldestExuRedirect_bits_ftqIdx_flag(io_oldestExuRedirect_bits_ftqIdx_flag),
    .io_oldestExuRedirect_bits_ftqIdx_value(io_oldestExuRedirect_bits_ftqIdx_value),
    .io_oldestExuRedirect_bits_ftqOffset(io_oldestExuRedirect_bits_ftqOffset),
    .io_oldestExuRedirect_bits_level(io_oldestExuRedirect_bits_level),
    .io_oldestExuRedirect_bits_cfiUpdate_pc(io_oldestExuRedirect_bits_cfiUpdate_pc),
    .io_oldestExuRedirect_bits_cfiUpdate_target(io_oldestExuRedirect_bits_cfiUpdate_target),
    .io_oldestExuRedirect_bits_cfiUpdate_taken(io_oldestExuRedirect_bits_cfiUpdate_taken),
    .io_oldestExuRedirect_bits_cfiUpdate_isMisPred(io_oldestExuRedirect_bits_cfiUpdate_isMisPred),
    .io_oldestExuRedirect_bits_cfiUpdate_backendIGPF(io_oldestExuRedirect_bits_cfiUpdate_backendIGPF),
    .io_oldestExuRedirect_bits_cfiUpdate_backendIPF(io_oldestExuRedirect_bits_cfiUpdate_backendIPF),
    .io_oldestExuRedirect_bits_cfiUpdate_backendIAF(io_oldestExuRedirect_bits_cfiUpdate_backendIAF),
    .io_oldestExuRedirect_bits_fullTarget(io_oldestExuRedirect_bits_fullTarget),
    .io_oldestExuRedirect_bits_debugIsCtrl(io_oldestExuRedirect_bits_debugIsCtrl),
    .io_oldestExuRedirectIsCSR(io_oldestExuRedirectIsCSR),
    .io_instrAddrTransType_bare(io_instrAddrTransType_bare),
    .io_instrAddrTransType_sv39(io_instrAddrTransType_sv39),
    .io_instrAddrTransType_sv39x4(io_instrAddrTransType_sv39x4),
    .io_instrAddrTransType_sv48(io_instrAddrTransType_sv48),
    .io_instrAddrTransType_sv48x4(io_instrAddrTransType_sv48x4),
    .io_loadReplay_valid(io_loadReplay_valid),
    .io_loadReplay_bits_robIdx_flag(io_loadReplay_bits_robIdx_flag),
    .io_loadReplay_bits_robIdx_value(io_loadReplay_bits_robIdx_value),
    .io_loadReplay_bits_ftqIdx_flag(io_loadReplay_bits_ftqIdx_flag),
    .io_loadReplay_bits_ftqIdx_value(io_loadReplay_bits_ftqIdx_value),
    .io_loadReplay_bits_ftqOffset(io_loadReplay_bits_ftqOffset),
    .io_loadReplay_bits_level(io_loadReplay_bits_level),
    .io_loadReplay_bits_cfiUpdate_pc(io_loadReplay_bits_cfiUpdate_pc),
    .io_loadReplay_bits_cfiUpdate_target(io_loadReplay_bits_cfiUpdate_target),
    .io_robFlush_valid(io_robFlush_valid),
    .io_robFlush_bits_robIdx_flag(io_robFlush_bits_robIdx_flag),
    .io_robFlush_bits_robIdx_value(io_robFlush_bits_robIdx_value),
    .io_robFlush_bits_level(io_robFlush_bits_level),
    .io_memPredPcRead_data(io_memPredPcRead_data),
    .io_stage2Redirect_valid(i_io_stage2Redirect_valid),
    .io_stage2Redirect_bits_robIdx_flag(i_io_stage2Redirect_bits_robIdx_flag),
    .io_stage2Redirect_bits_robIdx_value(i_io_stage2Redirect_bits_robIdx_value),
    .io_stage2Redirect_bits_ftqIdx_flag(i_io_stage2Redirect_bits_ftqIdx_flag),
    .io_stage2Redirect_bits_ftqIdx_value(i_io_stage2Redirect_bits_ftqIdx_value),
    .io_stage2Redirect_bits_ftqOffset(i_io_stage2Redirect_bits_ftqOffset),
    .io_stage2Redirect_bits_level(i_io_stage2Redirect_bits_level),
    .io_stage2Redirect_bits_cfiUpdate_pc(i_io_stage2Redirect_bits_cfiUpdate_pc),
    .io_stage2Redirect_bits_cfiUpdate_target(i_io_stage2Redirect_bits_cfiUpdate_target),
    .io_stage2Redirect_bits_cfiUpdate_taken(i_io_stage2Redirect_bits_cfiUpdate_taken),
    .io_stage2Redirect_bits_cfiUpdate_isMisPred(i_io_stage2Redirect_bits_cfiUpdate_isMisPred),
    .io_stage2Redirect_bits_cfiUpdate_backendIGPF(i_io_stage2Redirect_bits_cfiUpdate_backendIGPF),
    .io_stage2Redirect_bits_cfiUpdate_backendIPF(i_io_stage2Redirect_bits_cfiUpdate_backendIPF),
    .io_stage2Redirect_bits_cfiUpdate_backendIAF(i_io_stage2Redirect_bits_cfiUpdate_backendIAF),
    .io_stage2Redirect_bits_fullTarget(i_io_stage2Redirect_bits_fullTarget),
    .io_stage2Redirect_bits_debugIsCtrl(i_io_stage2Redirect_bits_debugIsCtrl),
    .io_stage2Redirect_bits_debugIsMemVio(i_io_stage2Redirect_bits_debugIsMemVio),
    .io_memPredUpdate_valid(i_io_memPredUpdate_valid),
    .io_memPredUpdate_waddr(i_io_memPredUpdate_waddr),
    .io_memPredUpdate_ldpc(i_io_memPredUpdate_ldpc),
    .io_memPredUpdate_stpc(i_io_memPredUpdate_stpc),
    .io_stage2oldestOH(i_io_stage2oldestOH)
  );

  task automatic drive_inputs();
    reset = ($urandom_range(0,99) < 5);
    io_oldestExuRedirect_valid = $urandom;
    io_oldestExuRedirect_bits_robIdx_flag = $urandom;
    io_oldestExuRedirect_bits_robIdx_value = $urandom;
    io_oldestExuRedirect_bits_ftqIdx_flag = $urandom;
    io_oldestExuRedirect_bits_ftqIdx_value = $urandom;
    io_oldestExuRedirect_bits_ftqOffset = $urandom;
    io_oldestExuRedirect_bits_level = $urandom;
    io_oldestExuRedirect_bits_cfiUpdate_pc = $urandom;
    io_oldestExuRedirect_bits_cfiUpdate_target = $urandom;
    io_oldestExuRedirect_bits_cfiUpdate_taken = $urandom;
    io_oldestExuRedirect_bits_cfiUpdate_isMisPred = $urandom;
    io_oldestExuRedirect_bits_cfiUpdate_backendIGPF = $urandom;
    io_oldestExuRedirect_bits_cfiUpdate_backendIPF = $urandom;
    io_oldestExuRedirect_bits_cfiUpdate_backendIAF = $urandom;
    io_oldestExuRedirect_bits_fullTarget = $urandom;
    io_oldestExuRedirect_bits_debugIsCtrl = $urandom;
    io_oldestExuRedirectIsCSR = $urandom;
    io_instrAddrTransType_bare = $urandom;
    io_instrAddrTransType_sv39 = $urandom;
    io_instrAddrTransType_sv39x4 = $urandom;
    io_instrAddrTransType_sv48 = $urandom;
    io_instrAddrTransType_sv48x4 = $urandom;
    io_loadReplay_valid = $urandom;
    io_loadReplay_bits_robIdx_flag = $urandom;
    io_loadReplay_bits_robIdx_value = $urandom;
    io_loadReplay_bits_ftqIdx_flag = $urandom;
    io_loadReplay_bits_ftqIdx_value = $urandom;
    io_loadReplay_bits_ftqOffset = $urandom;
    io_loadReplay_bits_level = $urandom;
    io_loadReplay_bits_cfiUpdate_pc = $urandom;
    io_loadReplay_bits_cfiUpdate_target = $urandom;
    io_robFlush_valid = $urandom;
    io_robFlush_bits_robIdx_flag = $urandom;
    io_robFlush_bits_robIdx_value = $urandom;
    io_robFlush_bits_level = $urandom;
    io_memPredPcRead_data = $urandom;
  endtask

  task automatic check_outputs();
    if (!$isunknown(g_io_stage2Redirect_valid) && (g_io_stage2Redirect_valid) !== (i_io_stage2Redirect_valid)) begin errors++; if (errors<=60) $display("[%0t] io_stage2Redirect_valid g=%h i=%h",$time,g_io_stage2Redirect_valid,i_io_stage2Redirect_valid); end checks++;
    if (!$isunknown(g_io_stage2Redirect_bits_robIdx_flag) && (g_io_stage2Redirect_bits_robIdx_flag) !== (i_io_stage2Redirect_bits_robIdx_flag)) begin errors++; if (errors<=60) $display("[%0t] io_stage2Redirect_bits_robIdx_flag g=%h i=%h",$time,g_io_stage2Redirect_bits_robIdx_flag,i_io_stage2Redirect_bits_robIdx_flag); end checks++;
    if (!$isunknown(g_io_stage2Redirect_bits_robIdx_value) && (g_io_stage2Redirect_bits_robIdx_value) !== (i_io_stage2Redirect_bits_robIdx_value)) begin errors++; if (errors<=60) $display("[%0t] io_stage2Redirect_bits_robIdx_value g=%h i=%h",$time,g_io_stage2Redirect_bits_robIdx_value,i_io_stage2Redirect_bits_robIdx_value); end checks++;
    if (!$isunknown(g_io_stage2Redirect_bits_ftqIdx_flag) && (g_io_stage2Redirect_bits_ftqIdx_flag) !== (i_io_stage2Redirect_bits_ftqIdx_flag)) begin errors++; if (errors<=60) $display("[%0t] io_stage2Redirect_bits_ftqIdx_flag g=%h i=%h",$time,g_io_stage2Redirect_bits_ftqIdx_flag,i_io_stage2Redirect_bits_ftqIdx_flag); end checks++;
    if (!$isunknown(g_io_stage2Redirect_bits_ftqIdx_value) && (g_io_stage2Redirect_bits_ftqIdx_value) !== (i_io_stage2Redirect_bits_ftqIdx_value)) begin errors++; if (errors<=60) $display("[%0t] io_stage2Redirect_bits_ftqIdx_value g=%h i=%h",$time,g_io_stage2Redirect_bits_ftqIdx_value,i_io_stage2Redirect_bits_ftqIdx_value); end checks++;
    if (!$isunknown(g_io_stage2Redirect_bits_ftqOffset) && (g_io_stage2Redirect_bits_ftqOffset) !== (i_io_stage2Redirect_bits_ftqOffset)) begin errors++; if (errors<=60) $display("[%0t] io_stage2Redirect_bits_ftqOffset g=%h i=%h",$time,g_io_stage2Redirect_bits_ftqOffset,i_io_stage2Redirect_bits_ftqOffset); end checks++;
    if (!$isunknown(g_io_stage2Redirect_bits_level) && (g_io_stage2Redirect_bits_level) !== (i_io_stage2Redirect_bits_level)) begin errors++; if (errors<=60) $display("[%0t] io_stage2Redirect_bits_level g=%h i=%h",$time,g_io_stage2Redirect_bits_level,i_io_stage2Redirect_bits_level); end checks++;
    if (!$isunknown(g_io_stage2Redirect_bits_cfiUpdate_pc) && (g_io_stage2Redirect_bits_cfiUpdate_pc) !== (i_io_stage2Redirect_bits_cfiUpdate_pc)) begin errors++; if (errors<=60) $display("[%0t] io_stage2Redirect_bits_cfiUpdate_pc g=%h i=%h",$time,g_io_stage2Redirect_bits_cfiUpdate_pc,i_io_stage2Redirect_bits_cfiUpdate_pc); end checks++;
    if (!$isunknown(g_io_stage2Redirect_bits_cfiUpdate_target) && (g_io_stage2Redirect_bits_cfiUpdate_target) !== (i_io_stage2Redirect_bits_cfiUpdate_target)) begin errors++; if (errors<=60) $display("[%0t] io_stage2Redirect_bits_cfiUpdate_target g=%h i=%h",$time,g_io_stage2Redirect_bits_cfiUpdate_target,i_io_stage2Redirect_bits_cfiUpdate_target); end checks++;
    if (!$isunknown(g_io_stage2Redirect_bits_cfiUpdate_taken) && (g_io_stage2Redirect_bits_cfiUpdate_taken) !== (i_io_stage2Redirect_bits_cfiUpdate_taken)) begin errors++; if (errors<=60) $display("[%0t] io_stage2Redirect_bits_cfiUpdate_taken g=%h i=%h",$time,g_io_stage2Redirect_bits_cfiUpdate_taken,i_io_stage2Redirect_bits_cfiUpdate_taken); end checks++;
    if (!$isunknown(g_io_stage2Redirect_bits_cfiUpdate_isMisPred) && (g_io_stage2Redirect_bits_cfiUpdate_isMisPred) !== (i_io_stage2Redirect_bits_cfiUpdate_isMisPred)) begin errors++; if (errors<=60) $display("[%0t] io_stage2Redirect_bits_cfiUpdate_isMisPred g=%h i=%h",$time,g_io_stage2Redirect_bits_cfiUpdate_isMisPred,i_io_stage2Redirect_bits_cfiUpdate_isMisPred); end checks++;
    if (!$isunknown(g_io_stage2Redirect_bits_cfiUpdate_backendIGPF) && (g_io_stage2Redirect_bits_cfiUpdate_backendIGPF) !== (i_io_stage2Redirect_bits_cfiUpdate_backendIGPF)) begin errors++; if (errors<=60) $display("[%0t] io_stage2Redirect_bits_cfiUpdate_backendIGPF g=%h i=%h",$time,g_io_stage2Redirect_bits_cfiUpdate_backendIGPF,i_io_stage2Redirect_bits_cfiUpdate_backendIGPF); end checks++;
    if (!$isunknown(g_io_stage2Redirect_bits_cfiUpdate_backendIPF) && (g_io_stage2Redirect_bits_cfiUpdate_backendIPF) !== (i_io_stage2Redirect_bits_cfiUpdate_backendIPF)) begin errors++; if (errors<=60) $display("[%0t] io_stage2Redirect_bits_cfiUpdate_backendIPF g=%h i=%h",$time,g_io_stage2Redirect_bits_cfiUpdate_backendIPF,i_io_stage2Redirect_bits_cfiUpdate_backendIPF); end checks++;
    if (!$isunknown(g_io_stage2Redirect_bits_cfiUpdate_backendIAF) && (g_io_stage2Redirect_bits_cfiUpdate_backendIAF) !== (i_io_stage2Redirect_bits_cfiUpdate_backendIAF)) begin errors++; if (errors<=60) $display("[%0t] io_stage2Redirect_bits_cfiUpdate_backendIAF g=%h i=%h",$time,g_io_stage2Redirect_bits_cfiUpdate_backendIAF,i_io_stage2Redirect_bits_cfiUpdate_backendIAF); end checks++;
    if (!$isunknown(g_io_stage2Redirect_bits_fullTarget) && (g_io_stage2Redirect_bits_fullTarget) !== (i_io_stage2Redirect_bits_fullTarget)) begin errors++; if (errors<=60) $display("[%0t] io_stage2Redirect_bits_fullTarget g=%h i=%h",$time,g_io_stage2Redirect_bits_fullTarget,i_io_stage2Redirect_bits_fullTarget); end checks++;
    if (!$isunknown(g_io_stage2Redirect_bits_debugIsCtrl) && (g_io_stage2Redirect_bits_debugIsCtrl) !== (i_io_stage2Redirect_bits_debugIsCtrl)) begin errors++; if (errors<=60) $display("[%0t] io_stage2Redirect_bits_debugIsCtrl g=%h i=%h",$time,g_io_stage2Redirect_bits_debugIsCtrl,i_io_stage2Redirect_bits_debugIsCtrl); end checks++;
    if (!$isunknown(g_io_stage2Redirect_bits_debugIsMemVio) && (g_io_stage2Redirect_bits_debugIsMemVio) !== (i_io_stage2Redirect_bits_debugIsMemVio)) begin errors++; if (errors<=60) $display("[%0t] io_stage2Redirect_bits_debugIsMemVio g=%h i=%h",$time,g_io_stage2Redirect_bits_debugIsMemVio,i_io_stage2Redirect_bits_debugIsMemVio); end checks++;
    if (!$isunknown(g_io_memPredUpdate_valid) && (g_io_memPredUpdate_valid) !== (i_io_memPredUpdate_valid)) begin errors++; if (errors<=60) $display("[%0t] io_memPredUpdate_valid g=%h i=%h",$time,g_io_memPredUpdate_valid,i_io_memPredUpdate_valid); end checks++;
    if (!$isunknown(g_io_memPredUpdate_waddr) && (g_io_memPredUpdate_waddr) !== (i_io_memPredUpdate_waddr)) begin errors++; if (errors<=60) $display("[%0t] io_memPredUpdate_waddr g=%h i=%h",$time,g_io_memPredUpdate_waddr,i_io_memPredUpdate_waddr); end checks++;
    if (!$isunknown(g_io_memPredUpdate_ldpc) && (g_io_memPredUpdate_ldpc) !== (i_io_memPredUpdate_ldpc)) begin errors++; if (errors<=60) $display("[%0t] io_memPredUpdate_ldpc g=%h i=%h",$time,g_io_memPredUpdate_ldpc,i_io_memPredUpdate_ldpc); end checks++;
    if (!$isunknown(g_io_memPredUpdate_stpc) && (g_io_memPredUpdate_stpc) !== (i_io_memPredUpdate_stpc)) begin errors++; if (errors<=60) $display("[%0t] io_memPredUpdate_stpc g=%h i=%h",$time,g_io_memPredUpdate_stpc,i_io_memPredUpdate_stpc); end checks++;
    if (!$isunknown(g_io_stage2oldestOH) && (g_io_stage2oldestOH) !== (i_io_stage2oldestOH)) begin errors++; if (errors<=60) $display("[%0t] io_stage2oldestOH g=%h i=%h",$time,g_io_stage2oldestOH,i_io_stage2oldestOH); end checks++;
  endtask

  initial begin
    drive_inputs();
    reset = 1;
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
