// =============================================================================
// tb —— FpAddPathF16 UT：FarPathF16Pipeline / ClosePathF16Pipeline 各自 golden 与重写件（<名>_xs）双例化，
//   同时钟同激励逐拍比全部输出；另配一个独立 IEEE oracle（tb 内精确整数加法 + 按 rm 舍入）。
// 两侧 child 不同：golden 实例读 golden child，重写件读重写 child（*_xs），整棵子树一起回归。
//
// 复位域：全部寄存器 RegEnable(fire)、不复位，且每次 fire 每个寄存器都被写——第一次 fire 之后两侧状态
//   全确定，所以从"出现过一次 fire"之后每拍比全部输出（+random 档两侧上电值不同）。
// 时序：negedge 给激励 I_n；posedge 若 fire 则两条路径锁存 I_n；下一个 negedge 上寄存器部分的输出就是
//   I_n 的结果（child FarPathAdderF16Pipeline 也只延迟一拍），此时对 I_n 做 oracle 比对。
// oracle（与 golden / 重写件都无关，按 IEEE 754 binary16 定义算）：
//   值 = 有效数 × 2^(有效指数-25)，换成以 2^-24 为单位的整数后精确求和，再按 rm（RNE/RTZ/RDN/RUP/RMM）
//   舍入到 binary16，上溢按 rm 给 Inf 或最大有限数，NX = 舍掉的部分非零 或 上溢。
//   前提照父级 FloatAdderF16Pipeline 的选路（Scala is_far_path）：d = |有效指数差|（非规格数指数按 1）；
//     far  = 有效相加 或 d >= 2 或（d == 1 且恰一个操作数指数为 0），比 fp_c、OF、NX；
//     close = 其余（有效相减、d <= 1、不含"规格数 2 对非规格数"那一格），close 恒做 sign_a·(|a| - |b|)，比 fp_c、NX。
//   两者都要求两数有限（指数 != 31）、rm <= 4。close 对"指数 2 对 0"会算错（只看指数低两位判大小），
//   父级正因此把这一格路由给 far——所以 oracle 的前提必须照父级的选路，而不是照"差 <= 1"。
//   恰好抵消的零按 IEEE：RDN 给 -0，其余 +0；同号两零相加保留该符号。
//   前提之外（Inf/NaN 操作数、far 的近距相减、close 的远距、rm 5..7）由父级 FloatAdderF16Pipeline 另行处理
//   或不会被选用，这里只做 golden vs 重写的差分。
// 覆盖（写进 PASS 判据，按重写件内部信号统计）：close 五个候选选择 sel_cs0..4 各 >= 200；far 的
//   正常/溢出 × 不进位/进位四格各 >= 200、上溢 >= 50、移位溢出 >= 200；rm 0..4 都出现；oracle 比对
//   far / close 各 >= 20000 次；激励含 1/16 的"移位溢出边界"（指数差 11..16、小数尾数只剩最低几位，
//   专打 sticky 在 14/15 位门限上的取舍）；每个输出位都见过 0 和 1（golden 字面 0 的 fflags 位只要求见过 0）。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0, oracle_errors = 0;
  int cyc;
  logic clock = 0;
  always #5 clock = ~clock;

  // ---- 激励 ----
  logic        fire;
  logic [15:0] fp_a, fp_b;
  logic        is_sub;
  logic [2:0]  round_mode;

  // ---- FarPath ----
  logic [15:0] g_far_c, i_far_c;
  logic [4:0]  g_far_ff, i_far_ff;
  logic [4:0]  g_far_abs, i_far_abs;
  logic        g_far_bg, i_far_bg;
  FarPathF16Pipeline u_g_far (.clock(clock), .io_fire(fire), .io_fp_a(fp_a), .io_fp_b(fp_b),
    .io_fp_c(g_far_c), .io_is_sub(is_sub), .io_round_mode(round_mode), .io_fflags(g_far_ff),
    .io_absEaSubEb(g_far_abs), .io_isEfp_bGreater(g_far_bg));
  FarPathF16Pipeline_xs u_i_far (.clock(clock), .io_fire(fire), .io_fp_a(fp_a), .io_fp_b(fp_b),
    .io_fp_c(i_far_c), .io_is_sub(is_sub), .io_round_mode(round_mode), .io_fflags(i_far_ff),
    .io_absEaSubEb(i_far_abs), .io_isEfp_bGreater(i_far_bg));

  // ---- ClosePath ----
  logic [15:0] g_close_c, i_close_c;
  logic [4:0]  g_close_ff, i_close_ff;
  logic [11:0] g_close_cs1, i_close_cs1;
  ClosePathF16Pipeline u_g_close (.clock(clock), .io_fire(fire), .io_fp_a(fp_a), .io_fp_b(fp_b),
    .io_fp_c(g_close_c), .io_round_mode(round_mode), .io_fflags(g_close_ff), .io_CS1(g_close_cs1));
  ClosePathF16Pipeline_xs u_i_close (.clock(clock), .io_fire(fire), .io_fp_a(fp_a), .io_fp_b(fp_b),
    .io_fp_c(i_close_c), .io_round_mode(round_mode), .io_fflags(i_close_ff), .io_CS1(i_close_cs1));

  // ---- 差分比较与逐位翻转覆盖 ----
  localparam int N_OUT = 7;
  logic [15:0] seen0 [N_OUT], seen1 [N_OUT];
  logic [15:0] must  [N_OUT];      // 要求见过 1 的位（golden 字面 0 的位不要求）
  initial begin
    for (int k = 0; k < N_OUT; k++) begin seen0[k] = '0; seen1[k] = '0; end
    must[0] = 16'hFFFF;            // far fp_c
    must[1] = 16'h0005;            // far fflags：仅 OF(bit2) / NX(bit0)
    must[2] = 16'h001F;            // far absEaSubEb
    must[3] = 16'h0001;            // far isEfp_bGreater
    must[4] = 16'hFFFF;            // close fp_c
    must[5] = 16'h0001;            // close fflags：仅 NX
    must[6] = 16'h0FFF;            // close CS1
  end
  `define CMP(k, g, i, w, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 30) $display("[%0d] MISMATCH %s golden=%h impl=%h", cyc, nm, (g), (i)); end \
      seen1[k] |= 16'(g); seen0[k] |= ~16'(g) & 16'((32'd1 << (w)) - 1); end
  task automatic compare_all();
    `CMP(0, g_far_c, i_far_c, 16, "far.io_fp_c")
    `CMP(1, g_far_ff, i_far_ff, 5, "far.io_fflags")
    `CMP(2, g_far_abs, i_far_abs, 5, "far.io_absEaSubEb")
    `CMP(3, g_far_bg, i_far_bg, 1, "far.io_isEfp_bGreater")
    `CMP(4, g_close_c, i_close_c, 16, "close.io_fp_c")
    `CMP(5, g_close_ff, i_close_ff, 5, "close.io_fflags")
    `CMP(6, g_close_cs1, i_close_cs1, 12, "close.io_CS1")
  endtask

  // ---- 独立 IEEE binary16 加法 oracle ----
  // 以 2^-24（最小非规格数）为单位：有效数 sig（含隐含位）× 2^(有效指数 - 1)
  function automatic longint f16_units(input logic [4:0] e, input logic [9:0] m);
    longint sig = (e == 0) ? longint'(m) : longint'({1'b1, m});
    int     ee  = (e == 0) ? 1 : int'(e);
    return sig << (ee - 1);
  endfunction
  // (-1)^sa |a| + (-1)^sb |b|，舍入到 binary16
  task automatic oracle_add(input logic sa, input logic [4:0] ea, input logic [9:0] ma,
                            input logic sb, input logic [4:0] eb, input logic [9:0] mb,
                            input logic [2:0] rm,
                            output logic [15:0] res, output logic of, output logic nx);
    longint s, mag, mant, rem, half;
    int     p, shift, e;
    logic   rs, inc;
    s   = (sa ? -f16_units(ea, ma) : f16_units(ea, ma)) + (sb ? -f16_units(eb, mb) : f16_units(eb, mb));
    rs  = s < 0;
    mag = rs ? -s : s;
    of = 0; nx = 0;
    if (mag == 0) begin
      // 精确零：同号保留符号；异号抵消按 rm（RDN 给 -0）
      res = {(sa == sb) ? sa : (rm == 3'd2), 15'h0};
      return;
    end
    p = 0;
    for (int k = 0; k < 64; k++) if (mag[k]) p = k;
    if (p < 10) begin                       // 非规格数结果：以 2^-24 为单位本身就精确
      res = {rs, 5'd0, mag[9:0]};
      return;
    end
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

  // fire 那一拍的激励快照，用于下一拍的 oracle 比对
  logic [15:0] q_a, q_b;
  logic        q_sub;
  logic [2:0]  q_rm;
  logic        q_valid = 0;
  longint ora_far = 0, ora_close = 0, ora_far_of = 0, ora_far_nx = 0, ora_close_nx = 0, ora_cancel = 0, ora_denorm = 0;
  function automatic int eff_exp(input logic [4:0] e);
    return (e == 0) ? 1 : int'(e);
  endfunction
  task automatic oracle_check();
    logic [15:0] r; logic of, nx;
    int d;
    bit finite, eop, is_far;
    finite = (q_a[14:10] != 5'h1F) && (q_b[14:10] != 5'h1F) && (q_rm <= 3'd4);
    d   = eff_exp(q_a[14:10]) - eff_exp(q_b[14:10]);
    eop = q_a[15] ^ q_b[15] ^ q_sub;
    is_far = !eop || d >= 2 || d <= -2
           || ((d == 1 || d == -1) && ((q_a[14:10] == 0) != (q_b[14:10] == 0)));
    // far
    if (finite && is_far) begin
      oracle_add(q_a[15], q_a[14:10], q_a[9:0], q_b[15] ^ q_sub, q_b[14:10], q_b[9:0], q_rm, r, of, nx);
      ora_far++; if (of) ora_far_of++; if (nx) ora_far_nx++;
      if (r[14:10] == 0) ora_denorm++;
      if (i_far_c !== r || i_far_ff[2] !== of || i_far_ff[0] !== nx) begin
        oracle_errors++;
        if (oracle_errors <= 30)
          $display("[%0d] ORACLE far a=%h b=%h sub=%0d rm=%0d: expect c=%h of=%0d nx=%0d, got c=%h ff=%b",
                   cyc, q_a, q_b, q_sub, q_rm, r, of, nx, i_far_c, i_far_ff);
      end
    end
    // close：sign_a·(|a| - |b|)
    if (finite && !is_far) begin
      oracle_add(q_a[15], q_a[14:10], q_a[9:0], ~q_a[15], q_b[14:10], q_b[9:0], q_rm, r, of, nx);
      ora_close++; if (nx) ora_close_nx++; if (r[14:0] == 0) ora_cancel++;
      if (i_close_c !== r || i_close_ff[0] !== nx) begin
        oracle_errors++;
        if (oracle_errors <= 30)
          $display("[%0d] ORACLE close a=%h b=%h rm=%0d: expect c=%h nx=%0d, got c=%h ff=%b",
                   cyc, q_a, q_b, q_rm, r, nx, i_close_c, i_close_ff);
      end
    end
  endtask

  // ---- 操作数构造 ----
  function automatic logic [4:0] pick_exp();
    case ($urandom_range(0, 11))
      0: return 5'd0;
      1: return 5'd1;
      2: return 5'd30;
      3: return 5'd29;
      4: return 5'd31;
      5: return 5'($urandom_range(2, 13));
      6: return 5'd12;
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
    if ($urandom_range(0, 7) == 0) begin          // 1/8 完全随机
      fp_a = $urandom; fp_b = $urandom;
      return;
    end
    if ($urandom_range(0, 15) == 0) begin         // 1/16 移位溢出边界：小数只剩最低几位、指数差 11..16
      ea = 5'($urandom_range(12, 30));
      eb = ea - 5'($urandom_range(11, 16));
      if (eb == 5'd1 && $urandom_range(0, 1)) eb = 5'd0;           // 非规格数（有效指数同为 1）
      ma = pick_mant();
      mb = 10'(1) << $urandom_range(0, 2);
      if ($urandom_range(0, 1)) begin fp_a = {1'($urandom), ea, ma}; fp_b = {1'($urandom), eb, mb}; end
      else begin fp_b = {1'($urandom), ea, ma}; fp_a = {1'($urandom), eb, mb}; end
      return;
    end
    ea = pick_exp();
    ma = pick_mant();
    case ($urandom_range(0, 5))
      0: eb = ea;                                                   // 相等
      1: eb = ($urandom & 1) ? ea + 5'd1 : ea - 5'd1;               // 差 1
      2: eb = ($urandom & 1) ? ea + 5'($urandom_range(2, 16)) : ea - 5'($urandom_range(2, 16));
      3: eb = ea ^ 5'd1;
      4: eb = ($urandom & 1) ? 5'd0 : 5'd1;
      default: eb = pick_exp();
    endcase
    case ($urandom_range(0, 3))
      0: mb = ma ^ 10'($urandom_range(0, 7));                       // 低位微差：大量抵消
      1: mb = ma;
      default: mb = pick_mant();
    endcase
    fp_a = {1'($urandom), ea, ma};
    fp_b = {1'($urandom), eb, mb};
  endtask

  // ---- 覆盖（重写件内部信号）----
  int cov_sel [5];
  int cov_far [4];
  int cov_of, cov_shift_out, cov_rm [8];
  int fires = 0;
  task automatic sample_cov();
    if (u_i_close.u_core.sel_cs0) cov_sel[0]++;
    if (u_i_close.u_core.sel_cs1) cov_sel[1]++;
    if (u_i_close.u_core.sel_cs2) cov_sel[2]++;
    if (u_i_close.u_core.sel_cs3) cov_sel[3]++;
    if (u_i_close.u_core.sel_cs4) cov_sel[4]++;
    if (u_i_far.u_core.sel_normal_keep)   cov_far[0]++;
    if (u_i_far.u_core.sel_normal_up)     cov_far[1]++;
    if (u_i_far.u_core.sel_overflow_keep) cov_far[2]++;
    if (u_i_far.u_core.sel_overflow_up)   cov_far[3]++;
    if (u_i_far.u_core.overflow) cov_of++;
    if (u_i_far.u_core.shift_out_of_range) cov_shift_out++;
    cov_rm[round_mode]++;
  endtask

  initial begin
    bit armed = 0;
    bit cov_ok = 1;
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    fire = 0; fp_a = 0; fp_b = 0; is_sub = 0; round_mode = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      #1;
      if (armed) begin compare_all(); sample_cov(); end
      if (q_valid) oracle_check();
      drive();
      @(posedge clock);
      q_valid = fire;
      if (fire) begin armed = 1; fires++; q_a = fp_a; q_b = fp_b; q_sub = is_sub; q_rm = round_mode; end
      @(negedge clock);
    end
    for (int k = 0; k < 5; k++) if (cov_sel[k] < 200) begin cov_ok = 0; $display("COV FAIL close sel_cs%0d=%0d", k, cov_sel[k]); end
    for (int k = 0; k < 4; k++) if (cov_far[k] < 200) begin cov_ok = 0; $display("COV FAIL far case%0d=%0d", k, cov_far[k]); end
    if (cov_of < 50) begin cov_ok = 0; $display("COV FAIL far overflow=%0d", cov_of); end
    if (cov_shift_out < 200) begin cov_ok = 0; $display("COV FAIL far shift_out=%0d", cov_shift_out); end
    for (int k = 0; k < 5; k++) if (cov_rm[k] == 0) begin cov_ok = 0; $display("COV FAIL rm%0d", k); end
    if (ora_far < 20000 || ora_close < 20000) begin cov_ok = 0; $display("COV FAIL oracle far=%0d close=%0d", ora_far, ora_close); end
    for (int k = 0; k < N_OUT; k++) begin
      if ((seen1[k] & must[k]) != must[k]) begin cov_ok = 0; $display("COV FAIL out%0d bits never 1: %h", k, must[k] & ~seen1[k]); end
    end
    $display("COVERAGE close sel=%0d/%0d/%0d/%0d/%0d far keepN/upN/keepO/upO=%0d/%0d/%0d/%0d of=%0d shift_out=%0d fires=%0d",
             cov_sel[0], cov_sel[1], cov_sel[2], cov_sel[3], cov_sel[4], cov_far[0], cov_far[1], cov_far[2], cov_far[3],
             cov_of, cov_shift_out, fires);
    $display("ORACLE far=%0d (of=%0d nx=%0d denorm=%0d) close=%0d (nx=%0d exact_cancel=%0d) oracle_errors=%0d",
             ora_far, ora_far_of, ora_far_nx, ora_denorm, ora_close, ora_close_nx, ora_cancel, oracle_errors);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && oracle_errors == 0 && cov_ok) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
