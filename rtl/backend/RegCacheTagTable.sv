// =============================================================================
// RegCacheTagTable —— RegCache tag 表顶层（Int / Mem 两个半区 + 作废判决）
//
// 对应 Chisel: xiangshan.backend.regcache.RegCacheTagTable
// 位置：Backend / NewDispatch 里。Dispatch 要知道「这条指令的源寄存器 pdest 是不是
//       正躺在 RegCache 里、在哪一条」，本模块就是那张查询表。它自己不存数据，
//       只存 tag(=pdest) 与依赖信息，数据在 rtl/backend/RegCache.sv。
//
// 结构：两个 xs_RegCacheTagModule_core 实例（与 golden 的实例名一致）
//   IntRCTagTable : 16 条目 / 4 写口（Int 侧 4 个 0 延迟唤醒源）
//   MemRCTagTable : 12 条目 / 3 写口（Mem 侧 3 个 load/store 流水）
// 读口 12 个**同时广播给两个半区**，命中哪边由输出 valid 决定；返回的 5 位
// RegCacheIdx = {是否 Mem 半区, 半区内 4 位下标}。
//
// 本层真正的逻辑只有三条式子（其余都是 12/16 份的复制）：
//   1) 写使能   wen[w] = valid & rfWen & 未被 load 取消 & 未被 og0 取消
//   2) 作废位   cancel[e] = (被新分配的 preg 撞号 | 被本拍写口撞号 | load 取消命中
//                            该条目的依赖) & 该条目有效
//   3) 读结果   valid = (Int 命中 | Mem 命中) & 该 tag 没有正被重新分配
//               addr  = Int 命中 ? {0, Int 下标} : {1, Mem 下标}
//
// ★三个"只能从 golden 读出来、Chisel 里看不出"的点（都在下面注释里逐条标了）★
//   a) Int 写口 2/3 的 is0Lat 被折成常数 1，Mem 三个写口的 og0Cancel 项整个消失；
//   b) 写进半区的 loadDependency 先左移一位（{dep[0], 1'b0}）；
//   c) 写口地址取 rcDest 的低 4 位，第 5 位（半区选择）在这里是冗余的。
// =============================================================================

module xs_RegCacheTagTable_core #(
  parameter int unsigned NUM_READ    = 12,  // 读口数
  parameter int unsigned NUM_WAKEUP  = 7,   // 唤醒源数 = Int 4 + Mem 3
  parameter int unsigned INT_WR      = 4,   // 前 INT_WR 个唤醒源写 Int 半区
  parameter int unsigned NUM_ALLOC   = 6,   // 每拍重命名分配的 preg 数（Rename 宽度）
  parameter int unsigned NUM_LDCANCEL= 3,   // load 取消通道数 = load unit 数
  parameter int unsigned INT_ENTRIES = 16,
  parameter int unsigned MEM_ENTRIES = 12,
  parameter int unsigned TAG_WIDTH   = 8,   // pdest 位宽
  parameter int unsigned HALF_ADDR_W = 4,   // 半区内下标位宽
  parameter int unsigned IDX_WIDTH   = 5,   // 对外 RegCacheIdx = 1 + HALF_ADDR_W
  parameter int unsigned LDEP_WIDTH  = 2
)(
  input  logic clock,
  input  logic reset,

  // ---- 12 个查询口（Dispatch 的源操作数）----
  input  logic [NUM_READ-1:0]                 io_read_ren,
  input  logic [NUM_READ-1:0][TAG_WIDTH-1:0]  io_read_tag,
  output logic [NUM_READ-1:0]                 io_read_valid,
  output logic [NUM_READ-1:0][IDX_WIDTH-1:0]  io_read_addr,

  // ---- 唤醒总线：谁把自己的结果写进了 RegCache 的哪一条 ----
  input  logic [NUM_WAKEUP-1:0]                                  io_wakeup_valid,
  input  logic [NUM_WAKEUP-1:0]                                  io_wakeup_rfWen,
  input  logic [NUM_WAKEUP-1:0][TAG_WIDTH-1:0]                   io_wakeup_pdest,
  input  logic [NUM_WAKEUP-1:0][NUM_LDCANCEL-1:0][LDEP_WIDTH-1:0] io_wakeup_loadDependency,
  input  logic [NUM_WAKEUP-1:0]                                  io_wakeup_is0Lat,
  input  logic [NUM_WAKEUP-1:0][IDX_WIDTH-1:0]                   io_wakeup_rcDest,

  // ---- 两路取消：og0（发射级撤销，只对 0 延迟唤醒有意义）与 load 取消 ----
  input  logic [NUM_WAKEUP-1:0]                io_og0Cancel,
  input  logic [NUM_LDCANCEL-1:0]              io_ldCancel,

  // ---- 重命名新分配的 preg：老条目的 tag 撞上就必须作废（号被复用了）----
  input  logic [NUM_ALLOC-1:0]                 io_allocPregs_valid,
  input  logic [NUM_ALLOC-1:0][TAG_WIDTH-1:0]  io_allocPregs_bits
);

  localparam int unsigned MEM_WR = NUM_WAKEUP - INT_WR;

  // ---------------------------------------------------------------------------
  // 1. 写使能：唤醒有效 & 真写整数寄存器 & 两种取消都没发生
  //
  //    load 取消：唤醒自带的 loadDependency[k] 的高位为 1，表示"本结果依赖第 k 个
  //    load，而那个 load 正好在本拍宣告失败" —— 结果作废，不许进 RegCache。
  //    og0 取消：只对 0 延迟唤醒（is0Lat）有意义；★golden 实测★ Int 写口 2/3 的
  //    is0Lat 被常量折叠成 1（golden 写成裸的 `& ~og0Cancel_4/6`），Mem 三个写口
  //    则连 og0Cancel 项都没有（该乘积恒 0）。按 Chisel 默认把 is0Lat 当 0 处理，
  //    会把 Int 口 2/3 的 og0 取消整条噤声 —— 是真 bug，不是良性差异。
  // ---------------------------------------------------------------------------
  logic [NUM_WAKEUP-1:0] wakeupWen;

  always_comb begin
    for (int w = 0; w < int'(NUM_WAKEUP); w++) begin
      automatic logic ldKilled = 1'b0;
      for (int k = 0; k < int'(NUM_LDCANCEL); k++)
        ldKilled |= io_ldCancel[k] & io_wakeup_loadDependency[w][k][LDEP_WIDTH-1];
      wakeupWen[w] = io_wakeup_valid[w] & io_wakeup_rfWen[w]
                   & ~ldKilled
                   & ~(io_wakeup_is0Lat[w] & io_og0Cancel[w]);
    end
  end

  // 写进条目的依赖先左移一位：唤醒总线上的 dep 是"发射那一拍"的相位，存进表里要
  // 对齐到"下一拍"。golden 写作 {dep[0], 1'h0}，高位被挤掉。
  logic [NUM_WAKEUP-1:0][NUM_LDCANCEL-1:0][LDEP_WIDTH-1:0] wakeupDepAged;

  always_comb
    for (int w = 0; w < int'(NUM_WAKEUP); w++)
      for (int k = 0; k < int'(NUM_LDCANCEL); k++)
        wakeupDepAged[w][k] = {io_wakeup_loadDependency[w][k][LDEP_WIDTH-2:0], 1'b0};

  // 写口地址 = rcDest 的低 4 位。rcDest 的最高位是半区选择，而写口本来就固定属于
  // 某个半区，所以那一位在这里是冗余的 —— golden 也只取 [3:0]。
  logic [NUM_WAKEUP-1:0][HALF_ADDR_W-1:0] wakeupAddr;
  always_comb
    for (int w = 0; w < int'(NUM_WAKEUP); w++)
      wakeupAddr[w] = io_wakeup_rcDest[w][HALF_ADDR_W-1:0];

  // ---------------------------------------------------------------------------
  // 2. 两个半区实例 + 各自的作废判决
  //    作废三因：① 该 tag(pdest) 本拍被重命名重新分配出去了（号被复用）；
  //              ② 该 tag 本拍被某个写口重新写入（同号换条目，老条目让位）；
  //              ③ 该条目依赖的 load 本拍宣告失败。
  //    三者都只在条目本来就有效时才算数。
  // ---------------------------------------------------------------------------
  logic [INT_ENTRIES-1:0]                                     intValidVec, intCancel;
  logic [INT_ENTRIES-1:0][TAG_WIDTH-1:0]                      intTagVec;
  logic [INT_ENTRIES-1:0][NUM_LDCANCEL-1:0][LDEP_WIDTH-1:0]   intDepVec;
  logic [MEM_ENTRIES-1:0]                                     memValidVec, memCancel;
  logic [MEM_ENTRIES-1:0][TAG_WIDTH-1:0]                      memTagVec;
  logic [MEM_ENTRIES-1:0][NUM_LDCANCEL-1:0][LDEP_WIDTH-1:0]   memDepVec;

  // 同一条作废式子在两个半区各算一遍；写成 function 让两处只维护一份语义。
  function automatic logic entryCancel(
      input logic                                  entryValid,
      input logic [TAG_WIDTH-1:0]                  entryTag,
      input logic [NUM_LDCANCEL-1:0][LDEP_WIDTH-1:0] entryDep,
      input int                                    wrLo,   // 本半区写口对应的唤醒源区间
      input int                                    wrHi);
    logic hit;
    hit = 1'b0;
    for (int a = 0; a < int'(NUM_ALLOC); a++)
      hit |= io_allocPregs_valid[a] & (io_allocPregs_bits[a] == entryTag);
    for (int w = wrLo; w < wrHi; w++)
      hit |= wakeupWen[w] & (io_wakeup_pdest[w] == entryTag);
    for (int k = 0; k < int'(NUM_LDCANCEL); k++)
      hit |= io_ldCancel[k] & entryDep[k][LDEP_WIDTH-1];
    return hit & entryValid;
  endfunction

  always_comb begin
    for (int e = 0; e < int'(INT_ENTRIES); e++)
      intCancel[e] = entryCancel(intValidVec[e], intTagVec[e], intDepVec[e], 0, INT_WR);
    for (int e = 0; e < int'(MEM_ENTRIES); e++)
      memCancel[e] = entryCancel(memValidVec[e], memTagVec[e], memDepVec[e],
                                 INT_WR, NUM_WAKEUP);
  end

  logic [NUM_READ-1:0]                  intHit, memHit;
  logic [NUM_READ-1:0][HALF_ADDR_W-1:0] intAddr, memAddr;

  xs_RegCacheTagModule_core #(
    .NUM_ENTRIES(INT_ENTRIES), .NUM_WRITE(INT_WR), .NUM_READ(NUM_READ),
    .TAG_WIDTH(TAG_WIDTH), .NUM_LDEP(NUM_LDCANCEL), .LDEP_WIDTH(LDEP_WIDTH),
    .ADDR_WIDTH(HALF_ADDR_W)
  ) IntRCTagTable (
    .clock                  (clock),
    .reset                  (reset),
    .io_read_ren            (io_read_ren),
    .io_read_tag            (io_read_tag),
    .io_read_valid          (intHit),
    .io_read_addr           (intAddr),
    .io_write_wen           (wakeupWen    [INT_WR-1:0]),
    .io_write_addr          (wakeupAddr   [INT_WR-1:0]),
    .io_write_tag           (io_wakeup_pdest[INT_WR-1:0]),
    .io_write_loadDependency(wakeupDepAged[INT_WR-1:0]),
    .io_cancelVec           (intCancel),
    .io_validVec            (intValidVec),
    .io_tagVec              (intTagVec),
    .io_loadDependencyVec   (intDepVec)
  );

  xs_RegCacheTagModule_core #(
    .NUM_ENTRIES(MEM_ENTRIES), .NUM_WRITE(MEM_WR), .NUM_READ(NUM_READ),
    .TAG_WIDTH(TAG_WIDTH), .NUM_LDEP(NUM_LDCANCEL), .LDEP_WIDTH(LDEP_WIDTH),
    .ADDR_WIDTH(HALF_ADDR_W),
    // Mem 半区写口 w 的第 w 组依赖是常数（见核里 SELF_DEP_DIAG 的说明）。忘了置位
    // 它会怎样：实测 UT 第 8 拍就失配 —— 依赖值错 ⇒ ldCancel 判据错 ⇒ cancelVec 错。
    .SELF_DEP_DIAG(1'b1)
  ) MemRCTagTable (
    .clock                  (clock),
    .reset                  (reset),
    .io_read_ren            (io_read_ren),
    .io_read_tag            (io_read_tag),
    .io_read_valid          (memHit),
    .io_read_addr           (memAddr),
    .io_write_wen           (wakeupWen    [NUM_WAKEUP-1:INT_WR]),
    .io_write_addr          (wakeupAddr   [NUM_WAKEUP-1:INT_WR]),
    .io_write_tag           (io_wakeup_pdest[NUM_WAKEUP-1:INT_WR]),
    .io_write_loadDependency(wakeupDepAged[NUM_WAKEUP-1:INT_WR]),
    .io_cancelVec           (memCancel),
    .io_validVec            (memValidVec),
    .io_tagVec              (memTagVec),
    .io_loadDependencyVec   (memDepVec)
  );

  // ---------------------------------------------------------------------------
  // 3. 读结果合并
  //    一个 tag 本拍正被重命名重新分配出去时，表里那条即使还在也不能用 —— 这一拍
  //    就要挡掉（半区里的 cancel 要等下一拍才生效）。Int 优先：两个半区不会同时
  //    命中同一个 pdest（同一个号只住一个半区），所以这不是仲裁而是选择。
  // ---------------------------------------------------------------------------
  always_comb begin
    for (int r = 0; r < int'(NUM_READ); r++) begin
      automatic logic reallocating = 1'b0;
      for (int a = 0; a < int'(NUM_ALLOC); a++)
        reallocating |= io_allocPregs_valid[a] & (io_allocPregs_bits[a] == io_read_tag[r]);
      io_read_valid[r] = (intHit[r] | memHit[r]) & ~reallocating;
      io_read_addr[r]  = intHit[r] ? {1'b0, intAddr[r]} : {1'b1, memAddr[r]};
    end
  end

endmodule

// BEGIN GENERATED(wrapper)
module RegCacheTagTable(
  input        clock,
  input        reset,
  input        io_readPorts_0_ren,
  input  [7:0] io_readPorts_0_tag,
  output       io_readPorts_0_valid,
  output [4:0] io_readPorts_0_addr,
  input        io_readPorts_1_ren,
  input  [7:0] io_readPorts_1_tag,
  output       io_readPorts_1_valid,
  output [4:0] io_readPorts_1_addr,
  input        io_readPorts_2_ren,
  input  [7:0] io_readPorts_2_tag,
  output       io_readPorts_2_valid,
  output [4:0] io_readPorts_2_addr,
  input        io_readPorts_3_ren,
  input  [7:0] io_readPorts_3_tag,
  output       io_readPorts_3_valid,
  output [4:0] io_readPorts_3_addr,
  input        io_readPorts_4_ren,
  input  [7:0] io_readPorts_4_tag,
  output       io_readPorts_4_valid,
  output [4:0] io_readPorts_4_addr,
  input        io_readPorts_5_ren,
  input  [7:0] io_readPorts_5_tag,
  output       io_readPorts_5_valid,
  output [4:0] io_readPorts_5_addr,
  input        io_readPorts_6_ren,
  input  [7:0] io_readPorts_6_tag,
  output       io_readPorts_6_valid,
  output [4:0] io_readPorts_6_addr,
  input        io_readPorts_7_ren,
  input  [7:0] io_readPorts_7_tag,
  output       io_readPorts_7_valid,
  output [4:0] io_readPorts_7_addr,
  input        io_readPorts_8_ren,
  input  [7:0] io_readPorts_8_tag,
  output       io_readPorts_8_valid,
  output [4:0] io_readPorts_8_addr,
  input        io_readPorts_9_ren,
  input  [7:0] io_readPorts_9_tag,
  output       io_readPorts_9_valid,
  output [4:0] io_readPorts_9_addr,
  input        io_readPorts_10_ren,
  input  [7:0] io_readPorts_10_tag,
  output       io_readPorts_10_valid,
  output [4:0] io_readPorts_10_addr,
  input        io_readPorts_11_ren,
  input  [7:0] io_readPorts_11_tag,
  output       io_readPorts_11_valid,
  output [4:0] io_readPorts_11_addr,
  input        io_wakeupFromIQ_6_valid,
  input        io_wakeupFromIQ_6_bits_rfWen,
  input  [7:0] io_wakeupFromIQ_6_bits_pdest,
  input  [1:0] io_wakeupFromIQ_6_bits_loadDependency_0,
  input  [1:0] io_wakeupFromIQ_6_bits_loadDependency_1,
  input  [1:0] io_wakeupFromIQ_6_bits_loadDependency_2,
  input  [4:0] io_wakeupFromIQ_6_bits_rcDest,
  input        io_wakeupFromIQ_5_valid,
  input        io_wakeupFromIQ_5_bits_rfWen,
  input  [7:0] io_wakeupFromIQ_5_bits_pdest,
  input  [1:0] io_wakeupFromIQ_5_bits_loadDependency_0,
  input  [1:0] io_wakeupFromIQ_5_bits_loadDependency_1,
  input  [1:0] io_wakeupFromIQ_5_bits_loadDependency_2,
  input  [4:0] io_wakeupFromIQ_5_bits_rcDest,
  input        io_wakeupFromIQ_4_valid,
  input        io_wakeupFromIQ_4_bits_rfWen,
  input  [7:0] io_wakeupFromIQ_4_bits_pdest,
  input  [1:0] io_wakeupFromIQ_4_bits_loadDependency_0,
  input  [1:0] io_wakeupFromIQ_4_bits_loadDependency_1,
  input  [1:0] io_wakeupFromIQ_4_bits_loadDependency_2,
  input  [4:0] io_wakeupFromIQ_4_bits_rcDest,
  input        io_wakeupFromIQ_3_valid,
  input        io_wakeupFromIQ_3_bits_rfWen,
  input  [7:0] io_wakeupFromIQ_3_bits_pdest,
  input  [1:0] io_wakeupFromIQ_3_bits_loadDependency_0,
  input  [1:0] io_wakeupFromIQ_3_bits_loadDependency_1,
  input  [1:0] io_wakeupFromIQ_3_bits_loadDependency_2,
  input  [4:0] io_wakeupFromIQ_3_bits_rcDest,
  input        io_wakeupFromIQ_2_valid,
  input        io_wakeupFromIQ_2_bits_rfWen,
  input  [7:0] io_wakeupFromIQ_2_bits_pdest,
  input  [1:0] io_wakeupFromIQ_2_bits_loadDependency_0,
  input  [1:0] io_wakeupFromIQ_2_bits_loadDependency_1,
  input  [1:0] io_wakeupFromIQ_2_bits_loadDependency_2,
  input  [4:0] io_wakeupFromIQ_2_bits_rcDest,
  input        io_wakeupFromIQ_1_valid,
  input        io_wakeupFromIQ_1_bits_rfWen,
  input  [7:0] io_wakeupFromIQ_1_bits_pdest,
  input  [1:0] io_wakeupFromIQ_1_bits_loadDependency_0,
  input  [1:0] io_wakeupFromIQ_1_bits_loadDependency_1,
  input  [1:0] io_wakeupFromIQ_1_bits_loadDependency_2,
  input        io_wakeupFromIQ_1_bits_is0Lat,
  input  [4:0] io_wakeupFromIQ_1_bits_rcDest,
  input        io_wakeupFromIQ_0_valid,
  input        io_wakeupFromIQ_0_bits_rfWen,
  input  [7:0] io_wakeupFromIQ_0_bits_pdest,
  input  [1:0] io_wakeupFromIQ_0_bits_loadDependency_0,
  input  [1:0] io_wakeupFromIQ_0_bits_loadDependency_1,
  input  [1:0] io_wakeupFromIQ_0_bits_loadDependency_2,
  input        io_wakeupFromIQ_0_bits_is0Lat,
  input  [4:0] io_wakeupFromIQ_0_bits_rcDest,
  input        io_allocPregs_0_valid,
  input  [7:0] io_allocPregs_0_bits,
  input        io_allocPregs_1_valid,
  input  [7:0] io_allocPregs_1_bits,
  input        io_allocPregs_2_valid,
  input  [7:0] io_allocPregs_2_bits,
  input        io_allocPregs_3_valid,
  input  [7:0] io_allocPregs_3_bits,
  input        io_allocPregs_4_valid,
  input  [7:0] io_allocPregs_4_bits,
  input        io_allocPregs_5_valid,
  input  [7:0] io_allocPregs_5_bits,
  input        io_og0Cancel_0,
  input        io_og0Cancel_2,
  input        io_og0Cancel_4,
  input        io_og0Cancel_6,
  input        io_ldCancel_0_ld2Cancel,
  input        io_ldCancel_1_ld2Cancel,
  input        io_ldCancel_2_ld2Cancel
);

  xs_RegCacheTagTable_core u_core (
    .clock                        (clock),
    .reset                        (reset),
    .io_read_ren ({
      io_readPorts_11_ren, io_readPorts_10_ren, io_readPorts_9_ren, io_readPorts_8_ren,
      io_readPorts_7_ren, io_readPorts_6_ren, io_readPorts_5_ren, io_readPorts_4_ren,
      io_readPorts_3_ren, io_readPorts_2_ren, io_readPorts_1_ren, io_readPorts_0_ren
    }),
    .io_read_tag ({
      io_readPorts_11_tag, io_readPorts_10_tag, io_readPorts_9_tag, io_readPorts_8_tag,
      io_readPorts_7_tag, io_readPorts_6_tag, io_readPorts_5_tag, io_readPorts_4_tag,
      io_readPorts_3_tag, io_readPorts_2_tag, io_readPorts_1_tag, io_readPorts_0_tag
    }),
    .io_read_valid ({
      io_readPorts_11_valid, io_readPorts_10_valid, io_readPorts_9_valid, io_readPorts_8_valid,
      io_readPorts_7_valid, io_readPorts_6_valid, io_readPorts_5_valid, io_readPorts_4_valid,
      io_readPorts_3_valid, io_readPorts_2_valid, io_readPorts_1_valid, io_readPorts_0_valid
    }),
    .io_read_addr ({
      io_readPorts_11_addr, io_readPorts_10_addr, io_readPorts_9_addr, io_readPorts_8_addr,
      io_readPorts_7_addr, io_readPorts_6_addr, io_readPorts_5_addr, io_readPorts_4_addr,
      io_readPorts_3_addr, io_readPorts_2_addr, io_readPorts_1_addr, io_readPorts_0_addr
    }),
    .io_wakeup_valid ({
      io_wakeupFromIQ_6_valid, io_wakeupFromIQ_5_valid, io_wakeupFromIQ_4_valid,
      io_wakeupFromIQ_3_valid, io_wakeupFromIQ_2_valid, io_wakeupFromIQ_1_valid,
      io_wakeupFromIQ_0_valid
    }),
    .io_wakeup_rfWen ({
      io_wakeupFromIQ_6_bits_rfWen, io_wakeupFromIQ_5_bits_rfWen, io_wakeupFromIQ_4_bits_rfWen,
      io_wakeupFromIQ_3_bits_rfWen, io_wakeupFromIQ_2_bits_rfWen, io_wakeupFromIQ_1_bits_rfWen,
      io_wakeupFromIQ_0_bits_rfWen
    }),
    .io_wakeup_pdest ({
      io_wakeupFromIQ_6_bits_pdest, io_wakeupFromIQ_5_bits_pdest, io_wakeupFromIQ_4_bits_pdest,
      io_wakeupFromIQ_3_bits_pdest, io_wakeupFromIQ_2_bits_pdest, io_wakeupFromIQ_1_bits_pdest,
      io_wakeupFromIQ_0_bits_pdest
    }),
    .io_wakeup_loadDependency ({
      {io_wakeupFromIQ_6_bits_loadDependency_2, io_wakeupFromIQ_6_bits_loadDependency_1,
      io_wakeupFromIQ_6_bits_loadDependency_0}, {io_wakeupFromIQ_5_bits_loadDependency_2,
      io_wakeupFromIQ_5_bits_loadDependency_1, io_wakeupFromIQ_5_bits_loadDependency_0},
      {io_wakeupFromIQ_4_bits_loadDependency_2, io_wakeupFromIQ_4_bits_loadDependency_1,
      io_wakeupFromIQ_4_bits_loadDependency_0}, {io_wakeupFromIQ_3_bits_loadDependency_2,
      io_wakeupFromIQ_3_bits_loadDependency_1, io_wakeupFromIQ_3_bits_loadDependency_0},
      {io_wakeupFromIQ_2_bits_loadDependency_2, io_wakeupFromIQ_2_bits_loadDependency_1,
      io_wakeupFromIQ_2_bits_loadDependency_0}, {io_wakeupFromIQ_1_bits_loadDependency_2,
      io_wakeupFromIQ_1_bits_loadDependency_1, io_wakeupFromIQ_1_bits_loadDependency_0},
      {io_wakeupFromIQ_0_bits_loadDependency_2, io_wakeupFromIQ_0_bits_loadDependency_1,
      io_wakeupFromIQ_0_bits_loadDependency_0}
    }),
    .io_wakeup_is0Lat ({
      1'b0, 1'b0, 1'b0, 1'b1, 1'b1, io_wakeupFromIQ_1_bits_is0Lat, io_wakeupFromIQ_0_bits_is0Lat
    }),
    .io_wakeup_rcDest ({
      io_wakeupFromIQ_6_bits_rcDest, io_wakeupFromIQ_5_bits_rcDest,
      io_wakeupFromIQ_4_bits_rcDest, io_wakeupFromIQ_3_bits_rcDest,
      io_wakeupFromIQ_2_bits_rcDest, io_wakeupFromIQ_1_bits_rcDest, io_wakeupFromIQ_0_bits_rcDest
    }),
    .io_og0Cancel ({
      1'b0, 1'b0, 1'b0, io_og0Cancel_6, io_og0Cancel_4, io_og0Cancel_2, io_og0Cancel_0
    }),
    .io_ldCancel ({
      io_ldCancel_2_ld2Cancel, io_ldCancel_1_ld2Cancel, io_ldCancel_0_ld2Cancel
    }),
    .io_allocPregs_valid ({
      io_allocPregs_5_valid, io_allocPregs_4_valid, io_allocPregs_3_valid, io_allocPregs_2_valid,
      io_allocPregs_1_valid, io_allocPregs_0_valid
    }),
    .io_allocPregs_bits ({
      io_allocPregs_5_bits, io_allocPregs_4_bits, io_allocPregs_3_bits, io_allocPregs_2_bits,
      io_allocPregs_1_bits, io_allocPregs_0_bits
    })
  );

endmodule
// END GENERATED
