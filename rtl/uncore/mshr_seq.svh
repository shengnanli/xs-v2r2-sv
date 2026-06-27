// =============================================================================
//  mshr_seq.svh —— xs_MSHR_core 的时序状态机 (next-state 计算 + 寄存器提交)
//  严格按 MSHR.scala 的 when 块顺序应用 (Chisel last-connect-wins => 后面的赋值覆盖前面)
//  顺序:
//    [A] alloc          : 分配新事务, 给 req/dirResult/state 初值, 清各标志
//    [B] task fire       : txreq/txrsp/source_b/mainpipe 握手成功 -> 置 s_* 标志
//    [C] c_resp(sinkC)   : ProbeAck/ProbeAckData -> 置 w_*probeack, 改 meta, CMO release
//    [D] rxdat           : CompData/DataSepResp -> 置 w_grant*, gotT/Dirty/GrantData
//    [E] rxrsp           : Comp/CompDBIDResp/RetryAck/RespSepData -> 置 w_grant/w_releaseack
//    [F] pCrd.grant      : 清 s_reissue
//    [G] replResp        : retry -> 清 s_refill/s_retry; !retry -> 置 w_replResp,改 dir,起 release
//    [H] nestedwb        : 嵌套回写改 meta / dir
//    [I] will_free       : 全部完成 -> req_valid:=0
//  采用 always_comb 算 next + always_ff 提交, 默认 next = 现值(寄存器保持)。
// =============================================================================

// ---- 用到的响应译码 ----
wire c_is_probeack     = io_resps_sinkC_valid & (io_resps_sinkC_bits_opcode == ProbeAck);
wire c_is_probeackdata = io_resps_sinkC_valid & (io_resps_sinkC_bits_opcode == ProbeAckData);
wire c_is_probeX       = c_is_probeack | c_is_probeackdata;
wire cresp_toN  = io_resps_sinkC_valid & c_isToN(io_resps_sinkC_bits_param);
wire cresp_toB  = io_resps_sinkC_valid & c_isToB(io_resps_sinkC_bits_param);
wire cresp_fromT= io_resps_sinkC_valid & c_isParamFromT(io_resps_sinkC_bits_param);

wire rxdat_isCompData    = io_resps_rxdat_valid & (io_resps_rxdat_bits_chiOpcode == CompData);
wire rxdat_isDataSepResp = io_resps_rxdat_valid & (io_resps_rxdat_bits_chiOpcode == DataSepResp);
wire rxdat_grantEvt      = rxdat_isCompData | rxdat_isDataSepResp;  // 二者都更新 grant/gotT
wire rxdatIsU    = (io_resps_rxdat_bits_resp == CHI_UC);
wire rxdatIsU_PD = (io_resps_rxdat_bits_resp == CHI_UC_PD);
wire rxdat_nderr = (io_resps_rxdat_bits_respErr == RESP_NDERR);
wire rxdat_derr  = (io_resps_rxdat_bits_respErr == RESP_DERR);

wire rxrsp_isComp       = io_resps_rxrsp_valid & (io_resps_rxrsp_bits_chiOpcode == Comp);          // 0x4
wire rxrsp_isCompDBID   = io_resps_rxrsp_valid & (io_resps_rxrsp_bits_chiOpcode == CompDBIDResp);  // 0x5
wire rxrsp_isRetryAck   = io_resps_rxrsp_valid & (io_resps_rxrsp_bits_chiOpcode == RetryAck);      // 0x3
wire rxrsp_isRespSepData= io_resps_rxrsp_valid & (io_resps_rxrsp_bits_chiOpcode == RespSepData);   // 0xB
wire rxrspIsU = (io_resps_rxrsp_bits_resp == CHI_UC);
wire rxrsp_nderr = (io_resps_rxrsp_bits_respErr == RESP_NDERR);
// Comp 的两个子条件
wire comp_grantOK    = ~state_w_grant & (state_s_cmoresp | state_w_releaseack);   // pending Read 等 Comp
wire comp_releaseOK  = ~state_w_releaseack;                                       // pending Evict/WEoE 等 Comp

wire replResp_retry   = io_replResp_valid & io_replResp_bits_retry;
wire replResp_done    = io_replResp_valid & ~io_replResp_bits_retry;

// ---- nestedwb 嵌套回写匹配 ----
wire nestedwb_addr_match = (dirResult_set == io_nestedwb_set) & (dirResult_tag == io_nestedwb_tag);
wire req_mayRepl = acq_or_get | req_prefetch;
wire nestedwb_match = req_valid & (|dirResult_meta_state) & nestedwb_addr_match & state_w_replResp
                    & (state_s_cmoresp | dirResult_hit) & (req_mayRepl | dirResult_hit);
wire nestedwb_hit_match = req_valid & dirResult_hit & nestedwb_addr_match;
// nestedwb_match 的子动作 (req.fromA = req_channel[0])
wire nwb_c_set_dirty = nestedwb_match & io_nestedwb_c_set_dirty;
wire nwb_c_set_tip   = nestedwb_match & io_nestedwb_c_set_tip;
wire nwb_b_inv_dirty = nestedwb_match & io_nestedwb_b_inv_dirty & req_channel[0];
// nestedwb_hit_match 的子动作
wire nwbh_b_toClean  = nestedwb_hit_match & io_nestedwb_b_toClean & req_channel[0];
wire nwbh_b_toB      = nestedwb_hit_match & io_nestedwb_b_toB & req_channel[0];
wire nwbh_b_toN      = nestedwb_hit_match & io_nestedwb_b_toN & req_channel[0];

// will_free / no_schedule / no_wait
wire no_schedule = state_s_refill & state_s_probeack & state_s_release & state_s_rcompack
                 & state_s_wcompack & state_s_cbwrdata & state_s_reissue & state_s_dct
                 & state_s_cmoresp & state_s_cmometaw;
wire no_wait = state_w_rprobeacklast & state_w_pprobeacklast & state_w_grantlast & state_w_grant
             & state_w_releaseack & state_w_replResp;
wire will_free = no_schedule & no_wait;

// =============================================================================
//  next-state 组合块
// =============================================================================
// --- 标志位 next ---
logic n_gotT, n_gotDirty, n_gotGrantData, n_probeDirty, n_releaseDirty;
logic [63:0] n_timer;
logic n_beatCnt;
logic n_req_valid;
logic [1:0] n_dirResult_meta_state;
logic n_dirResult_meta_dirty, n_dirResult_meta_clients;
logic n_dirResult_hit;
logic [30:0] n_dirResult_tag;
logic [2:0]  n_dirResult_way;
logic [1:0]  n_dirResult_meta_alias;
logic n_dirResult_meta_prefetch, n_dirResult_meta_accessed, n_dirResult_meta_tagErr, n_dirResult_meta_dataErr;
logic [2:0]  n_dirResult_meta_prefetchSrc;
logic n_tagErr, n_denied, n_corrupt, n_dataCheckErr, n_cbWrDataTraceTag;
logic n_gotRetryAck, n_gotPCrdGrant;
logic [3:0] n_pcrdtype;
logic [1:0] n_retryTimes;
logic [4:0] n_backoffTimer;
logic [6:0] n_req_released_chiOpcode;
logic n_req_traceTag;
logic n_req_aliasTask;

// state next
logic n_s_acquire, n_s_rprobe, n_s_pprobe, n_s_release, n_s_probeack, n_s_refill, n_s_retry;
logic n_s_cmoresp, n_s_cmometaw, n_s_rcompack, n_s_wcompack, n_s_cbwrdata, n_s_reissue, n_s_dct;
logic n_w_rprobeackfirst, n_w_rprobeacklast, n_w_pprobeackfirst, n_w_pprobeacklast;
logic n_w_grantfirst, n_w_grantlast, n_w_grant, n_w_releaseack, n_w_replResp;

always_comb begin
  // ---------- 默认: 保持现值 ----------
  n_gotT = gotT; n_gotDirty = gotDirty; n_gotGrantData = gotGrantData;
  n_probeDirty = probeDirty; n_releaseDirty = releaseDirty;
  n_timer = timer; n_beatCnt = beatCnt; n_req_valid = req_valid;
  n_dirResult_meta_state = dirResult_meta_state;
  n_dirResult_meta_dirty = dirResult_meta_dirty;
  n_dirResult_meta_clients = dirResult_meta_clients;
  n_dirResult_hit = dirResult_hit; n_dirResult_tag = dirResult_tag; n_dirResult_way = dirResult_way;
  n_dirResult_meta_alias = dirResult_meta_alias;
  n_dirResult_meta_prefetch = dirResult_meta_prefetch;
  n_dirResult_meta_accessed = dirResult_meta_accessed;
  n_dirResult_meta_tagErr = dirResult_meta_tagErr;
  n_dirResult_meta_dataErr = dirResult_meta_dataErr;
  n_dirResult_meta_prefetchSrc = dirResult_meta_prefetchSrc;
  n_tagErr = tagErr; n_denied = denied; n_corrupt = corrupt;
  n_dataCheckErr = dataCheckErr; n_cbWrDataTraceTag = cbWrDataTraceTag;
  n_gotRetryAck = gotRetryAck; n_gotPCrdGrant = gotPCrdGrant; n_pcrdtype = pcrdtype;
  n_retryTimes = retryTimes; n_backoffTimer = backoffTimer;
  n_req_released_chiOpcode = req_released_chiOpcode;
  n_req_traceTag = req_traceTag;
  n_req_aliasTask = req_aliasTask;

  n_s_acquire = state_s_acquire; n_s_rprobe = state_s_rprobe; n_s_pprobe = state_s_pprobe;
  n_s_release = state_s_release; n_s_probeack = state_s_probeack; n_s_refill = state_s_refill;
  n_s_retry = state_s_retry; n_s_cmoresp = state_s_cmoresp; n_s_cmometaw = state_s_cmometaw;
  n_s_rcompack = state_s_rcompack; n_s_wcompack = state_s_wcompack; n_s_cbwrdata = state_s_cbwrdata;
  n_s_reissue = state_s_reissue; n_s_dct = state_s_dct;
  n_w_rprobeackfirst = state_w_rprobeackfirst; n_w_rprobeacklast = state_w_rprobeacklast;
  n_w_pprobeackfirst = state_w_pprobeackfirst; n_w_pprobeacklast = state_w_pprobeacklast;
  n_w_grantfirst = state_w_grantfirst; n_w_grantlast = state_w_grantlast; n_w_grant = state_w_grant;
  n_w_releaseack = state_w_releaseack; n_w_replResp = state_w_replResp;

  // ====================== [A] alloc (Scala 最前; 后续 event 块按源序覆盖) =========
  //  注意: alloc 在 Chisel 源码里是第一个 when 块, 故后面的 task.fire/resp/replResp/
  //  nestedwb 都可能"覆盖"alloc 给的值(last-connect-wins)。本块只给初值, 真正的优先级
  //  由后面块决定。alloc 读到的 dirResult/req 是本块刚赋的值? 不: 后面块读 *现值寄存器*,
  //  不读 n_*; 与 Chisel 一致。
  if (io_alloc_valid) begin
    n_req_valid = 1'b1;
    n_s_acquire = io_alloc_bits_state_s_acquire;
    n_s_rprobe  = io_alloc_bits_state_s_rprobe;
    n_s_pprobe  = io_alloc_bits_state_s_pprobe;
    n_s_release = io_alloc_bits_state_s_release;
    n_s_probeack= io_alloc_bits_state_s_probeack;
    n_s_refill  = io_alloc_bits_state_s_refill;
    n_s_retry   = 1'b1;       // s_retry 不在 alloc bundle: golden 用 io_alloc_valid 项置 1
    n_s_cmoresp = io_alloc_bits_state_s_cmoresp;
    n_s_cmometaw= 1'b1;
    n_w_rprobeackfirst = io_alloc_bits_state_w_rprobeackfirst;
    n_w_rprobeacklast  = io_alloc_bits_state_w_rprobeacklast;
    n_w_pprobeackfirst = io_alloc_bits_state_w_pprobeackfirst;
    n_w_pprobeacklast  = io_alloc_bits_state_w_pprobeacklast;
    n_w_grantfirst = io_alloc_bits_state_w_grantfirst;
    n_w_grantlast  = io_alloc_bits_state_w_grantlast;
    n_w_grant      = io_alloc_bits_state_w_grant;
    n_w_releaseack = io_alloc_bits_state_w_releaseack;
    n_w_replResp   = io_alloc_bits_state_w_replResp;
    n_s_rcompack = io_alloc_bits_state_s_rcompack;
    n_s_wcompack = 1'b1;
    n_s_cbwrdata = 1'b1;
    n_s_reissue  = 1'b1;
    n_s_dct      = io_alloc_bits_state_s_dct;
    n_dirResult_hit = io_alloc_bits_dirResult_hit;
    n_dirResult_tag = io_alloc_bits_dirResult_tag;
    n_dirResult_way = io_alloc_bits_dirResult_way;
    n_dirResult_meta_dirty    = io_alloc_bits_dirResult_meta_dirty;
    n_dirResult_meta_state    = io_alloc_bits_dirResult_meta_state;
    n_dirResult_meta_clients  = io_alloc_bits_dirResult_meta_clients;
    n_dirResult_meta_alias    = io_alloc_bits_dirResult_meta_alias;
    n_dirResult_meta_prefetch = io_alloc_bits_dirResult_meta_prefetch;
    n_dirResult_meta_prefetchSrc = io_alloc_bits_dirResult_meta_prefetchSrc;
    n_dirResult_meta_accessed = io_alloc_bits_dirResult_meta_accessed;
    n_dirResult_meta_tagErr   = io_alloc_bits_dirResult_meta_tagErr;
    n_dirResult_meta_dataErr  = io_alloc_bits_dirResult_meta_dataErr;
    n_gotT = 1'b0; n_gotDirty = 1'b0; n_gotGrantData = 1'b0;
    n_probeDirty = 1'b0; n_releaseDirty = 1'b0;
    n_timer = 64'h1; n_beatCnt = 1'b0;
    n_gotRetryAck = 1'b0; n_gotPCrdGrant = 1'b0; n_pcrdtype = 4'h0;
    n_tagErr = io_alloc_bits_dirResult_hit & (io_alloc_bits_dirResult_meta_tagErr | io_alloc_bits_dirResult_error);
    n_denied = 1'b0; n_corrupt = 1'b0; n_dataCheckErr = 1'b0; n_cbWrDataTraceTag = 1'b0;
    // retryTimes/backoffTimer 的 alloc 复位放到统一优先块(见末尾), 那里 golden 优先级是
    // replResp_retry(增/清) > pending-自增 > alloc(清), 不能在此简单覆盖。
    n_req_traceTag = io_alloc_bits_task_traceTag;
    n_req_aliasTask = io_alloc_bits_task_aliasTask;
  end

  // ====================== [B] task fire (s_* 置位) ======================
  if (txreq_fire) begin
    // CMO 的 acquire 部分也可能被重试: cmo 时 s_acquire 取决于 w_releaseack
    n_s_acquire = cmo_cbo ? (state_s_acquire | state_w_releaseack) : 1'b1;
    if (~state_s_reissue) begin
      n_s_reissue = 1'b1; n_gotRetryAck = 1'b0; n_gotPCrdGrant = 1'b0;
    end
  end
  if (txrsp_fire) begin
    if (rcompack_valid) n_s_rcompack = 1'b1;
    if (wcompack_valid) n_s_wcompack = 1'b1;
  end
  if (source_b_fire) begin
    n_s_pprobe = 1'b1; n_s_rprobe = 1'b1;
  end
  if (mainpipe_ready) begin
    if (mp_grant_valid) begin
      n_s_refill = 1'b1; n_s_retry = 1'b1;
      if (mp_grant_opcode == CBOAck) n_s_cmoresp = 1'b1;
    end else if (release_valid1) begin
      n_req_released_chiOpcode = mp_release_chiOpcode;
      n_s_release = 1'b1;
      n_s_cbwrdata = isEvict;
      if (isEvict) begin n_dirResult_meta_state = INVALID; n_dirResult_meta_dirty = 1'b0; end
    end else if (mp_cbwrdata_valid) begin
      n_s_cbwrdata = 1'b1; n_dirResult_meta_state = INVALID; n_dirResult_meta_dirty = 1'b0;
    end else if (mp_probeack_valid) begin
      n_s_probeack = 1'b1;
    end else if (mp_dct_valid) begin
      n_s_dct = 1'b1;
    end else if (mp_cmometaw_valid) begin
      n_s_cmometaw = 1'b1;
    end
  end

  // ====================== [C] c_resp (sinkC: ProbeAck) ======================
  if (c_is_probeX) begin
    n_w_rprobeackfirst = 1'b1;
    n_w_rprobeacklast  = state_w_rprobeacklast | io_resps_sinkC_bits_last;
    n_w_pprobeackfirst = 1'b1;
    n_w_pprobeacklast  = state_w_pprobeacklast | io_resps_sinkC_bits_last;
  end
  if (c_is_probeackdata) begin
    n_probeDirty = 1'b1; n_dirResult_meta_dirty = 1'b1;
  end
  if (cresp_toN) begin
    n_dirResult_meta_state = isT(dirResult_meta_state) ? TIP : dirResult_meta_state;
    n_dirResult_meta_clients = 1'b0;
  end
  if (cresp_toB) begin
    n_dirResult_meta_state = isT(dirResult_meta_state) ? TIP : dirResult_meta_state;
  end
  if (cresp_fromT) begin
    n_dirResult_meta_tagErr = io_resps_sinkC_bits_denied;
    n_dirResult_meta_dataErr = io_resps_sinkC_bits_corrupt;
    n_denied = denied | io_resps_sinkC_bits_denied;
    n_corrupt = corrupt | io_resps_sinkC_bits_corrupt;
  end
  // CMO cboClean: ProbeAck/Data 触发 release 或 cmometaw
  //   ★关键: 判定用的 meta.dirty 是"分配前的旧寄存器值"(Chisel read 读寄存器, 不读 alloc pending)。
  //   golden: ProbeAckData -> 清 s_release/w_releaseack 当 w_rprobeackfirst(旧);
  //           ProbeAck     -> 旧 dirty 则清 s_release/w_releaseack, 否则清 s_cmometaw。
  if (io_resps_sinkC_valid & req_cboClean) begin
    if (c_is_probeackdata & state_w_rprobeackfirst) begin
      n_s_release = 1'b0; n_w_releaseack = 1'b0;
    end
    if (c_is_probeack) begin
      if (dirResult_meta_dirty) begin n_s_release = 1'b0; n_w_releaseack = 1'b0; end
      else n_s_cmometaw = 1'b0;
    end
  end

  // ====================== [D] rxdat (CompData/DataSepResp) ======================
  if (rxdat_isDataSepResp) begin  // afterIssueC
    n_beatCnt = beatCnt + 1'b1;
    n_w_grantfirst = 1'b1;
    n_w_grantlast = state_w_grantfirst & (beatCnt == 1'b1);  // beatSize-1 == 1
    n_w_replResp = state_w_replResp | rxdat_nderr;
    n_gotT = rxdatIsU | rxdatIsU_PD;
    n_gotDirty = gotDirty | rxdatIsU_PD;
    n_gotGrantData = 1'b1;
    n_denied = denied | rxdat_nderr;
    n_corrupt = corrupt | rxdat_derr | rxdat_nderr | io_resps_rxdat_bits_corrupt;
    n_dataCheckErr = dataCheckErr | io_resps_rxdat_bits_dataCheckErr;
  end
  if (rxdat_isCompData) begin
    n_w_grantfirst = 1'b1;
    n_w_grantlast = state_w_grantfirst;  // beatSize=2 一拍收完
    n_w_grant = 1'b1;
    n_w_replResp = state_w_replResp | rxdat_nderr;
    n_gotT = rxdatIsU | rxdatIsU_PD;
    n_gotDirty = gotDirty | rxdatIsU_PD;
    n_gotGrantData = 1'b1;
    n_denied = denied | rxdat_nderr;
    n_corrupt = corrupt | rxdat_derr | rxdat_nderr | io_resps_rxdat_bits_corrupt;
    n_dataCheckErr = dataCheckErr | io_resps_rxdat_bits_dataCheckErr;
    n_req_traceTag = req_traceTag | io_resps_rxdat_bits_traceTag;
  end

  // ====================== [E] rxrsp (Comp/CompDBIDResp/RetryAck/RespSepData) ====
  if (rxrsp_isRespSepData) begin  // afterIssueC
    n_w_grant = 1'b1;
    n_w_replResp = state_w_replResp | rxrsp_nderr;
    n_denied = denied | rxrsp_nderr;
    n_req_traceTag = io_resps_rxrsp_bits_traceTag;
  end
  if (rxrsp_isComp) begin
    if (comp_grantOK) begin
      n_w_grantfirst = 1'b1; n_w_grantlast = 1'b1; n_w_grant = 1'b1;
      n_gotT = rxrspIsU; n_gotDirty = 1'b0;
      n_denied = denied | rxrsp_nderr;
      n_req_traceTag = io_resps_rxrsp_bits_traceTag;
    end
    if (comp_releaseOK) begin
      n_w_releaseack = 1'b1;
      if (isWriteEvictOrEvict) begin
        n_req_traceTag = io_resps_rxrsp_bits_traceTag;
        n_s_cbwrdata = 1'b1;
        n_s_wcompack = 1'b0;
      end
    end
  end
  if (rxrsp_isCompDBID) begin
    n_w_releaseack = 1'b1;
    n_cbWrDataTraceTag = io_resps_rxrsp_bits_traceTag;
  end
  if (rxrsp_isRetryAck) begin
    n_pcrdtype = io_resps_rxrsp_bits_pCrdType;
    n_gotRetryAck = 1'b1;
  end

  // ====================== [F] pCrd.grant ======================
  if (io_pCrd_grant) begin
    n_s_reissue = 1'b0; n_gotPCrdGrant = 1'b1;
  end

  // ====================== [G] replResp ======================
  if (replResp_retry) begin
    n_s_refill = 1'b0; n_s_retry = 1'b0;
    n_dirResult_way = io_replResp_bits_way;
    // retryTimes/backoffTimer 在统一优先块里处理(见末尾)
  end
  if (replResp_done) begin
    n_w_replResp = 1'b1;
    n_dirResult_tag = io_replResp_bits_tag;
    n_dirResult_way = io_replResp_bits_way;
    n_dirResult_meta_dirty   = io_replResp_bits_meta_dirty;
    n_dirResult_meta_state   = io_replResp_bits_meta_state;
    n_dirResult_meta_clients = io_replResp_bits_meta_clients;
    n_dirResult_meta_alias   = io_replResp_bits_meta_alias;
    n_dirResult_meta_prefetch= io_replResp_bits_meta_prefetch;
    n_dirResult_meta_prefetchSrc = io_replResp_bits_meta_prefetchSrc;
    n_dirResult_meta_accessed= io_replResp_bits_meta_accessed;
    n_dirResult_meta_tagErr  = io_replResp_bits_meta_tagErr;
    n_dirResult_meta_dataErr = io_replResp_bits_meta_dataErr;
    if (io_replResp_bits_meta_state != INVALID) begin
      n_s_release = 1'b0; n_w_releaseack = 1'b0;
      if (io_replResp_bits_meta_clients) begin
        n_s_rprobe = 1'b0; n_w_rprobeackfirst = 1'b0; n_w_rprobeacklast = 1'b0;
      end
    end
  end

  // ====================== [H] nestedwb ======================
  if (nwb_c_set_dirty) begin
    n_dirResult_meta_dirty = 1'b1; n_dirResult_meta_state = TIP;
    n_dirResult_meta_clients = 1'b0; n_releaseDirty = 1'b1;
  end
  if (nwb_c_set_tip) begin
    n_dirResult_meta_state = TIP; n_dirResult_meta_clients = 1'b0;
  end
  if (nwb_b_inv_dirty) begin
    n_dirResult_meta_dirty = 1'b0; n_dirResult_meta_state = INVALID; n_probeDirty = 1'b0;
  end
  if (nwbh_b_toClean) begin
    n_dirResult_meta_dirty = 1'b0; n_probeDirty = 1'b0;
  end
  if (nwbh_b_toB) begin
    n_dirResult_meta_state = (dirResult_meta_state >= BRANCH) ? BRANCH : INVALID;
  end
  if (nwbh_b_toN) begin
    n_dirResult_meta_state = INVALID; n_dirResult_hit = 1'b0; n_dirResult_meta_clients = 1'b0;
    n_w_replResp = cmo_cbo; n_req_aliasTask = 1'b0;
  end

  // ============ retryTimes / backoffTimer 统一优先块 (golden 末段 else-if 链) ======
  //  retryTimes  : replResp_retry & retryTimes!=3 -> +1 ; else alloc -> 0 ; else keep
  //  backoffTimer: replResp_retry -> 0 ; else (pending & bt<20 & retryTimes==3) -> +1 ;
  //                else alloc -> 0 ; else keep
  //  ★ pending 自增的优先级高于 alloc, 故不能让 alloc 简单清零(golden bug-for-bug)。
  if (replResp_retry & (retryTimes != BACKOFF_THRESHOLD[1:0]))
    n_retryTimes = retryTimes + 2'h1;
  else if (io_alloc_valid)
    n_retryTimes = 2'h0;
  else
    n_retryTimes = retryTimes;

  if (replResp_retry)
    n_backoffTimer = 5'h0;
  else if (pending_grant_valid & (backoffTimer < BACKOFF_CYCLES[4:0]) & (retryTimes == BACKOFF_THRESHOLD[1:0]))
    n_backoffTimer = backoffTimer + 5'h1;
  else if (io_alloc_valid)
    n_backoffTimer = 5'h0;
  else
    n_backoffTimer = backoffTimer;

  // ====================== [I] timer / will_free (Scala 接近末尾) ==============
  if (req_valid) n_timer = timer + 64'h1;
  if (will_free & req_valid) begin n_req_valid = 1'b0; n_timer = 64'h0; end
end

// =============================================================================
//  寄存器提交 (异步 reset, 与 golden 一致)
// =============================================================================
always_ff @(posedge clock or posedge reset) begin
  if (reset) begin
    gotT <= 1'b0; gotDirty <= 1'b0; gotGrantData <= 1'b0; probeDirty <= 1'b0; releaseDirty <= 1'b0;
    timer <= 64'h0; beatCnt <= 1'b0; req_valid <= 1'b0;
    req_channel <= 3'h0; req_set <= 9'h0; req_tag <= 31'h0; req_off <= 6'h0; req_alias <= 2'h0;
    req_isKeyword <= 1'b0; req_opcode <= 4'h0; req_param <= 3'h0; req_sourceId <= 7'h0;
    req_aliasTask <= 1'b0; req_fromL2pft <= 1'b0; req_reqSource <= 5'h0;
    req_snpHitRelease <= 1'b0; req_snpHitReleaseToInval <= 1'b0; req_snpHitReleaseToClean <= 1'b0;
    req_snpHitReleaseWithData <= 1'b0; req_snpHitReleaseIdx <= 8'h0;
    req_snpHitReleaseMeta_dirty <= 1'b0; req_snpHitReleaseMeta_state <= 2'h0;
    req_snpHitReleaseMeta_clients <= 1'b0; req_snpHitReleaseMeta_alias <= 2'h0;
    req_snpHitReleaseMeta_prefetch <= 1'b0; req_snpHitReleaseMeta_prefetchSrc <= 3'h0;
    req_snpHitReleaseMeta_accessed <= 1'b0; req_snpHitReleaseMeta_tagErr <= 1'b0; req_snpHitReleaseMeta_dataErr <= 1'b0;
    req_srcID <= 11'h0; req_txnID <= 12'h0; req_fwdNID <= 11'h0; req_fwdTxnID <= 12'h0;
    req_chiOpcode <= 7'h0; req_retToSrc <= 1'b0; req_traceTag <= 1'b0;
    dirResult_hit <= 1'b0; dirResult_tag <= 31'h0; dirResult_set <= 9'h0; dirResult_way <= 3'h0;
    dirResult_meta_dirty <= 1'b0; dirResult_meta_state <= 2'h0; dirResult_meta_clients <= 1'b0;
    dirResult_meta_alias <= 2'h0; dirResult_meta_prefetch <= 1'b0; dirResult_meta_prefetchSrc <= 3'h0;
    dirResult_meta_accessed <= 1'b0; dirResult_meta_tagErr <= 1'b0; dirResult_meta_dataErr <= 1'b0;
    state_s_acquire <= 1'b1; state_s_rprobe <= 1'b1; state_s_pprobe <= 1'b1; state_s_release <= 1'b1;
    state_s_probeack <= 1'b1; state_s_refill <= 1'b1; state_s_retry <= 1'b1; state_s_cmoresp <= 1'b1;
    state_s_cmometaw <= 1'b1; state_w_rprobeackfirst <= 1'b1; state_w_rprobeacklast <= 1'b1;
    state_w_pprobeackfirst <= 1'b1; state_w_pprobeacklast <= 1'b1; state_w_grantfirst <= 1'b1;
    state_w_grantlast <= 1'b1; state_w_grant <= 1'b1; state_w_releaseack <= 1'b1; state_w_replResp <= 1'b1;
    state_s_rcompack <= 1'b1; state_s_wcompack <= 1'b1; state_s_cbwrdata <= 1'b1; state_s_reissue <= 1'b1;
    state_s_dct <= 1'b1;
    req_released_chiOpcode <= 7'h0; retryTimes <= 2'h0; backoffTimer <= 5'h0; pcrdtype <= 4'h0;
    gotRetryAck <= 1'b0; gotPCrdGrant <= 1'b0; tagErr <= 1'b0; denied <= 1'b0; corrupt <= 1'b0;
    dataCheckErr <= 1'b0; cbWrDataTraceTag <= 1'b0; mergeA <= 1'b0;
    merge_task_r_off <= 6'h0; merge_task_r_alias <= 2'h0; merge_task_r_vaddr <= 44'h0;
    merge_task_r_isKeyword <= 1'b0; merge_task_r_opcode <= 4'h0; merge_task_r_param <= 3'h0;
    merge_task_r_sourceId <= 7'h0;
    blockRefill_d1 <= 1'b0; blockRefill_d1b <= 1'b0; blockRefill_d2 <= 1'b0; validCnt <= 64'h0;
  end else begin
    gotT <= n_gotT; gotDirty <= n_gotDirty; gotGrantData <= n_gotGrantData;
    probeDirty <= n_probeDirty; releaseDirty <= n_releaseDirty;
    timer <= n_timer; beatCnt <= n_beatCnt; req_valid <= n_req_valid;
    dirResult_hit <= n_dirResult_hit; dirResult_tag <= n_dirResult_tag; dirResult_way <= n_dirResult_way;
    dirResult_meta_dirty <= n_dirResult_meta_dirty; dirResult_meta_state <= n_dirResult_meta_state;
    dirResult_meta_clients <= n_dirResult_meta_clients; dirResult_meta_alias <= n_dirResult_meta_alias;
    dirResult_meta_prefetch <= n_dirResult_meta_prefetch; dirResult_meta_prefetchSrc <= n_dirResult_meta_prefetchSrc;
    dirResult_meta_accessed <= n_dirResult_meta_accessed; dirResult_meta_tagErr <= n_dirResult_meta_tagErr;
    dirResult_meta_dataErr <= n_dirResult_meta_dataErr;
    tagErr <= n_tagErr; denied <= n_denied; corrupt <= n_corrupt; dataCheckErr <= n_dataCheckErr;
    cbWrDataTraceTag <= n_cbWrDataTraceTag; gotRetryAck <= n_gotRetryAck; gotPCrdGrant <= n_gotPCrdGrant;
    pcrdtype <= n_pcrdtype; retryTimes <= n_retryTimes; backoffTimer <= n_backoffTimer;
    req_released_chiOpcode <= n_req_released_chiOpcode; req_traceTag <= n_req_traceTag;
    req_aliasTask <= n_req_aliasTask;
    state_s_acquire <= n_s_acquire; state_s_rprobe <= n_s_rprobe; state_s_pprobe <= n_s_pprobe;
    state_s_release <= n_s_release; state_s_probeack <= n_s_probeack; state_s_refill <= n_s_refill;
    state_s_retry <= n_s_retry; state_s_cmoresp <= n_s_cmoresp; state_s_cmometaw <= n_s_cmometaw;
    state_s_rcompack <= n_s_rcompack; state_s_wcompack <= n_s_wcompack; state_s_cbwrdata <= n_s_cbwrdata;
    state_s_reissue <= n_s_reissue; state_s_dct <= n_s_dct;
    state_w_rprobeackfirst <= n_w_rprobeackfirst; state_w_rprobeacklast <= n_w_rprobeacklast;
    state_w_pprobeackfirst <= n_w_pprobeackfirst; state_w_pprobeacklast <= n_w_pprobeacklast;
    state_w_grantfirst <= n_w_grantfirst; state_w_grantlast <= n_w_grantlast; state_w_grant <= n_w_grant;
    state_w_releaseack <= n_w_releaseack; state_w_replResp <= n_w_replResp;

    // --- req / merge / blockRefill / validCnt (只有 alloc 或专门事件改) ---
    if (io_alloc_valid) begin
      req_channel <= io_alloc_bits_task_channel; req_set <= io_alloc_bits_task_set;
      req_tag <= io_alloc_bits_task_tag; req_off <= io_alloc_bits_task_off;
      req_alias <= io_alloc_bits_task_alias; req_isKeyword <= io_alloc_bits_task_isKeyword;
      req_opcode <= io_alloc_bits_task_opcode; req_param <= io_alloc_bits_task_param;
      req_sourceId <= io_alloc_bits_task_sourceId;
      req_fromL2pft <= io_alloc_bits_task_fromL2pft; req_reqSource <= io_alloc_bits_task_reqSource;
      req_snpHitRelease <= io_alloc_bits_task_snpHitRelease;
      req_snpHitReleaseToInval <= io_alloc_bits_task_snpHitReleaseToInval;
      req_snpHitReleaseToClean <= io_alloc_bits_task_snpHitReleaseToClean;
      req_snpHitReleaseWithData <= io_alloc_bits_task_snpHitReleaseWithData;
      req_snpHitReleaseIdx <= io_alloc_bits_task_snpHitReleaseIdx;
      req_snpHitReleaseMeta_dirty <= io_alloc_bits_task_snpHitReleaseMeta_dirty;
      req_snpHitReleaseMeta_state <= io_alloc_bits_task_snpHitReleaseMeta_state;
      req_snpHitReleaseMeta_clients <= io_alloc_bits_task_snpHitReleaseMeta_clients;
      req_snpHitReleaseMeta_alias <= io_alloc_bits_task_snpHitReleaseMeta_alias;
      req_snpHitReleaseMeta_prefetch <= io_alloc_bits_task_snpHitReleaseMeta_prefetch;
      req_snpHitReleaseMeta_prefetchSrc <= io_alloc_bits_task_snpHitReleaseMeta_prefetchSrc;
      req_snpHitReleaseMeta_accessed <= io_alloc_bits_task_snpHitReleaseMeta_accessed;
      req_snpHitReleaseMeta_tagErr <= io_alloc_bits_task_snpHitReleaseMeta_tagErr;
      req_snpHitReleaseMeta_dataErr <= io_alloc_bits_task_snpHitReleaseMeta_dataErr;
      req_srcID <= io_alloc_bits_task_srcID; req_txnID <= io_alloc_bits_task_txnID;
      req_fwdNID <= io_alloc_bits_task_fwdNID; req_fwdTxnID <= io_alloc_bits_task_fwdTxnID;
      req_chiOpcode <= io_alloc_bits_task_chiOpcode; req_retToSrc <= io_alloc_bits_task_retToSrc;
      dirResult_set <= io_alloc_bits_dirResult_set;
    end
    // req_traceTag / req_aliasTask 已统一进 n_* 组合块(含 alloc 初值与 resp/nestedwb 覆盖)

    // mergeA: aMergeTask.valid -> 1; 否则 alloc -> 0
    if (io_aMergeTask_valid) mergeA <= 1'b1;
    else if (io_alloc_valid) mergeA <= 1'b0;
    // merge_task_r: RegEnable(io_aMergeTask.bits, io_aMergeTask.valid)
    if (io_aMergeTask_valid) begin
      merge_task_r_off <= io_aMergeTask_bits_off; merge_task_r_alias <= io_aMergeTask_bits_alias;
      merge_task_r_vaddr <= io_aMergeTask_bits_vaddr; merge_task_r_isKeyword <= io_aMergeTask_bits_isKeyword;
      merge_task_r_opcode <= io_aMergeTask_bits_opcode; merge_task_r_param <= io_aMergeTask_bits_param;
      merge_task_r_sourceId <= io_aMergeTask_bits_sourceId;
    end
    // blockRefill 打拍 (REG/REG_1=RegNext(~s_release); REG_2=RegNext(REG_1))
    blockRefill_d1   <= ~state_s_release;
    blockRefill_d1b <= ~state_s_release;
    blockRefill_d2 <= blockRefill_d1b;
    // validCnt (deadlock 计数): golden 顺序 req_valid 优先于 alloc
    if (req_valid) validCnt <= validCnt + 64'h1;
    else if (io_alloc_valid) validCnt <= 64'h0;
  end
end

// =============================================================================
//  CompAck 路由寄存器 + 性能时间戳 (golden 用同步无复位 always 块)
//  tgtid/txnid_rcompack: 读事务 CompAck 的目标 (来自 Comp/RespSepData 的 srcID/dbID,
//                        或 CompData 的 homeNID/dbID)
//  tgtid/txnid_wcompack: 写事务 CompAck 的目标 (来自 CompDBIDResp 或 WEoE 的 Comp)
//  srcid_retryack      : RetryAck 的 srcID (协议重试用)
// =============================================================================
wire weoe_comp_evt = rxrsp_isComp & ~state_w_releaseack & isWriteEvictOrEvict;  // WriteEvictOrEvict 的 Comp 事件
wire acquire_start = txreq_fire;          // io_tasks_txreq.fire
wire release_start = mainpipe_ready & io_tasks_mainpipe_valid_w;  // io_tasks_mainpipe.fire(以 ready&valid 近似 golden _release_start_T)
wire acquire_finish = state_w_grant & state_w_grantlast;
always_ff @(posedge clock) begin
  if (rxrsp_isComp & comp_grantOK | rxrsp_isRespSepData) begin
    tgtid_rcompack <= io_resps_rxrsp_bits_srcID;
    txnid_rcompack <= io_resps_rxrsp_bits_dbID;
  end else if (rxdat_isCompData) begin
    tgtid_rcompack <= io_resps_rxdat_bits_homeNID;
    txnid_rcompack <= io_resps_rxdat_bits_dbID;
  end
  if (rxrsp_isCompDBID | weoe_comp_evt) begin
    tgtid_wcompack <= io_resps_rxrsp_bits_srcID;
    txnid_wcompack <= io_resps_rxrsp_bits_dbID;
  end
  if (rxrsp_isRetryAck) srcid_retryack <= io_resps_rxrsp_bits_srcID;
  // 性能时间戳
  if (acquire_start & ~state_s_acquire) acquire_ts <= timer;
  if (release_start & ~state_s_release) release_ts <= timer;
  acquire_period_valid_d <= acquire_finish;
  release_period_valid_d <= state_w_releaseack;
end
