// =============================================================================
// xs_SnapshotGenerator_2_core —— specVtype 快照环形缓冲(VTypeBuffer 内
// walkVTypeSnapshots)。
//
// 对应 golden SnapshotGenerator_2。4 深快照队列(snapshots[0..3]), 每个快照 payload =
// 一个 VType {illegal, vma, vta, vsew[1:0], vlmul[2:0]}(8 位)。控制逻辑与 sibling
// SnapshotGenerator_1/_3/_14 完全同构(enq/deq 指针 + flush 重定位 + valids), 仅
// payload 位宽/字段不同。
//
// 忠实复刻 golden 逐位语义。io_enq 未 deq 且队满时的 golden 断言在 SYNTHESIS 下裁剪。
// =============================================================================
module xs_SnapshotGenerator_2_core(
  input        clock,
  input        reset,
  input        io_enq,
  input        io_enqData_illegal,
  input        io_enqData_vma,
  input        io_enqData_vta,
  input  [1:0] io_enqData_vsew,
  input  [2:0] io_enqData_vlmul,
  input        io_deq,
  input        io_redirect,
  input        io_flushVec_0,
  input        io_flushVec_1,
  input        io_flushVec_2,
  input        io_flushVec_3,
  output       io_snapshots_0_illegal,
  output       io_snapshots_0_vma,
  output       io_snapshots_0_vta,
  output [1:0] io_snapshots_0_vsew,
  output [2:0] io_snapshots_0_vlmul,
  output       io_snapshots_1_illegal,
  output       io_snapshots_1_vma,
  output       io_snapshots_1_vta,
  output [1:0] io_snapshots_1_vsew,
  output [2:0] io_snapshots_1_vlmul,
  output       io_snapshots_2_illegal,
  output       io_snapshots_2_vma,
  output       io_snapshots_2_vta,
  output [1:0] io_snapshots_2_vsew,
  output [2:0] io_snapshots_2_vlmul,
  output       io_snapshots_3_illegal,
  output       io_snapshots_3_vma,
  output       io_snapshots_3_vta,
  output [1:0] io_snapshots_3_vsew,
  output [2:0] io_snapshots_3_vlmul
);

  // --- 快照存储: 4 槽, payload = VType 8 位 --------------------------------
  //   位布局(低→高, 与 golden RANDOM init 对齐):
  //     [0]=illegal [1]=vma [2]=vta [4:3]=vsew [7:5]=vlmul
  localparam int PW = 1 + 1 + 1 + 2 + 3;  // = 8
  logic [PW-1:0] snapshots [4];
  logic [3:0]    snptValids;
  logic          snptEnqPtr_flag;
  logic [1:0]    snptEnqPtr_value;
  logic          snptDeqPtr_flag;
  logic [1:0]    snptDeqPtr_value;

  wire [PW-1:0] enqPayload =
      {io_enqData_vlmul, io_enqData_vsew, io_enqData_vta, io_enqData_vma,
       io_enqData_illegal};

  wire [3:0] flushVec = {io_flushVec_3, io_flushVec_2, io_flushVec_1, io_flushVec_0};

  wire full = (snptEnqPtr_flag != snptDeqPtr_flag)
            & (snptEnqPtr_value == snptDeqPtr_value);
  wire doEnq = ~io_redirect & ~full & io_enq;
  wire doDeq = ~io_redirect & io_deq;

  wire [3:0] enqOH = doEnq ? (4'h1 << snptEnqPtr_value) : 4'h0;

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

  always_ff @(posedge clock) begin
    for (int i = 0; i < 4; i++)
      if (enqOH[i]) snapshots[i] <= enqPayload;
  end

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

  // --- 输出: 快照 payload 拆回各字段(位布局同 enqPayload) ------------------
  assign {io_snapshots_0_vlmul, io_snapshots_0_vsew, io_snapshots_0_vta,
          io_snapshots_0_vma, io_snapshots_0_illegal} = snapshots[0];
  assign {io_snapshots_1_vlmul, io_snapshots_1_vsew, io_snapshots_1_vta,
          io_snapshots_1_vma, io_snapshots_1_illegal} = snapshots[1];
  assign {io_snapshots_2_vlmul, io_snapshots_2_vsew, io_snapshots_2_vta,
          io_snapshots_2_vma, io_snapshots_2_illegal} = snapshots[2];
  assign {io_snapshots_3_vlmul, io_snapshots_3_vsew, io_snapshots_3_vta,
          io_snapshots_3_vma, io_snapshots_3_illegal} = snapshots[3];

endmodule
