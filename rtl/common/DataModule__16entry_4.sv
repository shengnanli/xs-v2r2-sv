// DataModule__16entry_4 —— 内层单 bank 存储
// 形状：16 项 × 576 位，1 读口 / 1 写口；载荷字段：meta, ftb_entry_isCall, ftb_entry_isRet, ftb_entry_isJalr…
// 核体见 rtl/common/xs_DataModule.sv；本文件只做参数化与端口展平。
// 自动生成：scripts/gen_dm_wrappers.py（G1 基线驱动）—— 勿手改
module DataModule__16entry_4(
  input  clock,
  input  [3:0] io_raddr_0,
  output [515:0] io_rdata_0_meta,
  output io_rdata_0_ftb_entry_isCall,
  output io_rdata_0_ftb_entry_isRet,
  output io_rdata_0_ftb_entry_isJalr,
  output io_rdata_0_ftb_entry_valid,
  output [3:0] io_rdata_0_ftb_entry_brSlots_0_offset,
  output io_rdata_0_ftb_entry_brSlots_0_sharing,
  output io_rdata_0_ftb_entry_brSlots_0_valid,
  output [11:0] io_rdata_0_ftb_entry_brSlots_0_lower,
  output [1:0] io_rdata_0_ftb_entry_brSlots_0_tarStat,
  output [3:0] io_rdata_0_ftb_entry_tailSlot_offset,
  output io_rdata_0_ftb_entry_tailSlot_sharing,
  output io_rdata_0_ftb_entry_tailSlot_valid,
  output [19:0] io_rdata_0_ftb_entry_tailSlot_lower,
  output [1:0] io_rdata_0_ftb_entry_tailSlot_tarStat,
  output [3:0] io_rdata_0_ftb_entry_pftAddr,
  output io_rdata_0_ftb_entry_carry,
  output io_rdata_0_ftb_entry_last_may_be_rvi_call,
  output io_rdata_0_ftb_entry_strong_bias_0,
  output io_rdata_0_ftb_entry_strong_bias_1,
  input  io_wen_0,
  input  [3:0] io_waddr_0,
  input  [515:0] io_wdata_0_meta,
  input  io_wdata_0_ftb_entry_isCall,
  input  io_wdata_0_ftb_entry_isRet,
  input  io_wdata_0_ftb_entry_isJalr,
  input  io_wdata_0_ftb_entry_valid,
  input  [3:0] io_wdata_0_ftb_entry_brSlots_0_offset,
  input  io_wdata_0_ftb_entry_brSlots_0_sharing,
  input  io_wdata_0_ftb_entry_brSlots_0_valid,
  input  [11:0] io_wdata_0_ftb_entry_brSlots_0_lower,
  input  [1:0] io_wdata_0_ftb_entry_brSlots_0_tarStat,
  input  [3:0] io_wdata_0_ftb_entry_tailSlot_offset,
  input  io_wdata_0_ftb_entry_tailSlot_sharing,
  input  io_wdata_0_ftb_entry_tailSlot_valid,
  input  [19:0] io_wdata_0_ftb_entry_tailSlot_lower,
  input  [1:0] io_wdata_0_ftb_entry_tailSlot_tarStat,
  input  [3:0] io_wdata_0_ftb_entry_pftAddr,
  input  io_wdata_0_ftb_entry_carry,
  input  io_wdata_0_ftb_entry_last_may_be_rvi_call,
  input  io_wdata_0_ftb_entry_strong_bias_0,
  input  io_wdata_0_ftb_entry_strong_bias_1
);
  wire [1-1:0][576-1:0] rdata_bus;
  assign io_rdata_0_meta = rdata_bus[0][515:0];
  assign io_rdata_0_ftb_entry_isCall = rdata_bus[0][516:516];
  assign io_rdata_0_ftb_entry_isRet = rdata_bus[0][517:517];
  assign io_rdata_0_ftb_entry_isJalr = rdata_bus[0][518:518];
  assign io_rdata_0_ftb_entry_valid = rdata_bus[0][519:519];
  assign io_rdata_0_ftb_entry_brSlots_0_offset = rdata_bus[0][523:520];
  assign io_rdata_0_ftb_entry_brSlots_0_sharing = rdata_bus[0][524:524];
  assign io_rdata_0_ftb_entry_brSlots_0_valid = rdata_bus[0][525:525];
  assign io_rdata_0_ftb_entry_brSlots_0_lower = rdata_bus[0][537:526];
  assign io_rdata_0_ftb_entry_brSlots_0_tarStat = rdata_bus[0][539:538];
  assign io_rdata_0_ftb_entry_tailSlot_offset = rdata_bus[0][543:540];
  assign io_rdata_0_ftb_entry_tailSlot_sharing = rdata_bus[0][544:544];
  assign io_rdata_0_ftb_entry_tailSlot_valid = rdata_bus[0][545:545];
  assign io_rdata_0_ftb_entry_tailSlot_lower = rdata_bus[0][565:546];
  assign io_rdata_0_ftb_entry_tailSlot_tarStat = rdata_bus[0][567:566];
  assign io_rdata_0_ftb_entry_pftAddr = rdata_bus[0][571:568];
  assign io_rdata_0_ftb_entry_carry = rdata_bus[0][572:572];
  assign io_rdata_0_ftb_entry_last_may_be_rvi_call = rdata_bus[0][573:573];
  assign io_rdata_0_ftb_entry_strong_bias_0 = rdata_bus[0][574:574];
  assign io_rdata_0_ftb_entry_strong_bias_1 = rdata_bus[0][575:575];
  xs_DataModule #(
    .NUM_ENTRIES(16),
    .NUM_READ(1),
    .NUM_WRITE(1),
    .DATA_WIDTH(576),
    .BYPASS_EN(1'b1)
  ) u_core (
    .clock(clock),
    .io_raddr({io_raddr_0}),
    .io_rdata(rdata_bus),
    .io_wen({io_wen_0}),
    .io_waddr({io_waddr_0}),
    .io_wdata({{io_wdata_0_ftb_entry_strong_bias_1, io_wdata_0_ftb_entry_strong_bias_0, io_wdata_0_ftb_entry_last_may_be_rvi_call, io_wdata_0_ftb_entry_carry, io_wdata_0_ftb_entry_pftAddr, io_wdata_0_ftb_entry_tailSlot_tarStat, io_wdata_0_ftb_entry_tailSlot_lower, io_wdata_0_ftb_entry_tailSlot_valid, io_wdata_0_ftb_entry_tailSlot_sharing, io_wdata_0_ftb_entry_tailSlot_offset, io_wdata_0_ftb_entry_brSlots_0_tarStat, io_wdata_0_ftb_entry_brSlots_0_lower, io_wdata_0_ftb_entry_brSlots_0_valid, io_wdata_0_ftb_entry_brSlots_0_sharing, io_wdata_0_ftb_entry_brSlots_0_offset, io_wdata_0_ftb_entry_valid, io_wdata_0_ftb_entry_isJalr, io_wdata_0_ftb_entry_isRet, io_wdata_0_ftb_entry_isCall, io_wdata_0_meta}})
  );
endmodule
