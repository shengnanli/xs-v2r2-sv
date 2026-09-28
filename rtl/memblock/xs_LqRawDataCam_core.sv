// =============================================================================
// xs_LqRawDataCam_core —— LoadQueueRAW 的两块 CAM 数据阵列共用的可读核
//                         （LqMaskModule / LqPAddrModule_1 两个薄 wrapper 例化本核）
//
// 对应 Chisel: xiangshan.mem.LqRawDataModule（基类，写通路）+ 子类 LqMaskModule /
// LqPAddrModule 的 violation CAM（src/main/scala/xiangshan/mem/lsqueue/LoadQueueData.scala）。
//
// 在流水线里的位置：LoadQueueRAW 为"已经拿到数据、但前面还有地址未就绪的 store"的
// load 各分配一个槽（32 项）。每个槽要记两样东西供 store 来查：
//   · LqPAddrModule_1：load 的**部分物理地址** paddr[27:4]（24 位，按 16B 对齐）；
//   · LqMaskModule   ：load 在那 16B 里读了哪些字节（16 位字节掩码）。
// store 写回时带着自己的 paddr/mask 来"反查"（CAM）：同一 16B 且字节有交叠的 load
// 就是读早了的 RAW 违例候选。两块阵列各出一张 32 位命中向量，父模块逐位相与。
//
// 端口：3 写口（每条 load 流水各一个）+ 2 CAM 口（每条 store 流水各一个）。
//   golden 里读口（ren/raddr/rdata）与 release CAM 都被 firtool 消掉了（父模块没接），
//   所以本核只有写通路与 violation CAM。
//
// 核心机制一 —— 写通路分 bank 再打一拍（与 LqVAddrModule 同一套基类逻辑）：
//   写地址译成 32 位 one-hot，按 8 个 bank × 4 项切片。每个 bank 对每个写口各存一份
//   打过拍的"bank 写使能 / bank 内地址译码 / 写数据"（numWDelay=2 ⇒ 延迟 1 拍），
//   下一拍才真正写进条目。★写数据每 bank 各一份（8×3=24 个延迟件，同一写口的 8 份
//   内容恒等）是 golden 的真实结构，不许合并：合并会改掉寄存器集合，FM 上就是
//   21×DATA_W 个对不上的比较点。
//   同拍多个写口命中同一条目时 Chisel 用 Mux1H ⇒ 结果是各口数据**按位或**
//   （上游保证不撞，golden 仅有非综合断言）。照抄"或"，不能写成优先级。
//
// 核心机制二 —— violation CAM（组合，当拍出结果），两种比较规则由参数 LINE_CAM 选：
//   LINE_CAM=0（LqMaskModule）   ：hit = |(mdata & data[j])          —— 字节掩码有交叠
//   LINE_CAM=1（LqPAddrModule_1）：hit = mdata[高位]==data[j][高位]   —— 同一 cacheline
//                                  && (checkLine || mdata[低位]==data[j][低位]) —— 且同一 16B
//     低位宽 = DCacheLineOffset(6) - paddrOffset(4) = 2：cacheline 64B 里的 16B 块号。
//     checkLine=1 表示这条 store 写整条 cacheline（cbo.zero），此时只比 cacheline。
//
// 三个延迟件按 golden 同名例化（都是本仓已签核的重写件，各只有一级寄存器、无复位）：
//   DelayN_13                          1 位，无使能（bank 写使能）
//   DelayNWithValid_52                 4 位，valid 使能（bank 内 4 项的地址译码）
//   DelayNWithValid_103 / _55          16 / 24 位，valid 使能（写数据）
//   写数据延迟件的**模块名**随位宽不同（firtool 按位宽去重命名），SV 不能把模块名
//   作参数，所以按 DATA_W 在 generate 里二选一；其它位宽没有对应的 golden 件，直接报错。
//
// ★复位域：本核 32 个条目寄存器**全部不复位**（Chisel `Reg(Vec(...))`），延迟件也不复位。
//   wrapper 端口上的 reset 只被 golden `ifndef SYNTHESIS 的写冲突断言用到。
// =============================================================================
module xs_LqRawDataCam_core #(
  parameter int NUM_ENTRIES = 32,    // LoadQueueRAWSize
  parameter int DATA_W      = 16,    // 条目宽度：mask 16 位 / 部分 paddr 24 位
  parameter int NUM_WRITE   = 3,     // LoadPipelineWidth
  parameter int NUM_WBANK   = 8,     // LoadQueueNWriteBanks
  parameter int NUM_CAM     = 2,     // StorePipelineWidth
  parameter bit LINE_CAM    = 1'b0,  // 0: 掩码交叠 CAM；1: 地址 CAM（带 cacheline 整行检查）
  parameter int LINE_LOW_W  = 2,     // LINE_CAM=1 时：cacheline 内 16B 块号的位数
  parameter int ADDR_W      = $clog2(NUM_ENTRIES)
) (
  input  logic                   clock,

  // 写口：wen/waddr/wdata 当拍给出，经 1 拍延迟后写入条目
  input  logic [NUM_WRITE-1:0]   io_wen,
  input  logic [ADDR_W-1:0]      io_waddr [NUM_WRITE],
  input  logic [DATA_W-1:0]      io_wdata [NUM_WRITE],

  // violation CAM：每个 store 口一份查询数据，出一张 NUM_ENTRIES 位命中向量
  input  logic [DATA_W-1:0]      io_violationMdata     [NUM_CAM],
  input  logic [NUM_CAM-1:0]     io_violationCheckLine,           // 仅 LINE_CAM=1 使用
  output logic [NUM_ENTRIES-1:0] io_violationMmask     [NUM_CAM]
);

  localparam int PER_BANK = NUM_ENTRIES / NUM_WBANK;  // 4 项/bank
  localparam int DEC_W    = 1 << ADDR_W;              // UIntToOH 宽度 = 2^ADDR_W = 32

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

  // bank b 内的 4 位译码片，以及"写口 w 这拍写的是不是 bank b"
  logic [PER_BANK-1:0] s0_bankWriteAddrDec [NUM_WBANK][NUM_WRITE];
  logic                s0_bankWriteEn      [NUM_WBANK][NUM_WRITE];
  always_comb
    for (int b = 0; b < NUM_WBANK; b++)
      for (int w = 0; w < NUM_WRITE; w++) begin
        s0_bankWriteAddrDec[b][w] = writeAddrDec[w][b*PER_BANK +: PER_BANK];
        s0_bankWriteEn[b][w]      = io_wen[w] & (|s0_bankWriteAddrDec[b][w]);
      end

  // ===========================================================================
  // 3. 写通路打拍（sx = 打过 1 拍），每 bank 各存一份
  // ===========================================================================
  logic [PER_BANK-1:0] sx_bankWriteAddrDec [NUM_WBANK][NUM_WRITE];
  logic                sx_bankWriteEn      [NUM_WBANK][NUM_WRITE];
  logic [DATA_W-1:0]   sx_writeData        [NUM_WBANK][NUM_WRITE];

  for (genvar b = 0; b < NUM_WBANK; b++) begin : g_bank
    for (genvar w = 0; w < NUM_WRITE; w++) begin : g_wport
      // bank 内地址译码：valid=io_wen（wen=0 时保持旧值，与写使能一起失效）
      DelayNWithValid_52 sx_bankWriteAddrDec_resp_pipMod (
        .clock       (clock),
        .io_in_bits  (s0_bankWriteAddrDec[b][w]),
        .io_in_valid (io_wen[w]),
        .io_out_bits (sx_bankWriteAddrDec[b][w])
      );
      // bank 写使能：无使能的纯 1 拍延迟
      DelayN_13 sx_bankWriteEn_delay (
        .clock  (clock),
        .io_in  (s0_bankWriteEn[b][w]),
        .io_out (sx_bankWriteEn[b][w])
      );
      // 写数据：与 bank 无关，但 golden 每 bank 各例化一份，照抄（见文件头）
      if (DATA_W == 16) begin : g_wdata
        DelayNWithValid_103 sx_writeData_resp_pipMod (
          .clock       (clock),
          .io_in_bits  (io_wdata[w]),
          .io_in_valid (io_wen[w]),
          .io_out_bits (sx_writeData[b][w])
        );
      end else if (DATA_W == 24) begin : g_wdata
        DelayNWithValid_55 sx_writeData_resp_pipMod (
          .clock       (clock),
          .io_in_bits  (io_wdata[w]),
          .io_in_valid (io_wen[w]),
          .io_out_bits (sx_writeData[b][w])
        );
      end else begin : g_wdata_unsupported
        initial $fatal(1, "xs_LqRawDataCam_core: DATA_W=%0d 没有对应的 golden 写数据延迟件", DATA_W);
      end
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
  // 5. violation CAM（纯组合）
  // ===========================================================================
  always_comb
    for (int c = 0; c < NUM_CAM; c++)
      for (int j = 0; j < NUM_ENTRIES; j++)
        if (LINE_CAM)
          // 同一 cacheline（高位相等）且（整行写 或 同一 16B 块）
          io_violationMmask[c][j] =
              (io_violationMdata[c][DATA_W-1:LINE_LOW_W] == data[j][DATA_W-1:LINE_LOW_W])
            & (io_violationCheckLine[c]
               | (io_violationMdata[c][LINE_LOW_W-1:0] == data[j][LINE_LOW_W-1:0]));
        else
          // 字节掩码有任何一位交叠
          io_violationMmask[c][j] = |(io_violationMdata[c] & data[j]);

endmodule
