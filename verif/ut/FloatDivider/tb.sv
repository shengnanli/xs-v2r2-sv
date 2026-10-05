// =============================================================================
// tb —— FloatDivider UT：golden FloatDivider（含 golden 子树 FloatDividerR64 / fpsqrt_r16）与重写件 FloatDivider_xs
// （子树全是重写件）双例化，同时钟同激励逐拍比；另带独立 IEEE oracle（除法、开方各一份）。
//
// 差分比较：start_ready / finish_valid 每拍比（两子单元状态机带复位）；fpdiv_res / fflags 在 finish_valid=0 时两侧都
//   恒 0（本层按 finish_valid 门控），每拍比；finish_valid=1 时：除法结果在 golden 除法器走过一次 PRE_2 → POST_0 之后比
//   （此前余数/商位寄存器是上电值，+random / <seed>017 档两侧不同；同 verif/ut/FloatDividerR64 的口径），开方结果在
//   golden 开方器走过一次迭代态之后比（提前结束路径的 NX 读上一次迭代的残留寄存器，同 verif/ut/fpsqrt_r16 的口径）。
// 独立 oracle（tb 内整数算术，不看 golden）：
//   - 除法：照抄 verif/ut/FloatDividerR64/tb.sv 的 ref_div（RNE/RTZ/RDN/RUP/RMM，rm 5..7 按 RTZ；NaN 规范化；
//     NV/DZ/OF/UF/NX，UF 按「舍入后判 tiny」；canonical-NaN 标志当 qNaN）；
//   - 开方：照抄 verif/ut/fpsqrt_r16/tb.sv 的 oracle（逐位恢复法整数平方根 + 舍入；NV 全比，NX 除 ±0/+Inf/尾数全 0
//     的提前结束路径外都比）；本层把格式编码减 1 后送开方器，所以 oracle 按 fp_format 1/2/3 = f16/f32/f64 取元素。
//   按子单元各自跟踪（golden 的 start 分派不看对外 start_ready，除法忙时开方照样能启动，反之亦然）：子单元自己的
//   start 握手时登记，在它自己的 finish 握手（且另一子单元同拍不出结果）时比。
// 激励：start_valid 3/4、is_sqrt 1/2；fp_format 九成合法（1/2/3），一成任意（含非法 0 —— 开方器收到的是 3）；
//   rm 九成 0..4；finish_ready 3/4；flush 1/150；canonical-NaN 标志各 1/24。
// 覆盖（写进 PASS 判据）：除法 / 开方 oracle 各 >= 8000；3 格式 × 5 rm × {除, 开方} 各 >= 30；除法结果类别 6 类各 >= 50；
//   flush 打断在途运算 >= 50；finish 反压 >= 500；两个子单元同时在忙 >= 1000 拍；每个输出位都见过 0 和 1（fflags 五位都能为 1：DZ/OF/UF 来自除法）。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0, oracle_err = 0, div_checks = 0, sqrt_checks = 0;
  int cyc;
  logic clock = 0;
  always #5 clock = ~clock;
  logic reset;

  logic        start_valid, flush, finish_ready, a_cnan, b_cnan, is_sqrt;
  logic [1:0]  fp_format;
  logic [63:0] opa, opb;
  logic [2:0]  rm;
  logic        g_start_ready, i_start_ready, g_finish_valid, i_finish_valid;
  logic [63:0] g_res, i_res;
  logic [4:0]  g_ff, i_ff;

  FloatDivider u_g (
    .clock(clock), .reset(reset), .io_start_valid_i(start_valid), .io_start_ready_o(g_start_ready),
    .io_flush_i(flush), .io_fp_format_i(fp_format), .io_opa_i(opa), .io_opb_i(opb), .io_is_sqrt_i(is_sqrt),
    .io_rm_i(rm), .io_fp_aIsFpCanonicalNAN(a_cnan), .io_fp_bIsFpCanonicalNAN(b_cnan),
    .io_finish_valid_o(g_finish_valid), .io_finish_ready_i(finish_ready),
    .io_fpdiv_res_o(g_res), .io_fflags_o(g_ff));
  FloatDivider_xs u_i (
    .clock(clock), .reset(reset), .io_start_valid_i(start_valid), .io_start_ready_o(i_start_ready),
    .io_flush_i(flush), .io_fp_format_i(fp_format), .io_opa_i(opa), .io_opb_i(opb), .io_is_sqrt_i(is_sqrt),
    .io_rm_i(rm), .io_fp_aIsFpCanonicalNAN(a_cnan), .io_fp_bIsFpCanonicalNAN(b_cnan),
    .io_finish_valid_o(i_finish_valid), .io_finish_ready_i(finish_ready),
    .io_fpdiv_res_o(i_res), .io_fflags_o(i_ff));

  // ---------------------------------------------------------------------------
  // 差分比较
  // ---------------------------------------------------------------------------
  bit div_seen_pre2 = 0, div_armed = 0, sqrt_armed = 0;
  logic [63:0] seen0_res = '0, seen1_res = '0;
  logic [4:0]  seen0_ff = '0, seen1_ff = '0;
  `define CMP(g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 30) $display("[%0d] MISMATCH %s golden=%h impl=%h", cyc, nm, (g), (i)); end end
  task automatic compare_all();
    bit div_fin, sqrt_fin;
    div_fin  = u_g.u_vector_float_divider_r64.io_finish_valid_o;
    sqrt_fin = u_g.u_vector_float_sqrt_r16.finish_valid_o;
    `CMP(g_start_ready, i_start_ready, "io_start_ready_o")
    `CMP(g_finish_valid, i_finish_valid, "io_finish_valid_o")
    if ((!div_fin || div_armed) && (!sqrt_fin || sqrt_armed)) begin
      `CMP(g_res, i_res, "io_fpdiv_res_o")
      `CMP(g_ff, i_ff, "io_fflags_o")
      seen1_res |= g_res; seen0_res |= ~g_res;
      seen1_ff  |= g_ff;  seen0_ff  |= ~g_ff;
    end
  endtask


  // ---------------------------------------------------------------------------
  // IEEE 754 除法 oracle（fmt：0 f16 / 1 f32 / 2 f64）
  // ---------------------------------------------------------------------------
  localparam int FL_NV = 4, FL_DZ = 3, FL_OF = 2, FL_UF = 1, FL_NX = 0;
  function automatic bit rup(input logic [2:0] mode, input bit sign, input bit lsb, input bit rnd, input bit stk);
    case (mode)
      3'd0: return rnd & (stk | lsb);
      3'd2: return (rnd | stk) & sign;
      3'd3: return (rnd | stk) & ~sign;
      3'd4: return rnd;
      default: return 0;          // RTZ（及 5..7）
    endcase
  endfunction

  int res_class [6];   // 0 规格 1 非规格 2 上溢 3 NaN 4 ∞ 5 零
  function automatic void ref_div(input int fmt, input logic [63:0] a, input logic [63:0] b, input logic [2:0] mode,
                                  input bit a_cnan, input bit b_cnan,
                                  output logic [63:0] res, output logic [4:0] fl);
    int ew, mw, bias, emax_b;
    bit sa, sb, sign, a_nan, b_nan, a_snan, b_snan, a_inf, b_inf, a_zero, b_zero;
    longint ea, eb, xa, xb, e, ebiased, shift;
    logic [127:0] ma, mb, num, q, tmp, sig;
    bit sticky, lost, r, st, up, inexact, tiny;
    ew = (fmt == 2) ? 11 : (fmt == 1) ? 8 : 5;
    mw = (fmt == 2) ? 52 : (fmt == 1) ? 23 : 10;
    bias = (1 << (ew - 1)) - 1;
    emax_b = (1 << ew) - 1;
    sa = a[ew + mw]; sb = b[ew + mw]; sign = sa ^ sb;
    ea = (a >> mw) & ((64'd1 << ew) - 1);  eb = (b >> mw) & ((64'd1 << ew) - 1);
    ma = a & ((128'd1 << mw) - 1);         mb = b & ((128'd1 << mw) - 1);
    a_nan = (ea == emax_b) && (ma != 0);   b_nan = (eb == emax_b) && (mb != 0);
    a_snan = a_nan && !ma[mw - 1];         b_snan = b_nan && !mb[mw - 1];
    a_inf = (ea == emax_b) && (ma == 0);   b_inf = (eb == emax_b) && (mb == 0);
    a_zero = (ea == 0) && (ma == 0);       b_zero = (eb == 0) && (mb == 0);
    // NaN-boxing 失败（canonical-NaN 标志）：该操作数当 quiet NaN，不是 sNaN/0/∞
    if (a_cnan) begin a_nan = 1; a_snan = 0; a_inf = 0; a_zero = 0; end
    if (b_cnan) begin b_nan = 1; b_snan = 0; b_inf = 0; b_zero = 0; end
    fl = '0;
    if (a_nan || b_nan || (a_inf && b_inf) || (a_zero && b_zero)) begin
      res = (64'(emax_b) << mw) | (64'd1 << (mw - 1));      // 正号 quiet NaN
      fl[FL_NV] = a_snan | b_snan | (a_inf & b_inf) | (a_zero & b_zero);
      res_class[3]++;
      return;
    end
    if (a_inf || b_zero) begin
      res = (64'(sign) << (ew + mw)) | (64'(emax_b) << mw);
      fl[FL_DZ] = b_zero & ~a_inf;
      res_class[4]++;
      return;
    end
    if (a_zero || b_inf) begin
      res = 64'(sign) << (ew + mw);
      res_class[5]++;
      return;
    end
    // 有限非零：规格化成 1.xxx（ma/mb 的最高位在 bit mw）
    xa = (ea == 0) ? 1 - bias : ea - bias;  if (ea != 0) ma |= 128'd1 << mw;
    xb = (eb == 0) ? 1 - bias : eb - bias;  if (eb != 0) mb |= 128'd1 << mw;
    while (ma < (128'd1 << mw)) begin ma <<= 1; xa--; end
    while (mb < (128'd1 << mw)) begin mb <<= 1; xb--; end
    e = xa - xb;
    if (ma < mb) begin num = ma << (mw + 5); e--; end
    else         num = ma << (mw + 4);
    q = num / mb;                 // 商在 [2^(mw+4), 2^(mw+5))：p = mw+1 个有效位 + 4 个额外位
    sticky = (num % mb) != 0;
    ebiased = e + bias;
    if (ebiased >= 1) begin
      sig = q >> 4;  r = q[3];  st = (q[2:0] != 0) | sticky;
      up = rup(mode, sign, sig[0], r, st);
      sig += up;
      inexact = r | st;
      if (sig == (128'd1 << (mw + 1))) begin sig >>= 1; ebiased++; end
      if (ebiased >= emax_b) begin
        fl[FL_OF] = 1; fl[FL_NX] = 1;
        if (mode == 0 || mode == 4 || (mode == 3 && !sign) || (mode == 2 && sign))
          res = (64'(sign) << (ew + mw)) | (64'(emax_b) << mw);
        else
          res = (64'(sign) << (ew + mw)) | (64'(emax_b - 1) << mw) | ((64'd1 << mw) - 1);
        res_class[2]++;
        return;
      end
      res = (64'(sign) << (ew + mw)) | (64'(ebiased) << mw) | 64'(sig & ((128'd1 << mw) - 1));
      fl[FL_NX] = inexact;
      res_class[0]++;
      return;
    end
    // 非规格数结果：右移 1−E 位后舍入
    shift = 1 - ebiased;
    if (shift > mw + 8) begin
      tmp = 0; lost = 1;
    end else begin
      tmp  = q >> shift;
      lost = (q & ((128'd1 << shift) - 1)) != 0;
    end
    sig = tmp >> 4;  r = tmp[3];  st = (tmp[2:0] != 0) | lost | sticky;
    up = rup(mode, sign, sig[0], r, st);
    sig += up;
    inexact = r | st;
    // tiny 判定（舍入后、指数无界）：E<0 必 tiny；E==0 时看按 p 位舍入是否进位到 2^emin
    if (ebiased < 0) tiny = 1;
    else tiny = !(((q >> 4) + rup(mode, sign, q[4], q[3], (q[2:0] != 0) | sticky)) == (128'd1 << (mw + 1)));
    fl[FL_UF] = tiny & inexact;
    fl[FL_NX] = inexact;
    res = (64'(sign) << (ew + mw)) | (64'(sig >> mw) << mw) | 64'(sig & ((128'd1 << mw) - 1));
    res_class[1]++;
  endfunction


  int cls_hist [8];
  function automatic logic [63:0] make_fp(input int fmt, input int cls, input int exp_hint);
    int ew, mw, emax_b;
    logic [63:0] m, e, s;
    ew = (fmt == 2) ? 11 : (fmt == 1) ? 8 : 5;
    mw = (fmt == 2) ? 52 : (fmt == 1) ? 23 : 10;
    emax_b = (1 << ew) - 1;
    s = $urandom & 1;
    m = {$urandom, $urandom} & ((64'd1 << mw) - 1);
    case ($urandom_range(0, 7))
      0: m = '0;
      1: m = (64'd1 << mw) - 1;
      2: m = m & {$urandom, $urandom};
      default: ;
    endcase
    case (cls)
      0: begin e = 0; m = 0; end                                  // ±0
      1: begin e = 0; if (m == 0) m = 1; end                       // 非规格数
      2: e = 1;                                                    // 最小规格数附近
      3: begin e = emax_b - 1; end                                 // 最大有限数附近
      4: begin e = emax_b; m = 0; end                              // ±∞
      5: begin e = emax_b; m = m | (64'd1 << (mw - 1)); end        // qNaN
      6: begin e = emax_b; m = m & ~(64'd1 << (mw - 1)); if (m == 0) m = 1; end   // sNaN
      default: begin                                               // 规格数，指数按提示
        if (exp_hint < 1) e = 1; else if (exp_hint > emax_b - 1) e = emax_b - 1; else e = exp_hint;
      end
    endcase
    return (s << (ew + mw)) | (e << mw) | m;
  endfunction

  // 生成一对元素（a, b），偏置指数关系与尾数关系
  task automatic make_pair(input int fmt, output logic [63:0] a, output logic [63:0] b);
    int ew, mw, emax_b, bias, ca, cb, ea, eb, mw_mask;
    ew = (fmt == 2) ? 11 : (fmt == 1) ? 8 : 5;
    mw = (fmt == 2) ? 52 : (fmt == 1) ? 23 : 10;
    emax_b = (1 << ew) - 1;
    bias = (1 << (ew - 1)) - 1;
    ca = ($urandom_range(0, 3) == 0) ? $urandom_range(0, 6) : 7;
    cb = ($urandom_range(0, 3) == 0) ? $urandom_range(0, 6) : 7;
    cls_hist[ca]++;
    eb = $urandom_range(1, emax_b - 1);
    case ($urandom_range(0, 5))
      0: ea = eb + bias + $urandom_range(0, 3) - 1;          // 商指数在上溢边界
      1: ea = eb - bias + 1 - $urandom_range(0, mw + 3);     // 商落入非规格数区
      2: ea = eb - bias - $urandom_range(0, 3);              // 商在最小规格数边界
      default: ea = $urandom_range(1, emax_b - 1);
    endcase
    a = make_fp(fmt, ca, ea);
    b = make_fp(fmt, cb, eb);
    if (cb == 7 && $urandom_range(0, 7) == 0) b &= ~((64'd1 << mw) - 1);                       // 除数 2 的幂
    if (ca == 7 && cb == 7 && $urandom_range(0, 15) == 0)                                      // 尾数相同
      a = (a & ~((64'd1 << mw) - 1)) | (b & ((64'd1 << mw) - 1));
  endtask


  // ---------------------------------------------------------------------------
  // IEEE 754 开方 oracle（照抄 verif/ut/fpsqrt_r16/tb.sv；fmt：0 f16 / 1 f32 / 2 f64）
  // ---------------------------------------------------------------------------
  typedef enum int {K_NORM, K_DENORM, K_ZERO, K_INF, K_QNAN, K_SNAN, K_NEG, K_POW2, K_SQUARE, K_RAND} kind_t;
  localparam int NKIND = 9;
  function automatic logic [63:0] isqrt(input logic [127:0] x);   // 逐位恢复法，结果不超过 64 位
    logic [127:0] r = 0, bitv = 128'd1 << 126, rem = x;
    while (bitv > rem) bitv >>= 2;
    while (bitv != 0) begin
      if (rem >= r + bitv) begin rem -= r + bitv; r = (r >> 1) + bitv; end
      else r >>= 1;
      bitv >>= 2;
    end
    return 64'(r);
  endfunction

  function automatic logic [63:0] make_sq_fp(input int exp_w, input int frac_w, input kind_t k);
    logic [63:0] exp_max, e, f, s;
    exp_max = (64'd1 << exp_w) - 1;
    f = {$urandom, $urandom} & ((64'd1 << frac_w) - 1);
    s = 1'b0;
    case (k)
      K_NORM:   begin e = 64'($urandom_range(1, exp_max - 1)); if ($urandom_range(0, 1) == 0) f = (64'd1 << frac_w) - 1; end
      K_DENORM: begin e = 0; if ($urandom_range(0, 1)) f = f >> $urandom_range(0, frac_w - 1); if (f == 0) f = 1; end
      K_ZERO:   begin e = 0; f = 0; s = $urandom; end
      K_INF:    begin e = exp_max; f = 0; end
      K_QNAN:   begin e = exp_max; f = f | (64'd1 << (frac_w - 1)); end
      K_SNAN:   begin e = exp_max; f = (f & ~(64'd1 << (frac_w - 1))); if (f == 0) f = 1; end
      K_NEG:    begin e = 64'($urandom_range(0, exp_max)); s = 1'b1; end
      K_POW2:   begin e = 64'($urandom_range(1, exp_max - 1)); f = 0; end
      K_SQUARE: begin   // 完全平方：有效位不超过 (frac_w+1)/2 的整数 Y 的平方
        int h = $urandom_range(1, (frac_w + 1) / 2);
        logic [63:0] Y = (64'd1 << (h - 1)) | ({$urandom, $urandom} & ((64'd1 << (h - 1)) - 1));
        logic [127:0] Y2 = 128'(Y) * 128'(Y);
        int t = 0;
        for (int b = 0; b < 128; b++) if (Y2[b]) t = b;     // 最高位
        f = 64'((Y2 << (frac_w - t)) & ((128'd1 << frac_w) - 1));
        e = 64'($urandom_range(1, exp_max - 1));
        if (((e - (exp_max >> 1)) & 1) != (t & 1)) e = (e == exp_max - 1) ? e - 1 : e + 1;  // 指数奇偶配齐
      end
      default:  begin e = 64'($urandom_range(0, exp_max)); s = $urandom; end
    endcase
    return (s << (exp_w + frac_w)) | (e << frac_w) | f;
  endfunction

  // ---- IEEE oracle：返回 {结果, NV, NX, NX 可比} ----
  task automatic oracle(input int fmt, input logic [63:0] op, input logic [2:0] rm, input logic cnan,
                        output logic [63:0] res, output logic nv, output logic nx, output logic nx_cmp);
    int exp_w = (fmt == 0) ? 5 : (fmt == 1) ? 8 : 11;
    int frac_w = (fmt == 0) ? 10 : (fmt == 1) ? 23 : 52;
    int p = frac_w + 1, bias = (1 << (exp_w - 1)) - 1;
    logic [63:0] emax = (64'd1 << exp_w) - 1;
    logic [63:0] x, f, e, qnan;
    logic s;
    x = (fmt == 0) ? {48'b0, op[15:0]} : (fmt == 1) ? {32'b0, op[31:0]} : op;
    s = x[exp_w + frac_w];
    e = (x >> frac_w) & emax;
    f = x & ((64'd1 << frac_w) - 1);
    qnan = (emax << frac_w) | (64'd1 << (frac_w - 1));
    nv = 0; nx = 0; nx_cmp = 1;
    if (cnan) begin res = qnan; return; end
    if (e == emax) begin
      if (f != 0) begin res = qnan; nv = ~f[frac_w - 1]; return; end
      if (s) begin res = qnan; nv = 1; return; end
      res = x; nx_cmp = 0; return;                         // +Inf
    end
    if (e == 0 && f == 0) begin res = x; nx_cmp = 0; return; end   // ±0
    if (s) begin res = qnan; nv = 1; return; end
    if (f == 0) nx_cmp = 0;                               // 尾数全 0：提前结束路径（见文件头）
    begin
      longint E;               // 值 = M · 2^E
      logic [63:0] M;
      logic [127:0] rad;
      logic [63:0] R, Rr;
      int G, t, sh, ue;
      bit sticky, guard, rest, up, lsb;
      if (e == 0) begin M = f; E = 1 - bias - frac_w; end
      else begin M = f | (64'd1 << frac_w); E = longint'(e) - bias - frac_w; end
      while (M[frac_w] == 1'b0) begin M = M << 1; E = E - 1; end   // 非规格数先规格化到 p 位
      if (E % 2 != 0) begin M = M << 1; E = E - 1; end
      G = (p + 7) / 2;                                    // 根至少 p+3 位；被开方数 <= p+1+2G <= 128 位
      rad = 128'(M) << (2 * G);
      R = isqrt(rad);
      sticky = (128'(R) * 128'(R) != rad);
      t = 0;
      for (int b = 0; b < 64; b++) if (R[b]) t = b;
      ue = int'(E / 2) - G + t;                           // 结果的无偏指数
      sh = t + 1 - p;                                     // 要舍掉的位数（>= 3）
      guard = R[sh - 1];
      rest = sticky | ((R & ((64'd1 << (sh - 1)) - 1)) != 0);
      Rr = R >> sh;
      lsb = Rr[0];
      case (rm)
        3'd0:    up = guard & (rest | lsb);               // RNE
        3'd3:    up = guard | rest;                       // RUP（结果为正）
        3'd4:    up = guard;                              // RMM
        default: up = 0;                                  // RTZ / RDN（正数）/ 5..7
      endcase
      Rr = Rr + up;
      if (Rr[p]) begin Rr = Rr >> 1; ue = ue + 1; end
      nx = guard | rest;
      res = (64'(ue + bias) << frac_w) | (Rr & ((64'd1 << frac_w) - 1));
    end
  endtask

  // ---------------------------------------------------------------------------
  // 激励
  // ---------------------------------------------------------------------------
  kind_t sq_kind;
  task automatic drive();
    logic [63:0] a, b, x, y;
    flush        = ($urandom_range(0, 149) == 0);
    finish_ready = ($urandom_range(0, 3) != 0);
    start_valid  = ($urandom_range(0, 3) != 0);
    is_sqrt      = $urandom;
    rm           = ($urandom_range(0, 9) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, 4));
    fp_format    = ($urandom_range(0, 9) == 0) ? 2'($urandom) : 2'($urandom_range(1, 3));
    a_cnan       = ($urandom_range(0, 23) == 0);
    b_cnan       = ($urandom_range(0, 23) == 0);
    a = {$urandom, $urandom}; b = {$urandom, $urandom};
    if (is_sqrt) begin
      sq_kind = kind_t'($urandom_range(0, NKIND - 1));
      case (fp_format)
        2'd3: a = make_sq_fp(11, 52, sq_kind);
        2'd2: a[31:0] = 32'(make_sq_fp(8, 23, sq_kind));
        2'd1: a[15:0] = 16'(make_sq_fp(5, 10, sq_kind));
        default: ;
      endcase
      if ($urandom_range(0, 7) == 0) begin a = {$urandom, $urandom}; sq_kind = K_RAND; end
    end else begin
      case (fp_format)
        2'd3: begin make_pair(2, x, y); a = x; b = y; end
        2'd2: begin make_pair(1, x, y); a[31:0] = x[31:0]; b[31:0] = y[31:0]; end
        2'd1: begin make_pair(0, x, y); a[15:0] = x[15:0]; b[15:0] = y[15:0]; end
        default: ;
      endcase
    end
    opa = a; opb = b;
  endtask

  // ---------------------------------------------------------------------------
  // 主循环：两个子单元各自跟踪在途运算
  //   ★golden 的 start 分派不看对外 start_ready★：is_sqrt=1 的 start_valid 直接送开方器，所以除法器在忙时
  //   开方器照样可以接新运算（反之亦然）。oracle 因此按子单元各记一份：子单元自己的 start 握手（它的 ready &
  //   它的 valid & 无 flush）时登记，在它自己的 finish 握手（finish_valid & finish_ready & 无 flush）且另一个子单元
  //   同拍不出结果时比（同拍两个都出结果时本层按位或，oracle 不比，差分照比）。
  // ---------------------------------------------------------------------------
  bit          op_live [2], op_acn [2], op_bcn [2];
  logic [1:0]  op_fmt [2];
  logic [63:0] op_a [2], op_b [2];
  logic [2:0]  op_rm [2];
  int cov_fmt_rm [2][4][8];
  int cov_flag [5];
  int n_flush_mid = 0, n_backpressure = 0, n_both_busy = 0;

  task automatic oracle_check(input int u);   // u: 0 除法 / 1 开方
    logic [63:0] er, mask;
    logic [4:0]  ef;
    logic        nv, nx, nx_cmp;
    int fmt;
    bit bad;
    fmt  = (op_fmt[u] == 2'd3) ? 2 : (op_fmt[u] == 2'd2) ? 1 : 0;
    mask = (op_fmt[u] == 2'd3) ? '1 : (op_fmt[u] == 2'd2) ? 64'hFFFF_FFFF : 64'hFFFF;
    if (u == 1) begin
      oracle(fmt, op_a[u], op_rm[u], op_acn[u], er, nv, nx, nx_cmp);
      bad = (i_res !== er) || (i_ff[4] !== nv) || (nx_cmp && i_ff[0] !== nx);
      sqrt_checks++;
      ef = {nv, 3'b0, nx};
    end else begin
      ref_div(fmt, op_a[u] & mask, op_b[u] & mask, op_rm[u], op_acn[u], op_bcn[u], er, ef);
      bad = ((i_res & mask) !== (er & mask)) || (i_ff !== ef);
      div_checks++;
      for (int k = 0; k < 5; k++) if (ef[k]) cov_flag[k]++;
    end
    cov_fmt_rm[u][op_fmt[u]][op_rm[u]]++;
    if (bad) begin
      oracle_err++;
      if (oracle_err <= 30)
        $display("[%0d] ORACLE %s fmt=%0d rm=%0d cnan=%0d%0d a=%h b=%h : impl res=%h ff=%b  ref res=%h ff=%b",
                 cyc, u ? "sqrt" : "div", op_fmt[u], op_rm[u], op_acn[u], op_bcn[u], op_a[u], op_b[u], i_res, i_ff, er, ef);
    end
  endtask

  initial begin
    int bad;
    bit fin [2], rdy [2], go [2];
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    reset = 1; start_valid = 0; flush = 0; finish_ready = 0; fp_format = 2'd3; opa = '0; opb = '0; rm = '0;
    a_cnan = 0; b_cnan = 0; is_sqrt = 0;
    op_live[0] = 0; op_live[1] = 0;
    repeat (3) @(posedge clock);
    #1 reset = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      drive();
      #1;
      fin[0] = u_g.u_vector_float_divider_r64.io_finish_valid_o;
      fin[1] = u_g.u_vector_float_sqrt_r16.finish_valid_o;
      rdy[0] = u_g.u_vector_float_divider_r64.io_start_ready_o;
      rdy[1] = u_g.u_vector_float_sqrt_r16.start_ready_o;
      go[0]  = rdy[0] & start_valid & ~is_sqrt & ~flush;
      go[1]  = rdy[1] & start_valid &  is_sqrt & ~flush;
      // ---- 武装：两个子单元各自走过一次完整迭代之后，结果位才两侧确定 ----
      if (u_g.u_vector_float_divider_r64.fsm_q[2]) div_seen_pre2 = 1;
      if (div_seen_pre2 && u_g.u_vector_float_divider_r64.fsm_q[4]) div_armed = 1;
      if (u_g.u_vector_float_sqrt_r16.fsm_q[2]) sqrt_armed = 1;
      compare_all();
      if (!rdy[0] && !rdy[1]) n_both_busy++;
      for (int u = 0; u < 2; u++) begin
        if (fin[u] && finish_ready && !flush && op_live[u] && !fin[1 - u])
          if ((u == 1 && sqrt_armed) || (u == 0 && div_armed)) oracle_check(u);
        if (op_live[u] && !fin[u] && flush) n_flush_mid++;
        if (flush || (fin[u] && finish_ready)) op_live[u] = 0;
        if (go[u]) begin
          op_live[u] = (fp_format != 2'd0);
          op_fmt[u] = fp_format; op_a[u] = opa; op_b[u] = opb; op_rm[u] = rm; op_acn[u] = a_cnan; op_bcn[u] = b_cnan;
        end
      end
      if (g_finish_valid && !finish_ready) n_backpressure++;
    end
    // ---- 判据 ----
    bad = 0;
    for (int s = 0; s < 2; s++) for (int f = 1; f < 4; f++) for (int m = 0; m < 5; m++)
      if (cov_fmt_rm[s][f][m] < 30) begin bad++; $display("COV FAIL %s fmt=%0d rm=%0d : %0d", s ? "sqrt" : "div", f, m, cov_fmt_rm[s][f][m]); end
    $display("cov div result class normal/denormal/overflow/nan/inf/zero : %0d %0d %0d %0d %0d %0d",
             res_class[0], res_class[1], res_class[2], res_class[3], res_class[4], res_class[5]);
    foreach (res_class[k]) if (res_class[k] < 50) begin bad++; $display("COV FAIL res_class %0d", k); end
    $display("cov div flags NV/DZ/OF/UF/NX : %0d %0d %0d %0d %0d", cov_flag[4], cov_flag[3], cov_flag[2], cov_flag[1], cov_flag[0]);
    if (div_checks < 8000 || sqrt_checks < 8000) begin bad++; $display("COV FAIL oracle div=%0d sqrt=%0d", div_checks, sqrt_checks); end
    if (n_flush_mid < 50 || n_backpressure < 500 || n_both_busy < 1000) begin bad++; $display("COV FAIL flush_mid=%0d backpressure=%0d", n_flush_mid, n_backpressure); end
    if (seen1_res != '1 || seen0_res != '1) begin bad++; $display("COV FAIL res bits 1=%h 0=%h", seen1_res, seen0_res); end
    if (seen1_ff != '1 || seen0_ff != '1) begin bad++; $display("COV FAIL fflags bits 1=%b 0=%b", seen1_ff, seen0_ff); end
    $display("COVERAGE div_oracle=%0d sqrt_oracle=%0d flush_mid=%0d backpressure=%0d both_busy=%0d", div_checks, sqrt_checks, n_flush_mid, n_backpressure, n_both_busy);
    $display("ORACLE oracle_errors=%0d", oracle_err);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && oracle_err == 0 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
