// MieModule.sv — machine interrupt-enable CSR (mie) inside NewCSR.
// Scala: NewCSR/MachineLevel.scala (val mie = CSRModule("Mie", MieBundle)).
// mie holds one enable flop per *non-local* interrupt plus LCOFIE:
//   1/5/9 (S), 2/6/10 (VS), 3/7/11 (M), 12 (SGEI), 13 (LCOFI).
// Besides a direct CSR write (w_wen/w_wdata), the S/VS/SGEI/LCOFI bits are
// aliases that other CSRs write through sidebands:
//   sie  -> SSIE STIE SEIE LCOFIE      (sie bit delegated by mideleg)
//   hie  -> VSSIE VSTIE VSEIE SGEIE    (hie is a view of mie)
//   vsie -> VSSIE VSTIE VSEIE LCOFIE   (guest writes landing in mie)
// Rule per bit: any sideband valid wins over the CSR write; if two sidebands
// fire together the data is their Mux1H, i.e. the OR of (valid & bits).
// The M bits (3/7/11) have no sideband and change only on a CSR write.
// Config fact: MieBundle in Scala also marks LC48IE writable, but the golden
// (KunminghuV2) has no flop for it — rdata[63:14] is constant zero here.
// Reset: asynchronous, every flop 0.
module xs_MieModule_core
  import csr_irq_pkg::*;
(
  input  logic     clk,
  input  logic     rst,
  input  logic     wen,             // CSR write strobe
  input  irq_vec_t wdata,           // CSR write data
  input  irq_vec_t sie_wr_valid,    // per-interrupt write from sie
  input  irq_vec_t sie_wr_bits,
  input  irq_vec_t hie_wr_valid,    // per-interrupt write from hie
  input  irq_vec_t hie_wr_bits,
  input  irq_vec_t vsie_wr_valid,   // per-interrupt write from vsie
  input  irq_vec_t vsie_wr_bits,
  output irq_vec_t value            // mie read data (0 where no flop exists)
);
  // Which interrupts have a flop in mie.
  localparam irq_vec_t FLOP_MASK = IRQ_HS_MASK | IRQ_VS_MASK | IRQ_M_MASK
                                 | IRQ_SGEI_MASK | IRQ_LCOFI_MASK;

  irq_vec_t side_valid;   // some sideband writes this bit
  irq_vec_t side_data;    // Mux1H of the sidebands = OR of (valid & bits)

  assign side_valid = sie_wr_valid | hie_wr_valid | vsie_wr_valid;
  assign side_data  = (sie_wr_valid & sie_wr_bits)
                    | (hie_wr_valid & hie_wr_bits)
                    | (vsie_wr_valid & vsie_wr_bits);

  for (genvar i = 0; i < 64; i++) begin : g_bit
    if (FLOP_MASK[i]) begin : g_flop
      logic q;
      always_ff @(posedge clk or posedge rst) begin
        if (rst)
          q <= 1'b0;
        else if (side_valid[i])
          q <= side_data[i];
        else if (wen)
          q <= wdata[i];
      end
      assign value[i] = q;
    end else begin : g_none
      assign value[i] = 1'b0;
    end
  end
endmodule

// golden-named wrapper: gathers the per-interrupt scalar sideband ports into
// interrupt-indexed vectors (absent sources tie to 0) and scatters regOut.
module MieModule
  import csr_irq_pkg::*;
(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output        regOut_SSIE,
  output        regOut_VSSIE,
  output        regOut_MSIE,
  output        regOut_STIE,
  output        regOut_VSTIE,
  output        regOut_MTIE,
  output        regOut_SEIE,
  output        regOut_VSEIE,
  output        regOut_MEIE,
  output        regOut_SGEIE,
  output        regOut_LCOFIE,
  input         fromHie_VSSIE_valid,
  input         fromHie_VSSIE_bits,
  input         fromHie_VSTIE_valid,
  input         fromHie_VSTIE_bits,
  input         fromHie_VSEIE_valid,
  input         fromHie_VSEIE_bits,
  input         fromHie_SGEIE_valid,
  input         fromHie_SGEIE_bits,
  input         fromSie_SSIE_valid,
  input         fromSie_SSIE_bits,
  input         fromSie_STIE_valid,
  input         fromSie_STIE_bits,
  input         fromSie_SEIE_valid,
  input         fromSie_SEIE_bits,
  input         fromSie_LCOFIE_valid,
  input         fromSie_LCOFIE_bits,
  input         fromVSie_VSSIE_valid,
  input         fromVSie_VSSIE_bits,
  input         fromVSie_VSTIE_valid,
  input         fromVSie_VSTIE_bits,
  input         fromVSie_VSEIE_valid,
  input         fromVSie_VSEIE_bits,
  input         fromVSie_LCOFIE_valid,
  input         fromVSie_LCOFIE_bits
);
  irq_vec_t sie_v, sie_b, hie_v, hie_b, vsie_v, vsie_b, value;

  always_comb begin
    sie_v = '0;  sie_b = '0;
    hie_v = '0;  hie_b = '0;
    vsie_v = '0; vsie_b = '0;
    sie_v[IRQ_SSI]    = fromSie_SSIE_valid;    sie_b[IRQ_SSI]    = fromSie_SSIE_bits;
    sie_v[IRQ_STI]    = fromSie_STIE_valid;    sie_b[IRQ_STI]    = fromSie_STIE_bits;
    sie_v[IRQ_SEI]    = fromSie_SEIE_valid;    sie_b[IRQ_SEI]    = fromSie_SEIE_bits;
    sie_v[IRQ_LCOFI]  = fromSie_LCOFIE_valid;  sie_b[IRQ_LCOFI]  = fromSie_LCOFIE_bits;
    hie_v[IRQ_VSSI]   = fromHie_VSSIE_valid;   hie_b[IRQ_VSSI]   = fromHie_VSSIE_bits;
    hie_v[IRQ_VSTI]   = fromHie_VSTIE_valid;   hie_b[IRQ_VSTI]   = fromHie_VSTIE_bits;
    hie_v[IRQ_VSEI]   = fromHie_VSEIE_valid;   hie_b[IRQ_VSEI]   = fromHie_VSEIE_bits;
    hie_v[IRQ_SGEI]   = fromHie_SGEIE_valid;   hie_b[IRQ_SGEI]   = fromHie_SGEIE_bits;
    vsie_v[IRQ_VSSI]  = fromVSie_VSSIE_valid;  vsie_b[IRQ_VSSI]  = fromVSie_VSSIE_bits;
    vsie_v[IRQ_VSTI]  = fromVSie_VSTIE_valid;  vsie_b[IRQ_VSTI]  = fromVSie_VSTIE_bits;
    vsie_v[IRQ_VSEI]  = fromVSie_VSEIE_valid;  vsie_b[IRQ_VSEI]  = fromVSie_VSEIE_bits;
    vsie_v[IRQ_LCOFI] = fromVSie_LCOFIE_valid; vsie_b[IRQ_LCOFI] = fromVSie_LCOFIE_bits;
  end

  xs_MieModule_core u_core (
    .clk           (clock),
    .rst           (reset),
    .wen           (w_wen),
    .wdata         (w_wdata),
    .sie_wr_valid  (sie_v),
    .sie_wr_bits   (sie_b),
    .hie_wr_valid  (hie_v),
    .hie_wr_bits   (hie_b),
    .vsie_wr_valid (vsie_v),
    .vsie_wr_bits  (vsie_b),
    .value         (value)
  );

  assign rdata         = value;
  assign regOut_SSIE   = value[IRQ_SSI];
  assign regOut_VSSIE  = value[IRQ_VSSI];
  assign regOut_MSIE   = value[IRQ_MSI];
  assign regOut_STIE   = value[IRQ_STI];
  assign regOut_VSTIE  = value[IRQ_VSTI];
  assign regOut_MTIE   = value[IRQ_MTI];
  assign regOut_SEIE   = value[IRQ_SEI];
  assign regOut_VSEIE  = value[IRQ_VSEI];
  assign regOut_MEIE   = value[IRQ_MEI];
  assign regOut_SGEIE  = value[IRQ_SGEI];
  assign regOut_LCOFIE = value[IRQ_LCOFI];
endmodule
