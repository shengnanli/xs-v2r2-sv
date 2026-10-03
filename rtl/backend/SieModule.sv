// SieModule.sv — supervisor interrupt-enable CSR (sie) inside NewCSR.
// sie is not one register but a per-interrupt *view* chosen by mideleg/mvien
// (priv. spec 3.1.9 + AIA 5.3):
//   mideleg[i]=1              -> sie[i] is an alias of mie[i]; a write is
//                                forwarded to mie through the toMie sideband.
//   mideleg[i]=0, mvien[i]=1  -> sie[i] is its own writable flop kept here
//                                (interrupt i is a virtual one, filtered by M).
//   mideleg[i]=0, mvien[i]=0  -> read-only zero.
// Only the HS group (1/5/9) and the locals (13..63) are visible; M, VS and
// SGEI positions read zero.  vsie can also write the local flops (fromVSie:
// the guest's vsie aliases sie when hideleg=1 and mideleg=0).
// Config facts visible only in golden (KunminghuV2): mideleg is writable at
// 1/5/9/13 only (VS+SGEI hard 1, the rest hard 0); mvien is writable at
// 1/9/14..63.  So flops exist for 1, 9 and 14..63 only: STIE (5) is RO in the
// bundle, and LCOFIE (13) can never be "own" because mvien[13] is hard 0.
// Reset: asynchronous, all flops 0.
module xs_SieModule_core
  import csr_irq_pkg::*;
(
  input  logic     clk,
  input  logic     rst,
  input  logic     wen,            // CSR write strobe
  input  irq_vec_t wdata,          // CSR write data
  input  irq_vec_t mideleg,        // 1 = interrupt delegated to S
  input  irq_vec_t mie,            // machine enables (alias source)
  input  irq_vec_t mvien,          // 1 = virtual interrupt for S level
  input  irq_vec_t vsie_wr_valid,  // vsie-originated write, per interrupt
  input  irq_vec_t vsie_wr_bits,
  output irq_vec_t value,          // sie read data (rdata and regOut)
  output irq_vec_t to_mie_valid,   // forwarded write to mie, per interrupt
  output irq_vec_t to_mie_bits
);
  // Which flops exist (see header) and which sideband fields are writable.
  localparam irq_vec_t OWN_FLOP_MASK = (64'h1 << IRQ_SSI) | (64'h1 << IRQ_SEI) | IRQ_LC14UP_MASK;
  localparam irq_vec_t TO_MIE_RW     = IRQ_HS_MASK | IRQ_LOCAL_MASK;   // SieToMie
  localparam irq_vec_t FROM_VSIE_RW  = IRQ_VS_MASK | IRQ_LOCAL_MASK;   // VSieToSie

  irq_vec_t mie_is_alias;  // bit comes from mie
  irq_vec_t uses_own_bit;  // bit comes from the flop below
  irq_vec_t own_bits;      // the flops (0 where no flop exists)

  assign mie_is_alias = mideleg;
  assign uses_own_bit = ~mideleg & mvien;

  // ---- Read view -----------------------------------------------------------
  assign value = ((mie_is_alias & mie) | (uses_own_bit & own_bits)) & IRQ_S_VIEW_MASK;

  // ---- Write forwarded to mie (aliased bits) -------------------------------
  // bits is gated by valid, exactly as the Scala `&<` does.
  assign to_mie_valid = {64{wen}} & mie_is_alias & TO_MIE_RW;
  assign to_mie_bits  = to_mie_valid & wdata;

  // ---- Own flops -----------------------------------------------------------
  // Two writers, a CSR write to sie and a write arriving from vsie.  Both are
  // qualified by uses_own_bit.  The data is a one-hot mux written as an OR, so
  // if both fire in the same cycle the result is the OR of the two (bug-for-bug
  // with the golden Mux1H).
  for (genvar i = 0; i < 64; i++) begin : g_bit
    if (OWN_FLOP_MASK[i]) begin : g_flop
      logic q;
      logic csr_write;
      logic vsie_write;
      assign csr_write  = wen & uses_own_bit[i];
      assign vsie_write = vsie_wr_valid[i] & uses_own_bit[i] & FROM_VSIE_RW[i];
      always_ff @(posedge clk or posedge rst) begin
        if (rst)
          q <= 1'b0;
        else if (csr_write | vsie_write)
          q <= (wen & wdata[i]) | (vsie_wr_valid[i] & vsie_wr_bits[i]);
      end
      assign own_bits[i] = q;
    end else begin : g_none
      assign own_bits[i] = 1'b0;
    end
  end
endmodule

// BEGIN GENERATED(csr-irq-handle)
module SieModule (
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SSIE,
  output        regOut_STIE,
  output        regOut_SEIE,
  output        regOut_LCOFIE,
  output        regOut_LC14IE,
  output        regOut_LC15IE,
  output        regOut_LC16IE,
  output        regOut_LC17IE,
  output        regOut_LC18IE,
  output        regOut_LC19IE,
  output        regOut_LC20IE,
  output        regOut_LC21IE,
  output        regOut_LC22IE,
  output        regOut_LC23IE,
  output        regOut_LC24IE,
  output        regOut_LC25IE,
  output        regOut_LC26IE,
  output        regOut_LC27IE,
  output        regOut_LC28IE,
  output        regOut_LC29IE,
  output        regOut_LC30IE,
  output        regOut_LC31IE,
  output        regOut_LC32IE,
  output        regOut_LC33IE,
  output        regOut_LC34IE,
  output        regOut_LPRASEIE,
  output        regOut_LC36IE,
  output        regOut_LC37IE,
  output        regOut_LC38IE,
  output        regOut_LC39IE,
  output        regOut_LC40IE,
  output        regOut_LC41IE,
  output        regOut_LC42IE,
  output        regOut_HPRASEIE,
  output        regOut_LC44IE,
  output        regOut_LC45IE,
  output        regOut_LC46IE,
  output        regOut_LC47IE,
  output        regOut_LC48IE,
  output        regOut_LC49IE,
  output        regOut_LC50IE,
  output        regOut_LC51IE,
  output        regOut_LC52IE,
  output        regOut_LC53IE,
  output        regOut_LC54IE,
  output        regOut_LC55IE,
  output        regOut_LC56IE,
  output        regOut_LC57IE,
  output        regOut_LC58IE,
  output        regOut_LC59IE,
  output        regOut_LC60IE,
  output        regOut_LC61IE,
  output        regOut_LC62IE,
  output        regOut_LC63IE,
  input         mideleg_SSI,
  input         mideleg_STI,
  input         mideleg_SEI,
  input         mideleg_LCOFI,
  input         mie_SSIE,
  input         mie_VSSIE,
  input         mie_MSIE,
  input         mie_STIE,
  input         mie_VSTIE,
  input         mie_MTIE,
  input         mie_SEIE,
  input         mie_VSEIE,
  input         mie_MEIE,
  input         mie_SGEIE,
  input         mie_LCOFIE,
  input         mvien_SSIE,
  input         mvien_SEIE,
  input         mvien_LC14IE,
  input         mvien_LC15IE,
  input         mvien_LC16IE,
  input         mvien_LC17IE,
  input         mvien_LC18IE,
  input         mvien_LC19IE,
  input         mvien_LC20IE,
  input         mvien_LC21IE,
  input         mvien_LC22IE,
  input         mvien_LC23IE,
  input         mvien_LC24IE,
  input         mvien_LC25IE,
  input         mvien_LC26IE,
  input         mvien_LC27IE,
  input         mvien_LC28IE,
  input         mvien_LC29IE,
  input         mvien_LC30IE,
  input         mvien_LC31IE,
  input         mvien_LC32IE,
  input         mvien_LC33IE,
  input         mvien_LC34IE,
  input         mvien_LPRASEIE,
  input         mvien_LC36IE,
  input         mvien_LC37IE,
  input         mvien_LC38IE,
  input         mvien_LC39IE,
  input         mvien_LC40IE,
  input         mvien_LC41IE,
  input         mvien_LC42IE,
  input         mvien_HPRASEIE,
  input         mvien_LC44IE,
  input         mvien_LC45IE,
  input         mvien_LC46IE,
  input         mvien_LC47IE,
  input         mvien_LC48IE,
  input         mvien_LC49IE,
  input         mvien_LC50IE,
  input         mvien_LC51IE,
  input         mvien_LC52IE,
  input         mvien_LC53IE,
  input         mvien_LC54IE,
  input         mvien_LC55IE,
  input         mvien_LC56IE,
  input         mvien_LC57IE,
  input         mvien_LC58IE,
  input         mvien_LC59IE,
  input         mvien_LC60IE,
  input         mvien_LC61IE,
  input         mvien_LC62IE,
  input         mvien_LC63IE,
  output        toMie_SSIE_valid,
  output        toMie_SSIE_bits,
  output        toMie_STIE_valid,
  output        toMie_STIE_bits,
  output        toMie_SEIE_valid,
  output        toMie_SEIE_bits,
  output        toMie_LCOFIE_valid,
  output        toMie_LCOFIE_bits,
  input         fromVSie_VSSIE_valid,
  input         fromVSie_VSSIE_bits,
  input         fromVSie_VSTIE_valid,
  input         fromVSie_VSTIE_bits,
  input         fromVSie_VSEIE_valid,
  input         fromVSie_VSEIE_bits,
  input         fromVSie_LCOFIE_valid,
  input         fromVSie_LCOFIE_bits,
  input         fromVSie_LC14IE_valid,
  input         fromVSie_LC14IE_bits,
  input         fromVSie_LC15IE_valid,
  input         fromVSie_LC15IE_bits,
  input         fromVSie_LC16IE_valid,
  input         fromVSie_LC16IE_bits,
  input         fromVSie_LC17IE_valid,
  input         fromVSie_LC17IE_bits,
  input         fromVSie_LC18IE_valid,
  input         fromVSie_LC18IE_bits,
  input         fromVSie_LC19IE_valid,
  input         fromVSie_LC19IE_bits,
  input         fromVSie_LC20IE_valid,
  input         fromVSie_LC20IE_bits,
  input         fromVSie_LC21IE_valid,
  input         fromVSie_LC21IE_bits,
  input         fromVSie_LC22IE_valid,
  input         fromVSie_LC22IE_bits,
  input         fromVSie_LC23IE_valid,
  input         fromVSie_LC23IE_bits,
  input         fromVSie_LC24IE_valid,
  input         fromVSie_LC24IE_bits,
  input         fromVSie_LC25IE_valid,
  input         fromVSie_LC25IE_bits,
  input         fromVSie_LC26IE_valid,
  input         fromVSie_LC26IE_bits,
  input         fromVSie_LC27IE_valid,
  input         fromVSie_LC27IE_bits,
  input         fromVSie_LC28IE_valid,
  input         fromVSie_LC28IE_bits,
  input         fromVSie_LC29IE_valid,
  input         fromVSie_LC29IE_bits,
  input         fromVSie_LC30IE_valid,
  input         fromVSie_LC30IE_bits,
  input         fromVSie_LC31IE_valid,
  input         fromVSie_LC31IE_bits,
  input         fromVSie_LC32IE_valid,
  input         fromVSie_LC32IE_bits,
  input         fromVSie_LC33IE_valid,
  input         fromVSie_LC33IE_bits,
  input         fromVSie_LC34IE_valid,
  input         fromVSie_LC34IE_bits,
  input         fromVSie_LPRASEIE_valid,
  input         fromVSie_LPRASEIE_bits,
  input         fromVSie_LC36IE_valid,
  input         fromVSie_LC36IE_bits,
  input         fromVSie_LC37IE_valid,
  input         fromVSie_LC37IE_bits,
  input         fromVSie_LC38IE_valid,
  input         fromVSie_LC38IE_bits,
  input         fromVSie_LC39IE_valid,
  input         fromVSie_LC39IE_bits,
  input         fromVSie_LC40IE_valid,
  input         fromVSie_LC40IE_bits,
  input         fromVSie_LC41IE_valid,
  input         fromVSie_LC41IE_bits,
  input         fromVSie_LC42IE_valid,
  input         fromVSie_LC42IE_bits,
  input         fromVSie_HPRASEIE_valid,
  input         fromVSie_HPRASEIE_bits,
  input         fromVSie_LC44IE_valid,
  input         fromVSie_LC44IE_bits,
  input         fromVSie_LC45IE_valid,
  input         fromVSie_LC45IE_bits,
  input         fromVSie_LC46IE_valid,
  input         fromVSie_LC46IE_bits,
  input         fromVSie_LC47IE_valid,
  input         fromVSie_LC47IE_bits,
  input         fromVSie_LC48IE_valid,
  input         fromVSie_LC48IE_bits,
  input         fromVSie_LC49IE_valid,
  input         fromVSie_LC49IE_bits,
  input         fromVSie_LC50IE_valid,
  input         fromVSie_LC50IE_bits,
  input         fromVSie_LC51IE_valid,
  input         fromVSie_LC51IE_bits,
  input         fromVSie_LC52IE_valid,
  input         fromVSie_LC52IE_bits,
  input         fromVSie_LC53IE_valid,
  input         fromVSie_LC53IE_bits,
  input         fromVSie_LC54IE_valid,
  input         fromVSie_LC54IE_bits,
  input         fromVSie_LC55IE_valid,
  input         fromVSie_LC55IE_bits,
  input         fromVSie_LC56IE_valid,
  input         fromVSie_LC56IE_bits,
  input         fromVSie_LC57IE_valid,
  input         fromVSie_LC57IE_bits,
  input         fromVSie_LC58IE_valid,
  input         fromVSie_LC58IE_bits,
  input         fromVSie_LC59IE_valid,
  input         fromVSie_LC59IE_bits,
  input         fromVSie_LC60IE_valid,
  input         fromVSie_LC60IE_bits,
  input         fromVSie_LC61IE_valid,
  input         fromVSie_LC61IE_bits,
  input         fromVSie_LC62IE_valid,
  input         fromVSie_LC62IE_bits,
  input         fromVSie_LC63IE_valid,
  input         fromVSie_LC63IE_bits
);
  // Inputs gathered by interrupt number.  A bit without a golden port is a
  // constant that firtool folded away; the default below restates it.
  logic [63:0] mideleg;
  always_comb begin
    mideleg = 64'h0000_0000_0000_1444;
    mideleg[1] = mideleg_SSI;
    mideleg[5] = mideleg_STI;
    mideleg[9] = mideleg_SEI;
    mideleg[13] = mideleg_LCOFI;
  end
  logic [63:0] mie;
  always_comb begin
    mie = 64'h0000_0000_0000_0000;
    mie[1] = mie_SSIE;
    mie[2] = mie_VSSIE;
    mie[3] = mie_MSIE;
    mie[5] = mie_STIE;
    mie[6] = mie_VSTIE;
    mie[7] = mie_MTIE;
    mie[9] = mie_SEIE;
    mie[10] = mie_VSEIE;
    mie[11] = mie_MEIE;
    mie[12] = mie_SGEIE;
    mie[13] = mie_LCOFIE;
  end
  logic [63:0] mvien;
  always_comb begin
    mvien = 64'h0000_0000_0000_0000;
    mvien[1] = mvien_SSIE;
    mvien[9] = mvien_SEIE;
    mvien[14] = mvien_LC14IE;
    mvien[15] = mvien_LC15IE;
    mvien[16] = mvien_LC16IE;
    mvien[17] = mvien_LC17IE;
    mvien[18] = mvien_LC18IE;
    mvien[19] = mvien_LC19IE;
    mvien[20] = mvien_LC20IE;
    mvien[21] = mvien_LC21IE;
    mvien[22] = mvien_LC22IE;
    mvien[23] = mvien_LC23IE;
    mvien[24] = mvien_LC24IE;
    mvien[25] = mvien_LC25IE;
    mvien[26] = mvien_LC26IE;
    mvien[27] = mvien_LC27IE;
    mvien[28] = mvien_LC28IE;
    mvien[29] = mvien_LC29IE;
    mvien[30] = mvien_LC30IE;
    mvien[31] = mvien_LC31IE;
    mvien[32] = mvien_LC32IE;
    mvien[33] = mvien_LC33IE;
    mvien[34] = mvien_LC34IE;
    mvien[35] = mvien_LPRASEIE;
    mvien[36] = mvien_LC36IE;
    mvien[37] = mvien_LC37IE;
    mvien[38] = mvien_LC38IE;
    mvien[39] = mvien_LC39IE;
    mvien[40] = mvien_LC40IE;
    mvien[41] = mvien_LC41IE;
    mvien[42] = mvien_LC42IE;
    mvien[43] = mvien_HPRASEIE;
    mvien[44] = mvien_LC44IE;
    mvien[45] = mvien_LC45IE;
    mvien[46] = mvien_LC46IE;
    mvien[47] = mvien_LC47IE;
    mvien[48] = mvien_LC48IE;
    mvien[49] = mvien_LC49IE;
    mvien[50] = mvien_LC50IE;
    mvien[51] = mvien_LC51IE;
    mvien[52] = mvien_LC52IE;
    mvien[53] = mvien_LC53IE;
    mvien[54] = mvien_LC54IE;
    mvien[55] = mvien_LC55IE;
    mvien[56] = mvien_LC56IE;
    mvien[57] = mvien_LC57IE;
    mvien[58] = mvien_LC58IE;
    mvien[59] = mvien_LC59IE;
    mvien[60] = mvien_LC60IE;
    mvien[61] = mvien_LC61IE;
    mvien[62] = mvien_LC62IE;
    mvien[63] = mvien_LC63IE;
  end
  logic [63:0] vsie_wr_valid;
  always_comb begin
    vsie_wr_valid = 64'h0000_0000_0000_0000;
    vsie_wr_valid[2] = fromVSie_VSSIE_valid;
    vsie_wr_valid[6] = fromVSie_VSTIE_valid;
    vsie_wr_valid[10] = fromVSie_VSEIE_valid;
    vsie_wr_valid[13] = fromVSie_LCOFIE_valid;
    vsie_wr_valid[14] = fromVSie_LC14IE_valid;
    vsie_wr_valid[15] = fromVSie_LC15IE_valid;
    vsie_wr_valid[16] = fromVSie_LC16IE_valid;
    vsie_wr_valid[17] = fromVSie_LC17IE_valid;
    vsie_wr_valid[18] = fromVSie_LC18IE_valid;
    vsie_wr_valid[19] = fromVSie_LC19IE_valid;
    vsie_wr_valid[20] = fromVSie_LC20IE_valid;
    vsie_wr_valid[21] = fromVSie_LC21IE_valid;
    vsie_wr_valid[22] = fromVSie_LC22IE_valid;
    vsie_wr_valid[23] = fromVSie_LC23IE_valid;
    vsie_wr_valid[24] = fromVSie_LC24IE_valid;
    vsie_wr_valid[25] = fromVSie_LC25IE_valid;
    vsie_wr_valid[26] = fromVSie_LC26IE_valid;
    vsie_wr_valid[27] = fromVSie_LC27IE_valid;
    vsie_wr_valid[28] = fromVSie_LC28IE_valid;
    vsie_wr_valid[29] = fromVSie_LC29IE_valid;
    vsie_wr_valid[30] = fromVSie_LC30IE_valid;
    vsie_wr_valid[31] = fromVSie_LC31IE_valid;
    vsie_wr_valid[32] = fromVSie_LC32IE_valid;
    vsie_wr_valid[33] = fromVSie_LC33IE_valid;
    vsie_wr_valid[34] = fromVSie_LC34IE_valid;
    vsie_wr_valid[35] = fromVSie_LPRASEIE_valid;
    vsie_wr_valid[36] = fromVSie_LC36IE_valid;
    vsie_wr_valid[37] = fromVSie_LC37IE_valid;
    vsie_wr_valid[38] = fromVSie_LC38IE_valid;
    vsie_wr_valid[39] = fromVSie_LC39IE_valid;
    vsie_wr_valid[40] = fromVSie_LC40IE_valid;
    vsie_wr_valid[41] = fromVSie_LC41IE_valid;
    vsie_wr_valid[42] = fromVSie_LC42IE_valid;
    vsie_wr_valid[43] = fromVSie_HPRASEIE_valid;
    vsie_wr_valid[44] = fromVSie_LC44IE_valid;
    vsie_wr_valid[45] = fromVSie_LC45IE_valid;
    vsie_wr_valid[46] = fromVSie_LC46IE_valid;
    vsie_wr_valid[47] = fromVSie_LC47IE_valid;
    vsie_wr_valid[48] = fromVSie_LC48IE_valid;
    vsie_wr_valid[49] = fromVSie_LC49IE_valid;
    vsie_wr_valid[50] = fromVSie_LC50IE_valid;
    vsie_wr_valid[51] = fromVSie_LC51IE_valid;
    vsie_wr_valid[52] = fromVSie_LC52IE_valid;
    vsie_wr_valid[53] = fromVSie_LC53IE_valid;
    vsie_wr_valid[54] = fromVSie_LC54IE_valid;
    vsie_wr_valid[55] = fromVSie_LC55IE_valid;
    vsie_wr_valid[56] = fromVSie_LC56IE_valid;
    vsie_wr_valid[57] = fromVSie_LC57IE_valid;
    vsie_wr_valid[58] = fromVSie_LC58IE_valid;
    vsie_wr_valid[59] = fromVSie_LC59IE_valid;
    vsie_wr_valid[60] = fromVSie_LC60IE_valid;
    vsie_wr_valid[61] = fromVSie_LC61IE_valid;
    vsie_wr_valid[62] = fromVSie_LC62IE_valid;
    vsie_wr_valid[63] = fromVSie_LC63IE_valid;
  end
  logic [63:0] vsie_wr_bits;
  always_comb begin
    vsie_wr_bits = 64'h0000_0000_0000_0000;
    vsie_wr_bits[2] = fromVSie_VSSIE_bits;
    vsie_wr_bits[6] = fromVSie_VSTIE_bits;
    vsie_wr_bits[10] = fromVSie_VSEIE_bits;
    vsie_wr_bits[13] = fromVSie_LCOFIE_bits;
    vsie_wr_bits[14] = fromVSie_LC14IE_bits;
    vsie_wr_bits[15] = fromVSie_LC15IE_bits;
    vsie_wr_bits[16] = fromVSie_LC16IE_bits;
    vsie_wr_bits[17] = fromVSie_LC17IE_bits;
    vsie_wr_bits[18] = fromVSie_LC18IE_bits;
    vsie_wr_bits[19] = fromVSie_LC19IE_bits;
    vsie_wr_bits[20] = fromVSie_LC20IE_bits;
    vsie_wr_bits[21] = fromVSie_LC21IE_bits;
    vsie_wr_bits[22] = fromVSie_LC22IE_bits;
    vsie_wr_bits[23] = fromVSie_LC23IE_bits;
    vsie_wr_bits[24] = fromVSie_LC24IE_bits;
    vsie_wr_bits[25] = fromVSie_LC25IE_bits;
    vsie_wr_bits[26] = fromVSie_LC26IE_bits;
    vsie_wr_bits[27] = fromVSie_LC27IE_bits;
    vsie_wr_bits[28] = fromVSie_LC28IE_bits;
    vsie_wr_bits[29] = fromVSie_LC29IE_bits;
    vsie_wr_bits[30] = fromVSie_LC30IE_bits;
    vsie_wr_bits[31] = fromVSie_LC31IE_bits;
    vsie_wr_bits[32] = fromVSie_LC32IE_bits;
    vsie_wr_bits[33] = fromVSie_LC33IE_bits;
    vsie_wr_bits[34] = fromVSie_LC34IE_bits;
    vsie_wr_bits[35] = fromVSie_LPRASEIE_bits;
    vsie_wr_bits[36] = fromVSie_LC36IE_bits;
    vsie_wr_bits[37] = fromVSie_LC37IE_bits;
    vsie_wr_bits[38] = fromVSie_LC38IE_bits;
    vsie_wr_bits[39] = fromVSie_LC39IE_bits;
    vsie_wr_bits[40] = fromVSie_LC40IE_bits;
    vsie_wr_bits[41] = fromVSie_LC41IE_bits;
    vsie_wr_bits[42] = fromVSie_LC42IE_bits;
    vsie_wr_bits[43] = fromVSie_HPRASEIE_bits;
    vsie_wr_bits[44] = fromVSie_LC44IE_bits;
    vsie_wr_bits[45] = fromVSie_LC45IE_bits;
    vsie_wr_bits[46] = fromVSie_LC46IE_bits;
    vsie_wr_bits[47] = fromVSie_LC47IE_bits;
    vsie_wr_bits[48] = fromVSie_LC48IE_bits;
    vsie_wr_bits[49] = fromVSie_LC49IE_bits;
    vsie_wr_bits[50] = fromVSie_LC50IE_bits;
    vsie_wr_bits[51] = fromVSie_LC51IE_bits;
    vsie_wr_bits[52] = fromVSie_LC52IE_bits;
    vsie_wr_bits[53] = fromVSie_LC53IE_bits;
    vsie_wr_bits[54] = fromVSie_LC54IE_bits;
    vsie_wr_bits[55] = fromVSie_LC55IE_bits;
    vsie_wr_bits[56] = fromVSie_LC56IE_bits;
    vsie_wr_bits[57] = fromVSie_LC57IE_bits;
    vsie_wr_bits[58] = fromVSie_LC58IE_bits;
    vsie_wr_bits[59] = fromVSie_LC59IE_bits;
    vsie_wr_bits[60] = fromVSie_LC60IE_bits;
    vsie_wr_bits[61] = fromVSie_LC61IE_bits;
    vsie_wr_bits[62] = fromVSie_LC62IE_bits;
    vsie_wr_bits[63] = fromVSie_LC63IE_bits;
  end
  logic [63:0] value;
  logic [63:0] to_mie_valid;
  logic [63:0] to_mie_bits;

  xs_SieModule_core u_core (
    .clk           (clock),
    .rst           (reset),
    .wen           (w_wen),
    .wdata         (w_wdata),
    .mideleg       (mideleg),
    .mie           (mie),
    .mvien         (mvien),
    .vsie_wr_valid (vsie_wr_valid),
    .vsie_wr_bits  (vsie_wr_bits),
    .value         (value),
    .to_mie_valid  (to_mie_valid),
    .to_mie_bits   (to_mie_bits)
  );

  // Outputs spread back to one port per interrupt number.
  assign rdata = value;
  assign regOut_SSIE = value[1];
  assign regOut_STIE = value[5];
  assign regOut_SEIE = value[9];
  assign regOut_LCOFIE = value[13];
  assign regOut_LC14IE = value[14];
  assign regOut_LC15IE = value[15];
  assign regOut_LC16IE = value[16];
  assign regOut_LC17IE = value[17];
  assign regOut_LC18IE = value[18];
  assign regOut_LC19IE = value[19];
  assign regOut_LC20IE = value[20];
  assign regOut_LC21IE = value[21];
  assign regOut_LC22IE = value[22];
  assign regOut_LC23IE = value[23];
  assign regOut_LC24IE = value[24];
  assign regOut_LC25IE = value[25];
  assign regOut_LC26IE = value[26];
  assign regOut_LC27IE = value[27];
  assign regOut_LC28IE = value[28];
  assign regOut_LC29IE = value[29];
  assign regOut_LC30IE = value[30];
  assign regOut_LC31IE = value[31];
  assign regOut_LC32IE = value[32];
  assign regOut_LC33IE = value[33];
  assign regOut_LC34IE = value[34];
  assign regOut_LPRASEIE = value[35];
  assign regOut_LC36IE = value[36];
  assign regOut_LC37IE = value[37];
  assign regOut_LC38IE = value[38];
  assign regOut_LC39IE = value[39];
  assign regOut_LC40IE = value[40];
  assign regOut_LC41IE = value[41];
  assign regOut_LC42IE = value[42];
  assign regOut_HPRASEIE = value[43];
  assign regOut_LC44IE = value[44];
  assign regOut_LC45IE = value[45];
  assign regOut_LC46IE = value[46];
  assign regOut_LC47IE = value[47];
  assign regOut_LC48IE = value[48];
  assign regOut_LC49IE = value[49];
  assign regOut_LC50IE = value[50];
  assign regOut_LC51IE = value[51];
  assign regOut_LC52IE = value[52];
  assign regOut_LC53IE = value[53];
  assign regOut_LC54IE = value[54];
  assign regOut_LC55IE = value[55];
  assign regOut_LC56IE = value[56];
  assign regOut_LC57IE = value[57];
  assign regOut_LC58IE = value[58];
  assign regOut_LC59IE = value[59];
  assign regOut_LC60IE = value[60];
  assign regOut_LC61IE = value[61];
  assign regOut_LC62IE = value[62];
  assign regOut_LC63IE = value[63];
  assign toMie_SSIE_valid = to_mie_valid[1];
  assign toMie_STIE_valid = to_mie_valid[5];
  assign toMie_SEIE_valid = to_mie_valid[9];
  assign toMie_LCOFIE_valid = to_mie_valid[13];
  assign toMie_SSIE_bits = to_mie_bits[1];
  assign toMie_STIE_bits = to_mie_bits[5];
  assign toMie_SEIE_bits = to_mie_bits[9];
  assign toMie_LCOFIE_bits = to_mie_bits[13];
endmodule
// END GENERATED
