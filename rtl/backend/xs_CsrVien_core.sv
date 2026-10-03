// xs_CsrVien_core.sv — shared core of the AIA "virtual interrupt enable" CSRs
// mvien (MvienModule) and hvien (HvienModule) of NewCSR.
// Both are plain WARL registers indexed by interrupt number: a CSR write
// stores wdata on the writable bits, every other bit is read-only zero.
// Nothing else writes them.  They only steer the views built by the
// sie/sip/vsie/vsip leaves (a set bit means "interrupt i is a virtual
// interrupt for the next lower level").  The two differ only in which bits
// are writable (AIA 5.3 / 6.3.2), given by WRITABLE:
//   mvien: 1 (SSIE), 9 (SEIE) and locals 14..63  (13 = LCOFIE is read-only 0)
//   hvien: locals 14..63 only                    (bits 13:0 read-only 0)
// Reset: asynchronous, 0.  One flop per writable bit, none elsewhere.
module xs_CsrVien_core
  import csr_irq_pkg::*;
#(
  parameter irq_vec_t WRITABLE = '0
) (
  input  logic     clk,
  input  logic     rst,
  input  logic     wen,     // CSR write strobe
  input  irq_vec_t wdata,   // CSR write data
  output irq_vec_t value    // read data (rdata and regOut)
);
  for (genvar i = 0; i < 64; i++) begin : g_bit
    if (WRITABLE[i]) begin : g_flop
      logic q;
      always_ff @(posedge clk or posedge rst) begin
        if (rst)
          q <= 1'b0;
        else if (wen)
          q <= wdata[i];
      end
      assign value[i] = q;
    end else begin : g_none
      assign value[i] = 1'b0;
    end
  end
endmodule
