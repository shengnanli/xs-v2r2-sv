// =============================================================================
// BoothEncoderF64F32F16.sv —— 浮点乘加的 Booth-4 部分积生成器（标量 FloatFMA 与向量 VectorFloatFMA 共用核）
//
// 位置：乘加单元第 0 拍。一个 64 位数据块里可以并排放 1 个 f64 / 2 个 f32 / 4 个 f16，
//   它们的有效数（含隐含位）被父模块摆在 53 位输入的固定位置上：
//       f64 : [52:0]
//       f32 : [23:0]  [52:29]                       （24 位 × 2）
//       f16 : [10:0]  [23:13]  [39:29]  [52:42]     （11 位 × 4）
//   本模块纯组合：把 in_b 按 Booth-4（每 2 位一个数字，取值 -2..+2）重编码，对 in_a 生成
//   27 个 107 位"加数"（部分积 + 符号扩展技巧 + 上一项的补 1 位），交给后面的 CSA 压缩树。
//   同一棵 107 位的树同时算出所有元素的乘积：各元素（"通道"）的加数只占 107 位里自己那一段，
//       f64 : 乘积 106 位，占 [106:0]
//       f32 : 乘积  48 位，通道 0 占 [48:0]、通道 1 占 [106:58]
//       f16 : 乘积  22 位，通道 0..3 分别从第 0 / 26 / 58 / 84 位起，各 23 位
//   Scala：yunsuan/src/main/scala/yunsuan/vector/VectorFloatFMA.scala 与
//   yunsuan/src/main/scala/yunsuan/fpu/FloatFMA.scala 的 BoothEncoderF64F32F16
//   （width=53, is_addend_expand_1bit=true）。
//
// 两个 golden 变体 = 同一个核的两种通道数（参数 PACKED）：
//   BoothEncoderF64F32F16_3（向量，PACKED=1）：f32 两条、f16 四条通道都在；
//   BoothEncoderF64F32F16  （标量，PACKED=0）：每种格式只有通道 0。标量 Scala 把乘数写成
//     f32: {30'h0, b[23:0], 0}、f16: {43'h0, b[10:0], 0}，并把通道 0 以外的数字整项写 0 ——
//     效果就是"向量版只留通道 0"，下面用同一份通道几何表达。本文件是该家族的核文件，
//     BoothEncoderF64F32F16_3.sv 只是一个设参数的薄 wrapper。
//
// 机制（一个通道内，有效数宽 W，数字个数 N = W/2 + 1，加数宽 2W+1）：
//   1. 数字 k 看乘数的 {b[2k+1], b[2k], b[2k-1]}（b[-1]=0），译成 +1 / +2 / -1 / -2 / 0 五选一。
//   2. 部分积 pp（W+1 位）= 0 / a / 2a / ~a / ~(2a)。负数用"按位取反"表示，欠的 +1（neg 位）
//      不在本项里加，而是塞进**下一项**的低位（下一项左移 2 位后正好空出两位：{0, neg_prev}）。
//   3. 符号扩展不真的把符号位铺满高位，而用经典的"高位补常数 1 + 符号位取反"技巧：
//         第 0 项           : { ~neg, neg, neg, pp }
//         中间项 k          : { 1, ~neg, pp, 0, neg_prev } << 2(k-1)
//         最后一项（W 奇数）: { 1,       pp, 0, neg_prev } << 2(k-1)     最高数字只可能是 0/+1
//         最后一项（W 偶数）: { pp[W-1:0],   0, neg_prev } << 2(k-1)     同上，且 pp 最高位用不到
//
// 怪癖（照 golden，不"修"）：
//   1. 数字下标在三种格式间共用同一组 27 个译码器：乘数先按格式重排成 54 位，通道之间垫 0，
//      使每个通道的第 0 个数字看到的 b[-1] 是 0、最后一个数字看到的高位是 0。
//      f32 通道 0/1 用数字 0..12 / 14..26；f16 通道 0..3 用数字 0..5 / 7..12 / 14..19 / 21..26。
//      没被任何通道用到的数字（向量 f32 的 13；f16 的 6、13、20；标量里通道 0 之外的全部）输出恒 0。
//   2. 最后一项不带自己的 neg 位（最高数字非负），所以整个通道最后一项"欠的 +1"不存在；
//      但倒数第二项的 neg 仍由最后一项的低位带上。
// =============================================================================

// 一个通道的 Booth-4 加数生成：W 位被乘数、N 个已译码的数字 -> N 个 (2W+1) 位加数。
module xs_BoothAddendLane #(
  parameter int unsigned W = 53,          // 有效数位宽（含隐含位）
  parameter int unsigned N = W / 2 + 1    // Booth 数字个数
) (
  input  logic [W-1:0]            multiplicand,
  input  logic [N-1:0]            sel_pos1,   // 数字 = +1
  input  logic [N-1:0]            sel_pos2,   // 数字 = +2
  input  logic [N-1:0]            sel_neg1,   // 数字 = -1
  input  logic [N-1:0]            sel_neg2,   // 数字 = -2
  output logic [N-1:0][2*W:0]     addend
);
  localparam int unsigned AW = 2 * W + 1;

  logic [N-1:0][W:0] pp;    // 部分积：负数是按位取反，欠的 +1 由 neg 位另行补
  logic [N-1:0]      neg;

  for (genvar k = 0; k < N; k++) begin : g_digit
    assign neg[k] = sel_neg1[k] | sel_neg2[k];
    assign pp[k]  = ({(W+1){sel_pos1[k]}} & {1'b0, multiplicand})
                  | ({(W+1){sel_pos2[k]}} & {multiplicand, 1'b0})
                  | ({(W+1){sel_neg1[k]}} & {1'b1, ~multiplicand})
                  | ({(W+1){sel_neg2[k]}} & {~multiplicand, 1'b1});

    if (k == 0) begin : g_first
      assign addend[k] = AW'({~neg[k], neg[k], neg[k], pp[k]});
    end else if (k < N - 1) begin : g_mid
      assign addend[k] = AW'({1'b1, ~neg[k], pp[k], 1'b0, neg[k-1]}) << (2 * (k - 1));
    end else if (W % 2 == 1) begin : g_last_odd
      assign addend[k] = AW'({1'b1, pp[k], 1'b0, neg[k-1]}) << (2 * (k - 1));
    end else begin : g_last_even
      assign addend[k] = AW'({pp[k][W-1:0], 1'b0, neg[k-1]}) << (2 * (k - 1));
    end
  end
endmodule

module xs_BoothEncoderF64F32F16_core #(
  parameter bit PACKED = 1'b1             // 1：向量（f32×2、f16×4）；0：标量（每种格式只有通道 0）
) (
  input  logic [52:0]          in_a,      // 被乘数有效数（按格式摆位，见文件头）
  input  logic [52:0]          in_b,      // 乘数有效数
  input  logic                 is_fp64,
  input  logic                 is_fp32,   // 两者都为 0 即 f16
  output logic [26:0][106:0]   pp         // 27 个加数
);
  localparam int unsigned NUM_DIGIT = 27;
  localparam int unsigned SUM_W     = 107;

  // 各格式的通道几何：有效数宽 / 每通道数字个数 / 通道数
  localparam int unsigned F64_W = 53, F64_N = 27;
  localparam int unsigned F32_W = 24, F32_N = 13, F32_LANES = PACKED ? 2 : 1;
  localparam int unsigned F16_W = 11, F16_N = 6,  F16_LANES = PACKED ? 4 : 1;
  // 通道 l 的：有效数在 53 位输入里的起始位 / 第 0 个数字的全局下标 / 加数在 107 位里的起始位
  localparam int unsigned F32_SIG_LSB   [2] = '{0, 29};
  localparam int unsigned F32_DIGIT_BASE[2] = '{0, 14};
  localparam int unsigned F32_SUM_LSB   [2] = '{0, 58};
  localparam int unsigned F16_SIG_LSB   [4] = '{0, 13, 29, 42};
  localparam int unsigned F16_DIGIT_BASE[4] = '{0, 7, 14, 21};
  localparam int unsigned F16_SUM_LSB   [4] = '{0, 26, 58, 84};

  // ---------------------------------------------------------------------------
  // §1 乘数重排 + Booth-4 译码（27 个译码器三种格式共用）
  //    multiplier_ext[0] 是 b[-1]=0；通道之间垫的 0 让相邻通道互不"看见"对方的位。
  //    （标量版的 f32/f16 只有通道 0，它的数字窗口看到的位与这里完全相同；其余数字的加数整项为 0，
  //     窗口里是什么都无所谓。）
  // ---------------------------------------------------------------------------
  logic [54:0] multiplier_ext;
  always_comb begin
    if (is_fp64) begin
      multiplier_ext = {1'b0, in_b, 1'b0};
    end else if (is_fp32) begin
      multiplier_ext = {2'b0, in_b[52:29], 4'b0, in_b[23:0], 1'b0};
    end else begin
      multiplier_ext = {1'b0, in_b[52:42], 3'b0, in_b[39:29], 3'b0, in_b[23:13], 3'b0, in_b[10:0], 1'b0};
    end
  end

  logic [NUM_DIGIT-1:0] sel_pos1, sel_pos2, sel_neg1, sel_neg2;
  for (genvar i = 0; i < NUM_DIGIT; i++) begin : g_decode
    logic [2:0] window;
    assign window      = multiplier_ext[2*i+2 : 2*i];
    assign sel_pos1[i] = (window == 3'b001) || (window == 3'b010);
    assign sel_pos2[i] = (window == 3'b011);
    assign sel_neg2[i] = (window == 3'b100);
    assign sel_neg1[i] = (window == 3'b101) || (window == 3'b110);
  end

  // ---------------------------------------------------------------------------
  // §2 三种格式各自的加数，摆到 107 位里各通道自己的那一段；没有通道使用的数字恒 0
  // ---------------------------------------------------------------------------
  logic [NUM_DIGIT-1:0][SUM_W-1:0] addend_f64;
  logic [NUM_DIGIT-1:0][SUM_W-1:0] addend_f32;
  logic [NUM_DIGIT-1:0][SUM_W-1:0] addend_f16;

  xs_BoothAddendLane #(.W(F64_W), .N(F64_N)) u_lane_f64 (
    .multiplicand (in_a),
    .sel_pos1     (sel_pos1),
    .sel_pos2     (sel_pos2),
    .sel_neg1     (sel_neg1),
    .sel_neg2     (sel_neg2),
    .addend       (addend_f64)
  );

  logic [F32_LANES-1:0][F32_N-1:0][2*F32_W:0] lane_addend_f32;
  logic [F16_LANES-1:0][F16_N-1:0][2*F16_W:0] lane_addend_f16;

  for (genvar l = 0; l < F32_LANES; l++) begin : g_f32
    localparam int unsigned D0 = F32_DIGIT_BASE[l];
    xs_BoothAddendLane #(.W(F32_W), .N(F32_N)) u_lane (
      .multiplicand (in_a[F32_SIG_LSB[l] +: F32_W]),
      .sel_pos1     (sel_pos1[D0 +: F32_N]),
      .sel_pos2     (sel_pos2[D0 +: F32_N]),
      .sel_neg1     (sel_neg1[D0 +: F32_N]),
      .sel_neg2     (sel_neg2[D0 +: F32_N]),
      .addend       (lane_addend_f32[l])
    );
  end

  for (genvar l = 0; l < F16_LANES; l++) begin : g_f16
    localparam int unsigned D0 = F16_DIGIT_BASE[l];
    xs_BoothAddendLane #(.W(F16_W), .N(F16_N)) u_lane (
      .multiplicand (in_a[F16_SIG_LSB[l] +: F16_W]),
      .sel_pos1     (sel_pos1[D0 +: F16_N]),
      .sel_pos2     (sel_pos2[D0 +: F16_N]),
      .sel_neg1     (sel_neg1[D0 +: F16_N]),
      .sel_neg2     (sel_neg2[D0 +: F16_N]),
      .addend       (lane_addend_f16[l])
    );
  end

  always_comb begin
    addend_f32 = '0;
    for (int unsigned l = 0; l < F32_LANES; l++) begin
      for (int unsigned k = 0; k < F32_N; k++) begin
        addend_f32[F32_DIGIT_BASE[l] + k] = SUM_W'(lane_addend_f32[l][k]) << F32_SUM_LSB[l];
      end
    end
    addend_f16 = '0;
    for (int unsigned l = 0; l < F16_LANES; l++) begin
      for (int unsigned k = 0; k < F16_N; k++) begin
        addend_f16[F16_DIGIT_BASE[l] + k] = SUM_W'(lane_addend_f16[l][k]) << F16_SUM_LSB[l];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // §3 按格式选出
  // ---------------------------------------------------------------------------
  assign pp = is_fp64 ? addend_f64 : (is_fp32 ? addend_f32 : addend_f16);
endmodule

module BoothEncoderF64F32F16 (
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

  xs_BoothEncoderF64F32F16_core #(.PACKED(1'b0)) u_core (
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
