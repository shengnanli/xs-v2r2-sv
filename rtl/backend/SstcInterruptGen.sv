// Readable implementation derived from G1-canonical/golden-rtl/SstcInterruptGen.sv.
// Interrupt state is sampled only when the corresponding time/cmp/config input changes.
// Comparisons are formed from the sampled time and compare values without adding state.
module SstcInterruptGen(
  input  logic        clock,
  input  logic        reset,
  input  logic        i_stime_valid,
  input  logic [63:0] i_stime_bits,
  input  logic        i_vstime_valid,
  input  logic [63:0] i_vstime_bits,
  input  logic        i_stimecmp_wen,
  input  logic [63:0] i_stimecmp_rdata,
  input  logic        i_vstimecmp_wen,
  input  logic [63:0] i_vstimecmp_rdata,
  input  logic        i_htimedeltaWen,
  input  logic        i_menvcfg_wen,
  input  logic        i_menvcfg_STCE,
  input  logic        i_henvcfg_wen,
  input  logic        i_henvcfg_STCE,
  output logic        o_STIP,
  output logic        o_VSTIP
);
  logic stip_q;
  logic vstip_q;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      stip_q <= 1'b0;
      vstip_q <= 1'b0;
    end else begin
      if (i_stime_valid || i_stimecmp_wen || i_menvcfg_wen)
        stip_q <= (i_stime_bits >= i_stimecmp_rdata) && i_menvcfg_STCE;
      if (i_vstime_valid || i_vstimecmp_wen || i_htimedeltaWen ||
          i_menvcfg_wen || i_henvcfg_wen)
        vstip_q <= (i_vstime_bits >= i_vstimecmp_rdata) && i_henvcfg_STCE;
    end
  end

  assign o_STIP = stip_q;
  assign o_VSTIP = vstip_q;
endmodule
