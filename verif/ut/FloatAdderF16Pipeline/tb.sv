// =============================================================================
// tb —— FloatAdderF16Pipeline UT：golden 与重写件（FloatAdderF16Pipeline_xs）双例化，同时钟同激励逐拍比。
// 两侧 child 不同：golden 实例读 golden child，重写件读重写 child（*_xs），所以同时回归了整棵子树。
//
// 独立 oracle（tb 内纯整数算术 + RISC-V F 扩展语义，与被测电路无共享代码），对上一次 fire 的激励：
//   - 加减类（fadd/fsub、fsum_ure 且两侧都未掩码、fsum_ore 且 a 未掩码；rm ∈ 0..4）：
//       NaN 输入或 Inf-Inf → 7E00，NV = 有 SNaN 或 Inf-Inf；Inf → 带符号 Inf、fflags 0；
//       有限数 → 以 2^-24 为单位的精确和按 rm 舍入，fflags = {0,0,OF,0,NX}。
//   - min/max（NaN 规则、-0 < +0）、feq/fne/flt/fle/fgt/fge（a ? b，NaN 时为 0；fne 为 !feq）、
//     sgnj/sgnjn/sgnjx、fclass（10 位分类）、fmerge、fmove/fmv_f_s/fmv_s_f、归约的掩码特判；
//     对应 NV 规则；其余 op 码结果 0、fflags 0。
// 复位域：全部寄存器 RegEnable(fire)、不复位，且每次 fire 每个寄存器都被写——第一次 fire 之后两侧状态全确定，
//   所以从"出现过一次 fire"起每拍比全部输出（+random 档两侧上电值不同）。
// 激励（fire 3/4）：op 码 1/2 加减、其余均匀散到全部 32 个码（含未定义码）；操作数：特殊值（±0/±Inf/qNaN/sNaN/
//   最小最大非规格数/最大有限数）、指数相等 / 差 1 / 0 对 1 / 远差 / 移位溢出边界、尾数低位微差（大量抵消）。
// 覆盖（写进 PASS 判据）：far >= 20000、close >= 10000 次 oracle 比对；NaN 结果、Inf 结果、NV、OF、NX 各 >= 200；
//   全部 22 个已定义 op 码各 >= 1000 次 oracle 比对；rm 0..4 都出现；fire=0 拍 >= 20000；
//   每个输出位都见过 0 和 1（fflags 只有 NV/OF/NX 三位可为 1）。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0, oracle_errors = 0, oracle_checks = 0;
  int cyc;
  logic clock = 0;
  always #5 clock = ~clock;

  // ---- 激励 ----
  logic        fire, is_sub, mask;
  logic [15:0] fp_a, fp_b;
  logic [2:0]  round_mode;
  logic [4:0]  op_code;
  logic [1:0]  mask_red;

  logic [15:0] g_c, i_c;
  logic [4:0]  g_ff, i_ff;
  FloatAdderF16Pipeline u_g (
    .clock(clock), .io_fire(fire), .io_fp_a(fp_a), .io_fp_b(fp_b), .io_fp_c(g_c), .io_is_sub(is_sub),
    .io_mask(mask), .io_round_mode(round_mode), .io_fflags(g_ff), .io_op_code(op_code),
    .io_maskForReduction(mask_red));
  FloatAdderF16Pipeline_xs u_i (
    .clock(clock), .io_fire(fire), .io_fp_a(fp_a), .io_fp_b(fp_b), .io_fp_c(i_c), .io_is_sub(is_sub),
    .io_mask(mask), .io_round_mode(round_mode), .io_fflags(i_ff), .io_op_code(op_code),
    .io_maskForReduction(mask_red));

  // ---- 差分比较与逐位翻转覆盖 ----
  logic [15:0] seen0_c = '0, seen1_c = '0;
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
  localparam logic [15:0] QNAN = 16'h7E00;
  function automatic bit is_nan (input logic [15:0] x); return (x[14:10] == 5'h1F) && (x[9:0] != 0); endfunction
  function automatic bit is_snan(input logic [15:0] x); return is_nan(x) && !x[9]; endfunction
  function automatic bit is_inf (input logic [15:0] x); return (x[14:10] == 5'h1F) && (x[9:0] == 0); endfunction
  function automatic bit is_zero(input logic [15:0] x); return x[14:0] == 0; endfunction
  // 以 2^-24 为单位的带符号值（有限数）
  function automatic longint f16_val(input logic [15:0] x);
    longint sig = (x[14:10] == 0) ? longint'(x[9:0]) : longint'({1'b1, x[9:0]});
    int     ee  = (x[14:10] == 0) ? 1 : int'(x[14:10]);
    longint m   = sig << (ee - 1);
    return x[15] ? -m : m;
  endfunction
  // 有限数 a + b（b 已带有效符号），舍入到 binary16
  task automatic oracle_add(input logic [15:0] a, input logic [15:0] b, input logic [2:0] rm,
                            output logic [15:0] res, output logic of, output logic nx);
    longint s, mag, mant, rem, half;
    int     p, shift, e;
    logic   rs, inc;
    s   = f16_val(a) + f16_val(b);
    rs  = s < 0;
    mag = rs ? -s : s;
    of = 0; nx = 0;
    if (mag == 0) begin
      res = {(a[15] == b[15]) ? a[15] : (rm == 3'd2), 15'h0};
      return;
    end
    p = 0;
    for (int k = 0; k < 64; k++) if (mag[k]) p = k;
    if (p < 10) begin res = {rs, 5'd0, mag[9:0]}; return; end
    shift = p - 10;
    mant  = mag >> shift;
    rem   = mag & ((longint'(1) << shift) - 1);
    half  = (shift == 0) ? 0 : (longint'(1) << (shift - 1));
    e     = shift + 1;
    case (rm)
      3'd0: inc = (shift != 0) && ((rem > half) || (rem == half && mant[0]));
      3'd1: inc = 0;
      3'd2: inc = rs && (rem != 0);
      3'd3: inc = !rs && (rem != 0);
      default: inc = (shift != 0) && (rem >= half);
    endcase
    nx   = rem != 0;
    mant = mant + inc;
    if (mant == 2048) begin mant = 1024; e = e + 1; end
    if (e >= 31) begin
      of  = 1; nx = 1;
      res = {rs, ((rm == 3'd1) || (rm == 3'd2 && !rs) || (rm == 3'd3 && rs)) ? 15'h7BFF : 15'h7C00};
      return;
    end
    res = {rs, 5'(e), mant[9:0]};
  endtask
  // 比较：a < b / a == b（非 NaN；±0 相等）
  function automatic bit f_lt(input logic [15:0] a, input logic [15:0] b);
    if (is_zero(a) && is_zero(b)) return 0;
    if (is_inf(a) || is_inf(b)) begin
      if (a == b) return 0;
      if (is_inf(a)) return a[15];
      return !b[15];
    end
    return f16_val(a) < f16_val(b);
  endfunction
  function automatic bit f_eq(input logic [15:0] a, input logic [15:0] b);
    if (is_zero(a) && is_zero(b)) return 1;
    return a == b;
  endfunction
  function automatic logic [15:0] f_min(input logic [15:0] a, input logic [15:0] b, input bit want_max);
    if (is_nan(a) && is_nan(b)) return QNAN;
    if (is_nan(a)) return b;
    if (is_nan(b)) return a;
    if (is_zero(a) && is_zero(b)) return want_max ? (a[15] ? b : a) : (a[15] ? a : b);
    if (want_max) return f_lt(a, b) ? b : a;
    return f_lt(b, a) ? b : a;
  endfunction
  function automatic logic [9:0] f_class(input logic [15:0] a);
    logic [9:0] c = '0;
    if (is_nan(a))       c[a[9] ? 9 : 8] = 1;
    else if (is_inf(a))  c[a[15] ? 0 : 7] = 1;
    else if (is_zero(a)) c[a[15] ? 3 : 4] = 1;
    else if (a[14:10] == 0) c[a[15] ? 2 : 5] = 1;
    else                 c[a[15] ? 1 : 6] = 1;
    return c;
  endfunction

  // fire 那一拍的激励快照
  logic [15:0] q_a, q_b;
  logic        q_sub, q_mask;
  logic [2:0]  q_rm;
  logic [4:0]  q_op;
  logic [1:0]  q_mr;
  longint ora_far = 0, ora_close = 0, ora_nanres = 0, ora_infres = 0, ora_nv = 0, ora_of = 0, ora_nx = 0;
  int     ora_op [32];
  task automatic oracle_check();
    logic [15:0] exp_c, bb; logic [4:0] exp_f; logic of, nx;
    bit addsub, nv;
    int d;
    exp_c = 0; exp_f = 0;
    addsub = (q_op == 5'h00) || (q_op == 5'h01) || (q_op == 5'h1A && q_mr == 2'b11) || (q_op == 5'h16 && q_mr[0]);
    if (addsub) begin
      if (q_rm > 3'd4) return;                     // 非法 rm：只做 golden 对比
      bb = {q_b[15] ^ q_sub, q_b[14:0]};
      if (is_nan(q_a) || is_nan(q_b) || (is_inf(q_a) && is_inf(bb) && q_a[15] != bb[15])) begin
        exp_c = QNAN;
        nv    = is_snan(q_a) || is_snan(q_b) || (is_inf(q_a) && is_inf(bb) && q_a[15] != bb[15]);
        exp_f = {nv, 4'b0};
        ora_nanres++; if (nv) ora_nv++;
      end else if (is_inf(q_a) || is_inf(bb)) begin
        exp_c = is_inf(q_a) ? q_a : bb;
        ora_infres++;
      end else begin
        oracle_add(q_a, bb, q_rm, exp_c, of, nx);
        exp_f = {2'b0, of, 1'b0, nx};
        if (of) ora_of++; if (nx) ora_nx++;
        d = ((q_a[14:10] == 0) ? 1 : int'(q_a[14:10])) - ((q_b[14:10] == 0) ? 1 : int'(q_b[14:10]));
        if ((q_a[15] == bb[15]) || d >= 2 || d <= -2 || ((d == 1 || d == -1) && ((q_a[14:10] == 0) != (q_b[14:10] == 0))))
          ora_far++;
        else
          ora_close++;
      end
    end else begin
      nv = 0;
      case (q_op)
        5'h02, 5'h03: begin exp_c = f_min(q_a, q_b, q_op == 5'h03); nv = is_snan(q_a) || is_snan(q_b); end
        5'h09: begin exp_c = !(is_nan(q_a) || is_nan(q_b)) && f_eq(q_a, q_b);  nv = is_snan(q_a) || is_snan(q_b); end
        5'h0A: begin exp_c = !(!(is_nan(q_a) || is_nan(q_b)) && f_eq(q_a, q_b)); nv = is_snan(q_a) || is_snan(q_b); end
        5'h0B: begin exp_c = !(is_nan(q_a) || is_nan(q_b)) && f_lt(q_a, q_b); nv = is_nan(q_a) || is_nan(q_b); end
        5'h0C: begin exp_c = !(is_nan(q_a) || is_nan(q_b)) && (f_lt(q_a, q_b) || f_eq(q_a, q_b)); nv = is_nan(q_a) || is_nan(q_b); end
        5'h0D: begin exp_c = !(is_nan(q_a) || is_nan(q_b)) && f_lt(q_b, q_a); nv = is_nan(q_a) || is_nan(q_b); end
        5'h0E: begin exp_c = !(is_nan(q_a) || is_nan(q_b)) && (f_lt(q_b, q_a) || f_eq(q_a, q_b)); nv = is_nan(q_a) || is_nan(q_b); end
        5'h06: exp_c = {q_b[15], q_a[14:0]};
        5'h07: exp_c = {~q_b[15], q_a[14:0]};
        5'h08: exp_c = {q_a[15] ^ q_b[15], q_a[14:0]};
        5'h0F: exp_c = {6'h0, f_class(q_a)};
        5'h04: exp_c = q_mask ? q_b : q_a;
        5'h05, 5'h11, 5'h12: exp_c = q_b;
        5'h1A: exp_c = (q_mr == 2'b00) ? {q_rm != 3'd2, 15'h0} : (q_mr[0] ? q_a : q_b);   // 部分/全掩码
        5'h14, 5'h15: begin
          if (q_mr == 2'b00)      exp_c = QNAN;
          else if (q_mr == 2'b11) exp_c = f_min(q_a, q_b, q_op == 5'h15);
          else                    exp_c = q_mr[0] ? q_a : q_b;
          nv = (q_mr[0] && is_snan(q_a)) || (q_mr[1] && is_snan(q_b));
        end
        5'h16: exp_c = q_b;                      // a 被掩码：直通 b
        default: exp_c = 0;
      endcase
      exp_f = {nv, 4'b0};
      if (nv) ora_nv++;
    end
    oracle_checks++;
    ora_op[q_op]++;
    if (i_c !== exp_c || i_ff !== exp_f) begin
      oracle_errors++;
      if (oracle_errors <= 30)
        $display("[%0d] ORACLE op=%h a=%h b=%h sub=%0d rm=%0d mask=%0d mr=%b: expect c=%h ff=%b, got c=%h ff=%b",
                 cyc, q_op, q_a, q_b, q_sub, q_rm, q_mask, q_mr, exp_c, exp_f, i_c, i_ff);
    end
  endtask

  // ---- 操作数构造 ----
  function automatic logic [15:0] pick_special();
    case ($urandom_range(0, 9))
      0: return 16'h0000;
      1: return 16'h7C00;              // +Inf
      2: return 16'h7E00;              // qNaN
      3: return 16'h7C00 | 16'($urandom_range(1, 511));   // sNaN
      4: return 16'h7E00 | 16'($urandom_range(0, 511));   // qNaN 带载荷
      5: return 16'h0001;              // 最小非规格数
      6: return 16'h03FF;              // 最大非规格数
      7: return 16'h7BFF;              // 最大有限数
      8: return 16'h0400;              // 最小规格数
      default: return 16'h3C00;        // 1.0
    endcase
  endfunction
  function automatic logic [4:0] pick_exp();
    case ($urandom_range(0, 11))
      0: return 5'd0;
      1: return 5'd1;
      2: return 5'd30;
      3: return 5'd29;
      4: return 5'd31;
      5: return 5'($urandom_range(2, 13));
      default: return 5'($urandom_range(0, 30));
    endcase
  endfunction
  function automatic logic [9:0] pick_mant();
    case ($urandom_range(0, 5))
      0: return '1;
      1: return '0;
      2: return 10'(1) << $urandom_range(0, 9);
      default: return 10'($urandom);
    endcase
  endfunction

  task automatic drive();
    logic [4:0] ea, eb;
    logic [9:0] ma, mb;
    fire       = ($urandom_range(0, 3) != 0);
    round_mode = ($urandom_range(0, 7) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, 4));
    is_sub     = $urandom;
    mask       = $urandom;
    mask_red   = $urandom;
    op_code    = ($urandom_range(0, 1) == 0) ? 5'($urandom_range(0, 1)) : 5'($urandom);
    if ($urandom_range(0, 7) == 0) begin fp_a = $urandom; fp_b = $urandom; return; end
    if ($urandom_range(0, 5) == 0) begin
      fp_a = $urandom_range(0, 1) ? pick_special() : 16'($urandom);
      fp_b = $urandom_range(0, 1) ? pick_special() : 16'($urandom);
      fp_a[15] = $urandom; fp_b[15] = $urandom;
      if ($urandom_range(0, 3) == 0) fp_b = fp_a ^ {1'($urandom), 15'h0};     // 同值 / 相反数
      return;
    end
    if ($urandom_range(0, 15) == 0) begin         // 移位溢出边界：小数只剩最低几位、指数差 11..16
      ea = 5'($urandom_range(12, 30));
      eb = ea - 5'($urandom_range(11, 16));
      ma = pick_mant();
      mb = 10'(1) << $urandom_range(0, 2);
      if ($urandom_range(0, 1)) begin fp_a = {1'($urandom), ea, ma}; fp_b = {1'($urandom), eb, mb}; end
      else begin fp_b = {1'($urandom), ea, ma}; fp_a = {1'($urandom), eb, mb}; end
      return;
    end
    ea = pick_exp();
    ma = pick_mant();
    case ($urandom_range(0, 5))
      0: eb = ea;
      1: eb = ($urandom & 1) ? ea + 5'd1 : ea - 5'd1;
      2: eb = ($urandom & 1) ? ea + 5'($urandom_range(2, 16)) : ea - 5'($urandom_range(2, 16));
      3: eb = ea ^ 5'd1;
      4: eb = ($urandom & 1) ? 5'd0 : 5'd1;
      default: eb = pick_exp();
    endcase
    case ($urandom_range(0, 3))
      0: mb = ma ^ 10'($urandom_range(0, 7));
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
    int defined_ops [22] = '{5'h00, 5'h01, 5'h02, 5'h03, 5'h04, 5'h05, 5'h06, 5'h07, 5'h08, 5'h09, 5'h0A,
                             5'h0B, 5'h0C, 5'h0D, 5'h0E, 5'h0F, 5'h11, 5'h12, 5'h14, 5'h15, 5'h16, 5'h1A};
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    fire = 0; fp_a = 0; fp_b = 0; is_sub = 0; round_mode = 0; mask = 0; op_code = 0; mask_red = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      #1;
      if (armed) compare_all();
      if (q_valid) oracle_check();
      drive();
      @(posedge clock);
      if (fire) begin
        armed = 1; q_valid = 1; fires++; cov_rm[round_mode]++;
        q_a = fp_a; q_b = fp_b; q_sub = is_sub; q_rm = round_mode; q_op = op_code; q_mr = mask_red; q_mask = mask;
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
    for (int k = 0; k < 5; k++) if (cov_rm[k] == 0) begin cov_ok = 0; $display("COV FAIL rm%0d", k); end
    if (idles < 20000) begin cov_ok = 0; $display("COV FAIL idle=%0d", idles); end
    if (seen1_c != 16'hFFFF || seen0_c != 16'hFFFF) begin cov_ok = 0; $display("COV FAIL fp_c bits 1=%h 0=%h", seen1_c, seen0_c); end
    if (seen1_f != 5'b10101 || seen0_f != 5'h1F) begin cov_ok = 0; $display("COV FAIL fflags bits 1=%b 0=%b", seen1_f, seen0_f); end
    $display("COVERAGE fires=%0d idles=%0d rm=%0d/%0d/%0d/%0d/%0d", fires, idles, cov_rm[0], cov_rm[1], cov_rm[2], cov_rm[3], cov_rm[4]);
    $display("ORACLE checks=%0d far=%0d close=%0d nanres=%0d infres=%0d nv=%0d of=%0d nx=%0d oracle_errors=%0d",
             oracle_checks, ora_far, ora_close, ora_nanres, ora_infres, ora_nv, ora_of, ora_nx, oracle_errors);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && oracle_errors == 0 && cov_ok) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
