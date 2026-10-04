// 自动生成：verif/ut/FloatFMA/gen.py（scripts/dual_tb_lib.py + 本文件的独立 IEEE 754 oracle）—— 勿手改
// FloatFMA：golden vs 重写 FloatFMA_xs 逐拍比对；另有独立参考模型对 golden 逐个操作比结果与 fflags。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= FloatFMA =================
  int unsigned fma_mode = 0;
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
  logic fma_reset;
  logic fma_io_fire;
  logic [63:0] fma_io_fp_a;
  logic [63:0] fma_io_fp_b;
  logic [63:0] fma_io_fp_c;
  logic [2:0] fma_io_round_mode;
  logic [1:0] fma_io_fp_format;
  logic [3:0] fma_io_op_code;
  wire  [63:0] fma_g_io_fp_result, fma_i_io_fp_result;
  logic [63:0] fma_s0_io_fp_result = '0, fma_s1_io_fp_result = '0;
  wire  [4:0] fma_g_io_fflags, fma_i_io_fflags;
  logic [4:0] fma_s0_io_fflags = '0, fma_s1_io_fflags = '0;
  logic fma_io_fp_aIsFpCanonicalNAN;
  logic fma_io_fp_bIsFpCanonicalNAN;
  logic fma_io_fp_cIsFpCanonicalNAN;
  int fma_cov_is_fix = 0;
  int fma_cov_fire = 0;
  int fma_cov_fmt_f64 = 0;
  int fma_cov_fmt_f32 = 0;
  int fma_cov_fmt_f16 = 0;
  logic [0:0] fma_armed = '0;
  int fma_armed_at = -1;
  FloatFMA fma_u_gold (
    .clock(clk),
    .reset(fma_reset),
    .io_fire(fma_io_fire),
    .io_fp_a(fma_io_fp_a),
    .io_fp_b(fma_io_fp_b),
    .io_fp_c(fma_io_fp_c),
    .io_round_mode(fma_io_round_mode),
    .io_fp_format(fma_io_fp_format),
    .io_op_code(fma_io_op_code),
    .io_fp_result(fma_g_io_fp_result),
    .io_fflags(fma_g_io_fflags),
    .io_fp_aIsFpCanonicalNAN(fma_io_fp_aIsFpCanonicalNAN),
    .io_fp_bIsFpCanonicalNAN(fma_io_fp_bIsFpCanonicalNAN),
    .io_fp_cIsFpCanonicalNAN(fma_io_fp_cIsFpCanonicalNAN)
  );
  FloatFMA_xs fma_u_impl (
    .clock(clk),
    .reset(fma_reset),
    .io_fire(fma_io_fire),
    .io_fp_a(fma_io_fp_a),
    .io_fp_b(fma_io_fp_b),
    .io_fp_c(fma_io_fp_c),
    .io_round_mode(fma_io_round_mode),
    .io_fp_format(fma_io_fp_format),
    .io_op_code(fma_io_op_code),
    .io_fp_result(fma_i_io_fp_result),
    .io_fflags(fma_i_io_fflags),
    .io_fp_aIsFpCanonicalNAN(fma_io_fp_aIsFpCanonicalNAN),
    .io_fp_bIsFpCanonicalNAN(fma_io_fp_bIsFpCanonicalNAN),
    .io_fp_cIsFpCanonicalNAN(fma_io_fp_cIsFpCanonicalNAN)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) fma_mode = $urandom_range(0, 15);
      fma_io_fire = 1'($urandom);
      fma_io_fp_a = 64'({$urandom, $urandom});
      fma_io_fp_b = 64'({$urandom, $urandom});
      fma_io_fp_c = 64'({$urandom, $urandom});
      fma_io_round_mode = 3'($urandom);
      fma_io_fp_format = 2'($urandom);
      fma_io_op_code = 4'($urandom);
      fma_io_fp_aIsFpCanonicalNAN = 1'($urandom);
      fma_io_fp_bIsFpCanonicalNAN = 1'($urandom);
      fma_io_fp_cIsFpCanonicalNAN = 1'($urandom);
      fma_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_fma
        begin
          int fmt, eh, ca, cb, cc;
          logic [63:0] prod;
          logic [4:0] pfl;
          int pcl;
          case ($urandom_range(0, 7))
            0, 1, 2: fma_io_fp_format = 2'd3;
            3, 4, 5: fma_io_fp_format = 2'd2;
            default: fma_io_fp_format = 2'($urandom_range(0, 1));
          endcase
          fmt = (fma_io_fp_format == 2'd3) ? 0 : (fma_io_fp_format == 2'd2) ? 1 : 2;
          fma_io_fire       = ($urandom_range(0, 3) != 0);
          fma_io_round_mode = ($urandom_range(0, 15) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, 4));
          fma_io_op_code    = ($urandom_range(0, 15) == 0) ? 4'($urandom_range(5, 15)) : 4'($urandom_range(0, 4));
          fma_io_fp_aIsFpCanonicalNAN = ($urandom_range(0, 31) == 0);
          fma_io_fp_bIsFpCanonicalNAN = ($urandom_range(0, 31) == 0);
          fma_io_fp_cIsFpCanonicalNAN = ($urandom_range(0, 31) == 0);
          // 类别：特殊值约 1/4，次正规 / 极值约 1/4，其余规格化
          ca = ($urandom_range(0, 3) == 0) ? $urandom_range(0, 5) : $urandom_range(4, 7);
          cb = ($urandom_range(0, 3) == 0) ? $urandom_range(0, 5) : $urandom_range(4, 7);
          cc = ($urandom_range(0, 3) == 0) ? $urandom_range(0, 5) : $urandom_range(4, 7);
          eh = (1 << (ora_ew(fmt) - 1)) - 1;                 // 偏置：指数居中
          if (fma_mode < 4) eh = $urandom_range(1, (1 << ora_ew(fmt)) - 2);
          fma_io_fp_a = ora_gen_operand(fmt, ca, eh);
          fma_io_fp_b = ora_gen_operand(fmt, cb, eh);
          // c 的指数取在乘积指数附近（ea + eb - bias）
          eh = int'((fma_io_fp_a >> (ora_p(fmt) - 1)) & ((1 << ora_ew(fmt)) - 1))
             + int'((fma_io_fp_b >> (ora_p(fmt) - 1)) & ((1 << ora_ew(fmt)) - 1)) - ((1 << (ora_ew(fmt) - 1)) - 1);
          fma_io_fp_c = ora_gen_operand(fmt, ($urandom_range(0, 1) == 0) ? 7 : cc, eh);
          // 1/16：c = -round(a*b)，精确抵消
          if ($urandom_range(0, 15) == 0) begin
            prod = ora_fma(fma_io_fp_format, fma_io_fp_a, fma_io_fp_b, 64'd0, 4'd0, 3'($urandom_range(0, 4)), 1'b0, 1'b0, 1'b0, pfl, pcl);
            fma_io_op_code = 4'd1;
            fma_io_fp_aIsFpCanonicalNAN = 1'b0; fma_io_fp_bIsFpCanonicalNAN = 1'b0; fma_io_fp_cIsFpCanonicalNAN = 1'b0;
            fma_io_fp_c = prod ^ (64'd1 << (ora_p(fmt) + ora_ew(fmt) - 1));
          end
        end
      end
      #4;
      if (cyc >= RESET_CYC + 0 && fma_armed_at >= 0 && cyc >= fma_armed_at) begin
        checks++;
        if (fma_g_io_fp_result !== fma_i_io_fp_result) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FloatFMA.io_fp_result g=%h i=%h", cyc, fma_g_io_fp_result, fma_i_io_fp_result);
        end
        fma_s1_io_fp_result |= fma_g_io_fp_result;
        fma_s0_io_fp_result |= ~fma_g_io_fp_result;
        checks++;
        if (fma_g_io_fflags !== fma_i_io_fflags) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FloatFMA.io_fflags g=%h i=%h", cyc, fma_g_io_fflags, fma_i_io_fflags);
        end
        fma_s1_io_fflags |= fma_g_io_fflags;
        fma_s0_io_fflags |= ~fma_g_io_fflags;
        if (fma_u_gold.is_fix_reg2) fma_cov_is_fix++;
        if (fma_io_fire) fma_cov_fire++;
        if (fma_io_fp_format == 2'd3) fma_cov_fmt_f64++;
        if (fma_io_fp_format == 2'd2) fma_cov_fmt_f32++;
        if (fma_io_fp_format == 2'd1) fma_cov_fmt_f16++;
      end
      if (fma_io_fire && !fma_reset) fma_armed[0] = 1'b1;
      if (fma_armed_at < 0 && (&fma_armed)) fma_armed_at = cyc + 1 + 3;
    end

    // ---- 覆盖闸 ----
    if (!(fma_s0_io_fp_result[0] && fma_s1_io_fp_result[0])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[0] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[1] && fma_s1_io_fp_result[1])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[1] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[2] && fma_s1_io_fp_result[2])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[2] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[3] && fma_s1_io_fp_result[3])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[3] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[4] && fma_s1_io_fp_result[4])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[4] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[5] && fma_s1_io_fp_result[5])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[5] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[6] && fma_s1_io_fp_result[6])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[6] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[7] && fma_s1_io_fp_result[7])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[7] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[8] && fma_s1_io_fp_result[8])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[8] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[9] && fma_s1_io_fp_result[9])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[9] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[10] && fma_s1_io_fp_result[10])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[10] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[11] && fma_s1_io_fp_result[11])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[11] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[12] && fma_s1_io_fp_result[12])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[12] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[13] && fma_s1_io_fp_result[13])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[13] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[14] && fma_s1_io_fp_result[14])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[14] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[15] && fma_s1_io_fp_result[15])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[15] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[16] && fma_s1_io_fp_result[16])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[16] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[17] && fma_s1_io_fp_result[17])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[17] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[18] && fma_s1_io_fp_result[18])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[18] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[19] && fma_s1_io_fp_result[19])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[19] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[20] && fma_s1_io_fp_result[20])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[20] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[21] && fma_s1_io_fp_result[21])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[21] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[22] && fma_s1_io_fp_result[22])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[22] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[23] && fma_s1_io_fp_result[23])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[23] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[24] && fma_s1_io_fp_result[24])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[24] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[25] && fma_s1_io_fp_result[25])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[25] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[26] && fma_s1_io_fp_result[26])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[26] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[27] && fma_s1_io_fp_result[27])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[27] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[28] && fma_s1_io_fp_result[28])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[28] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[29] && fma_s1_io_fp_result[29])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[29] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[30] && fma_s1_io_fp_result[30])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[30] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[31] && fma_s1_io_fp_result[31])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[31] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[32] && fma_s1_io_fp_result[32])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[32] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[33] && fma_s1_io_fp_result[33])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[33] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[34] && fma_s1_io_fp_result[34])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[34] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[35] && fma_s1_io_fp_result[35])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[35] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[36] && fma_s1_io_fp_result[36])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[36] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[37] && fma_s1_io_fp_result[37])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[37] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[38] && fma_s1_io_fp_result[38])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[38] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[39] && fma_s1_io_fp_result[39])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[39] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[40] && fma_s1_io_fp_result[40])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[40] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[41] && fma_s1_io_fp_result[41])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[41] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[42] && fma_s1_io_fp_result[42])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[42] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[43] && fma_s1_io_fp_result[43])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[43] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[44] && fma_s1_io_fp_result[44])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[44] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[45] && fma_s1_io_fp_result[45])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[45] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[46] && fma_s1_io_fp_result[46])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[46] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[47] && fma_s1_io_fp_result[47])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[47] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[48] && fma_s1_io_fp_result[48])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[48] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[49] && fma_s1_io_fp_result[49])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[49] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[50] && fma_s1_io_fp_result[50])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[50] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[51] && fma_s1_io_fp_result[51])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[51] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[52] && fma_s1_io_fp_result[52])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[52] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[53] && fma_s1_io_fp_result[53])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[53] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[54] && fma_s1_io_fp_result[54])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[54] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[55] && fma_s1_io_fp_result[55])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[55] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[56] && fma_s1_io_fp_result[56])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[56] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[57] && fma_s1_io_fp_result[57])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[57] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[58] && fma_s1_io_fp_result[58])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[58] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[59] && fma_s1_io_fp_result[59])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[59] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[60] && fma_s1_io_fp_result[60])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[60] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[61] && fma_s1_io_fp_result[61])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[61] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[62] && fma_s1_io_fp_result[62])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[62] 未见过 0 和 1"); end
    if (!(fma_s0_io_fp_result[63] && fma_s1_io_fp_result[63])) begin cov_fail++; $display("[COV] FloatFMA.io_fp_result[63] 未见过 0 和 1"); end
    if (!(fma_s0_io_fflags[0] && fma_s1_io_fflags[0])) begin cov_fail++; $display("[COV] FloatFMA.io_fflags[0] 未见过 0 和 1"); end
    if (!(fma_s0_io_fflags[1] && fma_s1_io_fflags[1])) begin cov_fail++; $display("[COV] FloatFMA.io_fflags[1] 未见过 0 和 1"); end
    if (!(fma_s0_io_fflags[2] && fma_s1_io_fflags[2])) begin cov_fail++; $display("[COV] FloatFMA.io_fflags[2] 未见过 0 和 1"); end
    if (!(fma_s0_io_fflags[4] && fma_s1_io_fflags[4])) begin cov_fail++; $display("[COV] FloatFMA.io_fflags[4] 未见过 0 和 1"); end
    $display("[ARM] FloatFMA armed_at=%0d", fma_armed_at);
    if (fma_armed_at < 0) begin cov_fail++; $display("[ARM] FloatFMA 从未 arm"); end
    $display("[COV] FloatFMA.is_fix = %0d", fma_cov_is_fix);
    if (fma_cov_is_fix < 200) begin cov_fail++; $display("[COV] FloatFMA.is_fix < 200"); end
    $display("[COV] FloatFMA.fire = %0d", fma_cov_fire);
    if (fma_cov_fire < 200) begin cov_fail++; $display("[COV] FloatFMA.fire < 200"); end
    $display("[COV] FloatFMA.fmt_f64 = %0d", fma_cov_fmt_f64);
    if (fma_cov_fmt_f64 < 200) begin cov_fail++; $display("[COV] FloatFMA.fmt_f64 < 200"); end
    $display("[COV] FloatFMA.fmt_f32 = %0d", fma_cov_fmt_f32);
    if (fma_cov_fmt_f32 < 200) begin cov_fail++; $display("[COV] FloatFMA.fmt_f32 < 200"); end
    $display("[COV] FloatFMA.fmt_f16 = %0d", fma_cov_fmt_f16);
    if (fma_cov_fmt_f16 < 200) begin cov_fail++; $display("[COV] FloatFMA.fmt_f16 < 200"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
