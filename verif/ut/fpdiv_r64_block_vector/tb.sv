// =============================================================================
// tb —— fpdiv_r64_block_vector UT：golden（含 golden CSA/qds 子树）与重写件 _xs（含重写子树）
// 双例化，同激励逐拍比全部 32 个输出。纯组合，每拍一组新输入。
//
// 激励：
//   fp_format_onehot 八成 one-hot（f64/f32/f16 轮换），一成全 0，一成任意 3 位（多热非法值，
//     golden 的 Mux1H 直接相或，照样有确定输出）；
//   余数 sum/carry、除数 四种形状轮换：全随机 / 稀疏 / 稠密 / 全 0；除数另有 1/8 为"规范"
//     （每通道最高位置 1，像真实的规格化尾数）；6/7 位余数片全随机（覆盖 qds 全表）。
// 覆盖（写进 PASS 判据）：格式 one-hot 三种 × 通道 0 的 s0/s1/s2 商位（5 值）共 45 格每格 >= 200；
//   多热/全 0 格式各 >= 200；每个输出位都见过 0 和 1。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0;
  int cyc;

  // ---- 以下声明/例化/比较由 golden 端口表机械展开（12 输入 / 22 输出）----
  logic [2:0] io_fp_format_onehot;
  logic [71:0] io_f_r_s_i;
  logic [71:0] io_f_r_c_i;
  logic [59:0] io_divisor_i;
  logic [5:0] io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_0;
  logic [5:0] io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_1;
  logic [5:0] io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_2;
  logic [5:0] io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_3;
  logic [6:0] io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_0;
  logic [6:0] io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_1;
  logic [6:0] io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_2;
  logic [6:0] io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_3;
  logic [4:0] g_io_nxt_quo_dig_o_0_0, i_io_nxt_quo_dig_o_0_0;
  logic [4:0] g_io_nxt_quo_dig_o_0_1, i_io_nxt_quo_dig_o_0_1;
  logic [4:0] g_io_nxt_quo_dig_o_0_2, i_io_nxt_quo_dig_o_0_2;
  logic [4:0] g_io_nxt_quo_dig_o_1_0, i_io_nxt_quo_dig_o_1_0;
  logic [4:0] g_io_nxt_quo_dig_o_1_1, i_io_nxt_quo_dig_o_1_1;
  logic [4:0] g_io_nxt_quo_dig_o_1_2, i_io_nxt_quo_dig_o_1_2;
  logic [4:0] g_io_nxt_quo_dig_o_2_0, i_io_nxt_quo_dig_o_2_0;
  logic [4:0] g_io_nxt_quo_dig_o_2_1, i_io_nxt_quo_dig_o_2_1;
  logic [4:0] g_io_nxt_quo_dig_o_2_2, i_io_nxt_quo_dig_o_2_2;
  logic [4:0] g_io_nxt_quo_dig_o_3_0, i_io_nxt_quo_dig_o_3_0;
  logic [4:0] g_io_nxt_quo_dig_o_3_1, i_io_nxt_quo_dig_o_3_1;
  logic [4:0] g_io_nxt_quo_dig_o_3_2, i_io_nxt_quo_dig_o_3_2;
  logic [71:0] g_io_nxt_f_r_s_o_2, i_io_nxt_f_r_s_o_2;
  logic [71:0] g_io_nxt_f_r_c_o_2, i_io_nxt_f_r_c_o_2;
  logic [5:0] g_io_adder_6b_res_for_nxt_cycle_s0_qds_o_0, i_io_adder_6b_res_for_nxt_cycle_s0_qds_o_0;
  logic [5:0] g_io_adder_6b_res_for_nxt_cycle_s0_qds_o_1, i_io_adder_6b_res_for_nxt_cycle_s0_qds_o_1;
  logic [5:0] g_io_adder_6b_res_for_nxt_cycle_s0_qds_o_2, i_io_adder_6b_res_for_nxt_cycle_s0_qds_o_2;
  logic [5:0] g_io_adder_6b_res_for_nxt_cycle_s0_qds_o_3, i_io_adder_6b_res_for_nxt_cycle_s0_qds_o_3;
  logic [6:0] g_io_adder_7b_res_for_nxt_cycle_s1_qds_o_0, i_io_adder_7b_res_for_nxt_cycle_s1_qds_o_0;
  logic [6:0] g_io_adder_7b_res_for_nxt_cycle_s1_qds_o_1, i_io_adder_7b_res_for_nxt_cycle_s1_qds_o_1;
  logic [6:0] g_io_adder_7b_res_for_nxt_cycle_s1_qds_o_2, i_io_adder_7b_res_for_nxt_cycle_s1_qds_o_2;
  logic [6:0] g_io_adder_7b_res_for_nxt_cycle_s1_qds_o_3, i_io_adder_7b_res_for_nxt_cycle_s1_qds_o_3;
  fpdiv_r64_block_vector u_g (
    .io_fp_format_onehot(io_fp_format_onehot),
    .io_f_r_s_i(io_f_r_s_i),
    .io_f_r_c_i(io_f_r_c_i),
    .io_divisor_i(io_divisor_i),
    .io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_0(io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_0),
    .io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_1(io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_1),
    .io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_2(io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_2),
    .io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_3(io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_3),
    .io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_0(io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_0),
    .io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_1(io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_1),
    .io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_2(io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_2),
    .io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_3(io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_3),
    .io_nxt_quo_dig_o_0_0(g_io_nxt_quo_dig_o_0_0),
    .io_nxt_quo_dig_o_0_1(g_io_nxt_quo_dig_o_0_1),
    .io_nxt_quo_dig_o_0_2(g_io_nxt_quo_dig_o_0_2),
    .io_nxt_quo_dig_o_1_0(g_io_nxt_quo_dig_o_1_0),
    .io_nxt_quo_dig_o_1_1(g_io_nxt_quo_dig_o_1_1),
    .io_nxt_quo_dig_o_1_2(g_io_nxt_quo_dig_o_1_2),
    .io_nxt_quo_dig_o_2_0(g_io_nxt_quo_dig_o_2_0),
    .io_nxt_quo_dig_o_2_1(g_io_nxt_quo_dig_o_2_1),
    .io_nxt_quo_dig_o_2_2(g_io_nxt_quo_dig_o_2_2),
    .io_nxt_quo_dig_o_3_0(g_io_nxt_quo_dig_o_3_0),
    .io_nxt_quo_dig_o_3_1(g_io_nxt_quo_dig_o_3_1),
    .io_nxt_quo_dig_o_3_2(g_io_nxt_quo_dig_o_3_2),
    .io_nxt_f_r_s_o_2(g_io_nxt_f_r_s_o_2),
    .io_nxt_f_r_c_o_2(g_io_nxt_f_r_c_o_2),
    .io_adder_6b_res_for_nxt_cycle_s0_qds_o_0(g_io_adder_6b_res_for_nxt_cycle_s0_qds_o_0),
    .io_adder_6b_res_for_nxt_cycle_s0_qds_o_1(g_io_adder_6b_res_for_nxt_cycle_s0_qds_o_1),
    .io_adder_6b_res_for_nxt_cycle_s0_qds_o_2(g_io_adder_6b_res_for_nxt_cycle_s0_qds_o_2),
    .io_adder_6b_res_for_nxt_cycle_s0_qds_o_3(g_io_adder_6b_res_for_nxt_cycle_s0_qds_o_3),
    .io_adder_7b_res_for_nxt_cycle_s1_qds_o_0(g_io_adder_7b_res_for_nxt_cycle_s1_qds_o_0),
    .io_adder_7b_res_for_nxt_cycle_s1_qds_o_1(g_io_adder_7b_res_for_nxt_cycle_s1_qds_o_1),
    .io_adder_7b_res_for_nxt_cycle_s1_qds_o_2(g_io_adder_7b_res_for_nxt_cycle_s1_qds_o_2),
    .io_adder_7b_res_for_nxt_cycle_s1_qds_o_3(g_io_adder_7b_res_for_nxt_cycle_s1_qds_o_3)
  );
  fpdiv_r64_block_vector_xs u_i (
    .io_fp_format_onehot(io_fp_format_onehot),
    .io_f_r_s_i(io_f_r_s_i),
    .io_f_r_c_i(io_f_r_c_i),
    .io_divisor_i(io_divisor_i),
    .io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_0(io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_0),
    .io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_1(io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_1),
    .io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_2(io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_2),
    .io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_3(io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_3),
    .io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_0(io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_0),
    .io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_1(io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_1),
    .io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_2(io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_2),
    .io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_3(io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_3),
    .io_nxt_quo_dig_o_0_0(i_io_nxt_quo_dig_o_0_0),
    .io_nxt_quo_dig_o_0_1(i_io_nxt_quo_dig_o_0_1),
    .io_nxt_quo_dig_o_0_2(i_io_nxt_quo_dig_o_0_2),
    .io_nxt_quo_dig_o_1_0(i_io_nxt_quo_dig_o_1_0),
    .io_nxt_quo_dig_o_1_1(i_io_nxt_quo_dig_o_1_1),
    .io_nxt_quo_dig_o_1_2(i_io_nxt_quo_dig_o_1_2),
    .io_nxt_quo_dig_o_2_0(i_io_nxt_quo_dig_o_2_0),
    .io_nxt_quo_dig_o_2_1(i_io_nxt_quo_dig_o_2_1),
    .io_nxt_quo_dig_o_2_2(i_io_nxt_quo_dig_o_2_2),
    .io_nxt_quo_dig_o_3_0(i_io_nxt_quo_dig_o_3_0),
    .io_nxt_quo_dig_o_3_1(i_io_nxt_quo_dig_o_3_1),
    .io_nxt_quo_dig_o_3_2(i_io_nxt_quo_dig_o_3_2),
    .io_nxt_f_r_s_o_2(i_io_nxt_f_r_s_o_2),
    .io_nxt_f_r_c_o_2(i_io_nxt_f_r_c_o_2),
    .io_adder_6b_res_for_nxt_cycle_s0_qds_o_0(i_io_adder_6b_res_for_nxt_cycle_s0_qds_o_0),
    .io_adder_6b_res_for_nxt_cycle_s0_qds_o_1(i_io_adder_6b_res_for_nxt_cycle_s0_qds_o_1),
    .io_adder_6b_res_for_nxt_cycle_s0_qds_o_2(i_io_adder_6b_res_for_nxt_cycle_s0_qds_o_2),
    .io_adder_6b_res_for_nxt_cycle_s0_qds_o_3(i_io_adder_6b_res_for_nxt_cycle_s0_qds_o_3),
    .io_adder_7b_res_for_nxt_cycle_s1_qds_o_0(i_io_adder_7b_res_for_nxt_cycle_s1_qds_o_0),
    .io_adder_7b_res_for_nxt_cycle_s1_qds_o_1(i_io_adder_7b_res_for_nxt_cycle_s1_qds_o_1),
    .io_adder_7b_res_for_nxt_cycle_s1_qds_o_2(i_io_adder_7b_res_for_nxt_cycle_s1_qds_o_2),
    .io_adder_7b_res_for_nxt_cycle_s1_qds_o_3(i_io_adder_7b_res_for_nxt_cycle_s1_qds_o_3)
  );
  localparam int N_OUT = 22;
  bit seen0 [N_OUT];  // 该输出出现过"某位为 0"
  bit seen1 [N_OUT];  // 该输出出现过"某位为 1"
  `define CMP(k, g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 30) $display("[%0d] MISMATCH %s golden=%h impl=%h", cyc, nm, (g), (i)); end \
      if (|(g)) seen1[k] = 1; if (!(&(g))) seen0[k] = 1; end
  task automatic compare_all();
    `CMP(0, g_io_nxt_quo_dig_o_0_0, i_io_nxt_quo_dig_o_0_0, "io_nxt_quo_dig_o_0_0")
    `CMP(1, g_io_nxt_quo_dig_o_0_1, i_io_nxt_quo_dig_o_0_1, "io_nxt_quo_dig_o_0_1")
    `CMP(2, g_io_nxt_quo_dig_o_0_2, i_io_nxt_quo_dig_o_0_2, "io_nxt_quo_dig_o_0_2")
    `CMP(3, g_io_nxt_quo_dig_o_1_0, i_io_nxt_quo_dig_o_1_0, "io_nxt_quo_dig_o_1_0")
    `CMP(4, g_io_nxt_quo_dig_o_1_1, i_io_nxt_quo_dig_o_1_1, "io_nxt_quo_dig_o_1_1")
    `CMP(5, g_io_nxt_quo_dig_o_1_2, i_io_nxt_quo_dig_o_1_2, "io_nxt_quo_dig_o_1_2")
    `CMP(6, g_io_nxt_quo_dig_o_2_0, i_io_nxt_quo_dig_o_2_0, "io_nxt_quo_dig_o_2_0")
    `CMP(7, g_io_nxt_quo_dig_o_2_1, i_io_nxt_quo_dig_o_2_1, "io_nxt_quo_dig_o_2_1")
    `CMP(8, g_io_nxt_quo_dig_o_2_2, i_io_nxt_quo_dig_o_2_2, "io_nxt_quo_dig_o_2_2")
    `CMP(9, g_io_nxt_quo_dig_o_3_0, i_io_nxt_quo_dig_o_3_0, "io_nxt_quo_dig_o_3_0")
    `CMP(10, g_io_nxt_quo_dig_o_3_1, i_io_nxt_quo_dig_o_3_1, "io_nxt_quo_dig_o_3_1")
    `CMP(11, g_io_nxt_quo_dig_o_3_2, i_io_nxt_quo_dig_o_3_2, "io_nxt_quo_dig_o_3_2")
    `CMP(12, g_io_nxt_f_r_s_o_2, i_io_nxt_f_r_s_o_2, "io_nxt_f_r_s_o_2")
    `CMP(13, g_io_nxt_f_r_c_o_2, i_io_nxt_f_r_c_o_2, "io_nxt_f_r_c_o_2")
    `CMP(14, g_io_adder_6b_res_for_nxt_cycle_s0_qds_o_0, i_io_adder_6b_res_for_nxt_cycle_s0_qds_o_0, "io_adder_6b_res_for_nxt_cycle_s0_qds_o_0")
    `CMP(15, g_io_adder_6b_res_for_nxt_cycle_s0_qds_o_1, i_io_adder_6b_res_for_nxt_cycle_s0_qds_o_1, "io_adder_6b_res_for_nxt_cycle_s0_qds_o_1")
    `CMP(16, g_io_adder_6b_res_for_nxt_cycle_s0_qds_o_2, i_io_adder_6b_res_for_nxt_cycle_s0_qds_o_2, "io_adder_6b_res_for_nxt_cycle_s0_qds_o_2")
    `CMP(17, g_io_adder_6b_res_for_nxt_cycle_s0_qds_o_3, i_io_adder_6b_res_for_nxt_cycle_s0_qds_o_3, "io_adder_6b_res_for_nxt_cycle_s0_qds_o_3")
    `CMP(18, g_io_adder_7b_res_for_nxt_cycle_s1_qds_o_0, i_io_adder_7b_res_for_nxt_cycle_s1_qds_o_0, "io_adder_7b_res_for_nxt_cycle_s1_qds_o_0")
    `CMP(19, g_io_adder_7b_res_for_nxt_cycle_s1_qds_o_1, i_io_adder_7b_res_for_nxt_cycle_s1_qds_o_1, "io_adder_7b_res_for_nxt_cycle_s1_qds_o_1")
    `CMP(20, g_io_adder_7b_res_for_nxt_cycle_s1_qds_o_2, i_io_adder_7b_res_for_nxt_cycle_s1_qds_o_2, "io_adder_7b_res_for_nxt_cycle_s1_qds_o_2")
    `CMP(21, g_io_adder_7b_res_for_nxt_cycle_s1_qds_o_3, i_io_adder_7b_res_for_nxt_cycle_s1_qds_o_3, "io_adder_7b_res_for_nxt_cycle_s1_qds_o_3")
  endtask
  task automatic rand_inputs();
    io_fp_format_onehot = 3'($urandom);
    io_f_r_s_i = 72'({$urandom, $urandom, $urandom});
    io_f_r_c_i = 72'({$urandom, $urandom, $urandom});
    io_divisor_i = 60'({$urandom, $urandom});
    io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_0 = 6'($urandom);
    io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_1 = 6'($urandom);
    io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_2 = 6'($urandom);
    io_nr_f_r_6b_for_nxt_cycle_s0_qds_i_3 = 6'($urandom);
    io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_0 = 7'($urandom);
    io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_1 = 7'($urandom);
    io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_2 = 7'($urandom);
    io_nr_f_r_7b_for_nxt_cycle_s1_qds_i_3 = 7'($urandom);
  endtask

  int cov_dig [3][3][5];   // [格式][级][商位]
  int cov_fmt_bad [2];     // 全 0 / 多热

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

  initial begin
    int bad, f;
    logic [2:0] fmt;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      rand_inputs();
      case ($urandom_range(0, 9))
        8: fmt = 3'b0;
        9: fmt = 3'($urandom);
        default: fmt = 3'b1 << $urandom_range(0, 2);
      endcase
      io_fp_format_onehot = fmt;
      io_f_r_s_i   = shape72();
      io_f_r_c_i   = shape72();
      io_divisor_i = 60'(shape72());
      if ($urandom_range(0, 7) == 0) begin   // 规格化尾数：各通道最高位置 1
        case (fmt)
          3'b100: io_divisor_i[59] = 1'b1;
          3'b010: begin io_divisor_i[29] = 1'b1; io_divisor_i[59] = 1'b1; end
          default: begin io_divisor_i[14] = 1'b1; io_divisor_i[29] = 1'b1; io_divisor_i[44] = 1'b1; io_divisor_i[59] = 1'b1; end
        endcase
      end
      #1;
      compare_all();
      if ($onehot(fmt)) begin
        f = fmt[2] ? 2 : fmt[1] ? 1 : 0;
        for (int q = 0; q < 5; q++) begin
          if (g_io_nxt_quo_dig_o_0_0[q]) cov_dig[f][0][q]++;
          if (g_io_nxt_quo_dig_o_0_1[q]) cov_dig[f][1][q]++;
          if (g_io_nxt_quo_dig_o_0_2[q]) cov_dig[f][2][q]++;
        end
      end else cov_fmt_bad[fmt != 0]++;
      #1;
    end
    bad = 0;
    foreach (cov_dig[a, b, c]) begin
      $display("cov fmt=%0d stage=%0d dig=%0d : %0d", a, b, c, cov_dig[a][b][c]);
      if (cov_dig[a][b][c] < NCYCLES / 1000) bad++;
    end
    $display("cov fmt zero/multihot : %0d / %0d", cov_fmt_bad[0], cov_fmt_bad[1]);
    foreach (cov_fmt_bad[a]) if (cov_fmt_bad[a] < NCYCLES / 1000) bad++;
    for (int o = 0; o < N_OUT; o++) if (!seen0[o] || !seen1[o]) begin bad++; $display("output %0d stuck", o); end
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
