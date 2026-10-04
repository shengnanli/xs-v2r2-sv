#!/usr/bin/env python3
"""生成 FloatFMA 的 UT testbench（tb.sv）：双例化逐拍比对 + 独立 IEEE 754 参考模型（oracle）。

一、双例化（scripts/dual_tb_lib.py，端口表读 G1 golden）：golden FloatFMA vs 重写 FloatFMA_xs，
   每拍逐位比 fp_result / fflags。寄存器不复位：复位撤销后第一次 fire 之后 3 拍才开始比（arm；复位期间 fire_s1/s2 被压住，
   那时的 fire 不会把数据推到输出级）。
二、独立 oracle（本文件 ORACLE 段，纯 SV 函数，不读 golden 任何内部信号）：
   对每个 fire 的操作，按 RISC-V F/D/Zfh + IEEE 754-2008 算出精确的融合乘加结果，3 拍后与 golden 输出比：
   * 有限数：有效数是整数 M、指数 E（值 = ±M·2^E），乘积 Ma·Mb 精确；与 c 精确相加（大整数，320 位窗口；
     两数量级相差 > 2p+8 位时，小的那个换成同号的一个最低位 1 —— 它只影响 sticky 与舍入方向，
     这是 softfloat shiftRightJam 的同一个论证）；然后按舍入模式一次性舍入到 p 位（含次正规数）。
   * 标志：NX = 舍入有余数；OF = 舍入后指数超 emax（结果按方向给 Inf / 最大数）；
     UF = 不精确且"舍入后为 tiny"（RISC-V 规定的 after-rounding tininess：按指数无界舍入后 < 2^emin）。
   * 特殊值：任一 NaN（含 fp_*IsFpCanonicalNAN）-> 规范 qNaN；sNaN、Inf×0（即使 c 是 qNaN）、
     Inf-Inf -> NV。精确为 0：fmul 取乘积符号；否则同号取该号、异号只有 RDN 得 -0。
   * f32 / f16 结果高位补 1（NaN-boxing）。fmul 是纯乘法（不是 +0 的乘加：-0 乘积保持 -0）。
   * 不判（双例化仍逐拍比）：舍入模式 5..7（非法编码）；fmul 且 fp_cIsFpCanonicalNAN=1（父模块 FMA 对 fmul
     恒给 0，属契约外输入；golden 此时把 c 当 NaN）。
三、激励：格式 f64 / f32 / f16（fp_format 0/1 也按 f16）；操作数按类别抽（±0、±Inf、qNaN、sNaN、次正规、
   最大 / 最小规格化、全范围规格化、指数居中的规格化）；c 的指数常取在乘积指数附近（制造对齐、大量抵消）；
   1/16 的拍让 c 恰为 -round(a*b)（精确抵消，只剩舍入误差）；op_code 多数取 0..4，偶尔 5..15；
   CanonicalNAN 标志各 1/32。
覆盖闸：三种格式 × {NX, UF, OF, NV, 精确 0, 次正规结果, NaN, Inf} 的 oracle 判过次数；5 种舍入模式 × 5 种
  操作码；golden 内部 is_fix_reg2 为 1 的拍数；每个输出位见过 0/1（fflags[3] = DZ 结构恒 0，豁免）。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

ORACLE = r"""
// ============================ 独立 oracle ============================
localparam int ORA_BW = 320;
typedef logic [ORA_BW-1:0] ora_big_t;
int ora_checks = 0, ora_errors = 0;
localparam int ORA_MIN_CHECKS = 50000;   // 200k 拍下的下限（fire 约 3/4，减去非法舍入模式）
localparam int ORA_MIN_CLS    = 20;

function automatic int ora_msb(input ora_big_t v);   // 最高 1 的位置；全 0 返回 -1
  for (int i = ORA_BW - 1; i >= 0; i--) if (v[i]) return i;
  return -1;
endfunction

function automatic int ora_p(input int fmt);  return (fmt == 0) ? 53 : (fmt == 1) ? 24 : 11; endfunction
function automatic int ora_ew(input int fmt); return (fmt == 0) ? 11 : (fmt == 1) ? 8 : 5;   endfunction

// mag·2^e_lsb 在第 sh 位处舍入（sh <= 0 表示精确左移）。m = 舍入后的整数，inexact = 有余数
function automatic void ora_rnd(input ora_big_t mag, input int sh, input bit sign, input logic [2:0] rm,
                                output ora_big_t m, output bit inexact);
  ora_big_t rem, half;
  bit incr;
  int msb;
  if (sh <= 0) begin
    m = mag << (-sh);
    inexact = 1'b0;
    return;
  end
  msb = ora_msb(mag);
  if (sh > msb + 2) sh = msb + 2;            // 值小于半个 ulp：再往上移结果都一样
  m       = mag >> sh;
  rem     = mag & ((ora_big_t'(1) << sh) - 1);
  half    = ora_big_t'(1) << (sh - 1);
  inexact = (rem != 0);
  case (rm)
    3'd0:    incr = (rem > half) || ((rem == half) && m[0]);   // RNE
    3'd1:    incr = 1'b0;                                       // RTZ
    3'd2:    incr = sign && inexact;                            // RDN
    3'd3:    incr = !sign && inexact;                           // RUP
    3'd4:    incr = (rem >= half);                              // RMM
    default: incr = 1'b0;
  endcase
  m = m + incr;
endfunction

// (-1)^sign · mag · 2^e_lsb（mag != 0）舍入、打包成 fmt 格式（低 p+ew 位）；cls：0 规格化 1 次正规/下溢 3 溢出
function automatic logic [63:0] ora_round_pack(input bit sign, input ora_big_t mag, input int e_lsb, input int fmt,
                                               input logic [2:0] rm, output logic [4:0] flags, output int cls);
  int p, ew, bias, emin, emax, msb, e_res, q, sh;
  ora_big_t m, m2;
  bit inexact, inexact2, tiny, ovf;
  logic [63:0] r, fracmask;
  logic [63:0] expo;
  p = ora_p(fmt); ew = ora_ew(fmt);
  bias = (1 << (ew - 1)) - 1; emin = 1 - bias; emax = bias;
  msb   = ora_msb(mag);
  e_res = e_lsb + msb;                         // 值落在 [2^e_res, 2^(e_res+1))
  q = e_res - (p - 1);
  if (q < emin - (p - 1)) q = emin - (p - 1);  // 次正规：最低位固定在 2^(emin-p+1)
  sh = q - e_lsb;
  ora_rnd(mag, sh, sign, rm, m, inexact);
  if (m == (ora_big_t'(1) << p)) begin m = m >> 1; q = q + 1; end
  // tininess（舍入后判定）：按无界指数舍入到 p 位，结果 < 2^emin
  if (e_res < emin - 1) tiny = 1'b1;
  else if (e_res == emin - 1) begin
    ora_rnd(mag, (e_res - (p - 1)) - e_lsb, sign, rm, m2, inexact2);
    tiny = (m2 != (ora_big_t'(1) << p));
  end else tiny = 1'b0;
  ovf = (q + (p - 1) > emax);
  fracmask = (64'd1 << (p - 1)) - 1;
  if (ovf) begin
    flags = 5'b00101;
    cls   = 3;
    if ((rm == 3'd1) || (rm == 3'd2 && !sign) || (rm == 3'd3 && sign))
      r = (64'(sign) << (p + ew - 1)) | (64'((1 << ew) - 2) << (p - 1)) | fracmask;   // 最大有限数
    else
      r = (64'(sign) << (p + ew - 1)) | (64'((1 << ew) - 1) << (p - 1));              // Inf
    return r;
  end
  flags = {3'b000, tiny && inexact, inexact};
  if (m >= (ora_big_t'(1) << (p - 1))) begin
    expo = 64'(q + (p - 1) + bias);
    cls  = (tiny && inexact) ? 1 : 0;
  end else begin
    expo = 64'd0;
    cls  = 1;
  end
  r = (64'(sign) << (p + ew - 1)) | (expo << (p - 1)) | (64'(m) & fracmask);
  return r;
endfunction

// 完整参考：返回 64 位结果（f32/f16 已 NaN-boxing）。cls：0 规格化 1 次正规/下溢 2 精确 0 3 溢出 4 NaN 5 Inf 6 结果就是 c
function automatic logic [63:0] ora_fma(input logic [1:0] fp_format, input logic [63:0] a, input logic [63:0] b,
                                        input logic [63:0] c, input logic [3:0] op, input logic [2:0] rm,
                                        input bit an, input bit bn, input bit cn,
                                        output logic [4:0] flags, output int cls);
  int fmt, p, ew, w, bias, emax_raw;
  bit is_fmul, nega, negc;
  bit sa, sb, sc, sp;
  int ea, eb, ec, Ea, Eb, Ec, Ep, t1, t2, elow;
  logic [63:0] fa, fb, fc, fracmask, qnan, r, cword;
  bit nan_a, nan_b, nan_c, snan_a, snan_b, snan_c, inf_a, inf_b, inf_c, zero_a, zero_b, zero_c;
  ora_big_t Ma, Mb, Mc, Mp, A, B, mag;
  bit s;
  fmt = (fp_format == 2'd3) ? 0 : (fp_format == 2'd2) ? 1 : 2;
  p = ora_p(fmt); ew = ora_ew(fmt); w = p + ew;
  bias = (1 << (ew - 1)) - 1; emax_raw = (1 << ew) - 1;
  is_fmul = (op == 4'd0);
  nega    = (op == 4'd2) || (op == 4'd4);
  negc    = (op == 4'd2) || (op == 4'd3);
  fracmask = (64'd1 << (p - 1)) - 1;
  qnan  = (64'(emax_raw) << (p - 1)) | (64'd1 << (p - 2));
  sa = a[w-1] ^ nega; sb = b[w-1]; sc = is_fmul ? 1'b0 : (c[w-1] ^ negc);
  ea = int'((a >> (p - 1)) & emax_raw); eb = int'((b >> (p - 1)) & emax_raw);
  ec = is_fmul ? 0 : int'((c >> (p - 1)) & emax_raw);
  fa = a & fracmask; fb = b & fracmask; fc = is_fmul ? 64'd0 : (c & fracmask);
  nan_a  = an | (ea == emax_raw && fa != 0);  nan_b = bn | (eb == emax_raw && fb != 0);  nan_c = cn | (ec == emax_raw && fc != 0);
  snan_a = !an && ea == emax_raw && fa != 0 && !fa[p-2];
  snan_b = !bn && eb == emax_raw && fb != 0 && !fb[p-2];
  snan_c = !cn && ec == emax_raw && fc != 0 && !fc[p-2];
  inf_a  = !an && ea == emax_raw && fa == 0;  inf_b = !bn && eb == emax_raw && fb == 0;  inf_c = !cn && ec == emax_raw && fc == 0;
  zero_a = !an && ea == 0 && fa == 0;         zero_b = !bn && eb == 0 && fb == 0;        zero_c = !cn && ec == 0 && fc == 0;
  sp = sa ^ sb;
  flags = 5'b0;
  if (nan_a || nan_b || nan_c) begin
    cls = 4;
    if (snan_a || snan_b || snan_c || (inf_a && zero_b) || (zero_a && inf_b)) flags = 5'b10000;
    r = qnan;
  end else if (inf_a || inf_b || inf_c) begin
    if ((inf_a && zero_b) || (zero_a && inf_b) || ((inf_a || inf_b) && inf_c && (sp != sc))) begin
      cls = 4; flags = 5'b10000; r = qnan;
    end else begin
      cls = 5;
      s   = (inf_a || inf_b) ? sp : sc;
      r   = (64'(s) << (w - 1)) | (64'(emax_raw) << (p - 1));
    end
  end else begin
    Ma = (ea == 0) ? ora_big_t'(fa) : (ora_big_t'(fa) | (ora_big_t'(1) << (p - 1)));
    Mb = (eb == 0) ? ora_big_t'(fb) : (ora_big_t'(fb) | (ora_big_t'(1) << (p - 1)));
    Mc = (ec == 0) ? ora_big_t'(fc) : (ora_big_t'(fc) | (ora_big_t'(1) << (p - 1)));
    Ea = ((ea == 0) ? 1 : ea) - bias - (p - 1);
    Eb = ((eb == 0) ? 1 : eb) - bias - (p - 1);
    Ec = ((ec == 0) ? 1 : ec) - bias - (p - 1);
    Mp = Ma * Mb;
    Ep = Ea + Eb;
    if (Mp == 0 && (is_fmul || Mc == 0)) begin
      cls = 2;
      s   = is_fmul ? sp : ((sp == sc) ? sp : (rm == 3'd2));
      r   = 64'(s) << (w - 1);
    end else if (Mp == 0) begin
      cls = 6;
      r   = (64'(sc) << (w - 1)) | (c & ((64'd1 << (w - 1)) - 1));
    end else if (is_fmul || Mc == 0) begin
      r = ora_round_pack(sp, Mp, Ep, fmt, rm, flags, cls);
    end else begin
      t1 = Ep + ora_msb(Mp) + 1;
      t2 = Ec + ora_msb(Mc) + 1;
      if (t1 - t2 > 2 * p + 8) begin Mc = 1; Ec = t1 - 2 * p - 9; end
      else if (t2 - t1 > 2 * p + 8) begin Mp = 1; Ep = t2 - 2 * p - 9; end
      elow = (Ep < Ec) ? Ep : Ec;
      A = Mp << (Ep - elow);
      B = Mc << (Ec - elow);
      if (sp == sc)  begin mag = A + B; s = sp; end
      else if (A >= B) begin mag = A - B; s = sp; end
      else             begin mag = B - A; s = sc; end
      if (mag == 0) begin
        cls = 2;
        r   = 64'(rm == 3'd2) << (w - 1);
      end else begin
        r = ora_round_pack(s, mag, elow, fmt, rm, flags, cls);
      end
    end
  end
  if (fmt == 1)      r = {32'hffff_ffff, r[31:0]};
  else if (fmt == 2) r = {48'hffff_ffff_ffff, r[15:0]};
  return r;
endfunction

// ---- 操作数生成 ----
function automatic logic [63:0] ora_gen_operand(input int fmt, input int cls_pick, input int exp_hint);
  int p, ew, w, emax_raw, e;
  logic [63:0] x, fracmask, frac;
  p = ora_p(fmt); ew = ora_ew(fmt); w = p + ew;
  emax_raw = (1 << ew) - 1;
  fracmask = (64'd1 << (p - 1)) - 1;
  x    = {$urandom, $urandom};               // 高位（f32/f16 不用的部分）随机
  frac = {$urandom, $urandom} & fracmask;
  case ($urandom_range(0, 7))
    0: frac = 0;
    1: frac = fracmask;
    2: frac = frac & ~((64'd1 << $urandom_range(0, p - 2)) - 1);   // 尾部长串 0
    3: frac = frac | ((64'd1 << $urandom_range(0, p - 2)) - 1);    // 尾部长串 1
    default: ;
  endcase
  case (cls_pick)
    0: begin e = 0; frac = 0; end                                   // ±0
    1: begin e = emax_raw; frac = 0; end                            // ±Inf
    2: begin e = emax_raw; frac = frac | (64'd1 << (p - 2)); end    // qNaN
    3: begin e = emax_raw; frac = (frac & ~(64'd1 << (p - 2))) | 64'd1; end   // sNaN
    4: begin e = 0; if (frac == 0) frac = 1; end                    // 次正规
    5: begin e = $urandom_range(0, 1) ? emax_raw - 1 : 1; end       // 最大 / 最小规格化指数
    6: e = $urandom_range(1, emax_raw - 1);                         // 全范围
    default: begin                                                  // 指数在 hint 附近
      e = exp_hint + $urandom_range(0, 2 * p + 8) - (p + 4);
      if (e < 1) e = $urandom_range(0, 1) ? 0 : 1;
      if (e > emax_raw - 1) e = emax_raw - 1;
    end
  endcase
  x = x & ~((64'd1 << w) - 1);
  x = x | (64'($urandom_range(0, 1)) << (w - 1)) | (64'(e) << (p - 1)) | frac;
  return x;
endfunction

// ---- 每拍：登记 fire 的操作，3 拍后对 golden 输出（negedge 后 3ns，早于主循环的比较点）----
typedef struct { bit skip; int due; logic [63:0] res; logic [4:0] flags; int cls; int fmt; logic [2:0] rm; logic [3:0] op; } ora_pend_t;
ora_pend_t ora_q[$];
int ora_cyc = 0;
int ora_cov_cls[3][7];
int ora_cov_nx[3], ora_cov_uf[3], ora_cov_of[3], ora_cov_nv[3];
int ora_cov_rm_op[5][5];
logic ora_tick = 1'b0;
always @(negedge clk) begin
  ora_pend_t e;
  logic [4:0] fl;
  int cl, fmt;
  #3;
  while (ora_q.size() > 0 && ora_q[0].due <= ora_cyc) begin
    e = ora_q.pop_front();
    if (e.due == ora_cyc && !e.skip) begin
      ora_checks++;
      if (tb.fma_g_io_fp_result !== e.res || tb.fma_g_io_fflags !== e.flags) begin
        ora_errors++;
        tb.errors++;
        if (ora_errors <= 20)
          $display("[ORACLE] cyc=%0d fmt=%0d rm=%0d op=%0d golden=%h/%b oracle=%h/%b cls=%0d",
                   ora_cyc, e.fmt, e.rm, e.op, tb.fma_g_io_fp_result, tb.fma_g_io_fflags, e.res, e.flags, e.cls);
      end else begin
        ora_cov_cls[e.fmt][e.cls]++;
        if (e.flags[0]) ora_cov_nx[e.fmt]++;
        if (e.flags[1]) ora_cov_uf[e.fmt]++;
        if (e.flags[2]) ora_cov_of[e.fmt]++;
        if (e.flags[4]) ora_cov_nv[e.fmt]++;
        if (e.op <= 4'd4) ora_cov_rm_op[e.rm][e.op]++;
      end
    end
  end
  // 复位清掉在途的操作（fire_s1/s2 被复位，结果不会出来）
  if (tb.fma_reset) ora_q.delete();
  if (tb.fma_io_fire && !tb.fma_reset) begin
    e.res = ora_fma(tb.fma_io_fp_format, tb.fma_io_fp_a, tb.fma_io_fp_b, tb.fma_io_fp_c, tb.fma_io_op_code,
                    tb.fma_io_round_mode, tb.fma_io_fp_aIsFpCanonicalNAN, tb.fma_io_fp_bIsFpCanonicalNAN,
                    tb.fma_io_fp_cIsFpCanonicalNAN, fl, cl);
    // 不判：非法舍入模式 5..7；fmul 而 c 的 CanonicalNAN=1（父模块 FMA 对 fmul 恒给 0，契约外输入——
    // golden 此时仍把 c 当 NaN，见 golden FloatFMA 的 fp_c_is_nan；双例化照样逐拍比）
    e.skip = (tb.fma_io_round_mode > 3'd4) || (tb.fma_io_op_code == 4'd0 && tb.fma_io_fp_cIsFpCanonicalNAN);
    e.flags = fl; e.cls = cl; e.due = ora_cyc + 3; e.rm = tb.fma_io_round_mode; e.op = tb.fma_io_op_code;
    e.fmt = (tb.fma_io_fp_format == 2'd3) ? 0 : (tb.fma_io_fp_format == 2'd2) ? 1 : 2;
    ora_q.push_back(e);
  end
  // 最后一拍（主循环比较点之前）：oracle 判过的次数与各类覆盖不足即判失败
  if (ora_cyc == tb.NCYCLES - 1) ora_gate();
  ora_cyc++;
end
function automatic void ora_gate();
  string fn[3] = '{"f64", "f32", "f16"};
  string cn[7] = '{"normal", "subnormal_or_uf", "exact_zero", "overflow", "nan", "inf", "c_only"};
  $display("[ORACLE] checks=%0d errors=%0d", ora_checks, ora_errors);
  if (ora_checks < ORA_MIN_CHECKS) begin tb.cov_fail++; $display("[ORACLE] checks < %0d", ORA_MIN_CHECKS); end
  for (int f = 0; f < 3; f++) begin
    for (int k = 0; k < 7; k++) begin
      $display("[ORACLE-COV] %s %s = %0d", fn[f], cn[k], ora_cov_cls[f][k]);
      if (ora_cov_cls[f][k] < ORA_MIN_CLS) begin tb.cov_fail++; $display("[ORACLE-COV] %s %s < %0d", fn[f], cn[k], ORA_MIN_CLS); end
    end
    $display("[ORACLE-COV] %s NX=%0d UF=%0d OF=%0d NV=%0d", fn[f], ora_cov_nx[f], ora_cov_uf[f], ora_cov_of[f], ora_cov_nv[f]);
    if (ora_cov_nx[f] < ORA_MIN_CLS || ora_cov_uf[f] < ORA_MIN_CLS || ora_cov_of[f] < ORA_MIN_CLS || ora_cov_nv[f] < ORA_MIN_CLS) begin
      tb.cov_fail++; $display("[ORACLE-COV] %s 标志覆盖 < %0d", fn[f], ORA_MIN_CLS);
    end
  end
  for (int r = 0; r < 5; r++) for (int o = 0; o < 5; o++) begin
    if (ora_cov_rm_op[r][o] < ORA_MIN_CLS) begin tb.cov_fail++; $display("[ORACLE-COV] rm=%0d op=%0d = %0d < %0d", r, o, ora_cov_rm_op[r][o], ORA_MIN_CLS); end
  end
endfunction
"""

STIM = r"""
begin
  int fmt, eh, ca, cb, cc;
  logic [63:0] prod;
  logic [4:0] pfl;
  int pcl;
  case ($urandom_range(0, 7))
    0, 1, 2: @io_fp_format = 2'd3;
    3, 4, 5: @io_fp_format = 2'd2;
    default: @io_fp_format = 2'($urandom_range(0, 1));
  endcase
  fmt = (@io_fp_format == 2'd3) ? 0 : (@io_fp_format == 2'd2) ? 1 : 2;
  @io_fire       = ($urandom_range(0, 3) != 0);
  @io_round_mode = ($urandom_range(0, 15) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, 4));
  @io_op_code    = ($urandom_range(0, 15) == 0) ? 4'($urandom_range(5, 15)) : 4'($urandom_range(0, 4));
  @io_fp_aIsFpCanonicalNAN = ($urandom_range(0, 31) == 0);
  @io_fp_bIsFpCanonicalNAN = ($urandom_range(0, 31) == 0);
  @io_fp_cIsFpCanonicalNAN = ($urandom_range(0, 31) == 0);
  // 类别：特殊值约 1/4，次正规 / 极值约 1/4，其余规格化
  ca = ($urandom_range(0, 3) == 0) ? $urandom_range(0, 5) : $urandom_range(4, 7);
  cb = ($urandom_range(0, 3) == 0) ? $urandom_range(0, 5) : $urandom_range(4, 7);
  cc = ($urandom_range(0, 3) == 0) ? $urandom_range(0, 5) : $urandom_range(4, 7);
  eh = (1 << (ora_ew(fmt) - 1)) - 1;                 // 偏置：指数居中
  if (fma_mode < 4) eh = $urandom_range(1, (1 << ora_ew(fmt)) - 2);
  @io_fp_a = ora_gen_operand(fmt, ca, eh);
  @io_fp_b = ora_gen_operand(fmt, cb, eh);
  // c 的指数取在乘积指数附近（ea + eb - bias）
  eh = int'((@io_fp_a >> (ora_p(fmt) - 1)) & ((1 << ora_ew(fmt)) - 1))
     + int'((@io_fp_b >> (ora_p(fmt) - 1)) & ((1 << ora_ew(fmt)) - 1)) - ((1 << (ora_ew(fmt) - 1)) - 1);
  @io_fp_c = ora_gen_operand(fmt, ($urandom_range(0, 1) == 0) ? 7 : cc, eh);
  // 1/16：c = -round(a*b)，精确抵消
  if ($urandom_range(0, 15) == 0) begin
    prod = ora_fma(@io_fp_format, @io_fp_a, @io_fp_b, 64'd0, 4'd0, 3'($urandom_range(0, 4)), 1'b0, 1'b0, 1'b0, pfl, pcl);
    @io_op_code = 4'd1;
    @io_fp_aIsFpCanonicalNAN = 1'b0; @io_fp_bIsFpCanonicalNAN = 1'b0; @io_fp_cIsFpCanonicalNAN = 1'b0;
    @io_fp_c = prod ^ (64'd1 << (ora_p(fmt) + ora_ew(fmt) - 1));
  end
end
"""

G = "fma_u_gold."
COV = [("is_fix", G + "is_fix_reg2"), ("fire", "@io_fire")]
for f, nm in ((3, "f64"), (2, "f32"), (1, "f16")):
    COV.append(("fmt_" + nm, "@io_fp_format == 2'd%d" % f))

PAIRS = [
    Pair("FloatFMA", "fma_", clocked=True, stim=STIM, decls=ORACLE, cov=COV,
         exempt=["io_fflags[3]"], arm=["@io_fire && !@reset"], arm_delay=3, cov_min=200),
]

HEADER = """自动生成：verif/ut/FloatFMA/gen.py（scripts/dual_tb_lib.py + 本文件的独立 IEEE 754 oracle）—— 勿手改
FloatFMA：golden vs 重写 FloatFMA_xs 逐拍比对；另有独立参考模型对 golden 逐个操作比结果与 fflags。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
