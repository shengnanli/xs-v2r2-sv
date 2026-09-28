// MainPipe_1.sv —— L2（CoupledL2 tl2chi）slice 的主流水线 s3 / s4 / s5
//
// 对照 coupledL2/src/main/scala/coupledL2/tl2chi/MainPipe.scala（KunminghuV2Config：8 路、512 组、mshrsAll 16，
// CHI Issue E.b，prefetch 打开，enableL2Flush 关 => cmoAllBlock 恒 0）。
//
// 一拍一级：
//   s2  RequestArb 送来的任务（io_taskFromArb_s2）只用来做 s1 入口的同组阻塞（§7），下一拍进 s3。
//   s3  拿到目录结果（io_dirResp_s3）后做全部决策（§2..§5）：
//        * 要不要 MSHR（A：miss/权限不够/CMO/需探测/别名；B：要 pprobe 或要转发 DCT）→ io_toMSHRCtl；
//        * 不要 MSHR 的通道请求当场给出响应（sink_resp：A 的 Grant/AccessAck…、B 的 SnpResp[Data][Fwded]、C 的 ReleaseAck），
//          与 MSHR 任务一起统称 source_req_s3；
//        * 读 / 写数据阵列（io_toDS）、写目录（metaWReq / tagWReq）、嵌套写回（nestedwb）、预取训练；
//        * 决定这条任务走哪个出口（D / TXREQ / TXRSP / TXDAT），能在 s3 就发的直接进出口仲裁器。
//   s4  s3 没发出去的（或还要把 DS 读出的数据写 releaseBuf 的）顺延一拍；"s3 需要数据但 s3 还拿不到"的通道响应在这里挂起。
//   s5  DS 读数据回来（io_toDS_rdata_s5）：写 releaseBuf、给 MSHR 回 dsResp、需要 DS 数据的响应在这里发。
// 三级的四类出口各经一个 3 入口固定优先级仲裁器（s5 > s4 > s3），见 wrapper 里的 toSourceD/TXREQ/TXRSP/TXDAT_arb。
// 另有 CustomL1Hint（给 L1 的 GrantData 提前唤醒）与 13 个 perf 事件（打两拍输出）。
//
// 细节照 golden（bug-for-bug）：
//   * d_s3 / txdat_s3 只放 MSHR 任务与 C 通道（d_s3_latch / txdat_s3_latch 恒 true：通道响应为时序一律推到 s4）；
//   * sink_resp 的 mshrId = 128 + sourceId；odOpGen 查表越界（opcode 15）给 0；
//   * s4/s5 在任务被丢弃时仍更新 tag/set/off（给 io_error 报地址），s5 另在"s3 丢弃后的下一拍"也更新；
//   * 复位后 512 拍逐组清目录（resetIdx 递减、wayOH 全 1、wmeta 全 0）。
// 端口 wrapper、TaskBundle 结构体与出口仲裁器 / CustomL1Hint 的例化由 scripts/gen_l2_mainpipe.py 从 golden 端口表生成；核手写。
// 本文件导航（共 2964 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L399   §0 复位后逐组清目录
//   L414   §1 s3 寄存器与任务分类
//   L491   §2 目录结果与"可嵌套"的目录视图
//   L538   §3 要不要 MSHR
//   L540   A：miss / 命中但权限不够 / CMO 需要下发；Get/CBO 命中 TRUNK 等要先探测 L1；别名
//   L622   §4 不要 MSHR 的通道请求当场响应
//   L624   B：回不回数据
//   L740   §5 数据阵列、目录写、嵌套写回
//   L857   §6 出口：s3 能发就发；否则进 s4 / s5
//   L1087  §7 入口阻塞与流水线状态
//   L1089  s2/s3 可能写目录：挡 s1 同组的通道请求
//   L1122  §8 ECC 错误上报与 perf 事件
//

package l2mainpipe_pkg;
  // BEGIN GENERATED(task_t) —— scripts/gen_l2_mainpipe.py 从 golden 端口表生成
  // TaskBundle（94 个字段，383 位）：字段顺序与位宽逐字取自 golden 端口 io_taskFromArb_s2_bits_*
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

  // CHI 请求（toTXREQ）载荷：TaskBundle.toCHIREQBundle 在 golden 端口上留下的字段
  typedef struct packed {
    logic [10:0] tgtID;
    logic [10:0] srcID;
    logic [11:0] txnID;
    logic [6:0]  opcode;
    logic [47:0] addr;
    logic        likelyshared;
    logic        allowRetry;
    logic [3:0]  pCrdType;
    logic        memAttr_allocate;
    logic        memAttr_cacheable;
    logic        memAttr_device;
    logic        memAttr_ewa;
    logic        expCompAck;
  } chireq_t;

  // MetaEntry（目录项）
  typedef struct packed {
    logic       dirty;
    logic [1:0] state;
    logic       clients;
    logic [1:0] alias_;
    logic       prefetch;
    logic [2:0] prefetchSrc;
    logic       accessed;
    logic       tagErr;
    logic       dataErr;
  } meta_t;

  // MSHR 分配时的初始状态机（s_* / w_* 为"假即有效"：false = 还要做 / 还要等）
  typedef struct packed {
    logic s_acquire, s_rprobe, s_pprobe, s_release, s_probeack, s_refill, s_cmoresp;
    logic w_rprobeackfirst, w_rprobeacklast, w_pprobeackfirst, w_pprobeacklast;
    logic w_grantfirst, w_grantlast, w_grant, w_releaseack, w_replResp;
    logic s_rcompack, s_dct;
  } fsm_state_t;

  localparam int unsigned N_SETS = 512;
  // 目录状态
  localparam logic [1:0] INVALID = 2'd0, BRANCH = 2'd1, TRUNK = 2'd2, TIP = 2'd3;
  // TileLink A / C 通道 opcode
  localparam logic [3:0] A_Get = 4'd4, A_Hint = 4'd5, A_AcquireBlock = 4'd6, A_AcquirePerm = 4'd7;
  localparam logic [3:0] A_CBOClean = 4'd12, A_CBOFlush = 4'd13, A_CBOInval = 4'd14;
  localparam logic [3:0] C_Release = 4'd6, C_ReleaseData = 4'd7;
  // TileLink D 通道 opcode
  localparam logic [3:0] D_AccessAck = 4'd0, D_AccessAckData = 4'd1, D_HintAck = 4'd2;
  localparam logic [3:0] D_Grant = 4'd4, D_GrantData = 4'd5, D_ReleaseAck = 4'd6, D_CBOAck = 4'd8;
  // TileLink 权限 param
  localparam logic [2:0] TtoB = 3'd0, TtoN = 3'd1, BtoN = 3'd2, TtoT = 3'd3, NtoN = 3'd5;
  localparam logic [2:0] NtoB = 3'd0, PREFETCH_WRITE = 3'd1;
  // CHI 缓存状态（Resp / FwdState 低 2 位；bit2 = PassDirty）
  localparam logic [2:0] CHI_I = 3'd0, CHI_SC = 3'd1, CHI_UC = 3'd2, CHI_UD = 3'd2;
  // CHI opcode（Issue E.b）
  localparam logic [6:0] REQ_Evict = 7'h0D, REQ_WriteEvictFull = 7'h15, REQ_WriteCleanFull = 7'h17;
  localparam logic [6:0] REQ_WriteBackFull = 7'h1B, REQ_WriteEvictOrEvict = 7'h42;
  localparam logic [6:0] RSP_SnpResp = 7'h01, RSP_SnpRespFwded = 7'h09;
  localparam logic [6:0] DAT_SnpRespData = 7'h01, DAT_CopyBackWrData = 7'h02, DAT_CompData = 7'h04;
  localparam logic [6:0] DAT_SnpRespDataPtl = 7'h05, DAT_SnpRespDataFwded = 7'h06;
  localparam logic [6:0] SnpShared = 7'h01, SnpClean = 7'h02, SnpOnce = 7'h03, SnpNotSharedDirty = 7'h04;
  localparam logic [6:0] SnpUniqueStash = 7'h05, SnpMakeInvalidStash = 7'h06, SnpUnique = 7'h07;
  localparam logic [6:0] SnpCleanShared = 7'h08, SnpCleanInvalid = 7'h09, SnpMakeInvalid = 7'h0A;
  localparam logic [6:0] SnpStashUnique = 7'h0B, SnpStashShared = 7'h0C, SnpQuery = 7'h10;
  localparam logic [6:0] SnpSharedFwd = 7'h11, SnpCleanFwd = 7'h12, SnpOnceFwd = 7'h13, SnpNotSharedDirtyFwd = 7'h14;
  localparam logic [6:0] SnpPreferUnique = 7'h15, SnpPreferUniqueFwd = 7'h16, SnpUniqueFwd = 7'h17;

  // ---- snoop opcode 分类（HasCHIOpcodes） ----
  function automatic logic isSnpStashX(input logic [6:0] op);
    return op == SnpStashUnique || op == SnpStashShared;
  endfunction
  function automatic logic isSnpXFwd(input logic [6:0] op);
    return op == SnpSharedFwd || op == SnpCleanFwd || op == SnpOnceFwd || op == SnpNotSharedDirtyFwd ||
           op == SnpUniqueFwd || op == SnpPreferUniqueFwd;
  endfunction
  function automatic logic isSnpQuery(input logic [6:0] op);
    return op == SnpQuery;
  endfunction
  function automatic logic isSnpOnceX(input logic [6:0] op);
    return op == SnpOnce || op == SnpOnceFwd;
  endfunction
  function automatic logic isSnpToBNonFwd(input logic [6:0] op);
    return op == SnpClean || op == SnpNotSharedDirty || op == SnpShared;
  endfunction
  function automatic logic isSnpToBFwd(input logic [6:0] op);
    return op == SnpCleanFwd || op == SnpNotSharedDirtyFwd || op == SnpSharedFwd;
  endfunction
  function automatic logic isSnpToB(input logic [6:0] op);
    return isSnpToBNonFwd(op) || isSnpToBFwd(op);
  endfunction
  function automatic logic isSnpUniqueX(input logic [6:0] op);
    return op == SnpUnique || op == SnpUniqueFwd || op == SnpUniqueStash ||
           op == SnpPreferUnique || op == SnpPreferUniqueFwd;
  endfunction
  function automatic logic isSnpMakeInvalidX(input logic [6:0] op);
    return op == SnpMakeInvalid || op == SnpMakeInvalidStash;
  endfunction
  function automatic logic isSnpToN(input logic [6:0] op);
    return isSnpUniqueX(op) || op == SnpCleanInvalid || isSnpMakeInvalidX(op);
  endfunction

  // ---- TileLink 辅助（coupledL2.MetaData） ----
  // 请求要不要 T 权限
  function automatic logic needT(input logic [3:0] opcode, input logic [2:0] param);
    return !opcode[2] || (opcode == A_Hint && param == PREFETCH_WRITE) ||
           ((opcode == A_AcquireBlock || opcode == A_AcquirePerm) && param != NtoB);
  endfunction
  function automatic logic isParamFromT(input logic [2:0] param);
    return param == TtoN || param == TtoB || param == TtoT;
  endfunction
  function automatic logic isToN(input logic [2:0] param);
    return param == TtoN || param == BtoN || param == NtoN;
  endfunction
  // A 请求 -> D 响应 opcode（odOpGen；15 项表，下标 15 越界给 0）
  function automatic logic [3:0] odOpGen(input logic [3:0] a);
    case (a)
      4'd0, 4'd1:             return D_AccessAck;
      4'd2, 4'd3, 4'd4:       return D_AccessAckData;
      4'd5:                   return D_HintAck;
      4'd6:                   return D_GrantData;
      4'd7:                   return D_Grant;
      4'd12, 4'd13, 4'd14:    return D_CBOAck;
      default:                return 4'd0;
    endcase
  endfunction

  function automatic chireq_t toCHIREQ(input task_t t);
    chireq_t r;
    r.tgtID             = t.tgtID;
    r.srcID             = t.srcID;
    r.txnID             = t.txnID;
    r.opcode            = t.chiOpcode;
    r.addr              = {2'b00, t.tag, t.set, 6'd0};
    r.likelyshared      = t.likelyshared;
    r.allowRetry        = t.allowRetry;
    r.pCrdType          = t.pCrdType;
    r.memAttr_allocate  = t.memAttr_allocate;
    r.memAttr_cacheable = t.memAttr_cacheable;
    r.memAttr_device    = t.memAttr_device;
    r.memAttr_ewa       = t.memAttr_ewa;
    r.expCompAck        = t.expCompAck;
    return r;
  endfunction
endpackage

module xs_MainPipe_1_core
  import l2mainpipe_pkg::*;
(
  input  logic         clock,
  input  logic         reset,
  // s1 状态 / s2 任务
  input  logic [30:0]  s1_b_tag,
  input  logic [8:0]   s1_c_set, s1_b_set, s1_a_set, s1_g_set,
  input  logic         s2_valid,
  input  task_t        s2_task,
  // s3 目录 / 替换结果
  input  logic         dir_valid,
  input  logic         dir_hit,
  input  logic [30:0]  dir_tag,
  input  logic [8:0]   dir_set,
  input  logic [2:0]   dir_way,
  input  meta_t        dir_meta,
  input  logic         dir_error,
  input  logic         repl_valid,
  input  logic [2:0]   repl_way,
  input  logic [1:0]   repl_state,
  input  logic         repl_retry,
  input  logic [7:0]   mshr_alloc_ptr,
  // 缓冲读结果
  input  logic [511:0] c_releaseData,      // SinkC 的 Release 数据（bufResp 两拍拼成）
  input  logic [511:0] refillBuf_data,
  input  logic         releaseBuf_valid,
  input  logic [511:0] releaseBuf_data,
  input  logic [511:0] ds_rdata_s5,
  input  logic         ds_error_s5,
  // 入口阻塞
  output logic         blockG_s1, blockB_s1, blockC_s1,
  output logic         toReqBuf_0, toReqBuf_1,
  // 流水线状态（给 GrantBuffer / TX 通道做容量反压）
  output logic         statusD_valid   [3],
  output logic [2:0]   statusD_channel [3],
  output logic         statusTX_valid     [3],
  output logic [2:0]   statusTX_channel   [3],
  output logic [2:0]   statusTX_txChannel [3],
  output logic         statusTX_mshrTask  [3],
  // MSHR 分配
  output logic         alloc_valid,
  output logic         alloc_dir_hit,
  output logic [30:0]  alloc_dir_tag,
  output logic [8:0]   alloc_dir_set,
  output logic [2:0]   alloc_dir_way,
  output meta_t        alloc_dir_meta,
  output logic         alloc_dir_error,
  output fsm_state_t   alloc_state,
  output task_t        alloc_task,
  // 数据阵列
  output logic         ds_en_s3,
  output logic         ds_req_valid,
  output logic [2:0]   ds_req_way,
  output logic [8:0]   ds_req_set,
  output logic         ds_req_wen,
  output logic [511:0] ds_wdata,
  // 四类出口：[k] 是出口仲裁器第 k 路 —— k=0 是 s5、k=1 是 s4、k=2 是 s3（s5 优先级最高）
  output logic         d_valid    [3],
  output task_t        d_task     [3],
  output logic [511:0] d_data     [3],
  input  logic         d_ready    [3],
  output logic         txreq_valid [3],
  output chireq_t      txreq_bits  [3],
  input  logic         txreq_ready [3],
  output logic         txrsp_valid [3],
  output task_t        txrsp_task  [3],
  input  logic         txrsp_ready [3],
  output logic         txdat_valid [3],
  output task_t        txdat_task  [3],
  output logic [511:0] txdat_data  [3],
  input  logic         txdat_ready [3],
  // 目录写
  output logic         metaW_valid,
  output logic [8:0]   metaW_set,
  output logic [7:0]   metaW_wayOH,
  output meta_t        metaW_meta,
  output logic         tagW_valid,
  output logic [8:0]   tagW_set,
  output logic [2:0]   tagW_way,
  output logic [30:0]  tagW_tag,
  // s5：DS 读数据写 releaseBuf、回 MSHR
  output logic         releaseBufW_valid,
  output logic [7:0]   s5_mshrId,
  // 嵌套写回
  output logic [8:0]   nwb_set,
  output logic [30:0]  nwb_tag,
  output logic         nwb_c_set_dirty, nwb_c_set_tip,
  output logic         nwb_b_inv_dirty, nwb_b_toB, nwb_b_toN, nwb_b_toClean,
  output logic         nwb_denied, nwb_corrupt,
  // 给 CustomL1Hint 的 s3 信息
  output logic         hint_s3_valid,
  output task_t        hint_s3_task,       // opcode 已换成"当场响应"的 D opcode（若当场响应）
  output logic         hint_s3_need_mshr,
  // 预取训练
  output logic         pft_valid,
  output logic [30:0]  pft_tag,
  output logic [8:0]   pft_set,
  output logic         pft_needT,
  output logic [6:0]   pft_source,
  output logic [43:0]  pft_vaddr,
  output logic         pft_hit,
  output logic         pft_prefetched,
  output logic [2:0]   pft_pfsource,
  output logic [4:0]   pft_reqsource,
  // ECC 错误
  output logic         err_valid,
  output logic         err_bits_valid,
  output logic [45:0]  err_address,
  // perf 事件（打两拍）
  output logic         perf [13]
);

  // ================================================================================================
  // §0 复位后逐组清目录
  // ================================================================================================
  logic       resetFinish;
  logic [8:0] resetIdx;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      resetFinish <= 1'b0;
      resetIdx    <= 9'(N_SETS - 1);
    end else begin
      if (!resetFinish)     resetIdx    <= resetIdx - 9'd1;
      if (resetIdx == 9'd0) resetFinish <= 1'b1;
    end
  end

  // ================================================================================================
  // §1 s3 寄存器与任务分类
  // ================================================================================================
  logic  s3_valid;
  task_t req;                      // task_s3.bits
  logic [1:0] s3_validHold2;       // 让 ds_req_valid 保持两拍（DataStorage 要求）
  logic  replResp_valid_s4;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s3_valid          <= 1'b0;
      req               <= '0;
      s3_validHold2     <= 2'b00;
      replResp_valid_s4 <= 1'b0;
    end else begin
      s3_valid <= s2_valid;
      if (s2_valid) begin
        req           <= s2_task;
        s3_validHold2 <= 2'b11;
      end else begin
        s3_validHold2 <= {1'b0, s3_validHold2[1]};
      end
      replResp_valid_s4 <= repl_valid;
    end
  end

  logic fromA, fromB, fromC, toTXREQ, toTXRSP, toTXDAT;
  assign fromA   = req.channel[0];
  assign fromB   = req.channel[1];
  assign fromC   = req.channel[2];
  assign toTXREQ = req.txChannel[0];
  assign toTXRSP = req.txChannel[1];
  assign toTXDAT = req.txChannel[2];

  logic mshr_req, sinkA_req, sinkB_req, sinkC_req;
  assign mshr_req  = req.mshrTask;
  assign sinkA_req = !mshr_req && fromA;
  assign sinkB_req = !mshr_req && fromB;
  assign sinkC_req = !mshr_req && fromC;

  // 通道请求
  logic req_acquire, req_acquireBlock, req_prefetch, req_get, req_cbo_clean, req_cbo_flush, req_cbo_inval, cmo_cbo;
  assign req_acquire      = sinkA_req && (req.opcode == A_AcquireBlock || req.opcode == A_AcquirePerm);
  assign req_acquireBlock = sinkA_req && req.opcode == A_AcquireBlock;
  assign req_prefetch     = sinkA_req && req.opcode == A_Hint;
  assign req_get          = sinkA_req && req.opcode == A_Get;
  assign req_cbo_clean    = sinkA_req && req.opcode == A_CBOClean;
  assign req_cbo_flush    = sinkA_req && req.opcode == A_CBOFlush;   // cmoHitInvalid 恒 0（无 L2 flush）
  assign req_cbo_inval    = sinkA_req && req.opcode == A_CBOInval;
  assign cmo_cbo          = req_cbo_clean || req_cbo_flush || req_cbo_inval;

  // MSHR 任务
  logic mshr_grant, mshr_accessackdata, mshr_hintack, mshr_cmoresp, mshr_refill;
  assign mshr_grant         = mshr_req && fromA && (req.opcode == D_Grant || req.opcode == D_GrantData);
  assign mshr_accessackdata = mshr_req && fromA && req.opcode == D_AccessAckData;
  assign mshr_hintack       = mshr_req && fromA && req.opcode == D_HintAck;
  assign mshr_cmoresp       = mshr_req && fromA && req.opcode == D_CBOAck;
  assign mshr_refill        = mshr_accessackdata || mshr_hintack || mshr_grant;   // 要回填 DS

  logic mshr_snpResp, mshr_snpRespFwded, mshr_snpRespData, mshr_snpRespDataPtl, mshr_snpRespDataFwded;
  logic mshr_snpRespX, mshr_snpRespDataX, mshr_dct, mshr_cbWrData;
  logic mshr_writeCleanFull, mshr_writeBackFull, mshr_writeEvictFull, mshr_writeEvictOrEvict, mshr_evict;
  assign mshr_snpResp           = mshr_req && toTXRSP && req.chiOpcode == RSP_SnpResp;
  assign mshr_snpRespFwded      = mshr_req && toTXRSP && req.chiOpcode == RSP_SnpRespFwded;
  assign mshr_snpRespData       = mshr_req && toTXDAT && req.chiOpcode == DAT_SnpRespData;
  assign mshr_snpRespDataPtl    = mshr_req && toTXDAT && req.chiOpcode == DAT_SnpRespDataPtl;
  assign mshr_snpRespDataFwded  = mshr_req && toTXDAT && req.chiOpcode == DAT_SnpRespDataFwded;
  assign mshr_snpRespX          = mshr_snpResp || mshr_snpRespFwded;
  assign mshr_snpRespDataX      = mshr_snpRespData || mshr_snpRespDataPtl || mshr_snpRespDataFwded;
  assign mshr_dct               = mshr_req && toTXDAT && req.chiOpcode == DAT_CompData;
  assign mshr_writeCleanFull    = mshr_req && toTXREQ && req.chiOpcode == REQ_WriteCleanFull;
  assign mshr_writeBackFull     = mshr_req && toTXREQ && req.chiOpcode == REQ_WriteBackFull;
  assign mshr_writeEvictFull    = mshr_req && toTXREQ && req.chiOpcode == REQ_WriteEvictFull;
  assign mshr_writeEvictOrEvict = mshr_req && toTXREQ && req.chiOpcode == REQ_WriteEvictOrEvict;
  assign mshr_evict             = mshr_req && toTXREQ && req.chiOpcode == REQ_Evict;
  assign mshr_cbWrData          = mshr_req && toTXDAT && req.chiOpcode == DAT_CopyBackWrData;

  // ================================================================================================
  // §2 目录结果与"可嵌套"的目录视图
  // ================================================================================================
  logic meta_has_clients, req_needT;
  assign meta_has_clients = dir_meta.clients;
  assign req_needT        = needT(req.opcode, req.param);

  logic cache_alias;   // L1 以另一个别名持有这一块：要先探测
  assign cache_alias = req_acquire && dir_hit && dir_meta.clients && dir_meta.alias_ != req.alias_;

  // snoop 嵌套在 Release 上时，以 MSHR 里的元数据当作目录结果（必定视作命中/按其状态）
  logic        n_hit;
  logic [30:0] n_tag;
  logic [8:0]  n_set;
  meta_t       n_meta;
  always_comb begin
    n_hit  = dir_hit;
    n_tag  = dir_tag;
    n_set  = dir_set;
    n_meta = dir_meta;
    if (req.snpHitRelease) begin
      n_hit  = req.snpHitReleaseMeta_state != INVALID;
      n_tag  = req.tag;
      n_set  = req.set;
      n_meta = '{dirty:       req.snpHitReleaseMeta_dirty,
                 state:       req.snpHitReleaseMeta_state,
                 clients:     req.snpHitReleaseMeta_clients,
                 alias_:      req.snpHitReleaseMeta_alias,
                 prefetch:    req.snpHitReleaseMeta_prefetch,
                 prefetchSrc: req.snpHitReleaseMeta_prefetchSrc,
                 accessed:    req.snpHitReleaseMeta_accessed,
                 tagErr:      req.snpHitReleaseMeta_tagErr,
                 dataErr:     req.snpHitReleaseMeta_dataErr};
    end
  end

  logic tagError, dataError, l2Error;
  assign tagError  = (dir_error || dir_meta.tagErr) && dir_valid;
  assign dataError = dir_meta.dataErr && dir_valid;
  assign l2Error   = dir_error && dir_valid;

  // 替换结果（s3 或 s4 到达都算）
  logic replResp_hold, retry, need_repl;
  assign replResp_hold = repl_valid || replResp_valid_s4;
  assign retry         = replResp_hold && repl_retry;
  assign need_repl     = replResp_hold && repl_state != INVALID && req.replTask;

  // ================================================================================================
  // §3 要不要 MSHR
  // ================================================================================================
  // A：miss / 命中但权限不够 / CMO 需要下发；Get/CBO 命中 TRUNK 等要先探测 L1；别名
  logic acquire_on_miss, acquire_on_hit, need_acquire_a, need_probe_a, need_release_a, need_mshr_a;
  assign acquire_on_miss = req_acquire || req_prefetch || req_get;
  assign acquire_on_hit  = dir_meta.state == BRANCH && req_needT && !req_prefetch;
  assign need_acquire_a  = fromA && ((dir_hit ? acquire_on_hit : acquire_on_miss) || cmo_cbo);
  assign need_probe_a    = dir_hit && meta_has_clients &&
                           (req_get && dir_meta.state == TRUNK || req_cbo_clean && dir_meta.state == TRUNK ||
                            req_cbo_flush || req_cbo_inval);
  assign need_release_a  = dir_hit && (req_cbo_clean && !need_probe_a && dir_meta.dirty ||
                                       req_cbo_flush && dir_meta.state != INVALID ||
                                       req_cbo_inval && dir_meta.state != INVALID);
  assign need_mshr_a     = need_acquire_a || need_probe_a || cache_alias;

  // B：要 pprobe 上层（见 Scala 注释的四类）或要做 DCT 转发
  logic [6:0] snpOp;
  assign snpOp = req.chiOpcode;
  logic doFwd, pprobe_stable, pprobe_toB, pprobe_toN, pprobe_nderr, need_pprobe_b, need_mshr_b, need_mshr;
  assign doFwd         = isSnpXFwd(snpOp) && n_hit && !(n_meta.tagErr || dir_error);
  assign pprobe_stable = fromB && (isSnpOnceX(snpOp) || isSnpQuery(snpOp) || isSnpStashX(snpOp)) &&
                         dir_hit && dir_meta.state == TRUNK && meta_has_clients;
  assign pprobe_toB    = fromB && (isSnpToB(snpOp) || snpOp == SnpCleanShared) &&
                         dir_hit && dir_meta.state == TRUNK && meta_has_clients;
  assign pprobe_toN    = fromB && (isSnpUniqueX(snpOp) || snpOp == SnpCleanInvalid || isSnpMakeInvalidX(snpOp)) &&
                         dir_hit && meta_has_clients;
  assign pprobe_nderr  = fromB && tagError && dir_hit;
  assign need_pprobe_b = pprobe_stable || pprobe_toB || pprobe_toN || pprobe_nderr;
  assign need_mshr_b   = need_pprobe_b || doFwd;
  assign need_mshr     = need_mshr_a || need_mshr_b;

  assign alloc_valid     = s3_valid && !mshr_req && need_mshr;
  assign alloc_dir_hit   = n_hit;
  assign alloc_dir_tag   = n_tag;
  assign alloc_dir_set   = n_set;
  assign alloc_dir_way   = dir_way;
  assign alloc_dir_meta  = n_meta;
  assign alloc_dir_error = dir_error;
  always_comb begin
    alloc_task          = req;
    alloc_task.bufIdx   = '0;
    alloc_task.mshrTask = 1'b0;
    alloc_task.aliasTask = cache_alias;
    alloc_task.wayMask  = '0;
    alloc_task.denied   = tagError;
    alloc_task.corrupt  = dataError;
  end

  // MSHR 初始状态（假即有效）
  always_comb begin
    alloc_state = '1;
    if (fromA) begin
      alloc_state.s_refill   = cmo_cbo;
      alloc_state.w_replResp = cmo_cbo || dir_hit;
      if (need_acquire_a) begin
        alloc_state.s_acquire    = 1'b0;       // cmoAllBlock 恒 0
        alloc_state.s_rcompack   = cmo_cbo;    // = !need_compack
        alloc_state.w_grantfirst = 1'b0;
        alloc_state.w_grantlast  = 1'b0;
        alloc_state.w_grant      = 1'b0;
      end
      if (cache_alias || need_probe_a) begin
        alloc_state.s_rprobe         = 1'b0;
        alloc_state.w_rprobeackfirst = 1'b0;
        alloc_state.w_rprobeacklast  = 1'b0;
      end
      if (need_release_a) begin
        alloc_state.s_release    = 1'b0;
        alloc_state.w_releaseack = 1'b0;
      end
      if (cmo_cbo) alloc_state.s_cmoresp = 1'b0;
    end
    if (fromB) begin
      alloc_state.s_probeack = 1'b0;
      if (need_pprobe_b) begin
        alloc_state.s_pprobe         = 1'b0;
        alloc_state.w_pprobeackfirst = 1'b0;
        alloc_state.w_pprobeacklast  = 1'b0;
      end
      if (doFwd) alloc_state.s_dct = 1'b0;
    end
  end

  // ================================================================================================
  // §4 不要 MSHR 的通道请求当场响应（sink_resp），与 MSHR 任务合成 source_req_s3
  // ================================================================================================
  // B：回不回数据
  logic retToSrc, neverRespData, respData_dirty, respData_once, respData_fwd, respData_nonFwd, shouldRespData, doRespData;
  assign retToSrc        = req.retToSrc;
  assign neverRespData   = isSnpMakeInvalidX(snpOp) || isSnpStashX(snpOp) || isSnpQuery(snpOp) ||
                           snpOp == SnpOnceFwd || snpOp == SnpUniqueFwd || snpOp == SnpPreferUniqueFwd;
  assign respData_dirty  = n_hit && (n_meta.state == TIP || n_meta.state == TRUNK) && n_meta.dirty;
  assign respData_once   = n_hit && n_meta.state == TIP && !n_meta.dirty && snpOp == SnpOnce;
  assign respData_fwd    = n_hit && retToSrc && isSnpXFwd(snpOp);
  assign respData_nonFwd = n_hit && retToSrc && n_meta.state == BRANCH &&
                           (snpOp == SnpOnce || snpOp == SnpUnique || snpOp == SnpPreferUnique || isSnpToBNonFwd(snpOp));
  assign shouldRespData  = respData_dirty || respData_once || respData_fwd || respData_nonFwd;
  assign doRespData      = shouldRespData && !neverRespData;

  // SnpResp 的 Resp = {PassDirty, CacheState}
  logic [2:0] respCacheState;
  logic       respPassDirty;
  assign respPassDirty = doRespData && n_hit && n_meta.state[1] && n_meta.dirty &&     // isT
                         (snpOp != SnpOnce || req.snpHitRelease) && !(isSnpStashX(snpOp) || isSnpQuery(snpOp));
  always_comb begin
    respCacheState = CHI_I;
    if (n_hit && !tagError) begin
      if (isSnpToB(snpOp))
        respCacheState = req.snpHitReleaseToInval ? CHI_I : CHI_SC;
      if (isSnpOnceX(snpOp) || isSnpStashX(snpOp) || isSnpQuery(snpOp))
        respCacheState = n_meta.state == BRANCH ? CHI_SC : (n_meta.dirty ? CHI_UD : CHI_UC);
      if (isSnpOnceX(snpOp)) begin
        if (req.snpHitReleaseToClean && n_meta.dirty) respCacheState = CHI_SC;
        if (req.snpHitReleaseToInval)                 respCacheState = CHI_I;
      end
      if (snpOp == SnpCleanShared)
        respCacheState = n_meta.state[1] ? CHI_UC : CHI_SC;
    end
  end

  // 转发给请求者的 FwdState
  logic [2:0] fwdCacheState;
  logic       fwdPassDirty;
  always_comb begin
    fwdCacheState = CHI_I;
    fwdPassDirty  = 1'b0;
    if (n_hit) begin
      if (isSnpToBFwd(snpOp))
        fwdCacheState = req.snpHitReleaseToInval ? CHI_I : CHI_SC;
      if (snpOp == SnpUniqueFwd || snpOp == SnpPreferUniqueFwd) begin
        if (n_meta.state == TIP && n_meta.dirty) begin
          fwdCacheState = CHI_UD;
          fwdPassDirty  = 1'b1;
        end else begin
          fwdCacheState = CHI_UC;
        end
      end
    end
  end

  // B 请求命中时要写回目录的新元数据（SnpToN -> 全 0；否则降到 BRANCH、清 dirty，SnpCleanShared 保持状态）
  logic  metaW_valid_b;
  meta_t metaW_b;
  always_comb begin
    metaW_b = '0;
    if (!isSnpToN(snpOp)) begin
      metaW_b.state    = snpOp == SnpCleanShared ? dir_meta.state : BRANCH;
      metaW_b.clients  = dir_meta.clients;
      metaW_b.alias_   = dir_meta.alias_;
      metaW_b.accessed = dir_meta.accessed;
      metaW_b.tagErr   = dir_meta.tagErr;
      metaW_b.dataErr  = dir_meta.dataErr;
    end
  end

  logic  sink_resp_valid, promoteT;
  task_t sink_resp;
  assign sink_resp_valid = s3_valid && !mshr_req && !need_mshr;
  assign promoteT        = dir_hit && dir_meta.state[1];
  always_comb begin
    sink_resp        = req;
    sink_resp.mshrId = 8'd128 + 8'(req.sourceId);
    if (fromA) begin
      sink_resp.opcode = odOpGen(req.opcode);
      sink_resp.param  = req_acquire ? ((req.param == NtoB && !promoteT) ? 3'd1 : 3'd0) : 3'd0;  // toB : toT
    end else if (fromB) begin
      sink_resp.opcode    = '0;
      sink_resp.param     = '0;
      sink_resp.tgtID     = req.srcID;
      sink_resp.srcID     = req.tgtID;
      sink_resp.dbID      = '0;
      sink_resp.pCrdType  = '0;
      case ({doFwd, doRespData})
        2'b00: sink_resp.chiOpcode = RSP_SnpResp;
        2'b10: sink_resp.chiOpcode = RSP_SnpRespFwded;
        2'b01: sink_resp.chiOpcode = DAT_SnpRespData;
        default: sink_resp.chiOpcode = DAT_SnpRespDataFwded;
      endcase
      sink_resp.resp      = respCacheState | {respPassDirty && doRespData, 2'b00};
      sink_resp.fwdState  = fwdCacheState | {fwdPassDirty, 2'b00};
      sink_resp.txChannel = {doRespData, !doRespData, 1'b0};
      sink_resp.size      = 3'd6;
      sink_resp.meta_dirty       = metaW_b.dirty;
      sink_resp.meta_state       = metaW_b.state;
      sink_resp.meta_clients     = metaW_b.clients;
      sink_resp.meta_alias       = metaW_b.alias_;
      sink_resp.meta_prefetch    = metaW_b.prefetch;
      sink_resp.meta_prefetchSrc = metaW_b.prefetchSrc;
      sink_resp.meta_accessed    = metaW_b.accessed;
      sink_resp.meta_tagErr      = metaW_b.tagErr;
      sink_resp.meta_dataErr     = metaW_b.dataErr;
      sink_resp.metaWen          = metaW_valid_b;
    end else begin
      sink_resp.opcode = D_ReleaseAck;
      sink_resp.param  = '0;
    end
  end

  task_t src;   // source_req_s3
  assign src = sink_resp_valid ? sink_resp : req;

  // ================================================================================================
  // §5 数据阵列、目录写、嵌套写回
  // ================================================================================================
  logic [511:0] data_s3;
  assign data_s3 = releaseBuf_valid ? releaseBuf_data : refillBuf_data;

  logic hasData, need_data_a, need_data_b, need_data_repl, need_data_cmo, ren, wen_c, wen_mshr, wen;
  assign hasData        = src.opcode[0] || src.txChannel[2];          // 回 TL 带数据 / 回 CHI 带数据
  assign need_data_a    = dir_hit && (req_get || req_acquireBlock);
  assign need_data_b    = sinkB_req && (doRespData || doFwd || n_hit && n_meta.state == TRUNK);
  assign need_data_repl = mshr_refill && need_repl && !retry;
  assign need_data_cmo  = cmo_cbo && n_hit && n_meta.dirty;
  assign ren            = need_data_a || need_data_b || need_data_repl || need_data_cmo;
  assign wen_c          = sinkC_req && isParamFromT(req.param) && req.opcode[0] && dir_hit;
  assign wen_mshr       = req.dsWen && (mshr_snpRespX || mshr_snpRespDataX || mshr_writeCleanFull || mshr_writeBackFull ||
                                        mshr_writeEvictFull || mshr_writeEvictOrEvict || mshr_evict ||
                                        mshr_refill && !need_repl && !retry);
  assign wen            = wen_c || wen_mshr;

  logic [2:0] refillWay;   // 回填用替换结果的路，MSHR 任务用自带的路，其余用目录结果
  assign refillWay = (mshr_refill && req.replTask) ? repl_way : (mshr_req ? req.way : dir_way);

  assign ds_en_s3     = s3_valid && (ren || wen);
  assign ds_req_valid = s3_validHold2[0] && (ren || wen);
  assign ds_req_way   = refillWay;
  assign ds_req_set   = mshr_req ? req.set : dir_set;
  assign ds_req_wen   = wen;
  assign ds_wdata     = !mshr_req ? c_releaseData : (req.useProbeData ? releaseBuf_data : refillBuf_data);

  // 要把 DS 读出的数据写进 releaseBuf（交给 MSHR 继续处理）
  logic need_write_releaseBuf;
  assign need_write_releaseBuf = need_probe_a || cache_alias || need_data_b && need_mshr_b || need_data_repl || need_data_cmo;

  // 目录写：五类来源按优先级 a > b > c > mshr > cmo
  logic metaW_valid_a, metaW_valid_c, metaW_valid_mshr, metaW_valid_cmo;
  assign metaW_valid_a    = sinkA_req && !need_mshr_a && !req_get && !req_prefetch && !cmo_cbo;
  assign metaW_valid_b    = sinkB_req && !need_mshr_b && dir_hit &&
                            (snpOp != SnpOnce || req.snpHitReleaseToClean && req.snpHitReleaseMeta_dirty) &&
                            !isSnpStashX(snpOp) && !isSnpQuery(snpOp) &&
                            (dir_meta.state == TIP || dir_meta.state == BRANCH && isSnpToN(snpOp));
  assign metaW_valid_c    = sinkC_req && dir_hit;
  assign metaW_valid_mshr = mshr_req && req.metaWen && !(mshr_refill && retry);
  assign metaW_valid_cmo  = req_cbo_inval && dir_hit;

  meta_t metaW_a, metaW_c, metaW_mshr, metaW_sel;
  always_comb begin
    metaW_a          = '0;
    metaW_a.dirty    = dir_meta.dirty;
    metaW_a.state    = (req_needT || promoteT) ? TRUNK : dir_meta.state;
    metaW_a.clients  = !l2Error;
    metaW_a.alias_   = (req_get || req_prefetch) ? dir_meta.alias_ : req.alias_;
    metaW_a.accessed = 1'b1;
    metaW_a.tagErr   = dir_meta.tagErr;
    metaW_a.dataErr  = dir_meta.dataErr;

    metaW_c          = '0;
    metaW_c.dirty    = dir_meta.dirty || wen_c;
    metaW_c.state    = isParamFromT(req.param) ? TIP : dir_meta.state;
    metaW_c.clients  = !isToN(req.param);
    metaW_c.alias_   = dir_meta.alias_;
    metaW_c.accessed = dir_meta.accessed;
    metaW_c.tagErr   = wen_c ? req.denied  : dir_meta.tagErr;
    metaW_c.dataErr  = wen_c ? req.corrupt : dir_meta.dataErr;

    // MSHR 任务：带着要写的元数据来（mergeA 用合并进来那个 A 请求的），错误位按本任务的 denied/corrupt
    if (req.mergeA)
      metaW_mshr = '{req.aMergeTask_meta_dirty, req.aMergeTask_meta_state, req.aMergeTask_meta_clients,
                     req.aMergeTask_meta_alias, req.aMergeTask_meta_prefetch, req.aMergeTask_meta_prefetchSrc,
                     req.aMergeTask_meta_accessed, 1'b0, 1'b0};
    else
      metaW_mshr = '{req.meta_dirty, req.meta_state, req.meta_clients, req.meta_alias, req.meta_prefetch,
                     req.meta_prefetchSrc, req.meta_accessed, 1'b0, 1'b0};
    metaW_mshr.tagErr  = req.denied;
    metaW_mshr.dataErr = req.corrupt;

    if      (metaW_valid_a)    metaW_sel = metaW_a;
    else if (metaW_valid_b)    metaW_sel = metaW_b;
    else if (metaW_valid_c)    metaW_sel = metaW_c;
    else if (metaW_valid_mshr) metaW_sel = metaW_mshr;
    else                       metaW_sel = '0;          // cmo：作废该块
  end

  assign metaW_valid = !resetFinish ||
                       s3_valid && (metaW_valid_a || metaW_valid_b || metaW_valid_c || metaW_valid_mshr || metaW_valid_cmo);
  assign metaW_set   = resetFinish ? req.set : resetIdx;
  assign metaW_wayOH = resetFinish ? (8'd1 << refillWay) : 8'hFF;
  assign metaW_meta  = resetFinish ? metaW_sel : '0;

  assign tagW_valid = s3_valid && req.tagWen && mshr_refill && !retry;
  assign tagW_set   = req.set;
  assign tagW_way   = (mshr_refill && req.replTask) ? repl_way : req.way;
  assign tagW_tag   = req.tag;

  // 嵌套写回（给 MSHR：本拍 s3 的 Release / snoop 改了同地址的状态）
  assign nwb_set         = req.set;
  assign nwb_tag         = req.tag;
  assign nwb_denied      = req.denied;
  assign nwb_corrupt     = req.corrupt;
  assign nwb_c_set_dirty = s3_valid && fromC && req.opcode == C_ReleaseData && req.param == TtoN;
  assign nwb_c_set_tip   = s3_valid && fromC && req.opcode == C_Release && req.param == TtoN;
  assign nwb_b_inv_dirty = s3_valid && fromB && src.snpHitReleaseToInval && !(isSnpStashX(snpOp) || isSnpQuery(snpOp));
  assign nwb_b_toB       = s3_valid && fromB && src.metaWen && src.meta_state == BRANCH;
  assign nwb_b_toN       = s3_valid && fromB && src.metaWen && src.meta_state == INVALID;
  assign nwb_b_toClean   = s3_valid && fromB && src.metaWen && !src.meta_dirty;

  // 预取训练：带 needHint 的 Acquire/Get miss 或命中预取块，以及 mergeA
  assign pft_valid      = s3_valid && ((req_acquire || req_get) && req.needHint && (!dir_hit || dir_meta.prefetch) || req.mergeA);
  assign pft_tag        = req.tag;
  assign pft_set        = req.set;
  assign pft_needT      = req.mergeA ? needT({1'b0, req.aMergeTask_opcode}, req.aMergeTask_param) : req_needT;
  assign pft_source     = req.mergeA ? req.aMergeTask_sourceId : req.sourceId;
  assign pft_vaddr      = req.mergeA ? req.aMergeTask_vaddr : req.vaddr;
  assign pft_hit        = req.mergeA || dir_hit;
  assign pft_prefetched = req.mergeA || dir_meta.prefetch;
  assign pft_pfsource   = dir_meta.prefetchSrc;
  assign pft_reqsource  = req.reqSource;

  // ================================================================================================
  // §6 出口：s3 能发就发；否则进 s4 / s5
  // ================================================================================================
  logic chnl_fire_s3, chnl_fire_s4, chnl_fire_s5;
  logic denied_s3, corrupt_s3, req_drop_s3;
  logic isD_s3, isTXREQ_s3, isTXRSP_s3, isTXDAT_s3;
  logic mshrOrNestData_s3;   // MSHR 任务 / 带数据的嵌套 snoop：denied/corrupt 不并目录错误

  assign mshrOrNestData_s3 = req.mshrTask || req.snpHitReleaseWithData;
  assign denied_s3   = mshrOrNestData_s3 ? req.denied  : (req.denied  || tagError);
  assign corrupt_s3  = mshrOrNestData_s3 ? req.corrupt : (req.corrupt || dataError);
  assign req_drop_s3 = !need_write_releaseBuf && (!mshr_req && need_mshr || chnl_fire_s3) || mshr_refill && retry;

  logic data_unready_s3, data_unready_tl_s3;   // s3 还拿不到要回的数据（通道请求的数据在 s5 才从 DS 读回）
  assign data_unready_s3    = hasData && !mshr_req;
  assign data_unready_tl_s3 = src.opcode[0] && !mshr_req;

  assign isD_s3     = mshr_req ? (mshr_cmoresp || mshr_refill && !retry)
                               : (fromC || fromA && !need_mshr_a && !data_unready_tl_s3 && req.opcode != A_Hint);
  assign isTXRSP_s3 = mshr_req ? mshr_snpRespX : (fromB && !need_mshr && !hasData);
  assign isTXDAT_s3 = mshr_req ? (mshr_snpRespDataX || mshr_cbWrData || mshr_dct)
                               : (fromB && !need_mshr &&
                                  doRespData && (!data_unready_s3 || req.snpHitRelease && req.snpHitReleaseWithData));
  assign isTXREQ_s3 = mshr_req && (mshr_writeBackFull || mshr_writeCleanFull || mshr_writeEvictFull ||
                                   mshr_writeEvictOrEvict || mshr_evict) && !req.meta_tagErr;   // tag 错不替换

  // 真正在 s3 发出的（d / txdat 的通道响应一律推到 s4：*_s3_latch 恒 true）
  logic d_s3_valid, txreq_s3_valid, txrsp_s3_valid, txdat_s3_valid;
  assign d_s3_valid     = s3_valid && (mshr_req ? (mshr_cmoresp || mshr_refill && !retry) : fromC);
  assign txreq_s3_valid = s3_valid && isTXREQ_s3;
  assign txrsp_s3_valid = s3_valid && isTXRSP_s3;
  assign txdat_s3_valid = s3_valid && mshr_req && (mshr_snpRespDataX || mshr_cbWrData || mshr_dct);
  assign chnl_fire_s3   = d_s3_valid && d_ready[2] || txreq_s3_valid && txreq_ready[2] ||
                          txrsp_s3_valid && txrsp_ready[2] || txdat_s3_valid && txdat_ready[2];

  // ---- s4 ----
  logic         s4_valid;
  task_t        s4;
  logic [511:0] data_s4;
  logic         needWRB_s4, isD_s4, isTXREQ_s4, isTXRSP_s4, isTXDAT_s4, tagError_s4, dataError_s4, l2Error_s4;
  logic         chnlFire_s3_d1;          // RegNext(chnl_fire_s3)

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s4_valid       <= 1'b0;
      s4             <= '0;
      needWRB_s4     <= 1'b0;
      isD_s4         <= 1'b0;
      isTXREQ_s4     <= 1'b0;
      isTXRSP_s4     <= 1'b0;
      isTXDAT_s4     <= 1'b0;
      tagError_s4    <= 1'b0;
      dataError_s4   <= 1'b0;
      l2Error_s4     <= 1'b0;
      chnlFire_s3_d1 <= 1'b0;
    end else begin
      s4_valid       <= s3_valid && !req_drop_s3;
      chnlFire_s3_d1 <= chnl_fire_s3;
      if (s3_valid) begin
        l2Error_s4 <= l2Error;
        // 丢弃时也记地址（给 io_error）
        s4.tag     <= src.tag;
        s4.set     <= src.set;
        s4.off     <= src.off;
        if (!req_drop_s3) begin
          s4        <= src;
          s4.mshrId <= (!mshr_req && need_mshr) ? mshr_alloc_ptr : src.mshrId;
          needWRB_s4   <= need_write_releaseBuf;
          isD_s4       <= isD_s3;
          isTXREQ_s4   <= isTXREQ_s3;
          isTXRSP_s4   <= isTXRSP_s3;
          isTXDAT_s4   <= isTXDAT_s3;
          tagError_s4  <= tagError;
          dataError_s4 <= dataError;
        end
      end
    end
  end
  always_ff @(posedge clock) begin
    if (s3_valid && !req_drop_s3) data_s4 <= data_s3;
  end

  logic req_drop_s4, chnl_valid_s4, mshrOrNestData_s4, denied_s4, corrupt_s4, pendingD_s4, pendingTXDAT_s4;
  assign req_drop_s4       = !needWRB_s4 && chnl_fire_s4;
  assign chnl_valid_s4     = s4_valid && !chnlFire_s3_d1;
  assign mshrOrNestData_s4 = s4.mshrTask || s4.snpHitReleaseWithData;
  assign denied_s4         = mshrOrNestData_s4 ? s4.denied  : (s4.denied  || tagError_s4);
  assign corrupt_s4        = mshrOrNestData_s4 ? s4.corrupt : (s4.corrupt || dataError_s4);
  // s3 推迟下来、要等 DS 数据的通道响应：到 s5 发
  assign pendingTXDAT_s4   = s4.channel[1] && !s4.mshrTask && s4.txChannel[2];
  assign pendingD_s4       = s4.channel[0] && !s4.mshrTask && (s4.opcode == D_GrantData || s4.opcode == D_AccessAckData);

  logic d_s4_valid, txreq_s4_valid, txrsp_s4_valid, txdat_s4_valid;
  assign d_s4_valid     = chnl_valid_s4 && isD_s4;
  assign txreq_s4_valid = chnl_valid_s4 && isTXREQ_s4;
  assign txrsp_s4_valid = chnl_valid_s4 && isTXRSP_s4;
  assign txdat_s4_valid = chnl_valid_s4 && isTXDAT_s4;
  assign chnl_fire_s4   = d_s4_valid && d_ready[1] || txreq_s4_valid && txreq_ready[1] ||
                          txrsp_s4_valid && txrsp_ready[1] || txdat_s4_valid && txdat_ready[1];

  // ---- s5 ----
  logic         s5_valid;
  task_t        s5;
  logic [511:0] data_s5;
  logic         needWRB_s5, isD_s5, isTXREQ_s5, isTXRSP_s5, isTXDAT_s5, tagError_s5, dataMetaError_s5, l2TagError_s5;
  logic         s3DropValid_d1;                   // RegNext(task_s3.valid && req_drop_s3)
  logic         chnlFire_s4_d1, chnlFire_s3_d1b, chnlFire_s3_d2;   // RegNext(chnl_fire_s4)、RegNextN(chnl_fire_s3, 2)

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s5_valid         <= 1'b0;
      s5               <= '0;
      needWRB_s5       <= 1'b0;
      isD_s5           <= 1'b0;
      isTXREQ_s5       <= 1'b0;
      isTXRSP_s5       <= 1'b0;
      isTXDAT_s5       <= 1'b0;
      tagError_s5      <= 1'b0;
      dataMetaError_s5 <= 1'b0;
      l2TagError_s5    <= 1'b0;
      chnlFire_s4_d1   <= 1'b0;
      chnlFire_s3_d1b  <= 1'b0;
      chnlFire_s3_d2   <= 1'b0;
    end else begin
      s5_valid        <= s4_valid && !req_drop_s4;
      chnlFire_s4_d1  <= chnl_fire_s4;
      chnlFire_s3_d1b <= chnl_fire_s3;
      chnlFire_s3_d2  <= chnlFire_s3_d1b;
      if (s4_valid || s3DropValid_d1) begin
        l2TagError_s5 <= l2Error_s4;
        s5.tag        <= s4.tag;
        s5.set        <= s4.set;
        s5.off        <= s4.off;
      end
      if (s4_valid && !req_drop_s4) begin
        s5               <= s4;
        needWRB_s5       <= needWRB_s4;
        isD_s5           <= isD_s4 || pendingD_s4;
        isTXREQ_s5       <= isTXREQ_s4;
        isTXRSP_s5       <= isTXRSP_s4;
        isTXDAT_s5       <= isTXDAT_s4 || pendingTXDAT_s4;
        tagError_s5      <= tagError_s4;
        dataMetaError_s5 <= dataError_s4;
      end
    end
  end
  always_ff @(posedge clock) begin
    if (s4_valid && !req_drop_s4) data_s5 <= data_s4;
    s3DropValid_d1 <= s3_valid && req_drop_s3;
  end

  logic         mshrOrNestData_s5, dataError_s5, l2Error_s5, chnl_valid_s5, denied_s5, corrupt_s5;
  logic [511:0] out_data_s5;
  assign mshrOrNestData_s5 = s5.mshrTask || s5.snpHitReleaseWithData;
  assign dataError_s5      = ds_error_s5 || dataMetaError_s5;
  assign l2Error_s5        = l2TagError_s5 || ds_error_s5;
  assign out_data_s5       = mshrOrNestData_s5 ? data_s5 : ds_rdata_s5;   // 通道响应用 DS 读回的数据
  assign chnl_valid_s5     = s5_valid && !chnlFire_s4_d1 && !chnlFire_s3_d2;
  assign denied_s5         = mshrOrNestData_s5 ? s5.denied  : (s5.denied  || tagError_s5);
  assign corrupt_s5        = mshrOrNestData_s5 ? s5.corrupt : (s5.corrupt || dataError_s5);

  logic d_s5_valid, txreq_s5_valid, txrsp_s5_valid, txdat_s5_valid;
  assign d_s5_valid     = chnl_valid_s5 && isD_s5;
  assign txreq_s5_valid = chnl_valid_s5 && isTXREQ_s5;
  assign txrsp_s5_valid = chnl_valid_s5 && isTXRSP_s5;
  assign txdat_s5_valid = chnl_valid_s5 && isTXDAT_s5;
  assign chnl_fire_s5   = d_s5_valid && d_ready[0] || txreq_s5_valid && txreq_ready[0] ||
                          txrsp_s5_valid && txrsp_ready[0] || txdat_s5_valid && txdat_ready[0];

  assign releaseBufW_valid = s5_valid && needWRB_s5;
  assign s5_mshrId         = s5.mshrId;

  // ---- 四类出口的三路载荷（k：0=s5 1=s4 2=s3） ----
  always_comb begin
    d_valid[0] = d_s5_valid;
    d_valid[1] = d_s4_valid;
    d_valid[2] = d_s3_valid;
    d_task[0] = s5;
    d_task[0].denied  = denied_s5;
    d_task[0].corrupt = corrupt_s5;
    d_task[1] = s4;
    d_task[1].denied  = denied_s4;
    d_task[1].corrupt = corrupt_s4;
    d_task[2] = src;
    d_task[2].opcode  = mshr_req ? req.opcode : sink_resp.opcode;
    d_task[2].denied  = denied_s3;
    d_task[2].corrupt = corrupt_s3;
    d_data[0] = out_data_s5;
    d_data[1] = data_s4;
    d_data[2] = data_s3;

    txreq_valid[0] = txreq_s5_valid;
    txreq_valid[1] = txreq_s4_valid;
    txreq_valid[2] = txreq_s3_valid;
    txreq_bits[0]  = toCHIREQ(s5);
    txreq_bits[1]  = toCHIREQ(s4);
    txreq_bits[2]  = toCHIREQ(src);

    txrsp_valid[0] = txrsp_s5_valid;
    txrsp_valid[1] = txrsp_s4_valid;
    txrsp_valid[2] = txrsp_s3_valid;
    txrsp_task[0] = s5;
    txrsp_task[0].denied = denied_s5;
    txrsp_task[1] = s4;
    txrsp_task[1].denied = denied_s4;
    txrsp_task[2] = src;
    txrsp_task[2].denied = denied_s3;

    txdat_valid[0] = txdat_s5_valid;
    txdat_valid[1] = txdat_s4_valid;
    txdat_valid[2] = txdat_s3_valid;
    txdat_task[0] = s5;
    txdat_task[0].corrupt = corrupt_s5;
    txdat_task[1] = s4;
    txdat_task[1].corrupt = corrupt_s4;
    txdat_task[2] = src;
    txdat_task[2].corrupt = corrupt_s3;
    txdat_data[0] = out_data_s5;
    txdat_data[1] = data_s4;
    txdat_data[2] = data_s3;
  end

  // CustomL1Hint 的 s3 输入：能当场响应就用响应的 D opcode
  always_comb begin
    hint_s3_task        = req;
    hint_s3_task.opcode = sink_resp_valid ? sink_resp.opcode : req.opcode;
  end
  assign hint_s3_valid     = s3_valid;
  assign hint_s3_need_mshr = need_mshr;

  // ================================================================================================
  // §7 入口阻塞与流水线状态
  // ================================================================================================
  // s2/s3 可能写目录：挡 s1 同组的通道请求（确定不写 meta 的 MSHR 任务除外）
  function automatic logic s23Block(input task_t t, input logic [8:0] s1set);
    return t.set == s1set && !(t.mshrTask && !t.metaWen);
  endfunction
  assign toReqBuf_0 = s2_valid && s23Block(s2_task, s1_a_set);
  assign toReqBuf_1 = s3_valid && s23Block(req, s1_a_set);
  assign blockC_s1  = s2_valid && s23Block(s2_task, s1_c_set);
  assign blockG_s1  = s2_valid && s23Block(s2_task, s1_g_set);
  assign blockB_s1  = s2_valid && s2_task.set == s1_b_set || s3_valid && req.set == s1_b_set ||
                      s4_valid && s4.set == s1_b_set && s4.tag == s1_b_tag ||
                      s5_valid && s5.set == s1_b_set && s5.tag == s1_b_tag;

  assign statusD_valid[0]   = s3_valid && (mshr_req ? (mshr_refill && !retry) : 1'b1);
  assign statusD_channel[0] = req.channel;
  assign statusD_valid[1]   = s4_valid && (isD_s4 || pendingD_s4);
  assign statusD_channel[1] = s4.channel;
  assign statusD_valid[2]   = d_s5_valid;
  assign statusD_channel[2] = s5.channel;

  assign statusTX_valid[0]     = s3_valid;
  assign statusTX_channel[0]   = req.channel;
  assign statusTX_txChannel[0] = src.txChannel;
  assign statusTX_mshrTask[0]  = req.mshrTask;
  assign statusTX_valid[1]     = s4_valid;
  assign statusTX_channel[1]   = s4.channel;
  assign statusTX_txChannel[1] = s4.txChannel;
  assign statusTX_mshrTask[1]  = s4.mshrTask;
  assign statusTX_valid[2]     = s5_valid;
  assign statusTX_channel[2]   = s5.channel;
  assign statusTX_txChannel[2] = s5.txChannel;
  assign statusTX_mshrTask[2]  = s5.mshrTask;

  // ================================================================================================
  // §8 ECC 错误上报与 perf 事件
  // ================================================================================================
  logic reqDrop_s3_d1, reqDrop_s3_d2, reqDrop_s4_d1, reqDropped_s5;
  always_ff @(posedge clock) begin
    reqDrop_s3_d1 <= req_drop_s3 && s3_valid;
    reqDrop_s3_d2 <= reqDrop_s3_d1;
    reqDrop_s4_d1 <= req_drop_s4 && s4_valid;
  end
  assign reqDropped_s5  = reqDrop_s3_d2 || reqDrop_s4_d1;
  assign err_valid      = s5_valid || reqDropped_s5;
  assign err_bits_valid = reqDropped_s5 ? l2TagError_s5 : l2Error_s5;
  assign err_address    = {s5.tag, s5.set, s5.off};

  logic hit_s3, miss_s3;
  assign hit_s3  = s3_valid && !mshr_req && dir_hit;
  assign miss_s3 = s3_valid && !mshr_req && !dir_hit;
  logic perfEv [13];
  assign perfEv[0]  = hit_s3 && fromA;                                                     // l2_cache_hit
  assign perfEv[1]  = miss_s3 && fromA;                                                    // l2_cache_miss
  assign perfEv[2]  = s3_valid && (sinkA_req && !req_prefetch || sinkC_req);               // l2_cache_access
  assign perfEv[3]  = s3_valid && (mshr_cbWrData || mshr_snpRespDataX);                    // l2_cache_l2wb
  assign perfEv[4]  = s3_valid && sinkC_req && req.opcode == C_ReleaseData;                // l2_cache_l1wb
  assign perfEv[5]  = s3_valid && mshr_cbWrData;                                           // l2_cache_wb_victim
  assign perfEv[6]  = s3_valid && mshr_snpRespDataX;                                       // l2_cache_wb_cleaning_coh
  assign perfEv[7]  = s3_valid && sinkA_req && req_prefetch;                               // l2_cache_prefetch_access
  assign perfEv[8]  = s3_valid && sinkA_req && req_prefetch && miss_s3;                    // l2_cache_prefetch_miss
  assign perfEv[9]  = s3_valid && sinkA_req && !req_prefetch;                              // l2_cache_access_rd
  assign perfEv[10] = s3_valid && sinkC_req;                                               // l2_cache_access_wr
  assign perfEv[11] = s3_valid && sinkA_req && !req_prefetch && miss_s3;                   // l2_cache_miss_rd
  assign perfEv[12] = s3_valid && sinkB_req && req.param == 3'd2;                          // l2_cache_inv（toN）

  logic perf_d1 [13];
  always_ff @(posedge clock) begin
    for (int i = 0; i < 13; i++) begin
      perf_d1[i] <= perfEv[i];
      perf[i]    <= perf_d1[i];
    end
  end

endmodule

// BEGIN GENERATED(wrapper) —— scripts/gen_l2_mainpipe.py 从 golden 端口表生成
module MainPipe_1
  import l2mainpipe_pkg::*;
(
  input  logic clock,
  input  logic reset,
  input  logic io_taskFromArb_s2_valid,
  input  logic [2:0] io_taskFromArb_s2_bits_channel,
  input  logic [2:0] io_taskFromArb_s2_bits_txChannel,
  input  logic [8:0] io_taskFromArb_s2_bits_set,
  input  logic [30:0] io_taskFromArb_s2_bits_tag,
  input  logic [5:0] io_taskFromArb_s2_bits_off,
  input  logic [1:0] io_taskFromArb_s2_bits_alias,
  input  logic [43:0] io_taskFromArb_s2_bits_vaddr,
  input  logic io_taskFromArb_s2_bits_isKeyword,
  input  logic [3:0] io_taskFromArb_s2_bits_opcode,
  input  logic [2:0] io_taskFromArb_s2_bits_param,
  input  logic [2:0] io_taskFromArb_s2_bits_size,
  input  logic [6:0] io_taskFromArb_s2_bits_sourceId,
  input  logic [1:0] io_taskFromArb_s2_bits_bufIdx,
  input  logic io_taskFromArb_s2_bits_needProbeAckData,
  input  logic io_taskFromArb_s2_bits_denied,
  input  logic io_taskFromArb_s2_bits_corrupt,
  input  logic io_taskFromArb_s2_bits_mshrTask,
  input  logic [7:0] io_taskFromArb_s2_bits_mshrId,
  input  logic io_taskFromArb_s2_bits_aliasTask,
  input  logic io_taskFromArb_s2_bits_useProbeData,
  input  logic io_taskFromArb_s2_bits_mshrRetry,
  input  logic io_taskFromArb_s2_bits_readProbeDataDown,
  input  logic io_taskFromArb_s2_bits_fromL2pft,
  input  logic io_taskFromArb_s2_bits_needHint,
  input  logic io_taskFromArb_s2_bits_dirty,
  input  logic [2:0] io_taskFromArb_s2_bits_way,
  input  logic io_taskFromArb_s2_bits_meta_dirty,
  input  logic [1:0] io_taskFromArb_s2_bits_meta_state,
  input  logic io_taskFromArb_s2_bits_meta_clients,
  input  logic [1:0] io_taskFromArb_s2_bits_meta_alias,
  input  logic io_taskFromArb_s2_bits_meta_prefetch,
  input  logic [2:0] io_taskFromArb_s2_bits_meta_prefetchSrc,
  input  logic io_taskFromArb_s2_bits_meta_accessed,
  input  logic io_taskFromArb_s2_bits_meta_tagErr,
  input  logic io_taskFromArb_s2_bits_meta_dataErr,
  input  logic io_taskFromArb_s2_bits_metaWen,
  input  logic io_taskFromArb_s2_bits_tagWen,
  input  logic io_taskFromArb_s2_bits_dsWen,
  input  logic [7:0] io_taskFromArb_s2_bits_wayMask,
  input  logic io_taskFromArb_s2_bits_replTask,
  input  logic io_taskFromArb_s2_bits_cmoTask,
  input  logic io_taskFromArb_s2_bits_cmoAll,
  input  logic [4:0] io_taskFromArb_s2_bits_reqSource,
  input  logic io_taskFromArb_s2_bits_mergeA,
  input  logic [5:0] io_taskFromArb_s2_bits_aMergeTask_off,
  input  logic [1:0] io_taskFromArb_s2_bits_aMergeTask_alias,
  input  logic [43:0] io_taskFromArb_s2_bits_aMergeTask_vaddr,
  input  logic io_taskFromArb_s2_bits_aMergeTask_isKeyword,
  input  logic [2:0] io_taskFromArb_s2_bits_aMergeTask_opcode,
  input  logic [2:0] io_taskFromArb_s2_bits_aMergeTask_param,
  input  logic [6:0] io_taskFromArb_s2_bits_aMergeTask_sourceId,
  input  logic io_taskFromArb_s2_bits_aMergeTask_meta_dirty,
  input  logic [1:0] io_taskFromArb_s2_bits_aMergeTask_meta_state,
  input  logic io_taskFromArb_s2_bits_aMergeTask_meta_clients,
  input  logic [1:0] io_taskFromArb_s2_bits_aMergeTask_meta_alias,
  input  logic io_taskFromArb_s2_bits_aMergeTask_meta_prefetch,
  input  logic [2:0] io_taskFromArb_s2_bits_aMergeTask_meta_prefetchSrc,
  input  logic io_taskFromArb_s2_bits_aMergeTask_meta_accessed,
  input  logic io_taskFromArb_s2_bits_aMergeTask_meta_tagErr,
  input  logic io_taskFromArb_s2_bits_aMergeTask_meta_dataErr,
  input  logic io_taskFromArb_s2_bits_snpHitRelease,
  input  logic io_taskFromArb_s2_bits_snpHitReleaseToInval,
  input  logic io_taskFromArb_s2_bits_snpHitReleaseToClean,
  input  logic io_taskFromArb_s2_bits_snpHitReleaseWithData,
  input  logic [7:0] io_taskFromArb_s2_bits_snpHitReleaseIdx,
  input  logic io_taskFromArb_s2_bits_snpHitReleaseMeta_dirty,
  input  logic [1:0] io_taskFromArb_s2_bits_snpHitReleaseMeta_state,
  input  logic io_taskFromArb_s2_bits_snpHitReleaseMeta_clients,
  input  logic [1:0] io_taskFromArb_s2_bits_snpHitReleaseMeta_alias,
  input  logic io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetch,
  input  logic [2:0] io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetchSrc,
  input  logic io_taskFromArb_s2_bits_snpHitReleaseMeta_accessed,
  input  logic io_taskFromArb_s2_bits_snpHitReleaseMeta_tagErr,
  input  logic io_taskFromArb_s2_bits_snpHitReleaseMeta_dataErr,
  input  logic [10:0] io_taskFromArb_s2_bits_tgtID,
  input  logic [10:0] io_taskFromArb_s2_bits_srcID,
  input  logic [11:0] io_taskFromArb_s2_bits_txnID,
  input  logic [10:0] io_taskFromArb_s2_bits_homeNID,
  input  logic [11:0] io_taskFromArb_s2_bits_dbID,
  input  logic [10:0] io_taskFromArb_s2_bits_fwdNID,
  input  logic [11:0] io_taskFromArb_s2_bits_fwdTxnID,
  input  logic [6:0] io_taskFromArb_s2_bits_chiOpcode,
  input  logic [2:0] io_taskFromArb_s2_bits_resp,
  input  logic [2:0] io_taskFromArb_s2_bits_fwdState,
  input  logic [3:0] io_taskFromArb_s2_bits_pCrdType,
  input  logic io_taskFromArb_s2_bits_retToSrc,
  input  logic io_taskFromArb_s2_bits_likelyshared,
  input  logic io_taskFromArb_s2_bits_expCompAck,
  input  logic io_taskFromArb_s2_bits_allowRetry,
  input  logic io_taskFromArb_s2_bits_memAttr_allocate,
  input  logic io_taskFromArb_s2_bits_memAttr_cacheable,
  input  logic io_taskFromArb_s2_bits_memAttr_device,
  input  logic io_taskFromArb_s2_bits_memAttr_ewa,
  input  logic io_taskFromArb_s2_bits_traceTag,
  input  logic io_taskInfo_s1_valid,
  input  logic [2:0] io_taskInfo_s1_bits_channel,
  input  logic io_taskInfo_s1_bits_isKeyword,
  input  logic [3:0] io_taskInfo_s1_bits_opcode,
  input  logic [6:0] io_taskInfo_s1_bits_sourceId,
  input  logic io_taskInfo_s1_bits_mshrTask,
  input  logic io_taskInfo_s1_bits_mergeA,
  input  logic io_taskInfo_s1_bits_aMergeTask_isKeyword,
  input  logic [2:0] io_taskInfo_s1_bits_aMergeTask_opcode,
  input  logic [6:0] io_taskInfo_s1_bits_aMergeTask_sourceId,
  input  logic [30:0] io_fromReqArb_status_s1_tags_1,
  input  logic [8:0] io_fromReqArb_status_s1_sets_0,
  input  logic [8:0] io_fromReqArb_status_s1_sets_1,
  input  logic [8:0] io_fromReqArb_status_s1_sets_2,
  input  logic [8:0] io_fromReqArb_status_s1_sets_3,
  output logic io_toReqArb_blockG_s1,
  output logic io_toReqArb_blockB_s1,
  output logic io_toReqArb_blockC_s1,
  output logic io_toReqBuf_0,
  output logic io_toReqBuf_1,
  output logic io_status_vec_toD_0_valid,
  output logic [2:0] io_status_vec_toD_0_bits_channel,
  output logic io_status_vec_toD_1_valid,
  output logic [2:0] io_status_vec_toD_1_bits_channel,
  output logic io_status_vec_toD_2_valid,
  output logic [2:0] io_status_vec_toD_2_bits_channel,
  output logic io_status_vec_toTX_0_valid,
  output logic [2:0] io_status_vec_toTX_0_bits_channel,
  output logic [2:0] io_status_vec_toTX_0_bits_txChannel,
  output logic io_status_vec_toTX_0_bits_mshrTask,
  output logic io_status_vec_toTX_1_valid,
  output logic [2:0] io_status_vec_toTX_1_bits_channel,
  output logic [2:0] io_status_vec_toTX_1_bits_txChannel,
  output logic io_status_vec_toTX_1_bits_mshrTask,
  output logic io_status_vec_toTX_2_valid,
  output logic [2:0] io_status_vec_toTX_2_bits_channel,
  output logic [2:0] io_status_vec_toTX_2_bits_txChannel,
  output logic io_status_vec_toTX_2_bits_mshrTask,
  input  logic io_dirResp_s3_valid,
  input  logic io_dirResp_s3_bits_hit,
  input  logic [30:0] io_dirResp_s3_bits_tag,
  input  logic [8:0] io_dirResp_s3_bits_set,
  input  logic [2:0] io_dirResp_s3_bits_way,
  input  logic io_dirResp_s3_bits_meta_dirty,
  input  logic [1:0] io_dirResp_s3_bits_meta_state,
  input  logic io_dirResp_s3_bits_meta_clients,
  input  logic [1:0] io_dirResp_s3_bits_meta_alias,
  input  logic io_dirResp_s3_bits_meta_prefetch,
  input  logic [2:0] io_dirResp_s3_bits_meta_prefetchSrc,
  input  logic io_dirResp_s3_bits_meta_accessed,
  input  logic io_dirResp_s3_bits_meta_tagErr,
  input  logic io_dirResp_s3_bits_meta_dataErr,
  input  logic io_dirResp_s3_bits_error,
  input  logic io_replResp_valid,
  input  logic [2:0] io_replResp_bits_way,
  input  logic [1:0] io_replResp_bits_meta_state,
  input  logic io_replResp_bits_retry,
  output logic io_toMSHRCtl_mshr_alloc_s3_valid,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_hit,
  output logic [30:0] io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_tag,
  output logic [8:0] io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_set,
  output logic [2:0] io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_way,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dirty,
  output logic [1:0] io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_state,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_clients,
  output logic [1:0] io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_alias,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetch,
  output logic [2:0] io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_accessed,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_tagErr,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dataErr,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_error,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_state_s_acquire,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rprobe,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_state_s_pprobe,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_state_s_release,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_state_s_probeack,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_state_s_refill,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_state_s_cmoresp,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeackfirst,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeacklast,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeackfirst,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeacklast,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantfirst,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantlast,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grant,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_state_w_releaseack,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_state_w_replResp,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rcompack,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_state_s_dct,
  output logic [2:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_channel,
  output logic [8:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_set,
  output logic [30:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_tag,
  output logic [5:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_off,
  output logic [1:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_alias,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_task_isKeyword,
  output logic [3:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_opcode,
  output logic [2:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_param,
  output logic [6:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_sourceId,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_task_denied,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_task_corrupt,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_task_aliasTask,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_task_fromL2pft,
  output logic [4:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_reqSource,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitRelease,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToInval,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToClean,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseWithData,
  output logic [7:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseIdx,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty,
  output logic [1:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients,
  output logic [1:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch,
  output logic [2:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr,
  output logic [10:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_srcID,
  output logic [11:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_txnID,
  output logic [10:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdNID,
  output logic [11:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdTxnID,
  output logic [6:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_chiOpcode,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_task_retToSrc,
  output logic io_toMSHRCtl_mshr_alloc_s3_bits_task_traceTag,
  input  logic [7:0] io_fromMSHRCtl_mshr_alloc_ptr,
  input  logic [255:0] io_bufResp_data_0,
  input  logic [255:0] io_bufResp_data_1,
  input  logic [511:0] io_refillBufResp_s3_bits_data,
  input  logic io_releaseBufResp_s3_valid,
  input  logic [511:0] io_releaseBufResp_s3_bits_data,
  output logic io_toDS_en_s3,
  output logic io_toDS_req_s3_valid,
  output logic [2:0] io_toDS_req_s3_bits_way,
  output logic [8:0] io_toDS_req_s3_bits_set,
  output logic io_toDS_req_s3_bits_wen,
  input  logic [511:0] io_toDS_rdata_s5_data,
  output logic [511:0] io_toDS_wdata_s3_data,
  input  logic io_toDS_error_s5,
  output logic io_toSourceD_valid,
  output logic [2:0] io_toSourceD_bits_task_channel,
  output logic [2:0] io_toSourceD_bits_task_txChannel,
  output logic [8:0] io_toSourceD_bits_task_set,
  output logic [30:0] io_toSourceD_bits_task_tag,
  output logic [5:0] io_toSourceD_bits_task_off,
  output logic [1:0] io_toSourceD_bits_task_alias,
  output logic [43:0] io_toSourceD_bits_task_vaddr,
  output logic io_toSourceD_bits_task_isKeyword,
  output logic [3:0] io_toSourceD_bits_task_opcode,
  output logic [2:0] io_toSourceD_bits_task_param,
  output logic [2:0] io_toSourceD_bits_task_size,
  output logic [6:0] io_toSourceD_bits_task_sourceId,
  output logic [1:0] io_toSourceD_bits_task_bufIdx,
  output logic io_toSourceD_bits_task_needProbeAckData,
  output logic io_toSourceD_bits_task_denied,
  output logic io_toSourceD_bits_task_corrupt,
  output logic io_toSourceD_bits_task_mshrTask,
  output logic [7:0] io_toSourceD_bits_task_mshrId,
  output logic io_toSourceD_bits_task_aliasTask,
  output logic io_toSourceD_bits_task_useProbeData,
  output logic io_toSourceD_bits_task_mshrRetry,
  output logic io_toSourceD_bits_task_readProbeDataDown,
  output logic io_toSourceD_bits_task_fromL2pft,
  output logic io_toSourceD_bits_task_needHint,
  output logic io_toSourceD_bits_task_dirty,
  output logic [2:0] io_toSourceD_bits_task_way,
  output logic io_toSourceD_bits_task_meta_dirty,
  output logic [1:0] io_toSourceD_bits_task_meta_state,
  output logic io_toSourceD_bits_task_meta_clients,
  output logic [1:0] io_toSourceD_bits_task_meta_alias,
  output logic io_toSourceD_bits_task_meta_prefetch,
  output logic [2:0] io_toSourceD_bits_task_meta_prefetchSrc,
  output logic io_toSourceD_bits_task_meta_accessed,
  output logic io_toSourceD_bits_task_meta_tagErr,
  output logic io_toSourceD_bits_task_meta_dataErr,
  output logic io_toSourceD_bits_task_metaWen,
  output logic io_toSourceD_bits_task_tagWen,
  output logic io_toSourceD_bits_task_dsWen,
  output logic [7:0] io_toSourceD_bits_task_wayMask,
  output logic io_toSourceD_bits_task_replTask,
  output logic io_toSourceD_bits_task_cmoTask,
  output logic io_toSourceD_bits_task_cmoAll,
  output logic [4:0] io_toSourceD_bits_task_reqSource,
  output logic io_toSourceD_bits_task_mergeA,
  output logic [5:0] io_toSourceD_bits_task_aMergeTask_off,
  output logic [1:0] io_toSourceD_bits_task_aMergeTask_alias,
  output logic [43:0] io_toSourceD_bits_task_aMergeTask_vaddr,
  output logic io_toSourceD_bits_task_aMergeTask_isKeyword,
  output logic [2:0] io_toSourceD_bits_task_aMergeTask_opcode,
  output logic [2:0] io_toSourceD_bits_task_aMergeTask_param,
  output logic [6:0] io_toSourceD_bits_task_aMergeTask_sourceId,
  output logic io_toSourceD_bits_task_aMergeTask_meta_dirty,
  output logic [1:0] io_toSourceD_bits_task_aMergeTask_meta_state,
  output logic io_toSourceD_bits_task_aMergeTask_meta_clients,
  output logic [1:0] io_toSourceD_bits_task_aMergeTask_meta_alias,
  output logic io_toSourceD_bits_task_aMergeTask_meta_prefetch,
  output logic [2:0] io_toSourceD_bits_task_aMergeTask_meta_prefetchSrc,
  output logic io_toSourceD_bits_task_aMergeTask_meta_accessed,
  output logic io_toSourceD_bits_task_aMergeTask_meta_tagErr,
  output logic io_toSourceD_bits_task_aMergeTask_meta_dataErr,
  output logic io_toSourceD_bits_task_snpHitRelease,
  output logic io_toSourceD_bits_task_snpHitReleaseToInval,
  output logic io_toSourceD_bits_task_snpHitReleaseToClean,
  output logic io_toSourceD_bits_task_snpHitReleaseWithData,
  output logic [7:0] io_toSourceD_bits_task_snpHitReleaseIdx,
  output logic io_toSourceD_bits_task_snpHitReleaseMeta_dirty,
  output logic [1:0] io_toSourceD_bits_task_snpHitReleaseMeta_state,
  output logic io_toSourceD_bits_task_snpHitReleaseMeta_clients,
  output logic [1:0] io_toSourceD_bits_task_snpHitReleaseMeta_alias,
  output logic io_toSourceD_bits_task_snpHitReleaseMeta_prefetch,
  output logic [2:0] io_toSourceD_bits_task_snpHitReleaseMeta_prefetchSrc,
  output logic io_toSourceD_bits_task_snpHitReleaseMeta_accessed,
  output logic io_toSourceD_bits_task_snpHitReleaseMeta_tagErr,
  output logic io_toSourceD_bits_task_snpHitReleaseMeta_dataErr,
  output logic [10:0] io_toSourceD_bits_task_tgtID,
  output logic [10:0] io_toSourceD_bits_task_srcID,
  output logic [11:0] io_toSourceD_bits_task_txnID,
  output logic [10:0] io_toSourceD_bits_task_homeNID,
  output logic [11:0] io_toSourceD_bits_task_dbID,
  output logic [10:0] io_toSourceD_bits_task_fwdNID,
  output logic [11:0] io_toSourceD_bits_task_fwdTxnID,
  output logic [6:0] io_toSourceD_bits_task_chiOpcode,
  output logic [2:0] io_toSourceD_bits_task_resp,
  output logic [2:0] io_toSourceD_bits_task_fwdState,
  output logic [3:0] io_toSourceD_bits_task_pCrdType,
  output logic io_toSourceD_bits_task_retToSrc,
  output logic io_toSourceD_bits_task_likelyshared,
  output logic io_toSourceD_bits_task_expCompAck,
  output logic io_toSourceD_bits_task_allowRetry,
  output logic io_toSourceD_bits_task_memAttr_allocate,
  output logic io_toSourceD_bits_task_memAttr_cacheable,
  output logic io_toSourceD_bits_task_memAttr_device,
  output logic io_toSourceD_bits_task_memAttr_ewa,
  output logic io_toSourceD_bits_task_traceTag,
  output logic [511:0] io_toSourceD_bits_data_data,
  output logic io_toTXREQ_valid,
  output logic [10:0] io_toTXREQ_bits_tgtID,
  output logic [10:0] io_toTXREQ_bits_srcID,
  output logic [11:0] io_toTXREQ_bits_txnID,
  output logic [6:0] io_toTXREQ_bits_opcode,
  output logic [47:0] io_toTXREQ_bits_addr,
  output logic io_toTXREQ_bits_likelyshared,
  output logic io_toTXREQ_bits_allowRetry,
  output logic [3:0] io_toTXREQ_bits_pCrdType,
  output logic io_toTXREQ_bits_memAttr_allocate,
  output logic io_toTXREQ_bits_memAttr_cacheable,
  output logic io_toTXREQ_bits_memAttr_device,
  output logic io_toTXREQ_bits_memAttr_ewa,
  output logic io_toTXREQ_bits_expCompAck,
  output logic io_toTXRSP_valid,
  output logic [2:0] io_toTXRSP_bits_txChannel,
  output logic io_toTXRSP_bits_denied,
  output logic [10:0] io_toTXRSP_bits_tgtID,
  output logic [10:0] io_toTXRSP_bits_srcID,
  output logic [11:0] io_toTXRSP_bits_txnID,
  output logic [11:0] io_toTXRSP_bits_dbID,
  output logic [6:0] io_toTXRSP_bits_chiOpcode,
  output logic [2:0] io_toTXRSP_bits_resp,
  output logic [2:0] io_toTXRSP_bits_fwdState,
  output logic [3:0] io_toTXRSP_bits_pCrdType,
  output logic io_toTXRSP_bits_traceTag,
  input  logic io_toTXDAT_ready,
  output logic io_toTXDAT_valid,
  output logic [2:0] io_toTXDAT_bits_task_channel,
  output logic [2:0] io_toTXDAT_bits_task_txChannel,
  output logic [8:0] io_toTXDAT_bits_task_set,
  output logic [30:0] io_toTXDAT_bits_task_tag,
  output logic [5:0] io_toTXDAT_bits_task_off,
  output logic [1:0] io_toTXDAT_bits_task_alias,
  output logic [43:0] io_toTXDAT_bits_task_vaddr,
  output logic io_toTXDAT_bits_task_isKeyword,
  output logic [3:0] io_toTXDAT_bits_task_opcode,
  output logic [2:0] io_toTXDAT_bits_task_param,
  output logic [2:0] io_toTXDAT_bits_task_size,
  output logic [6:0] io_toTXDAT_bits_task_sourceId,
  output logic [1:0] io_toTXDAT_bits_task_bufIdx,
  output logic io_toTXDAT_bits_task_needProbeAckData,
  output logic io_toTXDAT_bits_task_denied,
  output logic io_toTXDAT_bits_task_corrupt,
  output logic io_toTXDAT_bits_task_mshrTask,
  output logic [7:0] io_toTXDAT_bits_task_mshrId,
  output logic io_toTXDAT_bits_task_aliasTask,
  output logic io_toTXDAT_bits_task_useProbeData,
  output logic io_toTXDAT_bits_task_mshrRetry,
  output logic io_toTXDAT_bits_task_readProbeDataDown,
  output logic io_toTXDAT_bits_task_fromL2pft,
  output logic io_toTXDAT_bits_task_needHint,
  output logic io_toTXDAT_bits_task_dirty,
  output logic [2:0] io_toTXDAT_bits_task_way,
  output logic io_toTXDAT_bits_task_meta_dirty,
  output logic [1:0] io_toTXDAT_bits_task_meta_state,
  output logic io_toTXDAT_bits_task_meta_clients,
  output logic [1:0] io_toTXDAT_bits_task_meta_alias,
  output logic io_toTXDAT_bits_task_meta_prefetch,
  output logic [2:0] io_toTXDAT_bits_task_meta_prefetchSrc,
  output logic io_toTXDAT_bits_task_meta_accessed,
  output logic io_toTXDAT_bits_task_meta_tagErr,
  output logic io_toTXDAT_bits_task_meta_dataErr,
  output logic io_toTXDAT_bits_task_metaWen,
  output logic io_toTXDAT_bits_task_tagWen,
  output logic io_toTXDAT_bits_task_dsWen,
  output logic [7:0] io_toTXDAT_bits_task_wayMask,
  output logic io_toTXDAT_bits_task_replTask,
  output logic io_toTXDAT_bits_task_cmoTask,
  output logic io_toTXDAT_bits_task_cmoAll,
  output logic [4:0] io_toTXDAT_bits_task_reqSource,
  output logic io_toTXDAT_bits_task_mergeA,
  output logic [5:0] io_toTXDAT_bits_task_aMergeTask_off,
  output logic [1:0] io_toTXDAT_bits_task_aMergeTask_alias,
  output logic [43:0] io_toTXDAT_bits_task_aMergeTask_vaddr,
  output logic io_toTXDAT_bits_task_aMergeTask_isKeyword,
  output logic [2:0] io_toTXDAT_bits_task_aMergeTask_opcode,
  output logic [2:0] io_toTXDAT_bits_task_aMergeTask_param,
  output logic [6:0] io_toTXDAT_bits_task_aMergeTask_sourceId,
  output logic io_toTXDAT_bits_task_aMergeTask_meta_dirty,
  output logic [1:0] io_toTXDAT_bits_task_aMergeTask_meta_state,
  output logic io_toTXDAT_bits_task_aMergeTask_meta_clients,
  output logic [1:0] io_toTXDAT_bits_task_aMergeTask_meta_alias,
  output logic io_toTXDAT_bits_task_aMergeTask_meta_prefetch,
  output logic [2:0] io_toTXDAT_bits_task_aMergeTask_meta_prefetchSrc,
  output logic io_toTXDAT_bits_task_aMergeTask_meta_accessed,
  output logic io_toTXDAT_bits_task_aMergeTask_meta_tagErr,
  output logic io_toTXDAT_bits_task_aMergeTask_meta_dataErr,
  output logic io_toTXDAT_bits_task_snpHitRelease,
  output logic io_toTXDAT_bits_task_snpHitReleaseToInval,
  output logic io_toTXDAT_bits_task_snpHitReleaseToClean,
  output logic io_toTXDAT_bits_task_snpHitReleaseWithData,
  output logic [7:0] io_toTXDAT_bits_task_snpHitReleaseIdx,
  output logic io_toTXDAT_bits_task_snpHitReleaseMeta_dirty,
  output logic [1:0] io_toTXDAT_bits_task_snpHitReleaseMeta_state,
  output logic io_toTXDAT_bits_task_snpHitReleaseMeta_clients,
  output logic [1:0] io_toTXDAT_bits_task_snpHitReleaseMeta_alias,
  output logic io_toTXDAT_bits_task_snpHitReleaseMeta_prefetch,
  output logic [2:0] io_toTXDAT_bits_task_snpHitReleaseMeta_prefetchSrc,
  output logic io_toTXDAT_bits_task_snpHitReleaseMeta_accessed,
  output logic io_toTXDAT_bits_task_snpHitReleaseMeta_tagErr,
  output logic io_toTXDAT_bits_task_snpHitReleaseMeta_dataErr,
  output logic [10:0] io_toTXDAT_bits_task_tgtID,
  output logic [10:0] io_toTXDAT_bits_task_srcID,
  output logic [11:0] io_toTXDAT_bits_task_txnID,
  output logic [10:0] io_toTXDAT_bits_task_homeNID,
  output logic [11:0] io_toTXDAT_bits_task_dbID,
  output logic [10:0] io_toTXDAT_bits_task_fwdNID,
  output logic [11:0] io_toTXDAT_bits_task_fwdTxnID,
  output logic [6:0] io_toTXDAT_bits_task_chiOpcode,
  output logic [2:0] io_toTXDAT_bits_task_resp,
  output logic [2:0] io_toTXDAT_bits_task_fwdState,
  output logic [3:0] io_toTXDAT_bits_task_pCrdType,
  output logic io_toTXDAT_bits_task_retToSrc,
  output logic io_toTXDAT_bits_task_likelyshared,
  output logic io_toTXDAT_bits_task_expCompAck,
  output logic io_toTXDAT_bits_task_allowRetry,
  output logic io_toTXDAT_bits_task_memAttr_allocate,
  output logic io_toTXDAT_bits_task_memAttr_cacheable,
  output logic io_toTXDAT_bits_task_memAttr_device,
  output logic io_toTXDAT_bits_task_memAttr_ewa,
  output logic io_toTXDAT_bits_task_traceTag,
  output logic [511:0] io_toTXDAT_bits_data_data,
  output logic io_metaWReq_valid,
  output logic [8:0] io_metaWReq_bits_set,
  output logic [7:0] io_metaWReq_bits_wayOH,
  output logic io_metaWReq_bits_wmeta_dirty,
  output logic [1:0] io_metaWReq_bits_wmeta_state,
  output logic io_metaWReq_bits_wmeta_clients,
  output logic [1:0] io_metaWReq_bits_wmeta_alias,
  output logic io_metaWReq_bits_wmeta_prefetch,
  output logic [2:0] io_metaWReq_bits_wmeta_prefetchSrc,
  output logic io_metaWReq_bits_wmeta_accessed,
  output logic io_metaWReq_bits_wmeta_tagErr,
  output logic io_metaWReq_bits_wmeta_dataErr,
  output logic io_tagWReq_valid,
  output logic [8:0] io_tagWReq_bits_set,
  output logic [2:0] io_tagWReq_bits_way,
  output logic [30:0] io_tagWReq_bits_wtag,
  output logic io_releaseBufWrite_valid,
  output logic [7:0] io_releaseBufWrite_bits_id,
  output logic [511:0] io_releaseBufWrite_bits_data_data,
  output logic io_dsResp_valid,
  output logic [7:0] io_dsResp_bits_mshrId,
  output logic io_dsResp_bits_dataError,
  output logic [8:0] io_nestedwb_set,
  output logic [30:0] io_nestedwb_tag,
  output logic io_nestedwb_c_set_dirty,
  output logic io_nestedwb_c_set_tip,
  output logic io_nestedwb_b_inv_dirty,
  output logic io_nestedwb_b_toB,
  output logic io_nestedwb_b_toN,
  output logic io_nestedwb_b_toClean,
  output logic io_nestedwb_denied,
  output logic io_nestedwb_corrupt,
  output logic [511:0] io_nestedwbData_data,
  input  logic io_l1Hint_ready,
  output logic io_l1Hint_valid,
  output logic [31:0] io_l1Hint_bits_sourceId,
  output logic io_l1Hint_bits_isKeyword,
  input  logic io_prefetchTrain_ready,
  output logic io_prefetchTrain_valid,
  output logic [32:0] io_prefetchTrain_bits_tag,
  output logic [8:0] io_prefetchTrain_bits_set,
  output logic io_prefetchTrain_bits_needT,
  output logic [6:0] io_prefetchTrain_bits_source,
  output logic [43:0] io_prefetchTrain_bits_vaddr,
  output logic io_prefetchTrain_bits_hit,
  output logic io_prefetchTrain_bits_prefetched,
  output logic [2:0] io_prefetchTrain_bits_pfsource,
  output logic [4:0] io_prefetchTrain_bits_reqsource,
  output logic io_error_valid,
  output logic io_error_bits_valid,
  output logic [45:0] io_error_bits_address,
  output logic [5:0] io_perf_0_value,
  output logic [5:0] io_perf_1_value,
  output logic [5:0] io_perf_2_value,
  output logic [5:0] io_perf_3_value,
  output logic [5:0] io_perf_4_value,
  output logic [5:0] io_perf_5_value,
  output logic [5:0] io_perf_6_value,
  output logic [5:0] io_perf_7_value,
  output logic [5:0] io_perf_8_value,
  output logic [5:0] io_perf_9_value,
  output logic [5:0] io_perf_10_value,
  output logic [5:0] io_perf_11_value,
  output logic [5:0] io_perf_12_value
);

  task_t       s2_task;
  meta_t       dir_meta;
  meta_t       alloc_dir_meta;
  fsm_state_t  alloc_state;
  task_t       alloc_task;
  meta_t       metaW_meta;
  logic        hint_s3_valid;
  task_t       hint_s3_task;
  logic        hint_s3_need_mshr;
  logic [30:0] pft_tag;
  logic        perf [13];
  logic        statusD_valid [3];
  logic [2:0]  statusD_channel [3];
  logic        statusTX_valid [3];
  logic [2:0]  statusTX_channel [3];
  logic [2:0]  statusTX_txChannel [3];
  logic        statusTX_mshrTask [3];
  logic        d_valid [3];
  task_t       d_task [3];
  logic        d_ready [3];
  logic        txrsp_valid [3];
  task_t       txrsp_task [3];
  logic        txrsp_ready [3];
  logic        txdat_valid [3];
  task_t       txdat_task [3];
  logic        txdat_ready [3];
  logic [511:0] d_data [3];
  logic [511:0] txdat_data [3];
  logic        txreq_valid [3];
  chireq_t     txreq_bits [3];
  logic        txreq_ready [3];

  // golden 端口 -> 结构体
  assign s2_task.channel = io_taskFromArb_s2_bits_channel;
  assign s2_task.txChannel = io_taskFromArb_s2_bits_txChannel;
  assign s2_task.set = io_taskFromArb_s2_bits_set;
  assign s2_task.tag = io_taskFromArb_s2_bits_tag;
  assign s2_task.off = io_taskFromArb_s2_bits_off;
  assign s2_task.alias_ = io_taskFromArb_s2_bits_alias;
  assign s2_task.vaddr = io_taskFromArb_s2_bits_vaddr;
  assign s2_task.isKeyword = io_taskFromArb_s2_bits_isKeyword;
  assign s2_task.opcode = io_taskFromArb_s2_bits_opcode;
  assign s2_task.param = io_taskFromArb_s2_bits_param;
  assign s2_task.size = io_taskFromArb_s2_bits_size;
  assign s2_task.sourceId = io_taskFromArb_s2_bits_sourceId;
  assign s2_task.bufIdx = io_taskFromArb_s2_bits_bufIdx;
  assign s2_task.needProbeAckData = io_taskFromArb_s2_bits_needProbeAckData;
  assign s2_task.denied = io_taskFromArb_s2_bits_denied;
  assign s2_task.corrupt = io_taskFromArb_s2_bits_corrupt;
  assign s2_task.mshrTask = io_taskFromArb_s2_bits_mshrTask;
  assign s2_task.mshrId = io_taskFromArb_s2_bits_mshrId;
  assign s2_task.aliasTask = io_taskFromArb_s2_bits_aliasTask;
  assign s2_task.useProbeData = io_taskFromArb_s2_bits_useProbeData;
  assign s2_task.mshrRetry = io_taskFromArb_s2_bits_mshrRetry;
  assign s2_task.readProbeDataDown = io_taskFromArb_s2_bits_readProbeDataDown;
  assign s2_task.fromL2pft = io_taskFromArb_s2_bits_fromL2pft;
  assign s2_task.needHint = io_taskFromArb_s2_bits_needHint;
  assign s2_task.dirty = io_taskFromArb_s2_bits_dirty;
  assign s2_task.way = io_taskFromArb_s2_bits_way;
  assign s2_task.meta_dirty = io_taskFromArb_s2_bits_meta_dirty;
  assign s2_task.meta_state = io_taskFromArb_s2_bits_meta_state;
  assign s2_task.meta_clients = io_taskFromArb_s2_bits_meta_clients;
  assign s2_task.meta_alias = io_taskFromArb_s2_bits_meta_alias;
  assign s2_task.meta_prefetch = io_taskFromArb_s2_bits_meta_prefetch;
  assign s2_task.meta_prefetchSrc = io_taskFromArb_s2_bits_meta_prefetchSrc;
  assign s2_task.meta_accessed = io_taskFromArb_s2_bits_meta_accessed;
  assign s2_task.meta_tagErr = io_taskFromArb_s2_bits_meta_tagErr;
  assign s2_task.meta_dataErr = io_taskFromArb_s2_bits_meta_dataErr;
  assign s2_task.metaWen = io_taskFromArb_s2_bits_metaWen;
  assign s2_task.tagWen = io_taskFromArb_s2_bits_tagWen;
  assign s2_task.dsWen = io_taskFromArb_s2_bits_dsWen;
  assign s2_task.wayMask = io_taskFromArb_s2_bits_wayMask;
  assign s2_task.replTask = io_taskFromArb_s2_bits_replTask;
  assign s2_task.cmoTask = io_taskFromArb_s2_bits_cmoTask;
  assign s2_task.cmoAll = io_taskFromArb_s2_bits_cmoAll;
  assign s2_task.reqSource = io_taskFromArb_s2_bits_reqSource;
  assign s2_task.mergeA = io_taskFromArb_s2_bits_mergeA;
  assign s2_task.aMergeTask_off = io_taskFromArb_s2_bits_aMergeTask_off;
  assign s2_task.aMergeTask_alias = io_taskFromArb_s2_bits_aMergeTask_alias;
  assign s2_task.aMergeTask_vaddr = io_taskFromArb_s2_bits_aMergeTask_vaddr;
  assign s2_task.aMergeTask_isKeyword = io_taskFromArb_s2_bits_aMergeTask_isKeyword;
  assign s2_task.aMergeTask_opcode = io_taskFromArb_s2_bits_aMergeTask_opcode;
  assign s2_task.aMergeTask_param = io_taskFromArb_s2_bits_aMergeTask_param;
  assign s2_task.aMergeTask_sourceId = io_taskFromArb_s2_bits_aMergeTask_sourceId;
  assign s2_task.aMergeTask_meta_dirty = io_taskFromArb_s2_bits_aMergeTask_meta_dirty;
  assign s2_task.aMergeTask_meta_state = io_taskFromArb_s2_bits_aMergeTask_meta_state;
  assign s2_task.aMergeTask_meta_clients = io_taskFromArb_s2_bits_aMergeTask_meta_clients;
  assign s2_task.aMergeTask_meta_alias = io_taskFromArb_s2_bits_aMergeTask_meta_alias;
  assign s2_task.aMergeTask_meta_prefetch = io_taskFromArb_s2_bits_aMergeTask_meta_prefetch;
  assign s2_task.aMergeTask_meta_prefetchSrc = io_taskFromArb_s2_bits_aMergeTask_meta_prefetchSrc;
  assign s2_task.aMergeTask_meta_accessed = io_taskFromArb_s2_bits_aMergeTask_meta_accessed;
  assign s2_task.aMergeTask_meta_tagErr = io_taskFromArb_s2_bits_aMergeTask_meta_tagErr;
  assign s2_task.aMergeTask_meta_dataErr = io_taskFromArb_s2_bits_aMergeTask_meta_dataErr;
  assign s2_task.snpHitRelease = io_taskFromArb_s2_bits_snpHitRelease;
  assign s2_task.snpHitReleaseToInval = io_taskFromArb_s2_bits_snpHitReleaseToInval;
  assign s2_task.snpHitReleaseToClean = io_taskFromArb_s2_bits_snpHitReleaseToClean;
  assign s2_task.snpHitReleaseWithData = io_taskFromArb_s2_bits_snpHitReleaseWithData;
  assign s2_task.snpHitReleaseIdx = io_taskFromArb_s2_bits_snpHitReleaseIdx;
  assign s2_task.snpHitReleaseMeta_dirty = io_taskFromArb_s2_bits_snpHitReleaseMeta_dirty;
  assign s2_task.snpHitReleaseMeta_state = io_taskFromArb_s2_bits_snpHitReleaseMeta_state;
  assign s2_task.snpHitReleaseMeta_clients = io_taskFromArb_s2_bits_snpHitReleaseMeta_clients;
  assign s2_task.snpHitReleaseMeta_alias = io_taskFromArb_s2_bits_snpHitReleaseMeta_alias;
  assign s2_task.snpHitReleaseMeta_prefetch = io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetch;
  assign s2_task.snpHitReleaseMeta_prefetchSrc = io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetchSrc;
  assign s2_task.snpHitReleaseMeta_accessed = io_taskFromArb_s2_bits_snpHitReleaseMeta_accessed;
  assign s2_task.snpHitReleaseMeta_tagErr = io_taskFromArb_s2_bits_snpHitReleaseMeta_tagErr;
  assign s2_task.snpHitReleaseMeta_dataErr = io_taskFromArb_s2_bits_snpHitReleaseMeta_dataErr;
  assign s2_task.tgtID = io_taskFromArb_s2_bits_tgtID;
  assign s2_task.srcID = io_taskFromArb_s2_bits_srcID;
  assign s2_task.txnID = io_taskFromArb_s2_bits_txnID;
  assign s2_task.homeNID = io_taskFromArb_s2_bits_homeNID;
  assign s2_task.dbID = io_taskFromArb_s2_bits_dbID;
  assign s2_task.fwdNID = io_taskFromArb_s2_bits_fwdNID;
  assign s2_task.fwdTxnID = io_taskFromArb_s2_bits_fwdTxnID;
  assign s2_task.chiOpcode = io_taskFromArb_s2_bits_chiOpcode;
  assign s2_task.resp = io_taskFromArb_s2_bits_resp;
  assign s2_task.fwdState = io_taskFromArb_s2_bits_fwdState;
  assign s2_task.pCrdType = io_taskFromArb_s2_bits_pCrdType;
  assign s2_task.retToSrc = io_taskFromArb_s2_bits_retToSrc;
  assign s2_task.likelyshared = io_taskFromArb_s2_bits_likelyshared;
  assign s2_task.expCompAck = io_taskFromArb_s2_bits_expCompAck;
  assign s2_task.allowRetry = io_taskFromArb_s2_bits_allowRetry;
  assign s2_task.memAttr_allocate = io_taskFromArb_s2_bits_memAttr_allocate;
  assign s2_task.memAttr_cacheable = io_taskFromArb_s2_bits_memAttr_cacheable;
  assign s2_task.memAttr_device = io_taskFromArb_s2_bits_memAttr_device;
  assign s2_task.memAttr_ewa = io_taskFromArb_s2_bits_memAttr_ewa;
  assign s2_task.traceTag = io_taskFromArb_s2_bits_traceTag;
  assign dir_meta.dirty = io_dirResp_s3_bits_meta_dirty;
  assign dir_meta.state = io_dirResp_s3_bits_meta_state;
  assign dir_meta.clients = io_dirResp_s3_bits_meta_clients;
  assign dir_meta.alias_ = io_dirResp_s3_bits_meta_alias;
  assign dir_meta.prefetch = io_dirResp_s3_bits_meta_prefetch;
  assign dir_meta.prefetchSrc = io_dirResp_s3_bits_meta_prefetchSrc;
  assign dir_meta.accessed = io_dirResp_s3_bits_meta_accessed;
  assign dir_meta.tagErr = io_dirResp_s3_bits_meta_tagErr;
  assign dir_meta.dataErr = io_dirResp_s3_bits_meta_dataErr;

  xs_MainPipe_1_core u_core (
    .clock              (clock),
    .reset              (reset),
    .s1_b_tag           (io_fromReqArb_status_s1_tags_1),
    .s1_c_set           (io_fromReqArb_status_s1_sets_0),
    .s1_b_set           (io_fromReqArb_status_s1_sets_1),
    .s1_a_set           (io_fromReqArb_status_s1_sets_2),
    .s1_g_set           (io_fromReqArb_status_s1_sets_3),
    .s2_valid           (io_taskFromArb_s2_valid),
    .s2_task            (s2_task),
    .dir_valid          (io_dirResp_s3_valid),
    .dir_hit            (io_dirResp_s3_bits_hit),
    .dir_tag            (io_dirResp_s3_bits_tag),
    .dir_set            (io_dirResp_s3_bits_set),
    .dir_way            (io_dirResp_s3_bits_way),
    .dir_meta           (dir_meta),
    .dir_error          (io_dirResp_s3_bits_error),
    .repl_valid         (io_replResp_valid),
    .repl_way           (io_replResp_bits_way),
    .repl_state         (io_replResp_bits_meta_state),
    .repl_retry         (io_replResp_bits_retry),
    .mshr_alloc_ptr     (io_fromMSHRCtl_mshr_alloc_ptr),
    .c_releaseData      ({io_bufResp_data_1, io_bufResp_data_0}),
    .refillBuf_data     (io_refillBufResp_s3_bits_data),
    .releaseBuf_valid   (io_releaseBufResp_s3_valid),
    .releaseBuf_data    (io_releaseBufResp_s3_bits_data),
    .ds_rdata_s5        (io_toDS_rdata_s5_data),
    .ds_error_s5        (io_toDS_error_s5),
    .blockG_s1          (io_toReqArb_blockG_s1),
    .blockB_s1          (io_toReqArb_blockB_s1),
    .blockC_s1          (io_toReqArb_blockC_s1),
    .toReqBuf_0         (io_toReqBuf_0),
    .toReqBuf_1         (io_toReqBuf_1),
    .statusD_valid      (statusD_valid),
    .statusD_channel    (statusD_channel),
    .statusTX_valid     (statusTX_valid),
    .statusTX_channel   (statusTX_channel),
    .statusTX_txChannel (statusTX_txChannel),
    .statusTX_mshrTask  (statusTX_mshrTask),
    .alloc_valid        (io_toMSHRCtl_mshr_alloc_s3_valid),
    .alloc_dir_hit      (io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_hit),
    .alloc_dir_tag      (io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_tag),
    .alloc_dir_set      (io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_set),
    .alloc_dir_way      (io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_way),
    .alloc_dir_meta     (alloc_dir_meta),
    .alloc_dir_error    (io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_error),
    .alloc_state        (alloc_state),
    .alloc_task         (alloc_task),
    .ds_en_s3           (io_toDS_en_s3),
    .ds_req_valid       (io_toDS_req_s3_valid),
    .ds_req_way         (io_toDS_req_s3_bits_way),
    .ds_req_set         (io_toDS_req_s3_bits_set),
    .ds_req_wen         (io_toDS_req_s3_bits_wen),
    .ds_wdata           (io_toDS_wdata_s3_data),
    .d_valid            (d_valid),
    .d_task             (d_task),
    .d_data             (d_data),
    .d_ready            (d_ready),
    .txreq_valid        (txreq_valid),
    .txreq_bits         (txreq_bits),
    .txreq_ready        (txreq_ready),
    .txrsp_valid        (txrsp_valid),
    .txrsp_task         (txrsp_task),
    .txrsp_ready        (txrsp_ready),
    .txdat_valid        (txdat_valid),
    .txdat_task         (txdat_task),
    .txdat_data         (txdat_data),
    .txdat_ready        (txdat_ready),
    .metaW_valid        (io_metaWReq_valid),
    .metaW_set          (io_metaWReq_bits_set),
    .metaW_wayOH        (io_metaWReq_bits_wayOH),
    .metaW_meta         (metaW_meta),
    .tagW_valid         (io_tagWReq_valid),
    .tagW_set           (io_tagWReq_bits_set),
    .tagW_way           (io_tagWReq_bits_way),
    .tagW_tag           (io_tagWReq_bits_wtag),
    .releaseBufW_valid  (io_releaseBufWrite_valid),
    .s5_mshrId          (io_releaseBufWrite_bits_id),
    .nwb_set            (io_nestedwb_set),
    .nwb_tag            (io_nestedwb_tag),
    .nwb_c_set_dirty    (io_nestedwb_c_set_dirty),
    .nwb_c_set_tip      (io_nestedwb_c_set_tip),
    .nwb_b_inv_dirty    (io_nestedwb_b_inv_dirty),
    .nwb_b_toB          (io_nestedwb_b_toB),
    .nwb_b_toN          (io_nestedwb_b_toN),
    .nwb_b_toClean      (io_nestedwb_b_toClean),
    .nwb_denied         (io_nestedwb_denied),
    .nwb_corrupt        (io_nestedwb_corrupt),
    .hint_s3_valid      (hint_s3_valid),
    .hint_s3_task       (hint_s3_task),
    .hint_s3_need_mshr  (hint_s3_need_mshr),
    .pft_valid          (io_prefetchTrain_valid),
    .pft_tag            (pft_tag),
    .pft_set            (io_prefetchTrain_bits_set),
    .pft_needT          (io_prefetchTrain_bits_needT),
    .pft_source         (io_prefetchTrain_bits_source),
    .pft_vaddr          (io_prefetchTrain_bits_vaddr),
    .pft_hit            (io_prefetchTrain_bits_hit),
    .pft_prefetched     (io_prefetchTrain_bits_prefetched),
    .pft_pfsource       (io_prefetchTrain_bits_pfsource),
    .pft_reqsource      (io_prefetchTrain_bits_reqsource),
    .err_valid          (io_error_valid),
    .err_bits_valid     (io_error_bits_valid),
    .err_address        (io_error_bits_address),
    .perf               (perf)
  );

  assign io_status_vec_toD_0_valid = statusD_valid[0];
  assign io_status_vec_toD_0_bits_channel = statusD_channel[0];
  assign io_status_vec_toD_1_valid = statusD_valid[1];
  assign io_status_vec_toD_1_bits_channel = statusD_channel[1];
  assign io_status_vec_toD_2_valid = statusD_valid[2];
  assign io_status_vec_toD_2_bits_channel = statusD_channel[2];
  assign io_status_vec_toTX_0_valid = statusTX_valid[0];
  assign io_status_vec_toTX_0_bits_channel = statusTX_channel[0];
  assign io_status_vec_toTX_0_bits_txChannel = statusTX_txChannel[0];
  assign io_status_vec_toTX_0_bits_mshrTask = statusTX_mshrTask[0];
  assign io_status_vec_toTX_1_valid = statusTX_valid[1];
  assign io_status_vec_toTX_1_bits_channel = statusTX_channel[1];
  assign io_status_vec_toTX_1_bits_txChannel = statusTX_txChannel[1];
  assign io_status_vec_toTX_1_bits_mshrTask = statusTX_mshrTask[1];
  assign io_status_vec_toTX_2_valid = statusTX_valid[2];
  assign io_status_vec_toTX_2_bits_channel = statusTX_channel[2];
  assign io_status_vec_toTX_2_bits_txChannel = statusTX_txChannel[2];
  assign io_status_vec_toTX_2_bits_mshrTask = statusTX_mshrTask[2];
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dirty = alloc_dir_meta.dirty;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_state = alloc_dir_meta.state;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_clients = alloc_dir_meta.clients;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_alias = alloc_dir_meta.alias_;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetch = alloc_dir_meta.prefetch;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc = alloc_dir_meta.prefetchSrc;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_accessed = alloc_dir_meta.accessed;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_tagErr = alloc_dir_meta.tagErr;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dataErr = alloc_dir_meta.dataErr;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_acquire = alloc_state.s_acquire;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rprobe = alloc_state.s_rprobe;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_pprobe = alloc_state.s_pprobe;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_release = alloc_state.s_release;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_probeack = alloc_state.s_probeack;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_refill = alloc_state.s_refill;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_cmoresp = alloc_state.s_cmoresp;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeackfirst = alloc_state.w_rprobeackfirst;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeacklast = alloc_state.w_rprobeacklast;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeackfirst = alloc_state.w_pprobeackfirst;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeacklast = alloc_state.w_pprobeacklast;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantfirst = alloc_state.w_grantfirst;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantlast = alloc_state.w_grantlast;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grant = alloc_state.w_grant;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_releaseack = alloc_state.w_releaseack;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_replResp = alloc_state.w_replResp;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rcompack = alloc_state.s_rcompack;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_dct = alloc_state.s_dct;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_channel = alloc_task.channel;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_set = alloc_task.set;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_tag = alloc_task.tag;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_off = alloc_task.off;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_alias = alloc_task.alias_;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_isKeyword = alloc_task.isKeyword;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_opcode = alloc_task.opcode;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_param = alloc_task.param;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_sourceId = alloc_task.sourceId;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_denied = alloc_task.denied;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_corrupt = alloc_task.corrupt;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_aliasTask = alloc_task.aliasTask;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_fromL2pft = alloc_task.fromL2pft;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_reqSource = alloc_task.reqSource;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitRelease = alloc_task.snpHitRelease;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToInval = alloc_task.snpHitReleaseToInval;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToClean = alloc_task.snpHitReleaseToClean;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseWithData = alloc_task.snpHitReleaseWithData;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseIdx = alloc_task.snpHitReleaseIdx;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty = alloc_task.snpHitReleaseMeta_dirty;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state = alloc_task.snpHitReleaseMeta_state;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients = alloc_task.snpHitReleaseMeta_clients;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias = alloc_task.snpHitReleaseMeta_alias;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch = alloc_task.snpHitReleaseMeta_prefetch;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc = alloc_task.snpHitReleaseMeta_prefetchSrc;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed = alloc_task.snpHitReleaseMeta_accessed;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr = alloc_task.snpHitReleaseMeta_tagErr;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr = alloc_task.snpHitReleaseMeta_dataErr;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_srcID = alloc_task.srcID;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_txnID = alloc_task.txnID;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdNID = alloc_task.fwdNID;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdTxnID = alloc_task.fwdTxnID;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_chiOpcode = alloc_task.chiOpcode;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_retToSrc = alloc_task.retToSrc;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_traceTag = alloc_task.traceTag;
  assign io_metaWReq_bits_wmeta_dirty = metaW_meta.dirty;
  assign io_metaWReq_bits_wmeta_state = metaW_meta.state;
  assign io_metaWReq_bits_wmeta_clients = metaW_meta.clients;
  assign io_metaWReq_bits_wmeta_alias = metaW_meta.alias_;
  assign io_metaWReq_bits_wmeta_prefetch = metaW_meta.prefetch;
  assign io_metaWReq_bits_wmeta_prefetchSrc = metaW_meta.prefetchSrc;
  assign io_metaWReq_bits_wmeta_accessed = metaW_meta.accessed;
  assign io_metaWReq_bits_wmeta_tagErr = metaW_meta.tagErr;
  assign io_metaWReq_bits_wmeta_dataErr = metaW_meta.dataErr;
  assign io_releaseBufWrite_bits_data_data = io_toDS_rdata_s5_data;
  assign io_dsResp_valid = io_releaseBufWrite_valid;
  assign io_dsResp_bits_mshrId = io_releaseBufWrite_bits_id;
  assign io_dsResp_bits_dataError = io_toDS_error_s5;
  assign io_nestedwbData_data = {io_bufResp_data_1, io_bufResp_data_0};
  assign io_prefetchTrain_bits_tag = {2'b00, pft_tag};   // PrefetchTrain.tag 比 L2 tag 宽 2 位
  assign io_perf_0_value = {5'd0, perf[0]};
  assign io_perf_1_value = {5'd0, perf[1]};
  assign io_perf_2_value = {5'd0, perf[2]};
  assign io_perf_3_value = {5'd0, perf[3]};
  assign io_perf_4_value = {5'd0, perf[4]};
  assign io_perf_5_value = {5'd0, perf[5]};
  assign io_perf_6_value = {5'd0, perf[6]};
  assign io_perf_7_value = {5'd0, perf[7]};
  assign io_perf_8_value = {5'd0, perf[8]};
  assign io_perf_9_value = {5'd0, perf[9]};
  assign io_perf_10_value = {5'd0, perf[10]};
  assign io_perf_11_value = {5'd0, perf[11]};
  assign io_perf_12_value = {5'd0, perf[12]};

  CustomL1Hint customL1Hint (
    .clock                            (clock),
    .reset                            (reset),
    .io_s1_valid                      (io_taskInfo_s1_valid),
    .io_s1_bits_channel               (io_taskInfo_s1_bits_channel),
    .io_s1_bits_isKeyword             (io_taskInfo_s1_bits_isKeyword),
    .io_s1_bits_opcode                (io_taskInfo_s1_bits_opcode),
    .io_s1_bits_sourceId              (io_taskInfo_s1_bits_sourceId),
    .io_s1_bits_mshrTask              (io_taskInfo_s1_bits_mshrTask),
    .io_s1_bits_mergeA                (io_taskInfo_s1_bits_mergeA),
    .io_s1_bits_aMergeTask_isKeyword  (io_taskInfo_s1_bits_aMergeTask_isKeyword),
    .io_s1_bits_aMergeTask_opcode     (io_taskInfo_s1_bits_aMergeTask_opcode),
    .io_s1_bits_aMergeTask_sourceId   (io_taskInfo_s1_bits_aMergeTask_sourceId),
    .io_s3_task_valid                 (hint_s3_valid),
    .io_s3_task_bits_channel          (hint_s3_task.channel),
    .io_s3_task_bits_isKeyword        (hint_s3_task.isKeyword),
    .io_s3_task_bits_opcode           (hint_s3_task.opcode),
    .io_s3_task_bits_sourceId         (hint_s3_task.sourceId),
    .io_s3_task_bits_mshrTask         (hint_s3_task.mshrTask),
    .io_s3_need_mshr                  (hint_s3_need_mshr),
    .io_l1Hint_ready                  (io_l1Hint_ready),
    .io_l1Hint_valid                  (io_l1Hint_valid),
    .io_l1Hint_bits_sourceId          (io_l1Hint_bits_sourceId),
    .io_l1Hint_bits_isKeyword         (io_l1Hint_bits_isKeyword)
  );

  // 四个出口仲裁器：第 k 路 = 核的 [k]（0=s5 1=s4 2=s3，s5 优先级最高）
  Arbiter3_TaskWithData toSourceD_arb (
    .io_in_0_ready                            (d_ready[0]),
    .io_in_0_valid                            (d_valid[0]),
    .io_in_0_bits_task_channel                (d_task[0].channel),
    .io_in_0_bits_task_txChannel              (d_task[0].txChannel),
    .io_in_0_bits_task_set                    (d_task[0].set),
    .io_in_0_bits_task_tag                    (d_task[0].tag),
    .io_in_0_bits_task_off                    (d_task[0].off),
    .io_in_0_bits_task_alias                  (d_task[0].alias_),
    .io_in_0_bits_task_vaddr                  (d_task[0].vaddr),
    .io_in_0_bits_task_isKeyword              (d_task[0].isKeyword),
    .io_in_0_bits_task_opcode                 (d_task[0].opcode),
    .io_in_0_bits_task_param                  (d_task[0].param),
    .io_in_0_bits_task_size                   (d_task[0].size),
    .io_in_0_bits_task_sourceId               (d_task[0].sourceId),
    .io_in_0_bits_task_bufIdx                 (d_task[0].bufIdx),
    .io_in_0_bits_task_needProbeAckData       (d_task[0].needProbeAckData),
    .io_in_0_bits_task_denied                 (d_task[0].denied),
    .io_in_0_bits_task_corrupt                (d_task[0].corrupt),
    .io_in_0_bits_task_mshrTask               (d_task[0].mshrTask),
    .io_in_0_bits_task_mshrId                 (d_task[0].mshrId),
    .io_in_0_bits_task_aliasTask              (d_task[0].aliasTask),
    .io_in_0_bits_task_useProbeData           (d_task[0].useProbeData),
    .io_in_0_bits_task_mshrRetry              (d_task[0].mshrRetry),
    .io_in_0_bits_task_readProbeDataDown      (d_task[0].readProbeDataDown),
    .io_in_0_bits_task_fromL2pft              (d_task[0].fromL2pft),
    .io_in_0_bits_task_needHint               (d_task[0].needHint),
    .io_in_0_bits_task_dirty                  (d_task[0].dirty),
    .io_in_0_bits_task_way                    (d_task[0].way),
    .io_in_0_bits_task_meta_dirty             (d_task[0].meta_dirty),
    .io_in_0_bits_task_meta_state             (d_task[0].meta_state),
    .io_in_0_bits_task_meta_clients           (d_task[0].meta_clients),
    .io_in_0_bits_task_meta_alias             (d_task[0].meta_alias),
    .io_in_0_bits_task_meta_prefetch          (d_task[0].meta_prefetch),
    .io_in_0_bits_task_meta_prefetchSrc       (d_task[0].meta_prefetchSrc),
    .io_in_0_bits_task_meta_accessed          (d_task[0].meta_accessed),
    .io_in_0_bits_task_meta_tagErr            (d_task[0].meta_tagErr),
    .io_in_0_bits_task_meta_dataErr           (d_task[0].meta_dataErr),
    .io_in_0_bits_task_metaWen                (d_task[0].metaWen),
    .io_in_0_bits_task_tagWen                 (d_task[0].tagWen),
    .io_in_0_bits_task_dsWen                  (d_task[0].dsWen),
    .io_in_0_bits_task_wayMask                (d_task[0].wayMask),
    .io_in_0_bits_task_replTask               (d_task[0].replTask),
    .io_in_0_bits_task_cmoTask                (d_task[0].cmoTask),
    .io_in_0_bits_task_cmoAll                 (d_task[0].cmoAll),
    .io_in_0_bits_task_reqSource              (d_task[0].reqSource),
    .io_in_0_bits_task_mergeA                 (d_task[0].mergeA),
    .io_in_0_bits_task_aMergeTask_off         (d_task[0].aMergeTask_off),
    .io_in_0_bits_task_aMergeTask_alias       (d_task[0].aMergeTask_alias),
    .io_in_0_bits_task_aMergeTask_vaddr       (d_task[0].aMergeTask_vaddr),
    .io_in_0_bits_task_aMergeTask_isKeyword   (d_task[0].aMergeTask_isKeyword),
    .io_in_0_bits_task_aMergeTask_opcode      (d_task[0].aMergeTask_opcode),
    .io_in_0_bits_task_aMergeTask_param       (d_task[0].aMergeTask_param),
    .io_in_0_bits_task_aMergeTask_sourceId    (d_task[0].aMergeTask_sourceId),
    .io_in_0_bits_task_aMergeTask_meta_dirty  (d_task[0].aMergeTask_meta_dirty),
    .io_in_0_bits_task_aMergeTask_meta_state  (d_task[0].aMergeTask_meta_state),
    .io_in_0_bits_task_aMergeTask_meta_clients (d_task[0].aMergeTask_meta_clients),
    .io_in_0_bits_task_aMergeTask_meta_alias  (d_task[0].aMergeTask_meta_alias),
    .io_in_0_bits_task_aMergeTask_meta_prefetch (d_task[0].aMergeTask_meta_prefetch),
    .io_in_0_bits_task_aMergeTask_meta_prefetchSrc (d_task[0].aMergeTask_meta_prefetchSrc),
    .io_in_0_bits_task_aMergeTask_meta_accessed (d_task[0].aMergeTask_meta_accessed),
    .io_in_0_bits_task_aMergeTask_meta_tagErr (d_task[0].aMergeTask_meta_tagErr),
    .io_in_0_bits_task_aMergeTask_meta_dataErr (d_task[0].aMergeTask_meta_dataErr),
    .io_in_0_bits_task_snpHitRelease          (d_task[0].snpHitRelease),
    .io_in_0_bits_task_snpHitReleaseToInval   (d_task[0].snpHitReleaseToInval),
    .io_in_0_bits_task_snpHitReleaseToClean   (d_task[0].snpHitReleaseToClean),
    .io_in_0_bits_task_snpHitReleaseWithData  (d_task[0].snpHitReleaseWithData),
    .io_in_0_bits_task_snpHitReleaseIdx       (d_task[0].snpHitReleaseIdx),
    .io_in_0_bits_task_snpHitReleaseMeta_dirty (d_task[0].snpHitReleaseMeta_dirty),
    .io_in_0_bits_task_snpHitReleaseMeta_state (d_task[0].snpHitReleaseMeta_state),
    .io_in_0_bits_task_snpHitReleaseMeta_clients (d_task[0].snpHitReleaseMeta_clients),
    .io_in_0_bits_task_snpHitReleaseMeta_alias (d_task[0].snpHitReleaseMeta_alias),
    .io_in_0_bits_task_snpHitReleaseMeta_prefetch (d_task[0].snpHitReleaseMeta_prefetch),
    .io_in_0_bits_task_snpHitReleaseMeta_prefetchSrc (d_task[0].snpHitReleaseMeta_prefetchSrc),
    .io_in_0_bits_task_snpHitReleaseMeta_accessed (d_task[0].snpHitReleaseMeta_accessed),
    .io_in_0_bits_task_snpHitReleaseMeta_tagErr (d_task[0].snpHitReleaseMeta_tagErr),
    .io_in_0_bits_task_snpHitReleaseMeta_dataErr (d_task[0].snpHitReleaseMeta_dataErr),
    .io_in_0_bits_task_tgtID                  (d_task[0].tgtID),
    .io_in_0_bits_task_srcID                  (d_task[0].srcID),
    .io_in_0_bits_task_txnID                  (d_task[0].txnID),
    .io_in_0_bits_task_homeNID                (d_task[0].homeNID),
    .io_in_0_bits_task_dbID                   (d_task[0].dbID),
    .io_in_0_bits_task_fwdNID                 (d_task[0].fwdNID),
    .io_in_0_bits_task_fwdTxnID               (d_task[0].fwdTxnID),
    .io_in_0_bits_task_chiOpcode              (d_task[0].chiOpcode),
    .io_in_0_bits_task_resp                   (d_task[0].resp),
    .io_in_0_bits_task_fwdState               (d_task[0].fwdState),
    .io_in_0_bits_task_pCrdType               (d_task[0].pCrdType),
    .io_in_0_bits_task_retToSrc               (d_task[0].retToSrc),
    .io_in_0_bits_task_likelyshared           (d_task[0].likelyshared),
    .io_in_0_bits_task_expCompAck             (d_task[0].expCompAck),
    .io_in_0_bits_task_allowRetry             (d_task[0].allowRetry),
    .io_in_0_bits_task_memAttr_allocate       (d_task[0].memAttr_allocate),
    .io_in_0_bits_task_memAttr_cacheable      (d_task[0].memAttr_cacheable),
    .io_in_0_bits_task_memAttr_device         (d_task[0].memAttr_device),
    .io_in_0_bits_task_memAttr_ewa            (d_task[0].memAttr_ewa),
    .io_in_0_bits_task_traceTag               (d_task[0].traceTag),
    .io_in_0_bits_data_data                   (d_data[0]),
    .io_in_1_ready                            (d_ready[1]),
    .io_in_1_valid                            (d_valid[1]),
    .io_in_1_bits_task_channel                (d_task[1].channel),
    .io_in_1_bits_task_txChannel              (d_task[1].txChannel),
    .io_in_1_bits_task_set                    (d_task[1].set),
    .io_in_1_bits_task_tag                    (d_task[1].tag),
    .io_in_1_bits_task_off                    (d_task[1].off),
    .io_in_1_bits_task_alias                  (d_task[1].alias_),
    .io_in_1_bits_task_vaddr                  (d_task[1].vaddr),
    .io_in_1_bits_task_isKeyword              (d_task[1].isKeyword),
    .io_in_1_bits_task_opcode                 (d_task[1].opcode),
    .io_in_1_bits_task_param                  (d_task[1].param),
    .io_in_1_bits_task_size                   (d_task[1].size),
    .io_in_1_bits_task_sourceId               (d_task[1].sourceId),
    .io_in_1_bits_task_bufIdx                 (d_task[1].bufIdx),
    .io_in_1_bits_task_needProbeAckData       (d_task[1].needProbeAckData),
    .io_in_1_bits_task_denied                 (d_task[1].denied),
    .io_in_1_bits_task_corrupt                (d_task[1].corrupt),
    .io_in_1_bits_task_mshrTask               (d_task[1].mshrTask),
    .io_in_1_bits_task_mshrId                 (d_task[1].mshrId),
    .io_in_1_bits_task_aliasTask              (d_task[1].aliasTask),
    .io_in_1_bits_task_useProbeData           (d_task[1].useProbeData),
    .io_in_1_bits_task_mshrRetry              (d_task[1].mshrRetry),
    .io_in_1_bits_task_readProbeDataDown      (d_task[1].readProbeDataDown),
    .io_in_1_bits_task_fromL2pft              (d_task[1].fromL2pft),
    .io_in_1_bits_task_needHint               (d_task[1].needHint),
    .io_in_1_bits_task_dirty                  (d_task[1].dirty),
    .io_in_1_bits_task_way                    (d_task[1].way),
    .io_in_1_bits_task_meta_dirty             (d_task[1].meta_dirty),
    .io_in_1_bits_task_meta_state             (d_task[1].meta_state),
    .io_in_1_bits_task_meta_clients           (d_task[1].meta_clients),
    .io_in_1_bits_task_meta_alias             (d_task[1].meta_alias),
    .io_in_1_bits_task_meta_prefetch          (d_task[1].meta_prefetch),
    .io_in_1_bits_task_meta_prefetchSrc       (d_task[1].meta_prefetchSrc),
    .io_in_1_bits_task_meta_accessed          (d_task[1].meta_accessed),
    .io_in_1_bits_task_meta_tagErr            (d_task[1].meta_tagErr),
    .io_in_1_bits_task_meta_dataErr           (d_task[1].meta_dataErr),
    .io_in_1_bits_task_metaWen                (d_task[1].metaWen),
    .io_in_1_bits_task_tagWen                 (d_task[1].tagWen),
    .io_in_1_bits_task_dsWen                  (d_task[1].dsWen),
    .io_in_1_bits_task_wayMask                (d_task[1].wayMask),
    .io_in_1_bits_task_replTask               (d_task[1].replTask),
    .io_in_1_bits_task_cmoTask                (d_task[1].cmoTask),
    .io_in_1_bits_task_cmoAll                 (d_task[1].cmoAll),
    .io_in_1_bits_task_reqSource              (d_task[1].reqSource),
    .io_in_1_bits_task_mergeA                 (d_task[1].mergeA),
    .io_in_1_bits_task_aMergeTask_off         (d_task[1].aMergeTask_off),
    .io_in_1_bits_task_aMergeTask_alias       (d_task[1].aMergeTask_alias),
    .io_in_1_bits_task_aMergeTask_vaddr       (d_task[1].aMergeTask_vaddr),
    .io_in_1_bits_task_aMergeTask_isKeyword   (d_task[1].aMergeTask_isKeyword),
    .io_in_1_bits_task_aMergeTask_opcode      (d_task[1].aMergeTask_opcode),
    .io_in_1_bits_task_aMergeTask_param       (d_task[1].aMergeTask_param),
    .io_in_1_bits_task_aMergeTask_sourceId    (d_task[1].aMergeTask_sourceId),
    .io_in_1_bits_task_aMergeTask_meta_dirty  (d_task[1].aMergeTask_meta_dirty),
    .io_in_1_bits_task_aMergeTask_meta_state  (d_task[1].aMergeTask_meta_state),
    .io_in_1_bits_task_aMergeTask_meta_clients (d_task[1].aMergeTask_meta_clients),
    .io_in_1_bits_task_aMergeTask_meta_alias  (d_task[1].aMergeTask_meta_alias),
    .io_in_1_bits_task_aMergeTask_meta_prefetch (d_task[1].aMergeTask_meta_prefetch),
    .io_in_1_bits_task_aMergeTask_meta_prefetchSrc (d_task[1].aMergeTask_meta_prefetchSrc),
    .io_in_1_bits_task_aMergeTask_meta_accessed (d_task[1].aMergeTask_meta_accessed),
    .io_in_1_bits_task_aMergeTask_meta_tagErr (d_task[1].aMergeTask_meta_tagErr),
    .io_in_1_bits_task_aMergeTask_meta_dataErr (d_task[1].aMergeTask_meta_dataErr),
    .io_in_1_bits_task_snpHitRelease          (d_task[1].snpHitRelease),
    .io_in_1_bits_task_snpHitReleaseToInval   (d_task[1].snpHitReleaseToInval),
    .io_in_1_bits_task_snpHitReleaseToClean   (d_task[1].snpHitReleaseToClean),
    .io_in_1_bits_task_snpHitReleaseWithData  (d_task[1].snpHitReleaseWithData),
    .io_in_1_bits_task_snpHitReleaseIdx       (d_task[1].snpHitReleaseIdx),
    .io_in_1_bits_task_snpHitReleaseMeta_dirty (d_task[1].snpHitReleaseMeta_dirty),
    .io_in_1_bits_task_snpHitReleaseMeta_state (d_task[1].snpHitReleaseMeta_state),
    .io_in_1_bits_task_snpHitReleaseMeta_clients (d_task[1].snpHitReleaseMeta_clients),
    .io_in_1_bits_task_snpHitReleaseMeta_alias (d_task[1].snpHitReleaseMeta_alias),
    .io_in_1_bits_task_snpHitReleaseMeta_prefetch (d_task[1].snpHitReleaseMeta_prefetch),
    .io_in_1_bits_task_snpHitReleaseMeta_prefetchSrc (d_task[1].snpHitReleaseMeta_prefetchSrc),
    .io_in_1_bits_task_snpHitReleaseMeta_accessed (d_task[1].snpHitReleaseMeta_accessed),
    .io_in_1_bits_task_snpHitReleaseMeta_tagErr (d_task[1].snpHitReleaseMeta_tagErr),
    .io_in_1_bits_task_snpHitReleaseMeta_dataErr (d_task[1].snpHitReleaseMeta_dataErr),
    .io_in_1_bits_task_tgtID                  (d_task[1].tgtID),
    .io_in_1_bits_task_srcID                  (d_task[1].srcID),
    .io_in_1_bits_task_txnID                  (d_task[1].txnID),
    .io_in_1_bits_task_homeNID                (d_task[1].homeNID),
    .io_in_1_bits_task_dbID                   (d_task[1].dbID),
    .io_in_1_bits_task_fwdNID                 (d_task[1].fwdNID),
    .io_in_1_bits_task_fwdTxnID               (d_task[1].fwdTxnID),
    .io_in_1_bits_task_chiOpcode              (d_task[1].chiOpcode),
    .io_in_1_bits_task_resp                   (d_task[1].resp),
    .io_in_1_bits_task_fwdState               (d_task[1].fwdState),
    .io_in_1_bits_task_pCrdType               (d_task[1].pCrdType),
    .io_in_1_bits_task_retToSrc               (d_task[1].retToSrc),
    .io_in_1_bits_task_likelyshared           (d_task[1].likelyshared),
    .io_in_1_bits_task_expCompAck             (d_task[1].expCompAck),
    .io_in_1_bits_task_allowRetry             (d_task[1].allowRetry),
    .io_in_1_bits_task_memAttr_allocate       (d_task[1].memAttr_allocate),
    .io_in_1_bits_task_memAttr_cacheable      (d_task[1].memAttr_cacheable),
    .io_in_1_bits_task_memAttr_device         (d_task[1].memAttr_device),
    .io_in_1_bits_task_memAttr_ewa            (d_task[1].memAttr_ewa),
    .io_in_1_bits_task_traceTag               (d_task[1].traceTag),
    .io_in_1_bits_data_data                   (d_data[1]),
    .io_in_2_ready                            (d_ready[2]),
    .io_in_2_valid                            (d_valid[2]),
    .io_in_2_bits_task_channel                (d_task[2].channel),
    .io_in_2_bits_task_txChannel              (d_task[2].txChannel),
    .io_in_2_bits_task_set                    (d_task[2].set),
    .io_in_2_bits_task_tag                    (d_task[2].tag),
    .io_in_2_bits_task_off                    (d_task[2].off),
    .io_in_2_bits_task_alias                  (d_task[2].alias_),
    .io_in_2_bits_task_vaddr                  (d_task[2].vaddr),
    .io_in_2_bits_task_isKeyword              (d_task[2].isKeyword),
    .io_in_2_bits_task_opcode                 (d_task[2].opcode),
    .io_in_2_bits_task_param                  (d_task[2].param),
    .io_in_2_bits_task_size                   (d_task[2].size),
    .io_in_2_bits_task_sourceId               (d_task[2].sourceId),
    .io_in_2_bits_task_bufIdx                 (d_task[2].bufIdx),
    .io_in_2_bits_task_needProbeAckData       (d_task[2].needProbeAckData),
    .io_in_2_bits_task_denied                 (d_task[2].denied),
    .io_in_2_bits_task_corrupt                (d_task[2].corrupt),
    .io_in_2_bits_task_mshrTask               (d_task[2].mshrTask),
    .io_in_2_bits_task_mshrId                 (d_task[2].mshrId),
    .io_in_2_bits_task_aliasTask              (d_task[2].aliasTask),
    .io_in_2_bits_task_useProbeData           (d_task[2].useProbeData),
    .io_in_2_bits_task_mshrRetry              (d_task[2].mshrRetry),
    .io_in_2_bits_task_readProbeDataDown      (d_task[2].readProbeDataDown),
    .io_in_2_bits_task_fromL2pft              (d_task[2].fromL2pft),
    .io_in_2_bits_task_needHint               (d_task[2].needHint),
    .io_in_2_bits_task_dirty                  (d_task[2].dirty),
    .io_in_2_bits_task_way                    (d_task[2].way),
    .io_in_2_bits_task_meta_dirty             (d_task[2].meta_dirty),
    .io_in_2_bits_task_meta_state             (d_task[2].meta_state),
    .io_in_2_bits_task_meta_clients           (d_task[2].meta_clients),
    .io_in_2_bits_task_meta_alias             (d_task[2].meta_alias),
    .io_in_2_bits_task_meta_prefetch          (d_task[2].meta_prefetch),
    .io_in_2_bits_task_meta_prefetchSrc       (d_task[2].meta_prefetchSrc),
    .io_in_2_bits_task_meta_accessed          (d_task[2].meta_accessed),
    .io_in_2_bits_task_meta_tagErr            (d_task[2].meta_tagErr),
    .io_in_2_bits_task_meta_dataErr           (d_task[2].meta_dataErr),
    .io_in_2_bits_task_metaWen                (d_task[2].metaWen),
    .io_in_2_bits_task_tagWen                 (d_task[2].tagWen),
    .io_in_2_bits_task_dsWen                  (d_task[2].dsWen),
    .io_in_2_bits_task_wayMask                (d_task[2].wayMask),
    .io_in_2_bits_task_replTask               (d_task[2].replTask),
    .io_in_2_bits_task_cmoTask                (d_task[2].cmoTask),
    .io_in_2_bits_task_cmoAll                 (d_task[2].cmoAll),
    .io_in_2_bits_task_reqSource              (d_task[2].reqSource),
    .io_in_2_bits_task_mergeA                 (d_task[2].mergeA),
    .io_in_2_bits_task_aMergeTask_off         (d_task[2].aMergeTask_off),
    .io_in_2_bits_task_aMergeTask_alias       (d_task[2].aMergeTask_alias),
    .io_in_2_bits_task_aMergeTask_vaddr       (d_task[2].aMergeTask_vaddr),
    .io_in_2_bits_task_aMergeTask_isKeyword   (d_task[2].aMergeTask_isKeyword),
    .io_in_2_bits_task_aMergeTask_opcode      (d_task[2].aMergeTask_opcode),
    .io_in_2_bits_task_aMergeTask_param       (d_task[2].aMergeTask_param),
    .io_in_2_bits_task_aMergeTask_sourceId    (d_task[2].aMergeTask_sourceId),
    .io_in_2_bits_task_aMergeTask_meta_dirty  (d_task[2].aMergeTask_meta_dirty),
    .io_in_2_bits_task_aMergeTask_meta_state  (d_task[2].aMergeTask_meta_state),
    .io_in_2_bits_task_aMergeTask_meta_clients (d_task[2].aMergeTask_meta_clients),
    .io_in_2_bits_task_aMergeTask_meta_alias  (d_task[2].aMergeTask_meta_alias),
    .io_in_2_bits_task_aMergeTask_meta_prefetch (d_task[2].aMergeTask_meta_prefetch),
    .io_in_2_bits_task_aMergeTask_meta_prefetchSrc (d_task[2].aMergeTask_meta_prefetchSrc),
    .io_in_2_bits_task_aMergeTask_meta_accessed (d_task[2].aMergeTask_meta_accessed),
    .io_in_2_bits_task_aMergeTask_meta_tagErr (d_task[2].aMergeTask_meta_tagErr),
    .io_in_2_bits_task_aMergeTask_meta_dataErr (d_task[2].aMergeTask_meta_dataErr),
    .io_in_2_bits_task_snpHitRelease          (d_task[2].snpHitRelease),
    .io_in_2_bits_task_snpHitReleaseToInval   (d_task[2].snpHitReleaseToInval),
    .io_in_2_bits_task_snpHitReleaseToClean   (d_task[2].snpHitReleaseToClean),
    .io_in_2_bits_task_snpHitReleaseWithData  (d_task[2].snpHitReleaseWithData),
    .io_in_2_bits_task_snpHitReleaseIdx       (d_task[2].snpHitReleaseIdx),
    .io_in_2_bits_task_snpHitReleaseMeta_dirty (d_task[2].snpHitReleaseMeta_dirty),
    .io_in_2_bits_task_snpHitReleaseMeta_state (d_task[2].snpHitReleaseMeta_state),
    .io_in_2_bits_task_snpHitReleaseMeta_clients (d_task[2].snpHitReleaseMeta_clients),
    .io_in_2_bits_task_snpHitReleaseMeta_alias (d_task[2].snpHitReleaseMeta_alias),
    .io_in_2_bits_task_snpHitReleaseMeta_prefetch (d_task[2].snpHitReleaseMeta_prefetch),
    .io_in_2_bits_task_snpHitReleaseMeta_prefetchSrc (d_task[2].snpHitReleaseMeta_prefetchSrc),
    .io_in_2_bits_task_snpHitReleaseMeta_accessed (d_task[2].snpHitReleaseMeta_accessed),
    .io_in_2_bits_task_snpHitReleaseMeta_tagErr (d_task[2].snpHitReleaseMeta_tagErr),
    .io_in_2_bits_task_snpHitReleaseMeta_dataErr (d_task[2].snpHitReleaseMeta_dataErr),
    .io_in_2_bits_task_tgtID                  (d_task[2].tgtID),
    .io_in_2_bits_task_srcID                  (d_task[2].srcID),
    .io_in_2_bits_task_txnID                  (d_task[2].txnID),
    .io_in_2_bits_task_homeNID                (d_task[2].homeNID),
    .io_in_2_bits_task_dbID                   (d_task[2].dbID),
    .io_in_2_bits_task_fwdNID                 (d_task[2].fwdNID),
    .io_in_2_bits_task_fwdTxnID               (d_task[2].fwdTxnID),
    .io_in_2_bits_task_chiOpcode              (d_task[2].chiOpcode),
    .io_in_2_bits_task_resp                   (d_task[2].resp),
    .io_in_2_bits_task_fwdState               (d_task[2].fwdState),
    .io_in_2_bits_task_pCrdType               (d_task[2].pCrdType),
    .io_in_2_bits_task_retToSrc               (d_task[2].retToSrc),
    .io_in_2_bits_task_likelyshared           (d_task[2].likelyshared),
    .io_in_2_bits_task_expCompAck             (d_task[2].expCompAck),
    .io_in_2_bits_task_allowRetry             (d_task[2].allowRetry),
    .io_in_2_bits_task_memAttr_allocate       (d_task[2].memAttr_allocate),
    .io_in_2_bits_task_memAttr_cacheable      (d_task[2].memAttr_cacheable),
    .io_in_2_bits_task_memAttr_device         (d_task[2].memAttr_device),
    .io_in_2_bits_task_memAttr_ewa            (d_task[2].memAttr_ewa),
    .io_in_2_bits_task_traceTag               (d_task[2].traceTag),
    .io_in_2_bits_data_data                   (d_data[2]),
    .io_out_ready                             (1'b1),
    .io_out_valid                             (io_toSourceD_valid),
    .io_out_bits_task_channel                 (io_toSourceD_bits_task_channel),
    .io_out_bits_task_txChannel               (io_toSourceD_bits_task_txChannel),
    .io_out_bits_task_set                     (io_toSourceD_bits_task_set),
    .io_out_bits_task_tag                     (io_toSourceD_bits_task_tag),
    .io_out_bits_task_off                     (io_toSourceD_bits_task_off),
    .io_out_bits_task_alias                   (io_toSourceD_bits_task_alias),
    .io_out_bits_task_vaddr                   (io_toSourceD_bits_task_vaddr),
    .io_out_bits_task_isKeyword               (io_toSourceD_bits_task_isKeyword),
    .io_out_bits_task_opcode                  (io_toSourceD_bits_task_opcode),
    .io_out_bits_task_param                   (io_toSourceD_bits_task_param),
    .io_out_bits_task_size                    (io_toSourceD_bits_task_size),
    .io_out_bits_task_sourceId                (io_toSourceD_bits_task_sourceId),
    .io_out_bits_task_bufIdx                  (io_toSourceD_bits_task_bufIdx),
    .io_out_bits_task_needProbeAckData        (io_toSourceD_bits_task_needProbeAckData),
    .io_out_bits_task_denied                  (io_toSourceD_bits_task_denied),
    .io_out_bits_task_corrupt                 (io_toSourceD_bits_task_corrupt),
    .io_out_bits_task_mshrTask                (io_toSourceD_bits_task_mshrTask),
    .io_out_bits_task_mshrId                  (io_toSourceD_bits_task_mshrId),
    .io_out_bits_task_aliasTask               (io_toSourceD_bits_task_aliasTask),
    .io_out_bits_task_useProbeData            (io_toSourceD_bits_task_useProbeData),
    .io_out_bits_task_mshrRetry               (io_toSourceD_bits_task_mshrRetry),
    .io_out_bits_task_readProbeDataDown       (io_toSourceD_bits_task_readProbeDataDown),
    .io_out_bits_task_fromL2pft               (io_toSourceD_bits_task_fromL2pft),
    .io_out_bits_task_needHint                (io_toSourceD_bits_task_needHint),
    .io_out_bits_task_dirty                   (io_toSourceD_bits_task_dirty),
    .io_out_bits_task_way                     (io_toSourceD_bits_task_way),
    .io_out_bits_task_meta_dirty              (io_toSourceD_bits_task_meta_dirty),
    .io_out_bits_task_meta_state              (io_toSourceD_bits_task_meta_state),
    .io_out_bits_task_meta_clients            (io_toSourceD_bits_task_meta_clients),
    .io_out_bits_task_meta_alias              (io_toSourceD_bits_task_meta_alias),
    .io_out_bits_task_meta_prefetch           (io_toSourceD_bits_task_meta_prefetch),
    .io_out_bits_task_meta_prefetchSrc        (io_toSourceD_bits_task_meta_prefetchSrc),
    .io_out_bits_task_meta_accessed           (io_toSourceD_bits_task_meta_accessed),
    .io_out_bits_task_meta_tagErr             (io_toSourceD_bits_task_meta_tagErr),
    .io_out_bits_task_meta_dataErr            (io_toSourceD_bits_task_meta_dataErr),
    .io_out_bits_task_metaWen                 (io_toSourceD_bits_task_metaWen),
    .io_out_bits_task_tagWen                  (io_toSourceD_bits_task_tagWen),
    .io_out_bits_task_dsWen                   (io_toSourceD_bits_task_dsWen),
    .io_out_bits_task_wayMask                 (io_toSourceD_bits_task_wayMask),
    .io_out_bits_task_replTask                (io_toSourceD_bits_task_replTask),
    .io_out_bits_task_cmoTask                 (io_toSourceD_bits_task_cmoTask),
    .io_out_bits_task_cmoAll                  (io_toSourceD_bits_task_cmoAll),
    .io_out_bits_task_reqSource               (io_toSourceD_bits_task_reqSource),
    .io_out_bits_task_mergeA                  (io_toSourceD_bits_task_mergeA),
    .io_out_bits_task_aMergeTask_off          (io_toSourceD_bits_task_aMergeTask_off),
    .io_out_bits_task_aMergeTask_alias        (io_toSourceD_bits_task_aMergeTask_alias),
    .io_out_bits_task_aMergeTask_vaddr        (io_toSourceD_bits_task_aMergeTask_vaddr),
    .io_out_bits_task_aMergeTask_isKeyword    (io_toSourceD_bits_task_aMergeTask_isKeyword),
    .io_out_bits_task_aMergeTask_opcode       (io_toSourceD_bits_task_aMergeTask_opcode),
    .io_out_bits_task_aMergeTask_param        (io_toSourceD_bits_task_aMergeTask_param),
    .io_out_bits_task_aMergeTask_sourceId     (io_toSourceD_bits_task_aMergeTask_sourceId),
    .io_out_bits_task_aMergeTask_meta_dirty   (io_toSourceD_bits_task_aMergeTask_meta_dirty),
    .io_out_bits_task_aMergeTask_meta_state   (io_toSourceD_bits_task_aMergeTask_meta_state),
    .io_out_bits_task_aMergeTask_meta_clients (io_toSourceD_bits_task_aMergeTask_meta_clients),
    .io_out_bits_task_aMergeTask_meta_alias   (io_toSourceD_bits_task_aMergeTask_meta_alias),
    .io_out_bits_task_aMergeTask_meta_prefetch (io_toSourceD_bits_task_aMergeTask_meta_prefetch),
    .io_out_bits_task_aMergeTask_meta_prefetchSrc (io_toSourceD_bits_task_aMergeTask_meta_prefetchSrc),
    .io_out_bits_task_aMergeTask_meta_accessed (io_toSourceD_bits_task_aMergeTask_meta_accessed),
    .io_out_bits_task_aMergeTask_meta_tagErr  (io_toSourceD_bits_task_aMergeTask_meta_tagErr),
    .io_out_bits_task_aMergeTask_meta_dataErr (io_toSourceD_bits_task_aMergeTask_meta_dataErr),
    .io_out_bits_task_snpHitRelease           (io_toSourceD_bits_task_snpHitRelease),
    .io_out_bits_task_snpHitReleaseToInval    (io_toSourceD_bits_task_snpHitReleaseToInval),
    .io_out_bits_task_snpHitReleaseToClean    (io_toSourceD_bits_task_snpHitReleaseToClean),
    .io_out_bits_task_snpHitReleaseWithData   (io_toSourceD_bits_task_snpHitReleaseWithData),
    .io_out_bits_task_snpHitReleaseIdx        (io_toSourceD_bits_task_snpHitReleaseIdx),
    .io_out_bits_task_snpHitReleaseMeta_dirty (io_toSourceD_bits_task_snpHitReleaseMeta_dirty),
    .io_out_bits_task_snpHitReleaseMeta_state (io_toSourceD_bits_task_snpHitReleaseMeta_state),
    .io_out_bits_task_snpHitReleaseMeta_clients (io_toSourceD_bits_task_snpHitReleaseMeta_clients),
    .io_out_bits_task_snpHitReleaseMeta_alias (io_toSourceD_bits_task_snpHitReleaseMeta_alias),
    .io_out_bits_task_snpHitReleaseMeta_prefetch (io_toSourceD_bits_task_snpHitReleaseMeta_prefetch),
    .io_out_bits_task_snpHitReleaseMeta_prefetchSrc (io_toSourceD_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_out_bits_task_snpHitReleaseMeta_accessed (io_toSourceD_bits_task_snpHitReleaseMeta_accessed),
    .io_out_bits_task_snpHitReleaseMeta_tagErr (io_toSourceD_bits_task_snpHitReleaseMeta_tagErr),
    .io_out_bits_task_snpHitReleaseMeta_dataErr (io_toSourceD_bits_task_snpHitReleaseMeta_dataErr),
    .io_out_bits_task_tgtID                   (io_toSourceD_bits_task_tgtID),
    .io_out_bits_task_srcID                   (io_toSourceD_bits_task_srcID),
    .io_out_bits_task_txnID                   (io_toSourceD_bits_task_txnID),
    .io_out_bits_task_homeNID                 (io_toSourceD_bits_task_homeNID),
    .io_out_bits_task_dbID                    (io_toSourceD_bits_task_dbID),
    .io_out_bits_task_fwdNID                  (io_toSourceD_bits_task_fwdNID),
    .io_out_bits_task_fwdTxnID                (io_toSourceD_bits_task_fwdTxnID),
    .io_out_bits_task_chiOpcode               (io_toSourceD_bits_task_chiOpcode),
    .io_out_bits_task_resp                    (io_toSourceD_bits_task_resp),
    .io_out_bits_task_fwdState                (io_toSourceD_bits_task_fwdState),
    .io_out_bits_task_pCrdType                (io_toSourceD_bits_task_pCrdType),
    .io_out_bits_task_retToSrc                (io_toSourceD_bits_task_retToSrc),
    .io_out_bits_task_likelyshared            (io_toSourceD_bits_task_likelyshared),
    .io_out_bits_task_expCompAck              (io_toSourceD_bits_task_expCompAck),
    .io_out_bits_task_allowRetry              (io_toSourceD_bits_task_allowRetry),
    .io_out_bits_task_memAttr_allocate        (io_toSourceD_bits_task_memAttr_allocate),
    .io_out_bits_task_memAttr_cacheable       (io_toSourceD_bits_task_memAttr_cacheable),
    .io_out_bits_task_memAttr_device          (io_toSourceD_bits_task_memAttr_device),
    .io_out_bits_task_memAttr_ewa             (io_toSourceD_bits_task_memAttr_ewa),
    .io_out_bits_task_traceTag                (io_toSourceD_bits_task_traceTag),
    .io_out_bits_data_data                    (io_toSourceD_bits_data_data)
  );
  Arbiter3_TaskWithData toTXDAT_arb (
    .io_in_0_ready                            (txdat_ready[0]),
    .io_in_0_valid                            (txdat_valid[0]),
    .io_in_0_bits_task_channel                (txdat_task[0].channel),
    .io_in_0_bits_task_txChannel              (txdat_task[0].txChannel),
    .io_in_0_bits_task_set                    (txdat_task[0].set),
    .io_in_0_bits_task_tag                    (txdat_task[0].tag),
    .io_in_0_bits_task_off                    (txdat_task[0].off),
    .io_in_0_bits_task_alias                  (txdat_task[0].alias_),
    .io_in_0_bits_task_vaddr                  (txdat_task[0].vaddr),
    .io_in_0_bits_task_isKeyword              (txdat_task[0].isKeyword),
    .io_in_0_bits_task_opcode                 (txdat_task[0].opcode),
    .io_in_0_bits_task_param                  (txdat_task[0].param),
    .io_in_0_bits_task_size                   (txdat_task[0].size),
    .io_in_0_bits_task_sourceId               (txdat_task[0].sourceId),
    .io_in_0_bits_task_bufIdx                 (txdat_task[0].bufIdx),
    .io_in_0_bits_task_needProbeAckData       (txdat_task[0].needProbeAckData),
    .io_in_0_bits_task_denied                 (txdat_task[0].denied),
    .io_in_0_bits_task_corrupt                (txdat_task[0].corrupt),
    .io_in_0_bits_task_mshrTask               (txdat_task[0].mshrTask),
    .io_in_0_bits_task_mshrId                 (txdat_task[0].mshrId),
    .io_in_0_bits_task_aliasTask              (txdat_task[0].aliasTask),
    .io_in_0_bits_task_useProbeData           (txdat_task[0].useProbeData),
    .io_in_0_bits_task_mshrRetry              (txdat_task[0].mshrRetry),
    .io_in_0_bits_task_readProbeDataDown      (txdat_task[0].readProbeDataDown),
    .io_in_0_bits_task_fromL2pft              (txdat_task[0].fromL2pft),
    .io_in_0_bits_task_needHint               (txdat_task[0].needHint),
    .io_in_0_bits_task_dirty                  (txdat_task[0].dirty),
    .io_in_0_bits_task_way                    (txdat_task[0].way),
    .io_in_0_bits_task_meta_dirty             (txdat_task[0].meta_dirty),
    .io_in_0_bits_task_meta_state             (txdat_task[0].meta_state),
    .io_in_0_bits_task_meta_clients           (txdat_task[0].meta_clients),
    .io_in_0_bits_task_meta_alias             (txdat_task[0].meta_alias),
    .io_in_0_bits_task_meta_prefetch          (txdat_task[0].meta_prefetch),
    .io_in_0_bits_task_meta_prefetchSrc       (txdat_task[0].meta_prefetchSrc),
    .io_in_0_bits_task_meta_accessed          (txdat_task[0].meta_accessed),
    .io_in_0_bits_task_meta_tagErr            (txdat_task[0].meta_tagErr),
    .io_in_0_bits_task_meta_dataErr           (txdat_task[0].meta_dataErr),
    .io_in_0_bits_task_metaWen                (txdat_task[0].metaWen),
    .io_in_0_bits_task_tagWen                 (txdat_task[0].tagWen),
    .io_in_0_bits_task_dsWen                  (txdat_task[0].dsWen),
    .io_in_0_bits_task_wayMask                (txdat_task[0].wayMask),
    .io_in_0_bits_task_replTask               (txdat_task[0].replTask),
    .io_in_0_bits_task_cmoTask                (txdat_task[0].cmoTask),
    .io_in_0_bits_task_cmoAll                 (txdat_task[0].cmoAll),
    .io_in_0_bits_task_reqSource              (txdat_task[0].reqSource),
    .io_in_0_bits_task_mergeA                 (txdat_task[0].mergeA),
    .io_in_0_bits_task_aMergeTask_off         (txdat_task[0].aMergeTask_off),
    .io_in_0_bits_task_aMergeTask_alias       (txdat_task[0].aMergeTask_alias),
    .io_in_0_bits_task_aMergeTask_vaddr       (txdat_task[0].aMergeTask_vaddr),
    .io_in_0_bits_task_aMergeTask_isKeyword   (txdat_task[0].aMergeTask_isKeyword),
    .io_in_0_bits_task_aMergeTask_opcode      (txdat_task[0].aMergeTask_opcode),
    .io_in_0_bits_task_aMergeTask_param       (txdat_task[0].aMergeTask_param),
    .io_in_0_bits_task_aMergeTask_sourceId    (txdat_task[0].aMergeTask_sourceId),
    .io_in_0_bits_task_aMergeTask_meta_dirty  (txdat_task[0].aMergeTask_meta_dirty),
    .io_in_0_bits_task_aMergeTask_meta_state  (txdat_task[0].aMergeTask_meta_state),
    .io_in_0_bits_task_aMergeTask_meta_clients (txdat_task[0].aMergeTask_meta_clients),
    .io_in_0_bits_task_aMergeTask_meta_alias  (txdat_task[0].aMergeTask_meta_alias),
    .io_in_0_bits_task_aMergeTask_meta_prefetch (txdat_task[0].aMergeTask_meta_prefetch),
    .io_in_0_bits_task_aMergeTask_meta_prefetchSrc (txdat_task[0].aMergeTask_meta_prefetchSrc),
    .io_in_0_bits_task_aMergeTask_meta_accessed (txdat_task[0].aMergeTask_meta_accessed),
    .io_in_0_bits_task_aMergeTask_meta_tagErr (txdat_task[0].aMergeTask_meta_tagErr),
    .io_in_0_bits_task_aMergeTask_meta_dataErr (txdat_task[0].aMergeTask_meta_dataErr),
    .io_in_0_bits_task_snpHitRelease          (txdat_task[0].snpHitRelease),
    .io_in_0_bits_task_snpHitReleaseToInval   (txdat_task[0].snpHitReleaseToInval),
    .io_in_0_bits_task_snpHitReleaseToClean   (txdat_task[0].snpHitReleaseToClean),
    .io_in_0_bits_task_snpHitReleaseWithData  (txdat_task[0].snpHitReleaseWithData),
    .io_in_0_bits_task_snpHitReleaseIdx       (txdat_task[0].snpHitReleaseIdx),
    .io_in_0_bits_task_snpHitReleaseMeta_dirty (txdat_task[0].snpHitReleaseMeta_dirty),
    .io_in_0_bits_task_snpHitReleaseMeta_state (txdat_task[0].snpHitReleaseMeta_state),
    .io_in_0_bits_task_snpHitReleaseMeta_clients (txdat_task[0].snpHitReleaseMeta_clients),
    .io_in_0_bits_task_snpHitReleaseMeta_alias (txdat_task[0].snpHitReleaseMeta_alias),
    .io_in_0_bits_task_snpHitReleaseMeta_prefetch (txdat_task[0].snpHitReleaseMeta_prefetch),
    .io_in_0_bits_task_snpHitReleaseMeta_prefetchSrc (txdat_task[0].snpHitReleaseMeta_prefetchSrc),
    .io_in_0_bits_task_snpHitReleaseMeta_accessed (txdat_task[0].snpHitReleaseMeta_accessed),
    .io_in_0_bits_task_snpHitReleaseMeta_tagErr (txdat_task[0].snpHitReleaseMeta_tagErr),
    .io_in_0_bits_task_snpHitReleaseMeta_dataErr (txdat_task[0].snpHitReleaseMeta_dataErr),
    .io_in_0_bits_task_tgtID                  (txdat_task[0].tgtID),
    .io_in_0_bits_task_srcID                  (txdat_task[0].srcID),
    .io_in_0_bits_task_txnID                  (txdat_task[0].txnID),
    .io_in_0_bits_task_homeNID                (txdat_task[0].homeNID),
    .io_in_0_bits_task_dbID                   (txdat_task[0].dbID),
    .io_in_0_bits_task_fwdNID                 (txdat_task[0].fwdNID),
    .io_in_0_bits_task_fwdTxnID               (txdat_task[0].fwdTxnID),
    .io_in_0_bits_task_chiOpcode              (txdat_task[0].chiOpcode),
    .io_in_0_bits_task_resp                   (txdat_task[0].resp),
    .io_in_0_bits_task_fwdState               (txdat_task[0].fwdState),
    .io_in_0_bits_task_pCrdType               (txdat_task[0].pCrdType),
    .io_in_0_bits_task_retToSrc               (txdat_task[0].retToSrc),
    .io_in_0_bits_task_likelyshared           (txdat_task[0].likelyshared),
    .io_in_0_bits_task_expCompAck             (txdat_task[0].expCompAck),
    .io_in_0_bits_task_allowRetry             (txdat_task[0].allowRetry),
    .io_in_0_bits_task_memAttr_allocate       (txdat_task[0].memAttr_allocate),
    .io_in_0_bits_task_memAttr_cacheable      (txdat_task[0].memAttr_cacheable),
    .io_in_0_bits_task_memAttr_device         (txdat_task[0].memAttr_device),
    .io_in_0_bits_task_memAttr_ewa            (txdat_task[0].memAttr_ewa),
    .io_in_0_bits_task_traceTag               (txdat_task[0].traceTag),
    .io_in_0_bits_data_data                   (txdat_data[0]),
    .io_in_1_ready                            (txdat_ready[1]),
    .io_in_1_valid                            (txdat_valid[1]),
    .io_in_1_bits_task_channel                (txdat_task[1].channel),
    .io_in_1_bits_task_txChannel              (txdat_task[1].txChannel),
    .io_in_1_bits_task_set                    (txdat_task[1].set),
    .io_in_1_bits_task_tag                    (txdat_task[1].tag),
    .io_in_1_bits_task_off                    (txdat_task[1].off),
    .io_in_1_bits_task_alias                  (txdat_task[1].alias_),
    .io_in_1_bits_task_vaddr                  (txdat_task[1].vaddr),
    .io_in_1_bits_task_isKeyword              (txdat_task[1].isKeyword),
    .io_in_1_bits_task_opcode                 (txdat_task[1].opcode),
    .io_in_1_bits_task_param                  (txdat_task[1].param),
    .io_in_1_bits_task_size                   (txdat_task[1].size),
    .io_in_1_bits_task_sourceId               (txdat_task[1].sourceId),
    .io_in_1_bits_task_bufIdx                 (txdat_task[1].bufIdx),
    .io_in_1_bits_task_needProbeAckData       (txdat_task[1].needProbeAckData),
    .io_in_1_bits_task_denied                 (txdat_task[1].denied),
    .io_in_1_bits_task_corrupt                (txdat_task[1].corrupt),
    .io_in_1_bits_task_mshrTask               (txdat_task[1].mshrTask),
    .io_in_1_bits_task_mshrId                 (txdat_task[1].mshrId),
    .io_in_1_bits_task_aliasTask              (txdat_task[1].aliasTask),
    .io_in_1_bits_task_useProbeData           (txdat_task[1].useProbeData),
    .io_in_1_bits_task_mshrRetry              (txdat_task[1].mshrRetry),
    .io_in_1_bits_task_readProbeDataDown      (txdat_task[1].readProbeDataDown),
    .io_in_1_bits_task_fromL2pft              (txdat_task[1].fromL2pft),
    .io_in_1_bits_task_needHint               (txdat_task[1].needHint),
    .io_in_1_bits_task_dirty                  (txdat_task[1].dirty),
    .io_in_1_bits_task_way                    (txdat_task[1].way),
    .io_in_1_bits_task_meta_dirty             (txdat_task[1].meta_dirty),
    .io_in_1_bits_task_meta_state             (txdat_task[1].meta_state),
    .io_in_1_bits_task_meta_clients           (txdat_task[1].meta_clients),
    .io_in_1_bits_task_meta_alias             (txdat_task[1].meta_alias),
    .io_in_1_bits_task_meta_prefetch          (txdat_task[1].meta_prefetch),
    .io_in_1_bits_task_meta_prefetchSrc       (txdat_task[1].meta_prefetchSrc),
    .io_in_1_bits_task_meta_accessed          (txdat_task[1].meta_accessed),
    .io_in_1_bits_task_meta_tagErr            (txdat_task[1].meta_tagErr),
    .io_in_1_bits_task_meta_dataErr           (txdat_task[1].meta_dataErr),
    .io_in_1_bits_task_metaWen                (txdat_task[1].metaWen),
    .io_in_1_bits_task_tagWen                 (txdat_task[1].tagWen),
    .io_in_1_bits_task_dsWen                  (txdat_task[1].dsWen),
    .io_in_1_bits_task_wayMask                (txdat_task[1].wayMask),
    .io_in_1_bits_task_replTask               (txdat_task[1].replTask),
    .io_in_1_bits_task_cmoTask                (txdat_task[1].cmoTask),
    .io_in_1_bits_task_cmoAll                 (txdat_task[1].cmoAll),
    .io_in_1_bits_task_reqSource              (txdat_task[1].reqSource),
    .io_in_1_bits_task_mergeA                 (txdat_task[1].mergeA),
    .io_in_1_bits_task_aMergeTask_off         (txdat_task[1].aMergeTask_off),
    .io_in_1_bits_task_aMergeTask_alias       (txdat_task[1].aMergeTask_alias),
    .io_in_1_bits_task_aMergeTask_vaddr       (txdat_task[1].aMergeTask_vaddr),
    .io_in_1_bits_task_aMergeTask_isKeyword   (txdat_task[1].aMergeTask_isKeyword),
    .io_in_1_bits_task_aMergeTask_opcode      (txdat_task[1].aMergeTask_opcode),
    .io_in_1_bits_task_aMergeTask_param       (txdat_task[1].aMergeTask_param),
    .io_in_1_bits_task_aMergeTask_sourceId    (txdat_task[1].aMergeTask_sourceId),
    .io_in_1_bits_task_aMergeTask_meta_dirty  (txdat_task[1].aMergeTask_meta_dirty),
    .io_in_1_bits_task_aMergeTask_meta_state  (txdat_task[1].aMergeTask_meta_state),
    .io_in_1_bits_task_aMergeTask_meta_clients (txdat_task[1].aMergeTask_meta_clients),
    .io_in_1_bits_task_aMergeTask_meta_alias  (txdat_task[1].aMergeTask_meta_alias),
    .io_in_1_bits_task_aMergeTask_meta_prefetch (txdat_task[1].aMergeTask_meta_prefetch),
    .io_in_1_bits_task_aMergeTask_meta_prefetchSrc (txdat_task[1].aMergeTask_meta_prefetchSrc),
    .io_in_1_bits_task_aMergeTask_meta_accessed (txdat_task[1].aMergeTask_meta_accessed),
    .io_in_1_bits_task_aMergeTask_meta_tagErr (txdat_task[1].aMergeTask_meta_tagErr),
    .io_in_1_bits_task_aMergeTask_meta_dataErr (txdat_task[1].aMergeTask_meta_dataErr),
    .io_in_1_bits_task_snpHitRelease          (txdat_task[1].snpHitRelease),
    .io_in_1_bits_task_snpHitReleaseToInval   (txdat_task[1].snpHitReleaseToInval),
    .io_in_1_bits_task_snpHitReleaseToClean   (txdat_task[1].snpHitReleaseToClean),
    .io_in_1_bits_task_snpHitReleaseWithData  (txdat_task[1].snpHitReleaseWithData),
    .io_in_1_bits_task_snpHitReleaseIdx       (txdat_task[1].snpHitReleaseIdx),
    .io_in_1_bits_task_snpHitReleaseMeta_dirty (txdat_task[1].snpHitReleaseMeta_dirty),
    .io_in_1_bits_task_snpHitReleaseMeta_state (txdat_task[1].snpHitReleaseMeta_state),
    .io_in_1_bits_task_snpHitReleaseMeta_clients (txdat_task[1].snpHitReleaseMeta_clients),
    .io_in_1_bits_task_snpHitReleaseMeta_alias (txdat_task[1].snpHitReleaseMeta_alias),
    .io_in_1_bits_task_snpHitReleaseMeta_prefetch (txdat_task[1].snpHitReleaseMeta_prefetch),
    .io_in_1_bits_task_snpHitReleaseMeta_prefetchSrc (txdat_task[1].snpHitReleaseMeta_prefetchSrc),
    .io_in_1_bits_task_snpHitReleaseMeta_accessed (txdat_task[1].snpHitReleaseMeta_accessed),
    .io_in_1_bits_task_snpHitReleaseMeta_tagErr (txdat_task[1].snpHitReleaseMeta_tagErr),
    .io_in_1_bits_task_snpHitReleaseMeta_dataErr (txdat_task[1].snpHitReleaseMeta_dataErr),
    .io_in_1_bits_task_tgtID                  (txdat_task[1].tgtID),
    .io_in_1_bits_task_srcID                  (txdat_task[1].srcID),
    .io_in_1_bits_task_txnID                  (txdat_task[1].txnID),
    .io_in_1_bits_task_homeNID                (txdat_task[1].homeNID),
    .io_in_1_bits_task_dbID                   (txdat_task[1].dbID),
    .io_in_1_bits_task_fwdNID                 (txdat_task[1].fwdNID),
    .io_in_1_bits_task_fwdTxnID               (txdat_task[1].fwdTxnID),
    .io_in_1_bits_task_chiOpcode              (txdat_task[1].chiOpcode),
    .io_in_1_bits_task_resp                   (txdat_task[1].resp),
    .io_in_1_bits_task_fwdState               (txdat_task[1].fwdState),
    .io_in_1_bits_task_pCrdType               (txdat_task[1].pCrdType),
    .io_in_1_bits_task_retToSrc               (txdat_task[1].retToSrc),
    .io_in_1_bits_task_likelyshared           (txdat_task[1].likelyshared),
    .io_in_1_bits_task_expCompAck             (txdat_task[1].expCompAck),
    .io_in_1_bits_task_allowRetry             (txdat_task[1].allowRetry),
    .io_in_1_bits_task_memAttr_allocate       (txdat_task[1].memAttr_allocate),
    .io_in_1_bits_task_memAttr_cacheable      (txdat_task[1].memAttr_cacheable),
    .io_in_1_bits_task_memAttr_device         (txdat_task[1].memAttr_device),
    .io_in_1_bits_task_memAttr_ewa            (txdat_task[1].memAttr_ewa),
    .io_in_1_bits_task_traceTag               (txdat_task[1].traceTag),
    .io_in_1_bits_data_data                   (txdat_data[1]),
    .io_in_2_ready                            (txdat_ready[2]),
    .io_in_2_valid                            (txdat_valid[2]),
    .io_in_2_bits_task_channel                (txdat_task[2].channel),
    .io_in_2_bits_task_txChannel              (txdat_task[2].txChannel),
    .io_in_2_bits_task_set                    (txdat_task[2].set),
    .io_in_2_bits_task_tag                    (txdat_task[2].tag),
    .io_in_2_bits_task_off                    (txdat_task[2].off),
    .io_in_2_bits_task_alias                  (txdat_task[2].alias_),
    .io_in_2_bits_task_vaddr                  (txdat_task[2].vaddr),
    .io_in_2_bits_task_isKeyword              (txdat_task[2].isKeyword),
    .io_in_2_bits_task_opcode                 (txdat_task[2].opcode),
    .io_in_2_bits_task_param                  (txdat_task[2].param),
    .io_in_2_bits_task_size                   (txdat_task[2].size),
    .io_in_2_bits_task_sourceId               (txdat_task[2].sourceId),
    .io_in_2_bits_task_bufIdx                 (txdat_task[2].bufIdx),
    .io_in_2_bits_task_needProbeAckData       (txdat_task[2].needProbeAckData),
    .io_in_2_bits_task_denied                 (txdat_task[2].denied),
    .io_in_2_bits_task_corrupt                (txdat_task[2].corrupt),
    .io_in_2_bits_task_mshrTask               (txdat_task[2].mshrTask),
    .io_in_2_bits_task_mshrId                 (txdat_task[2].mshrId),
    .io_in_2_bits_task_aliasTask              (txdat_task[2].aliasTask),
    .io_in_2_bits_task_useProbeData           (txdat_task[2].useProbeData),
    .io_in_2_bits_task_mshrRetry              (txdat_task[2].mshrRetry),
    .io_in_2_bits_task_readProbeDataDown      (txdat_task[2].readProbeDataDown),
    .io_in_2_bits_task_fromL2pft              (txdat_task[2].fromL2pft),
    .io_in_2_bits_task_needHint               (txdat_task[2].needHint),
    .io_in_2_bits_task_dirty                  (txdat_task[2].dirty),
    .io_in_2_bits_task_way                    (txdat_task[2].way),
    .io_in_2_bits_task_meta_dirty             (txdat_task[2].meta_dirty),
    .io_in_2_bits_task_meta_state             (txdat_task[2].meta_state),
    .io_in_2_bits_task_meta_clients           (txdat_task[2].meta_clients),
    .io_in_2_bits_task_meta_alias             (txdat_task[2].meta_alias),
    .io_in_2_bits_task_meta_prefetch          (txdat_task[2].meta_prefetch),
    .io_in_2_bits_task_meta_prefetchSrc       (txdat_task[2].meta_prefetchSrc),
    .io_in_2_bits_task_meta_accessed          (txdat_task[2].meta_accessed),
    .io_in_2_bits_task_meta_tagErr            (txdat_task[2].meta_tagErr),
    .io_in_2_bits_task_meta_dataErr           (txdat_task[2].meta_dataErr),
    .io_in_2_bits_task_metaWen                (txdat_task[2].metaWen),
    .io_in_2_bits_task_tagWen                 (txdat_task[2].tagWen),
    .io_in_2_bits_task_dsWen                  (txdat_task[2].dsWen),
    .io_in_2_bits_task_wayMask                (txdat_task[2].wayMask),
    .io_in_2_bits_task_replTask               (txdat_task[2].replTask),
    .io_in_2_bits_task_cmoTask                (txdat_task[2].cmoTask),
    .io_in_2_bits_task_cmoAll                 (txdat_task[2].cmoAll),
    .io_in_2_bits_task_reqSource              (txdat_task[2].reqSource),
    .io_in_2_bits_task_mergeA                 (txdat_task[2].mergeA),
    .io_in_2_bits_task_aMergeTask_off         (txdat_task[2].aMergeTask_off),
    .io_in_2_bits_task_aMergeTask_alias       (txdat_task[2].aMergeTask_alias),
    .io_in_2_bits_task_aMergeTask_vaddr       (txdat_task[2].aMergeTask_vaddr),
    .io_in_2_bits_task_aMergeTask_isKeyword   (txdat_task[2].aMergeTask_isKeyword),
    .io_in_2_bits_task_aMergeTask_opcode      (txdat_task[2].aMergeTask_opcode),
    .io_in_2_bits_task_aMergeTask_param       (txdat_task[2].aMergeTask_param),
    .io_in_2_bits_task_aMergeTask_sourceId    (txdat_task[2].aMergeTask_sourceId),
    .io_in_2_bits_task_aMergeTask_meta_dirty  (txdat_task[2].aMergeTask_meta_dirty),
    .io_in_2_bits_task_aMergeTask_meta_state  (txdat_task[2].aMergeTask_meta_state),
    .io_in_2_bits_task_aMergeTask_meta_clients (txdat_task[2].aMergeTask_meta_clients),
    .io_in_2_bits_task_aMergeTask_meta_alias  (txdat_task[2].aMergeTask_meta_alias),
    .io_in_2_bits_task_aMergeTask_meta_prefetch (txdat_task[2].aMergeTask_meta_prefetch),
    .io_in_2_bits_task_aMergeTask_meta_prefetchSrc (txdat_task[2].aMergeTask_meta_prefetchSrc),
    .io_in_2_bits_task_aMergeTask_meta_accessed (txdat_task[2].aMergeTask_meta_accessed),
    .io_in_2_bits_task_aMergeTask_meta_tagErr (txdat_task[2].aMergeTask_meta_tagErr),
    .io_in_2_bits_task_aMergeTask_meta_dataErr (txdat_task[2].aMergeTask_meta_dataErr),
    .io_in_2_bits_task_snpHitRelease          (txdat_task[2].snpHitRelease),
    .io_in_2_bits_task_snpHitReleaseToInval   (txdat_task[2].snpHitReleaseToInval),
    .io_in_2_bits_task_snpHitReleaseToClean   (txdat_task[2].snpHitReleaseToClean),
    .io_in_2_bits_task_snpHitReleaseWithData  (txdat_task[2].snpHitReleaseWithData),
    .io_in_2_bits_task_snpHitReleaseIdx       (txdat_task[2].snpHitReleaseIdx),
    .io_in_2_bits_task_snpHitReleaseMeta_dirty (txdat_task[2].snpHitReleaseMeta_dirty),
    .io_in_2_bits_task_snpHitReleaseMeta_state (txdat_task[2].snpHitReleaseMeta_state),
    .io_in_2_bits_task_snpHitReleaseMeta_clients (txdat_task[2].snpHitReleaseMeta_clients),
    .io_in_2_bits_task_snpHitReleaseMeta_alias (txdat_task[2].snpHitReleaseMeta_alias),
    .io_in_2_bits_task_snpHitReleaseMeta_prefetch (txdat_task[2].snpHitReleaseMeta_prefetch),
    .io_in_2_bits_task_snpHitReleaseMeta_prefetchSrc (txdat_task[2].snpHitReleaseMeta_prefetchSrc),
    .io_in_2_bits_task_snpHitReleaseMeta_accessed (txdat_task[2].snpHitReleaseMeta_accessed),
    .io_in_2_bits_task_snpHitReleaseMeta_tagErr (txdat_task[2].snpHitReleaseMeta_tagErr),
    .io_in_2_bits_task_snpHitReleaseMeta_dataErr (txdat_task[2].snpHitReleaseMeta_dataErr),
    .io_in_2_bits_task_tgtID                  (txdat_task[2].tgtID),
    .io_in_2_bits_task_srcID                  (txdat_task[2].srcID),
    .io_in_2_bits_task_txnID                  (txdat_task[2].txnID),
    .io_in_2_bits_task_homeNID                (txdat_task[2].homeNID),
    .io_in_2_bits_task_dbID                   (txdat_task[2].dbID),
    .io_in_2_bits_task_fwdNID                 (txdat_task[2].fwdNID),
    .io_in_2_bits_task_fwdTxnID               (txdat_task[2].fwdTxnID),
    .io_in_2_bits_task_chiOpcode              (txdat_task[2].chiOpcode),
    .io_in_2_bits_task_resp                   (txdat_task[2].resp),
    .io_in_2_bits_task_fwdState               (txdat_task[2].fwdState),
    .io_in_2_bits_task_pCrdType               (txdat_task[2].pCrdType),
    .io_in_2_bits_task_retToSrc               (txdat_task[2].retToSrc),
    .io_in_2_bits_task_likelyshared           (txdat_task[2].likelyshared),
    .io_in_2_bits_task_expCompAck             (txdat_task[2].expCompAck),
    .io_in_2_bits_task_allowRetry             (txdat_task[2].allowRetry),
    .io_in_2_bits_task_memAttr_allocate       (txdat_task[2].memAttr_allocate),
    .io_in_2_bits_task_memAttr_cacheable      (txdat_task[2].memAttr_cacheable),
    .io_in_2_bits_task_memAttr_device         (txdat_task[2].memAttr_device),
    .io_in_2_bits_task_memAttr_ewa            (txdat_task[2].memAttr_ewa),
    .io_in_2_bits_task_traceTag               (txdat_task[2].traceTag),
    .io_in_2_bits_data_data                   (txdat_data[2]),
    .io_out_ready                             (io_toTXDAT_ready),
    .io_out_valid                             (io_toTXDAT_valid),
    .io_out_bits_task_channel                 (io_toTXDAT_bits_task_channel),
    .io_out_bits_task_txChannel               (io_toTXDAT_bits_task_txChannel),
    .io_out_bits_task_set                     (io_toTXDAT_bits_task_set),
    .io_out_bits_task_tag                     (io_toTXDAT_bits_task_tag),
    .io_out_bits_task_off                     (io_toTXDAT_bits_task_off),
    .io_out_bits_task_alias                   (io_toTXDAT_bits_task_alias),
    .io_out_bits_task_vaddr                   (io_toTXDAT_bits_task_vaddr),
    .io_out_bits_task_isKeyword               (io_toTXDAT_bits_task_isKeyword),
    .io_out_bits_task_opcode                  (io_toTXDAT_bits_task_opcode),
    .io_out_bits_task_param                   (io_toTXDAT_bits_task_param),
    .io_out_bits_task_size                    (io_toTXDAT_bits_task_size),
    .io_out_bits_task_sourceId                (io_toTXDAT_bits_task_sourceId),
    .io_out_bits_task_bufIdx                  (io_toTXDAT_bits_task_bufIdx),
    .io_out_bits_task_needProbeAckData        (io_toTXDAT_bits_task_needProbeAckData),
    .io_out_bits_task_denied                  (io_toTXDAT_bits_task_denied),
    .io_out_bits_task_corrupt                 (io_toTXDAT_bits_task_corrupt),
    .io_out_bits_task_mshrTask                (io_toTXDAT_bits_task_mshrTask),
    .io_out_bits_task_mshrId                  (io_toTXDAT_bits_task_mshrId),
    .io_out_bits_task_aliasTask               (io_toTXDAT_bits_task_aliasTask),
    .io_out_bits_task_useProbeData            (io_toTXDAT_bits_task_useProbeData),
    .io_out_bits_task_mshrRetry               (io_toTXDAT_bits_task_mshrRetry),
    .io_out_bits_task_readProbeDataDown       (io_toTXDAT_bits_task_readProbeDataDown),
    .io_out_bits_task_fromL2pft               (io_toTXDAT_bits_task_fromL2pft),
    .io_out_bits_task_needHint                (io_toTXDAT_bits_task_needHint),
    .io_out_bits_task_dirty                   (io_toTXDAT_bits_task_dirty),
    .io_out_bits_task_way                     (io_toTXDAT_bits_task_way),
    .io_out_bits_task_meta_dirty              (io_toTXDAT_bits_task_meta_dirty),
    .io_out_bits_task_meta_state              (io_toTXDAT_bits_task_meta_state),
    .io_out_bits_task_meta_clients            (io_toTXDAT_bits_task_meta_clients),
    .io_out_bits_task_meta_alias              (io_toTXDAT_bits_task_meta_alias),
    .io_out_bits_task_meta_prefetch           (io_toTXDAT_bits_task_meta_prefetch),
    .io_out_bits_task_meta_prefetchSrc        (io_toTXDAT_bits_task_meta_prefetchSrc),
    .io_out_bits_task_meta_accessed           (io_toTXDAT_bits_task_meta_accessed),
    .io_out_bits_task_meta_tagErr             (io_toTXDAT_bits_task_meta_tagErr),
    .io_out_bits_task_meta_dataErr            (io_toTXDAT_bits_task_meta_dataErr),
    .io_out_bits_task_metaWen                 (io_toTXDAT_bits_task_metaWen),
    .io_out_bits_task_tagWen                  (io_toTXDAT_bits_task_tagWen),
    .io_out_bits_task_dsWen                   (io_toTXDAT_bits_task_dsWen),
    .io_out_bits_task_wayMask                 (io_toTXDAT_bits_task_wayMask),
    .io_out_bits_task_replTask                (io_toTXDAT_bits_task_replTask),
    .io_out_bits_task_cmoTask                 (io_toTXDAT_bits_task_cmoTask),
    .io_out_bits_task_cmoAll                  (io_toTXDAT_bits_task_cmoAll),
    .io_out_bits_task_reqSource               (io_toTXDAT_bits_task_reqSource),
    .io_out_bits_task_mergeA                  (io_toTXDAT_bits_task_mergeA),
    .io_out_bits_task_aMergeTask_off          (io_toTXDAT_bits_task_aMergeTask_off),
    .io_out_bits_task_aMergeTask_alias        (io_toTXDAT_bits_task_aMergeTask_alias),
    .io_out_bits_task_aMergeTask_vaddr        (io_toTXDAT_bits_task_aMergeTask_vaddr),
    .io_out_bits_task_aMergeTask_isKeyword    (io_toTXDAT_bits_task_aMergeTask_isKeyword),
    .io_out_bits_task_aMergeTask_opcode       (io_toTXDAT_bits_task_aMergeTask_opcode),
    .io_out_bits_task_aMergeTask_param        (io_toTXDAT_bits_task_aMergeTask_param),
    .io_out_bits_task_aMergeTask_sourceId     (io_toTXDAT_bits_task_aMergeTask_sourceId),
    .io_out_bits_task_aMergeTask_meta_dirty   (io_toTXDAT_bits_task_aMergeTask_meta_dirty),
    .io_out_bits_task_aMergeTask_meta_state   (io_toTXDAT_bits_task_aMergeTask_meta_state),
    .io_out_bits_task_aMergeTask_meta_clients (io_toTXDAT_bits_task_aMergeTask_meta_clients),
    .io_out_bits_task_aMergeTask_meta_alias   (io_toTXDAT_bits_task_aMergeTask_meta_alias),
    .io_out_bits_task_aMergeTask_meta_prefetch (io_toTXDAT_bits_task_aMergeTask_meta_prefetch),
    .io_out_bits_task_aMergeTask_meta_prefetchSrc (io_toTXDAT_bits_task_aMergeTask_meta_prefetchSrc),
    .io_out_bits_task_aMergeTask_meta_accessed (io_toTXDAT_bits_task_aMergeTask_meta_accessed),
    .io_out_bits_task_aMergeTask_meta_tagErr  (io_toTXDAT_bits_task_aMergeTask_meta_tagErr),
    .io_out_bits_task_aMergeTask_meta_dataErr (io_toTXDAT_bits_task_aMergeTask_meta_dataErr),
    .io_out_bits_task_snpHitRelease           (io_toTXDAT_bits_task_snpHitRelease),
    .io_out_bits_task_snpHitReleaseToInval    (io_toTXDAT_bits_task_snpHitReleaseToInval),
    .io_out_bits_task_snpHitReleaseToClean    (io_toTXDAT_bits_task_snpHitReleaseToClean),
    .io_out_bits_task_snpHitReleaseWithData   (io_toTXDAT_bits_task_snpHitReleaseWithData),
    .io_out_bits_task_snpHitReleaseIdx        (io_toTXDAT_bits_task_snpHitReleaseIdx),
    .io_out_bits_task_snpHitReleaseMeta_dirty (io_toTXDAT_bits_task_snpHitReleaseMeta_dirty),
    .io_out_bits_task_snpHitReleaseMeta_state (io_toTXDAT_bits_task_snpHitReleaseMeta_state),
    .io_out_bits_task_snpHitReleaseMeta_clients (io_toTXDAT_bits_task_snpHitReleaseMeta_clients),
    .io_out_bits_task_snpHitReleaseMeta_alias (io_toTXDAT_bits_task_snpHitReleaseMeta_alias),
    .io_out_bits_task_snpHitReleaseMeta_prefetch (io_toTXDAT_bits_task_snpHitReleaseMeta_prefetch),
    .io_out_bits_task_snpHitReleaseMeta_prefetchSrc (io_toTXDAT_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_out_bits_task_snpHitReleaseMeta_accessed (io_toTXDAT_bits_task_snpHitReleaseMeta_accessed),
    .io_out_bits_task_snpHitReleaseMeta_tagErr (io_toTXDAT_bits_task_snpHitReleaseMeta_tagErr),
    .io_out_bits_task_snpHitReleaseMeta_dataErr (io_toTXDAT_bits_task_snpHitReleaseMeta_dataErr),
    .io_out_bits_task_tgtID                   (io_toTXDAT_bits_task_tgtID),
    .io_out_bits_task_srcID                   (io_toTXDAT_bits_task_srcID),
    .io_out_bits_task_txnID                   (io_toTXDAT_bits_task_txnID),
    .io_out_bits_task_homeNID                 (io_toTXDAT_bits_task_homeNID),
    .io_out_bits_task_dbID                    (io_toTXDAT_bits_task_dbID),
    .io_out_bits_task_fwdNID                  (io_toTXDAT_bits_task_fwdNID),
    .io_out_bits_task_fwdTxnID                (io_toTXDAT_bits_task_fwdTxnID),
    .io_out_bits_task_chiOpcode               (io_toTXDAT_bits_task_chiOpcode),
    .io_out_bits_task_resp                    (io_toTXDAT_bits_task_resp),
    .io_out_bits_task_fwdState                (io_toTXDAT_bits_task_fwdState),
    .io_out_bits_task_pCrdType                (io_toTXDAT_bits_task_pCrdType),
    .io_out_bits_task_retToSrc                (io_toTXDAT_bits_task_retToSrc),
    .io_out_bits_task_likelyshared            (io_toTXDAT_bits_task_likelyshared),
    .io_out_bits_task_expCompAck              (io_toTXDAT_bits_task_expCompAck),
    .io_out_bits_task_allowRetry              (io_toTXDAT_bits_task_allowRetry),
    .io_out_bits_task_memAttr_allocate        (io_toTXDAT_bits_task_memAttr_allocate),
    .io_out_bits_task_memAttr_cacheable       (io_toTXDAT_bits_task_memAttr_cacheable),
    .io_out_bits_task_memAttr_device          (io_toTXDAT_bits_task_memAttr_device),
    .io_out_bits_task_memAttr_ewa             (io_toTXDAT_bits_task_memAttr_ewa),
    .io_out_bits_task_traceTag                (io_toTXDAT_bits_task_traceTag),
    .io_out_bits_data_data                    (io_toTXDAT_bits_data_data)
  );
  assign txreq_ready[0] = 1'b1;   // out.ready 恒 1 => 第 0 路永远 ready（golden 删了这根）
  Arbiter3_CHIREQ toTXREQ_arb (
    .io_in_0_valid                  (txreq_valid[0]),
    .io_in_0_bits_tgtID             (txreq_bits[0].tgtID),
    .io_in_0_bits_srcID             (txreq_bits[0].srcID),
    .io_in_0_bits_txnID             (txreq_bits[0].txnID),
    .io_in_0_bits_opcode            (txreq_bits[0].opcode),
    .io_in_0_bits_addr              (txreq_bits[0].addr),
    .io_in_0_bits_likelyshared      (txreq_bits[0].likelyshared),
    .io_in_0_bits_allowRetry        (txreq_bits[0].allowRetry),
    .io_in_0_bits_pCrdType          (txreq_bits[0].pCrdType),
    .io_in_0_bits_memAttr_allocate  (txreq_bits[0].memAttr_allocate),
    .io_in_0_bits_memAttr_cacheable (txreq_bits[0].memAttr_cacheable),
    .io_in_0_bits_memAttr_device    (txreq_bits[0].memAttr_device),
    .io_in_0_bits_memAttr_ewa       (txreq_bits[0].memAttr_ewa),
    .io_in_0_bits_expCompAck        (txreq_bits[0].expCompAck),
    .io_in_1_ready                  (txreq_ready[1]),
    .io_in_1_valid                  (txreq_valid[1]),
    .io_in_1_bits_tgtID             (txreq_bits[1].tgtID),
    .io_in_1_bits_srcID             (txreq_bits[1].srcID),
    .io_in_1_bits_txnID             (txreq_bits[1].txnID),
    .io_in_1_bits_opcode            (txreq_bits[1].opcode),
    .io_in_1_bits_addr              (txreq_bits[1].addr),
    .io_in_1_bits_likelyshared      (txreq_bits[1].likelyshared),
    .io_in_1_bits_allowRetry        (txreq_bits[1].allowRetry),
    .io_in_1_bits_pCrdType          (txreq_bits[1].pCrdType),
    .io_in_1_bits_memAttr_allocate  (txreq_bits[1].memAttr_allocate),
    .io_in_1_bits_memAttr_cacheable (txreq_bits[1].memAttr_cacheable),
    .io_in_1_bits_memAttr_device    (txreq_bits[1].memAttr_device),
    .io_in_1_bits_memAttr_ewa       (txreq_bits[1].memAttr_ewa),
    .io_in_1_bits_expCompAck        (txreq_bits[1].expCompAck),
    .io_in_2_ready                  (txreq_ready[2]),
    .io_in_2_valid                  (txreq_valid[2]),
    .io_in_2_bits_tgtID             (txreq_bits[2].tgtID),
    .io_in_2_bits_srcID             (txreq_bits[2].srcID),
    .io_in_2_bits_txnID             (txreq_bits[2].txnID),
    .io_in_2_bits_opcode            (txreq_bits[2].opcode),
    .io_in_2_bits_addr              (txreq_bits[2].addr),
    .io_in_2_bits_likelyshared      (txreq_bits[2].likelyshared),
    .io_in_2_bits_allowRetry        (txreq_bits[2].allowRetry),
    .io_in_2_bits_pCrdType          (txreq_bits[2].pCrdType),
    .io_in_2_bits_memAttr_allocate  (txreq_bits[2].memAttr_allocate),
    .io_in_2_bits_memAttr_cacheable (txreq_bits[2].memAttr_cacheable),
    .io_in_2_bits_memAttr_device    (txreq_bits[2].memAttr_device),
    .io_in_2_bits_memAttr_ewa       (txreq_bits[2].memAttr_ewa),
    .io_in_2_bits_expCompAck        (txreq_bits[2].expCompAck),
    .io_out_valid                   (io_toTXREQ_valid),
    .io_out_bits_tgtID              (io_toTXREQ_bits_tgtID),
    .io_out_bits_srcID              (io_toTXREQ_bits_srcID),
    .io_out_bits_txnID              (io_toTXREQ_bits_txnID),
    .io_out_bits_opcode             (io_toTXREQ_bits_opcode),
    .io_out_bits_addr               (io_toTXREQ_bits_addr),
    .io_out_bits_likelyshared       (io_toTXREQ_bits_likelyshared),
    .io_out_bits_allowRetry         (io_toTXREQ_bits_allowRetry),
    .io_out_bits_pCrdType           (io_toTXREQ_bits_pCrdType),
    .io_out_bits_memAttr_allocate   (io_toTXREQ_bits_memAttr_allocate),
    .io_out_bits_memAttr_cacheable  (io_toTXREQ_bits_memAttr_cacheable),
    .io_out_bits_memAttr_device     (io_toTXREQ_bits_memAttr_device),
    .io_out_bits_memAttr_ewa        (io_toTXREQ_bits_memAttr_ewa),
    .io_out_bits_expCompAck         (io_toTXREQ_bits_expCompAck)
  );
  assign txrsp_ready[0] = 1'b1;
  Arbiter3_TaskBundle toTXRSP_arb (
    .io_in_0_valid            (txrsp_valid[0]),
    .io_in_0_bits_txChannel   (txrsp_task[0].txChannel),
    .io_in_0_bits_denied      (txrsp_task[0].denied),
    .io_in_0_bits_tgtID       (txrsp_task[0].tgtID),
    .io_in_0_bits_srcID       (txrsp_task[0].srcID),
    .io_in_0_bits_txnID       (txrsp_task[0].txnID),
    .io_in_0_bits_dbID        (txrsp_task[0].dbID),
    .io_in_0_bits_chiOpcode   (txrsp_task[0].chiOpcode),
    .io_in_0_bits_resp        (txrsp_task[0].resp),
    .io_in_0_bits_fwdState    (txrsp_task[0].fwdState),
    .io_in_0_bits_pCrdType    (txrsp_task[0].pCrdType),
    .io_in_0_bits_traceTag    (txrsp_task[0].traceTag),
    .io_in_1_ready            (txrsp_ready[1]),
    .io_in_1_valid            (txrsp_valid[1]),
    .io_in_1_bits_txChannel   (txrsp_task[1].txChannel),
    .io_in_1_bits_denied      (txrsp_task[1].denied),
    .io_in_1_bits_tgtID       (txrsp_task[1].tgtID),
    .io_in_1_bits_srcID       (txrsp_task[1].srcID),
    .io_in_1_bits_txnID       (txrsp_task[1].txnID),
    .io_in_1_bits_dbID        (txrsp_task[1].dbID),
    .io_in_1_bits_chiOpcode   (txrsp_task[1].chiOpcode),
    .io_in_1_bits_resp        (txrsp_task[1].resp),
    .io_in_1_bits_fwdState    (txrsp_task[1].fwdState),
    .io_in_1_bits_pCrdType    (txrsp_task[1].pCrdType),
    .io_in_1_bits_traceTag    (txrsp_task[1].traceTag),
    .io_in_2_ready            (txrsp_ready[2]),
    .io_in_2_valid            (txrsp_valid[2]),
    .io_in_2_bits_txChannel   (txrsp_task[2].txChannel),
    .io_in_2_bits_denied      (txrsp_task[2].denied),
    .io_in_2_bits_tgtID       (txrsp_task[2].tgtID),
    .io_in_2_bits_srcID       (txrsp_task[2].srcID),
    .io_in_2_bits_txnID       (txrsp_task[2].txnID),
    .io_in_2_bits_dbID        (txrsp_task[2].dbID),
    .io_in_2_bits_chiOpcode   (txrsp_task[2].chiOpcode),
    .io_in_2_bits_resp        (txrsp_task[2].resp),
    .io_in_2_bits_fwdState    (txrsp_task[2].fwdState),
    .io_in_2_bits_pCrdType    (txrsp_task[2].pCrdType),
    .io_in_2_bits_traceTag    (txrsp_task[2].traceTag),
    .io_out_valid             (io_toTXRSP_valid),
    .io_out_bits_txChannel    (io_toTXRSP_bits_txChannel),
    .io_out_bits_denied       (io_toTXRSP_bits_denied),
    .io_out_bits_tgtID        (io_toTXRSP_bits_tgtID),
    .io_out_bits_srcID        (io_toTXRSP_bits_srcID),
    .io_out_bits_txnID        (io_toTXRSP_bits_txnID),
    .io_out_bits_dbID         (io_toTXRSP_bits_dbID),
    .io_out_bits_chiOpcode    (io_toTXRSP_bits_chiOpcode),
    .io_out_bits_resp         (io_toTXRSP_bits_resp),
    .io_out_bits_fwdState     (io_toTXRSP_bits_fwdState),
    .io_out_bits_pCrdType     (io_toTXRSP_bits_pCrdType),
    .io_out_bits_traceTag     (io_toTXRSP_bits_traceTag)
  );

endmodule
// END GENERATED(wrapper)
