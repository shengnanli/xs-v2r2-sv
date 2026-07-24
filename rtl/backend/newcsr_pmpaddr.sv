// NewCSR CSR-field primitive: Pmpaddr (PMP address register).
//
// Faithful, readable, parameterized reimplementation of the golden
// PmpaddrNModule family (Pmpaddr0Module .. Pmpaddr15Module, N=0..15,
// 16 instances).
//
// Golden behavior (bug-for-bug identical across all 16 instances; the ONLY
// per-instance difference is the read-mux source input port name
// addrRData_{N}, which the thin wrapper binds to `addr_rdata`):
//
//   reg_ADDRESS is a 46-bit architectural PMP address register, async-reset
//   to 0. On a CSR write (w_wen) it latches the low 46 bits of w_wdata; else
//   it holds. The write is unconditionally 46-bit truncated (matching golden's
//   WARL: only ADDRESS[45:0] is architectural; upper w_wdata bits dropped).
//
//     reg_ADDRESS <= reset ? 46'h0
//                  : w_wen  ? w_wdata[45:0]
//                           : reg_ADDRESS
//
//   The read data path returns the externally-supplied addrRData input (NOT
//   reg_ADDRESS directly). This is because PMP address readback in the golden
//   CSR file is a grouped/locked read produced upstream (accounting for TOR
//   locking / grain), fed back in as addrRData_{N}. regOut_ADDRESS exposes the
//   raw stored register for the PMP checker.
//
//     rdata          = addr_rdata      (external grouped read value)
//     regOut_ADDRESS = reg_ADDRESS     (raw stored value)

module xs_pmpaddr #(
    parameter int unsigned IDX = 0  // pmp address index (0-based); doc/provenance only
) (
    input         clock,
    input         reset,
    input         w_wen,             // CSR write enable
    input  [63:0] w_wdata,           // CSR write data (only [45:0] retained)
    output [63:0] rdata,             // CSR read data (= external grouped read)
    output [45:0] regOut_ADDRESS,    // raw stored PMP address (= reg_ADDRESS)
    input  [63:0] addr_rdata         // externally-computed grouped read value
);

  reg [45:0] reg_ADDRESS;

  always @(posedge clock or posedge reset) begin
    if (reset)
      reg_ADDRESS <= 46'h0;
    else if (w_wen)
      reg_ADDRESS <= w_wdata[45:0];
  end

  assign rdata          = addr_rdata;
  assign regOut_ADDRESS = reg_ADDRESS;

endmodule
