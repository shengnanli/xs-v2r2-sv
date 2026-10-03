// =============================================================================
// tb —— FloatAdderF32F16MixedPipeline UT：golden 与重写件（FloatAdderF32F16MixedPipeline_xs）双例化，
//   同时钟同激励逐拍比 io_fp_c / io_fflags。两侧 child 不同：golden 读 golden 的 far/close 子树，
//   重写件读重写子树（*_xs），所以同时回归了整棵子树。
//
// 独立 IEEE oracle（对照上一次 fire 的输入；纯整数算术，fp_add_oracle_pkg + 本文件的比较类模型）：
//   - fadd / fsub（op 0/1）：NaN（含 canonical-NaN 输入）/ inf-inf 给 canonical qNaN，sNaN 或 inf-inf 置 NV；
//     无穷、零参与按 IEEE；其余 round_rm(a ± b) 与 NX/OF（exact_add）。只在 rm ∈ 0..4 时比。
//     ★golden 怪癖（照 Scala，oracle 显式建模）★：b 为 ±0、a 非零有限时结果是**整个 32 位 io_fp_a**，
//     f16 时高 16 位不清 0；f16 两零相加得 -0 时符号位复制 17 份（结果 0xFFFF8000）。
//     oracle 对这两格比全 32 位，其余 f16 结果高 16 位应为 0。
//     特殊值（NaN/无穷/零参与）时 fflags 只可能是 NV 或 0（x ± 0 精确，IEEE 一致）。
//   - fmin/fmax/fminm/fmaxm/feq/flt/fle/fltq/fleq/fsgnj/fsgnjn/fsgnjx/fclass：按 RISC-V F/Zfa 语义
//     （-0 < +0；min/max 单 NaN 取另一个、双 NaN 给 qNaN；fminm/fmaxm 任一 NaN 给 qNaN；
//      flt/fle 遇任何 NaN 置 NV，feq/fltq/fleq/min/max 只遇 sNaN 置 NV）。
//   - 其余 op_code：结果 0、fflags 0。
// 复位域：全部寄存器 RegEnable(fire)、不复位；第一次 fire 之后两侧状态全确定，从那以后每拍比。
// 激励（fire 3/4）：op 一半 fadd/fsub、其余按合法比较类 op 轮换、1/16 任意 5 位；fp_format 2 位随机；
//   canonical-NaN 标志各 1/16；操作数按 f32 / f16 布局造（f16 时高 16 位随机——golden 应忽略或照怪癖透传）：
//   指数相等 / 差 1 / 差 2..30 / 任意，含 0、全 1、全 1 附近（上溢）；尾数随机 / 全 1 / 全 0 / 仅差低位。
// 覆盖（写进 PASS 判据）：far / close 两路各 >= 2000 次被选中（fadd/fsub 非特殊）；每类比较 op 各 >= 500；
//   NV/OF/NX 各 >= 200；oracle 比对 >= 100000；每个输出位都见过 0 和 1（fflags 的 DZ/UF 是 golden 字面 0，只要求见过 0）。
// =============================================================================
`timescale 1ns/1ps
module tb;
  import fp_add_oracle_pkg::*;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0, oracle_checks = 0;
  int cyc;
  logic clock = 0;
  always #5 clock = ~clock;

  logic        fire;
  logic [31:0] fp_a, fp_b;
  logic        is_sub;
  logic [2:0]  round_mode;
  logic [1:0]  fp_format;
  logic [4:0]  op_code;
  logic        a_cnan, b_cnan;

  logic [31:0] g_c, i_c;
  logic [4:0]  g_ff, i_ff;
  FloatAdderF32F16MixedPipeline u_g (.clock(clock), .io_fire(fire), .io_fp_a(fp_a), .io_fp_b(fp_b), .io_fp_c(g_c),
    .io_is_sub(is_sub), .io_round_mode(round_mode), .io_fflags(g_ff), .io_fp_format(fp_format), .io_op_code(op_code),
    .io_fp_aIsFpCanonicalNAN(a_cnan), .io_fp_bIsFpCanonicalNAN(b_cnan));
  FloatAdderF32F16MixedPipeline_xs u_i (.clock(clock), .io_fire(fire), .io_fp_a(fp_a), .io_fp_b(fp_b), .io_fp_c(i_c),
    .io_is_sub(is_sub), .io_round_mode(round_mode), .io_fflags(i_ff), .io_fp_format(fp_format), .io_op_code(op_code),
    .io_fp_aIsFpCanonicalNAN(a_cnan), .io_fp_bIsFpCanonicalNAN(b_cnan));

  // ---- golden 对比与逐位翻转覆盖 ----
  logic [31:0] seen0 [2], seen1 [2];
  initial begin seen0[0] = 0; seen0[1] = 0; seen1[0] = 0; seen1[1] = 0; end
  task automatic compare_all();
    checks++;
    if (g_c !== i_c || g_ff !== i_ff) begin
      errors++;
      if (errors <= 30) $display("[%0d] MISMATCH fp_c golden=%h impl=%h fflags golden=%b impl=%b", cyc, g_c, i_c, g_ff, i_ff);
    end
    seen1[0] |= g_c; seen0[0] |= ~g_c; seen1[1] |= 32'(g_ff); seen0[1] |= ~32'(g_ff) & 32'h1F;
  endtask

  // ---- oracle ----
  typedef struct {
    logic        nan, snan, inf, zero, sign;
    logic [7:0]  e;                    // 本格式指数（f16 时 5 位右对齐）
    logic [22:0] m;                    // 本格式尾数（f16 时 10 位右对齐）
  } cls_t;
  function automatic cls_t classify(input logic [31:0] x, input bit f32, input logic cnan);
    cls_t c;
    logic all1, mnz;
    if (f32) begin c.sign = x[31]; c.e = x[30:23]; c.m = x[22:0]; all1 = &x[30:23]; end
    else     begin c.sign = x[15]; c.e = {3'b0, x[14:10]}; c.m = {13'b0, x[9:0]}; all1 = &x[14:10]; end
    mnz    = |c.m;
    c.nan  = cnan | (all1 & mnz);
    c.snan = ~cnan & all1 & mnz & ~(f32 ? c.m[22] : c.m[9]);
    c.inf  = ~cnan & all1 & ~mnz;
    c.zero = ~cnan & (c.e == 0) & ~mnz;
    return c;
  endfunction
  // a < b（均非 NaN；-0 与 +0 相等）
  function automatic bit flt_mag(input cls_t a, input cls_t b);
    logic [30:0] ka, kb;
    ka = {a.e, a.m}; kb = {b.e, b.m};
    if (a.zero && b.zero) return 0;
    if (a.sign != b.sign) return a.sign;
    return a.sign ? (ka > kb) : (ka < kb);
  endfunction
  function automatic bit feq_mag(input cls_t a, input cls_t b);
    if (a.zero && b.zero) return 1;
    return (a.sign == b.sign) && (a.e == b.e) && (a.m == b.m);
  endfunction

  logic [31:0] l_a, l_b;
  logic        l_sub, l_acn, l_bcn;
  logic [2:0]  l_rm;
  logic [1:0]  l_fmt;
  logic [4:0]  l_op;
  int cov_op [32];
  int cov_nv = 0, cov_of = 0, cov_nx = 0, cov_far = 0, cov_close = 0;

  task automatic oracle_check();
    bit f32;
    cls_t a, b;
    logic [31:0] exp_c, qnan, a_fix, b_fix, a_nat, b_nat, pick_min, pick_max;
    logic [4:0]  exp_ff;
    logic        sb_eff, lt, eq, nv_any, nv_s;
    fp_res_t r;
    f32  = l_fmt[0];
    a    = classify(l_a, f32, l_acn);
    b    = classify(l_b, f32, l_bcn);
    qnan = f32 ? 32'h7FC0_0000 : 32'h0000_7E00;
    a_fix = l_acn ? qnan : l_a;
    b_fix = l_bcn ? qnan : l_b;
    a_nat = f32 ? a_fix : {16'h0, a_fix[15:0]};
    b_nat = f32 ? b_fix : {16'h0, b_fix[15:0]};
    nv_any = a.nan | b.nan;
    nv_s   = a.snan | b.snan;
    exp_ff = 0;
    if (l_op == 5'd0 || l_op == 5'd1) begin
      if (l_rm > 3'd4) return;
      sb_eff = b.sign ^ l_sub;
      if (a.nan || b.nan || (a.inf && b.inf && (a.sign != sb_eff))) begin
        exp_c = qnan; exp_ff = (nv_s || (a.inf && b.inf)) ? 5'b10000 : 5'b0;
      end else if (a.inf || b.inf) begin
        exp_c = f32 ? {a.inf ? a.sign : sb_eff, 31'h7F80_0000} : {16'h0, a.inf ? a.sign : sb_eff, 15'h7C00};
      end else if (b.zero && !a.zero) begin
        exp_c = l_a;                     // ★golden 怪癖：整个 32 位 io_fp_a 透传（f16 时高 16 位不清）★
      end else begin
        r = f32 ? exact_add(24, 8, a.sign, 11'(a.e), 52'(a.m), sb_eff, 11'(b.e), 52'(b.m), l_rm)
                : exact_add(11, 5, a.sign, 11'(a.e), 52'(a.m), sb_eff, 11'(b.e), 52'(b.m), l_rm);
        exp_c  = f32 ? r.bits[31:0] : {16'h0, r.bits[15:0]};
        exp_ff = {2'b00, r.of, 1'b0, r.nx};
        // ★golden 怪癖：f16 两零相加得 -0 时，符号位复制了 17 份（高 16 位全 1）★
        if (!f32 && a.zero && b.zero && r.bits[15]) exp_c = 32'hFFFF_8000;
        if (!(a.zero && b.zero)) begin if (u_i.u_core.far_path_q) cov_far++; else cov_close++; end
      end
    end else begin
      lt = !nv_any && flt_mag(a, b);
      eq = !nv_any && feq_mag(a, b);
      pick_min = (flt_mag(b, a) || (b.sign && a.zero && b.zero)) ? b_nat : a_nat;
      pick_max = (flt_mag(a, b) || (!b.sign && a.zero && b.zero)) ? b_nat : a_nat;
      case (l_op)
        5'b00010, 5'b00011: begin      // fmin / fmax
          exp_c = (a.nan && b.nan) ? qnan : a.nan ? b_nat : b.nan ? a_nat : (l_op[0] ? pick_max : pick_min);
          exp_ff = {nv_s, 4'b0};
        end
        5'b11110, 5'b10011: begin      // fminm / fmaxm
          exp_c = nv_any ? qnan : (l_op == 5'b10011 ? pick_max : pick_min);
          exp_ff = {nv_s, 4'b0};
        end
        5'b01001: begin exp_c = {31'h0, eq};       exp_ff = {nv_s, 4'b0};   end   // feq
        5'b01011: begin exp_c = {31'h0, lt};       exp_ff = {nv_any, 4'b0}; end   // flt
        5'b01100: begin exp_c = {31'h0, lt | eq};  exp_ff = {nv_any, 4'b0}; end   // fle
        5'b11011: begin exp_c = {31'h0, lt};       exp_ff = {nv_s, 4'b0};   end   // fltq
        5'b11100: begin exp_c = {31'h0, lt | eq};  exp_ff = {nv_s, 4'b0};   end   // fleq
        5'b00110: exp_c = f32 ? {b_fix[31], a_fix[30:0]} : {16'h0, b_fix[15], a_fix[14:0]};
        5'b00111: exp_c = f32 ? {~b_fix[31], a_fix[30:0]} : {16'h0, ~b_fix[15], a_fix[14:0]};
        5'b01000: exp_c = f32 ? {b_fix[31] ^ a_fix[31], a_fix[30:0]} : {16'h0, b_fix[15] ^ a_fix[15], a_fix[14:0]};
        5'b01111: begin                // fclass
          logic sub_n, norm;
          sub_n = (a.e == 0) && (a.m != 0);
          norm  = (a.e != 0) && !(f32 ? &a.e : &a.e[4:0]);
          exp_c = l_acn ? 32'h200 : {22'h0,
                    a.nan & ~a.snan, a.snan,
                    ~a.sign & a.inf, ~a.sign & norm, ~a.sign & sub_n, ~a.sign & a.zero,
                    a.sign & a.zero, a.sign & sub_n, a.sign & norm, a.sign & a.inf};
        end
        default: exp_c = 32'h0;
      endcase
    end
    oracle_checks++;
    cov_op[l_op]++;
    if (exp_ff[4]) cov_nv++;
    if (exp_ff[2]) cov_of++;
    if (exp_ff[0]) cov_nx++;
    if (g_c !== exp_c || g_ff !== exp_ff) begin
      errors++;
      if (errors <= 30) $display("[%0d] ORACLE op=%0d fmt=%0d rm=%0d sub=%0d cn=%0d%0d a=%h b=%h golden=%h/%b expect=%h/%b",
                                 cyc, l_op, l_fmt, l_rm, l_sub, l_acn, l_bcn, l_a, l_b, g_c, g_ff, exp_c, exp_ff);
    end
  endtask

  // ---- 激励 ----
  localparam logic [4:0] CMP_OPS [13] = '{5'b00010, 5'b00011, 5'b00110, 5'b00111, 5'b01000, 5'b01001,
                                          5'b01011, 5'b01100, 5'b01111, 5'b10011, 5'b11011, 5'b11100, 5'b11110};
  function automatic logic [7:0] pick_exp(input bit f32);
    logic [7:0] emax = f32 ? 8'hFF : 8'h1F;
    case ($urandom_range(0, 9))
      0: return 8'h00;
      1: return 8'h01;
      2: return emax;
      3: return emax - 8'h1;
      4: return emax - 8'(1 + $urandom_range(0, 1));
      5: return 8'($urandom_range(2, 26));
      default: return f32 ? 8'($urandom) : 8'($urandom_range(0, 31));
    endcase
  endfunction
  function automatic logic [22:0] pick_mant(input bit f32);
    logic [22:0] m = 23'($urandom);
    case ($urandom_range(0, 6))
      0: m = '1;
      1, 2: m = '0;
      3: m = 23'(1) << $urandom_range(0, 22);
      default: ;
    endcase
    return f32 ? m : {13'h0, m[9:0]};
  endfunction
  function automatic logic [31:0] pack(input bit f32, input logic s, input logic [7:0] e, input logic [22:0] m);
    return f32 ? {s, e, m} : {16'($urandom), s, e[4:0], m[9:0]};
  endfunction

  task automatic drive();
    logic [7:0]  ea, eb;
    logic [22:0] ma, mb;
    bit f32;
    fire       = ($urandom_range(0, 3) != 0);
    round_mode = ($urandom_range(0, 7) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, 4));
    is_sub     = $urandom;
    fp_format  = $urandom;
    a_cnan     = ($urandom_range(0, 15) == 0);
    b_cnan     = ($urandom_range(0, 15) == 0);
    case ($urandom_range(0, 15))
      0: op_code = 5'($urandom);
      1, 2, 3, 4, 5, 6: op_code = CMP_OPS[$urandom_range(0, 12)];
      default: op_code = 5'($urandom_range(0, 1));
    endcase
    f32 = fp_format[0];
    if ($urandom_range(0, 7) == 0) begin
      fp_a = $urandom; fp_b = $urandom;
      return;
    end
    ea = pick_exp(f32);
    ma = pick_mant(f32);
    case ($urandom_range(0, 4))
      0: eb = ea;
      1: eb = ($urandom & 1) ? ea + 8'h1 : ea - 8'h1;
      2: eb = ($urandom & 1) ? ea + 8'($urandom_range(2, 30)) : ea - 8'($urandom_range(2, 30));
      3: eb = ea ^ 8'h1;
      default: eb = pick_exp(f32);
    endcase
    case ($urandom_range(0, 3))
      0: mb = ma ^ (f32 ? 23'($urandom_range(0, 7)) : 23'($urandom_range(0, 7)));
      1: mb = ma;
      default: mb = pick_mant(f32);
    endcase
    fp_a = pack(f32, $urandom, ea, ma);
    fp_b = pack(f32, $urandom, eb, mb);
  endtask

  initial begin
    bit armed = 0;
    bit cov_ok = 1;
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (int k = 0; k < 32; k++) cov_op[k] = 0;
    fire = 0; fp_a = 0; fp_b = 0; is_sub = 0; round_mode = 0; fp_format = 0; op_code = 0; a_cnan = 0; b_cnan = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      drive();
      #1;
      if (armed) begin compare_all(); oracle_check(); end
      @(posedge clock);
      if (fire) begin
        armed = 1;
        l_a = fp_a; l_b = fp_b; l_sub = is_sub; l_rm = round_mode; l_fmt = fp_format; l_op = op_code;
        l_acn = a_cnan; l_bcn = b_cnan;
      end
      #1;
    end
    if (cov_far < 2000 || cov_close < 2000) begin cov_ok = 0; $display("COV FAIL far=%0d close=%0d", cov_far, cov_close); end
    foreach (CMP_OPS[k]) if (cov_op[CMP_OPS[k]] < 500) begin cov_ok = 0; $display("COV FAIL op %b = %0d", CMP_OPS[k], cov_op[CMP_OPS[k]]); end
    if (cov_nv < 200 || cov_of < 200 || cov_nx < 200) begin cov_ok = 0; $display("COV FAIL nv=%0d of=%0d nx=%0d", cov_nv, cov_of, cov_nx); end
    if (oracle_checks < 100000) begin cov_ok = 0; $display("COV FAIL oracle_checks=%0d", oracle_checks); end
    if (seen1[0] != '1 || seen0[0] != '1) begin cov_ok = 0; $display("COV FAIL fp_c toggle 1:%h 0:%h", seen1[0], seen0[0]); end
    if (seen1[1] != 32'h15 || seen0[1] != 32'h1F) begin cov_ok = 0; $display("COV FAIL fflags toggle 1:%h 0:%h", seen1[1], seen0[1]); end
    $display("COVERAGE oracle=%0d far=%0d close=%0d nv=%0d of=%0d nx=%0d fadd=%0d fsub=%0d", oracle_checks, cov_far, cov_close,
             cov_nv, cov_of, cov_nx, cov_op[0], cov_op[1]);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && cov_ok) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
