// NewCSR TrapHandleModule — readable transcription.
//
// Purely combinational trap dispatcher: given the pending interrupt/exception
// info and the delegation CSRs, it decides which privilege level handles the
// trap (M / HS / VS), the entered privilege state, the encoded cause number, the
// xtvec-derived entry PC, and the double-trap outcome. The readable rewrite
// renames the CIRCT priority-OR wires (excGrpA/B/C, excRegularVec). FM-verified
// strict golden-vs-impl SUCCEEDED, no black box, no dont_verify.


module TrapHandleModule(
  input         io_in_trapInfo_valid,
  input  [63:0] io_in_trapInfo_bits_trapVec,
  input         io_in_trapInfo_bits_nmi,
  input  [7:0]  io_in_trapInfo_bits_intrVec,
  input         io_in_trapInfo_bits_isInterrupt,
  input         io_in_trapInfo_bits_singleStep,
  input         io_in_trapInfo_bits_irToHS,
  input         io_in_trapInfo_bits_irToVS,
  input  [1:0]  io_in_privState_PRVM,
  input         io_in_privState_V,
  input         io_in_mstatus_SDT,
  input         io_in_mstatus_MDT,
  input         io_in_vsstatus_SDT,
  input         io_in_mnstatus_NMIE,
  input         io_in_medeleg_EX_IAM,
  input         io_in_medeleg_EX_IAF,
  input         io_in_medeleg_EX_II,
  input         io_in_medeleg_EX_BP,
  input         io_in_medeleg_EX_LAM,
  input         io_in_medeleg_EX_LAF,
  input         io_in_medeleg_EX_SAM,
  input         io_in_medeleg_EX_SAF,
  input         io_in_medeleg_EX_UCALL,
  input         io_in_medeleg_EX_HSCALL,
  input         io_in_medeleg_EX_VSCALL,
  input         io_in_medeleg_EX_IPF,
  input         io_in_medeleg_EX_LPF,
  input         io_in_medeleg_EX_SPF,
  input         io_in_medeleg_EX_SWC,
  input         io_in_medeleg_EX_HWE,
  input         io_in_medeleg_EX_IGPF,
  input         io_in_medeleg_EX_LGPF,
  input         io_in_medeleg_EX_VI,
  input         io_in_medeleg_EX_SGPF,
  input         io_in_hedeleg_EX_IAM,
  input         io_in_hedeleg_EX_IAF,
  input         io_in_hedeleg_EX_II,
  input         io_in_hedeleg_EX_BP,
  input         io_in_hedeleg_EX_LAM,
  input         io_in_hedeleg_EX_LAF,
  input         io_in_hedeleg_EX_SAM,
  input         io_in_hedeleg_EX_SAF,
  input         io_in_hedeleg_EX_UCALL,
  input         io_in_hedeleg_EX_IPF,
  input         io_in_hedeleg_EX_LPF,
  input         io_in_hedeleg_EX_SPF,
  input         io_in_hedeleg_EX_SWC,
  input         io_in_hedeleg_EX_HWE,
  input  [1:0]  io_in_mtvec_mode,
  input  [61:0] io_in_mtvec_addr,
  input  [1:0]  io_in_stvec_mode,
  input  [61:0] io_in_stvec_addr,
  input  [1:0]  io_in_vstvec_mode,
  input  [61:0] io_in_vstvec_addr,
  output [1:0]  io_out_entryPrivState_PRVM,
  output        io_out_entryPrivState_V,
  output        io_out_causeNO_Interrupt,
  output [62:0] io_out_causeNO_ExceptionCode,
  output        io_out_dbltrpToMN,
  output        io_out_hasDTExcp,
  output [63:0] io_out_pcFromXtvec
);

  wire        hasNMI = io_in_trapInfo_valid & io_in_trapInfo_bits_nmi;
  wire        hasIR = io_in_trapInfo_valid & io_in_trapInfo_bits_isInterrupt;
  wire [23:0] hasEXVec =
    io_in_trapInfo_valid & ~io_in_trapInfo_bits_isInterrupt
      ? io_in_trapInfo_bits_trapVec[23:0]
      : 24'h0;
  wire [7:0]  hasIRVec = hasIR ? io_in_trapInfo_bits_intrVec : 8'h0;
  wire        highestPrioEXVec_1 =
    (&{~(hasEXVec[16]), ~(hasEXVec[3]), ~(hasEXVec[12]), ~(hasEXVec[20])}) & hasEXVec[1];
  wire        highestPrioEXVec_2 =
    (&{~(hasEXVec[16]), ~(hasEXVec[3]), ~(hasEXVec[12]), ~(hasEXVec[20]), ~(hasEXVec[1])})
    & hasEXVec[2];
  wire        highestPrioEXVec_3 = ~(hasEXVec[16]) & hasEXVec[3];
  wire        highestPrioEXVec_4 =
    (&{~(hasEXVec[16]),
       ~(hasEXVec[3]),
       ~(hasEXVec[12]),
       ~(hasEXVec[20]),
       ~(hasEXVec[1]),
       ~(hasEXVec[2]),
       ~(hasEXVec[22]),
       ~(hasEXVec[0]),
       ~(hasEXVec[11]),
       ~(hasEXVec[9]),
       ~(hasEXVec[10]),
       ~(hasEXVec[8]),
       ~(hasEXVec[6])}) & hasEXVec[4];
  wire        highestPrioEXVec_5 =
    (&{~(hasEXVec[16]),
       ~(hasEXVec[3]),
       ~(hasEXVec[12]),
       ~(hasEXVec[20]),
       ~(hasEXVec[1]),
       ~(hasEXVec[2]),
       ~(hasEXVec[22]),
       ~(hasEXVec[0]),
       ~(hasEXVec[11]),
       ~(hasEXVec[9]),
       ~(hasEXVec[10]),
       ~(hasEXVec[8]),
       ~(hasEXVec[6]),
       ~(hasEXVec[4]),
       ~(hasEXVec[15]),
       ~(hasEXVec[13]),
       ~(hasEXVec[23]),
       ~(hasEXVec[21]),
       ~(hasEXVec[7])}) & hasEXVec[5];
  wire        highestPrioEXVec_6 =
    (&{~(hasEXVec[16]),
       ~(hasEXVec[3]),
       ~(hasEXVec[12]),
       ~(hasEXVec[20]),
       ~(hasEXVec[1]),
       ~(hasEXVec[2]),
       ~(hasEXVec[22]),
       ~(hasEXVec[0]),
       ~(hasEXVec[11]),
       ~(hasEXVec[9]),
       ~(hasEXVec[10]),
       ~(hasEXVec[8])}) & hasEXVec[6];
  wire        highestPrioEXVec_7 =
    (&{~(hasEXVec[16]),
       ~(hasEXVec[3]),
       ~(hasEXVec[12]),
       ~(hasEXVec[20]),
       ~(hasEXVec[1]),
       ~(hasEXVec[2]),
       ~(hasEXVec[22]),
       ~(hasEXVec[0]),
       ~(hasEXVec[11]),
       ~(hasEXVec[9]),
       ~(hasEXVec[10]),
       ~(hasEXVec[8]),
       ~(hasEXVec[6]),
       ~(hasEXVec[4]),
       ~(hasEXVec[15]),
       ~(hasEXVec[13]),
       ~(hasEXVec[23]),
       ~(hasEXVec[21])}) & hasEXVec[7];
  wire        highestPrioEXVec_8 =
    (&{~(hasEXVec[16]),
       ~(hasEXVec[3]),
       ~(hasEXVec[12]),
       ~(hasEXVec[20]),
       ~(hasEXVec[1]),
       ~(hasEXVec[2]),
       ~(hasEXVec[22]),
       ~(hasEXVec[0]),
       ~(hasEXVec[11]),
       ~(hasEXVec[9]),
       ~(hasEXVec[10])}) & hasEXVec[8];
  wire        highestPrioEXVec_9 =
    (&{~(hasEXVec[16]),
       ~(hasEXVec[3]),
       ~(hasEXVec[12]),
       ~(hasEXVec[20]),
       ~(hasEXVec[1]),
       ~(hasEXVec[2]),
       ~(hasEXVec[22]),
       ~(hasEXVec[0]),
       ~(hasEXVec[11])}) & hasEXVec[9];
  wire        highestPrioEXVec_10 =
    (&{~(hasEXVec[16]),
       ~(hasEXVec[3]),
       ~(hasEXVec[12]),
       ~(hasEXVec[20]),
       ~(hasEXVec[1]),
       ~(hasEXVec[2]),
       ~(hasEXVec[22]),
       ~(hasEXVec[0]),
       ~(hasEXVec[11]),
       ~(hasEXVec[9])}) & hasEXVec[10];
  wire        highestPrioEXVec_11 =
    (&{~(hasEXVec[16]),
       ~(hasEXVec[3]),
       ~(hasEXVec[12]),
       ~(hasEXVec[20]),
       ~(hasEXVec[1]),
       ~(hasEXVec[2]),
       ~(hasEXVec[22]),
       ~(hasEXVec[0])}) & hasEXVec[11];
  wire        highestPrioEXVec_12 = (&{~(hasEXVec[16]), ~(hasEXVec[3])}) & hasEXVec[12];
  wire        highestPrioEXVec_13 =
    (&{~(hasEXVec[16]),
       ~(hasEXVec[3]),
       ~(hasEXVec[12]),
       ~(hasEXVec[20]),
       ~(hasEXVec[1]),
       ~(hasEXVec[2]),
       ~(hasEXVec[22]),
       ~(hasEXVec[0]),
       ~(hasEXVec[11]),
       ~(hasEXVec[9]),
       ~(hasEXVec[10]),
       ~(hasEXVec[8]),
       ~(hasEXVec[6]),
       ~(hasEXVec[4]),
       ~(hasEXVec[15])}) & hasEXVec[13];
  wire        highestPrioEXVec_15 =
    (&{~(hasEXVec[16]),
       ~(hasEXVec[3]),
       ~(hasEXVec[12]),
       ~(hasEXVec[20]),
       ~(hasEXVec[1]),
       ~(hasEXVec[2]),
       ~(hasEXVec[22]),
       ~(hasEXVec[0]),
       ~(hasEXVec[11]),
       ~(hasEXVec[9]),
       ~(hasEXVec[10]),
       ~(hasEXVec[8]),
       ~(hasEXVec[6]),
       ~(hasEXVec[4])}) & hasEXVec[15];
  wire        highestPrioEXVec_19 =
    (&{~(hasEXVec[16]),
       ~(hasEXVec[3]),
       ~(hasEXVec[12]),
       ~(hasEXVec[20]),
       ~(hasEXVec[1]),
       ~(hasEXVec[2]),
       ~(hasEXVec[22]),
       ~(hasEXVec[0]),
       ~(hasEXVec[11]),
       ~(hasEXVec[9]),
       ~(hasEXVec[10]),
       ~(hasEXVec[8]),
       ~(hasEXVec[6]),
       ~(hasEXVec[4]),
       ~(hasEXVec[15]),
       ~(hasEXVec[13]),
       ~(hasEXVec[23]),
       ~(hasEXVec[21]),
       ~(hasEXVec[7]),
       ~(hasEXVec[5])}) & hasEXVec[19];
  wire        highestPrioEXVec_20 =
    (&{~(hasEXVec[16]), ~(hasEXVec[3]), ~(hasEXVec[12])}) & hasEXVec[20];
  wire        highestPrioEXVec_21 =
    (&{~(hasEXVec[16]),
       ~(hasEXVec[3]),
       ~(hasEXVec[12]),
       ~(hasEXVec[20]),
       ~(hasEXVec[1]),
       ~(hasEXVec[2]),
       ~(hasEXVec[22]),
       ~(hasEXVec[0]),
       ~(hasEXVec[11]),
       ~(hasEXVec[9]),
       ~(hasEXVec[10]),
       ~(hasEXVec[8]),
       ~(hasEXVec[6]),
       ~(hasEXVec[4]),
       ~(hasEXVec[15]),
       ~(hasEXVec[13]),
       ~(hasEXVec[23])}) & hasEXVec[21];
  wire        highestPrioEXVec_22 =
    (&{~(hasEXVec[16]),
       ~(hasEXVec[3]),
       ~(hasEXVec[12]),
       ~(hasEXVec[20]),
       ~(hasEXVec[1]),
       ~(hasEXVec[2])}) & hasEXVec[22];
  wire        highestPrioEXVec_23 =
    (&{~(hasEXVec[16]),
       ~(hasEXVec[3]),
       ~(hasEXVec[12]),
       ~(hasEXVec[20]),
       ~(hasEXVec[1]),
       ~(hasEXVec[2]),
       ~(hasEXVec[22]),
       ~(hasEXVec[0]),
       ~(hasEXVec[11]),
       ~(hasEXVec[9]),
       ~(hasEXVec[10]),
       ~(hasEXVec[8]),
       ~(hasEXVec[6]),
       ~(hasEXVec[4]),
       ~(hasEXVec[15]),
       ~(hasEXVec[13])}) & hasEXVec[23];
  wire [23:0] hsEXVec =
    {highestPrioEXVec_23,
     highestPrioEXVec_22,
     highestPrioEXVec_21,
     highestPrioEXVec_20,
     highestPrioEXVec_19,
     2'h0,
     hasEXVec[16],
     highestPrioEXVec_15,
     1'h0,
     highestPrioEXVec_13,
     highestPrioEXVec_12,
     highestPrioEXVec_11,
     highestPrioEXVec_10,
     highestPrioEXVec_9,
     highestPrioEXVec_8,
     highestPrioEXVec_7,
     highestPrioEXVec_6,
     highestPrioEXVec_5,
     highestPrioEXVec_4,
     highestPrioEXVec_3,
     highestPrioEXVec_2,
     highestPrioEXVec_1,
     (&{~(hasEXVec[16]),
        ~(hasEXVec[3]),
        ~(hasEXVec[12]),
        ~(hasEXVec[20]),
        ~(hasEXVec[1]),
        ~(hasEXVec[2]),
        ~(hasEXVec[22])}) & hasEXVec[0]}
    & {io_in_medeleg_EX_SGPF,
       io_in_medeleg_EX_VI,
       io_in_medeleg_EX_LGPF,
       io_in_medeleg_EX_IGPF,
       io_in_medeleg_EX_HWE,
       io_in_medeleg_EX_SWC,
       2'h0,
       io_in_medeleg_EX_SPF,
       1'h0,
       io_in_medeleg_EX_LPF,
       io_in_medeleg_EX_IPF,
       1'h0,
       io_in_medeleg_EX_VSCALL,
       io_in_medeleg_EX_HSCALL,
       io_in_medeleg_EX_UCALL,
       io_in_medeleg_EX_SAF,
       io_in_medeleg_EX_SAM,
       io_in_medeleg_EX_LAF,
       io_in_medeleg_EX_LAM,
       io_in_medeleg_EX_BP,
       io_in_medeleg_EX_II,
       io_in_medeleg_EX_IAF,
       io_in_medeleg_EX_IAM};
  wire [19:0] vsEXVec =
    hsEXVec[19:0]
    & {io_in_hedeleg_EX_HWE,
       io_in_hedeleg_EX_SWC,
       2'h0,
       io_in_hedeleg_EX_SPF,
       1'h0,
       io_in_hedeleg_EX_LPF,
       io_in_hedeleg_EX_IPF,
       3'h0,
       io_in_hedeleg_EX_UCALL,
       io_in_hedeleg_EX_SAF,
       io_in_hedeleg_EX_SAM,
       io_in_hedeleg_EX_LAF,
       io_in_hedeleg_EX_LAM,
       io_in_hedeleg_EX_BP,
       io_in_hedeleg_EX_II,
       io_in_hedeleg_EX_IAF,
       io_in_hedeleg_EX_IAM};
  wire        vsHasIR = hasIR & io_in_trapInfo_bits_irToVS & ~hasNMI;
  wire        handleTrapUnderHS_v_PrvmIsM = &io_in_privState_PRVM;
  wire        handleTrapUnderHS_isModeM = handleTrapUnderHS_v_PrvmIsM;
  wire        handleTrapUnderHS =
    ~handleTrapUnderHS_isModeM
    & ((|{hsEXVec[23:19], hsEXVec[15], hsEXVec[13:12], hsEXVec[10:0]}) | hasIR
       & io_in_trapInfo_bits_irToHS & ~hasNMI);
  wire        handleTrapUnderVS =
    io_in_privState_V
    & ((|{vsEXVec[19], vsEXVec[15], vsEXVec[13:12], vsEXVec[8:0]}) | vsHasIR);
  // Exception-code bit-2 sub-groups: OR together the highest-priority exception
  // vector bits that map to the same encoded cause bit, feeding the final
  // io_out_causeNO_ExceptionCode packing below.
  wire        excGrpA = highestPrioEXVec_22 | highestPrioEXVec_6;
  wire        excGrpB = highestPrioEXVec_15 | highestPrioEXVec_23 | highestPrioEXVec_7;
  wire        excGrpC = highestPrioEXVec_13 | highestPrioEXVec_21 | highestPrioEXVec_5;
  wire [2:0]  excRegularVec =
    {excGrpB, excGrpA, excGrpC}
    | {highestPrioEXVec_11 | highestPrioEXVec_19 | highestPrioEXVec_3,
       highestPrioEXVec_10 | highestPrioEXVec_2,
       highestPrioEXVec_9 | highestPrioEXVec_1};
  wire        m_EX_DT =
    ~handleTrapUnderVS & ~handleTrapUnderHS & io_in_mstatus_MDT & io_in_trapInfo_valid;
  wire        s_EX_DT = handleTrapUnderHS & io_in_mstatus_SDT & io_in_trapInfo_valid;
  wire        vs_EX_DT = handleTrapUnderVS & io_in_vsstatus_SDT & io_in_trapInfo_valid;
  wire        trapToHS = handleTrapUnderHS & ~s_EX_DT & ~vs_EX_DT;
  wire        traptoVS = handleTrapUnderVS & ~vs_EX_DT;
  assign io_out_entryPrivState_PRVM = {~(traptoVS | trapToHS), 1'h1};
  assign io_out_entryPrivState_V = traptoVS;
  assign io_out_causeNO_Interrupt = hasIR;
  assign io_out_causeNO_ExceptionCode =
    {55'h0,
     hasIR
       ? io_in_trapInfo_bits_intrVec
       : {2'h0,
          io_in_trapInfo_bits_singleStep
            ? 6'h3
            : {1'h0,
               |{highestPrioEXVec_23,
                 highestPrioEXVec_22,
                 highestPrioEXVec_21,
                 highestPrioEXVec_20,
                 highestPrioEXVec_19,
                 hasEXVec[16]},
               |{highestPrioEXVec_15,
                 highestPrioEXVec_13,
                 highestPrioEXVec_12,
                 highestPrioEXVec_11,
                 highestPrioEXVec_10,
                 highestPrioEXVec_9,
                 highestPrioEXVec_8},
               |{excGrpB,
                 excGrpA,
                 excGrpC,
                 highestPrioEXVec_12 | highestPrioEXVec_20 | highestPrioEXVec_4},
               |(excRegularVec[2:1]),
               excRegularVec[2] | excRegularVec[0]}}};
  assign io_out_dbltrpToMN = m_EX_DT & io_in_mnstatus_NMIE;
  assign io_out_hasDTExcp = m_EX_DT | s_EX_DT | vs_EX_DT;
  assign io_out_pcFromXtvec =
    {62'((traptoVS ? io_in_vstvec_addr : trapToHS ? io_in_stvec_addr : io_in_mtvec_addr)
         + {56'h0,
            (traptoVS
               ? io_in_vstvec_mode
               : trapToHS ? io_in_stvec_mode : io_in_mtvec_mode) == 2'h1 & hasIR
              ? ((hasIRVec == 8'h2 | hasIRVec == 8'h6 | hasIRVec == 8'hA) & vsHasIR
                   ? 6'(hasIRVec[5:0] - 6'h1)
                   : hasIRVec[5:0])
              : 6'h0}),
     2'h0};
endmodule
