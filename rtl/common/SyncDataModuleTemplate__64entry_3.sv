// SyncDataModuleTemplate__64entry_3 —— 外层同步读存储（分 bank + 输入寄存器复制）
// 形状：64 项 × 90 位，2 读口 / 1 写口；载荷字段：brMask_0, brMask_1, brMask_2, brMask_3…
// 核体见 rtl/common/xs_SyncDataModule.sv；本文件只做参数化与端口展平。
// 自动生成：scripts/gen_dm_wrappers.py（G1 基线驱动）—— 勿手改
module SyncDataModuleTemplate__64entry_3(
  input  clock,
  input  reset,
  input  io_ren_0,
  input  io_ren_1,
  input  [5:0] io_raddr_0,
  input  [5:0] io_raddr_1,
  output io_rdata_0_brMask_0,
  output io_rdata_0_brMask_1,
  output io_rdata_0_brMask_2,
  output io_rdata_0_brMask_3,
  output io_rdata_0_brMask_4,
  output io_rdata_0_brMask_5,
  output io_rdata_0_brMask_6,
  output io_rdata_0_brMask_7,
  output io_rdata_0_brMask_8,
  output io_rdata_0_brMask_9,
  output io_rdata_0_brMask_10,
  output io_rdata_0_brMask_11,
  output io_rdata_0_brMask_12,
  output io_rdata_0_brMask_13,
  output io_rdata_0_brMask_14,
  output io_rdata_0_brMask_15,
  output io_rdata_0_jmpInfo_valid,
  output io_rdata_0_jmpInfo_bits_0,
  output io_rdata_0_jmpInfo_bits_1,
  output io_rdata_0_jmpInfo_bits_2,
  output [3:0] io_rdata_0_jmpOffset,
  output io_rdata_0_rvcMask_0,
  output io_rdata_0_rvcMask_1,
  output io_rdata_0_rvcMask_2,
  output io_rdata_0_rvcMask_3,
  output io_rdata_0_rvcMask_4,
  output io_rdata_0_rvcMask_5,
  output io_rdata_0_rvcMask_6,
  output io_rdata_0_rvcMask_7,
  output io_rdata_0_rvcMask_8,
  output io_rdata_0_rvcMask_9,
  output io_rdata_0_rvcMask_10,
  output io_rdata_0_rvcMask_11,
  output io_rdata_0_rvcMask_12,
  output io_rdata_0_rvcMask_13,
  output io_rdata_0_rvcMask_14,
  output io_rdata_0_rvcMask_15,
  output io_rdata_1_brMask_0,
  output io_rdata_1_brMask_1,
  output io_rdata_1_brMask_2,
  output io_rdata_1_brMask_3,
  output io_rdata_1_brMask_4,
  output io_rdata_1_brMask_5,
  output io_rdata_1_brMask_6,
  output io_rdata_1_brMask_7,
  output io_rdata_1_brMask_8,
  output io_rdata_1_brMask_9,
  output io_rdata_1_brMask_10,
  output io_rdata_1_brMask_11,
  output io_rdata_1_brMask_12,
  output io_rdata_1_brMask_13,
  output io_rdata_1_brMask_14,
  output io_rdata_1_brMask_15,
  output io_rdata_1_jmpInfo_valid,
  output io_rdata_1_jmpInfo_bits_0,
  output io_rdata_1_jmpInfo_bits_1,
  output io_rdata_1_jmpInfo_bits_2,
  output [3:0] io_rdata_1_jmpOffset,
  output [49:0] io_rdata_1_jalTarget,
  output io_rdata_1_rvcMask_0,
  output io_rdata_1_rvcMask_1,
  output io_rdata_1_rvcMask_2,
  output io_rdata_1_rvcMask_3,
  output io_rdata_1_rvcMask_4,
  output io_rdata_1_rvcMask_5,
  output io_rdata_1_rvcMask_6,
  output io_rdata_1_rvcMask_7,
  output io_rdata_1_rvcMask_8,
  output io_rdata_1_rvcMask_9,
  output io_rdata_1_rvcMask_10,
  output io_rdata_1_rvcMask_11,
  output io_rdata_1_rvcMask_12,
  output io_rdata_1_rvcMask_13,
  output io_rdata_1_rvcMask_14,
  output io_rdata_1_rvcMask_15,
  input  io_wen_0,
  input  [5:0] io_waddr_0,
  input  io_wdata_0_brMask_0,
  input  io_wdata_0_brMask_1,
  input  io_wdata_0_brMask_2,
  input  io_wdata_0_brMask_3,
  input  io_wdata_0_brMask_4,
  input  io_wdata_0_brMask_5,
  input  io_wdata_0_brMask_6,
  input  io_wdata_0_brMask_7,
  input  io_wdata_0_brMask_8,
  input  io_wdata_0_brMask_9,
  input  io_wdata_0_brMask_10,
  input  io_wdata_0_brMask_11,
  input  io_wdata_0_brMask_12,
  input  io_wdata_0_brMask_13,
  input  io_wdata_0_brMask_14,
  input  io_wdata_0_brMask_15,
  input  io_wdata_0_jmpInfo_valid,
  input  io_wdata_0_jmpInfo_bits_0,
  input  io_wdata_0_jmpInfo_bits_1,
  input  io_wdata_0_jmpInfo_bits_2,
  input  [3:0] io_wdata_0_jmpOffset,
  input  [49:0] io_wdata_0_jalTarget,
  input  io_wdata_0_rvcMask_0,
  input  io_wdata_0_rvcMask_1,
  input  io_wdata_0_rvcMask_2,
  input  io_wdata_0_rvcMask_3,
  input  io_wdata_0_rvcMask_4,
  input  io_wdata_0_rvcMask_5,
  input  io_wdata_0_rvcMask_6,
  input  io_wdata_0_rvcMask_7,
  input  io_wdata_0_rvcMask_8,
  input  io_wdata_0_rvcMask_9,
  input  io_wdata_0_rvcMask_10,
  input  io_wdata_0_rvcMask_11,
  input  io_wdata_0_rvcMask_12,
  input  io_wdata_0_rvcMask_13,
  input  io_wdata_0_rvcMask_14,
  input  io_wdata_0_rvcMask_15
);
  wire [2-1:0][90-1:0] rdata_bus;
  assign io_rdata_0_brMask_0 = rdata_bus[0][0:0];
  assign io_rdata_0_brMask_1 = rdata_bus[0][1:1];
  assign io_rdata_0_brMask_2 = rdata_bus[0][2:2];
  assign io_rdata_0_brMask_3 = rdata_bus[0][3:3];
  assign io_rdata_0_brMask_4 = rdata_bus[0][4:4];
  assign io_rdata_0_brMask_5 = rdata_bus[0][5:5];
  assign io_rdata_0_brMask_6 = rdata_bus[0][6:6];
  assign io_rdata_0_brMask_7 = rdata_bus[0][7:7];
  assign io_rdata_0_brMask_8 = rdata_bus[0][8:8];
  assign io_rdata_0_brMask_9 = rdata_bus[0][9:9];
  assign io_rdata_0_brMask_10 = rdata_bus[0][10:10];
  assign io_rdata_0_brMask_11 = rdata_bus[0][11:11];
  assign io_rdata_0_brMask_12 = rdata_bus[0][12:12];
  assign io_rdata_0_brMask_13 = rdata_bus[0][13:13];
  assign io_rdata_0_brMask_14 = rdata_bus[0][14:14];
  assign io_rdata_0_brMask_15 = rdata_bus[0][15:15];
  assign io_rdata_0_jmpInfo_valid = rdata_bus[0][16:16];
  assign io_rdata_0_jmpInfo_bits_0 = rdata_bus[0][17:17];
  assign io_rdata_0_jmpInfo_bits_1 = rdata_bus[0][18:18];
  assign io_rdata_0_jmpInfo_bits_2 = rdata_bus[0][19:19];
  assign io_rdata_0_jmpOffset = rdata_bus[0][23:20];
  assign io_rdata_0_rvcMask_0 = rdata_bus[0][74:74];
  assign io_rdata_0_rvcMask_1 = rdata_bus[0][75:75];
  assign io_rdata_0_rvcMask_2 = rdata_bus[0][76:76];
  assign io_rdata_0_rvcMask_3 = rdata_bus[0][77:77];
  assign io_rdata_0_rvcMask_4 = rdata_bus[0][78:78];
  assign io_rdata_0_rvcMask_5 = rdata_bus[0][79:79];
  assign io_rdata_0_rvcMask_6 = rdata_bus[0][80:80];
  assign io_rdata_0_rvcMask_7 = rdata_bus[0][81:81];
  assign io_rdata_0_rvcMask_8 = rdata_bus[0][82:82];
  assign io_rdata_0_rvcMask_9 = rdata_bus[0][83:83];
  assign io_rdata_0_rvcMask_10 = rdata_bus[0][84:84];
  assign io_rdata_0_rvcMask_11 = rdata_bus[0][85:85];
  assign io_rdata_0_rvcMask_12 = rdata_bus[0][86:86];
  assign io_rdata_0_rvcMask_13 = rdata_bus[0][87:87];
  assign io_rdata_0_rvcMask_14 = rdata_bus[0][88:88];
  assign io_rdata_0_rvcMask_15 = rdata_bus[0][89:89];
  assign io_rdata_1_brMask_0 = rdata_bus[1][0:0];
  assign io_rdata_1_brMask_1 = rdata_bus[1][1:1];
  assign io_rdata_1_brMask_2 = rdata_bus[1][2:2];
  assign io_rdata_1_brMask_3 = rdata_bus[1][3:3];
  assign io_rdata_1_brMask_4 = rdata_bus[1][4:4];
  assign io_rdata_1_brMask_5 = rdata_bus[1][5:5];
  assign io_rdata_1_brMask_6 = rdata_bus[1][6:6];
  assign io_rdata_1_brMask_7 = rdata_bus[1][7:7];
  assign io_rdata_1_brMask_8 = rdata_bus[1][8:8];
  assign io_rdata_1_brMask_9 = rdata_bus[1][9:9];
  assign io_rdata_1_brMask_10 = rdata_bus[1][10:10];
  assign io_rdata_1_brMask_11 = rdata_bus[1][11:11];
  assign io_rdata_1_brMask_12 = rdata_bus[1][12:12];
  assign io_rdata_1_brMask_13 = rdata_bus[1][13:13];
  assign io_rdata_1_brMask_14 = rdata_bus[1][14:14];
  assign io_rdata_1_brMask_15 = rdata_bus[1][15:15];
  assign io_rdata_1_jmpInfo_valid = rdata_bus[1][16:16];
  assign io_rdata_1_jmpInfo_bits_0 = rdata_bus[1][17:17];
  assign io_rdata_1_jmpInfo_bits_1 = rdata_bus[1][18:18];
  assign io_rdata_1_jmpInfo_bits_2 = rdata_bus[1][19:19];
  assign io_rdata_1_jmpOffset = rdata_bus[1][23:20];
  assign io_rdata_1_jalTarget = rdata_bus[1][73:24];
  assign io_rdata_1_rvcMask_0 = rdata_bus[1][74:74];
  assign io_rdata_1_rvcMask_1 = rdata_bus[1][75:75];
  assign io_rdata_1_rvcMask_2 = rdata_bus[1][76:76];
  assign io_rdata_1_rvcMask_3 = rdata_bus[1][77:77];
  assign io_rdata_1_rvcMask_4 = rdata_bus[1][78:78];
  assign io_rdata_1_rvcMask_5 = rdata_bus[1][79:79];
  assign io_rdata_1_rvcMask_6 = rdata_bus[1][80:80];
  assign io_rdata_1_rvcMask_7 = rdata_bus[1][81:81];
  assign io_rdata_1_rvcMask_8 = rdata_bus[1][82:82];
  assign io_rdata_1_rvcMask_9 = rdata_bus[1][83:83];
  assign io_rdata_1_rvcMask_10 = rdata_bus[1][84:84];
  assign io_rdata_1_rvcMask_11 = rdata_bus[1][85:85];
  assign io_rdata_1_rvcMask_12 = rdata_bus[1][86:86];
  assign io_rdata_1_rvcMask_13 = rdata_bus[1][87:87];
  assign io_rdata_1_rvcMask_14 = rdata_bus[1][88:88];
  assign io_rdata_1_rvcMask_15 = rdata_bus[1][89:89];
  xs_SyncDataModule #(
    .NUM_ENTRIES(64),
    .NUM_READ(2),
    .NUM_WRITE(1),
    .DATA_WIDTH(90),
    .HAS_REN(1),
    .BYPASS_EN(2'b11)
  ) u_core (
    .clock(clock),
    .reset(reset),
    .io_ren({io_ren_1, io_ren_0}),
    .io_raddr({io_raddr_1, io_raddr_0}),
    .io_rdata(rdata_bus),
    .io_wen({io_wen_0}),
    .io_waddr({io_waddr_0}),
    .io_wdata({{io_wdata_0_rvcMask_15, io_wdata_0_rvcMask_14, io_wdata_0_rvcMask_13, io_wdata_0_rvcMask_12, io_wdata_0_rvcMask_11, io_wdata_0_rvcMask_10, io_wdata_0_rvcMask_9, io_wdata_0_rvcMask_8, io_wdata_0_rvcMask_7, io_wdata_0_rvcMask_6, io_wdata_0_rvcMask_5, io_wdata_0_rvcMask_4, io_wdata_0_rvcMask_3, io_wdata_0_rvcMask_2, io_wdata_0_rvcMask_1, io_wdata_0_rvcMask_0, io_wdata_0_jalTarget, io_wdata_0_jmpOffset, io_wdata_0_jmpInfo_bits_2, io_wdata_0_jmpInfo_bits_1, io_wdata_0_jmpInfo_bits_0, io_wdata_0_jmpInfo_valid, io_wdata_0_brMask_15, io_wdata_0_brMask_14, io_wdata_0_brMask_13, io_wdata_0_brMask_12, io_wdata_0_brMask_11, io_wdata_0_brMask_10, io_wdata_0_brMask_9, io_wdata_0_brMask_8, io_wdata_0_brMask_7, io_wdata_0_brMask_6, io_wdata_0_brMask_5, io_wdata_0_brMask_4, io_wdata_0_brMask_3, io_wdata_0_brMask_2, io_wdata_0_brMask_1, io_wdata_0_brMask_0}})
  );
endmodule
