// 自动生成：verif/ut/CSA_Nto2With3to2MainPipeline/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// CSA_Nto2With3to2MainPipeline 双例化逐拍比对：golden vs 重写 CSA_Nto2With3to2MainPipeline_xs。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= CSA_Nto2With3to2MainPipeline =================
  int unsigned csa_mode = 0;
  always @(posedge clk) tb.csa_clock = 1'b1;   // 本模块无 reset 端口，时钟自己驱动（见 gen.py 文件头）
  function automatic logic [106:0] csa_rnd(input int unsigned mode);
    logic [106:0] v;
    v = {$urandom, $urandom, $urandom, $urandom};
    case (mode % 4)
      0: ;                                                    // 全随机
      1: v = v & {$urandom, $urandom, $urandom, $urandom}
               & {$urandom, $urandom, $urandom, $urandom};    // 稀疏
      2: v = ($urandom_range(0, 3) == 0) ? '1 : v;            // 常有全 1
      default: v = v | ({107{1'b1}} << $urandom_range(20, 106)); // 高位补 1（Booth 形状）
    endcase
    return v;
  endfunction
  logic csa_clock;
  logic csa_io_fire;
  logic [106:0] csa_io_in_0;
  logic [106:0] csa_io_in_1;
  logic [106:0] csa_io_in_2;
  logic [106:0] csa_io_in_3;
  logic [106:0] csa_io_in_4;
  logic [106:0] csa_io_in_5;
  logic [106:0] csa_io_in_6;
  logic [106:0] csa_io_in_7;
  logic [106:0] csa_io_in_8;
  logic [106:0] csa_io_in_9;
  logic [106:0] csa_io_in_10;
  logic [106:0] csa_io_in_11;
  logic [106:0] csa_io_in_12;
  logic [106:0] csa_io_in_13;
  logic [106:0] csa_io_in_14;
  logic [106:0] csa_io_in_15;
  logic [106:0] csa_io_in_16;
  logic [106:0] csa_io_in_17;
  logic [106:0] csa_io_in_18;
  logic [106:0] csa_io_in_19;
  logic [106:0] csa_io_in_20;
  logic [106:0] csa_io_in_21;
  logic [106:0] csa_io_in_22;
  logic [106:0] csa_io_in_23;
  logic [106:0] csa_io_in_24;
  logic [106:0] csa_io_in_25;
  logic [106:0] csa_io_in_26;
  wire  [106:0] csa_g_io_out_sum, csa_i_io_out_sum;
  logic [106:0] csa_s0_io_out_sum = '0, csa_s1_io_out_sum = '0;
  wire  [106:0] csa_g_io_out_car, csa_i_io_out_car;
  logic [106:0] csa_s0_io_out_car = '0, csa_s1_io_out_car = '0;
  int csa_cov_fire_hi = 0;
  int csa_cov_fire_lo = 0;
  logic [0:0] csa_armed = '0;
  int csa_armed_at = -1;
  CSA_Nto2With3to2MainPipeline csa_u_gold (
    .clock(csa_clock),
    .io_fire(csa_io_fire),
    .io_in_0(csa_io_in_0),
    .io_in_1(csa_io_in_1),
    .io_in_2(csa_io_in_2),
    .io_in_3(csa_io_in_3),
    .io_in_4(csa_io_in_4),
    .io_in_5(csa_io_in_5),
    .io_in_6(csa_io_in_6),
    .io_in_7(csa_io_in_7),
    .io_in_8(csa_io_in_8),
    .io_in_9(csa_io_in_9),
    .io_in_10(csa_io_in_10),
    .io_in_11(csa_io_in_11),
    .io_in_12(csa_io_in_12),
    .io_in_13(csa_io_in_13),
    .io_in_14(csa_io_in_14),
    .io_in_15(csa_io_in_15),
    .io_in_16(csa_io_in_16),
    .io_in_17(csa_io_in_17),
    .io_in_18(csa_io_in_18),
    .io_in_19(csa_io_in_19),
    .io_in_20(csa_io_in_20),
    .io_in_21(csa_io_in_21),
    .io_in_22(csa_io_in_22),
    .io_in_23(csa_io_in_23),
    .io_in_24(csa_io_in_24),
    .io_in_25(csa_io_in_25),
    .io_in_26(csa_io_in_26),
    .io_out_sum(csa_g_io_out_sum),
    .io_out_car(csa_g_io_out_car)
  );
  CSA_Nto2With3to2MainPipeline_xs csa_u_impl (
    .clock(csa_clock),
    .io_fire(csa_io_fire),
    .io_in_0(csa_io_in_0),
    .io_in_1(csa_io_in_1),
    .io_in_2(csa_io_in_2),
    .io_in_3(csa_io_in_3),
    .io_in_4(csa_io_in_4),
    .io_in_5(csa_io_in_5),
    .io_in_6(csa_io_in_6),
    .io_in_7(csa_io_in_7),
    .io_in_8(csa_io_in_8),
    .io_in_9(csa_io_in_9),
    .io_in_10(csa_io_in_10),
    .io_in_11(csa_io_in_11),
    .io_in_12(csa_io_in_12),
    .io_in_13(csa_io_in_13),
    .io_in_14(csa_io_in_14),
    .io_in_15(csa_io_in_15),
    .io_in_16(csa_io_in_16),
    .io_in_17(csa_io_in_17),
    .io_in_18(csa_io_in_18),
    .io_in_19(csa_io_in_19),
    .io_in_20(csa_io_in_20),
    .io_in_21(csa_io_in_21),
    .io_in_22(csa_io_in_22),
    .io_in_23(csa_io_in_23),
    .io_in_24(csa_io_in_24),
    .io_in_25(csa_io_in_25),
    .io_in_26(csa_io_in_26),
    .io_out_sum(csa_i_io_out_sum),
    .io_out_car(csa_i_io_out_car)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 500 == 0) csa_mode = $urandom_range(0, 15);
      csa_clock = 1'($urandom);
      csa_io_fire = 1'($urandom);
      csa_io_in_0 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_1 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_2 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_3 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_4 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_5 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_6 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_7 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_8 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_9 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_10 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_11 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_12 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_13 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_14 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_15 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_16 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_17 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_18 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_19 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_20 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_21 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_22 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_23 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_24 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_25 = 107'({$urandom, $urandom, $urandom, $urandom});
      csa_io_in_26 = 107'({$urandom, $urandom, $urandom, $urandom});
      begin : stim_csa
        csa_clock = 1'b0;
        csa_io_fire = ($urandom_range(0, 3) != 0);
        csa_io_in_0 = csa_rnd(csa_mode);
        csa_io_in_1 = csa_rnd(csa_mode);
        csa_io_in_2 = csa_rnd(csa_mode);
        csa_io_in_3 = csa_rnd(csa_mode);
        csa_io_in_4 = csa_rnd(csa_mode);
        csa_io_in_5 = csa_rnd(csa_mode);
        csa_io_in_6 = csa_rnd(csa_mode);
        csa_io_in_7 = csa_rnd(csa_mode);
        csa_io_in_8 = csa_rnd(csa_mode);
        csa_io_in_9 = csa_rnd(csa_mode);
        csa_io_in_10 = csa_rnd(csa_mode);
        csa_io_in_11 = csa_rnd(csa_mode);
        csa_io_in_12 = csa_rnd(csa_mode);
        csa_io_in_13 = csa_rnd(csa_mode);
        csa_io_in_14 = csa_rnd(csa_mode);
        csa_io_in_15 = csa_rnd(csa_mode);
        csa_io_in_16 = csa_rnd(csa_mode);
        csa_io_in_17 = csa_rnd(csa_mode);
        csa_io_in_18 = csa_rnd(csa_mode);
        csa_io_in_19 = csa_rnd(csa_mode);
        csa_io_in_20 = csa_rnd(csa_mode);
        csa_io_in_21 = csa_rnd(csa_mode);
        csa_io_in_22 = csa_rnd(csa_mode);
        csa_io_in_23 = csa_rnd(csa_mode);
        csa_io_in_24 = csa_rnd(csa_mode);
        csa_io_in_25 = csa_rnd(csa_mode);
        csa_io_in_26 = csa_rnd(csa_mode);
      end
      #4;
      if (cyc >= RESET_CYC + 0 && (&csa_armed)) begin
        checks++;
        if (csa_g_io_out_sum !== csa_i_io_out_sum) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CSA_Nto2With3to2MainPipeline.io_out_sum g=%h i=%h", cyc, csa_g_io_out_sum, csa_i_io_out_sum);
        end
        csa_s1_io_out_sum |= csa_g_io_out_sum;
        csa_s0_io_out_sum |= ~csa_g_io_out_sum;
        checks++;
        if (csa_g_io_out_car !== csa_i_io_out_car) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CSA_Nto2With3to2MainPipeline.io_out_car g=%h i=%h", cyc, csa_g_io_out_car, csa_i_io_out_car);
        end
        csa_s1_io_out_car |= csa_g_io_out_car;
        csa_s0_io_out_car |= ~csa_g_io_out_car;
        if (csa_io_fire) csa_cov_fire_hi++;
        if (!csa_io_fire) csa_cov_fire_lo++;
      end
      if (csa_io_fire) csa_armed[0] = 1'b1;
      if (csa_armed_at < 0 && (&csa_armed)) csa_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(csa_s0_io_out_sum[0] && csa_s1_io_out_sum[0])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[0] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[2] && csa_s1_io_out_sum[2])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[2] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[3] && csa_s1_io_out_sum[3])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[3] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[4] && csa_s1_io_out_sum[4])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[4] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[5] && csa_s1_io_out_sum[5])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[5] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[6] && csa_s1_io_out_sum[6])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[6] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[7] && csa_s1_io_out_sum[7])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[7] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[8] && csa_s1_io_out_sum[8])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[8] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[9] && csa_s1_io_out_sum[9])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[9] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[10] && csa_s1_io_out_sum[10])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[10] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[11] && csa_s1_io_out_sum[11])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[11] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[12] && csa_s1_io_out_sum[12])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[12] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[13] && csa_s1_io_out_sum[13])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[13] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[14] && csa_s1_io_out_sum[14])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[14] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[15] && csa_s1_io_out_sum[15])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[15] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[16] && csa_s1_io_out_sum[16])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[16] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[17] && csa_s1_io_out_sum[17])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[17] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[18] && csa_s1_io_out_sum[18])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[18] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[19] && csa_s1_io_out_sum[19])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[19] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[20] && csa_s1_io_out_sum[20])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[20] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[21] && csa_s1_io_out_sum[21])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[21] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[22] && csa_s1_io_out_sum[22])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[22] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[23] && csa_s1_io_out_sum[23])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[23] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[24] && csa_s1_io_out_sum[24])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[24] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[25] && csa_s1_io_out_sum[25])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[25] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[26] && csa_s1_io_out_sum[26])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[26] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[27] && csa_s1_io_out_sum[27])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[27] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[28] && csa_s1_io_out_sum[28])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[28] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[29] && csa_s1_io_out_sum[29])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[29] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[30] && csa_s1_io_out_sum[30])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[30] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[31] && csa_s1_io_out_sum[31])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[31] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[32] && csa_s1_io_out_sum[32])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[32] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[33] && csa_s1_io_out_sum[33])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[33] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[34] && csa_s1_io_out_sum[34])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[34] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[35] && csa_s1_io_out_sum[35])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[35] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[36] && csa_s1_io_out_sum[36])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[36] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[37] && csa_s1_io_out_sum[37])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[37] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[38] && csa_s1_io_out_sum[38])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[38] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[39] && csa_s1_io_out_sum[39])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[39] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[40] && csa_s1_io_out_sum[40])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[40] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[41] && csa_s1_io_out_sum[41])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[41] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[42] && csa_s1_io_out_sum[42])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[42] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[43] && csa_s1_io_out_sum[43])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[43] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[44] && csa_s1_io_out_sum[44])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[44] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[45] && csa_s1_io_out_sum[45])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[45] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[46] && csa_s1_io_out_sum[46])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[46] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[47] && csa_s1_io_out_sum[47])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[47] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[48] && csa_s1_io_out_sum[48])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[48] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[49] && csa_s1_io_out_sum[49])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[49] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[50] && csa_s1_io_out_sum[50])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[50] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[51] && csa_s1_io_out_sum[51])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[51] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[52] && csa_s1_io_out_sum[52])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[52] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[53] && csa_s1_io_out_sum[53])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[53] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[54] && csa_s1_io_out_sum[54])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[54] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[55] && csa_s1_io_out_sum[55])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[55] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[56] && csa_s1_io_out_sum[56])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[56] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[57] && csa_s1_io_out_sum[57])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[57] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[58] && csa_s1_io_out_sum[58])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[58] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[59] && csa_s1_io_out_sum[59])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[59] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[60] && csa_s1_io_out_sum[60])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[60] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[61] && csa_s1_io_out_sum[61])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[61] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[62] && csa_s1_io_out_sum[62])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[62] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[63] && csa_s1_io_out_sum[63])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[63] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[64] && csa_s1_io_out_sum[64])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[64] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[65] && csa_s1_io_out_sum[65])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[65] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[66] && csa_s1_io_out_sum[66])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[66] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[67] && csa_s1_io_out_sum[67])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[67] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[68] && csa_s1_io_out_sum[68])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[68] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[69] && csa_s1_io_out_sum[69])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[69] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[70] && csa_s1_io_out_sum[70])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[70] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[71] && csa_s1_io_out_sum[71])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[71] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[72] && csa_s1_io_out_sum[72])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[72] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[73] && csa_s1_io_out_sum[73])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[73] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[74] && csa_s1_io_out_sum[74])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[74] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[75] && csa_s1_io_out_sum[75])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[75] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[76] && csa_s1_io_out_sum[76])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[76] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[77] && csa_s1_io_out_sum[77])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[77] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[78] && csa_s1_io_out_sum[78])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[78] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[79] && csa_s1_io_out_sum[79])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[79] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[80] && csa_s1_io_out_sum[80])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[80] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[81] && csa_s1_io_out_sum[81])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[81] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[82] && csa_s1_io_out_sum[82])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[82] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[83] && csa_s1_io_out_sum[83])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[83] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[84] && csa_s1_io_out_sum[84])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[84] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[85] && csa_s1_io_out_sum[85])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[85] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[86] && csa_s1_io_out_sum[86])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[86] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[87] && csa_s1_io_out_sum[87])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[87] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[88] && csa_s1_io_out_sum[88])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[88] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[89] && csa_s1_io_out_sum[89])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[89] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[90] && csa_s1_io_out_sum[90])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[90] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[91] && csa_s1_io_out_sum[91])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[91] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[92] && csa_s1_io_out_sum[92])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[92] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[93] && csa_s1_io_out_sum[93])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[93] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[94] && csa_s1_io_out_sum[94])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[94] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[95] && csa_s1_io_out_sum[95])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[95] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[96] && csa_s1_io_out_sum[96])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[96] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[97] && csa_s1_io_out_sum[97])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[97] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[98] && csa_s1_io_out_sum[98])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[98] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[99] && csa_s1_io_out_sum[99])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[99] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[100] && csa_s1_io_out_sum[100])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[100] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[101] && csa_s1_io_out_sum[101])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[101] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[102] && csa_s1_io_out_sum[102])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[102] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[103] && csa_s1_io_out_sum[103])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[103] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[104] && csa_s1_io_out_sum[104])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[104] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[105] && csa_s1_io_out_sum[105])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[105] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_sum[106] && csa_s1_io_out_sum[106])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_sum[106] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[1] && csa_s1_io_out_car[1])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[1] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[2] && csa_s1_io_out_car[2])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[2] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[3] && csa_s1_io_out_car[3])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[3] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[4] && csa_s1_io_out_car[4])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[4] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[5] && csa_s1_io_out_car[5])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[5] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[6] && csa_s1_io_out_car[6])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[6] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[7] && csa_s1_io_out_car[7])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[7] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[8] && csa_s1_io_out_car[8])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[8] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[9] && csa_s1_io_out_car[9])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[9] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[10] && csa_s1_io_out_car[10])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[10] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[11] && csa_s1_io_out_car[11])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[11] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[12] && csa_s1_io_out_car[12])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[12] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[13] && csa_s1_io_out_car[13])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[13] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[14] && csa_s1_io_out_car[14])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[14] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[15] && csa_s1_io_out_car[15])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[15] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[16] && csa_s1_io_out_car[16])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[16] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[17] && csa_s1_io_out_car[17])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[17] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[18] && csa_s1_io_out_car[18])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[18] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[19] && csa_s1_io_out_car[19])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[19] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[20] && csa_s1_io_out_car[20])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[20] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[21] && csa_s1_io_out_car[21])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[21] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[22] && csa_s1_io_out_car[22])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[22] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[23] && csa_s1_io_out_car[23])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[23] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[24] && csa_s1_io_out_car[24])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[24] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[25] && csa_s1_io_out_car[25])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[25] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[26] && csa_s1_io_out_car[26])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[26] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[27] && csa_s1_io_out_car[27])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[27] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[28] && csa_s1_io_out_car[28])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[28] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[29] && csa_s1_io_out_car[29])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[29] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[30] && csa_s1_io_out_car[30])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[30] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[31] && csa_s1_io_out_car[31])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[31] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[32] && csa_s1_io_out_car[32])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[32] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[33] && csa_s1_io_out_car[33])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[33] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[34] && csa_s1_io_out_car[34])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[34] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[35] && csa_s1_io_out_car[35])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[35] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[36] && csa_s1_io_out_car[36])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[36] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[37] && csa_s1_io_out_car[37])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[37] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[38] && csa_s1_io_out_car[38])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[38] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[39] && csa_s1_io_out_car[39])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[39] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[40] && csa_s1_io_out_car[40])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[40] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[41] && csa_s1_io_out_car[41])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[41] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[42] && csa_s1_io_out_car[42])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[42] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[43] && csa_s1_io_out_car[43])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[43] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[44] && csa_s1_io_out_car[44])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[44] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[45] && csa_s1_io_out_car[45])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[45] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[46] && csa_s1_io_out_car[46])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[46] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[47] && csa_s1_io_out_car[47])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[47] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[48] && csa_s1_io_out_car[48])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[48] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[49] && csa_s1_io_out_car[49])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[49] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[50] && csa_s1_io_out_car[50])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[50] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[51] && csa_s1_io_out_car[51])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[51] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[52] && csa_s1_io_out_car[52])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[52] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[53] && csa_s1_io_out_car[53])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[53] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[54] && csa_s1_io_out_car[54])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[54] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[55] && csa_s1_io_out_car[55])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[55] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[56] && csa_s1_io_out_car[56])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[56] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[57] && csa_s1_io_out_car[57])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[57] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[58] && csa_s1_io_out_car[58])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[58] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[59] && csa_s1_io_out_car[59])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[59] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[60] && csa_s1_io_out_car[60])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[60] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[61] && csa_s1_io_out_car[61])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[61] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[62] && csa_s1_io_out_car[62])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[62] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[63] && csa_s1_io_out_car[63])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[63] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[64] && csa_s1_io_out_car[64])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[64] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[65] && csa_s1_io_out_car[65])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[65] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[66] && csa_s1_io_out_car[66])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[66] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[67] && csa_s1_io_out_car[67])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[67] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[68] && csa_s1_io_out_car[68])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[68] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[69] && csa_s1_io_out_car[69])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[69] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[70] && csa_s1_io_out_car[70])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[70] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[71] && csa_s1_io_out_car[71])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[71] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[72] && csa_s1_io_out_car[72])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[72] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[73] && csa_s1_io_out_car[73])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[73] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[74] && csa_s1_io_out_car[74])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[74] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[75] && csa_s1_io_out_car[75])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[75] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[76] && csa_s1_io_out_car[76])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[76] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[77] && csa_s1_io_out_car[77])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[77] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[78] && csa_s1_io_out_car[78])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[78] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[79] && csa_s1_io_out_car[79])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[79] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[80] && csa_s1_io_out_car[80])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[80] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[81] && csa_s1_io_out_car[81])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[81] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[82] && csa_s1_io_out_car[82])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[82] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[83] && csa_s1_io_out_car[83])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[83] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[84] && csa_s1_io_out_car[84])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[84] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[85] && csa_s1_io_out_car[85])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[85] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[86] && csa_s1_io_out_car[86])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[86] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[87] && csa_s1_io_out_car[87])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[87] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[88] && csa_s1_io_out_car[88])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[88] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[89] && csa_s1_io_out_car[89])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[89] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[90] && csa_s1_io_out_car[90])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[90] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[91] && csa_s1_io_out_car[91])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[91] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[92] && csa_s1_io_out_car[92])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[92] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[93] && csa_s1_io_out_car[93])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[93] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[94] && csa_s1_io_out_car[94])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[94] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[95] && csa_s1_io_out_car[95])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[95] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[96] && csa_s1_io_out_car[96])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[96] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[97] && csa_s1_io_out_car[97])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[97] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[98] && csa_s1_io_out_car[98])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[98] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[99] && csa_s1_io_out_car[99])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[99] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[100] && csa_s1_io_out_car[100])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[100] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[101] && csa_s1_io_out_car[101])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[101] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[102] && csa_s1_io_out_car[102])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[102] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[103] && csa_s1_io_out_car[103])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[103] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[104] && csa_s1_io_out_car[104])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[104] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[105] && csa_s1_io_out_car[105])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[105] 未见过 0 和 1"); end
    if (!(csa_s0_io_out_car[106] && csa_s1_io_out_car[106])) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.io_out_car[106] 未见过 0 和 1"); end
    $display("[ARM] CSA_Nto2With3to2MainPipeline armed_at=%0d", csa_armed_at);
    if (csa_armed_at < 0) begin cov_fail++; $display("[ARM] CSA_Nto2With3to2MainPipeline 从未 arm"); end
    $display("[COV] CSA_Nto2With3to2MainPipeline.fire_hi = %0d", csa_cov_fire_hi);
    if (csa_cov_fire_hi < 1000) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.fire_hi < 1000"); end
    $display("[COV] CSA_Nto2With3to2MainPipeline.fire_lo = %0d", csa_cov_fire_lo);
    if (csa_cov_fire_lo < 1000) begin cov_fail++; $display("[COV] CSA_Nto2With3to2MainPipeline.fire_lo < 1000"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
