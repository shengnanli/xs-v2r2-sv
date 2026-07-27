// =============================================================================
// xs_GPAMem_core —— Guest-Physical-Address 内存(CtrlBlock 内, 异常 gpaddr 回读)。
//
// 对应 golden GPAMem。功能:
//   写: IFU 侧把 {gpaddr, isForVSnonLeafPTE} 按 waddr 写入 64 深 SyncDataModule;
//   读: 异常读地址 valid 时以 ftqPtr 读出该 entry, 并把 ftqOffset 打一拍;
//   输出 gpaddr = rdata.gpaddr + {ftqOffset, 1'b0}(offset*2 字节地址修正)。
//
// SyncDataModule 存储子模块 = golden SyncDataModuleTemplate__64entry_4(已是 305
// signoff 目标, 在 SyncDataModule UT 里独立验证)。本核只重写顶层 glue:
// ftqOffset 寄存器 + 输出地址加法。FM 两侧同源 elaborate 该 golden 子(非黑盒)。
// =============================================================================
module xs_GPAMem_core(
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

  wire [55:0] mem_rdata_gpaddr;

  // ftqOffset 在读有效拍锁存(与读数据同步一拍)。
  reg [3:0] ftqOffset;
  always_ff @(posedge clock) begin
    if (io_exceptionReadAddr_valid)
      ftqOffset <= io_exceptionReadAddr_bits_ftqOffset;
  end

  SyncDataModuleTemplate__64entry_4 mem (
    .clock                        (clock),
    .reset                        (reset),
    .io_ren_0                     (io_exceptionReadAddr_valid),
    .io_raddr_0                   (io_exceptionReadAddr_bits_ftqPtr_value),
    .io_rdata_0_gpaddr            (mem_rdata_gpaddr),
    .io_rdata_0_isForVSnonLeafPTE (io_exceptionReadData_isForVSnonLeafPTE),
    .io_wen_0                     (io_fromIFU_gpaddrMem_wen),
    .io_waddr_0                   (io_fromIFU_gpaddrMem_waddr),
    .io_wdata_0_gpaddr            (io_fromIFU_gpaddrMem_wdata_gpaddr),
    .io_wdata_0_isForVSnonLeafPTE (io_fromIFU_gpaddrMem_wdata_isForVSnonLeafPTE)
  );

  // gpaddr = rdata + ftqOffset*2 (56 位截断)。
  assign io_exceptionReadData_gpaddr =
      56'(mem_rdata_gpaddr + {51'h0, ftqOffset, 1'h0});

endmodule
