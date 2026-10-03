// =============================================================================
// fpdiv_r64_block.sv —— 标量浮点除法器的"一拍算 3 个基 4 商位"迭代块（纯组合，只有 f64 一条通道）
//
// 在哪一层：yunsuan fpu/FloatDivider.scala 的 FloatDividerR64（标量 f16/f32/f64 除法，SRT 基 4）
//   每个迭代拍调用本块一次。父级把尾数都左对齐到 f64 宽度后送进来，所以本块只有一条 60 位
//   余数通道（72 位余数向量的 [71:12]，低 12 位恒 0）与一个 57 位除数（60 位除数向量的 [59:3]）。
//   本块串联 3 级基 4 迭代（s0/s1/s2），返回 3 个商位、迭代后的余数（sum/carry 冗余形式），
//   以及下一拍 s0/s1 商位选择要用的 6 位 / 7 位余数片（提前一拍算好，缩短关键路径）。
// 设计源：yunsuan/fpu/FloatDivider.scala class fpdiv_r64_block（S1_SPECULATIVE_QDS=1,
//   S2_SPECULATIVE_QDS=true, QDS_ARCH=2）。golden 里 io.fp_format_onehot 已被 firtool 消掉
//   （标量版只用 f64 通道，格式输入不影响任何输出）；io.nxt_f_r_s_o / nxt_f_r_c_o 只剩下标 2。
//
// 一级基 4 迭代：商位 q ∈ {+2,+1,0,-1,-2}，one-hot 编码 digit[4:0]，位序 [0]=+2 [1]=+1 [2]=0
//   [3]=-1 [4]=-2（父级累加商时 digit[0] 接 2'b10、digit[4] 接 quo_m1 的 2'b10，可据此核对）。
//   下一余数 = 4*rem - q*D：digit[j] 选中的候选是 4*rem + (j-2)*D，对 4 个非零项各用一个 3:2 CSA
//   投机算一份（j=2 只是移位），再按本级商位选中一份（Mux1H，按位或）。除数倍数以 60 位
//   "扩展除数" ext = {2'b0, D, 1'b0} 为底：+D = ext，+2D = ext<<1，-D = ~ext，-2D = ~(ext<<1)；
//   取负的两项把补码的 +1 加在 carry 的通道最低位上。
//   商位选择：s0 用 r4_qds_v2 直接查父级送来的 6 位余数片；s1 用 r4_qds_v2_spec（父级送来的 7 位
//   余数片 + 除数高 7 位，按 s0 商位投机）；s2 也是投机的，但它的 7 位余数片取自本拍 s0 的 5 个候选
//   （"S2_SPECULATIVE"：不等 s1 的余数算完）。
//
// 与 Scala 的差别（只差在读不到的位上，输出逐位相同）：
//   - s0 的 CSA 是与向量版共用的 200 位实例（CSA3to2_20），Scala 还往它的 f32/f16 字段里塞了数据，
//     但标量版只读 f64 字段 [199:140]；CSA 是逐位的、进位只左移一位，[199:140] 只依赖输入 [199:139]，
//     所以本文件只填 f64 字段，其余位给 0。
//   - Scala 的 s1 投机商位取的是"f16 通道 3"的除数片 divisor_i[59:45]，它的高 7 位与 f64 除数的高
//     7 位是同一批位（divisor_i[59:53] / [58:52]），本文件统一写成 f64 除数片。
//   - Scala 对 s1/s2 的 pos 候选 carry 做 `& mask_zero`，标量版 mask_zero 全 1，是空操作，省略。
// 子模块（全部为本仓已签核的重写件，实例名与 golden 一致）：
//   CSA3to2_20 ×4（200 位，s0）、CSA3to2_24 ×8（72 位，s1/s2）、r4_qds_v2 ×1、r4_qds_v2_spec ×2。
// golden 对照：G1-canonical/golden-rtl/fpdiv_r64_block.sv
// =============================================================================
module xs_fpdiv_r64_block_core (
  input  logic [59:0]      rem_s_in,      // 当前余数 sum（f64 通道，60 位）
  input  logic [59:0]      rem_c_in,      // 当前余数 carry
  input  logic [56:0]      divisor,       // 规格化后的除数尾数（57 位）
  input  logic [5:0]       rem6_for_s0,   // 上一拍预算的 s0 商位余数片
  input  logic [6:0]       rem7_for_s1,   // 上一拍预算的 s1 商位余数片
  output logic [2:0][4:0]  quo_dig,       // 本拍 3 个商位（[0]=s0 … [2]=s2）
  output logic [59:0]      rem_s_out,     // 迭代 3 级后的余数 sum
  output logic [59:0]      rem_c_out,     // 迭代 3 级后的余数 carry
  output logic [5:0]       adder6_out,    // 下一拍 s0 商位用的 6 位余数片
  output logic [6:0]       adder7_out     // 下一拍 s1 商位用的 7 位余数片
);
  // ---------------------------------------------------------------------------
  // §0 商位编码与除数倍数
  //   下标 j = digit 的位：候选 j 往 4*rem 上加的除数倍数是 (j-2)*D。常量按"加的是什么"命名：
  //   Q_N2 = 0（加 -2D，商位 +2）、Q_N1 = 1（加 -D，商位 +1）、Q_Z = 2（商位 0）、
  //   Q_P1 = 3（加 +D，商位 -1）、Q_P2 = 4（加 +2D，商位 -2）。r4_qds 的端口名 pos/neg 也是这个口径。
  // ---------------------------------------------------------------------------
  localparam int Q_N2 = 0, Q_N1 = 1, Q_Z = 2, Q_P1 = 3, Q_P2 = 4;

  logic [59:0]      divisor_ext;
  logic [4:0][59:0] div_mul;        // 60 位通道里候选 j 要加的 (j-2)*D（取负的以反码给出，+1 另加），Q_Z 项为 0
  logic [4:0][6:0]  div_hi7;        // 除数倍数的高 7 位片 [57:51]（投机商位选择 / 下一拍余数片）
  logic [4:0][7:0]  div_hi8;        // 除数倍数的高 8 位片 [55:48]（下一拍 s1 余数片）
  always_comb begin
    divisor_ext    = {2'b00, divisor, 1'b0};
    div_mul[Q_P1]  = divisor_ext;
    div_mul[Q_P2]  = {divisor_ext[58:0], 1'b0};
    div_mul[Q_N1]  = ~divisor_ext;
    div_mul[Q_N2]  = ~{divisor_ext[58:0], 1'b0};
    div_mul[Q_Z]   = '0;
    for (int q = 0; q < 5; q++) begin
      div_hi7[q] = div_mul[q][57:51];
      div_hi8[q] = div_mul[q][55:48];
    end
  end

  // 按商位 one-hot 选候选（按位或，与 Chisel Mux1H 一致）
  function automatic logic [59:0] pick60(input logic [4:0] dig, input logic [4:0][59:0] cand);
    pick60 = '0;
    for (int q = 0; q < 5; q++) pick60 |= {60{dig[q]}} & cand[q];
  endfunction
  function automatic logic [6:0] pick7(input logic [4:0] dig, input logic [4:0][6:0] cand);
    pick7 = '0;
    for (int q = 0; q < 5; q++) pick7 |= {7{dig[q]}} & cand[q];
  endfunction
  function automatic logic [7:0] pick8(input logic [4:0] dig, input logic [4:0][7:0] cand);
    pick8 = '0;
    for (int q = 0; q < 5; q++) pick8 |= {8{dig[q]}} & cand[q];
  endfunction

  // 加负倍数的候选（商位 > 0）的 carry 要在通道最低位补 1，完成补码
  function automatic logic is_neg(input int q);
    is_neg = (q == Q_N1) || (q == Q_N2);
  endfunction

  // ---------------------------------------------------------------------------
  // §1 s0 级：4*rem 与 4 个除数倍数各做一次 3:2 压缩（200 位共享 CSA 的 f64 字段 [199:140]）
  // ---------------------------------------------------------------------------
  logic [199:0]      csa0_a, csa0_b;
  logic [4:0][199:0] csa0_c, csa0_sum, csa0_car;
  always_comb begin
    csa0_a = {rem_s_in[57:0], 2'b00, 140'b0};
    csa0_b = {rem_c_in[57:0], 2'b00, 140'b0};
    for (int q = 0; q < 5; q++) csa0_c[q] = {div_mul[q], 140'b0};
  end
  assign csa0_sum[Q_Z] = '0;
  assign csa0_car[Q_Z] = '0;
  CSA3to2_20 U_CSA_0_4 (.io_in_a(csa0_a), .io_in_b(csa0_b), .io_in_c(csa0_c[Q_P2]),
                        .io_out_sum(csa0_sum[Q_P2]), .io_out_car(csa0_car[Q_P2]));
  CSA3to2_20 U_CSA_0_3 (.io_in_a(csa0_a), .io_in_b(csa0_b), .io_in_c(csa0_c[Q_P1]),
                        .io_out_sum(csa0_sum[Q_P1]), .io_out_car(csa0_car[Q_P1]));
  CSA3to2_20 U_CSA_0_1 (.io_in_a(csa0_a), .io_in_b(csa0_b), .io_in_c(csa0_c[Q_N1]),
                        .io_out_sum(csa0_sum[Q_N1]), .io_out_car(csa0_car[Q_N1]));
  CSA3to2_20 U_CSA_0_0 (.io_in_a(csa0_a), .io_in_b(csa0_b), .io_in_c(csa0_c[Q_N2]),
                        .io_out_sum(csa0_sum[Q_N2]), .io_out_car(csa0_car[Q_N2]));

  // 5 个候选余数（60 位通道）；商位 0 的候选就是 4*rem
  logic [4:0][59:0] cand0_s, cand0_c;
  always_comb begin
    for (int q = 0; q < 5; q++) begin
      if (q == Q_Z) begin
        cand0_s[q] = {rem_s_in[57:0], 2'b00};
        cand0_c[q] = {rem_c_in[57:0], 2'b00};
      end else begin
        cand0_s[q] = csa0_sum[q][199:140];
        cand0_c[q] = csa0_car[q][199:140] | 60'(is_neg(q));
      end
    end
  end

  // s0 商位：直接查上一拍送来的 6 位余数片
  r4_qds_v2 u_r4_qds_s0_0 (.io_rem_i(rem6_for_s0), .io_quo_dig_o(quo_dig[0]));

  logic [59:0] rem0_s, rem0_c;     // s0 选中的余数
  assign rem0_s = pick60(quo_dig[0], cand0_s);
  assign rem0_c = pick60(quo_dig[0], cand0_c);

  // s2 的投机余数片：s0 每个候选的 7 位窗 [55:49] 先做 s+c，再按 s0 商位选（不等 s1 算完）
  logic [4:0][6:0] cand0_win7;
  always_comb
    for (int q = 0; q < 5; q++) cand0_win7[q] = 7'(cand0_s[q][55:49] + cand0_c[q][55:49]);
  logic [6:0] s2_rem7;
  assign s2_rem7 = pick7(quo_dig[0], cand0_win7);

  // ---------------------------------------------------------------------------
  // §2 s1 级：72 位 CSA（通道在 [71:12]），商位按 s0 商位投机
  // ---------------------------------------------------------------------------
  logic [71:0]      csa1_a, csa1_b;
  logic [4:0][71:0] csa1_sum, csa1_car;
  assign csa1_a = {rem0_s[57:0], 2'b00, 12'b0};
  assign csa1_b = {rem0_c[57:0], 2'b00, 12'b0};
  assign csa1_sum[Q_Z] = '0;
  assign csa1_car[Q_Z] = '0;
  CSA3to2_24 U_CSA_1_4 (.io_in_a(csa1_a), .io_in_b(csa1_b), .io_in_c({div_mul[Q_P2], 12'b0}),
                        .io_out_sum(csa1_sum[Q_P2]), .io_out_car(csa1_car[Q_P2]));
  CSA3to2_24 U_CSA_1_3 (.io_in_a(csa1_a), .io_in_b(csa1_b), .io_in_c({div_mul[Q_P1], 12'b0}),
                        .io_out_sum(csa1_sum[Q_P1]), .io_out_car(csa1_car[Q_P1]));
  CSA3to2_24 U_CSA_1_1 (.io_in_a(csa1_a), .io_in_b(csa1_b), .io_in_c({div_mul[Q_N1], 12'b0}),
                        .io_out_sum(csa1_sum[Q_N1]), .io_out_car(csa1_car[Q_N1]));
  CSA3to2_24 U_CSA_1_0 (.io_in_a(csa1_a), .io_in_b(csa1_b), .io_in_c({div_mul[Q_N2], 12'b0}),
                        .io_out_sum(csa1_sum[Q_N2]), .io_out_car(csa1_car[Q_N2]));

  logic [4:0][59:0] cand1_s, cand1_c;
  always_comb begin
    for (int q = 0; q < 5; q++) begin
      if (q == Q_Z) begin
        cand1_s[q] = {rem0_s[57:0], 2'b00};
        cand1_c[q] = {rem0_c[57:0], 2'b00};
      end else begin
        cand1_s[q] = csa1_sum[q][71:12];
        cand1_c[q] = csa1_car[q][71:12] | 60'(is_neg(q));
      end
    end
  end

  r4_qds_v2_spec u_r4_qds_s1_6 (.io_rem_i(rem7_for_s1),
                                .io_divisor_mul_pos_2_i(div_hi7[Q_P2]),
                                .io_divisor_mul_pos_1_i(div_hi7[Q_P1]),
                                .io_divisor_mul_neg_1_i(div_hi7[Q_N1]),
                                .io_divisor_mul_neg_2_i(div_hi7[Q_N2]),
                                .io_prev_quo_dig_i(quo_dig[0]),
                                .io_quo_dig_o(quo_dig[1]));

  logic [59:0] rem1_s, rem1_c;     // s1 选中的余数
  assign rem1_s = pick60(quo_dig[1], cand1_s);
  assign rem1_c = pick60(quo_dig[1], cand1_c);

  // ---------------------------------------------------------------------------
  // §3 s2 级：同 s1；商位用 §1 投机得到的余数片
  // ---------------------------------------------------------------------------
  logic [71:0]      csa2_a, csa2_b;
  logic [4:0][71:0] csa2_sum, csa2_car;
  assign csa2_a = {rem1_s[57:0], 2'b00, 12'b0};
  assign csa2_b = {rem1_c[57:0], 2'b00, 12'b0};
  assign csa2_sum[Q_Z] = '0;
  assign csa2_car[Q_Z] = '0;
  CSA3to2_24 U_CSA_2_4 (.io_in_a(csa2_a), .io_in_b(csa2_b), .io_in_c({div_mul[Q_P2], 12'b0}),
                        .io_out_sum(csa2_sum[Q_P2]), .io_out_car(csa2_car[Q_P2]));
  CSA3to2_24 U_CSA_2_3 (.io_in_a(csa2_a), .io_in_b(csa2_b), .io_in_c({div_mul[Q_P1], 12'b0}),
                        .io_out_sum(csa2_sum[Q_P1]), .io_out_car(csa2_car[Q_P1]));
  CSA3to2_24 U_CSA_2_1 (.io_in_a(csa2_a), .io_in_b(csa2_b), .io_in_c({div_mul[Q_N1], 12'b0}),
                        .io_out_sum(csa2_sum[Q_N1]), .io_out_car(csa2_car[Q_N1]));
  CSA3to2_24 U_CSA_2_0 (.io_in_a(csa2_a), .io_in_b(csa2_b), .io_in_c({div_mul[Q_N2], 12'b0}),
                        .io_out_sum(csa2_sum[Q_N2]), .io_out_car(csa2_car[Q_N2]));

  logic [4:0][59:0] cand2_s, cand2_c;
  always_comb begin
    for (int q = 0; q < 5; q++) begin
      if (q == Q_Z) begin
        cand2_s[q] = {rem1_s[57:0], 2'b00};
        cand2_c[q] = {rem1_c[57:0], 2'b00};
      end else begin
        cand2_s[q] = csa2_sum[q][71:12];
        cand2_c[q] = csa2_car[q][71:12] | 60'(is_neg(q));
      end
    end
  end

  r4_qds_v2_spec u_r4_qds_s2_0 (.io_rem_i(s2_rem7),
                                .io_divisor_mul_pos_2_i(div_hi7[Q_P2]),
                                .io_divisor_mul_pos_1_i(div_hi7[Q_P1]),
                                .io_divisor_mul_neg_1_i(div_hi7[Q_N1]),
                                .io_divisor_mul_neg_2_i(div_hi7[Q_N2]),
                                .io_prev_quo_dig_i(quo_dig[1]),
                                .io_quo_dig_o(quo_dig[2]));

  assign rem_s_out = pick60(quo_dig[2], cand2_s);
  assign rem_c_out = pick60(quo_dig[2], cand2_c);

  // ---------------------------------------------------------------------------
  // §4 下一拍的余数片：对 s1 选中的余数，按 5 个可能的 s2 商位各预算一份
  //   "s2 之后的余数窗" = (s + c) + 该候选的除数倍数 的高位片（商位 0 不加），再按 s2 商位选，丢掉最低位。
  //   6 位片取余数 [55:49] 的 7 位和的高 6 位；7 位片取 [53:46] 的 8 位和的高 7 位。
  // ---------------------------------------------------------------------------
  logic [6:0]      win7_sc;
  logic [7:0]      win8_sc;
  logic [4:0][6:0] nxt7;
  logic [4:0][7:0] nxt8;
  always_comb begin
    win7_sc = 7'(rem1_s[55:49] + rem1_c[55:49]);
    win8_sc = 8'(rem1_s[53:46] + rem1_c[53:46]);
    for (int q = 0; q < 5; q++) begin
      nxt7[q] = (q == Q_Z) ? win7_sc : 7'(win7_sc + div_hi7[q]);
      nxt8[q] = (q == Q_Z) ? win8_sc : 8'(win8_sc + div_hi8[q]);
    end
  end
  logic [6:0] nxt7_sel;
  logic [7:0] nxt8_sel;
  assign nxt7_sel   = pick7(quo_dig[2], nxt7);
  assign nxt8_sel   = pick8(quo_dig[2], nxt8);
  assign adder6_out = nxt7_sel[6:1];
  assign adder7_out = nxt8_sel[7:1];
endmodule

// -----------------------------------------------------------------------------
// golden 同名 wrapper：72 位余数向量的 f64 通道在 [71:12]，60 位除数向量的除数在 [59:3]
// -----------------------------------------------------------------------------
module fpdiv_r64_block (
  input  logic [71:0] io_f_r_s_i,
  input  logic [71:0] io_f_r_c_i,
  input  logic [59:0] io_divisor_i,
  input  logic [5:0]  io_nr_f_r_6b_for_nxt_cycle_s0_qds_i,
  input  logic [6:0]  io_nr_f_r_7b_for_nxt_cycle_s1_qds_i,
  output logic [4:0]  io_nxt_quo_dig_o_0_0,
  output logic [4:0]  io_nxt_quo_dig_o_0_1,
  output logic [4:0]  io_nxt_quo_dig_o_0_2,
  output logic [71:0] io_nxt_f_r_s_o_2,
  output logic [71:0] io_nxt_f_r_c_o_2,
  output logic [5:0]  io_adder_6b_res_for_nxt_cycle_s0_qds_o,
  output logic [6:0]  io_adder_7b_res_for_nxt_cycle_s1_qds_o
);
  logic [2:0][4:0] quo_dig;
  logic [59:0]     rem_s_out, rem_c_out;

  xs_fpdiv_r64_block_core u_core (
    .rem_s_in    (io_f_r_s_i[71:12]),
    .rem_c_in    (io_f_r_c_i[71:12]),
    .divisor     (io_divisor_i[59:3]),
    .rem6_for_s0 (io_nr_f_r_6b_for_nxt_cycle_s0_qds_i),
    .rem7_for_s1 (io_nr_f_r_7b_for_nxt_cycle_s1_qds_i),
    .quo_dig     (quo_dig),
    .rem_s_out   (rem_s_out),
    .rem_c_out   (rem_c_out),
    .adder6_out  (io_adder_6b_res_for_nxt_cycle_s0_qds_o),
    .adder7_out  (io_adder_7b_res_for_nxt_cycle_s1_qds_o)
  );

  assign io_nxt_quo_dig_o_0_0 = quo_dig[0];
  assign io_nxt_quo_dig_o_0_1 = quo_dig[1];
  assign io_nxt_quo_dig_o_0_2 = quo_dig[2];
  assign io_nxt_f_r_s_o_2     = {rem_s_out, 12'b0};
  assign io_nxt_f_r_c_o_2     = {rem_c_out, 12'b0};
endmodule
