// VSipModule.sv — virtual-supervisor interrupt-pending CSR (vsip) in NewCSR.
// Purely combinational view, what the guest sees as "sip".  Per interrupt
// number i the pending bit comes from (priv. spec 18.2.3 + AIA 6.3.2/6.3.3):
//   hideleg[i]=1, mideleg[i]=1            -> mip[i]
//   hideleg[i]=1, mideleg[i]=0, mvien[i]  -> mvip[i]
//   hideleg[i]=0, hvien[i]=1              -> hvip[i]
//   otherwise                             -> 0
// The result is moved from interrupt-number space to supervisor positions
// (VSSIP 2 -> SSIP 1, VSTIP 6 -> STIP 5, VSEIP 10 -> SEIP 9; locals stay).
// Writes: vsip.SSIP goes to hvip.VSSIP when hideleg.VSSI=1; a local bit goes
// to whichever register it currently aliases (mip / mvip / hvip).
// Quirks kept from golden:
//   * the sideband `bits` are NOT gated by `valid` here (plain wdata), unlike
//     sie/sip/vsie;
//   * toward mip only LCOFIP (13) is writable (VSipToMip);
//   * the Scala toMvip sideband has no port at all in golden (its valid is a
//     folded constant 0 and NewCSR does not read it), so it is not modelled.
module xs_VSipModule_core
  import csr_irq_pkg::*;
(
  input  logic     wen,            // CSR write strobe
  input  irq_vec_t wdata,          // CSR write data (supervisor positions)
  input  irq_vec_t mideleg,
  input  irq_vec_t hideleg,
  input  irq_vec_t mip,
  input  irq_vec_t mvip,
  input  irq_vec_t hvip,
  input  irq_vec_t mvien,
  input  irq_vec_t hvien,
  output irq_vec_t value,          // vsip read data (rdata and regOut)
  output irq_vec_t to_mip_valid,   // indexed by interrupt number
  output irq_vec_t to_mip_bits,
  output irq_vec_t to_hvip_valid,
  output irq_vec_t to_hvip_bits
);
  localparam irq_vec_t TO_MIP_RW = IRQ_LCOFI_MASK;   // VSipToMip

  irq_vec_t mip_is_alias;
  irq_vec_t mvip_is_alias;
  irq_vec_t hvip_is_alias;
  irq_vec_t pending_by_irq;

  assign mip_is_alias   = hideleg & mideleg;
  assign mvip_is_alias  = hideleg & ~mideleg & mvien;
  assign hvip_is_alias  = ~hideleg & hvien;
  assign pending_by_irq = (mip_is_alias & mip) | (mvip_is_alias & mvip) | (hvip_is_alias & hvip);

  assign value = vs_to_s_view(pending_by_irq) & IRQ_S_VIEW_MASK;

  // ---- Forwarded writes ----------------------------------------------------
  irq_vec_t wdata_by_irq;
  assign wdata_by_irq = s_to_vs_wdata(wdata);

  // Locals follow the alias; VSSIP has its own rule (hideleg.VSSI alone).
  assign to_mip_valid = {64{wen}} & mip_is_alias & IRQ_LOCAL_MASK & TO_MIP_RW;
  assign to_mip_bits  = wdata_by_irq;

  always_comb begin
    to_hvip_valid           = {64{wen}} & hvip_is_alias & IRQ_LOCAL_MASK;
    to_hvip_valid[IRQ_VSSI] = wen & hideleg[IRQ_VSSI];
  end
  assign to_hvip_bits = wdata_by_irq;
endmodule

// BEGIN GENERATED(csr-irq-handle)
module VSipModule (
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SSIP,
  output        regOut_STIP,
  output        regOut_SEIP,
  output        regOut_LCOFIP,
  output        regOut_LC14IP,
  output        regOut_LC15IP,
  output        regOut_LC16IP,
  output        regOut_LC17IP,
  output        regOut_LC18IP,
  output        regOut_LC19IP,
  output        regOut_LC20IP,
  output        regOut_LC21IP,
  output        regOut_LC22IP,
  output        regOut_LC23IP,
  output        regOut_LC24IP,
  output        regOut_LC25IP,
  output        regOut_LC26IP,
  output        regOut_LC27IP,
  output        regOut_LC28IP,
  output        regOut_LC29IP,
  output        regOut_LC30IP,
  output        regOut_LC31IP,
  output        regOut_LC32IP,
  output        regOut_LC33IP,
  output        regOut_LC34IP,
  output        regOut_LPRASEIP,
  output        regOut_LC36IP,
  output        regOut_LC37IP,
  output        regOut_LC38IP,
  output        regOut_LC39IP,
  output        regOut_LC40IP,
  output        regOut_LC41IP,
  output        regOut_LC42IP,
  output        regOut_HPRASEIP,
  output        regOut_LC44IP,
  output        regOut_LC45IP,
  output        regOut_LC46IP,
  output        regOut_LC47IP,
  output        regOut_LC48IP,
  output        regOut_LC49IP,
  output        regOut_LC50IP,
  output        regOut_LC51IP,
  output        regOut_LC52IP,
  output        regOut_LC53IP,
  output        regOut_LC54IP,
  output        regOut_LC55IP,
  output        regOut_LC56IP,
  output        regOut_LC57IP,
  output        regOut_LC58IP,
  output        regOut_LC59IP,
  output        regOut_LC60IP,
  output        regOut_LC61IP,
  output        regOut_LC62IP,
  output        regOut_LC63IP,
  input         mideleg_SSI,
  input         mideleg_STI,
  input         mideleg_SEI,
  input         mideleg_LCOFI,
  input         mip_SSIP,
  input         mip_VSSIP,
  input         mip_MSIP,
  input         mip_STIP,
  input         mip_VSTIP,
  input         mip_MTIP,
  input         mip_SEIP,
  input         mip_VSEIP,
  input         mip_MEIP,
  input         mip_SGEIP,
  input         mip_LCOFIP,
  input         mip_LC14IP,
  input         mip_LC15IP,
  input         mip_LC16IP,
  input         mip_LC17IP,
  input         mip_LC18IP,
  input         mip_LC19IP,
  input         mip_LC20IP,
  input         mip_LC21IP,
  input         mip_LC22IP,
  input         mip_LC23IP,
  input         mip_LC24IP,
  input         mip_LC25IP,
  input         mip_LC26IP,
  input         mip_LC27IP,
  input         mip_LC28IP,
  input         mip_LC29IP,
  input         mip_LC30IP,
  input         mip_LC31IP,
  input         mip_LC32IP,
  input         mip_LC33IP,
  input         mip_LC34IP,
  input         mip_LPRASEIP,
  input         mip_LC36IP,
  input         mip_LC37IP,
  input         mip_LC38IP,
  input         mip_LC39IP,
  input         mip_LC40IP,
  input         mip_LC41IP,
  input         mip_LC42IP,
  input         mip_HPRASEIP,
  input         mip_LC44IP,
  input         mip_LC45IP,
  input         mip_LC46IP,
  input         mip_LC47IP,
  input         mip_LC48IP,
  input         mip_LC49IP,
  input         mip_LC50IP,
  input         mip_LC51IP,
  input         mip_LC52IP,
  input         mip_LC53IP,
  input         mip_LC54IP,
  input         mip_LC55IP,
  input         mip_LC56IP,
  input         mip_LC57IP,
  input         mip_LC58IP,
  input         mip_LC59IP,
  input         mip_LC60IP,
  input         mip_LC61IP,
  input         mip_LC62IP,
  input         mip_LC63IP,
  input         mvip_SSIP,
  input         mvip_STIP,
  input         mvip_SEIP,
  input         mvip_LCOFIP,
  input         mvip_LC14IP,
  input         mvip_LC15IP,
  input         mvip_LC16IP,
  input         mvip_LC17IP,
  input         mvip_LC18IP,
  input         mvip_LC19IP,
  input         mvip_LC20IP,
  input         mvip_LC21IP,
  input         mvip_LC22IP,
  input         mvip_LC23IP,
  input         mvip_LC24IP,
  input         mvip_LC25IP,
  input         mvip_LC26IP,
  input         mvip_LC27IP,
  input         mvip_LC28IP,
  input         mvip_LC29IP,
  input         mvip_LC30IP,
  input         mvip_LC31IP,
  input         mvip_LC32IP,
  input         mvip_LC33IP,
  input         mvip_LC34IP,
  input         mvip_LPRASEIP,
  input         mvip_LC36IP,
  input         mvip_LC37IP,
  input         mvip_LC38IP,
  input         mvip_LC39IP,
  input         mvip_LC40IP,
  input         mvip_LC41IP,
  input         mvip_LC42IP,
  input         mvip_HPRASEIP,
  input         mvip_LC44IP,
  input         mvip_LC45IP,
  input         mvip_LC46IP,
  input         mvip_LC47IP,
  input         mvip_LC48IP,
  input         mvip_LC49IP,
  input         mvip_LC50IP,
  input         mvip_LC51IP,
  input         mvip_LC52IP,
  input         mvip_LC53IP,
  input         mvip_LC54IP,
  input         mvip_LC55IP,
  input         mvip_LC56IP,
  input         mvip_LC57IP,
  input         mvip_LC58IP,
  input         mvip_LC59IP,
  input         mvip_LC60IP,
  input         mvip_LC61IP,
  input         mvip_LC62IP,
  input         mvip_LC63IP,
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
  input         hvip_VSSIP,
  input         hvip_VSTIP,
  input         hvip_VSEIP,
  input         hvip_LCOFIP,
  input         hvip_LC14IP,
  input         hvip_LC15IP,
  input         hvip_LC16IP,
  input         hvip_LC17IP,
  input         hvip_LC18IP,
  input         hvip_LC19IP,
  input         hvip_LC20IP,
  input         hvip_LC21IP,
  input         hvip_LC22IP,
  input         hvip_LC23IP,
  input         hvip_LC24IP,
  input         hvip_LC25IP,
  input         hvip_LC26IP,
  input         hvip_LC27IP,
  input         hvip_LC28IP,
  input         hvip_LC29IP,
  input         hvip_LC30IP,
  input         hvip_LC31IP,
  input         hvip_LC32IP,
  input         hvip_LC33IP,
  input         hvip_LC34IP,
  input         hvip_LPRASEIP,
  input         hvip_LC36IP,
  input         hvip_LC37IP,
  input         hvip_LC38IP,
  input         hvip_LC39IP,
  input         hvip_LC40IP,
  input         hvip_LC41IP,
  input         hvip_LC42IP,
  input         hvip_HPRASEIP,
  input         hvip_LC44IP,
  input         hvip_LC45IP,
  input         hvip_LC46IP,
  input         hvip_LC47IP,
  input         hvip_LC48IP,
  input         hvip_LC49IP,
  input         hvip_LC50IP,
  input         hvip_LC51IP,
  input         hvip_LC52IP,
  input         hvip_LC53IP,
  input         hvip_LC54IP,
  input         hvip_LC55IP,
  input         hvip_LC56IP,
  input         hvip_LC57IP,
  input         hvip_LC58IP,
  input         hvip_LC59IP,
  input         hvip_LC60IP,
  input         hvip_LC61IP,
  input         hvip_LC62IP,
  input         hvip_LC63IP,
  output        toMip_LCOFIP_valid,
  output        toMip_LCOFIP_bits,
  output        toHvip_VSSIP_valid,
  output        toHvip_VSSIP_bits,
  output        toHvip_LCOFIP_bits,
  output        toHvip_LC14IP_valid,
  output        toHvip_LC14IP_bits,
  output        toHvip_LC15IP_valid,
  output        toHvip_LC15IP_bits,
  output        toHvip_LC16IP_valid,
  output        toHvip_LC16IP_bits,
  output        toHvip_LC17IP_valid,
  output        toHvip_LC17IP_bits,
  output        toHvip_LC18IP_valid,
  output        toHvip_LC18IP_bits,
  output        toHvip_LC19IP_valid,
  output        toHvip_LC19IP_bits,
  output        toHvip_LC20IP_valid,
  output        toHvip_LC20IP_bits,
  output        toHvip_LC21IP_valid,
  output        toHvip_LC21IP_bits,
  output        toHvip_LC22IP_valid,
  output        toHvip_LC22IP_bits,
  output        toHvip_LC23IP_valid,
  output        toHvip_LC23IP_bits,
  output        toHvip_LC24IP_valid,
  output        toHvip_LC24IP_bits,
  output        toHvip_LC25IP_valid,
  output        toHvip_LC25IP_bits,
  output        toHvip_LC26IP_valid,
  output        toHvip_LC26IP_bits,
  output        toHvip_LC27IP_valid,
  output        toHvip_LC27IP_bits,
  output        toHvip_LC28IP_valid,
  output        toHvip_LC28IP_bits,
  output        toHvip_LC29IP_valid,
  output        toHvip_LC29IP_bits,
  output        toHvip_LC30IP_valid,
  output        toHvip_LC30IP_bits,
  output        toHvip_LC31IP_valid,
  output        toHvip_LC31IP_bits,
  output        toHvip_LC32IP_valid,
  output        toHvip_LC32IP_bits,
  output        toHvip_LC33IP_valid,
  output        toHvip_LC33IP_bits,
  output        toHvip_LC34IP_valid,
  output        toHvip_LC34IP_bits,
  output        toHvip_LPRASEIP_valid,
  output        toHvip_LPRASEIP_bits,
  output        toHvip_LC36IP_valid,
  output        toHvip_LC36IP_bits,
  output        toHvip_LC37IP_valid,
  output        toHvip_LC37IP_bits,
  output        toHvip_LC38IP_valid,
  output        toHvip_LC38IP_bits,
  output        toHvip_LC39IP_valid,
  output        toHvip_LC39IP_bits,
  output        toHvip_LC40IP_valid,
  output        toHvip_LC40IP_bits,
  output        toHvip_LC41IP_valid,
  output        toHvip_LC41IP_bits,
  output        toHvip_LC42IP_valid,
  output        toHvip_LC42IP_bits,
  output        toHvip_HPRASEIP_valid,
  output        toHvip_HPRASEIP_bits,
  output        toHvip_LC44IP_valid,
  output        toHvip_LC44IP_bits,
  output        toHvip_LC45IP_valid,
  output        toHvip_LC45IP_bits,
  output        toHvip_LC46IP_valid,
  output        toHvip_LC46IP_bits,
  output        toHvip_LC47IP_valid,
  output        toHvip_LC47IP_bits,
  output        toHvip_LC48IP_valid,
  output        toHvip_LC48IP_bits,
  output        toHvip_LC49IP_valid,
  output        toHvip_LC49IP_bits,
  output        toHvip_LC50IP_valid,
  output        toHvip_LC50IP_bits,
  output        toHvip_LC51IP_valid,
  output        toHvip_LC51IP_bits,
  output        toHvip_LC52IP_valid,
  output        toHvip_LC52IP_bits,
  output        toHvip_LC53IP_valid,
  output        toHvip_LC53IP_bits,
  output        toHvip_LC54IP_valid,
  output        toHvip_LC54IP_bits,
  output        toHvip_LC55IP_valid,
  output        toHvip_LC55IP_bits,
  output        toHvip_LC56IP_valid,
  output        toHvip_LC56IP_bits,
  output        toHvip_LC57IP_valid,
  output        toHvip_LC57IP_bits,
  output        toHvip_LC58IP_valid,
  output        toHvip_LC58IP_bits,
  output        toHvip_LC59IP_valid,
  output        toHvip_LC59IP_bits,
  output        toHvip_LC60IP_valid,
  output        toHvip_LC60IP_bits,
  output        toHvip_LC61IP_valid,
  output        toHvip_LC61IP_bits,
  output        toHvip_LC62IP_valid,
  output        toHvip_LC62IP_bits,
  output        toHvip_LC63IP_valid,
  output        toHvip_LC63IP_bits
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
  logic [63:0] mip;
  always_comb begin
    mip = 64'h0000_0000_0000_0000;
    mip[1] = mip_SSIP;
    mip[2] = mip_VSSIP;
    mip[3] = mip_MSIP;
    mip[5] = mip_STIP;
    mip[6] = mip_VSTIP;
    mip[7] = mip_MTIP;
    mip[9] = mip_SEIP;
    mip[10] = mip_VSEIP;
    mip[11] = mip_MEIP;
    mip[12] = mip_SGEIP;
    mip[13] = mip_LCOFIP;
    mip[14] = mip_LC14IP;
    mip[15] = mip_LC15IP;
    mip[16] = mip_LC16IP;
    mip[17] = mip_LC17IP;
    mip[18] = mip_LC18IP;
    mip[19] = mip_LC19IP;
    mip[20] = mip_LC20IP;
    mip[21] = mip_LC21IP;
    mip[22] = mip_LC22IP;
    mip[23] = mip_LC23IP;
    mip[24] = mip_LC24IP;
    mip[25] = mip_LC25IP;
    mip[26] = mip_LC26IP;
    mip[27] = mip_LC27IP;
    mip[28] = mip_LC28IP;
    mip[29] = mip_LC29IP;
    mip[30] = mip_LC30IP;
    mip[31] = mip_LC31IP;
    mip[32] = mip_LC32IP;
    mip[33] = mip_LC33IP;
    mip[34] = mip_LC34IP;
    mip[35] = mip_LPRASEIP;
    mip[36] = mip_LC36IP;
    mip[37] = mip_LC37IP;
    mip[38] = mip_LC38IP;
    mip[39] = mip_LC39IP;
    mip[40] = mip_LC40IP;
    mip[41] = mip_LC41IP;
    mip[42] = mip_LC42IP;
    mip[43] = mip_HPRASEIP;
    mip[44] = mip_LC44IP;
    mip[45] = mip_LC45IP;
    mip[46] = mip_LC46IP;
    mip[47] = mip_LC47IP;
    mip[48] = mip_LC48IP;
    mip[49] = mip_LC49IP;
    mip[50] = mip_LC50IP;
    mip[51] = mip_LC51IP;
    mip[52] = mip_LC52IP;
    mip[53] = mip_LC53IP;
    mip[54] = mip_LC54IP;
    mip[55] = mip_LC55IP;
    mip[56] = mip_LC56IP;
    mip[57] = mip_LC57IP;
    mip[58] = mip_LC58IP;
    mip[59] = mip_LC59IP;
    mip[60] = mip_LC60IP;
    mip[61] = mip_LC61IP;
    mip[62] = mip_LC62IP;
    mip[63] = mip_LC63IP;
  end
  logic [63:0] mvip;
  always_comb begin
    mvip = 64'h0000_0000_0000_0000;
    mvip[1] = mvip_SSIP;
    mvip[5] = mvip_STIP;
    mvip[9] = mvip_SEIP;
    mvip[13] = mvip_LCOFIP;
    mvip[14] = mvip_LC14IP;
    mvip[15] = mvip_LC15IP;
    mvip[16] = mvip_LC16IP;
    mvip[17] = mvip_LC17IP;
    mvip[18] = mvip_LC18IP;
    mvip[19] = mvip_LC19IP;
    mvip[20] = mvip_LC20IP;
    mvip[21] = mvip_LC21IP;
    mvip[22] = mvip_LC22IP;
    mvip[23] = mvip_LC23IP;
    mvip[24] = mvip_LC24IP;
    mvip[25] = mvip_LC25IP;
    mvip[26] = mvip_LC26IP;
    mvip[27] = mvip_LC27IP;
    mvip[28] = mvip_LC28IP;
    mvip[29] = mvip_LC29IP;
    mvip[30] = mvip_LC30IP;
    mvip[31] = mvip_LC31IP;
    mvip[32] = mvip_LC32IP;
    mvip[33] = mvip_LC33IP;
    mvip[34] = mvip_LC34IP;
    mvip[35] = mvip_LPRASEIP;
    mvip[36] = mvip_LC36IP;
    mvip[37] = mvip_LC37IP;
    mvip[38] = mvip_LC38IP;
    mvip[39] = mvip_LC39IP;
    mvip[40] = mvip_LC40IP;
    mvip[41] = mvip_LC41IP;
    mvip[42] = mvip_LC42IP;
    mvip[43] = mvip_HPRASEIP;
    mvip[44] = mvip_LC44IP;
    mvip[45] = mvip_LC45IP;
    mvip[46] = mvip_LC46IP;
    mvip[47] = mvip_LC47IP;
    mvip[48] = mvip_LC48IP;
    mvip[49] = mvip_LC49IP;
    mvip[50] = mvip_LC50IP;
    mvip[51] = mvip_LC51IP;
    mvip[52] = mvip_LC52IP;
    mvip[53] = mvip_LC53IP;
    mvip[54] = mvip_LC54IP;
    mvip[55] = mvip_LC55IP;
    mvip[56] = mvip_LC56IP;
    mvip[57] = mvip_LC57IP;
    mvip[58] = mvip_LC58IP;
    mvip[59] = mvip_LC59IP;
    mvip[60] = mvip_LC60IP;
    mvip[61] = mvip_LC61IP;
    mvip[62] = mvip_LC62IP;
    mvip[63] = mvip_LC63IP;
  end
  logic [63:0] hvip;
  always_comb begin
    hvip = 64'h0000_0000_0000_0000;
    hvip[2] = hvip_VSSIP;
    hvip[6] = hvip_VSTIP;
    hvip[10] = hvip_VSEIP;
    hvip[13] = hvip_LCOFIP;
    hvip[14] = hvip_LC14IP;
    hvip[15] = hvip_LC15IP;
    hvip[16] = hvip_LC16IP;
    hvip[17] = hvip_LC17IP;
    hvip[18] = hvip_LC18IP;
    hvip[19] = hvip_LC19IP;
    hvip[20] = hvip_LC20IP;
    hvip[21] = hvip_LC21IP;
    hvip[22] = hvip_LC22IP;
    hvip[23] = hvip_LC23IP;
    hvip[24] = hvip_LC24IP;
    hvip[25] = hvip_LC25IP;
    hvip[26] = hvip_LC26IP;
    hvip[27] = hvip_LC27IP;
    hvip[28] = hvip_LC28IP;
    hvip[29] = hvip_LC29IP;
    hvip[30] = hvip_LC30IP;
    hvip[31] = hvip_LC31IP;
    hvip[32] = hvip_LC32IP;
    hvip[33] = hvip_LC33IP;
    hvip[34] = hvip_LC34IP;
    hvip[35] = hvip_LPRASEIP;
    hvip[36] = hvip_LC36IP;
    hvip[37] = hvip_LC37IP;
    hvip[38] = hvip_LC38IP;
    hvip[39] = hvip_LC39IP;
    hvip[40] = hvip_LC40IP;
    hvip[41] = hvip_LC41IP;
    hvip[42] = hvip_LC42IP;
    hvip[43] = hvip_HPRASEIP;
    hvip[44] = hvip_LC44IP;
    hvip[45] = hvip_LC45IP;
    hvip[46] = hvip_LC46IP;
    hvip[47] = hvip_LC47IP;
    hvip[48] = hvip_LC48IP;
    hvip[49] = hvip_LC49IP;
    hvip[50] = hvip_LC50IP;
    hvip[51] = hvip_LC51IP;
    hvip[52] = hvip_LC52IP;
    hvip[53] = hvip_LC53IP;
    hvip[54] = hvip_LC54IP;
    hvip[55] = hvip_LC55IP;
    hvip[56] = hvip_LC56IP;
    hvip[57] = hvip_LC57IP;
    hvip[58] = hvip_LC58IP;
    hvip[59] = hvip_LC59IP;
    hvip[60] = hvip_LC60IP;
    hvip[61] = hvip_LC61IP;
    hvip[62] = hvip_LC62IP;
    hvip[63] = hvip_LC63IP;
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
  logic [63:0] to_mip_valid;
  logic [63:0] to_mip_bits;
  logic [63:0] to_hvip_valid;
  logic [63:0] to_hvip_bits;

  xs_VSipModule_core u_core (
    .wen           (w_wen),
    .wdata         (w_wdata),
    .mideleg       (mideleg),
    .hideleg       (hideleg),
    .mip           (mip),
    .mvip          (mvip),
    .hvip          (hvip),
    .mvien         (mvien),
    .hvien         (hvien),
    .value         (value),
    .to_mip_valid  (to_mip_valid),
    .to_mip_bits   (to_mip_bits),
    .to_hvip_valid (to_hvip_valid),
    .to_hvip_bits  (to_hvip_bits)
  );

  // Outputs spread back to one port per interrupt number.
  assign rdata = value;
  assign regOut_SSIP = value[1];
  assign regOut_STIP = value[5];
  assign regOut_SEIP = value[9];
  assign regOut_LCOFIP = value[13];
  assign regOut_LC14IP = value[14];
  assign regOut_LC15IP = value[15];
  assign regOut_LC16IP = value[16];
  assign regOut_LC17IP = value[17];
  assign regOut_LC18IP = value[18];
  assign regOut_LC19IP = value[19];
  assign regOut_LC20IP = value[20];
  assign regOut_LC21IP = value[21];
  assign regOut_LC22IP = value[22];
  assign regOut_LC23IP = value[23];
  assign regOut_LC24IP = value[24];
  assign regOut_LC25IP = value[25];
  assign regOut_LC26IP = value[26];
  assign regOut_LC27IP = value[27];
  assign regOut_LC28IP = value[28];
  assign regOut_LC29IP = value[29];
  assign regOut_LC30IP = value[30];
  assign regOut_LC31IP = value[31];
  assign regOut_LC32IP = value[32];
  assign regOut_LC33IP = value[33];
  assign regOut_LC34IP = value[34];
  assign regOut_LPRASEIP = value[35];
  assign regOut_LC36IP = value[36];
  assign regOut_LC37IP = value[37];
  assign regOut_LC38IP = value[38];
  assign regOut_LC39IP = value[39];
  assign regOut_LC40IP = value[40];
  assign regOut_LC41IP = value[41];
  assign regOut_LC42IP = value[42];
  assign regOut_HPRASEIP = value[43];
  assign regOut_LC44IP = value[44];
  assign regOut_LC45IP = value[45];
  assign regOut_LC46IP = value[46];
  assign regOut_LC47IP = value[47];
  assign regOut_LC48IP = value[48];
  assign regOut_LC49IP = value[49];
  assign regOut_LC50IP = value[50];
  assign regOut_LC51IP = value[51];
  assign regOut_LC52IP = value[52];
  assign regOut_LC53IP = value[53];
  assign regOut_LC54IP = value[54];
  assign regOut_LC55IP = value[55];
  assign regOut_LC56IP = value[56];
  assign regOut_LC57IP = value[57];
  assign regOut_LC58IP = value[58];
  assign regOut_LC59IP = value[59];
  assign regOut_LC60IP = value[60];
  assign regOut_LC61IP = value[61];
  assign regOut_LC62IP = value[62];
  assign regOut_LC63IP = value[63];
  assign toMip_LCOFIP_valid = to_mip_valid[13];
  assign toMip_LCOFIP_bits = to_mip_bits[13];
  assign toHvip_VSSIP_valid = to_hvip_valid[2];
  assign toHvip_LC14IP_valid = to_hvip_valid[14];
  assign toHvip_LC15IP_valid = to_hvip_valid[15];
  assign toHvip_LC16IP_valid = to_hvip_valid[16];
  assign toHvip_LC17IP_valid = to_hvip_valid[17];
  assign toHvip_LC18IP_valid = to_hvip_valid[18];
  assign toHvip_LC19IP_valid = to_hvip_valid[19];
  assign toHvip_LC20IP_valid = to_hvip_valid[20];
  assign toHvip_LC21IP_valid = to_hvip_valid[21];
  assign toHvip_LC22IP_valid = to_hvip_valid[22];
  assign toHvip_LC23IP_valid = to_hvip_valid[23];
  assign toHvip_LC24IP_valid = to_hvip_valid[24];
  assign toHvip_LC25IP_valid = to_hvip_valid[25];
  assign toHvip_LC26IP_valid = to_hvip_valid[26];
  assign toHvip_LC27IP_valid = to_hvip_valid[27];
  assign toHvip_LC28IP_valid = to_hvip_valid[28];
  assign toHvip_LC29IP_valid = to_hvip_valid[29];
  assign toHvip_LC30IP_valid = to_hvip_valid[30];
  assign toHvip_LC31IP_valid = to_hvip_valid[31];
  assign toHvip_LC32IP_valid = to_hvip_valid[32];
  assign toHvip_LC33IP_valid = to_hvip_valid[33];
  assign toHvip_LC34IP_valid = to_hvip_valid[34];
  assign toHvip_LPRASEIP_valid = to_hvip_valid[35];
  assign toHvip_LC36IP_valid = to_hvip_valid[36];
  assign toHvip_LC37IP_valid = to_hvip_valid[37];
  assign toHvip_LC38IP_valid = to_hvip_valid[38];
  assign toHvip_LC39IP_valid = to_hvip_valid[39];
  assign toHvip_LC40IP_valid = to_hvip_valid[40];
  assign toHvip_LC41IP_valid = to_hvip_valid[41];
  assign toHvip_LC42IP_valid = to_hvip_valid[42];
  assign toHvip_HPRASEIP_valid = to_hvip_valid[43];
  assign toHvip_LC44IP_valid = to_hvip_valid[44];
  assign toHvip_LC45IP_valid = to_hvip_valid[45];
  assign toHvip_LC46IP_valid = to_hvip_valid[46];
  assign toHvip_LC47IP_valid = to_hvip_valid[47];
  assign toHvip_LC48IP_valid = to_hvip_valid[48];
  assign toHvip_LC49IP_valid = to_hvip_valid[49];
  assign toHvip_LC50IP_valid = to_hvip_valid[50];
  assign toHvip_LC51IP_valid = to_hvip_valid[51];
  assign toHvip_LC52IP_valid = to_hvip_valid[52];
  assign toHvip_LC53IP_valid = to_hvip_valid[53];
  assign toHvip_LC54IP_valid = to_hvip_valid[54];
  assign toHvip_LC55IP_valid = to_hvip_valid[55];
  assign toHvip_LC56IP_valid = to_hvip_valid[56];
  assign toHvip_LC57IP_valid = to_hvip_valid[57];
  assign toHvip_LC58IP_valid = to_hvip_valid[58];
  assign toHvip_LC59IP_valid = to_hvip_valid[59];
  assign toHvip_LC60IP_valid = to_hvip_valid[60];
  assign toHvip_LC61IP_valid = to_hvip_valid[61];
  assign toHvip_LC62IP_valid = to_hvip_valid[62];
  assign toHvip_LC63IP_valid = to_hvip_valid[63];
  assign toHvip_VSSIP_bits = to_hvip_bits[2];
  assign toHvip_LCOFIP_bits = to_hvip_bits[13];
  assign toHvip_LC14IP_bits = to_hvip_bits[14];
  assign toHvip_LC15IP_bits = to_hvip_bits[15];
  assign toHvip_LC16IP_bits = to_hvip_bits[16];
  assign toHvip_LC17IP_bits = to_hvip_bits[17];
  assign toHvip_LC18IP_bits = to_hvip_bits[18];
  assign toHvip_LC19IP_bits = to_hvip_bits[19];
  assign toHvip_LC20IP_bits = to_hvip_bits[20];
  assign toHvip_LC21IP_bits = to_hvip_bits[21];
  assign toHvip_LC22IP_bits = to_hvip_bits[22];
  assign toHvip_LC23IP_bits = to_hvip_bits[23];
  assign toHvip_LC24IP_bits = to_hvip_bits[24];
  assign toHvip_LC25IP_bits = to_hvip_bits[25];
  assign toHvip_LC26IP_bits = to_hvip_bits[26];
  assign toHvip_LC27IP_bits = to_hvip_bits[27];
  assign toHvip_LC28IP_bits = to_hvip_bits[28];
  assign toHvip_LC29IP_bits = to_hvip_bits[29];
  assign toHvip_LC30IP_bits = to_hvip_bits[30];
  assign toHvip_LC31IP_bits = to_hvip_bits[31];
  assign toHvip_LC32IP_bits = to_hvip_bits[32];
  assign toHvip_LC33IP_bits = to_hvip_bits[33];
  assign toHvip_LC34IP_bits = to_hvip_bits[34];
  assign toHvip_LPRASEIP_bits = to_hvip_bits[35];
  assign toHvip_LC36IP_bits = to_hvip_bits[36];
  assign toHvip_LC37IP_bits = to_hvip_bits[37];
  assign toHvip_LC38IP_bits = to_hvip_bits[38];
  assign toHvip_LC39IP_bits = to_hvip_bits[39];
  assign toHvip_LC40IP_bits = to_hvip_bits[40];
  assign toHvip_LC41IP_bits = to_hvip_bits[41];
  assign toHvip_LC42IP_bits = to_hvip_bits[42];
  assign toHvip_HPRASEIP_bits = to_hvip_bits[43];
  assign toHvip_LC44IP_bits = to_hvip_bits[44];
  assign toHvip_LC45IP_bits = to_hvip_bits[45];
  assign toHvip_LC46IP_bits = to_hvip_bits[46];
  assign toHvip_LC47IP_bits = to_hvip_bits[47];
  assign toHvip_LC48IP_bits = to_hvip_bits[48];
  assign toHvip_LC49IP_bits = to_hvip_bits[49];
  assign toHvip_LC50IP_bits = to_hvip_bits[50];
  assign toHvip_LC51IP_bits = to_hvip_bits[51];
  assign toHvip_LC52IP_bits = to_hvip_bits[52];
  assign toHvip_LC53IP_bits = to_hvip_bits[53];
  assign toHvip_LC54IP_bits = to_hvip_bits[54];
  assign toHvip_LC55IP_bits = to_hvip_bits[55];
  assign toHvip_LC56IP_bits = to_hvip_bits[56];
  assign toHvip_LC57IP_bits = to_hvip_bits[57];
  assign toHvip_LC58IP_bits = to_hvip_bits[58];
  assign toHvip_LC59IP_bits = to_hvip_bits[59];
  assign toHvip_LC60IP_bits = to_hvip_bits[60];
  assign toHvip_LC61IP_bits = to_hvip_bits[61];
  assign toHvip_LC62IP_bits = to_hvip_bits[62];
  assign toHvip_LC63IP_bits = to_hvip_bits[63];
endmodule
// END GENERATED
