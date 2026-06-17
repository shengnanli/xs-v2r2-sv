// =============================================================================
// tb —— DelayReg UT:golden DelayReg (u_g) vs 可读核 DelayReg_xs (u_i) 逐拍逐输出比对。
// DelayReg 为「延迟 3 拍」时序模块:每拍随机驱动全部 payload 字段(含随机复位),
// 上升沿后比较两边全部 42 个输出。$isunknown 跳过复位初值未知窗口(实际两边
// 复位都到 0,但保险起见保留)。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  // 输入(全 payload 字段)
  logic        reset;
  logic        i_valid, i_skip, i_isRVC, i_rfwen, i_fpwen, i_vecwen, i_v0wen;
  logic [7:0]  i_wpdest, i_wdest, i_nFused, i_coreid, i_index;
  logic [7:0]  i_otherwpdest [8];

  // golden / impl 输出
  logic        g_valid, g_skip, g_isRVC, g_rfwen, g_fpwen, g_vecwen, g_v0wen;
  logic [7:0]  g_wpdest, g_wdest, g_nFused, g_coreid, g_index;
  logic [7:0]  g_otherwpdest [8];
  logic        i_valid_o, i_skip_o, i_isRVC_o, i_rfwen_o, i_fpwen_o, i_vecwen_o, i_v0wen_o;
  logic [7:0]  i_wpdest_o, i_wdest_o, i_nFused_o, i_coreid_o, i_index_o;
  logic [7:0]  i_otherwpdest_o [8];

  DelayReg u_g (
    .clock(clk), .reset(reset),
    .i_valid(i_valid), .i_skip(i_skip), .i_isRVC(i_isRVC), .i_rfwen(i_rfwen),
    .i_fpwen(i_fpwen), .i_vecwen(i_vecwen), .i_v0wen(i_v0wen),
    .i_wpdest(i_wpdest), .i_wdest(i_wdest),
    .i_otherwpdest_0(i_otherwpdest[0]), .i_otherwpdest_1(i_otherwpdest[1]),
    .i_otherwpdest_2(i_otherwpdest[2]), .i_otherwpdest_3(i_otherwpdest[3]),
    .i_otherwpdest_4(i_otherwpdest[4]), .i_otherwpdest_5(i_otherwpdest[5]),
    .i_otherwpdest_6(i_otherwpdest[6]), .i_otherwpdest_7(i_otherwpdest[7]),
    .i_nFused(i_nFused), .i_coreid(i_coreid), .i_index(i_index),
    .o_valid(g_valid), .o_skip(g_skip), .o_isRVC(g_isRVC), .o_rfwen(g_rfwen),
    .o_fpwen(g_fpwen), .o_vecwen(g_vecwen), .o_v0wen(g_v0wen),
    .o_wpdest(g_wpdest), .o_wdest(g_wdest),
    .o_otherwpdest_0(g_otherwpdest[0]), .o_otherwpdest_1(g_otherwpdest[1]),
    .o_otherwpdest_2(g_otherwpdest[2]), .o_otherwpdest_3(g_otherwpdest[3]),
    .o_otherwpdest_4(g_otherwpdest[4]), .o_otherwpdest_5(g_otherwpdest[5]),
    .o_otherwpdest_6(g_otherwpdest[6]), .o_otherwpdest_7(g_otherwpdest[7]),
    .o_nFused(g_nFused), .o_coreid(g_coreid), .o_index(g_index)
  );

  DelayReg_xs u_i (
    .clock(clk), .reset(reset),
    .i_valid(i_valid), .i_skip(i_skip), .i_isRVC(i_isRVC), .i_rfwen(i_rfwen),
    .i_fpwen(i_fpwen), .i_vecwen(i_vecwen), .i_v0wen(i_v0wen),
    .i_wpdest(i_wpdest), .i_wdest(i_wdest),
    .i_otherwpdest_0(i_otherwpdest[0]), .i_otherwpdest_1(i_otherwpdest[1]),
    .i_otherwpdest_2(i_otherwpdest[2]), .i_otherwpdest_3(i_otherwpdest[3]),
    .i_otherwpdest_4(i_otherwpdest[4]), .i_otherwpdest_5(i_otherwpdest[5]),
    .i_otherwpdest_6(i_otherwpdest[6]), .i_otherwpdest_7(i_otherwpdest[7]),
    .i_nFused(i_nFused), .i_coreid(i_coreid), .i_index(i_index),
    .o_valid(i_valid_o), .o_skip(i_skip_o), .o_isRVC(i_isRVC_o), .o_rfwen(i_rfwen_o),
    .o_fpwen(i_fpwen_o), .o_vecwen(i_vecwen_o), .o_v0wen(i_v0wen_o),
    .o_wpdest(i_wpdest_o), .o_wdest(i_wdest_o),
    .o_otherwpdest_0(i_otherwpdest_o[0]), .o_otherwpdest_1(i_otherwpdest_o[1]),
    .o_otherwpdest_2(i_otherwpdest_o[2]), .o_otherwpdest_3(i_otherwpdest_o[3]),
    .o_otherwpdest_4(i_otherwpdest_o[4]), .o_otherwpdest_5(i_otherwpdest_o[5]),
    .o_otherwpdest_6(i_otherwpdest_o[6]), .o_otherwpdest_7(i_otherwpdest_o[7]),
    .o_nFused(i_nFused_o), .o_coreid(i_coreid_o), .o_index(i_index_o)
  );

  task automatic drive_inputs();
    // 大部分拍 reset=0,偶发拉高复位(测异步清 0 + 复位后前 3 拍 0)。
    reset    = ($urandom_range(0, 99) < 3);
    i_valid  = $urandom;  i_skip   = $urandom;  i_isRVC  = $urandom;
    i_rfwen  = $urandom;  i_fpwen  = $urandom;  i_vecwen = $urandom;
    i_v0wen  = $urandom;
    i_wpdest = $urandom;  i_wdest  = $urandom;
    i_nFused = $urandom;  i_coreid = $urandom;  i_index  = $urandom;
    for (int k = 0; k < 8; k++) i_otherwpdest[k] = $urandom;
  endtask

  `define CK(g,i,nm) \
    if (!$isunknown(g) && (g) !== (i)) begin errors++; \
      if (errors<=60) $display("[%0t] %s g=%h i=%h", $time, nm, g, i); end \
    checks++;

  task automatic check_outputs();
    `CK(g_valid,  i_valid_o,  "valid")
    `CK(g_skip,   i_skip_o,   "skip")
    `CK(g_isRVC,  i_isRVC_o,  "isRVC")
    `CK(g_rfwen,  i_rfwen_o,  "rfwen")
    `CK(g_fpwen,  i_fpwen_o,  "fpwen")
    `CK(g_vecwen, i_vecwen_o, "vecwen")
    `CK(g_v0wen,  i_v0wen_o,  "v0wen")
    `CK(g_wpdest, i_wpdest_o, "wpdest")
    `CK(g_wdest,  i_wdest_o,  "wdest")
    `CK(g_nFused, i_nFused_o, "nFused")
    `CK(g_coreid, i_coreid_o, "coreid")
    `CK(g_index,  i_index_o,  "index")
    for (int k = 0; k < 8; k++) begin
      `CK(g_otherwpdest[k], i_otherwpdest_o[k], "otherwpdest")
    end
  endtask

  initial begin
    // 上电先复位若干拍,清掉两侧寄存器的 X(异步复位,driven 在 negedge 避免竞争)。
    drive_inputs();
    reset = 1;
    repeat (5) @(negedge clk);
    repeat (NCYCLES) begin
      drive_inputs();           // 在 negedge 后驱动输入(远离上升采样沿)
      @(posedge clk);           // 寄存器在此沿更新
      #1 check_outputs();       // 稳定后比对
      @(negedge clk);           // 走到下降沿,准备下一拍驱动
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
