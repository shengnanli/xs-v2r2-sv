`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0;
  int vectors = 0;

  // ---------------- r4_qds ----------------
  logic [6:0] qds_rem, qds_mn1, qds_mn0, qds_mp1, qds_mp2;
  wire  [4:0] qds_g, qds_i;
  r4_qds g_qds (
    .rem_i(qds_rem), .m_neg_1_i(qds_mn1), .m_neg_0_i(qds_mn0),
    .m_pos_1_i(qds_mp1), .m_pos_2_i(qds_mp2), .rt_dig_o(qds_g)
  );
  r4_qds_xs i_qds (
    .rem_i(qds_rem), .m_neg_1_i(qds_mn1), .m_neg_0_i(qds_mn0),
    .m_pos_1_i(qds_mp1), .m_pos_2_i(qds_mp2), .rt_dig_o(qds_i)
  );

  // ---------------- r4_qds_v2 ----------------
  logic [5:0] qv2_rem;
  wire  [4:0] qv2_g, qv2_i;
  r4_qds_v2    g_qv2 (.io_rem_i(qv2_rem), .io_quo_dig_o(qv2_g));
  r4_qds_v2_xs i_qv2 (.io_rem_i(qv2_rem), .io_quo_dig_o(qv2_i));

  // ---------------- r4_qds_spec ----------------
  // qs_m 组序 prev={neg_2,neg_1,neg_0,pos_1,pos_2}，组内 {neg_1,neg_0,pos_1,pos_2}
  logic [8:0] qs_rem, qs_csa_n2, qs_csa_n1, qs_csa_p1, qs_csa_p2;
  logic [6:0] qs_m [0:19];
  logic [4:0] qs_prev;
  wire  [4:0] qs_g, qs_i;
  r4_qds_spec g_qs (
    .rem_i(qs_rem),
    .sqrt_csa_val_neg_2_msbs_i(qs_csa_n2), .sqrt_csa_val_neg_1_msbs_i(qs_csa_n1),
    .sqrt_csa_val_pos_1_msbs_i(qs_csa_p1), .sqrt_csa_val_pos_2_msbs_i(qs_csa_p2),
    .m_neg_1_neg_2_i(qs_m[0]),  .m_neg_0_neg_2_i(qs_m[1]),
    .m_pos_1_neg_2_i(qs_m[2]),  .m_pos_2_neg_2_i(qs_m[3]),
    .m_neg_1_neg_1_i(qs_m[4]),  .m_neg_0_neg_1_i(qs_m[5]),
    .m_pos_1_neg_1_i(qs_m[6]),  .m_pos_2_neg_1_i(qs_m[7]),
    .m_neg_1_neg_0_i(qs_m[8]),  .m_neg_0_neg_0_i(qs_m[9]),
    .m_pos_1_neg_0_i(qs_m[10]), .m_pos_2_neg_0_i(qs_m[11]),
    .m_neg_1_pos_1_i(qs_m[12]), .m_neg_0_pos_1_i(qs_m[13]),
    .m_pos_1_pos_1_i(qs_m[14]), .m_pos_2_pos_1_i(qs_m[15]),
    .m_neg_1_pos_2_i(qs_m[16]), .m_neg_0_pos_2_i(qs_m[17]),
    .m_pos_1_pos_2_i(qs_m[18]), .m_pos_2_pos_2_i(qs_m[19]),
    .prev_rt_dig_i(qs_prev), .rt_dig_o(qs_g)
  );
  r4_qds_spec_xs i_qs (
    .rem_i(qs_rem),
    .sqrt_csa_val_neg_2_msbs_i(qs_csa_n2), .sqrt_csa_val_neg_1_msbs_i(qs_csa_n1),
    .sqrt_csa_val_pos_1_msbs_i(qs_csa_p1), .sqrt_csa_val_pos_2_msbs_i(qs_csa_p2),
    .m_neg_1_neg_2_i(qs_m[0]),  .m_neg_0_neg_2_i(qs_m[1]),
    .m_pos_1_neg_2_i(qs_m[2]),  .m_pos_2_neg_2_i(qs_m[3]),
    .m_neg_1_neg_1_i(qs_m[4]),  .m_neg_0_neg_1_i(qs_m[5]),
    .m_pos_1_neg_1_i(qs_m[6]),  .m_pos_2_neg_1_i(qs_m[7]),
    .m_neg_1_neg_0_i(qs_m[8]),  .m_neg_0_neg_0_i(qs_m[9]),
    .m_pos_1_neg_0_i(qs_m[10]), .m_pos_2_neg_0_i(qs_m[11]),
    .m_neg_1_pos_1_i(qs_m[12]), .m_neg_0_pos_1_i(qs_m[13]),
    .m_pos_1_pos_1_i(qs_m[14]), .m_pos_2_pos_1_i(qs_m[15]),
    .m_neg_1_pos_2_i(qs_m[16]), .m_neg_0_pos_2_i(qs_m[17]),
    .m_pos_1_pos_2_i(qs_m[18]), .m_pos_2_pos_2_i(qs_m[19]),
    .prev_rt_dig_i(qs_prev), .rt_dig_o(qs_i)
  );

  // ---------------- r4_qds_v2_spec ----------------
  logic [6:0] qvs_rem, qvs_dmul_p2, qvs_dmul_p1, qvs_dmul_n1, qvs_dmul_n2;
  logic [4:0] qvs_prev;
  wire  [4:0] qvs_g, qvs_i;
  r4_qds_v2_spec g_qvs (
    .io_rem_i(qvs_rem),
    .io_divisor_mul_pos_2_i(qvs_dmul_p2), .io_divisor_mul_pos_1_i(qvs_dmul_p1),
    .io_divisor_mul_neg_1_i(qvs_dmul_n1), .io_divisor_mul_neg_2_i(qvs_dmul_n2),
    .io_prev_quo_dig_i(qvs_prev), .io_quo_dig_o(qvs_g)
  );
  r4_qds_v2_spec_xs i_qvs (
    .io_rem_i(qvs_rem),
    .io_divisor_mul_pos_2_i(qvs_dmul_p2), .io_divisor_mul_pos_1_i(qvs_dmul_p1),
    .io_divisor_mul_neg_1_i(qvs_dmul_n1), .io_divisor_mul_neg_2_i(qvs_dmul_n2),
    .io_prev_quo_dig_i(qvs_prev), .io_quo_dig_o(qvs_i)
  );

  // ---------------- r4_qds_cg ----------------
  logic cg_a0, cg_a2, cg_a3, cg_a4;
  wire [6:0] cg_n1_g, cg_n0_g, cg_p1_g, cg_p2_g;
  wire [6:0] cg_n1_i, cg_n0_i, cg_p1_i, cg_p2_i;
  r4_qds_cg g_cg (
    .a0_i(cg_a0), .a2_i(cg_a2), .a3_i(cg_a3), .a4_i(cg_a4),
    .m_neg_1_o(cg_n1_g), .m_neg_0_o(cg_n0_g),
    .m_pos_1_o(cg_p1_g), .m_pos_2_o(cg_p2_g)
  );
  r4_qds_cg_xs i_cg (
    .a0_i(cg_a0), .a2_i(cg_a2), .a3_i(cg_a3), .a4_i(cg_a4),
    .m_neg_1_o(cg_n1_i), .m_neg_0_o(cg_n0_i),
    .m_pos_1_o(cg_p1_i), .m_pos_2_o(cg_p2_i)
  );

  // ---------------- SRT4qdsCons ----------------
  logic [2:0] cons_idx;
  wire [8:0] cons_n1_g, cons_n0_g, cons_p1_g, cons_p2_g;
  wire [8:0] cons_n1_i, cons_n0_i, cons_p1_i, cons_p2_i;
  SRT4qdsCons g_cons (
    .io_d_trunc_3(cons_idx),
    .io_m_neg_1(cons_n1_g), .io_m_neg_0(cons_n0_g),
    .io_m_pos_1(cons_p1_g), .io_m_pos_2(cons_p2_g)
  );
  SRT4qdsCons_xs i_cons (
    .io_d_trunc_3(cons_idx),
    .io_m_neg_1(cons_n1_i), .io_m_neg_0(cons_n0_i),
    .io_m_pos_1(cons_p1_i), .io_m_pos_2(cons_p2_i)
  );

  // ---------------- IterBlockI8Nr4 ----------------
  logic [8:0] it_d [0:3];
  logic [8:0] it_w;
  logic [7:0] it_wl, it_q;
  wire  [8:0] it_nw_g, it_nw_i;
  wire  [7:0] it_nwl_g, it_nwl_i, it_nq_g, it_nq_i;
  IterBlockI8Nr4 g_it (
    .io_d_cons_0(it_d[0]), .io_d_cons_1(it_d[1]),
    .io_d_cons_2(it_d[2]), .io_d_cons_3(it_d[3]),
    .io_pre_w(it_w), .io_pre_w_low(it_wl),
    .io_nxt_w(it_nw_g), .io_nxt_w_low(it_nwl_g),
    .io_pre_q(it_q), .io_nxt_q(it_nq_g)
  );
  IterBlockI8Nr4_xs i_it (
    .io_d_cons_0(it_d[0]), .io_d_cons_1(it_d[1]),
    .io_d_cons_2(it_d[2]), .io_d_cons_3(it_d[3]),
    .io_pre_w(it_w), .io_pre_w_low(it_wl),
    .io_nxt_w(it_nw_i), .io_nxt_w_low(it_nwl_i),
    .io_pre_q(it_q), .io_nxt_q(it_nq_i)
  );

  // ---------------- lzc 家族 ----------------
  logic [52:0] lzc_in;
  logic [23:0] lzc3_in;
  logic [10:0] lzc4_in;
  wire [5:0] lzc_cnt_g, lzc_cnt_i;
  wire       lzc_e_g, lzc_e_i;
  wire [4:0] lzc3_cnt_g, lzc3_cnt_i;
  wire       lzc3_e_g, lzc3_e_i;
  wire [3:0] lzc4_cnt_g, lzc4_cnt_i;
  wire       lzc4_e_g, lzc4_e_i;
  lzc    g_lzc  (.in_i(lzc_in),  .cnt_o(lzc_cnt_g),  .empty_o(lzc_e_g));
  lzc_xs i_lzc  (.in_i(lzc_in),  .cnt_o(lzc_cnt_i),  .empty_o(lzc_e_i));
  lzc_3    g_lzc3 (.in_i(lzc3_in), .cnt_o(lzc3_cnt_g), .empty_o(lzc3_e_g));
  lzc_3_xs i_lzc3 (.in_i(lzc3_in), .cnt_o(lzc3_cnt_i), .empty_o(lzc3_e_i));
  lzc_4    g_lzc4 (.in_i(lzc4_in), .cnt_o(lzc4_cnt_g), .empty_o(lzc4_e_g));
  lzc_4_xs i_lzc4 (.in_i(lzc4_in), .cnt_o(lzc4_cnt_i), .empty_o(lzc4_e_i));

  // ================= 独立 oracle（int 取模算术，与 RTL 写法不同源） =================

  // N 位回绕和的符号：折回 N 位二进制补码再判负
  function automatic logic sign_wrap6(input int unsigned a, input int unsigned b);
    return ((a + b) % 64) >= 32;
  endfunction
  function automatic logic sign_wrap7(input int unsigned a, input int unsigned b);
    return ((a + b) % 128) >= 64;
  endfunction
  function automatic logic sign_wrap9(input int unsigned a, input int unsigned b);
    return ((a + b) % 512) >= 256;
  endfunction

  // QDS 选择表：四个比较和符号 -> one-hot {-2,-1,0,+1,+2}
  function automatic logic [4:0] qds_decode(input logic s_p2, input logic s_p1,
                                            input logic s_n0, input logic s_n1);
    qds_decode[4] = s_n0 & s_n1;
    qds_decode[3] = s_n0 & ~s_n1;
    qds_decode[2] = ~s_n0 & s_p1;
    qds_decode[1] = s_p2 & ~s_p1;
    qds_decode[0] = ~s_p2 & ~s_p1;
  endfunction

  // 全宽 CLZ：最高置位在 p 则返回 w-1-p；全零返回 0（含 empty 截零语义）
  function automatic int unsigned oracle_clz(input logic [52:0] din, input int unsigned w);
    if (din == '0) return 0;
    for (int i = w - 1; i >= 0; i--)
      if (din[i]) return w - 1 - i;
    return 0;  // 不可达
  endfunction

  task automatic compare_now;
    logic [4:0] exp_qds, exp_qv2, exp_qs, exp_qvs;
    logic [6:0] exp_cg_n1, exp_cg_n0, exp_cg_p1, exp_cg_p2;
    logic [8:0] exp_cons_n1, exp_cons_n0, exp_cons_p1, exp_cons_p2;
    logic [8:0] exp_it_w;
    logic [7:0] exp_it_wl, exp_it_q;
    logic [5:0] exp_lzc;
    logic [4:0] exp_lzc3;
    logic [3:0] exp_lzc4;
    logic [3:0] s_signs;
    int unsigned base;
    int unsigned trial, nxw, sel1, sel2;
    int unsigned row;
    begin
      #1;
      vectors++;

      // ---- r4_qds ----
      exp_qds = qds_decode(sign_wrap7(qds_rem, qds_mp2), sign_wrap7(qds_rem, qds_mp1),
                           sign_wrap7(qds_rem, qds_mn0), sign_wrap7(qds_rem, qds_mn1));

      // ---- r4_qds_v2（常数 -12,-3,+4,+13 mod 64）----
      exp_qv2 = qds_decode(sign_wrap6(qv2_rem, 52), sign_wrap6(qv2_rem, 61),
                           sign_wrap6(qv2_rem, 4), sign_wrap6(qv2_rem, 13));

      // ---- r4_qds_spec ----
      s_signs = 4'h0;
      for (int c = 0; c < 5; c++) begin
        if (qs_prev[c]) begin
          // 候选 c 的余数修正项（c=2：上拍 q=0，无修正）
          case (c)
            0:       base = (qs_rem + qs_csa_p2) % 512;
            1:       base = (qs_rem + qs_csa_p1) % 512;
            2:       base = qs_rem;
            3:       base = (qs_rem + qs_csa_n1) % 512;
            default: base = (qs_rem + qs_csa_n2) % 512;
          endcase
          // 组号 4-c，组内 {neg_1,neg_0,pos_1,pos_2}；比较常数左移 2 位 = 4*m
          s_signs[3] |= sign_wrap9(base, 4 * qs_m[(4-c)*4+3]);  // pos_2
          s_signs[2] |= sign_wrap9(base, 4 * qs_m[(4-c)*4+2]);  // pos_1
          s_signs[1] |= sign_wrap9(base, 4 * qs_m[(4-c)*4+1]);  // neg_0
          s_signs[0] |= sign_wrap9(base, 4 * qs_m[(4-c)*4+0]);  // neg_1
        end
      end
      exp_qs = qds_decode(s_signs[3], s_signs[2], s_signs[1], s_signs[0]);

      // ---- r4_qds_v2_spec（阈值偏移 -24,-6,+8,+26 mod 128）----
      s_signs = 4'h0;
      for (int c = 0; c < 5; c++) begin
        if (qvs_prev[c]) begin
          case (c)
            0:       base = (qvs_rem + qvs_dmul_n2) % 128;
            1:       base = (qvs_rem + qvs_dmul_n1) % 128;
            2:       base = qvs_rem;
            3:       base = (qvs_rem + qvs_dmul_p1) % 128;
            default: base = (qvs_rem + qvs_dmul_p2) % 128;
          endcase
          s_signs[3] |= ((base + 104) % 128) >= 64;  // -24
          s_signs[2] |= ((base + 122) % 128) >= 64;  // -6
          s_signs[1] |= ((base + 8) % 128) >= 64;
          s_signs[0] |= ((base + 26) % 128) >= 64;
        end
      end
      exp_qvs = qds_decode(s_signs[3], s_signs[2], s_signs[1], s_signs[0]);

      // ---- r4_qds_cg（a0=1 折叠到第 7 行）----
      row = cg_a0 ? 7 : {cg_a2, cg_a3, cg_a4};
      case (row)
        0: begin
          exp_cg_n1 = 7'h0D; exp_cg_n0 = 7'h04; exp_cg_p1 = 7'h7C; exp_cg_p2 = 7'h74;
        end
        1: begin
          exp_cg_n1 = 7'h0E; exp_cg_n0 = 7'h05; exp_cg_p1 = 7'h7C; exp_cg_p2 = 7'h72;
        end
        2: begin
          exp_cg_n1 = 7'h10; exp_cg_n0 = 7'h06; exp_cg_p1 = 7'h7C; exp_cg_p2 = 7'h70;
        end
        3: begin
          exp_cg_n1 = 7'h11; exp_cg_n0 = 7'h06; exp_cg_p1 = 7'h7C; exp_cg_p2 = 7'h70;
        end
        4: begin
          exp_cg_n1 = 7'h12; exp_cg_n0 = 7'h06; exp_cg_p1 = 7'h7A; exp_cg_p2 = 7'h6E;
        end
        5: begin
          exp_cg_n1 = 7'h14; exp_cg_n0 = 7'h08; exp_cg_p1 = 7'h7A; exp_cg_p2 = 7'h6C;
        end
        6: begin
          exp_cg_n1 = 7'h16; exp_cg_n0 = 7'h08; exp_cg_p1 = 7'h78; exp_cg_p2 = 7'h6C;
        end
        default: begin
          exp_cg_n1 = 7'h17; exp_cg_n0 = 7'h08; exp_cg_p1 = 7'h78; exp_cg_p2 = 7'h6A;
        end
      endcase

      // ---- SRT4qdsCons ----
      case (cons_idx)
        0: begin
          exp_cons_n1 = 9'h034; exp_cons_n0 = 9'h010; exp_cons_p1 = 9'h1F4; exp_cons_p2 = 9'h1D0;
        end
        1: begin
          exp_cons_n1 = 9'h03C; exp_cons_n0 = 9'h018; exp_cons_p1 = 9'h1F0; exp_cons_p2 = 9'h1C8;
        end
        2: begin
          exp_cons_n1 = 9'h040; exp_cons_n0 = 9'h018; exp_cons_p1 = 9'h1F0; exp_cons_p2 = 9'h1C4;
        end
        3: begin
          exp_cons_n1 = 9'h048; exp_cons_n0 = 9'h018; exp_cons_p1 = 9'h1F0; exp_cons_p2 = 9'h1BC;
        end
        4: begin
          exp_cons_n1 = 9'h04C; exp_cons_n0 = 9'h020; exp_cons_p1 = 9'h1EC; exp_cons_p2 = 9'h1B8;
        end
        5: begin
          exp_cons_n1 = 9'h054; exp_cons_n0 = 9'h020; exp_cons_p1 = 9'h1E8; exp_cons_p2 = 9'h1B0;
        end
        6: begin
          exp_cons_n1 = 9'h058; exp_cons_n0 = 9'h020; exp_cons_p1 = 9'h1E8; exp_cons_p2 = 9'h1AC;
        end
        default: begin
          exp_cons_n1 = 9'h060; exp_cons_n0 = 9'h020; exp_cons_p1 = 9'h1E8; exp_cons_p2 = 9'h1A4;
        end
      endcase

      // ---- IterBlockI8Nr4 ----
      sel1  = it_w[8] + 1;
      trial = (it_d[sel1] + ((it_w % 256) * 2 + it_wl[7])) % 512;
      sel2  = it_w[8] * 2 + ((trial >= 256) ? 1 : 0);
      nxw   = (it_d[sel2] + ((it_w % 128) * 4 + it_wl[7:6])) % 512;
      exp_it_w  = nxw[8:0];
      exp_it_wl = {it_wl[5:0], 2'b00};
      exp_it_q  = {it_q[5:0], (trial < 256), (nxw < 256)};

      // ---- lzc 家族 ----
      exp_lzc  = oracle_clz(lzc_in, 53);
      exp_lzc3 = oracle_clz({29'h0, lzc3_in}, 24);
      exp_lzc4 = oracle_clz({42'h0, lzc4_in}, 11);

      // ---- 双例化比对 ----
      if ({qds_g, qv2_g, qs_g, qvs_g,
           cg_n1_g, cg_n0_g, cg_p1_g, cg_p2_g,
           cons_n1_g, cons_n0_g, cons_p1_g, cons_p2_g,
           it_nw_g, it_nwl_g, it_nq_g,
           lzc_cnt_g, lzc_e_g, lzc3_cnt_g, lzc3_e_g, lzc4_cnt_g, lzc4_e_g} !==
          {qds_i, qv2_i, qs_i, qvs_i,
           cg_n1_i, cg_n0_i, cg_p1_i, cg_p2_i,
           cons_n1_i, cons_n0_i, cons_p1_i, cons_p2_i,
           it_nw_i, it_nwl_i, it_nq_i,
           lzc_cnt_i, lzc_e_i, lzc3_cnt_i, lzc3_e_i, lzc4_cnt_i, lzc4_e_i}) begin
        errors++;
        if (errors < 8)
          $display("golden mismatch at vector %0d", vectors);
      end

      // ---- 独立 oracle 比对 ----
      if ({qds_i, qv2_i, qs_i, qvs_i,
           cg_n1_i, cg_n0_i, cg_p1_i, cg_p2_i,
           cons_n1_i, cons_n0_i, cons_p1_i, cons_p2_i,
           it_nw_i, it_nwl_i, it_nq_i,
           lzc_cnt_i, lzc_e_i, lzc3_cnt_i, lzc3_e_i, lzc4_cnt_i, lzc4_e_i} !==
          {exp_qds, exp_qv2, exp_qs, exp_qvs,
           exp_cg_n1, exp_cg_n0, exp_cg_p1, exp_cg_p2,
           exp_cons_n1, exp_cons_n0, exp_cons_p1, exp_cons_p2,
           exp_it_w, exp_it_wl, exp_it_q,
           exp_lzc, (lzc_in == '0), exp_lzc3, (lzc3_in == '0),
           exp_lzc4, (lzc4_in == '0)}) begin
        errors++;
        if (errors < 8)
          $display("independent oracle mismatch at vector %0d", vectors);
      end
    end
  endtask

  task automatic drive_zero;
    qds_rem = '0; qds_mn1 = '0; qds_mn0 = '0; qds_mp1 = '0; qds_mp2 = '0;
    qv2_rem = '0;
    qs_rem = '0; qs_csa_n2 = '0; qs_csa_n1 = '0; qs_csa_p1 = '0; qs_csa_p2 = '0;
    for (int k = 0; k < 20; k++) qs_m[k] = '0;
    qs_prev = '0;
    qvs_rem = '0; qvs_dmul_p2 = '0; qvs_dmul_p1 = '0; qvs_dmul_n1 = '0; qvs_dmul_n2 = '0;
    qvs_prev = '0;
    {cg_a0, cg_a2, cg_a3, cg_a4} = '0;
    cons_idx = '0;
    for (int k = 0; k < 4; k++) it_d[k] = '0;
    it_w = '0; it_wl = '0; it_q = '0;
    lzc_in = '0; lzc3_in = '0; lzc4_in = '0;
  endtask

  task automatic drive_ones;
    qds_rem = '1; qds_mn1 = '1; qds_mn0 = '1; qds_mp1 = '1; qds_mp2 = '1;
    qv2_rem = '1;
    qs_rem = '1; qs_csa_n2 = '1; qs_csa_n1 = '1; qs_csa_p1 = '1; qs_csa_p2 = '1;
    for (int k = 0; k < 20; k++) qs_m[k] = '1;
    qs_prev = '1;
    qvs_rem = '1; qvs_dmul_p2 = '1; qvs_dmul_p1 = '1; qvs_dmul_n1 = '1; qvs_dmul_n2 = '1;
    qvs_prev = '1;
    {cg_a0, cg_a2, cg_a3, cg_a4} = '1;
    cons_idx = '1;
    for (int k = 0; k < 4; k++) it_d[k] = '1;
    it_w = '1; it_wl = '1; it_q = '1;
    lzc_in = '1; lzc3_in = '1; lzc4_in = '1;
  endtask

  task automatic randomize_inputs;
    qds_rem = $urandom; qds_mn1 = $urandom; qds_mn0 = $urandom;
    qds_mp1 = $urandom; qds_mp2 = $urandom;
    qv2_rem = $urandom;
    qs_rem = $urandom; qs_csa_n2 = $urandom; qs_csa_n1 = $urandom;
    qs_csa_p1 = $urandom; qs_csa_p2 = $urandom;
    for (int k = 0; k < 20; k++) qs_m[k] = $urandom;
    qs_prev = $urandom;
    qvs_rem = $urandom;
    qvs_dmul_p2 = $urandom; qvs_dmul_p1 = $urandom;
    qvs_dmul_n1 = $urandom; qvs_dmul_n2 = $urandom;
    qvs_prev = $urandom;
    {cg_a0, cg_a2, cg_a3, cg_a4} = $urandom;
    cons_idx = $urandom;
    for (int k = 0; k < 4; k++) it_d[k] = $urandom;
    it_w = $urandom; it_wl = $urandom; it_q = $urandom;
    lzc_in = {$urandom, $urandom};
    lzc3_in = $urandom;
    lzc4_in = $urandom;
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end

    // 全零（含 lzc empty 档）
    drive_zero();
    compare_now();
    // 全 1（含 prev 多 hot 的或语义）
    drive_ones();
    compare_now();

    // r4_qds：16 组比较器符号组合（rem=0，m=7'h40 置符号位）
    qds_rem = '0;
    for (int p = 0; p < 16; p++) begin
      qds_mp2 = p[3] ? 7'h40 : 7'h00;
      qds_mp1 = p[2] ? 7'h40 : 7'h00;
      qds_mn0 = p[1] ? 7'h40 : 7'h00;
      qds_mn1 = p[0] ? 7'h40 : 7'h00;
      compare_now();
    end

    // r4_qds_v2：6 位输入穷举
    for (int v = 0; v < 64; v++) begin
      qv2_rem = v[5:0];
      compare_now();
    end

    // r4_qds_cg：4 输入穷举
    for (int v = 0; v < 16; v++) begin
      {cg_a0, cg_a2, cg_a3, cg_a4} = v[3:0];
      compare_now();
    end

    // SRT4qdsCons：3 位索引穷举
    for (int v = 0; v < 8; v++) begin
      cons_idx = v[2:0];
      compare_now();
    end

    // lzc 家族：逐位置 1（含第 0 位的 PriorityEncoder 末档）
    for (int b = 0; b < 53; b++) begin
      lzc_in = '0; lzc_in[b] = 1'b1;
      compare_now();
    end
    for (int b = 0; b < 24; b++) begin
      lzc3_in = '0; lzc3_in[b] = 1'b1;
      compare_now();
    end
    for (int b = 0; b < 11; b++) begin
      lzc4_in = '0; lzc4_in[b] = 1'b1;
      compare_now();
    end

    // r4_qds_spec：5 个 prev one-hot × 16 组符号组合（rem=csa=0，m=7'h40 置符号）
    for (int c = 0; c < 5; c++) begin
      for (int p = 0; p < 16; p++) begin
        qs_rem = '0; qs_csa_n2 = '0; qs_csa_n1 = '0; qs_csa_p1 = '0; qs_csa_p2 = '0;
        for (int k = 0; k < 20; k++) qs_m[k] = '0;
        qs_prev = 5'b00001 << c;
        qs_m[(4-c)*4+3] = p[3] ? 7'h40 : 7'h00;
        qs_m[(4-c)*4+2] = p[2] ? 7'h40 : 7'h00;
        qs_m[(4-c)*4+1] = p[1] ? 7'h40 : 7'h00;
        qs_m[(4-c)*4+0] = p[0] ? 7'h40 : 7'h00;
        compare_now();
      end
    end
    // prev 多 hot 的或语义（各候选组取不同符号型样）
    for (int k = 0; k < 20; k++) qs_m[k] = '0;
    qs_rem = '0; qs_csa_n2 = '0; qs_csa_n1 = '0; qs_csa_p1 = '0; qs_csa_p2 = '0;
    qs_prev = 5'b11111;
    for (int c = 0; c < 5; c++)
      qs_m[(4-c)*4 + (c % 4)] = 7'h40;
    compare_now();
    qs_prev = 5'b01010;
    compare_now();

    // r4_qds_v2_spec：prev one-hot × rem 扫描（dmul=0）
    qvs_dmul_p2 = '0; qvs_dmul_p1 = '0; qvs_dmul_n1 = '0; qvs_dmul_n2 = '0;
    for (int c = 0; c < 5; c++) begin
      for (int v = 0; v < 8; v++) begin
        qvs_prev = 5'b00001 << c;
        qvs_rem = v[2:0] * 16;
        compare_now();
      end
    end
    // prev 多 hot
    qvs_prev = 5'b10101;
    qvs_rem = 7'h55;
    compare_now();

    // IterBlockI8Nr4：余数符号 × 低位注入的定向组合
    it_d[0] = 9'h000; it_d[1] = 9'h055; it_d[2] = 9'h1AB; it_d[3] = 9'h0AA;
    it_q = 8'hA5;
    for (int a = 0; a < 5; a++) begin
      case (a)
        0: it_w = 9'h000;
        1: it_w = 9'h100;
        2: it_w = 9'h1FF;
        3: it_w = 9'h07F;
        default: it_w = 9'h080;
      endcase
      for (int b = 0; b < 4; b++) begin
        case (b)
          0: it_wl = 8'h00;
          1: it_wl = 8'hFF;
          2: it_wl = 8'h80;
          default: it_wl = 8'h40;
        endcase
        compare_now();
      end
    end

    repeat (NCYCLES) begin
      randomize_inputs();
      compare_now();
    end

    $display("SRTDivSqrtLeaves10 UT: vectors=%0d module_checks=%0d errors=%0d",
             vectors, vectors * 10, errors);
    if (errors == 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
