// HvipModule.sv — hypervisor virtual-interrupt-pending CSR (hvip, priv. spec
// 18.2.3 + AIA 6.3.3).
// hvip is where the hypervisor posts interrupts for its guest.  Per interrupt
// number:
//   2  VSSIP  flop; CSR-writable, and also written by the three CSRs that
//             alias it: mip, hip and vsip (fromMip / fromHip / fromVSip)
//   6  VSTIP  flop; CSR-writable only
//   10 VSEIP  flop; CSR-writable only
//   13 LCOFIP read-only zero (RO field whose only writer is absent in golden)
//   14..63    flops; CSR-writable, vsip can overwrite them (when hideleg=0 and
//             hvien=1 the guest's vsip bit *is* this bit)
//   others    read-only zero
// Priority: an alias write wins over a CSR write in the same cycle.  If
// several alias writers of VSSIP fire together the stored value is the OR of
// their data (golden Mux1H written as an OR, kept bug-for-bug).
// Reset: asynchronous, all flops 0.
module xs_HvipModule_core
  import csr_irq_pkg::*;
(
  input  logic     clk,
  input  logic     rst,
  input  logic     wen,            // CSR write strobe
  input  irq_vec_t wdata,          // CSR write data
  input  irq_vec_t mip_wr_valid,   // alias write from mip  (VSSIP only)
  input  irq_vec_t mip_wr_bits,
  input  irq_vec_t hip_wr_valid,   // alias write from hip  (VSSIP only)
  input  irq_vec_t hip_wr_bits,
  input  irq_vec_t vsip_wr_valid,  // alias write from vsip (VSSIP, locals)
  input  irq_vec_t vsip_wr_bits,
  output irq_vec_t value           // hvip read data (rdata and regOut)
);
  logic     vssip_q;
  logic     vstip_q;
  logic     vseip_q;
  irq_vec_t local_bits;   // flops 14..63, zero below

  // ---- Bit 2: VSSIP ---------------------------------------------------------
  logic vssip_alias_write;
  logic vssip_alias_data;
  assign vssip_alias_write = mip_wr_valid[IRQ_VSSI] | hip_wr_valid[IRQ_VSSI] | vsip_wr_valid[IRQ_VSSI];
  assign vssip_alias_data  = (mip_wr_valid[IRQ_VSSI]  & mip_wr_bits[IRQ_VSSI])
                           | (hip_wr_valid[IRQ_VSSI]  & hip_wr_bits[IRQ_VSSI])
                           | (vsip_wr_valid[IRQ_VSSI] & vsip_wr_bits[IRQ_VSSI]);

  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      vssip_q <= 1'b0;
    else if (vssip_alias_write)
      vssip_q <= vssip_alias_data;
    else if (wen)
      vssip_q <= wdata[IRQ_VSSI];
  end

  // ---- Bits 6 / 10: VSTIP, VSEIP --------------------------------------------
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      vstip_q <= 1'b0;
      vseip_q <= 1'b0;
    end else if (wen) begin
      vstip_q <= wdata[IRQ_VSTI];
      vseip_q <= wdata[IRQ_VSEI];
    end
  end

  // ---- Bits 14..63: locals --------------------------------------------------
  for (genvar i = 0; i < 64; i++) begin : g_bit
    if (IRQ_LC14UP_MASK[i]) begin : g_flop
      logic q;
      always_ff @(posedge clk or posedge rst) begin
        if (rst)
          q <= 1'b0;
        else if (vsip_wr_valid[i])
          q <= vsip_wr_bits[i];
        else if (wen)
          q <= wdata[i];
      end
      assign local_bits[i] = q;
    end else begin : g_none
      assign local_bits[i] = 1'b0;
    end
  end

  // ---- Read view ------------------------------------------------------------
  always_comb begin
    value           = local_bits;
    value[IRQ_VSSI] = vssip_q;
    value[IRQ_VSTI] = vstip_q;
    value[IRQ_VSEI] = vseip_q;
  end
endmodule

// BEGIN GENERATED(csr-irq-handle)
module HvipModule (
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_VSSIP,
  output        regOut_VSTIP,
  output        regOut_VSEIP,
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
  input         fromMip_VSSIP_valid,
  input         fromMip_VSSIP_bits,
  input         fromHip_VSSIP_valid,
  input         fromHip_VSSIP_bits,
  input         fromVSip_VSSIP_valid,
  input         fromVSip_VSSIP_bits,
  input         fromVSip_LCOFIP_bits,
  input         fromVSip_LC14IP_valid,
  input         fromVSip_LC14IP_bits,
  input         fromVSip_LC15IP_valid,
  input         fromVSip_LC15IP_bits,
  input         fromVSip_LC16IP_valid,
  input         fromVSip_LC16IP_bits,
  input         fromVSip_LC17IP_valid,
  input         fromVSip_LC17IP_bits,
  input         fromVSip_LC18IP_valid,
  input         fromVSip_LC18IP_bits,
  input         fromVSip_LC19IP_valid,
  input         fromVSip_LC19IP_bits,
  input         fromVSip_LC20IP_valid,
  input         fromVSip_LC20IP_bits,
  input         fromVSip_LC21IP_valid,
  input         fromVSip_LC21IP_bits,
  input         fromVSip_LC22IP_valid,
  input         fromVSip_LC22IP_bits,
  input         fromVSip_LC23IP_valid,
  input         fromVSip_LC23IP_bits,
  input         fromVSip_LC24IP_valid,
  input         fromVSip_LC24IP_bits,
  input         fromVSip_LC25IP_valid,
  input         fromVSip_LC25IP_bits,
  input         fromVSip_LC26IP_valid,
  input         fromVSip_LC26IP_bits,
  input         fromVSip_LC27IP_valid,
  input         fromVSip_LC27IP_bits,
  input         fromVSip_LC28IP_valid,
  input         fromVSip_LC28IP_bits,
  input         fromVSip_LC29IP_valid,
  input         fromVSip_LC29IP_bits,
  input         fromVSip_LC30IP_valid,
  input         fromVSip_LC30IP_bits,
  input         fromVSip_LC31IP_valid,
  input         fromVSip_LC31IP_bits,
  input         fromVSip_LC32IP_valid,
  input         fromVSip_LC32IP_bits,
  input         fromVSip_LC33IP_valid,
  input         fromVSip_LC33IP_bits,
  input         fromVSip_LC34IP_valid,
  input         fromVSip_LC34IP_bits,
  input         fromVSip_LPRASEIP_valid,
  input         fromVSip_LPRASEIP_bits,
  input         fromVSip_LC36IP_valid,
  input         fromVSip_LC36IP_bits,
  input         fromVSip_LC37IP_valid,
  input         fromVSip_LC37IP_bits,
  input         fromVSip_LC38IP_valid,
  input         fromVSip_LC38IP_bits,
  input         fromVSip_LC39IP_valid,
  input         fromVSip_LC39IP_bits,
  input         fromVSip_LC40IP_valid,
  input         fromVSip_LC40IP_bits,
  input         fromVSip_LC41IP_valid,
  input         fromVSip_LC41IP_bits,
  input         fromVSip_LC42IP_valid,
  input         fromVSip_LC42IP_bits,
  input         fromVSip_HPRASEIP_valid,
  input         fromVSip_HPRASEIP_bits,
  input         fromVSip_LC44IP_valid,
  input         fromVSip_LC44IP_bits,
  input         fromVSip_LC45IP_valid,
  input         fromVSip_LC45IP_bits,
  input         fromVSip_LC46IP_valid,
  input         fromVSip_LC46IP_bits,
  input         fromVSip_LC47IP_valid,
  input         fromVSip_LC47IP_bits,
  input         fromVSip_LC48IP_valid,
  input         fromVSip_LC48IP_bits,
  input         fromVSip_LC49IP_valid,
  input         fromVSip_LC49IP_bits,
  input         fromVSip_LC50IP_valid,
  input         fromVSip_LC50IP_bits,
  input         fromVSip_LC51IP_valid,
  input         fromVSip_LC51IP_bits,
  input         fromVSip_LC52IP_valid,
  input         fromVSip_LC52IP_bits,
  input         fromVSip_LC53IP_valid,
  input         fromVSip_LC53IP_bits,
  input         fromVSip_LC54IP_valid,
  input         fromVSip_LC54IP_bits,
  input         fromVSip_LC55IP_valid,
  input         fromVSip_LC55IP_bits,
  input         fromVSip_LC56IP_valid,
  input         fromVSip_LC56IP_bits,
  input         fromVSip_LC57IP_valid,
  input         fromVSip_LC57IP_bits,
  input         fromVSip_LC58IP_valid,
  input         fromVSip_LC58IP_bits,
  input         fromVSip_LC59IP_valid,
  input         fromVSip_LC59IP_bits,
  input         fromVSip_LC60IP_valid,
  input         fromVSip_LC60IP_bits,
  input         fromVSip_LC61IP_valid,
  input         fromVSip_LC61IP_bits,
  input         fromVSip_LC62IP_valid,
  input         fromVSip_LC62IP_bits,
  input         fromVSip_LC63IP_valid,
  input         fromVSip_LC63IP_bits
);
  // Inputs gathered by interrupt number.  A bit without a golden port is a
  // constant that firtool folded away; the default below restates it.
  logic [63:0] mip_wr_valid;
  always_comb begin
    mip_wr_valid = 64'h0000_0000_0000_0000;
    mip_wr_valid[2] = fromMip_VSSIP_valid;
  end
  logic [63:0] mip_wr_bits;
  always_comb begin
    mip_wr_bits = 64'h0000_0000_0000_0000;
    mip_wr_bits[2] = fromMip_VSSIP_bits;
  end
  logic [63:0] hip_wr_valid;
  always_comb begin
    hip_wr_valid = 64'h0000_0000_0000_0000;
    hip_wr_valid[2] = fromHip_VSSIP_valid;
  end
  logic [63:0] hip_wr_bits;
  always_comb begin
    hip_wr_bits = 64'h0000_0000_0000_0000;
    hip_wr_bits[2] = fromHip_VSSIP_bits;
  end
  logic [63:0] vsip_wr_valid;
  always_comb begin
    vsip_wr_valid = 64'h0000_0000_0000_0000;
    vsip_wr_valid[2] = fromVSip_VSSIP_valid;
    vsip_wr_valid[14] = fromVSip_LC14IP_valid;
    vsip_wr_valid[15] = fromVSip_LC15IP_valid;
    vsip_wr_valid[16] = fromVSip_LC16IP_valid;
    vsip_wr_valid[17] = fromVSip_LC17IP_valid;
    vsip_wr_valid[18] = fromVSip_LC18IP_valid;
    vsip_wr_valid[19] = fromVSip_LC19IP_valid;
    vsip_wr_valid[20] = fromVSip_LC20IP_valid;
    vsip_wr_valid[21] = fromVSip_LC21IP_valid;
    vsip_wr_valid[22] = fromVSip_LC22IP_valid;
    vsip_wr_valid[23] = fromVSip_LC23IP_valid;
    vsip_wr_valid[24] = fromVSip_LC24IP_valid;
    vsip_wr_valid[25] = fromVSip_LC25IP_valid;
    vsip_wr_valid[26] = fromVSip_LC26IP_valid;
    vsip_wr_valid[27] = fromVSip_LC27IP_valid;
    vsip_wr_valid[28] = fromVSip_LC28IP_valid;
    vsip_wr_valid[29] = fromVSip_LC29IP_valid;
    vsip_wr_valid[30] = fromVSip_LC30IP_valid;
    vsip_wr_valid[31] = fromVSip_LC31IP_valid;
    vsip_wr_valid[32] = fromVSip_LC32IP_valid;
    vsip_wr_valid[33] = fromVSip_LC33IP_valid;
    vsip_wr_valid[34] = fromVSip_LC34IP_valid;
    vsip_wr_valid[35] = fromVSip_LPRASEIP_valid;
    vsip_wr_valid[36] = fromVSip_LC36IP_valid;
    vsip_wr_valid[37] = fromVSip_LC37IP_valid;
    vsip_wr_valid[38] = fromVSip_LC38IP_valid;
    vsip_wr_valid[39] = fromVSip_LC39IP_valid;
    vsip_wr_valid[40] = fromVSip_LC40IP_valid;
    vsip_wr_valid[41] = fromVSip_LC41IP_valid;
    vsip_wr_valid[42] = fromVSip_LC42IP_valid;
    vsip_wr_valid[43] = fromVSip_HPRASEIP_valid;
    vsip_wr_valid[44] = fromVSip_LC44IP_valid;
    vsip_wr_valid[45] = fromVSip_LC45IP_valid;
    vsip_wr_valid[46] = fromVSip_LC46IP_valid;
    vsip_wr_valid[47] = fromVSip_LC47IP_valid;
    vsip_wr_valid[48] = fromVSip_LC48IP_valid;
    vsip_wr_valid[49] = fromVSip_LC49IP_valid;
    vsip_wr_valid[50] = fromVSip_LC50IP_valid;
    vsip_wr_valid[51] = fromVSip_LC51IP_valid;
    vsip_wr_valid[52] = fromVSip_LC52IP_valid;
    vsip_wr_valid[53] = fromVSip_LC53IP_valid;
    vsip_wr_valid[54] = fromVSip_LC54IP_valid;
    vsip_wr_valid[55] = fromVSip_LC55IP_valid;
    vsip_wr_valid[56] = fromVSip_LC56IP_valid;
    vsip_wr_valid[57] = fromVSip_LC57IP_valid;
    vsip_wr_valid[58] = fromVSip_LC58IP_valid;
    vsip_wr_valid[59] = fromVSip_LC59IP_valid;
    vsip_wr_valid[60] = fromVSip_LC60IP_valid;
    vsip_wr_valid[61] = fromVSip_LC61IP_valid;
    vsip_wr_valid[62] = fromVSip_LC62IP_valid;
    vsip_wr_valid[63] = fromVSip_LC63IP_valid;
  end
  logic [63:0] vsip_wr_bits;
  always_comb begin
    vsip_wr_bits = 64'h0000_0000_0000_0000;
    vsip_wr_bits[2] = fromVSip_VSSIP_bits;
    vsip_wr_bits[13] = fromVSip_LCOFIP_bits;
    vsip_wr_bits[14] = fromVSip_LC14IP_bits;
    vsip_wr_bits[15] = fromVSip_LC15IP_bits;
    vsip_wr_bits[16] = fromVSip_LC16IP_bits;
    vsip_wr_bits[17] = fromVSip_LC17IP_bits;
    vsip_wr_bits[18] = fromVSip_LC18IP_bits;
    vsip_wr_bits[19] = fromVSip_LC19IP_bits;
    vsip_wr_bits[20] = fromVSip_LC20IP_bits;
    vsip_wr_bits[21] = fromVSip_LC21IP_bits;
    vsip_wr_bits[22] = fromVSip_LC22IP_bits;
    vsip_wr_bits[23] = fromVSip_LC23IP_bits;
    vsip_wr_bits[24] = fromVSip_LC24IP_bits;
    vsip_wr_bits[25] = fromVSip_LC25IP_bits;
    vsip_wr_bits[26] = fromVSip_LC26IP_bits;
    vsip_wr_bits[27] = fromVSip_LC27IP_bits;
    vsip_wr_bits[28] = fromVSip_LC28IP_bits;
    vsip_wr_bits[29] = fromVSip_LC29IP_bits;
    vsip_wr_bits[30] = fromVSip_LC30IP_bits;
    vsip_wr_bits[31] = fromVSip_LC31IP_bits;
    vsip_wr_bits[32] = fromVSip_LC32IP_bits;
    vsip_wr_bits[33] = fromVSip_LC33IP_bits;
    vsip_wr_bits[34] = fromVSip_LC34IP_bits;
    vsip_wr_bits[35] = fromVSip_LPRASEIP_bits;
    vsip_wr_bits[36] = fromVSip_LC36IP_bits;
    vsip_wr_bits[37] = fromVSip_LC37IP_bits;
    vsip_wr_bits[38] = fromVSip_LC38IP_bits;
    vsip_wr_bits[39] = fromVSip_LC39IP_bits;
    vsip_wr_bits[40] = fromVSip_LC40IP_bits;
    vsip_wr_bits[41] = fromVSip_LC41IP_bits;
    vsip_wr_bits[42] = fromVSip_LC42IP_bits;
    vsip_wr_bits[43] = fromVSip_HPRASEIP_bits;
    vsip_wr_bits[44] = fromVSip_LC44IP_bits;
    vsip_wr_bits[45] = fromVSip_LC45IP_bits;
    vsip_wr_bits[46] = fromVSip_LC46IP_bits;
    vsip_wr_bits[47] = fromVSip_LC47IP_bits;
    vsip_wr_bits[48] = fromVSip_LC48IP_bits;
    vsip_wr_bits[49] = fromVSip_LC49IP_bits;
    vsip_wr_bits[50] = fromVSip_LC50IP_bits;
    vsip_wr_bits[51] = fromVSip_LC51IP_bits;
    vsip_wr_bits[52] = fromVSip_LC52IP_bits;
    vsip_wr_bits[53] = fromVSip_LC53IP_bits;
    vsip_wr_bits[54] = fromVSip_LC54IP_bits;
    vsip_wr_bits[55] = fromVSip_LC55IP_bits;
    vsip_wr_bits[56] = fromVSip_LC56IP_bits;
    vsip_wr_bits[57] = fromVSip_LC57IP_bits;
    vsip_wr_bits[58] = fromVSip_LC58IP_bits;
    vsip_wr_bits[59] = fromVSip_LC59IP_bits;
    vsip_wr_bits[60] = fromVSip_LC60IP_bits;
    vsip_wr_bits[61] = fromVSip_LC61IP_bits;
    vsip_wr_bits[62] = fromVSip_LC62IP_bits;
    vsip_wr_bits[63] = fromVSip_LC63IP_bits;
  end
  logic [63:0] value;

  xs_HvipModule_core u_core (
    .clk           (clock),
    .rst           (reset),
    .wen           (w_wen),
    .wdata         (w_wdata),
    .mip_wr_valid  (mip_wr_valid),
    .mip_wr_bits   (mip_wr_bits),
    .hip_wr_valid  (hip_wr_valid),
    .hip_wr_bits   (hip_wr_bits),
    .vsip_wr_valid (vsip_wr_valid),
    .vsip_wr_bits  (vsip_wr_bits),
    .value         (value)
  );

  // Outputs spread back to one port per interrupt number.
  assign rdata = value;
  assign regOut_VSSIP = value[2];
  assign regOut_VSTIP = value[6];
  assign regOut_VSEIP = value[10];
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
endmodule
// END GENERATED
