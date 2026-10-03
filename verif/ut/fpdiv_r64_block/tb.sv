// =============================================================================
// tb —— fpdiv_r64_block UT：golden（含 golden CSA/qds 子树）与重写件 fpdiv_r64_block_xs（含重写子树）
// 双例化，同激励逐拍比全部 7 个输出。纯组合，每拍一组新输入。
//
// 两种激励交替：
//   A. 随机拍（一半）：余数 sum/carry、除数、6/7 位余数片任意（四种形状：全随机/稀疏/稠密/全 0），
//      覆盖 qds 全表与 CSA 全部进位情形；
//   B. 闭环除法（一半）：按 FloatDividerR64 的流程造一次真实的 f64 尾数除法——两个 52 位尾数
//      按 golden 的预缩放表同乘一个因子（9..16 / 8），按"被除数尾数 < 除数尾数"选移位，装初始余数
//      与整数商位（+2/+1），然后把**重写件**的输出（余数、6/7 位片）喂回去连迭代 9 次（27 个商位）。
//
// 独立 oracle（不看 golden，只用整数算术）：
//   O1 每一拍（随机拍里 qds 查表多命中、商位非 one-hot 时跳过并计数；闭环拍必须 one-hot）：(s_out + c_out) ≡ 64·(s_in + c_in) − (16·q0 + 4·q1 + q2)·2D  (mod 2^60)，
//      即"3 级基 4 迭代 + 选候选"的代数恒等式；q0/q1/q2 必须 one-hot。
//   O2 闭环终了：R = 有符号(s + c)，Q = 整数商位·4^27 + Σ 商位·4^(27-j)，要求 |R| < 2D 且
//      Q·2D + R == 4^27·X（X 为初始被除数片），于是 Q 等于 floor(4^27·X / 2D)（R ≥ 0）或其 +1（R < 0）——
//      与 tb 内宽整数除法逐位核对。
// 覆盖（写进 PASS 判据）：s0/s1/s2 各 5 个商位、预缩放 8 档、移位 2 档、终了余数正/负 各 >= 门槛；
//   每个输出位都见过 0 和 1。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0, oracle_err = 0, oracle_checks = 0;
  int cyc;

  logic [71:0] f_r_s_i, f_r_c_i;
  logic [59:0] divisor_i;
  logic [5:0]  rem6_i;
  logic [6:0]  rem7_i;

  logic [4:0]  g_q0, g_q1, g_q2, i_q0, i_q1, i_q2;
  logic [71:0] g_s, g_c, i_s, i_c;
  logic [5:0]  g_r6, i_r6;
  logic [6:0]  g_r7, i_r7;

  fpdiv_r64_block u_g (
    .io_f_r_s_i(f_r_s_i), .io_f_r_c_i(f_r_c_i), .io_divisor_i(divisor_i),
    .io_nr_f_r_6b_for_nxt_cycle_s0_qds_i(rem6_i), .io_nr_f_r_7b_for_nxt_cycle_s1_qds_i(rem7_i),
    .io_nxt_quo_dig_o_0_0(g_q0), .io_nxt_quo_dig_o_0_1(g_q1), .io_nxt_quo_dig_o_0_2(g_q2),
    .io_nxt_f_r_s_o_2(g_s), .io_nxt_f_r_c_o_2(g_c),
    .io_adder_6b_res_for_nxt_cycle_s0_qds_o(g_r6), .io_adder_7b_res_for_nxt_cycle_s1_qds_o(g_r7));
  fpdiv_r64_block_xs u_i (
    .io_f_r_s_i(f_r_s_i), .io_f_r_c_i(f_r_c_i), .io_divisor_i(divisor_i),
    .io_nr_f_r_6b_for_nxt_cycle_s0_qds_i(rem6_i), .io_nr_f_r_7b_for_nxt_cycle_s1_qds_i(rem7_i),
    .io_nxt_quo_dig_o_0_0(i_q0), .io_nxt_quo_dig_o_0_1(i_q1), .io_nxt_quo_dig_o_0_2(i_q2),
    .io_nxt_f_r_s_o_2(i_s), .io_nxt_f_r_c_o_2(i_c),
    .io_adder_6b_res_for_nxt_cycle_s0_qds_o(i_r6), .io_adder_7b_res_for_nxt_cycle_s1_qds_o(i_r7));

  // ---- 差分比较 + 逐位翻转覆盖 ----
  localparam int N_OUT = 7;
  logic [71:0] seen0 [N_OUT], seen1 [N_OUT], must [N_OUT];
  initial begin
    for (int k = 0; k < N_OUT; k++) begin seen0[k] = '0; seen1[k] = '0; end
    must[0] = 72'h1F; must[1] = 72'h1F; must[2] = 72'h1F;
    must[3] = {60'hFFF_FFFF_FFFF_FFFF, 12'h0};     // 余数低 12 位恒 0（golden 字面）
    must[4] = {60'hFFF_FFFF_FFFF_FFFD, 12'h0};     // carry 通道 bit1 结构恒 0（低位进 0 的进位）
    must[5] = 72'h3F; must[6] = 72'h7F;
  end
  `define CMP(k, g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 30) $display("[%0d] MISMATCH %s golden=%h impl=%h", cyc, nm, (g), (i)); end \
      seen1[k] |= 72'(g); seen0[k] |= ~72'(g); end
  task automatic compare_all();
    `CMP(0, g_q0, i_q0, "io_nxt_quo_dig_o_0_0")
    `CMP(1, g_q1, i_q1, "io_nxt_quo_dig_o_0_1")
    `CMP(2, g_q2, i_q2, "io_nxt_quo_dig_o_0_2")
    `CMP(3, g_s, i_s, "io_nxt_f_r_s_o_2")
    `CMP(4, g_c, i_c, "io_nxt_f_r_c_o_2")
    `CMP(5, g_r6, i_r6, "io_adder_6b_res_for_nxt_cycle_s0_qds_o")
    `CMP(6, g_r7, i_r7, "io_adder_7b_res_for_nxt_cycle_s1_qds_o")
  endtask

  // ---- 独立 oracle O1：一拍的代数恒等式 ----
  function automatic int dig_val(input logic [4:0] d);
    case (d)
      5'b00001: return 2;      // digit[0] = +2（候选加 -2D）
      5'b00010: return 1;
      5'b00100: return 0;
      5'b01000: return -1;
      5'b10000: return -2;
      default:  return 99;
    endcase
  endfunction
  int cov_dig [3][5];
  int n_multihot;          // 随机拍里 qds 给出非 one-hot（余数片落在合法区间外，查表多命中）的拍数
  // strict=1：闭环里商位必须 one-hot；strict=0：随机拍若非 one-hot 则 Mux1H 相或，恒等式不适用，跳过
  task automatic oracle_step(input bit strict);
    logic [59:0] lhs, rhs, two_d;
    int v0, v1, v2, q3;
    v0 = dig_val(i_q0); v1 = dig_val(i_q1); v2 = dig_val(i_q2);
    if (!strict && (v0 == 99 || v1 == 99 || v2 == 99)) begin n_multihot++; return; end
    oracle_checks++;
    if (v0 == 99 || v1 == 99 || v2 == 99) begin
      oracle_err++;
      if (oracle_err <= 10) $display("[%0d] ORACLE O1 digit not one-hot %b %b %b", cyc, i_q0, i_q1, i_q2);
      return;
    end
    cov_dig[0][v0 + 2]++; cov_dig[1][v1 + 2]++; cov_dig[2][v2 + 2]++;
    q3    = 16 * v0 + 4 * v1 + v2;
    two_d = {2'b00, divisor_i[59:3], 1'b0};
    lhs   = i_s[71:12] + i_c[71:12];
    rhs   = 60'(64 * (f_r_s_i[71:12] + f_r_c_i[71:12])) - 60'(longint'(q3)) * two_d;
    if (lhs !== rhs) begin
      oracle_err++;
      if (oracle_err <= 10) $display("[%0d] ORACLE O1 lhs=%h rhs=%h q=%0d,%0d,%0d", cyc, lhs, rhs, v0, v1, v2);
    end
  endtask

  // ---- 激励形状 ----
  function automatic logic [71:0] shape72();
    logic [71:0] x;
    x = {$urandom, $urandom, $urandom};
    case ($urandom_range(0, 3))
      0: return x;
      1: return x & {$urandom, $urandom, $urandom};
      2: return x | {$urandom, $urandom, $urandom};
      default: return '0;
    endcase
  endfunction

  // 预缩放：除数尾数最高 3 位决定因子（÷8）：16/14/13/12/11/10/9/9，被除数同乘
  function automatic int scale_of(input logic [2:0] top3);
    case (top3)
      3'd0: return 16; 3'd1: return 14; 3'd2: return 13; 3'd3: return 12;
      3'd4: return 11; 3'd5: return 10; default: return 9;
    endcase
  endfunction
  function automatic logic [51:0] rand_frac();
    logic [51:0] f;
    f = {$urandom, $urandom};
    case ($urandom_range(0, 5))
      0: f = '1;
      1: f = '0;
      2: f = f & {$urandom, $urandom};
      default: ;
    endcase
    return f;
  endfunction

  int cov_scale [8], cov_shift [2], cov_rsign [2], n_div;
  task automatic closed_loop();
    logic [51:0]  a_frac, b_frac;
    logic [56:0]  a57, d57;
    logic [57:0]  pre;
    logic         lt, ipos2;
    logic [59:0]  s_lane, c_lane, two_d;
    logic signed [255:0] X, Qtot, R, lhs, rhs, quo_ref, rem_ref;
    int sc, v0, v1, v2;
    a_frac = rand_frac();
    b_frac = rand_frac();
    sc     = scale_of(b_frac[51:49]);
    a57    = 57'(({1'b1, a_frac} * sc));
    d57    = 57'(({1'b1, b_frac} * sc));
    lt     = a_frac < b_frac;
    pre    = lt ? {a57, 1'b0} : {1'b0, a57};
    ipos2  = pre[57] | (&pre[56:55]);
    s_lane = {1'b0, pre, 1'b1};
    c_lane = ipos2 ? {1'b1, ~d57, 2'b11} : {2'b11, ~d57, 1'b1};
    cov_scale[b_frac[51:49]]++; cov_shift[lt]++;
    X      = 256'(pre) * 2;
    Qtot   = ipos2 ? 2 : 1;
    two_d  = {2'b00, d57, 1'b0};
    f_r_s_i   = {s_lane, 12'h0};
    f_r_c_i   = {c_lane, 12'h0};
    divisor_i = {d57, 3'b000};
    rem6_i    = 6'(pre[56:51] + c_lane[57:52]);
    rem7_i    = 7'(pre[54:48] + c_lane[55:49]);
    for (int it = 0; it < 9; it++) begin
      #1;
      compare_all();
      oracle_step(1);
      v0 = dig_val(i_q0); v1 = dig_val(i_q1); v2 = dig_val(i_q2);
      Qtot = Qtot * 64 + 16 * v0 + 4 * v1 + v2;
      f_r_s_i = i_s; f_r_c_i = i_c; rem6_i = i_r6; rem7_i = i_r7;
      cyc++;
      #1;
    end
    // 终了：有符号余数 + 宽整数核对
    R   = 256'($signed(60'(f_r_s_i[71:12] + f_r_c_i[71:12])));
    lhs = Qtot * $signed({196'b0, two_d}) + R;
    rhs = X <<< 54;
    quo_ref = rhs / $signed({196'b0, two_d});
    rem_ref = rhs % $signed({196'b0, two_d});
    oracle_checks++; n_div++;
    cov_rsign[R < 0]++;
    if (lhs != rhs || R >= $signed({196'b0, two_d}) || -R >= $signed({196'b0, two_d}) ||
        (R >= 0 && Qtot != quo_ref) || (R < 0 && Qtot != quo_ref + 1)) begin
      oracle_err++;
      if (oracle_err <= 10)
        $display("[%0d] ORACLE O2 a=%h b=%h Q=%h ref=%h R=%0d", cyc, a_frac, b_frac, Qtot[127:0], quo_ref[127:0], R);
    end
  endtask

  initial begin
    int bad;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    cyc = 0;
    while (cyc < NCYCLES) begin
      if ($urandom_range(0, 1) == 0) begin
        f_r_s_i   = shape72();
        f_r_c_i   = shape72();
        divisor_i = 60'(shape72());
        if ($urandom_range(0, 3) == 0) divisor_i[59] = 1'b1;
        rem6_i = 6'($urandom);
        rem7_i = 7'($urandom);
        #1;
        compare_all();
        oracle_step(0);
        cyc++;
        #1;
      end else begin
        closed_loop();
      end
    end
    bad = 0;
    foreach (cov_dig[s, d]) begin
      $display("cov stage=%0d dig=%0d : %0d", s, d - 2, cov_dig[s][d]);
      if (cov_dig[s][d] < NCYCLES / 1000) bad++;
    end
    foreach (cov_scale[k]) begin
      $display("cov prescale top3=%0d : %0d", k, cov_scale[k]);
      if (cov_scale[k] < NCYCLES / 20000) bad++;
    end
    $display("cov shift(a>=b / a<b) : %0d / %0d ; final rem (>=0 / <0) : %0d / %0d ; closed-loop divisions %0d",
             cov_shift[0], cov_shift[1], cov_rsign[0], cov_rsign[1], n_div);
    foreach (cov_shift[k]) if (cov_shift[k] < NCYCLES / 2000) bad++;
    foreach (cov_rsign[k]) if (cov_rsign[k] < NCYCLES / 2000) bad++;
    for (int o = 0; o < N_OUT; o++)
      if (((seen0[o] & must[o]) != must[o]) || ((seen1[o] & must[o]) != must[o])) begin
        bad++; $display("output %0d not toggled: seen0=%h seen1=%h", o, seen0[o], seen1[o]);
      end
    $display("random-mode multi-hot digit cycles (O1 skipped): %0d", n_multihot);
    $display("checks=%0d errors=%0d oracle_checks=%0d oracle_err=%0d bad_cov=%0d",
             checks, errors, oracle_checks, oracle_err, bad);
    if (errors == 0 && oracle_err == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
