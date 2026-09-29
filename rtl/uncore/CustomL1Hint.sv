// CustomL1Hint.sv —— L2 给 L1 的 GrantData 提前唤醒提示（l1Hint）
//
// 对照 coupledL2/src/main/scala/coupledL2/CustomL1Hint.scala（mshrsAll = 16）。MainPipe 在两处知道"马上要回 D 通道了"：
//   * s1：MSHR 任务里的 Grant / GrantData（含 mergeA 合并进来的那个 A 请求），以及通道 C 的 Release/ReleaseData
//     （回 ReleaseAck）。这些先进 4 项 flow 队列 hint_s1Queue（"最多只会有 2 项"）。
//   * s3：直接命中、不需要 MSHR 的 A 通道 Grant / GrantData，当拍进 hintQueue，且优先于 hint_s1Queue 出队。
// hintQueue（16 项）出队头若是 GrantData 才对外给 l1Hint.valid；但不论是不是 GrantData，l1Hint.ready 都照样出队
// （Grant / ReleaseAck 占位只为保持与 D 通道同序，出口上"默默丢掉"）。
// 两个队列都"不该满"：golden 只有 ifndef SYNTHESIS 的断言，无反压；这里同样。
// opcode 在队列里只存 3 位（TileLink D 的 Grant=4 / GrantData=5 / ReleaseAck=6）。
// 本文件手写；两个队列是 scripts/gen_l2_queues.py 生成的薄文件（共享核 xs_ChiselQueue_core）。

module CustomL1Hint (
  input  logic        clock,
  input  logic        reset,
  input  logic        io_s1_valid,
  input  logic [2:0]  io_s1_bits_channel,
  input  logic        io_s1_bits_isKeyword,
  input  logic [3:0]  io_s1_bits_opcode,
  input  logic [6:0]  io_s1_bits_sourceId,
  input  logic        io_s1_bits_mshrTask,
  input  logic        io_s1_bits_mergeA,
  input  logic        io_s1_bits_aMergeTask_isKeyword,
  input  logic [2:0]  io_s1_bits_aMergeTask_opcode,
  input  logic [6:0]  io_s1_bits_aMergeTask_sourceId,
  input  logic        io_s3_task_valid,
  input  logic [2:0]  io_s3_task_bits_channel,
  input  logic        io_s3_task_bits_isKeyword,
  input  logic [3:0]  io_s3_task_bits_opcode,
  input  logic [6:0]  io_s3_task_bits_sourceId,
  input  logic        io_s3_task_bits_mshrTask,
  input  logic        io_s3_need_mshr,
  input  logic        io_l1Hint_ready,
  output logic        io_l1Hint_valid,
  output logic [31:0] io_l1Hint_bits_sourceId,
  output logic        io_l1Hint_bits_isKeyword
);

  // TileLink D opcode（hint 队列里存 3 位）
  localparam logic [2:0] Grant       = 3'd4;
  localparam logic [2:0] GrantData   = 3'd5;
  localparam logic [2:0] ReleaseAck  = 3'd6;
  // TileLink C opcode
  localparam logic [3:0] Release     = 4'd6;
  localparam logic [3:0] ReleaseData = 4'd7;

  // channel 是独热编码：bit0 = A，bit2 = C
  logic s1_fromA, s1_fromC, s3_fromA;
  assign s1_fromA = io_s1_bits_channel[0];
  assign s1_fromC = io_s1_bits_channel[2];
  assign s3_fromA = io_s3_task_bits_channel[0];

  // ---- s1：MSHR 任务的 Grant[Data]（含 mergeA 那个 A 请求）与通道 C 的 Release ----
  logic s1_mshr;
  logic mshrGrantData_s1, mshrGrant_s1, chnRelease_s1;
  assign s1_mshr          = io_s1_valid && io_s1_bits_mshrTask;
  assign mshrGrantData_s1 = s1_mshr && s1_fromA &&
                            (io_s1_bits_opcode == {1'b0, GrantData} ||
                             io_s1_bits_mergeA && io_s1_bits_aMergeTask_opcode == GrantData);
  assign mshrGrant_s1     = s1_mshr && s1_fromA &&
                            (io_s1_bits_opcode == {1'b0, Grant} ||
                             io_s1_bits_mergeA && io_s1_bits_aMergeTask_opcode == Grant);
  assign chnRelease_s1    = io_s1_valid && !io_s1_bits_mshrTask && s1_fromC &&
                            (io_s1_bits_opcode == Release || io_s1_bits_opcode == ReleaseData);

  logic       s1q_enq_valid;
  logic [6:0] s1q_enq_source;
  logic [2:0] s1q_enq_opcode;
  logic       s1q_enq_isKeyword;
  assign s1q_enq_valid     = mshrGrantData_s1 || mshrGrant_s1 || chnRelease_s1;
  assign s1q_enq_source    = io_s1_bits_mergeA ? io_s1_bits_aMergeTask_sourceId : io_s1_bits_sourceId;
  assign s1q_enq_isKeyword = io_s1_bits_mergeA ? io_s1_bits_aMergeTask_isKeyword : io_s1_bits_isKeyword;
  // ParallelPriorityMux：Grant 优先于 GrantData，都不是就给 ReleaseAck（三者都不成立时 enq 无效，值无所谓）
  assign s1q_enq_opcode    = mshrGrant_s1 ? Grant : (mshrGrantData_s1 ? GrantData : ReleaseAck);

  // ---- s3：不需要 MSHR 的 A 通道直接命中 ----
  logic s3_direct, chnGrant_s3, chnGrantData_s3, enqValid_s3;
  assign s3_direct       = io_s3_task_valid && !io_s3_task_bits_mshrTask && !io_s3_need_mshr && s3_fromA;
  assign chnGrant_s3     = s3_direct && io_s3_task_bits_opcode == {1'b0, Grant};
  assign chnGrantData_s3 = s3_direct && io_s3_task_bits_opcode == {1'b0, GrantData};
  assign enqValid_s3     = chnGrant_s3 || chnGrantData_s3;

  // ---- 两级队列：s3 的直接提示优先进 hintQueue，hint_s1Queue 让路 ----
  logic       s1q_enq_ready, s1q_deq_ready, s1q_deq_valid;
  logic [6:0] s1q_deq_source;
  logic [2:0] s1q_deq_opcode;
  logic       s1q_deq_isKeyword;
  logic       hq_enq_ready, hq_enq_valid, hq_deq_valid;
  logic [6:0] hq_deq_source;
  logic [2:0] hq_deq_opcode;

  assign s1q_deq_ready = hq_enq_ready && !enqValid_s3;
  assign hq_enq_valid  = enqValid_s3 || s1q_deq_valid;

  Queue16_HintQueueEntry hintQueue (
    .clock                 (clock),
    .reset                 (reset),
    .io_enq_ready          (hq_enq_ready),
    .io_enq_valid          (hq_enq_valid),
    .io_enq_bits_source    (enqValid_s3 ? io_s3_task_bits_sourceId : s1q_deq_source),
    .io_enq_bits_opcode    (enqValid_s3 ? (chnGrant_s3 ? Grant : GrantData) : s1q_deq_opcode),
    .io_enq_bits_isKeyword (enqValid_s3 ? io_s3_task_bits_isKeyword : s1q_deq_isKeyword),
    .io_deq_ready          (io_l1Hint_ready),
    .io_deq_valid          (hq_deq_valid),
    .io_deq_bits_source    (hq_deq_source),
    .io_deq_bits_opcode    (hq_deq_opcode),
    .io_deq_bits_isKeyword (io_l1Hint_bits_isKeyword)
  );

  Queue4_HintQueueEntry hint_s1Queue (
    .clock                 (clock),
    .reset                 (reset),
    .io_enq_ready          (s1q_enq_ready),
    .io_enq_valid          (s1q_enq_valid),
    .io_enq_bits_source    (s1q_enq_source),
    .io_enq_bits_opcode    (s1q_enq_opcode),
    .io_enq_bits_isKeyword (s1q_enq_isKeyword),
    .io_deq_ready          (s1q_deq_ready),
    .io_deq_valid          (s1q_deq_valid),
    .io_deq_bits_source    (s1q_deq_source),
    .io_deq_bits_opcode    (s1q_deq_opcode),
    .io_deq_bits_isKeyword (s1q_deq_isKeyword)
  );

  // 只有 GrantData 才对外提示；sourceId 在 L2ToL1Hint 里是 32 位，高位补 0
  assign io_l1Hint_valid         = hq_deq_valid && hq_deq_opcode == GrantData;
  assign io_l1Hint_bits_sourceId = {25'd0, hq_deq_source};

`ifndef SYNTHESIS
  always_ff @(posedge clock) begin
    if (!reset) begin
      assert (s1q_enq_ready) else $error("hint_s1Queue should never be full");
      assert (hq_enq_ready)  else $error("hintQueue should never be full");
    end
  end
`endif

endmodule
