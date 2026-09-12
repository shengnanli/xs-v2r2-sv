// SyncDataModuleTemplate__64entry_2 —— 外层同步读存储（分 bank + 输入寄存器复制）
// 形状：64 项 × 14 位，2 读口 / 1 写口；载荷字段：isCall, isRet, isJalr, brSlots_0_offset…
// 核体见 rtl/common/xs_SyncDataModule.sv；本文件只做参数化与端口展平。
// 自动生成：scripts/gen_dm_wrappers.py（G1 基线驱动）—— 勿手改
module SyncDataModuleTemplate__64entry_2(
  input  clock,
  input  reset,
  input  io_ren_0,
  input  io_ren_1,
  input  [5:0] io_raddr_0,
  input  [5:0] io_raddr_1,
  output io_rdata_0_isCall,
  output io_rdata_0_isRet,
  output io_rdata_0_isJalr,
  output [3:0] io_rdata_0_brSlots_0_offset,
  output io_rdata_0_brSlots_0_valid,
  output [3:0] io_rdata_0_tailSlot_offset,
  output io_rdata_0_tailSlot_sharing,
  output io_rdata_0_tailSlot_valid,
  output io_rdata_1_isJalr,
  output [3:0] io_rdata_1_brSlots_0_offset,
  output io_rdata_1_brSlots_0_valid,
  output [3:0] io_rdata_1_tailSlot_offset,
  output io_rdata_1_tailSlot_sharing,
  output io_rdata_1_tailSlot_valid,
  input  io_wen_0,
  input  [5:0] io_waddr_0,
  input  io_wdata_0_isCall,
  input  io_wdata_0_isRet,
  input  io_wdata_0_isJalr,
  input  [3:0] io_wdata_0_brSlots_0_offset,
  input  io_wdata_0_brSlots_0_valid,
  input  [3:0] io_wdata_0_tailSlot_offset,
  input  io_wdata_0_tailSlot_sharing,
  input  io_wdata_0_tailSlot_valid
);
  wire [2-1:0][14-1:0] rdata_bus;
  assign io_rdata_0_isCall = rdata_bus[0][0:0];
  assign io_rdata_0_isRet = rdata_bus[0][1:1];
  assign io_rdata_0_isJalr = rdata_bus[0][2:2];
  assign io_rdata_0_brSlots_0_offset = rdata_bus[0][6:3];
  assign io_rdata_0_brSlots_0_valid = rdata_bus[0][7:7];
  assign io_rdata_0_tailSlot_offset = rdata_bus[0][11:8];
  assign io_rdata_0_tailSlot_sharing = rdata_bus[0][12:12];
  assign io_rdata_0_tailSlot_valid = rdata_bus[0][13:13];
  assign io_rdata_1_isJalr = rdata_bus[1][2:2];
  assign io_rdata_1_brSlots_0_offset = rdata_bus[1][6:3];
  assign io_rdata_1_brSlots_0_valid = rdata_bus[1][7:7];
  assign io_rdata_1_tailSlot_offset = rdata_bus[1][11:8];
  assign io_rdata_1_tailSlot_sharing = rdata_bus[1][12:12];
  assign io_rdata_1_tailSlot_valid = rdata_bus[1][13:13];
  xs_SyncDataModule #(
    .NUM_ENTRIES(64),
    .NUM_READ(2),
    .NUM_WRITE(1),
    .DATA_WIDTH(14),
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
    .io_wdata({{io_wdata_0_tailSlot_valid, io_wdata_0_tailSlot_sharing, io_wdata_0_tailSlot_offset, io_wdata_0_brSlots_0_valid, io_wdata_0_brSlots_0_offset, io_wdata_0_isJalr, io_wdata_0_isRet, io_wdata_0_isCall}})
  );
endmodule
