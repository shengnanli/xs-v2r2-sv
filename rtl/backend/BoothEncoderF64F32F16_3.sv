// =============================================================================
// BoothEncoderF64F32F16_3.sv —— 向量浮点乘加（VectorFloatFMA）的 Booth-4 部分积生成器
//
// 家族薄 wrapper：核 xs_BoothEncoderF64F32F16_core 在 BoothEncoderF64F32F16.sv（机制、几何、
// 怪癖都写在那里）。本变体 PACKED=1：f32 两条通道、f16 四条通道全在，
// 与标量 BoothEncoderF64F32F16（PACKED=0，只留通道 0）是同一份 Scala 的两种用法。
// =============================================================================

module BoothEncoderF64F32F16_3 (
  input  [52:0]  io_in_a,
  input  [52:0]  io_in_b,
  input          io_is_fp64,
  input          io_is_fp32,
  output [106:0] io_out_pp_0,
  output [106:0] io_out_pp_1,
  output [106:0] io_out_pp_2,
  output [106:0] io_out_pp_3,
  output [106:0] io_out_pp_4,
  output [106:0] io_out_pp_5,
  output [106:0] io_out_pp_6,
  output [106:0] io_out_pp_7,
  output [106:0] io_out_pp_8,
  output [106:0] io_out_pp_9,
  output [106:0] io_out_pp_10,
  output [106:0] io_out_pp_11,
  output [106:0] io_out_pp_12,
  output [106:0] io_out_pp_13,
  output [106:0] io_out_pp_14,
  output [106:0] io_out_pp_15,
  output [106:0] io_out_pp_16,
  output [106:0] io_out_pp_17,
  output [106:0] io_out_pp_18,
  output [106:0] io_out_pp_19,
  output [106:0] io_out_pp_20,
  output [106:0] io_out_pp_21,
  output [106:0] io_out_pp_22,
  output [106:0] io_out_pp_23,
  output [106:0] io_out_pp_24,
  output [106:0] io_out_pp_25,
  output [106:0] io_out_pp_26
);
  logic [26:0][106:0] pp;

  xs_BoothEncoderF64F32F16_core #(.PACKED(1'b1)) u_core (
    .in_a    (io_in_a),
    .in_b    (io_in_b),
    .is_fp64 (io_is_fp64),
    .is_fp32 (io_is_fp32),
    .pp      (pp)
  );

  assign io_out_pp_0  = pp[0];
  assign io_out_pp_1  = pp[1];
  assign io_out_pp_2  = pp[2];
  assign io_out_pp_3  = pp[3];
  assign io_out_pp_4  = pp[4];
  assign io_out_pp_5  = pp[5];
  assign io_out_pp_6  = pp[6];
  assign io_out_pp_7  = pp[7];
  assign io_out_pp_8  = pp[8];
  assign io_out_pp_9  = pp[9];
  assign io_out_pp_10 = pp[10];
  assign io_out_pp_11 = pp[11];
  assign io_out_pp_12 = pp[12];
  assign io_out_pp_13 = pp[13];
  assign io_out_pp_14 = pp[14];
  assign io_out_pp_15 = pp[15];
  assign io_out_pp_16 = pp[16];
  assign io_out_pp_17 = pp[17];
  assign io_out_pp_18 = pp[18];
  assign io_out_pp_19 = pp[19];
  assign io_out_pp_20 = pp[20];
  assign io_out_pp_21 = pp[21];
  assign io_out_pp_22 = pp[22];
  assign io_out_pp_23 = pp[23];
  assign io_out_pp_24 = pp[24];
  assign io_out_pp_25 = pp[25];
  assign io_out_pp_26 = pp[26];
endmodule
