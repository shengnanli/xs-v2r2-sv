// RequestBuffer.sv —— L2 slice 的 A 通道请求缓冲（SinkA -> RequestArb 之间的 4 项等待区）
//
// 对照 coupledL2/src/main/scala/coupledL2/RequestBuffer.scala（flow = true, entries = 4）。
// 上游 SinkA 送来的 A 请求（Acquire / Get / Hint 等）不一定能马上进 MainPipe：同地址的 MSHR 还没完、
// MainPipe 正在处理同 set 的任务、这个 set 的 8 路已经被在飞请求占满……于是先在这里等。
//
// 主要机制：
//   * 直通（flow）：缓冲没满、没有地址冲突、chosenQ 空、MainPipe 不挡、这个 set 还有空路时，请求当拍直接
//     从 io_in 送到 io_out，不进缓冲。
//   * 分配：不能直通、又不是可丢弃的重复预取、也不能并进 MSHR 时，放进第一个空表项，并记下它在等什么：
//       waitMS —— 与哪些在飞 MSHR 地址冲突（同 set 且 tag 相同，或 MSHR 要替换掉的正是这一行）；
//       waitMP —— MainPipe 流水线里是否有同 set 的任务（[3] s1、[2] s2、[1] s3，逐拍右移），
//       rdy    —— 上面都清了、且该 set 还有空路（noFreeWay）才置 1。
//   * 更新（每拍，对有效表项）：MSHR 释放时从 waitMS 里清掉；waitMP 右移；waitMP 刚走完（[1]=0,[0]=1）
//     时重算一次 waitMS（把期间新分配的 MSHR 算进来）；本拍 s1 有同 set 任务进入就把 waitMP 置 0100。
//   * 发射：4 个 rdy 表项经 FastArbiter_2（轮转）挑一个进 chosenQ（1 项 pipe 队列，记下表项号）；出队时
//     若该表项已不 rdy（期间条件变了）就取消本次出队，表项留在缓冲里下次再发。
//   * 去重 / 合并：Hint 预取若与在飞 MSHR 或缓冲里的请求同地址，直接丢掉（算 ready）；Acquire 若命中一个
//     "晚到的预取" MSHR（同地址、还没 refill、没被合并过……），就并进那个 MSHR（aMergeTask），不占缓冲。
//   * noFreeWay：在飞 MSHR（A 通道的）+ MainPipe s2 + s3 上同 set 的 A 请求个数 >= 8 路 ⇒ 这个 set 暂时没路可用。
//     s3 的那一份来自两拍前 RequestArb 的 s2 任务（RegNext）。★Scala 在每个调用点各建一份这两个寄存器★
//     （直通判定 1 份、分配 1 份、4 个表项各 1 份，共 6 份，值恒相等），golden 保留全部 6 份，这里照抄。
//   * 统计输出：hasHitPfInMSHR（命中晚到预取）、hasPfLateInMSHR（丢弃的重复预取）、hasMergeA，都与上一拍
//     同地址时不重复报（RegNext(in) 两份，golden 也是两份）。
// perf 专用寄存器（每项的驻留计时 bufferTimer 及其清零/采样用的 RegNext）只被 perf 打印与 `ifndef SYNTHESIS
// 的 assert 读，golden 仍把它们综合出来，这里照 golden 保留（CONVENTIONS「debug 寄存器照写」）。

package requestbuffer_pkg;
  // BEGIN GENERATED(types) —— scripts/gen_l2_reqbuf.py 从 golden 端口表生成
  // A 请求：io_in_bits_* 的字段（14 个字段，118 位）
  typedef struct packed {
    logic [8:0] set;
    logic [30:0] tag;
    logic [5:0] off;
    logic [1:0] alias_;
    logic [43:0] vaddr;
    logic isKeyword;
    logic [3:0] opcode;
    logic [2:0] param;
    logic [2:0] size;
    logic [6:0] sourceId;
    logic corrupt;
    logic fromL2pft;
    logic needHint;
    logic [4:0] reqSource;
  } a_req_t;

  // 出口 TaskBundle：io_out_bits_* 的字段（93 个字段，375 位）
  typedef struct packed {
    logic [2:0] channel;
    logic [2:0] txChannel;
    logic [8:0] set;
    logic [30:0] tag;
    logic [5:0] off;
    logic [1:0] alias_;
    logic [43:0] vaddr;
    logic isKeyword;
    logic [3:0] opcode;
    logic [2:0] param;
    logic [2:0] size;
    logic [6:0] sourceId;
    logic [1:0] bufIdx;
    logic needProbeAckData;
    logic denied;
    logic corrupt;
    logic mshrTask;
    logic [7:0] mshrId;
    logic aliasTask;
    logic useProbeData;
    logic mshrRetry;
    logic readProbeDataDown;
    logic fromL2pft;
    logic needHint;
    logic dirty;
    logic [2:0] way;
    logic meta_dirty;
    logic [1:0] meta_state;
    logic meta_clients;
    logic [1:0] meta_alias;
    logic meta_prefetch;
    logic [2:0] meta_prefetchSrc;
    logic meta_accessed;
    logic meta_tagErr;
    logic meta_dataErr;
    logic metaWen;
    logic tagWen;
    logic dsWen;
    logic replTask;
    logic cmoTask;
    logic cmoAll;
    logic [4:0] reqSource;
    logic mergeA;
    logic [5:0] aMergeTask_off;
    logic [1:0] aMergeTask_alias;
    logic [43:0] aMergeTask_vaddr;
    logic aMergeTask_isKeyword;
    logic [2:0] aMergeTask_opcode;
    logic [2:0] aMergeTask_param;
    logic [6:0] aMergeTask_sourceId;
    logic aMergeTask_meta_dirty;
    logic [1:0] aMergeTask_meta_state;
    logic aMergeTask_meta_clients;
    logic [1:0] aMergeTask_meta_alias;
    logic aMergeTask_meta_prefetch;
    logic [2:0] aMergeTask_meta_prefetchSrc;
    logic aMergeTask_meta_accessed;
    logic aMergeTask_meta_tagErr;
    logic aMergeTask_meta_dataErr;
    logic snpHitRelease;
    logic snpHitReleaseToInval;
    logic snpHitReleaseToClean;
    logic snpHitReleaseWithData;
    logic [7:0] snpHitReleaseIdx;
    logic snpHitReleaseMeta_dirty;
    logic [1:0] snpHitReleaseMeta_state;
    logic snpHitReleaseMeta_clients;
    logic [1:0] snpHitReleaseMeta_alias;
    logic snpHitReleaseMeta_prefetch;
    logic [2:0] snpHitReleaseMeta_prefetchSrc;
    logic snpHitReleaseMeta_accessed;
    logic snpHitReleaseMeta_tagErr;
    logic snpHitReleaseMeta_dataErr;
    logic [10:0] tgtID;
    logic [10:0] srcID;
    logic [11:0] txnID;
    logic [10:0] homeNID;
    logic [11:0] dbID;
    logic [10:0] fwdNID;
    logic [11:0] fwdTxnID;
    logic [6:0] chiOpcode;
    logic [2:0] resp;
    logic [2:0] fwdState;
    logic [3:0] pCrdType;
    logic retToSrc;
    logic likelyshared;
    logic expCompAck;
    logic allowRetry;
    logic memAttr_allocate;
    logic memAttr_cacheable;
    logic memAttr_device;
    logic memAttr_ewa;
    logic traceTag;
  } task_t;

  // 缓冲表项 ReqEntry（= FastArbiter_2 载荷 / chosenQ 入队字段）
  typedef struct packed {
    logic        valid;
    logic        rdy;
    logic [2:0]  channel;
    a_req_t      req;
    logic [3:0]  waitMP;
    logic [15:0] waitMS;
  } entry_t;
  // END GENERATED(types)

  localparam int unsigned N_ENTRY = 4;
  localparam int unsigned N_MSHR  = 16;
  localparam int unsigned WAYS    = 8;
  // TileLink A 通道 opcode / param
  localparam logic [3:0] A_Hint         = 4'd5;
  localparam logic [3:0] A_AcquireBlock = 4'd6;
  localparam logic [3:0] A_AcquirePerm  = 4'd7;
  localparam logic [2:0] NtoB           = 3'd0;
  localparam logic [2:0] NtoT           = 3'd1;
endpackage

module xs_RequestBuffer_core
  import requestbuffer_pkg::*;
(
  input  logic               clock,
  input  logic               reset,

  // ---- 入口（SinkA）----
  input  logic               in_valid,
  output logic               in_ready,
  input  a_req_t             in_req,

  // ---- 出口（RequestArb.sinkA）：直通时取 in，否则取 chosenQ ----
  input  logic               out_ready,
  output logic               out_valid,
  output task_t              out_task,

  // ---- MSHR 状态 ----
  input  logic               ms_valid           [N_MSHR],
  input  logic [2:0]         ms_channel         [N_MSHR],
  input  logic [8:0]         ms_set             [N_MSHR],
  input  logic [30:0]        ms_reqTag          [N_MSHR],
  input  logic [30:0]        ms_metaTag         [N_MSHR],
  input  logic               ms_willFree        [N_MSHR],
  input  logic               ms_needRelease     [N_MSHR],
  input  logic [2:0]         ms_prefetchSrc     [N_MSHR],
  input  logic               ms_dirHit          [N_MSHR],
  input  logic               ms_isAcqOrPrefetch [N_MSHR],
  input  logic               ms_isPrefetch      [N_MSHR],
  input  logic [2:0]         ms_param           [N_MSHR],
  input  logic               ms_mergeA          [N_MSHR],
  input  logic               ms_s_refill        [N_MSHR],

  // ---- MainPipe / RequestArb 状态 ----
  input  logic               mainPipeBlock      [2],
  input  logic               arbS2_valid,
  input  logic [2:0]         arbS2_channel,
  input  logic [8:0]         arbS2_set,
  input  logic               arbS2_mshrTask,
  input  logic               s1Entrance_valid,
  input  logic [8:0]         s1Entrance_set,

  // ---- 发射仲裁器 issueArb（FastArbiter_2）----
  output logic               arbIn_valid        [N_ENTRY],
  output entry_t             arbIn_entry        [N_ENTRY],
  input  logic               arbOut_valid,
  input  entry_t             arbOut_entry,
  input  logic [1:0]         arbOut_chosen,

  // ---- 发射队列 chosenQ（Queue1_ChosenQBundle）----
  output logic               chosenQ_enqValid,
  output entry_t             chosenQ_enqEntry,
  output logic [1:0]         chosenQ_enqId,
  input  logic               chosenQ_enqReady,
  input  logic               chosenQ_deqValid,
  input  task_t              chosenQ_deqTask,
  input  logic [1:0]         chosenQ_deqId,
  output logic               chosenQ_deqReady,

  // ---- 合并 / 统计 ----
  output logic               aMergeTask_valid,
  output logic [7:0]         aMergeTask_id,
  output logic               hasHitPfInMSHR_valid,
  output logic [2:0]         hasHitPfInMSHR_bits,
  output logic               hasPfLateInMSHR_valid,
  output logic               hasMergeA
);

  // ===========================================================================
  // noFreeWay：该 set 的在飞 A 请求（MSHR + s2 + s3）已占满 8 路
  //   s3 份额来自 RegNext；Scala 每个调用点各建一份（见文件头），这里用 6 份同构寄存器
  // ===========================================================================
  localparam int unsigned N_SITE = 2 + N_ENTRY;   // 0 = 直通判定，1 = 分配，2..5 = 表项 0..3
  logic       arbS2IsA;                           // s2 上是 A 通道的非 MSHR 任务
  logic       sameSetS3Valid [N_SITE];            // RegNext(arbS2IsA)
  logic [8:0] sameSetS3Set   [N_SITE];            // RegEnable(s2.set, s2.valid)

  assign arbS2IsA = arbS2_valid & arbS2_channel[0] & ~arbS2_mshrTask;

  always_ff @(posedge clock) begin
    for (int k = 0; k < N_SITE; k++) begin
      sameSetS3Valid[k] <= arbS2IsA;
      if (arbS2_valid) sameSetS3Set[k] <= arbS2_set;
    end
  end

  // ===========================================================================
  // 缓冲表项（per-field 数组）
  // ===========================================================================
  logic        buffer_valid  [N_ENTRY];
  logic        buffer_rdy    [N_ENTRY];
  a_req_t      buffer_task   [N_ENTRY];
  logic [2:0]  buffer_channel[N_ENTRY];   // 恒写 1（A 通道）；golden 仍存这 3 位
  logic [3:0]  buffer_waitMP [N_ENTRY];
  logic [15:0] buffer_waitMS [N_ENTRY];

  logic full;
  always_comb begin
    full = 1'b1;
    for (int k = 0; k < N_ENTRY; k++) full &= buffer_valid[k];
  end

  // ===========================================================================
  // 地址冲突与 noFreeWay（对入口请求、以及每个表项各算一份）
  //   冲突：MSHR i 有效、同 set，且 tag 等于它请求的 tag、或等于它要替换掉的 tag（要 release 时），且不在释放
  //   noFreeWay：在飞 A 通道 MSHR + s2 + s3 上同 set 的个数 >= 8
  // ===========================================================================
  logic [N_MSHR-1:0] inConflict;                  // 入口请求与哪些 MSHR 冲突
  logic [N_MSHR-1:0] entryConflict [N_ENTRY];     // 表项 k 与哪些 MSHR 冲突
  logic [4:0]        inMshrSameSet;               // 同 set 的在飞 A 通道 MSHR 个数（入口请求）
  logic [4:0]        entryMshrSameSet [N_ENTRY];

  always_comb begin
    inMshrSameSet = '0;
    for (int i = 0; i < N_MSHR; i++) begin
      inConflict[i] = ms_valid[i] && in_req.set == ms_set[i] &&
                      (in_req.tag == ms_reqTag[i] || (in_req.tag == ms_metaTag[i] && ms_needRelease[i])) &&
                      !ms_willFree[i];
      inMshrSameSet += 5'(ms_valid[i] && ms_set[i] == in_req.set && ms_channel[i][0]);
    end
    for (int k = 0; k < N_ENTRY; k++) begin
      entryMshrSameSet[k] = '0;
      for (int i = 0; i < N_MSHR; i++) begin
        entryConflict[k][i] = ms_valid[i] && buffer_task[k].set == ms_set[i] &&
                              (buffer_task[k].tag == ms_reqTag[i] ||
                               (buffer_task[k].tag == ms_metaTag[i] && ms_needRelease[i])) &&
                              !ms_willFree[i];
        entryMshrSameSet[k] += 5'(ms_valid[i] && ms_set[i] == buffer_task[k].set && ms_channel[i][0]);
      end
    end
  end

  // 各调用点的 noFreeWay（s3 份额用各自那份寄存器）
  logic flowNoFreeWay, allocNoFreeWay;
  logic entryNoFreeWay [N_ENTRY];
  assign flowNoFreeWay  = 5'(inMshrSameSet + 5'(arbS2IsA && arbS2_set == in_req.set)
                             + 5'(sameSetS3Valid[0] && sameSetS3Set[0] == in_req.set)) >= 5'(WAYS);
  assign allocNoFreeWay = 5'(inMshrSameSet + 5'(arbS2IsA && arbS2_set == in_req.set)
                             + 5'(sameSetS3Valid[1] && sameSetS3Set[1] == in_req.set)) >= 5'(WAYS);
  for (genvar k = 0; k < int'(N_ENTRY); k++) begin : g_nfw
    assign entryNoFreeWay[k] = 5'(entryMshrSameSet[k] + 5'(arbS2IsA && arbS2_set == buffer_task[k].set)
                                  + 5'(sameSetS3Valid[2+k] && sameSetS3Set[2+k] == buffer_task[k].set)) >= 5'(WAYS);
  end

  // ===========================================================================
  // 入口判定：冲突 / 合并 / 去重 / 直通
  // ===========================================================================
  logic [N_MSHR-1:0] mergeAMask;       // 可以并进哪个晚到预取 MSHR
  logic [N_MSHR-1:0] latePfMatch;      // 命中晚到预取（统计用）
  logic [N_MSHR-1:0] dupMshr;
  logic [N_ENTRY-1:0] dupBuf;
  logic inIsAcquire, isPrefetch, mergeA, dup, mpBlock, canFlow, doFlow, alloc;

  assign inIsAcquire = in_req.opcode == A_AcquireBlock || in_req.opcode == A_AcquirePerm;  // SinkA 请求恒为 A 通道
  assign isPrefetch  = in_req.opcode == A_Hint;
  assign mpBlock     = mainPipeBlock[0] | mainPipeBlock[1];

  always_comb begin
    for (int i = 0; i < N_MSHR; i++) begin
      logic sameAddr;
      sameAddr       = {in_req.tag, in_req.set} == {ms_reqTag[i], ms_set[i]};
      latePfMatch[i] = ms_valid[i] && ms_isPrefetch[i] && sameAddr && !ms_willFree[i] && inIsAcquire;
      mergeAMask[i]  = latePfMatch[i] && !ms_dirHit[i] && !ms_s_refill[i] && !ms_mergeA[i] &&
                       !(in_req.param == NtoT && ms_param[i] == NtoB);
      dupMshr[i]     = ms_valid[i] && ms_isAcqOrPrefetch[i] && sameAddr;
    end
    for (int k = 0; k < N_ENTRY; k++)
      dupBuf[k] = buffer_valid[k] && {in_req.tag, in_req.set} == {buffer_task[k].tag, buffer_task[k].set};
  end

  assign mergeA      = |mergeAMask;
  assign dup         = isPrefetch & ((|dupMshr) | (|dupBuf));
  assign canFlow     = ~full & ~(|inConflict) & ~chosenQ_deqValid & ~mpBlock & ~flowNoFreeWay;
  assign doFlow      = canFlow & out_ready;
  assign in_ready    = ~full | doFlow | mergeA | dup;
  assign alloc       = ~full & in_valid & ~doFlow & ~dup & ~mergeA;

  // 合并：OHToUInt(mergeAMask)（正常至多一位）
  always_comb begin
    aMergeTask_id = '0;
    for (int i = 0; i < N_MSHR; i++) if (mergeAMask[i]) aMergeTask_id |= 8'(i);
  end
  assign aMergeTask_valid = in_valid & mergeA;

  // ===========================================================================
  // 出口：chosenQ 队头若已不 rdy 则取消（表项留着下次再发）
  // ===========================================================================
  logic headRdy, cancel;
  assign headRdy          = buffer_rdy[chosenQ_deqId];
  assign cancel           = ~headRdy;
  assign chosenQ_deqReady = out_ready | cancel;
  assign out_valid        = (chosenQ_deqValid & ~cancel) | (in_valid & canFlow);

  task_t inAsTask;                     // 直通时的出口任务：A 请求字段 + channel=A，其余字段为 0
  always_comb begin
    inAsTask           = '0;
    inAsTask.channel   = 3'd1;
    inAsTask.set       = in_req.set;
    inAsTask.tag       = in_req.tag;
    inAsTask.off       = in_req.off;
    inAsTask.alias_    = in_req.alias_;
    inAsTask.vaddr     = in_req.vaddr;
    inAsTask.isKeyword = in_req.isKeyword;
    inAsTask.opcode    = in_req.opcode;
    inAsTask.param     = in_req.param;
    inAsTask.size      = in_req.size;
    inAsTask.sourceId  = in_req.sourceId;
    inAsTask.corrupt   = in_req.corrupt;
    inAsTask.fromL2pft = in_req.fromL2pft;
    inAsTask.needHint  = in_req.needHint;
    inAsTask.reqSource = in_req.reqSource;
  end
  assign out_task = canFlow ? inAsTask : chosenQ_deqTask;

  // ===========================================================================
  // 发射：rdy 表项进仲裁器（出口本拍同 set 的暂缓），赢家进 chosenQ
  // ===========================================================================
  logic outFire;
  assign outFire = out_ready & out_valid;

  for (genvar k = 0; k < int'(N_ENTRY); k++) begin : g_issue
    assign arbIn_valid[k]       = buffer_valid[k] & buffer_rdy[k] & ~(out_valid & buffer_task[k].set == out_task.set);
    assign arbIn_entry[k].valid  = buffer_valid[k];
    assign arbIn_entry[k].rdy    = buffer_rdy[k];
    assign arbIn_entry[k].channel = buffer_channel[k];
    assign arbIn_entry[k].req    = buffer_task[k];
    assign arbIn_entry[k].waitMP = buffer_waitMP[k];
    assign arbIn_entry[k].waitMS = buffer_waitMS[k];
  end
  assign chosenQ_enqValid = arbOut_valid;
  assign chosenQ_enqEntry = arbOut_entry;
  assign chosenQ_enqId    = arbOut_chosen;

  // ===========================================================================
  // 表项更新
  // ===========================================================================
  logic [1:0] insertIdx;               // 第一个空表项（PriorityEncoder，全满时缺省 3）
  always_comb begin
    insertIdx = 2'd3;
    for (int k = N_ENTRY - 1; k >= 0; k--) if (!buffer_valid[k]) insertIdx = 2'(k);
  end

  // 新分配表项的初始状态
  logic inS1Block, allocRdy;
  logic [3:0] allocWaitMP;
  assign inS1Block   = (outFire & in_req.set == out_task.set) | (s1Entrance_valid & s1Entrance_set == in_req.set);
  assign allocRdy    = ~(|inConflict) & ~mpBlock & ~inS1Block & ~allocNoFreeWay;
  assign allocWaitMP = {inS1Block, mainPipeBlock[0], mainPipeBlock[1], 1'b0};

  logic [N_MSHR-1:0] willFreeMask;
  always_comb for (int i = 0; i < N_MSHR; i++) willFreeMask[i] = ms_valid[i] & ms_willFree[i];

  logic deqIssued;                     // chosenQ 队头这拍真正发出去（没取消）
  assign deqIssued = chosenQ_deqReady & chosenQ_deqValid & headRdy;

  for (genvar k = 0; k < int'(N_ENTRY); k++) begin : g_entry
    logic        allocHere, s1Block;
    logic [15:0] waitMSUpdate;
    assign allocHere = alloc & (insertIdx == 2'(k));
    assign s1Block   = (outFire & buffer_task[k].set == out_task.set) |
                       (s1Entrance_valid & s1Entrance_set == buffer_task[k].set);
    // waitMP 刚走完（[1]=0,[0]=1）时整体重算冲突，否则只清掉将释放的 MSHR
    assign waitMSUpdate = (~buffer_waitMP[k][1] & buffer_waitMP[k][0]) ? entryConflict[k]
                                                                       : (buffer_waitMS[k] & ~willFreeMask);

    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        buffer_valid[k]   <= 1'b0;
        buffer_rdy[k]     <= 1'b0;
        buffer_task[k]    <= '0;
        buffer_channel[k] <= '0;
        buffer_waitMP[k]  <= '0;
        buffer_waitMS[k]  <= '0;
      end else begin
        buffer_valid[k] <= ~(deqIssued & chosenQ_deqId == 2'(k)) & (allocHere | buffer_valid[k]);
        if (buffer_valid[k]) begin
          buffer_rdy[k]    <= waitMSUpdate == '0 && buffer_waitMP[k] == '0 && !s1Block && !entryNoFreeWay[k];
          buffer_waitMP[k] <= {1'b0, {s1Block, 2'b00} | buffer_waitMP[k][3:1]};   // 右移，s1 同 set 时置 0100
          buffer_waitMS[k] <= waitMSUpdate;
        end else if (allocHere) begin
          buffer_rdy[k]    <= allocRdy;
          buffer_waitMP[k] <= allocWaitMP;
          buffer_waitMS[k] <= inConflict;
        end
        if (allocHere) begin
          buffer_task[k]    <= in_req;
          buffer_channel[k] <= 3'd1;
        end
      end
    end
  end

  // ===========================================================================
  // 统计输出（与上一拍同地址不重复报；RegNext(in) 两份，golden 如此）
  // ===========================================================================
  logic [8:0]  hitPfPrev_set,  mergeAPrev_set;
  logic [30:0] hitPfPrev_tag,  mergeAPrev_tag;
  always_ff @(posedge clock) begin
    hitPfPrev_set  <= in_req.set;
    hitPfPrev_tag  <= in_req.tag;
    mergeAPrev_set <= in_req.set;
    mergeAPrev_tag <= in_req.tag;
  end

  assign hasHitPfInMSHR_valid  = (|latePfMatch) & in_valid & ({in_req.tag, in_req.set} != {hitPfPrev_tag, hitPfPrev_set});
  assign hasPfLateInMSHR_valid = in_valid & dup;
  assign hasMergeA             = mergeA & in_valid & ({in_req.tag, in_req.set} != {mergeAPrev_tag, mergeAPrev_set});
  // 命中的晚到预取 MSHR 的预取来源：ParallelPriorityMux（编号小的优先，全不命中时取最后一个）
  always_comb begin
    hasHitPfInMSHR_bits = ms_prefetchSrc[N_MSHR-1];
    for (int i = N_MSHR - 2; i >= 0; i--) if (latePfMatch[i]) hasHitPfInMSHR_bits = ms_prefetchSrc[i];
  end

  // ===========================================================================
  // perf 专用寄存器（只被 perf 打印 / `ifndef SYNTHESIS 的 assert 读；照 golden 保留）
  //   bufferTimer[k]：表项 k 的驻留拍数，表项释放后两拍清零
  // ===========================================================================
  logic [15:0] bufferTimer   [N_ENTRY];
  logic        validPrev     [N_ENTRY];   // RegNext(valid)
  logic        timerClear    [N_ENTRY];   // RegNext(RegNext(valid) && !valid)
  logic        histValidPrev [N_ENTRY];   // 直方图采样用的 RegNext(valid)
  always_ff @(posedge clock) begin
    for (int k = 0; k < N_ENTRY; k++) begin
      validPrev[k]     <= buffer_valid[k];
      timerClear[k]    <= validPrev[k] & ~buffer_valid[k];
      histValidPrev[k] <= buffer_valid[k];
    end
  end
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int k = 0; k < N_ENTRY; k++) bufferTimer[k] <= '0;
    end else begin
      for (int k = 0; k < N_ENTRY; k++) begin
        if (timerClear[k])        bufferTimer[k] <= '0;
        else if (buffer_valid[k]) bufferTimer[k] <= bufferTimer[k] + 16'd1;
      end
    end
  end

endmodule

// BEGIN GENERATED(wrapper) —— scripts/gen_l2_reqbuf.py 从 golden 端口表生成
module RequestBuffer
  import requestbuffer_pkg::*;
(
  input  logic clock,
  input  logic reset,
  output logic io_in_ready,
  input  logic io_in_valid,
  input  logic [8:0] io_in_bits_set,
  input  logic [30:0] io_in_bits_tag,
  input  logic [5:0] io_in_bits_off,
  input  logic [1:0] io_in_bits_alias,
  input  logic [43:0] io_in_bits_vaddr,
  input  logic io_in_bits_isKeyword,
  input  logic [3:0] io_in_bits_opcode,
  input  logic [2:0] io_in_bits_param,
  input  logic [2:0] io_in_bits_size,
  input  logic [6:0] io_in_bits_sourceId,
  input  logic io_in_bits_corrupt,
  input  logic io_in_bits_fromL2pft,
  input  logic io_in_bits_needHint,
  input  logic [4:0] io_in_bits_reqSource,
  input  logic io_out_ready,
  output logic io_out_valid,
  output logic [2:0] io_out_bits_channel,
  output logic [2:0] io_out_bits_txChannel,
  output logic [8:0] io_out_bits_set,
  output logic [30:0] io_out_bits_tag,
  output logic [5:0] io_out_bits_off,
  output logic [1:0] io_out_bits_alias,
  output logic [43:0] io_out_bits_vaddr,
  output logic io_out_bits_isKeyword,
  output logic [3:0] io_out_bits_opcode,
  output logic [2:0] io_out_bits_param,
  output logic [2:0] io_out_bits_size,
  output logic [6:0] io_out_bits_sourceId,
  output logic [1:0] io_out_bits_bufIdx,
  output logic io_out_bits_needProbeAckData,
  output logic io_out_bits_denied,
  output logic io_out_bits_corrupt,
  output logic io_out_bits_mshrTask,
  output logic [7:0] io_out_bits_mshrId,
  output logic io_out_bits_aliasTask,
  output logic io_out_bits_useProbeData,
  output logic io_out_bits_mshrRetry,
  output logic io_out_bits_readProbeDataDown,
  output logic io_out_bits_fromL2pft,
  output logic io_out_bits_needHint,
  output logic io_out_bits_dirty,
  output logic [2:0] io_out_bits_way,
  output logic io_out_bits_meta_dirty,
  output logic [1:0] io_out_bits_meta_state,
  output logic io_out_bits_meta_clients,
  output logic [1:0] io_out_bits_meta_alias,
  output logic io_out_bits_meta_prefetch,
  output logic [2:0] io_out_bits_meta_prefetchSrc,
  output logic io_out_bits_meta_accessed,
  output logic io_out_bits_meta_tagErr,
  output logic io_out_bits_meta_dataErr,
  output logic io_out_bits_metaWen,
  output logic io_out_bits_tagWen,
  output logic io_out_bits_dsWen,
  output logic io_out_bits_replTask,
  output logic io_out_bits_cmoTask,
  output logic io_out_bits_cmoAll,
  output logic [4:0] io_out_bits_reqSource,
  output logic io_out_bits_mergeA,
  output logic [5:0] io_out_bits_aMergeTask_off,
  output logic [1:0] io_out_bits_aMergeTask_alias,
  output logic [43:0] io_out_bits_aMergeTask_vaddr,
  output logic io_out_bits_aMergeTask_isKeyword,
  output logic [2:0] io_out_bits_aMergeTask_opcode,
  output logic [2:0] io_out_bits_aMergeTask_param,
  output logic [6:0] io_out_bits_aMergeTask_sourceId,
  output logic io_out_bits_aMergeTask_meta_dirty,
  output logic [1:0] io_out_bits_aMergeTask_meta_state,
  output logic io_out_bits_aMergeTask_meta_clients,
  output logic [1:0] io_out_bits_aMergeTask_meta_alias,
  output logic io_out_bits_aMergeTask_meta_prefetch,
  output logic [2:0] io_out_bits_aMergeTask_meta_prefetchSrc,
  output logic io_out_bits_aMergeTask_meta_accessed,
  output logic io_out_bits_aMergeTask_meta_tagErr,
  output logic io_out_bits_aMergeTask_meta_dataErr,
  output logic io_out_bits_snpHitRelease,
  output logic io_out_bits_snpHitReleaseToInval,
  output logic io_out_bits_snpHitReleaseToClean,
  output logic io_out_bits_snpHitReleaseWithData,
  output logic [7:0] io_out_bits_snpHitReleaseIdx,
  output logic io_out_bits_snpHitReleaseMeta_dirty,
  output logic [1:0] io_out_bits_snpHitReleaseMeta_state,
  output logic io_out_bits_snpHitReleaseMeta_clients,
  output logic [1:0] io_out_bits_snpHitReleaseMeta_alias,
  output logic io_out_bits_snpHitReleaseMeta_prefetch,
  output logic [2:0] io_out_bits_snpHitReleaseMeta_prefetchSrc,
  output logic io_out_bits_snpHitReleaseMeta_accessed,
  output logic io_out_bits_snpHitReleaseMeta_tagErr,
  output logic io_out_bits_snpHitReleaseMeta_dataErr,
  output logic [10:0] io_out_bits_tgtID,
  output logic [10:0] io_out_bits_srcID,
  output logic [11:0] io_out_bits_txnID,
  output logic [10:0] io_out_bits_homeNID,
  output logic [11:0] io_out_bits_dbID,
  output logic [10:0] io_out_bits_fwdNID,
  output logic [11:0] io_out_bits_fwdTxnID,
  output logic [6:0] io_out_bits_chiOpcode,
  output logic [2:0] io_out_bits_resp,
  output logic [2:0] io_out_bits_fwdState,
  output logic [3:0] io_out_bits_pCrdType,
  output logic io_out_bits_retToSrc,
  output logic io_out_bits_likelyshared,
  output logic io_out_bits_expCompAck,
  output logic io_out_bits_allowRetry,
  output logic io_out_bits_memAttr_allocate,
  output logic io_out_bits_memAttr_cacheable,
  output logic io_out_bits_memAttr_device,
  output logic io_out_bits_memAttr_ewa,
  output logic io_out_bits_traceTag,
  input  logic io_mshrInfo_0_valid,
  input  logic [2:0] io_mshrInfo_0_bits_channel,
  input  logic [8:0] io_mshrInfo_0_bits_set,
  input  logic [30:0] io_mshrInfo_0_bits_reqTag,
  input  logic io_mshrInfo_0_bits_willFree,
  input  logic io_mshrInfo_0_bits_needRelease,
  input  logic [2:0] io_mshrInfo_0_bits_meta_prefetchSrc,
  input  logic [30:0] io_mshrInfo_0_bits_metaTag,
  input  logic io_mshrInfo_0_bits_dirHit,
  input  logic io_mshrInfo_0_bits_isAcqOrPrefetch,
  input  logic io_mshrInfo_0_bits_isPrefetch,
  input  logic [2:0] io_mshrInfo_0_bits_param,
  input  logic io_mshrInfo_0_bits_mergeA,
  input  logic io_mshrInfo_0_bits_s_refill,
  input  logic io_mshrInfo_1_valid,
  input  logic [2:0] io_mshrInfo_1_bits_channel,
  input  logic [8:0] io_mshrInfo_1_bits_set,
  input  logic [30:0] io_mshrInfo_1_bits_reqTag,
  input  logic io_mshrInfo_1_bits_willFree,
  input  logic io_mshrInfo_1_bits_needRelease,
  input  logic [2:0] io_mshrInfo_1_bits_meta_prefetchSrc,
  input  logic [30:0] io_mshrInfo_1_bits_metaTag,
  input  logic io_mshrInfo_1_bits_dirHit,
  input  logic io_mshrInfo_1_bits_isAcqOrPrefetch,
  input  logic io_mshrInfo_1_bits_isPrefetch,
  input  logic [2:0] io_mshrInfo_1_bits_param,
  input  logic io_mshrInfo_1_bits_mergeA,
  input  logic io_mshrInfo_1_bits_s_refill,
  input  logic io_mshrInfo_2_valid,
  input  logic [2:0] io_mshrInfo_2_bits_channel,
  input  logic [8:0] io_mshrInfo_2_bits_set,
  input  logic [30:0] io_mshrInfo_2_bits_reqTag,
  input  logic io_mshrInfo_2_bits_willFree,
  input  logic io_mshrInfo_2_bits_needRelease,
  input  logic [2:0] io_mshrInfo_2_bits_meta_prefetchSrc,
  input  logic [30:0] io_mshrInfo_2_bits_metaTag,
  input  logic io_mshrInfo_2_bits_dirHit,
  input  logic io_mshrInfo_2_bits_isAcqOrPrefetch,
  input  logic io_mshrInfo_2_bits_isPrefetch,
  input  logic [2:0] io_mshrInfo_2_bits_param,
  input  logic io_mshrInfo_2_bits_mergeA,
  input  logic io_mshrInfo_2_bits_s_refill,
  input  logic io_mshrInfo_3_valid,
  input  logic [2:0] io_mshrInfo_3_bits_channel,
  input  logic [8:0] io_mshrInfo_3_bits_set,
  input  logic [30:0] io_mshrInfo_3_bits_reqTag,
  input  logic io_mshrInfo_3_bits_willFree,
  input  logic io_mshrInfo_3_bits_needRelease,
  input  logic [2:0] io_mshrInfo_3_bits_meta_prefetchSrc,
  input  logic [30:0] io_mshrInfo_3_bits_metaTag,
  input  logic io_mshrInfo_3_bits_dirHit,
  input  logic io_mshrInfo_3_bits_isAcqOrPrefetch,
  input  logic io_mshrInfo_3_bits_isPrefetch,
  input  logic [2:0] io_mshrInfo_3_bits_param,
  input  logic io_mshrInfo_3_bits_mergeA,
  input  logic io_mshrInfo_3_bits_s_refill,
  input  logic io_mshrInfo_4_valid,
  input  logic [2:0] io_mshrInfo_4_bits_channel,
  input  logic [8:0] io_mshrInfo_4_bits_set,
  input  logic [30:0] io_mshrInfo_4_bits_reqTag,
  input  logic io_mshrInfo_4_bits_willFree,
  input  logic io_mshrInfo_4_bits_needRelease,
  input  logic [2:0] io_mshrInfo_4_bits_meta_prefetchSrc,
  input  logic [30:0] io_mshrInfo_4_bits_metaTag,
  input  logic io_mshrInfo_4_bits_dirHit,
  input  logic io_mshrInfo_4_bits_isAcqOrPrefetch,
  input  logic io_mshrInfo_4_bits_isPrefetch,
  input  logic [2:0] io_mshrInfo_4_bits_param,
  input  logic io_mshrInfo_4_bits_mergeA,
  input  logic io_mshrInfo_4_bits_s_refill,
  input  logic io_mshrInfo_5_valid,
  input  logic [2:0] io_mshrInfo_5_bits_channel,
  input  logic [8:0] io_mshrInfo_5_bits_set,
  input  logic [30:0] io_mshrInfo_5_bits_reqTag,
  input  logic io_mshrInfo_5_bits_willFree,
  input  logic io_mshrInfo_5_bits_needRelease,
  input  logic [2:0] io_mshrInfo_5_bits_meta_prefetchSrc,
  input  logic [30:0] io_mshrInfo_5_bits_metaTag,
  input  logic io_mshrInfo_5_bits_dirHit,
  input  logic io_mshrInfo_5_bits_isAcqOrPrefetch,
  input  logic io_mshrInfo_5_bits_isPrefetch,
  input  logic [2:0] io_mshrInfo_5_bits_param,
  input  logic io_mshrInfo_5_bits_mergeA,
  input  logic io_mshrInfo_5_bits_s_refill,
  input  logic io_mshrInfo_6_valid,
  input  logic [2:0] io_mshrInfo_6_bits_channel,
  input  logic [8:0] io_mshrInfo_6_bits_set,
  input  logic [30:0] io_mshrInfo_6_bits_reqTag,
  input  logic io_mshrInfo_6_bits_willFree,
  input  logic io_mshrInfo_6_bits_needRelease,
  input  logic [2:0] io_mshrInfo_6_bits_meta_prefetchSrc,
  input  logic [30:0] io_mshrInfo_6_bits_metaTag,
  input  logic io_mshrInfo_6_bits_dirHit,
  input  logic io_mshrInfo_6_bits_isAcqOrPrefetch,
  input  logic io_mshrInfo_6_bits_isPrefetch,
  input  logic [2:0] io_mshrInfo_6_bits_param,
  input  logic io_mshrInfo_6_bits_mergeA,
  input  logic io_mshrInfo_6_bits_s_refill,
  input  logic io_mshrInfo_7_valid,
  input  logic [2:0] io_mshrInfo_7_bits_channel,
  input  logic [8:0] io_mshrInfo_7_bits_set,
  input  logic [30:0] io_mshrInfo_7_bits_reqTag,
  input  logic io_mshrInfo_7_bits_willFree,
  input  logic io_mshrInfo_7_bits_needRelease,
  input  logic [2:0] io_mshrInfo_7_bits_meta_prefetchSrc,
  input  logic [30:0] io_mshrInfo_7_bits_metaTag,
  input  logic io_mshrInfo_7_bits_dirHit,
  input  logic io_mshrInfo_7_bits_isAcqOrPrefetch,
  input  logic io_mshrInfo_7_bits_isPrefetch,
  input  logic [2:0] io_mshrInfo_7_bits_param,
  input  logic io_mshrInfo_7_bits_mergeA,
  input  logic io_mshrInfo_7_bits_s_refill,
  input  logic io_mshrInfo_8_valid,
  input  logic [2:0] io_mshrInfo_8_bits_channel,
  input  logic [8:0] io_mshrInfo_8_bits_set,
  input  logic [30:0] io_mshrInfo_8_bits_reqTag,
  input  logic io_mshrInfo_8_bits_willFree,
  input  logic io_mshrInfo_8_bits_needRelease,
  input  logic [2:0] io_mshrInfo_8_bits_meta_prefetchSrc,
  input  logic [30:0] io_mshrInfo_8_bits_metaTag,
  input  logic io_mshrInfo_8_bits_dirHit,
  input  logic io_mshrInfo_8_bits_isAcqOrPrefetch,
  input  logic io_mshrInfo_8_bits_isPrefetch,
  input  logic [2:0] io_mshrInfo_8_bits_param,
  input  logic io_mshrInfo_8_bits_mergeA,
  input  logic io_mshrInfo_8_bits_s_refill,
  input  logic io_mshrInfo_9_valid,
  input  logic [2:0] io_mshrInfo_9_bits_channel,
  input  logic [8:0] io_mshrInfo_9_bits_set,
  input  logic [30:0] io_mshrInfo_9_bits_reqTag,
  input  logic io_mshrInfo_9_bits_willFree,
  input  logic io_mshrInfo_9_bits_needRelease,
  input  logic [2:0] io_mshrInfo_9_bits_meta_prefetchSrc,
  input  logic [30:0] io_mshrInfo_9_bits_metaTag,
  input  logic io_mshrInfo_9_bits_dirHit,
  input  logic io_mshrInfo_9_bits_isAcqOrPrefetch,
  input  logic io_mshrInfo_9_bits_isPrefetch,
  input  logic [2:0] io_mshrInfo_9_bits_param,
  input  logic io_mshrInfo_9_bits_mergeA,
  input  logic io_mshrInfo_9_bits_s_refill,
  input  logic io_mshrInfo_10_valid,
  input  logic [2:0] io_mshrInfo_10_bits_channel,
  input  logic [8:0] io_mshrInfo_10_bits_set,
  input  logic [30:0] io_mshrInfo_10_bits_reqTag,
  input  logic io_mshrInfo_10_bits_willFree,
  input  logic io_mshrInfo_10_bits_needRelease,
  input  logic [2:0] io_mshrInfo_10_bits_meta_prefetchSrc,
  input  logic [30:0] io_mshrInfo_10_bits_metaTag,
  input  logic io_mshrInfo_10_bits_dirHit,
  input  logic io_mshrInfo_10_bits_isAcqOrPrefetch,
  input  logic io_mshrInfo_10_bits_isPrefetch,
  input  logic [2:0] io_mshrInfo_10_bits_param,
  input  logic io_mshrInfo_10_bits_mergeA,
  input  logic io_mshrInfo_10_bits_s_refill,
  input  logic io_mshrInfo_11_valid,
  input  logic [2:0] io_mshrInfo_11_bits_channel,
  input  logic [8:0] io_mshrInfo_11_bits_set,
  input  logic [30:0] io_mshrInfo_11_bits_reqTag,
  input  logic io_mshrInfo_11_bits_willFree,
  input  logic io_mshrInfo_11_bits_needRelease,
  input  logic [2:0] io_mshrInfo_11_bits_meta_prefetchSrc,
  input  logic [30:0] io_mshrInfo_11_bits_metaTag,
  input  logic io_mshrInfo_11_bits_dirHit,
  input  logic io_mshrInfo_11_bits_isAcqOrPrefetch,
  input  logic io_mshrInfo_11_bits_isPrefetch,
  input  logic [2:0] io_mshrInfo_11_bits_param,
  input  logic io_mshrInfo_11_bits_mergeA,
  input  logic io_mshrInfo_11_bits_s_refill,
  input  logic io_mshrInfo_12_valid,
  input  logic [2:0] io_mshrInfo_12_bits_channel,
  input  logic [8:0] io_mshrInfo_12_bits_set,
  input  logic [30:0] io_mshrInfo_12_bits_reqTag,
  input  logic io_mshrInfo_12_bits_willFree,
  input  logic io_mshrInfo_12_bits_needRelease,
  input  logic [2:0] io_mshrInfo_12_bits_meta_prefetchSrc,
  input  logic [30:0] io_mshrInfo_12_bits_metaTag,
  input  logic io_mshrInfo_12_bits_dirHit,
  input  logic io_mshrInfo_12_bits_isAcqOrPrefetch,
  input  logic io_mshrInfo_12_bits_isPrefetch,
  input  logic [2:0] io_mshrInfo_12_bits_param,
  input  logic io_mshrInfo_12_bits_mergeA,
  input  logic io_mshrInfo_12_bits_s_refill,
  input  logic io_mshrInfo_13_valid,
  input  logic [2:0] io_mshrInfo_13_bits_channel,
  input  logic [8:0] io_mshrInfo_13_bits_set,
  input  logic [30:0] io_mshrInfo_13_bits_reqTag,
  input  logic io_mshrInfo_13_bits_willFree,
  input  logic io_mshrInfo_13_bits_needRelease,
  input  logic [2:0] io_mshrInfo_13_bits_meta_prefetchSrc,
  input  logic [30:0] io_mshrInfo_13_bits_metaTag,
  input  logic io_mshrInfo_13_bits_dirHit,
  input  logic io_mshrInfo_13_bits_isAcqOrPrefetch,
  input  logic io_mshrInfo_13_bits_isPrefetch,
  input  logic [2:0] io_mshrInfo_13_bits_param,
  input  logic io_mshrInfo_13_bits_mergeA,
  input  logic io_mshrInfo_13_bits_s_refill,
  input  logic io_mshrInfo_14_valid,
  input  logic [2:0] io_mshrInfo_14_bits_channel,
  input  logic [8:0] io_mshrInfo_14_bits_set,
  input  logic [30:0] io_mshrInfo_14_bits_reqTag,
  input  logic io_mshrInfo_14_bits_willFree,
  input  logic io_mshrInfo_14_bits_needRelease,
  input  logic [2:0] io_mshrInfo_14_bits_meta_prefetchSrc,
  input  logic [30:0] io_mshrInfo_14_bits_metaTag,
  input  logic io_mshrInfo_14_bits_dirHit,
  input  logic io_mshrInfo_14_bits_isAcqOrPrefetch,
  input  logic io_mshrInfo_14_bits_isPrefetch,
  input  logic [2:0] io_mshrInfo_14_bits_param,
  input  logic io_mshrInfo_14_bits_mergeA,
  input  logic io_mshrInfo_14_bits_s_refill,
  input  logic io_mshrInfo_15_valid,
  input  logic [2:0] io_mshrInfo_15_bits_channel,
  input  logic [8:0] io_mshrInfo_15_bits_set,
  input  logic [30:0] io_mshrInfo_15_bits_reqTag,
  input  logic io_mshrInfo_15_bits_willFree,
  input  logic io_mshrInfo_15_bits_needRelease,
  input  logic [2:0] io_mshrInfo_15_bits_meta_prefetchSrc,
  input  logic [30:0] io_mshrInfo_15_bits_metaTag,
  input  logic io_mshrInfo_15_bits_dirHit,
  input  logic io_mshrInfo_15_bits_isAcqOrPrefetch,
  input  logic io_mshrInfo_15_bits_isPrefetch,
  input  logic [2:0] io_mshrInfo_15_bits_param,
  input  logic io_mshrInfo_15_bits_mergeA,
  input  logic io_mshrInfo_15_bits_s_refill,
  output logic io_aMergeTask_valid,
  output logic [7:0] io_aMergeTask_bits_id,
  output logic [5:0] io_aMergeTask_bits_task_off,
  output logic [1:0] io_aMergeTask_bits_task_alias,
  output logic [43:0] io_aMergeTask_bits_task_vaddr,
  output logic io_aMergeTask_bits_task_isKeyword,
  output logic [3:0] io_aMergeTask_bits_task_opcode,
  output logic [2:0] io_aMergeTask_bits_task_param,
  output logic [6:0] io_aMergeTask_bits_task_sourceId,
  input  logic io_mainPipeBlock_0,
  input  logic io_mainPipeBlock_1,
  input  logic io_taskFromArb_s2_valid,
  input  logic [2:0] io_taskFromArb_s2_bits_channel,
  input  logic [8:0] io_taskFromArb_s2_bits_set,
  input  logic io_taskFromArb_s2_bits_mshrTask,
  output logic [30:0] io_ATag,
  output logic [8:0] io_ASet,
  input  logic io_s1Entrance_valid,
  input  logic [8:0] io_s1Entrance_bits_set,
  output logic io_hasHitPfInMSHR_valid,
  output logic [2:0] io_hasHitPfInMSHR_bits,
  output logic io_hasPfLateInMSHR_valid,
  output logic [4:0] io_hasPfLateInMSHR_bits,
  output logic io_hasMergeA
);

  a_req_t     inReq;
  task_t      outTask, deqTask;
  logic       arbIn_valid [N_ENTRY];
  entry_t     arbIn_entry [N_ENTRY];
  entry_t     arbOut_entry, enqEntry;
  logic       arbOut_valid, enqValid, enqReady, deqValid, deqReady;
  logic [1:0] arbOut_chosen, enqId, deqId;

  assign inReq = '{
    io_in_bits_set,
    io_in_bits_tag,
    io_in_bits_off,
    io_in_bits_alias,
    io_in_bits_vaddr,
    io_in_bits_isKeyword,
    io_in_bits_opcode,
    io_in_bits_param,
    io_in_bits_size,
    io_in_bits_sourceId,
    io_in_bits_corrupt,
    io_in_bits_fromL2pft,
    io_in_bits_needHint,
    io_in_bits_reqSource
  };

  xs_RequestBuffer_core u_core (
    .clock                  (clock),
    .reset                  (reset),
    .in_valid               (io_in_valid),
    .in_ready               (io_in_ready),
    .in_req                 (inReq),
    .out_ready              (io_out_ready),
    .out_valid              (io_out_valid),
    .out_task               (outTask),
    .ms_valid               ('{io_mshrInfo_0_valid, io_mshrInfo_1_valid, io_mshrInfo_2_valid, io_mshrInfo_3_valid, io_mshrInfo_4_valid, io_mshrInfo_5_valid, io_mshrInfo_6_valid, io_mshrInfo_7_valid, io_mshrInfo_8_valid, io_mshrInfo_9_valid, io_mshrInfo_10_valid, io_mshrInfo_11_valid, io_mshrInfo_12_valid, io_mshrInfo_13_valid, io_mshrInfo_14_valid, io_mshrInfo_15_valid}),
    .ms_channel             ('{io_mshrInfo_0_bits_channel, io_mshrInfo_1_bits_channel, io_mshrInfo_2_bits_channel, io_mshrInfo_3_bits_channel, io_mshrInfo_4_bits_channel, io_mshrInfo_5_bits_channel, io_mshrInfo_6_bits_channel, io_mshrInfo_7_bits_channel, io_mshrInfo_8_bits_channel, io_mshrInfo_9_bits_channel, io_mshrInfo_10_bits_channel, io_mshrInfo_11_bits_channel, io_mshrInfo_12_bits_channel, io_mshrInfo_13_bits_channel, io_mshrInfo_14_bits_channel, io_mshrInfo_15_bits_channel}),
    .ms_set                 ('{io_mshrInfo_0_bits_set, io_mshrInfo_1_bits_set, io_mshrInfo_2_bits_set, io_mshrInfo_3_bits_set, io_mshrInfo_4_bits_set, io_mshrInfo_5_bits_set, io_mshrInfo_6_bits_set, io_mshrInfo_7_bits_set, io_mshrInfo_8_bits_set, io_mshrInfo_9_bits_set, io_mshrInfo_10_bits_set, io_mshrInfo_11_bits_set, io_mshrInfo_12_bits_set, io_mshrInfo_13_bits_set, io_mshrInfo_14_bits_set, io_mshrInfo_15_bits_set}),
    .ms_reqTag              ('{io_mshrInfo_0_bits_reqTag, io_mshrInfo_1_bits_reqTag, io_mshrInfo_2_bits_reqTag, io_mshrInfo_3_bits_reqTag, io_mshrInfo_4_bits_reqTag, io_mshrInfo_5_bits_reqTag, io_mshrInfo_6_bits_reqTag, io_mshrInfo_7_bits_reqTag, io_mshrInfo_8_bits_reqTag, io_mshrInfo_9_bits_reqTag, io_mshrInfo_10_bits_reqTag, io_mshrInfo_11_bits_reqTag, io_mshrInfo_12_bits_reqTag, io_mshrInfo_13_bits_reqTag, io_mshrInfo_14_bits_reqTag, io_mshrInfo_15_bits_reqTag}),
    .ms_metaTag             ('{io_mshrInfo_0_bits_metaTag, io_mshrInfo_1_bits_metaTag, io_mshrInfo_2_bits_metaTag, io_mshrInfo_3_bits_metaTag, io_mshrInfo_4_bits_metaTag, io_mshrInfo_5_bits_metaTag, io_mshrInfo_6_bits_metaTag, io_mshrInfo_7_bits_metaTag, io_mshrInfo_8_bits_metaTag, io_mshrInfo_9_bits_metaTag, io_mshrInfo_10_bits_metaTag, io_mshrInfo_11_bits_metaTag, io_mshrInfo_12_bits_metaTag, io_mshrInfo_13_bits_metaTag, io_mshrInfo_14_bits_metaTag, io_mshrInfo_15_bits_metaTag}),
    .ms_willFree            ('{io_mshrInfo_0_bits_willFree, io_mshrInfo_1_bits_willFree, io_mshrInfo_2_bits_willFree, io_mshrInfo_3_bits_willFree, io_mshrInfo_4_bits_willFree, io_mshrInfo_5_bits_willFree, io_mshrInfo_6_bits_willFree, io_mshrInfo_7_bits_willFree, io_mshrInfo_8_bits_willFree, io_mshrInfo_9_bits_willFree, io_mshrInfo_10_bits_willFree, io_mshrInfo_11_bits_willFree, io_mshrInfo_12_bits_willFree, io_mshrInfo_13_bits_willFree, io_mshrInfo_14_bits_willFree, io_mshrInfo_15_bits_willFree}),
    .ms_needRelease         ('{io_mshrInfo_0_bits_needRelease, io_mshrInfo_1_bits_needRelease, io_mshrInfo_2_bits_needRelease, io_mshrInfo_3_bits_needRelease, io_mshrInfo_4_bits_needRelease, io_mshrInfo_5_bits_needRelease, io_mshrInfo_6_bits_needRelease, io_mshrInfo_7_bits_needRelease, io_mshrInfo_8_bits_needRelease, io_mshrInfo_9_bits_needRelease, io_mshrInfo_10_bits_needRelease, io_mshrInfo_11_bits_needRelease, io_mshrInfo_12_bits_needRelease, io_mshrInfo_13_bits_needRelease, io_mshrInfo_14_bits_needRelease, io_mshrInfo_15_bits_needRelease}),
    .ms_prefetchSrc         ('{io_mshrInfo_0_bits_meta_prefetchSrc, io_mshrInfo_1_bits_meta_prefetchSrc, io_mshrInfo_2_bits_meta_prefetchSrc, io_mshrInfo_3_bits_meta_prefetchSrc, io_mshrInfo_4_bits_meta_prefetchSrc, io_mshrInfo_5_bits_meta_prefetchSrc, io_mshrInfo_6_bits_meta_prefetchSrc, io_mshrInfo_7_bits_meta_prefetchSrc, io_mshrInfo_8_bits_meta_prefetchSrc, io_mshrInfo_9_bits_meta_prefetchSrc, io_mshrInfo_10_bits_meta_prefetchSrc, io_mshrInfo_11_bits_meta_prefetchSrc, io_mshrInfo_12_bits_meta_prefetchSrc, io_mshrInfo_13_bits_meta_prefetchSrc, io_mshrInfo_14_bits_meta_prefetchSrc, io_mshrInfo_15_bits_meta_prefetchSrc}),
    .ms_dirHit              ('{io_mshrInfo_0_bits_dirHit, io_mshrInfo_1_bits_dirHit, io_mshrInfo_2_bits_dirHit, io_mshrInfo_3_bits_dirHit, io_mshrInfo_4_bits_dirHit, io_mshrInfo_5_bits_dirHit, io_mshrInfo_6_bits_dirHit, io_mshrInfo_7_bits_dirHit, io_mshrInfo_8_bits_dirHit, io_mshrInfo_9_bits_dirHit, io_mshrInfo_10_bits_dirHit, io_mshrInfo_11_bits_dirHit, io_mshrInfo_12_bits_dirHit, io_mshrInfo_13_bits_dirHit, io_mshrInfo_14_bits_dirHit, io_mshrInfo_15_bits_dirHit}),
    .ms_isAcqOrPrefetch     ('{io_mshrInfo_0_bits_isAcqOrPrefetch, io_mshrInfo_1_bits_isAcqOrPrefetch, io_mshrInfo_2_bits_isAcqOrPrefetch, io_mshrInfo_3_bits_isAcqOrPrefetch, io_mshrInfo_4_bits_isAcqOrPrefetch, io_mshrInfo_5_bits_isAcqOrPrefetch, io_mshrInfo_6_bits_isAcqOrPrefetch, io_mshrInfo_7_bits_isAcqOrPrefetch, io_mshrInfo_8_bits_isAcqOrPrefetch, io_mshrInfo_9_bits_isAcqOrPrefetch, io_mshrInfo_10_bits_isAcqOrPrefetch, io_mshrInfo_11_bits_isAcqOrPrefetch, io_mshrInfo_12_bits_isAcqOrPrefetch, io_mshrInfo_13_bits_isAcqOrPrefetch, io_mshrInfo_14_bits_isAcqOrPrefetch, io_mshrInfo_15_bits_isAcqOrPrefetch}),
    .ms_isPrefetch          ('{io_mshrInfo_0_bits_isPrefetch, io_mshrInfo_1_bits_isPrefetch, io_mshrInfo_2_bits_isPrefetch, io_mshrInfo_3_bits_isPrefetch, io_mshrInfo_4_bits_isPrefetch, io_mshrInfo_5_bits_isPrefetch, io_mshrInfo_6_bits_isPrefetch, io_mshrInfo_7_bits_isPrefetch, io_mshrInfo_8_bits_isPrefetch, io_mshrInfo_9_bits_isPrefetch, io_mshrInfo_10_bits_isPrefetch, io_mshrInfo_11_bits_isPrefetch, io_mshrInfo_12_bits_isPrefetch, io_mshrInfo_13_bits_isPrefetch, io_mshrInfo_14_bits_isPrefetch, io_mshrInfo_15_bits_isPrefetch}),
    .ms_param               ('{io_mshrInfo_0_bits_param, io_mshrInfo_1_bits_param, io_mshrInfo_2_bits_param, io_mshrInfo_3_bits_param, io_mshrInfo_4_bits_param, io_mshrInfo_5_bits_param, io_mshrInfo_6_bits_param, io_mshrInfo_7_bits_param, io_mshrInfo_8_bits_param, io_mshrInfo_9_bits_param, io_mshrInfo_10_bits_param, io_mshrInfo_11_bits_param, io_mshrInfo_12_bits_param, io_mshrInfo_13_bits_param, io_mshrInfo_14_bits_param, io_mshrInfo_15_bits_param}),
    .ms_mergeA              ('{io_mshrInfo_0_bits_mergeA, io_mshrInfo_1_bits_mergeA, io_mshrInfo_2_bits_mergeA, io_mshrInfo_3_bits_mergeA, io_mshrInfo_4_bits_mergeA, io_mshrInfo_5_bits_mergeA, io_mshrInfo_6_bits_mergeA, io_mshrInfo_7_bits_mergeA, io_mshrInfo_8_bits_mergeA, io_mshrInfo_9_bits_mergeA, io_mshrInfo_10_bits_mergeA, io_mshrInfo_11_bits_mergeA, io_mshrInfo_12_bits_mergeA, io_mshrInfo_13_bits_mergeA, io_mshrInfo_14_bits_mergeA, io_mshrInfo_15_bits_mergeA}),
    .ms_s_refill            ('{io_mshrInfo_0_bits_s_refill, io_mshrInfo_1_bits_s_refill, io_mshrInfo_2_bits_s_refill, io_mshrInfo_3_bits_s_refill, io_mshrInfo_4_bits_s_refill, io_mshrInfo_5_bits_s_refill, io_mshrInfo_6_bits_s_refill, io_mshrInfo_7_bits_s_refill, io_mshrInfo_8_bits_s_refill, io_mshrInfo_9_bits_s_refill, io_mshrInfo_10_bits_s_refill, io_mshrInfo_11_bits_s_refill, io_mshrInfo_12_bits_s_refill, io_mshrInfo_13_bits_s_refill, io_mshrInfo_14_bits_s_refill, io_mshrInfo_15_bits_s_refill}),
    .mainPipeBlock          ('{io_mainPipeBlock_0, io_mainPipeBlock_1}),
    .arbS2_valid            (io_taskFromArb_s2_valid),
    .arbS2_channel          (io_taskFromArb_s2_bits_channel),
    .arbS2_set              (io_taskFromArb_s2_bits_set),
    .arbS2_mshrTask         (io_taskFromArb_s2_bits_mshrTask),
    .s1Entrance_valid       (io_s1Entrance_valid),
    .s1Entrance_set         (io_s1Entrance_bits_set),
    .arbIn_valid            (arbIn_valid),
    .arbIn_entry            (arbIn_entry),
    .arbOut_valid           (arbOut_valid),
    .arbOut_entry           (arbOut_entry),
    .arbOut_chosen          (arbOut_chosen),
    .chosenQ_enqValid       (enqValid),
    .chosenQ_enqEntry       (enqEntry),
    .chosenQ_enqId          (enqId),
    .chosenQ_enqReady       (enqReady),
    .chosenQ_deqValid       (deqValid),
    .chosenQ_deqTask        (deqTask),
    .chosenQ_deqId          (deqId),
    .chosenQ_deqReady       (deqReady),
    .aMergeTask_valid       (io_aMergeTask_valid),
    .aMergeTask_id          (io_aMergeTask_bits_id),
    .hasHitPfInMSHR_valid   (io_hasHitPfInMSHR_valid),
    .hasHitPfInMSHR_bits    (io_hasHitPfInMSHR_bits),
    .hasPfLateInMSHR_valid  (io_hasPfLateInMSHR_valid),
    .hasMergeA              (io_hasMergeA)
  );

  // 发射仲裁：4 个表项 -> chosenQ（端口不带 ready，赢家下标走 io_chosen）
  FastArbiter_2 issueArb (
    .clock                        (clock),
    .reset                        (reset),
    .io_in_0_valid                (arbIn_valid[0]),
    .io_in_0_bits_valid           (arbIn_entry[0].valid),
    .io_in_0_bits_rdy             (arbIn_entry[0].rdy),
    .io_in_0_bits_task_channel    (arbIn_entry[0].channel),
    .io_in_0_bits_task_set        (arbIn_entry[0].req.set),
    .io_in_0_bits_task_tag        (arbIn_entry[0].req.tag),
    .io_in_0_bits_task_off        (arbIn_entry[0].req.off),
    .io_in_0_bits_task_alias      (arbIn_entry[0].req.alias_),
    .io_in_0_bits_task_vaddr      (arbIn_entry[0].req.vaddr),
    .io_in_0_bits_task_isKeyword  (arbIn_entry[0].req.isKeyword),
    .io_in_0_bits_task_opcode     (arbIn_entry[0].req.opcode),
    .io_in_0_bits_task_param      (arbIn_entry[0].req.param),
    .io_in_0_bits_task_size       (arbIn_entry[0].req.size),
    .io_in_0_bits_task_sourceId   (arbIn_entry[0].req.sourceId),
    .io_in_0_bits_task_corrupt    (arbIn_entry[0].req.corrupt),
    .io_in_0_bits_task_fromL2pft  (arbIn_entry[0].req.fromL2pft),
    .io_in_0_bits_task_needHint   (arbIn_entry[0].req.needHint),
    .io_in_0_bits_task_reqSource  (arbIn_entry[0].req.reqSource),
    .io_in_0_bits_waitMP          (arbIn_entry[0].waitMP),
    .io_in_0_bits_waitMS          (arbIn_entry[0].waitMS),
    .io_in_1_valid                (arbIn_valid[1]),
    .io_in_1_bits_valid           (arbIn_entry[1].valid),
    .io_in_1_bits_rdy             (arbIn_entry[1].rdy),
    .io_in_1_bits_task_channel    (arbIn_entry[1].channel),
    .io_in_1_bits_task_set        (arbIn_entry[1].req.set),
    .io_in_1_bits_task_tag        (arbIn_entry[1].req.tag),
    .io_in_1_bits_task_off        (arbIn_entry[1].req.off),
    .io_in_1_bits_task_alias      (arbIn_entry[1].req.alias_),
    .io_in_1_bits_task_vaddr      (arbIn_entry[1].req.vaddr),
    .io_in_1_bits_task_isKeyword  (arbIn_entry[1].req.isKeyword),
    .io_in_1_bits_task_opcode     (arbIn_entry[1].req.opcode),
    .io_in_1_bits_task_param      (arbIn_entry[1].req.param),
    .io_in_1_bits_task_size       (arbIn_entry[1].req.size),
    .io_in_1_bits_task_sourceId   (arbIn_entry[1].req.sourceId),
    .io_in_1_bits_task_corrupt    (arbIn_entry[1].req.corrupt),
    .io_in_1_bits_task_fromL2pft  (arbIn_entry[1].req.fromL2pft),
    .io_in_1_bits_task_needHint   (arbIn_entry[1].req.needHint),
    .io_in_1_bits_task_reqSource  (arbIn_entry[1].req.reqSource),
    .io_in_1_bits_waitMP          (arbIn_entry[1].waitMP),
    .io_in_1_bits_waitMS          (arbIn_entry[1].waitMS),
    .io_in_2_valid                (arbIn_valid[2]),
    .io_in_2_bits_valid           (arbIn_entry[2].valid),
    .io_in_2_bits_rdy             (arbIn_entry[2].rdy),
    .io_in_2_bits_task_channel    (arbIn_entry[2].channel),
    .io_in_2_bits_task_set        (arbIn_entry[2].req.set),
    .io_in_2_bits_task_tag        (arbIn_entry[2].req.tag),
    .io_in_2_bits_task_off        (arbIn_entry[2].req.off),
    .io_in_2_bits_task_alias      (arbIn_entry[2].req.alias_),
    .io_in_2_bits_task_vaddr      (arbIn_entry[2].req.vaddr),
    .io_in_2_bits_task_isKeyword  (arbIn_entry[2].req.isKeyword),
    .io_in_2_bits_task_opcode     (arbIn_entry[2].req.opcode),
    .io_in_2_bits_task_param      (arbIn_entry[2].req.param),
    .io_in_2_bits_task_size       (arbIn_entry[2].req.size),
    .io_in_2_bits_task_sourceId   (arbIn_entry[2].req.sourceId),
    .io_in_2_bits_task_corrupt    (arbIn_entry[2].req.corrupt),
    .io_in_2_bits_task_fromL2pft  (arbIn_entry[2].req.fromL2pft),
    .io_in_2_bits_task_needHint   (arbIn_entry[2].req.needHint),
    .io_in_2_bits_task_reqSource  (arbIn_entry[2].req.reqSource),
    .io_in_2_bits_waitMP          (arbIn_entry[2].waitMP),
    .io_in_2_bits_waitMS          (arbIn_entry[2].waitMS),
    .io_in_3_valid                (arbIn_valid[3]),
    .io_in_3_bits_valid           (arbIn_entry[3].valid),
    .io_in_3_bits_rdy             (arbIn_entry[3].rdy),
    .io_in_3_bits_task_channel    (arbIn_entry[3].channel),
    .io_in_3_bits_task_set        (arbIn_entry[3].req.set),
    .io_in_3_bits_task_tag        (arbIn_entry[3].req.tag),
    .io_in_3_bits_task_off        (arbIn_entry[3].req.off),
    .io_in_3_bits_task_alias      (arbIn_entry[3].req.alias_),
    .io_in_3_bits_task_vaddr      (arbIn_entry[3].req.vaddr),
    .io_in_3_bits_task_isKeyword  (arbIn_entry[3].req.isKeyword),
    .io_in_3_bits_task_opcode     (arbIn_entry[3].req.opcode),
    .io_in_3_bits_task_param      (arbIn_entry[3].req.param),
    .io_in_3_bits_task_size       (arbIn_entry[3].req.size),
    .io_in_3_bits_task_sourceId   (arbIn_entry[3].req.sourceId),
    .io_in_3_bits_task_corrupt    (arbIn_entry[3].req.corrupt),
    .io_in_3_bits_task_fromL2pft  (arbIn_entry[3].req.fromL2pft),
    .io_in_3_bits_task_needHint   (arbIn_entry[3].req.needHint),
    .io_in_3_bits_task_reqSource  (arbIn_entry[3].req.reqSource),
    .io_in_3_bits_waitMP          (arbIn_entry[3].waitMP),
    .io_in_3_bits_waitMS          (arbIn_entry[3].waitMS),
    .io_out_ready                 (enqReady),
    .io_out_valid                 (arbOut_valid),
    .io_out_bits_valid            (arbOut_entry.valid),
    .io_out_bits_rdy              (arbOut_entry.rdy),
    .io_out_bits_task_channel     (arbOut_entry.channel),
    .io_out_bits_task_set         (arbOut_entry.req.set),
    .io_out_bits_task_tag         (arbOut_entry.req.tag),
    .io_out_bits_task_off         (arbOut_entry.req.off),
    .io_out_bits_task_alias       (arbOut_entry.req.alias_),
    .io_out_bits_task_vaddr       (arbOut_entry.req.vaddr),
    .io_out_bits_task_isKeyword   (arbOut_entry.req.isKeyword),
    .io_out_bits_task_opcode      (arbOut_entry.req.opcode),
    .io_out_bits_task_param       (arbOut_entry.req.param),
    .io_out_bits_task_size        (arbOut_entry.req.size),
    .io_out_bits_task_sourceId    (arbOut_entry.req.sourceId),
    .io_out_bits_task_corrupt     (arbOut_entry.req.corrupt),
    .io_out_bits_task_fromL2pft   (arbOut_entry.req.fromL2pft),
    .io_out_bits_task_needHint    (arbOut_entry.req.needHint),
    .io_out_bits_task_reqSource   (arbOut_entry.req.reqSource),
    .io_out_bits_waitMP           (arbOut_entry.waitMP),
    .io_out_bits_waitMS           (arbOut_entry.waitMS),
    .io_chosen                    (arbOut_chosen)
  );

  // 发射队列（1 项，pipe）：记下赢家与它的表项号
  Queue1_ChosenQBundle chosenQ (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_enq_ready                             (enqReady),
    .io_enq_valid                             (enqValid),
    .io_enq_bits_bits_valid                   (enqEntry.valid),
    .io_enq_bits_bits_rdy                     (enqEntry.rdy),
    .io_enq_bits_bits_task_channel            (enqEntry.channel),
    .io_enq_bits_bits_task_set                (enqEntry.req.set),
    .io_enq_bits_bits_task_tag                (enqEntry.req.tag),
    .io_enq_bits_bits_task_off                (enqEntry.req.off),
    .io_enq_bits_bits_task_alias              (enqEntry.req.alias_),
    .io_enq_bits_bits_task_vaddr              (enqEntry.req.vaddr),
    .io_enq_bits_bits_task_isKeyword          (enqEntry.req.isKeyword),
    .io_enq_bits_bits_task_opcode             (enqEntry.req.opcode),
    .io_enq_bits_bits_task_param              (enqEntry.req.param),
    .io_enq_bits_bits_task_size               (enqEntry.req.size),
    .io_enq_bits_bits_task_sourceId           (enqEntry.req.sourceId),
    .io_enq_bits_bits_task_corrupt            (enqEntry.req.corrupt),
    .io_enq_bits_bits_task_fromL2pft          (enqEntry.req.fromL2pft),
    .io_enq_bits_bits_task_needHint           (enqEntry.req.needHint),
    .io_enq_bits_bits_task_reqSource          (enqEntry.req.reqSource),
    .io_enq_bits_bits_waitMP                  (enqEntry.waitMP),
    .io_enq_bits_bits_waitMS                  (enqEntry.waitMS),
    .io_enq_bits_id                           (enqId),
    .io_deq_ready                             (deqReady),
    .io_deq_valid                             (deqValid),
    .io_deq_bits_bits_task_channel            (deqTask.channel),
    .io_deq_bits_bits_task_txChannel          (deqTask.txChannel),
    .io_deq_bits_bits_task_set                (deqTask.set),
    .io_deq_bits_bits_task_tag                (deqTask.tag),
    .io_deq_bits_bits_task_off                (deqTask.off),
    .io_deq_bits_bits_task_alias              (deqTask.alias_),
    .io_deq_bits_bits_task_vaddr              (deqTask.vaddr),
    .io_deq_bits_bits_task_isKeyword          (deqTask.isKeyword),
    .io_deq_bits_bits_task_opcode             (deqTask.opcode),
    .io_deq_bits_bits_task_param              (deqTask.param),
    .io_deq_bits_bits_task_size               (deqTask.size),
    .io_deq_bits_bits_task_sourceId           (deqTask.sourceId),
    .io_deq_bits_bits_task_bufIdx             (deqTask.bufIdx),
    .io_deq_bits_bits_task_needProbeAckData   (deqTask.needProbeAckData),
    .io_deq_bits_bits_task_denied             (deqTask.denied),
    .io_deq_bits_bits_task_corrupt            (deqTask.corrupt),
    .io_deq_bits_bits_task_mshrTask           (deqTask.mshrTask),
    .io_deq_bits_bits_task_mshrId             (deqTask.mshrId),
    .io_deq_bits_bits_task_aliasTask          (deqTask.aliasTask),
    .io_deq_bits_bits_task_useProbeData       (deqTask.useProbeData),
    .io_deq_bits_bits_task_mshrRetry          (deqTask.mshrRetry),
    .io_deq_bits_bits_task_readProbeDataDown  (deqTask.readProbeDataDown),
    .io_deq_bits_bits_task_fromL2pft          (deqTask.fromL2pft),
    .io_deq_bits_bits_task_needHint           (deqTask.needHint),
    .io_deq_bits_bits_task_dirty              (deqTask.dirty),
    .io_deq_bits_bits_task_way                (deqTask.way),
    .io_deq_bits_bits_task_meta_dirty         (deqTask.meta_dirty),
    .io_deq_bits_bits_task_meta_state         (deqTask.meta_state),
    .io_deq_bits_bits_task_meta_clients       (deqTask.meta_clients),
    .io_deq_bits_bits_task_meta_alias         (deqTask.meta_alias),
    .io_deq_bits_bits_task_meta_prefetch      (deqTask.meta_prefetch),
    .io_deq_bits_bits_task_meta_prefetchSrc   (deqTask.meta_prefetchSrc),
    .io_deq_bits_bits_task_meta_accessed      (deqTask.meta_accessed),
    .io_deq_bits_bits_task_meta_tagErr        (deqTask.meta_tagErr),
    .io_deq_bits_bits_task_meta_dataErr       (deqTask.meta_dataErr),
    .io_deq_bits_bits_task_metaWen            (deqTask.metaWen),
    .io_deq_bits_bits_task_tagWen             (deqTask.tagWen),
    .io_deq_bits_bits_task_dsWen              (deqTask.dsWen),
    .io_deq_bits_bits_task_replTask           (deqTask.replTask),
    .io_deq_bits_bits_task_cmoTask            (deqTask.cmoTask),
    .io_deq_bits_bits_task_cmoAll             (deqTask.cmoAll),
    .io_deq_bits_bits_task_reqSource          (deqTask.reqSource),
    .io_deq_bits_bits_task_mergeA             (deqTask.mergeA),
    .io_deq_bits_bits_task_aMergeTask_off     (deqTask.aMergeTask_off),
    .io_deq_bits_bits_task_aMergeTask_alias   (deqTask.aMergeTask_alias),
    .io_deq_bits_bits_task_aMergeTask_vaddr   (deqTask.aMergeTask_vaddr),
    .io_deq_bits_bits_task_aMergeTask_isKeyword (deqTask.aMergeTask_isKeyword),
    .io_deq_bits_bits_task_aMergeTask_opcode  (deqTask.aMergeTask_opcode),
    .io_deq_bits_bits_task_aMergeTask_param   (deqTask.aMergeTask_param),
    .io_deq_bits_bits_task_aMergeTask_sourceId (deqTask.aMergeTask_sourceId),
    .io_deq_bits_bits_task_aMergeTask_meta_dirty (deqTask.aMergeTask_meta_dirty),
    .io_deq_bits_bits_task_aMergeTask_meta_state (deqTask.aMergeTask_meta_state),
    .io_deq_bits_bits_task_aMergeTask_meta_clients (deqTask.aMergeTask_meta_clients),
    .io_deq_bits_bits_task_aMergeTask_meta_alias (deqTask.aMergeTask_meta_alias),
    .io_deq_bits_bits_task_aMergeTask_meta_prefetch (deqTask.aMergeTask_meta_prefetch),
    .io_deq_bits_bits_task_aMergeTask_meta_prefetchSrc (deqTask.aMergeTask_meta_prefetchSrc),
    .io_deq_bits_bits_task_aMergeTask_meta_accessed (deqTask.aMergeTask_meta_accessed),
    .io_deq_bits_bits_task_aMergeTask_meta_tagErr (deqTask.aMergeTask_meta_tagErr),
    .io_deq_bits_bits_task_aMergeTask_meta_dataErr (deqTask.aMergeTask_meta_dataErr),
    .io_deq_bits_bits_task_snpHitRelease      (deqTask.snpHitRelease),
    .io_deq_bits_bits_task_snpHitReleaseToInval (deqTask.snpHitReleaseToInval),
    .io_deq_bits_bits_task_snpHitReleaseToClean (deqTask.snpHitReleaseToClean),
    .io_deq_bits_bits_task_snpHitReleaseWithData (deqTask.snpHitReleaseWithData),
    .io_deq_bits_bits_task_snpHitReleaseIdx   (deqTask.snpHitReleaseIdx),
    .io_deq_bits_bits_task_snpHitReleaseMeta_dirty (deqTask.snpHitReleaseMeta_dirty),
    .io_deq_bits_bits_task_snpHitReleaseMeta_state (deqTask.snpHitReleaseMeta_state),
    .io_deq_bits_bits_task_snpHitReleaseMeta_clients (deqTask.snpHitReleaseMeta_clients),
    .io_deq_bits_bits_task_snpHitReleaseMeta_alias (deqTask.snpHitReleaseMeta_alias),
    .io_deq_bits_bits_task_snpHitReleaseMeta_prefetch (deqTask.snpHitReleaseMeta_prefetch),
    .io_deq_bits_bits_task_snpHitReleaseMeta_prefetchSrc (deqTask.snpHitReleaseMeta_prefetchSrc),
    .io_deq_bits_bits_task_snpHitReleaseMeta_accessed (deqTask.snpHitReleaseMeta_accessed),
    .io_deq_bits_bits_task_snpHitReleaseMeta_tagErr (deqTask.snpHitReleaseMeta_tagErr),
    .io_deq_bits_bits_task_snpHitReleaseMeta_dataErr (deqTask.snpHitReleaseMeta_dataErr),
    .io_deq_bits_bits_task_tgtID              (deqTask.tgtID),
    .io_deq_bits_bits_task_srcID              (deqTask.srcID),
    .io_deq_bits_bits_task_txnID              (deqTask.txnID),
    .io_deq_bits_bits_task_homeNID            (deqTask.homeNID),
    .io_deq_bits_bits_task_dbID               (deqTask.dbID),
    .io_deq_bits_bits_task_fwdNID             (deqTask.fwdNID),
    .io_deq_bits_bits_task_fwdTxnID           (deqTask.fwdTxnID),
    .io_deq_bits_bits_task_chiOpcode          (deqTask.chiOpcode),
    .io_deq_bits_bits_task_resp               (deqTask.resp),
    .io_deq_bits_bits_task_fwdState           (deqTask.fwdState),
    .io_deq_bits_bits_task_pCrdType           (deqTask.pCrdType),
    .io_deq_bits_bits_task_retToSrc           (deqTask.retToSrc),
    .io_deq_bits_bits_task_likelyshared       (deqTask.likelyshared),
    .io_deq_bits_bits_task_expCompAck         (deqTask.expCompAck),
    .io_deq_bits_bits_task_allowRetry         (deqTask.allowRetry),
    .io_deq_bits_bits_task_memAttr_allocate   (deqTask.memAttr_allocate),
    .io_deq_bits_bits_task_memAttr_cacheable  (deqTask.memAttr_cacheable),
    .io_deq_bits_bits_task_memAttr_device     (deqTask.memAttr_device),
    .io_deq_bits_bits_task_memAttr_ewa        (deqTask.memAttr_ewa),
    .io_deq_bits_bits_task_traceTag           (deqTask.traceTag),
    .io_deq_bits_id                           (deqId)
  );

  // 出口任务拆回端口；合并任务与统计里直接透传入口字段的部分
  assign io_out_bits_channel = outTask.channel;
  assign io_out_bits_txChannel = outTask.txChannel;
  assign io_out_bits_set = outTask.set;
  assign io_out_bits_tag = outTask.tag;
  assign io_out_bits_off = outTask.off;
  assign io_out_bits_alias = outTask.alias_;
  assign io_out_bits_vaddr = outTask.vaddr;
  assign io_out_bits_isKeyword = outTask.isKeyword;
  assign io_out_bits_opcode = outTask.opcode;
  assign io_out_bits_param = outTask.param;
  assign io_out_bits_size = outTask.size;
  assign io_out_bits_sourceId = outTask.sourceId;
  assign io_out_bits_bufIdx = outTask.bufIdx;
  assign io_out_bits_needProbeAckData = outTask.needProbeAckData;
  assign io_out_bits_denied = outTask.denied;
  assign io_out_bits_corrupt = outTask.corrupt;
  assign io_out_bits_mshrTask = outTask.mshrTask;
  assign io_out_bits_mshrId = outTask.mshrId;
  assign io_out_bits_aliasTask = outTask.aliasTask;
  assign io_out_bits_useProbeData = outTask.useProbeData;
  assign io_out_bits_mshrRetry = outTask.mshrRetry;
  assign io_out_bits_readProbeDataDown = outTask.readProbeDataDown;
  assign io_out_bits_fromL2pft = outTask.fromL2pft;
  assign io_out_bits_needHint = outTask.needHint;
  assign io_out_bits_dirty = outTask.dirty;
  assign io_out_bits_way = outTask.way;
  assign io_out_bits_meta_dirty = outTask.meta_dirty;
  assign io_out_bits_meta_state = outTask.meta_state;
  assign io_out_bits_meta_clients = outTask.meta_clients;
  assign io_out_bits_meta_alias = outTask.meta_alias;
  assign io_out_bits_meta_prefetch = outTask.meta_prefetch;
  assign io_out_bits_meta_prefetchSrc = outTask.meta_prefetchSrc;
  assign io_out_bits_meta_accessed = outTask.meta_accessed;
  assign io_out_bits_meta_tagErr = outTask.meta_tagErr;
  assign io_out_bits_meta_dataErr = outTask.meta_dataErr;
  assign io_out_bits_metaWen = outTask.metaWen;
  assign io_out_bits_tagWen = outTask.tagWen;
  assign io_out_bits_dsWen = outTask.dsWen;
  assign io_out_bits_replTask = outTask.replTask;
  assign io_out_bits_cmoTask = outTask.cmoTask;
  assign io_out_bits_cmoAll = outTask.cmoAll;
  assign io_out_bits_reqSource = outTask.reqSource;
  assign io_out_bits_mergeA = outTask.mergeA;
  assign io_out_bits_aMergeTask_off = outTask.aMergeTask_off;
  assign io_out_bits_aMergeTask_alias = outTask.aMergeTask_alias;
  assign io_out_bits_aMergeTask_vaddr = outTask.aMergeTask_vaddr;
  assign io_out_bits_aMergeTask_isKeyword = outTask.aMergeTask_isKeyword;
  assign io_out_bits_aMergeTask_opcode = outTask.aMergeTask_opcode;
  assign io_out_bits_aMergeTask_param = outTask.aMergeTask_param;
  assign io_out_bits_aMergeTask_sourceId = outTask.aMergeTask_sourceId;
  assign io_out_bits_aMergeTask_meta_dirty = outTask.aMergeTask_meta_dirty;
  assign io_out_bits_aMergeTask_meta_state = outTask.aMergeTask_meta_state;
  assign io_out_bits_aMergeTask_meta_clients = outTask.aMergeTask_meta_clients;
  assign io_out_bits_aMergeTask_meta_alias = outTask.aMergeTask_meta_alias;
  assign io_out_bits_aMergeTask_meta_prefetch = outTask.aMergeTask_meta_prefetch;
  assign io_out_bits_aMergeTask_meta_prefetchSrc = outTask.aMergeTask_meta_prefetchSrc;
  assign io_out_bits_aMergeTask_meta_accessed = outTask.aMergeTask_meta_accessed;
  assign io_out_bits_aMergeTask_meta_tagErr = outTask.aMergeTask_meta_tagErr;
  assign io_out_bits_aMergeTask_meta_dataErr = outTask.aMergeTask_meta_dataErr;
  assign io_out_bits_snpHitRelease = outTask.snpHitRelease;
  assign io_out_bits_snpHitReleaseToInval = outTask.snpHitReleaseToInval;
  assign io_out_bits_snpHitReleaseToClean = outTask.snpHitReleaseToClean;
  assign io_out_bits_snpHitReleaseWithData = outTask.snpHitReleaseWithData;
  assign io_out_bits_snpHitReleaseIdx = outTask.snpHitReleaseIdx;
  assign io_out_bits_snpHitReleaseMeta_dirty = outTask.snpHitReleaseMeta_dirty;
  assign io_out_bits_snpHitReleaseMeta_state = outTask.snpHitReleaseMeta_state;
  assign io_out_bits_snpHitReleaseMeta_clients = outTask.snpHitReleaseMeta_clients;
  assign io_out_bits_snpHitReleaseMeta_alias = outTask.snpHitReleaseMeta_alias;
  assign io_out_bits_snpHitReleaseMeta_prefetch = outTask.snpHitReleaseMeta_prefetch;
  assign io_out_bits_snpHitReleaseMeta_prefetchSrc = outTask.snpHitReleaseMeta_prefetchSrc;
  assign io_out_bits_snpHitReleaseMeta_accessed = outTask.snpHitReleaseMeta_accessed;
  assign io_out_bits_snpHitReleaseMeta_tagErr = outTask.snpHitReleaseMeta_tagErr;
  assign io_out_bits_snpHitReleaseMeta_dataErr = outTask.snpHitReleaseMeta_dataErr;
  assign io_out_bits_tgtID = outTask.tgtID;
  assign io_out_bits_srcID = outTask.srcID;
  assign io_out_bits_txnID = outTask.txnID;
  assign io_out_bits_homeNID = outTask.homeNID;
  assign io_out_bits_dbID = outTask.dbID;
  assign io_out_bits_fwdNID = outTask.fwdNID;
  assign io_out_bits_fwdTxnID = outTask.fwdTxnID;
  assign io_out_bits_chiOpcode = outTask.chiOpcode;
  assign io_out_bits_resp = outTask.resp;
  assign io_out_bits_fwdState = outTask.fwdState;
  assign io_out_bits_pCrdType = outTask.pCrdType;
  assign io_out_bits_retToSrc = outTask.retToSrc;
  assign io_out_bits_likelyshared = outTask.likelyshared;
  assign io_out_bits_expCompAck = outTask.expCompAck;
  assign io_out_bits_allowRetry = outTask.allowRetry;
  assign io_out_bits_memAttr_allocate = outTask.memAttr_allocate;
  assign io_out_bits_memAttr_cacheable = outTask.memAttr_cacheable;
  assign io_out_bits_memAttr_device = outTask.memAttr_device;
  assign io_out_bits_memAttr_ewa = outTask.memAttr_ewa;
  assign io_out_bits_traceTag = outTask.traceTag;
  assign io_aMergeTask_bits_task_off = io_in_bits_off;
  assign io_aMergeTask_bits_task_alias = io_in_bits_alias;
  assign io_aMergeTask_bits_task_vaddr = io_in_bits_vaddr;
  assign io_aMergeTask_bits_task_isKeyword = io_in_bits_isKeyword;
  assign io_aMergeTask_bits_task_opcode = io_in_bits_opcode;
  assign io_aMergeTask_bits_task_param = io_in_bits_param;
  assign io_aMergeTask_bits_task_sourceId = io_in_bits_sourceId;
  assign io_ATag = io_in_bits_tag;
  assign io_ASet = io_in_bits_set;
  assign io_hasPfLateInMSHR_bits = io_in_bits_reqSource;

endmodule
// END GENERATED(wrapper)
