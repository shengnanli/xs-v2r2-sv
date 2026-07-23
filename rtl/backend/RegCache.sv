// =============================================================================
// xs_regcache_core —— 香山 V2R2 寄存器缓存 RegCache 顶层路由/流水核 (可读重写)
// -----------------------------------------------------------------------------
// 设计源:RegCache.scala。本核负责「半区拆分 + 读流水 + 数据回选 + 替换下标回送」
//   的顶层布线;实际存储/年龄逻辑在 3 类黑盒子模块里(见 regcache_blackbox.svh):
//     RegCacheDataModule  : 16×64bit 数据体,多读多写
//     RegCacheAgeTimer    : 维护各条目相对年龄(上三角配对)
//     RegCacheAgeDetector : 从年龄信息选出最旧条目作为替换目标
//   每类各两份:Int 半区(整数域)与 Mem 半区(访存域),各 16 条目。
//
// 三条主数据流:
//   (1) 读:外部读口 -> 按 addr[4] 拆 Int/Mem -> 子模块读 -> 按 addr[4] 回选数据。
//       地址/使能各打 1 拍(RegEnable/RegNext)对齐子模块的同步读时序。
//   (2) 写:外部写口前 INT_WR 个进 Int、其余进 Mem;写地址不是外部给的,而是
//       AgeDetector 选出的替换下标经 3 拍流水回来(见 (3))。
//   (3) 替换下标回送:AgeDetector.out -> 拼上半区位 -> 输出给唤醒队列,同时打 3 拍
//       后作为写口的写地址。3 拍对齐写数据从执行单元产出到回 RegCache 的延迟。
// =============================================================================
module xs_regcache_core
  import regcache_pkg::*;
(
  input  logic clock,
  input  logic reset,

  // 读口:ren + 5 位 RegCacheIdx -> 同步读出 64 位数据(打拍后有效)。
  input  logic              [N_READ-1:0]            rd_ren,
  input  logic [N_READ-1:0] [IDX_W-1:0]             rd_idx,
  output logic [N_READ-1:0] [DATA_W-1:0]            rd_data,

  // 写口:仅 wen + 64 位数据(写地址来自替换下标流水,非外部)。
  input  logic              [N_WRITE-1:0]           wr_wen,
  input  logic [N_WRITE-1:0][DATA_W-1:0]            wr_data,

  // 回送唤醒队列的替换下标(组合,带半区最高位)。
  output logic [N_WRITE-1:0][IDX_W-1:0]             to_wakeup_idx
);

  // ===========================================================================
  // 1. 读流水:把外部读口拆到两个半区,并打 1 拍对齐子模块同步读。
  //    - 地址:RegEnable(idx, ren) —— 仅在本拍有读请求时更新锁存的地址。
  //    - 使能:int/mem 各 RegNext(ren & 半区匹配),复位为 0(GatedValidRegNext)。
  //    两个半区共享低 4 位条目地址,只是 ren 按 addr[4] 路由到对应半区。
  // ===========================================================================
  logic [N_READ-1:0][IDX_W-1:0] rd_idx_reg;   // 锁存的读地址(带半区位)
  logic [N_READ-1:0]            int_ren_reg;   // 打拍后送 Int 半区的读使能
  logic [N_READ-1:0]            mem_ren_reg;   // 打拍后送 Mem 半区的读使能

  genvar p;
  generate
    for (p = 0; p < N_READ; p++) begin : g_read_pipe
      // 地址锁存:RegEnable,无复位(命中前为 X,由 ren 选通保证被读时已有效)。
      always_ff @(posedge clock) begin
        if (rd_ren[p])
          rd_idx_reg[p] <= rd_idx[p];
      end
      // 读使能打 1 拍,按地址最高位路由到 Int/Mem,复位清 0。
      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          int_ren_reg[p] <= 1'b0;
          mem_ren_reg[p] <= 1'b0;
        end else begin
          int_ren_reg[p] <= rd_ren[p] & ~rd_idx[p][IDX_W-1];
          mem_ren_reg[p] <= rd_ren[p] &  rd_idx[p][IDX_W-1];
        end
      end
    end
  endgenerate

  // 子模块读口连接(两半区共用低 4 位地址,ren 分流)。
  logic [N_READ-1:0]            IntRegCache_rd_ren, MemRegCache_rd_ren;
  logic [N_READ-1:0][ADDR_W-1:0] IntRegCache_rd_addr, MemRegCache_rd_addr;
  logic [N_READ-1:0][DATA_W-1:0] IntRegCache_rd_data, MemRegCache_rd_data;
  logic [INT_SIZE-1:0]          IntRegCache_valid;   // Int 半区 16 条目有效位
  logic [MEM_SIZE-1:0]          MemRegCache_valid;   // Mem 半区 12 条目有效位

  generate
    for (p = 0; p < N_READ; p++) begin : g_read_route
      assign IntRegCache_rd_ren [p] = int_ren_reg[p];
      assign MemRegCache_rd_ren [p] = mem_ren_reg[p];
      assign IntRegCache_rd_addr[p] = rd_idx_reg[p][ADDR_W-1:0];
      assign MemRegCache_rd_addr[p] = rd_idx_reg[p][ADDR_W-1:0];
      // 数据回选:锁存地址的最高位决定取 Mem 还是 Int 半区的读出数据。
      assign rd_data[p] = rd_idx_reg[p][IDX_W-1] ? MemRegCache_rd_data[p]
                                                 : IntRegCache_rd_data[p];
    end
  endgenerate

  // ===========================================================================
  // 2. 替换下标:AgeDetector 选出各写口的替换目标条目下标,拼上半区最高位输出给
  //    唤醒队列;再经 3 拍流水作为写地址(写数据从执行单元回到这里需要 3 拍)。
  // ===========================================================================
  logic [INT_WR-1:0][ADDR_W-1:0] rep_int;  // Int 半区各写口的替换条目下标
  logic [MEM_WR-1:0][ADDR_W-1:0] rep_mem;  // Mem 半区各写口的替换条目下标

  // to_wakeup_idx:前 INT_WR 个属 Int(高位 0),其余属 Mem(高位 1)。
  generate
    for (p = 0; p < N_WRITE; p++) begin : g_wakeup
      if (p < INT_WR) begin : g_wk_int
        assign to_wakeup_idx[p] = {1'b0, rep_int[p]};
      end else begin : g_wk_mem
        assign to_wakeup_idx[p] = {1'b1, rep_mem[p-INT_WR]};
      end
    end
  endgenerate

  // 3 拍延迟链(RegNextN, 无复位):to_wakeup_idx -> ... -> 写口地址。
  //   写地址只取 [ADDR_W-1:0](低 4 位);半区最高位 bit[IDX_W-1] 恒为常数
  //   (Int 口 0 / Mem 口 1)且从不被写口读用 —— 只存 4 位条目下标,不把这个
  //   write-never-read 的常数半区位打进流水寄存器(否则成死位,golden 侧保留全宽
  //   5 位 delayToWakeupQueueRCIdx 使其 bit[4] 成 golden-only cone-dead)。
  logic [N_WRITE-1:0][ADDR_W-1:0] rcidx_delay [RCIDX_DELAY];
  generate
    for (p = 0; p < N_WRITE; p++) begin : g_rcidx_delay
      genvar s;
      for (s = 0; s < RCIDX_DELAY; s++) begin : g_stage
        always_ff @(posedge clock) begin
          rcidx_delay[s][p] <= (s == 0) ? to_wakeup_idx[p][ADDR_W-1:0]
                                        : rcidx_delay[s-1][p];
        end
      end
    end
  endgenerate

  // ===========================================================================
  // 3. 写口路由:前 INT_WR 个写口 -> Int 半区,其余 -> Mem 半区。
  //    写地址 = 替换下标流水末级的低 4 位;写数据/使能直接来自外部。
  // ===========================================================================
  logic [INT_WR-1:0]            IntRegCache_wr_wen;
  logic [INT_WR-1:0][ADDR_W-1:0] IntRegCache_wr_addr;
  logic [INT_WR-1:0][DATA_W-1:0] IntRegCache_wr_data;
  logic [MEM_WR-1:0]            MemRegCache_wr_wen;
  logic [MEM_WR-1:0][ADDR_W-1:0] MemRegCache_wr_addr;
  logic [MEM_WR-1:0][DATA_W-1:0] MemRegCache_wr_data;

  generate
    for (p = 0; p < INT_WR; p++) begin : g_wr_int
      assign IntRegCache_wr_wen [p] = wr_wen[p];
      assign IntRegCache_wr_data[p] = wr_data[p];
      assign IntRegCache_wr_addr[p] = rcidx_delay[RCIDX_DELAY-1][p];
    end
    for (p = 0; p < MEM_WR; p++) begin : g_wr_mem
      assign MemRegCache_wr_wen [p] = wr_wen[INT_WR+p];
      assign MemRegCache_wr_data[p] = wr_data[INT_WR+p];
      assign MemRegCache_wr_addr[p] = rcidx_delay[RCIDX_DELAY-1][INT_WR+p];
    end
  endgenerate

  // ===========================================================================
  // 4. 年龄信息(上三角配对)线 + 黑盒子模块例化(机械连接,见生成片段)。
  //    age_int/age_mem[120] 表达 16 条目两两配对的年龄关系。
  // ===========================================================================
  logic [INT_AGE_PAIRS-1:0] age_int;   // Int 半区 C(16,2)=120 配对年龄
  logic [MEM_AGE_PAIRS-1:0] age_mem;   // Mem 半区 C(12,2)=66 配对年龄

  `include "regcache_blackbox.svh"

endmodule : xs_regcache_core
