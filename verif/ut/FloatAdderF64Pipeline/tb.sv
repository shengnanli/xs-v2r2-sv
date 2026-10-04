// =============================================================================
// tb —— FloatAdderF64Pipeline UT：golden 与重写件（FloatAdderF64Pipeline_xs）双例化，同时钟同激励逐拍比。
// 两侧 child 不同：golden 实例读 golden child，重写件读重写 child（*_xs），所以同时回归了整棵子树。
//
// 独立 oracle（fp_add_oracle_pkg 的精确加法 + fp64_misc_oracle_pkg 的比较/分类，与被测电路无共享代码），
// 对上一次 fire 的激励：
//   - canonical NaN 标志：置 1 的操作数按 qNaN 处理（sgnj 里 a 换成 7FF8…、b 的符号取 0；fclass 给 bit9）；
//   - fadd/fsub（rm ∈ 0..4）：NaN 输入或 Inf-Inf → 7FF8…，NV = 有 sNaN 或 Inf-Inf；Inf → 带符号 Inf；
//     有限数 → 精确和按 rm 舍入，fflags = {0,0,OF,0,NX}；
//   - fmin/fmax（minNum/maxNum）、fminm/fmaxm（minimum/maximum）、feq/flt/fle（flt/fle 遇 NaN 置 NV）、
//     fltq/fleq（只有 sNaN 置 NV）、fsgnj/fsgnjn/fsgnjx、fclass；其余 op 码结果 0、fflags 0。
// 复位域：全部寄存器 RegEnable(fire)、不复位，且每次 fire 每个寄存器都被写——第一次 fire 之后两侧状态全确定，
//   所以从「出现过一次 fire」起每拍比全部输出（+random / <seed>017 档两侧上电值不同）。
// 激励（fire 3/4）：op 码一半是 0/1 加减、其余均匀散到全部 32 个码（含未定义码）；操作数：特殊值、
//   指数相等 / 差 1 / 0 对 1 / 远差 / 移位溢出边界（差 53..60）、尾数低位微差（大量抵消）、±0 对 ±0；
//   canonical NaN 标志各 1/16。
// 覆盖（写进 PASS 判据）：far >= 20000、close >= 10000 次 oracle 比对；NaN 结果、Inf 结果、NV、OF、NX 各 >= 200；
//   15 个已定义 op 码各 >= 1000 次 oracle 比对；两个 canonical 标志各 >= 1000 次；rm 0..4 都出现；
//   fire=0 拍 >= 20000；每个输出位都见过 0 和 1（fflags 只有 NV/OF/NX 三位可为 1）。
// =============================================================================
`timescale 1ns/1ps
module tb;
  import fp_add_oracle_pkg::*;
  import fp64_misc_oracle_pkg::*;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0, oracle_errors = 0, oracle_checks = 0;
  int cyc;
  logic clock = 0;
  always #5 clock = ~clock;

  // ---- 激励 ----
  logic        fire, is_sub, canon_a, canon_b;
  logic [63:0] fp_a, fp_b;
  logic [2:0]  round_mode;
  logic [4:0]  op_code;

  logic [63:0] g_c, i_c;
  logic [4:0]  g_ff, i_ff;
  FloatAdderF64Pipeline u_g (
    .clock(clock), .io_fire(fire), .io_fp_a(fp_a), .io_fp_b(fp_b), .io_fp_c(g_c), .io_is_sub(is_sub),
    .io_round_mode(round_mode), .io_fflags(g_ff), .io_op_code(op_code),
    .io_fp_aIsFpCanonicalNAN(canon_a), .io_fp_bIsFpCanonicalNAN(canon_b));
  FloatAdderF64Pipeline_xs u_i (
    .clock(clock), .io_fire(fire), .io_fp_a(fp_a), .io_fp_b(fp_b), .io_fp_c(i_c), .io_is_sub(is_sub),
    .io_round_mode(round_mode), .io_fflags(i_ff), .io_op_code(op_code),
    .io_fp_aIsFpCanonicalNAN(canon_a), .io_fp_bIsFpCanonicalNAN(canon_b));

  // ---- 差分比较与逐位翻转覆盖 ----
  logic [63:0] seen0_c = '0, seen1_c = '0;
  logic [4:0]  seen0_f = '0, seen1_f = '0;
  task automatic compare_all();
    checks++;
    if (g_c !== i_c || g_ff !== i_ff) begin
      errors++;
      if (errors <= 30) $display("[%0d] MISMATCH fp_c g=%h i=%h fflags g=%b i=%b", cyc, g_c, i_c, g_ff, i_ff);
    end
    seen1_c |= g_c; seen0_c |= ~g_c; seen1_f |= g_ff; seen0_f |= ~g_ff;
  endtask

  // ---- 独立 oracle ----
  logic [63:0] q_a, q_b;
  logic        q_sub, q_ca, q_cb;
  logic [2:0]  q_rm;
  logic [4:0]  q_op;
  longint ora_far = 0, ora_close = 0, ora_nanres = 0, ora_infres = 0, ora_nv = 0, ora_of = 0, ora_nx = 0;
  longint ora_ca = 0, ora_cb = 0;
  int     ora_op [32];
  task automatic oracle_check();
    logic [63:0] exp_c, a, b, bb; logic [4:0] exp_f;
    fp_res_t r;
    bit nv, a_nan, b_nan, a_snan, b_snan;
    int ea, eb, d;
    exp_c = 0; exp_f = 0; nv = 0;
    a      = q_ca ? QNAN64 : q_a;                 // canonical NaN 标志 = 把它当 qNaN
    b      = q_cb ? QNAN64 : q_b;
    a_nan  = is_nan(a);  b_nan  = is_nan(b);
    a_snan = is_snan(a); b_snan = is_snan(b);
    if (q_op == 5'h00 || q_op == 5'h01) begin
      if (q_rm > 3'd4) return;                     // 非法 rm：只做 golden 对比
      bb = {b[63] ^ q_sub, b[62:0]};
      if (a_nan || b_nan || (is_inf(a) && is_inf(bb) && a[63] != bb[63])) begin
        exp_c = QNAN64;
        nv    = a_snan || b_snan || (is_inf(a) && is_inf(bb) && a[63] != bb[63]);
        ora_nanres++;
      end else if (is_inf(a) || is_inf(bb)) begin
        exp_c = is_inf(a) ? a : bb;
        ora_infres++;
      end else begin
        r = exact_add(53, 11, a[63], a[62:52], a[51:0], bb[63], bb[62:52], bb[51:0], q_rm);
        exp_c = r.bits;
        exp_f = {2'b0, r.of, 1'b0, r.nx};
        if (r.of) ora_of++; if (r.nx) ora_nx++;
        ea = (a[62:52] == 0) ? 1 : int'(a[62:52]);
        eb = (b[62:52] == 0) ? 1 : int'(b[62:52]);
        d  = ea - eb;
        if ((a[63] == bb[63]) || d >= 2 || d <= -2 || ((d == 1 || d == -1) && ((a[62:52] == 0) != (b[62:52] == 0))))
          ora_far++;
        else
          ora_close++;
      end
    end else begin
      case (q_op)
        5'h02, 5'h03: begin                                    // fmin / fmax：返回的是原始操作数
          if (a_nan && b_nan) exp_c = QNAN64;
          else if (a_nan)     exp_c = q_b;
          else if (b_nan)     exp_c = q_a;
          else                exp_c = f_minmax(q_a, q_b, q_op == 5'h03);
          nv = a_snan || b_snan;
        end
        5'h1E, 5'h13: begin                                    // fminm / fmaxm
          exp_c = (a_nan || b_nan) ? QNAN64 : f_minmax(q_a, q_b, q_op == 5'h13);
          nv = a_snan || b_snan;
        end
        5'h09: begin exp_c = !(a_nan || b_nan) && f_eq(a, b); nv = a_snan || b_snan; end
        5'h0B: begin exp_c = !(a_nan || b_nan) && f_lt(a, b); nv = a_nan || b_nan; end
        5'h0C: begin exp_c = !(a_nan || b_nan) && (f_lt(a, b) || f_eq(a, b)); nv = a_nan || b_nan; end
        5'h1B: begin exp_c = !(a_nan || b_nan) && f_lt(a, b); nv = a_snan || b_snan; end
        5'h1C: begin exp_c = !(a_nan || b_nan) && (f_lt(a, b) || f_eq(a, b)); nv = a_snan || b_snan; end
        5'h06: exp_c = {q_cb ? 1'b0 :  q_b[63], a[62:0]};
        5'h07: exp_c = {q_cb ? 1'b1 : ~q_b[63], a[62:0]};
        5'h08: exp_c = {(q_cb ? 1'b0 : q_b[63]) ^ a[63], a[62:0]};
        5'h0F: exp_c = {54'h0, q_ca ? 10'h200 : f_class(q_a)};
        default: exp_c = 0;
      endcase
    end
    if (nv) ora_nv++;
    exp_f[4] = nv;
    oracle_checks++;
    ora_op[q_op]++;
    if (q_ca) ora_ca++; if (q_cb) ora_cb++;
    if (i_c !== exp_c || i_ff !== exp_f) begin
      oracle_errors++;
      if (oracle_errors <= 30)
        $display("[%0d] ORACLE op=%h a=%h b=%h ca=%0d cb=%0d sub=%0d rm=%0d: expect c=%h ff=%b, got c=%h ff=%b",
                 cyc, q_op, q_a, q_b, q_ca, q_cb, q_sub, q_rm, exp_c, exp_f, i_c, i_ff);
    end
  endtask

  // ---- 操作数构造 ----
  function automatic logic [63:0] pick_special();
    case ($urandom_range(0, 9))
      0: return 64'h0;
      1: return 64'h7FF0_0000_0000_0000;                                  // +Inf
      2: return 64'h7FF8_0000_0000_0000;                                  // qNaN
      3: return 64'h7FF0_0000_0000_0000 | 64'($urandom_range(1, 255));     // sNaN
      4: return 64'h7FF8_0000_0000_0000 | {$urandom, $urandom} & 64'h0007_FFFF_FFFF_FFFF;  // qNaN 带载荷
      5: return 64'h1;                                                    // 最小非规格数
      6: return 64'h000F_FFFF_FFFF_FFFF;                                  // 最大非规格数
      7: return 64'h7FEF_FFFF_FFFF_FFFF;                                  // 最大有限数
      8: return 64'h0010_0000_0000_0000;                                  // 最小规格数
      default: return 64'h3FF0_0000_0000_0000;                            // 1.0
    endcase
  endfunction
  function automatic logic [10:0] pick_exp();
    case ($urandom_range(0, 11))
      0: return 11'd0;
      1: return 11'd1;
      2: return 11'd2046;
      3: return 11'd2045;
      4: return 11'd2047;
      5: return 11'($urandom_range(2, 60));
      default: return 11'($urandom_range(0, 2046));
    endcase
  endfunction
  function automatic logic [51:0] pick_mant();
    case ($urandom_range(0, 5))
      0: return '1;
      1: return '0;
      2: return 52'(1) << $urandom_range(0, 51);
      default: return {$urandom, $urandom};
    endcase
  endfunction

  task automatic drive();
    logic [10:0] ea, eb;
    logic [51:0] ma, mb;
    fire       = ($urandom_range(0, 3) != 0);
    round_mode = ($urandom_range(0, 7) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, 4));
    is_sub     = $urandom;
    canon_a    = ($urandom_range(0, 15) == 0);
    canon_b    = ($urandom_range(0, 15) == 0);
    op_code    = ($urandom_range(0, 1) == 0) ? 5'($urandom_range(0, 1)) : 5'($urandom);
    if ($urandom_range(0, 7) == 0) begin fp_a = {$urandom, $urandom}; fp_b = {$urandom, $urandom}; return; end
    if ($urandom_range(0, 31) == 0) begin         // ±0 对 ±0（min/max 的 -0 < +0 规则、比较的 ±0 相等）
      fp_a = {1'($urandom), 63'h0}; fp_b = {1'($urandom), 63'h0};
      if ($urandom_range(0, 1)) op_code = ($urandom_range(0, 1)) ? 5'($urandom_range(2, 3)) : 5'h13;
      return;
    end
    if ($urandom_range(0, 5) == 0) begin
      fp_a = $urandom_range(0, 1) ? pick_special() : {$urandom, $urandom};
      fp_b = $urandom_range(0, 1) ? pick_special() : {$urandom, $urandom};
      fp_a[63] = $urandom; fp_b[63] = $urandom;
      if ($urandom_range(0, 3) == 0) fp_b = fp_a ^ {1'($urandom), 63'h0};     // 同值 / 相反数
      return;
    end
    if ($urandom_range(0, 15) == 0) begin         // 移位溢出边界：小数只剩最低几位、指数差 53..60
      ea = 11'($urandom_range(62, 2046));
      eb = ea - 11'($urandom_range(53, 60));
      ma = pick_mant();
      mb = 52'(1) << $urandom_range(0, 2);
      if ($urandom_range(0, 1)) begin fp_a = {1'($urandom), ea, ma}; fp_b = {1'($urandom), eb, mb}; end
      else begin fp_b = {1'($urandom), ea, ma}; fp_a = {1'($urandom), eb, mb}; end
      return;
    end
    ea = pick_exp();
    ma = pick_mant();
    case ($urandom_range(0, 5))
      0: eb = ea;
      1: eb = ($urandom & 1) ? ea + 11'd1 : ea - 11'd1;
      2: eb = ($urandom & 1) ? ea + 11'($urandom_range(2, 60)) : ea - 11'($urandom_range(2, 60));
      3: eb = ea ^ 11'd1;
      4: eb = ($urandom & 1) ? 11'd0 : 11'd1;
      default: eb = pick_exp();
    endcase
    case ($urandom_range(0, 3))
      0: mb = ma ^ 52'($urandom_range(0, 7));
      1: mb = ma;
      default: mb = pick_mant();
    endcase
    fp_a = {1'($urandom), ea, ma};
    fp_b = {1'($urandom), eb, mb};
  endtask

  int fires = 0, idles = 0, cov_rm [8];
  initial begin
    bit armed = 0, q_valid = 0;
    bit cov_ok = 1;
    int defined_ops [15] = '{5'h00, 5'h01, 5'h02, 5'h03, 5'h06, 5'h07, 5'h08, 5'h09, 5'h0B, 5'h0C,
                             5'h0F, 5'h13, 5'h1B, 5'h1C, 5'h1E};
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    fire = 0; fp_a = 0; fp_b = 0; is_sub = 0; round_mode = 0; op_code = 0; canon_a = 0; canon_b = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      #1;
      if (armed) compare_all();
      if (q_valid) oracle_check();
      drive();
      @(posedge clock);
      if (fire) begin
        armed = 1; q_valid = 1; fires++; cov_rm[round_mode]++;
        q_a = fp_a; q_b = fp_b; q_sub = is_sub; q_rm = round_mode; q_op = op_code; q_ca = canon_a; q_cb = canon_b;
      end else idles++;
      @(negedge clock);
    end
    if (ora_far < 20000 || ora_close < 10000) begin cov_ok = 0; $display("COV FAIL oracle far=%0d close=%0d", ora_far, ora_close); end
    if (ora_nanres < 200 || ora_infres < 200 || ora_nv < 200 || ora_of < 200 || ora_nx < 200) begin
      cov_ok = 0; $display("COV FAIL nanres=%0d infres=%0d nv=%0d of=%0d nx=%0d", ora_nanres, ora_infres, ora_nv, ora_of, ora_nx);
    end
    foreach (defined_ops[k]) if (ora_op[defined_ops[k]] < 1000) begin
      cov_ok = 0; $display("COV FAIL op %h oracle=%0d", defined_ops[k], ora_op[defined_ops[k]]);
    end
    if (ora_ca < 1000 || ora_cb < 1000) begin cov_ok = 0; $display("COV FAIL canon a=%0d b=%0d", ora_ca, ora_cb); end
    for (int k = 0; k < 5; k++) if (cov_rm[k] == 0) begin cov_ok = 0; $display("COV FAIL rm%0d", k); end
    if (idles < 20000) begin cov_ok = 0; $display("COV FAIL idle=%0d", idles); end
    if (seen1_c != '1 || seen0_c != '1) begin cov_ok = 0; $display("COV FAIL fp_c bits 1=%h 0=%h", seen1_c, seen0_c); end
    if (seen1_f != 5'b10101 || seen0_f != 5'h1F) begin cov_ok = 0; $display("COV FAIL fflags bits 1=%b 0=%b", seen1_f, seen0_f); end
    $display("COVERAGE fires=%0d idles=%0d rm=%0d/%0d/%0d/%0d/%0d canon a/b=%0d/%0d", fires, idles,
             cov_rm[0], cov_rm[1], cov_rm[2], cov_rm[3], cov_rm[4], ora_ca, ora_cb);
    $display("ORACLE checks=%0d far=%0d close=%0d nanres=%0d infres=%0d nv=%0d of=%0d nx=%0d oracle_errors=%0d",
             oracle_checks, ora_far, ora_close, ora_nanres, ora_infres, ora_nv, ora_of, ora_nx, oracle_errors);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && oracle_errors == 0 && cov_ok) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
