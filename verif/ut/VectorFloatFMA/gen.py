#!/usr/bin/env python3
"""生成 VectorFloatFMA 的双例化 UT testbench（tb.sv）。

golden VectorFloatFMA vs 重写 VectorFloatFMA_xs（scripts/dual_tb_lib.py，端口表读 G1 golden），逐拍比
io_fp_result / io_fflags。

激励按"操作码 × 结果格式 × 是否加宽"组织，每拍抽一组：
  op      9 个 VfmaOpCode 均匀；mode>=14 时 op_code 4 位全随机（含未定义的 9..15）
  格式    f16 / f32 / f64 均匀（fp_format = 1 / 2 / 3）；mode>=14 时 2 位全随机（含 0）
  加宽    1/3 概率 res_widening=1（f16 结果下该位无作用，照样打）
  舍入    0..4 均匀，1/16 概率给 5..7（五个独热位全 0）
  fire    mode<4 恒 1（背靠背）；mode 4..5 稀疏（1/8）；其余 1/2
数据逐元素按"场景"生成 x*y+z 三元组（x、y 用源格式——加宽时是半宽格式，z 用结果格式），纯随机 64 位
浮点几乎打不到抵消 / 次正规 / 溢出路径，所以：
  场景 A 特殊值混合：每个操作数独立从 {±0, ±inf, qNaN, sNaN, 次正规(最小/最大/随机), 最小规格化数,
          最大规格化数, 1.0 附近, 指数在偏置附近的随机数, 全随机} 里抽；
  场景 B 指数配平：ea + eb 使乘积指数落在 {下溢边界附近, 溢出边界附近, 中间}，z 的指数取在乘积指数
          上下 [-(2W+6), W+6] 内 —— 打对齐右移的三个区间（c 太大 / 中间 / 太小）与舍入边界；
  场景 C 抵消：y 取 2 的幂或 1.5 * 2^k，z 的指数取乘积指数（±1）、尾数取 x 的尾数（可扰动低几位），
          有效减法时得到精确为 0 或大段前导零的和 —— 打规格化左移、is_fix、结果为 0；
  场景 E 特殊值配对：inf*0、inf+inf（一半是 inf-inf）、有限数+inf —— 打 NV 与无穷结果的符号；
  场景 D 全随机位。
  尾数另有偏置（全 0 / 全 1 / 只最低位 / 只最高位 / 低半段为 0 / 随机）以打舍入的 tie 与进位到指数。
  madd 类（操作码 5..8）硬件会交换 a 与 c，tb 相应把 x 放到 fp_c、z 放到 fp_a，使场景仍然成立。
  加宽时 x、y 放进 widen_a / widen_b 被 uop_idx 选中的那一半，另一半与 fp_a / fp_b 随机。
覆盖闸（看 golden 内部信号，gold 侧第 3 拍有效时才计）：
  9 op × 3 格式 × 2 加宽 = 54 个组合各自的 fire 计数；5 种舍入模式 × 3 种格式；
  7 条通道各自的：NaN / Inf / 溢出 / a 或 b 为 0 / 和恰为 0 / 次正规结果 / is_fix / 和为负 / UF / NX /
  舍入进位到指数 / c 对齐的三个区间；每种格式下 fflags 的 NV / OF / UF / NX 见过 1；每个输出位见过 0/1
  （DZ 位恒 0，豁免）。
不复位寄存器：除两级有效位外全部不复位。arm 条件 = golden 的 fire_reg1_last_r（第 2 拍有效）为 1：
  它带异步复位，为 1 说明前两拍的 fire 链完整走过（S0、S1 寄存器都已装载），且下一个上升沿必然装载
  S2 寄存器，所以从下一拍起两侧输出都由写入过的寄存器决定。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

OPS = ["vfmul", "vfmacc", "vfnmacc", "vfmsac", "vfnmsac", "vfmadd", "vfnmadd", "vfmsub", "vfnmsub"]
FMTS = [("f16", 1), ("f32", 2), ("f64", 3)]
LANES = ["f64", "f32_0", "f32_1", "f16_0", "f16_1", "f16_2", "f16_3"]

DECLS = r"""
int unsigned fa_op;       // 本拍操作（0..8；9 = op_code 全随机）
int unsigned fa_fmt;      // 0 = f16, 1 = f32, 2 = f64；3 = fp_format 全随机
logic        fa_widen;

// 尾数偏置
function automatic logic [63:0] fa_frac(input int fw);
  logic [63:0] f;
  f = {$urandom, $urandom};
  case ($urandom_range(0, 9))
    0:       f = 64'h0;
    1:       f = ~64'h0;
    2:       f = 64'h1;
    3:       f = 64'h1 << (fw - 1);
    4:       f = (f >> (fw / 2)) << (fw / 2);        // 低半段为 0
    5:       f = ~(64'h1 << $urandom_range(0, fw - 1)); // 只有一位 0
    default: ;
  endcase
  return f & ((64'h1 << fw) - 64'h1);
endfunction
function automatic logic [63:0] fa_pack(input int ew, input int fw, input logic s, input logic [63:0] e, input logic [63:0] f);
  return (64'(s) << (ew + fw)) | ((e & ((64'h1 << ew) - 64'h1)) << fw) | (f & ((64'h1 << fw) - 64'h1));
endfunction
// 场景 A：特殊值混合
function automatic logic [63:0] fa_any(input int ew, input int fw);
  logic        s;
  logic [63:0] emax, bias, e, f;
  s    = 1'($urandom);
  emax = (64'h1 << ew) - 64'h1;
  bias = (64'h1 << (ew - 1)) - 64'h1;
  f    = fa_frac(fw);
  case ($urandom_range(0, 15))
    0:       return fa_pack(ew, fw, s, 64'h0, 64'h0);                            // ±0
    1:       return fa_pack(ew, fw, s, emax, 64'h0);                             // ±inf
    2:       return fa_pack(ew, fw, s, emax, f | (64'h1 << (fw - 1)));           // qNaN
    3:       return fa_pack(ew, fw, s, emax, (f & ~(64'h1 << (fw - 1))) | 64'h1);// sNaN
    4:       return fa_pack(ew, fw, s, 64'h0, f | 64'h1);                        // 次正规
    5:       return fa_pack(ew, fw, s, 64'h0, ($urandom_range(0, 1) == 0) ? 64'h1 : ~64'h0);
    6:       return fa_pack(ew, fw, s, 64'h1, ($urandom_range(0, 1) == 0) ? 64'h0 : f);   // 最小规格化数附近
    7:       return fa_pack(ew, fw, s, emax - 64'h1, ($urandom_range(0, 1) == 0) ? ~64'h0 : f); // 最大规格化数附近
    8, 9:    return fa_pack(ew, fw, s, bias + 64'($urandom_range(0, 2)) - 64'h1, f);  // 1.0 附近
    10, 11, 12: begin
      e = bias + 64'($urandom_range(0, 2 * fw + 8)) - 64'(fw + 4);                // 偏置附近
      return fa_pack(ew, fw, s, e, f);
    end
    default: return {$urandom, $urandom};
  endcase
endfunction
// 生成一个元素的 x*y+z 三元组。源格式 (sew, sfw)，结果格式 (ew, fw)。
task automatic fa_triplet(input int sew, input int sfw, input int ew, input int fw,
                          output logic [63:0] x, output logic [63:0] y, output logic [63:0] z);
  int          sbias, bias, emax, semax, ea, eb, te, ec, d;
  logic [63:0] fx, fy, fz;
  sbias = (1 << (sew - 1)) - 1;
  bias  = (1 << (ew - 1)) - 1;
  emax  = (1 << ew) - 1;
  semax = (1 << sew) - 1;
  case ($urandom_range(0, 15))
    0, 1, 2, 3: begin  // A
      x = fa_any(sew, sfw); y = fa_any(sew, sfw); z = fa_any(ew, fw);
    end
    4, 5, 6, 7: begin  // B 指数配平：结果指数 te = ea + eb - 2*sbias + bias
      case ($urandom_range(0, 3))
        0:       te = $urandom_range(0, fw + 6) - (fw + 3);         // 下溢边界
        1:       te = emax - 4 + $urandom_range(0, 6);              // 溢出边界
        default: te = $urandom_range(1, emax - 1);
      endcase
      // ea + eb = te - bias + 2*sbias，在 [1, semax-1] 内拆分（拆不出来就夹住）
      d  = te - bias + 2 * sbias;
      ea = $urandom_range(1, semax - 1);
      eb = d - ea;
      if (eb < 0) begin eb = $urandom_range(0, 1); ea = d - eb; end
      if (eb > semax - 1) begin eb = semax - 1; ea = d - eb; end
      if (ea < 0) ea = 0;
      if (ea > semax - 1) ea = semax - 1;
      x  = fa_pack(sew, sfw, 1'($urandom), 64'(ea), fa_frac(sfw));
      y  = fa_pack(sew, sfw, 1'($urandom), 64'(eb), fa_frac(sfw));
      ec = te + $urandom_range(0, 3 * fw + 12) - (2 * fw + 6);
      if (ec < 0) ec = 0;
      if (ec > emax - 1) ec = emax - 1;
      z  = ($urandom_range(0, 3) == 0) ? fa_any(ew, fw) : fa_pack(ew, fw, 1'($urandom), 64'(ec), fa_frac(fw));
    end
    8, 9, 10, 11: begin  // C 抵消
      ea = $urandom_range(1, semax - 1);
      eb = sbias + $urandom_range(0, 6) - 3;
      if (eb < 1) eb = 1;
      if (eb > semax - 1) eb = semax - 1;
      fx = fa_frac(sfw);
      fy = ($urandom_range(0, 2) == 0) ? (64'h1 << (sfw - 1)) : 64'h0;   // 1.5 或 1.0
      x  = fa_pack(sew, sfw, 1'($urandom), 64'(ea), fx);
      y  = fa_pack(sew, sfw, 1'($urandom), 64'(eb), fy);
      te = ea + eb - 2 * sbias + bias + $urandom_range(0, 8) / 4 - 1;     // 多数为 0 偏移，少数 ±1
      if (te < 1) te = 1;
      if (te > emax - 1) te = emax - 1;
      fz = fx << (fw - sfw);
      case ($urandom_range(0, 5))
        0:       fz = fz ^ 64'h1;
        1:       fz = fz + 64'h1;
        2:       fz = fz ^ (64'h1 << $urandom_range(0, fw - 1));
        3:       fz = fz ^ 64'($urandom_range(0, 15));
        default: ;
      endcase
      z  = fa_pack(ew, fw, 1'($urandom), 64'(te), fz);
    end
    12: begin  // E 特殊值配对：inf*0、inf+inf（符号随机，一半是 inf-inf）、有限数+inf
      x = fa_pack(sew, sfw, 1'($urandom), 64'(semax), 64'h0);
      z = fa_any(ew, fw);
      case ($urandom_range(0, 3))
        0:       y = fa_pack(sew, sfw, 1'($urandom), 64'h0, 64'h0);
        1:       begin y = fa_pack(sew, sfw, 1'($urandom), 64'(sbias), fa_frac(sfw)); z = fa_pack(ew, fw, 1'($urandom), 64'(emax), 64'h0); end
        2:       begin y = x; x = fa_pack(sew, sfw, 1'($urandom), 64'h0, 64'h0); end
        default: begin x = fa_pack(sew, sfw, 1'($urandom), 64'(sbias), fa_frac(sfw)); y = fa_pack(sew, sfw, 1'($urandom), 64'(sbias), fa_frac(sfw));
                       z = fa_pack(ew, fw, 1'($urandom), 64'(emax), 64'h0); end
      endcase
    end
    default: begin  // D
      x = {$urandom, $urandom}; y = {$urandom, $urandom}; z = {$urandom, $urandom};
    end
  endcase
endtask
"""

STIM = r"""
logic [63:0] vx, vy, vz, wx, wy, tx, ty, tz;
int          w, ew, fw, sew, sfw, nslot, half;
logic        swap;
fa_op    = (@mode >= 14) ? 9 : $urandom_range(0, 8);
fa_fmt   = (@mode >= 14) ? 3 : $urandom_range(0, 2);
fa_widen = ($urandom_range(0, 2) == 0);
if (fa_op < 9) @io_op_code = 4'(fa_op);
if (fa_fmt < 3) @io_fp_format = 2'(fa_fmt + 1);
@io_res_widening = fa_widen;
@io_round_mode   = ($urandom_range(0, 15) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, 4));
@io_fire         = (@mode < 4) ? 1'b1 : (@mode < 6) ? ($urandom_range(0, 7) == 0) : 1'($urandom);
// 实际生效的格式（fp_format 0 按 f16 处理）
w  = (@io_fp_format == 2'd3) ? 64 : (@io_fp_format == 2'd2) ? 32 : 16;
ew = (w == 64) ? 11 : (w == 32) ? 8 : 5;
fw = w - 1 - ew;
if (fa_widen && w != 16) begin
  sew = (w == 64) ? 8 : 5;
  sfw = w / 2 - 1 - sew;
end else begin
  sew = ew;
  sfw = fw;
end
nslot = 64 / w;
swap  = (@io_op_code >= 4'd5) && (@io_op_code <= 4'd8);
half  = @io_uop_idx ? 32 : 0;
vx = {$urandom, $urandom}; vy = {$urandom, $urandom}; vz = {$urandom, $urandom};
wx = {$urandom, $urandom}; wy = {$urandom, $urandom};
for (int k = 0; k < nslot; k++) begin
  fa_triplet(sew, sfw, ew, fw, tx, ty, tz);
  for (int b = 0; b < w; b++) vz[k * w + b] = tz[b];
  if (fa_widen && w != 16) begin
    for (int b = 0; b < w / 2; b++) begin
      wx[half + k * (w / 2) + b] = tx[b];
      wy[half + k * (w / 2) + b] = ty[b];
    end
  end else begin
    for (int b = 0; b < w; b++) begin
      vx[k * w + b] = tx[b];
      vy[k * w + b] = ty[b];
    end
  end
end
@io_fp_b    = vy;
@io_widen_a = wx;
@io_widen_b = wy;
if (swap) begin
  @io_fp_c = vx; @io_fp_a = vz;
end else begin
  @io_fp_a = vx; @io_fp_c = vz;
end
"""

G = "fa_u_gold."
COV = []
for k, op in enumerate(OPS):
    for f, (fn, _) in enumerate(FMTS):
        for wd in (0, 1):
            COV.append(("%s_%s_%s" % (op, fn, "widen" if wd else "same"),
                        "@io_fire && fa_op == %d && fa_fmt == %d && fa_widen == 1'b%d" % (k, f, wd)))
for f, (fn, _) in enumerate(FMTS):
    COV.append(("randop_%s" % fn, "@io_fire && fa_op == 9 && @io_fp_format == 2'd%d" % (f + 1)))
COV.append(("fmt0_as_f16", "@io_fire && @io_fp_format == 2'd0"))
COV.append(("op_undefined", "@io_fire && @io_op_code > 4'd8"))
COV.append(("fire_gap", "!@io_fire"))
COV.append(("uop_idx_widen", "@io_fire && @io_res_widening && @io_uop_idx"))

# 以下看 golden 第 3 拍（reg2）的状态；out_vld = 上一拍 fire_reg1 为 1 之后 reg2 才是新数据，
# 这里不追求"每个事件只计一次"，只要求该状态在比较窗口内出现过足够多拍。
FMT_SEL = {"f64": G + "is_fp64_reg2",
           "f32": "(!%sis_fp64_reg2 && %sis_fp32_reg2)" % (G, G),
           "f16": G + "is_fp16_reg2"}
for fn in ("f16", "f32", "f64"):
    for rm in ("RNE", "RTZ", "RDN", "RUP", "RMM"):
        COV.append(("%s_%s" % (rm.lower(), fn), "%s && %s%s_reg2" % (FMT_SEL[fn], G, rm)))
    COV.append(("rm_invalid_%s" % fn,
                "%s && !(%sRNE_reg2 || %sRTZ_reg2 || %sRDN_reg2 || %sRUP_reg2 || %sRMM_reg2)" % (FMT_SEL[fn], G, G, G, G, G)))
    for bit, nm in ((4, "NV"), (2, "OF"), (1, "UF"), (0, "NX")):
        COV.append(("flag_%s_%s" % (nm, fn), "%s && @io_fflags[%d]" % (FMT_SEL[fn], bit)))
SLOT = {"f64": 0, "f32_0": 0, "f32_1": 1, "f16_0": 0, "f16_1": 1, "f16_2": 2, "f16_3": 3}
for ln in LANES:
    sel = FMT_SEL[ln[:3]]
    s = SLOT[ln]
    nospecial = "!%shas_nan_%s_reg2 && !%shas_inf_%s_reg2" % (G, ln, G, ln)
    normal = "%s && !%sexponent_overflow_%s && !%shas_zero_%s_reg2" % (nospecial, G, ln, G, ln)
    COV.append(("%s_nan" % ln, "%s && %shas_nan_%s_reg2" % (sel, G, ln)))
    COV.append(("%s_nan_nv" % ln, "%s && %shas_nan_%s_reg2 && %shas_nan_%s_is_NV_reg2" % (sel, G, ln, G, ln)))
    COV.append(("%s_inf" % ln, "%s && !%shas_nan_%s_reg2 && %shas_inf_%s_reg2" % (sel, G, ln, G, ln)))
    COV.append(("%s_inf_nv" % ln, "%s && !%shas_nan_%s_reg2 && %shas_inf_%s_reg2 && %shas_inf_%s_is_NV_reg2"
                % (sel, G, ln, G, ln, G, ln)))
    COV.append(("%s_overflow" % ln, "%s && %s && %sexponent_overflow_%s" % (sel, nospecial, G, ln)))
    COV.append(("%s_ab_zero" % ln, "%s && %s && !%sexponent_overflow_%s && %sfp_a_or_b_is_zero_%s_reg2"
                % (sel, nospecial, G, ln, G, ln)))
    COV.append(("%s_sum_zero" % ln, "%s && %s && !%sexponent_overflow_%s && !%sfp_a_or_b_is_zero_%s_reg2 && %snormal_result_is_zero_%s_reg2"
                % (sel, nospecial, G, ln, G, ln, G, ln)))
    COV.append(("%s_subnormal" % ln, "%s && %s && %sexponent_is_min_%s" % (sel, normal, G, ln)))
    COV.append(("%s_is_fix" % ln, "%s && %s && %sis_fix_reg2[%d]" % (sel, normal, G, s)))
    COV.append(("%s_sum_neg" % ln, "%s && %s && %sadder_is_negative_reg2[%d]" % (sel, normal, G, s)))
    COV.append(("%s_uf" % ln, "%s && %s && %sUF_%s" % (sel, normal, G, ln)))
    COV.append(("%s_nx" % ln, "%s && %s && %sNX_%s" % (sel, normal, G, ln)))
    COV.append(("%s_exact" % ln, "%s && %s && !%sNX_%s" % (sel, normal, G, ln)))
    COV.append(("%s_round_up" % ln, "%s && %s && %sround_add1_%s" % (sel, normal, G, ln)))
    COV.append(("%s_exp_carry" % ln, "%s && %s && %sexponent_add_1_%s" % (sel, normal, G, ln)))
    # S0 的对齐区间（看 fire 那一拍 golden 的组合信号）
    in_sel = {"f64": "@io_fp_format == 2'd3", "f32": "@io_fp_format == 2'd2", "f16": "@io_fp_format < 2'd2"}[ln[:3]]
    COV.append(("%s_c_medium" % ln, "@io_fire && %s && %sEc_is_medium_%s" % (in_sel, G, ln)))
    COV.append(("%s_c_too_big" % ln, "@io_fire && %s && %sEc_is_too_big_%s" % (in_sel, G, ln)))
    COV.append(("%s_c_too_small" % ln, "@io_fire && %s && !%sEc_is_medium_%s && !%sEc_is_too_big_%s" % (in_sel, G, ln, G, ln)))

# DZ（除零）位恒 0
EXEMPT = ["io_fflags[3]", "io_fflags[8]", "io_fflags[13]", "io_fflags[18]"]

PAIRS = [
    Pair("VectorFloatFMA", "fa_", clocked=True, stim=STIM, decls=DECLS, cov=COV, exempt=EXEMPT,
         mode_period=1000, reset_period=20000, cov_min=100, arm=[G + "fire_reg1_last_r"]),
]

HEADER = """自动生成：verif/ut/VectorFloatFMA/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
VectorFloatFMA 双例化逐拍比对：golden VectorFloatFMA vs 重写 VectorFloatFMA_xs，io_fp_result / io_fflags 逐位 !==。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
