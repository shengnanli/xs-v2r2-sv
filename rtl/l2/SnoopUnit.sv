// ============================================================================
// SnoopUnit —— OpenLLC snoop-task issue buffer (可读手写核 xs_SnoopUnit_core)
// ----------------------------------------------------------------------------
// 忠实重写 golden SnoopUnit.sv(firtool 展开的 16 条目 buffer + FastArbiter_50)。
// 逻辑等价 bug-for-bug:
//   * 16 条目 buffer 保存 snoop task, 记录 ready / waitID / 存活计时器 bufferTimer;
//   * canFlow: 当入站 replSnp 任务已有匹配 respInfo(不需等 snoop resp)且仲裁器空闲时,
//     直接旁路 buffer 从 io_in 透传到 io_out;
//   * 入队: buffer 未满 & io_in.valid & ~doFlow → 分配首个空槽(priority insertIdx);
//     入队时若匹配 respInfo(_buffer_ready_T_210)直接置 ready, 否则 waitID=首个匹配 reqID;
//   * ack(opcode==2 & txnID==waitID) → 置对应条目 ready(update_vec/update_id);
//   * ready 条目送 FastArbiter_50 仲裁 → io_out; 出队(_GEN_18)清 chosen 条目 valid;
//   * bufferTimer: valid 时自增, 条目由 valid→invalid(REG_i & ~valid)时清零(泄漏检测计时)。
// FastArbiter_50 在两侧 elaborate(确定性逻辑, 非厂商宏)。
// ============================================================================

package xs_snoopunit_pkg;
  // 参数(与 golden 位宽逐位一致)
  localparam int unsigned N          = 16;   // buffer 条目数
  localparam int unsigned SET_W      = 12;
  localparam int unsigned BANK_W     = 2;
  localparam int unsigned TAG_W      = 28;
  localparam int unsigned TXNID_W    = 12;
  localparam int unsigned OPCODE_W   = 7;
  localparam int unsigned REQID_W    = 12;
  localparam int unsigned WAITID_W   = 12;
  localparam int unsigned TIMER_W    = 16;
  localparam int unsigned IDX_W      = 4;    // $clog2(16)
  localparam int unsigned KEY_W      = TAG_W + SET_W; // {tag,set} 比较键 = 40 位

  // snoop 完成 ack 的 opcode(CHI SnpRespData / CompAck 语义, golden 常量 7'h2)
  localparam logic [OPCODE_W-1:0] ACK_OPCODE = 7'h2;
  // 触发 canFlow / 初始 ready 的 respInfo opcode 集合(golden: 0x26 / 0x7 / 0xC)
  localparam logic [OPCODE_W-1:0] RESP_OP_A = 7'h26;
  localparam logic [OPCODE_W-1:0] RESP_OP_B = 7'h7;
  localparam logic [OPCODE_W-1:0] RESP_OP_C = 7'hC;
  localparam logic [TIMER_W-1:0]  TIMEOUT_THRESHOLD = 16'h4E1F;

  // 缓存的 snoop task(仅 buffer 实际保存的字段)
  typedef struct packed {
    logic [SET_W-1:0]    set;
    logic [BANK_W-1:0]   bank;
    logic [TAG_W-1:0]    tag;
    logic                replSnp;
    logic                snpVec_0;
    logic [TXNID_W-1:0]  txnID;
    logic [OPCODE_W-1:0] chiOpcode;
    logic                retToSrc;
    logic                doNotGoToSD;
  } snoop_task_t;

  // respInfo 通道(16 路)
  typedef struct packed {
    logic                valid;
    logic [SET_W-1:0]    set;
    logic [TAG_W-1:0]    tag;
    logic [OPCODE_W-1:0] opcode;
    logic [REQID_W-1:0]  reqID;
    logic                w_compack;
  } resp_info_t;
endpackage

// ----------------------------------------------------------------------------
// 可读核: struct 化端口 + generate 展开的 16 条目 buffer
// ----------------------------------------------------------------------------
module xs_SnoopUnit_core
  import xs_snoopunit_pkg::*;
(
  input  logic                clock,
  input  logic                reset,

  // 入站 snoop task
  input  logic                io_in_valid,
  input  snoop_task_t         io_in_task,

  // 出站(仲裁后或 flow 旁路)
  input  logic                io_out_ready,
  output logic                io_out_valid,
  output logic [SET_W-1:0]    io_out_bits_set,
  output logic [BANK_W-1:0]   io_out_bits_bank,
  output logic [TAG_W-1:0]    io_out_bits_tag,
  output logic                io_out_bits_snpVec_0,
  output logic [TXNID_W-1:0]  io_out_bits_txnID,
  output logic [10:0]         io_out_bits_fwdNID,
  output logic [11:0]         io_out_bits_fwdTxnID,
  output logic [OPCODE_W-1:0] io_out_bits_chiOpcode,
  output logic                io_out_bits_retToSrc,
  output logic                io_out_bits_doNotGoToSD,

  // 16 路 respInfo(打包为数组)
  input  resp_info_t [N-1:0]  io_respInfo,

  // snoop 完成 ack
  input  logic                io_ack_valid,
  input  logic [TXNID_W-1:0]  io_ack_bits_txnID,
  input  logic [OPCODE_W-1:0] io_ack_bits_opcode
);

  // -------------------- buffer 状态寄存器 --------------------
  snoop_task_t             buffer_task   [N-1:0];
  logic                    buffer_valid  [N-1:0];
  logic                    buffer_ready  [N-1:0];
  logic [WAITID_W-1:0]     buffer_waitID [N-1:0];
  logic [TIMER_W-1:0]      bufferTimer   [N-1:0];
  logic                    REG_valid_d   [N-1:0]; // 上一拍 valid(golden REG_i, 用于计时清零)

  // -------------------- 入站任务的 {tag,set} 比较键 --------------------
  logic [KEY_W-1:0] inKey;
  assign inKey = {io_in_task.tag, io_in_task.set};

  // -------------------- respInfo 匹配向量 --------------------
  // matchVec[i]: 入站 replSnp 任务与 respInfo[i] 同地址、无 w_compack、opcode ∈ {0x26,0x7,0xC}
  // => 该 snoop 的响应已在途, 无需真正外发 snoop(可直接 flow / 入队即 ready)。
  logic [N-1:0] respMatch;
  for (genvar i = 0; i < N; i++) begin : g_respmatch
    assign respMatch[i] =
        io_respInfo[i].valid & io_in_task.replSnp
      & ({io_respInfo[i].tag, io_respInfo[i].set} == inKey)
      & ~io_respInfo[i].w_compack
      & ( (io_respInfo[i].opcode == RESP_OP_A)
        | (io_respInfo[i].opcode == RESP_OP_B)
        | (io_respInfo[i].opcode == RESP_OP_C) );
  end

  // 首个匹配 respInfo 的 reqID → 入队时作为 waitID(golden _GEN_17)
  logic [REQID_W-1:0] firstMatchReqID;
  always_comb begin
    firstMatchReqID = io_respInfo[N-1].reqID; // 缺省=最高号(与 golden 末项一致)
    for (int k = N-1; k >= 0; k--) begin
      if (respMatch[k]) firstMatchReqID = io_respInfo[k].reqID;
    end
  end
  // 入队初始 ready = 无匹配 respInfo(该 snoop 无待决响应 → 立即可发)
  // golden _buffer_ready_T_210 = {matchVec} == 0
  logic initReady;
  assign initReady = (respMatch == '0);

  // -------------------- 仲裁器实例(FastArbiter_50, 两侧 elaborate) --------------------
  logic                arb_out_valid;
  logic [SET_W-1:0]    arb_out_set;
  logic [BANK_W-1:0]   arb_out_bank;
  logic [TAG_W-1:0]    arb_out_tag;
  logic                arb_out_snpVec_0;
  logic [TXNID_W-1:0]  arb_out_txnID;
  logic [10:0]         arb_out_fwdNID;
  logic [11:0]         arb_out_fwdTxnID;
  logic [OPCODE_W-1:0] arb_out_chiOpcode;
  logic                arb_out_retToSrc;
  logic                arb_out_doNotGoToSD;
  logic [IDX_W-1:0]    arb_chosen;

  // -------------------- canFlow / doFlow / io_out_valid --------------------
  // canFlow: 无匹配 respInfo(该 snoop 不需外发, 但也不满足旁路...) 实为:入站任务地址无
  // 匹配 pending resp(respMatch==0) 且仲裁器空闲 → 直接旁路透传。
  logic canFlow, doFlow;
  assign canFlow = (respMatch == '0) & ~arb_out_valid;
  assign doFlow  = canFlow & io_out_ready;

  // -------------------- 入队分配 --------------------
  logic [N-1:0] validVec;
  for (genvar i = 0; i < N; i++) begin : g_validvec
    assign validVec[i] = buffer_valid[i];
  end
  logic notFull;                 // golden _alloc_T
  assign notFull = (validVec != {N{1'b1}});
  logic alloc;                   // golden alloc
  assign alloc = notFull & io_in_valid & ~doFlow;

  // 首个空槽索引(priority, golden insertIdx)
  logic [IDX_W-1:0] insertIdx;
  always_comb begin
    insertIdx = {IDX_W{1'b1}}; // 缺省 15(与 golden 末项一致)
    for (int k = N-1; k >= 0; k--) begin
      if (!buffer_valid[k]) insertIdx = IDX_W'(k);
    end
  end

  // -------------------- ack 更新向量 --------------------
  // update_vec[i]: 条目 valid 且未 ready, ack opcode==2 且 txnID 命中 waitID
  logic [N-1:0] update_vec;
  for (genvar i = 0; i < N; i++) begin : g_updatevec
    assign update_vec[i] =
        buffer_valid[i] & ~buffer_ready[i]
      & (io_ack_bits_opcode == ACK_OPCODE)
      & (io_ack_bits_txnID == buffer_waitID[i]);
  end
  logic anyUpdate;               // golden (|_canUpdate_T)
  assign anyUpdate = (update_vec != '0);
  logic [IDX_W-1:0] update_id;   // 首个命中条目(priority)
  always_comb begin
    update_id = {IDX_W{1'b1}};
    for (int k = N-1; k >= 0; k--) begin
      if (update_vec[k]) update_id = IDX_W'(k);
    end
  end

  // -------------------- 出队(dequeue) --------------------
  // golden _GEN_18 = io_out_ready & io_out_valid_0 & arb_out_valid
  logic deqFire;
  assign deqFire = io_out_ready & io_out_valid & arb_out_valid;

  // -------------------- 每条目状态机 --------------------
  for (genvar i = 0; i < N; i++) begin : g_entry
    localparam logic [IDX_W-1:0] IDX = IDX_W'(i);
    logic allocHere;   // golden _GEN_i = alloc & insertIdx==i
    logic deqHere;     // golden _GEN_19.. = deqFire & arb_chosen==i
    assign allocHere = alloc   & (insertIdx == IDX);
    assign deqHere   = deqFire & (arb_chosen == IDX);

    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        buffer_valid[i]            <= 1'b0;
        buffer_task[i].set         <= '0;
        buffer_task[i].bank        <= '0;
        buffer_task[i].tag         <= '0;
        buffer_task[i].replSnp     <= 1'b0;
        buffer_task[i].snpVec_0    <= 1'b0;
        buffer_task[i].txnID       <= '0;
        buffer_task[i].chiOpcode   <= '0;
        buffer_task[i].retToSrc    <= 1'b0;
        buffer_task[i].doNotGoToSD <= 1'b0;
        buffer_ready[i]            <= 1'b0;
        buffer_waitID[i]           <= '0;
        bufferTimer[i]             <= '0;
        REG_valid_d[i]             <= 1'b0;
      end
      else begin
        // valid: 出队清 0, 否则入队或保持
        buffer_valid[i] <= ~deqHere & (allocHere | buffer_valid[i]);
        // task payload: 仅入队写(除 doNotGoToSD)
        if (allocHere) begin
          buffer_task[i].set       <= io_in_task.set;
          buffer_task[i].bank      <= io_in_task.bank;
          buffer_task[i].tag       <= io_in_task.tag;
          buffer_task[i].replSnp   <= io_in_task.replSnp;
          buffer_task[i].snpVec_0  <= io_in_task.snpVec_0;
          buffer_task[i].txnID     <= io_in_task.txnID;
          buffer_task[i].chiOpcode <= io_in_task.chiOpcode;
          buffer_task[i].retToSrc  <= io_in_task.retToSrc;
          buffer_waitID[i]         <= firstMatchReqID;
        end
        // doNotGoToSD: 入队置位后粘住(golden _GEN_i | buffer_i_task_doNotGoToSD)
        buffer_task[i].doNotGoToSD <= allocHere | buffer_task[i].doNotGoToSD;
        // ready: 出队清 0; 否则 ack 命中该条目置位, 或入队 initReady, 或保持
        buffer_ready[i] <=
            ~deqHere
          & ( (io_ack_valid & anyUpdate & (update_id == IDX))
            | (allocHere ? initReady : buffer_ready[i]) );
        // bufferTimer: 由 valid→invalid 时清零(REG_i & ~valid), 否则 valid 时自增
        if (REG_valid_d[i] & ~buffer_valid[i])
          bufferTimer[i] <= '0;
        else if (buffer_valid[i])
          bufferTimer[i] <= TIMER_W'(bufferTimer[i] + 16'h1);
        // REG_i <= buffer_i_valid(上一拍 valid 快照)
        REG_valid_d[i] <= buffer_valid[i];
      end
    end
  end

  // -------------------- 仲裁器输入(ready 条目参与) --------------------
  logic [N-1:0]              arb_in_valid;
  snoop_task_t [N-1:0]      arb_in_task;
  for (genvar i = 0; i < N; i++) begin : g_arbin
    assign arb_in_valid[i] = buffer_valid[i] & buffer_ready[i];
    assign arb_in_task[i]  = buffer_task[i];
  end

  FastArbiter_50 issueArb (
    .clock (clock),
    .reset (reset),
    .io_in_0_valid  (arb_in_valid[0]),  .io_in_0_bits_set (arb_in_task[0].set),  .io_in_0_bits_bank (arb_in_task[0].bank),  .io_in_0_bits_tag (arb_in_task[0].tag),  .io_in_0_bits_off (6'h0), .io_in_0_bits_size (3'h0), .io_in_0_bits_refillTask (1'h0), .io_in_0_bits_bufID (4'h0), .io_in_0_bits_reqID (12'h0), .io_in_0_bits_replSnp (arb_in_task[0].replSnp), .io_in_0_bits_snpVec_0 (arb_in_task[0].snpVec_0), .io_in_0_bits_tgtID (11'h0), .io_in_0_bits_srcID (11'h0), .io_in_0_bits_txnID (arb_in_task[0].txnID), .io_in_0_bits_dbID (12'h0), .io_in_0_bits_fwdNID (11'h0), .io_in_0_bits_fwdTxnID (12'h0), .io_in_0_bits_chiOpcode (arb_in_task[0].chiOpcode), .io_in_0_bits_resp (3'h0), .io_in_0_bits_fwdState (3'h0), .io_in_0_bits_pCrdType (4'h0), .io_in_0_bits_retToSrc (arb_in_task[0].retToSrc), .io_in_0_bits_doNotGoToSD (arb_in_task[0].doNotGoToSD), .io_in_0_bits_expCompAck (1'h0), .io_in_0_bits_allowRetry (1'h0), .io_in_0_bits_order (2'h0), .io_in_0_bits_memAttr_allocate (1'h0), .io_in_0_bits_memAttr_cacheable (1'h0), .io_in_0_bits_memAttr_device (1'h0), .io_in_0_bits_memAttr_ewa (1'h0), .io_in_0_bits_snpAttr (1'h0),
    .io_in_1_valid  (arb_in_valid[1]),  .io_in_1_bits_set (arb_in_task[1].set),  .io_in_1_bits_bank (arb_in_task[1].bank),  .io_in_1_bits_tag (arb_in_task[1].tag),  .io_in_1_bits_off (6'h0), .io_in_1_bits_size (3'h0), .io_in_1_bits_refillTask (1'h0), .io_in_1_bits_bufID (4'h0), .io_in_1_bits_reqID (12'h0), .io_in_1_bits_replSnp (arb_in_task[1].replSnp), .io_in_1_bits_snpVec_0 (arb_in_task[1].snpVec_0), .io_in_1_bits_tgtID (11'h0), .io_in_1_bits_srcID (11'h0), .io_in_1_bits_txnID (arb_in_task[1].txnID), .io_in_1_bits_dbID (12'h0), .io_in_1_bits_fwdNID (11'h0), .io_in_1_bits_fwdTxnID (12'h0), .io_in_1_bits_chiOpcode (arb_in_task[1].chiOpcode), .io_in_1_bits_resp (3'h0), .io_in_1_bits_fwdState (3'h0), .io_in_1_bits_pCrdType (4'h0), .io_in_1_bits_retToSrc (arb_in_task[1].retToSrc), .io_in_1_bits_doNotGoToSD (arb_in_task[1].doNotGoToSD), .io_in_1_bits_expCompAck (1'h0), .io_in_1_bits_allowRetry (1'h0), .io_in_1_bits_order (2'h0), .io_in_1_bits_memAttr_allocate (1'h0), .io_in_1_bits_memAttr_cacheable (1'h0), .io_in_1_bits_memAttr_device (1'h0), .io_in_1_bits_memAttr_ewa (1'h0), .io_in_1_bits_snpAttr (1'h0),
    .io_in_2_valid  (arb_in_valid[2]),  .io_in_2_bits_set (arb_in_task[2].set),  .io_in_2_bits_bank (arb_in_task[2].bank),  .io_in_2_bits_tag (arb_in_task[2].tag),  .io_in_2_bits_off (6'h0), .io_in_2_bits_size (3'h0), .io_in_2_bits_refillTask (1'h0), .io_in_2_bits_bufID (4'h0), .io_in_2_bits_reqID (12'h0), .io_in_2_bits_replSnp (arb_in_task[2].replSnp), .io_in_2_bits_snpVec_0 (arb_in_task[2].snpVec_0), .io_in_2_bits_tgtID (11'h0), .io_in_2_bits_srcID (11'h0), .io_in_2_bits_txnID (arb_in_task[2].txnID), .io_in_2_bits_dbID (12'h0), .io_in_2_bits_fwdNID (11'h0), .io_in_2_bits_fwdTxnID (12'h0), .io_in_2_bits_chiOpcode (arb_in_task[2].chiOpcode), .io_in_2_bits_resp (3'h0), .io_in_2_bits_fwdState (3'h0), .io_in_2_bits_pCrdType (4'h0), .io_in_2_bits_retToSrc (arb_in_task[2].retToSrc), .io_in_2_bits_doNotGoToSD (arb_in_task[2].doNotGoToSD), .io_in_2_bits_expCompAck (1'h0), .io_in_2_bits_allowRetry (1'h0), .io_in_2_bits_order (2'h0), .io_in_2_bits_memAttr_allocate (1'h0), .io_in_2_bits_memAttr_cacheable (1'h0), .io_in_2_bits_memAttr_device (1'h0), .io_in_2_bits_memAttr_ewa (1'h0), .io_in_2_bits_snpAttr (1'h0),
    .io_in_3_valid  (arb_in_valid[3]),  .io_in_3_bits_set (arb_in_task[3].set),  .io_in_3_bits_bank (arb_in_task[3].bank),  .io_in_3_bits_tag (arb_in_task[3].tag),  .io_in_3_bits_off (6'h0), .io_in_3_bits_size (3'h0), .io_in_3_bits_refillTask (1'h0), .io_in_3_bits_bufID (4'h0), .io_in_3_bits_reqID (12'h0), .io_in_3_bits_replSnp (arb_in_task[3].replSnp), .io_in_3_bits_snpVec_0 (arb_in_task[3].snpVec_0), .io_in_3_bits_tgtID (11'h0), .io_in_3_bits_srcID (11'h0), .io_in_3_bits_txnID (arb_in_task[3].txnID), .io_in_3_bits_dbID (12'h0), .io_in_3_bits_fwdNID (11'h0), .io_in_3_bits_fwdTxnID (12'h0), .io_in_3_bits_chiOpcode (arb_in_task[3].chiOpcode), .io_in_3_bits_resp (3'h0), .io_in_3_bits_fwdState (3'h0), .io_in_3_bits_pCrdType (4'h0), .io_in_3_bits_retToSrc (arb_in_task[3].retToSrc), .io_in_3_bits_doNotGoToSD (arb_in_task[3].doNotGoToSD), .io_in_3_bits_expCompAck (1'h0), .io_in_3_bits_allowRetry (1'h0), .io_in_3_bits_order (2'h0), .io_in_3_bits_memAttr_allocate (1'h0), .io_in_3_bits_memAttr_cacheable (1'h0), .io_in_3_bits_memAttr_device (1'h0), .io_in_3_bits_memAttr_ewa (1'h0), .io_in_3_bits_snpAttr (1'h0),
    .io_in_4_valid  (arb_in_valid[4]),  .io_in_4_bits_set (arb_in_task[4].set),  .io_in_4_bits_bank (arb_in_task[4].bank),  .io_in_4_bits_tag (arb_in_task[4].tag),  .io_in_4_bits_off (6'h0), .io_in_4_bits_size (3'h0), .io_in_4_bits_refillTask (1'h0), .io_in_4_bits_bufID (4'h0), .io_in_4_bits_reqID (12'h0), .io_in_4_bits_replSnp (arb_in_task[4].replSnp), .io_in_4_bits_snpVec_0 (arb_in_task[4].snpVec_0), .io_in_4_bits_tgtID (11'h0), .io_in_4_bits_srcID (11'h0), .io_in_4_bits_txnID (arb_in_task[4].txnID), .io_in_4_bits_dbID (12'h0), .io_in_4_bits_fwdNID (11'h0), .io_in_4_bits_fwdTxnID (12'h0), .io_in_4_bits_chiOpcode (arb_in_task[4].chiOpcode), .io_in_4_bits_resp (3'h0), .io_in_4_bits_fwdState (3'h0), .io_in_4_bits_pCrdType (4'h0), .io_in_4_bits_retToSrc (arb_in_task[4].retToSrc), .io_in_4_bits_doNotGoToSD (arb_in_task[4].doNotGoToSD), .io_in_4_bits_expCompAck (1'h0), .io_in_4_bits_allowRetry (1'h0), .io_in_4_bits_order (2'h0), .io_in_4_bits_memAttr_allocate (1'h0), .io_in_4_bits_memAttr_cacheable (1'h0), .io_in_4_bits_memAttr_device (1'h0), .io_in_4_bits_memAttr_ewa (1'h0), .io_in_4_bits_snpAttr (1'h0),
    .io_in_5_valid  (arb_in_valid[5]),  .io_in_5_bits_set (arb_in_task[5].set),  .io_in_5_bits_bank (arb_in_task[5].bank),  .io_in_5_bits_tag (arb_in_task[5].tag),  .io_in_5_bits_off (6'h0), .io_in_5_bits_size (3'h0), .io_in_5_bits_refillTask (1'h0), .io_in_5_bits_bufID (4'h0), .io_in_5_bits_reqID (12'h0), .io_in_5_bits_replSnp (arb_in_task[5].replSnp), .io_in_5_bits_snpVec_0 (arb_in_task[5].snpVec_0), .io_in_5_bits_tgtID (11'h0), .io_in_5_bits_srcID (11'h0), .io_in_5_bits_txnID (arb_in_task[5].txnID), .io_in_5_bits_dbID (12'h0), .io_in_5_bits_fwdNID (11'h0), .io_in_5_bits_fwdTxnID (12'h0), .io_in_5_bits_chiOpcode (arb_in_task[5].chiOpcode), .io_in_5_bits_resp (3'h0), .io_in_5_bits_fwdState (3'h0), .io_in_5_bits_pCrdType (4'h0), .io_in_5_bits_retToSrc (arb_in_task[5].retToSrc), .io_in_5_bits_doNotGoToSD (arb_in_task[5].doNotGoToSD), .io_in_5_bits_expCompAck (1'h0), .io_in_5_bits_allowRetry (1'h0), .io_in_5_bits_order (2'h0), .io_in_5_bits_memAttr_allocate (1'h0), .io_in_5_bits_memAttr_cacheable (1'h0), .io_in_5_bits_memAttr_device (1'h0), .io_in_5_bits_memAttr_ewa (1'h0), .io_in_5_bits_snpAttr (1'h0),
    .io_in_6_valid  (arb_in_valid[6]),  .io_in_6_bits_set (arb_in_task[6].set),  .io_in_6_bits_bank (arb_in_task[6].bank),  .io_in_6_bits_tag (arb_in_task[6].tag),  .io_in_6_bits_off (6'h0), .io_in_6_bits_size (3'h0), .io_in_6_bits_refillTask (1'h0), .io_in_6_bits_bufID (4'h0), .io_in_6_bits_reqID (12'h0), .io_in_6_bits_replSnp (arb_in_task[6].replSnp), .io_in_6_bits_snpVec_0 (arb_in_task[6].snpVec_0), .io_in_6_bits_tgtID (11'h0), .io_in_6_bits_srcID (11'h0), .io_in_6_bits_txnID (arb_in_task[6].txnID), .io_in_6_bits_dbID (12'h0), .io_in_6_bits_fwdNID (11'h0), .io_in_6_bits_fwdTxnID (12'h0), .io_in_6_bits_chiOpcode (arb_in_task[6].chiOpcode), .io_in_6_bits_resp (3'h0), .io_in_6_bits_fwdState (3'h0), .io_in_6_bits_pCrdType (4'h0), .io_in_6_bits_retToSrc (arb_in_task[6].retToSrc), .io_in_6_bits_doNotGoToSD (arb_in_task[6].doNotGoToSD), .io_in_6_bits_expCompAck (1'h0), .io_in_6_bits_allowRetry (1'h0), .io_in_6_bits_order (2'h0), .io_in_6_bits_memAttr_allocate (1'h0), .io_in_6_bits_memAttr_cacheable (1'h0), .io_in_6_bits_memAttr_device (1'h0), .io_in_6_bits_memAttr_ewa (1'h0), .io_in_6_bits_snpAttr (1'h0),
    .io_in_7_valid  (arb_in_valid[7]),  .io_in_7_bits_set (arb_in_task[7].set),  .io_in_7_bits_bank (arb_in_task[7].bank),  .io_in_7_bits_tag (arb_in_task[7].tag),  .io_in_7_bits_off (6'h0), .io_in_7_bits_size (3'h0), .io_in_7_bits_refillTask (1'h0), .io_in_7_bits_bufID (4'h0), .io_in_7_bits_reqID (12'h0), .io_in_7_bits_replSnp (arb_in_task[7].replSnp), .io_in_7_bits_snpVec_0 (arb_in_task[7].snpVec_0), .io_in_7_bits_tgtID (11'h0), .io_in_7_bits_srcID (11'h0), .io_in_7_bits_txnID (arb_in_task[7].txnID), .io_in_7_bits_dbID (12'h0), .io_in_7_bits_fwdNID (11'h0), .io_in_7_bits_fwdTxnID (12'h0), .io_in_7_bits_chiOpcode (arb_in_task[7].chiOpcode), .io_in_7_bits_resp (3'h0), .io_in_7_bits_fwdState (3'h0), .io_in_7_bits_pCrdType (4'h0), .io_in_7_bits_retToSrc (arb_in_task[7].retToSrc), .io_in_7_bits_doNotGoToSD (arb_in_task[7].doNotGoToSD), .io_in_7_bits_expCompAck (1'h0), .io_in_7_bits_allowRetry (1'h0), .io_in_7_bits_order (2'h0), .io_in_7_bits_memAttr_allocate (1'h0), .io_in_7_bits_memAttr_cacheable (1'h0), .io_in_7_bits_memAttr_device (1'h0), .io_in_7_bits_memAttr_ewa (1'h0), .io_in_7_bits_snpAttr (1'h0),
    .io_in_8_valid  (arb_in_valid[8]),  .io_in_8_bits_set (arb_in_task[8].set),  .io_in_8_bits_bank (arb_in_task[8].bank),  .io_in_8_bits_tag (arb_in_task[8].tag),  .io_in_8_bits_off (6'h0), .io_in_8_bits_size (3'h0), .io_in_8_bits_refillTask (1'h0), .io_in_8_bits_bufID (4'h0), .io_in_8_bits_reqID (12'h0), .io_in_8_bits_replSnp (arb_in_task[8].replSnp), .io_in_8_bits_snpVec_0 (arb_in_task[8].snpVec_0), .io_in_8_bits_tgtID (11'h0), .io_in_8_bits_srcID (11'h0), .io_in_8_bits_txnID (arb_in_task[8].txnID), .io_in_8_bits_dbID (12'h0), .io_in_8_bits_fwdNID (11'h0), .io_in_8_bits_fwdTxnID (12'h0), .io_in_8_bits_chiOpcode (arb_in_task[8].chiOpcode), .io_in_8_bits_resp (3'h0), .io_in_8_bits_fwdState (3'h0), .io_in_8_bits_pCrdType (4'h0), .io_in_8_bits_retToSrc (arb_in_task[8].retToSrc), .io_in_8_bits_doNotGoToSD (arb_in_task[8].doNotGoToSD), .io_in_8_bits_expCompAck (1'h0), .io_in_8_bits_allowRetry (1'h0), .io_in_8_bits_order (2'h0), .io_in_8_bits_memAttr_allocate (1'h0), .io_in_8_bits_memAttr_cacheable (1'h0), .io_in_8_bits_memAttr_device (1'h0), .io_in_8_bits_memAttr_ewa (1'h0), .io_in_8_bits_snpAttr (1'h0),
    .io_in_9_valid  (arb_in_valid[9]),  .io_in_9_bits_set (arb_in_task[9].set),  .io_in_9_bits_bank (arb_in_task[9].bank),  .io_in_9_bits_tag (arb_in_task[9].tag),  .io_in_9_bits_off (6'h0), .io_in_9_bits_size (3'h0), .io_in_9_bits_refillTask (1'h0), .io_in_9_bits_bufID (4'h0), .io_in_9_bits_reqID (12'h0), .io_in_9_bits_replSnp (arb_in_task[9].replSnp), .io_in_9_bits_snpVec_0 (arb_in_task[9].snpVec_0), .io_in_9_bits_tgtID (11'h0), .io_in_9_bits_srcID (11'h0), .io_in_9_bits_txnID (arb_in_task[9].txnID), .io_in_9_bits_dbID (12'h0), .io_in_9_bits_fwdNID (11'h0), .io_in_9_bits_fwdTxnID (12'h0), .io_in_9_bits_chiOpcode (arb_in_task[9].chiOpcode), .io_in_9_bits_resp (3'h0), .io_in_9_bits_fwdState (3'h0), .io_in_9_bits_pCrdType (4'h0), .io_in_9_bits_retToSrc (arb_in_task[9].retToSrc), .io_in_9_bits_doNotGoToSD (arb_in_task[9].doNotGoToSD), .io_in_9_bits_expCompAck (1'h0), .io_in_9_bits_allowRetry (1'h0), .io_in_9_bits_order (2'h0), .io_in_9_bits_memAttr_allocate (1'h0), .io_in_9_bits_memAttr_cacheable (1'h0), .io_in_9_bits_memAttr_device (1'h0), .io_in_9_bits_memAttr_ewa (1'h0), .io_in_9_bits_snpAttr (1'h0),
    .io_in_10_valid (arb_in_valid[10]), .io_in_10_bits_set (arb_in_task[10].set), .io_in_10_bits_bank (arb_in_task[10].bank), .io_in_10_bits_tag (arb_in_task[10].tag), .io_in_10_bits_off (6'h0), .io_in_10_bits_size (3'h0), .io_in_10_bits_refillTask (1'h0), .io_in_10_bits_bufID (4'h0), .io_in_10_bits_reqID (12'h0), .io_in_10_bits_replSnp (arb_in_task[10].replSnp), .io_in_10_bits_snpVec_0 (arb_in_task[10].snpVec_0), .io_in_10_bits_tgtID (11'h0), .io_in_10_bits_srcID (11'h0), .io_in_10_bits_txnID (arb_in_task[10].txnID), .io_in_10_bits_dbID (12'h0), .io_in_10_bits_fwdNID (11'h0), .io_in_10_bits_fwdTxnID (12'h0), .io_in_10_bits_chiOpcode (arb_in_task[10].chiOpcode), .io_in_10_bits_resp (3'h0), .io_in_10_bits_fwdState (3'h0), .io_in_10_bits_pCrdType (4'h0), .io_in_10_bits_retToSrc (arb_in_task[10].retToSrc), .io_in_10_bits_doNotGoToSD (arb_in_task[10].doNotGoToSD), .io_in_10_bits_expCompAck (1'h0), .io_in_10_bits_allowRetry (1'h0), .io_in_10_bits_order (2'h0), .io_in_10_bits_memAttr_allocate (1'h0), .io_in_10_bits_memAttr_cacheable (1'h0), .io_in_10_bits_memAttr_device (1'h0), .io_in_10_bits_memAttr_ewa (1'h0), .io_in_10_bits_snpAttr (1'h0),
    .io_in_11_valid (arb_in_valid[11]), .io_in_11_bits_set (arb_in_task[11].set), .io_in_11_bits_bank (arb_in_task[11].bank), .io_in_11_bits_tag (arb_in_task[11].tag), .io_in_11_bits_off (6'h0), .io_in_11_bits_size (3'h0), .io_in_11_bits_refillTask (1'h0), .io_in_11_bits_bufID (4'h0), .io_in_11_bits_reqID (12'h0), .io_in_11_bits_replSnp (arb_in_task[11].replSnp), .io_in_11_bits_snpVec_0 (arb_in_task[11].snpVec_0), .io_in_11_bits_tgtID (11'h0), .io_in_11_bits_srcID (11'h0), .io_in_11_bits_txnID (arb_in_task[11].txnID), .io_in_11_bits_dbID (12'h0), .io_in_11_bits_fwdNID (11'h0), .io_in_11_bits_fwdTxnID (12'h0), .io_in_11_bits_chiOpcode (arb_in_task[11].chiOpcode), .io_in_11_bits_resp (3'h0), .io_in_11_bits_fwdState (3'h0), .io_in_11_bits_pCrdType (4'h0), .io_in_11_bits_retToSrc (arb_in_task[11].retToSrc), .io_in_11_bits_doNotGoToSD (arb_in_task[11].doNotGoToSD), .io_in_11_bits_expCompAck (1'h0), .io_in_11_bits_allowRetry (1'h0), .io_in_11_bits_order (2'h0), .io_in_11_bits_memAttr_allocate (1'h0), .io_in_11_bits_memAttr_cacheable (1'h0), .io_in_11_bits_memAttr_device (1'h0), .io_in_11_bits_memAttr_ewa (1'h0), .io_in_11_bits_snpAttr (1'h0),
    .io_in_12_valid (arb_in_valid[12]), .io_in_12_bits_set (arb_in_task[12].set), .io_in_12_bits_bank (arb_in_task[12].bank), .io_in_12_bits_tag (arb_in_task[12].tag), .io_in_12_bits_off (6'h0), .io_in_12_bits_size (3'h0), .io_in_12_bits_refillTask (1'h0), .io_in_12_bits_bufID (4'h0), .io_in_12_bits_reqID (12'h0), .io_in_12_bits_replSnp (arb_in_task[12].replSnp), .io_in_12_bits_snpVec_0 (arb_in_task[12].snpVec_0), .io_in_12_bits_tgtID (11'h0), .io_in_12_bits_srcID (11'h0), .io_in_12_bits_txnID (arb_in_task[12].txnID), .io_in_12_bits_dbID (12'h0), .io_in_12_bits_fwdNID (11'h0), .io_in_12_bits_fwdTxnID (12'h0), .io_in_12_bits_chiOpcode (arb_in_task[12].chiOpcode), .io_in_12_bits_resp (3'h0), .io_in_12_bits_fwdState (3'h0), .io_in_12_bits_pCrdType (4'h0), .io_in_12_bits_retToSrc (arb_in_task[12].retToSrc), .io_in_12_bits_doNotGoToSD (arb_in_task[12].doNotGoToSD), .io_in_12_bits_expCompAck (1'h0), .io_in_12_bits_allowRetry (1'h0), .io_in_12_bits_order (2'h0), .io_in_12_bits_memAttr_allocate (1'h0), .io_in_12_bits_memAttr_cacheable (1'h0), .io_in_12_bits_memAttr_device (1'h0), .io_in_12_bits_memAttr_ewa (1'h0), .io_in_12_bits_snpAttr (1'h0),
    .io_in_13_valid (arb_in_valid[13]), .io_in_13_bits_set (arb_in_task[13].set), .io_in_13_bits_bank (arb_in_task[13].bank), .io_in_13_bits_tag (arb_in_task[13].tag), .io_in_13_bits_off (6'h0), .io_in_13_bits_size (3'h0), .io_in_13_bits_refillTask (1'h0), .io_in_13_bits_bufID (4'h0), .io_in_13_bits_reqID (12'h0), .io_in_13_bits_replSnp (arb_in_task[13].replSnp), .io_in_13_bits_snpVec_0 (arb_in_task[13].snpVec_0), .io_in_13_bits_tgtID (11'h0), .io_in_13_bits_srcID (11'h0), .io_in_13_bits_txnID (arb_in_task[13].txnID), .io_in_13_bits_dbID (12'h0), .io_in_13_bits_fwdNID (11'h0), .io_in_13_bits_fwdTxnID (12'h0), .io_in_13_bits_chiOpcode (arb_in_task[13].chiOpcode), .io_in_13_bits_resp (3'h0), .io_in_13_bits_fwdState (3'h0), .io_in_13_bits_pCrdType (4'h0), .io_in_13_bits_retToSrc (arb_in_task[13].retToSrc), .io_in_13_bits_doNotGoToSD (arb_in_task[13].doNotGoToSD), .io_in_13_bits_expCompAck (1'h0), .io_in_13_bits_allowRetry (1'h0), .io_in_13_bits_order (2'h0), .io_in_13_bits_memAttr_allocate (1'h0), .io_in_13_bits_memAttr_cacheable (1'h0), .io_in_13_bits_memAttr_device (1'h0), .io_in_13_bits_memAttr_ewa (1'h0), .io_in_13_bits_snpAttr (1'h0),
    .io_in_14_valid (arb_in_valid[14]), .io_in_14_bits_set (arb_in_task[14].set), .io_in_14_bits_bank (arb_in_task[14].bank), .io_in_14_bits_tag (arb_in_task[14].tag), .io_in_14_bits_off (6'h0), .io_in_14_bits_size (3'h0), .io_in_14_bits_refillTask (1'h0), .io_in_14_bits_bufID (4'h0), .io_in_14_bits_reqID (12'h0), .io_in_14_bits_replSnp (arb_in_task[14].replSnp), .io_in_14_bits_snpVec_0 (arb_in_task[14].snpVec_0), .io_in_14_bits_tgtID (11'h0), .io_in_14_bits_srcID (11'h0), .io_in_14_bits_txnID (arb_in_task[14].txnID), .io_in_14_bits_dbID (12'h0), .io_in_14_bits_fwdNID (11'h0), .io_in_14_bits_fwdTxnID (12'h0), .io_in_14_bits_chiOpcode (arb_in_task[14].chiOpcode), .io_in_14_bits_resp (3'h0), .io_in_14_bits_fwdState (3'h0), .io_in_14_bits_pCrdType (4'h0), .io_in_14_bits_retToSrc (arb_in_task[14].retToSrc), .io_in_14_bits_doNotGoToSD (arb_in_task[14].doNotGoToSD), .io_in_14_bits_expCompAck (1'h0), .io_in_14_bits_allowRetry (1'h0), .io_in_14_bits_order (2'h0), .io_in_14_bits_memAttr_allocate (1'h0), .io_in_14_bits_memAttr_cacheable (1'h0), .io_in_14_bits_memAttr_device (1'h0), .io_in_14_bits_memAttr_ewa (1'h0), .io_in_14_bits_snpAttr (1'h0),
    .io_in_15_valid (arb_in_valid[15]), .io_in_15_bits_set (arb_in_task[15].set), .io_in_15_bits_bank (arb_in_task[15].bank), .io_in_15_bits_tag (arb_in_task[15].tag), .io_in_15_bits_off (6'h0), .io_in_15_bits_size (3'h0), .io_in_15_bits_refillTask (1'h0), .io_in_15_bits_bufID (4'h0), .io_in_15_bits_reqID (12'h0), .io_in_15_bits_replSnp (arb_in_task[15].replSnp), .io_in_15_bits_snpVec_0 (arb_in_task[15].snpVec_0), .io_in_15_bits_tgtID (11'h0), .io_in_15_bits_srcID (11'h0), .io_in_15_bits_txnID (arb_in_task[15].txnID), .io_in_15_bits_dbID (12'h0), .io_in_15_bits_fwdNID (11'h0), .io_in_15_bits_fwdTxnID (12'h0), .io_in_15_bits_chiOpcode (arb_in_task[15].chiOpcode), .io_in_15_bits_resp (3'h0), .io_in_15_bits_fwdState (3'h0), .io_in_15_bits_pCrdType (4'h0), .io_in_15_bits_retToSrc (arb_in_task[15].retToSrc), .io_in_15_bits_doNotGoToSD (arb_in_task[15].doNotGoToSD), .io_in_15_bits_expCompAck (1'h0), .io_in_15_bits_allowRetry (1'h0), .io_in_15_bits_order (2'h0), .io_in_15_bits_memAttr_allocate (1'h0), .io_in_15_bits_memAttr_cacheable (1'h0), .io_in_15_bits_memAttr_device (1'h0), .io_in_15_bits_memAttr_ewa (1'h0), .io_in_15_bits_snpAttr (1'h0),
    .io_out_ready                    (io_out_ready),
    .io_out_valid                    (arb_out_valid),
    .io_out_bits_set                 (arb_out_set),
    .io_out_bits_bank                (arb_out_bank),
    .io_out_bits_tag                 (arb_out_tag),
    .io_out_bits_off                 (/* unused */),
    .io_out_bits_size                (/* unused */),
    .io_out_bits_refillTask          (/* unused */),
    .io_out_bits_bufID               (/* unused */),
    .io_out_bits_reqID               (/* unused */),
    .io_out_bits_replSnp             (/* unused */),
    .io_out_bits_snpVec_0            (arb_out_snpVec_0),
    .io_out_bits_tgtID               (/* unused */),
    .io_out_bits_srcID               (/* unused */),
    .io_out_bits_txnID               (arb_out_txnID),
    .io_out_bits_dbID                (/* unused */),
    .io_out_bits_fwdNID              (arb_out_fwdNID),
    .io_out_bits_fwdTxnID            (arb_out_fwdTxnID),
    .io_out_bits_chiOpcode           (arb_out_chiOpcode),
    .io_out_bits_resp                (/* unused */),
    .io_out_bits_fwdState            (/* unused */),
    .io_out_bits_pCrdType            (/* unused */),
    .io_out_bits_retToSrc            (arb_out_retToSrc),
    .io_out_bits_doNotGoToSD         (arb_out_doNotGoToSD),
    .io_out_bits_expCompAck          (/* unused */),
    .io_out_bits_allowRetry          (/* unused */),
    .io_out_bits_order               (/* unused */),
    .io_out_bits_memAttr_allocate    (/* unused */),
    .io_out_bits_memAttr_cacheable   (/* unused */),
    .io_out_bits_memAttr_device      (/* unused */),
    .io_out_bits_memAttr_ewa         (/* unused */),
    .io_out_bits_snpAttr             (/* unused */),
    .io_chosen                       (arb_chosen)
  );

  // -------------------- 输出装配(canFlow 旁路 vs 仲裁器) --------------------
  assign io_out_valid           = (io_in_valid & canFlow) | arb_out_valid;
  assign io_out_bits_set        = canFlow ? io_in_task.set       : arb_out_set;
  assign io_out_bits_bank       = canFlow ? io_in_task.bank      : arb_out_bank;
  assign io_out_bits_tag        = canFlow ? io_in_task.tag       : arb_out_tag;
  assign io_out_bits_snpVec_0   = canFlow ? io_in_task.snpVec_0  : arb_out_snpVec_0;
  assign io_out_bits_txnID      = canFlow ? io_in_task.txnID     : arb_out_txnID;
  assign io_out_bits_fwdNID     = canFlow ? 11'h0                : arb_out_fwdNID;
  assign io_out_bits_fwdTxnID   = canFlow ? 12'h0                : arb_out_fwdTxnID;
  assign io_out_bits_chiOpcode  = canFlow ? io_in_task.chiOpcode : arb_out_chiOpcode;
  assign io_out_bits_retToSrc   = canFlow ? io_in_task.retToSrc  : arb_out_retToSrc;
  assign io_out_bits_doNotGoToSD = canFlow | arb_out_doNotGoToSD;

endmodule
