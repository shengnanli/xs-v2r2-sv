// VSieModule.sv — virtual-supervisor interrupt-enable CSR (vsie) in NewCSR.
// What the guest sees as "sie".  Per interrupt number i the bit is one of
// (priv. spec 18.2.3 hideleg + AIA 6.3.2 hvien):
//   hideleg[i]=1, mideleg[i]=1            -> alias of mie[i]   (write -> toMie)
//   hideleg[i]=1, mideleg[i]=0, mvien[i]  -> alias of sie[i]   (write -> toSie)
//   hideleg[i]=0, hvien[i]=1              -> own flop kept here
//   otherwise                             -> read-only zero
// Position shift: the guest's SSIE/STIE/SEIE (bits 1/5/9) are the VS
// interrupts 2/6/10.  All selection is done in *interrupt-number* space and
// the result is then moved to the supervisor positions with vs_to_s_view();
// write data goes the other way with s_to_vs_wdata().  Locals (13..63) do not
// move.
// Config facts visible only in golden: hvien is writable at 14..63 only, so
// own flops exist exactly there (bit 13 can never be "own"); hideleg is hard 0
// at 14..63 and mideleg hard 1 at the VS bits, so every toSie output folds to
// constant 0 in this configuration — the core still states the general rule.
// Reset: asynchronous, all flops 0.
module xs_VSieModule_core
  import csr_irq_pkg::*;
(
  input  logic     clk,
  input  logic     rst,
  input  logic     wen,            // CSR write strobe
  input  irq_vec_t wdata,          // CSR write data (supervisor positions)
  input  irq_vec_t mideleg,
  input  irq_vec_t hideleg,
  input  irq_vec_t mie,
  input  irq_vec_t sie,
  input  irq_vec_t mvien,
  input  irq_vec_t hvien,
  output irq_vec_t value,          // vsie read data (rdata and regOut)
  output irq_vec_t to_mie_valid,   // indexed by interrupt number
  output irq_vec_t to_mie_bits,
  output irq_vec_t to_sie_valid,
  output irq_vec_t to_sie_bits
);
  localparam irq_vec_t OWN_FLOP_MASK = IRQ_LC14UP_MASK;
  localparam irq_vec_t SIDEBAND_RW   = IRQ_VS_MASK | IRQ_LOCAL_MASK;  // VSieToMie / VSieToSie

  // ---- Source selection, in interrupt-number space -------------------------
  irq_vec_t mie_is_alias;
  irq_vec_t sie_is_alias;
  irq_vec_t uses_own_bit;
  irq_vec_t alias_value;
  irq_vec_t own_bits;      // flops, already at their (unshifted) local position

  assign mie_is_alias = hideleg & mideleg;
  assign sie_is_alias = hideleg & ~mideleg & mvien;
  assign uses_own_bit = ~hideleg & hvien;
  assign alias_value  = (mie_is_alias & mie) | (sie_is_alias & sie);

  // ---- Read view: shift to supervisor positions, then hard-wire ------------
  // The own flops are indexed by the *shifted* position (Scala reg(sNum));
  // for the locals that is the interrupt number itself.
  assign value = (vs_to_s_view(alias_value) | (vs_to_s_view(uses_own_bit) & own_bits))
                 & IRQ_S_VIEW_MASK;

  // ---- Forwarded writes ----------------------------------------------------
  irq_vec_t wdata_by_irq;  // write data re-indexed by interrupt number
  assign wdata_by_irq = s_to_vs_wdata(wdata);

  assign to_mie_valid = {64{wen}} & mie_is_alias & SIDEBAND_RW;
  assign to_mie_bits  = to_mie_valid & wdata_by_irq;
  assign to_sie_valid = {64{wen}} & sie_is_alias & SIDEBAND_RW;
  assign to_sie_bits  = to_sie_valid & wdata_by_irq;

  // ---- Own flops (locals 14..63) -------------------------------------------
  for (genvar i = 0; i < 64; i++) begin : g_bit
    if (OWN_FLOP_MASK[i]) begin : g_flop
      logic q;
      always_ff @(posedge clk or posedge rst) begin
        if (rst)
          q <= 1'b0;
        else if (wen & uses_own_bit[i])
          q <= wdata[i];
      end
      assign own_bits[i] = q;
    end else begin : g_none
      assign own_bits[i] = 1'b0;
    end
  end
endmodule

// BEGIN GENERATED(csr-irq-handle)
module VSieModule (
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
  input         hideleg_SSI,
  input         hideleg_VSSI,
  input         hideleg_MSI,
  input         hideleg_STI,
  input         hideleg_VSTI,
  input         hideleg_MTI,
  input         hideleg_SEI,
  input         hideleg_VSEI,
  input         hideleg_MEI,
  input         hideleg_SGEI,
  input         hideleg_LCOFI,
  input         hvien_LC14IE,
  input         hvien_LC15IE,
  input         hvien_LC16IE,
  input         hvien_LC17IE,
  input         hvien_LC18IE,
  input         hvien_LC19IE,
  input         hvien_LC20IE,
  input         hvien_LC21IE,
  input         hvien_LC22IE,
  input         hvien_LC23IE,
  input         hvien_LC24IE,
  input         hvien_LC25IE,
  input         hvien_LC26IE,
  input         hvien_LC27IE,
  input         hvien_LC28IE,
  input         hvien_LC29IE,
  input         hvien_LC30IE,
  input         hvien_LC31IE,
  input         hvien_LC32IE,
  input         hvien_LC33IE,
  input         hvien_LC34IE,
  input         hvien_LPRASEIE,
  input         hvien_LC36IE,
  input         hvien_LC37IE,
  input         hvien_LC38IE,
  input         hvien_LC39IE,
  input         hvien_LC40IE,
  input         hvien_LC41IE,
  input         hvien_LC42IE,
  input         hvien_HPRASEIE,
  input         hvien_LC44IE,
  input         hvien_LC45IE,
  input         hvien_LC46IE,
  input         hvien_LC47IE,
  input         hvien_LC48IE,
  input         hvien_LC49IE,
  input         hvien_LC50IE,
  input         hvien_LC51IE,
  input         hvien_LC52IE,
  input         hvien_LC53IE,
  input         hvien_LC54IE,
  input         hvien_LC55IE,
  input         hvien_LC56IE,
  input         hvien_LC57IE,
  input         hvien_LC58IE,
  input         hvien_LC59IE,
  input         hvien_LC60IE,
  input         hvien_LC61IE,
  input         hvien_LC62IE,
  input         hvien_LC63IE,
  input         sie_SSIE,
  input         sie_STIE,
  input         sie_SEIE,
  input         sie_LCOFIE,
  input         sie_LC14IE,
  input         sie_LC15IE,
  input         sie_LC16IE,
  input         sie_LC17IE,
  input         sie_LC18IE,
  input         sie_LC19IE,
  input         sie_LC20IE,
  input         sie_LC21IE,
  input         sie_LC22IE,
  input         sie_LC23IE,
  input         sie_LC24IE,
  input         sie_LC25IE,
  input         sie_LC26IE,
  input         sie_LC27IE,
  input         sie_LC28IE,
  input         sie_LC29IE,
  input         sie_LC30IE,
  input         sie_LC31IE,
  input         sie_LC32IE,
  input         sie_LC33IE,
  input         sie_LC34IE,
  input         sie_LPRASEIE,
  input         sie_LC36IE,
  input         sie_LC37IE,
  input         sie_LC38IE,
  input         sie_LC39IE,
  input         sie_LC40IE,
  input         sie_LC41IE,
  input         sie_LC42IE,
  input         sie_HPRASEIE,
  input         sie_LC44IE,
  input         sie_LC45IE,
  input         sie_LC46IE,
  input         sie_LC47IE,
  input         sie_LC48IE,
  input         sie_LC49IE,
  input         sie_LC50IE,
  input         sie_LC51IE,
  input         sie_LC52IE,
  input         sie_LC53IE,
  input         sie_LC54IE,
  input         sie_LC55IE,
  input         sie_LC56IE,
  input         sie_LC57IE,
  input         sie_LC58IE,
  input         sie_LC59IE,
  input         sie_LC60IE,
  input         sie_LC61IE,
  input         sie_LC62IE,
  input         sie_LC63IE,
  output        toMie_VSSIE_valid,
  output        toMie_VSSIE_bits,
  output        toMie_VSTIE_valid,
  output        toMie_VSTIE_bits,
  output        toMie_VSEIE_valid,
  output        toMie_VSEIE_bits,
  output        toMie_LCOFIE_valid,
  output        toMie_LCOFIE_bits,
  output        toSie_VSSIE_valid,
  output        toSie_VSSIE_bits,
  output        toSie_VSTIE_valid,
  output        toSie_VSTIE_bits,
  output        toSie_VSEIE_valid,
  output        toSie_VSEIE_bits,
  output        toSie_LCOFIE_valid,
  output        toSie_LCOFIE_bits,
  output        toSie_LC14IE_valid,
  output        toSie_LC14IE_bits,
  output        toSie_LC15IE_valid,
  output        toSie_LC15IE_bits,
  output        toSie_LC16IE_valid,
  output        toSie_LC16IE_bits,
  output        toSie_LC17IE_valid,
  output        toSie_LC17IE_bits,
  output        toSie_LC18IE_valid,
  output        toSie_LC18IE_bits,
  output        toSie_LC19IE_valid,
  output        toSie_LC19IE_bits,
  output        toSie_LC20IE_valid,
  output        toSie_LC20IE_bits,
  output        toSie_LC21IE_valid,
  output        toSie_LC21IE_bits,
  output        toSie_LC22IE_valid,
  output        toSie_LC22IE_bits,
  output        toSie_LC23IE_valid,
  output        toSie_LC23IE_bits,
  output        toSie_LC24IE_valid,
  output        toSie_LC24IE_bits,
  output        toSie_LC25IE_valid,
  output        toSie_LC25IE_bits,
  output        toSie_LC26IE_valid,
  output        toSie_LC26IE_bits,
  output        toSie_LC27IE_valid,
  output        toSie_LC27IE_bits,
  output        toSie_LC28IE_valid,
  output        toSie_LC28IE_bits,
  output        toSie_LC29IE_valid,
  output        toSie_LC29IE_bits,
  output        toSie_LC30IE_valid,
  output        toSie_LC30IE_bits,
  output        toSie_LC31IE_valid,
  output        toSie_LC31IE_bits,
  output        toSie_LC32IE_valid,
  output        toSie_LC32IE_bits,
  output        toSie_LC33IE_valid,
  output        toSie_LC33IE_bits,
  output        toSie_LC34IE_valid,
  output        toSie_LC34IE_bits,
  output        toSie_LPRASEIE_valid,
  output        toSie_LPRASEIE_bits,
  output        toSie_LC36IE_valid,
  output        toSie_LC36IE_bits,
  output        toSie_LC37IE_valid,
  output        toSie_LC37IE_bits,
  output        toSie_LC38IE_valid,
  output        toSie_LC38IE_bits,
  output        toSie_LC39IE_valid,
  output        toSie_LC39IE_bits,
  output        toSie_LC40IE_valid,
  output        toSie_LC40IE_bits,
  output        toSie_LC41IE_valid,
  output        toSie_LC41IE_bits,
  output        toSie_LC42IE_valid,
  output        toSie_LC42IE_bits,
  output        toSie_HPRASEIE_valid,
  output        toSie_HPRASEIE_bits,
  output        toSie_LC44IE_valid,
  output        toSie_LC44IE_bits,
  output        toSie_LC45IE_valid,
  output        toSie_LC45IE_bits,
  output        toSie_LC46IE_valid,
  output        toSie_LC46IE_bits,
  output        toSie_LC47IE_valid,
  output        toSie_LC47IE_bits,
  output        toSie_LC48IE_valid,
  output        toSie_LC48IE_bits,
  output        toSie_LC49IE_valid,
  output        toSie_LC49IE_bits,
  output        toSie_LC50IE_valid,
  output        toSie_LC50IE_bits,
  output        toSie_LC51IE_valid,
  output        toSie_LC51IE_bits,
  output        toSie_LC52IE_valid,
  output        toSie_LC52IE_bits,
  output        toSie_LC53IE_valid,
  output        toSie_LC53IE_bits,
  output        toSie_LC54IE_valid,
  output        toSie_LC54IE_bits,
  output        toSie_LC55IE_valid,
  output        toSie_LC55IE_bits,
  output        toSie_LC56IE_valid,
  output        toSie_LC56IE_bits,
  output        toSie_LC57IE_valid,
  output        toSie_LC57IE_bits,
  output        toSie_LC58IE_valid,
  output        toSie_LC58IE_bits,
  output        toSie_LC59IE_valid,
  output        toSie_LC59IE_bits,
  output        toSie_LC60IE_valid,
  output        toSie_LC60IE_bits,
  output        toSie_LC61IE_valid,
  output        toSie_LC61IE_bits,
  output        toSie_LC62IE_valid,
  output        toSie_LC62IE_bits,
  output        toSie_LC63IE_valid,
  output        toSie_LC63IE_bits
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
  logic [63:0] hideleg;
  always_comb begin
    hideleg = 64'h0000_0000_0000_0000;
    hideleg[1] = hideleg_SSI;
    hideleg[2] = hideleg_VSSI;
    hideleg[3] = hideleg_MSI;
    hideleg[5] = hideleg_STI;
    hideleg[6] = hideleg_VSTI;
    hideleg[7] = hideleg_MTI;
    hideleg[9] = hideleg_SEI;
    hideleg[10] = hideleg_VSEI;
    hideleg[11] = hideleg_MEI;
    hideleg[12] = hideleg_SGEI;
    hideleg[13] = hideleg_LCOFI;
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
  logic [63:0] sie;
  always_comb begin
    sie = 64'h0000_0000_0000_0000;
    sie[1] = sie_SSIE;
    sie[5] = sie_STIE;
    sie[9] = sie_SEIE;
    sie[13] = sie_LCOFIE;
    sie[14] = sie_LC14IE;
    sie[15] = sie_LC15IE;
    sie[16] = sie_LC16IE;
    sie[17] = sie_LC17IE;
    sie[18] = sie_LC18IE;
    sie[19] = sie_LC19IE;
    sie[20] = sie_LC20IE;
    sie[21] = sie_LC21IE;
    sie[22] = sie_LC22IE;
    sie[23] = sie_LC23IE;
    sie[24] = sie_LC24IE;
    sie[25] = sie_LC25IE;
    sie[26] = sie_LC26IE;
    sie[27] = sie_LC27IE;
    sie[28] = sie_LC28IE;
    sie[29] = sie_LC29IE;
    sie[30] = sie_LC30IE;
    sie[31] = sie_LC31IE;
    sie[32] = sie_LC32IE;
    sie[33] = sie_LC33IE;
    sie[34] = sie_LC34IE;
    sie[35] = sie_LPRASEIE;
    sie[36] = sie_LC36IE;
    sie[37] = sie_LC37IE;
    sie[38] = sie_LC38IE;
    sie[39] = sie_LC39IE;
    sie[40] = sie_LC40IE;
    sie[41] = sie_LC41IE;
    sie[42] = sie_LC42IE;
    sie[43] = sie_HPRASEIE;
    sie[44] = sie_LC44IE;
    sie[45] = sie_LC45IE;
    sie[46] = sie_LC46IE;
    sie[47] = sie_LC47IE;
    sie[48] = sie_LC48IE;
    sie[49] = sie_LC49IE;
    sie[50] = sie_LC50IE;
    sie[51] = sie_LC51IE;
    sie[52] = sie_LC52IE;
    sie[53] = sie_LC53IE;
    sie[54] = sie_LC54IE;
    sie[55] = sie_LC55IE;
    sie[56] = sie_LC56IE;
    sie[57] = sie_LC57IE;
    sie[58] = sie_LC58IE;
    sie[59] = sie_LC59IE;
    sie[60] = sie_LC60IE;
    sie[61] = sie_LC61IE;
    sie[62] = sie_LC62IE;
    sie[63] = sie_LC63IE;
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
  logic [63:0] hvien;
  always_comb begin
    hvien = 64'h0000_0000_0000_0000;
    hvien[14] = hvien_LC14IE;
    hvien[15] = hvien_LC15IE;
    hvien[16] = hvien_LC16IE;
    hvien[17] = hvien_LC17IE;
    hvien[18] = hvien_LC18IE;
    hvien[19] = hvien_LC19IE;
    hvien[20] = hvien_LC20IE;
    hvien[21] = hvien_LC21IE;
    hvien[22] = hvien_LC22IE;
    hvien[23] = hvien_LC23IE;
    hvien[24] = hvien_LC24IE;
    hvien[25] = hvien_LC25IE;
    hvien[26] = hvien_LC26IE;
    hvien[27] = hvien_LC27IE;
    hvien[28] = hvien_LC28IE;
    hvien[29] = hvien_LC29IE;
    hvien[30] = hvien_LC30IE;
    hvien[31] = hvien_LC31IE;
    hvien[32] = hvien_LC32IE;
    hvien[33] = hvien_LC33IE;
    hvien[34] = hvien_LC34IE;
    hvien[35] = hvien_LPRASEIE;
    hvien[36] = hvien_LC36IE;
    hvien[37] = hvien_LC37IE;
    hvien[38] = hvien_LC38IE;
    hvien[39] = hvien_LC39IE;
    hvien[40] = hvien_LC40IE;
    hvien[41] = hvien_LC41IE;
    hvien[42] = hvien_LC42IE;
    hvien[43] = hvien_HPRASEIE;
    hvien[44] = hvien_LC44IE;
    hvien[45] = hvien_LC45IE;
    hvien[46] = hvien_LC46IE;
    hvien[47] = hvien_LC47IE;
    hvien[48] = hvien_LC48IE;
    hvien[49] = hvien_LC49IE;
    hvien[50] = hvien_LC50IE;
    hvien[51] = hvien_LC51IE;
    hvien[52] = hvien_LC52IE;
    hvien[53] = hvien_LC53IE;
    hvien[54] = hvien_LC54IE;
    hvien[55] = hvien_LC55IE;
    hvien[56] = hvien_LC56IE;
    hvien[57] = hvien_LC57IE;
    hvien[58] = hvien_LC58IE;
    hvien[59] = hvien_LC59IE;
    hvien[60] = hvien_LC60IE;
    hvien[61] = hvien_LC61IE;
    hvien[62] = hvien_LC62IE;
    hvien[63] = hvien_LC63IE;
  end
  logic [63:0] value;
  logic [63:0] to_mie_valid;
  logic [63:0] to_mie_bits;
  logic [63:0] to_sie_valid;
  logic [63:0] to_sie_bits;

  xs_VSieModule_core u_core (
    .clk          (clock),
    .rst          (reset),
    .wen          (w_wen),
    .wdata        (w_wdata),
    .mideleg      (mideleg),
    .hideleg      (hideleg),
    .mie          (mie),
    .sie          (sie),
    .mvien        (mvien),
    .hvien        (hvien),
    .value        (value),
    .to_mie_valid (to_mie_valid),
    .to_mie_bits  (to_mie_bits),
    .to_sie_valid (to_sie_valid),
    .to_sie_bits  (to_sie_bits)
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
  assign toMie_VSSIE_valid = to_mie_valid[2];
  assign toMie_VSTIE_valid = to_mie_valid[6];
  assign toMie_VSEIE_valid = to_mie_valid[10];
  assign toMie_LCOFIE_valid = to_mie_valid[13];
  assign toMie_VSSIE_bits = to_mie_bits[2];
  assign toMie_VSTIE_bits = to_mie_bits[6];
  assign toMie_VSEIE_bits = to_mie_bits[10];
  assign toMie_LCOFIE_bits = to_mie_bits[13];
  assign toSie_VSSIE_valid = to_sie_valid[2];
  assign toSie_VSTIE_valid = to_sie_valid[6];
  assign toSie_VSEIE_valid = to_sie_valid[10];
  assign toSie_LCOFIE_valid = to_sie_valid[13];
  assign toSie_LC14IE_valid = to_sie_valid[14];
  assign toSie_LC15IE_valid = to_sie_valid[15];
  assign toSie_LC16IE_valid = to_sie_valid[16];
  assign toSie_LC17IE_valid = to_sie_valid[17];
  assign toSie_LC18IE_valid = to_sie_valid[18];
  assign toSie_LC19IE_valid = to_sie_valid[19];
  assign toSie_LC20IE_valid = to_sie_valid[20];
  assign toSie_LC21IE_valid = to_sie_valid[21];
  assign toSie_LC22IE_valid = to_sie_valid[22];
  assign toSie_LC23IE_valid = to_sie_valid[23];
  assign toSie_LC24IE_valid = to_sie_valid[24];
  assign toSie_LC25IE_valid = to_sie_valid[25];
  assign toSie_LC26IE_valid = to_sie_valid[26];
  assign toSie_LC27IE_valid = to_sie_valid[27];
  assign toSie_LC28IE_valid = to_sie_valid[28];
  assign toSie_LC29IE_valid = to_sie_valid[29];
  assign toSie_LC30IE_valid = to_sie_valid[30];
  assign toSie_LC31IE_valid = to_sie_valid[31];
  assign toSie_LC32IE_valid = to_sie_valid[32];
  assign toSie_LC33IE_valid = to_sie_valid[33];
  assign toSie_LC34IE_valid = to_sie_valid[34];
  assign toSie_LPRASEIE_valid = to_sie_valid[35];
  assign toSie_LC36IE_valid = to_sie_valid[36];
  assign toSie_LC37IE_valid = to_sie_valid[37];
  assign toSie_LC38IE_valid = to_sie_valid[38];
  assign toSie_LC39IE_valid = to_sie_valid[39];
  assign toSie_LC40IE_valid = to_sie_valid[40];
  assign toSie_LC41IE_valid = to_sie_valid[41];
  assign toSie_LC42IE_valid = to_sie_valid[42];
  assign toSie_HPRASEIE_valid = to_sie_valid[43];
  assign toSie_LC44IE_valid = to_sie_valid[44];
  assign toSie_LC45IE_valid = to_sie_valid[45];
  assign toSie_LC46IE_valid = to_sie_valid[46];
  assign toSie_LC47IE_valid = to_sie_valid[47];
  assign toSie_LC48IE_valid = to_sie_valid[48];
  assign toSie_LC49IE_valid = to_sie_valid[49];
  assign toSie_LC50IE_valid = to_sie_valid[50];
  assign toSie_LC51IE_valid = to_sie_valid[51];
  assign toSie_LC52IE_valid = to_sie_valid[52];
  assign toSie_LC53IE_valid = to_sie_valid[53];
  assign toSie_LC54IE_valid = to_sie_valid[54];
  assign toSie_LC55IE_valid = to_sie_valid[55];
  assign toSie_LC56IE_valid = to_sie_valid[56];
  assign toSie_LC57IE_valid = to_sie_valid[57];
  assign toSie_LC58IE_valid = to_sie_valid[58];
  assign toSie_LC59IE_valid = to_sie_valid[59];
  assign toSie_LC60IE_valid = to_sie_valid[60];
  assign toSie_LC61IE_valid = to_sie_valid[61];
  assign toSie_LC62IE_valid = to_sie_valid[62];
  assign toSie_LC63IE_valid = to_sie_valid[63];
  assign toSie_VSSIE_bits = to_sie_bits[2];
  assign toSie_VSTIE_bits = to_sie_bits[6];
  assign toSie_VSEIE_bits = to_sie_bits[10];
  assign toSie_LCOFIE_bits = to_sie_bits[13];
  assign toSie_LC14IE_bits = to_sie_bits[14];
  assign toSie_LC15IE_bits = to_sie_bits[15];
  assign toSie_LC16IE_bits = to_sie_bits[16];
  assign toSie_LC17IE_bits = to_sie_bits[17];
  assign toSie_LC18IE_bits = to_sie_bits[18];
  assign toSie_LC19IE_bits = to_sie_bits[19];
  assign toSie_LC20IE_bits = to_sie_bits[20];
  assign toSie_LC21IE_bits = to_sie_bits[21];
  assign toSie_LC22IE_bits = to_sie_bits[22];
  assign toSie_LC23IE_bits = to_sie_bits[23];
  assign toSie_LC24IE_bits = to_sie_bits[24];
  assign toSie_LC25IE_bits = to_sie_bits[25];
  assign toSie_LC26IE_bits = to_sie_bits[26];
  assign toSie_LC27IE_bits = to_sie_bits[27];
  assign toSie_LC28IE_bits = to_sie_bits[28];
  assign toSie_LC29IE_bits = to_sie_bits[29];
  assign toSie_LC30IE_bits = to_sie_bits[30];
  assign toSie_LC31IE_bits = to_sie_bits[31];
  assign toSie_LC32IE_bits = to_sie_bits[32];
  assign toSie_LC33IE_bits = to_sie_bits[33];
  assign toSie_LC34IE_bits = to_sie_bits[34];
  assign toSie_LPRASEIE_bits = to_sie_bits[35];
  assign toSie_LC36IE_bits = to_sie_bits[36];
  assign toSie_LC37IE_bits = to_sie_bits[37];
  assign toSie_LC38IE_bits = to_sie_bits[38];
  assign toSie_LC39IE_bits = to_sie_bits[39];
  assign toSie_LC40IE_bits = to_sie_bits[40];
  assign toSie_LC41IE_bits = to_sie_bits[41];
  assign toSie_LC42IE_bits = to_sie_bits[42];
  assign toSie_HPRASEIE_bits = to_sie_bits[43];
  assign toSie_LC44IE_bits = to_sie_bits[44];
  assign toSie_LC45IE_bits = to_sie_bits[45];
  assign toSie_LC46IE_bits = to_sie_bits[46];
  assign toSie_LC47IE_bits = to_sie_bits[47];
  assign toSie_LC48IE_bits = to_sie_bits[48];
  assign toSie_LC49IE_bits = to_sie_bits[49];
  assign toSie_LC50IE_bits = to_sie_bits[50];
  assign toSie_LC51IE_bits = to_sie_bits[51];
  assign toSie_LC52IE_bits = to_sie_bits[52];
  assign toSie_LC53IE_bits = to_sie_bits[53];
  assign toSie_LC54IE_bits = to_sie_bits[54];
  assign toSie_LC55IE_bits = to_sie_bits[55];
  assign toSie_LC56IE_bits = to_sie_bits[56];
  assign toSie_LC57IE_bits = to_sie_bits[57];
  assign toSie_LC58IE_bits = to_sie_bits[58];
  assign toSie_LC59IE_bits = to_sie_bits[59];
  assign toSie_LC60IE_bits = to_sie_bits[60];
  assign toSie_LC61IE_bits = to_sie_bits[61];
  assign toSie_LC62IE_bits = to_sie_bits[62];
  assign toSie_LC63IE_bits = to_sie_bits[63];
endmodule
// END GENERATED
