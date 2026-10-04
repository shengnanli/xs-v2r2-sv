// =============================================================================
// tb —— FarPathFloatAdderF64WidenPipeline UT：golden 与重写件（<名>_xs）双例化，同时钟同激励逐拍比全部 4 个输出。
// 两侧 child 不同：golden 实例读 golden child（Adder / FarShiftRightWithMuxInvFirst / FarPathAdderF64WidenPipeline），
//   重写件读重写 child（*_xs），所以同时回归了整棵子树。
//
// 独立 oracle（fp_add_oracle_pkg，纯整数算术）：
//   - 组合输出（每拍，对当拍输入）：absEaSubEb == |Ea' - Eb'|（Ea' = 指数为 0 时按 1），isEfp_bGreater == (Eb > Ea)。
//   - 寄存器输出（对上一次 fire 的输入）：在 far path 的前提域内（两操作数指数均非全 1、rm ∈ 0..4，且
//     有效相加 / 有效指数差 >= 2 / 差 1 且恰一个非规格数——即父级把它路由给 far 的情形），
//     fp_c == round_rm(a + (-1)^is_sub · b)，fflags == {0, 0, OF, 0, NX}。域外只做 golden 对比。
// 复位域：全部寄存器 RegEnable(fire)、不复位，且每次 fire 每个寄存器都被写——第一次 fire 之后两侧状态全确定，
//   所以从"出现过一次 fire"起每拍比 fp_c / fflags；absEaSubEb / isEfp_bGreater 是纯组合，从第 0 拍起就比。
// 激励（fire 3/4）：指数关系 相等 / 差 1 / 差 2..60（跨 56 移位溢出门限）/ 0 对 1 / 全 1 附近（上溢）；
//   尾数 随机 / 全 1 / 全 0 / 单 1；1/8 完全随机。
//   另 1/16 拍专打移位溢出门限：小数是尾数只剩低 0..3 位单 1 的非规格数、有效指数差 54..60。
// 覆盖（写进 PASS 判据，按重写件内部信号统计）：正常不进位 / 正常进位 / 溢出不进位 / 溢出进位 各 >= 1000；
//   上溢 >= 200；移位溢出 >= 1000；oracle 比对 >= 50000（其中 NX >= 1000、有效相减 >= 10000、非规格数结果 >= 100）；
//   rm 0..4 都出现；fire=0 拍 >= 20000；每个输出位都见过 0 和 1（fflags 只有 OF/NX 两位可为 1）。
// =============================================================================
`timescale 1ns/1ps
module tb;
  import fp_add_oracle_pkg::*;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0, oracle_errors = 0;
  int cyc;
  logic clock = 0;
  always #5 clock = ~clock;

  logic        fire, is_sub;
  logic [63:0] fp_a, fp_b;
  logic [2:0]  round_mode;

  logic [63:0] g_c, i_c;
  logic [4:0]  g_ff, i_ff;
  logic [10:0] g_abs, i_abs;
  logic        g_bg, i_bg;
  FarPathFloatAdderF64WidenPipeline u_g (
    .clock(clock), .io_fire(fire), .io_fp_a(fp_a), .io_fp_b(fp_b), .io_fp_c(g_c), .io_is_sub(is_sub),
    .io_round_mode(round_mode), .io_fflags(g_ff), .io_absEaSubEb(g_abs), .io_isEfp_bGreater(g_bg));
  FarPathFloatAdderF64WidenPipeline_xs u_i (
    .clock(clock), .io_fire(fire), .io_fp_a(fp_a), .io_fp_b(fp_b), .io_fp_c(i_c), .io_is_sub(is_sub),
    .io_round_mode(round_mode), .io_fflags(i_ff), .io_absEaSubEb(i_abs), .io_isEfp_bGreater(i_bg));

  // ---- 差分比较与逐位翻转覆盖 ----
  logic [63:0] seen0_c = '0, seen1_c = '0;
  logic [4:0]  seen0_f = '0, seen1_f = '0;
  logic [10:0] seen0_a = '0, seen1_a = '0;
  logic        seen0_b = 0, seen1_b = 0;
  task automatic compare_comb();
    checks++;
    if (g_abs !== i_abs || g_bg !== i_bg) begin
      errors++;
      if (errors <= 30) $display("[%0d] MISMATCH abs g=%h i=%h bgreater g=%b i=%b", cyc, g_abs, i_abs, g_bg, i_bg);
    end
    seen1_a |= g_abs; seen0_a |= ~g_abs; seen1_b |= g_bg; seen0_b |= ~g_bg;
  endtask
  task automatic compare_regs();
    checks++;
    if (g_c !== i_c || g_ff !== i_ff) begin
      errors++;
      if (errors <= 30) $display("[%0d] MISMATCH fp_c g=%h i=%h fflags g=%b i=%b", cyc, g_c, i_c, g_ff, i_ff);
    end
    seen1_c |= g_c; seen0_c |= ~g_c; seen1_f |= g_ff; seen0_f |= ~g_ff;
  endtask

  // ---- oracle ----
  function automatic int eff_exp(input logic [10:0] e); return (e == 0) ? 1 : int'(e); endfunction
  longint ora_comb = 0, ora_add = 0, ora_nx = 0, ora_of = 0, ora_sub = 0, ora_denorm = 0;
  task automatic oracle_comb();
    int d;
    d = eff_exp(fp_a[62:52]) - eff_exp(fp_b[62:52]);
    ora_comb++;
    if (i_abs !== 11'(d < 0 ? -d : d) || i_bg !== (fp_b[62:52] > fp_a[62:52])) begin
      oracle_errors++;
      if (oracle_errors <= 30) $display("[%0d] ORACLE comb a=%h b=%h: abs=%h bg=%b", cyc, fp_a, fp_b, i_abs, i_bg);
    end
  endtask

  logic [63:0] q_a, q_b;
  logic        q_sub;
  logic [2:0]  q_rm;
  task automatic oracle_regs();
    fp_res_t r;
    int d;
    bit eop, is_far;
    if (q_a[62:52] == 11'h7FF || q_b[62:52] == 11'h7FF || q_rm > 3'd4) return;
    d   = eff_exp(q_a[62:52]) - eff_exp(q_b[62:52]);
    eop = q_a[63] ^ q_b[63] ^ q_sub;
    is_far = !eop || d >= 2 || d <= -2 || ((d == 1 || d == -1) && ((q_a[62:52] == 0) != (q_b[62:52] == 0)));
    if (!is_far) return;
    r = exact_add(53, 11, q_a[63], q_a[62:52], q_a[51:0], q_b[63] ^ q_sub, q_b[62:52], q_b[51:0], q_rm);
    ora_add++; if (r.nx) ora_nx++; if (r.of) ora_of++; if (eop) ora_sub++; if (r.bits[62:52] == 0) ora_denorm++;
    if (i_c !== r.bits || i_ff !== {2'b00, r.of, 1'b0, r.nx}) begin
      oracle_errors++;
      if (oracle_errors <= 30)
        $display("[%0d] ORACLE a=%h b=%h sub=%0d rm=%0d: expect c=%h of=%0d nx=%0d, got c=%h ff=%b",
                 cyc, q_a, q_b, q_sub, q_rm, r.bits, r.of, r.nx, i_c, i_ff);
    end
  endtask

  // ---- 激励 ----
  function automatic logic [10:0] pick_exp();
    case ($urandom_range(0, 11))
      0: return 11'd0;
      1: return 11'd1;
      2: return 11'h7FE;
      3: return 11'h7FD;
      4: return 11'h7FF;
      5: return 11'($urandom_range(2, 70));
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
    int dd;
    fire       = ($urandom_range(0, 3) != 0);
    round_mode = ($urandom_range(0, 7) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, 4));
    is_sub     = $urandom;
    if ($urandom_range(0, 7) == 0) begin fp_a = {$urandom, $urandom}; fp_b = {$urandom, $urandom}; return; end
    if ($urandom_range(0, 15) == 0) begin         // 移位溢出门限：小数是只剩最低几位的非规格数，有效指数差 54..60
      fp_a = {1'($urandom), 11'($urandom_range(55, 61)), pick_mant()};
      fp_b = {1'($urandom), 11'h0, 52'(1) << $urandom_range(0, 3)};
      if ($urandom_range(0, 1)) begin logic [63:0] t = fp_a; fp_a = fp_b; fp_b = t; end
      return;
    end
    ea = pick_exp();
    ma = pick_mant();
    case ($urandom_range(0, 6))
      0: eb = ea;
      1: eb = ($urandom & 1) ? ea + 11'd1 : ea - 11'd1;
      2, 3: begin dd = $urandom_range(2, 60); eb = ($urandom & 1) ? ea + 11'(dd) : ea - 11'(dd); end
      4: eb = ($urandom & 1) ? 11'd0 : 11'd1;
      5: eb = ($urandom & 1) ? ea + 11'($urandom_range(54, 58)) : ea - 11'($urandom_range(54, 58));
      default: eb = pick_exp();
    endcase
    mb = pick_mant();
    fp_a = {1'($urandom), ea, ma};
    fp_b = {1'($urandom), eb, mb};
    if ($urandom_range(0, 1)) begin logic [63:0] t = fp_a; fp_a = fp_b; fp_b = t; end
  endtask

  int cov_case [4];
  int cov_of = 0, cov_shift_out = 0, cov_rm [8], fires = 0, idles = 0;
  task automatic sample_cov();
    if (u_i.u_core.sel_normal_keep)   cov_case[0]++;
    if (u_i.u_core.sel_normal_up)     cov_case[1]++;
    if (u_i.u_core.sel_overflow_keep) cov_case[2]++;
    if (u_i.u_core.sel_overflow_up)   cov_case[3]++;
    if (u_i.u_core.overflow)          cov_of++;
    if (u_i.u_core.shift_out_q)       cov_shift_out++;
  endtask

  initial begin
    bit armed = 0, q_valid = 0;
    bit cov_ok = 1;
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    fire = 0; fp_a = 0; fp_b = 0; is_sub = 0; round_mode = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      #1;
      if (armed) begin compare_regs(); sample_cov(); end
      if (q_valid) oracle_regs();
      drive();
      #1;
      compare_comb();
      oracle_comb();
      @(posedge clock);
      if (fire) begin
        armed = 1; q_valid = 1; fires++; cov_rm[round_mode]++;
        q_a = fp_a; q_b = fp_b; q_sub = is_sub; q_rm = round_mode;
      end else idles++;
      @(negedge clock);
    end
    for (int k = 0; k < 4; k++) if (cov_case[k] < 1000) begin cov_ok = 0; $display("COV FAIL case%0d=%0d", k, cov_case[k]); end
    if (cov_of < 200) begin cov_ok = 0; $display("COV FAIL overflow=%0d", cov_of); end
    if (cov_shift_out < 1000) begin cov_ok = 0; $display("COV FAIL shift_out=%0d", cov_shift_out); end
    if (ora_add < 50000 || ora_nx < 1000 || ora_sub < 10000 || ora_denorm < 100) begin
      cov_ok = 0; $display("COV FAIL oracle add=%0d nx=%0d sub=%0d denorm=%0d", ora_add, ora_nx, ora_sub, ora_denorm);
    end
    for (int k = 0; k < 5; k++) if (cov_rm[k] == 0) begin cov_ok = 0; $display("COV FAIL rm%0d", k); end
    if (idles < 20000) begin cov_ok = 0; $display("COV FAIL idle=%0d", idles); end
    if (seen1_c != '1 || seen0_c != '1) begin cov_ok = 0; $display("COV FAIL fp_c bits 1=%h 0=%h", seen1_c, seen0_c); end
    if (seen1_f != 5'b00101 || seen0_f != 5'h1F) begin cov_ok = 0; $display("COV FAIL fflags 1=%b 0=%b", seen1_f, seen0_f); end
    if (seen1_a != '1 || seen0_a != '1 || !seen1_b || !seen0_b) begin cov_ok = 0; $display("COV FAIL abs/bgreater bits"); end
    $display("COVERAGE keepN/upN/keepO/upO=%0d/%0d/%0d/%0d of=%0d shift_out=%0d fires=%0d idles=%0d",
             cov_case[0], cov_case[1], cov_case[2], cov_case[3], cov_of, cov_shift_out, fires, idles);
    $display("ORACLE comb=%0d add=%0d (nx=%0d of=%0d eop=%0d denorm=%0d) oracle_errors=%0d",
             ora_comb, ora_add, ora_nx, ora_of, ora_sub, ora_denorm, oracle_errors);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && oracle_errors == 0 && cov_ok) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
