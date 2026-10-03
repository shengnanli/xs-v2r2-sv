// =============================================================================
// SRT4qdsCons —— 整数 SRT 除法的 QDS 比较常数查表（SRT16Divint{,_4,_6} 使用）
//
// 按除数高 3 位 io_d_trunc_3 查表产出四档 9 位比较常数
//   io_m_neg_1/io_m_neg_0/io_m_pos_1/io_m_pos_2（二进制补码；pos_* 为负值）。
// 注意 golden 的压缩数组字面量 '{a,b,...} 首元素对应**最高**下标（[7]）——
//   本文件 LUT 一律按下标 0..7 顺序书写并注释有符号十进制，避免 cat 方向误读。
// 结构：golden 端口 -> xs_SRT4qdsCons_core（可读核）-> 直接出。纯组合。
// 自动生成：scripts/gen_srt_divsqrt_leaves10.py —— 勿手改
// =============================================================================

module xs_SRT4qdsCons_core (
  input  logic [2:0] divisor_top3,
  output logic [8:0] cmp_neg_1,
  output logic [8:0] cmp_neg_0,
  output logic [8:0] cmp_pos_1,
  output logic [8:0] cmp_pos_2
);
  // 四张 8 行 LUT，按下标 0..7 书写；右侧注释是有符号十进制读法
  localparam logic [8:0] LUT_NEG_1 [0:7] =
    '{9'h034, 9'h03C, 9'h040, 9'h048, 9'h04C, 9'h054, 9'h058, 9'h060};  // +52,+60,+64,+72,+76,+84,+88,+96
  localparam logic [8:0] LUT_NEG_0 [0:7] =
    '{9'h010, 9'h018, 9'h018, 9'h018, 9'h020, 9'h020, 9'h020, 9'h020};  // +16,+24,+24,+24,+32,+32,+32,+32
  localparam logic [8:0] LUT_POS_1 [0:7] =
    '{9'h1F4, 9'h1F0, 9'h1F0, 9'h1F0, 9'h1EC, 9'h1E8, 9'h1E8, 9'h1E8};  // -12,-16,-16,-16,-20,-24,-24,-24
  localparam logic [8:0] LUT_POS_2 [0:7] =
    '{9'h1D0, 9'h1C8, 9'h1C4, 9'h1BC, 9'h1B8, 9'h1B0, 9'h1AC, 9'h1A4};  // -48,-56,-60,-68,-72,-80,-84,-92

  assign cmp_neg_1 = LUT_NEG_1[divisor_top3];
  assign cmp_neg_0 = LUT_NEG_0[divisor_top3];
  assign cmp_pos_1 = LUT_POS_1[divisor_top3];
  assign cmp_pos_2 = LUT_POS_2[divisor_top3];
endmodule

module SRT4qdsCons (
  input  logic [2:0] io_d_trunc_3,
  output logic [8:0] io_m_neg_1,
  output logic [8:0] io_m_neg_0,
  output logic [8:0] io_m_pos_1,
  output logic [8:0] io_m_pos_2
);
  xs_SRT4qdsCons_core u_core (
    .divisor_top3 (io_d_trunc_3),
    .cmp_neg_1    (io_m_neg_1),
    .cmp_neg_0    (io_m_neg_0),
    .cmp_pos_1    (io_m_pos_1),
    .cmp_pos_2    (io_m_pos_2)
  );
endmodule
