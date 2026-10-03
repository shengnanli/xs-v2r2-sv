// tb —— CsrDebugTime4：NewCSR 下 4 个叶（Debug / MieModule / timeModule / XRetPermitModule）的双例化 UT。
// 本文件由 gen.py 生成（scripts/dual_tb_lib.py），勿手改。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= Debug =================
  int unsigned dbg_mode = 0;
  logic dbg_io_in_trapInfo_valid;
  logic [63:0] dbg_io_in_trapInfo_bits_trapVec;
  logic dbg_io_in_trapInfo_bits_isDebugIntr;
  logic dbg_io_in_trapInfo_bits_isInterrupt;
  logic dbg_io_in_trapInfo_bits_singleStep;
  logic [3:0] dbg_io_in_trapInfo_bits_trigger;
  logic dbg_io_in_trapInfo_bits_criticalErrorState;
  logic [1:0] dbg_io_in_privState_PRVM;
  logic dbg_io_in_privState_V;
  logic dbg_io_in_debugMode;
  logic dbg_io_in_dcsr_CETRIG;
  logic dbg_io_in_dcsr_EBREAKVS;
  logic dbg_io_in_dcsr_EBREAKVU;
  logic dbg_io_in_dcsr_EBREAKM;
  logic dbg_io_in_dcsr_EBREAKS;
  logic dbg_io_in_dcsr_EBREAKU;
  logic [1:0] dbg_io_in_tselect_ALL;
  logic [58:0] dbg_io_in_tdata1Selected_DATA;
  logic [63:0] dbg_io_in_tdata2Selected_ALL;
  logic [3:0] dbg_io_in_tdata1Vec_0_TYPE;
  logic [58:0] dbg_io_in_tdata1Vec_0_DATA;
  logic [3:0] dbg_io_in_tdata1Vec_1_TYPE;
  logic [58:0] dbg_io_in_tdata1Vec_1_DATA;
  logic [3:0] dbg_io_in_tdata1Vec_2_TYPE;
  logic [58:0] dbg_io_in_tdata1Vec_2_DATA;
  logic [3:0] dbg_io_in_tdata1Vec_3_TYPE;
  logic [58:0] dbg_io_in_tdata1Vec_3_DATA;
  logic dbg_io_in_triggerCanRaiseBpExp;
  logic dbg_io_in_tdata1Update;
  logic dbg_io_in_tdata2Update;
  logic [3:0] dbg_io_in_tdata1Wdata_TYPE;
  logic [58:0] dbg_io_in_tdata1Wdata_DATA;
  wire  dbg_g_io_out_triggerFrontendChange, dbg_i_io_out_triggerFrontendChange;
  logic dbg_s0_io_out_triggerFrontendChange = '0, dbg_s1_io_out_triggerFrontendChange = '0;
  wire  dbg_g_io_out_newTriggerChainIsLegal, dbg_i_io_out_newTriggerChainIsLegal;
  logic dbg_s0_io_out_newTriggerChainIsLegal = '0, dbg_s1_io_out_newTriggerChainIsLegal = '0;
  wire  dbg_g_io_out_memTrigger_tUpdate_valid, dbg_i_io_out_memTrigger_tUpdate_valid;
  logic dbg_s0_io_out_memTrigger_tUpdate_valid = '0, dbg_s1_io_out_memTrigger_tUpdate_valid = '0;
  wire  [1:0] dbg_g_io_out_memTrigger_tUpdate_bits_addr, dbg_i_io_out_memTrigger_tUpdate_bits_addr;
  logic [1:0] dbg_s0_io_out_memTrigger_tUpdate_bits_addr = '0, dbg_s1_io_out_memTrigger_tUpdate_bits_addr = '0;
  wire  [1:0] dbg_g_io_out_memTrigger_tUpdate_bits_tdata_matchType, dbg_i_io_out_memTrigger_tUpdate_bits_tdata_matchType;
  logic [1:0] dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_matchType = '0, dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_matchType = '0;
  wire  dbg_g_io_out_memTrigger_tUpdate_bits_tdata_select, dbg_i_io_out_memTrigger_tUpdate_bits_tdata_select;
  logic dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_select = '0, dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_select = '0;
  wire  [3:0] dbg_g_io_out_memTrigger_tUpdate_bits_tdata_action, dbg_i_io_out_memTrigger_tUpdate_bits_tdata_action;
  logic [3:0] dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_action = '0, dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_action = '0;
  wire  dbg_g_io_out_memTrigger_tUpdate_bits_tdata_chain, dbg_i_io_out_memTrigger_tUpdate_bits_tdata_chain;
  logic dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_chain = '0, dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_chain = '0;
  wire  dbg_g_io_out_memTrigger_tUpdate_bits_tdata_store, dbg_i_io_out_memTrigger_tUpdate_bits_tdata_store;
  logic dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_store = '0, dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_store = '0;
  wire  dbg_g_io_out_memTrigger_tUpdate_bits_tdata_load, dbg_i_io_out_memTrigger_tUpdate_bits_tdata_load;
  logic dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_load = '0, dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_load = '0;
  wire  [63:0] dbg_g_io_out_memTrigger_tUpdate_bits_tdata_tdata2, dbg_i_io_out_memTrigger_tUpdate_bits_tdata_tdata2;
  logic [63:0] dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2 = '0, dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2 = '0;
  wire  dbg_g_io_out_memTrigger_tEnableVec_0, dbg_i_io_out_memTrigger_tEnableVec_0;
  logic dbg_s0_io_out_memTrigger_tEnableVec_0 = '0, dbg_s1_io_out_memTrigger_tEnableVec_0 = '0;
  wire  dbg_g_io_out_memTrigger_tEnableVec_1, dbg_i_io_out_memTrigger_tEnableVec_1;
  logic dbg_s0_io_out_memTrigger_tEnableVec_1 = '0, dbg_s1_io_out_memTrigger_tEnableVec_1 = '0;
  wire  dbg_g_io_out_memTrigger_tEnableVec_2, dbg_i_io_out_memTrigger_tEnableVec_2;
  logic dbg_s0_io_out_memTrigger_tEnableVec_2 = '0, dbg_s1_io_out_memTrigger_tEnableVec_2 = '0;
  wire  dbg_g_io_out_memTrigger_tEnableVec_3, dbg_i_io_out_memTrigger_tEnableVec_3;
  logic dbg_s0_io_out_memTrigger_tEnableVec_3 = '0, dbg_s1_io_out_memTrigger_tEnableVec_3 = '0;
  wire  dbg_g_io_out_memTrigger_debugMode, dbg_i_io_out_memTrigger_debugMode;
  logic dbg_s0_io_out_memTrigger_debugMode = '0, dbg_s1_io_out_memTrigger_debugMode = '0;
  wire  dbg_g_io_out_memTrigger_triggerCanRaiseBpExp, dbg_i_io_out_memTrigger_triggerCanRaiseBpExp;
  logic dbg_s0_io_out_memTrigger_triggerCanRaiseBpExp = '0, dbg_s1_io_out_memTrigger_triggerCanRaiseBpExp = '0;
  wire  dbg_g_io_out_frontendTrigger_tUpdate_valid, dbg_i_io_out_frontendTrigger_tUpdate_valid;
  logic dbg_s0_io_out_frontendTrigger_tUpdate_valid = '0, dbg_s1_io_out_frontendTrigger_tUpdate_valid = '0;
  wire  [1:0] dbg_g_io_out_frontendTrigger_tUpdate_bits_addr, dbg_i_io_out_frontendTrigger_tUpdate_bits_addr;
  logic [1:0] dbg_s0_io_out_frontendTrigger_tUpdate_bits_addr = '0, dbg_s1_io_out_frontendTrigger_tUpdate_bits_addr = '0;
  wire  [1:0] dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_matchType, dbg_i_io_out_frontendTrigger_tUpdate_bits_tdata_matchType;
  logic [1:0] dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_matchType = '0, dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_matchType = '0;
  wire  dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_select, dbg_i_io_out_frontendTrigger_tUpdate_bits_tdata_select;
  logic dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_select = '0, dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_select = '0;
  wire  [3:0] dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_action, dbg_i_io_out_frontendTrigger_tUpdate_bits_tdata_action;
  logic [3:0] dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_action = '0, dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_action = '0;
  wire  dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_chain, dbg_i_io_out_frontendTrigger_tUpdate_bits_tdata_chain;
  logic dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_chain = '0, dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_chain = '0;
  wire  [63:0] dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2, dbg_i_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2;
  logic [63:0] dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2 = '0, dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2 = '0;
  wire  dbg_g_io_out_frontendTrigger_tEnableVec_0, dbg_i_io_out_frontendTrigger_tEnableVec_0;
  logic dbg_s0_io_out_frontendTrigger_tEnableVec_0 = '0, dbg_s1_io_out_frontendTrigger_tEnableVec_0 = '0;
  wire  dbg_g_io_out_frontendTrigger_tEnableVec_1, dbg_i_io_out_frontendTrigger_tEnableVec_1;
  logic dbg_s0_io_out_frontendTrigger_tEnableVec_1 = '0, dbg_s1_io_out_frontendTrigger_tEnableVec_1 = '0;
  wire  dbg_g_io_out_frontendTrigger_tEnableVec_2, dbg_i_io_out_frontendTrigger_tEnableVec_2;
  logic dbg_s0_io_out_frontendTrigger_tEnableVec_2 = '0, dbg_s1_io_out_frontendTrigger_tEnableVec_2 = '0;
  wire  dbg_g_io_out_frontendTrigger_tEnableVec_3, dbg_i_io_out_frontendTrigger_tEnableVec_3;
  logic dbg_s0_io_out_frontendTrigger_tEnableVec_3 = '0, dbg_s1_io_out_frontendTrigger_tEnableVec_3 = '0;
  wire  dbg_g_io_out_frontendTrigger_debugMode, dbg_i_io_out_frontendTrigger_debugMode;
  logic dbg_s0_io_out_frontendTrigger_debugMode = '0, dbg_s1_io_out_frontendTrigger_debugMode = '0;
  wire  dbg_g_io_out_frontendTrigger_triggerCanRaiseBpExp, dbg_i_io_out_frontendTrigger_triggerCanRaiseBpExp;
  logic dbg_s0_io_out_frontendTrigger_triggerCanRaiseBpExp = '0, dbg_s1_io_out_frontendTrigger_triggerCanRaiseBpExp = '0;
  wire  dbg_g_io_out_hasDebugTrap, dbg_i_io_out_hasDebugTrap;
  logic dbg_s0_io_out_hasDebugTrap = '0, dbg_s1_io_out_hasDebugTrap = '0;
  wire  dbg_g_io_out_hasDebugIntr, dbg_i_io_out_hasDebugIntr;
  logic dbg_s0_io_out_hasDebugIntr = '0, dbg_s1_io_out_hasDebugIntr = '0;
  wire  dbg_g_io_out_hasSingleStep, dbg_i_io_out_hasSingleStep;
  logic dbg_s0_io_out_hasSingleStep = '0, dbg_s1_io_out_hasSingleStep = '0;
  wire  dbg_g_io_out_triggerEnterDebugMode, dbg_i_io_out_triggerEnterDebugMode;
  logic dbg_s0_io_out_triggerEnterDebugMode = '0, dbg_s1_io_out_triggerEnterDebugMode = '0;
  wire  dbg_g_io_out_hasDebugEbreakException, dbg_i_io_out_hasDebugEbreakException;
  logic dbg_s0_io_out_hasDebugEbreakException = '0, dbg_s1_io_out_hasDebugEbreakException = '0;
  wire  dbg_g_io_out_breakPoint, dbg_i_io_out_breakPoint;
  logic dbg_s0_io_out_breakPoint = '0, dbg_s1_io_out_breakPoint = '0;
  wire  dbg_g_io_out_criticalErrorStateEnterDebug, dbg_i_io_out_criticalErrorStateEnterDebug;
  logic dbg_s0_io_out_criticalErrorStateEnterDebug = '0, dbg_s1_io_out_criticalErrorStateEnterDebug = '0;
  int dbg_cov_ebreak_dbg = 0;
  int dbg_cov_trig_dmode = 0;
  int dbg_cov_single_step = 0;
  int dbg_cov_debug_intr = 0;
  int dbg_cov_crit_err = 0;
  int dbg_cov_chain_legal = 0;
  int dbg_cov_chain_illegal = 0;
  int dbg_cov_fe_upd_valid = 0;
  int dbg_cov_mem_upd_valid = 0;
  int dbg_cov_fe_enable = 0;
  int dbg_cov_mem_enable = 0;
  logic [0:0] dbg_armed = '0;
  int dbg_armed_at = -1;
  Debug dbg_u_gold (
    .clock(clk),
    .io_in_trapInfo_valid(dbg_io_in_trapInfo_valid),
    .io_in_trapInfo_bits_trapVec(dbg_io_in_trapInfo_bits_trapVec),
    .io_in_trapInfo_bits_isDebugIntr(dbg_io_in_trapInfo_bits_isDebugIntr),
    .io_in_trapInfo_bits_isInterrupt(dbg_io_in_trapInfo_bits_isInterrupt),
    .io_in_trapInfo_bits_singleStep(dbg_io_in_trapInfo_bits_singleStep),
    .io_in_trapInfo_bits_trigger(dbg_io_in_trapInfo_bits_trigger),
    .io_in_trapInfo_bits_criticalErrorState(dbg_io_in_trapInfo_bits_criticalErrorState),
    .io_in_privState_PRVM(dbg_io_in_privState_PRVM),
    .io_in_privState_V(dbg_io_in_privState_V),
    .io_in_debugMode(dbg_io_in_debugMode),
    .io_in_dcsr_CETRIG(dbg_io_in_dcsr_CETRIG),
    .io_in_dcsr_EBREAKVS(dbg_io_in_dcsr_EBREAKVS),
    .io_in_dcsr_EBREAKVU(dbg_io_in_dcsr_EBREAKVU),
    .io_in_dcsr_EBREAKM(dbg_io_in_dcsr_EBREAKM),
    .io_in_dcsr_EBREAKS(dbg_io_in_dcsr_EBREAKS),
    .io_in_dcsr_EBREAKU(dbg_io_in_dcsr_EBREAKU),
    .io_in_tselect_ALL(dbg_io_in_tselect_ALL),
    .io_in_tdata1Selected_DATA(dbg_io_in_tdata1Selected_DATA),
    .io_in_tdata2Selected_ALL(dbg_io_in_tdata2Selected_ALL),
    .io_in_tdata1Vec_0_TYPE(dbg_io_in_tdata1Vec_0_TYPE),
    .io_in_tdata1Vec_0_DATA(dbg_io_in_tdata1Vec_0_DATA),
    .io_in_tdata1Vec_1_TYPE(dbg_io_in_tdata1Vec_1_TYPE),
    .io_in_tdata1Vec_1_DATA(dbg_io_in_tdata1Vec_1_DATA),
    .io_in_tdata1Vec_2_TYPE(dbg_io_in_tdata1Vec_2_TYPE),
    .io_in_tdata1Vec_2_DATA(dbg_io_in_tdata1Vec_2_DATA),
    .io_in_tdata1Vec_3_TYPE(dbg_io_in_tdata1Vec_3_TYPE),
    .io_in_tdata1Vec_3_DATA(dbg_io_in_tdata1Vec_3_DATA),
    .io_in_triggerCanRaiseBpExp(dbg_io_in_triggerCanRaiseBpExp),
    .io_in_tdata1Update(dbg_io_in_tdata1Update),
    .io_in_tdata2Update(dbg_io_in_tdata2Update),
    .io_in_tdata1Wdata_TYPE(dbg_io_in_tdata1Wdata_TYPE),
    .io_in_tdata1Wdata_DATA(dbg_io_in_tdata1Wdata_DATA),
    .io_out_triggerFrontendChange(dbg_g_io_out_triggerFrontendChange),
    .io_out_newTriggerChainIsLegal(dbg_g_io_out_newTriggerChainIsLegal),
    .io_out_memTrigger_tUpdate_valid(dbg_g_io_out_memTrigger_tUpdate_valid),
    .io_out_memTrigger_tUpdate_bits_addr(dbg_g_io_out_memTrigger_tUpdate_bits_addr),
    .io_out_memTrigger_tUpdate_bits_tdata_matchType(dbg_g_io_out_memTrigger_tUpdate_bits_tdata_matchType),
    .io_out_memTrigger_tUpdate_bits_tdata_select(dbg_g_io_out_memTrigger_tUpdate_bits_tdata_select),
    .io_out_memTrigger_tUpdate_bits_tdata_action(dbg_g_io_out_memTrigger_tUpdate_bits_tdata_action),
    .io_out_memTrigger_tUpdate_bits_tdata_chain(dbg_g_io_out_memTrigger_tUpdate_bits_tdata_chain),
    .io_out_memTrigger_tUpdate_bits_tdata_store(dbg_g_io_out_memTrigger_tUpdate_bits_tdata_store),
    .io_out_memTrigger_tUpdate_bits_tdata_load(dbg_g_io_out_memTrigger_tUpdate_bits_tdata_load),
    .io_out_memTrigger_tUpdate_bits_tdata_tdata2(dbg_g_io_out_memTrigger_tUpdate_bits_tdata_tdata2),
    .io_out_memTrigger_tEnableVec_0(dbg_g_io_out_memTrigger_tEnableVec_0),
    .io_out_memTrigger_tEnableVec_1(dbg_g_io_out_memTrigger_tEnableVec_1),
    .io_out_memTrigger_tEnableVec_2(dbg_g_io_out_memTrigger_tEnableVec_2),
    .io_out_memTrigger_tEnableVec_3(dbg_g_io_out_memTrigger_tEnableVec_3),
    .io_out_memTrigger_debugMode(dbg_g_io_out_memTrigger_debugMode),
    .io_out_memTrigger_triggerCanRaiseBpExp(dbg_g_io_out_memTrigger_triggerCanRaiseBpExp),
    .io_out_frontendTrigger_tUpdate_valid(dbg_g_io_out_frontendTrigger_tUpdate_valid),
    .io_out_frontendTrigger_tUpdate_bits_addr(dbg_g_io_out_frontendTrigger_tUpdate_bits_addr),
    .io_out_frontendTrigger_tUpdate_bits_tdata_matchType(dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_matchType),
    .io_out_frontendTrigger_tUpdate_bits_tdata_select(dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_select),
    .io_out_frontendTrigger_tUpdate_bits_tdata_action(dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_action),
    .io_out_frontendTrigger_tUpdate_bits_tdata_chain(dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_chain),
    .io_out_frontendTrigger_tUpdate_bits_tdata_tdata2(dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2),
    .io_out_frontendTrigger_tEnableVec_0(dbg_g_io_out_frontendTrigger_tEnableVec_0),
    .io_out_frontendTrigger_tEnableVec_1(dbg_g_io_out_frontendTrigger_tEnableVec_1),
    .io_out_frontendTrigger_tEnableVec_2(dbg_g_io_out_frontendTrigger_tEnableVec_2),
    .io_out_frontendTrigger_tEnableVec_3(dbg_g_io_out_frontendTrigger_tEnableVec_3),
    .io_out_frontendTrigger_debugMode(dbg_g_io_out_frontendTrigger_debugMode),
    .io_out_frontendTrigger_triggerCanRaiseBpExp(dbg_g_io_out_frontendTrigger_triggerCanRaiseBpExp),
    .io_out_hasDebugTrap(dbg_g_io_out_hasDebugTrap),
    .io_out_hasDebugIntr(dbg_g_io_out_hasDebugIntr),
    .io_out_hasSingleStep(dbg_g_io_out_hasSingleStep),
    .io_out_triggerEnterDebugMode(dbg_g_io_out_triggerEnterDebugMode),
    .io_out_hasDebugEbreakException(dbg_g_io_out_hasDebugEbreakException),
    .io_out_breakPoint(dbg_g_io_out_breakPoint),
    .io_out_criticalErrorStateEnterDebug(dbg_g_io_out_criticalErrorStateEnterDebug)
  );
  Debug_xs dbg_u_impl (
    .clock(clk),
    .io_in_trapInfo_valid(dbg_io_in_trapInfo_valid),
    .io_in_trapInfo_bits_trapVec(dbg_io_in_trapInfo_bits_trapVec),
    .io_in_trapInfo_bits_isDebugIntr(dbg_io_in_trapInfo_bits_isDebugIntr),
    .io_in_trapInfo_bits_isInterrupt(dbg_io_in_trapInfo_bits_isInterrupt),
    .io_in_trapInfo_bits_singleStep(dbg_io_in_trapInfo_bits_singleStep),
    .io_in_trapInfo_bits_trigger(dbg_io_in_trapInfo_bits_trigger),
    .io_in_trapInfo_bits_criticalErrorState(dbg_io_in_trapInfo_bits_criticalErrorState),
    .io_in_privState_PRVM(dbg_io_in_privState_PRVM),
    .io_in_privState_V(dbg_io_in_privState_V),
    .io_in_debugMode(dbg_io_in_debugMode),
    .io_in_dcsr_CETRIG(dbg_io_in_dcsr_CETRIG),
    .io_in_dcsr_EBREAKVS(dbg_io_in_dcsr_EBREAKVS),
    .io_in_dcsr_EBREAKVU(dbg_io_in_dcsr_EBREAKVU),
    .io_in_dcsr_EBREAKM(dbg_io_in_dcsr_EBREAKM),
    .io_in_dcsr_EBREAKS(dbg_io_in_dcsr_EBREAKS),
    .io_in_dcsr_EBREAKU(dbg_io_in_dcsr_EBREAKU),
    .io_in_tselect_ALL(dbg_io_in_tselect_ALL),
    .io_in_tdata1Selected_DATA(dbg_io_in_tdata1Selected_DATA),
    .io_in_tdata2Selected_ALL(dbg_io_in_tdata2Selected_ALL),
    .io_in_tdata1Vec_0_TYPE(dbg_io_in_tdata1Vec_0_TYPE),
    .io_in_tdata1Vec_0_DATA(dbg_io_in_tdata1Vec_0_DATA),
    .io_in_tdata1Vec_1_TYPE(dbg_io_in_tdata1Vec_1_TYPE),
    .io_in_tdata1Vec_1_DATA(dbg_io_in_tdata1Vec_1_DATA),
    .io_in_tdata1Vec_2_TYPE(dbg_io_in_tdata1Vec_2_TYPE),
    .io_in_tdata1Vec_2_DATA(dbg_io_in_tdata1Vec_2_DATA),
    .io_in_tdata1Vec_3_TYPE(dbg_io_in_tdata1Vec_3_TYPE),
    .io_in_tdata1Vec_3_DATA(dbg_io_in_tdata1Vec_3_DATA),
    .io_in_triggerCanRaiseBpExp(dbg_io_in_triggerCanRaiseBpExp),
    .io_in_tdata1Update(dbg_io_in_tdata1Update),
    .io_in_tdata2Update(dbg_io_in_tdata2Update),
    .io_in_tdata1Wdata_TYPE(dbg_io_in_tdata1Wdata_TYPE),
    .io_in_tdata1Wdata_DATA(dbg_io_in_tdata1Wdata_DATA),
    .io_out_triggerFrontendChange(dbg_i_io_out_triggerFrontendChange),
    .io_out_newTriggerChainIsLegal(dbg_i_io_out_newTriggerChainIsLegal),
    .io_out_memTrigger_tUpdate_valid(dbg_i_io_out_memTrigger_tUpdate_valid),
    .io_out_memTrigger_tUpdate_bits_addr(dbg_i_io_out_memTrigger_tUpdate_bits_addr),
    .io_out_memTrigger_tUpdate_bits_tdata_matchType(dbg_i_io_out_memTrigger_tUpdate_bits_tdata_matchType),
    .io_out_memTrigger_tUpdate_bits_tdata_select(dbg_i_io_out_memTrigger_tUpdate_bits_tdata_select),
    .io_out_memTrigger_tUpdate_bits_tdata_action(dbg_i_io_out_memTrigger_tUpdate_bits_tdata_action),
    .io_out_memTrigger_tUpdate_bits_tdata_chain(dbg_i_io_out_memTrigger_tUpdate_bits_tdata_chain),
    .io_out_memTrigger_tUpdate_bits_tdata_store(dbg_i_io_out_memTrigger_tUpdate_bits_tdata_store),
    .io_out_memTrigger_tUpdate_bits_tdata_load(dbg_i_io_out_memTrigger_tUpdate_bits_tdata_load),
    .io_out_memTrigger_tUpdate_bits_tdata_tdata2(dbg_i_io_out_memTrigger_tUpdate_bits_tdata_tdata2),
    .io_out_memTrigger_tEnableVec_0(dbg_i_io_out_memTrigger_tEnableVec_0),
    .io_out_memTrigger_tEnableVec_1(dbg_i_io_out_memTrigger_tEnableVec_1),
    .io_out_memTrigger_tEnableVec_2(dbg_i_io_out_memTrigger_tEnableVec_2),
    .io_out_memTrigger_tEnableVec_3(dbg_i_io_out_memTrigger_tEnableVec_3),
    .io_out_memTrigger_debugMode(dbg_i_io_out_memTrigger_debugMode),
    .io_out_memTrigger_triggerCanRaiseBpExp(dbg_i_io_out_memTrigger_triggerCanRaiseBpExp),
    .io_out_frontendTrigger_tUpdate_valid(dbg_i_io_out_frontendTrigger_tUpdate_valid),
    .io_out_frontendTrigger_tUpdate_bits_addr(dbg_i_io_out_frontendTrigger_tUpdate_bits_addr),
    .io_out_frontendTrigger_tUpdate_bits_tdata_matchType(dbg_i_io_out_frontendTrigger_tUpdate_bits_tdata_matchType),
    .io_out_frontendTrigger_tUpdate_bits_tdata_select(dbg_i_io_out_frontendTrigger_tUpdate_bits_tdata_select),
    .io_out_frontendTrigger_tUpdate_bits_tdata_action(dbg_i_io_out_frontendTrigger_tUpdate_bits_tdata_action),
    .io_out_frontendTrigger_tUpdate_bits_tdata_chain(dbg_i_io_out_frontendTrigger_tUpdate_bits_tdata_chain),
    .io_out_frontendTrigger_tUpdate_bits_tdata_tdata2(dbg_i_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2),
    .io_out_frontendTrigger_tEnableVec_0(dbg_i_io_out_frontendTrigger_tEnableVec_0),
    .io_out_frontendTrigger_tEnableVec_1(dbg_i_io_out_frontendTrigger_tEnableVec_1),
    .io_out_frontendTrigger_tEnableVec_2(dbg_i_io_out_frontendTrigger_tEnableVec_2),
    .io_out_frontendTrigger_tEnableVec_3(dbg_i_io_out_frontendTrigger_tEnableVec_3),
    .io_out_frontendTrigger_debugMode(dbg_i_io_out_frontendTrigger_debugMode),
    .io_out_frontendTrigger_triggerCanRaiseBpExp(dbg_i_io_out_frontendTrigger_triggerCanRaiseBpExp),
    .io_out_hasDebugTrap(dbg_i_io_out_hasDebugTrap),
    .io_out_hasDebugIntr(dbg_i_io_out_hasDebugIntr),
    .io_out_hasSingleStep(dbg_i_io_out_hasSingleStep),
    .io_out_triggerEnterDebugMode(dbg_i_io_out_triggerEnterDebugMode),
    .io_out_hasDebugEbreakException(dbg_i_io_out_hasDebugEbreakException),
    .io_out_breakPoint(dbg_i_io_out_breakPoint),
    .io_out_criticalErrorStateEnterDebug(dbg_i_io_out_criticalErrorStateEnterDebug)
  );

  // ================= MieModule =================
  int unsigned mie_mode = 0;
  logic mie_reset;
  logic mie_w_wen;
  logic [63:0] mie_w_wdata;
  wire  [63:0] mie_g_rdata, mie_i_rdata;
  logic [63:0] mie_s0_rdata = '0, mie_s1_rdata = '0;
  wire  mie_g_regOut_SSIE, mie_i_regOut_SSIE;
  logic mie_s0_regOut_SSIE = '0, mie_s1_regOut_SSIE = '0;
  wire  mie_g_regOut_VSSIE, mie_i_regOut_VSSIE;
  logic mie_s0_regOut_VSSIE = '0, mie_s1_regOut_VSSIE = '0;
  wire  mie_g_regOut_MSIE, mie_i_regOut_MSIE;
  logic mie_s0_regOut_MSIE = '0, mie_s1_regOut_MSIE = '0;
  wire  mie_g_regOut_STIE, mie_i_regOut_STIE;
  logic mie_s0_regOut_STIE = '0, mie_s1_regOut_STIE = '0;
  wire  mie_g_regOut_VSTIE, mie_i_regOut_VSTIE;
  logic mie_s0_regOut_VSTIE = '0, mie_s1_regOut_VSTIE = '0;
  wire  mie_g_regOut_MTIE, mie_i_regOut_MTIE;
  logic mie_s0_regOut_MTIE = '0, mie_s1_regOut_MTIE = '0;
  wire  mie_g_regOut_SEIE, mie_i_regOut_SEIE;
  logic mie_s0_regOut_SEIE = '0, mie_s1_regOut_SEIE = '0;
  wire  mie_g_regOut_VSEIE, mie_i_regOut_VSEIE;
  logic mie_s0_regOut_VSEIE = '0, mie_s1_regOut_VSEIE = '0;
  wire  mie_g_regOut_MEIE, mie_i_regOut_MEIE;
  logic mie_s0_regOut_MEIE = '0, mie_s1_regOut_MEIE = '0;
  wire  mie_g_regOut_SGEIE, mie_i_regOut_SGEIE;
  logic mie_s0_regOut_SGEIE = '0, mie_s1_regOut_SGEIE = '0;
  wire  mie_g_regOut_LCOFIE, mie_i_regOut_LCOFIE;
  logic mie_s0_regOut_LCOFIE = '0, mie_s1_regOut_LCOFIE = '0;
  logic mie_fromHie_VSSIE_valid;
  logic mie_fromHie_VSSIE_bits;
  logic mie_fromHie_VSTIE_valid;
  logic mie_fromHie_VSTIE_bits;
  logic mie_fromHie_VSEIE_valid;
  logic mie_fromHie_VSEIE_bits;
  logic mie_fromHie_SGEIE_valid;
  logic mie_fromHie_SGEIE_bits;
  logic mie_fromSie_SSIE_valid;
  logic mie_fromSie_SSIE_bits;
  logic mie_fromSie_STIE_valid;
  logic mie_fromSie_STIE_bits;
  logic mie_fromSie_SEIE_valid;
  logic mie_fromSie_SEIE_bits;
  logic mie_fromSie_LCOFIE_valid;
  logic mie_fromSie_LCOFIE_bits;
  logic mie_fromVSie_VSSIE_valid;
  logic mie_fromVSie_VSSIE_bits;
  logic mie_fromVSie_VSTIE_valid;
  logic mie_fromVSie_VSTIE_bits;
  logic mie_fromVSie_VSEIE_valid;
  logic mie_fromVSie_VSEIE_bits;
  logic mie_fromVSie_LCOFIE_valid;
  logic mie_fromVSie_LCOFIE_bits;
  int mie_cov_csr_wr_only = 0;
  int mie_cov_sie_wr = 0;
  int mie_cov_hie_vsie_both = 0;
  int mie_cov_vsie_lcofi = 0;
  int mie_cov_m_bit_set = 0;
  logic [0:0] mie_armed = '0;
  int mie_armed_at = -1;
  MieModule mie_u_gold (
    .clock(clk),
    .reset(mie_reset),
    .w_wen(mie_w_wen),
    .w_wdata(mie_w_wdata),
    .rdata(mie_g_rdata),
    .regOut_SSIE(mie_g_regOut_SSIE),
    .regOut_VSSIE(mie_g_regOut_VSSIE),
    .regOut_MSIE(mie_g_regOut_MSIE),
    .regOut_STIE(mie_g_regOut_STIE),
    .regOut_VSTIE(mie_g_regOut_VSTIE),
    .regOut_MTIE(mie_g_regOut_MTIE),
    .regOut_SEIE(mie_g_regOut_SEIE),
    .regOut_VSEIE(mie_g_regOut_VSEIE),
    .regOut_MEIE(mie_g_regOut_MEIE),
    .regOut_SGEIE(mie_g_regOut_SGEIE),
    .regOut_LCOFIE(mie_g_regOut_LCOFIE),
    .fromHie_VSSIE_valid(mie_fromHie_VSSIE_valid),
    .fromHie_VSSIE_bits(mie_fromHie_VSSIE_bits),
    .fromHie_VSTIE_valid(mie_fromHie_VSTIE_valid),
    .fromHie_VSTIE_bits(mie_fromHie_VSTIE_bits),
    .fromHie_VSEIE_valid(mie_fromHie_VSEIE_valid),
    .fromHie_VSEIE_bits(mie_fromHie_VSEIE_bits),
    .fromHie_SGEIE_valid(mie_fromHie_SGEIE_valid),
    .fromHie_SGEIE_bits(mie_fromHie_SGEIE_bits),
    .fromSie_SSIE_valid(mie_fromSie_SSIE_valid),
    .fromSie_SSIE_bits(mie_fromSie_SSIE_bits),
    .fromSie_STIE_valid(mie_fromSie_STIE_valid),
    .fromSie_STIE_bits(mie_fromSie_STIE_bits),
    .fromSie_SEIE_valid(mie_fromSie_SEIE_valid),
    .fromSie_SEIE_bits(mie_fromSie_SEIE_bits),
    .fromSie_LCOFIE_valid(mie_fromSie_LCOFIE_valid),
    .fromSie_LCOFIE_bits(mie_fromSie_LCOFIE_bits),
    .fromVSie_VSSIE_valid(mie_fromVSie_VSSIE_valid),
    .fromVSie_VSSIE_bits(mie_fromVSie_VSSIE_bits),
    .fromVSie_VSTIE_valid(mie_fromVSie_VSTIE_valid),
    .fromVSie_VSTIE_bits(mie_fromVSie_VSTIE_bits),
    .fromVSie_VSEIE_valid(mie_fromVSie_VSEIE_valid),
    .fromVSie_VSEIE_bits(mie_fromVSie_VSEIE_bits),
    .fromVSie_LCOFIE_valid(mie_fromVSie_LCOFIE_valid),
    .fromVSie_LCOFIE_bits(mie_fromVSie_LCOFIE_bits)
  );
  MieModule_xs mie_u_impl (
    .clock(clk),
    .reset(mie_reset),
    .w_wen(mie_w_wen),
    .w_wdata(mie_w_wdata),
    .rdata(mie_i_rdata),
    .regOut_SSIE(mie_i_regOut_SSIE),
    .regOut_VSSIE(mie_i_regOut_VSSIE),
    .regOut_MSIE(mie_i_regOut_MSIE),
    .regOut_STIE(mie_i_regOut_STIE),
    .regOut_VSTIE(mie_i_regOut_VSTIE),
    .regOut_MTIE(mie_i_regOut_MTIE),
    .regOut_SEIE(mie_i_regOut_SEIE),
    .regOut_VSEIE(mie_i_regOut_VSEIE),
    .regOut_MEIE(mie_i_regOut_MEIE),
    .regOut_SGEIE(mie_i_regOut_SGEIE),
    .regOut_LCOFIE(mie_i_regOut_LCOFIE),
    .fromHie_VSSIE_valid(mie_fromHie_VSSIE_valid),
    .fromHie_VSSIE_bits(mie_fromHie_VSSIE_bits),
    .fromHie_VSTIE_valid(mie_fromHie_VSTIE_valid),
    .fromHie_VSTIE_bits(mie_fromHie_VSTIE_bits),
    .fromHie_VSEIE_valid(mie_fromHie_VSEIE_valid),
    .fromHie_VSEIE_bits(mie_fromHie_VSEIE_bits),
    .fromHie_SGEIE_valid(mie_fromHie_SGEIE_valid),
    .fromHie_SGEIE_bits(mie_fromHie_SGEIE_bits),
    .fromSie_SSIE_valid(mie_fromSie_SSIE_valid),
    .fromSie_SSIE_bits(mie_fromSie_SSIE_bits),
    .fromSie_STIE_valid(mie_fromSie_STIE_valid),
    .fromSie_STIE_bits(mie_fromSie_STIE_bits),
    .fromSie_SEIE_valid(mie_fromSie_SEIE_valid),
    .fromSie_SEIE_bits(mie_fromSie_SEIE_bits),
    .fromSie_LCOFIE_valid(mie_fromSie_LCOFIE_valid),
    .fromSie_LCOFIE_bits(mie_fromSie_LCOFIE_bits),
    .fromVSie_VSSIE_valid(mie_fromVSie_VSSIE_valid),
    .fromVSie_VSSIE_bits(mie_fromVSie_VSSIE_bits),
    .fromVSie_VSTIE_valid(mie_fromVSie_VSTIE_valid),
    .fromVSie_VSTIE_bits(mie_fromVSie_VSTIE_bits),
    .fromVSie_VSEIE_valid(mie_fromVSie_VSEIE_valid),
    .fromVSie_VSEIE_bits(mie_fromVSie_VSEIE_bits),
    .fromVSie_LCOFIE_valid(mie_fromVSie_LCOFIE_valid),
    .fromVSie_LCOFIE_bits(mie_fromVSie_LCOFIE_bits)
  );

  // ================= timeModule =================
  int unsigned tm_mode = 0;
  logic tm_reset;
  wire  [63:0] tm_g_rdata, tm_i_rdata;
  logic [63:0] tm_s0_rdata = '0, tm_s1_rdata = '0;
  logic tm_mHPM_time_valid;
  logic [63:0] tm_mHPM_time_bits;
  logic tm_v;
  logic tm_nextV;
  logic [63:0] tm_htimedelta;
  logic tm_debugModeStopTime;
  wire  tm_g_updated, tm_i_updated;
  logic tm_s0_updated = '0, tm_s1_updated = '0;
  wire  [63:0] tm_g_stime, tm_i_stime;
  logic [63:0] tm_s0_stime = '0, tm_s1_stime = '0;
  wire  [63:0] tm_g_vstime, tm_i_vstime;
  logic [63:0] tm_s0_vstime = '0, tm_s1_vstime = '0;
  int tm_cov_tick = 0;
  int tm_cov_stopped_tick = 0;
  int tm_cov_v_change = 0;
  int tm_cov_guest_view = 0;
  logic [0:0] tm_armed = '0;
  int tm_armed_at = -1;
  timeModule tm_u_gold (
    .clock(clk),
    .reset(tm_reset),
    .rdata(tm_g_rdata),
    .mHPM_time_valid(tm_mHPM_time_valid),
    .mHPM_time_bits(tm_mHPM_time_bits),
    .v(tm_v),
    .nextV(tm_nextV),
    .htimedelta(tm_htimedelta),
    .debugModeStopTime(tm_debugModeStopTime),
    .updated(tm_g_updated),
    .stime(tm_g_stime),
    .vstime(tm_g_vstime)
  );
  timeModule_xs tm_u_impl (
    .clock(clk),
    .reset(tm_reset),
    .rdata(tm_i_rdata),
    .mHPM_time_valid(tm_mHPM_time_valid),
    .mHPM_time_bits(tm_mHPM_time_bits),
    .v(tm_v),
    .nextV(tm_nextV),
    .htimedelta(tm_htimedelta),
    .debugModeStopTime(tm_debugModeStopTime),
    .updated(tm_i_updated),
    .stime(tm_i_stime),
    .vstime(tm_i_vstime)
  );

  // ================= XRetPermitModule =================
  int unsigned xr_mode = 0;
  logic [1:0] xr_io_in_privState_PRVM;
  logic xr_io_in_privState_V;
  logic xr_io_in_debugMode;
  logic xr_io_in_xRet_mnret;
  logic xr_io_in_xRet_mret;
  logic xr_io_in_xRet_sret;
  logic xr_io_in_xRet_dret;
  logic xr_io_in_status_tsr;
  logic xr_io_in_status_vtsr;
  wire  xr_g_io_out_Xret_EX_II, xr_i_io_out_Xret_EX_II;
  logic xr_s0_io_out_Xret_EX_II = '0, xr_s1_io_out_Xret_EX_II = '0;
  wire  xr_g_io_out_Xret_EX_VI, xr_i_io_out_Xret_EX_VI;
  logic xr_s0_io_out_Xret_EX_VI = '0, xr_s1_io_out_Xret_EX_VI = '0;
  wire  xr_g_io_out_hasLegalMNret, xr_i_io_out_hasLegalMNret;
  logic xr_s0_io_out_hasLegalMNret = '0, xr_s1_io_out_hasLegalMNret = '0;
  wire  xr_g_io_out_hasLegalMret, xr_i_io_out_hasLegalMret;
  logic xr_s0_io_out_hasLegalMret = '0, xr_s1_io_out_hasLegalMret = '0;
  wire  xr_g_io_out_hasLegalSret, xr_i_io_out_hasLegalSret;
  logic xr_s0_io_out_hasLegalSret = '0, xr_s1_io_out_hasLegalSret = '0;
  wire  xr_g_io_out_hasLegalDret, xr_i_io_out_hasLegalDret;
  logic xr_s0_io_out_hasLegalDret = '0, xr_s1_io_out_hasLegalDret = '0;
  int xr_cov_ex_ii = 0;
  int xr_cov_ex_vi = 0;
  int xr_cov_legal_sret = 0;
  int xr_cov_legal_mnret = 0;
  logic [0:0] xr_armed = '0;
  int xr_armed_at = -1;
  XRetPermitModule xr_u_gold (
    .io_in_privState_PRVM(xr_io_in_privState_PRVM),
    .io_in_privState_V(xr_io_in_privState_V),
    .io_in_debugMode(xr_io_in_debugMode),
    .io_in_xRet_mnret(xr_io_in_xRet_mnret),
    .io_in_xRet_mret(xr_io_in_xRet_mret),
    .io_in_xRet_sret(xr_io_in_xRet_sret),
    .io_in_xRet_dret(xr_io_in_xRet_dret),
    .io_in_status_tsr(xr_io_in_status_tsr),
    .io_in_status_vtsr(xr_io_in_status_vtsr),
    .io_out_Xret_EX_II(xr_g_io_out_Xret_EX_II),
    .io_out_Xret_EX_VI(xr_g_io_out_Xret_EX_VI),
    .io_out_hasLegalMNret(xr_g_io_out_hasLegalMNret),
    .io_out_hasLegalMret(xr_g_io_out_hasLegalMret),
    .io_out_hasLegalSret(xr_g_io_out_hasLegalSret),
    .io_out_hasLegalDret(xr_g_io_out_hasLegalDret)
  );
  XRetPermitModule_xs xr_u_impl (
    .io_in_privState_PRVM(xr_io_in_privState_PRVM),
    .io_in_privState_V(xr_io_in_privState_V),
    .io_in_debugMode(xr_io_in_debugMode),
    .io_in_xRet_mnret(xr_io_in_xRet_mnret),
    .io_in_xRet_mret(xr_io_in_xRet_mret),
    .io_in_xRet_sret(xr_io_in_xRet_sret),
    .io_in_xRet_dret(xr_io_in_xRet_dret),
    .io_in_status_tsr(xr_io_in_status_tsr),
    .io_in_status_vtsr(xr_io_in_status_vtsr),
    .io_out_Xret_EX_II(xr_i_io_out_Xret_EX_II),
    .io_out_Xret_EX_VI(xr_i_io_out_Xret_EX_VI),
    .io_out_hasLegalMNret(xr_i_io_out_hasLegalMNret),
    .io_out_hasLegalMret(xr_i_io_out_hasLegalMret),
    .io_out_hasLegalSret(xr_i_io_out_hasLegalSret),
    .io_out_hasLegalDret(xr_i_io_out_hasLegalDret)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) dbg_mode = $urandom_range(0, 15);
      dbg_io_in_trapInfo_valid = 1'($urandom);
      dbg_io_in_trapInfo_bits_trapVec = 64'({$urandom, $urandom});
      dbg_io_in_trapInfo_bits_isDebugIntr = 1'($urandom);
      dbg_io_in_trapInfo_bits_isInterrupt = 1'($urandom);
      dbg_io_in_trapInfo_bits_singleStep = 1'($urandom);
      dbg_io_in_trapInfo_bits_trigger = 4'($urandom);
      dbg_io_in_trapInfo_bits_criticalErrorState = 1'($urandom);
      dbg_io_in_privState_PRVM = 2'($urandom);
      dbg_io_in_privState_V = 1'($urandom);
      dbg_io_in_debugMode = 1'($urandom);
      dbg_io_in_dcsr_CETRIG = 1'($urandom);
      dbg_io_in_dcsr_EBREAKVS = 1'($urandom);
      dbg_io_in_dcsr_EBREAKVU = 1'($urandom);
      dbg_io_in_dcsr_EBREAKM = 1'($urandom);
      dbg_io_in_dcsr_EBREAKS = 1'($urandom);
      dbg_io_in_dcsr_EBREAKU = 1'($urandom);
      dbg_io_in_tselect_ALL = 2'($urandom);
      dbg_io_in_tdata1Selected_DATA = 59'({$urandom, $urandom});
      dbg_io_in_tdata2Selected_ALL = 64'({$urandom, $urandom});
      dbg_io_in_tdata1Vec_0_TYPE = 4'($urandom);
      dbg_io_in_tdata1Vec_0_DATA = 59'({$urandom, $urandom});
      dbg_io_in_tdata1Vec_1_TYPE = 4'($urandom);
      dbg_io_in_tdata1Vec_1_DATA = 59'({$urandom, $urandom});
      dbg_io_in_tdata1Vec_2_TYPE = 4'($urandom);
      dbg_io_in_tdata1Vec_2_DATA = 59'({$urandom, $urandom});
      dbg_io_in_tdata1Vec_3_TYPE = 4'($urandom);
      dbg_io_in_tdata1Vec_3_DATA = 59'({$urandom, $urandom});
      dbg_io_in_triggerCanRaiseBpExp = 1'($urandom);
      dbg_io_in_tdata1Update = 1'($urandom);
      dbg_io_in_tdata2Update = 1'($urandom);
      dbg_io_in_tdata1Wdata_TYPE = 4'($urandom);
      dbg_io_in_tdata1Wdata_DATA = 59'({$urandom, $urandom});
      begin : stim_dbg
        if ($urandom_range(0, 3) != 0) dbg_io_in_tdata1Vec_0_TYPE = 4'd6;
        if ($urandom_range(0, 3) != 0) dbg_io_in_tdata1Vec_1_TYPE = 4'd6;
        if ($urandom_range(0, 3) != 0) dbg_io_in_tdata1Vec_2_TYPE = 4'd6;
        if ($urandom_range(0, 3) != 0) dbg_io_in_tdata1Vec_3_TYPE = 4'd6;
        if ($urandom_range(0, 3) != 0) dbg_io_in_tdata1Wdata_TYPE = 4'd6;
        case ($urandom_range(0, 3))
          0: dbg_io_in_trapInfo_bits_trigger = 4'd0;
          1: dbg_io_in_trapInfo_bits_trigger = 4'd1;
          2: dbg_io_in_trapInfo_bits_trigger = 4'd15;
          default: ;
        endcase
        if (dbg_mode % 2 == 0) begin
          dbg_io_in_tdata1Vec_0_DATA[11] = ($urandom_range(0, 3) == 0);
          dbg_io_in_tdata1Vec_1_DATA[11] = ($urandom_range(0, 3) == 0);
          dbg_io_in_tdata1Vec_2_DATA[11] = ($urandom_range(0, 3) == 0);
          dbg_io_in_tdata1Vec_3_DATA[11] = ($urandom_range(0, 3) == 0);
        end
      end
      if (cyc % 4000 == 0) mie_mode = $urandom_range(0, 15);
      mie_w_wen = 1'($urandom);
      mie_w_wdata = 64'({$urandom, $urandom});
      mie_fromHie_VSSIE_valid = 1'($urandom);
      mie_fromHie_VSSIE_bits = 1'($urandom);
      mie_fromHie_VSTIE_valid = 1'($urandom);
      mie_fromHie_VSTIE_bits = 1'($urandom);
      mie_fromHie_VSEIE_valid = 1'($urandom);
      mie_fromHie_VSEIE_bits = 1'($urandom);
      mie_fromHie_SGEIE_valid = 1'($urandom);
      mie_fromHie_SGEIE_bits = 1'($urandom);
      mie_fromSie_SSIE_valid = 1'($urandom);
      mie_fromSie_SSIE_bits = 1'($urandom);
      mie_fromSie_STIE_valid = 1'($urandom);
      mie_fromSie_STIE_bits = 1'($urandom);
      mie_fromSie_SEIE_valid = 1'($urandom);
      mie_fromSie_SEIE_bits = 1'($urandom);
      mie_fromSie_LCOFIE_valid = 1'($urandom);
      mie_fromSie_LCOFIE_bits = 1'($urandom);
      mie_fromVSie_VSSIE_valid = 1'($urandom);
      mie_fromVSie_VSSIE_bits = 1'($urandom);
      mie_fromVSie_VSTIE_valid = 1'($urandom);
      mie_fromVSie_VSTIE_bits = 1'($urandom);
      mie_fromVSie_VSEIE_valid = 1'($urandom);
      mie_fromVSie_VSEIE_bits = 1'($urandom);
      mie_fromVSie_LCOFIE_valid = 1'($urandom);
      mie_fromVSie_LCOFIE_bits = 1'($urandom);
      mie_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_mie
        if (mie_mode % 2 == 0) begin
          if ($urandom_range(0, 7) != 0) mie_fromHie_VSSIE_valid = 1'b0;
          if ($urandom_range(0, 7) != 0) mie_fromHie_VSTIE_valid = 1'b0;
          if ($urandom_range(0, 7) != 0) mie_fromHie_VSEIE_valid = 1'b0;
          if ($urandom_range(0, 7) != 0) mie_fromHie_SGEIE_valid = 1'b0;
          if ($urandom_range(0, 7) != 0) mie_fromSie_SSIE_valid = 1'b0;
          if ($urandom_range(0, 7) != 0) mie_fromSie_STIE_valid = 1'b0;
          if ($urandom_range(0, 7) != 0) mie_fromSie_SEIE_valid = 1'b0;
          if ($urandom_range(0, 7) != 0) mie_fromSie_LCOFIE_valid = 1'b0;
          if ($urandom_range(0, 7) != 0) mie_fromVSie_VSSIE_valid = 1'b0;
          if ($urandom_range(0, 7) != 0) mie_fromVSie_VSTIE_valid = 1'b0;
          if ($urandom_range(0, 7) != 0) mie_fromVSie_VSEIE_valid = 1'b0;
          if ($urandom_range(0, 7) != 0) mie_fromVSie_LCOFIE_valid = 1'b0;
        end
      end
      if (cyc % 4000 == 0) tm_mode = $urandom_range(0, 15);
      tm_mHPM_time_valid = 1'($urandom);
      tm_mHPM_time_bits = 64'({$urandom, $urandom});
      tm_v = 1'($urandom);
      tm_nextV = 1'($urandom);
      tm_htimedelta = 64'({$urandom, $urandom});
      tm_debugModeStopTime = 1'($urandom);
      tm_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      if (cyc % 4000 == 0) xr_mode = $urandom_range(0, 15);
      xr_io_in_privState_PRVM = 2'($urandom);
      xr_io_in_privState_V = 1'($urandom);
      xr_io_in_debugMode = 1'($urandom);
      xr_io_in_xRet_mnret = 1'($urandom);
      xr_io_in_xRet_mret = 1'($urandom);
      xr_io_in_xRet_sret = 1'($urandom);
      xr_io_in_xRet_dret = 1'($urandom);
      xr_io_in_status_tsr = 1'($urandom);
      xr_io_in_status_vtsr = 1'($urandom);
      #4;
      dbg_armed = 1'b1;
      if (cyc >= RESET_CYC + 8 && (&dbg_armed)) begin
        checks++;
        if (dbg_g_io_out_triggerFrontendChange !== dbg_i_io_out_triggerFrontendChange) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_triggerFrontendChange g=%h i=%h", cyc, dbg_g_io_out_triggerFrontendChange, dbg_i_io_out_triggerFrontendChange);
        end
        dbg_s1_io_out_triggerFrontendChange |= dbg_g_io_out_triggerFrontendChange;
        dbg_s0_io_out_triggerFrontendChange |= ~dbg_g_io_out_triggerFrontendChange;
        checks++;
        if (dbg_g_io_out_newTriggerChainIsLegal !== dbg_i_io_out_newTriggerChainIsLegal) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_newTriggerChainIsLegal g=%h i=%h", cyc, dbg_g_io_out_newTriggerChainIsLegal, dbg_i_io_out_newTriggerChainIsLegal);
        end
        dbg_s1_io_out_newTriggerChainIsLegal |= dbg_g_io_out_newTriggerChainIsLegal;
        dbg_s0_io_out_newTriggerChainIsLegal |= ~dbg_g_io_out_newTriggerChainIsLegal;
        checks++;
        if (dbg_g_io_out_memTrigger_tUpdate_valid !== dbg_i_io_out_memTrigger_tUpdate_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_memTrigger_tUpdate_valid g=%h i=%h", cyc, dbg_g_io_out_memTrigger_tUpdate_valid, dbg_i_io_out_memTrigger_tUpdate_valid);
        end
        dbg_s1_io_out_memTrigger_tUpdate_valid |= dbg_g_io_out_memTrigger_tUpdate_valid;
        dbg_s0_io_out_memTrigger_tUpdate_valid |= ~dbg_g_io_out_memTrigger_tUpdate_valid;
        checks++;
        if (dbg_g_io_out_memTrigger_tUpdate_bits_addr !== dbg_i_io_out_memTrigger_tUpdate_bits_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_memTrigger_tUpdate_bits_addr g=%h i=%h", cyc, dbg_g_io_out_memTrigger_tUpdate_bits_addr, dbg_i_io_out_memTrigger_tUpdate_bits_addr);
        end
        dbg_s1_io_out_memTrigger_tUpdate_bits_addr |= dbg_g_io_out_memTrigger_tUpdate_bits_addr;
        dbg_s0_io_out_memTrigger_tUpdate_bits_addr |= ~dbg_g_io_out_memTrigger_tUpdate_bits_addr;
        checks++;
        if (dbg_g_io_out_memTrigger_tUpdate_bits_tdata_matchType !== dbg_i_io_out_memTrigger_tUpdate_bits_tdata_matchType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_memTrigger_tUpdate_bits_tdata_matchType g=%h i=%h", cyc, dbg_g_io_out_memTrigger_tUpdate_bits_tdata_matchType, dbg_i_io_out_memTrigger_tUpdate_bits_tdata_matchType);
        end
        dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_matchType |= dbg_g_io_out_memTrigger_tUpdate_bits_tdata_matchType;
        dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_matchType |= ~dbg_g_io_out_memTrigger_tUpdate_bits_tdata_matchType;
        checks++;
        if (dbg_g_io_out_memTrigger_tUpdate_bits_tdata_select !== dbg_i_io_out_memTrigger_tUpdate_bits_tdata_select) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_memTrigger_tUpdate_bits_tdata_select g=%h i=%h", cyc, dbg_g_io_out_memTrigger_tUpdate_bits_tdata_select, dbg_i_io_out_memTrigger_tUpdate_bits_tdata_select);
        end
        dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_select |= dbg_g_io_out_memTrigger_tUpdate_bits_tdata_select;
        dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_select |= ~dbg_g_io_out_memTrigger_tUpdate_bits_tdata_select;
        checks++;
        if (dbg_g_io_out_memTrigger_tUpdate_bits_tdata_action !== dbg_i_io_out_memTrigger_tUpdate_bits_tdata_action) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_memTrigger_tUpdate_bits_tdata_action g=%h i=%h", cyc, dbg_g_io_out_memTrigger_tUpdate_bits_tdata_action, dbg_i_io_out_memTrigger_tUpdate_bits_tdata_action);
        end
        dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_action |= dbg_g_io_out_memTrigger_tUpdate_bits_tdata_action;
        dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_action |= ~dbg_g_io_out_memTrigger_tUpdate_bits_tdata_action;
        checks++;
        if (dbg_g_io_out_memTrigger_tUpdate_bits_tdata_chain !== dbg_i_io_out_memTrigger_tUpdate_bits_tdata_chain) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_memTrigger_tUpdate_bits_tdata_chain g=%h i=%h", cyc, dbg_g_io_out_memTrigger_tUpdate_bits_tdata_chain, dbg_i_io_out_memTrigger_tUpdate_bits_tdata_chain);
        end
        dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_chain |= dbg_g_io_out_memTrigger_tUpdate_bits_tdata_chain;
        dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_chain |= ~dbg_g_io_out_memTrigger_tUpdate_bits_tdata_chain;
        checks++;
        if (dbg_g_io_out_memTrigger_tUpdate_bits_tdata_store !== dbg_i_io_out_memTrigger_tUpdate_bits_tdata_store) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_memTrigger_tUpdate_bits_tdata_store g=%h i=%h", cyc, dbg_g_io_out_memTrigger_tUpdate_bits_tdata_store, dbg_i_io_out_memTrigger_tUpdate_bits_tdata_store);
        end
        dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_store |= dbg_g_io_out_memTrigger_tUpdate_bits_tdata_store;
        dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_store |= ~dbg_g_io_out_memTrigger_tUpdate_bits_tdata_store;
        checks++;
        if (dbg_g_io_out_memTrigger_tUpdate_bits_tdata_load !== dbg_i_io_out_memTrigger_tUpdate_bits_tdata_load) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_memTrigger_tUpdate_bits_tdata_load g=%h i=%h", cyc, dbg_g_io_out_memTrigger_tUpdate_bits_tdata_load, dbg_i_io_out_memTrigger_tUpdate_bits_tdata_load);
        end
        dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_load |= dbg_g_io_out_memTrigger_tUpdate_bits_tdata_load;
        dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_load |= ~dbg_g_io_out_memTrigger_tUpdate_bits_tdata_load;
        checks++;
        if (dbg_g_io_out_memTrigger_tUpdate_bits_tdata_tdata2 !== dbg_i_io_out_memTrigger_tUpdate_bits_tdata_tdata2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2 g=%h i=%h", cyc, dbg_g_io_out_memTrigger_tUpdate_bits_tdata_tdata2, dbg_i_io_out_memTrigger_tUpdate_bits_tdata_tdata2);
        end
        dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2 |= dbg_g_io_out_memTrigger_tUpdate_bits_tdata_tdata2;
        dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2 |= ~dbg_g_io_out_memTrigger_tUpdate_bits_tdata_tdata2;
        checks++;
        if (dbg_g_io_out_memTrigger_tEnableVec_0 !== dbg_i_io_out_memTrigger_tEnableVec_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_memTrigger_tEnableVec_0 g=%h i=%h", cyc, dbg_g_io_out_memTrigger_tEnableVec_0, dbg_i_io_out_memTrigger_tEnableVec_0);
        end
        dbg_s1_io_out_memTrigger_tEnableVec_0 |= dbg_g_io_out_memTrigger_tEnableVec_0;
        dbg_s0_io_out_memTrigger_tEnableVec_0 |= ~dbg_g_io_out_memTrigger_tEnableVec_0;
        checks++;
        if (dbg_g_io_out_memTrigger_tEnableVec_1 !== dbg_i_io_out_memTrigger_tEnableVec_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_memTrigger_tEnableVec_1 g=%h i=%h", cyc, dbg_g_io_out_memTrigger_tEnableVec_1, dbg_i_io_out_memTrigger_tEnableVec_1);
        end
        dbg_s1_io_out_memTrigger_tEnableVec_1 |= dbg_g_io_out_memTrigger_tEnableVec_1;
        dbg_s0_io_out_memTrigger_tEnableVec_1 |= ~dbg_g_io_out_memTrigger_tEnableVec_1;
        checks++;
        if (dbg_g_io_out_memTrigger_tEnableVec_2 !== dbg_i_io_out_memTrigger_tEnableVec_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_memTrigger_tEnableVec_2 g=%h i=%h", cyc, dbg_g_io_out_memTrigger_tEnableVec_2, dbg_i_io_out_memTrigger_tEnableVec_2);
        end
        dbg_s1_io_out_memTrigger_tEnableVec_2 |= dbg_g_io_out_memTrigger_tEnableVec_2;
        dbg_s0_io_out_memTrigger_tEnableVec_2 |= ~dbg_g_io_out_memTrigger_tEnableVec_2;
        checks++;
        if (dbg_g_io_out_memTrigger_tEnableVec_3 !== dbg_i_io_out_memTrigger_tEnableVec_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_memTrigger_tEnableVec_3 g=%h i=%h", cyc, dbg_g_io_out_memTrigger_tEnableVec_3, dbg_i_io_out_memTrigger_tEnableVec_3);
        end
        dbg_s1_io_out_memTrigger_tEnableVec_3 |= dbg_g_io_out_memTrigger_tEnableVec_3;
        dbg_s0_io_out_memTrigger_tEnableVec_3 |= ~dbg_g_io_out_memTrigger_tEnableVec_3;
        checks++;
        if (dbg_g_io_out_memTrigger_debugMode !== dbg_i_io_out_memTrigger_debugMode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_memTrigger_debugMode g=%h i=%h", cyc, dbg_g_io_out_memTrigger_debugMode, dbg_i_io_out_memTrigger_debugMode);
        end
        dbg_s1_io_out_memTrigger_debugMode |= dbg_g_io_out_memTrigger_debugMode;
        dbg_s0_io_out_memTrigger_debugMode |= ~dbg_g_io_out_memTrigger_debugMode;
        checks++;
        if (dbg_g_io_out_memTrigger_triggerCanRaiseBpExp !== dbg_i_io_out_memTrigger_triggerCanRaiseBpExp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_memTrigger_triggerCanRaiseBpExp g=%h i=%h", cyc, dbg_g_io_out_memTrigger_triggerCanRaiseBpExp, dbg_i_io_out_memTrigger_triggerCanRaiseBpExp);
        end
        dbg_s1_io_out_memTrigger_triggerCanRaiseBpExp |= dbg_g_io_out_memTrigger_triggerCanRaiseBpExp;
        dbg_s0_io_out_memTrigger_triggerCanRaiseBpExp |= ~dbg_g_io_out_memTrigger_triggerCanRaiseBpExp;
        checks++;
        if (dbg_g_io_out_frontendTrigger_tUpdate_valid !== dbg_i_io_out_frontendTrigger_tUpdate_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_frontendTrigger_tUpdate_valid g=%h i=%h", cyc, dbg_g_io_out_frontendTrigger_tUpdate_valid, dbg_i_io_out_frontendTrigger_tUpdate_valid);
        end
        dbg_s1_io_out_frontendTrigger_tUpdate_valid |= dbg_g_io_out_frontendTrigger_tUpdate_valid;
        dbg_s0_io_out_frontendTrigger_tUpdate_valid |= ~dbg_g_io_out_frontendTrigger_tUpdate_valid;
        checks++;
        if (dbg_g_io_out_frontendTrigger_tUpdate_bits_addr !== dbg_i_io_out_frontendTrigger_tUpdate_bits_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_frontendTrigger_tUpdate_bits_addr g=%h i=%h", cyc, dbg_g_io_out_frontendTrigger_tUpdate_bits_addr, dbg_i_io_out_frontendTrigger_tUpdate_bits_addr);
        end
        dbg_s1_io_out_frontendTrigger_tUpdate_bits_addr |= dbg_g_io_out_frontendTrigger_tUpdate_bits_addr;
        dbg_s0_io_out_frontendTrigger_tUpdate_bits_addr |= ~dbg_g_io_out_frontendTrigger_tUpdate_bits_addr;
        checks++;
        if (dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_matchType !== dbg_i_io_out_frontendTrigger_tUpdate_bits_tdata_matchType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_frontendTrigger_tUpdate_bits_tdata_matchType g=%h i=%h", cyc, dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_matchType, dbg_i_io_out_frontendTrigger_tUpdate_bits_tdata_matchType);
        end
        dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_matchType |= dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_matchType;
        dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_matchType |= ~dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_matchType;
        checks++;
        if (dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_select !== dbg_i_io_out_frontendTrigger_tUpdate_bits_tdata_select) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_frontendTrigger_tUpdate_bits_tdata_select g=%h i=%h", cyc, dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_select, dbg_i_io_out_frontendTrigger_tUpdate_bits_tdata_select);
        end
        dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_select |= dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_select;
        dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_select |= ~dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_select;
        checks++;
        if (dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_action !== dbg_i_io_out_frontendTrigger_tUpdate_bits_tdata_action) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_frontendTrigger_tUpdate_bits_tdata_action g=%h i=%h", cyc, dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_action, dbg_i_io_out_frontendTrigger_tUpdate_bits_tdata_action);
        end
        dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_action |= dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_action;
        dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_action |= ~dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_action;
        checks++;
        if (dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_chain !== dbg_i_io_out_frontendTrigger_tUpdate_bits_tdata_chain) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_frontendTrigger_tUpdate_bits_tdata_chain g=%h i=%h", cyc, dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_chain, dbg_i_io_out_frontendTrigger_tUpdate_bits_tdata_chain);
        end
        dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_chain |= dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_chain;
        dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_chain |= ~dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_chain;
        checks++;
        if (dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2 !== dbg_i_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2 g=%h i=%h", cyc, dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2, dbg_i_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2);
        end
        dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2 |= dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2;
        dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2 |= ~dbg_g_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2;
        checks++;
        if (dbg_g_io_out_frontendTrigger_tEnableVec_0 !== dbg_i_io_out_frontendTrigger_tEnableVec_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_frontendTrigger_tEnableVec_0 g=%h i=%h", cyc, dbg_g_io_out_frontendTrigger_tEnableVec_0, dbg_i_io_out_frontendTrigger_tEnableVec_0);
        end
        dbg_s1_io_out_frontendTrigger_tEnableVec_0 |= dbg_g_io_out_frontendTrigger_tEnableVec_0;
        dbg_s0_io_out_frontendTrigger_tEnableVec_0 |= ~dbg_g_io_out_frontendTrigger_tEnableVec_0;
        checks++;
        if (dbg_g_io_out_frontendTrigger_tEnableVec_1 !== dbg_i_io_out_frontendTrigger_tEnableVec_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_frontendTrigger_tEnableVec_1 g=%h i=%h", cyc, dbg_g_io_out_frontendTrigger_tEnableVec_1, dbg_i_io_out_frontendTrigger_tEnableVec_1);
        end
        dbg_s1_io_out_frontendTrigger_tEnableVec_1 |= dbg_g_io_out_frontendTrigger_tEnableVec_1;
        dbg_s0_io_out_frontendTrigger_tEnableVec_1 |= ~dbg_g_io_out_frontendTrigger_tEnableVec_1;
        checks++;
        if (dbg_g_io_out_frontendTrigger_tEnableVec_2 !== dbg_i_io_out_frontendTrigger_tEnableVec_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_frontendTrigger_tEnableVec_2 g=%h i=%h", cyc, dbg_g_io_out_frontendTrigger_tEnableVec_2, dbg_i_io_out_frontendTrigger_tEnableVec_2);
        end
        dbg_s1_io_out_frontendTrigger_tEnableVec_2 |= dbg_g_io_out_frontendTrigger_tEnableVec_2;
        dbg_s0_io_out_frontendTrigger_tEnableVec_2 |= ~dbg_g_io_out_frontendTrigger_tEnableVec_2;
        checks++;
        if (dbg_g_io_out_frontendTrigger_tEnableVec_3 !== dbg_i_io_out_frontendTrigger_tEnableVec_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_frontendTrigger_tEnableVec_3 g=%h i=%h", cyc, dbg_g_io_out_frontendTrigger_tEnableVec_3, dbg_i_io_out_frontendTrigger_tEnableVec_3);
        end
        dbg_s1_io_out_frontendTrigger_tEnableVec_3 |= dbg_g_io_out_frontendTrigger_tEnableVec_3;
        dbg_s0_io_out_frontendTrigger_tEnableVec_3 |= ~dbg_g_io_out_frontendTrigger_tEnableVec_3;
        checks++;
        if (dbg_g_io_out_frontendTrigger_debugMode !== dbg_i_io_out_frontendTrigger_debugMode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_frontendTrigger_debugMode g=%h i=%h", cyc, dbg_g_io_out_frontendTrigger_debugMode, dbg_i_io_out_frontendTrigger_debugMode);
        end
        dbg_s1_io_out_frontendTrigger_debugMode |= dbg_g_io_out_frontendTrigger_debugMode;
        dbg_s0_io_out_frontendTrigger_debugMode |= ~dbg_g_io_out_frontendTrigger_debugMode;
        checks++;
        if (dbg_g_io_out_frontendTrigger_triggerCanRaiseBpExp !== dbg_i_io_out_frontendTrigger_triggerCanRaiseBpExp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_frontendTrigger_triggerCanRaiseBpExp g=%h i=%h", cyc, dbg_g_io_out_frontendTrigger_triggerCanRaiseBpExp, dbg_i_io_out_frontendTrigger_triggerCanRaiseBpExp);
        end
        dbg_s1_io_out_frontendTrigger_triggerCanRaiseBpExp |= dbg_g_io_out_frontendTrigger_triggerCanRaiseBpExp;
        dbg_s0_io_out_frontendTrigger_triggerCanRaiseBpExp |= ~dbg_g_io_out_frontendTrigger_triggerCanRaiseBpExp;
        checks++;
        if (dbg_g_io_out_hasDebugTrap !== dbg_i_io_out_hasDebugTrap) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_hasDebugTrap g=%h i=%h", cyc, dbg_g_io_out_hasDebugTrap, dbg_i_io_out_hasDebugTrap);
        end
        dbg_s1_io_out_hasDebugTrap |= dbg_g_io_out_hasDebugTrap;
        dbg_s0_io_out_hasDebugTrap |= ~dbg_g_io_out_hasDebugTrap;
        checks++;
        if (dbg_g_io_out_hasDebugIntr !== dbg_i_io_out_hasDebugIntr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_hasDebugIntr g=%h i=%h", cyc, dbg_g_io_out_hasDebugIntr, dbg_i_io_out_hasDebugIntr);
        end
        dbg_s1_io_out_hasDebugIntr |= dbg_g_io_out_hasDebugIntr;
        dbg_s0_io_out_hasDebugIntr |= ~dbg_g_io_out_hasDebugIntr;
        checks++;
        if (dbg_g_io_out_hasSingleStep !== dbg_i_io_out_hasSingleStep) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_hasSingleStep g=%h i=%h", cyc, dbg_g_io_out_hasSingleStep, dbg_i_io_out_hasSingleStep);
        end
        dbg_s1_io_out_hasSingleStep |= dbg_g_io_out_hasSingleStep;
        dbg_s0_io_out_hasSingleStep |= ~dbg_g_io_out_hasSingleStep;
        checks++;
        if (dbg_g_io_out_triggerEnterDebugMode !== dbg_i_io_out_triggerEnterDebugMode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_triggerEnterDebugMode g=%h i=%h", cyc, dbg_g_io_out_triggerEnterDebugMode, dbg_i_io_out_triggerEnterDebugMode);
        end
        dbg_s1_io_out_triggerEnterDebugMode |= dbg_g_io_out_triggerEnterDebugMode;
        dbg_s0_io_out_triggerEnterDebugMode |= ~dbg_g_io_out_triggerEnterDebugMode;
        checks++;
        if (dbg_g_io_out_hasDebugEbreakException !== dbg_i_io_out_hasDebugEbreakException) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_hasDebugEbreakException g=%h i=%h", cyc, dbg_g_io_out_hasDebugEbreakException, dbg_i_io_out_hasDebugEbreakException);
        end
        dbg_s1_io_out_hasDebugEbreakException |= dbg_g_io_out_hasDebugEbreakException;
        dbg_s0_io_out_hasDebugEbreakException |= ~dbg_g_io_out_hasDebugEbreakException;
        checks++;
        if (dbg_g_io_out_breakPoint !== dbg_i_io_out_breakPoint) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_breakPoint g=%h i=%h", cyc, dbg_g_io_out_breakPoint, dbg_i_io_out_breakPoint);
        end
        dbg_s1_io_out_breakPoint |= dbg_g_io_out_breakPoint;
        dbg_s0_io_out_breakPoint |= ~dbg_g_io_out_breakPoint;
        checks++;
        if (dbg_g_io_out_criticalErrorStateEnterDebug !== dbg_i_io_out_criticalErrorStateEnterDebug) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Debug.io_out_criticalErrorStateEnterDebug g=%h i=%h", cyc, dbg_g_io_out_criticalErrorStateEnterDebug, dbg_i_io_out_criticalErrorStateEnterDebug);
        end
        dbg_s1_io_out_criticalErrorStateEnterDebug |= dbg_g_io_out_criticalErrorStateEnterDebug;
        dbg_s0_io_out_criticalErrorStateEnterDebug |= ~dbg_g_io_out_criticalErrorStateEnterDebug;
        if (dbg_g_io_out_hasDebugEbreakException) dbg_cov_ebreak_dbg++;
        if (dbg_g_io_out_triggerEnterDebugMode) dbg_cov_trig_dmode++;
        if (dbg_g_io_out_hasSingleStep) dbg_cov_single_step++;
        if (dbg_g_io_out_hasDebugIntr) dbg_cov_debug_intr++;
        if (dbg_g_io_out_criticalErrorStateEnterDebug) dbg_cov_crit_err++;
        if (dbg_g_io_out_newTriggerChainIsLegal) dbg_cov_chain_legal++;
        if (!dbg_g_io_out_newTriggerChainIsLegal) dbg_cov_chain_illegal++;
        if (dbg_g_io_out_frontendTrigger_tUpdate_valid) dbg_cov_fe_upd_valid++;
        if (dbg_g_io_out_memTrigger_tUpdate_valid) dbg_cov_mem_upd_valid++;
        if (dbg_g_io_out_frontendTrigger_tEnableVec_3) dbg_cov_fe_enable++;
        if (dbg_g_io_out_memTrigger_tEnableVec_0) dbg_cov_mem_enable++;
      end
      if (dbg_armed_at < 0 && (&dbg_armed)) dbg_armed_at = cyc + 1;
      mie_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&mie_armed)) begin
        checks++;
        if (mie_g_rdata !== mie_i_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MieModule.rdata g=%h i=%h", cyc, mie_g_rdata, mie_i_rdata);
        end
        mie_s1_rdata |= mie_g_rdata;
        mie_s0_rdata |= ~mie_g_rdata;
        checks++;
        if (mie_g_regOut_SSIE !== mie_i_regOut_SSIE) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MieModule.regOut_SSIE g=%h i=%h", cyc, mie_g_regOut_SSIE, mie_i_regOut_SSIE);
        end
        mie_s1_regOut_SSIE |= mie_g_regOut_SSIE;
        mie_s0_regOut_SSIE |= ~mie_g_regOut_SSIE;
        checks++;
        if (mie_g_regOut_VSSIE !== mie_i_regOut_VSSIE) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MieModule.regOut_VSSIE g=%h i=%h", cyc, mie_g_regOut_VSSIE, mie_i_regOut_VSSIE);
        end
        mie_s1_regOut_VSSIE |= mie_g_regOut_VSSIE;
        mie_s0_regOut_VSSIE |= ~mie_g_regOut_VSSIE;
        checks++;
        if (mie_g_regOut_MSIE !== mie_i_regOut_MSIE) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MieModule.regOut_MSIE g=%h i=%h", cyc, mie_g_regOut_MSIE, mie_i_regOut_MSIE);
        end
        mie_s1_regOut_MSIE |= mie_g_regOut_MSIE;
        mie_s0_regOut_MSIE |= ~mie_g_regOut_MSIE;
        checks++;
        if (mie_g_regOut_STIE !== mie_i_regOut_STIE) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MieModule.regOut_STIE g=%h i=%h", cyc, mie_g_regOut_STIE, mie_i_regOut_STIE);
        end
        mie_s1_regOut_STIE |= mie_g_regOut_STIE;
        mie_s0_regOut_STIE |= ~mie_g_regOut_STIE;
        checks++;
        if (mie_g_regOut_VSTIE !== mie_i_regOut_VSTIE) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MieModule.regOut_VSTIE g=%h i=%h", cyc, mie_g_regOut_VSTIE, mie_i_regOut_VSTIE);
        end
        mie_s1_regOut_VSTIE |= mie_g_regOut_VSTIE;
        mie_s0_regOut_VSTIE |= ~mie_g_regOut_VSTIE;
        checks++;
        if (mie_g_regOut_MTIE !== mie_i_regOut_MTIE) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MieModule.regOut_MTIE g=%h i=%h", cyc, mie_g_regOut_MTIE, mie_i_regOut_MTIE);
        end
        mie_s1_regOut_MTIE |= mie_g_regOut_MTIE;
        mie_s0_regOut_MTIE |= ~mie_g_regOut_MTIE;
        checks++;
        if (mie_g_regOut_SEIE !== mie_i_regOut_SEIE) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MieModule.regOut_SEIE g=%h i=%h", cyc, mie_g_regOut_SEIE, mie_i_regOut_SEIE);
        end
        mie_s1_regOut_SEIE |= mie_g_regOut_SEIE;
        mie_s0_regOut_SEIE |= ~mie_g_regOut_SEIE;
        checks++;
        if (mie_g_regOut_VSEIE !== mie_i_regOut_VSEIE) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MieModule.regOut_VSEIE g=%h i=%h", cyc, mie_g_regOut_VSEIE, mie_i_regOut_VSEIE);
        end
        mie_s1_regOut_VSEIE |= mie_g_regOut_VSEIE;
        mie_s0_regOut_VSEIE |= ~mie_g_regOut_VSEIE;
        checks++;
        if (mie_g_regOut_MEIE !== mie_i_regOut_MEIE) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MieModule.regOut_MEIE g=%h i=%h", cyc, mie_g_regOut_MEIE, mie_i_regOut_MEIE);
        end
        mie_s1_regOut_MEIE |= mie_g_regOut_MEIE;
        mie_s0_regOut_MEIE |= ~mie_g_regOut_MEIE;
        checks++;
        if (mie_g_regOut_SGEIE !== mie_i_regOut_SGEIE) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MieModule.regOut_SGEIE g=%h i=%h", cyc, mie_g_regOut_SGEIE, mie_i_regOut_SGEIE);
        end
        mie_s1_regOut_SGEIE |= mie_g_regOut_SGEIE;
        mie_s0_regOut_SGEIE |= ~mie_g_regOut_SGEIE;
        checks++;
        if (mie_g_regOut_LCOFIE !== mie_i_regOut_LCOFIE) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MieModule.regOut_LCOFIE g=%h i=%h", cyc, mie_g_regOut_LCOFIE, mie_i_regOut_LCOFIE);
        end
        mie_s1_regOut_LCOFIE |= mie_g_regOut_LCOFIE;
        mie_s0_regOut_LCOFIE |= ~mie_g_regOut_LCOFIE;
        if (mie_w_wen && !mie_fromSie_SSIE_valid) mie_cov_csr_wr_only++;
        if (mie_fromSie_SSIE_valid) mie_cov_sie_wr++;
        if (mie_fromHie_VSSIE_valid && mie_fromVSie_VSSIE_valid) mie_cov_hie_vsie_both++;
        if (mie_fromVSie_LCOFIE_valid && !mie_fromSie_LCOFIE_valid) mie_cov_vsie_lcofi++;
        if (mie_g_regOut_MEIE) mie_cov_m_bit_set++;
      end
      if (mie_armed_at < 0 && (&mie_armed)) mie_armed_at = cyc + 1;
      if (cyc >= RESET_CYC + 0 && (&tm_armed)) begin
        checks++;
        if (tm_g_rdata !== tm_i_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d timeModule.rdata g=%h i=%h", cyc, tm_g_rdata, tm_i_rdata);
        end
        tm_s1_rdata |= tm_g_rdata;
        tm_s0_rdata |= ~tm_g_rdata;
        checks++;
        if (tm_g_updated !== tm_i_updated) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d timeModule.updated g=%h i=%h", cyc, tm_g_updated, tm_i_updated);
        end
        tm_s1_updated |= tm_g_updated;
        tm_s0_updated |= ~tm_g_updated;
        checks++;
        if (tm_g_stime !== tm_i_stime) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d timeModule.stime g=%h i=%h", cyc, tm_g_stime, tm_i_stime);
        end
        tm_s1_stime |= tm_g_stime;
        tm_s0_stime |= ~tm_g_stime;
        checks++;
        if (tm_g_vstime !== tm_i_vstime) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d timeModule.vstime g=%h i=%h", cyc, tm_g_vstime, tm_i_vstime);
        end
        tm_s1_vstime |= tm_g_vstime;
        tm_s0_vstime |= ~tm_g_vstime;
        if (tm_mHPM_time_valid && !tm_debugModeStopTime) tm_cov_tick++;
        if (tm_mHPM_time_valid && tm_debugModeStopTime) tm_cov_stopped_tick++;
        if (tm_nextV != tm_v) tm_cov_v_change++;
        if (tm_v) tm_cov_guest_view++;
      end
      if (tm_mHPM_time_valid && !tm_debugModeStopTime) tm_armed[0] = 1'b1;
      if (tm_armed_at < 0 && (&tm_armed)) tm_armed_at = cyc + 1;
      xr_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&xr_armed)) begin
        checks++;
        if (xr_g_io_out_Xret_EX_II !== xr_i_io_out_Xret_EX_II) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d XRetPermitModule.io_out_Xret_EX_II g=%h i=%h", cyc, xr_g_io_out_Xret_EX_II, xr_i_io_out_Xret_EX_II);
        end
        xr_s1_io_out_Xret_EX_II |= xr_g_io_out_Xret_EX_II;
        xr_s0_io_out_Xret_EX_II |= ~xr_g_io_out_Xret_EX_II;
        checks++;
        if (xr_g_io_out_Xret_EX_VI !== xr_i_io_out_Xret_EX_VI) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d XRetPermitModule.io_out_Xret_EX_VI g=%h i=%h", cyc, xr_g_io_out_Xret_EX_VI, xr_i_io_out_Xret_EX_VI);
        end
        xr_s1_io_out_Xret_EX_VI |= xr_g_io_out_Xret_EX_VI;
        xr_s0_io_out_Xret_EX_VI |= ~xr_g_io_out_Xret_EX_VI;
        checks++;
        if (xr_g_io_out_hasLegalMNret !== xr_i_io_out_hasLegalMNret) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d XRetPermitModule.io_out_hasLegalMNret g=%h i=%h", cyc, xr_g_io_out_hasLegalMNret, xr_i_io_out_hasLegalMNret);
        end
        xr_s1_io_out_hasLegalMNret |= xr_g_io_out_hasLegalMNret;
        xr_s0_io_out_hasLegalMNret |= ~xr_g_io_out_hasLegalMNret;
        checks++;
        if (xr_g_io_out_hasLegalMret !== xr_i_io_out_hasLegalMret) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d XRetPermitModule.io_out_hasLegalMret g=%h i=%h", cyc, xr_g_io_out_hasLegalMret, xr_i_io_out_hasLegalMret);
        end
        xr_s1_io_out_hasLegalMret |= xr_g_io_out_hasLegalMret;
        xr_s0_io_out_hasLegalMret |= ~xr_g_io_out_hasLegalMret;
        checks++;
        if (xr_g_io_out_hasLegalSret !== xr_i_io_out_hasLegalSret) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d XRetPermitModule.io_out_hasLegalSret g=%h i=%h", cyc, xr_g_io_out_hasLegalSret, xr_i_io_out_hasLegalSret);
        end
        xr_s1_io_out_hasLegalSret |= xr_g_io_out_hasLegalSret;
        xr_s0_io_out_hasLegalSret |= ~xr_g_io_out_hasLegalSret;
        checks++;
        if (xr_g_io_out_hasLegalDret !== xr_i_io_out_hasLegalDret) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d XRetPermitModule.io_out_hasLegalDret g=%h i=%h", cyc, xr_g_io_out_hasLegalDret, xr_i_io_out_hasLegalDret);
        end
        xr_s1_io_out_hasLegalDret |= xr_g_io_out_hasLegalDret;
        xr_s0_io_out_hasLegalDret |= ~xr_g_io_out_hasLegalDret;
        if (xr_g_io_out_Xret_EX_II) xr_cov_ex_ii++;
        if (xr_g_io_out_Xret_EX_VI) xr_cov_ex_vi++;
        if (xr_g_io_out_hasLegalSret) xr_cov_legal_sret++;
        if (xr_g_io_out_hasLegalMNret) xr_cov_legal_mnret++;
      end
      if (xr_armed_at < 0 && (&xr_armed)) xr_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(dbg_s0_io_out_triggerFrontendChange && dbg_s1_io_out_triggerFrontendChange)) begin cov_fail++; $display("[COV] Debug.io_out_triggerFrontendChange 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_newTriggerChainIsLegal && dbg_s1_io_out_newTriggerChainIsLegal)) begin cov_fail++; $display("[COV] Debug.io_out_newTriggerChainIsLegal 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_valid && dbg_s1_io_out_memTrigger_tUpdate_valid)) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_valid 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_addr[0] && dbg_s1_io_out_memTrigger_tUpdate_bits_addr[0])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_addr[0] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_addr[1] && dbg_s1_io_out_memTrigger_tUpdate_bits_addr[1])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_addr[1] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_matchType[0] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_matchType[0])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_matchType[0] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_matchType[1] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_matchType[1])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_matchType[1] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_select && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_select)) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_select 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_action[0] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_action[0])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_action[0] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_action[1] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_action[1])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_action[1] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_action[2] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_action[2])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_action[2] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_action[3] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_action[3])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_action[3] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_chain && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_chain)) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_chain 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_store && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_store)) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_store 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_load && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_load)) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_load 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[0] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[0])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[0] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[1] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[1])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[1] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[2] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[2])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[2] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[3] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[3])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[3] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[4] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[4])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[4] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[5] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[5])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[5] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[6] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[6])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[6] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[7] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[7])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[7] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[8] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[8])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[8] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[9] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[9])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[9] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[10] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[10])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[10] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[11] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[11])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[11] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[12] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[12])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[12] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[13] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[13])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[13] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[14] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[14])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[14] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[15] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[15])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[15] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[16] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[16])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[16] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[17] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[17])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[17] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[18] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[18])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[18] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[19] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[19])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[19] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[20] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[20])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[20] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[21] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[21])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[21] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[22] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[22])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[22] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[23] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[23])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[23] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[24] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[24])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[24] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[25] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[25])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[25] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[26] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[26])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[26] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[27] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[27])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[27] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[28] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[28])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[28] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[29] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[29])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[29] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[30] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[30])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[30] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[31] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[31])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[31] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[32] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[32])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[32] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[33] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[33])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[33] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[34] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[34])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[34] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[35] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[35])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[35] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[36] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[36])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[36] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[37] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[37])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[37] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[38] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[38])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[38] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[39] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[39])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[39] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[40] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[40])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[40] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[41] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[41])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[41] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[42] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[42])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[42] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[43] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[43])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[43] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[44] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[44])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[44] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[45] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[45])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[45] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[46] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[46])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[46] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[47] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[47])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[47] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[48] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[48])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[48] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[49] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[49])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[49] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[50] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[50])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[50] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[51] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[51])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[51] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[52] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[52])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[52] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[53] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[53])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[53] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[54] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[54])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[54] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[55] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[55])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[55] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[56] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[56])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[56] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[57] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[57])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[57] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[58] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[58])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[58] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[59] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[59])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[59] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[60] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[60])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[60] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[61] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[61])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[61] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[62] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[62])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[62] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tUpdate_bits_tdata_tdata2[63] && dbg_s1_io_out_memTrigger_tUpdate_bits_tdata_tdata2[63])) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tUpdate_bits_tdata_tdata2[63] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tEnableVec_0 && dbg_s1_io_out_memTrigger_tEnableVec_0)) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tEnableVec_0 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tEnableVec_1 && dbg_s1_io_out_memTrigger_tEnableVec_1)) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tEnableVec_1 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tEnableVec_2 && dbg_s1_io_out_memTrigger_tEnableVec_2)) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tEnableVec_2 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_tEnableVec_3 && dbg_s1_io_out_memTrigger_tEnableVec_3)) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_tEnableVec_3 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_debugMode && dbg_s1_io_out_memTrigger_debugMode)) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_debugMode 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_memTrigger_triggerCanRaiseBpExp && dbg_s1_io_out_memTrigger_triggerCanRaiseBpExp)) begin cov_fail++; $display("[COV] Debug.io_out_memTrigger_triggerCanRaiseBpExp 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_valid && dbg_s1_io_out_frontendTrigger_tUpdate_valid)) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_valid 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_addr[0] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_addr[0])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_addr[0] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_addr[1] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_addr[1])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_addr[1] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_matchType[0] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_matchType[0])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_matchType[0] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_matchType[1] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_matchType[1])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_matchType[1] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_select && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_select)) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_select 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_action[0] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_action[0])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_action[0] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_action[1] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_action[1])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_action[1] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_action[2] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_action[2])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_action[2] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_action[3] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_action[3])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_action[3] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_chain && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_chain)) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_chain 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[0] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[0])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[0] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[1] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[1])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[1] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[2] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[2])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[2] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[3] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[3])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[3] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[4] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[4])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[4] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[5] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[5])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[5] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[6] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[6])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[6] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[7] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[7])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[7] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[8] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[8])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[8] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[9] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[9])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[9] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[10] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[10])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[10] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[11] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[11])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[11] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[12] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[12])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[12] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[13] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[13])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[13] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[14] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[14])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[14] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[15] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[15])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[15] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[16] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[16])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[16] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[17] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[17])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[17] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[18] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[18])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[18] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[19] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[19])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[19] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[20] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[20])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[20] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[21] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[21])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[21] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[22] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[22])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[22] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[23] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[23])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[23] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[24] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[24])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[24] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[25] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[25])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[25] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[26] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[26])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[26] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[27] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[27])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[27] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[28] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[28])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[28] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[29] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[29])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[29] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[30] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[30])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[30] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[31] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[31])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[31] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[32] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[32])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[32] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[33] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[33])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[33] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[34] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[34])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[34] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[35] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[35])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[35] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[36] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[36])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[36] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[37] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[37])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[37] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[38] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[38])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[38] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[39] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[39])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[39] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[40] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[40])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[40] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[41] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[41])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[41] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[42] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[42])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[42] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[43] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[43])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[43] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[44] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[44])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[44] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[45] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[45])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[45] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[46] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[46])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[46] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[47] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[47])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[47] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[48] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[48])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[48] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[49] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[49])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[49] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[50] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[50])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[50] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[51] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[51])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[51] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[52] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[52])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[52] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[53] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[53])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[53] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[54] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[54])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[54] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[55] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[55])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[55] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[56] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[56])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[56] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[57] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[57])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[57] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[58] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[58])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[58] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[59] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[59])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[59] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[60] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[60])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[60] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[61] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[61])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[61] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[62] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[62])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[62] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[63] && dbg_s1_io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[63])) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tUpdate_bits_tdata_tdata2[63] 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tEnableVec_0 && dbg_s1_io_out_frontendTrigger_tEnableVec_0)) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tEnableVec_0 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tEnableVec_1 && dbg_s1_io_out_frontendTrigger_tEnableVec_1)) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tEnableVec_1 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tEnableVec_2 && dbg_s1_io_out_frontendTrigger_tEnableVec_2)) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tEnableVec_2 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_tEnableVec_3 && dbg_s1_io_out_frontendTrigger_tEnableVec_3)) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_tEnableVec_3 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_debugMode && dbg_s1_io_out_frontendTrigger_debugMode)) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_debugMode 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_frontendTrigger_triggerCanRaiseBpExp && dbg_s1_io_out_frontendTrigger_triggerCanRaiseBpExp)) begin cov_fail++; $display("[COV] Debug.io_out_frontendTrigger_triggerCanRaiseBpExp 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_hasDebugTrap && dbg_s1_io_out_hasDebugTrap)) begin cov_fail++; $display("[COV] Debug.io_out_hasDebugTrap 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_hasDebugIntr && dbg_s1_io_out_hasDebugIntr)) begin cov_fail++; $display("[COV] Debug.io_out_hasDebugIntr 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_hasSingleStep && dbg_s1_io_out_hasSingleStep)) begin cov_fail++; $display("[COV] Debug.io_out_hasSingleStep 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_triggerEnterDebugMode && dbg_s1_io_out_triggerEnterDebugMode)) begin cov_fail++; $display("[COV] Debug.io_out_triggerEnterDebugMode 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_hasDebugEbreakException && dbg_s1_io_out_hasDebugEbreakException)) begin cov_fail++; $display("[COV] Debug.io_out_hasDebugEbreakException 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_breakPoint && dbg_s1_io_out_breakPoint)) begin cov_fail++; $display("[COV] Debug.io_out_breakPoint 未见过 0 和 1"); end
    if (!(dbg_s0_io_out_criticalErrorStateEnterDebug && dbg_s1_io_out_criticalErrorStateEnterDebug)) begin cov_fail++; $display("[COV] Debug.io_out_criticalErrorStateEnterDebug 未见过 0 和 1"); end
    $display("[ARM] Debug armed_at=%0d", dbg_armed_at);
    if (dbg_armed_at < 0) begin cov_fail++; $display("[ARM] Debug 从未 arm"); end
    $display("[COV] Debug.ebreak_dbg = %0d", dbg_cov_ebreak_dbg);
    if (dbg_cov_ebreak_dbg < 100) begin cov_fail++; $display("[COV] Debug.ebreak_dbg < 100"); end
    $display("[COV] Debug.trig_dmode = %0d", dbg_cov_trig_dmode);
    if (dbg_cov_trig_dmode < 100) begin cov_fail++; $display("[COV] Debug.trig_dmode < 100"); end
    $display("[COV] Debug.single_step = %0d", dbg_cov_single_step);
    if (dbg_cov_single_step < 100) begin cov_fail++; $display("[COV] Debug.single_step < 100"); end
    $display("[COV] Debug.debug_intr = %0d", dbg_cov_debug_intr);
    if (dbg_cov_debug_intr < 100) begin cov_fail++; $display("[COV] Debug.debug_intr < 100"); end
    $display("[COV] Debug.crit_err = %0d", dbg_cov_crit_err);
    if (dbg_cov_crit_err < 100) begin cov_fail++; $display("[COV] Debug.crit_err < 100"); end
    $display("[COV] Debug.chain_legal = %0d", dbg_cov_chain_legal);
    if (dbg_cov_chain_legal < 100) begin cov_fail++; $display("[COV] Debug.chain_legal < 100"); end
    $display("[COV] Debug.chain_illegal = %0d", dbg_cov_chain_illegal);
    if (dbg_cov_chain_illegal < 100) begin cov_fail++; $display("[COV] Debug.chain_illegal < 100"); end
    $display("[COV] Debug.fe_upd_valid = %0d", dbg_cov_fe_upd_valid);
    if (dbg_cov_fe_upd_valid < 100) begin cov_fail++; $display("[COV] Debug.fe_upd_valid < 100"); end
    $display("[COV] Debug.mem_upd_valid = %0d", dbg_cov_mem_upd_valid);
    if (dbg_cov_mem_upd_valid < 100) begin cov_fail++; $display("[COV] Debug.mem_upd_valid < 100"); end
    $display("[COV] Debug.fe_enable = %0d", dbg_cov_fe_enable);
    if (dbg_cov_fe_enable < 100) begin cov_fail++; $display("[COV] Debug.fe_enable < 100"); end
    $display("[COV] Debug.mem_enable = %0d", dbg_cov_mem_enable);
    if (dbg_cov_mem_enable < 100) begin cov_fail++; $display("[COV] Debug.mem_enable < 100"); end
    if (!(mie_s0_rdata[1] && mie_s1_rdata[1])) begin cov_fail++; $display("[COV] MieModule.rdata[1] 未见过 0 和 1"); end
    if (!(mie_s0_rdata[2] && mie_s1_rdata[2])) begin cov_fail++; $display("[COV] MieModule.rdata[2] 未见过 0 和 1"); end
    if (!(mie_s0_rdata[3] && mie_s1_rdata[3])) begin cov_fail++; $display("[COV] MieModule.rdata[3] 未见过 0 和 1"); end
    if (!(mie_s0_rdata[5] && mie_s1_rdata[5])) begin cov_fail++; $display("[COV] MieModule.rdata[5] 未见过 0 和 1"); end
    if (!(mie_s0_rdata[6] && mie_s1_rdata[6])) begin cov_fail++; $display("[COV] MieModule.rdata[6] 未见过 0 和 1"); end
    if (!(mie_s0_rdata[7] && mie_s1_rdata[7])) begin cov_fail++; $display("[COV] MieModule.rdata[7] 未见过 0 和 1"); end
    if (!(mie_s0_rdata[9] && mie_s1_rdata[9])) begin cov_fail++; $display("[COV] MieModule.rdata[9] 未见过 0 和 1"); end
    if (!(mie_s0_rdata[10] && mie_s1_rdata[10])) begin cov_fail++; $display("[COV] MieModule.rdata[10] 未见过 0 和 1"); end
    if (!(mie_s0_rdata[11] && mie_s1_rdata[11])) begin cov_fail++; $display("[COV] MieModule.rdata[11] 未见过 0 和 1"); end
    if (!(mie_s0_rdata[12] && mie_s1_rdata[12])) begin cov_fail++; $display("[COV] MieModule.rdata[12] 未见过 0 和 1"); end
    if (!(mie_s0_rdata[13] && mie_s1_rdata[13])) begin cov_fail++; $display("[COV] MieModule.rdata[13] 未见过 0 和 1"); end
    if (!(mie_s0_regOut_SSIE && mie_s1_regOut_SSIE)) begin cov_fail++; $display("[COV] MieModule.regOut_SSIE 未见过 0 和 1"); end
    if (!(mie_s0_regOut_VSSIE && mie_s1_regOut_VSSIE)) begin cov_fail++; $display("[COV] MieModule.regOut_VSSIE 未见过 0 和 1"); end
    if (!(mie_s0_regOut_MSIE && mie_s1_regOut_MSIE)) begin cov_fail++; $display("[COV] MieModule.regOut_MSIE 未见过 0 和 1"); end
    if (!(mie_s0_regOut_STIE && mie_s1_regOut_STIE)) begin cov_fail++; $display("[COV] MieModule.regOut_STIE 未见过 0 和 1"); end
    if (!(mie_s0_regOut_VSTIE && mie_s1_regOut_VSTIE)) begin cov_fail++; $display("[COV] MieModule.regOut_VSTIE 未见过 0 和 1"); end
    if (!(mie_s0_regOut_MTIE && mie_s1_regOut_MTIE)) begin cov_fail++; $display("[COV] MieModule.regOut_MTIE 未见过 0 和 1"); end
    if (!(mie_s0_regOut_SEIE && mie_s1_regOut_SEIE)) begin cov_fail++; $display("[COV] MieModule.regOut_SEIE 未见过 0 和 1"); end
    if (!(mie_s0_regOut_VSEIE && mie_s1_regOut_VSEIE)) begin cov_fail++; $display("[COV] MieModule.regOut_VSEIE 未见过 0 和 1"); end
    if (!(mie_s0_regOut_MEIE && mie_s1_regOut_MEIE)) begin cov_fail++; $display("[COV] MieModule.regOut_MEIE 未见过 0 和 1"); end
    if (!(mie_s0_regOut_SGEIE && mie_s1_regOut_SGEIE)) begin cov_fail++; $display("[COV] MieModule.regOut_SGEIE 未见过 0 和 1"); end
    if (!(mie_s0_regOut_LCOFIE && mie_s1_regOut_LCOFIE)) begin cov_fail++; $display("[COV] MieModule.regOut_LCOFIE 未见过 0 和 1"); end
    $display("[ARM] MieModule armed_at=%0d", mie_armed_at);
    if (mie_armed_at < 0) begin cov_fail++; $display("[ARM] MieModule 从未 arm"); end
    $display("[COV] MieModule.csr_wr_only = %0d", mie_cov_csr_wr_only);
    if (mie_cov_csr_wr_only < 100) begin cov_fail++; $display("[COV] MieModule.csr_wr_only < 100"); end
    $display("[COV] MieModule.sie_wr = %0d", mie_cov_sie_wr);
    if (mie_cov_sie_wr < 100) begin cov_fail++; $display("[COV] MieModule.sie_wr < 100"); end
    $display("[COV] MieModule.hie_vsie_both = %0d", mie_cov_hie_vsie_both);
    if (mie_cov_hie_vsie_both < 100) begin cov_fail++; $display("[COV] MieModule.hie_vsie_both < 100"); end
    $display("[COV] MieModule.vsie_lcofi = %0d", mie_cov_vsie_lcofi);
    if (mie_cov_vsie_lcofi < 100) begin cov_fail++; $display("[COV] MieModule.vsie_lcofi < 100"); end
    $display("[COV] MieModule.m_bit_set = %0d", mie_cov_m_bit_set);
    if (mie_cov_m_bit_set < 100) begin cov_fail++; $display("[COV] MieModule.m_bit_set < 100"); end
    if (!(tm_s0_rdata[0] && tm_s1_rdata[0])) begin cov_fail++; $display("[COV] timeModule.rdata[0] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[1] && tm_s1_rdata[1])) begin cov_fail++; $display("[COV] timeModule.rdata[1] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[2] && tm_s1_rdata[2])) begin cov_fail++; $display("[COV] timeModule.rdata[2] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[3] && tm_s1_rdata[3])) begin cov_fail++; $display("[COV] timeModule.rdata[3] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[4] && tm_s1_rdata[4])) begin cov_fail++; $display("[COV] timeModule.rdata[4] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[5] && tm_s1_rdata[5])) begin cov_fail++; $display("[COV] timeModule.rdata[5] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[6] && tm_s1_rdata[6])) begin cov_fail++; $display("[COV] timeModule.rdata[6] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[7] && tm_s1_rdata[7])) begin cov_fail++; $display("[COV] timeModule.rdata[7] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[8] && tm_s1_rdata[8])) begin cov_fail++; $display("[COV] timeModule.rdata[8] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[9] && tm_s1_rdata[9])) begin cov_fail++; $display("[COV] timeModule.rdata[9] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[10] && tm_s1_rdata[10])) begin cov_fail++; $display("[COV] timeModule.rdata[10] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[11] && tm_s1_rdata[11])) begin cov_fail++; $display("[COV] timeModule.rdata[11] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[12] && tm_s1_rdata[12])) begin cov_fail++; $display("[COV] timeModule.rdata[12] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[13] && tm_s1_rdata[13])) begin cov_fail++; $display("[COV] timeModule.rdata[13] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[14] && tm_s1_rdata[14])) begin cov_fail++; $display("[COV] timeModule.rdata[14] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[15] && tm_s1_rdata[15])) begin cov_fail++; $display("[COV] timeModule.rdata[15] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[16] && tm_s1_rdata[16])) begin cov_fail++; $display("[COV] timeModule.rdata[16] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[17] && tm_s1_rdata[17])) begin cov_fail++; $display("[COV] timeModule.rdata[17] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[18] && tm_s1_rdata[18])) begin cov_fail++; $display("[COV] timeModule.rdata[18] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[19] && tm_s1_rdata[19])) begin cov_fail++; $display("[COV] timeModule.rdata[19] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[20] && tm_s1_rdata[20])) begin cov_fail++; $display("[COV] timeModule.rdata[20] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[21] && tm_s1_rdata[21])) begin cov_fail++; $display("[COV] timeModule.rdata[21] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[22] && tm_s1_rdata[22])) begin cov_fail++; $display("[COV] timeModule.rdata[22] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[23] && tm_s1_rdata[23])) begin cov_fail++; $display("[COV] timeModule.rdata[23] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[24] && tm_s1_rdata[24])) begin cov_fail++; $display("[COV] timeModule.rdata[24] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[25] && tm_s1_rdata[25])) begin cov_fail++; $display("[COV] timeModule.rdata[25] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[26] && tm_s1_rdata[26])) begin cov_fail++; $display("[COV] timeModule.rdata[26] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[27] && tm_s1_rdata[27])) begin cov_fail++; $display("[COV] timeModule.rdata[27] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[28] && tm_s1_rdata[28])) begin cov_fail++; $display("[COV] timeModule.rdata[28] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[29] && tm_s1_rdata[29])) begin cov_fail++; $display("[COV] timeModule.rdata[29] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[30] && tm_s1_rdata[30])) begin cov_fail++; $display("[COV] timeModule.rdata[30] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[31] && tm_s1_rdata[31])) begin cov_fail++; $display("[COV] timeModule.rdata[31] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[32] && tm_s1_rdata[32])) begin cov_fail++; $display("[COV] timeModule.rdata[32] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[33] && tm_s1_rdata[33])) begin cov_fail++; $display("[COV] timeModule.rdata[33] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[34] && tm_s1_rdata[34])) begin cov_fail++; $display("[COV] timeModule.rdata[34] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[35] && tm_s1_rdata[35])) begin cov_fail++; $display("[COV] timeModule.rdata[35] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[36] && tm_s1_rdata[36])) begin cov_fail++; $display("[COV] timeModule.rdata[36] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[37] && tm_s1_rdata[37])) begin cov_fail++; $display("[COV] timeModule.rdata[37] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[38] && tm_s1_rdata[38])) begin cov_fail++; $display("[COV] timeModule.rdata[38] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[39] && tm_s1_rdata[39])) begin cov_fail++; $display("[COV] timeModule.rdata[39] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[40] && tm_s1_rdata[40])) begin cov_fail++; $display("[COV] timeModule.rdata[40] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[41] && tm_s1_rdata[41])) begin cov_fail++; $display("[COV] timeModule.rdata[41] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[42] && tm_s1_rdata[42])) begin cov_fail++; $display("[COV] timeModule.rdata[42] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[43] && tm_s1_rdata[43])) begin cov_fail++; $display("[COV] timeModule.rdata[43] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[44] && tm_s1_rdata[44])) begin cov_fail++; $display("[COV] timeModule.rdata[44] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[45] && tm_s1_rdata[45])) begin cov_fail++; $display("[COV] timeModule.rdata[45] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[46] && tm_s1_rdata[46])) begin cov_fail++; $display("[COV] timeModule.rdata[46] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[47] && tm_s1_rdata[47])) begin cov_fail++; $display("[COV] timeModule.rdata[47] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[48] && tm_s1_rdata[48])) begin cov_fail++; $display("[COV] timeModule.rdata[48] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[49] && tm_s1_rdata[49])) begin cov_fail++; $display("[COV] timeModule.rdata[49] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[50] && tm_s1_rdata[50])) begin cov_fail++; $display("[COV] timeModule.rdata[50] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[51] && tm_s1_rdata[51])) begin cov_fail++; $display("[COV] timeModule.rdata[51] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[52] && tm_s1_rdata[52])) begin cov_fail++; $display("[COV] timeModule.rdata[52] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[53] && tm_s1_rdata[53])) begin cov_fail++; $display("[COV] timeModule.rdata[53] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[54] && tm_s1_rdata[54])) begin cov_fail++; $display("[COV] timeModule.rdata[54] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[55] && tm_s1_rdata[55])) begin cov_fail++; $display("[COV] timeModule.rdata[55] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[56] && tm_s1_rdata[56])) begin cov_fail++; $display("[COV] timeModule.rdata[56] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[57] && tm_s1_rdata[57])) begin cov_fail++; $display("[COV] timeModule.rdata[57] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[58] && tm_s1_rdata[58])) begin cov_fail++; $display("[COV] timeModule.rdata[58] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[59] && tm_s1_rdata[59])) begin cov_fail++; $display("[COV] timeModule.rdata[59] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[60] && tm_s1_rdata[60])) begin cov_fail++; $display("[COV] timeModule.rdata[60] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[61] && tm_s1_rdata[61])) begin cov_fail++; $display("[COV] timeModule.rdata[61] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[62] && tm_s1_rdata[62])) begin cov_fail++; $display("[COV] timeModule.rdata[62] 未见过 0 和 1"); end
    if (!(tm_s0_rdata[63] && tm_s1_rdata[63])) begin cov_fail++; $display("[COV] timeModule.rdata[63] 未见过 0 和 1"); end
    if (!(tm_s0_updated && tm_s1_updated)) begin cov_fail++; $display("[COV] timeModule.updated 未见过 0 和 1"); end
    if (!(tm_s0_stime[0] && tm_s1_stime[0])) begin cov_fail++; $display("[COV] timeModule.stime[0] 未见过 0 和 1"); end
    if (!(tm_s0_stime[1] && tm_s1_stime[1])) begin cov_fail++; $display("[COV] timeModule.stime[1] 未见过 0 和 1"); end
    if (!(tm_s0_stime[2] && tm_s1_stime[2])) begin cov_fail++; $display("[COV] timeModule.stime[2] 未见过 0 和 1"); end
    if (!(tm_s0_stime[3] && tm_s1_stime[3])) begin cov_fail++; $display("[COV] timeModule.stime[3] 未见过 0 和 1"); end
    if (!(tm_s0_stime[4] && tm_s1_stime[4])) begin cov_fail++; $display("[COV] timeModule.stime[4] 未见过 0 和 1"); end
    if (!(tm_s0_stime[5] && tm_s1_stime[5])) begin cov_fail++; $display("[COV] timeModule.stime[5] 未见过 0 和 1"); end
    if (!(tm_s0_stime[6] && tm_s1_stime[6])) begin cov_fail++; $display("[COV] timeModule.stime[6] 未见过 0 和 1"); end
    if (!(tm_s0_stime[7] && tm_s1_stime[7])) begin cov_fail++; $display("[COV] timeModule.stime[7] 未见过 0 和 1"); end
    if (!(tm_s0_stime[8] && tm_s1_stime[8])) begin cov_fail++; $display("[COV] timeModule.stime[8] 未见过 0 和 1"); end
    if (!(tm_s0_stime[9] && tm_s1_stime[9])) begin cov_fail++; $display("[COV] timeModule.stime[9] 未见过 0 和 1"); end
    if (!(tm_s0_stime[10] && tm_s1_stime[10])) begin cov_fail++; $display("[COV] timeModule.stime[10] 未见过 0 和 1"); end
    if (!(tm_s0_stime[11] && tm_s1_stime[11])) begin cov_fail++; $display("[COV] timeModule.stime[11] 未见过 0 和 1"); end
    if (!(tm_s0_stime[12] && tm_s1_stime[12])) begin cov_fail++; $display("[COV] timeModule.stime[12] 未见过 0 和 1"); end
    if (!(tm_s0_stime[13] && tm_s1_stime[13])) begin cov_fail++; $display("[COV] timeModule.stime[13] 未见过 0 和 1"); end
    if (!(tm_s0_stime[14] && tm_s1_stime[14])) begin cov_fail++; $display("[COV] timeModule.stime[14] 未见过 0 和 1"); end
    if (!(tm_s0_stime[15] && tm_s1_stime[15])) begin cov_fail++; $display("[COV] timeModule.stime[15] 未见过 0 和 1"); end
    if (!(tm_s0_stime[16] && tm_s1_stime[16])) begin cov_fail++; $display("[COV] timeModule.stime[16] 未见过 0 和 1"); end
    if (!(tm_s0_stime[17] && tm_s1_stime[17])) begin cov_fail++; $display("[COV] timeModule.stime[17] 未见过 0 和 1"); end
    if (!(tm_s0_stime[18] && tm_s1_stime[18])) begin cov_fail++; $display("[COV] timeModule.stime[18] 未见过 0 和 1"); end
    if (!(tm_s0_stime[19] && tm_s1_stime[19])) begin cov_fail++; $display("[COV] timeModule.stime[19] 未见过 0 和 1"); end
    if (!(tm_s0_stime[20] && tm_s1_stime[20])) begin cov_fail++; $display("[COV] timeModule.stime[20] 未见过 0 和 1"); end
    if (!(tm_s0_stime[21] && tm_s1_stime[21])) begin cov_fail++; $display("[COV] timeModule.stime[21] 未见过 0 和 1"); end
    if (!(tm_s0_stime[22] && tm_s1_stime[22])) begin cov_fail++; $display("[COV] timeModule.stime[22] 未见过 0 和 1"); end
    if (!(tm_s0_stime[23] && tm_s1_stime[23])) begin cov_fail++; $display("[COV] timeModule.stime[23] 未见过 0 和 1"); end
    if (!(tm_s0_stime[24] && tm_s1_stime[24])) begin cov_fail++; $display("[COV] timeModule.stime[24] 未见过 0 和 1"); end
    if (!(tm_s0_stime[25] && tm_s1_stime[25])) begin cov_fail++; $display("[COV] timeModule.stime[25] 未见过 0 和 1"); end
    if (!(tm_s0_stime[26] && tm_s1_stime[26])) begin cov_fail++; $display("[COV] timeModule.stime[26] 未见过 0 和 1"); end
    if (!(tm_s0_stime[27] && tm_s1_stime[27])) begin cov_fail++; $display("[COV] timeModule.stime[27] 未见过 0 和 1"); end
    if (!(tm_s0_stime[28] && tm_s1_stime[28])) begin cov_fail++; $display("[COV] timeModule.stime[28] 未见过 0 和 1"); end
    if (!(tm_s0_stime[29] && tm_s1_stime[29])) begin cov_fail++; $display("[COV] timeModule.stime[29] 未见过 0 和 1"); end
    if (!(tm_s0_stime[30] && tm_s1_stime[30])) begin cov_fail++; $display("[COV] timeModule.stime[30] 未见过 0 和 1"); end
    if (!(tm_s0_stime[31] && tm_s1_stime[31])) begin cov_fail++; $display("[COV] timeModule.stime[31] 未见过 0 和 1"); end
    if (!(tm_s0_stime[32] && tm_s1_stime[32])) begin cov_fail++; $display("[COV] timeModule.stime[32] 未见过 0 和 1"); end
    if (!(tm_s0_stime[33] && tm_s1_stime[33])) begin cov_fail++; $display("[COV] timeModule.stime[33] 未见过 0 和 1"); end
    if (!(tm_s0_stime[34] && tm_s1_stime[34])) begin cov_fail++; $display("[COV] timeModule.stime[34] 未见过 0 和 1"); end
    if (!(tm_s0_stime[35] && tm_s1_stime[35])) begin cov_fail++; $display("[COV] timeModule.stime[35] 未见过 0 和 1"); end
    if (!(tm_s0_stime[36] && tm_s1_stime[36])) begin cov_fail++; $display("[COV] timeModule.stime[36] 未见过 0 和 1"); end
    if (!(tm_s0_stime[37] && tm_s1_stime[37])) begin cov_fail++; $display("[COV] timeModule.stime[37] 未见过 0 和 1"); end
    if (!(tm_s0_stime[38] && tm_s1_stime[38])) begin cov_fail++; $display("[COV] timeModule.stime[38] 未见过 0 和 1"); end
    if (!(tm_s0_stime[39] && tm_s1_stime[39])) begin cov_fail++; $display("[COV] timeModule.stime[39] 未见过 0 和 1"); end
    if (!(tm_s0_stime[40] && tm_s1_stime[40])) begin cov_fail++; $display("[COV] timeModule.stime[40] 未见过 0 和 1"); end
    if (!(tm_s0_stime[41] && tm_s1_stime[41])) begin cov_fail++; $display("[COV] timeModule.stime[41] 未见过 0 和 1"); end
    if (!(tm_s0_stime[42] && tm_s1_stime[42])) begin cov_fail++; $display("[COV] timeModule.stime[42] 未见过 0 和 1"); end
    if (!(tm_s0_stime[43] && tm_s1_stime[43])) begin cov_fail++; $display("[COV] timeModule.stime[43] 未见过 0 和 1"); end
    if (!(tm_s0_stime[44] && tm_s1_stime[44])) begin cov_fail++; $display("[COV] timeModule.stime[44] 未见过 0 和 1"); end
    if (!(tm_s0_stime[45] && tm_s1_stime[45])) begin cov_fail++; $display("[COV] timeModule.stime[45] 未见过 0 和 1"); end
    if (!(tm_s0_stime[46] && tm_s1_stime[46])) begin cov_fail++; $display("[COV] timeModule.stime[46] 未见过 0 和 1"); end
    if (!(tm_s0_stime[47] && tm_s1_stime[47])) begin cov_fail++; $display("[COV] timeModule.stime[47] 未见过 0 和 1"); end
    if (!(tm_s0_stime[48] && tm_s1_stime[48])) begin cov_fail++; $display("[COV] timeModule.stime[48] 未见过 0 和 1"); end
    if (!(tm_s0_stime[49] && tm_s1_stime[49])) begin cov_fail++; $display("[COV] timeModule.stime[49] 未见过 0 和 1"); end
    if (!(tm_s0_stime[50] && tm_s1_stime[50])) begin cov_fail++; $display("[COV] timeModule.stime[50] 未见过 0 和 1"); end
    if (!(tm_s0_stime[51] && tm_s1_stime[51])) begin cov_fail++; $display("[COV] timeModule.stime[51] 未见过 0 和 1"); end
    if (!(tm_s0_stime[52] && tm_s1_stime[52])) begin cov_fail++; $display("[COV] timeModule.stime[52] 未见过 0 和 1"); end
    if (!(tm_s0_stime[53] && tm_s1_stime[53])) begin cov_fail++; $display("[COV] timeModule.stime[53] 未见过 0 和 1"); end
    if (!(tm_s0_stime[54] && tm_s1_stime[54])) begin cov_fail++; $display("[COV] timeModule.stime[54] 未见过 0 和 1"); end
    if (!(tm_s0_stime[55] && tm_s1_stime[55])) begin cov_fail++; $display("[COV] timeModule.stime[55] 未见过 0 和 1"); end
    if (!(tm_s0_stime[56] && tm_s1_stime[56])) begin cov_fail++; $display("[COV] timeModule.stime[56] 未见过 0 和 1"); end
    if (!(tm_s0_stime[57] && tm_s1_stime[57])) begin cov_fail++; $display("[COV] timeModule.stime[57] 未见过 0 和 1"); end
    if (!(tm_s0_stime[58] && tm_s1_stime[58])) begin cov_fail++; $display("[COV] timeModule.stime[58] 未见过 0 和 1"); end
    if (!(tm_s0_stime[59] && tm_s1_stime[59])) begin cov_fail++; $display("[COV] timeModule.stime[59] 未见过 0 和 1"); end
    if (!(tm_s0_stime[60] && tm_s1_stime[60])) begin cov_fail++; $display("[COV] timeModule.stime[60] 未见过 0 和 1"); end
    if (!(tm_s0_stime[61] && tm_s1_stime[61])) begin cov_fail++; $display("[COV] timeModule.stime[61] 未见过 0 和 1"); end
    if (!(tm_s0_stime[62] && tm_s1_stime[62])) begin cov_fail++; $display("[COV] timeModule.stime[62] 未见过 0 和 1"); end
    if (!(tm_s0_stime[63] && tm_s1_stime[63])) begin cov_fail++; $display("[COV] timeModule.stime[63] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[0] && tm_s1_vstime[0])) begin cov_fail++; $display("[COV] timeModule.vstime[0] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[1] && tm_s1_vstime[1])) begin cov_fail++; $display("[COV] timeModule.vstime[1] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[2] && tm_s1_vstime[2])) begin cov_fail++; $display("[COV] timeModule.vstime[2] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[3] && tm_s1_vstime[3])) begin cov_fail++; $display("[COV] timeModule.vstime[3] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[4] && tm_s1_vstime[4])) begin cov_fail++; $display("[COV] timeModule.vstime[4] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[5] && tm_s1_vstime[5])) begin cov_fail++; $display("[COV] timeModule.vstime[5] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[6] && tm_s1_vstime[6])) begin cov_fail++; $display("[COV] timeModule.vstime[6] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[7] && tm_s1_vstime[7])) begin cov_fail++; $display("[COV] timeModule.vstime[7] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[8] && tm_s1_vstime[8])) begin cov_fail++; $display("[COV] timeModule.vstime[8] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[9] && tm_s1_vstime[9])) begin cov_fail++; $display("[COV] timeModule.vstime[9] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[10] && tm_s1_vstime[10])) begin cov_fail++; $display("[COV] timeModule.vstime[10] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[11] && tm_s1_vstime[11])) begin cov_fail++; $display("[COV] timeModule.vstime[11] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[12] && tm_s1_vstime[12])) begin cov_fail++; $display("[COV] timeModule.vstime[12] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[13] && tm_s1_vstime[13])) begin cov_fail++; $display("[COV] timeModule.vstime[13] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[14] && tm_s1_vstime[14])) begin cov_fail++; $display("[COV] timeModule.vstime[14] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[15] && tm_s1_vstime[15])) begin cov_fail++; $display("[COV] timeModule.vstime[15] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[16] && tm_s1_vstime[16])) begin cov_fail++; $display("[COV] timeModule.vstime[16] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[17] && tm_s1_vstime[17])) begin cov_fail++; $display("[COV] timeModule.vstime[17] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[18] && tm_s1_vstime[18])) begin cov_fail++; $display("[COV] timeModule.vstime[18] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[19] && tm_s1_vstime[19])) begin cov_fail++; $display("[COV] timeModule.vstime[19] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[20] && tm_s1_vstime[20])) begin cov_fail++; $display("[COV] timeModule.vstime[20] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[21] && tm_s1_vstime[21])) begin cov_fail++; $display("[COV] timeModule.vstime[21] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[22] && tm_s1_vstime[22])) begin cov_fail++; $display("[COV] timeModule.vstime[22] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[23] && tm_s1_vstime[23])) begin cov_fail++; $display("[COV] timeModule.vstime[23] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[24] && tm_s1_vstime[24])) begin cov_fail++; $display("[COV] timeModule.vstime[24] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[25] && tm_s1_vstime[25])) begin cov_fail++; $display("[COV] timeModule.vstime[25] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[26] && tm_s1_vstime[26])) begin cov_fail++; $display("[COV] timeModule.vstime[26] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[27] && tm_s1_vstime[27])) begin cov_fail++; $display("[COV] timeModule.vstime[27] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[28] && tm_s1_vstime[28])) begin cov_fail++; $display("[COV] timeModule.vstime[28] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[29] && tm_s1_vstime[29])) begin cov_fail++; $display("[COV] timeModule.vstime[29] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[30] && tm_s1_vstime[30])) begin cov_fail++; $display("[COV] timeModule.vstime[30] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[31] && tm_s1_vstime[31])) begin cov_fail++; $display("[COV] timeModule.vstime[31] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[32] && tm_s1_vstime[32])) begin cov_fail++; $display("[COV] timeModule.vstime[32] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[33] && tm_s1_vstime[33])) begin cov_fail++; $display("[COV] timeModule.vstime[33] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[34] && tm_s1_vstime[34])) begin cov_fail++; $display("[COV] timeModule.vstime[34] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[35] && tm_s1_vstime[35])) begin cov_fail++; $display("[COV] timeModule.vstime[35] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[36] && tm_s1_vstime[36])) begin cov_fail++; $display("[COV] timeModule.vstime[36] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[37] && tm_s1_vstime[37])) begin cov_fail++; $display("[COV] timeModule.vstime[37] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[38] && tm_s1_vstime[38])) begin cov_fail++; $display("[COV] timeModule.vstime[38] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[39] && tm_s1_vstime[39])) begin cov_fail++; $display("[COV] timeModule.vstime[39] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[40] && tm_s1_vstime[40])) begin cov_fail++; $display("[COV] timeModule.vstime[40] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[41] && tm_s1_vstime[41])) begin cov_fail++; $display("[COV] timeModule.vstime[41] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[42] && tm_s1_vstime[42])) begin cov_fail++; $display("[COV] timeModule.vstime[42] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[43] && tm_s1_vstime[43])) begin cov_fail++; $display("[COV] timeModule.vstime[43] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[44] && tm_s1_vstime[44])) begin cov_fail++; $display("[COV] timeModule.vstime[44] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[45] && tm_s1_vstime[45])) begin cov_fail++; $display("[COV] timeModule.vstime[45] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[46] && tm_s1_vstime[46])) begin cov_fail++; $display("[COV] timeModule.vstime[46] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[47] && tm_s1_vstime[47])) begin cov_fail++; $display("[COV] timeModule.vstime[47] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[48] && tm_s1_vstime[48])) begin cov_fail++; $display("[COV] timeModule.vstime[48] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[49] && tm_s1_vstime[49])) begin cov_fail++; $display("[COV] timeModule.vstime[49] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[50] && tm_s1_vstime[50])) begin cov_fail++; $display("[COV] timeModule.vstime[50] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[51] && tm_s1_vstime[51])) begin cov_fail++; $display("[COV] timeModule.vstime[51] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[52] && tm_s1_vstime[52])) begin cov_fail++; $display("[COV] timeModule.vstime[52] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[53] && tm_s1_vstime[53])) begin cov_fail++; $display("[COV] timeModule.vstime[53] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[54] && tm_s1_vstime[54])) begin cov_fail++; $display("[COV] timeModule.vstime[54] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[55] && tm_s1_vstime[55])) begin cov_fail++; $display("[COV] timeModule.vstime[55] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[56] && tm_s1_vstime[56])) begin cov_fail++; $display("[COV] timeModule.vstime[56] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[57] && tm_s1_vstime[57])) begin cov_fail++; $display("[COV] timeModule.vstime[57] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[58] && tm_s1_vstime[58])) begin cov_fail++; $display("[COV] timeModule.vstime[58] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[59] && tm_s1_vstime[59])) begin cov_fail++; $display("[COV] timeModule.vstime[59] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[60] && tm_s1_vstime[60])) begin cov_fail++; $display("[COV] timeModule.vstime[60] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[61] && tm_s1_vstime[61])) begin cov_fail++; $display("[COV] timeModule.vstime[61] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[62] && tm_s1_vstime[62])) begin cov_fail++; $display("[COV] timeModule.vstime[62] 未见过 0 和 1"); end
    if (!(tm_s0_vstime[63] && tm_s1_vstime[63])) begin cov_fail++; $display("[COV] timeModule.vstime[63] 未见过 0 和 1"); end
    $display("[ARM] timeModule armed_at=%0d", tm_armed_at);
    if (tm_armed_at < 0) begin cov_fail++; $display("[ARM] timeModule 从未 arm"); end
    $display("[COV] timeModule.tick = %0d", tm_cov_tick);
    if (tm_cov_tick < 100) begin cov_fail++; $display("[COV] timeModule.tick < 100"); end
    $display("[COV] timeModule.stopped_tick = %0d", tm_cov_stopped_tick);
    if (tm_cov_stopped_tick < 100) begin cov_fail++; $display("[COV] timeModule.stopped_tick < 100"); end
    $display("[COV] timeModule.v_change = %0d", tm_cov_v_change);
    if (tm_cov_v_change < 100) begin cov_fail++; $display("[COV] timeModule.v_change < 100"); end
    $display("[COV] timeModule.guest_view = %0d", tm_cov_guest_view);
    if (tm_cov_guest_view < 100) begin cov_fail++; $display("[COV] timeModule.guest_view < 100"); end
    if (!(xr_s0_io_out_Xret_EX_II && xr_s1_io_out_Xret_EX_II)) begin cov_fail++; $display("[COV] XRetPermitModule.io_out_Xret_EX_II 未见过 0 和 1"); end
    if (!(xr_s0_io_out_Xret_EX_VI && xr_s1_io_out_Xret_EX_VI)) begin cov_fail++; $display("[COV] XRetPermitModule.io_out_Xret_EX_VI 未见过 0 和 1"); end
    if (!(xr_s0_io_out_hasLegalMNret && xr_s1_io_out_hasLegalMNret)) begin cov_fail++; $display("[COV] XRetPermitModule.io_out_hasLegalMNret 未见过 0 和 1"); end
    if (!(xr_s0_io_out_hasLegalMret && xr_s1_io_out_hasLegalMret)) begin cov_fail++; $display("[COV] XRetPermitModule.io_out_hasLegalMret 未见过 0 和 1"); end
    if (!(xr_s0_io_out_hasLegalSret && xr_s1_io_out_hasLegalSret)) begin cov_fail++; $display("[COV] XRetPermitModule.io_out_hasLegalSret 未见过 0 和 1"); end
    if (!(xr_s0_io_out_hasLegalDret && xr_s1_io_out_hasLegalDret)) begin cov_fail++; $display("[COV] XRetPermitModule.io_out_hasLegalDret 未见过 0 和 1"); end
    $display("[ARM] XRetPermitModule armed_at=%0d", xr_armed_at);
    if (xr_armed_at < 0) begin cov_fail++; $display("[ARM] XRetPermitModule 从未 arm"); end
    $display("[COV] XRetPermitModule.ex_ii = %0d", xr_cov_ex_ii);
    if (xr_cov_ex_ii < 100) begin cov_fail++; $display("[COV] XRetPermitModule.ex_ii < 100"); end
    $display("[COV] XRetPermitModule.ex_vi = %0d", xr_cov_ex_vi);
    if (xr_cov_ex_vi < 100) begin cov_fail++; $display("[COV] XRetPermitModule.ex_vi < 100"); end
    $display("[COV] XRetPermitModule.legal_sret = %0d", xr_cov_legal_sret);
    if (xr_cov_legal_sret < 100) begin cov_fail++; $display("[COV] XRetPermitModule.legal_sret < 100"); end
    $display("[COV] XRetPermitModule.legal_mnret = %0d", xr_cov_legal_mnret);
    if (xr_cov_legal_mnret < 100) begin cov_fail++; $display("[COV] XRetPermitModule.legal_mnret < 100"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
