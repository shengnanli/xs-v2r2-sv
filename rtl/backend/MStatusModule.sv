// MStatusModule.sv — machine status CSR (mstatus) of NewCSR, which also
// serves sstatus: sstatus is a restricted view of the same flops.
// Every field has its own list of writers.  Writers are combined the way
// Chisel's Mux1H does it — an OR of (valid & data) — so two writers firing in
// the same cycle OR their data (kept bug-for-bug; in the real core the events
// are mutually exclusive).  The writers are:
//   csr      a CSR write to mstatus            (all fields)
//   alias    a CSR write to sstatus            (S-visible fields only)
//   trap_m   trap entry into M                 (MIE MPIE MPP GVA MPV MDT)
//   trap_hs  trap entry into HS                (SIE SPIE SPP SDT)
//   ret_m    mret                              (MIE MPIE MPP MPRV SDT MPV MDT)
//   ret_s    sret                              (SIE SPIE SPP MPRV SDT MDT)
//   ret_d    dret   / ret_mn  mnret            (MPRV SDT MDT)
//   dirty    FP/vector state modified          (FS / VS forced to Dirty)
// Special rules on top of the plain field table (Smdbltrp / Ssdbltrp):
//   * writing MDT=1 through mstatus clears MIE in the same cycle;
//   * writing SDT=1 clears SIE; through sstatus the written SDT only counts
//     when menvcfg.DTE=1, otherwise the *current* SDT is used for this rule
//     and the SDT flop itself holds (even against other writers that cycle);
//   * sstatus reads SDT as zero while menvcfg.DTE=0;
//   * MPP is WARL: a CSR write of the reserved value 2'b10 does not enable
//     the update (the data path still ORs it in if a trap/mret enables it).
// Read-only constants: UXL=SXL=2 (64-bit), XS/UBE/SBE/MBE=0; SD = FS or VS
// dirty.  Reset: asynchronous; everything 0 except MDT=1.
package mstatus_pkg;
  // Field positions in the mstatus / sstatus CSR encoding.
  localparam int MS_SIE  = 1;
  localparam int MS_MIE  = 3;
  localparam int MS_SPIE = 5;
  localparam int MS_MPIE = 7;
  localparam int MS_SPP  = 8;
  localparam int MS_VS   = 9;   // [10:9]
  localparam int MS_MPP  = 11;  // [12:11]
  localparam int MS_FS   = 13;  // [14:13]
  localparam int MS_MPRV = 17;
  localparam int MS_SUM  = 18;
  localparam int MS_MXR  = 19;
  localparam int MS_TVM  = 20;
  localparam int MS_TW   = 21;
  localparam int MS_TSR  = 22;
  localparam int MS_SDT  = 24;
  localparam int MS_UXL  = 32;  // [33:32]
  localparam int MS_SXL  = 34;  // [35:34]
  localparam int MS_GVA  = 38;
  localparam int MS_MPV  = 39;
  localparam int MS_MDT  = 42;
  localparam int MS_SD   = 63;

  localparam logic [1:0] CTX_DIRTY = 2'b11;
  localparam logic [1:0] XLEN_64   = 2'b10;
  localparam logic [1:0] PRV_RSVD  = 2'b10;  // not a legal MPP value

  // The registered fields, in CSR order.
  typedef struct packed {
    logic       MDT;
    logic       MPV;
    logic       GVA;
    logic       SDT;
    logic       TSR;
    logic       TW;
    logic       TVM;
    logic       MXR;
    logic       SUM;
    logic       MPRV;
    logic [1:0] FS;
    logic [1:0] MPP;
    logic [1:0] VS;
    logic       SPP;
    logic       MPIE;
    logic       SPIE;
    logic       MIE;
    logic       SIE;
  } mstatus_fields_t;

  // Event writers.  Each carries only the fields it updates.
  typedef struct packed {
    logic       valid;
    logic       MIE;
    logic       MPIE;
    logic [1:0] MPP;
    logic       GVA;
    logic       MPV;
    logic       MDT;
  } trap_to_m_t;

  typedef struct packed {
    logic valid;
    logic SIE;
    logic SPIE;
    logic SPP;
    logic SDT;
  } trap_to_hs_t;

  typedef struct packed {  // dret and mnret
    logic valid;
    logic MPRV;
    logic SDT;
    logic MDT;
  } ret_dbg_t;

  typedef struct packed {
    logic       valid;
    logic       MIE;
    logic       MPIE;
    logic [1:0] MPP;
    logic       MPRV;
    logic       SDT;
    logic       MPV;
    logic       MDT;
  } ret_from_m_t;

  typedef struct packed {
    logic valid;
    logic SIE;
    logic SPIE;
    logic SPP;
    logic MPRV;
    logic SDT;
    logic MDT;
  } ret_from_s_t;
endpackage

module xs_MStatusModule_core
  import mstatus_pkg::*;
(
  input  logic            clk,
  input  logic            rst,
  input  logic            csr_wen,      // CSR write to mstatus
  input  logic [63:0]     csr_wdata,
  input  logic            alias_wen,    // CSR write to sstatus
  input  logic [63:0]     alias_wdata,
  input  trap_to_m_t      trap_m,
  input  trap_to_hs_t     trap_hs,
  input  ret_dbg_t        ret_d,
  input  ret_from_m_t     ret_m,
  input  ret_dbg_t        ret_mn,
  input  ret_from_s_t     ret_s,
  input  logic            fs_dirty,     // FP state written this cycle
  input  logic            vs_dirty,     // vector state written this cycle
  input  logic            menvcfg_dte,  // S-mode double-trap enabled
  output mstatus_fields_t fields,       // the flops (regOut)
  output logic            sd,           // FS or VS dirty
  output logic            sstatus_sdt,  // SDT as seen through sstatus
  output logic [63:0]     mstatus_rdata,
  output logic [63:0]     sstatus_rdata
);
  mstatus_fields_t st;
  assign fields = st;

  // ---- Writer groups --------------------------------------------------------
  // Which writers can touch the S-level fields and the M-level trap stack.
  logic s_stack_write;   // SIE / SPIE / SPP
  logic m_stack_write;   // MIE / MPIE / MPV
  logic sw_write;        // either CSR path (fields shared by mstatus/sstatus)
  logic any_ret;         // any of the four return events
  assign s_stack_write = csr_wen | trap_hs.valid | ret_s.valid | alias_wen;
  assign m_stack_write = csr_wen | trap_m.valid | ret_m.valid;
  assign sw_write      = csr_wen | alias_wen;
  assign any_ret       = ret_d.valid | ret_m.valid | ret_mn.valid | ret_s.valid;

  // ---- Double-trap side effects on the interrupt enables --------------------
  logic clear_mie;   // MDT explicitly written 1
  logic clear_sie;   // SDT explicitly written 1
  assign clear_mie = csr_wen & csr_wdata[MS_MDT];
  assign clear_sie = csr_wen ? csr_wdata[MS_SDT]
                             : alias_wen & (menvcfg_dte ? alias_wdata[MS_SDT] : st.SDT);

  // SDT holds when sstatus is written with DTE off, whatever else fires.
  logic sdt_write;
  assign sdt_write = (csr_wen | trap_hs.valid | any_ret | alias_wen)
                   & ~(~menvcfg_dte & alias_wen);

  // ---- S-level trap stack: SIE, SPIE, SPP ------------------------------------
  logic sie_mux;
  assign sie_mux = (trap_hs.valid & trap_hs.SIE) | (ret_s.valid & ret_s.SIE)
                 | (alias_wen & alias_wdata[MS_SIE]) | (csr_wen & csr_wdata[MS_SIE]);

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      st.SIE  <= 1'b0;
      st.SPIE <= 1'b0;
      st.SPP  <= 1'b0;
    end else begin
      st.SIE <= ~clear_sie & (s_stack_write ? sie_mux : st.SIE);
      if (s_stack_write) begin
        st.SPIE <= (trap_hs.valid & trap_hs.SPIE) | (ret_s.valid & ret_s.SPIE)
                 | (alias_wen & alias_wdata[MS_SPIE]) | (csr_wen & csr_wdata[MS_SPIE]);
        st.SPP  <= (trap_hs.valid & trap_hs.SPP) | (ret_s.valid & ret_s.SPP)
                 | (alias_wen & alias_wdata[MS_SPP]) | (csr_wen & csr_wdata[MS_SPP]);
      end
    end
  end

  // ---- M-level trap stack: MIE, MPIE, MPP, MPV, GVA ---------------------------
  logic mie_mux;
  logic mpp_write;
  assign mie_mux   = (trap_m.valid & trap_m.MIE) | (ret_m.valid & ret_m.MIE)
                   | (csr_wen & csr_wdata[MS_MIE]);
  assign mpp_write = (csr_wen & (csr_wdata[MS_MPP +: 2] != PRV_RSVD))
                   | trap_m.valid | ret_m.valid;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      st.MIE  <= 1'b0;
      st.MPIE <= 1'b0;
      st.MPP  <= 2'b00;
      st.MPV  <= 1'b0;
      st.GVA  <= 1'b0;
    end else begin
      st.MIE <= ~clear_mie & (m_stack_write ? mie_mux : st.MIE);
      if (m_stack_write) begin
        st.MPIE <= (trap_m.valid & trap_m.MPIE) | (ret_m.valid & ret_m.MPIE)
                 | (csr_wen & csr_wdata[MS_MPIE]);
        st.MPV  <= (trap_m.valid & trap_m.MPV) | (ret_m.valid & ret_m.MPV)
                 | (csr_wen & csr_wdata[MS_MPV]);
      end
      if (mpp_write)
        st.MPP <= (trap_m.valid ? trap_m.MPP : 2'b00) | (ret_m.valid ? ret_m.MPP : 2'b00)
                | (csr_wen ? csr_wdata[MS_MPP +: 2] : 2'b00);
      if (csr_wen | trap_m.valid)
        st.GVA <= (trap_m.valid & trap_m.GVA) | (csr_wen & csr_wdata[MS_GVA]);
    end
  end

  // ---- Context status: FS, VS -------------------------------------------------
  // "Dirty" from the pipeline wins over a software write in the same cycle.
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      st.FS <= 2'b00;
      st.VS <= 2'b00;
    end else begin
      if (fs_dirty)
        st.FS <= CTX_DIRTY;
      else if (sw_write)
        st.FS <= (alias_wen ? alias_wdata[MS_FS +: 2] : 2'b00)
               | (csr_wen ? csr_wdata[MS_FS +: 2] : 2'b00);
      if (vs_dirty)
        st.VS <= CTX_DIRTY;
      else if (sw_write)
        st.VS <= (alias_wen ? alias_wdata[MS_VS +: 2] : 2'b00)
               | (csr_wen ? csr_wdata[MS_VS +: 2] : 2'b00);
    end
  end

  // ---- Memory-privilege modifiers: MPRV, SUM, MXR -----------------------------
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      st.MPRV <= 1'b0;
      st.SUM  <= 1'b0;
      st.MXR  <= 1'b0;
    end else begin
      if (csr_wen | any_ret)
        st.MPRV <= (ret_d.valid & ret_d.MPRV) | (ret_m.valid & ret_m.MPRV)
                 | (ret_mn.valid & ret_mn.MPRV) | (ret_s.valid & ret_s.MPRV)
                 | (csr_wen & csr_wdata[MS_MPRV]);
      if (sw_write) begin
        st.SUM <= (alias_wen & alias_wdata[MS_SUM]) | (csr_wen & csr_wdata[MS_SUM]);
        st.MXR <= (alias_wen & alias_wdata[MS_MXR]) | (csr_wen & csr_wdata[MS_MXR]);
      end
    end
  end

  // ---- Virtualisation traps: TVM, TW, TSR (mstatus only) ----------------------
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      st.TVM <= 1'b0;
      st.TW  <= 1'b0;
      st.TSR <= 1'b0;
    end else if (csr_wen) begin
      st.TVM <= csr_wdata[MS_TVM];
      st.TW  <= csr_wdata[MS_TW];
      st.TSR <= csr_wdata[MS_TSR];
    end
  end

  // ---- Double-trap bits: SDT, MDT ---------------------------------------------
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      st.SDT <= 1'b0;
      st.MDT <= 1'b1;
    end else begin
      if (sdt_write)
        st.SDT <= (trap_hs.valid & trap_hs.SDT) | (ret_d.valid & ret_d.SDT)
                | (ret_m.valid & ret_m.SDT) | (ret_mn.valid & ret_mn.SDT)
                | (ret_s.valid & ret_s.SDT) | (alias_wen & alias_wdata[MS_SDT])
                | (csr_wen & csr_wdata[MS_SDT]);
      if (csr_wen | trap_m.valid | any_ret)
        st.MDT <= (trap_m.valid & trap_m.MDT) | (ret_d.valid & ret_d.MDT)
                | (ret_m.valid & ret_m.MDT) | (ret_mn.valid & ret_mn.MDT)
                | (ret_s.valid & ret_s.MDT) | (csr_wen & csr_wdata[MS_MDT]);
    end
  end

  // ---- Read views -------------------------------------------------------------
  assign sd          = (st.FS == CTX_DIRTY) | (st.VS == CTX_DIRTY);
  assign sstatus_sdt = st.SDT & menvcfg_dte;

  always_comb begin
    mstatus_rdata              = 64'h0;
    mstatus_rdata[MS_SIE]      = st.SIE;
    mstatus_rdata[MS_MIE]      = st.MIE;
    mstatus_rdata[MS_SPIE]     = st.SPIE;
    mstatus_rdata[MS_MPIE]     = st.MPIE;
    mstatus_rdata[MS_SPP]      = st.SPP;
    mstatus_rdata[MS_VS +: 2]  = st.VS;
    mstatus_rdata[MS_MPP +: 2] = st.MPP;
    mstatus_rdata[MS_FS +: 2]  = st.FS;
    mstatus_rdata[MS_MPRV]     = st.MPRV;
    mstatus_rdata[MS_SUM]      = st.SUM;
    mstatus_rdata[MS_MXR]      = st.MXR;
    mstatus_rdata[MS_TVM]      = st.TVM;
    mstatus_rdata[MS_TW]       = st.TW;
    mstatus_rdata[MS_TSR]      = st.TSR;
    mstatus_rdata[MS_SDT]      = st.SDT;
    mstatus_rdata[MS_UXL +: 2] = XLEN_64;
    mstatus_rdata[MS_SXL +: 2] = XLEN_64;
    mstatus_rdata[MS_GVA]      = st.GVA;
    mstatus_rdata[MS_MPV]      = st.MPV;
    mstatus_rdata[MS_MDT]      = st.MDT;
    mstatus_rdata[MS_SD]       = sd;
  end

  // sstatus: the S-visible subset; SDT masked by DTE.
  always_comb begin
    sstatus_rdata              = 64'h0;
    sstatus_rdata[MS_SIE]      = st.SIE;
    sstatus_rdata[MS_SPIE]     = st.SPIE;
    sstatus_rdata[MS_SPP]      = st.SPP;
    sstatus_rdata[MS_VS +: 2]  = st.VS;
    sstatus_rdata[MS_FS +: 2]  = st.FS;
    sstatus_rdata[MS_SUM]      = st.SUM;
    sstatus_rdata[MS_MXR]      = st.MXR;
    sstatus_rdata[MS_SDT]      = sstatus_sdt;
    sstatus_rdata[MS_UXL +: 2] = XLEN_64;
    sstatus_rdata[MS_SD]       = sd;
  end
endmodule

module MStatusModule (
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SIE,
  output        regOut_MIE,
  output        regOut_SPIE,
  output        regOut_MPIE,
  output        regOut_SPP,
  output [1:0]  regOut_VS,
  output [1:0]  regOut_MPP,
  output [1:0]  regOut_FS,
  output        regOut_MPRV,
  output        regOut_SUM,
  output        regOut_MXR,
  output        regOut_TVM,
  output        regOut_TW,
  output        regOut_TSR,
  output        regOut_SDT,
  output        regOut_GVA,
  output        regOut_MPV,
  output        regOut_MDT,
  input         trapToM_mstatus_valid,
  input         trapToM_mstatus_bits_MIE,
  input         trapToM_mstatus_bits_MPIE,
  input  [1:0]  trapToM_mstatus_bits_MPP,
  input         trapToM_mstatus_bits_GVA,
  input         trapToM_mstatus_bits_MPV,
  input         trapToM_mstatus_bits_MDT,
  input         trapToHS_mstatus_valid,
  input         trapToHS_mstatus_bits_SIE,
  input         trapToHS_mstatus_bits_SPIE,
  input         trapToHS_mstatus_bits_SPP,
  input         trapToHS_mstatus_bits_SDT,
  input         retFromD_mstatus_valid,
  input         retFromD_mstatus_bits_MPRV,
  input         retFromD_mstatus_bits_SDT,
  input         retFromD_mstatus_bits_MDT,
  input         retFromM_mstatus_valid,
  input         retFromM_mstatus_bits_MIE,
  input         retFromM_mstatus_bits_MPIE,
  input  [1:0]  retFromM_mstatus_bits_MPP,
  input         retFromM_mstatus_bits_MPRV,
  input         retFromM_mstatus_bits_SDT,
  input         retFromM_mstatus_bits_MPV,
  input         retFromM_mstatus_bits_MDT,
  input         retFromMN_mstatus_valid,
  input         retFromMN_mstatus_bits_MPRV,
  input         retFromMN_mstatus_bits_SDT,
  input         retFromMN_mstatus_bits_MDT,
  input         retFromS_mstatus_valid,
  input         retFromS_mstatus_bits_SIE,
  input         retFromS_mstatus_bits_SPIE,
  input         retFromS_mstatus_bits_SPP,
  input         retFromS_mstatus_bits_MPRV,
  input         retFromS_mstatus_bits_SDT,
  input         retFromS_mstatus_bits_MDT,
  input         robCommit_fsDirty,
  input         robCommit_vsDirty,
  input         robCommit_vstart_valid,
  input  [6:0]  robCommit_vstart_bits,
  input         writeFCSR,
  input         writeVCSR,
  input         menvcfg_DTE,
  output        sstatus_SIE,
  output        sstatus_SPIE,
  output        sstatus_SPP,
  output [1:0]  sstatus_VS,
  output [1:0]  sstatus_FS,
  output        sstatus_SUM,
  output        sstatus_MXR,
  output        sstatus_SDT,
  output        sstatus_SD,
  output [63:0] sstatusRdata,
  input         wAliasSstatus_wen,
  input  [63:0] wAliasSstatus_wdata
);
  mstatus_pkg::mstatus_fields_t fields;
  logic                         sd;
  logic                         sstatus_sdt_view;

  xs_MStatusModule_core u_core (
    .clk          (clock),
    .rst          (reset),
    .csr_wen      (w_wen),
    .csr_wdata    (w_wdata),
    .alias_wen    (wAliasSstatus_wen),
    .alias_wdata  (wAliasSstatus_wdata),
    .trap_m       ('{valid: trapToM_mstatus_valid,
                     MIE:   trapToM_mstatus_bits_MIE,
                     MPIE:  trapToM_mstatus_bits_MPIE,
                     MPP:   trapToM_mstatus_bits_MPP,
                     GVA:   trapToM_mstatus_bits_GVA,
                     MPV:   trapToM_mstatus_bits_MPV,
                     MDT:   trapToM_mstatus_bits_MDT}),
    .trap_hs      ('{valid: trapToHS_mstatus_valid,
                     SIE:   trapToHS_mstatus_bits_SIE,
                     SPIE:  trapToHS_mstatus_bits_SPIE,
                     SPP:   trapToHS_mstatus_bits_SPP,
                     SDT:   trapToHS_mstatus_bits_SDT}),
    .ret_d        ('{valid: retFromD_mstatus_valid,
                     MPRV:  retFromD_mstatus_bits_MPRV,
                     SDT:   retFromD_mstatus_bits_SDT,
                     MDT:   retFromD_mstatus_bits_MDT}),
    .ret_m        ('{valid: retFromM_mstatus_valid,
                     MIE:   retFromM_mstatus_bits_MIE,
                     MPIE:  retFromM_mstatus_bits_MPIE,
                     MPP:   retFromM_mstatus_bits_MPP,
                     MPRV:  retFromM_mstatus_bits_MPRV,
                     SDT:   retFromM_mstatus_bits_SDT,
                     MPV:   retFromM_mstatus_bits_MPV,
                     MDT:   retFromM_mstatus_bits_MDT}),
    .ret_mn       ('{valid: retFromMN_mstatus_valid,
                     MPRV:  retFromMN_mstatus_bits_MPRV,
                     SDT:   retFromMN_mstatus_bits_SDT,
                     MDT:   retFromMN_mstatus_bits_MDT}),
    .ret_s        ('{valid: retFromS_mstatus_valid,
                     SIE:   retFromS_mstatus_bits_SIE,
                     SPIE:  retFromS_mstatus_bits_SPIE,
                     SPP:   retFromS_mstatus_bits_SPP,
                     MPRV:  retFromS_mstatus_bits_MPRV,
                     SDT:   retFromS_mstatus_bits_SDT,
                     MDT:   retFromS_mstatus_bits_MDT}),
    // FP state is dirtied by a committing FP instruction or an fcsr write;
    // vector state additionally by a commit that leaves vstart non-zero.
    .fs_dirty     (robCommit_fsDirty | writeFCSR),
    .vs_dirty     (robCommit_vsDirty | writeVCSR
                   | (robCommit_vstart_valid & (|robCommit_vstart_bits))),
    .menvcfg_dte  (menvcfg_DTE),
    .fields       (fields),
    .sd           (sd),
    .sstatus_sdt  (sstatus_sdt_view),
    .mstatus_rdata(rdata),
    .sstatus_rdata(sstatusRdata)
  );

  assign regOut_SIE  = fields.SIE;
  assign regOut_MIE  = fields.MIE;
  assign regOut_SPIE = fields.SPIE;
  assign regOut_MPIE = fields.MPIE;
  assign regOut_SPP  = fields.SPP;
  assign regOut_VS   = fields.VS;
  assign regOut_MPP  = fields.MPP;
  assign regOut_FS   = fields.FS;
  assign regOut_MPRV = fields.MPRV;
  assign regOut_SUM  = fields.SUM;
  assign regOut_MXR  = fields.MXR;
  assign regOut_TVM  = fields.TVM;
  assign regOut_TW   = fields.TW;
  assign regOut_TSR  = fields.TSR;
  assign regOut_SDT  = fields.SDT;
  assign regOut_GVA  = fields.GVA;
  assign regOut_MPV  = fields.MPV;
  assign regOut_MDT  = fields.MDT;

  assign sstatus_SIE  = fields.SIE;
  assign sstatus_SPIE = fields.SPIE;
  assign sstatus_SPP  = fields.SPP;
  assign sstatus_VS   = fields.VS;
  assign sstatus_FS   = fields.FS;
  assign sstatus_SUM  = fields.SUM;
  assign sstatus_MXR  = fields.MXR;
  assign sstatus_SDT  = sstatus_sdt_view;
  assign sstatus_SD   = sd;
endmodule
