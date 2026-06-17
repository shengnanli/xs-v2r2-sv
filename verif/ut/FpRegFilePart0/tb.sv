// 自动生成：scripts/gen_regfile.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic [7:0] io_readPorts_addr [11];
  logic io_writePorts_wen [6];
  logic [7:0] io_writePorts_addr [6];
  logic [15:0] io_writePorts_data [6];
  logic [7:0] io_debug_rports_addr [32];
  logic [15:0] g_read [11];
  logic [15:0] i_read [11];
  logic [15:0] g_dbg [32];
  logic [15:0] i_dbg [32];

  FpRegFilePart0 g_u (.clock(clk), .reset(rst), .io_readPorts_0_addr(io_readPorts_addr[0]), .io_readPorts_1_addr(io_readPorts_addr[1]), .io_readPorts_2_addr(io_readPorts_addr[2]), .io_readPorts_3_addr(io_readPorts_addr[3]), .io_readPorts_4_addr(io_readPorts_addr[4]), .io_readPorts_5_addr(io_readPorts_addr[5]), .io_readPorts_6_addr(io_readPorts_addr[6]), .io_readPorts_7_addr(io_readPorts_addr[7]), .io_readPorts_8_addr(io_readPorts_addr[8]), .io_readPorts_9_addr(io_readPorts_addr[9]), .io_readPorts_10_addr(io_readPorts_addr[10]), .io_writePorts_0_wen(io_writePorts_wen[0]), .io_writePorts_0_addr(io_writePorts_addr[0]), .io_writePorts_0_data(io_writePorts_data[0]), .io_writePorts_1_wen(io_writePorts_wen[1]), .io_writePorts_1_addr(io_writePorts_addr[1]), .io_writePorts_1_data(io_writePorts_data[1]), .io_writePorts_2_wen(io_writePorts_wen[2]), .io_writePorts_2_addr(io_writePorts_addr[2]), .io_writePorts_2_data(io_writePorts_data[2]), .io_writePorts_3_wen(io_writePorts_wen[3]), .io_writePorts_3_addr(io_writePorts_addr[3]), .io_writePorts_3_data(io_writePorts_data[3]), .io_writePorts_4_wen(io_writePorts_wen[4]), .io_writePorts_4_addr(io_writePorts_addr[4]), .io_writePorts_4_data(io_writePorts_data[4]), .io_writePorts_5_wen(io_writePorts_wen[5]), .io_writePorts_5_addr(io_writePorts_addr[5]), .io_writePorts_5_data(io_writePorts_data[5]), .io_debug_rports_0_addr(io_debug_rports_addr[0]), .io_debug_rports_1_addr(io_debug_rports_addr[1]), .io_debug_rports_2_addr(io_debug_rports_addr[2]), .io_debug_rports_3_addr(io_debug_rports_addr[3]), .io_debug_rports_4_addr(io_debug_rports_addr[4]), .io_debug_rports_5_addr(io_debug_rports_addr[5]), .io_debug_rports_6_addr(io_debug_rports_addr[6]), .io_debug_rports_7_addr(io_debug_rports_addr[7]), .io_debug_rports_8_addr(io_debug_rports_addr[8]), .io_debug_rports_9_addr(io_debug_rports_addr[9]), .io_debug_rports_10_addr(io_debug_rports_addr[10]), .io_debug_rports_11_addr(io_debug_rports_addr[11]), .io_debug_rports_12_addr(io_debug_rports_addr[12]), .io_debug_rports_13_addr(io_debug_rports_addr[13]), .io_debug_rports_14_addr(io_debug_rports_addr[14]), .io_debug_rports_15_addr(io_debug_rports_addr[15]), .io_debug_rports_16_addr(io_debug_rports_addr[16]), .io_debug_rports_17_addr(io_debug_rports_addr[17]), .io_debug_rports_18_addr(io_debug_rports_addr[18]), .io_debug_rports_19_addr(io_debug_rports_addr[19]), .io_debug_rports_20_addr(io_debug_rports_addr[20]), .io_debug_rports_21_addr(io_debug_rports_addr[21]), .io_debug_rports_22_addr(io_debug_rports_addr[22]), .io_debug_rports_23_addr(io_debug_rports_addr[23]), .io_debug_rports_24_addr(io_debug_rports_addr[24]), .io_debug_rports_25_addr(io_debug_rports_addr[25]), .io_debug_rports_26_addr(io_debug_rports_addr[26]), .io_debug_rports_27_addr(io_debug_rports_addr[27]), .io_debug_rports_28_addr(io_debug_rports_addr[28]), .io_debug_rports_29_addr(io_debug_rports_addr[29]), .io_debug_rports_30_addr(io_debug_rports_addr[30]), .io_debug_rports_31_addr(io_debug_rports_addr[31]), .io_readPorts_0_data(g_read[0]), .io_readPorts_1_data(g_read[1]), .io_readPorts_2_data(g_read[2]), .io_readPorts_3_data(g_read[3]), .io_readPorts_4_data(g_read[4]), .io_readPorts_5_data(g_read[5]), .io_readPorts_6_data(g_read[6]), .io_readPorts_7_data(g_read[7]), .io_readPorts_8_data(g_read[8]), .io_readPorts_9_data(g_read[9]), .io_readPorts_10_data(g_read[10]), .io_debug_rports_0_data(g_dbg[0]), .io_debug_rports_1_data(g_dbg[1]), .io_debug_rports_2_data(g_dbg[2]), .io_debug_rports_3_data(g_dbg[3]), .io_debug_rports_4_data(g_dbg[4]), .io_debug_rports_5_data(g_dbg[5]), .io_debug_rports_6_data(g_dbg[6]), .io_debug_rports_7_data(g_dbg[7]), .io_debug_rports_8_data(g_dbg[8]), .io_debug_rports_9_data(g_dbg[9]), .io_debug_rports_10_data(g_dbg[10]), .io_debug_rports_11_data(g_dbg[11]), .io_debug_rports_12_data(g_dbg[12]), .io_debug_rports_13_data(g_dbg[13]), .io_debug_rports_14_data(g_dbg[14]), .io_debug_rports_15_data(g_dbg[15]), .io_debug_rports_16_data(g_dbg[16]), .io_debug_rports_17_data(g_dbg[17]), .io_debug_rports_18_data(g_dbg[18]), .io_debug_rports_19_data(g_dbg[19]), .io_debug_rports_20_data(g_dbg[20]), .io_debug_rports_21_data(g_dbg[21]), .io_debug_rports_22_data(g_dbg[22]), .io_debug_rports_23_data(g_dbg[23]), .io_debug_rports_24_data(g_dbg[24]), .io_debug_rports_25_data(g_dbg[25]), .io_debug_rports_26_data(g_dbg[26]), .io_debug_rports_27_data(g_dbg[27]), .io_debug_rports_28_data(g_dbg[28]), .io_debug_rports_29_data(g_dbg[29]), .io_debug_rports_30_data(g_dbg[30]), .io_debug_rports_31_data(g_dbg[31]));
  FpRegFilePart0_xs i_u (.clock(clk), .reset(rst), .io_readPorts_0_addr(io_readPorts_addr[0]), .io_readPorts_1_addr(io_readPorts_addr[1]), .io_readPorts_2_addr(io_readPorts_addr[2]), .io_readPorts_3_addr(io_readPorts_addr[3]), .io_readPorts_4_addr(io_readPorts_addr[4]), .io_readPorts_5_addr(io_readPorts_addr[5]), .io_readPorts_6_addr(io_readPorts_addr[6]), .io_readPorts_7_addr(io_readPorts_addr[7]), .io_readPorts_8_addr(io_readPorts_addr[8]), .io_readPorts_9_addr(io_readPorts_addr[9]), .io_readPorts_10_addr(io_readPorts_addr[10]), .io_writePorts_0_wen(io_writePorts_wen[0]), .io_writePorts_0_addr(io_writePorts_addr[0]), .io_writePorts_0_data(io_writePorts_data[0]), .io_writePorts_1_wen(io_writePorts_wen[1]), .io_writePorts_1_addr(io_writePorts_addr[1]), .io_writePorts_1_data(io_writePorts_data[1]), .io_writePorts_2_wen(io_writePorts_wen[2]), .io_writePorts_2_addr(io_writePorts_addr[2]), .io_writePorts_2_data(io_writePorts_data[2]), .io_writePorts_3_wen(io_writePorts_wen[3]), .io_writePorts_3_addr(io_writePorts_addr[3]), .io_writePorts_3_data(io_writePorts_data[3]), .io_writePorts_4_wen(io_writePorts_wen[4]), .io_writePorts_4_addr(io_writePorts_addr[4]), .io_writePorts_4_data(io_writePorts_data[4]), .io_writePorts_5_wen(io_writePorts_wen[5]), .io_writePorts_5_addr(io_writePorts_addr[5]), .io_writePorts_5_data(io_writePorts_data[5]), .io_debug_rports_0_addr(io_debug_rports_addr[0]), .io_debug_rports_1_addr(io_debug_rports_addr[1]), .io_debug_rports_2_addr(io_debug_rports_addr[2]), .io_debug_rports_3_addr(io_debug_rports_addr[3]), .io_debug_rports_4_addr(io_debug_rports_addr[4]), .io_debug_rports_5_addr(io_debug_rports_addr[5]), .io_debug_rports_6_addr(io_debug_rports_addr[6]), .io_debug_rports_7_addr(io_debug_rports_addr[7]), .io_debug_rports_8_addr(io_debug_rports_addr[8]), .io_debug_rports_9_addr(io_debug_rports_addr[9]), .io_debug_rports_10_addr(io_debug_rports_addr[10]), .io_debug_rports_11_addr(io_debug_rports_addr[11]), .io_debug_rports_12_addr(io_debug_rports_addr[12]), .io_debug_rports_13_addr(io_debug_rports_addr[13]), .io_debug_rports_14_addr(io_debug_rports_addr[14]), .io_debug_rports_15_addr(io_debug_rports_addr[15]), .io_debug_rports_16_addr(io_debug_rports_addr[16]), .io_debug_rports_17_addr(io_debug_rports_addr[17]), .io_debug_rports_18_addr(io_debug_rports_addr[18]), .io_debug_rports_19_addr(io_debug_rports_addr[19]), .io_debug_rports_20_addr(io_debug_rports_addr[20]), .io_debug_rports_21_addr(io_debug_rports_addr[21]), .io_debug_rports_22_addr(io_debug_rports_addr[22]), .io_debug_rports_23_addr(io_debug_rports_addr[23]), .io_debug_rports_24_addr(io_debug_rports_addr[24]), .io_debug_rports_25_addr(io_debug_rports_addr[25]), .io_debug_rports_26_addr(io_debug_rports_addr[26]), .io_debug_rports_27_addr(io_debug_rports_addr[27]), .io_debug_rports_28_addr(io_debug_rports_addr[28]), .io_debug_rports_29_addr(io_debug_rports_addr[29]), .io_debug_rports_30_addr(io_debug_rports_addr[30]), .io_debug_rports_31_addr(io_debug_rports_addr[31]), .io_readPorts_0_data(i_read[0]), .io_readPorts_1_data(i_read[1]), .io_readPorts_2_data(i_read[2]), .io_readPorts_3_data(i_read[3]), .io_readPorts_4_data(i_read[4]), .io_readPorts_5_data(i_read[5]), .io_readPorts_6_data(i_read[6]), .io_readPorts_7_data(i_read[7]), .io_readPorts_8_data(i_read[8]), .io_readPorts_9_data(i_read[9]), .io_readPorts_10_data(i_read[10]), .io_debug_rports_0_data(i_dbg[0]), .io_debug_rports_1_data(i_dbg[1]), .io_debug_rports_2_data(i_dbg[2]), .io_debug_rports_3_data(i_dbg[3]), .io_debug_rports_4_data(i_dbg[4]), .io_debug_rports_5_data(i_dbg[5]), .io_debug_rports_6_data(i_dbg[6]), .io_debug_rports_7_data(i_dbg[7]), .io_debug_rports_8_data(i_dbg[8]), .io_debug_rports_9_data(i_dbg[9]), .io_debug_rports_10_data(i_dbg[10]), .io_debug_rports_11_data(i_dbg[11]), .io_debug_rports_12_data(i_dbg[12]), .io_debug_rports_13_data(i_dbg[13]), .io_debug_rports_14_data(i_dbg[14]), .io_debug_rports_15_data(i_dbg[15]), .io_debug_rports_16_data(i_dbg[16]), .io_debug_rports_17_data(i_dbg[17]), .io_debug_rports_18_data(i_dbg[18]), .io_debug_rports_19_data(i_dbg[19]), .io_debug_rports_20_data(i_dbg[20]), .io_debug_rports_21_data(i_dbg[21]), .io_debug_rports_22_data(i_dbg[22]), .io_debug_rports_23_data(i_dbg[23]), .io_debug_rports_24_data(i_dbg[24]), .io_debug_rports_25_data(i_dbg[25]), .io_debug_rports_26_data(i_dbg[26]), .io_debug_rports_27_data(i_dbg[27]), .io_debug_rports_28_data(i_dbg[28]), .io_debug_rports_29_data(i_dbg[29]), .io_debug_rports_30_data(i_dbg[30]), .io_debug_rports_31_data(i_dbg[31]));

  // 随机地址:0..191(覆盖全部物理寄存器,含 x0)
  function automatic logic [7:0] rnd_addr();
    return 8'($urandom_range(0,191));
  endfunction

  always @(negedge clk) begin
    if (rst) begin
      for (int r = 0; r < 11; r++) io_readPorts_addr[r] <= 0;
      for (int w = 0; w < 6; w++) begin
        io_writePorts_wen[w] <= 0; io_writePorts_addr[w] <= 0; io_writePorts_data[w] <= 0;
      end
      for (int d = 0; d < 32; d++) io_debug_rports_addr[d] <= 0;
    end else begin
      for (int r = 0; r < 11; r++) io_readPorts_addr[r] <= rnd_addr();
      // 写口:为遵守 golden assert(同拍不写同地址),每口分配互斥的地址区间。
      for (int w = 0; w < 6; w++) begin
        io_writePorts_wen[w]  <= ($urandom_range(0,99) < 60);
        io_writePorts_addr[w] <= rnd_addr();
        io_writePorts_data[w] <= 16'($urandom);
      end
      // 强制写地址两两不同(简单去重:第 w 口若与前面撞,则关其 wen)
      for (int d = 0; d < 32; d++) io_debug_rports_addr[d] <= rnd_addr();
    end
  end

  // 同拍写同地址去重:在驱动后、时钟沿前调整(组合保证 g/i 看到同一激励)。
  // golden 对此情形有 assert,但 SYNTHESIS 下 assert 关闭;为语义清晰仍做去重。
  always @(io_writePorts_wen, io_writePorts_addr) begin
    for (int a = 0; a < 6; a++)
      for (int b = a+1; b < 6; b++)
        if (io_writePorts_wen[a] && io_writePorts_wen[b] &&
            io_writePorts_addr[a] == io_writePorts_addr[b])
          io_writePorts_wen[b] = 1'b0;
  end

  task automatic check(input string nm, input logic [15:0] g, input logic [15:0] i);
    checks++;
    if (!$isunknown(g) && g !== i) begin
      errors++;
      if (errors <= 80) $display("[%0t] %s g=%h i=%h", $time, nm, g, i);
    end
  endtask

  always @(negedge clk) if (!rst) begin
    #4;
    for (int r = 0; r < 11; r++) check($sformatf("read_%0d", r), g_read[r], i_read[r]);
    for (int d = 0; d < 32; d++) check($sformatf("debug_%0d", d), g_dbg[d], i_dbg[d]);
  end

  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
