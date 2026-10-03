// =============================================================================
// RegCacheAgeDetector —— 由年龄矩阵选出 RegCache 里最老的若干项作为替换槽（RegCache 的子模块；
//                        家族核 xs_RegCacheAgeDetector_core 也服务 RegCacheAgeDetector_1）
//
// 设计源：src/main/scala/xiangshan/backend/regcache/RegCacheAgeDetector.scala。
//
// 机制：
//   * age[i][j]（i<j，"i 比 j 老"）是 RegCacheAgeTimer 本拍比较结果打一拍的寄存器，
//     只存上三角（省一半寄存器）；读时 get_age(i,j) = i<j ? age[i][j] : i==j ? 1 : ~age[j][i]。
//   * 第 i 行 1 的个数 rowOnesSum[i] = 比多少项老（含自己）。最老的那项行和为 N，
//     第二老为 N-1，……；第 idx 个替换口取行和 == N-idx 的那一项（PriorityMux：
//     多项同时满足取号最小者，一项都不满足取最后一项 N-1）。
//     矩阵若不是全序（golden 只有断言把关），按上述 PriorityMux 规则照常给出结果。
// 复位：age 全部异步复位为 1（RegInit(true)）。
// =============================================================================
module xs_RegCacheAgeDetector_core #(
  parameter int N_ENTRY   = 16,
  parameter int N_REPLACE = 4,
  parameter int OUT_W     = $clog2(N_ENTRY)
) (
  input  logic                clock,
  input  logic                reset,
  input  logic [N_ENTRY-1:0]  age_info [N_ENTRY],    // 只读上三角 [i][j]，i<j
  output logic [OUT_W-1:0]    out [N_REPLACE]
);

  localparam int SUM_W = $clog2(N_ENTRY + 1);

  // ---------------------------------------------------------------------------
  // §1 上三角年龄寄存器（对角线与下三角不建寄存器）
  // ---------------------------------------------------------------------------
  logic age [N_ENTRY][N_ENTRY];

  for (genvar i = 0; i < N_ENTRY; i++) begin : g_row
    for (genvar j = i + 1; j < N_ENTRY; j++) begin : g_col
      always_ff @(posedge clock or posedge reset) begin
        if (reset) age[i][j] <= 1'b1;
        else       age[i][j] <= age_info[i][j];
      end
    end
  end

  // 完整矩阵 older[i][j]：上三角取寄存器，对角恒 1，下三角取对称位的反（Scala get_age）
  logic [N_ENTRY-1:0] older [N_ENTRY];
  always_comb begin
    for (int i = 0; i < N_ENTRY; i++)
      for (int j = 0; j < N_ENTRY; j++)
        if (i < j)       older[i][j] = age[i][j];
        else if (i == j) older[i][j] = 1'b1;
        else             older[i][j] = ~age[j][i];
  end

  // ---------------------------------------------------------------------------
  // §2 行和与按行和挑选替换项
  // ---------------------------------------------------------------------------
  logic [SUM_W-1:0] row_ones_sum [N_ENTRY];
  always_comb begin
    for (int i = 0; i < N_ENTRY; i++)
      row_ones_sum[i] = SUM_W'($countones(older[i]));
  end

  always_comb begin
    for (int idx = 0; idx < N_REPLACE; idx++) begin
      out[idx] = OUT_W'(N_ENTRY - 1);                      // 一项都不满足：最后一项
      for (int i = N_ENTRY - 2; i >= 0; i--)               // 号小者优先
        if (row_ones_sum[i] == SUM_W'(N_ENTRY - idx)) out[idx] = OUT_W'(i);
    end
  end

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden RegCacheAgeDetector.sv 逐位一致（16 项、选 4 个替换项；
// ageInfo 只有上三角 i<j 的 C(n,2) 位输入，与 golden 端口表同）
// ---------------------------------------------------------------------------
module RegCacheAgeDetector (
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
  input        io_ageInfo_0_12,
  input        io_ageInfo_0_13,
  input        io_ageInfo_0_14,
  input        io_ageInfo_0_15,
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
  input        io_ageInfo_1_12,
  input        io_ageInfo_1_13,
  input        io_ageInfo_1_14,
  input        io_ageInfo_1_15,
  input        io_ageInfo_2_3,
  input        io_ageInfo_2_4,
  input        io_ageInfo_2_5,
  input        io_ageInfo_2_6,
  input        io_ageInfo_2_7,
  input        io_ageInfo_2_8,
  input        io_ageInfo_2_9,
  input        io_ageInfo_2_10,
  input        io_ageInfo_2_11,
  input        io_ageInfo_2_12,
  input        io_ageInfo_2_13,
  input        io_ageInfo_2_14,
  input        io_ageInfo_2_15,
  input        io_ageInfo_3_4,
  input        io_ageInfo_3_5,
  input        io_ageInfo_3_6,
  input        io_ageInfo_3_7,
  input        io_ageInfo_3_8,
  input        io_ageInfo_3_9,
  input        io_ageInfo_3_10,
  input        io_ageInfo_3_11,
  input        io_ageInfo_3_12,
  input        io_ageInfo_3_13,
  input        io_ageInfo_3_14,
  input        io_ageInfo_3_15,
  input        io_ageInfo_4_5,
  input        io_ageInfo_4_6,
  input        io_ageInfo_4_7,
  input        io_ageInfo_4_8,
  input        io_ageInfo_4_9,
  input        io_ageInfo_4_10,
  input        io_ageInfo_4_11,
  input        io_ageInfo_4_12,
  input        io_ageInfo_4_13,
  input        io_ageInfo_4_14,
  input        io_ageInfo_4_15,
  input        io_ageInfo_5_6,
  input        io_ageInfo_5_7,
  input        io_ageInfo_5_8,
  input        io_ageInfo_5_9,
  input        io_ageInfo_5_10,
  input        io_ageInfo_5_11,
  input        io_ageInfo_5_12,
  input        io_ageInfo_5_13,
  input        io_ageInfo_5_14,
  input        io_ageInfo_5_15,
  input        io_ageInfo_6_7,
  input        io_ageInfo_6_8,
  input        io_ageInfo_6_9,
  input        io_ageInfo_6_10,
  input        io_ageInfo_6_11,
  input        io_ageInfo_6_12,
  input        io_ageInfo_6_13,
  input        io_ageInfo_6_14,
  input        io_ageInfo_6_15,
  input        io_ageInfo_7_8,
  input        io_ageInfo_7_9,
  input        io_ageInfo_7_10,
  input        io_ageInfo_7_11,
  input        io_ageInfo_7_12,
  input        io_ageInfo_7_13,
  input        io_ageInfo_7_14,
  input        io_ageInfo_7_15,
  input        io_ageInfo_8_9,
  input        io_ageInfo_8_10,
  input        io_ageInfo_8_11,
  input        io_ageInfo_8_12,
  input        io_ageInfo_8_13,
  input        io_ageInfo_8_14,
  input        io_ageInfo_8_15,
  input        io_ageInfo_9_10,
  input        io_ageInfo_9_11,
  input        io_ageInfo_9_12,
  input        io_ageInfo_9_13,
  input        io_ageInfo_9_14,
  input        io_ageInfo_9_15,
  input        io_ageInfo_10_11,
  input        io_ageInfo_10_12,
  input        io_ageInfo_10_13,
  input        io_ageInfo_10_14,
  input        io_ageInfo_10_15,
  input        io_ageInfo_11_12,
  input        io_ageInfo_11_13,
  input        io_ageInfo_11_14,
  input        io_ageInfo_11_15,
  input        io_ageInfo_12_13,
  input        io_ageInfo_12_14,
  input        io_ageInfo_12_15,
  input        io_ageInfo_13_14,
  input        io_ageInfo_13_15,
  input        io_ageInfo_14_15,
  output [3:0] io_out_0,
  output [3:0] io_out_1,
  output [3:0] io_out_2,
  output [3:0] io_out_3
);

  logic [15:0] age_info [16];
  logic [3:0]  out [4];

  // 只有上三角有端口；对角线与下三角核内不读，这里接常数 0 以免悬空
  always_comb begin
    for (int i = 0; i < 16; i++) age_info[i] = '0;
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
    age_info[0][12] = io_ageInfo_0_12;
    age_info[0][13] = io_ageInfo_0_13;
    age_info[0][14] = io_ageInfo_0_14;
    age_info[0][15] = io_ageInfo_0_15;
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
    age_info[1][12] = io_ageInfo_1_12;
    age_info[1][13] = io_ageInfo_1_13;
    age_info[1][14] = io_ageInfo_1_14;
    age_info[1][15] = io_ageInfo_1_15;
    age_info[2][3] = io_ageInfo_2_3;
    age_info[2][4] = io_ageInfo_2_4;
    age_info[2][5] = io_ageInfo_2_5;
    age_info[2][6] = io_ageInfo_2_6;
    age_info[2][7] = io_ageInfo_2_7;
    age_info[2][8] = io_ageInfo_2_8;
    age_info[2][9] = io_ageInfo_2_9;
    age_info[2][10] = io_ageInfo_2_10;
    age_info[2][11] = io_ageInfo_2_11;
    age_info[2][12] = io_ageInfo_2_12;
    age_info[2][13] = io_ageInfo_2_13;
    age_info[2][14] = io_ageInfo_2_14;
    age_info[2][15] = io_ageInfo_2_15;
    age_info[3][4] = io_ageInfo_3_4;
    age_info[3][5] = io_ageInfo_3_5;
    age_info[3][6] = io_ageInfo_3_6;
    age_info[3][7] = io_ageInfo_3_7;
    age_info[3][8] = io_ageInfo_3_8;
    age_info[3][9] = io_ageInfo_3_9;
    age_info[3][10] = io_ageInfo_3_10;
    age_info[3][11] = io_ageInfo_3_11;
    age_info[3][12] = io_ageInfo_3_12;
    age_info[3][13] = io_ageInfo_3_13;
    age_info[3][14] = io_ageInfo_3_14;
    age_info[3][15] = io_ageInfo_3_15;
    age_info[4][5] = io_ageInfo_4_5;
    age_info[4][6] = io_ageInfo_4_6;
    age_info[4][7] = io_ageInfo_4_7;
    age_info[4][8] = io_ageInfo_4_8;
    age_info[4][9] = io_ageInfo_4_9;
    age_info[4][10] = io_ageInfo_4_10;
    age_info[4][11] = io_ageInfo_4_11;
    age_info[4][12] = io_ageInfo_4_12;
    age_info[4][13] = io_ageInfo_4_13;
    age_info[4][14] = io_ageInfo_4_14;
    age_info[4][15] = io_ageInfo_4_15;
    age_info[5][6] = io_ageInfo_5_6;
    age_info[5][7] = io_ageInfo_5_7;
    age_info[5][8] = io_ageInfo_5_8;
    age_info[5][9] = io_ageInfo_5_9;
    age_info[5][10] = io_ageInfo_5_10;
    age_info[5][11] = io_ageInfo_5_11;
    age_info[5][12] = io_ageInfo_5_12;
    age_info[5][13] = io_ageInfo_5_13;
    age_info[5][14] = io_ageInfo_5_14;
    age_info[5][15] = io_ageInfo_5_15;
    age_info[6][7] = io_ageInfo_6_7;
    age_info[6][8] = io_ageInfo_6_8;
    age_info[6][9] = io_ageInfo_6_9;
    age_info[6][10] = io_ageInfo_6_10;
    age_info[6][11] = io_ageInfo_6_11;
    age_info[6][12] = io_ageInfo_6_12;
    age_info[6][13] = io_ageInfo_6_13;
    age_info[6][14] = io_ageInfo_6_14;
    age_info[6][15] = io_ageInfo_6_15;
    age_info[7][8] = io_ageInfo_7_8;
    age_info[7][9] = io_ageInfo_7_9;
    age_info[7][10] = io_ageInfo_7_10;
    age_info[7][11] = io_ageInfo_7_11;
    age_info[7][12] = io_ageInfo_7_12;
    age_info[7][13] = io_ageInfo_7_13;
    age_info[7][14] = io_ageInfo_7_14;
    age_info[7][15] = io_ageInfo_7_15;
    age_info[8][9] = io_ageInfo_8_9;
    age_info[8][10] = io_ageInfo_8_10;
    age_info[8][11] = io_ageInfo_8_11;
    age_info[8][12] = io_ageInfo_8_12;
    age_info[8][13] = io_ageInfo_8_13;
    age_info[8][14] = io_ageInfo_8_14;
    age_info[8][15] = io_ageInfo_8_15;
    age_info[9][10] = io_ageInfo_9_10;
    age_info[9][11] = io_ageInfo_9_11;
    age_info[9][12] = io_ageInfo_9_12;
    age_info[9][13] = io_ageInfo_9_13;
    age_info[9][14] = io_ageInfo_9_14;
    age_info[9][15] = io_ageInfo_9_15;
    age_info[10][11] = io_ageInfo_10_11;
    age_info[10][12] = io_ageInfo_10_12;
    age_info[10][13] = io_ageInfo_10_13;
    age_info[10][14] = io_ageInfo_10_14;
    age_info[10][15] = io_ageInfo_10_15;
    age_info[11][12] = io_ageInfo_11_12;
    age_info[11][13] = io_ageInfo_11_13;
    age_info[11][14] = io_ageInfo_11_14;
    age_info[11][15] = io_ageInfo_11_15;
    age_info[12][13] = io_ageInfo_12_13;
    age_info[12][14] = io_ageInfo_12_14;
    age_info[12][15] = io_ageInfo_12_15;
    age_info[13][14] = io_ageInfo_13_14;
    age_info[13][15] = io_ageInfo_13_15;
    age_info[14][15] = io_ageInfo_14_15;
  end

  xs_RegCacheAgeDetector_core #(
    .N_ENTRY   (16),
    .N_REPLACE (4)
  ) u_core (
    .clock    (clock),
    .reset    (reset),
    .age_info (age_info),
    .out      (out)
  );

  assign io_out_0 = out[0];
  assign io_out_1 = out[1];
  assign io_out_2 = out[2];
  assign io_out_3 = out[3];

endmodule
