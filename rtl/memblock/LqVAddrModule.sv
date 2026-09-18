// =============================================================================
// LqVAddrModule —— LoadQueueReplay 的虚地址数据阵列（72 项 × 50 位）
//
// 对应 Chisel: xiangshan.mem.LqVAddrModule（实体逻辑全在基类 LqRawDataModule，
// 见 src/main/scala/xiangshan/mem/lsqueue/LoadQueueData.scala）。
//
// 在流水线里的位置：LoadQueueReplay 每收下一条待重放的 load，就把它的虚地址
// （VAddrBits=50 位）按队列槽位号写进本阵列；重放发射时按槽位号读回。它是一块
// "多写口 + 多读口 + 写通路打拍"的寄存器堆，不是 SRAM。
//
// 端口（3 读 / 3 写，地址 7 位寻址 72 项）：
//   ren/raddr  → rdata ：读使能 + 读地址，**读数据打一拍**（RegEnable）后给出。
//   wen/waddr/wdata    ：写使能 + 写地址 + 写数据。
//
// 核心机制 —— 写通路为什么要分 bank 再打拍：
//   写地址先译码成 one-hot（UIntToOH，宽度 128 = 2^7），再按 bank 切片成 8 段
//   × 9 项。每个 bank 对每个写口各自保存一份"打过拍的写使能 / 写地址译码 /
//   写数据"（numWDelay=2 ⇒ 延迟 numWDelay-1 = 1 拍），下一拍才真正写进条目寄存器。
//   这样做的目的是把"一个 72 项 × 50 位阵列的 3 口写"拆成 8 组 9 项的局部写，
//   缩短写译码的扇出/走线；代价是写数据要在每个 bank 各存一份。
//   ★ 每 bank 一份写数据延迟件是 golden 的真实结构（8×3=24 个 50 位延迟件，
//     其中同一写口的 8 份内容恒等）。这是冗余但**不许合并**：合并会改掉模块的
//     寄存器集合（24 份变 3 份），FM 上就是 21×50 个对不上的比较点。
//
// 三个延迟件按 golden 同名例化，各只有一个寄存器：
//   DelayN_13           1 位、1 拍、无使能（延迟 bank 写使能）
//   DelayNWithValid_152 9 位、1 拍、valid 使能（延迟 bank 内写地址译码）
//   DelayNWithValid_155 50 位、1 拍、valid 使能（延迟写数据）
// 它们在 FM 里两侧同源 elaborate（不设黑盒），理由见 verif/ut/LqVAddrModule/Makefile。
// DelayN_13 在本仓另有独立重写目标 rtl/common/DelayN_13.sv；另两个尚未重写。
//
// ★ 复位域：本模块 **75 个寄存器（72 项数据 + 3 个读数据寄存器）全部不复位**
//   （Chisel 用 Reg/RegEnable 而非 RegInit）。golden 的 always 块是
//   `always @(posedge clock)`，没有 reset 分支。端口上的 reset 只被
//   `ifndef SYNTHESIS 的写冲突断言用到，综合视图里悬空。照抄成带复位是真 bug。
// =============================================================================
package lqvaddr_pkg;

  localparam int NUM_ENTRIES = 72;  // 队列槽位数（= LoadQueueReplay 条目数）
  localparam int DATA_WIDTH  = 50;  // VAddrBits
  localparam int NUM_READ    = 3;   // 读口数
  localparam int NUM_WRITE   = 3;   // 写口数
  localparam int NUM_WBANK   = 8;   // 写 bank 数（numEntries 必须整除）
  localparam int NUM_WDELAY  = 2;   // 写延迟级数；实际延迟件深度 = NUM_WDELAY-1

  localparam int ADDR_W   = $clog2(NUM_ENTRIES);      // 7
  localparam int PER_BANK = NUM_ENTRIES / NUM_WBANK;  // 9 项/bank
  // UIntToOH(waddr) 的宽度由地址位宽决定，是 2^ADDR_W = 128 而不是 NUM_ENTRIES。
  // 高 56 位恒为 0（waddr < 72 时），但 bank 切片只取到第 71 位，用不到它们。
  localparam int DEC_W    = 1 << ADDR_W;              // 128

endpackage

// -----------------------------------------------------------------------------
// xs_LqVAddrModule_core —— 可读核
// -----------------------------------------------------------------------------
module xs_LqVAddrModule_core
  import lqvaddr_pkg::*;
(
  input  logic                    clock,

  // 读口：读地址当拍给出，读数据下一拍有效（ren 为读数据寄存器的使能）
  input  logic [NUM_READ-1:0]     io_ren,
  input  logic [ADDR_W-1:0]       io_raddr [NUM_READ],
  output logic [DATA_WIDTH-1:0]   io_rdata [NUM_READ],

  // 写口：wen/waddr/wdata 当拍给出，经 1 拍延迟后写入条目
  input  logic [NUM_WRITE-1:0]    io_wen,
  input  logic [ADDR_W-1:0]       io_waddr [NUM_WRITE],
  input  logic [DATA_WIDTH-1:0]   io_wdata [NUM_WRITE]
);

  // ===========================================================================
  // 1. 条目存储（不复位）
  // ===========================================================================
  logic [DATA_WIDTH-1:0] data [NUM_ENTRIES];

  // ===========================================================================
  // 2. 写地址译码 + 分 bank
  // ===========================================================================
  // writeAddrDec[w] = UIntToOH(waddr[w])，128 位
  logic [DEC_W-1:0] writeAddrDec [NUM_WRITE];
  always_comb
    for (int w = 0; w < NUM_WRITE; w++)
      writeAddrDec[w] = DEC_W'(1) << io_waddr[w];

  // s0（当拍）：bank b 内的 9 位译码片 + 该 bank 是否被写口 w 命中
  logic [PER_BANK-1:0] s0_bankWriteAddrDec [NUM_WBANK][NUM_WRITE];
  logic                s0_bankWriteEn      [NUM_WBANK][NUM_WRITE];
  always_comb
    for (int b = 0; b < NUM_WBANK; b++)
      for (int w = 0; w < NUM_WRITE; w++) begin
        s0_bankWriteAddrDec[b][w] = writeAddrDec[w][b*PER_BANK +: PER_BANK];
        s0_bankWriteEn[b][w]      = io_wen[w] & (|s0_bankWriteAddrDec[b][w]);
      end

  // ===========================================================================
  // 3. 写通路打拍（NUM_WDELAY-1 = 1 拍），每 bank 各存一份
  // ===========================================================================
  logic [PER_BANK-1:0]   sx_bankWriteAddrDec [NUM_WBANK][NUM_WRITE];
  logic                  sx_bankWriteEn      [NUM_WBANK][NUM_WRITE];
  logic [DATA_WIDTH-1:0] sx_writeData        [NUM_WBANK][NUM_WRITE];

  for (genvar b = 0; b < NUM_WBANK; b++) begin : g_bank
    for (genvar w = 0; w < NUM_WRITE; w++) begin : g_wport
      // 写地址译码片：valid 用 io_wen（wen 为 0 时保持上次值，与写使能一起失效）
      DelayNWithValid_152 sx_bankWriteAddrDec_resp_pipMod (
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
      // 写数据：与 bank 无关，但 golden 每 bank 各例化一份，照抄（见文件头说明）
      DelayNWithValid_155 sx_writeData_resp_pipMod (
        .clock       (clock),
        .io_in_bits  (io_wdata[w]),
        .io_in_valid (io_wen[w]),
        .io_out_bits (sx_writeData[b][w])
      );
    end
  end

  // ===========================================================================
  // 4. 条目写入
  // ---------------------------------------------------------------------------
  // 每个条目由所在 bank 的 3 个写口竞争。Chisel 用 Mux1H：多个写口同拍命中同一
  // 条目时结果是**按位或**，不是优先级选择。上游（LoadQueueReplay）保证写地址
  // 互不相同（golden 里有对应的非综合断言），所以正常情况下至多一个写口命中。
  // ★ 这里必须照抄"或"语义：写成优先级选择在正常激励下值相同，但 FM 会失配。
  // ===========================================================================
  logic [NUM_WRITE-1:0]  entryWriteEn   [NUM_ENTRIES];
  logic [DATA_WIDTH-1:0] entryWriteData [NUM_ENTRIES];
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

  // ===========================================================================
  // 5. 读口
  // ---------------------------------------------------------------------------
  // ★ 越界读语义：raddr 是 7 位（0..127），条目只有 72 个。firtool 把 Chisel 的
  //   Vec 读展开成 128 项查找表，其中 72..127 这 56 项**全部填 data[0]**，不是 0。
  //   本设计上游不会给出越界地址，但按"查不到就是 0"写会与 golden 失配。
  // ===========================================================================
  //   写法上这里**不用变量下标**，而是"默认取第 0 项 + 逐项常量比较覆盖"——
  //   它就是 golden 那张 128 项查找表的字面形状。用 data[io_raddr[i]] 写会让
  //   Formality 报 FMR_ELAB-147（Index may take values outside array bound）：
  //   FM 不把外面那个 `< NUM_ENTRIES` 守卫传播进下标，set_top 直接失败。
  logic [DATA_WIDTH-1:0] readSel [NUM_READ];
  always_comb
    for (int i = 0; i < NUM_READ; i++) begin
      readSel[i] = data[0];                           // 越界（72..127）的填充项
      for (int e = 1; e < NUM_ENTRIES; e++)
        if (io_raddr[i] == ADDR_W'(e)) readSel[i] = data[e];
    end

  // ===========================================================================
  // 6. 时序（全部无复位）
  // ===========================================================================
  always_ff @(posedge clock) begin
    for (int e = 0; e < NUM_ENTRIES; e++)
      if (|entryWriteEn[e]) data[e] <= entryWriteData[e];
    for (int i = 0; i < NUM_READ; i++)
      if (io_ren[i]) io_rdata[i] <= readSel[i];
  end

endmodule

// -----------------------------------------------------------------------------
// golden 同名 wrapper —— 端口与 G1 golden 逐位对齐，只做展平/改名
// -----------------------------------------------------------------------------
module LqVAddrModule(
  input         clock,
  input         reset,
  input         io_ren_0,
  input         io_ren_1,
  input         io_ren_2,
  input  [6:0]  io_raddr_0,
  input  [6:0]  io_raddr_1,
  input  [6:0]  io_raddr_2,
  output [49:0] io_rdata_0,
  output [49:0] io_rdata_1,
  output [49:0] io_rdata_2,
  input         io_wen_0,
  input         io_wen_1,
  input         io_wen_2,
  input  [6:0]  io_waddr_0,
  input  [6:0]  io_waddr_1,
  input  [6:0]  io_waddr_2,
  input  [49:0] io_wdata_0,
  input  [49:0] io_wdata_1,
  input  [49:0] io_wdata_2
);
  // reset 在综合视图里没有负载：golden 只在 `ifndef SYNTHESIS 的写冲突断言里
  // 用它（assert(!(wen(i) && wen(j) && waddr(i)===waddr(j)))），所有寄存器都不复位。
  // 保留端口是为了与 golden 端口表逐位一致。
  logic [6:0]  raddr [3];
  logic [49:0] rdata [3];
  logic [6:0]  waddr [3];
  logic [49:0] wdata [3];

  assign raddr[0] = io_raddr_0;  assign raddr[1] = io_raddr_1;  assign raddr[2] = io_raddr_2;
  assign waddr[0] = io_waddr_0;  assign waddr[1] = io_waddr_1;  assign waddr[2] = io_waddr_2;
  assign wdata[0] = io_wdata_0;  assign wdata[1] = io_wdata_1;  assign wdata[2] = io_wdata_2;
  assign io_rdata_0 = rdata[0];
  assign io_rdata_1 = rdata[1];
  assign io_rdata_2 = rdata[2];

  xs_LqVAddrModule_core u_core (
    .clock    (clock),
    .io_ren   ({io_ren_2, io_ren_1, io_ren_0}),
    .io_raddr (raddr),
    .io_rdata (rdata),
    .io_wen   ({io_wen_2, io_wen_1, io_wen_0}),
    .io_waddr (waddr),
    .io_wdata (wdata)
  );
endmodule
