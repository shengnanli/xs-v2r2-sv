// =============================================================================
// LqPAddrModule.sv —— LoadQueueRAR 的部分物理地址 CAM 阵列（72 项 × 16 位"折叠 paddr"）
//
// 对应 Chisel: xiangshan.mem.LqPAddrModule（写通路在基类 LqRawDataModule）
//   src/main/scala/xiangshan/mem/lsqueue/LoadQueueData.scala
//   例化处：LoadQueueRAR.scala `new LqPAddrModule(gen = UInt(16.W), numEntries = 72,
//           numRead = 3, numWrite = 3, numWBank = 8, numWDelay = 1, numCamPort = 3,
//           enableCacheLineCheck = false, paddrOffset = 0)`
//
// 在流水线里的位置：LoadQueueRAR 为每条"前面还有没写回的 load"的 load 占一个槽（72 项），
// 本阵列存该 load 的 16 位**折叠物理地址**（genPartialPAddr：把 paddr[47:6] 异或折叠成
// 16 位，见 LoadQueueRAR.sv）。存进来之后被两种查询反查（CAM，纯组合，当拍出结果）：
//   · releaseViolation CAM ×3（每条 load 流水一个）：新来的 load 与队里哪些 load 同地址
//     —— load→load 违例检测的地址条件；
//   · release CAM ×1（只剩第 2 口，见下）：DCache 释放（release）的 cacheline 命中了哪些
//     load —— 用来置 released 标志。
//   两种 CAM 的比较规则相同：整 16 位相等（enableCacheLineCheck=false）。
//
// ★golden 里被 firtool 消掉、因此本文件也不写的端口：
//   读口 ren/raddr/rdata（父级没接）、violation CAM（父级没用）、release CAM 的第 0/1 口
//   （父级只用 `releaseMdata.takeRight(1)`，即第 2 口 —— 所以端口名是 io_releaseMdata_2 /
//   io_releaseMmask_2_*，下标从 2 开始不是笔误）。
//
// 写通路（基类逻辑，与 LqVAddrModule / xs_LqRawDataCam_core 同一套，只是 numWDelay 不同）：
//   写地址译成 one-hot（UIntToOH，宽 2^7 = 128），按 8 个 bank × 9 项切片；每个 bank 对每个
//   写口各有一份"bank 写使能 / bank 内地址译码 / 写数据"的延迟件，经过它们再写进条目。
//   ★本模块 numWDelay = 1 ⇒ 延迟件深度 numWDelay-1 = 0：三个延迟件都是**直连线**
//   （golden 里连 clock 端口都没有），写请求**当拍**就在时钟沿写进条目。
//   延迟件照 golden 同名例化（每 bank × 每写口一份，共 3 × 24 = 72 个），它们没有寄存器，
//   保留它们只是为了与 golden 的层次一一对应（FM 两侧白盒）。
//   同拍多个写口命中同一条目时 Chisel 用 Mux1H ⇒ 各口数据**按位或**
//   （上游 FreeList 保证不撞，golden 仅有非综合断言）。照抄"或"，不能写成优先级。
//
// 三个延迟件（都是本仓已签核的重写件，PROVEN_DIRECT）：
//   DelayN_225          1 位，0 级（bank 写使能）
//   DelayNWithValid_4   9 位，0 级（bank 内 9 项的地址译码）
//   DelayNWithValid_7   16 位，0 级（写数据）
//
// ★复位域：72 个条目寄存器**全部不复位**（Chisel `Reg(Vec(...))`）。
//   wrapper 端口上的 reset 只被 golden `ifndef SYNTHESIS 的写冲突断言用到（本文件不写断言）。
//
// 为什么不复用 xs_LqRawDataCam_core（LoadQueueRAW 的两块 CAM 共用核）：那个核固化了
// numWDelay=2 的延迟件（DelayN_13 / DelayNWithValid_52 带 clock/valid 端口）和
// violation CAM 口；本模块延迟件是另一组 0 级件、CAM 是 release/releaseViolation 两组、
// 项数/bank 宽也不同。塞进同一个核要加三四个模式参数并重证 3 个已签目标，
// 读起来反而更绕 —— 与 LqVAddrModule 一样，自成一个核。
// =============================================================================

module xs_LqPAddrModule_core #(
  parameter int NUM_ENTRIES = 72,   // LoadQueueRARSize
  parameter int DATA_W      = 16,   // PartialPAddrBits
  parameter int NUM_WRITE   = 3,    // LoadPipelineWidth
  parameter int NUM_WBANK   = 8,    // LoadQueueNWriteBanks
  parameter int NUM_VIO_CAM = 3,    // releaseViolation CAM 口数（= LoadPipelineWidth）
  parameter int ADDR_W      = $clog2(NUM_ENTRIES)
) (
  // 写口：wen/waddr/wdata 当拍给出，本拍时钟沿写进条目（0 级延迟）
  input  logic                   clock,
  input  logic [NUM_WRITE-1:0]   io_wen,
  input  logic [ADDR_W-1:0]      io_waddr [NUM_WRITE],
  input  logic [DATA_W-1:0]      io_wdata [NUM_WRITE],

  // release CAM（golden 只剩一个口）：被释放的 cacheline 命中了哪些条目
  input  logic [DATA_W-1:0]      io_releaseMdata,
  output logic [NUM_ENTRIES-1:0] io_releaseMmask,

  // releaseViolation CAM：每条 load 流水查一次，看队里哪些条目与它同地址
  input  logic [DATA_W-1:0]      io_releaseViolationMdata [NUM_VIO_CAM],
  output logic [NUM_ENTRIES-1:0] io_releaseViolationMmask [NUM_VIO_CAM]
);

  localparam int PER_BANK = NUM_ENTRIES / NUM_WBANK;  // 9 项/bank
  localparam int DEC_W    = 1 << ADDR_W;              // UIntToOH 宽度 = 128（高 56 位用不到）

  // ===========================================================================
  // 1. 条目存储（不复位）
  // ===========================================================================
  logic [DATA_W-1:0] data [NUM_ENTRIES];

  // ===========================================================================
  // 2. 写地址译码 + 分 bank（s0 = 写请求当拍）
  // ===========================================================================
  logic [DEC_W-1:0] writeAddrDec [NUM_WRITE];
  always_comb
    for (int w = 0; w < NUM_WRITE; w++)
      writeAddrDec[w] = DEC_W'(1) << io_waddr[w];

  // bank b 内的 9 位译码片，以及"写口 w 这拍写的是不是 bank b"
  logic [PER_BANK-1:0] s0_bankWriteAddrDec [NUM_WBANK][NUM_WRITE];
  logic                s0_bankWriteEn      [NUM_WBANK][NUM_WRITE];
  always_comb
    for (int b = 0; b < NUM_WBANK; b++)
      for (int w = 0; w < NUM_WRITE; w++) begin
        s0_bankWriteAddrDec[b][w] = writeAddrDec[w][b*PER_BANK +: PER_BANK];
        s0_bankWriteEn[b][w]      = io_wen[w] & (|s0_bankWriteAddrDec[b][w]);
      end

  // ===========================================================================
  // 3. 写通路"延迟"（0 级 = 直连），每 bank × 每写口各一份，照 golden 层次例化
  // ===========================================================================
  logic [PER_BANK-1:0] sx_bankWriteAddrDec [NUM_WBANK][NUM_WRITE];
  logic                sx_bankWriteEn      [NUM_WBANK][NUM_WRITE];
  logic [DATA_W-1:0]   sx_writeData        [NUM_WBANK][NUM_WRITE];

  for (genvar b = 0; b < NUM_WBANK; b++) begin : g_bank
    for (genvar w = 0; w < NUM_WRITE; w++) begin : g_wport
      DelayNWithValid_4 sx_bankWriteAddrDec_resp_pipMod (
        .io_in_bits  (s0_bankWriteAddrDec[b][w]),
        .io_out_bits (sx_bankWriteAddrDec[b][w])
      );
      DelayN_225 sx_bankWriteEn_delay (
        .io_in  (s0_bankWriteEn[b][w]),
        .io_out (sx_bankWriteEn[b][w])
      );
      DelayNWithValid_7 sx_writeData_resp_pipMod (
        .io_in_bits  (io_wdata[w]),
        .io_out_bits (sx_writeData[b][w])
      );
    end
  end

  // ===========================================================================
  // 4. 条目写入：所在 bank 的 3 个写口竞争，Mux1H（多命中 = 按位或）
  // ===========================================================================
  logic [NUM_WRITE-1:0] entryWriteEn   [NUM_ENTRIES];
  logic [DATA_W-1:0]    entryWriteData [NUM_ENTRIES];
  always_comb
    for (int b = 0; b < NUM_WBANK; b++)
      for (int e = 0; e < PER_BANK; e++) begin
        automatic int idx = b*PER_BANK + e;
        entryWriteData[idx] = '0;
        for (int w = 0; w < NUM_WRITE; w++) begin
          entryWriteEn[idx][w] = sx_bankWriteEn[b][w] & sx_bankWriteAddrDec[b][w][e];
          entryWriteData[idx] |= entryWriteEn[idx][w] ? sx_writeData[b][w] : '0;
        end
      end

  always_ff @(posedge clock)
    for (int e = 0; e < NUM_ENTRIES; e++)
      if (|entryWriteEn[e]) data[e] <= entryWriteData[e];

  // ===========================================================================
  // 5. 两组 CAM（纯组合，整 16 位相等）
  // ===========================================================================
  always_comb begin
    for (int j = 0; j < NUM_ENTRIES; j++)
      io_releaseMmask[j] = (io_releaseMdata == data[j]);
    for (int c = 0; c < NUM_VIO_CAM; c++)
      for (int j = 0; j < NUM_ENTRIES; j++)
        io_releaseViolationMmask[c][j] = (io_releaseViolationMdata[c] == data[j]);
  end

endmodule


// -----------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden 逐位同名同序，只做展平/改名
// （scripts/gen_lqrar.py 生成，勿手改）
// -----------------------------------------------------------------------------
// BEGIN GENERATED(lqpaddr-wrapper)
module LqPAddrModule(
  input         clock,
  input         reset,
  input         io_wen_0,
  input         io_wen_1,
  input         io_wen_2,
  input  [6:0]  io_waddr_0,
  input  [6:0]  io_waddr_1,
  input  [6:0]  io_waddr_2,
  input  [15:0] io_wdata_0,
  input  [15:0] io_wdata_1,
  input  [15:0] io_wdata_2,
  input  [15:0] io_releaseMdata_2,
  output        io_releaseMmask_2_0,
  output        io_releaseMmask_2_1,
  output        io_releaseMmask_2_2,
  output        io_releaseMmask_2_3,
  output        io_releaseMmask_2_4,
  output        io_releaseMmask_2_5,
  output        io_releaseMmask_2_6,
  output        io_releaseMmask_2_7,
  output        io_releaseMmask_2_8,
  output        io_releaseMmask_2_9,
  output        io_releaseMmask_2_10,
  output        io_releaseMmask_2_11,
  output        io_releaseMmask_2_12,
  output        io_releaseMmask_2_13,
  output        io_releaseMmask_2_14,
  output        io_releaseMmask_2_15,
  output        io_releaseMmask_2_16,
  output        io_releaseMmask_2_17,
  output        io_releaseMmask_2_18,
  output        io_releaseMmask_2_19,
  output        io_releaseMmask_2_20,
  output        io_releaseMmask_2_21,
  output        io_releaseMmask_2_22,
  output        io_releaseMmask_2_23,
  output        io_releaseMmask_2_24,
  output        io_releaseMmask_2_25,
  output        io_releaseMmask_2_26,
  output        io_releaseMmask_2_27,
  output        io_releaseMmask_2_28,
  output        io_releaseMmask_2_29,
  output        io_releaseMmask_2_30,
  output        io_releaseMmask_2_31,
  output        io_releaseMmask_2_32,
  output        io_releaseMmask_2_33,
  output        io_releaseMmask_2_34,
  output        io_releaseMmask_2_35,
  output        io_releaseMmask_2_36,
  output        io_releaseMmask_2_37,
  output        io_releaseMmask_2_38,
  output        io_releaseMmask_2_39,
  output        io_releaseMmask_2_40,
  output        io_releaseMmask_2_41,
  output        io_releaseMmask_2_42,
  output        io_releaseMmask_2_43,
  output        io_releaseMmask_2_44,
  output        io_releaseMmask_2_45,
  output        io_releaseMmask_2_46,
  output        io_releaseMmask_2_47,
  output        io_releaseMmask_2_48,
  output        io_releaseMmask_2_49,
  output        io_releaseMmask_2_50,
  output        io_releaseMmask_2_51,
  output        io_releaseMmask_2_52,
  output        io_releaseMmask_2_53,
  output        io_releaseMmask_2_54,
  output        io_releaseMmask_2_55,
  output        io_releaseMmask_2_56,
  output        io_releaseMmask_2_57,
  output        io_releaseMmask_2_58,
  output        io_releaseMmask_2_59,
  output        io_releaseMmask_2_60,
  output        io_releaseMmask_2_61,
  output        io_releaseMmask_2_62,
  output        io_releaseMmask_2_63,
  output        io_releaseMmask_2_64,
  output        io_releaseMmask_2_65,
  output        io_releaseMmask_2_66,
  output        io_releaseMmask_2_67,
  output        io_releaseMmask_2_68,
  output        io_releaseMmask_2_69,
  output        io_releaseMmask_2_70,
  output        io_releaseMmask_2_71,
  input  [15:0] io_releaseViolationMdata_0,
  input  [15:0] io_releaseViolationMdata_1,
  input  [15:0] io_releaseViolationMdata_2,
  output        io_releaseViolationMmask_0_0,
  output        io_releaseViolationMmask_0_1,
  output        io_releaseViolationMmask_0_2,
  output        io_releaseViolationMmask_0_3,
  output        io_releaseViolationMmask_0_4,
  output        io_releaseViolationMmask_0_5,
  output        io_releaseViolationMmask_0_6,
  output        io_releaseViolationMmask_0_7,
  output        io_releaseViolationMmask_0_8,
  output        io_releaseViolationMmask_0_9,
  output        io_releaseViolationMmask_0_10,
  output        io_releaseViolationMmask_0_11,
  output        io_releaseViolationMmask_0_12,
  output        io_releaseViolationMmask_0_13,
  output        io_releaseViolationMmask_0_14,
  output        io_releaseViolationMmask_0_15,
  output        io_releaseViolationMmask_0_16,
  output        io_releaseViolationMmask_0_17,
  output        io_releaseViolationMmask_0_18,
  output        io_releaseViolationMmask_0_19,
  output        io_releaseViolationMmask_0_20,
  output        io_releaseViolationMmask_0_21,
  output        io_releaseViolationMmask_0_22,
  output        io_releaseViolationMmask_0_23,
  output        io_releaseViolationMmask_0_24,
  output        io_releaseViolationMmask_0_25,
  output        io_releaseViolationMmask_0_26,
  output        io_releaseViolationMmask_0_27,
  output        io_releaseViolationMmask_0_28,
  output        io_releaseViolationMmask_0_29,
  output        io_releaseViolationMmask_0_30,
  output        io_releaseViolationMmask_0_31,
  output        io_releaseViolationMmask_0_32,
  output        io_releaseViolationMmask_0_33,
  output        io_releaseViolationMmask_0_34,
  output        io_releaseViolationMmask_0_35,
  output        io_releaseViolationMmask_0_36,
  output        io_releaseViolationMmask_0_37,
  output        io_releaseViolationMmask_0_38,
  output        io_releaseViolationMmask_0_39,
  output        io_releaseViolationMmask_0_40,
  output        io_releaseViolationMmask_0_41,
  output        io_releaseViolationMmask_0_42,
  output        io_releaseViolationMmask_0_43,
  output        io_releaseViolationMmask_0_44,
  output        io_releaseViolationMmask_0_45,
  output        io_releaseViolationMmask_0_46,
  output        io_releaseViolationMmask_0_47,
  output        io_releaseViolationMmask_0_48,
  output        io_releaseViolationMmask_0_49,
  output        io_releaseViolationMmask_0_50,
  output        io_releaseViolationMmask_0_51,
  output        io_releaseViolationMmask_0_52,
  output        io_releaseViolationMmask_0_53,
  output        io_releaseViolationMmask_0_54,
  output        io_releaseViolationMmask_0_55,
  output        io_releaseViolationMmask_0_56,
  output        io_releaseViolationMmask_0_57,
  output        io_releaseViolationMmask_0_58,
  output        io_releaseViolationMmask_0_59,
  output        io_releaseViolationMmask_0_60,
  output        io_releaseViolationMmask_0_61,
  output        io_releaseViolationMmask_0_62,
  output        io_releaseViolationMmask_0_63,
  output        io_releaseViolationMmask_0_64,
  output        io_releaseViolationMmask_0_65,
  output        io_releaseViolationMmask_0_66,
  output        io_releaseViolationMmask_0_67,
  output        io_releaseViolationMmask_0_68,
  output        io_releaseViolationMmask_0_69,
  output        io_releaseViolationMmask_0_70,
  output        io_releaseViolationMmask_0_71,
  output        io_releaseViolationMmask_1_0,
  output        io_releaseViolationMmask_1_1,
  output        io_releaseViolationMmask_1_2,
  output        io_releaseViolationMmask_1_3,
  output        io_releaseViolationMmask_1_4,
  output        io_releaseViolationMmask_1_5,
  output        io_releaseViolationMmask_1_6,
  output        io_releaseViolationMmask_1_7,
  output        io_releaseViolationMmask_1_8,
  output        io_releaseViolationMmask_1_9,
  output        io_releaseViolationMmask_1_10,
  output        io_releaseViolationMmask_1_11,
  output        io_releaseViolationMmask_1_12,
  output        io_releaseViolationMmask_1_13,
  output        io_releaseViolationMmask_1_14,
  output        io_releaseViolationMmask_1_15,
  output        io_releaseViolationMmask_1_16,
  output        io_releaseViolationMmask_1_17,
  output        io_releaseViolationMmask_1_18,
  output        io_releaseViolationMmask_1_19,
  output        io_releaseViolationMmask_1_20,
  output        io_releaseViolationMmask_1_21,
  output        io_releaseViolationMmask_1_22,
  output        io_releaseViolationMmask_1_23,
  output        io_releaseViolationMmask_1_24,
  output        io_releaseViolationMmask_1_25,
  output        io_releaseViolationMmask_1_26,
  output        io_releaseViolationMmask_1_27,
  output        io_releaseViolationMmask_1_28,
  output        io_releaseViolationMmask_1_29,
  output        io_releaseViolationMmask_1_30,
  output        io_releaseViolationMmask_1_31,
  output        io_releaseViolationMmask_1_32,
  output        io_releaseViolationMmask_1_33,
  output        io_releaseViolationMmask_1_34,
  output        io_releaseViolationMmask_1_35,
  output        io_releaseViolationMmask_1_36,
  output        io_releaseViolationMmask_1_37,
  output        io_releaseViolationMmask_1_38,
  output        io_releaseViolationMmask_1_39,
  output        io_releaseViolationMmask_1_40,
  output        io_releaseViolationMmask_1_41,
  output        io_releaseViolationMmask_1_42,
  output        io_releaseViolationMmask_1_43,
  output        io_releaseViolationMmask_1_44,
  output        io_releaseViolationMmask_1_45,
  output        io_releaseViolationMmask_1_46,
  output        io_releaseViolationMmask_1_47,
  output        io_releaseViolationMmask_1_48,
  output        io_releaseViolationMmask_1_49,
  output        io_releaseViolationMmask_1_50,
  output        io_releaseViolationMmask_1_51,
  output        io_releaseViolationMmask_1_52,
  output        io_releaseViolationMmask_1_53,
  output        io_releaseViolationMmask_1_54,
  output        io_releaseViolationMmask_1_55,
  output        io_releaseViolationMmask_1_56,
  output        io_releaseViolationMmask_1_57,
  output        io_releaseViolationMmask_1_58,
  output        io_releaseViolationMmask_1_59,
  output        io_releaseViolationMmask_1_60,
  output        io_releaseViolationMmask_1_61,
  output        io_releaseViolationMmask_1_62,
  output        io_releaseViolationMmask_1_63,
  output        io_releaseViolationMmask_1_64,
  output        io_releaseViolationMmask_1_65,
  output        io_releaseViolationMmask_1_66,
  output        io_releaseViolationMmask_1_67,
  output        io_releaseViolationMmask_1_68,
  output        io_releaseViolationMmask_1_69,
  output        io_releaseViolationMmask_1_70,
  output        io_releaseViolationMmask_1_71,
  output        io_releaseViolationMmask_2_0,
  output        io_releaseViolationMmask_2_1,
  output        io_releaseViolationMmask_2_2,
  output        io_releaseViolationMmask_2_3,
  output        io_releaseViolationMmask_2_4,
  output        io_releaseViolationMmask_2_5,
  output        io_releaseViolationMmask_2_6,
  output        io_releaseViolationMmask_2_7,
  output        io_releaseViolationMmask_2_8,
  output        io_releaseViolationMmask_2_9,
  output        io_releaseViolationMmask_2_10,
  output        io_releaseViolationMmask_2_11,
  output        io_releaseViolationMmask_2_12,
  output        io_releaseViolationMmask_2_13,
  output        io_releaseViolationMmask_2_14,
  output        io_releaseViolationMmask_2_15,
  output        io_releaseViolationMmask_2_16,
  output        io_releaseViolationMmask_2_17,
  output        io_releaseViolationMmask_2_18,
  output        io_releaseViolationMmask_2_19,
  output        io_releaseViolationMmask_2_20,
  output        io_releaseViolationMmask_2_21,
  output        io_releaseViolationMmask_2_22,
  output        io_releaseViolationMmask_2_23,
  output        io_releaseViolationMmask_2_24,
  output        io_releaseViolationMmask_2_25,
  output        io_releaseViolationMmask_2_26,
  output        io_releaseViolationMmask_2_27,
  output        io_releaseViolationMmask_2_28,
  output        io_releaseViolationMmask_2_29,
  output        io_releaseViolationMmask_2_30,
  output        io_releaseViolationMmask_2_31,
  output        io_releaseViolationMmask_2_32,
  output        io_releaseViolationMmask_2_33,
  output        io_releaseViolationMmask_2_34,
  output        io_releaseViolationMmask_2_35,
  output        io_releaseViolationMmask_2_36,
  output        io_releaseViolationMmask_2_37,
  output        io_releaseViolationMmask_2_38,
  output        io_releaseViolationMmask_2_39,
  output        io_releaseViolationMmask_2_40,
  output        io_releaseViolationMmask_2_41,
  output        io_releaseViolationMmask_2_42,
  output        io_releaseViolationMmask_2_43,
  output        io_releaseViolationMmask_2_44,
  output        io_releaseViolationMmask_2_45,
  output        io_releaseViolationMmask_2_46,
  output        io_releaseViolationMmask_2_47,
  output        io_releaseViolationMmask_2_48,
  output        io_releaseViolationMmask_2_49,
  output        io_releaseViolationMmask_2_50,
  output        io_releaseViolationMmask_2_51,
  output        io_releaseViolationMmask_2_52,
  output        io_releaseViolationMmask_2_53,
  output        io_releaseViolationMmask_2_54,
  output        io_releaseViolationMmask_2_55,
  output        io_releaseViolationMmask_2_56,
  output        io_releaseViolationMmask_2_57,
  output        io_releaseViolationMmask_2_58,
  output        io_releaseViolationMmask_2_59,
  output        io_releaseViolationMmask_2_60,
  output        io_releaseViolationMmask_2_61,
  output        io_releaseViolationMmask_2_62,
  output        io_releaseViolationMmask_2_63,
  output        io_releaseViolationMmask_2_64,
  output        io_releaseViolationMmask_2_65,
  output        io_releaseViolationMmask_2_66,
  output        io_releaseViolationMmask_2_67,
  output        io_releaseViolationMmask_2_68,
  output        io_releaseViolationMmask_2_69,
  output        io_releaseViolationMmask_2_70,
  output        io_releaseViolationMmask_2_71
);
  // reset 只被 golden `ifndef SYNTHESIS 的写冲突断言用到，综合视图里悬空。
  logic [6:0] waddr [3];
  logic [15:0] wdata [3];
  logic [15:0] vioMdata [3];
  logic [71:0] releaseMmask;
  logic [71:0] vioMmask [3];

  assign waddr[0] = io_waddr_0;
  assign waddr[1] = io_waddr_1;
  assign waddr[2] = io_waddr_2;
  assign wdata[0] = io_wdata_0;
  assign wdata[1] = io_wdata_1;
  assign wdata[2] = io_wdata_2;
  assign vioMdata[0] = io_releaseViolationMdata_0;
  assign vioMdata[1] = io_releaseViolationMdata_1;
  assign vioMdata[2] = io_releaseViolationMdata_2;

  xs_LqPAddrModule_core #(
    .NUM_ENTRIES (72),
    .DATA_W      (16),
    .NUM_WRITE   (3),
    .NUM_WBANK   (8),
    .NUM_VIO_CAM (3)
  ) u_core (
    .clock                    (clock),
    .io_wen                   ({io_wen_2, io_wen_1, io_wen_0}),
    .io_waddr                 (waddr),
    .io_wdata                 (wdata),
    .io_releaseMdata          (io_releaseMdata_2),
    .io_releaseMmask          (releaseMmask),
    .io_releaseViolationMdata (vioMdata),
    .io_releaseViolationMmask (vioMmask)
  );

  assign io_releaseMmask_2_0 = releaseMmask[0];
  assign io_releaseMmask_2_1 = releaseMmask[1];
  assign io_releaseMmask_2_2 = releaseMmask[2];
  assign io_releaseMmask_2_3 = releaseMmask[3];
  assign io_releaseMmask_2_4 = releaseMmask[4];
  assign io_releaseMmask_2_5 = releaseMmask[5];
  assign io_releaseMmask_2_6 = releaseMmask[6];
  assign io_releaseMmask_2_7 = releaseMmask[7];
  assign io_releaseMmask_2_8 = releaseMmask[8];
  assign io_releaseMmask_2_9 = releaseMmask[9];
  assign io_releaseMmask_2_10 = releaseMmask[10];
  assign io_releaseMmask_2_11 = releaseMmask[11];
  assign io_releaseMmask_2_12 = releaseMmask[12];
  assign io_releaseMmask_2_13 = releaseMmask[13];
  assign io_releaseMmask_2_14 = releaseMmask[14];
  assign io_releaseMmask_2_15 = releaseMmask[15];
  assign io_releaseMmask_2_16 = releaseMmask[16];
  assign io_releaseMmask_2_17 = releaseMmask[17];
  assign io_releaseMmask_2_18 = releaseMmask[18];
  assign io_releaseMmask_2_19 = releaseMmask[19];
  assign io_releaseMmask_2_20 = releaseMmask[20];
  assign io_releaseMmask_2_21 = releaseMmask[21];
  assign io_releaseMmask_2_22 = releaseMmask[22];
  assign io_releaseMmask_2_23 = releaseMmask[23];
  assign io_releaseMmask_2_24 = releaseMmask[24];
  assign io_releaseMmask_2_25 = releaseMmask[25];
  assign io_releaseMmask_2_26 = releaseMmask[26];
  assign io_releaseMmask_2_27 = releaseMmask[27];
  assign io_releaseMmask_2_28 = releaseMmask[28];
  assign io_releaseMmask_2_29 = releaseMmask[29];
  assign io_releaseMmask_2_30 = releaseMmask[30];
  assign io_releaseMmask_2_31 = releaseMmask[31];
  assign io_releaseMmask_2_32 = releaseMmask[32];
  assign io_releaseMmask_2_33 = releaseMmask[33];
  assign io_releaseMmask_2_34 = releaseMmask[34];
  assign io_releaseMmask_2_35 = releaseMmask[35];
  assign io_releaseMmask_2_36 = releaseMmask[36];
  assign io_releaseMmask_2_37 = releaseMmask[37];
  assign io_releaseMmask_2_38 = releaseMmask[38];
  assign io_releaseMmask_2_39 = releaseMmask[39];
  assign io_releaseMmask_2_40 = releaseMmask[40];
  assign io_releaseMmask_2_41 = releaseMmask[41];
  assign io_releaseMmask_2_42 = releaseMmask[42];
  assign io_releaseMmask_2_43 = releaseMmask[43];
  assign io_releaseMmask_2_44 = releaseMmask[44];
  assign io_releaseMmask_2_45 = releaseMmask[45];
  assign io_releaseMmask_2_46 = releaseMmask[46];
  assign io_releaseMmask_2_47 = releaseMmask[47];
  assign io_releaseMmask_2_48 = releaseMmask[48];
  assign io_releaseMmask_2_49 = releaseMmask[49];
  assign io_releaseMmask_2_50 = releaseMmask[50];
  assign io_releaseMmask_2_51 = releaseMmask[51];
  assign io_releaseMmask_2_52 = releaseMmask[52];
  assign io_releaseMmask_2_53 = releaseMmask[53];
  assign io_releaseMmask_2_54 = releaseMmask[54];
  assign io_releaseMmask_2_55 = releaseMmask[55];
  assign io_releaseMmask_2_56 = releaseMmask[56];
  assign io_releaseMmask_2_57 = releaseMmask[57];
  assign io_releaseMmask_2_58 = releaseMmask[58];
  assign io_releaseMmask_2_59 = releaseMmask[59];
  assign io_releaseMmask_2_60 = releaseMmask[60];
  assign io_releaseMmask_2_61 = releaseMmask[61];
  assign io_releaseMmask_2_62 = releaseMmask[62];
  assign io_releaseMmask_2_63 = releaseMmask[63];
  assign io_releaseMmask_2_64 = releaseMmask[64];
  assign io_releaseMmask_2_65 = releaseMmask[65];
  assign io_releaseMmask_2_66 = releaseMmask[66];
  assign io_releaseMmask_2_67 = releaseMmask[67];
  assign io_releaseMmask_2_68 = releaseMmask[68];
  assign io_releaseMmask_2_69 = releaseMmask[69];
  assign io_releaseMmask_2_70 = releaseMmask[70];
  assign io_releaseMmask_2_71 = releaseMmask[71];
  assign io_releaseViolationMmask_0_0 = vioMmask[0][0];
  assign io_releaseViolationMmask_0_1 = vioMmask[0][1];
  assign io_releaseViolationMmask_0_2 = vioMmask[0][2];
  assign io_releaseViolationMmask_0_3 = vioMmask[0][3];
  assign io_releaseViolationMmask_0_4 = vioMmask[0][4];
  assign io_releaseViolationMmask_0_5 = vioMmask[0][5];
  assign io_releaseViolationMmask_0_6 = vioMmask[0][6];
  assign io_releaseViolationMmask_0_7 = vioMmask[0][7];
  assign io_releaseViolationMmask_0_8 = vioMmask[0][8];
  assign io_releaseViolationMmask_0_9 = vioMmask[0][9];
  assign io_releaseViolationMmask_0_10 = vioMmask[0][10];
  assign io_releaseViolationMmask_0_11 = vioMmask[0][11];
  assign io_releaseViolationMmask_0_12 = vioMmask[0][12];
  assign io_releaseViolationMmask_0_13 = vioMmask[0][13];
  assign io_releaseViolationMmask_0_14 = vioMmask[0][14];
  assign io_releaseViolationMmask_0_15 = vioMmask[0][15];
  assign io_releaseViolationMmask_0_16 = vioMmask[0][16];
  assign io_releaseViolationMmask_0_17 = vioMmask[0][17];
  assign io_releaseViolationMmask_0_18 = vioMmask[0][18];
  assign io_releaseViolationMmask_0_19 = vioMmask[0][19];
  assign io_releaseViolationMmask_0_20 = vioMmask[0][20];
  assign io_releaseViolationMmask_0_21 = vioMmask[0][21];
  assign io_releaseViolationMmask_0_22 = vioMmask[0][22];
  assign io_releaseViolationMmask_0_23 = vioMmask[0][23];
  assign io_releaseViolationMmask_0_24 = vioMmask[0][24];
  assign io_releaseViolationMmask_0_25 = vioMmask[0][25];
  assign io_releaseViolationMmask_0_26 = vioMmask[0][26];
  assign io_releaseViolationMmask_0_27 = vioMmask[0][27];
  assign io_releaseViolationMmask_0_28 = vioMmask[0][28];
  assign io_releaseViolationMmask_0_29 = vioMmask[0][29];
  assign io_releaseViolationMmask_0_30 = vioMmask[0][30];
  assign io_releaseViolationMmask_0_31 = vioMmask[0][31];
  assign io_releaseViolationMmask_0_32 = vioMmask[0][32];
  assign io_releaseViolationMmask_0_33 = vioMmask[0][33];
  assign io_releaseViolationMmask_0_34 = vioMmask[0][34];
  assign io_releaseViolationMmask_0_35 = vioMmask[0][35];
  assign io_releaseViolationMmask_0_36 = vioMmask[0][36];
  assign io_releaseViolationMmask_0_37 = vioMmask[0][37];
  assign io_releaseViolationMmask_0_38 = vioMmask[0][38];
  assign io_releaseViolationMmask_0_39 = vioMmask[0][39];
  assign io_releaseViolationMmask_0_40 = vioMmask[0][40];
  assign io_releaseViolationMmask_0_41 = vioMmask[0][41];
  assign io_releaseViolationMmask_0_42 = vioMmask[0][42];
  assign io_releaseViolationMmask_0_43 = vioMmask[0][43];
  assign io_releaseViolationMmask_0_44 = vioMmask[0][44];
  assign io_releaseViolationMmask_0_45 = vioMmask[0][45];
  assign io_releaseViolationMmask_0_46 = vioMmask[0][46];
  assign io_releaseViolationMmask_0_47 = vioMmask[0][47];
  assign io_releaseViolationMmask_0_48 = vioMmask[0][48];
  assign io_releaseViolationMmask_0_49 = vioMmask[0][49];
  assign io_releaseViolationMmask_0_50 = vioMmask[0][50];
  assign io_releaseViolationMmask_0_51 = vioMmask[0][51];
  assign io_releaseViolationMmask_0_52 = vioMmask[0][52];
  assign io_releaseViolationMmask_0_53 = vioMmask[0][53];
  assign io_releaseViolationMmask_0_54 = vioMmask[0][54];
  assign io_releaseViolationMmask_0_55 = vioMmask[0][55];
  assign io_releaseViolationMmask_0_56 = vioMmask[0][56];
  assign io_releaseViolationMmask_0_57 = vioMmask[0][57];
  assign io_releaseViolationMmask_0_58 = vioMmask[0][58];
  assign io_releaseViolationMmask_0_59 = vioMmask[0][59];
  assign io_releaseViolationMmask_0_60 = vioMmask[0][60];
  assign io_releaseViolationMmask_0_61 = vioMmask[0][61];
  assign io_releaseViolationMmask_0_62 = vioMmask[0][62];
  assign io_releaseViolationMmask_0_63 = vioMmask[0][63];
  assign io_releaseViolationMmask_0_64 = vioMmask[0][64];
  assign io_releaseViolationMmask_0_65 = vioMmask[0][65];
  assign io_releaseViolationMmask_0_66 = vioMmask[0][66];
  assign io_releaseViolationMmask_0_67 = vioMmask[0][67];
  assign io_releaseViolationMmask_0_68 = vioMmask[0][68];
  assign io_releaseViolationMmask_0_69 = vioMmask[0][69];
  assign io_releaseViolationMmask_0_70 = vioMmask[0][70];
  assign io_releaseViolationMmask_0_71 = vioMmask[0][71];
  assign io_releaseViolationMmask_1_0 = vioMmask[1][0];
  assign io_releaseViolationMmask_1_1 = vioMmask[1][1];
  assign io_releaseViolationMmask_1_2 = vioMmask[1][2];
  assign io_releaseViolationMmask_1_3 = vioMmask[1][3];
  assign io_releaseViolationMmask_1_4 = vioMmask[1][4];
  assign io_releaseViolationMmask_1_5 = vioMmask[1][5];
  assign io_releaseViolationMmask_1_6 = vioMmask[1][6];
  assign io_releaseViolationMmask_1_7 = vioMmask[1][7];
  assign io_releaseViolationMmask_1_8 = vioMmask[1][8];
  assign io_releaseViolationMmask_1_9 = vioMmask[1][9];
  assign io_releaseViolationMmask_1_10 = vioMmask[1][10];
  assign io_releaseViolationMmask_1_11 = vioMmask[1][11];
  assign io_releaseViolationMmask_1_12 = vioMmask[1][12];
  assign io_releaseViolationMmask_1_13 = vioMmask[1][13];
  assign io_releaseViolationMmask_1_14 = vioMmask[1][14];
  assign io_releaseViolationMmask_1_15 = vioMmask[1][15];
  assign io_releaseViolationMmask_1_16 = vioMmask[1][16];
  assign io_releaseViolationMmask_1_17 = vioMmask[1][17];
  assign io_releaseViolationMmask_1_18 = vioMmask[1][18];
  assign io_releaseViolationMmask_1_19 = vioMmask[1][19];
  assign io_releaseViolationMmask_1_20 = vioMmask[1][20];
  assign io_releaseViolationMmask_1_21 = vioMmask[1][21];
  assign io_releaseViolationMmask_1_22 = vioMmask[1][22];
  assign io_releaseViolationMmask_1_23 = vioMmask[1][23];
  assign io_releaseViolationMmask_1_24 = vioMmask[1][24];
  assign io_releaseViolationMmask_1_25 = vioMmask[1][25];
  assign io_releaseViolationMmask_1_26 = vioMmask[1][26];
  assign io_releaseViolationMmask_1_27 = vioMmask[1][27];
  assign io_releaseViolationMmask_1_28 = vioMmask[1][28];
  assign io_releaseViolationMmask_1_29 = vioMmask[1][29];
  assign io_releaseViolationMmask_1_30 = vioMmask[1][30];
  assign io_releaseViolationMmask_1_31 = vioMmask[1][31];
  assign io_releaseViolationMmask_1_32 = vioMmask[1][32];
  assign io_releaseViolationMmask_1_33 = vioMmask[1][33];
  assign io_releaseViolationMmask_1_34 = vioMmask[1][34];
  assign io_releaseViolationMmask_1_35 = vioMmask[1][35];
  assign io_releaseViolationMmask_1_36 = vioMmask[1][36];
  assign io_releaseViolationMmask_1_37 = vioMmask[1][37];
  assign io_releaseViolationMmask_1_38 = vioMmask[1][38];
  assign io_releaseViolationMmask_1_39 = vioMmask[1][39];
  assign io_releaseViolationMmask_1_40 = vioMmask[1][40];
  assign io_releaseViolationMmask_1_41 = vioMmask[1][41];
  assign io_releaseViolationMmask_1_42 = vioMmask[1][42];
  assign io_releaseViolationMmask_1_43 = vioMmask[1][43];
  assign io_releaseViolationMmask_1_44 = vioMmask[1][44];
  assign io_releaseViolationMmask_1_45 = vioMmask[1][45];
  assign io_releaseViolationMmask_1_46 = vioMmask[1][46];
  assign io_releaseViolationMmask_1_47 = vioMmask[1][47];
  assign io_releaseViolationMmask_1_48 = vioMmask[1][48];
  assign io_releaseViolationMmask_1_49 = vioMmask[1][49];
  assign io_releaseViolationMmask_1_50 = vioMmask[1][50];
  assign io_releaseViolationMmask_1_51 = vioMmask[1][51];
  assign io_releaseViolationMmask_1_52 = vioMmask[1][52];
  assign io_releaseViolationMmask_1_53 = vioMmask[1][53];
  assign io_releaseViolationMmask_1_54 = vioMmask[1][54];
  assign io_releaseViolationMmask_1_55 = vioMmask[1][55];
  assign io_releaseViolationMmask_1_56 = vioMmask[1][56];
  assign io_releaseViolationMmask_1_57 = vioMmask[1][57];
  assign io_releaseViolationMmask_1_58 = vioMmask[1][58];
  assign io_releaseViolationMmask_1_59 = vioMmask[1][59];
  assign io_releaseViolationMmask_1_60 = vioMmask[1][60];
  assign io_releaseViolationMmask_1_61 = vioMmask[1][61];
  assign io_releaseViolationMmask_1_62 = vioMmask[1][62];
  assign io_releaseViolationMmask_1_63 = vioMmask[1][63];
  assign io_releaseViolationMmask_1_64 = vioMmask[1][64];
  assign io_releaseViolationMmask_1_65 = vioMmask[1][65];
  assign io_releaseViolationMmask_1_66 = vioMmask[1][66];
  assign io_releaseViolationMmask_1_67 = vioMmask[1][67];
  assign io_releaseViolationMmask_1_68 = vioMmask[1][68];
  assign io_releaseViolationMmask_1_69 = vioMmask[1][69];
  assign io_releaseViolationMmask_1_70 = vioMmask[1][70];
  assign io_releaseViolationMmask_1_71 = vioMmask[1][71];
  assign io_releaseViolationMmask_2_0 = vioMmask[2][0];
  assign io_releaseViolationMmask_2_1 = vioMmask[2][1];
  assign io_releaseViolationMmask_2_2 = vioMmask[2][2];
  assign io_releaseViolationMmask_2_3 = vioMmask[2][3];
  assign io_releaseViolationMmask_2_4 = vioMmask[2][4];
  assign io_releaseViolationMmask_2_5 = vioMmask[2][5];
  assign io_releaseViolationMmask_2_6 = vioMmask[2][6];
  assign io_releaseViolationMmask_2_7 = vioMmask[2][7];
  assign io_releaseViolationMmask_2_8 = vioMmask[2][8];
  assign io_releaseViolationMmask_2_9 = vioMmask[2][9];
  assign io_releaseViolationMmask_2_10 = vioMmask[2][10];
  assign io_releaseViolationMmask_2_11 = vioMmask[2][11];
  assign io_releaseViolationMmask_2_12 = vioMmask[2][12];
  assign io_releaseViolationMmask_2_13 = vioMmask[2][13];
  assign io_releaseViolationMmask_2_14 = vioMmask[2][14];
  assign io_releaseViolationMmask_2_15 = vioMmask[2][15];
  assign io_releaseViolationMmask_2_16 = vioMmask[2][16];
  assign io_releaseViolationMmask_2_17 = vioMmask[2][17];
  assign io_releaseViolationMmask_2_18 = vioMmask[2][18];
  assign io_releaseViolationMmask_2_19 = vioMmask[2][19];
  assign io_releaseViolationMmask_2_20 = vioMmask[2][20];
  assign io_releaseViolationMmask_2_21 = vioMmask[2][21];
  assign io_releaseViolationMmask_2_22 = vioMmask[2][22];
  assign io_releaseViolationMmask_2_23 = vioMmask[2][23];
  assign io_releaseViolationMmask_2_24 = vioMmask[2][24];
  assign io_releaseViolationMmask_2_25 = vioMmask[2][25];
  assign io_releaseViolationMmask_2_26 = vioMmask[2][26];
  assign io_releaseViolationMmask_2_27 = vioMmask[2][27];
  assign io_releaseViolationMmask_2_28 = vioMmask[2][28];
  assign io_releaseViolationMmask_2_29 = vioMmask[2][29];
  assign io_releaseViolationMmask_2_30 = vioMmask[2][30];
  assign io_releaseViolationMmask_2_31 = vioMmask[2][31];
  assign io_releaseViolationMmask_2_32 = vioMmask[2][32];
  assign io_releaseViolationMmask_2_33 = vioMmask[2][33];
  assign io_releaseViolationMmask_2_34 = vioMmask[2][34];
  assign io_releaseViolationMmask_2_35 = vioMmask[2][35];
  assign io_releaseViolationMmask_2_36 = vioMmask[2][36];
  assign io_releaseViolationMmask_2_37 = vioMmask[2][37];
  assign io_releaseViolationMmask_2_38 = vioMmask[2][38];
  assign io_releaseViolationMmask_2_39 = vioMmask[2][39];
  assign io_releaseViolationMmask_2_40 = vioMmask[2][40];
  assign io_releaseViolationMmask_2_41 = vioMmask[2][41];
  assign io_releaseViolationMmask_2_42 = vioMmask[2][42];
  assign io_releaseViolationMmask_2_43 = vioMmask[2][43];
  assign io_releaseViolationMmask_2_44 = vioMmask[2][44];
  assign io_releaseViolationMmask_2_45 = vioMmask[2][45];
  assign io_releaseViolationMmask_2_46 = vioMmask[2][46];
  assign io_releaseViolationMmask_2_47 = vioMmask[2][47];
  assign io_releaseViolationMmask_2_48 = vioMmask[2][48];
  assign io_releaseViolationMmask_2_49 = vioMmask[2][49];
  assign io_releaseViolationMmask_2_50 = vioMmask[2][50];
  assign io_releaseViolationMmask_2_51 = vioMmask[2][51];
  assign io_releaseViolationMmask_2_52 = vioMmask[2][52];
  assign io_releaseViolationMmask_2_53 = vioMmask[2][53];
  assign io_releaseViolationMmask_2_54 = vioMmask[2][54];
  assign io_releaseViolationMmask_2_55 = vioMmask[2][55];
  assign io_releaseViolationMmask_2_56 = vioMmask[2][56];
  assign io_releaseViolationMmask_2_57 = vioMmask[2][57];
  assign io_releaseViolationMmask_2_58 = vioMmask[2][58];
  assign io_releaseViolationMmask_2_59 = vioMmask[2][59];
  assign io_releaseViolationMmask_2_60 = vioMmask[2][60];
  assign io_releaseViolationMmask_2_61 = vioMmask[2][61];
  assign io_releaseViolationMmask_2_62 = vioMmask[2][62];
  assign io_releaseViolationMmask_2_63 = vioMmask[2][63];
  assign io_releaseViolationMmask_2_64 = vioMmask[2][64];
  assign io_releaseViolationMmask_2_65 = vioMmask[2][65];
  assign io_releaseViolationMmask_2_66 = vioMmask[2][66];
  assign io_releaseViolationMmask_2_67 = vioMmask[2][67];
  assign io_releaseViolationMmask_2_68 = vioMmask[2][68];
  assign io_releaseViolationMmask_2_69 = vioMmask[2][69];
  assign io_releaseViolationMmask_2_70 = vioMmask[2][70];
  assign io_releaseViolationMmask_2_71 = vioMmask[2][71];
endmodule
// END GENERATED
