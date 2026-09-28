// ============================================================================
// tb —— RealWBCollideChecker 家族 UT：5 个 golden 变体与重写件逐拍双例化比对。
//
// 本族纯组合。判别力靠覆盖：每一路输入都要真的在自己组里赢过（比它优先级高的
// 都不请求而它请求），且每个 ready 端口取遍 0/1（组内第 0 名只要求取到 1）。
// 激励：valid 六种形态轮换（全 0 / 全 1 / 单点 / 稀疏 / 稠密 / 随机），
// payload 每路每拍独立随机（含别的域 wen 这些「应被忽略」的输入）。
//
// 本文件由 scripts/gen_realwbcc.py 生成，勿手改。
// ============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0; always #5 clk = ~clk;
  longint errors = 0, checks = 0;
  `define CK(g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors < 20) $display("MISMATCH %0t %s golden=%h impl=%h", $time, nm, (g), (i)); \
    end end
  localparam int MAXIN = 16;
  logic [MAXIN-1:0] vld [5];
  logic [MAXIN-1:0] w1, w2;          // 本域 wen / 别的域 wen
  logic [7:0]   pd  [MAXIN];
  logic [127:0] dat [MAXIN];
  longint win_cnt [5][MAXIN];
  longint rdy0 [5][MAXIN], rdy1 [5][MAXIN];

  // ---- RealWBCollideChecker ----
  logic [0:0] g_0_io_in_11_ready, i_0_io_in_11_ready;
  logic [0:0] g_0_io_in_10_ready, i_0_io_in_10_ready;
  logic [0:0] g_0_io_in_9_ready, i_0_io_in_9_ready;
  logic [0:0] g_0_io_in_8_ready, i_0_io_in_8_ready;
  logic [0:0] g_0_io_in_7_ready, i_0_io_in_7_ready;
  logic [0:0] g_0_io_in_5_ready, i_0_io_in_5_ready;
  logic [0:0] g_0_io_in_4_ready, i_0_io_in_4_ready;
  logic [0:0] g_0_io_in_3_ready, i_0_io_in_3_ready;
  logic [0:0] g_0_io_in_2_ready, i_0_io_in_2_ready;
  logic [0:0] g_0_io_in_1_ready, i_0_io_in_1_ready;
  logic [0:0] g_0_io_in_0_ready, i_0_io_in_0_ready;
  logic [0:0] g_0_io_out_7_valid, i_0_io_out_7_valid;
  logic [0:0] g_0_io_out_7_bits_rfWen, i_0_io_out_7_bits_rfWen;
  logic [7:0] g_0_io_out_7_bits_pdest, i_0_io_out_7_bits_pdest;
  logic [63:0] g_0_io_out_7_bits_data, i_0_io_out_7_bits_data;
  logic [0:0] g_0_io_out_6_valid, i_0_io_out_6_valid;
  logic [0:0] g_0_io_out_6_bits_rfWen, i_0_io_out_6_bits_rfWen;
  logic [7:0] g_0_io_out_6_bits_pdest, i_0_io_out_6_bits_pdest;
  logic [63:0] g_0_io_out_6_bits_data, i_0_io_out_6_bits_data;
  logic [0:0] g_0_io_out_5_valid, i_0_io_out_5_valid;
  logic [0:0] g_0_io_out_5_bits_rfWen, i_0_io_out_5_bits_rfWen;
  logic [7:0] g_0_io_out_5_bits_pdest, i_0_io_out_5_bits_pdest;
  logic [63:0] g_0_io_out_5_bits_data, i_0_io_out_5_bits_data;
  logic [0:0] g_0_io_out_4_valid, i_0_io_out_4_valid;
  logic [0:0] g_0_io_out_4_bits_rfWen, i_0_io_out_4_bits_rfWen;
  logic [7:0] g_0_io_out_4_bits_pdest, i_0_io_out_4_bits_pdest;
  logic [63:0] g_0_io_out_4_bits_data, i_0_io_out_4_bits_data;
  logic [0:0] g_0_io_out_3_valid, i_0_io_out_3_valid;
  logic [0:0] g_0_io_out_3_bits_rfWen, i_0_io_out_3_bits_rfWen;
  logic [7:0] g_0_io_out_3_bits_pdest, i_0_io_out_3_bits_pdest;
  logic [63:0] g_0_io_out_3_bits_data, i_0_io_out_3_bits_data;
  logic [0:0] g_0_io_out_2_valid, i_0_io_out_2_valid;
  logic [0:0] g_0_io_out_2_bits_rfWen, i_0_io_out_2_bits_rfWen;
  logic [7:0] g_0_io_out_2_bits_pdest, i_0_io_out_2_bits_pdest;
  logic [63:0] g_0_io_out_2_bits_data, i_0_io_out_2_bits_data;
  logic [0:0] g_0_io_out_1_valid, i_0_io_out_1_valid;
  logic [0:0] g_0_io_out_1_bits_rfWen, i_0_io_out_1_bits_rfWen;
  logic [7:0] g_0_io_out_1_bits_pdest, i_0_io_out_1_bits_pdest;
  logic [63:0] g_0_io_out_1_bits_data, i_0_io_out_1_bits_data;
  logic [0:0] g_0_io_out_0_valid, i_0_io_out_0_valid;
  logic [0:0] g_0_io_out_0_bits_rfWen, i_0_io_out_0_bits_rfWen;
  logic [7:0] g_0_io_out_0_bits_pdest, i_0_io_out_0_bits_pdest;
  logic [63:0] g_0_io_out_0_bits_data, i_0_io_out_0_bits_data;
  RealWBCollideChecker u_g0 (
    .io_in_14_valid (vld[0][14]),
    .io_in_14_bits_rfWen (w1[14]),
    .io_in_14_bits_fpWen (w2[14]),
    .io_in_14_bits_pdest (pd[14][7:0]),
    .io_in_14_bits_data (dat[14][63:0]),
    .io_in_13_valid (vld[0][13]),
    .io_in_13_bits_rfWen (w1[13]),
    .io_in_13_bits_fpWen (w2[13]),
    .io_in_13_bits_pdest (pd[13][7:0]),
    .io_in_13_bits_data (dat[13][63:0]),
    .io_in_12_valid (vld[0][12]),
    .io_in_12_bits_rfWen (w1[12]),
    .io_in_12_bits_fpWen (w2[12]),
    .io_in_12_bits_pdest (pd[12][7:0]),
    .io_in_12_bits_data (dat[12][63:0]),
    .io_in_11_ready (g_0_io_in_11_ready),
    .io_in_11_valid (vld[0][11]),
    .io_in_11_bits_rfWen (w1[11]),
    .io_in_11_bits_pdest (pd[11][7:0]),
    .io_in_11_bits_data (dat[11][63:0]),
    .io_in_10_ready (g_0_io_in_10_ready),
    .io_in_10_valid (vld[0][10]),
    .io_in_10_bits_rfWen (w1[10]),
    .io_in_10_bits_fpWen (w2[10]),
    .io_in_10_bits_pdest (pd[10][7:0]),
    .io_in_10_bits_data (dat[10][63:0]),
    .io_in_9_ready (g_0_io_in_9_ready),
    .io_in_9_valid (vld[0][9]),
    .io_in_9_bits_rfWen (w1[9]),
    .io_in_9_bits_pdest (pd[9][7:0]),
    .io_in_9_bits_data (dat[9][63:0]),
    .io_in_8_ready (g_0_io_in_8_ready),
    .io_in_8_valid (vld[0][8]),
    .io_in_8_bits_rfWen (w1[8]),
    .io_in_8_bits_pdest (pd[8][7:0]),
    .io_in_8_bits_data (dat[8][63:0]),
    .io_in_7_ready (g_0_io_in_7_ready),
    .io_in_7_valid (vld[0][7]),
    .io_in_7_bits_rfWen (w1[7]),
    .io_in_7_bits_pdest (pd[7][7:0]),
    .io_in_7_bits_data (dat[7][63:0]),
    .io_in_6_valid (vld[0][6]),
    .io_in_6_bits_rfWen (w1[6]),
    .io_in_6_bits_pdest (pd[6][7:0]),
    .io_in_6_bits_data (dat[6][63:0]),
    .io_in_5_ready (g_0_io_in_5_ready),
    .io_in_5_valid (vld[0][5]),
    .io_in_5_bits_rfWen (w1[5]),
    .io_in_5_bits_fpWen (w2[5]),
    .io_in_5_bits_pdest (pd[5][7:0]),
    .io_in_5_bits_data (dat[5][63:0]),
    .io_in_4_ready (g_0_io_in_4_ready),
    .io_in_4_valid (vld[0][4]),
    .io_in_4_bits_rfWen (w1[4]),
    .io_in_4_bits_pdest (pd[4][7:0]),
    .io_in_4_bits_data (dat[4][63:0]),
    .io_in_3_ready (g_0_io_in_3_ready),
    .io_in_3_valid (vld[0][3]),
    .io_in_3_bits_rfWen (w1[3]),
    .io_in_3_bits_pdest (pd[3][7:0]),
    .io_in_3_bits_data (dat[3][63:0]),
    .io_in_2_ready (g_0_io_in_2_ready),
    .io_in_2_valid (vld[0][2]),
    .io_in_2_bits_rfWen (w1[2]),
    .io_in_2_bits_pdest (pd[2][7:0]),
    .io_in_2_bits_data (dat[2][63:0]),
    .io_in_1_ready (g_0_io_in_1_ready),
    .io_in_1_valid (vld[0][1]),
    .io_in_1_bits_rfWen (w1[1]),
    .io_in_1_bits_pdest (pd[1][7:0]),
    .io_in_1_bits_data (dat[1][63:0]),
    .io_in_0_ready (g_0_io_in_0_ready),
    .io_in_0_valid (vld[0][0]),
    .io_in_0_bits_rfWen (w1[0]),
    .io_in_0_bits_pdest (pd[0][7:0]),
    .io_in_0_bits_data (dat[0][63:0]),
    .io_out_7_valid (g_0_io_out_7_valid),
    .io_out_7_bits_rfWen (g_0_io_out_7_bits_rfWen),
    .io_out_7_bits_pdest (g_0_io_out_7_bits_pdest),
    .io_out_7_bits_data (g_0_io_out_7_bits_data),
    .io_out_6_valid (g_0_io_out_6_valid),
    .io_out_6_bits_rfWen (g_0_io_out_6_bits_rfWen),
    .io_out_6_bits_pdest (g_0_io_out_6_bits_pdest),
    .io_out_6_bits_data (g_0_io_out_6_bits_data),
    .io_out_5_valid (g_0_io_out_5_valid),
    .io_out_5_bits_rfWen (g_0_io_out_5_bits_rfWen),
    .io_out_5_bits_pdest (g_0_io_out_5_bits_pdest),
    .io_out_5_bits_data (g_0_io_out_5_bits_data),
    .io_out_4_valid (g_0_io_out_4_valid),
    .io_out_4_bits_rfWen (g_0_io_out_4_bits_rfWen),
    .io_out_4_bits_pdest (g_0_io_out_4_bits_pdest),
    .io_out_4_bits_data (g_0_io_out_4_bits_data),
    .io_out_3_valid (g_0_io_out_3_valid),
    .io_out_3_bits_rfWen (g_0_io_out_3_bits_rfWen),
    .io_out_3_bits_pdest (g_0_io_out_3_bits_pdest),
    .io_out_3_bits_data (g_0_io_out_3_bits_data),
    .io_out_2_valid (g_0_io_out_2_valid),
    .io_out_2_bits_rfWen (g_0_io_out_2_bits_rfWen),
    .io_out_2_bits_pdest (g_0_io_out_2_bits_pdest),
    .io_out_2_bits_data (g_0_io_out_2_bits_data),
    .io_out_1_valid (g_0_io_out_1_valid),
    .io_out_1_bits_rfWen (g_0_io_out_1_bits_rfWen),
    .io_out_1_bits_pdest (g_0_io_out_1_bits_pdest),
    .io_out_1_bits_data (g_0_io_out_1_bits_data),
    .io_out_0_valid (g_0_io_out_0_valid),
    .io_out_0_bits_rfWen (g_0_io_out_0_bits_rfWen),
    .io_out_0_bits_pdest (g_0_io_out_0_bits_pdest),
    .io_out_0_bits_data (g_0_io_out_0_bits_data)
  );
  RealWBCollideChecker_xs u_i0 (
    .io_in_14_valid (vld[0][14]),
    .io_in_14_bits_rfWen (w1[14]),
    .io_in_14_bits_fpWen (w2[14]),
    .io_in_14_bits_pdest (pd[14][7:0]),
    .io_in_14_bits_data (dat[14][63:0]),
    .io_in_13_valid (vld[0][13]),
    .io_in_13_bits_rfWen (w1[13]),
    .io_in_13_bits_fpWen (w2[13]),
    .io_in_13_bits_pdest (pd[13][7:0]),
    .io_in_13_bits_data (dat[13][63:0]),
    .io_in_12_valid (vld[0][12]),
    .io_in_12_bits_rfWen (w1[12]),
    .io_in_12_bits_fpWen (w2[12]),
    .io_in_12_bits_pdest (pd[12][7:0]),
    .io_in_12_bits_data (dat[12][63:0]),
    .io_in_11_ready (i_0_io_in_11_ready),
    .io_in_11_valid (vld[0][11]),
    .io_in_11_bits_rfWen (w1[11]),
    .io_in_11_bits_pdest (pd[11][7:0]),
    .io_in_11_bits_data (dat[11][63:0]),
    .io_in_10_ready (i_0_io_in_10_ready),
    .io_in_10_valid (vld[0][10]),
    .io_in_10_bits_rfWen (w1[10]),
    .io_in_10_bits_fpWen (w2[10]),
    .io_in_10_bits_pdest (pd[10][7:0]),
    .io_in_10_bits_data (dat[10][63:0]),
    .io_in_9_ready (i_0_io_in_9_ready),
    .io_in_9_valid (vld[0][9]),
    .io_in_9_bits_rfWen (w1[9]),
    .io_in_9_bits_pdest (pd[9][7:0]),
    .io_in_9_bits_data (dat[9][63:0]),
    .io_in_8_ready (i_0_io_in_8_ready),
    .io_in_8_valid (vld[0][8]),
    .io_in_8_bits_rfWen (w1[8]),
    .io_in_8_bits_pdest (pd[8][7:0]),
    .io_in_8_bits_data (dat[8][63:0]),
    .io_in_7_ready (i_0_io_in_7_ready),
    .io_in_7_valid (vld[0][7]),
    .io_in_7_bits_rfWen (w1[7]),
    .io_in_7_bits_pdest (pd[7][7:0]),
    .io_in_7_bits_data (dat[7][63:0]),
    .io_in_6_valid (vld[0][6]),
    .io_in_6_bits_rfWen (w1[6]),
    .io_in_6_bits_pdest (pd[6][7:0]),
    .io_in_6_bits_data (dat[6][63:0]),
    .io_in_5_ready (i_0_io_in_5_ready),
    .io_in_5_valid (vld[0][5]),
    .io_in_5_bits_rfWen (w1[5]),
    .io_in_5_bits_fpWen (w2[5]),
    .io_in_5_bits_pdest (pd[5][7:0]),
    .io_in_5_bits_data (dat[5][63:0]),
    .io_in_4_ready (i_0_io_in_4_ready),
    .io_in_4_valid (vld[0][4]),
    .io_in_4_bits_rfWen (w1[4]),
    .io_in_4_bits_pdest (pd[4][7:0]),
    .io_in_4_bits_data (dat[4][63:0]),
    .io_in_3_ready (i_0_io_in_3_ready),
    .io_in_3_valid (vld[0][3]),
    .io_in_3_bits_rfWen (w1[3]),
    .io_in_3_bits_pdest (pd[3][7:0]),
    .io_in_3_bits_data (dat[3][63:0]),
    .io_in_2_ready (i_0_io_in_2_ready),
    .io_in_2_valid (vld[0][2]),
    .io_in_2_bits_rfWen (w1[2]),
    .io_in_2_bits_pdest (pd[2][7:0]),
    .io_in_2_bits_data (dat[2][63:0]),
    .io_in_1_ready (i_0_io_in_1_ready),
    .io_in_1_valid (vld[0][1]),
    .io_in_1_bits_rfWen (w1[1]),
    .io_in_1_bits_pdest (pd[1][7:0]),
    .io_in_1_bits_data (dat[1][63:0]),
    .io_in_0_ready (i_0_io_in_0_ready),
    .io_in_0_valid (vld[0][0]),
    .io_in_0_bits_rfWen (w1[0]),
    .io_in_0_bits_pdest (pd[0][7:0]),
    .io_in_0_bits_data (dat[0][63:0]),
    .io_out_7_valid (i_0_io_out_7_valid),
    .io_out_7_bits_rfWen (i_0_io_out_7_bits_rfWen),
    .io_out_7_bits_pdest (i_0_io_out_7_bits_pdest),
    .io_out_7_bits_data (i_0_io_out_7_bits_data),
    .io_out_6_valid (i_0_io_out_6_valid),
    .io_out_6_bits_rfWen (i_0_io_out_6_bits_rfWen),
    .io_out_6_bits_pdest (i_0_io_out_6_bits_pdest),
    .io_out_6_bits_data (i_0_io_out_6_bits_data),
    .io_out_5_valid (i_0_io_out_5_valid),
    .io_out_5_bits_rfWen (i_0_io_out_5_bits_rfWen),
    .io_out_5_bits_pdest (i_0_io_out_5_bits_pdest),
    .io_out_5_bits_data (i_0_io_out_5_bits_data),
    .io_out_4_valid (i_0_io_out_4_valid),
    .io_out_4_bits_rfWen (i_0_io_out_4_bits_rfWen),
    .io_out_4_bits_pdest (i_0_io_out_4_bits_pdest),
    .io_out_4_bits_data (i_0_io_out_4_bits_data),
    .io_out_3_valid (i_0_io_out_3_valid),
    .io_out_3_bits_rfWen (i_0_io_out_3_bits_rfWen),
    .io_out_3_bits_pdest (i_0_io_out_3_bits_pdest),
    .io_out_3_bits_data (i_0_io_out_3_bits_data),
    .io_out_2_valid (i_0_io_out_2_valid),
    .io_out_2_bits_rfWen (i_0_io_out_2_bits_rfWen),
    .io_out_2_bits_pdest (i_0_io_out_2_bits_pdest),
    .io_out_2_bits_data (i_0_io_out_2_bits_data),
    .io_out_1_valid (i_0_io_out_1_valid),
    .io_out_1_bits_rfWen (i_0_io_out_1_bits_rfWen),
    .io_out_1_bits_pdest (i_0_io_out_1_bits_pdest),
    .io_out_1_bits_data (i_0_io_out_1_bits_data),
    .io_out_0_valid (i_0_io_out_0_valid),
    .io_out_0_bits_rfWen (i_0_io_out_0_bits_rfWen),
    .io_out_0_bits_pdest (i_0_io_out_0_bits_pdest),
    .io_out_0_bits_data (i_0_io_out_0_bits_data)
  );

  // ---- RealWBCollideChecker_1 ----
  logic [0:0] g_1_io_in_9_ready, i_1_io_in_9_ready;
  logic [0:0] g_1_io_in_8_ready, i_1_io_in_8_ready;
  logic [0:0] g_1_io_in_7_ready, i_1_io_in_7_ready;
  logic [0:0] g_1_io_in_6_ready, i_1_io_in_6_ready;
  logic [0:0] g_1_io_in_5_ready, i_1_io_in_5_ready;
  logic [0:0] g_1_io_in_4_ready, i_1_io_in_4_ready;
  logic [0:0] g_1_io_in_3_ready, i_1_io_in_3_ready;
  logic [0:0] g_1_io_in_2_ready, i_1_io_in_2_ready;
  logic [0:0] g_1_io_in_1_ready, i_1_io_in_1_ready;
  logic [0:0] g_1_io_in_0_ready, i_1_io_in_0_ready;
  logic [0:0] g_1_io_out_5_valid, i_1_io_out_5_valid;
  logic [0:0] g_1_io_out_5_bits_fpWen, i_1_io_out_5_bits_fpWen;
  logic [7:0] g_1_io_out_5_bits_pdest, i_1_io_out_5_bits_pdest;
  logic [63:0] g_1_io_out_5_bits_data, i_1_io_out_5_bits_data;
  logic [0:0] g_1_io_out_4_valid, i_1_io_out_4_valid;
  logic [0:0] g_1_io_out_4_bits_fpWen, i_1_io_out_4_bits_fpWen;
  logic [7:0] g_1_io_out_4_bits_pdest, i_1_io_out_4_bits_pdest;
  logic [63:0] g_1_io_out_4_bits_data, i_1_io_out_4_bits_data;
  logic [0:0] g_1_io_out_3_valid, i_1_io_out_3_valid;
  logic [0:0] g_1_io_out_3_bits_fpWen, i_1_io_out_3_bits_fpWen;
  logic [7:0] g_1_io_out_3_bits_pdest, i_1_io_out_3_bits_pdest;
  logic [63:0] g_1_io_out_3_bits_data, i_1_io_out_3_bits_data;
  logic [0:0] g_1_io_out_2_valid, i_1_io_out_2_valid;
  logic [0:0] g_1_io_out_2_bits_fpWen, i_1_io_out_2_bits_fpWen;
  logic [7:0] g_1_io_out_2_bits_pdest, i_1_io_out_2_bits_pdest;
  logic [63:0] g_1_io_out_2_bits_data, i_1_io_out_2_bits_data;
  logic [0:0] g_1_io_out_1_valid, i_1_io_out_1_valid;
  logic [0:0] g_1_io_out_1_bits_fpWen, i_1_io_out_1_bits_fpWen;
  logic [7:0] g_1_io_out_1_bits_pdest, i_1_io_out_1_bits_pdest;
  logic [63:0] g_1_io_out_1_bits_data, i_1_io_out_1_bits_data;
  logic [0:0] g_1_io_out_0_valid, i_1_io_out_0_valid;
  logic [0:0] g_1_io_out_0_bits_fpWen, i_1_io_out_0_bits_fpWen;
  logic [7:0] g_1_io_out_0_bits_pdest, i_1_io_out_0_bits_pdest;
  logic [63:0] g_1_io_out_0_bits_data, i_1_io_out_0_bits_data;
  RealWBCollideChecker_1 u_g1 (
    .io_in_10_valid (vld[1][10]),
    .io_in_10_bits_rfWen (w2[10]),
    .io_in_10_bits_fpWen (w1[10]),
    .io_in_10_bits_pdest (pd[10][7:0]),
    .io_in_10_bits_data (dat[10][63:0]),
    .io_in_9_ready (g_1_io_in_9_ready),
    .io_in_9_valid (vld[1][9]),
    .io_in_9_bits_rfWen (w2[9]),
    .io_in_9_bits_fpWen (w1[9]),
    .io_in_9_bits_pdest (pd[9][7:0]),
    .io_in_9_bits_data (dat[9][63:0]),
    .io_in_8_ready (g_1_io_in_8_ready),
    .io_in_8_valid (vld[1][8]),
    .io_in_8_bits_rfWen (w2[8]),
    .io_in_8_bits_fpWen (w1[8]),
    .io_in_8_bits_pdest (pd[8][7:0]),
    .io_in_8_bits_data (dat[8][63:0]),
    .io_in_7_ready (g_1_io_in_7_ready),
    .io_in_7_valid (vld[1][7]),
    .io_in_7_bits_fpWen (w1[7]),
    .io_in_7_bits_pdest (pd[7][7:0]),
    .io_in_7_bits_data (dat[7][63:0]),
    .io_in_6_ready (g_1_io_in_6_ready),
    .io_in_6_valid (vld[1][6]),
    .io_in_6_bits_rfWen (w2[6]),
    .io_in_6_bits_fpWen (w1[6]),
    .io_in_6_bits_pdest (pd[6][7:0]),
    .io_in_6_bits_data (dat[6][63:0]),
    .io_in_5_ready (g_1_io_in_5_ready),
    .io_in_5_valid (vld[1][5]),
    .io_in_5_bits_rfWen (w2[5]),
    .io_in_5_bits_fpWen (w1[5]),
    .io_in_5_bits_pdest (pd[5][7:0]),
    .io_in_5_bits_data (dat[5][63:0]),
    .io_in_4_ready (g_1_io_in_4_ready),
    .io_in_4_valid (vld[1][4]),
    .io_in_4_bits_fpWen (w1[4]),
    .io_in_4_bits_pdest (pd[4][7:0]),
    .io_in_4_bits_data (dat[4][63:0]),
    .io_in_3_ready (g_1_io_in_3_ready),
    .io_in_3_valid (vld[1][3]),
    .io_in_3_bits_rfWen (w2[3]),
    .io_in_3_bits_fpWen (w1[3]),
    .io_in_3_bits_pdest (pd[3][7:0]),
    .io_in_3_bits_data (dat[3][63:0]),
    .io_in_2_ready (g_1_io_in_2_ready),
    .io_in_2_valid (vld[1][2]),
    .io_in_2_bits_fpWen (w1[2]),
    .io_in_2_bits_pdest (pd[2][7:0]),
    .io_in_2_bits_data (dat[2][63:0]),
    .io_in_1_ready (g_1_io_in_1_ready),
    .io_in_1_valid (vld[1][1]),
    .io_in_1_bits_rfWen (w2[1]),
    .io_in_1_bits_fpWen (w1[1]),
    .io_in_1_bits_pdest (pd[1][7:0]),
    .io_in_1_bits_data (dat[1][63:0]),
    .io_in_0_ready (g_1_io_in_0_ready),
    .io_in_0_valid (vld[1][0]),
    .io_in_0_bits_rfWen (w2[0]),
    .io_in_0_bits_fpWen (w1[0]),
    .io_in_0_bits_pdest (pd[0][7:0]),
    .io_in_0_bits_data (dat[0][63:0]),
    .io_out_5_valid (g_1_io_out_5_valid),
    .io_out_5_bits_fpWen (g_1_io_out_5_bits_fpWen),
    .io_out_5_bits_pdest (g_1_io_out_5_bits_pdest),
    .io_out_5_bits_data (g_1_io_out_5_bits_data),
    .io_out_4_valid (g_1_io_out_4_valid),
    .io_out_4_bits_fpWen (g_1_io_out_4_bits_fpWen),
    .io_out_4_bits_pdest (g_1_io_out_4_bits_pdest),
    .io_out_4_bits_data (g_1_io_out_4_bits_data),
    .io_out_3_valid (g_1_io_out_3_valid),
    .io_out_3_bits_fpWen (g_1_io_out_3_bits_fpWen),
    .io_out_3_bits_pdest (g_1_io_out_3_bits_pdest),
    .io_out_3_bits_data (g_1_io_out_3_bits_data),
    .io_out_2_valid (g_1_io_out_2_valid),
    .io_out_2_bits_fpWen (g_1_io_out_2_bits_fpWen),
    .io_out_2_bits_pdest (g_1_io_out_2_bits_pdest),
    .io_out_2_bits_data (g_1_io_out_2_bits_data),
    .io_out_1_valid (g_1_io_out_1_valid),
    .io_out_1_bits_fpWen (g_1_io_out_1_bits_fpWen),
    .io_out_1_bits_pdest (g_1_io_out_1_bits_pdest),
    .io_out_1_bits_data (g_1_io_out_1_bits_data),
    .io_out_0_valid (g_1_io_out_0_valid),
    .io_out_0_bits_fpWen (g_1_io_out_0_bits_fpWen),
    .io_out_0_bits_pdest (g_1_io_out_0_bits_pdest),
    .io_out_0_bits_data (g_1_io_out_0_bits_data)
  );
  RealWBCollideChecker_1_xs u_i1 (
    .io_in_10_valid (vld[1][10]),
    .io_in_10_bits_rfWen (w2[10]),
    .io_in_10_bits_fpWen (w1[10]),
    .io_in_10_bits_pdest (pd[10][7:0]),
    .io_in_10_bits_data (dat[10][63:0]),
    .io_in_9_ready (i_1_io_in_9_ready),
    .io_in_9_valid (vld[1][9]),
    .io_in_9_bits_rfWen (w2[9]),
    .io_in_9_bits_fpWen (w1[9]),
    .io_in_9_bits_pdest (pd[9][7:0]),
    .io_in_9_bits_data (dat[9][63:0]),
    .io_in_8_ready (i_1_io_in_8_ready),
    .io_in_8_valid (vld[1][8]),
    .io_in_8_bits_rfWen (w2[8]),
    .io_in_8_bits_fpWen (w1[8]),
    .io_in_8_bits_pdest (pd[8][7:0]),
    .io_in_8_bits_data (dat[8][63:0]),
    .io_in_7_ready (i_1_io_in_7_ready),
    .io_in_7_valid (vld[1][7]),
    .io_in_7_bits_fpWen (w1[7]),
    .io_in_7_bits_pdest (pd[7][7:0]),
    .io_in_7_bits_data (dat[7][63:0]),
    .io_in_6_ready (i_1_io_in_6_ready),
    .io_in_6_valid (vld[1][6]),
    .io_in_6_bits_rfWen (w2[6]),
    .io_in_6_bits_fpWen (w1[6]),
    .io_in_6_bits_pdest (pd[6][7:0]),
    .io_in_6_bits_data (dat[6][63:0]),
    .io_in_5_ready (i_1_io_in_5_ready),
    .io_in_5_valid (vld[1][5]),
    .io_in_5_bits_rfWen (w2[5]),
    .io_in_5_bits_fpWen (w1[5]),
    .io_in_5_bits_pdest (pd[5][7:0]),
    .io_in_5_bits_data (dat[5][63:0]),
    .io_in_4_ready (i_1_io_in_4_ready),
    .io_in_4_valid (vld[1][4]),
    .io_in_4_bits_fpWen (w1[4]),
    .io_in_4_bits_pdest (pd[4][7:0]),
    .io_in_4_bits_data (dat[4][63:0]),
    .io_in_3_ready (i_1_io_in_3_ready),
    .io_in_3_valid (vld[1][3]),
    .io_in_3_bits_rfWen (w2[3]),
    .io_in_3_bits_fpWen (w1[3]),
    .io_in_3_bits_pdest (pd[3][7:0]),
    .io_in_3_bits_data (dat[3][63:0]),
    .io_in_2_ready (i_1_io_in_2_ready),
    .io_in_2_valid (vld[1][2]),
    .io_in_2_bits_fpWen (w1[2]),
    .io_in_2_bits_pdest (pd[2][7:0]),
    .io_in_2_bits_data (dat[2][63:0]),
    .io_in_1_ready (i_1_io_in_1_ready),
    .io_in_1_valid (vld[1][1]),
    .io_in_1_bits_rfWen (w2[1]),
    .io_in_1_bits_fpWen (w1[1]),
    .io_in_1_bits_pdest (pd[1][7:0]),
    .io_in_1_bits_data (dat[1][63:0]),
    .io_in_0_ready (i_1_io_in_0_ready),
    .io_in_0_valid (vld[1][0]),
    .io_in_0_bits_rfWen (w2[0]),
    .io_in_0_bits_fpWen (w1[0]),
    .io_in_0_bits_pdest (pd[0][7:0]),
    .io_in_0_bits_data (dat[0][63:0]),
    .io_out_5_valid (i_1_io_out_5_valid),
    .io_out_5_bits_fpWen (i_1_io_out_5_bits_fpWen),
    .io_out_5_bits_pdest (i_1_io_out_5_bits_pdest),
    .io_out_5_bits_data (i_1_io_out_5_bits_data),
    .io_out_4_valid (i_1_io_out_4_valid),
    .io_out_4_bits_fpWen (i_1_io_out_4_bits_fpWen),
    .io_out_4_bits_pdest (i_1_io_out_4_bits_pdest),
    .io_out_4_bits_data (i_1_io_out_4_bits_data),
    .io_out_3_valid (i_1_io_out_3_valid),
    .io_out_3_bits_fpWen (i_1_io_out_3_bits_fpWen),
    .io_out_3_bits_pdest (i_1_io_out_3_bits_pdest),
    .io_out_3_bits_data (i_1_io_out_3_bits_data),
    .io_out_2_valid (i_1_io_out_2_valid),
    .io_out_2_bits_fpWen (i_1_io_out_2_bits_fpWen),
    .io_out_2_bits_pdest (i_1_io_out_2_bits_pdest),
    .io_out_2_bits_data (i_1_io_out_2_bits_data),
    .io_out_1_valid (i_1_io_out_1_valid),
    .io_out_1_bits_fpWen (i_1_io_out_1_bits_fpWen),
    .io_out_1_bits_pdest (i_1_io_out_1_bits_pdest),
    .io_out_1_bits_data (i_1_io_out_1_bits_data),
    .io_out_0_valid (i_1_io_out_0_valid),
    .io_out_0_bits_fpWen (i_1_io_out_0_bits_fpWen),
    .io_out_0_bits_pdest (i_1_io_out_0_bits_pdest),
    .io_out_0_bits_data (i_1_io_out_0_bits_data)
  );

  // ---- RealWBCollideChecker_2 ----
  logic [0:0] g_2_io_in_6_ready, i_2_io_in_6_ready;
  logic [0:0] g_2_io_in_5_ready, i_2_io_in_5_ready;
  logic [0:0] g_2_io_in_3_ready, i_2_io_in_3_ready;
  logic [0:0] g_2_io_in_2_ready, i_2_io_in_2_ready;
  logic [0:0] g_2_io_in_1_ready, i_2_io_in_1_ready;
  logic [0:0] g_2_io_in_0_ready, i_2_io_in_0_ready;
  logic [0:0] g_2_io_out_5_valid, i_2_io_out_5_valid;
  logic [0:0] g_2_io_out_5_bits_vecWen, i_2_io_out_5_bits_vecWen;
  logic [6:0] g_2_io_out_5_bits_pdest, i_2_io_out_5_bits_pdest;
  logic [127:0] g_2_io_out_5_bits_data, i_2_io_out_5_bits_data;
  logic [0:0] g_2_io_out_4_valid, i_2_io_out_4_valid;
  logic [0:0] g_2_io_out_4_bits_vecWen, i_2_io_out_4_bits_vecWen;
  logic [6:0] g_2_io_out_4_bits_pdest, i_2_io_out_4_bits_pdest;
  logic [127:0] g_2_io_out_4_bits_data, i_2_io_out_4_bits_data;
  logic [0:0] g_2_io_out_3_valid, i_2_io_out_3_valid;
  logic [0:0] g_2_io_out_3_bits_vecWen, i_2_io_out_3_bits_vecWen;
  logic [6:0] g_2_io_out_3_bits_pdest, i_2_io_out_3_bits_pdest;
  logic [127:0] g_2_io_out_3_bits_data, i_2_io_out_3_bits_data;
  logic [0:0] g_2_io_out_2_valid, i_2_io_out_2_valid;
  logic [0:0] g_2_io_out_2_bits_vecWen, i_2_io_out_2_bits_vecWen;
  logic [6:0] g_2_io_out_2_bits_pdest, i_2_io_out_2_bits_pdest;
  logic [127:0] g_2_io_out_2_bits_data, i_2_io_out_2_bits_data;
  logic [0:0] g_2_io_out_1_valid, i_2_io_out_1_valid;
  logic [0:0] g_2_io_out_1_bits_vecWen, i_2_io_out_1_bits_vecWen;
  logic [6:0] g_2_io_out_1_bits_pdest, i_2_io_out_1_bits_pdest;
  logic [127:0] g_2_io_out_1_bits_data, i_2_io_out_1_bits_data;
  logic [0:0] g_2_io_out_0_valid, i_2_io_out_0_valid;
  logic [0:0] g_2_io_out_0_bits_vecWen, i_2_io_out_0_bits_vecWen;
  logic [6:0] g_2_io_out_0_bits_pdest, i_2_io_out_0_bits_pdest;
  logic [127:0] g_2_io_out_0_bits_data, i_2_io_out_0_bits_data;
  RealWBCollideChecker_2 u_g2 (
    .io_in_8_valid (vld[2][8]),
    .io_in_8_bits_vecWen (w1[8]),
    .io_in_8_bits_pdest (pd[8][6:0]),
    .io_in_8_bits_data (dat[8][127:0]),
    .io_in_7_valid (vld[2][7]),
    .io_in_7_bits_vecWen (w1[7]),
    .io_in_7_bits_pdest (pd[7][6:0]),
    .io_in_7_bits_data (dat[7][127:0]),
    .io_in_6_ready (g_2_io_in_6_ready),
    .io_in_6_valid (vld[2][6]),
    .io_in_6_bits_vecWen (w1[6]),
    .io_in_6_bits_pdest (pd[6][6:0]),
    .io_in_6_bits_data (dat[6][127:0]),
    .io_in_5_ready (g_2_io_in_5_ready),
    .io_in_5_valid (vld[2][5]),
    .io_in_5_bits_vecWen (w1[5]),
    .io_in_5_bits_pdest (pd[5][6:0]),
    .io_in_5_bits_data (dat[5][127:0]),
    .io_in_4_valid (vld[2][4]),
    .io_in_4_bits_vecWen (w1[4]),
    .io_in_4_bits_pdest (pd[4][6:0]),
    .io_in_4_bits_data (dat[4][127:0]),
    .io_in_3_ready (g_2_io_in_3_ready),
    .io_in_3_valid (vld[2][3]),
    .io_in_3_bits_vecWen (w1[3]),
    .io_in_3_bits_pdest (pd[3][6:0]),
    .io_in_3_bits_data (dat[3][127:0]),
    .io_in_2_ready (g_2_io_in_2_ready),
    .io_in_2_valid (vld[2][2]),
    .io_in_2_bits_vecWen (w1[2]),
    .io_in_2_bits_pdest (pd[2][6:0]),
    .io_in_2_bits_data (dat[2][127:0]),
    .io_in_1_ready (g_2_io_in_1_ready),
    .io_in_1_valid (vld[2][1]),
    .io_in_1_bits_vecWen (w1[1]),
    .io_in_1_bits_pdest (pd[1][6:0]),
    .io_in_1_bits_data (dat[1][127:0]),
    .io_in_0_ready (g_2_io_in_0_ready),
    .io_in_0_valid (vld[2][0]),
    .io_in_0_bits_vecWen (w1[0]),
    .io_in_0_bits_pdest (pd[0][6:0]),
    .io_in_0_bits_data (dat[0][127:0]),
    .io_out_5_valid (g_2_io_out_5_valid),
    .io_out_5_bits_vecWen (g_2_io_out_5_bits_vecWen),
    .io_out_5_bits_pdest (g_2_io_out_5_bits_pdest),
    .io_out_5_bits_data (g_2_io_out_5_bits_data),
    .io_out_4_valid (g_2_io_out_4_valid),
    .io_out_4_bits_vecWen (g_2_io_out_4_bits_vecWen),
    .io_out_4_bits_pdest (g_2_io_out_4_bits_pdest),
    .io_out_4_bits_data (g_2_io_out_4_bits_data),
    .io_out_3_valid (g_2_io_out_3_valid),
    .io_out_3_bits_vecWen (g_2_io_out_3_bits_vecWen),
    .io_out_3_bits_pdest (g_2_io_out_3_bits_pdest),
    .io_out_3_bits_data (g_2_io_out_3_bits_data),
    .io_out_2_valid (g_2_io_out_2_valid),
    .io_out_2_bits_vecWen (g_2_io_out_2_bits_vecWen),
    .io_out_2_bits_pdest (g_2_io_out_2_bits_pdest),
    .io_out_2_bits_data (g_2_io_out_2_bits_data),
    .io_out_1_valid (g_2_io_out_1_valid),
    .io_out_1_bits_vecWen (g_2_io_out_1_bits_vecWen),
    .io_out_1_bits_pdest (g_2_io_out_1_bits_pdest),
    .io_out_1_bits_data (g_2_io_out_1_bits_data),
    .io_out_0_valid (g_2_io_out_0_valid),
    .io_out_0_bits_vecWen (g_2_io_out_0_bits_vecWen),
    .io_out_0_bits_pdest (g_2_io_out_0_bits_pdest),
    .io_out_0_bits_data (g_2_io_out_0_bits_data)
  );
  RealWBCollideChecker_2_xs u_i2 (
    .io_in_8_valid (vld[2][8]),
    .io_in_8_bits_vecWen (w1[8]),
    .io_in_8_bits_pdest (pd[8][6:0]),
    .io_in_8_bits_data (dat[8][127:0]),
    .io_in_7_valid (vld[2][7]),
    .io_in_7_bits_vecWen (w1[7]),
    .io_in_7_bits_pdest (pd[7][6:0]),
    .io_in_7_bits_data (dat[7][127:0]),
    .io_in_6_ready (i_2_io_in_6_ready),
    .io_in_6_valid (vld[2][6]),
    .io_in_6_bits_vecWen (w1[6]),
    .io_in_6_bits_pdest (pd[6][6:0]),
    .io_in_6_bits_data (dat[6][127:0]),
    .io_in_5_ready (i_2_io_in_5_ready),
    .io_in_5_valid (vld[2][5]),
    .io_in_5_bits_vecWen (w1[5]),
    .io_in_5_bits_pdest (pd[5][6:0]),
    .io_in_5_bits_data (dat[5][127:0]),
    .io_in_4_valid (vld[2][4]),
    .io_in_4_bits_vecWen (w1[4]),
    .io_in_4_bits_pdest (pd[4][6:0]),
    .io_in_4_bits_data (dat[4][127:0]),
    .io_in_3_ready (i_2_io_in_3_ready),
    .io_in_3_valid (vld[2][3]),
    .io_in_3_bits_vecWen (w1[3]),
    .io_in_3_bits_pdest (pd[3][6:0]),
    .io_in_3_bits_data (dat[3][127:0]),
    .io_in_2_ready (i_2_io_in_2_ready),
    .io_in_2_valid (vld[2][2]),
    .io_in_2_bits_vecWen (w1[2]),
    .io_in_2_bits_pdest (pd[2][6:0]),
    .io_in_2_bits_data (dat[2][127:0]),
    .io_in_1_ready (i_2_io_in_1_ready),
    .io_in_1_valid (vld[2][1]),
    .io_in_1_bits_vecWen (w1[1]),
    .io_in_1_bits_pdest (pd[1][6:0]),
    .io_in_1_bits_data (dat[1][127:0]),
    .io_in_0_ready (i_2_io_in_0_ready),
    .io_in_0_valid (vld[2][0]),
    .io_in_0_bits_vecWen (w1[0]),
    .io_in_0_bits_pdest (pd[0][6:0]),
    .io_in_0_bits_data (dat[0][127:0]),
    .io_out_5_valid (i_2_io_out_5_valid),
    .io_out_5_bits_vecWen (i_2_io_out_5_bits_vecWen),
    .io_out_5_bits_pdest (i_2_io_out_5_bits_pdest),
    .io_out_5_bits_data (i_2_io_out_5_bits_data),
    .io_out_4_valid (i_2_io_out_4_valid),
    .io_out_4_bits_vecWen (i_2_io_out_4_bits_vecWen),
    .io_out_4_bits_pdest (i_2_io_out_4_bits_pdest),
    .io_out_4_bits_data (i_2_io_out_4_bits_data),
    .io_out_3_valid (i_2_io_out_3_valid),
    .io_out_3_bits_vecWen (i_2_io_out_3_bits_vecWen),
    .io_out_3_bits_pdest (i_2_io_out_3_bits_pdest),
    .io_out_3_bits_data (i_2_io_out_3_bits_data),
    .io_out_2_valid (i_2_io_out_2_valid),
    .io_out_2_bits_vecWen (i_2_io_out_2_bits_vecWen),
    .io_out_2_bits_pdest (i_2_io_out_2_bits_pdest),
    .io_out_2_bits_data (i_2_io_out_2_bits_data),
    .io_out_1_valid (i_2_io_out_1_valid),
    .io_out_1_bits_vecWen (i_2_io_out_1_bits_vecWen),
    .io_out_1_bits_pdest (i_2_io_out_1_bits_pdest),
    .io_out_1_bits_data (i_2_io_out_1_bits_data),
    .io_out_0_valid (i_2_io_out_0_valid),
    .io_out_0_bits_vecWen (i_2_io_out_0_bits_vecWen),
    .io_out_0_bits_pdest (i_2_io_out_0_bits_pdest),
    .io_out_0_bits_data (i_2_io_out_0_bits_data)
  );

  // ---- RealWBCollideChecker_3 ----
  logic [0:0] g_3_io_in_6_ready, i_3_io_in_6_ready;
  logic [0:0] g_3_io_in_5_ready, i_3_io_in_5_ready;
  logic [0:0] g_3_io_in_3_ready, i_3_io_in_3_ready;
  logic [0:0] g_3_io_in_2_ready, i_3_io_in_2_ready;
  logic [0:0] g_3_io_in_1_ready, i_3_io_in_1_ready;
  logic [0:0] g_3_io_in_0_ready, i_3_io_in_0_ready;
  logic [0:0] g_3_io_out_5_valid, i_3_io_out_5_valid;
  logic [0:0] g_3_io_out_5_bits_v0Wen, i_3_io_out_5_bits_v0Wen;
  logic [4:0] g_3_io_out_5_bits_pdest, i_3_io_out_5_bits_pdest;
  logic [127:0] g_3_io_out_5_bits_data, i_3_io_out_5_bits_data;
  logic [0:0] g_3_io_out_4_valid, i_3_io_out_4_valid;
  logic [0:0] g_3_io_out_4_bits_v0Wen, i_3_io_out_4_bits_v0Wen;
  logic [4:0] g_3_io_out_4_bits_pdest, i_3_io_out_4_bits_pdest;
  logic [127:0] g_3_io_out_4_bits_data, i_3_io_out_4_bits_data;
  logic [0:0] g_3_io_out_3_valid, i_3_io_out_3_valid;
  logic [0:0] g_3_io_out_3_bits_v0Wen, i_3_io_out_3_bits_v0Wen;
  logic [4:0] g_3_io_out_3_bits_pdest, i_3_io_out_3_bits_pdest;
  logic [127:0] g_3_io_out_3_bits_data, i_3_io_out_3_bits_data;
  logic [0:0] g_3_io_out_2_valid, i_3_io_out_2_valid;
  logic [0:0] g_3_io_out_2_bits_v0Wen, i_3_io_out_2_bits_v0Wen;
  logic [4:0] g_3_io_out_2_bits_pdest, i_3_io_out_2_bits_pdest;
  logic [127:0] g_3_io_out_2_bits_data, i_3_io_out_2_bits_data;
  logic [0:0] g_3_io_out_1_valid, i_3_io_out_1_valid;
  logic [0:0] g_3_io_out_1_bits_v0Wen, i_3_io_out_1_bits_v0Wen;
  logic [4:0] g_3_io_out_1_bits_pdest, i_3_io_out_1_bits_pdest;
  logic [127:0] g_3_io_out_1_bits_data, i_3_io_out_1_bits_data;
  logic [0:0] g_3_io_out_0_valid, i_3_io_out_0_valid;
  logic [0:0] g_3_io_out_0_bits_v0Wen, i_3_io_out_0_bits_v0Wen;
  logic [4:0] g_3_io_out_0_bits_pdest, i_3_io_out_0_bits_pdest;
  logic [127:0] g_3_io_out_0_bits_data, i_3_io_out_0_bits_data;
  RealWBCollideChecker_3 u_g3 (
    .io_in_8_valid (vld[3][8]),
    .io_in_8_bits_v0Wen (w1[8]),
    .io_in_8_bits_pdest (pd[8][4:0]),
    .io_in_8_bits_data (dat[8][127:0]),
    .io_in_7_valid (vld[3][7]),
    .io_in_7_bits_v0Wen (w1[7]),
    .io_in_7_bits_pdest (pd[7][4:0]),
    .io_in_7_bits_data (dat[7][127:0]),
    .io_in_6_ready (g_3_io_in_6_ready),
    .io_in_6_valid (vld[3][6]),
    .io_in_6_bits_v0Wen (w1[6]),
    .io_in_6_bits_pdest (pd[6][4:0]),
    .io_in_6_bits_data (dat[6][127:0]),
    .io_in_5_ready (g_3_io_in_5_ready),
    .io_in_5_valid (vld[3][5]),
    .io_in_5_bits_v0Wen (w1[5]),
    .io_in_5_bits_pdest (pd[5][4:0]),
    .io_in_5_bits_data (dat[5][127:0]),
    .io_in_4_valid (vld[3][4]),
    .io_in_4_bits_v0Wen (w1[4]),
    .io_in_4_bits_pdest (pd[4][4:0]),
    .io_in_4_bits_data (dat[4][127:0]),
    .io_in_3_ready (g_3_io_in_3_ready),
    .io_in_3_valid (vld[3][3]),
    .io_in_3_bits_v0Wen (w1[3]),
    .io_in_3_bits_pdest (pd[3][4:0]),
    .io_in_3_bits_data (dat[3][127:0]),
    .io_in_2_ready (g_3_io_in_2_ready),
    .io_in_2_valid (vld[3][2]),
    .io_in_2_bits_v0Wen (w1[2]),
    .io_in_2_bits_pdest (pd[2][4:0]),
    .io_in_2_bits_data (dat[2][127:0]),
    .io_in_1_ready (g_3_io_in_1_ready),
    .io_in_1_valid (vld[3][1]),
    .io_in_1_bits_v0Wen (w1[1]),
    .io_in_1_bits_pdest (pd[1][4:0]),
    .io_in_1_bits_data (dat[1][127:0]),
    .io_in_0_ready (g_3_io_in_0_ready),
    .io_in_0_valid (vld[3][0]),
    .io_in_0_bits_v0Wen (w1[0]),
    .io_in_0_bits_pdest (pd[0][4:0]),
    .io_in_0_bits_data (dat[0][127:0]),
    .io_out_5_valid (g_3_io_out_5_valid),
    .io_out_5_bits_v0Wen (g_3_io_out_5_bits_v0Wen),
    .io_out_5_bits_pdest (g_3_io_out_5_bits_pdest),
    .io_out_5_bits_data (g_3_io_out_5_bits_data),
    .io_out_4_valid (g_3_io_out_4_valid),
    .io_out_4_bits_v0Wen (g_3_io_out_4_bits_v0Wen),
    .io_out_4_bits_pdest (g_3_io_out_4_bits_pdest),
    .io_out_4_bits_data (g_3_io_out_4_bits_data),
    .io_out_3_valid (g_3_io_out_3_valid),
    .io_out_3_bits_v0Wen (g_3_io_out_3_bits_v0Wen),
    .io_out_3_bits_pdest (g_3_io_out_3_bits_pdest),
    .io_out_3_bits_data (g_3_io_out_3_bits_data),
    .io_out_2_valid (g_3_io_out_2_valid),
    .io_out_2_bits_v0Wen (g_3_io_out_2_bits_v0Wen),
    .io_out_2_bits_pdest (g_3_io_out_2_bits_pdest),
    .io_out_2_bits_data (g_3_io_out_2_bits_data),
    .io_out_1_valid (g_3_io_out_1_valid),
    .io_out_1_bits_v0Wen (g_3_io_out_1_bits_v0Wen),
    .io_out_1_bits_pdest (g_3_io_out_1_bits_pdest),
    .io_out_1_bits_data (g_3_io_out_1_bits_data),
    .io_out_0_valid (g_3_io_out_0_valid),
    .io_out_0_bits_v0Wen (g_3_io_out_0_bits_v0Wen),
    .io_out_0_bits_pdest (g_3_io_out_0_bits_pdest),
    .io_out_0_bits_data (g_3_io_out_0_bits_data)
  );
  RealWBCollideChecker_3_xs u_i3 (
    .io_in_8_valid (vld[3][8]),
    .io_in_8_bits_v0Wen (w1[8]),
    .io_in_8_bits_pdest (pd[8][4:0]),
    .io_in_8_bits_data (dat[8][127:0]),
    .io_in_7_valid (vld[3][7]),
    .io_in_7_bits_v0Wen (w1[7]),
    .io_in_7_bits_pdest (pd[7][4:0]),
    .io_in_7_bits_data (dat[7][127:0]),
    .io_in_6_ready (i_3_io_in_6_ready),
    .io_in_6_valid (vld[3][6]),
    .io_in_6_bits_v0Wen (w1[6]),
    .io_in_6_bits_pdest (pd[6][4:0]),
    .io_in_6_bits_data (dat[6][127:0]),
    .io_in_5_ready (i_3_io_in_5_ready),
    .io_in_5_valid (vld[3][5]),
    .io_in_5_bits_v0Wen (w1[5]),
    .io_in_5_bits_pdest (pd[5][4:0]),
    .io_in_5_bits_data (dat[5][127:0]),
    .io_in_4_valid (vld[3][4]),
    .io_in_4_bits_v0Wen (w1[4]),
    .io_in_4_bits_pdest (pd[4][4:0]),
    .io_in_4_bits_data (dat[4][127:0]),
    .io_in_3_ready (i_3_io_in_3_ready),
    .io_in_3_valid (vld[3][3]),
    .io_in_3_bits_v0Wen (w1[3]),
    .io_in_3_bits_pdest (pd[3][4:0]),
    .io_in_3_bits_data (dat[3][127:0]),
    .io_in_2_ready (i_3_io_in_2_ready),
    .io_in_2_valid (vld[3][2]),
    .io_in_2_bits_v0Wen (w1[2]),
    .io_in_2_bits_pdest (pd[2][4:0]),
    .io_in_2_bits_data (dat[2][127:0]),
    .io_in_1_ready (i_3_io_in_1_ready),
    .io_in_1_valid (vld[3][1]),
    .io_in_1_bits_v0Wen (w1[1]),
    .io_in_1_bits_pdest (pd[1][4:0]),
    .io_in_1_bits_data (dat[1][127:0]),
    .io_in_0_ready (i_3_io_in_0_ready),
    .io_in_0_valid (vld[3][0]),
    .io_in_0_bits_v0Wen (w1[0]),
    .io_in_0_bits_pdest (pd[0][4:0]),
    .io_in_0_bits_data (dat[0][127:0]),
    .io_out_5_valid (i_3_io_out_5_valid),
    .io_out_5_bits_v0Wen (i_3_io_out_5_bits_v0Wen),
    .io_out_5_bits_pdest (i_3_io_out_5_bits_pdest),
    .io_out_5_bits_data (i_3_io_out_5_bits_data),
    .io_out_4_valid (i_3_io_out_4_valid),
    .io_out_4_bits_v0Wen (i_3_io_out_4_bits_v0Wen),
    .io_out_4_bits_pdest (i_3_io_out_4_bits_pdest),
    .io_out_4_bits_data (i_3_io_out_4_bits_data),
    .io_out_3_valid (i_3_io_out_3_valid),
    .io_out_3_bits_v0Wen (i_3_io_out_3_bits_v0Wen),
    .io_out_3_bits_pdest (i_3_io_out_3_bits_pdest),
    .io_out_3_bits_data (i_3_io_out_3_bits_data),
    .io_out_2_valid (i_3_io_out_2_valid),
    .io_out_2_bits_v0Wen (i_3_io_out_2_bits_v0Wen),
    .io_out_2_bits_pdest (i_3_io_out_2_bits_pdest),
    .io_out_2_bits_data (i_3_io_out_2_bits_data),
    .io_out_1_valid (i_3_io_out_1_valid),
    .io_out_1_bits_v0Wen (i_3_io_out_1_bits_v0Wen),
    .io_out_1_bits_pdest (i_3_io_out_1_bits_pdest),
    .io_out_1_bits_data (i_3_io_out_1_bits_data),
    .io_out_0_valid (i_3_io_out_0_valid),
    .io_out_0_bits_v0Wen (i_3_io_out_0_bits_v0Wen),
    .io_out_0_bits_pdest (i_3_io_out_0_bits_pdest),
    .io_out_0_bits_data (i_3_io_out_0_bits_data)
  );

  // ---- RealWBCollideChecker_4 ----
  logic [0:0] g_4_io_out_3_valid, i_4_io_out_3_valid;
  logic [0:0] g_4_io_out_3_bits_vlWen, i_4_io_out_3_bits_vlWen;
  logic [4:0] g_4_io_out_3_bits_pdest, i_4_io_out_3_bits_pdest;
  logic [7:0] g_4_io_out_3_bits_data, i_4_io_out_3_bits_data;
  logic [0:0] g_4_io_out_2_valid, i_4_io_out_2_valid;
  logic [0:0] g_4_io_out_2_bits_vlWen, i_4_io_out_2_bits_vlWen;
  logic [4:0] g_4_io_out_2_bits_pdest, i_4_io_out_2_bits_pdest;
  logic [7:0] g_4_io_out_2_bits_data, i_4_io_out_2_bits_data;
  logic [0:0] g_4_io_out_1_valid, i_4_io_out_1_valid;
  logic [0:0] g_4_io_out_1_bits_vlWen, i_4_io_out_1_bits_vlWen;
  logic [4:0] g_4_io_out_1_bits_pdest, i_4_io_out_1_bits_pdest;
  logic [7:0] g_4_io_out_1_bits_data, i_4_io_out_1_bits_data;
  logic [0:0] g_4_io_out_0_valid, i_4_io_out_0_valid;
  logic [0:0] g_4_io_out_0_bits_vlWen, i_4_io_out_0_bits_vlWen;
  logic [4:0] g_4_io_out_0_bits_pdest, i_4_io_out_0_bits_pdest;
  logic [7:0] g_4_io_out_0_bits_data, i_4_io_out_0_bits_data;
  RealWBCollideChecker_4 u_g4 (
    .io_in_3_valid (vld[4][3]),
    .io_in_3_bits_vlWen (w1[3]),
    .io_in_3_bits_pdest (pd[3][4:0]),
    .io_in_3_bits_data (dat[3][7:0]),
    .io_in_2_valid (vld[4][2]),
    .io_in_2_bits_vlWen (w1[2]),
    .io_in_2_bits_pdest (pd[2][4:0]),
    .io_in_2_bits_data (dat[2][7:0]),
    .io_in_1_valid (vld[4][1]),
    .io_in_1_bits_vlWen (w1[1]),
    .io_in_1_bits_pdest (pd[1][4:0]),
    .io_in_1_bits_data (dat[1][7:0]),
    .io_in_0_valid (vld[4][0]),
    .io_in_0_bits_vlWen (w1[0]),
    .io_in_0_bits_pdest (pd[0][4:0]),
    .io_in_0_bits_data (dat[0][7:0]),
    .io_out_3_valid (g_4_io_out_3_valid),
    .io_out_3_bits_vlWen (g_4_io_out_3_bits_vlWen),
    .io_out_3_bits_pdest (g_4_io_out_3_bits_pdest),
    .io_out_3_bits_data (g_4_io_out_3_bits_data),
    .io_out_2_valid (g_4_io_out_2_valid),
    .io_out_2_bits_vlWen (g_4_io_out_2_bits_vlWen),
    .io_out_2_bits_pdest (g_4_io_out_2_bits_pdest),
    .io_out_2_bits_data (g_4_io_out_2_bits_data),
    .io_out_1_valid (g_4_io_out_1_valid),
    .io_out_1_bits_vlWen (g_4_io_out_1_bits_vlWen),
    .io_out_1_bits_pdest (g_4_io_out_1_bits_pdest),
    .io_out_1_bits_data (g_4_io_out_1_bits_data),
    .io_out_0_valid (g_4_io_out_0_valid),
    .io_out_0_bits_vlWen (g_4_io_out_0_bits_vlWen),
    .io_out_0_bits_pdest (g_4_io_out_0_bits_pdest),
    .io_out_0_bits_data (g_4_io_out_0_bits_data)
  );
  RealWBCollideChecker_4_xs u_i4 (
    .io_in_3_valid (vld[4][3]),
    .io_in_3_bits_vlWen (w1[3]),
    .io_in_3_bits_pdest (pd[3][4:0]),
    .io_in_3_bits_data (dat[3][7:0]),
    .io_in_2_valid (vld[4][2]),
    .io_in_2_bits_vlWen (w1[2]),
    .io_in_2_bits_pdest (pd[2][4:0]),
    .io_in_2_bits_data (dat[2][7:0]),
    .io_in_1_valid (vld[4][1]),
    .io_in_1_bits_vlWen (w1[1]),
    .io_in_1_bits_pdest (pd[1][4:0]),
    .io_in_1_bits_data (dat[1][7:0]),
    .io_in_0_valid (vld[4][0]),
    .io_in_0_bits_vlWen (w1[0]),
    .io_in_0_bits_pdest (pd[0][4:0]),
    .io_in_0_bits_data (dat[0][7:0]),
    .io_out_3_valid (i_4_io_out_3_valid),
    .io_out_3_bits_vlWen (i_4_io_out_3_bits_vlWen),
    .io_out_3_bits_pdest (i_4_io_out_3_bits_pdest),
    .io_out_3_bits_data (i_4_io_out_3_bits_data),
    .io_out_2_valid (i_4_io_out_2_valid),
    .io_out_2_bits_vlWen (i_4_io_out_2_bits_vlWen),
    .io_out_2_bits_pdest (i_4_io_out_2_bits_pdest),
    .io_out_2_bits_data (i_4_io_out_2_bits_data),
    .io_out_1_valid (i_4_io_out_1_valid),
    .io_out_1_bits_vlWen (i_4_io_out_1_bits_vlWen),
    .io_out_1_bits_pdest (i_4_io_out_1_bits_pdest),
    .io_out_1_bits_data (i_4_io_out_1_bits_data),
    .io_out_0_valid (i_4_io_out_0_valid),
    .io_out_0_bits_vlWen (i_4_io_out_0_bits_vlWen),
    .io_out_0_bits_pdest (i_4_io_out_0_bits_pdest),
    .io_out_0_bits_data (i_4_io_out_0_bits_data)
  );

  task automatic drive(int unsigned cyc);
    for (int v = 0; v < 5; v++) begin
      case ((cyc / 7 + v) % 6)
        0: vld[v] = '0;
        1: vld[v] = '1;
        2: vld[v] = MAXIN'(1) << $urandom_range(MAXIN-1);
        3: vld[v] = MAXIN'($urandom) & MAXIN'($urandom) & MAXIN'($urandom);
        4: vld[v] = MAXIN'($urandom) | MAXIN'($urandom);
        default: vld[v] = MAXIN'($urandom);
      endcase
    end
    w1 = MAXIN'($urandom); w2 = MAXIN'($urandom);
    for (int i = 0; i < MAXIN; i++) begin
      pd[i] = 8'($urandom);
      dat[i] = {$urandom, $urandom, $urandom, $urandom};
    end
  endtask

  task automatic compare();
    `CK(g_0_io_in_11_ready, i_0_io_in_11_ready, "RealWBCollideChecker.io_in_11_ready")
    `CK(g_0_io_in_10_ready, i_0_io_in_10_ready, "RealWBCollideChecker.io_in_10_ready")
    `CK(g_0_io_in_9_ready, i_0_io_in_9_ready, "RealWBCollideChecker.io_in_9_ready")
    `CK(g_0_io_in_8_ready, i_0_io_in_8_ready, "RealWBCollideChecker.io_in_8_ready")
    `CK(g_0_io_in_7_ready, i_0_io_in_7_ready, "RealWBCollideChecker.io_in_7_ready")
    `CK(g_0_io_in_5_ready, i_0_io_in_5_ready, "RealWBCollideChecker.io_in_5_ready")
    `CK(g_0_io_in_4_ready, i_0_io_in_4_ready, "RealWBCollideChecker.io_in_4_ready")
    `CK(g_0_io_in_3_ready, i_0_io_in_3_ready, "RealWBCollideChecker.io_in_3_ready")
    `CK(g_0_io_in_2_ready, i_0_io_in_2_ready, "RealWBCollideChecker.io_in_2_ready")
    `CK(g_0_io_in_1_ready, i_0_io_in_1_ready, "RealWBCollideChecker.io_in_1_ready")
    `CK(g_0_io_in_0_ready, i_0_io_in_0_ready, "RealWBCollideChecker.io_in_0_ready")
    `CK(g_0_io_out_7_valid, i_0_io_out_7_valid, "RealWBCollideChecker.io_out_7_valid")
    `CK(g_0_io_out_7_bits_rfWen, i_0_io_out_7_bits_rfWen, "RealWBCollideChecker.io_out_7_bits_rfWen")
    `CK(g_0_io_out_7_bits_pdest, i_0_io_out_7_bits_pdest, "RealWBCollideChecker.io_out_7_bits_pdest")
    `CK(g_0_io_out_7_bits_data, i_0_io_out_7_bits_data, "RealWBCollideChecker.io_out_7_bits_data")
    `CK(g_0_io_out_6_valid, i_0_io_out_6_valid, "RealWBCollideChecker.io_out_6_valid")
    `CK(g_0_io_out_6_bits_rfWen, i_0_io_out_6_bits_rfWen, "RealWBCollideChecker.io_out_6_bits_rfWen")
    `CK(g_0_io_out_6_bits_pdest, i_0_io_out_6_bits_pdest, "RealWBCollideChecker.io_out_6_bits_pdest")
    `CK(g_0_io_out_6_bits_data, i_0_io_out_6_bits_data, "RealWBCollideChecker.io_out_6_bits_data")
    `CK(g_0_io_out_5_valid, i_0_io_out_5_valid, "RealWBCollideChecker.io_out_5_valid")
    `CK(g_0_io_out_5_bits_rfWen, i_0_io_out_5_bits_rfWen, "RealWBCollideChecker.io_out_5_bits_rfWen")
    `CK(g_0_io_out_5_bits_pdest, i_0_io_out_5_bits_pdest, "RealWBCollideChecker.io_out_5_bits_pdest")
    `CK(g_0_io_out_5_bits_data, i_0_io_out_5_bits_data, "RealWBCollideChecker.io_out_5_bits_data")
    `CK(g_0_io_out_4_valid, i_0_io_out_4_valid, "RealWBCollideChecker.io_out_4_valid")
    `CK(g_0_io_out_4_bits_rfWen, i_0_io_out_4_bits_rfWen, "RealWBCollideChecker.io_out_4_bits_rfWen")
    `CK(g_0_io_out_4_bits_pdest, i_0_io_out_4_bits_pdest, "RealWBCollideChecker.io_out_4_bits_pdest")
    `CK(g_0_io_out_4_bits_data, i_0_io_out_4_bits_data, "RealWBCollideChecker.io_out_4_bits_data")
    `CK(g_0_io_out_3_valid, i_0_io_out_3_valid, "RealWBCollideChecker.io_out_3_valid")
    `CK(g_0_io_out_3_bits_rfWen, i_0_io_out_3_bits_rfWen, "RealWBCollideChecker.io_out_3_bits_rfWen")
    `CK(g_0_io_out_3_bits_pdest, i_0_io_out_3_bits_pdest, "RealWBCollideChecker.io_out_3_bits_pdest")
    `CK(g_0_io_out_3_bits_data, i_0_io_out_3_bits_data, "RealWBCollideChecker.io_out_3_bits_data")
    `CK(g_0_io_out_2_valid, i_0_io_out_2_valid, "RealWBCollideChecker.io_out_2_valid")
    `CK(g_0_io_out_2_bits_rfWen, i_0_io_out_2_bits_rfWen, "RealWBCollideChecker.io_out_2_bits_rfWen")
    `CK(g_0_io_out_2_bits_pdest, i_0_io_out_2_bits_pdest, "RealWBCollideChecker.io_out_2_bits_pdest")
    `CK(g_0_io_out_2_bits_data, i_0_io_out_2_bits_data, "RealWBCollideChecker.io_out_2_bits_data")
    `CK(g_0_io_out_1_valid, i_0_io_out_1_valid, "RealWBCollideChecker.io_out_1_valid")
    `CK(g_0_io_out_1_bits_rfWen, i_0_io_out_1_bits_rfWen, "RealWBCollideChecker.io_out_1_bits_rfWen")
    `CK(g_0_io_out_1_bits_pdest, i_0_io_out_1_bits_pdest, "RealWBCollideChecker.io_out_1_bits_pdest")
    `CK(g_0_io_out_1_bits_data, i_0_io_out_1_bits_data, "RealWBCollideChecker.io_out_1_bits_data")
    `CK(g_0_io_out_0_valid, i_0_io_out_0_valid, "RealWBCollideChecker.io_out_0_valid")
    `CK(g_0_io_out_0_bits_rfWen, i_0_io_out_0_bits_rfWen, "RealWBCollideChecker.io_out_0_bits_rfWen")
    `CK(g_0_io_out_0_bits_pdest, i_0_io_out_0_bits_pdest, "RealWBCollideChecker.io_out_0_bits_pdest")
    `CK(g_0_io_out_0_bits_data, i_0_io_out_0_bits_data, "RealWBCollideChecker.io_out_0_bits_data")
    `CK(g_1_io_in_9_ready, i_1_io_in_9_ready, "RealWBCollideChecker_1.io_in_9_ready")
    `CK(g_1_io_in_8_ready, i_1_io_in_8_ready, "RealWBCollideChecker_1.io_in_8_ready")
    `CK(g_1_io_in_7_ready, i_1_io_in_7_ready, "RealWBCollideChecker_1.io_in_7_ready")
    `CK(g_1_io_in_6_ready, i_1_io_in_6_ready, "RealWBCollideChecker_1.io_in_6_ready")
    `CK(g_1_io_in_5_ready, i_1_io_in_5_ready, "RealWBCollideChecker_1.io_in_5_ready")
    `CK(g_1_io_in_4_ready, i_1_io_in_4_ready, "RealWBCollideChecker_1.io_in_4_ready")
    `CK(g_1_io_in_3_ready, i_1_io_in_3_ready, "RealWBCollideChecker_1.io_in_3_ready")
    `CK(g_1_io_in_2_ready, i_1_io_in_2_ready, "RealWBCollideChecker_1.io_in_2_ready")
    `CK(g_1_io_in_1_ready, i_1_io_in_1_ready, "RealWBCollideChecker_1.io_in_1_ready")
    `CK(g_1_io_in_0_ready, i_1_io_in_0_ready, "RealWBCollideChecker_1.io_in_0_ready")
    `CK(g_1_io_out_5_valid, i_1_io_out_5_valid, "RealWBCollideChecker_1.io_out_5_valid")
    `CK(g_1_io_out_5_bits_fpWen, i_1_io_out_5_bits_fpWen, "RealWBCollideChecker_1.io_out_5_bits_fpWen")
    `CK(g_1_io_out_5_bits_pdest, i_1_io_out_5_bits_pdest, "RealWBCollideChecker_1.io_out_5_bits_pdest")
    `CK(g_1_io_out_5_bits_data, i_1_io_out_5_bits_data, "RealWBCollideChecker_1.io_out_5_bits_data")
    `CK(g_1_io_out_4_valid, i_1_io_out_4_valid, "RealWBCollideChecker_1.io_out_4_valid")
    `CK(g_1_io_out_4_bits_fpWen, i_1_io_out_4_bits_fpWen, "RealWBCollideChecker_1.io_out_4_bits_fpWen")
    `CK(g_1_io_out_4_bits_pdest, i_1_io_out_4_bits_pdest, "RealWBCollideChecker_1.io_out_4_bits_pdest")
    `CK(g_1_io_out_4_bits_data, i_1_io_out_4_bits_data, "RealWBCollideChecker_1.io_out_4_bits_data")
    `CK(g_1_io_out_3_valid, i_1_io_out_3_valid, "RealWBCollideChecker_1.io_out_3_valid")
    `CK(g_1_io_out_3_bits_fpWen, i_1_io_out_3_bits_fpWen, "RealWBCollideChecker_1.io_out_3_bits_fpWen")
    `CK(g_1_io_out_3_bits_pdest, i_1_io_out_3_bits_pdest, "RealWBCollideChecker_1.io_out_3_bits_pdest")
    `CK(g_1_io_out_3_bits_data, i_1_io_out_3_bits_data, "RealWBCollideChecker_1.io_out_3_bits_data")
    `CK(g_1_io_out_2_valid, i_1_io_out_2_valid, "RealWBCollideChecker_1.io_out_2_valid")
    `CK(g_1_io_out_2_bits_fpWen, i_1_io_out_2_bits_fpWen, "RealWBCollideChecker_1.io_out_2_bits_fpWen")
    `CK(g_1_io_out_2_bits_pdest, i_1_io_out_2_bits_pdest, "RealWBCollideChecker_1.io_out_2_bits_pdest")
    `CK(g_1_io_out_2_bits_data, i_1_io_out_2_bits_data, "RealWBCollideChecker_1.io_out_2_bits_data")
    `CK(g_1_io_out_1_valid, i_1_io_out_1_valid, "RealWBCollideChecker_1.io_out_1_valid")
    `CK(g_1_io_out_1_bits_fpWen, i_1_io_out_1_bits_fpWen, "RealWBCollideChecker_1.io_out_1_bits_fpWen")
    `CK(g_1_io_out_1_bits_pdest, i_1_io_out_1_bits_pdest, "RealWBCollideChecker_1.io_out_1_bits_pdest")
    `CK(g_1_io_out_1_bits_data, i_1_io_out_1_bits_data, "RealWBCollideChecker_1.io_out_1_bits_data")
    `CK(g_1_io_out_0_valid, i_1_io_out_0_valid, "RealWBCollideChecker_1.io_out_0_valid")
    `CK(g_1_io_out_0_bits_fpWen, i_1_io_out_0_bits_fpWen, "RealWBCollideChecker_1.io_out_0_bits_fpWen")
    `CK(g_1_io_out_0_bits_pdest, i_1_io_out_0_bits_pdest, "RealWBCollideChecker_1.io_out_0_bits_pdest")
    `CK(g_1_io_out_0_bits_data, i_1_io_out_0_bits_data, "RealWBCollideChecker_1.io_out_0_bits_data")
    `CK(g_2_io_in_6_ready, i_2_io_in_6_ready, "RealWBCollideChecker_2.io_in_6_ready")
    `CK(g_2_io_in_5_ready, i_2_io_in_5_ready, "RealWBCollideChecker_2.io_in_5_ready")
    `CK(g_2_io_in_3_ready, i_2_io_in_3_ready, "RealWBCollideChecker_2.io_in_3_ready")
    `CK(g_2_io_in_2_ready, i_2_io_in_2_ready, "RealWBCollideChecker_2.io_in_2_ready")
    `CK(g_2_io_in_1_ready, i_2_io_in_1_ready, "RealWBCollideChecker_2.io_in_1_ready")
    `CK(g_2_io_in_0_ready, i_2_io_in_0_ready, "RealWBCollideChecker_2.io_in_0_ready")
    `CK(g_2_io_out_5_valid, i_2_io_out_5_valid, "RealWBCollideChecker_2.io_out_5_valid")
    `CK(g_2_io_out_5_bits_vecWen, i_2_io_out_5_bits_vecWen, "RealWBCollideChecker_2.io_out_5_bits_vecWen")
    `CK(g_2_io_out_5_bits_pdest, i_2_io_out_5_bits_pdest, "RealWBCollideChecker_2.io_out_5_bits_pdest")
    `CK(g_2_io_out_5_bits_data, i_2_io_out_5_bits_data, "RealWBCollideChecker_2.io_out_5_bits_data")
    `CK(g_2_io_out_4_valid, i_2_io_out_4_valid, "RealWBCollideChecker_2.io_out_4_valid")
    `CK(g_2_io_out_4_bits_vecWen, i_2_io_out_4_bits_vecWen, "RealWBCollideChecker_2.io_out_4_bits_vecWen")
    `CK(g_2_io_out_4_bits_pdest, i_2_io_out_4_bits_pdest, "RealWBCollideChecker_2.io_out_4_bits_pdest")
    `CK(g_2_io_out_4_bits_data, i_2_io_out_4_bits_data, "RealWBCollideChecker_2.io_out_4_bits_data")
    `CK(g_2_io_out_3_valid, i_2_io_out_3_valid, "RealWBCollideChecker_2.io_out_3_valid")
    `CK(g_2_io_out_3_bits_vecWen, i_2_io_out_3_bits_vecWen, "RealWBCollideChecker_2.io_out_3_bits_vecWen")
    `CK(g_2_io_out_3_bits_pdest, i_2_io_out_3_bits_pdest, "RealWBCollideChecker_2.io_out_3_bits_pdest")
    `CK(g_2_io_out_3_bits_data, i_2_io_out_3_bits_data, "RealWBCollideChecker_2.io_out_3_bits_data")
    `CK(g_2_io_out_2_valid, i_2_io_out_2_valid, "RealWBCollideChecker_2.io_out_2_valid")
    `CK(g_2_io_out_2_bits_vecWen, i_2_io_out_2_bits_vecWen, "RealWBCollideChecker_2.io_out_2_bits_vecWen")
    `CK(g_2_io_out_2_bits_pdest, i_2_io_out_2_bits_pdest, "RealWBCollideChecker_2.io_out_2_bits_pdest")
    `CK(g_2_io_out_2_bits_data, i_2_io_out_2_bits_data, "RealWBCollideChecker_2.io_out_2_bits_data")
    `CK(g_2_io_out_1_valid, i_2_io_out_1_valid, "RealWBCollideChecker_2.io_out_1_valid")
    `CK(g_2_io_out_1_bits_vecWen, i_2_io_out_1_bits_vecWen, "RealWBCollideChecker_2.io_out_1_bits_vecWen")
    `CK(g_2_io_out_1_bits_pdest, i_2_io_out_1_bits_pdest, "RealWBCollideChecker_2.io_out_1_bits_pdest")
    `CK(g_2_io_out_1_bits_data, i_2_io_out_1_bits_data, "RealWBCollideChecker_2.io_out_1_bits_data")
    `CK(g_2_io_out_0_valid, i_2_io_out_0_valid, "RealWBCollideChecker_2.io_out_0_valid")
    `CK(g_2_io_out_0_bits_vecWen, i_2_io_out_0_bits_vecWen, "RealWBCollideChecker_2.io_out_0_bits_vecWen")
    `CK(g_2_io_out_0_bits_pdest, i_2_io_out_0_bits_pdest, "RealWBCollideChecker_2.io_out_0_bits_pdest")
    `CK(g_2_io_out_0_bits_data, i_2_io_out_0_bits_data, "RealWBCollideChecker_2.io_out_0_bits_data")
    `CK(g_3_io_in_6_ready, i_3_io_in_6_ready, "RealWBCollideChecker_3.io_in_6_ready")
    `CK(g_3_io_in_5_ready, i_3_io_in_5_ready, "RealWBCollideChecker_3.io_in_5_ready")
    `CK(g_3_io_in_3_ready, i_3_io_in_3_ready, "RealWBCollideChecker_3.io_in_3_ready")
    `CK(g_3_io_in_2_ready, i_3_io_in_2_ready, "RealWBCollideChecker_3.io_in_2_ready")
    `CK(g_3_io_in_1_ready, i_3_io_in_1_ready, "RealWBCollideChecker_3.io_in_1_ready")
    `CK(g_3_io_in_0_ready, i_3_io_in_0_ready, "RealWBCollideChecker_3.io_in_0_ready")
    `CK(g_3_io_out_5_valid, i_3_io_out_5_valid, "RealWBCollideChecker_3.io_out_5_valid")
    `CK(g_3_io_out_5_bits_v0Wen, i_3_io_out_5_bits_v0Wen, "RealWBCollideChecker_3.io_out_5_bits_v0Wen")
    `CK(g_3_io_out_5_bits_pdest, i_3_io_out_5_bits_pdest, "RealWBCollideChecker_3.io_out_5_bits_pdest")
    `CK(g_3_io_out_5_bits_data, i_3_io_out_5_bits_data, "RealWBCollideChecker_3.io_out_5_bits_data")
    `CK(g_3_io_out_4_valid, i_3_io_out_4_valid, "RealWBCollideChecker_3.io_out_4_valid")
    `CK(g_3_io_out_4_bits_v0Wen, i_3_io_out_4_bits_v0Wen, "RealWBCollideChecker_3.io_out_4_bits_v0Wen")
    `CK(g_3_io_out_4_bits_pdest, i_3_io_out_4_bits_pdest, "RealWBCollideChecker_3.io_out_4_bits_pdest")
    `CK(g_3_io_out_4_bits_data, i_3_io_out_4_bits_data, "RealWBCollideChecker_3.io_out_4_bits_data")
    `CK(g_3_io_out_3_valid, i_3_io_out_3_valid, "RealWBCollideChecker_3.io_out_3_valid")
    `CK(g_3_io_out_3_bits_v0Wen, i_3_io_out_3_bits_v0Wen, "RealWBCollideChecker_3.io_out_3_bits_v0Wen")
    `CK(g_3_io_out_3_bits_pdest, i_3_io_out_3_bits_pdest, "RealWBCollideChecker_3.io_out_3_bits_pdest")
    `CK(g_3_io_out_3_bits_data, i_3_io_out_3_bits_data, "RealWBCollideChecker_3.io_out_3_bits_data")
    `CK(g_3_io_out_2_valid, i_3_io_out_2_valid, "RealWBCollideChecker_3.io_out_2_valid")
    `CK(g_3_io_out_2_bits_v0Wen, i_3_io_out_2_bits_v0Wen, "RealWBCollideChecker_3.io_out_2_bits_v0Wen")
    `CK(g_3_io_out_2_bits_pdest, i_3_io_out_2_bits_pdest, "RealWBCollideChecker_3.io_out_2_bits_pdest")
    `CK(g_3_io_out_2_bits_data, i_3_io_out_2_bits_data, "RealWBCollideChecker_3.io_out_2_bits_data")
    `CK(g_3_io_out_1_valid, i_3_io_out_1_valid, "RealWBCollideChecker_3.io_out_1_valid")
    `CK(g_3_io_out_1_bits_v0Wen, i_3_io_out_1_bits_v0Wen, "RealWBCollideChecker_3.io_out_1_bits_v0Wen")
    `CK(g_3_io_out_1_bits_pdest, i_3_io_out_1_bits_pdest, "RealWBCollideChecker_3.io_out_1_bits_pdest")
    `CK(g_3_io_out_1_bits_data, i_3_io_out_1_bits_data, "RealWBCollideChecker_3.io_out_1_bits_data")
    `CK(g_3_io_out_0_valid, i_3_io_out_0_valid, "RealWBCollideChecker_3.io_out_0_valid")
    `CK(g_3_io_out_0_bits_v0Wen, i_3_io_out_0_bits_v0Wen, "RealWBCollideChecker_3.io_out_0_bits_v0Wen")
    `CK(g_3_io_out_0_bits_pdest, i_3_io_out_0_bits_pdest, "RealWBCollideChecker_3.io_out_0_bits_pdest")
    `CK(g_3_io_out_0_bits_data, i_3_io_out_0_bits_data, "RealWBCollideChecker_3.io_out_0_bits_data")
    `CK(g_4_io_out_3_valid, i_4_io_out_3_valid, "RealWBCollideChecker_4.io_out_3_valid")
    `CK(g_4_io_out_3_bits_vlWen, i_4_io_out_3_bits_vlWen, "RealWBCollideChecker_4.io_out_3_bits_vlWen")
    `CK(g_4_io_out_3_bits_pdest, i_4_io_out_3_bits_pdest, "RealWBCollideChecker_4.io_out_3_bits_pdest")
    `CK(g_4_io_out_3_bits_data, i_4_io_out_3_bits_data, "RealWBCollideChecker_4.io_out_3_bits_data")
    `CK(g_4_io_out_2_valid, i_4_io_out_2_valid, "RealWBCollideChecker_4.io_out_2_valid")
    `CK(g_4_io_out_2_bits_vlWen, i_4_io_out_2_bits_vlWen, "RealWBCollideChecker_4.io_out_2_bits_vlWen")
    `CK(g_4_io_out_2_bits_pdest, i_4_io_out_2_bits_pdest, "RealWBCollideChecker_4.io_out_2_bits_pdest")
    `CK(g_4_io_out_2_bits_data, i_4_io_out_2_bits_data, "RealWBCollideChecker_4.io_out_2_bits_data")
    `CK(g_4_io_out_1_valid, i_4_io_out_1_valid, "RealWBCollideChecker_4.io_out_1_valid")
    `CK(g_4_io_out_1_bits_vlWen, i_4_io_out_1_bits_vlWen, "RealWBCollideChecker_4.io_out_1_bits_vlWen")
    `CK(g_4_io_out_1_bits_pdest, i_4_io_out_1_bits_pdest, "RealWBCollideChecker_4.io_out_1_bits_pdest")
    `CK(g_4_io_out_1_bits_data, i_4_io_out_1_bits_data, "RealWBCollideChecker_4.io_out_1_bits_data")
    `CK(g_4_io_out_0_valid, i_4_io_out_0_valid, "RealWBCollideChecker_4.io_out_0_valid")
    `CK(g_4_io_out_0_bits_vlWen, i_4_io_out_0_bits_vlWen, "RealWBCollideChecker_4.io_out_0_bits_vlWen")
    `CK(g_4_io_out_0_bits_pdest, i_4_io_out_0_bits_pdest, "RealWBCollideChecker_4.io_out_0_bits_pdest")
    `CK(g_4_io_out_0_bits_data, i_4_io_out_0_bits_data, "RealWBCollideChecker_4.io_out_0_bits_data")
  endtask

  // 覆盖：谁赢了（按 golden 分组表，赢 = 本组排在它前面的都不请求而它请求）
  task automatic sample_cov();
    if (vld[0][0]) win_cnt[0][0]++;
    if (vld[0][1] & ~vld[0][0]) win_cnt[0][1]++;
    if (vld[0][8] & ~vld[0][0] & ~vld[0][1]) win_cnt[0][8]++;
    if (vld[0][2]) win_cnt[0][2]++;
    if (vld[0][3] & ~vld[0][2]) win_cnt[0][3]++;
    if (vld[0][11] & ~vld[0][2] & ~vld[0][3]) win_cnt[0][11]++;
    if (vld[0][9] & ~vld[0][2] & ~vld[0][3] & ~vld[0][11]) win_cnt[0][9]++;
    if (vld[0][4]) win_cnt[0][4]++;
    if (vld[0][10] & ~vld[0][4]) win_cnt[0][10]++;
    if (vld[0][6]) win_cnt[0][6]++;
    if (vld[0][5]) win_cnt[0][5]++;
    if (vld[0][7] & ~vld[0][5]) win_cnt[0][7]++;
    if (vld[0][12]) win_cnt[0][12]++;
    if (vld[0][13]) win_cnt[0][13]++;
    if (vld[0][14]) win_cnt[0][14]++;
    if (g_0_io_in_0_ready) rdy1[0][0]++; else rdy0[0][0]++;
    if (g_0_io_in_1_ready) rdy1[0][1]++; else rdy0[0][1]++;
    if (g_0_io_in_2_ready) rdy1[0][2]++; else rdy0[0][2]++;
    if (g_0_io_in_3_ready) rdy1[0][3]++; else rdy0[0][3]++;
    if (g_0_io_in_4_ready) rdy1[0][4]++; else rdy0[0][4]++;
    if (g_0_io_in_5_ready) rdy1[0][5]++; else rdy0[0][5]++;
    if (g_0_io_in_7_ready) rdy1[0][7]++; else rdy0[0][7]++;
    if (g_0_io_in_8_ready) rdy1[0][8]++; else rdy0[0][8]++;
    if (g_0_io_in_9_ready) rdy1[0][9]++; else rdy0[0][9]++;
    if (g_0_io_in_10_ready) rdy1[0][10]++; else rdy0[0][10]++;
    if (g_0_io_in_11_ready) rdy1[0][11]++; else rdy0[0][11]++;
    if (vld[1][1]) win_cnt[1][1]++;
    if (vld[1][6] & ~vld[1][1]) win_cnt[1][6]++;
    if (vld[1][3]) win_cnt[1][3]++;
    if (vld[1][7] & ~vld[1][3]) win_cnt[1][7]++;
    if (vld[1][5]) win_cnt[1][5]++;
    if (vld[1][0] & ~vld[1][5]) win_cnt[1][0]++;
    if (vld[1][8]) win_cnt[1][8]++;
    if (vld[1][2] & ~vld[1][8]) win_cnt[1][2]++;
    if (vld[1][9]) win_cnt[1][9]++;
    if (vld[1][4] & ~vld[1][9]) win_cnt[1][4]++;
    if (vld[1][10]) win_cnt[1][10]++;
    if (g_1_io_in_0_ready) rdy1[1][0]++; else rdy0[1][0]++;
    if (g_1_io_in_1_ready) rdy1[1][1]++; else rdy0[1][1]++;
    if (g_1_io_in_2_ready) rdy1[1][2]++; else rdy0[1][2]++;
    if (g_1_io_in_3_ready) rdy1[1][3]++; else rdy0[1][3]++;
    if (g_1_io_in_4_ready) rdy1[1][4]++; else rdy0[1][4]++;
    if (g_1_io_in_5_ready) rdy1[1][5]++; else rdy0[1][5]++;
    if (g_1_io_in_6_ready) rdy1[1][6]++; else rdy0[1][6]++;
    if (g_1_io_in_7_ready) rdy1[1][7]++; else rdy0[1][7]++;
    if (g_1_io_in_8_ready) rdy1[1][8]++; else rdy0[1][8]++;
    if (g_1_io_in_9_ready) rdy1[1][9]++; else rdy0[1][9]++;
    if (vld[2][2]) win_cnt[2][2]++;
    if (vld[2][3] & ~vld[2][2]) win_cnt[2][3]++;
    if (vld[2][4]) win_cnt[2][4]++;
    if (vld[2][0]) win_cnt[2][0]++;
    if (vld[2][5] & ~vld[2][0]) win_cnt[2][5]++;
    if (vld[2][1]) win_cnt[2][1]++;
    if (vld[2][6] & ~vld[2][1]) win_cnt[2][6]++;
    if (vld[2][7]) win_cnt[2][7]++;
    if (vld[2][8]) win_cnt[2][8]++;
    if (g_2_io_in_0_ready) rdy1[2][0]++; else rdy0[2][0]++;
    if (g_2_io_in_1_ready) rdy1[2][1]++; else rdy0[2][1]++;
    if (g_2_io_in_2_ready) rdy1[2][2]++; else rdy0[2][2]++;
    if (g_2_io_in_3_ready) rdy1[2][3]++; else rdy0[2][3]++;
    if (g_2_io_in_5_ready) rdy1[2][5]++; else rdy0[2][5]++;
    if (g_2_io_in_6_ready) rdy1[2][6]++; else rdy0[2][6]++;
    if (vld[3][2]) win_cnt[3][2]++;
    if (vld[3][3] & ~vld[3][2]) win_cnt[3][3]++;
    if (vld[3][4]) win_cnt[3][4]++;
    if (vld[3][0]) win_cnt[3][0]++;
    if (vld[3][5] & ~vld[3][0]) win_cnt[3][5]++;
    if (vld[3][1]) win_cnt[3][1]++;
    if (vld[3][6] & ~vld[3][1]) win_cnt[3][6]++;
    if (vld[3][7]) win_cnt[3][7]++;
    if (vld[3][8]) win_cnt[3][8]++;
    if (g_3_io_in_0_ready) rdy1[3][0]++; else rdy0[3][0]++;
    if (g_3_io_in_1_ready) rdy1[3][1]++; else rdy0[3][1]++;
    if (g_3_io_in_2_ready) rdy1[3][2]++; else rdy0[3][2]++;
    if (g_3_io_in_3_ready) rdy1[3][3]++; else rdy0[3][3]++;
    if (g_3_io_in_5_ready) rdy1[3][5]++; else rdy0[3][5]++;
    if (g_3_io_in_6_ready) rdy1[3][6]++; else rdy0[3][6]++;
    if (vld[4][0]) win_cnt[4][0]++;
    if (vld[4][1]) win_cnt[4][1]++;
    if (vld[4][2]) win_cnt[4][2]++;
    if (vld[4][3]) win_cnt[4][3]++;
  endtask

  initial begin
    int unsigned cyc;
    bit cov_ok;
    void'($value$plusargs("ncycles=%d", NCYCLES));
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      drive(cyc);
      #1;
      compare();
      sample_cov();
      @(posedge clk);
    end
    cov_ok = 1;
    if (win_cnt[0][0] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in0 never won"); end
    if (rdy1[0][0] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in0 ready never 1"); end
    if (win_cnt[0][1] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in1 never won"); end
    if (rdy1[0][1] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in1 ready never 1"); end
    if (rdy0[0][1] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in1 ready never 0"); end
    if (win_cnt[0][2] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in2 never won"); end
    if (rdy1[0][2] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in2 ready never 1"); end
    if (win_cnt[0][3] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in3 never won"); end
    if (rdy1[0][3] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in3 ready never 1"); end
    if (rdy0[0][3] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in3 ready never 0"); end
    if (win_cnt[0][4] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in4 never won"); end
    if (rdy1[0][4] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in4 ready never 1"); end
    if (win_cnt[0][5] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in5 never won"); end
    if (rdy1[0][5] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in5 ready never 1"); end
    if (win_cnt[0][6] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in6 never won"); end
    if (win_cnt[0][7] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in7 never won"); end
    if (rdy1[0][7] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in7 ready never 1"); end
    if (rdy0[0][7] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in7 ready never 0"); end
    if (win_cnt[0][8] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in8 never won"); end
    if (rdy1[0][8] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in8 ready never 1"); end
    if (rdy0[0][8] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in8 ready never 0"); end
    if (win_cnt[0][9] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in9 never won"); end
    if (rdy1[0][9] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in9 ready never 1"); end
    if (rdy0[0][9] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in9 ready never 0"); end
    if (win_cnt[0][10] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in10 never won"); end
    if (rdy1[0][10] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in10 ready never 1"); end
    if (rdy0[0][10] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in10 ready never 0"); end
    if (win_cnt[0][11] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in11 never won"); end
    if (rdy1[0][11] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in11 ready never 1"); end
    if (rdy0[0][11] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in11 ready never 0"); end
    if (win_cnt[0][12] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in12 never won"); end
    if (win_cnt[0][13] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in13 never won"); end
    if (win_cnt[0][14] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker in14 never won"); end
    if (win_cnt[1][0] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in0 never won"); end
    if (rdy1[1][0] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in0 ready never 1"); end
    if (rdy0[1][0] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in0 ready never 0"); end
    if (win_cnt[1][1] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in1 never won"); end
    if (rdy1[1][1] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in1 ready never 1"); end
    if (win_cnt[1][2] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in2 never won"); end
    if (rdy1[1][2] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in2 ready never 1"); end
    if (rdy0[1][2] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in2 ready never 0"); end
    if (win_cnt[1][3] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in3 never won"); end
    if (rdy1[1][3] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in3 ready never 1"); end
    if (win_cnt[1][4] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in4 never won"); end
    if (rdy1[1][4] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in4 ready never 1"); end
    if (rdy0[1][4] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in4 ready never 0"); end
    if (win_cnt[1][5] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in5 never won"); end
    if (rdy1[1][5] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in5 ready never 1"); end
    if (win_cnt[1][6] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in6 never won"); end
    if (rdy1[1][6] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in6 ready never 1"); end
    if (rdy0[1][6] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in6 ready never 0"); end
    if (win_cnt[1][7] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in7 never won"); end
    if (rdy1[1][7] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in7 ready never 1"); end
    if (rdy0[1][7] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in7 ready never 0"); end
    if (win_cnt[1][8] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in8 never won"); end
    if (rdy1[1][8] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in8 ready never 1"); end
    if (win_cnt[1][9] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in9 never won"); end
    if (rdy1[1][9] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in9 ready never 1"); end
    if (win_cnt[1][10] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_1 in10 never won"); end
    if (win_cnt[2][0] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_2 in0 never won"); end
    if (rdy1[2][0] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_2 in0 ready never 1"); end
    if (win_cnt[2][1] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_2 in1 never won"); end
    if (rdy1[2][1] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_2 in1 ready never 1"); end
    if (win_cnt[2][2] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_2 in2 never won"); end
    if (rdy1[2][2] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_2 in2 ready never 1"); end
    if (win_cnt[2][3] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_2 in3 never won"); end
    if (rdy1[2][3] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_2 in3 ready never 1"); end
    if (rdy0[2][3] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_2 in3 ready never 0"); end
    if (win_cnt[2][4] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_2 in4 never won"); end
    if (win_cnt[2][5] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_2 in5 never won"); end
    if (rdy1[2][5] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_2 in5 ready never 1"); end
    if (rdy0[2][5] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_2 in5 ready never 0"); end
    if (win_cnt[2][6] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_2 in6 never won"); end
    if (rdy1[2][6] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_2 in6 ready never 1"); end
    if (rdy0[2][6] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_2 in6 ready never 0"); end
    if (win_cnt[2][7] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_2 in7 never won"); end
    if (win_cnt[2][8] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_2 in8 never won"); end
    if (win_cnt[3][0] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_3 in0 never won"); end
    if (rdy1[3][0] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_3 in0 ready never 1"); end
    if (win_cnt[3][1] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_3 in1 never won"); end
    if (rdy1[3][1] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_3 in1 ready never 1"); end
    if (win_cnt[3][2] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_3 in2 never won"); end
    if (rdy1[3][2] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_3 in2 ready never 1"); end
    if (win_cnt[3][3] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_3 in3 never won"); end
    if (rdy1[3][3] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_3 in3 ready never 1"); end
    if (rdy0[3][3] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_3 in3 ready never 0"); end
    if (win_cnt[3][4] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_3 in4 never won"); end
    if (win_cnt[3][5] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_3 in5 never won"); end
    if (rdy1[3][5] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_3 in5 ready never 1"); end
    if (rdy0[3][5] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_3 in5 ready never 0"); end
    if (win_cnt[3][6] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_3 in6 never won"); end
    if (rdy1[3][6] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_3 in6 ready never 1"); end
    if (rdy0[3][6] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_3 in6 ready never 0"); end
    if (win_cnt[3][7] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_3 in7 never won"); end
    if (win_cnt[3][8] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_3 in8 never won"); end
    if (win_cnt[4][0] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_4 in0 never won"); end
    if (win_cnt[4][1] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_4 in1 never won"); end
    if (win_cnt[4][2] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_4 in2 never won"); end
    if (win_cnt[4][3] == 0) begin cov_ok = 0; $display("COVER-MISS RealWBCollideChecker_4 in3 never won"); end
    $display("COVER RealWBCollideChecker wins: %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d", win_cnt[0][0], win_cnt[0][1], win_cnt[0][2], win_cnt[0][3], win_cnt[0][4], win_cnt[0][5], win_cnt[0][6], win_cnt[0][7], win_cnt[0][8], win_cnt[0][9], win_cnt[0][10], win_cnt[0][11], win_cnt[0][12], win_cnt[0][13], win_cnt[0][14]);
    $display("COVER RealWBCollideChecker_1 wins: %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d", win_cnt[1][0], win_cnt[1][1], win_cnt[1][2], win_cnt[1][3], win_cnt[1][4], win_cnt[1][5], win_cnt[1][6], win_cnt[1][7], win_cnt[1][8], win_cnt[1][9], win_cnt[1][10]);
    $display("COVER RealWBCollideChecker_2 wins: %0d %0d %0d %0d %0d %0d %0d %0d %0d", win_cnt[2][0], win_cnt[2][1], win_cnt[2][2], win_cnt[2][3], win_cnt[2][4], win_cnt[2][5], win_cnt[2][6], win_cnt[2][7], win_cnt[2][8]);
    $display("COVER RealWBCollideChecker_3 wins: %0d %0d %0d %0d %0d %0d %0d %0d %0d", win_cnt[3][0], win_cnt[3][1], win_cnt[3][2], win_cnt[3][3], win_cnt[3][4], win_cnt[3][5], win_cnt[3][6], win_cnt[3][7], win_cnt[3][8]);
    $display("COVER RealWBCollideChecker_4 wins: %0d %0d %0d %0d", win_cnt[4][0], win_cnt[4][1], win_cnt[4][2], win_cnt[4][3]);
    $display("checks=%0d errors=%0d cover=%0d", checks, errors, cov_ok);
    if (errors == 0 && cov_ok) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
