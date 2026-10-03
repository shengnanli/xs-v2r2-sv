// MvipModule.sv — machine virtual-interrupt-pending CSR (mvip, AIA 5.3).
// mvip holds the pending bits of the interrupts M-mode virtualises for
// supervisor level.  Per interrupt number:
//   1  SSIP   mvien.SSIE=0: alias of mip.SSIP (read mip, write -> toMip)
//             mvien.SSIE=1: own flop; also written by sip (fromSip)
//   5  STIP   never a flop: alias of mip.STIP while menvcfg.STCE=0 (write ->
//             toMip), read-only zero when STCE=1 (Sstc owns STIP then)
//   9  SEIP   own flop, always CSR-writable; mip can overwrite it (fromMip)
//   13 LCOFIP own flop but read-only for CSR writes: only sip can write it
//   14..63    own flops, CSR-writable; sip can overwrite them
//   others    read-only zero
// Priority when two writers hit the same flop in one cycle: the sideband
// (sip / mip) wins over the CSR write.
// Quirks kept from golden:
//   * toMip `bits` are plain wdata, not gated by valid;
//   * the value kept in the SSIP flop is retained while mvien.SSIE=0;
//   * the Scala toMip.SEIP and fromVSip sidebands have no ports in golden
//     (NewCSR leaves them unconnected), so they are not modelled.
// Reset: asynchronous, all flops 0.
module xs_MvipModule_core
  import csr_irq_pkg::*;
(
  input  logic     clk,
  input  logic     rst,
  input  logic     wen,           // CSR write strobe
  input  irq_vec_t wdata,         // CSR write data
  input  irq_vec_t mip,           // only SSIP / STIP are used
  input  irq_vec_t mvien,         // only SSIE is used
  input  logic     menvcfg_stce,  // Sstc enabled: STIP not writable
  input  irq_vec_t mip_wr_valid,  // write arriving from mip (SEIP only)
  input  irq_vec_t mip_wr_bits,
  input  irq_vec_t sip_wr_valid,  // write arriving from sip (SSIP, locals)
  input  irq_vec_t sip_wr_bits,
  output irq_vec_t value,         // mvip read data (rdata and regOut)
  output irq_vec_t to_mip_valid,  // forwarded write to mip (SSIP, STIP)
  output irq_vec_t to_mip_bits
);
  logic     ssip_q;
  logic     seip_q;
  irq_vec_t local_bits;   // flops 13..63, zero below

  // ---- Bit 1: SSIP ----------------------------------------------------------
  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      ssip_q <= 1'b0;
    else if (sip_wr_valid[IRQ_SSI])
      ssip_q <= sip_wr_bits[IRQ_SSI];
    else if (wen & mvien[IRQ_SSI])
      ssip_q <= wdata[IRQ_SSI];
  end

  // ---- Bit 9: SEIP ----------------------------------------------------------
  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      seip_q <= 1'b0;
    else if (mip_wr_valid[IRQ_SEI])
      seip_q <= mip_wr_bits[IRQ_SEI];
    else if (wen)
      seip_q <= wdata[IRQ_SEI];
  end

  // ---- Bits 13..63: locals --------------------------------------------------
  // LCOFIP (13) is RO for CSR writes; 14..63 are RW.
  for (genvar i = 0; i < 64; i++) begin : g_bit
    if (IRQ_LOCAL_MASK[i]) begin : g_flop
      logic q;
      always_ff @(posedge clk or posedge rst) begin
        if (rst)
          q <= 1'b0;
        else if (sip_wr_valid[i])
          q <= sip_wr_bits[i];
        else if (wen & IRQ_LC14UP_MASK[i])
          q <= wdata[i];
      end
      assign local_bits[i] = q;
    end else begin : g_none
      assign local_bits[i] = 1'b0;
    end
  end

  // ---- Read view ------------------------------------------------------------
  always_comb begin
    value          = local_bits;
    value[IRQ_SSI] = mvien[IRQ_SSI] ? ssip_q : mip[IRQ_SSI];
    value[IRQ_STI] = ~menvcfg_stce & mip[IRQ_STI];
    value[IRQ_SEI] = seip_q;
  end

  // ---- Writes forwarded to mip ----------------------------------------------
  always_comb begin
    to_mip_valid          = '0;
    to_mip_valid[IRQ_SSI] = wen & ~mvien[IRQ_SSI];
    to_mip_valid[IRQ_STI] = wen & ~menvcfg_stce;
  end
  assign to_mip_bits = wdata;
endmodule

// BEGIN GENERATED(csr-irq-handle)
module MvipModule (
  input         clock,
  input         reset,
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
  input         mip_SSIP,
  input         mip_STIP,
  input         mvien_SSIE,
  input         menvcfg_STCE,
  output        toMip_SSIP_valid,
  output        toMip_SSIP_bits,
  output        toMip_STIP_valid,
  output        toMip_STIP_bits,
  input         fromMip_SEIP_valid,
  input         fromMip_SEIP_bits,
  input         fromSip_SSIP_valid,
  input         fromSip_SSIP_bits,
  input         fromSip_LCOFIP_valid,
  input         fromSip_LCOFIP_bits,
  input         fromSip_LC14IP_valid,
  input         fromSip_LC14IP_bits,
  input         fromSip_LC15IP_valid,
  input         fromSip_LC15IP_bits,
  input         fromSip_LC16IP_valid,
  input         fromSip_LC16IP_bits,
  input         fromSip_LC17IP_valid,
  input         fromSip_LC17IP_bits,
  input         fromSip_LC18IP_valid,
  input         fromSip_LC18IP_bits,
  input         fromSip_LC19IP_valid,
  input         fromSip_LC19IP_bits,
  input         fromSip_LC20IP_valid,
  input         fromSip_LC20IP_bits,
  input         fromSip_LC21IP_valid,
  input         fromSip_LC21IP_bits,
  input         fromSip_LC22IP_valid,
  input         fromSip_LC22IP_bits,
  input         fromSip_LC23IP_valid,
  input         fromSip_LC23IP_bits,
  input         fromSip_LC24IP_valid,
  input         fromSip_LC24IP_bits,
  input         fromSip_LC25IP_valid,
  input         fromSip_LC25IP_bits,
  input         fromSip_LC26IP_valid,
  input         fromSip_LC26IP_bits,
  input         fromSip_LC27IP_valid,
  input         fromSip_LC27IP_bits,
  input         fromSip_LC28IP_valid,
  input         fromSip_LC28IP_bits,
  input         fromSip_LC29IP_valid,
  input         fromSip_LC29IP_bits,
  input         fromSip_LC30IP_valid,
  input         fromSip_LC30IP_bits,
  input         fromSip_LC31IP_valid,
  input         fromSip_LC31IP_bits,
  input         fromSip_LC32IP_valid,
  input         fromSip_LC32IP_bits,
  input         fromSip_LC33IP_valid,
  input         fromSip_LC33IP_bits,
  input         fromSip_LC34IP_valid,
  input         fromSip_LC34IP_bits,
  input         fromSip_LPRASEIP_valid,
  input         fromSip_LPRASEIP_bits,
  input         fromSip_LC36IP_valid,
  input         fromSip_LC36IP_bits,
  input         fromSip_LC37IP_valid,
  input         fromSip_LC37IP_bits,
  input         fromSip_LC38IP_valid,
  input         fromSip_LC38IP_bits,
  input         fromSip_LC39IP_valid,
  input         fromSip_LC39IP_bits,
  input         fromSip_LC40IP_valid,
  input         fromSip_LC40IP_bits,
  input         fromSip_LC41IP_valid,
  input         fromSip_LC41IP_bits,
  input         fromSip_LC42IP_valid,
  input         fromSip_LC42IP_bits,
  input         fromSip_HPRASEIP_valid,
  input         fromSip_HPRASEIP_bits,
  input         fromSip_LC44IP_valid,
  input         fromSip_LC44IP_bits,
  input         fromSip_LC45IP_valid,
  input         fromSip_LC45IP_bits,
  input         fromSip_LC46IP_valid,
  input         fromSip_LC46IP_bits,
  input         fromSip_LC47IP_valid,
  input         fromSip_LC47IP_bits,
  input         fromSip_LC48IP_valid,
  input         fromSip_LC48IP_bits,
  input         fromSip_LC49IP_valid,
  input         fromSip_LC49IP_bits,
  input         fromSip_LC50IP_valid,
  input         fromSip_LC50IP_bits,
  input         fromSip_LC51IP_valid,
  input         fromSip_LC51IP_bits,
  input         fromSip_LC52IP_valid,
  input         fromSip_LC52IP_bits,
  input         fromSip_LC53IP_valid,
  input         fromSip_LC53IP_bits,
  input         fromSip_LC54IP_valid,
  input         fromSip_LC54IP_bits,
  input         fromSip_LC55IP_valid,
  input         fromSip_LC55IP_bits,
  input         fromSip_LC56IP_valid,
  input         fromSip_LC56IP_bits,
  input         fromSip_LC57IP_valid,
  input         fromSip_LC57IP_bits,
  input         fromSip_LC58IP_valid,
  input         fromSip_LC58IP_bits,
  input         fromSip_LC59IP_valid,
  input         fromSip_LC59IP_bits,
  input         fromSip_LC60IP_valid,
  input         fromSip_LC60IP_bits,
  input         fromSip_LC61IP_valid,
  input         fromSip_LC61IP_bits,
  input         fromSip_LC62IP_valid,
  input         fromSip_LC62IP_bits,
  input         fromSip_LC63IP_valid,
  input         fromSip_LC63IP_bits
);
  // Inputs gathered by interrupt number.  A bit without a golden port is a
  // constant that firtool folded away; the default below restates it.
  logic [63:0] mip;
  always_comb begin
    mip = 64'h0000_0000_0000_0000;
    mip[1] = mip_SSIP;
    mip[5] = mip_STIP;
  end
  logic [63:0] mvien;
  always_comb begin
    mvien = 64'h0000_0000_0000_0000;
    mvien[1] = mvien_SSIE;
  end
  logic [63:0] mip_wr_valid;
  always_comb begin
    mip_wr_valid = 64'h0000_0000_0000_0000;
    mip_wr_valid[9] = fromMip_SEIP_valid;
  end
  logic [63:0] mip_wr_bits;
  always_comb begin
    mip_wr_bits = 64'h0000_0000_0000_0000;
    mip_wr_bits[9] = fromMip_SEIP_bits;
  end
  logic [63:0] sip_wr_valid;
  always_comb begin
    sip_wr_valid = 64'h0000_0000_0000_0000;
    sip_wr_valid[1] = fromSip_SSIP_valid;
    sip_wr_valid[13] = fromSip_LCOFIP_valid;
    sip_wr_valid[14] = fromSip_LC14IP_valid;
    sip_wr_valid[15] = fromSip_LC15IP_valid;
    sip_wr_valid[16] = fromSip_LC16IP_valid;
    sip_wr_valid[17] = fromSip_LC17IP_valid;
    sip_wr_valid[18] = fromSip_LC18IP_valid;
    sip_wr_valid[19] = fromSip_LC19IP_valid;
    sip_wr_valid[20] = fromSip_LC20IP_valid;
    sip_wr_valid[21] = fromSip_LC21IP_valid;
    sip_wr_valid[22] = fromSip_LC22IP_valid;
    sip_wr_valid[23] = fromSip_LC23IP_valid;
    sip_wr_valid[24] = fromSip_LC24IP_valid;
    sip_wr_valid[25] = fromSip_LC25IP_valid;
    sip_wr_valid[26] = fromSip_LC26IP_valid;
    sip_wr_valid[27] = fromSip_LC27IP_valid;
    sip_wr_valid[28] = fromSip_LC28IP_valid;
    sip_wr_valid[29] = fromSip_LC29IP_valid;
    sip_wr_valid[30] = fromSip_LC30IP_valid;
    sip_wr_valid[31] = fromSip_LC31IP_valid;
    sip_wr_valid[32] = fromSip_LC32IP_valid;
    sip_wr_valid[33] = fromSip_LC33IP_valid;
    sip_wr_valid[34] = fromSip_LC34IP_valid;
    sip_wr_valid[35] = fromSip_LPRASEIP_valid;
    sip_wr_valid[36] = fromSip_LC36IP_valid;
    sip_wr_valid[37] = fromSip_LC37IP_valid;
    sip_wr_valid[38] = fromSip_LC38IP_valid;
    sip_wr_valid[39] = fromSip_LC39IP_valid;
    sip_wr_valid[40] = fromSip_LC40IP_valid;
    sip_wr_valid[41] = fromSip_LC41IP_valid;
    sip_wr_valid[42] = fromSip_LC42IP_valid;
    sip_wr_valid[43] = fromSip_HPRASEIP_valid;
    sip_wr_valid[44] = fromSip_LC44IP_valid;
    sip_wr_valid[45] = fromSip_LC45IP_valid;
    sip_wr_valid[46] = fromSip_LC46IP_valid;
    sip_wr_valid[47] = fromSip_LC47IP_valid;
    sip_wr_valid[48] = fromSip_LC48IP_valid;
    sip_wr_valid[49] = fromSip_LC49IP_valid;
    sip_wr_valid[50] = fromSip_LC50IP_valid;
    sip_wr_valid[51] = fromSip_LC51IP_valid;
    sip_wr_valid[52] = fromSip_LC52IP_valid;
    sip_wr_valid[53] = fromSip_LC53IP_valid;
    sip_wr_valid[54] = fromSip_LC54IP_valid;
    sip_wr_valid[55] = fromSip_LC55IP_valid;
    sip_wr_valid[56] = fromSip_LC56IP_valid;
    sip_wr_valid[57] = fromSip_LC57IP_valid;
    sip_wr_valid[58] = fromSip_LC58IP_valid;
    sip_wr_valid[59] = fromSip_LC59IP_valid;
    sip_wr_valid[60] = fromSip_LC60IP_valid;
    sip_wr_valid[61] = fromSip_LC61IP_valid;
    sip_wr_valid[62] = fromSip_LC62IP_valid;
    sip_wr_valid[63] = fromSip_LC63IP_valid;
  end
  logic [63:0] sip_wr_bits;
  always_comb begin
    sip_wr_bits = 64'h0000_0000_0000_0000;
    sip_wr_bits[1] = fromSip_SSIP_bits;
    sip_wr_bits[13] = fromSip_LCOFIP_bits;
    sip_wr_bits[14] = fromSip_LC14IP_bits;
    sip_wr_bits[15] = fromSip_LC15IP_bits;
    sip_wr_bits[16] = fromSip_LC16IP_bits;
    sip_wr_bits[17] = fromSip_LC17IP_bits;
    sip_wr_bits[18] = fromSip_LC18IP_bits;
    sip_wr_bits[19] = fromSip_LC19IP_bits;
    sip_wr_bits[20] = fromSip_LC20IP_bits;
    sip_wr_bits[21] = fromSip_LC21IP_bits;
    sip_wr_bits[22] = fromSip_LC22IP_bits;
    sip_wr_bits[23] = fromSip_LC23IP_bits;
    sip_wr_bits[24] = fromSip_LC24IP_bits;
    sip_wr_bits[25] = fromSip_LC25IP_bits;
    sip_wr_bits[26] = fromSip_LC26IP_bits;
    sip_wr_bits[27] = fromSip_LC27IP_bits;
    sip_wr_bits[28] = fromSip_LC28IP_bits;
    sip_wr_bits[29] = fromSip_LC29IP_bits;
    sip_wr_bits[30] = fromSip_LC30IP_bits;
    sip_wr_bits[31] = fromSip_LC31IP_bits;
    sip_wr_bits[32] = fromSip_LC32IP_bits;
    sip_wr_bits[33] = fromSip_LC33IP_bits;
    sip_wr_bits[34] = fromSip_LC34IP_bits;
    sip_wr_bits[35] = fromSip_LPRASEIP_bits;
    sip_wr_bits[36] = fromSip_LC36IP_bits;
    sip_wr_bits[37] = fromSip_LC37IP_bits;
    sip_wr_bits[38] = fromSip_LC38IP_bits;
    sip_wr_bits[39] = fromSip_LC39IP_bits;
    sip_wr_bits[40] = fromSip_LC40IP_bits;
    sip_wr_bits[41] = fromSip_LC41IP_bits;
    sip_wr_bits[42] = fromSip_LC42IP_bits;
    sip_wr_bits[43] = fromSip_HPRASEIP_bits;
    sip_wr_bits[44] = fromSip_LC44IP_bits;
    sip_wr_bits[45] = fromSip_LC45IP_bits;
    sip_wr_bits[46] = fromSip_LC46IP_bits;
    sip_wr_bits[47] = fromSip_LC47IP_bits;
    sip_wr_bits[48] = fromSip_LC48IP_bits;
    sip_wr_bits[49] = fromSip_LC49IP_bits;
    sip_wr_bits[50] = fromSip_LC50IP_bits;
    sip_wr_bits[51] = fromSip_LC51IP_bits;
    sip_wr_bits[52] = fromSip_LC52IP_bits;
    sip_wr_bits[53] = fromSip_LC53IP_bits;
    sip_wr_bits[54] = fromSip_LC54IP_bits;
    sip_wr_bits[55] = fromSip_LC55IP_bits;
    sip_wr_bits[56] = fromSip_LC56IP_bits;
    sip_wr_bits[57] = fromSip_LC57IP_bits;
    sip_wr_bits[58] = fromSip_LC58IP_bits;
    sip_wr_bits[59] = fromSip_LC59IP_bits;
    sip_wr_bits[60] = fromSip_LC60IP_bits;
    sip_wr_bits[61] = fromSip_LC61IP_bits;
    sip_wr_bits[62] = fromSip_LC62IP_bits;
    sip_wr_bits[63] = fromSip_LC63IP_bits;
  end
  logic [63:0] value;
  logic [63:0] to_mip_valid;
  logic [63:0] to_mip_bits;

  xs_MvipModule_core u_core (
    .clk          (clock),
    .rst          (reset),
    .wen          (w_wen),
    .wdata        (w_wdata),
    .mip          (mip),
    .mvien        (mvien),
    .menvcfg_stce (menvcfg_STCE),
    .mip_wr_valid (mip_wr_valid),
    .mip_wr_bits  (mip_wr_bits),
    .sip_wr_valid (sip_wr_valid),
    .sip_wr_bits  (sip_wr_bits),
    .value        (value),
    .to_mip_valid (to_mip_valid),
    .to_mip_bits  (to_mip_bits)
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
  assign toMip_STIP_valid = to_mip_valid[5];
  assign toMip_SSIP_bits = to_mip_bits[1];
  assign toMip_STIP_bits = to_mip_bits[5];
endmodule
// END GENERATED
