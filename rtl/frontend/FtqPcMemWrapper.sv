// =============================================================================
// FtqPcMemWrapper —— FTQ 的 PC 存储包装（多读口 PC 内存）
//
// 在前端的位置：
//   FTQ（Fetch Target Queue）是 BPU（分支预测）与 IFU（取指）之间的队列。
//   每个 FTQ 条目（fetch block）对应一段连续取指，其“PC 元信息”单独存在这块
//   专用内存里——而不是放在 FTQ 主体寄存器堆，目的是把 50 位起始地址等较宽字段
//   从扇出极大的 FTQ 主存储里剥离，单独做成多读口 SyncDataModule（SRAM 风格），
//   省面积、降时序压力。
//
// 这块内存按 ftqPtr（6 位，64 项）索引，存的每条 PC 元信息是：
//   - startAddr      [49:0]  本 fetch block 的起始 PC（取指请求地址）
//   - nextLineAddr   [49:0]  跨 cache line 时下一行的地址（供 IFU 预取/对齐）
//   - fallThruError  [0:0]   fallThrough（顺序结束地址）越界/异常标记
//
// 七个并发读口，各由一个 FTQ 指针驱动，服务前端不同阶段的“按 ftqPtr 查 PC”：
//   port0 ifuPtr        IFU 当前要取的 fetch block
//   port1 ifuPtrPlus1   IFU 下一个 block（流水提前取 PC）
//   port2 ifuPtrPlus2   IFU 再下一个 block（仅需 startAddr）
//   port3 pfPtr         指令预取（prefetch）当前指针
//   port4 pfPtrPlus1    预取下一指针
//   port5 commPtrPlus1  提交指针 +1（仅需 startAddr）
//   port6 commPtr       提交指针（commit，仅需 startAddr，做重定向/异常 PC 还原）
// 注意 port5/port6 与“commPtr / commPtrPlus1”的端口顺序：见下方实例化里的
// raddr 映射——commPtrPlus1 接 raddr5、commPtr 接 raddr6（与 golden 一致）。
//
// 写口只有一个（enq）：BPU 产生新预测、FTQ 入队（或重定向回填）时，把该 ftqPtr
// 对应条目的 PC 元信息写进来。读延迟 1 拍（地址寄存一拍，bank 内组合读），底层
// 复用 xs_SyncDataModule（分 bank、多读口、可写旁路），故同地址“本拍写、下拍读”
// 能读到新值。
//
// 本文件分两层（遵循工程可读重写规范）：
//   xs_FtqPcMemWrapper —— 可读核：用 struct 表示一条 PC 元信息，端口按 FTQ 指针
//                          命名，读出按读口聚合，便于阅读理解微架构。
//   FtqPcMemWrapper    —— golden 同名包装：把可读核的 struct/数组端口拆成 firtool
//                          生成的扁平端口，供 FM 等价比对与系统级替换对接。
// =============================================================================

package ftq_pc_pkg;
  // PC 元信息的物理参数（与 FTQ / VAddrBits 对齐）
  localparam int unsigned FTQ_PC_ADDR_W = 50;  // startAddr / nextLineAddr 位宽
  localparam int unsigned FTQ_SIZE      = 64;  // FTQ 条目数（ftqPtr 索引空间）
  localparam int unsigned FTQ_PTR_W     = 6;   // ftqPtr 位宽 = clog2(FTQ_SIZE)
  localparam int unsigned NUM_READ      = 7;   // 并发读口数（见模块头端口表）

  // 一条 FTQ PC 元信息条目
  typedef struct packed {
    logic                      fallThruError;  // [100]   fallThrough 越界标记
    logic [FTQ_PC_ADDR_W-1:0]  nextLineAddr;   // [99:50] 跨行下一行地址
    logic [FTQ_PC_ADDR_W-1:0]  startAddr;      // [49:0]  起始 PC
  } ftq_pc_entry_t;

  localparam int unsigned FTQ_PC_ENTRY_W = $bits(ftq_pc_entry_t);  // = 101
endpackage

// -----------------------------------------------------------------------------
// 可读核：多读口 PC 内存，端口按 FTQ 指针命名
// -----------------------------------------------------------------------------
module xs_FtqPcMemWrapper
  import ftq_pc_pkg::*;
(
  input  logic clock,
  input  logic reset,

  // 七个读地址：各前端阶段的 ftqPtr（读延迟 1 拍）
  input  logic [FTQ_PTR_W-1:0] ifuPtr,
  input  logic [FTQ_PTR_W-1:0] ifuPtrPlus1,
  input  logic [FTQ_PTR_W-1:0] ifuPtrPlus2,
  input  logic [FTQ_PTR_W-1:0] pfPtr,
  input  logic [FTQ_PTR_W-1:0] pfPtrPlus1,
  input  logic [FTQ_PTR_W-1:0] commPtr,
  input  logic [FTQ_PTR_W-1:0] commPtrPlus1,

  // 七个读出条目（完整 struct；上层只挑需要的字段用）
  output ftq_pc_entry_t        ifuPtr_rdata,
  output ftq_pc_entry_t        ifuPtrPlus1_rdata,
  output ftq_pc_entry_t        ifuPtrPlus2_rdata,
  output ftq_pc_entry_t        pfPtr_rdata,
  output ftq_pc_entry_t        pfPtrPlus1_rdata,
  output ftq_pc_entry_t        commPtr_rdata,
  output ftq_pc_entry_t        commPtrPlus1_rdata,

  // 单写口（FTQ 入队 / 回填）
  input  logic                 wen,
  input  logic [FTQ_PTR_W-1:0] waddr,
  input  ftq_pc_entry_t        wdata
);

  // 七个读口聚到数组，喂给底层 SyncDataModule。
  // 读口下标与 FTQ 指针的对应关系（与 golden raddr 映射严格一致）：
  //   0:ifuPtr 1:ifuPtrPlus1 2:ifuPtrPlus2 3:pfPtr 4:pfPtrPlus1
  //   5:commPtrPlus1 6:commPtr   ← 注意 5/6 是 Plus1 在前
  logic [NUM_READ-1:0][FTQ_PTR_W-1:0]      raddr;
  logic [NUM_READ-1:0][FTQ_PC_ENTRY_W-1:0] rdata;

  assign raddr = '{
    6: commPtr,
    5: commPtrPlus1,
    4: pfPtrPlus1,
    3: pfPtr,
    2: ifuPtrPlus2,
    1: ifuPtrPlus1,
    0: ifuPtr
  };

  assign ifuPtr_rdata       = ftq_pc_entry_t'(rdata[0]);
  assign ifuPtrPlus1_rdata  = ftq_pc_entry_t'(rdata[1]);
  assign ifuPtrPlus2_rdata  = ftq_pc_entry_t'(rdata[2]);
  assign pfPtr_rdata        = ftq_pc_entry_t'(rdata[3]);
  assign pfPtrPlus1_rdata   = ftq_pc_entry_t'(rdata[4]);
  assign commPtrPlus1_rdata = ftq_pc_entry_t'(rdata[5]);
  assign commPtr_rdata      = ftq_pc_entry_t'(rdata[6]);

  // 底层多读口同步内存：
  //   HAS_REN=0 —— FTQ PC 内存读地址恒采样（无读使能门控），与 golden 一致；
  //   BYPASS_EN 全 1 —— 各读口都启用写旁路（同地址先写后读读到新值）。
  xs_SyncDataModule #(
    .NUM_ENTRIES (FTQ_SIZE),
    .NUM_READ    (NUM_READ),
    .NUM_WRITE   (1),
    .DATA_WIDTH  (FTQ_PC_ENTRY_W),
    .HAS_REN     (1'b0),
    .BYPASS_EN   ({NUM_READ{1'b1}})
  ) u_mem (
    .clock    (clock),
    .reset    (reset),
    .io_ren   ({NUM_READ{1'b1}}),
    .io_raddr (raddr),
    .io_rdata (rdata),
    .io_wen   (wen),
    .io_waddr (waddr),
    .io_wdata (wdata)
  );

endmodule

// -----------------------------------------------------------------------------
// golden 同名包装：扁平端口 <-> 可读核（机械适配层，供 FM / 系统级替换）
//   - 写数据按 {fallThruError, nextLineAddr, startAddr} 拼成 struct；
//   - 各读口按 golden 实际暴露的字段子集拆出（port2/5/6 仅 startAddr）。
// -----------------------------------------------------------------------------
module FtqPcMemWrapper
  import ftq_pc_pkg::*;
(
  input         clock,
  input         reset,
  input  [5:0]  io_ifuPtr_w_value,
  input  [5:0]  io_ifuPtrPlus1_w_value,
  input  [5:0]  io_ifuPtrPlus2_w_value,
  input  [5:0]  io_pfPtr_w_value,
  input  [5:0]  io_pfPtrPlus1_w_value,
  input  [5:0]  io_commPtr_w_value,
  input  [5:0]  io_commPtrPlus1_w_value,
  output [49:0] io_ifuPtr_rdata_startAddr,
  output [49:0] io_ifuPtr_rdata_nextLineAddr,
  output        io_ifuPtr_rdata_fallThruError,
  output [49:0] io_ifuPtrPlus1_rdata_startAddr,
  output [49:0] io_ifuPtrPlus1_rdata_nextLineAddr,
  output        io_ifuPtrPlus1_rdata_fallThruError,
  output [49:0] io_ifuPtrPlus2_rdata_startAddr,
  output [49:0] io_pfPtr_rdata_startAddr,
  output [49:0] io_pfPtr_rdata_nextLineAddr,
  output [49:0] io_pfPtrPlus1_rdata_startAddr,
  output [49:0] io_pfPtrPlus1_rdata_nextLineAddr,
  output [49:0] io_commPtr_rdata_startAddr,
  output [49:0] io_commPtrPlus1_rdata_startAddr,
  input         io_wen,
  input  [5:0]  io_waddr,
  input  [49:0] io_wdata_startAddr,
  input  [49:0] io_wdata_nextLineAddr,
  input         io_wdata_fallThruError
);

  ftq_pc_entry_t ifuPtr_rd, ifuPtrPlus1_rd, ifuPtrPlus2_rd;
  ftq_pc_entry_t pfPtr_rd, pfPtrPlus1_rd, commPtr_rd, commPtrPlus1_rd;

  ftq_pc_entry_t wdata;
  assign wdata = '{
    fallThruError: io_wdata_fallThruError,
    nextLineAddr:  io_wdata_nextLineAddr,
    startAddr:     io_wdata_startAddr
  };

  xs_FtqPcMemWrapper u_core (
    .clock              (clock),
    .reset              (reset),
    .ifuPtr             (io_ifuPtr_w_value),
    .ifuPtrPlus1        (io_ifuPtrPlus1_w_value),
    .ifuPtrPlus2        (io_ifuPtrPlus2_w_value),
    .pfPtr              (io_pfPtr_w_value),
    .pfPtrPlus1         (io_pfPtrPlus1_w_value),
    .commPtr            (io_commPtr_w_value),
    .commPtrPlus1       (io_commPtrPlus1_w_value),
    .ifuPtr_rdata       (ifuPtr_rd),
    .ifuPtrPlus1_rdata  (ifuPtrPlus1_rd),
    .ifuPtrPlus2_rdata  (ifuPtrPlus2_rd),
    .pfPtr_rdata        (pfPtr_rd),
    .pfPtrPlus1_rdata   (pfPtrPlus1_rd),
    .commPtr_rdata      (commPtr_rd),
    .commPtrPlus1_rdata (commPtrPlus1_rd),
    .wen                (io_wen),
    .waddr              (io_waddr),
    .wdata              (wdata)
  );

  // port0 ifuPtr：全字段
  assign io_ifuPtr_rdata_startAddr        = ifuPtr_rd.startAddr;
  assign io_ifuPtr_rdata_nextLineAddr     = ifuPtr_rd.nextLineAddr;
  assign io_ifuPtr_rdata_fallThruError    = ifuPtr_rd.fallThruError;
  // port1 ifuPtrPlus1：全字段
  assign io_ifuPtrPlus1_rdata_startAddr     = ifuPtrPlus1_rd.startAddr;
  assign io_ifuPtrPlus1_rdata_nextLineAddr  = ifuPtrPlus1_rd.nextLineAddr;
  assign io_ifuPtrPlus1_rdata_fallThruError = ifuPtrPlus1_rd.fallThruError;
  // port2 ifuPtrPlus2：仅 startAddr
  assign io_ifuPtrPlus2_rdata_startAddr   = ifuPtrPlus2_rd.startAddr;
  // port3 pfPtr：startAddr + nextLineAddr
  assign io_pfPtr_rdata_startAddr         = pfPtr_rd.startAddr;
  assign io_pfPtr_rdata_nextLineAddr      = pfPtr_rd.nextLineAddr;
  // port4 pfPtrPlus1：startAddr + nextLineAddr
  assign io_pfPtrPlus1_rdata_startAddr    = pfPtrPlus1_rd.startAddr;
  assign io_pfPtrPlus1_rdata_nextLineAddr = pfPtrPlus1_rd.nextLineAddr;
  // port5 commPtrPlus1 / port6 commPtr：仅 startAddr
  assign io_commPtrPlus1_rdata_startAddr  = commPtrPlus1_rd.startAddr;
  assign io_commPtr_rdata_startAddr       = commPtr_rd.startAddr;

endmodule
