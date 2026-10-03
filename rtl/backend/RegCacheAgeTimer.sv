// =============================================================================
// RegCacheAgeTimer —— 寄存器缓存各项的"年龄计时器"与两两年龄比较矩阵（RegCache 的子模块；
//                     家族核 xs_RegCacheAgeTimer_core 也服务 RegCacheAgeTimer_1）
//
// 设计源：src/main/scala/xiangshan/backend/regcache/RegCacheAgeTimer.scala。
//
// 作用：RegCache 满了要替换时选"最久没用"的项。本模块给每项一个 2 位饱和计时器：
//   * 被写（新分配）⇒ 清 0；被读 ⇒ 保持（读不算变老，也不算变新）；
//   * 否则 +1；已到 3 且该项有效 ⇒ 饱和停在 3（无效项会从 3 回绕到 0）。
//   为了在计时器都饱和时还能分出先后，项按 N/4 一组分 4 组，每组再拼一个 2 位
//   "组额外计时" ageTimerExtra[g]（复位为 g，每拍 +1、自由回绕）作为低位。
// 比较（输出 ageInfo[i][j]，i<j，"i 比 j 老"）：
//   i 有效 j 无效 ⇒ 0；i 无效 j 有效 ⇒ 1（无效项永远最该被替换）；
//   否则 {next_i, extra[i 所在组]} >= {next_j, extra[j 所在组]}，用的是**本拍更新后的**
//   计时值 next（与 RegCacheAgeDetector 打一拍后的矩阵对齐）。
// 复位：ageTimer[k] 复位为 k / (N/4)（各组错开），ageTimerExtra[g] 复位为 g；均异步复位。
// 读写口命中按"地址 == 项号"判，地址越界（只有 12 项的 _1 变体可能）不命中任何项。
// =============================================================================
module xs_RegCacheAgeTimer_core #(
  parameter int N_ENTRY = 16,
  parameter int N_READ  = 23,
  parameter int N_WRITE = 4,
  parameter int ADDR_W  = 4
) (
  input  logic                clock,
  input  logic                reset,
  input  logic [N_READ-1:0]   ren,
  input  logic [ADDR_W-1:0]   raddr [N_READ],
  input  logic [N_WRITE-1:0]  wen,
  input  logic [ADDR_W-1:0]   waddr [N_WRITE],
  input  logic [N_ENTRY-1:0]  valid_info,
  output logic [N_ENTRY-1:0]  age_info [N_ENTRY]     // [i][j]：i 比 j 老
);

  localparam int GROUP = N_ENTRY / 4;                // 每组项数

  logic [1:0] ageTimer      [N_ENTRY];
  logic [1:0] ageTimerExtra [4];

  // ---------------------------------------------------------------------------
  // §1 每项本拍是否被读 / 被写
  // ---------------------------------------------------------------------------
  logic [N_ENTRY-1:0] has_read;
  logic [N_ENTRY-1:0] has_write;
  always_comb begin
    for (int k = 0; k < N_ENTRY; k++) begin
      has_read[k]  = 1'b0;
      has_write[k] = 1'b0;
      for (int r = 0; r < N_READ; r++)
        has_read[k]  |= ren[r] & (raddr[r] == ADDR_W'(k));
      for (int w = 0; w < N_WRITE; w++)
        has_write[k] |= wen[w] & (waddr[w] == ADDR_W'(k));
    end
  end

  // ---------------------------------------------------------------------------
  // §2 计时器下一值与寄存器
  // ---------------------------------------------------------------------------
  logic [1:0] age_next [N_ENTRY];
  always_comb begin
    for (int k = 0; k < N_ENTRY; k++) begin
      if (has_write[k])                                age_next[k] = 2'd0;
      else if (has_read[k])                            age_next[k] = ageTimer[k];
      else if (ageTimer[k] == 2'd3 && valid_info[k])   age_next[k] = 2'd3;
      else                                             age_next[k] = ageTimer[k] + 2'd1;
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int k = 0; k < N_ENTRY; k++) ageTimer[k]      <= 2'(k / GROUP);
      for (int g = 0; g < 4; g++)       ageTimerExtra[g] <= 2'(g);
    end else begin
      for (int k = 0; k < N_ENTRY; k++) ageTimer[k]      <= age_next[k];
      for (int g = 0; g < 4; g++)       ageTimerExtra[g] <= ageTimerExtra[g] + 2'd1;
    end
  end

  // ---------------------------------------------------------------------------
  // §3 两两比较（只算上三角 i<j，下三角取反、对角恒 1，与 Scala age_cmp_func 同）
  // ---------------------------------------------------------------------------
  always_comb begin
    for (int i = 0; i < N_ENTRY; i++) begin
      age_info[i][i] = 1'b1;
      for (int j = i + 1; j < N_ENTRY; j++) begin
        if (valid_info[i] && !valid_info[j])
          age_info[i][j] = 1'b0;
        else if (!valid_info[i] && valid_info[j])
          age_info[i][j] = 1'b1;
        else
          age_info[i][j] = {age_next[i], ageTimerExtra[i / GROUP]}
                        >= {age_next[j], ageTimerExtra[j / GROUP]};
        age_info[j][i] = ~age_info[i][j];
      end
    end
  end

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden RegCacheAgeTimer.sv 逐位一致（16 项 / 23 读口 / 4 写口；
// ageInfo 只引出上三角 i<j 的 C(n,2) 位，与 golden 端口表同）
// ---------------------------------------------------------------------------
module RegCacheAgeTimer (
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
  input        io_writePorts_3_wen,
  input  [3:0] io_writePorts_3_addr,
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
  input        io_validInfo_12,
  input        io_validInfo_13,
  input        io_validInfo_14,
  input        io_validInfo_15,
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
  output       io_ageInfo_0_12,
  output       io_ageInfo_0_13,
  output       io_ageInfo_0_14,
  output       io_ageInfo_0_15,
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
  output       io_ageInfo_1_12,
  output       io_ageInfo_1_13,
  output       io_ageInfo_1_14,
  output       io_ageInfo_1_15,
  output       io_ageInfo_2_3,
  output       io_ageInfo_2_4,
  output       io_ageInfo_2_5,
  output       io_ageInfo_2_6,
  output       io_ageInfo_2_7,
  output       io_ageInfo_2_8,
  output       io_ageInfo_2_9,
  output       io_ageInfo_2_10,
  output       io_ageInfo_2_11,
  output       io_ageInfo_2_12,
  output       io_ageInfo_2_13,
  output       io_ageInfo_2_14,
  output       io_ageInfo_2_15,
  output       io_ageInfo_3_4,
  output       io_ageInfo_3_5,
  output       io_ageInfo_3_6,
  output       io_ageInfo_3_7,
  output       io_ageInfo_3_8,
  output       io_ageInfo_3_9,
  output       io_ageInfo_3_10,
  output       io_ageInfo_3_11,
  output       io_ageInfo_3_12,
  output       io_ageInfo_3_13,
  output       io_ageInfo_3_14,
  output       io_ageInfo_3_15,
  output       io_ageInfo_4_5,
  output       io_ageInfo_4_6,
  output       io_ageInfo_4_7,
  output       io_ageInfo_4_8,
  output       io_ageInfo_4_9,
  output       io_ageInfo_4_10,
  output       io_ageInfo_4_11,
  output       io_ageInfo_4_12,
  output       io_ageInfo_4_13,
  output       io_ageInfo_4_14,
  output       io_ageInfo_4_15,
  output       io_ageInfo_5_6,
  output       io_ageInfo_5_7,
  output       io_ageInfo_5_8,
  output       io_ageInfo_5_9,
  output       io_ageInfo_5_10,
  output       io_ageInfo_5_11,
  output       io_ageInfo_5_12,
  output       io_ageInfo_5_13,
  output       io_ageInfo_5_14,
  output       io_ageInfo_5_15,
  output       io_ageInfo_6_7,
  output       io_ageInfo_6_8,
  output       io_ageInfo_6_9,
  output       io_ageInfo_6_10,
  output       io_ageInfo_6_11,
  output       io_ageInfo_6_12,
  output       io_ageInfo_6_13,
  output       io_ageInfo_6_14,
  output       io_ageInfo_6_15,
  output       io_ageInfo_7_8,
  output       io_ageInfo_7_9,
  output       io_ageInfo_7_10,
  output       io_ageInfo_7_11,
  output       io_ageInfo_7_12,
  output       io_ageInfo_7_13,
  output       io_ageInfo_7_14,
  output       io_ageInfo_7_15,
  output       io_ageInfo_8_9,
  output       io_ageInfo_8_10,
  output       io_ageInfo_8_11,
  output       io_ageInfo_8_12,
  output       io_ageInfo_8_13,
  output       io_ageInfo_8_14,
  output       io_ageInfo_8_15,
  output       io_ageInfo_9_10,
  output       io_ageInfo_9_11,
  output       io_ageInfo_9_12,
  output       io_ageInfo_9_13,
  output       io_ageInfo_9_14,
  output       io_ageInfo_9_15,
  output       io_ageInfo_10_11,
  output       io_ageInfo_10_12,
  output       io_ageInfo_10_13,
  output       io_ageInfo_10_14,
  output       io_ageInfo_10_15,
  output       io_ageInfo_11_12,
  output       io_ageInfo_11_13,
  output       io_ageInfo_11_14,
  output       io_ageInfo_11_15,
  output       io_ageInfo_12_13,
  output       io_ageInfo_12_14,
  output       io_ageInfo_12_15,
  output       io_ageInfo_13_14,
  output       io_ageInfo_13_15,
  output       io_ageInfo_14_15
);

  logic [22:0] ren;
  logic [3:0]  raddr [23];
  logic [3:0]  wen;
  logic [3:0]  waddr [4];
  logic [15:0] valid_info;
  logic [15:0] age_info [16];

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
  assign wen[3]   = io_writePorts_3_wen;
  assign waddr[3] = io_writePorts_3_addr;
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
  assign valid_info[12] = io_validInfo_12;
  assign valid_info[13] = io_validInfo_13;
  assign valid_info[14] = io_validInfo_14;
  assign valid_info[15] = io_validInfo_15;

  xs_RegCacheAgeTimer_core #(
    .N_ENTRY (16),
    .N_READ  (23),
    .N_WRITE (4)
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
  assign io_ageInfo_0_12 = age_info[0][12];
  assign io_ageInfo_0_13 = age_info[0][13];
  assign io_ageInfo_0_14 = age_info[0][14];
  assign io_ageInfo_0_15 = age_info[0][15];
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
  assign io_ageInfo_1_12 = age_info[1][12];
  assign io_ageInfo_1_13 = age_info[1][13];
  assign io_ageInfo_1_14 = age_info[1][14];
  assign io_ageInfo_1_15 = age_info[1][15];
  assign io_ageInfo_2_3 = age_info[2][3];
  assign io_ageInfo_2_4 = age_info[2][4];
  assign io_ageInfo_2_5 = age_info[2][5];
  assign io_ageInfo_2_6 = age_info[2][6];
  assign io_ageInfo_2_7 = age_info[2][7];
  assign io_ageInfo_2_8 = age_info[2][8];
  assign io_ageInfo_2_9 = age_info[2][9];
  assign io_ageInfo_2_10 = age_info[2][10];
  assign io_ageInfo_2_11 = age_info[2][11];
  assign io_ageInfo_2_12 = age_info[2][12];
  assign io_ageInfo_2_13 = age_info[2][13];
  assign io_ageInfo_2_14 = age_info[2][14];
  assign io_ageInfo_2_15 = age_info[2][15];
  assign io_ageInfo_3_4 = age_info[3][4];
  assign io_ageInfo_3_5 = age_info[3][5];
  assign io_ageInfo_3_6 = age_info[3][6];
  assign io_ageInfo_3_7 = age_info[3][7];
  assign io_ageInfo_3_8 = age_info[3][8];
  assign io_ageInfo_3_9 = age_info[3][9];
  assign io_ageInfo_3_10 = age_info[3][10];
  assign io_ageInfo_3_11 = age_info[3][11];
  assign io_ageInfo_3_12 = age_info[3][12];
  assign io_ageInfo_3_13 = age_info[3][13];
  assign io_ageInfo_3_14 = age_info[3][14];
  assign io_ageInfo_3_15 = age_info[3][15];
  assign io_ageInfo_4_5 = age_info[4][5];
  assign io_ageInfo_4_6 = age_info[4][6];
  assign io_ageInfo_4_7 = age_info[4][7];
  assign io_ageInfo_4_8 = age_info[4][8];
  assign io_ageInfo_4_9 = age_info[4][9];
  assign io_ageInfo_4_10 = age_info[4][10];
  assign io_ageInfo_4_11 = age_info[4][11];
  assign io_ageInfo_4_12 = age_info[4][12];
  assign io_ageInfo_4_13 = age_info[4][13];
  assign io_ageInfo_4_14 = age_info[4][14];
  assign io_ageInfo_4_15 = age_info[4][15];
  assign io_ageInfo_5_6 = age_info[5][6];
  assign io_ageInfo_5_7 = age_info[5][7];
  assign io_ageInfo_5_8 = age_info[5][8];
  assign io_ageInfo_5_9 = age_info[5][9];
  assign io_ageInfo_5_10 = age_info[5][10];
  assign io_ageInfo_5_11 = age_info[5][11];
  assign io_ageInfo_5_12 = age_info[5][12];
  assign io_ageInfo_5_13 = age_info[5][13];
  assign io_ageInfo_5_14 = age_info[5][14];
  assign io_ageInfo_5_15 = age_info[5][15];
  assign io_ageInfo_6_7 = age_info[6][7];
  assign io_ageInfo_6_8 = age_info[6][8];
  assign io_ageInfo_6_9 = age_info[6][9];
  assign io_ageInfo_6_10 = age_info[6][10];
  assign io_ageInfo_6_11 = age_info[6][11];
  assign io_ageInfo_6_12 = age_info[6][12];
  assign io_ageInfo_6_13 = age_info[6][13];
  assign io_ageInfo_6_14 = age_info[6][14];
  assign io_ageInfo_6_15 = age_info[6][15];
  assign io_ageInfo_7_8 = age_info[7][8];
  assign io_ageInfo_7_9 = age_info[7][9];
  assign io_ageInfo_7_10 = age_info[7][10];
  assign io_ageInfo_7_11 = age_info[7][11];
  assign io_ageInfo_7_12 = age_info[7][12];
  assign io_ageInfo_7_13 = age_info[7][13];
  assign io_ageInfo_7_14 = age_info[7][14];
  assign io_ageInfo_7_15 = age_info[7][15];
  assign io_ageInfo_8_9 = age_info[8][9];
  assign io_ageInfo_8_10 = age_info[8][10];
  assign io_ageInfo_8_11 = age_info[8][11];
  assign io_ageInfo_8_12 = age_info[8][12];
  assign io_ageInfo_8_13 = age_info[8][13];
  assign io_ageInfo_8_14 = age_info[8][14];
  assign io_ageInfo_8_15 = age_info[8][15];
  assign io_ageInfo_9_10 = age_info[9][10];
  assign io_ageInfo_9_11 = age_info[9][11];
  assign io_ageInfo_9_12 = age_info[9][12];
  assign io_ageInfo_9_13 = age_info[9][13];
  assign io_ageInfo_9_14 = age_info[9][14];
  assign io_ageInfo_9_15 = age_info[9][15];
  assign io_ageInfo_10_11 = age_info[10][11];
  assign io_ageInfo_10_12 = age_info[10][12];
  assign io_ageInfo_10_13 = age_info[10][13];
  assign io_ageInfo_10_14 = age_info[10][14];
  assign io_ageInfo_10_15 = age_info[10][15];
  assign io_ageInfo_11_12 = age_info[11][12];
  assign io_ageInfo_11_13 = age_info[11][13];
  assign io_ageInfo_11_14 = age_info[11][14];
  assign io_ageInfo_11_15 = age_info[11][15];
  assign io_ageInfo_12_13 = age_info[12][13];
  assign io_ageInfo_12_14 = age_info[12][14];
  assign io_ageInfo_12_15 = age_info[12][15];
  assign io_ageInfo_13_14 = age_info[13][14];
  assign io_ageInfo_13_15 = age_info[13][15];
  assign io_ageInfo_14_15 = age_info[14][15];

endmodule
