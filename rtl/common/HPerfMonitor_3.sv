// =============================================================================
// HPerfMonitor_3.sv —— 一组 8 个硬件性能计数器的事件选择器（utility.HPerfMonitor，8 CSR × 144 事件）
//
// 在哪一层：某个层级（本变体 numPCnt=144、numCSRPCnt=8）的性能事件汇聚点。8 个 mhpmevent
//   编码各驱动一个 HPerfCounter_21，144 个事件增量广播给全部 8 个计数器；每个计数器的输出
//   再经 generatePerfEvent 打两拍送出（所以从事件进来到 io_perf 共 6 拍）。
// 设计源：utility/src/main/scala/utility/HardwarePerfMonitor.scala class HPerfMonitor。
// 结构：纯例化 + 每路两级无复位打拍寄存器（golden regs 16 个 = 8 × 2）。
// 子模块：HPerfCounter_21（本仓重写件，实例名 perfEvents_hpc / _1.._7 与 golden 一致）。
// golden 对照：G1-canonical/golden-rtl/HPerfMonitor_3.sv
// =============================================================================
module xs_HPerfMonitor_core #(
  parameter int NUM_CNT  = 8,
  parameter int NUM_SETS = 144,
  parameter int W        = 6
) (
  input  logic          clock,
  input  logic [63:0]   hpm_event  [NUM_CNT],
  input  logic [W-1:0]  event_set  [NUM_SETS],
  output logic [W-1:0]  perf_value [NUM_CNT]
);
  logic [W-1:0] counter_value [NUM_CNT];
  logic [W-1:0] perf_q  [NUM_CNT];
  logic [W-1:0] perf_qq [NUM_CNT];

  for (genvar c = 0; c < NUM_CNT; c++) begin : g_cnt
    HPerfCounter_21 perfEvents_hpc (
      .clock           (clock),
      .io_hpm_event    (hpm_event[c]),
      .io_events_sets_1_value (event_set[1]),
      .io_events_sets_2_value (event_set[2]),
      .io_events_sets_3_value (event_set[3]),
      .io_events_sets_4_value (event_set[4]),
      .io_events_sets_5_value (event_set[5]),
      .io_events_sets_6_value (event_set[6]),
      .io_events_sets_7_value (event_set[7]),
      .io_events_sets_8_value (event_set[8]),
      .io_events_sets_9_value (event_set[9]),
      .io_events_sets_10_value (event_set[10]),
      .io_events_sets_11_value (event_set[11]),
      .io_events_sets_12_value (event_set[12]),
      .io_events_sets_13_value (event_set[13]),
      .io_events_sets_14_value (event_set[14]),
      .io_events_sets_15_value (event_set[15]),
      .io_events_sets_16_value (event_set[16]),
      .io_events_sets_17_value (event_set[17]),
      .io_events_sets_18_value (event_set[18]),
      .io_events_sets_19_value (event_set[19]),
      .io_events_sets_20_value (event_set[20]),
      .io_events_sets_21_value (event_set[21]),
      .io_events_sets_22_value (event_set[22]),
      .io_events_sets_23_value (event_set[23]),
      .io_events_sets_24_value (event_set[24]),
      .io_events_sets_25_value (event_set[25]),
      .io_events_sets_26_value (event_set[26]),
      .io_events_sets_27_value (event_set[27]),
      .io_events_sets_28_value (event_set[28]),
      .io_events_sets_29_value (event_set[29]),
      .io_events_sets_30_value (event_set[30]),
      .io_events_sets_31_value (event_set[31]),
      .io_events_sets_32_value (event_set[32]),
      .io_events_sets_33_value (event_set[33]),
      .io_events_sets_34_value (event_set[34]),
      .io_events_sets_35_value (event_set[35]),
      .io_events_sets_36_value (event_set[36]),
      .io_events_sets_37_value (event_set[37]),
      .io_events_sets_38_value (event_set[38]),
      .io_events_sets_39_value (event_set[39]),
      .io_events_sets_40_value (event_set[40]),
      .io_events_sets_41_value (event_set[41]),
      .io_events_sets_42_value (event_set[42]),
      .io_events_sets_43_value (event_set[43]),
      .io_events_sets_44_value (event_set[44]),
      .io_events_sets_45_value (event_set[45]),
      .io_events_sets_46_value (event_set[46]),
      .io_events_sets_47_value (event_set[47]),
      .io_events_sets_48_value (event_set[48]),
      .io_events_sets_49_value (event_set[49]),
      .io_events_sets_50_value (event_set[50]),
      .io_events_sets_51_value (event_set[51]),
      .io_events_sets_52_value (event_set[52]),
      .io_events_sets_53_value (event_set[53]),
      .io_events_sets_54_value (event_set[54]),
      .io_events_sets_55_value (event_set[55]),
      .io_events_sets_56_value (event_set[56]),
      .io_events_sets_57_value (event_set[57]),
      .io_events_sets_58_value (event_set[58]),
      .io_events_sets_59_value (event_set[59]),
      .io_events_sets_60_value (event_set[60]),
      .io_events_sets_61_value (event_set[61]),
      .io_events_sets_62_value (event_set[62]),
      .io_events_sets_63_value (event_set[63]),
      .io_events_sets_64_value (event_set[64]),
      .io_events_sets_65_value (event_set[65]),
      .io_events_sets_66_value (event_set[66]),
      .io_events_sets_67_value (event_set[67]),
      .io_events_sets_68_value (event_set[68]),
      .io_events_sets_69_value (event_set[69]),
      .io_events_sets_70_value (event_set[70]),
      .io_events_sets_71_value (event_set[71]),
      .io_events_sets_72_value (event_set[72]),
      .io_events_sets_73_value (event_set[73]),
      .io_events_sets_74_value (event_set[74]),
      .io_events_sets_75_value (event_set[75]),
      .io_events_sets_76_value (event_set[76]),
      .io_events_sets_77_value (event_set[77]),
      .io_events_sets_78_value (event_set[78]),
      .io_events_sets_79_value (event_set[79]),
      .io_events_sets_80_value (event_set[80]),
      .io_events_sets_81_value (event_set[81]),
      .io_events_sets_82_value (event_set[82]),
      .io_events_sets_83_value (event_set[83]),
      .io_events_sets_84_value (event_set[84]),
      .io_events_sets_85_value (event_set[85]),
      .io_events_sets_86_value (event_set[86]),
      .io_events_sets_87_value (event_set[87]),
      .io_events_sets_88_value (event_set[88]),
      .io_events_sets_89_value (event_set[89]),
      .io_events_sets_90_value (event_set[90]),
      .io_events_sets_91_value (event_set[91]),
      .io_events_sets_92_value (event_set[92]),
      .io_events_sets_93_value (event_set[93]),
      .io_events_sets_94_value (event_set[94]),
      .io_events_sets_95_value (event_set[95]),
      .io_events_sets_96_value (event_set[96]),
      .io_events_sets_97_value (event_set[97]),
      .io_events_sets_98_value (event_set[98]),
      .io_events_sets_99_value (event_set[99]),
      .io_events_sets_100_value (event_set[100]),
      .io_events_sets_101_value (event_set[101]),
      .io_events_sets_102_value (event_set[102]),
      .io_events_sets_103_value (event_set[103]),
      .io_events_sets_104_value (event_set[104]),
      .io_events_sets_105_value (event_set[105]),
      .io_events_sets_106_value (event_set[106]),
      .io_events_sets_107_value (event_set[107]),
      .io_events_sets_108_value (event_set[108]),
      .io_events_sets_109_value (event_set[109]),
      .io_events_sets_110_value (event_set[110]),
      .io_events_sets_111_value (event_set[111]),
      .io_events_sets_112_value (event_set[112]),
      .io_events_sets_113_value (event_set[113]),
      .io_events_sets_114_value (event_set[114]),
      .io_events_sets_115_value (event_set[115]),
      .io_events_sets_116_value (event_set[116]),
      .io_events_sets_117_value (event_set[117]),
      .io_events_sets_118_value (event_set[118]),
      .io_events_sets_119_value (event_set[119]),
      .io_events_sets_120_value (event_set[120]),
      .io_events_sets_121_value (event_set[121]),
      .io_events_sets_122_value (event_set[122]),
      .io_events_sets_123_value (event_set[123]),
      .io_events_sets_124_value (event_set[124]),
      .io_events_sets_125_value (event_set[125]),
      .io_events_sets_126_value (event_set[126]),
      .io_events_sets_127_value (event_set[127]),
      .io_events_sets_128_value (event_set[128]),
      .io_events_sets_129_value (event_set[129]),
      .io_events_sets_130_value (event_set[130]),
      .io_events_sets_131_value (event_set[131]),
      .io_events_sets_132_value (event_set[132]),
      .io_events_sets_133_value (event_set[133]),
      .io_events_sets_134_value (event_set[134]),
      .io_events_sets_135_value (event_set[135]),
      .io_events_sets_136_value (event_set[136]),
      .io_events_sets_137_value (event_set[137]),
      .io_events_sets_138_value (event_set[138]),
      .io_events_sets_139_value (event_set[139]),
      .io_events_sets_140_value (event_set[140]),
      .io_events_sets_141_value (event_set[141]),
      .io_events_sets_142_value (event_set[142]),
      .io_events_sets_143_value (event_set[143]),
      .io_perf_0_value (counter_value[c])
    );
    // generatePerfEvent：两拍输出打拍
    always_ff @(posedge clock) begin
      perf_q[c]  <= counter_value[c];
      perf_qq[c] <= perf_q[c];
    end
    assign perf_value[c] = perf_qq[c];
  end
endmodule

module HPerfMonitor_3 (
  input  logic         clock,
  input  logic [63:0]  io_hpm_event_0,
  input  logic [63:0]  io_hpm_event_1,
  input  logic [63:0]  io_hpm_event_2,
  input  logic [63:0]  io_hpm_event_3,
  input  logic [63:0]  io_hpm_event_4,
  input  logic [63:0]  io_hpm_event_5,
  input  logic [63:0]  io_hpm_event_6,
  input  logic [63:0]  io_hpm_event_7,
  input  logic [5:0]   io_events_sets_1_value,
  input  logic [5:0]   io_events_sets_2_value,
  input  logic [5:0]   io_events_sets_3_value,
  input  logic [5:0]   io_events_sets_4_value,
  input  logic [5:0]   io_events_sets_5_value,
  input  logic [5:0]   io_events_sets_6_value,
  input  logic [5:0]   io_events_sets_7_value,
  input  logic [5:0]   io_events_sets_8_value,
  input  logic [5:0]   io_events_sets_9_value,
  input  logic [5:0]   io_events_sets_10_value,
  input  logic [5:0]   io_events_sets_11_value,
  input  logic [5:0]   io_events_sets_12_value,
  input  logic [5:0]   io_events_sets_13_value,
  input  logic [5:0]   io_events_sets_14_value,
  input  logic [5:0]   io_events_sets_15_value,
  input  logic [5:0]   io_events_sets_16_value,
  input  logic [5:0]   io_events_sets_17_value,
  input  logic [5:0]   io_events_sets_18_value,
  input  logic [5:0]   io_events_sets_19_value,
  input  logic [5:0]   io_events_sets_20_value,
  input  logic [5:0]   io_events_sets_21_value,
  input  logic [5:0]   io_events_sets_22_value,
  input  logic [5:0]   io_events_sets_23_value,
  input  logic [5:0]   io_events_sets_24_value,
  input  logic [5:0]   io_events_sets_25_value,
  input  logic [5:0]   io_events_sets_26_value,
  input  logic [5:0]   io_events_sets_27_value,
  input  logic [5:0]   io_events_sets_28_value,
  input  logic [5:0]   io_events_sets_29_value,
  input  logic [5:0]   io_events_sets_30_value,
  input  logic [5:0]   io_events_sets_31_value,
  input  logic [5:0]   io_events_sets_32_value,
  input  logic [5:0]   io_events_sets_33_value,
  input  logic [5:0]   io_events_sets_34_value,
  input  logic [5:0]   io_events_sets_35_value,
  input  logic [5:0]   io_events_sets_36_value,
  input  logic [5:0]   io_events_sets_37_value,
  input  logic [5:0]   io_events_sets_38_value,
  input  logic [5:0]   io_events_sets_39_value,
  input  logic [5:0]   io_events_sets_40_value,
  input  logic [5:0]   io_events_sets_41_value,
  input  logic [5:0]   io_events_sets_42_value,
  input  logic [5:0]   io_events_sets_43_value,
  input  logic [5:0]   io_events_sets_44_value,
  input  logic [5:0]   io_events_sets_45_value,
  input  logic [5:0]   io_events_sets_46_value,
  input  logic [5:0]   io_events_sets_47_value,
  input  logic [5:0]   io_events_sets_48_value,
  input  logic [5:0]   io_events_sets_49_value,
  input  logic [5:0]   io_events_sets_50_value,
  input  logic [5:0]   io_events_sets_51_value,
  input  logic [5:0]   io_events_sets_52_value,
  input  logic [5:0]   io_events_sets_53_value,
  input  logic [5:0]   io_events_sets_54_value,
  input  logic [5:0]   io_events_sets_55_value,
  input  logic [5:0]   io_events_sets_56_value,
  input  logic [5:0]   io_events_sets_57_value,
  input  logic [5:0]   io_events_sets_58_value,
  input  logic [5:0]   io_events_sets_59_value,
  input  logic [5:0]   io_events_sets_60_value,
  input  logic [5:0]   io_events_sets_61_value,
  input  logic [5:0]   io_events_sets_62_value,
  input  logic [5:0]   io_events_sets_63_value,
  input  logic [5:0]   io_events_sets_64_value,
  input  logic [5:0]   io_events_sets_65_value,
  input  logic [5:0]   io_events_sets_66_value,
  input  logic [5:0]   io_events_sets_67_value,
  input  logic [5:0]   io_events_sets_68_value,
  input  logic [5:0]   io_events_sets_69_value,
  input  logic [5:0]   io_events_sets_70_value,
  input  logic [5:0]   io_events_sets_71_value,
  input  logic [5:0]   io_events_sets_72_value,
  input  logic [5:0]   io_events_sets_73_value,
  input  logic [5:0]   io_events_sets_74_value,
  input  logic [5:0]   io_events_sets_75_value,
  input  logic [5:0]   io_events_sets_76_value,
  input  logic [5:0]   io_events_sets_77_value,
  input  logic [5:0]   io_events_sets_78_value,
  input  logic [5:0]   io_events_sets_79_value,
  input  logic [5:0]   io_events_sets_80_value,
  input  logic [5:0]   io_events_sets_81_value,
  input  logic [5:0]   io_events_sets_82_value,
  input  logic [5:0]   io_events_sets_83_value,
  input  logic [5:0]   io_events_sets_84_value,
  input  logic [5:0]   io_events_sets_85_value,
  input  logic [5:0]   io_events_sets_86_value,
  input  logic [5:0]   io_events_sets_87_value,
  input  logic [5:0]   io_events_sets_88_value,
  input  logic [5:0]   io_events_sets_89_value,
  input  logic [5:0]   io_events_sets_90_value,
  input  logic [5:0]   io_events_sets_91_value,
  input  logic [5:0]   io_events_sets_92_value,
  input  logic [5:0]   io_events_sets_93_value,
  input  logic [5:0]   io_events_sets_94_value,
  input  logic [5:0]   io_events_sets_95_value,
  input  logic [5:0]   io_events_sets_96_value,
  input  logic [5:0]   io_events_sets_97_value,
  input  logic [5:0]   io_events_sets_98_value,
  input  logic [5:0]   io_events_sets_99_value,
  input  logic [5:0]   io_events_sets_100_value,
  input  logic [5:0]   io_events_sets_101_value,
  input  logic [5:0]   io_events_sets_102_value,
  input  logic [5:0]   io_events_sets_103_value,
  input  logic [5:0]   io_events_sets_104_value,
  input  logic [5:0]   io_events_sets_105_value,
  input  logic [5:0]   io_events_sets_106_value,
  input  logic [5:0]   io_events_sets_107_value,
  input  logic [5:0]   io_events_sets_108_value,
  input  logic [5:0]   io_events_sets_109_value,
  input  logic [5:0]   io_events_sets_110_value,
  input  logic [5:0]   io_events_sets_111_value,
  input  logic [5:0]   io_events_sets_112_value,
  input  logic [5:0]   io_events_sets_113_value,
  input  logic [5:0]   io_events_sets_114_value,
  input  logic [5:0]   io_events_sets_115_value,
  input  logic [5:0]   io_events_sets_116_value,
  input  logic [5:0]   io_events_sets_117_value,
  input  logic [5:0]   io_events_sets_118_value,
  input  logic [5:0]   io_events_sets_119_value,
  input  logic [5:0]   io_events_sets_120_value,
  input  logic [5:0]   io_events_sets_121_value,
  input  logic [5:0]   io_events_sets_122_value,
  input  logic [5:0]   io_events_sets_123_value,
  input  logic [5:0]   io_events_sets_124_value,
  input  logic [5:0]   io_events_sets_125_value,
  input  logic [5:0]   io_events_sets_126_value,
  input  logic [5:0]   io_events_sets_127_value,
  input  logic [5:0]   io_events_sets_128_value,
  input  logic [5:0]   io_events_sets_129_value,
  input  logic [5:0]   io_events_sets_130_value,
  input  logic [5:0]   io_events_sets_131_value,
  input  logic [5:0]   io_events_sets_132_value,
  input  logic [5:0]   io_events_sets_133_value,
  input  logic [5:0]   io_events_sets_134_value,
  input  logic [5:0]   io_events_sets_135_value,
  input  logic [5:0]   io_events_sets_136_value,
  input  logic [5:0]   io_events_sets_137_value,
  input  logic [5:0]   io_events_sets_138_value,
  input  logic [5:0]   io_events_sets_139_value,
  input  logic [5:0]   io_events_sets_140_value,
  input  logic [5:0]   io_events_sets_141_value,
  input  logic [5:0]   io_events_sets_142_value,
  input  logic [5:0]   io_events_sets_143_value,
  output logic [5:0]   io_perf_0_value,
  output logic [5:0]   io_perf_1_value,
  output logic [5:0]   io_perf_2_value,
  output logic [5:0]   io_perf_3_value,
  output logic [5:0]   io_perf_4_value,
  output logic [5:0]   io_perf_5_value,
  output logic [5:0]   io_perf_6_value,
  output logic [5:0]   io_perf_7_value
);
  logic [63:0] hpm_event  [8];
  logic [5:0]  event_set  [144];
  logic [5:0]  perf_value [8];
  assign event_set[0] = 6'h0;     // 事件 0 在上游恒 0，golden 没有这个端口
  assign hpm_event[0] = io_hpm_event_0;
  assign hpm_event[1] = io_hpm_event_1;
  assign hpm_event[2] = io_hpm_event_2;
  assign hpm_event[3] = io_hpm_event_3;
  assign hpm_event[4] = io_hpm_event_4;
  assign hpm_event[5] = io_hpm_event_5;
  assign hpm_event[6] = io_hpm_event_6;
  assign hpm_event[7] = io_hpm_event_7;
  assign event_set[1] = io_events_sets_1_value;
  assign event_set[2] = io_events_sets_2_value;
  assign event_set[3] = io_events_sets_3_value;
  assign event_set[4] = io_events_sets_4_value;
  assign event_set[5] = io_events_sets_5_value;
  assign event_set[6] = io_events_sets_6_value;
  assign event_set[7] = io_events_sets_7_value;
  assign event_set[8] = io_events_sets_8_value;
  assign event_set[9] = io_events_sets_9_value;
  assign event_set[10] = io_events_sets_10_value;
  assign event_set[11] = io_events_sets_11_value;
  assign event_set[12] = io_events_sets_12_value;
  assign event_set[13] = io_events_sets_13_value;
  assign event_set[14] = io_events_sets_14_value;
  assign event_set[15] = io_events_sets_15_value;
  assign event_set[16] = io_events_sets_16_value;
  assign event_set[17] = io_events_sets_17_value;
  assign event_set[18] = io_events_sets_18_value;
  assign event_set[19] = io_events_sets_19_value;
  assign event_set[20] = io_events_sets_20_value;
  assign event_set[21] = io_events_sets_21_value;
  assign event_set[22] = io_events_sets_22_value;
  assign event_set[23] = io_events_sets_23_value;
  assign event_set[24] = io_events_sets_24_value;
  assign event_set[25] = io_events_sets_25_value;
  assign event_set[26] = io_events_sets_26_value;
  assign event_set[27] = io_events_sets_27_value;
  assign event_set[28] = io_events_sets_28_value;
  assign event_set[29] = io_events_sets_29_value;
  assign event_set[30] = io_events_sets_30_value;
  assign event_set[31] = io_events_sets_31_value;
  assign event_set[32] = io_events_sets_32_value;
  assign event_set[33] = io_events_sets_33_value;
  assign event_set[34] = io_events_sets_34_value;
  assign event_set[35] = io_events_sets_35_value;
  assign event_set[36] = io_events_sets_36_value;
  assign event_set[37] = io_events_sets_37_value;
  assign event_set[38] = io_events_sets_38_value;
  assign event_set[39] = io_events_sets_39_value;
  assign event_set[40] = io_events_sets_40_value;
  assign event_set[41] = io_events_sets_41_value;
  assign event_set[42] = io_events_sets_42_value;
  assign event_set[43] = io_events_sets_43_value;
  assign event_set[44] = io_events_sets_44_value;
  assign event_set[45] = io_events_sets_45_value;
  assign event_set[46] = io_events_sets_46_value;
  assign event_set[47] = io_events_sets_47_value;
  assign event_set[48] = io_events_sets_48_value;
  assign event_set[49] = io_events_sets_49_value;
  assign event_set[50] = io_events_sets_50_value;
  assign event_set[51] = io_events_sets_51_value;
  assign event_set[52] = io_events_sets_52_value;
  assign event_set[53] = io_events_sets_53_value;
  assign event_set[54] = io_events_sets_54_value;
  assign event_set[55] = io_events_sets_55_value;
  assign event_set[56] = io_events_sets_56_value;
  assign event_set[57] = io_events_sets_57_value;
  assign event_set[58] = io_events_sets_58_value;
  assign event_set[59] = io_events_sets_59_value;
  assign event_set[60] = io_events_sets_60_value;
  assign event_set[61] = io_events_sets_61_value;
  assign event_set[62] = io_events_sets_62_value;
  assign event_set[63] = io_events_sets_63_value;
  assign event_set[64] = io_events_sets_64_value;
  assign event_set[65] = io_events_sets_65_value;
  assign event_set[66] = io_events_sets_66_value;
  assign event_set[67] = io_events_sets_67_value;
  assign event_set[68] = io_events_sets_68_value;
  assign event_set[69] = io_events_sets_69_value;
  assign event_set[70] = io_events_sets_70_value;
  assign event_set[71] = io_events_sets_71_value;
  assign event_set[72] = io_events_sets_72_value;
  assign event_set[73] = io_events_sets_73_value;
  assign event_set[74] = io_events_sets_74_value;
  assign event_set[75] = io_events_sets_75_value;
  assign event_set[76] = io_events_sets_76_value;
  assign event_set[77] = io_events_sets_77_value;
  assign event_set[78] = io_events_sets_78_value;
  assign event_set[79] = io_events_sets_79_value;
  assign event_set[80] = io_events_sets_80_value;
  assign event_set[81] = io_events_sets_81_value;
  assign event_set[82] = io_events_sets_82_value;
  assign event_set[83] = io_events_sets_83_value;
  assign event_set[84] = io_events_sets_84_value;
  assign event_set[85] = io_events_sets_85_value;
  assign event_set[86] = io_events_sets_86_value;
  assign event_set[87] = io_events_sets_87_value;
  assign event_set[88] = io_events_sets_88_value;
  assign event_set[89] = io_events_sets_89_value;
  assign event_set[90] = io_events_sets_90_value;
  assign event_set[91] = io_events_sets_91_value;
  assign event_set[92] = io_events_sets_92_value;
  assign event_set[93] = io_events_sets_93_value;
  assign event_set[94] = io_events_sets_94_value;
  assign event_set[95] = io_events_sets_95_value;
  assign event_set[96] = io_events_sets_96_value;
  assign event_set[97] = io_events_sets_97_value;
  assign event_set[98] = io_events_sets_98_value;
  assign event_set[99] = io_events_sets_99_value;
  assign event_set[100] = io_events_sets_100_value;
  assign event_set[101] = io_events_sets_101_value;
  assign event_set[102] = io_events_sets_102_value;
  assign event_set[103] = io_events_sets_103_value;
  assign event_set[104] = io_events_sets_104_value;
  assign event_set[105] = io_events_sets_105_value;
  assign event_set[106] = io_events_sets_106_value;
  assign event_set[107] = io_events_sets_107_value;
  assign event_set[108] = io_events_sets_108_value;
  assign event_set[109] = io_events_sets_109_value;
  assign event_set[110] = io_events_sets_110_value;
  assign event_set[111] = io_events_sets_111_value;
  assign event_set[112] = io_events_sets_112_value;
  assign event_set[113] = io_events_sets_113_value;
  assign event_set[114] = io_events_sets_114_value;
  assign event_set[115] = io_events_sets_115_value;
  assign event_set[116] = io_events_sets_116_value;
  assign event_set[117] = io_events_sets_117_value;
  assign event_set[118] = io_events_sets_118_value;
  assign event_set[119] = io_events_sets_119_value;
  assign event_set[120] = io_events_sets_120_value;
  assign event_set[121] = io_events_sets_121_value;
  assign event_set[122] = io_events_sets_122_value;
  assign event_set[123] = io_events_sets_123_value;
  assign event_set[124] = io_events_sets_124_value;
  assign event_set[125] = io_events_sets_125_value;
  assign event_set[126] = io_events_sets_126_value;
  assign event_set[127] = io_events_sets_127_value;
  assign event_set[128] = io_events_sets_128_value;
  assign event_set[129] = io_events_sets_129_value;
  assign event_set[130] = io_events_sets_130_value;
  assign event_set[131] = io_events_sets_131_value;
  assign event_set[132] = io_events_sets_132_value;
  assign event_set[133] = io_events_sets_133_value;
  assign event_set[134] = io_events_sets_134_value;
  assign event_set[135] = io_events_sets_135_value;
  assign event_set[136] = io_events_sets_136_value;
  assign event_set[137] = io_events_sets_137_value;
  assign event_set[138] = io_events_sets_138_value;
  assign event_set[139] = io_events_sets_139_value;
  assign event_set[140] = io_events_sets_140_value;
  assign event_set[141] = io_events_sets_141_value;
  assign event_set[142] = io_events_sets_142_value;
  assign event_set[143] = io_events_sets_143_value;
  assign io_perf_0_value = perf_value[0];
  assign io_perf_1_value = perf_value[1];
  assign io_perf_2_value = perf_value[2];
  assign io_perf_3_value = perf_value[3];
  assign io_perf_4_value = perf_value[4];
  assign io_perf_5_value = perf_value[5];
  assign io_perf_6_value = perf_value[6];
  assign io_perf_7_value = perf_value[7];

  xs_HPerfMonitor_core #(.NUM_CNT(8), .NUM_SETS(144), .W(6)) u_core (
    .clock      (clock),
    .hpm_event  (hpm_event),
    .event_set  (event_set),
    .perf_value (perf_value)
  );
endmodule
