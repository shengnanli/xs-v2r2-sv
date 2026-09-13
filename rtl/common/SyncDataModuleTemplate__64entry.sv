// SyncDataModuleTemplate__64entry —— 外层同步读存储（分 bank + 输入寄存器复制）
// 形状：64 项 × 86 位，3 读口 / 1 写口；载荷字段：histPtr_flag, histPtr_value, ssp, sctr…
// 核体见 rtl/common/xs_SyncDataModule.sv；本文件只做参数化与端口展平。
// 自动生成：scripts/gen_dm_wrappers.py（G1 基线驱动）—— 勿手改
module SyncDataModuleTemplate__64entry(
  input  clock,
  input  reset,
  input  io_ren_0,
  input  io_ren_1,
  input  io_ren_2,
  input  [5:0] io_raddr_0,
  input  [5:0] io_raddr_1,
  input  [5:0] io_raddr_2,
  output io_rdata_0_histPtr_flag,
  output [7:0] io_rdata_0_histPtr_value,
  output [3:0] io_rdata_0_ssp,
  output [2:0] io_rdata_0_sctr,
  output io_rdata_0_TOSW_flag,
  output [4:0] io_rdata_0_TOSW_value,
  output io_rdata_0_TOSR_flag,
  output [4:0] io_rdata_0_TOSR_value,
  output io_rdata_0_NOS_flag,
  output [4:0] io_rdata_0_NOS_value,
  output [49:0] io_rdata_0_topAddr,
  output io_rdata_1_histPtr_flag,
  output [7:0] io_rdata_1_histPtr_value,
  output [3:0] io_rdata_1_ssp,
  output [2:0] io_rdata_1_sctr,
  output io_rdata_1_TOSW_flag,
  output [4:0] io_rdata_1_TOSW_value,
  output io_rdata_1_TOSR_flag,
  output [4:0] io_rdata_1_TOSR_value,
  output io_rdata_1_NOS_flag,
  output [4:0] io_rdata_1_NOS_value,
  output io_rdata_1_sc_disagree_0,
  output io_rdata_1_sc_disagree_1,
  output [7:0] io_rdata_2_histPtr_value,
  input  io_wen_0,
  input  [5:0] io_waddr_0,
  input  io_wdata_0_histPtr_flag,
  input  [7:0] io_wdata_0_histPtr_value,
  input  [3:0] io_wdata_0_ssp,
  input  [2:0] io_wdata_0_sctr,
  input  io_wdata_0_TOSW_flag,
  input  [4:0] io_wdata_0_TOSW_value,
  input  io_wdata_0_TOSR_flag,
  input  [4:0] io_wdata_0_TOSR_value,
  input  io_wdata_0_NOS_flag,
  input  [4:0] io_wdata_0_NOS_value,
  input  [49:0] io_wdata_0_topAddr,
  input  io_wdata_0_sc_disagree_0,
  input  io_wdata_0_sc_disagree_1
);
  wire [3-1:0][86-1:0] rdata_bus;
  assign io_rdata_0_histPtr_flag = rdata_bus[0][0:0];
  assign io_rdata_0_histPtr_value = rdata_bus[0][8:1];
  assign io_rdata_0_ssp = rdata_bus[0][12:9];
  assign io_rdata_0_sctr = rdata_bus[0][15:13];
  assign io_rdata_0_TOSW_flag = rdata_bus[0][16:16];
  assign io_rdata_0_TOSW_value = rdata_bus[0][21:17];
  assign io_rdata_0_TOSR_flag = rdata_bus[0][22:22];
  assign io_rdata_0_TOSR_value = rdata_bus[0][27:23];
  assign io_rdata_0_NOS_flag = rdata_bus[0][28:28];
  assign io_rdata_0_NOS_value = rdata_bus[0][33:29];
  assign io_rdata_0_topAddr = rdata_bus[0][83:34];
  assign io_rdata_1_histPtr_flag = rdata_bus[1][0:0];
  assign io_rdata_1_histPtr_value = rdata_bus[1][8:1];
  assign io_rdata_1_ssp = rdata_bus[1][12:9];
  assign io_rdata_1_sctr = rdata_bus[1][15:13];
  assign io_rdata_1_TOSW_flag = rdata_bus[1][16:16];
  assign io_rdata_1_TOSW_value = rdata_bus[1][21:17];
  assign io_rdata_1_TOSR_flag = rdata_bus[1][22:22];
  assign io_rdata_1_TOSR_value = rdata_bus[1][27:23];
  assign io_rdata_1_NOS_flag = rdata_bus[1][28:28];
  assign io_rdata_1_NOS_value = rdata_bus[1][33:29];
  assign io_rdata_1_sc_disagree_0 = rdata_bus[1][84:84];
  assign io_rdata_1_sc_disagree_1 = rdata_bus[1][85:85];
  assign io_rdata_2_histPtr_value = rdata_bus[2][8:1];
  xs_SyncDataModule #(
    .NUM_ENTRIES(64),
    .NUM_READ(3),
    .NUM_WRITE(1),
    .DATA_WIDTH(86),
    .HAS_REN(1),
    .BYPASS_EN(3'b111),
    // G1 锚点：golden SyncDataModuleTemplate__64entry.sv 里例化了 4 个 DataModule* 子模块 = 应分出的 bank 数
    .G1_NUM_BANKS(4)
  ) u_core (
    .clock(clock),
    .reset(reset),
    .io_ren({io_ren_2, io_ren_1, io_ren_0}),
    .io_raddr({io_raddr_2, io_raddr_1, io_raddr_0}),
    .io_rdata(rdata_bus),
    .io_wen({io_wen_0}),
    .io_waddr({io_waddr_0}),
    .io_wdata({{io_wdata_0_sc_disagree_1, io_wdata_0_sc_disagree_0, io_wdata_0_topAddr, io_wdata_0_NOS_value, io_wdata_0_NOS_flag, io_wdata_0_TOSR_value, io_wdata_0_TOSR_flag, io_wdata_0_TOSW_value, io_wdata_0_TOSW_flag, io_wdata_0_sctr, io_wdata_0_ssp, io_wdata_0_histPtr_value, io_wdata_0_histPtr_flag}})
  );
endmodule
