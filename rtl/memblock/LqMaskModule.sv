// =============================================================================
// LqMaskModule —— LoadQueueRAW 的字节掩码 CAM 阵列（32 项 × 16 位）
//
// 薄 wrapper：逻辑全部在共用核 xs_LqRawDataCam_core（同目录 xs_LqRawDataCam_core.sv）。
// 本变体：DATA_W=16，LINE_CAM=0（字节掩码交叠 CAM），写数据延迟件 = DelayNWithValid_103。
// 本层只做端口展平/改名：golden 的扁平 io_* 名 <-> 核的按口号成组的数组端口。
// reset 在综合视图里没有负载：golden 只在 `ifndef SYNTHESIS 的写冲突断言里用它
// （assert(!(wen(i) && wen(j) && waddr(i)===waddr(j)))），所有寄存器都不复位。
// 端口表逐字抄自 G1 golden 同名模块。自动生成：scripts/gen_lqraw.py —— 勿手改
// =============================================================================

module LqMaskModule(
  input         clock,
  input         reset,
  input         io_wen_0,
  input         io_wen_1,
  input         io_wen_2,
  input  [4:0]  io_waddr_0,
  input  [4:0]  io_waddr_1,
  input  [4:0]  io_waddr_2,
  input  [15:0] io_wdata_0,
  input  [15:0] io_wdata_1,
  input  [15:0] io_wdata_2,
  input  [15:0] io_violationMdata_0,
  input  [15:0] io_violationMdata_1,
  output        io_violationMmask_0_0,
  output        io_violationMmask_0_1,
  output        io_violationMmask_0_2,
  output        io_violationMmask_0_3,
  output        io_violationMmask_0_4,
  output        io_violationMmask_0_5,
  output        io_violationMmask_0_6,
  output        io_violationMmask_0_7,
  output        io_violationMmask_0_8,
  output        io_violationMmask_0_9,
  output        io_violationMmask_0_10,
  output        io_violationMmask_0_11,
  output        io_violationMmask_0_12,
  output        io_violationMmask_0_13,
  output        io_violationMmask_0_14,
  output        io_violationMmask_0_15,
  output        io_violationMmask_0_16,
  output        io_violationMmask_0_17,
  output        io_violationMmask_0_18,
  output        io_violationMmask_0_19,
  output        io_violationMmask_0_20,
  output        io_violationMmask_0_21,
  output        io_violationMmask_0_22,
  output        io_violationMmask_0_23,
  output        io_violationMmask_0_24,
  output        io_violationMmask_0_25,
  output        io_violationMmask_0_26,
  output        io_violationMmask_0_27,
  output        io_violationMmask_0_28,
  output        io_violationMmask_0_29,
  output        io_violationMmask_0_30,
  output        io_violationMmask_0_31,
  output        io_violationMmask_1_0,
  output        io_violationMmask_1_1,
  output        io_violationMmask_1_2,
  output        io_violationMmask_1_3,
  output        io_violationMmask_1_4,
  output        io_violationMmask_1_5,
  output        io_violationMmask_1_6,
  output        io_violationMmask_1_7,
  output        io_violationMmask_1_8,
  output        io_violationMmask_1_9,
  output        io_violationMmask_1_10,
  output        io_violationMmask_1_11,
  output        io_violationMmask_1_12,
  output        io_violationMmask_1_13,
  output        io_violationMmask_1_14,
  output        io_violationMmask_1_15,
  output        io_violationMmask_1_16,
  output        io_violationMmask_1_17,
  output        io_violationMmask_1_18,
  output        io_violationMmask_1_19,
  output        io_violationMmask_1_20,
  output        io_violationMmask_1_21,
  output        io_violationMmask_1_22,
  output        io_violationMmask_1_23,
  output        io_violationMmask_1_24,
  output        io_violationMmask_1_25,
  output        io_violationMmask_1_26,
  output        io_violationMmask_1_27,
  output        io_violationMmask_1_28,
  output        io_violationMmask_1_29,
  output        io_violationMmask_1_30,
  output        io_violationMmask_1_31
);
  logic [4:0] waddr [3];
  logic [15:0] wdata [3];
  logic [15:0] mdata [2];
  logic [31:0] mmask [2];

  assign waddr[0] = io_waddr_0;
  assign waddr[1] = io_waddr_1;
  assign waddr[2] = io_waddr_2;
  assign wdata[0] = io_wdata_0;
  assign wdata[1] = io_wdata_1;
  assign wdata[2] = io_wdata_2;
  assign mdata[0] = io_violationMdata_0;
  assign mdata[1] = io_violationMdata_1;

  xs_LqRawDataCam_core #(
    .NUM_ENTRIES (32),
    .DATA_W      (16),
    .NUM_WRITE   (3),
    .NUM_WBANK   (8),
    .NUM_CAM     (2),
    .LINE_CAM    (1'b0)
  ) u_core (
    .clock                 (clock),
    .io_wen                ({io_wen_2, io_wen_1, io_wen_0}),
    .io_waddr              (waddr),
    .io_wdata              (wdata),
    .io_violationMdata     (mdata),
    .io_violationCheckLine (2'b0),  // 掩码 CAM 不看整行标志
    .io_violationMmask     (mmask)
  );

  assign io_violationMmask_0_0 = mmask[0][0];
  assign io_violationMmask_0_1 = mmask[0][1];
  assign io_violationMmask_0_2 = mmask[0][2];
  assign io_violationMmask_0_3 = mmask[0][3];
  assign io_violationMmask_0_4 = mmask[0][4];
  assign io_violationMmask_0_5 = mmask[0][5];
  assign io_violationMmask_0_6 = mmask[0][6];
  assign io_violationMmask_0_7 = mmask[0][7];
  assign io_violationMmask_0_8 = mmask[0][8];
  assign io_violationMmask_0_9 = mmask[0][9];
  assign io_violationMmask_0_10 = mmask[0][10];
  assign io_violationMmask_0_11 = mmask[0][11];
  assign io_violationMmask_0_12 = mmask[0][12];
  assign io_violationMmask_0_13 = mmask[0][13];
  assign io_violationMmask_0_14 = mmask[0][14];
  assign io_violationMmask_0_15 = mmask[0][15];
  assign io_violationMmask_0_16 = mmask[0][16];
  assign io_violationMmask_0_17 = mmask[0][17];
  assign io_violationMmask_0_18 = mmask[0][18];
  assign io_violationMmask_0_19 = mmask[0][19];
  assign io_violationMmask_0_20 = mmask[0][20];
  assign io_violationMmask_0_21 = mmask[0][21];
  assign io_violationMmask_0_22 = mmask[0][22];
  assign io_violationMmask_0_23 = mmask[0][23];
  assign io_violationMmask_0_24 = mmask[0][24];
  assign io_violationMmask_0_25 = mmask[0][25];
  assign io_violationMmask_0_26 = mmask[0][26];
  assign io_violationMmask_0_27 = mmask[0][27];
  assign io_violationMmask_0_28 = mmask[0][28];
  assign io_violationMmask_0_29 = mmask[0][29];
  assign io_violationMmask_0_30 = mmask[0][30];
  assign io_violationMmask_0_31 = mmask[0][31];
  assign io_violationMmask_1_0 = mmask[1][0];
  assign io_violationMmask_1_1 = mmask[1][1];
  assign io_violationMmask_1_2 = mmask[1][2];
  assign io_violationMmask_1_3 = mmask[1][3];
  assign io_violationMmask_1_4 = mmask[1][4];
  assign io_violationMmask_1_5 = mmask[1][5];
  assign io_violationMmask_1_6 = mmask[1][6];
  assign io_violationMmask_1_7 = mmask[1][7];
  assign io_violationMmask_1_8 = mmask[1][8];
  assign io_violationMmask_1_9 = mmask[1][9];
  assign io_violationMmask_1_10 = mmask[1][10];
  assign io_violationMmask_1_11 = mmask[1][11];
  assign io_violationMmask_1_12 = mmask[1][12];
  assign io_violationMmask_1_13 = mmask[1][13];
  assign io_violationMmask_1_14 = mmask[1][14];
  assign io_violationMmask_1_15 = mmask[1][15];
  assign io_violationMmask_1_16 = mmask[1][16];
  assign io_violationMmask_1_17 = mmask[1][17];
  assign io_violationMmask_1_18 = mmask[1][18];
  assign io_violationMmask_1_19 = mmask[1][19];
  assign io_violationMmask_1_20 = mmask[1][20];
  assign io_violationMmask_1_21 = mmask[1][21];
  assign io_violationMmask_1_22 = mmask[1][22];
  assign io_violationMmask_1_23 = mmask[1][23];
  assign io_violationMmask_1_24 = mmask[1][24];
  assign io_violationMmask_1_25 = mmask[1][25];
  assign io_violationMmask_1_26 = mmask[1][26];
  assign io_violationMmask_1_27 = mmask[1][27];
  assign io_violationMmask_1_28 = mmask[1][28];
  assign io_violationMmask_1_29 = mmask[1][29];
  assign io_violationMmask_1_30 = mmask[1][30];
  assign io_violationMmask_1_31 = mmask[1][31];
endmodule
