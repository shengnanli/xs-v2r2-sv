// =============================================================================
// GPAMem.sv —— Guest 物理地址暂存（异常上报时按 FTQ 位置取回 gpaddr）
// -----------------------------------------------------------------------------
// 设计源: XiangShan src/main/scala/xiangshan/backend/GPAMem.scala
// golden 对照: G1-canonical/golden-rtl/GPAMem.sv（140 行）
// 层次位置: SimTop…backend.inner.ctrlBlock.gpaMem
//
// ★ 它是什么 ★
// 虚拟化下取指发生 guest 页错误时，IFU 把该取指块的 guest 物理地址（gpaddr，
// 56 位 = PAddrBitsMax）和「是否是 VS 阶段非叶 PTE 引起」两项写进一张按 FtqPtr
// 索引的 64 项表（FtqSize=64）。Rob 提交异常时用 {ftqPtr, ftqOffset} 读回：
//   gpaddr_out = 表项 gpaddr + (ftqOffset << 1)     （instOffsetBits = 1）
// 即取指块基址加上指令在块内的字节偏移；isForVSnonLeafPTE 原样透传。
//
// ★ 时序 ★
//   表是 SyncDataModuleTemplate（读地址打一拍，bank 内组合读）；ftqOffset 也在
//   exceptionReadAddr.valid 时 RegEnable 一拍，两者对齐后相加。所以读结果在
//   valid 的下一拍出现，之后一直保持到下一次 valid（地址寄存器只在 valid 时更新）。
//
// ★ golden 事实 ★
//   - ftqOffset 寄存器**无复位**（RegEnable 无 init）；
//   - 加法是 56 位截断（golden 写作 56'(base + {51'h0, ftqOffset, 1'h0})）；
//   - 表 SyncDataModuleTemplate__64entry_5 本身就是 306 目标之一，可读件在
//     rtl/common/（本模块只例化它，不重写它）。
// =============================================================================

module xs_GPAMem_core #(
  parameter int unsigned FTQ_IDX_W  = 6,   // log2(FtqSize=64)
  parameter int unsigned FTQ_OFF_W  = 4,   // log2(PredictWidth=16)
  parameter int unsigned GPADDR_W   = 56   // PAddrBitsMax
)(
  input  logic                  clock,
  input  logic                  reset,
  // IFU 写口
  input  logic                  ifu_wen,
  input  logic [FTQ_IDX_W-1:0]  ifu_waddr,
  input  logic [GPADDR_W-1:0]   ifu_wdata_gpaddr,
  input  logic                  ifu_wdata_isForVSnonLeafPTE,
  // 异常读口
  input  logic                  rd_valid,
  input  logic [FTQ_IDX_W-1:0]  rd_ftqPtr,
  input  logic [FTQ_OFF_W-1:0]  rd_ftqOffset,
  output logic [GPADDR_W-1:0]   rd_gpaddr,
  output logic                  rd_isForVSnonLeafPTE
);

  // 与表的读地址同拍锁存的块内偏移（无复位，照 golden）
  logic [FTQ_OFF_W-1:0] ftqOffset;
  always_ff @(posedge clock)
    if (rd_valid) ftqOffset <= rd_ftqOffset;

  logic [GPADDR_W-1:0] mem_gpaddr;
  SyncDataModuleTemplate__64entry_5 mem (
    .clock                        (clock),
    .reset                        (reset),
    .io_ren_0                     (rd_valid),
    .io_raddr_0                   (rd_ftqPtr),
    .io_rdata_0_gpaddr            (mem_gpaddr),
    .io_rdata_0_isForVSnonLeafPTE (rd_isForVSnonLeafPTE),
    .io_wen_0                     (ifu_wen),
    .io_waddr_0                   (ifu_waddr),
    .io_wdata_0_gpaddr            (ifu_wdata_gpaddr),
    .io_wdata_0_isForVSnonLeafPTE (ifu_wdata_isForVSnonLeafPTE)
  );

  // 块基址 + 指令字节偏移（ftqOffset 以 2 字节为单位），56 位截断
  assign rd_gpaddr = mem_gpaddr + GPADDR_W'({ftqOffset, 1'b0});

endmodule : xs_GPAMem_core

module GPAMem(
  input         clock,
  input         reset,
  input         io_fromIFU_gpaddrMem_wen,
  input  [5:0]  io_fromIFU_gpaddrMem_waddr,
  input  [55:0] io_fromIFU_gpaddrMem_wdata_gpaddr,
  input         io_fromIFU_gpaddrMem_wdata_isForVSnonLeafPTE,
  input         io_exceptionReadAddr_valid,
  input  [5:0]  io_exceptionReadAddr_bits_ftqPtr_value,
  input  [3:0]  io_exceptionReadAddr_bits_ftqOffset,
  output [55:0] io_exceptionReadData_gpaddr,
  output        io_exceptionReadData_isForVSnonLeafPTE
);
  xs_GPAMem_core u_core (
    .clock                       (clock),
    .reset                       (reset),
    .ifu_wen                     (io_fromIFU_gpaddrMem_wen),
    .ifu_waddr                   (io_fromIFU_gpaddrMem_waddr),
    .ifu_wdata_gpaddr            (io_fromIFU_gpaddrMem_wdata_gpaddr),
    .ifu_wdata_isForVSnonLeafPTE (io_fromIFU_gpaddrMem_wdata_isForVSnonLeafPTE),
    .rd_valid                    (io_exceptionReadAddr_valid),
    .rd_ftqPtr                   (io_exceptionReadAddr_bits_ftqPtr_value),
    .rd_ftqOffset                (io_exceptionReadAddr_bits_ftqOffset),
    .rd_gpaddr                   (io_exceptionReadData_gpaddr),
    .rd_isForVSnonLeafPTE        (io_exceptionReadData_isForVSnonLeafPTE)
  );
endmodule
