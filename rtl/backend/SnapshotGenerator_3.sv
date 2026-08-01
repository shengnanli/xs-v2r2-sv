// =============================================================================
// xs_SnapshotGenerator_3_core —— rename 快照环形缓冲(Rob 内 snapshots_snapshotGen)。
//
// 对应 golden SnapshotGenerator_3。4 深快照队列(snapshots[0..3]), 每个快照 payload =
// 单个 robIdx {flag, value[7:0]}(9 位)。功能与 sibling SnapshotGenerator_14 同构,
// 仅 payload 更窄(1 个 robIdx, 无 isCFI)且不外露 enqPtr/deqPtr/valids:
//   enq: 非 redirect 且非满时把 io_enqData_0 写入 enqPtr 指向槽, enqPtr++;
//   deq: 非 redirect 且 io_deq 时 deqPtr++;
//   flush: 若 flushVec 命中有效槽, 从 deqPtr 起顺序找首个"未有效或被 flush"的槽,
//          把 enqPtr 重定位到该处(丢弃后续快照);
//   valids: 每槽 valid = ~(flush 命中 | deq 该槽) & (enq 该槽 | 原 valid)。
//
// 忠实复刻 golden 逐位语义。genvar/组合表达式重写, 0 个 _GEN_/_T_ 噪声。
// io_enq 未 deq 且队满时的 golden 断言(LogUtils assert)在 SYNTHESIS 下裁剪, 不影响等价。
// =============================================================================
module xs_SnapshotGenerator_3_core(
  input        clock,
  input        reset,
  input        io_enq,
  input        io_enqData_0_flag,
  input  [7:0] io_enqData_0_value,
  input        io_deq,
  input        io_redirect,
  input        io_flushVec_0,
  input        io_flushVec_1,
  input        io_flushVec_2,
  input        io_flushVec_3,
  output       io_snapshots_0_0_flag,
  output [7:0] io_snapshots_0_0_value,
  output       io_snapshots_1_0_flag,
  output [7:0] io_snapshots_1_0_value,
  output       io_snapshots_2_0_flag,
  output [7:0] io_snapshots_2_0_value,
  output       io_snapshots_3_0_flag,
  output [7:0] io_snapshots_3_0_value
);

  // --- 快照存储: 4 槽, 每槽 payload = 1 个 robIdx {flag, value[7:0]} = 9 位 ------
  localparam int PW = 1 + 8;  // = 9
  logic [PW-1:0] snapshots [4];
  logic [3:0]    snptValids;
  logic          snptEnqPtr_flag;
  logic [1:0]    snptEnqPtr_value;
  logic          snptDeqPtr_flag;
  logic [1:0]    snptDeqPtr_value;

  wire [PW-1:0] enqPayload = {io_enqData_0_flag, io_enqData_0_value};

  wire [3:0] flushVec = {io_flushVec_3, io_flushVec_2, io_flushVec_1, io_flushVec_0};

  // 队满 = enqPtr 与 deqPtr 环相差满(flag 不同且 value 相等)。
  wire full = (snptEnqPtr_flag != snptDeqPtr_flag)
            & (snptEnqPtr_value == snptDeqPtr_value);
  // 本拍是否真正 enq(非 redirect 且非满且 io_enq)。
  wire doEnq = ~io_redirect & ~full & io_enq;
  // 本拍是否真正 deq。
  wire doDeq = ~io_redirect & io_deq;

  // enq/deq 的 one-hot(按 enqPtr_value / deqPtr_value)。
  wire [3:0] enqOH = doEnq ? (4'h1 << snptEnqPtr_value) : 4'h0;
  wire [3:0] deqOH = doDeq ? (4'h1 << snptDeqPtr_value) : 4'h0;

  // --- flush 后 enqPtr 重定位: 从 deqPtr 起顺序找首个"无效或被flush"的槽 --------
  // 候选 3 位环指针(含 flag): base = {deqFlag, deqValue}, +0/+1/+2/+3。
  wire [2:0] deqPtr3 = {snptDeqPtr_flag, snptDeqPtr_value};
  wire [2:0] cand0 = deqPtr3;
  wire [2:0] cand1 = 3'(deqPtr3 + 3'h1);
  wire [2:0] cand2 = 3'(deqPtr3 + 3'h2);
  wire [2:0] cand3 = 3'(deqPtr3 + 3'h3);

  // 某候选槽"合格"(即在此停下重定位) = 该槽无效 或 被 flush。
  // 复刻 golden: qualified_0 = ~valids[deq] | flush[deq];
  //   qualified_k(k=1,2) = valids[cand_k] & (~valids[cand_k] | flush[cand_k])。
  wire q0 = ~snptValids[snptDeqPtr_value] | flushVec[snptDeqPtr_value];
  wire v1 = snptValids[cand1[1:0]];
  wire q1 = v1 & (~v1 | flushVec[cand1[1:0]]);
  wire v2 = snptValids[cand2[1:0]];
  wire q2 = v2 & (~v2 | flushVec[cand2[1:0]]);

  // 重定位后的新 enqPtr(3 位, 含 flag)。
  wire [2:0] newEnqPtr = q0 ? deqPtr3 : q1 ? cand1 : q2 ? cand2 : cand3;
  // 是否有任何有效槽被 flush 命中(触发重定位)。
  wire flushHit = |(flushVec & snptValids);

  // enq 正常步进后的 enqPtr(3 位)。
  wire [2:0] enqPtrNext = 3'({snptEnqPtr_flag, snptEnqPtr_value} + 3'h1);
  // deq 步进后的 deqPtr(3 位)。
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
      // valid[i] = ~(flush[i] | (deq 命中 i)) & (enq 命中 i | 原 valid[i])
      for (int i = 0; i < 4; i++)
        snptValids[i] <=
            ~(flushVec[i] | (doDeq & (snptDeqPtr_value == i[1:0])))
            & (enqOH[i] | snptValids[i]);
    end
  end

  // --- 输出: 快照 payload 拆回各字段 ----------------------------------------
  // 位布局: [8]=robIdx.flag [7:0]=robIdx.value
  assign {io_snapshots_0_0_flag, io_snapshots_0_0_value} = snapshots[0];
  assign {io_snapshots_1_0_flag, io_snapshots_1_0_value} = snapshots[1];
  assign {io_snapshots_2_0_flag, io_snapshots_2_0_value} = snapshots[2];
  assign {io_snapshots_3_0_flag, io_snapshots_3_0_value} = snapshots[3];

endmodule
