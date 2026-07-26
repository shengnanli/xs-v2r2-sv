// =============================================================================
//  FastArbiter_29 —— 72 路纯 grant round-robin 仲裁器可读核 (xs_FastArbiter_29_core)
// -----------------------------------------------------------------------------
//  TL2CHICoupledL2 直接子: 72 路输入只有 valid/ready 握手, 无 payload。
//  ★本变体无 io_out_ready 端口 (sink 恒收), 与 4/5 路 FastArbiter 的关键差异★:
//    状态更新条件是 (|valids) 而非 (io_out_ready & |valids);
//    io_in_i_ready = chosenOH[i] (不再 & io_out_ready)。
//  算法 = utility.FastArbiter 带挂起记忆 round-robin (同 FastArbiter_1/2/28, NUM=72):
//    rrSelOH  = lowest_oh(rrGrantMask & pendingMask)
//    chosenOH = (rrSelOH 命中 valid) ? rrSelOH : lowest_oh(valids)
//    pendingMask <= valids & ~chosenOH; rrGrantMask <= gt_mask(chosenOH)  (|valids 时)
//  io_out_valid = |valids。golden 是 firtool 把 72 位 round-robin 展平成 5800 行位表达式,
//  本核用通用循环复刻, 与 golden FastArbiter_29 逐位等价。
// =============================================================================
module xs_FastArbiter_29_core (
  input  clock,
  input  reset,
  output io_in_0_ready,
  input  io_in_0_valid,
  output io_in_1_ready,
  input  io_in_1_valid,
  output io_in_2_ready,
  input  io_in_2_valid,
  output io_in_3_ready,
  input  io_in_3_valid,
  output io_in_4_ready,
  input  io_in_4_valid,
  output io_in_5_ready,
  input  io_in_5_valid,
  output io_in_6_ready,
  input  io_in_6_valid,
  output io_in_7_ready,
  input  io_in_7_valid,
  output io_in_8_ready,
  input  io_in_8_valid,
  output io_in_9_ready,
  input  io_in_9_valid,
  output io_in_10_ready,
  input  io_in_10_valid,
  output io_in_11_ready,
  input  io_in_11_valid,
  output io_in_12_ready,
  input  io_in_12_valid,
  output io_in_13_ready,
  input  io_in_13_valid,
  output io_in_14_ready,
  input  io_in_14_valid,
  output io_in_15_ready,
  input  io_in_15_valid,
  output io_in_16_ready,
  input  io_in_16_valid,
  output io_in_17_ready,
  input  io_in_17_valid,
  output io_in_18_ready,
  input  io_in_18_valid,
  output io_in_19_ready,
  input  io_in_19_valid,
  output io_in_20_ready,
  input  io_in_20_valid,
  output io_in_21_ready,
  input  io_in_21_valid,
  output io_in_22_ready,
  input  io_in_22_valid,
  output io_in_23_ready,
  input  io_in_23_valid,
  output io_in_24_ready,
  input  io_in_24_valid,
  output io_in_25_ready,
  input  io_in_25_valid,
  output io_in_26_ready,
  input  io_in_26_valid,
  output io_in_27_ready,
  input  io_in_27_valid,
  output io_in_28_ready,
  input  io_in_28_valid,
  output io_in_29_ready,
  input  io_in_29_valid,
  output io_in_30_ready,
  input  io_in_30_valid,
  output io_in_31_ready,
  input  io_in_31_valid,
  output io_in_32_ready,
  input  io_in_32_valid,
  output io_in_33_ready,
  input  io_in_33_valid,
  output io_in_34_ready,
  input  io_in_34_valid,
  output io_in_35_ready,
  input  io_in_35_valid,
  output io_in_36_ready,
  input  io_in_36_valid,
  output io_in_37_ready,
  input  io_in_37_valid,
  output io_in_38_ready,
  input  io_in_38_valid,
  output io_in_39_ready,
  input  io_in_39_valid,
  output io_in_40_ready,
  input  io_in_40_valid,
  output io_in_41_ready,
  input  io_in_41_valid,
  output io_in_42_ready,
  input  io_in_42_valid,
  output io_in_43_ready,
  input  io_in_43_valid,
  output io_in_44_ready,
  input  io_in_44_valid,
  output io_in_45_ready,
  input  io_in_45_valid,
  output io_in_46_ready,
  input  io_in_46_valid,
  output io_in_47_ready,
  input  io_in_47_valid,
  output io_in_48_ready,
  input  io_in_48_valid,
  output io_in_49_ready,
  input  io_in_49_valid,
  output io_in_50_ready,
  input  io_in_50_valid,
  output io_in_51_ready,
  input  io_in_51_valid,
  output io_in_52_ready,
  input  io_in_52_valid,
  output io_in_53_ready,
  input  io_in_53_valid,
  output io_in_54_ready,
  input  io_in_54_valid,
  output io_in_55_ready,
  input  io_in_55_valid,
  output io_in_56_ready,
  input  io_in_56_valid,
  output io_in_57_ready,
  input  io_in_57_valid,
  output io_in_58_ready,
  input  io_in_58_valid,
  output io_in_59_ready,
  input  io_in_59_valid,
  output io_in_60_ready,
  input  io_in_60_valid,
  output io_in_61_ready,
  input  io_in_61_valid,
  output io_in_62_ready,
  input  io_in_62_valid,
  output io_in_63_ready,
  input  io_in_63_valid,
  output io_in_64_ready,
  input  io_in_64_valid,
  output io_in_65_ready,
  input  io_in_65_valid,
  output io_in_66_ready,
  input  io_in_66_valid,
  output io_in_67_ready,
  input  io_in_67_valid,
  output io_in_68_ready,
  input  io_in_68_valid,
  output io_in_69_ready,
  input  io_in_69_valid,
  output io_in_70_ready,
  input  io_in_70_valid,
  output io_in_71_ready,
  input  io_in_71_valid,
  output io_out_valid
);

  localparam int unsigned NUM = 72;

  logic [NUM-1:0] valids;
  assign valids = {
    io_in_71_valid,
    io_in_70_valid,
    io_in_69_valid,
    io_in_68_valid,
    io_in_67_valid,
    io_in_66_valid,
    io_in_65_valid,
    io_in_64_valid,
    io_in_63_valid,
    io_in_62_valid,
    io_in_61_valid,
    io_in_60_valid,
    io_in_59_valid,
    io_in_58_valid,
    io_in_57_valid,
    io_in_56_valid,
    io_in_55_valid,
    io_in_54_valid,
    io_in_53_valid,
    io_in_52_valid,
    io_in_51_valid,
    io_in_50_valid,
    io_in_49_valid,
    io_in_48_valid,
    io_in_47_valid,
    io_in_46_valid,
    io_in_45_valid,
    io_in_44_valid,
    io_in_43_valid,
    io_in_42_valid,
    io_in_41_valid,
    io_in_40_valid,
    io_in_39_valid,
    io_in_38_valid,
    io_in_37_valid,
    io_in_36_valid,
    io_in_35_valid,
    io_in_34_valid,
    io_in_33_valid,
    io_in_32_valid,
    io_in_31_valid,
    io_in_30_valid,
    io_in_29_valid,
    io_in_28_valid,
    io_in_27_valid,
    io_in_26_valid,
    io_in_25_valid,
    io_in_24_valid,
    io_in_23_valid,
    io_in_22_valid,
    io_in_21_valid,
    io_in_20_valid,
    io_in_19_valid,
    io_in_18_valid,
    io_in_17_valid,
    io_in_16_valid,
    io_in_15_valid,
    io_in_14_valid,
    io_in_13_valid,
    io_in_12_valid,
    io_in_11_valid,
    io_in_10_valid,
    io_in_9_valid,
    io_in_8_valid,
    io_in_7_valid,
    io_in_6_valid,
    io_in_5_valid,
    io_in_4_valid,
    io_in_3_valid,
    io_in_2_valid,
    io_in_1_valid,
    io_in_0_valid
  };

  // ---- round-robin 状态 + 组合选胜 ----
  reg   [NUM-1:0] pendingMask;
  reg   [NUM-1:0] rrGrantMask;
  logic [NUM-1:0] chosenOH;

  logic [NUM-1:0] cand;
  logic [NUM-1:0] rrSelOH;
  assign cand    = rrGrantMask & pendingMask;
  assign rrSelOH = cand & (~cand + {{(NUM-1){1'b0}}, 1'b1});   // x & -x = 隔离最低置位
  logic [NUM-1:0] baseOH;
  assign baseOH   = valids & (~valids + {{(NUM-1){1'b0}}, 1'b1});
  assign chosenOH = (|(rrSelOH & valids)) ? rrSelOH : baseOH;

  // gt_mask(chosenOH): bit[i] = OR(chosenOH[i-1:0]); bit0 恒 0。
  logic [NUM-1:0] gtMask;
  always_comb begin
    gtMask = '0;
    for (int i = 0; i < NUM; i++)
      gtMask[i] = |(chosenOH & ((NUM'(1) << i) - NUM'(1)));
  end

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      pendingMask <= '0;
      rrGrantMask <= '0;
    end else if (|valids) begin
      pendingMask <= valids & ~chosenOH;
      rrGrantMask <= gtMask;
    end
  end

  // ---- 握手: io_in_i_ready = chosenOH[i] (无 io_out_ready 门控) ----
  assign io_in_0_ready = chosenOH[0];
  assign io_in_1_ready = chosenOH[1];
  assign io_in_2_ready = chosenOH[2];
  assign io_in_3_ready = chosenOH[3];
  assign io_in_4_ready = chosenOH[4];
  assign io_in_5_ready = chosenOH[5];
  assign io_in_6_ready = chosenOH[6];
  assign io_in_7_ready = chosenOH[7];
  assign io_in_8_ready = chosenOH[8];
  assign io_in_9_ready = chosenOH[9];
  assign io_in_10_ready = chosenOH[10];
  assign io_in_11_ready = chosenOH[11];
  assign io_in_12_ready = chosenOH[12];
  assign io_in_13_ready = chosenOH[13];
  assign io_in_14_ready = chosenOH[14];
  assign io_in_15_ready = chosenOH[15];
  assign io_in_16_ready = chosenOH[16];
  assign io_in_17_ready = chosenOH[17];
  assign io_in_18_ready = chosenOH[18];
  assign io_in_19_ready = chosenOH[19];
  assign io_in_20_ready = chosenOH[20];
  assign io_in_21_ready = chosenOH[21];
  assign io_in_22_ready = chosenOH[22];
  assign io_in_23_ready = chosenOH[23];
  assign io_in_24_ready = chosenOH[24];
  assign io_in_25_ready = chosenOH[25];
  assign io_in_26_ready = chosenOH[26];
  assign io_in_27_ready = chosenOH[27];
  assign io_in_28_ready = chosenOH[28];
  assign io_in_29_ready = chosenOH[29];
  assign io_in_30_ready = chosenOH[30];
  assign io_in_31_ready = chosenOH[31];
  assign io_in_32_ready = chosenOH[32];
  assign io_in_33_ready = chosenOH[33];
  assign io_in_34_ready = chosenOH[34];
  assign io_in_35_ready = chosenOH[35];
  assign io_in_36_ready = chosenOH[36];
  assign io_in_37_ready = chosenOH[37];
  assign io_in_38_ready = chosenOH[38];
  assign io_in_39_ready = chosenOH[39];
  assign io_in_40_ready = chosenOH[40];
  assign io_in_41_ready = chosenOH[41];
  assign io_in_42_ready = chosenOH[42];
  assign io_in_43_ready = chosenOH[43];
  assign io_in_44_ready = chosenOH[44];
  assign io_in_45_ready = chosenOH[45];
  assign io_in_46_ready = chosenOH[46];
  assign io_in_47_ready = chosenOH[47];
  assign io_in_48_ready = chosenOH[48];
  assign io_in_49_ready = chosenOH[49];
  assign io_in_50_ready = chosenOH[50];
  assign io_in_51_ready = chosenOH[51];
  assign io_in_52_ready = chosenOH[52];
  assign io_in_53_ready = chosenOH[53];
  assign io_in_54_ready = chosenOH[54];
  assign io_in_55_ready = chosenOH[55];
  assign io_in_56_ready = chosenOH[56];
  assign io_in_57_ready = chosenOH[57];
  assign io_in_58_ready = chosenOH[58];
  assign io_in_59_ready = chosenOH[59];
  assign io_in_60_ready = chosenOH[60];
  assign io_in_61_ready = chosenOH[61];
  assign io_in_62_ready = chosenOH[62];
  assign io_in_63_ready = chosenOH[63];
  assign io_in_64_ready = chosenOH[64];
  assign io_in_65_ready = chosenOH[65];
  assign io_in_66_ready = chosenOH[66];
  assign io_in_67_ready = chosenOH[67];
  assign io_in_68_ready = chosenOH[68];
  assign io_in_69_ready = chosenOH[69];
  assign io_in_70_ready = chosenOH[70];
  assign io_in_71_ready = chosenOH[71];

  assign io_out_valid = |valids;

endmodule
