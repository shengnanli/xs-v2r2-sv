// =============================================================================
// tb —— VectorFloatDivider UT：golden（含 golden VectorFloatDividerR64 / fpsqrt_vector_r16 子树）与重写件
// VectorFloatDivider_xs（两个子模块及其子树全用本仓重写件）双例化，同时钟同激励逐拍比全部输出；
// 另配独立 IEEE 754 oracle：除法（照搬 verif/ut/VectorFloatDividerR64 的整数算术模型）+ 开方（本 tb 新写，
// 宽整数逐位开平方，见 ref_sqrt）。
//
// 激励（每拍在下降沿换输入）：
//   is_sqrt 1/2；start_valid：start_ready=1 时 3/4，=0 时 1/60（违规发起，只做差分、oracle 暂停，见主循环）；fp_format 九成合法（1 f16 / 2 f32 / 3 f64），一成任意 2 位（含非法 0）；
//   rm 九成 0..4，一成 5..7；finish_ready 3/4；flush 1/150（可打断任一状态）；闲时输入照样乱变。
//   除法操作数沿用 R64 tb 的 make_vec（特殊值 / 上溢 / 非规格边界偏置）；开方操作数逐通道按类别造：
//   ±0 / 非规格数 / 最小、最大规格数附近 / ±∞ / qNaN / sNaN / 随机规格数（含负数）。
//
// 差分比较：start_ready / finish_valid 每拍比（只依赖带复位的状态机）；fpdiv_res / fflags 在 golden 的
//   除法器第一次走到 POST_0、且开方器第一次 finish 之后每拍比（此前结果通路读的是不复位寄存器的上电值，
//   +random 档两侧不同；两个迭代器各完整做过一次后全部结果寄存器都被写成确定值）。
// 独立 oracle（tb 内整数算术，不看 golden、不看重写件内部）：每个未被 flush 的合法操作，在 finish_valid 第一拍
//   按格式逐元素算期望值，与重写件 fpdiv_res / fflags 逐位比。除法同 R64 tb（rm 5..7 按 RTZ 建模）；开方：
//   负数（非 -0）→ 正号 qNaN + NV；NaN → 正号 qNaN（sNaN 置 NV）；±0 → ±0；+∞ → +∞；其余按 p+4 位截断开方
//   加余数 sticky 舍入（rm 5..7 同 RTZ），开方结果不会上溢 / 下溢，只可能 NX。
// 覆盖（写进 PASS 判据）：除法 / 开方 × 3 格式 × 5 舍入模式；除法结果类别六类、五个标志；开方结果类别
//   （规格 / NaN / ∞ / 零）与 NV、NX；flush 打断、finish 反压；每个输出位都见过 0 和 1。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0, oracle_err = 0, oracle_checks = 0;
  int cyc;
  logic clock = 0;
  always #5 clock = ~clock;
  logic reset;

  logic        start_valid, flush, finish_ready, is_sqrt;
  logic [1:0]  fp_format;
  logic [63:0] opa, opb;
  logic [2:0]  rm;
  logic        g_start_ready, i_start_ready, g_finish_valid, i_finish_valid;
  logic [63:0] g_res, i_res;
  logic [19:0] g_ff, i_ff;

  VectorFloatDivider u_g (
    .clock(clock), .reset(reset), .io_start_valid_i(start_valid), .io_start_ready_o(g_start_ready),
    .io_flush_i(flush), .io_fp_format_i(fp_format), .io_opa_i(opa), .io_opb_i(opb), .io_is_sqrt_i(is_sqrt),
    .io_rm_i(rm), .io_finish_valid_o(g_finish_valid), .io_finish_ready_i(finish_ready),
    .io_fpdiv_res_o(g_res), .io_fflags_o(g_ff));
  VectorFloatDivider_xs u_i (
    .clock(clock), .reset(reset), .io_start_valid_i(start_valid), .io_start_ready_o(i_start_ready),
    .io_flush_i(flush), .io_fp_format_i(fp_format), .io_opa_i(opa), .io_opb_i(opb), .io_is_sqrt_i(is_sqrt),
    .io_rm_i(rm), .io_finish_valid_o(i_finish_valid), .io_finish_ready_i(finish_ready),
    .io_fpdiv_res_o(i_res), .io_fflags_o(i_ff));

  // ---------------------------------------------------------------------------
  // 差分比较
  // ---------------------------------------------------------------------------
  bit armed = 0, div_done_once = 0, sqrt_done_once = 0;
  logic [63:0] seen0_res = '0, seen1_res = '0;
  logic [19:0] seen0_ff = '0, seen1_ff = '0;
  bit seen_ready[2], seen_fin[2];
  `define CMP(g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 30) $display("[%0d] MISMATCH %s golden=%h impl=%h", cyc, nm, (g), (i)); end end
  task automatic compare_all();
    `CMP(g_start_ready, i_start_ready, "io_start_ready_o")
    `CMP(g_finish_valid, i_finish_valid, "io_finish_valid_o")
    seen_ready[g_start_ready] = 1; seen_fin[g_finish_valid] = 1;
    if (armed) begin
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

  // 一次向量操作的期望结果
  function automatic void ref_vec(input logic [1:0] f, input logic [63:0] a, input logic [63:0] b, input logic [2:0] mode,
                                  output logic [63:0] res, output logic [19:0] fl);
    logic [63:0] r;
    logic [4:0]  x;
    res = '0; fl = '0;
    case (f)
      2'd3: begin ref_div(2, a, b, mode, r, x); res = r; fl[4:0] = x; end
      2'd2: for (int k = 0; k < 2; k++) begin
              ref_div(1, 64'(a[32*k +: 32]), 64'(b[32*k +: 32]), mode, r, x);
              res[32*k +: 32] = r[31:0]; fl[5*k +: 5] = x;
            end
      default: for (int k = 0; k < 4; k++) begin
              ref_div(0, 64'(a[16*k +: 16]), 64'(b[16*k +: 16]), mode, r, x);
              res[16*k +: 16] = r[15:0]; fl[5*k +: 5] = x;
            end
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // 操作数构造
  // ---------------------------------------------------------------------------
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

  task automatic make_vec(input logic [1:0] f, output logic [63:0] a, output logic [63:0] b);
    logic [63:0] x, y;
    a = {$urandom, $urandom}; b = {$urandom, $urandom};
    case (f)
      2'd3: begin make_pair(2, x, y); a = x; b = y; end
      2'd2: for (int k = 0; k < 2; k++) begin make_pair(1, x, y); a[32*k +: 32] = x[31:0]; b[32*k +: 32] = y[31:0]; end
      2'd1: for (int k = 0; k < 4; k++) begin make_pair(0, x, y); a[16*k +: 16] = x[15:0]; b[16*k +: 16] = y[15:0]; end
      default: ;
    endcase
  endtask


  // ---------------------------------------------------------------------------
  // IEEE 754 开方 oracle（fmt：0 f16 / 1 f32 / 2 f64）
  // ---------------------------------------------------------------------------
  int sq_class [4];   // 0 规格 1 NaN 2 ∞ 3 零
  function automatic logic [255:0] isqrt256(input logic [255:0] n, output bit exact);
    logic [255:0] r, bit_, x;
    x = n; r = 0; bit_ = 256'd1 << 254;
    while (bit_ > x) bit_ >>= 2;
    while (bit_ != 0) begin
      if (x >= r + bit_) begin x -= r + bit_; r = (r >> 1) + bit_; end
      else r >>= 1;
      bit_ >>= 2;
    end
    exact = (x == 0);
    return r;
  endfunction

  function automatic void ref_sqrt(input int fmt, input logic [63:0] a, input logic [2:0] mode,
                                   output logic [63:0] res, output logic [4:0] fl);
    int ew, mw, bias, emax_b, nb, sh;
    bit sa, a_nan, a_snan, a_inf, a_zero, exact, r, st, up;
    longint ea, e;
    logic [255:0] m, root, sig;
    ew = (fmt == 2) ? 11 : (fmt == 1) ? 8 : 5;
    mw = (fmt == 2) ? 52 : (fmt == 1) ? 23 : 10;
    bias = (1 << (ew - 1)) - 1;
    emax_b = (1 << ew) - 1;
    sa = a[ew + mw];
    ea = (a >> mw) & ((64'd1 << ew) - 1);
    m  = a & ((256'd1 << mw) - 1);
    a_nan = (ea == emax_b) && (m != 0);  a_snan = a_nan && !m[mw - 1];
    a_inf = (ea == emax_b) && (m == 0);  a_zero = (ea == 0) && (m == 0);
    fl = '0;
    if (a_nan || (sa && !a_zero)) begin
      res = (64'(emax_b) << mw) | (64'd1 << (mw - 1));      // 正号 quiet NaN
      fl[FL_NV] = a_snan | (sa & !a_nan);
      sq_class[1]++;
      return;
    end
    if (a_zero) begin res = 64'(sa) << (ew + mw); sq_class[3]++; return; end
    if (a_inf)  begin res = 64'(emax_b) << mw;    sq_class[2]++; return; end
    // 有限正数：值 = m * 2^(e)，m 为整数尾数（规格数补隐含位）
    if (ea == 0) e = 1 - bias - mw; else begin e = ea - bias - mw; m |= 256'd1 << mw; end
    if (e % 2 != 0) begin m <<= 1; e -= 1; end             // 指数凑偶
    // root = floor(sqrt(m * 4^(mw+6)))，值 = root * 2^(e/2 - (mw+6))
    root = isqrt256(m << (2 * (mw + 6)), exact);
    nb = 0; for (int k = 0; k < 256; k++) if (root[k]) nb = k + 1;
    sh = nb - (mw + 5);                                    // 归一到 mw+1 个有效位 + 4 位额外位
    st = !exact;
    if (sh > 0) begin st |= (root & ((256'd1 << sh) - 1)) != 0; sig = root >> sh; end
    else sig = root << (-sh);
    // 最高位的指数：(nb-1) + e/2 - (mw+6)
    e = (nb - 1) + e / 2 - (mw + 6) + bias;
    r = sig[3]; st |= (sig[2:0] != 0);
    sig >>= 4;
    up = rup(mode, 1'b0, sig[0], r, st);
    sig += up;
    if (sig == (256'd1 << (mw + 1))) begin sig >>= 1; e++; end
    res = (64'(e) << mw) | 64'(sig & ((256'd1 << mw) - 1));
    fl[FL_NX] = r | st;
    sq_class[0]++;
  endfunction

  function automatic void ref_sqrt_vec(input logic [1:0] f, input logic [63:0] a, input logic [2:0] mode,
                                       output logic [63:0] res, output logic [19:0] fl);
    logic [63:0] r;
    logic [4:0]  x;
    res = '0; fl = '0;
    case (f)
      2'd3: begin ref_sqrt(2, a, mode, r, x); res = r; fl[4:0] = x; end
      2'd2: for (int k = 0; k < 2; k++) begin
              ref_sqrt(1, 64'(a[32*k +: 32]), mode, r, x);
              res[32*k +: 32] = r[31:0]; fl[5*k +: 5] = x;
            end
      default: for (int k = 0; k < 4; k++) begin
              ref_sqrt(0, 64'(a[16*k +: 16]), mode, r, x);
              res[16*k +: 16] = r[15:0]; fl[5*k +: 5] = x;
            end
    endcase
  endfunction

  task automatic make_sqrt_vec(input logic [1:0] f, output logic [63:0] a);
    logic [63:0] x;
    int fmt, w, n, cls, ew, emax_b;
    a = {$urandom, $urandom};
    fmt = (f == 2'd3) ? 2 : (f == 2'd2) ? 1 : 0;
    w = (fmt == 2) ? 64 : (fmt == 1) ? 32 : 16;
    n = 64 / w;
    ew = (fmt == 2) ? 11 : (fmt == 1) ? 8 : 5;
    emax_b = (1 << ew) - 1;
    if (f == 2'd0) return;
    for (int k = 0; k < n; k++) begin
      cls = ($urandom_range(0, 2) == 0) ? $urandom_range(0, 6) : 7;
      x = make_fp(fmt, cls, $urandom_range(1, emax_b - 1));
      if (cls == 7 && $urandom_range(0, 3) != 0) x[w - 1] = 1'b0;   // 规格数大多取正（负数另有 1/4）
      case (fmt)
        2: a = x;
        1: a[32*k +: 32] = x[31:0];
        default: a[16*k +: 16] = x[15:0];
      endcase
    end
  endtask

  // ---------------------------------------------------------------------------
  // 主循环
  // ---------------------------------------------------------------------------
  bit          op_live = 0, op_checked = 0, op_sqrt;
  logic [1:0]  op_fmt;
  logic [63:0] op_a, op_b;
  logic [2:0]  op_rm;
  int cov_fmt_rm [2][4][8];
  int n_ops, n_flush_mid, n_backpressure, n_pow2, n_violate;
  bit taint = 0;
  int cov_flag [5], cov_sq_flag [5];

  task automatic oracle_check();
    logic [63:0] er;
    logic [19:0] ef;
    oracle_checks++;
    if (op_sqrt) begin
      ref_sqrt_vec(op_fmt, op_a, op_rm, er, ef);
      for (int k = 0; k < 20; k++) if (ef[k]) cov_sq_flag[k % 5]++;
    end else begin
      ref_vec(op_fmt, op_a, op_b, op_rm, er, ef);
      for (int k = 0; k < 20; k++) if (ef[k]) cov_flag[k % 5]++;
    end
    if (i_res !== er || i_ff !== ef) begin
      oracle_err++;
      if (oracle_err <= 30)
        $display("[%0d] ORACLE %s fmt=%0d rm=%0d a=%h b=%h : impl res=%h ff=%h  ref res=%h ff=%h",
                 cyc, op_sqrt ? "sqrt" : "div", op_fmt, op_rm, op_a, op_b, i_res, i_ff, er, ef);
    end
  endtask

  initial begin
    int bad;
    logic [63:0] a, b;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    reset = 1; start_valid = 0; flush = 0; finish_ready = 0; fp_format = 2'd3; opa = '0; opb = '0; rm = '0;
    is_sqrt = 0;
    repeat (3) @(posedge clock);
    #1 reset = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      // ---- 本拍的输入 ----
      flush        = ($urandom_range(0, 149) == 0);
      finish_ready = ($urandom_range(0, 3) != 0);
      // 协议：调用方只在 start_ready=1 时发起（start_ready 只依赖寄存器，下降沿采样即本拍值）。
      // 另留 1/60 的违规发起：子迭代器各看自己的 ready，忙的只是另一个时它会真的接下 —— golden 行为照比，
      // 但此后到两个迭代器都空闲之前 oracle 不判（taint）。
      start_valid  = g_start_ready ? ($urandom_range(0, 3) != 0) : ($urandom_range(0, 59) == 0);
      is_sqrt      = $urandom_range(0, 1);
      rm           = ($urandom_range(0, 9) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, 4));
      fp_format    = ($urandom_range(0, 9) == 0) ? 2'($urandom) : 2'($urandom_range(1, 3));
      if (is_sqrt) begin make_sqrt_vec(fp_format, a); b = {$urandom, $urandom}; end
      else make_vec(fp_format, a, b);
      opa = a; opb = b;
      #1;
      // ---- 比较（输出只依赖寄存器，输入换了也不影响）----
      if (u_g.u_vector_float_divider_r64.fsm_q[4]) div_done_once = 1;
      if (u_g.u_vector_float_sqrt_r16.finish_valid_o) sqrt_done_once = 1;
      armed = div_done_once & sqrt_done_once;
      compare_all();
      if (g_finish_valid && op_live && !op_checked && !taint) begin oracle_check(); op_checked = 1; end
      // ---- 记录本拍上升沿将发生的握手 ----
      if (op_live && !g_finish_valid && flush) n_flush_mid++;
      if (g_finish_valid && !finish_ready) n_backpressure++;
      if (flush) op_live = 0;
      else if (g_finish_valid && finish_ready) op_live = 0;
      if (start_valid && !g_start_ready) begin taint = 1; op_live = 0; n_violate++; end
      else if (g_start_ready) taint = 0;
      if (!flush && g_start_ready && start_valid) begin
        op_live    = (fp_format != 2'd0);
        op_checked = 0;
        op_sqrt = is_sqrt; op_fmt = fp_format; op_a = opa; op_b = opb; op_rm = rm;
        n_ops++;
        cov_fmt_rm[is_sqrt][fp_format][rm]++;
        if (!is_sqrt && fp_format == 2'd3 && opb[51:0] == 0) n_pow2++;
      end
    end
    // ---- 判据 ----
    bad = 0;
    for (int s = 0; s < 2; s++) for (int f = 1; f < 4; f++) for (int m = 0; m < 5; m++) begin
      $display("cov %s fmt=%0d rm=%0d : %0d", s ? "sqrt" : "div", f, m, cov_fmt_rm[s][f][m]);
      if (cov_fmt_rm[s][f][m] < NCYCLES / 8000) bad++;
    end
    $display("cov div result class normal/denormal/overflow/nan/inf/zero : %0d %0d %0d %0d %0d %0d",
             res_class[0], res_class[1], res_class[2], res_class[3], res_class[4], res_class[5]);
    foreach (res_class[k]) if (res_class[k] < NCYCLES / 4000) bad++;
    $display("cov div flags NV/DZ/OF/UF/NX : %0d %0d %0d %0d %0d", cov_flag[4], cov_flag[3], cov_flag[2], cov_flag[1], cov_flag[0]);
    foreach (cov_flag[k]) if (cov_flag[k] < NCYCLES / 8000) bad++;
    $display("cov sqrt result class normal/nan/inf/zero : %0d %0d %0d %0d", sq_class[0], sq_class[1], sq_class[2], sq_class[3]);
    foreach (sq_class[k]) if (sq_class[k] < NCYCLES / 4000) bad++;
    $display("cov sqrt flags NV/NX : %0d %0d", cov_sq_flag[4], cov_sq_flag[0]);
    if (cov_sq_flag[4] < NCYCLES / 8000 || cov_sq_flag[0] < NCYCLES / 8000) bad++;
    $display("cov ops=%0d flush-mid=%0d backpressure=%0d f64-pow2-divisor=%0d protocol-violating-start=%0d",
             n_ops, n_flush_mid, n_backpressure, n_pow2, n_violate);
    if (n_flush_mid < 20 || n_backpressure < 100 || n_pow2 < 10 || n_violate < 100) bad++;
    if (seen0_res !== '1 || seen1_res !== '1) begin bad++; $display("fpdiv_res not toggled: seen0=%h seen1=%h", seen0_res, seen1_res); end
    if (seen0_ff !== '1 || seen1_ff !== '1) begin bad++; $display("fflags not toggled: seen0=%h seen1=%h", seen0_ff, seen1_ff); end
    if (!seen_ready[0] || !seen_ready[1] || !seen_fin[0] || !seen_fin[1]) bad++;
    $display("checks=%0d errors=%0d oracle_checks=%0d oracle_err=%0d bad_cov=%0d", checks, errors, oracle_checks, oracle_err, bad);
    if (errors == 0 && oracle_err == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
