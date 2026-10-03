// =============================================================================
// tb —— fpsqrt_vector_r16 UT：golden fpsqrt_vector_r16（含 golden 子树）与重写件 fpsqrt_vector_r16_xs
// （lzc/r4_qds_cg 用重写件，fpsqrt_r16_block 两侧同读 golden）双例化，同激励逐拍比。
//
// 比对：start_ready_o / finish_valid_o 每拍比（fsm_q 有复位）；fpsqrt_res_o / fflags_o 只在
//   finish_valid_o=1 时比——其余寄存器都不复位，+random 档两侧上电值不同，结果通路在第一次运算
//   完成前读到的是未写过的寄存器（tb 契约：结果只在 finish 握手窗口有效）。
// 激励：start_valid 3/4 置 1；fp_format 0/1/2 各 30%、3（非法，三个格式位全 0）10%；rm 0..4 各 18%、5..7 10%；
//   操作数按格式逐通道造：规格数 / 非规格数 / 零 / 无穷 / qNaN / sNaN / 负数 八类轮换，另 1/4 全随机；
//   finish_ready 3/4 置 1（握手等待时结果须保持）；flush 1/64 拍，可打断任意状态。
// 覆盖（写进 PASS 判据）：3 合法格式 × 5 合法 rm 各 >= 100 次 finish；通道 0 的 8 类操作数 × 3 格式各 >= 50；
//   余数为负（选根减一）>= 100、舍入进位 >= 30（规格数一半取全 1 尾数专门打它，只在 RUP/RMM 下触发）；flush 打断迭代 >= 20；
//   结果 64 位与 fflags 20 位每位都见过 0 和 1，除 fflags 的 DZ/OF/UF 三列（golden 字面 0，只要求见过 0）。
//   ★更正★：上一版只跟踪 fflags 低 16 位、且把 DZ/OF/UF 也要求见过 1——它在 initreg=0 档必然红，在全 1 档
//   却因 finish 窗口里混入未写寄存器的值而"绿"，判据读的是上电值不是功能；已改。零操作数随机带符号以打结果符号位。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0;
  int cyc;

  logic clock = 0, reset = 1;
  logic start_valid_i, flush_i, finish_ready_i;
  logic [1:0] fp_format_i;
  logic [63:0] op_i;
  logic [2:0] rm_i;
  logic g_start_ready, i_start_ready, g_finish_valid, i_finish_valid;
  logic [63:0] g_res, i_res;
  logic [19:0] g_fflags, i_fflags;

  fpsqrt_vector_r16 u_g (.clock(clock), .reset(reset), .start_valid_i(start_valid_i), .start_ready_o(g_start_ready),
    .flush_i(flush_i), .fp_format_i(fp_format_i), .op_i(op_i), .rm_i(rm_i), .finish_valid_o(g_finish_valid),
    .finish_ready_i(finish_ready_i), .fpsqrt_res_o(g_res), .fflags_o(g_fflags));
  fpsqrt_vector_r16_xs u_i (.clock(clock), .reset(reset), .start_valid_i(start_valid_i), .start_ready_o(i_start_ready),
    .flush_i(flush_i), .fp_format_i(fp_format_i), .op_i(op_i), .rm_i(rm_i), .finish_valid_o(i_finish_valid),
    .finish_ready_i(finish_ready_i), .fpsqrt_res_o(i_res), .fflags_o(i_fflags));

  always #5 clock = ~clock;

  // ---- 操作数构造 ----
  typedef enum int {K_NORM, K_DENORM, K_ZERO, K_INF, K_QNAN, K_SNAN, K_NEG, K_RAND} kind_t;
  function automatic logic [63:0] make_fp(input int exp_w, input int frac_w, input kind_t k);
    logic [63:0] exp_max, e, f, s;
    exp_max = (64'd1 << exp_w) - 1;
    f = {$urandom, $urandom} & ((64'd1 << frac_w) - 1);
    s = 1'b0;
    case (k)
      K_NORM:   begin e = 64'($urandom_range(1, exp_max - 1)); if ($urandom_range(0, 1) == 0) f = (64'd1 << frac_w) - 1; end   // 一半取全 1 尾数：指数为奇时根 = 2-ε，RUP/RMM 下舍入进位
      K_DENORM: begin e = 0; if (f == 0) f = 1; end
      K_ZERO:   begin e = 0; f = 0; s = $urandom; end                                  // ±0：sqrt(-0) = -0，结果符号位只靠它置 1
      K_INF:    begin e = exp_max; f = 0; end
      K_QNAN:   begin e = exp_max; f = f | (64'd1 << (frac_w - 1)); end
      K_SNAN:   begin e = exp_max; f = (f & ~(64'd1 << (frac_w - 1))); if (f == 0) f = 1; end
      K_NEG:    begin e = 64'($urandom_range(0, exp_max)); s = 1'b1; end
      default:  begin e = 64'($urandom_range(0, exp_max)); s = $urandom; end
    endcase
    return (s << (exp_w + frac_w)) | (e << frac_w) | f;
  endfunction

  int cov_fmt_rm [3][5];
  int cov_kind [3][8];
  int cov_negrem, cov_carry, cov_flush_iter, cov_finish;
  logic seen0 [88], seen1 [88];   // 0..3 握手/汇总，4..67 结果 64 位，68..87 fflags 20 位
  kind_t kind0;

  task automatic drive();
    kind_t kk;
    int fmt;
    start_valid_i  = ($urandom_range(0, 3) != 0);
    finish_ready_i = ($urandom_range(0, 3) != 0);
    flush_i        = ($urandom_range(0, 63) == 0);
    case ($urandom_range(0, 9))
      0, 1, 2: fp_format_i = 2'd0;
      3, 4, 5: fp_format_i = 2'd1;
      6, 7, 8: fp_format_i = 2'd2;
      default: fp_format_i = 2'd3;
    endcase
    rm_i = ($urandom_range(0, 9) == 0) ? 3'($urandom_range(5, 7)) : 3'($urandom_range(0, 4));
    kind0 = kind_t'($urandom_range(0, 7));
    fmt = (fp_format_i == 2'd3) ? 0 : fp_format_i;
    case (fmt)
      2:       op_i = make_fp(11, 52, kind0);
      1:       begin op_i[63:32] = 32'(make_fp(8, 23, kind0)); op_i[31:0] = 32'(make_fp(8, 23, kind_t'($urandom_range(0, 7)))); end
      default: begin
        op_i[63:48] = 16'(make_fp(5, 10, kind0));
        for (int l = 0; l < 3; l++) op_i[16*l +: 16] = 16'(make_fp(5, 10, kind_t'($urandom_range(0, 7))));
      end
    endcase
    if ($urandom_range(0, 3) == 0) begin op_i = {$urandom, $urandom}; kind0 = K_RAND; end
  endtask

  `define CMP(k, g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 30) $display("[%0d] MISMATCH %s golden=%h impl=%h", cyc, nm, (g), (i)); end \
      if (|(g)) seen1[k] = 1; if (!(&(g))) seen0[k] = 1; end

  // 记住每次发起的运算的格式/rm/操作数类，finish 时计覆盖
  logic [1:0] cur_fmt; logic [2:0] cur_rm; kind_t cur_kind;

  initial begin
    int bad;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    cov_negrem = 0; cov_carry = 0; cov_flush_iter = 0; cov_finish = 0;
    start_valid_i = 0; finish_ready_i = 0; flush_i = 0; fp_format_i = 0; op_i = 0; rm_i = 0;
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
        for (int b = 0; b < 64; b++) begin if (g_res[b]) seen1[4 + b] = 1; else seen0[4 + b] = 1; end
        for (int b = 0; b < 20; b++) begin if (g_fflags[b]) seen1[68 + b] = 1; else seen0[68 + b] = 1; end
        if (finish_ready_i) begin
          cov_finish++;
          if (cur_fmt != 2'd3 && cur_rm < 5) cov_fmt_rm[cur_fmt][cur_rm]++;
          if (cur_fmt != 2'd3) cov_kind[cur_fmt][cur_kind]++;
          if (u_g._nr_f_r_T[66]) cov_negrem++;
          if (u_g.frac_rounded_0[52]) cov_carry++;
        end
      end
      if (g_start_ready && start_valid_i && !flush_i) begin cur_fmt = fp_format_i; cur_rm = rm_i; cur_kind = kind0; end
      if (flush_i && u_g.fsm_q[2]) cov_flush_iter++;
    end
    bad = 0;
    foreach (cov_fmt_rm[a, b]) begin
      $display("cov fmt=%0d rm=%0d : %0d", a, b, cov_fmt_rm[a][b]);
      if (cov_fmt_rm[a][b] < 100) bad++;
    end
    foreach (cov_kind[a, b]) begin
      $display("cov fmt=%0d kind=%0d : %0d", a, b, cov_kind[a][b]);
      if (cov_kind[a][b] < 50) bad++;
    end
    $display("cov finish=%0d negrem=%0d carry=%0d flush_in_iter=%0d", cov_finish, cov_negrem, cov_carry, cov_flush_iter);
    if (cov_negrem < 100 || cov_carry < 30 || cov_flush_iter < 20) bad++;
    // fflags 每 5 位一组 {NV, DZ, OF, UF, NX}：开方没有除零/上溢/下溢，golden 的 fflags_o 在这三位上
    // 是字面 3'h0（golden fpsqrt_vector_r16.sv 的 assign fflags_o），所以这 12 位只要求见过 0。
    for (int o = 0; o < 88; o++) begin
      bit const0;
      const0 = (o >= 68) && ((o - 68) % 5 inside {1, 2, 3});
      if (!seen0[o] || (!const0 && !seen1[o])) begin bad++; $display("output bit %0d stuck", o); end
    end
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
