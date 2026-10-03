// TrapHandleModule.sv — trap entry decision of NewCSR (combinational).
// Given the trap that the ROB reports this cycle (an exception vector or an
// interrupt number) and the delegation CSRs, it answers four questions:
//   1. which exception wins        -> fixed priority pick over the vector
//   2. who handles the trap        -> M by default; HS if delegated by
//                                     medeleg (or the interrupt is routed to
//                                     HS) and we are not in M; VS if further
//                                     delegated by hedeleg and we are in a
//                                     guest (V=1)
//   3. is it a double trap         -> the target level already has its
//                                     xDT bit set (Smdbltrp / Ssdbltrp); the
//                                     trap is then escalated: a VS or HS
//                                     double trap goes to M, an M double trap
//                                     is reported (and goes to the NMI
//                                     handler when mnstatus.NMIE allows)
//   4. where to jump               -> the chosen level's xtvec; in vectored
//                                     mode an interrupt adds 4*cause, where a
//                                     VS interrupt taken in VS uses the
//                                     supervisor number (cause-1)
// Config facts from golden: only exception numbers 0..23 exist (trapVec bits
// above 23 are ignored); 14 and 17 are never raised; medeleg has no bit for
// 11 (ecall-M), 14, 16 (double trap), 17 and hedeleg none for 9..11, 14,
// 16..17, 20..23 — those are hard zero.  Bug-for-bug: single-step forces the
// reported exception code to breakpoint (3) but does not influence the
// delegation decision; "in M mode" is PRVM==3 only (V is not consulted).
package traphandle_pkg;
  localparam int EXC_NUM = 24;
  typedef logic [EXC_NUM-1:0] exc_vec_t;

  // Exception priority, highest first (Scala ExceptionNO.priorities).
  localparam int EXC_PRIO_LEN = 22;
  localparam int EXC_PRIO [EXC_PRIO_LEN] = '{
    16,  // double trap
    3,   // breakpoint
    12,  // instruction page fault
    20,  // instruction guest-page fault
    1,   // instruction access fault
    18,  // software check
    2,   // illegal instruction
    22,  // virtual instruction
    0,   // instruction address misaligned
    11,  // ecall from M
    9,   // ecall from HS
    10,  // ecall from VS
    8,   // ecall from U
    6,   // store address misaligned
    4,   // load address misaligned
    15,  // store page fault
    13,  // load page fault
    23,  // store guest-page fault
    21,  // load guest-page fault
    7,   // store access fault
    5,   // load access fault
    19   // hardware error
  };

  localparam logic [5:0] EXC_BREAKPOINT = 6'd3;
  localparam logic [1:0] PRV_M = 2'b11;
  localparam logic [1:0] PRV_S = 2'b01;
  localparam logic [1:0] TVEC_VECTORED = 2'b01;

  typedef struct packed {
    logic [61:0] addr;   // xtvec[63:2]
    logic [1:0]  mode;
  } xtvec_t;
endpackage

module xs_TrapHandleModule_core
  import traphandle_pkg::*;
(
  input  logic        trap_valid,
  input  exc_vec_t    exc_vec,        // pending exceptions (when !is_interrupt)
  input  logic [7:0]  intr_no,        // interrupt cause (when is_interrupt)
  input  logic        is_interrupt,
  input  logic        single_step,
  input  logic        intr_to_hs,     // interrupt is routed to HS
  input  logic        intr_to_vs,     // interrupt is routed to VS
  input  logic [1:0]  cur_prvm,       // current privilege
  input  logic        cur_v,          // current virtualisation mode
  input  logic        mstatus_mdt,
  input  logic        sstatus_sdt,
  input  logic        vsstatus_sdt,
  input  logic        mnstatus_nmie,
  input  exc_vec_t    medeleg,
  input  exc_vec_t    hedeleg,
  input  xtvec_t      mtvec,
  input  xtvec_t      stvec,
  input  xtvec_t      vstvec,
  output logic [1:0]  entry_prvm,     // privilege after trap entry
  output logic        entry_v,
  output logic        cause_is_intr,
  output logic [62:0] cause_code,
  output logic        dbltrp_to_mn,   // M double trap, NMI handler enabled
  output logic        has_dt_excp,    // some double trap happened
  output logic [63:0] pc_from_xtvec
);
  // ---- 1. What is trapping ----------------------------------------------------
  logic     has_intr;
  logic     has_exc;
  exc_vec_t exc_pending;
  assign has_intr    = trap_valid & is_interrupt;
  assign has_exc     = trap_valid & ~is_interrupt;
  assign exc_pending = has_exc ? exc_vec : '0;

  // Fixed-priority pick: walk the priority list, the first pending one wins.
  // exc_winner is one-hot (or zero); exc_code is its number.
  exc_vec_t   exc_winner;
  logic [5:0] exc_code;
  always_comb begin
    exc_winner = '0;
    exc_code   = 6'd0;
    for (int k = EXC_PRIO_LEN - 1; k >= 0; k--) begin
      if (exc_pending[EXC_PRIO[k]]) begin
        exc_winner               = '0;
        exc_winner[EXC_PRIO[k]]  = 1'b1;
        exc_code                 = 6'(EXC_PRIO[k]);
      end
    end
  end

  // ---- 2. Who handles it --------------------------------------------------------
  exc_vec_t exc_to_hs;
  exc_vec_t exc_to_vs;
  logic     hs_has_trap;
  logic     vs_has_trap;
  logic     vs_has_intr;
  logic     handle_in_hs;   // delegated at least to HS
  logic     handle_in_vs;   // delegated all the way to VS
  logic     handle_in_m;

  assign exc_to_hs   = exc_winner & medeleg;
  assign exc_to_vs   = exc_winner & medeleg & hedeleg;
  assign vs_has_intr = has_intr & intr_to_vs;
  assign hs_has_trap = (|exc_to_hs) | (has_intr & intr_to_hs);
  assign vs_has_trap = (|exc_to_vs) | vs_has_intr;

  assign handle_in_hs = (cur_prvm != PRV_M) & hs_has_trap;
  assign handle_in_vs = cur_v & vs_has_trap;
  assign handle_in_m  = ~handle_in_vs & ~handle_in_hs;

  // ---- 3. Double trap -----------------------------------------------------------
  logic m_double_trap;
  logic s_double_trap;
  logic vs_double_trap;
  logic trap_to_hs;
  logic trap_to_vs;

  assign m_double_trap  = handle_in_m  & mstatus_mdt  & trap_valid;
  assign s_double_trap  = handle_in_hs & sstatus_sdt  & trap_valid;
  assign vs_double_trap = handle_in_vs & vsstatus_sdt & trap_valid;

  // A double trap at HS/VS level is escalated, i.e. it is no longer taken there.
  assign trap_to_hs = handle_in_hs & ~s_double_trap & ~vs_double_trap;
  assign trap_to_vs = handle_in_vs & ~vs_double_trap;

  assign dbltrp_to_mn = m_double_trap & mnstatus_nmie;
  assign has_dt_excp  = m_double_trap | s_double_trap | vs_double_trap;

  // VS has priority over HS when both flags are set.
  assign entry_prvm = (trap_to_vs | trap_to_hs) ? PRV_S : PRV_M;
  assign entry_v    = trap_to_vs;

  // ---- Cause ----------------------------------------------------------------------
  assign cause_is_intr = has_intr;
  assign cause_code    = {55'h0, has_intr ? intr_no
                                          : {2'b00, single_step ? EXC_BREAKPOINT : exc_code}};

  // ---- 4. Trap vector -------------------------------------------------------------
  xtvec_t     xtvec;
  logic [7:0] intr_cause;       // interrupt number, zero when not an interrupt
  logic       intr_is_vs;       // VSSI / VSTI / VSEI
  logic [5:0] vector_index;

  assign xtvec = trap_to_vs ? vstvec
               : trap_to_hs ? stvec
               :              mtvec;

  assign intr_cause = has_intr ? intr_no : 8'h0;
  assign intr_is_vs = (intr_cause == 8'd2) | (intr_cause == 8'd6) | (intr_cause == 8'd10);

  // The guest sees its interrupts under the supervisor numbers (2 -> 1 ...).
  assign vector_index = (intr_is_vs & vs_has_intr) ? 6'(intr_cause[5:0] - 6'd1)
                                                   : intr_cause[5:0];

  assign pc_from_xtvec = {62'(xtvec.addr + 62'(((xtvec.mode == TVEC_VECTORED) & has_intr)
                                              ? vector_index : 6'd0)),
                          2'b00};
endmodule

module TrapHandleModule (
  input         io_in_trapInfo_valid,
  input  [63:0] io_in_trapInfo_bits_trapVec,
  input  [7:0]  io_in_trapInfo_bits_intrVec,
  input         io_in_trapInfo_bits_isInterrupt,
  input         io_in_trapInfo_bits_singleStep,
  input         io_in_trapInfo_bits_irToHS,
  input         io_in_trapInfo_bits_irToVS,
  input  [1:0]  io_in_privState_PRVM,
  input         io_in_privState_V,
  input         io_in_mstatus_MDT,
  input         io_in_sstatus_SDT,
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
  // Delegation CSRs re-indexed by exception number; numbers without a golden
  // port are not delegatable (hard zero).
  traphandle_pkg::exc_vec_t medeleg;
  traphandle_pkg::exc_vec_t hedeleg;

  always_comb begin
    medeleg     = '0;
    medeleg[0]  = io_in_medeleg_EX_IAM;
    medeleg[1]  = io_in_medeleg_EX_IAF;
    medeleg[2]  = io_in_medeleg_EX_II;
    medeleg[3]  = io_in_medeleg_EX_BP;
    medeleg[4]  = io_in_medeleg_EX_LAM;
    medeleg[5]  = io_in_medeleg_EX_LAF;
    medeleg[6]  = io_in_medeleg_EX_SAM;
    medeleg[7]  = io_in_medeleg_EX_SAF;
    medeleg[8]  = io_in_medeleg_EX_UCALL;
    medeleg[9]  = io_in_medeleg_EX_HSCALL;
    medeleg[10] = io_in_medeleg_EX_VSCALL;
    medeleg[12] = io_in_medeleg_EX_IPF;
    medeleg[13] = io_in_medeleg_EX_LPF;
    medeleg[15] = io_in_medeleg_EX_SPF;
    medeleg[18] = io_in_medeleg_EX_SWC;
    medeleg[19] = io_in_medeleg_EX_HWE;
    medeleg[20] = io_in_medeleg_EX_IGPF;
    medeleg[21] = io_in_medeleg_EX_LGPF;
    medeleg[22] = io_in_medeleg_EX_VI;
    medeleg[23] = io_in_medeleg_EX_SGPF;
  end

  always_comb begin
    hedeleg     = '0;
    hedeleg[0]  = io_in_hedeleg_EX_IAM;
    hedeleg[1]  = io_in_hedeleg_EX_IAF;
    hedeleg[2]  = io_in_hedeleg_EX_II;
    hedeleg[3]  = io_in_hedeleg_EX_BP;
    hedeleg[4]  = io_in_hedeleg_EX_LAM;
    hedeleg[5]  = io_in_hedeleg_EX_LAF;
    hedeleg[6]  = io_in_hedeleg_EX_SAM;
    hedeleg[7]  = io_in_hedeleg_EX_SAF;
    hedeleg[8]  = io_in_hedeleg_EX_UCALL;
    hedeleg[12] = io_in_hedeleg_EX_IPF;
    hedeleg[13] = io_in_hedeleg_EX_LPF;
    hedeleg[15] = io_in_hedeleg_EX_SPF;
    hedeleg[18] = io_in_hedeleg_EX_SWC;
    hedeleg[19] = io_in_hedeleg_EX_HWE;
  end

  xs_TrapHandleModule_core u_core (
    .trap_valid   (io_in_trapInfo_valid),
    .exc_vec      (io_in_trapInfo_bits_trapVec[traphandle_pkg::EXC_NUM-1:0]),
    .intr_no      (io_in_trapInfo_bits_intrVec),
    .is_interrupt (io_in_trapInfo_bits_isInterrupt),
    .single_step  (io_in_trapInfo_bits_singleStep),
    .intr_to_hs   (io_in_trapInfo_bits_irToHS),
    .intr_to_vs   (io_in_trapInfo_bits_irToVS),
    .cur_prvm     (io_in_privState_PRVM),
    .cur_v        (io_in_privState_V),
    .mstatus_mdt  (io_in_mstatus_MDT),
    .sstatus_sdt  (io_in_sstatus_SDT),
    .vsstatus_sdt (io_in_vsstatus_SDT),
    .mnstatus_nmie(io_in_mnstatus_NMIE),
    .medeleg      (medeleg),
    .hedeleg      (hedeleg),
    .mtvec        ('{addr: io_in_mtvec_addr,  mode: io_in_mtvec_mode}),
    .stvec        ('{addr: io_in_stvec_addr,  mode: io_in_stvec_mode}),
    .vstvec       ('{addr: io_in_vstvec_addr, mode: io_in_vstvec_mode}),
    .entry_prvm   (io_out_entryPrivState_PRVM),
    .entry_v      (io_out_entryPrivState_V),
    .cause_is_intr(io_out_causeNO_Interrupt),
    .cause_code   (io_out_causeNO_ExceptionCode),
    .dbltrp_to_mn (io_out_dbltrpToMN),
    .has_dt_excp  (io_out_hasDTExcp),
    .pc_from_xtvec(io_out_pcFromXtvec)
  );
endmodule
