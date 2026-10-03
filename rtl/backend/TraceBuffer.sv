// =============================================================================
// TraceBuffer.sv —— RISC-V 指令跟踪（Trace）的提交块压缩缓冲
// -----------------------------------------------------------------------------
// 设计源: XiangShan src/main/scala/xiangshan/backend/trace/TraceBuffer.scala
// golden 对照: G1-canonical/golden-rtl/TraceBuffer.sv（1,184 行）
// 层次位置: SimTop…backend.inner.ctrlBlock.trace.traceBuffer
//
// ★ 它是什么 ★
// Rob 每拍最多提交 CommitWidth=8 个「块」（block：一段连续提交的指令，带 itype /
// iretire 计数 / ilastsize 与 ftq 位置）。编码器每拍只能吃 TraceGroupNum=3 组，且
// 只关心带控制流类型（itype != None）的块。本模块把一拍里的 8 个块压缩：
//   needPc(i) = 块 i 有效 且 (itype 非 None 或 它右边再没有有效块) 且 未阻塞
//   —— 不需要 PC 的块把自己的 iretire 累加进右邻，ftq 位置也顺延给右邻
//      （blocksUpdate：iretire 前缀累加、ftqIdx/ftqOffset 沿用左邻）。
// 需要 PC 的块按 popcount 前缀算出槽位 enqPtr + count - 1 写进 8 项环形缓冲
// traceEntries；每拍从 deqPtr 起最多取 3 项给 pcMem/编码器。
// 阻塞：编码器使能时，若 enq/deq 指针拉开距离（本拍取不完）或编码器 stall，
// 下一拍 blockCommit=1 反压 Rob（同时 needPc 全清、不再入队）。
//
// ★ golden 事实 ★
//   - traceEntries 8 项 **无复位**；enqPtr/deqPtr/blockCommit 异步复位 0；
//     deqPtrPre(=RegNext(deqPtr)) 无复位。
//   - 同一槽位被多个块命中时下标大的块赢（Chisel 顺序 for 里后连接者优先）。
//   - 写入 traceEntries 的 valid/itype/ilastsize 取原始输入，iretire/ftqIdx/ftqOffset
//     取压缩后的 blocksUpdate（块 0 没有左邻，全取原始输入）。
//   - deqPtrNext = min(deqPtr+3, enqPtrNext)（按环形指针序比较）。
//   - 出队读 traceEntries 用的是 deqPtrPre（上一拍的 deqPtr），有效条件是
//     deqPtrPre+i 在 enqPtr 之前；无效时各字段给 0。
// =============================================================================

package tracebuffer_pkg;
  localparam int unsigned COMMIT_W  = 8;   // CommitWidth
  localparam int unsigned GROUP_N   = 3;   // TraceGroupNum
  localparam int unsigned FTQ_IDX_W = 6;
  localparam int unsigned FTQ_OFF_W = 4;
  localparam int unsigned ITYPE_W   = 4;
  localparam int unsigned IRETIRE_W = 7;   // IretireWidthCompressed
  localparam int unsigned PTR_W     = 3;   // log2(COMMIT_W)

  // 环形指针（utility.CircularQueuePtr，entries = 8）
  typedef struct packed {
    logic             flag;
    logic [PTR_W-1:0] value;
  } trace_ptr_t;

  // 一个提交块的跟踪信息（不含 iaddr）
  typedef struct packed {
    logic [FTQ_IDX_W-1:0] ftqIdx;
    logic [FTQ_OFF_W-1:0] ftqOffset;
    logic [ITYPE_W-1:0]   itype;
    logic [IRETIRE_W-1:0] iretire;
    logic                 ilastsize;
  } trace_block_t;

  function automatic logic ptr_is_before(input trace_ptr_t a, input trace_ptr_t b);
    // a < b（环形序）：flag 相同看 value；flag 不同则 value 大的反而在前
    return a.flag ^ b.flag ^ (a.value < b.value);
  endfunction
endpackage

module xs_TraceBuffer_core
  import tracebuffer_pkg::*;
(
  input  logic                        clock,
  input  logic                        reset,
  input  logic                        enc_enable,
  input  logic                        enc_stall,
  input  logic         [COMMIT_W-1:0] in_valid,
  input  trace_block_t [COMMIT_W-1:0] in_block,
  output logic                        blockCommit,
  output logic         [GROUP_N-1:0]  out_valid,
  output trace_block_t [GROUP_N-1:0]  out_block
);

  // ---------------------------------------------------------------------------
  // 状态
  // ---------------------------------------------------------------------------
  trace_block_t [COMMIT_W-1:0] traceEntries_bits;   // 无复位
  logic         [COMMIT_W-1:0] traceEntries_valid;  // 无复位
  trace_ptr_t                  enqPtr, deqPtr;      // 复位 0
  trace_ptr_t                  deqPtrPre;           // RegNext(deqPtr)，无复位

  // ---------------------------------------------------------------------------
  // 压缩：哪些块需要 PC
  // ---------------------------------------------------------------------------
  logic [COMMIT_W-1:0] needPc;
  always_comb begin
    for (int i = 0; i < COMMIT_W; i++) begin
      logic right_has_valid;
      right_has_valid = 1'b0;
      for (int j = i + 1; j < COMMIT_W; j++) right_has_valid |= in_valid[j];
      needPc[i] = in_valid[i] & ((|in_block[i].itype) | ~right_has_valid) & ~blockCommit;
    end
  end

  // 不需要 PC 的块把 iretire 累进右邻、ftq 位置顺延给右邻
  trace_block_t [COMMIT_W-1:0] blocksUpdate;
  always_comb begin
    blocksUpdate = in_block;
    for (int i = 1; i < COMMIT_W; i++) begin
      if (!needPc[i-1]) begin
        blocksUpdate[i].iretire   = blocksUpdate[i-1].iretire + in_block[i].iretire;
        blocksUpdate[i].ftqOffset = blocksUpdate[i-1].ftqOffset;
        blocksUpdate[i].ftqIdx    = blocksUpdate[i-1].ftqIdx;
      end
    end
  end

  // 前缀计数：countVec[i] = popcount(needPc[i:0])；numNeedPc = countVec[7]
  logic [COMMIT_W-1:0][PTR_W:0] countVec;
  always_comb begin
    countVec[0] = {3'b0, needPc[0]};
    for (int i = 1; i < COMMIT_W; i++) countVec[i] = countVec[i-1] + {3'b0, needPc[i]};
  end
  wire [PTR_W:0] numNeedPc = countVec[COMMIT_W-1];

  // ---------------------------------------------------------------------------
  // 指针推进
  // ---------------------------------------------------------------------------
  trace_ptr_t enqPtrNext, deqPtrNext, deqPtrPlusGroup;
  assign enqPtrNext      = enqPtr + numNeedPc;
  assign deqPtrPlusGroup = deqPtr + PTR_W'(GROUP_N) + 4'b0;  // deqPtr + 3
  // deqPtrNext = min(deqPtr + 3, enqPtrNext)
  wire   deq_overrun = ptr_is_before(enqPtrNext, deqPtrPlusGroup);   // deqPtr+3 > enqPtrNext
  assign deqPtrNext  = deq_overrun ? enqPtrNext : deqPtrPlusGroup;

  // distanceBetween(enqPtrNext, deqPtrNext) > 0
  logic [PTR_W:0] dist_next;
  always_comb begin
    if (enqPtrNext.flag == deqPtrNext.flag)
      dist_next = {1'b0, PTR_W'(enqPtrNext.value - deqPtrNext.value)};
    else
      dist_next = (PTR_W+1)'(COMMIT_W) + {1'b0, enqPtrNext.value} - {1'b0, deqPtrNext.value};
  end
  wire canNotTraceAll = |dist_next;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      blockCommit <= 1'b0;
      enqPtr      <= '0;
      deqPtr      <= '0;
    end else begin
      blockCommit <= enc_enable & (canNotTraceAll | enc_stall);
      enqPtr      <= enqPtrNext;
      deqPtr      <= deqPtrNext;
    end
  end

  always_ff @(posedge clock)
    deqPtrPre <= deqPtr;

  // ---------------------------------------------------------------------------
  // 入队：块 i 写进槽 enqPtr + countVec[i] - 1；同槽多命中时下标大的块赢
  // ---------------------------------------------------------------------------
  logic [COMMIT_W-1:0][PTR_W-1:0] traceIdx;
  always_comb
    for (int i = 0; i < COMMIT_W; i++)
      traceIdx[i] = enqPtr.value + PTR_W'(countVec[i][PTR_W-1:0] - 1'b1);

  always_ff @(posedge clock) begin
    for (int i = 0; i < COMMIT_W; i++) begin
      if (needPc[i]) begin
        traceEntries_valid[traceIdx[i]]          <= in_valid[i];
        traceEntries_bits[traceIdx[i]].ftqIdx    <= blocksUpdate[i].ftqIdx;
        traceEntries_bits[traceIdx[i]].ftqOffset <= blocksUpdate[i].ftqOffset;
        traceEntries_bits[traceIdx[i]].itype     <= in_block[i].itype;
        traceEntries_bits[traceIdx[i]].iretire   <= blocksUpdate[i].iretire;
        traceEntries_bits[traceIdx[i]].ilastsize <= in_block[i].ilastsize;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // 出队：从 deqPtrPre 起最多 3 项，只要 deqPtrPre+i 还在 enqPtr 之前
  // ---------------------------------------------------------------------------
  always_comb begin
    for (int i = 0; i < GROUP_N; i++) begin
      trace_ptr_t rd_ptr;
      logic       in_range;
      rd_ptr   = deqPtrPre + PTR_W'(i) + 4'b0;
      in_range = ptr_is_before(rd_ptr, enqPtr);
      out_valid[i] = in_range & traceEntries_valid[rd_ptr.value];
      out_block[i] = in_range ? traceEntries_bits[rd_ptr.value] : '0;
    end
  end

endmodule : xs_TraceBuffer_core

module TraceBuffer(
  input        clock,
  input        reset,
  input        io_in_fromEncoder_enable,
  input        io_in_fromEncoder_stall,
  input        io_in_fromRob_blocks_0_valid,
  input  [5:0] io_in_fromRob_blocks_0_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_0_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_0_bits_tracePipe_itype,
  input  [6:0] io_in_fromRob_blocks_0_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_0_bits_tracePipe_ilastsize,
  input        io_in_fromRob_blocks_1_valid,
  input  [5:0] io_in_fromRob_blocks_1_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_1_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_1_bits_tracePipe_itype,
  input  [6:0] io_in_fromRob_blocks_1_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_1_bits_tracePipe_ilastsize,
  input        io_in_fromRob_blocks_2_valid,
  input  [5:0] io_in_fromRob_blocks_2_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_2_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_2_bits_tracePipe_itype,
  input  [6:0] io_in_fromRob_blocks_2_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_2_bits_tracePipe_ilastsize,
  input        io_in_fromRob_blocks_3_valid,
  input  [5:0] io_in_fromRob_blocks_3_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_3_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_3_bits_tracePipe_itype,
  input  [6:0] io_in_fromRob_blocks_3_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_3_bits_tracePipe_ilastsize,
  input        io_in_fromRob_blocks_4_valid,
  input  [5:0] io_in_fromRob_blocks_4_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_4_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_4_bits_tracePipe_itype,
  input  [6:0] io_in_fromRob_blocks_4_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_4_bits_tracePipe_ilastsize,
  input        io_in_fromRob_blocks_5_valid,
  input  [5:0] io_in_fromRob_blocks_5_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_5_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_5_bits_tracePipe_itype,
  input  [6:0] io_in_fromRob_blocks_5_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_5_bits_tracePipe_ilastsize,
  input        io_in_fromRob_blocks_6_valid,
  input  [5:0] io_in_fromRob_blocks_6_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_6_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_6_bits_tracePipe_itype,
  input  [6:0] io_in_fromRob_blocks_6_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_6_bits_tracePipe_ilastsize,
  input        io_in_fromRob_blocks_7_valid,
  input  [5:0] io_in_fromRob_blocks_7_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_7_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_7_bits_tracePipe_itype,
  input  [6:0] io_in_fromRob_blocks_7_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_7_bits_tracePipe_ilastsize,
  output       io_out_blockCommit,
  output       io_out_groups_blocks_0_valid,
  output [5:0] io_out_groups_blocks_0_bits_ftqIdx_value,
  output [3:0] io_out_groups_blocks_0_bits_ftqOffset,
  output [3:0] io_out_groups_blocks_0_bits_tracePipe_itype,
  output [6:0] io_out_groups_blocks_0_bits_tracePipe_iretire,
  output       io_out_groups_blocks_0_bits_tracePipe_ilastsize,
  output       io_out_groups_blocks_1_valid,
  output [5:0] io_out_groups_blocks_1_bits_ftqIdx_value,
  output [3:0] io_out_groups_blocks_1_bits_ftqOffset,
  output [3:0] io_out_groups_blocks_1_bits_tracePipe_itype,
  output [6:0] io_out_groups_blocks_1_bits_tracePipe_iretire,
  output       io_out_groups_blocks_1_bits_tracePipe_ilastsize,
  output       io_out_groups_blocks_2_valid,
  output [5:0] io_out_groups_blocks_2_bits_ftqIdx_value,
  output [3:0] io_out_groups_blocks_2_bits_ftqOffset,
  output [3:0] io_out_groups_blocks_2_bits_tracePipe_itype,
  output [6:0] io_out_groups_blocks_2_bits_tracePipe_iretire,
  output       io_out_groups_blocks_2_bits_tracePipe_ilastsize
);
  import tracebuffer_pkg::*;
  trace_block_t [COMMIT_W-1:0] in_block;
  trace_block_t [GROUP_N-1:0]  out_block;
  logic         [COMMIT_W-1:0] in_valid;
  logic         [GROUP_N-1:0]  out_valid;

  // BEGIN GENERATED(tracebuffer_wrapper) —— 逐块打包/拆包（字段顺序见 trace_block_t）
  assign in_valid = {io_in_fromRob_blocks_7_valid, io_in_fromRob_blocks_6_valid,
                     io_in_fromRob_blocks_5_valid, io_in_fromRob_blocks_4_valid,
                     io_in_fromRob_blocks_3_valid, io_in_fromRob_blocks_2_valid,
                     io_in_fromRob_blocks_1_valid, io_in_fromRob_blocks_0_valid};
  assign in_block[0] = '{io_in_fromRob_blocks_0_bits_ftqIdx_value, io_in_fromRob_blocks_0_bits_ftqOffset, io_in_fromRob_blocks_0_bits_tracePipe_itype, io_in_fromRob_blocks_0_bits_tracePipe_iretire, io_in_fromRob_blocks_0_bits_tracePipe_ilastsize};
  assign in_block[1] = '{io_in_fromRob_blocks_1_bits_ftqIdx_value, io_in_fromRob_blocks_1_bits_ftqOffset, io_in_fromRob_blocks_1_bits_tracePipe_itype, io_in_fromRob_blocks_1_bits_tracePipe_iretire, io_in_fromRob_blocks_1_bits_tracePipe_ilastsize};
  assign in_block[2] = '{io_in_fromRob_blocks_2_bits_ftqIdx_value, io_in_fromRob_blocks_2_bits_ftqOffset, io_in_fromRob_blocks_2_bits_tracePipe_itype, io_in_fromRob_blocks_2_bits_tracePipe_iretire, io_in_fromRob_blocks_2_bits_tracePipe_ilastsize};
  assign in_block[3] = '{io_in_fromRob_blocks_3_bits_ftqIdx_value, io_in_fromRob_blocks_3_bits_ftqOffset, io_in_fromRob_blocks_3_bits_tracePipe_itype, io_in_fromRob_blocks_3_bits_tracePipe_iretire, io_in_fromRob_blocks_3_bits_tracePipe_ilastsize};
  assign in_block[4] = '{io_in_fromRob_blocks_4_bits_ftqIdx_value, io_in_fromRob_blocks_4_bits_ftqOffset, io_in_fromRob_blocks_4_bits_tracePipe_itype, io_in_fromRob_blocks_4_bits_tracePipe_iretire, io_in_fromRob_blocks_4_bits_tracePipe_ilastsize};
  assign in_block[5] = '{io_in_fromRob_blocks_5_bits_ftqIdx_value, io_in_fromRob_blocks_5_bits_ftqOffset, io_in_fromRob_blocks_5_bits_tracePipe_itype, io_in_fromRob_blocks_5_bits_tracePipe_iretire, io_in_fromRob_blocks_5_bits_tracePipe_ilastsize};
  assign in_block[6] = '{io_in_fromRob_blocks_6_bits_ftqIdx_value, io_in_fromRob_blocks_6_bits_ftqOffset, io_in_fromRob_blocks_6_bits_tracePipe_itype, io_in_fromRob_blocks_6_bits_tracePipe_iretire, io_in_fromRob_blocks_6_bits_tracePipe_ilastsize};
  assign in_block[7] = '{io_in_fromRob_blocks_7_bits_ftqIdx_value, io_in_fromRob_blocks_7_bits_ftqOffset, io_in_fromRob_blocks_7_bits_tracePipe_itype, io_in_fromRob_blocks_7_bits_tracePipe_iretire, io_in_fromRob_blocks_7_bits_tracePipe_ilastsize};
  assign io_out_groups_blocks_0_valid = out_valid[0];
  assign io_out_groups_blocks_0_bits_ftqIdx_value = out_block[0].ftqIdx;
  assign io_out_groups_blocks_0_bits_ftqOffset = out_block[0].ftqOffset;
  assign io_out_groups_blocks_0_bits_tracePipe_itype = out_block[0].itype;
  assign io_out_groups_blocks_0_bits_tracePipe_iretire = out_block[0].iretire;
  assign io_out_groups_blocks_0_bits_tracePipe_ilastsize = out_block[0].ilastsize;
  assign io_out_groups_blocks_1_valid = out_valid[1];
  assign io_out_groups_blocks_1_bits_ftqIdx_value = out_block[1].ftqIdx;
  assign io_out_groups_blocks_1_bits_ftqOffset = out_block[1].ftqOffset;
  assign io_out_groups_blocks_1_bits_tracePipe_itype = out_block[1].itype;
  assign io_out_groups_blocks_1_bits_tracePipe_iretire = out_block[1].iretire;
  assign io_out_groups_blocks_1_bits_tracePipe_ilastsize = out_block[1].ilastsize;
  assign io_out_groups_blocks_2_valid = out_valid[2];
  assign io_out_groups_blocks_2_bits_ftqIdx_value = out_block[2].ftqIdx;
  assign io_out_groups_blocks_2_bits_ftqOffset = out_block[2].ftqOffset;
  assign io_out_groups_blocks_2_bits_tracePipe_itype = out_block[2].itype;
  assign io_out_groups_blocks_2_bits_tracePipe_iretire = out_block[2].iretire;
  assign io_out_groups_blocks_2_bits_tracePipe_ilastsize = out_block[2].ilastsize;
  // END GENERATED

  xs_TraceBuffer_core u_core (
    .clock       (clock),
    .reset       (reset),
    .enc_enable  (io_in_fromEncoder_enable),
    .enc_stall   (io_in_fromEncoder_stall),
    .in_valid    (in_valid),
    .in_block    (in_block),
    .blockCommit (io_out_blockCommit),
    .out_valid   (out_valid),
    .out_block   (out_block)
  );
endmodule
