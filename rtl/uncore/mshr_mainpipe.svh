// =============================================================================
//  mshr_mainpipe.svh —— io_tasks_mainpipe_bits_* 的 6 路优先选择输出
//  优先级: grant(mp_is_grant) > release(release_valid1) > cbwrdata(mp_cbwrdata_valid)
//          > probeack(mp_probeack_valid) > dct(mp_dct_valid) > cmometaw(else)
//  对照 MSHR.scala mp_grant_task/mp_release_task/mp_cbwrdata_task/mp_probeack_task/
//  mp_dct_task/mp_cmometaw_task 六个构造块 + 末尾 ParallelPriorityMux。
//  golden 已把六块按优先级压平到每个字段; 此处保持压平结构但用语义名。
// =============================================================================

// 前向声明(其表达式在本文件末尾给出, 供上方 assign 引用)
wire [3:0] io_tasks_mainpipe_bits_opcode_w;
wire [6:0] io_tasks_mainpipe_bits_chiOpcode_w;
wire [2:0] io_tasks_mainpipe_bits_resp_w;
wire [2:0] io_tasks_mainpipe_bits_fwdState_w;

// 公共谓词(对齐 golden _GEN 语义)
wire mp_grantOrRelease = mp_grant_valid | release_valid1;          // golden-GEN4
wire mp_probeOrDct     = mp_probeack_valid | mp_dct_valid;         // golden-GEN5/6/9 同义
wire mp_notWriteGrpOrGrant = ~mp_is_writeGrp | mp_grant_valid;     // golden-GEN7

// merge task (晚到 Acquire/Prefetch 合并)
wire [1:0] merge_alias  = io_aMergeTask_valid ? io_aMergeTask_bits_alias  : merge_task_r_alias;
wire [3:0] merge_opcode = io_aMergeTask_valid ? io_aMergeTask_bits_opcode : merge_task_r_opcode;
wire [2:0] merge_param  = io_aMergeTask_valid ? io_aMergeTask_bits_param  : merge_task_r_param;

// chiOpcode for probeack: {doFwd|doFwdHitRelease, doRespData} 2bit -> SnpResp 系
wire [1:0] mp_probeack_chiOpcode_sel = {
  ((isSnpToBFwd_v | isSnpToNFwd_v | isSnpOnceFwd_v) & dirResult_hit)
   | ((isSnpToBFwd_v | isSnpToNFwd_v | isSnpOnceFwd_v) & (hitWriteDirty | hitWriteEvict)),
  doRespData
};
// resp 的 passDirty bit (probeack)
wire mp_probeack_resp_pd = (hitDirtyOrWriteDirty & ~tagErr &
    (snpToB | isSnpUnique_v | isSnpUniqueStash_v | isSnpCleanShared_v | isSnpCleanInvalid_v))
  | (hitWriteDirty & isSnpOnceFwd_v);
wire [2:0] mp_dct_resp_pd = {fwdPassDirty, 2'h0};

// ===================== 标量控制字段 =====================
assign io_tasks_mainpipe_bits_channel =
  (mp_is_writeGrp | mp_probeack_valid | mp_dct_valid) ? req_channel : 3'h0;
assign io_tasks_mainpipe_bits_txChannel = io_tasks_mainpipe_bits_txChannel_w;
assign io_tasks_mainpipe_bits_set = req_set;
assign io_tasks_mainpipe_bits_tag = mp_notWriteGrpOrGrant ? req_tag : dirResult_tag;
assign io_tasks_mainpipe_bits_off = mp_notWriteGrpOrGrant ? req_off : 6'h0;
assign io_tasks_mainpipe_bits_alias = mp_is_grant ? mp_grant_alias : 2'h0;
assign io_tasks_mainpipe_bits_isKeyword = req_isKeyword;
assign io_tasks_mainpipe_bits_opcode = io_tasks_mainpipe_bits_opcode_w;
assign io_tasks_mainpipe_bits_param =
  mp_is_writeGrp
    ? (mp_grant_valid
         ? (aliasFinal_use_meta | (req_param == NtoT) | (req_param == BtoT)
              ? 3'h0                                                  // Get/Prefetch 或 NtoT/BtoT -> 0/toT
              : (req_param == NtoB) ? GRANT_PARAM_DEF : req_param)
         : release_valid1
             ? (cmo_cbo
                  ? (req_cboClean ? 3'h0 : dirResult_meta_state[1] ? TtoN[2:0] /*1*/ : BtoN[2:0] /*2*/)
                  : dirResult_meta_state[1] ? 3'h1 : 3'h2)
             : 3'h0)
    : 3'h0;
assign io_tasks_mainpipe_bits_size = mp_is_grant ? 3'h0 : 3'h6;
assign io_tasks_mainpipe_bits_sourceId = mp_is_grant ? req_sourceId : 7'h0;
assign io_tasks_mainpipe_bits_denied = mp_is_writeGrp & denied;
assign io_tasks_mainpipe_bits_corrupt = mp_is_writeGrp & corrupt;
assign io_tasks_mainpipe_bits_mshrId = io_id;
assign io_tasks_mainpipe_bits_aliasTask = mp_is_grant & req_aliasTask;
assign io_tasks_mainpipe_bits_useProbeData =
  mp_is_writeGrp
    ? (mp_grant_valid
         ? ((dirResult_hit & req_get) | (req_aliasTask & ~((dirResult_meta_state == BRANCH) & req_needT)))
         : (release_valid1 & cmo_cbo))
    : mp_probe_or_dct;
assign io_tasks_mainpipe_bits_mshrRetry = mp_is_grant & ~state_s_retry;
assign io_tasks_mainpipe_bits_readProbeDataDown =
  mp_is_writeGrp
    ? (~mp_grant_valid & (~release_valid1 | (cmo_cbo & (req_cboClean | (req_cboFlush & isWriteBackFull)))))
    : mp_probeack_valid ? (doRespData | mp_probeack_dsWen) : mp_dct_valid;
assign io_tasks_mainpipe_bits_fromL2pft = mp_is_grant & req_fromL2pft;
assign io_tasks_mainpipe_bits_dirty = ~mp_is_writeGrp & hitDirty;
assign io_tasks_mainpipe_bits_way = dirResult_way;

// ===================== meta 字段 =====================
assign io_tasks_mainpipe_bits_meta_dirty =
  mp_is_writeGrp
    ? (mp_grant_valid & (gotDirty | hitDirty))
    : (mp_probeack_valid & ~tagErr
        & (~(~dirResult_hit | ~dirResult_meta_dirty | snpToN | snpToB | isSnpCleanShared_v
             | ((isSnpOnce_v | isSnpOnceFwd_v) & req_snpHitReleaseToClean))
           | ((isSnpOnce_v | isSnpOnceFwd_v) & probeDirty)));
assign io_tasks_mainpipe_bits_meta_state =
  mp_is_writeGrp
    ? (mp_grant_valid
         ? (req_get
              ? {dirResult_hit ? dirResult_meta_state[1] : req_promoteT, 1'h1}  // Get: hit?TIP/BRANCH : promoteT?TIP:BRANCH
              : (req_promoteT | req_needT) ? {1'h1, req_prefetch} : 2'h1)        // Acquire: TRUNK/TIP : BRANCH
         : (mp_release_cmo
              ? ((dirResult_meta_state == TRUNK) ? TIP : dirResult_meta_state)   // cboClean: TRUNK->TIP
              : 2'h0))
    : mp_probeack_valid
        ? ((snpToN | tagErr) ? INVALID
            : (snpToB | (isSnpOnceFwd_v & hitWriteClean)) ? BRANCH
            : dirResult_meta_state)
        : mp_dct_valid ? 2'h0 : TIP;  // cmometaw -> TIP
assign io_tasks_mainpipe_bits_meta_clients =
  mp_is_writeGrp
    ? (mp_grant_valid
         ? (req_prefetch
              ? (dirResult_hit & dirResult_meta_clients)
              : ~(req_get & (~dirResult_hit | ~dirResult_meta_clients)))
         : (release_valid1 & req_cboClean & cmo_cbo & dirResult_meta_clients))
    : mp_probeack_valid ? (dirResult_meta_clients & ~snpToN)
                        : (~mp_dct_valid & dirResult_meta_clients);
assign io_tasks_mainpipe_bits_meta_alias =
  mp_is_writeGrp
    ? (mp_grant_valid ? mp_grant_alias : mp_release_cmo ? dirResult_meta_alias : 2'h0)
    : (mp_probeack_valid | ~mp_dct_valid) ? dirResult_meta_alias : 2'h0;
assign io_tasks_mainpipe_bits_meta_prefetch =
  mp_is_writeGrp
    ? (mp_grant_valid
         ? (req_prefetch | (dirResult_hit & dirResult_meta_prefetch))
         : (release_valid1 & req_cboClean & cmo_cbo & dirResult_meta_prefetch))
    : mp_probeack_valid ? (~snpToN & dirResult_meta_prefetch)
                        : (~mp_dct_valid & dirResult_meta_prefetch);
// prefetchSrc: 从 reqSource 映射 (PfSource.fromMemReqSource)
assign io_tasks_mainpipe_bits_meta_prefetchSrc =
  mp_is_writeGrp
    ? (mp_grant_valid
         ? ((req_reqSource == 5'h8) ? 3'h2 :
            (req_reqSource == 5'h9) ? 3'h3 :
            (req_reqSource == 5'hA) ? 3'h1 :
            (req_reqSource == 5'hD) ? 3'h6 :
            (req_reqSource == 5'hB) ? 3'h4 :
            (req_reqSource == 5'hC) ? 3'h5 : 3'h0)
         : (mp_release_cmo ? dirResult_meta_prefetchSrc : 3'h0))
    : mp_probe_or_dct ? 3'h0 : dirResult_meta_prefetchSrc;
assign io_tasks_mainpipe_bits_meta_accessed =
  mp_is_writeGrp
    ? (mp_grant_valid ? acq_or_get : (release_valid1 & req_cboClean & cmo_cbo & dirResult_meta_accessed))
    : mp_probeack_valid ? (~snpToN & dirResult_meta_accessed)
                        : (~mp_dct_valid & dirResult_meta_accessed);
assign io_tasks_mainpipe_bits_meta_tagErr =
  mp_is_writeGrp
    ? (~mp_grant_valid & release_valid1 & req_cboClean & cmo_cbo & dirResult_meta_tagErr)
    : (~mp_probe_or_dct & dirResult_meta_tagErr);
assign io_tasks_mainpipe_bits_meta_dataErr =
  mp_is_writeGrp
    ? (~mp_grant_valid & release_valid1 & req_cboClean & cmo_cbo & dirResult_meta_dataErr)
    : (~mp_probe_or_dct & dirResult_meta_dataErr);

// ===================== 写使能 / 任务标志 =====================
assign io_tasks_mainpipe_bits_metaWen =
  mp_is_writeGrp
    ? (mp_grant_valid ? (~cmo_cbo & ~denied) : (release_valid1 & cmo_cbo))
    : mp_probeack_valid ? ~req_snpHitReleaseToInval : ~mp_dct_valid;
assign io_tasks_mainpipe_bits_tagWen = mp_is_grant & ~cmo_cbo & ~dirResult_hit & ~denied;
assign io_tasks_mainpipe_bits_dsWen =
  mp_is_writeGrp
    ? (mp_grant_valid
         ? ((gotGrantData | (probeDirty & (req_get | req_aliasTask))) & ~denied)
         : (release_valid1 & (~cmo_cbo | probeDirty)))
    : (mp_probeack_valid & mp_probeack_dsWen);
assign io_tasks_mainpipe_bits_replTask =
  mp_is_writeGrp & (mp_grant_valid ? (~dirResult_hit & ~state_w_replResp & ~denied)
                                   : (release_valid1 & ~cmo_cbo));
assign io_tasks_mainpipe_bits_cmoTask = cmo_cbo;
assign io_tasks_mainpipe_bits_reqSource = req_reqSource;

// ===================== aMergeTask =====================
assign io_tasks_mainpipe_bits_mergeA = mp_is_grant & (mergeA | io_aMergeTask_valid);
assign io_tasks_mainpipe_bits_aMergeTask_off =
  mp_is_grant ? (io_aMergeTask_valid ? io_aMergeTask_bits_off : merge_task_r_off) : 6'h0;
assign io_tasks_mainpipe_bits_aMergeTask_alias = mp_is_grant ? merge_alias : 2'h0;
assign io_tasks_mainpipe_bits_aMergeTask_vaddr =
  mp_is_grant ? (io_aMergeTask_valid ? io_aMergeTask_bits_vaddr : merge_task_r_vaddr) : 44'h0;
assign io_tasks_mainpipe_bits_aMergeTask_isKeyword =
  mp_is_grant & (io_aMergeTask_valid ? io_aMergeTask_bits_isKeyword : merge_task_r_isKeyword);
// odOpGen 结果先存 wire 再取低 3 位 (Formality 的 Verilog reader 不接受 函数调用直接下标)
wire [3:0] merge_odop = odOpGen(merge_opcode);
assign io_tasks_mainpipe_bits_aMergeTask_opcode = mp_is_grant ? merge_odop[2:0] : 3'h0;
assign io_tasks_mainpipe_bits_aMergeTask_param =
  (~mp_is_grant | (merge_param == NtoT) | (merge_param == BtoT))
    ? 3'h0
    : (merge_param == NtoB) ? GRANT_PARAM_DEF : merge_param;
assign io_tasks_mainpipe_bits_aMergeTask_sourceId =
  mp_is_grant ? (io_aMergeTask_valid ? io_aMergeTask_bits_sourceId : merge_task_r_sourceId) : 7'h0;
assign io_tasks_mainpipe_bits_aMergeTask_meta_dirty = mp_is_grant & (gotDirty | hitDirty);
// merge meta.state: promoteT|needT(merge) ? TRUNK : BRANCH (用 merge_opcode/param 算 needT)
wire merge_needT = ~merge_opcode[2]
                 | ((merge_opcode == Hint) & (merge_param == 3'h1))
                 | (((merge_opcode == AcquireBlock) | (merge_opcode == AcquirePerm)) & (|merge_param));
assign io_tasks_mainpipe_bits_aMergeTask_meta_state =
  mp_is_grant ? ((req_promoteT | merge_needT) ? TRUNK : BRANCH) : 2'h0;
assign io_tasks_mainpipe_bits_aMergeTask_meta_clients = mp_is_writeGrp & mp_grant_valid;
assign io_tasks_mainpipe_bits_aMergeTask_meta_alias = mp_is_grant ? merge_alias : 2'h0;
assign io_tasks_mainpipe_bits_aMergeTask_meta_accessed = mp_is_writeGrp & mp_grant_valid;

// ===================== snpHitRelease 透传 =====================
assign io_tasks_mainpipe_bits_snpHitRelease = ~mp_is_writeGrp & req_snpHitRelease;
assign io_tasks_mainpipe_bits_snpHitReleaseToInval = ~mp_is_writeGrp & req_snpHitReleaseToInval;
assign io_tasks_mainpipe_bits_snpHitReleaseToClean = ~mp_is_writeGrp & req_snpHitReleaseToClean;
assign io_tasks_mainpipe_bits_snpHitReleaseWithData = ~mp_is_writeGrp & req_snpHitReleaseWithData;
assign io_tasks_mainpipe_bits_snpHitReleaseIdx = mp_is_writeGrp ? 8'h0 : req_snpHitReleaseIdx;
// snpHitReleaseMeta: 仅 dct 与 cmometaw 路携带原值(probeack 任务不带 Meta 字段, grant 系清零)
//   golden golden-GEN9 = mp_is_writeGrp | mp_probeack_valid; kept = ~golden-GEN9 (= dct 或 cmometaw)
wire mp_keep_snpMeta = ~(mp_is_writeGrp | mp_probeack_valid);
assign io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty   = mp_keep_snpMeta & req_snpHitReleaseMeta_dirty;
assign io_tasks_mainpipe_bits_snpHitReleaseMeta_state   = mp_keep_snpMeta ? req_snpHitReleaseMeta_state : 2'h0;
assign io_tasks_mainpipe_bits_snpHitReleaseMeta_clients = mp_keep_snpMeta & req_snpHitReleaseMeta_clients;
assign io_tasks_mainpipe_bits_snpHitReleaseMeta_alias   = mp_keep_snpMeta ? req_snpHitReleaseMeta_alias : 2'h0;
assign io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch= mp_keep_snpMeta & req_snpHitReleaseMeta_prefetch;
assign io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc = mp_keep_snpMeta ? req_snpHitReleaseMeta_prefetchSrc : 3'h0;
assign io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed= mp_keep_snpMeta & req_snpHitReleaseMeta_accessed;
assign io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr  = mp_keep_snpMeta & req_snpHitReleaseMeta_tagErr;
assign io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr = mp_keep_snpMeta & req_snpHitReleaseMeta_dataErr;

// ===================== CHI 路由字段 =====================
assign io_tasks_mainpipe_bits_tgtID =
  mp_is_writeGrp
    ? (mp_grantOrRelease ? 11'h0 : tgtid_wcompack)
    : mp_probeack_valid ? req_srcID : mp_dct_valid ? req_fwdNID : 11'h0;
assign io_tasks_mainpipe_bits_txnID =
  mp_is_writeGrp
    ? (mp_grant_valid ? 12'h0 : release_valid1 ? mp_release_txnID : txnid_wcompack)
    : mp_probeack_valid ? req_txnID : mp_dct_valid ? req_fwdTxnID : 12'h0;
// homeNID: 只有 dct 路携带 req_srcID; (golden-GEN9 = mp_is_writeGrp | mp_probeack_valid)
assign io_tasks_mainpipe_bits_homeNID =
  ((mp_is_writeGrp | mp_probeack_valid) | ~mp_dct_valid) ? 11'h0 : req_srcID;
assign io_tasks_mainpipe_bits_dbID = (mp_is_writeGrp | ~mp_probe_or_dct) ? 12'h0 : req_txnID;
assign io_tasks_mainpipe_bits_chiOpcode = io_tasks_mainpipe_bits_chiOpcode_w;
assign io_tasks_mainpipe_bits_resp = io_tasks_mainpipe_bits_resp_w;
assign io_tasks_mainpipe_bits_fwdState = io_tasks_mainpipe_bits_fwdState_w;
assign io_tasks_mainpipe_bits_retToSrc =
  mp_is_writeGrp ? (~mp_grant_valid & req_retToSrc) : (mp_probeack_valid & req_retToSrc);
assign io_tasks_mainpipe_bits_likelyshared =
  mp_is_writeGrp & ~mp_grant_valid & release_valid1 & ~cmo_cbo & isWriteEvictOrEvict & (dirResult_meta_state == BRANCH);
assign io_tasks_mainpipe_bits_expCompAck =
  mp_is_writeGrp & ~mp_grant_valid & release_valid1 & isWriteEvictOrEvict;
assign io_tasks_mainpipe_bits_allowRetry =
  mp_is_writeGrp & ~mp_grant_valid & release_valid1 & state_s_reissue;
assign io_tasks_mainpipe_bits_memAttr_allocate =
  mp_is_writeGrp & ~mp_grant_valid & release_valid1 & ~cmo_cbo & ~isEvict;
assign io_tasks_mainpipe_bits_memAttr_cacheable =
  mp_is_writeGrp & ~mp_grant_valid & release_valid1;
assign io_tasks_mainpipe_bits_memAttr_ewa =
  mp_is_writeGrp & ~mp_grant_valid & release_valid1;
assign io_tasks_mainpipe_bits_traceTag =
  mp_is_writeGrp ? (~mp_grantOrRelease & cbWrDataTraceTag) : (mp_probe_or_dct & req_traceTag);
assign io_tasks_mainpipe_bits_dataCheckErr = mp_is_grant & dataCheckErr;

// ===================== mainpipe opcode / chiOpcode / resp / fwdState =====================
// opcode: 仅 grant 用 odOpGen, 其余 0
assign io_tasks_mainpipe_bits_opcode_w = mp_is_grant ? mp_grant_opcode : 4'h0;
// chiOpcode: grant->0; release->mp_release_chiOpcode; cbwrdata->CopyBackWrData(2);
//            probeack-> SnpResp/SnpRespFwded/SnpRespData/SnpRespDataFwded; dct->CompData(4); cmometaw->0
assign io_tasks_mainpipe_bits_chiOpcode_w =
  mp_is_writeGrp
    ? (mp_grant_valid ? 7'h0 : release_valid1 ? mp_release_chiOpcode : CopyBackWrData)
    : mp_probeack_valid
        ? {2'h0,
           (&mp_probeack_chiOpcode_sel) ? 5'h6                         // {1,1}->SnpRespDataFwded(6)
           : (mp_probeack_chiOpcode_sel == 2'h1) ? 5'h1                // {0,1}->SnpRespData(1)
           : {1'h0, (mp_probeack_chiOpcode_sel == 2'h2), 3'h1}}        // {1,0}->SnpRespFwded(9)? else SnpResp(1)
        : {4'h0, mp_dct_valid, 2'h0};                                  // dct->CompData(4)
// resp (probeack): respCacheState 的压平 + passDirty(bit2) OR。
//   snpToN/tagErr/snpToB 走第一支; SnpOnceX 走第二支; SnpStash/SnpQuery 走 dirty?UD:metaChi;
//   其余(snpToB 已被前支吃掉)走 isSnpCleanShared?(isT?UC:metaChi)。
//   golden 把 isSnpCleanShared 分支压成 "state[1]?2'h2:metaChi"(SnpCleanShared 时 isT->UC)。
wire probeack_isSnpOnceX = isSnpOnce_v | isSnpOnceFwd_v;
wire probeack_isStashOrQuery = (req_chiOpcode == SnpStashUnique)   // 0xB
                             | (req_chiOpcode == SnpStashShared)   // 0xC
                             | (req_chiOpcode == 7'h10);            // SnpQuery
assign io_tasks_mainpipe_bits_resp_w =
  mp_is_writeGrp
    ? (mp_grantOrRelease ? 3'h0 : {dirResult_meta_dirty, metaChi_bit1, metaChi_is_SC})  // cbwrdata: setPD(metaChi,dirty)
    : mp_probeack_valid
        ? (((snpToN | tagErr) | snpToB)
             ? {2'h0, ~((snpToN | tagErr) | req_snpHitReleaseToInval)}
             : probeack_isSnpOnceX
                 ? (req_snpHitReleaseToInval ? 3'h0
                    : req_snpHitReleaseToClean ? (req_snpHitReleaseMeta_dirty ? CHI_SC : metaChi)
                    : (dirResult_meta_dirty ? 3'h2 : metaChi))
                 : ((probeack_isStashOrQuery ? dirResult_meta_dirty : dirResult_meta_state[1]) ? 3'h2 : metaChi))
          | {mp_probeack_resp_pd, 2'h0}
        : mp_dct_valid ? (fwdCacheState | mp_dct_resp_pd) : 3'h0;
assign io_tasks_mainpipe_bits_fwdState_w =
  (mp_is_writeGrp | ~mp_probeack_valid) ? 3'h0 : (fwdCacheState | mp_dct_resp_pd);
