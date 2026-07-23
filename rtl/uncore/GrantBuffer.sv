// 自动生成 scripts/gen_grantbuffer.py —— 勿手改
// =============================================================================
//  GrantBuffer —— coupledL2 (tl2chi) L2 slice D/E(授权/确认) 路径 可读重写核
//          (xs_GrantBuffer_core)
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/src/main/scala/coupledL2/GrantBuffer.scala
//  4 个 FIFO(grantQueue/grantQueueData0/1/pftRespQueue) 为黑盒, 在 golden 同名
//  wrapper 内例化; 本核做入队组装、出队组 TLBundleD、inflightGrant FSM、容量反压。
//  ===== X 铁律 =====
//    inflightGrant[16]/grantBuf 异步复位清 0 门控所有读出; e.sink/insertIdx 恒在 [0,15]。
// =============================================================================
module xs_GrantBuffer_core
  import l2_task_pkg::*;
(
  input  logic        clock,
  input  logic        reset,
  // ---- io.d_task (Flipped Decoupled TaskWithData; data 直接进数据 FIFO, 不入核) ----
  input  logic        io_d_task_valid,
  input  logic [2:0]  io_d_task_bits_task_channel,
  input  logic [2:0]  io_d_task_bits_task_txChannel,
  input  logic [8:0]  io_d_task_bits_task_set,
  input  logic [30:0] io_d_task_bits_task_tag,
  input  logic [5:0]  io_d_task_bits_task_off,
  input  logic [1:0]  io_d_task_bits_task_alias,
  input  logic [43:0] io_d_task_bits_task_vaddr,
  input  logic        io_d_task_bits_task_isKeyword,
  input  logic [3:0]  io_d_task_bits_task_opcode,
  input  logic [2:0]  io_d_task_bits_task_param,
  input  logic [2:0]  io_d_task_bits_task_size,
  input  logic [6:0]  io_d_task_bits_task_sourceId,
  input  logic [1:0]  io_d_task_bits_task_bufIdx,
  input  logic        io_d_task_bits_task_needProbeAckData,
  input  logic        io_d_task_bits_task_denied,
  input  logic        io_d_task_bits_task_corrupt,
  input  logic        io_d_task_bits_task_mshrTask,
  input  logic [7:0]  io_d_task_bits_task_mshrId,
  input  logic        io_d_task_bits_task_aliasTask,
  input  logic        io_d_task_bits_task_useProbeData,
  input  logic        io_d_task_bits_task_mshrRetry,
  input  logic        io_d_task_bits_task_readProbeDataDown,
  input  logic        io_d_task_bits_task_fromL2pft,
  input  logic        io_d_task_bits_task_needHint,
  input  logic        io_d_task_bits_task_dirty,
  input  logic [2:0]  io_d_task_bits_task_way,
  input  logic        io_d_task_bits_task_meta_dirty,
  input  logic [1:0]  io_d_task_bits_task_meta_state,
  input  logic        io_d_task_bits_task_meta_clients,
  input  logic [1:0]  io_d_task_bits_task_meta_alias,
  input  logic        io_d_task_bits_task_meta_prefetch,
  input  logic [2:0]  io_d_task_bits_task_meta_prefetchSrc,
  input  logic        io_d_task_bits_task_meta_accessed,
  input  logic        io_d_task_bits_task_meta_tagErr,
  input  logic        io_d_task_bits_task_meta_dataErr,
  input  logic        io_d_task_bits_task_metaWen,
  input  logic        io_d_task_bits_task_tagWen,
  input  logic        io_d_task_bits_task_dsWen,
  input  logic [7:0]  io_d_task_bits_task_wayMask,
  input  logic        io_d_task_bits_task_replTask,
  input  logic        io_d_task_bits_task_cmoTask,
  input  logic        io_d_task_bits_task_cmoAll,
  input  logic [4:0]  io_d_task_bits_task_reqSource,
  input  logic        io_d_task_bits_task_mergeA,
  input  logic [5:0]  io_d_task_bits_task_aMergeTask_off,
  input  logic [1:0]  io_d_task_bits_task_aMergeTask_alias,
  input  logic [43:0] io_d_task_bits_task_aMergeTask_vaddr,
  input  logic        io_d_task_bits_task_aMergeTask_isKeyword,
  input  logic [2:0]  io_d_task_bits_task_aMergeTask_opcode,
  input  logic [2:0]  io_d_task_bits_task_aMergeTask_param,
  input  logic [6:0]  io_d_task_bits_task_aMergeTask_sourceId,
  input  logic        io_d_task_bits_task_aMergeTask_meta_dirty,
  input  logic [1:0]  io_d_task_bits_task_aMergeTask_meta_state,
  input  logic        io_d_task_bits_task_aMergeTask_meta_clients,
  input  logic [1:0]  io_d_task_bits_task_aMergeTask_meta_alias,
  input  logic        io_d_task_bits_task_aMergeTask_meta_prefetch,
  input  logic [2:0]  io_d_task_bits_task_aMergeTask_meta_prefetchSrc,
  input  logic        io_d_task_bits_task_aMergeTask_meta_accessed,
  input  logic        io_d_task_bits_task_aMergeTask_meta_tagErr,
  input  logic        io_d_task_bits_task_aMergeTask_meta_dataErr,
  input  logic        io_d_task_bits_task_snpHitRelease,
  input  logic        io_d_task_bits_task_snpHitReleaseToInval,
  input  logic        io_d_task_bits_task_snpHitReleaseToClean,
  input  logic        io_d_task_bits_task_snpHitReleaseWithData,
  input  logic [7:0]  io_d_task_bits_task_snpHitReleaseIdx,
  input  logic        io_d_task_bits_task_snpHitReleaseMeta_dirty,
  input  logic [1:0]  io_d_task_bits_task_snpHitReleaseMeta_state,
  input  logic        io_d_task_bits_task_snpHitReleaseMeta_clients,
  input  logic [1:0]  io_d_task_bits_task_snpHitReleaseMeta_alias,
  input  logic        io_d_task_bits_task_snpHitReleaseMeta_prefetch,
  input  logic [2:0]  io_d_task_bits_task_snpHitReleaseMeta_prefetchSrc,
  input  logic        io_d_task_bits_task_snpHitReleaseMeta_accessed,
  input  logic        io_d_task_bits_task_snpHitReleaseMeta_tagErr,
  input  logic        io_d_task_bits_task_snpHitReleaseMeta_dataErr,
  input  logic [10:0] io_d_task_bits_task_tgtID,
  input  logic [10:0] io_d_task_bits_task_srcID,
  input  logic [11:0] io_d_task_bits_task_txnID,
  input  logic [10:0] io_d_task_bits_task_homeNID,
  input  logic [11:0] io_d_task_bits_task_dbID,
  input  logic [10:0] io_d_task_bits_task_fwdNID,
  input  logic [11:0] io_d_task_bits_task_fwdTxnID,
  input  logic [6:0]  io_d_task_bits_task_chiOpcode,
  input  logic [2:0]  io_d_task_bits_task_resp,
  input  logic [2:0]  io_d_task_bits_task_fwdState,
  input  logic [3:0]  io_d_task_bits_task_pCrdType,
  input  logic        io_d_task_bits_task_retToSrc,
  input  logic        io_d_task_bits_task_likelyshared,
  input  logic        io_d_task_bits_task_expCompAck,
  input  logic        io_d_task_bits_task_allowRetry,
  input  logic        io_d_task_bits_task_memAttr_allocate,
  input  logic        io_d_task_bits_task_memAttr_cacheable,
  input  logic        io_d_task_bits_task_memAttr_device,
  input  logic        io_d_task_bits_task_memAttr_ewa,
  input  logic        io_d_task_bits_task_traceTag,
  input  logic        io_d_task_bits_task_dataCheckErr,
  // ---- io.d (Decoupled TLBundleD 发往 L1) ----
  input  logic        io_d_ready,
  output logic        io_d_valid,
  output logic [3:0]  io_d_bits_opcode,
  output logic [1:0]  io_d_bits_param,
  output logic [6:0]  io_d_bits_source,
  output logic [7:0]  io_d_bits_sink,
  output logic        io_d_bits_denied,
  output logic        io_d_bits_echo_isKeyword,
  output logic [255:0] io_d_bits_data,
  output logic        io_d_bits_corrupt,
  // ---- io.e (Flipped Decoupled TLBundleE, GrantAck) ----
  input  logic        io_e_valid,
  input  logic [7:0]  io_e_bits_sink,
  // ---- 反压所需: ReqArb s1 状态 + 流水级占用 ----
  input  logic [30:0] io_fromReqArb_status_s1_tags_1,
  input  logic [8:0]  io_fromReqArb_status_s1_sets_1,
  input  logic        io_pipeStatusVec_1_valid,
  input  logic [2:0]  io_pipeStatusVec_1_bits_channel,
  input  logic        io_pipeStatusVec_2_valid,
  input  logic [2:0]  io_pipeStatusVec_2_bits_channel,
  input  logic        io_pipeStatusVec_3_valid,
  input  logic [2:0]  io_pipeStatusVec_3_bits_channel,
  input  logic        io_pipeStatusVec_4_valid,
  input  logic [2:0]  io_pipeStatusVec_4_bits_channel,
  output logic        io_toReqArb_blockSinkReqEntrance_blockA_s1,
  output logic        io_toReqArb_blockSinkReqEntrance_blockB_s1,
  output logic        io_toReqArb_blockSinkReqEntrance_blockC_s1,
  output logic        io_toReqArb_blockMSHRReqEntrance,
  // ---- io.grantStatus[16] (=inflightGrant, 供 SourceB 阻塞同址 Probe) ----
  output logic        io_grantStatus_0_valid,
  output logic [8:0]  io_grantStatus_0_set,
  output logic [30:0] io_grantStatus_0_tag,
  output logic        io_grantStatus_1_valid,
  output logic [8:0]  io_grantStatus_1_set,
  output logic [30:0] io_grantStatus_1_tag,
  output logic        io_grantStatus_2_valid,
  output logic [8:0]  io_grantStatus_2_set,
  output logic [30:0] io_grantStatus_2_tag,
  output logic        io_grantStatus_3_valid,
  output logic [8:0]  io_grantStatus_3_set,
  output logic [30:0] io_grantStatus_3_tag,
  output logic        io_grantStatus_4_valid,
  output logic [8:0]  io_grantStatus_4_set,
  output logic [30:0] io_grantStatus_4_tag,
  output logic        io_grantStatus_5_valid,
  output logic [8:0]  io_grantStatus_5_set,
  output logic [30:0] io_grantStatus_5_tag,
  output logic        io_grantStatus_6_valid,
  output logic [8:0]  io_grantStatus_6_set,
  output logic [30:0] io_grantStatus_6_tag,
  output logic        io_grantStatus_7_valid,
  output logic [8:0]  io_grantStatus_7_set,
  output logic [30:0] io_grantStatus_7_tag,
  output logic        io_grantStatus_8_valid,
  output logic [8:0]  io_grantStatus_8_set,
  output logic [30:0] io_grantStatus_8_tag,
  output logic        io_grantStatus_9_valid,
  output logic [8:0]  io_grantStatus_9_set,
  output logic [30:0] io_grantStatus_9_tag,
  output logic        io_grantStatus_10_valid,
  output logic [8:0]  io_grantStatus_10_set,
  output logic [30:0] io_grantStatus_10_tag,
  output logic        io_grantStatus_11_valid,
  output logic [8:0]  io_grantStatus_11_set,
  output logic [30:0] io_grantStatus_11_tag,
  output logic        io_grantStatus_12_valid,
  output logic [8:0]  io_grantStatus_12_set,
  output logic [30:0] io_grantStatus_12_tag,
  output logic        io_grantStatus_13_valid,
  output logic [8:0]  io_grantStatus_13_set,
  output logic [30:0] io_grantStatus_13_tag,
  output logic        io_grantStatus_14_valid,
  output logic [8:0]  io_grantStatus_14_set,
  output logic [30:0] io_grantStatus_14_tag,
  output logic        io_grantStatus_15_valid,
  output logic [8:0]  io_grantStatus_15_set,
  output logic [30:0] io_grantStatus_15_tag,
  // ---- 与 grantQueue(Queue16_GrantQueueTask) 黑盒对接 ----
  output l2_task_pkg::task_bundle_t gq_enq_task,  // 入队 task(已做 mergeA 重组)
  output logic        gq_enq_valid,
  output logic [7:0]  gq_enq_grantid,
  output logic        gq_deq_ready,
  input  logic        gq_deq_valid,
  input  logic        gq_deq_isKeyword,
  input  logic [3:0]  gq_deq_opcode,
  input  logic [2:0]  gq_deq_param,
  input  logic [6:0]  gq_deq_sourceId,
  input  logic        gq_deq_denied,
  input  logic        gq_deq_corrupt,
  input  logic [7:0]  gq_deq_grantid,
  input  logic [4:0]  gq_count,
  // ---- 与 grantQueueData0/1(Queue16_GrantQueueData) 黑盒对接 ----
  input  logic [255:0] gd0_deq_data,
  input  logic [255:0] gd1_deq_data,
  // ---- 与 pftRespQueue(Queue10) 黑盒对接(仅取计数做反压) ----
  input  logic [3:0]  pft_count
);

  // ===== 打包扁平 d_task 输入为 TaskBundle 结构体(便于按字段重组) =====
  task_bundle_t dtask;
  always_comb begin
    dtask.channel = io_d_task_bits_task_channel;
    dtask.txChannel = io_d_task_bits_task_txChannel;
    dtask.set = io_d_task_bits_task_set;
    dtask.tag = io_d_task_bits_task_tag;
    dtask.off = io_d_task_bits_task_off;
    dtask.alias_ = io_d_task_bits_task_alias;
    dtask.vaddr = io_d_task_bits_task_vaddr;
    dtask.isKeyword = io_d_task_bits_task_isKeyword;
    dtask.opcode = io_d_task_bits_task_opcode;
    dtask.param = io_d_task_bits_task_param;
    dtask.size = io_d_task_bits_task_size;
    dtask.sourceId = io_d_task_bits_task_sourceId;
    dtask.bufIdx = io_d_task_bits_task_bufIdx;
    dtask.needProbeAckData = io_d_task_bits_task_needProbeAckData;
    dtask.denied = io_d_task_bits_task_denied;
    dtask.corrupt = io_d_task_bits_task_corrupt;
    dtask.mshrTask = io_d_task_bits_task_mshrTask;
    dtask.mshrId = io_d_task_bits_task_mshrId;
    dtask.aliasTask = io_d_task_bits_task_aliasTask;
    dtask.useProbeData = io_d_task_bits_task_useProbeData;
    dtask.mshrRetry = io_d_task_bits_task_mshrRetry;
    dtask.readProbeDataDown = io_d_task_bits_task_readProbeDataDown;
    dtask.fromL2pft = io_d_task_bits_task_fromL2pft;
    dtask.needHint = io_d_task_bits_task_needHint;
    dtask.dirty = io_d_task_bits_task_dirty;
    dtask.way = io_d_task_bits_task_way;
    dtask.meta_dirty = io_d_task_bits_task_meta_dirty;
    dtask.meta_state = io_d_task_bits_task_meta_state;
    dtask.meta_clients = io_d_task_bits_task_meta_clients;
    dtask.meta_alias = io_d_task_bits_task_meta_alias;
    dtask.meta_prefetch = io_d_task_bits_task_meta_prefetch;
    dtask.meta_prefetchSrc = io_d_task_bits_task_meta_prefetchSrc;
    dtask.meta_accessed = io_d_task_bits_task_meta_accessed;
    dtask.meta_tagErr = io_d_task_bits_task_meta_tagErr;
    dtask.meta_dataErr = io_d_task_bits_task_meta_dataErr;
    dtask.metaWen = io_d_task_bits_task_metaWen;
    dtask.tagWen = io_d_task_bits_task_tagWen;
    dtask.dsWen = io_d_task_bits_task_dsWen;
    dtask.wayMask = io_d_task_bits_task_wayMask;
    dtask.replTask = io_d_task_bits_task_replTask;
    dtask.cmoTask = io_d_task_bits_task_cmoTask;
    dtask.cmoAll = io_d_task_bits_task_cmoAll;
    dtask.reqSource = io_d_task_bits_task_reqSource;
    dtask.mergeA = io_d_task_bits_task_mergeA;
    dtask.aMergeTask_off = io_d_task_bits_task_aMergeTask_off;
    dtask.aMergeTask_alias = io_d_task_bits_task_aMergeTask_alias;
    dtask.aMergeTask_vaddr = io_d_task_bits_task_aMergeTask_vaddr;
    dtask.aMergeTask_isKeyword = io_d_task_bits_task_aMergeTask_isKeyword;
    dtask.aMergeTask_opcode = io_d_task_bits_task_aMergeTask_opcode;
    dtask.aMergeTask_param = io_d_task_bits_task_aMergeTask_param;
    dtask.aMergeTask_sourceId = io_d_task_bits_task_aMergeTask_sourceId;
    dtask.aMergeTask_meta_dirty = io_d_task_bits_task_aMergeTask_meta_dirty;
    dtask.aMergeTask_meta_state = io_d_task_bits_task_aMergeTask_meta_state;
    dtask.aMergeTask_meta_clients = io_d_task_bits_task_aMergeTask_meta_clients;
    dtask.aMergeTask_meta_alias = io_d_task_bits_task_aMergeTask_meta_alias;
    dtask.aMergeTask_meta_prefetch = io_d_task_bits_task_aMergeTask_meta_prefetch;
    dtask.aMergeTask_meta_prefetchSrc = io_d_task_bits_task_aMergeTask_meta_prefetchSrc;
    dtask.aMergeTask_meta_accessed = io_d_task_bits_task_aMergeTask_meta_accessed;
    dtask.aMergeTask_meta_tagErr = io_d_task_bits_task_aMergeTask_meta_tagErr;
    dtask.aMergeTask_meta_dataErr = io_d_task_bits_task_aMergeTask_meta_dataErr;
    dtask.snpHitRelease = io_d_task_bits_task_snpHitRelease;
    dtask.snpHitReleaseToInval = io_d_task_bits_task_snpHitReleaseToInval;
    dtask.snpHitReleaseToClean = io_d_task_bits_task_snpHitReleaseToClean;
    dtask.snpHitReleaseWithData = io_d_task_bits_task_snpHitReleaseWithData;
    dtask.snpHitReleaseIdx = io_d_task_bits_task_snpHitReleaseIdx;
    dtask.snpHitReleaseMeta_dirty = io_d_task_bits_task_snpHitReleaseMeta_dirty;
    dtask.snpHitReleaseMeta_state = io_d_task_bits_task_snpHitReleaseMeta_state;
    dtask.snpHitReleaseMeta_clients = io_d_task_bits_task_snpHitReleaseMeta_clients;
    dtask.snpHitReleaseMeta_alias = io_d_task_bits_task_snpHitReleaseMeta_alias;
    dtask.snpHitReleaseMeta_prefetch = io_d_task_bits_task_snpHitReleaseMeta_prefetch;
    dtask.snpHitReleaseMeta_prefetchSrc = io_d_task_bits_task_snpHitReleaseMeta_prefetchSrc;
    dtask.snpHitReleaseMeta_accessed = io_d_task_bits_task_snpHitReleaseMeta_accessed;
    dtask.snpHitReleaseMeta_tagErr = io_d_task_bits_task_snpHitReleaseMeta_tagErr;
    dtask.snpHitReleaseMeta_dataErr = io_d_task_bits_task_snpHitReleaseMeta_dataErr;
    dtask.tgtID = io_d_task_bits_task_tgtID;
    dtask.srcID = io_d_task_bits_task_srcID;
    dtask.txnID = io_d_task_bits_task_txnID;
    dtask.homeNID = io_d_task_bits_task_homeNID;
    dtask.dbID = io_d_task_bits_task_dbID;
    dtask.fwdNID = io_d_task_bits_task_fwdNID;
    dtask.fwdTxnID = io_d_task_bits_task_fwdTxnID;
    dtask.chiOpcode = io_d_task_bits_task_chiOpcode;
    dtask.resp = io_d_task_bits_task_resp;
    dtask.fwdState = io_d_task_bits_task_fwdState;
    dtask.pCrdType = io_d_task_bits_task_pCrdType;
    dtask.retToSrc = io_d_task_bits_task_retToSrc;
    dtask.likelyshared = io_d_task_bits_task_likelyshared;
    dtask.expCompAck = io_d_task_bits_task_expCompAck;
    dtask.allowRetry = io_d_task_bits_task_allowRetry;
    dtask.memAttr_allocate = io_d_task_bits_task_memAttr_allocate;
    dtask.memAttr_cacheable = io_d_task_bits_task_memAttr_cacheable;
    dtask.memAttr_device = io_d_task_bits_task_memAttr_device;
    dtask.memAttr_ewa = io_d_task_bits_task_memAttr_ewa;
    dtask.traceTag = io_d_task_bits_task_traceTag;
    dtask.dataCheckErr = io_d_task_bits_task_dataCheckErr;
  end

  // ===== mergeA 入队重组: mergeAtask 取 aMergeTask 字段, 其余清 0; 非 mergeA 走原 task =====
  // 对照 Scala mergeAtask := WireInit(0.U.asTypeOf(TaskBundle)); 逐项覆盖, 再 Mux(mergeA,...)
  task_bundle_t mergeAtask;
  always_comb begin
    mergeAtask = '0;
    mergeAtask.channel = dtask.channel;
    mergeAtask.txChannel = dtask.txChannel;
    mergeAtask.set = dtask.set;
    mergeAtask.tag = dtask.tag;
    mergeAtask.off = dtask.aMergeTask_off;
    mergeAtask.alias_ = dtask.aMergeTask_alias;
    mergeAtask.vaddr = dtask.vaddr;
    mergeAtask.isKeyword = dtask.aMergeTask_isKeyword;
    mergeAtask.opcode = {1'b0, dtask.aMergeTask_opcode};
    mergeAtask.param = dtask.aMergeTask_param;
    mergeAtask.size = dtask.size;
    mergeAtask.sourceId = dtask.aMergeTask_sourceId;
    mergeAtask.bufIdx = dtask.bufIdx;
    mergeAtask.needProbeAckData = dtask.needProbeAckData;
    mergeAtask.denied = dtask.denied;
    mergeAtask.corrupt = dtask.corrupt | dtask.denied;
    mergeAtask.mshrTask = dtask.mshrTask;
    mergeAtask.mshrId = dtask.mshrId;
    mergeAtask.aliasTask = dtask.aliasTask;
    mergeAtask.dirty = dtask.dirty;
    mergeAtask.way = dtask.way;
    mergeAtask.meta_dirty = dtask.aMergeTask_meta_dirty;
    mergeAtask.meta_state = dtask.aMergeTask_meta_state;
    mergeAtask.meta_clients = dtask.aMergeTask_meta_clients;
    mergeAtask.meta_alias = dtask.aMergeTask_meta_alias;
    mergeAtask.meta_prefetch = dtask.aMergeTask_meta_prefetch;
    mergeAtask.meta_prefetchSrc = dtask.aMergeTask_meta_prefetchSrc;
    mergeAtask.meta_accessed = dtask.aMergeTask_meta_accessed;
    mergeAtask.meta_tagErr = dtask.aMergeTask_meta_tagErr;
    mergeAtask.meta_dataErr = dtask.aMergeTask_meta_dataErr;
    mergeAtask.metaWen = dtask.metaWen;
    mergeAtask.tagWen = dtask.tagWen;
    mergeAtask.dsWen = dtask.dsWen;
    mergeAtask.wayMask = dtask.wayMask;
    mergeAtask.replTask = dtask.replTask;
    mergeAtask.reqSource = dtask.reqSource;
  end
  assign gq_enq_task = io_d_task_bits_task_mergeA ? mergeAtask : dtask;

  // ===== inflightGrant 表(16): 已发 Grant 未收 GrantAck 的地址 =====
  logic        inflightGrant_valid [16];
  logic [8:0]  inflightGrant_set   [16];
  logic [30:0] inflightGrant_tag   [16];

  // insertIdx = 第一个空表项(PriorityEncoder(~valid)); 全满(0..14 valid)时取 15
  logic [3:0] insert_idx;
  always_comb begin
    insert_idx = 4'd15;
    for (int k = 14; k >= 0; k--)
      if (!inflightGrant_valid[k]) insert_idx = k[3:0];
  end

  // ===== grantBuf: 暂存 GrantData 未发出的第二拍 =====
  logic         grantBufValid;
  logic         grantBuf_task_isKeyword;
  logic [3:0]   grantBuf_task_opcode;
  // golden 存 3 位 param 但只读 [1:0](TL param 仅 2 位有效); bit[2] 在 golden 侧死。
  // 本核收窄到 golden 实际读出的 2 位, golden 的 grantBuf_task_param[2] 落 golden-only dead-ref。
  logic [1:0]   grantBuf_task_param;
  logic [6:0]   grantBuf_task_sourceId;
  logic         grantBuf_task_denied;
  logic         grantBuf_task_corrupt;
  logic [255:0] grantBuf_data_data;
  logic [7:0]   grantBuf_grantid;

  // ===== 入队/出队握手 =====
  // 入队: d_task 有效且(非 HintAck 或 mergeA); HintAck(预取响应,opcode==2)单独走 pftRespQueue
  assign gq_enq_valid = io_d_task_valid &
                        (io_d_task_bits_task_opcode != 4'h2 | io_d_task_bits_task_mergeA);
  assign gq_enq_grantid = {4'h0, insert_idx};
  // 出队就绪: io.d 就绪且 grantBuf 不占用(grantBuf 占用时第二拍优先)
  assign gq_deq_ready = io_d_ready & ~grantBufValid;

  // deqTask.opcode(0)=1(奇数 opcode=带数据): 首拍直发, 余拍存 grantBuf
  wire deq_fire   = gq_deq_valid & io_d_ready;
  wire load_grantBuf = deq_fire & ~grantBufValid & gq_deq_opcode[0];

  // 分配 inflight: d_task.fire 且为 Grant/GrantData/mergeA (io.d_task.ready 恒 1, fire==valid)
  wire inflight_alloc = io_d_task_valid &
       (io_d_task_bits_task_opcode == 4'h4 | io_d_task_bits_task_opcode == 4'h5 |
        io_d_task_bits_task_mergeA);

  // per-slot 分配/释放选择(组合, 移出 always_ff 避免 FM 每迭代推成死寄存器)
  logic alloc_k [16];
  logic free_k  [16];
  always_comb begin
    for (int k = 0; k < 16; k++) begin
      alloc_k[k] = inflight_alloc & (insert_idx == k[3:0]);
      free_k[k]  = io_e_valid & (io_e_bits_sink[3:0] == k[3:0]);
    end
  end

  // ===== 时序: inflightGrant + grantBuf =====
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int k = 0; k < 16; k++) begin
        inflightGrant_valid[k] <= 1'b0;
        inflightGrant_set[k]   <= 9'h0;
        inflightGrant_tag[k]   <= 31'h0;
      end
      grantBufValid           <= 1'b0;
      grantBuf_task_isKeyword <= 1'b0;
      grantBuf_task_opcode    <= 4'h0;
      grantBuf_task_param     <= 2'h0;
      grantBuf_task_sourceId  <= 7'h0;
      grantBuf_task_denied    <= 1'b0;
      grantBuf_task_corrupt   <= 1'b0;
      grantBuf_data_data      <= 256'h0;
      grantBuf_grantid        <= 8'h0;
    end else begin
      for (int k = 0; k < 16; k++) begin
        // 收到 GrantAck(free) 清 valid; 否则分配置位; 否则保持
        inflightGrant_valid[k] <= ~free_k[k] & (alloc_k[k] | inflightGrant_valid[k]);
        if (alloc_k[k]) begin
          inflightGrant_set[k] <= io_d_task_bits_task_set;
          inflightGrant_tag[k] <= io_d_task_bits_task_tag;
        end
      end
      // grantBuf: 装第二拍 / 发出后清空
      grantBufValid <= ~(grantBufValid & io_d_ready) & (load_grantBuf | grantBufValid);
      if (load_grantBuf) begin
        grantBuf_task_isKeyword <= gq_deq_isKeyword;
        grantBuf_task_opcode    <= gq_deq_opcode;
        grantBuf_task_param     <= gq_deq_param[1:0];
        grantBuf_task_sourceId  <= gq_deq_sourceId;
        grantBuf_task_denied    <= gq_deq_denied;
        grantBuf_task_corrupt   <= gq_deq_corrupt;
        // 装入 grantBuf 的是 "另一拍": isKeyword 时取 beat0 否则 beat1
        grantBuf_data_data      <= gq_deq_isKeyword ? gd0_deq_data : gd1_deq_data;
        grantBuf_grantid        <= gq_deq_grantid;
      end
    end
  end

  // ===== 组 TLBundleD 发往 L1: grantBuf 占用时发第二拍, 否则发出队首拍 =====
  assign io_d_valid              = grantBufValid | gq_deq_valid;
  assign io_d_bits_opcode        = grantBufValid ? grantBuf_task_opcode      : gq_deq_opcode;
  assign io_d_bits_param         = grantBufValid ? grantBuf_task_param       : gq_deq_param[1:0];
  assign io_d_bits_source        = grantBufValid ? grantBuf_task_sourceId    : gq_deq_sourceId;
  assign io_d_bits_sink          = grantBufValid ? grantBuf_grantid          : gq_deq_grantid;
  assign io_d_bits_denied        = grantBufValid ? grantBuf_task_denied      : gq_deq_denied;
  assign io_d_bits_echo_isKeyword= grantBufValid ? grantBuf_task_isKeyword   : gq_deq_isKeyword;
  // 首拍数据: isKeyword 时取 beat1 否则 beat0 (与装 grantBuf 的取拍相反 = keyword 重排)
  assign io_d_bits_data          = grantBufValid ? grantBuf_data_data :
                                   (gq_deq_isKeyword ? gd1_deq_data : gd0_deq_data);
  assign io_d_bits_corrupt       = grantBufValid ? (grantBuf_task_corrupt | grantBuf_task_denied)
                                                 : (gq_deq_corrupt | gq_deq_denied);

  // ===== grantStatus = inflightGrant(供 SourceB) =====
  assign io_grantStatus_0_valid = inflightGrant_valid[0];
  assign io_grantStatus_0_set   = inflightGrant_set[0];
  assign io_grantStatus_0_tag   = inflightGrant_tag[0];
  assign io_grantStatus_1_valid = inflightGrant_valid[1];
  assign io_grantStatus_1_set   = inflightGrant_set[1];
  assign io_grantStatus_1_tag   = inflightGrant_tag[1];
  assign io_grantStatus_2_valid = inflightGrant_valid[2];
  assign io_grantStatus_2_set   = inflightGrant_set[2];
  assign io_grantStatus_2_tag   = inflightGrant_tag[2];
  assign io_grantStatus_3_valid = inflightGrant_valid[3];
  assign io_grantStatus_3_set   = inflightGrant_set[3];
  assign io_grantStatus_3_tag   = inflightGrant_tag[3];
  assign io_grantStatus_4_valid = inflightGrant_valid[4];
  assign io_grantStatus_4_set   = inflightGrant_set[4];
  assign io_grantStatus_4_tag   = inflightGrant_tag[4];
  assign io_grantStatus_5_valid = inflightGrant_valid[5];
  assign io_grantStatus_5_set   = inflightGrant_set[5];
  assign io_grantStatus_5_tag   = inflightGrant_tag[5];
  assign io_grantStatus_6_valid = inflightGrant_valid[6];
  assign io_grantStatus_6_set   = inflightGrant_set[6];
  assign io_grantStatus_6_tag   = inflightGrant_tag[6];
  assign io_grantStatus_7_valid = inflightGrant_valid[7];
  assign io_grantStatus_7_set   = inflightGrant_set[7];
  assign io_grantStatus_7_tag   = inflightGrant_tag[7];
  assign io_grantStatus_8_valid = inflightGrant_valid[8];
  assign io_grantStatus_8_set   = inflightGrant_set[8];
  assign io_grantStatus_8_tag   = inflightGrant_tag[8];
  assign io_grantStatus_9_valid = inflightGrant_valid[9];
  assign io_grantStatus_9_set   = inflightGrant_set[9];
  assign io_grantStatus_9_tag   = inflightGrant_tag[9];
  assign io_grantStatus_10_valid = inflightGrant_valid[10];
  assign io_grantStatus_10_set   = inflightGrant_set[10];
  assign io_grantStatus_10_tag   = inflightGrant_tag[10];
  assign io_grantStatus_11_valid = inflightGrant_valid[11];
  assign io_grantStatus_11_set   = inflightGrant_set[11];
  assign io_grantStatus_11_tag   = inflightGrant_tag[11];
  assign io_grantStatus_12_valid = inflightGrant_valid[12];
  assign io_grantStatus_12_set   = inflightGrant_set[12];
  assign io_grantStatus_12_tag   = inflightGrant_tag[12];
  assign io_grantStatus_13_valid = inflightGrant_valid[13];
  assign io_grantStatus_13_set   = inflightGrant_set[13];
  assign io_grantStatus_13_tag   = inflightGrant_tag[13];
  assign io_grantStatus_14_valid = inflightGrant_valid[14];
  assign io_grantStatus_14_set   = inflightGrant_set[14];
  assign io_grantStatus_14_tag   = inflightGrant_tag[14];
  assign io_grantStatus_15_valid = inflightGrant_valid[15];
  assign io_grantStatus_15_set   = inflightGrant_set[15];
  assign io_grantStatus_15_tag   = inflightGrant_tag[15];

  // ===== 容量反压: 统计流水级占用 + 队列计数, 防 GrantBuf/inflight/pft 溢出 =====
  // 流水级 1..4 中 fromA(channel[0]) / fromC(channel[2]) 计数(可能占 GrantBuf)
  logic [2:0] cnt_ac, cnt_a;
  always_comb begin
    cnt_ac = 3'h0; cnt_a = 3'h0;
    if (io_pipeStatusVec_1_valid & (io_pipeStatusVec_1_bits_channel[0] | io_pipeStatusVec_1_bits_channel[2])) cnt_ac = cnt_ac + 3'h1;
    if (io_pipeStatusVec_2_valid & (io_pipeStatusVec_2_bits_channel[0] | io_pipeStatusVec_2_bits_channel[2])) cnt_ac = cnt_ac + 3'h1;
    if (io_pipeStatusVec_3_valid & (io_pipeStatusVec_3_bits_channel[0] | io_pipeStatusVec_3_bits_channel[2])) cnt_ac = cnt_ac + 3'h1;
    if (io_pipeStatusVec_4_valid & (io_pipeStatusVec_4_bits_channel[0] | io_pipeStatusVec_4_bits_channel[2])) cnt_ac = cnt_ac + 3'h1;
    if (io_pipeStatusVec_1_valid & io_pipeStatusVec_1_bits_channel[0])             cnt_a  = cnt_a  + 3'h1;
    if (io_pipeStatusVec_2_valid & io_pipeStatusVec_2_bits_channel[0])             cnt_a  = cnt_a  + 3'h1;
    if (io_pipeStatusVec_3_valid & io_pipeStatusVec_3_bits_channel[0])             cnt_a  = cnt_a  + 3'h1;
    if (io_pipeStatusVec_4_valid & io_pipeStatusVec_4_bits_channel[0])             cnt_a  = cnt_a  + 3'h1;
  end
  // inflightGrant 占用计数
  logic [4:0] cnt_inflight;
  always_comb begin
    cnt_inflight = 5'h0;
    for (int k = 0; k < 16; k++)
      if (inflightGrant_valid[k]) cnt_inflight = cnt_inflight + 5'h1;
  end

  // mshrsAll=16: SinkReq 阈值 16, MSHRReq 阈值 15(留一拍 s1 余量); pftQueueLen=10。
  // 位宽严格对齐 golden(队列计数被 FM 视为自由 cut-point, 取值可超 16, 必须按原截断)：
  //   sum_grant/sum_infl 截断到 5bit; sum_pft 截断到 4bit。
  wire [4:0] sum_grant = {2'h0, cnt_ac} + gq_count;          // +grantQueue, 5bit 截断
  wire [4:0] sum_infl  = {2'h0, cnt_a}  + cnt_inflight;      // +inflight(待 GrantAck)
  wire [3:0] sum_pft   = {1'h0, cnt_a}  + pft_count;         // +pftRespQueue, 4bit 截断
  // bit4 = sum>=16 (mshrsAll); >5'hE = sum>=15 (mshrsAll-1); pft 阈值 10/9 (pftQueueLen-0/1)
  assign io_toReqArb_blockSinkReqEntrance_blockC_s1 = sum_grant[4];
  assign io_toReqArb_blockSinkReqEntrance_blockA_s1 =
           sum_grant[4] | sum_infl[4] | (sum_pft > 4'h9);
  assign io_toReqArb_blockMSHRReqEntrance =
           (sum_grant > 5'hE) | (sum_infl > 5'hE) | (sum_pft > 4'h8);
  // blockB: 上层 B(Probe) 入口阻塞 —— 同址(set&tag)有在途 Grant 未确认
  logic blockB;
  always_comb begin
    blockB = 1'b0;
    for (int k = 0; k < 16; k++)
      if (inflightGrant_valid[k] &
          (inflightGrant_set[k] == io_fromReqArb_status_s1_sets_1) &
          (inflightGrant_tag[k] == io_fromReqArb_status_s1_tags_1)) blockB = 1'b1;
  end
  assign io_toReqArb_blockSinkReqEntrance_blockB_s1 = blockB;

endmodule
