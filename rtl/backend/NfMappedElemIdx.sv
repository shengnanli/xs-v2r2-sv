// NfMappedElemIdx maps vector indexed-element element widths to byte ranges.
// Pipeline/control leaf: combinational lookup indexed by nf and one-hot EEW.
// The tables are explicit so each range boundary remains reviewable against G1.

module NfMappedElemIdx(
  input  [2:0] in_nf,
  input  [3:0] in_eewOH,
  output [7:0] out_idxRangeVec_0_from,
  output [7:0] out_idxRangeVec_0_until,
  output [7:0] out_idxRangeVec_1_from,
  output [7:0] out_idxRangeVec_1_until,
  output [7:0] out_idxRangeVec_2_from,
  output [7:0] out_idxRangeVec_2_until,
  output [7:0] out_idxRangeVec_3_from,
  output [7:0] out_idxRangeVec_3_until,
  output [7:0] out_idxRangeVec_4_from,
  output [7:0] out_idxRangeVec_4_until,
  output [7:0] out_idxRangeVec_5_from,
  output [7:0] out_idxRangeVec_5_until,
  output [7:0] out_idxRangeVec_6_from,
  output [7:0] out_idxRangeVec_6_until,
  output [7:0] out_idxRangeVec_7_from,
  output [7:0] out_idxRangeVec_7_until
);

  wire [7:0]      element_stride_0 = {3'h0, in_eewOH[0], in_eewOH[1], in_eewOH[2], in_eewOH[3], 1'h0};
  wire [7:0]      element_stride_1 =
    {2'h0, in_eewOH[0], in_eewOH[1], in_eewOH[2], in_eewOH[3], 2'h0};
  wire [7:0]      element_stride_2 =
    (in_eewOH[0] ? 8'h30 : 8'h0) | (in_eewOH[1] ? 8'h18 : 8'h0)
    | (in_eewOH[2] ? 8'hC : 8'h0) | (in_eewOH[3] ? 8'h6 : 8'h0);
  wire [7:0]      element_stride_3 =
    {1'h0, in_eewOH[0], in_eewOH[1], in_eewOH[2], in_eewOH[3], 3'h0};
  wire [7:0]      element_stride_5 =
    (in_eewOH[0] ? 8'h50 : 8'h0) | (in_eewOH[1] ? 8'h28 : 8'h0)
    | (in_eewOH[2] ? 8'h14 : 8'h0) | (in_eewOH[3] ? 8'hA : 8'h0);
  wire [7:0]      element_stride_6 =
    (in_eewOH[0] ? 8'h60 : 8'h0) | (in_eewOH[1] ? 8'h30 : 8'h0)
    | (in_eewOH[2] ? 8'h18 : 8'h0) | (in_eewOH[3] ? 8'hC : 8'h0);
  wire [7:0]      element_stride_7 =
    (in_eewOH[0] ? 8'h70 : 8'h0) | (in_eewOH[1] ? 8'h38 : 8'h0)
    | (in_eewOH[2] ? 8'h1C : 8'h0) | (in_eewOH[3] ? 8'hE : 8'h0);
  wire [7:0][7:0] ranges_nf1_from =
    {{8'h0}, {8'h0}, {8'h0}, {8'h0}, {8'h0}, {8'h0}, {8'h0}, {element_stride_0}};
  wire [7:0][7:0] ranges_nf1_until =
    {{element_stride_0}, {element_stride_0}, {element_stride_0}, {element_stride_0}, {element_stride_0}, {element_stride_0}, {element_stride_0}, {element_stride_1}};
  wire [7:0][7:0] ranges_nf2_from =
    {{8'h0}, {8'h0}, {8'h0}, {8'h0}, {8'h0}, {8'h0}, {element_stride_0}, {element_stride_1}};
  wire [7:0][7:0] ranges_nf2_until =
    {{element_stride_0}, {element_stride_0}, {element_stride_0}, {element_stride_0}, {element_stride_0}, {element_stride_0}, {element_stride_1}, {element_stride_2}};
  wire [7:0][7:0] ranges_nf3_from =
    {{8'h0}, {8'h0}, {8'h0}, {8'h0}, {8'h0}, {element_stride_0}, {element_stride_0}, {element_stride_2}};
  wire [7:0][7:0] ranges_nf3_until =
    {{element_stride_0}, {element_stride_0}, {element_stride_0}, {element_stride_0}, {element_stride_0}, {element_stride_1}, {element_stride_1}, {element_stride_3}};
  wire [7:0][7:0] ranges_nf4_from =
    {{8'h0}, {8'h0}, {8'h0}, {8'h0}, {element_stride_0}, {element_stride_0}, {element_stride_1}, {element_stride_3}};
  wire [7:0][7:0] ranges_nf4_until =
    {{element_stride_0}, {element_stride_0}, {element_stride_0}, {element_stride_0}, {element_stride_1}, {element_stride_1}, {element_stride_2}, {element_stride_5}};
  wire [7:0][7:0] ranges_nf5_from =
    {{8'h0}, {8'h0}, {8'h0}, {element_stride_0}, {element_stride_0}, {element_stride_0}, {element_stride_1}, {element_stride_5}};
  wire [7:0][7:0] ranges_nf5_until =
    {{element_stride_0}, {element_stride_0}, {element_stride_0}, {element_stride_1}, {element_stride_1}, {element_stride_1}, {element_stride_2}, {element_stride_6}};
  wire [7:0][7:0] ranges_nf6_from =
    {{8'h0}, {8'h0}, {element_stride_0}, {element_stride_0}, {element_stride_0}, {element_stride_1}, {element_stride_2}, {element_stride_6}};
  wire [7:0][7:0] ranges_nf6_until =
    {{element_stride_0}, {element_stride_0}, {element_stride_1}, {element_stride_1}, {element_stride_1}, {element_stride_2}, {element_stride_3}, {element_stride_7}};
  wire [7:0][7:0] ranges_nf7_from =
    {{8'h0}, {element_stride_0}, {element_stride_0}, {element_stride_0}, {element_stride_0}, {element_stride_1}, {element_stride_2}, {element_stride_7}};
  wire [7:0][7:0] ranges_nf7_until =
    {{element_stride_0},
     {element_stride_1},
     {element_stride_1},
     {element_stride_1},
     {element_stride_1},
     {element_stride_2},
     {element_stride_3},
     {{in_eewOH[0], in_eewOH[1], in_eewOH[2], in_eewOH[3], 4'h0}}};
  assign out_idxRangeVec_0_from = 8'h0;
  assign out_idxRangeVec_0_until = element_stride_0;
  assign out_idxRangeVec_1_from = ranges_nf1_from[in_nf];
  assign out_idxRangeVec_1_until = ranges_nf1_until[in_nf];
  assign out_idxRangeVec_2_from = ranges_nf2_from[in_nf];
  assign out_idxRangeVec_2_until = ranges_nf2_until[in_nf];
  assign out_idxRangeVec_3_from = ranges_nf3_from[in_nf];
  assign out_idxRangeVec_3_until = ranges_nf3_until[in_nf];
  assign out_idxRangeVec_4_from = ranges_nf4_from[in_nf];
  assign out_idxRangeVec_4_until = ranges_nf4_until[in_nf];
  assign out_idxRangeVec_5_from = ranges_nf5_from[in_nf];
  assign out_idxRangeVec_5_until = ranges_nf5_until[in_nf];
  assign out_idxRangeVec_6_from = ranges_nf6_from[in_nf];
  assign out_idxRangeVec_6_until = ranges_nf6_until[in_nf];
  assign out_idxRangeVec_7_from = ranges_nf7_from[in_nf];
  assign out_idxRangeVec_7_until = ranges_nf7_until[in_nf];
endmodule
