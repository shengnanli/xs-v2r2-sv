// DataModule__16entry_20 —— 内层单 bank 存储
// 形状：16 项 × 57 位，1 读口 / 1 写口；载荷字段：gpaddr(56), isForVSnonLeafPTE(1)
// 用途：GPAMem（guest 物理地址暂存）的 SyncDataModuleTemplate__64entry_5 的 4 个 bank 之一。
// 核体见 rtl/common/xs_DataModule.sv；本文件只做参数化与端口展平。
// 派生方式：按 scripts/gen_dm_wrappers.py 的薄文件模板手工派生（该生成器已
// 陈旧：产物缺 G1_NUM_BANKS 锚点、且 SPECIAL 分支依赖一个不存在的 scratchpad 文件，
// 整体重跑会覆盖家族里已手修的三个外层文件，故不重跑；名字已登记进它的 INNER 表）。
// 写旁路：golden 里有 `read_by_0 = io_wen_0 & io_waddr_0 == io_raddr_0` ⇒ 读口 0 带旁路。
module DataModule__16entry_20(
  input  clock,
  input  [3:0] io_raddr_0,
  output [55:0] io_rdata_0_gpaddr,
  output io_rdata_0_isForVSnonLeafPTE,
  input  io_wen_0,
  input  [3:0] io_waddr_0,
  input  [55:0] io_wdata_0_gpaddr,
  input  io_wdata_0_isForVSnonLeafPTE
);
  wire [1-1:0][57-1:0] rdata_bus;
  assign io_rdata_0_gpaddr = rdata_bus[0][55:0];
  assign io_rdata_0_isForVSnonLeafPTE = rdata_bus[0][56:56];
  xs_DataModule #(
    .NUM_ENTRIES(16),
    .NUM_READ(1),
    .NUM_WRITE(1),
    .DATA_WIDTH(57),
    .BYPASS_EN(1'b1)
  ) u_core (
    .clock(clock),
    .io_raddr({io_raddr_0}),
    .io_rdata(rdata_bus),
    .io_wen({io_wen_0}),
    .io_waddr({io_waddr_0}),
    .io_wdata({{io_wdata_0_isForVSnonLeafPTE, io_wdata_0_gpaddr}})
  );
endmodule
