// 自动生成：verif/ut/BoothEncoderF64F32F16/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// BoothEncoderF64F32F16 双例化逐拍比对：golden vs 重写 BoothEncoderF64F32F16_xs，27 个加数逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= BoothEncoderF64F32F16 =================
  int unsigned be_mode = 0;
  function automatic logic [52:0] be_rnd_sig();
    logic [52:0] d;
    d = {$urandom, $urandom};
    if ($urandom_range(0, 1) == 0) begin
      // f16 的四段：[10:0] [23:13] [39:29] [52:42]
      for (int l = 0; l < 4; l++) begin
        int lsb;
        logic [10:0] v;
        lsb = (l == 0) ? 0 : (l == 1) ? 13 : (l == 2) ? 29 : 42;
        case ($urandom_range(0, 7))
          0:       v = 11'h000;
          1:       v = 11'h7ff;
          2:       v = 11'h400;
          3:       v = 11'h001;
          4:       v = 11'h555;
          5:       v = 11'h2aa;
          default: v = 11'($urandom);
        endcase
        d[lsb +: 11] = v;
      end
    end
    return d;
  endfunction
  logic [52:0] be_io_in_a;
  logic [52:0] be_io_in_b;
  logic be_io_is_fp64;
  logic be_io_is_fp32;
  wire  [106:0] be_g_io_out_pp_0, be_i_io_out_pp_0;
  logic [106:0] be_s0_io_out_pp_0 = '0, be_s1_io_out_pp_0 = '0;
  wire  [106:0] be_g_io_out_pp_1, be_i_io_out_pp_1;
  logic [106:0] be_s0_io_out_pp_1 = '0, be_s1_io_out_pp_1 = '0;
  wire  [106:0] be_g_io_out_pp_2, be_i_io_out_pp_2;
  logic [106:0] be_s0_io_out_pp_2 = '0, be_s1_io_out_pp_2 = '0;
  wire  [106:0] be_g_io_out_pp_3, be_i_io_out_pp_3;
  logic [106:0] be_s0_io_out_pp_3 = '0, be_s1_io_out_pp_3 = '0;
  wire  [106:0] be_g_io_out_pp_4, be_i_io_out_pp_4;
  logic [106:0] be_s0_io_out_pp_4 = '0, be_s1_io_out_pp_4 = '0;
  wire  [106:0] be_g_io_out_pp_5, be_i_io_out_pp_5;
  logic [106:0] be_s0_io_out_pp_5 = '0, be_s1_io_out_pp_5 = '0;
  wire  [106:0] be_g_io_out_pp_6, be_i_io_out_pp_6;
  logic [106:0] be_s0_io_out_pp_6 = '0, be_s1_io_out_pp_6 = '0;
  wire  [106:0] be_g_io_out_pp_7, be_i_io_out_pp_7;
  logic [106:0] be_s0_io_out_pp_7 = '0, be_s1_io_out_pp_7 = '0;
  wire  [106:0] be_g_io_out_pp_8, be_i_io_out_pp_8;
  logic [106:0] be_s0_io_out_pp_8 = '0, be_s1_io_out_pp_8 = '0;
  wire  [106:0] be_g_io_out_pp_9, be_i_io_out_pp_9;
  logic [106:0] be_s0_io_out_pp_9 = '0, be_s1_io_out_pp_9 = '0;
  wire  [106:0] be_g_io_out_pp_10, be_i_io_out_pp_10;
  logic [106:0] be_s0_io_out_pp_10 = '0, be_s1_io_out_pp_10 = '0;
  wire  [106:0] be_g_io_out_pp_11, be_i_io_out_pp_11;
  logic [106:0] be_s0_io_out_pp_11 = '0, be_s1_io_out_pp_11 = '0;
  wire  [106:0] be_g_io_out_pp_12, be_i_io_out_pp_12;
  logic [106:0] be_s0_io_out_pp_12 = '0, be_s1_io_out_pp_12 = '0;
  wire  [106:0] be_g_io_out_pp_13, be_i_io_out_pp_13;
  logic [106:0] be_s0_io_out_pp_13 = '0, be_s1_io_out_pp_13 = '0;
  wire  [106:0] be_g_io_out_pp_14, be_i_io_out_pp_14;
  logic [106:0] be_s0_io_out_pp_14 = '0, be_s1_io_out_pp_14 = '0;
  wire  [106:0] be_g_io_out_pp_15, be_i_io_out_pp_15;
  logic [106:0] be_s0_io_out_pp_15 = '0, be_s1_io_out_pp_15 = '0;
  wire  [106:0] be_g_io_out_pp_16, be_i_io_out_pp_16;
  logic [106:0] be_s0_io_out_pp_16 = '0, be_s1_io_out_pp_16 = '0;
  wire  [106:0] be_g_io_out_pp_17, be_i_io_out_pp_17;
  logic [106:0] be_s0_io_out_pp_17 = '0, be_s1_io_out_pp_17 = '0;
  wire  [106:0] be_g_io_out_pp_18, be_i_io_out_pp_18;
  logic [106:0] be_s0_io_out_pp_18 = '0, be_s1_io_out_pp_18 = '0;
  wire  [106:0] be_g_io_out_pp_19, be_i_io_out_pp_19;
  logic [106:0] be_s0_io_out_pp_19 = '0, be_s1_io_out_pp_19 = '0;
  wire  [106:0] be_g_io_out_pp_20, be_i_io_out_pp_20;
  logic [106:0] be_s0_io_out_pp_20 = '0, be_s1_io_out_pp_20 = '0;
  wire  [106:0] be_g_io_out_pp_21, be_i_io_out_pp_21;
  logic [106:0] be_s0_io_out_pp_21 = '0, be_s1_io_out_pp_21 = '0;
  wire  [106:0] be_g_io_out_pp_22, be_i_io_out_pp_22;
  logic [106:0] be_s0_io_out_pp_22 = '0, be_s1_io_out_pp_22 = '0;
  wire  [106:0] be_g_io_out_pp_23, be_i_io_out_pp_23;
  logic [106:0] be_s0_io_out_pp_23 = '0, be_s1_io_out_pp_23 = '0;
  wire  [106:0] be_g_io_out_pp_24, be_i_io_out_pp_24;
  logic [106:0] be_s0_io_out_pp_24 = '0, be_s1_io_out_pp_24 = '0;
  wire  [106:0] be_g_io_out_pp_25, be_i_io_out_pp_25;
  logic [106:0] be_s0_io_out_pp_25 = '0, be_s1_io_out_pp_25 = '0;
  wire  [106:0] be_g_io_out_pp_26, be_i_io_out_pp_26;
  logic [106:0] be_s0_io_out_pp_26 = '0, be_s1_io_out_pp_26 = '0;
  int be_cov_fmt_f64 = 0;
  int be_cov_fmt_f32 = 0;
  int be_cov_fmt_f16 = 0;
  int be_cov_fmt_both = 0;
  int be_cov_d0_pos1 = 0;
  int be_cov_d0_neg1 = 0;
  int be_cov_d0_neg2 = 0;
  int be_cov_d1_pos1 = 0;
  int be_cov_d1_pos2 = 0;
  int be_cov_d1_neg1 = 0;
  int be_cov_d1_neg2 = 0;
  int be_cov_d2_pos1 = 0;
  int be_cov_d2_pos2 = 0;
  int be_cov_d2_neg1 = 0;
  int be_cov_d2_neg2 = 0;
  int be_cov_d3_pos1 = 0;
  int be_cov_d3_pos2 = 0;
  int be_cov_d3_neg1 = 0;
  int be_cov_d3_neg2 = 0;
  int be_cov_d4_pos1 = 0;
  int be_cov_d4_pos2 = 0;
  int be_cov_d4_neg1 = 0;
  int be_cov_d4_neg2 = 0;
  int be_cov_d5_pos1 = 0;
  int be_cov_d5_pos2 = 0;
  int be_cov_d5_neg1 = 0;
  int be_cov_d5_neg2 = 0;
  int be_cov_d6_pos1 = 0;
  int be_cov_d6_pos2 = 0;
  int be_cov_d6_neg1 = 0;
  int be_cov_d6_neg2 = 0;
  int be_cov_d7_pos1 = 0;
  int be_cov_d7_pos2 = 0;
  int be_cov_d7_neg1 = 0;
  int be_cov_d7_neg2 = 0;
  int be_cov_d8_pos1 = 0;
  int be_cov_d8_pos2 = 0;
  int be_cov_d8_neg1 = 0;
  int be_cov_d8_neg2 = 0;
  int be_cov_d9_pos1 = 0;
  int be_cov_d9_pos2 = 0;
  int be_cov_d9_neg1 = 0;
  int be_cov_d9_neg2 = 0;
  int be_cov_d10_pos1 = 0;
  int be_cov_d10_pos2 = 0;
  int be_cov_d10_neg1 = 0;
  int be_cov_d10_neg2 = 0;
  int be_cov_d11_pos1 = 0;
  int be_cov_d11_pos2 = 0;
  int be_cov_d11_neg1 = 0;
  int be_cov_d11_neg2 = 0;
  int be_cov_d12_pos1 = 0;
  int be_cov_d12_pos2 = 0;
  int be_cov_d12_neg1 = 0;
  int be_cov_d12_neg2 = 0;
  int be_cov_d13_pos1 = 0;
  int be_cov_d13_pos2 = 0;
  int be_cov_d13_neg1 = 0;
  int be_cov_d13_neg2 = 0;
  int be_cov_d14_pos1 = 0;
  int be_cov_d14_pos2 = 0;
  int be_cov_d14_neg1 = 0;
  int be_cov_d14_neg2 = 0;
  int be_cov_d15_pos1 = 0;
  int be_cov_d15_pos2 = 0;
  int be_cov_d15_neg1 = 0;
  int be_cov_d15_neg2 = 0;
  int be_cov_d16_pos1 = 0;
  int be_cov_d16_pos2 = 0;
  int be_cov_d16_neg1 = 0;
  int be_cov_d16_neg2 = 0;
  int be_cov_d17_pos1 = 0;
  int be_cov_d17_pos2 = 0;
  int be_cov_d17_neg1 = 0;
  int be_cov_d17_neg2 = 0;
  int be_cov_d18_pos1 = 0;
  int be_cov_d18_pos2 = 0;
  int be_cov_d18_neg1 = 0;
  int be_cov_d18_neg2 = 0;
  int be_cov_d19_pos1 = 0;
  int be_cov_d19_pos2 = 0;
  int be_cov_d19_neg1 = 0;
  int be_cov_d19_neg2 = 0;
  int be_cov_d20_pos1 = 0;
  int be_cov_d20_pos2 = 0;
  int be_cov_d20_neg1 = 0;
  int be_cov_d20_neg2 = 0;
  int be_cov_d21_pos1 = 0;
  int be_cov_d21_pos2 = 0;
  int be_cov_d21_neg1 = 0;
  int be_cov_d21_neg2 = 0;
  int be_cov_d22_pos1 = 0;
  int be_cov_d22_pos2 = 0;
  int be_cov_d22_neg1 = 0;
  int be_cov_d22_neg2 = 0;
  int be_cov_d23_pos1 = 0;
  int be_cov_d23_pos2 = 0;
  int be_cov_d23_neg1 = 0;
  int be_cov_d23_neg2 = 0;
  int be_cov_d24_pos1 = 0;
  int be_cov_d24_pos2 = 0;
  int be_cov_d24_neg1 = 0;
  int be_cov_d24_neg2 = 0;
  int be_cov_d25_pos1 = 0;
  int be_cov_d25_pos2 = 0;
  int be_cov_d25_neg1 = 0;
  int be_cov_d25_neg2 = 0;
  int be_cov_d26_pos1 = 0;
  int be_cov_d26_pos2 = 0;
  logic [0:0] be_armed = '0;
  int be_armed_at = -1;
  BoothEncoderF64F32F16 be_u_gold (
    .io_in_a(be_io_in_a),
    .io_in_b(be_io_in_b),
    .io_is_fp64(be_io_is_fp64),
    .io_is_fp32(be_io_is_fp32),
    .io_out_pp_0(be_g_io_out_pp_0),
    .io_out_pp_1(be_g_io_out_pp_1),
    .io_out_pp_2(be_g_io_out_pp_2),
    .io_out_pp_3(be_g_io_out_pp_3),
    .io_out_pp_4(be_g_io_out_pp_4),
    .io_out_pp_5(be_g_io_out_pp_5),
    .io_out_pp_6(be_g_io_out_pp_6),
    .io_out_pp_7(be_g_io_out_pp_7),
    .io_out_pp_8(be_g_io_out_pp_8),
    .io_out_pp_9(be_g_io_out_pp_9),
    .io_out_pp_10(be_g_io_out_pp_10),
    .io_out_pp_11(be_g_io_out_pp_11),
    .io_out_pp_12(be_g_io_out_pp_12),
    .io_out_pp_13(be_g_io_out_pp_13),
    .io_out_pp_14(be_g_io_out_pp_14),
    .io_out_pp_15(be_g_io_out_pp_15),
    .io_out_pp_16(be_g_io_out_pp_16),
    .io_out_pp_17(be_g_io_out_pp_17),
    .io_out_pp_18(be_g_io_out_pp_18),
    .io_out_pp_19(be_g_io_out_pp_19),
    .io_out_pp_20(be_g_io_out_pp_20),
    .io_out_pp_21(be_g_io_out_pp_21),
    .io_out_pp_22(be_g_io_out_pp_22),
    .io_out_pp_23(be_g_io_out_pp_23),
    .io_out_pp_24(be_g_io_out_pp_24),
    .io_out_pp_25(be_g_io_out_pp_25),
    .io_out_pp_26(be_g_io_out_pp_26)
  );
  BoothEncoderF64F32F16_xs be_u_impl (
    .io_in_a(be_io_in_a),
    .io_in_b(be_io_in_b),
    .io_is_fp64(be_io_is_fp64),
    .io_is_fp32(be_io_is_fp32),
    .io_out_pp_0(be_i_io_out_pp_0),
    .io_out_pp_1(be_i_io_out_pp_1),
    .io_out_pp_2(be_i_io_out_pp_2),
    .io_out_pp_3(be_i_io_out_pp_3),
    .io_out_pp_4(be_i_io_out_pp_4),
    .io_out_pp_5(be_i_io_out_pp_5),
    .io_out_pp_6(be_i_io_out_pp_6),
    .io_out_pp_7(be_i_io_out_pp_7),
    .io_out_pp_8(be_i_io_out_pp_8),
    .io_out_pp_9(be_i_io_out_pp_9),
    .io_out_pp_10(be_i_io_out_pp_10),
    .io_out_pp_11(be_i_io_out_pp_11),
    .io_out_pp_12(be_i_io_out_pp_12),
    .io_out_pp_13(be_i_io_out_pp_13),
    .io_out_pp_14(be_i_io_out_pp_14),
    .io_out_pp_15(be_i_io_out_pp_15),
    .io_out_pp_16(be_i_io_out_pp_16),
    .io_out_pp_17(be_i_io_out_pp_17),
    .io_out_pp_18(be_i_io_out_pp_18),
    .io_out_pp_19(be_i_io_out_pp_19),
    .io_out_pp_20(be_i_io_out_pp_20),
    .io_out_pp_21(be_i_io_out_pp_21),
    .io_out_pp_22(be_i_io_out_pp_22),
    .io_out_pp_23(be_i_io_out_pp_23),
    .io_out_pp_24(be_i_io_out_pp_24),
    .io_out_pp_25(be_i_io_out_pp_25),
    .io_out_pp_26(be_i_io_out_pp_26)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) be_mode = $urandom_range(0, 15);
      be_io_in_a = 53'({$urandom, $urandom});
      be_io_in_b = 53'({$urandom, $urandom});
      be_io_is_fp64 = 1'($urandom);
      be_io_is_fp32 = 1'($urandom);
      begin : stim_be
        be_io_in_a = be_rnd_sig();
        be_io_in_b = be_rnd_sig();
        if ($urandom_range(0, 15) != 0) begin
          case ($urandom_range(0, 2))
            0:       begin be_io_is_fp64 = 1'b1; be_io_is_fp32 = 1'b0; end
            1:       begin be_io_is_fp64 = 1'b0; be_io_is_fp32 = 1'b1; end
            default: begin be_io_is_fp64 = 1'b0; be_io_is_fp32 = 1'b0; end
          endcase
        end
      end
      #4;
      be_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&be_armed)) begin
        checks++;
        if (be_g_io_out_pp_0 !== be_i_io_out_pp_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_0 g=%h i=%h", cyc, be_g_io_out_pp_0, be_i_io_out_pp_0);
        end
        be_s1_io_out_pp_0 |= be_g_io_out_pp_0;
        be_s0_io_out_pp_0 |= ~be_g_io_out_pp_0;
        checks++;
        if (be_g_io_out_pp_1 !== be_i_io_out_pp_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_1 g=%h i=%h", cyc, be_g_io_out_pp_1, be_i_io_out_pp_1);
        end
        be_s1_io_out_pp_1 |= be_g_io_out_pp_1;
        be_s0_io_out_pp_1 |= ~be_g_io_out_pp_1;
        checks++;
        if (be_g_io_out_pp_2 !== be_i_io_out_pp_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_2 g=%h i=%h", cyc, be_g_io_out_pp_2, be_i_io_out_pp_2);
        end
        be_s1_io_out_pp_2 |= be_g_io_out_pp_2;
        be_s0_io_out_pp_2 |= ~be_g_io_out_pp_2;
        checks++;
        if (be_g_io_out_pp_3 !== be_i_io_out_pp_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_3 g=%h i=%h", cyc, be_g_io_out_pp_3, be_i_io_out_pp_3);
        end
        be_s1_io_out_pp_3 |= be_g_io_out_pp_3;
        be_s0_io_out_pp_3 |= ~be_g_io_out_pp_3;
        checks++;
        if (be_g_io_out_pp_4 !== be_i_io_out_pp_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_4 g=%h i=%h", cyc, be_g_io_out_pp_4, be_i_io_out_pp_4);
        end
        be_s1_io_out_pp_4 |= be_g_io_out_pp_4;
        be_s0_io_out_pp_4 |= ~be_g_io_out_pp_4;
        checks++;
        if (be_g_io_out_pp_5 !== be_i_io_out_pp_5) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_5 g=%h i=%h", cyc, be_g_io_out_pp_5, be_i_io_out_pp_5);
        end
        be_s1_io_out_pp_5 |= be_g_io_out_pp_5;
        be_s0_io_out_pp_5 |= ~be_g_io_out_pp_5;
        checks++;
        if (be_g_io_out_pp_6 !== be_i_io_out_pp_6) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_6 g=%h i=%h", cyc, be_g_io_out_pp_6, be_i_io_out_pp_6);
        end
        be_s1_io_out_pp_6 |= be_g_io_out_pp_6;
        be_s0_io_out_pp_6 |= ~be_g_io_out_pp_6;
        checks++;
        if (be_g_io_out_pp_7 !== be_i_io_out_pp_7) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_7 g=%h i=%h", cyc, be_g_io_out_pp_7, be_i_io_out_pp_7);
        end
        be_s1_io_out_pp_7 |= be_g_io_out_pp_7;
        be_s0_io_out_pp_7 |= ~be_g_io_out_pp_7;
        checks++;
        if (be_g_io_out_pp_8 !== be_i_io_out_pp_8) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_8 g=%h i=%h", cyc, be_g_io_out_pp_8, be_i_io_out_pp_8);
        end
        be_s1_io_out_pp_8 |= be_g_io_out_pp_8;
        be_s0_io_out_pp_8 |= ~be_g_io_out_pp_8;
        checks++;
        if (be_g_io_out_pp_9 !== be_i_io_out_pp_9) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_9 g=%h i=%h", cyc, be_g_io_out_pp_9, be_i_io_out_pp_9);
        end
        be_s1_io_out_pp_9 |= be_g_io_out_pp_9;
        be_s0_io_out_pp_9 |= ~be_g_io_out_pp_9;
        checks++;
        if (be_g_io_out_pp_10 !== be_i_io_out_pp_10) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_10 g=%h i=%h", cyc, be_g_io_out_pp_10, be_i_io_out_pp_10);
        end
        be_s1_io_out_pp_10 |= be_g_io_out_pp_10;
        be_s0_io_out_pp_10 |= ~be_g_io_out_pp_10;
        checks++;
        if (be_g_io_out_pp_11 !== be_i_io_out_pp_11) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_11 g=%h i=%h", cyc, be_g_io_out_pp_11, be_i_io_out_pp_11);
        end
        be_s1_io_out_pp_11 |= be_g_io_out_pp_11;
        be_s0_io_out_pp_11 |= ~be_g_io_out_pp_11;
        checks++;
        if (be_g_io_out_pp_12 !== be_i_io_out_pp_12) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_12 g=%h i=%h", cyc, be_g_io_out_pp_12, be_i_io_out_pp_12);
        end
        be_s1_io_out_pp_12 |= be_g_io_out_pp_12;
        be_s0_io_out_pp_12 |= ~be_g_io_out_pp_12;
        checks++;
        if (be_g_io_out_pp_13 !== be_i_io_out_pp_13) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_13 g=%h i=%h", cyc, be_g_io_out_pp_13, be_i_io_out_pp_13);
        end
        be_s1_io_out_pp_13 |= be_g_io_out_pp_13;
        be_s0_io_out_pp_13 |= ~be_g_io_out_pp_13;
        checks++;
        if (be_g_io_out_pp_14 !== be_i_io_out_pp_14) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_14 g=%h i=%h", cyc, be_g_io_out_pp_14, be_i_io_out_pp_14);
        end
        be_s1_io_out_pp_14 |= be_g_io_out_pp_14;
        be_s0_io_out_pp_14 |= ~be_g_io_out_pp_14;
        checks++;
        if (be_g_io_out_pp_15 !== be_i_io_out_pp_15) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_15 g=%h i=%h", cyc, be_g_io_out_pp_15, be_i_io_out_pp_15);
        end
        be_s1_io_out_pp_15 |= be_g_io_out_pp_15;
        be_s0_io_out_pp_15 |= ~be_g_io_out_pp_15;
        checks++;
        if (be_g_io_out_pp_16 !== be_i_io_out_pp_16) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_16 g=%h i=%h", cyc, be_g_io_out_pp_16, be_i_io_out_pp_16);
        end
        be_s1_io_out_pp_16 |= be_g_io_out_pp_16;
        be_s0_io_out_pp_16 |= ~be_g_io_out_pp_16;
        checks++;
        if (be_g_io_out_pp_17 !== be_i_io_out_pp_17) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_17 g=%h i=%h", cyc, be_g_io_out_pp_17, be_i_io_out_pp_17);
        end
        be_s1_io_out_pp_17 |= be_g_io_out_pp_17;
        be_s0_io_out_pp_17 |= ~be_g_io_out_pp_17;
        checks++;
        if (be_g_io_out_pp_18 !== be_i_io_out_pp_18) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_18 g=%h i=%h", cyc, be_g_io_out_pp_18, be_i_io_out_pp_18);
        end
        be_s1_io_out_pp_18 |= be_g_io_out_pp_18;
        be_s0_io_out_pp_18 |= ~be_g_io_out_pp_18;
        checks++;
        if (be_g_io_out_pp_19 !== be_i_io_out_pp_19) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_19 g=%h i=%h", cyc, be_g_io_out_pp_19, be_i_io_out_pp_19);
        end
        be_s1_io_out_pp_19 |= be_g_io_out_pp_19;
        be_s0_io_out_pp_19 |= ~be_g_io_out_pp_19;
        checks++;
        if (be_g_io_out_pp_20 !== be_i_io_out_pp_20) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_20 g=%h i=%h", cyc, be_g_io_out_pp_20, be_i_io_out_pp_20);
        end
        be_s1_io_out_pp_20 |= be_g_io_out_pp_20;
        be_s0_io_out_pp_20 |= ~be_g_io_out_pp_20;
        checks++;
        if (be_g_io_out_pp_21 !== be_i_io_out_pp_21) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_21 g=%h i=%h", cyc, be_g_io_out_pp_21, be_i_io_out_pp_21);
        end
        be_s1_io_out_pp_21 |= be_g_io_out_pp_21;
        be_s0_io_out_pp_21 |= ~be_g_io_out_pp_21;
        checks++;
        if (be_g_io_out_pp_22 !== be_i_io_out_pp_22) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_22 g=%h i=%h", cyc, be_g_io_out_pp_22, be_i_io_out_pp_22);
        end
        be_s1_io_out_pp_22 |= be_g_io_out_pp_22;
        be_s0_io_out_pp_22 |= ~be_g_io_out_pp_22;
        checks++;
        if (be_g_io_out_pp_23 !== be_i_io_out_pp_23) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_23 g=%h i=%h", cyc, be_g_io_out_pp_23, be_i_io_out_pp_23);
        end
        be_s1_io_out_pp_23 |= be_g_io_out_pp_23;
        be_s0_io_out_pp_23 |= ~be_g_io_out_pp_23;
        checks++;
        if (be_g_io_out_pp_24 !== be_i_io_out_pp_24) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_24 g=%h i=%h", cyc, be_g_io_out_pp_24, be_i_io_out_pp_24);
        end
        be_s1_io_out_pp_24 |= be_g_io_out_pp_24;
        be_s0_io_out_pp_24 |= ~be_g_io_out_pp_24;
        checks++;
        if (be_g_io_out_pp_25 !== be_i_io_out_pp_25) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_25 g=%h i=%h", cyc, be_g_io_out_pp_25, be_i_io_out_pp_25);
        end
        be_s1_io_out_pp_25 |= be_g_io_out_pp_25;
        be_s0_io_out_pp_25 |= ~be_g_io_out_pp_25;
        checks++;
        if (be_g_io_out_pp_26 !== be_i_io_out_pp_26) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BoothEncoderF64F32F16.io_out_pp_26 g=%h i=%h", cyc, be_g_io_out_pp_26, be_i_io_out_pp_26);
        end
        be_s1_io_out_pp_26 |= be_g_io_out_pp_26;
        be_s0_io_out_pp_26 |= ~be_g_io_out_pp_26;
        if (be_io_is_fp64 && !be_io_is_fp32) be_cov_fmt_f64++;
        if (!be_io_is_fp64 && be_io_is_fp32) be_cov_fmt_f32++;
        if (!be_io_is_fp64 && !be_io_is_fp32) be_cov_fmt_f16++;
        if (be_io_is_fp64 && be_io_is_fp32) be_cov_fmt_both++;
        if (be_u_gold.booth_4bit_onehot_0[3]) be_cov_d0_pos1++;
        if (be_u_gold.booth_4bit_onehot_0[1]) be_cov_d0_neg1++;
        if (be_u_gold.booth_4bit_onehot_0[0]) be_cov_d0_neg2++;
        if (be_u_gold.booth_4bit_onehot_1[3]) be_cov_d1_pos1++;
        if (be_u_gold.booth_4bit_onehot_1[2]) be_cov_d1_pos2++;
        if (be_u_gold.booth_4bit_onehot_1[1]) be_cov_d1_neg1++;
        if (be_u_gold.booth_4bit_onehot_1[0]) be_cov_d1_neg2++;
        if (be_u_gold.booth_4bit_onehot_2[3]) be_cov_d2_pos1++;
        if (be_u_gold.booth_4bit_onehot_2[2]) be_cov_d2_pos2++;
        if (be_u_gold.booth_4bit_onehot_2[1]) be_cov_d2_neg1++;
        if (be_u_gold.booth_4bit_onehot_2[0]) be_cov_d2_neg2++;
        if (be_u_gold.booth_4bit_onehot_3[3]) be_cov_d3_pos1++;
        if (be_u_gold.booth_4bit_onehot_3[2]) be_cov_d3_pos2++;
        if (be_u_gold.booth_4bit_onehot_3[1]) be_cov_d3_neg1++;
        if (be_u_gold.booth_4bit_onehot_3[0]) be_cov_d3_neg2++;
        if (be_u_gold.booth_4bit_onehot_4[3]) be_cov_d4_pos1++;
        if (be_u_gold.booth_4bit_onehot_4[2]) be_cov_d4_pos2++;
        if (be_u_gold.booth_4bit_onehot_4[1]) be_cov_d4_neg1++;
        if (be_u_gold.booth_4bit_onehot_4[0]) be_cov_d4_neg2++;
        if (be_u_gold.booth_4bit_onehot_5[3]) be_cov_d5_pos1++;
        if (be_u_gold.booth_4bit_onehot_5[2]) be_cov_d5_pos2++;
        if (be_u_gold.booth_4bit_onehot_5[1]) be_cov_d5_neg1++;
        if (be_u_gold.booth_4bit_onehot_5[0]) be_cov_d5_neg2++;
        if (be_u_gold.booth_4bit_onehot_6[3]) be_cov_d6_pos1++;
        if (be_u_gold.booth_4bit_onehot_6[2]) be_cov_d6_pos2++;
        if (be_u_gold.booth_4bit_onehot_6[1]) be_cov_d6_neg1++;
        if (be_u_gold.booth_4bit_onehot_6[0]) be_cov_d6_neg2++;
        if (be_u_gold.booth_4bit_onehot_7[3]) be_cov_d7_pos1++;
        if (be_u_gold.booth_4bit_onehot_7[2]) be_cov_d7_pos2++;
        if (be_u_gold.booth_4bit_onehot_7[1]) be_cov_d7_neg1++;
        if (be_u_gold.booth_4bit_onehot_7[0]) be_cov_d7_neg2++;
        if (be_u_gold.booth_4bit_onehot_8[3]) be_cov_d8_pos1++;
        if (be_u_gold.booth_4bit_onehot_8[2]) be_cov_d8_pos2++;
        if (be_u_gold.booth_4bit_onehot_8[1]) be_cov_d8_neg1++;
        if (be_u_gold.booth_4bit_onehot_8[0]) be_cov_d8_neg2++;
        if (be_u_gold.booth_4bit_onehot_9[3]) be_cov_d9_pos1++;
        if (be_u_gold.booth_4bit_onehot_9[2]) be_cov_d9_pos2++;
        if (be_u_gold.booth_4bit_onehot_9[1]) be_cov_d9_neg1++;
        if (be_u_gold.booth_4bit_onehot_9[0]) be_cov_d9_neg2++;
        if (be_u_gold.booth_4bit_onehot_10[3]) be_cov_d10_pos1++;
        if (be_u_gold.booth_4bit_onehot_10[2]) be_cov_d10_pos2++;
        if (be_u_gold.booth_4bit_onehot_10[1]) be_cov_d10_neg1++;
        if (be_u_gold.booth_4bit_onehot_10[0]) be_cov_d10_neg2++;
        if (be_u_gold.booth_4bit_onehot_11[3]) be_cov_d11_pos1++;
        if (be_u_gold.booth_4bit_onehot_11[2]) be_cov_d11_pos2++;
        if (be_u_gold.booth_4bit_onehot_11[1]) be_cov_d11_neg1++;
        if (be_u_gold.booth_4bit_onehot_11[0]) be_cov_d11_neg2++;
        if (be_u_gold.booth_4bit_onehot_12[3]) be_cov_d12_pos1++;
        if (be_u_gold.booth_4bit_onehot_12[2]) be_cov_d12_pos2++;
        if (be_u_gold.booth_4bit_onehot_12[1]) be_cov_d12_neg1++;
        if (be_u_gold.booth_4bit_onehot_12[0]) be_cov_d12_neg2++;
        if (be_u_gold.booth_4bit_onehot_13[3]) be_cov_d13_pos1++;
        if (be_u_gold.booth_4bit_onehot_13[2]) be_cov_d13_pos2++;
        if (be_u_gold.booth_4bit_onehot_13[1]) be_cov_d13_neg1++;
        if (be_u_gold.booth_4bit_onehot_13[0]) be_cov_d13_neg2++;
        if (be_u_gold.booth_4bit_onehot_14[3]) be_cov_d14_pos1++;
        if (be_u_gold.booth_4bit_onehot_14[2]) be_cov_d14_pos2++;
        if (be_u_gold.booth_4bit_onehot_14[1]) be_cov_d14_neg1++;
        if (be_u_gold.booth_4bit_onehot_14[0]) be_cov_d14_neg2++;
        if (be_u_gold.booth_4bit_onehot_15[3]) be_cov_d15_pos1++;
        if (be_u_gold.booth_4bit_onehot_15[2]) be_cov_d15_pos2++;
        if (be_u_gold.booth_4bit_onehot_15[1]) be_cov_d15_neg1++;
        if (be_u_gold.booth_4bit_onehot_15[0]) be_cov_d15_neg2++;
        if (be_u_gold.booth_4bit_onehot_16[3]) be_cov_d16_pos1++;
        if (be_u_gold.booth_4bit_onehot_16[2]) be_cov_d16_pos2++;
        if (be_u_gold.booth_4bit_onehot_16[1]) be_cov_d16_neg1++;
        if (be_u_gold.booth_4bit_onehot_16[0]) be_cov_d16_neg2++;
        if (be_u_gold.booth_4bit_onehot_17[3]) be_cov_d17_pos1++;
        if (be_u_gold.booth_4bit_onehot_17[2]) be_cov_d17_pos2++;
        if (be_u_gold.booth_4bit_onehot_17[1]) be_cov_d17_neg1++;
        if (be_u_gold.booth_4bit_onehot_17[0]) be_cov_d17_neg2++;
        if (be_u_gold.booth_4bit_onehot_18[3]) be_cov_d18_pos1++;
        if (be_u_gold.booth_4bit_onehot_18[2]) be_cov_d18_pos2++;
        if (be_u_gold.booth_4bit_onehot_18[1]) be_cov_d18_neg1++;
        if (be_u_gold.booth_4bit_onehot_18[0]) be_cov_d18_neg2++;
        if (be_u_gold.booth_4bit_onehot_19[3]) be_cov_d19_pos1++;
        if (be_u_gold.booth_4bit_onehot_19[2]) be_cov_d19_pos2++;
        if (be_u_gold.booth_4bit_onehot_19[1]) be_cov_d19_neg1++;
        if (be_u_gold.booth_4bit_onehot_19[0]) be_cov_d19_neg2++;
        if (be_u_gold.booth_4bit_onehot_20[3]) be_cov_d20_pos1++;
        if (be_u_gold.booth_4bit_onehot_20[2]) be_cov_d20_pos2++;
        if (be_u_gold.booth_4bit_onehot_20[1]) be_cov_d20_neg1++;
        if (be_u_gold.booth_4bit_onehot_20[0]) be_cov_d20_neg2++;
        if (be_u_gold.booth_4bit_onehot_21[3]) be_cov_d21_pos1++;
        if (be_u_gold.booth_4bit_onehot_21[2]) be_cov_d21_pos2++;
        if (be_u_gold.booth_4bit_onehot_21[1]) be_cov_d21_neg1++;
        if (be_u_gold.booth_4bit_onehot_21[0]) be_cov_d21_neg2++;
        if (be_u_gold.booth_4bit_onehot_22[3]) be_cov_d22_pos1++;
        if (be_u_gold.booth_4bit_onehot_22[2]) be_cov_d22_pos2++;
        if (be_u_gold.booth_4bit_onehot_22[1]) be_cov_d22_neg1++;
        if (be_u_gold.booth_4bit_onehot_22[0]) be_cov_d22_neg2++;
        if (be_u_gold.booth_4bit_onehot_23[3]) be_cov_d23_pos1++;
        if (be_u_gold.booth_4bit_onehot_23[2]) be_cov_d23_pos2++;
        if (be_u_gold.booth_4bit_onehot_23[1]) be_cov_d23_neg1++;
        if (be_u_gold.booth_4bit_onehot_23[0]) be_cov_d23_neg2++;
        if (be_u_gold.booth_4bit_onehot_24[3]) be_cov_d24_pos1++;
        if (be_u_gold.booth_4bit_onehot_24[2]) be_cov_d24_pos2++;
        if (be_u_gold.booth_4bit_onehot_24[1]) be_cov_d24_neg1++;
        if (be_u_gold.booth_4bit_onehot_24[0]) be_cov_d24_neg2++;
        if (be_u_gold.booth_4bit_onehot_25[3]) be_cov_d25_pos1++;
        if (be_u_gold.booth_4bit_onehot_25[2]) be_cov_d25_pos2++;
        if (be_u_gold.booth_4bit_onehot_25[1]) be_cov_d25_neg1++;
        if (be_u_gold.booth_4bit_onehot_25[0]) be_cov_d25_neg2++;
        if (be_u_gold.booth_4bit_onehot_26[3]) be_cov_d26_pos1++;
        if (be_u_gold.booth_4bit_onehot_26[2]) be_cov_d26_pos2++;
      end
      if (be_armed_at < 0 && (&be_armed)) be_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(be_s0_io_out_pp_0[0] && be_s1_io_out_pp_0[0])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[0] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[1] && be_s1_io_out_pp_0[1])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[1] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[2] && be_s1_io_out_pp_0[2])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[2] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[3] && be_s1_io_out_pp_0[3])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[3] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[4] && be_s1_io_out_pp_0[4])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[4] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[5] && be_s1_io_out_pp_0[5])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[5] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[6] && be_s1_io_out_pp_0[6])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[6] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[7] && be_s1_io_out_pp_0[7])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[7] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[8] && be_s1_io_out_pp_0[8])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[8] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[9] && be_s1_io_out_pp_0[9])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[9] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[10] && be_s1_io_out_pp_0[10])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[10] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[11] && be_s1_io_out_pp_0[11])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[11] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[12] && be_s1_io_out_pp_0[12])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[12] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[13] && be_s1_io_out_pp_0[13])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[13] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[14] && be_s1_io_out_pp_0[14])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[14] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[15] && be_s1_io_out_pp_0[15])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[15] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[16] && be_s1_io_out_pp_0[16])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[16] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[17] && be_s1_io_out_pp_0[17])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[17] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[18] && be_s1_io_out_pp_0[18])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[18] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[19] && be_s1_io_out_pp_0[19])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[19] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[20] && be_s1_io_out_pp_0[20])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[20] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[21] && be_s1_io_out_pp_0[21])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[21] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[22] && be_s1_io_out_pp_0[22])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[22] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[23] && be_s1_io_out_pp_0[23])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[23] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[24] && be_s1_io_out_pp_0[24])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[24] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[25] && be_s1_io_out_pp_0[25])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[25] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[26] && be_s1_io_out_pp_0[26])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[26] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[27] && be_s1_io_out_pp_0[27])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[27] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[28] && be_s1_io_out_pp_0[28])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[28] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[29] && be_s1_io_out_pp_0[29])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[29] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[30] && be_s1_io_out_pp_0[30])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[30] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[31] && be_s1_io_out_pp_0[31])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[31] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[32] && be_s1_io_out_pp_0[32])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[32] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[33] && be_s1_io_out_pp_0[33])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[33] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[34] && be_s1_io_out_pp_0[34])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[34] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[35] && be_s1_io_out_pp_0[35])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[35] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[36] && be_s1_io_out_pp_0[36])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[36] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[37] && be_s1_io_out_pp_0[37])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[37] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[38] && be_s1_io_out_pp_0[38])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[38] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[39] && be_s1_io_out_pp_0[39])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[39] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[40] && be_s1_io_out_pp_0[40])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[40] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[41] && be_s1_io_out_pp_0[41])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[41] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[42] && be_s1_io_out_pp_0[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[43] && be_s1_io_out_pp_0[43])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[43] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[44] && be_s1_io_out_pp_0[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[45] && be_s1_io_out_pp_0[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[46] && be_s1_io_out_pp_0[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[47] && be_s1_io_out_pp_0[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[48] && be_s1_io_out_pp_0[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[49] && be_s1_io_out_pp_0[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[50] && be_s1_io_out_pp_0[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[51] && be_s1_io_out_pp_0[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[52] && be_s1_io_out_pp_0[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[53] && be_s1_io_out_pp_0[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[54] && be_s1_io_out_pp_0[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[55] && be_s1_io_out_pp_0[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_0[56] && be_s1_io_out_pp_0[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_0[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[0] && be_s1_io_out_pp_1[0])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[0] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[2] && be_s1_io_out_pp_1[2])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[2] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[3] && be_s1_io_out_pp_1[3])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[3] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[4] && be_s1_io_out_pp_1[4])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[4] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[5] && be_s1_io_out_pp_1[5])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[5] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[6] && be_s1_io_out_pp_1[6])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[6] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[7] && be_s1_io_out_pp_1[7])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[7] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[8] && be_s1_io_out_pp_1[8])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[8] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[9] && be_s1_io_out_pp_1[9])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[9] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[10] && be_s1_io_out_pp_1[10])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[10] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[11] && be_s1_io_out_pp_1[11])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[11] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[12] && be_s1_io_out_pp_1[12])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[12] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[13] && be_s1_io_out_pp_1[13])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[13] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[14] && be_s1_io_out_pp_1[14])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[14] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[15] && be_s1_io_out_pp_1[15])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[15] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[16] && be_s1_io_out_pp_1[16])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[16] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[17] && be_s1_io_out_pp_1[17])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[17] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[18] && be_s1_io_out_pp_1[18])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[18] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[19] && be_s1_io_out_pp_1[19])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[19] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[20] && be_s1_io_out_pp_1[20])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[20] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[21] && be_s1_io_out_pp_1[21])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[21] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[22] && be_s1_io_out_pp_1[22])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[22] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[23] && be_s1_io_out_pp_1[23])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[23] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[24] && be_s1_io_out_pp_1[24])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[24] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[25] && be_s1_io_out_pp_1[25])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[25] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[26] && be_s1_io_out_pp_1[26])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[26] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[27] && be_s1_io_out_pp_1[27])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[27] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[28] && be_s1_io_out_pp_1[28])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[28] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[29] && be_s1_io_out_pp_1[29])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[29] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[30] && be_s1_io_out_pp_1[30])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[30] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[31] && be_s1_io_out_pp_1[31])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[31] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[32] && be_s1_io_out_pp_1[32])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[32] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[33] && be_s1_io_out_pp_1[33])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[33] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[34] && be_s1_io_out_pp_1[34])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[34] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[35] && be_s1_io_out_pp_1[35])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[35] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[36] && be_s1_io_out_pp_1[36])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[36] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[37] && be_s1_io_out_pp_1[37])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[37] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[38] && be_s1_io_out_pp_1[38])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[38] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[39] && be_s1_io_out_pp_1[39])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[39] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[40] && be_s1_io_out_pp_1[40])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[40] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[41] && be_s1_io_out_pp_1[41])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[41] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[42] && be_s1_io_out_pp_1[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[43] && be_s1_io_out_pp_1[43])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[43] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[44] && be_s1_io_out_pp_1[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[45] && be_s1_io_out_pp_1[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[46] && be_s1_io_out_pp_1[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[47] && be_s1_io_out_pp_1[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[48] && be_s1_io_out_pp_1[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[49] && be_s1_io_out_pp_1[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[50] && be_s1_io_out_pp_1[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[51] && be_s1_io_out_pp_1[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[52] && be_s1_io_out_pp_1[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[53] && be_s1_io_out_pp_1[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[54] && be_s1_io_out_pp_1[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[55] && be_s1_io_out_pp_1[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[56] && be_s1_io_out_pp_1[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_1[57] && be_s1_io_out_pp_1[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_1[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[2] && be_s1_io_out_pp_2[2])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[2] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[4] && be_s1_io_out_pp_2[4])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[4] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[5] && be_s1_io_out_pp_2[5])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[5] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[6] && be_s1_io_out_pp_2[6])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[6] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[7] && be_s1_io_out_pp_2[7])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[7] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[8] && be_s1_io_out_pp_2[8])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[8] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[9] && be_s1_io_out_pp_2[9])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[9] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[10] && be_s1_io_out_pp_2[10])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[10] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[11] && be_s1_io_out_pp_2[11])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[11] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[12] && be_s1_io_out_pp_2[12])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[12] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[13] && be_s1_io_out_pp_2[13])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[13] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[14] && be_s1_io_out_pp_2[14])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[14] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[15] && be_s1_io_out_pp_2[15])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[15] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[16] && be_s1_io_out_pp_2[16])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[16] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[17] && be_s1_io_out_pp_2[17])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[17] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[18] && be_s1_io_out_pp_2[18])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[18] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[19] && be_s1_io_out_pp_2[19])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[19] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[20] && be_s1_io_out_pp_2[20])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[20] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[21] && be_s1_io_out_pp_2[21])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[21] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[22] && be_s1_io_out_pp_2[22])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[22] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[23] && be_s1_io_out_pp_2[23])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[23] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[24] && be_s1_io_out_pp_2[24])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[24] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[25] && be_s1_io_out_pp_2[25])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[25] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[26] && be_s1_io_out_pp_2[26])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[26] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[27] && be_s1_io_out_pp_2[27])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[27] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[28] && be_s1_io_out_pp_2[28])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[28] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[29] && be_s1_io_out_pp_2[29])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[29] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[30] && be_s1_io_out_pp_2[30])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[30] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[31] && be_s1_io_out_pp_2[31])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[31] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[32] && be_s1_io_out_pp_2[32])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[32] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[33] && be_s1_io_out_pp_2[33])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[33] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[34] && be_s1_io_out_pp_2[34])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[34] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[35] && be_s1_io_out_pp_2[35])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[35] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[36] && be_s1_io_out_pp_2[36])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[36] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[37] && be_s1_io_out_pp_2[37])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[37] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[38] && be_s1_io_out_pp_2[38])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[38] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[39] && be_s1_io_out_pp_2[39])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[39] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[40] && be_s1_io_out_pp_2[40])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[40] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[41] && be_s1_io_out_pp_2[41])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[41] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[42] && be_s1_io_out_pp_2[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[43] && be_s1_io_out_pp_2[43])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[43] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[44] && be_s1_io_out_pp_2[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[45] && be_s1_io_out_pp_2[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[46] && be_s1_io_out_pp_2[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[47] && be_s1_io_out_pp_2[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[48] && be_s1_io_out_pp_2[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[49] && be_s1_io_out_pp_2[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[50] && be_s1_io_out_pp_2[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[51] && be_s1_io_out_pp_2[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[52] && be_s1_io_out_pp_2[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[53] && be_s1_io_out_pp_2[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[54] && be_s1_io_out_pp_2[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[55] && be_s1_io_out_pp_2[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[56] && be_s1_io_out_pp_2[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[57] && be_s1_io_out_pp_2[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[58] && be_s1_io_out_pp_2[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_2[59] && be_s1_io_out_pp_2[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_2[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[4] && be_s1_io_out_pp_3[4])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[4] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[6] && be_s1_io_out_pp_3[6])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[6] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[7] && be_s1_io_out_pp_3[7])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[7] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[8] && be_s1_io_out_pp_3[8])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[8] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[9] && be_s1_io_out_pp_3[9])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[9] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[10] && be_s1_io_out_pp_3[10])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[10] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[11] && be_s1_io_out_pp_3[11])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[11] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[12] && be_s1_io_out_pp_3[12])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[12] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[13] && be_s1_io_out_pp_3[13])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[13] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[14] && be_s1_io_out_pp_3[14])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[14] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[15] && be_s1_io_out_pp_3[15])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[15] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[16] && be_s1_io_out_pp_3[16])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[16] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[17] && be_s1_io_out_pp_3[17])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[17] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[18] && be_s1_io_out_pp_3[18])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[18] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[19] && be_s1_io_out_pp_3[19])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[19] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[20] && be_s1_io_out_pp_3[20])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[20] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[21] && be_s1_io_out_pp_3[21])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[21] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[22] && be_s1_io_out_pp_3[22])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[22] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[23] && be_s1_io_out_pp_3[23])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[23] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[24] && be_s1_io_out_pp_3[24])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[24] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[25] && be_s1_io_out_pp_3[25])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[25] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[26] && be_s1_io_out_pp_3[26])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[26] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[27] && be_s1_io_out_pp_3[27])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[27] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[28] && be_s1_io_out_pp_3[28])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[28] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[29] && be_s1_io_out_pp_3[29])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[29] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[30] && be_s1_io_out_pp_3[30])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[30] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[31] && be_s1_io_out_pp_3[31])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[31] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[32] && be_s1_io_out_pp_3[32])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[32] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[33] && be_s1_io_out_pp_3[33])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[33] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[34] && be_s1_io_out_pp_3[34])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[34] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[35] && be_s1_io_out_pp_3[35])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[35] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[36] && be_s1_io_out_pp_3[36])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[36] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[37] && be_s1_io_out_pp_3[37])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[37] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[38] && be_s1_io_out_pp_3[38])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[38] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[39] && be_s1_io_out_pp_3[39])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[39] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[40] && be_s1_io_out_pp_3[40])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[40] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[41] && be_s1_io_out_pp_3[41])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[41] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[42] && be_s1_io_out_pp_3[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[43] && be_s1_io_out_pp_3[43])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[43] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[44] && be_s1_io_out_pp_3[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[45] && be_s1_io_out_pp_3[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[46] && be_s1_io_out_pp_3[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[47] && be_s1_io_out_pp_3[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[48] && be_s1_io_out_pp_3[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[49] && be_s1_io_out_pp_3[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[50] && be_s1_io_out_pp_3[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[51] && be_s1_io_out_pp_3[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[52] && be_s1_io_out_pp_3[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[53] && be_s1_io_out_pp_3[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[54] && be_s1_io_out_pp_3[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[55] && be_s1_io_out_pp_3[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[56] && be_s1_io_out_pp_3[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[57] && be_s1_io_out_pp_3[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[58] && be_s1_io_out_pp_3[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[59] && be_s1_io_out_pp_3[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[60] && be_s1_io_out_pp_3[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_3[61] && be_s1_io_out_pp_3[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_3[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[6] && be_s1_io_out_pp_4[6])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[6] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[8] && be_s1_io_out_pp_4[8])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[8] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[9] && be_s1_io_out_pp_4[9])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[9] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[10] && be_s1_io_out_pp_4[10])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[10] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[11] && be_s1_io_out_pp_4[11])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[11] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[12] && be_s1_io_out_pp_4[12])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[12] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[13] && be_s1_io_out_pp_4[13])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[13] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[14] && be_s1_io_out_pp_4[14])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[14] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[15] && be_s1_io_out_pp_4[15])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[15] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[16] && be_s1_io_out_pp_4[16])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[16] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[17] && be_s1_io_out_pp_4[17])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[17] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[18] && be_s1_io_out_pp_4[18])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[18] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[19] && be_s1_io_out_pp_4[19])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[19] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[20] && be_s1_io_out_pp_4[20])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[20] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[21] && be_s1_io_out_pp_4[21])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[21] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[22] && be_s1_io_out_pp_4[22])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[22] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[23] && be_s1_io_out_pp_4[23])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[23] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[24] && be_s1_io_out_pp_4[24])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[24] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[25] && be_s1_io_out_pp_4[25])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[25] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[26] && be_s1_io_out_pp_4[26])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[26] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[27] && be_s1_io_out_pp_4[27])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[27] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[28] && be_s1_io_out_pp_4[28])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[28] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[29] && be_s1_io_out_pp_4[29])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[29] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[30] && be_s1_io_out_pp_4[30])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[30] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[31] && be_s1_io_out_pp_4[31])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[31] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[32] && be_s1_io_out_pp_4[32])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[32] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[33] && be_s1_io_out_pp_4[33])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[33] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[34] && be_s1_io_out_pp_4[34])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[34] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[35] && be_s1_io_out_pp_4[35])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[35] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[36] && be_s1_io_out_pp_4[36])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[36] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[37] && be_s1_io_out_pp_4[37])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[37] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[38] && be_s1_io_out_pp_4[38])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[38] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[39] && be_s1_io_out_pp_4[39])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[39] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[40] && be_s1_io_out_pp_4[40])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[40] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[41] && be_s1_io_out_pp_4[41])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[41] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[42] && be_s1_io_out_pp_4[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[43] && be_s1_io_out_pp_4[43])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[43] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[44] && be_s1_io_out_pp_4[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[45] && be_s1_io_out_pp_4[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[46] && be_s1_io_out_pp_4[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[47] && be_s1_io_out_pp_4[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[48] && be_s1_io_out_pp_4[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[49] && be_s1_io_out_pp_4[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[50] && be_s1_io_out_pp_4[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[51] && be_s1_io_out_pp_4[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[52] && be_s1_io_out_pp_4[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[53] && be_s1_io_out_pp_4[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[54] && be_s1_io_out_pp_4[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[55] && be_s1_io_out_pp_4[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[56] && be_s1_io_out_pp_4[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[57] && be_s1_io_out_pp_4[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[58] && be_s1_io_out_pp_4[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[59] && be_s1_io_out_pp_4[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[60] && be_s1_io_out_pp_4[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[61] && be_s1_io_out_pp_4[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[62] && be_s1_io_out_pp_4[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_4[63] && be_s1_io_out_pp_4[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_4[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[8] && be_s1_io_out_pp_5[8])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[8] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[10] && be_s1_io_out_pp_5[10])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[10] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[11] && be_s1_io_out_pp_5[11])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[11] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[12] && be_s1_io_out_pp_5[12])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[12] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[13] && be_s1_io_out_pp_5[13])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[13] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[14] && be_s1_io_out_pp_5[14])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[14] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[15] && be_s1_io_out_pp_5[15])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[15] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[16] && be_s1_io_out_pp_5[16])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[16] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[17] && be_s1_io_out_pp_5[17])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[17] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[18] && be_s1_io_out_pp_5[18])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[18] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[19] && be_s1_io_out_pp_5[19])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[19] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[20] && be_s1_io_out_pp_5[20])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[20] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[21] && be_s1_io_out_pp_5[21])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[21] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[22] && be_s1_io_out_pp_5[22])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[22] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[23] && be_s1_io_out_pp_5[23])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[23] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[24] && be_s1_io_out_pp_5[24])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[24] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[25] && be_s1_io_out_pp_5[25])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[25] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[26] && be_s1_io_out_pp_5[26])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[26] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[27] && be_s1_io_out_pp_5[27])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[27] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[28] && be_s1_io_out_pp_5[28])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[28] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[29] && be_s1_io_out_pp_5[29])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[29] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[30] && be_s1_io_out_pp_5[30])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[30] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[31] && be_s1_io_out_pp_5[31])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[31] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[32] && be_s1_io_out_pp_5[32])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[32] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[33] && be_s1_io_out_pp_5[33])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[33] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[34] && be_s1_io_out_pp_5[34])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[34] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[35] && be_s1_io_out_pp_5[35])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[35] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[36] && be_s1_io_out_pp_5[36])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[36] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[37] && be_s1_io_out_pp_5[37])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[37] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[38] && be_s1_io_out_pp_5[38])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[38] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[39] && be_s1_io_out_pp_5[39])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[39] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[40] && be_s1_io_out_pp_5[40])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[40] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[41] && be_s1_io_out_pp_5[41])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[41] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[42] && be_s1_io_out_pp_5[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[43] && be_s1_io_out_pp_5[43])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[43] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[44] && be_s1_io_out_pp_5[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[45] && be_s1_io_out_pp_5[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[46] && be_s1_io_out_pp_5[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[47] && be_s1_io_out_pp_5[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[48] && be_s1_io_out_pp_5[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[49] && be_s1_io_out_pp_5[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[50] && be_s1_io_out_pp_5[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[51] && be_s1_io_out_pp_5[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[52] && be_s1_io_out_pp_5[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[53] && be_s1_io_out_pp_5[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[54] && be_s1_io_out_pp_5[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[55] && be_s1_io_out_pp_5[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[56] && be_s1_io_out_pp_5[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[57] && be_s1_io_out_pp_5[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[58] && be_s1_io_out_pp_5[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[59] && be_s1_io_out_pp_5[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[60] && be_s1_io_out_pp_5[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[61] && be_s1_io_out_pp_5[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[62] && be_s1_io_out_pp_5[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[63] && be_s1_io_out_pp_5[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[64] && be_s1_io_out_pp_5[64])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[64] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_5[65] && be_s1_io_out_pp_5[65])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_5[65] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[10] && be_s1_io_out_pp_6[10])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[10] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[12] && be_s1_io_out_pp_6[12])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[12] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[13] && be_s1_io_out_pp_6[13])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[13] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[14] && be_s1_io_out_pp_6[14])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[14] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[15] && be_s1_io_out_pp_6[15])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[15] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[16] && be_s1_io_out_pp_6[16])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[16] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[17] && be_s1_io_out_pp_6[17])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[17] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[18] && be_s1_io_out_pp_6[18])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[18] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[19] && be_s1_io_out_pp_6[19])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[19] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[20] && be_s1_io_out_pp_6[20])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[20] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[21] && be_s1_io_out_pp_6[21])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[21] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[22] && be_s1_io_out_pp_6[22])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[22] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[23] && be_s1_io_out_pp_6[23])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[23] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[24] && be_s1_io_out_pp_6[24])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[24] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[25] && be_s1_io_out_pp_6[25])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[25] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[26] && be_s1_io_out_pp_6[26])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[26] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[27] && be_s1_io_out_pp_6[27])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[27] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[28] && be_s1_io_out_pp_6[28])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[28] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[29] && be_s1_io_out_pp_6[29])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[29] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[30] && be_s1_io_out_pp_6[30])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[30] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[31] && be_s1_io_out_pp_6[31])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[31] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[32] && be_s1_io_out_pp_6[32])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[32] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[33] && be_s1_io_out_pp_6[33])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[33] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[34] && be_s1_io_out_pp_6[34])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[34] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[35] && be_s1_io_out_pp_6[35])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[35] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[36] && be_s1_io_out_pp_6[36])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[36] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[37] && be_s1_io_out_pp_6[37])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[37] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[38] && be_s1_io_out_pp_6[38])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[38] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[39] && be_s1_io_out_pp_6[39])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[39] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[40] && be_s1_io_out_pp_6[40])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[40] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[41] && be_s1_io_out_pp_6[41])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[41] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[42] && be_s1_io_out_pp_6[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[43] && be_s1_io_out_pp_6[43])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[43] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[44] && be_s1_io_out_pp_6[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[45] && be_s1_io_out_pp_6[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[46] && be_s1_io_out_pp_6[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[47] && be_s1_io_out_pp_6[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[48] && be_s1_io_out_pp_6[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[49] && be_s1_io_out_pp_6[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[50] && be_s1_io_out_pp_6[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[51] && be_s1_io_out_pp_6[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[52] && be_s1_io_out_pp_6[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[53] && be_s1_io_out_pp_6[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[54] && be_s1_io_out_pp_6[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[55] && be_s1_io_out_pp_6[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[56] && be_s1_io_out_pp_6[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[57] && be_s1_io_out_pp_6[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[58] && be_s1_io_out_pp_6[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[59] && be_s1_io_out_pp_6[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[60] && be_s1_io_out_pp_6[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[61] && be_s1_io_out_pp_6[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[62] && be_s1_io_out_pp_6[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[63] && be_s1_io_out_pp_6[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[64] && be_s1_io_out_pp_6[64])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[64] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[65] && be_s1_io_out_pp_6[65])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[65] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[66] && be_s1_io_out_pp_6[66])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[66] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_6[67] && be_s1_io_out_pp_6[67])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_6[67] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[12] && be_s1_io_out_pp_7[12])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[12] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[14] && be_s1_io_out_pp_7[14])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[14] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[15] && be_s1_io_out_pp_7[15])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[15] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[16] && be_s1_io_out_pp_7[16])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[16] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[17] && be_s1_io_out_pp_7[17])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[17] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[18] && be_s1_io_out_pp_7[18])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[18] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[19] && be_s1_io_out_pp_7[19])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[19] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[20] && be_s1_io_out_pp_7[20])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[20] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[21] && be_s1_io_out_pp_7[21])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[21] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[22] && be_s1_io_out_pp_7[22])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[22] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[23] && be_s1_io_out_pp_7[23])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[23] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[24] && be_s1_io_out_pp_7[24])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[24] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[25] && be_s1_io_out_pp_7[25])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[25] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[26] && be_s1_io_out_pp_7[26])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[26] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[27] && be_s1_io_out_pp_7[27])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[27] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[28] && be_s1_io_out_pp_7[28])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[28] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[29] && be_s1_io_out_pp_7[29])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[29] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[30] && be_s1_io_out_pp_7[30])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[30] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[31] && be_s1_io_out_pp_7[31])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[31] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[32] && be_s1_io_out_pp_7[32])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[32] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[33] && be_s1_io_out_pp_7[33])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[33] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[34] && be_s1_io_out_pp_7[34])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[34] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[35] && be_s1_io_out_pp_7[35])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[35] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[36] && be_s1_io_out_pp_7[36])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[36] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[37] && be_s1_io_out_pp_7[37])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[37] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[38] && be_s1_io_out_pp_7[38])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[38] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[39] && be_s1_io_out_pp_7[39])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[39] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[40] && be_s1_io_out_pp_7[40])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[40] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[41] && be_s1_io_out_pp_7[41])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[41] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[42] && be_s1_io_out_pp_7[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[43] && be_s1_io_out_pp_7[43])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[43] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[44] && be_s1_io_out_pp_7[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[45] && be_s1_io_out_pp_7[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[46] && be_s1_io_out_pp_7[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[47] && be_s1_io_out_pp_7[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[48] && be_s1_io_out_pp_7[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[49] && be_s1_io_out_pp_7[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[50] && be_s1_io_out_pp_7[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[51] && be_s1_io_out_pp_7[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[52] && be_s1_io_out_pp_7[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[53] && be_s1_io_out_pp_7[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[54] && be_s1_io_out_pp_7[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[55] && be_s1_io_out_pp_7[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[56] && be_s1_io_out_pp_7[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[57] && be_s1_io_out_pp_7[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[58] && be_s1_io_out_pp_7[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[59] && be_s1_io_out_pp_7[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[60] && be_s1_io_out_pp_7[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[61] && be_s1_io_out_pp_7[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[62] && be_s1_io_out_pp_7[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[63] && be_s1_io_out_pp_7[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[64] && be_s1_io_out_pp_7[64])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[64] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[65] && be_s1_io_out_pp_7[65])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[65] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[66] && be_s1_io_out_pp_7[66])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[66] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[67] && be_s1_io_out_pp_7[67])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[67] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[68] && be_s1_io_out_pp_7[68])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[68] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_7[69] && be_s1_io_out_pp_7[69])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_7[69] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[14] && be_s1_io_out_pp_8[14])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[14] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[16] && be_s1_io_out_pp_8[16])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[16] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[17] && be_s1_io_out_pp_8[17])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[17] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[18] && be_s1_io_out_pp_8[18])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[18] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[19] && be_s1_io_out_pp_8[19])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[19] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[20] && be_s1_io_out_pp_8[20])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[20] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[21] && be_s1_io_out_pp_8[21])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[21] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[22] && be_s1_io_out_pp_8[22])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[22] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[23] && be_s1_io_out_pp_8[23])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[23] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[24] && be_s1_io_out_pp_8[24])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[24] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[25] && be_s1_io_out_pp_8[25])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[25] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[26] && be_s1_io_out_pp_8[26])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[26] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[27] && be_s1_io_out_pp_8[27])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[27] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[28] && be_s1_io_out_pp_8[28])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[28] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[29] && be_s1_io_out_pp_8[29])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[29] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[30] && be_s1_io_out_pp_8[30])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[30] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[31] && be_s1_io_out_pp_8[31])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[31] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[32] && be_s1_io_out_pp_8[32])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[32] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[33] && be_s1_io_out_pp_8[33])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[33] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[34] && be_s1_io_out_pp_8[34])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[34] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[35] && be_s1_io_out_pp_8[35])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[35] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[36] && be_s1_io_out_pp_8[36])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[36] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[37] && be_s1_io_out_pp_8[37])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[37] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[38] && be_s1_io_out_pp_8[38])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[38] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[39] && be_s1_io_out_pp_8[39])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[39] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[40] && be_s1_io_out_pp_8[40])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[40] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[41] && be_s1_io_out_pp_8[41])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[41] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[42] && be_s1_io_out_pp_8[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[43] && be_s1_io_out_pp_8[43])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[43] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[44] && be_s1_io_out_pp_8[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[45] && be_s1_io_out_pp_8[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[46] && be_s1_io_out_pp_8[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[47] && be_s1_io_out_pp_8[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[48] && be_s1_io_out_pp_8[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[49] && be_s1_io_out_pp_8[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[50] && be_s1_io_out_pp_8[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[51] && be_s1_io_out_pp_8[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[52] && be_s1_io_out_pp_8[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[53] && be_s1_io_out_pp_8[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[54] && be_s1_io_out_pp_8[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[55] && be_s1_io_out_pp_8[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[56] && be_s1_io_out_pp_8[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[57] && be_s1_io_out_pp_8[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[58] && be_s1_io_out_pp_8[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[59] && be_s1_io_out_pp_8[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[60] && be_s1_io_out_pp_8[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[61] && be_s1_io_out_pp_8[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[62] && be_s1_io_out_pp_8[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[63] && be_s1_io_out_pp_8[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[64] && be_s1_io_out_pp_8[64])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[64] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[65] && be_s1_io_out_pp_8[65])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[65] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[66] && be_s1_io_out_pp_8[66])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[66] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[67] && be_s1_io_out_pp_8[67])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[67] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[68] && be_s1_io_out_pp_8[68])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[68] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[69] && be_s1_io_out_pp_8[69])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[69] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[70] && be_s1_io_out_pp_8[70])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[70] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_8[71] && be_s1_io_out_pp_8[71])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_8[71] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[16] && be_s1_io_out_pp_9[16])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[16] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[18] && be_s1_io_out_pp_9[18])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[18] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[19] && be_s1_io_out_pp_9[19])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[19] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[20] && be_s1_io_out_pp_9[20])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[20] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[21] && be_s1_io_out_pp_9[21])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[21] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[22] && be_s1_io_out_pp_9[22])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[22] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[23] && be_s1_io_out_pp_9[23])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[23] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[24] && be_s1_io_out_pp_9[24])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[24] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[25] && be_s1_io_out_pp_9[25])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[25] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[26] && be_s1_io_out_pp_9[26])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[26] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[27] && be_s1_io_out_pp_9[27])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[27] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[28] && be_s1_io_out_pp_9[28])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[28] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[29] && be_s1_io_out_pp_9[29])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[29] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[30] && be_s1_io_out_pp_9[30])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[30] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[31] && be_s1_io_out_pp_9[31])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[31] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[32] && be_s1_io_out_pp_9[32])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[32] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[33] && be_s1_io_out_pp_9[33])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[33] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[34] && be_s1_io_out_pp_9[34])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[34] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[35] && be_s1_io_out_pp_9[35])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[35] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[36] && be_s1_io_out_pp_9[36])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[36] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[37] && be_s1_io_out_pp_9[37])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[37] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[38] && be_s1_io_out_pp_9[38])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[38] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[39] && be_s1_io_out_pp_9[39])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[39] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[40] && be_s1_io_out_pp_9[40])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[40] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[41] && be_s1_io_out_pp_9[41])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[41] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[42] && be_s1_io_out_pp_9[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[43] && be_s1_io_out_pp_9[43])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[43] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[44] && be_s1_io_out_pp_9[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[45] && be_s1_io_out_pp_9[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[46] && be_s1_io_out_pp_9[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[47] && be_s1_io_out_pp_9[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[48] && be_s1_io_out_pp_9[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[49] && be_s1_io_out_pp_9[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[50] && be_s1_io_out_pp_9[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[51] && be_s1_io_out_pp_9[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[52] && be_s1_io_out_pp_9[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[53] && be_s1_io_out_pp_9[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[54] && be_s1_io_out_pp_9[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[55] && be_s1_io_out_pp_9[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[56] && be_s1_io_out_pp_9[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[57] && be_s1_io_out_pp_9[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[58] && be_s1_io_out_pp_9[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[59] && be_s1_io_out_pp_9[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[60] && be_s1_io_out_pp_9[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[61] && be_s1_io_out_pp_9[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[62] && be_s1_io_out_pp_9[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[63] && be_s1_io_out_pp_9[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[64] && be_s1_io_out_pp_9[64])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[64] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[65] && be_s1_io_out_pp_9[65])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[65] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[66] && be_s1_io_out_pp_9[66])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[66] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[67] && be_s1_io_out_pp_9[67])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[67] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[68] && be_s1_io_out_pp_9[68])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[68] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[69] && be_s1_io_out_pp_9[69])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[69] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[70] && be_s1_io_out_pp_9[70])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[70] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[71] && be_s1_io_out_pp_9[71])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[71] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[72] && be_s1_io_out_pp_9[72])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[72] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_9[73] && be_s1_io_out_pp_9[73])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_9[73] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[18] && be_s1_io_out_pp_10[18])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[18] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[20] && be_s1_io_out_pp_10[20])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[20] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[21] && be_s1_io_out_pp_10[21])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[21] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[22] && be_s1_io_out_pp_10[22])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[22] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[23] && be_s1_io_out_pp_10[23])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[23] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[24] && be_s1_io_out_pp_10[24])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[24] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[25] && be_s1_io_out_pp_10[25])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[25] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[26] && be_s1_io_out_pp_10[26])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[26] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[27] && be_s1_io_out_pp_10[27])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[27] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[28] && be_s1_io_out_pp_10[28])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[28] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[29] && be_s1_io_out_pp_10[29])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[29] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[30] && be_s1_io_out_pp_10[30])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[30] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[31] && be_s1_io_out_pp_10[31])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[31] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[32] && be_s1_io_out_pp_10[32])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[32] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[33] && be_s1_io_out_pp_10[33])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[33] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[34] && be_s1_io_out_pp_10[34])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[34] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[35] && be_s1_io_out_pp_10[35])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[35] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[36] && be_s1_io_out_pp_10[36])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[36] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[37] && be_s1_io_out_pp_10[37])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[37] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[38] && be_s1_io_out_pp_10[38])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[38] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[39] && be_s1_io_out_pp_10[39])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[39] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[40] && be_s1_io_out_pp_10[40])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[40] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[41] && be_s1_io_out_pp_10[41])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[41] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[42] && be_s1_io_out_pp_10[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[43] && be_s1_io_out_pp_10[43])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[43] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[44] && be_s1_io_out_pp_10[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[45] && be_s1_io_out_pp_10[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[46] && be_s1_io_out_pp_10[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[47] && be_s1_io_out_pp_10[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[48] && be_s1_io_out_pp_10[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[49] && be_s1_io_out_pp_10[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[50] && be_s1_io_out_pp_10[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[51] && be_s1_io_out_pp_10[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[52] && be_s1_io_out_pp_10[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[53] && be_s1_io_out_pp_10[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[54] && be_s1_io_out_pp_10[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[55] && be_s1_io_out_pp_10[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[56] && be_s1_io_out_pp_10[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[57] && be_s1_io_out_pp_10[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[58] && be_s1_io_out_pp_10[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[59] && be_s1_io_out_pp_10[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[60] && be_s1_io_out_pp_10[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[61] && be_s1_io_out_pp_10[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[62] && be_s1_io_out_pp_10[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[63] && be_s1_io_out_pp_10[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[64] && be_s1_io_out_pp_10[64])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[64] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[65] && be_s1_io_out_pp_10[65])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[65] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[66] && be_s1_io_out_pp_10[66])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[66] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[67] && be_s1_io_out_pp_10[67])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[67] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[68] && be_s1_io_out_pp_10[68])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[68] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[69] && be_s1_io_out_pp_10[69])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[69] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[70] && be_s1_io_out_pp_10[70])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[70] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[71] && be_s1_io_out_pp_10[71])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[71] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[72] && be_s1_io_out_pp_10[72])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[72] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[73] && be_s1_io_out_pp_10[73])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[73] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[74] && be_s1_io_out_pp_10[74])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[74] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_10[75] && be_s1_io_out_pp_10[75])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_10[75] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[20] && be_s1_io_out_pp_11[20])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[20] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[22] && be_s1_io_out_pp_11[22])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[22] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[23] && be_s1_io_out_pp_11[23])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[23] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[24] && be_s1_io_out_pp_11[24])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[24] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[25] && be_s1_io_out_pp_11[25])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[25] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[26] && be_s1_io_out_pp_11[26])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[26] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[27] && be_s1_io_out_pp_11[27])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[27] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[28] && be_s1_io_out_pp_11[28])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[28] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[29] && be_s1_io_out_pp_11[29])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[29] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[30] && be_s1_io_out_pp_11[30])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[30] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[31] && be_s1_io_out_pp_11[31])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[31] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[32] && be_s1_io_out_pp_11[32])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[32] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[33] && be_s1_io_out_pp_11[33])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[33] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[34] && be_s1_io_out_pp_11[34])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[34] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[35] && be_s1_io_out_pp_11[35])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[35] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[36] && be_s1_io_out_pp_11[36])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[36] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[37] && be_s1_io_out_pp_11[37])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[37] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[38] && be_s1_io_out_pp_11[38])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[38] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[39] && be_s1_io_out_pp_11[39])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[39] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[40] && be_s1_io_out_pp_11[40])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[40] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[41] && be_s1_io_out_pp_11[41])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[41] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[42] && be_s1_io_out_pp_11[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[43] && be_s1_io_out_pp_11[43])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[43] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[44] && be_s1_io_out_pp_11[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[45] && be_s1_io_out_pp_11[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[46] && be_s1_io_out_pp_11[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[47] && be_s1_io_out_pp_11[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[48] && be_s1_io_out_pp_11[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[49] && be_s1_io_out_pp_11[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[50] && be_s1_io_out_pp_11[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[51] && be_s1_io_out_pp_11[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[52] && be_s1_io_out_pp_11[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[53] && be_s1_io_out_pp_11[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[54] && be_s1_io_out_pp_11[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[55] && be_s1_io_out_pp_11[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[56] && be_s1_io_out_pp_11[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[57] && be_s1_io_out_pp_11[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[58] && be_s1_io_out_pp_11[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[59] && be_s1_io_out_pp_11[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[60] && be_s1_io_out_pp_11[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[61] && be_s1_io_out_pp_11[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[62] && be_s1_io_out_pp_11[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[63] && be_s1_io_out_pp_11[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[64] && be_s1_io_out_pp_11[64])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[64] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[65] && be_s1_io_out_pp_11[65])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[65] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[66] && be_s1_io_out_pp_11[66])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[66] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[67] && be_s1_io_out_pp_11[67])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[67] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[68] && be_s1_io_out_pp_11[68])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[68] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[69] && be_s1_io_out_pp_11[69])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[69] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[70] && be_s1_io_out_pp_11[70])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[70] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[71] && be_s1_io_out_pp_11[71])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[71] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[72] && be_s1_io_out_pp_11[72])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[72] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[73] && be_s1_io_out_pp_11[73])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[73] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[74] && be_s1_io_out_pp_11[74])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[74] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[75] && be_s1_io_out_pp_11[75])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[75] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[76] && be_s1_io_out_pp_11[76])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[76] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_11[77] && be_s1_io_out_pp_11[77])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_11[77] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[22] && be_s1_io_out_pp_12[22])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[22] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[24] && be_s1_io_out_pp_12[24])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[24] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[25] && be_s1_io_out_pp_12[25])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[25] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[26] && be_s1_io_out_pp_12[26])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[26] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[27] && be_s1_io_out_pp_12[27])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[27] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[28] && be_s1_io_out_pp_12[28])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[28] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[29] && be_s1_io_out_pp_12[29])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[29] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[30] && be_s1_io_out_pp_12[30])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[30] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[31] && be_s1_io_out_pp_12[31])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[31] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[32] && be_s1_io_out_pp_12[32])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[32] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[33] && be_s1_io_out_pp_12[33])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[33] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[34] && be_s1_io_out_pp_12[34])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[34] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[35] && be_s1_io_out_pp_12[35])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[35] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[36] && be_s1_io_out_pp_12[36])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[36] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[37] && be_s1_io_out_pp_12[37])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[37] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[38] && be_s1_io_out_pp_12[38])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[38] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[39] && be_s1_io_out_pp_12[39])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[39] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[40] && be_s1_io_out_pp_12[40])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[40] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[41] && be_s1_io_out_pp_12[41])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[41] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[42] && be_s1_io_out_pp_12[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[43] && be_s1_io_out_pp_12[43])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[43] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[44] && be_s1_io_out_pp_12[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[45] && be_s1_io_out_pp_12[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[46] && be_s1_io_out_pp_12[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[47] && be_s1_io_out_pp_12[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[48] && be_s1_io_out_pp_12[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[49] && be_s1_io_out_pp_12[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[50] && be_s1_io_out_pp_12[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[51] && be_s1_io_out_pp_12[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[52] && be_s1_io_out_pp_12[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[53] && be_s1_io_out_pp_12[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[54] && be_s1_io_out_pp_12[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[55] && be_s1_io_out_pp_12[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[56] && be_s1_io_out_pp_12[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[57] && be_s1_io_out_pp_12[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[58] && be_s1_io_out_pp_12[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[59] && be_s1_io_out_pp_12[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[60] && be_s1_io_out_pp_12[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[61] && be_s1_io_out_pp_12[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[62] && be_s1_io_out_pp_12[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[63] && be_s1_io_out_pp_12[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[64] && be_s1_io_out_pp_12[64])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[64] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[65] && be_s1_io_out_pp_12[65])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[65] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[66] && be_s1_io_out_pp_12[66])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[66] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[67] && be_s1_io_out_pp_12[67])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[67] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[68] && be_s1_io_out_pp_12[68])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[68] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[69] && be_s1_io_out_pp_12[69])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[69] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[70] && be_s1_io_out_pp_12[70])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[70] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[71] && be_s1_io_out_pp_12[71])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[71] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[72] && be_s1_io_out_pp_12[72])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[72] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[73] && be_s1_io_out_pp_12[73])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[73] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[74] && be_s1_io_out_pp_12[74])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[74] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[75] && be_s1_io_out_pp_12[75])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[75] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[76] && be_s1_io_out_pp_12[76])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[76] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[77] && be_s1_io_out_pp_12[77])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[77] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[78] && be_s1_io_out_pp_12[78])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[78] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_12[79] && be_s1_io_out_pp_12[79])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_12[79] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[24] && be_s1_io_out_pp_13[24])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[24] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[26] && be_s1_io_out_pp_13[26])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[26] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[27] && be_s1_io_out_pp_13[27])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[27] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[28] && be_s1_io_out_pp_13[28])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[28] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[29] && be_s1_io_out_pp_13[29])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[29] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[30] && be_s1_io_out_pp_13[30])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[30] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[31] && be_s1_io_out_pp_13[31])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[31] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[32] && be_s1_io_out_pp_13[32])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[32] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[33] && be_s1_io_out_pp_13[33])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[33] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[34] && be_s1_io_out_pp_13[34])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[34] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[35] && be_s1_io_out_pp_13[35])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[35] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[36] && be_s1_io_out_pp_13[36])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[36] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[37] && be_s1_io_out_pp_13[37])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[37] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[38] && be_s1_io_out_pp_13[38])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[38] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[39] && be_s1_io_out_pp_13[39])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[39] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[40] && be_s1_io_out_pp_13[40])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[40] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[41] && be_s1_io_out_pp_13[41])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[41] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[42] && be_s1_io_out_pp_13[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[43] && be_s1_io_out_pp_13[43])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[43] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[44] && be_s1_io_out_pp_13[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[45] && be_s1_io_out_pp_13[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[46] && be_s1_io_out_pp_13[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[47] && be_s1_io_out_pp_13[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[48] && be_s1_io_out_pp_13[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[49] && be_s1_io_out_pp_13[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[50] && be_s1_io_out_pp_13[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[51] && be_s1_io_out_pp_13[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[52] && be_s1_io_out_pp_13[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[53] && be_s1_io_out_pp_13[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[54] && be_s1_io_out_pp_13[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[55] && be_s1_io_out_pp_13[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[56] && be_s1_io_out_pp_13[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[57] && be_s1_io_out_pp_13[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[58] && be_s1_io_out_pp_13[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[59] && be_s1_io_out_pp_13[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[60] && be_s1_io_out_pp_13[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[61] && be_s1_io_out_pp_13[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[62] && be_s1_io_out_pp_13[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[63] && be_s1_io_out_pp_13[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[64] && be_s1_io_out_pp_13[64])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[64] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[65] && be_s1_io_out_pp_13[65])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[65] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[66] && be_s1_io_out_pp_13[66])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[66] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[67] && be_s1_io_out_pp_13[67])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[67] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[68] && be_s1_io_out_pp_13[68])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[68] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[69] && be_s1_io_out_pp_13[69])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[69] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[70] && be_s1_io_out_pp_13[70])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[70] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[71] && be_s1_io_out_pp_13[71])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[71] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[72] && be_s1_io_out_pp_13[72])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[72] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[73] && be_s1_io_out_pp_13[73])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[73] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[74] && be_s1_io_out_pp_13[74])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[74] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[75] && be_s1_io_out_pp_13[75])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[75] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[76] && be_s1_io_out_pp_13[76])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[76] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[77] && be_s1_io_out_pp_13[77])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[77] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[78] && be_s1_io_out_pp_13[78])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[78] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[79] && be_s1_io_out_pp_13[79])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[79] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[80] && be_s1_io_out_pp_13[80])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[80] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_13[81] && be_s1_io_out_pp_13[81])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_13[81] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[26] && be_s1_io_out_pp_14[26])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[26] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[28] && be_s1_io_out_pp_14[28])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[28] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[29] && be_s1_io_out_pp_14[29])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[29] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[30] && be_s1_io_out_pp_14[30])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[30] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[31] && be_s1_io_out_pp_14[31])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[31] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[32] && be_s1_io_out_pp_14[32])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[32] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[33] && be_s1_io_out_pp_14[33])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[33] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[34] && be_s1_io_out_pp_14[34])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[34] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[35] && be_s1_io_out_pp_14[35])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[35] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[36] && be_s1_io_out_pp_14[36])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[36] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[37] && be_s1_io_out_pp_14[37])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[37] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[38] && be_s1_io_out_pp_14[38])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[38] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[39] && be_s1_io_out_pp_14[39])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[39] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[40] && be_s1_io_out_pp_14[40])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[40] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[41] && be_s1_io_out_pp_14[41])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[41] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[42] && be_s1_io_out_pp_14[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[43] && be_s1_io_out_pp_14[43])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[43] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[44] && be_s1_io_out_pp_14[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[45] && be_s1_io_out_pp_14[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[46] && be_s1_io_out_pp_14[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[47] && be_s1_io_out_pp_14[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[48] && be_s1_io_out_pp_14[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[49] && be_s1_io_out_pp_14[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[50] && be_s1_io_out_pp_14[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[51] && be_s1_io_out_pp_14[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[52] && be_s1_io_out_pp_14[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[53] && be_s1_io_out_pp_14[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[54] && be_s1_io_out_pp_14[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[55] && be_s1_io_out_pp_14[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[56] && be_s1_io_out_pp_14[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[57] && be_s1_io_out_pp_14[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[58] && be_s1_io_out_pp_14[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[59] && be_s1_io_out_pp_14[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[60] && be_s1_io_out_pp_14[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[61] && be_s1_io_out_pp_14[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[62] && be_s1_io_out_pp_14[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[63] && be_s1_io_out_pp_14[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[64] && be_s1_io_out_pp_14[64])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[64] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[65] && be_s1_io_out_pp_14[65])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[65] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[66] && be_s1_io_out_pp_14[66])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[66] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[67] && be_s1_io_out_pp_14[67])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[67] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[68] && be_s1_io_out_pp_14[68])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[68] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[69] && be_s1_io_out_pp_14[69])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[69] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[70] && be_s1_io_out_pp_14[70])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[70] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[71] && be_s1_io_out_pp_14[71])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[71] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[72] && be_s1_io_out_pp_14[72])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[72] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[73] && be_s1_io_out_pp_14[73])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[73] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[74] && be_s1_io_out_pp_14[74])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[74] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[75] && be_s1_io_out_pp_14[75])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[75] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[76] && be_s1_io_out_pp_14[76])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[76] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[77] && be_s1_io_out_pp_14[77])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[77] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[78] && be_s1_io_out_pp_14[78])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[78] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[79] && be_s1_io_out_pp_14[79])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[79] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[80] && be_s1_io_out_pp_14[80])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[80] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[81] && be_s1_io_out_pp_14[81])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[81] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[82] && be_s1_io_out_pp_14[82])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[82] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_14[83] && be_s1_io_out_pp_14[83])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_14[83] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[28] && be_s1_io_out_pp_15[28])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[28] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[30] && be_s1_io_out_pp_15[30])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[30] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[31] && be_s1_io_out_pp_15[31])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[31] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[32] && be_s1_io_out_pp_15[32])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[32] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[33] && be_s1_io_out_pp_15[33])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[33] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[34] && be_s1_io_out_pp_15[34])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[34] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[35] && be_s1_io_out_pp_15[35])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[35] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[36] && be_s1_io_out_pp_15[36])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[36] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[37] && be_s1_io_out_pp_15[37])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[37] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[38] && be_s1_io_out_pp_15[38])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[38] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[39] && be_s1_io_out_pp_15[39])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[39] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[40] && be_s1_io_out_pp_15[40])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[40] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[41] && be_s1_io_out_pp_15[41])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[41] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[42] && be_s1_io_out_pp_15[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[43] && be_s1_io_out_pp_15[43])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[43] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[44] && be_s1_io_out_pp_15[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[45] && be_s1_io_out_pp_15[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[46] && be_s1_io_out_pp_15[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[47] && be_s1_io_out_pp_15[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[48] && be_s1_io_out_pp_15[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[49] && be_s1_io_out_pp_15[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[50] && be_s1_io_out_pp_15[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[51] && be_s1_io_out_pp_15[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[52] && be_s1_io_out_pp_15[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[53] && be_s1_io_out_pp_15[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[54] && be_s1_io_out_pp_15[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[55] && be_s1_io_out_pp_15[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[56] && be_s1_io_out_pp_15[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[57] && be_s1_io_out_pp_15[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[58] && be_s1_io_out_pp_15[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[59] && be_s1_io_out_pp_15[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[60] && be_s1_io_out_pp_15[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[61] && be_s1_io_out_pp_15[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[62] && be_s1_io_out_pp_15[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[63] && be_s1_io_out_pp_15[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[64] && be_s1_io_out_pp_15[64])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[64] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[65] && be_s1_io_out_pp_15[65])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[65] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[66] && be_s1_io_out_pp_15[66])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[66] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[67] && be_s1_io_out_pp_15[67])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[67] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[68] && be_s1_io_out_pp_15[68])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[68] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[69] && be_s1_io_out_pp_15[69])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[69] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[70] && be_s1_io_out_pp_15[70])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[70] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[71] && be_s1_io_out_pp_15[71])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[71] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[72] && be_s1_io_out_pp_15[72])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[72] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[73] && be_s1_io_out_pp_15[73])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[73] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[74] && be_s1_io_out_pp_15[74])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[74] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[75] && be_s1_io_out_pp_15[75])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[75] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[76] && be_s1_io_out_pp_15[76])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[76] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[77] && be_s1_io_out_pp_15[77])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[77] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[78] && be_s1_io_out_pp_15[78])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[78] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[79] && be_s1_io_out_pp_15[79])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[79] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[80] && be_s1_io_out_pp_15[80])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[80] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[81] && be_s1_io_out_pp_15[81])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[81] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[82] && be_s1_io_out_pp_15[82])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[82] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[83] && be_s1_io_out_pp_15[83])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[83] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[84] && be_s1_io_out_pp_15[84])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[84] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_15[85] && be_s1_io_out_pp_15[85])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_15[85] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[30] && be_s1_io_out_pp_16[30])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[30] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[32] && be_s1_io_out_pp_16[32])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[32] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[33] && be_s1_io_out_pp_16[33])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[33] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[34] && be_s1_io_out_pp_16[34])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[34] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[35] && be_s1_io_out_pp_16[35])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[35] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[36] && be_s1_io_out_pp_16[36])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[36] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[37] && be_s1_io_out_pp_16[37])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[37] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[38] && be_s1_io_out_pp_16[38])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[38] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[39] && be_s1_io_out_pp_16[39])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[39] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[40] && be_s1_io_out_pp_16[40])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[40] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[41] && be_s1_io_out_pp_16[41])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[41] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[42] && be_s1_io_out_pp_16[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[43] && be_s1_io_out_pp_16[43])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[43] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[44] && be_s1_io_out_pp_16[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[45] && be_s1_io_out_pp_16[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[46] && be_s1_io_out_pp_16[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[47] && be_s1_io_out_pp_16[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[48] && be_s1_io_out_pp_16[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[49] && be_s1_io_out_pp_16[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[50] && be_s1_io_out_pp_16[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[51] && be_s1_io_out_pp_16[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[52] && be_s1_io_out_pp_16[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[53] && be_s1_io_out_pp_16[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[54] && be_s1_io_out_pp_16[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[55] && be_s1_io_out_pp_16[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[56] && be_s1_io_out_pp_16[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[57] && be_s1_io_out_pp_16[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[58] && be_s1_io_out_pp_16[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[59] && be_s1_io_out_pp_16[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[60] && be_s1_io_out_pp_16[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[61] && be_s1_io_out_pp_16[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[62] && be_s1_io_out_pp_16[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[63] && be_s1_io_out_pp_16[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[64] && be_s1_io_out_pp_16[64])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[64] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[65] && be_s1_io_out_pp_16[65])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[65] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[66] && be_s1_io_out_pp_16[66])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[66] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[67] && be_s1_io_out_pp_16[67])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[67] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[68] && be_s1_io_out_pp_16[68])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[68] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[69] && be_s1_io_out_pp_16[69])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[69] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[70] && be_s1_io_out_pp_16[70])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[70] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[71] && be_s1_io_out_pp_16[71])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[71] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[72] && be_s1_io_out_pp_16[72])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[72] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[73] && be_s1_io_out_pp_16[73])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[73] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[74] && be_s1_io_out_pp_16[74])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[74] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[75] && be_s1_io_out_pp_16[75])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[75] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[76] && be_s1_io_out_pp_16[76])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[76] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[77] && be_s1_io_out_pp_16[77])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[77] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[78] && be_s1_io_out_pp_16[78])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[78] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[79] && be_s1_io_out_pp_16[79])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[79] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[80] && be_s1_io_out_pp_16[80])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[80] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[81] && be_s1_io_out_pp_16[81])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[81] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[82] && be_s1_io_out_pp_16[82])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[82] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[83] && be_s1_io_out_pp_16[83])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[83] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[84] && be_s1_io_out_pp_16[84])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[84] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[85] && be_s1_io_out_pp_16[85])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[85] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[86] && be_s1_io_out_pp_16[86])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[86] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_16[87] && be_s1_io_out_pp_16[87])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_16[87] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[32] && be_s1_io_out_pp_17[32])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[32] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[34] && be_s1_io_out_pp_17[34])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[34] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[35] && be_s1_io_out_pp_17[35])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[35] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[36] && be_s1_io_out_pp_17[36])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[36] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[37] && be_s1_io_out_pp_17[37])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[37] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[38] && be_s1_io_out_pp_17[38])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[38] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[39] && be_s1_io_out_pp_17[39])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[39] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[40] && be_s1_io_out_pp_17[40])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[40] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[41] && be_s1_io_out_pp_17[41])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[41] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[42] && be_s1_io_out_pp_17[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[43] && be_s1_io_out_pp_17[43])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[43] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[44] && be_s1_io_out_pp_17[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[45] && be_s1_io_out_pp_17[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[46] && be_s1_io_out_pp_17[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[47] && be_s1_io_out_pp_17[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[48] && be_s1_io_out_pp_17[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[49] && be_s1_io_out_pp_17[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[50] && be_s1_io_out_pp_17[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[51] && be_s1_io_out_pp_17[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[52] && be_s1_io_out_pp_17[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[53] && be_s1_io_out_pp_17[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[54] && be_s1_io_out_pp_17[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[55] && be_s1_io_out_pp_17[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[56] && be_s1_io_out_pp_17[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[57] && be_s1_io_out_pp_17[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[58] && be_s1_io_out_pp_17[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[59] && be_s1_io_out_pp_17[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[60] && be_s1_io_out_pp_17[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[61] && be_s1_io_out_pp_17[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[62] && be_s1_io_out_pp_17[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[63] && be_s1_io_out_pp_17[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[64] && be_s1_io_out_pp_17[64])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[64] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[65] && be_s1_io_out_pp_17[65])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[65] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[66] && be_s1_io_out_pp_17[66])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[66] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[67] && be_s1_io_out_pp_17[67])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[67] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[68] && be_s1_io_out_pp_17[68])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[68] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[69] && be_s1_io_out_pp_17[69])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[69] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[70] && be_s1_io_out_pp_17[70])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[70] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[71] && be_s1_io_out_pp_17[71])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[71] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[72] && be_s1_io_out_pp_17[72])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[72] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[73] && be_s1_io_out_pp_17[73])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[73] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[74] && be_s1_io_out_pp_17[74])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[74] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[75] && be_s1_io_out_pp_17[75])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[75] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[76] && be_s1_io_out_pp_17[76])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[76] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[77] && be_s1_io_out_pp_17[77])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[77] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[78] && be_s1_io_out_pp_17[78])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[78] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[79] && be_s1_io_out_pp_17[79])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[79] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[80] && be_s1_io_out_pp_17[80])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[80] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[81] && be_s1_io_out_pp_17[81])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[81] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[82] && be_s1_io_out_pp_17[82])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[82] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[83] && be_s1_io_out_pp_17[83])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[83] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[84] && be_s1_io_out_pp_17[84])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[84] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[85] && be_s1_io_out_pp_17[85])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[85] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[86] && be_s1_io_out_pp_17[86])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[86] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[87] && be_s1_io_out_pp_17[87])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[87] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[88] && be_s1_io_out_pp_17[88])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[88] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_17[89] && be_s1_io_out_pp_17[89])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_17[89] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[34] && be_s1_io_out_pp_18[34])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[34] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[36] && be_s1_io_out_pp_18[36])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[36] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[37] && be_s1_io_out_pp_18[37])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[37] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[38] && be_s1_io_out_pp_18[38])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[38] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[39] && be_s1_io_out_pp_18[39])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[39] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[40] && be_s1_io_out_pp_18[40])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[40] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[41] && be_s1_io_out_pp_18[41])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[41] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[42] && be_s1_io_out_pp_18[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[43] && be_s1_io_out_pp_18[43])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[43] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[44] && be_s1_io_out_pp_18[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[45] && be_s1_io_out_pp_18[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[46] && be_s1_io_out_pp_18[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[47] && be_s1_io_out_pp_18[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[48] && be_s1_io_out_pp_18[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[49] && be_s1_io_out_pp_18[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[50] && be_s1_io_out_pp_18[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[51] && be_s1_io_out_pp_18[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[52] && be_s1_io_out_pp_18[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[53] && be_s1_io_out_pp_18[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[54] && be_s1_io_out_pp_18[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[55] && be_s1_io_out_pp_18[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[56] && be_s1_io_out_pp_18[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[57] && be_s1_io_out_pp_18[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[58] && be_s1_io_out_pp_18[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[59] && be_s1_io_out_pp_18[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[60] && be_s1_io_out_pp_18[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[61] && be_s1_io_out_pp_18[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[62] && be_s1_io_out_pp_18[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[63] && be_s1_io_out_pp_18[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[64] && be_s1_io_out_pp_18[64])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[64] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[65] && be_s1_io_out_pp_18[65])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[65] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[66] && be_s1_io_out_pp_18[66])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[66] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[67] && be_s1_io_out_pp_18[67])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[67] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[68] && be_s1_io_out_pp_18[68])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[68] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[69] && be_s1_io_out_pp_18[69])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[69] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[70] && be_s1_io_out_pp_18[70])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[70] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[71] && be_s1_io_out_pp_18[71])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[71] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[72] && be_s1_io_out_pp_18[72])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[72] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[73] && be_s1_io_out_pp_18[73])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[73] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[74] && be_s1_io_out_pp_18[74])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[74] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[75] && be_s1_io_out_pp_18[75])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[75] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[76] && be_s1_io_out_pp_18[76])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[76] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[77] && be_s1_io_out_pp_18[77])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[77] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[78] && be_s1_io_out_pp_18[78])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[78] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[79] && be_s1_io_out_pp_18[79])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[79] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[80] && be_s1_io_out_pp_18[80])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[80] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[81] && be_s1_io_out_pp_18[81])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[81] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[82] && be_s1_io_out_pp_18[82])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[82] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[83] && be_s1_io_out_pp_18[83])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[83] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[84] && be_s1_io_out_pp_18[84])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[84] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[85] && be_s1_io_out_pp_18[85])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[85] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[86] && be_s1_io_out_pp_18[86])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[86] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[87] && be_s1_io_out_pp_18[87])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[87] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[88] && be_s1_io_out_pp_18[88])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[88] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[89] && be_s1_io_out_pp_18[89])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[89] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[90] && be_s1_io_out_pp_18[90])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[90] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_18[91] && be_s1_io_out_pp_18[91])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_18[91] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[36] && be_s1_io_out_pp_19[36])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[36] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[38] && be_s1_io_out_pp_19[38])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[38] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[39] && be_s1_io_out_pp_19[39])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[39] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[40] && be_s1_io_out_pp_19[40])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[40] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[41] && be_s1_io_out_pp_19[41])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[41] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[42] && be_s1_io_out_pp_19[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[43] && be_s1_io_out_pp_19[43])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[43] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[44] && be_s1_io_out_pp_19[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[45] && be_s1_io_out_pp_19[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[46] && be_s1_io_out_pp_19[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[47] && be_s1_io_out_pp_19[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[48] && be_s1_io_out_pp_19[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[49] && be_s1_io_out_pp_19[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[50] && be_s1_io_out_pp_19[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[51] && be_s1_io_out_pp_19[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[52] && be_s1_io_out_pp_19[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[53] && be_s1_io_out_pp_19[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[54] && be_s1_io_out_pp_19[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[55] && be_s1_io_out_pp_19[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[56] && be_s1_io_out_pp_19[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[57] && be_s1_io_out_pp_19[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[58] && be_s1_io_out_pp_19[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[59] && be_s1_io_out_pp_19[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[60] && be_s1_io_out_pp_19[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[61] && be_s1_io_out_pp_19[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[62] && be_s1_io_out_pp_19[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[63] && be_s1_io_out_pp_19[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[64] && be_s1_io_out_pp_19[64])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[64] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[65] && be_s1_io_out_pp_19[65])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[65] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[66] && be_s1_io_out_pp_19[66])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[66] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[67] && be_s1_io_out_pp_19[67])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[67] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[68] && be_s1_io_out_pp_19[68])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[68] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[69] && be_s1_io_out_pp_19[69])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[69] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[70] && be_s1_io_out_pp_19[70])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[70] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[71] && be_s1_io_out_pp_19[71])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[71] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[72] && be_s1_io_out_pp_19[72])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[72] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[73] && be_s1_io_out_pp_19[73])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[73] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[74] && be_s1_io_out_pp_19[74])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[74] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[75] && be_s1_io_out_pp_19[75])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[75] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[76] && be_s1_io_out_pp_19[76])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[76] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[77] && be_s1_io_out_pp_19[77])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[77] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[78] && be_s1_io_out_pp_19[78])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[78] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[79] && be_s1_io_out_pp_19[79])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[79] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[80] && be_s1_io_out_pp_19[80])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[80] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[81] && be_s1_io_out_pp_19[81])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[81] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[82] && be_s1_io_out_pp_19[82])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[82] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[83] && be_s1_io_out_pp_19[83])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[83] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[84] && be_s1_io_out_pp_19[84])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[84] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[85] && be_s1_io_out_pp_19[85])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[85] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[86] && be_s1_io_out_pp_19[86])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[86] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[87] && be_s1_io_out_pp_19[87])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[87] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[88] && be_s1_io_out_pp_19[88])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[88] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[89] && be_s1_io_out_pp_19[89])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[89] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[90] && be_s1_io_out_pp_19[90])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[90] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[91] && be_s1_io_out_pp_19[91])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[91] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[92] && be_s1_io_out_pp_19[92])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[92] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_19[93] && be_s1_io_out_pp_19[93])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_19[93] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[38] && be_s1_io_out_pp_20[38])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[38] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[40] && be_s1_io_out_pp_20[40])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[40] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[41] && be_s1_io_out_pp_20[41])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[41] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[42] && be_s1_io_out_pp_20[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[43] && be_s1_io_out_pp_20[43])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[43] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[44] && be_s1_io_out_pp_20[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[45] && be_s1_io_out_pp_20[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[46] && be_s1_io_out_pp_20[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[47] && be_s1_io_out_pp_20[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[48] && be_s1_io_out_pp_20[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[49] && be_s1_io_out_pp_20[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[50] && be_s1_io_out_pp_20[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[51] && be_s1_io_out_pp_20[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[52] && be_s1_io_out_pp_20[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[53] && be_s1_io_out_pp_20[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[54] && be_s1_io_out_pp_20[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[55] && be_s1_io_out_pp_20[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[56] && be_s1_io_out_pp_20[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[57] && be_s1_io_out_pp_20[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[58] && be_s1_io_out_pp_20[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[59] && be_s1_io_out_pp_20[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[60] && be_s1_io_out_pp_20[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[61] && be_s1_io_out_pp_20[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[62] && be_s1_io_out_pp_20[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[63] && be_s1_io_out_pp_20[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[64] && be_s1_io_out_pp_20[64])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[64] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[65] && be_s1_io_out_pp_20[65])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[65] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[66] && be_s1_io_out_pp_20[66])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[66] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[67] && be_s1_io_out_pp_20[67])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[67] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[68] && be_s1_io_out_pp_20[68])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[68] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[69] && be_s1_io_out_pp_20[69])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[69] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[70] && be_s1_io_out_pp_20[70])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[70] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[71] && be_s1_io_out_pp_20[71])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[71] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[72] && be_s1_io_out_pp_20[72])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[72] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[73] && be_s1_io_out_pp_20[73])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[73] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[74] && be_s1_io_out_pp_20[74])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[74] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[75] && be_s1_io_out_pp_20[75])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[75] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[76] && be_s1_io_out_pp_20[76])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[76] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[77] && be_s1_io_out_pp_20[77])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[77] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[78] && be_s1_io_out_pp_20[78])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[78] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[79] && be_s1_io_out_pp_20[79])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[79] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[80] && be_s1_io_out_pp_20[80])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[80] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[81] && be_s1_io_out_pp_20[81])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[81] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[82] && be_s1_io_out_pp_20[82])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[82] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[83] && be_s1_io_out_pp_20[83])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[83] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[84] && be_s1_io_out_pp_20[84])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[84] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[85] && be_s1_io_out_pp_20[85])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[85] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[86] && be_s1_io_out_pp_20[86])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[86] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[87] && be_s1_io_out_pp_20[87])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[87] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[88] && be_s1_io_out_pp_20[88])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[88] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[89] && be_s1_io_out_pp_20[89])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[89] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[90] && be_s1_io_out_pp_20[90])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[90] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[91] && be_s1_io_out_pp_20[91])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[91] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[92] && be_s1_io_out_pp_20[92])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[92] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[93] && be_s1_io_out_pp_20[93])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[93] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[94] && be_s1_io_out_pp_20[94])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[94] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_20[95] && be_s1_io_out_pp_20[95])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_20[95] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[40] && be_s1_io_out_pp_21[40])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[40] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[42] && be_s1_io_out_pp_21[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[43] && be_s1_io_out_pp_21[43])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[43] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[44] && be_s1_io_out_pp_21[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[45] && be_s1_io_out_pp_21[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[46] && be_s1_io_out_pp_21[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[47] && be_s1_io_out_pp_21[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[48] && be_s1_io_out_pp_21[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[49] && be_s1_io_out_pp_21[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[50] && be_s1_io_out_pp_21[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[51] && be_s1_io_out_pp_21[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[52] && be_s1_io_out_pp_21[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[53] && be_s1_io_out_pp_21[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[54] && be_s1_io_out_pp_21[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[55] && be_s1_io_out_pp_21[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[56] && be_s1_io_out_pp_21[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[57] && be_s1_io_out_pp_21[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[58] && be_s1_io_out_pp_21[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[59] && be_s1_io_out_pp_21[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[60] && be_s1_io_out_pp_21[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[61] && be_s1_io_out_pp_21[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[62] && be_s1_io_out_pp_21[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[63] && be_s1_io_out_pp_21[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[64] && be_s1_io_out_pp_21[64])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[64] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[65] && be_s1_io_out_pp_21[65])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[65] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[66] && be_s1_io_out_pp_21[66])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[66] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[67] && be_s1_io_out_pp_21[67])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[67] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[68] && be_s1_io_out_pp_21[68])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[68] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[69] && be_s1_io_out_pp_21[69])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[69] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[70] && be_s1_io_out_pp_21[70])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[70] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[71] && be_s1_io_out_pp_21[71])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[71] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[72] && be_s1_io_out_pp_21[72])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[72] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[73] && be_s1_io_out_pp_21[73])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[73] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[74] && be_s1_io_out_pp_21[74])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[74] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[75] && be_s1_io_out_pp_21[75])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[75] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[76] && be_s1_io_out_pp_21[76])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[76] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[77] && be_s1_io_out_pp_21[77])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[77] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[78] && be_s1_io_out_pp_21[78])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[78] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[79] && be_s1_io_out_pp_21[79])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[79] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[80] && be_s1_io_out_pp_21[80])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[80] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[81] && be_s1_io_out_pp_21[81])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[81] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[82] && be_s1_io_out_pp_21[82])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[82] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[83] && be_s1_io_out_pp_21[83])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[83] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[84] && be_s1_io_out_pp_21[84])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[84] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[85] && be_s1_io_out_pp_21[85])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[85] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[86] && be_s1_io_out_pp_21[86])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[86] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[87] && be_s1_io_out_pp_21[87])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[87] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[88] && be_s1_io_out_pp_21[88])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[88] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[89] && be_s1_io_out_pp_21[89])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[89] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[90] && be_s1_io_out_pp_21[90])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[90] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[91] && be_s1_io_out_pp_21[91])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[91] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[92] && be_s1_io_out_pp_21[92])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[92] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[93] && be_s1_io_out_pp_21[93])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[93] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[94] && be_s1_io_out_pp_21[94])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[94] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[95] && be_s1_io_out_pp_21[95])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[95] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[96] && be_s1_io_out_pp_21[96])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[96] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_21[97] && be_s1_io_out_pp_21[97])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_21[97] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[42] && be_s1_io_out_pp_22[42])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[42] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[44] && be_s1_io_out_pp_22[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[45] && be_s1_io_out_pp_22[45])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[45] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[46] && be_s1_io_out_pp_22[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[47] && be_s1_io_out_pp_22[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[48] && be_s1_io_out_pp_22[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[49] && be_s1_io_out_pp_22[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[50] && be_s1_io_out_pp_22[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[51] && be_s1_io_out_pp_22[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[52] && be_s1_io_out_pp_22[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[53] && be_s1_io_out_pp_22[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[54] && be_s1_io_out_pp_22[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[55] && be_s1_io_out_pp_22[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[56] && be_s1_io_out_pp_22[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[57] && be_s1_io_out_pp_22[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[58] && be_s1_io_out_pp_22[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[59] && be_s1_io_out_pp_22[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[60] && be_s1_io_out_pp_22[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[61] && be_s1_io_out_pp_22[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[62] && be_s1_io_out_pp_22[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[63] && be_s1_io_out_pp_22[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[64] && be_s1_io_out_pp_22[64])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[64] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[65] && be_s1_io_out_pp_22[65])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[65] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[66] && be_s1_io_out_pp_22[66])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[66] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[67] && be_s1_io_out_pp_22[67])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[67] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[68] && be_s1_io_out_pp_22[68])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[68] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[69] && be_s1_io_out_pp_22[69])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[69] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[70] && be_s1_io_out_pp_22[70])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[70] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[71] && be_s1_io_out_pp_22[71])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[71] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[72] && be_s1_io_out_pp_22[72])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[72] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[73] && be_s1_io_out_pp_22[73])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[73] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[74] && be_s1_io_out_pp_22[74])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[74] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[75] && be_s1_io_out_pp_22[75])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[75] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[76] && be_s1_io_out_pp_22[76])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[76] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[77] && be_s1_io_out_pp_22[77])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[77] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[78] && be_s1_io_out_pp_22[78])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[78] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[79] && be_s1_io_out_pp_22[79])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[79] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[80] && be_s1_io_out_pp_22[80])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[80] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[81] && be_s1_io_out_pp_22[81])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[81] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[82] && be_s1_io_out_pp_22[82])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[82] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[83] && be_s1_io_out_pp_22[83])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[83] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[84] && be_s1_io_out_pp_22[84])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[84] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[85] && be_s1_io_out_pp_22[85])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[85] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[86] && be_s1_io_out_pp_22[86])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[86] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[87] && be_s1_io_out_pp_22[87])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[87] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[88] && be_s1_io_out_pp_22[88])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[88] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[89] && be_s1_io_out_pp_22[89])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[89] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[90] && be_s1_io_out_pp_22[90])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[90] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[91] && be_s1_io_out_pp_22[91])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[91] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[92] && be_s1_io_out_pp_22[92])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[92] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[93] && be_s1_io_out_pp_22[93])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[93] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[94] && be_s1_io_out_pp_22[94])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[94] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[95] && be_s1_io_out_pp_22[95])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[95] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[96] && be_s1_io_out_pp_22[96])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[96] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[97] && be_s1_io_out_pp_22[97])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[97] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[98] && be_s1_io_out_pp_22[98])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[98] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_22[99] && be_s1_io_out_pp_22[99])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_22[99] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[44] && be_s1_io_out_pp_23[44])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[44] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[46] && be_s1_io_out_pp_23[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[47] && be_s1_io_out_pp_23[47])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[47] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[48] && be_s1_io_out_pp_23[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[49] && be_s1_io_out_pp_23[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[50] && be_s1_io_out_pp_23[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[51] && be_s1_io_out_pp_23[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[52] && be_s1_io_out_pp_23[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[53] && be_s1_io_out_pp_23[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[54] && be_s1_io_out_pp_23[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[55] && be_s1_io_out_pp_23[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[56] && be_s1_io_out_pp_23[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[57] && be_s1_io_out_pp_23[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[58] && be_s1_io_out_pp_23[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[59] && be_s1_io_out_pp_23[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[60] && be_s1_io_out_pp_23[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[61] && be_s1_io_out_pp_23[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[62] && be_s1_io_out_pp_23[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[63] && be_s1_io_out_pp_23[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[64] && be_s1_io_out_pp_23[64])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[64] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[65] && be_s1_io_out_pp_23[65])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[65] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[66] && be_s1_io_out_pp_23[66])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[66] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[67] && be_s1_io_out_pp_23[67])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[67] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[68] && be_s1_io_out_pp_23[68])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[68] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[69] && be_s1_io_out_pp_23[69])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[69] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[70] && be_s1_io_out_pp_23[70])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[70] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[71] && be_s1_io_out_pp_23[71])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[71] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[72] && be_s1_io_out_pp_23[72])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[72] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[73] && be_s1_io_out_pp_23[73])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[73] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[74] && be_s1_io_out_pp_23[74])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[74] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[75] && be_s1_io_out_pp_23[75])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[75] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[76] && be_s1_io_out_pp_23[76])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[76] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[77] && be_s1_io_out_pp_23[77])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[77] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[78] && be_s1_io_out_pp_23[78])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[78] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[79] && be_s1_io_out_pp_23[79])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[79] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[80] && be_s1_io_out_pp_23[80])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[80] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[81] && be_s1_io_out_pp_23[81])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[81] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[82] && be_s1_io_out_pp_23[82])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[82] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[83] && be_s1_io_out_pp_23[83])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[83] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[84] && be_s1_io_out_pp_23[84])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[84] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[85] && be_s1_io_out_pp_23[85])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[85] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[86] && be_s1_io_out_pp_23[86])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[86] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[87] && be_s1_io_out_pp_23[87])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[87] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[88] && be_s1_io_out_pp_23[88])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[88] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[89] && be_s1_io_out_pp_23[89])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[89] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[90] && be_s1_io_out_pp_23[90])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[90] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[91] && be_s1_io_out_pp_23[91])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[91] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[92] && be_s1_io_out_pp_23[92])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[92] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[93] && be_s1_io_out_pp_23[93])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[93] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[94] && be_s1_io_out_pp_23[94])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[94] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[95] && be_s1_io_out_pp_23[95])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[95] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[96] && be_s1_io_out_pp_23[96])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[96] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[97] && be_s1_io_out_pp_23[97])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[97] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[98] && be_s1_io_out_pp_23[98])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[98] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[99] && be_s1_io_out_pp_23[99])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[99] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[100] && be_s1_io_out_pp_23[100])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[100] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_23[101] && be_s1_io_out_pp_23[101])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_23[101] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[46] && be_s1_io_out_pp_24[46])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[46] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[48] && be_s1_io_out_pp_24[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[49] && be_s1_io_out_pp_24[49])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[49] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[50] && be_s1_io_out_pp_24[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[51] && be_s1_io_out_pp_24[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[52] && be_s1_io_out_pp_24[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[53] && be_s1_io_out_pp_24[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[54] && be_s1_io_out_pp_24[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[55] && be_s1_io_out_pp_24[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[56] && be_s1_io_out_pp_24[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[57] && be_s1_io_out_pp_24[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[58] && be_s1_io_out_pp_24[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[59] && be_s1_io_out_pp_24[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[60] && be_s1_io_out_pp_24[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[61] && be_s1_io_out_pp_24[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[62] && be_s1_io_out_pp_24[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[63] && be_s1_io_out_pp_24[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[64] && be_s1_io_out_pp_24[64])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[64] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[65] && be_s1_io_out_pp_24[65])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[65] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[66] && be_s1_io_out_pp_24[66])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[66] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[67] && be_s1_io_out_pp_24[67])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[67] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[68] && be_s1_io_out_pp_24[68])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[68] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[69] && be_s1_io_out_pp_24[69])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[69] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[70] && be_s1_io_out_pp_24[70])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[70] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[71] && be_s1_io_out_pp_24[71])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[71] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[72] && be_s1_io_out_pp_24[72])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[72] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[73] && be_s1_io_out_pp_24[73])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[73] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[74] && be_s1_io_out_pp_24[74])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[74] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[75] && be_s1_io_out_pp_24[75])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[75] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[76] && be_s1_io_out_pp_24[76])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[76] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[77] && be_s1_io_out_pp_24[77])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[77] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[78] && be_s1_io_out_pp_24[78])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[78] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[79] && be_s1_io_out_pp_24[79])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[79] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[80] && be_s1_io_out_pp_24[80])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[80] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[81] && be_s1_io_out_pp_24[81])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[81] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[82] && be_s1_io_out_pp_24[82])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[82] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[83] && be_s1_io_out_pp_24[83])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[83] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[84] && be_s1_io_out_pp_24[84])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[84] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[85] && be_s1_io_out_pp_24[85])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[85] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[86] && be_s1_io_out_pp_24[86])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[86] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[87] && be_s1_io_out_pp_24[87])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[87] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[88] && be_s1_io_out_pp_24[88])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[88] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[89] && be_s1_io_out_pp_24[89])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[89] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[90] && be_s1_io_out_pp_24[90])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[90] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[91] && be_s1_io_out_pp_24[91])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[91] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[92] && be_s1_io_out_pp_24[92])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[92] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[93] && be_s1_io_out_pp_24[93])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[93] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[94] && be_s1_io_out_pp_24[94])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[94] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[95] && be_s1_io_out_pp_24[95])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[95] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[96] && be_s1_io_out_pp_24[96])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[96] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[97] && be_s1_io_out_pp_24[97])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[97] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[98] && be_s1_io_out_pp_24[98])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[98] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[99] && be_s1_io_out_pp_24[99])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[99] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[100] && be_s1_io_out_pp_24[100])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[100] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[101] && be_s1_io_out_pp_24[101])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[101] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[102] && be_s1_io_out_pp_24[102])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[102] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_24[103] && be_s1_io_out_pp_24[103])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_24[103] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[48] && be_s1_io_out_pp_25[48])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[48] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[50] && be_s1_io_out_pp_25[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[51] && be_s1_io_out_pp_25[51])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[51] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[52] && be_s1_io_out_pp_25[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[53] && be_s1_io_out_pp_25[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[54] && be_s1_io_out_pp_25[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[55] && be_s1_io_out_pp_25[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[56] && be_s1_io_out_pp_25[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[57] && be_s1_io_out_pp_25[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[58] && be_s1_io_out_pp_25[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[59] && be_s1_io_out_pp_25[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[60] && be_s1_io_out_pp_25[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[61] && be_s1_io_out_pp_25[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[62] && be_s1_io_out_pp_25[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[63] && be_s1_io_out_pp_25[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[64] && be_s1_io_out_pp_25[64])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[64] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[65] && be_s1_io_out_pp_25[65])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[65] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[66] && be_s1_io_out_pp_25[66])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[66] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[67] && be_s1_io_out_pp_25[67])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[67] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[68] && be_s1_io_out_pp_25[68])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[68] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[69] && be_s1_io_out_pp_25[69])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[69] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[70] && be_s1_io_out_pp_25[70])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[70] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[71] && be_s1_io_out_pp_25[71])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[71] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[72] && be_s1_io_out_pp_25[72])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[72] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[73] && be_s1_io_out_pp_25[73])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[73] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[74] && be_s1_io_out_pp_25[74])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[74] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[75] && be_s1_io_out_pp_25[75])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[75] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[76] && be_s1_io_out_pp_25[76])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[76] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[77] && be_s1_io_out_pp_25[77])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[77] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[78] && be_s1_io_out_pp_25[78])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[78] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[79] && be_s1_io_out_pp_25[79])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[79] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[80] && be_s1_io_out_pp_25[80])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[80] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[81] && be_s1_io_out_pp_25[81])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[81] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[82] && be_s1_io_out_pp_25[82])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[82] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[83] && be_s1_io_out_pp_25[83])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[83] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[84] && be_s1_io_out_pp_25[84])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[84] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[85] && be_s1_io_out_pp_25[85])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[85] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[86] && be_s1_io_out_pp_25[86])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[86] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[87] && be_s1_io_out_pp_25[87])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[87] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[88] && be_s1_io_out_pp_25[88])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[88] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[89] && be_s1_io_out_pp_25[89])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[89] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[90] && be_s1_io_out_pp_25[90])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[90] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[91] && be_s1_io_out_pp_25[91])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[91] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[92] && be_s1_io_out_pp_25[92])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[92] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[93] && be_s1_io_out_pp_25[93])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[93] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[94] && be_s1_io_out_pp_25[94])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[94] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[95] && be_s1_io_out_pp_25[95])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[95] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[96] && be_s1_io_out_pp_25[96])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[96] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[97] && be_s1_io_out_pp_25[97])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[97] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[98] && be_s1_io_out_pp_25[98])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[98] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[99] && be_s1_io_out_pp_25[99])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[99] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[100] && be_s1_io_out_pp_25[100])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[100] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[101] && be_s1_io_out_pp_25[101])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[101] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[102] && be_s1_io_out_pp_25[102])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[102] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[103] && be_s1_io_out_pp_25[103])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[103] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[104] && be_s1_io_out_pp_25[104])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[104] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_25[105] && be_s1_io_out_pp_25[105])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_25[105] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[50] && be_s1_io_out_pp_26[50])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[50] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[52] && be_s1_io_out_pp_26[52])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[52] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[53] && be_s1_io_out_pp_26[53])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[53] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[54] && be_s1_io_out_pp_26[54])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[54] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[55] && be_s1_io_out_pp_26[55])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[55] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[56] && be_s1_io_out_pp_26[56])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[56] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[57] && be_s1_io_out_pp_26[57])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[57] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[58] && be_s1_io_out_pp_26[58])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[58] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[59] && be_s1_io_out_pp_26[59])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[59] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[60] && be_s1_io_out_pp_26[60])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[60] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[61] && be_s1_io_out_pp_26[61])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[61] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[62] && be_s1_io_out_pp_26[62])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[62] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[63] && be_s1_io_out_pp_26[63])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[63] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[64] && be_s1_io_out_pp_26[64])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[64] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[65] && be_s1_io_out_pp_26[65])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[65] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[66] && be_s1_io_out_pp_26[66])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[66] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[67] && be_s1_io_out_pp_26[67])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[67] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[68] && be_s1_io_out_pp_26[68])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[68] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[69] && be_s1_io_out_pp_26[69])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[69] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[70] && be_s1_io_out_pp_26[70])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[70] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[71] && be_s1_io_out_pp_26[71])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[71] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[72] && be_s1_io_out_pp_26[72])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[72] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[73] && be_s1_io_out_pp_26[73])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[73] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[74] && be_s1_io_out_pp_26[74])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[74] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[75] && be_s1_io_out_pp_26[75])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[75] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[76] && be_s1_io_out_pp_26[76])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[76] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[77] && be_s1_io_out_pp_26[77])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[77] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[78] && be_s1_io_out_pp_26[78])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[78] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[79] && be_s1_io_out_pp_26[79])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[79] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[80] && be_s1_io_out_pp_26[80])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[80] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[81] && be_s1_io_out_pp_26[81])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[81] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[82] && be_s1_io_out_pp_26[82])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[82] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[83] && be_s1_io_out_pp_26[83])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[83] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[84] && be_s1_io_out_pp_26[84])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[84] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[85] && be_s1_io_out_pp_26[85])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[85] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[86] && be_s1_io_out_pp_26[86])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[86] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[87] && be_s1_io_out_pp_26[87])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[87] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[88] && be_s1_io_out_pp_26[88])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[88] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[89] && be_s1_io_out_pp_26[89])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[89] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[90] && be_s1_io_out_pp_26[90])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[90] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[91] && be_s1_io_out_pp_26[91])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[91] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[92] && be_s1_io_out_pp_26[92])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[92] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[93] && be_s1_io_out_pp_26[93])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[93] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[94] && be_s1_io_out_pp_26[94])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[94] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[95] && be_s1_io_out_pp_26[95])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[95] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[96] && be_s1_io_out_pp_26[96])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[96] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[97] && be_s1_io_out_pp_26[97])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[97] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[98] && be_s1_io_out_pp_26[98])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[98] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[99] && be_s1_io_out_pp_26[99])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[99] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[100] && be_s1_io_out_pp_26[100])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[100] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[101] && be_s1_io_out_pp_26[101])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[101] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[102] && be_s1_io_out_pp_26[102])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[102] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[103] && be_s1_io_out_pp_26[103])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[103] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[104] && be_s1_io_out_pp_26[104])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[104] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[105] && be_s1_io_out_pp_26[105])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[105] 未见过 0 和 1"); end
    if (!(be_s0_io_out_pp_26[106] && be_s1_io_out_pp_26[106])) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.io_out_pp_26[106] 未见过 0 和 1"); end
    $display("[ARM] BoothEncoderF64F32F16 armed_at=%0d", be_armed_at);
    if (be_armed_at < 0) begin cov_fail++; $display("[ARM] BoothEncoderF64F32F16 从未 arm"); end
    $display("[COV] BoothEncoderF64F32F16.fmt_f64 = %0d", be_cov_fmt_f64);
    if (be_cov_fmt_f64 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.fmt_f64 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.fmt_f32 = %0d", be_cov_fmt_f32);
    if (be_cov_fmt_f32 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.fmt_f32 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.fmt_f16 = %0d", be_cov_fmt_f16);
    if (be_cov_fmt_f16 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.fmt_f16 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.fmt_both = %0d", be_cov_fmt_both);
    if (be_cov_fmt_both < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.fmt_both < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d0_pos1 = %0d", be_cov_d0_pos1);
    if (be_cov_d0_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d0_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d0_neg1 = %0d", be_cov_d0_neg1);
    if (be_cov_d0_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d0_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d0_neg2 = %0d", be_cov_d0_neg2);
    if (be_cov_d0_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d0_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d1_pos1 = %0d", be_cov_d1_pos1);
    if (be_cov_d1_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d1_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d1_pos2 = %0d", be_cov_d1_pos2);
    if (be_cov_d1_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d1_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d1_neg1 = %0d", be_cov_d1_neg1);
    if (be_cov_d1_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d1_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d1_neg2 = %0d", be_cov_d1_neg2);
    if (be_cov_d1_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d1_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d2_pos1 = %0d", be_cov_d2_pos1);
    if (be_cov_d2_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d2_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d2_pos2 = %0d", be_cov_d2_pos2);
    if (be_cov_d2_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d2_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d2_neg1 = %0d", be_cov_d2_neg1);
    if (be_cov_d2_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d2_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d2_neg2 = %0d", be_cov_d2_neg2);
    if (be_cov_d2_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d2_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d3_pos1 = %0d", be_cov_d3_pos1);
    if (be_cov_d3_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d3_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d3_pos2 = %0d", be_cov_d3_pos2);
    if (be_cov_d3_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d3_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d3_neg1 = %0d", be_cov_d3_neg1);
    if (be_cov_d3_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d3_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d3_neg2 = %0d", be_cov_d3_neg2);
    if (be_cov_d3_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d3_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d4_pos1 = %0d", be_cov_d4_pos1);
    if (be_cov_d4_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d4_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d4_pos2 = %0d", be_cov_d4_pos2);
    if (be_cov_d4_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d4_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d4_neg1 = %0d", be_cov_d4_neg1);
    if (be_cov_d4_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d4_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d4_neg2 = %0d", be_cov_d4_neg2);
    if (be_cov_d4_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d4_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d5_pos1 = %0d", be_cov_d5_pos1);
    if (be_cov_d5_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d5_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d5_pos2 = %0d", be_cov_d5_pos2);
    if (be_cov_d5_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d5_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d5_neg1 = %0d", be_cov_d5_neg1);
    if (be_cov_d5_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d5_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d5_neg2 = %0d", be_cov_d5_neg2);
    if (be_cov_d5_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d5_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d6_pos1 = %0d", be_cov_d6_pos1);
    if (be_cov_d6_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d6_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d6_pos2 = %0d", be_cov_d6_pos2);
    if (be_cov_d6_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d6_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d6_neg1 = %0d", be_cov_d6_neg1);
    if (be_cov_d6_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d6_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d6_neg2 = %0d", be_cov_d6_neg2);
    if (be_cov_d6_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d6_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d7_pos1 = %0d", be_cov_d7_pos1);
    if (be_cov_d7_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d7_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d7_pos2 = %0d", be_cov_d7_pos2);
    if (be_cov_d7_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d7_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d7_neg1 = %0d", be_cov_d7_neg1);
    if (be_cov_d7_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d7_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d7_neg2 = %0d", be_cov_d7_neg2);
    if (be_cov_d7_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d7_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d8_pos1 = %0d", be_cov_d8_pos1);
    if (be_cov_d8_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d8_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d8_pos2 = %0d", be_cov_d8_pos2);
    if (be_cov_d8_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d8_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d8_neg1 = %0d", be_cov_d8_neg1);
    if (be_cov_d8_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d8_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d8_neg2 = %0d", be_cov_d8_neg2);
    if (be_cov_d8_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d8_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d9_pos1 = %0d", be_cov_d9_pos1);
    if (be_cov_d9_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d9_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d9_pos2 = %0d", be_cov_d9_pos2);
    if (be_cov_d9_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d9_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d9_neg1 = %0d", be_cov_d9_neg1);
    if (be_cov_d9_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d9_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d9_neg2 = %0d", be_cov_d9_neg2);
    if (be_cov_d9_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d9_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d10_pos1 = %0d", be_cov_d10_pos1);
    if (be_cov_d10_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d10_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d10_pos2 = %0d", be_cov_d10_pos2);
    if (be_cov_d10_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d10_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d10_neg1 = %0d", be_cov_d10_neg1);
    if (be_cov_d10_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d10_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d10_neg2 = %0d", be_cov_d10_neg2);
    if (be_cov_d10_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d10_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d11_pos1 = %0d", be_cov_d11_pos1);
    if (be_cov_d11_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d11_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d11_pos2 = %0d", be_cov_d11_pos2);
    if (be_cov_d11_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d11_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d11_neg1 = %0d", be_cov_d11_neg1);
    if (be_cov_d11_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d11_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d11_neg2 = %0d", be_cov_d11_neg2);
    if (be_cov_d11_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d11_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d12_pos1 = %0d", be_cov_d12_pos1);
    if (be_cov_d12_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d12_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d12_pos2 = %0d", be_cov_d12_pos2);
    if (be_cov_d12_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d12_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d12_neg1 = %0d", be_cov_d12_neg1);
    if (be_cov_d12_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d12_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d12_neg2 = %0d", be_cov_d12_neg2);
    if (be_cov_d12_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d12_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d13_pos1 = %0d", be_cov_d13_pos1);
    if (be_cov_d13_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d13_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d13_pos2 = %0d", be_cov_d13_pos2);
    if (be_cov_d13_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d13_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d13_neg1 = %0d", be_cov_d13_neg1);
    if (be_cov_d13_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d13_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d13_neg2 = %0d", be_cov_d13_neg2);
    if (be_cov_d13_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d13_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d14_pos1 = %0d", be_cov_d14_pos1);
    if (be_cov_d14_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d14_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d14_pos2 = %0d", be_cov_d14_pos2);
    if (be_cov_d14_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d14_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d14_neg1 = %0d", be_cov_d14_neg1);
    if (be_cov_d14_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d14_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d14_neg2 = %0d", be_cov_d14_neg2);
    if (be_cov_d14_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d14_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d15_pos1 = %0d", be_cov_d15_pos1);
    if (be_cov_d15_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d15_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d15_pos2 = %0d", be_cov_d15_pos2);
    if (be_cov_d15_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d15_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d15_neg1 = %0d", be_cov_d15_neg1);
    if (be_cov_d15_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d15_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d15_neg2 = %0d", be_cov_d15_neg2);
    if (be_cov_d15_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d15_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d16_pos1 = %0d", be_cov_d16_pos1);
    if (be_cov_d16_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d16_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d16_pos2 = %0d", be_cov_d16_pos2);
    if (be_cov_d16_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d16_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d16_neg1 = %0d", be_cov_d16_neg1);
    if (be_cov_d16_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d16_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d16_neg2 = %0d", be_cov_d16_neg2);
    if (be_cov_d16_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d16_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d17_pos1 = %0d", be_cov_d17_pos1);
    if (be_cov_d17_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d17_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d17_pos2 = %0d", be_cov_d17_pos2);
    if (be_cov_d17_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d17_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d17_neg1 = %0d", be_cov_d17_neg1);
    if (be_cov_d17_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d17_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d17_neg2 = %0d", be_cov_d17_neg2);
    if (be_cov_d17_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d17_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d18_pos1 = %0d", be_cov_d18_pos1);
    if (be_cov_d18_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d18_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d18_pos2 = %0d", be_cov_d18_pos2);
    if (be_cov_d18_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d18_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d18_neg1 = %0d", be_cov_d18_neg1);
    if (be_cov_d18_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d18_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d18_neg2 = %0d", be_cov_d18_neg2);
    if (be_cov_d18_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d18_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d19_pos1 = %0d", be_cov_d19_pos1);
    if (be_cov_d19_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d19_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d19_pos2 = %0d", be_cov_d19_pos2);
    if (be_cov_d19_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d19_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d19_neg1 = %0d", be_cov_d19_neg1);
    if (be_cov_d19_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d19_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d19_neg2 = %0d", be_cov_d19_neg2);
    if (be_cov_d19_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d19_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d20_pos1 = %0d", be_cov_d20_pos1);
    if (be_cov_d20_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d20_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d20_pos2 = %0d", be_cov_d20_pos2);
    if (be_cov_d20_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d20_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d20_neg1 = %0d", be_cov_d20_neg1);
    if (be_cov_d20_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d20_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d20_neg2 = %0d", be_cov_d20_neg2);
    if (be_cov_d20_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d20_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d21_pos1 = %0d", be_cov_d21_pos1);
    if (be_cov_d21_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d21_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d21_pos2 = %0d", be_cov_d21_pos2);
    if (be_cov_d21_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d21_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d21_neg1 = %0d", be_cov_d21_neg1);
    if (be_cov_d21_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d21_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d21_neg2 = %0d", be_cov_d21_neg2);
    if (be_cov_d21_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d21_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d22_pos1 = %0d", be_cov_d22_pos1);
    if (be_cov_d22_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d22_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d22_pos2 = %0d", be_cov_d22_pos2);
    if (be_cov_d22_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d22_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d22_neg1 = %0d", be_cov_d22_neg1);
    if (be_cov_d22_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d22_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d22_neg2 = %0d", be_cov_d22_neg2);
    if (be_cov_d22_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d22_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d23_pos1 = %0d", be_cov_d23_pos1);
    if (be_cov_d23_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d23_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d23_pos2 = %0d", be_cov_d23_pos2);
    if (be_cov_d23_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d23_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d23_neg1 = %0d", be_cov_d23_neg1);
    if (be_cov_d23_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d23_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d23_neg2 = %0d", be_cov_d23_neg2);
    if (be_cov_d23_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d23_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d24_pos1 = %0d", be_cov_d24_pos1);
    if (be_cov_d24_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d24_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d24_pos2 = %0d", be_cov_d24_pos2);
    if (be_cov_d24_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d24_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d24_neg1 = %0d", be_cov_d24_neg1);
    if (be_cov_d24_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d24_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d24_neg2 = %0d", be_cov_d24_neg2);
    if (be_cov_d24_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d24_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d25_pos1 = %0d", be_cov_d25_pos1);
    if (be_cov_d25_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d25_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d25_pos2 = %0d", be_cov_d25_pos2);
    if (be_cov_d25_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d25_pos2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d25_neg1 = %0d", be_cov_d25_neg1);
    if (be_cov_d25_neg1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d25_neg1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d25_neg2 = %0d", be_cov_d25_neg2);
    if (be_cov_d25_neg2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d25_neg2 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d26_pos1 = %0d", be_cov_d26_pos1);
    if (be_cov_d26_pos1 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d26_pos1 < 300"); end
    $display("[COV] BoothEncoderF64F32F16.d26_pos2 = %0d", be_cov_d26_pos2);
    if (be_cov_d26_pos2 < 300) begin cov_fail++; $display("[COV] BoothEncoderF64F32F16.d26_pos2 < 300"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
