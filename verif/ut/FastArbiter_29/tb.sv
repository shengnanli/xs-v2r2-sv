// 自动生成：scripts/gen_fastarbiter.py —— 勿手改
// FastArbiter_29 双例化逐拍比对: golden FastArbiter_29 vs 可读 FastArbiter_29_xs。
// 激励: 全随机 (随机 valids + 随机 io_out_ready 自然遍历 round-robin 轮转相位)。
`timescale 1ns/1ps
`define CHECK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 30) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
    end \
  end \
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  bit reset;
  int errors = 0;
  int checks = 0;
  always #5 clock = ~clock;

  logic io_in_0_valid;
  logic io_in_1_valid;
  logic io_in_2_valid;
  logic io_in_3_valid;
  logic io_in_4_valid;
  logic io_in_5_valid;
  logic io_in_6_valid;
  logic io_in_7_valid;
  logic io_in_8_valid;
  logic io_in_9_valid;
  logic io_in_10_valid;
  logic io_in_11_valid;
  logic io_in_12_valid;
  logic io_in_13_valid;
  logic io_in_14_valid;
  logic io_in_15_valid;
  logic io_in_16_valid;
  logic io_in_17_valid;
  logic io_in_18_valid;
  logic io_in_19_valid;
  logic io_in_20_valid;
  logic io_in_21_valid;
  logic io_in_22_valid;
  logic io_in_23_valid;
  logic io_in_24_valid;
  logic io_in_25_valid;
  logic io_in_26_valid;
  logic io_in_27_valid;
  logic io_in_28_valid;
  logic io_in_29_valid;
  logic io_in_30_valid;
  logic io_in_31_valid;
  logic io_in_32_valid;
  logic io_in_33_valid;
  logic io_in_34_valid;
  logic io_in_35_valid;
  logic io_in_36_valid;
  logic io_in_37_valid;
  logic io_in_38_valid;
  logic io_in_39_valid;
  logic io_in_40_valid;
  logic io_in_41_valid;
  logic io_in_42_valid;
  logic io_in_43_valid;
  logic io_in_44_valid;
  logic io_in_45_valid;
  logic io_in_46_valid;
  logic io_in_47_valid;
  logic io_in_48_valid;
  logic io_in_49_valid;
  logic io_in_50_valid;
  logic io_in_51_valid;
  logic io_in_52_valid;
  logic io_in_53_valid;
  logic io_in_54_valid;
  logic io_in_55_valid;
  logic io_in_56_valid;
  logic io_in_57_valid;
  logic io_in_58_valid;
  logic io_in_59_valid;
  logic io_in_60_valid;
  logic io_in_61_valid;
  logic io_in_62_valid;
  logic io_in_63_valid;
  logic io_in_64_valid;
  logic io_in_65_valid;
  logic io_in_66_valid;
  logic io_in_67_valid;
  logic io_in_68_valid;
  logic io_in_69_valid;
  logic io_in_70_valid;
  logic io_in_71_valid;
  wire g_io_in_0_ready;
  wire i_io_in_0_ready;
  wire g_io_in_1_ready;
  wire i_io_in_1_ready;
  wire g_io_in_2_ready;
  wire i_io_in_2_ready;
  wire g_io_in_3_ready;
  wire i_io_in_3_ready;
  wire g_io_in_4_ready;
  wire i_io_in_4_ready;
  wire g_io_in_5_ready;
  wire i_io_in_5_ready;
  wire g_io_in_6_ready;
  wire i_io_in_6_ready;
  wire g_io_in_7_ready;
  wire i_io_in_7_ready;
  wire g_io_in_8_ready;
  wire i_io_in_8_ready;
  wire g_io_in_9_ready;
  wire i_io_in_9_ready;
  wire g_io_in_10_ready;
  wire i_io_in_10_ready;
  wire g_io_in_11_ready;
  wire i_io_in_11_ready;
  wire g_io_in_12_ready;
  wire i_io_in_12_ready;
  wire g_io_in_13_ready;
  wire i_io_in_13_ready;
  wire g_io_in_14_ready;
  wire i_io_in_14_ready;
  wire g_io_in_15_ready;
  wire i_io_in_15_ready;
  wire g_io_in_16_ready;
  wire i_io_in_16_ready;
  wire g_io_in_17_ready;
  wire i_io_in_17_ready;
  wire g_io_in_18_ready;
  wire i_io_in_18_ready;
  wire g_io_in_19_ready;
  wire i_io_in_19_ready;
  wire g_io_in_20_ready;
  wire i_io_in_20_ready;
  wire g_io_in_21_ready;
  wire i_io_in_21_ready;
  wire g_io_in_22_ready;
  wire i_io_in_22_ready;
  wire g_io_in_23_ready;
  wire i_io_in_23_ready;
  wire g_io_in_24_ready;
  wire i_io_in_24_ready;
  wire g_io_in_25_ready;
  wire i_io_in_25_ready;
  wire g_io_in_26_ready;
  wire i_io_in_26_ready;
  wire g_io_in_27_ready;
  wire i_io_in_27_ready;
  wire g_io_in_28_ready;
  wire i_io_in_28_ready;
  wire g_io_in_29_ready;
  wire i_io_in_29_ready;
  wire g_io_in_30_ready;
  wire i_io_in_30_ready;
  wire g_io_in_31_ready;
  wire i_io_in_31_ready;
  wire g_io_in_32_ready;
  wire i_io_in_32_ready;
  wire g_io_in_33_ready;
  wire i_io_in_33_ready;
  wire g_io_in_34_ready;
  wire i_io_in_34_ready;
  wire g_io_in_35_ready;
  wire i_io_in_35_ready;
  wire g_io_in_36_ready;
  wire i_io_in_36_ready;
  wire g_io_in_37_ready;
  wire i_io_in_37_ready;
  wire g_io_in_38_ready;
  wire i_io_in_38_ready;
  wire g_io_in_39_ready;
  wire i_io_in_39_ready;
  wire g_io_in_40_ready;
  wire i_io_in_40_ready;
  wire g_io_in_41_ready;
  wire i_io_in_41_ready;
  wire g_io_in_42_ready;
  wire i_io_in_42_ready;
  wire g_io_in_43_ready;
  wire i_io_in_43_ready;
  wire g_io_in_44_ready;
  wire i_io_in_44_ready;
  wire g_io_in_45_ready;
  wire i_io_in_45_ready;
  wire g_io_in_46_ready;
  wire i_io_in_46_ready;
  wire g_io_in_47_ready;
  wire i_io_in_47_ready;
  wire g_io_in_48_ready;
  wire i_io_in_48_ready;
  wire g_io_in_49_ready;
  wire i_io_in_49_ready;
  wire g_io_in_50_ready;
  wire i_io_in_50_ready;
  wire g_io_in_51_ready;
  wire i_io_in_51_ready;
  wire g_io_in_52_ready;
  wire i_io_in_52_ready;
  wire g_io_in_53_ready;
  wire i_io_in_53_ready;
  wire g_io_in_54_ready;
  wire i_io_in_54_ready;
  wire g_io_in_55_ready;
  wire i_io_in_55_ready;
  wire g_io_in_56_ready;
  wire i_io_in_56_ready;
  wire g_io_in_57_ready;
  wire i_io_in_57_ready;
  wire g_io_in_58_ready;
  wire i_io_in_58_ready;
  wire g_io_in_59_ready;
  wire i_io_in_59_ready;
  wire g_io_in_60_ready;
  wire i_io_in_60_ready;
  wire g_io_in_61_ready;
  wire i_io_in_61_ready;
  wire g_io_in_62_ready;
  wire i_io_in_62_ready;
  wire g_io_in_63_ready;
  wire i_io_in_63_ready;
  wire g_io_in_64_ready;
  wire i_io_in_64_ready;
  wire g_io_in_65_ready;
  wire i_io_in_65_ready;
  wire g_io_in_66_ready;
  wire i_io_in_66_ready;
  wire g_io_in_67_ready;
  wire i_io_in_67_ready;
  wire g_io_in_68_ready;
  wire i_io_in_68_ready;
  wire g_io_in_69_ready;
  wire i_io_in_69_ready;
  wire g_io_in_70_ready;
  wire i_io_in_70_ready;
  wire g_io_in_71_ready;
  wire i_io_in_71_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;

  FastArbiter_29 u_g (
    .clock(clock),
    .reset(reset),
    .io_in_0_ready(g_io_in_0_ready),
    .io_in_0_valid(io_in_0_valid),
    .io_in_1_ready(g_io_in_1_ready),
    .io_in_1_valid(io_in_1_valid),
    .io_in_2_ready(g_io_in_2_ready),
    .io_in_2_valid(io_in_2_valid),
    .io_in_3_ready(g_io_in_3_ready),
    .io_in_3_valid(io_in_3_valid),
    .io_in_4_ready(g_io_in_4_ready),
    .io_in_4_valid(io_in_4_valid),
    .io_in_5_ready(g_io_in_5_ready),
    .io_in_5_valid(io_in_5_valid),
    .io_in_6_ready(g_io_in_6_ready),
    .io_in_6_valid(io_in_6_valid),
    .io_in_7_ready(g_io_in_7_ready),
    .io_in_7_valid(io_in_7_valid),
    .io_in_8_ready(g_io_in_8_ready),
    .io_in_8_valid(io_in_8_valid),
    .io_in_9_ready(g_io_in_9_ready),
    .io_in_9_valid(io_in_9_valid),
    .io_in_10_ready(g_io_in_10_ready),
    .io_in_10_valid(io_in_10_valid),
    .io_in_11_ready(g_io_in_11_ready),
    .io_in_11_valid(io_in_11_valid),
    .io_in_12_ready(g_io_in_12_ready),
    .io_in_12_valid(io_in_12_valid),
    .io_in_13_ready(g_io_in_13_ready),
    .io_in_13_valid(io_in_13_valid),
    .io_in_14_ready(g_io_in_14_ready),
    .io_in_14_valid(io_in_14_valid),
    .io_in_15_ready(g_io_in_15_ready),
    .io_in_15_valid(io_in_15_valid),
    .io_in_16_ready(g_io_in_16_ready),
    .io_in_16_valid(io_in_16_valid),
    .io_in_17_ready(g_io_in_17_ready),
    .io_in_17_valid(io_in_17_valid),
    .io_in_18_ready(g_io_in_18_ready),
    .io_in_18_valid(io_in_18_valid),
    .io_in_19_ready(g_io_in_19_ready),
    .io_in_19_valid(io_in_19_valid),
    .io_in_20_ready(g_io_in_20_ready),
    .io_in_20_valid(io_in_20_valid),
    .io_in_21_ready(g_io_in_21_ready),
    .io_in_21_valid(io_in_21_valid),
    .io_in_22_ready(g_io_in_22_ready),
    .io_in_22_valid(io_in_22_valid),
    .io_in_23_ready(g_io_in_23_ready),
    .io_in_23_valid(io_in_23_valid),
    .io_in_24_ready(g_io_in_24_ready),
    .io_in_24_valid(io_in_24_valid),
    .io_in_25_ready(g_io_in_25_ready),
    .io_in_25_valid(io_in_25_valid),
    .io_in_26_ready(g_io_in_26_ready),
    .io_in_26_valid(io_in_26_valid),
    .io_in_27_ready(g_io_in_27_ready),
    .io_in_27_valid(io_in_27_valid),
    .io_in_28_ready(g_io_in_28_ready),
    .io_in_28_valid(io_in_28_valid),
    .io_in_29_ready(g_io_in_29_ready),
    .io_in_29_valid(io_in_29_valid),
    .io_in_30_ready(g_io_in_30_ready),
    .io_in_30_valid(io_in_30_valid),
    .io_in_31_ready(g_io_in_31_ready),
    .io_in_31_valid(io_in_31_valid),
    .io_in_32_ready(g_io_in_32_ready),
    .io_in_32_valid(io_in_32_valid),
    .io_in_33_ready(g_io_in_33_ready),
    .io_in_33_valid(io_in_33_valid),
    .io_in_34_ready(g_io_in_34_ready),
    .io_in_34_valid(io_in_34_valid),
    .io_in_35_ready(g_io_in_35_ready),
    .io_in_35_valid(io_in_35_valid),
    .io_in_36_ready(g_io_in_36_ready),
    .io_in_36_valid(io_in_36_valid),
    .io_in_37_ready(g_io_in_37_ready),
    .io_in_37_valid(io_in_37_valid),
    .io_in_38_ready(g_io_in_38_ready),
    .io_in_38_valid(io_in_38_valid),
    .io_in_39_ready(g_io_in_39_ready),
    .io_in_39_valid(io_in_39_valid),
    .io_in_40_ready(g_io_in_40_ready),
    .io_in_40_valid(io_in_40_valid),
    .io_in_41_ready(g_io_in_41_ready),
    .io_in_41_valid(io_in_41_valid),
    .io_in_42_ready(g_io_in_42_ready),
    .io_in_42_valid(io_in_42_valid),
    .io_in_43_ready(g_io_in_43_ready),
    .io_in_43_valid(io_in_43_valid),
    .io_in_44_ready(g_io_in_44_ready),
    .io_in_44_valid(io_in_44_valid),
    .io_in_45_ready(g_io_in_45_ready),
    .io_in_45_valid(io_in_45_valid),
    .io_in_46_ready(g_io_in_46_ready),
    .io_in_46_valid(io_in_46_valid),
    .io_in_47_ready(g_io_in_47_ready),
    .io_in_47_valid(io_in_47_valid),
    .io_in_48_ready(g_io_in_48_ready),
    .io_in_48_valid(io_in_48_valid),
    .io_in_49_ready(g_io_in_49_ready),
    .io_in_49_valid(io_in_49_valid),
    .io_in_50_ready(g_io_in_50_ready),
    .io_in_50_valid(io_in_50_valid),
    .io_in_51_ready(g_io_in_51_ready),
    .io_in_51_valid(io_in_51_valid),
    .io_in_52_ready(g_io_in_52_ready),
    .io_in_52_valid(io_in_52_valid),
    .io_in_53_ready(g_io_in_53_ready),
    .io_in_53_valid(io_in_53_valid),
    .io_in_54_ready(g_io_in_54_ready),
    .io_in_54_valid(io_in_54_valid),
    .io_in_55_ready(g_io_in_55_ready),
    .io_in_55_valid(io_in_55_valid),
    .io_in_56_ready(g_io_in_56_ready),
    .io_in_56_valid(io_in_56_valid),
    .io_in_57_ready(g_io_in_57_ready),
    .io_in_57_valid(io_in_57_valid),
    .io_in_58_ready(g_io_in_58_ready),
    .io_in_58_valid(io_in_58_valid),
    .io_in_59_ready(g_io_in_59_ready),
    .io_in_59_valid(io_in_59_valid),
    .io_in_60_ready(g_io_in_60_ready),
    .io_in_60_valid(io_in_60_valid),
    .io_in_61_ready(g_io_in_61_ready),
    .io_in_61_valid(io_in_61_valid),
    .io_in_62_ready(g_io_in_62_ready),
    .io_in_62_valid(io_in_62_valid),
    .io_in_63_ready(g_io_in_63_ready),
    .io_in_63_valid(io_in_63_valid),
    .io_in_64_ready(g_io_in_64_ready),
    .io_in_64_valid(io_in_64_valid),
    .io_in_65_ready(g_io_in_65_ready),
    .io_in_65_valid(io_in_65_valid),
    .io_in_66_ready(g_io_in_66_ready),
    .io_in_66_valid(io_in_66_valid),
    .io_in_67_ready(g_io_in_67_ready),
    .io_in_67_valid(io_in_67_valid),
    .io_in_68_ready(g_io_in_68_ready),
    .io_in_68_valid(io_in_68_valid),
    .io_in_69_ready(g_io_in_69_ready),
    .io_in_69_valid(io_in_69_valid),
    .io_in_70_ready(g_io_in_70_ready),
    .io_in_70_valid(io_in_70_valid),
    .io_in_71_ready(g_io_in_71_ready),
    .io_in_71_valid(io_in_71_valid),
    .io_out_valid(g_io_out_valid)
  );

  FastArbiter_29_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_0_ready(i_io_in_0_ready),
    .io_in_0_valid(io_in_0_valid),
    .io_in_1_ready(i_io_in_1_ready),
    .io_in_1_valid(io_in_1_valid),
    .io_in_2_ready(i_io_in_2_ready),
    .io_in_2_valid(io_in_2_valid),
    .io_in_3_ready(i_io_in_3_ready),
    .io_in_3_valid(io_in_3_valid),
    .io_in_4_ready(i_io_in_4_ready),
    .io_in_4_valid(io_in_4_valid),
    .io_in_5_ready(i_io_in_5_ready),
    .io_in_5_valid(io_in_5_valid),
    .io_in_6_ready(i_io_in_6_ready),
    .io_in_6_valid(io_in_6_valid),
    .io_in_7_ready(i_io_in_7_ready),
    .io_in_7_valid(io_in_7_valid),
    .io_in_8_ready(i_io_in_8_ready),
    .io_in_8_valid(io_in_8_valid),
    .io_in_9_ready(i_io_in_9_ready),
    .io_in_9_valid(io_in_9_valid),
    .io_in_10_ready(i_io_in_10_ready),
    .io_in_10_valid(io_in_10_valid),
    .io_in_11_ready(i_io_in_11_ready),
    .io_in_11_valid(io_in_11_valid),
    .io_in_12_ready(i_io_in_12_ready),
    .io_in_12_valid(io_in_12_valid),
    .io_in_13_ready(i_io_in_13_ready),
    .io_in_13_valid(io_in_13_valid),
    .io_in_14_ready(i_io_in_14_ready),
    .io_in_14_valid(io_in_14_valid),
    .io_in_15_ready(i_io_in_15_ready),
    .io_in_15_valid(io_in_15_valid),
    .io_in_16_ready(i_io_in_16_ready),
    .io_in_16_valid(io_in_16_valid),
    .io_in_17_ready(i_io_in_17_ready),
    .io_in_17_valid(io_in_17_valid),
    .io_in_18_ready(i_io_in_18_ready),
    .io_in_18_valid(io_in_18_valid),
    .io_in_19_ready(i_io_in_19_ready),
    .io_in_19_valid(io_in_19_valid),
    .io_in_20_ready(i_io_in_20_ready),
    .io_in_20_valid(io_in_20_valid),
    .io_in_21_ready(i_io_in_21_ready),
    .io_in_21_valid(io_in_21_valid),
    .io_in_22_ready(i_io_in_22_ready),
    .io_in_22_valid(io_in_22_valid),
    .io_in_23_ready(i_io_in_23_ready),
    .io_in_23_valid(io_in_23_valid),
    .io_in_24_ready(i_io_in_24_ready),
    .io_in_24_valid(io_in_24_valid),
    .io_in_25_ready(i_io_in_25_ready),
    .io_in_25_valid(io_in_25_valid),
    .io_in_26_ready(i_io_in_26_ready),
    .io_in_26_valid(io_in_26_valid),
    .io_in_27_ready(i_io_in_27_ready),
    .io_in_27_valid(io_in_27_valid),
    .io_in_28_ready(i_io_in_28_ready),
    .io_in_28_valid(io_in_28_valid),
    .io_in_29_ready(i_io_in_29_ready),
    .io_in_29_valid(io_in_29_valid),
    .io_in_30_ready(i_io_in_30_ready),
    .io_in_30_valid(io_in_30_valid),
    .io_in_31_ready(i_io_in_31_ready),
    .io_in_31_valid(io_in_31_valid),
    .io_in_32_ready(i_io_in_32_ready),
    .io_in_32_valid(io_in_32_valid),
    .io_in_33_ready(i_io_in_33_ready),
    .io_in_33_valid(io_in_33_valid),
    .io_in_34_ready(i_io_in_34_ready),
    .io_in_34_valid(io_in_34_valid),
    .io_in_35_ready(i_io_in_35_ready),
    .io_in_35_valid(io_in_35_valid),
    .io_in_36_ready(i_io_in_36_ready),
    .io_in_36_valid(io_in_36_valid),
    .io_in_37_ready(i_io_in_37_ready),
    .io_in_37_valid(io_in_37_valid),
    .io_in_38_ready(i_io_in_38_ready),
    .io_in_38_valid(io_in_38_valid),
    .io_in_39_ready(i_io_in_39_ready),
    .io_in_39_valid(io_in_39_valid),
    .io_in_40_ready(i_io_in_40_ready),
    .io_in_40_valid(io_in_40_valid),
    .io_in_41_ready(i_io_in_41_ready),
    .io_in_41_valid(io_in_41_valid),
    .io_in_42_ready(i_io_in_42_ready),
    .io_in_42_valid(io_in_42_valid),
    .io_in_43_ready(i_io_in_43_ready),
    .io_in_43_valid(io_in_43_valid),
    .io_in_44_ready(i_io_in_44_ready),
    .io_in_44_valid(io_in_44_valid),
    .io_in_45_ready(i_io_in_45_ready),
    .io_in_45_valid(io_in_45_valid),
    .io_in_46_ready(i_io_in_46_ready),
    .io_in_46_valid(io_in_46_valid),
    .io_in_47_ready(i_io_in_47_ready),
    .io_in_47_valid(io_in_47_valid),
    .io_in_48_ready(i_io_in_48_ready),
    .io_in_48_valid(io_in_48_valid),
    .io_in_49_ready(i_io_in_49_ready),
    .io_in_49_valid(io_in_49_valid),
    .io_in_50_ready(i_io_in_50_ready),
    .io_in_50_valid(io_in_50_valid),
    .io_in_51_ready(i_io_in_51_ready),
    .io_in_51_valid(io_in_51_valid),
    .io_in_52_ready(i_io_in_52_ready),
    .io_in_52_valid(io_in_52_valid),
    .io_in_53_ready(i_io_in_53_ready),
    .io_in_53_valid(io_in_53_valid),
    .io_in_54_ready(i_io_in_54_ready),
    .io_in_54_valid(io_in_54_valid),
    .io_in_55_ready(i_io_in_55_ready),
    .io_in_55_valid(io_in_55_valid),
    .io_in_56_ready(i_io_in_56_ready),
    .io_in_56_valid(io_in_56_valid),
    .io_in_57_ready(i_io_in_57_ready),
    .io_in_57_valid(io_in_57_valid),
    .io_in_58_ready(i_io_in_58_ready),
    .io_in_58_valid(io_in_58_valid),
    .io_in_59_ready(i_io_in_59_ready),
    .io_in_59_valid(io_in_59_valid),
    .io_in_60_ready(i_io_in_60_ready),
    .io_in_60_valid(io_in_60_valid),
    .io_in_61_ready(i_io_in_61_ready),
    .io_in_61_valid(io_in_61_valid),
    .io_in_62_ready(i_io_in_62_ready),
    .io_in_62_valid(io_in_62_valid),
    .io_in_63_ready(i_io_in_63_ready),
    .io_in_63_valid(io_in_63_valid),
    .io_in_64_ready(i_io_in_64_ready),
    .io_in_64_valid(io_in_64_valid),
    .io_in_65_ready(i_io_in_65_ready),
    .io_in_65_valid(io_in_65_valid),
    .io_in_66_ready(i_io_in_66_ready),
    .io_in_66_valid(io_in_66_valid),
    .io_in_67_ready(i_io_in_67_ready),
    .io_in_67_valid(io_in_67_valid),
    .io_in_68_ready(i_io_in_68_ready),
    .io_in_68_valid(io_in_68_valid),
    .io_in_69_ready(i_io_in_69_ready),
    .io_in_69_valid(io_in_69_valid),
    .io_in_70_ready(i_io_in_70_ready),
    .io_in_70_valid(io_in_70_valid),
    .io_in_71_ready(i_io_in_71_ready),
    .io_in_71_valid(io_in_71_valid),
    .io_out_valid(i_io_out_valid)
  );

  task automatic drive_random_inputs();
    io_in_0_valid <= $urandom_range(0, 1);
    io_in_1_valid <= $urandom_range(0, 1);
    io_in_2_valid <= $urandom_range(0, 1);
    io_in_3_valid <= $urandom_range(0, 1);
    io_in_4_valid <= $urandom_range(0, 1);
    io_in_5_valid <= $urandom_range(0, 1);
    io_in_6_valid <= $urandom_range(0, 1);
    io_in_7_valid <= $urandom_range(0, 1);
    io_in_8_valid <= $urandom_range(0, 1);
    io_in_9_valid <= $urandom_range(0, 1);
    io_in_10_valid <= $urandom_range(0, 1);
    io_in_11_valid <= $urandom_range(0, 1);
    io_in_12_valid <= $urandom_range(0, 1);
    io_in_13_valid <= $urandom_range(0, 1);
    io_in_14_valid <= $urandom_range(0, 1);
    io_in_15_valid <= $urandom_range(0, 1);
    io_in_16_valid <= $urandom_range(0, 1);
    io_in_17_valid <= $urandom_range(0, 1);
    io_in_18_valid <= $urandom_range(0, 1);
    io_in_19_valid <= $urandom_range(0, 1);
    io_in_20_valid <= $urandom_range(0, 1);
    io_in_21_valid <= $urandom_range(0, 1);
    io_in_22_valid <= $urandom_range(0, 1);
    io_in_23_valid <= $urandom_range(0, 1);
    io_in_24_valid <= $urandom_range(0, 1);
    io_in_25_valid <= $urandom_range(0, 1);
    io_in_26_valid <= $urandom_range(0, 1);
    io_in_27_valid <= $urandom_range(0, 1);
    io_in_28_valid <= $urandom_range(0, 1);
    io_in_29_valid <= $urandom_range(0, 1);
    io_in_30_valid <= $urandom_range(0, 1);
    io_in_31_valid <= $urandom_range(0, 1);
    io_in_32_valid <= $urandom_range(0, 1);
    io_in_33_valid <= $urandom_range(0, 1);
    io_in_34_valid <= $urandom_range(0, 1);
    io_in_35_valid <= $urandom_range(0, 1);
    io_in_36_valid <= $urandom_range(0, 1);
    io_in_37_valid <= $urandom_range(0, 1);
    io_in_38_valid <= $urandom_range(0, 1);
    io_in_39_valid <= $urandom_range(0, 1);
    io_in_40_valid <= $urandom_range(0, 1);
    io_in_41_valid <= $urandom_range(0, 1);
    io_in_42_valid <= $urandom_range(0, 1);
    io_in_43_valid <= $urandom_range(0, 1);
    io_in_44_valid <= $urandom_range(0, 1);
    io_in_45_valid <= $urandom_range(0, 1);
    io_in_46_valid <= $urandom_range(0, 1);
    io_in_47_valid <= $urandom_range(0, 1);
    io_in_48_valid <= $urandom_range(0, 1);
    io_in_49_valid <= $urandom_range(0, 1);
    io_in_50_valid <= $urandom_range(0, 1);
    io_in_51_valid <= $urandom_range(0, 1);
    io_in_52_valid <= $urandom_range(0, 1);
    io_in_53_valid <= $urandom_range(0, 1);
    io_in_54_valid <= $urandom_range(0, 1);
    io_in_55_valid <= $urandom_range(0, 1);
    io_in_56_valid <= $urandom_range(0, 1);
    io_in_57_valid <= $urandom_range(0, 1);
    io_in_58_valid <= $urandom_range(0, 1);
    io_in_59_valid <= $urandom_range(0, 1);
    io_in_60_valid <= $urandom_range(0, 1);
    io_in_61_valid <= $urandom_range(0, 1);
    io_in_62_valid <= $urandom_range(0, 1);
    io_in_63_valid <= $urandom_range(0, 1);
    io_in_64_valid <= $urandom_range(0, 1);
    io_in_65_valid <= $urandom_range(0, 1);
    io_in_66_valid <= $urandom_range(0, 1);
    io_in_67_valid <= $urandom_range(0, 1);
    io_in_68_valid <= $urandom_range(0, 1);
    io_in_69_valid <= $urandom_range(0, 1);
    io_in_70_valid <= $urandom_range(0, 1);
    io_in_71_valid <= $urandom_range(0, 1);
  endtask

  task automatic check_outputs();
    `CHECK(io_in_0_ready)
    `CHECK(io_in_1_ready)
    `CHECK(io_in_2_ready)
    `CHECK(io_in_3_ready)
    `CHECK(io_in_4_ready)
    `CHECK(io_in_5_ready)
    `CHECK(io_in_6_ready)
    `CHECK(io_in_7_ready)
    `CHECK(io_in_8_ready)
    `CHECK(io_in_9_ready)
    `CHECK(io_in_10_ready)
    `CHECK(io_in_11_ready)
    `CHECK(io_in_12_ready)
    `CHECK(io_in_13_ready)
    `CHECK(io_in_14_ready)
    `CHECK(io_in_15_ready)
    `CHECK(io_in_16_ready)
    `CHECK(io_in_17_ready)
    `CHECK(io_in_18_ready)
    `CHECK(io_in_19_ready)
    `CHECK(io_in_20_ready)
    `CHECK(io_in_21_ready)
    `CHECK(io_in_22_ready)
    `CHECK(io_in_23_ready)
    `CHECK(io_in_24_ready)
    `CHECK(io_in_25_ready)
    `CHECK(io_in_26_ready)
    `CHECK(io_in_27_ready)
    `CHECK(io_in_28_ready)
    `CHECK(io_in_29_ready)
    `CHECK(io_in_30_ready)
    `CHECK(io_in_31_ready)
    `CHECK(io_in_32_ready)
    `CHECK(io_in_33_ready)
    `CHECK(io_in_34_ready)
    `CHECK(io_in_35_ready)
    `CHECK(io_in_36_ready)
    `CHECK(io_in_37_ready)
    `CHECK(io_in_38_ready)
    `CHECK(io_in_39_ready)
    `CHECK(io_in_40_ready)
    `CHECK(io_in_41_ready)
    `CHECK(io_in_42_ready)
    `CHECK(io_in_43_ready)
    `CHECK(io_in_44_ready)
    `CHECK(io_in_45_ready)
    `CHECK(io_in_46_ready)
    `CHECK(io_in_47_ready)
    `CHECK(io_in_48_ready)
    `CHECK(io_in_49_ready)
    `CHECK(io_in_50_ready)
    `CHECK(io_in_51_ready)
    `CHECK(io_in_52_ready)
    `CHECK(io_in_53_ready)
    `CHECK(io_in_54_ready)
    `CHECK(io_in_55_ready)
    `CHECK(io_in_56_ready)
    `CHECK(io_in_57_ready)
    `CHECK(io_in_58_ready)
    `CHECK(io_in_59_ready)
    `CHECK(io_in_60_ready)
    `CHECK(io_in_61_ready)
    `CHECK(io_in_62_ready)
    `CHECK(io_in_63_ready)
    `CHECK(io_in_64_ready)
    `CHECK(io_in_65_ready)
    `CHECK(io_in_66_ready)
    `CHECK(io_in_67_ready)
    `CHECK(io_in_68_ready)
    `CHECK(io_in_69_ready)
    `CHECK(io_in_70_ready)
    `CHECK(io_in_71_ready)
    `CHECK(io_out_valid)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_in_0_valid = '0;
    io_in_1_valid = '0;
    io_in_2_valid = '0;
    io_in_3_valid = '0;
    io_in_4_valid = '0;
    io_in_5_valid = '0;
    io_in_6_valid = '0;
    io_in_7_valid = '0;
    io_in_8_valid = '0;
    io_in_9_valid = '0;
    io_in_10_valid = '0;
    io_in_11_valid = '0;
    io_in_12_valid = '0;
    io_in_13_valid = '0;
    io_in_14_valid = '0;
    io_in_15_valid = '0;
    io_in_16_valid = '0;
    io_in_17_valid = '0;
    io_in_18_valid = '0;
    io_in_19_valid = '0;
    io_in_20_valid = '0;
    io_in_21_valid = '0;
    io_in_22_valid = '0;
    io_in_23_valid = '0;
    io_in_24_valid = '0;
    io_in_25_valid = '0;
    io_in_26_valid = '0;
    io_in_27_valid = '0;
    io_in_28_valid = '0;
    io_in_29_valid = '0;
    io_in_30_valid = '0;
    io_in_31_valid = '0;
    io_in_32_valid = '0;
    io_in_33_valid = '0;
    io_in_34_valid = '0;
    io_in_35_valid = '0;
    io_in_36_valid = '0;
    io_in_37_valid = '0;
    io_in_38_valid = '0;
    io_in_39_valid = '0;
    io_in_40_valid = '0;
    io_in_41_valid = '0;
    io_in_42_valid = '0;
    io_in_43_valid = '0;
    io_in_44_valid = '0;
    io_in_45_valid = '0;
    io_in_46_valid = '0;
    io_in_47_valid = '0;
    io_in_48_valid = '0;
    io_in_49_valid = '0;
    io_in_50_valid = '0;
    io_in_51_valid = '0;
    io_in_52_valid = '0;
    io_in_53_valid = '0;
    io_in_54_valid = '0;
    io_in_55_valid = '0;
    io_in_56_valid = '0;
    io_in_57_valid = '0;
    io_in_58_valid = '0;
    io_in_59_valid = '0;
    io_in_60_valid = '0;
    io_in_61_valid = '0;
    io_in_62_valid = '0;
    io_in_63_valid = '0;
    io_in_64_valid = '0;
    io_in_65_valid = '0;
    io_in_66_valid = '0;
    io_in_67_valid = '0;
    io_in_68_valid = '0;
    io_in_69_valid = '0;
    io_in_70_valid = '0;
    io_in_71_valid = '0;
    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("FastArbiter_29 checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
