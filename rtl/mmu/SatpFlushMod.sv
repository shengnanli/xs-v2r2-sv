// SATP/VSATP transition snapshot register.
// Pipeline/control leaf: on either CSR write pulse, capture the pre-transition
// privilege and mode fields and hold them until the next transition.
module SatpFlushMod(
  input        clock,
  input        in_satp_valid,
  input  [3:0] in_satp_bits,
  input        in_vsatp_valid,
  input  [3:0] in_vsatp_bits,
  input  [1:0] in_privState_PRVM,
  input        in_privState_V,
  output [1:0] out_oldPrivState_PRVM,
  output       out_oldPrivState_V,
  output [3:0] out_oldSatpMode,
  output [3:0] out_oldVsatpMode
);
  logic [1:0] old_priv_mode;
  logic old_virtual;
  logic [3:0] old_satp_mode;
  logic [3:0] old_vsatp_mode;
  wire capture = in_satp_valid | in_vsatp_valid;
  always @(posedge clock) begin
    if (capture) begin
      old_priv_mode <= in_privState_PRVM;
      old_virtual <= in_privState_V;
      old_satp_mode <= in_satp_bits;
      old_vsatp_mode <= in_vsatp_bits;
    end
  end
  assign out_oldPrivState_PRVM = old_priv_mode;
  assign out_oldPrivState_V = old_virtual;
  assign out_oldSatpMode = old_satp_mode;
  assign out_oldVsatpMode = old_vsatp_mode;
endmodule
