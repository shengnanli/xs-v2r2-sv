// TrapEntryMNEventModule.sv — privilege-specific trap-entry event transformation.
// This leaf translates trap causes, saved state, and target addresses for the CSR block.
// Address-mode and virtualization cases intentionally preserve the G1 reset/field semantics.
module TrapEntryMNEventModule(
  input         valid,
  input         in_causeNO_Interrupt,
  input  [62:0] in_causeNO_ExceptionCode,
  input  [49:0] in_trapPc,
  input  [63:0] in_fetchMalTval,
  input         in_isFetchMalAddr,
  input         in_satpFlushFirstFetchFault,
  input  [1:0]  in_iMode_PRVM,
  input         in_iMode_V,
  input  [1:0]  in_privState_PRVM,
  input         in_privState_V,
  input  [63:0] in_pcFromXtvec,
  input  [3:0]  in_hgatp_MODE,
  input  [3:0]  in_oldSatp_MODE,
  input  [3:0]  in_oldVsatp_MODE,
  output        out_privState_valid,
  output [1:0]  out_privState_bits_PRVM,
  output        out_privState_bits_V,
  output        out_mnstatus_valid,
  output        out_mnstatus_bits_NMIE,
  output        out_mnstatus_bits_MNPV,
  output        out_mnstatus_bits_MNPELP,
  output [1:0]  out_mnstatus_bits_MNPP,
  output        out_mnepc_valid,
  output [62:0] out_mnepc_bits_epc,
  output        out_mncause_valid,
  output        out_mncause_bits_Interrupt,
  output [62:0] out_mncause_bits_ExceptionCode,
  output        out_targetPc_valid,
  output [63:0] out_targetPc_bits_pc,
  output        out_targetPc_bits_raiseIPF,
  output        out_targetPc_bits_raiseIAF,
  output        out_targetPc_bits_raiseIGPF
);

  wire trapPC_isBare_v_PrvmIsM = &in_iMode_PRVM;
  wire trapPC_isBare_isModeM = trapPC_isBare_v_PrvmIsM;
  wire trapPC_isBare_PrvmIsU = in_iMode_PRVM == 2'h0;
  wire trapPC_isBare_PrvmIsS = in_iMode_PRVM == 2'h1;
  wire _trapPC_isSv48_calc = trapPC_isBare_PrvmIsU | trapPC_isBare_PrvmIsS;
  wire _trapPC_isSv48x4_calc2 = in_oldVsatp_MODE == 4'h0;
  assign out_privState_valid = valid;
  assign out_privState_bits_PRVM = 2'h3;
  assign out_privState_bits_V = 1'h0;
  assign out_mnstatus_valid = valid;
  assign out_mnstatus_bits_NMIE = 1'h0;
  assign out_mnstatus_bits_MNPV = in_privState_V;
  assign out_mnstatus_bits_MNPELP = 1'h0;
  assign out_mnstatus_bits_MNPP = in_privState_PRVM;
  assign out_mnepc_valid = valid;
  assign out_mnepc_bits_epc =
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
  assign out_mncause_valid = valid;
  assign out_mncause_bits_Interrupt = in_causeNO_Interrupt;
  assign out_mncause_bits_ExceptionCode = in_causeNO_ExceptionCode;
  assign out_targetPc_valid = valid;
  assign out_targetPc_bits_pc = in_pcFromXtvec;
  assign out_targetPc_bits_raiseIPF = 1'h0;
  assign out_targetPc_bits_raiseIAF = |(in_pcFromXtvec[63:48]);
  assign out_targetPc_bits_raiseIGPF = 1'h0;
endmodule
