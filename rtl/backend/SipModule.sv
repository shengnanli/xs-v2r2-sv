// SipModule.sv — supervisor interrupt-pending CSR (sip) inside NewCSR.
// Purely combinational: sip owns no state, every bit is a view (priv. spec
// 3.1.9 + AIA 5.3), selected per interrupt number:
//   mideleg[i]=1              -> sip[i] aliases mip[i];  write goes to mip
//   mideleg[i]=0, mvien[i]=1  -> sip[i] aliases mvip[i]; write goes to mvip
//   otherwise                 -> read-only zero, write dropped
// Visible bits are the HS group (1/5/9) and the locals (13..63).
// Writable through sip: toward mip only SSIP (1) and LCOFIP (13); toward mvip
// SSIP (1) and every local (13..63).  STIP/SEIP are never writable from S.
// The sideband `bits` are gated by their `valid` (Scala `&<`).
module xs_SipModule_core
  import csr_irq_pkg::*;
(
  input  logic     wen,            // CSR write strobe
  input  irq_vec_t wdata,          // CSR write data
  input  irq_vec_t mideleg,        // 1 = interrupt delegated to S
  input  irq_vec_t mip,            // machine pending bits
  input  irq_vec_t mvip,           // virtual pending bits kept by M
  input  irq_vec_t mvien,          // 1 = virtual interrupt for S level
  output irq_vec_t value,          // sip read data (rdata and regOut)
  output irq_vec_t to_mip_valid,
  output irq_vec_t to_mip_bits,
  output irq_vec_t to_mvip_valid,
  output irq_vec_t to_mvip_bits
);
  localparam irq_vec_t TO_MIP_RW  = (64'h1 << IRQ_SSI) | IRQ_LCOFI_MASK;  // SipToMip
  localparam irq_vec_t TO_MVIP_RW = (64'h1 << IRQ_SSI) | IRQ_LOCAL_MASK;  // SipToMvip

  irq_vec_t mip_is_alias;
  irq_vec_t mvip_is_alias;

  assign mip_is_alias  = mideleg;
  assign mvip_is_alias = ~mideleg & mvien;

  assign value = ((mip_is_alias & mip) | (mvip_is_alias & mvip)) & IRQ_S_VIEW_MASK;

  assign to_mip_valid  = {64{wen}} & mip_is_alias & TO_MIP_RW;
  assign to_mip_bits   = to_mip_valid & wdata;
  assign to_mvip_valid = {64{wen}} & mvip_is_alias & TO_MVIP_RW;
  assign to_mvip_bits  = to_mvip_valid & wdata;
endmodule

// BEGIN GENERATED(csr-irq-handle)
module SipModule (
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
  output        toMip_SSIP_valid,
  output        toMip_SSIP_bits,
  output        toMip_LCOFIP_valid,
  output        toMip_LCOFIP_bits,
  output        toMvip_SSIP_valid,
  output        toMvip_SSIP_bits,
  output        toMvip_LCOFIP_valid,
  output        toMvip_LCOFIP_bits,
  output        toMvip_LC14IP_valid,
  output        toMvip_LC14IP_bits,
  output        toMvip_LC15IP_valid,
  output        toMvip_LC15IP_bits,
  output        toMvip_LC16IP_valid,
  output        toMvip_LC16IP_bits,
  output        toMvip_LC17IP_valid,
  output        toMvip_LC17IP_bits,
  output        toMvip_LC18IP_valid,
  output        toMvip_LC18IP_bits,
  output        toMvip_LC19IP_valid,
  output        toMvip_LC19IP_bits,
  output        toMvip_LC20IP_valid,
  output        toMvip_LC20IP_bits,
  output        toMvip_LC21IP_valid,
  output        toMvip_LC21IP_bits,
  output        toMvip_LC22IP_valid,
  output        toMvip_LC22IP_bits,
  output        toMvip_LC23IP_valid,
  output        toMvip_LC23IP_bits,
  output        toMvip_LC24IP_valid,
  output        toMvip_LC24IP_bits,
  output        toMvip_LC25IP_valid,
  output        toMvip_LC25IP_bits,
  output        toMvip_LC26IP_valid,
  output        toMvip_LC26IP_bits,
  output        toMvip_LC27IP_valid,
  output        toMvip_LC27IP_bits,
  output        toMvip_LC28IP_valid,
  output        toMvip_LC28IP_bits,
  output        toMvip_LC29IP_valid,
  output        toMvip_LC29IP_bits,
  output        toMvip_LC30IP_valid,
  output        toMvip_LC30IP_bits,
  output        toMvip_LC31IP_valid,
  output        toMvip_LC31IP_bits,
  output        toMvip_LC32IP_valid,
  output        toMvip_LC32IP_bits,
  output        toMvip_LC33IP_valid,
  output        toMvip_LC33IP_bits,
  output        toMvip_LC34IP_valid,
  output        toMvip_LC34IP_bits,
  output        toMvip_LPRASEIP_valid,
  output        toMvip_LPRASEIP_bits,
  output        toMvip_LC36IP_valid,
  output        toMvip_LC36IP_bits,
  output        toMvip_LC37IP_valid,
  output        toMvip_LC37IP_bits,
  output        toMvip_LC38IP_valid,
  output        toMvip_LC38IP_bits,
  output        toMvip_LC39IP_valid,
  output        toMvip_LC39IP_bits,
  output        toMvip_LC40IP_valid,
  output        toMvip_LC40IP_bits,
  output        toMvip_LC41IP_valid,
  output        toMvip_LC41IP_bits,
  output        toMvip_LC42IP_valid,
  output        toMvip_LC42IP_bits,
  output        toMvip_HPRASEIP_valid,
  output        toMvip_HPRASEIP_bits,
  output        toMvip_LC44IP_valid,
  output        toMvip_LC44IP_bits,
  output        toMvip_LC45IP_valid,
  output        toMvip_LC45IP_bits,
  output        toMvip_LC46IP_valid,
  output        toMvip_LC46IP_bits,
  output        toMvip_LC47IP_valid,
  output        toMvip_LC47IP_bits,
  output        toMvip_LC48IP_valid,
  output        toMvip_LC48IP_bits,
  output        toMvip_LC49IP_valid,
  output        toMvip_LC49IP_bits,
  output        toMvip_LC50IP_valid,
  output        toMvip_LC50IP_bits,
  output        toMvip_LC51IP_valid,
  output        toMvip_LC51IP_bits,
  output        toMvip_LC52IP_valid,
  output        toMvip_LC52IP_bits,
  output        toMvip_LC53IP_valid,
  output        toMvip_LC53IP_bits,
  output        toMvip_LC54IP_valid,
  output        toMvip_LC54IP_bits,
  output        toMvip_LC55IP_valid,
  output        toMvip_LC55IP_bits,
  output        toMvip_LC56IP_valid,
  output        toMvip_LC56IP_bits,
  output        toMvip_LC57IP_valid,
  output        toMvip_LC57IP_bits,
  output        toMvip_LC58IP_valid,
  output        toMvip_LC58IP_bits,
  output        toMvip_LC59IP_valid,
  output        toMvip_LC59IP_bits,
  output        toMvip_LC60IP_valid,
  output        toMvip_LC60IP_bits,
  output        toMvip_LC61IP_valid,
  output        toMvip_LC61IP_bits,
  output        toMvip_LC62IP_valid,
  output        toMvip_LC62IP_bits,
  output        toMvip_LC63IP_valid,
  output        toMvip_LC63IP_bits
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
  logic [63:0] value;
  logic [63:0] to_mip_valid;
  logic [63:0] to_mip_bits;
  logic [63:0] to_mvip_valid;
  logic [63:0] to_mvip_bits;

  xs_SipModule_core u_core (
    .wen           (w_wen),
    .wdata         (w_wdata),
    .mideleg       (mideleg),
    .mip           (mip),
    .mvip          (mvip),
    .mvien         (mvien),
    .value         (value),
    .to_mip_valid  (to_mip_valid),
    .to_mip_bits   (to_mip_bits),
    .to_mvip_valid (to_mvip_valid),
    .to_mvip_bits  (to_mvip_bits)
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
  assign toMip_SSIP_valid = to_mip_valid[1];
  assign toMip_LCOFIP_valid = to_mip_valid[13];
  assign toMip_SSIP_bits = to_mip_bits[1];
  assign toMip_LCOFIP_bits = to_mip_bits[13];
  assign toMvip_SSIP_valid = to_mvip_valid[1];
  assign toMvip_LCOFIP_valid = to_mvip_valid[13];
  assign toMvip_LC14IP_valid = to_mvip_valid[14];
  assign toMvip_LC15IP_valid = to_mvip_valid[15];
  assign toMvip_LC16IP_valid = to_mvip_valid[16];
  assign toMvip_LC17IP_valid = to_mvip_valid[17];
  assign toMvip_LC18IP_valid = to_mvip_valid[18];
  assign toMvip_LC19IP_valid = to_mvip_valid[19];
  assign toMvip_LC20IP_valid = to_mvip_valid[20];
  assign toMvip_LC21IP_valid = to_mvip_valid[21];
  assign toMvip_LC22IP_valid = to_mvip_valid[22];
  assign toMvip_LC23IP_valid = to_mvip_valid[23];
  assign toMvip_LC24IP_valid = to_mvip_valid[24];
  assign toMvip_LC25IP_valid = to_mvip_valid[25];
  assign toMvip_LC26IP_valid = to_mvip_valid[26];
  assign toMvip_LC27IP_valid = to_mvip_valid[27];
  assign toMvip_LC28IP_valid = to_mvip_valid[28];
  assign toMvip_LC29IP_valid = to_mvip_valid[29];
  assign toMvip_LC30IP_valid = to_mvip_valid[30];
  assign toMvip_LC31IP_valid = to_mvip_valid[31];
  assign toMvip_LC32IP_valid = to_mvip_valid[32];
  assign toMvip_LC33IP_valid = to_mvip_valid[33];
  assign toMvip_LC34IP_valid = to_mvip_valid[34];
  assign toMvip_LPRASEIP_valid = to_mvip_valid[35];
  assign toMvip_LC36IP_valid = to_mvip_valid[36];
  assign toMvip_LC37IP_valid = to_mvip_valid[37];
  assign toMvip_LC38IP_valid = to_mvip_valid[38];
  assign toMvip_LC39IP_valid = to_mvip_valid[39];
  assign toMvip_LC40IP_valid = to_mvip_valid[40];
  assign toMvip_LC41IP_valid = to_mvip_valid[41];
  assign toMvip_LC42IP_valid = to_mvip_valid[42];
  assign toMvip_HPRASEIP_valid = to_mvip_valid[43];
  assign toMvip_LC44IP_valid = to_mvip_valid[44];
  assign toMvip_LC45IP_valid = to_mvip_valid[45];
  assign toMvip_LC46IP_valid = to_mvip_valid[46];
  assign toMvip_LC47IP_valid = to_mvip_valid[47];
  assign toMvip_LC48IP_valid = to_mvip_valid[48];
  assign toMvip_LC49IP_valid = to_mvip_valid[49];
  assign toMvip_LC50IP_valid = to_mvip_valid[50];
  assign toMvip_LC51IP_valid = to_mvip_valid[51];
  assign toMvip_LC52IP_valid = to_mvip_valid[52];
  assign toMvip_LC53IP_valid = to_mvip_valid[53];
  assign toMvip_LC54IP_valid = to_mvip_valid[54];
  assign toMvip_LC55IP_valid = to_mvip_valid[55];
  assign toMvip_LC56IP_valid = to_mvip_valid[56];
  assign toMvip_LC57IP_valid = to_mvip_valid[57];
  assign toMvip_LC58IP_valid = to_mvip_valid[58];
  assign toMvip_LC59IP_valid = to_mvip_valid[59];
  assign toMvip_LC60IP_valid = to_mvip_valid[60];
  assign toMvip_LC61IP_valid = to_mvip_valid[61];
  assign toMvip_LC62IP_valid = to_mvip_valid[62];
  assign toMvip_LC63IP_valid = to_mvip_valid[63];
  assign toMvip_SSIP_bits = to_mvip_bits[1];
  assign toMvip_LCOFIP_bits = to_mvip_bits[13];
  assign toMvip_LC14IP_bits = to_mvip_bits[14];
  assign toMvip_LC15IP_bits = to_mvip_bits[15];
  assign toMvip_LC16IP_bits = to_mvip_bits[16];
  assign toMvip_LC17IP_bits = to_mvip_bits[17];
  assign toMvip_LC18IP_bits = to_mvip_bits[18];
  assign toMvip_LC19IP_bits = to_mvip_bits[19];
  assign toMvip_LC20IP_bits = to_mvip_bits[20];
  assign toMvip_LC21IP_bits = to_mvip_bits[21];
  assign toMvip_LC22IP_bits = to_mvip_bits[22];
  assign toMvip_LC23IP_bits = to_mvip_bits[23];
  assign toMvip_LC24IP_bits = to_mvip_bits[24];
  assign toMvip_LC25IP_bits = to_mvip_bits[25];
  assign toMvip_LC26IP_bits = to_mvip_bits[26];
  assign toMvip_LC27IP_bits = to_mvip_bits[27];
  assign toMvip_LC28IP_bits = to_mvip_bits[28];
  assign toMvip_LC29IP_bits = to_mvip_bits[29];
  assign toMvip_LC30IP_bits = to_mvip_bits[30];
  assign toMvip_LC31IP_bits = to_mvip_bits[31];
  assign toMvip_LC32IP_bits = to_mvip_bits[32];
  assign toMvip_LC33IP_bits = to_mvip_bits[33];
  assign toMvip_LC34IP_bits = to_mvip_bits[34];
  assign toMvip_LPRASEIP_bits = to_mvip_bits[35];
  assign toMvip_LC36IP_bits = to_mvip_bits[36];
  assign toMvip_LC37IP_bits = to_mvip_bits[37];
  assign toMvip_LC38IP_bits = to_mvip_bits[38];
  assign toMvip_LC39IP_bits = to_mvip_bits[39];
  assign toMvip_LC40IP_bits = to_mvip_bits[40];
  assign toMvip_LC41IP_bits = to_mvip_bits[41];
  assign toMvip_LC42IP_bits = to_mvip_bits[42];
  assign toMvip_HPRASEIP_bits = to_mvip_bits[43];
  assign toMvip_LC44IP_bits = to_mvip_bits[44];
  assign toMvip_LC45IP_bits = to_mvip_bits[45];
  assign toMvip_LC46IP_bits = to_mvip_bits[46];
  assign toMvip_LC47IP_bits = to_mvip_bits[47];
  assign toMvip_LC48IP_bits = to_mvip_bits[48];
  assign toMvip_LC49IP_bits = to_mvip_bits[49];
  assign toMvip_LC50IP_bits = to_mvip_bits[50];
  assign toMvip_LC51IP_bits = to_mvip_bits[51];
  assign toMvip_LC52IP_bits = to_mvip_bits[52];
  assign toMvip_LC53IP_bits = to_mvip_bits[53];
  assign toMvip_LC54IP_bits = to_mvip_bits[54];
  assign toMvip_LC55IP_bits = to_mvip_bits[55];
  assign toMvip_LC56IP_bits = to_mvip_bits[56];
  assign toMvip_LC57IP_bits = to_mvip_bits[57];
  assign toMvip_LC58IP_bits = to_mvip_bits[58];
  assign toMvip_LC59IP_bits = to_mvip_bits[59];
  assign toMvip_LC60IP_bits = to_mvip_bits[60];
  assign toMvip_LC61IP_bits = to_mvip_bits[61];
  assign toMvip_LC62IP_bits = to_mvip_bits[62];
  assign toMvip_LC63IP_bits = to_mvip_bits[63];
endmodule
// END GENERATED
