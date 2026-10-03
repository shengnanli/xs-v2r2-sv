// =============================================================================
// RegCacheAgeDetector_1 —— MemRegCache 的替换项选择（12 项、选 3 个替换项）
//
// 薄 wrapper：只设参数并展平端口，核体是 RegCacheAgeDetector.sv 里的
// xs_RegCacheAgeDetector_core（上三角年龄寄存器、行和挑选规则见那里的文件头）。
// =============================================================================
// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden RegCacheAgeDetector_1.sv 逐位一致（12 项、选 3 个替换项；
// ageInfo 只有上三角 i<j 的 C(n,2) 位输入，与 golden 端口表同）
// ---------------------------------------------------------------------------
module RegCacheAgeDetector_1 (
  input        clock,
  input        reset,
  input        io_ageInfo_0_1,
  input        io_ageInfo_0_2,
  input        io_ageInfo_0_3,
  input        io_ageInfo_0_4,
  input        io_ageInfo_0_5,
  input        io_ageInfo_0_6,
  input        io_ageInfo_0_7,
  input        io_ageInfo_0_8,
  input        io_ageInfo_0_9,
  input        io_ageInfo_0_10,
  input        io_ageInfo_0_11,
  input        io_ageInfo_1_2,
  input        io_ageInfo_1_3,
  input        io_ageInfo_1_4,
  input        io_ageInfo_1_5,
  input        io_ageInfo_1_6,
  input        io_ageInfo_1_7,
  input        io_ageInfo_1_8,
  input        io_ageInfo_1_9,
  input        io_ageInfo_1_10,
  input        io_ageInfo_1_11,
  input        io_ageInfo_2_3,
  input        io_ageInfo_2_4,
  input        io_ageInfo_2_5,
  input        io_ageInfo_2_6,
  input        io_ageInfo_2_7,
  input        io_ageInfo_2_8,
  input        io_ageInfo_2_9,
  input        io_ageInfo_2_10,
  input        io_ageInfo_2_11,
  input        io_ageInfo_3_4,
  input        io_ageInfo_3_5,
  input        io_ageInfo_3_6,
  input        io_ageInfo_3_7,
  input        io_ageInfo_3_8,
  input        io_ageInfo_3_9,
  input        io_ageInfo_3_10,
  input        io_ageInfo_3_11,
  input        io_ageInfo_4_5,
  input        io_ageInfo_4_6,
  input        io_ageInfo_4_7,
  input        io_ageInfo_4_8,
  input        io_ageInfo_4_9,
  input        io_ageInfo_4_10,
  input        io_ageInfo_4_11,
  input        io_ageInfo_5_6,
  input        io_ageInfo_5_7,
  input        io_ageInfo_5_8,
  input        io_ageInfo_5_9,
  input        io_ageInfo_5_10,
  input        io_ageInfo_5_11,
  input        io_ageInfo_6_7,
  input        io_ageInfo_6_8,
  input        io_ageInfo_6_9,
  input        io_ageInfo_6_10,
  input        io_ageInfo_6_11,
  input        io_ageInfo_7_8,
  input        io_ageInfo_7_9,
  input        io_ageInfo_7_10,
  input        io_ageInfo_7_11,
  input        io_ageInfo_8_9,
  input        io_ageInfo_8_10,
  input        io_ageInfo_8_11,
  input        io_ageInfo_9_10,
  input        io_ageInfo_9_11,
  input        io_ageInfo_10_11,
  output [3:0] io_out_0,
  output [3:0] io_out_1,
  output [3:0] io_out_2
);

  logic [11:0] age_info [12];
  logic [3:0]  out [3];

  // 只有上三角有端口；对角线与下三角核内不读，这里接常数 0 以免悬空
  always_comb begin
    for (int i = 0; i < 12; i++) age_info[i] = '0;
    age_info[0][1] = io_ageInfo_0_1;
    age_info[0][2] = io_ageInfo_0_2;
    age_info[0][3] = io_ageInfo_0_3;
    age_info[0][4] = io_ageInfo_0_4;
    age_info[0][5] = io_ageInfo_0_5;
    age_info[0][6] = io_ageInfo_0_6;
    age_info[0][7] = io_ageInfo_0_7;
    age_info[0][8] = io_ageInfo_0_8;
    age_info[0][9] = io_ageInfo_0_9;
    age_info[0][10] = io_ageInfo_0_10;
    age_info[0][11] = io_ageInfo_0_11;
    age_info[1][2] = io_ageInfo_1_2;
    age_info[1][3] = io_ageInfo_1_3;
    age_info[1][4] = io_ageInfo_1_4;
    age_info[1][5] = io_ageInfo_1_5;
    age_info[1][6] = io_ageInfo_1_6;
    age_info[1][7] = io_ageInfo_1_7;
    age_info[1][8] = io_ageInfo_1_8;
    age_info[1][9] = io_ageInfo_1_9;
    age_info[1][10] = io_ageInfo_1_10;
    age_info[1][11] = io_ageInfo_1_11;
    age_info[2][3] = io_ageInfo_2_3;
    age_info[2][4] = io_ageInfo_2_4;
    age_info[2][5] = io_ageInfo_2_5;
    age_info[2][6] = io_ageInfo_2_6;
    age_info[2][7] = io_ageInfo_2_7;
    age_info[2][8] = io_ageInfo_2_8;
    age_info[2][9] = io_ageInfo_2_9;
    age_info[2][10] = io_ageInfo_2_10;
    age_info[2][11] = io_ageInfo_2_11;
    age_info[3][4] = io_ageInfo_3_4;
    age_info[3][5] = io_ageInfo_3_5;
    age_info[3][6] = io_ageInfo_3_6;
    age_info[3][7] = io_ageInfo_3_7;
    age_info[3][8] = io_ageInfo_3_8;
    age_info[3][9] = io_ageInfo_3_9;
    age_info[3][10] = io_ageInfo_3_10;
    age_info[3][11] = io_ageInfo_3_11;
    age_info[4][5] = io_ageInfo_4_5;
    age_info[4][6] = io_ageInfo_4_6;
    age_info[4][7] = io_ageInfo_4_7;
    age_info[4][8] = io_ageInfo_4_8;
    age_info[4][9] = io_ageInfo_4_9;
    age_info[4][10] = io_ageInfo_4_10;
    age_info[4][11] = io_ageInfo_4_11;
    age_info[5][6] = io_ageInfo_5_6;
    age_info[5][7] = io_ageInfo_5_7;
    age_info[5][8] = io_ageInfo_5_8;
    age_info[5][9] = io_ageInfo_5_9;
    age_info[5][10] = io_ageInfo_5_10;
    age_info[5][11] = io_ageInfo_5_11;
    age_info[6][7] = io_ageInfo_6_7;
    age_info[6][8] = io_ageInfo_6_8;
    age_info[6][9] = io_ageInfo_6_9;
    age_info[6][10] = io_ageInfo_6_10;
    age_info[6][11] = io_ageInfo_6_11;
    age_info[7][8] = io_ageInfo_7_8;
    age_info[7][9] = io_ageInfo_7_9;
    age_info[7][10] = io_ageInfo_7_10;
    age_info[7][11] = io_ageInfo_7_11;
    age_info[8][9] = io_ageInfo_8_9;
    age_info[8][10] = io_ageInfo_8_10;
    age_info[8][11] = io_ageInfo_8_11;
    age_info[9][10] = io_ageInfo_9_10;
    age_info[9][11] = io_ageInfo_9_11;
    age_info[10][11] = io_ageInfo_10_11;
  end

  xs_RegCacheAgeDetector_core #(
    .N_ENTRY   (12),
    .N_REPLACE (3)
  ) u_core (
    .clock    (clock),
    .reset    (reset),
    .age_info (age_info),
    .out      (out)
  );

  assign io_out_0 = out[0];
  assign io_out_1 = out[1];
  assign io_out_2 = out[2];

endmodule
