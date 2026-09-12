// SyncDataModuleTemplate_FtqPC_64entry —— 外层同步读存储（分 bank + 输入寄存器复制）
// 形状：64 项 × 101 位，7 读口 / 1 写口；载荷字段：startAddr, nextLineAddr, fallThruError
// 核体见 rtl/common/xs_SyncDataModule.sv；本文件只做参数化与端口展平。
// 自动生成：scripts/gen_dm_wrappers.py（G1 基线驱动）—— 勿手改
module SyncDataModuleTemplate_FtqPC_64entry(
  input  clock,
  input  reset,
  input  [5:0] io_raddr_0,
  input  [5:0] io_raddr_1,
  input  [5:0] io_raddr_2,
  input  [5:0] io_raddr_3,
  input  [5:0] io_raddr_4,
  input  [5:0] io_raddr_5,
  input  [5:0] io_raddr_6,
  output [49:0] io_rdata_0_startAddr,
  output [49:0] io_rdata_0_nextLineAddr,
  output io_rdata_0_fallThruError,
  output [49:0] io_rdata_1_startAddr,
  output [49:0] io_rdata_1_nextLineAddr,
  output io_rdata_1_fallThruError,
  output [49:0] io_rdata_2_startAddr,
  output [49:0] io_rdata_3_startAddr,
  output [49:0] io_rdata_3_nextLineAddr,
  output [49:0] io_rdata_4_startAddr,
  output [49:0] io_rdata_4_nextLineAddr,
  output [49:0] io_rdata_5_startAddr,
  output [49:0] io_rdata_6_startAddr,
  input  io_wen_0,
  input  [5:0] io_waddr_0,
  input  [49:0] io_wdata_0_startAddr,
  input  [49:0] io_wdata_0_nextLineAddr,
  input  io_wdata_0_fallThruError
);
  wire [7-1:0][101-1:0] rdata_bus;
  assign io_rdata_0_startAddr = rdata_bus[0][49:0];
  assign io_rdata_0_nextLineAddr = rdata_bus[0][99:50];
  assign io_rdata_0_fallThruError = rdata_bus[0][100:100];
  assign io_rdata_1_startAddr = rdata_bus[1][49:0];
  assign io_rdata_1_nextLineAddr = rdata_bus[1][99:50];
  assign io_rdata_1_fallThruError = rdata_bus[1][100:100];
  assign io_rdata_2_startAddr = rdata_bus[2][49:0];
  assign io_rdata_3_startAddr = rdata_bus[3][49:0];
  assign io_rdata_3_nextLineAddr = rdata_bus[3][99:50];
  assign io_rdata_4_startAddr = rdata_bus[4][49:0];
  assign io_rdata_4_nextLineAddr = rdata_bus[4][99:50];
  assign io_rdata_5_startAddr = rdata_bus[5][49:0];
  assign io_rdata_6_startAddr = rdata_bus[6][49:0];
  xs_SyncDataModule #(
    .NUM_ENTRIES(64),
    .NUM_READ(7),
    .NUM_WRITE(1),
    .DATA_WIDTH(101),
    .HAS_REN(0),
    .BYPASS_EN(7'b1111111)
  ) u_core (
    .clock(clock),
    .reset(reset),
    .io_ren({7{1'b1}}),
    .io_raddr({io_raddr_6, io_raddr_5, io_raddr_4, io_raddr_3, io_raddr_2, io_raddr_1, io_raddr_0}),
    .io_rdata(rdata_bus),
    .io_wen({io_wen_0}),
    .io_waddr({io_waddr_0}),
    .io_wdata({{io_wdata_0_fallThruError, io_wdata_0_nextLineAddr, io_wdata_0_startAddr}})
  );
endmodule
