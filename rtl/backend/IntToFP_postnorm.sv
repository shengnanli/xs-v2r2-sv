// =============================================================================
// IntToFP_postnorm —— 整数转 f32 的舍入与 IEEE754 拼装
//
// 位置：fudian IntToFP 闭包第二级，接 prenorm 的「63 位有效数（最高 1 已
// 移进 bit63 作隐藏位并被丢掉）+ 左移量 + 零标志 + 符号」，调用
// RoundingUnit（codex lane 所有，两侧 golden-reuse）按 rm 舍入到
// f32 精度，拼出 {符号, 指数, 尾数}。
//
// 机制：
//   1) 切分：保留位 norm_int[62:40]、舍入位 norm_int[39]、
//      粘滞位 |norm_int[38:0]，连同符号与 rm 一起进 RoundingUnit。
//   2) 指数：fp_exp = (偏置+63) - lzc + 舍入进位；零输入时恒 0（与零尾数
//      拼出 ±0）。11 位中间宽度照抄 golden。
//   3) 上溢：fp_exp > 11'hFE（f32 最大有限指数 254 之外即上溢）。上溢时按 rm 选「最大有限值」（RTZ 恒取；
//      RDN 对正数、RUP 对负数也取——方向舍入不越过无穷）或「无穷」。
//   4) fflags = {nv=0, dz=0, of, uf=0, nx=of|inexact}。
// 纯组合，无寄存器。
// =============================================================================
module xs_IntToFP_postnorm_core (
  input  logic [62:0]        norm_int,
  input  logic [5:0]         lzc,
  input  logic               is_zero,
  input  logic               sign_in,
  input  logic [2:0]         rm,
  output logic [31:0]        result,
  output logic [4:0]         fflags
);
  logic [22:0] sig_rounded;
  logic        round_inexact;
  logic        round_cout;
  logic [10:0] fp_exp;
  logic        overflow;
  logic        sat_to_max;

  RoundingUnit rounder (
    .io_in       (norm_int[62:40]),
    .io_roundIn  (norm_int[39]),
    .io_stickyIn (|norm_int[38:0]),
    .io_signIn   (sign_in),
    .io_rm       (rm),
    .io_out      (sig_rounded),
    .io_inexact  (round_inexact),
    .io_cout     (round_cout)
  );

  assign fp_exp = is_zero ? 11'h0
                          : (11'hBE - {5'h0, lzc}) + {10'h0, round_cout};
  assign overflow   = fp_exp > 11'hFE;
  assign sat_to_max = (rm == 3'h1) | (sign_in & (rm == 3'h3))
                      | (~sign_in & (rm == 3'h2));
  assign result = {sign_in,
                   overflow ? (sat_to_max ? 31'h7F7FFFFF : 31'h7F800000)
                            : {fp_exp[7:0], sig_rounded}};
  assign fflags = {2'h0, overflow, 1'h0, overflow | round_inexact};
endmodule

module IntToFP_postnorm (
  input  logic [62:0]        io_in_norm_int,
  input  logic [5:0]         io_in_lzc,
  input  logic               io_in_is_zero,
  input  logic               io_in_sign,
  input  logic [2:0]         io_rm,
  output logic [31:0]        io_result,
  output logic [4:0]         io_fflags
);
  xs_IntToFP_postnorm_core u_core (
    .norm_int (io_in_norm_int),
    .lzc      (io_in_lzc),
    .is_zero  (io_in_is_zero),
    .sign_in  (io_in_sign),
    .rm       (io_rm),
    .result   (io_result),
    .fflags   (io_fflags)
  );
endmodule
