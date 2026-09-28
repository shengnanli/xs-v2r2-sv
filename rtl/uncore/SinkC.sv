// SinkC.sv —— L2 slice 的 TileLink C 通道入口：接收 L1 的 Release / ReleaseData 与 ProbeAck / ProbeAckData
//
// 对照 coupledL2/src/main/scala/coupledL2/SinkC.scala（bufBlocks = 4，beatSize = 2，beat 256 位）。
// C 通道两类报文走两条路：
//   * Release / ReleaseData（L1 主动写回，opcode[1]=1）：变成 TaskBundle 进 4 项 taskBuf，经轮转仲裁器
//     RRArbiterInit_16（taskArb）送 RequestArb（io_task）。带数据的两拍数据先存进同号 dataBuf，
//     MainPipe 读 DS 前从这里取（io_bufResp，任务出队后第二拍给出）。
//   * ProbeAck / ProbeAckData（对 Probe 的应答，opcode[1]=0）：不进缓冲，直接把应答信息送 MSHR（io_resp）；
//     带数据的两拍拼成 512 位写 releaseBuf（io_releaseBufWrite，第一拍先存进 probeAckDataBuf）。
//
// 细节（bug-for-bug 照 golden）：
//   * beat 计数：edgeIn.count —— 带数据且 size 为整块（64B）时两拍，r_counter 标记"在第二拍"。
//   * 表项分配：nextPtr = 第一个空表项（空 = 既没有待发任务、也没有未取走的数据）；ReleaseData 在第一拍锁定
//     nextPtrReg，两拍数据与最后的任务都进 nextPtrReg 号；无数据的 Release 直接进 nextPtr 号。
//   * 满且是第一拍的 Release 才反压（io_c_ready = !Release || 非第一拍 || !full）；ProbeAck 永远收。
//   * 新数据嵌套：ReleaseData 出队时若某 MSHR 正等着同地址的回填（blockRefill），下一拍把这块新数据写进
//     refillBuf（io_refillBufWrite），免得 MSHR 随后的替换释放写回旧数据。
//   * dataBuf 的读出：io_bufResp = RegNext(RegEnable(dataBuf[bufIdx], task.fire))，同时在出队后第二拍清掉该项
//     的 beatValids；io_refillBufWrite 的数据则是"上一拍出队的 bufIdx"索引的**当拍** dataBuf。

package sinkc_pkg;
  // BEGIN GENERATED(task_t) —— scripts/gen_l2_sinkc.py 从 golden 端口表生成
  // TaskBundle（94 个字段，383 位）：字段顺序与位宽逐字取自 golden 端口 io_task_bits_*
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

  localparam int unsigned N_BUF  = 4;    // bufBlocks
  localparam int unsigned N_MSHR = 16;
  // TileLink C opcode
  localparam logic [2:0] ProbeAck     = 3'd4;
  localparam logic [2:0] ProbeAckData = 3'd5;
  localparam logic [2:0] Release      = 3'd6;
  localparam logic [2:0] ReleaseData  = 3'd7;
endpackage

module xs_SinkC_core
  import sinkc_pkg::*;
(
  input  logic         clock,
  input  logic         reset,

  // ---- TileLink C 通道 ----
  input  logic         c_valid,
  output logic         c_ready,
  input  logic [2:0]   c_opcode,
  input  logic [2:0]   c_param,
  input  logic [2:0]   c_size,
  input  logic [6:0]   c_source,
  input  logic [47:0]  c_address,
  input  logic [255:0] c_data,
  input  logic         c_corrupt,

  // ---- 任务缓冲 <-> 仲裁器 taskArb ----
  output logic         arbIn_valid [N_BUF],
  output task_t        arbIn_task  [N_BUF],
  input  logic         arbIn_ready [N_BUF],
  input  logic         arbOut_valid,
  input  logic [8:0]   arbOut_set,
  input  logic [30:0]  arbOut_tag,
  input  logic [3:0]   arbOut_opcode,
  input  logic [1:0]   arbOut_bufIdx,
  input  logic         task_ready,

  // ---- ProbeAck 应答（给 MSHR）----
  output logic         resp_valid,
  output logic [8:0]   resp_set,
  output logic [30:0]  resp_tag,
  output logic         resp_last,
  output logic         resp_denied,
  output logic         resp_corrupt,

  // ---- 数据通路 ----
  output logic         releaseBufWrite_valid,
  output logic [511:0] releaseBufWrite_data,
  output logic [255:0] bufResp_data [2],
  output logic         refillBufWrite_valid,
  output logic [7:0]   refillBufWrite_id,
  output logic [511:0] refillBufWrite_data,

  // ---- MSHR 状态（新数据嵌套判定）----
  input  logic         ms_valid       [N_MSHR],
  input  logic [8:0]   ms_set         [N_MSHR],
  input  logic [30:0]  ms_reqTag      [N_MSHR],
  input  logic         ms_blockRefill [N_MSHR]
);

  // ===========================================================================
  // §1 报文分类与 beat 计数（edgeIn.count）
  // ===========================================================================
  logic isRelease, hasData, cFire;
  logic r_counter;          // 1 = 正在收两拍报文的第二拍
  logic twoBeats;           // 本报文带数据且是整块（size 6 → 两拍）
  logic first, last;
  logic beatIdx;            // 本拍是第几拍（edgeIn.count 的 beat = beats1 & counter）
  logic [12:0] sizeDecode;  // 13'h3F << size：第 5 位为 1 表示不足一个 beat（单拍）

  assign isRelease = c_opcode[1];
  assign hasData   = c_opcode[0];
  assign cFire     = c_ready & c_valid;
  assign sizeDecode = 13'h3F << c_size;
  assign twoBeats  = hasData & ~sizeDecode[5];                 // beats1：带数据且超过一个 beat
  assign first     = ~r_counter;
  assign last      = r_counter | ~twoBeats;
  assign beatIdx   = twoBeats & r_counter;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)       r_counter <= 1'b0;
    else if (cFire)  r_counter <= r_counter ? 1'b0 : twoBeats;
  end

  // ===========================================================================
  // §2 缓冲：4 项，每项 = 一个任务 + 两拍数据
  // ===========================================================================
  logic [255:0] dataBuf    [N_BUF][2];
  logic         beatValids [N_BUF][2];
  task_t        taskBuf    [N_BUF];
  logic         taskValids [N_BUF];
  logic [N_BUF-1:0] bufValids;
  logic         full;
  logic [1:0]   nextPtr, nextPtrReg;

  always_comb begin
    for (int k = 0; k < N_BUF; k++)
      bufValids[k] = taskValids[k] | beatValids[k][0] | beatValids[k][1];
  end
  assign full = &bufValids;

  // 第一个空表项（PriorityEncoder，全满时缺省 3）
  always_comb begin
    nextPtr = 2'd3;
    for (int k = N_BUF - 2; k >= 0; k--) if (!bufValids[k]) nextPtr = 2'(k);
  end

  assign c_ready = ~isRelease | ~first | ~full;

  // Release 报文 → TaskBundle（toTaskBundle：未列出的字段一律 0）
  task_t cTask;
  always_comb begin
    cTask           = '0;
    cTask.channel   = 3'b100;                  // C 通道
    cTask.tag       = c_address[47:17];        // parseAddress：{tag 31, set 9, bank 2, offset 6}
    cTask.set       = c_address[16:8];
    cTask.off       = c_address[5:0];
    cTask.opcode    = {1'b0, c_opcode};
    cTask.param     = c_param;
    cTask.size      = c_size;
    cTask.sourceId  = c_source;
    cTask.corrupt   = c_corrupt & (c_opcode == ProbeAckData || c_opcode == ReleaseData);
    cTask.denied    = c_corrupt & (c_opcode == ProbeAck || c_opcode == Release);
    cTask.wayMask   = 8'hFF;
  end

  // 出队后第二拍清该项的 beatValids
  logic       taskFire;            // io_task.fire
  logic       taskFirePrev;        // RegNext(io_task.fire)
  logic [1:0] taskBufIdxPrev;      // RegNext(io_task.bits.bufIdx)
  assign taskFire = task_ready & arbOut_valid;

  logic releaseFire, dataBeat;
  logic [1:0] beatPtr;             // 本拍数据写进哪一项：第一拍 nextPtr，第二拍 nextPtrReg
  assign releaseFire = cFire & isRelease;
  assign dataBeat    = releaseFire & hasData;
  assign beatPtr     = first ? nextPtr : nextPtrReg;

  logic       taskAlloc;           // 本拍把一个 Release 任务放进缓冲
  logic [1:0] taskPtr;
  assign taskAlloc = releaseFire & last;
  assign taskPtr   = hasData ? nextPtrReg : nextPtr;

  logic writeBeat [N_BUF][2];      // 本拍把 c_data 写进第 k 项的第 b 拍
  always_comb begin
    for (int k = 0; k < N_BUF; k++)
      for (int b = 0; b < 2; b++)
        writeBeat[k][b] = dataBeat && beatPtr == 2'(k) && beatIdx == 1'(b);
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int k = 0; k < N_BUF; k++) begin
        dataBuf[k][0]    <= '0;
        dataBuf[k][1]    <= '0;
        beatValids[k][0] <= 1'b0;
        beatValids[k][1] <= 1'b0;
        taskBuf[k]       <= '0;
        taskValids[k]    <= 1'b0;
      end
      nextPtrReg <= '0;
    end else begin
      for (int k = 0; k < N_BUF; k++) begin
        for (int b = 0; b < 2; b++) begin
          if (writeBeat[k][b]) dataBuf[k][b] <= c_data;
          beatValids[k][b] <= ~(taskFirePrev && taskBufIdxPrev == 2'(k)) & (writeBeat[k][b] | beatValids[k][b]);
        end
        if (taskAlloc && taskPtr == 2'(k)) begin
          taskBuf[k]        <= cTask;
          taskBuf[k].bufIdx <= taskPtr;
        end
        taskValids[k] <= ~(arbIn_ready[k] & taskValids[k]) & ((taskAlloc && taskPtr == 2'(k)) | taskValids[k]);
      end
      if (releaseFire && first && hasData) nextPtrReg <= nextPtr;
    end
  end

  for (genvar k = 0; k < int'(N_BUF); k++) begin : g_arb
    assign arbIn_valid[k] = taskValids[k];
    assign arbIn_task[k]  = taskBuf[k];
  end

  // ===========================================================================
  // §3 ProbeAck：应答信息给 MSHR；ProbeAckData 两拍拼成整块写 releaseBuf
  // ===========================================================================
  logic [255:0] probeAckDataBuf;   // ProbeAckData 的第一拍
  always_ff @(posedge clock or posedge reset) begin
    if (reset)                                             probeAckDataBuf <= '0;
    else if (c_valid && c_opcode == ProbeAckData && first) probeAckDataBuf <= c_data;
  end

  assign resp_valid   = c_valid & (first | last) & ~isRelease;
  assign resp_set     = c_address[16:8];
  assign resp_tag     = c_address[47:17];
  assign resp_last    = last;
  assign resp_denied  = c_corrupt & (c_opcode == ProbeAck || c_opcode == Release);
  assign resp_corrupt = c_corrupt & (c_opcode == ProbeAckData || c_opcode == ReleaseData);

  assign releaseBufWrite_valid = c_valid & (c_opcode == ProbeAckData) & last;
  assign releaseBufWrite_data  = {c_data, probeAckDataBuf};

  // ===========================================================================
  // §4 任务出队后的数据读出与新数据嵌套
  // ===========================================================================
  logic [15:0]  newdataMask;       // 等着同地址回填的 MSHR
  always_comb begin
    for (int i = 0; i < N_MSHR; i++)
      newdataMask[i] = ms_valid[i] && ms_set[i] == arbOut_set && ms_reqTag[i] == arbOut_tag && ms_blockRefill[i];
  end

  logic         refillValidReg;
  logic [3:0]   refillIdReg;       // OHToUInt(newdataMask)
  logic [1:0]   refillBufIdxReg;   // RegNext(io_task.bits.bufIdx)
  logic [255:0] bufRespStage [2];  // RegEnable(dataBuf(bufIdx), task.fire)
  logic [255:0] bufRespOut   [2];  // 再 RegNext 一拍

  always_ff @(posedge clock or posedge reset) begin
    if (reset) refillValidReg <= 1'b0;
    else       refillValidReg <= taskFire & (arbOut_opcode == {1'b0, ReleaseData}) & (|newdataMask);
  end

  logic [3:0] newdataId;           // OHToUInt(newdataMask)（正常至多一位）
  always_comb begin
    newdataId = '0;
    for (int i = 0; i < N_MSHR; i++) if (newdataMask[i]) newdataId |= 4'(i);
  end

  always_ff @(posedge clock) begin
    refillIdReg     <= newdataId;
    refillBufIdxReg <= arbOut_bufIdx;
    if (taskFire) begin
      bufRespStage[0] <= dataBuf[arbOut_bufIdx][0];
      bufRespStage[1] <= dataBuf[arbOut_bufIdx][1];
    end
    bufRespOut[0]  <= bufRespStage[0];
    bufRespOut[1]  <= bufRespStage[1];
    taskFirePrev   <= taskFire;
    taskBufIdxPrev <= arbOut_bufIdx;
  end

  assign refillBufWrite_valid = refillValidReg;
  assign refillBufWrite_id    = {4'h0, refillIdReg};
  assign refillBufWrite_data  = {dataBuf[refillBufIdxReg][1], dataBuf[refillBufIdxReg][0]};
  assign bufResp_data[0]      = bufRespOut[0];
  assign bufResp_data[1]      = bufRespOut[1];

endmodule

// BEGIN GENERATED(wrapper) —— scripts/gen_l2_sinkc.py 从 golden 端口表生成
module SinkC
  import sinkc_pkg::*;
(
  input  logic clock,
  input  logic reset,
  output logic io_c_ready,
  input  logic io_c_valid,
  input  logic [2:0] io_c_bits_opcode,
  input  logic [2:0] io_c_bits_param,
  input  logic [2:0] io_c_bits_size,
  input  logic [6:0] io_c_bits_source,
  input  logic [47:0] io_c_bits_address,
  input  logic [255:0] io_c_bits_data,
  input  logic io_c_bits_corrupt,
  input  logic io_task_ready,
  output logic io_task_valid,
  output logic [2:0] io_task_bits_channel,
  output logic [2:0] io_task_bits_txChannel,
  output logic [8:0] io_task_bits_set,
  output logic [30:0] io_task_bits_tag,
  output logic [5:0] io_task_bits_off,
  output logic [1:0] io_task_bits_alias,
  output logic [43:0] io_task_bits_vaddr,
  output logic io_task_bits_isKeyword,
  output logic [3:0] io_task_bits_opcode,
  output logic [2:0] io_task_bits_param,
  output logic [2:0] io_task_bits_size,
  output logic [6:0] io_task_bits_sourceId,
  output logic [1:0] io_task_bits_bufIdx,
  output logic io_task_bits_needProbeAckData,
  output logic io_task_bits_denied,
  output logic io_task_bits_corrupt,
  output logic io_task_bits_mshrTask,
  output logic [7:0] io_task_bits_mshrId,
  output logic io_task_bits_aliasTask,
  output logic io_task_bits_useProbeData,
  output logic io_task_bits_mshrRetry,
  output logic io_task_bits_readProbeDataDown,
  output logic io_task_bits_fromL2pft,
  output logic io_task_bits_needHint,
  output logic io_task_bits_dirty,
  output logic [2:0] io_task_bits_way,
  output logic io_task_bits_meta_dirty,
  output logic [1:0] io_task_bits_meta_state,
  output logic io_task_bits_meta_clients,
  output logic [1:0] io_task_bits_meta_alias,
  output logic io_task_bits_meta_prefetch,
  output logic [2:0] io_task_bits_meta_prefetchSrc,
  output logic io_task_bits_meta_accessed,
  output logic io_task_bits_meta_tagErr,
  output logic io_task_bits_meta_dataErr,
  output logic io_task_bits_metaWen,
  output logic io_task_bits_tagWen,
  output logic io_task_bits_dsWen,
  output logic [7:0] io_task_bits_wayMask,
  output logic io_task_bits_replTask,
  output logic io_task_bits_cmoTask,
  output logic io_task_bits_cmoAll,
  output logic [4:0] io_task_bits_reqSource,
  output logic io_task_bits_mergeA,
  output logic [5:0] io_task_bits_aMergeTask_off,
  output logic [1:0] io_task_bits_aMergeTask_alias,
  output logic [43:0] io_task_bits_aMergeTask_vaddr,
  output logic io_task_bits_aMergeTask_isKeyword,
  output logic [2:0] io_task_bits_aMergeTask_opcode,
  output logic [2:0] io_task_bits_aMergeTask_param,
  output logic [6:0] io_task_bits_aMergeTask_sourceId,
  output logic io_task_bits_aMergeTask_meta_dirty,
  output logic [1:0] io_task_bits_aMergeTask_meta_state,
  output logic io_task_bits_aMergeTask_meta_clients,
  output logic [1:0] io_task_bits_aMergeTask_meta_alias,
  output logic io_task_bits_aMergeTask_meta_prefetch,
  output logic [2:0] io_task_bits_aMergeTask_meta_prefetchSrc,
  output logic io_task_bits_aMergeTask_meta_accessed,
  output logic io_task_bits_aMergeTask_meta_tagErr,
  output logic io_task_bits_aMergeTask_meta_dataErr,
  output logic io_task_bits_snpHitRelease,
  output logic io_task_bits_snpHitReleaseToInval,
  output logic io_task_bits_snpHitReleaseToClean,
  output logic io_task_bits_snpHitReleaseWithData,
  output logic [7:0] io_task_bits_snpHitReleaseIdx,
  output logic io_task_bits_snpHitReleaseMeta_dirty,
  output logic [1:0] io_task_bits_snpHitReleaseMeta_state,
  output logic io_task_bits_snpHitReleaseMeta_clients,
  output logic [1:0] io_task_bits_snpHitReleaseMeta_alias,
  output logic io_task_bits_snpHitReleaseMeta_prefetch,
  output logic [2:0] io_task_bits_snpHitReleaseMeta_prefetchSrc,
  output logic io_task_bits_snpHitReleaseMeta_accessed,
  output logic io_task_bits_snpHitReleaseMeta_tagErr,
  output logic io_task_bits_snpHitReleaseMeta_dataErr,
  output logic [10:0] io_task_bits_tgtID,
  output logic [10:0] io_task_bits_srcID,
  output logic [11:0] io_task_bits_txnID,
  output logic [10:0] io_task_bits_homeNID,
  output logic [11:0] io_task_bits_dbID,
  output logic [10:0] io_task_bits_fwdNID,
  output logic [11:0] io_task_bits_fwdTxnID,
  output logic [6:0] io_task_bits_chiOpcode,
  output logic [2:0] io_task_bits_resp,
  output logic [2:0] io_task_bits_fwdState,
  output logic [3:0] io_task_bits_pCrdType,
  output logic io_task_bits_retToSrc,
  output logic io_task_bits_likelyshared,
  output logic io_task_bits_expCompAck,
  output logic io_task_bits_allowRetry,
  output logic io_task_bits_memAttr_allocate,
  output logic io_task_bits_memAttr_cacheable,
  output logic io_task_bits_memAttr_device,
  output logic io_task_bits_memAttr_ewa,
  output logic io_task_bits_traceTag,
  output logic io_resp_valid,
  output logic [8:0] io_resp_set,
  output logic [30:0] io_resp_tag,
  output logic [2:0] io_resp_respInfo_opcode,
  output logic [2:0] io_resp_respInfo_param,
  output logic io_resp_respInfo_last,
  output logic io_resp_respInfo_denied,
  output logic io_resp_respInfo_corrupt,
  output logic io_releaseBufWrite_valid,
  output logic [511:0] io_releaseBufWrite_bits_data_data,
  output logic [255:0] io_bufResp_data_0,
  output logic [255:0] io_bufResp_data_1,
  output logic io_refillBufWrite_valid,
  output logic [7:0] io_refillBufWrite_bits_id,
  output logic [511:0] io_refillBufWrite_bits_data_data,
  input  logic io_msInfo_0_valid,
  input  logic [8:0] io_msInfo_0_bits_set,
  input  logic [30:0] io_msInfo_0_bits_reqTag,
  input  logic io_msInfo_0_bits_blockRefill,
  input  logic io_msInfo_1_valid,
  input  logic [8:0] io_msInfo_1_bits_set,
  input  logic [30:0] io_msInfo_1_bits_reqTag,
  input  logic io_msInfo_1_bits_blockRefill,
  input  logic io_msInfo_2_valid,
  input  logic [8:0] io_msInfo_2_bits_set,
  input  logic [30:0] io_msInfo_2_bits_reqTag,
  input  logic io_msInfo_2_bits_blockRefill,
  input  logic io_msInfo_3_valid,
  input  logic [8:0] io_msInfo_3_bits_set,
  input  logic [30:0] io_msInfo_3_bits_reqTag,
  input  logic io_msInfo_3_bits_blockRefill,
  input  logic io_msInfo_4_valid,
  input  logic [8:0] io_msInfo_4_bits_set,
  input  logic [30:0] io_msInfo_4_bits_reqTag,
  input  logic io_msInfo_4_bits_blockRefill,
  input  logic io_msInfo_5_valid,
  input  logic [8:0] io_msInfo_5_bits_set,
  input  logic [30:0] io_msInfo_5_bits_reqTag,
  input  logic io_msInfo_5_bits_blockRefill,
  input  logic io_msInfo_6_valid,
  input  logic [8:0] io_msInfo_6_bits_set,
  input  logic [30:0] io_msInfo_6_bits_reqTag,
  input  logic io_msInfo_6_bits_blockRefill,
  input  logic io_msInfo_7_valid,
  input  logic [8:0] io_msInfo_7_bits_set,
  input  logic [30:0] io_msInfo_7_bits_reqTag,
  input  logic io_msInfo_7_bits_blockRefill,
  input  logic io_msInfo_8_valid,
  input  logic [8:0] io_msInfo_8_bits_set,
  input  logic [30:0] io_msInfo_8_bits_reqTag,
  input  logic io_msInfo_8_bits_blockRefill,
  input  logic io_msInfo_9_valid,
  input  logic [8:0] io_msInfo_9_bits_set,
  input  logic [30:0] io_msInfo_9_bits_reqTag,
  input  logic io_msInfo_9_bits_blockRefill,
  input  logic io_msInfo_10_valid,
  input  logic [8:0] io_msInfo_10_bits_set,
  input  logic [30:0] io_msInfo_10_bits_reqTag,
  input  logic io_msInfo_10_bits_blockRefill,
  input  logic io_msInfo_11_valid,
  input  logic [8:0] io_msInfo_11_bits_set,
  input  logic [30:0] io_msInfo_11_bits_reqTag,
  input  logic io_msInfo_11_bits_blockRefill,
  input  logic io_msInfo_12_valid,
  input  logic [8:0] io_msInfo_12_bits_set,
  input  logic [30:0] io_msInfo_12_bits_reqTag,
  input  logic io_msInfo_12_bits_blockRefill,
  input  logic io_msInfo_13_valid,
  input  logic [8:0] io_msInfo_13_bits_set,
  input  logic [30:0] io_msInfo_13_bits_reqTag,
  input  logic io_msInfo_13_bits_blockRefill,
  input  logic io_msInfo_14_valid,
  input  logic [8:0] io_msInfo_14_bits_set,
  input  logic [30:0] io_msInfo_14_bits_reqTag,
  input  logic io_msInfo_14_bits_blockRefill,
  input  logic io_msInfo_15_valid,
  input  logic [8:0] io_msInfo_15_bits_set,
  input  logic [30:0] io_msInfo_15_bits_reqTag,
  input  logic io_msInfo_15_bits_blockRefill
);

  logic  arbIn_valid [N_BUF];
  task_t arbIn_task  [N_BUF];
  logic  arbIn_ready [N_BUF];
  logic [255:0] bufResp [2];

  xs_SinkC_core u_core (
    .clock                  (clock),
    .reset                  (reset),
    .c_valid                (io_c_valid),
    .c_ready                (io_c_ready),
    .c_opcode               (io_c_bits_opcode),
    .c_param                (io_c_bits_param),
    .c_size                 (io_c_bits_size),
    .c_source               (io_c_bits_source),
    .c_address              (io_c_bits_address),
    .c_data                 (io_c_bits_data),
    .c_corrupt              (io_c_bits_corrupt),
    .arbIn_valid            (arbIn_valid),
    .arbIn_task             (arbIn_task),
    .arbIn_ready            (arbIn_ready),
    .arbOut_valid           (io_task_valid),
    .arbOut_set             (io_task_bits_set),
    .arbOut_tag             (io_task_bits_tag),
    .arbOut_opcode          (io_task_bits_opcode),
    .arbOut_bufIdx          (io_task_bits_bufIdx),
    .task_ready             (io_task_ready),
    .resp_valid             (io_resp_valid),
    .resp_set               (io_resp_set),
    .resp_tag               (io_resp_tag),
    .resp_last              (io_resp_respInfo_last),
    .resp_denied            (io_resp_respInfo_denied),
    .resp_corrupt           (io_resp_respInfo_corrupt),
    .releaseBufWrite_valid  (io_releaseBufWrite_valid),
    .releaseBufWrite_data   (io_releaseBufWrite_bits_data_data),
    .bufResp_data           (bufResp),
    .refillBufWrite_valid   (io_refillBufWrite_valid),
    .refillBufWrite_id      (io_refillBufWrite_bits_id),
    .refillBufWrite_data    (io_refillBufWrite_bits_data_data),
    .ms_valid               ('{io_msInfo_0_valid, io_msInfo_1_valid, io_msInfo_2_valid, io_msInfo_3_valid, io_msInfo_4_valid, io_msInfo_5_valid, io_msInfo_6_valid, io_msInfo_7_valid, io_msInfo_8_valid, io_msInfo_9_valid, io_msInfo_10_valid, io_msInfo_11_valid, io_msInfo_12_valid, io_msInfo_13_valid, io_msInfo_14_valid, io_msInfo_15_valid}),
    .ms_set                 ('{io_msInfo_0_bits_set, io_msInfo_1_bits_set, io_msInfo_2_bits_set, io_msInfo_3_bits_set, io_msInfo_4_bits_set, io_msInfo_5_bits_set, io_msInfo_6_bits_set, io_msInfo_7_bits_set, io_msInfo_8_bits_set, io_msInfo_9_bits_set, io_msInfo_10_bits_set, io_msInfo_11_bits_set, io_msInfo_12_bits_set, io_msInfo_13_bits_set, io_msInfo_14_bits_set, io_msInfo_15_bits_set}),
    .ms_reqTag              ('{io_msInfo_0_bits_reqTag, io_msInfo_1_bits_reqTag, io_msInfo_2_bits_reqTag, io_msInfo_3_bits_reqTag, io_msInfo_4_bits_reqTag, io_msInfo_5_bits_reqTag, io_msInfo_6_bits_reqTag, io_msInfo_7_bits_reqTag, io_msInfo_8_bits_reqTag, io_msInfo_9_bits_reqTag, io_msInfo_10_bits_reqTag, io_msInfo_11_bits_reqTag, io_msInfo_12_bits_reqTag, io_msInfo_13_bits_reqTag, io_msInfo_14_bits_reqTag, io_msInfo_15_bits_reqTag}),
    .ms_blockRefill         ('{io_msInfo_0_bits_blockRefill, io_msInfo_1_bits_blockRefill, io_msInfo_2_bits_blockRefill, io_msInfo_3_bits_blockRefill, io_msInfo_4_bits_blockRefill, io_msInfo_5_bits_blockRefill, io_msInfo_6_bits_blockRefill, io_msInfo_7_bits_blockRefill, io_msInfo_8_bits_blockRefill, io_msInfo_9_bits_blockRefill, io_msInfo_10_bits_blockRefill, io_msInfo_11_bits_blockRefill, io_msInfo_12_bits_blockRefill, io_msInfo_13_bits_blockRefill, io_msInfo_14_bits_blockRefill, io_msInfo_15_bits_blockRefill})
  );

  assign io_resp_respInfo_opcode = io_c_bits_opcode;
  assign io_resp_respInfo_param  = io_c_bits_param;
  assign io_bufResp_data_0 = bufResp[0];
  assign io_bufResp_data_1 = bufResp[1];

  // 4 项 Release 任务轮转仲裁（出口直接就是 io_task）
  RRArbiterInit_16 taskArb (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_in_0_ready                            (arbIn_ready[0]),
    .io_in_0_valid                            (arbIn_valid[0]),
    .io_in_0_bits_channel                     (arbIn_task[0].channel),
    .io_in_0_bits_txChannel                   (arbIn_task[0].txChannel),
    .io_in_0_bits_set                         (arbIn_task[0].set),
    .io_in_0_bits_tag                         (arbIn_task[0].tag),
    .io_in_0_bits_off                         (arbIn_task[0].off),
    .io_in_0_bits_alias                       (arbIn_task[0].alias_),
    .io_in_0_bits_vaddr                       (arbIn_task[0].vaddr),
    .io_in_0_bits_isKeyword                   (arbIn_task[0].isKeyword),
    .io_in_0_bits_opcode                      (arbIn_task[0].opcode),
    .io_in_0_bits_param                       (arbIn_task[0].param),
    .io_in_0_bits_size                        (arbIn_task[0].size),
    .io_in_0_bits_sourceId                    (arbIn_task[0].sourceId),
    .io_in_0_bits_bufIdx                      (arbIn_task[0].bufIdx),
    .io_in_0_bits_needProbeAckData            (arbIn_task[0].needProbeAckData),
    .io_in_0_bits_denied                      (arbIn_task[0].denied),
    .io_in_0_bits_corrupt                     (arbIn_task[0].corrupt),
    .io_in_0_bits_mshrTask                    (arbIn_task[0].mshrTask),
    .io_in_0_bits_mshrId                      (arbIn_task[0].mshrId),
    .io_in_0_bits_aliasTask                   (arbIn_task[0].aliasTask),
    .io_in_0_bits_useProbeData                (arbIn_task[0].useProbeData),
    .io_in_0_bits_mshrRetry                   (arbIn_task[0].mshrRetry),
    .io_in_0_bits_readProbeDataDown           (arbIn_task[0].readProbeDataDown),
    .io_in_0_bits_fromL2pft                   (arbIn_task[0].fromL2pft),
    .io_in_0_bits_needHint                    (arbIn_task[0].needHint),
    .io_in_0_bits_dirty                       (arbIn_task[0].dirty),
    .io_in_0_bits_way                         (arbIn_task[0].way),
    .io_in_0_bits_meta_dirty                  (arbIn_task[0].meta_dirty),
    .io_in_0_bits_meta_state                  (arbIn_task[0].meta_state),
    .io_in_0_bits_meta_clients                (arbIn_task[0].meta_clients),
    .io_in_0_bits_meta_alias                  (arbIn_task[0].meta_alias),
    .io_in_0_bits_meta_prefetch               (arbIn_task[0].meta_prefetch),
    .io_in_0_bits_meta_prefetchSrc            (arbIn_task[0].meta_prefetchSrc),
    .io_in_0_bits_meta_accessed               (arbIn_task[0].meta_accessed),
    .io_in_0_bits_meta_tagErr                 (arbIn_task[0].meta_tagErr),
    .io_in_0_bits_meta_dataErr                (arbIn_task[0].meta_dataErr),
    .io_in_0_bits_metaWen                     (arbIn_task[0].metaWen),
    .io_in_0_bits_tagWen                      (arbIn_task[0].tagWen),
    .io_in_0_bits_dsWen                       (arbIn_task[0].dsWen),
    .io_in_0_bits_wayMask                     (arbIn_task[0].wayMask),
    .io_in_0_bits_replTask                    (arbIn_task[0].replTask),
    .io_in_0_bits_cmoTask                     (arbIn_task[0].cmoTask),
    .io_in_0_bits_cmoAll                      (arbIn_task[0].cmoAll),
    .io_in_0_bits_reqSource                   (arbIn_task[0].reqSource),
    .io_in_0_bits_mergeA                      (arbIn_task[0].mergeA),
    .io_in_0_bits_aMergeTask_off              (arbIn_task[0].aMergeTask_off),
    .io_in_0_bits_aMergeTask_alias            (arbIn_task[0].aMergeTask_alias),
    .io_in_0_bits_aMergeTask_vaddr            (arbIn_task[0].aMergeTask_vaddr),
    .io_in_0_bits_aMergeTask_isKeyword        (arbIn_task[0].aMergeTask_isKeyword),
    .io_in_0_bits_aMergeTask_opcode           (arbIn_task[0].aMergeTask_opcode),
    .io_in_0_bits_aMergeTask_param            (arbIn_task[0].aMergeTask_param),
    .io_in_0_bits_aMergeTask_sourceId         (arbIn_task[0].aMergeTask_sourceId),
    .io_in_0_bits_aMergeTask_meta_dirty       (arbIn_task[0].aMergeTask_meta_dirty),
    .io_in_0_bits_aMergeTask_meta_state       (arbIn_task[0].aMergeTask_meta_state),
    .io_in_0_bits_aMergeTask_meta_clients     (arbIn_task[0].aMergeTask_meta_clients),
    .io_in_0_bits_aMergeTask_meta_alias       (arbIn_task[0].aMergeTask_meta_alias),
    .io_in_0_bits_aMergeTask_meta_prefetch    (arbIn_task[0].aMergeTask_meta_prefetch),
    .io_in_0_bits_aMergeTask_meta_prefetchSrc (arbIn_task[0].aMergeTask_meta_prefetchSrc),
    .io_in_0_bits_aMergeTask_meta_accessed    (arbIn_task[0].aMergeTask_meta_accessed),
    .io_in_0_bits_aMergeTask_meta_tagErr      (arbIn_task[0].aMergeTask_meta_tagErr),
    .io_in_0_bits_aMergeTask_meta_dataErr     (arbIn_task[0].aMergeTask_meta_dataErr),
    .io_in_0_bits_snpHitRelease               (arbIn_task[0].snpHitRelease),
    .io_in_0_bits_snpHitReleaseToInval        (arbIn_task[0].snpHitReleaseToInval),
    .io_in_0_bits_snpHitReleaseToClean        (arbIn_task[0].snpHitReleaseToClean),
    .io_in_0_bits_snpHitReleaseWithData       (arbIn_task[0].snpHitReleaseWithData),
    .io_in_0_bits_snpHitReleaseIdx            (arbIn_task[0].snpHitReleaseIdx),
    .io_in_0_bits_snpHitReleaseMeta_dirty     (arbIn_task[0].snpHitReleaseMeta_dirty),
    .io_in_0_bits_snpHitReleaseMeta_state     (arbIn_task[0].snpHitReleaseMeta_state),
    .io_in_0_bits_snpHitReleaseMeta_clients   (arbIn_task[0].snpHitReleaseMeta_clients),
    .io_in_0_bits_snpHitReleaseMeta_alias     (arbIn_task[0].snpHitReleaseMeta_alias),
    .io_in_0_bits_snpHitReleaseMeta_prefetch  (arbIn_task[0].snpHitReleaseMeta_prefetch),
    .io_in_0_bits_snpHitReleaseMeta_prefetchSrc (arbIn_task[0].snpHitReleaseMeta_prefetchSrc),
    .io_in_0_bits_snpHitReleaseMeta_accessed  (arbIn_task[0].snpHitReleaseMeta_accessed),
    .io_in_0_bits_snpHitReleaseMeta_tagErr    (arbIn_task[0].snpHitReleaseMeta_tagErr),
    .io_in_0_bits_snpHitReleaseMeta_dataErr   (arbIn_task[0].snpHitReleaseMeta_dataErr),
    .io_in_0_bits_tgtID                       (arbIn_task[0].tgtID),
    .io_in_0_bits_srcID                       (arbIn_task[0].srcID),
    .io_in_0_bits_txnID                       (arbIn_task[0].txnID),
    .io_in_0_bits_homeNID                     (arbIn_task[0].homeNID),
    .io_in_0_bits_dbID                        (arbIn_task[0].dbID),
    .io_in_0_bits_fwdNID                      (arbIn_task[0].fwdNID),
    .io_in_0_bits_fwdTxnID                    (arbIn_task[0].fwdTxnID),
    .io_in_0_bits_chiOpcode                   (arbIn_task[0].chiOpcode),
    .io_in_0_bits_resp                        (arbIn_task[0].resp),
    .io_in_0_bits_fwdState                    (arbIn_task[0].fwdState),
    .io_in_0_bits_pCrdType                    (arbIn_task[0].pCrdType),
    .io_in_0_bits_retToSrc                    (arbIn_task[0].retToSrc),
    .io_in_0_bits_likelyshared                (arbIn_task[0].likelyshared),
    .io_in_0_bits_expCompAck                  (arbIn_task[0].expCompAck),
    .io_in_0_bits_allowRetry                  (arbIn_task[0].allowRetry),
    .io_in_0_bits_memAttr_allocate            (arbIn_task[0].memAttr_allocate),
    .io_in_0_bits_memAttr_cacheable           (arbIn_task[0].memAttr_cacheable),
    .io_in_0_bits_memAttr_device              (arbIn_task[0].memAttr_device),
    .io_in_0_bits_memAttr_ewa                 (arbIn_task[0].memAttr_ewa),
    .io_in_0_bits_traceTag                    (arbIn_task[0].traceTag),
    .io_in_1_ready                            (arbIn_ready[1]),
    .io_in_1_valid                            (arbIn_valid[1]),
    .io_in_1_bits_channel                     (arbIn_task[1].channel),
    .io_in_1_bits_txChannel                   (arbIn_task[1].txChannel),
    .io_in_1_bits_set                         (arbIn_task[1].set),
    .io_in_1_bits_tag                         (arbIn_task[1].tag),
    .io_in_1_bits_off                         (arbIn_task[1].off),
    .io_in_1_bits_alias                       (arbIn_task[1].alias_),
    .io_in_1_bits_vaddr                       (arbIn_task[1].vaddr),
    .io_in_1_bits_isKeyword                   (arbIn_task[1].isKeyword),
    .io_in_1_bits_opcode                      (arbIn_task[1].opcode),
    .io_in_1_bits_param                       (arbIn_task[1].param),
    .io_in_1_bits_size                        (arbIn_task[1].size),
    .io_in_1_bits_sourceId                    (arbIn_task[1].sourceId),
    .io_in_1_bits_bufIdx                      (arbIn_task[1].bufIdx),
    .io_in_1_bits_needProbeAckData            (arbIn_task[1].needProbeAckData),
    .io_in_1_bits_denied                      (arbIn_task[1].denied),
    .io_in_1_bits_corrupt                     (arbIn_task[1].corrupt),
    .io_in_1_bits_mshrTask                    (arbIn_task[1].mshrTask),
    .io_in_1_bits_mshrId                      (arbIn_task[1].mshrId),
    .io_in_1_bits_aliasTask                   (arbIn_task[1].aliasTask),
    .io_in_1_bits_useProbeData                (arbIn_task[1].useProbeData),
    .io_in_1_bits_mshrRetry                   (arbIn_task[1].mshrRetry),
    .io_in_1_bits_readProbeDataDown           (arbIn_task[1].readProbeDataDown),
    .io_in_1_bits_fromL2pft                   (arbIn_task[1].fromL2pft),
    .io_in_1_bits_needHint                    (arbIn_task[1].needHint),
    .io_in_1_bits_dirty                       (arbIn_task[1].dirty),
    .io_in_1_bits_way                         (arbIn_task[1].way),
    .io_in_1_bits_meta_dirty                  (arbIn_task[1].meta_dirty),
    .io_in_1_bits_meta_state                  (arbIn_task[1].meta_state),
    .io_in_1_bits_meta_clients                (arbIn_task[1].meta_clients),
    .io_in_1_bits_meta_alias                  (arbIn_task[1].meta_alias),
    .io_in_1_bits_meta_prefetch               (arbIn_task[1].meta_prefetch),
    .io_in_1_bits_meta_prefetchSrc            (arbIn_task[1].meta_prefetchSrc),
    .io_in_1_bits_meta_accessed               (arbIn_task[1].meta_accessed),
    .io_in_1_bits_meta_tagErr                 (arbIn_task[1].meta_tagErr),
    .io_in_1_bits_meta_dataErr                (arbIn_task[1].meta_dataErr),
    .io_in_1_bits_metaWen                     (arbIn_task[1].metaWen),
    .io_in_1_bits_tagWen                      (arbIn_task[1].tagWen),
    .io_in_1_bits_dsWen                       (arbIn_task[1].dsWen),
    .io_in_1_bits_wayMask                     (arbIn_task[1].wayMask),
    .io_in_1_bits_replTask                    (arbIn_task[1].replTask),
    .io_in_1_bits_cmoTask                     (arbIn_task[1].cmoTask),
    .io_in_1_bits_cmoAll                      (arbIn_task[1].cmoAll),
    .io_in_1_bits_reqSource                   (arbIn_task[1].reqSource),
    .io_in_1_bits_mergeA                      (arbIn_task[1].mergeA),
    .io_in_1_bits_aMergeTask_off              (arbIn_task[1].aMergeTask_off),
    .io_in_1_bits_aMergeTask_alias            (arbIn_task[1].aMergeTask_alias),
    .io_in_1_bits_aMergeTask_vaddr            (arbIn_task[1].aMergeTask_vaddr),
    .io_in_1_bits_aMergeTask_isKeyword        (arbIn_task[1].aMergeTask_isKeyword),
    .io_in_1_bits_aMergeTask_opcode           (arbIn_task[1].aMergeTask_opcode),
    .io_in_1_bits_aMergeTask_param            (arbIn_task[1].aMergeTask_param),
    .io_in_1_bits_aMergeTask_sourceId         (arbIn_task[1].aMergeTask_sourceId),
    .io_in_1_bits_aMergeTask_meta_dirty       (arbIn_task[1].aMergeTask_meta_dirty),
    .io_in_1_bits_aMergeTask_meta_state       (arbIn_task[1].aMergeTask_meta_state),
    .io_in_1_bits_aMergeTask_meta_clients     (arbIn_task[1].aMergeTask_meta_clients),
    .io_in_1_bits_aMergeTask_meta_alias       (arbIn_task[1].aMergeTask_meta_alias),
    .io_in_1_bits_aMergeTask_meta_prefetch    (arbIn_task[1].aMergeTask_meta_prefetch),
    .io_in_1_bits_aMergeTask_meta_prefetchSrc (arbIn_task[1].aMergeTask_meta_prefetchSrc),
    .io_in_1_bits_aMergeTask_meta_accessed    (arbIn_task[1].aMergeTask_meta_accessed),
    .io_in_1_bits_aMergeTask_meta_tagErr      (arbIn_task[1].aMergeTask_meta_tagErr),
    .io_in_1_bits_aMergeTask_meta_dataErr     (arbIn_task[1].aMergeTask_meta_dataErr),
    .io_in_1_bits_snpHitRelease               (arbIn_task[1].snpHitRelease),
    .io_in_1_bits_snpHitReleaseToInval        (arbIn_task[1].snpHitReleaseToInval),
    .io_in_1_bits_snpHitReleaseToClean        (arbIn_task[1].snpHitReleaseToClean),
    .io_in_1_bits_snpHitReleaseWithData       (arbIn_task[1].snpHitReleaseWithData),
    .io_in_1_bits_snpHitReleaseIdx            (arbIn_task[1].snpHitReleaseIdx),
    .io_in_1_bits_snpHitReleaseMeta_dirty     (arbIn_task[1].snpHitReleaseMeta_dirty),
    .io_in_1_bits_snpHitReleaseMeta_state     (arbIn_task[1].snpHitReleaseMeta_state),
    .io_in_1_bits_snpHitReleaseMeta_clients   (arbIn_task[1].snpHitReleaseMeta_clients),
    .io_in_1_bits_snpHitReleaseMeta_alias     (arbIn_task[1].snpHitReleaseMeta_alias),
    .io_in_1_bits_snpHitReleaseMeta_prefetch  (arbIn_task[1].snpHitReleaseMeta_prefetch),
    .io_in_1_bits_snpHitReleaseMeta_prefetchSrc (arbIn_task[1].snpHitReleaseMeta_prefetchSrc),
    .io_in_1_bits_snpHitReleaseMeta_accessed  (arbIn_task[1].snpHitReleaseMeta_accessed),
    .io_in_1_bits_snpHitReleaseMeta_tagErr    (arbIn_task[1].snpHitReleaseMeta_tagErr),
    .io_in_1_bits_snpHitReleaseMeta_dataErr   (arbIn_task[1].snpHitReleaseMeta_dataErr),
    .io_in_1_bits_tgtID                       (arbIn_task[1].tgtID),
    .io_in_1_bits_srcID                       (arbIn_task[1].srcID),
    .io_in_1_bits_txnID                       (arbIn_task[1].txnID),
    .io_in_1_bits_homeNID                     (arbIn_task[1].homeNID),
    .io_in_1_bits_dbID                        (arbIn_task[1].dbID),
    .io_in_1_bits_fwdNID                      (arbIn_task[1].fwdNID),
    .io_in_1_bits_fwdTxnID                    (arbIn_task[1].fwdTxnID),
    .io_in_1_bits_chiOpcode                   (arbIn_task[1].chiOpcode),
    .io_in_1_bits_resp                        (arbIn_task[1].resp),
    .io_in_1_bits_fwdState                    (arbIn_task[1].fwdState),
    .io_in_1_bits_pCrdType                    (arbIn_task[1].pCrdType),
    .io_in_1_bits_retToSrc                    (arbIn_task[1].retToSrc),
    .io_in_1_bits_likelyshared                (arbIn_task[1].likelyshared),
    .io_in_1_bits_expCompAck                  (arbIn_task[1].expCompAck),
    .io_in_1_bits_allowRetry                  (arbIn_task[1].allowRetry),
    .io_in_1_bits_memAttr_allocate            (arbIn_task[1].memAttr_allocate),
    .io_in_1_bits_memAttr_cacheable           (arbIn_task[1].memAttr_cacheable),
    .io_in_1_bits_memAttr_device              (arbIn_task[1].memAttr_device),
    .io_in_1_bits_memAttr_ewa                 (arbIn_task[1].memAttr_ewa),
    .io_in_1_bits_traceTag                    (arbIn_task[1].traceTag),
    .io_in_2_ready                            (arbIn_ready[2]),
    .io_in_2_valid                            (arbIn_valid[2]),
    .io_in_2_bits_channel                     (arbIn_task[2].channel),
    .io_in_2_bits_txChannel                   (arbIn_task[2].txChannel),
    .io_in_2_bits_set                         (arbIn_task[2].set),
    .io_in_2_bits_tag                         (arbIn_task[2].tag),
    .io_in_2_bits_off                         (arbIn_task[2].off),
    .io_in_2_bits_alias                       (arbIn_task[2].alias_),
    .io_in_2_bits_vaddr                       (arbIn_task[2].vaddr),
    .io_in_2_bits_isKeyword                   (arbIn_task[2].isKeyword),
    .io_in_2_bits_opcode                      (arbIn_task[2].opcode),
    .io_in_2_bits_param                       (arbIn_task[2].param),
    .io_in_2_bits_size                        (arbIn_task[2].size),
    .io_in_2_bits_sourceId                    (arbIn_task[2].sourceId),
    .io_in_2_bits_bufIdx                      (arbIn_task[2].bufIdx),
    .io_in_2_bits_needProbeAckData            (arbIn_task[2].needProbeAckData),
    .io_in_2_bits_denied                      (arbIn_task[2].denied),
    .io_in_2_bits_corrupt                     (arbIn_task[2].corrupt),
    .io_in_2_bits_mshrTask                    (arbIn_task[2].mshrTask),
    .io_in_2_bits_mshrId                      (arbIn_task[2].mshrId),
    .io_in_2_bits_aliasTask                   (arbIn_task[2].aliasTask),
    .io_in_2_bits_useProbeData                (arbIn_task[2].useProbeData),
    .io_in_2_bits_mshrRetry                   (arbIn_task[2].mshrRetry),
    .io_in_2_bits_readProbeDataDown           (arbIn_task[2].readProbeDataDown),
    .io_in_2_bits_fromL2pft                   (arbIn_task[2].fromL2pft),
    .io_in_2_bits_needHint                    (arbIn_task[2].needHint),
    .io_in_2_bits_dirty                       (arbIn_task[2].dirty),
    .io_in_2_bits_way                         (arbIn_task[2].way),
    .io_in_2_bits_meta_dirty                  (arbIn_task[2].meta_dirty),
    .io_in_2_bits_meta_state                  (arbIn_task[2].meta_state),
    .io_in_2_bits_meta_clients                (arbIn_task[2].meta_clients),
    .io_in_2_bits_meta_alias                  (arbIn_task[2].meta_alias),
    .io_in_2_bits_meta_prefetch               (arbIn_task[2].meta_prefetch),
    .io_in_2_bits_meta_prefetchSrc            (arbIn_task[2].meta_prefetchSrc),
    .io_in_2_bits_meta_accessed               (arbIn_task[2].meta_accessed),
    .io_in_2_bits_meta_tagErr                 (arbIn_task[2].meta_tagErr),
    .io_in_2_bits_meta_dataErr                (arbIn_task[2].meta_dataErr),
    .io_in_2_bits_metaWen                     (arbIn_task[2].metaWen),
    .io_in_2_bits_tagWen                      (arbIn_task[2].tagWen),
    .io_in_2_bits_dsWen                       (arbIn_task[2].dsWen),
    .io_in_2_bits_wayMask                     (arbIn_task[2].wayMask),
    .io_in_2_bits_replTask                    (arbIn_task[2].replTask),
    .io_in_2_bits_cmoTask                     (arbIn_task[2].cmoTask),
    .io_in_2_bits_cmoAll                      (arbIn_task[2].cmoAll),
    .io_in_2_bits_reqSource                   (arbIn_task[2].reqSource),
    .io_in_2_bits_mergeA                      (arbIn_task[2].mergeA),
    .io_in_2_bits_aMergeTask_off              (arbIn_task[2].aMergeTask_off),
    .io_in_2_bits_aMergeTask_alias            (arbIn_task[2].aMergeTask_alias),
    .io_in_2_bits_aMergeTask_vaddr            (arbIn_task[2].aMergeTask_vaddr),
    .io_in_2_bits_aMergeTask_isKeyword        (arbIn_task[2].aMergeTask_isKeyword),
    .io_in_2_bits_aMergeTask_opcode           (arbIn_task[2].aMergeTask_opcode),
    .io_in_2_bits_aMergeTask_param            (arbIn_task[2].aMergeTask_param),
    .io_in_2_bits_aMergeTask_sourceId         (arbIn_task[2].aMergeTask_sourceId),
    .io_in_2_bits_aMergeTask_meta_dirty       (arbIn_task[2].aMergeTask_meta_dirty),
    .io_in_2_bits_aMergeTask_meta_state       (arbIn_task[2].aMergeTask_meta_state),
    .io_in_2_bits_aMergeTask_meta_clients     (arbIn_task[2].aMergeTask_meta_clients),
    .io_in_2_bits_aMergeTask_meta_alias       (arbIn_task[2].aMergeTask_meta_alias),
    .io_in_2_bits_aMergeTask_meta_prefetch    (arbIn_task[2].aMergeTask_meta_prefetch),
    .io_in_2_bits_aMergeTask_meta_prefetchSrc (arbIn_task[2].aMergeTask_meta_prefetchSrc),
    .io_in_2_bits_aMergeTask_meta_accessed    (arbIn_task[2].aMergeTask_meta_accessed),
    .io_in_2_bits_aMergeTask_meta_tagErr      (arbIn_task[2].aMergeTask_meta_tagErr),
    .io_in_2_bits_aMergeTask_meta_dataErr     (arbIn_task[2].aMergeTask_meta_dataErr),
    .io_in_2_bits_snpHitRelease               (arbIn_task[2].snpHitRelease),
    .io_in_2_bits_snpHitReleaseToInval        (arbIn_task[2].snpHitReleaseToInval),
    .io_in_2_bits_snpHitReleaseToClean        (arbIn_task[2].snpHitReleaseToClean),
    .io_in_2_bits_snpHitReleaseWithData       (arbIn_task[2].snpHitReleaseWithData),
    .io_in_2_bits_snpHitReleaseIdx            (arbIn_task[2].snpHitReleaseIdx),
    .io_in_2_bits_snpHitReleaseMeta_dirty     (arbIn_task[2].snpHitReleaseMeta_dirty),
    .io_in_2_bits_snpHitReleaseMeta_state     (arbIn_task[2].snpHitReleaseMeta_state),
    .io_in_2_bits_snpHitReleaseMeta_clients   (arbIn_task[2].snpHitReleaseMeta_clients),
    .io_in_2_bits_snpHitReleaseMeta_alias     (arbIn_task[2].snpHitReleaseMeta_alias),
    .io_in_2_bits_snpHitReleaseMeta_prefetch  (arbIn_task[2].snpHitReleaseMeta_prefetch),
    .io_in_2_bits_snpHitReleaseMeta_prefetchSrc (arbIn_task[2].snpHitReleaseMeta_prefetchSrc),
    .io_in_2_bits_snpHitReleaseMeta_accessed  (arbIn_task[2].snpHitReleaseMeta_accessed),
    .io_in_2_bits_snpHitReleaseMeta_tagErr    (arbIn_task[2].snpHitReleaseMeta_tagErr),
    .io_in_2_bits_snpHitReleaseMeta_dataErr   (arbIn_task[2].snpHitReleaseMeta_dataErr),
    .io_in_2_bits_tgtID                       (arbIn_task[2].tgtID),
    .io_in_2_bits_srcID                       (arbIn_task[2].srcID),
    .io_in_2_bits_txnID                       (arbIn_task[2].txnID),
    .io_in_2_bits_homeNID                     (arbIn_task[2].homeNID),
    .io_in_2_bits_dbID                        (arbIn_task[2].dbID),
    .io_in_2_bits_fwdNID                      (arbIn_task[2].fwdNID),
    .io_in_2_bits_fwdTxnID                    (arbIn_task[2].fwdTxnID),
    .io_in_2_bits_chiOpcode                   (arbIn_task[2].chiOpcode),
    .io_in_2_bits_resp                        (arbIn_task[2].resp),
    .io_in_2_bits_fwdState                    (arbIn_task[2].fwdState),
    .io_in_2_bits_pCrdType                    (arbIn_task[2].pCrdType),
    .io_in_2_bits_retToSrc                    (arbIn_task[2].retToSrc),
    .io_in_2_bits_likelyshared                (arbIn_task[2].likelyshared),
    .io_in_2_bits_expCompAck                  (arbIn_task[2].expCompAck),
    .io_in_2_bits_allowRetry                  (arbIn_task[2].allowRetry),
    .io_in_2_bits_memAttr_allocate            (arbIn_task[2].memAttr_allocate),
    .io_in_2_bits_memAttr_cacheable           (arbIn_task[2].memAttr_cacheable),
    .io_in_2_bits_memAttr_device              (arbIn_task[2].memAttr_device),
    .io_in_2_bits_memAttr_ewa                 (arbIn_task[2].memAttr_ewa),
    .io_in_2_bits_traceTag                    (arbIn_task[2].traceTag),
    .io_in_3_ready                            (arbIn_ready[3]),
    .io_in_3_valid                            (arbIn_valid[3]),
    .io_in_3_bits_channel                     (arbIn_task[3].channel),
    .io_in_3_bits_txChannel                   (arbIn_task[3].txChannel),
    .io_in_3_bits_set                         (arbIn_task[3].set),
    .io_in_3_bits_tag                         (arbIn_task[3].tag),
    .io_in_3_bits_off                         (arbIn_task[3].off),
    .io_in_3_bits_alias                       (arbIn_task[3].alias_),
    .io_in_3_bits_vaddr                       (arbIn_task[3].vaddr),
    .io_in_3_bits_isKeyword                   (arbIn_task[3].isKeyword),
    .io_in_3_bits_opcode                      (arbIn_task[3].opcode),
    .io_in_3_bits_param                       (arbIn_task[3].param),
    .io_in_3_bits_size                        (arbIn_task[3].size),
    .io_in_3_bits_sourceId                    (arbIn_task[3].sourceId),
    .io_in_3_bits_bufIdx                      (arbIn_task[3].bufIdx),
    .io_in_3_bits_needProbeAckData            (arbIn_task[3].needProbeAckData),
    .io_in_3_bits_denied                      (arbIn_task[3].denied),
    .io_in_3_bits_corrupt                     (arbIn_task[3].corrupt),
    .io_in_3_bits_mshrTask                    (arbIn_task[3].mshrTask),
    .io_in_3_bits_mshrId                      (arbIn_task[3].mshrId),
    .io_in_3_bits_aliasTask                   (arbIn_task[3].aliasTask),
    .io_in_3_bits_useProbeData                (arbIn_task[3].useProbeData),
    .io_in_3_bits_mshrRetry                   (arbIn_task[3].mshrRetry),
    .io_in_3_bits_readProbeDataDown           (arbIn_task[3].readProbeDataDown),
    .io_in_3_bits_fromL2pft                   (arbIn_task[3].fromL2pft),
    .io_in_3_bits_needHint                    (arbIn_task[3].needHint),
    .io_in_3_bits_dirty                       (arbIn_task[3].dirty),
    .io_in_3_bits_way                         (arbIn_task[3].way),
    .io_in_3_bits_meta_dirty                  (arbIn_task[3].meta_dirty),
    .io_in_3_bits_meta_state                  (arbIn_task[3].meta_state),
    .io_in_3_bits_meta_clients                (arbIn_task[3].meta_clients),
    .io_in_3_bits_meta_alias                  (arbIn_task[3].meta_alias),
    .io_in_3_bits_meta_prefetch               (arbIn_task[3].meta_prefetch),
    .io_in_3_bits_meta_prefetchSrc            (arbIn_task[3].meta_prefetchSrc),
    .io_in_3_bits_meta_accessed               (arbIn_task[3].meta_accessed),
    .io_in_3_bits_meta_tagErr                 (arbIn_task[3].meta_tagErr),
    .io_in_3_bits_meta_dataErr                (arbIn_task[3].meta_dataErr),
    .io_in_3_bits_metaWen                     (arbIn_task[3].metaWen),
    .io_in_3_bits_tagWen                      (arbIn_task[3].tagWen),
    .io_in_3_bits_dsWen                       (arbIn_task[3].dsWen),
    .io_in_3_bits_wayMask                     (arbIn_task[3].wayMask),
    .io_in_3_bits_replTask                    (arbIn_task[3].replTask),
    .io_in_3_bits_cmoTask                     (arbIn_task[3].cmoTask),
    .io_in_3_bits_cmoAll                      (arbIn_task[3].cmoAll),
    .io_in_3_bits_reqSource                   (arbIn_task[3].reqSource),
    .io_in_3_bits_mergeA                      (arbIn_task[3].mergeA),
    .io_in_3_bits_aMergeTask_off              (arbIn_task[3].aMergeTask_off),
    .io_in_3_bits_aMergeTask_alias            (arbIn_task[3].aMergeTask_alias),
    .io_in_3_bits_aMergeTask_vaddr            (arbIn_task[3].aMergeTask_vaddr),
    .io_in_3_bits_aMergeTask_isKeyword        (arbIn_task[3].aMergeTask_isKeyword),
    .io_in_3_bits_aMergeTask_opcode           (arbIn_task[3].aMergeTask_opcode),
    .io_in_3_bits_aMergeTask_param            (arbIn_task[3].aMergeTask_param),
    .io_in_3_bits_aMergeTask_sourceId         (arbIn_task[3].aMergeTask_sourceId),
    .io_in_3_bits_aMergeTask_meta_dirty       (arbIn_task[3].aMergeTask_meta_dirty),
    .io_in_3_bits_aMergeTask_meta_state       (arbIn_task[3].aMergeTask_meta_state),
    .io_in_3_bits_aMergeTask_meta_clients     (arbIn_task[3].aMergeTask_meta_clients),
    .io_in_3_bits_aMergeTask_meta_alias       (arbIn_task[3].aMergeTask_meta_alias),
    .io_in_3_bits_aMergeTask_meta_prefetch    (arbIn_task[3].aMergeTask_meta_prefetch),
    .io_in_3_bits_aMergeTask_meta_prefetchSrc (arbIn_task[3].aMergeTask_meta_prefetchSrc),
    .io_in_3_bits_aMergeTask_meta_accessed    (arbIn_task[3].aMergeTask_meta_accessed),
    .io_in_3_bits_aMergeTask_meta_tagErr      (arbIn_task[3].aMergeTask_meta_tagErr),
    .io_in_3_bits_aMergeTask_meta_dataErr     (arbIn_task[3].aMergeTask_meta_dataErr),
    .io_in_3_bits_snpHitRelease               (arbIn_task[3].snpHitRelease),
    .io_in_3_bits_snpHitReleaseToInval        (arbIn_task[3].snpHitReleaseToInval),
    .io_in_3_bits_snpHitReleaseToClean        (arbIn_task[3].snpHitReleaseToClean),
    .io_in_3_bits_snpHitReleaseWithData       (arbIn_task[3].snpHitReleaseWithData),
    .io_in_3_bits_snpHitReleaseIdx            (arbIn_task[3].snpHitReleaseIdx),
    .io_in_3_bits_snpHitReleaseMeta_dirty     (arbIn_task[3].snpHitReleaseMeta_dirty),
    .io_in_3_bits_snpHitReleaseMeta_state     (arbIn_task[3].snpHitReleaseMeta_state),
    .io_in_3_bits_snpHitReleaseMeta_clients   (arbIn_task[3].snpHitReleaseMeta_clients),
    .io_in_3_bits_snpHitReleaseMeta_alias     (arbIn_task[3].snpHitReleaseMeta_alias),
    .io_in_3_bits_snpHitReleaseMeta_prefetch  (arbIn_task[3].snpHitReleaseMeta_prefetch),
    .io_in_3_bits_snpHitReleaseMeta_prefetchSrc (arbIn_task[3].snpHitReleaseMeta_prefetchSrc),
    .io_in_3_bits_snpHitReleaseMeta_accessed  (arbIn_task[3].snpHitReleaseMeta_accessed),
    .io_in_3_bits_snpHitReleaseMeta_tagErr    (arbIn_task[3].snpHitReleaseMeta_tagErr),
    .io_in_3_bits_snpHitReleaseMeta_dataErr   (arbIn_task[3].snpHitReleaseMeta_dataErr),
    .io_in_3_bits_tgtID                       (arbIn_task[3].tgtID),
    .io_in_3_bits_srcID                       (arbIn_task[3].srcID),
    .io_in_3_bits_txnID                       (arbIn_task[3].txnID),
    .io_in_3_bits_homeNID                     (arbIn_task[3].homeNID),
    .io_in_3_bits_dbID                        (arbIn_task[3].dbID),
    .io_in_3_bits_fwdNID                      (arbIn_task[3].fwdNID),
    .io_in_3_bits_fwdTxnID                    (arbIn_task[3].fwdTxnID),
    .io_in_3_bits_chiOpcode                   (arbIn_task[3].chiOpcode),
    .io_in_3_bits_resp                        (arbIn_task[3].resp),
    .io_in_3_bits_fwdState                    (arbIn_task[3].fwdState),
    .io_in_3_bits_pCrdType                    (arbIn_task[3].pCrdType),
    .io_in_3_bits_retToSrc                    (arbIn_task[3].retToSrc),
    .io_in_3_bits_likelyshared                (arbIn_task[3].likelyshared),
    .io_in_3_bits_expCompAck                  (arbIn_task[3].expCompAck),
    .io_in_3_bits_allowRetry                  (arbIn_task[3].allowRetry),
    .io_in_3_bits_memAttr_allocate            (arbIn_task[3].memAttr_allocate),
    .io_in_3_bits_memAttr_cacheable           (arbIn_task[3].memAttr_cacheable),
    .io_in_3_bits_memAttr_device              (arbIn_task[3].memAttr_device),
    .io_in_3_bits_memAttr_ewa                 (arbIn_task[3].memAttr_ewa),
    .io_in_3_bits_traceTag                    (arbIn_task[3].traceTag),
    .io_out_ready                             (io_task_ready),
    .io_out_valid                             (io_task_valid),
    .io_out_bits_channel                      (io_task_bits_channel),
    .io_out_bits_txChannel                    (io_task_bits_txChannel),
    .io_out_bits_set                          (io_task_bits_set),
    .io_out_bits_tag                          (io_task_bits_tag),
    .io_out_bits_off                          (io_task_bits_off),
    .io_out_bits_alias                        (io_task_bits_alias),
    .io_out_bits_vaddr                        (io_task_bits_vaddr),
    .io_out_bits_isKeyword                    (io_task_bits_isKeyword),
    .io_out_bits_opcode                       (io_task_bits_opcode),
    .io_out_bits_param                        (io_task_bits_param),
    .io_out_bits_size                         (io_task_bits_size),
    .io_out_bits_sourceId                     (io_task_bits_sourceId),
    .io_out_bits_bufIdx                       (io_task_bits_bufIdx),
    .io_out_bits_needProbeAckData             (io_task_bits_needProbeAckData),
    .io_out_bits_denied                       (io_task_bits_denied),
    .io_out_bits_corrupt                      (io_task_bits_corrupt),
    .io_out_bits_mshrTask                     (io_task_bits_mshrTask),
    .io_out_bits_mshrId                       (io_task_bits_mshrId),
    .io_out_bits_aliasTask                    (io_task_bits_aliasTask),
    .io_out_bits_useProbeData                 (io_task_bits_useProbeData),
    .io_out_bits_mshrRetry                    (io_task_bits_mshrRetry),
    .io_out_bits_readProbeDataDown            (io_task_bits_readProbeDataDown),
    .io_out_bits_fromL2pft                    (io_task_bits_fromL2pft),
    .io_out_bits_needHint                     (io_task_bits_needHint),
    .io_out_bits_dirty                        (io_task_bits_dirty),
    .io_out_bits_way                          (io_task_bits_way),
    .io_out_bits_meta_dirty                   (io_task_bits_meta_dirty),
    .io_out_bits_meta_state                   (io_task_bits_meta_state),
    .io_out_bits_meta_clients                 (io_task_bits_meta_clients),
    .io_out_bits_meta_alias                   (io_task_bits_meta_alias),
    .io_out_bits_meta_prefetch                (io_task_bits_meta_prefetch),
    .io_out_bits_meta_prefetchSrc             (io_task_bits_meta_prefetchSrc),
    .io_out_bits_meta_accessed                (io_task_bits_meta_accessed),
    .io_out_bits_meta_tagErr                  (io_task_bits_meta_tagErr),
    .io_out_bits_meta_dataErr                 (io_task_bits_meta_dataErr),
    .io_out_bits_metaWen                      (io_task_bits_metaWen),
    .io_out_bits_tagWen                       (io_task_bits_tagWen),
    .io_out_bits_dsWen                        (io_task_bits_dsWen),
    .io_out_bits_wayMask                      (io_task_bits_wayMask),
    .io_out_bits_replTask                     (io_task_bits_replTask),
    .io_out_bits_cmoTask                      (io_task_bits_cmoTask),
    .io_out_bits_cmoAll                       (io_task_bits_cmoAll),
    .io_out_bits_reqSource                    (io_task_bits_reqSource),
    .io_out_bits_mergeA                       (io_task_bits_mergeA),
    .io_out_bits_aMergeTask_off               (io_task_bits_aMergeTask_off),
    .io_out_bits_aMergeTask_alias             (io_task_bits_aMergeTask_alias),
    .io_out_bits_aMergeTask_vaddr             (io_task_bits_aMergeTask_vaddr),
    .io_out_bits_aMergeTask_isKeyword         (io_task_bits_aMergeTask_isKeyword),
    .io_out_bits_aMergeTask_opcode            (io_task_bits_aMergeTask_opcode),
    .io_out_bits_aMergeTask_param             (io_task_bits_aMergeTask_param),
    .io_out_bits_aMergeTask_sourceId          (io_task_bits_aMergeTask_sourceId),
    .io_out_bits_aMergeTask_meta_dirty        (io_task_bits_aMergeTask_meta_dirty),
    .io_out_bits_aMergeTask_meta_state        (io_task_bits_aMergeTask_meta_state),
    .io_out_bits_aMergeTask_meta_clients      (io_task_bits_aMergeTask_meta_clients),
    .io_out_bits_aMergeTask_meta_alias        (io_task_bits_aMergeTask_meta_alias),
    .io_out_bits_aMergeTask_meta_prefetch     (io_task_bits_aMergeTask_meta_prefetch),
    .io_out_bits_aMergeTask_meta_prefetchSrc  (io_task_bits_aMergeTask_meta_prefetchSrc),
    .io_out_bits_aMergeTask_meta_accessed     (io_task_bits_aMergeTask_meta_accessed),
    .io_out_bits_aMergeTask_meta_tagErr       (io_task_bits_aMergeTask_meta_tagErr),
    .io_out_bits_aMergeTask_meta_dataErr      (io_task_bits_aMergeTask_meta_dataErr),
    .io_out_bits_snpHitRelease                (io_task_bits_snpHitRelease),
    .io_out_bits_snpHitReleaseToInval         (io_task_bits_snpHitReleaseToInval),
    .io_out_bits_snpHitReleaseToClean         (io_task_bits_snpHitReleaseToClean),
    .io_out_bits_snpHitReleaseWithData        (io_task_bits_snpHitReleaseWithData),
    .io_out_bits_snpHitReleaseIdx             (io_task_bits_snpHitReleaseIdx),
    .io_out_bits_snpHitReleaseMeta_dirty      (io_task_bits_snpHitReleaseMeta_dirty),
    .io_out_bits_snpHitReleaseMeta_state      (io_task_bits_snpHitReleaseMeta_state),
    .io_out_bits_snpHitReleaseMeta_clients    (io_task_bits_snpHitReleaseMeta_clients),
    .io_out_bits_snpHitReleaseMeta_alias      (io_task_bits_snpHitReleaseMeta_alias),
    .io_out_bits_snpHitReleaseMeta_prefetch   (io_task_bits_snpHitReleaseMeta_prefetch),
    .io_out_bits_snpHitReleaseMeta_prefetchSrc (io_task_bits_snpHitReleaseMeta_prefetchSrc),
    .io_out_bits_snpHitReleaseMeta_accessed   (io_task_bits_snpHitReleaseMeta_accessed),
    .io_out_bits_snpHitReleaseMeta_tagErr     (io_task_bits_snpHitReleaseMeta_tagErr),
    .io_out_bits_snpHitReleaseMeta_dataErr    (io_task_bits_snpHitReleaseMeta_dataErr),
    .io_out_bits_tgtID                        (io_task_bits_tgtID),
    .io_out_bits_srcID                        (io_task_bits_srcID),
    .io_out_bits_txnID                        (io_task_bits_txnID),
    .io_out_bits_homeNID                      (io_task_bits_homeNID),
    .io_out_bits_dbID                         (io_task_bits_dbID),
    .io_out_bits_fwdNID                       (io_task_bits_fwdNID),
    .io_out_bits_fwdTxnID                     (io_task_bits_fwdTxnID),
    .io_out_bits_chiOpcode                    (io_task_bits_chiOpcode),
    .io_out_bits_resp                         (io_task_bits_resp),
    .io_out_bits_fwdState                     (io_task_bits_fwdState),
    .io_out_bits_pCrdType                     (io_task_bits_pCrdType),
    .io_out_bits_retToSrc                     (io_task_bits_retToSrc),
    .io_out_bits_likelyshared                 (io_task_bits_likelyshared),
    .io_out_bits_expCompAck                   (io_task_bits_expCompAck),
    .io_out_bits_allowRetry                   (io_task_bits_allowRetry),
    .io_out_bits_memAttr_allocate             (io_task_bits_memAttr_allocate),
    .io_out_bits_memAttr_cacheable            (io_task_bits_memAttr_cacheable),
    .io_out_bits_memAttr_device               (io_task_bits_memAttr_device),
    .io_out_bits_memAttr_ewa                  (io_task_bits_memAttr_ewa),
    .io_out_bits_traceTag                     (io_task_bits_traceTag)
  );

endmodule
// END GENERATED(wrapper)
