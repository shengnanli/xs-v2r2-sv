// tb -- HPerfMonitor_2 UT: golden (u_g) vs readable _xs (u_i), per-cycle output compare.
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic [63:0] io_hpm_event_0;
  logic [63:0] io_hpm_event_1;
  logic [63:0] io_hpm_event_2;
  logic [63:0] io_hpm_event_3;
  logic [63:0] io_hpm_event_4;
  logic [63:0] io_hpm_event_5;
  logic [63:0] io_hpm_event_6;
  logic [63:0] io_hpm_event_7;
  logic [5:0]  io_events_sets_1_value;
  logic [5:0]  io_events_sets_2_value;
  logic [5:0]  io_events_sets_3_value;
  logic [5:0]  io_events_sets_4_value;
  logic [5:0]  io_events_sets_5_value;
  logic [5:0]  io_events_sets_6_value;
  logic [5:0]  io_events_sets_7_value;
  logic [5:0]  io_events_sets_8_value;
  logic [5:0]  io_events_sets_9_value;
  logic [5:0]  io_events_sets_10_value;
  logic [5:0]  io_events_sets_11_value;
  logic [5:0]  io_events_sets_12_value;
  logic [5:0]  io_events_sets_13_value;
  logic [5:0]  io_events_sets_14_value;
  logic [5:0]  io_events_sets_15_value;
  logic [5:0]  io_events_sets_16_value;
  logic [5:0]  io_events_sets_17_value;
  logic [5:0]  io_events_sets_18_value;
  logic [5:0]  io_events_sets_19_value;
  logic [5:0]  io_events_sets_20_value;
  logic [5:0]  io_events_sets_21_value;
  logic [5:0]  io_events_sets_22_value;
  logic [5:0]  io_events_sets_23_value;
  logic [5:0]  io_events_sets_24_value;
  logic [5:0]  io_events_sets_25_value;
  logic [5:0]  io_events_sets_26_value;
  logic [5:0]  io_events_sets_27_value;
  logic [5:0]  io_events_sets_28_value;
  logic [5:0]  io_events_sets_29_value;
  logic [5:0]  io_events_sets_30_value;
  logic [5:0]  io_events_sets_31_value;
  logic [5:0]  io_events_sets_32_value;
  logic [5:0]  io_events_sets_33_value;
  logic [5:0]  io_events_sets_34_value;
  logic [5:0]  io_events_sets_35_value;
  logic [5:0]  io_events_sets_36_value;
  logic [5:0]  io_events_sets_37_value;
  logic [5:0]  io_events_sets_38_value;
  logic [5:0]  io_events_sets_39_value;
  logic [5:0]  io_events_sets_40_value;
  logic [5:0]  io_events_sets_42_value;
  logic [5:0]  io_events_sets_43_value;
  logic [5:0]  io_events_sets_44_value;
  logic [5:0]  io_events_sets_45_value;
  logic [5:0]  io_events_sets_46_value;
  logic [5:0]  io_events_sets_47_value;
  logic [5:0]  io_events_sets_48_value;
  logic [5:0]  io_events_sets_49_value;
  logic [5:0]  io_events_sets_50_value;
  logic [5:0]  io_events_sets_51_value;
  logic [5:0]  io_events_sets_52_value;
  logic [5:0]  io_events_sets_53_value;
  logic [5:0]  io_events_sets_54_value;
  logic [5:0]  io_events_sets_55_value;
  logic [5:0]  io_events_sets_56_value;
  logic [5:0]  io_events_sets_57_value;
  logic [5:0]  io_events_sets_58_value;
  logic [5:0]  io_events_sets_59_value;
  logic [5:0]  io_events_sets_60_value;
  logic [5:0]  io_events_sets_61_value;
  logic [5:0]  io_events_sets_62_value;
  logic [5:0]  io_events_sets_63_value;
  logic [5:0]  io_events_sets_64_value;
  logic [5:0]  io_events_sets_65_value;
  logic [5:0]  io_events_sets_66_value;
  logic [5:0]  io_events_sets_67_value;
  logic [5:0]  io_events_sets_68_value;
  logic [5:0]  io_events_sets_69_value;
  logic [5:0]  io_events_sets_70_value;
  logic [5:0]  io_events_sets_71_value;
  logic [5:0]  io_events_sets_72_value;
  logic [5:0]  io_events_sets_73_value;
  logic [5:0]  io_events_sets_74_value;
  logic [5:0]  io_events_sets_75_value;
  logic [5:0]  io_events_sets_76_value;
  logic [5:0]  io_events_sets_77_value;
  logic [5:0]  io_events_sets_78_value;
  logic [5:0]  io_events_sets_79_value;
  logic [5:0]  io_events_sets_80_value;
  logic [5:0]  io_events_sets_81_value;
  logic [5:0]  io_events_sets_82_value;
  logic [5:0]  io_events_sets_83_value;
  logic [5:0]  io_events_sets_84_value;
  logic [5:0]  io_events_sets_85_value;
  logic [5:0]  io_events_sets_86_value;
  logic [5:0]  io_events_sets_87_value;
  logic [5:0]  io_events_sets_88_value;
  logic [5:0]  io_events_sets_89_value;
  logic [5:0]  io_events_sets_90_value;
  logic [5:0]  io_events_sets_91_value;
  wire [5:0] g_io_perf_0_value, i_io_perf_0_value;
  wire [5:0] g_io_perf_1_value, i_io_perf_1_value;
  wire [5:0] g_io_perf_2_value, i_io_perf_2_value;
  wire [5:0] g_io_perf_3_value, i_io_perf_3_value;
  wire [5:0] g_io_perf_4_value, i_io_perf_4_value;
  wire [5:0] g_io_perf_5_value, i_io_perf_5_value;
  wire [5:0] g_io_perf_6_value, i_io_perf_6_value;
  wire [5:0] g_io_perf_7_value, i_io_perf_7_value;

  HPerfMonitor_2    u_g (
    .clock(clk),
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
    .io_perf_0_value(g_io_perf_0_value),
    .io_perf_1_value(g_io_perf_1_value),
    .io_perf_2_value(g_io_perf_2_value),
    .io_perf_3_value(g_io_perf_3_value),
    .io_perf_4_value(g_io_perf_4_value),
    .io_perf_5_value(g_io_perf_5_value),
    .io_perf_6_value(g_io_perf_6_value),
    .io_perf_7_value(g_io_perf_7_value)
  );

  HPerfMonitor_2_xs u_i (
    .clock(clk),
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
    .io_perf_0_value(i_io_perf_0_value),
    .io_perf_1_value(i_io_perf_1_value),
    .io_perf_2_value(i_io_perf_2_value),
    .io_perf_3_value(i_io_perf_3_value),
    .io_perf_4_value(i_io_perf_4_value),
    .io_perf_5_value(i_io_perf_5_value),
    .io_perf_6_value(i_io_perf_6_value),
    .io_perf_7_value(i_io_perf_7_value)
  );

  task automatic drive_inputs();
    io_hpm_event_0 = {$urandom,$urandom};
    io_hpm_event_1 = {$urandom,$urandom};
    io_hpm_event_2 = {$urandom,$urandom};
    io_hpm_event_3 = {$urandom,$urandom};
    io_hpm_event_4 = {$urandom,$urandom};
    io_hpm_event_5 = {$urandom,$urandom};
    io_hpm_event_6 = {$urandom,$urandom};
    io_hpm_event_7 = {$urandom,$urandom};
    io_hpm_event_0[6:0]   = $urandom % 8'd120;
    io_hpm_event_0[16:10] = $urandom % 8'd120;
    io_hpm_event_0[26:20] = $urandom % 8'd120;
    io_hpm_event_0[36:30] = $urandom % 8'd120;
    io_hpm_event_1[6:0]   = $urandom % 8'd120;
    io_hpm_event_1[16:10] = $urandom % 8'd120;
    io_hpm_event_1[26:20] = $urandom % 8'd120;
    io_hpm_event_1[36:30] = $urandom % 8'd120;
    io_hpm_event_2[6:0]   = $urandom % 8'd120;
    io_hpm_event_2[16:10] = $urandom % 8'd120;
    io_hpm_event_2[26:20] = $urandom % 8'd120;
    io_hpm_event_2[36:30] = $urandom % 8'd120;
    io_hpm_event_3[6:0]   = $urandom % 8'd120;
    io_hpm_event_3[16:10] = $urandom % 8'd120;
    io_hpm_event_3[26:20] = $urandom % 8'd120;
    io_hpm_event_3[36:30] = $urandom % 8'd120;
    io_hpm_event_4[6:0]   = $urandom % 8'd120;
    io_hpm_event_4[16:10] = $urandom % 8'd120;
    io_hpm_event_4[26:20] = $urandom % 8'd120;
    io_hpm_event_4[36:30] = $urandom % 8'd120;
    io_hpm_event_5[6:0]   = $urandom % 8'd120;
    io_hpm_event_5[16:10] = $urandom % 8'd120;
    io_hpm_event_5[26:20] = $urandom % 8'd120;
    io_hpm_event_5[36:30] = $urandom % 8'd120;
    io_hpm_event_6[6:0]   = $urandom % 8'd120;
    io_hpm_event_6[16:10] = $urandom % 8'd120;
    io_hpm_event_6[26:20] = $urandom % 8'd120;
    io_hpm_event_6[36:30] = $urandom % 8'd120;
    io_hpm_event_7[6:0]   = $urandom % 8'd120;
    io_hpm_event_7[16:10] = $urandom % 8'd120;
    io_hpm_event_7[26:20] = $urandom % 8'd120;
    io_hpm_event_7[36:30] = $urandom % 8'd120;
    io_events_sets_1_value = $urandom;
    io_events_sets_2_value = $urandom;
    io_events_sets_3_value = $urandom;
    io_events_sets_4_value = $urandom;
    io_events_sets_5_value = $urandom;
    io_events_sets_6_value = $urandom;
    io_events_sets_7_value = $urandom;
    io_events_sets_8_value = $urandom;
    io_events_sets_9_value = $urandom;
    io_events_sets_10_value = $urandom;
    io_events_sets_11_value = $urandom;
    io_events_sets_12_value = $urandom;
    io_events_sets_13_value = $urandom;
    io_events_sets_14_value = $urandom;
    io_events_sets_15_value = $urandom;
    io_events_sets_16_value = $urandom;
    io_events_sets_17_value = $urandom;
    io_events_sets_18_value = $urandom;
    io_events_sets_19_value = $urandom;
    io_events_sets_20_value = $urandom;
    io_events_sets_21_value = $urandom;
    io_events_sets_22_value = $urandom;
    io_events_sets_23_value = $urandom;
    io_events_sets_24_value = $urandom;
    io_events_sets_25_value = $urandom;
    io_events_sets_26_value = $urandom;
    io_events_sets_27_value = $urandom;
    io_events_sets_28_value = $urandom;
    io_events_sets_29_value = $urandom;
    io_events_sets_30_value = $urandom;
    io_events_sets_31_value = $urandom;
    io_events_sets_32_value = $urandom;
    io_events_sets_33_value = $urandom;
    io_events_sets_34_value = $urandom;
    io_events_sets_35_value = $urandom;
    io_events_sets_36_value = $urandom;
    io_events_sets_37_value = $urandom;
    io_events_sets_38_value = $urandom;
    io_events_sets_39_value = $urandom;
    io_events_sets_40_value = $urandom;
    io_events_sets_42_value = $urandom;
    io_events_sets_43_value = $urandom;
    io_events_sets_44_value = $urandom;
    io_events_sets_45_value = $urandom;
    io_events_sets_46_value = $urandom;
    io_events_sets_47_value = $urandom;
    io_events_sets_48_value = $urandom;
    io_events_sets_49_value = $urandom;
    io_events_sets_50_value = $urandom;
    io_events_sets_51_value = $urandom;
    io_events_sets_52_value = $urandom;
    io_events_sets_53_value = $urandom;
    io_events_sets_54_value = $urandom;
    io_events_sets_55_value = $urandom;
    io_events_sets_56_value = $urandom;
    io_events_sets_57_value = $urandom;
    io_events_sets_58_value = $urandom;
    io_events_sets_59_value = $urandom;
    io_events_sets_60_value = $urandom;
    io_events_sets_61_value = $urandom;
    io_events_sets_62_value = $urandom;
    io_events_sets_63_value = $urandom;
    io_events_sets_64_value = $urandom;
    io_events_sets_65_value = $urandom;
    io_events_sets_66_value = $urandom;
    io_events_sets_67_value = $urandom;
    io_events_sets_68_value = $urandom;
    io_events_sets_69_value = $urandom;
    io_events_sets_70_value = $urandom;
    io_events_sets_71_value = $urandom;
    io_events_sets_72_value = $urandom;
    io_events_sets_73_value = $urandom;
    io_events_sets_74_value = $urandom;
    io_events_sets_75_value = $urandom;
    io_events_sets_76_value = $urandom;
    io_events_sets_77_value = $urandom;
    io_events_sets_78_value = $urandom;
    io_events_sets_79_value = $urandom;
    io_events_sets_80_value = $urandom;
    io_events_sets_81_value = $urandom;
    io_events_sets_82_value = $urandom;
    io_events_sets_83_value = $urandom;
    io_events_sets_84_value = $urandom;
    io_events_sets_85_value = $urandom;
    io_events_sets_86_value = $urandom;
    io_events_sets_87_value = $urandom;
    io_events_sets_88_value = $urandom;
    io_events_sets_89_value = $urandom;
    io_events_sets_90_value = $urandom;
    io_events_sets_91_value = $urandom;
  endtask

  task automatic check_outputs();
    checks++;
    if (!$isunknown(g_io_perf_0_value) && g_io_perf_0_value !== i_io_perf_0_value) begin errors++; if (errors<=40) $display("[%0d] MISMATCH perf_0 g=%h i=%h", cyc, g_io_perf_0_value, i_io_perf_0_value); end
    if (!$isunknown(g_io_perf_1_value) && g_io_perf_1_value !== i_io_perf_1_value) begin errors++; if (errors<=40) $display("[%0d] MISMATCH perf_1 g=%h i=%h", cyc, g_io_perf_1_value, i_io_perf_1_value); end
    if (!$isunknown(g_io_perf_2_value) && g_io_perf_2_value !== i_io_perf_2_value) begin errors++; if (errors<=40) $display("[%0d] MISMATCH perf_2 g=%h i=%h", cyc, g_io_perf_2_value, i_io_perf_2_value); end
    if (!$isunknown(g_io_perf_3_value) && g_io_perf_3_value !== i_io_perf_3_value) begin errors++; if (errors<=40) $display("[%0d] MISMATCH perf_3 g=%h i=%h", cyc, g_io_perf_3_value, i_io_perf_3_value); end
    if (!$isunknown(g_io_perf_4_value) && g_io_perf_4_value !== i_io_perf_4_value) begin errors++; if (errors<=40) $display("[%0d] MISMATCH perf_4 g=%h i=%h", cyc, g_io_perf_4_value, i_io_perf_4_value); end
    if (!$isunknown(g_io_perf_5_value) && g_io_perf_5_value !== i_io_perf_5_value) begin errors++; if (errors<=40) $display("[%0d] MISMATCH perf_5 g=%h i=%h", cyc, g_io_perf_5_value, i_io_perf_5_value); end
    if (!$isunknown(g_io_perf_6_value) && g_io_perf_6_value !== i_io_perf_6_value) begin errors++; if (errors<=40) $display("[%0d] MISMATCH perf_6 g=%h i=%h", cyc, g_io_perf_6_value, i_io_perf_6_value); end
    if (!$isunknown(g_io_perf_7_value) && g_io_perf_7_value !== i_io_perf_7_value) begin errors++; if (errors<=40) $display("[%0d] MISMATCH perf_7 g=%h i=%h", cyc, g_io_perf_7_value, i_io_perf_7_value); end
  endtask

  initial begin
    io_hpm_event_0 = '0;
    io_hpm_event_1 = '0;
    io_hpm_event_2 = '0;
    io_hpm_event_3 = '0;
    io_hpm_event_4 = '0;
    io_hpm_event_5 = '0;
    io_hpm_event_6 = '0;
    io_hpm_event_7 = '0;
    io_events_sets_1_value = '0;
    io_events_sets_2_value = '0;
    io_events_sets_3_value = '0;
    io_events_sets_4_value = '0;
    io_events_sets_5_value = '0;
    io_events_sets_6_value = '0;
    io_events_sets_7_value = '0;
    io_events_sets_8_value = '0;
    io_events_sets_9_value = '0;
    io_events_sets_10_value = '0;
    io_events_sets_11_value = '0;
    io_events_sets_12_value = '0;
    io_events_sets_13_value = '0;
    io_events_sets_14_value = '0;
    io_events_sets_15_value = '0;
    io_events_sets_16_value = '0;
    io_events_sets_17_value = '0;
    io_events_sets_18_value = '0;
    io_events_sets_19_value = '0;
    io_events_sets_20_value = '0;
    io_events_sets_21_value = '0;
    io_events_sets_22_value = '0;
    io_events_sets_23_value = '0;
    io_events_sets_24_value = '0;
    io_events_sets_25_value = '0;
    io_events_sets_26_value = '0;
    io_events_sets_27_value = '0;
    io_events_sets_28_value = '0;
    io_events_sets_29_value = '0;
    io_events_sets_30_value = '0;
    io_events_sets_31_value = '0;
    io_events_sets_32_value = '0;
    io_events_sets_33_value = '0;
    io_events_sets_34_value = '0;
    io_events_sets_35_value = '0;
    io_events_sets_36_value = '0;
    io_events_sets_37_value = '0;
    io_events_sets_38_value = '0;
    io_events_sets_39_value = '0;
    io_events_sets_40_value = '0;
    io_events_sets_42_value = '0;
    io_events_sets_43_value = '0;
    io_events_sets_44_value = '0;
    io_events_sets_45_value = '0;
    io_events_sets_46_value = '0;
    io_events_sets_47_value = '0;
    io_events_sets_48_value = '0;
    io_events_sets_49_value = '0;
    io_events_sets_50_value = '0;
    io_events_sets_51_value = '0;
    io_events_sets_52_value = '0;
    io_events_sets_53_value = '0;
    io_events_sets_54_value = '0;
    io_events_sets_55_value = '0;
    io_events_sets_56_value = '0;
    io_events_sets_57_value = '0;
    io_events_sets_58_value = '0;
    io_events_sets_59_value = '0;
    io_events_sets_60_value = '0;
    io_events_sets_61_value = '0;
    io_events_sets_62_value = '0;
    io_events_sets_63_value = '0;
    io_events_sets_64_value = '0;
    io_events_sets_65_value = '0;
    io_events_sets_66_value = '0;
    io_events_sets_67_value = '0;
    io_events_sets_68_value = '0;
    io_events_sets_69_value = '0;
    io_events_sets_70_value = '0;
    io_events_sets_71_value = '0;
    io_events_sets_72_value = '0;
    io_events_sets_73_value = '0;
    io_events_sets_74_value = '0;
    io_events_sets_75_value = '0;
    io_events_sets_76_value = '0;
    io_events_sets_77_value = '0;
    io_events_sets_78_value = '0;
    io_events_sets_79_value = '0;
    io_events_sets_80_value = '0;
    io_events_sets_81_value = '0;
    io_events_sets_82_value = '0;
    io_events_sets_83_value = '0;
    io_events_sets_84_value = '0;
    io_events_sets_85_value = '0;
    io_events_sets_86_value = '0;
    io_events_sets_87_value = '0;
    io_events_sets_88_value = '0;
    io_events_sets_89_value = '0;
    io_events_sets_90_value = '0;
    io_events_sets_91_value = '0;
    repeat (8) @(negedge clk);
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      drive_inputs();
      @(posedge clk);
      #1;
      if (cyc >= WARMUP) check_outputs();
      @(negedge clk);
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
