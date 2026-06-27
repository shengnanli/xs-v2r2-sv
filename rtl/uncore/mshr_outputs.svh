// =============================================================================
//  mshr_outputs.svh —— status / msInfo / txreq / txrsp / source_b / pCrd / perf 输出
//  对照 MSHR.scala 末段的 io 赋值。
// =============================================================================

// ---------------- pCrd 查询 ----------------
assign io_pCrd_query_valid       = gotRetryAck & ~gotPCrdGrant;
assign io_pCrd_query_bits_pCrdType = pcrdtype;
assign io_pCrd_query_bits_srcID  = srcid_retryack;

// ---------------- tasks 顶层 valid ----------------
assign io_tasks_txreq_valid      = io_tasks_txreq_valid_w;
assign io_tasks_txrsp_valid      = io_tasks_txrsp_valid_w;
assign io_tasks_source_b_valid   = io_tasks_source_b_valid_w;
assign io_tasks_mainpipe_valid   = io_tasks_mainpipe_valid_w;

// ---------------- TXREQ bits ----------------
assign io_tasks_txreq_bits_tgtID = state_s_reissue ? 11'h0 : srcid_retryack;
assign io_tasks_txreq_bits_txnID = mp_release_txnID;
assign io_tasks_txreq_bits_opcode= io_tasks_txreq_bits_opcode_w;
//  addr = {tag, set, offset(0)}; release2 用 dirResult.tag, 否则 req.tag (高 2 位补 0 凑 48b)
assign io_tasks_txreq_bits_addr  = {2'h0, (release_valid2 ? dirResult_tag : req_tag), req_set, 6'h0};
//  likelyshared: 仅 release2 的 WriteEvictOrEvict 且 meta.state==BRANCH 置 1
assign io_tasks_txreq_bits_likelyshared =
  release_valid2 & released_is_WEoE & (dirResult_meta_state == BRANCH);
assign io_tasks_txreq_bits_allowRetry = state_s_reissue;
assign io_tasks_txreq_bits_pCrdType   = state_s_reissue ? 4'h0 : pcrdtype;
assign io_tasks_txreq_bits_memAttr_allocate = ~release_valid2 | (~isEvict & ~cmo_cbo);
assign io_tasks_txreq_bits_memAttr_ewa      = ~cmo_cbo;
assign io_tasks_txreq_bits_expCompAck = release_valid2 ? released_is_WEoE : ~cmo_cbo;

// ---------------- TXRSP bits (CompAck) ----------------
assign io_tasks_txrsp_bits_tgtID    = wcompack_valid ? tgtid_wcompack : tgtid_rcompack;
assign io_tasks_txrsp_bits_txnID    = wcompack_valid ? txnid_wcompack : txnid_rcompack;
assign io_tasks_txrsp_bits_traceTag = req_traceTag;

// ---------------- SOURCE_B bits (Probe) ----------------
assign io_tasks_source_b_bits_tag = dirResult_tag;
assign io_tasks_source_b_bits_set = dirResult_set;
//  param: !s_pprobe (snoop-probe) 时按 snpToB/snpToN; 否则 (rprobe) 按 get/cboClean hit&TRUNK -> toB
assign io_tasks_source_b_bits_param =
  state_s_pprobe
    ? (((req_get | req_cboClean) & dirResult_hit & (dirResult_meta_state == TRUNK)) ? toB : toN)
    : (snpToB ? toB : {snpToN, 1'h0});
assign io_tasks_source_b_bits_alias = dirResult_meta_alias;

// ---------------- STATUS ----------------
assign io_status_valid           = req_valid;
assign io_status_bits_channel    = req_channel;
assign io_status_bits_set        = req_set;
assign io_status_bits_reqTag     = req_tag;
assign io_status_bits_metaTag    = dirResult_tag;
assign io_status_bits_needsRepl  = ~state_s_release;
assign io_status_bits_w_c_resp   = ~state_w_rprobeacklast | ~state_w_pprobeacklast;
assign io_status_bits_will_free  = will_free;
assign io_status_bits_reqSource  = req_reqSource;
assign io_status_bits_is_miss    = ~dirResult_hit;
assign io_status_bits_is_prefetch= req_prefetch;

// ---------------- MSINFO ----------------
assign io_msInfo_valid              = req_valid;
assign io_msInfo_bits_channel       = req_channel;
assign io_msInfo_bits_set           = req_set;
assign io_msInfo_bits_way           = dirResult_way;
assign io_msInfo_bits_reqTag        = req_tag;
assign io_msInfo_bits_willFree      = will_free;
assign io_msInfo_bits_aliasTask     = req_aliasTask;
assign io_msInfo_bits_needRelease   = ~state_w_releaseack;
assign io_msInfo_bits_blockRefill   = ~state_s_release | blockRefill_d1 | blockRefill_d2;
assign io_msInfo_bits_meta_dirty    = dirResult_meta_dirty;
assign io_msInfo_bits_meta_state    = dirResult_meta_state;
assign io_msInfo_bits_meta_clients  = dirResult_meta_clients;
assign io_msInfo_bits_meta_alias    = dirResult_meta_alias;
assign io_msInfo_bits_meta_prefetch = dirResult_meta_prefetch;
assign io_msInfo_bits_meta_prefetchSrc = dirResult_meta_prefetchSrc;
assign io_msInfo_bits_meta_accessed = dirResult_meta_accessed;
assign io_msInfo_bits_meta_tagErr   = dirResult_meta_tagErr;
assign io_msInfo_bits_meta_dataErr  = dirResult_meta_dataErr;
assign io_msInfo_bits_metaTag       = dirResult_tag;
assign io_msInfo_bits_dirHit        = dirResult_hit;
assign io_msInfo_bits_isAcqOrPrefetch = req_acquire | req_prefetch;
assign io_msInfo_bits_isPrefetch    = req_prefetch;
assign io_msInfo_bits_param         = req_param;
assign io_msInfo_bits_mergeA        = mergeA;
assign io_msInfo_bits_w_grantfirst  = state_w_grantfirst;
assign io_msInfo_bits_s_release     = state_s_release;
assign io_msInfo_bits_s_refill      = state_s_refill;
assign io_msInfo_bits_s_cmoresp     = state_s_cmoresp;
assign io_msInfo_bits_s_cmometaw    = state_s_cmometaw;
assign io_msInfo_bits_w_releaseack  = state_w_releaseack;
assign io_msInfo_bits_w_replResp    = state_w_replResp;
assign io_msInfo_bits_w_rprobeacklast = state_w_rprobeacklast;
//  replaceData: T 且 dirty (含 WriteCleanFull) 或 WriteEvictOrEvict
assign io_msInfo_bits_replaceData   = (dirResult_meta_state[1] & dirResult_meta_dirty) | isWriteEvictOrEvict;
assign io_msInfo_bits_releaseToClean= req_cboClean;

// ---------------- nestedwbData ----------------
assign io_nestedwbData = nestedwb_match & io_nestedwb_c_set_dirty;

// ---------------- 性能计数 ----------------
assign acquire_period_valid = acquire_finish & ~acquire_period_valid_d;
assign acquire_period_bits  = timer - acquire_ts;
assign release_period_valid = state_w_releaseack & ~release_period_valid_d;
assign release_period_bits  = timer - release_ts;
