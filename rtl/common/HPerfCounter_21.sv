// =============================================================================
// HPerfCounter_21.sv —— 硬件性能计数器的事件选择/组合流水线（utility.HPerfCounter，numPCnt=144）
//
// 在哪一层：HPerfMonitor_3 里例化 8 份，每份对应一个 mhpmevent CSR。上游把本层级能观测的
//   144 个性能事件（每个 6 位增量 PerfEvent.value）平铺送进来，CSR 的 64 位 mhpmevent 编码
//   决定"选哪 4 个事件、怎么两两组合"，输出一个 6 位增量给 CSR 的 mhpmcounter 累加。
// 设计源：utility/src/main/scala/utility/HardwarePerfMonitor.scala class HPerfCounter。
//
// mhpmevent 编码（本层只读这 55 位）：
//   [9:0]/[19:10]/[29:20]/[39:30]  四个事件下标 —— ★firtool 只取各段低 8 位★（Vec(144) 的
//        下标按 256 取模），下标 0 与 144..255 读到常量 0（事件 0 在上游恒 0，端口已被消掉）
//   [44:40]/[49:45]/[54:50]        三个组合算子 op0/op1/op2
//   combine(a, b, op) = op[0] ? a&b : op[1] ? a^b : op[2] ? a+b（6 位截断） : a|b
// 四级流水（全部无复位，与 golden 一致）：
//   S1 选出 4 个事件增量 events_incr_0..3、打拍 op0/op1/op2
//   S2 step0 = combine(incr0, incr1, op0)，step1 = combine(incr2, incr3, op1)，op2 再打一拍
//   S3 selected = combine(step0, step1, op2)      —— generatePerfEvent 的第一拍
//   S4 再打一拍输出                                —— generatePerfEvent 的第二拍
// golden 对照：G1-canonical/golden-rtl/HPerfCounter_21.sv（regs 12 个 = 4+3+1+2+2）
// =============================================================================
module xs_HPerfCounter_core #(
  parameter int NUM_SETS = 144,      // 本层级事件数（含恒 0 的第 0 号）
  parameter int W        = 6         // 事件增量位宽
) (
  input  logic          clock,
  input  logic [63:0]   hpm_event,
  input  logic [W-1:0]  event_set [NUM_SETS],
  output logic [W-1:0]  perf_value
);
  localparam int IDX_W = 8;          // firtool 按 8 位下标（256 项）查表

  // 查表：下标落在 [0, NUM_SETS) 取事件值，否则 0（Chisel Vec 越界在 G1 展开成"填 0 项"的
  // 效果——第 0 项本身恒 0）。写成循环形式是为了让 FM 看得出下标范围（见 CONVENTIONS ELAB-147）。
  function automatic logic [W-1:0] pick(input logic [W-1:0] sets [NUM_SETS], input logic [IDX_W-1:0] idx);
    logic [W-1:0] v;
    v = '0;
    for (int i = 0; i < NUM_SETS; i++) if (idx == IDX_W'(i)) v = sets[i];
    return v;
  endfunction

  function automatic logic [W-1:0] combine(input logic [W-1:0] a, input logic [W-1:0] b,
                                           input logic [4:0] op);
    if (op[0])      return a & b;
    else if (op[1]) return a ^ b;
    else if (op[2]) return W'(a + b);
    else            return a | b;
  endfunction

  // ---- S1：事件选择与算子打拍 ----
  logic [W-1:0] events_incr_value [4];
  // 三个算子各 5 位，但 combine 只看低 3 位：[4:3] 两侧（golden 同为 5 位寄存器）都是死位。
  // 名字照抄 golden 的 event_op_0/1/2（不用数组），让 FM 按名把这些死位一一配上，再由
  // verif/fm_target_config/HPerfCounter_21.tcl 打开 vmucp 实际比较。
  logic [4:0]   event_op_0, event_op_1, event_op_2;
  always_ff @(posedge clock) begin
    events_incr_value[0] <= pick(event_set, hpm_event[7:0]);
    events_incr_value[1] <= pick(event_set, hpm_event[17:10]);
    events_incr_value[2] <= pick(event_set, hpm_event[27:20]);
    events_incr_value[3] <= pick(event_set, hpm_event[37:30]);
    event_op_0 <= hpm_event[44:40];
    event_op_1 <= hpm_event[49:45];
    event_op_2 <= hpm_event[54:50];
  end

  // ---- S2：两两组合 ----
  logic [W-1:0] event_step_reg [2];
  logic [4:0]   event_op_2_reg;
  always_ff @(posedge clock) begin
    event_step_reg[0] <= combine(events_incr_value[0], events_incr_value[1], event_op_0);
    event_step_reg[1] <= combine(events_incr_value[2], events_incr_value[3], event_op_1);
    event_op_2_reg    <= event_op_2;
  end

  // ---- S3/S4：最终组合 + 两拍输出打拍 ----
  logic [W-1:0] selected_q, selected_qq;
  always_ff @(posedge clock) begin
    selected_q  <= combine(event_step_reg[0], event_step_reg[1], event_op_2_reg);
    selected_qq <= selected_q;
  end
  assign perf_value = selected_qq;
endmodule

module HPerfCounter_21 (
  input  logic         clock,
  input  logic [63:0]  io_hpm_event,
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
  output logic [5:0]   io_perf_0_value
);
  logic [5:0] event_set [144];
  assign event_set[0] = 6'h0;     // 事件 0 在上游恒 0，golden 没有这个端口
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

  xs_HPerfCounter_core #(.NUM_SETS(144), .W(6)) u_core (
    .clock      (clock),
    .hpm_event  (io_hpm_event),
    .event_set  (event_set),
    .perf_value (io_perf_0_value)
  );
endmodule
