// 生成 HPerfMonitor / HPerfMonitor_1 / HPerfMonitor_2 的 UT testbench（tb.sv）：三对双例化 + 独立参考模型。
//
// 一、双例化（scripts/dual_tb_lib.py，端口表读 G1 golden）：每个变体 golden（例化 golden HPerfCounter*）vs
//    重写 <变体>_xs（例化重写件 HPerfCounter*_xs → xs_HPerfCounter_core），逐拍比全部 io_perf_*_value。
//    全部寄存器无复位、无 reset 端口：暖机 8 拍（最长通路 6 拍）后开始比。
// 二、独立参考模型（纯 SV，按 utility/HardwarePerfMonitor.scala 定义，不读任何实现内部信号）：
//    每个计数器 c：4 个事件号 hpm_event[9:0]/[19:10]/[29:20]/[39:30] 取低 B 位（B = clog2(numPCnt)）选事件增量；
//    编号不在 golden 端口表里的槽位是父级接的常数（见 HOLE_CONST，除 Backend 第 96 号为 1 外都是 0）；
//    编号 >= numPCnt 是 Chisel 越界下标，G1 firtool 取第 0 项；3 个算子 op0=[44:40]、op1=[49:45]、
//    op2=[54:50] 按 combineEvents（op[0] 与 / op[1] 异或 / op[2] 加 / 否则 或，优先级自低位）两级归约。
//    tb 每个上升沿按当拍输入算出期望值压进 6 级移位链，输出与 6 拍前的期望逐个核对（golden 与重写件同时核）。
//    numPCnt 与"哪些槽位在端口表里"是从 golden 端口表读的接口事实（不是内部实现）。
// 激励偏置：每个事件号字段 1/2 取在表槽位、1/4 取缺槽 / 越界编号、1/4 任意 10 位；每个算子字段 1/2 取 {0,1,2,4}、
//    1/2 任意 5 位（多热走优先级、[4:3] 两侧都不看）；事件增量全随机。
// 覆盖闸：每个变体的 op2 四种归约（与/异或/加/或）各 >= 1000 拍；事件号缺槽 / 越界各 >= 1000 拍；每个输出位见过 0/1。
//
// 用法：python3 gen.py [--check]
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= HPerfMonitor =================
  int unsigned m0_mode = 0;
  // ============================ 独立参考模型（HPerfMonitor：numPCnt=58，事件号取低 6 位）============================
  logic [5:0] m0_ref_tbl [64];
  always_comb m0_ref_tbl = '{
    6'd0,
    tb.m0_io_events_sets_1_value,
    tb.m0_io_events_sets_2_value,
    tb.m0_io_events_sets_3_value,
    tb.m0_io_events_sets_4_value,
    tb.m0_io_events_sets_5_value,
    tb.m0_io_events_sets_6_value,
    tb.m0_io_events_sets_7_value,
    tb.m0_io_events_sets_8_value,
    tb.m0_io_events_sets_9_value,
    tb.m0_io_events_sets_10_value,
    tb.m0_io_events_sets_11_value,
    tb.m0_io_events_sets_12_value,
    tb.m0_io_events_sets_13_value,
    tb.m0_io_events_sets_14_value,
    tb.m0_io_events_sets_15_value,
    tb.m0_io_events_sets_16_value,
    tb.m0_io_events_sets_17_value,
    tb.m0_io_events_sets_18_value,
    tb.m0_io_events_sets_19_value,
    tb.m0_io_events_sets_20_value,
    tb.m0_io_events_sets_21_value,
    tb.m0_io_events_sets_22_value,
    tb.m0_io_events_sets_23_value,
    6'd0,
    tb.m0_io_events_sets_25_value,
    tb.m0_io_events_sets_26_value,
    tb.m0_io_events_sets_27_value,
    tb.m0_io_events_sets_28_value,
    tb.m0_io_events_sets_29_value,
    tb.m0_io_events_sets_30_value,
    tb.m0_io_events_sets_31_value,
    tb.m0_io_events_sets_32_value,
    tb.m0_io_events_sets_33_value,
    tb.m0_io_events_sets_34_value,
    tb.m0_io_events_sets_35_value,
    tb.m0_io_events_sets_36_value,
    tb.m0_io_events_sets_37_value,
    tb.m0_io_events_sets_38_value,
    tb.m0_io_events_sets_39_value,
    tb.m0_io_events_sets_40_value,
    tb.m0_io_events_sets_41_value,
    tb.m0_io_events_sets_42_value,
    tb.m0_io_events_sets_43_value,
    tb.m0_io_events_sets_44_value,
    tb.m0_io_events_sets_45_value,
    tb.m0_io_events_sets_46_value,
    tb.m0_io_events_sets_47_value,
    tb.m0_io_events_sets_48_value,
    tb.m0_io_events_sets_49_value,
    tb.m0_io_events_sets_50_value,
    tb.m0_io_events_sets_51_value,
    tb.m0_io_events_sets_52_value,
    tb.m0_io_events_sets_53_value,
    tb.m0_io_events_sets_54_value,
    tb.m0_io_events_sets_55_value,
    tb.m0_io_events_sets_56_value,
    tb.m0_io_events_sets_57_value,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0
  };
  logic [5:0] m0_ref_pipe [6][8];
  int m0_ref_fill = 0, m0_ref_checks = 0, m0_ref_errors = 0;
  function automatic logic [5:0] m0_combine(input logic [5:0] a, input logic [5:0] b, input logic [4:0] op);
    if (op[0]) return a & b;
    if (op[1]) return a ^ b;
    if (op[2]) return 6'(a + b);
    return a | b;
  endfunction
  function automatic logic [5:0] m0_ref_one(input logic [63:0] e);
    logic [5:0] v [4];
    for (int k = 0; k < 4; k++) begin
      logic [9:0] idx;
      idx = e[10*k +: 10];
      v[k] = m0_ref_tbl[idx[5:0]];
    end
    return m0_combine(m0_combine(v[0], v[1], e[44:40]), m0_combine(v[2], v[3], e[49:45]), e[54:50]);
  endfunction
  always @(posedge clk) begin
    for (int d = 5; d > 0; d--) m0_ref_pipe[d] <= m0_ref_pipe[d - 1];
    m0_ref_pipe[0][0] <= m0_ref_one(tb.m0_io_hpm_event_0);
    m0_ref_pipe[0][1] <= m0_ref_one(tb.m0_io_hpm_event_1);
    m0_ref_pipe[0][2] <= m0_ref_one(tb.m0_io_hpm_event_2);
    m0_ref_pipe[0][3] <= m0_ref_one(tb.m0_io_hpm_event_3);
    m0_ref_pipe[0][4] <= m0_ref_one(tb.m0_io_hpm_event_4);
    m0_ref_pipe[0][5] <= m0_ref_one(tb.m0_io_hpm_event_5);
    m0_ref_pipe[0][6] <= m0_ref_one(tb.m0_io_hpm_event_6);
    m0_ref_pipe[0][7] <= m0_ref_one(tb.m0_io_hpm_event_7);
    m0_ref_fill <= m0_ref_fill + 1;
  end
  always @(negedge clk) begin
    #4;
    if (m0_ref_fill >= 6) begin
      m0_ref_checks++;
      if (tb.m0_g_io_perf_0_value !== m0_ref_pipe[5][0] || tb.m0_i_io_perf_0_value !== m0_ref_pipe[5][0]) begin
        m0_ref_errors++; errors++;
        if (m0_ref_errors <= 10) $display("[ORACLE] HPerfMonitor cyc=%0d perf_0 ref=%h g=%h i=%h", cyc, m0_ref_pipe[5][0], tb.m0_g_io_perf_0_value, tb.m0_i_io_perf_0_value);
      end
      if (tb.m0_g_io_perf_1_value !== m0_ref_pipe[5][1] || tb.m0_i_io_perf_1_value !== m0_ref_pipe[5][1]) begin
        m0_ref_errors++; errors++;
        if (m0_ref_errors <= 10) $display("[ORACLE] HPerfMonitor cyc=%0d perf_1 ref=%h g=%h i=%h", cyc, m0_ref_pipe[5][1], tb.m0_g_io_perf_1_value, tb.m0_i_io_perf_1_value);
      end
      if (tb.m0_g_io_perf_2_value !== m0_ref_pipe[5][2] || tb.m0_i_io_perf_2_value !== m0_ref_pipe[5][2]) begin
        m0_ref_errors++; errors++;
        if (m0_ref_errors <= 10) $display("[ORACLE] HPerfMonitor cyc=%0d perf_2 ref=%h g=%h i=%h", cyc, m0_ref_pipe[5][2], tb.m0_g_io_perf_2_value, tb.m0_i_io_perf_2_value);
      end
      if (tb.m0_g_io_perf_3_value !== m0_ref_pipe[5][3] || tb.m0_i_io_perf_3_value !== m0_ref_pipe[5][3]) begin
        m0_ref_errors++; errors++;
        if (m0_ref_errors <= 10) $display("[ORACLE] HPerfMonitor cyc=%0d perf_3 ref=%h g=%h i=%h", cyc, m0_ref_pipe[5][3], tb.m0_g_io_perf_3_value, tb.m0_i_io_perf_3_value);
      end
      if (tb.m0_g_io_perf_4_value !== m0_ref_pipe[5][4] || tb.m0_i_io_perf_4_value !== m0_ref_pipe[5][4]) begin
        m0_ref_errors++; errors++;
        if (m0_ref_errors <= 10) $display("[ORACLE] HPerfMonitor cyc=%0d perf_4 ref=%h g=%h i=%h", cyc, m0_ref_pipe[5][4], tb.m0_g_io_perf_4_value, tb.m0_i_io_perf_4_value);
      end
      if (tb.m0_g_io_perf_5_value !== m0_ref_pipe[5][5] || tb.m0_i_io_perf_5_value !== m0_ref_pipe[5][5]) begin
        m0_ref_errors++; errors++;
        if (m0_ref_errors <= 10) $display("[ORACLE] HPerfMonitor cyc=%0d perf_5 ref=%h g=%h i=%h", cyc, m0_ref_pipe[5][5], tb.m0_g_io_perf_5_value, tb.m0_i_io_perf_5_value);
      end
      if (tb.m0_g_io_perf_6_value !== m0_ref_pipe[5][6] || tb.m0_i_io_perf_6_value !== m0_ref_pipe[5][6]) begin
        m0_ref_errors++; errors++;
        if (m0_ref_errors <= 10) $display("[ORACLE] HPerfMonitor cyc=%0d perf_6 ref=%h g=%h i=%h", cyc, m0_ref_pipe[5][6], tb.m0_g_io_perf_6_value, tb.m0_i_io_perf_6_value);
      end
      if (tb.m0_g_io_perf_7_value !== m0_ref_pipe[5][7] || tb.m0_i_io_perf_7_value !== m0_ref_pipe[5][7]) begin
        m0_ref_errors++; errors++;
        if (m0_ref_errors <= 10) $display("[ORACLE] HPerfMonitor cyc=%0d perf_7 ref=%h g=%h i=%h", cyc, m0_ref_pipe[5][7], tb.m0_g_io_perf_7_value, tb.m0_i_io_perf_7_value);
      end
    end
  end
  final $display("[ORACLE] HPerfMonitor checks=%0d errors=%0d", m0_ref_checks, m0_ref_errors);
  logic [63:0] m0_io_hpm_event_0;
  logic [63:0] m0_io_hpm_event_1;
  logic [63:0] m0_io_hpm_event_2;
  logic [63:0] m0_io_hpm_event_3;
  logic [63:0] m0_io_hpm_event_4;
  logic [63:0] m0_io_hpm_event_5;
  logic [63:0] m0_io_hpm_event_6;
  logic [63:0] m0_io_hpm_event_7;
  logic [5:0] m0_io_events_sets_1_value;
  logic [5:0] m0_io_events_sets_2_value;
  logic [5:0] m0_io_events_sets_3_value;
  logic [5:0] m0_io_events_sets_4_value;
  logic [5:0] m0_io_events_sets_5_value;
  logic [5:0] m0_io_events_sets_6_value;
  logic [5:0] m0_io_events_sets_7_value;
  logic [5:0] m0_io_events_sets_8_value;
  logic [5:0] m0_io_events_sets_9_value;
  logic [5:0] m0_io_events_sets_10_value;
  logic [5:0] m0_io_events_sets_11_value;
  logic [5:0] m0_io_events_sets_12_value;
  logic [5:0] m0_io_events_sets_13_value;
  logic [5:0] m0_io_events_sets_14_value;
  logic [5:0] m0_io_events_sets_15_value;
  logic [5:0] m0_io_events_sets_16_value;
  logic [5:0] m0_io_events_sets_17_value;
  logic [5:0] m0_io_events_sets_18_value;
  logic [5:0] m0_io_events_sets_19_value;
  logic [5:0] m0_io_events_sets_20_value;
  logic [5:0] m0_io_events_sets_21_value;
  logic [5:0] m0_io_events_sets_22_value;
  logic [5:0] m0_io_events_sets_23_value;
  logic [5:0] m0_io_events_sets_25_value;
  logic [5:0] m0_io_events_sets_26_value;
  logic [5:0] m0_io_events_sets_27_value;
  logic [5:0] m0_io_events_sets_28_value;
  logic [5:0] m0_io_events_sets_29_value;
  logic [5:0] m0_io_events_sets_30_value;
  logic [5:0] m0_io_events_sets_31_value;
  logic [5:0] m0_io_events_sets_32_value;
  logic [5:0] m0_io_events_sets_33_value;
  logic [5:0] m0_io_events_sets_34_value;
  logic [5:0] m0_io_events_sets_35_value;
  logic [5:0] m0_io_events_sets_36_value;
  logic [5:0] m0_io_events_sets_37_value;
  logic [5:0] m0_io_events_sets_38_value;
  logic [5:0] m0_io_events_sets_39_value;
  logic [5:0] m0_io_events_sets_40_value;
  logic [5:0] m0_io_events_sets_41_value;
  logic [5:0] m0_io_events_sets_42_value;
  logic [5:0] m0_io_events_sets_43_value;
  logic [5:0] m0_io_events_sets_44_value;
  logic [5:0] m0_io_events_sets_45_value;
  logic [5:0] m0_io_events_sets_46_value;
  logic [5:0] m0_io_events_sets_47_value;
  logic [5:0] m0_io_events_sets_48_value;
  logic [5:0] m0_io_events_sets_49_value;
  logic [5:0] m0_io_events_sets_50_value;
  logic [5:0] m0_io_events_sets_51_value;
  logic [5:0] m0_io_events_sets_52_value;
  logic [5:0] m0_io_events_sets_53_value;
  logic [5:0] m0_io_events_sets_54_value;
  logic [5:0] m0_io_events_sets_55_value;
  logic [5:0] m0_io_events_sets_56_value;
  logic [5:0] m0_io_events_sets_57_value;
  wire  [5:0] m0_g_io_perf_0_value, m0_i_io_perf_0_value;
  logic [5:0] m0_s0_io_perf_0_value = '0, m0_s1_io_perf_0_value = '0;
  wire  [5:0] m0_g_io_perf_1_value, m0_i_io_perf_1_value;
  logic [5:0] m0_s0_io_perf_1_value = '0, m0_s1_io_perf_1_value = '0;
  wire  [5:0] m0_g_io_perf_2_value, m0_i_io_perf_2_value;
  logic [5:0] m0_s0_io_perf_2_value = '0, m0_s1_io_perf_2_value = '0;
  wire  [5:0] m0_g_io_perf_3_value, m0_i_io_perf_3_value;
  logic [5:0] m0_s0_io_perf_3_value = '0, m0_s1_io_perf_3_value = '0;
  wire  [5:0] m0_g_io_perf_4_value, m0_i_io_perf_4_value;
  logic [5:0] m0_s0_io_perf_4_value = '0, m0_s1_io_perf_4_value = '0;
  wire  [5:0] m0_g_io_perf_5_value, m0_i_io_perf_5_value;
  logic [5:0] m0_s0_io_perf_5_value = '0, m0_s1_io_perf_5_value = '0;
  wire  [5:0] m0_g_io_perf_6_value, m0_i_io_perf_6_value;
  logic [5:0] m0_s0_io_perf_6_value = '0, m0_s1_io_perf_6_value = '0;
  wire  [5:0] m0_g_io_perf_7_value, m0_i_io_perf_7_value;
  logic [5:0] m0_s0_io_perf_7_value = '0, m0_s1_io_perf_7_value = '0;
  int m0_cov_op2_and = 0;
  int m0_cov_op2_xor = 0;
  int m0_cov_op2_add = 0;
  int m0_cov_op2_or = 0;
  int m0_cov_idx_oob = 0;
  int m0_cov_idx_hole = 0;
  logic [0:0] m0_armed = '0;
  int m0_armed_at = -1;
  HPerfMonitor m0_u_gold (
    .clock(clk),
    .io_hpm_event_0(m0_io_hpm_event_0),
    .io_hpm_event_1(m0_io_hpm_event_1),
    .io_hpm_event_2(m0_io_hpm_event_2),
    .io_hpm_event_3(m0_io_hpm_event_3),
    .io_hpm_event_4(m0_io_hpm_event_4),
    .io_hpm_event_5(m0_io_hpm_event_5),
    .io_hpm_event_6(m0_io_hpm_event_6),
    .io_hpm_event_7(m0_io_hpm_event_7),
    .io_events_sets_1_value(m0_io_events_sets_1_value),
    .io_events_sets_2_value(m0_io_events_sets_2_value),
    .io_events_sets_3_value(m0_io_events_sets_3_value),
    .io_events_sets_4_value(m0_io_events_sets_4_value),
    .io_events_sets_5_value(m0_io_events_sets_5_value),
    .io_events_sets_6_value(m0_io_events_sets_6_value),
    .io_events_sets_7_value(m0_io_events_sets_7_value),
    .io_events_sets_8_value(m0_io_events_sets_8_value),
    .io_events_sets_9_value(m0_io_events_sets_9_value),
    .io_events_sets_10_value(m0_io_events_sets_10_value),
    .io_events_sets_11_value(m0_io_events_sets_11_value),
    .io_events_sets_12_value(m0_io_events_sets_12_value),
    .io_events_sets_13_value(m0_io_events_sets_13_value),
    .io_events_sets_14_value(m0_io_events_sets_14_value),
    .io_events_sets_15_value(m0_io_events_sets_15_value),
    .io_events_sets_16_value(m0_io_events_sets_16_value),
    .io_events_sets_17_value(m0_io_events_sets_17_value),
    .io_events_sets_18_value(m0_io_events_sets_18_value),
    .io_events_sets_19_value(m0_io_events_sets_19_value),
    .io_events_sets_20_value(m0_io_events_sets_20_value),
    .io_events_sets_21_value(m0_io_events_sets_21_value),
    .io_events_sets_22_value(m0_io_events_sets_22_value),
    .io_events_sets_23_value(m0_io_events_sets_23_value),
    .io_events_sets_25_value(m0_io_events_sets_25_value),
    .io_events_sets_26_value(m0_io_events_sets_26_value),
    .io_events_sets_27_value(m0_io_events_sets_27_value),
    .io_events_sets_28_value(m0_io_events_sets_28_value),
    .io_events_sets_29_value(m0_io_events_sets_29_value),
    .io_events_sets_30_value(m0_io_events_sets_30_value),
    .io_events_sets_31_value(m0_io_events_sets_31_value),
    .io_events_sets_32_value(m0_io_events_sets_32_value),
    .io_events_sets_33_value(m0_io_events_sets_33_value),
    .io_events_sets_34_value(m0_io_events_sets_34_value),
    .io_events_sets_35_value(m0_io_events_sets_35_value),
    .io_events_sets_36_value(m0_io_events_sets_36_value),
    .io_events_sets_37_value(m0_io_events_sets_37_value),
    .io_events_sets_38_value(m0_io_events_sets_38_value),
    .io_events_sets_39_value(m0_io_events_sets_39_value),
    .io_events_sets_40_value(m0_io_events_sets_40_value),
    .io_events_sets_41_value(m0_io_events_sets_41_value),
    .io_events_sets_42_value(m0_io_events_sets_42_value),
    .io_events_sets_43_value(m0_io_events_sets_43_value),
    .io_events_sets_44_value(m0_io_events_sets_44_value),
    .io_events_sets_45_value(m0_io_events_sets_45_value),
    .io_events_sets_46_value(m0_io_events_sets_46_value),
    .io_events_sets_47_value(m0_io_events_sets_47_value),
    .io_events_sets_48_value(m0_io_events_sets_48_value),
    .io_events_sets_49_value(m0_io_events_sets_49_value),
    .io_events_sets_50_value(m0_io_events_sets_50_value),
    .io_events_sets_51_value(m0_io_events_sets_51_value),
    .io_events_sets_52_value(m0_io_events_sets_52_value),
    .io_events_sets_53_value(m0_io_events_sets_53_value),
    .io_events_sets_54_value(m0_io_events_sets_54_value),
    .io_events_sets_55_value(m0_io_events_sets_55_value),
    .io_events_sets_56_value(m0_io_events_sets_56_value),
    .io_events_sets_57_value(m0_io_events_sets_57_value),
    .io_perf_0_value(m0_g_io_perf_0_value),
    .io_perf_1_value(m0_g_io_perf_1_value),
    .io_perf_2_value(m0_g_io_perf_2_value),
    .io_perf_3_value(m0_g_io_perf_3_value),
    .io_perf_4_value(m0_g_io_perf_4_value),
    .io_perf_5_value(m0_g_io_perf_5_value),
    .io_perf_6_value(m0_g_io_perf_6_value),
    .io_perf_7_value(m0_g_io_perf_7_value)
  );
  HPerfMonitor_xs m0_u_impl (
    .clock(clk),
    .io_hpm_event_0(m0_io_hpm_event_0),
    .io_hpm_event_1(m0_io_hpm_event_1),
    .io_hpm_event_2(m0_io_hpm_event_2),
    .io_hpm_event_3(m0_io_hpm_event_3),
    .io_hpm_event_4(m0_io_hpm_event_4),
    .io_hpm_event_5(m0_io_hpm_event_5),
    .io_hpm_event_6(m0_io_hpm_event_6),
    .io_hpm_event_7(m0_io_hpm_event_7),
    .io_events_sets_1_value(m0_io_events_sets_1_value),
    .io_events_sets_2_value(m0_io_events_sets_2_value),
    .io_events_sets_3_value(m0_io_events_sets_3_value),
    .io_events_sets_4_value(m0_io_events_sets_4_value),
    .io_events_sets_5_value(m0_io_events_sets_5_value),
    .io_events_sets_6_value(m0_io_events_sets_6_value),
    .io_events_sets_7_value(m0_io_events_sets_7_value),
    .io_events_sets_8_value(m0_io_events_sets_8_value),
    .io_events_sets_9_value(m0_io_events_sets_9_value),
    .io_events_sets_10_value(m0_io_events_sets_10_value),
    .io_events_sets_11_value(m0_io_events_sets_11_value),
    .io_events_sets_12_value(m0_io_events_sets_12_value),
    .io_events_sets_13_value(m0_io_events_sets_13_value),
    .io_events_sets_14_value(m0_io_events_sets_14_value),
    .io_events_sets_15_value(m0_io_events_sets_15_value),
    .io_events_sets_16_value(m0_io_events_sets_16_value),
    .io_events_sets_17_value(m0_io_events_sets_17_value),
    .io_events_sets_18_value(m0_io_events_sets_18_value),
    .io_events_sets_19_value(m0_io_events_sets_19_value),
    .io_events_sets_20_value(m0_io_events_sets_20_value),
    .io_events_sets_21_value(m0_io_events_sets_21_value),
    .io_events_sets_22_value(m0_io_events_sets_22_value),
    .io_events_sets_23_value(m0_io_events_sets_23_value),
    .io_events_sets_25_value(m0_io_events_sets_25_value),
    .io_events_sets_26_value(m0_io_events_sets_26_value),
    .io_events_sets_27_value(m0_io_events_sets_27_value),
    .io_events_sets_28_value(m0_io_events_sets_28_value),
    .io_events_sets_29_value(m0_io_events_sets_29_value),
    .io_events_sets_30_value(m0_io_events_sets_30_value),
    .io_events_sets_31_value(m0_io_events_sets_31_value),
    .io_events_sets_32_value(m0_io_events_sets_32_value),
    .io_events_sets_33_value(m0_io_events_sets_33_value),
    .io_events_sets_34_value(m0_io_events_sets_34_value),
    .io_events_sets_35_value(m0_io_events_sets_35_value),
    .io_events_sets_36_value(m0_io_events_sets_36_value),
    .io_events_sets_37_value(m0_io_events_sets_37_value),
    .io_events_sets_38_value(m0_io_events_sets_38_value),
    .io_events_sets_39_value(m0_io_events_sets_39_value),
    .io_events_sets_40_value(m0_io_events_sets_40_value),
    .io_events_sets_41_value(m0_io_events_sets_41_value),
    .io_events_sets_42_value(m0_io_events_sets_42_value),
    .io_events_sets_43_value(m0_io_events_sets_43_value),
    .io_events_sets_44_value(m0_io_events_sets_44_value),
    .io_events_sets_45_value(m0_io_events_sets_45_value),
    .io_events_sets_46_value(m0_io_events_sets_46_value),
    .io_events_sets_47_value(m0_io_events_sets_47_value),
    .io_events_sets_48_value(m0_io_events_sets_48_value),
    .io_events_sets_49_value(m0_io_events_sets_49_value),
    .io_events_sets_50_value(m0_io_events_sets_50_value),
    .io_events_sets_51_value(m0_io_events_sets_51_value),
    .io_events_sets_52_value(m0_io_events_sets_52_value),
    .io_events_sets_53_value(m0_io_events_sets_53_value),
    .io_events_sets_54_value(m0_io_events_sets_54_value),
    .io_events_sets_55_value(m0_io_events_sets_55_value),
    .io_events_sets_56_value(m0_io_events_sets_56_value),
    .io_events_sets_57_value(m0_io_events_sets_57_value),
    .io_perf_0_value(m0_i_io_perf_0_value),
    .io_perf_1_value(m0_i_io_perf_1_value),
    .io_perf_2_value(m0_i_io_perf_2_value),
    .io_perf_3_value(m0_i_io_perf_3_value),
    .io_perf_4_value(m0_i_io_perf_4_value),
    .io_perf_5_value(m0_i_io_perf_5_value),
    .io_perf_6_value(m0_i_io_perf_6_value),
    .io_perf_7_value(m0_i_io_perf_7_value)
  );

  // ================= HPerfMonitor_1 =================
  int unsigned m1_mode = 0;
  // ============================ 独立参考模型（HPerfMonitor_1：numPCnt=68，事件号取低 7 位）============================
  logic [5:0] m1_ref_tbl [128];
  always_comb m1_ref_tbl = '{
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_1_value,
    tb.m1_io_events_sets_2_value,
    tb.m1_io_events_sets_3_value,
    tb.m1_io_events_sets_4_value,
    tb.m1_io_events_sets_5_value,
    tb.m1_io_events_sets_6_value,
    tb.m1_io_events_sets_7_value,
    tb.m1_io_events_sets_8_value,
    tb.m1_io_events_sets_9_value,
    tb.m1_io_events_sets_10_value,
    tb.m1_io_events_sets_11_value,
    tb.m1_io_events_sets_12_value,
    tb.m1_io_events_sets_13_value,
    tb.m1_io_events_sets_14_value,
    tb.m1_io_events_sets_15_value,
    tb.m1_io_events_sets_16_value,
    tb.m1_io_events_sets_17_value,
    tb.m1_io_events_sets_18_value,
    tb.m1_io_events_sets_19_value,
    tb.m1_io_events_sets_20_value,
    tb.m1_io_events_sets_21_value,
    tb.m1_io_events_sets_22_value,
    tb.m1_io_events_sets_23_value,
    tb.m1_io_events_sets_24_value,
    tb.m1_io_events_sets_25_value,
    tb.m1_io_events_sets_26_value,
    tb.m1_io_events_sets_27_value,
    tb.m1_io_events_sets_28_value,
    tb.m1_io_events_sets_29_value,
    tb.m1_io_events_sets_30_value,
    tb.m1_io_events_sets_31_value,
    tb.m1_io_events_sets_32_value,
    tb.m1_io_events_sets_33_value,
    tb.m1_io_events_sets_34_value,
    tb.m1_io_events_sets_35_value,
    tb.m1_io_events_sets_36_value,
    tb.m1_io_events_sets_37_value,
    tb.m1_io_events_sets_38_value,
    tb.m1_io_events_sets_39_value,
    tb.m1_io_events_sets_40_value,
    tb.m1_io_events_sets_41_value,
    tb.m1_io_events_sets_42_value,
    tb.m1_io_events_sets_43_value,
    tb.m1_io_events_sets_44_value,
    tb.m1_io_events_sets_45_value,
    tb.m1_io_events_sets_46_value,
    tb.m1_io_events_sets_47_value,
    tb.m1_io_events_sets_48_value,
    tb.m1_io_events_sets_49_value,
    tb.m1_io_events_sets_50_value,
    tb.m1_io_events_sets_51_value,
    tb.m1_io_events_sets_52_value,
    tb.m1_io_events_sets_53_value,
    tb.m1_io_events_sets_54_value,
    tb.m1_io_events_sets_55_value,
    tb.m1_io_events_sets_56_value,
    tb.m1_io_events_sets_57_value,
    tb.m1_io_events_sets_58_value,
    tb.m1_io_events_sets_59_value,
    tb.m1_io_events_sets_60_value,
    tb.m1_io_events_sets_61_value,
    tb.m1_io_events_sets_62_value,
    tb.m1_io_events_sets_63_value,
    tb.m1_io_events_sets_64_value,
    tb.m1_io_events_sets_65_value,
    tb.m1_io_events_sets_66_value,
    tb.m1_io_events_sets_67_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value,
    tb.m1_io_events_sets_0_value
  };
  logic [5:0] m1_ref_pipe [6][5];
  int m1_ref_fill = 0, m1_ref_checks = 0, m1_ref_errors = 0;
  function automatic logic [5:0] m1_combine(input logic [5:0] a, input logic [5:0] b, input logic [4:0] op);
    if (op[0]) return a & b;
    if (op[1]) return a ^ b;
    if (op[2]) return 6'(a + b);
    return a | b;
  endfunction
  function automatic logic [5:0] m1_ref_one(input logic [63:0] e);
    logic [5:0] v [4];
    for (int k = 0; k < 4; k++) begin
      logic [9:0] idx;
      idx = e[10*k +: 10];
      v[k] = m1_ref_tbl[idx[6:0]];
    end
    return m1_combine(m1_combine(v[0], v[1], e[44:40]), m1_combine(v[2], v[3], e[49:45]), e[54:50]);
  endfunction
  always @(posedge clk) begin
    for (int d = 5; d > 0; d--) m1_ref_pipe[d] <= m1_ref_pipe[d - 1];
    m1_ref_pipe[0][0] <= m1_ref_one(tb.m1_io_hpm_event_0);
    m1_ref_pipe[0][1] <= m1_ref_one(tb.m1_io_hpm_event_1);
    m1_ref_pipe[0][2] <= m1_ref_one(tb.m1_io_hpm_event_2);
    m1_ref_pipe[0][3] <= m1_ref_one(tb.m1_io_hpm_event_3);
    m1_ref_pipe[0][4] <= m1_ref_one(tb.m1_io_hpm_event_4);
    m1_ref_fill <= m1_ref_fill + 1;
  end
  always @(negedge clk) begin
    #4;
    if (m1_ref_fill >= 6) begin
      m1_ref_checks++;
      if (tb.m1_g_io_perf_0_value !== m1_ref_pipe[5][0] || tb.m1_i_io_perf_0_value !== m1_ref_pipe[5][0]) begin
        m1_ref_errors++; errors++;
        if (m1_ref_errors <= 10) $display("[ORACLE] HPerfMonitor_1 cyc=%0d perf_0 ref=%h g=%h i=%h", cyc, m1_ref_pipe[5][0], tb.m1_g_io_perf_0_value, tb.m1_i_io_perf_0_value);
      end
      if (tb.m1_g_io_perf_1_value !== m1_ref_pipe[5][1] || tb.m1_i_io_perf_1_value !== m1_ref_pipe[5][1]) begin
        m1_ref_errors++; errors++;
        if (m1_ref_errors <= 10) $display("[ORACLE] HPerfMonitor_1 cyc=%0d perf_1 ref=%h g=%h i=%h", cyc, m1_ref_pipe[5][1], tb.m1_g_io_perf_1_value, tb.m1_i_io_perf_1_value);
      end
      if (tb.m1_g_io_perf_2_value !== m1_ref_pipe[5][2] || tb.m1_i_io_perf_2_value !== m1_ref_pipe[5][2]) begin
        m1_ref_errors++; errors++;
        if (m1_ref_errors <= 10) $display("[ORACLE] HPerfMonitor_1 cyc=%0d perf_2 ref=%h g=%h i=%h", cyc, m1_ref_pipe[5][2], tb.m1_g_io_perf_2_value, tb.m1_i_io_perf_2_value);
      end
      if (tb.m1_g_io_perf_3_value !== m1_ref_pipe[5][3] || tb.m1_i_io_perf_3_value !== m1_ref_pipe[5][3]) begin
        m1_ref_errors++; errors++;
        if (m1_ref_errors <= 10) $display("[ORACLE] HPerfMonitor_1 cyc=%0d perf_3 ref=%h g=%h i=%h", cyc, m1_ref_pipe[5][3], tb.m1_g_io_perf_3_value, tb.m1_i_io_perf_3_value);
      end
      if (tb.m1_g_io_perf_4_value !== m1_ref_pipe[5][4] || tb.m1_i_io_perf_4_value !== m1_ref_pipe[5][4]) begin
        m1_ref_errors++; errors++;
        if (m1_ref_errors <= 10) $display("[ORACLE] HPerfMonitor_1 cyc=%0d perf_4 ref=%h g=%h i=%h", cyc, m1_ref_pipe[5][4], tb.m1_g_io_perf_4_value, tb.m1_i_io_perf_4_value);
      end
    end
  end
  final $display("[ORACLE] HPerfMonitor_1 checks=%0d errors=%0d", m1_ref_checks, m1_ref_errors);
  logic [63:0] m1_io_hpm_event_0;
  logic [63:0] m1_io_hpm_event_1;
  logic [63:0] m1_io_hpm_event_2;
  logic [63:0] m1_io_hpm_event_3;
  logic [63:0] m1_io_hpm_event_4;
  logic [5:0] m1_io_events_sets_0_value;
  logic [5:0] m1_io_events_sets_1_value;
  logic [5:0] m1_io_events_sets_2_value;
  logic [5:0] m1_io_events_sets_3_value;
  logic [5:0] m1_io_events_sets_4_value;
  logic [5:0] m1_io_events_sets_5_value;
  logic [5:0] m1_io_events_sets_6_value;
  logic [5:0] m1_io_events_sets_7_value;
  logic [5:0] m1_io_events_sets_8_value;
  logic [5:0] m1_io_events_sets_9_value;
  logic [5:0] m1_io_events_sets_10_value;
  logic [5:0] m1_io_events_sets_11_value;
  logic [5:0] m1_io_events_sets_12_value;
  logic [5:0] m1_io_events_sets_13_value;
  logic [5:0] m1_io_events_sets_14_value;
  logic [5:0] m1_io_events_sets_15_value;
  logic [5:0] m1_io_events_sets_16_value;
  logic [5:0] m1_io_events_sets_17_value;
  logic [5:0] m1_io_events_sets_18_value;
  logic [5:0] m1_io_events_sets_19_value;
  logic [5:0] m1_io_events_sets_20_value;
  logic [5:0] m1_io_events_sets_21_value;
  logic [5:0] m1_io_events_sets_22_value;
  logic [5:0] m1_io_events_sets_23_value;
  logic [5:0] m1_io_events_sets_24_value;
  logic [5:0] m1_io_events_sets_25_value;
  logic [5:0] m1_io_events_sets_26_value;
  logic [5:0] m1_io_events_sets_27_value;
  logic [5:0] m1_io_events_sets_28_value;
  logic [5:0] m1_io_events_sets_29_value;
  logic [5:0] m1_io_events_sets_30_value;
  logic [5:0] m1_io_events_sets_31_value;
  logic [5:0] m1_io_events_sets_32_value;
  logic [5:0] m1_io_events_sets_33_value;
  logic [5:0] m1_io_events_sets_34_value;
  logic [5:0] m1_io_events_sets_35_value;
  logic [5:0] m1_io_events_sets_36_value;
  logic [5:0] m1_io_events_sets_37_value;
  logic [5:0] m1_io_events_sets_38_value;
  logic [5:0] m1_io_events_sets_39_value;
  logic [5:0] m1_io_events_sets_40_value;
  logic [5:0] m1_io_events_sets_41_value;
  logic [5:0] m1_io_events_sets_42_value;
  logic [5:0] m1_io_events_sets_43_value;
  logic [5:0] m1_io_events_sets_44_value;
  logic [5:0] m1_io_events_sets_45_value;
  logic [5:0] m1_io_events_sets_46_value;
  logic [5:0] m1_io_events_sets_47_value;
  logic [5:0] m1_io_events_sets_48_value;
  logic [5:0] m1_io_events_sets_49_value;
  logic [5:0] m1_io_events_sets_50_value;
  logic [5:0] m1_io_events_sets_51_value;
  logic [5:0] m1_io_events_sets_52_value;
  logic [5:0] m1_io_events_sets_53_value;
  logic [5:0] m1_io_events_sets_54_value;
  logic [5:0] m1_io_events_sets_55_value;
  logic [5:0] m1_io_events_sets_56_value;
  logic [5:0] m1_io_events_sets_57_value;
  logic [5:0] m1_io_events_sets_58_value;
  logic [5:0] m1_io_events_sets_59_value;
  logic [5:0] m1_io_events_sets_60_value;
  logic [5:0] m1_io_events_sets_61_value;
  logic [5:0] m1_io_events_sets_62_value;
  logic [5:0] m1_io_events_sets_63_value;
  logic [5:0] m1_io_events_sets_64_value;
  logic [5:0] m1_io_events_sets_65_value;
  logic [5:0] m1_io_events_sets_66_value;
  logic [5:0] m1_io_events_sets_67_value;
  wire  [5:0] m1_g_io_perf_0_value, m1_i_io_perf_0_value;
  logic [5:0] m1_s0_io_perf_0_value = '0, m1_s1_io_perf_0_value = '0;
  wire  [5:0] m1_g_io_perf_1_value, m1_i_io_perf_1_value;
  logic [5:0] m1_s0_io_perf_1_value = '0, m1_s1_io_perf_1_value = '0;
  wire  [5:0] m1_g_io_perf_2_value, m1_i_io_perf_2_value;
  logic [5:0] m1_s0_io_perf_2_value = '0, m1_s1_io_perf_2_value = '0;
  wire  [5:0] m1_g_io_perf_3_value, m1_i_io_perf_3_value;
  logic [5:0] m1_s0_io_perf_3_value = '0, m1_s1_io_perf_3_value = '0;
  wire  [5:0] m1_g_io_perf_4_value, m1_i_io_perf_4_value;
  logic [5:0] m1_s0_io_perf_4_value = '0, m1_s1_io_perf_4_value = '0;
  int m1_cov_op2_and = 0;
  int m1_cov_op2_xor = 0;
  int m1_cov_op2_add = 0;
  int m1_cov_op2_or = 0;
  int m1_cov_idx_oob = 0;
  logic [0:0] m1_armed = '0;
  int m1_armed_at = -1;
  HPerfMonitor_1 m1_u_gold (
    .clock(clk),
    .io_hpm_event_0(m1_io_hpm_event_0),
    .io_hpm_event_1(m1_io_hpm_event_1),
    .io_hpm_event_2(m1_io_hpm_event_2),
    .io_hpm_event_3(m1_io_hpm_event_3),
    .io_hpm_event_4(m1_io_hpm_event_4),
    .io_events_sets_0_value(m1_io_events_sets_0_value),
    .io_events_sets_1_value(m1_io_events_sets_1_value),
    .io_events_sets_2_value(m1_io_events_sets_2_value),
    .io_events_sets_3_value(m1_io_events_sets_3_value),
    .io_events_sets_4_value(m1_io_events_sets_4_value),
    .io_events_sets_5_value(m1_io_events_sets_5_value),
    .io_events_sets_6_value(m1_io_events_sets_6_value),
    .io_events_sets_7_value(m1_io_events_sets_7_value),
    .io_events_sets_8_value(m1_io_events_sets_8_value),
    .io_events_sets_9_value(m1_io_events_sets_9_value),
    .io_events_sets_10_value(m1_io_events_sets_10_value),
    .io_events_sets_11_value(m1_io_events_sets_11_value),
    .io_events_sets_12_value(m1_io_events_sets_12_value),
    .io_events_sets_13_value(m1_io_events_sets_13_value),
    .io_events_sets_14_value(m1_io_events_sets_14_value),
    .io_events_sets_15_value(m1_io_events_sets_15_value),
    .io_events_sets_16_value(m1_io_events_sets_16_value),
    .io_events_sets_17_value(m1_io_events_sets_17_value),
    .io_events_sets_18_value(m1_io_events_sets_18_value),
    .io_events_sets_19_value(m1_io_events_sets_19_value),
    .io_events_sets_20_value(m1_io_events_sets_20_value),
    .io_events_sets_21_value(m1_io_events_sets_21_value),
    .io_events_sets_22_value(m1_io_events_sets_22_value),
    .io_events_sets_23_value(m1_io_events_sets_23_value),
    .io_events_sets_24_value(m1_io_events_sets_24_value),
    .io_events_sets_25_value(m1_io_events_sets_25_value),
    .io_events_sets_26_value(m1_io_events_sets_26_value),
    .io_events_sets_27_value(m1_io_events_sets_27_value),
    .io_events_sets_28_value(m1_io_events_sets_28_value),
    .io_events_sets_29_value(m1_io_events_sets_29_value),
    .io_events_sets_30_value(m1_io_events_sets_30_value),
    .io_events_sets_31_value(m1_io_events_sets_31_value),
    .io_events_sets_32_value(m1_io_events_sets_32_value),
    .io_events_sets_33_value(m1_io_events_sets_33_value),
    .io_events_sets_34_value(m1_io_events_sets_34_value),
    .io_events_sets_35_value(m1_io_events_sets_35_value),
    .io_events_sets_36_value(m1_io_events_sets_36_value),
    .io_events_sets_37_value(m1_io_events_sets_37_value),
    .io_events_sets_38_value(m1_io_events_sets_38_value),
    .io_events_sets_39_value(m1_io_events_sets_39_value),
    .io_events_sets_40_value(m1_io_events_sets_40_value),
    .io_events_sets_41_value(m1_io_events_sets_41_value),
    .io_events_sets_42_value(m1_io_events_sets_42_value),
    .io_events_sets_43_value(m1_io_events_sets_43_value),
    .io_events_sets_44_value(m1_io_events_sets_44_value),
    .io_events_sets_45_value(m1_io_events_sets_45_value),
    .io_events_sets_46_value(m1_io_events_sets_46_value),
    .io_events_sets_47_value(m1_io_events_sets_47_value),
    .io_events_sets_48_value(m1_io_events_sets_48_value),
    .io_events_sets_49_value(m1_io_events_sets_49_value),
    .io_events_sets_50_value(m1_io_events_sets_50_value),
    .io_events_sets_51_value(m1_io_events_sets_51_value),
    .io_events_sets_52_value(m1_io_events_sets_52_value),
    .io_events_sets_53_value(m1_io_events_sets_53_value),
    .io_events_sets_54_value(m1_io_events_sets_54_value),
    .io_events_sets_55_value(m1_io_events_sets_55_value),
    .io_events_sets_56_value(m1_io_events_sets_56_value),
    .io_events_sets_57_value(m1_io_events_sets_57_value),
    .io_events_sets_58_value(m1_io_events_sets_58_value),
    .io_events_sets_59_value(m1_io_events_sets_59_value),
    .io_events_sets_60_value(m1_io_events_sets_60_value),
    .io_events_sets_61_value(m1_io_events_sets_61_value),
    .io_events_sets_62_value(m1_io_events_sets_62_value),
    .io_events_sets_63_value(m1_io_events_sets_63_value),
    .io_events_sets_64_value(m1_io_events_sets_64_value),
    .io_events_sets_65_value(m1_io_events_sets_65_value),
    .io_events_sets_66_value(m1_io_events_sets_66_value),
    .io_events_sets_67_value(m1_io_events_sets_67_value),
    .io_perf_0_value(m1_g_io_perf_0_value),
    .io_perf_1_value(m1_g_io_perf_1_value),
    .io_perf_2_value(m1_g_io_perf_2_value),
    .io_perf_3_value(m1_g_io_perf_3_value),
    .io_perf_4_value(m1_g_io_perf_4_value)
  );
  HPerfMonitor_1_xs m1_u_impl (
    .clock(clk),
    .io_hpm_event_0(m1_io_hpm_event_0),
    .io_hpm_event_1(m1_io_hpm_event_1),
    .io_hpm_event_2(m1_io_hpm_event_2),
    .io_hpm_event_3(m1_io_hpm_event_3),
    .io_hpm_event_4(m1_io_hpm_event_4),
    .io_events_sets_0_value(m1_io_events_sets_0_value),
    .io_events_sets_1_value(m1_io_events_sets_1_value),
    .io_events_sets_2_value(m1_io_events_sets_2_value),
    .io_events_sets_3_value(m1_io_events_sets_3_value),
    .io_events_sets_4_value(m1_io_events_sets_4_value),
    .io_events_sets_5_value(m1_io_events_sets_5_value),
    .io_events_sets_6_value(m1_io_events_sets_6_value),
    .io_events_sets_7_value(m1_io_events_sets_7_value),
    .io_events_sets_8_value(m1_io_events_sets_8_value),
    .io_events_sets_9_value(m1_io_events_sets_9_value),
    .io_events_sets_10_value(m1_io_events_sets_10_value),
    .io_events_sets_11_value(m1_io_events_sets_11_value),
    .io_events_sets_12_value(m1_io_events_sets_12_value),
    .io_events_sets_13_value(m1_io_events_sets_13_value),
    .io_events_sets_14_value(m1_io_events_sets_14_value),
    .io_events_sets_15_value(m1_io_events_sets_15_value),
    .io_events_sets_16_value(m1_io_events_sets_16_value),
    .io_events_sets_17_value(m1_io_events_sets_17_value),
    .io_events_sets_18_value(m1_io_events_sets_18_value),
    .io_events_sets_19_value(m1_io_events_sets_19_value),
    .io_events_sets_20_value(m1_io_events_sets_20_value),
    .io_events_sets_21_value(m1_io_events_sets_21_value),
    .io_events_sets_22_value(m1_io_events_sets_22_value),
    .io_events_sets_23_value(m1_io_events_sets_23_value),
    .io_events_sets_24_value(m1_io_events_sets_24_value),
    .io_events_sets_25_value(m1_io_events_sets_25_value),
    .io_events_sets_26_value(m1_io_events_sets_26_value),
    .io_events_sets_27_value(m1_io_events_sets_27_value),
    .io_events_sets_28_value(m1_io_events_sets_28_value),
    .io_events_sets_29_value(m1_io_events_sets_29_value),
    .io_events_sets_30_value(m1_io_events_sets_30_value),
    .io_events_sets_31_value(m1_io_events_sets_31_value),
    .io_events_sets_32_value(m1_io_events_sets_32_value),
    .io_events_sets_33_value(m1_io_events_sets_33_value),
    .io_events_sets_34_value(m1_io_events_sets_34_value),
    .io_events_sets_35_value(m1_io_events_sets_35_value),
    .io_events_sets_36_value(m1_io_events_sets_36_value),
    .io_events_sets_37_value(m1_io_events_sets_37_value),
    .io_events_sets_38_value(m1_io_events_sets_38_value),
    .io_events_sets_39_value(m1_io_events_sets_39_value),
    .io_events_sets_40_value(m1_io_events_sets_40_value),
    .io_events_sets_41_value(m1_io_events_sets_41_value),
    .io_events_sets_42_value(m1_io_events_sets_42_value),
    .io_events_sets_43_value(m1_io_events_sets_43_value),
    .io_events_sets_44_value(m1_io_events_sets_44_value),
    .io_events_sets_45_value(m1_io_events_sets_45_value),
    .io_events_sets_46_value(m1_io_events_sets_46_value),
    .io_events_sets_47_value(m1_io_events_sets_47_value),
    .io_events_sets_48_value(m1_io_events_sets_48_value),
    .io_events_sets_49_value(m1_io_events_sets_49_value),
    .io_events_sets_50_value(m1_io_events_sets_50_value),
    .io_events_sets_51_value(m1_io_events_sets_51_value),
    .io_events_sets_52_value(m1_io_events_sets_52_value),
    .io_events_sets_53_value(m1_io_events_sets_53_value),
    .io_events_sets_54_value(m1_io_events_sets_54_value),
    .io_events_sets_55_value(m1_io_events_sets_55_value),
    .io_events_sets_56_value(m1_io_events_sets_56_value),
    .io_events_sets_57_value(m1_io_events_sets_57_value),
    .io_events_sets_58_value(m1_io_events_sets_58_value),
    .io_events_sets_59_value(m1_io_events_sets_59_value),
    .io_events_sets_60_value(m1_io_events_sets_60_value),
    .io_events_sets_61_value(m1_io_events_sets_61_value),
    .io_events_sets_62_value(m1_io_events_sets_62_value),
    .io_events_sets_63_value(m1_io_events_sets_63_value),
    .io_events_sets_64_value(m1_io_events_sets_64_value),
    .io_events_sets_65_value(m1_io_events_sets_65_value),
    .io_events_sets_66_value(m1_io_events_sets_66_value),
    .io_events_sets_67_value(m1_io_events_sets_67_value),
    .io_perf_0_value(m1_i_io_perf_0_value),
    .io_perf_1_value(m1_i_io_perf_1_value),
    .io_perf_2_value(m1_i_io_perf_2_value),
    .io_perf_3_value(m1_i_io_perf_3_value),
    .io_perf_4_value(m1_i_io_perf_4_value)
  );

  // ================= HPerfMonitor_2 =================
  int unsigned m2_mode = 0;
  // ============================ 独立参考模型（HPerfMonitor_2：numPCnt=98，事件号取低 7 位）============================
  logic [5:0] m2_ref_tbl [128];
  always_comb m2_ref_tbl = '{
    6'd0,
    tb.m2_io_events_sets_1_value,
    tb.m2_io_events_sets_2_value,
    tb.m2_io_events_sets_3_value,
    tb.m2_io_events_sets_4_value,
    tb.m2_io_events_sets_5_value,
    tb.m2_io_events_sets_6_value,
    tb.m2_io_events_sets_7_value,
    tb.m2_io_events_sets_8_value,
    tb.m2_io_events_sets_9_value,
    tb.m2_io_events_sets_10_value,
    tb.m2_io_events_sets_11_value,
    tb.m2_io_events_sets_12_value,
    tb.m2_io_events_sets_13_value,
    tb.m2_io_events_sets_14_value,
    tb.m2_io_events_sets_15_value,
    tb.m2_io_events_sets_16_value,
    tb.m2_io_events_sets_17_value,
    tb.m2_io_events_sets_18_value,
    tb.m2_io_events_sets_19_value,
    tb.m2_io_events_sets_20_value,
    tb.m2_io_events_sets_21_value,
    tb.m2_io_events_sets_22_value,
    tb.m2_io_events_sets_23_value,
    tb.m2_io_events_sets_24_value,
    tb.m2_io_events_sets_25_value,
    tb.m2_io_events_sets_26_value,
    tb.m2_io_events_sets_27_value,
    tb.m2_io_events_sets_28_value,
    tb.m2_io_events_sets_29_value,
    tb.m2_io_events_sets_30_value,
    tb.m2_io_events_sets_31_value,
    tb.m2_io_events_sets_32_value,
    tb.m2_io_events_sets_33_value,
    tb.m2_io_events_sets_34_value,
    tb.m2_io_events_sets_35_value,
    tb.m2_io_events_sets_36_value,
    tb.m2_io_events_sets_37_value,
    tb.m2_io_events_sets_38_value,
    tb.m2_io_events_sets_39_value,
    tb.m2_io_events_sets_40_value,
    tb.m2_io_events_sets_41_value,
    tb.m2_io_events_sets_42_value,
    6'd0,
    tb.m2_io_events_sets_44_value,
    tb.m2_io_events_sets_45_value,
    tb.m2_io_events_sets_46_value,
    tb.m2_io_events_sets_47_value,
    tb.m2_io_events_sets_48_value,
    tb.m2_io_events_sets_49_value,
    tb.m2_io_events_sets_50_value,
    tb.m2_io_events_sets_51_value,
    tb.m2_io_events_sets_52_value,
    tb.m2_io_events_sets_53_value,
    tb.m2_io_events_sets_54_value,
    tb.m2_io_events_sets_55_value,
    tb.m2_io_events_sets_56_value,
    tb.m2_io_events_sets_57_value,
    tb.m2_io_events_sets_58_value,
    tb.m2_io_events_sets_59_value,
    tb.m2_io_events_sets_60_value,
    tb.m2_io_events_sets_61_value,
    tb.m2_io_events_sets_62_value,
    tb.m2_io_events_sets_63_value,
    tb.m2_io_events_sets_64_value,
    tb.m2_io_events_sets_65_value,
    tb.m2_io_events_sets_66_value,
    tb.m2_io_events_sets_67_value,
    tb.m2_io_events_sets_68_value,
    tb.m2_io_events_sets_69_value,
    tb.m2_io_events_sets_70_value,
    tb.m2_io_events_sets_71_value,
    tb.m2_io_events_sets_72_value,
    tb.m2_io_events_sets_73_value,
    tb.m2_io_events_sets_74_value,
    tb.m2_io_events_sets_75_value,
    tb.m2_io_events_sets_76_value,
    tb.m2_io_events_sets_77_value,
    tb.m2_io_events_sets_78_value,
    tb.m2_io_events_sets_79_value,
    tb.m2_io_events_sets_80_value,
    tb.m2_io_events_sets_81_value,
    tb.m2_io_events_sets_82_value,
    tb.m2_io_events_sets_83_value,
    tb.m2_io_events_sets_84_value,
    tb.m2_io_events_sets_85_value,
    tb.m2_io_events_sets_86_value,
    tb.m2_io_events_sets_87_value,
    tb.m2_io_events_sets_88_value,
    tb.m2_io_events_sets_89_value,
    tb.m2_io_events_sets_90_value,
    tb.m2_io_events_sets_91_value,
    tb.m2_io_events_sets_92_value,
    tb.m2_io_events_sets_93_value,
    tb.m2_io_events_sets_94_value,
    tb.m2_io_events_sets_95_value,
    6'd1,
    tb.m2_io_events_sets_97_value,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0,
    6'd0
  };
  logic [5:0] m2_ref_pipe [6][8];
  int m2_ref_fill = 0, m2_ref_checks = 0, m2_ref_errors = 0;
  function automatic logic [5:0] m2_combine(input logic [5:0] a, input logic [5:0] b, input logic [4:0] op);
    if (op[0]) return a & b;
    if (op[1]) return a ^ b;
    if (op[2]) return 6'(a + b);
    return a | b;
  endfunction
  function automatic logic [5:0] m2_ref_one(input logic [63:0] e);
    logic [5:0] v [4];
    for (int k = 0; k < 4; k++) begin
      logic [9:0] idx;
      idx = e[10*k +: 10];
      v[k] = m2_ref_tbl[idx[6:0]];
    end
    return m2_combine(m2_combine(v[0], v[1], e[44:40]), m2_combine(v[2], v[3], e[49:45]), e[54:50]);
  endfunction
  always @(posedge clk) begin
    for (int d = 5; d > 0; d--) m2_ref_pipe[d] <= m2_ref_pipe[d - 1];
    m2_ref_pipe[0][0] <= m2_ref_one(tb.m2_io_hpm_event_0);
    m2_ref_pipe[0][1] <= m2_ref_one(tb.m2_io_hpm_event_1);
    m2_ref_pipe[0][2] <= m2_ref_one(tb.m2_io_hpm_event_2);
    m2_ref_pipe[0][3] <= m2_ref_one(tb.m2_io_hpm_event_3);
    m2_ref_pipe[0][4] <= m2_ref_one(tb.m2_io_hpm_event_4);
    m2_ref_pipe[0][5] <= m2_ref_one(tb.m2_io_hpm_event_5);
    m2_ref_pipe[0][6] <= m2_ref_one(tb.m2_io_hpm_event_6);
    m2_ref_pipe[0][7] <= m2_ref_one(tb.m2_io_hpm_event_7);
    m2_ref_fill <= m2_ref_fill + 1;
  end
  always @(negedge clk) begin
    #4;
    if (m2_ref_fill >= 6) begin
      m2_ref_checks++;
      if (tb.m2_g_io_perf_0_value !== m2_ref_pipe[5][0] || tb.m2_i_io_perf_0_value !== m2_ref_pipe[5][0]) begin
        m2_ref_errors++; errors++;
        if (m2_ref_errors <= 10) $display("[ORACLE] HPerfMonitor_2 cyc=%0d perf_0 ref=%h g=%h i=%h", cyc, m2_ref_pipe[5][0], tb.m2_g_io_perf_0_value, tb.m2_i_io_perf_0_value);
      end
      if (tb.m2_g_io_perf_1_value !== m2_ref_pipe[5][1] || tb.m2_i_io_perf_1_value !== m2_ref_pipe[5][1]) begin
        m2_ref_errors++; errors++;
        if (m2_ref_errors <= 10) $display("[ORACLE] HPerfMonitor_2 cyc=%0d perf_1 ref=%h g=%h i=%h", cyc, m2_ref_pipe[5][1], tb.m2_g_io_perf_1_value, tb.m2_i_io_perf_1_value);
      end
      if (tb.m2_g_io_perf_2_value !== m2_ref_pipe[5][2] || tb.m2_i_io_perf_2_value !== m2_ref_pipe[5][2]) begin
        m2_ref_errors++; errors++;
        if (m2_ref_errors <= 10) $display("[ORACLE] HPerfMonitor_2 cyc=%0d perf_2 ref=%h g=%h i=%h", cyc, m2_ref_pipe[5][2], tb.m2_g_io_perf_2_value, tb.m2_i_io_perf_2_value);
      end
      if (tb.m2_g_io_perf_3_value !== m2_ref_pipe[5][3] || tb.m2_i_io_perf_3_value !== m2_ref_pipe[5][3]) begin
        m2_ref_errors++; errors++;
        if (m2_ref_errors <= 10) $display("[ORACLE] HPerfMonitor_2 cyc=%0d perf_3 ref=%h g=%h i=%h", cyc, m2_ref_pipe[5][3], tb.m2_g_io_perf_3_value, tb.m2_i_io_perf_3_value);
      end
      if (tb.m2_g_io_perf_4_value !== m2_ref_pipe[5][4] || tb.m2_i_io_perf_4_value !== m2_ref_pipe[5][4]) begin
        m2_ref_errors++; errors++;
        if (m2_ref_errors <= 10) $display("[ORACLE] HPerfMonitor_2 cyc=%0d perf_4 ref=%h g=%h i=%h", cyc, m2_ref_pipe[5][4], tb.m2_g_io_perf_4_value, tb.m2_i_io_perf_4_value);
      end
      if (tb.m2_g_io_perf_5_value !== m2_ref_pipe[5][5] || tb.m2_i_io_perf_5_value !== m2_ref_pipe[5][5]) begin
        m2_ref_errors++; errors++;
        if (m2_ref_errors <= 10) $display("[ORACLE] HPerfMonitor_2 cyc=%0d perf_5 ref=%h g=%h i=%h", cyc, m2_ref_pipe[5][5], tb.m2_g_io_perf_5_value, tb.m2_i_io_perf_5_value);
      end
      if (tb.m2_g_io_perf_6_value !== m2_ref_pipe[5][6] || tb.m2_i_io_perf_6_value !== m2_ref_pipe[5][6]) begin
        m2_ref_errors++; errors++;
        if (m2_ref_errors <= 10) $display("[ORACLE] HPerfMonitor_2 cyc=%0d perf_6 ref=%h g=%h i=%h", cyc, m2_ref_pipe[5][6], tb.m2_g_io_perf_6_value, tb.m2_i_io_perf_6_value);
      end
      if (tb.m2_g_io_perf_7_value !== m2_ref_pipe[5][7] || tb.m2_i_io_perf_7_value !== m2_ref_pipe[5][7]) begin
        m2_ref_errors++; errors++;
        if (m2_ref_errors <= 10) $display("[ORACLE] HPerfMonitor_2 cyc=%0d perf_7 ref=%h g=%h i=%h", cyc, m2_ref_pipe[5][7], tb.m2_g_io_perf_7_value, tb.m2_i_io_perf_7_value);
      end
    end
  end
  final $display("[ORACLE] HPerfMonitor_2 checks=%0d errors=%0d", m2_ref_checks, m2_ref_errors);
  logic [63:0] m2_io_hpm_event_0;
  logic [63:0] m2_io_hpm_event_1;
  logic [63:0] m2_io_hpm_event_2;
  logic [63:0] m2_io_hpm_event_3;
  logic [63:0] m2_io_hpm_event_4;
  logic [63:0] m2_io_hpm_event_5;
  logic [63:0] m2_io_hpm_event_6;
  logic [63:0] m2_io_hpm_event_7;
  logic [5:0] m2_io_events_sets_1_value;
  logic [5:0] m2_io_events_sets_2_value;
  logic [5:0] m2_io_events_sets_3_value;
  logic [5:0] m2_io_events_sets_4_value;
  logic [5:0] m2_io_events_sets_5_value;
  logic [5:0] m2_io_events_sets_6_value;
  logic [5:0] m2_io_events_sets_7_value;
  logic [5:0] m2_io_events_sets_8_value;
  logic [5:0] m2_io_events_sets_9_value;
  logic [5:0] m2_io_events_sets_10_value;
  logic [5:0] m2_io_events_sets_11_value;
  logic [5:0] m2_io_events_sets_12_value;
  logic [5:0] m2_io_events_sets_13_value;
  logic [5:0] m2_io_events_sets_14_value;
  logic [5:0] m2_io_events_sets_15_value;
  logic [5:0] m2_io_events_sets_16_value;
  logic [5:0] m2_io_events_sets_17_value;
  logic [5:0] m2_io_events_sets_18_value;
  logic [5:0] m2_io_events_sets_19_value;
  logic [5:0] m2_io_events_sets_20_value;
  logic [5:0] m2_io_events_sets_21_value;
  logic [5:0] m2_io_events_sets_22_value;
  logic [5:0] m2_io_events_sets_23_value;
  logic [5:0] m2_io_events_sets_24_value;
  logic [5:0] m2_io_events_sets_25_value;
  logic [5:0] m2_io_events_sets_26_value;
  logic [5:0] m2_io_events_sets_27_value;
  logic [5:0] m2_io_events_sets_28_value;
  logic [5:0] m2_io_events_sets_29_value;
  logic [5:0] m2_io_events_sets_30_value;
  logic [5:0] m2_io_events_sets_31_value;
  logic [5:0] m2_io_events_sets_32_value;
  logic [5:0] m2_io_events_sets_33_value;
  logic [5:0] m2_io_events_sets_34_value;
  logic [5:0] m2_io_events_sets_35_value;
  logic [5:0] m2_io_events_sets_36_value;
  logic [5:0] m2_io_events_sets_37_value;
  logic [5:0] m2_io_events_sets_38_value;
  logic [5:0] m2_io_events_sets_39_value;
  logic [5:0] m2_io_events_sets_40_value;
  logic [5:0] m2_io_events_sets_41_value;
  logic [5:0] m2_io_events_sets_42_value;
  logic [5:0] m2_io_events_sets_44_value;
  logic [5:0] m2_io_events_sets_45_value;
  logic [5:0] m2_io_events_sets_46_value;
  logic [5:0] m2_io_events_sets_47_value;
  logic [5:0] m2_io_events_sets_48_value;
  logic [5:0] m2_io_events_sets_49_value;
  logic [5:0] m2_io_events_sets_50_value;
  logic [5:0] m2_io_events_sets_51_value;
  logic [5:0] m2_io_events_sets_52_value;
  logic [5:0] m2_io_events_sets_53_value;
  logic [5:0] m2_io_events_sets_54_value;
  logic [5:0] m2_io_events_sets_55_value;
  logic [5:0] m2_io_events_sets_56_value;
  logic [5:0] m2_io_events_sets_57_value;
  logic [5:0] m2_io_events_sets_58_value;
  logic [5:0] m2_io_events_sets_59_value;
  logic [5:0] m2_io_events_sets_60_value;
  logic [5:0] m2_io_events_sets_61_value;
  logic [5:0] m2_io_events_sets_62_value;
  logic [5:0] m2_io_events_sets_63_value;
  logic [5:0] m2_io_events_sets_64_value;
  logic [5:0] m2_io_events_sets_65_value;
  logic [5:0] m2_io_events_sets_66_value;
  logic [5:0] m2_io_events_sets_67_value;
  logic [5:0] m2_io_events_sets_68_value;
  logic [5:0] m2_io_events_sets_69_value;
  logic [5:0] m2_io_events_sets_70_value;
  logic [5:0] m2_io_events_sets_71_value;
  logic [5:0] m2_io_events_sets_72_value;
  logic [5:0] m2_io_events_sets_73_value;
  logic [5:0] m2_io_events_sets_74_value;
  logic [5:0] m2_io_events_sets_75_value;
  logic [5:0] m2_io_events_sets_76_value;
  logic [5:0] m2_io_events_sets_77_value;
  logic [5:0] m2_io_events_sets_78_value;
  logic [5:0] m2_io_events_sets_79_value;
  logic [5:0] m2_io_events_sets_80_value;
  logic [5:0] m2_io_events_sets_81_value;
  logic [5:0] m2_io_events_sets_82_value;
  logic [5:0] m2_io_events_sets_83_value;
  logic [5:0] m2_io_events_sets_84_value;
  logic [5:0] m2_io_events_sets_85_value;
  logic [5:0] m2_io_events_sets_86_value;
  logic [5:0] m2_io_events_sets_87_value;
  logic [5:0] m2_io_events_sets_88_value;
  logic [5:0] m2_io_events_sets_89_value;
  logic [5:0] m2_io_events_sets_90_value;
  logic [5:0] m2_io_events_sets_91_value;
  logic [5:0] m2_io_events_sets_92_value;
  logic [5:0] m2_io_events_sets_93_value;
  logic [5:0] m2_io_events_sets_94_value;
  logic [5:0] m2_io_events_sets_95_value;
  logic [5:0] m2_io_events_sets_97_value;
  wire  [5:0] m2_g_io_perf_0_value, m2_i_io_perf_0_value;
  logic [5:0] m2_s0_io_perf_0_value = '0, m2_s1_io_perf_0_value = '0;
  wire  [5:0] m2_g_io_perf_1_value, m2_i_io_perf_1_value;
  logic [5:0] m2_s0_io_perf_1_value = '0, m2_s1_io_perf_1_value = '0;
  wire  [5:0] m2_g_io_perf_2_value, m2_i_io_perf_2_value;
  logic [5:0] m2_s0_io_perf_2_value = '0, m2_s1_io_perf_2_value = '0;
  wire  [5:0] m2_g_io_perf_3_value, m2_i_io_perf_3_value;
  logic [5:0] m2_s0_io_perf_3_value = '0, m2_s1_io_perf_3_value = '0;
  wire  [5:0] m2_g_io_perf_4_value, m2_i_io_perf_4_value;
  logic [5:0] m2_s0_io_perf_4_value = '0, m2_s1_io_perf_4_value = '0;
  wire  [5:0] m2_g_io_perf_5_value, m2_i_io_perf_5_value;
  logic [5:0] m2_s0_io_perf_5_value = '0, m2_s1_io_perf_5_value = '0;
  wire  [5:0] m2_g_io_perf_6_value, m2_i_io_perf_6_value;
  logic [5:0] m2_s0_io_perf_6_value = '0, m2_s1_io_perf_6_value = '0;
  wire  [5:0] m2_g_io_perf_7_value, m2_i_io_perf_7_value;
  logic [5:0] m2_s0_io_perf_7_value = '0, m2_s1_io_perf_7_value = '0;
  int m2_cov_op2_and = 0;
  int m2_cov_op2_xor = 0;
  int m2_cov_op2_add = 0;
  int m2_cov_op2_or = 0;
  int m2_cov_idx_oob = 0;
  int m2_cov_idx_hole = 0;
  logic [0:0] m2_armed = '0;
  int m2_armed_at = -1;
  HPerfMonitor_2 m2_u_gold (
    .clock(clk),
    .io_hpm_event_0(m2_io_hpm_event_0),
    .io_hpm_event_1(m2_io_hpm_event_1),
    .io_hpm_event_2(m2_io_hpm_event_2),
    .io_hpm_event_3(m2_io_hpm_event_3),
    .io_hpm_event_4(m2_io_hpm_event_4),
    .io_hpm_event_5(m2_io_hpm_event_5),
    .io_hpm_event_6(m2_io_hpm_event_6),
    .io_hpm_event_7(m2_io_hpm_event_7),
    .io_events_sets_1_value(m2_io_events_sets_1_value),
    .io_events_sets_2_value(m2_io_events_sets_2_value),
    .io_events_sets_3_value(m2_io_events_sets_3_value),
    .io_events_sets_4_value(m2_io_events_sets_4_value),
    .io_events_sets_5_value(m2_io_events_sets_5_value),
    .io_events_sets_6_value(m2_io_events_sets_6_value),
    .io_events_sets_7_value(m2_io_events_sets_7_value),
    .io_events_sets_8_value(m2_io_events_sets_8_value),
    .io_events_sets_9_value(m2_io_events_sets_9_value),
    .io_events_sets_10_value(m2_io_events_sets_10_value),
    .io_events_sets_11_value(m2_io_events_sets_11_value),
    .io_events_sets_12_value(m2_io_events_sets_12_value),
    .io_events_sets_13_value(m2_io_events_sets_13_value),
    .io_events_sets_14_value(m2_io_events_sets_14_value),
    .io_events_sets_15_value(m2_io_events_sets_15_value),
    .io_events_sets_16_value(m2_io_events_sets_16_value),
    .io_events_sets_17_value(m2_io_events_sets_17_value),
    .io_events_sets_18_value(m2_io_events_sets_18_value),
    .io_events_sets_19_value(m2_io_events_sets_19_value),
    .io_events_sets_20_value(m2_io_events_sets_20_value),
    .io_events_sets_21_value(m2_io_events_sets_21_value),
    .io_events_sets_22_value(m2_io_events_sets_22_value),
    .io_events_sets_23_value(m2_io_events_sets_23_value),
    .io_events_sets_24_value(m2_io_events_sets_24_value),
    .io_events_sets_25_value(m2_io_events_sets_25_value),
    .io_events_sets_26_value(m2_io_events_sets_26_value),
    .io_events_sets_27_value(m2_io_events_sets_27_value),
    .io_events_sets_28_value(m2_io_events_sets_28_value),
    .io_events_sets_29_value(m2_io_events_sets_29_value),
    .io_events_sets_30_value(m2_io_events_sets_30_value),
    .io_events_sets_31_value(m2_io_events_sets_31_value),
    .io_events_sets_32_value(m2_io_events_sets_32_value),
    .io_events_sets_33_value(m2_io_events_sets_33_value),
    .io_events_sets_34_value(m2_io_events_sets_34_value),
    .io_events_sets_35_value(m2_io_events_sets_35_value),
    .io_events_sets_36_value(m2_io_events_sets_36_value),
    .io_events_sets_37_value(m2_io_events_sets_37_value),
    .io_events_sets_38_value(m2_io_events_sets_38_value),
    .io_events_sets_39_value(m2_io_events_sets_39_value),
    .io_events_sets_40_value(m2_io_events_sets_40_value),
    .io_events_sets_41_value(m2_io_events_sets_41_value),
    .io_events_sets_42_value(m2_io_events_sets_42_value),
    .io_events_sets_44_value(m2_io_events_sets_44_value),
    .io_events_sets_45_value(m2_io_events_sets_45_value),
    .io_events_sets_46_value(m2_io_events_sets_46_value),
    .io_events_sets_47_value(m2_io_events_sets_47_value),
    .io_events_sets_48_value(m2_io_events_sets_48_value),
    .io_events_sets_49_value(m2_io_events_sets_49_value),
    .io_events_sets_50_value(m2_io_events_sets_50_value),
    .io_events_sets_51_value(m2_io_events_sets_51_value),
    .io_events_sets_52_value(m2_io_events_sets_52_value),
    .io_events_sets_53_value(m2_io_events_sets_53_value),
    .io_events_sets_54_value(m2_io_events_sets_54_value),
    .io_events_sets_55_value(m2_io_events_sets_55_value),
    .io_events_sets_56_value(m2_io_events_sets_56_value),
    .io_events_sets_57_value(m2_io_events_sets_57_value),
    .io_events_sets_58_value(m2_io_events_sets_58_value),
    .io_events_sets_59_value(m2_io_events_sets_59_value),
    .io_events_sets_60_value(m2_io_events_sets_60_value),
    .io_events_sets_61_value(m2_io_events_sets_61_value),
    .io_events_sets_62_value(m2_io_events_sets_62_value),
    .io_events_sets_63_value(m2_io_events_sets_63_value),
    .io_events_sets_64_value(m2_io_events_sets_64_value),
    .io_events_sets_65_value(m2_io_events_sets_65_value),
    .io_events_sets_66_value(m2_io_events_sets_66_value),
    .io_events_sets_67_value(m2_io_events_sets_67_value),
    .io_events_sets_68_value(m2_io_events_sets_68_value),
    .io_events_sets_69_value(m2_io_events_sets_69_value),
    .io_events_sets_70_value(m2_io_events_sets_70_value),
    .io_events_sets_71_value(m2_io_events_sets_71_value),
    .io_events_sets_72_value(m2_io_events_sets_72_value),
    .io_events_sets_73_value(m2_io_events_sets_73_value),
    .io_events_sets_74_value(m2_io_events_sets_74_value),
    .io_events_sets_75_value(m2_io_events_sets_75_value),
    .io_events_sets_76_value(m2_io_events_sets_76_value),
    .io_events_sets_77_value(m2_io_events_sets_77_value),
    .io_events_sets_78_value(m2_io_events_sets_78_value),
    .io_events_sets_79_value(m2_io_events_sets_79_value),
    .io_events_sets_80_value(m2_io_events_sets_80_value),
    .io_events_sets_81_value(m2_io_events_sets_81_value),
    .io_events_sets_82_value(m2_io_events_sets_82_value),
    .io_events_sets_83_value(m2_io_events_sets_83_value),
    .io_events_sets_84_value(m2_io_events_sets_84_value),
    .io_events_sets_85_value(m2_io_events_sets_85_value),
    .io_events_sets_86_value(m2_io_events_sets_86_value),
    .io_events_sets_87_value(m2_io_events_sets_87_value),
    .io_events_sets_88_value(m2_io_events_sets_88_value),
    .io_events_sets_89_value(m2_io_events_sets_89_value),
    .io_events_sets_90_value(m2_io_events_sets_90_value),
    .io_events_sets_91_value(m2_io_events_sets_91_value),
    .io_events_sets_92_value(m2_io_events_sets_92_value),
    .io_events_sets_93_value(m2_io_events_sets_93_value),
    .io_events_sets_94_value(m2_io_events_sets_94_value),
    .io_events_sets_95_value(m2_io_events_sets_95_value),
    .io_events_sets_97_value(m2_io_events_sets_97_value),
    .io_perf_0_value(m2_g_io_perf_0_value),
    .io_perf_1_value(m2_g_io_perf_1_value),
    .io_perf_2_value(m2_g_io_perf_2_value),
    .io_perf_3_value(m2_g_io_perf_3_value),
    .io_perf_4_value(m2_g_io_perf_4_value),
    .io_perf_5_value(m2_g_io_perf_5_value),
    .io_perf_6_value(m2_g_io_perf_6_value),
    .io_perf_7_value(m2_g_io_perf_7_value)
  );
  HPerfMonitor_2_xs m2_u_impl (
    .clock(clk),
    .io_hpm_event_0(m2_io_hpm_event_0),
    .io_hpm_event_1(m2_io_hpm_event_1),
    .io_hpm_event_2(m2_io_hpm_event_2),
    .io_hpm_event_3(m2_io_hpm_event_3),
    .io_hpm_event_4(m2_io_hpm_event_4),
    .io_hpm_event_5(m2_io_hpm_event_5),
    .io_hpm_event_6(m2_io_hpm_event_6),
    .io_hpm_event_7(m2_io_hpm_event_7),
    .io_events_sets_1_value(m2_io_events_sets_1_value),
    .io_events_sets_2_value(m2_io_events_sets_2_value),
    .io_events_sets_3_value(m2_io_events_sets_3_value),
    .io_events_sets_4_value(m2_io_events_sets_4_value),
    .io_events_sets_5_value(m2_io_events_sets_5_value),
    .io_events_sets_6_value(m2_io_events_sets_6_value),
    .io_events_sets_7_value(m2_io_events_sets_7_value),
    .io_events_sets_8_value(m2_io_events_sets_8_value),
    .io_events_sets_9_value(m2_io_events_sets_9_value),
    .io_events_sets_10_value(m2_io_events_sets_10_value),
    .io_events_sets_11_value(m2_io_events_sets_11_value),
    .io_events_sets_12_value(m2_io_events_sets_12_value),
    .io_events_sets_13_value(m2_io_events_sets_13_value),
    .io_events_sets_14_value(m2_io_events_sets_14_value),
    .io_events_sets_15_value(m2_io_events_sets_15_value),
    .io_events_sets_16_value(m2_io_events_sets_16_value),
    .io_events_sets_17_value(m2_io_events_sets_17_value),
    .io_events_sets_18_value(m2_io_events_sets_18_value),
    .io_events_sets_19_value(m2_io_events_sets_19_value),
    .io_events_sets_20_value(m2_io_events_sets_20_value),
    .io_events_sets_21_value(m2_io_events_sets_21_value),
    .io_events_sets_22_value(m2_io_events_sets_22_value),
    .io_events_sets_23_value(m2_io_events_sets_23_value),
    .io_events_sets_24_value(m2_io_events_sets_24_value),
    .io_events_sets_25_value(m2_io_events_sets_25_value),
    .io_events_sets_26_value(m2_io_events_sets_26_value),
    .io_events_sets_27_value(m2_io_events_sets_27_value),
    .io_events_sets_28_value(m2_io_events_sets_28_value),
    .io_events_sets_29_value(m2_io_events_sets_29_value),
    .io_events_sets_30_value(m2_io_events_sets_30_value),
    .io_events_sets_31_value(m2_io_events_sets_31_value),
    .io_events_sets_32_value(m2_io_events_sets_32_value),
    .io_events_sets_33_value(m2_io_events_sets_33_value),
    .io_events_sets_34_value(m2_io_events_sets_34_value),
    .io_events_sets_35_value(m2_io_events_sets_35_value),
    .io_events_sets_36_value(m2_io_events_sets_36_value),
    .io_events_sets_37_value(m2_io_events_sets_37_value),
    .io_events_sets_38_value(m2_io_events_sets_38_value),
    .io_events_sets_39_value(m2_io_events_sets_39_value),
    .io_events_sets_40_value(m2_io_events_sets_40_value),
    .io_events_sets_41_value(m2_io_events_sets_41_value),
    .io_events_sets_42_value(m2_io_events_sets_42_value),
    .io_events_sets_44_value(m2_io_events_sets_44_value),
    .io_events_sets_45_value(m2_io_events_sets_45_value),
    .io_events_sets_46_value(m2_io_events_sets_46_value),
    .io_events_sets_47_value(m2_io_events_sets_47_value),
    .io_events_sets_48_value(m2_io_events_sets_48_value),
    .io_events_sets_49_value(m2_io_events_sets_49_value),
    .io_events_sets_50_value(m2_io_events_sets_50_value),
    .io_events_sets_51_value(m2_io_events_sets_51_value),
    .io_events_sets_52_value(m2_io_events_sets_52_value),
    .io_events_sets_53_value(m2_io_events_sets_53_value),
    .io_events_sets_54_value(m2_io_events_sets_54_value),
    .io_events_sets_55_value(m2_io_events_sets_55_value),
    .io_events_sets_56_value(m2_io_events_sets_56_value),
    .io_events_sets_57_value(m2_io_events_sets_57_value),
    .io_events_sets_58_value(m2_io_events_sets_58_value),
    .io_events_sets_59_value(m2_io_events_sets_59_value),
    .io_events_sets_60_value(m2_io_events_sets_60_value),
    .io_events_sets_61_value(m2_io_events_sets_61_value),
    .io_events_sets_62_value(m2_io_events_sets_62_value),
    .io_events_sets_63_value(m2_io_events_sets_63_value),
    .io_events_sets_64_value(m2_io_events_sets_64_value),
    .io_events_sets_65_value(m2_io_events_sets_65_value),
    .io_events_sets_66_value(m2_io_events_sets_66_value),
    .io_events_sets_67_value(m2_io_events_sets_67_value),
    .io_events_sets_68_value(m2_io_events_sets_68_value),
    .io_events_sets_69_value(m2_io_events_sets_69_value),
    .io_events_sets_70_value(m2_io_events_sets_70_value),
    .io_events_sets_71_value(m2_io_events_sets_71_value),
    .io_events_sets_72_value(m2_io_events_sets_72_value),
    .io_events_sets_73_value(m2_io_events_sets_73_value),
    .io_events_sets_74_value(m2_io_events_sets_74_value),
    .io_events_sets_75_value(m2_io_events_sets_75_value),
    .io_events_sets_76_value(m2_io_events_sets_76_value),
    .io_events_sets_77_value(m2_io_events_sets_77_value),
    .io_events_sets_78_value(m2_io_events_sets_78_value),
    .io_events_sets_79_value(m2_io_events_sets_79_value),
    .io_events_sets_80_value(m2_io_events_sets_80_value),
    .io_events_sets_81_value(m2_io_events_sets_81_value),
    .io_events_sets_82_value(m2_io_events_sets_82_value),
    .io_events_sets_83_value(m2_io_events_sets_83_value),
    .io_events_sets_84_value(m2_io_events_sets_84_value),
    .io_events_sets_85_value(m2_io_events_sets_85_value),
    .io_events_sets_86_value(m2_io_events_sets_86_value),
    .io_events_sets_87_value(m2_io_events_sets_87_value),
    .io_events_sets_88_value(m2_io_events_sets_88_value),
    .io_events_sets_89_value(m2_io_events_sets_89_value),
    .io_events_sets_90_value(m2_io_events_sets_90_value),
    .io_events_sets_91_value(m2_io_events_sets_91_value),
    .io_events_sets_92_value(m2_io_events_sets_92_value),
    .io_events_sets_93_value(m2_io_events_sets_93_value),
    .io_events_sets_94_value(m2_io_events_sets_94_value),
    .io_events_sets_95_value(m2_io_events_sets_95_value),
    .io_events_sets_97_value(m2_io_events_sets_97_value),
    .io_perf_0_value(m2_i_io_perf_0_value),
    .io_perf_1_value(m2_i_io_perf_1_value),
    .io_perf_2_value(m2_i_io_perf_2_value),
    .io_perf_3_value(m2_i_io_perf_3_value),
    .io_perf_4_value(m2_i_io_perf_4_value),
    .io_perf_5_value(m2_i_io_perf_5_value),
    .io_perf_6_value(m2_i_io_perf_6_value),
    .io_perf_7_value(m2_i_io_perf_7_value)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) m0_mode = $urandom_range(0, 15);
      m0_io_hpm_event_0 = 64'({$urandom, $urandom});
      m0_io_hpm_event_1 = 64'({$urandom, $urandom});
      m0_io_hpm_event_2 = 64'({$urandom, $urandom});
      m0_io_hpm_event_3 = 64'({$urandom, $urandom});
      m0_io_hpm_event_4 = 64'({$urandom, $urandom});
      m0_io_hpm_event_5 = 64'({$urandom, $urandom});
      m0_io_hpm_event_6 = 64'({$urandom, $urandom});
      m0_io_hpm_event_7 = 64'({$urandom, $urandom});
      m0_io_events_sets_1_value = 6'($urandom);
      m0_io_events_sets_2_value = 6'($urandom);
      m0_io_events_sets_3_value = 6'($urandom);
      m0_io_events_sets_4_value = 6'($urandom);
      m0_io_events_sets_5_value = 6'($urandom);
      m0_io_events_sets_6_value = 6'($urandom);
      m0_io_events_sets_7_value = 6'($urandom);
      m0_io_events_sets_8_value = 6'($urandom);
      m0_io_events_sets_9_value = 6'($urandom);
      m0_io_events_sets_10_value = 6'($urandom);
      m0_io_events_sets_11_value = 6'($urandom);
      m0_io_events_sets_12_value = 6'($urandom);
      m0_io_events_sets_13_value = 6'($urandom);
      m0_io_events_sets_14_value = 6'($urandom);
      m0_io_events_sets_15_value = 6'($urandom);
      m0_io_events_sets_16_value = 6'($urandom);
      m0_io_events_sets_17_value = 6'($urandom);
      m0_io_events_sets_18_value = 6'($urandom);
      m0_io_events_sets_19_value = 6'($urandom);
      m0_io_events_sets_20_value = 6'($urandom);
      m0_io_events_sets_21_value = 6'($urandom);
      m0_io_events_sets_22_value = 6'($urandom);
      m0_io_events_sets_23_value = 6'($urandom);
      m0_io_events_sets_25_value = 6'($urandom);
      m0_io_events_sets_26_value = 6'($urandom);
      m0_io_events_sets_27_value = 6'($urandom);
      m0_io_events_sets_28_value = 6'($urandom);
      m0_io_events_sets_29_value = 6'($urandom);
      m0_io_events_sets_30_value = 6'($urandom);
      m0_io_events_sets_31_value = 6'($urandom);
      m0_io_events_sets_32_value = 6'($urandom);
      m0_io_events_sets_33_value = 6'($urandom);
      m0_io_events_sets_34_value = 6'($urandom);
      m0_io_events_sets_35_value = 6'($urandom);
      m0_io_events_sets_36_value = 6'($urandom);
      m0_io_events_sets_37_value = 6'($urandom);
      m0_io_events_sets_38_value = 6'($urandom);
      m0_io_events_sets_39_value = 6'($urandom);
      m0_io_events_sets_40_value = 6'($urandom);
      m0_io_events_sets_41_value = 6'($urandom);
      m0_io_events_sets_42_value = 6'($urandom);
      m0_io_events_sets_43_value = 6'($urandom);
      m0_io_events_sets_44_value = 6'($urandom);
      m0_io_events_sets_45_value = 6'($urandom);
      m0_io_events_sets_46_value = 6'($urandom);
      m0_io_events_sets_47_value = 6'($urandom);
      m0_io_events_sets_48_value = 6'($urandom);
      m0_io_events_sets_49_value = 6'($urandom);
      m0_io_events_sets_50_value = 6'($urandom);
      m0_io_events_sets_51_value = 6'($urandom);
      m0_io_events_sets_52_value = 6'($urandom);
      m0_io_events_sets_53_value = 6'($urandom);
      m0_io_events_sets_54_value = 6'($urandom);
      m0_io_events_sets_55_value = 6'($urandom);
      m0_io_events_sets_56_value = 6'($urandom);
      m0_io_events_sets_57_value = 6'($urandom);
      begin : stim_m0
        for (int k = 0; k < 4; k++)
          case ($urandom_range(0, 3))
            0, 1: begin
              int pick [$] = '{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57};
              m0_io_hpm_event_0[10*k +: 10] = 10'(pick[$urandom_range(0, pick.size() - 1)]);
            end
            2: begin
              int hole [$] = '{0, 24};
              m0_io_hpm_event_0[10*k +: 10] = ($urandom_range(0, 1) == 0) ? 10'(58 + $urandom_range(0, 5))
                                                                          : 10'(hole[$urandom_range(0, hole.size() - 1)]);
            end
            default: ;
          endcase
        for (int f = 40; f <= 50; f += 5)
          if ($urandom_range(0, 1) == 0) begin
            case ($urandom_range(0, 3))
              0: m0_io_hpm_event_0[f +: 5] = 5'd0;
              1: m0_io_hpm_event_0[f +: 5] = 5'd1;
              2: m0_io_hpm_event_0[f +: 5] = 5'd2;
              default: m0_io_hpm_event_0[f +: 5] = 5'd4;
            endcase
          end
        for (int k = 0; k < 4; k++)
          case ($urandom_range(0, 3))
            0, 1: begin
              int pick [$] = '{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57};
              m0_io_hpm_event_1[10*k +: 10] = 10'(pick[$urandom_range(0, pick.size() - 1)]);
            end
            2: begin
              int hole [$] = '{0, 24};
              m0_io_hpm_event_1[10*k +: 10] = ($urandom_range(0, 1) == 0) ? 10'(58 + $urandom_range(0, 5))
                                                                          : 10'(hole[$urandom_range(0, hole.size() - 1)]);
            end
            default: ;
          endcase
        for (int f = 40; f <= 50; f += 5)
          if ($urandom_range(0, 1) == 0) begin
            case ($urandom_range(0, 3))
              0: m0_io_hpm_event_1[f +: 5] = 5'd0;
              1: m0_io_hpm_event_1[f +: 5] = 5'd1;
              2: m0_io_hpm_event_1[f +: 5] = 5'd2;
              default: m0_io_hpm_event_1[f +: 5] = 5'd4;
            endcase
          end
        for (int k = 0; k < 4; k++)
          case ($urandom_range(0, 3))
            0, 1: begin
              int pick [$] = '{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57};
              m0_io_hpm_event_2[10*k +: 10] = 10'(pick[$urandom_range(0, pick.size() - 1)]);
            end
            2: begin
              int hole [$] = '{0, 24};
              m0_io_hpm_event_2[10*k +: 10] = ($urandom_range(0, 1) == 0) ? 10'(58 + $urandom_range(0, 5))
                                                                          : 10'(hole[$urandom_range(0, hole.size() - 1)]);
            end
            default: ;
          endcase
        for (int f = 40; f <= 50; f += 5)
          if ($urandom_range(0, 1) == 0) begin
            case ($urandom_range(0, 3))
              0: m0_io_hpm_event_2[f +: 5] = 5'd0;
              1: m0_io_hpm_event_2[f +: 5] = 5'd1;
              2: m0_io_hpm_event_2[f +: 5] = 5'd2;
              default: m0_io_hpm_event_2[f +: 5] = 5'd4;
            endcase
          end
        for (int k = 0; k < 4; k++)
          case ($urandom_range(0, 3))
            0, 1: begin
              int pick [$] = '{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57};
              m0_io_hpm_event_3[10*k +: 10] = 10'(pick[$urandom_range(0, pick.size() - 1)]);
            end
            2: begin
              int hole [$] = '{0, 24};
              m0_io_hpm_event_3[10*k +: 10] = ($urandom_range(0, 1) == 0) ? 10'(58 + $urandom_range(0, 5))
                                                                          : 10'(hole[$urandom_range(0, hole.size() - 1)]);
            end
            default: ;
          endcase
        for (int f = 40; f <= 50; f += 5)
          if ($urandom_range(0, 1) == 0) begin
            case ($urandom_range(0, 3))
              0: m0_io_hpm_event_3[f +: 5] = 5'd0;
              1: m0_io_hpm_event_3[f +: 5] = 5'd1;
              2: m0_io_hpm_event_3[f +: 5] = 5'd2;
              default: m0_io_hpm_event_3[f +: 5] = 5'd4;
            endcase
          end
        for (int k = 0; k < 4; k++)
          case ($urandom_range(0, 3))
            0, 1: begin
              int pick [$] = '{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57};
              m0_io_hpm_event_4[10*k +: 10] = 10'(pick[$urandom_range(0, pick.size() - 1)]);
            end
            2: begin
              int hole [$] = '{0, 24};
              m0_io_hpm_event_4[10*k +: 10] = ($urandom_range(0, 1) == 0) ? 10'(58 + $urandom_range(0, 5))
                                                                          : 10'(hole[$urandom_range(0, hole.size() - 1)]);
            end
            default: ;
          endcase
        for (int f = 40; f <= 50; f += 5)
          if ($urandom_range(0, 1) == 0) begin
            case ($urandom_range(0, 3))
              0: m0_io_hpm_event_4[f +: 5] = 5'd0;
              1: m0_io_hpm_event_4[f +: 5] = 5'd1;
              2: m0_io_hpm_event_4[f +: 5] = 5'd2;
              default: m0_io_hpm_event_4[f +: 5] = 5'd4;
            endcase
          end
        for (int k = 0; k < 4; k++)
          case ($urandom_range(0, 3))
            0, 1: begin
              int pick [$] = '{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57};
              m0_io_hpm_event_5[10*k +: 10] = 10'(pick[$urandom_range(0, pick.size() - 1)]);
            end
            2: begin
              int hole [$] = '{0, 24};
              m0_io_hpm_event_5[10*k +: 10] = ($urandom_range(0, 1) == 0) ? 10'(58 + $urandom_range(0, 5))
                                                                          : 10'(hole[$urandom_range(0, hole.size() - 1)]);
            end
            default: ;
          endcase
        for (int f = 40; f <= 50; f += 5)
          if ($urandom_range(0, 1) == 0) begin
            case ($urandom_range(0, 3))
              0: m0_io_hpm_event_5[f +: 5] = 5'd0;
              1: m0_io_hpm_event_5[f +: 5] = 5'd1;
              2: m0_io_hpm_event_5[f +: 5] = 5'd2;
              default: m0_io_hpm_event_5[f +: 5] = 5'd4;
            endcase
          end
        for (int k = 0; k < 4; k++)
          case ($urandom_range(0, 3))
            0, 1: begin
              int pick [$] = '{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57};
              m0_io_hpm_event_6[10*k +: 10] = 10'(pick[$urandom_range(0, pick.size() - 1)]);
            end
            2: begin
              int hole [$] = '{0, 24};
              m0_io_hpm_event_6[10*k +: 10] = ($urandom_range(0, 1) == 0) ? 10'(58 + $urandom_range(0, 5))
                                                                          : 10'(hole[$urandom_range(0, hole.size() - 1)]);
            end
            default: ;
          endcase
        for (int f = 40; f <= 50; f += 5)
          if ($urandom_range(0, 1) == 0) begin
            case ($urandom_range(0, 3))
              0: m0_io_hpm_event_6[f +: 5] = 5'd0;
              1: m0_io_hpm_event_6[f +: 5] = 5'd1;
              2: m0_io_hpm_event_6[f +: 5] = 5'd2;
              default: m0_io_hpm_event_6[f +: 5] = 5'd4;
            endcase
          end
        for (int k = 0; k < 4; k++)
          case ($urandom_range(0, 3))
            0, 1: begin
              int pick [$] = '{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57};
              m0_io_hpm_event_7[10*k +: 10] = 10'(pick[$urandom_range(0, pick.size() - 1)]);
            end
            2: begin
              int hole [$] = '{0, 24};
              m0_io_hpm_event_7[10*k +: 10] = ($urandom_range(0, 1) == 0) ? 10'(58 + $urandom_range(0, 5))
                                                                          : 10'(hole[$urandom_range(0, hole.size() - 1)]);
            end
            default: ;
          endcase
        for (int f = 40; f <= 50; f += 5)
          if ($urandom_range(0, 1) == 0) begin
            case ($urandom_range(0, 3))
              0: m0_io_hpm_event_7[f +: 5] = 5'd0;
              1: m0_io_hpm_event_7[f +: 5] = 5'd1;
              2: m0_io_hpm_event_7[f +: 5] = 5'd2;
              default: m0_io_hpm_event_7[f +: 5] = 5'd4;
            endcase
          end
      end
      if (cyc % 4000 == 0) m1_mode = $urandom_range(0, 15);
      m1_io_hpm_event_0 = 64'({$urandom, $urandom});
      m1_io_hpm_event_1 = 64'({$urandom, $urandom});
      m1_io_hpm_event_2 = 64'({$urandom, $urandom});
      m1_io_hpm_event_3 = 64'({$urandom, $urandom});
      m1_io_hpm_event_4 = 64'({$urandom, $urandom});
      m1_io_events_sets_0_value = 6'($urandom);
      m1_io_events_sets_1_value = 6'($urandom);
      m1_io_events_sets_2_value = 6'($urandom);
      m1_io_events_sets_3_value = 6'($urandom);
      m1_io_events_sets_4_value = 6'($urandom);
      m1_io_events_sets_5_value = 6'($urandom);
      m1_io_events_sets_6_value = 6'($urandom);
      m1_io_events_sets_7_value = 6'($urandom);
      m1_io_events_sets_8_value = 6'($urandom);
      m1_io_events_sets_9_value = 6'($urandom);
      m1_io_events_sets_10_value = 6'($urandom);
      m1_io_events_sets_11_value = 6'($urandom);
      m1_io_events_sets_12_value = 6'($urandom);
      m1_io_events_sets_13_value = 6'($urandom);
      m1_io_events_sets_14_value = 6'($urandom);
      m1_io_events_sets_15_value = 6'($urandom);
      m1_io_events_sets_16_value = 6'($urandom);
      m1_io_events_sets_17_value = 6'($urandom);
      m1_io_events_sets_18_value = 6'($urandom);
      m1_io_events_sets_19_value = 6'($urandom);
      m1_io_events_sets_20_value = 6'($urandom);
      m1_io_events_sets_21_value = 6'($urandom);
      m1_io_events_sets_22_value = 6'($urandom);
      m1_io_events_sets_23_value = 6'($urandom);
      m1_io_events_sets_24_value = 6'($urandom);
      m1_io_events_sets_25_value = 6'($urandom);
      m1_io_events_sets_26_value = 6'($urandom);
      m1_io_events_sets_27_value = 6'($urandom);
      m1_io_events_sets_28_value = 6'($urandom);
      m1_io_events_sets_29_value = 6'($urandom);
      m1_io_events_sets_30_value = 6'($urandom);
      m1_io_events_sets_31_value = 6'($urandom);
      m1_io_events_sets_32_value = 6'($urandom);
      m1_io_events_sets_33_value = 6'($urandom);
      m1_io_events_sets_34_value = 6'($urandom);
      m1_io_events_sets_35_value = 6'($urandom);
      m1_io_events_sets_36_value = 6'($urandom);
      m1_io_events_sets_37_value = 6'($urandom);
      m1_io_events_sets_38_value = 6'($urandom);
      m1_io_events_sets_39_value = 6'($urandom);
      m1_io_events_sets_40_value = 6'($urandom);
      m1_io_events_sets_41_value = 6'($urandom);
      m1_io_events_sets_42_value = 6'($urandom);
      m1_io_events_sets_43_value = 6'($urandom);
      m1_io_events_sets_44_value = 6'($urandom);
      m1_io_events_sets_45_value = 6'($urandom);
      m1_io_events_sets_46_value = 6'($urandom);
      m1_io_events_sets_47_value = 6'($urandom);
      m1_io_events_sets_48_value = 6'($urandom);
      m1_io_events_sets_49_value = 6'($urandom);
      m1_io_events_sets_50_value = 6'($urandom);
      m1_io_events_sets_51_value = 6'($urandom);
      m1_io_events_sets_52_value = 6'($urandom);
      m1_io_events_sets_53_value = 6'($urandom);
      m1_io_events_sets_54_value = 6'($urandom);
      m1_io_events_sets_55_value = 6'($urandom);
      m1_io_events_sets_56_value = 6'($urandom);
      m1_io_events_sets_57_value = 6'($urandom);
      m1_io_events_sets_58_value = 6'($urandom);
      m1_io_events_sets_59_value = 6'($urandom);
      m1_io_events_sets_60_value = 6'($urandom);
      m1_io_events_sets_61_value = 6'($urandom);
      m1_io_events_sets_62_value = 6'($urandom);
      m1_io_events_sets_63_value = 6'($urandom);
      m1_io_events_sets_64_value = 6'($urandom);
      m1_io_events_sets_65_value = 6'($urandom);
      m1_io_events_sets_66_value = 6'($urandom);
      m1_io_events_sets_67_value = 6'($urandom);
      begin : stim_m1
        for (int k = 0; k < 4; k++)
          case ($urandom_range(0, 3))
            0, 1: begin
              int pick [$] = '{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67};
              m1_io_hpm_event_0[10*k +: 10] = 10'(pick[$urandom_range(0, pick.size() - 1)]);
            end
            2: begin
              int hole [$] = '{68};
              m1_io_hpm_event_0[10*k +: 10] = ($urandom_range(0, 1) == 0) ? 10'(68 + $urandom_range(0, 59))
                                                                          : 10'(hole[$urandom_range(0, hole.size() - 1)]);
            end
            default: ;
          endcase
        for (int f = 40; f <= 50; f += 5)
          if ($urandom_range(0, 1) == 0) begin
            case ($urandom_range(0, 3))
              0: m1_io_hpm_event_0[f +: 5] = 5'd0;
              1: m1_io_hpm_event_0[f +: 5] = 5'd1;
              2: m1_io_hpm_event_0[f +: 5] = 5'd2;
              default: m1_io_hpm_event_0[f +: 5] = 5'd4;
            endcase
          end
        for (int k = 0; k < 4; k++)
          case ($urandom_range(0, 3))
            0, 1: begin
              int pick [$] = '{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67};
              m1_io_hpm_event_1[10*k +: 10] = 10'(pick[$urandom_range(0, pick.size() - 1)]);
            end
            2: begin
              int hole [$] = '{68};
              m1_io_hpm_event_1[10*k +: 10] = ($urandom_range(0, 1) == 0) ? 10'(68 + $urandom_range(0, 59))
                                                                          : 10'(hole[$urandom_range(0, hole.size() - 1)]);
            end
            default: ;
          endcase
        for (int f = 40; f <= 50; f += 5)
          if ($urandom_range(0, 1) == 0) begin
            case ($urandom_range(0, 3))
              0: m1_io_hpm_event_1[f +: 5] = 5'd0;
              1: m1_io_hpm_event_1[f +: 5] = 5'd1;
              2: m1_io_hpm_event_1[f +: 5] = 5'd2;
              default: m1_io_hpm_event_1[f +: 5] = 5'd4;
            endcase
          end
        for (int k = 0; k < 4; k++)
          case ($urandom_range(0, 3))
            0, 1: begin
              int pick [$] = '{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67};
              m1_io_hpm_event_2[10*k +: 10] = 10'(pick[$urandom_range(0, pick.size() - 1)]);
            end
            2: begin
              int hole [$] = '{68};
              m1_io_hpm_event_2[10*k +: 10] = ($urandom_range(0, 1) == 0) ? 10'(68 + $urandom_range(0, 59))
                                                                          : 10'(hole[$urandom_range(0, hole.size() - 1)]);
            end
            default: ;
          endcase
        for (int f = 40; f <= 50; f += 5)
          if ($urandom_range(0, 1) == 0) begin
            case ($urandom_range(0, 3))
              0: m1_io_hpm_event_2[f +: 5] = 5'd0;
              1: m1_io_hpm_event_2[f +: 5] = 5'd1;
              2: m1_io_hpm_event_2[f +: 5] = 5'd2;
              default: m1_io_hpm_event_2[f +: 5] = 5'd4;
            endcase
          end
        for (int k = 0; k < 4; k++)
          case ($urandom_range(0, 3))
            0, 1: begin
              int pick [$] = '{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67};
              m1_io_hpm_event_3[10*k +: 10] = 10'(pick[$urandom_range(0, pick.size() - 1)]);
            end
            2: begin
              int hole [$] = '{68};
              m1_io_hpm_event_3[10*k +: 10] = ($urandom_range(0, 1) == 0) ? 10'(68 + $urandom_range(0, 59))
                                                                          : 10'(hole[$urandom_range(0, hole.size() - 1)]);
            end
            default: ;
          endcase
        for (int f = 40; f <= 50; f += 5)
          if ($urandom_range(0, 1) == 0) begin
            case ($urandom_range(0, 3))
              0: m1_io_hpm_event_3[f +: 5] = 5'd0;
              1: m1_io_hpm_event_3[f +: 5] = 5'd1;
              2: m1_io_hpm_event_3[f +: 5] = 5'd2;
              default: m1_io_hpm_event_3[f +: 5] = 5'd4;
            endcase
          end
        for (int k = 0; k < 4; k++)
          case ($urandom_range(0, 3))
            0, 1: begin
              int pick [$] = '{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67};
              m1_io_hpm_event_4[10*k +: 10] = 10'(pick[$urandom_range(0, pick.size() - 1)]);
            end
            2: begin
              int hole [$] = '{68};
              m1_io_hpm_event_4[10*k +: 10] = ($urandom_range(0, 1) == 0) ? 10'(68 + $urandom_range(0, 59))
                                                                          : 10'(hole[$urandom_range(0, hole.size() - 1)]);
            end
            default: ;
          endcase
        for (int f = 40; f <= 50; f += 5)
          if ($urandom_range(0, 1) == 0) begin
            case ($urandom_range(0, 3))
              0: m1_io_hpm_event_4[f +: 5] = 5'd0;
              1: m1_io_hpm_event_4[f +: 5] = 5'd1;
              2: m1_io_hpm_event_4[f +: 5] = 5'd2;
              default: m1_io_hpm_event_4[f +: 5] = 5'd4;
            endcase
          end
      end
      if (cyc % 4000 == 0) m2_mode = $urandom_range(0, 15);
      m2_io_hpm_event_0 = 64'({$urandom, $urandom});
      m2_io_hpm_event_1 = 64'({$urandom, $urandom});
      m2_io_hpm_event_2 = 64'({$urandom, $urandom});
      m2_io_hpm_event_3 = 64'({$urandom, $urandom});
      m2_io_hpm_event_4 = 64'({$urandom, $urandom});
      m2_io_hpm_event_5 = 64'({$urandom, $urandom});
      m2_io_hpm_event_6 = 64'({$urandom, $urandom});
      m2_io_hpm_event_7 = 64'({$urandom, $urandom});
      m2_io_events_sets_1_value = 6'($urandom);
      m2_io_events_sets_2_value = 6'($urandom);
      m2_io_events_sets_3_value = 6'($urandom);
      m2_io_events_sets_4_value = 6'($urandom);
      m2_io_events_sets_5_value = 6'($urandom);
      m2_io_events_sets_6_value = 6'($urandom);
      m2_io_events_sets_7_value = 6'($urandom);
      m2_io_events_sets_8_value = 6'($urandom);
      m2_io_events_sets_9_value = 6'($urandom);
      m2_io_events_sets_10_value = 6'($urandom);
      m2_io_events_sets_11_value = 6'($urandom);
      m2_io_events_sets_12_value = 6'($urandom);
      m2_io_events_sets_13_value = 6'($urandom);
      m2_io_events_sets_14_value = 6'($urandom);
      m2_io_events_sets_15_value = 6'($urandom);
      m2_io_events_sets_16_value = 6'($urandom);
      m2_io_events_sets_17_value = 6'($urandom);
      m2_io_events_sets_18_value = 6'($urandom);
      m2_io_events_sets_19_value = 6'($urandom);
      m2_io_events_sets_20_value = 6'($urandom);
      m2_io_events_sets_21_value = 6'($urandom);
      m2_io_events_sets_22_value = 6'($urandom);
      m2_io_events_sets_23_value = 6'($urandom);
      m2_io_events_sets_24_value = 6'($urandom);
      m2_io_events_sets_25_value = 6'($urandom);
      m2_io_events_sets_26_value = 6'($urandom);
      m2_io_events_sets_27_value = 6'($urandom);
      m2_io_events_sets_28_value = 6'($urandom);
      m2_io_events_sets_29_value = 6'($urandom);
      m2_io_events_sets_30_value = 6'($urandom);
      m2_io_events_sets_31_value = 6'($urandom);
      m2_io_events_sets_32_value = 6'($urandom);
      m2_io_events_sets_33_value = 6'($urandom);
      m2_io_events_sets_34_value = 6'($urandom);
      m2_io_events_sets_35_value = 6'($urandom);
      m2_io_events_sets_36_value = 6'($urandom);
      m2_io_events_sets_37_value = 6'($urandom);
      m2_io_events_sets_38_value = 6'($urandom);
      m2_io_events_sets_39_value = 6'($urandom);
      m2_io_events_sets_40_value = 6'($urandom);
      m2_io_events_sets_41_value = 6'($urandom);
      m2_io_events_sets_42_value = 6'($urandom);
      m2_io_events_sets_44_value = 6'($urandom);
      m2_io_events_sets_45_value = 6'($urandom);
      m2_io_events_sets_46_value = 6'($urandom);
      m2_io_events_sets_47_value = 6'($urandom);
      m2_io_events_sets_48_value = 6'($urandom);
      m2_io_events_sets_49_value = 6'($urandom);
      m2_io_events_sets_50_value = 6'($urandom);
      m2_io_events_sets_51_value = 6'($urandom);
      m2_io_events_sets_52_value = 6'($urandom);
      m2_io_events_sets_53_value = 6'($urandom);
      m2_io_events_sets_54_value = 6'($urandom);
      m2_io_events_sets_55_value = 6'($urandom);
      m2_io_events_sets_56_value = 6'($urandom);
      m2_io_events_sets_57_value = 6'($urandom);
      m2_io_events_sets_58_value = 6'($urandom);
      m2_io_events_sets_59_value = 6'($urandom);
      m2_io_events_sets_60_value = 6'($urandom);
      m2_io_events_sets_61_value = 6'($urandom);
      m2_io_events_sets_62_value = 6'($urandom);
      m2_io_events_sets_63_value = 6'($urandom);
      m2_io_events_sets_64_value = 6'($urandom);
      m2_io_events_sets_65_value = 6'($urandom);
      m2_io_events_sets_66_value = 6'($urandom);
      m2_io_events_sets_67_value = 6'($urandom);
      m2_io_events_sets_68_value = 6'($urandom);
      m2_io_events_sets_69_value = 6'($urandom);
      m2_io_events_sets_70_value = 6'($urandom);
      m2_io_events_sets_71_value = 6'($urandom);
      m2_io_events_sets_72_value = 6'($urandom);
      m2_io_events_sets_73_value = 6'($urandom);
      m2_io_events_sets_74_value = 6'($urandom);
      m2_io_events_sets_75_value = 6'($urandom);
      m2_io_events_sets_76_value = 6'($urandom);
      m2_io_events_sets_77_value = 6'($urandom);
      m2_io_events_sets_78_value = 6'($urandom);
      m2_io_events_sets_79_value = 6'($urandom);
      m2_io_events_sets_80_value = 6'($urandom);
      m2_io_events_sets_81_value = 6'($urandom);
      m2_io_events_sets_82_value = 6'($urandom);
      m2_io_events_sets_83_value = 6'($urandom);
      m2_io_events_sets_84_value = 6'($urandom);
      m2_io_events_sets_85_value = 6'($urandom);
      m2_io_events_sets_86_value = 6'($urandom);
      m2_io_events_sets_87_value = 6'($urandom);
      m2_io_events_sets_88_value = 6'($urandom);
      m2_io_events_sets_89_value = 6'($urandom);
      m2_io_events_sets_90_value = 6'($urandom);
      m2_io_events_sets_91_value = 6'($urandom);
      m2_io_events_sets_92_value = 6'($urandom);
      m2_io_events_sets_93_value = 6'($urandom);
      m2_io_events_sets_94_value = 6'($urandom);
      m2_io_events_sets_95_value = 6'($urandom);
      m2_io_events_sets_97_value = 6'($urandom);
      begin : stim_m2
        for (int k = 0; k < 4; k++)
          case ($urandom_range(0, 3))
            0, 1: begin
              int pick [$] = '{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 97};
              m2_io_hpm_event_0[10*k +: 10] = 10'(pick[$urandom_range(0, pick.size() - 1)]);
            end
            2: begin
              int hole [$] = '{0, 43, 96};
              m2_io_hpm_event_0[10*k +: 10] = ($urandom_range(0, 1) == 0) ? 10'(98 + $urandom_range(0, 29))
                                                                          : 10'(hole[$urandom_range(0, hole.size() - 1)]);
            end
            default: ;
          endcase
        for (int f = 40; f <= 50; f += 5)
          if ($urandom_range(0, 1) == 0) begin
            case ($urandom_range(0, 3))
              0: m2_io_hpm_event_0[f +: 5] = 5'd0;
              1: m2_io_hpm_event_0[f +: 5] = 5'd1;
              2: m2_io_hpm_event_0[f +: 5] = 5'd2;
              default: m2_io_hpm_event_0[f +: 5] = 5'd4;
            endcase
          end
        for (int k = 0; k < 4; k++)
          case ($urandom_range(0, 3))
            0, 1: begin
              int pick [$] = '{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 97};
              m2_io_hpm_event_1[10*k +: 10] = 10'(pick[$urandom_range(0, pick.size() - 1)]);
            end
            2: begin
              int hole [$] = '{0, 43, 96};
              m2_io_hpm_event_1[10*k +: 10] = ($urandom_range(0, 1) == 0) ? 10'(98 + $urandom_range(0, 29))
                                                                          : 10'(hole[$urandom_range(0, hole.size() - 1)]);
            end
            default: ;
          endcase
        for (int f = 40; f <= 50; f += 5)
          if ($urandom_range(0, 1) == 0) begin
            case ($urandom_range(0, 3))
              0: m2_io_hpm_event_1[f +: 5] = 5'd0;
              1: m2_io_hpm_event_1[f +: 5] = 5'd1;
              2: m2_io_hpm_event_1[f +: 5] = 5'd2;
              default: m2_io_hpm_event_1[f +: 5] = 5'd4;
            endcase
          end
        for (int k = 0; k < 4; k++)
          case ($urandom_range(0, 3))
            0, 1: begin
              int pick [$] = '{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 97};
              m2_io_hpm_event_2[10*k +: 10] = 10'(pick[$urandom_range(0, pick.size() - 1)]);
            end
            2: begin
              int hole [$] = '{0, 43, 96};
              m2_io_hpm_event_2[10*k +: 10] = ($urandom_range(0, 1) == 0) ? 10'(98 + $urandom_range(0, 29))
                                                                          : 10'(hole[$urandom_range(0, hole.size() - 1)]);
            end
            default: ;
          endcase
        for (int f = 40; f <= 50; f += 5)
          if ($urandom_range(0, 1) == 0) begin
            case ($urandom_range(0, 3))
              0: m2_io_hpm_event_2[f +: 5] = 5'd0;
              1: m2_io_hpm_event_2[f +: 5] = 5'd1;
              2: m2_io_hpm_event_2[f +: 5] = 5'd2;
              default: m2_io_hpm_event_2[f +: 5] = 5'd4;
            endcase
          end
        for (int k = 0; k < 4; k++)
          case ($urandom_range(0, 3))
            0, 1: begin
              int pick [$] = '{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 97};
              m2_io_hpm_event_3[10*k +: 10] = 10'(pick[$urandom_range(0, pick.size() - 1)]);
            end
            2: begin
              int hole [$] = '{0, 43, 96};
              m2_io_hpm_event_3[10*k +: 10] = ($urandom_range(0, 1) == 0) ? 10'(98 + $urandom_range(0, 29))
                                                                          : 10'(hole[$urandom_range(0, hole.size() - 1)]);
            end
            default: ;
          endcase
        for (int f = 40; f <= 50; f += 5)
          if ($urandom_range(0, 1) == 0) begin
            case ($urandom_range(0, 3))
              0: m2_io_hpm_event_3[f +: 5] = 5'd0;
              1: m2_io_hpm_event_3[f +: 5] = 5'd1;
              2: m2_io_hpm_event_3[f +: 5] = 5'd2;
              default: m2_io_hpm_event_3[f +: 5] = 5'd4;
            endcase
          end
        for (int k = 0; k < 4; k++)
          case ($urandom_range(0, 3))
            0, 1: begin
              int pick [$] = '{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 97};
              m2_io_hpm_event_4[10*k +: 10] = 10'(pick[$urandom_range(0, pick.size() - 1)]);
            end
            2: begin
              int hole [$] = '{0, 43, 96};
              m2_io_hpm_event_4[10*k +: 10] = ($urandom_range(0, 1) == 0) ? 10'(98 + $urandom_range(0, 29))
                                                                          : 10'(hole[$urandom_range(0, hole.size() - 1)]);
            end
            default: ;
          endcase
        for (int f = 40; f <= 50; f += 5)
          if ($urandom_range(0, 1) == 0) begin
            case ($urandom_range(0, 3))
              0: m2_io_hpm_event_4[f +: 5] = 5'd0;
              1: m2_io_hpm_event_4[f +: 5] = 5'd1;
              2: m2_io_hpm_event_4[f +: 5] = 5'd2;
              default: m2_io_hpm_event_4[f +: 5] = 5'd4;
            endcase
          end
        for (int k = 0; k < 4; k++)
          case ($urandom_range(0, 3))
            0, 1: begin
              int pick [$] = '{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 97};
              m2_io_hpm_event_5[10*k +: 10] = 10'(pick[$urandom_range(0, pick.size() - 1)]);
            end
            2: begin
              int hole [$] = '{0, 43, 96};
              m2_io_hpm_event_5[10*k +: 10] = ($urandom_range(0, 1) == 0) ? 10'(98 + $urandom_range(0, 29))
                                                                          : 10'(hole[$urandom_range(0, hole.size() - 1)]);
            end
            default: ;
          endcase
        for (int f = 40; f <= 50; f += 5)
          if ($urandom_range(0, 1) == 0) begin
            case ($urandom_range(0, 3))
              0: m2_io_hpm_event_5[f +: 5] = 5'd0;
              1: m2_io_hpm_event_5[f +: 5] = 5'd1;
              2: m2_io_hpm_event_5[f +: 5] = 5'd2;
              default: m2_io_hpm_event_5[f +: 5] = 5'd4;
            endcase
          end
        for (int k = 0; k < 4; k++)
          case ($urandom_range(0, 3))
            0, 1: begin
              int pick [$] = '{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 97};
              m2_io_hpm_event_6[10*k +: 10] = 10'(pick[$urandom_range(0, pick.size() - 1)]);
            end
            2: begin
              int hole [$] = '{0, 43, 96};
              m2_io_hpm_event_6[10*k +: 10] = ($urandom_range(0, 1) == 0) ? 10'(98 + $urandom_range(0, 29))
                                                                          : 10'(hole[$urandom_range(0, hole.size() - 1)]);
            end
            default: ;
          endcase
        for (int f = 40; f <= 50; f += 5)
          if ($urandom_range(0, 1) == 0) begin
            case ($urandom_range(0, 3))
              0: m2_io_hpm_event_6[f +: 5] = 5'd0;
              1: m2_io_hpm_event_6[f +: 5] = 5'd1;
              2: m2_io_hpm_event_6[f +: 5] = 5'd2;
              default: m2_io_hpm_event_6[f +: 5] = 5'd4;
            endcase
          end
        for (int k = 0; k < 4; k++)
          case ($urandom_range(0, 3))
            0, 1: begin
              int pick [$] = '{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 97};
              m2_io_hpm_event_7[10*k +: 10] = 10'(pick[$urandom_range(0, pick.size() - 1)]);
            end
            2: begin
              int hole [$] = '{0, 43, 96};
              m2_io_hpm_event_7[10*k +: 10] = ($urandom_range(0, 1) == 0) ? 10'(98 + $urandom_range(0, 29))
                                                                          : 10'(hole[$urandom_range(0, hole.size() - 1)]);
            end
            default: ;
          endcase
        for (int f = 40; f <= 50; f += 5)
          if ($urandom_range(0, 1) == 0) begin
            case ($urandom_range(0, 3))
              0: m2_io_hpm_event_7[f +: 5] = 5'd0;
              1: m2_io_hpm_event_7[f +: 5] = 5'd1;
              2: m2_io_hpm_event_7[f +: 5] = 5'd2;
              default: m2_io_hpm_event_7[f +: 5] = 5'd4;
            endcase
          end
      end
      #4;
      m0_armed = 1'b1;
      if (cyc >= RESET_CYC + 8 && (&m0_armed)) begin
        checks++;
        if (m0_g_io_perf_0_value !== m0_i_io_perf_0_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d HPerfMonitor.io_perf_0_value g=%h i=%h", cyc, m0_g_io_perf_0_value, m0_i_io_perf_0_value);
        end
        m0_s1_io_perf_0_value |= m0_g_io_perf_0_value;
        m0_s0_io_perf_0_value |= ~m0_g_io_perf_0_value;
        checks++;
        if (m0_g_io_perf_1_value !== m0_i_io_perf_1_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d HPerfMonitor.io_perf_1_value g=%h i=%h", cyc, m0_g_io_perf_1_value, m0_i_io_perf_1_value);
        end
        m0_s1_io_perf_1_value |= m0_g_io_perf_1_value;
        m0_s0_io_perf_1_value |= ~m0_g_io_perf_1_value;
        checks++;
        if (m0_g_io_perf_2_value !== m0_i_io_perf_2_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d HPerfMonitor.io_perf_2_value g=%h i=%h", cyc, m0_g_io_perf_2_value, m0_i_io_perf_2_value);
        end
        m0_s1_io_perf_2_value |= m0_g_io_perf_2_value;
        m0_s0_io_perf_2_value |= ~m0_g_io_perf_2_value;
        checks++;
        if (m0_g_io_perf_3_value !== m0_i_io_perf_3_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d HPerfMonitor.io_perf_3_value g=%h i=%h", cyc, m0_g_io_perf_3_value, m0_i_io_perf_3_value);
        end
        m0_s1_io_perf_3_value |= m0_g_io_perf_3_value;
        m0_s0_io_perf_3_value |= ~m0_g_io_perf_3_value;
        checks++;
        if (m0_g_io_perf_4_value !== m0_i_io_perf_4_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d HPerfMonitor.io_perf_4_value g=%h i=%h", cyc, m0_g_io_perf_4_value, m0_i_io_perf_4_value);
        end
        m0_s1_io_perf_4_value |= m0_g_io_perf_4_value;
        m0_s0_io_perf_4_value |= ~m0_g_io_perf_4_value;
        checks++;
        if (m0_g_io_perf_5_value !== m0_i_io_perf_5_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d HPerfMonitor.io_perf_5_value g=%h i=%h", cyc, m0_g_io_perf_5_value, m0_i_io_perf_5_value);
        end
        m0_s1_io_perf_5_value |= m0_g_io_perf_5_value;
        m0_s0_io_perf_5_value |= ~m0_g_io_perf_5_value;
        checks++;
        if (m0_g_io_perf_6_value !== m0_i_io_perf_6_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d HPerfMonitor.io_perf_6_value g=%h i=%h", cyc, m0_g_io_perf_6_value, m0_i_io_perf_6_value);
        end
        m0_s1_io_perf_6_value |= m0_g_io_perf_6_value;
        m0_s0_io_perf_6_value |= ~m0_g_io_perf_6_value;
        checks++;
        if (m0_g_io_perf_7_value !== m0_i_io_perf_7_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d HPerfMonitor.io_perf_7_value g=%h i=%h", cyc, m0_g_io_perf_7_value, m0_i_io_perf_7_value);
        end
        m0_s1_io_perf_7_value |= m0_g_io_perf_7_value;
        m0_s0_io_perf_7_value |= ~m0_g_io_perf_7_value;
        if (m0_io_hpm_event_0[50]) m0_cov_op2_and++;
        if (!m0_io_hpm_event_0[50] && m0_io_hpm_event_0[51]) m0_cov_op2_xor++;
        if (m0_io_hpm_event_0[52:50] == 3'b100) m0_cov_op2_add++;
        if (m0_io_hpm_event_0[52:50] == 3'b000) m0_cov_op2_or++;
        if (m0_io_hpm_event_0[5:0] >= 58) m0_cov_idx_oob++;
        if (m0_io_hpm_event_0[9:0] == 10'd0 || m0_io_hpm_event_0[9:0] == 10'd24) m0_cov_idx_hole++;
      end
      if (m0_armed_at < 0 && (&m0_armed)) m0_armed_at = cyc + 1;
      m1_armed = 1'b1;
      if (cyc >= RESET_CYC + 8 && (&m1_armed)) begin
        checks++;
        if (m1_g_io_perf_0_value !== m1_i_io_perf_0_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d HPerfMonitor_1.io_perf_0_value g=%h i=%h", cyc, m1_g_io_perf_0_value, m1_i_io_perf_0_value);
        end
        m1_s1_io_perf_0_value |= m1_g_io_perf_0_value;
        m1_s0_io_perf_0_value |= ~m1_g_io_perf_0_value;
        checks++;
        if (m1_g_io_perf_1_value !== m1_i_io_perf_1_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d HPerfMonitor_1.io_perf_1_value g=%h i=%h", cyc, m1_g_io_perf_1_value, m1_i_io_perf_1_value);
        end
        m1_s1_io_perf_1_value |= m1_g_io_perf_1_value;
        m1_s0_io_perf_1_value |= ~m1_g_io_perf_1_value;
        checks++;
        if (m1_g_io_perf_2_value !== m1_i_io_perf_2_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d HPerfMonitor_1.io_perf_2_value g=%h i=%h", cyc, m1_g_io_perf_2_value, m1_i_io_perf_2_value);
        end
        m1_s1_io_perf_2_value |= m1_g_io_perf_2_value;
        m1_s0_io_perf_2_value |= ~m1_g_io_perf_2_value;
        checks++;
        if (m1_g_io_perf_3_value !== m1_i_io_perf_3_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d HPerfMonitor_1.io_perf_3_value g=%h i=%h", cyc, m1_g_io_perf_3_value, m1_i_io_perf_3_value);
        end
        m1_s1_io_perf_3_value |= m1_g_io_perf_3_value;
        m1_s0_io_perf_3_value |= ~m1_g_io_perf_3_value;
        checks++;
        if (m1_g_io_perf_4_value !== m1_i_io_perf_4_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d HPerfMonitor_1.io_perf_4_value g=%h i=%h", cyc, m1_g_io_perf_4_value, m1_i_io_perf_4_value);
        end
        m1_s1_io_perf_4_value |= m1_g_io_perf_4_value;
        m1_s0_io_perf_4_value |= ~m1_g_io_perf_4_value;
        if (m1_io_hpm_event_0[50]) m1_cov_op2_and++;
        if (!m1_io_hpm_event_0[50] && m1_io_hpm_event_0[51]) m1_cov_op2_xor++;
        if (m1_io_hpm_event_0[52:50] == 3'b100) m1_cov_op2_add++;
        if (m1_io_hpm_event_0[52:50] == 3'b000) m1_cov_op2_or++;
        if (m1_io_hpm_event_0[6:0] >= 68) m1_cov_idx_oob++;
      end
      if (m1_armed_at < 0 && (&m1_armed)) m1_armed_at = cyc + 1;
      m2_armed = 1'b1;
      if (cyc >= RESET_CYC + 8 && (&m2_armed)) begin
        checks++;
        if (m2_g_io_perf_0_value !== m2_i_io_perf_0_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d HPerfMonitor_2.io_perf_0_value g=%h i=%h", cyc, m2_g_io_perf_0_value, m2_i_io_perf_0_value);
        end
        m2_s1_io_perf_0_value |= m2_g_io_perf_0_value;
        m2_s0_io_perf_0_value |= ~m2_g_io_perf_0_value;
        checks++;
        if (m2_g_io_perf_1_value !== m2_i_io_perf_1_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d HPerfMonitor_2.io_perf_1_value g=%h i=%h", cyc, m2_g_io_perf_1_value, m2_i_io_perf_1_value);
        end
        m2_s1_io_perf_1_value |= m2_g_io_perf_1_value;
        m2_s0_io_perf_1_value |= ~m2_g_io_perf_1_value;
        checks++;
        if (m2_g_io_perf_2_value !== m2_i_io_perf_2_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d HPerfMonitor_2.io_perf_2_value g=%h i=%h", cyc, m2_g_io_perf_2_value, m2_i_io_perf_2_value);
        end
        m2_s1_io_perf_2_value |= m2_g_io_perf_2_value;
        m2_s0_io_perf_2_value |= ~m2_g_io_perf_2_value;
        checks++;
        if (m2_g_io_perf_3_value !== m2_i_io_perf_3_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d HPerfMonitor_2.io_perf_3_value g=%h i=%h", cyc, m2_g_io_perf_3_value, m2_i_io_perf_3_value);
        end
        m2_s1_io_perf_3_value |= m2_g_io_perf_3_value;
        m2_s0_io_perf_3_value |= ~m2_g_io_perf_3_value;
        checks++;
        if (m2_g_io_perf_4_value !== m2_i_io_perf_4_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d HPerfMonitor_2.io_perf_4_value g=%h i=%h", cyc, m2_g_io_perf_4_value, m2_i_io_perf_4_value);
        end
        m2_s1_io_perf_4_value |= m2_g_io_perf_4_value;
        m2_s0_io_perf_4_value |= ~m2_g_io_perf_4_value;
        checks++;
        if (m2_g_io_perf_5_value !== m2_i_io_perf_5_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d HPerfMonitor_2.io_perf_5_value g=%h i=%h", cyc, m2_g_io_perf_5_value, m2_i_io_perf_5_value);
        end
        m2_s1_io_perf_5_value |= m2_g_io_perf_5_value;
        m2_s0_io_perf_5_value |= ~m2_g_io_perf_5_value;
        checks++;
        if (m2_g_io_perf_6_value !== m2_i_io_perf_6_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d HPerfMonitor_2.io_perf_6_value g=%h i=%h", cyc, m2_g_io_perf_6_value, m2_i_io_perf_6_value);
        end
        m2_s1_io_perf_6_value |= m2_g_io_perf_6_value;
        m2_s0_io_perf_6_value |= ~m2_g_io_perf_6_value;
        checks++;
        if (m2_g_io_perf_7_value !== m2_i_io_perf_7_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d HPerfMonitor_2.io_perf_7_value g=%h i=%h", cyc, m2_g_io_perf_7_value, m2_i_io_perf_7_value);
        end
        m2_s1_io_perf_7_value |= m2_g_io_perf_7_value;
        m2_s0_io_perf_7_value |= ~m2_g_io_perf_7_value;
        if (m2_io_hpm_event_0[50]) m2_cov_op2_and++;
        if (!m2_io_hpm_event_0[50] && m2_io_hpm_event_0[51]) m2_cov_op2_xor++;
        if (m2_io_hpm_event_0[52:50] == 3'b100) m2_cov_op2_add++;
        if (m2_io_hpm_event_0[52:50] == 3'b000) m2_cov_op2_or++;
        if (m2_io_hpm_event_0[6:0] >= 98) m2_cov_idx_oob++;
        if (m2_io_hpm_event_0[9:0] == 10'd0 || m2_io_hpm_event_0[9:0] == 10'd43 || m2_io_hpm_event_0[9:0] == 10'd96) m2_cov_idx_hole++;
      end
      if (m2_armed_at < 0 && (&m2_armed)) m2_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(m0_s0_io_perf_0_value[0] && m0_s1_io_perf_0_value[0])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_0_value[0] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_0_value[1] && m0_s1_io_perf_0_value[1])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_0_value[1] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_0_value[2] && m0_s1_io_perf_0_value[2])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_0_value[2] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_0_value[3] && m0_s1_io_perf_0_value[3])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_0_value[3] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_0_value[4] && m0_s1_io_perf_0_value[4])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_0_value[4] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_0_value[5] && m0_s1_io_perf_0_value[5])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_0_value[5] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_1_value[0] && m0_s1_io_perf_1_value[0])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_1_value[0] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_1_value[1] && m0_s1_io_perf_1_value[1])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_1_value[1] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_1_value[2] && m0_s1_io_perf_1_value[2])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_1_value[2] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_1_value[3] && m0_s1_io_perf_1_value[3])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_1_value[3] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_1_value[4] && m0_s1_io_perf_1_value[4])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_1_value[4] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_1_value[5] && m0_s1_io_perf_1_value[5])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_1_value[5] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_2_value[0] && m0_s1_io_perf_2_value[0])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_2_value[0] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_2_value[1] && m0_s1_io_perf_2_value[1])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_2_value[1] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_2_value[2] && m0_s1_io_perf_2_value[2])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_2_value[2] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_2_value[3] && m0_s1_io_perf_2_value[3])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_2_value[3] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_2_value[4] && m0_s1_io_perf_2_value[4])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_2_value[4] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_2_value[5] && m0_s1_io_perf_2_value[5])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_2_value[5] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_3_value[0] && m0_s1_io_perf_3_value[0])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_3_value[0] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_3_value[1] && m0_s1_io_perf_3_value[1])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_3_value[1] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_3_value[2] && m0_s1_io_perf_3_value[2])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_3_value[2] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_3_value[3] && m0_s1_io_perf_3_value[3])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_3_value[3] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_3_value[4] && m0_s1_io_perf_3_value[4])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_3_value[4] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_3_value[5] && m0_s1_io_perf_3_value[5])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_3_value[5] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_4_value[0] && m0_s1_io_perf_4_value[0])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_4_value[0] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_4_value[1] && m0_s1_io_perf_4_value[1])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_4_value[1] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_4_value[2] && m0_s1_io_perf_4_value[2])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_4_value[2] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_4_value[3] && m0_s1_io_perf_4_value[3])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_4_value[3] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_4_value[4] && m0_s1_io_perf_4_value[4])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_4_value[4] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_4_value[5] && m0_s1_io_perf_4_value[5])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_4_value[5] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_5_value[0] && m0_s1_io_perf_5_value[0])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_5_value[0] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_5_value[1] && m0_s1_io_perf_5_value[1])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_5_value[1] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_5_value[2] && m0_s1_io_perf_5_value[2])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_5_value[2] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_5_value[3] && m0_s1_io_perf_5_value[3])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_5_value[3] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_5_value[4] && m0_s1_io_perf_5_value[4])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_5_value[4] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_5_value[5] && m0_s1_io_perf_5_value[5])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_5_value[5] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_6_value[0] && m0_s1_io_perf_6_value[0])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_6_value[0] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_6_value[1] && m0_s1_io_perf_6_value[1])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_6_value[1] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_6_value[2] && m0_s1_io_perf_6_value[2])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_6_value[2] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_6_value[3] && m0_s1_io_perf_6_value[3])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_6_value[3] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_6_value[4] && m0_s1_io_perf_6_value[4])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_6_value[4] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_6_value[5] && m0_s1_io_perf_6_value[5])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_6_value[5] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_7_value[0] && m0_s1_io_perf_7_value[0])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_7_value[0] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_7_value[1] && m0_s1_io_perf_7_value[1])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_7_value[1] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_7_value[2] && m0_s1_io_perf_7_value[2])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_7_value[2] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_7_value[3] && m0_s1_io_perf_7_value[3])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_7_value[3] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_7_value[4] && m0_s1_io_perf_7_value[4])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_7_value[4] 未见过 0 和 1"); end
    if (!(m0_s0_io_perf_7_value[5] && m0_s1_io_perf_7_value[5])) begin cov_fail++; $display("[COV] HPerfMonitor.io_perf_7_value[5] 未见过 0 和 1"); end
    $display("[ARM] HPerfMonitor armed_at=%0d", m0_armed_at);
    if (m0_armed_at < 0) begin cov_fail++; $display("[ARM] HPerfMonitor 从未 arm"); end
    $display("[COV] HPerfMonitor.op2_and = %0d", m0_cov_op2_and);
    if (m0_cov_op2_and < 1000) begin cov_fail++; $display("[COV] HPerfMonitor.op2_and < 1000"); end
    $display("[COV] HPerfMonitor.op2_xor = %0d", m0_cov_op2_xor);
    if (m0_cov_op2_xor < 1000) begin cov_fail++; $display("[COV] HPerfMonitor.op2_xor < 1000"); end
    $display("[COV] HPerfMonitor.op2_add = %0d", m0_cov_op2_add);
    if (m0_cov_op2_add < 1000) begin cov_fail++; $display("[COV] HPerfMonitor.op2_add < 1000"); end
    $display("[COV] HPerfMonitor.op2_or = %0d", m0_cov_op2_or);
    if (m0_cov_op2_or < 1000) begin cov_fail++; $display("[COV] HPerfMonitor.op2_or < 1000"); end
    $display("[COV] HPerfMonitor.idx_oob = %0d", m0_cov_idx_oob);
    if (m0_cov_idx_oob < 1000) begin cov_fail++; $display("[COV] HPerfMonitor.idx_oob < 1000"); end
    $display("[COV] HPerfMonitor.idx_hole = %0d", m0_cov_idx_hole);
    if (m0_cov_idx_hole < 1000) begin cov_fail++; $display("[COV] HPerfMonitor.idx_hole < 1000"); end
    if (!(m1_s0_io_perf_0_value[0] && m1_s1_io_perf_0_value[0])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_0_value[0] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_0_value[1] && m1_s1_io_perf_0_value[1])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_0_value[1] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_0_value[2] && m1_s1_io_perf_0_value[2])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_0_value[2] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_0_value[3] && m1_s1_io_perf_0_value[3])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_0_value[3] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_0_value[4] && m1_s1_io_perf_0_value[4])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_0_value[4] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_0_value[5] && m1_s1_io_perf_0_value[5])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_0_value[5] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_1_value[0] && m1_s1_io_perf_1_value[0])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_1_value[0] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_1_value[1] && m1_s1_io_perf_1_value[1])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_1_value[1] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_1_value[2] && m1_s1_io_perf_1_value[2])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_1_value[2] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_1_value[3] && m1_s1_io_perf_1_value[3])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_1_value[3] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_1_value[4] && m1_s1_io_perf_1_value[4])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_1_value[4] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_1_value[5] && m1_s1_io_perf_1_value[5])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_1_value[5] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_2_value[0] && m1_s1_io_perf_2_value[0])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_2_value[0] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_2_value[1] && m1_s1_io_perf_2_value[1])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_2_value[1] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_2_value[2] && m1_s1_io_perf_2_value[2])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_2_value[2] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_2_value[3] && m1_s1_io_perf_2_value[3])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_2_value[3] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_2_value[4] && m1_s1_io_perf_2_value[4])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_2_value[4] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_2_value[5] && m1_s1_io_perf_2_value[5])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_2_value[5] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_3_value[0] && m1_s1_io_perf_3_value[0])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_3_value[0] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_3_value[1] && m1_s1_io_perf_3_value[1])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_3_value[1] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_3_value[2] && m1_s1_io_perf_3_value[2])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_3_value[2] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_3_value[3] && m1_s1_io_perf_3_value[3])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_3_value[3] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_3_value[4] && m1_s1_io_perf_3_value[4])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_3_value[4] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_3_value[5] && m1_s1_io_perf_3_value[5])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_3_value[5] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_4_value[0] && m1_s1_io_perf_4_value[0])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_4_value[0] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_4_value[1] && m1_s1_io_perf_4_value[1])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_4_value[1] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_4_value[2] && m1_s1_io_perf_4_value[2])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_4_value[2] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_4_value[3] && m1_s1_io_perf_4_value[3])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_4_value[3] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_4_value[4] && m1_s1_io_perf_4_value[4])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_4_value[4] 未见过 0 和 1"); end
    if (!(m1_s0_io_perf_4_value[5] && m1_s1_io_perf_4_value[5])) begin cov_fail++; $display("[COV] HPerfMonitor_1.io_perf_4_value[5] 未见过 0 和 1"); end
    $display("[ARM] HPerfMonitor_1 armed_at=%0d", m1_armed_at);
    if (m1_armed_at < 0) begin cov_fail++; $display("[ARM] HPerfMonitor_1 从未 arm"); end
    $display("[COV] HPerfMonitor_1.op2_and = %0d", m1_cov_op2_and);
    if (m1_cov_op2_and < 1000) begin cov_fail++; $display("[COV] HPerfMonitor_1.op2_and < 1000"); end
    $display("[COV] HPerfMonitor_1.op2_xor = %0d", m1_cov_op2_xor);
    if (m1_cov_op2_xor < 1000) begin cov_fail++; $display("[COV] HPerfMonitor_1.op2_xor < 1000"); end
    $display("[COV] HPerfMonitor_1.op2_add = %0d", m1_cov_op2_add);
    if (m1_cov_op2_add < 1000) begin cov_fail++; $display("[COV] HPerfMonitor_1.op2_add < 1000"); end
    $display("[COV] HPerfMonitor_1.op2_or = %0d", m1_cov_op2_or);
    if (m1_cov_op2_or < 1000) begin cov_fail++; $display("[COV] HPerfMonitor_1.op2_or < 1000"); end
    $display("[COV] HPerfMonitor_1.idx_oob = %0d", m1_cov_idx_oob);
    if (m1_cov_idx_oob < 1000) begin cov_fail++; $display("[COV] HPerfMonitor_1.idx_oob < 1000"); end
    if (!(m2_s0_io_perf_0_value[0] && m2_s1_io_perf_0_value[0])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_0_value[0] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_0_value[1] && m2_s1_io_perf_0_value[1])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_0_value[1] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_0_value[2] && m2_s1_io_perf_0_value[2])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_0_value[2] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_0_value[3] && m2_s1_io_perf_0_value[3])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_0_value[3] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_0_value[4] && m2_s1_io_perf_0_value[4])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_0_value[4] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_0_value[5] && m2_s1_io_perf_0_value[5])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_0_value[5] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_1_value[0] && m2_s1_io_perf_1_value[0])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_1_value[0] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_1_value[1] && m2_s1_io_perf_1_value[1])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_1_value[1] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_1_value[2] && m2_s1_io_perf_1_value[2])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_1_value[2] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_1_value[3] && m2_s1_io_perf_1_value[3])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_1_value[3] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_1_value[4] && m2_s1_io_perf_1_value[4])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_1_value[4] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_1_value[5] && m2_s1_io_perf_1_value[5])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_1_value[5] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_2_value[0] && m2_s1_io_perf_2_value[0])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_2_value[0] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_2_value[1] && m2_s1_io_perf_2_value[1])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_2_value[1] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_2_value[2] && m2_s1_io_perf_2_value[2])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_2_value[2] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_2_value[3] && m2_s1_io_perf_2_value[3])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_2_value[3] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_2_value[4] && m2_s1_io_perf_2_value[4])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_2_value[4] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_2_value[5] && m2_s1_io_perf_2_value[5])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_2_value[5] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_3_value[0] && m2_s1_io_perf_3_value[0])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_3_value[0] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_3_value[1] && m2_s1_io_perf_3_value[1])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_3_value[1] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_3_value[2] && m2_s1_io_perf_3_value[2])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_3_value[2] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_3_value[3] && m2_s1_io_perf_3_value[3])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_3_value[3] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_3_value[4] && m2_s1_io_perf_3_value[4])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_3_value[4] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_3_value[5] && m2_s1_io_perf_3_value[5])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_3_value[5] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_4_value[0] && m2_s1_io_perf_4_value[0])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_4_value[0] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_4_value[1] && m2_s1_io_perf_4_value[1])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_4_value[1] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_4_value[2] && m2_s1_io_perf_4_value[2])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_4_value[2] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_4_value[3] && m2_s1_io_perf_4_value[3])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_4_value[3] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_4_value[4] && m2_s1_io_perf_4_value[4])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_4_value[4] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_4_value[5] && m2_s1_io_perf_4_value[5])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_4_value[5] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_5_value[0] && m2_s1_io_perf_5_value[0])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_5_value[0] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_5_value[1] && m2_s1_io_perf_5_value[1])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_5_value[1] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_5_value[2] && m2_s1_io_perf_5_value[2])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_5_value[2] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_5_value[3] && m2_s1_io_perf_5_value[3])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_5_value[3] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_5_value[4] && m2_s1_io_perf_5_value[4])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_5_value[4] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_5_value[5] && m2_s1_io_perf_5_value[5])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_5_value[5] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_6_value[0] && m2_s1_io_perf_6_value[0])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_6_value[0] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_6_value[1] && m2_s1_io_perf_6_value[1])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_6_value[1] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_6_value[2] && m2_s1_io_perf_6_value[2])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_6_value[2] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_6_value[3] && m2_s1_io_perf_6_value[3])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_6_value[3] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_6_value[4] && m2_s1_io_perf_6_value[4])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_6_value[4] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_6_value[5] && m2_s1_io_perf_6_value[5])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_6_value[5] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_7_value[0] && m2_s1_io_perf_7_value[0])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_7_value[0] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_7_value[1] && m2_s1_io_perf_7_value[1])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_7_value[1] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_7_value[2] && m2_s1_io_perf_7_value[2])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_7_value[2] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_7_value[3] && m2_s1_io_perf_7_value[3])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_7_value[3] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_7_value[4] && m2_s1_io_perf_7_value[4])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_7_value[4] 未见过 0 和 1"); end
    if (!(m2_s0_io_perf_7_value[5] && m2_s1_io_perf_7_value[5])) begin cov_fail++; $display("[COV] HPerfMonitor_2.io_perf_7_value[5] 未见过 0 和 1"); end
    $display("[ARM] HPerfMonitor_2 armed_at=%0d", m2_armed_at);
    if (m2_armed_at < 0) begin cov_fail++; $display("[ARM] HPerfMonitor_2 从未 arm"); end
    $display("[COV] HPerfMonitor_2.op2_and = %0d", m2_cov_op2_and);
    if (m2_cov_op2_and < 1000) begin cov_fail++; $display("[COV] HPerfMonitor_2.op2_and < 1000"); end
    $display("[COV] HPerfMonitor_2.op2_xor = %0d", m2_cov_op2_xor);
    if (m2_cov_op2_xor < 1000) begin cov_fail++; $display("[COV] HPerfMonitor_2.op2_xor < 1000"); end
    $display("[COV] HPerfMonitor_2.op2_add = %0d", m2_cov_op2_add);
    if (m2_cov_op2_add < 1000) begin cov_fail++; $display("[COV] HPerfMonitor_2.op2_add < 1000"); end
    $display("[COV] HPerfMonitor_2.op2_or = %0d", m2_cov_op2_or);
    if (m2_cov_op2_or < 1000) begin cov_fail++; $display("[COV] HPerfMonitor_2.op2_or < 1000"); end
    $display("[COV] HPerfMonitor_2.idx_oob = %0d", m2_cov_idx_oob);
    if (m2_cov_idx_oob < 1000) begin cov_fail++; $display("[COV] HPerfMonitor_2.idx_oob < 1000"); end
    $display("[COV] HPerfMonitor_2.idx_hole = %0d", m2_cov_idx_hole);
    if (m2_cov_idx_hole < 1000) begin cov_fail++; $display("[COV] HPerfMonitor_2.idx_hole < 1000"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
