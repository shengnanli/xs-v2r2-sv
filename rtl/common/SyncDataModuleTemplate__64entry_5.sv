// SyncDataModuleTemplate__64entry_5 —— 外层同步读存储（分 bank + 输入寄存器复制）
// 形状：64 项 × 57 位，1 读口（带 ren）/ 1 写口；载荷字段：gpaddr(56), isForVSnonLeafPTE(1)
// 用途：GPAMem 的 guest 物理地址暂存（按 FtqPtr 索引，64 = FtqSize）。
// 核体见 rtl/common/xs_SyncDataModule.sv；本文件只做参数化与端口展平。
// 派生方式：按 scripts/gen_dm_wrappers.py 模板手工派生（生成器已陈旧，理由见
// DataModule__16entry_20.sv 文件头；名字已登记进它的 OUTER 表）。
// G1 锚点：golden SyncDataModuleTemplate__64entry_5.sv 里例化了 4 个
// DataModule__16entry_20 子模块 = 应分出的 bank 数。
module SyncDataModuleTemplate__64entry_5(
  input  clock,
  input  reset,
  input  io_ren_0,
  input  [5:0] io_raddr_0,
  output [55:0] io_rdata_0_gpaddr,
  output io_rdata_0_isForVSnonLeafPTE,
  input  io_wen_0,
  input  [5:0] io_waddr_0,
  input  [55:0] io_wdata_0_gpaddr,
  input  io_wdata_0_isForVSnonLeafPTE
);
  wire [1-1:0][57-1:0] rdata_bus;
  assign io_rdata_0_gpaddr = rdata_bus[0][55:0];
  assign io_rdata_0_isForVSnonLeafPTE = rdata_bus[0][56:56];
  xs_SyncDataModule #(
    .NUM_ENTRIES(64),
    .NUM_READ(1),
    .NUM_WRITE(1),
    .DATA_WIDTH(57),
    .HAS_REN(1),
    .BYPASS_EN(1'b1),
    .G1_NUM_BANKS(4)
  ) u_core (
    .clock(clock),
    .reset(reset),
    .io_ren({io_ren_0}),
    .io_raddr({io_raddr_0}),
    .io_rdata(rdata_bus),
    .io_wen({io_wen_0}),
    .io_waddr({io_waddr_0}),
    .io_wdata({{io_wdata_0_isForVSnonLeafPTE, io_wdata_0_gpaddr}})
  );
endmodule
