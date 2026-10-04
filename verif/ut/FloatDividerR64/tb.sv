// =============================================================================
// tb —— FloatDividerR64 UT：golden（含 golden 子树）与重写件 FloatDividerR64_xs（含重写子树）
// 双例化，同时钟同激励逐拍比全部输出；另配一个独立的 IEEE 754 除法 oracle。
//
// 激励（每拍在下降沿换输入）：
//   start_valid 随机（空闲时 3/4 发起），fp_format 九成合法（f16/f32/f64 各 1/3），一成任意 2 位（含非法 0）；
//   rm 九成 0..4，一成 5..7；finish_ready 3/4；flush 1/150（可打断任一状态）；闲时 opa/opb/rm 照样乱变。
//   元素放在操作数低位（f64 [63:0] / f32 [31:0] / f16 [15:0]），高位随机（golden 不看）。
//   操作数按类别造：±0 / 非规格数 / 最小规格数 / 最大有限数 / ±∞ / qNaN / sNaN / 随机规格数，
//   指数关系另偏置到"商上溢""商落入非规格数"两端；除数尾数 1/8 全 0（2 的幂快速通路）、被除数 1/16 等于除数尾数。
//   fp_aIsFpCanonicalNAN / fp_bIsFpCanonicalNAN 各 1/24 置 1（该操作数强制当 quiet NaN）。
//
// 差分比较：start_ready / finish_valid 每拍比（只依赖带复位的状态机与 PRE_0 必写的指数差）；fpdiv_res / fflags
//   从 golden 走过一次 PRE_2 之后第一次到 POST_0 起每拍比（此前余数/商位寄存器还是上电值，+random 档两侧不同）。
// 独立 oracle（tb 内整数算术，不看 golden；与 VectorFloatDividerR64 UT 同一份 ref_div，另加 canonical-NaN）：
//   每个未被 flush 的合法操作，在 finish_valid 第一拍算 IEEE 754 商（RNE/RTZ/RDN/RUP/RMM；rm 5..7 按 RTZ），
//   含 NaN 规范化（正号 quiet NaN）、NV/DZ/OF/UF/NX（UF 按 RISC-V 的"舍入后判 tiny"），
//   与 fpdiv_res 的本格式位（f64 [63:0] / f32 [31:0] / f16 [15:0]）及 fflags 逐位比。
// 覆盖（写进 PASS 判据）：3 格式 × 5 舍入模式；结果类别（规格 / 非规格 / 上溢 / NaN / ∞ / 0）；五个标志各自出现；
//   2 的幂除数、需左规（PRE_1）路径、canonical-NaN 两侧、flush 打断、finish 反压；每个输出位都见过 0 和 1。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0, oracle_err = 0, oracle_checks = 0;
  int cyc;
  logic clock = 0;
  always #5 clock = ~clock;
  logic reset;

  logic        start_valid, flush, finish_ready, a_cnan, b_cnan;
  logic [1:0]  fp_format;
  logic [63:0] opa, opb;
  logic [2:0]  rm;
  logic        g_start_ready, i_start_ready, g_finish_valid, i_finish_valid;
  logic [63:0] g_res, i_res;
  logic [4:0]  g_ff, i_ff;

  FloatDividerR64 u_g (
    .clock(clock), .reset(reset), .io_start_valid_i(start_valid), .io_start_ready_o(g_start_ready),
    .io_flush_i(flush), .io_fp_format_i(fp_format), .io_opa_i(opa), .io_opb_i(opb), .io_rm_i(rm),
    .io_fp_aIsFpCanonicalNAN(a_cnan), .io_fp_bIsFpCanonicalNAN(b_cnan),
    .io_finish_valid_o(g_finish_valid), .io_finish_ready_i(finish_ready),
    .io_fpdiv_res_o(g_res), .io_fflags_o(g_ff));
  FloatDividerR64_xs u_i (
    .clock(clock), .reset(reset), .io_start_valid_i(start_valid), .io_start_ready_o(i_start_ready),
    .io_flush_i(flush), .io_fp_format_i(fp_format), .io_opa_i(opa), .io_opb_i(opb), .io_rm_i(rm),
    .io_fp_aIsFpCanonicalNAN(a_cnan), .io_fp_bIsFpCanonicalNAN(b_cnan),
    .io_finish_valid_o(i_finish_valid), .io_finish_ready_i(finish_ready),
    .io_fpdiv_res_o(i_res), .io_fflags_o(i_ff));

  // ---------------------------------------------------------------------------
  // 差分比较
  // ---------------------------------------------------------------------------
  bit armed = 0, seen_pre2 = 0;
  logic [63:0] seen0_res = '0, seen1_res = '0;
  logic [4:0]  seen0_ff = '0, seen1_ff = '0;
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

  task automatic make_op(input logic [1:0] f, output logic [63:0] a, output logic [63:0] b);
    logic [63:0] x, y;
    a = {$urandom, $urandom}; b = {$urandom, $urandom};
    case (f)
      2'd3: begin make_pair(2, x, y); a = x; b = y; end
      2'd2: begin make_pair(1, x, y); a[31:0] = x[31:0]; b[31:0] = y[31:0]; end
      2'd1: begin make_pair(0, x, y); a[15:0] = x[15:0]; b[15:0] = y[15:0]; end
      default: ;
    endcase
  endtask

  // ---------------------------------------------------------------------------
  // 主循环
  // ---------------------------------------------------------------------------
  bit          op_live = 0, op_checked = 0, op_acn, op_bcn;
  logic [1:0]  op_fmt;
  logic [63:0] op_a, op_b;
  logic [2:0]  op_rm;
  int cov_fmt_rm [4][8];
  int n_ops, n_flush_mid, n_backpressure, n_pow2, n_pre1, n_acn, n_bcn;
  int cov_flag [5];

  task automatic oracle_check();
    logic [63:0] er, mask;
    logic [4:0]  ef;
    int fmt;
    oracle_checks++;
    fmt  = (op_fmt == 2'd3) ? 2 : (op_fmt == 2'd2) ? 1 : 0;
    mask = (op_fmt == 2'd3) ? '1 : (op_fmt == 2'd2) ? 64'hFFFF_FFFF : 64'hFFFF;
    ref_div(fmt, op_a & mask, op_b & mask, op_rm, op_acn, op_bcn, er, ef);
    for (int k = 0; k < 5; k++) if (ef[k]) cov_flag[k]++;
    if ((i_res & mask) !== (er & mask) || i_ff !== ef) begin
      oracle_err++;
      if (oracle_err <= 30)
        $display("[%0d] ORACLE fmt=%0d rm=%0d cnan=%0d%0d a=%h b=%h : impl res=%h ff=%h  ref res=%h ff=%h",
                 cyc, op_fmt, op_rm, op_acn, op_bcn, op_a, op_b, i_res & mask, i_ff, er & mask, ef);
    end
  endtask

  initial begin
    int bad;
    logic [63:0] a, b;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    reset = 1; start_valid = 0; flush = 0; finish_ready = 0; fp_format = 2'd3; opa = '0; opb = '0; rm = '0;
    a_cnan = 0; b_cnan = 0;
    repeat (3) @(posedge clock);
    #1 reset = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      // ---- 本拍的输入 ----
      flush        = ($urandom_range(0, 149) == 0);
      finish_ready = ($urandom_range(0, 3) != 0);
      start_valid  = ($urandom_range(0, 3) != 0);
      rm           = ($urandom_range(0, 9) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, 4));
      fp_format    = ($urandom_range(0, 9) == 0) ? 2'($urandom) : 2'($urandom_range(1, 3));
      a_cnan       = ($urandom_range(0, 23) == 0);
      b_cnan       = ($urandom_range(0, 23) == 0);
      make_op(fp_format, a, b);
      opa = a; opb = b;
      #1;
      // ---- 比较（输出只依赖寄存器，输入换了也不影响）----
      if (u_g.fsm_q[2]) seen_pre2 = 1;
      if (seen_pre2 && u_g.fsm_q[4]) armed = 1;
      compare_all();
      if (g_finish_valid && op_live && !op_checked) begin oracle_check(); op_checked = 1; end
      if (u_g.fsm_q[1]) n_pre1++;
      // ---- 记录本拍上升沿将发生的握手 ----
      if (op_live && !g_finish_valid && flush) n_flush_mid++;
      if (g_finish_valid && !finish_ready) n_backpressure++;
      if (flush) op_live = 0;
      else if (g_finish_valid && finish_ready) op_live = 0;
      if (!flush && g_start_ready && start_valid) begin
        op_live    = (fp_format != 2'd0);
        op_checked = 0;
        op_fmt = fp_format; op_a = opa; op_b = opb; op_rm = rm; op_acn = a_cnan; op_bcn = b_cnan;
        n_ops++;
        if (a_cnan) n_acn++;
        if (b_cnan) n_bcn++;
        cov_fmt_rm[fp_format][rm]++;
        if (fp_format == 2'd3 && opb[51:0] == 0) n_pow2++;
      end
    end
    // ---- 判据 ----
    bad = 0;
    for (int f = 1; f < 4; f++) for (int m = 0; m < 5; m++) begin
      $display("cov fmt=%0d rm=%0d : %0d", f, m, cov_fmt_rm[f][m]);
      if (cov_fmt_rm[f][m] < NCYCLES / 4000) bad++;
    end
    $display("cov illegal fmt ops=%0d  rm5..7 ops(f64)=%0d", cov_fmt_rm[0][0] + cov_fmt_rm[0][1] + cov_fmt_rm[0][2],
             cov_fmt_rm[3][5] + cov_fmt_rm[3][6] + cov_fmt_rm[3][7]);
    $display("cov result class normal/denormal/overflow/nan/inf/zero : %0d %0d %0d %0d %0d %0d",
             res_class[0], res_class[1], res_class[2], res_class[3], res_class[4], res_class[5]);
    foreach (res_class[k]) if (res_class[k] < NCYCLES / 2000) bad++;
    $display("cov flags NV/DZ/OF/UF/NX : %0d %0d %0d %0d %0d", cov_flag[4], cov_flag[3], cov_flag[2], cov_flag[1], cov_flag[0]);
    foreach (cov_flag[k]) if (cov_flag[k] < NCYCLES / 4000) bad++;
    $display("cov ops=%0d flush-mid=%0d backpressure=%0d f64-pow2-divisor=%0d pre1-cycles=%0d a_cnan=%0d b_cnan=%0d",
             n_ops, n_flush_mid, n_backpressure, n_pow2, n_pre1, n_acn, n_bcn);
    if (n_flush_mid < 20 || n_backpressure < 100 || n_pow2 < 20 || n_pre1 < 100 || n_acn < 100 || n_bcn < 100) bad++;
    if (seen0_res !== '1 || seen1_res !== '1) begin bad++; $display("fpdiv_res not toggled: seen0=%h seen1=%h", seen0_res, seen1_res); end
    if (seen0_ff !== '1 || seen1_ff !== '1) begin bad++; $display("fflags not toggled: seen0=%h seen1=%h", seen0_ff, seen1_ff); end
    if (!seen_ready[0] || !seen_ready[1] || !seen_fin[0] || !seen_fin[1]) bad++;
    $display("checks=%0d errors=%0d oracle_checks=%0d oracle_err=%0d bad_cov=%0d", checks, errors, oracle_checks, oracle_err, bad);
    if (errors == 0 && oracle_err == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
