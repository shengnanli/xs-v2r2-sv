// GrantBuffer.sv —— L2 slice 的 TileLink D 通道出口：把 MainPipe 送来的应答（Grant / GrantData / ReleaseAck /
// AccessAck[Data] / HintAck）按 FIFO 顺序发给 L1，并记账"已发 Grant、尚未收到 GrantAck"的地址
//
// 对照 coupledL2/src/main/scala/coupledL2/GrantBuffer.scala（mshrsAll = 16，grantBufInflightSize = 16，beatSize = 2，
// beat 256 位；prefetch 打开，pftQueueLen = 10）。数据流：
//   1. 入队：io_d_task 永远 ready（容量靠下面的"入口阻塞"反压保证）。除 HintAck 以外的任务（mergeA 的 HintAck 也算）
//      进 grantQueue（任务头 + grantid）与 grantQueueData0/1（两拍数据各一份）。mergeA 任务要把 aMergeTask 里那个
//      被合并进来的 A 请求"还原"成一个普通任务（mergeATask，见核里的函数）。
//   2. 出队：grantQueue 出队头直接驱动 D 通道；带数据（opcode[0]=1）的任务第一拍发一拍、第二拍从 grantBuf 发另一拍，
//      grantBuf 占用期间队列不出队。isKeyword 任务先发高半块（beat1），再发低半块。
//   3. 预取响应：fromL2pft 的 HintAck 进 10 项 pftRespQueue（flow），出口就是 io_prefetchResp。
//   4. GrantAck 记账：Grant / GrantData / mergeA 入队时占 inflightGrant 第一个空项（项号即 D 通道的 sink），
//      E 通道 GrantAck 按 sink 低 4 位清项；io_grantStatus 把它们报给 SourceB 挡同地址 Probe。
//   5. 入口阻塞（给 RequestArb）：流水线 s2..s5 里可能用到本模块容量的任务数 + 已占用数 超过门槛就挡；
//      给 MSHR 任务的门槛少 1（s1 的信息为时序丢掉了，永远给它留一项）。
//   6. perf：每个 inflight 项一个 64 位计时器（有效时 +1、有效下降沿清 0），只被 ifndef SYNTHESIS 的断言读。
// 端口 wrapper 与 TaskBundle 结构体由 scripts/gen_l2_grantbuf.py 从 golden 端口表生成；本核手写。

package grantbuf_pkg;
  // BEGIN GENERATED(task_t) —— scripts/gen_l2_grantbuf.py 从 golden 端口表生成
  // TaskBundle（94 个字段，383 位）：字段顺序与位宽逐字取自 golden 端口 io_d_task_bits_task_*
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
    logic [7:0] wayMask;
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
  // END GENERATED(task_t)

  localparam int unsigned N_INFLIGHT = 16;  // grantBufInflightSize
  localparam int unsigned N_MSHR     = 16;  // mshrsAll（= grantQueue 深度）
  localparam int unsigned PFT_LEN    = 10;  // pftRespQueue 深度
  // TileLink D opcode
  localparam logic [3:0] Grant     = 4'd4;
  localparam logic [3:0] GrantData = 4'd5;
  localparam logic [3:0] HintAck   = 4'd2;
endpackage

module xs_GrantBuffer_core
  import grantbuf_pkg::*;
(
  input  logic         clock,
  input  logic         reset,
  // MainPipe 送来的任务（数据两拍在 wrapper 里直接接进两个数据队列）
  input  logic         dTask_valid,
  input  task_t        dTask,
  // grantQueue / grantQueueData0/1 的入队（三者同一个 valid）
  output logic         q_enq_valid,
  output task_t        q_enq_task,
  output logic [7:0]   q_enq_grantid,
  input  logic         q_enq_ready,       // 只给断言用
  // grantQueue 出队头（firtool 只留了出队用得到的字段）
  output logic         q_deq_ready,
  input  logic         q_deq_valid,
  input  logic         q_deq_isKeyword,
  input  logic [3:0]   q_deq_opcode,
  input  logic [2:0]   q_deq_param,
  input  logic [6:0]   q_deq_sourceId,
  input  logic         q_deq_denied,
  input  logic         q_deq_corrupt,
  input  logic [7:0]   q_deq_grantid,
  input  logic [255:0] q_deq_data0,
  input  logic [255:0] q_deq_data1,
  input  logic [4:0]   q_count,
  // D 通道
  input  logic         d_ready,
  output logic         d_valid,
  output logic [3:0]   d_opcode,
  output logic [1:0]   d_param,
  output logic [6:0]   d_source,
  output logic [7:0]   d_sink,
  output logic         d_denied,
  output logic         d_isKeyword,
  output logic [255:0] d_data,
  output logic         d_corrupt,
  // E 通道（GrantAck，永远 ready）
  input  logic         e_valid,
  input  logic [7:0]   e_sink,
  // 入口阻塞
  input  logic [30:0]  s1_b_tag,
  input  logic [8:0]   s1_b_set,
  input  logic         pipe_valid   [4],   // pipeStatusVec(1..4)，即 s2..s5
  input  logic [2:0]   pipe_channel [4],
  output logic         blockA_s1,
  output logic         blockB_s1,
  output logic         blockC_s1,
  output logic         blockMSHR,
  // 预取响应队列：入队 valid 与占用数
  output logic         pft_enq_valid,
  input  logic         pft_enq_ready,     // 只给断言用
  input  logic [3:0]   pft_count,
  // 给 SourceB 的 inflight Grant 状态
  output logic         gs_valid [N_INFLIGHT],
  output logic [8:0]   gs_set   [N_INFLIGHT],
  output logic [30:0]  gs_tag   [N_INFLIGHT]
);

  // ------------------------------------------------------------------------------------------------
  // mergeA：MainPipe 把一个 A 请求合并进了这条任务（aMergeTask），D 通道要回的是那个 A 请求。
  // 照 Scala 的 mergeAtask：WireInit(0) 再逐字段赋值 —— 下面没写到的字段都是 0。
  // corrupt 在这里就并上了 denied（与 toTLBundleD 的 corrupt||denied 重复，无害）。
  // ------------------------------------------------------------------------------------------------
  function automatic task_t mergeATask(input task_t t);
    task_t m;
    m = '0;
    m.channel          = t.channel;
    m.txChannel        = t.txChannel;
    m.set              = t.set;
    m.tag              = t.tag;
    m.off              = t.aMergeTask_off;
    m.alias_           = t.aMergeTask_alias;
    m.vaddr            = t.vaddr;
    m.isKeyword        = t.aMergeTask_isKeyword;
    m.opcode           = {1'b0, t.aMergeTask_opcode};
    m.param            = t.aMergeTask_param;
    m.size             = t.size;
    m.sourceId         = t.aMergeTask_sourceId;
    m.bufIdx           = t.bufIdx;
    m.needProbeAckData = t.needProbeAckData;
    m.denied           = t.denied;
    m.corrupt          = t.corrupt | t.denied;
    m.mshrTask         = t.mshrTask;
    m.mshrId           = t.mshrId;
    m.aliasTask        = t.aliasTask;
    m.dirty            = t.dirty;
    m.way              = t.way;
    m.meta_dirty       = t.aMergeTask_meta_dirty;
    m.meta_state       = t.aMergeTask_meta_state;
    m.meta_clients     = t.aMergeTask_meta_clients;
    m.meta_alias       = t.aMergeTask_meta_alias;
    m.meta_prefetch    = t.aMergeTask_meta_prefetch;
    m.meta_prefetchSrc = t.aMergeTask_meta_prefetchSrc;
    m.meta_accessed    = t.aMergeTask_meta_accessed;
    m.meta_tagErr      = t.aMergeTask_meta_tagErr;
    m.meta_dataErr     = t.aMergeTask_meta_dataErr;
    m.metaWen          = t.metaWen;
    m.tagWen           = t.tagWen;
    m.dsWen            = t.dsWen;
    m.wayMask          = t.wayMask;
    m.replTask         = t.replTask;
    m.reqSource        = t.reqSource;
    return m;
  endfunction

  // ------------------------------------------------------------------------------------------------
  // inflightGrant：已发 Grant、未收 GrantAck 的地址表
  // ------------------------------------------------------------------------------------------------
  logic        ig_valid [N_INFLIGHT];
  logic [8:0]  ig_set   [N_INFLIGHT];
  logic [30:0] ig_tag   [N_INFLIGHT];

  // 第一个空项（全满时 PriorityEncoder 给 15）
  logic [3:0] insertIdx;
  always_comb begin
    insertIdx = 4'd15;
    for (int i = N_INFLIGHT - 1; i >= 0; i--)
      if (!ig_valid[i]) insertIdx = 4'(i);
  end

  logic needInflight;   // 这条任务要等 GrantAck
  assign needInflight = dTask_valid && (dTask.opcode == Grant || dTask.opcode == GrantData || dTask.mergeA);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < N_INFLIGHT; i++) begin
        ig_valid[i] <= 1'b0;
        ig_set[i]   <= '0;
        ig_tag[i]   <= '0;
      end
    end else begin
      for (int i = 0; i < N_INFLIGHT; i++) begin
        // 同拍"占项"与"GrantAck 清项"撞同一项时清项赢（Scala 里 e.fire 的 when 在后）
        if (needInflight && insertIdx == 4'(i)) begin
          ig_valid[i] <= 1'b1;
          ig_set[i]   <= dTask.set;
          ig_tag[i]   <= dTask.tag;
        end
        if (e_valid && e_sink[3:0] == 4'(i))
          ig_valid[i] <= 1'b0;
      end
    end
  end

  for (genvar i = 0; i < N_INFLIGHT; i++) begin : g_status
    assign gs_valid[i] = ig_valid[i];
    assign gs_set[i]   = ig_set[i];
    assign gs_tag[i]   = ig_tag[i];
  end

  // ------------------------------------------------------------------------------------------------
  // 入队
  // ------------------------------------------------------------------------------------------------
  assign q_enq_valid   = dTask_valid && (dTask.opcode != HintAck || dTask.mergeA);
  assign q_enq_task    = dTask.mergeA ? mergeATask(dTask) : dTask;
  assign q_enq_grantid = {4'd0, insertIdx};
  assign pft_enq_valid = dTask_valid && dTask.opcode == HintAck && dTask.fromL2pft;

  // ------------------------------------------------------------------------------------------------
  // 出队与 D 通道：带数据的任务第一拍直发，另一拍存 grantBuf 下一拍发
  // ------------------------------------------------------------------------------------------------
  logic         gb_valid;
  logic         gb_isKeyword;
  logic [3:0]   gb_opcode;
  logic [2:0]   gb_param;
  logic [6:0]   gb_sourceId;
  logic         gb_denied;
  logic         gb_corrupt;
  logic [255:0] gb_data;
  logic [7:0]   gb_grantid;

  logic takeSecondBeat;   // 出队的是带数据任务：把第二拍存进 grantBuf
  assign q_deq_ready    = d_ready && !gb_valid;
  assign takeSecondBeat = q_deq_valid && d_ready && !gb_valid && q_deq_opcode[0];

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      gb_valid     <= 1'b0;
      gb_isKeyword <= 1'b0;
      gb_opcode    <= '0;
      gb_param     <= '0;
      gb_sourceId  <= '0;
      gb_denied    <= 1'b0;
      gb_corrupt   <= 1'b0;
      gb_data      <= '0;
      gb_grantid   <= '0;
    end else begin
      if (takeSecondBeat) begin
        gb_valid     <= 1'b1;
        gb_isKeyword <= q_deq_isKeyword;
        gb_opcode    <= q_deq_opcode;
        gb_param     <= q_deq_param;
        gb_sourceId  <= q_deq_sourceId;
        gb_denied    <= q_deq_denied;
        gb_corrupt   <= q_deq_corrupt;
        gb_data      <= q_deq_isKeyword ? q_deq_data0 : q_deq_data1;
        gb_grantid   <= q_deq_grantid;
      end
      if (gb_valid && d_ready)
        gb_valid <= 1'b0;
    end
  end

  assign d_valid     = gb_valid || q_deq_valid;
  assign d_opcode    = gb_valid ? gb_opcode         : q_deq_opcode;
  assign d_param     = gb_valid ? gb_param[1:0]     : q_deq_param[1:0];
  assign d_source    = gb_valid ? gb_sourceId       : q_deq_sourceId;
  assign d_sink      = gb_valid ? gb_grantid        : q_deq_grantid;
  assign d_denied    = gb_valid ? gb_denied         : q_deq_denied;
  assign d_isKeyword = gb_valid ? gb_isKeyword      : q_deq_isKeyword;
  assign d_corrupt   = gb_valid ? (gb_corrupt | gb_denied) : (q_deq_corrupt | q_deq_denied);
  assign d_data      = gb_valid ? gb_data : (q_deq_isKeyword ? q_deq_data1 : q_deq_data0);

  // ------------------------------------------------------------------------------------------------
  // 入口阻塞（容量反压）。grantQueue / inflight 两组加法用 6 位，不会溢出：4 + 16 = 20 < 32。
  // ★pftRespQueue 两条照 golden 用 4 位截断加法★：golden 写的是 4'(pipeA + io_count) > 9 / > 8。
  // 可达状态下 io_count ≤ 10、pipeA ≤ 4，和 ≤ 14 不回绕，与宽加法等价；但 io_count 来自 4 位
  // 指针，FM 不知道指针只取 [0,9]（ram_10x89 审定入表时人工复核的归纳不变量，FM 自己不证），
  // 在指针 10..15 的不可达状态下 io_count 可到 15，4 位和会回绕 —— 宽加法在那里与 golden 不同，
  // FM 报 blockA_s1 / blockMSHRReqEntrance 两个输出 failing。bug-for-bug 照抄截断。
  // ------------------------------------------------------------------------------------------------
  logic [2:0] pipeAorC, pipeA;  // s2..s5 里来自 A|C / 只来自 A 的有效任务数
  logic [4:0] inflightCnt;
  always_comb begin
    pipeAorC = '0;
    pipeA    = '0;
    for (int i = 0; i < 4; i++) begin
      pipeAorC += 3'(pipe_valid[i] && (pipe_channel[i][0] || pipe_channel[i][2]));  // fromA | fromC
      pipeA    += 3'(pipe_valid[i] && pipe_channel[i][0]);
    end
    inflightCnt = '0;
    for (int i = 0; i < N_INFLIGHT; i++)
      inflightCnt += 5'(ig_valid[i]);
  end

  logic noSpaceForSinkReq, noSpaceWaitSinkEForSinkReq, noSpaceForSinkPft;
  logic noSpaceForMSHRReq, noSpaceWaitSinkEForMSHRReq, noSpaceForMSHRPft;
  assign noSpaceForSinkReq          = 6'(pipeAorC) + 6'(q_count)     >= 6'(N_MSHR);
  assign noSpaceWaitSinkEForSinkReq = 6'(pipeA)    + 6'(inflightCnt) >= 6'(N_MSHR);
  assign noSpaceForSinkPft          = 4'(4'(pipeA) + pft_count)     >  4'(PFT_LEN - 1);
  assign noSpaceForMSHRReq          = 6'(pipeAorC) + 6'(q_count)     >= 6'(N_MSHR - 1);
  assign noSpaceWaitSinkEForMSHRReq = 6'(pipeA)    + 6'(inflightCnt) >= 6'(N_MSHR - 1);
  assign noSpaceForMSHRPft          = 4'(4'(pipeA) + pft_count)     >  4'(PFT_LEN - 2);

  assign blockA_s1 = noSpaceForSinkReq || noSpaceWaitSinkEForSinkReq || noSpaceForSinkPft;
  assign blockC_s1 = noSpaceForSinkReq;
  assign blockMSHR = noSpaceForMSHRReq || noSpaceWaitSinkEForMSHRReq || noSpaceForMSHRPft;
  always_comb begin
    blockB_s1 = 1'b0;   // s1 的 B 请求撞上还没收到 GrantAck 的同地址
    for (int i = 0; i < N_INFLIGHT; i++)
      blockB_s1 |= ig_valid[i] && ig_set[i] == s1_b_set && ig_tag[i] == s1_b_tag;
  end

  // ------------------------------------------------------------------------------------------------
  // perf：GrantAck 等待计时器（只被断言读）。validPrev = RegNext(valid) 用于"有效下降沿清 0"；
  // histValidPrev 是 golden 里同样的 RegNext（给已删掉的直方图采样用），照样保留一份。
  // ------------------------------------------------------------------------------------------------
  logic [63:0] timers        [N_INFLIGHT];
  logic        validPrev     [N_INFLIGHT];
  logic        histValidPrev [N_INFLIGHT];

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < N_INFLIGHT; i++)
        timers[i] <= '0;
    end else begin
      for (int i = 0; i < N_INFLIGHT; i++) begin
        if (validPrev[i] && !ig_valid[i])
          timers[i] <= '0;
        else if (ig_valid[i])
          timers[i] <= timers[i] + 64'd1;
      end
    end
  end

  always_ff @(posedge clock) begin
    for (int i = 0; i < N_INFLIGHT; i++) begin
      validPrev[i]     <= ig_valid[i];
      histValidPrev[i] <= ig_valid[i];
    end
  end

`ifndef SYNTHESIS
  always_ff @(posedge clock) begin
    if (!reset) begin
      assert (!(!q_enq_ready && dTask_valid)) else $error("GrantBuf full and RECEIVE new task, back pressure failed");
      assert (pft_enq_ready) else $error("pftRespQueue should never be full, no back pressure logic");
      assert (!(inflightCnt == 5'd16 && needInflight)) else $error("inflightGrant entries overflow");
      assert (!(e_valid && e_sink[7:4] != 4'd0)) else $error("GrantBuf: e.sink overflow inflightGrant size");
      for (int i = 0; i < N_INFLIGHT; i++)
        assert (timers[i] <= 64'd9999) else $error("Inflight Grant Leak");
    end
  end
`endif

endmodule

// BEGIN GENERATED(wrapper) —— scripts/gen_l2_grantbuf.py 从 golden 端口表生成
module GrantBuffer
  import grantbuf_pkg::*;
(
  input  logic clock,
  input  logic reset,
  input  logic io_d_task_valid,
  input  logic [2:0] io_d_task_bits_task_channel,
  input  logic [2:0] io_d_task_bits_task_txChannel,
  input  logic [8:0] io_d_task_bits_task_set,
  input  logic [30:0] io_d_task_bits_task_tag,
  input  logic [5:0] io_d_task_bits_task_off,
  input  logic [1:0] io_d_task_bits_task_alias,
  input  logic [43:0] io_d_task_bits_task_vaddr,
  input  logic io_d_task_bits_task_isKeyword,
  input  logic [3:0] io_d_task_bits_task_opcode,
  input  logic [2:0] io_d_task_bits_task_param,
  input  logic [2:0] io_d_task_bits_task_size,
  input  logic [6:0] io_d_task_bits_task_sourceId,
  input  logic [1:0] io_d_task_bits_task_bufIdx,
  input  logic io_d_task_bits_task_needProbeAckData,
  input  logic io_d_task_bits_task_denied,
  input  logic io_d_task_bits_task_corrupt,
  input  logic io_d_task_bits_task_mshrTask,
  input  logic [7:0] io_d_task_bits_task_mshrId,
  input  logic io_d_task_bits_task_aliasTask,
  input  logic io_d_task_bits_task_useProbeData,
  input  logic io_d_task_bits_task_mshrRetry,
  input  logic io_d_task_bits_task_readProbeDataDown,
  input  logic io_d_task_bits_task_fromL2pft,
  input  logic io_d_task_bits_task_needHint,
  input  logic io_d_task_bits_task_dirty,
  input  logic [2:0] io_d_task_bits_task_way,
  input  logic io_d_task_bits_task_meta_dirty,
  input  logic [1:0] io_d_task_bits_task_meta_state,
  input  logic io_d_task_bits_task_meta_clients,
  input  logic [1:0] io_d_task_bits_task_meta_alias,
  input  logic io_d_task_bits_task_meta_prefetch,
  input  logic [2:0] io_d_task_bits_task_meta_prefetchSrc,
  input  logic io_d_task_bits_task_meta_accessed,
  input  logic io_d_task_bits_task_meta_tagErr,
  input  logic io_d_task_bits_task_meta_dataErr,
  input  logic io_d_task_bits_task_metaWen,
  input  logic io_d_task_bits_task_tagWen,
  input  logic io_d_task_bits_task_dsWen,
  input  logic [7:0] io_d_task_bits_task_wayMask,
  input  logic io_d_task_bits_task_replTask,
  input  logic io_d_task_bits_task_cmoTask,
  input  logic io_d_task_bits_task_cmoAll,
  input  logic [4:0] io_d_task_bits_task_reqSource,
  input  logic io_d_task_bits_task_mergeA,
  input  logic [5:0] io_d_task_bits_task_aMergeTask_off,
  input  logic [1:0] io_d_task_bits_task_aMergeTask_alias,
  input  logic [43:0] io_d_task_bits_task_aMergeTask_vaddr,
  input  logic io_d_task_bits_task_aMergeTask_isKeyword,
  input  logic [2:0] io_d_task_bits_task_aMergeTask_opcode,
  input  logic [2:0] io_d_task_bits_task_aMergeTask_param,
  input  logic [6:0] io_d_task_bits_task_aMergeTask_sourceId,
  input  logic io_d_task_bits_task_aMergeTask_meta_dirty,
  input  logic [1:0] io_d_task_bits_task_aMergeTask_meta_state,
  input  logic io_d_task_bits_task_aMergeTask_meta_clients,
  input  logic [1:0] io_d_task_bits_task_aMergeTask_meta_alias,
  input  logic io_d_task_bits_task_aMergeTask_meta_prefetch,
  input  logic [2:0] io_d_task_bits_task_aMergeTask_meta_prefetchSrc,
  input  logic io_d_task_bits_task_aMergeTask_meta_accessed,
  input  logic io_d_task_bits_task_aMergeTask_meta_tagErr,
  input  logic io_d_task_bits_task_aMergeTask_meta_dataErr,
  input  logic io_d_task_bits_task_snpHitRelease,
  input  logic io_d_task_bits_task_snpHitReleaseToInval,
  input  logic io_d_task_bits_task_snpHitReleaseToClean,
  input  logic io_d_task_bits_task_snpHitReleaseWithData,
  input  logic [7:0] io_d_task_bits_task_snpHitReleaseIdx,
  input  logic io_d_task_bits_task_snpHitReleaseMeta_dirty,
  input  logic [1:0] io_d_task_bits_task_snpHitReleaseMeta_state,
  input  logic io_d_task_bits_task_snpHitReleaseMeta_clients,
  input  logic [1:0] io_d_task_bits_task_snpHitReleaseMeta_alias,
  input  logic io_d_task_bits_task_snpHitReleaseMeta_prefetch,
  input  logic [2:0] io_d_task_bits_task_snpHitReleaseMeta_prefetchSrc,
  input  logic io_d_task_bits_task_snpHitReleaseMeta_accessed,
  input  logic io_d_task_bits_task_snpHitReleaseMeta_tagErr,
  input  logic io_d_task_bits_task_snpHitReleaseMeta_dataErr,
  input  logic [10:0] io_d_task_bits_task_tgtID,
  input  logic [10:0] io_d_task_bits_task_srcID,
  input  logic [11:0] io_d_task_bits_task_txnID,
  input  logic [10:0] io_d_task_bits_task_homeNID,
  input  logic [11:0] io_d_task_bits_task_dbID,
  input  logic [10:0] io_d_task_bits_task_fwdNID,
  input  logic [11:0] io_d_task_bits_task_fwdTxnID,
  input  logic [6:0] io_d_task_bits_task_chiOpcode,
  input  logic [2:0] io_d_task_bits_task_resp,
  input  logic [2:0] io_d_task_bits_task_fwdState,
  input  logic [3:0] io_d_task_bits_task_pCrdType,
  input  logic io_d_task_bits_task_retToSrc,
  input  logic io_d_task_bits_task_likelyshared,
  input  logic io_d_task_bits_task_expCompAck,
  input  logic io_d_task_bits_task_allowRetry,
  input  logic io_d_task_bits_task_memAttr_allocate,
  input  logic io_d_task_bits_task_memAttr_cacheable,
  input  logic io_d_task_bits_task_memAttr_device,
  input  logic io_d_task_bits_task_memAttr_ewa,
  input  logic io_d_task_bits_task_traceTag,
  input  logic [511:0] io_d_task_bits_data_data,
  input  logic io_d_ready,
  output logic io_d_valid,
  output logic [3:0] io_d_bits_opcode,
  output logic [1:0] io_d_bits_param,
  output logic [6:0] io_d_bits_source,
  output logic [7:0] io_d_bits_sink,
  output logic io_d_bits_denied,
  output logic io_d_bits_echo_isKeyword,
  output logic [255:0] io_d_bits_data,
  output logic io_d_bits_corrupt,
  input  logic io_e_valid,
  input  logic [7:0] io_e_bits_sink,
  input  logic [30:0] io_fromReqArb_status_s1_tags_1,
  input  logic [8:0] io_fromReqArb_status_s1_sets_1,
  input  logic io_pipeStatusVec_1_valid,
  input  logic [2:0] io_pipeStatusVec_1_bits_channel,
  input  logic io_pipeStatusVec_2_valid,
  input  logic [2:0] io_pipeStatusVec_2_bits_channel,
  input  logic io_pipeStatusVec_3_valid,
  input  logic [2:0] io_pipeStatusVec_3_bits_channel,
  input  logic io_pipeStatusVec_4_valid,
  input  logic [2:0] io_pipeStatusVec_4_bits_channel,
  output logic io_toReqArb_blockSinkReqEntrance_blockA_s1,
  output logic io_toReqArb_blockSinkReqEntrance_blockB_s1,
  output logic io_toReqArb_blockSinkReqEntrance_blockC_s1,
  output logic io_toReqArb_blockMSHRReqEntrance,
  input  logic io_prefetchResp_ready,
  output logic io_prefetchResp_valid,
  output logic [32:0] io_prefetchResp_bits_tag,
  output logic [8:0] io_prefetchResp_bits_set,
  output logic [43:0] io_prefetchResp_bits_vaddr,
  output logic [4:0] io_prefetchResp_bits_pfSource,
  output logic io_grantStatus_0_valid,
  output logic [8:0] io_grantStatus_0_set,
  output logic [30:0] io_grantStatus_0_tag,
  output logic io_grantStatus_1_valid,
  output logic [8:0] io_grantStatus_1_set,
  output logic [30:0] io_grantStatus_1_tag,
  output logic io_grantStatus_2_valid,
  output logic [8:0] io_grantStatus_2_set,
  output logic [30:0] io_grantStatus_2_tag,
  output logic io_grantStatus_3_valid,
  output logic [8:0] io_grantStatus_3_set,
  output logic [30:0] io_grantStatus_3_tag,
  output logic io_grantStatus_4_valid,
  output logic [8:0] io_grantStatus_4_set,
  output logic [30:0] io_grantStatus_4_tag,
  output logic io_grantStatus_5_valid,
  output logic [8:0] io_grantStatus_5_set,
  output logic [30:0] io_grantStatus_5_tag,
  output logic io_grantStatus_6_valid,
  output logic [8:0] io_grantStatus_6_set,
  output logic [30:0] io_grantStatus_6_tag,
  output logic io_grantStatus_7_valid,
  output logic [8:0] io_grantStatus_7_set,
  output logic [30:0] io_grantStatus_7_tag,
  output logic io_grantStatus_8_valid,
  output logic [8:0] io_grantStatus_8_set,
  output logic [30:0] io_grantStatus_8_tag,
  output logic io_grantStatus_9_valid,
  output logic [8:0] io_grantStatus_9_set,
  output logic [30:0] io_grantStatus_9_tag,
  output logic io_grantStatus_10_valid,
  output logic [8:0] io_grantStatus_10_set,
  output logic [30:0] io_grantStatus_10_tag,
  output logic io_grantStatus_11_valid,
  output logic [8:0] io_grantStatus_11_set,
  output logic [30:0] io_grantStatus_11_tag,
  output logic io_grantStatus_12_valid,
  output logic [8:0] io_grantStatus_12_set,
  output logic [30:0] io_grantStatus_12_tag,
  output logic io_grantStatus_13_valid,
  output logic [8:0] io_grantStatus_13_set,
  output logic [30:0] io_grantStatus_13_tag,
  output logic io_grantStatus_14_valid,
  output logic [8:0] io_grantStatus_14_set,
  output logic [30:0] io_grantStatus_14_tag,
  output logic io_grantStatus_15_valid,
  output logic [8:0] io_grantStatus_15_set,
  output logic [30:0] io_grantStatus_15_tag
);

  task_t        dTask;
  logic         q_enq_valid;
  task_t        q_enq_task;
  logic [7:0]   q_enq_grantid;
  logic         q_enq_ready;
  logic         q_deq_ready;
  logic         q_deq_valid;
  logic         q_deq_isKeyword;
  logic [3:0]   q_deq_opcode;
  logic [2:0]   q_deq_param;
  logic [6:0]   q_deq_sourceId;
  logic         q_deq_denied;
  logic         q_deq_corrupt;
  logic [7:0]   q_deq_grantid;
  logic [255:0] q_deq_data0;
  logic [255:0] q_deq_data1;
  logic [4:0]   q_count;
  logic         pft_enq_valid;
  logic         pft_enq_ready;
  logic [3:0]   pft_count;
  logic [30:0]  pft_deq_tag;
  logic         gs_valid [N_INFLIGHT];
  logic [8:0]   gs_set   [N_INFLIGHT];
  logic [30:0]  gs_tag   [N_INFLIGHT];

  // golden 端口 -> TaskBundle 结构体
  assign dTask.channel = io_d_task_bits_task_channel;
  assign dTask.txChannel = io_d_task_bits_task_txChannel;
  assign dTask.set = io_d_task_bits_task_set;
  assign dTask.tag = io_d_task_bits_task_tag;
  assign dTask.off = io_d_task_bits_task_off;
  assign dTask.alias_ = io_d_task_bits_task_alias;
  assign dTask.vaddr = io_d_task_bits_task_vaddr;
  assign dTask.isKeyword = io_d_task_bits_task_isKeyword;
  assign dTask.opcode = io_d_task_bits_task_opcode;
  assign dTask.param = io_d_task_bits_task_param;
  assign dTask.size = io_d_task_bits_task_size;
  assign dTask.sourceId = io_d_task_bits_task_sourceId;
  assign dTask.bufIdx = io_d_task_bits_task_bufIdx;
  assign dTask.needProbeAckData = io_d_task_bits_task_needProbeAckData;
  assign dTask.denied = io_d_task_bits_task_denied;
  assign dTask.corrupt = io_d_task_bits_task_corrupt;
  assign dTask.mshrTask = io_d_task_bits_task_mshrTask;
  assign dTask.mshrId = io_d_task_bits_task_mshrId;
  assign dTask.aliasTask = io_d_task_bits_task_aliasTask;
  assign dTask.useProbeData = io_d_task_bits_task_useProbeData;
  assign dTask.mshrRetry = io_d_task_bits_task_mshrRetry;
  assign dTask.readProbeDataDown = io_d_task_bits_task_readProbeDataDown;
  assign dTask.fromL2pft = io_d_task_bits_task_fromL2pft;
  assign dTask.needHint = io_d_task_bits_task_needHint;
  assign dTask.dirty = io_d_task_bits_task_dirty;
  assign dTask.way = io_d_task_bits_task_way;
  assign dTask.meta_dirty = io_d_task_bits_task_meta_dirty;
  assign dTask.meta_state = io_d_task_bits_task_meta_state;
  assign dTask.meta_clients = io_d_task_bits_task_meta_clients;
  assign dTask.meta_alias = io_d_task_bits_task_meta_alias;
  assign dTask.meta_prefetch = io_d_task_bits_task_meta_prefetch;
  assign dTask.meta_prefetchSrc = io_d_task_bits_task_meta_prefetchSrc;
  assign dTask.meta_accessed = io_d_task_bits_task_meta_accessed;
  assign dTask.meta_tagErr = io_d_task_bits_task_meta_tagErr;
  assign dTask.meta_dataErr = io_d_task_bits_task_meta_dataErr;
  assign dTask.metaWen = io_d_task_bits_task_metaWen;
  assign dTask.tagWen = io_d_task_bits_task_tagWen;
  assign dTask.dsWen = io_d_task_bits_task_dsWen;
  assign dTask.wayMask = io_d_task_bits_task_wayMask;
  assign dTask.replTask = io_d_task_bits_task_replTask;
  assign dTask.cmoTask = io_d_task_bits_task_cmoTask;
  assign dTask.cmoAll = io_d_task_bits_task_cmoAll;
  assign dTask.reqSource = io_d_task_bits_task_reqSource;
  assign dTask.mergeA = io_d_task_bits_task_mergeA;
  assign dTask.aMergeTask_off = io_d_task_bits_task_aMergeTask_off;
  assign dTask.aMergeTask_alias = io_d_task_bits_task_aMergeTask_alias;
  assign dTask.aMergeTask_vaddr = io_d_task_bits_task_aMergeTask_vaddr;
  assign dTask.aMergeTask_isKeyword = io_d_task_bits_task_aMergeTask_isKeyword;
  assign dTask.aMergeTask_opcode = io_d_task_bits_task_aMergeTask_opcode;
  assign dTask.aMergeTask_param = io_d_task_bits_task_aMergeTask_param;
  assign dTask.aMergeTask_sourceId = io_d_task_bits_task_aMergeTask_sourceId;
  assign dTask.aMergeTask_meta_dirty = io_d_task_bits_task_aMergeTask_meta_dirty;
  assign dTask.aMergeTask_meta_state = io_d_task_bits_task_aMergeTask_meta_state;
  assign dTask.aMergeTask_meta_clients = io_d_task_bits_task_aMergeTask_meta_clients;
  assign dTask.aMergeTask_meta_alias = io_d_task_bits_task_aMergeTask_meta_alias;
  assign dTask.aMergeTask_meta_prefetch = io_d_task_bits_task_aMergeTask_meta_prefetch;
  assign dTask.aMergeTask_meta_prefetchSrc = io_d_task_bits_task_aMergeTask_meta_prefetchSrc;
  assign dTask.aMergeTask_meta_accessed = io_d_task_bits_task_aMergeTask_meta_accessed;
  assign dTask.aMergeTask_meta_tagErr = io_d_task_bits_task_aMergeTask_meta_tagErr;
  assign dTask.aMergeTask_meta_dataErr = io_d_task_bits_task_aMergeTask_meta_dataErr;
  assign dTask.snpHitRelease = io_d_task_bits_task_snpHitRelease;
  assign dTask.snpHitReleaseToInval = io_d_task_bits_task_snpHitReleaseToInval;
  assign dTask.snpHitReleaseToClean = io_d_task_bits_task_snpHitReleaseToClean;
  assign dTask.snpHitReleaseWithData = io_d_task_bits_task_snpHitReleaseWithData;
  assign dTask.snpHitReleaseIdx = io_d_task_bits_task_snpHitReleaseIdx;
  assign dTask.snpHitReleaseMeta_dirty = io_d_task_bits_task_snpHitReleaseMeta_dirty;
  assign dTask.snpHitReleaseMeta_state = io_d_task_bits_task_snpHitReleaseMeta_state;
  assign dTask.snpHitReleaseMeta_clients = io_d_task_bits_task_snpHitReleaseMeta_clients;
  assign dTask.snpHitReleaseMeta_alias = io_d_task_bits_task_snpHitReleaseMeta_alias;
  assign dTask.snpHitReleaseMeta_prefetch = io_d_task_bits_task_snpHitReleaseMeta_prefetch;
  assign dTask.snpHitReleaseMeta_prefetchSrc = io_d_task_bits_task_snpHitReleaseMeta_prefetchSrc;
  assign dTask.snpHitReleaseMeta_accessed = io_d_task_bits_task_snpHitReleaseMeta_accessed;
  assign dTask.snpHitReleaseMeta_tagErr = io_d_task_bits_task_snpHitReleaseMeta_tagErr;
  assign dTask.snpHitReleaseMeta_dataErr = io_d_task_bits_task_snpHitReleaseMeta_dataErr;
  assign dTask.tgtID = io_d_task_bits_task_tgtID;
  assign dTask.srcID = io_d_task_bits_task_srcID;
  assign dTask.txnID = io_d_task_bits_task_txnID;
  assign dTask.homeNID = io_d_task_bits_task_homeNID;
  assign dTask.dbID = io_d_task_bits_task_dbID;
  assign dTask.fwdNID = io_d_task_bits_task_fwdNID;
  assign dTask.fwdTxnID = io_d_task_bits_task_fwdTxnID;
  assign dTask.chiOpcode = io_d_task_bits_task_chiOpcode;
  assign dTask.resp = io_d_task_bits_task_resp;
  assign dTask.fwdState = io_d_task_bits_task_fwdState;
  assign dTask.pCrdType = io_d_task_bits_task_pCrdType;
  assign dTask.retToSrc = io_d_task_bits_task_retToSrc;
  assign dTask.likelyshared = io_d_task_bits_task_likelyshared;
  assign dTask.expCompAck = io_d_task_bits_task_expCompAck;
  assign dTask.allowRetry = io_d_task_bits_task_allowRetry;
  assign dTask.memAttr_allocate = io_d_task_bits_task_memAttr_allocate;
  assign dTask.memAttr_cacheable = io_d_task_bits_task_memAttr_cacheable;
  assign dTask.memAttr_device = io_d_task_bits_task_memAttr_device;
  assign dTask.memAttr_ewa = io_d_task_bits_task_memAttr_ewa;
  assign dTask.traceTag = io_d_task_bits_task_traceTag;

  xs_GrantBuffer_core u_core (
    .clock          (clock),
    .reset          (reset),
    .dTask_valid    (io_d_task_valid),
    .dTask          (dTask),
    .q_enq_valid    (q_enq_valid),
    .q_enq_task     (q_enq_task),
    .q_enq_grantid  (q_enq_grantid),
    .q_enq_ready    (q_enq_ready),
    .q_deq_ready    (q_deq_ready),
    .q_deq_valid    (q_deq_valid),
    .q_deq_isKeyword (q_deq_isKeyword),
    .q_deq_opcode   (q_deq_opcode),
    .q_deq_param    (q_deq_param),
    .q_deq_sourceId (q_deq_sourceId),
    .q_deq_denied   (q_deq_denied),
    .q_deq_corrupt  (q_deq_corrupt),
    .q_deq_grantid  (q_deq_grantid),
    .q_deq_data0    (q_deq_data0),
    .q_deq_data1    (q_deq_data1),
    .q_count        (q_count),
    .d_ready        (io_d_ready),
    .d_valid        (io_d_valid),
    .d_opcode       (io_d_bits_opcode),
    .d_param        (io_d_bits_param),
    .d_source       (io_d_bits_source),
    .d_sink         (io_d_bits_sink),
    .d_denied       (io_d_bits_denied),
    .d_isKeyword    (io_d_bits_echo_isKeyword),
    .d_data         (io_d_bits_data),
    .d_corrupt      (io_d_bits_corrupt),
    .e_valid        (io_e_valid),
    .e_sink         (io_e_bits_sink),
    .s1_b_tag       (io_fromReqArb_status_s1_tags_1),
    .s1_b_set       (io_fromReqArb_status_s1_sets_1),
    .pipe_valid     ('{io_pipeStatusVec_1_valid, io_pipeStatusVec_2_valid, io_pipeStatusVec_3_valid, io_pipeStatusVec_4_valid}),
    .pipe_channel   ('{io_pipeStatusVec_1_bits_channel, io_pipeStatusVec_2_bits_channel, io_pipeStatusVec_3_bits_channel, io_pipeStatusVec_4_bits_channel}),
    .blockA_s1      (io_toReqArb_blockSinkReqEntrance_blockA_s1),
    .blockB_s1      (io_toReqArb_blockSinkReqEntrance_blockB_s1),
    .blockC_s1      (io_toReqArb_blockSinkReqEntrance_blockC_s1),
    .blockMSHR      (io_toReqArb_blockMSHRReqEntrance),
    .pft_enq_valid  (pft_enq_valid),
    .pft_enq_ready  (pft_enq_ready),
    .pft_count      (pft_count),
    .gs_valid       (gs_valid),
    .gs_set         (gs_set),
    .gs_tag         (gs_tag)
  );

  // D 通道任务头队列（16 项；firtool 只存了出队用得到的字段，其余 enq 端口照接）
  Queue16_GrantQueueTask grantQueue (
    .clock                                  (clock),
    .reset                                  (reset),
    .io_enq_ready                           (q_enq_ready),
    .io_enq_valid                           (q_enq_valid),
    .io_enq_bits_task_channel               (q_enq_task.channel),
    .io_enq_bits_task_txChannel             (q_enq_task.txChannel),
    .io_enq_bits_task_set                   (q_enq_task.set),
    .io_enq_bits_task_tag                   (q_enq_task.tag),
    .io_enq_bits_task_off                   (q_enq_task.off),
    .io_enq_bits_task_alias                 (q_enq_task.alias_),
    .io_enq_bits_task_vaddr                 (q_enq_task.vaddr),
    .io_enq_bits_task_isKeyword             (q_enq_task.isKeyword),
    .io_enq_bits_task_opcode                (q_enq_task.opcode),
    .io_enq_bits_task_param                 (q_enq_task.param),
    .io_enq_bits_task_size                  (q_enq_task.size),
    .io_enq_bits_task_sourceId              (q_enq_task.sourceId),
    .io_enq_bits_task_bufIdx                (q_enq_task.bufIdx),
    .io_enq_bits_task_needProbeAckData      (q_enq_task.needProbeAckData),
    .io_enq_bits_task_denied                (q_enq_task.denied),
    .io_enq_bits_task_corrupt               (q_enq_task.corrupt),
    .io_enq_bits_task_mshrTask              (q_enq_task.mshrTask),
    .io_enq_bits_task_mshrId                (q_enq_task.mshrId),
    .io_enq_bits_task_aliasTask             (q_enq_task.aliasTask),
    .io_enq_bits_task_useProbeData          (q_enq_task.useProbeData),
    .io_enq_bits_task_mshrRetry             (q_enq_task.mshrRetry),
    .io_enq_bits_task_readProbeDataDown     (q_enq_task.readProbeDataDown),
    .io_enq_bits_task_fromL2pft             (q_enq_task.fromL2pft),
    .io_enq_bits_task_needHint              (q_enq_task.needHint),
    .io_enq_bits_task_dirty                 (q_enq_task.dirty),
    .io_enq_bits_task_way                   (q_enq_task.way),
    .io_enq_bits_task_meta_dirty            (q_enq_task.meta_dirty),
    .io_enq_bits_task_meta_state            (q_enq_task.meta_state),
    .io_enq_bits_task_meta_clients          (q_enq_task.meta_clients),
    .io_enq_bits_task_meta_alias            (q_enq_task.meta_alias),
    .io_enq_bits_task_meta_prefetch         (q_enq_task.meta_prefetch),
    .io_enq_bits_task_meta_prefetchSrc      (q_enq_task.meta_prefetchSrc),
    .io_enq_bits_task_meta_accessed         (q_enq_task.meta_accessed),
    .io_enq_bits_task_meta_tagErr           (q_enq_task.meta_tagErr),
    .io_enq_bits_task_meta_dataErr          (q_enq_task.meta_dataErr),
    .io_enq_bits_task_metaWen               (q_enq_task.metaWen),
    .io_enq_bits_task_tagWen                (q_enq_task.tagWen),
    .io_enq_bits_task_dsWen                 (q_enq_task.dsWen),
    .io_enq_bits_task_wayMask               (q_enq_task.wayMask),
    .io_enq_bits_task_replTask              (q_enq_task.replTask),
    .io_enq_bits_task_cmoTask               (q_enq_task.cmoTask),
    .io_enq_bits_task_cmoAll                (q_enq_task.cmoAll),
    .io_enq_bits_task_reqSource             (q_enq_task.reqSource),
    .io_enq_bits_task_mergeA                (q_enq_task.mergeA),
    .io_enq_bits_task_aMergeTask_off        (q_enq_task.aMergeTask_off),
    .io_enq_bits_task_aMergeTask_alias      (q_enq_task.aMergeTask_alias),
    .io_enq_bits_task_aMergeTask_vaddr      (q_enq_task.aMergeTask_vaddr),
    .io_enq_bits_task_aMergeTask_isKeyword  (q_enq_task.aMergeTask_isKeyword),
    .io_enq_bits_task_aMergeTask_opcode     (q_enq_task.aMergeTask_opcode),
    .io_enq_bits_task_aMergeTask_param      (q_enq_task.aMergeTask_param),
    .io_enq_bits_task_aMergeTask_sourceId   (q_enq_task.aMergeTask_sourceId),
    .io_enq_bits_task_aMergeTask_meta_dirty (q_enq_task.aMergeTask_meta_dirty),
    .io_enq_bits_task_aMergeTask_meta_state (q_enq_task.aMergeTask_meta_state),
    .io_enq_bits_task_aMergeTask_meta_clients (q_enq_task.aMergeTask_meta_clients),
    .io_enq_bits_task_aMergeTask_meta_alias (q_enq_task.aMergeTask_meta_alias),
    .io_enq_bits_task_aMergeTask_meta_prefetch (q_enq_task.aMergeTask_meta_prefetch),
    .io_enq_bits_task_aMergeTask_meta_prefetchSrc (q_enq_task.aMergeTask_meta_prefetchSrc),
    .io_enq_bits_task_aMergeTask_meta_accessed (q_enq_task.aMergeTask_meta_accessed),
    .io_enq_bits_task_aMergeTask_meta_tagErr (q_enq_task.aMergeTask_meta_tagErr),
    .io_enq_bits_task_aMergeTask_meta_dataErr (q_enq_task.aMergeTask_meta_dataErr),
    .io_enq_bits_task_snpHitRelease         (q_enq_task.snpHitRelease),
    .io_enq_bits_task_snpHitReleaseToInval  (q_enq_task.snpHitReleaseToInval),
    .io_enq_bits_task_snpHitReleaseToClean  (q_enq_task.snpHitReleaseToClean),
    .io_enq_bits_task_snpHitReleaseWithData (q_enq_task.snpHitReleaseWithData),
    .io_enq_bits_task_snpHitReleaseIdx      (q_enq_task.snpHitReleaseIdx),
    .io_enq_bits_task_snpHitReleaseMeta_dirty (q_enq_task.snpHitReleaseMeta_dirty),
    .io_enq_bits_task_snpHitReleaseMeta_state (q_enq_task.snpHitReleaseMeta_state),
    .io_enq_bits_task_snpHitReleaseMeta_clients (q_enq_task.snpHitReleaseMeta_clients),
    .io_enq_bits_task_snpHitReleaseMeta_alias (q_enq_task.snpHitReleaseMeta_alias),
    .io_enq_bits_task_snpHitReleaseMeta_prefetch (q_enq_task.snpHitReleaseMeta_prefetch),
    .io_enq_bits_task_snpHitReleaseMeta_prefetchSrc (q_enq_task.snpHitReleaseMeta_prefetchSrc),
    .io_enq_bits_task_snpHitReleaseMeta_accessed (q_enq_task.snpHitReleaseMeta_accessed),
    .io_enq_bits_task_snpHitReleaseMeta_tagErr (q_enq_task.snpHitReleaseMeta_tagErr),
    .io_enq_bits_task_snpHitReleaseMeta_dataErr (q_enq_task.snpHitReleaseMeta_dataErr),
    .io_enq_bits_task_tgtID                 (q_enq_task.tgtID),
    .io_enq_bits_task_srcID                 (q_enq_task.srcID),
    .io_enq_bits_task_txnID                 (q_enq_task.txnID),
    .io_enq_bits_task_homeNID               (q_enq_task.homeNID),
    .io_enq_bits_task_dbID                  (q_enq_task.dbID),
    .io_enq_bits_task_fwdNID                (q_enq_task.fwdNID),
    .io_enq_bits_task_fwdTxnID              (q_enq_task.fwdTxnID),
    .io_enq_bits_task_chiOpcode             (q_enq_task.chiOpcode),
    .io_enq_bits_task_resp                  (q_enq_task.resp),
    .io_enq_bits_task_fwdState              (q_enq_task.fwdState),
    .io_enq_bits_task_pCrdType              (q_enq_task.pCrdType),
    .io_enq_bits_task_retToSrc              (q_enq_task.retToSrc),
    .io_enq_bits_task_likelyshared          (q_enq_task.likelyshared),
    .io_enq_bits_task_expCompAck            (q_enq_task.expCompAck),
    .io_enq_bits_task_allowRetry            (q_enq_task.allowRetry),
    .io_enq_bits_task_memAttr_allocate      (q_enq_task.memAttr_allocate),
    .io_enq_bits_task_memAttr_cacheable     (q_enq_task.memAttr_cacheable),
    .io_enq_bits_task_memAttr_device        (q_enq_task.memAttr_device),
    .io_enq_bits_task_memAttr_ewa           (q_enq_task.memAttr_ewa),
    .io_enq_bits_task_traceTag              (q_enq_task.traceTag),
    .io_enq_bits_grantid                    (q_enq_grantid),
    .io_deq_ready                           (q_deq_ready),
    .io_deq_valid                           (q_deq_valid),
    .io_deq_bits_task_isKeyword             (q_deq_isKeyword),
    .io_deq_bits_task_opcode                (q_deq_opcode),
    .io_deq_bits_task_param                 (q_deq_param),
    .io_deq_bits_task_sourceId              (q_deq_sourceId),
    .io_deq_bits_task_denied                (q_deq_denied),
    .io_deq_bits_task_corrupt               (q_deq_corrupt),
    .io_deq_bits_grantid                    (q_deq_grantid),
    .io_count                               (q_count)
  );

  // 两拍数据各一个队列，与任务头队列同进同出
  Queue16_GrantQueueData grantQueueData0 (
    .clock                  (clock),
    .reset                  (reset),
    .io_enq_valid           (q_enq_valid),
    .io_enq_bits_data_data  (io_d_task_bits_data_data[255:0]),
    .io_deq_ready           (q_deq_ready),
    .io_deq_bits_data_data  (q_deq_data0)
  );
  Queue16_GrantQueueData grantQueueData1 (
    .clock                  (clock),
    .reset                  (reset),
    .io_enq_valid           (q_enq_valid),
    .io_enq_bits_data_data  (io_d_task_bits_data_data[511:256]),
    .io_deq_ready           (q_deq_ready),
    .io_deq_bits_data_data  (q_deq_data1)
  );

  // 预取响应队列（10 项，flow），出口就是 io_prefetchResp
  Queue10_GrantBuffer_Anon pftRespQueue (
    .clock                (clock),
    .reset                (reset),
    .io_enq_ready         (pft_enq_ready),
    .io_enq_valid         (pft_enq_valid),
    .io_enq_bits_tag      (io_d_task_bits_task_tag),
    .io_enq_bits_set      (io_d_task_bits_task_set),
    .io_enq_bits_vaddr    (io_d_task_bits_task_vaddr),
    .io_enq_bits_pfSource (io_d_task_bits_task_reqSource),
    .io_deq_ready         (io_prefetchResp_ready),
    .io_deq_valid         (io_prefetchResp_valid),
    .io_deq_bits_tag      (pft_deq_tag),
    .io_deq_bits_set      (io_prefetchResp_bits_set),
    .io_deq_bits_vaddr    (io_prefetchResp_bits_vaddr),
    .io_deq_bits_pfSource (io_prefetchResp_bits_pfSource),
    .io_count             (pft_count)
  );
  // PrefetchResp.tag 比 L2 tag 宽 2 位（预取器按更大的 tag 定义），高位补 0
  assign io_prefetchResp_bits_tag = {2'b00, pft_deq_tag};

  assign io_grantStatus_0_valid = gs_valid[0];
  assign io_grantStatus_0_set   = gs_set[0];
  assign io_grantStatus_0_tag   = gs_tag[0];
  assign io_grantStatus_1_valid = gs_valid[1];
  assign io_grantStatus_1_set   = gs_set[1];
  assign io_grantStatus_1_tag   = gs_tag[1];
  assign io_grantStatus_2_valid = gs_valid[2];
  assign io_grantStatus_2_set   = gs_set[2];
  assign io_grantStatus_2_tag   = gs_tag[2];
  assign io_grantStatus_3_valid = gs_valid[3];
  assign io_grantStatus_3_set   = gs_set[3];
  assign io_grantStatus_3_tag   = gs_tag[3];
  assign io_grantStatus_4_valid = gs_valid[4];
  assign io_grantStatus_4_set   = gs_set[4];
  assign io_grantStatus_4_tag   = gs_tag[4];
  assign io_grantStatus_5_valid = gs_valid[5];
  assign io_grantStatus_5_set   = gs_set[5];
  assign io_grantStatus_5_tag   = gs_tag[5];
  assign io_grantStatus_6_valid = gs_valid[6];
  assign io_grantStatus_6_set   = gs_set[6];
  assign io_grantStatus_6_tag   = gs_tag[6];
  assign io_grantStatus_7_valid = gs_valid[7];
  assign io_grantStatus_7_set   = gs_set[7];
  assign io_grantStatus_7_tag   = gs_tag[7];
  assign io_grantStatus_8_valid = gs_valid[8];
  assign io_grantStatus_8_set   = gs_set[8];
  assign io_grantStatus_8_tag   = gs_tag[8];
  assign io_grantStatus_9_valid = gs_valid[9];
  assign io_grantStatus_9_set   = gs_set[9];
  assign io_grantStatus_9_tag   = gs_tag[9];
  assign io_grantStatus_10_valid = gs_valid[10];
  assign io_grantStatus_10_set   = gs_set[10];
  assign io_grantStatus_10_tag   = gs_tag[10];
  assign io_grantStatus_11_valid = gs_valid[11];
  assign io_grantStatus_11_set   = gs_set[11];
  assign io_grantStatus_11_tag   = gs_tag[11];
  assign io_grantStatus_12_valid = gs_valid[12];
  assign io_grantStatus_12_set   = gs_set[12];
  assign io_grantStatus_12_tag   = gs_tag[12];
  assign io_grantStatus_13_valid = gs_valid[13];
  assign io_grantStatus_13_set   = gs_set[13];
  assign io_grantStatus_13_tag   = gs_tag[13];
  assign io_grantStatus_14_valid = gs_valid[14];
  assign io_grantStatus_14_set   = gs_set[14];
  assign io_grantStatus_14_tag   = gs_tag[14];
  assign io_grantStatus_15_valid = gs_valid[15];
  assign io_grantStatus_15_set   = gs_set[15];
  assign io_grantStatus_15_tag   = gs_tag[15];

endmodule
// END GENERATED(wrapper)
