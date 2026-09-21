// =============================================================================
// SQAddrModule_1.sv —— StoreQueue 地址阵列(vaddrModule 变体)薄 wrapper
// -----------------------------------------------------------------------------
// 核体见 SQAddrModule.sv 的 xs_SQAddrModule_core(家族共享)。本文件只有一个
// always_comb,做的是把 golden 的扁平端口打包成核的数组接口 —— 纯改线,
// 无任何运算、无状态。
//
// 本变体 = DATA_WIDTH 50(VAddrBits+1,虚地址),**不引出** rlineflag 读口。
// ★ 不引出 ≠ 没有 lineflag ★:56 个 lineflag 寄存器、io_wlineflag_0/1 输入、
//   以及 168 条前递比较式里的 lineflag[j] 项在本变体里一个不少,被 DCE 掉的只有
//   两个 io_rlineflag_* 输出端口及其读通路。核里由 HAS_RLINEFLAG_OUT=0 控制:
//   那一份读地址寄存器**不生成**,避免多出没人读的死寄存器。
//
// 端口名/顺序/位宽逐位对齐 G1 golden-rtl/SQAddrModule_1.sv。
// =============================================================================

module SQAddrModule_1(
  input          clock,
  input          reset,
  input  [5:0]   io_raddr_0,
  input  [5:0]   io_raddr_1,
  output [49:0]  io_rdata_0,
  output [49:0]  io_rdata_1,
  input          io_wen_0,
  input          io_wen_1,
  input  [5:0]   io_waddr_0,
  input  [5:0]   io_waddr_1,
  input  [49:0]  io_wdata_0,
  input  [49:0]  io_wdata_1,
  input  [15:0]  io_wmask_0,
  input  [15:0]  io_wmask_1,
  input          io_wlineflag_0,
  input          io_wlineflag_1,
  input  [49:0]  io_forwardMdata_0,
  input  [49:0]  io_forwardMdata_1,
  input  [49:0]  io_forwardMdata_2,
  input  [15:0]  io_forwardDataMask_0,
  input  [15:0]  io_forwardDataMask_1,
  input  [15:0]  io_forwardDataMask_2,
  output         io_forwardMmask_0_0,
  output         io_forwardMmask_0_1,
  output         io_forwardMmask_0_2,
  output         io_forwardMmask_0_3,
  output         io_forwardMmask_0_4,
  output         io_forwardMmask_0_5,
  output         io_forwardMmask_0_6,
  output         io_forwardMmask_0_7,
  output         io_forwardMmask_0_8,
  output         io_forwardMmask_0_9,
  output         io_forwardMmask_0_10,
  output         io_forwardMmask_0_11,
  output         io_forwardMmask_0_12,
  output         io_forwardMmask_0_13,
  output         io_forwardMmask_0_14,
  output         io_forwardMmask_0_15,
  output         io_forwardMmask_0_16,
  output         io_forwardMmask_0_17,
  output         io_forwardMmask_0_18,
  output         io_forwardMmask_0_19,
  output         io_forwardMmask_0_20,
  output         io_forwardMmask_0_21,
  output         io_forwardMmask_0_22,
  output         io_forwardMmask_0_23,
  output         io_forwardMmask_0_24,
  output         io_forwardMmask_0_25,
  output         io_forwardMmask_0_26,
  output         io_forwardMmask_0_27,
  output         io_forwardMmask_0_28,
  output         io_forwardMmask_0_29,
  output         io_forwardMmask_0_30,
  output         io_forwardMmask_0_31,
  output         io_forwardMmask_0_32,
  output         io_forwardMmask_0_33,
  output         io_forwardMmask_0_34,
  output         io_forwardMmask_0_35,
  output         io_forwardMmask_0_36,
  output         io_forwardMmask_0_37,
  output         io_forwardMmask_0_38,
  output         io_forwardMmask_0_39,
  output         io_forwardMmask_0_40,
  output         io_forwardMmask_0_41,
  output         io_forwardMmask_0_42,
  output         io_forwardMmask_0_43,
  output         io_forwardMmask_0_44,
  output         io_forwardMmask_0_45,
  output         io_forwardMmask_0_46,
  output         io_forwardMmask_0_47,
  output         io_forwardMmask_0_48,
  output         io_forwardMmask_0_49,
  output         io_forwardMmask_0_50,
  output         io_forwardMmask_0_51,
  output         io_forwardMmask_0_52,
  output         io_forwardMmask_0_53,
  output         io_forwardMmask_0_54,
  output         io_forwardMmask_0_55,
  output         io_forwardMmask_1_0,
  output         io_forwardMmask_1_1,
  output         io_forwardMmask_1_2,
  output         io_forwardMmask_1_3,
  output         io_forwardMmask_1_4,
  output         io_forwardMmask_1_5,
  output         io_forwardMmask_1_6,
  output         io_forwardMmask_1_7,
  output         io_forwardMmask_1_8,
  output         io_forwardMmask_1_9,
  output         io_forwardMmask_1_10,
  output         io_forwardMmask_1_11,
  output         io_forwardMmask_1_12,
  output         io_forwardMmask_1_13,
  output         io_forwardMmask_1_14,
  output         io_forwardMmask_1_15,
  output         io_forwardMmask_1_16,
  output         io_forwardMmask_1_17,
  output         io_forwardMmask_1_18,
  output         io_forwardMmask_1_19,
  output         io_forwardMmask_1_20,
  output         io_forwardMmask_1_21,
  output         io_forwardMmask_1_22,
  output         io_forwardMmask_1_23,
  output         io_forwardMmask_1_24,
  output         io_forwardMmask_1_25,
  output         io_forwardMmask_1_26,
  output         io_forwardMmask_1_27,
  output         io_forwardMmask_1_28,
  output         io_forwardMmask_1_29,
  output         io_forwardMmask_1_30,
  output         io_forwardMmask_1_31,
  output         io_forwardMmask_1_32,
  output         io_forwardMmask_1_33,
  output         io_forwardMmask_1_34,
  output         io_forwardMmask_1_35,
  output         io_forwardMmask_1_36,
  output         io_forwardMmask_1_37,
  output         io_forwardMmask_1_38,
  output         io_forwardMmask_1_39,
  output         io_forwardMmask_1_40,
  output         io_forwardMmask_1_41,
  output         io_forwardMmask_1_42,
  output         io_forwardMmask_1_43,
  output         io_forwardMmask_1_44,
  output         io_forwardMmask_1_45,
  output         io_forwardMmask_1_46,
  output         io_forwardMmask_1_47,
  output         io_forwardMmask_1_48,
  output         io_forwardMmask_1_49,
  output         io_forwardMmask_1_50,
  output         io_forwardMmask_1_51,
  output         io_forwardMmask_1_52,
  output         io_forwardMmask_1_53,
  output         io_forwardMmask_1_54,
  output         io_forwardMmask_1_55,
  output         io_forwardMmask_2_0,
  output         io_forwardMmask_2_1,
  output         io_forwardMmask_2_2,
  output         io_forwardMmask_2_3,
  output         io_forwardMmask_2_4,
  output         io_forwardMmask_2_5,
  output         io_forwardMmask_2_6,
  output         io_forwardMmask_2_7,
  output         io_forwardMmask_2_8,
  output         io_forwardMmask_2_9,
  output         io_forwardMmask_2_10,
  output         io_forwardMmask_2_11,
  output         io_forwardMmask_2_12,
  output         io_forwardMmask_2_13,
  output         io_forwardMmask_2_14,
  output         io_forwardMmask_2_15,
  output         io_forwardMmask_2_16,
  output         io_forwardMmask_2_17,
  output         io_forwardMmask_2_18,
  output         io_forwardMmask_2_19,
  output         io_forwardMmask_2_20,
  output         io_forwardMmask_2_21,
  output         io_forwardMmask_2_22,
  output         io_forwardMmask_2_23,
  output         io_forwardMmask_2_24,
  output         io_forwardMmask_2_25,
  output         io_forwardMmask_2_26,
  output         io_forwardMmask_2_27,
  output         io_forwardMmask_2_28,
  output         io_forwardMmask_2_29,
  output         io_forwardMmask_2_30,
  output         io_forwardMmask_2_31,
  output         io_forwardMmask_2_32,
  output         io_forwardMmask_2_33,
  output         io_forwardMmask_2_34,
  output         io_forwardMmask_2_35,
  output         io_forwardMmask_2_36,
  output         io_forwardMmask_2_37,
  output         io_forwardMmask_2_38,
  output         io_forwardMmask_2_39,
  output         io_forwardMmask_2_40,
  output         io_forwardMmask_2_41,
  output         io_forwardMmask_2_42,
  output         io_forwardMmask_2_43,
  output         io_forwardMmask_2_44,
  output         io_forwardMmask_2_45,
  output         io_forwardMmask_2_46,
  output         io_forwardMmask_2_47,
  output         io_forwardMmask_2_48,
  output         io_forwardMmask_2_49,
  output         io_forwardMmask_2_50,
  output         io_forwardMmask_2_51,
  output         io_forwardMmask_2_52,
  output         io_forwardMmask_2_53,
  output         io_forwardMmask_2_54,
  output         io_forwardMmask_2_55
);

  localparam int DW = 50;

  logic [5:0]    raddr     [2];
  logic [DW-1:0] rdata     [2];
  logic          rlineflag [2];
  logic          wen       [2];
  logic [5:0]    waddr     [2];
  logic [DW-1:0] wdata     [2];
  logic [15:0]   wmask     [2];
  logic          wlineflag [2];
  logic [DW-1:0] forwardMdata    [3];
  logic [15:0]   forwardDataMask [3];
  logic [55:0]   forwardMmask    [3];

  always_comb begin
    raddr[0]           = io_raddr_0;
    raddr[1]           = io_raddr_1;
    wen[0]             = io_wen_0;
    waddr[0]           = io_waddr_0;
    wdata[0]           = io_wdata_0;
    wmask[0]           = io_wmask_0;
    wlineflag[0]       = io_wlineflag_0;
    wen[1]             = io_wen_1;
    waddr[1]           = io_waddr_1;
    wdata[1]           = io_wdata_1;
    wmask[1]           = io_wmask_1;
    wlineflag[1]       = io_wlineflag_1;
    forwardMdata[0]    = io_forwardMdata_0;
    forwardDataMask[0] = io_forwardDataMask_0;
    forwardMdata[1]    = io_forwardMdata_1;
    forwardDataMask[1] = io_forwardDataMask_1;
    forwardMdata[2]    = io_forwardMdata_2;
    forwardDataMask[2] = io_forwardDataMask_2;
  end

  xs_SQAddrModule_core #(
    .DATA_WIDTH        (50),
    .HAS_RLINEFLAG_OUT (1'b0)
  ) u_core (
    .clock           (clock),
    .reset           (reset),
    .raddr           (raddr),
    .rdata           (rdata),
    .rlineflag       (rlineflag),
    .wen             (wen),
    .waddr           (waddr),
    .wdata           (wdata),
    .wmask           (wmask),
    .wlineflag       (wlineflag),
    .forwardMdata    (forwardMdata),
    .forwardDataMask (forwardDataMask),
    .forwardMmask    (forwardMmask)
  );

  assign io_rdata_0 = rdata[0];
  assign io_rdata_1 = rdata[1];
  // 本变体不引出 rlineflag:核里 HAS_RLINEFLAG_OUT=0,rlineflag[] 恒 0 且无人读。

  // 前递命中掩码:核里是 3 个 56 位向量,golden 摊平成 168 个 1 位输出。
  assign io_forwardMmask_0_0 = forwardMmask[0][0];
  assign io_forwardMmask_0_1 = forwardMmask[0][1];
  assign io_forwardMmask_0_2 = forwardMmask[0][2];
  assign io_forwardMmask_0_3 = forwardMmask[0][3];
  assign io_forwardMmask_0_4 = forwardMmask[0][4];
  assign io_forwardMmask_0_5 = forwardMmask[0][5];
  assign io_forwardMmask_0_6 = forwardMmask[0][6];
  assign io_forwardMmask_0_7 = forwardMmask[0][7];
  assign io_forwardMmask_0_8 = forwardMmask[0][8];
  assign io_forwardMmask_0_9 = forwardMmask[0][9];
  assign io_forwardMmask_0_10 = forwardMmask[0][10];
  assign io_forwardMmask_0_11 = forwardMmask[0][11];
  assign io_forwardMmask_0_12 = forwardMmask[0][12];
  assign io_forwardMmask_0_13 = forwardMmask[0][13];
  assign io_forwardMmask_0_14 = forwardMmask[0][14];
  assign io_forwardMmask_0_15 = forwardMmask[0][15];
  assign io_forwardMmask_0_16 = forwardMmask[0][16];
  assign io_forwardMmask_0_17 = forwardMmask[0][17];
  assign io_forwardMmask_0_18 = forwardMmask[0][18];
  assign io_forwardMmask_0_19 = forwardMmask[0][19];
  assign io_forwardMmask_0_20 = forwardMmask[0][20];
  assign io_forwardMmask_0_21 = forwardMmask[0][21];
  assign io_forwardMmask_0_22 = forwardMmask[0][22];
  assign io_forwardMmask_0_23 = forwardMmask[0][23];
  assign io_forwardMmask_0_24 = forwardMmask[0][24];
  assign io_forwardMmask_0_25 = forwardMmask[0][25];
  assign io_forwardMmask_0_26 = forwardMmask[0][26];
  assign io_forwardMmask_0_27 = forwardMmask[0][27];
  assign io_forwardMmask_0_28 = forwardMmask[0][28];
  assign io_forwardMmask_0_29 = forwardMmask[0][29];
  assign io_forwardMmask_0_30 = forwardMmask[0][30];
  assign io_forwardMmask_0_31 = forwardMmask[0][31];
  assign io_forwardMmask_0_32 = forwardMmask[0][32];
  assign io_forwardMmask_0_33 = forwardMmask[0][33];
  assign io_forwardMmask_0_34 = forwardMmask[0][34];
  assign io_forwardMmask_0_35 = forwardMmask[0][35];
  assign io_forwardMmask_0_36 = forwardMmask[0][36];
  assign io_forwardMmask_0_37 = forwardMmask[0][37];
  assign io_forwardMmask_0_38 = forwardMmask[0][38];
  assign io_forwardMmask_0_39 = forwardMmask[0][39];
  assign io_forwardMmask_0_40 = forwardMmask[0][40];
  assign io_forwardMmask_0_41 = forwardMmask[0][41];
  assign io_forwardMmask_0_42 = forwardMmask[0][42];
  assign io_forwardMmask_0_43 = forwardMmask[0][43];
  assign io_forwardMmask_0_44 = forwardMmask[0][44];
  assign io_forwardMmask_0_45 = forwardMmask[0][45];
  assign io_forwardMmask_0_46 = forwardMmask[0][46];
  assign io_forwardMmask_0_47 = forwardMmask[0][47];
  assign io_forwardMmask_0_48 = forwardMmask[0][48];
  assign io_forwardMmask_0_49 = forwardMmask[0][49];
  assign io_forwardMmask_0_50 = forwardMmask[0][50];
  assign io_forwardMmask_0_51 = forwardMmask[0][51];
  assign io_forwardMmask_0_52 = forwardMmask[0][52];
  assign io_forwardMmask_0_53 = forwardMmask[0][53];
  assign io_forwardMmask_0_54 = forwardMmask[0][54];
  assign io_forwardMmask_0_55 = forwardMmask[0][55];
  assign io_forwardMmask_1_0 = forwardMmask[1][0];
  assign io_forwardMmask_1_1 = forwardMmask[1][1];
  assign io_forwardMmask_1_2 = forwardMmask[1][2];
  assign io_forwardMmask_1_3 = forwardMmask[1][3];
  assign io_forwardMmask_1_4 = forwardMmask[1][4];
  assign io_forwardMmask_1_5 = forwardMmask[1][5];
  assign io_forwardMmask_1_6 = forwardMmask[1][6];
  assign io_forwardMmask_1_7 = forwardMmask[1][7];
  assign io_forwardMmask_1_8 = forwardMmask[1][8];
  assign io_forwardMmask_1_9 = forwardMmask[1][9];
  assign io_forwardMmask_1_10 = forwardMmask[1][10];
  assign io_forwardMmask_1_11 = forwardMmask[1][11];
  assign io_forwardMmask_1_12 = forwardMmask[1][12];
  assign io_forwardMmask_1_13 = forwardMmask[1][13];
  assign io_forwardMmask_1_14 = forwardMmask[1][14];
  assign io_forwardMmask_1_15 = forwardMmask[1][15];
  assign io_forwardMmask_1_16 = forwardMmask[1][16];
  assign io_forwardMmask_1_17 = forwardMmask[1][17];
  assign io_forwardMmask_1_18 = forwardMmask[1][18];
  assign io_forwardMmask_1_19 = forwardMmask[1][19];
  assign io_forwardMmask_1_20 = forwardMmask[1][20];
  assign io_forwardMmask_1_21 = forwardMmask[1][21];
  assign io_forwardMmask_1_22 = forwardMmask[1][22];
  assign io_forwardMmask_1_23 = forwardMmask[1][23];
  assign io_forwardMmask_1_24 = forwardMmask[1][24];
  assign io_forwardMmask_1_25 = forwardMmask[1][25];
  assign io_forwardMmask_1_26 = forwardMmask[1][26];
  assign io_forwardMmask_1_27 = forwardMmask[1][27];
  assign io_forwardMmask_1_28 = forwardMmask[1][28];
  assign io_forwardMmask_1_29 = forwardMmask[1][29];
  assign io_forwardMmask_1_30 = forwardMmask[1][30];
  assign io_forwardMmask_1_31 = forwardMmask[1][31];
  assign io_forwardMmask_1_32 = forwardMmask[1][32];
  assign io_forwardMmask_1_33 = forwardMmask[1][33];
  assign io_forwardMmask_1_34 = forwardMmask[1][34];
  assign io_forwardMmask_1_35 = forwardMmask[1][35];
  assign io_forwardMmask_1_36 = forwardMmask[1][36];
  assign io_forwardMmask_1_37 = forwardMmask[1][37];
  assign io_forwardMmask_1_38 = forwardMmask[1][38];
  assign io_forwardMmask_1_39 = forwardMmask[1][39];
  assign io_forwardMmask_1_40 = forwardMmask[1][40];
  assign io_forwardMmask_1_41 = forwardMmask[1][41];
  assign io_forwardMmask_1_42 = forwardMmask[1][42];
  assign io_forwardMmask_1_43 = forwardMmask[1][43];
  assign io_forwardMmask_1_44 = forwardMmask[1][44];
  assign io_forwardMmask_1_45 = forwardMmask[1][45];
  assign io_forwardMmask_1_46 = forwardMmask[1][46];
  assign io_forwardMmask_1_47 = forwardMmask[1][47];
  assign io_forwardMmask_1_48 = forwardMmask[1][48];
  assign io_forwardMmask_1_49 = forwardMmask[1][49];
  assign io_forwardMmask_1_50 = forwardMmask[1][50];
  assign io_forwardMmask_1_51 = forwardMmask[1][51];
  assign io_forwardMmask_1_52 = forwardMmask[1][52];
  assign io_forwardMmask_1_53 = forwardMmask[1][53];
  assign io_forwardMmask_1_54 = forwardMmask[1][54];
  assign io_forwardMmask_1_55 = forwardMmask[1][55];
  assign io_forwardMmask_2_0 = forwardMmask[2][0];
  assign io_forwardMmask_2_1 = forwardMmask[2][1];
  assign io_forwardMmask_2_2 = forwardMmask[2][2];
  assign io_forwardMmask_2_3 = forwardMmask[2][3];
  assign io_forwardMmask_2_4 = forwardMmask[2][4];
  assign io_forwardMmask_2_5 = forwardMmask[2][5];
  assign io_forwardMmask_2_6 = forwardMmask[2][6];
  assign io_forwardMmask_2_7 = forwardMmask[2][7];
  assign io_forwardMmask_2_8 = forwardMmask[2][8];
  assign io_forwardMmask_2_9 = forwardMmask[2][9];
  assign io_forwardMmask_2_10 = forwardMmask[2][10];
  assign io_forwardMmask_2_11 = forwardMmask[2][11];
  assign io_forwardMmask_2_12 = forwardMmask[2][12];
  assign io_forwardMmask_2_13 = forwardMmask[2][13];
  assign io_forwardMmask_2_14 = forwardMmask[2][14];
  assign io_forwardMmask_2_15 = forwardMmask[2][15];
  assign io_forwardMmask_2_16 = forwardMmask[2][16];
  assign io_forwardMmask_2_17 = forwardMmask[2][17];
  assign io_forwardMmask_2_18 = forwardMmask[2][18];
  assign io_forwardMmask_2_19 = forwardMmask[2][19];
  assign io_forwardMmask_2_20 = forwardMmask[2][20];
  assign io_forwardMmask_2_21 = forwardMmask[2][21];
  assign io_forwardMmask_2_22 = forwardMmask[2][22];
  assign io_forwardMmask_2_23 = forwardMmask[2][23];
  assign io_forwardMmask_2_24 = forwardMmask[2][24];
  assign io_forwardMmask_2_25 = forwardMmask[2][25];
  assign io_forwardMmask_2_26 = forwardMmask[2][26];
  assign io_forwardMmask_2_27 = forwardMmask[2][27];
  assign io_forwardMmask_2_28 = forwardMmask[2][28];
  assign io_forwardMmask_2_29 = forwardMmask[2][29];
  assign io_forwardMmask_2_30 = forwardMmask[2][30];
  assign io_forwardMmask_2_31 = forwardMmask[2][31];
  assign io_forwardMmask_2_32 = forwardMmask[2][32];
  assign io_forwardMmask_2_33 = forwardMmask[2][33];
  assign io_forwardMmask_2_34 = forwardMmask[2][34];
  assign io_forwardMmask_2_35 = forwardMmask[2][35];
  assign io_forwardMmask_2_36 = forwardMmask[2][36];
  assign io_forwardMmask_2_37 = forwardMmask[2][37];
  assign io_forwardMmask_2_38 = forwardMmask[2][38];
  assign io_forwardMmask_2_39 = forwardMmask[2][39];
  assign io_forwardMmask_2_40 = forwardMmask[2][40];
  assign io_forwardMmask_2_41 = forwardMmask[2][41];
  assign io_forwardMmask_2_42 = forwardMmask[2][42];
  assign io_forwardMmask_2_43 = forwardMmask[2][43];
  assign io_forwardMmask_2_44 = forwardMmask[2][44];
  assign io_forwardMmask_2_45 = forwardMmask[2][45];
  assign io_forwardMmask_2_46 = forwardMmask[2][46];
  assign io_forwardMmask_2_47 = forwardMmask[2][47];
  assign io_forwardMmask_2_48 = forwardMmask[2][48];
  assign io_forwardMmask_2_49 = forwardMmask[2][49];
  assign io_forwardMmask_2_50 = forwardMmask[2][50];
  assign io_forwardMmask_2_51 = forwardMmask[2][51];
  assign io_forwardMmask_2_52 = forwardMmask[2][52];
  assign io_forwardMmask_2_53 = forwardMmask[2][53];
  assign io_forwardMmask_2_54 = forwardMmask[2][54];
  assign io_forwardMmask_2_55 = forwardMmask[2][55];

endmodule
