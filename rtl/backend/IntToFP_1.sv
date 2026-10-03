// =============================================================================
// IntToFP_1 —— 64/32 位整数转 f64（纯组合顶层）
//
// 位置：fudian 整数转浮点闭包的 f64 顶层，被 FCVT 等执行单元例化。
// 结构就是两级直连：IntToFP_prenorm（取绝对值、数前导零、左移对齐）接
// IntToFP_postnorm_1（按 rm 舍入并拼 IEEE754）。
// golden 本模块没有任何寄存器/时钟/复位 —— 纯组合，照抄。
//
// 输入：io_int 原始整数；io_sign=1 有符号转换；io_long=1 按 64 位、=0 按
// 32 位（word）；io_rm 舍入模式（RNE/RTZ/RDN/RUP/RMM）。
// 输出：io_result = {符号, 指数, 尾数}；io_fflags 只可能置 OF/NX。
// =============================================================================
module xs_IntToFP_1_core (
  input  logic [63:0]        int_in,
  input  logic               sign_en,
  input  logic               long_en,
  input  logic [2:0]         rm,
  output logic [63:0]        result,
  output logic [4:0]         fflags
);
  logic [62:0] norm_int;
  logic [5:0]  lzc;
  logic        is_zero;
  logic        sign_mid;

  IntToFP_prenorm pre_norm (
    .io_in_int       (int_in),
    .io_in_sign      (sign_en),
    .io_in_long      (long_en),
    .io_out_norm_int (norm_int),
    .io_out_lzc      (lzc),
    .io_out_is_zero  (is_zero),
    .io_out_sign     (sign_mid)
  );
  IntToFP_postnorm_1 post_norm (
    .io_in_norm_int (norm_int),
    .io_in_lzc      (lzc),
    .io_in_is_zero  (is_zero),
    .io_in_sign     (sign_mid),
    .io_rm          (rm),
    .io_result      (result),
    .io_fflags      (fflags)
  );
endmodule

module IntToFP_1 (
  input  logic [63:0]        io_int,
  input  logic               io_sign,
  input  logic               io_long,
  input  logic [2:0]         io_rm,
  output logic [63:0]        io_result,
  output logic [4:0]         io_fflags
);
  xs_IntToFP_1_core u_core (
    .int_in (io_int),
    .sign_en(io_sign),
    .long_en(io_long),
    .rm     (io_rm),
    .result (io_result),
    .fflags (io_fflags)
  );
endmodule
