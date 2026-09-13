// SyncDataModuleTemplate__1024entry —— 外层同步读存储（分 bank + 输入寄存器复制）
// 形状：1024 项 × 1 位，2 读口 / 2 写口；载荷字段：<flat>
// 核体见 rtl/common/xs_SyncDataModule.sv；本文件只做参数化与端口展平。
// 自动生成：scripts/gen_dm_wrappers.py（G1 基线驱动）—— 勿手改
module SyncDataModuleTemplate__1024entry(
  input  clock,
  input  reset,
  input  io_ren_0,
  input  io_ren_1,
  input  [9:0] io_raddr_0,
  input  [9:0] io_raddr_1,
  output io_rdata_0,
  output io_rdata_1,
  input  io_wen_0,
  input  io_wen_1,
  input  [9:0] io_waddr_0,
  input  [9:0] io_waddr_1,
  input  io_wdata_0,
  input  io_wdata_1
);
  wire [2-1:0][1-1:0] rdata_bus;
  assign io_rdata_0 = rdata_bus[0];
  assign io_rdata_1 = rdata_bus[1];
  xs_SyncDataModule #(
    .NUM_ENTRIES(1024),
    .NUM_READ(2),
    .NUM_WRITE(2),
    .DATA_WIDTH(1),
    .HAS_REN(1),
    .BYPASS_EN(2'b11),
    // G1 锚点：golden SyncDataModuleTemplate__1024entry.sv 里例化了 16 个 DataModule* 子模块 = 应分出的 bank 数
    .G1_NUM_BANKS(16)
  ) u_core (
    .clock(clock),
    .reset(reset),
    .io_ren({io_ren_1, io_ren_0}),
    .io_raddr({io_raddr_1, io_raddr_0}),
    .io_rdata(rdata_bus),
    .io_wen({io_wen_1, io_wen_0}),
    .io_waddr({io_waddr_1, io_waddr_0}),
    .io_wdata({io_wdata_1, io_wdata_0})
  );
endmodule
