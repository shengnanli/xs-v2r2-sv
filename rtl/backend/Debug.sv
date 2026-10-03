// Debug.sv — debug-mode entry decision and trigger (Sdtrig) distribution of NewCSR.
// Scala: xiangshan/backend/fu/NewCSR/Debug.scala (class Debug).
// Two independent jobs, both almost purely combinational:
//   1. Debug-mode entry.  The trap that the ROB reports this cycle enters
//      debug mode for one of five reasons: a debug interrupt from the debug
//      module, an ebreak when dcsr.ebreak<mode> is set, a trigger whose action
//      is "enter debug mode", a single step, or a critical-error state while
//      dcsr.cetrig is set.  hasDebugTrap is the OR of all five.
//   2. Trigger distribution.  The four mcontrol6 triggers (tdata1Vec) are
//      turned into per-trigger enables for the frontend (execute triggers) and
//      for the load/store units (load/store triggers); the currently selected
//      trigger (tselect, tdata1Selected/tdata2Selected) is broadcast as an
//      update, whose valid is delayed two cycles (RegNext(RegNext(...))).
//      newTriggerChainIsLegal rejects a chain longer than TriggerChainMaxLength=2,
//      i.e. two adjacent "chained" slots (tselect counts as chained here).
// Bug-for-bug notes:
//   * "isModeM" is PRVM==3 only (V is not consulted), as everywhere in NewCSR.
//   * an ebreak counts only when the trigger action is not "breakpoint
//     exception" (action != 0), i.e. trigger==0 means a trigger already
//     claimed the breakpoint.
//   * the update valid uses the *written* tdata1 (when its TYPE is legal) OR
//     the *currently selected* tdata1 — both terms, exactly as Scala.
//   * the two delay flops have no reset (golden `always @(posedge clock)`).
module xs_Debug_core #(
  parameter int TRIGGER_NUM = 4
) (
  input  logic        clock,
  // ---- trap reported this cycle ----
  input  logic        trap_valid,
  input  logic        trap_breakpoint,       // trapVec[3] (ExceptionNO.breakPoint)
  input  logic        trap_is_debug_intr,
  input  logic        trap_is_interrupt,
  input  logic        trap_single_step,
  input  logic [3:0]  trap_trigger_action,   // TriggerAction of the firing trigger
  input  logic        trap_critical_error,
  // ---- privilege state ----
  input  logic [1:0]  prvm,
  input  logic        virt,
  // ---- dcsr ----
  input  logic        dcsr_cetrig,
  input  logic        dcsr_ebreakvs,
  input  logic        dcsr_ebreakvu,
  input  logic        dcsr_ebreakm,
  input  logic        dcsr_ebreaks,
  input  logic        dcsr_ebreaku,
  // ---- trigger CSRs ----
  input  logic [1:0]  tselect,
  input  logic [58:0] tdata1_sel,                           // tdata1Selected.DATA (mcontrol6)
  input  logic [3:0]  tdata1_type [TRIGGER_NUM],            // tdata1Vec(i).TYPE
  input  logic [58:0] tdata1_data [TRIGGER_NUM],            // tdata1Vec(i).DATA (mcontrol6)
  input  logic        tdata1_update,
  input  logic        tdata2_update,
  input  logic [3:0]  tdata1_wtype,                         // tdata1Wdata.TYPE
  input  logic [58:0] tdata1_wdata,                         // tdata1Wdata.DATA
  // ---- outputs ----
  output logic                   trigger_frontend_change,   // frontend update (undelayed)
  output logic                   new_trigger_chain_legal,
  output logic                   frontend_update_valid,     // delayed two cycles
  output logic                   mem_update_valid,          // delayed two cycles
  output logic [TRIGGER_NUM-1:0] frontend_enable,
  output logic [TRIGGER_NUM-1:0] mem_enable,
  output logic                   has_debug_trap,
  output logic                   has_debug_intr,
  output logic                   has_single_step,
  output logic                   trigger_enter_debug_mode,
  output logic                   has_debug_ebreak_exception,
  output logic                   critical_error_enter_debug
);
  // mcontrol6 field positions inside tdata1.DATA (Mcontrol6, DebugLevel.scala)
  localparam int MC6_LOAD    = 0;
  localparam int MC6_STORE   = 1;
  localparam int MC6_EXECUTE = 2;
  localparam int MC6_U       = 3;
  localparam int MC6_S       = 4;
  localparam int MC6_M       = 6;
  localparam int MC6_CHAIN   = 11;
  localparam int MC6_VU      = 23;
  localparam int MC6_VS      = 24;
  localparam logic [3:0] TDATA1_TYPE_MCONTROL6 = 4'd6;   // the only legal TYPE
  localparam logic [3:0] ACTION_BP_EXCEPTION   = 4'd0;   // TriggerAction.BreakpointExp
  localparam logic [3:0] ACTION_DEBUG_MODE     = 4'd1;   // TriggerAction.DebugMode

  // ---------------------------------------------------------------------------
  // Privilege mode decode (PrivState.isMode*)
  // ---------------------------------------------------------------------------
  logic mode_m, mode_hs, mode_hu, mode_vs, mode_vu;
  assign mode_m  = (prvm == 2'b11);
  assign mode_hs = ~virt & (prvm == 2'b01);
  assign mode_hu = ~virt & (prvm == 2'b00);
  assign mode_vs =  virt & (prvm == 2'b01);
  assign mode_vu =  virt & (prvm == 2'b00);

  // ---------------------------------------------------------------------------
  // 1. Debug-mode entry: the five reasons
  // ---------------------------------------------------------------------------
  logic has_exception;      // a trap that is not an interrupt
  logic is_ebreak;          // breakpoint exception not claimed by a trigger
  logic ebreak_enters_debug;

  assign has_exception = trap_valid & ~trap_is_interrupt;
  assign has_debug_intr = trap_valid & trap_is_interrupt & trap_is_debug_intr;

  assign is_ebreak = has_exception & trap_breakpoint & (trap_trigger_action != ACTION_BP_EXCEPTION);
  assign ebreak_enters_debug = (mode_m  & dcsr_ebreakm)
                             | (mode_hs & dcsr_ebreaks)
                             | (mode_hu & dcsr_ebreaku)
                             | (mode_vs & dcsr_ebreakvs)
                             | (mode_vu & dcsr_ebreakvu);
  assign has_debug_ebreak_exception = is_ebreak & ebreak_enters_debug;

  assign trigger_enter_debug_mode   = has_exception & (trap_trigger_action == ACTION_DEBUG_MODE);
  assign has_single_step            = has_exception & trap_single_step;
  assign critical_error_enter_debug = trap_critical_error & dcsr_cetrig;

  assign has_debug_trap = has_debug_ebreak_exception | trigger_enter_debug_mode | has_single_step
                        | critical_error_enter_debug | has_debug_intr;

  // ---------------------------------------------------------------------------
  // 2a. Chain legality: slot i counts as chained if it is the one being
  //     written (tselect) or its CHAIN bit is set; two adjacent chained slots
  //     would form a chain of length 3 > TriggerChainMaxLength.
  // ---------------------------------------------------------------------------
  logic [TRIGGER_NUM-1:0] chained;
  logic                   two_adjacent;
  always_comb begin
    for (int i = 0; i < TRIGGER_NUM; i++)
      chained[i] = (tselect == 2'(i)) | tdata1_data[i][MC6_CHAIN];
    two_adjacent = 1'b0;
    for (int i = 0; i < TRIGGER_NUM - 1; i++)
      two_adjacent = two_adjacent | (chained[i] & chained[i+1]);
  end
  assign new_trigger_chain_legal = ~two_adjacent;

  // ---------------------------------------------------------------------------
  // 2b. Per-trigger enable: legal TYPE and enabled for the current mode;
  //     then split by kind (execute -> frontend, load/store -> memory).
  // ---------------------------------------------------------------------------
  for (genvar i = 0; i < TRIGGER_NUM; i++) begin : g_trigger
    logic enabled_here;
    assign enabled_here = (tdata1_type[i] == TDATA1_TYPE_MCONTROL6)
                        & ((tdata1_data[i][MC6_M]  & mode_m)
                         | (tdata1_data[i][MC6_S]  & mode_hs)
                         | (tdata1_data[i][MC6_U]  & mode_hu)
                         | (tdata1_data[i][MC6_VS] & mode_vs)
                         | (tdata1_data[i][MC6_VU] & mode_vu));
    assign frontend_enable[i] = enabled_here & tdata1_data[i][MC6_EXECUTE];
    assign mem_enable[i]      = enabled_here & (tdata1_data[i][MC6_STORE] | tdata1_data[i][MC6_LOAD]);
  end

  // ---------------------------------------------------------------------------
  // 2c. Update broadcast for the selected trigger, valid delayed two cycles
  // ---------------------------------------------------------------------------
  logic any_tdata_update;
  logic wtype_legal;
  logic frontend_update;
  logic mem_update;
  assign any_tdata_update = tdata1_update | tdata2_update;
  assign wtype_legal      = (tdata1_wtype == TDATA1_TYPE_MCONTROL6);
  assign frontend_update  = (tdata1_update & wtype_legal & tdata1_wdata[MC6_EXECUTE])
                          | (tdata1_sel[MC6_EXECUTE] & any_tdata_update);
  assign mem_update       = (tdata1_update & wtype_legal
                             & (tdata1_wdata[MC6_STORE] | tdata1_wdata[MC6_LOAD]))
                          | ((tdata1_sel[MC6_STORE] | tdata1_sel[MC6_LOAD]) & any_tdata_update);
  assign trigger_frontend_change = frontend_update;

  logic [1:0] frontend_update_q;   // [0] = one cycle old, [1] = two cycles old
  logic [1:0] mem_update_q;
  always_ff @(posedge clock) begin
    frontend_update_q <= {frontend_update_q[0], frontend_update};
    mem_update_q      <= {mem_update_q[0], mem_update};
  end
  assign frontend_update_valid = frontend_update_q[1];
  assign mem_update_valid      = mem_update_q[1];
endmodule

// golden-named wrapper: flattens tdata1Vec and fans the selected trigger's
// fields out to the two identical update bundles.
module Debug (
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
  logic [3:0]  tdata1_type [4];
  logic [58:0] tdata1_data [4];
  logic [3:0]  frontend_enable;
  logic [3:0]  mem_enable;

  assign tdata1_type[0] = io_in_tdata1Vec_0_TYPE;
  assign tdata1_type[1] = io_in_tdata1Vec_1_TYPE;
  assign tdata1_type[2] = io_in_tdata1Vec_2_TYPE;
  assign tdata1_type[3] = io_in_tdata1Vec_3_TYPE;
  assign tdata1_data[0] = io_in_tdata1Vec_0_DATA;
  assign tdata1_data[1] = io_in_tdata1Vec_1_DATA;
  assign tdata1_data[2] = io_in_tdata1Vec_2_DATA;
  assign tdata1_data[3] = io_in_tdata1Vec_3_DATA;

  xs_Debug_core #(.TRIGGER_NUM(4)) u_core (
    .clock                      (clock),
    .trap_valid                 (io_in_trapInfo_valid),
    .trap_breakpoint            (io_in_trapInfo_bits_trapVec[3]),
    .trap_is_debug_intr         (io_in_trapInfo_bits_isDebugIntr),
    .trap_is_interrupt          (io_in_trapInfo_bits_isInterrupt),
    .trap_single_step           (io_in_trapInfo_bits_singleStep),
    .trap_trigger_action        (io_in_trapInfo_bits_trigger),
    .trap_critical_error        (io_in_trapInfo_bits_criticalErrorState),
    .prvm                       (io_in_privState_PRVM),
    .virt                       (io_in_privState_V),
    .dcsr_cetrig                (io_in_dcsr_CETRIG),
    .dcsr_ebreakvs              (io_in_dcsr_EBREAKVS),
    .dcsr_ebreakvu              (io_in_dcsr_EBREAKVU),
    .dcsr_ebreakm               (io_in_dcsr_EBREAKM),
    .dcsr_ebreaks               (io_in_dcsr_EBREAKS),
    .dcsr_ebreaku               (io_in_dcsr_EBREAKU),
    .tselect                    (io_in_tselect_ALL),
    .tdata1_sel                 (io_in_tdata1Selected_DATA),
    .tdata1_type                (tdata1_type),
    .tdata1_data                (tdata1_data),
    .tdata1_update              (io_in_tdata1Update),
    .tdata2_update              (io_in_tdata2Update),
    .tdata1_wtype               (io_in_tdata1Wdata_TYPE),
    .tdata1_wdata               (io_in_tdata1Wdata_DATA),
    .trigger_frontend_change    (io_out_triggerFrontendChange),
    .new_trigger_chain_legal    (io_out_newTriggerChainIsLegal),
    .frontend_update_valid      (io_out_frontendTrigger_tUpdate_valid),
    .mem_update_valid           (io_out_memTrigger_tUpdate_valid),
    .frontend_enable            (frontend_enable),
    .mem_enable                 (mem_enable),
    .has_debug_trap             (io_out_hasDebugTrap),
    .has_debug_intr             (io_out_hasDebugIntr),
    .has_single_step            (io_out_hasSingleStep),
    .trigger_enter_debug_mode   (io_out_triggerEnterDebugMode),
    .has_debug_ebreak_exception (io_out_hasDebugEbreakException),
    .critical_error_enter_debug (io_out_criticalErrorStateEnterDebug)
  );

  assign io_out_breakPoint = io_in_trapInfo_bits_trapVec[3];

  // Selected trigger's fields (GenTdataDistribute): mcontrol6 MATCH[8:7],
  // SELECT[21], ACTION[15:12], CHAIN[11], STORE[1], LOAD[0] + tdata2.
  assign io_out_memTrigger_tUpdate_bits_addr           = io_in_tselect_ALL;
  assign io_out_memTrigger_tUpdate_bits_tdata_matchType = io_in_tdata1Selected_DATA[8:7];
  assign io_out_memTrigger_tUpdate_bits_tdata_select   = io_in_tdata1Selected_DATA[21];
  assign io_out_memTrigger_tUpdate_bits_tdata_action   = io_in_tdata1Selected_DATA[15:12];
  assign io_out_memTrigger_tUpdate_bits_tdata_chain    = io_in_tdata1Selected_DATA[11];
  assign io_out_memTrigger_tUpdate_bits_tdata_store    = io_in_tdata1Selected_DATA[1];
  assign io_out_memTrigger_tUpdate_bits_tdata_load     = io_in_tdata1Selected_DATA[0];
  assign io_out_memTrigger_tUpdate_bits_tdata_tdata2   = io_in_tdata2Selected_ALL;
  assign io_out_memTrigger_tEnableVec_0                = mem_enable[0];
  assign io_out_memTrigger_tEnableVec_1                = mem_enable[1];
  assign io_out_memTrigger_tEnableVec_2                = mem_enable[2];
  assign io_out_memTrigger_tEnableVec_3                = mem_enable[3];
  assign io_out_memTrigger_debugMode                   = io_in_debugMode;
  assign io_out_memTrigger_triggerCanRaiseBpExp        = io_in_triggerCanRaiseBpExp;

  assign io_out_frontendTrigger_tUpdate_bits_addr           = io_in_tselect_ALL;
  assign io_out_frontendTrigger_tUpdate_bits_tdata_matchType = io_in_tdata1Selected_DATA[8:7];
  assign io_out_frontendTrigger_tUpdate_bits_tdata_select   = io_in_tdata1Selected_DATA[21];
  assign io_out_frontendTrigger_tUpdate_bits_tdata_action   = io_in_tdata1Selected_DATA[15:12];
  assign io_out_frontendTrigger_tUpdate_bits_tdata_chain    = io_in_tdata1Selected_DATA[11];
  assign io_out_frontendTrigger_tUpdate_bits_tdata_tdata2   = io_in_tdata2Selected_ALL;
  assign io_out_frontendTrigger_tEnableVec_0                = frontend_enable[0];
  assign io_out_frontendTrigger_tEnableVec_1                = frontend_enable[1];
  assign io_out_frontendTrigger_tEnableVec_2                = frontend_enable[2];
  assign io_out_frontendTrigger_tEnableVec_3                = frontend_enable[3];
  assign io_out_frontendTrigger_debugMode                   = io_in_debugMode;
  assign io_out_frontendTrigger_triggerCanRaiseBpExp        = io_in_triggerCanRaiseBpExp;
endmodule
