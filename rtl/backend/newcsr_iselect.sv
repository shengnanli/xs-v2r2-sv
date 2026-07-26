// NewCSR CSR-field primitive: iselect (*iselect indirect-access select CSR).
//
// Faithful, readable, parameterized reimplementation of the golden
// {M,S,VS}iselectModule family. An iselect CSR holds the index used by the
// indirect CSR window (*ireg). The stored value is WIDTH bits; a CSR write only
// takes effect when the top bit of the written index is 0 (golden guard
// `w_wen & ~w_wdata[WIDTH-1]`), keeping the value in the architected legal range.
//
// The `inIMSICRange` output tells NewCSR whether the current select points at
// the IMSIC (AIA external-interrupt) register block. Golden uses two distinct
// range formulas which we carry via the RANGE_HI parameter:
//   * Miselect (WIDTH=9)              : value > 9'h6F  &  ~value[8]
//   * S/VSiselect (WIDTH=13)          : value > 13'h6F & value < 13'h100
// Both reduce to "value in (0x6F, 0x100)". For the 9-bit Miselect the upper
// bound 0x100 is exactly ~value[8] (bit 8 clear); for the 13-bit variants it is
// an explicit `< 13'h100`. We express both uniformly as (value > 0x6F) with the
// upper guard chosen by RANGE_HI so the generated logic is bit-identical to
// golden per instance.
//
//   RANGE_HI = 0 : upper guard = ~value[WIDTH-1]      (Miselect, WIDTH=9)
//   RANGE_HI = 1 : upper guard = (value < 'h100)       (S/VSiselect, WIDTH=13)

module xs_iselect #(
    parameter int WIDTH    = 9,
    parameter bit RANGE_HI = 1'b0
) (
    input               clock,
    input               reset,
    input               w_wen,
    input  [63:0]       w_wdata,
    output [63:0]       rdata,
    output [WIDTH-1:0]  regOut_ALL,
    output              inIMSICRange
);

  reg [WIDTH-1:0] value;

  always @(posedge clock or posedge reset) begin
    if (reset)
      value <= {WIDTH{1'b0}};
    else if (w_wen & ~(w_wdata[WIDTH-1]))
      value <= w_wdata[WIDTH-1:0];
  end

  assign rdata      = {{(64-WIDTH){1'b0}}, value};
  assign regOut_ALL = value;

  // (value > 0x6F) AND upper-range guard (per golden, chosen by RANGE_HI).
  assign inIMSICRange = RANGE_HI
      ? ((value > 13'h6F) & (value < 13'h100))
      : ((value > 9'h6F)  & ~(value[WIDTH-1]));

endmodule
