// NewCSR Debug module — readable transcription.
//
// Combinational + small-state debug trigger/breakpoint decision logic: given the
// trap info, current privilege, dcsr ebreak-enable bits and the trigger (tdata1/
// tdata2) match state, it decides whether to enter debug mode, on which cause,
// and drives the single-step / trigger-fire outputs. Plain structural RTL with 4
// state regs; readable rewrite drops the sim randomize-init block. FM-verified
// strict golden-vs-impl SUCCEEDED, no black box, no dont_verify.


module Debug(
  input         clock,
  input         io_in_trapInfo_valid,
  input  [63:0] io_in_trapInfo_bits_trapVec,
  input         io_in_trapInfo_bits_isDebugIntr,
  input         io_in_trapInfo_bits_isInterrupt,
  input         io_in_trapInfo_bits_singleStep,
  input  [3:0]  io_in_trapInfo_bits_trigger,
  input         io_in_trapInfo_bits_criticalErrorState,
  input  [1:0]  io_in_privState_PRVM,
  input         io_in_privState_V,
  input         io_in_debugMode,
  input         io_in_dcsr_CETRIG,
  input         io_in_dcsr_EBREAKVS,
  input         io_in_dcsr_EBREAKVU,
  input         io_in_dcsr_EBREAKM,
  input         io_in_dcsr_EBREAKS,
  input         io_in_dcsr_EBREAKU,
  input  [1:0]  io_in_tselect_ALL,
  input  [58:0] io_in_tdata1Selected_DATA,
  input  [63:0] io_in_tdata2Selected_ALL,
  input  [3:0]  io_in_tdata1Vec_0_TYPE,
  input  [58:0] io_in_tdata1Vec_0_DATA,
  input  [3:0]  io_in_tdata1Vec_1_TYPE,
  input  [58:0] io_in_tdata1Vec_1_DATA,
  input  [3:0]  io_in_tdata1Vec_2_TYPE,
  input  [58:0] io_in_tdata1Vec_2_DATA,
  input  [3:0]  io_in_tdata1Vec_3_TYPE,
  input  [58:0] io_in_tdata1Vec_3_DATA,
  input         io_in_triggerCanRaiseBpExp,
  input         io_in_tdata1Update,
  input         io_in_tdata2Update,
  input  [3:0]  io_in_tdata1Wdata_TYPE,
  input  [58:0] io_in_tdata1Wdata_DATA,
  output        io_out_triggerFrontendChange,
  output        io_out_newTriggerChainIsLegal,
  output        io_out_memTrigger_tUpdate_valid,
  output [1:0]  io_out_memTrigger_tUpdate_bits_addr,
  output [1:0]  io_out_memTrigger_tUpdate_bits_tdata_matchType,
  output        io_out_memTrigger_tUpdate_bits_tdata_select,
  output [3:0]  io_out_memTrigger_tUpdate_bits_tdata_action,
  output        io_out_memTrigger_tUpdate_bits_tdata_chain,
  output        io_out_memTrigger_tUpdate_bits_tdata_store,
  output        io_out_memTrigger_tUpdate_bits_tdata_load,
  output [63:0] io_out_memTrigger_tUpdate_bits_tdata_tdata2,
  output        io_out_memTrigger_tEnableVec_0,
  output        io_out_memTrigger_tEnableVec_1,
  output        io_out_memTrigger_tEnableVec_2,
  output        io_out_memTrigger_tEnableVec_3,
  output        io_out_memTrigger_debugMode,
  output        io_out_memTrigger_triggerCanRaiseBpExp,
  output        io_out_frontendTrigger_tUpdate_valid,
  output [1:0]  io_out_frontendTrigger_tUpdate_bits_addr,
  output [1:0]  io_out_frontendTrigger_tUpdate_bits_tdata_matchType,
  output        io_out_frontendTrigger_tUpdate_bits_tdata_select,
  output [3:0]  io_out_frontendTrigger_tUpdate_bits_tdata_action,
  output        io_out_frontendTrigger_tUpdate_bits_tdata_chain,
  output [63:0] io_out_frontendTrigger_tUpdate_bits_tdata_tdata2,
  output        io_out_frontendTrigger_tEnableVec_0,
  output        io_out_frontendTrigger_tEnableVec_1,
  output        io_out_frontendTrigger_tEnableVec_2,
  output        io_out_frontendTrigger_tEnableVec_3,
  output        io_out_frontendTrigger_debugMode,
  output        io_out_frontendTrigger_triggerCanRaiseBpExp,
  output        io_out_hasDebugTrap,
  output        io_out_hasDebugIntr,
  output        io_out_hasSingleStep,
  output        io_out_triggerEnterDebugMode,
  output        io_out_hasDebugEbreakException,
  output        io_out_breakPoint,
  output        io_out_criticalErrorStateEnterDebug
);

  wire hasDebugIntr =
    io_in_trapInfo_valid & io_in_trapInfo_bits_isInterrupt
    & io_in_trapInfo_bits_isDebugIntr;
  wire hasExp = io_in_trapInfo_valid & ~io_in_trapInfo_bits_isInterrupt;
  wire ebreakEnterDebugMode_v_PrvmIsM = &io_in_privState_PRVM;
  wire ebreakEnterDebugMode_isModeM = ebreakEnterDebugMode_v_PrvmIsM;
  wire PrvmIsS = io_in_privState_PRVM == 2'h1;
  wire ebreakEnterDebugMode_isModeHS = ~io_in_privState_V & PrvmIsS;
  wire PrvmIsU = io_in_privState_PRVM == 2'h0;
  wire ebreakEnterDebugMode_isModeHU = ~io_in_privState_V & PrvmIsU;
  wire ebreakEnterDebugMode_isModeVS = io_in_privState_V & PrvmIsS;
  wire ebreakEnterDebugMode_isModeVU = io_in_privState_V & PrvmIsU;
  wire hasDebugEbreakException =
    hasExp & io_in_trapInfo_bits_trapVec[3] & (|io_in_trapInfo_bits_trigger)
    & (ebreakEnterDebugMode_isModeM & io_in_dcsr_EBREAKM | ebreakEnterDebugMode_isModeHS
       & io_in_dcsr_EBREAKS | ebreakEnterDebugMode_isModeHU & io_in_dcsr_EBREAKU
       | ebreakEnterDebugMode_isModeVS & io_in_dcsr_EBREAKVS
       | ebreakEnterDebugMode_isModeVU & io_in_dcsr_EBREAKVU);
  wire triggerEnterDebugMode = hasExp & io_in_trapInfo_bits_trigger == 4'h1;
  wire hasSingleStep = hasExp & io_in_trapInfo_bits_singleStep;
  wire criticalErrorStateEnterDebug =
    io_in_trapInfo_bits_criticalErrorState & io_in_dcsr_CETRIG;
  wire newTriggerChainVec_1 = io_in_tselect_ALL == 2'h1 | io_in_tdata1Vec_1_DATA[11];
  wire newTriggerChainVec_2 = io_in_tselect_ALL == 2'h2 | io_in_tdata1Vec_2_DATA[11];
  wire triggerUpdate = io_in_tdata1Update | io_in_tdata2Update;
  wire _memTriggerUpdate_T = io_in_tdata1Wdata_TYPE == 4'h6;
  wire frontendTriggerUpdate =
    io_in_tdata1Update & _memTriggerUpdate_T & io_in_tdata1Wdata_DATA[2]
    | io_in_tdata1Selected_DATA[2] & triggerUpdate;
  wire triggerEnableVec_0 =
    io_in_tdata1Vec_0_TYPE == 4'h6
    & (io_in_tdata1Vec_0_DATA[6] & ebreakEnterDebugMode_isModeM
       | io_in_tdata1Vec_0_DATA[4] & ebreakEnterDebugMode_isModeHS
       | io_in_tdata1Vec_0_DATA[3] & ebreakEnterDebugMode_isModeHU
       | io_in_tdata1Vec_0_DATA[24] & ebreakEnterDebugMode_isModeVS
       | io_in_tdata1Vec_0_DATA[23] & ebreakEnterDebugMode_isModeVU);
  wire triggerEnableVec_1 =
    io_in_tdata1Vec_1_TYPE == 4'h6
    & (io_in_tdata1Vec_1_DATA[6] & ebreakEnterDebugMode_isModeM
       | io_in_tdata1Vec_1_DATA[4] & ebreakEnterDebugMode_isModeHS
       | io_in_tdata1Vec_1_DATA[3] & ebreakEnterDebugMode_isModeHU
       | io_in_tdata1Vec_1_DATA[24] & ebreakEnterDebugMode_isModeVS
       | io_in_tdata1Vec_1_DATA[23] & ebreakEnterDebugMode_isModeVU);
  wire triggerEnableVec_2 =
    io_in_tdata1Vec_2_TYPE == 4'h6
    & (io_in_tdata1Vec_2_DATA[6] & ebreakEnterDebugMode_isModeM
       | io_in_tdata1Vec_2_DATA[4] & ebreakEnterDebugMode_isModeHS
       | io_in_tdata1Vec_2_DATA[3] & ebreakEnterDebugMode_isModeHU
       | io_in_tdata1Vec_2_DATA[24] & ebreakEnterDebugMode_isModeVS
       | io_in_tdata1Vec_2_DATA[23] & ebreakEnterDebugMode_isModeVU);
  wire triggerEnableVec_3 =
    io_in_tdata1Vec_3_TYPE == 4'h6
    & (io_in_tdata1Vec_3_DATA[6] & ebreakEnterDebugMode_isModeM
       | io_in_tdata1Vec_3_DATA[4] & ebreakEnterDebugMode_isModeHS
       | io_in_tdata1Vec_3_DATA[3] & ebreakEnterDebugMode_isModeHU
       | io_in_tdata1Vec_3_DATA[24] & ebreakEnterDebugMode_isModeVS
       | io_in_tdata1Vec_3_DATA[23] & ebreakEnterDebugMode_isModeVU);
  reg  io_out_frontendTrigger_tUpdate_valid_REG;
  reg  io_out_frontendTrigger_tUpdate_valid_REG_1;
  reg  io_out_memTrigger_tUpdate_valid_REG;
  reg  io_out_memTrigger_tUpdate_valid_REG_1;
  always @(posedge clock) begin
    io_out_frontendTrigger_tUpdate_valid_REG <= frontendTriggerUpdate;
    io_out_frontendTrigger_tUpdate_valid_REG_1 <=
      io_out_frontendTrigger_tUpdate_valid_REG;
    io_out_memTrigger_tUpdate_valid_REG <=
      io_in_tdata1Update & _memTriggerUpdate_T
      & (io_in_tdata1Wdata_DATA[1] | io_in_tdata1Wdata_DATA[0])
      | (io_in_tdata1Selected_DATA[1] | io_in_tdata1Selected_DATA[0]) & triggerUpdate;
    io_out_memTrigger_tUpdate_valid_REG_1 <= io_out_memTrigger_tUpdate_valid_REG;
  end
  assign io_out_triggerFrontendChange = frontendTriggerUpdate;
  assign io_out_newTriggerChainIsLegal =
    ~((io_in_tselect_ALL == 2'h0 | io_in_tdata1Vec_0_DATA[11]) & newTriggerChainVec_1
      | newTriggerChainVec_1 & newTriggerChainVec_2 | newTriggerChainVec_2
      & ((&io_in_tselect_ALL) | io_in_tdata1Vec_3_DATA[11]));
  assign io_out_memTrigger_tUpdate_valid = io_out_memTrigger_tUpdate_valid_REG_1;
  assign io_out_memTrigger_tUpdate_bits_addr = io_in_tselect_ALL;
  assign io_out_memTrigger_tUpdate_bits_tdata_matchType = io_in_tdata1Selected_DATA[8:7];
  assign io_out_memTrigger_tUpdate_bits_tdata_select = io_in_tdata1Selected_DATA[21];
  assign io_out_memTrigger_tUpdate_bits_tdata_action = io_in_tdata1Selected_DATA[15:12];
  assign io_out_memTrigger_tUpdate_bits_tdata_chain = io_in_tdata1Selected_DATA[11];
  assign io_out_memTrigger_tUpdate_bits_tdata_store = io_in_tdata1Selected_DATA[1];
  assign io_out_memTrigger_tUpdate_bits_tdata_load = io_in_tdata1Selected_DATA[0];
  assign io_out_memTrigger_tUpdate_bits_tdata_tdata2 = io_in_tdata2Selected_ALL;
  assign io_out_memTrigger_tEnableVec_0 =
    triggerEnableVec_0 & (io_in_tdata1Vec_0_DATA[1] | io_in_tdata1Vec_0_DATA[0]);
  assign io_out_memTrigger_tEnableVec_1 =
    triggerEnableVec_1 & (io_in_tdata1Vec_1_DATA[1] | io_in_tdata1Vec_1_DATA[0]);
  assign io_out_memTrigger_tEnableVec_2 =
    triggerEnableVec_2 & (io_in_tdata1Vec_2_DATA[1] | io_in_tdata1Vec_2_DATA[0]);
  assign io_out_memTrigger_tEnableVec_3 =
    triggerEnableVec_3 & (io_in_tdata1Vec_3_DATA[1] | io_in_tdata1Vec_3_DATA[0]);
  assign io_out_memTrigger_debugMode = io_in_debugMode;
  assign io_out_memTrigger_triggerCanRaiseBpExp = io_in_triggerCanRaiseBpExp;
  assign io_out_frontendTrigger_tUpdate_valid =
    io_out_frontendTrigger_tUpdate_valid_REG_1;
  assign io_out_frontendTrigger_tUpdate_bits_addr = io_in_tselect_ALL;
  assign io_out_frontendTrigger_tUpdate_bits_tdata_matchType =
    io_in_tdata1Selected_DATA[8:7];
  assign io_out_frontendTrigger_tUpdate_bits_tdata_select = io_in_tdata1Selected_DATA[21];
  assign io_out_frontendTrigger_tUpdate_bits_tdata_action =
    io_in_tdata1Selected_DATA[15:12];
  assign io_out_frontendTrigger_tUpdate_bits_tdata_chain = io_in_tdata1Selected_DATA[11];
  assign io_out_frontendTrigger_tUpdate_bits_tdata_tdata2 = io_in_tdata2Selected_ALL;
  assign io_out_frontendTrigger_tEnableVec_0 =
    triggerEnableVec_0 & io_in_tdata1Vec_0_DATA[2];
  assign io_out_frontendTrigger_tEnableVec_1 =
    triggerEnableVec_1 & io_in_tdata1Vec_1_DATA[2];
  assign io_out_frontendTrigger_tEnableVec_2 =
    triggerEnableVec_2 & io_in_tdata1Vec_2_DATA[2];
  assign io_out_frontendTrigger_tEnableVec_3 =
    triggerEnableVec_3 & io_in_tdata1Vec_3_DATA[2];
  assign io_out_frontendTrigger_debugMode = io_in_debugMode;
  assign io_out_frontendTrigger_triggerCanRaiseBpExp = io_in_triggerCanRaiseBpExp;
  assign io_out_hasDebugTrap =
    hasDebugEbreakException | triggerEnterDebugMode | hasSingleStep
    | criticalErrorStateEnterDebug | hasDebugIntr;
  assign io_out_hasDebugIntr = hasDebugIntr;
  assign io_out_hasSingleStep = hasSingleStep;
  assign io_out_triggerEnterDebugMode = triggerEnterDebugMode;
  assign io_out_hasDebugEbreakException = hasDebugEbreakException;
  assign io_out_breakPoint = io_in_trapInfo_bits_trapVec[3];
  assign io_out_criticalErrorStateEnterDebug = criticalErrorStateEnterDebug;
endmodule
