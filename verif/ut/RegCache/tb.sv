// =============================================================================
// tb —— RegCache UT:golden RegCache (u_g) vs 可读核 RegCache_xs (u_i) 逐拍比对。
// 两侧各含一份黑盒子模块(独立状态)。每拍随机驱动读口(ren+5位idx)、写口
// (wen+data) 与偶发复位,上升沿后比对 23 个读数据 + 7 个唤醒下标。
// 写地址来自内部替换流水,不由 tb 控制。$isunknown 跳过未初始化窗口。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic reset;
  logic ren_0; logic [4:0] addr_0; logic [63:0] g_rdata_0, i_rdata_0;
  logic ren_1; logic [4:0] addr_1; logic [63:0] g_rdata_1, i_rdata_1;
  logic ren_2; logic [4:0] addr_2; logic [63:0] g_rdata_2, i_rdata_2;
  logic ren_3; logic [4:0] addr_3; logic [63:0] g_rdata_3, i_rdata_3;
  logic ren_4; logic [4:0] addr_4; logic [63:0] g_rdata_4, i_rdata_4;
  logic ren_5; logic [4:0] addr_5; logic [63:0] g_rdata_5, i_rdata_5;
  logic ren_6; logic [4:0] addr_6; logic [63:0] g_rdata_6, i_rdata_6;
  logic ren_7; logic [4:0] addr_7; logic [63:0] g_rdata_7, i_rdata_7;
  logic ren_8; logic [4:0] addr_8; logic [63:0] g_rdata_8, i_rdata_8;
  logic ren_9; logic [4:0] addr_9; logic [63:0] g_rdata_9, i_rdata_9;
  logic ren_10; logic [4:0] addr_10; logic [63:0] g_rdata_10, i_rdata_10;
  logic ren_11; logic [4:0] addr_11; logic [63:0] g_rdata_11, i_rdata_11;
  logic ren_12; logic [4:0] addr_12; logic [63:0] g_rdata_12, i_rdata_12;
  logic ren_13; logic [4:0] addr_13; logic [63:0] g_rdata_13, i_rdata_13;
  logic ren_14; logic [4:0] addr_14; logic [63:0] g_rdata_14, i_rdata_14;
  logic ren_15; logic [4:0] addr_15; logic [63:0] g_rdata_15, i_rdata_15;
  logic ren_16; logic [4:0] addr_16; logic [63:0] g_rdata_16, i_rdata_16;
  logic ren_17; logic [4:0] addr_17; logic [63:0] g_rdata_17, i_rdata_17;
  logic ren_18; logic [4:0] addr_18; logic [63:0] g_rdata_18, i_rdata_18;
  logic ren_19; logic [4:0] addr_19; logic [63:0] g_rdata_19, i_rdata_19;
  logic ren_20; logic [4:0] addr_20; logic [63:0] g_rdata_20, i_rdata_20;
  logic ren_21; logic [4:0] addr_21; logic [63:0] g_rdata_21, i_rdata_21;
  logic ren_22; logic [4:0] addr_22; logic [63:0] g_rdata_22, i_rdata_22;
  logic wen_0; logic [63:0] wdata_0; logic [4:0] g_wk_0, i_wk_0;
  logic wen_1; logic [63:0] wdata_1; logic [4:0] g_wk_1, i_wk_1;
  logic wen_2; logic [63:0] wdata_2; logic [4:0] g_wk_2, i_wk_2;
  logic wen_3; logic [63:0] wdata_3; logic [4:0] g_wk_3, i_wk_3;
  logic wen_4; logic [63:0] wdata_4; logic [4:0] g_wk_4, i_wk_4;
  logic wen_5; logic [63:0] wdata_5; logic [4:0] g_wk_5, i_wk_5;
  logic wen_6; logic [63:0] wdata_6; logic [4:0] g_wk_6, i_wk_6;

  RegCache u_g (
    .clock(clk), .reset(reset),
    .io_readPorts_0_ren(ren_0), .io_readPorts_0_addr(addr_0), .io_readPorts_0_data(g_rdata_0),
    .io_readPorts_1_ren(ren_1), .io_readPorts_1_addr(addr_1), .io_readPorts_1_data(g_rdata_1),
    .io_readPorts_2_ren(ren_2), .io_readPorts_2_addr(addr_2), .io_readPorts_2_data(g_rdata_2),
    .io_readPorts_3_ren(ren_3), .io_readPorts_3_addr(addr_3), .io_readPorts_3_data(g_rdata_3),
    .io_readPorts_4_ren(ren_4), .io_readPorts_4_addr(addr_4), .io_readPorts_4_data(g_rdata_4),
    .io_readPorts_5_ren(ren_5), .io_readPorts_5_addr(addr_5), .io_readPorts_5_data(g_rdata_5),
    .io_readPorts_6_ren(ren_6), .io_readPorts_6_addr(addr_6), .io_readPorts_6_data(g_rdata_6),
    .io_readPorts_7_ren(ren_7), .io_readPorts_7_addr(addr_7), .io_readPorts_7_data(g_rdata_7),
    .io_readPorts_8_ren(ren_8), .io_readPorts_8_addr(addr_8), .io_readPorts_8_data(g_rdata_8),
    .io_readPorts_9_ren(ren_9), .io_readPorts_9_addr(addr_9), .io_readPorts_9_data(g_rdata_9),
    .io_readPorts_10_ren(ren_10), .io_readPorts_10_addr(addr_10), .io_readPorts_10_data(g_rdata_10),
    .io_readPorts_11_ren(ren_11), .io_readPorts_11_addr(addr_11), .io_readPorts_11_data(g_rdata_11),
    .io_readPorts_12_ren(ren_12), .io_readPorts_12_addr(addr_12), .io_readPorts_12_data(g_rdata_12),
    .io_readPorts_13_ren(ren_13), .io_readPorts_13_addr(addr_13), .io_readPorts_13_data(g_rdata_13),
    .io_readPorts_14_ren(ren_14), .io_readPorts_14_addr(addr_14), .io_readPorts_14_data(g_rdata_14),
    .io_readPorts_15_ren(ren_15), .io_readPorts_15_addr(addr_15), .io_readPorts_15_data(g_rdata_15),
    .io_readPorts_16_ren(ren_16), .io_readPorts_16_addr(addr_16), .io_readPorts_16_data(g_rdata_16),
    .io_readPorts_17_ren(ren_17), .io_readPorts_17_addr(addr_17), .io_readPorts_17_data(g_rdata_17),
    .io_readPorts_18_ren(ren_18), .io_readPorts_18_addr(addr_18), .io_readPorts_18_data(g_rdata_18),
    .io_readPorts_19_ren(ren_19), .io_readPorts_19_addr(addr_19), .io_readPorts_19_data(g_rdata_19),
    .io_readPorts_20_ren(ren_20), .io_readPorts_20_addr(addr_20), .io_readPorts_20_data(g_rdata_20),
    .io_readPorts_21_ren(ren_21), .io_readPorts_21_addr(addr_21), .io_readPorts_21_data(g_rdata_21),
    .io_readPorts_22_ren(ren_22), .io_readPorts_22_addr(addr_22), .io_readPorts_22_data(g_rdata_22),
    .io_writePorts_0_wen(wen_0), .io_writePorts_0_data(wdata_0),
    .io_writePorts_1_wen(wen_1), .io_writePorts_1_data(wdata_1),
    .io_writePorts_2_wen(wen_2), .io_writePorts_2_data(wdata_2),
    .io_writePorts_3_wen(wen_3), .io_writePorts_3_data(wdata_3),
    .io_writePorts_4_wen(wen_4), .io_writePorts_4_data(wdata_4),
    .io_writePorts_5_wen(wen_5), .io_writePorts_5_data(wdata_5),
    .io_writePorts_6_wen(wen_6), .io_writePorts_6_data(wdata_6),
    .io_toWakeupQueueRCIdx_0(g_wk_0), .io_toWakeupQueueRCIdx_1(g_wk_1), .io_toWakeupQueueRCIdx_2(g_wk_2), .io_toWakeupQueueRCIdx_3(g_wk_3), .io_toWakeupQueueRCIdx_4(g_wk_4), .io_toWakeupQueueRCIdx_5(g_wk_5), .io_toWakeupQueueRCIdx_6(g_wk_6)
  );

  RegCache_xs u_i (
    .clock(clk), .reset(reset),
    .io_readPorts_0_ren(ren_0), .io_readPorts_0_addr(addr_0), .io_readPorts_0_data(i_rdata_0),
    .io_readPorts_1_ren(ren_1), .io_readPorts_1_addr(addr_1), .io_readPorts_1_data(i_rdata_1),
    .io_readPorts_2_ren(ren_2), .io_readPorts_2_addr(addr_2), .io_readPorts_2_data(i_rdata_2),
    .io_readPorts_3_ren(ren_3), .io_readPorts_3_addr(addr_3), .io_readPorts_3_data(i_rdata_3),
    .io_readPorts_4_ren(ren_4), .io_readPorts_4_addr(addr_4), .io_readPorts_4_data(i_rdata_4),
    .io_readPorts_5_ren(ren_5), .io_readPorts_5_addr(addr_5), .io_readPorts_5_data(i_rdata_5),
    .io_readPorts_6_ren(ren_6), .io_readPorts_6_addr(addr_6), .io_readPorts_6_data(i_rdata_6),
    .io_readPorts_7_ren(ren_7), .io_readPorts_7_addr(addr_7), .io_readPorts_7_data(i_rdata_7),
    .io_readPorts_8_ren(ren_8), .io_readPorts_8_addr(addr_8), .io_readPorts_8_data(i_rdata_8),
    .io_readPorts_9_ren(ren_9), .io_readPorts_9_addr(addr_9), .io_readPorts_9_data(i_rdata_9),
    .io_readPorts_10_ren(ren_10), .io_readPorts_10_addr(addr_10), .io_readPorts_10_data(i_rdata_10),
    .io_readPorts_11_ren(ren_11), .io_readPorts_11_addr(addr_11), .io_readPorts_11_data(i_rdata_11),
    .io_readPorts_12_ren(ren_12), .io_readPorts_12_addr(addr_12), .io_readPorts_12_data(i_rdata_12),
    .io_readPorts_13_ren(ren_13), .io_readPorts_13_addr(addr_13), .io_readPorts_13_data(i_rdata_13),
    .io_readPorts_14_ren(ren_14), .io_readPorts_14_addr(addr_14), .io_readPorts_14_data(i_rdata_14),
    .io_readPorts_15_ren(ren_15), .io_readPorts_15_addr(addr_15), .io_readPorts_15_data(i_rdata_15),
    .io_readPorts_16_ren(ren_16), .io_readPorts_16_addr(addr_16), .io_readPorts_16_data(i_rdata_16),
    .io_readPorts_17_ren(ren_17), .io_readPorts_17_addr(addr_17), .io_readPorts_17_data(i_rdata_17),
    .io_readPorts_18_ren(ren_18), .io_readPorts_18_addr(addr_18), .io_readPorts_18_data(i_rdata_18),
    .io_readPorts_19_ren(ren_19), .io_readPorts_19_addr(addr_19), .io_readPorts_19_data(i_rdata_19),
    .io_readPorts_20_ren(ren_20), .io_readPorts_20_addr(addr_20), .io_readPorts_20_data(i_rdata_20),
    .io_readPorts_21_ren(ren_21), .io_readPorts_21_addr(addr_21), .io_readPorts_21_data(i_rdata_21),
    .io_readPorts_22_ren(ren_22), .io_readPorts_22_addr(addr_22), .io_readPorts_22_data(i_rdata_22),
    .io_writePorts_0_wen(wen_0), .io_writePorts_0_data(wdata_0),
    .io_writePorts_1_wen(wen_1), .io_writePorts_1_data(wdata_1),
    .io_writePorts_2_wen(wen_2), .io_writePorts_2_data(wdata_2),
    .io_writePorts_3_wen(wen_3), .io_writePorts_3_data(wdata_3),
    .io_writePorts_4_wen(wen_4), .io_writePorts_4_data(wdata_4),
    .io_writePorts_5_wen(wen_5), .io_writePorts_5_data(wdata_5),
    .io_writePorts_6_wen(wen_6), .io_writePorts_6_data(wdata_6),
    .io_toWakeupQueueRCIdx_0(i_wk_0), .io_toWakeupQueueRCIdx_1(i_wk_1), .io_toWakeupQueueRCIdx_2(i_wk_2), .io_toWakeupQueueRCIdx_3(i_wk_3), .io_toWakeupQueueRCIdx_4(i_wk_4), .io_toWakeupQueueRCIdx_5(i_wk_5), .io_toWakeupQueueRCIdx_6(i_wk_6)
  );

  task automatic drive_inputs();
    reset = ($urandom_range(0,99) < 2);
    ren_0 = $urandom; addr_0 = $urandom_range(0,31);
    ren_1 = $urandom; addr_1 = $urandom_range(0,31);
    ren_2 = $urandom; addr_2 = $urandom_range(0,31);
    ren_3 = $urandom; addr_3 = $urandom_range(0,31);
    ren_4 = $urandom; addr_4 = $urandom_range(0,31);
    ren_5 = $urandom; addr_5 = $urandom_range(0,31);
    ren_6 = $urandom; addr_6 = $urandom_range(0,31);
    ren_7 = $urandom; addr_7 = $urandom_range(0,31);
    ren_8 = $urandom; addr_8 = $urandom_range(0,31);
    ren_9 = $urandom; addr_9 = $urandom_range(0,31);
    ren_10 = $urandom; addr_10 = $urandom_range(0,31);
    ren_11 = $urandom; addr_11 = $urandom_range(0,31);
    ren_12 = $urandom; addr_12 = $urandom_range(0,31);
    ren_13 = $urandom; addr_13 = $urandom_range(0,31);
    ren_14 = $urandom; addr_14 = $urandom_range(0,31);
    ren_15 = $urandom; addr_15 = $urandom_range(0,31);
    ren_16 = $urandom; addr_16 = $urandom_range(0,31);
    ren_17 = $urandom; addr_17 = $urandom_range(0,31);
    ren_18 = $urandom; addr_18 = $urandom_range(0,31);
    ren_19 = $urandom; addr_19 = $urandom_range(0,31);
    ren_20 = $urandom; addr_20 = $urandom_range(0,31);
    ren_21 = $urandom; addr_21 = $urandom_range(0,31);
    ren_22 = $urandom; addr_22 = $urandom_range(0,31);
    wen_0 = $urandom; wdata_0 = {$urandom,$urandom};
    wen_1 = $urandom; wdata_1 = {$urandom,$urandom};
    wen_2 = $urandom; wdata_2 = {$urandom,$urandom};
    wen_3 = $urandom; wdata_3 = {$urandom,$urandom};
    wen_4 = $urandom; wdata_4 = {$urandom,$urandom};
    wen_5 = $urandom; wdata_5 = {$urandom,$urandom};
    wen_6 = $urandom; wdata_6 = {$urandom,$urandom};
  endtask

  `define CK(g,i,nm) \
    if (!$isunknown(g) && (g) !== (i)) begin errors++; \
      if (errors<=80) $display("[%0t] %s g=%h i=%h", $time, nm, g, i); end \
    checks++;

  task automatic check_outputs();
    `CK(g_rdata_0, i_rdata_0, "rdata_0")
    `CK(g_rdata_1, i_rdata_1, "rdata_1")
    `CK(g_rdata_2, i_rdata_2, "rdata_2")
    `CK(g_rdata_3, i_rdata_3, "rdata_3")
    `CK(g_rdata_4, i_rdata_4, "rdata_4")
    `CK(g_rdata_5, i_rdata_5, "rdata_5")
    `CK(g_rdata_6, i_rdata_6, "rdata_6")
    `CK(g_rdata_7, i_rdata_7, "rdata_7")
    `CK(g_rdata_8, i_rdata_8, "rdata_8")
    `CK(g_rdata_9, i_rdata_9, "rdata_9")
    `CK(g_rdata_10, i_rdata_10, "rdata_10")
    `CK(g_rdata_11, i_rdata_11, "rdata_11")
    `CK(g_rdata_12, i_rdata_12, "rdata_12")
    `CK(g_rdata_13, i_rdata_13, "rdata_13")
    `CK(g_rdata_14, i_rdata_14, "rdata_14")
    `CK(g_rdata_15, i_rdata_15, "rdata_15")
    `CK(g_rdata_16, i_rdata_16, "rdata_16")
    `CK(g_rdata_17, i_rdata_17, "rdata_17")
    `CK(g_rdata_18, i_rdata_18, "rdata_18")
    `CK(g_rdata_19, i_rdata_19, "rdata_19")
    `CK(g_rdata_20, i_rdata_20, "rdata_20")
    `CK(g_rdata_21, i_rdata_21, "rdata_21")
    `CK(g_rdata_22, i_rdata_22, "rdata_22")
    `CK(g_wk_0, i_wk_0, "wk_0")
    `CK(g_wk_1, i_wk_1, "wk_1")
    `CK(g_wk_2, i_wk_2, "wk_2")
    `CK(g_wk_3, i_wk_3, "wk_3")
    `CK(g_wk_4, i_wk_4, "wk_4")
    `CK(g_wk_5, i_wk_5, "wk_5")
    `CK(g_wk_6, i_wk_6, "wk_6")
  endtask

  initial begin
    drive_inputs(); reset = 1;
    repeat (8) @(negedge clk);
    repeat (NCYCLES) begin
      drive_inputs();
      @(posedge clk);
      #1 check_outputs();
      @(negedge clk);
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
