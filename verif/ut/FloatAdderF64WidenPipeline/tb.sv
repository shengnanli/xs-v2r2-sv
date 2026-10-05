// =============================================================================
// tb —— FloatAdderF64WidenPipeline UT：golden 与重写件（FloatAdderF64WidenPipeline_xs）双例化，同时钟同激励逐拍比。
// 两侧 child 不同：golden 实例读 golden child，重写件读重写 child（*_xs），所以同时回归了整棵子树。
//
// 加宽操作数的产生：tb 自带 f32→f64 换算（widen_f32，按 FloatAdderWidenFormat 的输出约定：规格数指数 +896、
//   尾数左对齐；非规格数精确规格化；±0 给指数 0x369；Inf/NaN 照公式重偏置成 0x47F），1/8 的拍给乱码 widen_*
//   （只做 golden 对比，不进 oracle）。
// 独立 oracle（fp_add_oracle_pkg 的精确加法 + fp64_misc_oracle_pkg 的比较/分类，与被测电路无共享代码），
//   对上一次 fire 的激励：
//   - 走加法器的指令（fadd/fsub、fsum_ure 且两侧都未掩码、fsum_ore 且 a 未掩码；rm ∈ 0..4）：
//       操作数按 opb_widening / is_vfwredosum 决定取 widen_* 还是 fp_*，加宽来的值先还原成标准 f64（0x369/0 → ±0，
//       0x47F → Inf/NaN），再按 IEEE：NaN 或 Inf-Inf → 7FF8…（NV = 有 sNaN 或 Inf-Inf）；Inf → 带符号 Inf；
//       有限数 → 精确和按 rm 舍入，fflags = {0,0,OF,0,NX}；
//   - 其余指令（只在 res_widening=0 时进 oracle；向量单元不会对加宽格式发这些）：min/max、feq/fne/flt/fle/fgt/fge、
//     sgnj/sgnjn/sgnjx、fclass、fmerge、fmove/fmv_f_s/fmv_s_f、归约的掩码特判；其余 op 码结果 0、fflags 0。
// 复位域：全部寄存器 RegEnable(fire)、不复位，且每次 fire 每个寄存器都被写——第一次 fire 之后两侧状态全确定。
// 覆盖（写进 PASS 判据）：far >= 20000、close >= 10000 次加法 oracle 比对；加宽加法 >= 10000（其中加宽零操作数
//   >= 300、vfwadd.wv 形式 >= 2000、vfwredosum 形式 >= 2000）；NaN 结果、Inf 结果、NV、OF、NX 各 >= 200；
//   22 个已定义 op 码各 >= 1000 次 oracle 比对；rm 0..4 都出现；fire=0 拍 >= 20000；
//   每个输出位都见过 0 和 1（fflags 只有 NV/OF/NX 三位可为 1）。
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
  logic        fire, is_sub, mask, opb_w, res_w, wredosum;
  logic [63:0] fp_a, fp_b, widen_a, widen_b;
  logic [2:0]  round_mode;
  logic [4:0]  op_code;
  logic [1:0]  mask_red;
  bit          widen_ok;          // widen_* 是 widen_f32 产出的合法编码（否则只做 golden 对比）

  logic [63:0] g_c, i_c;
  logic [4:0]  g_ff, i_ff;
  FloatAdderF64WidenPipeline u_g (
    .clock(clock), .io_fire(fire), .io_fp_a(fp_a), .io_fp_b(fp_b), .io_widen_a(widen_a), .io_widen_b(widen_b),
    .io_fp_c(g_c), .io_mask(mask), .io_is_sub(is_sub), .io_round_mode(round_mode), .io_fflags(g_ff),
    .io_opb_widening(opb_w), .io_res_widening(res_w), .io_op_code(op_code), .io_maskForReduction(mask_red),
    .io_is_vfwredosum(wredosum));
  FloatAdderF64WidenPipeline_xs u_i (
    .clock(clock), .io_fire(fire), .io_fp_a(fp_a), .io_fp_b(fp_b), .io_widen_a(widen_a), .io_widen_b(widen_b),
    .io_fp_c(i_c), .io_mask(mask), .io_is_sub(is_sub), .io_round_mode(round_mode), .io_fflags(i_ff),
    .io_opb_widening(opb_w), .io_res_widening(res_w), .io_op_code(op_code), .io_maskForReduction(mask_red),
    .io_is_vfwredosum(wredosum));

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

  // ---- f32 → f64 加宽（FloatAdderWidenFormat 的输出约定）与还原 ----
  function automatic logic [63:0] widen_f32(input logic [31:0] x);
    int p;
    if (x[30:23] == 0) begin
      if (x[22:0] == 0) return {x[31], 11'h369, 52'h0};
      p = 0;
      for (int k = 0; k < 23; k++) if (x[k]) p = k;
      return {x[31], 11'(874 + p), 52'(64'(x[22:0]) << (52 - p))};
    end
    return {x[31], 11'(int'(x[30:23]) + 896), x[22:0], 29'h0};
  endfunction
  function automatic logic [63:0] unwiden(input logic [63:0] w);
    if (w[62:52] == 11'h369 && w[51:0] == 0) return {w[63], 63'h0};
    if (w[62:52] == 11'h47F) return {w[63], 11'h7FF, w[51:0]};
    return w;
  endfunction

  // ---- 独立 oracle ----
  logic [63:0] q_a, q_b, q_wa, q_wb;
  logic        q_sub, q_mask, q_opbw, q_resw, q_wro, q_wok;
  logic [2:0]  q_rm;
  logic [4:0]  q_op;
  logic [1:0]  q_mr;
  longint ora_far = 0, ora_close = 0, ora_nanres = 0, ora_infres = 0, ora_nv = 0, ora_of = 0, ora_nx = 0;
  longint ora_widen = 0, ora_widen_zero = 0, ora_wv = 0, ora_wro = 0;
  int     ora_op [32];
  task automatic oracle_check();
    logic [63:0] exp_c, a, b, bb; logic [4:0] exp_f;
    fp_res_t r;
    bit addsub, nv, a_f32, b_f32;
    int ea, eb, d;
    exp_c = 0; exp_f = 0; nv = 0;
    addsub = (q_op == 5'h00) || (q_op == 5'h01) || (q_op == 5'h1A && q_mr == 2'b11) || (q_op == 5'h16 && q_mr[0]);
    if (addsub) begin
      if (q_rm > 3'd4) return;                     // 非法 rm：只做 golden 对比
      a_f32 = q_resw && !q_opbw;
      b_f32 = q_resw && !q_wro;
      if ((a_f32 || b_f32) && !q_wok) return;      // 乱码 widen_*：只做 golden 对比
      a  = a_f32 ? unwiden(q_wa) : q_a;
      b  = b_f32 ? unwiden(q_wb) : q_b;
      bb = {b[63] ^ q_sub, b[62:0]};
      if (q_resw) begin
        ora_widen++;
        if (is_zero(a) || is_zero(b)) ora_widen_zero++;
        if (q_opbw) ora_wv++;
        if (q_wro) ora_wro++;
      end
      if (is_nan(a) || is_nan(b) || (is_inf(a) && is_inf(bb) && a[63] != bb[63])) begin
        exp_c = QNAN64;
        nv    = is_snan(a) || is_snan(b) || (is_inf(a) && is_inf(bb) && a[63] != bb[63]);
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
      if (q_resw) return;                          // 加宽格式只发加减/求和类
      case (q_op)
        5'h02, 5'h03: begin exp_c = f_minmax(q_a, q_b, q_op == 5'h03); nv = is_snan(q_a) || is_snan(q_b); end
        5'h09: begin exp_c = !(is_nan(q_a) || is_nan(q_b)) && f_eq(q_a, q_b);  nv = is_snan(q_a) || is_snan(q_b); end
        5'h0A: begin exp_c = !(!(is_nan(q_a) || is_nan(q_b)) && f_eq(q_a, q_b)); nv = is_snan(q_a) || is_snan(q_b); end
        5'h0B: begin exp_c = !(is_nan(q_a) || is_nan(q_b)) && f_lt(q_a, q_b); nv = is_nan(q_a) || is_nan(q_b); end
        5'h0C: begin exp_c = !(is_nan(q_a) || is_nan(q_b)) && (f_lt(q_a, q_b) || f_eq(q_a, q_b)); nv = is_nan(q_a) || is_nan(q_b); end
        5'h0D: begin exp_c = !(is_nan(q_a) || is_nan(q_b)) && f_lt(q_b, q_a); nv = is_nan(q_a) || is_nan(q_b); end
        5'h0E: begin exp_c = !(is_nan(q_a) || is_nan(q_b)) && (f_lt(q_b, q_a) || f_eq(q_a, q_b)); nv = is_nan(q_a) || is_nan(q_b); end
        5'h06: exp_c = {q_b[63], q_a[62:0]};
        5'h07: exp_c = {~q_b[63], q_a[62:0]};
        5'h08: exp_c = {q_a[63] ^ q_b[63], q_a[62:0]};
        5'h0F: exp_c = {54'h0, f_class(q_a)};
        5'h04: exp_c = q_mask ? q_b : q_a;
        5'h05, 5'h11, 5'h12: exp_c = q_b;
        5'h1A: exp_c = (q_mr == 2'b00) ? {q_rm != 3'd2, 63'h0} : (q_mr[0] ? q_a : q_b);   // 部分/全掩码
        5'h14, 5'h15: begin
          if (q_mr == 2'b00)      exp_c = QNAN64;
          else if (q_mr == 2'b11) exp_c = f_minmax(q_a, q_b, q_op == 5'h15);
          else                    exp_c = q_mr[0] ? q_a : q_b;
          nv = (q_mr[0] && is_snan(q_a)) || (q_mr[1] && is_snan(q_b));
        end
        5'h16: exp_c = q_b;                      // a 被掩码：直通 b
        default: exp_c = 0;
      endcase
    end
    if (nv) ora_nv++;
    exp_f[4] = nv;
    oracle_checks++;
    ora_op[q_op]++;
    if (i_c !== exp_c || i_ff !== exp_f) begin
      oracle_errors++;
      if (oracle_errors <= 30)
        $display("[%0d] ORACLE op=%h a=%h b=%h wa=%h wb=%h resw=%0d opbw=%0d wro=%0d sub=%0d rm=%0d mask=%0d mr=%b: expect c=%h ff=%b, got c=%h ff=%b",
                 cyc, q_op, q_a, q_b, q_wa, q_wb, q_resw, q_opbw, q_wro, q_sub, q_rm, q_mask, q_mr, exp_c, exp_f, i_c, i_ff);
    end
  endtask

  // ---- 操作数构造 ----
  function automatic logic [63:0] pick_special();
    case ($urandom_range(0, 9))
      0: return 64'h0;
      1: return 64'h7FF0_0000_0000_0000;                                  // +Inf
      2: return 64'h7FF8_0000_0000_0000;                                  // qNaN
      3: return 64'h7FF0_0000_0000_0000 | 64'($urandom_range(1, 255));     // sNaN
      4: return 64'h7FF8_0000_0000_0000 | {$urandom, $urandom} & 64'h0007_FFFF_FFFF_FFFF;
      5: return 64'h1;                                                    // 最小非规格数
      6: return 64'h000F_FFFF_FFFF_FFFF;                                  // 最大非规格数
      7: return 64'h7FEF_FFFF_FFFF_FFFF;                                  // 最大有限数
      8: return 64'h0010_0000_0000_0000;                                  // 最小规格数
      default: return 64'h3FF0_0000_0000_0000;                            // 1.0
    endcase
  endfunction
  function automatic logic [31:0] pick_f32();
    logic [7:0] e;
    case ($urandom_range(0, 11))
      0: return {1'($urandom), 31'h0};                                    // ±0
      1: return {1'($urandom), 8'hFF, 23'h0};                             // ±Inf
      2: return {1'($urandom), 8'hFF, 1'b1, 22'($urandom)};               // qNaN
      3: return {1'($urandom), 8'hFF, 1'b0, 22'($urandom_range(1, 4095))};// sNaN
      4: return {1'($urandom), 8'h0, 23'($urandom)};                      // 非规格数
      5: return {1'($urandom), 8'h0, 23'(1) << $urandom_range(0, 22)};    // 非规格数（单热）
      6: return {1'($urandom), 8'($urandom_range(125, 129)), 23'($urandom)};
      default: return $urandom;
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
      6: return 11'($urandom_range(860, 1160));                          // 与加宽值同量级
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

  task automatic drive_f64_pair();
    logic [10:0] ea, eb;
    logic [51:0] ma, mb;
    if ($urandom_range(0, 7) == 0) begin fp_a = {$urandom, $urandom}; fp_b = {$urandom, $urandom}; return; end
    if ($urandom_range(0, 31) == 0) begin         // ±0 对 ±0
      fp_a = {1'($urandom), 63'h0}; fp_b = {1'($urandom), 63'h0};
      if ($urandom_range(0, 1)) op_code = 5'($urandom_range(2, 3));
      return;
    end
    if ($urandom_range(0, 5) == 0) begin
      fp_a = $urandom_range(0, 1) ? pick_special() : {$urandom, $urandom};
      fp_b = $urandom_range(0, 1) ? pick_special() : {$urandom, $urandom};
      fp_a[63] = $urandom; fp_b[63] = $urandom;
      if ($urandom_range(0, 3) == 0) fp_b = fp_a ^ {1'($urandom), 63'h0};     // 同值 / 相反数
      return;
    end
    if ($urandom_range(0, 15) == 0) begin         // 移位溢出边界：指数差 53..60
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

  task automatic drive();
    logic [31:0] fa, fb;
    fire       = ($urandom_range(0, 3) != 0);
    round_mode = ($urandom_range(0, 7) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, 4));
    is_sub     = $urandom;
    mask       = $urandom;
    mask_red   = $urandom;
    op_code    = ($urandom_range(0, 1) == 0) ? 5'($urandom_range(0, 1)) : 5'($urandom);
    drive_f64_pair();
    // 加宽：1/3 的拍；其中 vfwadd.wv / vfwredosum 各约 1/4
    res_w    = ($urandom_range(0, 2) == 0);
    opb_w    = res_w ? ($urandom_range(0, 3) == 0) : $urandom;
    wredosum = res_w ? ($urandom_range(0, 3) == 0) : $urandom;
    fa = pick_f32();
    fb = pick_f32();
    if ($urandom_range(0, 3) == 0) fb = {1'($urandom), fa[30:0]};    // 同幅值（大量抵消 / 两零）
    if ($urandom_range(0, 3) == 0) fb = {fa[31:23] ^ 9'($urandom_range(0, 1)), 23'($urandom)};
    widen_a  = widen_f32(fa);
    widen_b  = widen_f32(fb);
    widen_ok = 1;
    if ($urandom_range(0, 7) == 0) begin widen_a = {$urandom, $urandom}; widen_b = {$urandom, $urandom}; widen_ok = 0; end
    if (res_w && opb_w && $urandom_range(0, 1)) fp_a = unwiden(widen_f32(pick_f32()));   // .wv 的 a 是 f64，同量级
  endtask

  int fires = 0, idles = 0, cov_rm [8];
  initial begin
    bit armed = 0, q_valid = 0;
    bit cov_ok = 1;
    int defined_ops [22] = '{5'h00, 5'h01, 5'h02, 5'h03, 5'h04, 5'h05, 5'h06, 5'h07, 5'h08, 5'h09, 5'h0A,
                             5'h0B, 5'h0C, 5'h0D, 5'h0E, 5'h0F, 5'h11, 5'h12, 5'h14, 5'h15, 5'h16, 5'h1A};
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    fire = 0; fp_a = 0; fp_b = 0; widen_a = 0; widen_b = 0; is_sub = 0; round_mode = 0; mask = 0;
    op_code = 0; mask_red = 0; opb_w = 0; res_w = 0; wredosum = 0; widen_ok = 1;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      #1;
      if (armed) compare_all();
      if (q_valid) oracle_check();
      drive();
      @(posedge clock);
      if (fire) begin
        armed = 1; q_valid = 1; fires++; cov_rm[round_mode]++;
        q_a = fp_a; q_b = fp_b; q_wa = widen_a; q_wb = widen_b; q_sub = is_sub; q_rm = round_mode; q_op = op_code;
        q_mr = mask_red; q_mask = mask; q_opbw = opb_w; q_resw = res_w; q_wro = wredosum; q_wok = widen_ok;
      end else idles++;
      @(negedge clock);
    end
    if (ora_far < 20000 || ora_close < 10000) begin cov_ok = 0; $display("COV FAIL oracle far=%0d close=%0d", ora_far, ora_close); end
    if (ora_widen < 10000 || ora_widen_zero < 300 || ora_wv < 2000 || ora_wro < 2000) begin
      cov_ok = 0; $display("COV FAIL widen=%0d widen_zero=%0d wv=%0d wro=%0d", ora_widen, ora_widen_zero, ora_wv, ora_wro);
    end
    if (ora_nanres < 200 || ora_infres < 200 || ora_nv < 200 || ora_of < 200 || ora_nx < 200) begin
      cov_ok = 0; $display("COV FAIL nanres=%0d infres=%0d nv=%0d of=%0d nx=%0d", ora_nanres, ora_infres, ora_nv, ora_of, ora_nx);
    end
    foreach (defined_ops[k]) if (ora_op[defined_ops[k]] < 1000) begin
      cov_ok = 0; $display("COV FAIL op %h oracle=%0d", defined_ops[k], ora_op[defined_ops[k]]);
    end
    for (int k = 0; k < 5; k++) if (cov_rm[k] == 0) begin cov_ok = 0; $display("COV FAIL rm%0d", k); end
    if (idles < 20000) begin cov_ok = 0; $display("COV FAIL idle=%0d", idles); end
    if (seen1_c != '1 || seen0_c != '1) begin cov_ok = 0; $display("COV FAIL fp_c bits 1=%h 0=%h", seen1_c, seen0_c); end
    if (seen1_f != 5'b10101 || seen0_f != 5'h1F) begin cov_ok = 0; $display("COV FAIL fflags bits 1=%b 0=%b", seen1_f, seen0_f); end
    $display("COVERAGE fires=%0d idles=%0d rm=%0d/%0d/%0d/%0d/%0d", fires, idles, cov_rm[0], cov_rm[1], cov_rm[2], cov_rm[3], cov_rm[4]);
    $display("ORACLE checks=%0d far=%0d close=%0d widen=%0d widen_zero=%0d wv=%0d wro=%0d nanres=%0d infres=%0d nv=%0d of=%0d nx=%0d oracle_errors=%0d",
             oracle_checks, ora_far, ora_close, ora_widen, ora_widen_zero, ora_wv, ora_wro, ora_nanres, ora_infres,
             ora_nv, ora_of, ora_nx, oracle_errors);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && oracle_errors == 0 && cov_ok) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
