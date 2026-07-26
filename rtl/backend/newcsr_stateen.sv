// NewCSR CSR-field primitives: Stateen family (Smstateen extension).
//
// Faithful, readable reimplementation of the golden {M,H,S}stateenN family
// (12 golden modules). The golden firtool output has several structurally
// distinct body shapes; we provide one small primitive per shape and bind the
// golden per-instance port names in thin wrappers (newcsr_stateen_wrappers.sv).
//
// Shape inventory (all transcribed bug-for-bug from golden):
//
//   xs_stateen0        Mstateen0Module : 7 architected fields
//                        {SE0[63],ENVCFG[62],CSRIND[60],AIA[59],IMSIC[58],
//                         CONTEXT[57],C[0]}, async-reset-0, write on w_wen,
//                        rdata packs fields at their bit positions (bit61=0),
//                        regOut = raw register value (NO upstream mask).
//
//   xs_stateen0_masked Hstateen0Module : same 7 fields + async-reset-0, but
//                        every regOut/rdata bit is ANDed with the corresponding
//                        fromMstateen0_* delegation bit (H can only enable what
//                        M has enabled). JVT/FCSR read-as-0 (S-only fields).
//
//   xs_stateen_se      Mstateen{1,2,3}Module : single SE field at w_wdata[63],
//                        async-reset-0, rdata = {SE,63'h0}, regOut = raw SE.
//
//   xs_stateen_se_masked Hstateen{1,2,3}Module : single SE field at w_wdata[63],
//                        NO reset (golden `always @(posedge clock)` only — the
//                        register has no reset value), regOut/rdata masked with
//                        fromMstateenN_SE.
//
// xs_sstateen0        Sstateen0Module : single reg_C, async-reset-0, with a
//                        privState_V delegation mux (see below). 32b rdata.
//
// The constant-zero Sstateen{1,2,3}Module are implemented directly in their
// wrappers (newcsr_stateen_wrappers.sv) since they carry no register/logic.

// ---------------------------------------------------------------------------
// Mstateen0Module core: 7 fields, async reset, unmasked read/regOut.
// ---------------------------------------------------------------------------
module xs_stateen0 (
    input         clock,
    input         reset,
    input         w_wen,
    input  [63:0] w_wdata,
    output [63:0] rdata,
    output        regOut_SE0,
    output        regOut_ENVCFG,
    output        regOut_CSRIND,
    output        regOut_AIA,
    output        regOut_IMSIC,
    output        regOut_CONTEXT,
    output        regOut_C
);

  reg reg_SE0;
  reg reg_ENVCFG;
  reg reg_CSRIND;
  reg reg_AIA;
  reg reg_IMSIC;
  reg reg_CONTEXT;
  reg reg_C;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_SE0     <= 1'h0;
      reg_ENVCFG  <= 1'h0;
      reg_CSRIND  <= 1'h0;
      reg_AIA     <= 1'h0;
      reg_IMSIC   <= 1'h0;
      reg_CONTEXT <= 1'h0;
      reg_C       <= 1'h0;
    end
    else if (w_wen) begin
      reg_SE0     <= w_wdata[63];
      reg_ENVCFG  <= w_wdata[62];
      reg_CSRIND  <= w_wdata[60];
      reg_AIA     <= w_wdata[59];
      reg_IMSIC   <= w_wdata[58];
      reg_CONTEXT <= w_wdata[57];
      reg_C       <= w_wdata[0];
    end
  end

  assign rdata =
    {reg_SE0, reg_ENVCFG, 1'h0, reg_CSRIND, reg_AIA, reg_IMSIC, reg_CONTEXT,
     56'h0, reg_C};
  assign regOut_SE0     = reg_SE0;
  assign regOut_ENVCFG  = reg_ENVCFG;
  assign regOut_CSRIND  = reg_CSRIND;
  assign regOut_AIA     = reg_AIA;
  assign regOut_IMSIC   = reg_IMSIC;
  assign regOut_CONTEXT = reg_CONTEXT;
  assign regOut_C       = reg_C;

endmodule

// ---------------------------------------------------------------------------
// Hstateen0Module core: 7 fields, async reset, read/regOut masked by
// fromMstateen0_* delegation bits. JVT/FCSR read-as-0.
// ---------------------------------------------------------------------------
module xs_stateen0_masked (
    input         clock,
    input         reset,
    input         w_wen,
    input  [63:0] w_wdata,
    output [63:0] rdata,
    output        regOut_JVT,
    output        regOut_FCSR,
    output        regOut_C,
    output        regOut_SE0,
    output        regOut_ENVCFG,
    output        regOut_CSRIND,
    output        regOut_AIA,
    output        regOut_IMSIC,
    output        regOut_CONTEXT,
    input         fromMstateen0_SE0,
    input         fromMstateen0_ENVCFG,
    input         fromMstateen0_CSRIND,
    input         fromMstateen0_AIA,
    input         fromMstateen0_IMSIC,
    input         fromMstateen0_CONTEXT,
    input         fromMstateen0_C
);

  reg reg_C;
  reg reg_SE0;
  reg reg_ENVCFG;
  reg reg_CSRIND;
  reg reg_AIA;
  reg reg_IMSIC;
  reg reg_CONTEXT;

  wire m_C       = reg_C       & fromMstateen0_C;
  wire m_SE0     = reg_SE0     & fromMstateen0_SE0;
  wire m_ENVCFG  = reg_ENVCFG  & fromMstateen0_ENVCFG;
  wire m_CSRIND  = reg_CSRIND  & fromMstateen0_CSRIND;
  wire m_AIA     = reg_AIA     & fromMstateen0_AIA;
  wire m_IMSIC   = reg_IMSIC   & fromMstateen0_IMSIC;
  wire m_CONTEXT = reg_CONTEXT & fromMstateen0_CONTEXT;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_C       <= 1'h0;
      reg_SE0     <= 1'h0;
      reg_ENVCFG  <= 1'h0;
      reg_CSRIND  <= 1'h0;
      reg_AIA     <= 1'h0;
      reg_IMSIC   <= 1'h0;
      reg_CONTEXT <= 1'h0;
    end
    else if (w_wen) begin
      reg_C       <= w_wdata[0];
      reg_SE0     <= w_wdata[63];
      reg_ENVCFG  <= w_wdata[62];
      reg_CSRIND  <= w_wdata[60];
      reg_AIA     <= w_wdata[59];
      reg_IMSIC   <= w_wdata[58];
      reg_CONTEXT <= w_wdata[57];
    end
  end

  assign rdata =
    {m_SE0, m_ENVCFG, 1'h0, m_CSRIND, m_AIA, m_IMSIC, m_CONTEXT, 56'h0, m_C};
  assign regOut_JVT     = 1'h0;
  assign regOut_FCSR    = 1'h0;
  assign regOut_C       = m_C;
  assign regOut_SE0     = m_SE0;
  assign regOut_ENVCFG  = m_ENVCFG;
  assign regOut_CSRIND  = m_CSRIND;
  assign regOut_AIA     = m_AIA;
  assign regOut_IMSIC   = m_IMSIC;
  assign regOut_CONTEXT = m_CONTEXT;

endmodule

// ---------------------------------------------------------------------------
// Mstateen{1,2,3}Module core: single SE field, async reset, unmasked.
// ---------------------------------------------------------------------------
module xs_stateen_se (
    input         clock,
    input         reset,
    input         w_wen,
    input  [63:0] w_wdata,
    output [63:0] rdata,
    output        regOut_SE
);

  reg reg_SE;

  always @(posedge clock or posedge reset) begin
    if (reset)
      reg_SE <= 1'h0;
    else if (w_wen)
      reg_SE <= w_wdata[63];
  end

  assign rdata     = {reg_SE, 63'h0};
  assign regOut_SE = reg_SE;

endmodule

// ---------------------------------------------------------------------------
// Hstateen{1,2,3}Module core: single SE field, NO reset (golden register has
// no reset value), read/regOut masked by fromMstateenN_SE.
// ---------------------------------------------------------------------------
module xs_stateen_se_masked (
    input         clock,
    input         w_wen,
    input  [63:0] w_wdata,
    output [63:0] rdata,
    output        regOut_SE,
    input         fromMstateen_SE
);

  reg reg_SE;

  wire m_SE = reg_SE & fromMstateen_SE;

  always @(posedge clock) begin
    if (w_wen)
      reg_SE <= w_wdata[63];
  end

  assign rdata     = {m_SE, 63'h0};
  assign regOut_SE = m_SE;

endmodule

// ---------------------------------------------------------------------------
// Sstateen0Module core: single reg_C + privState_V delegation mux.
//   _GEN = (V ? {Hstateen0.JVT,FCSR,C} : {2'h0, Mstateen0.C}) & {2'h0, reg_C}
// JVT/FCSR are S-only fields with no S-mode storage; only the low (C) lane is
// architected by reg_C. rdata = {29'h0,_GEN}; regOut_{JVT,FCSR,C} = _GEN[2:0].
// ---------------------------------------------------------------------------
module xs_sstateen0 (
    input         clock,
    input         reset,
    input         w_wen,
    input  [63:0] w_wdata,
    output [31:0] rdata,
    output        regOut_JVT,
    output        regOut_FCSR,
    output        regOut_C,
    input         fromMstateen0_C,
    input         fromHstateen0_JVT,
    input         fromHstateen0_FCSR,
    input         fromHstateen0_C,
    input         privState_V
);

  reg        reg_C;
  wire [2:0] _GEN =
    (privState_V ? {fromHstateen0_JVT, fromHstateen0_FCSR, fromHstateen0_C}
                 : {2'h0, fromMstateen0_C}) & {2'h0, reg_C};

  always @(posedge clock or posedge reset) begin
    if (reset)
      reg_C <= 1'h0;
    else if (w_wen)
      reg_C <= w_wdata[0];
  end

  assign rdata       = {29'h0, _GEN};
  assign regOut_JVT  = _GEN[2];
  assign regOut_FCSR = _GEN[1];
  assign regOut_C    = _GEN[0];

endmodule
