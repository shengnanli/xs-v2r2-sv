// 生成 PFEvent 的 UT testbench（tb.sv）：双例化逐拍比对 + 独立参考模型。
//
// 一、双例化（scripts/dual_tb_lib.py，端口表读 G1 golden）：golden PFEvent（24 个 golden perfEventsModule）vs
//    重写 PFEvent_xs（24 个重写 perfEventsModule_xs），逐拍比 24 个 64 位输出。全部寄存器异步复位，
//    上电复位 8 拍后即开始比；另按 1/40000 概率随机打复位。
// 二、独立参考模型（纯 SV，不读任何实现内部信号）：tb 自己存 24 个 64 位 mhpmevent 影子，按 RISC-V 特权规范
//    + Sstc/Sscofpmf 字段布局建模：w.valid 且 addr ∈ [0x323, 0x33A] 时写第 addr-0x323 个；[57:55] 保留读 0；
//    三个 OPTYPE 字段（[44:40]/[49:45]/[54:50]）WARL，只收合法值 {0 OR, 1 AND, 2 XOR, 4 ADD}，非法值保持原值；
//    异步复位全 0。每拍把模型与 golden、重写件两侧输出逐个核对。
// 激励偏置：w.valid 1/2；addr 1/2 落在 24 个合法地址、1/8 落在相邻的 0x320..0x322 / 0x33B..0x33F（打边界），其余任意 12 位；
//    写数据每个 OPTYPE 字段 1/2 取合法值、1/2 任意 5 位。
// 覆盖闸：24 个副本各被写 >= 100 次；OPTYPE 非法值被拒（保持）>= 100 次；边界外地址写 >= 100 次；
//    每个输出位见过 0/1（豁免：保留位 [57:55] 恒 0；三个 OPTYPE 的 [4:3] —— 合法值 {0,1,2,4} 最大 0b00100，
//    复位 0 之后只收合法值，这 6 位结构上恒 0）。
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

  // ================= PFEvent =================
  int unsigned pf_mode = 0;
  // ============================ 独立参考模型 ============================
  logic [63:0] ref_ev [24];
  int ref_checks = 0, ref_errors = 0, ref_rejects = 0;
  function automatic bit ref_legal_op(input logic [4:0] op);
    return op == 5'd0 || op == 5'd1 || op == 5'd2 || op == 5'd4;
  endfunction
  function automatic logic [63:0] ref_write(input logic [63:0] old, input logic [63:0] d);
    logic [63:0] n;
    n = d;
    n[57:55] = 3'b000;                                   // 保留位读 0
    for (int f = 40; f <= 50; f += 5)                    // OPTYPE0/1/2：WARL，非法值保持
      if (!ref_legal_op(d[f +: 5])) n[f +: 5] = old[f +: 5];
    return n;
  endfunction
  always @(posedge clk or posedge tb.pf_reset) begin
    if (tb.pf_reset) begin
      for (int k = 0; k < 24; k++) ref_ev[k] <= '0;
    end else if (tb.pf_io_distribute_csr_w_valid && tb.pf_io_distribute_csr_w_bits_addr >= 12'h323
                 && tb.pf_io_distribute_csr_w_bits_addr <= 12'h33A) begin
      ref_ev[tb.pf_io_distribute_csr_w_bits_addr - 12'h323] <=
        ref_write(ref_ev[tb.pf_io_distribute_csr_w_bits_addr - 12'h323], tb.pf_io_distribute_csr_w_bits_data);
      for (int f = 40; f <= 50; f += 5)
        if (!ref_legal_op(tb.pf_io_distribute_csr_w_bits_data[f +: 5])) ref_rejects++;
    end
  end
  always @(negedge clk) begin
    #4;
    if (cyc >= RESET_CYC) begin
      ref_checks++;
      if (tb.pf_g_io_hpmevent_0 !== ref_ev[0] || tb.pf_i_io_hpmevent_0 !== ref_ev[0]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_0 ref=%h g=%h i=%h", cyc, ref_ev[0], tb.pf_g_io_hpmevent_0, tb.pf_i_io_hpmevent_0);
      end
      if (tb.pf_g_io_hpmevent_1 !== ref_ev[1] || tb.pf_i_io_hpmevent_1 !== ref_ev[1]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_1 ref=%h g=%h i=%h", cyc, ref_ev[1], tb.pf_g_io_hpmevent_1, tb.pf_i_io_hpmevent_1);
      end
      if (tb.pf_g_io_hpmevent_2 !== ref_ev[2] || tb.pf_i_io_hpmevent_2 !== ref_ev[2]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_2 ref=%h g=%h i=%h", cyc, ref_ev[2], tb.pf_g_io_hpmevent_2, tb.pf_i_io_hpmevent_2);
      end
      if (tb.pf_g_io_hpmevent_3 !== ref_ev[3] || tb.pf_i_io_hpmevent_3 !== ref_ev[3]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_3 ref=%h g=%h i=%h", cyc, ref_ev[3], tb.pf_g_io_hpmevent_3, tb.pf_i_io_hpmevent_3);
      end
      if (tb.pf_g_io_hpmevent_4 !== ref_ev[4] || tb.pf_i_io_hpmevent_4 !== ref_ev[4]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_4 ref=%h g=%h i=%h", cyc, ref_ev[4], tb.pf_g_io_hpmevent_4, tb.pf_i_io_hpmevent_4);
      end
      if (tb.pf_g_io_hpmevent_5 !== ref_ev[5] || tb.pf_i_io_hpmevent_5 !== ref_ev[5]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_5 ref=%h g=%h i=%h", cyc, ref_ev[5], tb.pf_g_io_hpmevent_5, tb.pf_i_io_hpmevent_5);
      end
      if (tb.pf_g_io_hpmevent_6 !== ref_ev[6] || tb.pf_i_io_hpmevent_6 !== ref_ev[6]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_6 ref=%h g=%h i=%h", cyc, ref_ev[6], tb.pf_g_io_hpmevent_6, tb.pf_i_io_hpmevent_6);
      end
      if (tb.pf_g_io_hpmevent_7 !== ref_ev[7] || tb.pf_i_io_hpmevent_7 !== ref_ev[7]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_7 ref=%h g=%h i=%h", cyc, ref_ev[7], tb.pf_g_io_hpmevent_7, tb.pf_i_io_hpmevent_7);
      end
      if (tb.pf_g_io_hpmevent_8 !== ref_ev[8] || tb.pf_i_io_hpmevent_8 !== ref_ev[8]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_8 ref=%h g=%h i=%h", cyc, ref_ev[8], tb.pf_g_io_hpmevent_8, tb.pf_i_io_hpmevent_8);
      end
      if (tb.pf_g_io_hpmevent_9 !== ref_ev[9] || tb.pf_i_io_hpmevent_9 !== ref_ev[9]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_9 ref=%h g=%h i=%h", cyc, ref_ev[9], tb.pf_g_io_hpmevent_9, tb.pf_i_io_hpmevent_9);
      end
      if (tb.pf_g_io_hpmevent_10 !== ref_ev[10] || tb.pf_i_io_hpmevent_10 !== ref_ev[10]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_10 ref=%h g=%h i=%h", cyc, ref_ev[10], tb.pf_g_io_hpmevent_10, tb.pf_i_io_hpmevent_10);
      end
      if (tb.pf_g_io_hpmevent_11 !== ref_ev[11] || tb.pf_i_io_hpmevent_11 !== ref_ev[11]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_11 ref=%h g=%h i=%h", cyc, ref_ev[11], tb.pf_g_io_hpmevent_11, tb.pf_i_io_hpmevent_11);
      end
      if (tb.pf_g_io_hpmevent_12 !== ref_ev[12] || tb.pf_i_io_hpmevent_12 !== ref_ev[12]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_12 ref=%h g=%h i=%h", cyc, ref_ev[12], tb.pf_g_io_hpmevent_12, tb.pf_i_io_hpmevent_12);
      end
      if (tb.pf_g_io_hpmevent_13 !== ref_ev[13] || tb.pf_i_io_hpmevent_13 !== ref_ev[13]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_13 ref=%h g=%h i=%h", cyc, ref_ev[13], tb.pf_g_io_hpmevent_13, tb.pf_i_io_hpmevent_13);
      end
      if (tb.pf_g_io_hpmevent_14 !== ref_ev[14] || tb.pf_i_io_hpmevent_14 !== ref_ev[14]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_14 ref=%h g=%h i=%h", cyc, ref_ev[14], tb.pf_g_io_hpmevent_14, tb.pf_i_io_hpmevent_14);
      end
      if (tb.pf_g_io_hpmevent_15 !== ref_ev[15] || tb.pf_i_io_hpmevent_15 !== ref_ev[15]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_15 ref=%h g=%h i=%h", cyc, ref_ev[15], tb.pf_g_io_hpmevent_15, tb.pf_i_io_hpmevent_15);
      end
      if (tb.pf_g_io_hpmevent_16 !== ref_ev[16] || tb.pf_i_io_hpmevent_16 !== ref_ev[16]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_16 ref=%h g=%h i=%h", cyc, ref_ev[16], tb.pf_g_io_hpmevent_16, tb.pf_i_io_hpmevent_16);
      end
      if (tb.pf_g_io_hpmevent_17 !== ref_ev[17] || tb.pf_i_io_hpmevent_17 !== ref_ev[17]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_17 ref=%h g=%h i=%h", cyc, ref_ev[17], tb.pf_g_io_hpmevent_17, tb.pf_i_io_hpmevent_17);
      end
      if (tb.pf_g_io_hpmevent_18 !== ref_ev[18] || tb.pf_i_io_hpmevent_18 !== ref_ev[18]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_18 ref=%h g=%h i=%h", cyc, ref_ev[18], tb.pf_g_io_hpmevent_18, tb.pf_i_io_hpmevent_18);
      end
      if (tb.pf_g_io_hpmevent_19 !== ref_ev[19] || tb.pf_i_io_hpmevent_19 !== ref_ev[19]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_19 ref=%h g=%h i=%h", cyc, ref_ev[19], tb.pf_g_io_hpmevent_19, tb.pf_i_io_hpmevent_19);
      end
      if (tb.pf_g_io_hpmevent_20 !== ref_ev[20] || tb.pf_i_io_hpmevent_20 !== ref_ev[20]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_20 ref=%h g=%h i=%h", cyc, ref_ev[20], tb.pf_g_io_hpmevent_20, tb.pf_i_io_hpmevent_20);
      end
      if (tb.pf_g_io_hpmevent_21 !== ref_ev[21] || tb.pf_i_io_hpmevent_21 !== ref_ev[21]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_21 ref=%h g=%h i=%h", cyc, ref_ev[21], tb.pf_g_io_hpmevent_21, tb.pf_i_io_hpmevent_21);
      end
      if (tb.pf_g_io_hpmevent_22 !== ref_ev[22] || tb.pf_i_io_hpmevent_22 !== ref_ev[22]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_22 ref=%h g=%h i=%h", cyc, ref_ev[22], tb.pf_g_io_hpmevent_22, tb.pf_i_io_hpmevent_22);
      end
      if (tb.pf_g_io_hpmevent_23 !== ref_ev[23] || tb.pf_i_io_hpmevent_23 !== ref_ev[23]) begin
        ref_errors++; errors++;
        if (ref_errors <= 10) $display("[ORACLE] cyc=%0d hpmevent_23 ref=%h g=%h i=%h", cyc, ref_ev[23], tb.pf_g_io_hpmevent_23, tb.pf_i_io_hpmevent_23);
      end
    end
  end
  final $display("[ORACLE] checks=%0d errors=%0d optype_rejects=%0d", ref_checks, ref_errors, ref_rejects);
  logic pf_reset;
  logic pf_io_distribute_csr_w_valid;
  logic [11:0] pf_io_distribute_csr_w_bits_addr;
  logic [63:0] pf_io_distribute_csr_w_bits_data;
  wire  [63:0] pf_g_io_hpmevent_0, pf_i_io_hpmevent_0;
  logic [63:0] pf_s0_io_hpmevent_0 = '0, pf_s1_io_hpmevent_0 = '0;
  wire  [63:0] pf_g_io_hpmevent_1, pf_i_io_hpmevent_1;
  logic [63:0] pf_s0_io_hpmevent_1 = '0, pf_s1_io_hpmevent_1 = '0;
  wire  [63:0] pf_g_io_hpmevent_2, pf_i_io_hpmevent_2;
  logic [63:0] pf_s0_io_hpmevent_2 = '0, pf_s1_io_hpmevent_2 = '0;
  wire  [63:0] pf_g_io_hpmevent_3, pf_i_io_hpmevent_3;
  logic [63:0] pf_s0_io_hpmevent_3 = '0, pf_s1_io_hpmevent_3 = '0;
  wire  [63:0] pf_g_io_hpmevent_4, pf_i_io_hpmevent_4;
  logic [63:0] pf_s0_io_hpmevent_4 = '0, pf_s1_io_hpmevent_4 = '0;
  wire  [63:0] pf_g_io_hpmevent_5, pf_i_io_hpmevent_5;
  logic [63:0] pf_s0_io_hpmevent_5 = '0, pf_s1_io_hpmevent_5 = '0;
  wire  [63:0] pf_g_io_hpmevent_6, pf_i_io_hpmevent_6;
  logic [63:0] pf_s0_io_hpmevent_6 = '0, pf_s1_io_hpmevent_6 = '0;
  wire  [63:0] pf_g_io_hpmevent_7, pf_i_io_hpmevent_7;
  logic [63:0] pf_s0_io_hpmevent_7 = '0, pf_s1_io_hpmevent_7 = '0;
  wire  [63:0] pf_g_io_hpmevent_8, pf_i_io_hpmevent_8;
  logic [63:0] pf_s0_io_hpmevent_8 = '0, pf_s1_io_hpmevent_8 = '0;
  wire  [63:0] pf_g_io_hpmevent_9, pf_i_io_hpmevent_9;
  logic [63:0] pf_s0_io_hpmevent_9 = '0, pf_s1_io_hpmevent_9 = '0;
  wire  [63:0] pf_g_io_hpmevent_10, pf_i_io_hpmevent_10;
  logic [63:0] pf_s0_io_hpmevent_10 = '0, pf_s1_io_hpmevent_10 = '0;
  wire  [63:0] pf_g_io_hpmevent_11, pf_i_io_hpmevent_11;
  logic [63:0] pf_s0_io_hpmevent_11 = '0, pf_s1_io_hpmevent_11 = '0;
  wire  [63:0] pf_g_io_hpmevent_12, pf_i_io_hpmevent_12;
  logic [63:0] pf_s0_io_hpmevent_12 = '0, pf_s1_io_hpmevent_12 = '0;
  wire  [63:0] pf_g_io_hpmevent_13, pf_i_io_hpmevent_13;
  logic [63:0] pf_s0_io_hpmevent_13 = '0, pf_s1_io_hpmevent_13 = '0;
  wire  [63:0] pf_g_io_hpmevent_14, pf_i_io_hpmevent_14;
  logic [63:0] pf_s0_io_hpmevent_14 = '0, pf_s1_io_hpmevent_14 = '0;
  wire  [63:0] pf_g_io_hpmevent_15, pf_i_io_hpmevent_15;
  logic [63:0] pf_s0_io_hpmevent_15 = '0, pf_s1_io_hpmevent_15 = '0;
  wire  [63:0] pf_g_io_hpmevent_16, pf_i_io_hpmevent_16;
  logic [63:0] pf_s0_io_hpmevent_16 = '0, pf_s1_io_hpmevent_16 = '0;
  wire  [63:0] pf_g_io_hpmevent_17, pf_i_io_hpmevent_17;
  logic [63:0] pf_s0_io_hpmevent_17 = '0, pf_s1_io_hpmevent_17 = '0;
  wire  [63:0] pf_g_io_hpmevent_18, pf_i_io_hpmevent_18;
  logic [63:0] pf_s0_io_hpmevent_18 = '0, pf_s1_io_hpmevent_18 = '0;
  wire  [63:0] pf_g_io_hpmevent_19, pf_i_io_hpmevent_19;
  logic [63:0] pf_s0_io_hpmevent_19 = '0, pf_s1_io_hpmevent_19 = '0;
  wire  [63:0] pf_g_io_hpmevent_20, pf_i_io_hpmevent_20;
  logic [63:0] pf_s0_io_hpmevent_20 = '0, pf_s1_io_hpmevent_20 = '0;
  wire  [63:0] pf_g_io_hpmevent_21, pf_i_io_hpmevent_21;
  logic [63:0] pf_s0_io_hpmevent_21 = '0, pf_s1_io_hpmevent_21 = '0;
  wire  [63:0] pf_g_io_hpmevent_22, pf_i_io_hpmevent_22;
  logic [63:0] pf_s0_io_hpmevent_22 = '0, pf_s1_io_hpmevent_22 = '0;
  wire  [63:0] pf_g_io_hpmevent_23, pf_i_io_hpmevent_23;
  logic [63:0] pf_s0_io_hpmevent_23 = '0, pf_s1_io_hpmevent_23 = '0;
  int pf_cov_wr0 = 0;
  int pf_cov_wr1 = 0;
  int pf_cov_wr2 = 0;
  int pf_cov_wr3 = 0;
  int pf_cov_wr4 = 0;
  int pf_cov_wr5 = 0;
  int pf_cov_wr6 = 0;
  int pf_cov_wr7 = 0;
  int pf_cov_wr8 = 0;
  int pf_cov_wr9 = 0;
  int pf_cov_wr10 = 0;
  int pf_cov_wr11 = 0;
  int pf_cov_wr12 = 0;
  int pf_cov_wr13 = 0;
  int pf_cov_wr14 = 0;
  int pf_cov_wr15 = 0;
  int pf_cov_wr16 = 0;
  int pf_cov_wr17 = 0;
  int pf_cov_wr18 = 0;
  int pf_cov_wr19 = 0;
  int pf_cov_wr20 = 0;
  int pf_cov_wr21 = 0;
  int pf_cov_wr22 = 0;
  int pf_cov_wr23 = 0;
  int pf_cov_wr_outside = 0;
  int pf_cov_optype_reject = 0;
  logic [0:0] pf_armed = '0;
  int pf_armed_at = -1;
  PFEvent pf_u_gold (
    .clock(clk),
    .reset(pf_reset),
    .io_distribute_csr_w_valid(pf_io_distribute_csr_w_valid),
    .io_distribute_csr_w_bits_addr(pf_io_distribute_csr_w_bits_addr),
    .io_distribute_csr_w_bits_data(pf_io_distribute_csr_w_bits_data),
    .io_hpmevent_0(pf_g_io_hpmevent_0),
    .io_hpmevent_1(pf_g_io_hpmevent_1),
    .io_hpmevent_2(pf_g_io_hpmevent_2),
    .io_hpmevent_3(pf_g_io_hpmevent_3),
    .io_hpmevent_4(pf_g_io_hpmevent_4),
    .io_hpmevent_5(pf_g_io_hpmevent_5),
    .io_hpmevent_6(pf_g_io_hpmevent_6),
    .io_hpmevent_7(pf_g_io_hpmevent_7),
    .io_hpmevent_8(pf_g_io_hpmevent_8),
    .io_hpmevent_9(pf_g_io_hpmevent_9),
    .io_hpmevent_10(pf_g_io_hpmevent_10),
    .io_hpmevent_11(pf_g_io_hpmevent_11),
    .io_hpmevent_12(pf_g_io_hpmevent_12),
    .io_hpmevent_13(pf_g_io_hpmevent_13),
    .io_hpmevent_14(pf_g_io_hpmevent_14),
    .io_hpmevent_15(pf_g_io_hpmevent_15),
    .io_hpmevent_16(pf_g_io_hpmevent_16),
    .io_hpmevent_17(pf_g_io_hpmevent_17),
    .io_hpmevent_18(pf_g_io_hpmevent_18),
    .io_hpmevent_19(pf_g_io_hpmevent_19),
    .io_hpmevent_20(pf_g_io_hpmevent_20),
    .io_hpmevent_21(pf_g_io_hpmevent_21),
    .io_hpmevent_22(pf_g_io_hpmevent_22),
    .io_hpmevent_23(pf_g_io_hpmevent_23)
  );
  PFEvent_xs pf_u_impl (
    .clock(clk),
    .reset(pf_reset),
    .io_distribute_csr_w_valid(pf_io_distribute_csr_w_valid),
    .io_distribute_csr_w_bits_addr(pf_io_distribute_csr_w_bits_addr),
    .io_distribute_csr_w_bits_data(pf_io_distribute_csr_w_bits_data),
    .io_hpmevent_0(pf_i_io_hpmevent_0),
    .io_hpmevent_1(pf_i_io_hpmevent_1),
    .io_hpmevent_2(pf_i_io_hpmevent_2),
    .io_hpmevent_3(pf_i_io_hpmevent_3),
    .io_hpmevent_4(pf_i_io_hpmevent_4),
    .io_hpmevent_5(pf_i_io_hpmevent_5),
    .io_hpmevent_6(pf_i_io_hpmevent_6),
    .io_hpmevent_7(pf_i_io_hpmevent_7),
    .io_hpmevent_8(pf_i_io_hpmevent_8),
    .io_hpmevent_9(pf_i_io_hpmevent_9),
    .io_hpmevent_10(pf_i_io_hpmevent_10),
    .io_hpmevent_11(pf_i_io_hpmevent_11),
    .io_hpmevent_12(pf_i_io_hpmevent_12),
    .io_hpmevent_13(pf_i_io_hpmevent_13),
    .io_hpmevent_14(pf_i_io_hpmevent_14),
    .io_hpmevent_15(pf_i_io_hpmevent_15),
    .io_hpmevent_16(pf_i_io_hpmevent_16),
    .io_hpmevent_17(pf_i_io_hpmevent_17),
    .io_hpmevent_18(pf_i_io_hpmevent_18),
    .io_hpmevent_19(pf_i_io_hpmevent_19),
    .io_hpmevent_20(pf_i_io_hpmevent_20),
    .io_hpmevent_21(pf_i_io_hpmevent_21),
    .io_hpmevent_22(pf_i_io_hpmevent_22),
    .io_hpmevent_23(pf_i_io_hpmevent_23)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) pf_mode = $urandom_range(0, 15);
      pf_io_distribute_csr_w_valid = 1'($urandom);
      pf_io_distribute_csr_w_bits_addr = 12'($urandom);
      pf_io_distribute_csr_w_bits_data = 64'({$urandom, $urandom});
      pf_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_pf
        case ($urandom_range(0, 7))
          0, 1, 2, 3: pf_io_distribute_csr_w_bits_addr = 12'h323 + $urandom_range(0, 23);
          4: pf_io_distribute_csr_w_bits_addr = ($urandom_range(0, 1) == 0) ? 12'h320 + $urandom_range(0, 2) : 12'h33B + $urandom_range(0, 4);
          default: ;
        endcase
        for (int f = 40; f <= 50; f += 5)
          if ($urandom_range(0, 1) == 0) begin
            case ($urandom_range(0, 3))
              0: pf_io_distribute_csr_w_bits_data[f +: 5] = 5'd0;
              1: pf_io_distribute_csr_w_bits_data[f +: 5] = 5'd1;
              2: pf_io_distribute_csr_w_bits_data[f +: 5] = 5'd2;
              default: pf_io_distribute_csr_w_bits_data[f +: 5] = 5'd4;
            endcase
          end
      end
      #4;
      pf_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&pf_armed)) begin
        checks++;
        if (pf_g_io_hpmevent_0 !== pf_i_io_hpmevent_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_0 g=%h i=%h", cyc, pf_g_io_hpmevent_0, pf_i_io_hpmevent_0);
        end
        pf_s1_io_hpmevent_0 |= pf_g_io_hpmevent_0;
        pf_s0_io_hpmevent_0 |= ~pf_g_io_hpmevent_0;
        checks++;
        if (pf_g_io_hpmevent_1 !== pf_i_io_hpmevent_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_1 g=%h i=%h", cyc, pf_g_io_hpmevent_1, pf_i_io_hpmevent_1);
        end
        pf_s1_io_hpmevent_1 |= pf_g_io_hpmevent_1;
        pf_s0_io_hpmevent_1 |= ~pf_g_io_hpmevent_1;
        checks++;
        if (pf_g_io_hpmevent_2 !== pf_i_io_hpmevent_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_2 g=%h i=%h", cyc, pf_g_io_hpmevent_2, pf_i_io_hpmevent_2);
        end
        pf_s1_io_hpmevent_2 |= pf_g_io_hpmevent_2;
        pf_s0_io_hpmevent_2 |= ~pf_g_io_hpmevent_2;
        checks++;
        if (pf_g_io_hpmevent_3 !== pf_i_io_hpmevent_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_3 g=%h i=%h", cyc, pf_g_io_hpmevent_3, pf_i_io_hpmevent_3);
        end
        pf_s1_io_hpmevent_3 |= pf_g_io_hpmevent_3;
        pf_s0_io_hpmevent_3 |= ~pf_g_io_hpmevent_3;
        checks++;
        if (pf_g_io_hpmevent_4 !== pf_i_io_hpmevent_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_4 g=%h i=%h", cyc, pf_g_io_hpmevent_4, pf_i_io_hpmevent_4);
        end
        pf_s1_io_hpmevent_4 |= pf_g_io_hpmevent_4;
        pf_s0_io_hpmevent_4 |= ~pf_g_io_hpmevent_4;
        checks++;
        if (pf_g_io_hpmevent_5 !== pf_i_io_hpmevent_5) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_5 g=%h i=%h", cyc, pf_g_io_hpmevent_5, pf_i_io_hpmevent_5);
        end
        pf_s1_io_hpmevent_5 |= pf_g_io_hpmevent_5;
        pf_s0_io_hpmevent_5 |= ~pf_g_io_hpmevent_5;
        checks++;
        if (pf_g_io_hpmevent_6 !== pf_i_io_hpmevent_6) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_6 g=%h i=%h", cyc, pf_g_io_hpmevent_6, pf_i_io_hpmevent_6);
        end
        pf_s1_io_hpmevent_6 |= pf_g_io_hpmevent_6;
        pf_s0_io_hpmevent_6 |= ~pf_g_io_hpmevent_6;
        checks++;
        if (pf_g_io_hpmevent_7 !== pf_i_io_hpmevent_7) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_7 g=%h i=%h", cyc, pf_g_io_hpmevent_7, pf_i_io_hpmevent_7);
        end
        pf_s1_io_hpmevent_7 |= pf_g_io_hpmevent_7;
        pf_s0_io_hpmevent_7 |= ~pf_g_io_hpmevent_7;
        checks++;
        if (pf_g_io_hpmevent_8 !== pf_i_io_hpmevent_8) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_8 g=%h i=%h", cyc, pf_g_io_hpmevent_8, pf_i_io_hpmevent_8);
        end
        pf_s1_io_hpmevent_8 |= pf_g_io_hpmevent_8;
        pf_s0_io_hpmevent_8 |= ~pf_g_io_hpmevent_8;
        checks++;
        if (pf_g_io_hpmevent_9 !== pf_i_io_hpmevent_9) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_9 g=%h i=%h", cyc, pf_g_io_hpmevent_9, pf_i_io_hpmevent_9);
        end
        pf_s1_io_hpmevent_9 |= pf_g_io_hpmevent_9;
        pf_s0_io_hpmevent_9 |= ~pf_g_io_hpmevent_9;
        checks++;
        if (pf_g_io_hpmevent_10 !== pf_i_io_hpmevent_10) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_10 g=%h i=%h", cyc, pf_g_io_hpmevent_10, pf_i_io_hpmevent_10);
        end
        pf_s1_io_hpmevent_10 |= pf_g_io_hpmevent_10;
        pf_s0_io_hpmevent_10 |= ~pf_g_io_hpmevent_10;
        checks++;
        if (pf_g_io_hpmevent_11 !== pf_i_io_hpmevent_11) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_11 g=%h i=%h", cyc, pf_g_io_hpmevent_11, pf_i_io_hpmevent_11);
        end
        pf_s1_io_hpmevent_11 |= pf_g_io_hpmevent_11;
        pf_s0_io_hpmevent_11 |= ~pf_g_io_hpmevent_11;
        checks++;
        if (pf_g_io_hpmevent_12 !== pf_i_io_hpmevent_12) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_12 g=%h i=%h", cyc, pf_g_io_hpmevent_12, pf_i_io_hpmevent_12);
        end
        pf_s1_io_hpmevent_12 |= pf_g_io_hpmevent_12;
        pf_s0_io_hpmevent_12 |= ~pf_g_io_hpmevent_12;
        checks++;
        if (pf_g_io_hpmevent_13 !== pf_i_io_hpmevent_13) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_13 g=%h i=%h", cyc, pf_g_io_hpmevent_13, pf_i_io_hpmevent_13);
        end
        pf_s1_io_hpmevent_13 |= pf_g_io_hpmevent_13;
        pf_s0_io_hpmevent_13 |= ~pf_g_io_hpmevent_13;
        checks++;
        if (pf_g_io_hpmevent_14 !== pf_i_io_hpmevent_14) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_14 g=%h i=%h", cyc, pf_g_io_hpmevent_14, pf_i_io_hpmevent_14);
        end
        pf_s1_io_hpmevent_14 |= pf_g_io_hpmevent_14;
        pf_s0_io_hpmevent_14 |= ~pf_g_io_hpmevent_14;
        checks++;
        if (pf_g_io_hpmevent_15 !== pf_i_io_hpmevent_15) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_15 g=%h i=%h", cyc, pf_g_io_hpmevent_15, pf_i_io_hpmevent_15);
        end
        pf_s1_io_hpmevent_15 |= pf_g_io_hpmevent_15;
        pf_s0_io_hpmevent_15 |= ~pf_g_io_hpmevent_15;
        checks++;
        if (pf_g_io_hpmevent_16 !== pf_i_io_hpmevent_16) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_16 g=%h i=%h", cyc, pf_g_io_hpmevent_16, pf_i_io_hpmevent_16);
        end
        pf_s1_io_hpmevent_16 |= pf_g_io_hpmevent_16;
        pf_s0_io_hpmevent_16 |= ~pf_g_io_hpmevent_16;
        checks++;
        if (pf_g_io_hpmevent_17 !== pf_i_io_hpmevent_17) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_17 g=%h i=%h", cyc, pf_g_io_hpmevent_17, pf_i_io_hpmevent_17);
        end
        pf_s1_io_hpmevent_17 |= pf_g_io_hpmevent_17;
        pf_s0_io_hpmevent_17 |= ~pf_g_io_hpmevent_17;
        checks++;
        if (pf_g_io_hpmevent_18 !== pf_i_io_hpmevent_18) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_18 g=%h i=%h", cyc, pf_g_io_hpmevent_18, pf_i_io_hpmevent_18);
        end
        pf_s1_io_hpmevent_18 |= pf_g_io_hpmevent_18;
        pf_s0_io_hpmevent_18 |= ~pf_g_io_hpmevent_18;
        checks++;
        if (pf_g_io_hpmevent_19 !== pf_i_io_hpmevent_19) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_19 g=%h i=%h", cyc, pf_g_io_hpmevent_19, pf_i_io_hpmevent_19);
        end
        pf_s1_io_hpmevent_19 |= pf_g_io_hpmevent_19;
        pf_s0_io_hpmevent_19 |= ~pf_g_io_hpmevent_19;
        checks++;
        if (pf_g_io_hpmevent_20 !== pf_i_io_hpmevent_20) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_20 g=%h i=%h", cyc, pf_g_io_hpmevent_20, pf_i_io_hpmevent_20);
        end
        pf_s1_io_hpmevent_20 |= pf_g_io_hpmevent_20;
        pf_s0_io_hpmevent_20 |= ~pf_g_io_hpmevent_20;
        checks++;
        if (pf_g_io_hpmevent_21 !== pf_i_io_hpmevent_21) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_21 g=%h i=%h", cyc, pf_g_io_hpmevent_21, pf_i_io_hpmevent_21);
        end
        pf_s1_io_hpmevent_21 |= pf_g_io_hpmevent_21;
        pf_s0_io_hpmevent_21 |= ~pf_g_io_hpmevent_21;
        checks++;
        if (pf_g_io_hpmevent_22 !== pf_i_io_hpmevent_22) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_22 g=%h i=%h", cyc, pf_g_io_hpmevent_22, pf_i_io_hpmevent_22);
        end
        pf_s1_io_hpmevent_22 |= pf_g_io_hpmevent_22;
        pf_s0_io_hpmevent_22 |= ~pf_g_io_hpmevent_22;
        checks++;
        if (pf_g_io_hpmevent_23 !== pf_i_io_hpmevent_23) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d PFEvent.io_hpmevent_23 g=%h i=%h", cyc, pf_g_io_hpmevent_23, pf_i_io_hpmevent_23);
        end
        pf_s1_io_hpmevent_23 |= pf_g_io_hpmevent_23;
        pf_s0_io_hpmevent_23 |= ~pf_g_io_hpmevent_23;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h323) pf_cov_wr0++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h324) pf_cov_wr1++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h325) pf_cov_wr2++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h326) pf_cov_wr3++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h327) pf_cov_wr4++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h328) pf_cov_wr5++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h329) pf_cov_wr6++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h32A) pf_cov_wr7++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h32B) pf_cov_wr8++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h32C) pf_cov_wr9++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h32D) pf_cov_wr10++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h32E) pf_cov_wr11++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h32F) pf_cov_wr12++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h330) pf_cov_wr13++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h331) pf_cov_wr14++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h332) pf_cov_wr15++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h333) pf_cov_wr16++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h334) pf_cov_wr17++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h335) pf_cov_wr18++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h336) pf_cov_wr19++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h337) pf_cov_wr20++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h338) pf_cov_wr21++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h339) pf_cov_wr22++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr == 12'h33A) pf_cov_wr23++;
        if (pf_io_distribute_csr_w_valid && (pf_io_distribute_csr_w_bits_addr inside {[12'h320:12'h322], [12'h33B:12'h33F]})) pf_cov_wr_outside++;
        if (pf_io_distribute_csr_w_valid && pf_io_distribute_csr_w_bits_addr inside {[12'h323:12'h33A]} && !(pf_io_distribute_csr_w_bits_data[44:40] inside {0, 1, 2, 4})) pf_cov_optype_reject++;
      end
      if (pf_armed_at < 0 && (&pf_armed)) pf_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(pf_s0_io_hpmevent_0[0] && pf_s1_io_hpmevent_0[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[1] && pf_s1_io_hpmevent_0[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[2] && pf_s1_io_hpmevent_0[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[3] && pf_s1_io_hpmevent_0[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[4] && pf_s1_io_hpmevent_0[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[5] && pf_s1_io_hpmevent_0[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[6] && pf_s1_io_hpmevent_0[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[7] && pf_s1_io_hpmevent_0[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[8] && pf_s1_io_hpmevent_0[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[9] && pf_s1_io_hpmevent_0[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[10] && pf_s1_io_hpmevent_0[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[11] && pf_s1_io_hpmevent_0[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[12] && pf_s1_io_hpmevent_0[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[13] && pf_s1_io_hpmevent_0[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[14] && pf_s1_io_hpmevent_0[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[15] && pf_s1_io_hpmevent_0[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[16] && pf_s1_io_hpmevent_0[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[17] && pf_s1_io_hpmevent_0[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[18] && pf_s1_io_hpmevent_0[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[19] && pf_s1_io_hpmevent_0[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[20] && pf_s1_io_hpmevent_0[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[21] && pf_s1_io_hpmevent_0[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[22] && pf_s1_io_hpmevent_0[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[23] && pf_s1_io_hpmevent_0[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[24] && pf_s1_io_hpmevent_0[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[25] && pf_s1_io_hpmevent_0[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[26] && pf_s1_io_hpmevent_0[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[27] && pf_s1_io_hpmevent_0[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[28] && pf_s1_io_hpmevent_0[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[29] && pf_s1_io_hpmevent_0[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[30] && pf_s1_io_hpmevent_0[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[31] && pf_s1_io_hpmevent_0[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[32] && pf_s1_io_hpmevent_0[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[33] && pf_s1_io_hpmevent_0[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[34] && pf_s1_io_hpmevent_0[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[35] && pf_s1_io_hpmevent_0[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[36] && pf_s1_io_hpmevent_0[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[37] && pf_s1_io_hpmevent_0[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[38] && pf_s1_io_hpmevent_0[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[39] && pf_s1_io_hpmevent_0[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[40] && pf_s1_io_hpmevent_0[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[41] && pf_s1_io_hpmevent_0[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[42] && pf_s1_io_hpmevent_0[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[45] && pf_s1_io_hpmevent_0[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[46] && pf_s1_io_hpmevent_0[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[47] && pf_s1_io_hpmevent_0[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[50] && pf_s1_io_hpmevent_0[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[51] && pf_s1_io_hpmevent_0[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[52] && pf_s1_io_hpmevent_0[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[58] && pf_s1_io_hpmevent_0[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[59] && pf_s1_io_hpmevent_0[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[60] && pf_s1_io_hpmevent_0[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[61] && pf_s1_io_hpmevent_0[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[62] && pf_s1_io_hpmevent_0[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_0[63] && pf_s1_io_hpmevent_0[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_0[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[0] && pf_s1_io_hpmevent_1[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[1] && pf_s1_io_hpmevent_1[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[2] && pf_s1_io_hpmevent_1[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[3] && pf_s1_io_hpmevent_1[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[4] && pf_s1_io_hpmevent_1[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[5] && pf_s1_io_hpmevent_1[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[6] && pf_s1_io_hpmevent_1[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[7] && pf_s1_io_hpmevent_1[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[8] && pf_s1_io_hpmevent_1[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[9] && pf_s1_io_hpmevent_1[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[10] && pf_s1_io_hpmevent_1[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[11] && pf_s1_io_hpmevent_1[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[12] && pf_s1_io_hpmevent_1[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[13] && pf_s1_io_hpmevent_1[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[14] && pf_s1_io_hpmevent_1[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[15] && pf_s1_io_hpmevent_1[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[16] && pf_s1_io_hpmevent_1[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[17] && pf_s1_io_hpmevent_1[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[18] && pf_s1_io_hpmevent_1[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[19] && pf_s1_io_hpmevent_1[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[20] && pf_s1_io_hpmevent_1[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[21] && pf_s1_io_hpmevent_1[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[22] && pf_s1_io_hpmevent_1[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[23] && pf_s1_io_hpmevent_1[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[24] && pf_s1_io_hpmevent_1[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[25] && pf_s1_io_hpmevent_1[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[26] && pf_s1_io_hpmevent_1[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[27] && pf_s1_io_hpmevent_1[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[28] && pf_s1_io_hpmevent_1[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[29] && pf_s1_io_hpmevent_1[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[30] && pf_s1_io_hpmevent_1[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[31] && pf_s1_io_hpmevent_1[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[32] && pf_s1_io_hpmevent_1[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[33] && pf_s1_io_hpmevent_1[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[34] && pf_s1_io_hpmevent_1[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[35] && pf_s1_io_hpmevent_1[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[36] && pf_s1_io_hpmevent_1[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[37] && pf_s1_io_hpmevent_1[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[38] && pf_s1_io_hpmevent_1[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[39] && pf_s1_io_hpmevent_1[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[40] && pf_s1_io_hpmevent_1[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[41] && pf_s1_io_hpmevent_1[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[42] && pf_s1_io_hpmevent_1[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[45] && pf_s1_io_hpmevent_1[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[46] && pf_s1_io_hpmevent_1[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[47] && pf_s1_io_hpmevent_1[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[50] && pf_s1_io_hpmevent_1[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[51] && pf_s1_io_hpmevent_1[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[52] && pf_s1_io_hpmevent_1[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[58] && pf_s1_io_hpmevent_1[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[59] && pf_s1_io_hpmevent_1[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[60] && pf_s1_io_hpmevent_1[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[61] && pf_s1_io_hpmevent_1[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[62] && pf_s1_io_hpmevent_1[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_1[63] && pf_s1_io_hpmevent_1[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_1[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[0] && pf_s1_io_hpmevent_2[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[1] && pf_s1_io_hpmevent_2[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[2] && pf_s1_io_hpmevent_2[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[3] && pf_s1_io_hpmevent_2[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[4] && pf_s1_io_hpmevent_2[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[5] && pf_s1_io_hpmevent_2[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[6] && pf_s1_io_hpmevent_2[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[7] && pf_s1_io_hpmevent_2[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[8] && pf_s1_io_hpmevent_2[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[9] && pf_s1_io_hpmevent_2[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[10] && pf_s1_io_hpmevent_2[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[11] && pf_s1_io_hpmevent_2[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[12] && pf_s1_io_hpmevent_2[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[13] && pf_s1_io_hpmevent_2[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[14] && pf_s1_io_hpmevent_2[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[15] && pf_s1_io_hpmevent_2[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[16] && pf_s1_io_hpmevent_2[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[17] && pf_s1_io_hpmevent_2[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[18] && pf_s1_io_hpmevent_2[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[19] && pf_s1_io_hpmevent_2[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[20] && pf_s1_io_hpmevent_2[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[21] && pf_s1_io_hpmevent_2[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[22] && pf_s1_io_hpmevent_2[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[23] && pf_s1_io_hpmevent_2[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[24] && pf_s1_io_hpmevent_2[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[25] && pf_s1_io_hpmevent_2[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[26] && pf_s1_io_hpmevent_2[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[27] && pf_s1_io_hpmevent_2[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[28] && pf_s1_io_hpmevent_2[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[29] && pf_s1_io_hpmevent_2[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[30] && pf_s1_io_hpmevent_2[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[31] && pf_s1_io_hpmevent_2[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[32] && pf_s1_io_hpmevent_2[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[33] && pf_s1_io_hpmevent_2[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[34] && pf_s1_io_hpmevent_2[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[35] && pf_s1_io_hpmevent_2[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[36] && pf_s1_io_hpmevent_2[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[37] && pf_s1_io_hpmevent_2[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[38] && pf_s1_io_hpmevent_2[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[39] && pf_s1_io_hpmevent_2[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[40] && pf_s1_io_hpmevent_2[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[41] && pf_s1_io_hpmevent_2[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[42] && pf_s1_io_hpmevent_2[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[45] && pf_s1_io_hpmevent_2[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[46] && pf_s1_io_hpmevent_2[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[47] && pf_s1_io_hpmevent_2[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[50] && pf_s1_io_hpmevent_2[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[51] && pf_s1_io_hpmevent_2[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[52] && pf_s1_io_hpmevent_2[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[58] && pf_s1_io_hpmevent_2[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[59] && pf_s1_io_hpmevent_2[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[60] && pf_s1_io_hpmevent_2[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[61] && pf_s1_io_hpmevent_2[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[62] && pf_s1_io_hpmevent_2[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_2[63] && pf_s1_io_hpmevent_2[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_2[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[0] && pf_s1_io_hpmevent_3[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[1] && pf_s1_io_hpmevent_3[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[2] && pf_s1_io_hpmevent_3[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[3] && pf_s1_io_hpmevent_3[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[4] && pf_s1_io_hpmevent_3[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[5] && pf_s1_io_hpmevent_3[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[6] && pf_s1_io_hpmevent_3[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[7] && pf_s1_io_hpmevent_3[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[8] && pf_s1_io_hpmevent_3[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[9] && pf_s1_io_hpmevent_3[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[10] && pf_s1_io_hpmevent_3[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[11] && pf_s1_io_hpmevent_3[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[12] && pf_s1_io_hpmevent_3[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[13] && pf_s1_io_hpmevent_3[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[14] && pf_s1_io_hpmevent_3[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[15] && pf_s1_io_hpmevent_3[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[16] && pf_s1_io_hpmevent_3[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[17] && pf_s1_io_hpmevent_3[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[18] && pf_s1_io_hpmevent_3[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[19] && pf_s1_io_hpmevent_3[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[20] && pf_s1_io_hpmevent_3[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[21] && pf_s1_io_hpmevent_3[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[22] && pf_s1_io_hpmevent_3[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[23] && pf_s1_io_hpmevent_3[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[24] && pf_s1_io_hpmevent_3[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[25] && pf_s1_io_hpmevent_3[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[26] && pf_s1_io_hpmevent_3[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[27] && pf_s1_io_hpmevent_3[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[28] && pf_s1_io_hpmevent_3[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[29] && pf_s1_io_hpmevent_3[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[30] && pf_s1_io_hpmevent_3[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[31] && pf_s1_io_hpmevent_3[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[32] && pf_s1_io_hpmevent_3[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[33] && pf_s1_io_hpmevent_3[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[34] && pf_s1_io_hpmevent_3[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[35] && pf_s1_io_hpmevent_3[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[36] && pf_s1_io_hpmevent_3[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[37] && pf_s1_io_hpmevent_3[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[38] && pf_s1_io_hpmevent_3[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[39] && pf_s1_io_hpmevent_3[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[40] && pf_s1_io_hpmevent_3[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[41] && pf_s1_io_hpmevent_3[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[42] && pf_s1_io_hpmevent_3[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[45] && pf_s1_io_hpmevent_3[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[46] && pf_s1_io_hpmevent_3[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[47] && pf_s1_io_hpmevent_3[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[50] && pf_s1_io_hpmevent_3[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[51] && pf_s1_io_hpmevent_3[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[52] && pf_s1_io_hpmevent_3[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[58] && pf_s1_io_hpmevent_3[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[59] && pf_s1_io_hpmevent_3[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[60] && pf_s1_io_hpmevent_3[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[61] && pf_s1_io_hpmevent_3[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[62] && pf_s1_io_hpmevent_3[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_3[63] && pf_s1_io_hpmevent_3[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_3[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[0] && pf_s1_io_hpmevent_4[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[1] && pf_s1_io_hpmevent_4[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[2] && pf_s1_io_hpmevent_4[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[3] && pf_s1_io_hpmevent_4[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[4] && pf_s1_io_hpmevent_4[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[5] && pf_s1_io_hpmevent_4[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[6] && pf_s1_io_hpmevent_4[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[7] && pf_s1_io_hpmevent_4[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[8] && pf_s1_io_hpmevent_4[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[9] && pf_s1_io_hpmevent_4[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[10] && pf_s1_io_hpmevent_4[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[11] && pf_s1_io_hpmevent_4[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[12] && pf_s1_io_hpmevent_4[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[13] && pf_s1_io_hpmevent_4[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[14] && pf_s1_io_hpmevent_4[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[15] && pf_s1_io_hpmevent_4[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[16] && pf_s1_io_hpmevent_4[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[17] && pf_s1_io_hpmevent_4[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[18] && pf_s1_io_hpmevent_4[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[19] && pf_s1_io_hpmevent_4[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[20] && pf_s1_io_hpmevent_4[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[21] && pf_s1_io_hpmevent_4[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[22] && pf_s1_io_hpmevent_4[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[23] && pf_s1_io_hpmevent_4[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[24] && pf_s1_io_hpmevent_4[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[25] && pf_s1_io_hpmevent_4[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[26] && pf_s1_io_hpmevent_4[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[27] && pf_s1_io_hpmevent_4[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[28] && pf_s1_io_hpmevent_4[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[29] && pf_s1_io_hpmevent_4[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[30] && pf_s1_io_hpmevent_4[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[31] && pf_s1_io_hpmevent_4[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[32] && pf_s1_io_hpmevent_4[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[33] && pf_s1_io_hpmevent_4[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[34] && pf_s1_io_hpmevent_4[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[35] && pf_s1_io_hpmevent_4[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[36] && pf_s1_io_hpmevent_4[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[37] && pf_s1_io_hpmevent_4[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[38] && pf_s1_io_hpmevent_4[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[39] && pf_s1_io_hpmevent_4[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[40] && pf_s1_io_hpmevent_4[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[41] && pf_s1_io_hpmevent_4[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[42] && pf_s1_io_hpmevent_4[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[45] && pf_s1_io_hpmevent_4[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[46] && pf_s1_io_hpmevent_4[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[47] && pf_s1_io_hpmevent_4[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[50] && pf_s1_io_hpmevent_4[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[51] && pf_s1_io_hpmevent_4[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[52] && pf_s1_io_hpmevent_4[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[58] && pf_s1_io_hpmevent_4[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[59] && pf_s1_io_hpmevent_4[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[60] && pf_s1_io_hpmevent_4[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[61] && pf_s1_io_hpmevent_4[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[62] && pf_s1_io_hpmevent_4[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_4[63] && pf_s1_io_hpmevent_4[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_4[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[0] && pf_s1_io_hpmevent_5[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[1] && pf_s1_io_hpmevent_5[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[2] && pf_s1_io_hpmevent_5[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[3] && pf_s1_io_hpmevent_5[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[4] && pf_s1_io_hpmevent_5[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[5] && pf_s1_io_hpmevent_5[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[6] && pf_s1_io_hpmevent_5[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[7] && pf_s1_io_hpmevent_5[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[8] && pf_s1_io_hpmevent_5[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[9] && pf_s1_io_hpmevent_5[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[10] && pf_s1_io_hpmevent_5[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[11] && pf_s1_io_hpmevent_5[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[12] && pf_s1_io_hpmevent_5[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[13] && pf_s1_io_hpmevent_5[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[14] && pf_s1_io_hpmevent_5[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[15] && pf_s1_io_hpmevent_5[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[16] && pf_s1_io_hpmevent_5[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[17] && pf_s1_io_hpmevent_5[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[18] && pf_s1_io_hpmevent_5[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[19] && pf_s1_io_hpmevent_5[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[20] && pf_s1_io_hpmevent_5[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[21] && pf_s1_io_hpmevent_5[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[22] && pf_s1_io_hpmevent_5[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[23] && pf_s1_io_hpmevent_5[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[24] && pf_s1_io_hpmevent_5[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[25] && pf_s1_io_hpmevent_5[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[26] && pf_s1_io_hpmevent_5[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[27] && pf_s1_io_hpmevent_5[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[28] && pf_s1_io_hpmevent_5[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[29] && pf_s1_io_hpmevent_5[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[30] && pf_s1_io_hpmevent_5[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[31] && pf_s1_io_hpmevent_5[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[32] && pf_s1_io_hpmevent_5[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[33] && pf_s1_io_hpmevent_5[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[34] && pf_s1_io_hpmevent_5[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[35] && pf_s1_io_hpmevent_5[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[36] && pf_s1_io_hpmevent_5[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[37] && pf_s1_io_hpmevent_5[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[38] && pf_s1_io_hpmevent_5[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[39] && pf_s1_io_hpmevent_5[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[40] && pf_s1_io_hpmevent_5[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[41] && pf_s1_io_hpmevent_5[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[42] && pf_s1_io_hpmevent_5[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[45] && pf_s1_io_hpmevent_5[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[46] && pf_s1_io_hpmevent_5[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[47] && pf_s1_io_hpmevent_5[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[50] && pf_s1_io_hpmevent_5[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[51] && pf_s1_io_hpmevent_5[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[52] && pf_s1_io_hpmevent_5[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[58] && pf_s1_io_hpmevent_5[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[59] && pf_s1_io_hpmevent_5[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[60] && pf_s1_io_hpmevent_5[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[61] && pf_s1_io_hpmevent_5[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[62] && pf_s1_io_hpmevent_5[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_5[63] && pf_s1_io_hpmevent_5[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_5[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[0] && pf_s1_io_hpmevent_6[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[1] && pf_s1_io_hpmevent_6[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[2] && pf_s1_io_hpmevent_6[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[3] && pf_s1_io_hpmevent_6[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[4] && pf_s1_io_hpmevent_6[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[5] && pf_s1_io_hpmevent_6[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[6] && pf_s1_io_hpmevent_6[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[7] && pf_s1_io_hpmevent_6[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[8] && pf_s1_io_hpmevent_6[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[9] && pf_s1_io_hpmevent_6[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[10] && pf_s1_io_hpmevent_6[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[11] && pf_s1_io_hpmevent_6[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[12] && pf_s1_io_hpmevent_6[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[13] && pf_s1_io_hpmevent_6[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[14] && pf_s1_io_hpmevent_6[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[15] && pf_s1_io_hpmevent_6[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[16] && pf_s1_io_hpmevent_6[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[17] && pf_s1_io_hpmevent_6[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[18] && pf_s1_io_hpmevent_6[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[19] && pf_s1_io_hpmevent_6[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[20] && pf_s1_io_hpmevent_6[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[21] && pf_s1_io_hpmevent_6[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[22] && pf_s1_io_hpmevent_6[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[23] && pf_s1_io_hpmevent_6[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[24] && pf_s1_io_hpmevent_6[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[25] && pf_s1_io_hpmevent_6[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[26] && pf_s1_io_hpmevent_6[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[27] && pf_s1_io_hpmevent_6[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[28] && pf_s1_io_hpmevent_6[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[29] && pf_s1_io_hpmevent_6[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[30] && pf_s1_io_hpmevent_6[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[31] && pf_s1_io_hpmevent_6[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[32] && pf_s1_io_hpmevent_6[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[33] && pf_s1_io_hpmevent_6[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[34] && pf_s1_io_hpmevent_6[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[35] && pf_s1_io_hpmevent_6[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[36] && pf_s1_io_hpmevent_6[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[37] && pf_s1_io_hpmevent_6[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[38] && pf_s1_io_hpmevent_6[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[39] && pf_s1_io_hpmevent_6[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[40] && pf_s1_io_hpmevent_6[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[41] && pf_s1_io_hpmevent_6[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[42] && pf_s1_io_hpmevent_6[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[45] && pf_s1_io_hpmevent_6[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[46] && pf_s1_io_hpmevent_6[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[47] && pf_s1_io_hpmevent_6[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[50] && pf_s1_io_hpmevent_6[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[51] && pf_s1_io_hpmevent_6[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[52] && pf_s1_io_hpmevent_6[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[58] && pf_s1_io_hpmevent_6[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[59] && pf_s1_io_hpmevent_6[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[60] && pf_s1_io_hpmevent_6[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[61] && pf_s1_io_hpmevent_6[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[62] && pf_s1_io_hpmevent_6[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_6[63] && pf_s1_io_hpmevent_6[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_6[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[0] && pf_s1_io_hpmevent_7[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[1] && pf_s1_io_hpmevent_7[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[2] && pf_s1_io_hpmevent_7[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[3] && pf_s1_io_hpmevent_7[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[4] && pf_s1_io_hpmevent_7[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[5] && pf_s1_io_hpmevent_7[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[6] && pf_s1_io_hpmevent_7[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[7] && pf_s1_io_hpmevent_7[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[8] && pf_s1_io_hpmevent_7[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[9] && pf_s1_io_hpmevent_7[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[10] && pf_s1_io_hpmevent_7[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[11] && pf_s1_io_hpmevent_7[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[12] && pf_s1_io_hpmevent_7[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[13] && pf_s1_io_hpmevent_7[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[14] && pf_s1_io_hpmevent_7[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[15] && pf_s1_io_hpmevent_7[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[16] && pf_s1_io_hpmevent_7[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[17] && pf_s1_io_hpmevent_7[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[18] && pf_s1_io_hpmevent_7[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[19] && pf_s1_io_hpmevent_7[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[20] && pf_s1_io_hpmevent_7[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[21] && pf_s1_io_hpmevent_7[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[22] && pf_s1_io_hpmevent_7[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[23] && pf_s1_io_hpmevent_7[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[24] && pf_s1_io_hpmevent_7[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[25] && pf_s1_io_hpmevent_7[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[26] && pf_s1_io_hpmevent_7[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[27] && pf_s1_io_hpmevent_7[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[28] && pf_s1_io_hpmevent_7[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[29] && pf_s1_io_hpmevent_7[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[30] && pf_s1_io_hpmevent_7[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[31] && pf_s1_io_hpmevent_7[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[32] && pf_s1_io_hpmevent_7[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[33] && pf_s1_io_hpmevent_7[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[34] && pf_s1_io_hpmevent_7[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[35] && pf_s1_io_hpmevent_7[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[36] && pf_s1_io_hpmevent_7[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[37] && pf_s1_io_hpmevent_7[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[38] && pf_s1_io_hpmevent_7[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[39] && pf_s1_io_hpmevent_7[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[40] && pf_s1_io_hpmevent_7[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[41] && pf_s1_io_hpmevent_7[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[42] && pf_s1_io_hpmevent_7[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[45] && pf_s1_io_hpmevent_7[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[46] && pf_s1_io_hpmevent_7[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[47] && pf_s1_io_hpmevent_7[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[50] && pf_s1_io_hpmevent_7[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[51] && pf_s1_io_hpmevent_7[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[52] && pf_s1_io_hpmevent_7[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[58] && pf_s1_io_hpmevent_7[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[59] && pf_s1_io_hpmevent_7[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[60] && pf_s1_io_hpmevent_7[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[61] && pf_s1_io_hpmevent_7[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[62] && pf_s1_io_hpmevent_7[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_7[63] && pf_s1_io_hpmevent_7[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_7[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[0] && pf_s1_io_hpmevent_8[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[1] && pf_s1_io_hpmevent_8[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[2] && pf_s1_io_hpmevent_8[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[3] && pf_s1_io_hpmevent_8[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[4] && pf_s1_io_hpmevent_8[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[5] && pf_s1_io_hpmevent_8[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[6] && pf_s1_io_hpmevent_8[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[7] && pf_s1_io_hpmevent_8[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[8] && pf_s1_io_hpmevent_8[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[9] && pf_s1_io_hpmevent_8[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[10] && pf_s1_io_hpmevent_8[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[11] && pf_s1_io_hpmevent_8[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[12] && pf_s1_io_hpmevent_8[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[13] && pf_s1_io_hpmevent_8[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[14] && pf_s1_io_hpmevent_8[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[15] && pf_s1_io_hpmevent_8[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[16] && pf_s1_io_hpmevent_8[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[17] && pf_s1_io_hpmevent_8[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[18] && pf_s1_io_hpmevent_8[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[19] && pf_s1_io_hpmevent_8[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[20] && pf_s1_io_hpmevent_8[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[21] && pf_s1_io_hpmevent_8[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[22] && pf_s1_io_hpmevent_8[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[23] && pf_s1_io_hpmevent_8[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[24] && pf_s1_io_hpmevent_8[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[25] && pf_s1_io_hpmevent_8[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[26] && pf_s1_io_hpmevent_8[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[27] && pf_s1_io_hpmevent_8[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[28] && pf_s1_io_hpmevent_8[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[29] && pf_s1_io_hpmevent_8[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[30] && pf_s1_io_hpmevent_8[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[31] && pf_s1_io_hpmevent_8[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[32] && pf_s1_io_hpmevent_8[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[33] && pf_s1_io_hpmevent_8[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[34] && pf_s1_io_hpmevent_8[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[35] && pf_s1_io_hpmevent_8[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[36] && pf_s1_io_hpmevent_8[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[37] && pf_s1_io_hpmevent_8[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[38] && pf_s1_io_hpmevent_8[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[39] && pf_s1_io_hpmevent_8[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[40] && pf_s1_io_hpmevent_8[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[41] && pf_s1_io_hpmevent_8[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[42] && pf_s1_io_hpmevent_8[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[45] && pf_s1_io_hpmevent_8[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[46] && pf_s1_io_hpmevent_8[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[47] && pf_s1_io_hpmevent_8[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[50] && pf_s1_io_hpmevent_8[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[51] && pf_s1_io_hpmevent_8[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[52] && pf_s1_io_hpmevent_8[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[58] && pf_s1_io_hpmevent_8[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[59] && pf_s1_io_hpmevent_8[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[60] && pf_s1_io_hpmevent_8[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[61] && pf_s1_io_hpmevent_8[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[62] && pf_s1_io_hpmevent_8[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_8[63] && pf_s1_io_hpmevent_8[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_8[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[0] && pf_s1_io_hpmevent_9[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[1] && pf_s1_io_hpmevent_9[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[2] && pf_s1_io_hpmevent_9[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[3] && pf_s1_io_hpmevent_9[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[4] && pf_s1_io_hpmevent_9[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[5] && pf_s1_io_hpmevent_9[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[6] && pf_s1_io_hpmevent_9[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[7] && pf_s1_io_hpmevent_9[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[8] && pf_s1_io_hpmevent_9[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[9] && pf_s1_io_hpmevent_9[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[10] && pf_s1_io_hpmevent_9[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[11] && pf_s1_io_hpmevent_9[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[12] && pf_s1_io_hpmevent_9[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[13] && pf_s1_io_hpmevent_9[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[14] && pf_s1_io_hpmevent_9[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[15] && pf_s1_io_hpmevent_9[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[16] && pf_s1_io_hpmevent_9[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[17] && pf_s1_io_hpmevent_9[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[18] && pf_s1_io_hpmevent_9[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[19] && pf_s1_io_hpmevent_9[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[20] && pf_s1_io_hpmevent_9[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[21] && pf_s1_io_hpmevent_9[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[22] && pf_s1_io_hpmevent_9[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[23] && pf_s1_io_hpmevent_9[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[24] && pf_s1_io_hpmevent_9[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[25] && pf_s1_io_hpmevent_9[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[26] && pf_s1_io_hpmevent_9[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[27] && pf_s1_io_hpmevent_9[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[28] && pf_s1_io_hpmevent_9[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[29] && pf_s1_io_hpmevent_9[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[30] && pf_s1_io_hpmevent_9[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[31] && pf_s1_io_hpmevent_9[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[32] && pf_s1_io_hpmevent_9[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[33] && pf_s1_io_hpmevent_9[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[34] && pf_s1_io_hpmevent_9[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[35] && pf_s1_io_hpmevent_9[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[36] && pf_s1_io_hpmevent_9[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[37] && pf_s1_io_hpmevent_9[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[38] && pf_s1_io_hpmevent_9[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[39] && pf_s1_io_hpmevent_9[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[40] && pf_s1_io_hpmevent_9[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[41] && pf_s1_io_hpmevent_9[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[42] && pf_s1_io_hpmevent_9[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[45] && pf_s1_io_hpmevent_9[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[46] && pf_s1_io_hpmevent_9[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[47] && pf_s1_io_hpmevent_9[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[50] && pf_s1_io_hpmevent_9[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[51] && pf_s1_io_hpmevent_9[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[52] && pf_s1_io_hpmevent_9[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[58] && pf_s1_io_hpmevent_9[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[59] && pf_s1_io_hpmevent_9[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[60] && pf_s1_io_hpmevent_9[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[61] && pf_s1_io_hpmevent_9[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[62] && pf_s1_io_hpmevent_9[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_9[63] && pf_s1_io_hpmevent_9[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_9[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[0] && pf_s1_io_hpmevent_10[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[1] && pf_s1_io_hpmevent_10[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[2] && pf_s1_io_hpmevent_10[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[3] && pf_s1_io_hpmevent_10[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[4] && pf_s1_io_hpmevent_10[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[5] && pf_s1_io_hpmevent_10[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[6] && pf_s1_io_hpmevent_10[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[7] && pf_s1_io_hpmevent_10[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[8] && pf_s1_io_hpmevent_10[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[9] && pf_s1_io_hpmevent_10[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[10] && pf_s1_io_hpmevent_10[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[11] && pf_s1_io_hpmevent_10[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[12] && pf_s1_io_hpmevent_10[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[13] && pf_s1_io_hpmevent_10[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[14] && pf_s1_io_hpmevent_10[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[15] && pf_s1_io_hpmevent_10[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[16] && pf_s1_io_hpmevent_10[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[17] && pf_s1_io_hpmevent_10[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[18] && pf_s1_io_hpmevent_10[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[19] && pf_s1_io_hpmevent_10[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[20] && pf_s1_io_hpmevent_10[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[21] && pf_s1_io_hpmevent_10[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[22] && pf_s1_io_hpmevent_10[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[23] && pf_s1_io_hpmevent_10[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[24] && pf_s1_io_hpmevent_10[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[25] && pf_s1_io_hpmevent_10[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[26] && pf_s1_io_hpmevent_10[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[27] && pf_s1_io_hpmevent_10[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[28] && pf_s1_io_hpmevent_10[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[29] && pf_s1_io_hpmevent_10[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[30] && pf_s1_io_hpmevent_10[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[31] && pf_s1_io_hpmevent_10[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[32] && pf_s1_io_hpmevent_10[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[33] && pf_s1_io_hpmevent_10[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[34] && pf_s1_io_hpmevent_10[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[35] && pf_s1_io_hpmevent_10[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[36] && pf_s1_io_hpmevent_10[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[37] && pf_s1_io_hpmevent_10[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[38] && pf_s1_io_hpmevent_10[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[39] && pf_s1_io_hpmevent_10[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[40] && pf_s1_io_hpmevent_10[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[41] && pf_s1_io_hpmevent_10[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[42] && pf_s1_io_hpmevent_10[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[45] && pf_s1_io_hpmevent_10[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[46] && pf_s1_io_hpmevent_10[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[47] && pf_s1_io_hpmevent_10[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[50] && pf_s1_io_hpmevent_10[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[51] && pf_s1_io_hpmevent_10[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[52] && pf_s1_io_hpmevent_10[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[58] && pf_s1_io_hpmevent_10[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[59] && pf_s1_io_hpmevent_10[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[60] && pf_s1_io_hpmevent_10[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[61] && pf_s1_io_hpmevent_10[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[62] && pf_s1_io_hpmevent_10[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_10[63] && pf_s1_io_hpmevent_10[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_10[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[0] && pf_s1_io_hpmevent_11[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[1] && pf_s1_io_hpmevent_11[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[2] && pf_s1_io_hpmevent_11[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[3] && pf_s1_io_hpmevent_11[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[4] && pf_s1_io_hpmevent_11[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[5] && pf_s1_io_hpmevent_11[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[6] && pf_s1_io_hpmevent_11[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[7] && pf_s1_io_hpmevent_11[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[8] && pf_s1_io_hpmevent_11[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[9] && pf_s1_io_hpmevent_11[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[10] && pf_s1_io_hpmevent_11[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[11] && pf_s1_io_hpmevent_11[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[12] && pf_s1_io_hpmevent_11[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[13] && pf_s1_io_hpmevent_11[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[14] && pf_s1_io_hpmevent_11[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[15] && pf_s1_io_hpmevent_11[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[16] && pf_s1_io_hpmevent_11[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[17] && pf_s1_io_hpmevent_11[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[18] && pf_s1_io_hpmevent_11[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[19] && pf_s1_io_hpmevent_11[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[20] && pf_s1_io_hpmevent_11[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[21] && pf_s1_io_hpmevent_11[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[22] && pf_s1_io_hpmevent_11[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[23] && pf_s1_io_hpmevent_11[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[24] && pf_s1_io_hpmevent_11[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[25] && pf_s1_io_hpmevent_11[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[26] && pf_s1_io_hpmevent_11[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[27] && pf_s1_io_hpmevent_11[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[28] && pf_s1_io_hpmevent_11[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[29] && pf_s1_io_hpmevent_11[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[30] && pf_s1_io_hpmevent_11[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[31] && pf_s1_io_hpmevent_11[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[32] && pf_s1_io_hpmevent_11[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[33] && pf_s1_io_hpmevent_11[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[34] && pf_s1_io_hpmevent_11[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[35] && pf_s1_io_hpmevent_11[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[36] && pf_s1_io_hpmevent_11[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[37] && pf_s1_io_hpmevent_11[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[38] && pf_s1_io_hpmevent_11[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[39] && pf_s1_io_hpmevent_11[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[40] && pf_s1_io_hpmevent_11[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[41] && pf_s1_io_hpmevent_11[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[42] && pf_s1_io_hpmevent_11[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[45] && pf_s1_io_hpmevent_11[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[46] && pf_s1_io_hpmevent_11[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[47] && pf_s1_io_hpmevent_11[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[50] && pf_s1_io_hpmevent_11[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[51] && pf_s1_io_hpmevent_11[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[52] && pf_s1_io_hpmevent_11[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[58] && pf_s1_io_hpmevent_11[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[59] && pf_s1_io_hpmevent_11[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[60] && pf_s1_io_hpmevent_11[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[61] && pf_s1_io_hpmevent_11[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[62] && pf_s1_io_hpmevent_11[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_11[63] && pf_s1_io_hpmevent_11[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_11[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[0] && pf_s1_io_hpmevent_12[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[1] && pf_s1_io_hpmevent_12[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[2] && pf_s1_io_hpmevent_12[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[3] && pf_s1_io_hpmevent_12[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[4] && pf_s1_io_hpmevent_12[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[5] && pf_s1_io_hpmevent_12[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[6] && pf_s1_io_hpmevent_12[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[7] && pf_s1_io_hpmevent_12[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[8] && pf_s1_io_hpmevent_12[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[9] && pf_s1_io_hpmevent_12[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[10] && pf_s1_io_hpmevent_12[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[11] && pf_s1_io_hpmevent_12[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[12] && pf_s1_io_hpmevent_12[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[13] && pf_s1_io_hpmevent_12[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[14] && pf_s1_io_hpmevent_12[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[15] && pf_s1_io_hpmevent_12[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[16] && pf_s1_io_hpmevent_12[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[17] && pf_s1_io_hpmevent_12[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[18] && pf_s1_io_hpmevent_12[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[19] && pf_s1_io_hpmevent_12[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[20] && pf_s1_io_hpmevent_12[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[21] && pf_s1_io_hpmevent_12[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[22] && pf_s1_io_hpmevent_12[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[23] && pf_s1_io_hpmevent_12[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[24] && pf_s1_io_hpmevent_12[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[25] && pf_s1_io_hpmevent_12[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[26] && pf_s1_io_hpmevent_12[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[27] && pf_s1_io_hpmevent_12[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[28] && pf_s1_io_hpmevent_12[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[29] && pf_s1_io_hpmevent_12[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[30] && pf_s1_io_hpmevent_12[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[31] && pf_s1_io_hpmevent_12[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[32] && pf_s1_io_hpmevent_12[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[33] && pf_s1_io_hpmevent_12[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[34] && pf_s1_io_hpmevent_12[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[35] && pf_s1_io_hpmevent_12[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[36] && pf_s1_io_hpmevent_12[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[37] && pf_s1_io_hpmevent_12[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[38] && pf_s1_io_hpmevent_12[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[39] && pf_s1_io_hpmevent_12[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[40] && pf_s1_io_hpmevent_12[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[41] && pf_s1_io_hpmevent_12[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[42] && pf_s1_io_hpmevent_12[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[45] && pf_s1_io_hpmevent_12[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[46] && pf_s1_io_hpmevent_12[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[47] && pf_s1_io_hpmevent_12[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[50] && pf_s1_io_hpmevent_12[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[51] && pf_s1_io_hpmevent_12[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[52] && pf_s1_io_hpmevent_12[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[58] && pf_s1_io_hpmevent_12[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[59] && pf_s1_io_hpmevent_12[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[60] && pf_s1_io_hpmevent_12[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[61] && pf_s1_io_hpmevent_12[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[62] && pf_s1_io_hpmevent_12[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_12[63] && pf_s1_io_hpmevent_12[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_12[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[0] && pf_s1_io_hpmevent_13[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[1] && pf_s1_io_hpmevent_13[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[2] && pf_s1_io_hpmevent_13[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[3] && pf_s1_io_hpmevent_13[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[4] && pf_s1_io_hpmevent_13[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[5] && pf_s1_io_hpmevent_13[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[6] && pf_s1_io_hpmevent_13[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[7] && pf_s1_io_hpmevent_13[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[8] && pf_s1_io_hpmevent_13[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[9] && pf_s1_io_hpmevent_13[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[10] && pf_s1_io_hpmevent_13[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[11] && pf_s1_io_hpmevent_13[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[12] && pf_s1_io_hpmevent_13[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[13] && pf_s1_io_hpmevent_13[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[14] && pf_s1_io_hpmevent_13[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[15] && pf_s1_io_hpmevent_13[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[16] && pf_s1_io_hpmevent_13[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[17] && pf_s1_io_hpmevent_13[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[18] && pf_s1_io_hpmevent_13[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[19] && pf_s1_io_hpmevent_13[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[20] && pf_s1_io_hpmevent_13[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[21] && pf_s1_io_hpmevent_13[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[22] && pf_s1_io_hpmevent_13[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[23] && pf_s1_io_hpmevent_13[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[24] && pf_s1_io_hpmevent_13[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[25] && pf_s1_io_hpmevent_13[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[26] && pf_s1_io_hpmevent_13[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[27] && pf_s1_io_hpmevent_13[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[28] && pf_s1_io_hpmevent_13[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[29] && pf_s1_io_hpmevent_13[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[30] && pf_s1_io_hpmevent_13[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[31] && pf_s1_io_hpmevent_13[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[32] && pf_s1_io_hpmevent_13[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[33] && pf_s1_io_hpmevent_13[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[34] && pf_s1_io_hpmevent_13[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[35] && pf_s1_io_hpmevent_13[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[36] && pf_s1_io_hpmevent_13[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[37] && pf_s1_io_hpmevent_13[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[38] && pf_s1_io_hpmevent_13[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[39] && pf_s1_io_hpmevent_13[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[40] && pf_s1_io_hpmevent_13[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[41] && pf_s1_io_hpmevent_13[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[42] && pf_s1_io_hpmevent_13[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[45] && pf_s1_io_hpmevent_13[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[46] && pf_s1_io_hpmevent_13[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[47] && pf_s1_io_hpmevent_13[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[50] && pf_s1_io_hpmevent_13[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[51] && pf_s1_io_hpmevent_13[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[52] && pf_s1_io_hpmevent_13[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[58] && pf_s1_io_hpmevent_13[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[59] && pf_s1_io_hpmevent_13[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[60] && pf_s1_io_hpmevent_13[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[61] && pf_s1_io_hpmevent_13[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[62] && pf_s1_io_hpmevent_13[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_13[63] && pf_s1_io_hpmevent_13[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_13[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[0] && pf_s1_io_hpmevent_14[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[1] && pf_s1_io_hpmevent_14[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[2] && pf_s1_io_hpmevent_14[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[3] && pf_s1_io_hpmevent_14[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[4] && pf_s1_io_hpmevent_14[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[5] && pf_s1_io_hpmevent_14[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[6] && pf_s1_io_hpmevent_14[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[7] && pf_s1_io_hpmevent_14[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[8] && pf_s1_io_hpmevent_14[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[9] && pf_s1_io_hpmevent_14[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[10] && pf_s1_io_hpmevent_14[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[11] && pf_s1_io_hpmevent_14[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[12] && pf_s1_io_hpmevent_14[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[13] && pf_s1_io_hpmevent_14[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[14] && pf_s1_io_hpmevent_14[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[15] && pf_s1_io_hpmevent_14[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[16] && pf_s1_io_hpmevent_14[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[17] && pf_s1_io_hpmevent_14[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[18] && pf_s1_io_hpmevent_14[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[19] && pf_s1_io_hpmevent_14[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[20] && pf_s1_io_hpmevent_14[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[21] && pf_s1_io_hpmevent_14[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[22] && pf_s1_io_hpmevent_14[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[23] && pf_s1_io_hpmevent_14[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[24] && pf_s1_io_hpmevent_14[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[25] && pf_s1_io_hpmevent_14[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[26] && pf_s1_io_hpmevent_14[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[27] && pf_s1_io_hpmevent_14[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[28] && pf_s1_io_hpmevent_14[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[29] && pf_s1_io_hpmevent_14[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[30] && pf_s1_io_hpmevent_14[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[31] && pf_s1_io_hpmevent_14[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[32] && pf_s1_io_hpmevent_14[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[33] && pf_s1_io_hpmevent_14[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[34] && pf_s1_io_hpmevent_14[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[35] && pf_s1_io_hpmevent_14[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[36] && pf_s1_io_hpmevent_14[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[37] && pf_s1_io_hpmevent_14[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[38] && pf_s1_io_hpmevent_14[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[39] && pf_s1_io_hpmevent_14[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[40] && pf_s1_io_hpmevent_14[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[41] && pf_s1_io_hpmevent_14[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[42] && pf_s1_io_hpmevent_14[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[45] && pf_s1_io_hpmevent_14[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[46] && pf_s1_io_hpmevent_14[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[47] && pf_s1_io_hpmevent_14[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[50] && pf_s1_io_hpmevent_14[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[51] && pf_s1_io_hpmevent_14[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[52] && pf_s1_io_hpmevent_14[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[58] && pf_s1_io_hpmevent_14[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[59] && pf_s1_io_hpmevent_14[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[60] && pf_s1_io_hpmevent_14[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[61] && pf_s1_io_hpmevent_14[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[62] && pf_s1_io_hpmevent_14[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_14[63] && pf_s1_io_hpmevent_14[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_14[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[0] && pf_s1_io_hpmevent_15[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[1] && pf_s1_io_hpmevent_15[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[2] && pf_s1_io_hpmevent_15[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[3] && pf_s1_io_hpmevent_15[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[4] && pf_s1_io_hpmevent_15[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[5] && pf_s1_io_hpmevent_15[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[6] && pf_s1_io_hpmevent_15[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[7] && pf_s1_io_hpmevent_15[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[8] && pf_s1_io_hpmevent_15[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[9] && pf_s1_io_hpmevent_15[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[10] && pf_s1_io_hpmevent_15[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[11] && pf_s1_io_hpmevent_15[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[12] && pf_s1_io_hpmevent_15[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[13] && pf_s1_io_hpmevent_15[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[14] && pf_s1_io_hpmevent_15[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[15] && pf_s1_io_hpmevent_15[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[16] && pf_s1_io_hpmevent_15[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[17] && pf_s1_io_hpmevent_15[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[18] && pf_s1_io_hpmevent_15[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[19] && pf_s1_io_hpmevent_15[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[20] && pf_s1_io_hpmevent_15[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[21] && pf_s1_io_hpmevent_15[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[22] && pf_s1_io_hpmevent_15[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[23] && pf_s1_io_hpmevent_15[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[24] && pf_s1_io_hpmevent_15[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[25] && pf_s1_io_hpmevent_15[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[26] && pf_s1_io_hpmevent_15[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[27] && pf_s1_io_hpmevent_15[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[28] && pf_s1_io_hpmevent_15[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[29] && pf_s1_io_hpmevent_15[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[30] && pf_s1_io_hpmevent_15[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[31] && pf_s1_io_hpmevent_15[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[32] && pf_s1_io_hpmevent_15[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[33] && pf_s1_io_hpmevent_15[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[34] && pf_s1_io_hpmevent_15[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[35] && pf_s1_io_hpmevent_15[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[36] && pf_s1_io_hpmevent_15[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[37] && pf_s1_io_hpmevent_15[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[38] && pf_s1_io_hpmevent_15[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[39] && pf_s1_io_hpmevent_15[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[40] && pf_s1_io_hpmevent_15[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[41] && pf_s1_io_hpmevent_15[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[42] && pf_s1_io_hpmevent_15[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[45] && pf_s1_io_hpmevent_15[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[46] && pf_s1_io_hpmevent_15[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[47] && pf_s1_io_hpmevent_15[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[50] && pf_s1_io_hpmevent_15[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[51] && pf_s1_io_hpmevent_15[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[52] && pf_s1_io_hpmevent_15[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[58] && pf_s1_io_hpmevent_15[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[59] && pf_s1_io_hpmevent_15[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[60] && pf_s1_io_hpmevent_15[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[61] && pf_s1_io_hpmevent_15[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[62] && pf_s1_io_hpmevent_15[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_15[63] && pf_s1_io_hpmevent_15[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_15[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[0] && pf_s1_io_hpmevent_16[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[1] && pf_s1_io_hpmevent_16[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[2] && pf_s1_io_hpmevent_16[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[3] && pf_s1_io_hpmevent_16[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[4] && pf_s1_io_hpmevent_16[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[5] && pf_s1_io_hpmevent_16[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[6] && pf_s1_io_hpmevent_16[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[7] && pf_s1_io_hpmevent_16[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[8] && pf_s1_io_hpmevent_16[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[9] && pf_s1_io_hpmevent_16[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[10] && pf_s1_io_hpmevent_16[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[11] && pf_s1_io_hpmevent_16[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[12] && pf_s1_io_hpmevent_16[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[13] && pf_s1_io_hpmevent_16[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[14] && pf_s1_io_hpmevent_16[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[15] && pf_s1_io_hpmevent_16[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[16] && pf_s1_io_hpmevent_16[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[17] && pf_s1_io_hpmevent_16[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[18] && pf_s1_io_hpmevent_16[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[19] && pf_s1_io_hpmevent_16[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[20] && pf_s1_io_hpmevent_16[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[21] && pf_s1_io_hpmevent_16[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[22] && pf_s1_io_hpmevent_16[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[23] && pf_s1_io_hpmevent_16[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[24] && pf_s1_io_hpmevent_16[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[25] && pf_s1_io_hpmevent_16[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[26] && pf_s1_io_hpmevent_16[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[27] && pf_s1_io_hpmevent_16[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[28] && pf_s1_io_hpmevent_16[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[29] && pf_s1_io_hpmevent_16[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[30] && pf_s1_io_hpmevent_16[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[31] && pf_s1_io_hpmevent_16[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[32] && pf_s1_io_hpmevent_16[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[33] && pf_s1_io_hpmevent_16[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[34] && pf_s1_io_hpmevent_16[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[35] && pf_s1_io_hpmevent_16[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[36] && pf_s1_io_hpmevent_16[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[37] && pf_s1_io_hpmevent_16[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[38] && pf_s1_io_hpmevent_16[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[39] && pf_s1_io_hpmevent_16[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[40] && pf_s1_io_hpmevent_16[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[41] && pf_s1_io_hpmevent_16[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[42] && pf_s1_io_hpmevent_16[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[45] && pf_s1_io_hpmevent_16[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[46] && pf_s1_io_hpmevent_16[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[47] && pf_s1_io_hpmevent_16[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[50] && pf_s1_io_hpmevent_16[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[51] && pf_s1_io_hpmevent_16[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[52] && pf_s1_io_hpmevent_16[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[58] && pf_s1_io_hpmevent_16[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[59] && pf_s1_io_hpmevent_16[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[60] && pf_s1_io_hpmevent_16[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[61] && pf_s1_io_hpmevent_16[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[62] && pf_s1_io_hpmevent_16[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_16[63] && pf_s1_io_hpmevent_16[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_16[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[0] && pf_s1_io_hpmevent_17[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[1] && pf_s1_io_hpmevent_17[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[2] && pf_s1_io_hpmevent_17[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[3] && pf_s1_io_hpmevent_17[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[4] && pf_s1_io_hpmevent_17[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[5] && pf_s1_io_hpmevent_17[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[6] && pf_s1_io_hpmevent_17[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[7] && pf_s1_io_hpmevent_17[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[8] && pf_s1_io_hpmevent_17[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[9] && pf_s1_io_hpmevent_17[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[10] && pf_s1_io_hpmevent_17[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[11] && pf_s1_io_hpmevent_17[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[12] && pf_s1_io_hpmevent_17[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[13] && pf_s1_io_hpmevent_17[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[14] && pf_s1_io_hpmevent_17[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[15] && pf_s1_io_hpmevent_17[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[16] && pf_s1_io_hpmevent_17[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[17] && pf_s1_io_hpmevent_17[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[18] && pf_s1_io_hpmevent_17[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[19] && pf_s1_io_hpmevent_17[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[20] && pf_s1_io_hpmevent_17[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[21] && pf_s1_io_hpmevent_17[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[22] && pf_s1_io_hpmevent_17[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[23] && pf_s1_io_hpmevent_17[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[24] && pf_s1_io_hpmevent_17[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[25] && pf_s1_io_hpmevent_17[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[26] && pf_s1_io_hpmevent_17[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[27] && pf_s1_io_hpmevent_17[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[28] && pf_s1_io_hpmevent_17[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[29] && pf_s1_io_hpmevent_17[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[30] && pf_s1_io_hpmevent_17[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[31] && pf_s1_io_hpmevent_17[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[32] && pf_s1_io_hpmevent_17[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[33] && pf_s1_io_hpmevent_17[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[34] && pf_s1_io_hpmevent_17[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[35] && pf_s1_io_hpmevent_17[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[36] && pf_s1_io_hpmevent_17[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[37] && pf_s1_io_hpmevent_17[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[38] && pf_s1_io_hpmevent_17[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[39] && pf_s1_io_hpmevent_17[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[40] && pf_s1_io_hpmevent_17[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[41] && pf_s1_io_hpmevent_17[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[42] && pf_s1_io_hpmevent_17[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[45] && pf_s1_io_hpmevent_17[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[46] && pf_s1_io_hpmevent_17[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[47] && pf_s1_io_hpmevent_17[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[50] && pf_s1_io_hpmevent_17[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[51] && pf_s1_io_hpmevent_17[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[52] && pf_s1_io_hpmevent_17[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[58] && pf_s1_io_hpmevent_17[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[59] && pf_s1_io_hpmevent_17[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[60] && pf_s1_io_hpmevent_17[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[61] && pf_s1_io_hpmevent_17[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[62] && pf_s1_io_hpmevent_17[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_17[63] && pf_s1_io_hpmevent_17[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_17[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[0] && pf_s1_io_hpmevent_18[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[1] && pf_s1_io_hpmevent_18[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[2] && pf_s1_io_hpmevent_18[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[3] && pf_s1_io_hpmevent_18[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[4] && pf_s1_io_hpmevent_18[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[5] && pf_s1_io_hpmevent_18[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[6] && pf_s1_io_hpmevent_18[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[7] && pf_s1_io_hpmevent_18[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[8] && pf_s1_io_hpmevent_18[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[9] && pf_s1_io_hpmevent_18[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[10] && pf_s1_io_hpmevent_18[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[11] && pf_s1_io_hpmevent_18[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[12] && pf_s1_io_hpmevent_18[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[13] && pf_s1_io_hpmevent_18[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[14] && pf_s1_io_hpmevent_18[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[15] && pf_s1_io_hpmevent_18[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[16] && pf_s1_io_hpmevent_18[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[17] && pf_s1_io_hpmevent_18[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[18] && pf_s1_io_hpmevent_18[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[19] && pf_s1_io_hpmevent_18[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[20] && pf_s1_io_hpmevent_18[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[21] && pf_s1_io_hpmevent_18[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[22] && pf_s1_io_hpmevent_18[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[23] && pf_s1_io_hpmevent_18[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[24] && pf_s1_io_hpmevent_18[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[25] && pf_s1_io_hpmevent_18[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[26] && pf_s1_io_hpmevent_18[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[27] && pf_s1_io_hpmevent_18[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[28] && pf_s1_io_hpmevent_18[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[29] && pf_s1_io_hpmevent_18[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[30] && pf_s1_io_hpmevent_18[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[31] && pf_s1_io_hpmevent_18[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[32] && pf_s1_io_hpmevent_18[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[33] && pf_s1_io_hpmevent_18[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[34] && pf_s1_io_hpmevent_18[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[35] && pf_s1_io_hpmevent_18[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[36] && pf_s1_io_hpmevent_18[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[37] && pf_s1_io_hpmevent_18[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[38] && pf_s1_io_hpmevent_18[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[39] && pf_s1_io_hpmevent_18[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[40] && pf_s1_io_hpmevent_18[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[41] && pf_s1_io_hpmevent_18[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[42] && pf_s1_io_hpmevent_18[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[45] && pf_s1_io_hpmevent_18[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[46] && pf_s1_io_hpmevent_18[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[47] && pf_s1_io_hpmevent_18[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[50] && pf_s1_io_hpmevent_18[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[51] && pf_s1_io_hpmevent_18[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[52] && pf_s1_io_hpmevent_18[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[58] && pf_s1_io_hpmevent_18[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[59] && pf_s1_io_hpmevent_18[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[60] && pf_s1_io_hpmevent_18[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[61] && pf_s1_io_hpmevent_18[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[62] && pf_s1_io_hpmevent_18[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_18[63] && pf_s1_io_hpmevent_18[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_18[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[0] && pf_s1_io_hpmevent_19[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[1] && pf_s1_io_hpmevent_19[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[2] && pf_s1_io_hpmevent_19[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[3] && pf_s1_io_hpmevent_19[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[4] && pf_s1_io_hpmevent_19[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[5] && pf_s1_io_hpmevent_19[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[6] && pf_s1_io_hpmevent_19[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[7] && pf_s1_io_hpmevent_19[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[8] && pf_s1_io_hpmevent_19[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[9] && pf_s1_io_hpmevent_19[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[10] && pf_s1_io_hpmevent_19[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[11] && pf_s1_io_hpmevent_19[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[12] && pf_s1_io_hpmevent_19[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[13] && pf_s1_io_hpmevent_19[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[14] && pf_s1_io_hpmevent_19[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[15] && pf_s1_io_hpmevent_19[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[16] && pf_s1_io_hpmevent_19[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[17] && pf_s1_io_hpmevent_19[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[18] && pf_s1_io_hpmevent_19[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[19] && pf_s1_io_hpmevent_19[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[20] && pf_s1_io_hpmevent_19[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[21] && pf_s1_io_hpmevent_19[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[22] && pf_s1_io_hpmevent_19[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[23] && pf_s1_io_hpmevent_19[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[24] && pf_s1_io_hpmevent_19[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[25] && pf_s1_io_hpmevent_19[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[26] && pf_s1_io_hpmevent_19[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[27] && pf_s1_io_hpmevent_19[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[28] && pf_s1_io_hpmevent_19[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[29] && pf_s1_io_hpmevent_19[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[30] && pf_s1_io_hpmevent_19[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[31] && pf_s1_io_hpmevent_19[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[32] && pf_s1_io_hpmevent_19[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[33] && pf_s1_io_hpmevent_19[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[34] && pf_s1_io_hpmevent_19[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[35] && pf_s1_io_hpmevent_19[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[36] && pf_s1_io_hpmevent_19[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[37] && pf_s1_io_hpmevent_19[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[38] && pf_s1_io_hpmevent_19[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[39] && pf_s1_io_hpmevent_19[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[40] && pf_s1_io_hpmevent_19[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[41] && pf_s1_io_hpmevent_19[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[42] && pf_s1_io_hpmevent_19[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[45] && pf_s1_io_hpmevent_19[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[46] && pf_s1_io_hpmevent_19[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[47] && pf_s1_io_hpmevent_19[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[50] && pf_s1_io_hpmevent_19[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[51] && pf_s1_io_hpmevent_19[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[52] && pf_s1_io_hpmevent_19[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[58] && pf_s1_io_hpmevent_19[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[59] && pf_s1_io_hpmevent_19[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[60] && pf_s1_io_hpmevent_19[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[61] && pf_s1_io_hpmevent_19[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[62] && pf_s1_io_hpmevent_19[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_19[63] && pf_s1_io_hpmevent_19[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_19[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[0] && pf_s1_io_hpmevent_20[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[1] && pf_s1_io_hpmevent_20[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[2] && pf_s1_io_hpmevent_20[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[3] && pf_s1_io_hpmevent_20[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[4] && pf_s1_io_hpmevent_20[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[5] && pf_s1_io_hpmevent_20[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[6] && pf_s1_io_hpmevent_20[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[7] && pf_s1_io_hpmevent_20[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[8] && pf_s1_io_hpmevent_20[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[9] && pf_s1_io_hpmevent_20[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[10] && pf_s1_io_hpmevent_20[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[11] && pf_s1_io_hpmevent_20[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[12] && pf_s1_io_hpmevent_20[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[13] && pf_s1_io_hpmevent_20[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[14] && pf_s1_io_hpmevent_20[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[15] && pf_s1_io_hpmevent_20[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[16] && pf_s1_io_hpmevent_20[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[17] && pf_s1_io_hpmevent_20[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[18] && pf_s1_io_hpmevent_20[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[19] && pf_s1_io_hpmevent_20[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[20] && pf_s1_io_hpmevent_20[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[21] && pf_s1_io_hpmevent_20[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[22] && pf_s1_io_hpmevent_20[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[23] && pf_s1_io_hpmevent_20[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[24] && pf_s1_io_hpmevent_20[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[25] && pf_s1_io_hpmevent_20[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[26] && pf_s1_io_hpmevent_20[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[27] && pf_s1_io_hpmevent_20[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[28] && pf_s1_io_hpmevent_20[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[29] && pf_s1_io_hpmevent_20[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[30] && pf_s1_io_hpmevent_20[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[31] && pf_s1_io_hpmevent_20[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[32] && pf_s1_io_hpmevent_20[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[33] && pf_s1_io_hpmevent_20[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[34] && pf_s1_io_hpmevent_20[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[35] && pf_s1_io_hpmevent_20[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[36] && pf_s1_io_hpmevent_20[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[37] && pf_s1_io_hpmevent_20[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[38] && pf_s1_io_hpmevent_20[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[39] && pf_s1_io_hpmevent_20[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[40] && pf_s1_io_hpmevent_20[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[41] && pf_s1_io_hpmevent_20[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[42] && pf_s1_io_hpmevent_20[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[45] && pf_s1_io_hpmevent_20[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[46] && pf_s1_io_hpmevent_20[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[47] && pf_s1_io_hpmevent_20[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[50] && pf_s1_io_hpmevent_20[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[51] && pf_s1_io_hpmevent_20[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[52] && pf_s1_io_hpmevent_20[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[58] && pf_s1_io_hpmevent_20[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[59] && pf_s1_io_hpmevent_20[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[60] && pf_s1_io_hpmevent_20[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[61] && pf_s1_io_hpmevent_20[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[62] && pf_s1_io_hpmevent_20[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_20[63] && pf_s1_io_hpmevent_20[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_20[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[0] && pf_s1_io_hpmevent_21[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[1] && pf_s1_io_hpmevent_21[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[2] && pf_s1_io_hpmevent_21[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[3] && pf_s1_io_hpmevent_21[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[4] && pf_s1_io_hpmevent_21[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[5] && pf_s1_io_hpmevent_21[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[6] && pf_s1_io_hpmevent_21[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[7] && pf_s1_io_hpmevent_21[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[8] && pf_s1_io_hpmevent_21[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[9] && pf_s1_io_hpmevent_21[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[10] && pf_s1_io_hpmevent_21[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[11] && pf_s1_io_hpmevent_21[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[12] && pf_s1_io_hpmevent_21[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[13] && pf_s1_io_hpmevent_21[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[14] && pf_s1_io_hpmevent_21[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[15] && pf_s1_io_hpmevent_21[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[16] && pf_s1_io_hpmevent_21[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[17] && pf_s1_io_hpmevent_21[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[18] && pf_s1_io_hpmevent_21[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[19] && pf_s1_io_hpmevent_21[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[20] && pf_s1_io_hpmevent_21[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[21] && pf_s1_io_hpmevent_21[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[22] && pf_s1_io_hpmevent_21[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[23] && pf_s1_io_hpmevent_21[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[24] && pf_s1_io_hpmevent_21[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[25] && pf_s1_io_hpmevent_21[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[26] && pf_s1_io_hpmevent_21[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[27] && pf_s1_io_hpmevent_21[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[28] && pf_s1_io_hpmevent_21[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[29] && pf_s1_io_hpmevent_21[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[30] && pf_s1_io_hpmevent_21[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[31] && pf_s1_io_hpmevent_21[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[32] && pf_s1_io_hpmevent_21[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[33] && pf_s1_io_hpmevent_21[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[34] && pf_s1_io_hpmevent_21[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[35] && pf_s1_io_hpmevent_21[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[36] && pf_s1_io_hpmevent_21[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[37] && pf_s1_io_hpmevent_21[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[38] && pf_s1_io_hpmevent_21[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[39] && pf_s1_io_hpmevent_21[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[40] && pf_s1_io_hpmevent_21[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[41] && pf_s1_io_hpmevent_21[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[42] && pf_s1_io_hpmevent_21[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[45] && pf_s1_io_hpmevent_21[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[46] && pf_s1_io_hpmevent_21[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[47] && pf_s1_io_hpmevent_21[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[50] && pf_s1_io_hpmevent_21[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[51] && pf_s1_io_hpmevent_21[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[52] && pf_s1_io_hpmevent_21[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[58] && pf_s1_io_hpmevent_21[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[59] && pf_s1_io_hpmevent_21[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[60] && pf_s1_io_hpmevent_21[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[61] && pf_s1_io_hpmevent_21[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[62] && pf_s1_io_hpmevent_21[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_21[63] && pf_s1_io_hpmevent_21[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_21[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[0] && pf_s1_io_hpmevent_22[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[1] && pf_s1_io_hpmevent_22[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[2] && pf_s1_io_hpmevent_22[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[3] && pf_s1_io_hpmevent_22[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[4] && pf_s1_io_hpmevent_22[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[5] && pf_s1_io_hpmevent_22[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[6] && pf_s1_io_hpmevent_22[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[7] && pf_s1_io_hpmevent_22[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[8] && pf_s1_io_hpmevent_22[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[9] && pf_s1_io_hpmevent_22[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[10] && pf_s1_io_hpmevent_22[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[11] && pf_s1_io_hpmevent_22[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[12] && pf_s1_io_hpmevent_22[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[13] && pf_s1_io_hpmevent_22[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[14] && pf_s1_io_hpmevent_22[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[15] && pf_s1_io_hpmevent_22[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[16] && pf_s1_io_hpmevent_22[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[17] && pf_s1_io_hpmevent_22[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[18] && pf_s1_io_hpmevent_22[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[19] && pf_s1_io_hpmevent_22[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[20] && pf_s1_io_hpmevent_22[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[21] && pf_s1_io_hpmevent_22[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[22] && pf_s1_io_hpmevent_22[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[23] && pf_s1_io_hpmevent_22[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[24] && pf_s1_io_hpmevent_22[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[25] && pf_s1_io_hpmevent_22[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[26] && pf_s1_io_hpmevent_22[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[27] && pf_s1_io_hpmevent_22[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[28] && pf_s1_io_hpmevent_22[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[29] && pf_s1_io_hpmevent_22[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[30] && pf_s1_io_hpmevent_22[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[31] && pf_s1_io_hpmevent_22[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[32] && pf_s1_io_hpmevent_22[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[33] && pf_s1_io_hpmevent_22[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[34] && pf_s1_io_hpmevent_22[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[35] && pf_s1_io_hpmevent_22[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[36] && pf_s1_io_hpmevent_22[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[37] && pf_s1_io_hpmevent_22[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[38] && pf_s1_io_hpmevent_22[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[39] && pf_s1_io_hpmevent_22[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[40] && pf_s1_io_hpmevent_22[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[41] && pf_s1_io_hpmevent_22[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[42] && pf_s1_io_hpmevent_22[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[45] && pf_s1_io_hpmevent_22[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[46] && pf_s1_io_hpmevent_22[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[47] && pf_s1_io_hpmevent_22[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[50] && pf_s1_io_hpmevent_22[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[51] && pf_s1_io_hpmevent_22[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[52] && pf_s1_io_hpmevent_22[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[58] && pf_s1_io_hpmevent_22[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[59] && pf_s1_io_hpmevent_22[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[60] && pf_s1_io_hpmevent_22[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[61] && pf_s1_io_hpmevent_22[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[62] && pf_s1_io_hpmevent_22[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_22[63] && pf_s1_io_hpmevent_22[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_22[63] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[0] && pf_s1_io_hpmevent_23[0])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[0] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[1] && pf_s1_io_hpmevent_23[1])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[1] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[2] && pf_s1_io_hpmevent_23[2])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[2] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[3] && pf_s1_io_hpmevent_23[3])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[3] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[4] && pf_s1_io_hpmevent_23[4])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[4] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[5] && pf_s1_io_hpmevent_23[5])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[5] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[6] && pf_s1_io_hpmevent_23[6])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[6] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[7] && pf_s1_io_hpmevent_23[7])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[7] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[8] && pf_s1_io_hpmevent_23[8])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[8] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[9] && pf_s1_io_hpmevent_23[9])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[9] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[10] && pf_s1_io_hpmevent_23[10])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[10] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[11] && pf_s1_io_hpmevent_23[11])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[11] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[12] && pf_s1_io_hpmevent_23[12])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[12] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[13] && pf_s1_io_hpmevent_23[13])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[13] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[14] && pf_s1_io_hpmevent_23[14])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[14] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[15] && pf_s1_io_hpmevent_23[15])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[15] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[16] && pf_s1_io_hpmevent_23[16])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[16] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[17] && pf_s1_io_hpmevent_23[17])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[17] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[18] && pf_s1_io_hpmevent_23[18])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[18] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[19] && pf_s1_io_hpmevent_23[19])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[19] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[20] && pf_s1_io_hpmevent_23[20])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[20] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[21] && pf_s1_io_hpmevent_23[21])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[21] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[22] && pf_s1_io_hpmevent_23[22])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[22] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[23] && pf_s1_io_hpmevent_23[23])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[23] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[24] && pf_s1_io_hpmevent_23[24])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[24] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[25] && pf_s1_io_hpmevent_23[25])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[25] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[26] && pf_s1_io_hpmevent_23[26])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[26] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[27] && pf_s1_io_hpmevent_23[27])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[27] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[28] && pf_s1_io_hpmevent_23[28])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[28] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[29] && pf_s1_io_hpmevent_23[29])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[29] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[30] && pf_s1_io_hpmevent_23[30])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[30] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[31] && pf_s1_io_hpmevent_23[31])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[31] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[32] && pf_s1_io_hpmevent_23[32])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[32] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[33] && pf_s1_io_hpmevent_23[33])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[33] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[34] && pf_s1_io_hpmevent_23[34])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[34] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[35] && pf_s1_io_hpmevent_23[35])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[35] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[36] && pf_s1_io_hpmevent_23[36])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[36] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[37] && pf_s1_io_hpmevent_23[37])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[37] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[38] && pf_s1_io_hpmevent_23[38])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[38] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[39] && pf_s1_io_hpmevent_23[39])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[39] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[40] && pf_s1_io_hpmevent_23[40])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[40] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[41] && pf_s1_io_hpmevent_23[41])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[41] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[42] && pf_s1_io_hpmevent_23[42])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[42] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[45] && pf_s1_io_hpmevent_23[45])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[45] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[46] && pf_s1_io_hpmevent_23[46])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[46] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[47] && pf_s1_io_hpmevent_23[47])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[47] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[50] && pf_s1_io_hpmevent_23[50])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[50] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[51] && pf_s1_io_hpmevent_23[51])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[51] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[52] && pf_s1_io_hpmevent_23[52])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[52] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[58] && pf_s1_io_hpmevent_23[58])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[58] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[59] && pf_s1_io_hpmevent_23[59])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[59] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[60] && pf_s1_io_hpmevent_23[60])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[60] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[61] && pf_s1_io_hpmevent_23[61])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[61] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[62] && pf_s1_io_hpmevent_23[62])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[62] 未见过 0 和 1"); end
    if (!(pf_s0_io_hpmevent_23[63] && pf_s1_io_hpmevent_23[63])) begin cov_fail++; $display("[COV] PFEvent.io_hpmevent_23[63] 未见过 0 和 1"); end
    $display("[ARM] PFEvent armed_at=%0d", pf_armed_at);
    if (pf_armed_at < 0) begin cov_fail++; $display("[ARM] PFEvent 从未 arm"); end
    $display("[COV] PFEvent.wr0 = %0d", pf_cov_wr0);
    if (pf_cov_wr0 < 100) begin cov_fail++; $display("[COV] PFEvent.wr0 < 100"); end
    $display("[COV] PFEvent.wr1 = %0d", pf_cov_wr1);
    if (pf_cov_wr1 < 100) begin cov_fail++; $display("[COV] PFEvent.wr1 < 100"); end
    $display("[COV] PFEvent.wr2 = %0d", pf_cov_wr2);
    if (pf_cov_wr2 < 100) begin cov_fail++; $display("[COV] PFEvent.wr2 < 100"); end
    $display("[COV] PFEvent.wr3 = %0d", pf_cov_wr3);
    if (pf_cov_wr3 < 100) begin cov_fail++; $display("[COV] PFEvent.wr3 < 100"); end
    $display("[COV] PFEvent.wr4 = %0d", pf_cov_wr4);
    if (pf_cov_wr4 < 100) begin cov_fail++; $display("[COV] PFEvent.wr4 < 100"); end
    $display("[COV] PFEvent.wr5 = %0d", pf_cov_wr5);
    if (pf_cov_wr5 < 100) begin cov_fail++; $display("[COV] PFEvent.wr5 < 100"); end
    $display("[COV] PFEvent.wr6 = %0d", pf_cov_wr6);
    if (pf_cov_wr6 < 100) begin cov_fail++; $display("[COV] PFEvent.wr6 < 100"); end
    $display("[COV] PFEvent.wr7 = %0d", pf_cov_wr7);
    if (pf_cov_wr7 < 100) begin cov_fail++; $display("[COV] PFEvent.wr7 < 100"); end
    $display("[COV] PFEvent.wr8 = %0d", pf_cov_wr8);
    if (pf_cov_wr8 < 100) begin cov_fail++; $display("[COV] PFEvent.wr8 < 100"); end
    $display("[COV] PFEvent.wr9 = %0d", pf_cov_wr9);
    if (pf_cov_wr9 < 100) begin cov_fail++; $display("[COV] PFEvent.wr9 < 100"); end
    $display("[COV] PFEvent.wr10 = %0d", pf_cov_wr10);
    if (pf_cov_wr10 < 100) begin cov_fail++; $display("[COV] PFEvent.wr10 < 100"); end
    $display("[COV] PFEvent.wr11 = %0d", pf_cov_wr11);
    if (pf_cov_wr11 < 100) begin cov_fail++; $display("[COV] PFEvent.wr11 < 100"); end
    $display("[COV] PFEvent.wr12 = %0d", pf_cov_wr12);
    if (pf_cov_wr12 < 100) begin cov_fail++; $display("[COV] PFEvent.wr12 < 100"); end
    $display("[COV] PFEvent.wr13 = %0d", pf_cov_wr13);
    if (pf_cov_wr13 < 100) begin cov_fail++; $display("[COV] PFEvent.wr13 < 100"); end
    $display("[COV] PFEvent.wr14 = %0d", pf_cov_wr14);
    if (pf_cov_wr14 < 100) begin cov_fail++; $display("[COV] PFEvent.wr14 < 100"); end
    $display("[COV] PFEvent.wr15 = %0d", pf_cov_wr15);
    if (pf_cov_wr15 < 100) begin cov_fail++; $display("[COV] PFEvent.wr15 < 100"); end
    $display("[COV] PFEvent.wr16 = %0d", pf_cov_wr16);
    if (pf_cov_wr16 < 100) begin cov_fail++; $display("[COV] PFEvent.wr16 < 100"); end
    $display("[COV] PFEvent.wr17 = %0d", pf_cov_wr17);
    if (pf_cov_wr17 < 100) begin cov_fail++; $display("[COV] PFEvent.wr17 < 100"); end
    $display("[COV] PFEvent.wr18 = %0d", pf_cov_wr18);
    if (pf_cov_wr18 < 100) begin cov_fail++; $display("[COV] PFEvent.wr18 < 100"); end
    $display("[COV] PFEvent.wr19 = %0d", pf_cov_wr19);
    if (pf_cov_wr19 < 100) begin cov_fail++; $display("[COV] PFEvent.wr19 < 100"); end
    $display("[COV] PFEvent.wr20 = %0d", pf_cov_wr20);
    if (pf_cov_wr20 < 100) begin cov_fail++; $display("[COV] PFEvent.wr20 < 100"); end
    $display("[COV] PFEvent.wr21 = %0d", pf_cov_wr21);
    if (pf_cov_wr21 < 100) begin cov_fail++; $display("[COV] PFEvent.wr21 < 100"); end
    $display("[COV] PFEvent.wr22 = %0d", pf_cov_wr22);
    if (pf_cov_wr22 < 100) begin cov_fail++; $display("[COV] PFEvent.wr22 < 100"); end
    $display("[COV] PFEvent.wr23 = %0d", pf_cov_wr23);
    if (pf_cov_wr23 < 100) begin cov_fail++; $display("[COV] PFEvent.wr23 < 100"); end
    $display("[COV] PFEvent.wr_outside = %0d", pf_cov_wr_outside);
    if (pf_cov_wr_outside < 100) begin cov_fail++; $display("[COV] PFEvent.wr_outside < 100"); end
    $display("[COV] PFEvent.optype_reject = %0d", pf_cov_optype_reject);
    if (pf_cov_optype_reject < 100) begin cov_fail++; $display("[COV] PFEvent.optype_reject < 100"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
