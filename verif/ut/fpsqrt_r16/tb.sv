// =============================================================================
// tb —— fpsqrt_r16 UT：golden fpsqrt_r16（含 golden 子树）与重写件 fpsqrt_r16_xs（子树全是重写件：
// lzc / r4_qds_cg / fpsqrt_r16_block 及其 r4_qds*）双例化，同激励逐拍比；另带**独立 IEEE oracle**。
//
// 差分比较：start_ready_o / finish_valid_o 每拍比（fsm_q 有复位）；fpsqrt_res_o / fflags_o 只在
//   finish_valid_o=1 时比——其余寄存器都不复位，+random 档两侧上电值不同，结果通路在第一次运算完成前
//   读到的是未写过的寄存器（tb 契约：结果只在 finish 握手窗口有效）。
// oracle（与被测件算法无关）：每次被接收的运算（start 握手且同拍无 flush），按 IEEE 754 算期望结果——
//   正有限数先规格化成 M·2^E（E 调成偶数），R = isqrt(M·4^G)（tb 里逐位恢复法求整数平方根，G 取得足够大），
//   余数非零即 sticky，再按 rm 舍入到 p 位（RNE / RTZ / RDN / RUP / RMM；5..7 按截断，golden 对它们不进位）；
//   特殊值：NaN（含 fp_aIsFpCanonicalNAN）→ 规范 qNaN，sNaN 与负非零数置 NV；±0 → ±0；+Inf → +Inf。
//   finish 握手时（且该运算没被 flush 打断）结果位必须等于期望；fflags 的 NV 必须相等，NX 只对有限正数
//   与 NaN 比（见下"已知不比"）。
//   ★已知不比★（golden 的行为，差分照比、oracle 不比）：±0 / +Inf / 尾数全 0 的操作数走提前结束，不跑迭代，
//   NX 由上一拍残留的迭代寄存器组合出来；这几类只比结果位与 NV，NX 不比。
// 激励：start_valid 3/4；fp_format_i 0/1/2 各 30%、3（非法）10%；rm 0..4 各 18%、5..7 10%；
//   操作数按格式造：规格数 / 非规格数 / 零 / 无穷 / qNaN / sNaN / 负数 / 尾数全 0（√2 路径）/ 完全平方 九类，另 1/8 全随机；
//   fp_aIsFpCanonicalNAN 1/16 置 1；finish_ready 3/4；flush 1/64 拍，可打断任意状态。
// 覆盖（写进 PASS 判据）：3 合法格式 × 5 合法 rm 各 >= 100 次 finish；9 类操作数 × 3 格式各 >= 30；
//   oracle 比对 >= 20000 次；余数为负（选根减一）>= 100、舍入进位溢出 >= 30、flush 打断迭代 >= 20、
//   非规格数两拍初始化 >= 100；结果 64 位与 fflags 5 位每位都见过 0 和 1（fflags 的 DZ/OF/UF 是 golden 字面 0，只要求见过 0）。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0, oracle_checks = 0;
  int cyc;

  logic clock = 0, reset = 1;
  logic start_valid_i, flush_i, finish_ready_i, canon_nan;
  logic [1:0] fp_format_i;
  logic [63:0] op_i;
  logic [2:0] rm_i;
  logic g_start_ready, i_start_ready, g_finish_valid, i_finish_valid;
  logic [63:0] g_res, i_res;
  logic [4:0] g_fflags, i_fflags;

  fpsqrt_r16 u_g (.clock(clock), .reset(reset), .start_valid_i(start_valid_i), .start_ready_o(g_start_ready),
    .flush_i(flush_i), .fp_format_i(fp_format_i), .op_i(op_i), .rm_i(rm_i), .finish_valid_o(g_finish_valid),
    .finish_ready_i(finish_ready_i), .fpsqrt_res_o(g_res), .fflags_o(g_fflags), .fp_aIsFpCanonicalNAN(canon_nan));
  fpsqrt_r16_xs u_i (.clock(clock), .reset(reset), .start_valid_i(start_valid_i), .start_ready_o(i_start_ready),
    .flush_i(flush_i), .fp_format_i(fp_format_i), .op_i(op_i), .rm_i(rm_i), .finish_valid_o(i_finish_valid),
    .finish_ready_i(finish_ready_i), .fpsqrt_res_o(i_res), .fflags_o(i_fflags), .fp_aIsFpCanonicalNAN(canon_nan));

  always #5 clock = ~clock;

  // ---- 操作数构造 ----
  typedef enum int {K_NORM, K_DENORM, K_ZERO, K_INF, K_QNAN, K_SNAN, K_NEG, K_POW2, K_SQUARE, K_RAND} kind_t;
  localparam int NKIND = 9;
  function automatic logic [63:0] isqrt(input logic [127:0] x);   // 逐位恢复法，结果不超过 64 位
    logic [127:0] r = 0, bitv = 128'd1 << 126, rem = x;
    while (bitv > rem) bitv >>= 2;
    while (bitv != 0) begin
      if (rem >= r + bitv) begin rem -= r + bitv; r = (r >> 1) + bitv; end
      else r >>= 1;
      bitv >>= 2;
    end
    return 64'(r);
  endfunction

  function automatic logic [63:0] make_fp(input int exp_w, input int frac_w, input kind_t k);
    logic [63:0] exp_max, e, f, s;
    exp_max = (64'd1 << exp_w) - 1;
    f = {$urandom, $urandom} & ((64'd1 << frac_w) - 1);
    s = 1'b0;
    case (k)
      K_NORM:   begin e = 64'($urandom_range(1, exp_max - 1)); if ($urandom_range(0, 1) == 0) f = (64'd1 << frac_w) - 1; end
      K_DENORM: begin e = 0; if ($urandom_range(0, 1)) f = f >> $urandom_range(0, frac_w - 1); if (f == 0) f = 1; end
      K_ZERO:   begin e = 0; f = 0; s = $urandom; end
      K_INF:    begin e = exp_max; f = 0; end
      K_QNAN:   begin e = exp_max; f = f | (64'd1 << (frac_w - 1)); end
      K_SNAN:   begin e = exp_max; f = (f & ~(64'd1 << (frac_w - 1))); if (f == 0) f = 1; end
      K_NEG:    begin e = 64'($urandom_range(0, exp_max)); s = 1'b1; end
      K_POW2:   begin e = 64'($urandom_range(1, exp_max - 1)); f = 0; end
      K_SQUARE: begin   // 完全平方：有效位不超过 (frac_w+1)/2 的整数 Y 的平方
        int h = $urandom_range(1, (frac_w + 1) / 2);
        logic [63:0] Y = (64'd1 << (h - 1)) | ({$urandom, $urandom} & ((64'd1 << (h - 1)) - 1));
        logic [127:0] Y2 = 128'(Y) * 128'(Y);
        int t = 0;
        for (int b = 0; b < 128; b++) if (Y2[b]) t = b;     // 最高位
        f = 64'((Y2 << (frac_w - t)) & ((128'd1 << frac_w) - 1));
        e = 64'($urandom_range(1, exp_max - 1));
        if (((e - (exp_max >> 1)) & 1) != (t & 1)) e = (e == exp_max - 1) ? e - 1 : e + 1;  // 指数奇偶配齐
      end
      default:  begin e = 64'($urandom_range(0, exp_max)); s = $urandom; end
    endcase
    return (s << (exp_w + frac_w)) | (e << frac_w) | f;
  endfunction

  // ---- IEEE oracle：返回 {结果, NV, NX, NX 可比} ----
  task automatic oracle(input int fmt, input logic [63:0] op, input logic [2:0] rm, input logic cnan,
                        output logic [63:0] res, output logic nv, output logic nx, output logic nx_cmp);
    int exp_w = (fmt == 0) ? 5 : (fmt == 1) ? 8 : 11;
    int frac_w = (fmt == 0) ? 10 : (fmt == 1) ? 23 : 52;
    int p = frac_w + 1, bias = (1 << (exp_w - 1)) - 1;
    logic [63:0] emax = (64'd1 << exp_w) - 1;
    logic [63:0] x, f, e, qnan;
    logic s;
    x = (fmt == 0) ? {48'b0, op[15:0]} : (fmt == 1) ? {32'b0, op[31:0]} : op;
    s = x[exp_w + frac_w];
    e = (x >> frac_w) & emax;
    f = x & ((64'd1 << frac_w) - 1);
    qnan = (emax << frac_w) | (64'd1 << (frac_w - 1));
    nv = 0; nx = 0; nx_cmp = 1;
    if (cnan) begin res = qnan; return; end
    if (e == emax) begin
      if (f != 0) begin res = qnan; nv = ~f[frac_w - 1]; return; end
      if (s) begin res = qnan; nv = 1; return; end
      res = x; nx_cmp = 0; return;                         // +Inf
    end
    if (e == 0 && f == 0) begin res = x; nx_cmp = 0; return; end   // ±0
    if (s) begin res = qnan; nv = 1; return; end
    if (f == 0) nx_cmp = 0;                               // 尾数全 0：提前结束路径（见文件头）
    begin
      longint E;               // 值 = M · 2^E
      logic [63:0] M;
      logic [127:0] rad;
      logic [63:0] R, Rr;
      int G, t, sh, ue;
      bit sticky, guard, rest, up, lsb;
      if (e == 0) begin M = f; E = 1 - bias - frac_w; end
      else begin M = f | (64'd1 << frac_w); E = longint'(e) - bias - frac_w; end
      while (M[frac_w] == 1'b0) begin M = M << 1; E = E - 1; end   // 非规格数先规格化到 p 位
      if (E % 2 != 0) begin M = M << 1; E = E - 1; end
      G = (p + 7) / 2;                                    // 根至少 p+3 位；被开方数 <= p+1+2G <= 128 位
      rad = 128'(M) << (2 * G);
      R = isqrt(rad);
      sticky = (128'(R) * 128'(R) != rad);
      t = 0;
      for (int b = 0; b < 64; b++) if (R[b]) t = b;
      ue = int'(E / 2) - G + t;                           // 结果的无偏指数
      sh = t + 1 - p;                                     // 要舍掉的位数（>= 3）
      guard = R[sh - 1];
      rest = sticky | ((R & ((64'd1 << (sh - 1)) - 1)) != 0);
      Rr = R >> sh;
      lsb = Rr[0];
      case (rm)
        3'd0:    up = guard & (rest | lsb);               // RNE
        3'd3:    up = guard | rest;                       // RUP（结果为正）
        3'd4:    up = guard;                              // RMM
        default: up = 0;                                  // RTZ / RDN（正数）/ 5..7
      endcase
      Rr = Rr + up;
      if (Rr[p]) begin Rr = Rr >> 1; ue = ue + 1; end
      nx = guard | rest;
      res = (64'(ue + bias) << frac_w) | (Rr & ((64'd1 << frac_w) - 1));
    end
  endtask

  int cov_fmt_rm [3][5];
  int cov_kind [3][NKIND];
  int cov_negrem, cov_carry, cov_flush_iter, cov_finish, cov_pre1;
  logic seen0 [71], seen1 [71];   // 0..1 握手，2..65 结果 64 位，66..70 fflags 5 位
  kind_t kind0;

  task automatic drive();
    int fmt;
    start_valid_i  = ($urandom_range(0, 3) != 0);
    finish_ready_i = ($urandom_range(0, 3) != 0);
    flush_i        = ($urandom_range(0, 63) == 0);
    canon_nan      = ($urandom_range(0, 15) == 0);
    case ($urandom_range(0, 9))
      0, 1, 2: fp_format_i = 2'd0;
      3, 4, 5: fp_format_i = 2'd1;
      6, 7, 8: fp_format_i = 2'd2;
      default: fp_format_i = 2'd3;
    endcase
    rm_i = ($urandom_range(0, 9) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, 4));
    kind0 = kind_t'($urandom_range(0, NKIND - 1));
    fmt = (fp_format_i == 2'd3) ? 0 : fp_format_i;
    op_i = {$urandom, $urandom};                          // 未用高位也随机
    case (fmt)
      2:       op_i = make_fp(11, 52, kind0);
      1:       op_i[31:0] = 32'(make_fp(8, 23, kind0));
      default: op_i[15:0] = 16'(make_fp(5, 10, kind0));
    endcase
    if ($urandom_range(0, 7) == 0) begin op_i = {$urandom, $urandom}; kind0 = K_RAND; end
  endtask

  `define CMP(k, g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 30) $display("[%0d] MISMATCH %s golden=%h impl=%h", cyc, nm, (g), (i)); end \
      if (|(g)) seen1[k] = 1; if (!(&(g))) seen0[k] = 1; end

  // 在途运算的期望
  bit pending = 0;
  logic [1:0] cur_fmt; logic [2:0] cur_rm; kind_t cur_kind;
  logic [63:0] exp_res; logic exp_nv, exp_nx, exp_nx_cmp;

  initial begin
    int bad;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    cov_negrem = 0; cov_carry = 0; cov_flush_iter = 0; cov_finish = 0; cov_pre1 = 0;
    start_valid_i = 0; finish_ready_i = 0; flush_i = 0; fp_format_i = 0; op_i = 0; rm_i = 0; canon_nan = 0;
    repeat (3) @(posedge clock);
    #1 reset = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      drive();
      #1;
      `CMP(0, g_start_ready, i_start_ready, "start_ready_o")
      `CMP(1, g_finish_valid, i_finish_valid, "finish_valid_o")
      if (g_finish_valid) begin
        `CMP(2, g_res, i_res, "fpsqrt_res_o")
        `CMP(3, g_fflags, i_fflags, "fflags_o")
        for (int b = 0; b < 64; b++) begin if (g_res[b]) seen1[2 + b] = 1; else seen0[2 + b] = 1; end
        for (int b = 0; b < 5; b++) begin if (g_fflags[b]) seen1[66 + b] = 1; else seen0[66 + b] = 1; end
        if (finish_ready_i && !flush_i && pending) begin
          cov_finish++;
          if (cur_fmt != 2'd3 && cur_rm < 5) cov_fmt_rm[cur_fmt][cur_rm]++;
          if (cur_fmt != 2'd3 && cur_kind != K_RAND) cov_kind[cur_fmt][cur_kind]++;
          if (u_g._nr_f_r_T[66]) cov_negrem++;
          if (u_g.frac_rounded_0[52]) cov_carry++;
          if (cur_fmt != 2'd3) begin
            oracle_checks++;
            if (i_res !== exp_res || i_fflags[4] !== exp_nv || (exp_nx_cmp && i_fflags[0] !== exp_nx)) begin
              errors++;
              if (errors <= 30)
                $display("[%0d] ORACLE fmt=%0d rm=%0d kind=%0d got=%h/%b exp=%h nv=%0d nx=%0d(cmp %0d)",
                         cyc, cur_fmt, cur_rm, cur_kind, i_res, i_fflags, exp_res, exp_nv, exp_nx, exp_nx_cmp);
            end
          end
          pending = 0;
        end
      end
      if (flush_i) pending = 0;
      if (g_start_ready && start_valid_i && !flush_i) begin
        cur_fmt = fp_format_i; cur_rm = rm_i; cur_kind = kind0; pending = 1;
        if (fp_format_i != 2'd3) oracle(fp_format_i, op_i, rm_i, canon_nan, exp_res, exp_nv, exp_nx, exp_nx_cmp);
      end
      if (flush_i && u_g.fsm_q[2]) cov_flush_iter++;
      if (u_g.fsm_q[1]) cov_pre1++;
    end
    bad = 0;
    foreach (cov_fmt_rm[a, b]) if (cov_fmt_rm[a][b] < 100) begin bad++; $display("COV FAIL fmt=%0d rm=%0d : %0d", a, b, cov_fmt_rm[a][b]); end
    foreach (cov_kind[a, b]) if (cov_kind[a][b] < 30) begin bad++; $display("COV FAIL fmt=%0d kind=%0d : %0d", a, b, cov_kind[a][b]); end
    $display("COVERAGE finish=%0d oracle=%0d negrem=%0d carry=%0d flush_in_iter=%0d pre1=%0d",
             cov_finish, oracle_checks, cov_negrem, cov_carry, cov_flush_iter, cov_pre1);
    if (oracle_checks < 20000 || cov_negrem < 100 || cov_carry < 30 || cov_flush_iter < 20 || cov_pre1 < 100) bad++;
    // fflags {NV, DZ, OF, UF, NX}：DZ/OF/UF 是 golden 字面 0，只要求见过 0
    for (int o = 0; o < 71; o++) begin
      bit const0;
      const0 = (o >= 66) && ((o - 66) inside {1, 2, 3});
      if (!seen0[o] || (!const0 && !seen1[o])) begin bad++; $display("COV FAIL output bit %0d stuck", o); end
    end
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
