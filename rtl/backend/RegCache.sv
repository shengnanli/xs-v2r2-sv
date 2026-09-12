// =============================================================================
//  RegCache.sv —— 后端寄存器缓存（PRF 读口的旁路小缓存）
// -----------------------------------------------------------------------------
//  位置：Backend / DataPath 里，挂在物理寄存器堆(PRF)旁边。超标量每拍要为多条指令
//  读多个源操作数，PRF 读口是面积与时序的大头；香山观察到"刚写回的值很快又被后续
//  指令读用"，于是加一个小容量多读口的 RegCache 缓存最近写回值，命中就不占 PRF 读口。
//
//  核心机制（三条数据流，都在 xs_RegCache_core 里）：
//    读   ：23 个读口，RegCacheIdx 的最高位选半区(Int/Mem)、低 4 位选条目；地址与
//           使能各打 1 拍对齐子模块的同步读，读回后按锁存的半区位回选数据。
//    写   ：7 个写口(Int 4 / Mem 3)，写地址不是外部给的，而是"年龄替换"选出的条目。
//    替换 ：AgeTimer 记录条目两两相对新旧，AgeDetector 挑最旧条目当替换目标；该下标
//           组合输出给唤醒队列，同时打 3 拍后作为写口地址（对齐写数据回到本级的延迟）。
//
//  存储体/年龄逻辑在 6 个黑盒子模块里（Int/Mem 各一套）：
//    RegCacheDataModule(_1) / RegCacheAgeTimer(_1) / RegCacheAgeDetector(_1)
//  本文件只重写"顶层路由 + 流水 + 回选"。
//
//  G0→G1：golden RegCache.sv 在 422 个 commit 里逐字节未动，本文件是上一轮可读核的
//  原样继承，只按单文件规范把 package / 核 / golden 同名层并进一个文件。
// =============================================================================

package regcache_pkg;

  // ---- 规模参数(由 BackendParams 推导,这里取昆明湖实例值)----
  //   注意 Int/Mem 两半区条目数不同:整数域 16,访存域 12(访存 RC 命中需求较少)。
  localparam int INT_SIZE  = 16;  // Int 半区条目数(IntRegCacheSize)
  localparam int MEM_SIZE  = 12;  // Mem 半区条目数(MemRegCacheSize)
  localparam int ADDR_W    = 4;   // 半区内条目地址位宽(两半区都用 4 位,Mem 高位不用满)
  localparam int IDX_W     = 5;   // 完整 RegCacheIdx:最高位选半区 + 低 4 位选条目
  localparam int DATA_W    = 64;  // 寄存器数据位宽(rfDataWidth)

  localparam int N_READ    = 23;  // 读口数(IntExu + MemExu 的 RC 读口之和)
  localparam int INT_WR    = 4;   // Int 半区写口数(getIntExuRCWriteSize)
  localparam int MEM_WR    = 3;   // Mem 半区写口数(getMemExuRCWriteSize)
  localparam int N_WRITE   = INT_WR + MEM_WR;  // 总写口/唤醒回送数 = 7

  // 读流水深度:RegEnable(addr)/GatedValidRegNext(ren) 各打 1 拍 -> 子模块。
  localparam int READ_DELAY  = 1;
  // 替换下标回送写口的流水深度:RegNextN(toWakeupRCIdx, 3)。
  localparam int RCIDX_DELAY = 3;

  // AgeTimer 输出的年龄信息:N 条目两两配对的上三角矩阵 C(N,2) 条。
  localparam int INT_AGE_PAIRS = (INT_SIZE * (INT_SIZE - 1)) / 2;  // = 120
  localparam int MEM_AGE_PAIRS = (MEM_SIZE * (MEM_SIZE - 1)) / 2;  // = 66

endpackage : regcache_pkg

// =============================================================================
//  可读核：顶层路由 / 读写流水 / 替换下标回送
// =============================================================================
module xs_RegCache_core
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

  // ---- 黑盒子模块例化（两半区各 3 个；原为 regcache_blackbox.svh，
  //      单文件规范下就地展开）----
  RegCacheDataModule IntRegCache (
    .clock(clock), .reset(reset),
    .io_readPorts_0_ren (IntRegCache_rd_ren[0]),
    .io_readPorts_0_addr(IntRegCache_rd_addr[0]),
    .io_readPorts_0_data(IntRegCache_rd_data[0]),
    .io_readPorts_1_ren (IntRegCache_rd_ren[1]),
    .io_readPorts_1_addr(IntRegCache_rd_addr[1]),
    .io_readPorts_1_data(IntRegCache_rd_data[1]),
    .io_readPorts_2_ren (IntRegCache_rd_ren[2]),
    .io_readPorts_2_addr(IntRegCache_rd_addr[2]),
    .io_readPorts_2_data(IntRegCache_rd_data[2]),
    .io_readPorts_3_ren (IntRegCache_rd_ren[3]),
    .io_readPorts_3_addr(IntRegCache_rd_addr[3]),
    .io_readPorts_3_data(IntRegCache_rd_data[3]),
    .io_readPorts_4_ren (IntRegCache_rd_ren[4]),
    .io_readPorts_4_addr(IntRegCache_rd_addr[4]),
    .io_readPorts_4_data(IntRegCache_rd_data[4]),
    .io_readPorts_5_ren (IntRegCache_rd_ren[5]),
    .io_readPorts_5_addr(IntRegCache_rd_addr[5]),
    .io_readPorts_5_data(IntRegCache_rd_data[5]),
    .io_readPorts_6_ren (IntRegCache_rd_ren[6]),
    .io_readPorts_6_addr(IntRegCache_rd_addr[6]),
    .io_readPorts_6_data(IntRegCache_rd_data[6]),
    .io_readPorts_7_ren (IntRegCache_rd_ren[7]),
    .io_readPorts_7_addr(IntRegCache_rd_addr[7]),
    .io_readPorts_7_data(IntRegCache_rd_data[7]),
    .io_readPorts_8_ren (IntRegCache_rd_ren[8]),
    .io_readPorts_8_addr(IntRegCache_rd_addr[8]),
    .io_readPorts_8_data(IntRegCache_rd_data[8]),
    .io_readPorts_9_ren (IntRegCache_rd_ren[9]),
    .io_readPorts_9_addr(IntRegCache_rd_addr[9]),
    .io_readPorts_9_data(IntRegCache_rd_data[9]),
    .io_readPorts_10_ren (IntRegCache_rd_ren[10]),
    .io_readPorts_10_addr(IntRegCache_rd_addr[10]),
    .io_readPorts_10_data(IntRegCache_rd_data[10]),
    .io_readPorts_11_ren (IntRegCache_rd_ren[11]),
    .io_readPorts_11_addr(IntRegCache_rd_addr[11]),
    .io_readPorts_11_data(IntRegCache_rd_data[11]),
    .io_readPorts_12_ren (IntRegCache_rd_ren[12]),
    .io_readPorts_12_addr(IntRegCache_rd_addr[12]),
    .io_readPorts_12_data(IntRegCache_rd_data[12]),
    .io_readPorts_13_ren (IntRegCache_rd_ren[13]),
    .io_readPorts_13_addr(IntRegCache_rd_addr[13]),
    .io_readPorts_13_data(IntRegCache_rd_data[13]),
    .io_readPorts_14_ren (IntRegCache_rd_ren[14]),
    .io_readPorts_14_addr(IntRegCache_rd_addr[14]),
    .io_readPorts_14_data(IntRegCache_rd_data[14]),
    .io_readPorts_15_ren (IntRegCache_rd_ren[15]),
    .io_readPorts_15_addr(IntRegCache_rd_addr[15]),
    .io_readPorts_15_data(IntRegCache_rd_data[15]),
    .io_readPorts_16_ren (IntRegCache_rd_ren[16]),
    .io_readPorts_16_addr(IntRegCache_rd_addr[16]),
    .io_readPorts_16_data(IntRegCache_rd_data[16]),
    .io_readPorts_17_ren (IntRegCache_rd_ren[17]),
    .io_readPorts_17_addr(IntRegCache_rd_addr[17]),
    .io_readPorts_17_data(IntRegCache_rd_data[17]),
    .io_readPorts_18_ren (IntRegCache_rd_ren[18]),
    .io_readPorts_18_addr(IntRegCache_rd_addr[18]),
    .io_readPorts_18_data(IntRegCache_rd_data[18]),
    .io_readPorts_19_ren (IntRegCache_rd_ren[19]),
    .io_readPorts_19_addr(IntRegCache_rd_addr[19]),
    .io_readPorts_19_data(IntRegCache_rd_data[19]),
    .io_readPorts_20_ren (IntRegCache_rd_ren[20]),
    .io_readPorts_20_addr(IntRegCache_rd_addr[20]),
    .io_readPorts_20_data(IntRegCache_rd_data[20]),
    .io_readPorts_21_ren (IntRegCache_rd_ren[21]),
    .io_readPorts_21_addr(IntRegCache_rd_addr[21]),
    .io_readPorts_21_data(IntRegCache_rd_data[21]),
    .io_readPorts_22_ren (IntRegCache_rd_ren[22]),
    .io_readPorts_22_addr(IntRegCache_rd_addr[22]),
    .io_readPorts_22_data(IntRegCache_rd_data[22]),
    .io_writePorts_0_wen (IntRegCache_wr_wen[0]),
    .io_writePorts_0_addr(IntRegCache_wr_addr[0]),
    .io_writePorts_0_data(IntRegCache_wr_data[0]),
    .io_writePorts_1_wen (IntRegCache_wr_wen[1]),
    .io_writePorts_1_addr(IntRegCache_wr_addr[1]),
    .io_writePorts_1_data(IntRegCache_wr_data[1]),
    .io_writePorts_2_wen (IntRegCache_wr_wen[2]),
    .io_writePorts_2_addr(IntRegCache_wr_addr[2]),
    .io_writePorts_2_data(IntRegCache_wr_data[2]),
    .io_writePorts_3_wen (IntRegCache_wr_wen[3]),
    .io_writePorts_3_addr(IntRegCache_wr_addr[3]),
    .io_writePorts_3_data(IntRegCache_wr_data[3]),
    .io_validInfo_0(IntRegCache_valid[0]), .io_validInfo_1(IntRegCache_valid[1]), .io_validInfo_2(IntRegCache_valid[2]), .io_validInfo_3(IntRegCache_valid[3]), .io_validInfo_4(IntRegCache_valid[4]), .io_validInfo_5(IntRegCache_valid[5]), .io_validInfo_6(IntRegCache_valid[6]), .io_validInfo_7(IntRegCache_valid[7]), .io_validInfo_8(IntRegCache_valid[8]), .io_validInfo_9(IntRegCache_valid[9]), .io_validInfo_10(IntRegCache_valid[10]), .io_validInfo_11(IntRegCache_valid[11]), .io_validInfo_12(IntRegCache_valid[12]), .io_validInfo_13(IntRegCache_valid[13]), .io_validInfo_14(IntRegCache_valid[14]), .io_validInfo_15(IntRegCache_valid[15])
  );

  RegCacheAgeTimer IntRegCache_age_timer (
    .clock(clock), .reset(reset),
    .io_readPorts_0_ren (IntRegCache_rd_ren[0]),
    .io_readPorts_0_addr(IntRegCache_rd_addr[0]),
    .io_readPorts_1_ren (IntRegCache_rd_ren[1]),
    .io_readPorts_1_addr(IntRegCache_rd_addr[1]),
    .io_readPorts_2_ren (IntRegCache_rd_ren[2]),
    .io_readPorts_2_addr(IntRegCache_rd_addr[2]),
    .io_readPorts_3_ren (IntRegCache_rd_ren[3]),
    .io_readPorts_3_addr(IntRegCache_rd_addr[3]),
    .io_readPorts_4_ren (IntRegCache_rd_ren[4]),
    .io_readPorts_4_addr(IntRegCache_rd_addr[4]),
    .io_readPorts_5_ren (IntRegCache_rd_ren[5]),
    .io_readPorts_5_addr(IntRegCache_rd_addr[5]),
    .io_readPorts_6_ren (IntRegCache_rd_ren[6]),
    .io_readPorts_6_addr(IntRegCache_rd_addr[6]),
    .io_readPorts_7_ren (IntRegCache_rd_ren[7]),
    .io_readPorts_7_addr(IntRegCache_rd_addr[7]),
    .io_readPorts_8_ren (IntRegCache_rd_ren[8]),
    .io_readPorts_8_addr(IntRegCache_rd_addr[8]),
    .io_readPorts_9_ren (IntRegCache_rd_ren[9]),
    .io_readPorts_9_addr(IntRegCache_rd_addr[9]),
    .io_readPorts_10_ren (IntRegCache_rd_ren[10]),
    .io_readPorts_10_addr(IntRegCache_rd_addr[10]),
    .io_readPorts_11_ren (IntRegCache_rd_ren[11]),
    .io_readPorts_11_addr(IntRegCache_rd_addr[11]),
    .io_readPorts_12_ren (IntRegCache_rd_ren[12]),
    .io_readPorts_12_addr(IntRegCache_rd_addr[12]),
    .io_readPorts_13_ren (IntRegCache_rd_ren[13]),
    .io_readPorts_13_addr(IntRegCache_rd_addr[13]),
    .io_readPorts_14_ren (IntRegCache_rd_ren[14]),
    .io_readPorts_14_addr(IntRegCache_rd_addr[14]),
    .io_readPorts_15_ren (IntRegCache_rd_ren[15]),
    .io_readPorts_15_addr(IntRegCache_rd_addr[15]),
    .io_readPorts_16_ren (IntRegCache_rd_ren[16]),
    .io_readPorts_16_addr(IntRegCache_rd_addr[16]),
    .io_readPorts_17_ren (IntRegCache_rd_ren[17]),
    .io_readPorts_17_addr(IntRegCache_rd_addr[17]),
    .io_readPorts_18_ren (IntRegCache_rd_ren[18]),
    .io_readPorts_18_addr(IntRegCache_rd_addr[18]),
    .io_readPorts_19_ren (IntRegCache_rd_ren[19]),
    .io_readPorts_19_addr(IntRegCache_rd_addr[19]),
    .io_readPorts_20_ren (IntRegCache_rd_ren[20]),
    .io_readPorts_20_addr(IntRegCache_rd_addr[20]),
    .io_readPorts_21_ren (IntRegCache_rd_ren[21]),
    .io_readPorts_21_addr(IntRegCache_rd_addr[21]),
    .io_readPorts_22_ren (IntRegCache_rd_ren[22]),
    .io_readPorts_22_addr(IntRegCache_rd_addr[22]),
    .io_writePorts_0_wen (IntRegCache_wr_wen[0]),
    .io_writePorts_0_addr(IntRegCache_wr_addr[0]),
    .io_writePorts_1_wen (IntRegCache_wr_wen[1]),
    .io_writePorts_1_addr(IntRegCache_wr_addr[1]),
    .io_writePorts_2_wen (IntRegCache_wr_wen[2]),
    .io_writePorts_2_addr(IntRegCache_wr_addr[2]),
    .io_writePorts_3_wen (IntRegCache_wr_wen[3]),
    .io_writePorts_3_addr(IntRegCache_wr_addr[3]),
    .io_validInfo_0(IntRegCache_valid[0]),
    .io_validInfo_1(IntRegCache_valid[1]),
    .io_validInfo_2(IntRegCache_valid[2]),
    .io_validInfo_3(IntRegCache_valid[3]),
    .io_validInfo_4(IntRegCache_valid[4]),
    .io_validInfo_5(IntRegCache_valid[5]),
    .io_validInfo_6(IntRegCache_valid[6]),
    .io_validInfo_7(IntRegCache_valid[7]),
    .io_validInfo_8(IntRegCache_valid[8]),
    .io_validInfo_9(IntRegCache_valid[9]),
    .io_validInfo_10(IntRegCache_valid[10]),
    .io_validInfo_11(IntRegCache_valid[11]),
    .io_validInfo_12(IntRegCache_valid[12]),
    .io_validInfo_13(IntRegCache_valid[13]),
    .io_validInfo_14(IntRegCache_valid[14]),
    .io_validInfo_15(IntRegCache_valid[15]),
    .io_ageInfo_0_1(age_int[0]), .io_ageInfo_0_2(age_int[1]), .io_ageInfo_0_3(age_int[2]), .io_ageInfo_0_4(age_int[3]), .io_ageInfo_0_5(age_int[4]), .io_ageInfo_0_6(age_int[5]), .io_ageInfo_0_7(age_int[6]), .io_ageInfo_0_8(age_int[7]), .io_ageInfo_0_9(age_int[8]), .io_ageInfo_0_10(age_int[9]), .io_ageInfo_0_11(age_int[10]), .io_ageInfo_0_12(age_int[11]), .io_ageInfo_0_13(age_int[12]), .io_ageInfo_0_14(age_int[13]), .io_ageInfo_0_15(age_int[14]), .io_ageInfo_1_2(age_int[15]), .io_ageInfo_1_3(age_int[16]), .io_ageInfo_1_4(age_int[17]), .io_ageInfo_1_5(age_int[18]), .io_ageInfo_1_6(age_int[19]), .io_ageInfo_1_7(age_int[20]), .io_ageInfo_1_8(age_int[21]), .io_ageInfo_1_9(age_int[22]), .io_ageInfo_1_10(age_int[23]), .io_ageInfo_1_11(age_int[24]), .io_ageInfo_1_12(age_int[25]), .io_ageInfo_1_13(age_int[26]), .io_ageInfo_1_14(age_int[27]), .io_ageInfo_1_15(age_int[28]), .io_ageInfo_2_3(age_int[29]), .io_ageInfo_2_4(age_int[30]), .io_ageInfo_2_5(age_int[31]), .io_ageInfo_2_6(age_int[32]), .io_ageInfo_2_7(age_int[33]), .io_ageInfo_2_8(age_int[34]), .io_ageInfo_2_9(age_int[35]), .io_ageInfo_2_10(age_int[36]), .io_ageInfo_2_11(age_int[37]), .io_ageInfo_2_12(age_int[38]), .io_ageInfo_2_13(age_int[39]), .io_ageInfo_2_14(age_int[40]), .io_ageInfo_2_15(age_int[41]), .io_ageInfo_3_4(age_int[42]), .io_ageInfo_3_5(age_int[43]), .io_ageInfo_3_6(age_int[44]), .io_ageInfo_3_7(age_int[45]), .io_ageInfo_3_8(age_int[46]), .io_ageInfo_3_9(age_int[47]), .io_ageInfo_3_10(age_int[48]), .io_ageInfo_3_11(age_int[49]), .io_ageInfo_3_12(age_int[50]), .io_ageInfo_3_13(age_int[51]), .io_ageInfo_3_14(age_int[52]), .io_ageInfo_3_15(age_int[53]), .io_ageInfo_4_5(age_int[54]), .io_ageInfo_4_6(age_int[55]), .io_ageInfo_4_7(age_int[56]), .io_ageInfo_4_8(age_int[57]), .io_ageInfo_4_9(age_int[58]), .io_ageInfo_4_10(age_int[59]), .io_ageInfo_4_11(age_int[60]), .io_ageInfo_4_12(age_int[61]), .io_ageInfo_4_13(age_int[62]), .io_ageInfo_4_14(age_int[63]), .io_ageInfo_4_15(age_int[64]), .io_ageInfo_5_6(age_int[65]), .io_ageInfo_5_7(age_int[66]), .io_ageInfo_5_8(age_int[67]), .io_ageInfo_5_9(age_int[68]), .io_ageInfo_5_10(age_int[69]), .io_ageInfo_5_11(age_int[70]), .io_ageInfo_5_12(age_int[71]), .io_ageInfo_5_13(age_int[72]), .io_ageInfo_5_14(age_int[73]), .io_ageInfo_5_15(age_int[74]), .io_ageInfo_6_7(age_int[75]), .io_ageInfo_6_8(age_int[76]), .io_ageInfo_6_9(age_int[77]), .io_ageInfo_6_10(age_int[78]), .io_ageInfo_6_11(age_int[79]), .io_ageInfo_6_12(age_int[80]), .io_ageInfo_6_13(age_int[81]), .io_ageInfo_6_14(age_int[82]), .io_ageInfo_6_15(age_int[83]), .io_ageInfo_7_8(age_int[84]), .io_ageInfo_7_9(age_int[85]), .io_ageInfo_7_10(age_int[86]), .io_ageInfo_7_11(age_int[87]), .io_ageInfo_7_12(age_int[88]), .io_ageInfo_7_13(age_int[89]), .io_ageInfo_7_14(age_int[90]), .io_ageInfo_7_15(age_int[91]), .io_ageInfo_8_9(age_int[92]), .io_ageInfo_8_10(age_int[93]), .io_ageInfo_8_11(age_int[94]), .io_ageInfo_8_12(age_int[95]), .io_ageInfo_8_13(age_int[96]), .io_ageInfo_8_14(age_int[97]), .io_ageInfo_8_15(age_int[98]), .io_ageInfo_9_10(age_int[99]), .io_ageInfo_9_11(age_int[100]), .io_ageInfo_9_12(age_int[101]), .io_ageInfo_9_13(age_int[102]), .io_ageInfo_9_14(age_int[103]), .io_ageInfo_9_15(age_int[104]), .io_ageInfo_10_11(age_int[105]), .io_ageInfo_10_12(age_int[106]), .io_ageInfo_10_13(age_int[107]), .io_ageInfo_10_14(age_int[108]), .io_ageInfo_10_15(age_int[109]), .io_ageInfo_11_12(age_int[110]), .io_ageInfo_11_13(age_int[111]), .io_ageInfo_11_14(age_int[112]), .io_ageInfo_11_15(age_int[113]), .io_ageInfo_12_13(age_int[114]), .io_ageInfo_12_14(age_int[115]), .io_ageInfo_12_15(age_int[116]), .io_ageInfo_13_14(age_int[117]), .io_ageInfo_13_15(age_int[118]), .io_ageInfo_14_15(age_int[119])
  );

  RegCacheAgeDetector IntRegCache_rep (
    .clock(clock), .reset(reset),
    .io_ageInfo_0_1(age_int[0]), .io_ageInfo_0_2(age_int[1]), .io_ageInfo_0_3(age_int[2]), .io_ageInfo_0_4(age_int[3]), .io_ageInfo_0_5(age_int[4]), .io_ageInfo_0_6(age_int[5]), .io_ageInfo_0_7(age_int[6]), .io_ageInfo_0_8(age_int[7]), .io_ageInfo_0_9(age_int[8]), .io_ageInfo_0_10(age_int[9]), .io_ageInfo_0_11(age_int[10]), .io_ageInfo_0_12(age_int[11]), .io_ageInfo_0_13(age_int[12]), .io_ageInfo_0_14(age_int[13]), .io_ageInfo_0_15(age_int[14]), .io_ageInfo_1_2(age_int[15]), .io_ageInfo_1_3(age_int[16]), .io_ageInfo_1_4(age_int[17]), .io_ageInfo_1_5(age_int[18]), .io_ageInfo_1_6(age_int[19]), .io_ageInfo_1_7(age_int[20]), .io_ageInfo_1_8(age_int[21]), .io_ageInfo_1_9(age_int[22]), .io_ageInfo_1_10(age_int[23]), .io_ageInfo_1_11(age_int[24]), .io_ageInfo_1_12(age_int[25]), .io_ageInfo_1_13(age_int[26]), .io_ageInfo_1_14(age_int[27]), .io_ageInfo_1_15(age_int[28]), .io_ageInfo_2_3(age_int[29]), .io_ageInfo_2_4(age_int[30]), .io_ageInfo_2_5(age_int[31]), .io_ageInfo_2_6(age_int[32]), .io_ageInfo_2_7(age_int[33]), .io_ageInfo_2_8(age_int[34]), .io_ageInfo_2_9(age_int[35]), .io_ageInfo_2_10(age_int[36]), .io_ageInfo_2_11(age_int[37]), .io_ageInfo_2_12(age_int[38]), .io_ageInfo_2_13(age_int[39]), .io_ageInfo_2_14(age_int[40]), .io_ageInfo_2_15(age_int[41]), .io_ageInfo_3_4(age_int[42]), .io_ageInfo_3_5(age_int[43]), .io_ageInfo_3_6(age_int[44]), .io_ageInfo_3_7(age_int[45]), .io_ageInfo_3_8(age_int[46]), .io_ageInfo_3_9(age_int[47]), .io_ageInfo_3_10(age_int[48]), .io_ageInfo_3_11(age_int[49]), .io_ageInfo_3_12(age_int[50]), .io_ageInfo_3_13(age_int[51]), .io_ageInfo_3_14(age_int[52]), .io_ageInfo_3_15(age_int[53]), .io_ageInfo_4_5(age_int[54]), .io_ageInfo_4_6(age_int[55]), .io_ageInfo_4_7(age_int[56]), .io_ageInfo_4_8(age_int[57]), .io_ageInfo_4_9(age_int[58]), .io_ageInfo_4_10(age_int[59]), .io_ageInfo_4_11(age_int[60]), .io_ageInfo_4_12(age_int[61]), .io_ageInfo_4_13(age_int[62]), .io_ageInfo_4_14(age_int[63]), .io_ageInfo_4_15(age_int[64]), .io_ageInfo_5_6(age_int[65]), .io_ageInfo_5_7(age_int[66]), .io_ageInfo_5_8(age_int[67]), .io_ageInfo_5_9(age_int[68]), .io_ageInfo_5_10(age_int[69]), .io_ageInfo_5_11(age_int[70]), .io_ageInfo_5_12(age_int[71]), .io_ageInfo_5_13(age_int[72]), .io_ageInfo_5_14(age_int[73]), .io_ageInfo_5_15(age_int[74]), .io_ageInfo_6_7(age_int[75]), .io_ageInfo_6_8(age_int[76]), .io_ageInfo_6_9(age_int[77]), .io_ageInfo_6_10(age_int[78]), .io_ageInfo_6_11(age_int[79]), .io_ageInfo_6_12(age_int[80]), .io_ageInfo_6_13(age_int[81]), .io_ageInfo_6_14(age_int[82]), .io_ageInfo_6_15(age_int[83]), .io_ageInfo_7_8(age_int[84]), .io_ageInfo_7_9(age_int[85]), .io_ageInfo_7_10(age_int[86]), .io_ageInfo_7_11(age_int[87]), .io_ageInfo_7_12(age_int[88]), .io_ageInfo_7_13(age_int[89]), .io_ageInfo_7_14(age_int[90]), .io_ageInfo_7_15(age_int[91]), .io_ageInfo_8_9(age_int[92]), .io_ageInfo_8_10(age_int[93]), .io_ageInfo_8_11(age_int[94]), .io_ageInfo_8_12(age_int[95]), .io_ageInfo_8_13(age_int[96]), .io_ageInfo_8_14(age_int[97]), .io_ageInfo_8_15(age_int[98]), .io_ageInfo_9_10(age_int[99]), .io_ageInfo_9_11(age_int[100]), .io_ageInfo_9_12(age_int[101]), .io_ageInfo_9_13(age_int[102]), .io_ageInfo_9_14(age_int[103]), .io_ageInfo_9_15(age_int[104]), .io_ageInfo_10_11(age_int[105]), .io_ageInfo_10_12(age_int[106]), .io_ageInfo_10_13(age_int[107]), .io_ageInfo_10_14(age_int[108]), .io_ageInfo_10_15(age_int[109]), .io_ageInfo_11_12(age_int[110]), .io_ageInfo_11_13(age_int[111]), .io_ageInfo_11_14(age_int[112]), .io_ageInfo_11_15(age_int[113]), .io_ageInfo_12_13(age_int[114]), .io_ageInfo_12_14(age_int[115]), .io_ageInfo_12_15(age_int[116]), .io_ageInfo_13_14(age_int[117]), .io_ageInfo_13_15(age_int[118]), .io_ageInfo_14_15(age_int[119]),
    .io_out_0(rep_int[0]), .io_out_1(rep_int[1]), .io_out_2(rep_int[2]), .io_out_3(rep_int[3])
  );

  RegCacheDataModule_1 MemRegCache (
    .clock(clock), .reset(reset),
    .io_readPorts_0_ren (MemRegCache_rd_ren[0]),
    .io_readPorts_0_addr(MemRegCache_rd_addr[0]),
    .io_readPorts_0_data(MemRegCache_rd_data[0]),
    .io_readPorts_1_ren (MemRegCache_rd_ren[1]),
    .io_readPorts_1_addr(MemRegCache_rd_addr[1]),
    .io_readPorts_1_data(MemRegCache_rd_data[1]),
    .io_readPorts_2_ren (MemRegCache_rd_ren[2]),
    .io_readPorts_2_addr(MemRegCache_rd_addr[2]),
    .io_readPorts_2_data(MemRegCache_rd_data[2]),
    .io_readPorts_3_ren (MemRegCache_rd_ren[3]),
    .io_readPorts_3_addr(MemRegCache_rd_addr[3]),
    .io_readPorts_3_data(MemRegCache_rd_data[3]),
    .io_readPorts_4_ren (MemRegCache_rd_ren[4]),
    .io_readPorts_4_addr(MemRegCache_rd_addr[4]),
    .io_readPorts_4_data(MemRegCache_rd_data[4]),
    .io_readPorts_5_ren (MemRegCache_rd_ren[5]),
    .io_readPorts_5_addr(MemRegCache_rd_addr[5]),
    .io_readPorts_5_data(MemRegCache_rd_data[5]),
    .io_readPorts_6_ren (MemRegCache_rd_ren[6]),
    .io_readPorts_6_addr(MemRegCache_rd_addr[6]),
    .io_readPorts_6_data(MemRegCache_rd_data[6]),
    .io_readPorts_7_ren (MemRegCache_rd_ren[7]),
    .io_readPorts_7_addr(MemRegCache_rd_addr[7]),
    .io_readPorts_7_data(MemRegCache_rd_data[7]),
    .io_readPorts_8_ren (MemRegCache_rd_ren[8]),
    .io_readPorts_8_addr(MemRegCache_rd_addr[8]),
    .io_readPorts_8_data(MemRegCache_rd_data[8]),
    .io_readPorts_9_ren (MemRegCache_rd_ren[9]),
    .io_readPorts_9_addr(MemRegCache_rd_addr[9]),
    .io_readPorts_9_data(MemRegCache_rd_data[9]),
    .io_readPorts_10_ren (MemRegCache_rd_ren[10]),
    .io_readPorts_10_addr(MemRegCache_rd_addr[10]),
    .io_readPorts_10_data(MemRegCache_rd_data[10]),
    .io_readPorts_11_ren (MemRegCache_rd_ren[11]),
    .io_readPorts_11_addr(MemRegCache_rd_addr[11]),
    .io_readPorts_11_data(MemRegCache_rd_data[11]),
    .io_readPorts_12_ren (MemRegCache_rd_ren[12]),
    .io_readPorts_12_addr(MemRegCache_rd_addr[12]),
    .io_readPorts_12_data(MemRegCache_rd_data[12]),
    .io_readPorts_13_ren (MemRegCache_rd_ren[13]),
    .io_readPorts_13_addr(MemRegCache_rd_addr[13]),
    .io_readPorts_13_data(MemRegCache_rd_data[13]),
    .io_readPorts_14_ren (MemRegCache_rd_ren[14]),
    .io_readPorts_14_addr(MemRegCache_rd_addr[14]),
    .io_readPorts_14_data(MemRegCache_rd_data[14]),
    .io_readPorts_15_ren (MemRegCache_rd_ren[15]),
    .io_readPorts_15_addr(MemRegCache_rd_addr[15]),
    .io_readPorts_15_data(MemRegCache_rd_data[15]),
    .io_readPorts_16_ren (MemRegCache_rd_ren[16]),
    .io_readPorts_16_addr(MemRegCache_rd_addr[16]),
    .io_readPorts_16_data(MemRegCache_rd_data[16]),
    .io_readPorts_17_ren (MemRegCache_rd_ren[17]),
    .io_readPorts_17_addr(MemRegCache_rd_addr[17]),
    .io_readPorts_17_data(MemRegCache_rd_data[17]),
    .io_readPorts_18_ren (MemRegCache_rd_ren[18]),
    .io_readPorts_18_addr(MemRegCache_rd_addr[18]),
    .io_readPorts_18_data(MemRegCache_rd_data[18]),
    .io_readPorts_19_ren (MemRegCache_rd_ren[19]),
    .io_readPorts_19_addr(MemRegCache_rd_addr[19]),
    .io_readPorts_19_data(MemRegCache_rd_data[19]),
    .io_readPorts_20_ren (MemRegCache_rd_ren[20]),
    .io_readPorts_20_addr(MemRegCache_rd_addr[20]),
    .io_readPorts_20_data(MemRegCache_rd_data[20]),
    .io_readPorts_21_ren (MemRegCache_rd_ren[21]),
    .io_readPorts_21_addr(MemRegCache_rd_addr[21]),
    .io_readPorts_21_data(MemRegCache_rd_data[21]),
    .io_readPorts_22_ren (MemRegCache_rd_ren[22]),
    .io_readPorts_22_addr(MemRegCache_rd_addr[22]),
    .io_readPorts_22_data(MemRegCache_rd_data[22]),
    .io_writePorts_0_wen (MemRegCache_wr_wen[0]),
    .io_writePorts_0_addr(MemRegCache_wr_addr[0]),
    .io_writePorts_0_data(MemRegCache_wr_data[0]),
    .io_writePorts_1_wen (MemRegCache_wr_wen[1]),
    .io_writePorts_1_addr(MemRegCache_wr_addr[1]),
    .io_writePorts_1_data(MemRegCache_wr_data[1]),
    .io_writePorts_2_wen (MemRegCache_wr_wen[2]),
    .io_writePorts_2_addr(MemRegCache_wr_addr[2]),
    .io_writePorts_2_data(MemRegCache_wr_data[2]),
    .io_validInfo_0(MemRegCache_valid[0]), .io_validInfo_1(MemRegCache_valid[1]), .io_validInfo_2(MemRegCache_valid[2]), .io_validInfo_3(MemRegCache_valid[3]), .io_validInfo_4(MemRegCache_valid[4]), .io_validInfo_5(MemRegCache_valid[5]), .io_validInfo_6(MemRegCache_valid[6]), .io_validInfo_7(MemRegCache_valid[7]), .io_validInfo_8(MemRegCache_valid[8]), .io_validInfo_9(MemRegCache_valid[9]), .io_validInfo_10(MemRegCache_valid[10]), .io_validInfo_11(MemRegCache_valid[11])
  );

  RegCacheAgeTimer_1 MemRegCache_age_timer (
    .clock(clock), .reset(reset),
    .io_readPorts_0_ren (MemRegCache_rd_ren[0]),
    .io_readPorts_0_addr(MemRegCache_rd_addr[0]),
    .io_readPorts_1_ren (MemRegCache_rd_ren[1]),
    .io_readPorts_1_addr(MemRegCache_rd_addr[1]),
    .io_readPorts_2_ren (MemRegCache_rd_ren[2]),
    .io_readPorts_2_addr(MemRegCache_rd_addr[2]),
    .io_readPorts_3_ren (MemRegCache_rd_ren[3]),
    .io_readPorts_3_addr(MemRegCache_rd_addr[3]),
    .io_readPorts_4_ren (MemRegCache_rd_ren[4]),
    .io_readPorts_4_addr(MemRegCache_rd_addr[4]),
    .io_readPorts_5_ren (MemRegCache_rd_ren[5]),
    .io_readPorts_5_addr(MemRegCache_rd_addr[5]),
    .io_readPorts_6_ren (MemRegCache_rd_ren[6]),
    .io_readPorts_6_addr(MemRegCache_rd_addr[6]),
    .io_readPorts_7_ren (MemRegCache_rd_ren[7]),
    .io_readPorts_7_addr(MemRegCache_rd_addr[7]),
    .io_readPorts_8_ren (MemRegCache_rd_ren[8]),
    .io_readPorts_8_addr(MemRegCache_rd_addr[8]),
    .io_readPorts_9_ren (MemRegCache_rd_ren[9]),
    .io_readPorts_9_addr(MemRegCache_rd_addr[9]),
    .io_readPorts_10_ren (MemRegCache_rd_ren[10]),
    .io_readPorts_10_addr(MemRegCache_rd_addr[10]),
    .io_readPorts_11_ren (MemRegCache_rd_ren[11]),
    .io_readPorts_11_addr(MemRegCache_rd_addr[11]),
    .io_readPorts_12_ren (MemRegCache_rd_ren[12]),
    .io_readPorts_12_addr(MemRegCache_rd_addr[12]),
    .io_readPorts_13_ren (MemRegCache_rd_ren[13]),
    .io_readPorts_13_addr(MemRegCache_rd_addr[13]),
    .io_readPorts_14_ren (MemRegCache_rd_ren[14]),
    .io_readPorts_14_addr(MemRegCache_rd_addr[14]),
    .io_readPorts_15_ren (MemRegCache_rd_ren[15]),
    .io_readPorts_15_addr(MemRegCache_rd_addr[15]),
    .io_readPorts_16_ren (MemRegCache_rd_ren[16]),
    .io_readPorts_16_addr(MemRegCache_rd_addr[16]),
    .io_readPorts_17_ren (MemRegCache_rd_ren[17]),
    .io_readPorts_17_addr(MemRegCache_rd_addr[17]),
    .io_readPorts_18_ren (MemRegCache_rd_ren[18]),
    .io_readPorts_18_addr(MemRegCache_rd_addr[18]),
    .io_readPorts_19_ren (MemRegCache_rd_ren[19]),
    .io_readPorts_19_addr(MemRegCache_rd_addr[19]),
    .io_readPorts_20_ren (MemRegCache_rd_ren[20]),
    .io_readPorts_20_addr(MemRegCache_rd_addr[20]),
    .io_readPorts_21_ren (MemRegCache_rd_ren[21]),
    .io_readPorts_21_addr(MemRegCache_rd_addr[21]),
    .io_readPorts_22_ren (MemRegCache_rd_ren[22]),
    .io_readPorts_22_addr(MemRegCache_rd_addr[22]),
    .io_writePorts_0_wen (MemRegCache_wr_wen[0]),
    .io_writePorts_0_addr(MemRegCache_wr_addr[0]),
    .io_writePorts_1_wen (MemRegCache_wr_wen[1]),
    .io_writePorts_1_addr(MemRegCache_wr_addr[1]),
    .io_writePorts_2_wen (MemRegCache_wr_wen[2]),
    .io_writePorts_2_addr(MemRegCache_wr_addr[2]),
    .io_validInfo_0(MemRegCache_valid[0]),
    .io_validInfo_1(MemRegCache_valid[1]),
    .io_validInfo_2(MemRegCache_valid[2]),
    .io_validInfo_3(MemRegCache_valid[3]),
    .io_validInfo_4(MemRegCache_valid[4]),
    .io_validInfo_5(MemRegCache_valid[5]),
    .io_validInfo_6(MemRegCache_valid[6]),
    .io_validInfo_7(MemRegCache_valid[7]),
    .io_validInfo_8(MemRegCache_valid[8]),
    .io_validInfo_9(MemRegCache_valid[9]),
    .io_validInfo_10(MemRegCache_valid[10]),
    .io_validInfo_11(MemRegCache_valid[11]),
    .io_ageInfo_0_1(age_mem[0]), .io_ageInfo_0_2(age_mem[1]), .io_ageInfo_0_3(age_mem[2]), .io_ageInfo_0_4(age_mem[3]), .io_ageInfo_0_5(age_mem[4]), .io_ageInfo_0_6(age_mem[5]), .io_ageInfo_0_7(age_mem[6]), .io_ageInfo_0_8(age_mem[7]), .io_ageInfo_0_9(age_mem[8]), .io_ageInfo_0_10(age_mem[9]), .io_ageInfo_0_11(age_mem[10]), .io_ageInfo_1_2(age_mem[11]), .io_ageInfo_1_3(age_mem[12]), .io_ageInfo_1_4(age_mem[13]), .io_ageInfo_1_5(age_mem[14]), .io_ageInfo_1_6(age_mem[15]), .io_ageInfo_1_7(age_mem[16]), .io_ageInfo_1_8(age_mem[17]), .io_ageInfo_1_9(age_mem[18]), .io_ageInfo_1_10(age_mem[19]), .io_ageInfo_1_11(age_mem[20]), .io_ageInfo_2_3(age_mem[21]), .io_ageInfo_2_4(age_mem[22]), .io_ageInfo_2_5(age_mem[23]), .io_ageInfo_2_6(age_mem[24]), .io_ageInfo_2_7(age_mem[25]), .io_ageInfo_2_8(age_mem[26]), .io_ageInfo_2_9(age_mem[27]), .io_ageInfo_2_10(age_mem[28]), .io_ageInfo_2_11(age_mem[29]), .io_ageInfo_3_4(age_mem[30]), .io_ageInfo_3_5(age_mem[31]), .io_ageInfo_3_6(age_mem[32]), .io_ageInfo_3_7(age_mem[33]), .io_ageInfo_3_8(age_mem[34]), .io_ageInfo_3_9(age_mem[35]), .io_ageInfo_3_10(age_mem[36]), .io_ageInfo_3_11(age_mem[37]), .io_ageInfo_4_5(age_mem[38]), .io_ageInfo_4_6(age_mem[39]), .io_ageInfo_4_7(age_mem[40]), .io_ageInfo_4_8(age_mem[41]), .io_ageInfo_4_9(age_mem[42]), .io_ageInfo_4_10(age_mem[43]), .io_ageInfo_4_11(age_mem[44]), .io_ageInfo_5_6(age_mem[45]), .io_ageInfo_5_7(age_mem[46]), .io_ageInfo_5_8(age_mem[47]), .io_ageInfo_5_9(age_mem[48]), .io_ageInfo_5_10(age_mem[49]), .io_ageInfo_5_11(age_mem[50]), .io_ageInfo_6_7(age_mem[51]), .io_ageInfo_6_8(age_mem[52]), .io_ageInfo_6_9(age_mem[53]), .io_ageInfo_6_10(age_mem[54]), .io_ageInfo_6_11(age_mem[55]), .io_ageInfo_7_8(age_mem[56]), .io_ageInfo_7_9(age_mem[57]), .io_ageInfo_7_10(age_mem[58]), .io_ageInfo_7_11(age_mem[59]), .io_ageInfo_8_9(age_mem[60]), .io_ageInfo_8_10(age_mem[61]), .io_ageInfo_8_11(age_mem[62]), .io_ageInfo_9_10(age_mem[63]), .io_ageInfo_9_11(age_mem[64]), .io_ageInfo_10_11(age_mem[65])
  );

  RegCacheAgeDetector_1 MemRegCache_rep (
    .clock(clock), .reset(reset),
    .io_ageInfo_0_1(age_mem[0]), .io_ageInfo_0_2(age_mem[1]), .io_ageInfo_0_3(age_mem[2]), .io_ageInfo_0_4(age_mem[3]), .io_ageInfo_0_5(age_mem[4]), .io_ageInfo_0_6(age_mem[5]), .io_ageInfo_0_7(age_mem[6]), .io_ageInfo_0_8(age_mem[7]), .io_ageInfo_0_9(age_mem[8]), .io_ageInfo_0_10(age_mem[9]), .io_ageInfo_0_11(age_mem[10]), .io_ageInfo_1_2(age_mem[11]), .io_ageInfo_1_3(age_mem[12]), .io_ageInfo_1_4(age_mem[13]), .io_ageInfo_1_5(age_mem[14]), .io_ageInfo_1_6(age_mem[15]), .io_ageInfo_1_7(age_mem[16]), .io_ageInfo_1_8(age_mem[17]), .io_ageInfo_1_9(age_mem[18]), .io_ageInfo_1_10(age_mem[19]), .io_ageInfo_1_11(age_mem[20]), .io_ageInfo_2_3(age_mem[21]), .io_ageInfo_2_4(age_mem[22]), .io_ageInfo_2_5(age_mem[23]), .io_ageInfo_2_6(age_mem[24]), .io_ageInfo_2_7(age_mem[25]), .io_ageInfo_2_8(age_mem[26]), .io_ageInfo_2_9(age_mem[27]), .io_ageInfo_2_10(age_mem[28]), .io_ageInfo_2_11(age_mem[29]), .io_ageInfo_3_4(age_mem[30]), .io_ageInfo_3_5(age_mem[31]), .io_ageInfo_3_6(age_mem[32]), .io_ageInfo_3_7(age_mem[33]), .io_ageInfo_3_8(age_mem[34]), .io_ageInfo_3_9(age_mem[35]), .io_ageInfo_3_10(age_mem[36]), .io_ageInfo_3_11(age_mem[37]), .io_ageInfo_4_5(age_mem[38]), .io_ageInfo_4_6(age_mem[39]), .io_ageInfo_4_7(age_mem[40]), .io_ageInfo_4_8(age_mem[41]), .io_ageInfo_4_9(age_mem[42]), .io_ageInfo_4_10(age_mem[43]), .io_ageInfo_4_11(age_mem[44]), .io_ageInfo_5_6(age_mem[45]), .io_ageInfo_5_7(age_mem[46]), .io_ageInfo_5_8(age_mem[47]), .io_ageInfo_5_9(age_mem[48]), .io_ageInfo_5_10(age_mem[49]), .io_ageInfo_5_11(age_mem[50]), .io_ageInfo_6_7(age_mem[51]), .io_ageInfo_6_8(age_mem[52]), .io_ageInfo_6_9(age_mem[53]), .io_ageInfo_6_10(age_mem[54]), .io_ageInfo_6_11(age_mem[55]), .io_ageInfo_7_8(age_mem[56]), .io_ageInfo_7_9(age_mem[57]), .io_ageInfo_7_10(age_mem[58]), .io_ageInfo_7_11(age_mem[59]), .io_ageInfo_8_9(age_mem[60]), .io_ageInfo_8_10(age_mem[61]), .io_ageInfo_8_11(age_mem[62]), .io_ageInfo_9_10(age_mem[63]), .io_ageInfo_9_11(age_mem[64]), .io_ageInfo_10_11(age_mem[65]),
    .io_out_0(rep_mem[0]), .io_out_1(rep_mem[1]), .io_out_2(rep_mem[2])
  );

endmodule : xs_RegCache_core

// ---------------------------------------------------------------------------
//  golden 同名层：端口与 G1 golden RegCache.sv 逐位同名同宽，
//  只做"扁平端口 <-> 数组"的机械适配。
// ---------------------------------------------------------------------------
module RegCache
  import regcache_pkg::*;
(
  input         clock,
  input         reset,
  input         io_readPorts_0_ren,
  input  [4:0]  io_readPorts_0_addr,
  output [63:0] io_readPorts_0_data,
  input         io_readPorts_1_ren,
  input  [4:0]  io_readPorts_1_addr,
  output [63:0] io_readPorts_1_data,
  input         io_readPorts_2_ren,
  input  [4:0]  io_readPorts_2_addr,
  output [63:0] io_readPorts_2_data,
  input         io_readPorts_3_ren,
  input  [4:0]  io_readPorts_3_addr,
  output [63:0] io_readPorts_3_data,
  input         io_readPorts_4_ren,
  input  [4:0]  io_readPorts_4_addr,
  output [63:0] io_readPorts_4_data,
  input         io_readPorts_5_ren,
  input  [4:0]  io_readPorts_5_addr,
  output [63:0] io_readPorts_5_data,
  input         io_readPorts_6_ren,
  input  [4:0]  io_readPorts_6_addr,
  output [63:0] io_readPorts_6_data,
  input         io_readPorts_7_ren,
  input  [4:0]  io_readPorts_7_addr,
  output [63:0] io_readPorts_7_data,
  input         io_readPorts_8_ren,
  input  [4:0]  io_readPorts_8_addr,
  output [63:0] io_readPorts_8_data,
  input         io_readPorts_9_ren,
  input  [4:0]  io_readPorts_9_addr,
  output [63:0] io_readPorts_9_data,
  input         io_readPorts_10_ren,
  input  [4:0]  io_readPorts_10_addr,
  output [63:0] io_readPorts_10_data,
  input         io_readPorts_11_ren,
  input  [4:0]  io_readPorts_11_addr,
  output [63:0] io_readPorts_11_data,
  input         io_readPorts_12_ren,
  input  [4:0]  io_readPorts_12_addr,
  output [63:0] io_readPorts_12_data,
  input         io_readPorts_13_ren,
  input  [4:0]  io_readPorts_13_addr,
  output [63:0] io_readPorts_13_data,
  input         io_readPorts_14_ren,
  input  [4:0]  io_readPorts_14_addr,
  output [63:0] io_readPorts_14_data,
  input         io_readPorts_15_ren,
  input  [4:0]  io_readPorts_15_addr,
  output [63:0] io_readPorts_15_data,
  input         io_readPorts_16_ren,
  input  [4:0]  io_readPorts_16_addr,
  output [63:0] io_readPorts_16_data,
  input         io_readPorts_17_ren,
  input  [4:0]  io_readPorts_17_addr,
  output [63:0] io_readPorts_17_data,
  input         io_readPorts_18_ren,
  input  [4:0]  io_readPorts_18_addr,
  output [63:0] io_readPorts_18_data,
  input         io_readPorts_19_ren,
  input  [4:0]  io_readPorts_19_addr,
  output [63:0] io_readPorts_19_data,
  input         io_readPorts_20_ren,
  input  [4:0]  io_readPorts_20_addr,
  output [63:0] io_readPorts_20_data,
  input         io_readPorts_21_ren,
  input  [4:0]  io_readPorts_21_addr,
  output [63:0] io_readPorts_21_data,
  input         io_readPorts_22_ren,
  input  [4:0]  io_readPorts_22_addr,
  output [63:0] io_readPorts_22_data,
  input         io_writePorts_0_wen,
  input  [63:0] io_writePorts_0_data,
  input         io_writePorts_1_wen,
  input  [63:0] io_writePorts_1_data,
  input         io_writePorts_2_wen,
  input  [63:0] io_writePorts_2_data,
  input         io_writePorts_3_wen,
  input  [63:0] io_writePorts_3_data,
  input         io_writePorts_4_wen,
  input  [63:0] io_writePorts_4_data,
  input         io_writePorts_5_wen,
  input  [63:0] io_writePorts_5_data,
  input         io_writePorts_6_wen,
  input  [63:0] io_writePorts_6_data,
  output [4:0]  io_toWakeupQueueRCIdx_0,
  output [4:0]  io_toWakeupQueueRCIdx_1,
  output [4:0]  io_toWakeupQueueRCIdx_2,
  output [4:0]  io_toWakeupQueueRCIdx_3,
  output [4:0]  io_toWakeupQueueRCIdx_4,
  output [4:0]  io_toWakeupQueueRCIdx_5,
  output [4:0]  io_toWakeupQueueRCIdx_6
);

  // 扁平端口 -> 数组
  logic              [N_READ-1:0]            rd_ren;
  logic [N_READ-1:0] [IDX_W-1:0]             rd_idx;
  logic [N_READ-1:0] [DATA_W-1:0]            rd_data;
  logic              [N_WRITE-1:0]           wr_wen;
  logic [N_WRITE-1:0][DATA_W-1:0]            wr_data;
  logic [N_WRITE-1:0][IDX_W-1:0]             to_wakeup_idx;

  assign rd_ren[0]  = io_readPorts_0_ren;
  assign rd_idx[0]  = io_readPorts_0_addr;
  assign io_readPorts_0_data = rd_data[0];
  assign rd_ren[1]  = io_readPorts_1_ren;
  assign rd_idx[1]  = io_readPorts_1_addr;
  assign io_readPorts_1_data = rd_data[1];
  assign rd_ren[2]  = io_readPorts_2_ren;
  assign rd_idx[2]  = io_readPorts_2_addr;
  assign io_readPorts_2_data = rd_data[2];
  assign rd_ren[3]  = io_readPorts_3_ren;
  assign rd_idx[3]  = io_readPorts_3_addr;
  assign io_readPorts_3_data = rd_data[3];
  assign rd_ren[4]  = io_readPorts_4_ren;
  assign rd_idx[4]  = io_readPorts_4_addr;
  assign io_readPorts_4_data = rd_data[4];
  assign rd_ren[5]  = io_readPorts_5_ren;
  assign rd_idx[5]  = io_readPorts_5_addr;
  assign io_readPorts_5_data = rd_data[5];
  assign rd_ren[6]  = io_readPorts_6_ren;
  assign rd_idx[6]  = io_readPorts_6_addr;
  assign io_readPorts_6_data = rd_data[6];
  assign rd_ren[7]  = io_readPorts_7_ren;
  assign rd_idx[7]  = io_readPorts_7_addr;
  assign io_readPorts_7_data = rd_data[7];
  assign rd_ren[8]  = io_readPorts_8_ren;
  assign rd_idx[8]  = io_readPorts_8_addr;
  assign io_readPorts_8_data = rd_data[8];
  assign rd_ren[9]  = io_readPorts_9_ren;
  assign rd_idx[9]  = io_readPorts_9_addr;
  assign io_readPorts_9_data = rd_data[9];
  assign rd_ren[10]  = io_readPorts_10_ren;
  assign rd_idx[10]  = io_readPorts_10_addr;
  assign io_readPorts_10_data = rd_data[10];
  assign rd_ren[11]  = io_readPorts_11_ren;
  assign rd_idx[11]  = io_readPorts_11_addr;
  assign io_readPorts_11_data = rd_data[11];
  assign rd_ren[12]  = io_readPorts_12_ren;
  assign rd_idx[12]  = io_readPorts_12_addr;
  assign io_readPorts_12_data = rd_data[12];
  assign rd_ren[13]  = io_readPorts_13_ren;
  assign rd_idx[13]  = io_readPorts_13_addr;
  assign io_readPorts_13_data = rd_data[13];
  assign rd_ren[14]  = io_readPorts_14_ren;
  assign rd_idx[14]  = io_readPorts_14_addr;
  assign io_readPorts_14_data = rd_data[14];
  assign rd_ren[15]  = io_readPorts_15_ren;
  assign rd_idx[15]  = io_readPorts_15_addr;
  assign io_readPorts_15_data = rd_data[15];
  assign rd_ren[16]  = io_readPorts_16_ren;
  assign rd_idx[16]  = io_readPorts_16_addr;
  assign io_readPorts_16_data = rd_data[16];
  assign rd_ren[17]  = io_readPorts_17_ren;
  assign rd_idx[17]  = io_readPorts_17_addr;
  assign io_readPorts_17_data = rd_data[17];
  assign rd_ren[18]  = io_readPorts_18_ren;
  assign rd_idx[18]  = io_readPorts_18_addr;
  assign io_readPorts_18_data = rd_data[18];
  assign rd_ren[19]  = io_readPorts_19_ren;
  assign rd_idx[19]  = io_readPorts_19_addr;
  assign io_readPorts_19_data = rd_data[19];
  assign rd_ren[20]  = io_readPorts_20_ren;
  assign rd_idx[20]  = io_readPorts_20_addr;
  assign io_readPorts_20_data = rd_data[20];
  assign rd_ren[21]  = io_readPorts_21_ren;
  assign rd_idx[21]  = io_readPorts_21_addr;
  assign io_readPorts_21_data = rd_data[21];
  assign rd_ren[22]  = io_readPorts_22_ren;
  assign rd_idx[22]  = io_readPorts_22_addr;
  assign io_readPorts_22_data = rd_data[22];
  assign wr_wen[0]  = io_writePorts_0_wen;
  assign wr_data[0] = io_writePorts_0_data;
  assign io_toWakeupQueueRCIdx_0 = to_wakeup_idx[0];
  assign wr_wen[1]  = io_writePorts_1_wen;
  assign wr_data[1] = io_writePorts_1_data;
  assign io_toWakeupQueueRCIdx_1 = to_wakeup_idx[1];
  assign wr_wen[2]  = io_writePorts_2_wen;
  assign wr_data[2] = io_writePorts_2_data;
  assign io_toWakeupQueueRCIdx_2 = to_wakeup_idx[2];
  assign wr_wen[3]  = io_writePorts_3_wen;
  assign wr_data[3] = io_writePorts_3_data;
  assign io_toWakeupQueueRCIdx_3 = to_wakeup_idx[3];
  assign wr_wen[4]  = io_writePorts_4_wen;
  assign wr_data[4] = io_writePorts_4_data;
  assign io_toWakeupQueueRCIdx_4 = to_wakeup_idx[4];
  assign wr_wen[5]  = io_writePorts_5_wen;
  assign wr_data[5] = io_writePorts_5_data;
  assign io_toWakeupQueueRCIdx_5 = to_wakeup_idx[5];
  assign wr_wen[6]  = io_writePorts_6_wen;
  assign wr_data[6] = io_writePorts_6_data;
  assign io_toWakeupQueueRCIdx_6 = to_wakeup_idx[6];

  xs_RegCache_core u_core (
    .clock(clock), .reset(reset),
    .rd_ren(rd_ren), .rd_idx(rd_idx), .rd_data(rd_data),
    .wr_wen(wr_wen), .wr_data(wr_data),
    .to_wakeup_idx(to_wakeup_idx)
  );
endmodule
