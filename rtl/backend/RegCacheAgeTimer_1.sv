// =============================================================================
// RegCacheAgeTimer_1 —— MemRegCache 的年龄计时器（12 项 / 23 读口 / 3 写口，每组 3 项）
//
// 薄 wrapper：只设参数并展平端口，核体是 RegCacheAgeTimer.sv 里的
// xs_RegCacheAgeTimer_core（计时规则、组额外计时、比较规则见那里的文件头）。
// =============================================================================
// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden RegCacheAgeTimer_1.sv 逐位一致（12 项 / 23 读口 / 3 写口；
// ageInfo 只引出上三角 i<j 的 C(n,2) 位，与 golden 端口表同）
// ---------------------------------------------------------------------------
module RegCacheAgeTimer_1 (
  input        clock,
  input        reset,
  input        io_readPorts_0_ren,
  input  [3:0] io_readPorts_0_addr,
  input        io_readPorts_1_ren,
  input  [3:0] io_readPorts_1_addr,
  input        io_readPorts_2_ren,
  input  [3:0] io_readPorts_2_addr,
  input        io_readPorts_3_ren,
  input  [3:0] io_readPorts_3_addr,
  input        io_readPorts_4_ren,
  input  [3:0] io_readPorts_4_addr,
  input        io_readPorts_5_ren,
  input  [3:0] io_readPorts_5_addr,
  input        io_readPorts_6_ren,
  input  [3:0] io_readPorts_6_addr,
  input        io_readPorts_7_ren,
  input  [3:0] io_readPorts_7_addr,
  input        io_readPorts_8_ren,
  input  [3:0] io_readPorts_8_addr,
  input        io_readPorts_9_ren,
  input  [3:0] io_readPorts_9_addr,
  input        io_readPorts_10_ren,
  input  [3:0] io_readPorts_10_addr,
  input        io_readPorts_11_ren,
  input  [3:0] io_readPorts_11_addr,
  input        io_readPorts_12_ren,
  input  [3:0] io_readPorts_12_addr,
  input        io_readPorts_13_ren,
  input  [3:0] io_readPorts_13_addr,
  input        io_readPorts_14_ren,
  input  [3:0] io_readPorts_14_addr,
  input        io_readPorts_15_ren,
  input  [3:0] io_readPorts_15_addr,
  input        io_readPorts_16_ren,
  input  [3:0] io_readPorts_16_addr,
  input        io_readPorts_17_ren,
  input  [3:0] io_readPorts_17_addr,
  input        io_readPorts_18_ren,
  input  [3:0] io_readPorts_18_addr,
  input        io_readPorts_19_ren,
  input  [3:0] io_readPorts_19_addr,
  input        io_readPorts_20_ren,
  input  [3:0] io_readPorts_20_addr,
  input        io_readPorts_21_ren,
  input  [3:0] io_readPorts_21_addr,
  input        io_readPorts_22_ren,
  input  [3:0] io_readPorts_22_addr,
  input        io_writePorts_0_wen,
  input  [3:0] io_writePorts_0_addr,
  input        io_writePorts_1_wen,
  input  [3:0] io_writePorts_1_addr,
  input        io_writePorts_2_wen,
  input  [3:0] io_writePorts_2_addr,
  input        io_validInfo_0,
  input        io_validInfo_1,
  input        io_validInfo_2,
  input        io_validInfo_3,
  input        io_validInfo_4,
  input        io_validInfo_5,
  input        io_validInfo_6,
  input        io_validInfo_7,
  input        io_validInfo_8,
  input        io_validInfo_9,
  input        io_validInfo_10,
  input        io_validInfo_11,
  output       io_ageInfo_0_1,
  output       io_ageInfo_0_2,
  output       io_ageInfo_0_3,
  output       io_ageInfo_0_4,
  output       io_ageInfo_0_5,
  output       io_ageInfo_0_6,
  output       io_ageInfo_0_7,
  output       io_ageInfo_0_8,
  output       io_ageInfo_0_9,
  output       io_ageInfo_0_10,
  output       io_ageInfo_0_11,
  output       io_ageInfo_1_2,
  output       io_ageInfo_1_3,
  output       io_ageInfo_1_4,
  output       io_ageInfo_1_5,
  output       io_ageInfo_1_6,
  output       io_ageInfo_1_7,
  output       io_ageInfo_1_8,
  output       io_ageInfo_1_9,
  output       io_ageInfo_1_10,
  output       io_ageInfo_1_11,
  output       io_ageInfo_2_3,
  output       io_ageInfo_2_4,
  output       io_ageInfo_2_5,
  output       io_ageInfo_2_6,
  output       io_ageInfo_2_7,
  output       io_ageInfo_2_8,
  output       io_ageInfo_2_9,
  output       io_ageInfo_2_10,
  output       io_ageInfo_2_11,
  output       io_ageInfo_3_4,
  output       io_ageInfo_3_5,
  output       io_ageInfo_3_6,
  output       io_ageInfo_3_7,
  output       io_ageInfo_3_8,
  output       io_ageInfo_3_9,
  output       io_ageInfo_3_10,
  output       io_ageInfo_3_11,
  output       io_ageInfo_4_5,
  output       io_ageInfo_4_6,
  output       io_ageInfo_4_7,
  output       io_ageInfo_4_8,
  output       io_ageInfo_4_9,
  output       io_ageInfo_4_10,
  output       io_ageInfo_4_11,
  output       io_ageInfo_5_6,
  output       io_ageInfo_5_7,
  output       io_ageInfo_5_8,
  output       io_ageInfo_5_9,
  output       io_ageInfo_5_10,
  output       io_ageInfo_5_11,
  output       io_ageInfo_6_7,
  output       io_ageInfo_6_8,
  output       io_ageInfo_6_9,
  output       io_ageInfo_6_10,
  output       io_ageInfo_6_11,
  output       io_ageInfo_7_8,
  output       io_ageInfo_7_9,
  output       io_ageInfo_7_10,
  output       io_ageInfo_7_11,
  output       io_ageInfo_8_9,
  output       io_ageInfo_8_10,
  output       io_ageInfo_8_11,
  output       io_ageInfo_9_10,
  output       io_ageInfo_9_11,
  output       io_ageInfo_10_11
);

  logic [22:0] ren;
  logic [3:0]  raddr [23];
  logic [2:0]  wen;
  logic [3:0]  waddr [3];
  logic [11:0] valid_info;
  logic [11:0] age_info [12];

  assign ren[0]   = io_readPorts_0_ren;
  assign raddr[0] = io_readPorts_0_addr;
  assign ren[1]   = io_readPorts_1_ren;
  assign raddr[1] = io_readPorts_1_addr;
  assign ren[2]   = io_readPorts_2_ren;
  assign raddr[2] = io_readPorts_2_addr;
  assign ren[3]   = io_readPorts_3_ren;
  assign raddr[3] = io_readPorts_3_addr;
  assign ren[4]   = io_readPorts_4_ren;
  assign raddr[4] = io_readPorts_4_addr;
  assign ren[5]   = io_readPorts_5_ren;
  assign raddr[5] = io_readPorts_5_addr;
  assign ren[6]   = io_readPorts_6_ren;
  assign raddr[6] = io_readPorts_6_addr;
  assign ren[7]   = io_readPorts_7_ren;
  assign raddr[7] = io_readPorts_7_addr;
  assign ren[8]   = io_readPorts_8_ren;
  assign raddr[8] = io_readPorts_8_addr;
  assign ren[9]   = io_readPorts_9_ren;
  assign raddr[9] = io_readPorts_9_addr;
  assign ren[10]   = io_readPorts_10_ren;
  assign raddr[10] = io_readPorts_10_addr;
  assign ren[11]   = io_readPorts_11_ren;
  assign raddr[11] = io_readPorts_11_addr;
  assign ren[12]   = io_readPorts_12_ren;
  assign raddr[12] = io_readPorts_12_addr;
  assign ren[13]   = io_readPorts_13_ren;
  assign raddr[13] = io_readPorts_13_addr;
  assign ren[14]   = io_readPorts_14_ren;
  assign raddr[14] = io_readPorts_14_addr;
  assign ren[15]   = io_readPorts_15_ren;
  assign raddr[15] = io_readPorts_15_addr;
  assign ren[16]   = io_readPorts_16_ren;
  assign raddr[16] = io_readPorts_16_addr;
  assign ren[17]   = io_readPorts_17_ren;
  assign raddr[17] = io_readPorts_17_addr;
  assign ren[18]   = io_readPorts_18_ren;
  assign raddr[18] = io_readPorts_18_addr;
  assign ren[19]   = io_readPorts_19_ren;
  assign raddr[19] = io_readPorts_19_addr;
  assign ren[20]   = io_readPorts_20_ren;
  assign raddr[20] = io_readPorts_20_addr;
  assign ren[21]   = io_readPorts_21_ren;
  assign raddr[21] = io_readPorts_21_addr;
  assign ren[22]   = io_readPorts_22_ren;
  assign raddr[22] = io_readPorts_22_addr;
  assign wen[0]   = io_writePorts_0_wen;
  assign waddr[0] = io_writePorts_0_addr;
  assign wen[1]   = io_writePorts_1_wen;
  assign waddr[1] = io_writePorts_1_addr;
  assign wen[2]   = io_writePorts_2_wen;
  assign waddr[2] = io_writePorts_2_addr;
  assign valid_info[0] = io_validInfo_0;
  assign valid_info[1] = io_validInfo_1;
  assign valid_info[2] = io_validInfo_2;
  assign valid_info[3] = io_validInfo_3;
  assign valid_info[4] = io_validInfo_4;
  assign valid_info[5] = io_validInfo_5;
  assign valid_info[6] = io_validInfo_6;
  assign valid_info[7] = io_validInfo_7;
  assign valid_info[8] = io_validInfo_8;
  assign valid_info[9] = io_validInfo_9;
  assign valid_info[10] = io_validInfo_10;
  assign valid_info[11] = io_validInfo_11;

  xs_RegCacheAgeTimer_core #(
    .N_ENTRY (12),
    .N_READ  (23),
    .N_WRITE (3)
  ) u_core (
    .clock      (clock),
    .reset      (reset),
    .ren        (ren),
    .raddr      (raddr),
    .wen        (wen),
    .waddr      (waddr),
    .valid_info (valid_info),
    .age_info   (age_info)
  );

  assign io_ageInfo_0_1 = age_info[0][1];
  assign io_ageInfo_0_2 = age_info[0][2];
  assign io_ageInfo_0_3 = age_info[0][3];
  assign io_ageInfo_0_4 = age_info[0][4];
  assign io_ageInfo_0_5 = age_info[0][5];
  assign io_ageInfo_0_6 = age_info[0][6];
  assign io_ageInfo_0_7 = age_info[0][7];
  assign io_ageInfo_0_8 = age_info[0][8];
  assign io_ageInfo_0_9 = age_info[0][9];
  assign io_ageInfo_0_10 = age_info[0][10];
  assign io_ageInfo_0_11 = age_info[0][11];
  assign io_ageInfo_1_2 = age_info[1][2];
  assign io_ageInfo_1_3 = age_info[1][3];
  assign io_ageInfo_1_4 = age_info[1][4];
  assign io_ageInfo_1_5 = age_info[1][5];
  assign io_ageInfo_1_6 = age_info[1][6];
  assign io_ageInfo_1_7 = age_info[1][7];
  assign io_ageInfo_1_8 = age_info[1][8];
  assign io_ageInfo_1_9 = age_info[1][9];
  assign io_ageInfo_1_10 = age_info[1][10];
  assign io_ageInfo_1_11 = age_info[1][11];
  assign io_ageInfo_2_3 = age_info[2][3];
  assign io_ageInfo_2_4 = age_info[2][4];
  assign io_ageInfo_2_5 = age_info[2][5];
  assign io_ageInfo_2_6 = age_info[2][6];
  assign io_ageInfo_2_7 = age_info[2][7];
  assign io_ageInfo_2_8 = age_info[2][8];
  assign io_ageInfo_2_9 = age_info[2][9];
  assign io_ageInfo_2_10 = age_info[2][10];
  assign io_ageInfo_2_11 = age_info[2][11];
  assign io_ageInfo_3_4 = age_info[3][4];
  assign io_ageInfo_3_5 = age_info[3][5];
  assign io_ageInfo_3_6 = age_info[3][6];
  assign io_ageInfo_3_7 = age_info[3][7];
  assign io_ageInfo_3_8 = age_info[3][8];
  assign io_ageInfo_3_9 = age_info[3][9];
  assign io_ageInfo_3_10 = age_info[3][10];
  assign io_ageInfo_3_11 = age_info[3][11];
  assign io_ageInfo_4_5 = age_info[4][5];
  assign io_ageInfo_4_6 = age_info[4][6];
  assign io_ageInfo_4_7 = age_info[4][7];
  assign io_ageInfo_4_8 = age_info[4][8];
  assign io_ageInfo_4_9 = age_info[4][9];
  assign io_ageInfo_4_10 = age_info[4][10];
  assign io_ageInfo_4_11 = age_info[4][11];
  assign io_ageInfo_5_6 = age_info[5][6];
  assign io_ageInfo_5_7 = age_info[5][7];
  assign io_ageInfo_5_8 = age_info[5][8];
  assign io_ageInfo_5_9 = age_info[5][9];
  assign io_ageInfo_5_10 = age_info[5][10];
  assign io_ageInfo_5_11 = age_info[5][11];
  assign io_ageInfo_6_7 = age_info[6][7];
  assign io_ageInfo_6_8 = age_info[6][8];
  assign io_ageInfo_6_9 = age_info[6][9];
  assign io_ageInfo_6_10 = age_info[6][10];
  assign io_ageInfo_6_11 = age_info[6][11];
  assign io_ageInfo_7_8 = age_info[7][8];
  assign io_ageInfo_7_9 = age_info[7][9];
  assign io_ageInfo_7_10 = age_info[7][10];
  assign io_ageInfo_7_11 = age_info[7][11];
  assign io_ageInfo_8_9 = age_info[8][9];
  assign io_ageInfo_8_10 = age_info[8][10];
  assign io_ageInfo_8_11 = age_info[8][11];
  assign io_ageInfo_9_10 = age_info[9][10];
  assign io_ageInfo_9_11 = age_info[9][11];
  assign io_ageInfo_10_11 = age_info[10][11];

endmodule
