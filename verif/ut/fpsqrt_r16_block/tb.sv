// =============================================================================
// tb —— fpsqrt_r16_block UT：golden fpsqrt_r16_block（读 golden r4_qds*）与重写件 fpsqrt_r16_block_xs
// （读重写 r4_qds*_xs）双例化，同输入逐次比全部 28 个输出口；另带**独立 oracle**。
//
// 两种激励交替（每"拍"= 喂一次组合输入、#1 后比较）：
//   (R) 全随机：fp_fmt_i 3 位任意（含非 one-hot / 全 0）、其余输入全随机 —— 只做差分比较。
//   (L) 闭环开方：按格式（f16 ×4 / f32 ×2 / f64 ×1 元素）为每个元素造一个被开方数 X ∈ [1,4)，
//       按 yunsuan fpu/fqrt/fpsqrt_r16.scala 的初始化公式（首位根 rt_1st、f_r_s = X·4、f_r_c = -rt_1st²、
//       QDS 的 7/9 位初值、r4_qds_cg 比较常数）装初态，然后把重写件的输出原样喂回输入迭代
//       f16 3 次 / f32 6 次 / f64 13 次（mask 每次右移一位）。每次迭代照样做差分比较。
//       迭代完逐元素做 oracle：
//         R = isqrt(X_int · 2^(F+1))（tb 里逐位恢复法求整数平方根，与被测件无关），
//         余数 w = f_r_s + f_r_c（元素宽 W 位回绕），w < 0 时结果取 QM，否则取 Q，必须 == R；
//         且 w == 0 当且仅当 R² == X_int · 2^(F+1)（是否恰为完全平方）。
//       被开方数形状：随机尾数 / 全 1 / 全 0 / 完全平方（根只有少数有效位）。
// 覆盖（写进 PASS 判据）：三格式闭环各 >= 500 次、oracle 中"结果取 QM"与"取 Q"各 >= 200、恰为完全平方 >= 100；
//   s0 / s1 的 5 个数位在重写件 lane0..3 上各出现过；28 个输出逐位翻转过（在 (R) 激励下；结构恒定位除外：
//   nxt_f_r_c_o[1]，以及 m_*_to_nxt_cycle 在 r4_qds_cg 查表里恒定的位）。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0;
  int cyc;

  // ---- 输入（与 golden 端口同名，两个实例用 .* 接）----
  logic [2:0]  fp_fmt_i;
  logic [63:0] f_r_s_i, f_r_c_i;
  logic [55:0] rt_i;
  logic [52:0] rt_m1_i;
  logic [12:0] mask_i;
  logic [6:0]  est7 [4];
  logic [8:0]  est9 [4];
  logic [4:0]  mn1 [4];
  logic [3:0]  mn0 [4];
  logic [2:0]  mp1 [4];
  logic [3:0]  mp2 [4];
  logic [6:0] nr_f_r_7b_for_nxt_cycle_s0_qds_0_i, nr_f_r_7b_for_nxt_cycle_s0_qds_1_i,
              nr_f_r_7b_for_nxt_cycle_s0_qds_2_i, nr_f_r_7b_for_nxt_cycle_s0_qds_3_i;
  logic [8:0] nr_f_r_9b_for_nxt_cycle_s1_qds_0_i, nr_f_r_9b_for_nxt_cycle_s1_qds_1_i,
              nr_f_r_9b_for_nxt_cycle_s1_qds_2_i, nr_f_r_9b_for_nxt_cycle_s1_qds_3_i;
  logic [4:0] m_neg_1_for_nxt_cycle_s0_qds_0_i, m_neg_1_for_nxt_cycle_s0_qds_1_i,
              m_neg_1_for_nxt_cycle_s0_qds_2_i, m_neg_1_for_nxt_cycle_s0_qds_3_i;
  logic [3:0] m_neg_0_for_nxt_cycle_s0_qds_0_i, m_neg_0_for_nxt_cycle_s0_qds_1_i,
              m_neg_0_for_nxt_cycle_s0_qds_2_i, m_neg_0_for_nxt_cycle_s0_qds_3_i;
  logic [2:0] m_pos_1_for_nxt_cycle_s0_qds_0_i, m_pos_1_for_nxt_cycle_s0_qds_1_i,
              m_pos_1_for_nxt_cycle_s0_qds_2_i, m_pos_1_for_nxt_cycle_s0_qds_3_i;
  logic [3:0] m_pos_2_for_nxt_cycle_s0_qds_0_i, m_pos_2_for_nxt_cycle_s0_qds_1_i,
              m_pos_2_for_nxt_cycle_s0_qds_2_i, m_pos_2_for_nxt_cycle_s0_qds_3_i;
  assign {nr_f_r_7b_for_nxt_cycle_s0_qds_3_i, nr_f_r_7b_for_nxt_cycle_s0_qds_2_i,
          nr_f_r_7b_for_nxt_cycle_s0_qds_1_i, nr_f_r_7b_for_nxt_cycle_s0_qds_0_i} = {est7[3], est7[2], est7[1], est7[0]};
  assign {nr_f_r_9b_for_nxt_cycle_s1_qds_3_i, nr_f_r_9b_for_nxt_cycle_s1_qds_2_i,
          nr_f_r_9b_for_nxt_cycle_s1_qds_1_i, nr_f_r_9b_for_nxt_cycle_s1_qds_0_i} = {est9[3], est9[2], est9[1], est9[0]};
  assign {m_neg_1_for_nxt_cycle_s0_qds_3_i, m_neg_1_for_nxt_cycle_s0_qds_2_i,
          m_neg_1_for_nxt_cycle_s0_qds_1_i, m_neg_1_for_nxt_cycle_s0_qds_0_i} = {mn1[3], mn1[2], mn1[1], mn1[0]};
  assign {m_neg_0_for_nxt_cycle_s0_qds_3_i, m_neg_0_for_nxt_cycle_s0_qds_2_i,
          m_neg_0_for_nxt_cycle_s0_qds_1_i, m_neg_0_for_nxt_cycle_s0_qds_0_i} = {mn0[3], mn0[2], mn0[1], mn0[0]};
  assign {m_pos_1_for_nxt_cycle_s0_qds_3_i, m_pos_1_for_nxt_cycle_s0_qds_2_i,
          m_pos_1_for_nxt_cycle_s0_qds_1_i, m_pos_1_for_nxt_cycle_s0_qds_0_i} = {mp1[3], mp1[2], mp1[1], mp1[0]};
  assign {m_pos_2_for_nxt_cycle_s0_qds_3_i, m_pos_2_for_nxt_cycle_s0_qds_2_i,
          m_pos_2_for_nxt_cycle_s0_qds_1_i, m_pos_2_for_nxt_cycle_s0_qds_0_i} = {mp2[3], mp2[2], mp2[1], mp2[0]};

  // ---- 两个实例：g_dut[0] = golden，g_dut[1] = 重写件；输出在各自 generate 作用域里同名声明 ----
  for (genvar d = 0; d < 2; d++) begin : g_dut
    logic [55:0] nxt_rt_o;
    logic [52:0] nxt_rt_m1_o;
    logic [63:0] nxt_f_r_s_o;
    logic [63:0] nxt_f_r_c_o;
    logic [6:0] adder_7b_res_for_nxt_cycle_s0_qds_0_o;
    logic [6:0] adder_7b_res_for_nxt_cycle_s0_qds_1_o;
    logic [6:0] adder_7b_res_for_nxt_cycle_s0_qds_2_o;
    logic [6:0] adder_7b_res_for_nxt_cycle_s0_qds_3_o;
    logic [8:0] adder_9b_res_for_nxt_cycle_s1_qds_0_o;
    logic [8:0] adder_9b_res_for_nxt_cycle_s1_qds_1_o;
    logic [8:0] adder_9b_res_for_nxt_cycle_s1_qds_2_o;
    logic [8:0] adder_9b_res_for_nxt_cycle_s1_qds_3_o;
    logic [6:0] m_neg_1_to_nxt_cycle_0_o;
    logic [6:0] m_neg_1_to_nxt_cycle_1_o;
    logic [6:0] m_neg_1_to_nxt_cycle_2_o;
    logic [6:0] m_neg_1_to_nxt_cycle_3_o;
    logic [6:0] m_neg_0_to_nxt_cycle_0_o;
    logic [6:0] m_neg_0_to_nxt_cycle_1_o;
    logic [6:0] m_neg_0_to_nxt_cycle_2_o;
    logic [6:0] m_neg_0_to_nxt_cycle_3_o;
    logic [6:0] m_pos_1_to_nxt_cycle_0_o;
    logic [6:0] m_pos_1_to_nxt_cycle_1_o;
    logic [6:0] m_pos_1_to_nxt_cycle_2_o;
    logic [6:0] m_pos_1_to_nxt_cycle_3_o;
    logic [6:0] m_pos_2_to_nxt_cycle_0_o;
    logic [6:0] m_pos_2_to_nxt_cycle_1_o;
    logic [6:0] m_pos_2_to_nxt_cycle_2_o;
    logic [6:0] m_pos_2_to_nxt_cycle_3_o;
    if (d == 0) begin : g_gold
      fpsqrt_r16_block u (.*);
    end else begin : g_impl
      fpsqrt_r16_block_xs u (.*);
    end
  end

  // ---- 差分比较 + 逐位翻转覆盖 ----
  localparam int N_OUT = 28;
  logic [63:0] seen0 [N_OUT], seen1 [N_OUT], width_mask [N_OUT], must1 [N_OUT], must0 [N_OUT];
  bit cov_toggle_on = 0;          // 只在 (R) 激励下记翻转
  `define CMP(k, g, i, w, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 30) $display("[%0d] MISMATCH %s golden=%h impl=%h", cyc, nm, (g), (i)); end \
      width_mask[k] = (w == 64) ? '1 : ((64'd1 << (w)) - 1); \
      if (cov_toggle_on) begin seen1[k] |= 64'(g); seen0[k] |= ~64'(g) & width_mask[k]; end end
  task automatic compare_all();
    `CMP(0, g_dut[0].nxt_rt_o, g_dut[1].nxt_rt_o, 56, "nxt_rt_o")
    `CMP(1, g_dut[0].nxt_rt_m1_o, g_dut[1].nxt_rt_m1_o, 53, "nxt_rt_m1_o")
    `CMP(2, g_dut[0].nxt_f_r_s_o, g_dut[1].nxt_f_r_s_o, 64, "nxt_f_r_s_o")
    `CMP(3, g_dut[0].nxt_f_r_c_o, g_dut[1].nxt_f_r_c_o, 64, "nxt_f_r_c_o")
    `CMP(4, g_dut[0].adder_7b_res_for_nxt_cycle_s0_qds_0_o, g_dut[1].adder_7b_res_for_nxt_cycle_s0_qds_0_o, 7, "adder_7b_res_for_nxt_cycle_s0_qds_0_o")
    `CMP(5, g_dut[0].adder_7b_res_for_nxt_cycle_s0_qds_1_o, g_dut[1].adder_7b_res_for_nxt_cycle_s0_qds_1_o, 7, "adder_7b_res_for_nxt_cycle_s0_qds_1_o")
    `CMP(6, g_dut[0].adder_7b_res_for_nxt_cycle_s0_qds_2_o, g_dut[1].adder_7b_res_for_nxt_cycle_s0_qds_2_o, 7, "adder_7b_res_for_nxt_cycle_s0_qds_2_o")
    `CMP(7, g_dut[0].adder_7b_res_for_nxt_cycle_s0_qds_3_o, g_dut[1].adder_7b_res_for_nxt_cycle_s0_qds_3_o, 7, "adder_7b_res_for_nxt_cycle_s0_qds_3_o")
    `CMP(8, g_dut[0].adder_9b_res_for_nxt_cycle_s1_qds_0_o, g_dut[1].adder_9b_res_for_nxt_cycle_s1_qds_0_o, 9, "adder_9b_res_for_nxt_cycle_s1_qds_0_o")
    `CMP(9, g_dut[0].adder_9b_res_for_nxt_cycle_s1_qds_1_o, g_dut[1].adder_9b_res_for_nxt_cycle_s1_qds_1_o, 9, "adder_9b_res_for_nxt_cycle_s1_qds_1_o")
    `CMP(10, g_dut[0].adder_9b_res_for_nxt_cycle_s1_qds_2_o, g_dut[1].adder_9b_res_for_nxt_cycle_s1_qds_2_o, 9, "adder_9b_res_for_nxt_cycle_s1_qds_2_o")
    `CMP(11, g_dut[0].adder_9b_res_for_nxt_cycle_s1_qds_3_o, g_dut[1].adder_9b_res_for_nxt_cycle_s1_qds_3_o, 9, "adder_9b_res_for_nxt_cycle_s1_qds_3_o")
    `CMP(12, g_dut[0].m_neg_1_to_nxt_cycle_0_o, g_dut[1].m_neg_1_to_nxt_cycle_0_o, 7, "m_neg_1_to_nxt_cycle_0_o")
    `CMP(13, g_dut[0].m_neg_1_to_nxt_cycle_1_o, g_dut[1].m_neg_1_to_nxt_cycle_1_o, 7, "m_neg_1_to_nxt_cycle_1_o")
    `CMP(14, g_dut[0].m_neg_1_to_nxt_cycle_2_o, g_dut[1].m_neg_1_to_nxt_cycle_2_o, 7, "m_neg_1_to_nxt_cycle_2_o")
    `CMP(15, g_dut[0].m_neg_1_to_nxt_cycle_3_o, g_dut[1].m_neg_1_to_nxt_cycle_3_o, 7, "m_neg_1_to_nxt_cycle_3_o")
    `CMP(16, g_dut[0].m_neg_0_to_nxt_cycle_0_o, g_dut[1].m_neg_0_to_nxt_cycle_0_o, 7, "m_neg_0_to_nxt_cycle_0_o")
    `CMP(17, g_dut[0].m_neg_0_to_nxt_cycle_1_o, g_dut[1].m_neg_0_to_nxt_cycle_1_o, 7, "m_neg_0_to_nxt_cycle_1_o")
    `CMP(18, g_dut[0].m_neg_0_to_nxt_cycle_2_o, g_dut[1].m_neg_0_to_nxt_cycle_2_o, 7, "m_neg_0_to_nxt_cycle_2_o")
    `CMP(19, g_dut[0].m_neg_0_to_nxt_cycle_3_o, g_dut[1].m_neg_0_to_nxt_cycle_3_o, 7, "m_neg_0_to_nxt_cycle_3_o")
    `CMP(20, g_dut[0].m_pos_1_to_nxt_cycle_0_o, g_dut[1].m_pos_1_to_nxt_cycle_0_o, 7, "m_pos_1_to_nxt_cycle_0_o")
    `CMP(21, g_dut[0].m_pos_1_to_nxt_cycle_1_o, g_dut[1].m_pos_1_to_nxt_cycle_1_o, 7, "m_pos_1_to_nxt_cycle_1_o")
    `CMP(22, g_dut[0].m_pos_1_to_nxt_cycle_2_o, g_dut[1].m_pos_1_to_nxt_cycle_2_o, 7, "m_pos_1_to_nxt_cycle_2_o")
    `CMP(23, g_dut[0].m_pos_1_to_nxt_cycle_3_o, g_dut[1].m_pos_1_to_nxt_cycle_3_o, 7, "m_pos_1_to_nxt_cycle_3_o")
    `CMP(24, g_dut[0].m_pos_2_to_nxt_cycle_0_o, g_dut[1].m_pos_2_to_nxt_cycle_0_o, 7, "m_pos_2_to_nxt_cycle_0_o")
    `CMP(25, g_dut[0].m_pos_2_to_nxt_cycle_1_o, g_dut[1].m_pos_2_to_nxt_cycle_1_o, 7, "m_pos_2_to_nxt_cycle_1_o")
    `CMP(26, g_dut[0].m_pos_2_to_nxt_cycle_2_o, g_dut[1].m_pos_2_to_nxt_cycle_2_o, 7, "m_pos_2_to_nxt_cycle_2_o")
    `CMP(27, g_dut[0].m_pos_2_to_nxt_cycle_3_o, g_dut[1].m_pos_2_to_nxt_cycle_3_o, 7, "m_pos_2_to_nxt_cycle_3_o")
  endtask

  // ---- r4_qds_cg 的查表（Scala vfsqrt/r4_qds.scala class r4_qds_cg 的表，tb 自带一份）----
  function automatic void cg(input logic a0, a2, a3, a4,
                             output logic [6:0] n1, n0, p1, p2);
    logic [6:0] T_N1 [8] = '{7'h0D, 7'h0E, 7'h10, 7'h11, 7'h12, 7'h14, 7'h16, 7'h17};
    logic [6:0] T_N0 [8] = '{7'h04, 7'h05, 7'h06, 7'h06, 7'h06, 7'h08, 7'h08, 7'h08};
    logic [6:0] T_P1 [8] = '{7'h7C, 7'h7C, 7'h7C, 7'h7C, 7'h7A, 7'h7A, 7'h78, 7'h78};
    logic [6:0] T_P2 [8] = '{7'h74, 7'h72, 7'h70, 7'h70, 7'h6E, 7'h6C, 7'h6C, 7'h6A};
    int row = a0 ? 7 : {a2, a3, a4};
    n1 = T_N1[row]; n0 = T_N0[row]; p1 = T_P1[row]; p2 = T_P2[row];
  endfunction

  // ---- 整数平方根：逐位恢复法（与被测件算法无关）----
  function automatic logic [127:0] isqrt(input logic [127:0] x);
    logic [127:0] r = 0, bitv = 128'd1 << 126, rem = x;
    while (bitv > rem) bitv >>= 2;
    while (bitv != 0) begin
      if (rem >= r + bitv) begin rem -= r + bitv; r = (r >> 1) + bitv; end
      else r >>= 1;
      bitv >>= 2;
    end
    return r;
  endfunction

  // ---- 元素布局（输入/输出同一布局）：W 余数宽、lane 号、余数 LSB、rt / rt_m1 字段最高位 ----
  typedef struct { int W; int lane; int rem_lsb; int rh; int mh; } elem_t;
  function automatic elem_t elem(input int fmt, input int e);
    elem_t x;
    case (fmt)
      0: case (e)   // f16：{lane0 高 16, lane2, lane1 高 16, lane3}
           0: x = '{16, 0, 48, 55, 52};
           1: x = '{16, 1, 16, 27, 26};
           2: x = '{16, 2, 32, 41, 39};
           default: x = '{16, 3, 0, 13, 13};
         endcase
      1: if (e == 0) x = '{28, 0, 36, 55, 52};
         else        x = '{28, 1, 4, 27, 26};
      default: x = '{56, 0, 8, 55, 52};
    endcase
    return x;
  endfunction
  function automatic int n_elem(input int fmt); return (fmt == 0) ? 4 : (fmt == 1) ? 2 : 1; endfunction
  function automatic int n_iter(input int fmt); return (fmt == 0) ? 3 : (fmt == 1) ? 6 : 13; endfunction
  function automatic longint unsigned lmask(input int w); return (w >= 64) ? '1 : ((64'd1 << w) - 1); endfunction

  // ---- 随机输入 ----
  task automatic rand_inputs();
    fp_fmt_i = 3'($urandom);
    f_r_s_i = {$urandom, $urandom}; f_r_c_i = {$urandom, $urandom};
    rt_i = 56'({$urandom, $urandom}); rt_m1_i = 53'({$urandom, $urandom});
    mask_i = ($urandom_range(0, 1)) ? 13'(1) << $urandom_range(0, 12) : 13'($urandom);
    for (int l = 0; l < 4; l++) begin
      est7[l] = 7'($urandom); est9[l] = 9'($urandom);
      mn1[l] = 5'($urandom); mn0[l] = 4'($urandom); mp1[l] = 3'($urandom); mp2[l] = 4'($urandom);
    end
  endtask

  // ---- 覆盖 ----
  int cov_loop [3];
  int cov_res_q, cov_res_qm, cov_exact;
  bit [4:0] seen_dig_s0 [4], seen_dig_s1 [4];
  task automatic sample_digits();
    seen_dig_s0[0] |= g_dut[1].g_impl.u.u_core.u_lane0.s0_digit;
    seen_dig_s0[1] |= g_dut[1].g_impl.u.u_core.u_lane1.s0_digit;
    seen_dig_s0[2] |= g_dut[1].g_impl.u.u_core.u_lane2.s0_digit;
    seen_dig_s0[3] |= g_dut[1].g_impl.u.u_core.u_lane3.s0_digit;
    seen_dig_s1[0] |= g_dut[1].g_impl.u.u_core.u_lane0.s1_digit;
    seen_dig_s1[1] |= g_dut[1].g_impl.u.u_core.u_lane1.s1_digit;
    seen_dig_s1[2] |= g_dut[1].g_impl.u.u_core.u_lane2.s1_digit;
    seen_dig_s1[3] |= g_dut[1].g_impl.u.u_core.u_lane3.s1_digit;
  endtask

  task automatic step_compare();
    #1;
    compare_all();
    cyc++;
    #1;
  endtask

  // ---- (L) 闭环开方一次 ----
  task automatic sqrt_loop();
    int fmt = $urandom_range(0, 2);
    int ne = n_elem(fmt);
    longint unsigned xint [4];
    fp_fmt_i = 3'b001 << fmt;
    f_r_s_i = 0; f_r_c_i = 0; rt_i = 0; rt_m1_i = 0; mask_i = 13'h1000;
    // 不用的 lane 的 QDS 输入随机（输出按格式门控，不应受影响）
    for (int l = 0; l < 4; l++) begin
      est7[l] = 7'($urandom); est9[l] = 9'($urandom);
      mn1[l] = 5'($urandom); mn0[l] = 4'($urandom); mp1[l] = 3'($urandom); mp2[l] = 4'($urandom);
    end
    for (int e = 0; e < ne; e++) begin
      elem_t x = elem(fmt, e);
      int W = x.W, RW = x.W - 1, F = x.W - 3;
      longint unsigned frac, s, c, q0, qm0, X;
      bit odd;
      int rt1;
      logic [6:0] n1, n0, p1, p2;
      // 被开方数形状
      odd = $urandom;
      frac = {$urandom, $urandom} & lmask(F - 1);
      case ($urandom_range(0, 7))
        0: frac = lmask(F - 1);
        1: frac = 0;
        2, 3: begin   // 完全平方：根 Y 只有 h 位有效位，X_int = Y² << (F+1-2h)
          int h = $urandom_range(2, (F + 1) / 2 - 1);
          longint unsigned Y = (64'd1 << (h - 1)) | ({$urandom, $urandom} & lmask(h - 1));
          longint unsigned XX = (Y * Y) << (F + 1 - 2 * h);
          odd  = XX[F];
          frac = odd ? ((XX >> 1) & lmask(F - 1)) : (XX & lmask(F - 1));
        end
        default: ;
      endcase
      X = odd ? ((64'd1 << F) | (frac << 1)) : ((64'd1 << (F - 1)) | frac);
      xint[e] = X;
      rt1 = (odd == 0 && frac[F - 2] == 0) ? 0 : (odd == 1 && frac[F - 2] == 1) ? 2 : 1;
      q0  = (rt1 == 0) ? (64'b010 << (RW - 3)) : (rt1 == 1) ? (64'b011 << (RW - 3)) : (64'b100 << (RW - 3));
      qm0 = (rt1 == 0) ? (64'b001 << (RW - 3)) : (rt1 == 1) ? (64'b010 << (RW - 3)) : (64'b011 << (RW - 3));
      s   = (X << 2) & lmask(W);
      c   = (rt1 == 0) ? (64'd3 << (W - 2)) : (rt1 == 1) ? (64'd7 << (W - 4)) : 64'd0;
      for (int b = 0; b < W; b++) begin f_r_s_i[x.rem_lsb + b] = s[b]; f_r_c_i[x.rem_lsb + b] = c[b]; end
      for (int b = 0; b < RW - 1; b++) rt_i[x.rh - b] = q0[RW - 2 - b];
      for (int b = 0; b < RW - 2; b++) rt_m1_i[x.mh - b] = qm0[RW - 3 - b];
      // QDS 初值：s0 用 {s+c 的高 4 位, s 的次 4 位} 取高 7 位；s1 用 {s+c 的 [W-3:W-4], s 的 [W-5:W-11]}
      est7[x.lane] = 7'({4'(s[W-1 -: 4] + c[W-1 -: 4]), 4'(s[W-5 -: 4])} >> 1);
      est9[x.lane] = {2'(s[W-3 -: 2] + c[W-3 -: 2]), 7'(s[W-5 -: 7])};
      cg(q0[RW - 1], q0[RW - 3], q0[RW - 4], q0[RW - 5], n1, n0, p1, p2);
      mn1[x.lane] = n1[4:0]; mn0[x.lane] = n0[3:0]; mp1[x.lane] = p1[2:0]; mp2[x.lane] = p2[4:1];
    end
    // 迭代：重写件的输出原样喂回
    for (int it = 0; it < n_iter(fmt); it++) begin
      step_compare();
      sample_digits();
      f_r_s_i = g_dut[1].nxt_f_r_s_o;
      f_r_c_i = g_dut[1].nxt_f_r_c_o;
      rt_i    = g_dut[1].nxt_rt_o;
      rt_m1_i = g_dut[1].nxt_rt_m1_o;
      mask_i  = mask_i >> 1;
      est7 = '{g_dut[1].adder_7b_res_for_nxt_cycle_s0_qds_0_o, g_dut[1].adder_7b_res_for_nxt_cycle_s0_qds_1_o,
               g_dut[1].adder_7b_res_for_nxt_cycle_s0_qds_2_o, g_dut[1].adder_7b_res_for_nxt_cycle_s0_qds_3_o};
      est9 = '{g_dut[1].adder_9b_res_for_nxt_cycle_s1_qds_0_o, g_dut[1].adder_9b_res_for_nxt_cycle_s1_qds_1_o,
               g_dut[1].adder_9b_res_for_nxt_cycle_s1_qds_2_o, g_dut[1].adder_9b_res_for_nxt_cycle_s1_qds_3_o};
      mn1 = '{g_dut[1].m_neg_1_to_nxt_cycle_0_o[4:0], g_dut[1].m_neg_1_to_nxt_cycle_1_o[4:0],
              g_dut[1].m_neg_1_to_nxt_cycle_2_o[4:0], g_dut[1].m_neg_1_to_nxt_cycle_3_o[4:0]};
      mn0 = '{g_dut[1].m_neg_0_to_nxt_cycle_0_o[3:0], g_dut[1].m_neg_0_to_nxt_cycle_1_o[3:0],
              g_dut[1].m_neg_0_to_nxt_cycle_2_o[3:0], g_dut[1].m_neg_0_to_nxt_cycle_3_o[3:0]};
      mp1 = '{g_dut[1].m_pos_1_to_nxt_cycle_0_o[2:0], g_dut[1].m_pos_1_to_nxt_cycle_1_o[2:0],
              g_dut[1].m_pos_1_to_nxt_cycle_2_o[2:0], g_dut[1].m_pos_1_to_nxt_cycle_3_o[2:0]};
      mp2 = '{g_dut[1].m_pos_2_to_nxt_cycle_0_o[4:1], g_dut[1].m_pos_2_to_nxt_cycle_1_o[4:1],
              g_dut[1].m_pos_2_to_nxt_cycle_2_o[4:1], g_dut[1].m_pos_2_to_nxt_cycle_3_o[4:1]};
    end
    // oracle：逐元素对整数平方根
    cov_loop[fmt]++;
    for (int e = 0; e < ne; e++) begin
      elem_t x = elem(fmt, e);
      int W = x.W, RW = x.W - 1, F = x.W - 3;
      longint unsigned s = 0, c = 0, w, q = 0, qm = 0, got;
      logic [127:0] rad, R;
      bit neg, exact_hw, exact_ref;
      for (int b = 0; b < W; b++) begin s[b] = f_r_s_i[x.rem_lsb + b]; c[b] = f_r_c_i[x.rem_lsb + b]; end
      w = (s + c) & lmask(W);
      neg = w[W - 1];
      for (int b = 0; b < RW - 1; b++) q[RW - 2 - b] = rt_i[x.rh - b];
      q[RW - 1] = ~rt_i[x.rh];
      for (int b = 0; b < RW - 2; b++) qm[RW - 3 - b] = rt_m1_i[x.mh - b];
      qm[RW - 2] = 1'b1;
      got = neg ? qm : q;
      rad = 128'(xint[e]) << (F + 1);
      R = isqrt(rad);
      exact_ref = (R * R == rad);
      exact_hw  = (w == 0);
      checks++;
      if (128'(got) != R || exact_hw != exact_ref) begin
        errors++;
        if (errors <= 30)
          $display("[%0d] ORACLE fmt=%0d e=%0d X=%h got=%h (neg=%0d q=%h qm=%h w=%h) ref=%h exact hw/ref=%0d/%0d",
                   cyc, fmt, e, xint[e], got, neg, q, qm, w, R, exact_hw, exact_ref);
      end
      if (neg) cov_res_qm++; else cov_res_q++;
      if (exact_ref) cov_exact++;
    end
  endtask

  initial begin
    bit cov_ok = 1;
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (int k = 0; k < N_OUT; k++) begin seen0[k] = 0; seen1[k] = 0; width_mask[k] = 0; end
    cyc = 0;
    while (cyc < NCYCLES) begin
      if ($urandom_range(0, 1)) begin
        cov_toggle_on = 1;
        rand_inputs();
        step_compare();
        cov_toggle_on = 0;
      end else begin
        sqrt_loop();
      end
    end
    for (int f = 0; f < 3; f++) if (cov_loop[f] < 500) begin cov_ok = 0; $display("COV FAIL loops fmt%0d=%0d", f, cov_loop[f]); end
    if (cov_res_q < 200 || cov_res_qm < 200) begin cov_ok = 0; $display("COV FAIL result Q/QM = %0d/%0d", cov_res_q, cov_res_qm); end
    if (cov_exact < 100) begin cov_ok = 0; $display("COV FAIL exact=%0d", cov_exact); end
    for (int l = 0; l < 4; l++)
      if (seen_dig_s0[l] != 5'h1F || seen_dig_s1[l] != 5'h1F) begin
        cov_ok = 0; $display("COV FAIL lane%0d digits s0=%b s1=%b", l, seen_dig_s0[l], seen_dig_s1[l]);
      end
    // 结构恒定位不要求翻转：nxt_f_r_c_o[1] 恒 0（CSA 进位左移一位，而 ×4 后余数低两位为 0，
    // 进位的第 0 位 maj[0] 不可能为 1）；m_*_to_nxt_cycle 是 r4_qds_cg 的查表值，表内恒定的位按表算出。
    must1 = width_mask; must0 = width_mask;
    must1[3][1] = 1'b0;
    begin
      logic [6:0] n1, n0, p1, p2, or_n1 = 0, or_n0 = 0, or_p1 = 0, or_p2 = 0,
                  and_n1 = '1, and_n0 = '1, and_p1 = '1, and_p2 = '1;
      for (int r = 0; r < 8; r++) begin
        cg(1'b0, r[2], r[1], r[0], n1, n0, p1, p2);
        or_n1 |= n1; or_n0 |= n0; or_p1 |= p1; or_p2 |= p2;
        and_n1 &= n1; and_n0 &= n0; and_p1 &= p1; and_p2 &= p2;
      end
      for (int l = 0; l < 4; l++) begin
        must1[12 + l] = or_n1; must0[12 + l] = ~and_n1 & 7'h7F;
        must1[16 + l] = or_n0; must0[16 + l] = ~and_n0 & 7'h7F;
        must1[20 + l] = or_p1; must0[20 + l] = ~and_p1 & 7'h7F;
        must1[24 + l] = or_p2; must0[24 + l] = ~and_p2 & 7'h7F;
      end
    end
    for (int k = 0; k < N_OUT; k++)
      if ((seen1[k] & must1[k]) != must1[k] || (seen0[k] & must0[k]) != must0[k]) begin
        cov_ok = 0; $display("COV FAIL out%0d toggle 1=%h 0=%h", k, seen1[k], seen0[k]);
      end
    $display("COVERAGE loops f16/f32/f64=%0d/%0d/%0d result Q/QM=%0d/%0d exact=%0d", cov_loop[0], cov_loop[1], cov_loop[2],
             cov_res_q, cov_res_qm, cov_exact);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && cov_ok) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
