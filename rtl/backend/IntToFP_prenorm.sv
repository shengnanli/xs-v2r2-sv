// =============================================================================
// IntToFP_prenorm —— 整数转浮点的预规格化（f32/f64/f16 三个顶层共用）
//
// 位置：fudian IntToFP 闭包第一级，输入原始整数与转换模式，输出
// 「左移对齐后的 63 位有效数 + 左移量 + 零标志 + 符号」给 postnorm 舍入。
//
// 机制（按数据流）：
//   1) 符号判定 in_sign：有符号转换且操作数最高位（long 取 bit63，word 取
//      bit31）为 1。word 有符号时先把低 32 位符号扩展成 64 位（in_raw）。
//   2) 求绝对值 in_abs = in_sign ? ~in_raw+1 : in_raw。
//   3) 前导零计数：正数直接 CLZ(原始输入)；负数走 LZA(~in_raw) + CLZ 的
//      预判通路。预判在「幅值非 2 的幂」时会少数 1（数的是 幅值-1 的最高
//      变化位），lzc_error 用 one-mask 检测：取预判图样的最高 1 做成独热
//      mask，若 in_abs 在该位上恰好是 0，说明真正的最高 1 低一位，左移量
//      要 +1、对齐结果再多移一位。幅值为 2 的幂时预判本来就准，不纠。
//   4) 对齐：in_abs << lzc（127 位中间量），取 [62:0] —— 最高 1 被移进
//      bit63 后丢掉，成为 IEEE 隐藏位；lzc_error 时再多移一位。
//   5) io_out_lzc = lzc + lzc_error（6 位回绕，与 golden 一致）。
//   io_out_is_zero 看的是**原始输入** io_in_int，不是 in_abs（bug-for-bug：
//   word 有符号且高 32 位为垃圾、低 32 位为 0 时 is_zero=0，照抄）。
// 纯组合，无寄存器。子模块：CLZ（rtl/common 已签核）、LZA（本族重写）。
// =============================================================================
module xs_IntToFP_prenorm_core (
  input  logic [63:0] int_in,
  input  logic        sign_en,
  input  logic        long_en,
  output logic [62:0] norm_int,
  output logic [5:0]  lzc_out,
  output logic        is_zero,
  output logic        sign_out
);
  logic        in_sign;
  logic [63:0] in_raw;
  logic [63:0] in_abs;
  logic [63:0] lza_pattern;
  logic [5:0]  pos_lzc;
  logic [5:0]  neg_lzc;
  logic [5:0]  lzc;
  logic [63:0] any_above;
  logic [63:0] first_one;
  logic [63:0] top_one_mask;
  logic        lzc_error;
  logic [126:0] shifted_wide;

  assign in_sign = sign_en & (long_en ? int_in[63] : int_in[31]);
  assign in_raw  = (sign_en & ~long_en) ? {{32{int_in[31]}}, int_in[31:0]}
                                        : int_in;
  assign in_abs  = in_sign ? (~in_raw + 64'd1) : in_raw;

  // 负数预判通路：~in_raw = 幅值-1，相邻位变化图样经 CLZ 得左移量
  LZA lza (
    .io_b(~in_raw),
    .io_f(lza_pattern)
  );
  CLZ pos_lzc_clz (
    .io_in (int_in),
    .io_out(pos_lzc)
  );
  CLZ neg_lzc_clz (
    .io_in (lza_pattern),
    .io_out(neg_lzc)
  );

  assign lzc = in_sign ? neg_lzc : pos_lzc;

  // 预判图样的最高 1 做成独热 mask；图样全 0 时兜底取 bit0
  // （对应 golden one_mask 的 Chisel PriorityMux 兜底分支）。
  // any_above[i] = |lza_pattern[63:i+1]，纯 assign 写开
  // （always_comb 里读后写同一变量会触发 FMR_VLOG-929，FM 拒绝 elaborate）。
  assign any_above[63] = 1'b0;
  for (genvar g = 0; g < 63; g++) begin : gen_any_above
    assign any_above[g] = |lza_pattern[63:g+1];
  end
  assign first_one   = lza_pattern & ~any_above;
  assign top_one_mask = {first_one[63:1], ~any_above[0]};

  assign lzc_error    = in_sign & ~(|(in_abs & top_one_mask));
  assign shifted_wide = {63'h0, in_abs} << lzc;
  assign norm_int     = lzc_error ? {shifted_wide[61:0], 1'b0}
                                  : shifted_wide[62:0];
  assign lzc_out      = lzc_error ? (lzc + 6'd1) : lzc;
  assign is_zero      = (int_in == 64'd0);
  assign sign_out     = in_sign;
endmodule

module IntToFP_prenorm (
  input  logic [63:0] io_in_int,
  input  logic        io_in_sign,
  input  logic        io_in_long,
  output logic [62:0] io_out_norm_int,
  output logic [5:0]  io_out_lzc,
  output logic        io_out_is_zero,
  output logic        io_out_sign
);
  xs_IntToFP_prenorm_core u_core (
    .int_in  (io_in_int),
    .sign_en (io_in_sign),
    .long_en (io_in_long),
    .norm_int(io_out_norm_int),
    .lzc_out (io_out_lzc),
    .is_zero (io_out_is_zero),
    .sign_out(io_out_sign)
  );
endmodule
