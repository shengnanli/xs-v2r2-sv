// ============================================================================
// tb —— FuBusyTableRead 家族 UT：18 个 golden 变体与重写件逐拍双例化比对。
//
// 本族是**纯组合**的与/或矩阵，没有任何寄存器，所以「测到位」不能靠拍数，
// 只能靠覆盖：每个变体的 fuBusyTable 每一位都要取遍 0/1，每个条目的输出屏蔽位
// 都要取遍 0/1，并且**每一个非空槽都必须真的驱动过一次 1**（否则那一项的掩码
// 写错了也没人看得见）。三项全中才判 TEST PASSED。
//
// 激励形状：fuType 四种轮换 —— 全随机 35 位（超集，压满与/或矩阵）、随机 one-hot、
// 从「本族全部槽掩码的并集」里挑的 one-hot（专打有效位）、以及全 0；
// fuBusyTable 每变体独立取 5 位随机。
//
// 本文件由 scripts/gen_fubusy_wbarb.py 生成，勿手改。
// ============================================================================
`timescale 1ns/1ps
module tb;
  localparam int NV = 18;
  int unsigned NCYCLES = 200000;
  bit clk = 0; always #5 clk = ~clk;
  longint errors = 0, checks = 0;
  `define CK(g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors < 20) $display("MISMATCH %0t %s golden=%h impl=%h", $time, nm, (g), (i)); \
    end end

  localparam int NE  [NV] = '{24, 24, 24, 24, 24, 24, 18, 18, 18, 18, 16, 16, 16, 16, 16, 16, 16, 16};
  localparam int TW  [NV] = '{3, 1, 3, 1, 3, 1, 4, 3, 4, 2, 5, 4, 5, 3, 4, 2, 5, 4};
  // 每变体 5 个槽的 fuType 掩码（从 golden 解析，与 rtl 薄 wrapper 同源）
  localparam logic [34:0] SEL [NV][5] = '{
    '{35'h40, 35'h0, 35'h480, 35'h0, 35'h0},
    '{35'h1, 35'h0, 35'h0, 35'h0, 35'h0},
    '{35'h3000000b, 35'h0, 35'h4, 35'h0, 35'h0},
    '{35'h40, 35'h0, 35'h0, 35'h0, 35'h0},
    '{35'h8, 35'h0, 35'h4, 35'h0, 35'h0},
    '{35'h8, 35'h0, 35'h0, 35'h0, 35'h0},
    '{35'h10, 35'h800, 35'h2000, 35'h1000, 35'h0},
    '{35'h0, 35'h800, 35'h2000, 35'h0, 35'h0},
    '{35'h0, 35'h800, 35'h0, 35'h1000, 35'h0},
    '{35'h0, 35'h800, 35'h0, 35'h0, 35'h0},
    '{35'h0, 35'h0, 35'h80000, 35'h300000, 35'h2000000},
    '{35'h0, 35'h40000000, 35'h1000000, 35'h8040000, 35'h0},
    '{35'h0, 35'h0, 35'h40000000, 35'h0, 35'h40000},
    '{35'h0, 35'h0, 35'h1000000, 35'h0, 35'h0},
    '{35'h0, 35'h0, 35'h1000000, 35'h8040000, 35'h0},
    '{35'h0, 35'h40000000, 35'h0, 35'h0, 35'h0},
    '{35'h0, 35'h0, 35'h80000, 35'h0, 35'h2000000},
    '{35'h0, 35'h0, 35'h0, 35'h8000, 35'h0}};
  localparam logic [34:0] UNION = 35'h7b3cbcdf;   // 全族有效位并集，one-hot 激励从这里挑

  logic [34:0] ft [24];
  logic [4:0]  tbl [NV];

  // ---- FuBusyTableRead : NE=24 TW=3 ----
  logic [23:0] g_FuBusyTableRead_m, i_FuBusyTableRead_m;
  FuBusyTableRead u_g_FuBusyTableRead (
    .io_in_fuBusyTable (tbl[0][2:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_in_fuTypeRegVec_16 (ft[16]),
    .io_in_fuTypeRegVec_17 (ft[17]),
    .io_in_fuTypeRegVec_18 (ft[18]),
    .io_in_fuTypeRegVec_19 (ft[19]),
    .io_in_fuTypeRegVec_20 (ft[20]),
    .io_in_fuTypeRegVec_21 (ft[21]),
    .io_in_fuTypeRegVec_22 (ft[22]),
    .io_in_fuTypeRegVec_23 (ft[23]),
    .io_out_fuBusyTableMask (g_FuBusyTableRead_m)
  );
  FuBusyTableRead_xs u_i_FuBusyTableRead (
    .io_in_fuBusyTable (tbl[0][2:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_in_fuTypeRegVec_16 (ft[16]),
    .io_in_fuTypeRegVec_17 (ft[17]),
    .io_in_fuTypeRegVec_18 (ft[18]),
    .io_in_fuTypeRegVec_19 (ft[19]),
    .io_in_fuTypeRegVec_20 (ft[20]),
    .io_in_fuTypeRegVec_21 (ft[21]),
    .io_in_fuTypeRegVec_22 (ft[22]),
    .io_in_fuTypeRegVec_23 (ft[23]),
    .io_out_fuBusyTableMask (i_FuBusyTableRead_m)
  );
  // ---- FuBusyTableRead_2 : NE=24 TW=1 ----
  logic [23:0] g_FuBusyTableRead_2_m, i_FuBusyTableRead_2_m;
  FuBusyTableRead_2 u_g_FuBusyTableRead_2 (
    .io_in_fuBusyTable (tbl[1][0:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_in_fuTypeRegVec_16 (ft[16]),
    .io_in_fuTypeRegVec_17 (ft[17]),
    .io_in_fuTypeRegVec_18 (ft[18]),
    .io_in_fuTypeRegVec_19 (ft[19]),
    .io_in_fuTypeRegVec_20 (ft[20]),
    .io_in_fuTypeRegVec_21 (ft[21]),
    .io_in_fuTypeRegVec_22 (ft[22]),
    .io_in_fuTypeRegVec_23 (ft[23]),
    .io_out_fuBusyTableMask (g_FuBusyTableRead_2_m)
  );
  FuBusyTableRead_2_xs u_i_FuBusyTableRead_2 (
    .io_in_fuBusyTable (tbl[1][0:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_in_fuTypeRegVec_16 (ft[16]),
    .io_in_fuTypeRegVec_17 (ft[17]),
    .io_in_fuTypeRegVec_18 (ft[18]),
    .io_in_fuTypeRegVec_19 (ft[19]),
    .io_in_fuTypeRegVec_20 (ft[20]),
    .io_in_fuTypeRegVec_21 (ft[21]),
    .io_in_fuTypeRegVec_22 (ft[22]),
    .io_in_fuTypeRegVec_23 (ft[23]),
    .io_out_fuBusyTableMask (i_FuBusyTableRead_2_m)
  );
  // ---- FuBusyTableRead_22 : NE=24 TW=3 ----
  logic [23:0] g_FuBusyTableRead_22_m, i_FuBusyTableRead_22_m;
  FuBusyTableRead_22 u_g_FuBusyTableRead_22 (
    .io_in_fuBusyTable (tbl[2][2:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_in_fuTypeRegVec_16 (ft[16]),
    .io_in_fuTypeRegVec_17 (ft[17]),
    .io_in_fuTypeRegVec_18 (ft[18]),
    .io_in_fuTypeRegVec_19 (ft[19]),
    .io_in_fuTypeRegVec_20 (ft[20]),
    .io_in_fuTypeRegVec_21 (ft[21]),
    .io_in_fuTypeRegVec_22 (ft[22]),
    .io_in_fuTypeRegVec_23 (ft[23]),
    .io_out_fuBusyTableMask (g_FuBusyTableRead_22_m)
  );
  FuBusyTableRead_22_xs u_i_FuBusyTableRead_22 (
    .io_in_fuBusyTable (tbl[2][2:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_in_fuTypeRegVec_16 (ft[16]),
    .io_in_fuTypeRegVec_17 (ft[17]),
    .io_in_fuTypeRegVec_18 (ft[18]),
    .io_in_fuTypeRegVec_19 (ft[19]),
    .io_in_fuTypeRegVec_20 (ft[20]),
    .io_in_fuTypeRegVec_21 (ft[21]),
    .io_in_fuTypeRegVec_22 (ft[22]),
    .io_in_fuTypeRegVec_23 (ft[23]),
    .io_out_fuBusyTableMask (i_FuBusyTableRead_22_m)
  );
  // ---- FuBusyTableRead_23 : NE=24 TW=1 ----
  logic [23:0] g_FuBusyTableRead_23_m, i_FuBusyTableRead_23_m;
  FuBusyTableRead_23 u_g_FuBusyTableRead_23 (
    .io_in_fuBusyTable (tbl[3][0:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_in_fuTypeRegVec_16 (ft[16]),
    .io_in_fuTypeRegVec_17 (ft[17]),
    .io_in_fuTypeRegVec_18 (ft[18]),
    .io_in_fuTypeRegVec_19 (ft[19]),
    .io_in_fuTypeRegVec_20 (ft[20]),
    .io_in_fuTypeRegVec_21 (ft[21]),
    .io_in_fuTypeRegVec_22 (ft[22]),
    .io_in_fuTypeRegVec_23 (ft[23]),
    .io_out_fuBusyTableMask (g_FuBusyTableRead_23_m)
  );
  FuBusyTableRead_23_xs u_i_FuBusyTableRead_23 (
    .io_in_fuBusyTable (tbl[3][0:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_in_fuTypeRegVec_16 (ft[16]),
    .io_in_fuTypeRegVec_17 (ft[17]),
    .io_in_fuTypeRegVec_18 (ft[18]),
    .io_in_fuTypeRegVec_19 (ft[19]),
    .io_in_fuTypeRegVec_20 (ft[20]),
    .io_in_fuTypeRegVec_21 (ft[21]),
    .io_in_fuTypeRegVec_22 (ft[22]),
    .io_in_fuTypeRegVec_23 (ft[23]),
    .io_out_fuBusyTableMask (i_FuBusyTableRead_23_m)
  );
  // ---- FuBusyTableRead_26 : NE=24 TW=3 ----
  logic [23:0] g_FuBusyTableRead_26_m, i_FuBusyTableRead_26_m;
  FuBusyTableRead_26 u_g_FuBusyTableRead_26 (
    .io_in_fuBusyTable (tbl[4][2:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_in_fuTypeRegVec_16 (ft[16]),
    .io_in_fuTypeRegVec_17 (ft[17]),
    .io_in_fuTypeRegVec_18 (ft[18]),
    .io_in_fuTypeRegVec_19 (ft[19]),
    .io_in_fuTypeRegVec_20 (ft[20]),
    .io_in_fuTypeRegVec_21 (ft[21]),
    .io_in_fuTypeRegVec_22 (ft[22]),
    .io_in_fuTypeRegVec_23 (ft[23]),
    .io_out_fuBusyTableMask (g_FuBusyTableRead_26_m)
  );
  FuBusyTableRead_26_xs u_i_FuBusyTableRead_26 (
    .io_in_fuBusyTable (tbl[4][2:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_in_fuTypeRegVec_16 (ft[16]),
    .io_in_fuTypeRegVec_17 (ft[17]),
    .io_in_fuTypeRegVec_18 (ft[18]),
    .io_in_fuTypeRegVec_19 (ft[19]),
    .io_in_fuTypeRegVec_20 (ft[20]),
    .io_in_fuTypeRegVec_21 (ft[21]),
    .io_in_fuTypeRegVec_22 (ft[22]),
    .io_in_fuTypeRegVec_23 (ft[23]),
    .io_out_fuBusyTableMask (i_FuBusyTableRead_26_m)
  );
  // ---- FuBusyTableRead_28 : NE=24 TW=1 ----
  logic [23:0] g_FuBusyTableRead_28_m, i_FuBusyTableRead_28_m;
  FuBusyTableRead_28 u_g_FuBusyTableRead_28 (
    .io_in_fuBusyTable (tbl[5][0:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_in_fuTypeRegVec_16 (ft[16]),
    .io_in_fuTypeRegVec_17 (ft[17]),
    .io_in_fuTypeRegVec_18 (ft[18]),
    .io_in_fuTypeRegVec_19 (ft[19]),
    .io_in_fuTypeRegVec_20 (ft[20]),
    .io_in_fuTypeRegVec_21 (ft[21]),
    .io_in_fuTypeRegVec_22 (ft[22]),
    .io_in_fuTypeRegVec_23 (ft[23]),
    .io_out_fuBusyTableMask (g_FuBusyTableRead_28_m)
  );
  FuBusyTableRead_28_xs u_i_FuBusyTableRead_28 (
    .io_in_fuBusyTable (tbl[5][0:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_in_fuTypeRegVec_16 (ft[16]),
    .io_in_fuTypeRegVec_17 (ft[17]),
    .io_in_fuTypeRegVec_18 (ft[18]),
    .io_in_fuTypeRegVec_19 (ft[19]),
    .io_in_fuTypeRegVec_20 (ft[20]),
    .io_in_fuTypeRegVec_21 (ft[21]),
    .io_in_fuTypeRegVec_22 (ft[22]),
    .io_in_fuTypeRegVec_23 (ft[23]),
    .io_out_fuBusyTableMask (i_FuBusyTableRead_28_m)
  );
  // ---- FuBusyTableRead_42 : NE=18 TW=4 ----
  logic [17:0] g_FuBusyTableRead_42_m, i_FuBusyTableRead_42_m;
  FuBusyTableRead_42 u_g_FuBusyTableRead_42 (
    .io_in_fuBusyTable (tbl[6][3:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_in_fuTypeRegVec_16 (ft[16]),
    .io_in_fuTypeRegVec_17 (ft[17]),
    .io_out_fuBusyTableMask (g_FuBusyTableRead_42_m)
  );
  FuBusyTableRead_42_xs u_i_FuBusyTableRead_42 (
    .io_in_fuBusyTable (tbl[6][3:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_in_fuTypeRegVec_16 (ft[16]),
    .io_in_fuTypeRegVec_17 (ft[17]),
    .io_out_fuBusyTableMask (i_FuBusyTableRead_42_m)
  );
  // ---- FuBusyTableRead_43 : NE=18 TW=3 ----
  logic [17:0] g_FuBusyTableRead_43_m, i_FuBusyTableRead_43_m;
  FuBusyTableRead_43 u_g_FuBusyTableRead_43 (
    .io_in_fuBusyTable (tbl[7][2:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_in_fuTypeRegVec_16 (ft[16]),
    .io_in_fuTypeRegVec_17 (ft[17]),
    .io_out_fuBusyTableMask (g_FuBusyTableRead_43_m)
  );
  FuBusyTableRead_43_xs u_i_FuBusyTableRead_43 (
    .io_in_fuBusyTable (tbl[7][2:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_in_fuTypeRegVec_16 (ft[16]),
    .io_in_fuTypeRegVec_17 (ft[17]),
    .io_out_fuBusyTableMask (i_FuBusyTableRead_43_m)
  );
  // ---- FuBusyTableRead_52 : NE=18 TW=4 ----
  logic [17:0] g_FuBusyTableRead_52_m, i_FuBusyTableRead_52_m;
  FuBusyTableRead_52 u_g_FuBusyTableRead_52 (
    .io_in_fuBusyTable (tbl[8][3:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_in_fuTypeRegVec_16 (ft[16]),
    .io_in_fuTypeRegVec_17 (ft[17]),
    .io_out_fuBusyTableMask (g_FuBusyTableRead_52_m)
  );
  FuBusyTableRead_52_xs u_i_FuBusyTableRead_52 (
    .io_in_fuBusyTable (tbl[8][3:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_in_fuTypeRegVec_16 (ft[16]),
    .io_in_fuTypeRegVec_17 (ft[17]),
    .io_out_fuBusyTableMask (i_FuBusyTableRead_52_m)
  );
  // ---- FuBusyTableRead_53 : NE=18 TW=2 ----
  logic [17:0] g_FuBusyTableRead_53_m, i_FuBusyTableRead_53_m;
  FuBusyTableRead_53 u_g_FuBusyTableRead_53 (
    .io_in_fuBusyTable (tbl[9][1:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_in_fuTypeRegVec_16 (ft[16]),
    .io_in_fuTypeRegVec_17 (ft[17]),
    .io_out_fuBusyTableMask (g_FuBusyTableRead_53_m)
  );
  FuBusyTableRead_53_xs u_i_FuBusyTableRead_53 (
    .io_in_fuBusyTable (tbl[9][1:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_in_fuTypeRegVec_16 (ft[16]),
    .io_in_fuTypeRegVec_17 (ft[17]),
    .io_out_fuBusyTableMask (i_FuBusyTableRead_53_m)
  );
  // ---- FuBusyTableRead_68 : NE=16 TW=5 ----
  logic [15:0] g_FuBusyTableRead_68_m, i_FuBusyTableRead_68_m;
  FuBusyTableRead_68 u_g_FuBusyTableRead_68 (
    .io_in_fuBusyTable (tbl[10][4:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_out_fuBusyTableMask (g_FuBusyTableRead_68_m)
  );
  FuBusyTableRead_68_xs u_i_FuBusyTableRead_68 (
    .io_in_fuBusyTable (tbl[10][4:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_out_fuBusyTableMask (i_FuBusyTableRead_68_m)
  );
  // ---- FuBusyTableRead_69 : NE=16 TW=4 ----
  logic [15:0] g_FuBusyTableRead_69_m, i_FuBusyTableRead_69_m;
  FuBusyTableRead_69 u_g_FuBusyTableRead_69 (
    .io_in_fuBusyTable (tbl[11][3:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_out_fuBusyTableMask (g_FuBusyTableRead_69_m)
  );
  FuBusyTableRead_69_xs u_i_FuBusyTableRead_69 (
    .io_in_fuBusyTable (tbl[11][3:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_out_fuBusyTableMask (i_FuBusyTableRead_69_m)
  );
  // ---- FuBusyTableRead_71 : NE=16 TW=5 ----
  logic [15:0] g_FuBusyTableRead_71_m, i_FuBusyTableRead_71_m;
  FuBusyTableRead_71 u_g_FuBusyTableRead_71 (
    .io_in_fuBusyTable (tbl[12][4:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_out_fuBusyTableMask (g_FuBusyTableRead_71_m)
  );
  FuBusyTableRead_71_xs u_i_FuBusyTableRead_71 (
    .io_in_fuBusyTable (tbl[12][4:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_out_fuBusyTableMask (i_FuBusyTableRead_71_m)
  );
  // ---- FuBusyTableRead_73 : NE=16 TW=3 ----
  logic [15:0] g_FuBusyTableRead_73_m, i_FuBusyTableRead_73_m;
  FuBusyTableRead_73 u_g_FuBusyTableRead_73 (
    .io_in_fuBusyTable (tbl[13][2:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_out_fuBusyTableMask (g_FuBusyTableRead_73_m)
  );
  FuBusyTableRead_73_xs u_i_FuBusyTableRead_73 (
    .io_in_fuBusyTable (tbl[13][2:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_out_fuBusyTableMask (i_FuBusyTableRead_73_m)
  );
  // ---- FuBusyTableRead_75 : NE=16 TW=4 ----
  logic [15:0] g_FuBusyTableRead_75_m, i_FuBusyTableRead_75_m;
  FuBusyTableRead_75 u_g_FuBusyTableRead_75 (
    .io_in_fuBusyTable (tbl[14][3:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_out_fuBusyTableMask (g_FuBusyTableRead_75_m)
  );
  FuBusyTableRead_75_xs u_i_FuBusyTableRead_75 (
    .io_in_fuBusyTable (tbl[14][3:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_out_fuBusyTableMask (i_FuBusyTableRead_75_m)
  );
  // ---- FuBusyTableRead_79 : NE=16 TW=2 ----
  logic [15:0] g_FuBusyTableRead_79_m, i_FuBusyTableRead_79_m;
  FuBusyTableRead_79 u_g_FuBusyTableRead_79 (
    .io_in_fuBusyTable (tbl[15][1:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_out_fuBusyTableMask (g_FuBusyTableRead_79_m)
  );
  FuBusyTableRead_79_xs u_i_FuBusyTableRead_79 (
    .io_in_fuBusyTable (tbl[15][1:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_out_fuBusyTableMask (i_FuBusyTableRead_79_m)
  );
  // ---- FuBusyTableRead_80 : NE=16 TW=5 ----
  logic [15:0] g_FuBusyTableRead_80_m, i_FuBusyTableRead_80_m;
  FuBusyTableRead_80 u_g_FuBusyTableRead_80 (
    .io_in_fuBusyTable (tbl[16][4:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_out_fuBusyTableMask (g_FuBusyTableRead_80_m)
  );
  FuBusyTableRead_80_xs u_i_FuBusyTableRead_80 (
    .io_in_fuBusyTable (tbl[16][4:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_out_fuBusyTableMask (i_FuBusyTableRead_80_m)
  );
  // ---- FuBusyTableRead_105 : NE=16 TW=4 ----
  logic [15:0] g_FuBusyTableRead_105_m, i_FuBusyTableRead_105_m;
  FuBusyTableRead_105 u_g_FuBusyTableRead_105 (
    .io_in_fuBusyTable (tbl[17][3:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_out_fuBusyTableMask (g_FuBusyTableRead_105_m)
  );
  FuBusyTableRead_105_xs u_i_FuBusyTableRead_105 (
    .io_in_fuBusyTable (tbl[17][3:0]),
    .io_in_fuTypeRegVec_0 (ft[0]),
    .io_in_fuTypeRegVec_1 (ft[1]),
    .io_in_fuTypeRegVec_2 (ft[2]),
    .io_in_fuTypeRegVec_3 (ft[3]),
    .io_in_fuTypeRegVec_4 (ft[4]),
    .io_in_fuTypeRegVec_5 (ft[5]),
    .io_in_fuTypeRegVec_6 (ft[6]),
    .io_in_fuTypeRegVec_7 (ft[7]),
    .io_in_fuTypeRegVec_8 (ft[8]),
    .io_in_fuTypeRegVec_9 (ft[9]),
    .io_in_fuTypeRegVec_10 (ft[10]),
    .io_in_fuTypeRegVec_11 (ft[11]),
    .io_in_fuTypeRegVec_12 (ft[12]),
    .io_in_fuTypeRegVec_13 (ft[13]),
    .io_in_fuTypeRegVec_14 (ft[14]),
    .io_in_fuTypeRegVec_15 (ft[15]),
    .io_out_fuBusyTableMask (i_FuBusyTableRead_105_m)
  );

  // ---- 覆盖桶 ----
  bit [1:0] cov_tbl  [NV][5];    // 每变体每个表位取到过 0 / 1
  bit [1:0] cov_mask [NV][24];   // 每变体每个条目的屏蔽位取到过 0 / 1
  bit       cov_slot [NV][5];    // 每变体每个非空槽真的驱动过一次 1

  task automatic check();
    `CK(g_FuBusyTableRead_m, i_FuBusyTableRead_m, "FuBusyTableRead.mask")
    for (int b = 0; b < 3; b++) cov_tbl[0][b][tbl[0][b]] = 1'b1;
    for (int e = 0; e < 24; e++) cov_mask[0][e][g_FuBusyTableRead_m[e]] = 1'b1;
    for (int b = 0; b < 3; b++)
      if (tbl[0][b] && (|(ft[0] & SEL[0][b]))) cov_slot[0][b] = 1'b1;
    `CK(g_FuBusyTableRead_2_m, i_FuBusyTableRead_2_m, "FuBusyTableRead_2.mask")
    for (int b = 0; b < 1; b++) cov_tbl[1][b][tbl[1][b]] = 1'b1;
    for (int e = 0; e < 24; e++) cov_mask[1][e][g_FuBusyTableRead_2_m[e]] = 1'b1;
    for (int b = 0; b < 1; b++)
      if (tbl[1][b] && (|(ft[0] & SEL[1][b]))) cov_slot[1][b] = 1'b1;
    `CK(g_FuBusyTableRead_22_m, i_FuBusyTableRead_22_m, "FuBusyTableRead_22.mask")
    for (int b = 0; b < 3; b++) cov_tbl[2][b][tbl[2][b]] = 1'b1;
    for (int e = 0; e < 24; e++) cov_mask[2][e][g_FuBusyTableRead_22_m[e]] = 1'b1;
    for (int b = 0; b < 3; b++)
      if (tbl[2][b] && (|(ft[0] & SEL[2][b]))) cov_slot[2][b] = 1'b1;
    `CK(g_FuBusyTableRead_23_m, i_FuBusyTableRead_23_m, "FuBusyTableRead_23.mask")
    for (int b = 0; b < 1; b++) cov_tbl[3][b][tbl[3][b]] = 1'b1;
    for (int e = 0; e < 24; e++) cov_mask[3][e][g_FuBusyTableRead_23_m[e]] = 1'b1;
    for (int b = 0; b < 1; b++)
      if (tbl[3][b] && (|(ft[0] & SEL[3][b]))) cov_slot[3][b] = 1'b1;
    `CK(g_FuBusyTableRead_26_m, i_FuBusyTableRead_26_m, "FuBusyTableRead_26.mask")
    for (int b = 0; b < 3; b++) cov_tbl[4][b][tbl[4][b]] = 1'b1;
    for (int e = 0; e < 24; e++) cov_mask[4][e][g_FuBusyTableRead_26_m[e]] = 1'b1;
    for (int b = 0; b < 3; b++)
      if (tbl[4][b] && (|(ft[0] & SEL[4][b]))) cov_slot[4][b] = 1'b1;
    `CK(g_FuBusyTableRead_28_m, i_FuBusyTableRead_28_m, "FuBusyTableRead_28.mask")
    for (int b = 0; b < 1; b++) cov_tbl[5][b][tbl[5][b]] = 1'b1;
    for (int e = 0; e < 24; e++) cov_mask[5][e][g_FuBusyTableRead_28_m[e]] = 1'b1;
    for (int b = 0; b < 1; b++)
      if (tbl[5][b] && (|(ft[0] & SEL[5][b]))) cov_slot[5][b] = 1'b1;
    `CK(g_FuBusyTableRead_42_m, i_FuBusyTableRead_42_m, "FuBusyTableRead_42.mask")
    for (int b = 0; b < 4; b++) cov_tbl[6][b][tbl[6][b]] = 1'b1;
    for (int e = 0; e < 18; e++) cov_mask[6][e][g_FuBusyTableRead_42_m[e]] = 1'b1;
    for (int b = 0; b < 4; b++)
      if (tbl[6][b] && (|(ft[0] & SEL[6][b]))) cov_slot[6][b] = 1'b1;
    `CK(g_FuBusyTableRead_43_m, i_FuBusyTableRead_43_m, "FuBusyTableRead_43.mask")
    for (int b = 0; b < 3; b++) cov_tbl[7][b][tbl[7][b]] = 1'b1;
    for (int e = 0; e < 18; e++) cov_mask[7][e][g_FuBusyTableRead_43_m[e]] = 1'b1;
    for (int b = 0; b < 3; b++)
      if (tbl[7][b] && (|(ft[0] & SEL[7][b]))) cov_slot[7][b] = 1'b1;
    `CK(g_FuBusyTableRead_52_m, i_FuBusyTableRead_52_m, "FuBusyTableRead_52.mask")
    for (int b = 0; b < 4; b++) cov_tbl[8][b][tbl[8][b]] = 1'b1;
    for (int e = 0; e < 18; e++) cov_mask[8][e][g_FuBusyTableRead_52_m[e]] = 1'b1;
    for (int b = 0; b < 4; b++)
      if (tbl[8][b] && (|(ft[0] & SEL[8][b]))) cov_slot[8][b] = 1'b1;
    `CK(g_FuBusyTableRead_53_m, i_FuBusyTableRead_53_m, "FuBusyTableRead_53.mask")
    for (int b = 0; b < 2; b++) cov_tbl[9][b][tbl[9][b]] = 1'b1;
    for (int e = 0; e < 18; e++) cov_mask[9][e][g_FuBusyTableRead_53_m[e]] = 1'b1;
    for (int b = 0; b < 2; b++)
      if (tbl[9][b] && (|(ft[0] & SEL[9][b]))) cov_slot[9][b] = 1'b1;
    `CK(g_FuBusyTableRead_68_m, i_FuBusyTableRead_68_m, "FuBusyTableRead_68.mask")
    for (int b = 0; b < 5; b++) cov_tbl[10][b][tbl[10][b]] = 1'b1;
    for (int e = 0; e < 16; e++) cov_mask[10][e][g_FuBusyTableRead_68_m[e]] = 1'b1;
    for (int b = 0; b < 5; b++)
      if (tbl[10][b] && (|(ft[0] & SEL[10][b]))) cov_slot[10][b] = 1'b1;
    `CK(g_FuBusyTableRead_69_m, i_FuBusyTableRead_69_m, "FuBusyTableRead_69.mask")
    for (int b = 0; b < 4; b++) cov_tbl[11][b][tbl[11][b]] = 1'b1;
    for (int e = 0; e < 16; e++) cov_mask[11][e][g_FuBusyTableRead_69_m[e]] = 1'b1;
    for (int b = 0; b < 4; b++)
      if (tbl[11][b] && (|(ft[0] & SEL[11][b]))) cov_slot[11][b] = 1'b1;
    `CK(g_FuBusyTableRead_71_m, i_FuBusyTableRead_71_m, "FuBusyTableRead_71.mask")
    for (int b = 0; b < 5; b++) cov_tbl[12][b][tbl[12][b]] = 1'b1;
    for (int e = 0; e < 16; e++) cov_mask[12][e][g_FuBusyTableRead_71_m[e]] = 1'b1;
    for (int b = 0; b < 5; b++)
      if (tbl[12][b] && (|(ft[0] & SEL[12][b]))) cov_slot[12][b] = 1'b1;
    `CK(g_FuBusyTableRead_73_m, i_FuBusyTableRead_73_m, "FuBusyTableRead_73.mask")
    for (int b = 0; b < 3; b++) cov_tbl[13][b][tbl[13][b]] = 1'b1;
    for (int e = 0; e < 16; e++) cov_mask[13][e][g_FuBusyTableRead_73_m[e]] = 1'b1;
    for (int b = 0; b < 3; b++)
      if (tbl[13][b] && (|(ft[0] & SEL[13][b]))) cov_slot[13][b] = 1'b1;
    `CK(g_FuBusyTableRead_75_m, i_FuBusyTableRead_75_m, "FuBusyTableRead_75.mask")
    for (int b = 0; b < 4; b++) cov_tbl[14][b][tbl[14][b]] = 1'b1;
    for (int e = 0; e < 16; e++) cov_mask[14][e][g_FuBusyTableRead_75_m[e]] = 1'b1;
    for (int b = 0; b < 4; b++)
      if (tbl[14][b] && (|(ft[0] & SEL[14][b]))) cov_slot[14][b] = 1'b1;
    `CK(g_FuBusyTableRead_79_m, i_FuBusyTableRead_79_m, "FuBusyTableRead_79.mask")
    for (int b = 0; b < 2; b++) cov_tbl[15][b][tbl[15][b]] = 1'b1;
    for (int e = 0; e < 16; e++) cov_mask[15][e][g_FuBusyTableRead_79_m[e]] = 1'b1;
    for (int b = 0; b < 2; b++)
      if (tbl[15][b] && (|(ft[0] & SEL[15][b]))) cov_slot[15][b] = 1'b1;
    `CK(g_FuBusyTableRead_80_m, i_FuBusyTableRead_80_m, "FuBusyTableRead_80.mask")
    for (int b = 0; b < 5; b++) cov_tbl[16][b][tbl[16][b]] = 1'b1;
    for (int e = 0; e < 16; e++) cov_mask[16][e][g_FuBusyTableRead_80_m[e]] = 1'b1;
    for (int b = 0; b < 5; b++)
      if (tbl[16][b] && (|(ft[0] & SEL[16][b]))) cov_slot[16][b] = 1'b1;
    `CK(g_FuBusyTableRead_105_m, i_FuBusyTableRead_105_m, "FuBusyTableRead_105.mask")
    for (int b = 0; b < 4; b++) cov_tbl[17][b][tbl[17][b]] = 1'b1;
    for (int e = 0; e < 16; e++) cov_mask[17][e][g_FuBusyTableRead_105_m[e]] = 1'b1;
    for (int b = 0; b < 4; b++)
      if (tbl[17][b] && (|(ft[0] & SEL[17][b]))) cov_slot[17][b] = 1'b1;
  endtask

  task automatic drive();
    int mode; int nb;
    mode = $urandom_range(0, 3);
    for (int e = 0; e < 24; e++) begin
      case (mode)
        0: begin ft[e][31:0] = $urandom; ft[e][34:32] = $urandom; end  // 全随机
        1: ft[e] = 35'b1 << $urandom_range(0, 34);                     // 随机 one-hot
        2: begin                                                       // 只打有效位
             nb = $urandom_range(0, 34);
             while (!UNION[nb]) nb = (nb + 1) % 35;
             ft[e] = 35'b1 << nb;
           end
        default: ft[e] = '0;
      endcase
    end
    for (int v = 0; v < NV; v++) tbl[v] = $urandom_range(0, 31);
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int v = 0; v < NV; v++) begin
      for (int b = 0; b < 5;  b++) begin cov_tbl[v][b] = '0; cov_slot[v][b] = 1'b0; end
      for (int e = 0; e < 24; e++) cov_mask[v][e] = '0;
    end
    for (int e = 0; e < 24; e++) ft[e] = '0;
    for (int v = 0; v < NV; v++) tbl[v] = '0;
    repeat (2) @(posedge clk);
    repeat (NCYCLES) begin drive(); #1; check(); @(posedge clk); end
    report();
    $finish;
  end

  task automatic report();
    int bad = 0;
    $display("--- coverage: 表位 0/1 | 条目屏蔽位 0/1 | 非空槽驱动过 1 ---");
    for (int v = 0; v < NV; v++) begin
      int nt = 0, nm = 0, ns = 0, want_s = 0;
      for (int b = 0; b < TW[v]; b++) begin
        if (cov_tbl[v][b] == 2'b11) nt++;
        if (|SEL[v][b]) begin want_s++; if (cov_slot[v][b]) ns++; end
      end
      for (int e = 0; e < NE[v]; e++) if (cov_mask[v][e] == 2'b11) nm++;
      if (nt != TW[v] || nm != NE[v] || ns != want_s) bad++;
      $display("  variant[%0d] NE=%0d TW=%0d : tbl %0d/%0d, mask %0d/%0d, slot %0d/%0d",
               v, NE[v], TW[v], nt, TW[v], nm, NE[v], ns, want_s);
    end
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
  endtask
endmodule
