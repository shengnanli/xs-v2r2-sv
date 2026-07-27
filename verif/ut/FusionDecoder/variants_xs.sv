// FusionDecoder 包装层: golden 同名扁平端口 ↔ xs_FusionDecoder 的数组端口。
// 仅机械打包/拆包, 供 FM 等价对比与 ST 替换。
module FusionDecoder_xs(
  input         clock,
  input         reset,
  input         io_disableFusion,
  input         io_in_0_valid,
  input  [31:0] io_in_0_bits,
  input         io_in_1_valid,
  input  [31:0] io_in_1_bits,
  input         io_in_2_valid,
  input  [31:0] io_in_2_bits,
  input         io_in_3_valid,
  input  [31:0] io_in_3_bits,
  input         io_in_4_valid,
  input  [31:0] io_in_4_bits,
  input         io_in_5_valid,
  input  [31:0] io_in_5_bits,
  input         io_inReady_0,
  input         io_inReady_1,
  input         io_inReady_2,
  input         io_inReady_3,
  input         io_inReady_4,
  input  [8:0]  io_dec_0_fuOpType,
  input  [8:0]  io_dec_1_fuOpType,
  input  [8:0]  io_dec_2_fuOpType,
  input  [8:0]  io_dec_3_fuOpType,
  input  [8:0]  io_dec_4_fuOpType,
  output        io_out_0_valid,
  output        io_out_0_bits_fuType_valid,
  output        io_out_0_bits_fuOpType_valid,
  output [8:0]  io_out_0_bits_fuOpType_bits,
  output        io_out_0_bits_lsrc2_valid,
  output [5:0]  io_out_0_bits_lsrc2_bits,
  output        io_out_0_bits_src2Type_valid,
  output        io_out_0_bits_selImm_valid,
  output [3:0]  io_out_0_bits_selImm_bits,
  output        io_out_1_valid,
  output        io_out_1_bits_fuType_valid,
  output        io_out_1_bits_fuOpType_valid,
  output [8:0]  io_out_1_bits_fuOpType_bits,
  output        io_out_1_bits_lsrc2_valid,
  output [5:0]  io_out_1_bits_lsrc2_bits,
  output        io_out_1_bits_src2Type_valid,
  output        io_out_1_bits_selImm_valid,
  output [3:0]  io_out_1_bits_selImm_bits,
  output        io_out_2_valid,
  output        io_out_2_bits_fuType_valid,
  output        io_out_2_bits_fuOpType_valid,
  output [8:0]  io_out_2_bits_fuOpType_bits,
  output        io_out_2_bits_lsrc2_valid,
  output [5:0]  io_out_2_bits_lsrc2_bits,
  output        io_out_2_bits_src2Type_valid,
  output        io_out_2_bits_selImm_valid,
  output [3:0]  io_out_2_bits_selImm_bits,
  output        io_out_3_valid,
  output        io_out_3_bits_fuType_valid,
  output        io_out_3_bits_fuOpType_valid,
  output [8:0]  io_out_3_bits_fuOpType_bits,
  output        io_out_3_bits_lsrc2_valid,
  output [5:0]  io_out_3_bits_lsrc2_bits,
  output        io_out_3_bits_src2Type_valid,
  output        io_out_3_bits_selImm_valid,
  output [3:0]  io_out_3_bits_selImm_bits,
  output        io_out_4_valid,
  output        io_out_4_bits_fuType_valid,
  output        io_out_4_bits_fuOpType_valid,
  output [8:0]  io_out_4_bits_fuOpType_bits,
  output        io_out_4_bits_lsrc2_valid,
  output [5:0]  io_out_4_bits_lsrc2_bits,
  output        io_out_4_bits_src2Type_valid,
  output        io_out_4_bits_selImm_valid,
  output [3:0]  io_out_4_bits_selImm_bits,
  output        io_info_0_rs2FromRs1,
  output        io_info_0_rs2FromRs2,
  output        io_info_0_rs2FromZero,
  output        io_info_1_rs2FromRs1,
  output        io_info_1_rs2FromRs2,
  output        io_info_1_rs2FromZero,
  output        io_info_2_rs2FromRs1,
  output        io_info_2_rs2FromRs2,
  output        io_info_2_rs2FromZero,
  output        io_info_3_rs2FromRs1,
  output        io_info_3_rs2FromRs2,
  output        io_info_3_rs2FromZero,
  output        io_info_4_rs2FromRs1,
  output        io_info_4_rs2FromRs2,
  output        io_info_4_rs2FromZero,
  output        io_clear_1,
  output        io_clear_2,
  output        io_clear_3,
  output        io_clear_4,
  output        io_clear_5
);

  // ---- 扁平 → 数组(输入) ----
  wire        in_valid  [6];
  wire [31:0] in_bits   [6];
  wire        inReady   [5];
  wire [8:0]  dec_fuOpType [5];
  assign in_valid[0] = io_in_0_valid;  assign in_bits[0] = io_in_0_bits;
  assign in_valid[1] = io_in_1_valid;  assign in_bits[1] = io_in_1_bits;
  assign in_valid[2] = io_in_2_valid;  assign in_bits[2] = io_in_2_bits;
  assign in_valid[3] = io_in_3_valid;  assign in_bits[3] = io_in_3_bits;
  assign in_valid[4] = io_in_4_valid;  assign in_bits[4] = io_in_4_bits;
  assign in_valid[5] = io_in_5_valid;  assign in_bits[5] = io_in_5_bits;
  assign inReady[0] = io_inReady_0;  assign inReady[1] = io_inReady_1;
  assign inReady[2] = io_inReady_2;  assign inReady[3] = io_inReady_3;
  assign inReady[4] = io_inReady_4;
  assign dec_fuOpType[0] = io_dec_0_fuOpType;  assign dec_fuOpType[1] = io_dec_1_fuOpType;
  assign dec_fuOpType[2] = io_dec_2_fuOpType;  assign dec_fuOpType[3] = io_dec_3_fuOpType;
  assign dec_fuOpType[4] = io_dec_4_fuOpType;

  // ---- 数组 → 扁平(输出) ----
  wire        out_valid          [5];
  wire        out_fuType_valid   [5];
  wire        out_fuOpType_valid [5];
  wire [8:0]  out_fuOpType_bits  [5];
  wire        out_lsrc2_valid    [5];
  wire [5:0]  out_lsrc2_bits     [5];
  wire        out_src2Type_valid [5];
  wire        out_selImm_valid   [5];
  wire [3:0]  out_selImm_bits    [5];
  wire        info_rs2FromRs1    [5];
  wire        info_rs2FromRs2    [5];
  wire        info_rs2FromZero   [5];
  wire        clear              [5];

  assign io_out_0_valid = out_valid[0];
  assign io_out_0_bits_fuType_valid    = out_fuType_valid[0];
  assign io_out_0_bits_fuOpType_valid  = out_fuOpType_valid[0];
  assign io_out_0_bits_fuOpType_bits   = out_fuOpType_bits[0];
  assign io_out_0_bits_lsrc2_valid     = out_lsrc2_valid[0];
  assign io_out_0_bits_lsrc2_bits      = out_lsrc2_bits[0];
  assign io_out_0_bits_src2Type_valid  = out_src2Type_valid[0];
  assign io_out_0_bits_selImm_valid    = out_selImm_valid[0];
  assign io_out_0_bits_selImm_bits     = out_selImm_bits[0];
  assign io_out_1_valid = out_valid[1];
  assign io_out_1_bits_fuType_valid    = out_fuType_valid[1];
  assign io_out_1_bits_fuOpType_valid  = out_fuOpType_valid[1];
  assign io_out_1_bits_fuOpType_bits   = out_fuOpType_bits[1];
  assign io_out_1_bits_lsrc2_valid     = out_lsrc2_valid[1];
  assign io_out_1_bits_lsrc2_bits      = out_lsrc2_bits[1];
  assign io_out_1_bits_src2Type_valid  = out_src2Type_valid[1];
  assign io_out_1_bits_selImm_valid    = out_selImm_valid[1];
  assign io_out_1_bits_selImm_bits     = out_selImm_bits[1];
  assign io_out_2_valid = out_valid[2];
  assign io_out_2_bits_fuType_valid    = out_fuType_valid[2];
  assign io_out_2_bits_fuOpType_valid  = out_fuOpType_valid[2];
  assign io_out_2_bits_fuOpType_bits   = out_fuOpType_bits[2];
  assign io_out_2_bits_lsrc2_valid     = out_lsrc2_valid[2];
  assign io_out_2_bits_lsrc2_bits      = out_lsrc2_bits[2];
  assign io_out_2_bits_src2Type_valid  = out_src2Type_valid[2];
  assign io_out_2_bits_selImm_valid    = out_selImm_valid[2];
  assign io_out_2_bits_selImm_bits     = out_selImm_bits[2];
  assign io_out_3_valid = out_valid[3];
  assign io_out_3_bits_fuType_valid    = out_fuType_valid[3];
  assign io_out_3_bits_fuOpType_valid  = out_fuOpType_valid[3];
  assign io_out_3_bits_fuOpType_bits   = out_fuOpType_bits[3];
  assign io_out_3_bits_lsrc2_valid     = out_lsrc2_valid[3];
  assign io_out_3_bits_lsrc2_bits      = out_lsrc2_bits[3];
  assign io_out_3_bits_src2Type_valid  = out_src2Type_valid[3];
  assign io_out_3_bits_selImm_valid    = out_selImm_valid[3];
  assign io_out_3_bits_selImm_bits     = out_selImm_bits[3];
  assign io_out_4_valid = out_valid[4];
  assign io_out_4_bits_fuType_valid    = out_fuType_valid[4];
  assign io_out_4_bits_fuOpType_valid  = out_fuOpType_valid[4];
  assign io_out_4_bits_fuOpType_bits   = out_fuOpType_bits[4];
  assign io_out_4_bits_lsrc2_valid     = out_lsrc2_valid[4];
  assign io_out_4_bits_lsrc2_bits      = out_lsrc2_bits[4];
  assign io_out_4_bits_src2Type_valid  = out_src2Type_valid[4];
  assign io_out_4_bits_selImm_valid    = out_selImm_valid[4];
  assign io_out_4_bits_selImm_bits     = out_selImm_bits[4];

  assign io_info_0_rs2FromRs1  = info_rs2FromRs1[0];
  assign io_info_0_rs2FromRs2  = info_rs2FromRs2[0];
  assign io_info_0_rs2FromZero = info_rs2FromZero[0];
  assign io_info_1_rs2FromRs1  = info_rs2FromRs1[1];
  assign io_info_1_rs2FromRs2  = info_rs2FromRs2[1];
  assign io_info_1_rs2FromZero = info_rs2FromZero[1];
  assign io_info_2_rs2FromRs1  = info_rs2FromRs1[2];
  assign io_info_2_rs2FromRs2  = info_rs2FromRs2[2];
  assign io_info_2_rs2FromZero = info_rs2FromZero[2];
  assign io_info_3_rs2FromRs1  = info_rs2FromRs1[3];
  assign io_info_3_rs2FromRs2  = info_rs2FromRs2[3];
  assign io_info_3_rs2FromZero = info_rs2FromZero[3];
  assign io_info_4_rs2FromRs1  = info_rs2FromRs1[4];
  assign io_info_4_rs2FromRs2  = info_rs2FromRs2[4];
  assign io_info_4_rs2FromZero = info_rs2FromZero[4];

  assign io_clear_1 = clear[0];
  assign io_clear_2 = clear[1];
  assign io_clear_3 = clear[2];
  assign io_clear_4 = clear[3];
  assign io_clear_5 = clear[4];

  xs_FusionDecoder u_core (
    .clock         (clock),
    .reset         (reset),
    .disableFusion (io_disableFusion),
    .in_valid      (in_valid),
    .in_bits       (in_bits),
    .inReady       (inReady),
    .dec_fuOpType  (dec_fuOpType),
    .out_valid          (out_valid),
    .out_fuType_valid   (out_fuType_valid),
    .out_fuOpType_valid (out_fuOpType_valid),
    .out_fuOpType_bits  (out_fuOpType_bits),
    .out_lsrc2_valid    (out_lsrc2_valid),
    .out_lsrc2_bits     (out_lsrc2_bits),
    .out_src2Type_valid (out_src2Type_valid),
    .out_selImm_valid   (out_selImm_valid),
    .out_selImm_bits    (out_selImm_bits),
    .info_rs2FromRs1    (info_rs2FromRs1),
    .info_rs2FromRs2    (info_rs2FromRs2),
    .info_rs2FromZero   (info_rs2FromZero),
    .clear              (clear)
  );

endmodule
