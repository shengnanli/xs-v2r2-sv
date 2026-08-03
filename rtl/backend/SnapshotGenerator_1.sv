// =============================================================================
// xs_SnapshotGenerator_1_core —— walkPtr 快照环形缓冲(VTypeBuffer 内 walkPtrSnapshots)。
//
// 对应 golden SnapshotGenerator_1。4 深快照队列(snapshots[0..3]), 每个快照 payload =
// 单个 robIdx {flag, value[5:0]}(7 位)。控制逻辑与 sibling SnapshotGenerator_3/_14
// 完全同构(enq/deq 指针 + flush 重定位 + valids), 仅 payload 位宽/字段不同。
//   enq: 非 redirect 且非满时把 io_enqData 写入 enqPtr 指向槽, enqPtr++;
//   deq: 非 redirect 且 io_deq 时 deqPtr++;
//   flush: 若 flushVec 命中有效槽, 从 deqPtr 起顺序找首个"未有效或被 flush"的槽,
//          把 enqPtr 重定位到该处(丢弃后续快照);
//   valids: 每槽 valid = ~(flush 命中 | deq 该槽) & (enq 该槽 | 原 valid)。
//
// 忠实复刻 golden 逐位语义。io_enq 未 deq 且队满时的 golden 断言在 SYNTHESIS 下裁剪。
// =============================================================================
module xs_SnapshotGenerator_1_core(
  input        clock,
  input        reset,
  input        io_enq,
  input        io_enqData_flag,
  input  [5:0] io_enqData_value,
  input        io_deq,
  input        io_redirect,
  input        io_flushVec_0,
  input        io_flushVec_1,
  input        io_flushVec_2,
  input        io_flushVec_3,
  output       io_snapshots_0_flag,
  output [5:0] io_snapshots_0_value,
  output       io_snapshots_1_flag,
  output [5:0] io_snapshots_1_value,
  output       io_snapshots_2_flag,
  output [5:0] io_snapshots_2_value,
  output       io_snapshots_3_flag,
  output [5:0] io_snapshots_3_value
);

  // --- 快照存储: 4 槽, 每槽 payload = 1 个 robIdx {flag, value[5:0]} = 7 位 -------
  localparam int PW = 1 + 6;  // = 7
  logic [PW-1:0] snapshots [4];
  logic [3:0]    snptValids;
  logic          snptEnqPtr_flag;
  logic [1:0]    snptEnqPtr_value;
  logic          snptDeqPtr_flag;
  logic [1:0]    snptDeqPtr_value;

  wire [PW-1:0] enqPayload = {io_enqData_flag, io_enqData_value};

  wire [3:0] flushVec = {io_flushVec_3, io_flushVec_2, io_flushVec_1, io_flushVec_0};

  // 队满 = enqPtr 与 deqPtr 环相差满(flag 不同且 value 相等)。
  wire full = (snptEnqPtr_flag != snptDeqPtr_flag)
            & (snptEnqPtr_value == snptDeqPtr_value);
  wire doEnq = ~io_redirect & ~full & io_enq;
  wire doDeq = ~io_redirect & io_deq;

  wire [3:0] enqOH = doEnq ? (4'h1 << snptEnqPtr_value) : 4'h0;

  // --- flush 后 enqPtr 重定位: 从 deqPtr 起顺序找首个"无效或被flush"的槽 --------
  wire [2:0] deqPtr3 = {snptDeqPtr_flag, snptDeqPtr_value};
  wire [2:0] cand1 = 3'(deqPtr3 + 3'h1);
  wire [2:0] cand2 = 3'(deqPtr3 + 3'h2);
  wire [2:0] cand3 = 3'(deqPtr3 + 3'h3);

  wire q0 = ~snptValids[snptDeqPtr_value] | flushVec[snptDeqPtr_value];
  wire v1 = snptValids[cand1[1:0]];
  wire q1 = v1 & (~v1 | flushVec[cand1[1:0]]);
  wire v2 = snptValids[cand2[1:0]];
  wire q2 = v2 & (~v2 | flushVec[cand2[1:0]]);

  wire [2:0] newEnqPtr = q0 ? deqPtr3 : q1 ? cand1 : q2 ? cand2 : cand3;
  wire flushHit = |(flushVec & snptValids);

  wire [2:0] enqPtrNext = 3'({snptEnqPtr_flag, snptEnqPtr_value} + 3'h1);
  wire [2:0] deqPtrNext = 3'(deqPtr3 + 3'h1);

  // --- 时序: 快照写入 -------------------------------------------------------
  always_ff @(posedge clock) begin
    for (int i = 0; i < 4; i++)
      if (enqOH[i]) snapshots[i] <= enqPayload;
  end

  // --- 时序: 指针与 valids(异步复位) ---------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      snptEnqPtr_flag  <= 1'b0;
      snptEnqPtr_value <= 2'h0;
      snptDeqPtr_flag  <= 1'b0;
      snptDeqPtr_value <= 2'h0;
      snptValids       <= 4'h0;
    end
    else begin
      if (flushHit) begin
        snptEnqPtr_flag  <= newEnqPtr[2];
        snptEnqPtr_value <= newEnqPtr[1:0];
      end
      else if (doEnq) begin
        snptEnqPtr_flag  <= enqPtrNext[2];
        snptEnqPtr_value <= enqPtrNext[1:0];
      end
      if (doDeq) begin
        snptDeqPtr_flag  <= deqPtrNext[2];
        snptDeqPtr_value <= deqPtrNext[1:0];
      end
      for (int i = 0; i < 4; i++)
        snptValids[i] <=
            ~(flushVec[i] | (doDeq & (snptDeqPtr_value == i[1:0])))
            & (enqOH[i] | snptValids[i]);
    end
  end

  // --- 输出: 快照 payload 拆回各字段 ----------------------------------------
  assign {io_snapshots_0_flag, io_snapshots_0_value} = snapshots[0];
  assign {io_snapshots_1_flag, io_snapshots_1_value} = snapshots[1];
  assign {io_snapshots_2_flag, io_snapshots_2_value} = snapshots[2];
  assign {io_snapshots_3_flag, io_snapshots_3_value} = snapshots[3];

endmodule
