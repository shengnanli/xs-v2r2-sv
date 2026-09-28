// =============================================================================
// MSHR.sv —— CoupledL2（tl2chi）的一个 MSHR 表项：一条 miss / snoop / CMO 事务的状态机
//
// 位置：L2 slice 的 MSHRCtl 里例化 16 份（mshrs_0..15）。MainPipe 在 s3 判定"本拍处理
// 不完、要等外部"时分配一个空闲 MSHR（io_alloc），把请求（req = TaskBundle）、目录查询
// 结果（dirResult）和一组"还欠哪些动作"的标志（state）一起写进来；此后 MSHR 自己
// 往外发请求、收响应、改标志，全部标志回到 1 时释放（will_free）。
// 对照 Scala：coupledL2/src/main/scala/coupledL2/tl2chi/MSHR.scala（行号见各节）。
//
// ★核心数据结构：state 里 23 个标志，全部"1 = 已完成 / 不需要"，0 = 还欠着★
//   s_*（schedule，要"发出去"的动作；发出去那拍置 1）
//     s_acquire   向 CHI 下游发 Read*/MakeUnique（TXREQ）           s_rprobe  替换引起的 Probe（向 L1）
//     s_pprobe    snoop 引起的 Probe（向 L1）                          s_release 替换/CMO 的写回（经 MainPipe）
//     s_probeack  回 snoop 的 SnpResp[Data]（经 MainPipe）            s_refill  回 L1 的 Grant/AccessAck（经 MainPipe）
//     s_retry     replacer 要求重来时清 0，MainPipe 收下 grant 任务时置 1
//     s_cmoresp   CMO 的 CBOAck                                        s_cmometaw cbo.clean 的 meta 补写
//     s_rcompack  读事务的 CompAck（TXRSP）                            s_wcompack WriteEvictOrEvict 的 CompAck（TXRSP）
//     s_cbwrdata  写回的 CopyBackWrData（经 MainPipe → TXDAT）         s_reissue 收到 RetryAck + PCrdGrant 后重发
//     s_dct       DCT：直接把数据转发给请求者（CompData，经 MainPipe）
//   w_*（wait，要"等回来"的响应；收到那拍置 1）
//     w_rprobeackfirst/last  替换 Probe 的 ProbeAck 首/末拍      w_pprobeackfirst/last  snoop Probe 的 ProbeAck 首/末拍
//     w_grantfirst/last      CompData / DataSepResp 首/末拍      w_grant                读事务的"响应"部分已收到
//     w_releaseack           写回的 CompDBIDResp / Comp          w_replResp             replacer 选路结果已回来
//
// 本文件结构：package（元数据/任务打包类型、编码常量）→ xs_MSHR_core（可读核）→ MSHR（wrapper）。
// 核按 Scala 的节顺序写：§1 寄存器 → §2 派生判断 → §3 四路发请求（txreq/txrsp/source_b/mainpipe）
// → §4 状态更新（与 Chisel 的 when 顺序逐条对应，"后写覆盖先写"）→ §5 状态/信息输出 → §6 性能与断言影子。
//
// ★忠实 golden 的几处（照抄，勿"优化"）★
//   · 寄存器名与 golden 一一同名（req_* / dirResult_* / state_*），字段集合就是 golden 保留的那些
//     （firtool 把 txChannel/vaddr/size 等未被读的 req 字段整个删掉了，这里也没有）。
//   · io_alloc_bits_state 里没有 s_retry/s_cmometaw/s_wcompack/s_cbwrdata/s_reissue 五个端口：
//     MainPipe 分配时它们恒为 1，firtool 跨模块常量传播后删掉了端口，分配时这里直接写 1。
//   · 断言专用的影子寄存器（validCnt 死锁计数、REG/REG_1..3 写回类型打拍）在综合视图里没有读者，
//     golden 仍保留，这里照写（两侧对称死位，FM 走 vmucp）。
//   · msInfo.blockRefill 的两级 RegNext 在 golden 里是三个寄存器（REG 与 REG_1 同源），照写。
//
// BEGIN GENERATED(nav) —— scripts/gen_mshr.py 生成
// 本文件导航：
//   L501 §1 寄存器（MSHR.scala:70-116, 724, 815）。名字与 golden 一一相同。
//   L628 §2 派生判断（MSHR.scala:117-262）：请求是什么、snoop 该怎么回
//   L749 §3 四路发请求：何时 valid、发什么（MSHR.scala:264-296, 340-452, 454-988）
//   L1209 §4 状态更新。Chisel 的 when 在同一拍内按书写顺序执行、后写覆盖先写；
//   L1660 §5 状态与信息输出（MSHR.scala:128-130, 1320-1370, 1431）
//   L1727 §6 性能计数与断言影子的组合部分
//   L1782 BEGIN GENERATED(wrapper)
// END GENERATED(nav)
// =============================================================================
package mshr_pkg;
  // ---- TileLink / CHI 编码（只列本模块用到的）----
  // TL A 通道 opcode
  localparam logic [3:0] TL_GET = 4'h4, TL_HINT = 4'h5, TL_ACQUIRE_BLOCK = 4'h6,
                         TL_ACQUIRE_PERM = 4'h7, TL_CBO_CLEAN = 4'hC, TL_CBO_FLUSH = 4'hD,
                         TL_CBO_INVAL = 4'hE;
  // TL C 通道 opcode（sinkC 回来的 ProbeAck 类）
  localparam logic [2:0] TL_PROBE_ACK = 3'h4, TL_PROBE_ACK_DATA = 3'h5, TL_RELEASE_DATA = 3'h7;
  // TL 权限参数：Grant 用 toT/toB/toN；Acquire 用 NtoB/NtoT/BtoT；Release/ProbeAck 用 TtoB..NtoN
  localparam logic [2:0] TL_TOT = 3'h0, TL_TOB = 3'h1, TL_TON = 3'h2;
  localparam logic [2:0] TL_NTOB = 3'h0, TL_NTOT = 3'h1, TL_BTOT = 3'h2;
  localparam logic [2:0] TL_TTOB = 3'h0, TL_TTON = 3'h1, TL_BTON = 3'h2, TL_BTOB = 3'h4, TL_NTON = 3'h5;
  localparam logic [2:0] TL_PREFETCH_WRITE = 3'h1;
  // L2 目录状态（MetaData）：INVALID / BRANCH（上层有共享副本）/ TRUNK（唯一上层持有 T）/ TIP（本层持 T）
  localparam logic [1:0] ST_INVALID = 2'h0, ST_BRANCH = 2'h1, ST_TRUNK = 2'h2, ST_TIP = 2'h3;
  // CHI 缓存状态（resp 字段）：I / SC / UC(=UD) ，bit2 = PassDirty
  localparam logic [2:0] CHI_I = 3'h0, CHI_SC = 3'h1, CHI_UC = 3'h2, CHI_UD = 3'h2;
  // CHI 通道（TaskBundle.txChannel）
  localparam logic [2:0] CH_TXREQ = 3'h1, CH_TXRSP = 3'h2, CH_TXDAT = 3'h4;
  // CHI REQ opcode
  localparam logic [6:0] REQ_READ_UNIQUE = 7'h07, REQ_CLEAN_SHARED = 7'h08, REQ_CLEAN_INVALID = 7'h09,
                         REQ_MAKE_INVALID = 7'h0A, REQ_MAKE_UNIQUE = 7'h0C, REQ_EVICT = 7'h0D,
                         REQ_WRITE_EVICT_FULL = 7'h15, REQ_WRITE_CLEAN_FULL = 7'h17,
                         REQ_WRITE_BACK_FULL = 7'h1B, REQ_READ_NOT_SHARED_DIRTY = 7'h26,
                         REQ_WRITE_EVICT_OR_EVICT = 7'h42;
  // CHI RSP opcode
  localparam logic [6:0] RSP_SNP_RESP = 7'h1, RSP_RETRY_ACK = 7'h3, RSP_COMP = 7'h4,
                         RSP_COMP_DBID_RESP = 7'h5, RSP_SNP_RESP_FWDED = 7'h9, RSP_RESP_SEP_DATA = 7'hB;
  // CHI DAT opcode
  localparam logic [6:0] DAT_SNP_RESP_DATA = 7'h1, DAT_COPY_BACK_WR_DATA = 7'h2, DAT_COMP_DATA = 7'h4,
                         DAT_SNP_RESP_DATA_FWDED = 7'h6, DAT_DATA_SEP_RESP = 7'hB;
  // CHI RespErr
  localparam logic [1:0] RESP_ERR_DERR = 2'h2, RESP_ERR_NDERR = 2'h3;
  // CHI SNP opcode
  localparam logic [6:0] SNP_SHARED = 7'h01, SNP_CLEAN = 7'h02, SNP_ONCE = 7'h03,
                         SNP_NOT_SHARED_DIRTY = 7'h04, SNP_UNIQUE_STASH = 7'h05,
                         SNP_MAKE_INVALID_STASH = 7'h06, SNP_UNIQUE = 7'h07, SNP_CLEAN_SHARED = 7'h08,
                         SNP_CLEAN_INVALID = 7'h09, SNP_MAKE_INVALID = 7'h0A, SNP_STASH_UNIQUE = 7'h0B,
                         SNP_STASH_SHARED = 7'h0C, SNP_QUERY = 7'h10, SNP_SHARED_FWD = 7'h11,
                         SNP_CLEAN_FWD = 7'h12, SNP_ONCE_FWD = 7'h13, SNP_NOT_SHARED_DIRTY_FWD = 7'h14,
                         SNP_PREFER_UNIQUE = 7'h15, SNP_PREFER_UNIQUE_FWD = 7'h16, SNP_UNIQUE_FWD = 7'h17;
  // 重试退避（MSHR.scala:98）：连续 3 次选不到路后，每次要先等 20 拍才能再进 MainPipe
  localparam logic [1:0] BACKOFF_THRESHOLD = 2'd3;
  localparam logic [4:0] BACKOFF_CYCLES    = 5'd20;

  // ---- 目录元数据 MetaEntry（14 位）----
  typedef struct packed {
    logic       dirty;
    logic [1:0] state;
    logic       clients;       // 本配置只有 1 个上层 client
    logic [1:0] alias_f;       // alias 是 SV 保留字，加 _f
    logic       prefetch;
    logic [2:0] prefetchSrc;
    logic       accessed;
    logic       tagErr;
    logic       dataErr;
  } meta_t;

  // ---- 发往 MainPipe 的任务（TaskBundle 中 golden 保留下来的字段，顺序 = golden 端口顺序）----
  typedef struct packed {
    logic [2:0]  channel;
    logic [2:0]  txChannel;
    logic [8:0]  set;
    logic [30:0] tag;
    logic [5:0]  off;
    logic [1:0]  alias_f;
    logic        isKeyword;
    logic [3:0]  opcode;
    logic [2:0]  param;
    logic [2:0]  size;
    logic [6:0]  sourceId;
    logic        denied;
    logic        corrupt;
    logic [7:0]  mshrId;
    logic        aliasTask;
    logic        useProbeData;
    logic        mshrRetry;
    logic        readProbeDataDown;
    logic        fromL2pft;
    logic        dirty;
    logic [2:0]  way;
    meta_t       meta;
    logic        metaWen;
    logic        tagWen;
    logic        dsWen;
    logic        replTask;
    logic        cmoTask;
    logic [4:0]  reqSource;
    logic        mergeA;
    // aMergeTask：Grant 时顺带合并进来的那条 Acquire（其 meta 只剩 5 个字段）
    logic [5:0]  am_off;
    logic [1:0]  am_alias;
    logic [43:0] am_vaddr;
    logic        am_isKeyword;
    logic [2:0]  am_opcode;
    logic [2:0]  am_param;
    logic [6:0]  am_sourceId;
    logic        am_meta_dirty;
    logic [1:0]  am_meta_state;
    logic        am_meta_clients;
    logic [1:0]  am_meta_alias;
    logic        am_meta_accessed;
    logic        snpHitRelease;
    logic        snpHitReleaseToInval;
    logic        snpHitReleaseToClean;
    logic        snpHitReleaseWithData;
    logic [7:0]  snpHitReleaseIdx;
    meta_t       snpHitReleaseMeta;
    // CHI 字段
    logic [10:0] tgtID;
    logic [11:0] txnID;
    logic [10:0] homeNID;
    logic [11:0] dbID;
    logic [6:0]  chiOpcode;
    logic [2:0]  resp;
    logic [2:0]  fwdState;
    logic        retToSrc;
    logic        likelyshared;
    logic        expCompAck;
    logic        allowRetry;
    logic        memAttr_allocate;
    logic        memAttr_cacheable;
    logic        memAttr_ewa;
    logic        traceTag;
  } mp_task_t;

  // TL 的 Acquire/Get/Hint/CBO → 回给上层的 D 通道 opcode（CoupledL2.scala odOpGen）
  //   Put*→AccessAck(0)  Arith/Logical/Get→AccessAckData(1)  Hint→HintAck(2)
  //   AcquireBlock→GrantData(5)  AcquirePerm→Grant(4)  CBO*→CBOAck(8)  其余→0
  function automatic logic [3:0] od_op_gen(input logic [3:0] a_opcode);
    case (a_opcode)
      4'h2, 4'h3, 4'h4:    od_op_gen = 4'h1;
      4'h5:                od_op_gen = 4'h2;
      4'h6:                od_op_gen = 4'h5;
      4'h7:                od_op_gen = 4'h4;
      4'hC, 4'hD, 4'hE:    od_op_gen = 4'h8;
      default:             od_op_gen = 4'h0;
    endcase
  endfunction

  // Acquire 的 param 翻成 Grant 的 param（MuxLookup，默认原样）：NtoB→(promoteT?toT:toB)，BtoT/NtoT→toT
  function automatic logic [2:0] grant_param(input logic [2:0] a_param, input logic promote_t);
    case (a_param)
      TL_NTOB:          grant_param = promote_t ? TL_TOT : TL_TOB;
      TL_BTOT, TL_NTOT: grant_param = TL_TOT;
      default:          grant_param = a_param;
    endcase
  endfunction

  // Consts.scala needT：这个请求要不要本层先拿到 T 权限
  function automatic logic need_t(input logic [3:0] opcode, input logic [2:0] param);
    need_t = ~opcode[2]
           | (opcode == TL_HINT && param == TL_PREFETCH_WRITE)
           | ((opcode == TL_ACQUIRE_BLOCK || opcode == TL_ACQUIRE_PERM) && param != TL_NTOB);
  endfunction
endpackage

module xs_MSHR_core
  import mshr_pkg::*;
(
  // BEGIN GENERATED(core_ports) —— scripts/gen_mshr.py 从 golden 端口表生成，勿手改
  input         clock,
  input         reset,
  input  [7:0]  io_id,
  output        io_status_valid,
  output [2:0]  io_status_bits_channel,
  output [8:0]  io_status_bits_set,
  output [30:0] io_status_bits_reqTag,
  output [30:0] io_status_bits_metaTag,
  output        io_status_bits_needsRepl,
  output        io_status_bits_w_c_resp,
  output        io_status_bits_will_free,
  output [4:0]  io_status_bits_reqSource,
  output        io_status_bits_is_miss,
  output        io_status_bits_is_prefetch,
  output        io_statAlloc_valid,
  output [2:0]  io_statAlloc_bits_channel,
  output        io_statAlloc_bits_is_miss,
  output        io_statAlloc_bits_is_prefetch,
  output        io_msInfo_valid,
  output [2:0]  io_msInfo_bits_channel,
  output [8:0]  io_msInfo_bits_set,
  output [2:0]  io_msInfo_bits_way,
  output [30:0] io_msInfo_bits_reqTag,
  output        io_msInfo_bits_willFree,
  output        io_msInfo_bits_aliasTask,
  output        io_msInfo_bits_needRelease,
  output        io_msInfo_bits_blockRefill,
  output        io_msInfo_bits_meta_dirty,
  output [1:0]  io_msInfo_bits_meta_state,
  output        io_msInfo_bits_meta_clients,
  output [1:0]  io_msInfo_bits_meta_alias,
  output        io_msInfo_bits_meta_prefetch,
  output [2:0]  io_msInfo_bits_meta_prefetchSrc,
  output        io_msInfo_bits_meta_accessed,
  output        io_msInfo_bits_meta_tagErr,
  output        io_msInfo_bits_meta_dataErr,
  output [30:0] io_msInfo_bits_metaTag,
  output        io_msInfo_bits_dirHit,
  output        io_msInfo_bits_isAcqOrPrefetch,
  output        io_msInfo_bits_isPrefetch,
  output [2:0]  io_msInfo_bits_param,
  output        io_msInfo_bits_mergeA,
  output        io_msInfo_bits_w_grantfirst,
  output        io_msInfo_bits_s_release,
  output        io_msInfo_bits_s_refill,
  output        io_msInfo_bits_s_cmoresp,
  output        io_msInfo_bits_s_cmometaw,
  output        io_msInfo_bits_w_releaseack,
  output        io_msInfo_bits_w_replResp,
  output        io_msInfo_bits_w_rprobeacklast,
  output        io_msInfo_bits_replaceData,
  output        io_msInfo_bits_releaseToClean,
  input         io_alloc_valid,
  input         io_alloc_bits_dirResult_hit,
  input  [30:0] io_alloc_bits_dirResult_tag,
  input  [8:0]  io_alloc_bits_dirResult_set,
  input  [2:0]  io_alloc_bits_dirResult_way,
  input         io_alloc_bits_dirResult_meta_dirty,
  input  [1:0]  io_alloc_bits_dirResult_meta_state,
  input         io_alloc_bits_dirResult_meta_clients,
  input  [1:0]  io_alloc_bits_dirResult_meta_alias,
  input         io_alloc_bits_dirResult_meta_prefetch,
  input  [2:0]  io_alloc_bits_dirResult_meta_prefetchSrc,
  input         io_alloc_bits_dirResult_meta_accessed,
  input         io_alloc_bits_dirResult_meta_tagErr,
  input         io_alloc_bits_dirResult_meta_dataErr,
  input         io_alloc_bits_dirResult_error,
  input         io_alloc_bits_state_s_acquire,
  input         io_alloc_bits_state_s_rprobe,
  input         io_alloc_bits_state_s_pprobe,
  input         io_alloc_bits_state_s_release,
  input         io_alloc_bits_state_s_probeack,
  input         io_alloc_bits_state_s_refill,
  input         io_alloc_bits_state_s_cmoresp,
  input         io_alloc_bits_state_w_rprobeackfirst,
  input         io_alloc_bits_state_w_rprobeacklast,
  input         io_alloc_bits_state_w_pprobeackfirst,
  input         io_alloc_bits_state_w_pprobeacklast,
  input         io_alloc_bits_state_w_grantfirst,
  input         io_alloc_bits_state_w_grantlast,
  input         io_alloc_bits_state_w_grant,
  input         io_alloc_bits_state_w_releaseack,
  input         io_alloc_bits_state_w_replResp,
  input         io_alloc_bits_state_s_rcompack,
  input         io_alloc_bits_state_s_dct,
  input  [2:0]  io_alloc_bits_task_channel,
  input  [8:0]  io_alloc_bits_task_set,
  input  [30:0] io_alloc_bits_task_tag,
  input  [5:0]  io_alloc_bits_task_off,
  input  [1:0]  io_alloc_bits_task_alias,
  input         io_alloc_bits_task_isKeyword,
  input  [3:0]  io_alloc_bits_task_opcode,
  input  [2:0]  io_alloc_bits_task_param,
  input  [6:0]  io_alloc_bits_task_sourceId,
  input         io_alloc_bits_task_denied,
  input         io_alloc_bits_task_corrupt,
  input         io_alloc_bits_task_aliasTask,
  input         io_alloc_bits_task_fromL2pft,
  input  [4:0]  io_alloc_bits_task_reqSource,
  input         io_alloc_bits_task_snpHitRelease,
  input         io_alloc_bits_task_snpHitReleaseToInval,
  input         io_alloc_bits_task_snpHitReleaseToClean,
  input         io_alloc_bits_task_snpHitReleaseWithData,
  input  [7:0]  io_alloc_bits_task_snpHitReleaseIdx,
  input         io_alloc_bits_task_snpHitReleaseMeta_dirty,
  input  [1:0]  io_alloc_bits_task_snpHitReleaseMeta_state,
  input         io_alloc_bits_task_snpHitReleaseMeta_clients,
  input  [1:0]  io_alloc_bits_task_snpHitReleaseMeta_alias,
  input         io_alloc_bits_task_snpHitReleaseMeta_prefetch,
  input  [2:0]  io_alloc_bits_task_snpHitReleaseMeta_prefetchSrc,
  input         io_alloc_bits_task_snpHitReleaseMeta_accessed,
  input         io_alloc_bits_task_snpHitReleaseMeta_tagErr,
  input         io_alloc_bits_task_snpHitReleaseMeta_dataErr,
  input  [10:0] io_alloc_bits_task_srcID,
  input  [11:0] io_alloc_bits_task_txnID,
  input  [10:0] io_alloc_bits_task_fwdNID,
  input  [11:0] io_alloc_bits_task_fwdTxnID,
  input  [6:0]  io_alloc_bits_task_chiOpcode,
  input         io_alloc_bits_task_retToSrc,
  input         io_alloc_bits_task_traceTag,
  input         io_tasks_txreq_ready,
  output        io_tasks_txreq_valid,
  output [10:0] io_tasks_txreq_bits_tgtID,
  output [11:0] io_tasks_txreq_bits_txnID,
  output [6:0]  io_tasks_txreq_bits_opcode,
  output [47:0] io_tasks_txreq_bits_addr,
  output        io_tasks_txreq_bits_likelyshared,
  output        io_tasks_txreq_bits_allowRetry,
  output [3:0]  io_tasks_txreq_bits_pCrdType,
  output        io_tasks_txreq_bits_memAttr_allocate,
  output        io_tasks_txreq_bits_expCompAck,
  input         io_tasks_txrsp_ready,
  output        io_tasks_txrsp_valid,
  output [10:0] io_tasks_txrsp_bits_tgtID,
  output [11:0] io_tasks_txrsp_bits_txnID,
  output        io_tasks_txrsp_bits_traceTag,
  input         io_tasks_source_b_ready,
  output        io_tasks_source_b_valid,
  output [30:0] io_tasks_source_b_bits_tag,
  output [8:0]  io_tasks_source_b_bits_set,
  output [1:0]  io_tasks_source_b_bits_param,
  output [1:0]  io_tasks_source_b_bits_alias,
  input         io_tasks_mainpipe_ready,
  output        io_tasks_mainpipe_valid,
  output [2:0]  io_tasks_mainpipe_bits_channel,
  output [2:0]  io_tasks_mainpipe_bits_txChannel,
  output [8:0]  io_tasks_mainpipe_bits_set,
  output [30:0] io_tasks_mainpipe_bits_tag,
  output [5:0]  io_tasks_mainpipe_bits_off,
  output [1:0]  io_tasks_mainpipe_bits_alias,
  output        io_tasks_mainpipe_bits_isKeyword,
  output [3:0]  io_tasks_mainpipe_bits_opcode,
  output [2:0]  io_tasks_mainpipe_bits_param,
  output [2:0]  io_tasks_mainpipe_bits_size,
  output [6:0]  io_tasks_mainpipe_bits_sourceId,
  output        io_tasks_mainpipe_bits_denied,
  output        io_tasks_mainpipe_bits_corrupt,
  output [7:0]  io_tasks_mainpipe_bits_mshrId,
  output        io_tasks_mainpipe_bits_aliasTask,
  output        io_tasks_mainpipe_bits_useProbeData,
  output        io_tasks_mainpipe_bits_mshrRetry,
  output        io_tasks_mainpipe_bits_readProbeDataDown,
  output        io_tasks_mainpipe_bits_fromL2pft,
  output        io_tasks_mainpipe_bits_dirty,
  output [2:0]  io_tasks_mainpipe_bits_way,
  output        io_tasks_mainpipe_bits_meta_dirty,
  output [1:0]  io_tasks_mainpipe_bits_meta_state,
  output        io_tasks_mainpipe_bits_meta_clients,
  output [1:0]  io_tasks_mainpipe_bits_meta_alias,
  output        io_tasks_mainpipe_bits_meta_prefetch,
  output [2:0]  io_tasks_mainpipe_bits_meta_prefetchSrc,
  output        io_tasks_mainpipe_bits_meta_accessed,
  output        io_tasks_mainpipe_bits_meta_tagErr,
  output        io_tasks_mainpipe_bits_meta_dataErr,
  output        io_tasks_mainpipe_bits_metaWen,
  output        io_tasks_mainpipe_bits_tagWen,
  output        io_tasks_mainpipe_bits_dsWen,
  output        io_tasks_mainpipe_bits_replTask,
  output        io_tasks_mainpipe_bits_cmoTask,
  output [4:0]  io_tasks_mainpipe_bits_reqSource,
  output        io_tasks_mainpipe_bits_mergeA,
  output [5:0]  io_tasks_mainpipe_bits_aMergeTask_off,
  output [1:0]  io_tasks_mainpipe_bits_aMergeTask_alias,
  output [43:0] io_tasks_mainpipe_bits_aMergeTask_vaddr,
  output        io_tasks_mainpipe_bits_aMergeTask_isKeyword,
  output [2:0]  io_tasks_mainpipe_bits_aMergeTask_opcode,
  output [2:0]  io_tasks_mainpipe_bits_aMergeTask_param,
  output [6:0]  io_tasks_mainpipe_bits_aMergeTask_sourceId,
  output        io_tasks_mainpipe_bits_aMergeTask_meta_dirty,
  output [1:0]  io_tasks_mainpipe_bits_aMergeTask_meta_state,
  output        io_tasks_mainpipe_bits_aMergeTask_meta_clients,
  output [1:0]  io_tasks_mainpipe_bits_aMergeTask_meta_alias,
  output        io_tasks_mainpipe_bits_aMergeTask_meta_accessed,
  output        io_tasks_mainpipe_bits_snpHitRelease,
  output        io_tasks_mainpipe_bits_snpHitReleaseToInval,
  output        io_tasks_mainpipe_bits_snpHitReleaseToClean,
  output        io_tasks_mainpipe_bits_snpHitReleaseWithData,
  output [7:0]  io_tasks_mainpipe_bits_snpHitReleaseIdx,
  output        io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty,
  output [1:0]  io_tasks_mainpipe_bits_snpHitReleaseMeta_state,
  output        io_tasks_mainpipe_bits_snpHitReleaseMeta_clients,
  output [1:0]  io_tasks_mainpipe_bits_snpHitReleaseMeta_alias,
  output        io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch,
  output [2:0]  io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc,
  output        io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed,
  output        io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr,
  output        io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr,
  output [10:0] io_tasks_mainpipe_bits_tgtID,
  output [11:0] io_tasks_mainpipe_bits_txnID,
  output [10:0] io_tasks_mainpipe_bits_homeNID,
  output [11:0] io_tasks_mainpipe_bits_dbID,
  output [6:0]  io_tasks_mainpipe_bits_chiOpcode,
  output [2:0]  io_tasks_mainpipe_bits_resp,
  output [2:0]  io_tasks_mainpipe_bits_fwdState,
  output        io_tasks_mainpipe_bits_retToSrc,
  output        io_tasks_mainpipe_bits_likelyshared,
  output        io_tasks_mainpipe_bits_expCompAck,
  output        io_tasks_mainpipe_bits_allowRetry,
  output        io_tasks_mainpipe_bits_memAttr_allocate,
  output        io_tasks_mainpipe_bits_memAttr_cacheable,
  output        io_tasks_mainpipe_bits_memAttr_ewa,
  output        io_tasks_mainpipe_bits_traceTag,
  input         io_resps_sinkC_valid,
  input  [2:0]  io_resps_sinkC_bits_opcode,
  input  [2:0]  io_resps_sinkC_bits_param,
  input         io_resps_sinkC_bits_last,
  input         io_resps_sinkC_bits_denied,
  input         io_resps_sinkC_bits_corrupt,
  input         io_resps_rxrsp_valid,
  input  [6:0]  io_resps_rxrsp_bits_chiOpcode,
  input  [10:0] io_resps_rxrsp_bits_srcID,
  input  [11:0] io_resps_rxrsp_bits_dbID,
  input  [2:0]  io_resps_rxrsp_bits_resp,
  input  [3:0]  io_resps_rxrsp_bits_pCrdType,
  input  [1:0]  io_resps_rxrsp_bits_respErr,
  input         io_resps_rxrsp_bits_traceTag,
  input         io_resps_rxdat_valid,
  input         io_resps_rxdat_bits_corrupt,
  input  [6:0]  io_resps_rxdat_bits_chiOpcode,
  input  [10:0] io_resps_rxdat_bits_homeNID,
  input  [11:0] io_resps_rxdat_bits_dbID,
  input  [2:0]  io_resps_rxdat_bits_resp,
  input  [1:0]  io_resps_rxdat_bits_respErr,
  input         io_resps_rxdat_bits_traceTag,
  input  [8:0]  io_nestedwb_set,
  input  [30:0] io_nestedwb_tag,
  input         io_nestedwb_c_set_dirty,
  input         io_nestedwb_c_set_tip,
  input         io_nestedwb_b_inv_dirty,
  input         io_nestedwb_b_toB,
  input         io_nestedwb_b_toN,
  input         io_nestedwb_b_toClean,
  input         io_nestedwb_denied,
  input         io_nestedwb_corrupt,
  output        io_nestedwbData,
  input         io_aMergeTask_valid,
  input  [5:0]  io_aMergeTask_bits_off,
  input  [1:0]  io_aMergeTask_bits_alias,
  input  [43:0] io_aMergeTask_bits_vaddr,
  input         io_aMergeTask_bits_isKeyword,
  input  [3:0]  io_aMergeTask_bits_opcode,
  input  [2:0]  io_aMergeTask_bits_param,
  input  [6:0]  io_aMergeTask_bits_sourceId,
  input         io_replResp_valid,
  input  [30:0] io_replResp_bits_tag,
  input  [2:0]  io_replResp_bits_way,
  input         io_replResp_bits_meta_dirty,
  input  [1:0]  io_replResp_bits_meta_state,
  input         io_replResp_bits_meta_clients,
  input  [1:0]  io_replResp_bits_meta_alias,
  input         io_replResp_bits_meta_prefetch,
  input  [2:0]  io_replResp_bits_meta_prefetchSrc,
  input         io_replResp_bits_meta_accessed,
  input         io_replResp_bits_meta_tagErr,
  input         io_replResp_bits_meta_dataErr,
  input         io_replResp_bits_retry,
  input         io_replResp_bits_error,
  output        io_pCrd_query_valid,
  output [3:0]  io_pCrd_query_bits_pCrdType,
  output [10:0] io_pCrd_query_bits_srcID,
  input         io_pCrd_grant,
  input         io_dsResp_valid,
  input         io_dsResp_bits_dataError,
  output        acquire_period_valid,
  output [63:0] acquire_period_bits,
  output        release_period_valid,
  output [63:0] release_period_bits
  // END GENERATED(core_ports)
);

  // ===========================================================================
  // §1 寄存器（MSHR.scala:70-116, 724, 815）。名字与 golden 一一相同。
  // ===========================================================================
  // ---- 事务身份：本 MSHR 是否在用 + 请求本身（TaskBundle）----
  logic        req_valid;
  logic [2:0]  req_channel;             // bit0 = 来自 A 通道（fromA）
  logic [8:0]  req_set;
  logic [30:0] req_tag;
  logic [5:0]  req_off;
  logic [1:0]  req_alias;
  logic        req_isKeyword;
  logic [3:0]  req_opcode;              // TL A opcode（snoop 时无意义）
  logic [2:0]  req_param;
  logic [6:0]  req_sourceId;
  logic        req_aliasTask;
  logic        req_fromL2pft;
  logic [4:0]  req_reqSource;
  logic        req_snpHitRelease;       // snoop 撞上了一个正在写回的 Release（嵌套）
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
  logic [10:0] req_srcID;               // snoop 的来源（回 SnpResp 的目标）
  logic [11:0] req_txnID;
  logic [10:0] req_fwdNID;              // DCT：数据直接转发给谁
  logic [11:0] req_fwdTxnID;
  logic [6:0]  req_chiOpcode;           // snoop 的 CHI opcode
  logic        req_retToSrc;
  logic        req_traceTag;

  // ---- 目录结果 dirResult（分配时来自 MainPipe，之后被 replacer / 嵌套写回改写）----
  logic        dirResult_hit;
  logic [30:0] dirResult_tag;           // 命中/替换那一路的 tag（写回用）
  logic [8:0]  dirResult_set;
  logic [2:0]  dirResult_way;
  logic        dirResult_meta_dirty;
  logic [1:0]  dirResult_meta_state;
  logic        dirResult_meta_clients;
  logic [1:0]  dirResult_meta_alias;
  logic        dirResult_meta_prefetch;
  logic [2:0]  dirResult_meta_prefetchSrc;
  logic        dirResult_meta_accessed;
  logic        dirResult_meta_tagErr;
  logic        dirResult_meta_dataErr;

  // ---- 状态标志（见文件头；复位全 1 = 空闲）----
  logic state_s_acquire, state_s_rprobe, state_s_pprobe, state_s_release, state_s_probeack;
  logic state_s_refill, state_s_retry, state_s_cmoresp, state_s_cmometaw;
  logic state_w_rprobeackfirst, state_w_rprobeacklast, state_w_pprobeackfirst, state_w_pprobeacklast;
  logic state_w_grantfirst, state_w_grantlast, state_w_grant, state_w_releaseack, state_w_replResp;
  logic state_s_rcompack, state_s_wcompack, state_s_cbwrdata, state_s_reissue, state_s_dct;

  // ---- 事务过程中收集到的事实 ----
  logic        gotT;                    // 下游给了 UC/UD（L3 可能给 T 即使只要 B）
  logic        gotDirty;                // 下游给了 UD_PD
  logic        gotGrantData;            // 收到过 CompData / DataSepResp
  logic        probeDirty;              // Probe 拿回了脏数据（ProbeAckData）
  logic        releaseDirty;            // 嵌套 Release 带来了脏数据
  logic        beatCnt;                 // DataSepResp 的拍计数（2 拍）
  logic [6:0]  req_released_chiOpcode;  // 第一次写回用的 CHI opcode（重发时照用）
  logic        req_released_likelyShared;
  logic [1:0]  retryTimes;              // replacer 连续要求重试的次数（饱和于 3）
  logic [4:0]  backoffTimer;            // 退避计时（0..20）
  logic [10:0] tgtid_rcompack;          // 读事务 CompAck 的 TgtID / TxnID（无复位）
  logic [11:0] txnid_rcompack;
  logic [10:0] tgtid_wcompack;          // 写事务 CopyBackWrData / CompAck 的 TgtID / TxnID（无复位）
  logic [11:0] txnid_wcompack;
  logic [10:0] srcid_retryack;          // RetryAck 的 SrcID：PCrd 查询与重发目标（无复位）
  logic [3:0]  pcrdtype;
  logic        gotRetryAck;
  logic        gotPCrdGrant;
  logic        tagErr;                  // 分配时目录就报了 tag 错
  logic        denied;
  logic        corrupt;
  logic        cbWrDataTraceTag;
  logic        mergeA;                  // 有一条同地址 Acquire 合并进来了
  logic [5:0]  mp_grant_task_merge_task_r_off;       // 合并进来的 Acquire（RegEnable 保存）
  logic [1:0]  mp_grant_task_merge_task_r_alias;
  logic [43:0] mp_grant_task_merge_task_r_vaddr;
  logic        mp_grant_task_merge_task_r_isKeyword;
  logic [3:0]  mp_grant_task_merge_task_r_opcode;
  logic [2:0]  mp_grant_task_merge_task_r_param;
  logic [6:0]  mp_grant_task_merge_task_r_sourceId;
  logic        io_msInfo_bits_blockRefill_REG;       // RegNext(releaseNotSent)
  logic        io_msInfo_bits_blockRefill_REG_1;     // RegNext(RegNext(..)) 的第一级（与上一个同源）
  logic        io_msInfo_bits_blockRefill_REG_2;     //                      的第二级
  logic [63:0] timer;                   // 分配以来的拍数（性能统计用）
  logic [63:0] acquire_ts, release_ts;  // 发出 Acquire / Release 时的 timer（无复位）
  logic        acquire_period_valid_REG, release_period_valid_REG;  // 完成标志打一拍（无复位）
  // 断言专用影子（综合视图里没有读者，golden 保留，照写）
  logic [63:0] validCnt;                // 死锁检测：占用拍数
  logic        REG;                     // RegNext(evictFire)
  logic        REG_1;                   // RegNext(wbFire)
  logic        REG_2;                   // RegNext(wcFire)
  logic        REG_3;                   // RegNext(weFire)

  // 读起来方便的别名
  meta_t meta;
  assign meta = '{dirty: dirResult_meta_dirty, state: dirResult_meta_state,
                  clients: dirResult_meta_clients, alias_f: dirResult_meta_alias,
                  prefetch: dirResult_meta_prefetch, prefetchSrc: dirResult_meta_prefetchSrc,
                  accessed: dirResult_meta_accessed, tagErr: dirResult_meta_tagErr,
                  dataErr: dirResult_meta_dataErr};
  meta_t snp_hit_release_meta;
  assign snp_hit_release_meta = '{dirty: req_snpHitReleaseMeta_dirty,
                                  state: req_snpHitReleaseMeta_state,
                                  clients: req_snpHitReleaseMeta_clients,
                                  alias_f: req_snpHitReleaseMeta_alias,
                                  prefetch: req_snpHitReleaseMeta_prefetch,
                                  prefetchSrc: req_snpHitReleaseMeta_prefetchSrc,
                                  accessed: req_snpHitReleaseMeta_accessed,
                                  tagErr: req_snpHitReleaseMeta_tagErr,
                                  dataErr: req_snpHitReleaseMeta_dataErr};
  logic req_fromA;
  assign req_fromA = req_channel[0];
  logic meta_isT;                       // isT(meta.state)：TRUNK 或 TIP
  assign meta_isT = dirResult_meta_state[1];

  // ===========================================================================
  // §2 派生判断（MSHR.scala:117-262）：请求是什么、snoop 该怎么回
  // ===========================================================================
  // ---- 目录状态翻成 CHI 状态：{dirty,state} → I / SC / UC / UD ----
  logic [2:0] metaChi;
  always_comb begin
    case ({dirResult_meta_dirty, dirResult_meta_state})
      {1'b0, ST_BRANCH}:              metaChi = CHI_SC;
      {1'b0, ST_TRUNK}, {1'b0, ST_TIP},
      {1'b1, ST_TRUNK}, {1'b1, ST_TIP}: metaChi = CHI_UC;   // UD 与 UC 同编码
      default:                        metaChi = CHI_I;
    endcase
  end

  // ---- 请求类型 ----
  logic req_needT, req_needB, req_acquire, req_acquirePerm, req_get, req_prefetch, req_mayRepl;
  logic req_cboClean, req_cboFlush, req_cboInval, cmo_cbo;
  assign req_needT       = need_t(req_opcode, req_param);
  assign req_needB       = req_opcode == TL_GET
                         | (req_opcode == TL_ACQUIRE_BLOCK && req_param == TL_NTOB)
                         | (req_opcode == TL_HINT && req_param == 3'h0);
  assign req_acquire     = (req_opcode == TL_ACQUIRE_BLOCK && req_fromA) | req_opcode == TL_ACQUIRE_PERM;
  assign req_acquirePerm = req_opcode == TL_ACQUIRE_PERM;
  assign req_get         = req_opcode == TL_GET;
  assign req_prefetch    = req_opcode == TL_HINT;
  assign req_mayRepl     = req_acquire | req_get | req_prefetch;
  assign req_cboClean    = req_fromA && req_opcode == TL_CBO_CLEAN;
  assign req_cboFlush    = req_fromA && req_opcode == TL_CBO_FLUSH;
  assign req_cboInval    = req_fromA && req_opcode == TL_CBO_INVAL;
  assign cmo_cbo         = req_cboClean | req_cboFlush | req_cboInval;

  // ---- snoop 分类（chi/Opcode.scala 的 isSnp*）----
  logic [6:0] snp;
  assign snp = req_chiOpcode;
  logic snpToN, snpToB, snpToBFwd, snpToNFwd, snpToBNonFwd, snpToNNonFwd;
  logic snpOnce, snpOnceFwd, snpOnceX, snpXFwd, snpStashX, snpQuery, snpCleanShared;
  assign snpToN        = snp == SNP_UNIQUE || snp == SNP_UNIQUE_FWD || snp == SNP_UNIQUE_STASH
                       || snp == SNP_PREFER_UNIQUE || snp == SNP_PREFER_UNIQUE_FWD
                       || snp == SNP_CLEAN_INVALID || snp == SNP_MAKE_INVALID
                       || snp == SNP_MAKE_INVALID_STASH;
  assign snpToB        = snp == SNP_CLEAN || snp == SNP_CLEAN_FWD || snp == SNP_SHARED
                       || snp == SNP_SHARED_FWD || snp == SNP_NOT_SHARED_DIRTY
                       || snp == SNP_NOT_SHARED_DIRTY_FWD;
  assign snpToBNonFwd  = snp == SNP_CLEAN || snp == SNP_NOT_SHARED_DIRTY || snp == SNP_SHARED;
  assign snpToBFwd     = snp == SNP_CLEAN_FWD || snp == SNP_NOT_SHARED_DIRTY_FWD || snp == SNP_SHARED_FWD;
  assign snpToNNonFwd  = snp == SNP_UNIQUE || snp == SNP_UNIQUE_STASH || snp == SNP_PREFER_UNIQUE;
  assign snpToNFwd     = snp == SNP_UNIQUE_FWD || snp == SNP_PREFER_UNIQUE_FWD;
  assign snpOnce       = snp == SNP_ONCE;
  assign snpOnceFwd    = snp == SNP_ONCE_FWD;
  assign snpOnceX      = snpOnce | snpOnceFwd;
  assign snpXFwd       = snp == SNP_SHARED_FWD || snp == SNP_CLEAN_FWD || snp == SNP_ONCE_FWD
                       || snp == SNP_NOT_SHARED_DIRTY_FWD || snp == SNP_UNIQUE_FWD
                       || snp == SNP_PREFER_UNIQUE_FWD;
  assign snpStashX     = snp == SNP_STASH_UNIQUE || snp == SNP_STASH_SHARED;
  assign snpQuery      = snp == SNP_QUERY;
  assign snpCleanShared = snp == SNP_CLEAN_SHARED;

  // ---- 命中脏 / 嵌套写回的几种情形 ----
  logic hitDirty, hitWriteBack, hitWriteClean, hitWriteEvict, hitWriteX, hitWriteDirty, hitDirtyOrWriteDirty;
  assign hitDirty      = dirResult_hit && dirResult_meta_dirty;
  assign hitWriteBack  = req_snpHitRelease && req_snpHitReleaseWithData && req_snpHitReleaseMeta_dirty
                       && req_snpHitReleaseToInval;
  assign hitWriteClean = req_snpHitRelease && req_snpHitReleaseWithData && req_snpHitReleaseMeta_dirty
                       && req_snpHitReleaseToClean;
  assign hitWriteEvict = req_snpHitRelease && req_snpHitReleaseWithData && !req_snpHitReleaseMeta_dirty;
  assign hitWriteX     = hitWriteBack | hitWriteClean | hitWriteEvict;
  assign hitWriteDirty = hitWriteBack | hitWriteClean;
  assign hitDirtyOrWriteDirty = hitDirty | hitWriteDirty;

  // ---- snoop 要不要带数据回（SnpRespData*）—— 四种情形（Scala 注释 196-205）----
  logic doRespData_dirty, doRespData_retToSrc_fwd, doRespData_retToSrc_nonFwd, doRespData_once, doRespData;
  assign doRespData_dirty = hitDirtyOrWriteDirty
                          && (snpOnce || snpToB || snp == SNP_UNIQUE || snp == SNP_UNIQUE_STASH
                              || snpCleanShared || snp == SNP_CLEAN_INVALID || snp == SNP_PREFER_UNIQUE);
  assign doRespData_retToSrc_fwd    = req_retToSrc && snpToBFwd;
  assign doRespData_retToSrc_nonFwd = req_retToSrc && dirResult_hit && dirResult_meta_state == ST_BRANCH
                                    && (snpToBNonFwd || snpToNNonFwd || snpOnce);
  assign doRespData_once  = (hitWriteDirty && snpOnceFwd)
                          || ((dirResult_hit && !dirResult_meta_dirty && dirResult_meta_state != ST_BRANCH
                               || hitWriteEvict) && snpOnce);
  assign doRespData = (doRespData_dirty || doRespData_retToSrc_fwd || doRespData_retToSrc_nonFwd
                       || doRespData_once) && !tagErr;

  // ---- snoop 要不要回 *Fwded（DCT 转发给请求者）----
  logic doFwd, doFwdHitRelease;
  assign doFwd           = snpXFwd && dirResult_hit;
  assign doFwdHitRelease = snpXFwd && hitWriteX;

  // ---- 给上层 T 权限（即使它只要 B）的三种情形 ----
  logic promoteT_normal, promoteT_L3, promoteT_alias, req_promoteT;
  assign promoteT_normal = dirResult_hit && !dirResult_meta_clients && dirResult_meta_state == ST_TIP;
  assign promoteT_L3     = !dirResult_hit && gotT;
  assign promoteT_alias  = dirResult_hit && req_aliasTask
                         && (dirResult_meta_state == ST_TRUNK || dirResult_meta_state == ST_TIP);
  assign req_promoteT    = (req_acquire || req_get || req_prefetch)
                         && (promoteT_normal || promoteT_L3 || promoteT_alias);

  // ---- snoop 回复的缓存状态 resp / fwdState 及 PassDirty（MSHR.scala:311-338）----
  logic [2:0] respCacheState, fwdCacheState;
  logic       respPassDirty, fwdPassDirty;
  always_comb begin  // ParallelPriorityMux：第一个成立的赢；都不成立时取最后一项的值
    if (snpToN || tagErr)
      respCacheState = CHI_I;
    else if (snpToB)
      respCacheState = req_snpHitReleaseToInval ? CHI_I : CHI_SC;
    else if (snpOnceX)
      respCacheState = req_snpHitReleaseToInval ? CHI_I
                     : req_snpHitReleaseToClean ? (req_snpHitReleaseMeta_dirty ? CHI_SC : metaChi)
                     : (dirResult_meta_dirty ? CHI_UD : metaChi);
    else if (snpStashX || snpQuery)
      respCacheState = dirResult_meta_dirty ? CHI_UD : metaChi;
    else
      respCacheState = meta_isT ? CHI_UC : metaChi;          // SnpCleanShared（兼缺省）
  end
  assign respPassDirty = hitDirtyOrWriteDirty && !tagErr
                         && (snpToB || snp == SNP_UNIQUE || snp == SNP_UNIQUE_STASH || snpCleanShared
                             || snp == SNP_CLEAN_INVALID || snp == SNP_PREFER_UNIQUE)
                       || hitWriteDirty && snpOnceFwd;
  assign fwdCacheState = tagErr ? CHI_I : snpToBFwd ? CHI_SC : snpToNFwd ? CHI_UC : CHI_I;
  assign fwdPassDirty  = snpToNFwd && hitDirtyOrWriteDirty && !tagErr;

  // ===========================================================================
  // §3 四路发请求：何时 valid、发什么（MSHR.scala:264-296, 340-452, 454-988）
  // ===========================================================================
  // ---- 何时该发 ----
  logic release_valid1_cmo, release_valid1, release_valid2;
  // 第一次写回（AllowRetry=1）经 MainPipe（要读 DS）；被 Retry 后的第二次直接走 TXREQ
  assign release_valid1_cmo = !state_s_release && state_w_rprobeacklast && cmo_cbo;
  assign release_valid1 = !state_s_release && state_w_rprobeacklast && state_w_grantlast && state_w_grant
                          && state_w_replResp || release_valid1_cmo;
  assign release_valid2 = !state_s_reissue && !state_w_releaseack && gotRetryAck && gotPCrdGrant;

  logic rcompack_valid, wcompack_valid;
  assign rcompack_valid = !state_s_rcompack && state_w_grant && state_w_grantfirst;  // Issue C 起首拍即可回
  assign wcompack_valid = !state_s_wcompack && state_s_rcompack;                    // 写 CompAck 排在读之后

  logic mp_release_valid, mp_cbwrdata_valid, mp_probeack_valid, pending_grant_valid, mp_grant_valid;
  logic mp_dct_valid, mp_cmometaw_valid;
  assign mp_release_valid   = release_valid1;
  assign mp_cbwrdata_valid  = !state_s_cbwrdata && state_w_releaseack;
  assign mp_probeack_valid  = !state_s_probeack && state_w_pprobeacklast;
  assign pending_grant_valid = (!state_s_refill || (!state_s_cmoresp && state_w_releaseack && state_s_cbwrdata))
                               && state_w_grantlast && state_w_grant && state_w_rprobeacklast;
  assign mp_grant_valid     = pending_grant_valid
                              && (retryTimes < BACKOFF_THRESHOLD || backoffTimer == BACKOFF_CYCLES);
  assign mp_dct_valid       = !state_s_dct && state_s_probeack;
  assign mp_cmometaw_valid  = !state_s_cmometaw;

  assign io_tasks_txreq_valid = !state_s_acquire
                                  && !(cmo_cbo && (!state_w_rprobeacklast || !state_w_releaseack
                                                   || !state_s_cmometaw || !state_s_cbwrdata))
                              || !state_s_reissue && !state_w_grant && gotRetryAck && gotPCrdGrant
                              || release_valid2;
  assign io_tasks_txrsp_valid    = rcompack_valid || wcompack_valid;
  assign io_tasks_source_b_valid = !state_s_pprobe || !state_s_rprobe;
  assign io_tasks_mainpipe_valid = mp_release_valid || mp_probeack_valid || mp_grant_valid
                                   || mp_cbwrdata_valid || mp_dct_valid || mp_cmometaw_valid;

  logic txreq_fire, txrsp_fire, source_b_fire, mainpipe_fire;
  assign txreq_fire    = io_tasks_txreq_ready & io_tasks_txreq_valid;
  assign txrsp_fire    = io_tasks_txrsp_ready & io_tasks_txrsp_valid;
  assign source_b_fire = io_tasks_source_b_ready & io_tasks_source_b_valid;
  assign mainpipe_fire = io_tasks_mainpipe_ready & io_tasks_mainpipe_valid;

  // ---- 写回用哪个 CHI 命令（MSHR.scala:356-363）----
  logic isWriteCleanFull, isWriteBackFull, isWriteEvictFull, isWriteEvictOrEvict, isEvict;
  assign isWriteCleanFull    = req_cboClean;
  assign isWriteBackFull     = !req_cboClean && !req_cboInval && meta_isT && dirResult_meta_dirty;
  assign isWriteEvictFull    = 1'b0;
  assign isWriteEvictOrEvict = !req_cboFlush && !req_cboInval && !isWriteCleanFull && !isWriteBackFull
                               && !isWriteEvictFull;
  assign isEvict             = !isWriteCleanFull && !isWriteBackFull && !isWriteEvictFull
                               && !isWriteEvictOrEvict;

  // ---- TXRSP：CompAck ----
  assign io_tasks_txrsp_bits_tgtID    = wcompack_valid ? tgtid_wcompack : tgtid_rcompack;
  assign io_tasks_txrsp_bits_txnID    = wcompack_valid ? txnid_wcompack : txnid_rcompack;
  assign io_tasks_txrsp_bits_traceTag = req_traceTag;

  // ---- TXREQ：Acquire 类读请求，或被 Retry 后重发的写回 ----
  //   TL → CHI：Get/AcquireBlock NtoB/PrefetchRead → ReadNotSharedDirty；
  //             AcquireBlock NtoT/PrefetchWrite → ReadUnique；AcquirePerm → MakeUnique；
  //             CBO clean/flush/inval → CleanShared/CleanInvalid/MakeInvalid
  logic [6:0] txreq_opcode;
  always_comb begin
    if (release_valid2)       txreq_opcode = req_released_chiOpcode;
    else if (req_cboClean)    txreq_opcode = REQ_CLEAN_SHARED;
    else if (req_cboFlush)    txreq_opcode = REQ_CLEAN_INVALID;
    else if (req_cboInval)    txreq_opcode = REQ_MAKE_INVALID;
    else if (req_acquirePerm) txreq_opcode = REQ_MAKE_UNIQUE;
    else if (req_needT)       txreq_opcode = REQ_READ_UNIQUE;
    else                      txreq_opcode = REQ_READ_NOT_SHARED_DIRTY;   // needB（兼缺省）
  end
  assign io_tasks_txreq_bits_opcode = txreq_opcode;
  assign io_tasks_txreq_bits_tgtID  = !state_s_reissue ? srcid_retryack : 11'h0;
  assign io_tasks_txreq_bits_txnID  = {4'h0, io_id};
  assign io_tasks_txreq_bits_addr   = {2'h0, release_valid2 ? dirResult_tag : req_tag, req_set, 6'h0};
  assign io_tasks_txreq_bits_likelyshared = release_valid2 ? req_released_likelyShared : 1'b0;
  assign io_tasks_txreq_bits_allowRetry   = state_s_reissue;
  assign io_tasks_txreq_bits_pCrdType     = !state_s_reissue ? pcrdtype : 4'h0;
  assign io_tasks_txreq_bits_expCompAck   = release_valid2
                                            ? req_released_chiOpcode == REQ_WRITE_EVICT_OR_EVICT
                                            : !cmo_cbo;
  assign io_tasks_txreq_bits_memAttr_allocate = !release_valid2 || !isEvict && !cmo_cbo;
  // （qos / size / cacheable / ewa / snpAttr 为常量，端口被 firtool 删掉，常量在 FastArbiter_3 里补回）

  // ---- SourceB：向上层 Probe ----
  assign io_tasks_source_b_bits_tag   = dirResult_tag;
  assign io_tasks_source_b_bits_set   = dirResult_set;
  assign io_tasks_source_b_bits_alias = dirResult_meta_alias;
  assign io_tasks_source_b_bits_param =
      !state_s_pprobe ? (snpToB ? TL_TOB[1:0] : snpToN ? TL_TON[1:0] : TL_TOT[1:0])      // snoop 引起
    : ((req_get || req_cboClean) && dirResult_hit && dirResult_meta_state == ST_TRUNK)       // 替换引起：
      ? TL_TOB[1:0] : TL_TON[1:0];                    // Get/cbo.clean 命中 TRUNK 只需降到 B

  // ---- MainPipe：六种任务各拼一份，再按优先级选一份 ----
  mp_task_t mp_release, mp_cbwrdata, mp_probeack, mp_grant, mp_dct, mp_cmometaw, mp_sel;
  meta_t    meta_zero;
  assign meta_zero = '0;

  // (a) 写回：替换出去的那一路（Release），或 CMO 的写回（MSHR.scala:455-562）
  always_comb begin
    mp_release = '0;
    mp_release.channel   = req_channel;
    mp_release.txChannel = CH_TXREQ;
    mp_release.tag       = dirResult_tag;
    mp_release.set       = req_set;
    mp_release.param     = meta_isT ? TL_TTON : TL_BTON;
    mp_release.size      = 3'h6;
    mp_release.mshrId    = io_id;
    mp_release.way       = dirResult_way;
    mp_release.meta      = meta_zero;
    mp_release.dsWen     = !req_acquirePerm;   // 把 refill 数据写进 DS
    mp_release.replTask  = 1'b1;
    mp_release.cmoTask   = cmo_cbo;
    mp_release.denied    = denied;
    mp_release.corrupt   = corrupt;
    mp_release.txnID     = {4'h0, io_id};
    if (isWriteBackFull)          mp_release.chiOpcode = REQ_WRITE_BACK_FULL;
    else if (isWriteEvictFull)    mp_release.chiOpcode = REQ_WRITE_EVICT_FULL;
    else if (isWriteEvictOrEvict) mp_release.chiOpcode = REQ_WRITE_EVICT_OR_EVICT;
    else                          mp_release.chiOpcode = REQ_EVICT;
    mp_release.retToSrc     = req_retToSrc;
    mp_release.likelyshared = isWriteEvictOrEvict ? dirResult_meta_state == ST_BRANCH : 1'b0;
    mp_release.expCompAck   = isWriteEvictOrEvict;
    mp_release.allowRetry   = state_s_reissue;
    mp_release.memAttr_allocate  = !isEvict;
    mp_release.memAttr_cacheable = 1'b1;
    mp_release.memAttr_ewa       = 1'b1;
    // CMO：数据来自 releaseBuf（ProbeAckData 写进去的），写回后按 cbo 类型改 meta
    if (cmo_cbo) begin
      mp_release.useProbeData = 1'b1;
      if (req_cboClean)      mp_release.readProbeDataDown = 1'b1;
      else if (req_cboFlush) mp_release.readProbeDataDown = isWriteBackFull;
      else                   mp_release.readProbeDataDown = 1'b0;
      if (req_cboClean)      mp_release.param = TL_TTOB;
      else                   mp_release.param = meta_isT ? TL_TTON : TL_BTON;
      mp_release.meta       = req_cboClean ? meta : meta_zero;
      mp_release.meta.dirty = 1'b0;
      // cbo.clean 已把上层 Probe 到 B，所以 TRUNK 要变成 TIP
      mp_release.meta.state = req_cboClean
                              ? (dirResult_meta_state == ST_TRUNK ? ST_TIP : dirResult_meta_state)
                              : ST_INVALID;
      mp_release.metaWen   = 1'b1;
      mp_release.dsWen     = probeDirty;
      mp_release.replTask  = 1'b0;
      if (req_cboClean)      mp_release.chiOpcode = REQ_WRITE_CLEAN_FULL;
      else if (req_cboFlush) mp_release.chiOpcode = isWriteBackFull ? REQ_WRITE_BACK_FULL : REQ_EVICT;
      else                   mp_release.chiOpcode = REQ_EVICT;
      mp_release.likelyshared     = 1'b0;
      mp_release.memAttr_allocate = 1'b0;
    end
  end

  // (b) 写回的数据拍 CopyBackWrData（收到 CompDBIDResp 之后，MSHR.scala:564-618）
  always_comb begin
    mp_cbwrdata = '0;
    mp_cbwrdata.channel   = req_channel;
    mp_cbwrdata.txChannel = CH_TXDAT;
    mp_cbwrdata.tag       = dirResult_tag;
    mp_cbwrdata.set       = req_set;
    mp_cbwrdata.size      = 3'h6;
    mp_cbwrdata.mshrId    = io_id;
    mp_cbwrdata.readProbeDataDown = 1'b1;
    mp_cbwrdata.way       = dirResult_way;
    mp_cbwrdata.cmoTask   = cmo_cbo;
    mp_cbwrdata.denied    = denied;
    mp_cbwrdata.corrupt   = corrupt;
    mp_cbwrdata.tgtID     = tgtid_wcompack;
    mp_cbwrdata.txnID     = txnid_wcompack;
    mp_cbwrdata.chiOpcode = DAT_COPY_BACK_WR_DATA;
    mp_cbwrdata.resp      = metaChi | {dirResult_meta_dirty, 2'b00};   // setPD(metaChi, meta.dirty)
    mp_cbwrdata.retToSrc  = req_retToSrc;
    mp_cbwrdata.traceTag  = cbWrDataTraceTag;
  end

  // (c) 回 snoop：SnpResp / SnpRespData[Fwded]（MSHR.scala:620-721）
  logic probeack_dsWen;
  assign probeack_dsWen = !(snpToN || tagErr) && probeDirty && !releaseDirty;
  always_comb begin
    mp_probeack = '0;
    mp_probeack.channel   = req_channel;
    mp_probeack.txChannel = doRespData ? CH_TXDAT : CH_TXRSP;
    mp_probeack.tag       = req_tag;
    mp_probeack.set       = req_set;
    mp_probeack.off       = req_off;
    mp_probeack.size      = 3'h6;
    mp_probeack.mshrId    = io_id;
    mp_probeack.useProbeData      = 1'b1;
    mp_probeack.readProbeDataDown = doRespData || probeack_dsWen;
    mp_probeack.way       = dirResult_way;
    mp_probeack.dirty     = hitDirty;
    // 清 dirty 的情形：SnpToN / SnpToB / SnpCleanShared / SnpOnce* 嵌套 WriteClean / tagErr
    mp_probeack.meta.dirty = !tagErr
                             && (!(!dirResult_hit || !dirResult_meta_dirty || snpToN || snpToB
                                   || snpCleanShared || snpOnceX && req_snpHitReleaseToClean)
                                 || snpOnceX && probeDirty);
    mp_probeack.meta.state = (snpToN || tagErr) ? ST_INVALID
                           : (snpToB || snpOnceFwd && hitWriteClean) ? ST_BRANCH
                           : dirResult_meta_state;
    mp_probeack.meta.clients  = dirResult_meta_clients & !snpToN;
    mp_probeack.meta.alias_f    = dirResult_meta_alias;
    mp_probeack.meta.prefetch = !snpToN && dirResult_meta_prefetch;
    mp_probeack.meta.accessed = !snpToN && dirResult_meta_accessed;
    mp_probeack.meta.tagErr   = denied;
    mp_probeack.meta.dataErr  = corrupt;
    mp_probeack.metaWen   = !req_snpHitReleaseToInval;
    mp_probeack.dsWen     = probeack_dsWen;
    mp_probeack.cmoTask   = cmo_cbo;
    mp_probeack.denied    = denied;
    mp_probeack.corrupt   = corrupt;
    mp_probeack.tgtID     = req_srcID;
    mp_probeack.txnID     = req_txnID;
    mp_probeack.dbID      = req_txnID;
    case ({doFwd || doFwdHitRelease, doRespData})
      2'b00: mp_probeack.chiOpcode = RSP_SNP_RESP;
      2'b10: mp_probeack.chiOpcode = RSP_SNP_RESP_FWDED;
      2'b01: mp_probeack.chiOpcode = DAT_SNP_RESP_DATA;
      2'b11: mp_probeack.chiOpcode = DAT_SNP_RESP_DATA_FWDED;
    endcase
    mp_probeack.resp      = respCacheState | {respPassDirty, 2'b00};
    mp_probeack.fwdState  = fwdCacheState | {fwdPassDirty, 2'b00};
    mp_probeack.retToSrc  = req_retToSrc;
    mp_probeack.traceTag  = req_traceTag;
    mp_probeack.snpHitRelease         = req_snpHitRelease;
    mp_probeack.snpHitReleaseToInval  = req_snpHitReleaseToInval;
    mp_probeack.snpHitReleaseToClean  = req_snpHitReleaseToClean;
    mp_probeack.snpHitReleaseWithData = req_snpHitReleaseWithData;
    mp_probeack.snpHitReleaseIdx      = req_snpHitReleaseIdx;
  end

  // (d) 回上层：Grant / AccessAck / CBOAck（refill，MSHR.scala:730-848）
  //     合并进来的 Acquire：本拍 io_aMergeTask 有效就用它，否则用之前锁存的那份
  logic [5:0]  merge_off;
  logic [1:0]  merge_alias;
  logic [43:0] merge_vaddr;
  logic        merge_isKeyword;
  logic [3:0]  merge_opcode;
  logic [2:0]  merge_param;
  logic [6:0]  merge_sourceId;
  assign merge_off       = io_aMergeTask_valid ? io_aMergeTask_bits_off       : mp_grant_task_merge_task_r_off;
  assign merge_alias     = io_aMergeTask_valid ? io_aMergeTask_bits_alias     : mp_grant_task_merge_task_r_alias;
  assign merge_vaddr     = io_aMergeTask_valid ? io_aMergeTask_bits_vaddr     : mp_grant_task_merge_task_r_vaddr;
  assign merge_isKeyword = io_aMergeTask_valid ? io_aMergeTask_bits_isKeyword : mp_grant_task_merge_task_r_isKeyword;
  assign merge_opcode    = io_aMergeTask_valid ? io_aMergeTask_bits_opcode    : mp_grant_task_merge_task_r_opcode;
  assign merge_param     = io_aMergeTask_valid ? io_aMergeTask_bits_param     : mp_grant_task_merge_task_r_param;
  assign merge_sourceId  = io_aMergeTask_valid ? io_aMergeTask_bits_sourceId  : mp_grant_task_merge_task_r_sourceId;

  logic [1:0] aliasFinal;   // Get/Prefetch 保留目录里的 alias，否则用请求带来的
  assign aliasFinal = (req_get || req_prefetch) ? dirResult_meta_alias : req_alias;
  logic [2:0] grant_pfsrc;  // PfSource.fromMemReqSource：MemReqSource → 预取来源编号
  always_comb begin
    case (req_reqSource)
      5'h8:    grant_pfsrc = 3'h2;   // Prefetch2L2BOP    → BOP
      5'h9:    grant_pfsrc = 3'h3;   // Prefetch2L2PBOP   → PBOP
      5'hA:    grant_pfsrc = 3'h1;   // Prefetch2L2SMS    → SMS
      5'hB:    grant_pfsrc = 3'h4;   // Prefetch2L2Stream → Stream
      5'hC:    grant_pfsrc = 3'h5;   // Prefetch2L2Stride → Stride
      5'hD:    grant_pfsrc = 3'h6;   // Prefetch2L2TP     → TP
      5'hE:    grant_pfsrc = 3'h7;   // Prefetch2L2Berti  → Berti
      default: grant_pfsrc = 3'h0;   // NoWhere
    endcase
  end

  always_comb begin
    mp_grant = '0;
    mp_grant.channel   = req_channel;
    mp_grant.tag       = req_tag;
    mp_grant.set       = req_set;
    mp_grant.off       = req_off;
    mp_grant.sourceId  = req_sourceId;
    mp_grant.alias_f     = aliasFinal;
    mp_grant.isKeyword = req_isKeyword;
    mp_grant.opcode    = od_op_gen(req_opcode);
    mp_grant.param     = (req_get || req_prefetch) ? 3'h0 : grant_param(req_param, req_promoteT);
    mp_grant.denied    = denied;
    mp_grant.corrupt   = corrupt;
    mp_grant.mshrId    = io_id;
    mp_grant.way       = dirResult_way;
    mp_grant.aliasTask = req_aliasTask;
    // alias 引起的 Probe 数据要写进 DS；AcquireBlock NtoT 且本层是 BRANCH 时例外（L3 会给新数据）
    mp_grant.useProbeData = (dirResult_hit && req_get)
                            || (req_aliasTask && !(dirResult_meta_state == ST_BRANCH && req_needT));
    mp_grant.meta.dirty = gotDirty || dirResult_hit && dirResult_meta_dirty;
    if (req_get)
      mp_grant.meta.state = dirResult_hit ? (meta_isT ? ST_TIP : ST_BRANCH)
                                          : (req_promoteT ? ST_TIP : ST_BRANCH);
    else
      mp_grant.meta.state = (req_promoteT || req_needT) ? (req_prefetch ? ST_TIP : ST_TRUNK) : ST_BRANCH;
    mp_grant.meta.clients = req_prefetch ? (dirResult_hit ? dirResult_meta_clients : 1'b0)
                                         : !(req_get && (!dirResult_hit || !dirResult_meta_clients));
    mp_grant.meta.alias_f       = aliasFinal;
    mp_grant.meta.prefetch    = req_prefetch || dirResult_hit && dirResult_meta_prefetch;
    mp_grant.meta.prefetchSrc = grant_pfsrc;
    mp_grant.meta.accessed    = req_acquire || req_get;
    mp_grant.metaWen   = !cmo_cbo && !denied;
    mp_grant.tagWen    = !cmo_cbo && !dirResult_hit && !denied;
    mp_grant.dsWen     = (gotGrantData || probeDirty && (req_get || req_aliasTask)) && !denied;
    mp_grant.fromL2pft = req_fromL2pft;
    mp_grant.replTask  = !dirResult_hit && !state_w_replResp && !denied;
    mp_grant.cmoTask   = cmo_cbo;
    mp_grant.mshrRetry = !state_s_retry;
    mp_grant.mergeA    = mergeA || io_aMergeTask_valid;
    mp_grant.am_off       = merge_off;
    mp_grant.am_alias     = merge_alias;
    mp_grant.am_vaddr     = merge_vaddr;
    mp_grant.am_isKeyword = merge_isKeyword;
    mp_grant.am_opcode    = od_op_gen(merge_opcode)[2:0];
    mp_grant.am_param     = grant_param(merge_param, req_promoteT);
    mp_grant.am_sourceId  = merge_sourceId;
    mp_grant.am_meta_dirty   = gotDirty || dirResult_hit && dirResult_meta_dirty;
    mp_grant.am_meta_state   = (req_promoteT || need_t(merge_opcode, merge_param)) ? ST_TRUNK : ST_BRANCH;
    mp_grant.am_meta_clients = 1'b1;
    mp_grant.am_meta_alias   = merge_alias;
    mp_grant.am_meta_accessed = 1'b1;
  end

  // (e) DCT：把数据直接转发给请求者 CompData（MSHR.scala:850-908）
  always_comb begin
    mp_dct = '0;
    mp_dct.channel   = req_channel;
    mp_dct.txChannel = CH_TXDAT;
    mp_dct.tag       = req_tag;
    mp_dct.set       = req_set;
    mp_dct.off       = req_off;
    mp_dct.size      = 3'h6;
    mp_dct.mshrId    = io_id;
    mp_dct.useProbeData      = 1'b1;
    mp_dct.readProbeDataDown = 1'b1;
    mp_dct.way       = dirResult_way;
    mp_dct.dirty     = hitDirty;
    mp_dct.cmoTask   = cmo_cbo;
    mp_dct.tgtID     = req_fwdNID;
    mp_dct.txnID     = req_fwdTxnID;
    mp_dct.homeNID   = req_srcID;
    mp_dct.dbID      = req_txnID;
    mp_dct.chiOpcode = DAT_COMP_DATA;
    mp_dct.resp      = fwdCacheState | {fwdPassDirty, 2'b00};
    mp_dct.traceTag  = req_traceTag;
    mp_dct.snpHitRelease         = req_snpHitRelease;
    mp_dct.snpHitReleaseToInval  = req_snpHitReleaseToInval;
    mp_dct.snpHitReleaseToClean  = req_snpHitReleaseToClean;
    mp_dct.snpHitReleaseWithData = req_snpHitReleaseWithData;
    mp_dct.snpHitReleaseIdx      = req_snpHitReleaseIdx;
    mp_dct.snpHitReleaseMeta     = snp_hit_release_meta;
  end

  // (f) cbo.clean 的 meta 补写：ProbeAck TtoB/TtoN 之后把状态写回 TIP（MSHR.scala:910-975）
  always_comb begin
    mp_cmometaw = '0;
    mp_cmometaw.tag       = req_tag;
    mp_cmometaw.set       = req_set;
    mp_cmometaw.off       = req_off;
    mp_cmometaw.size      = 3'h6;
    mp_cmometaw.mshrId    = io_id;
    mp_cmometaw.way       = dirResult_way;
    mp_cmometaw.dirty     = hitDirty;
    mp_cmometaw.meta       = meta;
    mp_cmometaw.meta.dirty = 1'b0;
    mp_cmometaw.meta.state = ST_TIP;
    mp_cmometaw.metaWen   = 1'b1;
    mp_cmometaw.cmoTask   = cmo_cbo;
    mp_cmometaw.snpHitRelease         = req_snpHitRelease;
    mp_cmometaw.snpHitReleaseToInval  = req_snpHitReleaseToInval;
    mp_cmometaw.snpHitReleaseToClean  = req_snpHitReleaseToClean;
    mp_cmometaw.snpHitReleaseWithData = req_snpHitReleaseWithData;
    mp_cmometaw.snpHitReleaseIdx      = req_snpHitReleaseIdx;
    mp_cmometaw.snpHitReleaseMeta     = snp_hit_release_meta;
  end

  // 优先级：grant > release > cbwrdata > probeack > dct > cmometaw（都不成立时取 cmometaw）
  always_comb begin
    if (mp_grant_valid)         mp_sel = mp_grant;
    else if (mp_release_valid)  mp_sel = mp_release;
    else if (mp_cbwrdata_valid) mp_sel = mp_cbwrdata;
    else if (mp_probeack_valid) mp_sel = mp_probeack;
    else if (mp_dct_valid)      mp_sel = mp_dct;
    else                        mp_sel = mp_cmometaw;
    mp_sel.reqSource = req_reqSource;   // 统一覆盖（MSHR.scala:987-988）
    mp_sel.isKeyword = req_isKeyword;
  end

  assign io_tasks_mainpipe_bits_channel                  = mp_sel.channel;
  assign io_tasks_mainpipe_bits_txChannel                = mp_sel.txChannel;
  assign io_tasks_mainpipe_bits_set                      = mp_sel.set;
  assign io_tasks_mainpipe_bits_tag                      = mp_sel.tag;
  assign io_tasks_mainpipe_bits_off                      = mp_sel.off;
  assign io_tasks_mainpipe_bits_alias                    = mp_sel.alias_f;
  assign io_tasks_mainpipe_bits_isKeyword                = mp_sel.isKeyword;
  assign io_tasks_mainpipe_bits_opcode                   = mp_sel.opcode;
  assign io_tasks_mainpipe_bits_param                    = mp_sel.param;
  assign io_tasks_mainpipe_bits_size                     = mp_sel.size;
  assign io_tasks_mainpipe_bits_sourceId                 = mp_sel.sourceId;
  assign io_tasks_mainpipe_bits_denied                   = mp_sel.denied;
  assign io_tasks_mainpipe_bits_corrupt                  = mp_sel.corrupt;
  assign io_tasks_mainpipe_bits_mshrId                   = mp_sel.mshrId;
  assign io_tasks_mainpipe_bits_aliasTask                = mp_sel.aliasTask;
  assign io_tasks_mainpipe_bits_useProbeData             = mp_sel.useProbeData;
  assign io_tasks_mainpipe_bits_mshrRetry                = mp_sel.mshrRetry;
  assign io_tasks_mainpipe_bits_readProbeDataDown        = mp_sel.readProbeDataDown;
  assign io_tasks_mainpipe_bits_fromL2pft                = mp_sel.fromL2pft;
  assign io_tasks_mainpipe_bits_dirty                    = mp_sel.dirty;
  assign io_tasks_mainpipe_bits_way                      = mp_sel.way;
  assign io_tasks_mainpipe_bits_meta_dirty               = mp_sel.meta.dirty;
  assign io_tasks_mainpipe_bits_meta_state               = mp_sel.meta.state;
  assign io_tasks_mainpipe_bits_meta_clients             = mp_sel.meta.clients;
  assign io_tasks_mainpipe_bits_meta_alias               = mp_sel.meta.alias_f;
  assign io_tasks_mainpipe_bits_meta_prefetch            = mp_sel.meta.prefetch;
  assign io_tasks_mainpipe_bits_meta_prefetchSrc         = mp_sel.meta.prefetchSrc;
  assign io_tasks_mainpipe_bits_meta_accessed            = mp_sel.meta.accessed;
  assign io_tasks_mainpipe_bits_meta_tagErr              = mp_sel.meta.tagErr;
  assign io_tasks_mainpipe_bits_meta_dataErr             = mp_sel.meta.dataErr;
  assign io_tasks_mainpipe_bits_metaWen                  = mp_sel.metaWen;
  assign io_tasks_mainpipe_bits_tagWen                   = mp_sel.tagWen;
  assign io_tasks_mainpipe_bits_dsWen                    = mp_sel.dsWen;
  assign io_tasks_mainpipe_bits_replTask                 = mp_sel.replTask;
  assign io_tasks_mainpipe_bits_cmoTask                  = mp_sel.cmoTask;
  assign io_tasks_mainpipe_bits_reqSource                = mp_sel.reqSource;
  assign io_tasks_mainpipe_bits_mergeA                   = mp_sel.mergeA;
  assign io_tasks_mainpipe_bits_aMergeTask_off           = mp_sel.am_off;
  assign io_tasks_mainpipe_bits_aMergeTask_alias         = mp_sel.am_alias;
  assign io_tasks_mainpipe_bits_aMergeTask_vaddr         = mp_sel.am_vaddr;
  assign io_tasks_mainpipe_bits_aMergeTask_isKeyword     = mp_sel.am_isKeyword;
  assign io_tasks_mainpipe_bits_aMergeTask_opcode        = mp_sel.am_opcode;
  assign io_tasks_mainpipe_bits_aMergeTask_param         = mp_sel.am_param;
  assign io_tasks_mainpipe_bits_aMergeTask_sourceId      = mp_sel.am_sourceId;
  assign io_tasks_mainpipe_bits_aMergeTask_meta_dirty    = mp_sel.am_meta_dirty;
  assign io_tasks_mainpipe_bits_aMergeTask_meta_state    = mp_sel.am_meta_state;
  assign io_tasks_mainpipe_bits_aMergeTask_meta_clients  = mp_sel.am_meta_clients;
  assign io_tasks_mainpipe_bits_aMergeTask_meta_alias    = mp_sel.am_meta_alias;
  assign io_tasks_mainpipe_bits_aMergeTask_meta_accessed = mp_sel.am_meta_accessed;
  assign io_tasks_mainpipe_bits_snpHitRelease            = mp_sel.snpHitRelease;
  assign io_tasks_mainpipe_bits_snpHitReleaseToInval     = mp_sel.snpHitReleaseToInval;
  assign io_tasks_mainpipe_bits_snpHitReleaseToClean     = mp_sel.snpHitReleaseToClean;
  assign io_tasks_mainpipe_bits_snpHitReleaseWithData    = mp_sel.snpHitReleaseWithData;
  assign io_tasks_mainpipe_bits_snpHitReleaseIdx         = mp_sel.snpHitReleaseIdx;
  assign io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty       = mp_sel.snpHitReleaseMeta.dirty;
  assign io_tasks_mainpipe_bits_snpHitReleaseMeta_state       = mp_sel.snpHitReleaseMeta.state;
  assign io_tasks_mainpipe_bits_snpHitReleaseMeta_clients     = mp_sel.snpHitReleaseMeta.clients;
  assign io_tasks_mainpipe_bits_snpHitReleaseMeta_alias       = mp_sel.snpHitReleaseMeta.alias_f;
  assign io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch    = mp_sel.snpHitReleaseMeta.prefetch;
  assign io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc = mp_sel.snpHitReleaseMeta.prefetchSrc;
  assign io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed    = mp_sel.snpHitReleaseMeta.accessed;
  assign io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr      = mp_sel.snpHitReleaseMeta.tagErr;
  assign io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr     = mp_sel.snpHitReleaseMeta.dataErr;
  assign io_tasks_mainpipe_bits_tgtID                    = mp_sel.tgtID;
  assign io_tasks_mainpipe_bits_txnID                    = mp_sel.txnID;
  assign io_tasks_mainpipe_bits_homeNID                  = mp_sel.homeNID;
  assign io_tasks_mainpipe_bits_dbID                     = mp_sel.dbID;
  assign io_tasks_mainpipe_bits_chiOpcode                = mp_sel.chiOpcode;
  assign io_tasks_mainpipe_bits_resp                     = mp_sel.resp;
  assign io_tasks_mainpipe_bits_fwdState                 = mp_sel.fwdState;
  assign io_tasks_mainpipe_bits_retToSrc                 = mp_sel.retToSrc;
  assign io_tasks_mainpipe_bits_likelyshared             = mp_sel.likelyshared;
  assign io_tasks_mainpipe_bits_expCompAck               = mp_sel.expCompAck;
  assign io_tasks_mainpipe_bits_allowRetry               = mp_sel.allowRetry;
  assign io_tasks_mainpipe_bits_memAttr_allocate         = mp_sel.memAttr_allocate;
  assign io_tasks_mainpipe_bits_memAttr_cacheable        = mp_sel.memAttr_cacheable;
  assign io_tasks_mainpipe_bits_memAttr_ewa              = mp_sel.memAttr_ewa;
  assign io_tasks_mainpipe_bits_traceTag                 = mp_sel.traceTag;

  // ===========================================================================
  // §4 状态更新。Chisel 的 when 在同一拍内按书写顺序执行、后写覆盖先写；
  //    这里在一个 always_ff 里按同样顺序写非阻塞赋值，语义逐条对应（右边读的都是本拍旧值）。
  // ===========================================================================
  // 响应里用到的几个解码
  logic c_isProbeAck, c_isProbeAckData, c_isToN, c_isToB, c_isReport;
  assign c_isProbeAck     = io_resps_sinkC_bits_opcode == TL_PROBE_ACK;
  assign c_isProbeAckData = io_resps_sinkC_bits_opcode == TL_PROBE_ACK_DATA;
  assign c_isToN    = io_resps_sinkC_bits_param == TL_TTON || io_resps_sinkC_bits_param == TL_BTON
                    || io_resps_sinkC_bits_param == TL_NTON;
  assign c_isToB    = io_resps_sinkC_bits_param == TL_TTOB || io_resps_sinkC_bits_param == TL_BTOB;
  assign c_isReport = io_resps_sinkC_bits_param <= TL_NTON;   // TLPermissions.isReport：TtoB..NtoN
  logic dat_nderr, dat_derr, dat_isU, dat_isU_PD, dat_isCompData, dat_isDataSepResp;
  assign dat_nderr  = io_resps_rxdat_bits_respErr == RESP_ERR_NDERR;
  assign dat_derr   = io_resps_rxdat_bits_respErr == RESP_ERR_DERR;
  assign dat_isU    = io_resps_rxdat_bits_resp == CHI_UC;
  assign dat_isU_PD = io_resps_rxdat_bits_resp == (CHI_UC | 3'b100);
  assign dat_isCompData    = io_resps_rxdat_bits_chiOpcode == DAT_COMP_DATA;
  assign dat_isDataSepResp = io_resps_rxdat_bits_chiOpcode == DAT_DATA_SEP_RESP;
  logic rsp_nderr, rsp_isU;
  assign rsp_nderr = io_resps_rxrsp_bits_respErr == RESP_ERR_NDERR;
  assign rsp_isU   = io_resps_rxrsp_bits_resp == CHI_UC;
  logic rsp_isRespSepData, rsp_isComp, rsp_isCompDBIDResp, rsp_isRetryAck;
  assign rsp_isRespSepData  = io_resps_rxrsp_bits_chiOpcode == RSP_RESP_SEP_DATA;
  assign rsp_isComp         = io_resps_rxrsp_bits_chiOpcode == RSP_COMP;
  assign rsp_isCompDBIDResp = io_resps_rxrsp_bits_chiOpcode == RSP_COMP_DBID_RESP;
  assign rsp_isRetryAck     = io_resps_rxrsp_bits_chiOpcode == RSP_RETRY_ACK;
  logic comp_forRead, comp_forRelease;   // 一个 Comp 可能是读的响应，也可能是 Evict 的响应
  assign comp_forRead    = !state_w_grant && (state_s_cmoresp || state_w_releaseack);
  assign comp_forRelease = !state_w_releaseack;
  logic repl_retry, repl_done, repl_err;
  assign repl_retry = io_replResp_valid && io_replResp_bits_retry;
  assign repl_done  = io_replResp_valid && !io_replResp_bits_retry;
  assign repl_err   = io_replResp_bits_error || io_replResp_bits_meta_tagErr;

  logic will_free;
  assign will_free = state_s_refill && state_s_probeack && state_s_release && state_s_rcompack
                   && state_s_wcompack && state_s_cbwrdata && state_s_reissue && state_s_dct
                   && state_s_cmoresp && state_s_cmometaw
                   && state_w_rprobeacklast && state_w_pprobeacklast && state_w_grantlast && state_w_grant
                   && state_w_releaseack && state_w_replResp;

  // 嵌套写回：另一条 Release（C 通道）或 snoop 在我等待期间改了同一行（MSHR.scala:1379-1387）
  logic nestedwb_match, nestedwb_hit_match;
  assign nestedwb_match = req_valid && dirResult_meta_state != ST_INVALID
                          && dirResult_set == io_nestedwb_set && dirResult_tag == io_nestedwb_tag
                          && state_w_replResp
                          && (state_s_cmoresp || dirResult_hit)   // CMO 目录缺失时不算
                          && (req_mayRepl || dirResult_hit);      // 非替换类任务目录缺失时不算
  assign nestedwb_hit_match = req_valid && dirResult_hit
                              && dirResult_set == io_nestedwb_set && dirResult_tag == io_nestedwb_tag;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      req_valid <= 1'b0;
      {req_channel, req_set, req_tag, req_off, req_alias, req_isKeyword, req_opcode, req_param} <= '0;
      {req_sourceId, req_aliasTask, req_fromL2pft, req_reqSource} <= '0;
      {req_snpHitRelease, req_snpHitReleaseToInval, req_snpHitReleaseToClean, req_snpHitReleaseWithData,
       req_snpHitReleaseIdx} <= '0;
      {req_snpHitReleaseMeta_dirty, req_snpHitReleaseMeta_state, req_snpHitReleaseMeta_clients,
       req_snpHitReleaseMeta_alias, req_snpHitReleaseMeta_prefetch, req_snpHitReleaseMeta_prefetchSrc,
       req_snpHitReleaseMeta_accessed, req_snpHitReleaseMeta_tagErr, req_snpHitReleaseMeta_dataErr} <= '0;
      {req_srcID, req_txnID, req_fwdNID, req_fwdTxnID, req_chiOpcode, req_retToSrc, req_traceTag} <= '0;
      {dirResult_hit, dirResult_tag, dirResult_set, dirResult_way} <= '0;
      {dirResult_meta_dirty, dirResult_meta_state, dirResult_meta_clients, dirResult_meta_alias,
       dirResult_meta_prefetch, dirResult_meta_prefetchSrc, dirResult_meta_accessed,
       dirResult_meta_tagErr, dirResult_meta_dataErr} <= '0;
      // 状态标志复位全 1（= 没有待办）
      {state_s_acquire, state_s_rprobe, state_s_pprobe, state_s_release, state_s_probeack,
       state_s_refill, state_s_retry, state_s_cmoresp, state_s_cmometaw} <= '1;
      {state_w_rprobeackfirst, state_w_rprobeacklast, state_w_pprobeackfirst, state_w_pprobeacklast,
       state_w_grantfirst, state_w_grantlast, state_w_grant, state_w_releaseack, state_w_replResp} <= '1;
      {state_s_rcompack, state_s_wcompack, state_s_cbwrdata, state_s_reissue, state_s_dct} <= '1;
      {gotT, gotDirty, gotGrantData, probeDirty, releaseDirty, beatCnt} <= '0;
      timer <= 64'h0;
      {req_released_chiOpcode, req_released_likelyShared} <= '0;
      retryTimes <= 2'h0;
      backoffTimer <= 5'h0;
      {pcrdtype, gotRetryAck, gotPCrdGrant} <= '0;
      {tagErr, denied, corrupt, cbWrDataTraceTag} <= '0;
      mergeA <= 1'b0;
      {mp_grant_task_merge_task_r_off, mp_grant_task_merge_task_r_alias, mp_grant_task_merge_task_r_vaddr,
       mp_grant_task_merge_task_r_isKeyword, mp_grant_task_merge_task_r_opcode,
       mp_grant_task_merge_task_r_param, mp_grant_task_merge_task_r_sourceId} <= '0;
      {io_msInfo_bits_blockRefill_REG, io_msInfo_bits_blockRefill_REG_1,
       io_msInfo_bits_blockRefill_REG_2} <= '0;
      validCnt <= 64'h0;
    end
    else begin
      // ---- 分配（MSHR.scala:133-157）----
      if (io_alloc_valid) begin
        req_valid <= 1'b1;
        state_s_acquire        <= io_alloc_bits_state_s_acquire;
        state_s_rprobe         <= io_alloc_bits_state_s_rprobe;
        state_s_pprobe         <= io_alloc_bits_state_s_pprobe;
        state_s_release        <= io_alloc_bits_state_s_release;
        state_s_probeack       <= io_alloc_bits_state_s_probeack;
        state_s_refill         <= io_alloc_bits_state_s_refill;
        state_s_retry          <= 1'b1;        // 这五个在分配时恒为 1（见文件头）
        state_s_cmoresp        <= io_alloc_bits_state_s_cmoresp;
        state_s_cmometaw       <= 1'b1;
        state_w_rprobeackfirst <= io_alloc_bits_state_w_rprobeackfirst;
        state_w_rprobeacklast  <= io_alloc_bits_state_w_rprobeacklast;
        state_w_pprobeackfirst <= io_alloc_bits_state_w_pprobeackfirst;
        state_w_pprobeacklast  <= io_alloc_bits_state_w_pprobeacklast;
        state_w_grantfirst     <= io_alloc_bits_state_w_grantfirst;
        state_w_grantlast      <= io_alloc_bits_state_w_grantlast;
        state_w_grant          <= io_alloc_bits_state_w_grant;
        state_w_releaseack     <= io_alloc_bits_state_w_releaseack;
        state_w_replResp       <= io_alloc_bits_state_w_replResp;
        state_s_rcompack       <= io_alloc_bits_state_s_rcompack;
        state_s_wcompack       <= 1'b1;
        state_s_cbwrdata       <= 1'b1;
        state_s_reissue        <= 1'b1;
        state_s_dct            <= io_alloc_bits_state_s_dct;
        dirResult_hit              <= io_alloc_bits_dirResult_hit;
        dirResult_tag              <= io_alloc_bits_dirResult_tag;
        dirResult_set              <= io_alloc_bits_dirResult_set;
        dirResult_way              <= io_alloc_bits_dirResult_way;
        dirResult_meta_dirty       <= io_alloc_bits_dirResult_meta_dirty;
        dirResult_meta_state       <= io_alloc_bits_dirResult_meta_state;
        dirResult_meta_clients     <= io_alloc_bits_dirResult_meta_clients;
        dirResult_meta_alias       <= io_alloc_bits_dirResult_meta_alias;
        dirResult_meta_prefetch    <= io_alloc_bits_dirResult_meta_prefetch;
        dirResult_meta_prefetchSrc <= io_alloc_bits_dirResult_meta_prefetchSrc;
        dirResult_meta_accessed    <= io_alloc_bits_dirResult_meta_accessed;
        dirResult_meta_tagErr      <= io_alloc_bits_dirResult_meta_tagErr;
        dirResult_meta_dataErr     <= io_alloc_bits_dirResult_meta_dataErr;
        req_channel   <= io_alloc_bits_task_channel;
        req_set       <= io_alloc_bits_task_set;
        req_tag       <= io_alloc_bits_task_tag;
        req_off       <= io_alloc_bits_task_off;
        req_alias     <= io_alloc_bits_task_alias;
        req_isKeyword <= io_alloc_bits_task_isKeyword;
        req_opcode    <= io_alloc_bits_task_opcode;
        req_param     <= io_alloc_bits_task_param;
        req_sourceId  <= io_alloc_bits_task_sourceId;
        req_aliasTask <= io_alloc_bits_task_aliasTask;
        req_fromL2pft <= io_alloc_bits_task_fromL2pft;
        req_reqSource <= io_alloc_bits_task_reqSource;
        req_snpHitRelease         <= io_alloc_bits_task_snpHitRelease;
        req_snpHitReleaseToInval  <= io_alloc_bits_task_snpHitReleaseToInval;
        req_snpHitReleaseToClean  <= io_alloc_bits_task_snpHitReleaseToClean;
        req_snpHitReleaseWithData <= io_alloc_bits_task_snpHitReleaseWithData;
        req_snpHitReleaseIdx      <= io_alloc_bits_task_snpHitReleaseIdx;
        req_snpHitReleaseMeta_dirty       <= io_alloc_bits_task_snpHitReleaseMeta_dirty;
        req_snpHitReleaseMeta_state       <= io_alloc_bits_task_snpHitReleaseMeta_state;
        req_snpHitReleaseMeta_clients     <= io_alloc_bits_task_snpHitReleaseMeta_clients;
        req_snpHitReleaseMeta_alias       <= io_alloc_bits_task_snpHitReleaseMeta_alias;
        req_snpHitReleaseMeta_prefetch    <= io_alloc_bits_task_snpHitReleaseMeta_prefetch;
        req_snpHitReleaseMeta_prefetchSrc <= io_alloc_bits_task_snpHitReleaseMeta_prefetchSrc;
        req_snpHitReleaseMeta_accessed    <= io_alloc_bits_task_snpHitReleaseMeta_accessed;
        req_snpHitReleaseMeta_tagErr      <= io_alloc_bits_task_snpHitReleaseMeta_tagErr;
        req_snpHitReleaseMeta_dataErr     <= io_alloc_bits_task_snpHitReleaseMeta_dataErr;
        req_srcID     <= io_alloc_bits_task_srcID;
        req_txnID     <= io_alloc_bits_task_txnID;
        req_fwdNID    <= io_alloc_bits_task_fwdNID;
        req_fwdTxnID  <= io_alloc_bits_task_fwdTxnID;
        req_chiOpcode <= io_alloc_bits_task_chiOpcode;
        req_retToSrc  <= io_alloc_bits_task_retToSrc;
        req_traceTag  <= io_alloc_bits_task_traceTag;
        gotT         <= 1'b0;
        gotDirty     <= 1'b0;
        gotGrantData <= 1'b0;
        probeDirty   <= 1'b0;
        releaseDirty <= 1'b0;
        timer        <= 64'h1;
        beatCnt      <= 1'b0;
        gotRetryAck  <= 1'b0;
        gotPCrdGrant <= 1'b0;
        pcrdtype     <= 4'h0;
        tagErr  <= io_alloc_bits_dirResult_hit
                   && (io_alloc_bits_dirResult_meta_tagErr || io_alloc_bits_dirResult_error);
        denied  <= io_alloc_bits_dirResult_hit && io_alloc_bits_task_denied;
        corrupt <= io_alloc_bits_dirResult_hit && io_alloc_bits_task_corrupt;
        cbWrDataTraceTag <= 1'b0;
        retryTimes   <= 2'h0;
        backoffTimer <= 5'h0;
      end

      // ---- 退避计时（MSHR.scala:301-307）----
      if (pending_grant_valid && backoffTimer < BACKOFF_CYCLES && retryTimes == BACKOFF_THRESHOLD)
        backoffTimer <= backoffTimer + 5'h1;

      // ---- 四路请求发出后清标志（MSHR.scala:1030-1079）----
      if (txreq_fire) begin
        // CMO 的 release 与 acquire 两段都可能被 Retry
        state_s_acquire <= cmo_cbo ? (state_s_acquire || state_w_releaseack) : 1'b1;
        if (!state_s_reissue) begin
          state_s_reissue <= 1'b1;
          gotRetryAck     <= 1'b0;
          gotPCrdGrant    <= 1'b0;
        end
      end
      if (txrsp_fire) begin
        if (rcompack_valid) state_s_rcompack <= 1'b1;
        if (wcompack_valid) state_s_wcompack <= 1'b1;
      end
      if (source_b_fire) begin
        state_s_pprobe <= 1'b1;
        state_s_rprobe <= 1'b1;
      end
      if (io_tasks_mainpipe_ready) begin   // 注意：看 ready 而不是 fire
        if (mp_grant_valid) begin
          state_s_refill <= 1'b1;
          state_s_retry  <= 1'b1;
          if (mp_grant.opcode == 4'h8) state_s_cmoresp <= 1'b1;   // CBOAck
        end
        else if (mp_release_valid) begin
          req_released_chiOpcode    <= mp_release.chiOpcode;
          req_released_likelyShared <= mp_release.likelyshared;
          state_s_release  <= 1'b1;
          state_s_cbwrdata <= isEvict || dirResult_meta_tagErr;   // Evict 没有数据拍；tag 错不写回
          if (isEvict) begin
            dirResult_meta_state <= ST_INVALID;
            dirResult_meta_dirty <= 1'b0;
          end
        end
        else if (mp_cbwrdata_valid) begin
          state_s_cbwrdata     <= 1'b1;
          dirResult_meta_state <= ST_INVALID;
          dirResult_meta_dirty <= 1'b0;
        end
        else if (mp_probeack_valid)  state_s_probeack <= 1'b1;
        else if (mp_dct_valid)       state_s_dct      <= 1'b1;
        else if (mp_cmometaw_valid)  state_s_cmometaw <= 1'b1;
      end

      // ---- 上层 ProbeAck[Data]（sinkC，MSHR.scala:1096-1138）----
      if (io_resps_sinkC_valid) begin
        if (c_isProbeAck || c_isProbeAckData) begin
          state_w_rprobeackfirst <= 1'b1;
          state_w_rprobeacklast  <= state_w_rprobeacklast || io_resps_sinkC_bits_last;
          state_w_pprobeackfirst <= 1'b1;
          state_w_pprobeacklast  <= state_w_pprobeacklast || io_resps_sinkC_bits_last;
        end
        if (c_isProbeAckData) begin
          probeDirty           <= 1'b1;
          dirResult_meta_dirty <= 1'b1;
        end
        if (c_isToN) begin
          dirResult_meta_state   <= meta_isT ? ST_TIP : dirResult_meta_state;
          dirResult_meta_clients <= 1'b0;
        end
        if (c_isToB)
          dirResult_meta_state   <= meta_isT ? ST_TIP : dirResult_meta_state;
        if (c_isReport) begin
          dirResult_meta_tagErr  <= io_resps_sinkC_bits_denied;
          dirResult_meta_dataErr <= io_resps_sinkC_bits_corrupt;
          denied  <= denied || io_resps_sinkC_bits_denied;
          corrupt <= (c_isProbeAckData || io_resps_sinkC_bits_opcode == TL_RELEASE_DATA)
                     ? io_resps_sinkC_bits_corrupt : corrupt || io_resps_sinkC_bits_corrupt;
        end
        // cbo.clean：Probe 回来的是脏数据 → 要写回；是干净的 → 只补写 meta
        if (req_cboClean) begin
          if (c_isProbeAckData && state_w_rprobeackfirst) begin
            state_s_release    <= 1'b0;
            state_w_releaseack <= 1'b0;
          end
          if (c_isProbeAck) begin
            if (dirResult_meta_dirty) begin
              state_s_release    <= 1'b0;
              state_w_releaseack <= 1'b0;
            end
            else
              state_s_cmometaw <= 1'b0;
          end
        end
      end

      // ---- 下游读数据 RXDAT（MSHR.scala:1146-1182）----
      if (io_resps_rxdat_valid) begin
        if (dat_isDataSepResp) begin     // 数据与响应分离：两拍数据，响应另走 RXRSP
          beatCnt            <= beatCnt + 1'b1;
          state_w_grantfirst <= 1'b1;
          state_w_grantlast  <= state_w_grantfirst && beatCnt == 1'b1;
          state_w_replResp   <= state_w_replResp || dat_nderr;
          gotT         <= dat_isU || dat_isU_PD;
          gotDirty     <= gotDirty || dat_isU_PD;
          gotGrantData <= 1'b1;
          denied       <= denied || dat_nderr;
          corrupt      <= corrupt || dat_derr || dat_nderr || io_resps_rxdat_bits_corrupt;
        end
        if (dat_isCompData) begin        // 数据带响应：第二拍即完成
          state_w_grantfirst <= 1'b1;
          state_w_grantlast  <= state_w_grantfirst;
          state_w_grant      <= 1'b1;
          state_w_replResp   <= state_w_replResp || dat_nderr;
          gotT         <= dat_isU || dat_isU_PD;
          gotDirty     <= gotDirty || dat_isU_PD;
          gotGrantData <= 1'b1;
          denied       <= denied || dat_nderr;
          corrupt      <= corrupt || dat_derr || dat_nderr || io_resps_rxdat_bits_corrupt;
          req_traceTag <= req_traceTag || io_resps_rxdat_bits_traceTag;
        end
      end

      // ---- 下游响应 RXRSP（MSHR.scala:1185-1243）----
      if (io_resps_rxrsp_valid) begin
        if (rsp_isRespSepData) begin
          state_w_grant    <= 1'b1;
          state_w_replResp <= state_w_replResp || rsp_nderr;
          denied           <= denied || rsp_nderr;
          req_traceTag     <= io_resps_rxrsp_bits_traceTag;
        end
        if (rsp_isComp) begin
          if (comp_forRead) begin         // MakeUnique / CMO 的 Comp：无数据的读完成
            state_w_grantfirst <= 1'b1;
            state_w_grantlast  <= 1'b1;
            state_w_grant      <= 1'b1;
            state_w_replResp   <= state_w_replResp || rsp_nderr;
            gotT         <= rsp_isU;
            gotDirty     <= 1'b0;
            denied       <= denied || rsp_nderr;
            req_traceTag <= io_resps_rxrsp_bits_traceTag;
          end
          if (comp_forRelease) begin      // Evict / WriteEvictOrEvict 的 Comp
            state_w_releaseack <= 1'b1;
            if (isWriteEvictOrEvict) begin   // 对方选了 Evict：丢掉数据拍、补一个 CompAck
              req_traceTag     <= io_resps_rxrsp_bits_traceTag;
              state_s_cbwrdata <= 1'b1;
              state_s_wcompack <= 1'b0;
            end
          end
        end
        if (rsp_isCompDBIDResp) begin
          state_w_releaseack <= 1'b1;
          cbWrDataTraceTag   <= io_resps_rxrsp_bits_traceTag;
        end
        if (rsp_isRetryAck) begin
          pcrdtype    <= io_resps_rxrsp_bits_pCrdType;
          gotRetryAck <= 1'b1;
        end
      end

      // ---- 协议重试：拿到 P-Credit 后重发（MSHR.scala:1246-1249）----
      if (io_pCrd_grant) begin
        state_s_reissue <= 1'b0;
        gotPCrdGrant    <= 1'b1;
      end

      // ---- 写 releaseBuf 时 DS 报数据错（MSHR.scala:1252-1254）----
      if (io_dsResp_valid)
        corrupt <= corrupt || io_dsResp_bits_dataError;

      // ---- replacer 选路结果（MSHR.scala:1257-1297）----
      if (repl_retry) begin              // 本 set 的路都被别的 MSHR 占着：重来，并计次退避
        state_s_refill <= 1'b0;
        state_s_retry  <= 1'b0;
        dirResult_way  <= io_replResp_bits_way;
        if (retryTimes < BACKOFF_THRESHOLD)
          retryTimes <= retryTimes + 2'h1;
        backoffTimer <= 5'h0;
      end
      if (repl_done) begin
        state_w_replResp <= 1'b1;
        dirResult_tag              <= io_replResp_bits_tag;
        dirResult_way              <= io_replResp_bits_way;
        dirResult_meta_dirty       <= io_replResp_bits_meta_dirty;
        dirResult_meta_state       <= io_replResp_bits_meta_state;
        dirResult_meta_clients     <= io_replResp_bits_meta_clients;
        dirResult_meta_alias       <= io_replResp_bits_meta_alias;
        dirResult_meta_prefetch    <= io_replResp_bits_meta_prefetch;
        dirResult_meta_prefetchSrc <= io_replResp_bits_meta_prefetchSrc;
        dirResult_meta_accessed    <= io_replResp_bits_meta_accessed;
        dirResult_meta_tagErr      <= repl_err;
        dirResult_meta_dataErr     <= io_replResp_bits_meta_dataErr;
        // 选中的路不空 → 要先把它写回；tag 错不写回；上层还有副本 → 先 Probe 上层
        if (io_replResp_bits_meta_state != ST_INVALID) begin
          state_s_release <= 1'b0;
          if (!repl_err) begin
            state_w_releaseack <= 1'b0;
            if (io_replResp_bits_meta_clients) begin
              state_s_rprobe         <= 1'b0;
              state_w_rprobeackfirst <= 1'b0;
              state_w_rprobeacklast  <= 1'b0;
            end
          end
        end
      end

      // ---- 计时与释放（MSHR.scala:1299-1317）----
      if (req_valid)
        timer <= timer + 64'h1;
      if (will_free && req_valid) begin
        req_valid <= 1'b0;
        timer     <= 64'h0;
      end

      // ---- 嵌套写回改 meta（MSHR.scala:1389-1425）----
      if (nestedwb_match) begin
        if (io_nestedwb_c_set_dirty) begin     // 嵌套 ReleaseData 带来脏数据
          dirResult_meta_dirty   <= 1'b1;
          dirResult_meta_state   <= ST_TIP;
          dirResult_meta_clients <= 1'b0;
          releaseDirty <= 1'b1;
          denied       <= denied || io_nestedwb_denied;
          corrupt      <= io_nestedwb_corrupt;
        end
        if (io_nestedwb_c_set_tip) begin       // 嵌套 Release 交回了 T
          dirResult_meta_state   <= ST_TIP;
          dirResult_meta_clients <= 1'b0;
          denied <= denied || io_nestedwb_denied;
        end
        if (io_nestedwb_b_inv_dirty && req_fromA) begin
          dirResult_meta_dirty <= 1'b0;
          dirResult_meta_state <= ST_INVALID;
          probeDirty <= 1'b0;
        end
      end
      if (nestedwb_hit_match) begin            // 嵌套 snoop 改了我命中的那一行
        if (io_nestedwb_b_toClean && req_fromA) begin
          dirResult_meta_dirty <= 1'b0;
          probeDirty <= 1'b0;
        end
        if (io_nestedwb_b_toB && req_fromA)
          dirResult_meta_state <= (dirResult_meta_state >= ST_BRANCH) ? ST_BRANCH : ST_INVALID;
        if (io_nestedwb_b_toN && req_fromA) begin
          dirResult_meta_state   <= ST_INVALID;
          dirResult_hit          <= 1'b0;
          dirResult_meta_clients <= 1'b0;
          state_w_replResp <= cmo_cbo || denied;   // CMO 从不问 replacer
          req_aliasTask    <= 1'b0;
        end
      end

      // ---- 合并 Acquire（MSHR.scala:724-729, 815）----
      if (io_aMergeTask_valid) begin
        mergeA <= 1'b1;
        mp_grant_task_merge_task_r_off       <= io_aMergeTask_bits_off;
        mp_grant_task_merge_task_r_alias     <= io_aMergeTask_bits_alias;
        mp_grant_task_merge_task_r_vaddr     <= io_aMergeTask_bits_vaddr;
        mp_grant_task_merge_task_r_isKeyword <= io_aMergeTask_bits_isKeyword;
        mp_grant_task_merge_task_r_opcode    <= io_aMergeTask_bits_opcode;
        mp_grant_task_merge_task_r_param     <= io_aMergeTask_bits_param;
        mp_grant_task_merge_task_r_sourceId  <= io_aMergeTask_bits_sourceId;
      end
      else if (io_alloc_valid)
        mergeA <= 1'b0;

      // ---- msInfo.blockRefill 的延迟链（MSHR.scala:1349）----
      io_msInfo_bits_blockRefill_REG   <= !state_s_release;
      io_msInfo_bits_blockRefill_REG_1 <= !state_s_release;
      io_msInfo_bits_blockRefill_REG_2 <= io_msInfo_bits_blockRefill_REG_1;

      // ---- 死锁检测计数（断言用，MSHR.scala:1438-1445）----
      if (io_alloc_valid) validCnt <= 64'h0;
      if (req_valid)      validCnt <= validCnt + 64'h1;
    end
  end

  // ===========================================================================
  // §5 状态与信息输出（MSHR.scala:128-130, 1320-1370, 1431）
  // ===========================================================================
  logic releaseNotSent;
  assign releaseNotSent = !state_s_release;

  assign io_status_valid             = req_valid;
  assign io_status_bits_channel      = req_channel;
  assign io_status_bits_set          = req_set;
  assign io_status_bits_reqTag       = req_tag;
  assign io_status_bits_metaTag      = dirResult_tag;
  assign io_status_bits_needsRepl    = releaseNotSent;
  assign io_status_bits_w_c_resp     = !state_w_rprobeacklast || !state_w_pprobeacklast;
  assign io_status_bits_will_free    = will_free;
  assign io_status_bits_reqSource    = req_reqSource;
  assign io_status_bits_is_miss      = !dirResult_hit;
  assign io_status_bits_is_prefetch  = req_prefetch;

  assign io_statAlloc_valid          = io_alloc_valid;
  assign io_statAlloc_bits_channel   = io_alloc_bits_task_channel;
  assign io_statAlloc_bits_is_miss   = !io_alloc_bits_dirResult_hit;
  assign io_statAlloc_bits_is_prefetch = io_alloc_bits_task_opcode == TL_HINT;

  assign io_msInfo_valid             = req_valid;
  assign io_msInfo_bits_channel      = req_channel;
  assign io_msInfo_bits_set          = req_set;
  assign io_msInfo_bits_way          = dirResult_way;
  assign io_msInfo_bits_reqTag       = req_tag;
  assign io_msInfo_bits_willFree     = will_free;
  assign io_msInfo_bits_aliasTask    = req_aliasTask;
  assign io_msInfo_bits_needRelease  = !state_w_releaseack;
  // release 还在 MainPipe s1/s2 时 refill 也要挡（再往后两拍）
  assign io_msInfo_bits_blockRefill  = releaseNotSent || io_msInfo_bits_blockRefill_REG
                                       || io_msInfo_bits_blockRefill_REG_2;
  assign io_msInfo_bits_meta_dirty       = dirResult_meta_dirty;
  assign io_msInfo_bits_meta_state       = dirResult_meta_state;
  assign io_msInfo_bits_meta_clients     = dirResult_meta_clients;
  assign io_msInfo_bits_meta_alias       = dirResult_meta_alias;
  assign io_msInfo_bits_meta_prefetch    = dirResult_meta_prefetch;
  assign io_msInfo_bits_meta_prefetchSrc = dirResult_meta_prefetchSrc;
  assign io_msInfo_bits_meta_accessed    = dirResult_meta_accessed;
  assign io_msInfo_bits_meta_tagErr      = dirResult_meta_tagErr;
  assign io_msInfo_bits_meta_dataErr     = dirResult_meta_dataErr;
  assign io_msInfo_bits_metaTag          = dirResult_tag;
  assign io_msInfo_bits_dirHit           = dirResult_hit;
  assign io_msInfo_bits_isAcqOrPrefetch  = req_acquire || req_prefetch;
  assign io_msInfo_bits_isPrefetch       = req_prefetch;
  assign io_msInfo_bits_param            = req_param;
  assign io_msInfo_bits_mergeA           = mergeA;
  assign io_msInfo_bits_w_grantfirst     = state_w_grantfirst;
  assign io_msInfo_bits_s_release        = state_s_release;
  assign io_msInfo_bits_s_refill         = state_s_refill;
  assign io_msInfo_bits_s_cmoresp        = state_s_cmoresp;
  assign io_msInfo_bits_s_cmometaw       = state_s_cmometaw;
  assign io_msInfo_bits_w_releaseack     = state_w_releaseack;
  assign io_msInfo_bits_w_replResp       = state_w_replResp;
  assign io_msInfo_bits_w_rprobeacklast  = state_w_rprobeacklast;
  assign io_msInfo_bits_replaceData      = meta_isT && dirResult_meta_dirty   // 含 WriteCleanFull
                                           || isWriteEvictFull || isWriteEvictOrEvict;
  assign io_msInfo_bits_releaseToClean   = req_cboClean;

  assign io_nestedwbData = nestedwb_match && io_nestedwb_c_set_dirty;   // 让嵌套 C 把数据写进我的 releaseBuf

  assign io_pCrd_query_valid         = gotRetryAck && !gotPCrdGrant;
  assign io_pCrd_query_bits_pCrdType = pcrdtype;
  assign io_pCrd_query_bits_srcID    = srcid_retryack;

  // ===========================================================================
  // §6 性能计数与断言影子的组合部分
  // ===========================================================================
  logic acquire_finish;
  assign acquire_finish = state_w_grant && state_w_grantlast;
  assign acquire_period_valid = acquire_finish && !acquire_period_valid_REG;
  assign acquire_period_bits  = timer - acquire_ts;
  assign release_period_valid = state_w_releaseack && !release_period_valid_REG;
  assign release_period_bits  = timer - release_ts;

  // 发出了哪种写回（TXREQ 直发，或 MainPipe 发往 TXREQ 的任务）
  logic mp_toTXREQ, evictFire, wbFire, wcFire, weFire;
  assign mp_toTXREQ = io_tasks_mainpipe_bits_txChannel[0];
  assign evictFire = txreq_fire && io_tasks_txreq_bits_opcode == REQ_EVICT
                  || mainpipe_fire && {3'h0, io_tasks_mainpipe_bits_opcode} == REQ_EVICT && mp_toTXREQ;
  assign wbFire    = txreq_fire && io_tasks_txreq_bits_opcode == REQ_WRITE_BACK_FULL
                  || mainpipe_fire && {3'h0, io_tasks_mainpipe_bits_opcode} == REQ_WRITE_BACK_FULL && mp_toTXREQ;
  assign wcFire    = txreq_fire && io_tasks_txreq_bits_opcode == REQ_WRITE_CLEAN_FULL
                  || mainpipe_fire && {3'h0, io_tasks_mainpipe_bits_opcode} == REQ_WRITE_CLEAN_FULL && mp_toTXREQ;
  assign weFire    = txreq_fire && io_tasks_txreq_bits_opcode == REQ_WRITE_EVICT_FULL
                  || mainpipe_fire && {3'h0, io_tasks_mainpipe_bits_opcode} == REQ_WRITE_EVICT_FULL && mp_toTXREQ;

  // 无复位的寄存器（Chisel Reg / RegEnable 不带初值）
  always_ff @(posedge clock) begin
    if (io_resps_rxdat_valid && dat_isCompData) begin
      txnid_rcompack <= io_resps_rxdat_bits_dbID;      // CompAck 的 TxnID = 数据的 DBID
      tgtid_rcompack <= io_resps_rxdat_bits_homeNID;   // CompAck 的 TgtID = 数据的 HomeNID
    end
    if (io_resps_rxrsp_valid) begin
      if (rsp_isRespSepData || rsp_isComp && comp_forRead) begin
        tgtid_rcompack <= io_resps_rxrsp_bits_srcID;
        txnid_rcompack <= io_resps_rxrsp_bits_dbID;
      end
      if (rsp_isComp && comp_forRelease && isWriteEvictOrEvict || rsp_isCompDBIDResp) begin
        tgtid_wcompack <= io_resps_rxrsp_bits_srcID;
        txnid_wcompack <= io_resps_rxrsp_bits_dbID;
      end
      if (rsp_isRetryAck)
        srcid_retryack <= io_resps_rxrsp_bits_srcID;
    end
    // 性能：Acquire / Release 发出时刻，与完成标志打一拍（MSHR.scala:1466-1480）
    if (txreq_fire && !state_s_acquire)
      acquire_ts <= timer;
    if (mainpipe_fire && !state_s_release)
      release_ts <= timer;
    acquire_period_valid_REG <= acquire_finish;
    release_period_valid_REG <= state_w_releaseack;
    // 断言影子：上一拍发出的写回类型（MSHR.scala:1451-1462）
    REG   <= evictFire;
    REG_1 <= wbFire;
    REG_2 <= wcFire;
    REG_3 <= weFire;
  end

endmodule

// BEGIN GENERATED(wrapper) —— scripts/gen_mshr.py 从 golden 端口表生成，勿手改
// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden MSHR.sv 逐位同名同宽同序，按名直连可读核。
// ---------------------------------------------------------------------------
module MSHR(
  input         clock,
  input         reset,
  input  [7:0]  io_id,
  output        io_status_valid,
  output [2:0]  io_status_bits_channel,
  output [8:0]  io_status_bits_set,
  output [30:0] io_status_bits_reqTag,
  output [30:0] io_status_bits_metaTag,
  output        io_status_bits_needsRepl,
  output        io_status_bits_w_c_resp,
  output        io_status_bits_will_free,
  output [4:0]  io_status_bits_reqSource,
  output        io_status_bits_is_miss,
  output        io_status_bits_is_prefetch,
  output        io_statAlloc_valid,
  output [2:0]  io_statAlloc_bits_channel,
  output        io_statAlloc_bits_is_miss,
  output        io_statAlloc_bits_is_prefetch,
  output        io_msInfo_valid,
  output [2:0]  io_msInfo_bits_channel,
  output [8:0]  io_msInfo_bits_set,
  output [2:0]  io_msInfo_bits_way,
  output [30:0] io_msInfo_bits_reqTag,
  output        io_msInfo_bits_willFree,
  output        io_msInfo_bits_aliasTask,
  output        io_msInfo_bits_needRelease,
  output        io_msInfo_bits_blockRefill,
  output        io_msInfo_bits_meta_dirty,
  output [1:0]  io_msInfo_bits_meta_state,
  output        io_msInfo_bits_meta_clients,
  output [1:0]  io_msInfo_bits_meta_alias,
  output        io_msInfo_bits_meta_prefetch,
  output [2:0]  io_msInfo_bits_meta_prefetchSrc,
  output        io_msInfo_bits_meta_accessed,
  output        io_msInfo_bits_meta_tagErr,
  output        io_msInfo_bits_meta_dataErr,
  output [30:0] io_msInfo_bits_metaTag,
  output        io_msInfo_bits_dirHit,
  output        io_msInfo_bits_isAcqOrPrefetch,
  output        io_msInfo_bits_isPrefetch,
  output [2:0]  io_msInfo_bits_param,
  output        io_msInfo_bits_mergeA,
  output        io_msInfo_bits_w_grantfirst,
  output        io_msInfo_bits_s_release,
  output        io_msInfo_bits_s_refill,
  output        io_msInfo_bits_s_cmoresp,
  output        io_msInfo_bits_s_cmometaw,
  output        io_msInfo_bits_w_releaseack,
  output        io_msInfo_bits_w_replResp,
  output        io_msInfo_bits_w_rprobeacklast,
  output        io_msInfo_bits_replaceData,
  output        io_msInfo_bits_releaseToClean,
  input         io_alloc_valid,
  input         io_alloc_bits_dirResult_hit,
  input  [30:0] io_alloc_bits_dirResult_tag,
  input  [8:0]  io_alloc_bits_dirResult_set,
  input  [2:0]  io_alloc_bits_dirResult_way,
  input         io_alloc_bits_dirResult_meta_dirty,
  input  [1:0]  io_alloc_bits_dirResult_meta_state,
  input         io_alloc_bits_dirResult_meta_clients,
  input  [1:0]  io_alloc_bits_dirResult_meta_alias,
  input         io_alloc_bits_dirResult_meta_prefetch,
  input  [2:0]  io_alloc_bits_dirResult_meta_prefetchSrc,
  input         io_alloc_bits_dirResult_meta_accessed,
  input         io_alloc_bits_dirResult_meta_tagErr,
  input         io_alloc_bits_dirResult_meta_dataErr,
  input         io_alloc_bits_dirResult_error,
  input         io_alloc_bits_state_s_acquire,
  input         io_alloc_bits_state_s_rprobe,
  input         io_alloc_bits_state_s_pprobe,
  input         io_alloc_bits_state_s_release,
  input         io_alloc_bits_state_s_probeack,
  input         io_alloc_bits_state_s_refill,
  input         io_alloc_bits_state_s_cmoresp,
  input         io_alloc_bits_state_w_rprobeackfirst,
  input         io_alloc_bits_state_w_rprobeacklast,
  input         io_alloc_bits_state_w_pprobeackfirst,
  input         io_alloc_bits_state_w_pprobeacklast,
  input         io_alloc_bits_state_w_grantfirst,
  input         io_alloc_bits_state_w_grantlast,
  input         io_alloc_bits_state_w_grant,
  input         io_alloc_bits_state_w_releaseack,
  input         io_alloc_bits_state_w_replResp,
  input         io_alloc_bits_state_s_rcompack,
  input         io_alloc_bits_state_s_dct,
  input  [2:0]  io_alloc_bits_task_channel,
  input  [8:0]  io_alloc_bits_task_set,
  input  [30:0] io_alloc_bits_task_tag,
  input  [5:0]  io_alloc_bits_task_off,
  input  [1:0]  io_alloc_bits_task_alias,
  input         io_alloc_bits_task_isKeyword,
  input  [3:0]  io_alloc_bits_task_opcode,
  input  [2:0]  io_alloc_bits_task_param,
  input  [6:0]  io_alloc_bits_task_sourceId,
  input         io_alloc_bits_task_denied,
  input         io_alloc_bits_task_corrupt,
  input         io_alloc_bits_task_aliasTask,
  input         io_alloc_bits_task_fromL2pft,
  input  [4:0]  io_alloc_bits_task_reqSource,
  input         io_alloc_bits_task_snpHitRelease,
  input         io_alloc_bits_task_snpHitReleaseToInval,
  input         io_alloc_bits_task_snpHitReleaseToClean,
  input         io_alloc_bits_task_snpHitReleaseWithData,
  input  [7:0]  io_alloc_bits_task_snpHitReleaseIdx,
  input         io_alloc_bits_task_snpHitReleaseMeta_dirty,
  input  [1:0]  io_alloc_bits_task_snpHitReleaseMeta_state,
  input         io_alloc_bits_task_snpHitReleaseMeta_clients,
  input  [1:0]  io_alloc_bits_task_snpHitReleaseMeta_alias,
  input         io_alloc_bits_task_snpHitReleaseMeta_prefetch,
  input  [2:0]  io_alloc_bits_task_snpHitReleaseMeta_prefetchSrc,
  input         io_alloc_bits_task_snpHitReleaseMeta_accessed,
  input         io_alloc_bits_task_snpHitReleaseMeta_tagErr,
  input         io_alloc_bits_task_snpHitReleaseMeta_dataErr,
  input  [10:0] io_alloc_bits_task_srcID,
  input  [11:0] io_alloc_bits_task_txnID,
  input  [10:0] io_alloc_bits_task_fwdNID,
  input  [11:0] io_alloc_bits_task_fwdTxnID,
  input  [6:0]  io_alloc_bits_task_chiOpcode,
  input         io_alloc_bits_task_retToSrc,
  input         io_alloc_bits_task_traceTag,
  input         io_tasks_txreq_ready,
  output        io_tasks_txreq_valid,
  output [10:0] io_tasks_txreq_bits_tgtID,
  output [11:0] io_tasks_txreq_bits_txnID,
  output [6:0]  io_tasks_txreq_bits_opcode,
  output [47:0] io_tasks_txreq_bits_addr,
  output        io_tasks_txreq_bits_likelyshared,
  output        io_tasks_txreq_bits_allowRetry,
  output [3:0]  io_tasks_txreq_bits_pCrdType,
  output        io_tasks_txreq_bits_memAttr_allocate,
  output        io_tasks_txreq_bits_expCompAck,
  input         io_tasks_txrsp_ready,
  output        io_tasks_txrsp_valid,
  output [10:0] io_tasks_txrsp_bits_tgtID,
  output [11:0] io_tasks_txrsp_bits_txnID,
  output        io_tasks_txrsp_bits_traceTag,
  input         io_tasks_source_b_ready,
  output        io_tasks_source_b_valid,
  output [30:0] io_tasks_source_b_bits_tag,
  output [8:0]  io_tasks_source_b_bits_set,
  output [1:0]  io_tasks_source_b_bits_param,
  output [1:0]  io_tasks_source_b_bits_alias,
  input         io_tasks_mainpipe_ready,
  output        io_tasks_mainpipe_valid,
  output [2:0]  io_tasks_mainpipe_bits_channel,
  output [2:0]  io_tasks_mainpipe_bits_txChannel,
  output [8:0]  io_tasks_mainpipe_bits_set,
  output [30:0] io_tasks_mainpipe_bits_tag,
  output [5:0]  io_tasks_mainpipe_bits_off,
  output [1:0]  io_tasks_mainpipe_bits_alias,
  output        io_tasks_mainpipe_bits_isKeyword,
  output [3:0]  io_tasks_mainpipe_bits_opcode,
  output [2:0]  io_tasks_mainpipe_bits_param,
  output [2:0]  io_tasks_mainpipe_bits_size,
  output [6:0]  io_tasks_mainpipe_bits_sourceId,
  output        io_tasks_mainpipe_bits_denied,
  output        io_tasks_mainpipe_bits_corrupt,
  output [7:0]  io_tasks_mainpipe_bits_mshrId,
  output        io_tasks_mainpipe_bits_aliasTask,
  output        io_tasks_mainpipe_bits_useProbeData,
  output        io_tasks_mainpipe_bits_mshrRetry,
  output        io_tasks_mainpipe_bits_readProbeDataDown,
  output        io_tasks_mainpipe_bits_fromL2pft,
  output        io_tasks_mainpipe_bits_dirty,
  output [2:0]  io_tasks_mainpipe_bits_way,
  output        io_tasks_mainpipe_bits_meta_dirty,
  output [1:0]  io_tasks_mainpipe_bits_meta_state,
  output        io_tasks_mainpipe_bits_meta_clients,
  output [1:0]  io_tasks_mainpipe_bits_meta_alias,
  output        io_tasks_mainpipe_bits_meta_prefetch,
  output [2:0]  io_tasks_mainpipe_bits_meta_prefetchSrc,
  output        io_tasks_mainpipe_bits_meta_accessed,
  output        io_tasks_mainpipe_bits_meta_tagErr,
  output        io_tasks_mainpipe_bits_meta_dataErr,
  output        io_tasks_mainpipe_bits_metaWen,
  output        io_tasks_mainpipe_bits_tagWen,
  output        io_tasks_mainpipe_bits_dsWen,
  output        io_tasks_mainpipe_bits_replTask,
  output        io_tasks_mainpipe_bits_cmoTask,
  output [4:0]  io_tasks_mainpipe_bits_reqSource,
  output        io_tasks_mainpipe_bits_mergeA,
  output [5:0]  io_tasks_mainpipe_bits_aMergeTask_off,
  output [1:0]  io_tasks_mainpipe_bits_aMergeTask_alias,
  output [43:0] io_tasks_mainpipe_bits_aMergeTask_vaddr,
  output        io_tasks_mainpipe_bits_aMergeTask_isKeyword,
  output [2:0]  io_tasks_mainpipe_bits_aMergeTask_opcode,
  output [2:0]  io_tasks_mainpipe_bits_aMergeTask_param,
  output [6:0]  io_tasks_mainpipe_bits_aMergeTask_sourceId,
  output        io_tasks_mainpipe_bits_aMergeTask_meta_dirty,
  output [1:0]  io_tasks_mainpipe_bits_aMergeTask_meta_state,
  output        io_tasks_mainpipe_bits_aMergeTask_meta_clients,
  output [1:0]  io_tasks_mainpipe_bits_aMergeTask_meta_alias,
  output        io_tasks_mainpipe_bits_aMergeTask_meta_accessed,
  output        io_tasks_mainpipe_bits_snpHitRelease,
  output        io_tasks_mainpipe_bits_snpHitReleaseToInval,
  output        io_tasks_mainpipe_bits_snpHitReleaseToClean,
  output        io_tasks_mainpipe_bits_snpHitReleaseWithData,
  output [7:0]  io_tasks_mainpipe_bits_snpHitReleaseIdx,
  output        io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty,
  output [1:0]  io_tasks_mainpipe_bits_snpHitReleaseMeta_state,
  output        io_tasks_mainpipe_bits_snpHitReleaseMeta_clients,
  output [1:0]  io_tasks_mainpipe_bits_snpHitReleaseMeta_alias,
  output        io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch,
  output [2:0]  io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc,
  output        io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed,
  output        io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr,
  output        io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr,
  output [10:0] io_tasks_mainpipe_bits_tgtID,
  output [11:0] io_tasks_mainpipe_bits_txnID,
  output [10:0] io_tasks_mainpipe_bits_homeNID,
  output [11:0] io_tasks_mainpipe_bits_dbID,
  output [6:0]  io_tasks_mainpipe_bits_chiOpcode,
  output [2:0]  io_tasks_mainpipe_bits_resp,
  output [2:0]  io_tasks_mainpipe_bits_fwdState,
  output        io_tasks_mainpipe_bits_retToSrc,
  output        io_tasks_mainpipe_bits_likelyshared,
  output        io_tasks_mainpipe_bits_expCompAck,
  output        io_tasks_mainpipe_bits_allowRetry,
  output        io_tasks_mainpipe_bits_memAttr_allocate,
  output        io_tasks_mainpipe_bits_memAttr_cacheable,
  output        io_tasks_mainpipe_bits_memAttr_ewa,
  output        io_tasks_mainpipe_bits_traceTag,
  input         io_resps_sinkC_valid,
  input  [2:0]  io_resps_sinkC_bits_opcode,
  input  [2:0]  io_resps_sinkC_bits_param,
  input         io_resps_sinkC_bits_last,
  input         io_resps_sinkC_bits_denied,
  input         io_resps_sinkC_bits_corrupt,
  input         io_resps_rxrsp_valid,
  input  [6:0]  io_resps_rxrsp_bits_chiOpcode,
  input  [10:0] io_resps_rxrsp_bits_srcID,
  input  [11:0] io_resps_rxrsp_bits_dbID,
  input  [2:0]  io_resps_rxrsp_bits_resp,
  input  [3:0]  io_resps_rxrsp_bits_pCrdType,
  input  [1:0]  io_resps_rxrsp_bits_respErr,
  input         io_resps_rxrsp_bits_traceTag,
  input         io_resps_rxdat_valid,
  input         io_resps_rxdat_bits_corrupt,
  input  [6:0]  io_resps_rxdat_bits_chiOpcode,
  input  [10:0] io_resps_rxdat_bits_homeNID,
  input  [11:0] io_resps_rxdat_bits_dbID,
  input  [2:0]  io_resps_rxdat_bits_resp,
  input  [1:0]  io_resps_rxdat_bits_respErr,
  input         io_resps_rxdat_bits_traceTag,
  input  [8:0]  io_nestedwb_set,
  input  [30:0] io_nestedwb_tag,
  input         io_nestedwb_c_set_dirty,
  input         io_nestedwb_c_set_tip,
  input         io_nestedwb_b_inv_dirty,
  input         io_nestedwb_b_toB,
  input         io_nestedwb_b_toN,
  input         io_nestedwb_b_toClean,
  input         io_nestedwb_denied,
  input         io_nestedwb_corrupt,
  output        io_nestedwbData,
  input         io_aMergeTask_valid,
  input  [5:0]  io_aMergeTask_bits_off,
  input  [1:0]  io_aMergeTask_bits_alias,
  input  [43:0] io_aMergeTask_bits_vaddr,
  input         io_aMergeTask_bits_isKeyword,
  input  [3:0]  io_aMergeTask_bits_opcode,
  input  [2:0]  io_aMergeTask_bits_param,
  input  [6:0]  io_aMergeTask_bits_sourceId,
  input         io_replResp_valid,
  input  [30:0] io_replResp_bits_tag,
  input  [2:0]  io_replResp_bits_way,
  input         io_replResp_bits_meta_dirty,
  input  [1:0]  io_replResp_bits_meta_state,
  input         io_replResp_bits_meta_clients,
  input  [1:0]  io_replResp_bits_meta_alias,
  input         io_replResp_bits_meta_prefetch,
  input  [2:0]  io_replResp_bits_meta_prefetchSrc,
  input         io_replResp_bits_meta_accessed,
  input         io_replResp_bits_meta_tagErr,
  input         io_replResp_bits_meta_dataErr,
  input         io_replResp_bits_retry,
  input         io_replResp_bits_error,
  output        io_pCrd_query_valid,
  output [3:0]  io_pCrd_query_bits_pCrdType,
  output [10:0] io_pCrd_query_bits_srcID,
  input         io_pCrd_grant,
  input         io_dsResp_valid,
  input         io_dsResp_bits_dataError,
  output        acquire_period_valid,
  output [63:0] acquire_period_bits,
  output        release_period_valid,
  output [63:0] release_period_bits
);
  xs_MSHR_core u_core (
    .clock                                                (clock),
    .reset                                                (reset),
    .io_id                                                (io_id),
    .io_status_valid                                      (io_status_valid),
    .io_status_bits_channel                               (io_status_bits_channel),
    .io_status_bits_set                                   (io_status_bits_set),
    .io_status_bits_reqTag                                (io_status_bits_reqTag),
    .io_status_bits_metaTag                               (io_status_bits_metaTag),
    .io_status_bits_needsRepl                             (io_status_bits_needsRepl),
    .io_status_bits_w_c_resp                              (io_status_bits_w_c_resp),
    .io_status_bits_will_free                             (io_status_bits_will_free),
    .io_status_bits_reqSource                             (io_status_bits_reqSource),
    .io_status_bits_is_miss                               (io_status_bits_is_miss),
    .io_status_bits_is_prefetch                           (io_status_bits_is_prefetch),
    .io_statAlloc_valid                                   (io_statAlloc_valid),
    .io_statAlloc_bits_channel                            (io_statAlloc_bits_channel),
    .io_statAlloc_bits_is_miss                            (io_statAlloc_bits_is_miss),
    .io_statAlloc_bits_is_prefetch                        (io_statAlloc_bits_is_prefetch),
    .io_msInfo_valid                                      (io_msInfo_valid),
    .io_msInfo_bits_channel                               (io_msInfo_bits_channel),
    .io_msInfo_bits_set                                   (io_msInfo_bits_set),
    .io_msInfo_bits_way                                   (io_msInfo_bits_way),
    .io_msInfo_bits_reqTag                                (io_msInfo_bits_reqTag),
    .io_msInfo_bits_willFree                              (io_msInfo_bits_willFree),
    .io_msInfo_bits_aliasTask                             (io_msInfo_bits_aliasTask),
    .io_msInfo_bits_needRelease                           (io_msInfo_bits_needRelease),
    .io_msInfo_bits_blockRefill                           (io_msInfo_bits_blockRefill),
    .io_msInfo_bits_meta_dirty                            (io_msInfo_bits_meta_dirty),
    .io_msInfo_bits_meta_state                            (io_msInfo_bits_meta_state),
    .io_msInfo_bits_meta_clients                          (io_msInfo_bits_meta_clients),
    .io_msInfo_bits_meta_alias                            (io_msInfo_bits_meta_alias),
    .io_msInfo_bits_meta_prefetch                         (io_msInfo_bits_meta_prefetch),
    .io_msInfo_bits_meta_prefetchSrc                      (io_msInfo_bits_meta_prefetchSrc),
    .io_msInfo_bits_meta_accessed                         (io_msInfo_bits_meta_accessed),
    .io_msInfo_bits_meta_tagErr                           (io_msInfo_bits_meta_tagErr),
    .io_msInfo_bits_meta_dataErr                          (io_msInfo_bits_meta_dataErr),
    .io_msInfo_bits_metaTag                               (io_msInfo_bits_metaTag),
    .io_msInfo_bits_dirHit                                (io_msInfo_bits_dirHit),
    .io_msInfo_bits_isAcqOrPrefetch                       (io_msInfo_bits_isAcqOrPrefetch),
    .io_msInfo_bits_isPrefetch                            (io_msInfo_bits_isPrefetch),
    .io_msInfo_bits_param                                 (io_msInfo_bits_param),
    .io_msInfo_bits_mergeA                                (io_msInfo_bits_mergeA),
    .io_msInfo_bits_w_grantfirst                          (io_msInfo_bits_w_grantfirst),
    .io_msInfo_bits_s_release                             (io_msInfo_bits_s_release),
    .io_msInfo_bits_s_refill                              (io_msInfo_bits_s_refill),
    .io_msInfo_bits_s_cmoresp                             (io_msInfo_bits_s_cmoresp),
    .io_msInfo_bits_s_cmometaw                            (io_msInfo_bits_s_cmometaw),
    .io_msInfo_bits_w_releaseack                          (io_msInfo_bits_w_releaseack),
    .io_msInfo_bits_w_replResp                            (io_msInfo_bits_w_replResp),
    .io_msInfo_bits_w_rprobeacklast                       (io_msInfo_bits_w_rprobeacklast),
    .io_msInfo_bits_replaceData                           (io_msInfo_bits_replaceData),
    .io_msInfo_bits_releaseToClean                        (io_msInfo_bits_releaseToClean),
    .io_alloc_valid                                       (io_alloc_valid),
    .io_alloc_bits_dirResult_hit                          (io_alloc_bits_dirResult_hit),
    .io_alloc_bits_dirResult_tag                          (io_alloc_bits_dirResult_tag),
    .io_alloc_bits_dirResult_set                          (io_alloc_bits_dirResult_set),
    .io_alloc_bits_dirResult_way                          (io_alloc_bits_dirResult_way),
    .io_alloc_bits_dirResult_meta_dirty                   (io_alloc_bits_dirResult_meta_dirty),
    .io_alloc_bits_dirResult_meta_state                   (io_alloc_bits_dirResult_meta_state),
    .io_alloc_bits_dirResult_meta_clients                 (io_alloc_bits_dirResult_meta_clients),
    .io_alloc_bits_dirResult_meta_alias                   (io_alloc_bits_dirResult_meta_alias),
    .io_alloc_bits_dirResult_meta_prefetch                (io_alloc_bits_dirResult_meta_prefetch),
    .io_alloc_bits_dirResult_meta_prefetchSrc             (io_alloc_bits_dirResult_meta_prefetchSrc),
    .io_alloc_bits_dirResult_meta_accessed                (io_alloc_bits_dirResult_meta_accessed),
    .io_alloc_bits_dirResult_meta_tagErr                  (io_alloc_bits_dirResult_meta_tagErr),
    .io_alloc_bits_dirResult_meta_dataErr                 (io_alloc_bits_dirResult_meta_dataErr),
    .io_alloc_bits_dirResult_error                        (io_alloc_bits_dirResult_error),
    .io_alloc_bits_state_s_acquire                        (io_alloc_bits_state_s_acquire),
    .io_alloc_bits_state_s_rprobe                         (io_alloc_bits_state_s_rprobe),
    .io_alloc_bits_state_s_pprobe                         (io_alloc_bits_state_s_pprobe),
    .io_alloc_bits_state_s_release                        (io_alloc_bits_state_s_release),
    .io_alloc_bits_state_s_probeack                       (io_alloc_bits_state_s_probeack),
    .io_alloc_bits_state_s_refill                         (io_alloc_bits_state_s_refill),
    .io_alloc_bits_state_s_cmoresp                        (io_alloc_bits_state_s_cmoresp),
    .io_alloc_bits_state_w_rprobeackfirst                 (io_alloc_bits_state_w_rprobeackfirst),
    .io_alloc_bits_state_w_rprobeacklast                  (io_alloc_bits_state_w_rprobeacklast),
    .io_alloc_bits_state_w_pprobeackfirst                 (io_alloc_bits_state_w_pprobeackfirst),
    .io_alloc_bits_state_w_pprobeacklast                  (io_alloc_bits_state_w_pprobeacklast),
    .io_alloc_bits_state_w_grantfirst                     (io_alloc_bits_state_w_grantfirst),
    .io_alloc_bits_state_w_grantlast                      (io_alloc_bits_state_w_grantlast),
    .io_alloc_bits_state_w_grant                          (io_alloc_bits_state_w_grant),
    .io_alloc_bits_state_w_releaseack                     (io_alloc_bits_state_w_releaseack),
    .io_alloc_bits_state_w_replResp                       (io_alloc_bits_state_w_replResp),
    .io_alloc_bits_state_s_rcompack                       (io_alloc_bits_state_s_rcompack),
    .io_alloc_bits_state_s_dct                            (io_alloc_bits_state_s_dct),
    .io_alloc_bits_task_channel                           (io_alloc_bits_task_channel),
    .io_alloc_bits_task_set                               (io_alloc_bits_task_set),
    .io_alloc_bits_task_tag                               (io_alloc_bits_task_tag),
    .io_alloc_bits_task_off                               (io_alloc_bits_task_off),
    .io_alloc_bits_task_alias                             (io_alloc_bits_task_alias),
    .io_alloc_bits_task_isKeyword                         (io_alloc_bits_task_isKeyword),
    .io_alloc_bits_task_opcode                            (io_alloc_bits_task_opcode),
    .io_alloc_bits_task_param                             (io_alloc_bits_task_param),
    .io_alloc_bits_task_sourceId                          (io_alloc_bits_task_sourceId),
    .io_alloc_bits_task_denied                            (io_alloc_bits_task_denied),
    .io_alloc_bits_task_corrupt                           (io_alloc_bits_task_corrupt),
    .io_alloc_bits_task_aliasTask                         (io_alloc_bits_task_aliasTask),
    .io_alloc_bits_task_fromL2pft                         (io_alloc_bits_task_fromL2pft),
    .io_alloc_bits_task_reqSource                         (io_alloc_bits_task_reqSource),
    .io_alloc_bits_task_snpHitRelease                     (io_alloc_bits_task_snpHitRelease),
    .io_alloc_bits_task_snpHitReleaseToInval              (io_alloc_bits_task_snpHitReleaseToInval),
    .io_alloc_bits_task_snpHitReleaseToClean              (io_alloc_bits_task_snpHitReleaseToClean),
    .io_alloc_bits_task_snpHitReleaseWithData             (io_alloc_bits_task_snpHitReleaseWithData),
    .io_alloc_bits_task_snpHitReleaseIdx                  (io_alloc_bits_task_snpHitReleaseIdx),
    .io_alloc_bits_task_snpHitReleaseMeta_dirty           (io_alloc_bits_task_snpHitReleaseMeta_dirty),
    .io_alloc_bits_task_snpHitReleaseMeta_state           (io_alloc_bits_task_snpHitReleaseMeta_state),
    .io_alloc_bits_task_snpHitReleaseMeta_clients         (io_alloc_bits_task_snpHitReleaseMeta_clients),
    .io_alloc_bits_task_snpHitReleaseMeta_alias           (io_alloc_bits_task_snpHitReleaseMeta_alias),
    .io_alloc_bits_task_snpHitReleaseMeta_prefetch        (io_alloc_bits_task_snpHitReleaseMeta_prefetch),
    .io_alloc_bits_task_snpHitReleaseMeta_prefetchSrc     (io_alloc_bits_task_snpHitReleaseMeta_prefetchSrc),
    .io_alloc_bits_task_snpHitReleaseMeta_accessed        (io_alloc_bits_task_snpHitReleaseMeta_accessed),
    .io_alloc_bits_task_snpHitReleaseMeta_tagErr          (io_alloc_bits_task_snpHitReleaseMeta_tagErr),
    .io_alloc_bits_task_snpHitReleaseMeta_dataErr         (io_alloc_bits_task_snpHitReleaseMeta_dataErr),
    .io_alloc_bits_task_srcID                             (io_alloc_bits_task_srcID),
    .io_alloc_bits_task_txnID                             (io_alloc_bits_task_txnID),
    .io_alloc_bits_task_fwdNID                            (io_alloc_bits_task_fwdNID),
    .io_alloc_bits_task_fwdTxnID                          (io_alloc_bits_task_fwdTxnID),
    .io_alloc_bits_task_chiOpcode                         (io_alloc_bits_task_chiOpcode),
    .io_alloc_bits_task_retToSrc                          (io_alloc_bits_task_retToSrc),
    .io_alloc_bits_task_traceTag                          (io_alloc_bits_task_traceTag),
    .io_tasks_txreq_ready                                 (io_tasks_txreq_ready),
    .io_tasks_txreq_valid                                 (io_tasks_txreq_valid),
    .io_tasks_txreq_bits_tgtID                            (io_tasks_txreq_bits_tgtID),
    .io_tasks_txreq_bits_txnID                            (io_tasks_txreq_bits_txnID),
    .io_tasks_txreq_bits_opcode                           (io_tasks_txreq_bits_opcode),
    .io_tasks_txreq_bits_addr                             (io_tasks_txreq_bits_addr),
    .io_tasks_txreq_bits_likelyshared                     (io_tasks_txreq_bits_likelyshared),
    .io_tasks_txreq_bits_allowRetry                       (io_tasks_txreq_bits_allowRetry),
    .io_tasks_txreq_bits_pCrdType                         (io_tasks_txreq_bits_pCrdType),
    .io_tasks_txreq_bits_memAttr_allocate                 (io_tasks_txreq_bits_memAttr_allocate),
    .io_tasks_txreq_bits_expCompAck                       (io_tasks_txreq_bits_expCompAck),
    .io_tasks_txrsp_ready                                 (io_tasks_txrsp_ready),
    .io_tasks_txrsp_valid                                 (io_tasks_txrsp_valid),
    .io_tasks_txrsp_bits_tgtID                            (io_tasks_txrsp_bits_tgtID),
    .io_tasks_txrsp_bits_txnID                            (io_tasks_txrsp_bits_txnID),
    .io_tasks_txrsp_bits_traceTag                         (io_tasks_txrsp_bits_traceTag),
    .io_tasks_source_b_ready                              (io_tasks_source_b_ready),
    .io_tasks_source_b_valid                              (io_tasks_source_b_valid),
    .io_tasks_source_b_bits_tag                           (io_tasks_source_b_bits_tag),
    .io_tasks_source_b_bits_set                           (io_tasks_source_b_bits_set),
    .io_tasks_source_b_bits_param                         (io_tasks_source_b_bits_param),
    .io_tasks_source_b_bits_alias                         (io_tasks_source_b_bits_alias),
    .io_tasks_mainpipe_ready                              (io_tasks_mainpipe_ready),
    .io_tasks_mainpipe_valid                              (io_tasks_mainpipe_valid),
    .io_tasks_mainpipe_bits_channel                       (io_tasks_mainpipe_bits_channel),
    .io_tasks_mainpipe_bits_txChannel                     (io_tasks_mainpipe_bits_txChannel),
    .io_tasks_mainpipe_bits_set                           (io_tasks_mainpipe_bits_set),
    .io_tasks_mainpipe_bits_tag                           (io_tasks_mainpipe_bits_tag),
    .io_tasks_mainpipe_bits_off                           (io_tasks_mainpipe_bits_off),
    .io_tasks_mainpipe_bits_alias                         (io_tasks_mainpipe_bits_alias),
    .io_tasks_mainpipe_bits_isKeyword                     (io_tasks_mainpipe_bits_isKeyword),
    .io_tasks_mainpipe_bits_opcode                        (io_tasks_mainpipe_bits_opcode),
    .io_tasks_mainpipe_bits_param                         (io_tasks_mainpipe_bits_param),
    .io_tasks_mainpipe_bits_size                          (io_tasks_mainpipe_bits_size),
    .io_tasks_mainpipe_bits_sourceId                      (io_tasks_mainpipe_bits_sourceId),
    .io_tasks_mainpipe_bits_denied                        (io_tasks_mainpipe_bits_denied),
    .io_tasks_mainpipe_bits_corrupt                       (io_tasks_mainpipe_bits_corrupt),
    .io_tasks_mainpipe_bits_mshrId                        (io_tasks_mainpipe_bits_mshrId),
    .io_tasks_mainpipe_bits_aliasTask                     (io_tasks_mainpipe_bits_aliasTask),
    .io_tasks_mainpipe_bits_useProbeData                  (io_tasks_mainpipe_bits_useProbeData),
    .io_tasks_mainpipe_bits_mshrRetry                     (io_tasks_mainpipe_bits_mshrRetry),
    .io_tasks_mainpipe_bits_readProbeDataDown             (io_tasks_mainpipe_bits_readProbeDataDown),
    .io_tasks_mainpipe_bits_fromL2pft                     (io_tasks_mainpipe_bits_fromL2pft),
    .io_tasks_mainpipe_bits_dirty                         (io_tasks_mainpipe_bits_dirty),
    .io_tasks_mainpipe_bits_way                           (io_tasks_mainpipe_bits_way),
    .io_tasks_mainpipe_bits_meta_dirty                    (io_tasks_mainpipe_bits_meta_dirty),
    .io_tasks_mainpipe_bits_meta_state                    (io_tasks_mainpipe_bits_meta_state),
    .io_tasks_mainpipe_bits_meta_clients                  (io_tasks_mainpipe_bits_meta_clients),
    .io_tasks_mainpipe_bits_meta_alias                    (io_tasks_mainpipe_bits_meta_alias),
    .io_tasks_mainpipe_bits_meta_prefetch                 (io_tasks_mainpipe_bits_meta_prefetch),
    .io_tasks_mainpipe_bits_meta_prefetchSrc              (io_tasks_mainpipe_bits_meta_prefetchSrc),
    .io_tasks_mainpipe_bits_meta_accessed                 (io_tasks_mainpipe_bits_meta_accessed),
    .io_tasks_mainpipe_bits_meta_tagErr                   (io_tasks_mainpipe_bits_meta_tagErr),
    .io_tasks_mainpipe_bits_meta_dataErr                  (io_tasks_mainpipe_bits_meta_dataErr),
    .io_tasks_mainpipe_bits_metaWen                       (io_tasks_mainpipe_bits_metaWen),
    .io_tasks_mainpipe_bits_tagWen                        (io_tasks_mainpipe_bits_tagWen),
    .io_tasks_mainpipe_bits_dsWen                         (io_tasks_mainpipe_bits_dsWen),
    .io_tasks_mainpipe_bits_replTask                      (io_tasks_mainpipe_bits_replTask),
    .io_tasks_mainpipe_bits_cmoTask                       (io_tasks_mainpipe_bits_cmoTask),
    .io_tasks_mainpipe_bits_reqSource                     (io_tasks_mainpipe_bits_reqSource),
    .io_tasks_mainpipe_bits_mergeA                        (io_tasks_mainpipe_bits_mergeA),
    .io_tasks_mainpipe_bits_aMergeTask_off                (io_tasks_mainpipe_bits_aMergeTask_off),
    .io_tasks_mainpipe_bits_aMergeTask_alias              (io_tasks_mainpipe_bits_aMergeTask_alias),
    .io_tasks_mainpipe_bits_aMergeTask_vaddr              (io_tasks_mainpipe_bits_aMergeTask_vaddr),
    .io_tasks_mainpipe_bits_aMergeTask_isKeyword          (io_tasks_mainpipe_bits_aMergeTask_isKeyword),
    .io_tasks_mainpipe_bits_aMergeTask_opcode             (io_tasks_mainpipe_bits_aMergeTask_opcode),
    .io_tasks_mainpipe_bits_aMergeTask_param              (io_tasks_mainpipe_bits_aMergeTask_param),
    .io_tasks_mainpipe_bits_aMergeTask_sourceId           (io_tasks_mainpipe_bits_aMergeTask_sourceId),
    .io_tasks_mainpipe_bits_aMergeTask_meta_dirty         (io_tasks_mainpipe_bits_aMergeTask_meta_dirty),
    .io_tasks_mainpipe_bits_aMergeTask_meta_state         (io_tasks_mainpipe_bits_aMergeTask_meta_state),
    .io_tasks_mainpipe_bits_aMergeTask_meta_clients       (io_tasks_mainpipe_bits_aMergeTask_meta_clients),
    .io_tasks_mainpipe_bits_aMergeTask_meta_alias         (io_tasks_mainpipe_bits_aMergeTask_meta_alias),
    .io_tasks_mainpipe_bits_aMergeTask_meta_accessed      (io_tasks_mainpipe_bits_aMergeTask_meta_accessed),
    .io_tasks_mainpipe_bits_snpHitRelease                 (io_tasks_mainpipe_bits_snpHitRelease),
    .io_tasks_mainpipe_bits_snpHitReleaseToInval          (io_tasks_mainpipe_bits_snpHitReleaseToInval),
    .io_tasks_mainpipe_bits_snpHitReleaseToClean          (io_tasks_mainpipe_bits_snpHitReleaseToClean),
    .io_tasks_mainpipe_bits_snpHitReleaseWithData         (io_tasks_mainpipe_bits_snpHitReleaseWithData),
    .io_tasks_mainpipe_bits_snpHitReleaseIdx              (io_tasks_mainpipe_bits_snpHitReleaseIdx),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty       (io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_state       (io_tasks_mainpipe_bits_snpHitReleaseMeta_state),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_clients     (io_tasks_mainpipe_bits_snpHitReleaseMeta_clients),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_alias       (io_tasks_mainpipe_bits_snpHitReleaseMeta_alias),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch    (io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc (io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed    (io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr      (io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr),
    .io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr     (io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr),
    .io_tasks_mainpipe_bits_tgtID                         (io_tasks_mainpipe_bits_tgtID),
    .io_tasks_mainpipe_bits_txnID                         (io_tasks_mainpipe_bits_txnID),
    .io_tasks_mainpipe_bits_homeNID                       (io_tasks_mainpipe_bits_homeNID),
    .io_tasks_mainpipe_bits_dbID                          (io_tasks_mainpipe_bits_dbID),
    .io_tasks_mainpipe_bits_chiOpcode                     (io_tasks_mainpipe_bits_chiOpcode),
    .io_tasks_mainpipe_bits_resp                          (io_tasks_mainpipe_bits_resp),
    .io_tasks_mainpipe_bits_fwdState                      (io_tasks_mainpipe_bits_fwdState),
    .io_tasks_mainpipe_bits_retToSrc                      (io_tasks_mainpipe_bits_retToSrc),
    .io_tasks_mainpipe_bits_likelyshared                  (io_tasks_mainpipe_bits_likelyshared),
    .io_tasks_mainpipe_bits_expCompAck                    (io_tasks_mainpipe_bits_expCompAck),
    .io_tasks_mainpipe_bits_allowRetry                    (io_tasks_mainpipe_bits_allowRetry),
    .io_tasks_mainpipe_bits_memAttr_allocate              (io_tasks_mainpipe_bits_memAttr_allocate),
    .io_tasks_mainpipe_bits_memAttr_cacheable             (io_tasks_mainpipe_bits_memAttr_cacheable),
    .io_tasks_mainpipe_bits_memAttr_ewa                   (io_tasks_mainpipe_bits_memAttr_ewa),
    .io_tasks_mainpipe_bits_traceTag                      (io_tasks_mainpipe_bits_traceTag),
    .io_resps_sinkC_valid                                 (io_resps_sinkC_valid),
    .io_resps_sinkC_bits_opcode                           (io_resps_sinkC_bits_opcode),
    .io_resps_sinkC_bits_param                            (io_resps_sinkC_bits_param),
    .io_resps_sinkC_bits_last                             (io_resps_sinkC_bits_last),
    .io_resps_sinkC_bits_denied                           (io_resps_sinkC_bits_denied),
    .io_resps_sinkC_bits_corrupt                          (io_resps_sinkC_bits_corrupt),
    .io_resps_rxrsp_valid                                 (io_resps_rxrsp_valid),
    .io_resps_rxrsp_bits_chiOpcode                        (io_resps_rxrsp_bits_chiOpcode),
    .io_resps_rxrsp_bits_srcID                            (io_resps_rxrsp_bits_srcID),
    .io_resps_rxrsp_bits_dbID                             (io_resps_rxrsp_bits_dbID),
    .io_resps_rxrsp_bits_resp                             (io_resps_rxrsp_bits_resp),
    .io_resps_rxrsp_bits_pCrdType                         (io_resps_rxrsp_bits_pCrdType),
    .io_resps_rxrsp_bits_respErr                          (io_resps_rxrsp_bits_respErr),
    .io_resps_rxrsp_bits_traceTag                         (io_resps_rxrsp_bits_traceTag),
    .io_resps_rxdat_valid                                 (io_resps_rxdat_valid),
    .io_resps_rxdat_bits_corrupt                          (io_resps_rxdat_bits_corrupt),
    .io_resps_rxdat_bits_chiOpcode                        (io_resps_rxdat_bits_chiOpcode),
    .io_resps_rxdat_bits_homeNID                          (io_resps_rxdat_bits_homeNID),
    .io_resps_rxdat_bits_dbID                             (io_resps_rxdat_bits_dbID),
    .io_resps_rxdat_bits_resp                             (io_resps_rxdat_bits_resp),
    .io_resps_rxdat_bits_respErr                          (io_resps_rxdat_bits_respErr),
    .io_resps_rxdat_bits_traceTag                         (io_resps_rxdat_bits_traceTag),
    .io_nestedwb_set                                      (io_nestedwb_set),
    .io_nestedwb_tag                                      (io_nestedwb_tag),
    .io_nestedwb_c_set_dirty                              (io_nestedwb_c_set_dirty),
    .io_nestedwb_c_set_tip                                (io_nestedwb_c_set_tip),
    .io_nestedwb_b_inv_dirty                              (io_nestedwb_b_inv_dirty),
    .io_nestedwb_b_toB                                    (io_nestedwb_b_toB),
    .io_nestedwb_b_toN                                    (io_nestedwb_b_toN),
    .io_nestedwb_b_toClean                                (io_nestedwb_b_toClean),
    .io_nestedwb_denied                                   (io_nestedwb_denied),
    .io_nestedwb_corrupt                                  (io_nestedwb_corrupt),
    .io_nestedwbData                                      (io_nestedwbData),
    .io_aMergeTask_valid                                  (io_aMergeTask_valid),
    .io_aMergeTask_bits_off                               (io_aMergeTask_bits_off),
    .io_aMergeTask_bits_alias                             (io_aMergeTask_bits_alias),
    .io_aMergeTask_bits_vaddr                             (io_aMergeTask_bits_vaddr),
    .io_aMergeTask_bits_isKeyword                         (io_aMergeTask_bits_isKeyword),
    .io_aMergeTask_bits_opcode                            (io_aMergeTask_bits_opcode),
    .io_aMergeTask_bits_param                             (io_aMergeTask_bits_param),
    .io_aMergeTask_bits_sourceId                          (io_aMergeTask_bits_sourceId),
    .io_replResp_valid                                    (io_replResp_valid),
    .io_replResp_bits_tag                                 (io_replResp_bits_tag),
    .io_replResp_bits_way                                 (io_replResp_bits_way),
    .io_replResp_bits_meta_dirty                          (io_replResp_bits_meta_dirty),
    .io_replResp_bits_meta_state                          (io_replResp_bits_meta_state),
    .io_replResp_bits_meta_clients                        (io_replResp_bits_meta_clients),
    .io_replResp_bits_meta_alias                          (io_replResp_bits_meta_alias),
    .io_replResp_bits_meta_prefetch                       (io_replResp_bits_meta_prefetch),
    .io_replResp_bits_meta_prefetchSrc                    (io_replResp_bits_meta_prefetchSrc),
    .io_replResp_bits_meta_accessed                       (io_replResp_bits_meta_accessed),
    .io_replResp_bits_meta_tagErr                         (io_replResp_bits_meta_tagErr),
    .io_replResp_bits_meta_dataErr                        (io_replResp_bits_meta_dataErr),
    .io_replResp_bits_retry                               (io_replResp_bits_retry),
    .io_replResp_bits_error                               (io_replResp_bits_error),
    .io_pCrd_query_valid                                  (io_pCrd_query_valid),
    .io_pCrd_query_bits_pCrdType                          (io_pCrd_query_bits_pCrdType),
    .io_pCrd_query_bits_srcID                             (io_pCrd_query_bits_srcID),
    .io_pCrd_grant                                        (io_pCrd_grant),
    .io_dsResp_valid                                      (io_dsResp_valid),
    .io_dsResp_bits_dataError                             (io_dsResp_bits_dataError),
    .acquire_period_valid                                 (acquire_period_valid),
    .acquire_period_bits                                  (acquire_period_bits),
    .release_period_valid                                 (release_period_valid),
    .release_period_bits                                  (release_period_bits)
  );
endmodule
// END GENERATED(wrapper)
