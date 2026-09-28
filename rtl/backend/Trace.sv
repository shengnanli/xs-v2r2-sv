// =============================================================================
// Trace.sv —— RISC-V 指令跟踪（Trace）在后端的三级流水：打拍 → 压缩缓冲 → 出组
// -----------------------------------------------------------------------------
// 设计源: XiangShan src/main/scala/xiangshan/backend/trace/Trace.scala
// golden 对照: G1-canonical/golden-rtl/Trace.sv（702 行）
// 层次位置: SimTop…backend.inner.ctrlBlock.trace
//
// ★ 它是什么 ★
// Rob 每拍提交的 CommitWidth=8 个块的跟踪信息（itype / iretire / ilastsize / ftq 位置）
// 经三级走到跟踪编码器：
//   s1  打一拍（valid 受 blockCommit 反压保持；bits 各自在 valid 时锁存）
//   s2  TraceBuffer 压缩、入环形缓冲、每拍出最多 TraceGroupNum=3 组（rtl/backend/TraceBuffer.sv）
//   s3  出组再打一拍送编码器；同时未打拍的那份直接送 pcMem 查 iaddr（ftqIdx 只在这一路）
// blockRobCommit = TraceBuffer 的 blockCommit，原样送回 Rob。
//
// ★ golden 事实 ★
//   - s1 的 valid 与 bits 都异步复位 0；valid 使能 !blockCommit，bits 使能各自 in.valid。
//   - 输入 iretire 是 4 位（IretireWidthInPipe），送 TraceBuffer 时零扩展到 7 位。
//   - toPcMem 只剩 valid + ftqIdx（其余字段无消费者被裁掉）；toEncoder 没有 ftqIdx。
//   - s3 寄存器（RegNext）无复位。
// =============================================================================

module xs_Trace_core #(
  parameter int unsigned COMMIT_W     = 8,   // CommitWidth
  parameter int unsigned GROUP_N      = 3,   // TraceGroupNum
  parameter int unsigned FTQ_IDX_W    = 6,
  parameter int unsigned FTQ_OFF_W    = 4,
  parameter int unsigned ITYPE_W      = 4,
  parameter int unsigned IRETIRE_IN_W = 4,   // IretireWidthInPipe
  parameter int unsigned IRETIRE_W    = 7    // IretireWidthCompressed（TraceBuffer 侧）
)(
  input  logic                                clock,
  input  logic                                reset,
  input  logic                                enc_enable,
  input  logic                                enc_stall,
  // s0：Rob 提交块
  input  logic [COMMIT_W-1:0]                 rob_valid,
  input  logic [COMMIT_W-1:0][FTQ_IDX_W-1:0]  rob_ftqIdx,
  input  logic [COMMIT_W-1:0][FTQ_OFF_W-1:0]  rob_ftqOffset,
  input  logic [COMMIT_W-1:0][ITYPE_W-1:0]    rob_itype,
  input  logic [COMMIT_W-1:0][IRETIRE_IN_W-1:0] rob_iretire,
  input  logic [COMMIT_W-1:0]                 rob_ilastsize,
  // 出组：未打拍 → pcMem；打一拍 → 编码器
  output logic [GROUP_N-1:0]                  pcmem_valid,
  output logic [GROUP_N-1:0][FTQ_IDX_W-1:0]   pcmem_ftqIdx,
  output logic [GROUP_N-1:0]                  enc_valid,
  output logic [GROUP_N-1:0][FTQ_OFF_W-1:0]   enc_ftqOffset,
  output logic [GROUP_N-1:0][ITYPE_W-1:0]     enc_itype,
  output logic [GROUP_N-1:0][IRETIRE_W-1:0]   enc_iretire,
  output logic [GROUP_N-1:0]                  enc_ilastsize,
  output logic                                blockRobCommit
);

  // ---------------------------------------------------------------------------
  // s1：打一拍
  // ---------------------------------------------------------------------------
  logic [COMMIT_W-1:0]                   s1_valid;
  logic [COMMIT_W-1:0][FTQ_IDX_W-1:0]    s1_ftqIdx;
  logic [COMMIT_W-1:0][FTQ_OFF_W-1:0]    s1_ftqOffset;
  logic [COMMIT_W-1:0][ITYPE_W-1:0]      s1_itype;
  logic [COMMIT_W-1:0][IRETIRE_IN_W-1:0] s1_iretire;
  logic [COMMIT_W-1:0]                   s1_ilastsize;
  logic                                  blockCommit;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_valid     <= '0;
      s1_ftqIdx    <= '0;
      s1_ftqOffset <= '0;
      s1_itype     <= '0;
      s1_iretire   <= '0;
      s1_ilastsize <= '0;
    end else begin
      if (!blockCommit) s1_valid <= rob_valid;
      for (int i = 0; i < COMMIT_W; i++)
        if (rob_valid[i]) begin
          s1_ftqIdx[i]    <= rob_ftqIdx[i];
          s1_ftqOffset[i] <= rob_ftqOffset[i];
          s1_itype[i]     <= rob_itype[i];
          s1_iretire[i]   <= rob_iretire[i];
          s1_ilastsize[i] <= rob_ilastsize[i];
        end
    end
  end

  // ---------------------------------------------------------------------------
  // s2：压缩缓冲（golden 同名子模块，实例名 traceBuffer）
  // ---------------------------------------------------------------------------
  logic [GROUP_N-1:0]                s2_valid;
  logic [GROUP_N-1:0][FTQ_IDX_W-1:0] s2_ftqIdx;
  logic [GROUP_N-1:0][FTQ_OFF_W-1:0] s2_ftqOffset;
  logic [GROUP_N-1:0][ITYPE_W-1:0]   s2_itype;
  logic [GROUP_N-1:0][IRETIRE_W-1:0] s2_iretire;
  logic [GROUP_N-1:0]                s2_ilastsize;

  TraceBuffer traceBuffer (
    .clock                    (clock),
    .reset                    (reset),
    .io_in_fromEncoder_enable (enc_enable),
    .io_in_fromEncoder_stall  (enc_stall),
    .io_in_fromRob_blocks_0_valid                    (s1_valid[0]),
    .io_in_fromRob_blocks_0_bits_ftqIdx_value       (s1_ftqIdx[0]),
    .io_in_fromRob_blocks_0_bits_ftqOffset          (s1_ftqOffset[0]),
    .io_in_fromRob_blocks_0_bits_tracePipe_itype    (s1_itype[0]),
    .io_in_fromRob_blocks_0_bits_tracePipe_iretire  (IRETIRE_W'(s1_iretire[0])),   // 4 位零扩展到 7 位
    .io_in_fromRob_blocks_0_bits_tracePipe_ilastsize(s1_ilastsize[0]),
    .io_in_fromRob_blocks_1_valid                    (s1_valid[1]),
    .io_in_fromRob_blocks_1_bits_ftqIdx_value       (s1_ftqIdx[1]),
    .io_in_fromRob_blocks_1_bits_ftqOffset          (s1_ftqOffset[1]),
    .io_in_fromRob_blocks_1_bits_tracePipe_itype    (s1_itype[1]),
    .io_in_fromRob_blocks_1_bits_tracePipe_iretire  (IRETIRE_W'(s1_iretire[1])),   // 4 位零扩展到 7 位
    .io_in_fromRob_blocks_1_bits_tracePipe_ilastsize(s1_ilastsize[1]),
    .io_in_fromRob_blocks_2_valid                    (s1_valid[2]),
    .io_in_fromRob_blocks_2_bits_ftqIdx_value       (s1_ftqIdx[2]),
    .io_in_fromRob_blocks_2_bits_ftqOffset          (s1_ftqOffset[2]),
    .io_in_fromRob_blocks_2_bits_tracePipe_itype    (s1_itype[2]),
    .io_in_fromRob_blocks_2_bits_tracePipe_iretire  (IRETIRE_W'(s1_iretire[2])),   // 4 位零扩展到 7 位
    .io_in_fromRob_blocks_2_bits_tracePipe_ilastsize(s1_ilastsize[2]),
    .io_in_fromRob_blocks_3_valid                    (s1_valid[3]),
    .io_in_fromRob_blocks_3_bits_ftqIdx_value       (s1_ftqIdx[3]),
    .io_in_fromRob_blocks_3_bits_ftqOffset          (s1_ftqOffset[3]),
    .io_in_fromRob_blocks_3_bits_tracePipe_itype    (s1_itype[3]),
    .io_in_fromRob_blocks_3_bits_tracePipe_iretire  (IRETIRE_W'(s1_iretire[3])),   // 4 位零扩展到 7 位
    .io_in_fromRob_blocks_3_bits_tracePipe_ilastsize(s1_ilastsize[3]),
    .io_in_fromRob_blocks_4_valid                    (s1_valid[4]),
    .io_in_fromRob_blocks_4_bits_ftqIdx_value       (s1_ftqIdx[4]),
    .io_in_fromRob_blocks_4_bits_ftqOffset          (s1_ftqOffset[4]),
    .io_in_fromRob_blocks_4_bits_tracePipe_itype    (s1_itype[4]),
    .io_in_fromRob_blocks_4_bits_tracePipe_iretire  (IRETIRE_W'(s1_iretire[4])),   // 4 位零扩展到 7 位
    .io_in_fromRob_blocks_4_bits_tracePipe_ilastsize(s1_ilastsize[4]),
    .io_in_fromRob_blocks_5_valid                    (s1_valid[5]),
    .io_in_fromRob_blocks_5_bits_ftqIdx_value       (s1_ftqIdx[5]),
    .io_in_fromRob_blocks_5_bits_ftqOffset          (s1_ftqOffset[5]),
    .io_in_fromRob_blocks_5_bits_tracePipe_itype    (s1_itype[5]),
    .io_in_fromRob_blocks_5_bits_tracePipe_iretire  (IRETIRE_W'(s1_iretire[5])),   // 4 位零扩展到 7 位
    .io_in_fromRob_blocks_5_bits_tracePipe_ilastsize(s1_ilastsize[5]),
    .io_in_fromRob_blocks_6_valid                    (s1_valid[6]),
    .io_in_fromRob_blocks_6_bits_ftqIdx_value       (s1_ftqIdx[6]),
    .io_in_fromRob_blocks_6_bits_ftqOffset          (s1_ftqOffset[6]),
    .io_in_fromRob_blocks_6_bits_tracePipe_itype    (s1_itype[6]),
    .io_in_fromRob_blocks_6_bits_tracePipe_iretire  (IRETIRE_W'(s1_iretire[6])),   // 4 位零扩展到 7 位
    .io_in_fromRob_blocks_6_bits_tracePipe_ilastsize(s1_ilastsize[6]),
    .io_in_fromRob_blocks_7_valid                    (s1_valid[7]),
    .io_in_fromRob_blocks_7_bits_ftqIdx_value       (s1_ftqIdx[7]),
    .io_in_fromRob_blocks_7_bits_ftqOffset          (s1_ftqOffset[7]),
    .io_in_fromRob_blocks_7_bits_tracePipe_itype    (s1_itype[7]),
    .io_in_fromRob_blocks_7_bits_tracePipe_iretire  (IRETIRE_W'(s1_iretire[7])),   // 4 位零扩展到 7 位
    .io_in_fromRob_blocks_7_bits_tracePipe_ilastsize(s1_ilastsize[7]),
    .io_out_blockCommit       (blockCommit),
    .io_out_groups_blocks_0_valid                    (s2_valid[0]),
    .io_out_groups_blocks_0_bits_ftqIdx_value       (s2_ftqIdx[0]),
    .io_out_groups_blocks_0_bits_ftqOffset          (s2_ftqOffset[0]),
    .io_out_groups_blocks_0_bits_tracePipe_itype    (s2_itype[0]),
    .io_out_groups_blocks_0_bits_tracePipe_iretire  (s2_iretire[0]),
    .io_out_groups_blocks_0_bits_tracePipe_ilastsize(s2_ilastsize[0]),
    .io_out_groups_blocks_1_valid                    (s2_valid[1]),
    .io_out_groups_blocks_1_bits_ftqIdx_value       (s2_ftqIdx[1]),
    .io_out_groups_blocks_1_bits_ftqOffset          (s2_ftqOffset[1]),
    .io_out_groups_blocks_1_bits_tracePipe_itype    (s2_itype[1]),
    .io_out_groups_blocks_1_bits_tracePipe_iretire  (s2_iretire[1]),
    .io_out_groups_blocks_1_bits_tracePipe_ilastsize(s2_ilastsize[1]),
    .io_out_groups_blocks_2_valid                    (s2_valid[2]),
    .io_out_groups_blocks_2_bits_ftqIdx_value       (s2_ftqIdx[2]),
    .io_out_groups_blocks_2_bits_ftqOffset          (s2_ftqOffset[2]),
    .io_out_groups_blocks_2_bits_tracePipe_itype    (s2_itype[2]),
    .io_out_groups_blocks_2_bits_tracePipe_iretire  (s2_iretire[2]),
    .io_out_groups_blocks_2_bits_tracePipe_ilastsize(s2_ilastsize[2])
  );
  assign blockRobCommit = blockCommit;

  // ---------------------------------------------------------------------------
  // s3：pcMem 走未打拍的一份（只要 valid + ftqIdx）；编码器走打一拍的一份（无复位）
  // ---------------------------------------------------------------------------
  assign pcmem_valid  = s2_valid;
  assign pcmem_ftqIdx = s2_ftqIdx;

  always_ff @(posedge clock) begin
    enc_valid     <= s2_valid;
    enc_ftqOffset <= s2_ftqOffset;
    enc_itype     <= s2_itype;
    enc_iretire   <= s2_iretire;
    enc_ilastsize <= s2_ilastsize;
  end

endmodule : xs_Trace_core

module Trace(
  input        clock,
  input        reset,
  input        io_in_fromEncoder_enable,
  input        io_in_fromEncoder_stall,
  input        io_in_fromRob_blocks_0_valid,
  input  [5:0] io_in_fromRob_blocks_0_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_0_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_0_bits_tracePipe_itype,
  input  [3:0] io_in_fromRob_blocks_0_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_0_bits_tracePipe_ilastsize,
  input        io_in_fromRob_blocks_1_valid,
  input  [5:0] io_in_fromRob_blocks_1_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_1_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_1_bits_tracePipe_itype,
  input  [3:0] io_in_fromRob_blocks_1_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_1_bits_tracePipe_ilastsize,
  input        io_in_fromRob_blocks_2_valid,
  input  [5:0] io_in_fromRob_blocks_2_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_2_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_2_bits_tracePipe_itype,
  input  [3:0] io_in_fromRob_blocks_2_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_2_bits_tracePipe_ilastsize,
  input        io_in_fromRob_blocks_3_valid,
  input  [5:0] io_in_fromRob_blocks_3_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_3_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_3_bits_tracePipe_itype,
  input  [3:0] io_in_fromRob_blocks_3_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_3_bits_tracePipe_ilastsize,
  input        io_in_fromRob_blocks_4_valid,
  input  [5:0] io_in_fromRob_blocks_4_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_4_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_4_bits_tracePipe_itype,
  input  [3:0] io_in_fromRob_blocks_4_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_4_bits_tracePipe_ilastsize,
  input        io_in_fromRob_blocks_5_valid,
  input  [5:0] io_in_fromRob_blocks_5_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_5_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_5_bits_tracePipe_itype,
  input  [3:0] io_in_fromRob_blocks_5_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_5_bits_tracePipe_ilastsize,
  input        io_in_fromRob_blocks_6_valid,
  input  [5:0] io_in_fromRob_blocks_6_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_6_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_6_bits_tracePipe_itype,
  input  [3:0] io_in_fromRob_blocks_6_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_6_bits_tracePipe_ilastsize,
  input        io_in_fromRob_blocks_7_valid,
  input  [5:0] io_in_fromRob_blocks_7_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_7_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_7_bits_tracePipe_itype,
  input  [3:0] io_in_fromRob_blocks_7_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_7_bits_tracePipe_ilastsize,
  output       io_out_toPcMem_blocks_0_valid,
  output [5:0] io_out_toPcMem_blocks_0_bits_ftqIdx_value,
  output       io_out_toPcMem_blocks_1_valid,
  output [5:0] io_out_toPcMem_blocks_1_bits_ftqIdx_value,
  output       io_out_toPcMem_blocks_2_valid,
  output [5:0] io_out_toPcMem_blocks_2_bits_ftqIdx_value,
  output       io_out_toEncoder_blocks_0_valid,
  output [3:0] io_out_toEncoder_blocks_0_bits_ftqOffset,
  output [3:0] io_out_toEncoder_blocks_0_bits_tracePipe_itype,
  output [6:0] io_out_toEncoder_blocks_0_bits_tracePipe_iretire,
  output       io_out_toEncoder_blocks_0_bits_tracePipe_ilastsize,
  output       io_out_toEncoder_blocks_1_valid,
  output [3:0] io_out_toEncoder_blocks_1_bits_ftqOffset,
  output [3:0] io_out_toEncoder_blocks_1_bits_tracePipe_itype,
  output [6:0] io_out_toEncoder_blocks_1_bits_tracePipe_iretire,
  output       io_out_toEncoder_blocks_1_bits_tracePipe_ilastsize,
  output       io_out_toEncoder_blocks_2_valid,
  output [3:0] io_out_toEncoder_blocks_2_bits_ftqOffset,
  output [3:0] io_out_toEncoder_blocks_2_bits_tracePipe_itype,
  output [6:0] io_out_toEncoder_blocks_2_bits_tracePipe_iretire,
  output       io_out_toEncoder_blocks_2_bits_tracePipe_ilastsize,
  output       io_out_blockRobCommit
);
  logic [2:0]      enc_valid, pcmem_valid, enc_ilastsize;
  logic [2:0][5:0] pcmem_ftqIdx;
  logic [2:0][3:0] enc_ftqOffset, enc_itype;
  logic [2:0][6:0] enc_iretire;
  // BEGIN GENERATED(trace_wrapper)
  assign io_out_toPcMem_blocks_0_valid = pcmem_valid[0];
  assign io_out_toPcMem_blocks_0_bits_ftqIdx_value = pcmem_ftqIdx[0];
  assign io_out_toPcMem_blocks_1_valid = pcmem_valid[1];
  assign io_out_toPcMem_blocks_1_bits_ftqIdx_value = pcmem_ftqIdx[1];
  assign io_out_toPcMem_blocks_2_valid = pcmem_valid[2];
  assign io_out_toPcMem_blocks_2_bits_ftqIdx_value = pcmem_ftqIdx[2];
  assign io_out_toEncoder_blocks_0_valid = enc_valid[0];
  assign io_out_toEncoder_blocks_0_bits_ftqOffset = enc_ftqOffset[0];
  assign io_out_toEncoder_blocks_0_bits_tracePipe_itype = enc_itype[0];
  assign io_out_toEncoder_blocks_0_bits_tracePipe_iretire = enc_iretire[0];
  assign io_out_toEncoder_blocks_0_bits_tracePipe_ilastsize = enc_ilastsize[0];
  assign io_out_toEncoder_blocks_1_valid = enc_valid[1];
  assign io_out_toEncoder_blocks_1_bits_ftqOffset = enc_ftqOffset[1];
  assign io_out_toEncoder_blocks_1_bits_tracePipe_itype = enc_itype[1];
  assign io_out_toEncoder_blocks_1_bits_tracePipe_iretire = enc_iretire[1];
  assign io_out_toEncoder_blocks_1_bits_tracePipe_ilastsize = enc_ilastsize[1];
  assign io_out_toEncoder_blocks_2_valid = enc_valid[2];
  assign io_out_toEncoder_blocks_2_bits_ftqOffset = enc_ftqOffset[2];
  assign io_out_toEncoder_blocks_2_bits_tracePipe_itype = enc_itype[2];
  assign io_out_toEncoder_blocks_2_bits_tracePipe_iretire = enc_iretire[2];
  assign io_out_toEncoder_blocks_2_bits_tracePipe_ilastsize = enc_ilastsize[2];
  // END GENERATED

  xs_Trace_core u_core (
    .clock (clock),
    .reset (reset),
    .enc_enable (io_in_fromEncoder_enable),
    .enc_stall (io_in_fromEncoder_stall),
    .rob_valid ({io_in_fromRob_blocks_7_valid, io_in_fromRob_blocks_6_valid, io_in_fromRob_blocks_5_valid, io_in_fromRob_blocks_4_valid, io_in_fromRob_blocks_3_valid, io_in_fromRob_blocks_2_valid, io_in_fromRob_blocks_1_valid, io_in_fromRob_blocks_0_valid}),
    .rob_ftqIdx ({io_in_fromRob_blocks_7_bits_ftqIdx_value, io_in_fromRob_blocks_6_bits_ftqIdx_value, io_in_fromRob_blocks_5_bits_ftqIdx_value, io_in_fromRob_blocks_4_bits_ftqIdx_value, io_in_fromRob_blocks_3_bits_ftqIdx_value, io_in_fromRob_blocks_2_bits_ftqIdx_value, io_in_fromRob_blocks_1_bits_ftqIdx_value, io_in_fromRob_blocks_0_bits_ftqIdx_value}),
    .rob_ftqOffset ({io_in_fromRob_blocks_7_bits_ftqOffset, io_in_fromRob_blocks_6_bits_ftqOffset, io_in_fromRob_blocks_5_bits_ftqOffset, io_in_fromRob_blocks_4_bits_ftqOffset, io_in_fromRob_blocks_3_bits_ftqOffset, io_in_fromRob_blocks_2_bits_ftqOffset, io_in_fromRob_blocks_1_bits_ftqOffset, io_in_fromRob_blocks_0_bits_ftqOffset}),
    .rob_itype ({io_in_fromRob_blocks_7_bits_tracePipe_itype, io_in_fromRob_blocks_6_bits_tracePipe_itype, io_in_fromRob_blocks_5_bits_tracePipe_itype, io_in_fromRob_blocks_4_bits_tracePipe_itype, io_in_fromRob_blocks_3_bits_tracePipe_itype, io_in_fromRob_blocks_2_bits_tracePipe_itype, io_in_fromRob_blocks_1_bits_tracePipe_itype, io_in_fromRob_blocks_0_bits_tracePipe_itype}),
    .rob_iretire ({io_in_fromRob_blocks_7_bits_tracePipe_iretire, io_in_fromRob_blocks_6_bits_tracePipe_iretire, io_in_fromRob_blocks_5_bits_tracePipe_iretire, io_in_fromRob_blocks_4_bits_tracePipe_iretire, io_in_fromRob_blocks_3_bits_tracePipe_iretire, io_in_fromRob_blocks_2_bits_tracePipe_iretire, io_in_fromRob_blocks_1_bits_tracePipe_iretire, io_in_fromRob_blocks_0_bits_tracePipe_iretire}),
    .rob_ilastsize ({io_in_fromRob_blocks_7_bits_tracePipe_ilastsize, io_in_fromRob_blocks_6_bits_tracePipe_ilastsize, io_in_fromRob_blocks_5_bits_tracePipe_ilastsize, io_in_fromRob_blocks_4_bits_tracePipe_ilastsize, io_in_fromRob_blocks_3_bits_tracePipe_ilastsize, io_in_fromRob_blocks_2_bits_tracePipe_ilastsize, io_in_fromRob_blocks_1_bits_tracePipe_ilastsize, io_in_fromRob_blocks_0_bits_tracePipe_ilastsize}),
    .pcmem_valid (pcmem_valid),
    .pcmem_ftqIdx (pcmem_ftqIdx),
    .enc_valid (enc_valid),
    .enc_ftqOffset (enc_ftqOffset),
    .enc_itype (enc_itype),
    .enc_iretire (enc_iretire),
    .enc_ilastsize (enc_ilastsize),
    .blockRobCommit (io_out_blockRobCommit)
  );
endmodule
