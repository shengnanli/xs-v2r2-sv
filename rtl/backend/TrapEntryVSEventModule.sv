// TrapEntryVSEventModule.sv — privilege-specific trap-entry event transformation.
// This leaf translates trap causes, saved state, and target addresses for the CSR block.
// Address-mode and virtualization cases intentionally preserve the G1 reset/field semantics.
module TrapEntryVSEventModule(
  input         clock,
  input         reset,
  input         valid,
  input         in_causeNO_Interrupt,
  input  [62:0] in_causeNO_ExceptionCode,
  input  [49:0] in_trapPc,
  input         in_trapInst_valid,
  input  [31:0] in_trapInst_bits,
  input  [63:0] in_fetchMalTval,
  input         in_isCrossPageIPF,
  input         in_isFetchMalAddr,
  input         in_satpFlushFirstFetchFault,
  input         in_isFetchBkpt,
  input  [1:0]  in_iMode_PRVM,
  input         in_iMode_V,
  input         in_dMode_V,
  input  [1:0]  in_privState_PRVM,
  input         in_privState_V,
  input         in_vsstatus_SIE,
  input         in_henvcfg_DTE,
  input  [63:0] in_pcFromXtvec,
  input  [3:0]  in_vsatp_MODE,
  input  [3:0]  in_hgatp_MODE,
  input  [3:0]  in_oldSatp_MODE,
  input  [3:0]  in_oldVsatp_MODE,
  input  [63:0] in_memExceptionVAddr,
  input         in_virtualInterruptIsHvictlInject,
  input  [11:0] in_hvictlIID,
  output        out_privState_valid,
  output [1:0]  out_privState_bits_PRVM,
  output        out_privState_bits_V,
  output        out_vsstatus_valid,
  output        out_vsstatus_bits_SIE,
  output        out_vsstatus_bits_SPIE,
  output        out_vsstatus_bits_UBE,
  output        out_vsstatus_bits_SPP,
  output [1:0]  out_vsstatus_bits_VS,
  output [1:0]  out_vsstatus_bits_FS,
  output [1:0]  out_vsstatus_bits_XS,
  output        out_vsstatus_bits_SUM,
  output        out_vsstatus_bits_MXR,
  output        out_vsstatus_bits_SDT,
  output [1:0]  out_vsstatus_bits_UXL,
  output        out_vsstatus_bits_SD,
  output        out_vsepc_valid,
  output [62:0] out_vsepc_bits_epc,
  output        out_vscause_valid,
  output        out_vscause_bits_Interrupt,
  output [62:0] out_vscause_bits_ExceptionCode,
  output        out_vstval_valid,
  output [63:0] out_vstval_bits_ALL,
  output        out_targetPc_valid,
  output [63:0] out_targetPc_bits_pc,
  output        out_targetPc_bits_raiseIPF,
  output        out_targetPc_bits_raiseIAF,
  output        out_targetPc_bits_raiseIGPF
);

  `ifndef SYNTHESIS
    always @(posedge clock) begin
      if (valid & ~reset & ~in_privState_V) begin
        if (`ASSERT_VERBOSE_COND_)
          $fwrite(32'h80000002, "Assertion failed: The mode must be VU or VS when entry VS mode\n    at TrapEntryVSEvent.scala:29 assert(in.privState.isVirtual, \"The mode must be VU or VS when entry VS mode\")\n");
        if (`STOP_COND_)
          xs_assert_v2(`__FILE__, `__LINE__);
      end
      if (valid & in_causeNO_Interrupt & ~in_virtualInterruptIsHvictlInject & ~reset
          & ~(in_causeNO_ExceptionCode == 63'h2 | in_causeNO_ExceptionCode == 63'h6
              | in_causeNO_ExceptionCode == 63'hA | in_causeNO_ExceptionCode == 63'h2F
              | in_causeNO_ExceptionCode == 63'h17 | in_causeNO_ExceptionCode == 63'h2E
              | in_causeNO_ExceptionCode == 63'h2D | in_causeNO_ExceptionCode == 63'h16
              | in_causeNO_ExceptionCode == 63'h2C | in_causeNO_ExceptionCode == 63'h2B
              | in_causeNO_ExceptionCode == 63'h15 | in_causeNO_ExceptionCode == 63'h2A
              | in_causeNO_ExceptionCode == 63'h29 | in_causeNO_ExceptionCode == 63'h14
              | in_causeNO_ExceptionCode == 63'h28 | in_causeNO_ExceptionCode == 63'h27
              | in_causeNO_ExceptionCode == 63'h13 | in_causeNO_ExceptionCode == 63'h26
              | in_causeNO_ExceptionCode == 63'h25 | in_causeNO_ExceptionCode == 63'h12
              | in_causeNO_ExceptionCode == 63'h24 | in_causeNO_ExceptionCode == 63'h23
              | in_causeNO_ExceptionCode == 63'h11 | in_causeNO_ExceptionCode == 63'h22
              | in_causeNO_ExceptionCode == 63'h21 | in_causeNO_ExceptionCode == 63'h10
              | in_causeNO_ExceptionCode == 63'h20 | in_causeNO_ExceptionCode == 63'h3F
              | in_causeNO_ExceptionCode == 63'h1F | in_causeNO_ExceptionCode == 63'h3E
              | in_causeNO_ExceptionCode == 63'h3D | in_causeNO_ExceptionCode == 63'h1E
              | in_causeNO_ExceptionCode == 63'h3C | in_causeNO_ExceptionCode == 63'h3B
              | in_causeNO_ExceptionCode == 63'h1D | in_causeNO_ExceptionCode == 63'h3A
              | in_causeNO_ExceptionCode == 63'h39 | in_causeNO_ExceptionCode == 63'h1C
              | in_causeNO_ExceptionCode == 63'h38 | in_causeNO_ExceptionCode == 63'h37
              | in_causeNO_ExceptionCode == 63'h1B | in_causeNO_ExceptionCode == 63'h36
              | in_causeNO_ExceptionCode == 63'h35 | in_causeNO_ExceptionCode == 63'h1A
              | in_causeNO_ExceptionCode == 63'h34 | in_causeNO_ExceptionCode == 63'h33
              | in_causeNO_ExceptionCode == 63'h19 | in_causeNO_ExceptionCode == 63'h32
              | in_causeNO_ExceptionCode == 63'h31 | in_causeNO_ExceptionCode == 63'h18
              | in_causeNO_ExceptionCode == 63'h30
              | in_causeNO_ExceptionCode == 63'hD)) begin
        if (`ASSERT_VERBOSE_COND_)
          $fwrite(32'h80000002, "Assertion failed: The VS mode can only handle VSEI, VSTI, VSSI and local interrupts\n    at TrapEntryVSEvent.scala:48 assert(\n");
        if (`STOP_COND_)
          xs_assert_v2(`__FILE__, `__LINE__);
      end
    end // always @(posedge)
  `endif // not def SYNTHESIS
  wire [62:0] highPrioTrapNO =
    (in_causeNO_ExceptionCode == 63'h2 | in_causeNO_ExceptionCode == 63'h6
     | in_causeNO_ExceptionCode == 63'hA) & in_causeNO_Interrupt
      ? 63'(in_causeNO_ExceptionCode - 63'h1)
      : in_causeNO_ExceptionCode;
  wire        trapPC_isBare_v_PrvmIsM = &in_iMode_PRVM;
  wire        trapPC_isBare_isModeM = trapPC_isBare_v_PrvmIsM;
  wire        trapPC_isBare_PrvmIsU = in_iMode_PRVM == 2'h0;
  wire        trapPC_isBare_PrvmIsS = in_iMode_PRVM == 2'h1;
  wire        _trapPC_isSv48_calc = trapPC_isBare_PrvmIsU | trapPC_isBare_PrvmIsS;
  wire        _trapPC_isSv48x4_calc2 = in_oldVsatp_MODE == 4'h0;
  wire        _instrAddrTransType_x1_calc1 = in_hgatp_MODE == 4'h0;
  wire        _instrAddrTransType_x4_calc1 = in_hgatp_MODE == 4'h8;
  wire        _instrAddrTransType_x5_calc1 = in_hgatp_MODE == 4'h9;
  wire [63:0] trapPC =
    (trapPC_isBare_isModeM | _trapPC_isSv48_calc & ~in_iMode_V & in_oldSatp_MODE == 4'h0
     | in_iMode_V & _trapPC_isSv48x4_calc2 & _instrAddrTransType_x1_calc1
       ? {16'h0, in_trapPc[47:0]}
       : 64'h0)
    | (_trapPC_isSv48_calc & ~in_iMode_V & in_oldSatp_MODE == 4'h8 | in_iMode_V
       & in_oldVsatp_MODE == 4'h8
         ? {{25{in_trapPc[38]}}, in_trapPc[38:0]}
         : 64'h0)
    | (in_iMode_V & _trapPC_isSv48x4_calc2 & _instrAddrTransType_x4_calc1
         ? {23'h0, in_trapPc[40:0]}
         : 64'h0)
    | (_trapPC_isSv48_calc & ~in_iMode_V & in_oldSatp_MODE == 4'h9 | in_iMode_V
       & in_oldVsatp_MODE == 4'h9
         ? {{16{in_trapPc[47]}}, in_trapPc[47:0]}
         : 64'h0)
    | (in_iMode_V & _trapPC_isSv48x4_calc2 & _instrAddrTransType_x5_calc1
         ? {14'h0, in_trapPc}
         : 64'h0);
  wire        isFetchExcp =
    ~in_causeNO_Interrupt & (highPrioTrapNO == 63'h1 | highPrioTrapNO == 63'hC);
  wire        isBpExcp = ~in_causeNO_Interrupt & highPrioTrapNO == 63'h3;
  wire        isFetchBkpt = isBpExcp & in_isFetchBkpt;
  wire        tvalFillMemVaddr =
    ~in_causeNO_Interrupt
    & (highPrioTrapNO == 63'h4 | highPrioTrapNO == 63'h5 | highPrioTrapNO == 63'h6
       | highPrioTrapNO == 63'h7 | highPrioTrapNO == 63'hD | highPrioTrapNO == 63'hF)
    | isBpExcp & ~in_isFetchBkpt;
  wire        tvalFillGVA =
    (isFetchExcp | isFetchBkpt) & in_iMode_V | tvalFillMemVaddr & in_dMode_V;
  wire [63:0] _tval_calc7 =
    (isFetchExcp & ~in_isCrossPageIPF | isFetchBkpt ? trapPC : 64'h0)
    | (isFetchExcp & in_isCrossPageIPF ? 64'(trapPC + 64'h2) : 64'h0)
    | (tvalFillMemVaddr ? in_memExceptionVAddr : 64'h0);
  wire        _instrAddrTransType_x5_calc = in_vsatp_MODE == 4'h0;
  assign out_privState_valid = valid;
  assign out_privState_bits_PRVM = 2'h1;
  assign out_privState_bits_V = 1'h1;
  assign out_vsstatus_valid = valid;
  assign out_vsstatus_bits_SIE = 1'h0;
  assign out_vsstatus_bits_SPIE = in_vsstatus_SIE;
  assign out_vsstatus_bits_UBE = 1'h0;
  assign out_vsstatus_bits_SPP = in_privState_PRVM[0];
  assign out_vsstatus_bits_VS = 2'h0;
  assign out_vsstatus_bits_FS = 2'h0;
  assign out_vsstatus_bits_XS = 2'h0;
  assign out_vsstatus_bits_SUM = 1'h0;
  assign out_vsstatus_bits_MXR = 1'h0;
  assign out_vsstatus_bits_SDT = in_henvcfg_DTE;
  assign out_vsstatus_bits_UXL = 2'h0;
  assign out_vsstatus_bits_SD = 1'h0;
  assign out_vsepc_valid = valid;
  assign out_vsepc_bits_epc =
    in_satpFlushFirstFetchFault | ~in_isFetchMalAddr
      ? trapPC[63:1]
      : in_fetchMalTval[63:1];
  assign out_vscause_valid = valid;
  assign out_vscause_bits_Interrupt = in_causeNO_Interrupt;
  assign out_vscause_bits_ExceptionCode =
    in_virtualInterruptIsHvictlInject & in_causeNO_Interrupt
      ? {51'h0, in_hvictlIID}
      : highPrioTrapNO;
  assign out_vstval_valid = valid;
  assign out_vstval_bits_ALL =
    in_satpFlushFirstFetchFault | ~(~in_causeNO_Interrupt & in_isFetchMalAddr)
      ? {_tval_calc7[63:32],
         _tval_calc7[31:0]
           | (~in_causeNO_Interrupt & (highPrioTrapNO == 63'h2 | highPrioTrapNO == 63'h16)
              & in_trapInst_valid
                ? in_trapInst_bits
                : 32'h0)}
      : in_fetchMalTval;
  assign out_targetPc_valid = valid;
  assign out_targetPc_bits_pc = in_pcFromXtvec;
  assign out_targetPc_bits_raiseIPF =
    in_vsatp_MODE == 4'h8 & in_pcFromXtvec[63:39] != {25{in_pcFromXtvec[38]}}
    | in_vsatp_MODE == 4'h9 & in_pcFromXtvec[63:48] != {16{in_pcFromXtvec[47]}};
  assign out_targetPc_bits_raiseIAF =
    _instrAddrTransType_x5_calc & _instrAddrTransType_x1_calc1 & (|(in_pcFromXtvec[63:48]));
  assign out_targetPc_bits_raiseIGPF =
    _instrAddrTransType_x5_calc & _instrAddrTransType_x4_calc1 & (|(in_pcFromXtvec[63:41]))
    | _instrAddrTransType_x5_calc & _instrAddrTransType_x5_calc1 & (|(in_pcFromXtvec[63:50]));
endmodule
