#!/usr/bin/env python3
"""Generate the eight readable IntToFP-conversion-closure leaves.

Family B of the kimi/k3-next20 lane: LZA, IntToFP_prenorm,
IntToFP_postnorm{,_1,_2} and IntToFP{,_1,_2}.  All eight golden modules
are purely combinational (no clock/reset anywhere in the closure), so the
rewrites are combinational cores behind exact-port wrappers.
RoundingUnit{,_1,_2} are owned by another lane and reused as golden on
both sides (see verif/ut/IntToFPLeaves8/Makefile RTL_GOLDEN_DEPS).
"""

import argparse
from pathlib import Path


RTL_DIR = Path(__file__).resolve().parents[1] / "rtl/backend"


LZA = '''// =============================================================================
// LZA —— 前导 1 位置图样（Leading Zero Anticipator 在加数 a=0 时的退化形态）
//
// 位置：fudian 整数转浮点闭包的最底层，只被 IntToFP_prenorm 例化。
// 输入 io_b 恒为「~原码」（负数的绝对值减 1），输出 io_f 供 CLZ 数前导零。
//
// 核心机制：io_f[i] = io_b[i] ^ io_b[i-1]（i >= 1），io_f[0] 恒 0。
// 相邻位异或标出「从最高位往下第一个位值发生变化的位置」：对 io_b = 幅值-1
// 而言，这个位置要么是幅值最高 1 本身，要么是它上面一位（幅值非 2 的幂时），
// 调用方（IntToFP_prenorm）用 one-mask 检测后一种情况并纠正。
// 纯组合，无寄存器、无子模块。
// =============================================================================
module xs_LZA_core (
  input  logic [63:0] operand_b,
  output logic [63:0] change_pattern
);
  assign change_pattern = {operand_b[63:1] ^ operand_b[62:0], 1'b0};
endmodule

module LZA (
  input  logic [63:0] io_b,
  output logic [63:0] io_f
);
  xs_LZA_core u_core (
    .operand_b     (io_b),
    .change_pattern(io_f)
  );
endmodule
'''


PRENORM = '''// =============================================================================
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
'''


def postnorm(variant: str, res_w: int, exp_w: int, sig_w: int,
             exp_bias63: str, of_expr: str, sat_max: str, sat_inf: str,
             exp_slice: str, fmt_name: str) -> str:
    """One postnorm variant: round the normalized significand, assemble IEEE.

    res_w: io_result width; exp_w: exponent field width; sig_w: kept
    significand bits below the hidden bit; exp_bias63: (bias+63) literal;
    of_expr: golden overflow predicate on fp_exp; sat_max/sat_inf: golden
    saturation payloads (result minus sign); exp_slice: exponent slice used
    in the non-overflow assembly.
    """
    round_bit = 62 - sig_w
    sticky_hi = round_bit - 1
    return f'''// =============================================================================
// IntToFP_postnorm{variant} —— 整数转 {fmt_name} 的舍入与 IEEE754 拼装
//
// 位置：fudian IntToFP 闭包第二级，接 prenorm 的「63 位有效数（最高 1 已
// 移进 bit63 作隐藏位并被丢掉）+ 左移量 + 零标志 + 符号」，调用
// RoundingUnit{variant}（codex lane 所有，两侧 golden-reuse）按 rm 舍入到
// {fmt_name} 精度，拼出 {{符号, 指数, 尾数}}。
//
// 机制：
//   1) 切分：保留位 norm_int[62:{round_bit + 1}]、舍入位 norm_int[{round_bit}]、
//      粘滞位 |norm_int[{sticky_hi}:0]，连同符号与 rm 一起进 RoundingUnit。
//   2) 指数：fp_exp = (偏置+63) - lzc + 舍入进位；零输入时恒 0（与零尾数
//      拼出 ±0）。11 位中间宽度照抄 golden。
//   3) 上溢：{{of_expr_comment}}。上溢时按 rm 选「最大有限值」（RTZ 恒取；
//      RDN 对正数、RUP 对负数也取——方向舍入不越过无穷）或「无穷」。
//   4) fflags = {{nv=0, dz=0, of, uf=0, nx=of|inexact}}。
// 纯组合，无寄存器。
// =============================================================================
module xs_IntToFP_postnorm{variant}_core (
  input  logic [62:0]        norm_int,
  input  logic [5:0]         lzc,
  input  logic               is_zero,
  input  logic               sign_in,
  input  logic [2:0]         rm,
  output logic [{res_w - 1}:0]        result,
  output logic [4:0]         fflags
);
  logic [{sig_w - 1}:0] sig_rounded;
  logic        round_inexact;
  logic        round_cout;
  logic [10:0] fp_exp;
  logic        overflow;
  logic        sat_to_max;

  RoundingUnit{variant} rounder (
    .io_in       (norm_int[62:{round_bit + 1}]),
    .io_roundIn  (norm_int[{round_bit}]),
    .io_stickyIn (|norm_int[{sticky_hi}:0]),
    .io_signIn   (sign_in),
    .io_rm       (rm),
    .io_out      (sig_rounded),
    .io_inexact  (round_inexact),
    .io_cout     (round_cout)
  );

  assign fp_exp = is_zero ? 11'h0
                          : ({exp_bias63} - {{5'h0, lzc}}) + {{10'h0, round_cout}};
  assign overflow   = {of_expr};
  assign sat_to_max = (rm == 3'h1) | (sign_in & (rm == 3'h3))
                      | (~sign_in & (rm == 3'h2));
  assign result = {{sign_in,
                   overflow ? (sat_to_max ? {sat_max} : {sat_inf})
                            : {{{exp_slice}, sig_rounded}}}};
  assign fflags = {{2'h0, overflow, 1'h0, overflow | round_inexact}};
endmodule

module IntToFP_postnorm{variant} (
  input  logic [62:0]        io_in_norm_int,
  input  logic [5:0]         io_in_lzc,
  input  logic               io_in_is_zero,
  input  logic               io_in_sign,
  input  logic [2:0]         io_rm,
  output logic [{res_w - 1}:0]        io_result,
  output logic [4:0]         io_fflags
);
  xs_IntToFP_postnorm{variant}_core u_core (
    .norm_int (io_in_norm_int),
    .lzc      (io_in_lzc),
    .is_zero  (io_in_is_zero),
    .sign_in  (io_in_sign),
    .rm       (io_rm),
    .result   (io_result),
    .fflags   (io_fflags)
  );
endmodule
'''


def top(variant: str, res_w: int, fmt_name: str) -> str:
    return f'''// =============================================================================
// IntToFP{variant} —— 64/32 位整数转 {fmt_name}（纯组合顶层）
//
// 位置：fudian 整数转浮点闭包的 {fmt_name} 顶层，被 FCVT 等执行单元例化。
// 结构就是两级直连：IntToFP_prenorm（取绝对值、数前导零、左移对齐）接
// IntToFP_postnorm{variant}（按 rm 舍入并拼 IEEE754）。
// golden 本模块没有任何寄存器/时钟/复位 —— 纯组合，照抄。
//
// 输入：io_int 原始整数；io_sign=1 有符号转换；io_long=1 按 64 位、=0 按
// 32 位（word）；io_rm 舍入模式（RNE/RTZ/RDN/RUP/RMM）。
// 输出：io_result = {{符号, 指数, 尾数}}；io_fflags 只可能置 OF/NX。
// =============================================================================
module xs_IntToFP{variant}_core (
  input  logic [63:0]        int_in,
  input  logic               sign_en,
  input  logic               long_en,
  input  logic [2:0]         rm,
  output logic [{res_w - 1}:0]        result,
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
  IntToFP_postnorm{variant} post_norm (
    .io_in_norm_int (norm_int),
    .io_in_lzc      (lzc),
    .io_in_is_zero  (is_zero),
    .io_in_sign     (sign_mid),
    .io_rm          (rm),
    .io_result      (result),
    .io_fflags      (fflags)
  );
endmodule

module IntToFP{variant} (
  input  logic [63:0]        io_int,
  input  logic               io_sign,
  input  logic               io_long,
  input  logic [2:0]         io_rm,
  output logic [{res_w - 1}:0]        io_result,
  output logic [4:0]         io_fflags
);
  xs_IntToFP{variant}_core u_core (
    .int_in (io_int),
    .sign_en(io_sign),
    .long_en(io_long),
    .rm     (io_rm),
    .result (io_result),
    .fflags (io_fflags)
  );
endmodule
'''


OUTPUTS = {
    "LZA": LZA,
    "IntToFP_prenorm": PRENORM,
    "IntToFP_postnorm": postnorm(
        "", 32, 8, 23, "11'hBE", "fp_exp > 11'hFE",
        "31'h7F7FFFFF", "31'h7F800000", "fp_exp[7:0]", "f32"),
    "IntToFP_postnorm_1": postnorm(
        "_1", 64, 11, 52, "11'h43E", "&fp_exp",
        "63'h7FEFFFFFFFFFFFFF", "63'h7FF0000000000000", "fp_exp", "f64"),
    "IntToFP_postnorm_2": postnorm(
        "_2", 16, 5, 10, "11'h4E", "fp_exp > 11'h1E",
        "15'h7BFF", "15'h7C00", "fp_exp[4:0]", "f16"),
    "IntToFP": top("", 32, "f32"),
    "IntToFP_1": top("_1", 64, "f64"),
    "IntToFP_2": top("_2", 16, "f16"),
}

# of_expr 的人类可读注释放进各自文件头（生成时无法内联进模板占位）
OF_COMMENT = {
    "IntToFP_postnorm": "fp_exp > 11'hFE（f32 最大有限指数 254 之外即上溢）",
    "IntToFP_postnorm_1": "&fp_exp（golden 原文形状：11 位全 1；本设计指数 "
                          "最大 1023+63+1=1087，此分支不可达，照抄）",
    "IntToFP_postnorm_2": "fp_exp > 11'h1E（f16 最大有限指数 30 之外即上溢）",
}


def with_of_comment(name: str, text: str) -> str:
    if name in OF_COMMENT:
        text = text.replace("{of_expr_comment}", OF_COMMENT[name])
    return text


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    drift = []
    for module, contents in OUTPUTS.items():
        contents = with_of_comment(module, contents)
        path = RTL_DIR / f"{module}.sv"
        if args.check:
            if not path.exists() or path.read_text() != contents:
                drift.append(str(path))
        else:
            path.write_text(contents)

    if drift:
        print("gen_inttofp_leaves8 --check: DRIFT: " + " ".join(drift))
        raise SystemExit(1)
    if args.check:
        print(f"gen_inttofp_leaves8 --check: OK ({len(OUTPUTS)} files)")


if __name__ == "__main__":
    main()
