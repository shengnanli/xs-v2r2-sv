// TrapEntryDEventModule.sv — privilege-specific trap-entry event transformation.
// This leaf translates trap causes, saved state, and target addresses for the CSR block.
// Address-mode and virtualization cases intentionally preserve the G1 reset/field semantics.
module TrapEntryDEventModule(
  input         valid,
  input  [49:0] in_trapPc,
  input  [63:0] in_fetchMalTval,
  input         in_isFetchMalAddr,
  input         in_satpFlushFirstFetchFault,
  input  [1:0]  in_iMode_PRVM,
  input         in_iMode_V,
  input  [1:0]  in_privState_PRVM,
  input         in_privState_V,
  input  [3:0]  in_hgatp_MODE,
  input  [3:0]  in_oldSatp_MODE,
  input  [3:0]  in_oldVsatp_MODE,
  input         in_hasTrap,
  input         in_debugMode,
  input         in_hasDebugIntr,
  input         in_triggerEnterDebugMode,
  input         in_hasDebugEbreakException,
  input         in_hasSingleStep,
  input         in_breakPoint,
  input         in_criticalErrorStateEnterDebug,
  input         in_holdDpc,
  output        out_privState_valid,
  output [1:0]  out_privState_bits_PRVM,
  output        out_privState_bits_V,
  output        out_dcsr_valid,
  output [3:0]  out_dcsr_bits_DEBUGVER,
  output [2:0]  out_dcsr_bits_EXTCAUSE,
  output        out_dcsr_bits_CETRIG,
  output        out_dcsr_bits_EBREAKVS,
  output        out_dcsr_bits_EBREAKVU,
  output        out_dcsr_bits_EBREAKM,
  output        out_dcsr_bits_EBREAKS,
  output        out_dcsr_bits_EBREAKU,
  output        out_dcsr_bits_STEPIE,
  output        out_dcsr_bits_STOPCOUNT,
  output        out_dcsr_bits_STOPTIME,
  output [2:0]  out_dcsr_bits_CAUSE,
  output        out_dcsr_bits_V,
  output        out_dcsr_bits_MPRVEN,
  output        out_dcsr_bits_NMIP,
  output        out_dcsr_bits_STEP,
  output [1:0]  out_dcsr_bits_PRV,
  output        out_dpc_valid,
  output [62:0] out_dpc_bits_epc,
  output        out_targetPc_valid,
  output [63:0] out_targetPc_bits_pc,
  output        out_targetPc_bits_raiseIPF,
  output        out_targetPc_bits_raiseIAF,
  output        out_targetPc_bits_raiseIGPF,
  output        out_debugMode_valid,
  output        out_debugMode_bits,
  output        out_debugIntrEnable_valid,
  output        out_debugIntrEnable_bits
);

  wire hasExceptionInDmode = in_debugMode & in_hasTrap;
  wire trapPC_isBare_v_PrvmIsM = &in_iMode_PRVM;
  wire trapPC_isBare_isModeM = trapPC_isBare_v_PrvmIsM;
  wire trapPC_isBare_PrvmIsU = in_iMode_PRVM == 2'h0;
  wire trapPC_isBare_PrvmIsS = in_iMode_PRVM == 2'h1;
  wire _trapPC_isSv48_calc = trapPC_isBare_PrvmIsU | trapPC_isBare_PrvmIsS;
  wire _trapPC_isSv48x4_calc2 = in_oldVsatp_MODE == 4'h0;
  assign out_privState_valid = valid;
  assign out_privState_bits_PRVM = 2'h3;
  assign out_privState_bits_V = 1'h0;
  assign out_dcsr_valid = valid;
  assign out_dcsr_bits_DEBUGVER = 4'h0;
  assign out_dcsr_bits_EXTCAUSE = 3'h0;
  assign out_dcsr_bits_CETRIG = 1'h0;
  assign out_dcsr_bits_EBREAKVS = 1'h0;
  assign out_dcsr_bits_EBREAKVU = 1'h0;
  assign out_dcsr_bits_EBREAKM = 1'h0;
  assign out_dcsr_bits_EBREAKS = 1'h0;
  assign out_dcsr_bits_EBREAKU = 1'h0;
  assign out_dcsr_bits_STEPIE = 1'h0;
  assign out_dcsr_bits_STOPCOUNT = 1'h0;
  assign out_dcsr_bits_STOPTIME = 1'h0;
  assign out_dcsr_bits_CAUSE =
    in_criticalErrorStateEnterDebug
      ? 3'h7
      : in_hasDebugIntr
          ? 3'h3
          : in_triggerEnterDebugMode
              ? 3'h2
              : in_hasDebugEbreakException ? 3'h1 : {in_hasSingleStep, 2'h0};
  assign out_dcsr_bits_V = in_privState_V;
  assign out_dcsr_bits_MPRVEN = 1'h0;
  assign out_dcsr_bits_NMIP = 1'h0;
  assign out_dcsr_bits_STEP = 1'h0;
  assign out_dcsr_bits_PRV = in_privState_PRVM;
  assign out_dpc_valid = valid & ~in_holdDpc;
  assign out_dpc_bits_epc =
    in_satpFlushFirstFetchFault | ~in_isFetchMalAddr
      ? (trapPC_isBare_isModeM | _trapPC_isSv48_calc & ~in_iMode_V & in_oldSatp_MODE == 4'h0
         | in_iMode_V & _trapPC_isSv48x4_calc2 & in_hgatp_MODE == 4'h0
           ? {16'h0, in_trapPc[47:1]}
           : 63'h0)
        | (_trapPC_isSv48_calc & ~in_iMode_V & in_oldSatp_MODE == 4'h8 | in_iMode_V
           & in_oldVsatp_MODE == 4'h8
             ? {{25{in_trapPc[38]}}, in_trapPc[38:1]}
             : 63'h0)
        | (in_iMode_V & _trapPC_isSv48x4_calc2 & in_hgatp_MODE == 4'h8
             ? {23'h0, in_trapPc[40:1]}
             : 63'h0)
        | (_trapPC_isSv48_calc & ~in_iMode_V & in_oldSatp_MODE == 4'h9 | in_iMode_V
           & in_oldVsatp_MODE == 4'h9
             ? {{16{in_trapPc[47]}}, in_trapPc[47:1]}
             : 63'h0)
        | (in_iMode_V & _trapPC_isSv48x4_calc2 & in_hgatp_MODE == 4'h9
             ? {14'h0, in_trapPc[49:1]}
             : 63'h0)
      : in_fetchMalTval[63:1];
  assign out_targetPc_valid = valid | hasExceptionInDmode;
  assign out_targetPc_bits_pc = {60'h3802080, hasExceptionInDmode & ~in_breakPoint, 3'h0};
  assign out_targetPc_bits_raiseIPF = 1'h0;
  assign out_targetPc_bits_raiseIAF = 1'h0;
  assign out_targetPc_bits_raiseIGPF = 1'h0;
  assign out_debugMode_valid = valid;
  assign out_debugMode_bits = 1'h1;
  assign out_debugIntrEnable_valid = valid;
  assign out_debugIntrEnable_bits = 1'h0;
endmodule
