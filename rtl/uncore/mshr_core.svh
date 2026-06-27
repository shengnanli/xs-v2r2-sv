// =============================================================================
//  mshr_core.svh —— xs_MSHR_core 的核心逻辑 (被 MSHR.sv include)
//  分为五大块: ① 寄存器声明 ② 组合"附魔"译码 ③ 任务 valid/bits 生成
//             ④ 任务握手与响应驱动的状态机更新(时序) ⑤ status/msInfo/nestedwb 输出
//  全部对照 MSHR.scala 重写, 命名取语义名(非 golden 临时名)。
// =============================================================================

// =========================== ① 状态寄存器 ===================================
// --- 数据/进度标志 ---
logic        gotT;          // 下层(L3)给了 T 权限(即便本级只想要 B)
logic        gotDirty;      // 收到了 dirty 数据
logic        gotGrantData;  // 收到了 grant 数据(CompData)
logic        probeDirty;    // 上层 ProbeAckData 带回了脏
logic        releaseDirty;  // 嵌套 C 把脏写进了本 MSHR 的 releaseBuf
logic [63:0] timer;         // 性能计时
logic        beatCnt;       // beat 计数(beatSize=2 -> 1bit)

// --- req: 当前事务请求(TaskBundle 的子集) ---
logic        req_valid;
logic [2:0]  req_channel;
logic [8:0]  req_set;
logic [30:0] req_tag;
logic [5:0]  req_off;
logic [1:0]  req_alias;
logic        req_isKeyword;
logic [3:0]  req_opcode;
logic [2:0]  req_param;
logic [6:0]  req_sourceId;
logic        req_aliasTask;
logic        req_fromL2pft;
logic [4:0]  req_reqSource;
logic        req_snpHitRelease;
logic        req_snpHitReleaseToInval;
logic        req_snpHitReleaseToClean;
logic        req_snpHitReleaseWithData;
logic [7:0]  req_snpHitReleaseIdx;
logic        req_snpHitReleaseMeta_dirty;
logic [1:0]  req_snpHitReleaseMeta_state;
logic        req_snpHitReleaseMeta_clients;
logic [1:0]  req_snpHitReleaseMeta_alias;
logic        req_snpHitReleaseMeta_prefetch;
logic [2:0]  req_snpHitReleaseMeta_prefetchSrc;
logic        req_snpHitReleaseMeta_accessed;
logic        req_snpHitReleaseMeta_tagErr;
logic        req_snpHitReleaseMeta_dataErr;
logic [10:0] req_srcID;
logic [11:0] req_txnID;
logic [10:0] req_fwdNID;
logic [11:0] req_fwdTxnID;
logic [6:0]  req_chiOpcode;
logic        req_retToSrc;
logic        req_traceTag;

// --- dirResult: 分配时的目录查询结果(可被响应/嵌套改写) ---
logic        dirResult_hit;
logic [30:0] dirResult_tag;
logic [8:0]  dirResult_set;
logic [2:0]  dirResult_way;
logic        dirResult_meta_dirty;       // meta.dirty
logic [1:0]  dirResult_meta_state;       // meta.state (I/B/T/Tip)
logic        dirResult_meta_clients;     // meta.clients (1bit, clientBits=1)
logic [1:0]  dirResult_meta_alias;
logic        dirResult_meta_prefetch;
logic [2:0]  dirResult_meta_prefetchSrc;
logic        dirResult_meta_accessed;
logic        dirResult_meta_tagErr;
logic        dirResult_meta_dataErr;

// --- state: FSMState (s_*/w_* 标志) ---
logic        state_s_acquire;
logic        state_s_rprobe;
logic        state_s_pprobe;
logic        state_s_release;
logic        state_s_probeack;
logic        state_s_refill;
logic        state_s_retry;
logic        state_s_cmoresp;
logic        state_s_cmometaw;
logic        state_w_rprobeackfirst;
logic        state_w_rprobeacklast;
logic        state_w_pprobeackfirst;
logic        state_w_pprobeacklast;
logic        state_w_grantfirst;
logic        state_w_grantlast;
logic        state_w_grant;
logic        state_w_releaseack;
logic        state_w_replResp;
logic        state_s_rcompack;
logic        state_s_wcompack;
logic        state_s_cbwrdata;
logic        state_s_reissue;
logic        state_s_dct;

logic [6:0]  req_released_chiOpcode;  // 已发出 release 的 chiOpcode(重发用)

// --- 重试/CHI credit ---
logic [1:0]  retryTimes;
logic [4:0]  backoffTimer;
logic [10:0] tgtid_rcompack;
logic [11:0] txnid_rcompack;
logic [10:0] tgtid_wcompack;
logic [11:0] txnid_wcompack;
logic [10:0] srcid_retryack;
logic [3:0]  pcrdtype;
logic        gotRetryAck;
logic        gotPCrdGrant;

// --- 错误标志 ---
logic        tagErr;
logic        denied;
logic        corrupt;
logic        dataCheckErr;
logic        cbWrDataTraceTag;

// --- merge / blockRefill 打拍 ---
logic        mergeA;
logic [5:0]  merge_task_r_off;
logic [1:0]  merge_task_r_alias;
logic [43:0] merge_task_r_vaddr;
logic        merge_task_r_isKeyword;
logic [3:0]  merge_task_r_opcode;
logic [2:0]  merge_task_r_param;
logic [6:0]  merge_task_r_sourceId;
// blockRefill 三个打拍寄存器 (对应 golden REG/REG_1/REG_2):
//   REG   = RegNext(~s_release), REG_1 = RegNext(~s_release), REG_2 = RegNext(REG_1)
//   输出 blockRefill = ~s_release | REG | REG_2
logic        blockRefill_d1, blockRefill_d1b, blockRefill_d2;
logic [63:0] validCnt;
// CompAck 路由寄存器 (golden 用无复位 Reg, 单独 always 块更新)
// 已在 ① 声明: tgtid_rcompack/txnid_rcompack/tgtid_wcompack/txnid_wcompack/srcid_retryack

// --- 性能计数打拍 ---
logic [63:0] acquire_ts, release_ts;
logic        acquire_period_valid_d;
logic        release_period_valid_d;

// =========================== ② 组合"附魔"译码 ===============================
// meta 字段别名(直接取 dirResult.meta)
wire        meta_pft        = dirResult_meta_prefetch;
wire        meta_no_client  = ~dirResult_meta_clients;

// metaChi: 把 (meta.dirty, meta.state) 映射到 CHI 一致性态
//   {0,INVALID}->I, {0,BRANCH}->SC, {0,TRUNK/TIP}->UC, {1,TRUNK/TIP}->UD
wire [2:0]  meta_dirty_state = {dirResult_meta_dirty, dirResult_meta_state};
wire        metaChi_is_SC = (meta_dirty_state == 3'h1);  // {0,BRANCH}
wire        metaChi_bit1  = (meta_dirty_state == 3'h2) | (meta_dirty_state == 3'h3)
                          | (meta_dirty_state == 3'h6) | (meta_dirty_state == 3'h7);
wire [2:0]  metaChi = {1'h0, metaChi_bit1, metaChi_is_SC};

// req 译码: opcode/param 决定事务类型
wire        req_prefetch    = (req_opcode == Hint);
wire        req_is_acqblk   = (req_opcode == AcquireBlock);
wire        req_acquirePerm = (req_opcode == AcquirePerm);
// needT: 需要独占(T)权限
wire        req_needT = ~req_opcode[2]
                      | (req_prefetch & (req_param == 3'h1))
                      | ((req_is_acqblk | req_acquirePerm) & (|req_param));
wire        req_get     = (req_opcode == Get);
// req_acquire: AcquireBlock(来自 A 通道) 或 AcquirePerm (AcquireBlock 与 Probe 共用 opcode)
wire        req_acquire = (req_is_acqblk & req_channel[0]) | req_acquirePerm;
// acquire|get : 既用于 promoteT, 也是 meta.accessed
wire        acq_or_get  = req_acquire | req_get;

// snoop 分类
wire        snpToN = isSnpToN(req_chiOpcode);
wire        snpToB = isSnpToB(req_chiOpcode);

// CMO (cache block ops)
wire        req_cboClean = req_channel[0] & (req_opcode == CBOClean);
wire        req_cboFlush = req_channel[0] & (req_opcode == CBOFlush);
wire        req_cboInval = req_channel[0] & (req_opcode == CBOInval);
wire        cmo_cbo      = req_cboClean | req_cboFlush | req_cboInval;

// hit/dirty 组合
wire        hitDirty       = dirResult_hit & dirResult_meta_dirty;
wire        snpHitWithData = req_snpHitRelease & req_snpHitReleaseWithData;
wire        hitWriteClean  = snpHitWithData & req_snpHitReleaseMeta_dirty & req_snpHitReleaseToClean;
wire        hitWriteEvict  = snpHitWithData & ~req_snpHitReleaseMeta_dirty;
wire        hitWriteBack   = snpHitWithData & req_snpHitReleaseMeta_dirty & req_snpHitReleaseToInval;
wire        hitWriteDirty  = hitWriteBack | hitWriteClean;
wire        hitDirtyOrWriteDirty = hitDirty | hitWriteDirty;

// snoop opcode 细分类(供 resp/data 判定)
wire isSnpOnce_v        = (req_chiOpcode == SnpOnce);
wire isSnpOnceFwd_v     = (req_chiOpcode == SnpOnceFwd);
wire isSnpOnceX_v       = isSnpOnce_v | isSnpOnceFwd_v;
wire isSnpToBFwd_v      = isSnpToBFwd(req_chiOpcode);
wire isSnpToNFwd_v      = isSnpToNFwd(req_chiOpcode);
wire isSnpToBNonFwd_v   = isSnpToBNonFwd(req_chiOpcode);
wire isSnpToNNonFwd_v   = isSnpToNNonFwd(req_chiOpcode);
wire isSnpXFwd_v        = isSnpXFwd(req_chiOpcode);
wire isSnpCleanShared_v = isSnpCleanShared(req_chiOpcode);
wire isSnpStashX_v      = isSnpStashX(req_chiOpcode);
wire isSnpUnique_v      = (req_chiOpcode == SnpUnique);
wire isSnpUniqueStash_v = (req_chiOpcode == SnpUniqueStash);
wire isSnpCleanInvalid_v= (req_chiOpcode == SnpCleanInvalid);

// doRespData_*: 该 snoop 是否需要回带数据 (SnpRespData 而非 SnpResp)
wire doRespData_dirty = hitDirtyOrWriteDirty &
  (isSnpOnce_v | snpToB | isSnpUnique_v | isSnpUniqueStash_v | isSnpCleanShared_v | isSnpCleanInvalid_v);
wire doRespData_retToSrc_fwd = req_retToSrc & isSnpToBFwd_v;
wire doRespData_retToSrc_nonFwd = req_retToSrc & dirResult_hit & (dirResult_meta_state == BRANCH) &
  (isSnpToBNonFwd_v | isSnpToNNonFwd_v | isSnpOnce_v);
wire doRespData_once =
  ((hitWriteBack | hitWriteClean) & isSnpOnceFwd_v) |
  ((dirResult_hit & ~dirResult_meta_dirty & (dirResult_meta_state != BRANCH)) | hitWriteEvict) & isSnpOnce_v;
wire doRespData = (doRespData_dirty | doRespData_retToSrc_fwd | doRespData_retToSrc_nonFwd | doRespData_once) & ~tagErr;

// doFwd: 该 snoop 是否做转发(SnpResp[Data]Fwded)
wire doFwd           = isSnpXFwd_v & dirResult_hit;
wire hitWriteX       = hitWriteBack | hitWriteClean | hitWriteEvict;
wire doFwdHitRelease = isSnpXFwd_v & hitWriteX;

// promoteT: 即便上层只要 B, 也可以给 T
wire promoteT_normal = dirResult_hit & meta_no_client & (dirResult_meta_state == TIP);
wire promoteT_L3     = ~dirResult_hit & gotT;
wire promoteT_alias  = dirResult_hit & req_aliasTask & ((dirResult_meta_state == TRUNK) | (dirResult_meta_state == TIP));
wire req_promoteT    = (acq_or_get | req_prefetch) & (promoteT_normal | promoteT_L3 | promoteT_alias);

// =========================== ③ 任务 valid ==================================
// release: 第一次(AllowRetry=1)走 mainpipe; 第二次(AllowRetry=0)走 TXREQ
wire release_valid1 =
  (~state_s_release & state_w_rprobeacklast & state_w_grantlast & state_w_grant & state_w_replResp)
  | (~state_s_release & state_w_rprobeacklast & cmo_cbo);
wire release_valid2 = ~state_s_reissue & ~state_w_releaseack & gotRetryAck & gotPCrdGrant;

// txreq.valid: 发 acquire / 重发(协议 retry) / release2
wire io_tasks_txreq_valid_w =
  (~state_s_acquire & ~(cmo_cbo & (~state_w_rprobeacklast | ~state_w_releaseack | ~state_s_cmometaw | ~state_s_cbwrdata)))
  | (~state_s_reissue & ~state_w_grant & gotRetryAck & gotPCrdGrant)
  | release_valid2;

// txrsp.valid: 读/写事务的 CompAck (afterIssueC: rcompack 等 grantfirst 即可)
wire rcompack_valid = ~state_s_rcompack & state_w_grant & state_w_grantfirst;
wire wcompack_valid = ~state_s_wcompack & state_s_rcompack;
wire io_tasks_txrsp_valid_w = rcompack_valid | wcompack_valid;

// source_b.valid: 还需发 Probe (pprobe / rprobe)
wire io_tasks_source_b_valid_w = ~state_s_pprobe | ~state_s_rprobe;

// mainpipe 各子任务 valid
wire mp_release_valid  = release_valid1;
wire mp_cbwrdata_valid = ~state_s_cbwrdata & state_w_releaseack;
wire mp_probeack_valid = ~state_s_probeack & state_w_pprobeacklast;
wire pending_grant_valid = (~state_s_refill | (~state_s_cmoresp & state_w_releaseack & state_s_cbwrdata))
                         & state_w_grantlast & state_w_grant & state_w_rprobeacklast;
wire mp_grant_valid = pending_grant_valid & ((retryTimes != BACKOFF_THRESHOLD[1:0]) | (backoffTimer == BACKOFF_CYCLES[4:0]));
wire mp_dct_valid   = ~state_s_dct & state_s_probeack;
wire mp_cmometaw_valid = ~state_s_cmometaw;
wire io_tasks_mainpipe_valid_w =
  mp_release_valid | mp_probeack_valid | mp_grant_valid | mp_cbwrdata_valid | mp_dct_valid | mp_cmometaw_valid;

// =========================== ④ CHI resp 用到的派生量 ========================
// respCacheState: snoop 后回报的一致性态 (ParallelPriorityMux)
wire [2:0]  respCacheState =
  (snpToN | tagErr)        ? CHI_I :
  snpToB                   ? (req_snpHitReleaseToInval ? CHI_I : CHI_SC) :
  isSnpOnceX_v             ? (req_snpHitReleaseToInval ? CHI_I :
                              req_snpHitReleaseToClean ? (req_snpHitReleaseMeta_dirty ? CHI_SC : metaChi) :
                              (dirResult_meta_dirty ? CHI_UD : metaChi)) :
  (isSnpStashX_v)          ? (dirResult_meta_dirty ? CHI_UD : metaChi) :
  isSnpCleanShared_v       ? (isT(dirResult_meta_state) ? CHI_UC : metaChi) :
                             3'h0;
wire        respPassDirty = (hitDirtyOrWriteDirty & ~tagErr &
                              (snpToB | isSnpUnique_v | isSnpUniqueStash_v | isSnpCleanShared_v | isSnpCleanInvalid_v))
                          | (hitWriteDirty & isSnpOnceFwd_v);
wire [2:0]  fwdCacheState = tagErr ? CHI_I :
                            isSnpToBFwd_v ? CHI_SC :
                            isSnpToNFwd_v ? CHI_UC : CHI_I;
wire        fwdPassDirty   = isSnpToNFwd_v & hitDirtyOrWriteDirty & ~tagErr;

// =========================== ⑤ 握手 fire ===================================
wire txreq_fire     = io_tasks_txreq_ready & io_tasks_txreq_valid_w;
wire txrsp_fire     = io_tasks_txrsp_ready & io_tasks_txrsp_valid_w;
wire source_b_fire  = io_tasks_source_b_ready & io_tasks_source_b_valid_w;
wire mainpipe_ready = io_tasks_mainpipe_ready;

// =========================== ⑥ TXREQ opcode / WriteX 分类 ===================
// release2 的 WriteX 类型: CMO/状态决定 WriteCleanFull/WriteBackFull/WriteEvictOrEvict/Evict
wire isWriteBackFull   = ~req_cboClean & ~req_cboInval & isT(dirResult_meta_state) & dirResult_meta_dirty;
wire isWriteEvictOrEvict= ~req_cboFlush & ~req_cboInval & ~req_cboClean & ~isWriteBackFull;  // afterIssueEb
wire isEvict           = ~req_cboClean & ~isWriteBackFull & ~isWriteEvictOrEvict;
wire [11:0] mp_release_txnID = {4'h0, io_id};

// txreq opcode: release2 用已保存的; CMO/Acquire/needT/needB 各有目标
wire        a_opcode_is_cboClean_or_flush = req_cboClean | req_cboFlush;
wire [6:0]  io_tasks_txreq_bits_opcode_w =
  (release_valid2 | a_opcode_is_cboClean_or_flush)
    ? (release_valid2 ? req_released_chiOpcode : {6'h4, ~req_cboClean})  // CleanShared(8)/CleanInvalid(9)
    : (req_cboInval | req_acquirePerm)
        ? (req_cboInval ? MakeInvalid : MakeUnique)                       // A / C
        : (req_needT ? ReadUnique : ReadNotSharedDirty);                  // 7 / 0x26
wire        released_is_WEoE = (req_released_chiOpcode == WriteEvictOrEvict);

// mp_release chiOpcode: 普通/CMO 分支
wire [6:0]  mp_release_chiOpcode =
  cmo_cbo
    ? (req_cboClean ? WriteCleanFull : (req_cboFlush & isWriteBackFull) ? WriteBackFull : Evict_CHI)
    : (isWriteBackFull ? WriteBackFull : isWriteEvictOrEvict ? WriteEvictOrEvict : Evict_CHI);

// =========================== ⑦ mainpipe 6 路优先选择(基础控制量) ============
// 优先级(对齐 Scala ParallelPriorityMux): grant > release > cbwrdata > probeack > dct > cmometaw
wire mp_is_writeGrp = mp_grant_valid | release_valid1 | mp_cbwrdata_valid;  // grant/release/cbwrdata
wire mp_is_grant    = mp_is_writeGrp & mp_grant_valid;                       // 选中 grant
wire mp_release_cmo = release_valid1 & req_cboClean;                         // release 且 cboClean
wire mp_probe_or_dct= mp_probeack_valid | mp_dct_valid;
wire mp_probeack_dsWen = ~(snpToN | tagErr) & probeDirty & ~releaseDirty;

// txChannel: grant->channel-A(0); release->TXREQ(1); cbwrdata->TXDAT(4);
//            probeack-> doRespData?TXDAT(4):TXRSP(2); dct->TXDAT(4); cmometaw->0
wire [2:0]  io_tasks_mainpipe_bits_txChannel_w =
  mp_is_writeGrp
    ? (mp_grant_valid ? 3'h0 : release_valid1 ? 3'h1 : 3'h4)
    : mp_probeack_valid ? (doRespData ? 3'h4 : 3'h2) : {mp_dct_valid, 2'h0};

// odOpGen 查表 (A.opcode -> D.opcode)
wire [3:0]  mp_grant_opcode = odOpGen(req_opcode);
wire        aliasFinal_use_meta = req_get | req_prefetch;
wire [2:0]  GRANT_PARAM_DEF = {2'h0, ~req_promoteT};   // NtoB: promoteT?toT(0):toB(1)
wire [1:0]  mp_grant_alias = aliasFinal_use_meta ? dirResult_meta_alias : req_alias;

`include "mshr_mainpipe.svh"
`include "mshr_seq.svh"
`include "mshr_outputs.svh"
