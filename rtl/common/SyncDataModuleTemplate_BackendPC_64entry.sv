// SyncDataModuleTemplate_BackendPC_64entry —— 外层同步读存储（分 bank + 输入寄存器复制）
// 形状：64 项 × 50 位，15 读口 / 1 写口；载荷字段：startAddr
// 核体见 rtl/common/xs_SyncDataModule.sv；本文件只做参数化与端口展平。
// 自动生成：scripts/gen_dm_wrappers.py（G1 基线驱动）—— 勿手改
module SyncDataModuleTemplate_BackendPC_64entry(
  input  clock,
  input  reset,
  input  io_ren_0,
  input  io_ren_1,
  input  io_ren_2,
  input  io_ren_3,
  input  io_ren_4,
  input  io_ren_5,
  input  io_ren_6,
  input  io_ren_7,
  input  io_ren_8,
  input  io_ren_9,
  input  io_ren_10,
  input  io_ren_11,
  input  io_ren_12,
  input  io_ren_13,
  input  io_ren_14,
  input  [5:0] io_raddr_0,
  input  [5:0] io_raddr_1,
  input  [5:0] io_raddr_2,
  input  [5:0] io_raddr_3,
  input  [5:0] io_raddr_4,
  input  [5:0] io_raddr_5,
  input  [5:0] io_raddr_6,
  input  [5:0] io_raddr_7,
  input  [5:0] io_raddr_8,
  input  [5:0] io_raddr_9,
  input  [5:0] io_raddr_10,
  input  [5:0] io_raddr_11,
  input  [5:0] io_raddr_12,
  input  [5:0] io_raddr_13,
  input  [5:0] io_raddr_14,
  output [49:0] io_rdata_0_startAddr,
  output [49:0] io_rdata_1_startAddr,
  output [49:0] io_rdata_2_startAddr,
  output [49:0] io_rdata_3_startAddr,
  output [49:0] io_rdata_4_startAddr,
  output [49:0] io_rdata_5_startAddr,
  output [49:0] io_rdata_6_startAddr,
  output [49:0] io_rdata_7_startAddr,
  output [49:0] io_rdata_8_startAddr,
  output [49:0] io_rdata_9_startAddr,
  output [49:0] io_rdata_10_startAddr,
  output [49:0] io_rdata_11_startAddr,
  output [49:0] io_rdata_12_startAddr,
  output [49:0] io_rdata_13_startAddr,
  output [49:0] io_rdata_14_startAddr,
  input  io_wen_0,
  input  [5:0] io_waddr_0,
  input  [49:0] io_wdata_0_startAddr
);
  wire [15-1:0][50-1:0] rdata_bus;
  assign io_rdata_0_startAddr = rdata_bus[0];
  assign io_rdata_1_startAddr = rdata_bus[1];
  assign io_rdata_2_startAddr = rdata_bus[2];
  assign io_rdata_3_startAddr = rdata_bus[3];
  assign io_rdata_4_startAddr = rdata_bus[4];
  assign io_rdata_5_startAddr = rdata_bus[5];
  assign io_rdata_6_startAddr = rdata_bus[6];
  assign io_rdata_7_startAddr = rdata_bus[7];
  assign io_rdata_8_startAddr = rdata_bus[8];
  assign io_rdata_9_startAddr = rdata_bus[9];
  assign io_rdata_10_startAddr = rdata_bus[10];
  assign io_rdata_11_startAddr = rdata_bus[11];
  assign io_rdata_12_startAddr = rdata_bus[12];
  assign io_rdata_13_startAddr = rdata_bus[13];
  assign io_rdata_14_startAddr = rdata_bus[14];
  xs_SyncDataModule #(
    .NUM_ENTRIES(64),
    .NUM_READ(15),
    .NUM_WRITE(1),
    .DATA_WIDTH(50),
    .HAS_REN(1),
    .BYPASS_EN(15'b111111111111111),
    // G1 锚点：golden SyncDataModuleTemplate_BackendPC_64entry.sv 里例化了 4 个 DataModule* 子模块 = 应分出的 bank 数
    .G1_NUM_BANKS(4)
  ) u_core (
    .clock(clock),
    .reset(reset),
    .io_ren({io_ren_14, io_ren_13, io_ren_12, io_ren_11, io_ren_10, io_ren_9, io_ren_8, io_ren_7, io_ren_6, io_ren_5, io_ren_4, io_ren_3, io_ren_2, io_ren_1, io_ren_0}),
    .io_raddr({io_raddr_14, io_raddr_13, io_raddr_12, io_raddr_11, io_raddr_10, io_raddr_9, io_raddr_8, io_raddr_7, io_raddr_6, io_raddr_5, io_raddr_4, io_raddr_3, io_raddr_2, io_raddr_1, io_raddr_0}),
    .io_rdata(rdata_bus),
    .io_wen({io_wen_0}),
    .io_waddr({io_waddr_0}),
    .io_wdata({io_wdata_0_startAddr})
  );
endmodule
