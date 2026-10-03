// =============================================================================
// tb —— HPerfCounter_21 / HPerfMonitor_3 UT：golden 与重写件各双例化，同激励逐拍比全部输出。
//
// 激励（每拍换一组）：
//   144 个事件增量全随机；每个 mhpmevent 的 4 个下标段各按 1/4 概率取 {0, 1..143, 144..255, 任意 10 位}
//   （10 位下标的高 2 位 golden 不看，任意 10 位用来证明这一点）；三个算子段 1/2 one-hot、1/2 任意 5 位
//   （多热 / 全 0 走优先级与默认 OR）。HPerfMonitor_3 的 8 路各自独立随机。
// 比较：所有寄存器无复位，暖机 WARM=8 拍（最长通路 6 拍）后开始逐拍比。
// 覆盖（写进 PASS 判据）：下标三档各 >= 1000；算子四种结果（and/xor/add/or）各 >= 1000；
//   每个输出位都见过 0 和 1。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0;
  int cyc;
  localparam int WARM = 8;
  logic clock = 0;
  always #5 clock = ~clock;

  // ---- 以下声明/例化/比较由 golden 端口表机械展开（145 输入 / 1 输出）----
  logic [63:0] io_hpm_event;
  logic [5:0] io_events_sets_1_value;
  logic [5:0] io_events_sets_2_value;
  logic [5:0] io_events_sets_3_value;
  logic [5:0] io_events_sets_4_value;
  logic [5:0] io_events_sets_5_value;
  logic [5:0] io_events_sets_6_value;
  logic [5:0] io_events_sets_7_value;
  logic [5:0] io_events_sets_8_value;
  logic [5:0] io_events_sets_9_value;
  logic [5:0] io_events_sets_10_value;
  logic [5:0] io_events_sets_11_value;
  logic [5:0] io_events_sets_12_value;
  logic [5:0] io_events_sets_13_value;
  logic [5:0] io_events_sets_14_value;
  logic [5:0] io_events_sets_15_value;
  logic [5:0] io_events_sets_16_value;
  logic [5:0] io_events_sets_17_value;
  logic [5:0] io_events_sets_18_value;
  logic [5:0] io_events_sets_19_value;
  logic [5:0] io_events_sets_20_value;
  logic [5:0] io_events_sets_21_value;
  logic [5:0] io_events_sets_22_value;
  logic [5:0] io_events_sets_23_value;
  logic [5:0] io_events_sets_24_value;
  logic [5:0] io_events_sets_25_value;
  logic [5:0] io_events_sets_26_value;
  logic [5:0] io_events_sets_27_value;
  logic [5:0] io_events_sets_28_value;
  logic [5:0] io_events_sets_29_value;
  logic [5:0] io_events_sets_30_value;
  logic [5:0] io_events_sets_31_value;
  logic [5:0] io_events_sets_32_value;
  logic [5:0] io_events_sets_33_value;
  logic [5:0] io_events_sets_34_value;
  logic [5:0] io_events_sets_35_value;
  logic [5:0] io_events_sets_36_value;
  logic [5:0] io_events_sets_37_value;
  logic [5:0] io_events_sets_38_value;
  logic [5:0] io_events_sets_39_value;
  logic [5:0] io_events_sets_40_value;
  logic [5:0] io_events_sets_41_value;
  logic [5:0] io_events_sets_42_value;
  logic [5:0] io_events_sets_43_value;
  logic [5:0] io_events_sets_44_value;
  logic [5:0] io_events_sets_45_value;
  logic [5:0] io_events_sets_46_value;
  logic [5:0] io_events_sets_47_value;
  logic [5:0] io_events_sets_48_value;
  logic [5:0] io_events_sets_49_value;
  logic [5:0] io_events_sets_50_value;
  logic [5:0] io_events_sets_51_value;
  logic [5:0] io_events_sets_52_value;
  logic [5:0] io_events_sets_53_value;
  logic [5:0] io_events_sets_54_value;
  logic [5:0] io_events_sets_55_value;
  logic [5:0] io_events_sets_56_value;
  logic [5:0] io_events_sets_57_value;
  logic [5:0] io_events_sets_58_value;
  logic [5:0] io_events_sets_59_value;
  logic [5:0] io_events_sets_60_value;
  logic [5:0] io_events_sets_61_value;
  logic [5:0] io_events_sets_62_value;
  logic [5:0] io_events_sets_63_value;
  logic [5:0] io_events_sets_64_value;
  logic [5:0] io_events_sets_65_value;
  logic [5:0] io_events_sets_66_value;
  logic [5:0] io_events_sets_67_value;
  logic [5:0] io_events_sets_68_value;
  logic [5:0] io_events_sets_69_value;
  logic [5:0] io_events_sets_70_value;
  logic [5:0] io_events_sets_71_value;
  logic [5:0] io_events_sets_72_value;
  logic [5:0] io_events_sets_73_value;
  logic [5:0] io_events_sets_74_value;
  logic [5:0] io_events_sets_75_value;
  logic [5:0] io_events_sets_76_value;
  logic [5:0] io_events_sets_77_value;
  logic [5:0] io_events_sets_78_value;
  logic [5:0] io_events_sets_79_value;
  logic [5:0] io_events_sets_80_value;
  logic [5:0] io_events_sets_81_value;
  logic [5:0] io_events_sets_82_value;
  logic [5:0] io_events_sets_83_value;
  logic [5:0] io_events_sets_84_value;
  logic [5:0] io_events_sets_85_value;
  logic [5:0] io_events_sets_86_value;
  logic [5:0] io_events_sets_87_value;
  logic [5:0] io_events_sets_88_value;
  logic [5:0] io_events_sets_89_value;
  logic [5:0] io_events_sets_90_value;
  logic [5:0] io_events_sets_91_value;
  logic [5:0] io_events_sets_92_value;
  logic [5:0] io_events_sets_93_value;
  logic [5:0] io_events_sets_94_value;
  logic [5:0] io_events_sets_95_value;
  logic [5:0] io_events_sets_96_value;
  logic [5:0] io_events_sets_97_value;
  logic [5:0] io_events_sets_98_value;
  logic [5:0] io_events_sets_99_value;
  logic [5:0] io_events_sets_100_value;
  logic [5:0] io_events_sets_101_value;
  logic [5:0] io_events_sets_102_value;
  logic [5:0] io_events_sets_103_value;
  logic [5:0] io_events_sets_104_value;
  logic [5:0] io_events_sets_105_value;
  logic [5:0] io_events_sets_106_value;
  logic [5:0] io_events_sets_107_value;
  logic [5:0] io_events_sets_108_value;
  logic [5:0] io_events_sets_109_value;
  logic [5:0] io_events_sets_110_value;
  logic [5:0] io_events_sets_111_value;
  logic [5:0] io_events_sets_112_value;
  logic [5:0] io_events_sets_113_value;
  logic [5:0] io_events_sets_114_value;
  logic [5:0] io_events_sets_115_value;
  logic [5:0] io_events_sets_116_value;
  logic [5:0] io_events_sets_117_value;
  logic [5:0] io_events_sets_118_value;
  logic [5:0] io_events_sets_119_value;
  logic [5:0] io_events_sets_120_value;
  logic [5:0] io_events_sets_121_value;
  logic [5:0] io_events_sets_122_value;
  logic [5:0] io_events_sets_123_value;
  logic [5:0] io_events_sets_124_value;
  logic [5:0] io_events_sets_125_value;
  logic [5:0] io_events_sets_126_value;
  logic [5:0] io_events_sets_127_value;
  logic [5:0] io_events_sets_128_value;
  logic [5:0] io_events_sets_129_value;
  logic [5:0] io_events_sets_130_value;
  logic [5:0] io_events_sets_131_value;
  logic [5:0] io_events_sets_132_value;
  logic [5:0] io_events_sets_133_value;
  logic [5:0] io_events_sets_134_value;
  logic [5:0] io_events_sets_135_value;
  logic [5:0] io_events_sets_136_value;
  logic [5:0] io_events_sets_137_value;
  logic [5:0] io_events_sets_138_value;
  logic [5:0] io_events_sets_139_value;
  logic [5:0] io_events_sets_140_value;
  logic [5:0] io_events_sets_141_value;
  logic [5:0] io_events_sets_142_value;
  logic [5:0] io_events_sets_143_value;
  logic [5:0] g_cnt_perf_value, i_cnt_perf_value;
  HPerfCounter_21 u_g (
    .clock(clock),
    .io_hpm_event(io_hpm_event),
    .io_events_sets_1_value(io_events_sets_1_value),
    .io_events_sets_2_value(io_events_sets_2_value),
    .io_events_sets_3_value(io_events_sets_3_value),
    .io_events_sets_4_value(io_events_sets_4_value),
    .io_events_sets_5_value(io_events_sets_5_value),
    .io_events_sets_6_value(io_events_sets_6_value),
    .io_events_sets_7_value(io_events_sets_7_value),
    .io_events_sets_8_value(io_events_sets_8_value),
    .io_events_sets_9_value(io_events_sets_9_value),
    .io_events_sets_10_value(io_events_sets_10_value),
    .io_events_sets_11_value(io_events_sets_11_value),
    .io_events_sets_12_value(io_events_sets_12_value),
    .io_events_sets_13_value(io_events_sets_13_value),
    .io_events_sets_14_value(io_events_sets_14_value),
    .io_events_sets_15_value(io_events_sets_15_value),
    .io_events_sets_16_value(io_events_sets_16_value),
    .io_events_sets_17_value(io_events_sets_17_value),
    .io_events_sets_18_value(io_events_sets_18_value),
    .io_events_sets_19_value(io_events_sets_19_value),
    .io_events_sets_20_value(io_events_sets_20_value),
    .io_events_sets_21_value(io_events_sets_21_value),
    .io_events_sets_22_value(io_events_sets_22_value),
    .io_events_sets_23_value(io_events_sets_23_value),
    .io_events_sets_24_value(io_events_sets_24_value),
    .io_events_sets_25_value(io_events_sets_25_value),
    .io_events_sets_26_value(io_events_sets_26_value),
    .io_events_sets_27_value(io_events_sets_27_value),
    .io_events_sets_28_value(io_events_sets_28_value),
    .io_events_sets_29_value(io_events_sets_29_value),
    .io_events_sets_30_value(io_events_sets_30_value),
    .io_events_sets_31_value(io_events_sets_31_value),
    .io_events_sets_32_value(io_events_sets_32_value),
    .io_events_sets_33_value(io_events_sets_33_value),
    .io_events_sets_34_value(io_events_sets_34_value),
    .io_events_sets_35_value(io_events_sets_35_value),
    .io_events_sets_36_value(io_events_sets_36_value),
    .io_events_sets_37_value(io_events_sets_37_value),
    .io_events_sets_38_value(io_events_sets_38_value),
    .io_events_sets_39_value(io_events_sets_39_value),
    .io_events_sets_40_value(io_events_sets_40_value),
    .io_events_sets_41_value(io_events_sets_41_value),
    .io_events_sets_42_value(io_events_sets_42_value),
    .io_events_sets_43_value(io_events_sets_43_value),
    .io_events_sets_44_value(io_events_sets_44_value),
    .io_events_sets_45_value(io_events_sets_45_value),
    .io_events_sets_46_value(io_events_sets_46_value),
    .io_events_sets_47_value(io_events_sets_47_value),
    .io_events_sets_48_value(io_events_sets_48_value),
    .io_events_sets_49_value(io_events_sets_49_value),
    .io_events_sets_50_value(io_events_sets_50_value),
    .io_events_sets_51_value(io_events_sets_51_value),
    .io_events_sets_52_value(io_events_sets_52_value),
    .io_events_sets_53_value(io_events_sets_53_value),
    .io_events_sets_54_value(io_events_sets_54_value),
    .io_events_sets_55_value(io_events_sets_55_value),
    .io_events_sets_56_value(io_events_sets_56_value),
    .io_events_sets_57_value(io_events_sets_57_value),
    .io_events_sets_58_value(io_events_sets_58_value),
    .io_events_sets_59_value(io_events_sets_59_value),
    .io_events_sets_60_value(io_events_sets_60_value),
    .io_events_sets_61_value(io_events_sets_61_value),
    .io_events_sets_62_value(io_events_sets_62_value),
    .io_events_sets_63_value(io_events_sets_63_value),
    .io_events_sets_64_value(io_events_sets_64_value),
    .io_events_sets_65_value(io_events_sets_65_value),
    .io_events_sets_66_value(io_events_sets_66_value),
    .io_events_sets_67_value(io_events_sets_67_value),
    .io_events_sets_68_value(io_events_sets_68_value),
    .io_events_sets_69_value(io_events_sets_69_value),
    .io_events_sets_70_value(io_events_sets_70_value),
    .io_events_sets_71_value(io_events_sets_71_value),
    .io_events_sets_72_value(io_events_sets_72_value),
    .io_events_sets_73_value(io_events_sets_73_value),
    .io_events_sets_74_value(io_events_sets_74_value),
    .io_events_sets_75_value(io_events_sets_75_value),
    .io_events_sets_76_value(io_events_sets_76_value),
    .io_events_sets_77_value(io_events_sets_77_value),
    .io_events_sets_78_value(io_events_sets_78_value),
    .io_events_sets_79_value(io_events_sets_79_value),
    .io_events_sets_80_value(io_events_sets_80_value),
    .io_events_sets_81_value(io_events_sets_81_value),
    .io_events_sets_82_value(io_events_sets_82_value),
    .io_events_sets_83_value(io_events_sets_83_value),
    .io_events_sets_84_value(io_events_sets_84_value),
    .io_events_sets_85_value(io_events_sets_85_value),
    .io_events_sets_86_value(io_events_sets_86_value),
    .io_events_sets_87_value(io_events_sets_87_value),
    .io_events_sets_88_value(io_events_sets_88_value),
    .io_events_sets_89_value(io_events_sets_89_value),
    .io_events_sets_90_value(io_events_sets_90_value),
    .io_events_sets_91_value(io_events_sets_91_value),
    .io_events_sets_92_value(io_events_sets_92_value),
    .io_events_sets_93_value(io_events_sets_93_value),
    .io_events_sets_94_value(io_events_sets_94_value),
    .io_events_sets_95_value(io_events_sets_95_value),
    .io_events_sets_96_value(io_events_sets_96_value),
    .io_events_sets_97_value(io_events_sets_97_value),
    .io_events_sets_98_value(io_events_sets_98_value),
    .io_events_sets_99_value(io_events_sets_99_value),
    .io_events_sets_100_value(io_events_sets_100_value),
    .io_events_sets_101_value(io_events_sets_101_value),
    .io_events_sets_102_value(io_events_sets_102_value),
    .io_events_sets_103_value(io_events_sets_103_value),
    .io_events_sets_104_value(io_events_sets_104_value),
    .io_events_sets_105_value(io_events_sets_105_value),
    .io_events_sets_106_value(io_events_sets_106_value),
    .io_events_sets_107_value(io_events_sets_107_value),
    .io_events_sets_108_value(io_events_sets_108_value),
    .io_events_sets_109_value(io_events_sets_109_value),
    .io_events_sets_110_value(io_events_sets_110_value),
    .io_events_sets_111_value(io_events_sets_111_value),
    .io_events_sets_112_value(io_events_sets_112_value),
    .io_events_sets_113_value(io_events_sets_113_value),
    .io_events_sets_114_value(io_events_sets_114_value),
    .io_events_sets_115_value(io_events_sets_115_value),
    .io_events_sets_116_value(io_events_sets_116_value),
    .io_events_sets_117_value(io_events_sets_117_value),
    .io_events_sets_118_value(io_events_sets_118_value),
    .io_events_sets_119_value(io_events_sets_119_value),
    .io_events_sets_120_value(io_events_sets_120_value),
    .io_events_sets_121_value(io_events_sets_121_value),
    .io_events_sets_122_value(io_events_sets_122_value),
    .io_events_sets_123_value(io_events_sets_123_value),
    .io_events_sets_124_value(io_events_sets_124_value),
    .io_events_sets_125_value(io_events_sets_125_value),
    .io_events_sets_126_value(io_events_sets_126_value),
    .io_events_sets_127_value(io_events_sets_127_value),
    .io_events_sets_128_value(io_events_sets_128_value),
    .io_events_sets_129_value(io_events_sets_129_value),
    .io_events_sets_130_value(io_events_sets_130_value),
    .io_events_sets_131_value(io_events_sets_131_value),
    .io_events_sets_132_value(io_events_sets_132_value),
    .io_events_sets_133_value(io_events_sets_133_value),
    .io_events_sets_134_value(io_events_sets_134_value),
    .io_events_sets_135_value(io_events_sets_135_value),
    .io_events_sets_136_value(io_events_sets_136_value),
    .io_events_sets_137_value(io_events_sets_137_value),
    .io_events_sets_138_value(io_events_sets_138_value),
    .io_events_sets_139_value(io_events_sets_139_value),
    .io_events_sets_140_value(io_events_sets_140_value),
    .io_events_sets_141_value(io_events_sets_141_value),
    .io_events_sets_142_value(io_events_sets_142_value),
    .io_events_sets_143_value(io_events_sets_143_value),
    .io_perf_0_value(g_cnt_perf_value)
  );
  HPerfCounter_21_xs u_i (
    .clock(clock),
    .io_hpm_event(io_hpm_event),
    .io_events_sets_1_value(io_events_sets_1_value),
    .io_events_sets_2_value(io_events_sets_2_value),
    .io_events_sets_3_value(io_events_sets_3_value),
    .io_events_sets_4_value(io_events_sets_4_value),
    .io_events_sets_5_value(io_events_sets_5_value),
    .io_events_sets_6_value(io_events_sets_6_value),
    .io_events_sets_7_value(io_events_sets_7_value),
    .io_events_sets_8_value(io_events_sets_8_value),
    .io_events_sets_9_value(io_events_sets_9_value),
    .io_events_sets_10_value(io_events_sets_10_value),
    .io_events_sets_11_value(io_events_sets_11_value),
    .io_events_sets_12_value(io_events_sets_12_value),
    .io_events_sets_13_value(io_events_sets_13_value),
    .io_events_sets_14_value(io_events_sets_14_value),
    .io_events_sets_15_value(io_events_sets_15_value),
    .io_events_sets_16_value(io_events_sets_16_value),
    .io_events_sets_17_value(io_events_sets_17_value),
    .io_events_sets_18_value(io_events_sets_18_value),
    .io_events_sets_19_value(io_events_sets_19_value),
    .io_events_sets_20_value(io_events_sets_20_value),
    .io_events_sets_21_value(io_events_sets_21_value),
    .io_events_sets_22_value(io_events_sets_22_value),
    .io_events_sets_23_value(io_events_sets_23_value),
    .io_events_sets_24_value(io_events_sets_24_value),
    .io_events_sets_25_value(io_events_sets_25_value),
    .io_events_sets_26_value(io_events_sets_26_value),
    .io_events_sets_27_value(io_events_sets_27_value),
    .io_events_sets_28_value(io_events_sets_28_value),
    .io_events_sets_29_value(io_events_sets_29_value),
    .io_events_sets_30_value(io_events_sets_30_value),
    .io_events_sets_31_value(io_events_sets_31_value),
    .io_events_sets_32_value(io_events_sets_32_value),
    .io_events_sets_33_value(io_events_sets_33_value),
    .io_events_sets_34_value(io_events_sets_34_value),
    .io_events_sets_35_value(io_events_sets_35_value),
    .io_events_sets_36_value(io_events_sets_36_value),
    .io_events_sets_37_value(io_events_sets_37_value),
    .io_events_sets_38_value(io_events_sets_38_value),
    .io_events_sets_39_value(io_events_sets_39_value),
    .io_events_sets_40_value(io_events_sets_40_value),
    .io_events_sets_41_value(io_events_sets_41_value),
    .io_events_sets_42_value(io_events_sets_42_value),
    .io_events_sets_43_value(io_events_sets_43_value),
    .io_events_sets_44_value(io_events_sets_44_value),
    .io_events_sets_45_value(io_events_sets_45_value),
    .io_events_sets_46_value(io_events_sets_46_value),
    .io_events_sets_47_value(io_events_sets_47_value),
    .io_events_sets_48_value(io_events_sets_48_value),
    .io_events_sets_49_value(io_events_sets_49_value),
    .io_events_sets_50_value(io_events_sets_50_value),
    .io_events_sets_51_value(io_events_sets_51_value),
    .io_events_sets_52_value(io_events_sets_52_value),
    .io_events_sets_53_value(io_events_sets_53_value),
    .io_events_sets_54_value(io_events_sets_54_value),
    .io_events_sets_55_value(io_events_sets_55_value),
    .io_events_sets_56_value(io_events_sets_56_value),
    .io_events_sets_57_value(io_events_sets_57_value),
    .io_events_sets_58_value(io_events_sets_58_value),
    .io_events_sets_59_value(io_events_sets_59_value),
    .io_events_sets_60_value(io_events_sets_60_value),
    .io_events_sets_61_value(io_events_sets_61_value),
    .io_events_sets_62_value(io_events_sets_62_value),
    .io_events_sets_63_value(io_events_sets_63_value),
    .io_events_sets_64_value(io_events_sets_64_value),
    .io_events_sets_65_value(io_events_sets_65_value),
    .io_events_sets_66_value(io_events_sets_66_value),
    .io_events_sets_67_value(io_events_sets_67_value),
    .io_events_sets_68_value(io_events_sets_68_value),
    .io_events_sets_69_value(io_events_sets_69_value),
    .io_events_sets_70_value(io_events_sets_70_value),
    .io_events_sets_71_value(io_events_sets_71_value),
    .io_events_sets_72_value(io_events_sets_72_value),
    .io_events_sets_73_value(io_events_sets_73_value),
    .io_events_sets_74_value(io_events_sets_74_value),
    .io_events_sets_75_value(io_events_sets_75_value),
    .io_events_sets_76_value(io_events_sets_76_value),
    .io_events_sets_77_value(io_events_sets_77_value),
    .io_events_sets_78_value(io_events_sets_78_value),
    .io_events_sets_79_value(io_events_sets_79_value),
    .io_events_sets_80_value(io_events_sets_80_value),
    .io_events_sets_81_value(io_events_sets_81_value),
    .io_events_sets_82_value(io_events_sets_82_value),
    .io_events_sets_83_value(io_events_sets_83_value),
    .io_events_sets_84_value(io_events_sets_84_value),
    .io_events_sets_85_value(io_events_sets_85_value),
    .io_events_sets_86_value(io_events_sets_86_value),
    .io_events_sets_87_value(io_events_sets_87_value),
    .io_events_sets_88_value(io_events_sets_88_value),
    .io_events_sets_89_value(io_events_sets_89_value),
    .io_events_sets_90_value(io_events_sets_90_value),
    .io_events_sets_91_value(io_events_sets_91_value),
    .io_events_sets_92_value(io_events_sets_92_value),
    .io_events_sets_93_value(io_events_sets_93_value),
    .io_events_sets_94_value(io_events_sets_94_value),
    .io_events_sets_95_value(io_events_sets_95_value),
    .io_events_sets_96_value(io_events_sets_96_value),
    .io_events_sets_97_value(io_events_sets_97_value),
    .io_events_sets_98_value(io_events_sets_98_value),
    .io_events_sets_99_value(io_events_sets_99_value),
    .io_events_sets_100_value(io_events_sets_100_value),
    .io_events_sets_101_value(io_events_sets_101_value),
    .io_events_sets_102_value(io_events_sets_102_value),
    .io_events_sets_103_value(io_events_sets_103_value),
    .io_events_sets_104_value(io_events_sets_104_value),
    .io_events_sets_105_value(io_events_sets_105_value),
    .io_events_sets_106_value(io_events_sets_106_value),
    .io_events_sets_107_value(io_events_sets_107_value),
    .io_events_sets_108_value(io_events_sets_108_value),
    .io_events_sets_109_value(io_events_sets_109_value),
    .io_events_sets_110_value(io_events_sets_110_value),
    .io_events_sets_111_value(io_events_sets_111_value),
    .io_events_sets_112_value(io_events_sets_112_value),
    .io_events_sets_113_value(io_events_sets_113_value),
    .io_events_sets_114_value(io_events_sets_114_value),
    .io_events_sets_115_value(io_events_sets_115_value),
    .io_events_sets_116_value(io_events_sets_116_value),
    .io_events_sets_117_value(io_events_sets_117_value),
    .io_events_sets_118_value(io_events_sets_118_value),
    .io_events_sets_119_value(io_events_sets_119_value),
    .io_events_sets_120_value(io_events_sets_120_value),
    .io_events_sets_121_value(io_events_sets_121_value),
    .io_events_sets_122_value(io_events_sets_122_value),
    .io_events_sets_123_value(io_events_sets_123_value),
    .io_events_sets_124_value(io_events_sets_124_value),
    .io_events_sets_125_value(io_events_sets_125_value),
    .io_events_sets_126_value(io_events_sets_126_value),
    .io_events_sets_127_value(io_events_sets_127_value),
    .io_events_sets_128_value(io_events_sets_128_value),
    .io_events_sets_129_value(io_events_sets_129_value),
    .io_events_sets_130_value(io_events_sets_130_value),
    .io_events_sets_131_value(io_events_sets_131_value),
    .io_events_sets_132_value(io_events_sets_132_value),
    .io_events_sets_133_value(io_events_sets_133_value),
    .io_events_sets_134_value(io_events_sets_134_value),
    .io_events_sets_135_value(io_events_sets_135_value),
    .io_events_sets_136_value(io_events_sets_136_value),
    .io_events_sets_137_value(io_events_sets_137_value),
    .io_events_sets_138_value(io_events_sets_138_value),
    .io_events_sets_139_value(io_events_sets_139_value),
    .io_events_sets_140_value(io_events_sets_140_value),
    .io_events_sets_141_value(io_events_sets_141_value),
    .io_events_sets_142_value(io_events_sets_142_value),
    .io_events_sets_143_value(io_events_sets_143_value),
    .io_perf_0_value(i_cnt_perf_value)
  );
  localparam int N_OUT_C = 1;
  bit seen0 [256];  // 该输出出现过"某位为 0"
  bit seen1 [256];  // 该输出出现过"某位为 1"
  `define CMP(k, g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 30) $display("[%0d] MISMATCH %s golden=%h impl=%h", cyc, nm, (g), (i)); end \
      if (|(g)) seen1[k] = 1; if (!(&(g))) seen0[k] = 1; end
  task automatic compare_all_c();
    `CMP(0, g_cnt_perf_value, i_cnt_perf_value, "cnt_io_perf_0_value")
  endtask
  task automatic rand_inputs_c();
    io_hpm_event = 64'({$urandom, $urandom});
    io_events_sets_1_value = 6'($urandom);
    io_events_sets_2_value = 6'($urandom);
    io_events_sets_3_value = 6'($urandom);
    io_events_sets_4_value = 6'($urandom);
    io_events_sets_5_value = 6'($urandom);
    io_events_sets_6_value = 6'($urandom);
    io_events_sets_7_value = 6'($urandom);
    io_events_sets_8_value = 6'($urandom);
    io_events_sets_9_value = 6'($urandom);
    io_events_sets_10_value = 6'($urandom);
    io_events_sets_11_value = 6'($urandom);
    io_events_sets_12_value = 6'($urandom);
    io_events_sets_13_value = 6'($urandom);
    io_events_sets_14_value = 6'($urandom);
    io_events_sets_15_value = 6'($urandom);
    io_events_sets_16_value = 6'($urandom);
    io_events_sets_17_value = 6'($urandom);
    io_events_sets_18_value = 6'($urandom);
    io_events_sets_19_value = 6'($urandom);
    io_events_sets_20_value = 6'($urandom);
    io_events_sets_21_value = 6'($urandom);
    io_events_sets_22_value = 6'($urandom);
    io_events_sets_23_value = 6'($urandom);
    io_events_sets_24_value = 6'($urandom);
    io_events_sets_25_value = 6'($urandom);
    io_events_sets_26_value = 6'($urandom);
    io_events_sets_27_value = 6'($urandom);
    io_events_sets_28_value = 6'($urandom);
    io_events_sets_29_value = 6'($urandom);
    io_events_sets_30_value = 6'($urandom);
    io_events_sets_31_value = 6'($urandom);
    io_events_sets_32_value = 6'($urandom);
    io_events_sets_33_value = 6'($urandom);
    io_events_sets_34_value = 6'($urandom);
    io_events_sets_35_value = 6'($urandom);
    io_events_sets_36_value = 6'($urandom);
    io_events_sets_37_value = 6'($urandom);
    io_events_sets_38_value = 6'($urandom);
    io_events_sets_39_value = 6'($urandom);
    io_events_sets_40_value = 6'($urandom);
    io_events_sets_41_value = 6'($urandom);
    io_events_sets_42_value = 6'($urandom);
    io_events_sets_43_value = 6'($urandom);
    io_events_sets_44_value = 6'($urandom);
    io_events_sets_45_value = 6'($urandom);
    io_events_sets_46_value = 6'($urandom);
    io_events_sets_47_value = 6'($urandom);
    io_events_sets_48_value = 6'($urandom);
    io_events_sets_49_value = 6'($urandom);
    io_events_sets_50_value = 6'($urandom);
    io_events_sets_51_value = 6'($urandom);
    io_events_sets_52_value = 6'($urandom);
    io_events_sets_53_value = 6'($urandom);
    io_events_sets_54_value = 6'($urandom);
    io_events_sets_55_value = 6'($urandom);
    io_events_sets_56_value = 6'($urandom);
    io_events_sets_57_value = 6'($urandom);
    io_events_sets_58_value = 6'($urandom);
    io_events_sets_59_value = 6'($urandom);
    io_events_sets_60_value = 6'($urandom);
    io_events_sets_61_value = 6'($urandom);
    io_events_sets_62_value = 6'($urandom);
    io_events_sets_63_value = 6'($urandom);
    io_events_sets_64_value = 6'($urandom);
    io_events_sets_65_value = 6'($urandom);
    io_events_sets_66_value = 6'($urandom);
    io_events_sets_67_value = 6'($urandom);
    io_events_sets_68_value = 6'($urandom);
    io_events_sets_69_value = 6'($urandom);
    io_events_sets_70_value = 6'($urandom);
    io_events_sets_71_value = 6'($urandom);
    io_events_sets_72_value = 6'($urandom);
    io_events_sets_73_value = 6'($urandom);
    io_events_sets_74_value = 6'($urandom);
    io_events_sets_75_value = 6'($urandom);
    io_events_sets_76_value = 6'($urandom);
    io_events_sets_77_value = 6'($urandom);
    io_events_sets_78_value = 6'($urandom);
    io_events_sets_79_value = 6'($urandom);
    io_events_sets_80_value = 6'($urandom);
    io_events_sets_81_value = 6'($urandom);
    io_events_sets_82_value = 6'($urandom);
    io_events_sets_83_value = 6'($urandom);
    io_events_sets_84_value = 6'($urandom);
    io_events_sets_85_value = 6'($urandom);
    io_events_sets_86_value = 6'($urandom);
    io_events_sets_87_value = 6'($urandom);
    io_events_sets_88_value = 6'($urandom);
    io_events_sets_89_value = 6'($urandom);
    io_events_sets_90_value = 6'($urandom);
    io_events_sets_91_value = 6'($urandom);
    io_events_sets_92_value = 6'($urandom);
    io_events_sets_93_value = 6'($urandom);
    io_events_sets_94_value = 6'($urandom);
    io_events_sets_95_value = 6'($urandom);
    io_events_sets_96_value = 6'($urandom);
    io_events_sets_97_value = 6'($urandom);
    io_events_sets_98_value = 6'($urandom);
    io_events_sets_99_value = 6'($urandom);
    io_events_sets_100_value = 6'($urandom);
    io_events_sets_101_value = 6'($urandom);
    io_events_sets_102_value = 6'($urandom);
    io_events_sets_103_value = 6'($urandom);
    io_events_sets_104_value = 6'($urandom);
    io_events_sets_105_value = 6'($urandom);
    io_events_sets_106_value = 6'($urandom);
    io_events_sets_107_value = 6'($urandom);
    io_events_sets_108_value = 6'($urandom);
    io_events_sets_109_value = 6'($urandom);
    io_events_sets_110_value = 6'($urandom);
    io_events_sets_111_value = 6'($urandom);
    io_events_sets_112_value = 6'($urandom);
    io_events_sets_113_value = 6'($urandom);
    io_events_sets_114_value = 6'($urandom);
    io_events_sets_115_value = 6'($urandom);
    io_events_sets_116_value = 6'($urandom);
    io_events_sets_117_value = 6'($urandom);
    io_events_sets_118_value = 6'($urandom);
    io_events_sets_119_value = 6'($urandom);
    io_events_sets_120_value = 6'($urandom);
    io_events_sets_121_value = 6'($urandom);
    io_events_sets_122_value = 6'($urandom);
    io_events_sets_123_value = 6'($urandom);
    io_events_sets_124_value = 6'($urandom);
    io_events_sets_125_value = 6'($urandom);
    io_events_sets_126_value = 6'($urandom);
    io_events_sets_127_value = 6'($urandom);
    io_events_sets_128_value = 6'($urandom);
    io_events_sets_129_value = 6'($urandom);
    io_events_sets_130_value = 6'($urandom);
    io_events_sets_131_value = 6'($urandom);
    io_events_sets_132_value = 6'($urandom);
    io_events_sets_133_value = 6'($urandom);
    io_events_sets_134_value = 6'($urandom);
    io_events_sets_135_value = 6'($urandom);
    io_events_sets_136_value = 6'($urandom);
    io_events_sets_137_value = 6'($urandom);
    io_events_sets_138_value = 6'($urandom);
    io_events_sets_139_value = 6'($urandom);
    io_events_sets_140_value = 6'($urandom);
    io_events_sets_141_value = 6'($urandom);
    io_events_sets_142_value = 6'($urandom);
    io_events_sets_143_value = 6'($urandom);
  endtask
  // ---- 以下声明/例化/比较由 golden 端口表机械展开（152 输入 / 8 输出）----
  logic [63:0] io_hpm_event_0;
  logic [63:0] io_hpm_event_1;
  logic [63:0] io_hpm_event_2;
  logic [63:0] io_hpm_event_3;
  logic [63:0] io_hpm_event_4;
  logic [63:0] io_hpm_event_5;
  logic [63:0] io_hpm_event_6;
  logic [63:0] io_hpm_event_7;
  logic [5:0] g_io_perf_0_value, i_io_perf_0_value;
  logic [5:0] g_io_perf_1_value, i_io_perf_1_value;
  logic [5:0] g_io_perf_2_value, i_io_perf_2_value;
  logic [5:0] g_io_perf_3_value, i_io_perf_3_value;
  logic [5:0] g_io_perf_4_value, i_io_perf_4_value;
  logic [5:0] g_io_perf_5_value, i_io_perf_5_value;
  logic [5:0] g_io_perf_6_value, i_io_perf_6_value;
  logic [5:0] g_io_perf_7_value, i_io_perf_7_value;
  HPerfMonitor_3 u_gm (
    .clock(clock),
    .io_hpm_event_0(io_hpm_event_0),
    .io_hpm_event_1(io_hpm_event_1),
    .io_hpm_event_2(io_hpm_event_2),
    .io_hpm_event_3(io_hpm_event_3),
    .io_hpm_event_4(io_hpm_event_4),
    .io_hpm_event_5(io_hpm_event_5),
    .io_hpm_event_6(io_hpm_event_6),
    .io_hpm_event_7(io_hpm_event_7),
    .io_events_sets_1_value(io_events_sets_1_value),
    .io_events_sets_2_value(io_events_sets_2_value),
    .io_events_sets_3_value(io_events_sets_3_value),
    .io_events_sets_4_value(io_events_sets_4_value),
    .io_events_sets_5_value(io_events_sets_5_value),
    .io_events_sets_6_value(io_events_sets_6_value),
    .io_events_sets_7_value(io_events_sets_7_value),
    .io_events_sets_8_value(io_events_sets_8_value),
    .io_events_sets_9_value(io_events_sets_9_value),
    .io_events_sets_10_value(io_events_sets_10_value),
    .io_events_sets_11_value(io_events_sets_11_value),
    .io_events_sets_12_value(io_events_sets_12_value),
    .io_events_sets_13_value(io_events_sets_13_value),
    .io_events_sets_14_value(io_events_sets_14_value),
    .io_events_sets_15_value(io_events_sets_15_value),
    .io_events_sets_16_value(io_events_sets_16_value),
    .io_events_sets_17_value(io_events_sets_17_value),
    .io_events_sets_18_value(io_events_sets_18_value),
    .io_events_sets_19_value(io_events_sets_19_value),
    .io_events_sets_20_value(io_events_sets_20_value),
    .io_events_sets_21_value(io_events_sets_21_value),
    .io_events_sets_22_value(io_events_sets_22_value),
    .io_events_sets_23_value(io_events_sets_23_value),
    .io_events_sets_24_value(io_events_sets_24_value),
    .io_events_sets_25_value(io_events_sets_25_value),
    .io_events_sets_26_value(io_events_sets_26_value),
    .io_events_sets_27_value(io_events_sets_27_value),
    .io_events_sets_28_value(io_events_sets_28_value),
    .io_events_sets_29_value(io_events_sets_29_value),
    .io_events_sets_30_value(io_events_sets_30_value),
    .io_events_sets_31_value(io_events_sets_31_value),
    .io_events_sets_32_value(io_events_sets_32_value),
    .io_events_sets_33_value(io_events_sets_33_value),
    .io_events_sets_34_value(io_events_sets_34_value),
    .io_events_sets_35_value(io_events_sets_35_value),
    .io_events_sets_36_value(io_events_sets_36_value),
    .io_events_sets_37_value(io_events_sets_37_value),
    .io_events_sets_38_value(io_events_sets_38_value),
    .io_events_sets_39_value(io_events_sets_39_value),
    .io_events_sets_40_value(io_events_sets_40_value),
    .io_events_sets_41_value(io_events_sets_41_value),
    .io_events_sets_42_value(io_events_sets_42_value),
    .io_events_sets_43_value(io_events_sets_43_value),
    .io_events_sets_44_value(io_events_sets_44_value),
    .io_events_sets_45_value(io_events_sets_45_value),
    .io_events_sets_46_value(io_events_sets_46_value),
    .io_events_sets_47_value(io_events_sets_47_value),
    .io_events_sets_48_value(io_events_sets_48_value),
    .io_events_sets_49_value(io_events_sets_49_value),
    .io_events_sets_50_value(io_events_sets_50_value),
    .io_events_sets_51_value(io_events_sets_51_value),
    .io_events_sets_52_value(io_events_sets_52_value),
    .io_events_sets_53_value(io_events_sets_53_value),
    .io_events_sets_54_value(io_events_sets_54_value),
    .io_events_sets_55_value(io_events_sets_55_value),
    .io_events_sets_56_value(io_events_sets_56_value),
    .io_events_sets_57_value(io_events_sets_57_value),
    .io_events_sets_58_value(io_events_sets_58_value),
    .io_events_sets_59_value(io_events_sets_59_value),
    .io_events_sets_60_value(io_events_sets_60_value),
    .io_events_sets_61_value(io_events_sets_61_value),
    .io_events_sets_62_value(io_events_sets_62_value),
    .io_events_sets_63_value(io_events_sets_63_value),
    .io_events_sets_64_value(io_events_sets_64_value),
    .io_events_sets_65_value(io_events_sets_65_value),
    .io_events_sets_66_value(io_events_sets_66_value),
    .io_events_sets_67_value(io_events_sets_67_value),
    .io_events_sets_68_value(io_events_sets_68_value),
    .io_events_sets_69_value(io_events_sets_69_value),
    .io_events_sets_70_value(io_events_sets_70_value),
    .io_events_sets_71_value(io_events_sets_71_value),
    .io_events_sets_72_value(io_events_sets_72_value),
    .io_events_sets_73_value(io_events_sets_73_value),
    .io_events_sets_74_value(io_events_sets_74_value),
    .io_events_sets_75_value(io_events_sets_75_value),
    .io_events_sets_76_value(io_events_sets_76_value),
    .io_events_sets_77_value(io_events_sets_77_value),
    .io_events_sets_78_value(io_events_sets_78_value),
    .io_events_sets_79_value(io_events_sets_79_value),
    .io_events_sets_80_value(io_events_sets_80_value),
    .io_events_sets_81_value(io_events_sets_81_value),
    .io_events_sets_82_value(io_events_sets_82_value),
    .io_events_sets_83_value(io_events_sets_83_value),
    .io_events_sets_84_value(io_events_sets_84_value),
    .io_events_sets_85_value(io_events_sets_85_value),
    .io_events_sets_86_value(io_events_sets_86_value),
    .io_events_sets_87_value(io_events_sets_87_value),
    .io_events_sets_88_value(io_events_sets_88_value),
    .io_events_sets_89_value(io_events_sets_89_value),
    .io_events_sets_90_value(io_events_sets_90_value),
    .io_events_sets_91_value(io_events_sets_91_value),
    .io_events_sets_92_value(io_events_sets_92_value),
    .io_events_sets_93_value(io_events_sets_93_value),
    .io_events_sets_94_value(io_events_sets_94_value),
    .io_events_sets_95_value(io_events_sets_95_value),
    .io_events_sets_96_value(io_events_sets_96_value),
    .io_events_sets_97_value(io_events_sets_97_value),
    .io_events_sets_98_value(io_events_sets_98_value),
    .io_events_sets_99_value(io_events_sets_99_value),
    .io_events_sets_100_value(io_events_sets_100_value),
    .io_events_sets_101_value(io_events_sets_101_value),
    .io_events_sets_102_value(io_events_sets_102_value),
    .io_events_sets_103_value(io_events_sets_103_value),
    .io_events_sets_104_value(io_events_sets_104_value),
    .io_events_sets_105_value(io_events_sets_105_value),
    .io_events_sets_106_value(io_events_sets_106_value),
    .io_events_sets_107_value(io_events_sets_107_value),
    .io_events_sets_108_value(io_events_sets_108_value),
    .io_events_sets_109_value(io_events_sets_109_value),
    .io_events_sets_110_value(io_events_sets_110_value),
    .io_events_sets_111_value(io_events_sets_111_value),
    .io_events_sets_112_value(io_events_sets_112_value),
    .io_events_sets_113_value(io_events_sets_113_value),
    .io_events_sets_114_value(io_events_sets_114_value),
    .io_events_sets_115_value(io_events_sets_115_value),
    .io_events_sets_116_value(io_events_sets_116_value),
    .io_events_sets_117_value(io_events_sets_117_value),
    .io_events_sets_118_value(io_events_sets_118_value),
    .io_events_sets_119_value(io_events_sets_119_value),
    .io_events_sets_120_value(io_events_sets_120_value),
    .io_events_sets_121_value(io_events_sets_121_value),
    .io_events_sets_122_value(io_events_sets_122_value),
    .io_events_sets_123_value(io_events_sets_123_value),
    .io_events_sets_124_value(io_events_sets_124_value),
    .io_events_sets_125_value(io_events_sets_125_value),
    .io_events_sets_126_value(io_events_sets_126_value),
    .io_events_sets_127_value(io_events_sets_127_value),
    .io_events_sets_128_value(io_events_sets_128_value),
    .io_events_sets_129_value(io_events_sets_129_value),
    .io_events_sets_130_value(io_events_sets_130_value),
    .io_events_sets_131_value(io_events_sets_131_value),
    .io_events_sets_132_value(io_events_sets_132_value),
    .io_events_sets_133_value(io_events_sets_133_value),
    .io_events_sets_134_value(io_events_sets_134_value),
    .io_events_sets_135_value(io_events_sets_135_value),
    .io_events_sets_136_value(io_events_sets_136_value),
    .io_events_sets_137_value(io_events_sets_137_value),
    .io_events_sets_138_value(io_events_sets_138_value),
    .io_events_sets_139_value(io_events_sets_139_value),
    .io_events_sets_140_value(io_events_sets_140_value),
    .io_events_sets_141_value(io_events_sets_141_value),
    .io_events_sets_142_value(io_events_sets_142_value),
    .io_events_sets_143_value(io_events_sets_143_value),
    .io_perf_0_value(g_io_perf_0_value),
    .io_perf_1_value(g_io_perf_1_value),
    .io_perf_2_value(g_io_perf_2_value),
    .io_perf_3_value(g_io_perf_3_value),
    .io_perf_4_value(g_io_perf_4_value),
    .io_perf_5_value(g_io_perf_5_value),
    .io_perf_6_value(g_io_perf_6_value),
    .io_perf_7_value(g_io_perf_7_value)
  );
  HPerfMonitor_3_xs u_im (
    .clock(clock),
    .io_hpm_event_0(io_hpm_event_0),
    .io_hpm_event_1(io_hpm_event_1),
    .io_hpm_event_2(io_hpm_event_2),
    .io_hpm_event_3(io_hpm_event_3),
    .io_hpm_event_4(io_hpm_event_4),
    .io_hpm_event_5(io_hpm_event_5),
    .io_hpm_event_6(io_hpm_event_6),
    .io_hpm_event_7(io_hpm_event_7),
    .io_events_sets_1_value(io_events_sets_1_value),
    .io_events_sets_2_value(io_events_sets_2_value),
    .io_events_sets_3_value(io_events_sets_3_value),
    .io_events_sets_4_value(io_events_sets_4_value),
    .io_events_sets_5_value(io_events_sets_5_value),
    .io_events_sets_6_value(io_events_sets_6_value),
    .io_events_sets_7_value(io_events_sets_7_value),
    .io_events_sets_8_value(io_events_sets_8_value),
    .io_events_sets_9_value(io_events_sets_9_value),
    .io_events_sets_10_value(io_events_sets_10_value),
    .io_events_sets_11_value(io_events_sets_11_value),
    .io_events_sets_12_value(io_events_sets_12_value),
    .io_events_sets_13_value(io_events_sets_13_value),
    .io_events_sets_14_value(io_events_sets_14_value),
    .io_events_sets_15_value(io_events_sets_15_value),
    .io_events_sets_16_value(io_events_sets_16_value),
    .io_events_sets_17_value(io_events_sets_17_value),
    .io_events_sets_18_value(io_events_sets_18_value),
    .io_events_sets_19_value(io_events_sets_19_value),
    .io_events_sets_20_value(io_events_sets_20_value),
    .io_events_sets_21_value(io_events_sets_21_value),
    .io_events_sets_22_value(io_events_sets_22_value),
    .io_events_sets_23_value(io_events_sets_23_value),
    .io_events_sets_24_value(io_events_sets_24_value),
    .io_events_sets_25_value(io_events_sets_25_value),
    .io_events_sets_26_value(io_events_sets_26_value),
    .io_events_sets_27_value(io_events_sets_27_value),
    .io_events_sets_28_value(io_events_sets_28_value),
    .io_events_sets_29_value(io_events_sets_29_value),
    .io_events_sets_30_value(io_events_sets_30_value),
    .io_events_sets_31_value(io_events_sets_31_value),
    .io_events_sets_32_value(io_events_sets_32_value),
    .io_events_sets_33_value(io_events_sets_33_value),
    .io_events_sets_34_value(io_events_sets_34_value),
    .io_events_sets_35_value(io_events_sets_35_value),
    .io_events_sets_36_value(io_events_sets_36_value),
    .io_events_sets_37_value(io_events_sets_37_value),
    .io_events_sets_38_value(io_events_sets_38_value),
    .io_events_sets_39_value(io_events_sets_39_value),
    .io_events_sets_40_value(io_events_sets_40_value),
    .io_events_sets_41_value(io_events_sets_41_value),
    .io_events_sets_42_value(io_events_sets_42_value),
    .io_events_sets_43_value(io_events_sets_43_value),
    .io_events_sets_44_value(io_events_sets_44_value),
    .io_events_sets_45_value(io_events_sets_45_value),
    .io_events_sets_46_value(io_events_sets_46_value),
    .io_events_sets_47_value(io_events_sets_47_value),
    .io_events_sets_48_value(io_events_sets_48_value),
    .io_events_sets_49_value(io_events_sets_49_value),
    .io_events_sets_50_value(io_events_sets_50_value),
    .io_events_sets_51_value(io_events_sets_51_value),
    .io_events_sets_52_value(io_events_sets_52_value),
    .io_events_sets_53_value(io_events_sets_53_value),
    .io_events_sets_54_value(io_events_sets_54_value),
    .io_events_sets_55_value(io_events_sets_55_value),
    .io_events_sets_56_value(io_events_sets_56_value),
    .io_events_sets_57_value(io_events_sets_57_value),
    .io_events_sets_58_value(io_events_sets_58_value),
    .io_events_sets_59_value(io_events_sets_59_value),
    .io_events_sets_60_value(io_events_sets_60_value),
    .io_events_sets_61_value(io_events_sets_61_value),
    .io_events_sets_62_value(io_events_sets_62_value),
    .io_events_sets_63_value(io_events_sets_63_value),
    .io_events_sets_64_value(io_events_sets_64_value),
    .io_events_sets_65_value(io_events_sets_65_value),
    .io_events_sets_66_value(io_events_sets_66_value),
    .io_events_sets_67_value(io_events_sets_67_value),
    .io_events_sets_68_value(io_events_sets_68_value),
    .io_events_sets_69_value(io_events_sets_69_value),
    .io_events_sets_70_value(io_events_sets_70_value),
    .io_events_sets_71_value(io_events_sets_71_value),
    .io_events_sets_72_value(io_events_sets_72_value),
    .io_events_sets_73_value(io_events_sets_73_value),
    .io_events_sets_74_value(io_events_sets_74_value),
    .io_events_sets_75_value(io_events_sets_75_value),
    .io_events_sets_76_value(io_events_sets_76_value),
    .io_events_sets_77_value(io_events_sets_77_value),
    .io_events_sets_78_value(io_events_sets_78_value),
    .io_events_sets_79_value(io_events_sets_79_value),
    .io_events_sets_80_value(io_events_sets_80_value),
    .io_events_sets_81_value(io_events_sets_81_value),
    .io_events_sets_82_value(io_events_sets_82_value),
    .io_events_sets_83_value(io_events_sets_83_value),
    .io_events_sets_84_value(io_events_sets_84_value),
    .io_events_sets_85_value(io_events_sets_85_value),
    .io_events_sets_86_value(io_events_sets_86_value),
    .io_events_sets_87_value(io_events_sets_87_value),
    .io_events_sets_88_value(io_events_sets_88_value),
    .io_events_sets_89_value(io_events_sets_89_value),
    .io_events_sets_90_value(io_events_sets_90_value),
    .io_events_sets_91_value(io_events_sets_91_value),
    .io_events_sets_92_value(io_events_sets_92_value),
    .io_events_sets_93_value(io_events_sets_93_value),
    .io_events_sets_94_value(io_events_sets_94_value),
    .io_events_sets_95_value(io_events_sets_95_value),
    .io_events_sets_96_value(io_events_sets_96_value),
    .io_events_sets_97_value(io_events_sets_97_value),
    .io_events_sets_98_value(io_events_sets_98_value),
    .io_events_sets_99_value(io_events_sets_99_value),
    .io_events_sets_100_value(io_events_sets_100_value),
    .io_events_sets_101_value(io_events_sets_101_value),
    .io_events_sets_102_value(io_events_sets_102_value),
    .io_events_sets_103_value(io_events_sets_103_value),
    .io_events_sets_104_value(io_events_sets_104_value),
    .io_events_sets_105_value(io_events_sets_105_value),
    .io_events_sets_106_value(io_events_sets_106_value),
    .io_events_sets_107_value(io_events_sets_107_value),
    .io_events_sets_108_value(io_events_sets_108_value),
    .io_events_sets_109_value(io_events_sets_109_value),
    .io_events_sets_110_value(io_events_sets_110_value),
    .io_events_sets_111_value(io_events_sets_111_value),
    .io_events_sets_112_value(io_events_sets_112_value),
    .io_events_sets_113_value(io_events_sets_113_value),
    .io_events_sets_114_value(io_events_sets_114_value),
    .io_events_sets_115_value(io_events_sets_115_value),
    .io_events_sets_116_value(io_events_sets_116_value),
    .io_events_sets_117_value(io_events_sets_117_value),
    .io_events_sets_118_value(io_events_sets_118_value),
    .io_events_sets_119_value(io_events_sets_119_value),
    .io_events_sets_120_value(io_events_sets_120_value),
    .io_events_sets_121_value(io_events_sets_121_value),
    .io_events_sets_122_value(io_events_sets_122_value),
    .io_events_sets_123_value(io_events_sets_123_value),
    .io_events_sets_124_value(io_events_sets_124_value),
    .io_events_sets_125_value(io_events_sets_125_value),
    .io_events_sets_126_value(io_events_sets_126_value),
    .io_events_sets_127_value(io_events_sets_127_value),
    .io_events_sets_128_value(io_events_sets_128_value),
    .io_events_sets_129_value(io_events_sets_129_value),
    .io_events_sets_130_value(io_events_sets_130_value),
    .io_events_sets_131_value(io_events_sets_131_value),
    .io_events_sets_132_value(io_events_sets_132_value),
    .io_events_sets_133_value(io_events_sets_133_value),
    .io_events_sets_134_value(io_events_sets_134_value),
    .io_events_sets_135_value(io_events_sets_135_value),
    .io_events_sets_136_value(io_events_sets_136_value),
    .io_events_sets_137_value(io_events_sets_137_value),
    .io_events_sets_138_value(io_events_sets_138_value),
    .io_events_sets_139_value(io_events_sets_139_value),
    .io_events_sets_140_value(io_events_sets_140_value),
    .io_events_sets_141_value(io_events_sets_141_value),
    .io_events_sets_142_value(io_events_sets_142_value),
    .io_events_sets_143_value(io_events_sets_143_value),
    .io_perf_0_value(i_io_perf_0_value),
    .io_perf_1_value(i_io_perf_1_value),
    .io_perf_2_value(i_io_perf_2_value),
    .io_perf_3_value(i_io_perf_3_value),
    .io_perf_4_value(i_io_perf_4_value),
    .io_perf_5_value(i_io_perf_5_value),
    .io_perf_6_value(i_io_perf_6_value),
    .io_perf_7_value(i_io_perf_7_value)
  );
  localparam int N_OUT_M = 8;
  task automatic compare_all_m();
    `CMP(100+0, g_io_perf_0_value, i_io_perf_0_value, "io_perf_0_value")
    `CMP(100+1, g_io_perf_1_value, i_io_perf_1_value, "io_perf_1_value")
    `CMP(100+2, g_io_perf_2_value, i_io_perf_2_value, "io_perf_2_value")
    `CMP(100+3, g_io_perf_3_value, i_io_perf_3_value, "io_perf_3_value")
    `CMP(100+4, g_io_perf_4_value, i_io_perf_4_value, "io_perf_4_value")
    `CMP(100+5, g_io_perf_5_value, i_io_perf_5_value, "io_perf_5_value")
    `CMP(100+6, g_io_perf_6_value, i_io_perf_6_value, "io_perf_6_value")
    `CMP(100+7, g_io_perf_7_value, i_io_perf_7_value, "io_perf_7_value")
  endtask
  task automatic rand_inputs_m();
    io_hpm_event_0 = 64'({$urandom, $urandom});
    io_hpm_event_1 = 64'({$urandom, $urandom});
    io_hpm_event_2 = 64'({$urandom, $urandom});
    io_hpm_event_3 = 64'({$urandom, $urandom});
    io_hpm_event_4 = 64'({$urandom, $urandom});
    io_hpm_event_5 = 64'({$urandom, $urandom});
    io_hpm_event_6 = 64'({$urandom, $urandom});
    io_hpm_event_7 = 64'({$urandom, $urandom});
    io_events_sets_1_value = 6'($urandom);
    io_events_sets_2_value = 6'($urandom);
    io_events_sets_3_value = 6'($urandom);
    io_events_sets_4_value = 6'($urandom);
    io_events_sets_5_value = 6'($urandom);
    io_events_sets_6_value = 6'($urandom);
    io_events_sets_7_value = 6'($urandom);
    io_events_sets_8_value = 6'($urandom);
    io_events_sets_9_value = 6'($urandom);
    io_events_sets_10_value = 6'($urandom);
    io_events_sets_11_value = 6'($urandom);
    io_events_sets_12_value = 6'($urandom);
    io_events_sets_13_value = 6'($urandom);
    io_events_sets_14_value = 6'($urandom);
    io_events_sets_15_value = 6'($urandom);
    io_events_sets_16_value = 6'($urandom);
    io_events_sets_17_value = 6'($urandom);
    io_events_sets_18_value = 6'($urandom);
    io_events_sets_19_value = 6'($urandom);
    io_events_sets_20_value = 6'($urandom);
    io_events_sets_21_value = 6'($urandom);
    io_events_sets_22_value = 6'($urandom);
    io_events_sets_23_value = 6'($urandom);
    io_events_sets_24_value = 6'($urandom);
    io_events_sets_25_value = 6'($urandom);
    io_events_sets_26_value = 6'($urandom);
    io_events_sets_27_value = 6'($urandom);
    io_events_sets_28_value = 6'($urandom);
    io_events_sets_29_value = 6'($urandom);
    io_events_sets_30_value = 6'($urandom);
    io_events_sets_31_value = 6'($urandom);
    io_events_sets_32_value = 6'($urandom);
    io_events_sets_33_value = 6'($urandom);
    io_events_sets_34_value = 6'($urandom);
    io_events_sets_35_value = 6'($urandom);
    io_events_sets_36_value = 6'($urandom);
    io_events_sets_37_value = 6'($urandom);
    io_events_sets_38_value = 6'($urandom);
    io_events_sets_39_value = 6'($urandom);
    io_events_sets_40_value = 6'($urandom);
    io_events_sets_41_value = 6'($urandom);
    io_events_sets_42_value = 6'($urandom);
    io_events_sets_43_value = 6'($urandom);
    io_events_sets_44_value = 6'($urandom);
    io_events_sets_45_value = 6'($urandom);
    io_events_sets_46_value = 6'($urandom);
    io_events_sets_47_value = 6'($urandom);
    io_events_sets_48_value = 6'($urandom);
    io_events_sets_49_value = 6'($urandom);
    io_events_sets_50_value = 6'($urandom);
    io_events_sets_51_value = 6'($urandom);
    io_events_sets_52_value = 6'($urandom);
    io_events_sets_53_value = 6'($urandom);
    io_events_sets_54_value = 6'($urandom);
    io_events_sets_55_value = 6'($urandom);
    io_events_sets_56_value = 6'($urandom);
    io_events_sets_57_value = 6'($urandom);
    io_events_sets_58_value = 6'($urandom);
    io_events_sets_59_value = 6'($urandom);
    io_events_sets_60_value = 6'($urandom);
    io_events_sets_61_value = 6'($urandom);
    io_events_sets_62_value = 6'($urandom);
    io_events_sets_63_value = 6'($urandom);
    io_events_sets_64_value = 6'($urandom);
    io_events_sets_65_value = 6'($urandom);
    io_events_sets_66_value = 6'($urandom);
    io_events_sets_67_value = 6'($urandom);
    io_events_sets_68_value = 6'($urandom);
    io_events_sets_69_value = 6'($urandom);
    io_events_sets_70_value = 6'($urandom);
    io_events_sets_71_value = 6'($urandom);
    io_events_sets_72_value = 6'($urandom);
    io_events_sets_73_value = 6'($urandom);
    io_events_sets_74_value = 6'($urandom);
    io_events_sets_75_value = 6'($urandom);
    io_events_sets_76_value = 6'($urandom);
    io_events_sets_77_value = 6'($urandom);
    io_events_sets_78_value = 6'($urandom);
    io_events_sets_79_value = 6'($urandom);
    io_events_sets_80_value = 6'($urandom);
    io_events_sets_81_value = 6'($urandom);
    io_events_sets_82_value = 6'($urandom);
    io_events_sets_83_value = 6'($urandom);
    io_events_sets_84_value = 6'($urandom);
    io_events_sets_85_value = 6'($urandom);
    io_events_sets_86_value = 6'($urandom);
    io_events_sets_87_value = 6'($urandom);
    io_events_sets_88_value = 6'($urandom);
    io_events_sets_89_value = 6'($urandom);
    io_events_sets_90_value = 6'($urandom);
    io_events_sets_91_value = 6'($urandom);
    io_events_sets_92_value = 6'($urandom);
    io_events_sets_93_value = 6'($urandom);
    io_events_sets_94_value = 6'($urandom);
    io_events_sets_95_value = 6'($urandom);
    io_events_sets_96_value = 6'($urandom);
    io_events_sets_97_value = 6'($urandom);
    io_events_sets_98_value = 6'($urandom);
    io_events_sets_99_value = 6'($urandom);
    io_events_sets_100_value = 6'($urandom);
    io_events_sets_101_value = 6'($urandom);
    io_events_sets_102_value = 6'($urandom);
    io_events_sets_103_value = 6'($urandom);
    io_events_sets_104_value = 6'($urandom);
    io_events_sets_105_value = 6'($urandom);
    io_events_sets_106_value = 6'($urandom);
    io_events_sets_107_value = 6'($urandom);
    io_events_sets_108_value = 6'($urandom);
    io_events_sets_109_value = 6'($urandom);
    io_events_sets_110_value = 6'($urandom);
    io_events_sets_111_value = 6'($urandom);
    io_events_sets_112_value = 6'($urandom);
    io_events_sets_113_value = 6'($urandom);
    io_events_sets_114_value = 6'($urandom);
    io_events_sets_115_value = 6'($urandom);
    io_events_sets_116_value = 6'($urandom);
    io_events_sets_117_value = 6'($urandom);
    io_events_sets_118_value = 6'($urandom);
    io_events_sets_119_value = 6'($urandom);
    io_events_sets_120_value = 6'($urandom);
    io_events_sets_121_value = 6'($urandom);
    io_events_sets_122_value = 6'($urandom);
    io_events_sets_123_value = 6'($urandom);
    io_events_sets_124_value = 6'($urandom);
    io_events_sets_125_value = 6'($urandom);
    io_events_sets_126_value = 6'($urandom);
    io_events_sets_127_value = 6'($urandom);
    io_events_sets_128_value = 6'($urandom);
    io_events_sets_129_value = 6'($urandom);
    io_events_sets_130_value = 6'($urandom);
    io_events_sets_131_value = 6'($urandom);
    io_events_sets_132_value = 6'($urandom);
    io_events_sets_133_value = 6'($urandom);
    io_events_sets_134_value = 6'($urandom);
    io_events_sets_135_value = 6'($urandom);
    io_events_sets_136_value = 6'($urandom);
    io_events_sets_137_value = 6'($urandom);
    io_events_sets_138_value = 6'($urandom);
    io_events_sets_139_value = 6'($urandom);
    io_events_sets_140_value = 6'($urandom);
    io_events_sets_141_value = 6'($urandom);
    io_events_sets_142_value = 6'($urandom);
    io_events_sets_143_value = 6'($urandom);
  endtask

  int cov_idx [3];      // 下标 0 / 1..143 / 144..255
  int cov_op  [4];      // and / xor / add / or（按 op 段的实际生效算子计，三段都计）

  function automatic logic [63:0] make_event();
    logic [63:0] e;
    logic [9:0] idx;
    logic [4:0] op;
    e = {$urandom, $urandom};
    for (int s = 0; s < 4; s++) begin
      case ($urandom_range(0, 3))
        0: idx = 10'd0;
        1: idx = 10'($urandom_range(1, 143));
        2: idx = 10'($urandom_range(144, 255));
        default: idx = 10'($urandom);
      endcase
      e[s*10 +: 10] = idx;
      if (idx[7:0] == 0) cov_idx[0]++; else if (idx[7:0] < 144) cov_idx[1]++; else cov_idx[2]++;
    end
    for (int s = 0; s < 3; s++) begin
      op = $urandom_range(0, 1) ? (5'b1 << $urandom_range(0, 3)) : 5'($urandom);
      e[40 + s*5 +: 5] = op;
      if (op[0]) cov_op[0]++; else if (op[1]) cov_op[1]++; else if (op[2]) cov_op[2]++; else cov_op[3]++;
    end
    return e;
  endfunction

  initial begin
    int bad;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    cov_idx = '{0, 0, 0}; cov_op = '{0, 0, 0, 0};
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      rand_inputs_c();
      rand_inputs_m();
      io_hpm_event = make_event();
      io_hpm_event_0 = make_event(); io_hpm_event_1 = make_event();
      io_hpm_event_2 = make_event(); io_hpm_event_3 = make_event();
      io_hpm_event_4 = make_event(); io_hpm_event_5 = make_event();
      io_hpm_event_6 = make_event(); io_hpm_event_7 = make_event();
      #1;
      if (cyc >= WARM) begin
        compare_all_c();
        compare_all_m();
      end
    end
    bad = 0;
    $display("cov idx zero/valid/oob : %0d / %0d / %0d", cov_idx[0], cov_idx[1], cov_idx[2]);
    $display("cov op and/xor/add/or : %0d / %0d / %0d / %0d", cov_op[0], cov_op[1], cov_op[2], cov_op[3]);
    foreach (cov_idx[a]) if (cov_idx[a] < NCYCLES / 200) bad++;
    foreach (cov_op[a])  if (cov_op[a]  < NCYCLES / 200) bad++;
    for (int o = 0; o < N_OUT_C; o++) if (!seen0[o] || !seen1[o]) begin bad++; $display("counter output %0d stuck", o); end
    for (int o = 100; o < 100 + N_OUT_M; o++) if (!seen0[o] || !seen1[o]) begin bad++; $display("monitor output %0d stuck", o - 100); end
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
