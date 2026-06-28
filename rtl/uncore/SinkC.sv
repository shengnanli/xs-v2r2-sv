// =============================================================================
//  SinkC —— coupledL2 (tl2chi) TileLink C 通道接收器 可读重写核 (xs_SinkC_core)
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/src/main/scala/coupledL2/SinkC.scala
//  把上层 (DCache) 经 C 通道送来的 Release/ProbeAck 事务归一并回收数据:
//    (1) Release/ReleaseData : 数据多拍写入 dataBuf, 末拍生成 TaskBundle 投 taskBuf,
//        由 RRArbiterInit 轮询发往 RequestArb。
//    (2) ProbeAck/ProbeAckData: 经 io.resp 唤醒 MSHR 的 w_probeack;
//        ProbeAckData 整块数据 (2 拍) 写 ReleaseBuffer (io.releaseBufWrite)。
//    (3) refillBufWrite: C-Release 新数据先于 MSHR-Release 旧 refill 写回 DS 的冒险处理,
//        当 task 发射且命中某 MSHR 的 blockRefill 时, 把 dataBuf 内容回写 refillBuf。
//
//  单态化 (firtool SinkC.sv): bufBlocks=4, beatSize=2, mshrsAll=16, ways=8。
//  RRArbiterInit_14 (4 入 1 出轮询仲裁, TaskBundle 95 字段) 为黑盒, 在本核内例化;
//  4 个 taskBuf 表项逐字段保留为寄存器 (与 golden 同名), 喂给仲裁器, 出口 io_task_bits_*
//  由仲裁器直接驱动。
//
//  ===== 多拍计数 (edgeIn.count) =====
//    r_beats1 = hasData & (size 满块 => beats>1)。两拍块: 第 0 拍 r_counter=0 (first),
//    第 1 拍 r_counter=1 (last)。beat 为拍序号 (0/1)。单拍事务 first=last=1。
//
//  ===== X 铁律 =====
//    复位后 4 表项 valid=0 门控仲裁输入与缓冲读出; writeIdx/allocIdx ∈ [0,3];
//    OHToUInt 用显式位掩码归约; 无 generate 内函数捕获模块信号。
// =============================================================================
// ---- TaskBundle 4 表项寄存器 (与 golden 同名, 逐字段忠实保留) ----
// 用宏按表项号 K 展开: 95 个字段只写一遍, 4 个表项各例化一次。
// 仅 12 个有效字段会写非零值(见 SC_TB_WR), 其余字段 toTaskBundle 恒置 0;
// golden 把整条 TaskBundle 都建成寄存器, 这里同样保留以保证 1:1 等价。
`define SC_TB_DECL(K) \
  logic [2:0]   taskBuf_``K``_channel; \
  logic [2:0]   taskBuf_``K``_txChannel; \
  logic [8:0]   taskBuf_``K``_set; \
  logic [30:0]  taskBuf_``K``_tag; \
  logic [5:0]   taskBuf_``K``_off; \
  logic [1:0]   taskBuf_``K``_alias; \
  logic [43:0]  taskBuf_``K``_vaddr; \
  logic         taskBuf_``K``_isKeyword; \
  logic [3:0]   taskBuf_``K``_opcode; \
  logic [2:0]   taskBuf_``K``_param; \
  logic [2:0]   taskBuf_``K``_size; \
  logic [6:0]   taskBuf_``K``_sourceId; \
  logic [1:0]   taskBuf_``K``_bufIdx; \
  logic         taskBuf_``K``_needProbeAckData; \
  logic         taskBuf_``K``_denied; \
  logic         taskBuf_``K``_corrupt; \
  logic         taskBuf_``K``_mshrTask; \
  logic [7:0]   taskBuf_``K``_mshrId; \
  logic         taskBuf_``K``_aliasTask; \
  logic         taskBuf_``K``_useProbeData; \
  logic         taskBuf_``K``_mshrRetry; \
  logic         taskBuf_``K``_readProbeDataDown; \
  logic         taskBuf_``K``_fromL2pft; \
  logic         taskBuf_``K``_needHint; \
  logic         taskBuf_``K``_dirty; \
  logic [2:0]   taskBuf_``K``_way; \
  logic         taskBuf_``K``_meta_dirty; \
  logic [1:0]   taskBuf_``K``_meta_state; \
  logic         taskBuf_``K``_meta_clients; \
  logic [1:0]   taskBuf_``K``_meta_alias; \
  logic         taskBuf_``K``_meta_prefetch; \
  logic [2:0]   taskBuf_``K``_meta_prefetchSrc; \
  logic         taskBuf_``K``_meta_accessed; \
  logic         taskBuf_``K``_meta_tagErr; \
  logic         taskBuf_``K``_meta_dataErr; \
  logic         taskBuf_``K``_metaWen; \
  logic         taskBuf_``K``_tagWen; \
  logic         taskBuf_``K``_dsWen; \
  logic [7:0]   taskBuf_``K``_wayMask; \
  logic         taskBuf_``K``_replTask; \
  logic         taskBuf_``K``_cmoTask; \
  logic         taskBuf_``K``_cmoAll; \
  logic [4:0]   taskBuf_``K``_reqSource; \
  logic         taskBuf_``K``_mergeA; \
  logic [5:0]   taskBuf_``K``_aMergeTask_off; \
  logic [1:0]   taskBuf_``K``_aMergeTask_alias; \
  logic [43:0]  taskBuf_``K``_aMergeTask_vaddr; \
  logic         taskBuf_``K``_aMergeTask_isKeyword; \
  logic [2:0]   taskBuf_``K``_aMergeTask_opcode; \
  logic [2:0]   taskBuf_``K``_aMergeTask_param; \
  logic [6:0]   taskBuf_``K``_aMergeTask_sourceId; \
  logic         taskBuf_``K``_aMergeTask_meta_dirty; \
  logic [1:0]   taskBuf_``K``_aMergeTask_meta_state; \
  logic         taskBuf_``K``_aMergeTask_meta_clients; \
  logic [1:0]   taskBuf_``K``_aMergeTask_meta_alias; \
  logic         taskBuf_``K``_aMergeTask_meta_prefetch; \
  logic [2:0]   taskBuf_``K``_aMergeTask_meta_prefetchSrc; \
  logic         taskBuf_``K``_aMergeTask_meta_accessed; \
  logic         taskBuf_``K``_aMergeTask_meta_tagErr; \
  logic         taskBuf_``K``_aMergeTask_meta_dataErr; \
  logic         taskBuf_``K``_snpHitRelease; \
  logic         taskBuf_``K``_snpHitReleaseToInval; \
  logic         taskBuf_``K``_snpHitReleaseToClean; \
  logic         taskBuf_``K``_snpHitReleaseWithData; \
  logic [7:0]   taskBuf_``K``_snpHitReleaseIdx; \
  logic         taskBuf_``K``_snpHitReleaseMeta_dirty; \
  logic [1:0]   taskBuf_``K``_snpHitReleaseMeta_state; \
  logic         taskBuf_``K``_snpHitReleaseMeta_clients; \
  logic [1:0]   taskBuf_``K``_snpHitReleaseMeta_alias; \
  logic         taskBuf_``K``_snpHitReleaseMeta_prefetch; \
  logic [2:0]   taskBuf_``K``_snpHitReleaseMeta_prefetchSrc; \
  logic         taskBuf_``K``_snpHitReleaseMeta_accessed; \
  logic         taskBuf_``K``_snpHitReleaseMeta_tagErr; \
  logic         taskBuf_``K``_snpHitReleaseMeta_dataErr; \
  logic [10:0]  taskBuf_``K``_tgtID; \
  logic [10:0]  taskBuf_``K``_srcID; \
  logic [11:0]  taskBuf_``K``_txnID; \
  logic [10:0]  taskBuf_``K``_homeNID; \
  logic [11:0]  taskBuf_``K``_dbID; \
  logic [10:0]  taskBuf_``K``_fwdNID; \
  logic [11:0]  taskBuf_``K``_fwdTxnID; \
  logic [6:0]   taskBuf_``K``_chiOpcode; \
  logic [2:0]   taskBuf_``K``_resp; \
  logic [2:0]   taskBuf_``K``_fwdState; \
  logic [3:0]   taskBuf_``K``_pCrdType; \
  logic         taskBuf_``K``_retToSrc; \
  logic         taskBuf_``K``_likelyshared; \
  logic         taskBuf_``K``_expCompAck; \
  logic         taskBuf_``K``_allowRetry; \
  logic         taskBuf_``K``_memAttr_allocate; \
  logic         taskBuf_``K``_memAttr_cacheable; \
  logic         taskBuf_``K``_memAttr_device; \
  logic         taskBuf_``K``_memAttr_ewa; \
  logic         taskBuf_``K``_traceTag; \
  logic         taskBuf_``K``_dataCheckErr;

`define SC_TB_RST(K) \
      taskBuf_``K``_channel <= '0; \
      taskBuf_``K``_txChannel <= '0; \
      taskBuf_``K``_set <= '0; \
      taskBuf_``K``_tag <= '0; \
      taskBuf_``K``_off <= '0; \
      taskBuf_``K``_alias <= '0; \
      taskBuf_``K``_vaddr <= '0; \
      taskBuf_``K``_isKeyword <= '0; \
      taskBuf_``K``_opcode <= '0; \
      taskBuf_``K``_param <= '0; \
      taskBuf_``K``_size <= '0; \
      taskBuf_``K``_sourceId <= '0; \
      taskBuf_``K``_bufIdx <= '0; \
      taskBuf_``K``_needProbeAckData <= '0; \
      taskBuf_``K``_denied <= '0; \
      taskBuf_``K``_corrupt <= '0; \
      taskBuf_``K``_mshrTask <= '0; \
      taskBuf_``K``_mshrId <= '0; \
      taskBuf_``K``_aliasTask <= '0; \
      taskBuf_``K``_useProbeData <= '0; \
      taskBuf_``K``_mshrRetry <= '0; \
      taskBuf_``K``_readProbeDataDown <= '0; \
      taskBuf_``K``_fromL2pft <= '0; \
      taskBuf_``K``_needHint <= '0; \
      taskBuf_``K``_dirty <= '0; \
      taskBuf_``K``_way <= '0; \
      taskBuf_``K``_meta_dirty <= '0; \
      taskBuf_``K``_meta_state <= '0; \
      taskBuf_``K``_meta_clients <= '0; \
      taskBuf_``K``_meta_alias <= '0; \
      taskBuf_``K``_meta_prefetch <= '0; \
      taskBuf_``K``_meta_prefetchSrc <= '0; \
      taskBuf_``K``_meta_accessed <= '0; \
      taskBuf_``K``_meta_tagErr <= '0; \
      taskBuf_``K``_meta_dataErr <= '0; \
      taskBuf_``K``_metaWen <= '0; \
      taskBuf_``K``_tagWen <= '0; \
      taskBuf_``K``_dsWen <= '0; \
      taskBuf_``K``_wayMask <= '0; \
      taskBuf_``K``_replTask <= '0; \
      taskBuf_``K``_cmoTask <= '0; \
      taskBuf_``K``_cmoAll <= '0; \
      taskBuf_``K``_reqSource <= '0; \
      taskBuf_``K``_mergeA <= '0; \
      taskBuf_``K``_aMergeTask_off <= '0; \
      taskBuf_``K``_aMergeTask_alias <= '0; \
      taskBuf_``K``_aMergeTask_vaddr <= '0; \
      taskBuf_``K``_aMergeTask_isKeyword <= '0; \
      taskBuf_``K``_aMergeTask_opcode <= '0; \
      taskBuf_``K``_aMergeTask_param <= '0; \
      taskBuf_``K``_aMergeTask_sourceId <= '0; \
      taskBuf_``K``_aMergeTask_meta_dirty <= '0; \
      taskBuf_``K``_aMergeTask_meta_state <= '0; \
      taskBuf_``K``_aMergeTask_meta_clients <= '0; \
      taskBuf_``K``_aMergeTask_meta_alias <= '0; \
      taskBuf_``K``_aMergeTask_meta_prefetch <= '0; \
      taskBuf_``K``_aMergeTask_meta_prefetchSrc <= '0; \
      taskBuf_``K``_aMergeTask_meta_accessed <= '0; \
      taskBuf_``K``_aMergeTask_meta_tagErr <= '0; \
      taskBuf_``K``_aMergeTask_meta_dataErr <= '0; \
      taskBuf_``K``_snpHitRelease <= '0; \
      taskBuf_``K``_snpHitReleaseToInval <= '0; \
      taskBuf_``K``_snpHitReleaseToClean <= '0; \
      taskBuf_``K``_snpHitReleaseWithData <= '0; \
      taskBuf_``K``_snpHitReleaseIdx <= '0; \
      taskBuf_``K``_snpHitReleaseMeta_dirty <= '0; \
      taskBuf_``K``_snpHitReleaseMeta_state <= '0; \
      taskBuf_``K``_snpHitReleaseMeta_clients <= '0; \
      taskBuf_``K``_snpHitReleaseMeta_alias <= '0; \
      taskBuf_``K``_snpHitReleaseMeta_prefetch <= '0; \
      taskBuf_``K``_snpHitReleaseMeta_prefetchSrc <= '0; \
      taskBuf_``K``_snpHitReleaseMeta_accessed <= '0; \
      taskBuf_``K``_snpHitReleaseMeta_tagErr <= '0; \
      taskBuf_``K``_snpHitReleaseMeta_dataErr <= '0; \
      taskBuf_``K``_tgtID <= '0; \
      taskBuf_``K``_srcID <= '0; \
      taskBuf_``K``_txnID <= '0; \
      taskBuf_``K``_homeNID <= '0; \
      taskBuf_``K``_dbID <= '0; \
      taskBuf_``K``_fwdNID <= '0; \
      taskBuf_``K``_fwdTxnID <= '0; \
      taskBuf_``K``_chiOpcode <= '0; \
      taskBuf_``K``_resp <= '0; \
      taskBuf_``K``_fwdState <= '0; \
      taskBuf_``K``_pCrdType <= '0; \
      taskBuf_``K``_retToSrc <= '0; \
      taskBuf_``K``_likelyshared <= '0; \
      taskBuf_``K``_expCompAck <= '0; \
      taskBuf_``K``_allowRetry <= '0; \
      taskBuf_``K``_memAttr_allocate <= '0; \
      taskBuf_``K``_memAttr_cacheable <= '0; \
      taskBuf_``K``_memAttr_device <= '0; \
      taskBuf_``K``_memAttr_ewa <= '0; \
      taskBuf_``K``_traceTag <= '0; \
      taskBuf_``K``_dataCheckErr <= '0;

// 末拍且本表项被选中时, 写入 toTaskBundle 结果 (有效字段取 C 通道, 其余 0)
`define SC_TB_WR(K) \
    if (cValidLast & (allocIdx == K)) begin \
        taskBuf_``K``_channel <= 3'h4; \
        taskBuf_``K``_txChannel <= '0; \
        taskBuf_``K``_set <= io_c_bits_address[16:8]; \
        taskBuf_``K``_tag <= io_c_bits_address[47:17]; \
        taskBuf_``K``_off <= io_c_bits_address[5:0]; \
        taskBuf_``K``_alias <= '0; \
        taskBuf_``K``_vaddr <= '0; \
        taskBuf_``K``_isKeyword <= '0; \
        taskBuf_``K``_opcode <= {1'h0, io_c_bits_opcode}; \
        taskBuf_``K``_param <= io_c_bits_param; \
        taskBuf_``K``_size <= io_c_bits_size; \
        taskBuf_``K``_sourceId <= io_c_bits_source; \
        taskBuf_``K``_bufIdx <= allocIdx; \
        taskBuf_``K``_needProbeAckData <= '0; \
        taskBuf_``K``_denied <= taskBuf_task_denied; \
        taskBuf_``K``_corrupt <= taskBuf_task_corrupt; \
        taskBuf_``K``_mshrTask <= '0; \
        taskBuf_``K``_mshrId <= '0; \
        taskBuf_``K``_aliasTask <= '0; \
        taskBuf_``K``_useProbeData <= '0; \
        taskBuf_``K``_mshrRetry <= '0; \
        taskBuf_``K``_readProbeDataDown <= '0; \
        taskBuf_``K``_fromL2pft <= '0; \
        taskBuf_``K``_needHint <= '0; \
        taskBuf_``K``_dirty <= '0; \
        taskBuf_``K``_way <= '0; \
        taskBuf_``K``_meta_dirty <= '0; \
        taskBuf_``K``_meta_state <= '0; \
        taskBuf_``K``_meta_clients <= '0; \
        taskBuf_``K``_meta_alias <= '0; \
        taskBuf_``K``_meta_prefetch <= '0; \
        taskBuf_``K``_meta_prefetchSrc <= '0; \
        taskBuf_``K``_meta_accessed <= '0; \
        taskBuf_``K``_meta_tagErr <= '0; \
        taskBuf_``K``_meta_dataErr <= '0; \
        taskBuf_``K``_metaWen <= '0; \
        taskBuf_``K``_tagWen <= '0; \
        taskBuf_``K``_dsWen <= '0; \
        taskBuf_``K``_wayMask <= 8'hFF; \
        taskBuf_``K``_replTask <= '0; \
        taskBuf_``K``_cmoTask <= '0; \
        taskBuf_``K``_cmoAll <= '0; \
        taskBuf_``K``_reqSource <= '0; \
        taskBuf_``K``_mergeA <= '0; \
        taskBuf_``K``_aMergeTask_off <= '0; \
        taskBuf_``K``_aMergeTask_alias <= '0; \
        taskBuf_``K``_aMergeTask_vaddr <= '0; \
        taskBuf_``K``_aMergeTask_isKeyword <= '0; \
        taskBuf_``K``_aMergeTask_opcode <= '0; \
        taskBuf_``K``_aMergeTask_param <= '0; \
        taskBuf_``K``_aMergeTask_sourceId <= '0; \
        taskBuf_``K``_aMergeTask_meta_dirty <= '0; \
        taskBuf_``K``_aMergeTask_meta_state <= '0; \
        taskBuf_``K``_aMergeTask_meta_clients <= '0; \
        taskBuf_``K``_aMergeTask_meta_alias <= '0; \
        taskBuf_``K``_aMergeTask_meta_prefetch <= '0; \
        taskBuf_``K``_aMergeTask_meta_prefetchSrc <= '0; \
        taskBuf_``K``_aMergeTask_meta_accessed <= '0; \
        taskBuf_``K``_aMergeTask_meta_tagErr <= '0; \
        taskBuf_``K``_aMergeTask_meta_dataErr <= '0; \
        taskBuf_``K``_snpHitRelease <= '0; \
        taskBuf_``K``_snpHitReleaseToInval <= '0; \
        taskBuf_``K``_snpHitReleaseToClean <= '0; \
        taskBuf_``K``_snpHitReleaseWithData <= '0; \
        taskBuf_``K``_snpHitReleaseIdx <= '0; \
        taskBuf_``K``_snpHitReleaseMeta_dirty <= '0; \
        taskBuf_``K``_snpHitReleaseMeta_state <= '0; \
        taskBuf_``K``_snpHitReleaseMeta_clients <= '0; \
        taskBuf_``K``_snpHitReleaseMeta_alias <= '0; \
        taskBuf_``K``_snpHitReleaseMeta_prefetch <= '0; \
        taskBuf_``K``_snpHitReleaseMeta_prefetchSrc <= '0; \
        taskBuf_``K``_snpHitReleaseMeta_accessed <= '0; \
        taskBuf_``K``_snpHitReleaseMeta_tagErr <= '0; \
        taskBuf_``K``_snpHitReleaseMeta_dataErr <= '0; \
        taskBuf_``K``_tgtID <= '0; \
        taskBuf_``K``_srcID <= '0; \
        taskBuf_``K``_txnID <= '0; \
        taskBuf_``K``_homeNID <= '0; \
        taskBuf_``K``_dbID <= '0; \
        taskBuf_``K``_fwdNID <= '0; \
        taskBuf_``K``_fwdTxnID <= '0; \
        taskBuf_``K``_chiOpcode <= '0; \
        taskBuf_``K``_resp <= '0; \
        taskBuf_``K``_fwdState <= '0; \
        taskBuf_``K``_pCrdType <= '0; \
        taskBuf_``K``_retToSrc <= '0; \
        taskBuf_``K``_likelyshared <= '0; \
        taskBuf_``K``_expCompAck <= '0; \
        taskBuf_``K``_allowRetry <= '0; \
        taskBuf_``K``_memAttr_allocate <= '0; \
        taskBuf_``K``_memAttr_cacheable <= '0; \
        taskBuf_``K``_memAttr_device <= '0; \
        taskBuf_``K``_memAttr_ewa <= '0; \
        taskBuf_``K``_traceTag <= '0; \
        taskBuf_``K``_dataCheckErr <= '0; \
    end

`define SC_TB_ARB(K) \
    .io_in_``K``_ready(arb_in_``K``_ready), \
    .io_in_``K``_valid(taskValids[K]), \
    .io_in_``K``_bits_channel(taskBuf_``K``_channel), \
    .io_in_``K``_bits_txChannel(taskBuf_``K``_txChannel), \
    .io_in_``K``_bits_set(taskBuf_``K``_set), \
    .io_in_``K``_bits_tag(taskBuf_``K``_tag), \
    .io_in_``K``_bits_off(taskBuf_``K``_off), \
    .io_in_``K``_bits_alias(taskBuf_``K``_alias), \
    .io_in_``K``_bits_vaddr(taskBuf_``K``_vaddr), \
    .io_in_``K``_bits_isKeyword(taskBuf_``K``_isKeyword), \
    .io_in_``K``_bits_opcode(taskBuf_``K``_opcode), \
    .io_in_``K``_bits_param(taskBuf_``K``_param), \
    .io_in_``K``_bits_size(taskBuf_``K``_size), \
    .io_in_``K``_bits_sourceId(taskBuf_``K``_sourceId), \
    .io_in_``K``_bits_bufIdx(taskBuf_``K``_bufIdx), \
    .io_in_``K``_bits_needProbeAckData(taskBuf_``K``_needProbeAckData), \
    .io_in_``K``_bits_denied(taskBuf_``K``_denied), \
    .io_in_``K``_bits_corrupt(taskBuf_``K``_corrupt), \
    .io_in_``K``_bits_mshrTask(taskBuf_``K``_mshrTask), \
    .io_in_``K``_bits_mshrId(taskBuf_``K``_mshrId), \
    .io_in_``K``_bits_aliasTask(taskBuf_``K``_aliasTask), \
    .io_in_``K``_bits_useProbeData(taskBuf_``K``_useProbeData), \
    .io_in_``K``_bits_mshrRetry(taskBuf_``K``_mshrRetry), \
    .io_in_``K``_bits_readProbeDataDown(taskBuf_``K``_readProbeDataDown), \
    .io_in_``K``_bits_fromL2pft(taskBuf_``K``_fromL2pft), \
    .io_in_``K``_bits_needHint(taskBuf_``K``_needHint), \
    .io_in_``K``_bits_dirty(taskBuf_``K``_dirty), \
    .io_in_``K``_bits_way(taskBuf_``K``_way), \
    .io_in_``K``_bits_meta_dirty(taskBuf_``K``_meta_dirty), \
    .io_in_``K``_bits_meta_state(taskBuf_``K``_meta_state), \
    .io_in_``K``_bits_meta_clients(taskBuf_``K``_meta_clients), \
    .io_in_``K``_bits_meta_alias(taskBuf_``K``_meta_alias), \
    .io_in_``K``_bits_meta_prefetch(taskBuf_``K``_meta_prefetch), \
    .io_in_``K``_bits_meta_prefetchSrc(taskBuf_``K``_meta_prefetchSrc), \
    .io_in_``K``_bits_meta_accessed(taskBuf_``K``_meta_accessed), \
    .io_in_``K``_bits_meta_tagErr(taskBuf_``K``_meta_tagErr), \
    .io_in_``K``_bits_meta_dataErr(taskBuf_``K``_meta_dataErr), \
    .io_in_``K``_bits_metaWen(taskBuf_``K``_metaWen), \
    .io_in_``K``_bits_tagWen(taskBuf_``K``_tagWen), \
    .io_in_``K``_bits_dsWen(taskBuf_``K``_dsWen), \
    .io_in_``K``_bits_wayMask(taskBuf_``K``_wayMask), \
    .io_in_``K``_bits_replTask(taskBuf_``K``_replTask), \
    .io_in_``K``_bits_cmoTask(taskBuf_``K``_cmoTask), \
    .io_in_``K``_bits_cmoAll(taskBuf_``K``_cmoAll), \
    .io_in_``K``_bits_reqSource(taskBuf_``K``_reqSource), \
    .io_in_``K``_bits_mergeA(taskBuf_``K``_mergeA), \
    .io_in_``K``_bits_aMergeTask_off(taskBuf_``K``_aMergeTask_off), \
    .io_in_``K``_bits_aMergeTask_alias(taskBuf_``K``_aMergeTask_alias), \
    .io_in_``K``_bits_aMergeTask_vaddr(taskBuf_``K``_aMergeTask_vaddr), \
    .io_in_``K``_bits_aMergeTask_isKeyword(taskBuf_``K``_aMergeTask_isKeyword), \
    .io_in_``K``_bits_aMergeTask_opcode(taskBuf_``K``_aMergeTask_opcode), \
    .io_in_``K``_bits_aMergeTask_param(taskBuf_``K``_aMergeTask_param), \
    .io_in_``K``_bits_aMergeTask_sourceId(taskBuf_``K``_aMergeTask_sourceId), \
    .io_in_``K``_bits_aMergeTask_meta_dirty(taskBuf_``K``_aMergeTask_meta_dirty), \
    .io_in_``K``_bits_aMergeTask_meta_state(taskBuf_``K``_aMergeTask_meta_state), \
    .io_in_``K``_bits_aMergeTask_meta_clients(taskBuf_``K``_aMergeTask_meta_clients), \
    .io_in_``K``_bits_aMergeTask_meta_alias(taskBuf_``K``_aMergeTask_meta_alias), \
    .io_in_``K``_bits_aMergeTask_meta_prefetch(taskBuf_``K``_aMergeTask_meta_prefetch), \
    .io_in_``K``_bits_aMergeTask_meta_prefetchSrc(taskBuf_``K``_aMergeTask_meta_prefetchSrc), \
    .io_in_``K``_bits_aMergeTask_meta_accessed(taskBuf_``K``_aMergeTask_meta_accessed), \
    .io_in_``K``_bits_aMergeTask_meta_tagErr(taskBuf_``K``_aMergeTask_meta_tagErr), \
    .io_in_``K``_bits_aMergeTask_meta_dataErr(taskBuf_``K``_aMergeTask_meta_dataErr), \
    .io_in_``K``_bits_snpHitRelease(taskBuf_``K``_snpHitRelease), \
    .io_in_``K``_bits_snpHitReleaseToInval(taskBuf_``K``_snpHitReleaseToInval), \
    .io_in_``K``_bits_snpHitReleaseToClean(taskBuf_``K``_snpHitReleaseToClean), \
    .io_in_``K``_bits_snpHitReleaseWithData(taskBuf_``K``_snpHitReleaseWithData), \
    .io_in_``K``_bits_snpHitReleaseIdx(taskBuf_``K``_snpHitReleaseIdx), \
    .io_in_``K``_bits_snpHitReleaseMeta_dirty(taskBuf_``K``_snpHitReleaseMeta_dirty), \
    .io_in_``K``_bits_snpHitReleaseMeta_state(taskBuf_``K``_snpHitReleaseMeta_state), \
    .io_in_``K``_bits_snpHitReleaseMeta_clients(taskBuf_``K``_snpHitReleaseMeta_clients), \
    .io_in_``K``_bits_snpHitReleaseMeta_alias(taskBuf_``K``_snpHitReleaseMeta_alias), \
    .io_in_``K``_bits_snpHitReleaseMeta_prefetch(taskBuf_``K``_snpHitReleaseMeta_prefetch), \
    .io_in_``K``_bits_snpHitReleaseMeta_prefetchSrc(taskBuf_``K``_snpHitReleaseMeta_prefetchSrc), \
    .io_in_``K``_bits_snpHitReleaseMeta_accessed(taskBuf_``K``_snpHitReleaseMeta_accessed), \
    .io_in_``K``_bits_snpHitReleaseMeta_tagErr(taskBuf_``K``_snpHitReleaseMeta_tagErr), \
    .io_in_``K``_bits_snpHitReleaseMeta_dataErr(taskBuf_``K``_snpHitReleaseMeta_dataErr), \
    .io_in_``K``_bits_tgtID(taskBuf_``K``_tgtID), \
    .io_in_``K``_bits_srcID(taskBuf_``K``_srcID), \
    .io_in_``K``_bits_txnID(taskBuf_``K``_txnID), \
    .io_in_``K``_bits_homeNID(taskBuf_``K``_homeNID), \
    .io_in_``K``_bits_dbID(taskBuf_``K``_dbID), \
    .io_in_``K``_bits_fwdNID(taskBuf_``K``_fwdNID), \
    .io_in_``K``_bits_fwdTxnID(taskBuf_``K``_fwdTxnID), \
    .io_in_``K``_bits_chiOpcode(taskBuf_``K``_chiOpcode), \
    .io_in_``K``_bits_resp(taskBuf_``K``_resp), \
    .io_in_``K``_bits_fwdState(taskBuf_``K``_fwdState), \
    .io_in_``K``_bits_pCrdType(taskBuf_``K``_pCrdType), \
    .io_in_``K``_bits_retToSrc(taskBuf_``K``_retToSrc), \
    .io_in_``K``_bits_likelyshared(taskBuf_``K``_likelyshared), \
    .io_in_``K``_bits_expCompAck(taskBuf_``K``_expCompAck), \
    .io_in_``K``_bits_allowRetry(taskBuf_``K``_allowRetry), \
    .io_in_``K``_bits_memAttr_allocate(taskBuf_``K``_memAttr_allocate), \
    .io_in_``K``_bits_memAttr_cacheable(taskBuf_``K``_memAttr_cacheable), \
    .io_in_``K``_bits_memAttr_device(taskBuf_``K``_memAttr_device), \
    .io_in_``K``_bits_memAttr_ewa(taskBuf_``K``_memAttr_ewa), \
    .io_in_``K``_bits_traceTag(taskBuf_``K``_traceTag), \
    .io_in_``K``_bits_dataCheckErr(taskBuf_``K``_dataCheckErr),

module xs_SinkC_core
  import sinkc_pkg::*;
(
  input  logic          clock,
  input  logic          reset,
  output logic          io_c_ready,
  input  logic          io_c_valid,
  input  logic [2:0]    io_c_bits_opcode,
  input  logic [2:0]    io_c_bits_param,
  input  logic [2:0]    io_c_bits_size,
  input  logic [6:0]    io_c_bits_source,
  input  logic [47:0]   io_c_bits_address,
  input  logic [255:0]  io_c_bits_data,
  input  logic          io_c_bits_corrupt,
  input  logic          io_task_ready,
  output logic          io_task_valid,
  output logic [2:0]    io_task_bits_channel,
  output logic [2:0]    io_task_bits_txChannel,
  output logic [8:0]    io_task_bits_set,
  output logic [30:0]   io_task_bits_tag,
  output logic [5:0]    io_task_bits_off,
  output logic [1:0]    io_task_bits_alias,
  output logic [43:0]   io_task_bits_vaddr,
  output logic          io_task_bits_isKeyword,
  output logic [3:0]    io_task_bits_opcode,
  output logic [2:0]    io_task_bits_param,
  output logic [2:0]    io_task_bits_size,
  output logic [6:0]    io_task_bits_sourceId,
  output logic [1:0]    io_task_bits_bufIdx,
  output logic          io_task_bits_needProbeAckData,
  output logic          io_task_bits_denied,
  output logic          io_task_bits_corrupt,
  output logic          io_task_bits_mshrTask,
  output logic [7:0]    io_task_bits_mshrId,
  output logic          io_task_bits_aliasTask,
  output logic          io_task_bits_useProbeData,
  output logic          io_task_bits_mshrRetry,
  output logic          io_task_bits_readProbeDataDown,
  output logic          io_task_bits_fromL2pft,
  output logic          io_task_bits_needHint,
  output logic          io_task_bits_dirty,
  output logic [2:0]    io_task_bits_way,
  output logic          io_task_bits_meta_dirty,
  output logic [1:0]    io_task_bits_meta_state,
  output logic          io_task_bits_meta_clients,
  output logic [1:0]    io_task_bits_meta_alias,
  output logic          io_task_bits_meta_prefetch,
  output logic [2:0]    io_task_bits_meta_prefetchSrc,
  output logic          io_task_bits_meta_accessed,
  output logic          io_task_bits_meta_tagErr,
  output logic          io_task_bits_meta_dataErr,
  output logic          io_task_bits_metaWen,
  output logic          io_task_bits_tagWen,
  output logic          io_task_bits_dsWen,
  output logic [7:0]    io_task_bits_wayMask,
  output logic          io_task_bits_replTask,
  output logic          io_task_bits_cmoTask,
  output logic          io_task_bits_cmoAll,
  output logic [4:0]    io_task_bits_reqSource,
  output logic          io_task_bits_mergeA,
  output logic [5:0]    io_task_bits_aMergeTask_off,
  output logic [1:0]    io_task_bits_aMergeTask_alias,
  output logic [43:0]   io_task_bits_aMergeTask_vaddr,
  output logic          io_task_bits_aMergeTask_isKeyword,
  output logic [2:0]    io_task_bits_aMergeTask_opcode,
  output logic [2:0]    io_task_bits_aMergeTask_param,
  output logic [6:0]    io_task_bits_aMergeTask_sourceId,
  output logic          io_task_bits_aMergeTask_meta_dirty,
  output logic [1:0]    io_task_bits_aMergeTask_meta_state,
  output logic          io_task_bits_aMergeTask_meta_clients,
  output logic [1:0]    io_task_bits_aMergeTask_meta_alias,
  output logic          io_task_bits_aMergeTask_meta_prefetch,
  output logic [2:0]    io_task_bits_aMergeTask_meta_prefetchSrc,
  output logic          io_task_bits_aMergeTask_meta_accessed,
  output logic          io_task_bits_aMergeTask_meta_tagErr,
  output logic          io_task_bits_aMergeTask_meta_dataErr,
  output logic          io_task_bits_snpHitRelease,
  output logic          io_task_bits_snpHitReleaseToInval,
  output logic          io_task_bits_snpHitReleaseToClean,
  output logic          io_task_bits_snpHitReleaseWithData,
  output logic [7:0]    io_task_bits_snpHitReleaseIdx,
  output logic          io_task_bits_snpHitReleaseMeta_dirty,
  output logic [1:0]    io_task_bits_snpHitReleaseMeta_state,
  output logic          io_task_bits_snpHitReleaseMeta_clients,
  output logic [1:0]    io_task_bits_snpHitReleaseMeta_alias,
  output logic          io_task_bits_snpHitReleaseMeta_prefetch,
  output logic [2:0]    io_task_bits_snpHitReleaseMeta_prefetchSrc,
  output logic          io_task_bits_snpHitReleaseMeta_accessed,
  output logic          io_task_bits_snpHitReleaseMeta_tagErr,
  output logic          io_task_bits_snpHitReleaseMeta_dataErr,
  output logic [10:0]   io_task_bits_tgtID,
  output logic [10:0]   io_task_bits_srcID,
  output logic [11:0]   io_task_bits_txnID,
  output logic [10:0]   io_task_bits_homeNID,
  output logic [11:0]   io_task_bits_dbID,
  output logic [10:0]   io_task_bits_fwdNID,
  output logic [11:0]   io_task_bits_fwdTxnID,
  output logic [6:0]    io_task_bits_chiOpcode,
  output logic [2:0]    io_task_bits_resp,
  output logic [2:0]    io_task_bits_fwdState,
  output logic [3:0]    io_task_bits_pCrdType,
  output logic          io_task_bits_retToSrc,
  output logic          io_task_bits_likelyshared,
  output logic          io_task_bits_expCompAck,
  output logic          io_task_bits_allowRetry,
  output logic          io_task_bits_memAttr_allocate,
  output logic          io_task_bits_memAttr_cacheable,
  output logic          io_task_bits_memAttr_device,
  output logic          io_task_bits_memAttr_ewa,
  output logic          io_task_bits_traceTag,
  output logic          io_task_bits_dataCheckErr,
  output logic          io_resp_valid,
  output logic [8:0]    io_resp_set,
  output logic [30:0]   io_resp_tag,
  output logic [2:0]    io_resp_respInfo_opcode,
  output logic [2:0]    io_resp_respInfo_param,
  output logic          io_resp_respInfo_last,
  output logic          io_resp_respInfo_denied,
  output logic          io_resp_respInfo_corrupt,
  output logic          io_releaseBufWrite_valid,
  output logic [511:0]  io_releaseBufWrite_bits_data_data,
  output logic [255:0]  io_bufResp_data_0,
  output logic [255:0]  io_bufResp_data_1,
  output logic          io_refillBufWrite_valid,
  output logic [7:0]    io_refillBufWrite_bits_id,
  output logic [511:0]  io_refillBufWrite_bits_data_data,
  input  logic          io_msInfo_0_valid,
  input  logic [8:0]    io_msInfo_0_bits_set,
  input  logic [30:0]   io_msInfo_0_bits_reqTag,
  input  logic          io_msInfo_0_bits_blockRefill,
  input  logic          io_msInfo_1_valid,
  input  logic [8:0]    io_msInfo_1_bits_set,
  input  logic [30:0]   io_msInfo_1_bits_reqTag,
  input  logic          io_msInfo_1_bits_blockRefill,
  input  logic          io_msInfo_2_valid,
  input  logic [8:0]    io_msInfo_2_bits_set,
  input  logic [30:0]   io_msInfo_2_bits_reqTag,
  input  logic          io_msInfo_2_bits_blockRefill,
  input  logic          io_msInfo_3_valid,
  input  logic [8:0]    io_msInfo_3_bits_set,
  input  logic [30:0]   io_msInfo_3_bits_reqTag,
  input  logic          io_msInfo_3_bits_blockRefill,
  input  logic          io_msInfo_4_valid,
  input  logic [8:0]    io_msInfo_4_bits_set,
  input  logic [30:0]   io_msInfo_4_bits_reqTag,
  input  logic          io_msInfo_4_bits_blockRefill,
  input  logic          io_msInfo_5_valid,
  input  logic [8:0]    io_msInfo_5_bits_set,
  input  logic [30:0]   io_msInfo_5_bits_reqTag,
  input  logic          io_msInfo_5_bits_blockRefill,
  input  logic          io_msInfo_6_valid,
  input  logic [8:0]    io_msInfo_6_bits_set,
  input  logic [30:0]   io_msInfo_6_bits_reqTag,
  input  logic          io_msInfo_6_bits_blockRefill,
  input  logic          io_msInfo_7_valid,
  input  logic [8:0]    io_msInfo_7_bits_set,
  input  logic [30:0]   io_msInfo_7_bits_reqTag,
  input  logic          io_msInfo_7_bits_blockRefill,
  input  logic          io_msInfo_8_valid,
  input  logic [8:0]    io_msInfo_8_bits_set,
  input  logic [30:0]   io_msInfo_8_bits_reqTag,
  input  logic          io_msInfo_8_bits_blockRefill,
  input  logic          io_msInfo_9_valid,
  input  logic [8:0]    io_msInfo_9_bits_set,
  input  logic [30:0]   io_msInfo_9_bits_reqTag,
  input  logic          io_msInfo_9_bits_blockRefill,
  input  logic          io_msInfo_10_valid,
  input  logic [8:0]    io_msInfo_10_bits_set,
  input  logic [30:0]   io_msInfo_10_bits_reqTag,
  input  logic          io_msInfo_10_bits_blockRefill,
  input  logic          io_msInfo_11_valid,
  input  logic [8:0]    io_msInfo_11_bits_set,
  input  logic [30:0]   io_msInfo_11_bits_reqTag,
  input  logic          io_msInfo_11_bits_blockRefill,
  input  logic          io_msInfo_12_valid,
  input  logic [8:0]    io_msInfo_12_bits_set,
  input  logic [30:0]   io_msInfo_12_bits_reqTag,
  input  logic          io_msInfo_12_bits_blockRefill,
  input  logic          io_msInfo_13_valid,
  input  logic [8:0]    io_msInfo_13_bits_set,
  input  logic [30:0]   io_msInfo_13_bits_reqTag,
  input  logic          io_msInfo_13_bits_blockRefill,
  input  logic          io_msInfo_14_valid,
  input  logic [8:0]    io_msInfo_14_bits_set,
  input  logic [30:0]   io_msInfo_14_bits_reqTag,
  input  logic          io_msInfo_14_bits_blockRefill,
  input  logic          io_msInfo_15_valid,
  input  logic [8:0]    io_msInfo_15_bits_set,
  input  logic [30:0]   io_msInfo_15_bits_reqTag,
  input  logic          io_msInfo_15_bits_blockRefill
);

  // ===================== 数据/任务缓冲存储 =====================
  logic [255:0] dataBuf    [BUF_BLOCKS][BEAT_SIZE]; // Release/ReleaseData 数据 (4 块 × 2 拍)
  logic         beatValids [BUF_BLOCKS][BEAT_SIZE]; // 每拍是否已写入
  logic         taskValids [BUF_BLOCKS];            // taskBuf 表项是否待发射
  logic [1:0]   nextPtrReg;                         // RegEnable(nextPtr): 多拍块首拍锁定的块号
  logic         r_counter;                          // 多拍下行计数 (0=首拍, 1=次拍)
  logic [255:0] probeAckDataBuf;                    // 暂存 ProbeAckData 第一拍数据
  // 4 表项 TaskBundle 寄存器 (逐字段, 与 golden 同名)
  `SC_TB_DECL(0)
  `SC_TB_DECL(1)
  `SC_TB_DECL(2)
  `SC_TB_DECL(3)

  // bufResp / refillBuf 读出流水寄存器 (同步, 无复位; 名字对齐 golden)
  logic [255:0] r_0, r_1;        // RegEnable(dataBuf(bufIdx), task.fire)
  logic [255:0] REG_0, REG_1;    // RegNext(上一级) -> io.bufResp
  logic         REG_1_0;         // RegNext(io.task.fire)
  logic [1:0]   REG_2;           // RegNext(arb_out_bufIdx)
  logic [3:0]   io_refillBufWrite_bits_id_REG;
  logic [1:0]   io_refillBufWrite_bits_data_data_REG;
  logic         io_refillBufWrite_valid_REG;

  // 与 RRArbiterInit_14 黑盒对接的边界 wire
  wire        arb_in_0_ready, arb_in_1_ready, arb_in_2_ready, arb_in_3_ready;
  wire        arb_out_valid;
  wire [8:0]  arb_out_set;
  wire [30:0] arb_out_tag;
  wire [3:0]  arb_out_opcode;
  wire [1:0]  arb_out_bufIdx;

  // ===================== 多拍计数 (edgeIn.count) =====================
  wire        isRelease = io_c_bits_opcode[1];      // Release/ReleaseData
  wire        hasData   = io_c_bits_opcode[0];      // ProbeAckData/ReleaseData
  wire [12:0] beats_decode = 13'h3F << io_c_bits_size;
  wire        r_beats1  = hasData & ~beats_decode[5];   // 块超过 1 拍
  wire        last      = r_counter | ~r_beats1;        // 末拍
  wire        first     = ~r_counter;                   // 首拍
  wire        beat      = r_beats1 & ~(r_counter - 1'b1);   // 拍序号 (0/1)

  // ===================== 缓冲占用与分配 =====================
  wire [3:0] dataValids = {beatValids[3][1] | beatValids[3][0],
                           beatValids[2][1] | beatValids[2][0],
                           beatValids[1][1] | beatValids[1][0],
                           beatValids[0][1] | beatValids[0][0]};
  wire [3:0] bufValids  = {taskValids[3], taskValids[2], taskValids[1], taskValids[0]} | dataValids;
  wire       full       = &bufValids;

  // nextPtr = PriorityEncoder(~bufValids): 取最低空闲块
  wire [2:0] freeMask = ~bufValids[2:0];
  wire [1:0] nextPtr  = freeMask[0] ? 2'h0 : freeMask[1] ? 2'h1 : {1'h1, ~freeMask[2]};

  // io.c.ready = !isRelease || !first || !full
  assign io_c_ready = ~isRelease | r_counter | ~full;
  wire   cFire = io_c_ready & io_c_valid;

  // 写缓冲选块: 首拍用新分配 nextPtr, 次拍沿用 nextPtrReg
  wire [1:0] writeIdx = r_counter ? nextPtrReg : nextPtr;
  // 末拍生成 task 时选块: 带数据用 nextPtrReg, 无数据用 nextPtr
  wire [1:0] allocIdx = hasData ? nextPtrReg : nextPtr;

  wire cFireRelData = cFire & isRelease & hasData;   // io.c.fire && isRelease && hasData
  wire cValidLast   = cFire & isRelease & last;       // 末拍, 生成 task

  // toTaskBundle 的 corrupt/denied 派生 (与 golden 同名 wire)
  wire taskBuf_task_corrupt = io_c_bits_corrupt & (io_c_bits_opcode == PROBE_ACK_DATA | io_c_bits_opcode == RELEASE_DATA);
  wire taskBuf_task_denied  = io_c_bits_corrupt & (io_c_bits_opcode == PROBE_ACK      | io_c_bits_opcode == RELEASE);

  // 仲裁输入 fire (按表项): valid & ready
  wire [3:0] arbInReady = {arb_in_3_ready, arb_in_2_ready, arb_in_1_ready, arb_in_0_ready};
  wire [3:0] arbInFire  = {taskValids[3], taskValids[2], taskValids[1], taskValids[0]} & arbInReady;

  // beatValids 清除: RegNext(io.task.fire) 且 RegNext(bufIdx)==k
  wire [3:0] clearBeat  = {4{REG_1_0}} & {(REG_2 == 2'h3), (REG_2 == 2'h2),
                                          (REG_2 == 2'h1), (REG_2 == 2'h0)};

  // ===================== refillBuf 冒险判定 (newdataMask) =====================
  //  taskArb 发射的 task 地址命中某 MSHR 且其 blockRefill 置位时, 把 dataBuf 回写 refillBuf。
  wire io_task_fire = io_task_ready & arb_out_valid;
  logic [MSHRS-1:0] newdataMask;
  always_comb begin
    newdataMask[0]  = io_msInfo_0_valid  & (io_msInfo_0_bits_set  == arb_out_set) & (io_msInfo_0_bits_reqTag  == arb_out_tag) & io_msInfo_0_bits_blockRefill;
    newdataMask[1]  = io_msInfo_1_valid  & (io_msInfo_1_bits_set  == arb_out_set) & (io_msInfo_1_bits_reqTag  == arb_out_tag) & io_msInfo_1_bits_blockRefill;
    newdataMask[2]  = io_msInfo_2_valid  & (io_msInfo_2_bits_set  == arb_out_set) & (io_msInfo_2_bits_reqTag  == arb_out_tag) & io_msInfo_2_bits_blockRefill;
    newdataMask[3]  = io_msInfo_3_valid  & (io_msInfo_3_bits_set  == arb_out_set) & (io_msInfo_3_bits_reqTag  == arb_out_tag) & io_msInfo_3_bits_blockRefill;
    newdataMask[4]  = io_msInfo_4_valid  & (io_msInfo_4_bits_set  == arb_out_set) & (io_msInfo_4_bits_reqTag  == arb_out_tag) & io_msInfo_4_bits_blockRefill;
    newdataMask[5]  = io_msInfo_5_valid  & (io_msInfo_5_bits_set  == arb_out_set) & (io_msInfo_5_bits_reqTag  == arb_out_tag) & io_msInfo_5_bits_blockRefill;
    newdataMask[6]  = io_msInfo_6_valid  & (io_msInfo_6_bits_set  == arb_out_set) & (io_msInfo_6_bits_reqTag  == arb_out_tag) & io_msInfo_6_bits_blockRefill;
    newdataMask[7]  = io_msInfo_7_valid  & (io_msInfo_7_bits_set  == arb_out_set) & (io_msInfo_7_bits_reqTag  == arb_out_tag) & io_msInfo_7_bits_blockRefill;
    newdataMask[8]  = io_msInfo_8_valid  & (io_msInfo_8_bits_set  == arb_out_set) & (io_msInfo_8_bits_reqTag  == arb_out_tag) & io_msInfo_8_bits_blockRefill;
    newdataMask[9]  = io_msInfo_9_valid  & (io_msInfo_9_bits_set  == arb_out_set) & (io_msInfo_9_bits_reqTag  == arb_out_tag) & io_msInfo_9_bits_blockRefill;
    newdataMask[10] = io_msInfo_10_valid & (io_msInfo_10_bits_set == arb_out_set) & (io_msInfo_10_bits_reqTag == arb_out_tag) & io_msInfo_10_bits_blockRefill;
    newdataMask[11] = io_msInfo_11_valid & (io_msInfo_11_bits_set == arb_out_set) & (io_msInfo_11_bits_reqTag == arb_out_tag) & io_msInfo_11_bits_blockRefill;
    newdataMask[12] = io_msInfo_12_valid & (io_msInfo_12_bits_set == arb_out_set) & (io_msInfo_12_bits_reqTag == arb_out_tag) & io_msInfo_12_bits_blockRefill;
    newdataMask[13] = io_msInfo_13_valid & (io_msInfo_13_bits_set == arb_out_set) & (io_msInfo_13_bits_reqTag == arb_out_tag) & io_msInfo_13_bits_blockRefill;
    newdataMask[14] = io_msInfo_14_valid & (io_msInfo_14_bits_set == arb_out_set) & (io_msInfo_14_bits_reqTag == arb_out_tag) & io_msInfo_14_bits_blockRefill;
    newdataMask[15] = io_msInfo_15_valid & (io_msInfo_15_bits_set == arb_out_set) & (io_msInfo_15_bits_reqTag == arb_out_tag) & io_msInfo_15_bits_blockRefill;
  end

  // ===================== 主时序: 缓冲与计数 (异步复位) =====================
  integer k, b;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      r_counter  <= 1'b0;
      nextPtrReg <= 2'h0;
      probeAckDataBuf <= 256'h0;
      for (k = 0; k < BUF_BLOCKS; k++) begin
        taskValids[k] <= 1'b0;
        for (b = 0; b < BEAT_SIZE; b++) begin
          dataBuf[k][b]    <= 256'h0;
          beatValids[k][b] <= 1'b0;
        end
      end
      `SC_TB_RST(0)
      `SC_TB_RST(1)
      `SC_TB_RST(2)
      `SC_TB_RST(3)
    end else begin
      // 多拍计数: 每次 c.fire 更新 (次拍->0, 首拍->r_beats1)
      if (cFire)
        r_counter <= r_counter ? (r_counter - 1'b1) : r_beats1;

      // 首拍锁定块号
      if (cFire & isRelease & first & hasData)
        nextPtrReg <= nextPtr;

      // ProbeAckData 首拍暂存
      if (io_c_valid & (io_c_bits_opcode == PROBE_ACK_DATA) & first)
        probeAckDataBuf <= io_c_bits_data;

      // 数据写入 dataBuf / beatValids; 发射后两拍清 beatValids
      for (k = 0; k < BUF_BLOCKS; k++) begin
        for (b = 0; b < BEAT_SIZE; b++) begin
          if (cFireRelData & (writeIdx == k[1:0]) & (beat == b[0]))
            dataBuf[k][b] <= io_c_bits_data;
          if (clearBeat[k])
            beatValids[k][b] <= 1'b0;
          else if (cFireRelData & (writeIdx == k[1:0]) & (beat == b[0]))
            beatValids[k][b] <= 1'b1;
        end
      end

      // 末拍写入 task 数据 (与是否同拍被消费无关)
      `SC_TB_WR(0)
      `SC_TB_WR(1)
      `SC_TB_WR(2)
      `SC_TB_WR(3)

      // taskValids: 被仲裁器消费 (清) 优先于本拍分配 (置)
      //  单拍 ReleaseData 时 allocIdx=nextPtrReg 可能指向当拍正被消费的表项, golden 取「清」语义。
      for (k = 0; k < BUF_BLOCKS; k++)
        taskValids[k] <= ~arbInFire[k] & (taskValids[k] | (cValidLast & (allocIdx == k[1:0])));
    end
  end

  // ===================== bufResp / refillBuf 读出流水 (同步, 无复位) =====================
  //  io.bufResp.data := RegNext(RegEnable(dataBuf(bufIdx), io.task.fire))  (两级)
  always_ff @(posedge clock) begin
    io_refillBufWrite_bits_id_REG        <= ohToUInt16(newdataMask);
    io_refillBufWrite_bits_data_data_REG <= arb_out_bufIdx;
    if (io_task_fire) begin
      r_0 <= dataBuf[arb_out_bufIdx][0];
      r_1 <= dataBuf[arb_out_bufIdx][1];
    end
    REG_0   <= r_0;
    REG_1   <= r_1;
    REG_1_0 <= io_task_fire;
    REG_2   <= arb_out_bufIdx;
  end

  // io.refillBufWrite.valid := RegNext(task.fire && opcode==ReleaseData && newdataMask.orR)
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      io_refillBufWrite_valid_REG <= 1'b0;
    else
      io_refillBufWrite_valid_REG <= io_task_fire & (arb_out_opcode == TASK_RELEASE_DATA) & (|newdataMask);
  end

  // ===================== 标量输出 =====================
  // resp: ProbeAck/ProbeAckData (非 Release) 的首/末拍唤醒 MSHR
  assign io_resp_valid           = io_c_valid & (first | last) & ~isRelease;
  assign io_resp_set             = io_c_bits_address[16:8];
  assign io_resp_tag             = io_c_bits_address[47:17];
  assign io_resp_respInfo_opcode = io_c_bits_opcode;
  assign io_resp_respInfo_param  = io_c_bits_param;
  assign io_resp_respInfo_last   = last;
  assign io_resp_respInfo_denied  = taskBuf_task_denied;
  assign io_resp_respInfo_corrupt = taskBuf_task_corrupt;

  // releaseBufWrite: ProbeAckData 末拍, 整块 {第二拍, 第一拍}
  assign io_releaseBufWrite_valid          = io_c_valid & (io_c_bits_opcode == PROBE_ACK_DATA) & last;
  assign io_releaseBufWrite_bits_data_data = {io_c_bits_data, probeAckDataBuf};

  // bufResp: 两级流水读出
  assign io_bufResp_data_0 = REG_0;
  assign io_bufResp_data_1 = REG_1;

  // refillBufWrite
  assign io_refillBufWrite_valid          = io_refillBufWrite_valid_REG;
  assign io_refillBufWrite_bits_id        = {4'h0, io_refillBufWrite_bits_id_REG};
  assign io_refillBufWrite_bits_data_data = {dataBuf[io_refillBufWrite_bits_data_data_REG][1],
                                             dataBuf[io_refillBufWrite_bits_data_data_REG][0]};

  // io.task 出口握手与被回读字段
  assign io_task_valid       = arb_out_valid;
  assign io_task_bits_set    = arb_out_set;
  assign io_task_bits_tag    = arb_out_tag;
  assign io_task_bits_opcode = arb_out_opcode;
  assign io_task_bits_bufIdx = arb_out_bufIdx;

  // ===================== RRArbiterInit_14 (4 入 1 出轮询仲裁, 黑盒) =====================
  RRArbiterInit_14 taskArb (
    .clock(clock),
    .reset(reset),
    `SC_TB_ARB(0)
    `SC_TB_ARB(1)
    `SC_TB_ARB(2)
    `SC_TB_ARB(3)
    .io_out_ready(io_task_ready),
    .io_out_valid(arb_out_valid),
    .io_out_bits_channel(io_task_bits_channel),
    .io_out_bits_txChannel(io_task_bits_txChannel),
    .io_out_bits_set(arb_out_set),
    .io_out_bits_tag(arb_out_tag),
    .io_out_bits_off(io_task_bits_off),
    .io_out_bits_alias(io_task_bits_alias),
    .io_out_bits_vaddr(io_task_bits_vaddr),
    .io_out_bits_isKeyword(io_task_bits_isKeyword),
    .io_out_bits_opcode(arb_out_opcode),
    .io_out_bits_param(io_task_bits_param),
    .io_out_bits_size(io_task_bits_size),
    .io_out_bits_sourceId(io_task_bits_sourceId),
    .io_out_bits_bufIdx(arb_out_bufIdx),
    .io_out_bits_needProbeAckData(io_task_bits_needProbeAckData),
    .io_out_bits_denied(io_task_bits_denied),
    .io_out_bits_corrupt(io_task_bits_corrupt),
    .io_out_bits_mshrTask(io_task_bits_mshrTask),
    .io_out_bits_mshrId(io_task_bits_mshrId),
    .io_out_bits_aliasTask(io_task_bits_aliasTask),
    .io_out_bits_useProbeData(io_task_bits_useProbeData),
    .io_out_bits_mshrRetry(io_task_bits_mshrRetry),
    .io_out_bits_readProbeDataDown(io_task_bits_readProbeDataDown),
    .io_out_bits_fromL2pft(io_task_bits_fromL2pft),
    .io_out_bits_needHint(io_task_bits_needHint),
    .io_out_bits_dirty(io_task_bits_dirty),
    .io_out_bits_way(io_task_bits_way),
    .io_out_bits_meta_dirty(io_task_bits_meta_dirty),
    .io_out_bits_meta_state(io_task_bits_meta_state),
    .io_out_bits_meta_clients(io_task_bits_meta_clients),
    .io_out_bits_meta_alias(io_task_bits_meta_alias),
    .io_out_bits_meta_prefetch(io_task_bits_meta_prefetch),
    .io_out_bits_meta_prefetchSrc(io_task_bits_meta_prefetchSrc),
    .io_out_bits_meta_accessed(io_task_bits_meta_accessed),
    .io_out_bits_meta_tagErr(io_task_bits_meta_tagErr),
    .io_out_bits_meta_dataErr(io_task_bits_meta_dataErr),
    .io_out_bits_metaWen(io_task_bits_metaWen),
    .io_out_bits_tagWen(io_task_bits_tagWen),
    .io_out_bits_dsWen(io_task_bits_dsWen),
    .io_out_bits_wayMask(io_task_bits_wayMask),
    .io_out_bits_replTask(io_task_bits_replTask),
    .io_out_bits_cmoTask(io_task_bits_cmoTask),
    .io_out_bits_cmoAll(io_task_bits_cmoAll),
    .io_out_bits_reqSource(io_task_bits_reqSource),
    .io_out_bits_mergeA(io_task_bits_mergeA),
    .io_out_bits_aMergeTask_off(io_task_bits_aMergeTask_off),
    .io_out_bits_aMergeTask_alias(io_task_bits_aMergeTask_alias),
    .io_out_bits_aMergeTask_vaddr(io_task_bits_aMergeTask_vaddr),
    .io_out_bits_aMergeTask_isKeyword(io_task_bits_aMergeTask_isKeyword),
    .io_out_bits_aMergeTask_opcode(io_task_bits_aMergeTask_opcode),
    .io_out_bits_aMergeTask_param(io_task_bits_aMergeTask_param),
    .io_out_bits_aMergeTask_sourceId(io_task_bits_aMergeTask_sourceId),
    .io_out_bits_aMergeTask_meta_dirty(io_task_bits_aMergeTask_meta_dirty),
    .io_out_bits_aMergeTask_meta_state(io_task_bits_aMergeTask_meta_state),
    .io_out_bits_aMergeTask_meta_clients(io_task_bits_aMergeTask_meta_clients),
    .io_out_bits_aMergeTask_meta_alias(io_task_bits_aMergeTask_meta_alias),
    .io_out_bits_aMergeTask_meta_prefetch(io_task_bits_aMergeTask_meta_prefetch),
    .io_out_bits_aMergeTask_meta_prefetchSrc(io_task_bits_aMergeTask_meta_prefetchSrc),
    .io_out_bits_aMergeTask_meta_accessed(io_task_bits_aMergeTask_meta_accessed),
    .io_out_bits_aMergeTask_meta_tagErr(io_task_bits_aMergeTask_meta_tagErr),
    .io_out_bits_aMergeTask_meta_dataErr(io_task_bits_aMergeTask_meta_dataErr),
    .io_out_bits_snpHitRelease(io_task_bits_snpHitRelease),
    .io_out_bits_snpHitReleaseToInval(io_task_bits_snpHitReleaseToInval),
    .io_out_bits_snpHitReleaseToClean(io_task_bits_snpHitReleaseToClean),
    .io_out_bits_snpHitReleaseWithData(io_task_bits_snpHitReleaseWithData),
    .io_out_bits_snpHitReleaseIdx(io_task_bits_snpHitReleaseIdx),
    .io_out_bits_snpHitReleaseMeta_dirty(io_task_bits_snpHitReleaseMeta_dirty),
    .io_out_bits_snpHitReleaseMeta_state(io_task_bits_snpHitReleaseMeta_state),
    .io_out_bits_snpHitReleaseMeta_clients(io_task_bits_snpHitReleaseMeta_clients),
    .io_out_bits_snpHitReleaseMeta_alias(io_task_bits_snpHitReleaseMeta_alias),
    .io_out_bits_snpHitReleaseMeta_prefetch(io_task_bits_snpHitReleaseMeta_prefetch),
    .io_out_bits_snpHitReleaseMeta_prefetchSrc(io_task_bits_snpHitReleaseMeta_prefetchSrc),
    .io_out_bits_snpHitReleaseMeta_accessed(io_task_bits_snpHitReleaseMeta_accessed),
    .io_out_bits_snpHitReleaseMeta_tagErr(io_task_bits_snpHitReleaseMeta_tagErr),
    .io_out_bits_snpHitReleaseMeta_dataErr(io_task_bits_snpHitReleaseMeta_dataErr),
    .io_out_bits_tgtID(io_task_bits_tgtID),
    .io_out_bits_srcID(io_task_bits_srcID),
    .io_out_bits_txnID(io_task_bits_txnID),
    .io_out_bits_homeNID(io_task_bits_homeNID),
    .io_out_bits_dbID(io_task_bits_dbID),
    .io_out_bits_fwdNID(io_task_bits_fwdNID),
    .io_out_bits_fwdTxnID(io_task_bits_fwdTxnID),
    .io_out_bits_chiOpcode(io_task_bits_chiOpcode),
    .io_out_bits_resp(io_task_bits_resp),
    .io_out_bits_fwdState(io_task_bits_fwdState),
    .io_out_bits_pCrdType(io_task_bits_pCrdType),
    .io_out_bits_retToSrc(io_task_bits_retToSrc),
    .io_out_bits_likelyshared(io_task_bits_likelyshared),
    .io_out_bits_expCompAck(io_task_bits_expCompAck),
    .io_out_bits_allowRetry(io_task_bits_allowRetry),
    .io_out_bits_memAttr_allocate(io_task_bits_memAttr_allocate),
    .io_out_bits_memAttr_cacheable(io_task_bits_memAttr_cacheable),
    .io_out_bits_memAttr_device(io_task_bits_memAttr_device),
    .io_out_bits_memAttr_ewa(io_task_bits_memAttr_ewa),
    .io_out_bits_traceTag(io_task_bits_traceTag),
    .io_out_bits_dataCheckErr(io_task_bits_dataCheckErr)
  );

endmodule
