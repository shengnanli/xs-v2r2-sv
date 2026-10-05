// =============================================================================
// tb —— VectorFloatAdder UT：golden 与重写件（VectorFloatAdder_xs）双例化，同时钟同激励逐拍比 fp_result / fflags。
// 两侧 child 不同：golden 实例读 golden child，重写件读重写 child（*_xs），所以同时回归了整棵子树
// （FloatAdderWidenFormat ×3、F32WidenF16Mixed ×2、F64Widen ×1、F16 ×2 及其闭包）。
//
// 独立按元素 oracle（tb 内整数算术：fp_add_oracle_pkg 的精确加法 + 本文件的分类/比较，与被测电路无共享代码），
//   对上一次 fire 的激励、不折叠（is_fold=0）、非有序归约时：
//   - fadd/fsub（rm ∈ 0..4）：按结果格式 SEW（f16 4 个 / f32 2 个 / f64 1 个元素）逐元素算 IEEE 和；
//     加宽（res_widening：f16→f32 / f32→f64）时按 uop_idx 从 widen_a / widen_b 取半宽元素（低半 / 高半），
//     opb_widening（.wv）时 a 取 fp_a 的全宽元素；源先精确换到结果格式再加。
//   - fmin/fmax、feq/flt/fle（非加宽）逐元素；
//   - fflags 布局（golden 怪癖照建模）：f16 元素 k → [5k+4:5k]；f32 元素 0 → [4:0]、元素 1 → [9:5]，其余 0；
//     f64 → [4:0]，其余 0。
//   其余（sgnj/fclass/merge/move/归约/折叠/vfwredosum）只做差分。
// 复位域：唯一的本层寄存器 fp_format_reg 与子树寄存器都 RegEnable(fire)、不复位，每次 fire 全写：
//   第一次 fire 之后每拍比全部输出。
// 覆盖（写进 PASS 判据）：三种格式各 >= 5000 次 oracle 比对（加减）、加宽 f16→f32 / f32→f64 各 >= 3000（其中 .wv 各 >= 500、
//   uop_idx=1 各 >= 1000）、min/max/比较 >= 5000；NaN 结果 / NV / OF / NX 各 >= 200；
//   is_fold 三种单热各 >= 1000 拍、fp_format=0 >= 1000 拍；fp_result 64 位与 fflags 20 位每位都见过 0 和 1
//   （fflags 每组 DZ/UF 位加法不产生 → 只要求见过 0）。
// =============================================================================
`timescale 1ns/1ps
module tb;
  import fp_add_oracle_pkg::*;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0, oracle_errors = 0, oracle_checks = 0;
  int cyc;
  logic clock = 0;
  always #5 clock = ~clock;

  // ---- 激励 ----
  logic         fire, uop_idx, opb_w, res_w, wredosum;
  logic [63:0]  fp_a, fp_b, widen_a, widen_b;
  logic [3:0]   mask;
  logic [2:0]   rm, is_fold;
  logic [1:0]   fmt;
  logic [4:0]   op;
  logic [7:0]   mred;
  logic [127:0] vs2_fold;

  logic [63:0] g_r, i_r;
  logic [19:0] g_f, i_f;
  VectorFloatAdder u_g (
    .clock(clock), .io_fire(fire), .io_fp_a(fp_a), .io_fp_b(fp_b), .io_widen_a(widen_a), .io_widen_b(widen_b),
    .io_mask(mask), .io_uop_idx(uop_idx), .io_round_mode(rm), .io_fp_format(fmt), .io_opb_widening(opb_w),
    .io_res_widening(res_w), .io_op_code(op), .io_maskForReduction(mred), .io_is_vfwredosum(wredosum),
    .io_is_fold(is_fold), .io_vs2_fold(vs2_fold), .io_fp_result(g_r), .io_fflags(g_f));
  VectorFloatAdder_xs u_i (
    .clock(clock), .io_fire(fire), .io_fp_a(fp_a), .io_fp_b(fp_b), .io_widen_a(widen_a), .io_widen_b(widen_b),
    .io_mask(mask), .io_uop_idx(uop_idx), .io_round_mode(rm), .io_fp_format(fmt), .io_opb_widening(opb_w),
    .io_res_widening(res_w), .io_op_code(op), .io_maskForReduction(mred), .io_is_vfwredosum(wredosum),
    .io_is_fold(is_fold), .io_vs2_fold(vs2_fold), .io_fp_result(i_r), .io_fflags(i_f));

  // ---- 差分比较与逐位翻转覆盖 ----
  logic [63:0] seen0_r = '0, seen1_r = '0;
  logic [19:0] seen0_f = '0, seen1_f = '0;
  task automatic compare_all();
    checks++;
    if (g_r !== i_r || g_f !== i_f) begin
      errors++;
      if (errors <= 30) $display("[%0d] MISMATCH result g=%h i=%h fflags g=%h i=%h", cyc, g_r, i_r, g_f, i_f);
    end
    seen1_r |= g_r; seen0_r |= ~g_r; seen1_f |= g_f; seen0_f |= ~g_f;
  endtask

  // ---- 按格式的元素工具（f: 1=f16 2=f32 3=f64；元素右对齐放在 64 位里）----
  function automatic int EW(input logic [1:0] f); return (f == 1) ? 5 : (f == 2) ? 8 : 11; endfunction
  function automatic int MW(input logic [1:0] f); return (f == 1) ? 10 : (f == 2) ? 23 : 52; endfunction
  function automatic int SEW(input logic [1:0] f); return (f == 1) ? 16 : (f == 2) ? 32 : 64; endfunction
  function automatic longint unsigned emax(input logic [1:0] f); return (64'd1 << EW(f)) - 1; endfunction
  function automatic longint unsigned e_of(input logic [63:0] x, input logic [1:0] f); return (x >> MW(f)) & emax(f); endfunction
  function automatic longint unsigned m_of(input logic [63:0] x, input logic [1:0] f); return x & ((64'd1 << MW(f)) - 1); endfunction
  function automatic bit s_of(input logic [63:0] x, input logic [1:0] f); return x[EW(f) + MW(f)]; endfunction
  function automatic bit f_nan (input logic [63:0] x, input logic [1:0] f); return e_of(x, f) == emax(f) && m_of(x, f) != 0; endfunction
  function automatic bit f_snan(input logic [63:0] x, input logic [1:0] f); return f_nan(x, f) && !x[MW(f) - 1]; endfunction
  function automatic bit f_inf (input logic [63:0] x, input logic [1:0] f); return e_of(x, f) == emax(f) && m_of(x, f) == 0; endfunction
  function automatic bit f_zero(input logic [63:0] x, input logic [1:0] f); return e_of(x, f) == 0 && m_of(x, f) == 0; endfunction
  function automatic logic [63:0] qnan(input logic [1:0] f); return (emax(f) << MW(f)) | (64'd1 << (MW(f) - 1)); endfunction
  function automatic logic [63:0] mag(input logic [63:0] x, input logic [1:0] f); return x & ((64'd1 << (EW(f) + MW(f))) - 1); endfunction
  function automatic bit f_lt(input logic [63:0] a, input logic [63:0] b, input logic [1:0] f);
    if (f_zero(a, f) && f_zero(b, f)) return 0;
    if (s_of(a, f) != s_of(b, f)) return s_of(a, f);
    if (!s_of(a, f)) return mag(a, f) < mag(b, f);
    return mag(a, f) > mag(b, f);
  endfunction
  function automatic bit f_eq(input logic [63:0] a, input logic [63:0] b, input logic [1:0] f);
    if (f_zero(a, f) && f_zero(b, f)) return 1;
    return a == b;
  endfunction
  function automatic logic [63:0] f_minmax(input logic [63:0] a, input logic [63:0] b, input logic [1:0] f, input bit want_max);
    if (f_nan(a, f) && f_nan(b, f)) return qnan(f);
    if (f_nan(a, f)) return b;
    if (f_nan(b, f)) return a;
    if (f_zero(a, f) && f_zero(b, f)) return want_max ? (s_of(a, f) ? b : a) : (s_of(a, f) ? a : b);
    if (want_max) return f_lt(a, b, f) ? b : a;
    return f_lt(b, a, f) ? b : a;
  endfunction
  // 精确加宽：f（1/2）格式的 x → 下一档格式（2/3）
  function automatic logic [63:0] widen_exact(input logic [63:0] x, input logic [1:0] f);
    logic [1:0] t = f + 1;
    longint unsigned e = e_of(x, f), m = m_of(x, f);
    int bias_s = (1 << (EW(f) - 1)) - 1, bias_t = (1 << (EW(t) - 1)) - 1;
    int ee;
    bit s = s_of(x, f);
    if (e == emax(f)) return (64'(s) << (EW(t) + MW(t))) | (emax(t) << MW(t)) | (m << (MW(t) - MW(f)));
    if (e == 0 && m == 0) return 64'(s) << (EW(t) + MW(t));
    ee = (e == 0) ? 1 : int'(e);
    if (e == 0) while (m[MW(f)] == 0) begin m = m << 1; ee--; end    // 非规格数规格化
    m = m & ((64'd1 << MW(f)) - 1);
    return (64'(s) << (EW(t) + MW(t))) | (64'(ee - bias_s + bias_t) << MW(t)) | (m << (MW(t) - MW(f)));
  endfunction
  // 一个元素的 IEEE 加法：返回 {结果, fflags}
  task automatic elem_add(input logic [63:0] a, input logic [63:0] b, input bit sub, input logic [2:0] r,
                          input logic [1:0] f, output logic [63:0] res, output logic [4:0] fl);
    logic [63:0] bb;
    fp_res_t x;
    bit nv;
    bb = b ^ (64'(sub) << (EW(f) + MW(f)));
    fl = 0;
    if (f_nan(a, f) || f_nan(b, f) || (f_inf(a, f) && f_inf(bb, f) && s_of(a, f) != s_of(bb, f))) begin
      res = qnan(f);
      nv  = f_snan(a, f) || f_snan(b, f) || (f_inf(a, f) && f_inf(bb, f) && s_of(a, f) != s_of(bb, f));
      fl  = {nv, 4'b0};
    end else if (f_inf(a, f) || f_inf(bb, f)) begin
      res = f_inf(a, f) ? a : bb;
    end else begin
      x   = exact_add(MW(f) + 1, EW(f), s_of(a, f), 11'(e_of(a, f)), 52'(m_of(a, f)),
                      s_of(bb, f), 11'(e_of(bb, f)), 52'(m_of(bb, f)), r);
      res = x.bits;
      fl  = {2'b0, x.of, 1'b0, x.nx};
    end
  endtask

  // ---- 独立 oracle ----
  logic [63:0] q_a, q_b, q_wa, q_wb;
  logic        q_uop, q_opbw, q_resw, q_wro;
  logic [2:0]  q_rm, q_fold;
  logic [1:0]  q_fmt;
  logic [4:0]  q_op;
  longint ora_add [4], ora_widen [4], ora_wv [4], ora_uop1 [4], ora_cmp = 0;
  longint ora_nan = 0, ora_nv = 0, ora_of = 0, ora_nx = 0;
  task automatic oracle_check();
    logic [63:0] exp_r, a, b, er; logic [19:0] exp_f; logic [4:0] fl;
    logic [1:0] sf;           // 源格式
    int n, w, ws;
    bit addsub;
    addsub = (q_op == 5'h00 || q_op == 5'h01);
    if (q_fold != 0 || q_wro || q_fmt == 0) return;
    if (!(addsub || q_op == 5'h02 || q_op == 5'h03 || q_op == 5'h09 || q_op == 5'h0B || q_op == 5'h0C)) return;
    if (addsub && q_rm > 3'd4) return;
    if (q_resw && (!addsub || q_fmt == 1)) return;
    w  = SEW(q_fmt);
    n  = 64 / w;
    sf = q_fmt - 1;
    ws = SEW(sf);
    exp_r = 0; exp_f = 0;
    for (int k = 0; k < n; k++) begin
      if (q_resw) begin
        // 加宽源：uop_idx 选半宽元素所在的半边（f16→f32：低半 [15:0]/[31:16]，高半 [47:32]/[63:48]；f32→f64：[31:0] / [63:32]）
        b = widen_exact((q_wb >> (ws * (k + (q_uop ? n : 0)))) & ((64'd1 << ws) - 1), sf);
        a = q_opbw ? ((q_a >> (w * k)) & ((w == 64) ? '1 : ((64'd1 << w) - 1)))
                   : widen_exact((q_wa >> (ws * (k + (q_uop ? n : 0)))) & ((64'd1 << ws) - 1), sf);
      end else begin
        a = (q_a >> (w * k)) & ((w == 64) ? '1 : ((64'd1 << w) - 1));
        b = (q_b >> (w * k)) & ((w == 64) ? '1 : ((64'd1 << w) - 1));
      end
      fl = 0;
      case (q_op)
        5'h00, 5'h01: begin
          elem_add(a, b, q_op[0], q_rm, q_fmt, er, fl);
          if (er == qnan(q_fmt)) ora_nan++;
        end
        5'h02, 5'h03: begin er = f_minmax(a, b, q_fmt, q_op == 5'h03); fl = {f_snan(a, q_fmt) || f_snan(b, q_fmt), 4'b0}; end
        5'h09: begin er = !(f_nan(a, q_fmt) || f_nan(b, q_fmt)) && f_eq(a, b, q_fmt); fl = {f_snan(a, q_fmt) || f_snan(b, q_fmt), 4'b0}; end
        5'h0B: begin er = !(f_nan(a, q_fmt) || f_nan(b, q_fmt)) && f_lt(a, b, q_fmt); fl = {f_nan(a, q_fmt) || f_nan(b, q_fmt), 4'b0}; end
        default: begin er = !(f_nan(a, q_fmt) || f_nan(b, q_fmt)) && (f_lt(a, b, q_fmt) || f_eq(a, b, q_fmt));
                       fl = {f_nan(a, q_fmt) || f_nan(b, q_fmt), 4'b0}; end
      endcase
      if (fl[4]) ora_nv++; if (fl[2]) ora_of++; if (fl[0]) ora_nx++;
      exp_r |= er << (w * k);
      exp_f |= 20'(fl) << (5 * k);
    end
    if (addsub) begin
      if (q_resw) begin ora_widen[q_fmt]++; if (q_opbw) ora_wv[q_fmt]++; if (q_uop) ora_uop1[q_fmt]++; end
      else ora_add[q_fmt]++;
    end else ora_cmp++;
    oracle_checks++;
    if (i_r !== exp_r || i_f !== exp_f) begin
      oracle_errors++;
      if (oracle_errors <= 30)
        $display("[%0d] ORACLE fmt=%0d op=%h rm=%0d resw=%0d opbw=%0d uop=%0d a=%h b=%h wa=%h wb=%h: expect r=%h f=%h, got r=%h f=%h",
                 cyc, q_fmt, q_op, q_rm, q_resw, q_opbw, q_uop, q_a, q_b, q_wa, q_wb, exp_r, exp_f, i_r, i_f);
    end
  endtask

  // ---- 操作数构造：按格式造一个元素 ----
  function automatic logic [63:0] pick_elem(input logic [1:0] f, input logic [63:0] near);
    longint unsigned e, m, em = emax(f);
    bit s = $urandom;
    m = {$urandom, $urandom} & ((64'd1 << MW(f)) - 1);
    case ($urandom_range(0, 15))
      0: begin e = 0; m = 0; end                                   // ±0
      1: begin e = em; m = 0; end                                  // ±Inf
      2: begin e = em; m = m | (64'd1 << (MW(f) - 1)); end         // qNaN
      3: begin e = em; m = m & ~(64'd1 << (MW(f) - 1)); if (m == 0) m = 1; end   // sNaN
      4: e = 0;                                                    // 非规格数
      5: e = em - 1;                                               // 上溢附近
      6, 7, 8, 9: begin                                            // 与 near 同量级（far/close 边界、大量抵消）
        e = e_of(near, f);
        case ($urandom_range(0, 3))
          0: ;
          1: e = (e < em - 1) ? e + 1 : e;
          2: e = (e > 0) ? e - 1 : e;
          default: e = (e > 3) ? e - $urandom_range(0, 3) : e;
        endcase
        if (e == em) e = em - 1;
        if ($urandom_range(0, 1)) m = m_of(near, f) ^ ($urandom_range(0, 7));
        s = $urandom_range(0, 1) ? s_of(near, f) : s;
      end
      default: e = $urandom_range(0, em - 1);
    endcase
    return (64'(s) << (EW(f) + MW(f))) | (64'(e) << MW(f)) | 64'(m);
  endfunction
  function automatic logic [63:0] pack(input logic [1:0] f, input logic [63:0] ref_word);
    int w = SEW(f), n = 64 / w;
    logic [63:0] r = 0;
    for (int k = 0; k < n; k++)
      r |= pick_elem(f, (ref_word >> (w * k)) & ((w == 64) ? '1 : ((64'd1 << w) - 1))) << (w * k);
    return r;
  endfunction

  task automatic drive();
    logic [1:0] sf;
    fire     = ($urandom_range(0, 3) != 0);
    rm       = ($urandom_range(0, 7) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, 4));
    fmt      = ($urandom_range(0, 15) == 0) ? 2'd0 : 2'($urandom_range(1, 3));
    op       = ($urandom_range(0, 2) == 0) ? 5'($urandom) : (($urandom_range(0, 2) == 0) ? 5'($urandom_range(2, 3)) : 5'($urandom_range(0, 1)));
    if ($urandom_range(0, 7) == 0) op = ($urandom_range(0, 1)) ? 5'h09 : 5'($urandom_range(11, 12));
    uop_idx  = $urandom;
    mask     = $urandom;
    mred     = $urandom;
    res_w    = (fmt >= 2) && ($urandom_range(0, 3) == 0);
    opb_w    = res_w ? ($urandom_range(0, 3) == 0) : ($urandom_range(0, 15) == 0);
    wredosum = ($urandom_range(0, 15) == 0);
    case ($urandom_range(0, 15))
      0: is_fold = 3'b001;
      1: is_fold = 3'b010;
      2: is_fold = 3'b100;
      3: is_fold = $urandom;
      default: is_fold = 3'b000;
    endcase
    vs2_fold = {$urandom, $urandom, $urandom, $urandom};
    if (fmt == 0) begin
      fp_a = {$urandom, $urandom}; fp_b = {$urandom, $urandom}; widen_a = {$urandom, $urandom}; widen_b = {$urandom, $urandom};
      return;
    end
    fp_a = pack(fmt, {$urandom, $urandom});
    fp_b = pack(fmt, fp_a);
    sf   = (fmt == 1) ? 2'd1 : fmt - 1;
    widen_a = pack(sf, {$urandom, $urandom});
    widen_b = pack(sf, widen_a);
    if (opb_w) begin    // .wv：a 已是结果格式，让它和加宽后的 b 同量级
      fp_a = pack(fmt, {$urandom, $urandom});
    end
    if ($urandom_range(0, 7) == 0) begin fp_a = {$urandom, $urandom}; fp_b = {$urandom, $urandom}; end
    if ($urandom_range(0, 7) == 0) vs2_fold = {pack(fmt, fp_a), pack(fmt, fp_b)};
  endtask

  int fires = 0, idles = 0, cov_fold [8], cov_fmt0 = 0;
  initial begin
    bit armed = 0, q_valid = 0;
    bit cov_ok = 1;
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    fire = 0; fp_a = 0; fp_b = 0; widen_a = 0; widen_b = 0; mask = 0; uop_idx = 0; rm = 0; fmt = 0; opb_w = 0;
    res_w = 0; op = 0; mred = 0; wredosum = 0; is_fold = 0; vs2_fold = 0;
    foreach (ora_add[k]) begin ora_add[k] = 0; ora_widen[k] = 0; ora_wv[k] = 0; ora_uop1[k] = 0; end
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      #1;
      if (armed) compare_all();
      if (q_valid) oracle_check();
      drive();
      @(posedge clock);
      if (fire) begin
        armed = 1; q_valid = 1; fires++;
        cov_fold[is_fold]++; if (fmt == 0) cov_fmt0++;
        q_a = fp_a; q_b = fp_b; q_wa = widen_a; q_wb = widen_b; q_uop = uop_idx; q_opbw = opb_w; q_resw = res_w;
        q_wro = wredosum; q_rm = rm; q_fold = is_fold; q_fmt = fmt; q_op = op;
      end else idles++;
      @(negedge clock);
    end
    for (int f = 1; f <= 3; f++) if (ora_add[f] < 5000) begin cov_ok = 0; $display("COV FAIL add fmt%0d=%0d", f, ora_add[f]); end
    for (int f = 2; f <= 3; f++) if (ora_widen[f] < 3000 || ora_wv[f] < 500 || ora_uop1[f] < 1000) begin
      cov_ok = 0; $display("COV FAIL widen fmt%0d=%0d wv=%0d uop1=%0d", f, ora_widen[f], ora_wv[f], ora_uop1[f]);
    end
    if (ora_cmp < 5000) begin cov_ok = 0; $display("COV FAIL cmp=%0d", ora_cmp); end
    if (ora_nan < 200 || ora_nv < 200 || ora_of < 200 || ora_nx < 200) begin
      cov_ok = 0; $display("COV FAIL nan=%0d nv=%0d of=%0d nx=%0d", ora_nan, ora_nv, ora_of, ora_nx);
    end
    if (cov_fold[1] < 1000 || cov_fold[2] < 1000 || cov_fold[4] < 1000 || cov_fmt0 < 1000) begin
      cov_ok = 0; $display("COV FAIL fold1=%0d fold2=%0d fold4=%0d fmt0=%0d", cov_fold[1], cov_fold[2], cov_fold[4], cov_fmt0);
    end
    if (seen1_r != '1 || seen0_r != '1) begin cov_ok = 0; $display("COV FAIL result bits 1=%h 0=%h", seen1_r, seen0_r); end
    if (seen1_f != 20'b10101_10101_10101_10101 || seen0_f != '1) begin cov_ok = 0; $display("COV FAIL fflags bits 1=%b 0=%b", seen1_f, seen0_f); end
    $display("COVERAGE fires=%0d idles=%0d add f16/f32/f64=%0d/%0d/%0d widen f32/f64=%0d/%0d (wv %0d/%0d, uop1 %0d/%0d) cmp=%0d fold 1/2/4=%0d/%0d/%0d fmt0=%0d",
             fires, idles, ora_add[1], ora_add[2], ora_add[3], ora_widen[2], ora_widen[3], ora_wv[2], ora_wv[3],
             ora_uop1[2], ora_uop1[3], ora_cmp, cov_fold[1], cov_fold[2], cov_fold[4], cov_fmt0);
    $display("ORACLE checks=%0d nan=%0d nv=%0d of=%0d nx=%0d oracle_errors=%0d", oracle_checks, ora_nan, ora_nv, ora_of, ora_nx, oracle_errors);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && oracle_errors == 0 && cov_ok) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
