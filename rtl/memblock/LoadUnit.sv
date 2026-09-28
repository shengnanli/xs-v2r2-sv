// =====================================================================
// LoadUnit.sv —— 标量/向量 load 的 4 级访存流水（s0 选源发请求 → s1 TLB → s2 DCache → s3 写回）
// ---------------------------------------------------------------------
// 位置：MemBlock 里 3 条完全相同的 load 流水（inner_LoadUnit_0/1/2 都例化本模块）。
//   上游：发射队列（ldin 标量首发 / vecldin 向量元素）、LoadQueueReplay（replay 重发）、
//         自己 s3 的快速重发（fast_rep_in）、非对齐缓冲（misalign_ldin）、MMIO / NC 回来的
//         uncache 包（lsq_uncache / lsq_nc_ldin）、L1 硬件预取（prefetch_req）。
//   下游：DTLB、DCache、store queue / sbuffer / ubuffer 前递、LSQ（写 load queue、RAR/RAW
//         违例队列）、写回总线（ldout / vecldout）、发射队列反馈、回滚（rollback）。
// 每一级做什么（详见各节开头）：
//   s0 从 11 路来源里按固定优先级选一路，算虚地址、查非对齐，发 DTLB + DCache 请求；
//   s1 拿 TLB 结果：物理地址 / 页异常 / Svpbmt 属性，发 store→load 前递查询，查 st-ld 违例，
//      跑调试触发器（MemTrigger 子模块）；
//   s2 拿 DCache 与各路前递结果：合并前递数据，判定 PMP/PMA 异常与 MMIO/NC，
//      把"为什么这条 load 还不能完成"归结成 11 种 replay 原因之一，登记 RAR/RAW 队列；
//   s3 写回：命中者直接写回（标量 ldout / 向量 vecldout），否则写 load queue 等重发，
//      或走快速重发、进非对齐缓冲、或触发回滚；MMIO 写回也在这一拍与主流水共用写回口。
// 本配置（KunminghuV2Config）：load-to-load 指针追逐前递关闭（EnableLoadToLoadForward=false），
//   第 9 路来源恒无效；精确 ECC 延迟错误关闭；wpu（路预测）失败恒 0。
// 文件结构：loadunit_pkg → xs_LoadUnit_core（手写可读核）→ golden 同名 wrapper（生成）。
//   GENERATED 段由 verif/ut/LoadUnit/gen_loadunit.py 从 golden 端口表/寄存器表生成：
//   types（接口 struct）、core_ports（核端口表）、pipe_regs（整包打拍寄存器）、wrapper。
// =====================================================================
// 本文件导航（按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位；行号由生成器维护）：
// BEGIN GENERATED(nav) —— verif/ut/LoadUnit/gen_loadunit.py 生成，勿手改
//   L40    loadunit_pkg：常量、FlowSource、小工具函数
//   L809   xs_LoadUnit_core —— 可读核
//   L955   s0：11 路来源选一路，发 DTLB / DCache 请求
//   L1364  s1：TLB 应答、前递查询、st-ld 违例、调试触发器
//   L1594  s2：DCache 应答、前递合并、异常与 replay 原因
//   L1998  s3：写回 / 写 LQ / 快速重发 / 非对齐 / 回滚
//   L2311  性能事件
//   L2349  整包打拍寄存器（生成）
//   L4995  golden 同名 wrapper（生成）
// END GENERATED(nav)
// =====================================================================

package loadunit_pkg;

  // ---------------- 流水宽度与地址参数 ----------------
  localparam int VADDR_W   = 50;    // VAddrBits
  localparam int PADDR_W   = 48;    // PAddrBits
  localparam int XLEN      = 64;
  localparam int VLEN_B    = 16;    // VLEN/8：一次访问最多 16 字节
  localparam int SQ_SIZE   = 56;    // StoreQueueSize：sqIdxMask 的宽度

  // ---------------- s0 的 11 路 load 来源（下标 = 优先级，越小越优先）----------------
  localparam int SRC_MAB       = 0;   // 非对齐缓冲拆出的子访问（最高优先级）
  localparam int SRC_SUPER_REP = 1;   // LQ 重发里"等 D 通道回填"的 cache miss（可直接前递）
  localparam int SRC_FAST_REP  = 2;   // 本流水 s3 的快速重发
  localparam int SRC_LSQ_REP   = 3;   // LQ 普通重发
  localparam int SRC_HIGH_PF   = 4;   // 高置信硬件预取
  localparam int SRC_VEC       = 5;   // 向量 load 元素
  localparam int SRC_INT       = 6;   // 标量 load 首发（含软件 prefetch）
  localparam int SRC_MMIO      = 7;   // MMIO load 带数据回来（只借写回口，不访存）
  localparam int SRC_NC        = 8;   // NC load 带数据回来（要做前递与违例检查）
  localparam int SRC_L2L       = 9;   // load-to-load 指针追逐（本配置关闭，恒无效）
  localparam int SRC_LOW_PF    = 10;  // 低置信硬件预取（最低优先级）
  localparam int NUM_SRC       = 11;

  // ---------------- LSUOpType（xiangshan/package.scala）----------------
  localparam logic [8:0] OP_LB     = 9'h00;
  localparam logic [8:0] OP_LH     = 9'h01;
  localparam logic [8:0] OP_LW     = 9'h02;
  localparam logic [8:0] OP_LD     = 9'h03;
  localparam logic [8:0] OP_LBU    = 9'h04;
  localparam logic [8:0] OP_LHU    = 9'h05;
  localparam logic [8:0] OP_LWU    = 9'h06;
  localparam logic [8:0] OP_PREF_I = 9'h08;   // prefetch.i
  localparam logic [8:0] OP_PREF_R = 9'h09;   // prefetch.r
  localparam logic [8:0] OP_PREF_W = 9'h0A;   // prefetch.w
  localparam logic [8:0] OP_HLVB   = 9'h10;
  localparam logic [8:0] OP_HLVH   = 9'h11;
  localparam logic [8:0] OP_HLVW   = 9'h12;
  localparam logic [8:0] OP_HLVD   = 9'h13;
  localparam logic [8:0] OP_HLVBU  = 9'h14;
  localparam logic [8:0] OP_HLVHU  = 9'h15;
  localparam logic [8:0] OP_HLVWU  = 9'h16;
  localparam logic [8:0] OP_HLVXHU = 9'h1D;
  localparam logic [8:0] OP_HLVXWU = 9'h1E;

  // ---------------- 异常号（ExceptionNO）：LDU 只产生/关心这 6 个 ----------------
  localparam int EXC_BREAKPOINT = 3;    // breakPoint（调试触发器）
  localparam int EXC_LD_MISALIGN = 4;   // loadAddrMisaligned
  localparam int EXC_LD_ACCESS  = 5;    // loadAccessFault
  localparam int EXC_LD_PAGE    = 13;   // loadPageFault
  localparam int EXC_HW_ERROR   = 19;   // hardwareError（ECC / 总线 corrupt）
  localparam int EXC_LD_GUEST_PAGE = 21;  // loadGuestPageFault
  // ExceptionNO.selectByFu(_, LduCfg/VlduCfg)：只保留上面 6 位
  localparam logic [23:0] LDU_EXC_MASK = (24'h1 << EXC_BREAKPOINT) | (24'h1 << EXC_LD_MISALIGN)
                                       | (24'h1 << EXC_LD_ACCESS)  | (24'h1 << EXC_LD_PAGE)
                                       | (24'h1 << EXC_HW_ERROR)   | (24'h1 << EXC_LD_GUEST_PAGE);

  // ---------------- replay 原因（LoadReplayCauses，下标即优先级）----------------
  localparam int C_MA  = 0;    // mem_amb：store 地址还没算出来（memory ambiguity）
  localparam int C_TM  = 1;    // tlb_miss
  localparam int C_FF  = 2;    // fwd_fail：store 地址匹配但数据未就绪
  localparam int C_DR  = 3;    // dcache_rep：DCache 缺失队列满（mq nack）
  localparam int C_DM  = 4;    // dcache_miss
  localparam int C_WF  = 5;    // wpu_fail：路预测失败（本配置恒 0）
  localparam int C_BC  = 6;    // bank_conflict
  localparam int C_RAR = 7;    // rar_nack：RAR 违例队列满
  localparam int C_RAW = 8;    // raw_nack：RAW 违例队列满
  localparam int C_NK  = 9;    // nuke：被更老的 store 撞上（st-ld 违例）
  localparam int C_MF  = 10;   // misalign_nack：非对齐缓冲不收
  localparam int NUM_CAUSE = 11;

  // ---------------- 其它编码 ----------------
  localparam logic [1:0] PBMT_PMA = 2'd0;   // Svpbmt：按 PMA
  localparam logic [1:0] PBMT_NC  = 2'd1;   // 非缓存、可合并
  localparam logic [1:0] PBMT_IO  = 2'd2;   // I/O
  localparam logic [1:0] ST_MATCH_NORMAL    = 2'd0;  // StLdNukeMatchType：8 字节
  localparam logic [1:0] ST_MATCH_QUADWORD  = 2'd1;  //                   16 字节
  localparam logic [1:0] ST_MATCH_CACHELINE = 2'd2;  //                   整行（64B）
  localparam logic [3:0] TRIG_ACT_BREAKPOINT = 4'h0;  // TriggerAction.BreakpointExp
  localparam logic [3:0] TRIG_ACT_DEBUG_MODE = 4'h1;  // TriggerAction.DebugMode
  localparam logic [2:0] TLB_CMD_READ  = 3'd0;
  localparam logic [2:0] TLB_CMD_WRITE = 3'd1;
  localparam logic [4:0] M_XRD = 5'd0;       // DCache 命令：普通读
  localparam logic [4:0] M_PFR = 5'd2;       //              读预取
  localparam logic [4:0] M_PFW = 5'd3;       //              写预取
  localparam logic [3:0] LOAD_SOURCE = 4'd0;              // DCache 请求来源：load
  localparam logic [3:0] DCACHE_PREFETCH_SOURCE = 4'd3;   //                  预取
  localparam logic [2:0] L1_HW_PREFETCH_NULL = 3'd0;

  // BEGIN GENERATED(types) —— verif/ut/LoadUnit/gen_loadunit.py 生成，勿手改
  // DynInst（后端微操作）在 LoadUnit 里出现过的全部字段；各接口只用其中一部分，其余在 wrapper 里补 0 / 丢弃
  typedef struct packed {
    logic [31:0]           instr;
    logic [49:0]           pc;
    logic [9:0]            foldpc;
    logic [23:0]           exceptionVec;
    logic                  isFetchMalAddr;
    logic                  hasException;
    logic [3:0]            trigger;
    logic                  preDecodeInfo_valid;
    logic                  preDecodeInfo_isRVC;
    logic [1:0]            preDecodeInfo_brType;
    logic                  preDecodeInfo_isCall;
    logic                  preDecodeInfo_isRet;
    logic                  pred_taken;
    logic                  crossPageIPFFix;
    logic                  ftqPtr_flag;
    logic [5:0]            ftqPtr_value;
    logic [3:0]            ftqOffset;
    logic                  satpFlushFirstFetchFault;
    logic [3:0]            srcType_0;
    logic [3:0]            srcType_1;
    logic [3:0]            srcType_2;
    logic [3:0]            srcType_3;
    logic [3:0]            srcType_4;
    logic [5:0]            ldest;
    logic [34:0]           fuType;
    logic [8:0]            fuOpType;
    logic                  rfWen;
    logic                  fpWen;
    logic                  vecWen;
    logic                  v0Wen;
    logic                  vlWen;
    logic                  isXSTrap;
    logic                  waitForward;
    logic                  blockBackward;
    logic                  canRobCompress;
    logic [3:0]            selImm;
    logic [31:0]           imm;
    logic [1:0]            fpu_typeTagOut;
    logic                  fpu_wflags;
    logic [1:0]            fpu_typ;
    logic [1:0]            fpu_fmt;
    logic [2:0]            fpu_rm;
    logic                  vpu_vill;
    logic                  vpu_vma;
    logic                  vpu_vta;
    logic [1:0]            vpu_vsew;
    logic [2:0]            vpu_vlmul;
    logic                  vpu_specVill;
    logic                  vpu_specVma;
    logic                  vpu_specVta;
    logic [1:0]            vpu_specVsew;
    logic [2:0]            vpu_specVlmul;
    logic                  vpu_vm;
    logic [7:0]            vpu_vstart;
    logic [2:0]            vpu_frm;
    logic                  vpu_fpu_isFpToVecInst;
    logic                  vpu_fpu_isFP32Instr;
    logic                  vpu_fpu_isFP64Instr;
    logic                  vpu_fpu_isReduction;
    logic                  vpu_fpu_isFoldTo1_2;
    logic                  vpu_fpu_isFoldTo1_4;
    logic                  vpu_fpu_isFoldTo1_8;
    logic [1:0]            vpu_vxrm;
    logic [6:0]            vpu_vuopIdx;
    logic                  vpu_lastUop;
    logic [127:0]          vpu_vmask;
    logic [7:0]            vpu_vl;
    logic [2:0]            vpu_nf;
    logic [1:0]            vpu_veew;
    logic                  vpu_isReverse;
    logic                  vpu_isExt;
    logic                  vpu_isNarrow;
    logic                  vpu_isDstMask;
    logic                  vpu_isOpMask;
    logic                  vpu_isMove;
    logic                  vpu_isDependOldVd;
    logic                  vpu_isWritePartVd;
    logic                  vpu_isVleff;
    logic                  vlsInstr;
    logic                  wfflags;
    logic                  isMove;
    logic                  isDropAmocasSta;
    logic [6:0]            uopIdx;
    logic                  isVset;
    logic                  firstUop;
    logic                  lastUop;
    logic [6:0]            numUops;
    logic [6:0]            numWB;
    logic [2:0]            commitType;
    logic                  srcState_0;
    logic                  srcState_1;
    logic                  srcState_2;
    logic                  srcState_3;
    logic                  srcState_4;
    logic [1:0]            srcLoadDependency_0_0;
    logic [1:0]            srcLoadDependency_0_1;
    logic [1:0]            srcLoadDependency_0_2;
    logic [1:0]            srcLoadDependency_1_0;
    logic [1:0]            srcLoadDependency_1_1;
    logic [1:0]            srcLoadDependency_1_2;
    logic [1:0]            srcLoadDependency_2_0;
    logic [1:0]            srcLoadDependency_2_1;
    logic [1:0]            srcLoadDependency_2_2;
    logic [1:0]            srcLoadDependency_3_0;
    logic [1:0]            srcLoadDependency_3_1;
    logic [1:0]            srcLoadDependency_3_2;
    logic [1:0]            srcLoadDependency_4_0;
    logic [1:0]            srcLoadDependency_4_1;
    logic [1:0]            srcLoadDependency_4_2;
    logic [7:0]            psrc_0;
    logic [7:0]            psrc_1;
    logic [7:0]            psrc_2;
    logic [7:0]            psrc_3;
    logic [7:0]            psrc_4;
    logic [7:0]            pdest;
    logic                  useRegCache_0;
    logic                  useRegCache_1;
    logic [4:0]            regCacheIdx_0;
    logic [4:0]            regCacheIdx_1;
    logic                  robIdx_flag;
    logic [7:0]            robIdx_value;
    logic [2:0]            instrSize;
    logic                  dirtyFs;
    logic                  dirtyVs;
    logic [3:0]            traceBlockInPipe_itype;
    logic [3:0]            traceBlockInPipe_iretire;
    logic                  traceBlockInPipe_ilastsize;
    logic                  eliminatedMove;
    logic                  snapshot;
    logic                  debugInfo_eliminatedMove;
    logic [63:0]           debugInfo_renameTime;
    logic [63:0]           debugInfo_dispatchTime;
    logic [63:0]           debugInfo_enqRsTime;
    logic [63:0]           debugInfo_selectTime;
    logic [63:0]           debugInfo_issueTime;
    logic [63:0]           debugInfo_writebackTime;
    logic [63:0]           debugInfo_runahead_checkpoint_id;
    logic [63:0]           debugInfo_tlbFirstReqTime;
    logic [63:0]           debugInfo_tlbRespTime;
    logic [55:0]           debug_seqNum_seqNum;
    logic [7:0]            debug_seqNum_uopIdx;
    logic                  storeSetHit;
    logic                  waitForRobIdx_flag;
    logic [7:0]            waitForRobIdx_value;
    logic                  loadWaitBit;
    logic                  loadWaitStrict;
    logic [4:0]            ssid;
    logic                  lqIdx_flag;
    logic [6:0]            lqIdx_value;
    logic                  sqIdx_flag;
    logic [5:0]            sqIdx_value;
    logic                  singleStep;
    logic                  replayInst;
    logic [34:0]           debug_fuType;
    logic                  debug_sim_trig;
    logic [4:0]            numLsElem;
    logic                  flushPipe;
  } uop_t;

  // LqWriteBundle（= LsPipelineBundle + rep_info + nc_with_data）：load 流水各级的"包"，也是 replay/快速重发/非对齐缓冲/LSQ 各口的载荷
  typedef struct packed {
    uop_t                  uop;
    logic [49:0]           vaddr;
    logic [63:0]           fullva;
    logic                  vaNeedExt;
    logic [47:0]           paddr;
    logic [63:0]           gpaddr;
    logic [15:0]           mask;
    logic [128:0]          data;
    logic                  miss;
    logic                  tlbMiss;
    logic                  ptwBack;
    logic                  nc;
    logic                  mmio;
    logic                  memBackTypeMM;
    logic                  isHyper;
    logic                  isForVSnonLeafPTE;
    logic                  isPrefetch;
    logic                  isHWPrefetch;
    logic                  isvec;
    logic                  is128bit;
    logic [7:0]            elemIdx;
    logic [2:0]            alignedType;
    logic [3:0]            mbIndex;
    logic [3:0]            reg_offset;
    logic [7:0]            elemIdxInsideVd;
    logic [49:0]           vecBaseVaddr;
    logic [49:0]           vecVaddrOffset;
    logic [15:0]           vecTriggerMask;
    logic                  vecActive;
    logic                  isLoadReplay;
    logic                  isFastReplay;
    logic                  isFirstIssue;
    logic                  hasROBEntry;
    logic [3:0]            mshrid;
    logic                  handledByMSHR;
    logic                  forward_tlDchannel;
    logic                  delayedLoadError;
    logic                  lateKill;
    logic                  feedbacked;
    logic [6:0]            schedIndex;
    logic                  tlbNoQuery;
    logic                  isFrmMisAlignBuf;
    logic                  isMisalign;
    logic                  isFinalSplit;
    logic                  misalignWith16Byte;
    logic                  misalignNeedWakeUp;
    logic                  updateAddrValid;
    logic [3:0]            rep_info_mshr_id;
    logic                  rep_info_full_fwd;
    logic                  rep_info_data_inv_sq_idx_flag;
    logic [5:0]            rep_info_data_inv_sq_idx_value;
    logic                  rep_info_addr_inv_sq_idx_flag;
    logic [5:0]            rep_info_addr_inv_sq_idx_value;
    logic                  rep_info_last_beat;
    logic [10:0]           rep_info_cause;
    logic [3:0]            rep_info_tlb_id;
    logic                  rep_info_tlb_full;
    logic                  nc_with_data;
  } lq_write_t;

  // 标量 load 首次发射（发射队列）：src_0=基址寄存器
  typedef struct packed {
    uop_t                  uop;
    logic [63:0]           src_0;
  } ldin_t;

  // 向量 load 拆出的元素流（VLSplit）
  typedef struct packed {
    logic [63:0]           vaddr;
    logic [49:0]           basevaddr;
    logic [15:0]           mask;
    logic [3:0]            reg_offset;
    logic [2:0]            alignedType;
    logic                  vecActive;
    uop_t                  uop;
    logic [3:0]            mBIndex;
    logic [7:0]            elemIdx;
    logic [7:0]            elemIdxInsideVd;
  } vecldin_t;

  // MemExuOutput（写回包）
  typedef struct packed {
    uop_t                  uop;
    logic                  debug_isMMIO;
    logic [47:0]           debug_paddr;
    logic [49:0]           debug_vaddr;
    logic [63:0]           data;
    logic                  debug_isNCIO;
    logic                  debug_isPerfCnt;
  } exu_out_t;

  // 硬件预取请求（L1 prefetcher）
  typedef struct packed {
    logic [47:0]           paddr;
    logic [1:0]            alias_;
    logic                  confidence;
    logic                  is_store;
    logic [2:0]            pf_source_value;
  } pf_req_t;

  // DTLB 应答（s1）
  typedef struct packed {
    logic [1:0][47:0]      paddr;
    logic [63:0]           gpaddr_0;
    logic [63:0]           fullva;
    logic [1:0]            pbmt_0;
    logic                  miss;
    logic                  isForVSnonLeafPTE;
    logic                  excp_0_vaNeedExt;
    logic                  excp_0_isHyper;
    logic                  excp_0_gpf_ld;
    logic                  excp_0_pf_ld;
    logic                  excp_0_af_ld;
    logic                  ptwBack;
  } tlb_resp_t;

  // CSR 下发的调试触发器配置
  typedef struct packed {
    logic [1:0]            tdataVec_0_matchType;
    logic                  tdataVec_0_select;
    logic                  tdataVec_0_timing;
    logic [3:0]            tdataVec_0_action;
    logic                  tdataVec_0_chain;
    logic                  tdataVec_0_load;
    logic [63:0]           tdataVec_0_tdata2;
    logic [1:0]            tdataVec_1_matchType;
    logic                  tdataVec_1_select;
    logic                  tdataVec_1_timing;
    logic [3:0]            tdataVec_1_action;
    logic                  tdataVec_1_chain;
    logic                  tdataVec_1_load;
    logic [63:0]           tdataVec_1_tdata2;
    logic [1:0]            tdataVec_2_matchType;
    logic                  tdataVec_2_select;
    logic                  tdataVec_2_timing;
    logic [3:0]            tdataVec_2_action;
    logic                  tdataVec_2_chain;
    logic                  tdataVec_2_load;
    logic [63:0]           tdataVec_2_tdata2;
    logic [1:0]            tdataVec_3_matchType;
    logic                  tdataVec_3_select;
    logic                  tdataVec_3_timing;
    logic [3:0]            tdataVec_3_action;
    logic                  tdataVec_3_chain;
    logic                  tdataVec_3_load;
    logic [63:0]           tdataVec_3_tdata2;
    logic                  tEnableVec_0;
    logic                  tEnableVec_1;
    logic                  tEnableVec_2;
    logic                  tEnableVec_3;
    logic                  debugMode;
    logic                  triggerCanRaiseBpExp;
  } trigger_csr_t;

  // store 流水的 st-ld 违例广播
  typedef struct packed {
    logic                  valid;
    logic                  bits_robIdx_flag;
    logic [7:0]            bits_robIdx_value;
    logic [47:0]           bits_paddr;
    logic [15:0]           bits_mask;
    logic [1:0]            bits_matchType;
  } st_query_t;

  // PMP/PMA 检查结果（与 TLB 应答同拍到达，s2 用）
  typedef struct packed {
    logic                  ld;
    logic                  st;
    logic                  instr;
    logic                  mmio;
  } pmp_t;

  // DCache 应答（s2；tl_error_delayed 在 s3 用）
  typedef struct packed {
    logic [127:0]          data;
    logic                  miss;
    logic [3:0]            mshr_id;
    logic [2:0]            meta_prefetch;
    logic                  handled;
    logic                  tl_error_delayed_tl_denied;
    logic                  tl_error_delayed_tl_corrupt;
  } dcache_resp_t;

  // sbuffer/ubuffer 前递结果
  typedef struct packed {
    logic [15:0]           forwardMask;
    logic [15:0][7:0]      forwardData;
    logic                  matchInvalid;
  } fwd_resp_t;

  // store queue 前递结果
  typedef struct packed {
    logic [15:0]           forwardMask;
    logic [15:0][7:0]      forwardData;
    logic                  dataInvalid;
    logic                  matchInvalid;
    logic                  addrInvalid;
    logic                  dataInvalidSqIdx_flag;
    logic [5:0]            dataInvalidSqIdx_value;
    logic                  addrInvalidSqIdx_flag;
    logic [5:0]            addrInvalidSqIdx_value;
  } lsq_fwd_resp_t;

  // TileLink D 通道回填数据（前递用）
  typedef struct packed {
    logic                  valid;
    logic [255:0]          data;
    logic [3:0]            mshrid;
    logic                  last;
    logic                  denied;
    logic                  corrupt;
  } d_chan_t;

  // MSHR 前递结果
  typedef struct packed {
    logic                  forward_mshr;
    logic [15:0][7:0]      forwardData;
    logic                  forward_result_valid;
    logic                  denied;
    logic                  corrupt;
  } mshr_fwd_resp_t;

  // TLB miss 的 filter 表项号（回放唤醒用）
  typedef struct packed {
    logic [3:0]            id;
    logic                  full;
  } tlb_hint_t;

  // MMIO load 的原始数据（LQ 合并好的 64 位）
  typedef struct packed {
    logic [63:0]           lqData;
    uop_t                  uop;
    logic [2:0]            addrOffset;
  } ld_raw_data_t;

  // ROB 队头：非对齐只准最老指令进缓冲
  typedef struct packed {
    logic                  flag;
    logic [7:0]            value;
  } rob_ptr_t;

  // 后端重定向（冲刷）
  typedef struct packed {
    logic                  robIdx_flag;
    logic [7:0]            robIdx_value;
    logic                  level;
  } redirect_t;

  // 自定义 CSR 开关
  typedef struct packed {
    logic                  ldld_vio_check_enable;
    logic                  hd_misalign_ld_enable;
  } csr_ctrl_t;

  // DTLB 请求（s0 发，s1 带 pmp_addr）
  typedef struct packed {
    logic [49:0]           vaddr;
    logic [63:0]           fullva;
    logic                  checkfullva;
    logic [2:0]            cmd;
    logic                  hyperinst;
    logic                  hlvx;
    logic                  kill;
    logic                  isPrefetch;
    logic                  no_translate;
    logic [47:0]           pmp_addr;
    logic                  frm_mabuf;
    logic                  debug_robIdx_flag;
    logic [7:0]            debug_robIdx_value;
    logic                  debug_isFirstIssue;
  } tlb_req_t;

  // DCache 请求（s0）
  typedef struct packed {
    logic [4:0]            cmd;
    logic [49:0]           vaddr;
    logic [49:0]           vaddr_dup;
    logic [3:0]            instrtype;
    logic                  isFirstIssue;
    logic                  lqIdx_flag;
    logic [6:0]            lqIdx_value;
  } dcache_req_t;

  // sbuffer/ubuffer 前递查询
  typedef struct packed {
    logic [49:0]           vaddr;
    logic [47:0]           paddr;
    logic                  valid;
  } fwd_req_t;

  // store queue 前递查询（s1）
  typedef struct packed {
    logic [49:0]           vaddr;
    logic [47:0]           paddr;
    logic [15:0]           mask;
    uop_t                  uop;
    logic                  valid;
    logic                  sqIdx_flag;
    logic [55:0]           sqIdxMask;
  } lsq_fwd_req_t;

  // MSHR 前递查询（s1）
  typedef struct packed {
    logic                  valid;
    logic [3:0]            mshrid;
    logic [47:0]           paddr;
  } mshr_fwd_req_t;

  // RAR/RAW 违例队列登记请求
  typedef struct packed {
    uop_t                  uop;
    logic [15:0]           mask;
    logic [47:0]           paddr;
    logic                  data_valid;
    logic                  is_nc;
  } nuke_req_t;

  // 预取训练包
  typedef struct packed {
    uop_t                  uop;
    logic [49:0]           vaddr;
    logic [47:0]           paddr;
    logic                  miss;
    logic                  isFirstIssue;
    logic [2:0]            meta_prefetch;
  } pf_train_t;

  // prefetch.i 转给取指
  typedef struct packed {
    logic [49:0]           vaddr;
  } ifetch_pf_t;

  // 向量写回到合并缓冲（s3）
  typedef struct packed {
    logic [3:0]            mBIndex;
    logic [3:0]            trigger;
    logic [23:0]           exceptionVec;
    logic                  hasException;
    logic [63:0]           vaddr;
    logic                  vaNeedExt;
    logic [63:0]           gpaddr;
    logic                  isForVSnonLeafPTE;
    logic [7:0]            vstart;
    logic [15:0]           vecTriggerMask;
    logic [7:0]            elemIdx;
    logic [15:0]           mask;
    logic [2:0]            alignedType;
    logic [3:0]            reg_offset;
    logic [7:0]            elemIdxInsideVd;
    logic [127:0]          vecdata;
  } vecldout_t;

  // 给发射队列的慢反馈（s3）
  typedef struct packed {
    logic                  robIdx_flag;
    logic [7:0]            robIdx_value;
    logic                  flushState;
    logic                  sqIdx_flag;
    logic [5:0]            sqIdx_value;
    logic                  lqIdx_flag;
    logic [6:0]            lqIdx_value;
  } feedback_t;

  // RAR 违例 / 前递地址失配引起的回滚重定向（s3）
  typedef struct packed {
    logic                  isRVC;
    logic                  robIdx_flag;
    logic [7:0]            robIdx_value;
    logic                  ftqIdx_flag;
    logic [5:0]            ftqIdx_value;
    logic [3:0]            ftqOffset;
    logic                  level;
    logic [63:0]           debug_runahead_checkpoint_id;
  } rollback_t;

  // topdown 性能分析
  typedef struct packed {
    logic [7:0]            s1_robIdx;
    logic                  s1_vaddr_valid;
    logic [49:0]           s1_vaddr_bits;
    logic [7:0]            s2_robIdx;
    logic                  s2_paddr_valid;
    logic [47:0]           s2_paddr_bits;
  } topdown_t;
  // END GENERATED(types)

  // FlowSource：s0 把每一路来源先整理成同一个格式，再按优先级选一路（Scala: class FlowSource）
  typedef struct packed {
    logic [VADDR_W-1:0] vaddr;
    logic [VLEN_B-1:0]  mask;
    uop_t               uop;
    logic               has_rob_entry;   // 已在 ROB 里（非预取、非 MMIO）
    logic [3:0]         mshrid;          // 等哪个 MSHR 的回填
    logic               isFirstIssue;
    logic               fast_rep;        // 来自快速重发
    logic               ld_rep;          // 来自 LQ 重发
    logic               prf;             // 预取（软件 prefetch 或硬件预取）
    logic               prf_rd;
    logic               prf_wr;
    logic               prf_i;           // prefetch.i：不访问 DCache，转给取指
    logic [6:0]         sched_idx;       // LoadQueueReplay 的表项号
    logic               frm_mabuf;       // 来自非对齐缓冲
    logic               isvec;
    logic               is128bit;
    logic [3:0]         reg_offset;
    logic               vecActive;       // 向量活跃元素 / 标量访存恒 1
    logic [3:0]         mbIndex;
    logic [7:0]         elemIdx;
    logic [7:0]         elemIdxInsideVd;
    logic [2:0]         alignedType;
    logic [VADDR_W-1:0] vecBaseVaddr;
    logic               isnc;            // NC 带数据回来
    logic [PADDR_W-1:0] paddr;
    logic [128:0]       data;
  } flow_source_t;

  // ---------------- 小工具（纯函数：只读形参）----------------
  // 环形指针"a 比 b 年轻"：flag 不同时比较结果取反（CircularQueuePtr.isAfter）
  function automatic logic ptr_after(input logic a_flag, input logic [7:0] a_val,
                                     input logic b_flag, input logic [7:0] b_val);
    return a_flag ^ b_flag ^ (a_val > b_val);
  endfunction

  // RobPtr.needFlush(redirect)：redirect 有效，且 本条比重定向点年轻，或 level=flushItself 且就是它
  function automatic logic rob_need_flush(input logic rob_flag, input logic [7:0] rob_val,
                                          input logic rd_valid, input logic rd_level,
                                          input logic rd_flag, input logic [7:0] rd_val);
    return rd_valid & (rd_level & ({rob_flag, rob_val} == {rd_flag, rd_val})
                       | ptr_after(rob_flag, rob_val, rd_flag, rd_val));
  endfunction

  // 访存字节掩码：size 编码 0/1/2/3 = 1/2/4/8 字节，左移到 16B 块内偏移（genVWmask）
  function automatic logic [15:0] gen_vw_mask(input logic [3:0] offset, input logic [1:0] size);
    logic [7:0] base;
    case (size)
      2'd0:    base = 8'h01;
      2'd1:    base = 8'h03;
      2'd2:    base = 8'h0F;
      default: base = 8'hFF;
    endcase
    return 16'({15'h0, base} << offset);
  endfunction

  function automatic logic is_prefetch_op(input logic [8:0] op);   // LSUOpType.isPrefetch
    return op[3] & (op[5:4] == 2'b00) & (op[8:7] == 2'b00);
  endfunction

  function automatic logic is_hlv(input logic [8:0] op);           // LSUOpType.isHlv
    return op[4] & ~op[5] & (op[8:7] == 2'b00);
  endfunction

  function automatic logic is_hlvx(input logic [8:0] op);          // LSUOpType.isHlvx
    return op[4] & op[3] & ~op[5] & (op[8:7] == 2'b00);
  endfunction

  // 取 16 位掩码里最低的 1 所在字节号（genVFirstUnmask；全 0 时为 0）
  function automatic logic [3:0] first_unmasked(input logic [15:0] mask);
    logic [3:0] idx;
    idx = 4'd0;
    for (int i = 15; i >= 0; i--)
      if (mask[i]) idx = 4'(i);
    return idx;
  endfunction

  // 写回数据的"截取 + 符号/零扩展/NaN-box"选择（genRdataOH）：9 位 one-hot
  //   [0] lbu/hlvbu   [1] lhu/hlvhu/hlvxhu   [2] lwu/hlvwu/hlvxwu   [3] ld/hlvd
  //   [4] lb/hlvb     [5] lh/hlvh(非浮点)    [6] lw/hlvw(非浮点)    [7] flh   [8] flw
  function automatic logic [8:0] gen_rdata_oh(input logic [8:0] op, input logic fpWen);
    logic [8:0] s;
    s[0] = (op == OP_LBU) | (op == OP_HLVBU);
    s[1] = (op == OP_LHU) | (op == OP_HLVHU) | (op == OP_HLVXHU);
    s[2] = (op == OP_LWU) | (op == OP_HLVWU) | (op == OP_HLVXWU);
    s[3] = (op == OP_LD)  | (op == OP_HLVD);
    s[4] = (op == OP_LB)  | (op == OP_HLVB);
    s[5] = (op == OP_LH) & ~fpWen | (op == OP_HLVH);
    s[6] = (op == OP_LW) & ~fpWen | (op == OP_HLVW);
    s[7] = (op == OP_LH) & fpWen;
    s[8] = (op == OP_LW) & fpWen;
    return s;
  endfunction

  // 按 genRdataOH 的 one-hot 选择拼写回数据（newRdataHelper：Mux1H = 按位"与-或"，
  // 选择向量不是 one-hot 时各路数据相或 —— 照搬这个语义，不写成优先级）
  function automatic logic [63:0] new_rdata(input logic [8:0] sel, input logic [63:0] d);
    logic [63:0] r;
    r = '0;
    if (sel[0]) r |= {56'h0, d[7:0]};
    if (sel[1]) r |= {48'h0, d[15:0]};
    if (sel[2]) r |= {32'h0, d[31:0]};
    if (sel[3]) r |= d;
    if (sel[4]) r |= {{56{d[7]}}, d[7:0]};
    if (sel[5]) r |= {{48{d[15]}}, d[15:0]};
    if (sel[6]) r |= {{32{d[31]}}, d[31:0]};
    if (sel[7]) r |= {48'hFFFF_FFFF_FFFF, d[15:0]};   // FPU.box(H)：高位全 1 的 NaN-box
    if (sel[8]) r |= {32'hFFFF_FFFF, d[31:0]};        // FPU.box(S)
    return r;
  endfunction

  // MMIO 数据按 fuOpType 截取扩展（rdataHelper，LookupTree：不在表里的 op 得 0）
  function automatic logic [63:0] rdata_by_op(input logic [8:0] op, input logic fpWen,
                                               input logic [63:0] d);
    case (op)
      OP_LB, OP_HLVB:             return {{56{d[7]}}, d[7:0]};
      OP_LH:                      return fpWen ? {48'hFFFF_FFFF_FFFF, d[15:0]} : {{48{d[15]}}, d[15:0]};
      OP_LW:                      return fpWen ? {32'hFFFF_FFFF, d[31:0]} : {{32{d[31]}}, d[31:0]};
      OP_LD:                      return d;
      OP_LBU, OP_HLVBU:           return {56'h0, d[7:0]};
      OP_LHU, OP_HLVHU, OP_HLVXHU: return {48'h0, d[15:0]};
      OP_LWU, OP_HLVWU, OP_HLVXWU: return {32'h0, d[31:0]};
      OP_HLVH:                    return {{48{d[15]}}, d[15:0]};
      OP_HLVW:                    return {{32{d[31]}}, d[31:0]};
      OP_HLVD:                    return d;
      default:                    return 64'h0;
    endcase
  endfunction

endpackage

// =====================================================================
// xs_LoadUnit_core —— 可读核
// =====================================================================
module xs_LoadUnit_core
  import loadunit_pkg::*;
(
  // BEGIN GENERATED(core_ports) —— verif/ut/LoadUnit/gen_loadunit.py 生成，勿手改
  input  logic                clock,
  input  logic                reset,
  input  ldin_t               ldin,  // 标量 load 首次发射（发射队列）：src_0=基址寄存器
  input  vecldin_t            vecldin,  // 向量 load 拆出的元素流（VLSplit）
  input  lq_write_t           misalign_ldin,  // 非对齐缓冲拆出的对齐子访问
  input  lq_write_t           replay,  // LoadQueueReplay 重发
  input  lq_write_t           fast_rep_in,  // 本流水 s3 的快速重发回灌
  input  lq_write_t           lsq_nc_ldin,  // NC(非缓存可合并) load 带数据回来
  input  exu_out_t            lsq_uncache,  // MMIO load 从 uncache 回来的写回包
  input  pf_req_t             prefetch_req,  // 硬件预取请求（L1 prefetcher）
  input  tlb_resp_t           tlb_resp,  // DTLB 应答（s1）
  input  trigger_csr_t        trigger_csr,  // CSR 下发的调试触发器配置
  input  st_query_t           stld_nuke_query_0,  // store 流水 0 的 st-ld 违例广播
  input  st_query_t           stld_nuke_query_1,  // store 流水 1 的 st-ld 违例广播
  input  pmp_t                pmp,  // PMP/PMA 检查结果（与 TLB 应答同拍到达，s2 用）
  input  dcache_resp_t        dcache_resp,  // DCache 应答（s2；tl_error_delayed 在 s3 用）
  input  fwd_resp_t           sbuffer_resp,  // sbuffer 前递结果
  input  fwd_resp_t           ubuffer_resp,  // uncache buffer 前递结果（NC）
  input  lsq_fwd_resp_t       lsq_fwd_resp,  // store queue 前递结果
  input  d_chan_t             tl_d_channel,  // TileLink D 通道回填数据（前递用）
  input  mshr_fwd_resp_t      mshr_fwd_resp,  // MSHR 前递结果
  input  tlb_hint_t           tlb_hint,  // TLB miss 的 filter 表项号（回放唤醒用）
  input  ld_raw_data_t        ld_raw_data,  // MMIO load 的原始数据（LQ 合并好的 64 位）
  input  rob_ptr_t            robDeqIdx,  // ROB 队头：非对齐只准最老指令进缓冲
  input  redirect_t           redirect,  // 后端重定向（冲刷）
  input  csr_ctrl_t           csrCtrl,  // 自定义 CSR 开关
  output tlb_req_t            tlb_req,  // DTLB 请求（s0 发，s1 带 pmp_addr）
  output dcache_req_t         dcache_req,  // DCache 请求（s0）
  output fwd_req_t            sbuffer_req,  // sbuffer 前递查询（s1）
  output fwd_req_t            ubuffer_req,  // uncache buffer 前递查询（s1）
  output lsq_fwd_req_t        lsq_fwd_req,  // store queue 前递查询（s1）
  output mshr_fwd_req_t       mshr_fwd_req,  // MSHR 前递查询（s1）
  output nuke_req_t           stld_nuke_req,  // 登记 RAW 违例队列（s2）
  output nuke_req_t           ldld_nuke_req,  // 登记 RAR 违例队列（s2）
  output pf_train_t           prefetch_train,  // 训练 SMS 预取器（s3）
  output pf_train_t           prefetch_train_l1,  // 训练 L1 stream/stride 预取器（s3）
  output ifetch_pf_t          ifetchPrefetch,  // prefetch.i 转给取指
  output uop_t                wakeup,  // s0 推测唤醒的 uop
  output exu_out_t            ldout,  // 标量写回（s3）
  output vecldout_t           vecldout,  // 向量写回到合并缓冲（s3）
  output lq_write_t           lsq_ldin,  // 写 load queue（s3）
  output lq_write_t           fast_rep_out,  // 快速重发（s3 → 下一拍 s0）
  output lq_write_t           misalign_enq,  // 非对齐访问进非对齐缓冲（s3）
  output lq_write_t           misalign_ldout,  // 非对齐子访问的结果回非对齐缓冲（s3）
  output feedback_t           feedback_slow,  // 给发射队列的慢反馈（s3）
  output rollback_t           rollback,  // RAR 违例 / 前递地址失配引起的回滚重定向（s3）
  output topdown_t            lsTopdownInfo,  // topdown 性能分析
  // ---- 握手 / 标量口（名字 = golden 端口名去掉 io_ 前缀）----
  input  logic                redirect_valid,
  output logic                ldin_ready,
  input  logic                ldin_valid,
  input  logic                ldout_ready,
  output logic                ldout_valid,
  output logic                vecldin_ready,
  input  logic                vecldin_valid,
  output logic                vecldout_valid,
  output logic                misalign_ldin_ready,
  input  logic                misalign_ldin_valid,
  output logic                misalign_ldout_valid,
  output logic                tlb_req_valid,
  output logic                tlb_req_kill,
  input  logic                tlb_resp_valid,
  input  logic                dcache_req_ready,
  output logic                dcache_req_valid,
  input  logic                dcache_resp_valid,
  output logic                dcache_s1_kill_data_read,
  output logic                dcache_s1_kill,
  output logic                dcache_s2_kill,
  output logic                dcache_is128Req,
  output logic [2:0]          dcache_pf_source,
  output logic [47:0]         dcache_s1_paddr_dup_lsu,
  output logic [47:0]         dcache_s1_paddr_dup_dcache,
  input  logic                dcache_s2_bank_conflict,
  input  logic                dcache_s2_mq_nack,
  output logic                lsq_ldin_valid,
  output logic                lsq_uncache_ready,
  input  logic                lsq_uncache_valid,
  output logic                lsq_nc_ldin_ready,
  input  logic                lsq_nc_ldin_valid,
  input  logic                lsq_stld_nuke_query_req_ready,
  output logic                lsq_stld_nuke_query_req_valid,
  output logic                lsq_stld_nuke_query_revoke,
  input  logic                lsq_ldld_nuke_query_req_ready,
  output logic                lsq_ldld_nuke_query_req_valid,
  input  logic                lsq_ldld_nuke_query_resp_valid,
  input  logic                lsq_ldld_nuke_query_resp_bits_rep_frm_fetch,
  output logic                lsq_ldld_nuke_query_revoke,
  output logic                prefetch_train_valid,
  output logic                prefetch_train_l1_valid,
  output logic                s1_prefetch_spec,
  output logic                s2_prefetch_spec,
  output logic                s1_prefetch_spec_l1,
  output logic                s2_prefetch_spec_l1,
  input  logic                prefetch_req_valid,
  output logic                canAcceptLowConfPrefetch,
  output logic                canAcceptHighConfPrefetch,
  output logic                ifetchPrefetch_valid,
  output logic                wakeup_valid,
  output logic                feedback_slow_valid,
  output logic                ldCancel_ld2Cancel,
  output logic                replay_ready,
  input  logic                replay_valid,
  output logic                s2_ptr_chasing,
  input  logic                fast_rep_in_valid,
  output logic                fast_rep_out_valid,
  input  logic                misalign_enq_req_ready,
  output logic                misalign_enq_req_valid,
  output logic                rollback_valid,
  output logic [5:0]          perf_0_value,
  output logic [5:0]          perf_1_value,
  output logic [5:0]          perf_2_value,
  output logic [5:0]          perf_3_value,
  output logic [5:0]          perf_4_value,
  output logic [5:0]          perf_5_value,
  output logic [5:0]          perf_6_value,
  output logic [5:0]          perf_7_value,
  output logic [5:0]          perf_8_value
  // END GENERATED(core_ports)
);

  // -------------------------------------------------------------------
  // 各级之间的握手（下游先声明，上游用）
  // -------------------------------------------------------------------
  logic s1_ready, s2_ready, s3_ready;
  logic s0_fire, s1_fire, s2_fire;
  logic s1_kill, s2_kill;

  // 三级流水的"包"：sX_in = 本级寄存器读回；sX_out = 本级处理后交给下一级
  lq_write_t s0_out;
  lq_write_t s1_in, s1_out;
  lq_write_t s2_in, s2_out;
  lq_write_t s3_in;

  // 整包打拍寄存器组的读回（见文件尾 GENERATED(pipe_regs)）
  exu_out_t     mmio_req_d1, s2_mmio_req_bits, s3_mmio_req_bits;
  ld_raw_data_t mmio_raw_d1, mmio_raw_d2, s3_ld_raw_data_frm_mmio;
  lq_write_t    mab_wakeup_d1, mab_wakeup_d2, s3_misalign_wakeup_req_bits;
  lq_write_t    pf_train_in, pf_train_l1_in;

  // ===================================================================
  // s0：从 11 路来源里按优先级选一路，算虚地址，发 DTLB 与 DCache 请求
  // -------------------------------------------------------------------
  // 输入：各来源的 valid/bits、dcache_req_ready、s1_ready（下一级能收）。
  // 选源规则：valid 向量里编号最小者胜出（ready[i] = 前面没人 valid）。有两个例外：
  //   * LQ 普通重发（src 3）若比正在发射的标量/向量 load 年轻（lqIdx 更大）就让路
  //     （s0_rep_stall），避免年轻的重发把老指令挤掉；
  //   * MMIO（src 7）只借写回口，不访问 DCache、不占 s0_valid；NC（src 8）即使
  //     dcache 不 ready 也能走（它带着数据，只查前递）。
  // 地址：TLB 用"有地址的来源"的虚地址；DCache 另外可以直接用快速重发/硬件预取/NC 的地址。
  // 非对齐：地址不按 size 对齐 → 标 loadAddrMisaligned；若没跨 16B 边界就当作 128 位
  //   访问一次做完（misalignWith16Byte），跨了则 s1 杀掉 DCache 读、s3 交给非对齐缓冲。
  // ===================================================================
  logic [NUM_SRC-1:0] s0_src_valid, s0_src_ready, s0_src_select;
  logic               s0_rep_stall;

  always_comb begin
    // LQ 重发让路：比 ldin / vecldin 里正在发射的 load 年轻
    s0_rep_stall = ldin_valid    & ptr_after(replay.uop.lqIdx_flag, 8'(replay.uop.lqIdx_value),
                                             ldin.uop.lqIdx_flag, 8'(ldin.uop.lqIdx_value))
                 | vecldin_valid & ptr_after(replay.uop.lqIdx_flag, 8'(replay.uop.lqIdx_value),
                                             vecldin.uop.lqIdx_flag, 8'(vecldin.uop.lqIdx_value));

    s0_src_valid[SRC_MAB]       = misalign_ldin_valid;
    s0_src_valid[SRC_SUPER_REP] = replay_valid & replay.forward_tlDchannel;
    s0_src_valid[SRC_FAST_REP]  = fast_rep_in_valid;
    s0_src_valid[SRC_LSQ_REP]   = replay_valid & ~replay.forward_tlDchannel & ~s0_rep_stall;
    s0_src_valid[SRC_HIGH_PF]   = prefetch_req_valid & prefetch_req.confidence;
    s0_src_valid[SRC_VEC]       = vecldin_valid;
    s0_src_valid[SRC_INT]       = ldin_valid;
    s0_src_valid[SRC_MMIO]      = lsq_uncache_valid;
    s0_src_valid[SRC_NC]        = lsq_nc_ldin_valid;
    s0_src_valid[SRC_L2L]       = 1'b0;                  // 指针追逐关闭
    s0_src_valid[SRC_LOW_PF]    = prefetch_req_valid & ~prefetch_req.confidence;

    for (int i = 0; i < NUM_SRC; i++) begin
      s0_src_ready[i]  = (i == 0) ? 1'b1 : ~|(s0_src_valid & NUM_SRC'((1 << i) - 1));
      s0_src_select[i] = s0_src_valid[i] & s0_src_ready[i];
    end
  end

  // ---- 每一路来源整理成 FlowSource（Scala 的 fromXxxSource）----
  flow_source_t s0_src_fmt [NUM_SRC];
  logic [VADDR_W-1:0] int_issue_vaddr;     // 标量首发：基址 + 12 位立即数（按 VAddrBits 截断）
  logic [XLEN-1:0]    int_issue_fullva;    // 同上，但按 64 位算（给 TLB 查高位是否合法）

  always_comb begin
    int_issue_vaddr  = VADDR_W'(ldin.src_0[VADDR_W-1:0] + {{(VADDR_W-12){ldin.uop.imm[11]}}, ldin.uop.imm[11:0]});
    int_issue_fullva = ldin.src_0 + {{(XLEN-12){ldin.uop.imm[11]}}, ldin.uop.imm[11:0]};

    for (int i = 0; i < NUM_SRC; i++) s0_src_fmt[i] = '0;

    // 0：非对齐缓冲的子访问
    s0_src_fmt[SRC_MAB].vaddr     = misalign_ldin.vaddr;
    s0_src_fmt[SRC_MAB].mask      = misalign_ldin.mask;
    s0_src_fmt[SRC_MAB].uop       = misalign_ldin.uop;
    s0_src_fmt[SRC_MAB].mshrid    = misalign_ldin.mshrid;
    s0_src_fmt[SRC_MAB].frm_mabuf = 1'b1;
    s0_src_fmt[SRC_MAB].sched_idx = misalign_ldin.schedIndex;
    s0_src_fmt[SRC_MAB].isvec     = misalign_ldin.isvec;
    s0_src_fmt[SRC_MAB].is128bit  = misalign_ldin.is128bit;
    s0_src_fmt[SRC_MAB].vecActive = 1'b1;

    // 1 / 3：LQ 重发（super 与普通两种只是优先级不同，格式一样；vaddr 走 TLB 地址通路）
    for (int k = 0; k < 2; k++) begin
      automatic int s = (k == 0) ? SRC_SUPER_REP : SRC_LSQ_REP;
      s0_src_fmt[s].mask            = replay.isvec ? replay.mask
                                                   : gen_vw_mask(replay.vaddr[3:0], replay.uop.fuOpType[1:0]);
      s0_src_fmt[s].uop             = replay.uop;
      s0_src_fmt[s].has_rob_entry   = 1'b1;
      s0_src_fmt[s].mshrid          = replay.mshrid;
      s0_src_fmt[s].ld_rep          = 1'b1;
      s0_src_fmt[s].prf             = is_prefetch_op(replay.uop.fuOpType) & ~replay.isvec;
      s0_src_fmt[s].prf_rd          = replay.uop.fuOpType == OP_PREF_R;
      s0_src_fmt[s].prf_wr          = replay.uop.fuOpType == OP_PREF_W;
      s0_src_fmt[s].sched_idx       = replay.schedIndex;
      s0_src_fmt[s].isvec           = replay.isvec;
      s0_src_fmt[s].is128bit        = replay.is128bit;
      s0_src_fmt[s].reg_offset      = replay.reg_offset;
      s0_src_fmt[s].vecActive       = replay.vecActive;
      s0_src_fmt[s].mbIndex         = replay.mbIndex;
      s0_src_fmt[s].elemIdx         = replay.elemIdx;
      s0_src_fmt[s].elemIdxInsideVd = replay.elemIdxInsideVd;
      s0_src_fmt[s].alignedType     = replay.alignedType;
    end

    // 2：快速重发
    s0_src_fmt[SRC_FAST_REP].vaddr           = fast_rep_in.vaddr;
    s0_src_fmt[SRC_FAST_REP].paddr           = fast_rep_in.paddr;
    s0_src_fmt[SRC_FAST_REP].mask            = fast_rep_in.mask;
    s0_src_fmt[SRC_FAST_REP].uop             = fast_rep_in.uop;
    s0_src_fmt[SRC_FAST_REP].has_rob_entry   = fast_rep_in.hasROBEntry;
    s0_src_fmt[SRC_FAST_REP].mshrid          = fast_rep_in.rep_info_mshr_id;
    s0_src_fmt[SRC_FAST_REP].frm_mabuf       = fast_rep_in.isFrmMisAlignBuf;
    s0_src_fmt[SRC_FAST_REP].fast_rep        = 1'b1;
    s0_src_fmt[SRC_FAST_REP].ld_rep          = fast_rep_in.isLoadReplay;
    s0_src_fmt[SRC_FAST_REP].prf             = is_prefetch_op(fast_rep_in.uop.fuOpType) & ~fast_rep_in.isvec;
    s0_src_fmt[SRC_FAST_REP].prf_rd          = fast_rep_in.uop.fuOpType == OP_PREF_R;
    s0_src_fmt[SRC_FAST_REP].prf_wr          = fast_rep_in.uop.fuOpType == OP_PREF_W;
    s0_src_fmt[SRC_FAST_REP].sched_idx       = fast_rep_in.schedIndex;
    s0_src_fmt[SRC_FAST_REP].isvec           = fast_rep_in.isvec;
    s0_src_fmt[SRC_FAST_REP].is128bit        = fast_rep_in.is128bit;
    s0_src_fmt[SRC_FAST_REP].reg_offset      = fast_rep_in.reg_offset;
    s0_src_fmt[SRC_FAST_REP].vecActive       = fast_rep_in.vecActive;
    s0_src_fmt[SRC_FAST_REP].mbIndex         = fast_rep_in.mbIndex;
    s0_src_fmt[SRC_FAST_REP].elemIdx         = fast_rep_in.elemIdx;
    s0_src_fmt[SRC_FAST_REP].elemIdxInsideVd = fast_rep_in.elemIdxInsideVd;
    s0_src_fmt[SRC_FAST_REP].alignedType     = fast_rep_in.alignedType;
    s0_src_fmt[SRC_FAST_REP].data            = fast_rep_in.data;

    // 4 / 10：硬件预取（没有 uop，只有物理地址）
    for (int k = 0; k < 2; k++) begin
      automatic int s = (k == 0) ? SRC_HIGH_PF : SRC_LOW_PF;
      s0_src_fmt[s].prf    = 1'b1;
      s0_src_fmt[s].prf_rd = ~prefetch_req.is_store;
      s0_src_fmt[s].prf_wr = prefetch_req.is_store;
    end

    // 5：向量元素
    s0_src_fmt[SRC_VEC].mask            = vecldin.mask;
    s0_src_fmt[SRC_VEC].uop             = vecldin.uop;
    s0_src_fmt[SRC_VEC].has_rob_entry   = 1'b1;
    s0_src_fmt[SRC_VEC].isvec           = 1'b1;
    s0_src_fmt[SRC_VEC].is128bit        = vecldin.alignedType[2];   // is128Bit(alignedType)
    s0_src_fmt[SRC_VEC].reg_offset      = vecldin.reg_offset;
    s0_src_fmt[SRC_VEC].vecActive       = vecldin.vecActive;
    s0_src_fmt[SRC_VEC].mbIndex         = vecldin.mBIndex;
    s0_src_fmt[SRC_VEC].elemIdx         = vecldin.elemIdx;
    s0_src_fmt[SRC_VEC].elemIdxInsideVd = vecldin.elemIdxInsideVd;
    s0_src_fmt[SRC_VEC].vecBaseVaddr    = vecldin.basevaddr;
    s0_src_fmt[SRC_VEC].alignedType     = vecldin.alignedType;

    // 6：标量首发（含软件 prefetch.r/w/i）
    s0_src_fmt[SRC_INT].mask          = gen_vw_mask(4'(ldin.src_0[3:0] + ldin.uop.imm[3:0]),
                                                    ldin.uop.fuOpType[1:0]);
    s0_src_fmt[SRC_INT].uop           = ldin.uop;
    s0_src_fmt[SRC_INT].has_rob_entry = 1'b1;
    s0_src_fmt[SRC_INT].isFirstIssue  = 1'b1;
    s0_src_fmt[SRC_INT].prf           = is_prefetch_op(ldin.uop.fuOpType);
    s0_src_fmt[SRC_INT].prf_rd        = ldin.uop.fuOpType == OP_PREF_R;
    s0_src_fmt[SRC_INT].prf_wr        = ldin.uop.fuOpType == OP_PREF_W;
    s0_src_fmt[SRC_INT].prf_i         = ldin.uop.fuOpType == OP_PREF_I;
    s0_src_fmt[SRC_INT].vecActive     = 1'b1;

    // 7：MMIO 写回（只要 uop）
    s0_src_fmt[SRC_MMIO].uop       = lsq_uncache.uop;
    s0_src_fmt[SRC_MMIO].vecActive = 1'b1;

    // 8：NC 带数据回来
    s0_src_fmt[SRC_NC].vaddr         = lsq_nc_ldin.vaddr;
    s0_src_fmt[SRC_NC].paddr         = lsq_nc_ldin.paddr;
    s0_src_fmt[SRC_NC].mask          = gen_vw_mask(lsq_nc_ldin.vaddr[3:0], lsq_nc_ldin.uop.fuOpType[1:0]);
    s0_src_fmt[SRC_NC].uop           = lsq_nc_ldin.uop;
    s0_src_fmt[SRC_NC].has_rob_entry = 1'b1;
    s0_src_fmt[SRC_NC].sched_idx     = lsq_nc_ldin.schedIndex;
    s0_src_fmt[SRC_NC].isvec         = lsq_nc_ldin.isvec;
    s0_src_fmt[SRC_NC].is128bit      = lsq_nc_ldin.is128bit;
    s0_src_fmt[SRC_NC].vecActive     = lsq_nc_ldin.vecActive;
    s0_src_fmt[SRC_NC].isnc          = 1'b1;
    s0_src_fmt[SRC_NC].data          = lsq_nc_ldin.data;

    // 9：指针追逐（关闭）：全 0
  end

  // ---- 按 valid 优先级选一路（ParallelPriorityMux：全无效时落到最后一项 = 低置信预取的格式）----
  flow_source_t s0_sel_src;
  always_comb begin
    s0_sel_src = s0_src_fmt[NUM_SRC-1];
    for (int i = NUM_SRC - 2; i >= 0; i--)
      if (s0_src_valid[i]) s0_sel_src = s0_src_fmt[i];
  end

  // ---- s0 的有效性 ----
  logic s0_valid, s0_hw_prf_select, s0_tlb_no_query, s0_nc_with_data, s0_tlb_valid;
  logic s0_mmio_fire, s0_nc_fire, s0_misalign_wakeup_fire;
  logic misalign_ldin_fire;

  always_comb begin
    s0_hw_prf_select = s0_src_select[SRC_HIGH_PF] | s0_src_select[SRC_LOW_PF];
    // 不需要翻译的：硬件预取 / prefetch.i / 快速重发（已有 paddr）/ MMIO / NC
    s0_tlb_no_query  = s0_hw_prf_select | s0_sel_src.prf_i | s0_src_select[SRC_FAST_REP]
                     | s0_src_select[SRC_MMIO] | s0_src_select[SRC_NC];
    s0_nc_with_data  = s0_sel_src.isnc;
    misalign_ldin_fire = misalign_ldin_ready & misalign_ldin_valid;
    // NC 只要选中就有效；其余要求 DCache 能收，且 MMIO 没占着这一拍，且非对齐缓冲这拍
    // 没有在发"唤醒"（唤醒请求不访存，但占用 s0，最高优先）
    s0_valid = s0_src_select[SRC_NC]
             | (|(s0_src_valid & ~(NUM_SRC'(1) << SRC_MMIO) & ~(NUM_SRC'(1) << SRC_NC)))
               & ~s0_src_select[SRC_MMIO] & dcache_req_ready
               & ~(misalign_ldin_fire & misalign_ldin.misalignNeedWakeUp);
    // 有虚地址要翻译的来源才发 TLB（预取 / 快速重发 / MMIO / NC 不发）
    s0_tlb_valid = (s0_src_valid[SRC_MAB] | s0_src_valid[SRC_SUPER_REP] | s0_src_valid[SRC_LSQ_REP]
                    | s0_src_valid[SRC_VEC] | s0_src_valid[SRC_INT] | s0_src_valid[SRC_L2L])
                 & dcache_req_ready;

    s0_fire      = s0_valid & s1_ready;
    s0_mmio_fire = s0_src_select[SRC_MMIO] & s1_ready;
    s0_nc_fire   = s0_src_select[SRC_NC] & s1_ready;
    s0_misalign_wakeup_fire = s0_src_select[SRC_MAB] & s1_ready & dcache_req_ready
                            & misalign_ldin.misalignNeedWakeUp;
  end

  // ---- 地址 ----
  logic [VADDR_W-1:0] s0_tlb_vaddr, s0_dcache_vaddr;
  logic [XLEN-1:0]    s0_tlb_fullva;
  logic               s0_tlb_hlv, s0_tlb_hlvx;

  always_comb begin
    // TLB 用的虚地址：非对齐 > LQ 重发 > 向量 > 标量首发（按 valid，不按 select）
    if (s0_src_valid[SRC_MAB])
      s0_tlb_vaddr = misalign_ldin.vaddr;
    else if (s0_src_valid[SRC_SUPER_REP] | s0_src_valid[SRC_LSQ_REP])
      s0_tlb_vaddr = replay.vaddr;
    else if (s0_src_valid[SRC_VEC])
      s0_tlb_vaddr = vecldin.vaddr[VADDR_W-1:0];
    else
      s0_tlb_vaddr = int_issue_vaddr;

    // DCache 用的虚地址：快速重发 / 硬件预取 / NC 直接给，其余同 TLB
    if (s0_src_select[SRC_FAST_REP])
      s0_dcache_vaddr = fast_rep_in.vaddr;
    else if (s0_hw_prf_select)   // 预取只有物理地址：用 {alias, paddr 页内偏移} 当虚地址索引
      s0_dcache_vaddr = {36'h0, prefetch_req.alias_, prefetch_req.paddr[11:0]};
    else if (s0_src_select[SRC_NC])
      s0_dcache_vaddr = lsq_nc_ldin.vaddr;
    else
      s0_dcache_vaddr = s0_tlb_vaddr;

    // 完整 64 位虚地址（只有首发要检查高位是否是合法的符号扩展）
    if (s0_src_valid[SRC_MAB])
      s0_tlb_fullva = misalign_ldin.fullva;
    else if (s0_src_select[SRC_VEC])
      s0_tlb_fullva = vecldin.vaddr;
    else if (s0_src_select[SRC_INT])
      s0_tlb_fullva = int_issue_fullva;
    else
      s0_tlb_fullva = XLEN'(s0_dcache_vaddr);

    // 虚拟化 load（hlv / hlvx）要按 VS 阶段翻译
    if (s0_src_valid[SRC_MAB]) begin
      s0_tlb_hlv  = is_hlv(misalign_ldin.uop.fuOpType);
      s0_tlb_hlvx = is_hlvx(misalign_ldin.uop.fuOpType);
    end else if (s0_src_valid[SRC_SUPER_REP] | s0_src_valid[SRC_LSQ_REP]) begin
      s0_tlb_hlv  = is_hlv(replay.uop.fuOpType);
      s0_tlb_hlvx = is_hlvx(replay.uop.fuOpType);
    end else if (s0_src_valid[SRC_VEC]) begin
      s0_tlb_hlv  = 1'b0;
      s0_tlb_hlvx = 1'b0;
    end else begin
      s0_tlb_hlv  = is_hlv(ldin.uop.fuOpType);
      s0_tlb_hlvx = is_hlvx(ldin.uop.fuOpType);
    end
  end

  // ---- 对齐检查 ----
  logic [1:0] s0_align_type;          // 访问宽度编码 0/1/2/3 = 1/2/4/8 字节
  logic       s0_addr_aligned, s0_rs_cross16Bytes, s0_misalignWith16Byte, s0_is128bit;
  logic [4:0] s0_last_byte_low;       // 最后一个字节地址的低 5 位

  always_comb begin
    s0_align_type   = s0_sel_src.isvec ? s0_sel_src.alignedType[1:0] : s0_sel_src.uop.fuOpType[1:0];
    case (s0_align_type)
      2'd0:    s0_addr_aligned = 1'b1;
      2'd1:    s0_addr_aligned = s0_dcache_vaddr[0] == 1'b0;
      2'd2:    s0_addr_aligned = s0_dcache_vaddr[1:0] == 2'b0;
      default: s0_addr_aligned = s0_dcache_vaddr[2:0] == 3'b0;
    endcase
    // 首字节与末字节是否落在同一个 16B 块
    s0_last_byte_low      = 5'((5'd1 << s0_align_type) - 5'd1) + s0_dcache_vaddr[4:0];
    s0_rs_cross16Bytes    = s0_last_byte_low[4] != s0_dcache_vaddr[4];
    // 非对齐但没跨 16B：当一次 128 位访问直接做完
    s0_misalignWith16Byte = ~s0_rs_cross16Bytes & ~s0_addr_aligned & ~s0_hw_prf_select;
    s0_is128bit           = s0_sel_src.is128bit | s0_misalignWith16Byte;
  end

  // ---- GTimer：记录 TLB 首次请求时刻用的自由计数器 ----
  logic [63:0] s0_out_uop_debugInfo_tlbFirstReqTime_c;
  always_ff @(posedge clock or posedge reset)
    if (reset) s0_out_uop_debugInfo_tlbFirstReqTime_c <= 64'h0;
    else       s0_out_uop_debugInfo_tlbFirstReqTime_c <= s0_out_uop_debugInfo_tlbFirstReqTime_c + 64'h1;

  // ---- s0_out：交给 s1 的包 ----
  always_comb begin
    s0_out = '0;
    s0_out.uop                 = s0_sel_src.uop;
    s0_out.vaddr               = s0_nc_with_data ? s0_sel_src.vaddr : s0_dcache_vaddr;
    s0_out.fullva              = s0_sel_src.frm_mabuf ? XLEN'(s0_out.vaddr) : s0_tlb_fullva;
    s0_out.mask                = s0_sel_src.mask;
    s0_out.isFirstIssue        = s0_sel_src.isFirstIssue;
    s0_out.hasROBEntry         = s0_sel_src.has_rob_entry;
    s0_out.isPrefetch          = s0_sel_src.prf;
    s0_out.isHWPrefetch        = s0_hw_prf_select;
    s0_out.isFastReplay        = s0_sel_src.fast_rep;
    s0_out.isLoadReplay        = s0_sel_src.ld_rep;
    s0_out.mshrid              = s0_sel_src.mshrid;
    s0_out.isvec               = s0_sel_src.isvec;
    s0_out.is128bit            = s0_is128bit;
    s0_out.isFrmMisAlignBuf    = s0_sel_src.frm_mabuf;
    // 物理地址只对 NC / 快速重发 / 硬件预取有意义（其余等 s1 的 TLB 结果）
    if (s0_src_select[SRC_NC])
      s0_out.paddr = lsq_nc_ldin.paddr;
    else if (s0_src_select[SRC_FAST_REP])
      s0_out.paddr = fast_rep_in.paddr;
    else if (s0_src_select[SRC_INT] & s0_sel_src.prf_i)
      s0_out.paddr = '0;
    else
      s0_out.paddr = prefetch_req.paddr;
    s0_out.tlbNoQuery          = s0_tlb_no_query;
    s0_out.reg_offset          = s0_sel_src.reg_offset;
    s0_out.vecActive           = s0_sel_src.vecActive;
    s0_out.elemIdx             = s0_sel_src.elemIdx;
    s0_out.elemIdxInsideVd     = s0_sel_src.elemIdxInsideVd;
    s0_out.alignedType         = s0_sel_src.alignedType;
    s0_out.mbIndex             = s0_sel_src.mbIndex;
    s0_out.vecBaseVaddr        = s0_sel_src.vecBaseVaddr;
    // 非对齐异常：没对齐（或来源已带此异常）且是活跃元素；能一次做完的 16B 内非对齐不报
    s0_out.uop.exceptionVec[EXC_LD_MISALIGN] =
      (~s0_addr_aligned | s0_sel_src.uop.exceptionVec[EXC_LD_MISALIGN]) & s0_sel_src.vecActive
      & ~s0_misalignWith16Byte;
    s0_out.isMisalign          = (~s0_addr_aligned | s0_sel_src.uop.exceptionVec[EXC_LD_MISALIGN])
                               & s0_sel_src.vecActive;
    s0_out.forward_tlDchannel  = s0_src_select[SRC_SUPER_REP];
    s0_out.uop.debugInfo_tlbFirstReqTime = (s0_tlb_valid & s0_sel_src.isFirstIssue)
                                         ? s0_out_uop_debugInfo_tlbFirstReqTime_c
                                         : s0_sel_src.uop.debugInfo_tlbFirstReqTime;
    s0_out.schedIndex          = s0_sel_src.sched_idx;
    s0_out.nc                  = s0_sel_src.isnc;
    s0_out.data                = s0_sel_src.data;
    s0_out.misalignWith16Byte  = s0_misalignWith16Byte;
    s0_out.misalignNeedWakeUp  = s0_sel_src.frm_mabuf & misalign_ldin.misalignNeedWakeUp;
    s0_out.isFinalSplit        = s0_sel_src.frm_mabuf & misalign_ldin.isFinalSplit;
  end

  // ---- DTLB / DCache 请求 ----
  always_comb begin
    tlb_req_valid                = s0_tlb_valid;
    tlb_req                      = '0;
    tlb_req.cmd                  = (s0_sel_src.prf & s0_sel_src.prf_wr) ? TLB_CMD_WRITE : TLB_CMD_READ;
    tlb_req.isPrefetch           = s0_sel_src.prf;
    tlb_req.vaddr                = s0_tlb_vaddr;
    tlb_req.fullva               = s0_tlb_fullva;
    tlb_req.checkfullva          = s0_src_select[SRC_VEC] | s0_src_select[SRC_INT];
    tlb_req.hyperinst            = s0_tlb_hlv;
    tlb_req.hlvx                 = s0_tlb_hlvx;
    tlb_req.kill                 = s0_tlb_no_query;       // 不需要翻译的请求直接杀掉
    tlb_req.no_translate         = s0_tlb_no_query;
    tlb_req.frm_mabuf            = s0_sel_src.frm_mabuf;
    tlb_req.debug_robIdx_flag    = s0_sel_src.uop.robIdx_flag;
    tlb_req.debug_robIdx_value   = s0_sel_src.uop.robIdx_value;
    tlb_req.debug_isFirstIssue   = s0_sel_src.isFirstIssue;
    tlb_req.pmp_addr             = s1_in.paddr;           // s1：快速重发等带来的 paddr 给 PMP 检查

    dcache_req_valid             = s0_valid & ~s0_sel_src.prf_i & ~s0_nc_with_data;
    dcache_req                   = '0;
    dcache_req.cmd               = s0_sel_src.prf_rd ? M_PFR : s0_sel_src.prf_wr ? M_PFW : M_XRD;
    dcache_req.vaddr             = s0_dcache_vaddr;
    dcache_req.vaddr_dup         = s0_dcache_vaddr;
    dcache_req.instrtype         = s0_sel_src.prf ? DCACHE_PREFETCH_SOURCE : LOAD_SOURCE;
    dcache_req.isFirstIssue      = s0_sel_src.isFirstIssue;
    dcache_req.lqIdx_flag        = s0_sel_src.uop.lqIdx_flag;
    dcache_req.lqIdx_value       = s0_sel_src.uop.lqIdx_value;
    dcache_pf_source             = s0_hw_prf_select ? prefetch_req.pf_source_value : L1_HW_PREFETCH_NULL;
    dcache_is128Req              = s0_is128bit;
  end

  // ---- 各来源的 ready ----
  always_comb begin
    misalign_ldin_ready = s1_ready & dcache_req_ready & s0_src_ready[SRC_MAB];
    replay_ready        = s1_ready & dcache_req_ready
                        & (s0_src_ready[SRC_LSQ_REP] & ~s0_rep_stall | s0_src_select[SRC_SUPER_REP]);
    // fast_rep_in 的 ready（= s1_ready & dcache_req_ready & ready[FAST_REP]）在 golden 里没人用，已被消掉
    vecldin_ready       = s1_ready & dcache_req_ready & s0_src_ready[SRC_VEC];
    ldin_ready          = s1_ready & dcache_req_ready & s0_src_ready[SRC_INT];
    lsq_uncache_ready   = s0_mmio_fire;
    lsq_nc_ldin_ready   = s0_src_ready[SRC_NC] & s1_ready;
    canAcceptLowConfPrefetch  = s0_src_ready[SRC_LOW_PF] & dcache_req_ready;
    canAcceptHighConfPrefetch = s0_src_ready[SRC_HIGH_PF] & dcache_req_ready;
  end

  // ---- 推测唤醒（s0 就告诉发射队列"这条 load 两拍后有数据"）----
  // 选 uop 的优先级与选源不同（Scala s0_wakeup_selector），全无效时落到标量首发的 uop
  always_comb begin
    if (s0_misalign_wakeup_fire)          wakeup = misalign_ldin.uop;
    else if (s0_src_valid[SRC_SUPER_REP]) wakeup = replay.uop;
    else if (s0_src_valid[SRC_FAST_REP])  wakeup = fast_rep_in.uop;
    else if (s0_mmio_fire)                wakeup = lsq_uncache.uop;
    else if (s0_nc_fire)                  wakeup = lsq_nc_ldin.uop;
    else if (s0_src_valid[SRC_LSQ_REP])   wakeup = replay.uop;
    else                                  wakeup = ldin.uop;

    wakeup_valid = s0_fire & ~s0_sel_src.isvec & ~s0_sel_src.frm_mabuf
                   & (s0_src_valid[SRC_SUPER_REP] | s0_src_valid[SRC_FAST_REP] | s0_src_valid[SRC_LSQ_REP]
                      | s0_src_valid[SRC_INT] & ~s0_sel_src.prf & ~s0_src_valid[SRC_VEC]
                        & ~s0_src_valid[SRC_HIGH_PF])
                 | s0_mmio_fire | s0_nc_fire | s0_misalign_wakeup_fire;
  end

  // ---- prefetch.i：不进 DCache，下一拍把地址交给取指 ----
  logic io_ifetchPrefetch_valid_REG;
  logic [VADDR_W-1:0] io_ifetchPrefetch_bits_vaddr_r;
  wire  s0_prefetch_i_select = s0_src_select[SRC_INT] & s0_sel_src.prf_i;
  always_ff @(posedge clock)
    io_ifetchPrefetch_valid_REG <= s0_prefetch_i_select;
  always_ff @(posedge clock or posedge reset)
    if (reset)                     io_ifetchPrefetch_bits_vaddr_r <= '0;
    else if (s0_prefetch_i_select) io_ifetchPrefetch_bits_vaddr_r <= s0_out.vaddr;
  assign ifetchPrefetch_valid = io_ifetchPrefetch_valid_REG;
  assign ifetchPrefetch.vaddr = io_ifetchPrefetch_bits_vaddr_r;

  // ===================================================================
  // s1：拿 TLB 应答，发前递查询，查 st-ld 违例，跑调试触发器
  // -------------------------------------------------------------------
  // 输入：s1_in（s0 打拍）、tlb_resp（与 s1 同拍到达）、两条 store 流水的违例广播、
  //       redirect（本拍与上一拍的都要看：上一拍的重定向可能还没冲掉 s0→s1 的这条）。
  // 输出：DCache 的 s1 物理地址与 s1_kill、sbuffer/ubuffer/SQ/MSHR 前递查询、s1_out。
  // 异常：TLB 报的缺页/访问错误在这里写进 exceptionVec；不需要翻译的请求（tlbNoQuery）
  //   不采信 TLB 的异常。若首发检查 fullva 时 TLB 已报页异常，则撤销 s0 的非对齐异常
  //   （页异常优先）。
  // ===================================================================
  logic s1_valid;
  logic s1_vecActive;          // 向量元素是否活跃（带复位 1：非向量恒 1）
  logic s1_nc_with_data;
  logic s1_fast_rep_dly_kill_r;
  logic s1_misalign_kill;      // 跨 16B 的非对齐：DCache 这次不读数据
  logic REG;                   // golden 名：tlb_req.checkfullva 打一拍（s1 用来判"首发检查 fullva"）
  logic s1_try_ptr_chasing_last_REG, s1_kill_last_REG;   // 指针追逐（关闭）的残留寄存器，恒 0
  logic s1_redirect_reg_valid_last_REG;
  logic s1_redirect_reg_bits_r_robIdx_flag;
  logic [7:0] s1_redirect_reg_bits_r_robIdx_value;
  logic s1_redirect_reg_bits_r_level;
  logic [SQ_SIZE-1:0] s1_sqIdx_mask;   // 比本 load 老的 store 在 SQ 里的位置掩码（s0 预算）

  always_ff @(posedge clock or posedge reset)
    if (reset) begin
      s1_valid                       <= 1'b0;
      s1_vecActive                   <= 1'b1;
      s1_misalign_kill               <= 1'b0;
      s1_try_ptr_chasing_last_REG    <= 1'b0;
      s1_redirect_reg_valid_last_REG <= 1'b0;
      s1_kill_last_REG               <= 1'b0;
    end else begin
      s1_valid <= s0_fire | ~(s1_fire | s1_kill) & s1_valid;
      if (s0_fire) begin
        s1_vecActive     <= s0_sel_src.vecActive;
        s1_misalign_kill <= s0_rs_cross16Bytes & ~s0_addr_aligned & ~s0_hw_prf_select;
      end
      s1_try_ptr_chasing_last_REG    <= s0_src_select[SRC_L2L] & s1_ready & dcache_req_ready;
      s1_redirect_reg_valid_last_REG <= redirect_valid;
      s1_kill_last_REG               <= s0_src_select[SRC_L2L];
    end

  always_ff @(posedge clock) begin
    s1_nc_with_data <= s0_nc_with_data;
    if (fast_rep_in_valid) s1_fast_rep_dly_kill_r <= fast_rep_in.lateKill;
    REG <= tlb_req.checkfullva;
    if (redirect_valid) begin
      s1_redirect_reg_bits_r_robIdx_flag  <= redirect.robIdx_flag;
      s1_redirect_reg_bits_r_robIdx_value <= redirect.robIdx_value;
      s1_redirect_reg_bits_r_level        <= redirect.level;
    end
    // UIntToMask(sqIdx, 56) = (1 << sqIdx) - 1；sqIdx ≥ 56 时 one-hot 被截成 0，减 1 得全 1
    if (s0_fire) s1_sqIdx_mask <= SQ_SIZE'((64'h1 << s0_out.uop.sqIdx_value)) - SQ_SIZE'(1);
  end

  // ---- 冲刷与握手 ----
  logic s1_tlb_miss, s1_tlb_hit, s1_exception, s1_prf, s1_sw_prf;
  logic [1:0] s1_pbmt;
  logic [PADDR_W-1:0] s1_paddr_dup_lsu, s1_paddr_dup_dcache;

  always_comb begin
    s1_kill = s1_fast_rep_dly_kill_r & s1_in.isFastReplay     // 快速重发在 s3 被判"迟杀"
            | rob_need_flush(s1_in.uop.robIdx_flag, s1_in.uop.robIdx_value,
                             redirect_valid, redirect.level, redirect.robIdx_flag, redirect.robIdx_value)
            | rob_need_flush(s1_in.uop.robIdx_flag, s1_in.uop.robIdx_value,
                             s1_redirect_reg_valid_last_REG, s1_redirect_reg_bits_r_level,
                             s1_redirect_reg_bits_r_robIdx_flag, s1_redirect_reg_bits_r_robIdx_value)
              & ~s1_kill_last_REG;
    s1_ready = ~s1_valid | s1_kill | s2_ready;
    s1_fire  = s1_valid & ~s1_kill & s2_ready;

    s1_tlb_miss = tlb_resp.miss & tlb_resp_valid & s1_valid;
    s1_tlb_hit  = ~tlb_resp.miss & tlb_resp_valid & s1_valid;
    s1_pbmt     = s1_tlb_hit ? tlb_resp.pbmt_0 : PBMT_PMA;
    s1_prf      = s1_in.isPrefetch;
    s1_sw_prf   = s1_prf & ~s1_in.isHWPrefetch;
    s1_paddr_dup_lsu    = tlb_resp.paddr[0];
    s1_paddr_dup_dcache = tlb_resp.paddr[1];
    s1_exception = |(s1_out.uop.exceptionVec & LDU_EXC_MASK);   // 含 TLB 与触发器新报的
  end

  // ---- st-ld 违例（s1 先查一次；s2 还会再查一次）----
  // 更老的 store 在本拍写了与本 load 重叠的地址 → 本 load 读到的是旧值，要重发（nuke）。
  // 地址比较粒度由 store 的访问类型决定：整行 / 16 字节 / 8 字节。
  logic [1:0] s1_nuke_hit;
  always_comb begin
    st_query_t q [2];
    q[0] = stld_nuke_query_0;
    q[1] = stld_nuke_query_1;
    for (int w = 0; w < 2; w++) begin
      logic addr_match;
      if (q[w].bits_matchType == ST_MATCH_CACHELINE)
        addr_match = s1_paddr_dup_lsu[PADDR_W-1:6] == q[w].bits_paddr[PADDR_W-1:6];
      else if (q[w].bits_matchType == ST_MATCH_QUADWORD
               | (s1_in.isvec | s1_in.misalignWith16Byte) & s1_in.is128bit)
        addr_match = s1_paddr_dup_lsu[PADDR_W-1:4] == q[w].bits_paddr[PADDR_W-1:4];
      else
        addr_match = s1_paddr_dup_lsu[PADDR_W-1:3] == q[w].bits_paddr[PADDR_W-1:3];
      s1_nuke_hit[w] = q[w].valid
                     & ptr_after(s1_in.uop.robIdx_flag, s1_in.uop.robIdx_value,
                                 q[w].bits_robIdx_flag, q[w].bits_robIdx_value)
                     & addr_match & |(s1_in.mask & q[w].bits_mask);
    end
  end

  // ---- 调试触发器（MemTrigger 子模块：纯组合）----
  logic [3:0]          s1_trigger_action;
  logic [VADDR_W-1:0]  s1_trigger_vaddr;
  logic [VLEN_B-1:0]   s1_trigger_mask;
  logic                s1_trigger_debug_mode, s1_trigger_breakpoint;

  MemTrigger loadTrigger (
    .tdataVec_io_fromCsrTrigger_tdataVec_0_matchType   (trigger_csr.tdataVec_0_matchType),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_select      (trigger_csr.tdataVec_0_select),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_timing      (trigger_csr.tdataVec_0_timing),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_action      (trigger_csr.tdataVec_0_action),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_chain       (trigger_csr.tdataVec_0_chain),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_load        (trigger_csr.tdataVec_0_load),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_tdata2      (trigger_csr.tdataVec_0_tdata2),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_matchType   (trigger_csr.tdataVec_1_matchType),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_select      (trigger_csr.tdataVec_1_select),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_timing      (trigger_csr.tdataVec_1_timing),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_action      (trigger_csr.tdataVec_1_action),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_chain       (trigger_csr.tdataVec_1_chain),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_load        (trigger_csr.tdataVec_1_load),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_tdata2      (trigger_csr.tdataVec_1_tdata2),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_matchType   (trigger_csr.tdataVec_2_matchType),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_select      (trigger_csr.tdataVec_2_select),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_timing      (trigger_csr.tdataVec_2_timing),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_action      (trigger_csr.tdataVec_2_action),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_chain       (trigger_csr.tdataVec_2_chain),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_load        (trigger_csr.tdataVec_2_load),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_tdata2      (trigger_csr.tdataVec_2_tdata2),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_matchType   (trigger_csr.tdataVec_3_matchType),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_select      (trigger_csr.tdataVec_3_select),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_timing      (trigger_csr.tdataVec_3_timing),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_action      (trigger_csr.tdataVec_3_action),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_chain       (trigger_csr.tdataVec_3_chain),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_load        (trigger_csr.tdataVec_3_load),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_tdata2      (trigger_csr.tdataVec_3_tdata2),
    .tdataVec_io_fromCsrTrigger_tEnableVec_0           (trigger_csr.tEnableVec_0),
    .tdataVec_io_fromCsrTrigger_tEnableVec_1           (trigger_csr.tEnableVec_1),
    .tdataVec_io_fromCsrTrigger_tEnableVec_2           (trigger_csr.tEnableVec_2),
    .tdataVec_io_fromCsrTrigger_tEnableVec_3           (trigger_csr.tEnableVec_3),
    .tdataVec_io_fromCsrTrigger_debugMode              (trigger_csr.debugMode),
    .tdataVec_io_fromCsrTrigger_triggerCanRaiseBpExp   (trigger_csr.triggerCanRaiseBpExp),
    .tdataVec_io_fromLoadStore_vaddr                   (s1_out.fullva[VADDR_W-1:0]),
    .tdataVec_io_fromLoadStore_isVectorUnitStride      (s1_in.isvec & s1_in.is128bit),
    .tdataVec_io_fromLoadStore_mask                    (s1_in.mask),
    .tdataVec_io_toLoadStore_triggerAction             (s1_trigger_action),
    .tdataVec_io_toLoadStore_triggerVaddr              (s1_trigger_vaddr),
    .tdataVec_io_toLoadStore_triggerMask               (s1_trigger_mask),
    .tdataVec_io_isPrf                                 (s1_in.isPrefetch)
  );

  // ---- s1_out ----
  always_comb begin
    logic tlb_excp_pf, tlb_excp_gpf, tlb_excp_af;
    s1_trigger_debug_mode = s1_trigger_action == TRIG_ACT_DEBUG_MODE;
    s1_trigger_breakpoint = s1_trigger_action == TRIG_ACT_BREAKPOINT;

    s1_out                   = s1_in;
    s1_out.fullva            = s1_in.isFrmMisAlignBuf ? XLEN'(s1_in.vaddr) : tlb_resp.fullva;
    s1_out.vaNeedExt         = tlb_resp.excp_0_vaNeedExt;
    s1_out.isHyper           = tlb_resp.excp_0_isHyper;
    s1_out.paddr             = s1_paddr_dup_lsu;
    s1_out.gpaddr            = s1_in.isFastReplay ? XLEN'(s1_in.paddr) : tlb_resp.gpaddr_0;
    s1_out.isForVSnonLeafPTE = tlb_resp.isForVSnonLeafPTE;
    s1_out.tlbMiss           = s1_tlb_miss;
    s1_out.ptwBack           = tlb_resp.ptwBack;
    s1_out.rep_info_cause[C_NK] = (|s1_nuke_hit) & ~s1_tlb_miss & ~s1_sw_prf;
    s1_out.delayedLoadError  = 1'b0;          // 快速重发/指针追逐的延迟错误在本配置恒 0
    s1_out.nc                = (s1_in.nc | s1_pbmt == PBMT_NC) & ~s1_prf;
    s1_out.mmio              = s1_pbmt == PBMT_IO;

    // TLB 报的异常；不需要翻译的请求不采信
    tlb_excp_pf  = tlb_resp.excp_0_pf_ld  & s1_vecActive & ~s1_tlb_miss & ~s1_in.tlbNoQuery;
    tlb_excp_gpf = tlb_resp.excp_0_gpf_ld & ~s1_tlb_miss & ~s1_in.tlbNoQuery;
    tlb_excp_af  = tlb_resp.excp_0_af_ld  & s1_vecActive & ~s1_tlb_miss & ~s1_in.tlbNoQuery;
    s1_out.uop.exceptionVec[EXC_LD_PAGE]       = tlb_excp_pf;
    s1_out.uop.exceptionVec[EXC_LD_GUEST_PAGE] = tlb_excp_gpf;
    s1_out.uop.exceptionVec[EXC_LD_ACCESS]     = tlb_excp_af;
    if (REG & (tlb_excp_pf | tlb_excp_gpf | tlb_excp_af)) begin   // 页/访问异常优先于非对齐
      s1_out.uop.exceptionVec[EXC_LD_MISALIGN] = 1'b0;
      s1_out.isMisalign                        = 1'b0;
    end

    // 触发器：动作写进 uop.trigger，断点异常写进 exceptionVec
    s1_out.uop.trigger                       = s1_trigger_action;
    s1_out.uop.exceptionVec[EXC_BREAKPOINT]  = s1_trigger_breakpoint;
    // 向量：命中触发器时报告触发地址相对基址的偏移，否则报第一个活跃字节的偏移
    s1_out.vecVaddrOffset = (s1_trigger_debug_mode | s1_trigger_breakpoint)
                          ? VADDR_W'(s1_trigger_vaddr - s1_in.vecBaseVaddr)
                          : VADDR_W'(s1_in.vaddr + VADDR_W'(first_unmasked(s1_in.mask)) - s1_in.vecBaseVaddr);
    s1_out.vecTriggerMask = (s1_trigger_debug_mode | s1_trigger_breakpoint) ? s1_trigger_mask : '0;
  end

  // ---- 发往 DTLB / DCache / 前递源的 s1 信号 ----
  logic s1_fwd_query_valid;   // 没异常、没 TLB miss、没被杀、不是预取 → 才值得查前递
  always_comb begin
    s1_fwd_query_valid = s1_valid & ~(s1_exception | s1_tlb_miss | s1_kill | s1_prf);

    tlb_req_kill             = s1_kill;
    dcache_s1_paddr_dup_lsu    = s1_paddr_dup_lsu;
    dcache_s1_paddr_dup_dcache = s1_paddr_dup_dcache;
    dcache_s1_kill           = s1_kill | s1_tlb_miss | s1_exception | s1_misalign_kill;
    dcache_s1_kill_data_read = s1_misalign_kill;

    sbuffer_req.valid = s1_fwd_query_valid;
    sbuffer_req.vaddr = s1_in.vaddr;
    sbuffer_req.paddr = s1_paddr_dup_lsu;
    ubuffer_req.valid = s1_fwd_query_valid & s1_nc_with_data;
    ubuffer_req.vaddr = s1_in.vaddr;
    ubuffer_req.paddr = s1_paddr_dup_lsu;

    lsq_fwd_req            = '0;
    lsq_fwd_req.valid      = s1_fwd_query_valid;
    lsq_fwd_req.vaddr      = s1_in.vaddr;
    lsq_fwd_req.paddr      = s1_paddr_dup_lsu;
    lsq_fwd_req.uop        = s1_in.uop;
    lsq_fwd_req.sqIdx_flag = s1_in.uop.sqIdx_flag;
    lsq_fwd_req.sqIdxMask  = s1_sqIdx_mask;
    lsq_fwd_req.mask       = s1_in.mask;

    // 等 D 通道回填的 cache miss 重发：问 MSHR 要数据
    mshr_fwd_req.valid  = s1_valid & s1_out.forward_tlDchannel;
    mshr_fwd_req.mshrid = s1_out.mshrid;
    mshr_fwd_req.paddr  = s1_out.paddr;
  end

  // ===================================================================
  // s2：拿 DCache 应答与各路前递结果，判定异常、MMIO/NC 与 replay 原因
  // -------------------------------------------------------------------
  // 输入：s2_in、pmp（与 s2 同拍）、dcache_resp、sbuffer/ubuffer/SQ 前递结果、MSHR 前递、
  //       s1 预先锁存的 D 通道前递数据、两条 store 流水的违例广播、RAR/RAW 队列的 ready。
  // 要点：
  //   * 数据来源优先级（每字节）：SQ 前递 > (NC 时 ubuffer / 否则 sbuffer) > D 通道/MSHR/DCache；
  //   * "麻烦"（troublem）= 没异常、不是走 uncache 的（NC 带数据的除外）、不是预取：
  //     只有麻烦的 load 才会记录 replay 原因；
  //   * 快速重发：DCache 忙（mq nack / bank 冲突）或被 store 撞，而没有别的更慢的原因时，
  //     s3 直接回灌 s0，不进 LQ。
  // ===================================================================
  logic s2_valid, s2_vecActive, s2_isvec, s2_trigger_debug_mode, s2_nc_with_data, s2_tlb_hit;
  logic [1:0] s2_pbmt;
  logic s2_mmio_req_valid_REG, s2_mmio_req_valid_REG_1;   // uncache.fire 打两拍
  logic s3_misalign_wakeup_req_valid_REG, s3_misalign_wakeup_req_valid_REG_1,
        s3_misalign_wakeup_req_valid_REG_2;                // 非对齐唤醒 fire 打三拍
  logic s2_mis_align_last_REG;                              // hd_misalign_ld_enable 打一拍
  logic s2_mem_amb_REG, s2_fwd_fail_REG;                    // lsq_forward.valid 打一拍
  logic io_s2_ptr_chasing_r;
  logic [5:0] s2_ld_valid_dup;
  logic REG_1, REG_2;          // golden 名：s2 流水有效位自检断言用的两拍（不影响输出）

  // D 通道前递：s1 算好"这拍回填的就是我要的那半行"，把对应 16 字节锁存到 s2
  // （寄存器保持 golden 的展平名以便逐名配对，下面用数组视图访问）
  logic       s2_fwd_frm_d_chan, s2_d_denied, s2_d_corrupt;
  logic [7:0] s2_fwd_data_frm_d_chan_0,  s2_fwd_data_frm_d_chan_1,  s2_fwd_data_frm_d_chan_2,
              s2_fwd_data_frm_d_chan_3,  s2_fwd_data_frm_d_chan_4,  s2_fwd_data_frm_d_chan_5,
              s2_fwd_data_frm_d_chan_6,  s2_fwd_data_frm_d_chan_7,  s2_fwd_data_frm_d_chan_8,
              s2_fwd_data_frm_d_chan_9,  s2_fwd_data_frm_d_chan_10, s2_fwd_data_frm_d_chan_11,
              s2_fwd_data_frm_d_chan_12, s2_fwd_data_frm_d_chan_13, s2_fwd_data_frm_d_chan_14,
              s2_fwd_data_frm_d_chan_15;
  logic [127:0] s2_d_chan_data;
  assign s2_d_chan_data = {s2_fwd_data_frm_d_chan_15, s2_fwd_data_frm_d_chan_14, s2_fwd_data_frm_d_chan_13,
                           s2_fwd_data_frm_d_chan_12, s2_fwd_data_frm_d_chan_11, s2_fwd_data_frm_d_chan_10,
                           s2_fwd_data_frm_d_chan_9,  s2_fwd_data_frm_d_chan_8,  s2_fwd_data_frm_d_chan_7,
                           s2_fwd_data_frm_d_chan_6,  s2_fwd_data_frm_d_chan_5,  s2_fwd_data_frm_d_chan_4,
                           s2_fwd_data_frm_d_chan_3,  s2_fwd_data_frm_d_chan_2,  s2_fwd_data_frm_d_chan_1,
                           s2_fwd_data_frm_d_chan_0};

  // D 通道一拍回填 256 位 = 半行 32B = 4 个 64 位块；按 paddr[4:3] 取本 load 需要的 16 字节
  logic         s1_d_chan_match;
  logic [127:0] s1_d_chan_sel;
  always_comb begin
    logic [63:0] blk [4];
    logic [1:0]  idx;
    for (int i = 0; i < 4; i++) blk[i] = tl_d_channel.data[64*i +: 64];
    idx = s1_out.paddr[4:3];
    // paddr[3]=1：低 8 字节也放第 idx 块（数据右移 8 字节的情形）；否则拼 idx+1、idx（回绕）
    s1_d_chan_sel   = s1_out.paddr[3] ? {blk[idx], blk[idx]} : {blk[2'(idx + 2'd1)], blk[idx]};
    s1_d_chan_match = mshr_fwd_req.valid & tl_d_channel.valid
                    & (s1_out.mshrid == tl_d_channel.mshrid)
                    & (s1_out.paddr[5] == tl_d_channel.last);
  end

  always_ff @(posedge clock or posedge reset)
    if (reset) begin
      s2_valid                <= 1'b0;
      s2_vecActive            <= 1'b1;
      s2_isvec                <= 1'b0;
      s2_trigger_debug_mode   <= 1'b0;
      s2_mmio_req_valid_REG   <= 1'b0;
      s2_mmio_req_valid_REG_1 <= 1'b0;
      s3_misalign_wakeup_req_valid_REG   <= 1'b0;
      s3_misalign_wakeup_req_valid_REG_1 <= 1'b0;
      s3_misalign_wakeup_req_valid_REG_2 <= 1'b0;
      s2_mis_align_last_REG   <= 1'b0;
      s2_fwd_frm_d_chan       <= 1'b0;
      {s2_fwd_data_frm_d_chan_15, s2_fwd_data_frm_d_chan_14, s2_fwd_data_frm_d_chan_13,
       s2_fwd_data_frm_d_chan_12, s2_fwd_data_frm_d_chan_11, s2_fwd_data_frm_d_chan_10,
       s2_fwd_data_frm_d_chan_9,  s2_fwd_data_frm_d_chan_8,  s2_fwd_data_frm_d_chan_7,
       s2_fwd_data_frm_d_chan_6,  s2_fwd_data_frm_d_chan_5,  s2_fwd_data_frm_d_chan_4,
       s2_fwd_data_frm_d_chan_3,  s2_fwd_data_frm_d_chan_2,  s2_fwd_data_frm_d_chan_1,
       s2_fwd_data_frm_d_chan_0} <= '0;
      s2_d_denied             <= 1'b0;
      s2_d_corrupt            <= 1'b0;
      io_s2_ptr_chasing_r     <= 1'b0;
      s2_ld_valid_dup         <= 6'h0;
    end else begin
      s2_valid <= s1_fire | ~(s2_fire | s2_kill) & s2_valid;
      if (s1_fire) begin
        s2_vecActive          <= s1_out.vecActive;
        s2_isvec              <= s1_out.isvec;
        s2_trigger_debug_mode <= s1_trigger_debug_mode;
        io_s2_ptr_chasing_r   <= s1_try_ptr_chasing_last_REG;
      end
      s2_mmio_req_valid_REG   <= s0_mmio_fire & lsq_uncache_valid;
      s2_mmio_req_valid_REG_1 <= s2_mmio_req_valid_REG;
      s3_misalign_wakeup_req_valid_REG   <= misalign_ldin.misalignNeedWakeUp & misalign_ldin_fire;
      s3_misalign_wakeup_req_valid_REG_1 <= s3_misalign_wakeup_req_valid_REG;
      s3_misalign_wakeup_req_valid_REG_2 <= s3_misalign_wakeup_req_valid_REG_1;
      s2_mis_align_last_REG <= csrCtrl.hd_misalign_ld_enable;
      s2_fwd_frm_d_chan     <= s1_d_chan_match;
      if (s1_d_chan_match) begin
        {s2_fwd_data_frm_d_chan_15, s2_fwd_data_frm_d_chan_14, s2_fwd_data_frm_d_chan_13,
         s2_fwd_data_frm_d_chan_12, s2_fwd_data_frm_d_chan_11, s2_fwd_data_frm_d_chan_10,
         s2_fwd_data_frm_d_chan_9,  s2_fwd_data_frm_d_chan_8,  s2_fwd_data_frm_d_chan_7,
         s2_fwd_data_frm_d_chan_6,  s2_fwd_data_frm_d_chan_5,  s2_fwd_data_frm_d_chan_4,
         s2_fwd_data_frm_d_chan_3,  s2_fwd_data_frm_d_chan_2,  s2_fwd_data_frm_d_chan_1,
         s2_fwd_data_frm_d_chan_0} <= s1_d_chan_sel;
        s2_d_denied  <= tl_d_channel.denied;
        s2_d_corrupt <= tl_d_channel.corrupt;
      end
      // 数据写使能的 6 份复制（dirty 位复制，给 LQ 数据阵列扇出用）
      s2_ld_valid_dup <= (s1_kill | s1_out.isHWPrefetch) ? 6'h0
                       : {6{s1_valid & ~s1_kill & s2_ready & ~s1_out.isHWPrefetch}};
    end

  always_ff @(posedge clock) begin
    if (s1_fire) s2_pbmt <= s1_pbmt;
    s2_nc_with_data <= s1_nc_with_data;
    s2_tlb_hit      <= s1_tlb_hit;
    s2_mem_amb_REG  <= lsq_fwd_req.valid;
    s2_fwd_fail_REG <= lsq_fwd_req.valid;
    REG_1 <= s1_out.isHWPrefetch;
    REG_2 <= (s2_valid == s2_ld_valid_dup[0]) | REG_1;
  end

  // ---- 冲刷与握手 ----
  always_comb begin
    s2_kill  = rob_need_flush(s2_in.uop.robIdx_flag, s2_in.uop.robIdx_value,
                              redirect_valid, redirect.level, redirect.robIdx_flag, redirect.robIdx_value);
    s2_ready = ~s2_valid | s2_kill | s3_ready;
    s2_fire  = s2_valid & ~s2_kill & s3_ready;
  end

  // ---- 异常、uncache 判定 ----
  logic        s2_prf, s2_hw_prf, s2_un_access_exception;
  logic        s2_actually_uncache, s2_actually_all_mmio, s2_actually_pbmt_nc, s2_uncache;
  logic        s2_exc_clear;                 // 预取、或 TLB miss 且不是断点：清掉所有异常
  logic [23:0] s2_exception_vec;
  logic        s2_isMisalign, s2_exception, s2_mis_align, s2_mmio;

  always_comb begin
    s2_prf    = s2_in.isPrefetch;
    s2_hw_prf = s2_in.isHWPrefetch;
    // 地址翻译已出错时，PMP/PMA 的结果不可信
    s2_un_access_exception = s2_vecActive & (s2_in.uop.exceptionVec[EXC_LD_ACCESS]
                                             | s2_in.uop.exceptionVec[EXC_LD_PAGE]
                                             | s2_in.uop.exceptionVec[EXC_LD_GUEST_PAGE]);
    // 物理地址落在 uncache 空间：PMA 说是 MMIO（且没有读权限错误），或 Svpbmt 说 NC/IO
    s2_actually_uncache  = ~s2_in.tlbMiss & ~s2_un_access_exception & (s2_pbmt == PBMT_PMA)
                           & pmp.mmio & ~pmp.ld
                         | s2_in.nc | s2_in.mmio;
    s2_actually_all_mmio = ~s2_in.tlbMiss & ~s2_un_access_exception
                         & ((s2_pbmt == PBMT_PMA) & ~pmp.st & pmp.mmio | s2_in.mmio);
    s2_actually_pbmt_nc  = ~s2_in.tlbMiss & ~s2_un_access_exception & s2_in.nc;
    s2_uncache           = ~s2_prf & s2_actually_uncache;

    s2_exception_vec = s2_in.uop.exceptionVec;
    s2_exception_vec[EXC_LD_ACCESS] = s2_vecActive & (s2_in.uop.exceptionVec[EXC_LD_ACCESS]
                                                      | pmp.ld
                                                      | pmp.instr & is_hlvx(s2_in.uop.fuOpType)
                                                      | s2_isvec & s2_uncache);
    s2_isMisalign = s2_in.isMisalign;
    // 软件预取不报任何异常；TLB miss 的异常都是假的（断点除外，它与地址翻译无关）
    s2_exc_clear = s2_prf | s2_in.tlbMiss & ~s2_in.uop.exceptionVec[EXC_BREAKPOINT];
    if (s2_exc_clear) begin
      s2_exception_vec = '0;
      s2_isMisalign    = 1'b0;
    end
    s2_exception = s2_vecActive & (s2_trigger_debug_mode | |(s2_exception_vec & LDU_EXC_MASK));

    // 硬件非对齐处理：打开开关、不是 16B 内能一次做完的、没有更高优先级的断点/调试、不是 uncache
    s2_mis_align = s2_valid & s2_mis_align_last_REG & s2_isMisalign & ~s2_in.misalignWith16Byte
                 & ~s2_exception_vec[EXC_BREAKPOINT] & ~s2_trigger_debug_mode & ~s2_uncache;

    // MMIO：Svpbmt 标了 NC/IO 就听页表的（IO 才算 MMIO），否则听 PMA
    s2_mmio = ~s2_prf & ~s2_exception & ~s2_in.tlbMiss
            & ((s2_pbmt == PBMT_NC | s2_pbmt == PBMT_IO) ? s2_in.mmio : s2_tlb_hit & pmp.mmio);
  end

  // ---- 前递合并 ----
  logic [VLEN_B-1:0]      s2_fwd_mask;
  logic [VLEN_B-1:0][7:0] s2_fwd_data;
  logic                   s2_full_fwd;
  logic                   s2_fwd_frm_d_chan_or_mshr;

  always_comb begin
    for (int i = 0; i < VLEN_B; i++) begin
      s2_fwd_mask[i] = lsq_fwd_resp.forwardMask[i] | sbuffer_resp.forwardMask[i] | ubuffer_resp.forwardMask[i];
      s2_fwd_data[i] = lsq_fwd_resp.forwardMask[i] ? lsq_fwd_resp.forwardData[i]
                     : s2_nc_with_data             ? ubuffer_resp.forwardData[i]
                     :                               sbuffer_resp.forwardData[i];
    end
    // 所需字节全部由前递提供，且 SQ 没有"数据未就绪"
    s2_full_fwd = ((~s2_fwd_mask & s2_in.mask) == '0) & ~lsq_fwd_resp.dataInvalid;
    // D 通道 / MSHR 前递成功（结果有效且确实来自其一）
    s2_fwd_frm_d_chan_or_mshr = mshr_fwd_resp.forward_result_valid
                              & (s2_fwd_frm_d_chan | mshr_fwd_resp.forward_mshr);
  end

  // ---- replay 原因 ----
  logic s2_mem_amb, s2_fwd_fail, s2_dcache_miss, s2_mq_nack, s2_bank_conflict, s2_wpu_pred_fail;
  logic s2_rar_nack, s2_raw_nack, s2_nuke, s2_troublem;
  logic s2_dcache_fast_rep, s2_nuke_fast_rep, s2_fast_rep, s2_can_query;

  always_comb begin
    logic [1:0] nuke_hit;
    st_query_t  q [2];
    // 数据被 D 通道 / MSHR / 前递完全覆盖时，DCache 的 miss / nack / 冲突都不算数；NC 不访问 DCache
    logic dcache_matters;
    dcache_matters   = ~s2_fwd_frm_d_chan_or_mshr & ~s2_full_fwd & ~s2_in.nc;
    s2_mem_amb       = s2_in.uop.storeSetHit & lsq_fwd_resp.addrInvalid & s2_mem_amb_REG;
    s2_fwd_fail      = lsq_fwd_resp.dataInvalid & s2_fwd_fail_REG;
    s2_dcache_miss   = dcache_resp.miss & dcache_matters;
    s2_mq_nack       = dcache_s2_mq_nack & dcache_matters;
    s2_bank_conflict = dcache_s2_bank_conflict & dcache_matters;
    s2_wpu_pred_fail = 1'b0;              // 本配置没有路预测
    s2_rar_nack      = lsq_ldld_nuke_query_req_valid & ~lsq_ldld_nuke_query_req_ready;
    s2_raw_nack      = lsq_stld_nuke_query_req_valid & ~lsq_stld_nuke_query_req_ready;

    // st-ld 违例 s2 再查一次（用 s2 的 paddr），并继承 s1 已查出的
    q[0] = stld_nuke_query_0;
    q[1] = stld_nuke_query_1;
    for (int w = 0; w < 2; w++) begin
      logic addr_match;
      if (q[w].bits_matchType == ST_MATCH_CACHELINE)
        addr_match = s2_in.paddr[PADDR_W-1:6] == q[w].bits_paddr[PADDR_W-1:6];
      else if (q[w].bits_matchType == ST_MATCH_QUADWORD
               | (s2_in.isvec | s2_in.misalignWith16Byte) & s2_in.is128bit)
        addr_match = s2_in.paddr[PADDR_W-1:4] == q[w].bits_paddr[PADDR_W-1:4];
      else
        addr_match = s2_in.paddr[PADDR_W-1:3] == q[w].bits_paddr[PADDR_W-1:3];
      nuke_hit[w] = q[w].valid
                  & ptr_after(s2_in.uop.robIdx_flag, s2_in.uop.robIdx_value,
                              q[w].bits_robIdx_flag, q[w].bits_robIdx_value)
                  & addr_match & |(s2_in.mask & q[w].bits_mask);
    end
    s2_nuke = (|nuke_hit) & ~s2_in.tlbMiss | s2_in.rep_info_cause[C_NK];

    // 只有"麻烦的" load 才记 replay：没异常、不是走 uncache 的（NC 带数据的除外）、不是预取
    s2_troublem = ~s2_exception & (~s2_uncache | s2_nc_with_data) & ~s2_prf & ~s2_in.delayedLoadError;

    // 快速重发：DCache 忙或被 store 撞，且不是更慢的那几类原因
    s2_dcache_fast_rep = s2_mq_nack | ~s2_dcache_miss & (s2_bank_conflict | s2_wpu_pred_fail);
    s2_nuke_fast_rep   = ~s2_mq_nack & ~s2_dcache_miss & ~s2_bank_conflict & ~s2_wpu_pred_fail & s2_nuke;
    s2_fast_rep        = ~s2_in.isFastReplay & ~s2_mem_amb & ~s2_in.tlbMiss & ~s2_fwd_fail
                       & (s2_dcache_fast_rep | s2_nuke_fast_rep) & s2_troublem;
    // 要快速重发的（bank 冲突/wpu）或 s1 已被撞的，不必登记 RAW 队列
    s2_can_query = ~(~s2_dcache_miss & (s2_bank_conflict | s2_wpu_pred_fail) | s2_in.rep_info_cause[C_NK])
                 & s2_troublem;
  end

  // ---- 真正的异常向量（加上前递通路报的 denied / corrupt，与 uncache 的非对齐）----
  logic [23:0] s2_real_exceptionVec;
  logic        s2_real_exception, s2_fwd_vp_match_invalid, s2_vp_match_fail;
  logic        s2_safe_wakeup, s2_safe_writeback;

  always_comb begin
    logic mshr_fwd_ok;
    mshr_fwd_ok = mshr_fwd_resp.forward_result_valid & mshr_fwd_resp.forward_mshr;
    s2_real_exceptionVec = s2_exception_vec;
    // NC 上的非对齐访问：报非对齐异常（NC 不走硬件非对齐拆分）
    s2_real_exceptionVec[EXC_LD_MISALIGN] = (s2_isMisalign | s2_in.isFrmMisAlignBuf) & s2_actually_pbmt_nc
                                          & ~s2_isvec & ~s2_prf;
    // 回填数据被拒（denied）→ 访问错误；MMIO 上的非对齐访问也报访问错误
    s2_real_exceptionVec[EXC_LD_ACCESS] = (s2_exception_vec[EXC_LD_ACCESS]
                                           | s2_fwd_frm_d_chan & s2_d_denied
                                           | mshr_fwd_ok & mshr_fwd_resp.denied) & ~s2_prf
                                        | (s2_isMisalign | s2_in.isFrmMisAlignBuf) & s2_actually_all_mmio;
    // 回填数据损坏（corrupt，且没被拒）→ 硬件错误
    s2_real_exceptionVec[EXC_HW_ERROR]  = (s2_exception_vec[EXC_HW_ERROR]
                                           | s2_fwd_frm_d_chan & s2_d_corrupt & ~s2_d_denied
                                           | mshr_fwd_ok & mshr_fwd_resp.corrupt & ~mshr_fwd_resp.denied)
                                        & ~s2_prf;
    s2_real_exception = s2_vecActive & (s2_trigger_debug_mode | |(s2_real_exceptionVec & LDU_EXC_MASK));

    // 前递时发现"虚地址匹配但物理地址不匹配"（别名）→ 从取指重发
    s2_fwd_vp_match_invalid = lsq_fwd_resp.matchInvalid | sbuffer_resp.matchInvalid | ubuffer_resp.matchInvalid;
    s2_vp_match_fail        = s2_fwd_vp_match_invalid & s2_troublem;
  end

  // ---- s2_out ----
  always_comb begin
    s2_out                  = s2_in;
    s2_out.mmio             = s2_mmio;
    s2_out.memBackTypeMM    = ~pmp.mmio;
    s2_out.isMisalign       = s2_isMisalign;
    s2_out.uop.flushPipe    = 1'b0;
    s2_out.uop.exceptionVec = s2_real_exceptionVec;
    s2_out.handledByMSHR    = dcache_resp.handled;
    s2_out.miss             = s2_dcache_miss & s2_troublem;
    s2_out.feedbacked       = 1'b0;            // 快速反馈已取消，恒 0
    // 向量 vstart：首发时由"出错元素相对基址的偏移 / 元素宽度"算出；重发的沿用
    s2_out.uop.vpu_vstart   = (s2_in.isLoadReplay | s2_in.isFastReplay)
                            ? s2_in.uop.vpu_vstart
                            : 8'(s2_in.vecVaddrOffset >> s2_in.uop.vpu_veew);

    s2_out.rep_info_cause[C_MA]  = s2_mem_amb       & s2_troublem;
    s2_out.rep_info_cause[C_TM]  = s2_in.tlbMiss    & s2_troublem;
    s2_out.rep_info_cause[C_FF]  = s2_fwd_fail      & s2_troublem;
    s2_out.rep_info_cause[C_DR]  = s2_mq_nack       & s2_troublem;
    s2_out.rep_info_cause[C_DM]  = s2_dcache_miss   & s2_troublem;
    s2_out.rep_info_cause[C_WF]  = s2_wpu_pred_fail & s2_troublem;
    s2_out.rep_info_cause[C_BC]  = s2_bank_conflict & s2_troublem;
    s2_out.rep_info_cause[C_RAR] = s2_rar_nack      & s2_troublem;
    s2_out.rep_info_cause[C_RAW] = s2_raw_nack      & s2_troublem;
    s2_out.rep_info_cause[C_NK]  = s2_nuke          & s2_troublem;
    s2_out.rep_info_full_fwd              = s2_dcache_miss & s2_full_fwd;   // miss 但数据已全部前递到
    s2_out.rep_info_data_inv_sq_idx_flag  = lsq_fwd_resp.dataInvalidSqIdx_flag;
    s2_out.rep_info_data_inv_sq_idx_value = lsq_fwd_resp.dataInvalidSqIdx_value;
    s2_out.rep_info_addr_inv_sq_idx_flag  = lsq_fwd_resp.addrInvalidSqIdx_flag;
    s2_out.rep_info_addr_inv_sq_idx_value = lsq_fwd_resp.addrInvalidSqIdx_value;
    s2_out.rep_info_mshr_id               = dcache_resp.mshr_id;
    s2_out.rep_info_last_beat             = s2_in.paddr[5];    // 在回填的第几半行
    s2_out.rep_info_tlb_id                = tlb_hint.id;
    s2_out.rep_info_tlb_full              = tlb_hint.full;

    // 能否"安全唤醒"：不用重发、不是 MMIO、NC 只在带数据时、不走非对齐拆分、没异常
    s2_safe_wakeup    = ~|s2_out.rep_info_cause & ~s2_mmio & (~s2_in.nc | s2_nc_with_data)
                      & ~s2_mis_align & ~s2_real_exception;
    s2_safe_writeback = s2_real_exception | s2_safe_wakeup | s2_vp_match_fail;
  end

  // ---- RAR / RAW 违例队列登记 ----
  // RAR 队列与虚拟 LQ 等大：除预取外都登记；RAW 只登记能查询的。非对齐子访问不登记。
  always_comb begin
    logic data_valid;
    data_valid = (s2_full_fwd | mshr_fwd_resp.forward_result_valid | s2_nc_with_data) ? 1'b1 : ~s2_dcache_miss;

    lsq_ldld_nuke_query_req_valid = s2_valid & ~s2_prf & ~s2_in.isFrmMisAlignBuf;
    ldld_nuke_req            = '0;
    ldld_nuke_req.uop        = s2_in.uop;
    ldld_nuke_req.mask       = s2_in.mask;
    ldld_nuke_req.paddr      = s2_in.paddr;
    ldld_nuke_req.data_valid = data_valid;
    ldld_nuke_req.is_nc      = s2_nc_with_data;

    lsq_stld_nuke_query_req_valid = s2_valid & s2_can_query & ~s2_in.isFrmMisAlignBuf;
    stld_nuke_req            = ldld_nuke_req;
  end

  // ---- 预取训练（s2 判定，s3 送出）与 DCache s2_kill ----
  logic io_prefetch_train_valid_last_REG, io_prefetch_train_l1_valid_last_REG;
  logic io_prefetch_train_bits_miss_r, io_prefetch_train_l1_bits_miss_r;
  logic [2:0] io_prefetch_train_bits_meta_prefetch_r, io_prefetch_train_l1_bits_meta_prefetch_r;
  logic s2_prefetch_train_valid, s2_prefetch_train_l1_valid;

  always_comb begin
    s2_prefetch_train_valid    = s2_valid & ~s2_actually_uncache & (~s2_in.tlbMiss | s2_hw_prf);
    s2_prefetch_train_l1_valid = s2_valid & ~s2_actually_uncache;
    dcache_s2_kill = pmp.ld | pmp.st | s2_actually_uncache | s2_kill;
    s1_prefetch_spec    = s1_fire;
    s2_prefetch_spec    = s2_prefetch_train_valid;
    s1_prefetch_spec_l1 = s1_fire;
    s2_prefetch_spec_l1 = s2_prefetch_train_l1_valid;
  end

  always_ff @(posedge clock or posedge reset)
    if (reset) begin
      io_prefetch_train_valid_last_REG    <= 1'b0;
      io_prefetch_train_l1_valid_last_REG <= 1'b0;
    end else begin
      io_prefetch_train_valid_last_REG    <= s2_prefetch_train_valid;
      io_prefetch_train_l1_valid_last_REG <= s2_prefetch_train_l1_valid;
    end

  always_ff @(posedge clock) begin
    if (s2_prefetch_train_valid) begin
      io_prefetch_train_bits_miss_r          <= dcache_resp.miss;
      io_prefetch_train_bits_meta_prefetch_r <= dcache_resp.meta_prefetch;
    end
    if (s2_prefetch_train_l1_valid) begin
      io_prefetch_train_l1_bits_miss_r          <= dcache_resp.miss;
      io_prefetch_train_l1_bits_meta_prefetch_r <= dcache_resp.meta_prefetch;
    end
  end

  always_comb begin
    prefetch_train_valid              = io_prefetch_train_valid_last_REG;
    prefetch_train                    = '0;
    prefetch_train.uop                = pf_train_in.uop;
    prefetch_train.vaddr              = pf_train_in.vaddr;
    prefetch_train.paddr              = pf_train_in.paddr;
    prefetch_train.isFirstIssue       = pf_train_in.isFirstIssue;
    prefetch_train.miss               = io_prefetch_train_bits_miss_r;
    prefetch_train.meta_prefetch      = io_prefetch_train_bits_meta_prefetch_r;
    prefetch_train_l1_valid           = io_prefetch_train_l1_valid_last_REG;
    prefetch_train_l1                 = '0;
    prefetch_train_l1.uop             = pf_train_l1_in.uop;
    prefetch_train_l1.vaddr           = pf_train_l1_in.vaddr;
    prefetch_train_l1.paddr           = pf_train_l1_in.paddr;
    prefetch_train_l1.isFirstIssue    = pf_train_l1_in.isFirstIssue;
    prefetch_train_l1.miss            = io_prefetch_train_l1_bits_miss_r;
    prefetch_train_l1.meta_prefetch   = io_prefetch_train_l1_bits_meta_prefetch_r;
    s2_ptr_chasing                    = io_s2_ptr_chasing_r;
  end

  // ---- s2 的合并数据（s3 用）：D 通道/MSHR/DCache 三选一，再按字节叠上 SQ/sbuffer 前递 ----
  logic [127:0] s2_merged_data;
  always_comb begin
    logic [127:0] tl_data, dcache_data;
    logic         use_d, use_mshr;
    // NC 带数据：数据按 paddr[3] 挪到 16B 块的对应半边
    dcache_data = s2_nc_with_data ? (s2_in.paddr[3] ? {s2_in.data[63:0], 64'h0} : s2_in.data[127:0])
                                  : dcache_resp.data;
    use_d    = s2_fwd_frm_d_chan & ~s2_nc_with_data & mshr_fwd_resp.forward_result_valid;
    use_mshr = mshr_fwd_resp.forward_mshr & ~s2_nc_with_data & mshr_fwd_resp.forward_result_valid;
    tl_data  = (use_d | use_mshr) ? (use_d ? s2_d_chan_data : mshr_fwd_resp.forwardData) : dcache_data;
    for (int i = 0; i < VLEN_B; i++)
      s2_merged_data[8*i +: 8] = s2_fwd_mask[i] ? s2_fwd_data[i] : tl_data[8*i +: 8];
  end

  // ===================================================================
  // s3：写回 / 写 LQ / 快速重发 / 进非对齐缓冲 / 回滚
  // -------------------------------------------------------------------
  // 输入：s3_in、s2 锁存的结果（safe_wakeup/writeback、异常、数据选择等）、
  //       dcache_resp 的延迟 TL 错误、RAR 查询结果、非对齐缓冲 ready、ROB 队头。
  // 去向：
  //   * 能安全写回的：标量 → ldout，向量 → vecldout；
  //   * 需要重发的：写 LQ（lsq_ldin），replay 原因取优先级最高的一个；
  //   * 可快速重发的：fast_rep_out 回灌 s0（若 s0 这拍被更高优先级占用则改写 LQ）；
  //   * 跨 16B 的非对齐：只有 ROB 队头的才进非对齐缓冲，否则当 misalign_nack 重发；
  //   * RAR 违例 / 前递别名：回滚（rollback）从取指重来。
  //   MMIO 的写回包从 uncache 打三拍过来，与主流水共用 ldout（主流水优先）。
  // ===================================================================
  logic s3_valid_last_REG;     // = s3_valid
  logic s3_fast_rep_REG;       // = s3_fast_rep
  logic s3_nc_with_data, s3_troublem_last_REG, s3_vecActive, s3_isvec;
  logic [2:0] s3_vec_alignedType;
  logic [3:0] s3_vec_mBIndex;
  logic s3_mmio_req_valid;
  logic [7:0] s3_pdest;
  logic s3_rfWen, s3_fpWen;
  logic [8:0] s3_data_select;
  // s3 数据按 paddr[3:0] 选起始字节（one-hot；golden 展平名）
  logic s3_data_select_by_offset_0,  s3_data_select_by_offset_1,  s3_data_select_by_offset_2,
        s3_data_select_by_offset_3,  s3_data_select_by_offset_4,  s3_data_select_by_offset_5,
        s3_data_select_by_offset_6,  s3_data_select_by_offset_7,  s3_data_select_by_offset_8,
        s3_data_select_by_offset_9,  s3_data_select_by_offset_10, s3_data_select_by_offset_11,
        s3_data_select_by_offset_12, s3_data_select_by_offset_13, s3_data_select_by_offset_14,
        s3_data_select_by_offset_15;
  logic [15:0] s3_data_sel_offset;
  assign s3_data_sel_offset = {s3_data_select_by_offset_15, s3_data_select_by_offset_14,
                               s3_data_select_by_offset_13, s3_data_select_by_offset_12,
                               s3_data_select_by_offset_11, s3_data_select_by_offset_10,
                               s3_data_select_by_offset_9,  s3_data_select_by_offset_8,
                               s3_data_select_by_offset_7,  s3_data_select_by_offset_6,
                               s3_data_select_by_offset_5,  s3_data_select_by_offset_4,
                               s3_data_select_by_offset_3,  s3_data_select_by_offset_2,
                               s3_data_select_by_offset_1,  s3_data_select_by_offset_0};
  logic s3_safe_wakeup, s3_safe_writeback, s3_exception, s3_mis_align_r, s3_misalign_can_go;
  logic s3_vp_match_fail_last_REG, s3_ldld_rep_inst_last_REG;
  logic [127:0] s3_merged_data_frm_pipe;
  logic s3_ldout_valid_REG;
  logic REG_3, REG_4;          // golden 名：NC 性能计数用的两拍（不影响输出）

  always_ff @(posedge clock or posedge reset)
    if (reset) begin
      s3_valid_last_REG         <= 1'b0;
      s3_troublem_last_REG      <= 1'b0;
      s3_vecActive              <= 1'b1;
      s3_isvec                  <= 1'b0;
      s3_data_select            <= 9'h0;
      {s3_data_select_by_offset_15, s3_data_select_by_offset_14, s3_data_select_by_offset_13,
       s3_data_select_by_offset_12, s3_data_select_by_offset_11, s3_data_select_by_offset_10,
       s3_data_select_by_offset_9,  s3_data_select_by_offset_8,  s3_data_select_by_offset_7,
       s3_data_select_by_offset_6,  s3_data_select_by_offset_5,  s3_data_select_by_offset_4,
       s3_data_select_by_offset_3,  s3_data_select_by_offset_2,  s3_data_select_by_offset_1,
       s3_data_select_by_offset_0} <= 16'h0;
      s3_vp_match_fail_last_REG <= 1'b0;
      s3_ldld_rep_inst_last_REG <= 1'b0;
    end else begin
      // 进 s3：s2 有效、不是硬件预取（预取到 s2 就结束）、没被本拍的重定向冲掉
      s3_valid_last_REG    <= s2_valid & ~s2_out.isHWPrefetch
                            & ~rob_need_flush(s2_out.uop.robIdx_flag, s2_out.uop.robIdx_value,
                                              redirect_valid, redirect.level,
                                              redirect.robIdx_flag, redirect.robIdx_value);
      s3_troublem_last_REG <= s2_troublem;
      if (s2_fire) begin
        s3_vecActive   <= s2_out.vecActive;
        s3_isvec       <= s2_out.isvec;
        s3_data_select <= gen_rdata_oh(s2_out.uop.fuOpType, s2_out.uop.fpWen);
        // genDataSelectByOffset：paddr[3:0] 译成 16 位 one-hot
        {s3_data_select_by_offset_15, s3_data_select_by_offset_14, s3_data_select_by_offset_13,
         s3_data_select_by_offset_12, s3_data_select_by_offset_11, s3_data_select_by_offset_10,
         s3_data_select_by_offset_9,  s3_data_select_by_offset_8,  s3_data_select_by_offset_7,
         s3_data_select_by_offset_6,  s3_data_select_by_offset_5,  s3_data_select_by_offset_4,
         s3_data_select_by_offset_3,  s3_data_select_by_offset_2,  s3_data_select_by_offset_1,
         s3_data_select_by_offset_0} <= 16'h1 << s2_out.paddr[3:0];
      end
      s3_vp_match_fail_last_REG <= s2_fwd_vp_match_invalid;
      s3_ldld_rep_inst_last_REG <= csrCtrl.ldld_vio_check_enable;
    end

  always_ff @(posedge clock) begin
    s3_fast_rep_REG   <= s2_fast_rep;
    s3_nc_with_data   <= s2_nc_with_data;
    s3_mmio_req_valid <= s2_mmio_req_valid_REG_1;
    // MMIO 与主流水共用写回口：目的寄存器信息按"s2 有效则主流水，否则 MMIO"锁存
    s3_pdest <= s2_valid ? s2_out.uop.pdest : s2_mmio_req_bits.uop.pdest;
    if (s2_valid | s2_mmio_req_valid_REG_1) begin
      s3_rfWen <= s2_valid ? s2_out.uop.rfWen : s2_mmio_req_bits.uop.rfWen;
      s3_fpWen <= s2_valid ? s2_out.uop.fpWen : s2_mmio_req_bits.uop.fpWen;
    end
    if (s2_fire) begin
      s3_vec_alignedType      <= s2_out.alignedType;
      s3_vec_mBIndex          <= s2_out.mbIndex;
      s3_safe_wakeup          <= s2_safe_wakeup;
      s3_safe_writeback       <= s2_safe_writeback;
      s3_exception            <= s2_real_exception;
      s3_mis_align_r          <= s2_mis_align;
      s3_misalign_can_go      <= ~ptr_after(s2_out.uop.robIdx_flag, s2_out.uop.robIdx_value,
                                            robDeqIdx.flag, robDeqIdx.value);   // 已是 ROB 队头
      s3_merged_data_frm_pipe <= s2_merged_data;
    end
    s3_ldout_valid_REG <= ~s2_out.isvec & ~s2_out.isFrmMisAlignBuf;
    REG_3 <= s2_full_fwd;
    REG_4 <= s2_mem_amb | s2_fwd_fail;
  end

  // ---- 去向判定 ----
  logic s3_kill, s3_mis_align, s3_fast_rep_canceled, s3_can_enter_lsq_valid, toMisalignBufferValid;
  logic s3_vp_match_fail, s3_rep_frm_fetch, s3_ldld_rep_inst, s3_flushPipe, s3_frm_mis_flush;
  logic [NUM_CAUSE-1:0] s3_lrq_cause, s3_lrq_sel_rep_cause, s3_replayqueue_rep_cause, s3_mab_sel_rep_cause;
  logic s3_out_valid;
  uop_t s3_out_uop;
  logic [63:0] s3_picked_data_frm_pipe, s3_ld_data_frm_pipe;   // 主流水写回数据（见"写回数据"）
  logic [63:0] s3_picked_data_frm_mmio, s3_ld_data_frm_mmio;   // MMIO 写回数据

  // 取最低位的 1（PriorityEncoderOH）
  function automatic logic [NUM_CAUSE-1:0] lowest_one(input logic [NUM_CAUSE-1:0] v);
    return v & NUM_CAUSE'(~v + NUM_CAUSE'(1));
  endfunction

  always_comb begin
    s3_kill      = rob_need_flush(s3_in.uop.robIdx_flag, s3_in.uop.robIdx_value,
                                  redirect_valid, redirect.level, redirect.robIdx_flag, redirect.robIdx_value);
    s3_ready     = ~s3_valid_last_REG | s3_kill | ldout_ready;
    s3_mis_align = s3_mis_align_r & ~s3_exception;

    // 快速重发被取消：s0 这拍要收更高优先级的来源（super 重发 / 非对齐）或 DCache 不收
    s3_fast_rep_canceled   = replay_valid & replay.forward_tlDchannel | misalign_ldin_valid | ~dcache_req_ready;
    s3_can_enter_lsq_valid = s3_valid_last_REG & (~s3_fast_rep_REG | s3_fast_rep_canceled) & ~s3_in.feedbacked;
    toMisalignBufferValid  = s3_can_enter_lsq_valid & s3_mis_align & ~s3_in.isFrmMisAlignBuf;

    s3_vp_match_fail = s3_vp_match_fail_last_REG & s3_troublem_last_REG;
    s3_rep_frm_fetch = s3_vp_match_fail;
    // RAR 违例：LQ 说有更年轻的 load 已读到旧值 → 本条之后全部从取指重来
    s3_ldld_rep_inst = lsq_ldld_nuke_query_resp_valid & lsq_ldld_nuke_query_resp_bits_rep_frm_fetch
                     & s3_ldld_rep_inst_last_REG;
    s3_flushPipe     = s3_ldld_rep_inst;

    // 写 LQ 的 replay 原因：在 s3_in 的原因之外补上"非对齐缓冲不收"，只留优先级最高的一个
    s3_lrq_cause                    = s3_in.rep_info_cause;
    s3_lrq_cause[C_MF]              = toMisalignBufferValid & ~(misalign_enq_req_ready & s3_misalign_can_go);
    s3_lrq_sel_rep_cause            = lowest_one(s3_lrq_cause);
    s3_replayqueue_rep_cause        = (s3_rep_frm_fetch | s3_in.isFrmMisAlignBuf) ? '0 : s3_lrq_sel_rep_cause;
    s3_mab_sel_rep_cause            = lowest_one(s3_in.rep_info_cause);

    s3_out_valid = s3_valid_last_REG & s3_safe_writeback & ~toMisalignBufferValid;
    // 写回 uop：叠上 s3 才到的 TL 错误（ECC 延迟错误本配置关闭）
    s3_out_uop           = s3_in.uop;
    s3_out_uop.exceptionVec[EXC_LD_ACCESS] = (s3_in.uop.exceptionVec[EXC_LD_ACCESS]
                                              | dcache_resp.tl_error_delayed_tl_denied)
                                           & s3_vecActive & ~s3_in.isPrefetch;
    s3_out_uop.exceptionVec[EXC_HW_ERROR]  = (s3_in.uop.exceptionVec[EXC_HW_ERROR]
                                              | dcache_resp.tl_error_delayed_tl_corrupt
                                                & ~dcache_resp.tl_error_delayed_tl_denied)
                                           & s3_vecActive & ~s3_in.isPrefetch;
    s3_out_uop.flushPipe  = 1'b0;
    s3_out_uop.replayInst = 1'b0;
  end

  // ---- 写 LQ / 非对齐缓冲 / 快速重发 ----
  always_comb begin
    lsq_ldin_valid = s3_can_enter_lsq_valid;
    lsq_ldin       = s3_in;
    lsq_ldin.uop   = s3_out_uop;
    lsq_ldin.nc_with_data    = s3_nc_with_data;
    lsq_ldin.updateAddrValid = ~s3_mis_align & (~s3_in.isFrmMisAlignBuf | s3_in.isFinalSplit) | s3_exception;
    lsq_ldin.rep_info_cause  = s3_replayqueue_rep_cause;

    misalign_enq_req_valid = toMisalignBufferValid & s3_misalign_can_go;
    misalign_enq           = s3_in;

    fast_rep_out_valid        = s3_valid_last_REG & s3_fast_rep_REG;
    fast_rep_out              = s3_in;
    fast_rep_out.lateKill     = s3_rep_frm_fetch;
    fast_rep_out.delayedLoadError = 1'b0;

    // 非对齐缓冲：子访问的结果，或（优先）三拍前收到的唤醒请求原样送回
    misalign_ldout_valid = s3_valid_last_REG & (~s3_fast_rep_REG | s3_fast_rep_canceled) & s3_in.isFrmMisAlignBuf
                         | s3_misalign_wakeup_req_valid_REG_2;
    misalign_ldout       = s3_misalign_wakeup_req_valid_REG_2 ? s3_misalign_wakeup_req_bits : lsq_ldin;
    misalign_ldout.rep_info_cause = s3_misalign_wakeup_req_valid_REG_2 ? '0 : s3_mab_sel_rep_cause;
    misalign_ldout.data           = 129'(s3_picked_data_frm_pipe);   // 第 3 份数据复制（见下方数据通路）
  end

  // ---- 回滚 / 违例队列撤销 / 发射队列反馈 ----
  always_comb begin
    logic fb_no_waiting;
    // 非对齐子访问被 store 撞或队列满：整条非对齐指令从取指重来
    s3_frm_mis_flush = s3_in.isFrmMisAlignBuf
                     & (misalign_ldout.rep_info_cause[C_FF] | misalign_ldout.rep_info_cause[C_MA]
                        | misalign_ldout.rep_info_cause[C_NK] | misalign_ldout.rep_info_cause[C_RAR]
                        | misalign_ldout.rep_info_cause[C_RAW]);

    rollback_valid = s3_valid_last_REG & (s3_rep_frm_fetch | s3_flushPipe | s3_frm_mis_flush) & ~s3_exception;
    rollback                              = '0;
    rollback.isRVC                        = s3_out_uop.preDecodeInfo_isRVC;
    rollback.robIdx_flag                  = s3_out_uop.robIdx_flag;
    rollback.robIdx_value                 = s3_out_uop.robIdx_value;
    rollback.ftqIdx_flag                  = s3_out_uop.ftqPtr_flag;
    rollback.ftqIdx_value                 = s3_out_uop.ftqPtr_value;
    rollback.ftqOffset                    = s3_out_uop.ftqOffset;
    // flush = 连本条一起冲（本条也要重做）；flushAfter = 本条之后（RAR：本条已拿到正确值）
    rollback.level                        = s3_rep_frm_fetch | s3_frm_mis_flush;
    rollback.debug_runahead_checkpoint_id = s3_out_uop.debugInfo_runahead_checkpoint_id;

    // 这条 load 不会正常完成 → 让 RAR/RAW 队列撤销 s2 的登记
    lsq_ldld_nuke_query_revoke = s3_exception | (|lsq_ldin.rep_info_cause) | s3_mis_align
                               | s3_in.isFrmMisAlignBuf & (|misalign_ldout.rep_info_cause);
    lsq_stld_nuke_query_revoke = lsq_ldld_nuke_query_revoke;

    // 发射队列只等"首发的标量 load 的最终结果"：LQ 重发 / 快速重发中的 / 向量 / 非对齐子访问不反馈
    fb_no_waiting = ~s3_in.isLoadReplay & ~(s3_fast_rep_REG & ~s3_fast_rep_canceled) & ~s3_in.feedbacked;
    feedback_slow_valid        = s3_valid_last_REG & fb_no_waiting & ~s3_isvec & ~s3_in.isFrmMisAlignBuf;
    feedback_slow              = '0;
    feedback_slow.robIdx_flag  = s3_in.uop.robIdx_flag;
    feedback_slow.robIdx_value = s3_in.uop.robIdx_value;
    feedback_slow.flushState   = s3_in.ptwBack;
    feedback_slow.sqIdx_flag   = s3_in.uop.sqIdx_flag;
    feedback_slow.sqIdx_value  = s3_in.uop.sqIdx_value;
    feedback_slow.lqIdx_flag   = s3_in.uop.lqIdx_flag;
    feedback_slow.lqIdx_value  = s3_in.uop.lqIdx_value;

    // s0 推测唤醒过的消费者：这条 load 结果没按时出来就取消
    ldCancel_ld2Cancel = s3_valid_last_REG & ~s3_safe_wakeup & ~s3_isvec;
  end

  // ---- 写回数据 ----
  // 主流水：16 字节合并数据按起始字节偏移选出 64 位（Mux1H：按位与-或），再按指令截取扩展
  always_comb begin
    s3_picked_data_frm_pipe = '0;
    for (int k = 0; k < 16; k++)
      if (s3_data_sel_offset[k]) s3_picked_data_frm_pipe |= 64'(s3_merged_data_frm_pipe >> (8 * k));
    s3_ld_data_frm_pipe = new_rdata(s3_data_select, s3_picked_data_frm_pipe);

    // MMIO：LQ 送来的 64 位已合并数据按 addrOffset 右移，再按 fuOpType 截取扩展
    s3_picked_data_frm_mmio = s3_ld_raw_data_frm_mmio.lqData >> {s3_ld_raw_data_frm_mmio.addrOffset, 3'b000};
    s3_ld_data_frm_mmio     = rdata_by_op(s3_ld_raw_data_frm_mmio.uop.fuOpType,
                                          s3_ld_raw_data_frm_mmio.uop.fpWen, s3_picked_data_frm_mmio);
  end

  // ---- 标量写回 ldout：主流水优先，否则 MMIO ----
  always_comb begin
    exu_out_t wb_meta;
    wb_meta              = '0;
    if (s3_valid_last_REG) begin
      wb_meta.uop          = s3_out_uop;
      wb_meta.data         = s3_in.data[63:0];
      wb_meta.debug_isMMIO = s3_in.mmio;
      wb_meta.debug_isNCIO = s3_in.nc & ~s3_in.memBackTypeMM;
      wb_meta.debug_isPerfCnt = 1'b0;
      wb_meta.debug_paddr  = s3_in.paddr;
      wb_meta.debug_vaddr  = s3_in.vaddr;
    end else begin
      wb_meta = s3_mmio_req_bits;
    end

    ldout_valid = s3_mmio_req_valid | s3_out_valid & s3_ldout_valid_REG;
    ldout       = wb_meta;
    ldout.data  = s3_valid_last_REG ? s3_ld_data_frm_pipe : s3_ld_data_frm_mmio;
    ldout.uop.exceptionVec = wb_meta.uop.exceptionVec & LDU_EXC_MASK;
    ldout.uop.rfWen = s3_rfWen & ~|(wb_meta.uop.exceptionVec & LDU_EXC_MASK);   // 有异常不写寄存器
    ldout.uop.fpWen = s3_fpWen;
    ldout.uop.pdest = s3_pdest;
  end

  // ---- 向量写回 vecldout（到合并缓冲）----
  always_comb begin
    logic [127:0] elem_data;
    case (s3_vec_alignedType[1:0])
      2'd0:    elem_data = {120'h0, s3_picked_data_frm_pipe[7:0]};
      2'd1:    elem_data = {112'h0, s3_picked_data_frm_pipe[15:0]};
      2'd2:    elem_data = {96'h0,  s3_picked_data_frm_pipe[31:0]};
      default: elem_data = {64'h0,  s3_picked_data_frm_pipe};
    endcase

    vecldout_valid = s3_out_valid
                   & ~rob_need_flush(s3_out_uop.robIdx_flag, s3_out_uop.robIdx_value,
                                     redirect_valid, redirect.level, redirect.robIdx_flag, redirect.robIdx_value)
                   & s3_isvec & ~s3_mis_align & ~s3_in.isFrmMisAlignBuf;
    vecldout                    = '0;
    vecldout.alignedType        = s3_vec_alignedType;
    vecldout.vecdata            = s3_in.misalignWith16Byte ? {64'h0, s3_picked_data_frm_pipe}
                                : s3_in.is128bit           ? s3_merged_data_frm_pipe
                                :                            elem_data;
    vecldout.elemIdx            = s3_in.elemIdx;
    vecldout.elemIdxInsideVd    = s3_in.elemIdxInsideVd;
    vecldout.mask               = s3_in.mask;
    vecldout.hasException       = s3_exception;
    vecldout.reg_offset         = s3_in.reg_offset;
    vecldout.mBIndex            = s3_vec_mBIndex;
    vecldout.trigger            = s3_in.uop.trigger;
    vecldout.exceptionVec       = s3_out_uop.exceptionVec & LDU_EXC_MASK;
    vecldout.vaddr              = s3_in.fullva;
    vecldout.vaNeedExt          = s3_in.vaNeedExt;
    vecldout.gpaddr             = s3_in.gpaddr;
    vecldout.isForVSnonLeafPTE  = s3_in.isForVSnonLeafPTE;
    vecldout.vstart             = s3_in.uop.vpu_vstart;
    vecldout.vecTriggerMask     = s3_in.vecTriggerMask;
  end

  // ---- topdown ----
  always_comb begin
    lsTopdownInfo                = '0;
    lsTopdownInfo.s1_robIdx      = s1_in.uop.robIdx_value;
    lsTopdownInfo.s1_vaddr_valid = s1_valid & s1_in.hasROBEntry;
    lsTopdownInfo.s1_vaddr_bits  = s1_in.vaddr;
    lsTopdownInfo.s2_robIdx      = s2_in.uop.robIdx_value;
    lsTopdownInfo.s2_paddr_valid = s2_fire & s2_in.hasROBEntry & ~s2_in.tlbMiss;
    lsTopdownInfo.s2_paddr_bits  = s2_in.paddr;
  end

  // ===================================================================
  // 性能事件：9 个事件各打两拍输出（generatePerfEvent），只有最低位有意义
  // ===================================================================
  logic io_perf_0_value_REG, io_perf_0_value_REG_1, io_perf_1_value_REG, io_perf_1_value_REG_1,
        io_perf_2_value_REG, io_perf_2_value_REG_1, io_perf_3_value_REG, io_perf_3_value_REG_1,
        io_perf_4_value_REG, io_perf_4_value_REG_1, io_perf_5_value_REG, io_perf_5_value_REG_1,
        io_perf_6_value_REG, io_perf_6_value_REG_1, io_perf_7_value_REG, io_perf_7_value_REG_1,
        io_perf_8_value_REG, io_perf_8_value_REG_1;
  always_ff @(posedge clock) begin
    io_perf_0_value_REG <= s0_fire;                                        // load_s0_in_fire
    io_perf_1_value_REG <= s1_fire & s1_try_ptr_chasing_last_REG;          // load_to_load_forward
    io_perf_2_value_REG <= s0_fire & ~dcache_req_ready;                    // stall_dcache
    io_perf_3_value_REG <= s0_fire;                                        // load_s1_in_fire
    io_perf_4_value_REG <= s1_fire & tlb_resp.miss;                        // load_s1_tlb_miss
    io_perf_5_value_REG <= s1_fire;                                        // load_s2_in_fire
    io_perf_6_value_REG <= s2_fire & dcache_resp.miss;                     // load_s2_dcache_miss
    io_perf_7_value_REG <= s2_fire & s2_hw_prf;                            // l1D_load_hw_prf_access
    io_perf_8_value_REG <= s2_fire & s2_hw_prf & dcache_resp.miss;         // l1D_load_hw_prf_miss
    io_perf_0_value_REG_1 <= io_perf_0_value_REG;
    io_perf_1_value_REG_1 <= io_perf_1_value_REG;
    io_perf_2_value_REG_1 <= io_perf_2_value_REG;
    io_perf_3_value_REG_1 <= io_perf_3_value_REG;
    io_perf_4_value_REG_1 <= io_perf_4_value_REG;
    io_perf_5_value_REG_1 <= io_perf_5_value_REG;
    io_perf_6_value_REG_1 <= io_perf_6_value_REG;
    io_perf_7_value_REG_1 <= io_perf_7_value_REG;
    io_perf_8_value_REG_1 <= io_perf_8_value_REG;
  end
  assign perf_0_value = 6'(io_perf_0_value_REG_1);
  assign perf_1_value = 6'(io_perf_1_value_REG_1);
  assign perf_2_value = 6'(io_perf_2_value_REG_1);
  assign perf_3_value = 6'(io_perf_3_value_REG_1);
  assign perf_4_value = 6'(io_perf_4_value_REG_1);
  assign perf_5_value = 6'(io_perf_5_value_REG_1);
  assign perf_6_value = 6'(io_perf_6_value_REG_1);
  assign perf_7_value = 6'(io_perf_7_value_REG_1);
  assign perf_8_value = 6'(io_perf_8_value_REG_1);

  // ===================================================================
  // 整包打拍寄存器（golden 留下哪些字段由生成器从 golden 寄存器表读出；次态见各级 sX_out）
  // ===================================================================
  // BEGIN GENERATED(pipe_regs) —— verif/ut/LoadUnit/gen_loadunit.py 生成，勿手改
  // ---- s1_in  <= s0_out（s0_fire 时整包打拍，无复位）：golden 留下的 203 个字段 ----
  logic [31:0] s1_in_r_uop_instr;
  logic [49:0] s1_in_r_uop_pc;
  logic [9:0] s1_in_r_uop_foldpc;
  logic s1_in_r_uop_exceptionVec_0;
  logic s1_in_r_uop_exceptionVec_1;
  logic s1_in_r_uop_exceptionVec_2;
  logic s1_in_r_uop_exceptionVec_4;
  logic s1_in_r_uop_exceptionVec_6;
  logic s1_in_r_uop_exceptionVec_7;
  logic s1_in_r_uop_exceptionVec_8;
  logic s1_in_r_uop_exceptionVec_9;
  logic s1_in_r_uop_exceptionVec_10;
  logic s1_in_r_uop_exceptionVec_11;
  logic s1_in_r_uop_exceptionVec_12;
  logic s1_in_r_uop_exceptionVec_14;
  logic s1_in_r_uop_exceptionVec_15;
  logic s1_in_r_uop_exceptionVec_16;
  logic s1_in_r_uop_exceptionVec_17;
  logic s1_in_r_uop_exceptionVec_18;
  logic s1_in_r_uop_exceptionVec_19;
  logic s1_in_r_uop_exceptionVec_20;
  logic s1_in_r_uop_exceptionVec_22;
  logic s1_in_r_uop_exceptionVec_23;
  logic s1_in_r_uop_isFetchMalAddr;
  logic s1_in_r_uop_hasException;
  logic s1_in_r_uop_preDecodeInfo_valid;
  logic s1_in_r_uop_preDecodeInfo_isRVC;
  logic [1:0] s1_in_r_uop_preDecodeInfo_brType;
  logic s1_in_r_uop_preDecodeInfo_isCall;
  logic s1_in_r_uop_preDecodeInfo_isRet;
  logic s1_in_r_uop_pred_taken;
  logic s1_in_r_uop_crossPageIPFFix;
  logic s1_in_r_uop_ftqPtr_flag;
  logic [5:0] s1_in_r_uop_ftqPtr_value;
  logic [3:0] s1_in_r_uop_ftqOffset;
  logic s1_in_r_uop_satpFlushFirstFetchFault;
  logic [3:0] s1_in_r_uop_srcType_0;
  logic [3:0] s1_in_r_uop_srcType_1;
  logic [3:0] s1_in_r_uop_srcType_2;
  logic [3:0] s1_in_r_uop_srcType_3;
  logic [3:0] s1_in_r_uop_srcType_4;
  logic [5:0] s1_in_r_uop_ldest;
  logic [34:0] s1_in_r_uop_fuType;
  logic [8:0] s1_in_r_uop_fuOpType;
  logic s1_in_r_uop_rfWen;
  logic s1_in_r_uop_fpWen;
  logic s1_in_r_uop_vecWen;
  logic s1_in_r_uop_v0Wen;
  logic s1_in_r_uop_vlWen;
  logic s1_in_r_uop_isXSTrap;
  logic s1_in_r_uop_waitForward;
  logic s1_in_r_uop_blockBackward;
  logic s1_in_r_uop_canRobCompress;
  logic [3:0] s1_in_r_uop_selImm;
  logic [31:0] s1_in_r_uop_imm;
  logic [1:0] s1_in_r_uop_fpu_typeTagOut;
  logic s1_in_r_uop_fpu_wflags;
  logic [1:0] s1_in_r_uop_fpu_typ;
  logic [1:0] s1_in_r_uop_fpu_fmt;
  logic [2:0] s1_in_r_uop_fpu_rm;
  logic s1_in_r_uop_vpu_vill;
  logic s1_in_r_uop_vpu_vma;
  logic s1_in_r_uop_vpu_vta;
  logic [1:0] s1_in_r_uop_vpu_vsew;
  logic [2:0] s1_in_r_uop_vpu_vlmul;
  logic s1_in_r_uop_vpu_specVill;
  logic s1_in_r_uop_vpu_specVma;
  logic s1_in_r_uop_vpu_specVta;
  logic [1:0] s1_in_r_uop_vpu_specVsew;
  logic [2:0] s1_in_r_uop_vpu_specVlmul;
  logic s1_in_r_uop_vpu_vm;
  logic [7:0] s1_in_r_uop_vpu_vstart;
  logic [2:0] s1_in_r_uop_vpu_frm;
  logic s1_in_r_uop_vpu_fpu_isFpToVecInst;
  logic s1_in_r_uop_vpu_fpu_isFP32Instr;
  logic s1_in_r_uop_vpu_fpu_isFP64Instr;
  logic s1_in_r_uop_vpu_fpu_isReduction;
  logic s1_in_r_uop_vpu_fpu_isFoldTo1_2;
  logic s1_in_r_uop_vpu_fpu_isFoldTo1_4;
  logic s1_in_r_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0] s1_in_r_uop_vpu_vxrm;
  logic [6:0] s1_in_r_uop_vpu_vuopIdx;
  logic s1_in_r_uop_vpu_lastUop;
  logic [127:0] s1_in_r_uop_vpu_vmask;
  logic [7:0] s1_in_r_uop_vpu_vl;
  logic [2:0] s1_in_r_uop_vpu_nf;
  logic [1:0] s1_in_r_uop_vpu_veew;
  logic s1_in_r_uop_vpu_isReverse;
  logic s1_in_r_uop_vpu_isExt;
  logic s1_in_r_uop_vpu_isNarrow;
  logic s1_in_r_uop_vpu_isDstMask;
  logic s1_in_r_uop_vpu_isOpMask;
  logic s1_in_r_uop_vpu_isMove;
  logic s1_in_r_uop_vpu_isDependOldVd;
  logic s1_in_r_uop_vpu_isWritePartVd;
  logic s1_in_r_uop_vpu_isVleff;
  logic s1_in_r_uop_vlsInstr;
  logic s1_in_r_uop_wfflags;
  logic s1_in_r_uop_isMove;
  logic s1_in_r_uop_isDropAmocasSta;
  logic [6:0] s1_in_r_uop_uopIdx;
  logic s1_in_r_uop_isVset;
  logic s1_in_r_uop_firstUop;
  logic s1_in_r_uop_lastUop;
  logic [6:0] s1_in_r_uop_numUops;
  logic [6:0] s1_in_r_uop_numWB;
  logic [2:0] s1_in_r_uop_commitType;
  logic s1_in_r_uop_srcState_0;
  logic s1_in_r_uop_srcState_1;
  logic s1_in_r_uop_srcState_2;
  logic s1_in_r_uop_srcState_3;
  logic s1_in_r_uop_srcState_4;
  logic [1:0] s1_in_r_uop_srcLoadDependency_0_0;
  logic [1:0] s1_in_r_uop_srcLoadDependency_0_1;
  logic [1:0] s1_in_r_uop_srcLoadDependency_0_2;
  logic [1:0] s1_in_r_uop_srcLoadDependency_1_0;
  logic [1:0] s1_in_r_uop_srcLoadDependency_1_1;
  logic [1:0] s1_in_r_uop_srcLoadDependency_1_2;
  logic [1:0] s1_in_r_uop_srcLoadDependency_2_0;
  logic [1:0] s1_in_r_uop_srcLoadDependency_2_1;
  logic [1:0] s1_in_r_uop_srcLoadDependency_2_2;
  logic [1:0] s1_in_r_uop_srcLoadDependency_3_0;
  logic [1:0] s1_in_r_uop_srcLoadDependency_3_1;
  logic [1:0] s1_in_r_uop_srcLoadDependency_3_2;
  logic [1:0] s1_in_r_uop_srcLoadDependency_4_0;
  logic [1:0] s1_in_r_uop_srcLoadDependency_4_1;
  logic [1:0] s1_in_r_uop_srcLoadDependency_4_2;
  logic [7:0] s1_in_r_uop_psrc_0;
  logic [7:0] s1_in_r_uop_psrc_1;
  logic [7:0] s1_in_r_uop_psrc_2;
  logic [7:0] s1_in_r_uop_psrc_3;
  logic [7:0] s1_in_r_uop_psrc_4;
  logic [7:0] s1_in_r_uop_pdest;
  logic s1_in_r_uop_useRegCache_0;
  logic s1_in_r_uop_useRegCache_1;
  logic [4:0] s1_in_r_uop_regCacheIdx_0;
  logic [4:0] s1_in_r_uop_regCacheIdx_1;
  logic s1_in_r_uop_robIdx_flag;
  logic [7:0] s1_in_r_uop_robIdx_value;
  logic [2:0] s1_in_r_uop_instrSize;
  logic s1_in_r_uop_dirtyFs;
  logic s1_in_r_uop_dirtyVs;
  logic [3:0] s1_in_r_uop_traceBlockInPipe_itype;
  logic [3:0] s1_in_r_uop_traceBlockInPipe_iretire;
  logic s1_in_r_uop_traceBlockInPipe_ilastsize;
  logic s1_in_r_uop_eliminatedMove;
  logic s1_in_r_uop_snapshot;
  logic s1_in_r_uop_debugInfo_eliminatedMove;
  logic [63:0] s1_in_r_uop_debugInfo_renameTime;
  logic [63:0] s1_in_r_uop_debugInfo_dispatchTime;
  logic [63:0] s1_in_r_uop_debugInfo_enqRsTime;
  logic [63:0] s1_in_r_uop_debugInfo_selectTime;
  logic [63:0] s1_in_r_uop_debugInfo_issueTime;
  logic [63:0] s1_in_r_uop_debugInfo_writebackTime;
  logic [63:0] s1_in_r_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0] s1_in_r_uop_debugInfo_tlbFirstReqTime;
  logic [63:0] s1_in_r_uop_debugInfo_tlbRespTime;
  logic [55:0] s1_in_r_uop_debug_seqNum_seqNum;
  logic [7:0] s1_in_r_uop_debug_seqNum_uopIdx;
  logic s1_in_r_uop_storeSetHit;
  logic s1_in_r_uop_waitForRobIdx_flag;
  logic [7:0] s1_in_r_uop_waitForRobIdx_value;
  logic s1_in_r_uop_loadWaitBit;
  logic s1_in_r_uop_loadWaitStrict;
  logic [4:0] s1_in_r_uop_ssid;
  logic s1_in_r_uop_lqIdx_flag;
  logic [6:0] s1_in_r_uop_lqIdx_value;
  logic s1_in_r_uop_sqIdx_flag;
  logic [5:0] s1_in_r_uop_sqIdx_value;
  logic s1_in_r_uop_singleStep;
  logic s1_in_r_uop_replayInst;
  logic [34:0] s1_in_r_uop_debug_fuType;
  logic s1_in_r_uop_debug_sim_trig;
  logic [4:0] s1_in_r_uop_numLsElem;
  logic [49:0] s1_in_r_vaddr;
  logic [47:0] s1_in_r_paddr;
  logic [15:0] s1_in_r_mask;
  logic [128:0] s1_in_r_data;
  logic s1_in_r_nc;
  logic s1_in_r_isPrefetch;
  logic s1_in_r_isHWPrefetch;
  logic s1_in_r_isvec;
  logic s1_in_r_is128bit;
  logic [7:0] s1_in_r_elemIdx;
  logic [2:0] s1_in_r_alignedType;
  logic [3:0] s1_in_r_mbIndex;
  logic [3:0] s1_in_r_reg_offset;
  logic [7:0] s1_in_r_elemIdxInsideVd;
  logic [49:0] s1_in_r_vecBaseVaddr;
  logic s1_in_r_vecActive;
  logic s1_in_r_isLoadReplay;
  logic s1_in_r_isFastReplay;
  logic s1_in_r_isFirstIssue;
  logic s1_in_r_hasROBEntry;
  logic [3:0] s1_in_r_mshrid;
  logic s1_in_r_forward_tlDchannel;
  logic [6:0] s1_in_r_schedIndex;
  logic s1_in_r_tlbNoQuery;
  logic s1_in_r_isFrmMisAlignBuf;
  logic s1_in_r_isMisalign;
  logic s1_in_r_isFinalSplit;
  logic s1_in_r_misalignWith16Byte;
  logic s1_in_r_misalignNeedWakeUp;
  always_ff @(posedge clock) begin
    if (s0_fire) begin
      s1_in_r_uop_instr <= s0_out.uop.instr;
      s1_in_r_uop_pc <= s0_out.uop.pc;
      s1_in_r_uop_foldpc <= s0_out.uop.foldpc;
      s1_in_r_uop_exceptionVec_0 <= s0_out.uop.exceptionVec[0];
      s1_in_r_uop_exceptionVec_1 <= s0_out.uop.exceptionVec[1];
      s1_in_r_uop_exceptionVec_2 <= s0_out.uop.exceptionVec[2];
      s1_in_r_uop_exceptionVec_4 <= s0_out.uop.exceptionVec[4];
      s1_in_r_uop_exceptionVec_6 <= s0_out.uop.exceptionVec[6];
      s1_in_r_uop_exceptionVec_7 <= s0_out.uop.exceptionVec[7];
      s1_in_r_uop_exceptionVec_8 <= s0_out.uop.exceptionVec[8];
      s1_in_r_uop_exceptionVec_9 <= s0_out.uop.exceptionVec[9];
      s1_in_r_uop_exceptionVec_10 <= s0_out.uop.exceptionVec[10];
      s1_in_r_uop_exceptionVec_11 <= s0_out.uop.exceptionVec[11];
      s1_in_r_uop_exceptionVec_12 <= s0_out.uop.exceptionVec[12];
      s1_in_r_uop_exceptionVec_14 <= s0_out.uop.exceptionVec[14];
      s1_in_r_uop_exceptionVec_15 <= s0_out.uop.exceptionVec[15];
      s1_in_r_uop_exceptionVec_16 <= s0_out.uop.exceptionVec[16];
      s1_in_r_uop_exceptionVec_17 <= s0_out.uop.exceptionVec[17];
      s1_in_r_uop_exceptionVec_18 <= s0_out.uop.exceptionVec[18];
      s1_in_r_uop_exceptionVec_19 <= s0_out.uop.exceptionVec[19];
      s1_in_r_uop_exceptionVec_20 <= s0_out.uop.exceptionVec[20];
      s1_in_r_uop_exceptionVec_22 <= s0_out.uop.exceptionVec[22];
      s1_in_r_uop_exceptionVec_23 <= s0_out.uop.exceptionVec[23];
      s1_in_r_uop_isFetchMalAddr <= s0_out.uop.isFetchMalAddr;
      s1_in_r_uop_hasException <= s0_out.uop.hasException;
      s1_in_r_uop_preDecodeInfo_valid <= s0_out.uop.preDecodeInfo_valid;
      s1_in_r_uop_preDecodeInfo_isRVC <= s0_out.uop.preDecodeInfo_isRVC;
      s1_in_r_uop_preDecodeInfo_brType <= s0_out.uop.preDecodeInfo_brType;
      s1_in_r_uop_preDecodeInfo_isCall <= s0_out.uop.preDecodeInfo_isCall;
      s1_in_r_uop_preDecodeInfo_isRet <= s0_out.uop.preDecodeInfo_isRet;
      s1_in_r_uop_pred_taken <= s0_out.uop.pred_taken;
      s1_in_r_uop_crossPageIPFFix <= s0_out.uop.crossPageIPFFix;
      s1_in_r_uop_ftqPtr_flag <= s0_out.uop.ftqPtr_flag;
      s1_in_r_uop_ftqPtr_value <= s0_out.uop.ftqPtr_value;
      s1_in_r_uop_ftqOffset <= s0_out.uop.ftqOffset;
      s1_in_r_uop_satpFlushFirstFetchFault <= s0_out.uop.satpFlushFirstFetchFault;
      s1_in_r_uop_srcType_0 <= s0_out.uop.srcType_0;
      s1_in_r_uop_srcType_1 <= s0_out.uop.srcType_1;
      s1_in_r_uop_srcType_2 <= s0_out.uop.srcType_2;
      s1_in_r_uop_srcType_3 <= s0_out.uop.srcType_3;
      s1_in_r_uop_srcType_4 <= s0_out.uop.srcType_4;
      s1_in_r_uop_ldest <= s0_out.uop.ldest;
      s1_in_r_uop_fuType <= s0_out.uop.fuType;
      s1_in_r_uop_fuOpType <= s0_out.uop.fuOpType;
      s1_in_r_uop_rfWen <= s0_out.uop.rfWen;
      s1_in_r_uop_fpWen <= s0_out.uop.fpWen;
      s1_in_r_uop_vecWen <= s0_out.uop.vecWen;
      s1_in_r_uop_v0Wen <= s0_out.uop.v0Wen;
      s1_in_r_uop_vlWen <= s0_out.uop.vlWen;
      s1_in_r_uop_isXSTrap <= s0_out.uop.isXSTrap;
      s1_in_r_uop_waitForward <= s0_out.uop.waitForward;
      s1_in_r_uop_blockBackward <= s0_out.uop.blockBackward;
      s1_in_r_uop_canRobCompress <= s0_out.uop.canRobCompress;
      s1_in_r_uop_selImm <= s0_out.uop.selImm;
      s1_in_r_uop_imm <= s0_out.uop.imm;
      s1_in_r_uop_fpu_typeTagOut <= s0_out.uop.fpu_typeTagOut;
      s1_in_r_uop_fpu_wflags <= s0_out.uop.fpu_wflags;
      s1_in_r_uop_fpu_typ <= s0_out.uop.fpu_typ;
      s1_in_r_uop_fpu_fmt <= s0_out.uop.fpu_fmt;
      s1_in_r_uop_fpu_rm <= s0_out.uop.fpu_rm;
      s1_in_r_uop_vpu_vill <= s0_out.uop.vpu_vill;
      s1_in_r_uop_vpu_vma <= s0_out.uop.vpu_vma;
      s1_in_r_uop_vpu_vta <= s0_out.uop.vpu_vta;
      s1_in_r_uop_vpu_vsew <= s0_out.uop.vpu_vsew;
      s1_in_r_uop_vpu_vlmul <= s0_out.uop.vpu_vlmul;
      s1_in_r_uop_vpu_specVill <= s0_out.uop.vpu_specVill;
      s1_in_r_uop_vpu_specVma <= s0_out.uop.vpu_specVma;
      s1_in_r_uop_vpu_specVta <= s0_out.uop.vpu_specVta;
      s1_in_r_uop_vpu_specVsew <= s0_out.uop.vpu_specVsew;
      s1_in_r_uop_vpu_specVlmul <= s0_out.uop.vpu_specVlmul;
      s1_in_r_uop_vpu_vm <= s0_out.uop.vpu_vm;
      s1_in_r_uop_vpu_vstart <= s0_out.uop.vpu_vstart;
      s1_in_r_uop_vpu_frm <= s0_out.uop.vpu_frm;
      s1_in_r_uop_vpu_fpu_isFpToVecInst <= s0_out.uop.vpu_fpu_isFpToVecInst;
      s1_in_r_uop_vpu_fpu_isFP32Instr <= s0_out.uop.vpu_fpu_isFP32Instr;
      s1_in_r_uop_vpu_fpu_isFP64Instr <= s0_out.uop.vpu_fpu_isFP64Instr;
      s1_in_r_uop_vpu_fpu_isReduction <= s0_out.uop.vpu_fpu_isReduction;
      s1_in_r_uop_vpu_fpu_isFoldTo1_2 <= s0_out.uop.vpu_fpu_isFoldTo1_2;
      s1_in_r_uop_vpu_fpu_isFoldTo1_4 <= s0_out.uop.vpu_fpu_isFoldTo1_4;
      s1_in_r_uop_vpu_fpu_isFoldTo1_8 <= s0_out.uop.vpu_fpu_isFoldTo1_8;
      s1_in_r_uop_vpu_vxrm <= s0_out.uop.vpu_vxrm;
      s1_in_r_uop_vpu_vuopIdx <= s0_out.uop.vpu_vuopIdx;
      s1_in_r_uop_vpu_lastUop <= s0_out.uop.vpu_lastUop;
      s1_in_r_uop_vpu_vmask <= s0_out.uop.vpu_vmask;
      s1_in_r_uop_vpu_vl <= s0_out.uop.vpu_vl;
      s1_in_r_uop_vpu_nf <= s0_out.uop.vpu_nf;
      s1_in_r_uop_vpu_veew <= s0_out.uop.vpu_veew;
      s1_in_r_uop_vpu_isReverse <= s0_out.uop.vpu_isReverse;
      s1_in_r_uop_vpu_isExt <= s0_out.uop.vpu_isExt;
      s1_in_r_uop_vpu_isNarrow <= s0_out.uop.vpu_isNarrow;
      s1_in_r_uop_vpu_isDstMask <= s0_out.uop.vpu_isDstMask;
      s1_in_r_uop_vpu_isOpMask <= s0_out.uop.vpu_isOpMask;
      s1_in_r_uop_vpu_isMove <= s0_out.uop.vpu_isMove;
      s1_in_r_uop_vpu_isDependOldVd <= s0_out.uop.vpu_isDependOldVd;
      s1_in_r_uop_vpu_isWritePartVd <= s0_out.uop.vpu_isWritePartVd;
      s1_in_r_uop_vpu_isVleff <= s0_out.uop.vpu_isVleff;
      s1_in_r_uop_vlsInstr <= s0_out.uop.vlsInstr;
      s1_in_r_uop_wfflags <= s0_out.uop.wfflags;
      s1_in_r_uop_isMove <= s0_out.uop.isMove;
      s1_in_r_uop_isDropAmocasSta <= s0_out.uop.isDropAmocasSta;
      s1_in_r_uop_uopIdx <= s0_out.uop.uopIdx;
      s1_in_r_uop_isVset <= s0_out.uop.isVset;
      s1_in_r_uop_firstUop <= s0_out.uop.firstUop;
      s1_in_r_uop_lastUop <= s0_out.uop.lastUop;
      s1_in_r_uop_numUops <= s0_out.uop.numUops;
      s1_in_r_uop_numWB <= s0_out.uop.numWB;
      s1_in_r_uop_commitType <= s0_out.uop.commitType;
      s1_in_r_uop_srcState_0 <= s0_out.uop.srcState_0;
      s1_in_r_uop_srcState_1 <= s0_out.uop.srcState_1;
      s1_in_r_uop_srcState_2 <= s0_out.uop.srcState_2;
      s1_in_r_uop_srcState_3 <= s0_out.uop.srcState_3;
      s1_in_r_uop_srcState_4 <= s0_out.uop.srcState_4;
      s1_in_r_uop_srcLoadDependency_0_0 <= s0_out.uop.srcLoadDependency_0_0;
      s1_in_r_uop_srcLoadDependency_0_1 <= s0_out.uop.srcLoadDependency_0_1;
      s1_in_r_uop_srcLoadDependency_0_2 <= s0_out.uop.srcLoadDependency_0_2;
      s1_in_r_uop_srcLoadDependency_1_0 <= s0_out.uop.srcLoadDependency_1_0;
      s1_in_r_uop_srcLoadDependency_1_1 <= s0_out.uop.srcLoadDependency_1_1;
      s1_in_r_uop_srcLoadDependency_1_2 <= s0_out.uop.srcLoadDependency_1_2;
      s1_in_r_uop_srcLoadDependency_2_0 <= s0_out.uop.srcLoadDependency_2_0;
      s1_in_r_uop_srcLoadDependency_2_1 <= s0_out.uop.srcLoadDependency_2_1;
      s1_in_r_uop_srcLoadDependency_2_2 <= s0_out.uop.srcLoadDependency_2_2;
      s1_in_r_uop_srcLoadDependency_3_0 <= s0_out.uop.srcLoadDependency_3_0;
      s1_in_r_uop_srcLoadDependency_3_1 <= s0_out.uop.srcLoadDependency_3_1;
      s1_in_r_uop_srcLoadDependency_3_2 <= s0_out.uop.srcLoadDependency_3_2;
      s1_in_r_uop_srcLoadDependency_4_0 <= s0_out.uop.srcLoadDependency_4_0;
      s1_in_r_uop_srcLoadDependency_4_1 <= s0_out.uop.srcLoadDependency_4_1;
      s1_in_r_uop_srcLoadDependency_4_2 <= s0_out.uop.srcLoadDependency_4_2;
      s1_in_r_uop_psrc_0 <= s0_out.uop.psrc_0;
      s1_in_r_uop_psrc_1 <= s0_out.uop.psrc_1;
      s1_in_r_uop_psrc_2 <= s0_out.uop.psrc_2;
      s1_in_r_uop_psrc_3 <= s0_out.uop.psrc_3;
      s1_in_r_uop_psrc_4 <= s0_out.uop.psrc_4;
      s1_in_r_uop_pdest <= s0_out.uop.pdest;
      s1_in_r_uop_useRegCache_0 <= s0_out.uop.useRegCache_0;
      s1_in_r_uop_useRegCache_1 <= s0_out.uop.useRegCache_1;
      s1_in_r_uop_regCacheIdx_0 <= s0_out.uop.regCacheIdx_0;
      s1_in_r_uop_regCacheIdx_1 <= s0_out.uop.regCacheIdx_1;
      s1_in_r_uop_robIdx_flag <= s0_out.uop.robIdx_flag;
      s1_in_r_uop_robIdx_value <= s0_out.uop.robIdx_value;
      s1_in_r_uop_instrSize <= s0_out.uop.instrSize;
      s1_in_r_uop_dirtyFs <= s0_out.uop.dirtyFs;
      s1_in_r_uop_dirtyVs <= s0_out.uop.dirtyVs;
      s1_in_r_uop_traceBlockInPipe_itype <= s0_out.uop.traceBlockInPipe_itype;
      s1_in_r_uop_traceBlockInPipe_iretire <= s0_out.uop.traceBlockInPipe_iretire;
      s1_in_r_uop_traceBlockInPipe_ilastsize <= s0_out.uop.traceBlockInPipe_ilastsize;
      s1_in_r_uop_eliminatedMove <= s0_out.uop.eliminatedMove;
      s1_in_r_uop_snapshot <= s0_out.uop.snapshot;
      s1_in_r_uop_debugInfo_eliminatedMove <= s0_out.uop.debugInfo_eliminatedMove;
      s1_in_r_uop_debugInfo_renameTime <= s0_out.uop.debugInfo_renameTime;
      s1_in_r_uop_debugInfo_dispatchTime <= s0_out.uop.debugInfo_dispatchTime;
      s1_in_r_uop_debugInfo_enqRsTime <= s0_out.uop.debugInfo_enqRsTime;
      s1_in_r_uop_debugInfo_selectTime <= s0_out.uop.debugInfo_selectTime;
      s1_in_r_uop_debugInfo_issueTime <= s0_out.uop.debugInfo_issueTime;
      s1_in_r_uop_debugInfo_writebackTime <= s0_out.uop.debugInfo_writebackTime;
      s1_in_r_uop_debugInfo_runahead_checkpoint_id <= s0_out.uop.debugInfo_runahead_checkpoint_id;
      s1_in_r_uop_debugInfo_tlbFirstReqTime <= s0_out.uop.debugInfo_tlbFirstReqTime;
      s1_in_r_uop_debugInfo_tlbRespTime <= s0_out.uop.debugInfo_tlbRespTime;
      s1_in_r_uop_debug_seqNum_seqNum <= s0_out.uop.debug_seqNum_seqNum;
      s1_in_r_uop_debug_seqNum_uopIdx <= s0_out.uop.debug_seqNum_uopIdx;
      s1_in_r_uop_storeSetHit <= s0_out.uop.storeSetHit;
      s1_in_r_uop_waitForRobIdx_flag <= s0_out.uop.waitForRobIdx_flag;
      s1_in_r_uop_waitForRobIdx_value <= s0_out.uop.waitForRobIdx_value;
      s1_in_r_uop_loadWaitBit <= s0_out.uop.loadWaitBit;
      s1_in_r_uop_loadWaitStrict <= s0_out.uop.loadWaitStrict;
      s1_in_r_uop_ssid <= s0_out.uop.ssid;
      s1_in_r_uop_lqIdx_flag <= s0_out.uop.lqIdx_flag;
      s1_in_r_uop_lqIdx_value <= s0_out.uop.lqIdx_value;
      s1_in_r_uop_sqIdx_flag <= s0_out.uop.sqIdx_flag;
      s1_in_r_uop_sqIdx_value <= s0_out.uop.sqIdx_value;
      s1_in_r_uop_singleStep <= s0_out.uop.singleStep;
      s1_in_r_uop_replayInst <= s0_out.uop.replayInst;
      s1_in_r_uop_debug_fuType <= s0_out.uop.debug_fuType;
      s1_in_r_uop_debug_sim_trig <= s0_out.uop.debug_sim_trig;
      s1_in_r_uop_numLsElem <= s0_out.uop.numLsElem;
      s1_in_r_vaddr <= s0_out.vaddr;
      s1_in_r_paddr <= s0_out.paddr;
      s1_in_r_mask <= s0_out.mask;
      s1_in_r_data <= s0_out.data;
      s1_in_r_nc <= s0_out.nc;
      s1_in_r_isPrefetch <= s0_out.isPrefetch;
      s1_in_r_isHWPrefetch <= s0_out.isHWPrefetch;
      s1_in_r_isvec <= s0_out.isvec;
      s1_in_r_is128bit <= s0_out.is128bit;
      s1_in_r_elemIdx <= s0_out.elemIdx;
      s1_in_r_alignedType <= s0_out.alignedType;
      s1_in_r_mbIndex <= s0_out.mbIndex;
      s1_in_r_reg_offset <= s0_out.reg_offset;
      s1_in_r_elemIdxInsideVd <= s0_out.elemIdxInsideVd;
      s1_in_r_vecBaseVaddr <= s0_out.vecBaseVaddr;
      s1_in_r_vecActive <= s0_out.vecActive;
      s1_in_r_isLoadReplay <= s0_out.isLoadReplay;
      s1_in_r_isFastReplay <= s0_out.isFastReplay;
      s1_in_r_isFirstIssue <= s0_out.isFirstIssue;
      s1_in_r_hasROBEntry <= s0_out.hasROBEntry;
      s1_in_r_mshrid <= s0_out.mshrid;
      s1_in_r_forward_tlDchannel <= s0_out.forward_tlDchannel;
      s1_in_r_schedIndex <= s0_out.schedIndex;
      s1_in_r_tlbNoQuery <= s0_out.tlbNoQuery;
      s1_in_r_isFrmMisAlignBuf <= s0_out.isFrmMisAlignBuf;
      s1_in_r_isMisalign <= s0_out.isMisalign;
      s1_in_r_isFinalSplit <= s0_out.isFinalSplit;
      s1_in_r_misalignWith16Byte <= s0_out.misalignWith16Byte;
      s1_in_r_misalignNeedWakeUp <= s0_out.misalignNeedWakeUp;
    end
  end
  // 读回成 struct；golden 没留下的字段（DCE 掉 / 下游不用）恒 0
  always_comb begin
    s1_in = '0;
    s1_in.uop.instr = s1_in_r_uop_instr;
    s1_in.uop.pc = s1_in_r_uop_pc;
    s1_in.uop.foldpc = s1_in_r_uop_foldpc;
    s1_in.uop.exceptionVec[0] = s1_in_r_uop_exceptionVec_0;
    s1_in.uop.exceptionVec[1] = s1_in_r_uop_exceptionVec_1;
    s1_in.uop.exceptionVec[2] = s1_in_r_uop_exceptionVec_2;
    s1_in.uop.exceptionVec[4] = s1_in_r_uop_exceptionVec_4;
    s1_in.uop.exceptionVec[6] = s1_in_r_uop_exceptionVec_6;
    s1_in.uop.exceptionVec[7] = s1_in_r_uop_exceptionVec_7;
    s1_in.uop.exceptionVec[8] = s1_in_r_uop_exceptionVec_8;
    s1_in.uop.exceptionVec[9] = s1_in_r_uop_exceptionVec_9;
    s1_in.uop.exceptionVec[10] = s1_in_r_uop_exceptionVec_10;
    s1_in.uop.exceptionVec[11] = s1_in_r_uop_exceptionVec_11;
    s1_in.uop.exceptionVec[12] = s1_in_r_uop_exceptionVec_12;
    s1_in.uop.exceptionVec[14] = s1_in_r_uop_exceptionVec_14;
    s1_in.uop.exceptionVec[15] = s1_in_r_uop_exceptionVec_15;
    s1_in.uop.exceptionVec[16] = s1_in_r_uop_exceptionVec_16;
    s1_in.uop.exceptionVec[17] = s1_in_r_uop_exceptionVec_17;
    s1_in.uop.exceptionVec[18] = s1_in_r_uop_exceptionVec_18;
    s1_in.uop.exceptionVec[19] = s1_in_r_uop_exceptionVec_19;
    s1_in.uop.exceptionVec[20] = s1_in_r_uop_exceptionVec_20;
    s1_in.uop.exceptionVec[22] = s1_in_r_uop_exceptionVec_22;
    s1_in.uop.exceptionVec[23] = s1_in_r_uop_exceptionVec_23;
    s1_in.uop.isFetchMalAddr = s1_in_r_uop_isFetchMalAddr;
    s1_in.uop.hasException = s1_in_r_uop_hasException;
    s1_in.uop.preDecodeInfo_valid = s1_in_r_uop_preDecodeInfo_valid;
    s1_in.uop.preDecodeInfo_isRVC = s1_in_r_uop_preDecodeInfo_isRVC;
    s1_in.uop.preDecodeInfo_brType = s1_in_r_uop_preDecodeInfo_brType;
    s1_in.uop.preDecodeInfo_isCall = s1_in_r_uop_preDecodeInfo_isCall;
    s1_in.uop.preDecodeInfo_isRet = s1_in_r_uop_preDecodeInfo_isRet;
    s1_in.uop.pred_taken = s1_in_r_uop_pred_taken;
    s1_in.uop.crossPageIPFFix = s1_in_r_uop_crossPageIPFFix;
    s1_in.uop.ftqPtr_flag = s1_in_r_uop_ftqPtr_flag;
    s1_in.uop.ftqPtr_value = s1_in_r_uop_ftqPtr_value;
    s1_in.uop.ftqOffset = s1_in_r_uop_ftqOffset;
    s1_in.uop.satpFlushFirstFetchFault = s1_in_r_uop_satpFlushFirstFetchFault;
    s1_in.uop.srcType_0 = s1_in_r_uop_srcType_0;
    s1_in.uop.srcType_1 = s1_in_r_uop_srcType_1;
    s1_in.uop.srcType_2 = s1_in_r_uop_srcType_2;
    s1_in.uop.srcType_3 = s1_in_r_uop_srcType_3;
    s1_in.uop.srcType_4 = s1_in_r_uop_srcType_4;
    s1_in.uop.ldest = s1_in_r_uop_ldest;
    s1_in.uop.fuType = s1_in_r_uop_fuType;
    s1_in.uop.fuOpType = s1_in_r_uop_fuOpType;
    s1_in.uop.rfWen = s1_in_r_uop_rfWen;
    s1_in.uop.fpWen = s1_in_r_uop_fpWen;
    s1_in.uop.vecWen = s1_in_r_uop_vecWen;
    s1_in.uop.v0Wen = s1_in_r_uop_v0Wen;
    s1_in.uop.vlWen = s1_in_r_uop_vlWen;
    s1_in.uop.isXSTrap = s1_in_r_uop_isXSTrap;
    s1_in.uop.waitForward = s1_in_r_uop_waitForward;
    s1_in.uop.blockBackward = s1_in_r_uop_blockBackward;
    s1_in.uop.canRobCompress = s1_in_r_uop_canRobCompress;
    s1_in.uop.selImm = s1_in_r_uop_selImm;
    s1_in.uop.imm = s1_in_r_uop_imm;
    s1_in.uop.fpu_typeTagOut = s1_in_r_uop_fpu_typeTagOut;
    s1_in.uop.fpu_wflags = s1_in_r_uop_fpu_wflags;
    s1_in.uop.fpu_typ = s1_in_r_uop_fpu_typ;
    s1_in.uop.fpu_fmt = s1_in_r_uop_fpu_fmt;
    s1_in.uop.fpu_rm = s1_in_r_uop_fpu_rm;
    s1_in.uop.vpu_vill = s1_in_r_uop_vpu_vill;
    s1_in.uop.vpu_vma = s1_in_r_uop_vpu_vma;
    s1_in.uop.vpu_vta = s1_in_r_uop_vpu_vta;
    s1_in.uop.vpu_vsew = s1_in_r_uop_vpu_vsew;
    s1_in.uop.vpu_vlmul = s1_in_r_uop_vpu_vlmul;
    s1_in.uop.vpu_specVill = s1_in_r_uop_vpu_specVill;
    s1_in.uop.vpu_specVma = s1_in_r_uop_vpu_specVma;
    s1_in.uop.vpu_specVta = s1_in_r_uop_vpu_specVta;
    s1_in.uop.vpu_specVsew = s1_in_r_uop_vpu_specVsew;
    s1_in.uop.vpu_specVlmul = s1_in_r_uop_vpu_specVlmul;
    s1_in.uop.vpu_vm = s1_in_r_uop_vpu_vm;
    s1_in.uop.vpu_vstart = s1_in_r_uop_vpu_vstart;
    s1_in.uop.vpu_frm = s1_in_r_uop_vpu_frm;
    s1_in.uop.vpu_fpu_isFpToVecInst = s1_in_r_uop_vpu_fpu_isFpToVecInst;
    s1_in.uop.vpu_fpu_isFP32Instr = s1_in_r_uop_vpu_fpu_isFP32Instr;
    s1_in.uop.vpu_fpu_isFP64Instr = s1_in_r_uop_vpu_fpu_isFP64Instr;
    s1_in.uop.vpu_fpu_isReduction = s1_in_r_uop_vpu_fpu_isReduction;
    s1_in.uop.vpu_fpu_isFoldTo1_2 = s1_in_r_uop_vpu_fpu_isFoldTo1_2;
    s1_in.uop.vpu_fpu_isFoldTo1_4 = s1_in_r_uop_vpu_fpu_isFoldTo1_4;
    s1_in.uop.vpu_fpu_isFoldTo1_8 = s1_in_r_uop_vpu_fpu_isFoldTo1_8;
    s1_in.uop.vpu_vxrm = s1_in_r_uop_vpu_vxrm;
    s1_in.uop.vpu_vuopIdx = s1_in_r_uop_vpu_vuopIdx;
    s1_in.uop.vpu_lastUop = s1_in_r_uop_vpu_lastUop;
    s1_in.uop.vpu_vmask = s1_in_r_uop_vpu_vmask;
    s1_in.uop.vpu_vl = s1_in_r_uop_vpu_vl;
    s1_in.uop.vpu_nf = s1_in_r_uop_vpu_nf;
    s1_in.uop.vpu_veew = s1_in_r_uop_vpu_veew;
    s1_in.uop.vpu_isReverse = s1_in_r_uop_vpu_isReverse;
    s1_in.uop.vpu_isExt = s1_in_r_uop_vpu_isExt;
    s1_in.uop.vpu_isNarrow = s1_in_r_uop_vpu_isNarrow;
    s1_in.uop.vpu_isDstMask = s1_in_r_uop_vpu_isDstMask;
    s1_in.uop.vpu_isOpMask = s1_in_r_uop_vpu_isOpMask;
    s1_in.uop.vpu_isMove = s1_in_r_uop_vpu_isMove;
    s1_in.uop.vpu_isDependOldVd = s1_in_r_uop_vpu_isDependOldVd;
    s1_in.uop.vpu_isWritePartVd = s1_in_r_uop_vpu_isWritePartVd;
    s1_in.uop.vpu_isVleff = s1_in_r_uop_vpu_isVleff;
    s1_in.uop.vlsInstr = s1_in_r_uop_vlsInstr;
    s1_in.uop.wfflags = s1_in_r_uop_wfflags;
    s1_in.uop.isMove = s1_in_r_uop_isMove;
    s1_in.uop.isDropAmocasSta = s1_in_r_uop_isDropAmocasSta;
    s1_in.uop.uopIdx = s1_in_r_uop_uopIdx;
    s1_in.uop.isVset = s1_in_r_uop_isVset;
    s1_in.uop.firstUop = s1_in_r_uop_firstUop;
    s1_in.uop.lastUop = s1_in_r_uop_lastUop;
    s1_in.uop.numUops = s1_in_r_uop_numUops;
    s1_in.uop.numWB = s1_in_r_uop_numWB;
    s1_in.uop.commitType = s1_in_r_uop_commitType;
    s1_in.uop.srcState_0 = s1_in_r_uop_srcState_0;
    s1_in.uop.srcState_1 = s1_in_r_uop_srcState_1;
    s1_in.uop.srcState_2 = s1_in_r_uop_srcState_2;
    s1_in.uop.srcState_3 = s1_in_r_uop_srcState_3;
    s1_in.uop.srcState_4 = s1_in_r_uop_srcState_4;
    s1_in.uop.srcLoadDependency_0_0 = s1_in_r_uop_srcLoadDependency_0_0;
    s1_in.uop.srcLoadDependency_0_1 = s1_in_r_uop_srcLoadDependency_0_1;
    s1_in.uop.srcLoadDependency_0_2 = s1_in_r_uop_srcLoadDependency_0_2;
    s1_in.uop.srcLoadDependency_1_0 = s1_in_r_uop_srcLoadDependency_1_0;
    s1_in.uop.srcLoadDependency_1_1 = s1_in_r_uop_srcLoadDependency_1_1;
    s1_in.uop.srcLoadDependency_1_2 = s1_in_r_uop_srcLoadDependency_1_2;
    s1_in.uop.srcLoadDependency_2_0 = s1_in_r_uop_srcLoadDependency_2_0;
    s1_in.uop.srcLoadDependency_2_1 = s1_in_r_uop_srcLoadDependency_2_1;
    s1_in.uop.srcLoadDependency_2_2 = s1_in_r_uop_srcLoadDependency_2_2;
    s1_in.uop.srcLoadDependency_3_0 = s1_in_r_uop_srcLoadDependency_3_0;
    s1_in.uop.srcLoadDependency_3_1 = s1_in_r_uop_srcLoadDependency_3_1;
    s1_in.uop.srcLoadDependency_3_2 = s1_in_r_uop_srcLoadDependency_3_2;
    s1_in.uop.srcLoadDependency_4_0 = s1_in_r_uop_srcLoadDependency_4_0;
    s1_in.uop.srcLoadDependency_4_1 = s1_in_r_uop_srcLoadDependency_4_1;
    s1_in.uop.srcLoadDependency_4_2 = s1_in_r_uop_srcLoadDependency_4_2;
    s1_in.uop.psrc_0 = s1_in_r_uop_psrc_0;
    s1_in.uop.psrc_1 = s1_in_r_uop_psrc_1;
    s1_in.uop.psrc_2 = s1_in_r_uop_psrc_2;
    s1_in.uop.psrc_3 = s1_in_r_uop_psrc_3;
    s1_in.uop.psrc_4 = s1_in_r_uop_psrc_4;
    s1_in.uop.pdest = s1_in_r_uop_pdest;
    s1_in.uop.useRegCache_0 = s1_in_r_uop_useRegCache_0;
    s1_in.uop.useRegCache_1 = s1_in_r_uop_useRegCache_1;
    s1_in.uop.regCacheIdx_0 = s1_in_r_uop_regCacheIdx_0;
    s1_in.uop.regCacheIdx_1 = s1_in_r_uop_regCacheIdx_1;
    s1_in.uop.robIdx_flag = s1_in_r_uop_robIdx_flag;
    s1_in.uop.robIdx_value = s1_in_r_uop_robIdx_value;
    s1_in.uop.instrSize = s1_in_r_uop_instrSize;
    s1_in.uop.dirtyFs = s1_in_r_uop_dirtyFs;
    s1_in.uop.dirtyVs = s1_in_r_uop_dirtyVs;
    s1_in.uop.traceBlockInPipe_itype = s1_in_r_uop_traceBlockInPipe_itype;
    s1_in.uop.traceBlockInPipe_iretire = s1_in_r_uop_traceBlockInPipe_iretire;
    s1_in.uop.traceBlockInPipe_ilastsize = s1_in_r_uop_traceBlockInPipe_ilastsize;
    s1_in.uop.eliminatedMove = s1_in_r_uop_eliminatedMove;
    s1_in.uop.snapshot = s1_in_r_uop_snapshot;
    s1_in.uop.debugInfo_eliminatedMove = s1_in_r_uop_debugInfo_eliminatedMove;
    s1_in.uop.debugInfo_renameTime = s1_in_r_uop_debugInfo_renameTime;
    s1_in.uop.debugInfo_dispatchTime = s1_in_r_uop_debugInfo_dispatchTime;
    s1_in.uop.debugInfo_enqRsTime = s1_in_r_uop_debugInfo_enqRsTime;
    s1_in.uop.debugInfo_selectTime = s1_in_r_uop_debugInfo_selectTime;
    s1_in.uop.debugInfo_issueTime = s1_in_r_uop_debugInfo_issueTime;
    s1_in.uop.debugInfo_writebackTime = s1_in_r_uop_debugInfo_writebackTime;
    s1_in.uop.debugInfo_runahead_checkpoint_id = s1_in_r_uop_debugInfo_runahead_checkpoint_id;
    s1_in.uop.debugInfo_tlbFirstReqTime = s1_in_r_uop_debugInfo_tlbFirstReqTime;
    s1_in.uop.debugInfo_tlbRespTime = s1_in_r_uop_debugInfo_tlbRespTime;
    s1_in.uop.debug_seqNum_seqNum = s1_in_r_uop_debug_seqNum_seqNum;
    s1_in.uop.debug_seqNum_uopIdx = s1_in_r_uop_debug_seqNum_uopIdx;
    s1_in.uop.storeSetHit = s1_in_r_uop_storeSetHit;
    s1_in.uop.waitForRobIdx_flag = s1_in_r_uop_waitForRobIdx_flag;
    s1_in.uop.waitForRobIdx_value = s1_in_r_uop_waitForRobIdx_value;
    s1_in.uop.loadWaitBit = s1_in_r_uop_loadWaitBit;
    s1_in.uop.loadWaitStrict = s1_in_r_uop_loadWaitStrict;
    s1_in.uop.ssid = s1_in_r_uop_ssid;
    s1_in.uop.lqIdx_flag = s1_in_r_uop_lqIdx_flag;
    s1_in.uop.lqIdx_value = s1_in_r_uop_lqIdx_value;
    s1_in.uop.sqIdx_flag = s1_in_r_uop_sqIdx_flag;
    s1_in.uop.sqIdx_value = s1_in_r_uop_sqIdx_value;
    s1_in.uop.singleStep = s1_in_r_uop_singleStep;
    s1_in.uop.replayInst = s1_in_r_uop_replayInst;
    s1_in.uop.debug_fuType = s1_in_r_uop_debug_fuType;
    s1_in.uop.debug_sim_trig = s1_in_r_uop_debug_sim_trig;
    s1_in.uop.numLsElem = s1_in_r_uop_numLsElem;
    s1_in.vaddr = s1_in_r_vaddr;
    s1_in.paddr = s1_in_r_paddr;
    s1_in.mask = s1_in_r_mask;
    s1_in.data = s1_in_r_data;
    s1_in.nc = s1_in_r_nc;
    s1_in.isPrefetch = s1_in_r_isPrefetch;
    s1_in.isHWPrefetch = s1_in_r_isHWPrefetch;
    s1_in.isvec = s1_in_r_isvec;
    s1_in.is128bit = s1_in_r_is128bit;
    s1_in.elemIdx = s1_in_r_elemIdx;
    s1_in.alignedType = s1_in_r_alignedType;
    s1_in.mbIndex = s1_in_r_mbIndex;
    s1_in.reg_offset = s1_in_r_reg_offset;
    s1_in.elemIdxInsideVd = s1_in_r_elemIdxInsideVd;
    s1_in.vecBaseVaddr = s1_in_r_vecBaseVaddr;
    s1_in.vecActive = s1_in_r_vecActive;
    s1_in.isLoadReplay = s1_in_r_isLoadReplay;
    s1_in.isFastReplay = s1_in_r_isFastReplay;
    s1_in.isFirstIssue = s1_in_r_isFirstIssue;
    s1_in.hasROBEntry = s1_in_r_hasROBEntry;
    s1_in.mshrid = s1_in_r_mshrid;
    s1_in.forward_tlDchannel = s1_in_r_forward_tlDchannel;
    s1_in.schedIndex = s1_in_r_schedIndex;
    s1_in.tlbNoQuery = s1_in_r_tlbNoQuery;
    s1_in.isFrmMisAlignBuf = s1_in_r_isFrmMisAlignBuf;
    s1_in.isMisalign = s1_in_r_isMisalign;
    s1_in.isFinalSplit = s1_in_r_isFinalSplit;
    s1_in.misalignWith16Byte = s1_in_r_misalignWith16Byte;
    s1_in.misalignNeedWakeUp = s1_in_r_misalignNeedWakeUp;
  end

  // ---- s2_in  <= s1_out（s1_fire 时整包打拍，无复位）：golden 留下的 216 个字段 ----
  logic [7:0] s2_in_r_uop_robIdx_value;
  logic s2_in_r_uop_robIdx_flag;
  logic [31:0] s2_in_r_uop_instr;
  logic [49:0] s2_in_r_uop_pc;
  logic [9:0] s2_in_r_uop_foldpc;
  logic s2_in_r_uop_exceptionVec_0;
  logic s2_in_r_uop_exceptionVec_1;
  logic s2_in_r_uop_exceptionVec_2;
  logic s2_in_r_uop_exceptionVec_3;
  logic s2_in_r_uop_exceptionVec_4;
  logic s2_in_r_uop_exceptionVec_5;
  logic s2_in_r_uop_exceptionVec_6;
  logic s2_in_r_uop_exceptionVec_7;
  logic s2_in_r_uop_exceptionVec_8;
  logic s2_in_r_uop_exceptionVec_9;
  logic s2_in_r_uop_exceptionVec_10;
  logic s2_in_r_uop_exceptionVec_11;
  logic s2_in_r_uop_exceptionVec_12;
  logic s2_in_r_uop_exceptionVec_13;
  logic s2_in_r_uop_exceptionVec_14;
  logic s2_in_r_uop_exceptionVec_15;
  logic s2_in_r_uop_exceptionVec_16;
  logic s2_in_r_uop_exceptionVec_17;
  logic s2_in_r_uop_exceptionVec_18;
  logic s2_in_r_uop_exceptionVec_19;
  logic s2_in_r_uop_exceptionVec_20;
  logic s2_in_r_uop_exceptionVec_21;
  logic s2_in_r_uop_exceptionVec_22;
  logic s2_in_r_uop_exceptionVec_23;
  logic s2_in_r_uop_isFetchMalAddr;
  logic s2_in_r_uop_hasException;
  logic [3:0] s2_in_r_uop_trigger;
  logic s2_in_r_uop_preDecodeInfo_valid;
  logic s2_in_r_uop_preDecodeInfo_isRVC;
  logic [1:0] s2_in_r_uop_preDecodeInfo_brType;
  logic s2_in_r_uop_preDecodeInfo_isCall;
  logic s2_in_r_uop_preDecodeInfo_isRet;
  logic s2_in_r_uop_pred_taken;
  logic s2_in_r_uop_crossPageIPFFix;
  logic s2_in_r_uop_ftqPtr_flag;
  logic [5:0] s2_in_r_uop_ftqPtr_value;
  logic [3:0] s2_in_r_uop_ftqOffset;
  logic s2_in_r_uop_satpFlushFirstFetchFault;
  logic [3:0] s2_in_r_uop_srcType_0;
  logic [3:0] s2_in_r_uop_srcType_1;
  logic [3:0] s2_in_r_uop_srcType_2;
  logic [3:0] s2_in_r_uop_srcType_3;
  logic [3:0] s2_in_r_uop_srcType_4;
  logic [5:0] s2_in_r_uop_ldest;
  logic [34:0] s2_in_r_uop_fuType;
  logic [8:0] s2_in_r_uop_fuOpType;
  logic s2_in_r_uop_rfWen;
  logic s2_in_r_uop_fpWen;
  logic s2_in_r_uop_vecWen;
  logic s2_in_r_uop_v0Wen;
  logic s2_in_r_uop_vlWen;
  logic s2_in_r_uop_isXSTrap;
  logic s2_in_r_uop_waitForward;
  logic s2_in_r_uop_blockBackward;
  logic s2_in_r_uop_canRobCompress;
  logic [3:0] s2_in_r_uop_selImm;
  logic [31:0] s2_in_r_uop_imm;
  logic [1:0] s2_in_r_uop_fpu_typeTagOut;
  logic s2_in_r_uop_fpu_wflags;
  logic [1:0] s2_in_r_uop_fpu_typ;
  logic [1:0] s2_in_r_uop_fpu_fmt;
  logic [2:0] s2_in_r_uop_fpu_rm;
  logic s2_in_r_uop_vpu_vill;
  logic s2_in_r_uop_vpu_vma;
  logic s2_in_r_uop_vpu_vta;
  logic [1:0] s2_in_r_uop_vpu_vsew;
  logic [2:0] s2_in_r_uop_vpu_vlmul;
  logic s2_in_r_uop_vpu_specVill;
  logic s2_in_r_uop_vpu_specVma;
  logic s2_in_r_uop_vpu_specVta;
  logic [1:0] s2_in_r_uop_vpu_specVsew;
  logic [2:0] s2_in_r_uop_vpu_specVlmul;
  logic s2_in_r_uop_vpu_vm;
  logic [7:0] s2_in_r_uop_vpu_vstart;
  logic [2:0] s2_in_r_uop_vpu_frm;
  logic s2_in_r_uop_vpu_fpu_isFpToVecInst;
  logic s2_in_r_uop_vpu_fpu_isFP32Instr;
  logic s2_in_r_uop_vpu_fpu_isFP64Instr;
  logic s2_in_r_uop_vpu_fpu_isReduction;
  logic s2_in_r_uop_vpu_fpu_isFoldTo1_2;
  logic s2_in_r_uop_vpu_fpu_isFoldTo1_4;
  logic s2_in_r_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0] s2_in_r_uop_vpu_vxrm;
  logic [6:0] s2_in_r_uop_vpu_vuopIdx;
  logic s2_in_r_uop_vpu_lastUop;
  logic [127:0] s2_in_r_uop_vpu_vmask;
  logic [7:0] s2_in_r_uop_vpu_vl;
  logic [2:0] s2_in_r_uop_vpu_nf;
  logic [1:0] s2_in_r_uop_vpu_veew;
  logic s2_in_r_uop_vpu_isReverse;
  logic s2_in_r_uop_vpu_isExt;
  logic s2_in_r_uop_vpu_isNarrow;
  logic s2_in_r_uop_vpu_isDstMask;
  logic s2_in_r_uop_vpu_isOpMask;
  logic s2_in_r_uop_vpu_isMove;
  logic s2_in_r_uop_vpu_isDependOldVd;
  logic s2_in_r_uop_vpu_isWritePartVd;
  logic s2_in_r_uop_vpu_isVleff;
  logic s2_in_r_uop_vlsInstr;
  logic s2_in_r_uop_wfflags;
  logic s2_in_r_uop_isMove;
  logic s2_in_r_uop_isDropAmocasSta;
  logic [6:0] s2_in_r_uop_uopIdx;
  logic s2_in_r_uop_isVset;
  logic s2_in_r_uop_firstUop;
  logic s2_in_r_uop_lastUop;
  logic [6:0] s2_in_r_uop_numUops;
  logic [6:0] s2_in_r_uop_numWB;
  logic [2:0] s2_in_r_uop_commitType;
  logic s2_in_r_uop_srcState_0;
  logic s2_in_r_uop_srcState_1;
  logic s2_in_r_uop_srcState_2;
  logic s2_in_r_uop_srcState_3;
  logic s2_in_r_uop_srcState_4;
  logic [1:0] s2_in_r_uop_srcLoadDependency_0_0;
  logic [1:0] s2_in_r_uop_srcLoadDependency_0_1;
  logic [1:0] s2_in_r_uop_srcLoadDependency_0_2;
  logic [1:0] s2_in_r_uop_srcLoadDependency_1_0;
  logic [1:0] s2_in_r_uop_srcLoadDependency_1_1;
  logic [1:0] s2_in_r_uop_srcLoadDependency_1_2;
  logic [1:0] s2_in_r_uop_srcLoadDependency_2_0;
  logic [1:0] s2_in_r_uop_srcLoadDependency_2_1;
  logic [1:0] s2_in_r_uop_srcLoadDependency_2_2;
  logic [1:0] s2_in_r_uop_srcLoadDependency_3_0;
  logic [1:0] s2_in_r_uop_srcLoadDependency_3_1;
  logic [1:0] s2_in_r_uop_srcLoadDependency_3_2;
  logic [1:0] s2_in_r_uop_srcLoadDependency_4_0;
  logic [1:0] s2_in_r_uop_srcLoadDependency_4_1;
  logic [1:0] s2_in_r_uop_srcLoadDependency_4_2;
  logic [7:0] s2_in_r_uop_psrc_0;
  logic [7:0] s2_in_r_uop_psrc_1;
  logic [7:0] s2_in_r_uop_psrc_2;
  logic [7:0] s2_in_r_uop_psrc_3;
  logic [7:0] s2_in_r_uop_psrc_4;
  logic [7:0] s2_in_r_uop_pdest;
  logic s2_in_r_uop_useRegCache_0;
  logic s2_in_r_uop_useRegCache_1;
  logic [4:0] s2_in_r_uop_regCacheIdx_0;
  logic [4:0] s2_in_r_uop_regCacheIdx_1;
  logic [2:0] s2_in_r_uop_instrSize;
  logic s2_in_r_uop_dirtyFs;
  logic s2_in_r_uop_dirtyVs;
  logic [3:0] s2_in_r_uop_traceBlockInPipe_itype;
  logic [3:0] s2_in_r_uop_traceBlockInPipe_iretire;
  logic s2_in_r_uop_traceBlockInPipe_ilastsize;
  logic s2_in_r_uop_eliminatedMove;
  logic s2_in_r_uop_snapshot;
  logic s2_in_r_uop_debugInfo_eliminatedMove;
  logic [63:0] s2_in_r_uop_debugInfo_renameTime;
  logic [63:0] s2_in_r_uop_debugInfo_dispatchTime;
  logic [63:0] s2_in_r_uop_debugInfo_enqRsTime;
  logic [63:0] s2_in_r_uop_debugInfo_selectTime;
  logic [63:0] s2_in_r_uop_debugInfo_issueTime;
  logic [63:0] s2_in_r_uop_debugInfo_writebackTime;
  logic [63:0] s2_in_r_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0] s2_in_r_uop_debugInfo_tlbFirstReqTime;
  logic [63:0] s2_in_r_uop_debugInfo_tlbRespTime;
  logic [55:0] s2_in_r_uop_debug_seqNum_seqNum;
  logic [7:0] s2_in_r_uop_debug_seqNum_uopIdx;
  logic s2_in_r_uop_storeSetHit;
  logic s2_in_r_uop_waitForRobIdx_flag;
  logic [7:0] s2_in_r_uop_waitForRobIdx_value;
  logic s2_in_r_uop_loadWaitBit;
  logic s2_in_r_uop_loadWaitStrict;
  logic [4:0] s2_in_r_uop_ssid;
  logic s2_in_r_uop_lqIdx_flag;
  logic [6:0] s2_in_r_uop_lqIdx_value;
  logic s2_in_r_uop_sqIdx_flag;
  logic [5:0] s2_in_r_uop_sqIdx_value;
  logic s2_in_r_uop_singleStep;
  logic s2_in_r_uop_replayInst;
  logic [34:0] s2_in_r_uop_debug_fuType;
  logic s2_in_r_uop_debug_sim_trig;
  logic [4:0] s2_in_r_uop_numLsElem;
  logic [49:0] s2_in_r_vaddr;
  logic [63:0] s2_in_r_fullva;
  logic s2_in_r_vaNeedExt;
  logic [47:0] s2_in_r_paddr;
  logic [63:0] s2_in_r_gpaddr;
  logic [15:0] s2_in_r_mask;
  logic [128:0] s2_in_r_data;
  logic s2_in_r_tlbMiss;
  logic s2_in_r_ptwBack;
  logic s2_in_r_nc;
  logic s2_in_r_mmio;
  logic s2_in_r_isHyper;
  logic s2_in_r_isForVSnonLeafPTE;
  logic s2_in_r_isPrefetch;
  logic s2_in_r_isHWPrefetch;
  logic s2_in_r_isvec;
  logic s2_in_r_is128bit;
  logic [7:0] s2_in_r_elemIdx;
  logic [2:0] s2_in_r_alignedType;
  logic [3:0] s2_in_r_mbIndex;
  logic [3:0] s2_in_r_reg_offset;
  logic [7:0] s2_in_r_elemIdxInsideVd;
  logic [49:0] s2_in_r_vecVaddrOffset;
  logic [15:0] s2_in_r_vecTriggerMask;
  logic s2_in_r_vecActive;
  logic s2_in_r_isLoadReplay;
  logic s2_in_r_isFastReplay;
  logic s2_in_r_isFirstIssue;
  logic s2_in_r_hasROBEntry;
  logic s2_in_r_forward_tlDchannel;
  logic [6:0] s2_in_r_schedIndex;
  logic s2_in_r_isFrmMisAlignBuf;
  logic s2_in_r_isMisalign;
  logic s2_in_r_isFinalSplit;
  logic s2_in_r_misalignWith16Byte;
  logic s2_in_r_misalignNeedWakeUp;
  logic s2_in_r_rep_info_cause_9;
  always_ff @(posedge clock) begin
    if (s1_fire) begin
      s2_in_r_uop_robIdx_value <= s1_out.uop.robIdx_value;
      s2_in_r_uop_robIdx_flag <= s1_out.uop.robIdx_flag;
      s2_in_r_uop_instr <= s1_out.uop.instr;
      s2_in_r_uop_pc <= s1_out.uop.pc;
      s2_in_r_uop_foldpc <= s1_out.uop.foldpc;
      s2_in_r_uop_exceptionVec_0 <= s1_out.uop.exceptionVec[0];
      s2_in_r_uop_exceptionVec_1 <= s1_out.uop.exceptionVec[1];
      s2_in_r_uop_exceptionVec_2 <= s1_out.uop.exceptionVec[2];
      s2_in_r_uop_exceptionVec_3 <= s1_out.uop.exceptionVec[3];
      s2_in_r_uop_exceptionVec_4 <= s1_out.uop.exceptionVec[4];
      s2_in_r_uop_exceptionVec_5 <= s1_out.uop.exceptionVec[5];
      s2_in_r_uop_exceptionVec_6 <= s1_out.uop.exceptionVec[6];
      s2_in_r_uop_exceptionVec_7 <= s1_out.uop.exceptionVec[7];
      s2_in_r_uop_exceptionVec_8 <= s1_out.uop.exceptionVec[8];
      s2_in_r_uop_exceptionVec_9 <= s1_out.uop.exceptionVec[9];
      s2_in_r_uop_exceptionVec_10 <= s1_out.uop.exceptionVec[10];
      s2_in_r_uop_exceptionVec_11 <= s1_out.uop.exceptionVec[11];
      s2_in_r_uop_exceptionVec_12 <= s1_out.uop.exceptionVec[12];
      s2_in_r_uop_exceptionVec_13 <= s1_out.uop.exceptionVec[13];
      s2_in_r_uop_exceptionVec_14 <= s1_out.uop.exceptionVec[14];
      s2_in_r_uop_exceptionVec_15 <= s1_out.uop.exceptionVec[15];
      s2_in_r_uop_exceptionVec_16 <= s1_out.uop.exceptionVec[16];
      s2_in_r_uop_exceptionVec_17 <= s1_out.uop.exceptionVec[17];
      s2_in_r_uop_exceptionVec_18 <= s1_out.uop.exceptionVec[18];
      s2_in_r_uop_exceptionVec_19 <= s1_out.uop.exceptionVec[19];
      s2_in_r_uop_exceptionVec_20 <= s1_out.uop.exceptionVec[20];
      s2_in_r_uop_exceptionVec_21 <= s1_out.uop.exceptionVec[21];
      s2_in_r_uop_exceptionVec_22 <= s1_out.uop.exceptionVec[22];
      s2_in_r_uop_exceptionVec_23 <= s1_out.uop.exceptionVec[23];
      s2_in_r_uop_isFetchMalAddr <= s1_out.uop.isFetchMalAddr;
      s2_in_r_uop_hasException <= s1_out.uop.hasException;
      s2_in_r_uop_trigger <= s1_out.uop.trigger;
      s2_in_r_uop_preDecodeInfo_valid <= s1_out.uop.preDecodeInfo_valid;
      s2_in_r_uop_preDecodeInfo_isRVC <= s1_out.uop.preDecodeInfo_isRVC;
      s2_in_r_uop_preDecodeInfo_brType <= s1_out.uop.preDecodeInfo_brType;
      s2_in_r_uop_preDecodeInfo_isCall <= s1_out.uop.preDecodeInfo_isCall;
      s2_in_r_uop_preDecodeInfo_isRet <= s1_out.uop.preDecodeInfo_isRet;
      s2_in_r_uop_pred_taken <= s1_out.uop.pred_taken;
      s2_in_r_uop_crossPageIPFFix <= s1_out.uop.crossPageIPFFix;
      s2_in_r_uop_ftqPtr_flag <= s1_out.uop.ftqPtr_flag;
      s2_in_r_uop_ftqPtr_value <= s1_out.uop.ftqPtr_value;
      s2_in_r_uop_ftqOffset <= s1_out.uop.ftqOffset;
      s2_in_r_uop_satpFlushFirstFetchFault <= s1_out.uop.satpFlushFirstFetchFault;
      s2_in_r_uop_srcType_0 <= s1_out.uop.srcType_0;
      s2_in_r_uop_srcType_1 <= s1_out.uop.srcType_1;
      s2_in_r_uop_srcType_2 <= s1_out.uop.srcType_2;
      s2_in_r_uop_srcType_3 <= s1_out.uop.srcType_3;
      s2_in_r_uop_srcType_4 <= s1_out.uop.srcType_4;
      s2_in_r_uop_ldest <= s1_out.uop.ldest;
      s2_in_r_uop_fuType <= s1_out.uop.fuType;
      s2_in_r_uop_fuOpType <= s1_out.uop.fuOpType;
      s2_in_r_uop_rfWen <= s1_out.uop.rfWen;
      s2_in_r_uop_fpWen <= s1_out.uop.fpWen;
      s2_in_r_uop_vecWen <= s1_out.uop.vecWen;
      s2_in_r_uop_v0Wen <= s1_out.uop.v0Wen;
      s2_in_r_uop_vlWen <= s1_out.uop.vlWen;
      s2_in_r_uop_isXSTrap <= s1_out.uop.isXSTrap;
      s2_in_r_uop_waitForward <= s1_out.uop.waitForward;
      s2_in_r_uop_blockBackward <= s1_out.uop.blockBackward;
      s2_in_r_uop_canRobCompress <= s1_out.uop.canRobCompress;
      s2_in_r_uop_selImm <= s1_out.uop.selImm;
      s2_in_r_uop_imm <= s1_out.uop.imm;
      s2_in_r_uop_fpu_typeTagOut <= s1_out.uop.fpu_typeTagOut;
      s2_in_r_uop_fpu_wflags <= s1_out.uop.fpu_wflags;
      s2_in_r_uop_fpu_typ <= s1_out.uop.fpu_typ;
      s2_in_r_uop_fpu_fmt <= s1_out.uop.fpu_fmt;
      s2_in_r_uop_fpu_rm <= s1_out.uop.fpu_rm;
      s2_in_r_uop_vpu_vill <= s1_out.uop.vpu_vill;
      s2_in_r_uop_vpu_vma <= s1_out.uop.vpu_vma;
      s2_in_r_uop_vpu_vta <= s1_out.uop.vpu_vta;
      s2_in_r_uop_vpu_vsew <= s1_out.uop.vpu_vsew;
      s2_in_r_uop_vpu_vlmul <= s1_out.uop.vpu_vlmul;
      s2_in_r_uop_vpu_specVill <= s1_out.uop.vpu_specVill;
      s2_in_r_uop_vpu_specVma <= s1_out.uop.vpu_specVma;
      s2_in_r_uop_vpu_specVta <= s1_out.uop.vpu_specVta;
      s2_in_r_uop_vpu_specVsew <= s1_out.uop.vpu_specVsew;
      s2_in_r_uop_vpu_specVlmul <= s1_out.uop.vpu_specVlmul;
      s2_in_r_uop_vpu_vm <= s1_out.uop.vpu_vm;
      s2_in_r_uop_vpu_vstart <= s1_out.uop.vpu_vstart;
      s2_in_r_uop_vpu_frm <= s1_out.uop.vpu_frm;
      s2_in_r_uop_vpu_fpu_isFpToVecInst <= s1_out.uop.vpu_fpu_isFpToVecInst;
      s2_in_r_uop_vpu_fpu_isFP32Instr <= s1_out.uop.vpu_fpu_isFP32Instr;
      s2_in_r_uop_vpu_fpu_isFP64Instr <= s1_out.uop.vpu_fpu_isFP64Instr;
      s2_in_r_uop_vpu_fpu_isReduction <= s1_out.uop.vpu_fpu_isReduction;
      s2_in_r_uop_vpu_fpu_isFoldTo1_2 <= s1_out.uop.vpu_fpu_isFoldTo1_2;
      s2_in_r_uop_vpu_fpu_isFoldTo1_4 <= s1_out.uop.vpu_fpu_isFoldTo1_4;
      s2_in_r_uop_vpu_fpu_isFoldTo1_8 <= s1_out.uop.vpu_fpu_isFoldTo1_8;
      s2_in_r_uop_vpu_vxrm <= s1_out.uop.vpu_vxrm;
      s2_in_r_uop_vpu_vuopIdx <= s1_out.uop.vpu_vuopIdx;
      s2_in_r_uop_vpu_lastUop <= s1_out.uop.vpu_lastUop;
      s2_in_r_uop_vpu_vmask <= s1_out.uop.vpu_vmask;
      s2_in_r_uop_vpu_vl <= s1_out.uop.vpu_vl;
      s2_in_r_uop_vpu_nf <= s1_out.uop.vpu_nf;
      s2_in_r_uop_vpu_veew <= s1_out.uop.vpu_veew;
      s2_in_r_uop_vpu_isReverse <= s1_out.uop.vpu_isReverse;
      s2_in_r_uop_vpu_isExt <= s1_out.uop.vpu_isExt;
      s2_in_r_uop_vpu_isNarrow <= s1_out.uop.vpu_isNarrow;
      s2_in_r_uop_vpu_isDstMask <= s1_out.uop.vpu_isDstMask;
      s2_in_r_uop_vpu_isOpMask <= s1_out.uop.vpu_isOpMask;
      s2_in_r_uop_vpu_isMove <= s1_out.uop.vpu_isMove;
      s2_in_r_uop_vpu_isDependOldVd <= s1_out.uop.vpu_isDependOldVd;
      s2_in_r_uop_vpu_isWritePartVd <= s1_out.uop.vpu_isWritePartVd;
      s2_in_r_uop_vpu_isVleff <= s1_out.uop.vpu_isVleff;
      s2_in_r_uop_vlsInstr <= s1_out.uop.vlsInstr;
      s2_in_r_uop_wfflags <= s1_out.uop.wfflags;
      s2_in_r_uop_isMove <= s1_out.uop.isMove;
      s2_in_r_uop_isDropAmocasSta <= s1_out.uop.isDropAmocasSta;
      s2_in_r_uop_uopIdx <= s1_out.uop.uopIdx;
      s2_in_r_uop_isVset <= s1_out.uop.isVset;
      s2_in_r_uop_firstUop <= s1_out.uop.firstUop;
      s2_in_r_uop_lastUop <= s1_out.uop.lastUop;
      s2_in_r_uop_numUops <= s1_out.uop.numUops;
      s2_in_r_uop_numWB <= s1_out.uop.numWB;
      s2_in_r_uop_commitType <= s1_out.uop.commitType;
      s2_in_r_uop_srcState_0 <= s1_out.uop.srcState_0;
      s2_in_r_uop_srcState_1 <= s1_out.uop.srcState_1;
      s2_in_r_uop_srcState_2 <= s1_out.uop.srcState_2;
      s2_in_r_uop_srcState_3 <= s1_out.uop.srcState_3;
      s2_in_r_uop_srcState_4 <= s1_out.uop.srcState_4;
      s2_in_r_uop_srcLoadDependency_0_0 <= s1_out.uop.srcLoadDependency_0_0;
      s2_in_r_uop_srcLoadDependency_0_1 <= s1_out.uop.srcLoadDependency_0_1;
      s2_in_r_uop_srcLoadDependency_0_2 <= s1_out.uop.srcLoadDependency_0_2;
      s2_in_r_uop_srcLoadDependency_1_0 <= s1_out.uop.srcLoadDependency_1_0;
      s2_in_r_uop_srcLoadDependency_1_1 <= s1_out.uop.srcLoadDependency_1_1;
      s2_in_r_uop_srcLoadDependency_1_2 <= s1_out.uop.srcLoadDependency_1_2;
      s2_in_r_uop_srcLoadDependency_2_0 <= s1_out.uop.srcLoadDependency_2_0;
      s2_in_r_uop_srcLoadDependency_2_1 <= s1_out.uop.srcLoadDependency_2_1;
      s2_in_r_uop_srcLoadDependency_2_2 <= s1_out.uop.srcLoadDependency_2_2;
      s2_in_r_uop_srcLoadDependency_3_0 <= s1_out.uop.srcLoadDependency_3_0;
      s2_in_r_uop_srcLoadDependency_3_1 <= s1_out.uop.srcLoadDependency_3_1;
      s2_in_r_uop_srcLoadDependency_3_2 <= s1_out.uop.srcLoadDependency_3_2;
      s2_in_r_uop_srcLoadDependency_4_0 <= s1_out.uop.srcLoadDependency_4_0;
      s2_in_r_uop_srcLoadDependency_4_1 <= s1_out.uop.srcLoadDependency_4_1;
      s2_in_r_uop_srcLoadDependency_4_2 <= s1_out.uop.srcLoadDependency_4_2;
      s2_in_r_uop_psrc_0 <= s1_out.uop.psrc_0;
      s2_in_r_uop_psrc_1 <= s1_out.uop.psrc_1;
      s2_in_r_uop_psrc_2 <= s1_out.uop.psrc_2;
      s2_in_r_uop_psrc_3 <= s1_out.uop.psrc_3;
      s2_in_r_uop_psrc_4 <= s1_out.uop.psrc_4;
      s2_in_r_uop_pdest <= s1_out.uop.pdest;
      s2_in_r_uop_useRegCache_0 <= s1_out.uop.useRegCache_0;
      s2_in_r_uop_useRegCache_1 <= s1_out.uop.useRegCache_1;
      s2_in_r_uop_regCacheIdx_0 <= s1_out.uop.regCacheIdx_0;
      s2_in_r_uop_regCacheIdx_1 <= s1_out.uop.regCacheIdx_1;
      s2_in_r_uop_instrSize <= s1_out.uop.instrSize;
      s2_in_r_uop_dirtyFs <= s1_out.uop.dirtyFs;
      s2_in_r_uop_dirtyVs <= s1_out.uop.dirtyVs;
      s2_in_r_uop_traceBlockInPipe_itype <= s1_out.uop.traceBlockInPipe_itype;
      s2_in_r_uop_traceBlockInPipe_iretire <= s1_out.uop.traceBlockInPipe_iretire;
      s2_in_r_uop_traceBlockInPipe_ilastsize <= s1_out.uop.traceBlockInPipe_ilastsize;
      s2_in_r_uop_eliminatedMove <= s1_out.uop.eliminatedMove;
      s2_in_r_uop_snapshot <= s1_out.uop.snapshot;
      s2_in_r_uop_debugInfo_eliminatedMove <= s1_out.uop.debugInfo_eliminatedMove;
      s2_in_r_uop_debugInfo_renameTime <= s1_out.uop.debugInfo_renameTime;
      s2_in_r_uop_debugInfo_dispatchTime <= s1_out.uop.debugInfo_dispatchTime;
      s2_in_r_uop_debugInfo_enqRsTime <= s1_out.uop.debugInfo_enqRsTime;
      s2_in_r_uop_debugInfo_selectTime <= s1_out.uop.debugInfo_selectTime;
      s2_in_r_uop_debugInfo_issueTime <= s1_out.uop.debugInfo_issueTime;
      s2_in_r_uop_debugInfo_writebackTime <= s1_out.uop.debugInfo_writebackTime;
      s2_in_r_uop_debugInfo_runahead_checkpoint_id <= s1_out.uop.debugInfo_runahead_checkpoint_id;
      s2_in_r_uop_debugInfo_tlbFirstReqTime <= s1_out.uop.debugInfo_tlbFirstReqTime;
      s2_in_r_uop_debugInfo_tlbRespTime <= s1_out.uop.debugInfo_tlbRespTime;
      s2_in_r_uop_debug_seqNum_seqNum <= s1_out.uop.debug_seqNum_seqNum;
      s2_in_r_uop_debug_seqNum_uopIdx <= s1_out.uop.debug_seqNum_uopIdx;
      s2_in_r_uop_storeSetHit <= s1_out.uop.storeSetHit;
      s2_in_r_uop_waitForRobIdx_flag <= s1_out.uop.waitForRobIdx_flag;
      s2_in_r_uop_waitForRobIdx_value <= s1_out.uop.waitForRobIdx_value;
      s2_in_r_uop_loadWaitBit <= s1_out.uop.loadWaitBit;
      s2_in_r_uop_loadWaitStrict <= s1_out.uop.loadWaitStrict;
      s2_in_r_uop_ssid <= s1_out.uop.ssid;
      s2_in_r_uop_lqIdx_flag <= s1_out.uop.lqIdx_flag;
      s2_in_r_uop_lqIdx_value <= s1_out.uop.lqIdx_value;
      s2_in_r_uop_sqIdx_flag <= s1_out.uop.sqIdx_flag;
      s2_in_r_uop_sqIdx_value <= s1_out.uop.sqIdx_value;
      s2_in_r_uop_singleStep <= s1_out.uop.singleStep;
      s2_in_r_uop_replayInst <= s1_out.uop.replayInst;
      s2_in_r_uop_debug_fuType <= s1_out.uop.debug_fuType;
      s2_in_r_uop_debug_sim_trig <= s1_out.uop.debug_sim_trig;
      s2_in_r_uop_numLsElem <= s1_out.uop.numLsElem;
      s2_in_r_vaddr <= s1_out.vaddr;
      s2_in_r_fullva <= s1_out.fullva;
      s2_in_r_vaNeedExt <= s1_out.vaNeedExt;
      s2_in_r_paddr <= s1_out.paddr;
      s2_in_r_gpaddr <= s1_out.gpaddr;
      s2_in_r_mask <= s1_out.mask;
      s2_in_r_data <= s1_out.data;
      s2_in_r_tlbMiss <= s1_out.tlbMiss;
      s2_in_r_ptwBack <= s1_out.ptwBack;
      s2_in_r_nc <= s1_out.nc;
      s2_in_r_mmio <= s1_out.mmio;
      s2_in_r_isHyper <= s1_out.isHyper;
      s2_in_r_isForVSnonLeafPTE <= s1_out.isForVSnonLeafPTE;
      s2_in_r_isPrefetch <= s1_out.isPrefetch;
      s2_in_r_isHWPrefetch <= s1_out.isHWPrefetch;
      s2_in_r_isvec <= s1_out.isvec;
      s2_in_r_is128bit <= s1_out.is128bit;
      s2_in_r_elemIdx <= s1_out.elemIdx;
      s2_in_r_alignedType <= s1_out.alignedType;
      s2_in_r_mbIndex <= s1_out.mbIndex;
      s2_in_r_reg_offset <= s1_out.reg_offset;
      s2_in_r_elemIdxInsideVd <= s1_out.elemIdxInsideVd;
      s2_in_r_vecVaddrOffset <= s1_out.vecVaddrOffset;
      s2_in_r_vecTriggerMask <= s1_out.vecTriggerMask;
      s2_in_r_vecActive <= s1_out.vecActive;
      s2_in_r_isLoadReplay <= s1_out.isLoadReplay;
      s2_in_r_isFastReplay <= s1_out.isFastReplay;
      s2_in_r_isFirstIssue <= s1_out.isFirstIssue;
      s2_in_r_hasROBEntry <= s1_out.hasROBEntry;
      s2_in_r_forward_tlDchannel <= s1_out.forward_tlDchannel;
      s2_in_r_schedIndex <= s1_out.schedIndex;
      s2_in_r_isFrmMisAlignBuf <= s1_out.isFrmMisAlignBuf;
      s2_in_r_isMisalign <= s1_out.isMisalign;
      s2_in_r_isFinalSplit <= s1_out.isFinalSplit;
      s2_in_r_misalignWith16Byte <= s1_out.misalignWith16Byte;
      s2_in_r_misalignNeedWakeUp <= s1_out.misalignNeedWakeUp;
      s2_in_r_rep_info_cause_9 <= s1_out.rep_info_cause[9];
    end
  end
  // 读回成 struct；golden 没留下的字段（DCE 掉 / 下游不用）恒 0
  always_comb begin
    s2_in = '0;
    s2_in.uop.robIdx_value = s2_in_r_uop_robIdx_value;
    s2_in.uop.robIdx_flag = s2_in_r_uop_robIdx_flag;
    s2_in.uop.instr = s2_in_r_uop_instr;
    s2_in.uop.pc = s2_in_r_uop_pc;
    s2_in.uop.foldpc = s2_in_r_uop_foldpc;
    s2_in.uop.exceptionVec[0] = s2_in_r_uop_exceptionVec_0;
    s2_in.uop.exceptionVec[1] = s2_in_r_uop_exceptionVec_1;
    s2_in.uop.exceptionVec[2] = s2_in_r_uop_exceptionVec_2;
    s2_in.uop.exceptionVec[3] = s2_in_r_uop_exceptionVec_3;
    s2_in.uop.exceptionVec[4] = s2_in_r_uop_exceptionVec_4;
    s2_in.uop.exceptionVec[5] = s2_in_r_uop_exceptionVec_5;
    s2_in.uop.exceptionVec[6] = s2_in_r_uop_exceptionVec_6;
    s2_in.uop.exceptionVec[7] = s2_in_r_uop_exceptionVec_7;
    s2_in.uop.exceptionVec[8] = s2_in_r_uop_exceptionVec_8;
    s2_in.uop.exceptionVec[9] = s2_in_r_uop_exceptionVec_9;
    s2_in.uop.exceptionVec[10] = s2_in_r_uop_exceptionVec_10;
    s2_in.uop.exceptionVec[11] = s2_in_r_uop_exceptionVec_11;
    s2_in.uop.exceptionVec[12] = s2_in_r_uop_exceptionVec_12;
    s2_in.uop.exceptionVec[13] = s2_in_r_uop_exceptionVec_13;
    s2_in.uop.exceptionVec[14] = s2_in_r_uop_exceptionVec_14;
    s2_in.uop.exceptionVec[15] = s2_in_r_uop_exceptionVec_15;
    s2_in.uop.exceptionVec[16] = s2_in_r_uop_exceptionVec_16;
    s2_in.uop.exceptionVec[17] = s2_in_r_uop_exceptionVec_17;
    s2_in.uop.exceptionVec[18] = s2_in_r_uop_exceptionVec_18;
    s2_in.uop.exceptionVec[19] = s2_in_r_uop_exceptionVec_19;
    s2_in.uop.exceptionVec[20] = s2_in_r_uop_exceptionVec_20;
    s2_in.uop.exceptionVec[21] = s2_in_r_uop_exceptionVec_21;
    s2_in.uop.exceptionVec[22] = s2_in_r_uop_exceptionVec_22;
    s2_in.uop.exceptionVec[23] = s2_in_r_uop_exceptionVec_23;
    s2_in.uop.isFetchMalAddr = s2_in_r_uop_isFetchMalAddr;
    s2_in.uop.hasException = s2_in_r_uop_hasException;
    s2_in.uop.trigger = s2_in_r_uop_trigger;
    s2_in.uop.preDecodeInfo_valid = s2_in_r_uop_preDecodeInfo_valid;
    s2_in.uop.preDecodeInfo_isRVC = s2_in_r_uop_preDecodeInfo_isRVC;
    s2_in.uop.preDecodeInfo_brType = s2_in_r_uop_preDecodeInfo_brType;
    s2_in.uop.preDecodeInfo_isCall = s2_in_r_uop_preDecodeInfo_isCall;
    s2_in.uop.preDecodeInfo_isRet = s2_in_r_uop_preDecodeInfo_isRet;
    s2_in.uop.pred_taken = s2_in_r_uop_pred_taken;
    s2_in.uop.crossPageIPFFix = s2_in_r_uop_crossPageIPFFix;
    s2_in.uop.ftqPtr_flag = s2_in_r_uop_ftqPtr_flag;
    s2_in.uop.ftqPtr_value = s2_in_r_uop_ftqPtr_value;
    s2_in.uop.ftqOffset = s2_in_r_uop_ftqOffset;
    s2_in.uop.satpFlushFirstFetchFault = s2_in_r_uop_satpFlushFirstFetchFault;
    s2_in.uop.srcType_0 = s2_in_r_uop_srcType_0;
    s2_in.uop.srcType_1 = s2_in_r_uop_srcType_1;
    s2_in.uop.srcType_2 = s2_in_r_uop_srcType_2;
    s2_in.uop.srcType_3 = s2_in_r_uop_srcType_3;
    s2_in.uop.srcType_4 = s2_in_r_uop_srcType_4;
    s2_in.uop.ldest = s2_in_r_uop_ldest;
    s2_in.uop.fuType = s2_in_r_uop_fuType;
    s2_in.uop.fuOpType = s2_in_r_uop_fuOpType;
    s2_in.uop.rfWen = s2_in_r_uop_rfWen;
    s2_in.uop.fpWen = s2_in_r_uop_fpWen;
    s2_in.uop.vecWen = s2_in_r_uop_vecWen;
    s2_in.uop.v0Wen = s2_in_r_uop_v0Wen;
    s2_in.uop.vlWen = s2_in_r_uop_vlWen;
    s2_in.uop.isXSTrap = s2_in_r_uop_isXSTrap;
    s2_in.uop.waitForward = s2_in_r_uop_waitForward;
    s2_in.uop.blockBackward = s2_in_r_uop_blockBackward;
    s2_in.uop.canRobCompress = s2_in_r_uop_canRobCompress;
    s2_in.uop.selImm = s2_in_r_uop_selImm;
    s2_in.uop.imm = s2_in_r_uop_imm;
    s2_in.uop.fpu_typeTagOut = s2_in_r_uop_fpu_typeTagOut;
    s2_in.uop.fpu_wflags = s2_in_r_uop_fpu_wflags;
    s2_in.uop.fpu_typ = s2_in_r_uop_fpu_typ;
    s2_in.uop.fpu_fmt = s2_in_r_uop_fpu_fmt;
    s2_in.uop.fpu_rm = s2_in_r_uop_fpu_rm;
    s2_in.uop.vpu_vill = s2_in_r_uop_vpu_vill;
    s2_in.uop.vpu_vma = s2_in_r_uop_vpu_vma;
    s2_in.uop.vpu_vta = s2_in_r_uop_vpu_vta;
    s2_in.uop.vpu_vsew = s2_in_r_uop_vpu_vsew;
    s2_in.uop.vpu_vlmul = s2_in_r_uop_vpu_vlmul;
    s2_in.uop.vpu_specVill = s2_in_r_uop_vpu_specVill;
    s2_in.uop.vpu_specVma = s2_in_r_uop_vpu_specVma;
    s2_in.uop.vpu_specVta = s2_in_r_uop_vpu_specVta;
    s2_in.uop.vpu_specVsew = s2_in_r_uop_vpu_specVsew;
    s2_in.uop.vpu_specVlmul = s2_in_r_uop_vpu_specVlmul;
    s2_in.uop.vpu_vm = s2_in_r_uop_vpu_vm;
    s2_in.uop.vpu_vstart = s2_in_r_uop_vpu_vstart;
    s2_in.uop.vpu_frm = s2_in_r_uop_vpu_frm;
    s2_in.uop.vpu_fpu_isFpToVecInst = s2_in_r_uop_vpu_fpu_isFpToVecInst;
    s2_in.uop.vpu_fpu_isFP32Instr = s2_in_r_uop_vpu_fpu_isFP32Instr;
    s2_in.uop.vpu_fpu_isFP64Instr = s2_in_r_uop_vpu_fpu_isFP64Instr;
    s2_in.uop.vpu_fpu_isReduction = s2_in_r_uop_vpu_fpu_isReduction;
    s2_in.uop.vpu_fpu_isFoldTo1_2 = s2_in_r_uop_vpu_fpu_isFoldTo1_2;
    s2_in.uop.vpu_fpu_isFoldTo1_4 = s2_in_r_uop_vpu_fpu_isFoldTo1_4;
    s2_in.uop.vpu_fpu_isFoldTo1_8 = s2_in_r_uop_vpu_fpu_isFoldTo1_8;
    s2_in.uop.vpu_vxrm = s2_in_r_uop_vpu_vxrm;
    s2_in.uop.vpu_vuopIdx = s2_in_r_uop_vpu_vuopIdx;
    s2_in.uop.vpu_lastUop = s2_in_r_uop_vpu_lastUop;
    s2_in.uop.vpu_vmask = s2_in_r_uop_vpu_vmask;
    s2_in.uop.vpu_vl = s2_in_r_uop_vpu_vl;
    s2_in.uop.vpu_nf = s2_in_r_uop_vpu_nf;
    s2_in.uop.vpu_veew = s2_in_r_uop_vpu_veew;
    s2_in.uop.vpu_isReverse = s2_in_r_uop_vpu_isReverse;
    s2_in.uop.vpu_isExt = s2_in_r_uop_vpu_isExt;
    s2_in.uop.vpu_isNarrow = s2_in_r_uop_vpu_isNarrow;
    s2_in.uop.vpu_isDstMask = s2_in_r_uop_vpu_isDstMask;
    s2_in.uop.vpu_isOpMask = s2_in_r_uop_vpu_isOpMask;
    s2_in.uop.vpu_isMove = s2_in_r_uop_vpu_isMove;
    s2_in.uop.vpu_isDependOldVd = s2_in_r_uop_vpu_isDependOldVd;
    s2_in.uop.vpu_isWritePartVd = s2_in_r_uop_vpu_isWritePartVd;
    s2_in.uop.vpu_isVleff = s2_in_r_uop_vpu_isVleff;
    s2_in.uop.vlsInstr = s2_in_r_uop_vlsInstr;
    s2_in.uop.wfflags = s2_in_r_uop_wfflags;
    s2_in.uop.isMove = s2_in_r_uop_isMove;
    s2_in.uop.isDropAmocasSta = s2_in_r_uop_isDropAmocasSta;
    s2_in.uop.uopIdx = s2_in_r_uop_uopIdx;
    s2_in.uop.isVset = s2_in_r_uop_isVset;
    s2_in.uop.firstUop = s2_in_r_uop_firstUop;
    s2_in.uop.lastUop = s2_in_r_uop_lastUop;
    s2_in.uop.numUops = s2_in_r_uop_numUops;
    s2_in.uop.numWB = s2_in_r_uop_numWB;
    s2_in.uop.commitType = s2_in_r_uop_commitType;
    s2_in.uop.srcState_0 = s2_in_r_uop_srcState_0;
    s2_in.uop.srcState_1 = s2_in_r_uop_srcState_1;
    s2_in.uop.srcState_2 = s2_in_r_uop_srcState_2;
    s2_in.uop.srcState_3 = s2_in_r_uop_srcState_3;
    s2_in.uop.srcState_4 = s2_in_r_uop_srcState_4;
    s2_in.uop.srcLoadDependency_0_0 = s2_in_r_uop_srcLoadDependency_0_0;
    s2_in.uop.srcLoadDependency_0_1 = s2_in_r_uop_srcLoadDependency_0_1;
    s2_in.uop.srcLoadDependency_0_2 = s2_in_r_uop_srcLoadDependency_0_2;
    s2_in.uop.srcLoadDependency_1_0 = s2_in_r_uop_srcLoadDependency_1_0;
    s2_in.uop.srcLoadDependency_1_1 = s2_in_r_uop_srcLoadDependency_1_1;
    s2_in.uop.srcLoadDependency_1_2 = s2_in_r_uop_srcLoadDependency_1_2;
    s2_in.uop.srcLoadDependency_2_0 = s2_in_r_uop_srcLoadDependency_2_0;
    s2_in.uop.srcLoadDependency_2_1 = s2_in_r_uop_srcLoadDependency_2_1;
    s2_in.uop.srcLoadDependency_2_2 = s2_in_r_uop_srcLoadDependency_2_2;
    s2_in.uop.srcLoadDependency_3_0 = s2_in_r_uop_srcLoadDependency_3_0;
    s2_in.uop.srcLoadDependency_3_1 = s2_in_r_uop_srcLoadDependency_3_1;
    s2_in.uop.srcLoadDependency_3_2 = s2_in_r_uop_srcLoadDependency_3_2;
    s2_in.uop.srcLoadDependency_4_0 = s2_in_r_uop_srcLoadDependency_4_0;
    s2_in.uop.srcLoadDependency_4_1 = s2_in_r_uop_srcLoadDependency_4_1;
    s2_in.uop.srcLoadDependency_4_2 = s2_in_r_uop_srcLoadDependency_4_2;
    s2_in.uop.psrc_0 = s2_in_r_uop_psrc_0;
    s2_in.uop.psrc_1 = s2_in_r_uop_psrc_1;
    s2_in.uop.psrc_2 = s2_in_r_uop_psrc_2;
    s2_in.uop.psrc_3 = s2_in_r_uop_psrc_3;
    s2_in.uop.psrc_4 = s2_in_r_uop_psrc_4;
    s2_in.uop.pdest = s2_in_r_uop_pdest;
    s2_in.uop.useRegCache_0 = s2_in_r_uop_useRegCache_0;
    s2_in.uop.useRegCache_1 = s2_in_r_uop_useRegCache_1;
    s2_in.uop.regCacheIdx_0 = s2_in_r_uop_regCacheIdx_0;
    s2_in.uop.regCacheIdx_1 = s2_in_r_uop_regCacheIdx_1;
    s2_in.uop.instrSize = s2_in_r_uop_instrSize;
    s2_in.uop.dirtyFs = s2_in_r_uop_dirtyFs;
    s2_in.uop.dirtyVs = s2_in_r_uop_dirtyVs;
    s2_in.uop.traceBlockInPipe_itype = s2_in_r_uop_traceBlockInPipe_itype;
    s2_in.uop.traceBlockInPipe_iretire = s2_in_r_uop_traceBlockInPipe_iretire;
    s2_in.uop.traceBlockInPipe_ilastsize = s2_in_r_uop_traceBlockInPipe_ilastsize;
    s2_in.uop.eliminatedMove = s2_in_r_uop_eliminatedMove;
    s2_in.uop.snapshot = s2_in_r_uop_snapshot;
    s2_in.uop.debugInfo_eliminatedMove = s2_in_r_uop_debugInfo_eliminatedMove;
    s2_in.uop.debugInfo_renameTime = s2_in_r_uop_debugInfo_renameTime;
    s2_in.uop.debugInfo_dispatchTime = s2_in_r_uop_debugInfo_dispatchTime;
    s2_in.uop.debugInfo_enqRsTime = s2_in_r_uop_debugInfo_enqRsTime;
    s2_in.uop.debugInfo_selectTime = s2_in_r_uop_debugInfo_selectTime;
    s2_in.uop.debugInfo_issueTime = s2_in_r_uop_debugInfo_issueTime;
    s2_in.uop.debugInfo_writebackTime = s2_in_r_uop_debugInfo_writebackTime;
    s2_in.uop.debugInfo_runahead_checkpoint_id = s2_in_r_uop_debugInfo_runahead_checkpoint_id;
    s2_in.uop.debugInfo_tlbFirstReqTime = s2_in_r_uop_debugInfo_tlbFirstReqTime;
    s2_in.uop.debugInfo_tlbRespTime = s2_in_r_uop_debugInfo_tlbRespTime;
    s2_in.uop.debug_seqNum_seqNum = s2_in_r_uop_debug_seqNum_seqNum;
    s2_in.uop.debug_seqNum_uopIdx = s2_in_r_uop_debug_seqNum_uopIdx;
    s2_in.uop.storeSetHit = s2_in_r_uop_storeSetHit;
    s2_in.uop.waitForRobIdx_flag = s2_in_r_uop_waitForRobIdx_flag;
    s2_in.uop.waitForRobIdx_value = s2_in_r_uop_waitForRobIdx_value;
    s2_in.uop.loadWaitBit = s2_in_r_uop_loadWaitBit;
    s2_in.uop.loadWaitStrict = s2_in_r_uop_loadWaitStrict;
    s2_in.uop.ssid = s2_in_r_uop_ssid;
    s2_in.uop.lqIdx_flag = s2_in_r_uop_lqIdx_flag;
    s2_in.uop.lqIdx_value = s2_in_r_uop_lqIdx_value;
    s2_in.uop.sqIdx_flag = s2_in_r_uop_sqIdx_flag;
    s2_in.uop.sqIdx_value = s2_in_r_uop_sqIdx_value;
    s2_in.uop.singleStep = s2_in_r_uop_singleStep;
    s2_in.uop.replayInst = s2_in_r_uop_replayInst;
    s2_in.uop.debug_fuType = s2_in_r_uop_debug_fuType;
    s2_in.uop.debug_sim_trig = s2_in_r_uop_debug_sim_trig;
    s2_in.uop.numLsElem = s2_in_r_uop_numLsElem;
    s2_in.vaddr = s2_in_r_vaddr;
    s2_in.fullva = s2_in_r_fullva;
    s2_in.vaNeedExt = s2_in_r_vaNeedExt;
    s2_in.paddr = s2_in_r_paddr;
    s2_in.gpaddr = s2_in_r_gpaddr;
    s2_in.mask = s2_in_r_mask;
    s2_in.data = s2_in_r_data;
    s2_in.tlbMiss = s2_in_r_tlbMiss;
    s2_in.ptwBack = s2_in_r_ptwBack;
    s2_in.nc = s2_in_r_nc;
    s2_in.mmio = s2_in_r_mmio;
    s2_in.isHyper = s2_in_r_isHyper;
    s2_in.isForVSnonLeafPTE = s2_in_r_isForVSnonLeafPTE;
    s2_in.isPrefetch = s2_in_r_isPrefetch;
    s2_in.isHWPrefetch = s2_in_r_isHWPrefetch;
    s2_in.isvec = s2_in_r_isvec;
    s2_in.is128bit = s2_in_r_is128bit;
    s2_in.elemIdx = s2_in_r_elemIdx;
    s2_in.alignedType = s2_in_r_alignedType;
    s2_in.mbIndex = s2_in_r_mbIndex;
    s2_in.reg_offset = s2_in_r_reg_offset;
    s2_in.elemIdxInsideVd = s2_in_r_elemIdxInsideVd;
    s2_in.vecVaddrOffset = s2_in_r_vecVaddrOffset;
    s2_in.vecTriggerMask = s2_in_r_vecTriggerMask;
    s2_in.vecActive = s2_in_r_vecActive;
    s2_in.isLoadReplay = s2_in_r_isLoadReplay;
    s2_in.isFastReplay = s2_in_r_isFastReplay;
    s2_in.isFirstIssue = s2_in_r_isFirstIssue;
    s2_in.hasROBEntry = s2_in_r_hasROBEntry;
    s2_in.forward_tlDchannel = s2_in_r_forward_tlDchannel;
    s2_in.schedIndex = s2_in_r_schedIndex;
    s2_in.isFrmMisAlignBuf = s2_in_r_isFrmMisAlignBuf;
    s2_in.isMisalign = s2_in_r_isMisalign;
    s2_in.isFinalSplit = s2_in_r_isFinalSplit;
    s2_in.misalignWith16Byte = s2_in_r_misalignWith16Byte;
    s2_in.misalignNeedWakeUp = s2_in_r_misalignNeedWakeUp;
    s2_in.rep_info_cause[9] = s2_in_r_rep_info_cause_9;
  end

  // ---- s3_in  <= s2_out（s2_fire 时整包打拍，无复位）：golden 留下的 228 个字段 ----
  logic [31:0] s3_in_uop_instr;
  logic [49:0] s3_in_uop_pc;
  logic [9:0] s3_in_uop_foldpc;
  logic s3_in_uop_exceptionVec_0;
  logic s3_in_uop_exceptionVec_1;
  logic s3_in_uop_exceptionVec_2;
  logic s3_in_uop_exceptionVec_3;
  logic s3_in_uop_exceptionVec_4;
  logic s3_in_uop_exceptionVec_5;
  logic s3_in_uop_exceptionVec_6;
  logic s3_in_uop_exceptionVec_7;
  logic s3_in_uop_exceptionVec_8;
  logic s3_in_uop_exceptionVec_9;
  logic s3_in_uop_exceptionVec_10;
  logic s3_in_uop_exceptionVec_11;
  logic s3_in_uop_exceptionVec_12;
  logic s3_in_uop_exceptionVec_13;
  logic s3_in_uop_exceptionVec_14;
  logic s3_in_uop_exceptionVec_15;
  logic s3_in_uop_exceptionVec_16;
  logic s3_in_uop_exceptionVec_17;
  logic s3_in_uop_exceptionVec_18;
  logic s3_in_uop_exceptionVec_19;
  logic s3_in_uop_exceptionVec_20;
  logic s3_in_uop_exceptionVec_21;
  logic s3_in_uop_exceptionVec_22;
  logic s3_in_uop_exceptionVec_23;
  logic s3_in_uop_isFetchMalAddr;
  logic s3_in_uop_hasException;
  logic [3:0] s3_in_uop_trigger;
  logic s3_in_uop_preDecodeInfo_valid;
  logic s3_in_uop_preDecodeInfo_isRVC;
  logic [1:0] s3_in_uop_preDecodeInfo_brType;
  logic s3_in_uop_preDecodeInfo_isCall;
  logic s3_in_uop_preDecodeInfo_isRet;
  logic s3_in_uop_pred_taken;
  logic s3_in_uop_crossPageIPFFix;
  logic s3_in_uop_ftqPtr_flag;
  logic [5:0] s3_in_uop_ftqPtr_value;
  logic [3:0] s3_in_uop_ftqOffset;
  logic s3_in_uop_satpFlushFirstFetchFault;
  logic [3:0] s3_in_uop_srcType_0;
  logic [3:0] s3_in_uop_srcType_1;
  logic [3:0] s3_in_uop_srcType_2;
  logic [3:0] s3_in_uop_srcType_3;
  logic [3:0] s3_in_uop_srcType_4;
  logic [5:0] s3_in_uop_ldest;
  logic [34:0] s3_in_uop_fuType;
  logic [8:0] s3_in_uop_fuOpType;
  logic s3_in_uop_rfWen;
  logic s3_in_uop_fpWen;
  logic s3_in_uop_vecWen;
  logic s3_in_uop_v0Wen;
  logic s3_in_uop_vlWen;
  logic s3_in_uop_isXSTrap;
  logic s3_in_uop_waitForward;
  logic s3_in_uop_blockBackward;
  logic s3_in_uop_canRobCompress;
  logic [3:0] s3_in_uop_selImm;
  logic [31:0] s3_in_uop_imm;
  logic [1:0] s3_in_uop_fpu_typeTagOut;
  logic s3_in_uop_fpu_wflags;
  logic [1:0] s3_in_uop_fpu_typ;
  logic [1:0] s3_in_uop_fpu_fmt;
  logic [2:0] s3_in_uop_fpu_rm;
  logic s3_in_uop_vpu_vill;
  logic s3_in_uop_vpu_vma;
  logic s3_in_uop_vpu_vta;
  logic [1:0] s3_in_uop_vpu_vsew;
  logic [2:0] s3_in_uop_vpu_vlmul;
  logic s3_in_uop_vpu_specVill;
  logic s3_in_uop_vpu_specVma;
  logic s3_in_uop_vpu_specVta;
  logic [1:0] s3_in_uop_vpu_specVsew;
  logic [2:0] s3_in_uop_vpu_specVlmul;
  logic s3_in_uop_vpu_vm;
  logic [7:0] s3_in_uop_vpu_vstart;
  logic [2:0] s3_in_uop_vpu_frm;
  logic s3_in_uop_vpu_fpu_isFpToVecInst;
  logic s3_in_uop_vpu_fpu_isFP32Instr;
  logic s3_in_uop_vpu_fpu_isFP64Instr;
  logic s3_in_uop_vpu_fpu_isReduction;
  logic s3_in_uop_vpu_fpu_isFoldTo1_2;
  logic s3_in_uop_vpu_fpu_isFoldTo1_4;
  logic s3_in_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0] s3_in_uop_vpu_vxrm;
  logic [6:0] s3_in_uop_vpu_vuopIdx;
  logic s3_in_uop_vpu_lastUop;
  logic [127:0] s3_in_uop_vpu_vmask;
  logic [7:0] s3_in_uop_vpu_vl;
  logic [2:0] s3_in_uop_vpu_nf;
  logic [1:0] s3_in_uop_vpu_veew;
  logic s3_in_uop_vpu_isReverse;
  logic s3_in_uop_vpu_isExt;
  logic s3_in_uop_vpu_isNarrow;
  logic s3_in_uop_vpu_isDstMask;
  logic s3_in_uop_vpu_isOpMask;
  logic s3_in_uop_vpu_isMove;
  logic s3_in_uop_vpu_isDependOldVd;
  logic s3_in_uop_vpu_isWritePartVd;
  logic s3_in_uop_vpu_isVleff;
  logic s3_in_uop_vlsInstr;
  logic s3_in_uop_wfflags;
  logic s3_in_uop_isMove;
  logic s3_in_uop_isDropAmocasSta;
  logic [6:0] s3_in_uop_uopIdx;
  logic s3_in_uop_isVset;
  logic s3_in_uop_firstUop;
  logic s3_in_uop_lastUop;
  logic [6:0] s3_in_uop_numUops;
  logic [6:0] s3_in_uop_numWB;
  logic [2:0] s3_in_uop_commitType;
  logic s3_in_uop_srcState_0;
  logic s3_in_uop_srcState_1;
  logic s3_in_uop_srcState_2;
  logic s3_in_uop_srcState_3;
  logic s3_in_uop_srcState_4;
  logic [1:0] s3_in_uop_srcLoadDependency_0_0;
  logic [1:0] s3_in_uop_srcLoadDependency_0_1;
  logic [1:0] s3_in_uop_srcLoadDependency_0_2;
  logic [1:0] s3_in_uop_srcLoadDependency_1_0;
  logic [1:0] s3_in_uop_srcLoadDependency_1_1;
  logic [1:0] s3_in_uop_srcLoadDependency_1_2;
  logic [1:0] s3_in_uop_srcLoadDependency_2_0;
  logic [1:0] s3_in_uop_srcLoadDependency_2_1;
  logic [1:0] s3_in_uop_srcLoadDependency_2_2;
  logic [1:0] s3_in_uop_srcLoadDependency_3_0;
  logic [1:0] s3_in_uop_srcLoadDependency_3_1;
  logic [1:0] s3_in_uop_srcLoadDependency_3_2;
  logic [1:0] s3_in_uop_srcLoadDependency_4_0;
  logic [1:0] s3_in_uop_srcLoadDependency_4_1;
  logic [1:0] s3_in_uop_srcLoadDependency_4_2;
  logic [7:0] s3_in_uop_psrc_0;
  logic [7:0] s3_in_uop_psrc_1;
  logic [7:0] s3_in_uop_psrc_2;
  logic [7:0] s3_in_uop_psrc_3;
  logic [7:0] s3_in_uop_psrc_4;
  logic [7:0] s3_in_uop_pdest;
  logic s3_in_uop_useRegCache_0;
  logic s3_in_uop_useRegCache_1;
  logic [4:0] s3_in_uop_regCacheIdx_0;
  logic [4:0] s3_in_uop_regCacheIdx_1;
  logic s3_in_uop_robIdx_flag;
  logic [7:0] s3_in_uop_robIdx_value;
  logic [2:0] s3_in_uop_instrSize;
  logic s3_in_uop_dirtyFs;
  logic s3_in_uop_dirtyVs;
  logic [3:0] s3_in_uop_traceBlockInPipe_itype;
  logic [3:0] s3_in_uop_traceBlockInPipe_iretire;
  logic s3_in_uop_traceBlockInPipe_ilastsize;
  logic s3_in_uop_eliminatedMove;
  logic s3_in_uop_snapshot;
  logic s3_in_uop_debugInfo_eliminatedMove;
  logic [63:0] s3_in_uop_debugInfo_renameTime;
  logic [63:0] s3_in_uop_debugInfo_dispatchTime;
  logic [63:0] s3_in_uop_debugInfo_enqRsTime;
  logic [63:0] s3_in_uop_debugInfo_selectTime;
  logic [63:0] s3_in_uop_debugInfo_issueTime;
  logic [63:0] s3_in_uop_debugInfo_writebackTime;
  logic [63:0] s3_in_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0] s3_in_uop_debugInfo_tlbFirstReqTime;
  logic [63:0] s3_in_uop_debugInfo_tlbRespTime;
  logic [55:0] s3_in_uop_debug_seqNum_seqNum;
  logic [7:0] s3_in_uop_debug_seqNum_uopIdx;
  logic s3_in_uop_storeSetHit;
  logic s3_in_uop_waitForRobIdx_flag;
  logic [7:0] s3_in_uop_waitForRobIdx_value;
  logic s3_in_uop_loadWaitBit;
  logic s3_in_uop_loadWaitStrict;
  logic [4:0] s3_in_uop_ssid;
  logic s3_in_uop_lqIdx_flag;
  logic [6:0] s3_in_uop_lqIdx_value;
  logic s3_in_uop_sqIdx_flag;
  logic [5:0] s3_in_uop_sqIdx_value;
  logic s3_in_uop_singleStep;
  logic s3_in_uop_replayInst;
  logic [34:0] s3_in_uop_debug_fuType;
  logic s3_in_uop_debug_sim_trig;
  logic [4:0] s3_in_uop_numLsElem;
  logic [49:0] s3_in_vaddr;
  logic [63:0] s3_in_fullva;
  logic s3_in_vaNeedExt;
  logic [47:0] s3_in_paddr;
  logic [63:0] s3_in_gpaddr;
  logic [15:0] s3_in_mask;
  logic [128:0] s3_in_data;
  logic s3_in_ptwBack;
  logic s3_in_nc;
  logic s3_in_mmio;
  logic s3_in_memBackTypeMM;
  logic s3_in_isHyper;
  logic s3_in_isForVSnonLeafPTE;
  logic s3_in_isPrefetch;
  logic s3_in_isvec;
  logic s3_in_is128bit;
  logic [7:0] s3_in_elemIdx;
  logic [2:0] s3_in_alignedType;
  logic [3:0] s3_in_mbIndex;
  logic [3:0] s3_in_reg_offset;
  logic [7:0] s3_in_elemIdxInsideVd;
  logic [15:0] s3_in_vecTriggerMask;
  logic s3_in_vecActive;
  logic s3_in_isLoadReplay;
  logic s3_in_hasROBEntry;
  logic s3_in_handledByMSHR;
  logic [6:0] s3_in_schedIndex;
  logic s3_in_isFrmMisAlignBuf;
  logic s3_in_isFinalSplit;
  logic s3_in_misalignWith16Byte;
  logic s3_in_misalignNeedWakeUp;
  logic [3:0] s3_in_rep_info_mshr_id;
  logic s3_in_rep_info_full_fwd;
  logic s3_in_rep_info_data_inv_sq_idx_flag;
  logic [5:0] s3_in_rep_info_data_inv_sq_idx_value;
  logic s3_in_rep_info_addr_inv_sq_idx_flag;
  logic [5:0] s3_in_rep_info_addr_inv_sq_idx_value;
  logic s3_in_rep_info_last_beat;
  logic s3_in_rep_info_cause_0;
  logic s3_in_rep_info_cause_1;
  logic s3_in_rep_info_cause_2;
  logic s3_in_rep_info_cause_3;
  logic s3_in_rep_info_cause_4;
  logic s3_in_rep_info_cause_6;
  logic s3_in_rep_info_cause_7;
  logic s3_in_rep_info_cause_8;
  logic s3_in_rep_info_cause_9;
  logic [3:0] s3_in_rep_info_tlb_id;
  logic s3_in_rep_info_tlb_full;
  always_ff @(posedge clock) begin
    if (s2_fire) begin
      s3_in_uop_instr <= s2_out.uop.instr;
      s3_in_uop_pc <= s2_out.uop.pc;
      s3_in_uop_foldpc <= s2_out.uop.foldpc;
      s3_in_uop_exceptionVec_0 <= s2_out.uop.exceptionVec[0];
      s3_in_uop_exceptionVec_1 <= s2_out.uop.exceptionVec[1];
      s3_in_uop_exceptionVec_2 <= s2_out.uop.exceptionVec[2];
      s3_in_uop_exceptionVec_3 <= s2_out.uop.exceptionVec[3];
      s3_in_uop_exceptionVec_4 <= s2_out.uop.exceptionVec[4];
      s3_in_uop_exceptionVec_5 <= s2_out.uop.exceptionVec[5];
      s3_in_uop_exceptionVec_6 <= s2_out.uop.exceptionVec[6];
      s3_in_uop_exceptionVec_7 <= s2_out.uop.exceptionVec[7];
      s3_in_uop_exceptionVec_8 <= s2_out.uop.exceptionVec[8];
      s3_in_uop_exceptionVec_9 <= s2_out.uop.exceptionVec[9];
      s3_in_uop_exceptionVec_10 <= s2_out.uop.exceptionVec[10];
      s3_in_uop_exceptionVec_11 <= s2_out.uop.exceptionVec[11];
      s3_in_uop_exceptionVec_12 <= s2_out.uop.exceptionVec[12];
      s3_in_uop_exceptionVec_13 <= s2_out.uop.exceptionVec[13];
      s3_in_uop_exceptionVec_14 <= s2_out.uop.exceptionVec[14];
      s3_in_uop_exceptionVec_15 <= s2_out.uop.exceptionVec[15];
      s3_in_uop_exceptionVec_16 <= s2_out.uop.exceptionVec[16];
      s3_in_uop_exceptionVec_17 <= s2_out.uop.exceptionVec[17];
      s3_in_uop_exceptionVec_18 <= s2_out.uop.exceptionVec[18];
      s3_in_uop_exceptionVec_19 <= s2_out.uop.exceptionVec[19];
      s3_in_uop_exceptionVec_20 <= s2_out.uop.exceptionVec[20];
      s3_in_uop_exceptionVec_21 <= s2_out.uop.exceptionVec[21];
      s3_in_uop_exceptionVec_22 <= s2_out.uop.exceptionVec[22];
      s3_in_uop_exceptionVec_23 <= s2_out.uop.exceptionVec[23];
      s3_in_uop_isFetchMalAddr <= s2_out.uop.isFetchMalAddr;
      s3_in_uop_hasException <= s2_out.uop.hasException;
      s3_in_uop_trigger <= s2_out.uop.trigger;
      s3_in_uop_preDecodeInfo_valid <= s2_out.uop.preDecodeInfo_valid;
      s3_in_uop_preDecodeInfo_isRVC <= s2_out.uop.preDecodeInfo_isRVC;
      s3_in_uop_preDecodeInfo_brType <= s2_out.uop.preDecodeInfo_brType;
      s3_in_uop_preDecodeInfo_isCall <= s2_out.uop.preDecodeInfo_isCall;
      s3_in_uop_preDecodeInfo_isRet <= s2_out.uop.preDecodeInfo_isRet;
      s3_in_uop_pred_taken <= s2_out.uop.pred_taken;
      s3_in_uop_crossPageIPFFix <= s2_out.uop.crossPageIPFFix;
      s3_in_uop_ftqPtr_flag <= s2_out.uop.ftqPtr_flag;
      s3_in_uop_ftqPtr_value <= s2_out.uop.ftqPtr_value;
      s3_in_uop_ftqOffset <= s2_out.uop.ftqOffset;
      s3_in_uop_satpFlushFirstFetchFault <= s2_out.uop.satpFlushFirstFetchFault;
      s3_in_uop_srcType_0 <= s2_out.uop.srcType_0;
      s3_in_uop_srcType_1 <= s2_out.uop.srcType_1;
      s3_in_uop_srcType_2 <= s2_out.uop.srcType_2;
      s3_in_uop_srcType_3 <= s2_out.uop.srcType_3;
      s3_in_uop_srcType_4 <= s2_out.uop.srcType_4;
      s3_in_uop_ldest <= s2_out.uop.ldest;
      s3_in_uop_fuType <= s2_out.uop.fuType;
      s3_in_uop_fuOpType <= s2_out.uop.fuOpType;
      s3_in_uop_rfWen <= s2_out.uop.rfWen;
      s3_in_uop_fpWen <= s2_out.uop.fpWen;
      s3_in_uop_vecWen <= s2_out.uop.vecWen;
      s3_in_uop_v0Wen <= s2_out.uop.v0Wen;
      s3_in_uop_vlWen <= s2_out.uop.vlWen;
      s3_in_uop_isXSTrap <= s2_out.uop.isXSTrap;
      s3_in_uop_waitForward <= s2_out.uop.waitForward;
      s3_in_uop_blockBackward <= s2_out.uop.blockBackward;
      s3_in_uop_canRobCompress <= s2_out.uop.canRobCompress;
      s3_in_uop_selImm <= s2_out.uop.selImm;
      s3_in_uop_imm <= s2_out.uop.imm;
      s3_in_uop_fpu_typeTagOut <= s2_out.uop.fpu_typeTagOut;
      s3_in_uop_fpu_wflags <= s2_out.uop.fpu_wflags;
      s3_in_uop_fpu_typ <= s2_out.uop.fpu_typ;
      s3_in_uop_fpu_fmt <= s2_out.uop.fpu_fmt;
      s3_in_uop_fpu_rm <= s2_out.uop.fpu_rm;
      s3_in_uop_vpu_vill <= s2_out.uop.vpu_vill;
      s3_in_uop_vpu_vma <= s2_out.uop.vpu_vma;
      s3_in_uop_vpu_vta <= s2_out.uop.vpu_vta;
      s3_in_uop_vpu_vsew <= s2_out.uop.vpu_vsew;
      s3_in_uop_vpu_vlmul <= s2_out.uop.vpu_vlmul;
      s3_in_uop_vpu_specVill <= s2_out.uop.vpu_specVill;
      s3_in_uop_vpu_specVma <= s2_out.uop.vpu_specVma;
      s3_in_uop_vpu_specVta <= s2_out.uop.vpu_specVta;
      s3_in_uop_vpu_specVsew <= s2_out.uop.vpu_specVsew;
      s3_in_uop_vpu_specVlmul <= s2_out.uop.vpu_specVlmul;
      s3_in_uop_vpu_vm <= s2_out.uop.vpu_vm;
      s3_in_uop_vpu_vstart <= s2_out.uop.vpu_vstart;
      s3_in_uop_vpu_frm <= s2_out.uop.vpu_frm;
      s3_in_uop_vpu_fpu_isFpToVecInst <= s2_out.uop.vpu_fpu_isFpToVecInst;
      s3_in_uop_vpu_fpu_isFP32Instr <= s2_out.uop.vpu_fpu_isFP32Instr;
      s3_in_uop_vpu_fpu_isFP64Instr <= s2_out.uop.vpu_fpu_isFP64Instr;
      s3_in_uop_vpu_fpu_isReduction <= s2_out.uop.vpu_fpu_isReduction;
      s3_in_uop_vpu_fpu_isFoldTo1_2 <= s2_out.uop.vpu_fpu_isFoldTo1_2;
      s3_in_uop_vpu_fpu_isFoldTo1_4 <= s2_out.uop.vpu_fpu_isFoldTo1_4;
      s3_in_uop_vpu_fpu_isFoldTo1_8 <= s2_out.uop.vpu_fpu_isFoldTo1_8;
      s3_in_uop_vpu_vxrm <= s2_out.uop.vpu_vxrm;
      s3_in_uop_vpu_vuopIdx <= s2_out.uop.vpu_vuopIdx;
      s3_in_uop_vpu_lastUop <= s2_out.uop.vpu_lastUop;
      s3_in_uop_vpu_vmask <= s2_out.uop.vpu_vmask;
      s3_in_uop_vpu_vl <= s2_out.uop.vpu_vl;
      s3_in_uop_vpu_nf <= s2_out.uop.vpu_nf;
      s3_in_uop_vpu_veew <= s2_out.uop.vpu_veew;
      s3_in_uop_vpu_isReverse <= s2_out.uop.vpu_isReverse;
      s3_in_uop_vpu_isExt <= s2_out.uop.vpu_isExt;
      s3_in_uop_vpu_isNarrow <= s2_out.uop.vpu_isNarrow;
      s3_in_uop_vpu_isDstMask <= s2_out.uop.vpu_isDstMask;
      s3_in_uop_vpu_isOpMask <= s2_out.uop.vpu_isOpMask;
      s3_in_uop_vpu_isMove <= s2_out.uop.vpu_isMove;
      s3_in_uop_vpu_isDependOldVd <= s2_out.uop.vpu_isDependOldVd;
      s3_in_uop_vpu_isWritePartVd <= s2_out.uop.vpu_isWritePartVd;
      s3_in_uop_vpu_isVleff <= s2_out.uop.vpu_isVleff;
      s3_in_uop_vlsInstr <= s2_out.uop.vlsInstr;
      s3_in_uop_wfflags <= s2_out.uop.wfflags;
      s3_in_uop_isMove <= s2_out.uop.isMove;
      s3_in_uop_isDropAmocasSta <= s2_out.uop.isDropAmocasSta;
      s3_in_uop_uopIdx <= s2_out.uop.uopIdx;
      s3_in_uop_isVset <= s2_out.uop.isVset;
      s3_in_uop_firstUop <= s2_out.uop.firstUop;
      s3_in_uop_lastUop <= s2_out.uop.lastUop;
      s3_in_uop_numUops <= s2_out.uop.numUops;
      s3_in_uop_numWB <= s2_out.uop.numWB;
      s3_in_uop_commitType <= s2_out.uop.commitType;
      s3_in_uop_srcState_0 <= s2_out.uop.srcState_0;
      s3_in_uop_srcState_1 <= s2_out.uop.srcState_1;
      s3_in_uop_srcState_2 <= s2_out.uop.srcState_2;
      s3_in_uop_srcState_3 <= s2_out.uop.srcState_3;
      s3_in_uop_srcState_4 <= s2_out.uop.srcState_4;
      s3_in_uop_srcLoadDependency_0_0 <= s2_out.uop.srcLoadDependency_0_0;
      s3_in_uop_srcLoadDependency_0_1 <= s2_out.uop.srcLoadDependency_0_1;
      s3_in_uop_srcLoadDependency_0_2 <= s2_out.uop.srcLoadDependency_0_2;
      s3_in_uop_srcLoadDependency_1_0 <= s2_out.uop.srcLoadDependency_1_0;
      s3_in_uop_srcLoadDependency_1_1 <= s2_out.uop.srcLoadDependency_1_1;
      s3_in_uop_srcLoadDependency_1_2 <= s2_out.uop.srcLoadDependency_1_2;
      s3_in_uop_srcLoadDependency_2_0 <= s2_out.uop.srcLoadDependency_2_0;
      s3_in_uop_srcLoadDependency_2_1 <= s2_out.uop.srcLoadDependency_2_1;
      s3_in_uop_srcLoadDependency_2_2 <= s2_out.uop.srcLoadDependency_2_2;
      s3_in_uop_srcLoadDependency_3_0 <= s2_out.uop.srcLoadDependency_3_0;
      s3_in_uop_srcLoadDependency_3_1 <= s2_out.uop.srcLoadDependency_3_1;
      s3_in_uop_srcLoadDependency_3_2 <= s2_out.uop.srcLoadDependency_3_2;
      s3_in_uop_srcLoadDependency_4_0 <= s2_out.uop.srcLoadDependency_4_0;
      s3_in_uop_srcLoadDependency_4_1 <= s2_out.uop.srcLoadDependency_4_1;
      s3_in_uop_srcLoadDependency_4_2 <= s2_out.uop.srcLoadDependency_4_2;
      s3_in_uop_psrc_0 <= s2_out.uop.psrc_0;
      s3_in_uop_psrc_1 <= s2_out.uop.psrc_1;
      s3_in_uop_psrc_2 <= s2_out.uop.psrc_2;
      s3_in_uop_psrc_3 <= s2_out.uop.psrc_3;
      s3_in_uop_psrc_4 <= s2_out.uop.psrc_4;
      s3_in_uop_pdest <= s2_out.uop.pdest;
      s3_in_uop_useRegCache_0 <= s2_out.uop.useRegCache_0;
      s3_in_uop_useRegCache_1 <= s2_out.uop.useRegCache_1;
      s3_in_uop_regCacheIdx_0 <= s2_out.uop.regCacheIdx_0;
      s3_in_uop_regCacheIdx_1 <= s2_out.uop.regCacheIdx_1;
      s3_in_uop_robIdx_flag <= s2_out.uop.robIdx_flag;
      s3_in_uop_robIdx_value <= s2_out.uop.robIdx_value;
      s3_in_uop_instrSize <= s2_out.uop.instrSize;
      s3_in_uop_dirtyFs <= s2_out.uop.dirtyFs;
      s3_in_uop_dirtyVs <= s2_out.uop.dirtyVs;
      s3_in_uop_traceBlockInPipe_itype <= s2_out.uop.traceBlockInPipe_itype;
      s3_in_uop_traceBlockInPipe_iretire <= s2_out.uop.traceBlockInPipe_iretire;
      s3_in_uop_traceBlockInPipe_ilastsize <= s2_out.uop.traceBlockInPipe_ilastsize;
      s3_in_uop_eliminatedMove <= s2_out.uop.eliminatedMove;
      s3_in_uop_snapshot <= s2_out.uop.snapshot;
      s3_in_uop_debugInfo_eliminatedMove <= s2_out.uop.debugInfo_eliminatedMove;
      s3_in_uop_debugInfo_renameTime <= s2_out.uop.debugInfo_renameTime;
      s3_in_uop_debugInfo_dispatchTime <= s2_out.uop.debugInfo_dispatchTime;
      s3_in_uop_debugInfo_enqRsTime <= s2_out.uop.debugInfo_enqRsTime;
      s3_in_uop_debugInfo_selectTime <= s2_out.uop.debugInfo_selectTime;
      s3_in_uop_debugInfo_issueTime <= s2_out.uop.debugInfo_issueTime;
      s3_in_uop_debugInfo_writebackTime <= s2_out.uop.debugInfo_writebackTime;
      s3_in_uop_debugInfo_runahead_checkpoint_id <= s2_out.uop.debugInfo_runahead_checkpoint_id;
      s3_in_uop_debugInfo_tlbFirstReqTime <= s2_out.uop.debugInfo_tlbFirstReqTime;
      s3_in_uop_debugInfo_tlbRespTime <= s2_out.uop.debugInfo_tlbRespTime;
      s3_in_uop_debug_seqNum_seqNum <= s2_out.uop.debug_seqNum_seqNum;
      s3_in_uop_debug_seqNum_uopIdx <= s2_out.uop.debug_seqNum_uopIdx;
      s3_in_uop_storeSetHit <= s2_out.uop.storeSetHit;
      s3_in_uop_waitForRobIdx_flag <= s2_out.uop.waitForRobIdx_flag;
      s3_in_uop_waitForRobIdx_value <= s2_out.uop.waitForRobIdx_value;
      s3_in_uop_loadWaitBit <= s2_out.uop.loadWaitBit;
      s3_in_uop_loadWaitStrict <= s2_out.uop.loadWaitStrict;
      s3_in_uop_ssid <= s2_out.uop.ssid;
      s3_in_uop_lqIdx_flag <= s2_out.uop.lqIdx_flag;
      s3_in_uop_lqIdx_value <= s2_out.uop.lqIdx_value;
      s3_in_uop_sqIdx_flag <= s2_out.uop.sqIdx_flag;
      s3_in_uop_sqIdx_value <= s2_out.uop.sqIdx_value;
      s3_in_uop_singleStep <= s2_out.uop.singleStep;
      s3_in_uop_replayInst <= s2_out.uop.replayInst;
      s3_in_uop_debug_fuType <= s2_out.uop.debug_fuType;
      s3_in_uop_debug_sim_trig <= s2_out.uop.debug_sim_trig;
      s3_in_uop_numLsElem <= s2_out.uop.numLsElem;
      s3_in_vaddr <= s2_out.vaddr;
      s3_in_fullva <= s2_out.fullva;
      s3_in_vaNeedExt <= s2_out.vaNeedExt;
      s3_in_paddr <= s2_out.paddr;
      s3_in_gpaddr <= s2_out.gpaddr;
      s3_in_mask <= s2_out.mask;
      s3_in_data <= s2_out.data;
      s3_in_ptwBack <= s2_out.ptwBack;
      s3_in_nc <= s2_out.nc;
      s3_in_mmio <= s2_out.mmio;
      s3_in_memBackTypeMM <= s2_out.memBackTypeMM;
      s3_in_isHyper <= s2_out.isHyper;
      s3_in_isForVSnonLeafPTE <= s2_out.isForVSnonLeafPTE;
      s3_in_isPrefetch <= s2_out.isPrefetch;
      s3_in_isvec <= s2_out.isvec;
      s3_in_is128bit <= s2_out.is128bit;
      s3_in_elemIdx <= s2_out.elemIdx;
      s3_in_alignedType <= s2_out.alignedType;
      s3_in_mbIndex <= s2_out.mbIndex;
      s3_in_reg_offset <= s2_out.reg_offset;
      s3_in_elemIdxInsideVd <= s2_out.elemIdxInsideVd;
      s3_in_vecTriggerMask <= s2_out.vecTriggerMask;
      s3_in_vecActive <= s2_out.vecActive;
      s3_in_isLoadReplay <= s2_out.isLoadReplay;
      s3_in_hasROBEntry <= s2_out.hasROBEntry;
      s3_in_handledByMSHR <= s2_out.handledByMSHR;
      s3_in_schedIndex <= s2_out.schedIndex;
      s3_in_isFrmMisAlignBuf <= s2_out.isFrmMisAlignBuf;
      s3_in_isFinalSplit <= s2_out.isFinalSplit;
      s3_in_misalignWith16Byte <= s2_out.misalignWith16Byte;
      s3_in_misalignNeedWakeUp <= s2_out.misalignNeedWakeUp;
      s3_in_rep_info_mshr_id <= s2_out.rep_info_mshr_id;
      s3_in_rep_info_full_fwd <= s2_out.rep_info_full_fwd;
      s3_in_rep_info_data_inv_sq_idx_flag <= s2_out.rep_info_data_inv_sq_idx_flag;
      s3_in_rep_info_data_inv_sq_idx_value <= s2_out.rep_info_data_inv_sq_idx_value;
      s3_in_rep_info_addr_inv_sq_idx_flag <= s2_out.rep_info_addr_inv_sq_idx_flag;
      s3_in_rep_info_addr_inv_sq_idx_value <= s2_out.rep_info_addr_inv_sq_idx_value;
      s3_in_rep_info_last_beat <= s2_out.rep_info_last_beat;
      s3_in_rep_info_cause_0 <= s2_out.rep_info_cause[0];
      s3_in_rep_info_cause_1 <= s2_out.rep_info_cause[1];
      s3_in_rep_info_cause_2 <= s2_out.rep_info_cause[2];
      s3_in_rep_info_cause_3 <= s2_out.rep_info_cause[3];
      s3_in_rep_info_cause_4 <= s2_out.rep_info_cause[4];
      s3_in_rep_info_cause_6 <= s2_out.rep_info_cause[6];
      s3_in_rep_info_cause_7 <= s2_out.rep_info_cause[7];
      s3_in_rep_info_cause_8 <= s2_out.rep_info_cause[8];
      s3_in_rep_info_cause_9 <= s2_out.rep_info_cause[9];
      s3_in_rep_info_tlb_id <= s2_out.rep_info_tlb_id;
      s3_in_rep_info_tlb_full <= s2_out.rep_info_tlb_full;
    end
  end
  // 读回成 struct；golden 没留下的字段（DCE 掉 / 下游不用）恒 0
  always_comb begin
    s3_in = '0;
    s3_in.uop.instr = s3_in_uop_instr;
    s3_in.uop.pc = s3_in_uop_pc;
    s3_in.uop.foldpc = s3_in_uop_foldpc;
    s3_in.uop.exceptionVec[0] = s3_in_uop_exceptionVec_0;
    s3_in.uop.exceptionVec[1] = s3_in_uop_exceptionVec_1;
    s3_in.uop.exceptionVec[2] = s3_in_uop_exceptionVec_2;
    s3_in.uop.exceptionVec[3] = s3_in_uop_exceptionVec_3;
    s3_in.uop.exceptionVec[4] = s3_in_uop_exceptionVec_4;
    s3_in.uop.exceptionVec[5] = s3_in_uop_exceptionVec_5;
    s3_in.uop.exceptionVec[6] = s3_in_uop_exceptionVec_6;
    s3_in.uop.exceptionVec[7] = s3_in_uop_exceptionVec_7;
    s3_in.uop.exceptionVec[8] = s3_in_uop_exceptionVec_8;
    s3_in.uop.exceptionVec[9] = s3_in_uop_exceptionVec_9;
    s3_in.uop.exceptionVec[10] = s3_in_uop_exceptionVec_10;
    s3_in.uop.exceptionVec[11] = s3_in_uop_exceptionVec_11;
    s3_in.uop.exceptionVec[12] = s3_in_uop_exceptionVec_12;
    s3_in.uop.exceptionVec[13] = s3_in_uop_exceptionVec_13;
    s3_in.uop.exceptionVec[14] = s3_in_uop_exceptionVec_14;
    s3_in.uop.exceptionVec[15] = s3_in_uop_exceptionVec_15;
    s3_in.uop.exceptionVec[16] = s3_in_uop_exceptionVec_16;
    s3_in.uop.exceptionVec[17] = s3_in_uop_exceptionVec_17;
    s3_in.uop.exceptionVec[18] = s3_in_uop_exceptionVec_18;
    s3_in.uop.exceptionVec[19] = s3_in_uop_exceptionVec_19;
    s3_in.uop.exceptionVec[20] = s3_in_uop_exceptionVec_20;
    s3_in.uop.exceptionVec[21] = s3_in_uop_exceptionVec_21;
    s3_in.uop.exceptionVec[22] = s3_in_uop_exceptionVec_22;
    s3_in.uop.exceptionVec[23] = s3_in_uop_exceptionVec_23;
    s3_in.uop.isFetchMalAddr = s3_in_uop_isFetchMalAddr;
    s3_in.uop.hasException = s3_in_uop_hasException;
    s3_in.uop.trigger = s3_in_uop_trigger;
    s3_in.uop.preDecodeInfo_valid = s3_in_uop_preDecodeInfo_valid;
    s3_in.uop.preDecodeInfo_isRVC = s3_in_uop_preDecodeInfo_isRVC;
    s3_in.uop.preDecodeInfo_brType = s3_in_uop_preDecodeInfo_brType;
    s3_in.uop.preDecodeInfo_isCall = s3_in_uop_preDecodeInfo_isCall;
    s3_in.uop.preDecodeInfo_isRet = s3_in_uop_preDecodeInfo_isRet;
    s3_in.uop.pred_taken = s3_in_uop_pred_taken;
    s3_in.uop.crossPageIPFFix = s3_in_uop_crossPageIPFFix;
    s3_in.uop.ftqPtr_flag = s3_in_uop_ftqPtr_flag;
    s3_in.uop.ftqPtr_value = s3_in_uop_ftqPtr_value;
    s3_in.uop.ftqOffset = s3_in_uop_ftqOffset;
    s3_in.uop.satpFlushFirstFetchFault = s3_in_uop_satpFlushFirstFetchFault;
    s3_in.uop.srcType_0 = s3_in_uop_srcType_0;
    s3_in.uop.srcType_1 = s3_in_uop_srcType_1;
    s3_in.uop.srcType_2 = s3_in_uop_srcType_2;
    s3_in.uop.srcType_3 = s3_in_uop_srcType_3;
    s3_in.uop.srcType_4 = s3_in_uop_srcType_4;
    s3_in.uop.ldest = s3_in_uop_ldest;
    s3_in.uop.fuType = s3_in_uop_fuType;
    s3_in.uop.fuOpType = s3_in_uop_fuOpType;
    s3_in.uop.rfWen = s3_in_uop_rfWen;
    s3_in.uop.fpWen = s3_in_uop_fpWen;
    s3_in.uop.vecWen = s3_in_uop_vecWen;
    s3_in.uop.v0Wen = s3_in_uop_v0Wen;
    s3_in.uop.vlWen = s3_in_uop_vlWen;
    s3_in.uop.isXSTrap = s3_in_uop_isXSTrap;
    s3_in.uop.waitForward = s3_in_uop_waitForward;
    s3_in.uop.blockBackward = s3_in_uop_blockBackward;
    s3_in.uop.canRobCompress = s3_in_uop_canRobCompress;
    s3_in.uop.selImm = s3_in_uop_selImm;
    s3_in.uop.imm = s3_in_uop_imm;
    s3_in.uop.fpu_typeTagOut = s3_in_uop_fpu_typeTagOut;
    s3_in.uop.fpu_wflags = s3_in_uop_fpu_wflags;
    s3_in.uop.fpu_typ = s3_in_uop_fpu_typ;
    s3_in.uop.fpu_fmt = s3_in_uop_fpu_fmt;
    s3_in.uop.fpu_rm = s3_in_uop_fpu_rm;
    s3_in.uop.vpu_vill = s3_in_uop_vpu_vill;
    s3_in.uop.vpu_vma = s3_in_uop_vpu_vma;
    s3_in.uop.vpu_vta = s3_in_uop_vpu_vta;
    s3_in.uop.vpu_vsew = s3_in_uop_vpu_vsew;
    s3_in.uop.vpu_vlmul = s3_in_uop_vpu_vlmul;
    s3_in.uop.vpu_specVill = s3_in_uop_vpu_specVill;
    s3_in.uop.vpu_specVma = s3_in_uop_vpu_specVma;
    s3_in.uop.vpu_specVta = s3_in_uop_vpu_specVta;
    s3_in.uop.vpu_specVsew = s3_in_uop_vpu_specVsew;
    s3_in.uop.vpu_specVlmul = s3_in_uop_vpu_specVlmul;
    s3_in.uop.vpu_vm = s3_in_uop_vpu_vm;
    s3_in.uop.vpu_vstart = s3_in_uop_vpu_vstart;
    s3_in.uop.vpu_frm = s3_in_uop_vpu_frm;
    s3_in.uop.vpu_fpu_isFpToVecInst = s3_in_uop_vpu_fpu_isFpToVecInst;
    s3_in.uop.vpu_fpu_isFP32Instr = s3_in_uop_vpu_fpu_isFP32Instr;
    s3_in.uop.vpu_fpu_isFP64Instr = s3_in_uop_vpu_fpu_isFP64Instr;
    s3_in.uop.vpu_fpu_isReduction = s3_in_uop_vpu_fpu_isReduction;
    s3_in.uop.vpu_fpu_isFoldTo1_2 = s3_in_uop_vpu_fpu_isFoldTo1_2;
    s3_in.uop.vpu_fpu_isFoldTo1_4 = s3_in_uop_vpu_fpu_isFoldTo1_4;
    s3_in.uop.vpu_fpu_isFoldTo1_8 = s3_in_uop_vpu_fpu_isFoldTo1_8;
    s3_in.uop.vpu_vxrm = s3_in_uop_vpu_vxrm;
    s3_in.uop.vpu_vuopIdx = s3_in_uop_vpu_vuopIdx;
    s3_in.uop.vpu_lastUop = s3_in_uop_vpu_lastUop;
    s3_in.uop.vpu_vmask = s3_in_uop_vpu_vmask;
    s3_in.uop.vpu_vl = s3_in_uop_vpu_vl;
    s3_in.uop.vpu_nf = s3_in_uop_vpu_nf;
    s3_in.uop.vpu_veew = s3_in_uop_vpu_veew;
    s3_in.uop.vpu_isReverse = s3_in_uop_vpu_isReverse;
    s3_in.uop.vpu_isExt = s3_in_uop_vpu_isExt;
    s3_in.uop.vpu_isNarrow = s3_in_uop_vpu_isNarrow;
    s3_in.uop.vpu_isDstMask = s3_in_uop_vpu_isDstMask;
    s3_in.uop.vpu_isOpMask = s3_in_uop_vpu_isOpMask;
    s3_in.uop.vpu_isMove = s3_in_uop_vpu_isMove;
    s3_in.uop.vpu_isDependOldVd = s3_in_uop_vpu_isDependOldVd;
    s3_in.uop.vpu_isWritePartVd = s3_in_uop_vpu_isWritePartVd;
    s3_in.uop.vpu_isVleff = s3_in_uop_vpu_isVleff;
    s3_in.uop.vlsInstr = s3_in_uop_vlsInstr;
    s3_in.uop.wfflags = s3_in_uop_wfflags;
    s3_in.uop.isMove = s3_in_uop_isMove;
    s3_in.uop.isDropAmocasSta = s3_in_uop_isDropAmocasSta;
    s3_in.uop.uopIdx = s3_in_uop_uopIdx;
    s3_in.uop.isVset = s3_in_uop_isVset;
    s3_in.uop.firstUop = s3_in_uop_firstUop;
    s3_in.uop.lastUop = s3_in_uop_lastUop;
    s3_in.uop.numUops = s3_in_uop_numUops;
    s3_in.uop.numWB = s3_in_uop_numWB;
    s3_in.uop.commitType = s3_in_uop_commitType;
    s3_in.uop.srcState_0 = s3_in_uop_srcState_0;
    s3_in.uop.srcState_1 = s3_in_uop_srcState_1;
    s3_in.uop.srcState_2 = s3_in_uop_srcState_2;
    s3_in.uop.srcState_3 = s3_in_uop_srcState_3;
    s3_in.uop.srcState_4 = s3_in_uop_srcState_4;
    s3_in.uop.srcLoadDependency_0_0 = s3_in_uop_srcLoadDependency_0_0;
    s3_in.uop.srcLoadDependency_0_1 = s3_in_uop_srcLoadDependency_0_1;
    s3_in.uop.srcLoadDependency_0_2 = s3_in_uop_srcLoadDependency_0_2;
    s3_in.uop.srcLoadDependency_1_0 = s3_in_uop_srcLoadDependency_1_0;
    s3_in.uop.srcLoadDependency_1_1 = s3_in_uop_srcLoadDependency_1_1;
    s3_in.uop.srcLoadDependency_1_2 = s3_in_uop_srcLoadDependency_1_2;
    s3_in.uop.srcLoadDependency_2_0 = s3_in_uop_srcLoadDependency_2_0;
    s3_in.uop.srcLoadDependency_2_1 = s3_in_uop_srcLoadDependency_2_1;
    s3_in.uop.srcLoadDependency_2_2 = s3_in_uop_srcLoadDependency_2_2;
    s3_in.uop.srcLoadDependency_3_0 = s3_in_uop_srcLoadDependency_3_0;
    s3_in.uop.srcLoadDependency_3_1 = s3_in_uop_srcLoadDependency_3_1;
    s3_in.uop.srcLoadDependency_3_2 = s3_in_uop_srcLoadDependency_3_2;
    s3_in.uop.srcLoadDependency_4_0 = s3_in_uop_srcLoadDependency_4_0;
    s3_in.uop.srcLoadDependency_4_1 = s3_in_uop_srcLoadDependency_4_1;
    s3_in.uop.srcLoadDependency_4_2 = s3_in_uop_srcLoadDependency_4_2;
    s3_in.uop.psrc_0 = s3_in_uop_psrc_0;
    s3_in.uop.psrc_1 = s3_in_uop_psrc_1;
    s3_in.uop.psrc_2 = s3_in_uop_psrc_2;
    s3_in.uop.psrc_3 = s3_in_uop_psrc_3;
    s3_in.uop.psrc_4 = s3_in_uop_psrc_4;
    s3_in.uop.pdest = s3_in_uop_pdest;
    s3_in.uop.useRegCache_0 = s3_in_uop_useRegCache_0;
    s3_in.uop.useRegCache_1 = s3_in_uop_useRegCache_1;
    s3_in.uop.regCacheIdx_0 = s3_in_uop_regCacheIdx_0;
    s3_in.uop.regCacheIdx_1 = s3_in_uop_regCacheIdx_1;
    s3_in.uop.robIdx_flag = s3_in_uop_robIdx_flag;
    s3_in.uop.robIdx_value = s3_in_uop_robIdx_value;
    s3_in.uop.instrSize = s3_in_uop_instrSize;
    s3_in.uop.dirtyFs = s3_in_uop_dirtyFs;
    s3_in.uop.dirtyVs = s3_in_uop_dirtyVs;
    s3_in.uop.traceBlockInPipe_itype = s3_in_uop_traceBlockInPipe_itype;
    s3_in.uop.traceBlockInPipe_iretire = s3_in_uop_traceBlockInPipe_iretire;
    s3_in.uop.traceBlockInPipe_ilastsize = s3_in_uop_traceBlockInPipe_ilastsize;
    s3_in.uop.eliminatedMove = s3_in_uop_eliminatedMove;
    s3_in.uop.snapshot = s3_in_uop_snapshot;
    s3_in.uop.debugInfo_eliminatedMove = s3_in_uop_debugInfo_eliminatedMove;
    s3_in.uop.debugInfo_renameTime = s3_in_uop_debugInfo_renameTime;
    s3_in.uop.debugInfo_dispatchTime = s3_in_uop_debugInfo_dispatchTime;
    s3_in.uop.debugInfo_enqRsTime = s3_in_uop_debugInfo_enqRsTime;
    s3_in.uop.debugInfo_selectTime = s3_in_uop_debugInfo_selectTime;
    s3_in.uop.debugInfo_issueTime = s3_in_uop_debugInfo_issueTime;
    s3_in.uop.debugInfo_writebackTime = s3_in_uop_debugInfo_writebackTime;
    s3_in.uop.debugInfo_runahead_checkpoint_id = s3_in_uop_debugInfo_runahead_checkpoint_id;
    s3_in.uop.debugInfo_tlbFirstReqTime = s3_in_uop_debugInfo_tlbFirstReqTime;
    s3_in.uop.debugInfo_tlbRespTime = s3_in_uop_debugInfo_tlbRespTime;
    s3_in.uop.debug_seqNum_seqNum = s3_in_uop_debug_seqNum_seqNum;
    s3_in.uop.debug_seqNum_uopIdx = s3_in_uop_debug_seqNum_uopIdx;
    s3_in.uop.storeSetHit = s3_in_uop_storeSetHit;
    s3_in.uop.waitForRobIdx_flag = s3_in_uop_waitForRobIdx_flag;
    s3_in.uop.waitForRobIdx_value = s3_in_uop_waitForRobIdx_value;
    s3_in.uop.loadWaitBit = s3_in_uop_loadWaitBit;
    s3_in.uop.loadWaitStrict = s3_in_uop_loadWaitStrict;
    s3_in.uop.ssid = s3_in_uop_ssid;
    s3_in.uop.lqIdx_flag = s3_in_uop_lqIdx_flag;
    s3_in.uop.lqIdx_value = s3_in_uop_lqIdx_value;
    s3_in.uop.sqIdx_flag = s3_in_uop_sqIdx_flag;
    s3_in.uop.sqIdx_value = s3_in_uop_sqIdx_value;
    s3_in.uop.singleStep = s3_in_uop_singleStep;
    s3_in.uop.replayInst = s3_in_uop_replayInst;
    s3_in.uop.debug_fuType = s3_in_uop_debug_fuType;
    s3_in.uop.debug_sim_trig = s3_in_uop_debug_sim_trig;
    s3_in.uop.numLsElem = s3_in_uop_numLsElem;
    s3_in.vaddr = s3_in_vaddr;
    s3_in.fullva = s3_in_fullva;
    s3_in.vaNeedExt = s3_in_vaNeedExt;
    s3_in.paddr = s3_in_paddr;
    s3_in.gpaddr = s3_in_gpaddr;
    s3_in.mask = s3_in_mask;
    s3_in.data = s3_in_data;
    s3_in.ptwBack = s3_in_ptwBack;
    s3_in.nc = s3_in_nc;
    s3_in.mmio = s3_in_mmio;
    s3_in.memBackTypeMM = s3_in_memBackTypeMM;
    s3_in.isHyper = s3_in_isHyper;
    s3_in.isForVSnonLeafPTE = s3_in_isForVSnonLeafPTE;
    s3_in.isPrefetch = s3_in_isPrefetch;
    s3_in.isvec = s3_in_isvec;
    s3_in.is128bit = s3_in_is128bit;
    s3_in.elemIdx = s3_in_elemIdx;
    s3_in.alignedType = s3_in_alignedType;
    s3_in.mbIndex = s3_in_mbIndex;
    s3_in.reg_offset = s3_in_reg_offset;
    s3_in.elemIdxInsideVd = s3_in_elemIdxInsideVd;
    s3_in.vecTriggerMask = s3_in_vecTriggerMask;
    s3_in.vecActive = s3_in_vecActive;
    s3_in.isLoadReplay = s3_in_isLoadReplay;
    s3_in.hasROBEntry = s3_in_hasROBEntry;
    s3_in.handledByMSHR = s3_in_handledByMSHR;
    s3_in.schedIndex = s3_in_schedIndex;
    s3_in.isFrmMisAlignBuf = s3_in_isFrmMisAlignBuf;
    s3_in.isFinalSplit = s3_in_isFinalSplit;
    s3_in.misalignWith16Byte = s3_in_misalignWith16Byte;
    s3_in.misalignNeedWakeUp = s3_in_misalignNeedWakeUp;
    s3_in.rep_info_mshr_id = s3_in_rep_info_mshr_id;
    s3_in.rep_info_full_fwd = s3_in_rep_info_full_fwd;
    s3_in.rep_info_data_inv_sq_idx_flag = s3_in_rep_info_data_inv_sq_idx_flag;
    s3_in.rep_info_data_inv_sq_idx_value = s3_in_rep_info_data_inv_sq_idx_value;
    s3_in.rep_info_addr_inv_sq_idx_flag = s3_in_rep_info_addr_inv_sq_idx_flag;
    s3_in.rep_info_addr_inv_sq_idx_value = s3_in_rep_info_addr_inv_sq_idx_value;
    s3_in.rep_info_last_beat = s3_in_rep_info_last_beat;
    s3_in.rep_info_cause[0] = s3_in_rep_info_cause_0;
    s3_in.rep_info_cause[1] = s3_in_rep_info_cause_1;
    s3_in.rep_info_cause[2] = s3_in_rep_info_cause_2;
    s3_in.rep_info_cause[3] = s3_in_rep_info_cause_3;
    s3_in.rep_info_cause[4] = s3_in_rep_info_cause_4;
    s3_in.rep_info_cause[6] = s3_in_rep_info_cause_6;
    s3_in.rep_info_cause[7] = s3_in_rep_info_cause_7;
    s3_in.rep_info_cause[8] = s3_in_rep_info_cause_8;
    s3_in.rep_info_cause[9] = s3_in_rep_info_cause_9;
    s3_in.rep_info_tlb_id = s3_in_rep_info_tlb_id;
    s3_in.rep_info_tlb_full = s3_in_rep_info_tlb_full;
  end

  // ---- MMIO 写回包第 1 拍：golden 留下的 38 个字段 ----
  logic s2_mmio_req_bits_REG_uop_exceptionVec_3;
  logic s2_mmio_req_bits_REG_uop_exceptionVec_4;
  logic s2_mmio_req_bits_REG_uop_exceptionVec_5;
  logic s2_mmio_req_bits_REG_uop_exceptionVec_13;
  logic s2_mmio_req_bits_REG_uop_exceptionVec_19;
  logic s2_mmio_req_bits_REG_uop_exceptionVec_21;
  logic [3:0] s2_mmio_req_bits_REG_uop_trigger;
  logic s2_mmio_req_bits_REG_uop_preDecodeInfo_valid;
  logic s2_mmio_req_bits_REG_uop_preDecodeInfo_isRVC;
  logic [1:0] s2_mmio_req_bits_REG_uop_preDecodeInfo_brType;
  logic s2_mmio_req_bits_REG_uop_preDecodeInfo_isCall;
  logic s2_mmio_req_bits_REG_uop_preDecodeInfo_isRet;
  logic s2_mmio_req_bits_REG_uop_rfWen;
  logic s2_mmio_req_bits_REG_uop_fpWen;
  logic s2_mmio_req_bits_REG_uop_flushPipe;
  logic [7:0] s2_mmio_req_bits_REG_uop_pdest;
  logic s2_mmio_req_bits_REG_uop_robIdx_flag;
  logic [7:0] s2_mmio_req_bits_REG_uop_robIdx_value;
  logic s2_mmio_req_bits_REG_uop_debugInfo_eliminatedMove;
  logic [63:0] s2_mmio_req_bits_REG_uop_debugInfo_renameTime;
  logic [63:0] s2_mmio_req_bits_REG_uop_debugInfo_dispatchTime;
  logic [63:0] s2_mmio_req_bits_REG_uop_debugInfo_enqRsTime;
  logic [63:0] s2_mmio_req_bits_REG_uop_debugInfo_selectTime;
  logic [63:0] s2_mmio_req_bits_REG_uop_debugInfo_issueTime;
  logic [63:0] s2_mmio_req_bits_REG_uop_debugInfo_writebackTime;
  logic [63:0] s2_mmio_req_bits_REG_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0] s2_mmio_req_bits_REG_uop_debugInfo_tlbFirstReqTime;
  logic [63:0] s2_mmio_req_bits_REG_uop_debugInfo_tlbRespTime;
  logic [55:0] s2_mmio_req_bits_REG_uop_debug_seqNum_seqNum;
  logic [7:0] s2_mmio_req_bits_REG_uop_debug_seqNum_uopIdx;
  logic s2_mmio_req_bits_REG_uop_lqIdx_flag;
  logic [6:0] s2_mmio_req_bits_REG_uop_lqIdx_value;
  logic s2_mmio_req_bits_REG_uop_replayInst;
  logic s2_mmio_req_bits_REG_debug_isMMIO;
  logic s2_mmio_req_bits_REG_debug_isNCIO;
  logic s2_mmio_req_bits_REG_debug_isPerfCnt;
  logic [47:0] s2_mmio_req_bits_REG_debug_paddr;
  logic [49:0] s2_mmio_req_bits_REG_debug_vaddr;
  always_ff @(posedge clock) begin
    s2_mmio_req_bits_REG_uop_exceptionVec_3 <= lsq_uncache.uop.exceptionVec[3];
    s2_mmio_req_bits_REG_uop_exceptionVec_4 <= lsq_uncache.uop.exceptionVec[4];
    s2_mmio_req_bits_REG_uop_exceptionVec_5 <= lsq_uncache.uop.exceptionVec[5];
    s2_mmio_req_bits_REG_uop_exceptionVec_13 <= lsq_uncache.uop.exceptionVec[13];
    s2_mmio_req_bits_REG_uop_exceptionVec_19 <= lsq_uncache.uop.exceptionVec[19];
    s2_mmio_req_bits_REG_uop_exceptionVec_21 <= lsq_uncache.uop.exceptionVec[21];
    s2_mmio_req_bits_REG_uop_trigger <= lsq_uncache.uop.trigger;
    s2_mmio_req_bits_REG_uop_preDecodeInfo_valid <= lsq_uncache.uop.preDecodeInfo_valid;
    s2_mmio_req_bits_REG_uop_preDecodeInfo_isRVC <= lsq_uncache.uop.preDecodeInfo_isRVC;
    s2_mmio_req_bits_REG_uop_preDecodeInfo_brType <= lsq_uncache.uop.preDecodeInfo_brType;
    s2_mmio_req_bits_REG_uop_preDecodeInfo_isCall <= lsq_uncache.uop.preDecodeInfo_isCall;
    s2_mmio_req_bits_REG_uop_preDecodeInfo_isRet <= lsq_uncache.uop.preDecodeInfo_isRet;
    s2_mmio_req_bits_REG_uop_rfWen <= lsq_uncache.uop.rfWen;
    s2_mmio_req_bits_REG_uop_fpWen <= lsq_uncache.uop.fpWen;
    s2_mmio_req_bits_REG_uop_flushPipe <= lsq_uncache.uop.flushPipe;
    s2_mmio_req_bits_REG_uop_pdest <= lsq_uncache.uop.pdest;
    s2_mmio_req_bits_REG_uop_robIdx_flag <= lsq_uncache.uop.robIdx_flag;
    s2_mmio_req_bits_REG_uop_robIdx_value <= lsq_uncache.uop.robIdx_value;
    s2_mmio_req_bits_REG_uop_debugInfo_eliminatedMove <= lsq_uncache.uop.debugInfo_eliminatedMove;
    s2_mmio_req_bits_REG_uop_debugInfo_renameTime <= lsq_uncache.uop.debugInfo_renameTime;
    s2_mmio_req_bits_REG_uop_debugInfo_dispatchTime <= lsq_uncache.uop.debugInfo_dispatchTime;
    s2_mmio_req_bits_REG_uop_debugInfo_enqRsTime <= lsq_uncache.uop.debugInfo_enqRsTime;
    s2_mmio_req_bits_REG_uop_debugInfo_selectTime <= lsq_uncache.uop.debugInfo_selectTime;
    s2_mmio_req_bits_REG_uop_debugInfo_issueTime <= lsq_uncache.uop.debugInfo_issueTime;
    s2_mmio_req_bits_REG_uop_debugInfo_writebackTime <= lsq_uncache.uop.debugInfo_writebackTime;
    s2_mmio_req_bits_REG_uop_debugInfo_runahead_checkpoint_id <= lsq_uncache.uop.debugInfo_runahead_checkpoint_id;
    s2_mmio_req_bits_REG_uop_debugInfo_tlbFirstReqTime <= lsq_uncache.uop.debugInfo_tlbFirstReqTime;
    s2_mmio_req_bits_REG_uop_debugInfo_tlbRespTime <= lsq_uncache.uop.debugInfo_tlbRespTime;
    s2_mmio_req_bits_REG_uop_debug_seqNum_seqNum <= lsq_uncache.uop.debug_seqNum_seqNum;
    s2_mmio_req_bits_REG_uop_debug_seqNum_uopIdx <= lsq_uncache.uop.debug_seqNum_uopIdx;
    s2_mmio_req_bits_REG_uop_lqIdx_flag <= lsq_uncache.uop.lqIdx_flag;
    s2_mmio_req_bits_REG_uop_lqIdx_value <= lsq_uncache.uop.lqIdx_value;
    s2_mmio_req_bits_REG_uop_replayInst <= lsq_uncache.uop.replayInst;
    s2_mmio_req_bits_REG_debug_isMMIO <= lsq_uncache.debug_isMMIO;
    s2_mmio_req_bits_REG_debug_isNCIO <= lsq_uncache.debug_isNCIO;
    s2_mmio_req_bits_REG_debug_isPerfCnt <= lsq_uncache.debug_isPerfCnt;
    s2_mmio_req_bits_REG_debug_paddr <= lsq_uncache.debug_paddr;
    s2_mmio_req_bits_REG_debug_vaddr <= lsq_uncache.debug_vaddr;
  end
  // 读回成 struct；golden 没留下的字段（DCE 掉 / 下游不用）恒 0
  always_comb begin
    mmio_req_d1 = '0;
    mmio_req_d1.uop.exceptionVec[3] = s2_mmio_req_bits_REG_uop_exceptionVec_3;
    mmio_req_d1.uop.exceptionVec[4] = s2_mmio_req_bits_REG_uop_exceptionVec_4;
    mmio_req_d1.uop.exceptionVec[5] = s2_mmio_req_bits_REG_uop_exceptionVec_5;
    mmio_req_d1.uop.exceptionVec[13] = s2_mmio_req_bits_REG_uop_exceptionVec_13;
    mmio_req_d1.uop.exceptionVec[19] = s2_mmio_req_bits_REG_uop_exceptionVec_19;
    mmio_req_d1.uop.exceptionVec[21] = s2_mmio_req_bits_REG_uop_exceptionVec_21;
    mmio_req_d1.uop.trigger = s2_mmio_req_bits_REG_uop_trigger;
    mmio_req_d1.uop.preDecodeInfo_valid = s2_mmio_req_bits_REG_uop_preDecodeInfo_valid;
    mmio_req_d1.uop.preDecodeInfo_isRVC = s2_mmio_req_bits_REG_uop_preDecodeInfo_isRVC;
    mmio_req_d1.uop.preDecodeInfo_brType = s2_mmio_req_bits_REG_uop_preDecodeInfo_brType;
    mmio_req_d1.uop.preDecodeInfo_isCall = s2_mmio_req_bits_REG_uop_preDecodeInfo_isCall;
    mmio_req_d1.uop.preDecodeInfo_isRet = s2_mmio_req_bits_REG_uop_preDecodeInfo_isRet;
    mmio_req_d1.uop.rfWen = s2_mmio_req_bits_REG_uop_rfWen;
    mmio_req_d1.uop.fpWen = s2_mmio_req_bits_REG_uop_fpWen;
    mmio_req_d1.uop.flushPipe = s2_mmio_req_bits_REG_uop_flushPipe;
    mmio_req_d1.uop.pdest = s2_mmio_req_bits_REG_uop_pdest;
    mmio_req_d1.uop.robIdx_flag = s2_mmio_req_bits_REG_uop_robIdx_flag;
    mmio_req_d1.uop.robIdx_value = s2_mmio_req_bits_REG_uop_robIdx_value;
    mmio_req_d1.uop.debugInfo_eliminatedMove = s2_mmio_req_bits_REG_uop_debugInfo_eliminatedMove;
    mmio_req_d1.uop.debugInfo_renameTime = s2_mmio_req_bits_REG_uop_debugInfo_renameTime;
    mmio_req_d1.uop.debugInfo_dispatchTime = s2_mmio_req_bits_REG_uop_debugInfo_dispatchTime;
    mmio_req_d1.uop.debugInfo_enqRsTime = s2_mmio_req_bits_REG_uop_debugInfo_enqRsTime;
    mmio_req_d1.uop.debugInfo_selectTime = s2_mmio_req_bits_REG_uop_debugInfo_selectTime;
    mmio_req_d1.uop.debugInfo_issueTime = s2_mmio_req_bits_REG_uop_debugInfo_issueTime;
    mmio_req_d1.uop.debugInfo_writebackTime = s2_mmio_req_bits_REG_uop_debugInfo_writebackTime;
    mmio_req_d1.uop.debugInfo_runahead_checkpoint_id = s2_mmio_req_bits_REG_uop_debugInfo_runahead_checkpoint_id;
    mmio_req_d1.uop.debugInfo_tlbFirstReqTime = s2_mmio_req_bits_REG_uop_debugInfo_tlbFirstReqTime;
    mmio_req_d1.uop.debugInfo_tlbRespTime = s2_mmio_req_bits_REG_uop_debugInfo_tlbRespTime;
    mmio_req_d1.uop.debug_seqNum_seqNum = s2_mmio_req_bits_REG_uop_debug_seqNum_seqNum;
    mmio_req_d1.uop.debug_seqNum_uopIdx = s2_mmio_req_bits_REG_uop_debug_seqNum_uopIdx;
    mmio_req_d1.uop.lqIdx_flag = s2_mmio_req_bits_REG_uop_lqIdx_flag;
    mmio_req_d1.uop.lqIdx_value = s2_mmio_req_bits_REG_uop_lqIdx_value;
    mmio_req_d1.uop.replayInst = s2_mmio_req_bits_REG_uop_replayInst;
    mmio_req_d1.debug_isMMIO = s2_mmio_req_bits_REG_debug_isMMIO;
    mmio_req_d1.debug_isNCIO = s2_mmio_req_bits_REG_debug_isNCIO;
    mmio_req_d1.debug_isPerfCnt = s2_mmio_req_bits_REG_debug_isPerfCnt;
    mmio_req_d1.debug_paddr = s2_mmio_req_bits_REG_debug_paddr;
    mmio_req_d1.debug_vaddr = s2_mmio_req_bits_REG_debug_vaddr;
  end

  // ---- MMIO 写回包第 2 拍（= s2_mmio_req.bits）：golden 留下的 38 个字段 ----
  logic s2_mmio_req_bits_REG_1_uop_exceptionVec_3;
  logic s2_mmio_req_bits_REG_1_uop_exceptionVec_4;
  logic s2_mmio_req_bits_REG_1_uop_exceptionVec_5;
  logic s2_mmio_req_bits_REG_1_uop_exceptionVec_13;
  logic s2_mmio_req_bits_REG_1_uop_exceptionVec_19;
  logic s2_mmio_req_bits_REG_1_uop_exceptionVec_21;
  logic [3:0] s2_mmio_req_bits_REG_1_uop_trigger;
  logic s2_mmio_req_bits_REG_1_uop_preDecodeInfo_valid;
  logic s2_mmio_req_bits_REG_1_uop_preDecodeInfo_isRVC;
  logic [1:0] s2_mmio_req_bits_REG_1_uop_preDecodeInfo_brType;
  logic s2_mmio_req_bits_REG_1_uop_preDecodeInfo_isCall;
  logic s2_mmio_req_bits_REG_1_uop_preDecodeInfo_isRet;
  logic s2_mmio_req_bits_REG_1_uop_rfWen;
  logic s2_mmio_req_bits_REG_1_uop_fpWen;
  logic s2_mmio_req_bits_REG_1_uop_flushPipe;
  logic [7:0] s2_mmio_req_bits_REG_1_uop_pdest;
  logic s2_mmio_req_bits_REG_1_uop_robIdx_flag;
  logic [7:0] s2_mmio_req_bits_REG_1_uop_robIdx_value;
  logic s2_mmio_req_bits_REG_1_uop_debugInfo_eliminatedMove;
  logic [63:0] s2_mmio_req_bits_REG_1_uop_debugInfo_renameTime;
  logic [63:0] s2_mmio_req_bits_REG_1_uop_debugInfo_dispatchTime;
  logic [63:0] s2_mmio_req_bits_REG_1_uop_debugInfo_enqRsTime;
  logic [63:0] s2_mmio_req_bits_REG_1_uop_debugInfo_selectTime;
  logic [63:0] s2_mmio_req_bits_REG_1_uop_debugInfo_issueTime;
  logic [63:0] s2_mmio_req_bits_REG_1_uop_debugInfo_writebackTime;
  logic [63:0] s2_mmio_req_bits_REG_1_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0] s2_mmio_req_bits_REG_1_uop_debugInfo_tlbFirstReqTime;
  logic [63:0] s2_mmio_req_bits_REG_1_uop_debugInfo_tlbRespTime;
  logic [55:0] s2_mmio_req_bits_REG_1_uop_debug_seqNum_seqNum;
  logic [7:0] s2_mmio_req_bits_REG_1_uop_debug_seqNum_uopIdx;
  logic s2_mmio_req_bits_REG_1_uop_lqIdx_flag;
  logic [6:0] s2_mmio_req_bits_REG_1_uop_lqIdx_value;
  logic s2_mmio_req_bits_REG_1_uop_replayInst;
  logic s2_mmio_req_bits_REG_1_debug_isMMIO;
  logic s2_mmio_req_bits_REG_1_debug_isNCIO;
  logic s2_mmio_req_bits_REG_1_debug_isPerfCnt;
  logic [47:0] s2_mmio_req_bits_REG_1_debug_paddr;
  logic [49:0] s2_mmio_req_bits_REG_1_debug_vaddr;
  always_ff @(posedge clock) begin
    s2_mmio_req_bits_REG_1_uop_exceptionVec_3 <= mmio_req_d1.uop.exceptionVec[3];
    s2_mmio_req_bits_REG_1_uop_exceptionVec_4 <= mmio_req_d1.uop.exceptionVec[4];
    s2_mmio_req_bits_REG_1_uop_exceptionVec_5 <= mmio_req_d1.uop.exceptionVec[5];
    s2_mmio_req_bits_REG_1_uop_exceptionVec_13 <= mmio_req_d1.uop.exceptionVec[13];
    s2_mmio_req_bits_REG_1_uop_exceptionVec_19 <= mmio_req_d1.uop.exceptionVec[19];
    s2_mmio_req_bits_REG_1_uop_exceptionVec_21 <= mmio_req_d1.uop.exceptionVec[21];
    s2_mmio_req_bits_REG_1_uop_trigger <= mmio_req_d1.uop.trigger;
    s2_mmio_req_bits_REG_1_uop_preDecodeInfo_valid <= mmio_req_d1.uop.preDecodeInfo_valid;
    s2_mmio_req_bits_REG_1_uop_preDecodeInfo_isRVC <= mmio_req_d1.uop.preDecodeInfo_isRVC;
    s2_mmio_req_bits_REG_1_uop_preDecodeInfo_brType <= mmio_req_d1.uop.preDecodeInfo_brType;
    s2_mmio_req_bits_REG_1_uop_preDecodeInfo_isCall <= mmio_req_d1.uop.preDecodeInfo_isCall;
    s2_mmio_req_bits_REG_1_uop_preDecodeInfo_isRet <= mmio_req_d1.uop.preDecodeInfo_isRet;
    s2_mmio_req_bits_REG_1_uop_rfWen <= mmio_req_d1.uop.rfWen;
    s2_mmio_req_bits_REG_1_uop_fpWen <= mmio_req_d1.uop.fpWen;
    s2_mmio_req_bits_REG_1_uop_flushPipe <= mmio_req_d1.uop.flushPipe;
    s2_mmio_req_bits_REG_1_uop_pdest <= mmio_req_d1.uop.pdest;
    s2_mmio_req_bits_REG_1_uop_robIdx_flag <= mmio_req_d1.uop.robIdx_flag;
    s2_mmio_req_bits_REG_1_uop_robIdx_value <= mmio_req_d1.uop.robIdx_value;
    s2_mmio_req_bits_REG_1_uop_debugInfo_eliminatedMove <= mmio_req_d1.uop.debugInfo_eliminatedMove;
    s2_mmio_req_bits_REG_1_uop_debugInfo_renameTime <= mmio_req_d1.uop.debugInfo_renameTime;
    s2_mmio_req_bits_REG_1_uop_debugInfo_dispatchTime <= mmio_req_d1.uop.debugInfo_dispatchTime;
    s2_mmio_req_bits_REG_1_uop_debugInfo_enqRsTime <= mmio_req_d1.uop.debugInfo_enqRsTime;
    s2_mmio_req_bits_REG_1_uop_debugInfo_selectTime <= mmio_req_d1.uop.debugInfo_selectTime;
    s2_mmio_req_bits_REG_1_uop_debugInfo_issueTime <= mmio_req_d1.uop.debugInfo_issueTime;
    s2_mmio_req_bits_REG_1_uop_debugInfo_writebackTime <= mmio_req_d1.uop.debugInfo_writebackTime;
    s2_mmio_req_bits_REG_1_uop_debugInfo_runahead_checkpoint_id <= mmio_req_d1.uop.debugInfo_runahead_checkpoint_id;
    s2_mmio_req_bits_REG_1_uop_debugInfo_tlbFirstReqTime <= mmio_req_d1.uop.debugInfo_tlbFirstReqTime;
    s2_mmio_req_bits_REG_1_uop_debugInfo_tlbRespTime <= mmio_req_d1.uop.debugInfo_tlbRespTime;
    s2_mmio_req_bits_REG_1_uop_debug_seqNum_seqNum <= mmio_req_d1.uop.debug_seqNum_seqNum;
    s2_mmio_req_bits_REG_1_uop_debug_seqNum_uopIdx <= mmio_req_d1.uop.debug_seqNum_uopIdx;
    s2_mmio_req_bits_REG_1_uop_lqIdx_flag <= mmio_req_d1.uop.lqIdx_flag;
    s2_mmio_req_bits_REG_1_uop_lqIdx_value <= mmio_req_d1.uop.lqIdx_value;
    s2_mmio_req_bits_REG_1_uop_replayInst <= mmio_req_d1.uop.replayInst;
    s2_mmio_req_bits_REG_1_debug_isMMIO <= mmio_req_d1.debug_isMMIO;
    s2_mmio_req_bits_REG_1_debug_isNCIO <= mmio_req_d1.debug_isNCIO;
    s2_mmio_req_bits_REG_1_debug_isPerfCnt <= mmio_req_d1.debug_isPerfCnt;
    s2_mmio_req_bits_REG_1_debug_paddr <= mmio_req_d1.debug_paddr;
    s2_mmio_req_bits_REG_1_debug_vaddr <= mmio_req_d1.debug_vaddr;
  end
  // 读回成 struct；golden 没留下的字段（DCE 掉 / 下游不用）恒 0
  always_comb begin
    s2_mmio_req_bits = '0;
    s2_mmio_req_bits.uop.exceptionVec[3] = s2_mmio_req_bits_REG_1_uop_exceptionVec_3;
    s2_mmio_req_bits.uop.exceptionVec[4] = s2_mmio_req_bits_REG_1_uop_exceptionVec_4;
    s2_mmio_req_bits.uop.exceptionVec[5] = s2_mmio_req_bits_REG_1_uop_exceptionVec_5;
    s2_mmio_req_bits.uop.exceptionVec[13] = s2_mmio_req_bits_REG_1_uop_exceptionVec_13;
    s2_mmio_req_bits.uop.exceptionVec[19] = s2_mmio_req_bits_REG_1_uop_exceptionVec_19;
    s2_mmio_req_bits.uop.exceptionVec[21] = s2_mmio_req_bits_REG_1_uop_exceptionVec_21;
    s2_mmio_req_bits.uop.trigger = s2_mmio_req_bits_REG_1_uop_trigger;
    s2_mmio_req_bits.uop.preDecodeInfo_valid = s2_mmio_req_bits_REG_1_uop_preDecodeInfo_valid;
    s2_mmio_req_bits.uop.preDecodeInfo_isRVC = s2_mmio_req_bits_REG_1_uop_preDecodeInfo_isRVC;
    s2_mmio_req_bits.uop.preDecodeInfo_brType = s2_mmio_req_bits_REG_1_uop_preDecodeInfo_brType;
    s2_mmio_req_bits.uop.preDecodeInfo_isCall = s2_mmio_req_bits_REG_1_uop_preDecodeInfo_isCall;
    s2_mmio_req_bits.uop.preDecodeInfo_isRet = s2_mmio_req_bits_REG_1_uop_preDecodeInfo_isRet;
    s2_mmio_req_bits.uop.rfWen = s2_mmio_req_bits_REG_1_uop_rfWen;
    s2_mmio_req_bits.uop.fpWen = s2_mmio_req_bits_REG_1_uop_fpWen;
    s2_mmio_req_bits.uop.flushPipe = s2_mmio_req_bits_REG_1_uop_flushPipe;
    s2_mmio_req_bits.uop.pdest = s2_mmio_req_bits_REG_1_uop_pdest;
    s2_mmio_req_bits.uop.robIdx_flag = s2_mmio_req_bits_REG_1_uop_robIdx_flag;
    s2_mmio_req_bits.uop.robIdx_value = s2_mmio_req_bits_REG_1_uop_robIdx_value;
    s2_mmio_req_bits.uop.debugInfo_eliminatedMove = s2_mmio_req_bits_REG_1_uop_debugInfo_eliminatedMove;
    s2_mmio_req_bits.uop.debugInfo_renameTime = s2_mmio_req_bits_REG_1_uop_debugInfo_renameTime;
    s2_mmio_req_bits.uop.debugInfo_dispatchTime = s2_mmio_req_bits_REG_1_uop_debugInfo_dispatchTime;
    s2_mmio_req_bits.uop.debugInfo_enqRsTime = s2_mmio_req_bits_REG_1_uop_debugInfo_enqRsTime;
    s2_mmio_req_bits.uop.debugInfo_selectTime = s2_mmio_req_bits_REG_1_uop_debugInfo_selectTime;
    s2_mmio_req_bits.uop.debugInfo_issueTime = s2_mmio_req_bits_REG_1_uop_debugInfo_issueTime;
    s2_mmio_req_bits.uop.debugInfo_writebackTime = s2_mmio_req_bits_REG_1_uop_debugInfo_writebackTime;
    s2_mmio_req_bits.uop.debugInfo_runahead_checkpoint_id = s2_mmio_req_bits_REG_1_uop_debugInfo_runahead_checkpoint_id;
    s2_mmio_req_bits.uop.debugInfo_tlbFirstReqTime = s2_mmio_req_bits_REG_1_uop_debugInfo_tlbFirstReqTime;
    s2_mmio_req_bits.uop.debugInfo_tlbRespTime = s2_mmio_req_bits_REG_1_uop_debugInfo_tlbRespTime;
    s2_mmio_req_bits.uop.debug_seqNum_seqNum = s2_mmio_req_bits_REG_1_uop_debug_seqNum_seqNum;
    s2_mmio_req_bits.uop.debug_seqNum_uopIdx = s2_mmio_req_bits_REG_1_uop_debug_seqNum_uopIdx;
    s2_mmio_req_bits.uop.lqIdx_flag = s2_mmio_req_bits_REG_1_uop_lqIdx_flag;
    s2_mmio_req_bits.uop.lqIdx_value = s2_mmio_req_bits_REG_1_uop_lqIdx_value;
    s2_mmio_req_bits.uop.replayInst = s2_mmio_req_bits_REG_1_uop_replayInst;
    s2_mmio_req_bits.debug_isMMIO = s2_mmio_req_bits_REG_1_debug_isMMIO;
    s2_mmio_req_bits.debug_isNCIO = s2_mmio_req_bits_REG_1_debug_isNCIO;
    s2_mmio_req_bits.debug_isPerfCnt = s2_mmio_req_bits_REG_1_debug_isPerfCnt;
    s2_mmio_req_bits.debug_paddr = s2_mmio_req_bits_REG_1_debug_paddr;
    s2_mmio_req_bits.debug_vaddr = s2_mmio_req_bits_REG_1_debug_vaddr;
  end

  // ---- MMIO 写回包第 3 拍（= s3_mmio_req.bits）：golden 留下的 35 个字段 ----
  logic s3_mmio_req_bits_uop_exceptionVec_3;
  logic s3_mmio_req_bits_uop_exceptionVec_4;
  logic s3_mmio_req_bits_uop_exceptionVec_5;
  logic s3_mmio_req_bits_uop_exceptionVec_13;
  logic s3_mmio_req_bits_uop_exceptionVec_19;
  logic s3_mmio_req_bits_uop_exceptionVec_21;
  logic [3:0] s3_mmio_req_bits_uop_trigger;
  logic s3_mmio_req_bits_uop_preDecodeInfo_valid;
  logic s3_mmio_req_bits_uop_preDecodeInfo_isRVC;
  logic [1:0] s3_mmio_req_bits_uop_preDecodeInfo_brType;
  logic s3_mmio_req_bits_uop_preDecodeInfo_isCall;
  logic s3_mmio_req_bits_uop_preDecodeInfo_isRet;
  logic s3_mmio_req_bits_uop_flushPipe;
  logic s3_mmio_req_bits_uop_robIdx_flag;
  logic [7:0] s3_mmio_req_bits_uop_robIdx_value;
  logic s3_mmio_req_bits_uop_debugInfo_eliminatedMove;
  logic [63:0] s3_mmio_req_bits_uop_debugInfo_renameTime;
  logic [63:0] s3_mmio_req_bits_uop_debugInfo_dispatchTime;
  logic [63:0] s3_mmio_req_bits_uop_debugInfo_enqRsTime;
  logic [63:0] s3_mmio_req_bits_uop_debugInfo_selectTime;
  logic [63:0] s3_mmio_req_bits_uop_debugInfo_issueTime;
  logic [63:0] s3_mmio_req_bits_uop_debugInfo_writebackTime;
  logic [63:0] s3_mmio_req_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0] s3_mmio_req_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0] s3_mmio_req_bits_uop_debugInfo_tlbRespTime;
  logic [55:0] s3_mmio_req_bits_uop_debug_seqNum_seqNum;
  logic [7:0] s3_mmio_req_bits_uop_debug_seqNum_uopIdx;
  logic s3_mmio_req_bits_uop_lqIdx_flag;
  logic [6:0] s3_mmio_req_bits_uop_lqIdx_value;
  logic s3_mmio_req_bits_uop_replayInst;
  logic s3_mmio_req_bits_debug_isMMIO;
  logic s3_mmio_req_bits_debug_isNCIO;
  logic s3_mmio_req_bits_debug_isPerfCnt;
  logic [47:0] s3_mmio_req_bits_debug_paddr;
  logic [49:0] s3_mmio_req_bits_debug_vaddr;
  always_ff @(posedge clock) begin
    s3_mmio_req_bits_uop_exceptionVec_3 <= s2_mmio_req_bits.uop.exceptionVec[3];
    s3_mmio_req_bits_uop_exceptionVec_4 <= s2_mmio_req_bits.uop.exceptionVec[4];
    s3_mmio_req_bits_uop_exceptionVec_5 <= s2_mmio_req_bits.uop.exceptionVec[5];
    s3_mmio_req_bits_uop_exceptionVec_13 <= s2_mmio_req_bits.uop.exceptionVec[13];
    s3_mmio_req_bits_uop_exceptionVec_19 <= s2_mmio_req_bits.uop.exceptionVec[19];
    s3_mmio_req_bits_uop_exceptionVec_21 <= s2_mmio_req_bits.uop.exceptionVec[21];
    s3_mmio_req_bits_uop_trigger <= s2_mmio_req_bits.uop.trigger;
    s3_mmio_req_bits_uop_preDecodeInfo_valid <= s2_mmio_req_bits.uop.preDecodeInfo_valid;
    s3_mmio_req_bits_uop_preDecodeInfo_isRVC <= s2_mmio_req_bits.uop.preDecodeInfo_isRVC;
    s3_mmio_req_bits_uop_preDecodeInfo_brType <= s2_mmio_req_bits.uop.preDecodeInfo_brType;
    s3_mmio_req_bits_uop_preDecodeInfo_isCall <= s2_mmio_req_bits.uop.preDecodeInfo_isCall;
    s3_mmio_req_bits_uop_preDecodeInfo_isRet <= s2_mmio_req_bits.uop.preDecodeInfo_isRet;
    s3_mmio_req_bits_uop_flushPipe <= s2_mmio_req_bits.uop.flushPipe;
    s3_mmio_req_bits_uop_robIdx_flag <= s2_mmio_req_bits.uop.robIdx_flag;
    s3_mmio_req_bits_uop_robIdx_value <= s2_mmio_req_bits.uop.robIdx_value;
    s3_mmio_req_bits_uop_debugInfo_eliminatedMove <= s2_mmio_req_bits.uop.debugInfo_eliminatedMove;
    s3_mmio_req_bits_uop_debugInfo_renameTime <= s2_mmio_req_bits.uop.debugInfo_renameTime;
    s3_mmio_req_bits_uop_debugInfo_dispatchTime <= s2_mmio_req_bits.uop.debugInfo_dispatchTime;
    s3_mmio_req_bits_uop_debugInfo_enqRsTime <= s2_mmio_req_bits.uop.debugInfo_enqRsTime;
    s3_mmio_req_bits_uop_debugInfo_selectTime <= s2_mmio_req_bits.uop.debugInfo_selectTime;
    s3_mmio_req_bits_uop_debugInfo_issueTime <= s2_mmio_req_bits.uop.debugInfo_issueTime;
    s3_mmio_req_bits_uop_debugInfo_writebackTime <= s2_mmio_req_bits.uop.debugInfo_writebackTime;
    s3_mmio_req_bits_uop_debugInfo_runahead_checkpoint_id <= s2_mmio_req_bits.uop.debugInfo_runahead_checkpoint_id;
    s3_mmio_req_bits_uop_debugInfo_tlbFirstReqTime <= s2_mmio_req_bits.uop.debugInfo_tlbFirstReqTime;
    s3_mmio_req_bits_uop_debugInfo_tlbRespTime <= s2_mmio_req_bits.uop.debugInfo_tlbRespTime;
    s3_mmio_req_bits_uop_debug_seqNum_seqNum <= s2_mmio_req_bits.uop.debug_seqNum_seqNum;
    s3_mmio_req_bits_uop_debug_seqNum_uopIdx <= s2_mmio_req_bits.uop.debug_seqNum_uopIdx;
    s3_mmio_req_bits_uop_lqIdx_flag <= s2_mmio_req_bits.uop.lqIdx_flag;
    s3_mmio_req_bits_uop_lqIdx_value <= s2_mmio_req_bits.uop.lqIdx_value;
    s3_mmio_req_bits_uop_replayInst <= s2_mmio_req_bits.uop.replayInst;
    s3_mmio_req_bits_debug_isMMIO <= s2_mmio_req_bits.debug_isMMIO;
    s3_mmio_req_bits_debug_isNCIO <= s2_mmio_req_bits.debug_isNCIO;
    s3_mmio_req_bits_debug_isPerfCnt <= s2_mmio_req_bits.debug_isPerfCnt;
    s3_mmio_req_bits_debug_paddr <= s2_mmio_req_bits.debug_paddr;
    s3_mmio_req_bits_debug_vaddr <= s2_mmio_req_bits.debug_vaddr;
  end
  // 读回成 struct；golden 没留下的字段（DCE 掉 / 下游不用）恒 0
  always_comb begin
    s3_mmio_req_bits = '0;
    s3_mmio_req_bits.uop.exceptionVec[3] = s3_mmio_req_bits_uop_exceptionVec_3;
    s3_mmio_req_bits.uop.exceptionVec[4] = s3_mmio_req_bits_uop_exceptionVec_4;
    s3_mmio_req_bits.uop.exceptionVec[5] = s3_mmio_req_bits_uop_exceptionVec_5;
    s3_mmio_req_bits.uop.exceptionVec[13] = s3_mmio_req_bits_uop_exceptionVec_13;
    s3_mmio_req_bits.uop.exceptionVec[19] = s3_mmio_req_bits_uop_exceptionVec_19;
    s3_mmio_req_bits.uop.exceptionVec[21] = s3_mmio_req_bits_uop_exceptionVec_21;
    s3_mmio_req_bits.uop.trigger = s3_mmio_req_bits_uop_trigger;
    s3_mmio_req_bits.uop.preDecodeInfo_valid = s3_mmio_req_bits_uop_preDecodeInfo_valid;
    s3_mmio_req_bits.uop.preDecodeInfo_isRVC = s3_mmio_req_bits_uop_preDecodeInfo_isRVC;
    s3_mmio_req_bits.uop.preDecodeInfo_brType = s3_mmio_req_bits_uop_preDecodeInfo_brType;
    s3_mmio_req_bits.uop.preDecodeInfo_isCall = s3_mmio_req_bits_uop_preDecodeInfo_isCall;
    s3_mmio_req_bits.uop.preDecodeInfo_isRet = s3_mmio_req_bits_uop_preDecodeInfo_isRet;
    s3_mmio_req_bits.uop.flushPipe = s3_mmio_req_bits_uop_flushPipe;
    s3_mmio_req_bits.uop.robIdx_flag = s3_mmio_req_bits_uop_robIdx_flag;
    s3_mmio_req_bits.uop.robIdx_value = s3_mmio_req_bits_uop_robIdx_value;
    s3_mmio_req_bits.uop.debugInfo_eliminatedMove = s3_mmio_req_bits_uop_debugInfo_eliminatedMove;
    s3_mmio_req_bits.uop.debugInfo_renameTime = s3_mmio_req_bits_uop_debugInfo_renameTime;
    s3_mmio_req_bits.uop.debugInfo_dispatchTime = s3_mmio_req_bits_uop_debugInfo_dispatchTime;
    s3_mmio_req_bits.uop.debugInfo_enqRsTime = s3_mmio_req_bits_uop_debugInfo_enqRsTime;
    s3_mmio_req_bits.uop.debugInfo_selectTime = s3_mmio_req_bits_uop_debugInfo_selectTime;
    s3_mmio_req_bits.uop.debugInfo_issueTime = s3_mmio_req_bits_uop_debugInfo_issueTime;
    s3_mmio_req_bits.uop.debugInfo_writebackTime = s3_mmio_req_bits_uop_debugInfo_writebackTime;
    s3_mmio_req_bits.uop.debugInfo_runahead_checkpoint_id = s3_mmio_req_bits_uop_debugInfo_runahead_checkpoint_id;
    s3_mmio_req_bits.uop.debugInfo_tlbFirstReqTime = s3_mmio_req_bits_uop_debugInfo_tlbFirstReqTime;
    s3_mmio_req_bits.uop.debugInfo_tlbRespTime = s3_mmio_req_bits_uop_debugInfo_tlbRespTime;
    s3_mmio_req_bits.uop.debug_seqNum_seqNum = s3_mmio_req_bits_uop_debug_seqNum_seqNum;
    s3_mmio_req_bits.uop.debug_seqNum_uopIdx = s3_mmio_req_bits_uop_debug_seqNum_uopIdx;
    s3_mmio_req_bits.uop.lqIdx_flag = s3_mmio_req_bits_uop_lqIdx_flag;
    s3_mmio_req_bits.uop.lqIdx_value = s3_mmio_req_bits_uop_lqIdx_value;
    s3_mmio_req_bits.uop.replayInst = s3_mmio_req_bits_uop_replayInst;
    s3_mmio_req_bits.debug_isMMIO = s3_mmio_req_bits_debug_isMMIO;
    s3_mmio_req_bits.debug_isNCIO = s3_mmio_req_bits_debug_isNCIO;
    s3_mmio_req_bits.debug_isPerfCnt = s3_mmio_req_bits_debug_isPerfCnt;
    s3_mmio_req_bits.debug_paddr = s3_mmio_req_bits_debug_paddr;
    s3_mmio_req_bits.debug_vaddr = s3_mmio_req_bits_debug_vaddr;
  end

  // ---- MMIO 原始数据第 1 拍：golden 留下的 4 个字段 ----
  logic [63:0] s3_ld_raw_data_frm_mmio_REG_lqData;
  logic [8:0] s3_ld_raw_data_frm_mmio_REG_uop_fuOpType;
  logic s3_ld_raw_data_frm_mmio_REG_uop_fpWen;
  logic [2:0] s3_ld_raw_data_frm_mmio_REG_addrOffset;
  always_ff @(posedge clock) begin
    s3_ld_raw_data_frm_mmio_REG_lqData <= ld_raw_data.lqData;
    s3_ld_raw_data_frm_mmio_REG_uop_fuOpType <= ld_raw_data.uop.fuOpType;
    s3_ld_raw_data_frm_mmio_REG_uop_fpWen <= ld_raw_data.uop.fpWen;
    s3_ld_raw_data_frm_mmio_REG_addrOffset <= ld_raw_data.addrOffset;
  end
  // 读回成 struct；golden 没留下的字段（DCE 掉 / 下游不用）恒 0
  always_comb begin
    mmio_raw_d1 = '0;
    mmio_raw_d1.lqData = s3_ld_raw_data_frm_mmio_REG_lqData;
    mmio_raw_d1.uop.fuOpType = s3_ld_raw_data_frm_mmio_REG_uop_fuOpType;
    mmio_raw_d1.uop.fpWen = s3_ld_raw_data_frm_mmio_REG_uop_fpWen;
    mmio_raw_d1.addrOffset = s3_ld_raw_data_frm_mmio_REG_addrOffset;
  end

  // ---- MMIO 原始数据第 2 拍：golden 留下的 4 个字段 ----
  logic [63:0] s3_ld_raw_data_frm_mmio_REG_1_lqData;
  logic [8:0] s3_ld_raw_data_frm_mmio_REG_1_uop_fuOpType;
  logic s3_ld_raw_data_frm_mmio_REG_1_uop_fpWen;
  logic [2:0] s3_ld_raw_data_frm_mmio_REG_1_addrOffset;
  always_ff @(posedge clock) begin
    s3_ld_raw_data_frm_mmio_REG_1_lqData <= mmio_raw_d1.lqData;
    s3_ld_raw_data_frm_mmio_REG_1_uop_fuOpType <= mmio_raw_d1.uop.fuOpType;
    s3_ld_raw_data_frm_mmio_REG_1_uop_fpWen <= mmio_raw_d1.uop.fpWen;
    s3_ld_raw_data_frm_mmio_REG_1_addrOffset <= mmio_raw_d1.addrOffset;
  end
  // 读回成 struct；golden 没留下的字段（DCE 掉 / 下游不用）恒 0
  always_comb begin
    mmio_raw_d2 = '0;
    mmio_raw_d2.lqData = s3_ld_raw_data_frm_mmio_REG_1_lqData;
    mmio_raw_d2.uop.fuOpType = s3_ld_raw_data_frm_mmio_REG_1_uop_fuOpType;
    mmio_raw_d2.uop.fpWen = s3_ld_raw_data_frm_mmio_REG_1_uop_fpWen;
    mmio_raw_d2.addrOffset = s3_ld_raw_data_frm_mmio_REG_1_addrOffset;
  end

  // ---- MMIO 原始数据第 3 拍：golden 留下的 4 个字段 ----
  logic [63:0] s3_ld_raw_data_frm_mmio_lqData;
  logic [8:0] s3_ld_raw_data_frm_mmio_uop_fuOpType;
  logic s3_ld_raw_data_frm_mmio_uop_fpWen;
  logic [2:0] s3_ld_raw_data_frm_mmio_addrOffset;
  always_ff @(posedge clock) begin
    s3_ld_raw_data_frm_mmio_lqData <= mmio_raw_d2.lqData;
    s3_ld_raw_data_frm_mmio_uop_fuOpType <= mmio_raw_d2.uop.fuOpType;
    s3_ld_raw_data_frm_mmio_uop_fpWen <= mmio_raw_d2.uop.fpWen;
    s3_ld_raw_data_frm_mmio_addrOffset <= mmio_raw_d2.addrOffset;
  end
  // 读回成 struct；golden 没留下的字段（DCE 掉 / 下游不用）恒 0
  always_comb begin
    s3_ld_raw_data_frm_mmio = '0;
    s3_ld_raw_data_frm_mmio.lqData = s3_ld_raw_data_frm_mmio_lqData;
    s3_ld_raw_data_frm_mmio.uop.fuOpType = s3_ld_raw_data_frm_mmio_uop_fuOpType;
    s3_ld_raw_data_frm_mmio.uop.fpWen = s3_ld_raw_data_frm_mmio_uop_fpWen;
    s3_ld_raw_data_frm_mmio.addrOffset = s3_ld_raw_data_frm_mmio_addrOffset;
  end

  // ---- 非对齐唤醒包第 1 拍：golden 留下的 20 个字段 ----
  logic s3_misalign_wakeup_req_bits_REG_uop_exceptionVec_3;
  logic s3_misalign_wakeup_req_bits_REG_uop_exceptionVec_4;
  logic s3_misalign_wakeup_req_bits_REG_uop_exceptionVec_5;
  logic s3_misalign_wakeup_req_bits_REG_uop_exceptionVec_13;
  logic s3_misalign_wakeup_req_bits_REG_uop_exceptionVec_19;
  logic s3_misalign_wakeup_req_bits_REG_uop_exceptionVec_21;
  logic [3:0] s3_misalign_wakeup_req_bits_REG_uop_trigger;
  logic s3_misalign_wakeup_req_bits_REG_uop_robIdx_flag;
  logic [7:0] s3_misalign_wakeup_req_bits_REG_uop_robIdx_value;
  logic [49:0] s3_misalign_wakeup_req_bits_REG_vaddr;
  logic [63:0] s3_misalign_wakeup_req_bits_REG_fullva;
  logic s3_misalign_wakeup_req_bits_REG_vaNeedExt;
  logic [47:0] s3_misalign_wakeup_req_bits_REG_paddr;
  logic [63:0] s3_misalign_wakeup_req_bits_REG_gpaddr;
  logic s3_misalign_wakeup_req_bits_REG_nc;
  logic s3_misalign_wakeup_req_bits_REG_mmio;
  logic s3_misalign_wakeup_req_bits_REG_memBackTypeMM;
  logic s3_misalign_wakeup_req_bits_REG_isForVSnonLeafPTE;
  logic s3_misalign_wakeup_req_bits_REG_vecActive;
  logic s3_misalign_wakeup_req_bits_REG_misalignNeedWakeUp;
  always_ff @(posedge clock) begin
    s3_misalign_wakeup_req_bits_REG_uop_exceptionVec_3 <= misalign_ldin.uop.exceptionVec[3];
    s3_misalign_wakeup_req_bits_REG_uop_exceptionVec_4 <= misalign_ldin.uop.exceptionVec[4];
    s3_misalign_wakeup_req_bits_REG_uop_exceptionVec_5 <= misalign_ldin.uop.exceptionVec[5];
    s3_misalign_wakeup_req_bits_REG_uop_exceptionVec_13 <= misalign_ldin.uop.exceptionVec[13];
    s3_misalign_wakeup_req_bits_REG_uop_exceptionVec_19 <= misalign_ldin.uop.exceptionVec[19];
    s3_misalign_wakeup_req_bits_REG_uop_exceptionVec_21 <= misalign_ldin.uop.exceptionVec[21];
    s3_misalign_wakeup_req_bits_REG_uop_trigger <= misalign_ldin.uop.trigger;
    s3_misalign_wakeup_req_bits_REG_uop_robIdx_flag <= misalign_ldin.uop.robIdx_flag;
    s3_misalign_wakeup_req_bits_REG_uop_robIdx_value <= misalign_ldin.uop.robIdx_value;
    s3_misalign_wakeup_req_bits_REG_vaddr <= misalign_ldin.vaddr;
    s3_misalign_wakeup_req_bits_REG_fullva <= misalign_ldin.fullva;
    s3_misalign_wakeup_req_bits_REG_vaNeedExt <= misalign_ldin.vaNeedExt;
    s3_misalign_wakeup_req_bits_REG_paddr <= misalign_ldin.paddr;
    s3_misalign_wakeup_req_bits_REG_gpaddr <= misalign_ldin.gpaddr;
    s3_misalign_wakeup_req_bits_REG_nc <= misalign_ldin.nc;
    s3_misalign_wakeup_req_bits_REG_mmio <= misalign_ldin.mmio;
    s3_misalign_wakeup_req_bits_REG_memBackTypeMM <= misalign_ldin.memBackTypeMM;
    s3_misalign_wakeup_req_bits_REG_isForVSnonLeafPTE <= misalign_ldin.isForVSnonLeafPTE;
    s3_misalign_wakeup_req_bits_REG_vecActive <= misalign_ldin.vecActive;
    s3_misalign_wakeup_req_bits_REG_misalignNeedWakeUp <= misalign_ldin.misalignNeedWakeUp;
  end
  // 读回成 struct；golden 没留下的字段（DCE 掉 / 下游不用）恒 0
  always_comb begin
    mab_wakeup_d1 = '0;
    mab_wakeup_d1.uop.exceptionVec[3] = s3_misalign_wakeup_req_bits_REG_uop_exceptionVec_3;
    mab_wakeup_d1.uop.exceptionVec[4] = s3_misalign_wakeup_req_bits_REG_uop_exceptionVec_4;
    mab_wakeup_d1.uop.exceptionVec[5] = s3_misalign_wakeup_req_bits_REG_uop_exceptionVec_5;
    mab_wakeup_d1.uop.exceptionVec[13] = s3_misalign_wakeup_req_bits_REG_uop_exceptionVec_13;
    mab_wakeup_d1.uop.exceptionVec[19] = s3_misalign_wakeup_req_bits_REG_uop_exceptionVec_19;
    mab_wakeup_d1.uop.exceptionVec[21] = s3_misalign_wakeup_req_bits_REG_uop_exceptionVec_21;
    mab_wakeup_d1.uop.trigger = s3_misalign_wakeup_req_bits_REG_uop_trigger;
    mab_wakeup_d1.uop.robIdx_flag = s3_misalign_wakeup_req_bits_REG_uop_robIdx_flag;
    mab_wakeup_d1.uop.robIdx_value = s3_misalign_wakeup_req_bits_REG_uop_robIdx_value;
    mab_wakeup_d1.vaddr = s3_misalign_wakeup_req_bits_REG_vaddr;
    mab_wakeup_d1.fullva = s3_misalign_wakeup_req_bits_REG_fullva;
    mab_wakeup_d1.vaNeedExt = s3_misalign_wakeup_req_bits_REG_vaNeedExt;
    mab_wakeup_d1.paddr = s3_misalign_wakeup_req_bits_REG_paddr;
    mab_wakeup_d1.gpaddr = s3_misalign_wakeup_req_bits_REG_gpaddr;
    mab_wakeup_d1.nc = s3_misalign_wakeup_req_bits_REG_nc;
    mab_wakeup_d1.mmio = s3_misalign_wakeup_req_bits_REG_mmio;
    mab_wakeup_d1.memBackTypeMM = s3_misalign_wakeup_req_bits_REG_memBackTypeMM;
    mab_wakeup_d1.isForVSnonLeafPTE = s3_misalign_wakeup_req_bits_REG_isForVSnonLeafPTE;
    mab_wakeup_d1.vecActive = s3_misalign_wakeup_req_bits_REG_vecActive;
    mab_wakeup_d1.misalignNeedWakeUp = s3_misalign_wakeup_req_bits_REG_misalignNeedWakeUp;
  end

  // ---- 非对齐唤醒包第 2 拍：golden 留下的 20 个字段 ----
  logic s3_misalign_wakeup_req_bits_REG_1_uop_exceptionVec_3;
  logic s3_misalign_wakeup_req_bits_REG_1_uop_exceptionVec_4;
  logic s3_misalign_wakeup_req_bits_REG_1_uop_exceptionVec_5;
  logic s3_misalign_wakeup_req_bits_REG_1_uop_exceptionVec_13;
  logic s3_misalign_wakeup_req_bits_REG_1_uop_exceptionVec_19;
  logic s3_misalign_wakeup_req_bits_REG_1_uop_exceptionVec_21;
  logic [3:0] s3_misalign_wakeup_req_bits_REG_1_uop_trigger;
  logic s3_misalign_wakeup_req_bits_REG_1_uop_robIdx_flag;
  logic [7:0] s3_misalign_wakeup_req_bits_REG_1_uop_robIdx_value;
  logic [49:0] s3_misalign_wakeup_req_bits_REG_1_vaddr;
  logic [63:0] s3_misalign_wakeup_req_bits_REG_1_fullva;
  logic s3_misalign_wakeup_req_bits_REG_1_vaNeedExt;
  logic [47:0] s3_misalign_wakeup_req_bits_REG_1_paddr;
  logic [63:0] s3_misalign_wakeup_req_bits_REG_1_gpaddr;
  logic s3_misalign_wakeup_req_bits_REG_1_nc;
  logic s3_misalign_wakeup_req_bits_REG_1_mmio;
  logic s3_misalign_wakeup_req_bits_REG_1_memBackTypeMM;
  logic s3_misalign_wakeup_req_bits_REG_1_isForVSnonLeafPTE;
  logic s3_misalign_wakeup_req_bits_REG_1_vecActive;
  logic s3_misalign_wakeup_req_bits_REG_1_misalignNeedWakeUp;
  always_ff @(posedge clock) begin
    s3_misalign_wakeup_req_bits_REG_1_uop_exceptionVec_3 <= mab_wakeup_d1.uop.exceptionVec[3];
    s3_misalign_wakeup_req_bits_REG_1_uop_exceptionVec_4 <= mab_wakeup_d1.uop.exceptionVec[4];
    s3_misalign_wakeup_req_bits_REG_1_uop_exceptionVec_5 <= mab_wakeup_d1.uop.exceptionVec[5];
    s3_misalign_wakeup_req_bits_REG_1_uop_exceptionVec_13 <= mab_wakeup_d1.uop.exceptionVec[13];
    s3_misalign_wakeup_req_bits_REG_1_uop_exceptionVec_19 <= mab_wakeup_d1.uop.exceptionVec[19];
    s3_misalign_wakeup_req_bits_REG_1_uop_exceptionVec_21 <= mab_wakeup_d1.uop.exceptionVec[21];
    s3_misalign_wakeup_req_bits_REG_1_uop_trigger <= mab_wakeup_d1.uop.trigger;
    s3_misalign_wakeup_req_bits_REG_1_uop_robIdx_flag <= mab_wakeup_d1.uop.robIdx_flag;
    s3_misalign_wakeup_req_bits_REG_1_uop_robIdx_value <= mab_wakeup_d1.uop.robIdx_value;
    s3_misalign_wakeup_req_bits_REG_1_vaddr <= mab_wakeup_d1.vaddr;
    s3_misalign_wakeup_req_bits_REG_1_fullva <= mab_wakeup_d1.fullva;
    s3_misalign_wakeup_req_bits_REG_1_vaNeedExt <= mab_wakeup_d1.vaNeedExt;
    s3_misalign_wakeup_req_bits_REG_1_paddr <= mab_wakeup_d1.paddr;
    s3_misalign_wakeup_req_bits_REG_1_gpaddr <= mab_wakeup_d1.gpaddr;
    s3_misalign_wakeup_req_bits_REG_1_nc <= mab_wakeup_d1.nc;
    s3_misalign_wakeup_req_bits_REG_1_mmio <= mab_wakeup_d1.mmio;
    s3_misalign_wakeup_req_bits_REG_1_memBackTypeMM <= mab_wakeup_d1.memBackTypeMM;
    s3_misalign_wakeup_req_bits_REG_1_isForVSnonLeafPTE <= mab_wakeup_d1.isForVSnonLeafPTE;
    s3_misalign_wakeup_req_bits_REG_1_vecActive <= mab_wakeup_d1.vecActive;
    s3_misalign_wakeup_req_bits_REG_1_misalignNeedWakeUp <= mab_wakeup_d1.misalignNeedWakeUp;
  end
  // 读回成 struct；golden 没留下的字段（DCE 掉 / 下游不用）恒 0
  always_comb begin
    mab_wakeup_d2 = '0;
    mab_wakeup_d2.uop.exceptionVec[3] = s3_misalign_wakeup_req_bits_REG_1_uop_exceptionVec_3;
    mab_wakeup_d2.uop.exceptionVec[4] = s3_misalign_wakeup_req_bits_REG_1_uop_exceptionVec_4;
    mab_wakeup_d2.uop.exceptionVec[5] = s3_misalign_wakeup_req_bits_REG_1_uop_exceptionVec_5;
    mab_wakeup_d2.uop.exceptionVec[13] = s3_misalign_wakeup_req_bits_REG_1_uop_exceptionVec_13;
    mab_wakeup_d2.uop.exceptionVec[19] = s3_misalign_wakeup_req_bits_REG_1_uop_exceptionVec_19;
    mab_wakeup_d2.uop.exceptionVec[21] = s3_misalign_wakeup_req_bits_REG_1_uop_exceptionVec_21;
    mab_wakeup_d2.uop.trigger = s3_misalign_wakeup_req_bits_REG_1_uop_trigger;
    mab_wakeup_d2.uop.robIdx_flag = s3_misalign_wakeup_req_bits_REG_1_uop_robIdx_flag;
    mab_wakeup_d2.uop.robIdx_value = s3_misalign_wakeup_req_bits_REG_1_uop_robIdx_value;
    mab_wakeup_d2.vaddr = s3_misalign_wakeup_req_bits_REG_1_vaddr;
    mab_wakeup_d2.fullva = s3_misalign_wakeup_req_bits_REG_1_fullva;
    mab_wakeup_d2.vaNeedExt = s3_misalign_wakeup_req_bits_REG_1_vaNeedExt;
    mab_wakeup_d2.paddr = s3_misalign_wakeup_req_bits_REG_1_paddr;
    mab_wakeup_d2.gpaddr = s3_misalign_wakeup_req_bits_REG_1_gpaddr;
    mab_wakeup_d2.nc = s3_misalign_wakeup_req_bits_REG_1_nc;
    mab_wakeup_d2.mmio = s3_misalign_wakeup_req_bits_REG_1_mmio;
    mab_wakeup_d2.memBackTypeMM = s3_misalign_wakeup_req_bits_REG_1_memBackTypeMM;
    mab_wakeup_d2.isForVSnonLeafPTE = s3_misalign_wakeup_req_bits_REG_1_isForVSnonLeafPTE;
    mab_wakeup_d2.vecActive = s3_misalign_wakeup_req_bits_REG_1_vecActive;
    mab_wakeup_d2.misalignNeedWakeUp = s3_misalign_wakeup_req_bits_REG_1_misalignNeedWakeUp;
  end

  // ---- 非对齐唤醒包第 3 拍：golden 留下的 20 个字段 ----
  logic s3_misalign_wakeup_req_bits_REG_2_uop_exceptionVec_3;
  logic s3_misalign_wakeup_req_bits_REG_2_uop_exceptionVec_4;
  logic s3_misalign_wakeup_req_bits_REG_2_uop_exceptionVec_5;
  logic s3_misalign_wakeup_req_bits_REG_2_uop_exceptionVec_13;
  logic s3_misalign_wakeup_req_bits_REG_2_uop_exceptionVec_19;
  logic s3_misalign_wakeup_req_bits_REG_2_uop_exceptionVec_21;
  logic [3:0] s3_misalign_wakeup_req_bits_REG_2_uop_trigger;
  logic s3_misalign_wakeup_req_bits_REG_2_uop_robIdx_flag;
  logic [7:0] s3_misalign_wakeup_req_bits_REG_2_uop_robIdx_value;
  logic [49:0] s3_misalign_wakeup_req_bits_REG_2_vaddr;
  logic [63:0] s3_misalign_wakeup_req_bits_REG_2_fullva;
  logic s3_misalign_wakeup_req_bits_REG_2_vaNeedExt;
  logic [47:0] s3_misalign_wakeup_req_bits_REG_2_paddr;
  logic [63:0] s3_misalign_wakeup_req_bits_REG_2_gpaddr;
  logic s3_misalign_wakeup_req_bits_REG_2_nc;
  logic s3_misalign_wakeup_req_bits_REG_2_mmio;
  logic s3_misalign_wakeup_req_bits_REG_2_memBackTypeMM;
  logic s3_misalign_wakeup_req_bits_REG_2_isForVSnonLeafPTE;
  logic s3_misalign_wakeup_req_bits_REG_2_vecActive;
  logic s3_misalign_wakeup_req_bits_REG_2_misalignNeedWakeUp;
  always_ff @(posedge clock) begin
    s3_misalign_wakeup_req_bits_REG_2_uop_exceptionVec_3 <= mab_wakeup_d2.uop.exceptionVec[3];
    s3_misalign_wakeup_req_bits_REG_2_uop_exceptionVec_4 <= mab_wakeup_d2.uop.exceptionVec[4];
    s3_misalign_wakeup_req_bits_REG_2_uop_exceptionVec_5 <= mab_wakeup_d2.uop.exceptionVec[5];
    s3_misalign_wakeup_req_bits_REG_2_uop_exceptionVec_13 <= mab_wakeup_d2.uop.exceptionVec[13];
    s3_misalign_wakeup_req_bits_REG_2_uop_exceptionVec_19 <= mab_wakeup_d2.uop.exceptionVec[19];
    s3_misalign_wakeup_req_bits_REG_2_uop_exceptionVec_21 <= mab_wakeup_d2.uop.exceptionVec[21];
    s3_misalign_wakeup_req_bits_REG_2_uop_trigger <= mab_wakeup_d2.uop.trigger;
    s3_misalign_wakeup_req_bits_REG_2_uop_robIdx_flag <= mab_wakeup_d2.uop.robIdx_flag;
    s3_misalign_wakeup_req_bits_REG_2_uop_robIdx_value <= mab_wakeup_d2.uop.robIdx_value;
    s3_misalign_wakeup_req_bits_REG_2_vaddr <= mab_wakeup_d2.vaddr;
    s3_misalign_wakeup_req_bits_REG_2_fullva <= mab_wakeup_d2.fullva;
    s3_misalign_wakeup_req_bits_REG_2_vaNeedExt <= mab_wakeup_d2.vaNeedExt;
    s3_misalign_wakeup_req_bits_REG_2_paddr <= mab_wakeup_d2.paddr;
    s3_misalign_wakeup_req_bits_REG_2_gpaddr <= mab_wakeup_d2.gpaddr;
    s3_misalign_wakeup_req_bits_REG_2_nc <= mab_wakeup_d2.nc;
    s3_misalign_wakeup_req_bits_REG_2_mmio <= mab_wakeup_d2.mmio;
    s3_misalign_wakeup_req_bits_REG_2_memBackTypeMM <= mab_wakeup_d2.memBackTypeMM;
    s3_misalign_wakeup_req_bits_REG_2_isForVSnonLeafPTE <= mab_wakeup_d2.isForVSnonLeafPTE;
    s3_misalign_wakeup_req_bits_REG_2_vecActive <= mab_wakeup_d2.vecActive;
    s3_misalign_wakeup_req_bits_REG_2_misalignNeedWakeUp <= mab_wakeup_d2.misalignNeedWakeUp;
  end
  // 读回成 struct；golden 没留下的字段（DCE 掉 / 下游不用）恒 0
  always_comb begin
    s3_misalign_wakeup_req_bits = '0;
    s3_misalign_wakeup_req_bits.uop.exceptionVec[3] = s3_misalign_wakeup_req_bits_REG_2_uop_exceptionVec_3;
    s3_misalign_wakeup_req_bits.uop.exceptionVec[4] = s3_misalign_wakeup_req_bits_REG_2_uop_exceptionVec_4;
    s3_misalign_wakeup_req_bits.uop.exceptionVec[5] = s3_misalign_wakeup_req_bits_REG_2_uop_exceptionVec_5;
    s3_misalign_wakeup_req_bits.uop.exceptionVec[13] = s3_misalign_wakeup_req_bits_REG_2_uop_exceptionVec_13;
    s3_misalign_wakeup_req_bits.uop.exceptionVec[19] = s3_misalign_wakeup_req_bits_REG_2_uop_exceptionVec_19;
    s3_misalign_wakeup_req_bits.uop.exceptionVec[21] = s3_misalign_wakeup_req_bits_REG_2_uop_exceptionVec_21;
    s3_misalign_wakeup_req_bits.uop.trigger = s3_misalign_wakeup_req_bits_REG_2_uop_trigger;
    s3_misalign_wakeup_req_bits.uop.robIdx_flag = s3_misalign_wakeup_req_bits_REG_2_uop_robIdx_flag;
    s3_misalign_wakeup_req_bits.uop.robIdx_value = s3_misalign_wakeup_req_bits_REG_2_uop_robIdx_value;
    s3_misalign_wakeup_req_bits.vaddr = s3_misalign_wakeup_req_bits_REG_2_vaddr;
    s3_misalign_wakeup_req_bits.fullva = s3_misalign_wakeup_req_bits_REG_2_fullva;
    s3_misalign_wakeup_req_bits.vaNeedExt = s3_misalign_wakeup_req_bits_REG_2_vaNeedExt;
    s3_misalign_wakeup_req_bits.paddr = s3_misalign_wakeup_req_bits_REG_2_paddr;
    s3_misalign_wakeup_req_bits.gpaddr = s3_misalign_wakeup_req_bits_REG_2_gpaddr;
    s3_misalign_wakeup_req_bits.nc = s3_misalign_wakeup_req_bits_REG_2_nc;
    s3_misalign_wakeup_req_bits.mmio = s3_misalign_wakeup_req_bits_REG_2_mmio;
    s3_misalign_wakeup_req_bits.memBackTypeMM = s3_misalign_wakeup_req_bits_REG_2_memBackTypeMM;
    s3_misalign_wakeup_req_bits.isForVSnonLeafPTE = s3_misalign_wakeup_req_bits_REG_2_isForVSnonLeafPTE;
    s3_misalign_wakeup_req_bits.vecActive = s3_misalign_wakeup_req_bits_REG_2_vecActive;
    s3_misalign_wakeup_req_bits.misalignNeedWakeUp = s3_misalign_wakeup_req_bits_REG_2_misalignNeedWakeUp;
  end

  // ---- SMS 训练包锁存：golden 留下的 5 个字段 ----
  logic inputReg_uop_robIdx_flag;
  logic [7:0] inputReg_uop_robIdx_value;
  logic [49:0] inputReg_vaddr;
  logic [47:0] inputReg_paddr;
  logic inputReg_isFirstIssue;
  always_ff @(posedge clock) begin
    if (s2_prefetch_train_valid) begin
      inputReg_uop_robIdx_flag <= s2_in.uop.robIdx_flag;
      inputReg_uop_robIdx_value <= s2_in.uop.robIdx_value;
      inputReg_vaddr <= s2_in.vaddr;
      inputReg_paddr <= s2_in.paddr;
      inputReg_isFirstIssue <= s2_in.isFirstIssue;
    end
  end
  // 读回成 struct；golden 没留下的字段（DCE 掉 / 下游不用）恒 0
  always_comb begin
    pf_train_in = '0;
    pf_train_in.uop.robIdx_flag = inputReg_uop_robIdx_flag;
    pf_train_in.uop.robIdx_value = inputReg_uop_robIdx_value;
    pf_train_in.vaddr = inputReg_vaddr;
    pf_train_in.paddr = inputReg_paddr;
    pf_train_in.isFirstIssue = inputReg_isFirstIssue;
  end

  // ---- L1 预取训练包锁存：golden 留下的 4 个字段 ----
  logic inputReg_1_uop_robIdx_flag;
  logic [7:0] inputReg_1_uop_robIdx_value;
  logic [49:0] inputReg_1_vaddr;
  logic inputReg_1_isFirstIssue;
  always_ff @(posedge clock) begin
    if (s2_prefetch_train_l1_valid) begin
      inputReg_1_uop_robIdx_flag <= s2_in.uop.robIdx_flag;
      inputReg_1_uop_robIdx_value <= s2_in.uop.robIdx_value;
      inputReg_1_vaddr <= s2_in.vaddr;
      inputReg_1_isFirstIssue <= s2_in.isFirstIssue;
    end
  end
  // 读回成 struct；golden 没留下的字段（DCE 掉 / 下游不用）恒 0
  always_comb begin
    pf_train_l1_in = '0;
    pf_train_l1_in.uop.robIdx_flag = inputReg_1_uop_robIdx_flag;
    pf_train_l1_in.uop.robIdx_value = inputReg_1_uop_robIdx_value;
    pf_train_l1_in.vaddr = inputReg_1_vaddr;
    pf_train_l1_in.isFirstIssue = inputReg_1_isFirstIssue;
  end
  // END GENERATED(pipe_regs)

endmodule

// =====================================================================
// golden 同名 wrapper —— 端口逐位照抄 golden，拆装成 struct 接核
// =====================================================================
// BEGIN GENERATED(wrapper) —— verif/ut/LoadUnit/gen_loadunit.py 生成，勿手改
module LoadUnit
  import loadunit_pkg::*;
(
  input           clock,
  input           reset,
  input           io_redirect_valid,
  input           io_redirect_bits_robIdx_flag,
  input  [7:0]    io_redirect_bits_robIdx_value,
  input           io_redirect_bits_level,
  input           io_csrCtrl_ldld_vio_check_enable,
  input           io_csrCtrl_hd_misalign_ld_enable,
  output          io_ldin_ready,
  input           io_ldin_valid,
  input  [49:0]   io_ldin_bits_uop_pc,
  input           io_ldin_bits_uop_preDecodeInfo_valid,
  input           io_ldin_bits_uop_preDecodeInfo_isRVC,
  input  [1:0]    io_ldin_bits_uop_preDecodeInfo_brType,
  input           io_ldin_bits_uop_preDecodeInfo_isCall,
  input           io_ldin_bits_uop_preDecodeInfo_isRet,
  input           io_ldin_bits_uop_ftqPtr_flag,
  input  [5:0]    io_ldin_bits_uop_ftqPtr_value,
  input  [3:0]    io_ldin_bits_uop_ftqOffset,
  input  [34:0]   io_ldin_bits_uop_fuType,
  input  [8:0]    io_ldin_bits_uop_fuOpType,
  input           io_ldin_bits_uop_rfWen,
  input           io_ldin_bits_uop_fpWen,
  input  [31:0]   io_ldin_bits_uop_imm,
  input  [7:0]    io_ldin_bits_uop_pdest,
  input           io_ldin_bits_uop_robIdx_flag,
  input  [7:0]    io_ldin_bits_uop_robIdx_value,
  input           io_ldin_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]   io_ldin_bits_uop_debugInfo_renameTime,
  input  [63:0]   io_ldin_bits_uop_debugInfo_dispatchTime,
  input  [63:0]   io_ldin_bits_uop_debugInfo_enqRsTime,
  input  [63:0]   io_ldin_bits_uop_debugInfo_selectTime,
  input  [63:0]   io_ldin_bits_uop_debugInfo_issueTime,
  input  [63:0]   io_ldin_bits_uop_debugInfo_writebackTime,
  input  [63:0]   io_ldin_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]   io_ldin_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]   io_ldin_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]   io_ldin_bits_uop_debug_seqNum_seqNum,
  input  [7:0]    io_ldin_bits_uop_debug_seqNum_uopIdx,
  input           io_ldin_bits_uop_storeSetHit,
  input           io_ldin_bits_uop_waitForRobIdx_flag,
  input  [7:0]    io_ldin_bits_uop_waitForRobIdx_value,
  input           io_ldin_bits_uop_loadWaitBit,
  input           io_ldin_bits_uop_loadWaitStrict,
  input  [4:0]    io_ldin_bits_uop_ssid,
  input           io_ldin_bits_uop_lqIdx_flag,
  input  [6:0]    io_ldin_bits_uop_lqIdx_value,
  input           io_ldin_bits_uop_sqIdx_flag,
  input  [5:0]    io_ldin_bits_uop_sqIdx_value,
  input  [63:0]   io_ldin_bits_src_0,
  input           io_ldout_ready,
  output          io_ldout_valid,
  output          io_ldout_bits_uop_exceptionVec_3,
  output          io_ldout_bits_uop_exceptionVec_4,
  output          io_ldout_bits_uop_exceptionVec_5,
  output          io_ldout_bits_uop_exceptionVec_13,
  output          io_ldout_bits_uop_exceptionVec_19,
  output          io_ldout_bits_uop_exceptionVec_21,
  output [3:0]    io_ldout_bits_uop_trigger,
  output          io_ldout_bits_uop_preDecodeInfo_valid,
  output          io_ldout_bits_uop_preDecodeInfo_isRVC,
  output [1:0]    io_ldout_bits_uop_preDecodeInfo_brType,
  output          io_ldout_bits_uop_preDecodeInfo_isCall,
  output          io_ldout_bits_uop_preDecodeInfo_isRet,
  output          io_ldout_bits_uop_rfWen,
  output          io_ldout_bits_uop_fpWen,
  output          io_ldout_bits_uop_flushPipe,
  output [7:0]    io_ldout_bits_uop_pdest,
  output          io_ldout_bits_uop_robIdx_flag,
  output [7:0]    io_ldout_bits_uop_robIdx_value,
  output          io_ldout_bits_uop_debugInfo_eliminatedMove,
  output [63:0]   io_ldout_bits_uop_debugInfo_renameTime,
  output [63:0]   io_ldout_bits_uop_debugInfo_dispatchTime,
  output [63:0]   io_ldout_bits_uop_debugInfo_enqRsTime,
  output [63:0]   io_ldout_bits_uop_debugInfo_selectTime,
  output [63:0]   io_ldout_bits_uop_debugInfo_issueTime,
  output [63:0]   io_ldout_bits_uop_debugInfo_writebackTime,
  output [63:0]   io_ldout_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]   io_ldout_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]   io_ldout_bits_uop_debugInfo_tlbRespTime,
  output [55:0]   io_ldout_bits_uop_debug_seqNum_seqNum,
  output [7:0]    io_ldout_bits_uop_debug_seqNum_uopIdx,
  output          io_ldout_bits_uop_lqIdx_flag,
  output [6:0]    io_ldout_bits_uop_lqIdx_value,
  output          io_ldout_bits_uop_replayInst,
  output [63:0]   io_ldout_bits_data,
  output          io_ldout_bits_debug_isMMIO,
  output          io_ldout_bits_debug_isNCIO,
  output          io_ldout_bits_debug_isPerfCnt,
  output [47:0]   io_ldout_bits_debug_paddr,
  output [49:0]   io_ldout_bits_debug_vaddr,
  output          io_vecldin_ready,
  input           io_vecldin_valid,
  input  [63:0]   io_vecldin_bits_vaddr,
  input  [49:0]   io_vecldin_bits_basevaddr,
  input  [15:0]   io_vecldin_bits_mask,
  input  [3:0]    io_vecldin_bits_reg_offset,
  input  [2:0]    io_vecldin_bits_alignedType,
  input           io_vecldin_bits_vecActive,
  input  [31:0]   io_vecldin_bits_uop_instr,
  input  [49:0]   io_vecldin_bits_uop_pc,
  input  [9:0]    io_vecldin_bits_uop_foldpc,
  input           io_vecldin_bits_uop_exceptionVec_4,
  input           io_vecldin_bits_uop_exceptionVec_6,
  input           io_vecldin_bits_uop_exceptionVec_7,
  input           io_vecldin_bits_uop_exceptionVec_15,
  input           io_vecldin_bits_uop_exceptionVec_19,
  input           io_vecldin_bits_uop_exceptionVec_23,
  input           io_vecldin_bits_uop_isFetchMalAddr,
  input           io_vecldin_bits_uop_hasException,
  input           io_vecldin_bits_uop_preDecodeInfo_valid,
  input           io_vecldin_bits_uop_preDecodeInfo_isRVC,
  input  [1:0]    io_vecldin_bits_uop_preDecodeInfo_brType,
  input           io_vecldin_bits_uop_preDecodeInfo_isCall,
  input           io_vecldin_bits_uop_preDecodeInfo_isRet,
  input           io_vecldin_bits_uop_pred_taken,
  input           io_vecldin_bits_uop_crossPageIPFFix,
  input           io_vecldin_bits_uop_ftqPtr_flag,
  input  [5:0]    io_vecldin_bits_uop_ftqPtr_value,
  input  [3:0]    io_vecldin_bits_uop_ftqOffset,
  input           io_vecldin_bits_uop_satpFlushFirstFetchFault,
  input  [3:0]    io_vecldin_bits_uop_srcType_0,
  input  [3:0]    io_vecldin_bits_uop_srcType_1,
  input  [3:0]    io_vecldin_bits_uop_srcType_2,
  input  [3:0]    io_vecldin_bits_uop_srcType_3,
  input  [3:0]    io_vecldin_bits_uop_srcType_4,
  input  [5:0]    io_vecldin_bits_uop_ldest,
  input  [34:0]   io_vecldin_bits_uop_fuType,
  input  [8:0]    io_vecldin_bits_uop_fuOpType,
  input           io_vecldin_bits_uop_rfWen,
  input           io_vecldin_bits_uop_fpWen,
  input           io_vecldin_bits_uop_vecWen,
  input           io_vecldin_bits_uop_v0Wen,
  input           io_vecldin_bits_uop_vlWen,
  input           io_vecldin_bits_uop_isXSTrap,
  input           io_vecldin_bits_uop_waitForward,
  input           io_vecldin_bits_uop_blockBackward,
  input           io_vecldin_bits_uop_canRobCompress,
  input  [3:0]    io_vecldin_bits_uop_selImm,
  input  [1:0]    io_vecldin_bits_uop_fpu_typeTagOut,
  input           io_vecldin_bits_uop_fpu_wflags,
  input  [1:0]    io_vecldin_bits_uop_fpu_typ,
  input  [1:0]    io_vecldin_bits_uop_fpu_fmt,
  input  [2:0]    io_vecldin_bits_uop_fpu_rm,
  input           io_vecldin_bits_uop_vpu_vill,
  input           io_vecldin_bits_uop_vpu_vma,
  input           io_vecldin_bits_uop_vpu_vta,
  input  [1:0]    io_vecldin_bits_uop_vpu_vsew,
  input  [2:0]    io_vecldin_bits_uop_vpu_vlmul,
  input           io_vecldin_bits_uop_vpu_specVill,
  input           io_vecldin_bits_uop_vpu_specVma,
  input           io_vecldin_bits_uop_vpu_specVta,
  input  [1:0]    io_vecldin_bits_uop_vpu_specVsew,
  input  [2:0]    io_vecldin_bits_uop_vpu_specVlmul,
  input           io_vecldin_bits_uop_vpu_vm,
  input  [7:0]    io_vecldin_bits_uop_vpu_vstart,
  input  [2:0]    io_vecldin_bits_uop_vpu_frm,
  input           io_vecldin_bits_uop_vpu_fpu_isFpToVecInst,
  input           io_vecldin_bits_uop_vpu_fpu_isFP32Instr,
  input           io_vecldin_bits_uop_vpu_fpu_isFP64Instr,
  input           io_vecldin_bits_uop_vpu_fpu_isReduction,
  input           io_vecldin_bits_uop_vpu_fpu_isFoldTo1_2,
  input           io_vecldin_bits_uop_vpu_fpu_isFoldTo1_4,
  input           io_vecldin_bits_uop_vpu_fpu_isFoldTo1_8,
  input  [1:0]    io_vecldin_bits_uop_vpu_vxrm,
  input  [6:0]    io_vecldin_bits_uop_vpu_vuopIdx,
  input           io_vecldin_bits_uop_vpu_lastUop,
  input  [127:0]  io_vecldin_bits_uop_vpu_vmask,
  input  [7:0]    io_vecldin_bits_uop_vpu_vl,
  input  [2:0]    io_vecldin_bits_uop_vpu_nf,
  input  [1:0]    io_vecldin_bits_uop_vpu_veew,
  input           io_vecldin_bits_uop_vpu_isReverse,
  input           io_vecldin_bits_uop_vpu_isExt,
  input           io_vecldin_bits_uop_vpu_isNarrow,
  input           io_vecldin_bits_uop_vpu_isDstMask,
  input           io_vecldin_bits_uop_vpu_isOpMask,
  input           io_vecldin_bits_uop_vpu_isMove,
  input           io_vecldin_bits_uop_vpu_isDependOldVd,
  input           io_vecldin_bits_uop_vpu_isWritePartVd,
  input           io_vecldin_bits_uop_vpu_isVleff,
  input           io_vecldin_bits_uop_vlsInstr,
  input           io_vecldin_bits_uop_wfflags,
  input           io_vecldin_bits_uop_isMove,
  input           io_vecldin_bits_uop_isDropAmocasSta,
  input  [6:0]    io_vecldin_bits_uop_uopIdx,
  input           io_vecldin_bits_uop_isVset,
  input           io_vecldin_bits_uop_firstUop,
  input           io_vecldin_bits_uop_lastUop,
  input  [6:0]    io_vecldin_bits_uop_numUops,
  input  [6:0]    io_vecldin_bits_uop_numWB,
  input  [2:0]    io_vecldin_bits_uop_commitType,
  input           io_vecldin_bits_uop_srcState_0,
  input           io_vecldin_bits_uop_srcState_1,
  input           io_vecldin_bits_uop_srcState_2,
  input           io_vecldin_bits_uop_srcState_3,
  input           io_vecldin_bits_uop_srcState_4,
  input  [1:0]    io_vecldin_bits_uop_srcLoadDependency_0_0,
  input  [1:0]    io_vecldin_bits_uop_srcLoadDependency_0_1,
  input  [1:0]    io_vecldin_bits_uop_srcLoadDependency_0_2,
  input  [1:0]    io_vecldin_bits_uop_srcLoadDependency_1_0,
  input  [1:0]    io_vecldin_bits_uop_srcLoadDependency_1_1,
  input  [1:0]    io_vecldin_bits_uop_srcLoadDependency_1_2,
  input  [1:0]    io_vecldin_bits_uop_srcLoadDependency_2_0,
  input  [1:0]    io_vecldin_bits_uop_srcLoadDependency_2_1,
  input  [1:0]    io_vecldin_bits_uop_srcLoadDependency_2_2,
  input  [1:0]    io_vecldin_bits_uop_srcLoadDependency_3_0,
  input  [1:0]    io_vecldin_bits_uop_srcLoadDependency_3_1,
  input  [1:0]    io_vecldin_bits_uop_srcLoadDependency_3_2,
  input  [1:0]    io_vecldin_bits_uop_srcLoadDependency_4_0,
  input  [1:0]    io_vecldin_bits_uop_srcLoadDependency_4_1,
  input  [1:0]    io_vecldin_bits_uop_srcLoadDependency_4_2,
  input  [7:0]    io_vecldin_bits_uop_psrc_0,
  input  [7:0]    io_vecldin_bits_uop_psrc_1,
  input  [7:0]    io_vecldin_bits_uop_psrc_2,
  input  [7:0]    io_vecldin_bits_uop_psrc_3,
  input  [7:0]    io_vecldin_bits_uop_psrc_4,
  input  [7:0]    io_vecldin_bits_uop_pdest,
  input           io_vecldin_bits_uop_useRegCache_0,
  input           io_vecldin_bits_uop_useRegCache_1,
  input  [4:0]    io_vecldin_bits_uop_regCacheIdx_0,
  input  [4:0]    io_vecldin_bits_uop_regCacheIdx_1,
  input           io_vecldin_bits_uop_robIdx_flag,
  input  [7:0]    io_vecldin_bits_uop_robIdx_value,
  input  [2:0]    io_vecldin_bits_uop_instrSize,
  input           io_vecldin_bits_uop_dirtyFs,
  input           io_vecldin_bits_uop_dirtyVs,
  input  [3:0]    io_vecldin_bits_uop_traceBlockInPipe_itype,
  input  [3:0]    io_vecldin_bits_uop_traceBlockInPipe_iretire,
  input           io_vecldin_bits_uop_traceBlockInPipe_ilastsize,
  input           io_vecldin_bits_uop_eliminatedMove,
  input           io_vecldin_bits_uop_snapshot,
  input           io_vecldin_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]   io_vecldin_bits_uop_debugInfo_renameTime,
  input  [63:0]   io_vecldin_bits_uop_debugInfo_dispatchTime,
  input  [63:0]   io_vecldin_bits_uop_debugInfo_enqRsTime,
  input  [63:0]   io_vecldin_bits_uop_debugInfo_selectTime,
  input  [63:0]   io_vecldin_bits_uop_debugInfo_issueTime,
  input  [63:0]   io_vecldin_bits_uop_debugInfo_writebackTime,
  input  [63:0]   io_vecldin_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]   io_vecldin_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]   io_vecldin_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]   io_vecldin_bits_uop_debug_seqNum_seqNum,
  input  [7:0]    io_vecldin_bits_uop_debug_seqNum_uopIdx,
  input           io_vecldin_bits_uop_storeSetHit,
  input           io_vecldin_bits_uop_waitForRobIdx_flag,
  input  [7:0]    io_vecldin_bits_uop_waitForRobIdx_value,
  input           io_vecldin_bits_uop_loadWaitBit,
  input           io_vecldin_bits_uop_loadWaitStrict,
  input  [4:0]    io_vecldin_bits_uop_ssid,
  input           io_vecldin_bits_uop_lqIdx_flag,
  input  [6:0]    io_vecldin_bits_uop_lqIdx_value,
  input           io_vecldin_bits_uop_sqIdx_flag,
  input  [5:0]    io_vecldin_bits_uop_sqIdx_value,
  input           io_vecldin_bits_uop_singleStep,
  input           io_vecldin_bits_uop_replayInst,
  input  [34:0]   io_vecldin_bits_uop_debug_fuType,
  input           io_vecldin_bits_uop_debug_sim_trig,
  input  [4:0]    io_vecldin_bits_uop_numLsElem,
  input  [3:0]    io_vecldin_bits_mBIndex,
  input  [7:0]    io_vecldin_bits_elemIdx,
  input  [7:0]    io_vecldin_bits_elemIdxInsideVd,
  output          io_vecldout_valid,
  output [3:0]    io_vecldout_bits_mBIndex,
  output [3:0]    io_vecldout_bits_trigger,
  output          io_vecldout_bits_exceptionVec_3,
  output          io_vecldout_bits_exceptionVec_4,
  output          io_vecldout_bits_exceptionVec_5,
  output          io_vecldout_bits_exceptionVec_13,
  output          io_vecldout_bits_exceptionVec_19,
  output          io_vecldout_bits_exceptionVec_21,
  output          io_vecldout_bits_hasException,
  output [63:0]   io_vecldout_bits_vaddr,
  output          io_vecldout_bits_vaNeedExt,
  output [63:0]   io_vecldout_bits_gpaddr,
  output          io_vecldout_bits_isForVSnonLeafPTE,
  output [7:0]    io_vecldout_bits_vstart,
  output [15:0]   io_vecldout_bits_vecTriggerMask,
  output [7:0]    io_vecldout_bits_elemIdx,
  output [15:0]   io_vecldout_bits_mask,
  output [2:0]    io_vecldout_bits_alignedType,
  output [3:0]    io_vecldout_bits_reg_offset,
  output [7:0]    io_vecldout_bits_elemIdxInsideVd,
  output [127:0]  io_vecldout_bits_vecdata,
  output          io_misalign_ldin_ready,
  input           io_misalign_ldin_valid,
  input  [31:0]   io_misalign_ldin_bits_uop_instr,
  input  [49:0]   io_misalign_ldin_bits_uop_pc,
  input  [9:0]    io_misalign_ldin_bits_uop_foldpc,
  input           io_misalign_ldin_bits_uop_exceptionVec_0,
  input           io_misalign_ldin_bits_uop_exceptionVec_1,
  input           io_misalign_ldin_bits_uop_exceptionVec_2,
  input           io_misalign_ldin_bits_uop_exceptionVec_3,
  input           io_misalign_ldin_bits_uop_exceptionVec_4,
  input           io_misalign_ldin_bits_uop_exceptionVec_5,
  input           io_misalign_ldin_bits_uop_exceptionVec_6,
  input           io_misalign_ldin_bits_uop_exceptionVec_7,
  input           io_misalign_ldin_bits_uop_exceptionVec_8,
  input           io_misalign_ldin_bits_uop_exceptionVec_9,
  input           io_misalign_ldin_bits_uop_exceptionVec_10,
  input           io_misalign_ldin_bits_uop_exceptionVec_11,
  input           io_misalign_ldin_bits_uop_exceptionVec_12,
  input           io_misalign_ldin_bits_uop_exceptionVec_13,
  input           io_misalign_ldin_bits_uop_exceptionVec_14,
  input           io_misalign_ldin_bits_uop_exceptionVec_15,
  input           io_misalign_ldin_bits_uop_exceptionVec_16,
  input           io_misalign_ldin_bits_uop_exceptionVec_17,
  input           io_misalign_ldin_bits_uop_exceptionVec_18,
  input           io_misalign_ldin_bits_uop_exceptionVec_19,
  input           io_misalign_ldin_bits_uop_exceptionVec_20,
  input           io_misalign_ldin_bits_uop_exceptionVec_21,
  input           io_misalign_ldin_bits_uop_exceptionVec_22,
  input           io_misalign_ldin_bits_uop_exceptionVec_23,
  input           io_misalign_ldin_bits_uop_isFetchMalAddr,
  input           io_misalign_ldin_bits_uop_hasException,
  input  [3:0]    io_misalign_ldin_bits_uop_trigger,
  input           io_misalign_ldin_bits_uop_preDecodeInfo_valid,
  input           io_misalign_ldin_bits_uop_preDecodeInfo_isRVC,
  input  [1:0]    io_misalign_ldin_bits_uop_preDecodeInfo_brType,
  input           io_misalign_ldin_bits_uop_preDecodeInfo_isCall,
  input           io_misalign_ldin_bits_uop_preDecodeInfo_isRet,
  input           io_misalign_ldin_bits_uop_pred_taken,
  input           io_misalign_ldin_bits_uop_crossPageIPFFix,
  input           io_misalign_ldin_bits_uop_ftqPtr_flag,
  input  [5:0]    io_misalign_ldin_bits_uop_ftqPtr_value,
  input  [3:0]    io_misalign_ldin_bits_uop_ftqOffset,
  input           io_misalign_ldin_bits_uop_satpFlushFirstFetchFault,
  input  [3:0]    io_misalign_ldin_bits_uop_srcType_0,
  input  [3:0]    io_misalign_ldin_bits_uop_srcType_1,
  input  [3:0]    io_misalign_ldin_bits_uop_srcType_2,
  input  [3:0]    io_misalign_ldin_bits_uop_srcType_3,
  input  [3:0]    io_misalign_ldin_bits_uop_srcType_4,
  input  [5:0]    io_misalign_ldin_bits_uop_ldest,
  input  [34:0]   io_misalign_ldin_bits_uop_fuType,
  input  [8:0]    io_misalign_ldin_bits_uop_fuOpType,
  input           io_misalign_ldin_bits_uop_rfWen,
  input           io_misalign_ldin_bits_uop_fpWen,
  input           io_misalign_ldin_bits_uop_vecWen,
  input           io_misalign_ldin_bits_uop_v0Wen,
  input           io_misalign_ldin_bits_uop_vlWen,
  input           io_misalign_ldin_bits_uop_isXSTrap,
  input           io_misalign_ldin_bits_uop_waitForward,
  input           io_misalign_ldin_bits_uop_blockBackward,
  input           io_misalign_ldin_bits_uop_flushPipe,
  input           io_misalign_ldin_bits_uop_canRobCompress,
  input  [3:0]    io_misalign_ldin_bits_uop_selImm,
  input  [31:0]   io_misalign_ldin_bits_uop_imm,
  input  [1:0]    io_misalign_ldin_bits_uop_fpu_typeTagOut,
  input           io_misalign_ldin_bits_uop_fpu_wflags,
  input  [1:0]    io_misalign_ldin_bits_uop_fpu_typ,
  input  [1:0]    io_misalign_ldin_bits_uop_fpu_fmt,
  input  [2:0]    io_misalign_ldin_bits_uop_fpu_rm,
  input           io_misalign_ldin_bits_uop_vpu_vill,
  input           io_misalign_ldin_bits_uop_vpu_vma,
  input           io_misalign_ldin_bits_uop_vpu_vta,
  input  [1:0]    io_misalign_ldin_bits_uop_vpu_vsew,
  input  [2:0]    io_misalign_ldin_bits_uop_vpu_vlmul,
  input           io_misalign_ldin_bits_uop_vpu_specVill,
  input           io_misalign_ldin_bits_uop_vpu_specVma,
  input           io_misalign_ldin_bits_uop_vpu_specVta,
  input  [1:0]    io_misalign_ldin_bits_uop_vpu_specVsew,
  input  [2:0]    io_misalign_ldin_bits_uop_vpu_specVlmul,
  input           io_misalign_ldin_bits_uop_vpu_vm,
  input  [7:0]    io_misalign_ldin_bits_uop_vpu_vstart,
  input  [2:0]    io_misalign_ldin_bits_uop_vpu_frm,
  input           io_misalign_ldin_bits_uop_vpu_fpu_isFpToVecInst,
  input           io_misalign_ldin_bits_uop_vpu_fpu_isFP32Instr,
  input           io_misalign_ldin_bits_uop_vpu_fpu_isFP64Instr,
  input           io_misalign_ldin_bits_uop_vpu_fpu_isReduction,
  input           io_misalign_ldin_bits_uop_vpu_fpu_isFoldTo1_2,
  input           io_misalign_ldin_bits_uop_vpu_fpu_isFoldTo1_4,
  input           io_misalign_ldin_bits_uop_vpu_fpu_isFoldTo1_8,
  input  [1:0]    io_misalign_ldin_bits_uop_vpu_vxrm,
  input  [6:0]    io_misalign_ldin_bits_uop_vpu_vuopIdx,
  input           io_misalign_ldin_bits_uop_vpu_lastUop,
  input  [127:0]  io_misalign_ldin_bits_uop_vpu_vmask,
  input  [7:0]    io_misalign_ldin_bits_uop_vpu_vl,
  input  [2:0]    io_misalign_ldin_bits_uop_vpu_nf,
  input  [1:0]    io_misalign_ldin_bits_uop_vpu_veew,
  input           io_misalign_ldin_bits_uop_vpu_isReverse,
  input           io_misalign_ldin_bits_uop_vpu_isExt,
  input           io_misalign_ldin_bits_uop_vpu_isNarrow,
  input           io_misalign_ldin_bits_uop_vpu_isDstMask,
  input           io_misalign_ldin_bits_uop_vpu_isOpMask,
  input           io_misalign_ldin_bits_uop_vpu_isMove,
  input           io_misalign_ldin_bits_uop_vpu_isDependOldVd,
  input           io_misalign_ldin_bits_uop_vpu_isWritePartVd,
  input           io_misalign_ldin_bits_uop_vpu_isVleff,
  input           io_misalign_ldin_bits_uop_vlsInstr,
  input           io_misalign_ldin_bits_uop_wfflags,
  input           io_misalign_ldin_bits_uop_isMove,
  input           io_misalign_ldin_bits_uop_isDropAmocasSta,
  input  [6:0]    io_misalign_ldin_bits_uop_uopIdx,
  input           io_misalign_ldin_bits_uop_isVset,
  input           io_misalign_ldin_bits_uop_firstUop,
  input           io_misalign_ldin_bits_uop_lastUop,
  input  [6:0]    io_misalign_ldin_bits_uop_numUops,
  input  [6:0]    io_misalign_ldin_bits_uop_numWB,
  input  [2:0]    io_misalign_ldin_bits_uop_commitType,
  input           io_misalign_ldin_bits_uop_srcState_0,
  input           io_misalign_ldin_bits_uop_srcState_1,
  input           io_misalign_ldin_bits_uop_srcState_2,
  input           io_misalign_ldin_bits_uop_srcState_3,
  input           io_misalign_ldin_bits_uop_srcState_4,
  input  [1:0]    io_misalign_ldin_bits_uop_srcLoadDependency_0_0,
  input  [1:0]    io_misalign_ldin_bits_uop_srcLoadDependency_0_1,
  input  [1:0]    io_misalign_ldin_bits_uop_srcLoadDependency_0_2,
  input  [1:0]    io_misalign_ldin_bits_uop_srcLoadDependency_1_0,
  input  [1:0]    io_misalign_ldin_bits_uop_srcLoadDependency_1_1,
  input  [1:0]    io_misalign_ldin_bits_uop_srcLoadDependency_1_2,
  input  [1:0]    io_misalign_ldin_bits_uop_srcLoadDependency_2_0,
  input  [1:0]    io_misalign_ldin_bits_uop_srcLoadDependency_2_1,
  input  [1:0]    io_misalign_ldin_bits_uop_srcLoadDependency_2_2,
  input  [1:0]    io_misalign_ldin_bits_uop_srcLoadDependency_3_0,
  input  [1:0]    io_misalign_ldin_bits_uop_srcLoadDependency_3_1,
  input  [1:0]    io_misalign_ldin_bits_uop_srcLoadDependency_3_2,
  input  [1:0]    io_misalign_ldin_bits_uop_srcLoadDependency_4_0,
  input  [1:0]    io_misalign_ldin_bits_uop_srcLoadDependency_4_1,
  input  [1:0]    io_misalign_ldin_bits_uop_srcLoadDependency_4_2,
  input  [7:0]    io_misalign_ldin_bits_uop_psrc_0,
  input  [7:0]    io_misalign_ldin_bits_uop_psrc_1,
  input  [7:0]    io_misalign_ldin_bits_uop_psrc_2,
  input  [7:0]    io_misalign_ldin_bits_uop_psrc_3,
  input  [7:0]    io_misalign_ldin_bits_uop_psrc_4,
  input  [7:0]    io_misalign_ldin_bits_uop_pdest,
  input           io_misalign_ldin_bits_uop_useRegCache_0,
  input           io_misalign_ldin_bits_uop_useRegCache_1,
  input  [4:0]    io_misalign_ldin_bits_uop_regCacheIdx_0,
  input  [4:0]    io_misalign_ldin_bits_uop_regCacheIdx_1,
  input           io_misalign_ldin_bits_uop_robIdx_flag,
  input  [7:0]    io_misalign_ldin_bits_uop_robIdx_value,
  input  [2:0]    io_misalign_ldin_bits_uop_instrSize,
  input           io_misalign_ldin_bits_uop_dirtyFs,
  input           io_misalign_ldin_bits_uop_dirtyVs,
  input  [3:0]    io_misalign_ldin_bits_uop_traceBlockInPipe_itype,
  input  [3:0]    io_misalign_ldin_bits_uop_traceBlockInPipe_iretire,
  input           io_misalign_ldin_bits_uop_traceBlockInPipe_ilastsize,
  input           io_misalign_ldin_bits_uop_eliminatedMove,
  input           io_misalign_ldin_bits_uop_snapshot,
  input           io_misalign_ldin_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]   io_misalign_ldin_bits_uop_debugInfo_renameTime,
  input  [63:0]   io_misalign_ldin_bits_uop_debugInfo_dispatchTime,
  input  [63:0]   io_misalign_ldin_bits_uop_debugInfo_enqRsTime,
  input  [63:0]   io_misalign_ldin_bits_uop_debugInfo_selectTime,
  input  [63:0]   io_misalign_ldin_bits_uop_debugInfo_issueTime,
  input  [63:0]   io_misalign_ldin_bits_uop_debugInfo_writebackTime,
  input  [63:0]   io_misalign_ldin_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]   io_misalign_ldin_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]   io_misalign_ldin_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]   io_misalign_ldin_bits_uop_debug_seqNum_seqNum,
  input  [7:0]    io_misalign_ldin_bits_uop_debug_seqNum_uopIdx,
  input           io_misalign_ldin_bits_uop_storeSetHit,
  input           io_misalign_ldin_bits_uop_waitForRobIdx_flag,
  input  [7:0]    io_misalign_ldin_bits_uop_waitForRobIdx_value,
  input           io_misalign_ldin_bits_uop_loadWaitBit,
  input           io_misalign_ldin_bits_uop_loadWaitStrict,
  input  [4:0]    io_misalign_ldin_bits_uop_ssid,
  input           io_misalign_ldin_bits_uop_lqIdx_flag,
  input  [6:0]    io_misalign_ldin_bits_uop_lqIdx_value,
  input           io_misalign_ldin_bits_uop_sqIdx_flag,
  input  [5:0]    io_misalign_ldin_bits_uop_sqIdx_value,
  input           io_misalign_ldin_bits_uop_singleStep,
  input           io_misalign_ldin_bits_uop_replayInst,
  input  [34:0]   io_misalign_ldin_bits_uop_debug_fuType,
  input           io_misalign_ldin_bits_uop_debug_sim_trig,
  input  [4:0]    io_misalign_ldin_bits_uop_numLsElem,
  input  [49:0]   io_misalign_ldin_bits_vaddr,
  input  [63:0]   io_misalign_ldin_bits_fullva,
  input           io_misalign_ldin_bits_vaNeedExt,
  input  [47:0]   io_misalign_ldin_bits_paddr,
  input  [63:0]   io_misalign_ldin_bits_gpaddr,
  input  [15:0]   io_misalign_ldin_bits_mask,
  input           io_misalign_ldin_bits_nc,
  input           io_misalign_ldin_bits_mmio,
  input           io_misalign_ldin_bits_memBackTypeMM,
  input           io_misalign_ldin_bits_isForVSnonLeafPTE,
  input           io_misalign_ldin_bits_isvec,
  input           io_misalign_ldin_bits_is128bit,
  input           io_misalign_ldin_bits_vecActive,
  input  [3:0]    io_misalign_ldin_bits_mshrid,
  input  [6:0]    io_misalign_ldin_bits_schedIndex,
  input           io_misalign_ldin_bits_isFinalSplit,
  input           io_misalign_ldin_bits_misalignNeedWakeUp,
  output          io_misalign_ldout_valid,
  output          io_misalign_ldout_bits_uop_exceptionVec_3,
  output          io_misalign_ldout_bits_uop_exceptionVec_4,
  output          io_misalign_ldout_bits_uop_exceptionVec_5,
  output          io_misalign_ldout_bits_uop_exceptionVec_13,
  output          io_misalign_ldout_bits_uop_exceptionVec_19,
  output          io_misalign_ldout_bits_uop_exceptionVec_21,
  output [3:0]    io_misalign_ldout_bits_uop_trigger,
  output          io_misalign_ldout_bits_uop_robIdx_flag,
  output [7:0]    io_misalign_ldout_bits_uop_robIdx_value,
  output [49:0]   io_misalign_ldout_bits_vaddr,
  output [63:0]   io_misalign_ldout_bits_fullva,
  output          io_misalign_ldout_bits_vaNeedExt,
  output [47:0]   io_misalign_ldout_bits_paddr,
  output [63:0]   io_misalign_ldout_bits_gpaddr,
  output [128:0]  io_misalign_ldout_bits_data,
  output          io_misalign_ldout_bits_nc,
  output          io_misalign_ldout_bits_mmio,
  output          io_misalign_ldout_bits_memBackTypeMM,
  output          io_misalign_ldout_bits_isForVSnonLeafPTE,
  output          io_misalign_ldout_bits_vecActive,
  output          io_misalign_ldout_bits_misalignNeedWakeUp,
  output          io_misalign_ldout_bits_rep_info_cause_0,
  output          io_misalign_ldout_bits_rep_info_cause_1,
  output          io_misalign_ldout_bits_rep_info_cause_2,
  output          io_misalign_ldout_bits_rep_info_cause_3,
  output          io_misalign_ldout_bits_rep_info_cause_4,
  output          io_misalign_ldout_bits_rep_info_cause_5,
  output          io_misalign_ldout_bits_rep_info_cause_6,
  output          io_misalign_ldout_bits_rep_info_cause_7,
  output          io_misalign_ldout_bits_rep_info_cause_8,
  output          io_misalign_ldout_bits_rep_info_cause_9,
  output          io_misalign_ldout_bits_rep_info_cause_10,
  output          io_tlb_req_valid,
  output [49:0]   io_tlb_req_bits_vaddr,
  output [63:0]   io_tlb_req_bits_fullva,
  output          io_tlb_req_bits_checkfullva,
  output [2:0]    io_tlb_req_bits_cmd,
  output          io_tlb_req_bits_hyperinst,
  output          io_tlb_req_bits_hlvx,
  output          io_tlb_req_bits_kill,
  output          io_tlb_req_bits_isPrefetch,
  output          io_tlb_req_bits_no_translate,
  output [47:0]   io_tlb_req_bits_pmp_addr,
  output          io_tlb_req_bits_frm_mabuf,
  output          io_tlb_req_bits_debug_robIdx_flag,
  output [7:0]    io_tlb_req_bits_debug_robIdx_value,
  output          io_tlb_req_bits_debug_isFirstIssue,
  output          io_tlb_req_kill,
  input           io_tlb_resp_valid,
  input  [47:0]   io_tlb_resp_bits_paddr_0,
  input  [47:0]   io_tlb_resp_bits_paddr_1,
  input  [63:0]   io_tlb_resp_bits_gpaddr_0,
  input  [63:0]   io_tlb_resp_bits_fullva,
  input  [1:0]    io_tlb_resp_bits_pbmt_0,
  input           io_tlb_resp_bits_miss,
  input           io_tlb_resp_bits_isForVSnonLeafPTE,
  input           io_tlb_resp_bits_excp_0_vaNeedExt,
  input           io_tlb_resp_bits_excp_0_isHyper,
  input           io_tlb_resp_bits_excp_0_gpf_ld,
  input           io_tlb_resp_bits_excp_0_pf_ld,
  input           io_tlb_resp_bits_excp_0_af_ld,
  input           io_tlb_resp_bits_ptwBack,
  input           io_pmp_ld,
  input           io_pmp_st,
  input           io_pmp_instr,
  input           io_pmp_mmio,
  input           io_dcache_req_ready,
  output          io_dcache_req_valid,
  output [4:0]    io_dcache_req_bits_cmd,
  output [49:0]   io_dcache_req_bits_vaddr,
  output [49:0]   io_dcache_req_bits_vaddr_dup,
  output [3:0]    io_dcache_req_bits_instrtype,
  output          io_dcache_req_bits_isFirstIssue,
  output          io_dcache_req_bits_lqIdx_flag,
  output [6:0]    io_dcache_req_bits_lqIdx_value,
  input           io_dcache_resp_valid,
  input  [127:0]  io_dcache_resp_bits_data,
  input           io_dcache_resp_bits_miss,
  input  [3:0]    io_dcache_resp_bits_mshr_id,
  input  [2:0]    io_dcache_resp_bits_meta_prefetch,
  input           io_dcache_resp_bits_handled,
  input           io_dcache_resp_bits_tl_error_delayed_tl_denied,
  input           io_dcache_resp_bits_tl_error_delayed_tl_corrupt,
  output          io_dcache_s1_kill_data_read,
  output          io_dcache_s1_kill,
  output          io_dcache_s2_kill,
  output          io_dcache_is128Req,
  output [2:0]    io_dcache_pf_source,
  output [47:0]   io_dcache_s1_paddr_dup_lsu,
  output [47:0]   io_dcache_s1_paddr_dup_dcache,
  input           io_dcache_s2_bank_conflict,
  input           io_dcache_s2_mq_nack,
  output [49:0]   io_sbuffer_vaddr,
  output [47:0]   io_sbuffer_paddr,
  output          io_sbuffer_valid,
  input           io_sbuffer_forwardMask_0,
  input           io_sbuffer_forwardMask_1,
  input           io_sbuffer_forwardMask_2,
  input           io_sbuffer_forwardMask_3,
  input           io_sbuffer_forwardMask_4,
  input           io_sbuffer_forwardMask_5,
  input           io_sbuffer_forwardMask_6,
  input           io_sbuffer_forwardMask_7,
  input           io_sbuffer_forwardMask_8,
  input           io_sbuffer_forwardMask_9,
  input           io_sbuffer_forwardMask_10,
  input           io_sbuffer_forwardMask_11,
  input           io_sbuffer_forwardMask_12,
  input           io_sbuffer_forwardMask_13,
  input           io_sbuffer_forwardMask_14,
  input           io_sbuffer_forwardMask_15,
  input  [7:0]    io_sbuffer_forwardData_0,
  input  [7:0]    io_sbuffer_forwardData_1,
  input  [7:0]    io_sbuffer_forwardData_2,
  input  [7:0]    io_sbuffer_forwardData_3,
  input  [7:0]    io_sbuffer_forwardData_4,
  input  [7:0]    io_sbuffer_forwardData_5,
  input  [7:0]    io_sbuffer_forwardData_6,
  input  [7:0]    io_sbuffer_forwardData_7,
  input  [7:0]    io_sbuffer_forwardData_8,
  input  [7:0]    io_sbuffer_forwardData_9,
  input  [7:0]    io_sbuffer_forwardData_10,
  input  [7:0]    io_sbuffer_forwardData_11,
  input  [7:0]    io_sbuffer_forwardData_12,
  input  [7:0]    io_sbuffer_forwardData_13,
  input  [7:0]    io_sbuffer_forwardData_14,
  input  [7:0]    io_sbuffer_forwardData_15,
  input           io_sbuffer_matchInvalid,
  output [49:0]   io_ubuffer_vaddr,
  output [47:0]   io_ubuffer_paddr,
  output          io_ubuffer_valid,
  input           io_ubuffer_forwardMask_0,
  input           io_ubuffer_forwardMask_1,
  input           io_ubuffer_forwardMask_2,
  input           io_ubuffer_forwardMask_3,
  input           io_ubuffer_forwardMask_4,
  input           io_ubuffer_forwardMask_5,
  input           io_ubuffer_forwardMask_6,
  input           io_ubuffer_forwardMask_7,
  input           io_ubuffer_forwardMask_8,
  input           io_ubuffer_forwardMask_9,
  input           io_ubuffer_forwardMask_10,
  input           io_ubuffer_forwardMask_11,
  input           io_ubuffer_forwardMask_12,
  input           io_ubuffer_forwardMask_13,
  input           io_ubuffer_forwardMask_14,
  input           io_ubuffer_forwardMask_15,
  input  [7:0]    io_ubuffer_forwardData_0,
  input  [7:0]    io_ubuffer_forwardData_1,
  input  [7:0]    io_ubuffer_forwardData_2,
  input  [7:0]    io_ubuffer_forwardData_3,
  input  [7:0]    io_ubuffer_forwardData_4,
  input  [7:0]    io_ubuffer_forwardData_5,
  input  [7:0]    io_ubuffer_forwardData_6,
  input  [7:0]    io_ubuffer_forwardData_7,
  input  [7:0]    io_ubuffer_forwardData_8,
  input  [7:0]    io_ubuffer_forwardData_9,
  input  [7:0]    io_ubuffer_forwardData_10,
  input  [7:0]    io_ubuffer_forwardData_11,
  input  [7:0]    io_ubuffer_forwardData_12,
  input  [7:0]    io_ubuffer_forwardData_13,
  input  [7:0]    io_ubuffer_forwardData_14,
  input  [7:0]    io_ubuffer_forwardData_15,
  input           io_ubuffer_matchInvalid,
  output          io_lsq_ldin_valid,
  output [31:0]   io_lsq_ldin_bits_uop_instr,
  output [49:0]   io_lsq_ldin_bits_uop_pc,
  output [9:0]    io_lsq_ldin_bits_uop_foldpc,
  output          io_lsq_ldin_bits_uop_exceptionVec_0,
  output          io_lsq_ldin_bits_uop_exceptionVec_1,
  output          io_lsq_ldin_bits_uop_exceptionVec_2,
  output          io_lsq_ldin_bits_uop_exceptionVec_3,
  output          io_lsq_ldin_bits_uop_exceptionVec_4,
  output          io_lsq_ldin_bits_uop_exceptionVec_5,
  output          io_lsq_ldin_bits_uop_exceptionVec_6,
  output          io_lsq_ldin_bits_uop_exceptionVec_7,
  output          io_lsq_ldin_bits_uop_exceptionVec_8,
  output          io_lsq_ldin_bits_uop_exceptionVec_9,
  output          io_lsq_ldin_bits_uop_exceptionVec_10,
  output          io_lsq_ldin_bits_uop_exceptionVec_11,
  output          io_lsq_ldin_bits_uop_exceptionVec_12,
  output          io_lsq_ldin_bits_uop_exceptionVec_13,
  output          io_lsq_ldin_bits_uop_exceptionVec_14,
  output          io_lsq_ldin_bits_uop_exceptionVec_15,
  output          io_lsq_ldin_bits_uop_exceptionVec_16,
  output          io_lsq_ldin_bits_uop_exceptionVec_17,
  output          io_lsq_ldin_bits_uop_exceptionVec_18,
  output          io_lsq_ldin_bits_uop_exceptionVec_19,
  output          io_lsq_ldin_bits_uop_exceptionVec_20,
  output          io_lsq_ldin_bits_uop_exceptionVec_21,
  output          io_lsq_ldin_bits_uop_exceptionVec_22,
  output          io_lsq_ldin_bits_uop_exceptionVec_23,
  output          io_lsq_ldin_bits_uop_isFetchMalAddr,
  output          io_lsq_ldin_bits_uop_hasException,
  output [3:0]    io_lsq_ldin_bits_uop_trigger,
  output          io_lsq_ldin_bits_uop_preDecodeInfo_valid,
  output          io_lsq_ldin_bits_uop_preDecodeInfo_isRVC,
  output [1:0]    io_lsq_ldin_bits_uop_preDecodeInfo_brType,
  output          io_lsq_ldin_bits_uop_preDecodeInfo_isCall,
  output          io_lsq_ldin_bits_uop_preDecodeInfo_isRet,
  output          io_lsq_ldin_bits_uop_pred_taken,
  output          io_lsq_ldin_bits_uop_crossPageIPFFix,
  output          io_lsq_ldin_bits_uop_ftqPtr_flag,
  output [5:0]    io_lsq_ldin_bits_uop_ftqPtr_value,
  output [3:0]    io_lsq_ldin_bits_uop_ftqOffset,
  output          io_lsq_ldin_bits_uop_satpFlushFirstFetchFault,
  output [3:0]    io_lsq_ldin_bits_uop_srcType_0,
  output [3:0]    io_lsq_ldin_bits_uop_srcType_1,
  output [3:0]    io_lsq_ldin_bits_uop_srcType_2,
  output [3:0]    io_lsq_ldin_bits_uop_srcType_3,
  output [3:0]    io_lsq_ldin_bits_uop_srcType_4,
  output [5:0]    io_lsq_ldin_bits_uop_ldest,
  output [34:0]   io_lsq_ldin_bits_uop_fuType,
  output [8:0]    io_lsq_ldin_bits_uop_fuOpType,
  output          io_lsq_ldin_bits_uop_rfWen,
  output          io_lsq_ldin_bits_uop_fpWen,
  output          io_lsq_ldin_bits_uop_vecWen,
  output          io_lsq_ldin_bits_uop_v0Wen,
  output          io_lsq_ldin_bits_uop_vlWen,
  output          io_lsq_ldin_bits_uop_isXSTrap,
  output          io_lsq_ldin_bits_uop_waitForward,
  output          io_lsq_ldin_bits_uop_blockBackward,
  output          io_lsq_ldin_bits_uop_canRobCompress,
  output [3:0]    io_lsq_ldin_bits_uop_selImm,
  output [31:0]   io_lsq_ldin_bits_uop_imm,
  output [1:0]    io_lsq_ldin_bits_uop_fpu_typeTagOut,
  output          io_lsq_ldin_bits_uop_fpu_wflags,
  output [1:0]    io_lsq_ldin_bits_uop_fpu_typ,
  output [1:0]    io_lsq_ldin_bits_uop_fpu_fmt,
  output [2:0]    io_lsq_ldin_bits_uop_fpu_rm,
  output          io_lsq_ldin_bits_uop_vpu_vill,
  output          io_lsq_ldin_bits_uop_vpu_vma,
  output          io_lsq_ldin_bits_uop_vpu_vta,
  output [1:0]    io_lsq_ldin_bits_uop_vpu_vsew,
  output [2:0]    io_lsq_ldin_bits_uop_vpu_vlmul,
  output          io_lsq_ldin_bits_uop_vpu_specVill,
  output          io_lsq_ldin_bits_uop_vpu_specVma,
  output          io_lsq_ldin_bits_uop_vpu_specVta,
  output [1:0]    io_lsq_ldin_bits_uop_vpu_specVsew,
  output [2:0]    io_lsq_ldin_bits_uop_vpu_specVlmul,
  output          io_lsq_ldin_bits_uop_vpu_vm,
  output [7:0]    io_lsq_ldin_bits_uop_vpu_vstart,
  output [2:0]    io_lsq_ldin_bits_uop_vpu_frm,
  output          io_lsq_ldin_bits_uop_vpu_fpu_isFpToVecInst,
  output          io_lsq_ldin_bits_uop_vpu_fpu_isFP32Instr,
  output          io_lsq_ldin_bits_uop_vpu_fpu_isFP64Instr,
  output          io_lsq_ldin_bits_uop_vpu_fpu_isReduction,
  output          io_lsq_ldin_bits_uop_vpu_fpu_isFoldTo1_2,
  output          io_lsq_ldin_bits_uop_vpu_fpu_isFoldTo1_4,
  output          io_lsq_ldin_bits_uop_vpu_fpu_isFoldTo1_8,
  output [1:0]    io_lsq_ldin_bits_uop_vpu_vxrm,
  output [6:0]    io_lsq_ldin_bits_uop_vpu_vuopIdx,
  output          io_lsq_ldin_bits_uop_vpu_lastUop,
  output [127:0]  io_lsq_ldin_bits_uop_vpu_vmask,
  output [7:0]    io_lsq_ldin_bits_uop_vpu_vl,
  output [2:0]    io_lsq_ldin_bits_uop_vpu_nf,
  output [1:0]    io_lsq_ldin_bits_uop_vpu_veew,
  output          io_lsq_ldin_bits_uop_vpu_isReverse,
  output          io_lsq_ldin_bits_uop_vpu_isExt,
  output          io_lsq_ldin_bits_uop_vpu_isNarrow,
  output          io_lsq_ldin_bits_uop_vpu_isDstMask,
  output          io_lsq_ldin_bits_uop_vpu_isOpMask,
  output          io_lsq_ldin_bits_uop_vpu_isMove,
  output          io_lsq_ldin_bits_uop_vpu_isDependOldVd,
  output          io_lsq_ldin_bits_uop_vpu_isWritePartVd,
  output          io_lsq_ldin_bits_uop_vpu_isVleff,
  output          io_lsq_ldin_bits_uop_vlsInstr,
  output          io_lsq_ldin_bits_uop_wfflags,
  output          io_lsq_ldin_bits_uop_isMove,
  output          io_lsq_ldin_bits_uop_isDropAmocasSta,
  output [6:0]    io_lsq_ldin_bits_uop_uopIdx,
  output          io_lsq_ldin_bits_uop_isVset,
  output          io_lsq_ldin_bits_uop_firstUop,
  output          io_lsq_ldin_bits_uop_lastUop,
  output [6:0]    io_lsq_ldin_bits_uop_numUops,
  output [6:0]    io_lsq_ldin_bits_uop_numWB,
  output [2:0]    io_lsq_ldin_bits_uop_commitType,
  output          io_lsq_ldin_bits_uop_srcState_0,
  output          io_lsq_ldin_bits_uop_srcState_1,
  output          io_lsq_ldin_bits_uop_srcState_2,
  output          io_lsq_ldin_bits_uop_srcState_3,
  output          io_lsq_ldin_bits_uop_srcState_4,
  output [1:0]    io_lsq_ldin_bits_uop_srcLoadDependency_0_0,
  output [1:0]    io_lsq_ldin_bits_uop_srcLoadDependency_0_1,
  output [1:0]    io_lsq_ldin_bits_uop_srcLoadDependency_0_2,
  output [1:0]    io_lsq_ldin_bits_uop_srcLoadDependency_1_0,
  output [1:0]    io_lsq_ldin_bits_uop_srcLoadDependency_1_1,
  output [1:0]    io_lsq_ldin_bits_uop_srcLoadDependency_1_2,
  output [1:0]    io_lsq_ldin_bits_uop_srcLoadDependency_2_0,
  output [1:0]    io_lsq_ldin_bits_uop_srcLoadDependency_2_1,
  output [1:0]    io_lsq_ldin_bits_uop_srcLoadDependency_2_2,
  output [1:0]    io_lsq_ldin_bits_uop_srcLoadDependency_3_0,
  output [1:0]    io_lsq_ldin_bits_uop_srcLoadDependency_3_1,
  output [1:0]    io_lsq_ldin_bits_uop_srcLoadDependency_3_2,
  output [1:0]    io_lsq_ldin_bits_uop_srcLoadDependency_4_0,
  output [1:0]    io_lsq_ldin_bits_uop_srcLoadDependency_4_1,
  output [1:0]    io_lsq_ldin_bits_uop_srcLoadDependency_4_2,
  output [7:0]    io_lsq_ldin_bits_uop_psrc_0,
  output [7:0]    io_lsq_ldin_bits_uop_psrc_1,
  output [7:0]    io_lsq_ldin_bits_uop_psrc_2,
  output [7:0]    io_lsq_ldin_bits_uop_psrc_3,
  output [7:0]    io_lsq_ldin_bits_uop_psrc_4,
  output [7:0]    io_lsq_ldin_bits_uop_pdest,
  output          io_lsq_ldin_bits_uop_useRegCache_0,
  output          io_lsq_ldin_bits_uop_useRegCache_1,
  output [4:0]    io_lsq_ldin_bits_uop_regCacheIdx_0,
  output [4:0]    io_lsq_ldin_bits_uop_regCacheIdx_1,
  output          io_lsq_ldin_bits_uop_robIdx_flag,
  output [7:0]    io_lsq_ldin_bits_uop_robIdx_value,
  output [2:0]    io_lsq_ldin_bits_uop_instrSize,
  output          io_lsq_ldin_bits_uop_dirtyFs,
  output          io_lsq_ldin_bits_uop_dirtyVs,
  output [3:0]    io_lsq_ldin_bits_uop_traceBlockInPipe_itype,
  output [3:0]    io_lsq_ldin_bits_uop_traceBlockInPipe_iretire,
  output          io_lsq_ldin_bits_uop_traceBlockInPipe_ilastsize,
  output          io_lsq_ldin_bits_uop_eliminatedMove,
  output          io_lsq_ldin_bits_uop_snapshot,
  output          io_lsq_ldin_bits_uop_debugInfo_eliminatedMove,
  output [63:0]   io_lsq_ldin_bits_uop_debugInfo_renameTime,
  output [63:0]   io_lsq_ldin_bits_uop_debugInfo_dispatchTime,
  output [63:0]   io_lsq_ldin_bits_uop_debugInfo_enqRsTime,
  output [63:0]   io_lsq_ldin_bits_uop_debugInfo_selectTime,
  output [63:0]   io_lsq_ldin_bits_uop_debugInfo_issueTime,
  output [63:0]   io_lsq_ldin_bits_uop_debugInfo_writebackTime,
  output [63:0]   io_lsq_ldin_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]   io_lsq_ldin_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]   io_lsq_ldin_bits_uop_debugInfo_tlbRespTime,
  output [55:0]   io_lsq_ldin_bits_uop_debug_seqNum_seqNum,
  output [7:0]    io_lsq_ldin_bits_uop_debug_seqNum_uopIdx,
  output          io_lsq_ldin_bits_uop_storeSetHit,
  output          io_lsq_ldin_bits_uop_waitForRobIdx_flag,
  output [7:0]    io_lsq_ldin_bits_uop_waitForRobIdx_value,
  output          io_lsq_ldin_bits_uop_loadWaitBit,
  output          io_lsq_ldin_bits_uop_loadWaitStrict,
  output [4:0]    io_lsq_ldin_bits_uop_ssid,
  output          io_lsq_ldin_bits_uop_lqIdx_flag,
  output [6:0]    io_lsq_ldin_bits_uop_lqIdx_value,
  output          io_lsq_ldin_bits_uop_sqIdx_flag,
  output [5:0]    io_lsq_ldin_bits_uop_sqIdx_value,
  output          io_lsq_ldin_bits_uop_singleStep,
  output [34:0]   io_lsq_ldin_bits_uop_debug_fuType,
  output          io_lsq_ldin_bits_uop_debug_sim_trig,
  output [4:0]    io_lsq_ldin_bits_uop_numLsElem,
  output [49:0]   io_lsq_ldin_bits_vaddr,
  output [63:0]   io_lsq_ldin_bits_fullva,
  output          io_lsq_ldin_bits_vaNeedExt,
  output [47:0]   io_lsq_ldin_bits_paddr,
  output [63:0]   io_lsq_ldin_bits_gpaddr,
  output [15:0]   io_lsq_ldin_bits_mask,
  output          io_lsq_ldin_bits_nc,
  output          io_lsq_ldin_bits_mmio,
  output          io_lsq_ldin_bits_memBackTypeMM,
  output          io_lsq_ldin_bits_isHyper,
  output          io_lsq_ldin_bits_isForVSnonLeafPTE,
  output          io_lsq_ldin_bits_isvec,
  output          io_lsq_ldin_bits_is128bit,
  output [7:0]    io_lsq_ldin_bits_elemIdx,
  output [2:0]    io_lsq_ldin_bits_alignedType,
  output [3:0]    io_lsq_ldin_bits_mbIndex,
  output [3:0]    io_lsq_ldin_bits_reg_offset,
  output [7:0]    io_lsq_ldin_bits_elemIdxInsideVd,
  output          io_lsq_ldin_bits_vecActive,
  output          io_lsq_ldin_bits_isLoadReplay,
  output          io_lsq_ldin_bits_handledByMSHR,
  output [6:0]    io_lsq_ldin_bits_schedIndex,
  output          io_lsq_ldin_bits_updateAddrValid,
  output [3:0]    io_lsq_ldin_bits_rep_info_mshr_id,
  output          io_lsq_ldin_bits_rep_info_full_fwd,
  output          io_lsq_ldin_bits_rep_info_data_inv_sq_idx_flag,
  output [5:0]    io_lsq_ldin_bits_rep_info_data_inv_sq_idx_value,
  output          io_lsq_ldin_bits_rep_info_addr_inv_sq_idx_flag,
  output [5:0]    io_lsq_ldin_bits_rep_info_addr_inv_sq_idx_value,
  output          io_lsq_ldin_bits_rep_info_last_beat,
  output          io_lsq_ldin_bits_rep_info_cause_0,
  output          io_lsq_ldin_bits_rep_info_cause_1,
  output          io_lsq_ldin_bits_rep_info_cause_2,
  output          io_lsq_ldin_bits_rep_info_cause_3,
  output          io_lsq_ldin_bits_rep_info_cause_4,
  output          io_lsq_ldin_bits_rep_info_cause_5,
  output          io_lsq_ldin_bits_rep_info_cause_6,
  output          io_lsq_ldin_bits_rep_info_cause_7,
  output          io_lsq_ldin_bits_rep_info_cause_8,
  output          io_lsq_ldin_bits_rep_info_cause_9,
  output          io_lsq_ldin_bits_rep_info_cause_10,
  output [3:0]    io_lsq_ldin_bits_rep_info_tlb_id,
  output          io_lsq_ldin_bits_rep_info_tlb_full,
  output          io_lsq_ldin_bits_nc_with_data,
  output          io_lsq_uncache_ready,
  input           io_lsq_uncache_valid,
  input  [31:0]   io_lsq_uncache_bits_uop_instr,
  input  [49:0]   io_lsq_uncache_bits_uop_pc,
  input  [9:0]    io_lsq_uncache_bits_uop_foldpc,
  input           io_lsq_uncache_bits_uop_exceptionVec_0,
  input           io_lsq_uncache_bits_uop_exceptionVec_1,
  input           io_lsq_uncache_bits_uop_exceptionVec_2,
  input           io_lsq_uncache_bits_uop_exceptionVec_3,
  input           io_lsq_uncache_bits_uop_exceptionVec_4,
  input           io_lsq_uncache_bits_uop_exceptionVec_5,
  input           io_lsq_uncache_bits_uop_exceptionVec_6,
  input           io_lsq_uncache_bits_uop_exceptionVec_7,
  input           io_lsq_uncache_bits_uop_exceptionVec_8,
  input           io_lsq_uncache_bits_uop_exceptionVec_9,
  input           io_lsq_uncache_bits_uop_exceptionVec_10,
  input           io_lsq_uncache_bits_uop_exceptionVec_11,
  input           io_lsq_uncache_bits_uop_exceptionVec_12,
  input           io_lsq_uncache_bits_uop_exceptionVec_13,
  input           io_lsq_uncache_bits_uop_exceptionVec_14,
  input           io_lsq_uncache_bits_uop_exceptionVec_15,
  input           io_lsq_uncache_bits_uop_exceptionVec_16,
  input           io_lsq_uncache_bits_uop_exceptionVec_17,
  input           io_lsq_uncache_bits_uop_exceptionVec_18,
  input           io_lsq_uncache_bits_uop_exceptionVec_19,
  input           io_lsq_uncache_bits_uop_exceptionVec_20,
  input           io_lsq_uncache_bits_uop_exceptionVec_21,
  input           io_lsq_uncache_bits_uop_exceptionVec_22,
  input           io_lsq_uncache_bits_uop_exceptionVec_23,
  input           io_lsq_uncache_bits_uop_isFetchMalAddr,
  input           io_lsq_uncache_bits_uop_hasException,
  input  [3:0]    io_lsq_uncache_bits_uop_trigger,
  input           io_lsq_uncache_bits_uop_preDecodeInfo_valid,
  input           io_lsq_uncache_bits_uop_preDecodeInfo_isRVC,
  input  [1:0]    io_lsq_uncache_bits_uop_preDecodeInfo_brType,
  input           io_lsq_uncache_bits_uop_preDecodeInfo_isCall,
  input           io_lsq_uncache_bits_uop_preDecodeInfo_isRet,
  input           io_lsq_uncache_bits_uop_pred_taken,
  input           io_lsq_uncache_bits_uop_crossPageIPFFix,
  input           io_lsq_uncache_bits_uop_ftqPtr_flag,
  input  [5:0]    io_lsq_uncache_bits_uop_ftqPtr_value,
  input  [3:0]    io_lsq_uncache_bits_uop_ftqOffset,
  input           io_lsq_uncache_bits_uop_satpFlushFirstFetchFault,
  input  [3:0]    io_lsq_uncache_bits_uop_srcType_0,
  input  [3:0]    io_lsq_uncache_bits_uop_srcType_1,
  input  [3:0]    io_lsq_uncache_bits_uop_srcType_2,
  input  [3:0]    io_lsq_uncache_bits_uop_srcType_3,
  input  [3:0]    io_lsq_uncache_bits_uop_srcType_4,
  input  [5:0]    io_lsq_uncache_bits_uop_ldest,
  input  [34:0]   io_lsq_uncache_bits_uop_fuType,
  input  [8:0]    io_lsq_uncache_bits_uop_fuOpType,
  input           io_lsq_uncache_bits_uop_rfWen,
  input           io_lsq_uncache_bits_uop_fpWen,
  input           io_lsq_uncache_bits_uop_vecWen,
  input           io_lsq_uncache_bits_uop_v0Wen,
  input           io_lsq_uncache_bits_uop_vlWen,
  input           io_lsq_uncache_bits_uop_isXSTrap,
  input           io_lsq_uncache_bits_uop_waitForward,
  input           io_lsq_uncache_bits_uop_blockBackward,
  input           io_lsq_uncache_bits_uop_flushPipe,
  input           io_lsq_uncache_bits_uop_canRobCompress,
  input  [3:0]    io_lsq_uncache_bits_uop_selImm,
  input  [31:0]   io_lsq_uncache_bits_uop_imm,
  input  [1:0]    io_lsq_uncache_bits_uop_fpu_typeTagOut,
  input           io_lsq_uncache_bits_uop_fpu_wflags,
  input  [1:0]    io_lsq_uncache_bits_uop_fpu_typ,
  input  [1:0]    io_lsq_uncache_bits_uop_fpu_fmt,
  input  [2:0]    io_lsq_uncache_bits_uop_fpu_rm,
  input           io_lsq_uncache_bits_uop_vpu_vill,
  input           io_lsq_uncache_bits_uop_vpu_vma,
  input           io_lsq_uncache_bits_uop_vpu_vta,
  input  [1:0]    io_lsq_uncache_bits_uop_vpu_vsew,
  input  [2:0]    io_lsq_uncache_bits_uop_vpu_vlmul,
  input           io_lsq_uncache_bits_uop_vpu_specVill,
  input           io_lsq_uncache_bits_uop_vpu_specVma,
  input           io_lsq_uncache_bits_uop_vpu_specVta,
  input  [1:0]    io_lsq_uncache_bits_uop_vpu_specVsew,
  input  [2:0]    io_lsq_uncache_bits_uop_vpu_specVlmul,
  input           io_lsq_uncache_bits_uop_vpu_vm,
  input  [7:0]    io_lsq_uncache_bits_uop_vpu_vstart,
  input  [2:0]    io_lsq_uncache_bits_uop_vpu_frm,
  input           io_lsq_uncache_bits_uop_vpu_fpu_isFpToVecInst,
  input           io_lsq_uncache_bits_uop_vpu_fpu_isFP32Instr,
  input           io_lsq_uncache_bits_uop_vpu_fpu_isFP64Instr,
  input           io_lsq_uncache_bits_uop_vpu_fpu_isReduction,
  input           io_lsq_uncache_bits_uop_vpu_fpu_isFoldTo1_2,
  input           io_lsq_uncache_bits_uop_vpu_fpu_isFoldTo1_4,
  input           io_lsq_uncache_bits_uop_vpu_fpu_isFoldTo1_8,
  input  [1:0]    io_lsq_uncache_bits_uop_vpu_vxrm,
  input  [6:0]    io_lsq_uncache_bits_uop_vpu_vuopIdx,
  input           io_lsq_uncache_bits_uop_vpu_lastUop,
  input  [127:0]  io_lsq_uncache_bits_uop_vpu_vmask,
  input  [7:0]    io_lsq_uncache_bits_uop_vpu_vl,
  input  [2:0]    io_lsq_uncache_bits_uop_vpu_nf,
  input  [1:0]    io_lsq_uncache_bits_uop_vpu_veew,
  input           io_lsq_uncache_bits_uop_vpu_isReverse,
  input           io_lsq_uncache_bits_uop_vpu_isExt,
  input           io_lsq_uncache_bits_uop_vpu_isNarrow,
  input           io_lsq_uncache_bits_uop_vpu_isDstMask,
  input           io_lsq_uncache_bits_uop_vpu_isOpMask,
  input           io_lsq_uncache_bits_uop_vpu_isMove,
  input           io_lsq_uncache_bits_uop_vpu_isDependOldVd,
  input           io_lsq_uncache_bits_uop_vpu_isWritePartVd,
  input           io_lsq_uncache_bits_uop_vpu_isVleff,
  input           io_lsq_uncache_bits_uop_vlsInstr,
  input           io_lsq_uncache_bits_uop_wfflags,
  input           io_lsq_uncache_bits_uop_isMove,
  input           io_lsq_uncache_bits_uop_isDropAmocasSta,
  input  [6:0]    io_lsq_uncache_bits_uop_uopIdx,
  input           io_lsq_uncache_bits_uop_isVset,
  input           io_lsq_uncache_bits_uop_firstUop,
  input           io_lsq_uncache_bits_uop_lastUop,
  input  [6:0]    io_lsq_uncache_bits_uop_numUops,
  input  [6:0]    io_lsq_uncache_bits_uop_numWB,
  input  [2:0]    io_lsq_uncache_bits_uop_commitType,
  input           io_lsq_uncache_bits_uop_srcState_0,
  input           io_lsq_uncache_bits_uop_srcState_1,
  input           io_lsq_uncache_bits_uop_srcState_2,
  input           io_lsq_uncache_bits_uop_srcState_3,
  input           io_lsq_uncache_bits_uop_srcState_4,
  input  [1:0]    io_lsq_uncache_bits_uop_srcLoadDependency_0_0,
  input  [1:0]    io_lsq_uncache_bits_uop_srcLoadDependency_0_1,
  input  [1:0]    io_lsq_uncache_bits_uop_srcLoadDependency_0_2,
  input  [1:0]    io_lsq_uncache_bits_uop_srcLoadDependency_1_0,
  input  [1:0]    io_lsq_uncache_bits_uop_srcLoadDependency_1_1,
  input  [1:0]    io_lsq_uncache_bits_uop_srcLoadDependency_1_2,
  input  [1:0]    io_lsq_uncache_bits_uop_srcLoadDependency_2_0,
  input  [1:0]    io_lsq_uncache_bits_uop_srcLoadDependency_2_1,
  input  [1:0]    io_lsq_uncache_bits_uop_srcLoadDependency_2_2,
  input  [1:0]    io_lsq_uncache_bits_uop_srcLoadDependency_3_0,
  input  [1:0]    io_lsq_uncache_bits_uop_srcLoadDependency_3_1,
  input  [1:0]    io_lsq_uncache_bits_uop_srcLoadDependency_3_2,
  input  [1:0]    io_lsq_uncache_bits_uop_srcLoadDependency_4_0,
  input  [1:0]    io_lsq_uncache_bits_uop_srcLoadDependency_4_1,
  input  [1:0]    io_lsq_uncache_bits_uop_srcLoadDependency_4_2,
  input  [7:0]    io_lsq_uncache_bits_uop_psrc_0,
  input  [7:0]    io_lsq_uncache_bits_uop_psrc_1,
  input  [7:0]    io_lsq_uncache_bits_uop_psrc_2,
  input  [7:0]    io_lsq_uncache_bits_uop_psrc_3,
  input  [7:0]    io_lsq_uncache_bits_uop_psrc_4,
  input  [7:0]    io_lsq_uncache_bits_uop_pdest,
  input           io_lsq_uncache_bits_uop_useRegCache_0,
  input           io_lsq_uncache_bits_uop_useRegCache_1,
  input  [4:0]    io_lsq_uncache_bits_uop_regCacheIdx_0,
  input  [4:0]    io_lsq_uncache_bits_uop_regCacheIdx_1,
  input           io_lsq_uncache_bits_uop_robIdx_flag,
  input  [7:0]    io_lsq_uncache_bits_uop_robIdx_value,
  input  [2:0]    io_lsq_uncache_bits_uop_instrSize,
  input           io_lsq_uncache_bits_uop_dirtyFs,
  input           io_lsq_uncache_bits_uop_dirtyVs,
  input  [3:0]    io_lsq_uncache_bits_uop_traceBlockInPipe_itype,
  input  [3:0]    io_lsq_uncache_bits_uop_traceBlockInPipe_iretire,
  input           io_lsq_uncache_bits_uop_traceBlockInPipe_ilastsize,
  input           io_lsq_uncache_bits_uop_eliminatedMove,
  input           io_lsq_uncache_bits_uop_snapshot,
  input           io_lsq_uncache_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]   io_lsq_uncache_bits_uop_debugInfo_renameTime,
  input  [63:0]   io_lsq_uncache_bits_uop_debugInfo_dispatchTime,
  input  [63:0]   io_lsq_uncache_bits_uop_debugInfo_enqRsTime,
  input  [63:0]   io_lsq_uncache_bits_uop_debugInfo_selectTime,
  input  [63:0]   io_lsq_uncache_bits_uop_debugInfo_issueTime,
  input  [63:0]   io_lsq_uncache_bits_uop_debugInfo_writebackTime,
  input  [63:0]   io_lsq_uncache_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]   io_lsq_uncache_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]   io_lsq_uncache_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]   io_lsq_uncache_bits_uop_debug_seqNum_seqNum,
  input  [7:0]    io_lsq_uncache_bits_uop_debug_seqNum_uopIdx,
  input           io_lsq_uncache_bits_uop_storeSetHit,
  input           io_lsq_uncache_bits_uop_waitForRobIdx_flag,
  input  [7:0]    io_lsq_uncache_bits_uop_waitForRobIdx_value,
  input           io_lsq_uncache_bits_uop_loadWaitBit,
  input           io_lsq_uncache_bits_uop_loadWaitStrict,
  input  [4:0]    io_lsq_uncache_bits_uop_ssid,
  input           io_lsq_uncache_bits_uop_lqIdx_flag,
  input  [6:0]    io_lsq_uncache_bits_uop_lqIdx_value,
  input           io_lsq_uncache_bits_uop_sqIdx_flag,
  input  [5:0]    io_lsq_uncache_bits_uop_sqIdx_value,
  input           io_lsq_uncache_bits_uop_singleStep,
  input           io_lsq_uncache_bits_uop_replayInst,
  input  [34:0]   io_lsq_uncache_bits_uop_debug_fuType,
  input           io_lsq_uncache_bits_uop_debug_sim_trig,
  input  [4:0]    io_lsq_uncache_bits_uop_numLsElem,
  input           io_lsq_uncache_bits_debug_isMMIO,
  input  [47:0]   io_lsq_uncache_bits_debug_paddr,
  input  [49:0]   io_lsq_uncache_bits_debug_vaddr,
  input  [63:0]   io_lsq_ld_raw_data_lqData,
  input  [8:0]    io_lsq_ld_raw_data_uop_fuOpType,
  input           io_lsq_ld_raw_data_uop_fpWen,
  input  [2:0]    io_lsq_ld_raw_data_addrOffset,
  output          io_lsq_nc_ldin_ready,
  input           io_lsq_nc_ldin_valid,
  input  [31:0]   io_lsq_nc_ldin_bits_uop_instr,
  input  [49:0]   io_lsq_nc_ldin_bits_uop_pc,
  input  [9:0]    io_lsq_nc_ldin_bits_uop_foldpc,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_0,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_1,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_2,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_3,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_4,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_5,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_6,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_7,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_8,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_9,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_10,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_11,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_12,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_13,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_14,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_15,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_16,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_17,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_18,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_19,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_20,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_21,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_22,
  input           io_lsq_nc_ldin_bits_uop_exceptionVec_23,
  input           io_lsq_nc_ldin_bits_uop_isFetchMalAddr,
  input           io_lsq_nc_ldin_bits_uop_hasException,
  input  [3:0]    io_lsq_nc_ldin_bits_uop_trigger,
  input           io_lsq_nc_ldin_bits_uop_preDecodeInfo_valid,
  input           io_lsq_nc_ldin_bits_uop_preDecodeInfo_isRVC,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_preDecodeInfo_brType,
  input           io_lsq_nc_ldin_bits_uop_preDecodeInfo_isCall,
  input           io_lsq_nc_ldin_bits_uop_preDecodeInfo_isRet,
  input           io_lsq_nc_ldin_bits_uop_pred_taken,
  input           io_lsq_nc_ldin_bits_uop_crossPageIPFFix,
  input           io_lsq_nc_ldin_bits_uop_ftqPtr_flag,
  input  [5:0]    io_lsq_nc_ldin_bits_uop_ftqPtr_value,
  input  [3:0]    io_lsq_nc_ldin_bits_uop_ftqOffset,
  input           io_lsq_nc_ldin_bits_uop_satpFlushFirstFetchFault,
  input  [3:0]    io_lsq_nc_ldin_bits_uop_srcType_0,
  input  [3:0]    io_lsq_nc_ldin_bits_uop_srcType_1,
  input  [3:0]    io_lsq_nc_ldin_bits_uop_srcType_2,
  input  [3:0]    io_lsq_nc_ldin_bits_uop_srcType_3,
  input  [3:0]    io_lsq_nc_ldin_bits_uop_srcType_4,
  input  [5:0]    io_lsq_nc_ldin_bits_uop_ldest,
  input  [34:0]   io_lsq_nc_ldin_bits_uop_fuType,
  input  [8:0]    io_lsq_nc_ldin_bits_uop_fuOpType,
  input           io_lsq_nc_ldin_bits_uop_rfWen,
  input           io_lsq_nc_ldin_bits_uop_fpWen,
  input           io_lsq_nc_ldin_bits_uop_vecWen,
  input           io_lsq_nc_ldin_bits_uop_v0Wen,
  input           io_lsq_nc_ldin_bits_uop_vlWen,
  input           io_lsq_nc_ldin_bits_uop_isXSTrap,
  input           io_lsq_nc_ldin_bits_uop_waitForward,
  input           io_lsq_nc_ldin_bits_uop_blockBackward,
  input           io_lsq_nc_ldin_bits_uop_flushPipe,
  input           io_lsq_nc_ldin_bits_uop_canRobCompress,
  input  [3:0]    io_lsq_nc_ldin_bits_uop_selImm,
  input  [31:0]   io_lsq_nc_ldin_bits_uop_imm,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_fpu_typeTagOut,
  input           io_lsq_nc_ldin_bits_uop_fpu_wflags,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_fpu_typ,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_fpu_fmt,
  input  [2:0]    io_lsq_nc_ldin_bits_uop_fpu_rm,
  input           io_lsq_nc_ldin_bits_uop_vpu_vill,
  input           io_lsq_nc_ldin_bits_uop_vpu_vma,
  input           io_lsq_nc_ldin_bits_uop_vpu_vta,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_vpu_vsew,
  input  [2:0]    io_lsq_nc_ldin_bits_uop_vpu_vlmul,
  input           io_lsq_nc_ldin_bits_uop_vpu_specVill,
  input           io_lsq_nc_ldin_bits_uop_vpu_specVma,
  input           io_lsq_nc_ldin_bits_uop_vpu_specVta,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_vpu_specVsew,
  input  [2:0]    io_lsq_nc_ldin_bits_uop_vpu_specVlmul,
  input           io_lsq_nc_ldin_bits_uop_vpu_vm,
  input  [7:0]    io_lsq_nc_ldin_bits_uop_vpu_vstart,
  input  [2:0]    io_lsq_nc_ldin_bits_uop_vpu_frm,
  input           io_lsq_nc_ldin_bits_uop_vpu_fpu_isFpToVecInst,
  input           io_lsq_nc_ldin_bits_uop_vpu_fpu_isFP32Instr,
  input           io_lsq_nc_ldin_bits_uop_vpu_fpu_isFP64Instr,
  input           io_lsq_nc_ldin_bits_uop_vpu_fpu_isReduction,
  input           io_lsq_nc_ldin_bits_uop_vpu_fpu_isFoldTo1_2,
  input           io_lsq_nc_ldin_bits_uop_vpu_fpu_isFoldTo1_4,
  input           io_lsq_nc_ldin_bits_uop_vpu_fpu_isFoldTo1_8,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_vpu_vxrm,
  input  [6:0]    io_lsq_nc_ldin_bits_uop_vpu_vuopIdx,
  input           io_lsq_nc_ldin_bits_uop_vpu_lastUop,
  input  [127:0]  io_lsq_nc_ldin_bits_uop_vpu_vmask,
  input  [7:0]    io_lsq_nc_ldin_bits_uop_vpu_vl,
  input  [2:0]    io_lsq_nc_ldin_bits_uop_vpu_nf,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_vpu_veew,
  input           io_lsq_nc_ldin_bits_uop_vpu_isReverse,
  input           io_lsq_nc_ldin_bits_uop_vpu_isExt,
  input           io_lsq_nc_ldin_bits_uop_vpu_isNarrow,
  input           io_lsq_nc_ldin_bits_uop_vpu_isDstMask,
  input           io_lsq_nc_ldin_bits_uop_vpu_isOpMask,
  input           io_lsq_nc_ldin_bits_uop_vpu_isMove,
  input           io_lsq_nc_ldin_bits_uop_vpu_isDependOldVd,
  input           io_lsq_nc_ldin_bits_uop_vpu_isWritePartVd,
  input           io_lsq_nc_ldin_bits_uop_vpu_isVleff,
  input           io_lsq_nc_ldin_bits_uop_vlsInstr,
  input           io_lsq_nc_ldin_bits_uop_wfflags,
  input           io_lsq_nc_ldin_bits_uop_isMove,
  input           io_lsq_nc_ldin_bits_uop_isDropAmocasSta,
  input  [6:0]    io_lsq_nc_ldin_bits_uop_uopIdx,
  input           io_lsq_nc_ldin_bits_uop_isVset,
  input           io_lsq_nc_ldin_bits_uop_firstUop,
  input           io_lsq_nc_ldin_bits_uop_lastUop,
  input  [6:0]    io_lsq_nc_ldin_bits_uop_numUops,
  input  [6:0]    io_lsq_nc_ldin_bits_uop_numWB,
  input  [2:0]    io_lsq_nc_ldin_bits_uop_commitType,
  input           io_lsq_nc_ldin_bits_uop_srcState_0,
  input           io_lsq_nc_ldin_bits_uop_srcState_1,
  input           io_lsq_nc_ldin_bits_uop_srcState_2,
  input           io_lsq_nc_ldin_bits_uop_srcState_3,
  input           io_lsq_nc_ldin_bits_uop_srcState_4,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_srcLoadDependency_0_0,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_srcLoadDependency_0_1,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_srcLoadDependency_0_2,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_srcLoadDependency_1_0,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_srcLoadDependency_1_1,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_srcLoadDependency_1_2,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_srcLoadDependency_2_0,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_srcLoadDependency_2_1,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_srcLoadDependency_2_2,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_srcLoadDependency_3_0,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_srcLoadDependency_3_1,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_srcLoadDependency_3_2,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_srcLoadDependency_4_0,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_srcLoadDependency_4_1,
  input  [1:0]    io_lsq_nc_ldin_bits_uop_srcLoadDependency_4_2,
  input  [7:0]    io_lsq_nc_ldin_bits_uop_psrc_0,
  input  [7:0]    io_lsq_nc_ldin_bits_uop_psrc_1,
  input  [7:0]    io_lsq_nc_ldin_bits_uop_psrc_2,
  input  [7:0]    io_lsq_nc_ldin_bits_uop_psrc_3,
  input  [7:0]    io_lsq_nc_ldin_bits_uop_psrc_4,
  input  [7:0]    io_lsq_nc_ldin_bits_uop_pdest,
  input           io_lsq_nc_ldin_bits_uop_useRegCache_0,
  input           io_lsq_nc_ldin_bits_uop_useRegCache_1,
  input  [4:0]    io_lsq_nc_ldin_bits_uop_regCacheIdx_0,
  input  [4:0]    io_lsq_nc_ldin_bits_uop_regCacheIdx_1,
  input           io_lsq_nc_ldin_bits_uop_robIdx_flag,
  input  [7:0]    io_lsq_nc_ldin_bits_uop_robIdx_value,
  input  [2:0]    io_lsq_nc_ldin_bits_uop_instrSize,
  input           io_lsq_nc_ldin_bits_uop_dirtyFs,
  input           io_lsq_nc_ldin_bits_uop_dirtyVs,
  input  [3:0]    io_lsq_nc_ldin_bits_uop_traceBlockInPipe_itype,
  input  [3:0]    io_lsq_nc_ldin_bits_uop_traceBlockInPipe_iretire,
  input           io_lsq_nc_ldin_bits_uop_traceBlockInPipe_ilastsize,
  input           io_lsq_nc_ldin_bits_uop_eliminatedMove,
  input           io_lsq_nc_ldin_bits_uop_snapshot,
  input           io_lsq_nc_ldin_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]   io_lsq_nc_ldin_bits_uop_debugInfo_renameTime,
  input  [63:0]   io_lsq_nc_ldin_bits_uop_debugInfo_dispatchTime,
  input  [63:0]   io_lsq_nc_ldin_bits_uop_debugInfo_enqRsTime,
  input  [63:0]   io_lsq_nc_ldin_bits_uop_debugInfo_selectTime,
  input  [63:0]   io_lsq_nc_ldin_bits_uop_debugInfo_issueTime,
  input  [63:0]   io_lsq_nc_ldin_bits_uop_debugInfo_writebackTime,
  input  [63:0]   io_lsq_nc_ldin_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]   io_lsq_nc_ldin_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]   io_lsq_nc_ldin_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]   io_lsq_nc_ldin_bits_uop_debug_seqNum_seqNum,
  input  [7:0]    io_lsq_nc_ldin_bits_uop_debug_seqNum_uopIdx,
  input           io_lsq_nc_ldin_bits_uop_storeSetHit,
  input           io_lsq_nc_ldin_bits_uop_waitForRobIdx_flag,
  input  [7:0]    io_lsq_nc_ldin_bits_uop_waitForRobIdx_value,
  input           io_lsq_nc_ldin_bits_uop_loadWaitBit,
  input           io_lsq_nc_ldin_bits_uop_loadWaitStrict,
  input  [4:0]    io_lsq_nc_ldin_bits_uop_ssid,
  input           io_lsq_nc_ldin_bits_uop_lqIdx_flag,
  input  [6:0]    io_lsq_nc_ldin_bits_uop_lqIdx_value,
  input           io_lsq_nc_ldin_bits_uop_sqIdx_flag,
  input  [5:0]    io_lsq_nc_ldin_bits_uop_sqIdx_value,
  input           io_lsq_nc_ldin_bits_uop_singleStep,
  input           io_lsq_nc_ldin_bits_uop_replayInst,
  input  [34:0]   io_lsq_nc_ldin_bits_uop_debug_fuType,
  input           io_lsq_nc_ldin_bits_uop_debug_sim_trig,
  input  [4:0]    io_lsq_nc_ldin_bits_uop_numLsElem,
  input  [49:0]   io_lsq_nc_ldin_bits_vaddr,
  input  [47:0]   io_lsq_nc_ldin_bits_paddr,
  input  [128:0]  io_lsq_nc_ldin_bits_data,
  input           io_lsq_nc_ldin_bits_isvec,
  input           io_lsq_nc_ldin_bits_is128bit,
  input           io_lsq_nc_ldin_bits_vecActive,
  input  [6:0]    io_lsq_nc_ldin_bits_schedIndex,
  output [49:0]   io_lsq_forward_vaddr,
  output [47:0]   io_lsq_forward_paddr,
  output [15:0]   io_lsq_forward_mask,
  output          io_lsq_forward_uop_waitForRobIdx_flag,
  output [7:0]    io_lsq_forward_uop_waitForRobIdx_value,
  output          io_lsq_forward_uop_loadWaitBit,
  output          io_lsq_forward_uop_loadWaitStrict,
  output          io_lsq_forward_uop_sqIdx_flag,
  output [5:0]    io_lsq_forward_uop_sqIdx_value,
  output          io_lsq_forward_valid,
  input           io_lsq_forward_forwardMask_0,
  input           io_lsq_forward_forwardMask_1,
  input           io_lsq_forward_forwardMask_2,
  input           io_lsq_forward_forwardMask_3,
  input           io_lsq_forward_forwardMask_4,
  input           io_lsq_forward_forwardMask_5,
  input           io_lsq_forward_forwardMask_6,
  input           io_lsq_forward_forwardMask_7,
  input           io_lsq_forward_forwardMask_8,
  input           io_lsq_forward_forwardMask_9,
  input           io_lsq_forward_forwardMask_10,
  input           io_lsq_forward_forwardMask_11,
  input           io_lsq_forward_forwardMask_12,
  input           io_lsq_forward_forwardMask_13,
  input           io_lsq_forward_forwardMask_14,
  input           io_lsq_forward_forwardMask_15,
  input  [7:0]    io_lsq_forward_forwardData_0,
  input  [7:0]    io_lsq_forward_forwardData_1,
  input  [7:0]    io_lsq_forward_forwardData_2,
  input  [7:0]    io_lsq_forward_forwardData_3,
  input  [7:0]    io_lsq_forward_forwardData_4,
  input  [7:0]    io_lsq_forward_forwardData_5,
  input  [7:0]    io_lsq_forward_forwardData_6,
  input  [7:0]    io_lsq_forward_forwardData_7,
  input  [7:0]    io_lsq_forward_forwardData_8,
  input  [7:0]    io_lsq_forward_forwardData_9,
  input  [7:0]    io_lsq_forward_forwardData_10,
  input  [7:0]    io_lsq_forward_forwardData_11,
  input  [7:0]    io_lsq_forward_forwardData_12,
  input  [7:0]    io_lsq_forward_forwardData_13,
  input  [7:0]    io_lsq_forward_forwardData_14,
  input  [7:0]    io_lsq_forward_forwardData_15,
  output          io_lsq_forward_sqIdx_flag,
  input           io_lsq_forward_dataInvalid,
  input           io_lsq_forward_matchInvalid,
  input           io_lsq_forward_addrInvalid,
  output [55:0]   io_lsq_forward_sqIdxMask,
  input           io_lsq_forward_dataInvalidSqIdx_flag,
  input  [5:0]    io_lsq_forward_dataInvalidSqIdx_value,
  input           io_lsq_forward_addrInvalidSqIdx_flag,
  input  [5:0]    io_lsq_forward_addrInvalidSqIdx_value,
  input           io_lsq_stld_nuke_query_req_ready,
  output          io_lsq_stld_nuke_query_req_valid,
  output          io_lsq_stld_nuke_query_req_bits_uop_preDecodeInfo_isRVC,
  output          io_lsq_stld_nuke_query_req_bits_uop_ftqPtr_flag,
  output [5:0]    io_lsq_stld_nuke_query_req_bits_uop_ftqPtr_value,
  output [3:0]    io_lsq_stld_nuke_query_req_bits_uop_ftqOffset,
  output          io_lsq_stld_nuke_query_req_bits_uop_robIdx_flag,
  output [7:0]    io_lsq_stld_nuke_query_req_bits_uop_robIdx_value,
  output [63:0]   io_lsq_stld_nuke_query_req_bits_uop_debugInfo_runahead_checkpoint_id,
  output          io_lsq_stld_nuke_query_req_bits_uop_sqIdx_flag,
  output [5:0]    io_lsq_stld_nuke_query_req_bits_uop_sqIdx_value,
  output [15:0]   io_lsq_stld_nuke_query_req_bits_mask,
  output [47:0]   io_lsq_stld_nuke_query_req_bits_paddr,
  output          io_lsq_stld_nuke_query_req_bits_data_valid,
  output          io_lsq_stld_nuke_query_revoke,
  input           io_lsq_ldld_nuke_query_req_ready,
  output          io_lsq_ldld_nuke_query_req_valid,
  output          io_lsq_ldld_nuke_query_req_bits_uop_robIdx_flag,
  output [7:0]    io_lsq_ldld_nuke_query_req_bits_uop_robIdx_value,
  output          io_lsq_ldld_nuke_query_req_bits_uop_lqIdx_flag,
  output [6:0]    io_lsq_ldld_nuke_query_req_bits_uop_lqIdx_value,
  output [47:0]   io_lsq_ldld_nuke_query_req_bits_paddr,
  output          io_lsq_ldld_nuke_query_req_bits_data_valid,
  output          io_lsq_ldld_nuke_query_req_bits_is_nc,
  input           io_lsq_ldld_nuke_query_resp_valid,
  input           io_lsq_ldld_nuke_query_resp_bits_rep_frm_fetch,
  output          io_lsq_ldld_nuke_query_revoke,
  input           io_tl_d_channel_valid,
  input  [255:0]  io_tl_d_channel_data,
  input  [3:0]    io_tl_d_channel_mshrid,
  input           io_tl_d_channel_last,
  input           io_tl_d_channel_denied,
  input           io_tl_d_channel_corrupt,
  output          io_forward_mshr_valid,
  output [3:0]    io_forward_mshr_mshrid,
  output [47:0]   io_forward_mshr_paddr,
  input           io_forward_mshr_forward_mshr,
  input  [7:0]    io_forward_mshr_forwardData_0,
  input  [7:0]    io_forward_mshr_forwardData_1,
  input  [7:0]    io_forward_mshr_forwardData_2,
  input  [7:0]    io_forward_mshr_forwardData_3,
  input  [7:0]    io_forward_mshr_forwardData_4,
  input  [7:0]    io_forward_mshr_forwardData_5,
  input  [7:0]    io_forward_mshr_forwardData_6,
  input  [7:0]    io_forward_mshr_forwardData_7,
  input  [7:0]    io_forward_mshr_forwardData_8,
  input  [7:0]    io_forward_mshr_forwardData_9,
  input  [7:0]    io_forward_mshr_forwardData_10,
  input  [7:0]    io_forward_mshr_forwardData_11,
  input  [7:0]    io_forward_mshr_forwardData_12,
  input  [7:0]    io_forward_mshr_forwardData_13,
  input  [7:0]    io_forward_mshr_forwardData_14,
  input  [7:0]    io_forward_mshr_forwardData_15,
  input           io_forward_mshr_forward_result_valid,
  input           io_forward_mshr_denied,
  input           io_forward_mshr_corrupt,
  input  [3:0]    io_tlb_hint_id,
  input           io_tlb_hint_full,
  input  [1:0]    io_fromCsrTrigger_tdataVec_0_matchType,
  input           io_fromCsrTrigger_tdataVec_0_select,
  input           io_fromCsrTrigger_tdataVec_0_timing,
  input  [3:0]    io_fromCsrTrigger_tdataVec_0_action,
  input           io_fromCsrTrigger_tdataVec_0_chain,
  input           io_fromCsrTrigger_tdataVec_0_load,
  input  [63:0]   io_fromCsrTrigger_tdataVec_0_tdata2,
  input  [1:0]    io_fromCsrTrigger_tdataVec_1_matchType,
  input           io_fromCsrTrigger_tdataVec_1_select,
  input           io_fromCsrTrigger_tdataVec_1_timing,
  input  [3:0]    io_fromCsrTrigger_tdataVec_1_action,
  input           io_fromCsrTrigger_tdataVec_1_chain,
  input           io_fromCsrTrigger_tdataVec_1_load,
  input  [63:0]   io_fromCsrTrigger_tdataVec_1_tdata2,
  input  [1:0]    io_fromCsrTrigger_tdataVec_2_matchType,
  input           io_fromCsrTrigger_tdataVec_2_select,
  input           io_fromCsrTrigger_tdataVec_2_timing,
  input  [3:0]    io_fromCsrTrigger_tdataVec_2_action,
  input           io_fromCsrTrigger_tdataVec_2_chain,
  input           io_fromCsrTrigger_tdataVec_2_load,
  input  [63:0]   io_fromCsrTrigger_tdataVec_2_tdata2,
  input  [1:0]    io_fromCsrTrigger_tdataVec_3_matchType,
  input           io_fromCsrTrigger_tdataVec_3_select,
  input           io_fromCsrTrigger_tdataVec_3_timing,
  input  [3:0]    io_fromCsrTrigger_tdataVec_3_action,
  input           io_fromCsrTrigger_tdataVec_3_chain,
  input           io_fromCsrTrigger_tdataVec_3_load,
  input  [63:0]   io_fromCsrTrigger_tdataVec_3_tdata2,
  input           io_fromCsrTrigger_tEnableVec_0,
  input           io_fromCsrTrigger_tEnableVec_1,
  input           io_fromCsrTrigger_tEnableVec_2,
  input           io_fromCsrTrigger_tEnableVec_3,
  input           io_fromCsrTrigger_debugMode,
  input           io_fromCsrTrigger_triggerCanRaiseBpExp,
  output          io_prefetch_train_valid,
  output          io_prefetch_train_bits_uop_robIdx_flag,
  output [7:0]    io_prefetch_train_bits_uop_robIdx_value,
  output [49:0]   io_prefetch_train_bits_vaddr,
  output [47:0]   io_prefetch_train_bits_paddr,
  output          io_prefetch_train_bits_miss,
  output          io_prefetch_train_bits_isFirstIssue,
  output [2:0]    io_prefetch_train_bits_meta_prefetch,
  output          io_prefetch_train_l1_valid,
  output          io_prefetch_train_l1_bits_uop_robIdx_flag,
  output [7:0]    io_prefetch_train_l1_bits_uop_robIdx_value,
  output [49:0]   io_prefetch_train_l1_bits_vaddr,
  output          io_prefetch_train_l1_bits_miss,
  output          io_prefetch_train_l1_bits_isFirstIssue,
  output [2:0]    io_prefetch_train_l1_bits_meta_prefetch,
  output          io_s1_prefetch_spec,
  output          io_s2_prefetch_spec,
  output          io_s1_prefetch_spec_l1,
  output          io_s2_prefetch_spec_l1,
  input           io_prefetch_req_valid,
  input  [47:0]   io_prefetch_req_bits_paddr,
  input  [1:0]    io_prefetch_req_bits_alias,
  input           io_prefetch_req_bits_confidence,
  input           io_prefetch_req_bits_is_store,
  input  [2:0]    io_prefetch_req_bits_pf_source_value,
  output          io_canAcceptLowConfPrefetch,
  output          io_canAcceptHighConfPrefetch,
  output          io_ifetchPrefetch_valid,
  output [49:0]   io_ifetchPrefetch_bits_vaddr,
  output          io_wakeup_valid,
  output [31:0]   io_wakeup_bits_instr,
  output [49:0]   io_wakeup_bits_pc,
  output [9:0]    io_wakeup_bits_foldpc,
  output          io_wakeup_bits_exceptionVec_0,
  output          io_wakeup_bits_exceptionVec_1,
  output          io_wakeup_bits_exceptionVec_2,
  output          io_wakeup_bits_exceptionVec_3,
  output          io_wakeup_bits_exceptionVec_4,
  output          io_wakeup_bits_exceptionVec_5,
  output          io_wakeup_bits_exceptionVec_6,
  output          io_wakeup_bits_exceptionVec_7,
  output          io_wakeup_bits_exceptionVec_8,
  output          io_wakeup_bits_exceptionVec_9,
  output          io_wakeup_bits_exceptionVec_10,
  output          io_wakeup_bits_exceptionVec_11,
  output          io_wakeup_bits_exceptionVec_12,
  output          io_wakeup_bits_exceptionVec_13,
  output          io_wakeup_bits_exceptionVec_14,
  output          io_wakeup_bits_exceptionVec_15,
  output          io_wakeup_bits_exceptionVec_16,
  output          io_wakeup_bits_exceptionVec_17,
  output          io_wakeup_bits_exceptionVec_18,
  output          io_wakeup_bits_exceptionVec_19,
  output          io_wakeup_bits_exceptionVec_20,
  output          io_wakeup_bits_exceptionVec_21,
  output          io_wakeup_bits_exceptionVec_22,
  output          io_wakeup_bits_exceptionVec_23,
  output          io_wakeup_bits_isFetchMalAddr,
  output          io_wakeup_bits_hasException,
  output [3:0]    io_wakeup_bits_trigger,
  output          io_wakeup_bits_preDecodeInfo_valid,
  output          io_wakeup_bits_preDecodeInfo_isRVC,
  output [1:0]    io_wakeup_bits_preDecodeInfo_brType,
  output          io_wakeup_bits_preDecodeInfo_isCall,
  output          io_wakeup_bits_preDecodeInfo_isRet,
  output          io_wakeup_bits_pred_taken,
  output          io_wakeup_bits_crossPageIPFFix,
  output          io_wakeup_bits_ftqPtr_flag,
  output [5:0]    io_wakeup_bits_ftqPtr_value,
  output [3:0]    io_wakeup_bits_ftqOffset,
  output          io_wakeup_bits_satpFlushFirstFetchFault,
  output [3:0]    io_wakeup_bits_srcType_0,
  output [3:0]    io_wakeup_bits_srcType_1,
  output [3:0]    io_wakeup_bits_srcType_2,
  output [3:0]    io_wakeup_bits_srcType_3,
  output [3:0]    io_wakeup_bits_srcType_4,
  output [5:0]    io_wakeup_bits_ldest,
  output [34:0]   io_wakeup_bits_fuType,
  output [8:0]    io_wakeup_bits_fuOpType,
  output          io_wakeup_bits_rfWen,
  output          io_wakeup_bits_fpWen,
  output          io_wakeup_bits_vecWen,
  output          io_wakeup_bits_v0Wen,
  output          io_wakeup_bits_vlWen,
  output          io_wakeup_bits_isXSTrap,
  output          io_wakeup_bits_waitForward,
  output          io_wakeup_bits_blockBackward,
  output          io_wakeup_bits_flushPipe,
  output          io_wakeup_bits_canRobCompress,
  output [3:0]    io_wakeup_bits_selImm,
  output [31:0]   io_wakeup_bits_imm,
  output [1:0]    io_wakeup_bits_fpu_typeTagOut,
  output          io_wakeup_bits_fpu_wflags,
  output [1:0]    io_wakeup_bits_fpu_typ,
  output [1:0]    io_wakeup_bits_fpu_fmt,
  output [2:0]    io_wakeup_bits_fpu_rm,
  output          io_wakeup_bits_vpu_vill,
  output          io_wakeup_bits_vpu_vma,
  output          io_wakeup_bits_vpu_vta,
  output [1:0]    io_wakeup_bits_vpu_vsew,
  output [2:0]    io_wakeup_bits_vpu_vlmul,
  output          io_wakeup_bits_vpu_specVill,
  output          io_wakeup_bits_vpu_specVma,
  output          io_wakeup_bits_vpu_specVta,
  output [1:0]    io_wakeup_bits_vpu_specVsew,
  output [2:0]    io_wakeup_bits_vpu_specVlmul,
  output          io_wakeup_bits_vpu_vm,
  output [7:0]    io_wakeup_bits_vpu_vstart,
  output [2:0]    io_wakeup_bits_vpu_frm,
  output          io_wakeup_bits_vpu_fpu_isFpToVecInst,
  output          io_wakeup_bits_vpu_fpu_isFP32Instr,
  output          io_wakeup_bits_vpu_fpu_isFP64Instr,
  output          io_wakeup_bits_vpu_fpu_isReduction,
  output          io_wakeup_bits_vpu_fpu_isFoldTo1_2,
  output          io_wakeup_bits_vpu_fpu_isFoldTo1_4,
  output          io_wakeup_bits_vpu_fpu_isFoldTo1_8,
  output [1:0]    io_wakeup_bits_vpu_vxrm,
  output [6:0]    io_wakeup_bits_vpu_vuopIdx,
  output          io_wakeup_bits_vpu_lastUop,
  output [127:0]  io_wakeup_bits_vpu_vmask,
  output [7:0]    io_wakeup_bits_vpu_vl,
  output [2:0]    io_wakeup_bits_vpu_nf,
  output [1:0]    io_wakeup_bits_vpu_veew,
  output          io_wakeup_bits_vpu_isReverse,
  output          io_wakeup_bits_vpu_isExt,
  output          io_wakeup_bits_vpu_isNarrow,
  output          io_wakeup_bits_vpu_isDstMask,
  output          io_wakeup_bits_vpu_isOpMask,
  output          io_wakeup_bits_vpu_isMove,
  output          io_wakeup_bits_vpu_isDependOldVd,
  output          io_wakeup_bits_vpu_isWritePartVd,
  output          io_wakeup_bits_vpu_isVleff,
  output          io_wakeup_bits_vlsInstr,
  output          io_wakeup_bits_wfflags,
  output          io_wakeup_bits_isMove,
  output          io_wakeup_bits_isDropAmocasSta,
  output [6:0]    io_wakeup_bits_uopIdx,
  output          io_wakeup_bits_isVset,
  output          io_wakeup_bits_firstUop,
  output          io_wakeup_bits_lastUop,
  output [6:0]    io_wakeup_bits_numUops,
  output [6:0]    io_wakeup_bits_numWB,
  output [2:0]    io_wakeup_bits_commitType,
  output          io_wakeup_bits_srcState_0,
  output          io_wakeup_bits_srcState_1,
  output          io_wakeup_bits_srcState_2,
  output          io_wakeup_bits_srcState_3,
  output          io_wakeup_bits_srcState_4,
  output [1:0]    io_wakeup_bits_srcLoadDependency_0_0,
  output [1:0]    io_wakeup_bits_srcLoadDependency_0_1,
  output [1:0]    io_wakeup_bits_srcLoadDependency_0_2,
  output [1:0]    io_wakeup_bits_srcLoadDependency_1_0,
  output [1:0]    io_wakeup_bits_srcLoadDependency_1_1,
  output [1:0]    io_wakeup_bits_srcLoadDependency_1_2,
  output [1:0]    io_wakeup_bits_srcLoadDependency_2_0,
  output [1:0]    io_wakeup_bits_srcLoadDependency_2_1,
  output [1:0]    io_wakeup_bits_srcLoadDependency_2_2,
  output [1:0]    io_wakeup_bits_srcLoadDependency_3_0,
  output [1:0]    io_wakeup_bits_srcLoadDependency_3_1,
  output [1:0]    io_wakeup_bits_srcLoadDependency_3_2,
  output [1:0]    io_wakeup_bits_srcLoadDependency_4_0,
  output [1:0]    io_wakeup_bits_srcLoadDependency_4_1,
  output [1:0]    io_wakeup_bits_srcLoadDependency_4_2,
  output [7:0]    io_wakeup_bits_psrc_0,
  output [7:0]    io_wakeup_bits_psrc_1,
  output [7:0]    io_wakeup_bits_psrc_2,
  output [7:0]    io_wakeup_bits_psrc_3,
  output [7:0]    io_wakeup_bits_psrc_4,
  output [7:0]    io_wakeup_bits_pdest,
  output          io_wakeup_bits_useRegCache_0,
  output          io_wakeup_bits_useRegCache_1,
  output [4:0]    io_wakeup_bits_regCacheIdx_0,
  output [4:0]    io_wakeup_bits_regCacheIdx_1,
  output          io_wakeup_bits_robIdx_flag,
  output [7:0]    io_wakeup_bits_robIdx_value,
  output [2:0]    io_wakeup_bits_instrSize,
  output          io_wakeup_bits_dirtyFs,
  output          io_wakeup_bits_dirtyVs,
  output [3:0]    io_wakeup_bits_traceBlockInPipe_itype,
  output [3:0]    io_wakeup_bits_traceBlockInPipe_iretire,
  output          io_wakeup_bits_traceBlockInPipe_ilastsize,
  output          io_wakeup_bits_eliminatedMove,
  output          io_wakeup_bits_snapshot,
  output          io_wakeup_bits_debugInfo_eliminatedMove,
  output [63:0]   io_wakeup_bits_debugInfo_renameTime,
  output [63:0]   io_wakeup_bits_debugInfo_dispatchTime,
  output [63:0]   io_wakeup_bits_debugInfo_enqRsTime,
  output [63:0]   io_wakeup_bits_debugInfo_selectTime,
  output [63:0]   io_wakeup_bits_debugInfo_issueTime,
  output [63:0]   io_wakeup_bits_debugInfo_writebackTime,
  output [63:0]   io_wakeup_bits_debugInfo_runahead_checkpoint_id,
  output [63:0]   io_wakeup_bits_debugInfo_tlbFirstReqTime,
  output [63:0]   io_wakeup_bits_debugInfo_tlbRespTime,
  output [55:0]   io_wakeup_bits_debug_seqNum_seqNum,
  output [7:0]    io_wakeup_bits_debug_seqNum_uopIdx,
  output          io_wakeup_bits_storeSetHit,
  output          io_wakeup_bits_waitForRobIdx_flag,
  output [7:0]    io_wakeup_bits_waitForRobIdx_value,
  output          io_wakeup_bits_loadWaitBit,
  output          io_wakeup_bits_loadWaitStrict,
  output [4:0]    io_wakeup_bits_ssid,
  output          io_wakeup_bits_lqIdx_flag,
  output [6:0]    io_wakeup_bits_lqIdx_value,
  output          io_wakeup_bits_sqIdx_flag,
  output [5:0]    io_wakeup_bits_sqIdx_value,
  output          io_wakeup_bits_singleStep,
  output          io_wakeup_bits_replayInst,
  output [34:0]   io_wakeup_bits_debug_fuType,
  output          io_wakeup_bits_debug_sim_trig,
  output [4:0]    io_wakeup_bits_numLsElem,
  output          io_feedback_slow_valid,
  output          io_feedback_slow_bits_robIdx_flag,
  output [7:0]    io_feedback_slow_bits_robIdx_value,
  output          io_feedback_slow_bits_flushState,
  output          io_feedback_slow_bits_sqIdx_flag,
  output [5:0]    io_feedback_slow_bits_sqIdx_value,
  output          io_feedback_slow_bits_lqIdx_flag,
  output [6:0]    io_feedback_slow_bits_lqIdx_value,
  output          io_ldCancel_ld2Cancel,
  input           io_stld_nuke_query_0_valid,
  input           io_stld_nuke_query_0_bits_robIdx_flag,
  input  [7:0]    io_stld_nuke_query_0_bits_robIdx_value,
  input  [47:0]   io_stld_nuke_query_0_bits_paddr,
  input  [15:0]   io_stld_nuke_query_0_bits_mask,
  input  [1:0]    io_stld_nuke_query_0_bits_matchType,
  input           io_stld_nuke_query_1_valid,
  input           io_stld_nuke_query_1_bits_robIdx_flag,
  input  [7:0]    io_stld_nuke_query_1_bits_robIdx_value,
  input  [47:0]   io_stld_nuke_query_1_bits_paddr,
  input  [15:0]   io_stld_nuke_query_1_bits_mask,
  input  [1:0]    io_stld_nuke_query_1_bits_matchType,
  output          io_replay_ready,
  input           io_replay_valid,
  input  [31:0]   io_replay_bits_uop_instr,
  input  [49:0]   io_replay_bits_uop_pc,
  input  [9:0]    io_replay_bits_uop_foldpc,
  input           io_replay_bits_uop_exceptionVec_0,
  input           io_replay_bits_uop_exceptionVec_1,
  input           io_replay_bits_uop_exceptionVec_2,
  input           io_replay_bits_uop_exceptionVec_3,
  input           io_replay_bits_uop_exceptionVec_5,
  input           io_replay_bits_uop_exceptionVec_6,
  input           io_replay_bits_uop_exceptionVec_7,
  input           io_replay_bits_uop_exceptionVec_8,
  input           io_replay_bits_uop_exceptionVec_9,
  input           io_replay_bits_uop_exceptionVec_10,
  input           io_replay_bits_uop_exceptionVec_11,
  input           io_replay_bits_uop_exceptionVec_12,
  input           io_replay_bits_uop_exceptionVec_13,
  input           io_replay_bits_uop_exceptionVec_14,
  input           io_replay_bits_uop_exceptionVec_15,
  input           io_replay_bits_uop_exceptionVec_16,
  input           io_replay_bits_uop_exceptionVec_17,
  input           io_replay_bits_uop_exceptionVec_18,
  input           io_replay_bits_uop_exceptionVec_19,
  input           io_replay_bits_uop_exceptionVec_20,
  input           io_replay_bits_uop_exceptionVec_21,
  input           io_replay_bits_uop_exceptionVec_22,
  input           io_replay_bits_uop_exceptionVec_23,
  input           io_replay_bits_uop_isFetchMalAddr,
  input           io_replay_bits_uop_hasException,
  input  [3:0]    io_replay_bits_uop_trigger,
  input           io_replay_bits_uop_preDecodeInfo_valid,
  input           io_replay_bits_uop_preDecodeInfo_isRVC,
  input  [1:0]    io_replay_bits_uop_preDecodeInfo_brType,
  input           io_replay_bits_uop_preDecodeInfo_isCall,
  input           io_replay_bits_uop_preDecodeInfo_isRet,
  input           io_replay_bits_uop_pred_taken,
  input           io_replay_bits_uop_crossPageIPFFix,
  input           io_replay_bits_uop_ftqPtr_flag,
  input  [5:0]    io_replay_bits_uop_ftqPtr_value,
  input  [3:0]    io_replay_bits_uop_ftqOffset,
  input           io_replay_bits_uop_satpFlushFirstFetchFault,
  input  [3:0]    io_replay_bits_uop_srcType_0,
  input  [3:0]    io_replay_bits_uop_srcType_1,
  input  [3:0]    io_replay_bits_uop_srcType_2,
  input  [3:0]    io_replay_bits_uop_srcType_3,
  input  [3:0]    io_replay_bits_uop_srcType_4,
  input  [5:0]    io_replay_bits_uop_ldest,
  input  [34:0]   io_replay_bits_uop_fuType,
  input  [8:0]    io_replay_bits_uop_fuOpType,
  input           io_replay_bits_uop_rfWen,
  input           io_replay_bits_uop_fpWen,
  input           io_replay_bits_uop_vecWen,
  input           io_replay_bits_uop_v0Wen,
  input           io_replay_bits_uop_vlWen,
  input           io_replay_bits_uop_isXSTrap,
  input           io_replay_bits_uop_waitForward,
  input           io_replay_bits_uop_blockBackward,
  input           io_replay_bits_uop_canRobCompress,
  input  [3:0]    io_replay_bits_uop_selImm,
  input  [31:0]   io_replay_bits_uop_imm,
  input  [1:0]    io_replay_bits_uop_fpu_typeTagOut,
  input           io_replay_bits_uop_fpu_wflags,
  input  [1:0]    io_replay_bits_uop_fpu_typ,
  input  [1:0]    io_replay_bits_uop_fpu_fmt,
  input  [2:0]    io_replay_bits_uop_fpu_rm,
  input           io_replay_bits_uop_vpu_vill,
  input           io_replay_bits_uop_vpu_vma,
  input           io_replay_bits_uop_vpu_vta,
  input  [1:0]    io_replay_bits_uop_vpu_vsew,
  input  [2:0]    io_replay_bits_uop_vpu_vlmul,
  input           io_replay_bits_uop_vpu_specVill,
  input           io_replay_bits_uop_vpu_specVma,
  input           io_replay_bits_uop_vpu_specVta,
  input  [1:0]    io_replay_bits_uop_vpu_specVsew,
  input  [2:0]    io_replay_bits_uop_vpu_specVlmul,
  input           io_replay_bits_uop_vpu_vm,
  input  [7:0]    io_replay_bits_uop_vpu_vstart,
  input  [2:0]    io_replay_bits_uop_vpu_frm,
  input           io_replay_bits_uop_vpu_fpu_isFpToVecInst,
  input           io_replay_bits_uop_vpu_fpu_isFP32Instr,
  input           io_replay_bits_uop_vpu_fpu_isFP64Instr,
  input           io_replay_bits_uop_vpu_fpu_isReduction,
  input           io_replay_bits_uop_vpu_fpu_isFoldTo1_2,
  input           io_replay_bits_uop_vpu_fpu_isFoldTo1_4,
  input           io_replay_bits_uop_vpu_fpu_isFoldTo1_8,
  input  [1:0]    io_replay_bits_uop_vpu_vxrm,
  input  [6:0]    io_replay_bits_uop_vpu_vuopIdx,
  input           io_replay_bits_uop_vpu_lastUop,
  input  [127:0]  io_replay_bits_uop_vpu_vmask,
  input  [7:0]    io_replay_bits_uop_vpu_vl,
  input  [2:0]    io_replay_bits_uop_vpu_nf,
  input  [1:0]    io_replay_bits_uop_vpu_veew,
  input           io_replay_bits_uop_vpu_isReverse,
  input           io_replay_bits_uop_vpu_isExt,
  input           io_replay_bits_uop_vpu_isNarrow,
  input           io_replay_bits_uop_vpu_isDstMask,
  input           io_replay_bits_uop_vpu_isOpMask,
  input           io_replay_bits_uop_vpu_isMove,
  input           io_replay_bits_uop_vpu_isDependOldVd,
  input           io_replay_bits_uop_vpu_isWritePartVd,
  input           io_replay_bits_uop_vpu_isVleff,
  input           io_replay_bits_uop_vlsInstr,
  input           io_replay_bits_uop_wfflags,
  input           io_replay_bits_uop_isMove,
  input           io_replay_bits_uop_isDropAmocasSta,
  input  [6:0]    io_replay_bits_uop_uopIdx,
  input           io_replay_bits_uop_isVset,
  input           io_replay_bits_uop_firstUop,
  input           io_replay_bits_uop_lastUop,
  input  [6:0]    io_replay_bits_uop_numUops,
  input  [6:0]    io_replay_bits_uop_numWB,
  input  [2:0]    io_replay_bits_uop_commitType,
  input           io_replay_bits_uop_srcState_0,
  input           io_replay_bits_uop_srcState_1,
  input           io_replay_bits_uop_srcState_2,
  input           io_replay_bits_uop_srcState_3,
  input           io_replay_bits_uop_srcState_4,
  input  [1:0]    io_replay_bits_uop_srcLoadDependency_0_0,
  input  [1:0]    io_replay_bits_uop_srcLoadDependency_0_1,
  input  [1:0]    io_replay_bits_uop_srcLoadDependency_0_2,
  input  [1:0]    io_replay_bits_uop_srcLoadDependency_1_0,
  input  [1:0]    io_replay_bits_uop_srcLoadDependency_1_1,
  input  [1:0]    io_replay_bits_uop_srcLoadDependency_1_2,
  input  [1:0]    io_replay_bits_uop_srcLoadDependency_2_0,
  input  [1:0]    io_replay_bits_uop_srcLoadDependency_2_1,
  input  [1:0]    io_replay_bits_uop_srcLoadDependency_2_2,
  input  [1:0]    io_replay_bits_uop_srcLoadDependency_3_0,
  input  [1:0]    io_replay_bits_uop_srcLoadDependency_3_1,
  input  [1:0]    io_replay_bits_uop_srcLoadDependency_3_2,
  input  [1:0]    io_replay_bits_uop_srcLoadDependency_4_0,
  input  [1:0]    io_replay_bits_uop_srcLoadDependency_4_1,
  input  [1:0]    io_replay_bits_uop_srcLoadDependency_4_2,
  input  [7:0]    io_replay_bits_uop_psrc_0,
  input  [7:0]    io_replay_bits_uop_psrc_1,
  input  [7:0]    io_replay_bits_uop_psrc_2,
  input  [7:0]    io_replay_bits_uop_psrc_3,
  input  [7:0]    io_replay_bits_uop_psrc_4,
  input  [7:0]    io_replay_bits_uop_pdest,
  input           io_replay_bits_uop_useRegCache_0,
  input           io_replay_bits_uop_useRegCache_1,
  input  [4:0]    io_replay_bits_uop_regCacheIdx_0,
  input  [4:0]    io_replay_bits_uop_regCacheIdx_1,
  input           io_replay_bits_uop_robIdx_flag,
  input  [7:0]    io_replay_bits_uop_robIdx_value,
  input  [2:0]    io_replay_bits_uop_instrSize,
  input           io_replay_bits_uop_dirtyFs,
  input           io_replay_bits_uop_dirtyVs,
  input  [3:0]    io_replay_bits_uop_traceBlockInPipe_itype,
  input  [3:0]    io_replay_bits_uop_traceBlockInPipe_iretire,
  input           io_replay_bits_uop_traceBlockInPipe_ilastsize,
  input           io_replay_bits_uop_eliminatedMove,
  input           io_replay_bits_uop_snapshot,
  input           io_replay_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]   io_replay_bits_uop_debugInfo_renameTime,
  input  [63:0]   io_replay_bits_uop_debugInfo_dispatchTime,
  input  [63:0]   io_replay_bits_uop_debugInfo_enqRsTime,
  input  [63:0]   io_replay_bits_uop_debugInfo_selectTime,
  input  [63:0]   io_replay_bits_uop_debugInfo_issueTime,
  input  [63:0]   io_replay_bits_uop_debugInfo_writebackTime,
  input  [63:0]   io_replay_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]   io_replay_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]   io_replay_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]   io_replay_bits_uop_debug_seqNum_seqNum,
  input  [7:0]    io_replay_bits_uop_debug_seqNum_uopIdx,
  input           io_replay_bits_uop_storeSetHit,
  input           io_replay_bits_uop_waitForRobIdx_flag,
  input  [7:0]    io_replay_bits_uop_waitForRobIdx_value,
  input           io_replay_bits_uop_loadWaitBit,
  input  [4:0]    io_replay_bits_uop_ssid,
  input           io_replay_bits_uop_lqIdx_flag,
  input  [6:0]    io_replay_bits_uop_lqIdx_value,
  input           io_replay_bits_uop_sqIdx_flag,
  input  [5:0]    io_replay_bits_uop_sqIdx_value,
  input           io_replay_bits_uop_singleStep,
  input  [34:0]   io_replay_bits_uop_debug_fuType,
  input           io_replay_bits_uop_debug_sim_trig,
  input  [4:0]    io_replay_bits_uop_numLsElem,
  input  [49:0]   io_replay_bits_vaddr,
  input  [15:0]   io_replay_bits_mask,
  input           io_replay_bits_isvec,
  input           io_replay_bits_is128bit,
  input  [7:0]    io_replay_bits_elemIdx,
  input  [2:0]    io_replay_bits_alignedType,
  input  [3:0]    io_replay_bits_mbIndex,
  input  [3:0]    io_replay_bits_reg_offset,
  input  [7:0]    io_replay_bits_elemIdxInsideVd,
  input           io_replay_bits_vecActive,
  input  [3:0]    io_replay_bits_mshrid,
  input           io_replay_bits_forward_tlDchannel,
  input  [6:0]    io_replay_bits_schedIndex,
  output          io_s2_ptr_chasing,
  input           io_fast_rep_in_valid,
  input  [31:0]   io_fast_rep_in_bits_uop_instr,
  input  [49:0]   io_fast_rep_in_bits_uop_pc,
  input  [9:0]    io_fast_rep_in_bits_uop_foldpc,
  input           io_fast_rep_in_bits_uop_exceptionVec_0,
  input           io_fast_rep_in_bits_uop_exceptionVec_1,
  input           io_fast_rep_in_bits_uop_exceptionVec_2,
  input           io_fast_rep_in_bits_uop_exceptionVec_3,
  input           io_fast_rep_in_bits_uop_exceptionVec_4,
  input           io_fast_rep_in_bits_uop_exceptionVec_5,
  input           io_fast_rep_in_bits_uop_exceptionVec_6,
  input           io_fast_rep_in_bits_uop_exceptionVec_7,
  input           io_fast_rep_in_bits_uop_exceptionVec_8,
  input           io_fast_rep_in_bits_uop_exceptionVec_9,
  input           io_fast_rep_in_bits_uop_exceptionVec_10,
  input           io_fast_rep_in_bits_uop_exceptionVec_11,
  input           io_fast_rep_in_bits_uop_exceptionVec_12,
  input           io_fast_rep_in_bits_uop_exceptionVec_13,
  input           io_fast_rep_in_bits_uop_exceptionVec_14,
  input           io_fast_rep_in_bits_uop_exceptionVec_15,
  input           io_fast_rep_in_bits_uop_exceptionVec_16,
  input           io_fast_rep_in_bits_uop_exceptionVec_17,
  input           io_fast_rep_in_bits_uop_exceptionVec_18,
  input           io_fast_rep_in_bits_uop_exceptionVec_19,
  input           io_fast_rep_in_bits_uop_exceptionVec_20,
  input           io_fast_rep_in_bits_uop_exceptionVec_21,
  input           io_fast_rep_in_bits_uop_exceptionVec_22,
  input           io_fast_rep_in_bits_uop_exceptionVec_23,
  input           io_fast_rep_in_bits_uop_isFetchMalAddr,
  input           io_fast_rep_in_bits_uop_hasException,
  input  [3:0]    io_fast_rep_in_bits_uop_trigger,
  input           io_fast_rep_in_bits_uop_preDecodeInfo_valid,
  input           io_fast_rep_in_bits_uop_preDecodeInfo_isRVC,
  input  [1:0]    io_fast_rep_in_bits_uop_preDecodeInfo_brType,
  input           io_fast_rep_in_bits_uop_preDecodeInfo_isCall,
  input           io_fast_rep_in_bits_uop_preDecodeInfo_isRet,
  input           io_fast_rep_in_bits_uop_pred_taken,
  input           io_fast_rep_in_bits_uop_crossPageIPFFix,
  input           io_fast_rep_in_bits_uop_ftqPtr_flag,
  input  [5:0]    io_fast_rep_in_bits_uop_ftqPtr_value,
  input  [3:0]    io_fast_rep_in_bits_uop_ftqOffset,
  input           io_fast_rep_in_bits_uop_satpFlushFirstFetchFault,
  input  [3:0]    io_fast_rep_in_bits_uop_srcType_0,
  input  [3:0]    io_fast_rep_in_bits_uop_srcType_1,
  input  [3:0]    io_fast_rep_in_bits_uop_srcType_2,
  input  [3:0]    io_fast_rep_in_bits_uop_srcType_3,
  input  [3:0]    io_fast_rep_in_bits_uop_srcType_4,
  input  [5:0]    io_fast_rep_in_bits_uop_ldest,
  input  [34:0]   io_fast_rep_in_bits_uop_fuType,
  input  [8:0]    io_fast_rep_in_bits_uop_fuOpType,
  input           io_fast_rep_in_bits_uop_rfWen,
  input           io_fast_rep_in_bits_uop_fpWen,
  input           io_fast_rep_in_bits_uop_vecWen,
  input           io_fast_rep_in_bits_uop_v0Wen,
  input           io_fast_rep_in_bits_uop_vlWen,
  input           io_fast_rep_in_bits_uop_isXSTrap,
  input           io_fast_rep_in_bits_uop_waitForward,
  input           io_fast_rep_in_bits_uop_blockBackward,
  input           io_fast_rep_in_bits_uop_canRobCompress,
  input  [3:0]    io_fast_rep_in_bits_uop_selImm,
  input  [31:0]   io_fast_rep_in_bits_uop_imm,
  input  [1:0]    io_fast_rep_in_bits_uop_fpu_typeTagOut,
  input           io_fast_rep_in_bits_uop_fpu_wflags,
  input  [1:0]    io_fast_rep_in_bits_uop_fpu_typ,
  input  [1:0]    io_fast_rep_in_bits_uop_fpu_fmt,
  input  [2:0]    io_fast_rep_in_bits_uop_fpu_rm,
  input           io_fast_rep_in_bits_uop_vpu_vill,
  input           io_fast_rep_in_bits_uop_vpu_vma,
  input           io_fast_rep_in_bits_uop_vpu_vta,
  input  [1:0]    io_fast_rep_in_bits_uop_vpu_vsew,
  input  [2:0]    io_fast_rep_in_bits_uop_vpu_vlmul,
  input           io_fast_rep_in_bits_uop_vpu_specVill,
  input           io_fast_rep_in_bits_uop_vpu_specVma,
  input           io_fast_rep_in_bits_uop_vpu_specVta,
  input  [1:0]    io_fast_rep_in_bits_uop_vpu_specVsew,
  input  [2:0]    io_fast_rep_in_bits_uop_vpu_specVlmul,
  input           io_fast_rep_in_bits_uop_vpu_vm,
  input  [7:0]    io_fast_rep_in_bits_uop_vpu_vstart,
  input  [2:0]    io_fast_rep_in_bits_uop_vpu_frm,
  input           io_fast_rep_in_bits_uop_vpu_fpu_isFpToVecInst,
  input           io_fast_rep_in_bits_uop_vpu_fpu_isFP32Instr,
  input           io_fast_rep_in_bits_uop_vpu_fpu_isFP64Instr,
  input           io_fast_rep_in_bits_uop_vpu_fpu_isReduction,
  input           io_fast_rep_in_bits_uop_vpu_fpu_isFoldTo1_2,
  input           io_fast_rep_in_bits_uop_vpu_fpu_isFoldTo1_4,
  input           io_fast_rep_in_bits_uop_vpu_fpu_isFoldTo1_8,
  input  [1:0]    io_fast_rep_in_bits_uop_vpu_vxrm,
  input  [6:0]    io_fast_rep_in_bits_uop_vpu_vuopIdx,
  input           io_fast_rep_in_bits_uop_vpu_lastUop,
  input  [127:0]  io_fast_rep_in_bits_uop_vpu_vmask,
  input  [7:0]    io_fast_rep_in_bits_uop_vpu_vl,
  input  [2:0]    io_fast_rep_in_bits_uop_vpu_nf,
  input  [1:0]    io_fast_rep_in_bits_uop_vpu_veew,
  input           io_fast_rep_in_bits_uop_vpu_isReverse,
  input           io_fast_rep_in_bits_uop_vpu_isExt,
  input           io_fast_rep_in_bits_uop_vpu_isNarrow,
  input           io_fast_rep_in_bits_uop_vpu_isDstMask,
  input           io_fast_rep_in_bits_uop_vpu_isOpMask,
  input           io_fast_rep_in_bits_uop_vpu_isMove,
  input           io_fast_rep_in_bits_uop_vpu_isDependOldVd,
  input           io_fast_rep_in_bits_uop_vpu_isWritePartVd,
  input           io_fast_rep_in_bits_uop_vpu_isVleff,
  input           io_fast_rep_in_bits_uop_vlsInstr,
  input           io_fast_rep_in_bits_uop_wfflags,
  input           io_fast_rep_in_bits_uop_isMove,
  input           io_fast_rep_in_bits_uop_isDropAmocasSta,
  input  [6:0]    io_fast_rep_in_bits_uop_uopIdx,
  input           io_fast_rep_in_bits_uop_isVset,
  input           io_fast_rep_in_bits_uop_firstUop,
  input           io_fast_rep_in_bits_uop_lastUop,
  input  [6:0]    io_fast_rep_in_bits_uop_numUops,
  input  [6:0]    io_fast_rep_in_bits_uop_numWB,
  input  [2:0]    io_fast_rep_in_bits_uop_commitType,
  input           io_fast_rep_in_bits_uop_srcState_0,
  input           io_fast_rep_in_bits_uop_srcState_1,
  input           io_fast_rep_in_bits_uop_srcState_2,
  input           io_fast_rep_in_bits_uop_srcState_3,
  input           io_fast_rep_in_bits_uop_srcState_4,
  input  [1:0]    io_fast_rep_in_bits_uop_srcLoadDependency_0_0,
  input  [1:0]    io_fast_rep_in_bits_uop_srcLoadDependency_0_1,
  input  [1:0]    io_fast_rep_in_bits_uop_srcLoadDependency_0_2,
  input  [1:0]    io_fast_rep_in_bits_uop_srcLoadDependency_1_0,
  input  [1:0]    io_fast_rep_in_bits_uop_srcLoadDependency_1_1,
  input  [1:0]    io_fast_rep_in_bits_uop_srcLoadDependency_1_2,
  input  [1:0]    io_fast_rep_in_bits_uop_srcLoadDependency_2_0,
  input  [1:0]    io_fast_rep_in_bits_uop_srcLoadDependency_2_1,
  input  [1:0]    io_fast_rep_in_bits_uop_srcLoadDependency_2_2,
  input  [1:0]    io_fast_rep_in_bits_uop_srcLoadDependency_3_0,
  input  [1:0]    io_fast_rep_in_bits_uop_srcLoadDependency_3_1,
  input  [1:0]    io_fast_rep_in_bits_uop_srcLoadDependency_3_2,
  input  [1:0]    io_fast_rep_in_bits_uop_srcLoadDependency_4_0,
  input  [1:0]    io_fast_rep_in_bits_uop_srcLoadDependency_4_1,
  input  [1:0]    io_fast_rep_in_bits_uop_srcLoadDependency_4_2,
  input  [7:0]    io_fast_rep_in_bits_uop_psrc_0,
  input  [7:0]    io_fast_rep_in_bits_uop_psrc_1,
  input  [7:0]    io_fast_rep_in_bits_uop_psrc_2,
  input  [7:0]    io_fast_rep_in_bits_uop_psrc_3,
  input  [7:0]    io_fast_rep_in_bits_uop_psrc_4,
  input  [7:0]    io_fast_rep_in_bits_uop_pdest,
  input           io_fast_rep_in_bits_uop_useRegCache_0,
  input           io_fast_rep_in_bits_uop_useRegCache_1,
  input  [4:0]    io_fast_rep_in_bits_uop_regCacheIdx_0,
  input  [4:0]    io_fast_rep_in_bits_uop_regCacheIdx_1,
  input           io_fast_rep_in_bits_uop_robIdx_flag,
  input  [7:0]    io_fast_rep_in_bits_uop_robIdx_value,
  input  [2:0]    io_fast_rep_in_bits_uop_instrSize,
  input           io_fast_rep_in_bits_uop_dirtyFs,
  input           io_fast_rep_in_bits_uop_dirtyVs,
  input  [3:0]    io_fast_rep_in_bits_uop_traceBlockInPipe_itype,
  input  [3:0]    io_fast_rep_in_bits_uop_traceBlockInPipe_iretire,
  input           io_fast_rep_in_bits_uop_traceBlockInPipe_ilastsize,
  input           io_fast_rep_in_bits_uop_eliminatedMove,
  input           io_fast_rep_in_bits_uop_snapshot,
  input           io_fast_rep_in_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]   io_fast_rep_in_bits_uop_debugInfo_renameTime,
  input  [63:0]   io_fast_rep_in_bits_uop_debugInfo_dispatchTime,
  input  [63:0]   io_fast_rep_in_bits_uop_debugInfo_enqRsTime,
  input  [63:0]   io_fast_rep_in_bits_uop_debugInfo_selectTime,
  input  [63:0]   io_fast_rep_in_bits_uop_debugInfo_issueTime,
  input  [63:0]   io_fast_rep_in_bits_uop_debugInfo_writebackTime,
  input  [63:0]   io_fast_rep_in_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]   io_fast_rep_in_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]   io_fast_rep_in_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]   io_fast_rep_in_bits_uop_debug_seqNum_seqNum,
  input  [7:0]    io_fast_rep_in_bits_uop_debug_seqNum_uopIdx,
  input           io_fast_rep_in_bits_uop_storeSetHit,
  input           io_fast_rep_in_bits_uop_waitForRobIdx_flag,
  input  [7:0]    io_fast_rep_in_bits_uop_waitForRobIdx_value,
  input           io_fast_rep_in_bits_uop_loadWaitBit,
  input           io_fast_rep_in_bits_uop_loadWaitStrict,
  input  [4:0]    io_fast_rep_in_bits_uop_ssid,
  input           io_fast_rep_in_bits_uop_lqIdx_flag,
  input  [6:0]    io_fast_rep_in_bits_uop_lqIdx_value,
  input           io_fast_rep_in_bits_uop_sqIdx_flag,
  input  [5:0]    io_fast_rep_in_bits_uop_sqIdx_value,
  input           io_fast_rep_in_bits_uop_singleStep,
  input           io_fast_rep_in_bits_uop_replayInst,
  input  [34:0]   io_fast_rep_in_bits_uop_debug_fuType,
  input           io_fast_rep_in_bits_uop_debug_sim_trig,
  input  [4:0]    io_fast_rep_in_bits_uop_numLsElem,
  input  [49:0]   io_fast_rep_in_bits_vaddr,
  input  [47:0]   io_fast_rep_in_bits_paddr,
  input  [15:0]   io_fast_rep_in_bits_mask,
  input  [128:0]  io_fast_rep_in_bits_data,
  input           io_fast_rep_in_bits_isvec,
  input           io_fast_rep_in_bits_is128bit,
  input  [7:0]    io_fast_rep_in_bits_elemIdx,
  input  [2:0]    io_fast_rep_in_bits_alignedType,
  input  [3:0]    io_fast_rep_in_bits_mbIndex,
  input  [3:0]    io_fast_rep_in_bits_reg_offset,
  input  [7:0]    io_fast_rep_in_bits_elemIdxInsideVd,
  input           io_fast_rep_in_bits_vecActive,
  input           io_fast_rep_in_bits_isLoadReplay,
  input           io_fast_rep_in_bits_hasROBEntry,
  input           io_fast_rep_in_bits_lateKill,
  input  [6:0]    io_fast_rep_in_bits_schedIndex,
  input           io_fast_rep_in_bits_isFrmMisAlignBuf,
  input  [3:0]    io_fast_rep_in_bits_rep_info_mshr_id,
  output          io_fast_rep_out_valid,
  output [31:0]   io_fast_rep_out_bits_uop_instr,
  output [49:0]   io_fast_rep_out_bits_uop_pc,
  output [9:0]    io_fast_rep_out_bits_uop_foldpc,
  output          io_fast_rep_out_bits_uop_exceptionVec_0,
  output          io_fast_rep_out_bits_uop_exceptionVec_1,
  output          io_fast_rep_out_bits_uop_exceptionVec_2,
  output          io_fast_rep_out_bits_uop_exceptionVec_3,
  output          io_fast_rep_out_bits_uop_exceptionVec_4,
  output          io_fast_rep_out_bits_uop_exceptionVec_5,
  output          io_fast_rep_out_bits_uop_exceptionVec_6,
  output          io_fast_rep_out_bits_uop_exceptionVec_7,
  output          io_fast_rep_out_bits_uop_exceptionVec_8,
  output          io_fast_rep_out_bits_uop_exceptionVec_9,
  output          io_fast_rep_out_bits_uop_exceptionVec_10,
  output          io_fast_rep_out_bits_uop_exceptionVec_11,
  output          io_fast_rep_out_bits_uop_exceptionVec_12,
  output          io_fast_rep_out_bits_uop_exceptionVec_13,
  output          io_fast_rep_out_bits_uop_exceptionVec_14,
  output          io_fast_rep_out_bits_uop_exceptionVec_15,
  output          io_fast_rep_out_bits_uop_exceptionVec_16,
  output          io_fast_rep_out_bits_uop_exceptionVec_17,
  output          io_fast_rep_out_bits_uop_exceptionVec_18,
  output          io_fast_rep_out_bits_uop_exceptionVec_19,
  output          io_fast_rep_out_bits_uop_exceptionVec_20,
  output          io_fast_rep_out_bits_uop_exceptionVec_21,
  output          io_fast_rep_out_bits_uop_exceptionVec_22,
  output          io_fast_rep_out_bits_uop_exceptionVec_23,
  output          io_fast_rep_out_bits_uop_isFetchMalAddr,
  output          io_fast_rep_out_bits_uop_hasException,
  output [3:0]    io_fast_rep_out_bits_uop_trigger,
  output          io_fast_rep_out_bits_uop_preDecodeInfo_valid,
  output          io_fast_rep_out_bits_uop_preDecodeInfo_isRVC,
  output [1:0]    io_fast_rep_out_bits_uop_preDecodeInfo_brType,
  output          io_fast_rep_out_bits_uop_preDecodeInfo_isCall,
  output          io_fast_rep_out_bits_uop_preDecodeInfo_isRet,
  output          io_fast_rep_out_bits_uop_pred_taken,
  output          io_fast_rep_out_bits_uop_crossPageIPFFix,
  output          io_fast_rep_out_bits_uop_ftqPtr_flag,
  output [5:0]    io_fast_rep_out_bits_uop_ftqPtr_value,
  output [3:0]    io_fast_rep_out_bits_uop_ftqOffset,
  output          io_fast_rep_out_bits_uop_satpFlushFirstFetchFault,
  output [3:0]    io_fast_rep_out_bits_uop_srcType_0,
  output [3:0]    io_fast_rep_out_bits_uop_srcType_1,
  output [3:0]    io_fast_rep_out_bits_uop_srcType_2,
  output [3:0]    io_fast_rep_out_bits_uop_srcType_3,
  output [3:0]    io_fast_rep_out_bits_uop_srcType_4,
  output [5:0]    io_fast_rep_out_bits_uop_ldest,
  output [34:0]   io_fast_rep_out_bits_uop_fuType,
  output [8:0]    io_fast_rep_out_bits_uop_fuOpType,
  output          io_fast_rep_out_bits_uop_rfWen,
  output          io_fast_rep_out_bits_uop_fpWen,
  output          io_fast_rep_out_bits_uop_vecWen,
  output          io_fast_rep_out_bits_uop_v0Wen,
  output          io_fast_rep_out_bits_uop_vlWen,
  output          io_fast_rep_out_bits_uop_isXSTrap,
  output          io_fast_rep_out_bits_uop_waitForward,
  output          io_fast_rep_out_bits_uop_blockBackward,
  output          io_fast_rep_out_bits_uop_canRobCompress,
  output [3:0]    io_fast_rep_out_bits_uop_selImm,
  output [31:0]   io_fast_rep_out_bits_uop_imm,
  output [1:0]    io_fast_rep_out_bits_uop_fpu_typeTagOut,
  output          io_fast_rep_out_bits_uop_fpu_wflags,
  output [1:0]    io_fast_rep_out_bits_uop_fpu_typ,
  output [1:0]    io_fast_rep_out_bits_uop_fpu_fmt,
  output [2:0]    io_fast_rep_out_bits_uop_fpu_rm,
  output          io_fast_rep_out_bits_uop_vpu_vill,
  output          io_fast_rep_out_bits_uop_vpu_vma,
  output          io_fast_rep_out_bits_uop_vpu_vta,
  output [1:0]    io_fast_rep_out_bits_uop_vpu_vsew,
  output [2:0]    io_fast_rep_out_bits_uop_vpu_vlmul,
  output          io_fast_rep_out_bits_uop_vpu_specVill,
  output          io_fast_rep_out_bits_uop_vpu_specVma,
  output          io_fast_rep_out_bits_uop_vpu_specVta,
  output [1:0]    io_fast_rep_out_bits_uop_vpu_specVsew,
  output [2:0]    io_fast_rep_out_bits_uop_vpu_specVlmul,
  output          io_fast_rep_out_bits_uop_vpu_vm,
  output [7:0]    io_fast_rep_out_bits_uop_vpu_vstart,
  output [2:0]    io_fast_rep_out_bits_uop_vpu_frm,
  output          io_fast_rep_out_bits_uop_vpu_fpu_isFpToVecInst,
  output          io_fast_rep_out_bits_uop_vpu_fpu_isFP32Instr,
  output          io_fast_rep_out_bits_uop_vpu_fpu_isFP64Instr,
  output          io_fast_rep_out_bits_uop_vpu_fpu_isReduction,
  output          io_fast_rep_out_bits_uop_vpu_fpu_isFoldTo1_2,
  output          io_fast_rep_out_bits_uop_vpu_fpu_isFoldTo1_4,
  output          io_fast_rep_out_bits_uop_vpu_fpu_isFoldTo1_8,
  output [1:0]    io_fast_rep_out_bits_uop_vpu_vxrm,
  output [6:0]    io_fast_rep_out_bits_uop_vpu_vuopIdx,
  output          io_fast_rep_out_bits_uop_vpu_lastUop,
  output [127:0]  io_fast_rep_out_bits_uop_vpu_vmask,
  output [7:0]    io_fast_rep_out_bits_uop_vpu_vl,
  output [2:0]    io_fast_rep_out_bits_uop_vpu_nf,
  output [1:0]    io_fast_rep_out_bits_uop_vpu_veew,
  output          io_fast_rep_out_bits_uop_vpu_isReverse,
  output          io_fast_rep_out_bits_uop_vpu_isExt,
  output          io_fast_rep_out_bits_uop_vpu_isNarrow,
  output          io_fast_rep_out_bits_uop_vpu_isDstMask,
  output          io_fast_rep_out_bits_uop_vpu_isOpMask,
  output          io_fast_rep_out_bits_uop_vpu_isMove,
  output          io_fast_rep_out_bits_uop_vpu_isDependOldVd,
  output          io_fast_rep_out_bits_uop_vpu_isWritePartVd,
  output          io_fast_rep_out_bits_uop_vpu_isVleff,
  output          io_fast_rep_out_bits_uop_vlsInstr,
  output          io_fast_rep_out_bits_uop_wfflags,
  output          io_fast_rep_out_bits_uop_isMove,
  output          io_fast_rep_out_bits_uop_isDropAmocasSta,
  output [6:0]    io_fast_rep_out_bits_uop_uopIdx,
  output          io_fast_rep_out_bits_uop_isVset,
  output          io_fast_rep_out_bits_uop_firstUop,
  output          io_fast_rep_out_bits_uop_lastUop,
  output [6:0]    io_fast_rep_out_bits_uop_numUops,
  output [6:0]    io_fast_rep_out_bits_uop_numWB,
  output [2:0]    io_fast_rep_out_bits_uop_commitType,
  output          io_fast_rep_out_bits_uop_srcState_0,
  output          io_fast_rep_out_bits_uop_srcState_1,
  output          io_fast_rep_out_bits_uop_srcState_2,
  output          io_fast_rep_out_bits_uop_srcState_3,
  output          io_fast_rep_out_bits_uop_srcState_4,
  output [1:0]    io_fast_rep_out_bits_uop_srcLoadDependency_0_0,
  output [1:0]    io_fast_rep_out_bits_uop_srcLoadDependency_0_1,
  output [1:0]    io_fast_rep_out_bits_uop_srcLoadDependency_0_2,
  output [1:0]    io_fast_rep_out_bits_uop_srcLoadDependency_1_0,
  output [1:0]    io_fast_rep_out_bits_uop_srcLoadDependency_1_1,
  output [1:0]    io_fast_rep_out_bits_uop_srcLoadDependency_1_2,
  output [1:0]    io_fast_rep_out_bits_uop_srcLoadDependency_2_0,
  output [1:0]    io_fast_rep_out_bits_uop_srcLoadDependency_2_1,
  output [1:0]    io_fast_rep_out_bits_uop_srcLoadDependency_2_2,
  output [1:0]    io_fast_rep_out_bits_uop_srcLoadDependency_3_0,
  output [1:0]    io_fast_rep_out_bits_uop_srcLoadDependency_3_1,
  output [1:0]    io_fast_rep_out_bits_uop_srcLoadDependency_3_2,
  output [1:0]    io_fast_rep_out_bits_uop_srcLoadDependency_4_0,
  output [1:0]    io_fast_rep_out_bits_uop_srcLoadDependency_4_1,
  output [1:0]    io_fast_rep_out_bits_uop_srcLoadDependency_4_2,
  output [7:0]    io_fast_rep_out_bits_uop_psrc_0,
  output [7:0]    io_fast_rep_out_bits_uop_psrc_1,
  output [7:0]    io_fast_rep_out_bits_uop_psrc_2,
  output [7:0]    io_fast_rep_out_bits_uop_psrc_3,
  output [7:0]    io_fast_rep_out_bits_uop_psrc_4,
  output [7:0]    io_fast_rep_out_bits_uop_pdest,
  output          io_fast_rep_out_bits_uop_useRegCache_0,
  output          io_fast_rep_out_bits_uop_useRegCache_1,
  output [4:0]    io_fast_rep_out_bits_uop_regCacheIdx_0,
  output [4:0]    io_fast_rep_out_bits_uop_regCacheIdx_1,
  output          io_fast_rep_out_bits_uop_robIdx_flag,
  output [7:0]    io_fast_rep_out_bits_uop_robIdx_value,
  output [2:0]    io_fast_rep_out_bits_uop_instrSize,
  output          io_fast_rep_out_bits_uop_dirtyFs,
  output          io_fast_rep_out_bits_uop_dirtyVs,
  output [3:0]    io_fast_rep_out_bits_uop_traceBlockInPipe_itype,
  output [3:0]    io_fast_rep_out_bits_uop_traceBlockInPipe_iretire,
  output          io_fast_rep_out_bits_uop_traceBlockInPipe_ilastsize,
  output          io_fast_rep_out_bits_uop_eliminatedMove,
  output          io_fast_rep_out_bits_uop_snapshot,
  output          io_fast_rep_out_bits_uop_debugInfo_eliminatedMove,
  output [63:0]   io_fast_rep_out_bits_uop_debugInfo_renameTime,
  output [63:0]   io_fast_rep_out_bits_uop_debugInfo_dispatchTime,
  output [63:0]   io_fast_rep_out_bits_uop_debugInfo_enqRsTime,
  output [63:0]   io_fast_rep_out_bits_uop_debugInfo_selectTime,
  output [63:0]   io_fast_rep_out_bits_uop_debugInfo_issueTime,
  output [63:0]   io_fast_rep_out_bits_uop_debugInfo_writebackTime,
  output [63:0]   io_fast_rep_out_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]   io_fast_rep_out_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]   io_fast_rep_out_bits_uop_debugInfo_tlbRespTime,
  output [55:0]   io_fast_rep_out_bits_uop_debug_seqNum_seqNum,
  output [7:0]    io_fast_rep_out_bits_uop_debug_seqNum_uopIdx,
  output          io_fast_rep_out_bits_uop_storeSetHit,
  output          io_fast_rep_out_bits_uop_waitForRobIdx_flag,
  output [7:0]    io_fast_rep_out_bits_uop_waitForRobIdx_value,
  output          io_fast_rep_out_bits_uop_loadWaitBit,
  output          io_fast_rep_out_bits_uop_loadWaitStrict,
  output [4:0]    io_fast_rep_out_bits_uop_ssid,
  output          io_fast_rep_out_bits_uop_lqIdx_flag,
  output [6:0]    io_fast_rep_out_bits_uop_lqIdx_value,
  output          io_fast_rep_out_bits_uop_sqIdx_flag,
  output [5:0]    io_fast_rep_out_bits_uop_sqIdx_value,
  output          io_fast_rep_out_bits_uop_singleStep,
  output          io_fast_rep_out_bits_uop_replayInst,
  output [34:0]   io_fast_rep_out_bits_uop_debug_fuType,
  output          io_fast_rep_out_bits_uop_debug_sim_trig,
  output [4:0]    io_fast_rep_out_bits_uop_numLsElem,
  output [49:0]   io_fast_rep_out_bits_vaddr,
  output [47:0]   io_fast_rep_out_bits_paddr,
  output [15:0]   io_fast_rep_out_bits_mask,
  output [128:0]  io_fast_rep_out_bits_data,
  output          io_fast_rep_out_bits_isvec,
  output          io_fast_rep_out_bits_is128bit,
  output [7:0]    io_fast_rep_out_bits_elemIdx,
  output [2:0]    io_fast_rep_out_bits_alignedType,
  output [3:0]    io_fast_rep_out_bits_mbIndex,
  output [3:0]    io_fast_rep_out_bits_reg_offset,
  output [7:0]    io_fast_rep_out_bits_elemIdxInsideVd,
  output          io_fast_rep_out_bits_vecActive,
  output          io_fast_rep_out_bits_isLoadReplay,
  output          io_fast_rep_out_bits_hasROBEntry,
  output          io_fast_rep_out_bits_lateKill,
  output [6:0]    io_fast_rep_out_bits_schedIndex,
  output          io_fast_rep_out_bits_isFrmMisAlignBuf,
  output [3:0]    io_fast_rep_out_bits_rep_info_mshr_id,
  input           io_misalign_enq_req_ready,
  output          io_misalign_enq_req_valid,
  output [31:0]   io_misalign_enq_req_bits_uop_instr,
  output [49:0]   io_misalign_enq_req_bits_uop_pc,
  output [9:0]    io_misalign_enq_req_bits_uop_foldpc,
  output          io_misalign_enq_req_bits_uop_exceptionVec_0,
  output          io_misalign_enq_req_bits_uop_exceptionVec_1,
  output          io_misalign_enq_req_bits_uop_exceptionVec_2,
  output          io_misalign_enq_req_bits_uop_exceptionVec_3,
  output          io_misalign_enq_req_bits_uop_exceptionVec_5,
  output          io_misalign_enq_req_bits_uop_exceptionVec_6,
  output          io_misalign_enq_req_bits_uop_exceptionVec_7,
  output          io_misalign_enq_req_bits_uop_exceptionVec_8,
  output          io_misalign_enq_req_bits_uop_exceptionVec_9,
  output          io_misalign_enq_req_bits_uop_exceptionVec_10,
  output          io_misalign_enq_req_bits_uop_exceptionVec_11,
  output          io_misalign_enq_req_bits_uop_exceptionVec_12,
  output          io_misalign_enq_req_bits_uop_exceptionVec_13,
  output          io_misalign_enq_req_bits_uop_exceptionVec_14,
  output          io_misalign_enq_req_bits_uop_exceptionVec_15,
  output          io_misalign_enq_req_bits_uop_exceptionVec_16,
  output          io_misalign_enq_req_bits_uop_exceptionVec_17,
  output          io_misalign_enq_req_bits_uop_exceptionVec_18,
  output          io_misalign_enq_req_bits_uop_exceptionVec_19,
  output          io_misalign_enq_req_bits_uop_exceptionVec_20,
  output          io_misalign_enq_req_bits_uop_exceptionVec_21,
  output          io_misalign_enq_req_bits_uop_exceptionVec_22,
  output          io_misalign_enq_req_bits_uop_exceptionVec_23,
  output          io_misalign_enq_req_bits_uop_isFetchMalAddr,
  output          io_misalign_enq_req_bits_uop_hasException,
  output [3:0]    io_misalign_enq_req_bits_uop_trigger,
  output          io_misalign_enq_req_bits_uop_preDecodeInfo_valid,
  output          io_misalign_enq_req_bits_uop_preDecodeInfo_isRVC,
  output [1:0]    io_misalign_enq_req_bits_uop_preDecodeInfo_brType,
  output          io_misalign_enq_req_bits_uop_preDecodeInfo_isCall,
  output          io_misalign_enq_req_bits_uop_preDecodeInfo_isRet,
  output          io_misalign_enq_req_bits_uop_pred_taken,
  output          io_misalign_enq_req_bits_uop_crossPageIPFFix,
  output          io_misalign_enq_req_bits_uop_ftqPtr_flag,
  output [5:0]    io_misalign_enq_req_bits_uop_ftqPtr_value,
  output [3:0]    io_misalign_enq_req_bits_uop_ftqOffset,
  output          io_misalign_enq_req_bits_uop_satpFlushFirstFetchFault,
  output [3:0]    io_misalign_enq_req_bits_uop_srcType_0,
  output [3:0]    io_misalign_enq_req_bits_uop_srcType_1,
  output [3:0]    io_misalign_enq_req_bits_uop_srcType_2,
  output [3:0]    io_misalign_enq_req_bits_uop_srcType_3,
  output [3:0]    io_misalign_enq_req_bits_uop_srcType_4,
  output [5:0]    io_misalign_enq_req_bits_uop_ldest,
  output [34:0]   io_misalign_enq_req_bits_uop_fuType,
  output [8:0]    io_misalign_enq_req_bits_uop_fuOpType,
  output          io_misalign_enq_req_bits_uop_rfWen,
  output          io_misalign_enq_req_bits_uop_fpWen,
  output          io_misalign_enq_req_bits_uop_vecWen,
  output          io_misalign_enq_req_bits_uop_v0Wen,
  output          io_misalign_enq_req_bits_uop_vlWen,
  output          io_misalign_enq_req_bits_uop_isXSTrap,
  output          io_misalign_enq_req_bits_uop_waitForward,
  output          io_misalign_enq_req_bits_uop_blockBackward,
  output          io_misalign_enq_req_bits_uop_canRobCompress,
  output [3:0]    io_misalign_enq_req_bits_uop_selImm,
  output [31:0]   io_misalign_enq_req_bits_uop_imm,
  output [1:0]    io_misalign_enq_req_bits_uop_fpu_typeTagOut,
  output          io_misalign_enq_req_bits_uop_fpu_wflags,
  output [1:0]    io_misalign_enq_req_bits_uop_fpu_typ,
  output [1:0]    io_misalign_enq_req_bits_uop_fpu_fmt,
  output [2:0]    io_misalign_enq_req_bits_uop_fpu_rm,
  output          io_misalign_enq_req_bits_uop_vpu_vill,
  output          io_misalign_enq_req_bits_uop_vpu_vma,
  output          io_misalign_enq_req_bits_uop_vpu_vta,
  output [1:0]    io_misalign_enq_req_bits_uop_vpu_vsew,
  output [2:0]    io_misalign_enq_req_bits_uop_vpu_vlmul,
  output          io_misalign_enq_req_bits_uop_vpu_specVill,
  output          io_misalign_enq_req_bits_uop_vpu_specVma,
  output          io_misalign_enq_req_bits_uop_vpu_specVta,
  output [1:0]    io_misalign_enq_req_bits_uop_vpu_specVsew,
  output [2:0]    io_misalign_enq_req_bits_uop_vpu_specVlmul,
  output          io_misalign_enq_req_bits_uop_vpu_vm,
  output [7:0]    io_misalign_enq_req_bits_uop_vpu_vstart,
  output [2:0]    io_misalign_enq_req_bits_uop_vpu_frm,
  output          io_misalign_enq_req_bits_uop_vpu_fpu_isFpToVecInst,
  output          io_misalign_enq_req_bits_uop_vpu_fpu_isFP32Instr,
  output          io_misalign_enq_req_bits_uop_vpu_fpu_isFP64Instr,
  output          io_misalign_enq_req_bits_uop_vpu_fpu_isReduction,
  output          io_misalign_enq_req_bits_uop_vpu_fpu_isFoldTo1_2,
  output          io_misalign_enq_req_bits_uop_vpu_fpu_isFoldTo1_4,
  output          io_misalign_enq_req_bits_uop_vpu_fpu_isFoldTo1_8,
  output [1:0]    io_misalign_enq_req_bits_uop_vpu_vxrm,
  output [6:0]    io_misalign_enq_req_bits_uop_vpu_vuopIdx,
  output          io_misalign_enq_req_bits_uop_vpu_lastUop,
  output [127:0]  io_misalign_enq_req_bits_uop_vpu_vmask,
  output [7:0]    io_misalign_enq_req_bits_uop_vpu_vl,
  output [2:0]    io_misalign_enq_req_bits_uop_vpu_nf,
  output [1:0]    io_misalign_enq_req_bits_uop_vpu_veew,
  output          io_misalign_enq_req_bits_uop_vpu_isReverse,
  output          io_misalign_enq_req_bits_uop_vpu_isExt,
  output          io_misalign_enq_req_bits_uop_vpu_isNarrow,
  output          io_misalign_enq_req_bits_uop_vpu_isDstMask,
  output          io_misalign_enq_req_bits_uop_vpu_isOpMask,
  output          io_misalign_enq_req_bits_uop_vpu_isMove,
  output          io_misalign_enq_req_bits_uop_vpu_isDependOldVd,
  output          io_misalign_enq_req_bits_uop_vpu_isWritePartVd,
  output          io_misalign_enq_req_bits_uop_vpu_isVleff,
  output          io_misalign_enq_req_bits_uop_vlsInstr,
  output          io_misalign_enq_req_bits_uop_wfflags,
  output          io_misalign_enq_req_bits_uop_isMove,
  output          io_misalign_enq_req_bits_uop_isDropAmocasSta,
  output [6:0]    io_misalign_enq_req_bits_uop_uopIdx,
  output          io_misalign_enq_req_bits_uop_isVset,
  output          io_misalign_enq_req_bits_uop_firstUop,
  output          io_misalign_enq_req_bits_uop_lastUop,
  output [6:0]    io_misalign_enq_req_bits_uop_numUops,
  output [6:0]    io_misalign_enq_req_bits_uop_numWB,
  output [2:0]    io_misalign_enq_req_bits_uop_commitType,
  output          io_misalign_enq_req_bits_uop_srcState_0,
  output          io_misalign_enq_req_bits_uop_srcState_1,
  output          io_misalign_enq_req_bits_uop_srcState_2,
  output          io_misalign_enq_req_bits_uop_srcState_3,
  output          io_misalign_enq_req_bits_uop_srcState_4,
  output [1:0]    io_misalign_enq_req_bits_uop_srcLoadDependency_0_0,
  output [1:0]    io_misalign_enq_req_bits_uop_srcLoadDependency_0_1,
  output [1:0]    io_misalign_enq_req_bits_uop_srcLoadDependency_0_2,
  output [1:0]    io_misalign_enq_req_bits_uop_srcLoadDependency_1_0,
  output [1:0]    io_misalign_enq_req_bits_uop_srcLoadDependency_1_1,
  output [1:0]    io_misalign_enq_req_bits_uop_srcLoadDependency_1_2,
  output [1:0]    io_misalign_enq_req_bits_uop_srcLoadDependency_2_0,
  output [1:0]    io_misalign_enq_req_bits_uop_srcLoadDependency_2_1,
  output [1:0]    io_misalign_enq_req_bits_uop_srcLoadDependency_2_2,
  output [1:0]    io_misalign_enq_req_bits_uop_srcLoadDependency_3_0,
  output [1:0]    io_misalign_enq_req_bits_uop_srcLoadDependency_3_1,
  output [1:0]    io_misalign_enq_req_bits_uop_srcLoadDependency_3_2,
  output [1:0]    io_misalign_enq_req_bits_uop_srcLoadDependency_4_0,
  output [1:0]    io_misalign_enq_req_bits_uop_srcLoadDependency_4_1,
  output [1:0]    io_misalign_enq_req_bits_uop_srcLoadDependency_4_2,
  output [7:0]    io_misalign_enq_req_bits_uop_psrc_0,
  output [7:0]    io_misalign_enq_req_bits_uop_psrc_1,
  output [7:0]    io_misalign_enq_req_bits_uop_psrc_2,
  output [7:0]    io_misalign_enq_req_bits_uop_psrc_3,
  output [7:0]    io_misalign_enq_req_bits_uop_psrc_4,
  output [7:0]    io_misalign_enq_req_bits_uop_pdest,
  output          io_misalign_enq_req_bits_uop_useRegCache_0,
  output          io_misalign_enq_req_bits_uop_useRegCache_1,
  output [4:0]    io_misalign_enq_req_bits_uop_regCacheIdx_0,
  output [4:0]    io_misalign_enq_req_bits_uop_regCacheIdx_1,
  output          io_misalign_enq_req_bits_uop_robIdx_flag,
  output [7:0]    io_misalign_enq_req_bits_uop_robIdx_value,
  output [2:0]    io_misalign_enq_req_bits_uop_instrSize,
  output          io_misalign_enq_req_bits_uop_dirtyFs,
  output          io_misalign_enq_req_bits_uop_dirtyVs,
  output [3:0]    io_misalign_enq_req_bits_uop_traceBlockInPipe_itype,
  output [3:0]    io_misalign_enq_req_bits_uop_traceBlockInPipe_iretire,
  output          io_misalign_enq_req_bits_uop_traceBlockInPipe_ilastsize,
  output          io_misalign_enq_req_bits_uop_eliminatedMove,
  output          io_misalign_enq_req_bits_uop_snapshot,
  output          io_misalign_enq_req_bits_uop_debugInfo_eliminatedMove,
  output [63:0]   io_misalign_enq_req_bits_uop_debugInfo_renameTime,
  output [63:0]   io_misalign_enq_req_bits_uop_debugInfo_dispatchTime,
  output [63:0]   io_misalign_enq_req_bits_uop_debugInfo_enqRsTime,
  output [63:0]   io_misalign_enq_req_bits_uop_debugInfo_selectTime,
  output [63:0]   io_misalign_enq_req_bits_uop_debugInfo_issueTime,
  output [63:0]   io_misalign_enq_req_bits_uop_debugInfo_writebackTime,
  output [63:0]   io_misalign_enq_req_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]   io_misalign_enq_req_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]   io_misalign_enq_req_bits_uop_debugInfo_tlbRespTime,
  output [55:0]   io_misalign_enq_req_bits_uop_debug_seqNum_seqNum,
  output [7:0]    io_misalign_enq_req_bits_uop_debug_seqNum_uopIdx,
  output          io_misalign_enq_req_bits_uop_storeSetHit,
  output          io_misalign_enq_req_bits_uop_waitForRobIdx_flag,
  output [7:0]    io_misalign_enq_req_bits_uop_waitForRobIdx_value,
  output          io_misalign_enq_req_bits_uop_loadWaitBit,
  output          io_misalign_enq_req_bits_uop_loadWaitStrict,
  output [4:0]    io_misalign_enq_req_bits_uop_ssid,
  output          io_misalign_enq_req_bits_uop_lqIdx_flag,
  output [6:0]    io_misalign_enq_req_bits_uop_lqIdx_value,
  output          io_misalign_enq_req_bits_uop_sqIdx_flag,
  output [5:0]    io_misalign_enq_req_bits_uop_sqIdx_value,
  output          io_misalign_enq_req_bits_uop_singleStep,
  output          io_misalign_enq_req_bits_uop_replayInst,
  output [34:0]   io_misalign_enq_req_bits_uop_debug_fuType,
  output          io_misalign_enq_req_bits_uop_debug_sim_trig,
  output [4:0]    io_misalign_enq_req_bits_uop_numLsElem,
  output [49:0]   io_misalign_enq_req_bits_vaddr,
  output [63:0]   io_misalign_enq_req_bits_fullva,
  output          io_misalign_enq_req_bits_vaNeedExt,
  output [47:0]   io_misalign_enq_req_bits_paddr,
  output [63:0]   io_misalign_enq_req_bits_gpaddr,
  output [15:0]   io_misalign_enq_req_bits_mask,
  output          io_misalign_enq_req_bits_isForVSnonLeafPTE,
  output          io_misalign_enq_req_bits_isvec,
  output [7:0]    io_misalign_enq_req_bits_elemIdx,
  output [2:0]    io_misalign_enq_req_bits_alignedType,
  output [3:0]    io_misalign_enq_req_bits_mbIndex,
  output [7:0]    io_misalign_enq_req_bits_elemIdxInsideVd,
  output [15:0]   io_misalign_enq_req_bits_vecTriggerMask,
  output          io_rollback_valid,
  output          io_rollback_bits_isRVC,
  output          io_rollback_bits_robIdx_flag,
  output [7:0]    io_rollback_bits_robIdx_value,
  output          io_rollback_bits_ftqIdx_flag,
  output [5:0]    io_rollback_bits_ftqIdx_value,
  output [3:0]    io_rollback_bits_ftqOffset,
  output          io_rollback_bits_level,
  output [63:0]   io_rollback_bits_debug_runahead_checkpoint_id,
  input           io_robDeqIdx_flag,
  input  [7:0]    io_robDeqIdx_value,
  output [7:0]    io_lsTopdownInfo_s1_robIdx,
  output          io_lsTopdownInfo_s1_vaddr_valid,
  output [49:0]   io_lsTopdownInfo_s1_vaddr_bits,
  output [7:0]    io_lsTopdownInfo_s2_robIdx,
  output          io_lsTopdownInfo_s2_paddr_valid,
  output [47:0]   io_lsTopdownInfo_s2_paddr_bits,
  output [5:0]    io_perf_0_value,
  output [5:0]    io_perf_1_value,
  output [5:0]    io_perf_2_value,
  output [5:0]    io_perf_3_value,
  output [5:0]    io_perf_4_value,
  output [5:0]    io_perf_5_value,
  output [5:0]    io_perf_6_value,
  output [5:0]    io_perf_7_value,
  output [5:0]    io_perf_8_value
);

  ldin_t           ldin;
  vecldin_t        vecldin;
  lq_write_t       misalign_ldin;
  lq_write_t       replay;
  lq_write_t       fast_rep_in;
  lq_write_t       lsq_nc_ldin;
  exu_out_t        lsq_uncache;
  pf_req_t         prefetch_req;
  tlb_resp_t       tlb_resp;
  trigger_csr_t    trigger_csr;
  st_query_t       stld_nuke_query_0;
  st_query_t       stld_nuke_query_1;
  pmp_t            pmp;
  dcache_resp_t    dcache_resp;
  fwd_resp_t       sbuffer_resp;
  fwd_resp_t       ubuffer_resp;
  lsq_fwd_resp_t   lsq_fwd_resp;
  d_chan_t         tl_d_channel;
  mshr_fwd_resp_t  mshr_fwd_resp;
  tlb_hint_t       tlb_hint;
  ld_raw_data_t    ld_raw_data;
  rob_ptr_t        robDeqIdx;
  redirect_t       redirect;
  csr_ctrl_t       csrCtrl;
  tlb_req_t        tlb_req;
  dcache_req_t     dcache_req;
  fwd_req_t        sbuffer_req;
  fwd_req_t        ubuffer_req;
  lsq_fwd_req_t    lsq_fwd_req;
  mshr_fwd_req_t   mshr_fwd_req;
  nuke_req_t       stld_nuke_req;
  nuke_req_t       ldld_nuke_req;
  pf_train_t       prefetch_train;
  pf_train_t       prefetch_train_l1;
  ifetch_pf_t      ifetchPrefetch;
  uop_t            wakeup;
  exu_out_t        ldout;
  vecldout_t       vecldout;
  lq_write_t       lsq_ldin;
  lq_write_t       fast_rep_out;
  lq_write_t       misalign_enq;
  lq_write_t       misalign_ldout;
  feedback_t       feedback_slow;
  rollback_t       rollback;
  topdown_t        lsTopdownInfo;

  always_comb begin
    ldin = '0;
    ldin.uop.pc = io_ldin_bits_uop_pc;
    ldin.uop.preDecodeInfo_valid = io_ldin_bits_uop_preDecodeInfo_valid;
    ldin.uop.preDecodeInfo_isRVC = io_ldin_bits_uop_preDecodeInfo_isRVC;
    ldin.uop.preDecodeInfo_brType = io_ldin_bits_uop_preDecodeInfo_brType;
    ldin.uop.preDecodeInfo_isCall = io_ldin_bits_uop_preDecodeInfo_isCall;
    ldin.uop.preDecodeInfo_isRet = io_ldin_bits_uop_preDecodeInfo_isRet;
    ldin.uop.ftqPtr_flag = io_ldin_bits_uop_ftqPtr_flag;
    ldin.uop.ftqPtr_value = io_ldin_bits_uop_ftqPtr_value;
    ldin.uop.ftqOffset = io_ldin_bits_uop_ftqOffset;
    ldin.uop.fuType = io_ldin_bits_uop_fuType;
    ldin.uop.fuOpType = io_ldin_bits_uop_fuOpType;
    ldin.uop.rfWen = io_ldin_bits_uop_rfWen;
    ldin.uop.fpWen = io_ldin_bits_uop_fpWen;
    ldin.uop.imm = io_ldin_bits_uop_imm;
    ldin.uop.pdest = io_ldin_bits_uop_pdest;
    ldin.uop.robIdx_flag = io_ldin_bits_uop_robIdx_flag;
    ldin.uop.robIdx_value = io_ldin_bits_uop_robIdx_value;
    ldin.uop.debugInfo_eliminatedMove = io_ldin_bits_uop_debugInfo_eliminatedMove;
    ldin.uop.debugInfo_renameTime = io_ldin_bits_uop_debugInfo_renameTime;
    ldin.uop.debugInfo_dispatchTime = io_ldin_bits_uop_debugInfo_dispatchTime;
    ldin.uop.debugInfo_enqRsTime = io_ldin_bits_uop_debugInfo_enqRsTime;
    ldin.uop.debugInfo_selectTime = io_ldin_bits_uop_debugInfo_selectTime;
    ldin.uop.debugInfo_issueTime = io_ldin_bits_uop_debugInfo_issueTime;
    ldin.uop.debugInfo_writebackTime = io_ldin_bits_uop_debugInfo_writebackTime;
    ldin.uop.debugInfo_runahead_checkpoint_id = io_ldin_bits_uop_debugInfo_runahead_checkpoint_id;
    ldin.uop.debugInfo_tlbFirstReqTime = io_ldin_bits_uop_debugInfo_tlbFirstReqTime;
    ldin.uop.debugInfo_tlbRespTime = io_ldin_bits_uop_debugInfo_tlbRespTime;
    ldin.uop.debug_seqNum_seqNum = io_ldin_bits_uop_debug_seqNum_seqNum;
    ldin.uop.debug_seqNum_uopIdx = io_ldin_bits_uop_debug_seqNum_uopIdx;
    ldin.uop.storeSetHit = io_ldin_bits_uop_storeSetHit;
    ldin.uop.waitForRobIdx_flag = io_ldin_bits_uop_waitForRobIdx_flag;
    ldin.uop.waitForRobIdx_value = io_ldin_bits_uop_waitForRobIdx_value;
    ldin.uop.loadWaitBit = io_ldin_bits_uop_loadWaitBit;
    ldin.uop.loadWaitStrict = io_ldin_bits_uop_loadWaitStrict;
    ldin.uop.ssid = io_ldin_bits_uop_ssid;
    ldin.uop.lqIdx_flag = io_ldin_bits_uop_lqIdx_flag;
    ldin.uop.lqIdx_value = io_ldin_bits_uop_lqIdx_value;
    ldin.uop.sqIdx_flag = io_ldin_bits_uop_sqIdx_flag;
    ldin.uop.sqIdx_value = io_ldin_bits_uop_sqIdx_value;
    ldin.src_0 = io_ldin_bits_src_0;
  end
  always_comb begin
    vecldin = '0;
    vecldin.vaddr = io_vecldin_bits_vaddr;
    vecldin.basevaddr = io_vecldin_bits_basevaddr;
    vecldin.mask = io_vecldin_bits_mask;
    vecldin.reg_offset = io_vecldin_bits_reg_offset;
    vecldin.alignedType = io_vecldin_bits_alignedType;
    vecldin.vecActive = io_vecldin_bits_vecActive;
    vecldin.uop.instr = io_vecldin_bits_uop_instr;
    vecldin.uop.pc = io_vecldin_bits_uop_pc;
    vecldin.uop.foldpc = io_vecldin_bits_uop_foldpc;
    vecldin.uop.exceptionVec[4] = io_vecldin_bits_uop_exceptionVec_4;
    vecldin.uop.exceptionVec[6] = io_vecldin_bits_uop_exceptionVec_6;
    vecldin.uop.exceptionVec[7] = io_vecldin_bits_uop_exceptionVec_7;
    vecldin.uop.exceptionVec[15] = io_vecldin_bits_uop_exceptionVec_15;
    vecldin.uop.exceptionVec[19] = io_vecldin_bits_uop_exceptionVec_19;
    vecldin.uop.exceptionVec[23] = io_vecldin_bits_uop_exceptionVec_23;
    vecldin.uop.isFetchMalAddr = io_vecldin_bits_uop_isFetchMalAddr;
    vecldin.uop.hasException = io_vecldin_bits_uop_hasException;
    vecldin.uop.preDecodeInfo_valid = io_vecldin_bits_uop_preDecodeInfo_valid;
    vecldin.uop.preDecodeInfo_isRVC = io_vecldin_bits_uop_preDecodeInfo_isRVC;
    vecldin.uop.preDecodeInfo_brType = io_vecldin_bits_uop_preDecodeInfo_brType;
    vecldin.uop.preDecodeInfo_isCall = io_vecldin_bits_uop_preDecodeInfo_isCall;
    vecldin.uop.preDecodeInfo_isRet = io_vecldin_bits_uop_preDecodeInfo_isRet;
    vecldin.uop.pred_taken = io_vecldin_bits_uop_pred_taken;
    vecldin.uop.crossPageIPFFix = io_vecldin_bits_uop_crossPageIPFFix;
    vecldin.uop.ftqPtr_flag = io_vecldin_bits_uop_ftqPtr_flag;
    vecldin.uop.ftqPtr_value = io_vecldin_bits_uop_ftqPtr_value;
    vecldin.uop.ftqOffset = io_vecldin_bits_uop_ftqOffset;
    vecldin.uop.satpFlushFirstFetchFault = io_vecldin_bits_uop_satpFlushFirstFetchFault;
    vecldin.uop.srcType_0 = io_vecldin_bits_uop_srcType_0;
    vecldin.uop.srcType_1 = io_vecldin_bits_uop_srcType_1;
    vecldin.uop.srcType_2 = io_vecldin_bits_uop_srcType_2;
    vecldin.uop.srcType_3 = io_vecldin_bits_uop_srcType_3;
    vecldin.uop.srcType_4 = io_vecldin_bits_uop_srcType_4;
    vecldin.uop.ldest = io_vecldin_bits_uop_ldest;
    vecldin.uop.fuType = io_vecldin_bits_uop_fuType;
    vecldin.uop.fuOpType = io_vecldin_bits_uop_fuOpType;
    vecldin.uop.rfWen = io_vecldin_bits_uop_rfWen;
    vecldin.uop.fpWen = io_vecldin_bits_uop_fpWen;
    vecldin.uop.vecWen = io_vecldin_bits_uop_vecWen;
    vecldin.uop.v0Wen = io_vecldin_bits_uop_v0Wen;
    vecldin.uop.vlWen = io_vecldin_bits_uop_vlWen;
    vecldin.uop.isXSTrap = io_vecldin_bits_uop_isXSTrap;
    vecldin.uop.waitForward = io_vecldin_bits_uop_waitForward;
    vecldin.uop.blockBackward = io_vecldin_bits_uop_blockBackward;
    vecldin.uop.canRobCompress = io_vecldin_bits_uop_canRobCompress;
    vecldin.uop.selImm = io_vecldin_bits_uop_selImm;
    vecldin.uop.fpu_typeTagOut = io_vecldin_bits_uop_fpu_typeTagOut;
    vecldin.uop.fpu_wflags = io_vecldin_bits_uop_fpu_wflags;
    vecldin.uop.fpu_typ = io_vecldin_bits_uop_fpu_typ;
    vecldin.uop.fpu_fmt = io_vecldin_bits_uop_fpu_fmt;
    vecldin.uop.fpu_rm = io_vecldin_bits_uop_fpu_rm;
    vecldin.uop.vpu_vill = io_vecldin_bits_uop_vpu_vill;
    vecldin.uop.vpu_vma = io_vecldin_bits_uop_vpu_vma;
    vecldin.uop.vpu_vta = io_vecldin_bits_uop_vpu_vta;
    vecldin.uop.vpu_vsew = io_vecldin_bits_uop_vpu_vsew;
    vecldin.uop.vpu_vlmul = io_vecldin_bits_uop_vpu_vlmul;
    vecldin.uop.vpu_specVill = io_vecldin_bits_uop_vpu_specVill;
    vecldin.uop.vpu_specVma = io_vecldin_bits_uop_vpu_specVma;
    vecldin.uop.vpu_specVta = io_vecldin_bits_uop_vpu_specVta;
    vecldin.uop.vpu_specVsew = io_vecldin_bits_uop_vpu_specVsew;
    vecldin.uop.vpu_specVlmul = io_vecldin_bits_uop_vpu_specVlmul;
    vecldin.uop.vpu_vm = io_vecldin_bits_uop_vpu_vm;
    vecldin.uop.vpu_vstart = io_vecldin_bits_uop_vpu_vstart;
    vecldin.uop.vpu_frm = io_vecldin_bits_uop_vpu_frm;
    vecldin.uop.vpu_fpu_isFpToVecInst = io_vecldin_bits_uop_vpu_fpu_isFpToVecInst;
    vecldin.uop.vpu_fpu_isFP32Instr = io_vecldin_bits_uop_vpu_fpu_isFP32Instr;
    vecldin.uop.vpu_fpu_isFP64Instr = io_vecldin_bits_uop_vpu_fpu_isFP64Instr;
    vecldin.uop.vpu_fpu_isReduction = io_vecldin_bits_uop_vpu_fpu_isReduction;
    vecldin.uop.vpu_fpu_isFoldTo1_2 = io_vecldin_bits_uop_vpu_fpu_isFoldTo1_2;
    vecldin.uop.vpu_fpu_isFoldTo1_4 = io_vecldin_bits_uop_vpu_fpu_isFoldTo1_4;
    vecldin.uop.vpu_fpu_isFoldTo1_8 = io_vecldin_bits_uop_vpu_fpu_isFoldTo1_8;
    vecldin.uop.vpu_vxrm = io_vecldin_bits_uop_vpu_vxrm;
    vecldin.uop.vpu_vuopIdx = io_vecldin_bits_uop_vpu_vuopIdx;
    vecldin.uop.vpu_lastUop = io_vecldin_bits_uop_vpu_lastUop;
    vecldin.uop.vpu_vmask = io_vecldin_bits_uop_vpu_vmask;
    vecldin.uop.vpu_vl = io_vecldin_bits_uop_vpu_vl;
    vecldin.uop.vpu_nf = io_vecldin_bits_uop_vpu_nf;
    vecldin.uop.vpu_veew = io_vecldin_bits_uop_vpu_veew;
    vecldin.uop.vpu_isReverse = io_vecldin_bits_uop_vpu_isReverse;
    vecldin.uop.vpu_isExt = io_vecldin_bits_uop_vpu_isExt;
    vecldin.uop.vpu_isNarrow = io_vecldin_bits_uop_vpu_isNarrow;
    vecldin.uop.vpu_isDstMask = io_vecldin_bits_uop_vpu_isDstMask;
    vecldin.uop.vpu_isOpMask = io_vecldin_bits_uop_vpu_isOpMask;
    vecldin.uop.vpu_isMove = io_vecldin_bits_uop_vpu_isMove;
    vecldin.uop.vpu_isDependOldVd = io_vecldin_bits_uop_vpu_isDependOldVd;
    vecldin.uop.vpu_isWritePartVd = io_vecldin_bits_uop_vpu_isWritePartVd;
    vecldin.uop.vpu_isVleff = io_vecldin_bits_uop_vpu_isVleff;
    vecldin.uop.vlsInstr = io_vecldin_bits_uop_vlsInstr;
    vecldin.uop.wfflags = io_vecldin_bits_uop_wfflags;
    vecldin.uop.isMove = io_vecldin_bits_uop_isMove;
    vecldin.uop.isDropAmocasSta = io_vecldin_bits_uop_isDropAmocasSta;
    vecldin.uop.uopIdx = io_vecldin_bits_uop_uopIdx;
    vecldin.uop.isVset = io_vecldin_bits_uop_isVset;
    vecldin.uop.firstUop = io_vecldin_bits_uop_firstUop;
    vecldin.uop.lastUop = io_vecldin_bits_uop_lastUop;
    vecldin.uop.numUops = io_vecldin_bits_uop_numUops;
    vecldin.uop.numWB = io_vecldin_bits_uop_numWB;
    vecldin.uop.commitType = io_vecldin_bits_uop_commitType;
    vecldin.uop.srcState_0 = io_vecldin_bits_uop_srcState_0;
    vecldin.uop.srcState_1 = io_vecldin_bits_uop_srcState_1;
    vecldin.uop.srcState_2 = io_vecldin_bits_uop_srcState_2;
    vecldin.uop.srcState_3 = io_vecldin_bits_uop_srcState_3;
    vecldin.uop.srcState_4 = io_vecldin_bits_uop_srcState_4;
    vecldin.uop.srcLoadDependency_0_0 = io_vecldin_bits_uop_srcLoadDependency_0_0;
    vecldin.uop.srcLoadDependency_0_1 = io_vecldin_bits_uop_srcLoadDependency_0_1;
    vecldin.uop.srcLoadDependency_0_2 = io_vecldin_bits_uop_srcLoadDependency_0_2;
    vecldin.uop.srcLoadDependency_1_0 = io_vecldin_bits_uop_srcLoadDependency_1_0;
    vecldin.uop.srcLoadDependency_1_1 = io_vecldin_bits_uop_srcLoadDependency_1_1;
    vecldin.uop.srcLoadDependency_1_2 = io_vecldin_bits_uop_srcLoadDependency_1_2;
    vecldin.uop.srcLoadDependency_2_0 = io_vecldin_bits_uop_srcLoadDependency_2_0;
    vecldin.uop.srcLoadDependency_2_1 = io_vecldin_bits_uop_srcLoadDependency_2_1;
    vecldin.uop.srcLoadDependency_2_2 = io_vecldin_bits_uop_srcLoadDependency_2_2;
    vecldin.uop.srcLoadDependency_3_0 = io_vecldin_bits_uop_srcLoadDependency_3_0;
    vecldin.uop.srcLoadDependency_3_1 = io_vecldin_bits_uop_srcLoadDependency_3_1;
    vecldin.uop.srcLoadDependency_3_2 = io_vecldin_bits_uop_srcLoadDependency_3_2;
    vecldin.uop.srcLoadDependency_4_0 = io_vecldin_bits_uop_srcLoadDependency_4_0;
    vecldin.uop.srcLoadDependency_4_1 = io_vecldin_bits_uop_srcLoadDependency_4_1;
    vecldin.uop.srcLoadDependency_4_2 = io_vecldin_bits_uop_srcLoadDependency_4_2;
    vecldin.uop.psrc_0 = io_vecldin_bits_uop_psrc_0;
    vecldin.uop.psrc_1 = io_vecldin_bits_uop_psrc_1;
    vecldin.uop.psrc_2 = io_vecldin_bits_uop_psrc_2;
    vecldin.uop.psrc_3 = io_vecldin_bits_uop_psrc_3;
    vecldin.uop.psrc_4 = io_vecldin_bits_uop_psrc_4;
    vecldin.uop.pdest = io_vecldin_bits_uop_pdest;
    vecldin.uop.useRegCache_0 = io_vecldin_bits_uop_useRegCache_0;
    vecldin.uop.useRegCache_1 = io_vecldin_bits_uop_useRegCache_1;
    vecldin.uop.regCacheIdx_0 = io_vecldin_bits_uop_regCacheIdx_0;
    vecldin.uop.regCacheIdx_1 = io_vecldin_bits_uop_regCacheIdx_1;
    vecldin.uop.robIdx_flag = io_vecldin_bits_uop_robIdx_flag;
    vecldin.uop.robIdx_value = io_vecldin_bits_uop_robIdx_value;
    vecldin.uop.instrSize = io_vecldin_bits_uop_instrSize;
    vecldin.uop.dirtyFs = io_vecldin_bits_uop_dirtyFs;
    vecldin.uop.dirtyVs = io_vecldin_bits_uop_dirtyVs;
    vecldin.uop.traceBlockInPipe_itype = io_vecldin_bits_uop_traceBlockInPipe_itype;
    vecldin.uop.traceBlockInPipe_iretire = io_vecldin_bits_uop_traceBlockInPipe_iretire;
    vecldin.uop.traceBlockInPipe_ilastsize = io_vecldin_bits_uop_traceBlockInPipe_ilastsize;
    vecldin.uop.eliminatedMove = io_vecldin_bits_uop_eliminatedMove;
    vecldin.uop.snapshot = io_vecldin_bits_uop_snapshot;
    vecldin.uop.debugInfo_eliminatedMove = io_vecldin_bits_uop_debugInfo_eliminatedMove;
    vecldin.uop.debugInfo_renameTime = io_vecldin_bits_uop_debugInfo_renameTime;
    vecldin.uop.debugInfo_dispatchTime = io_vecldin_bits_uop_debugInfo_dispatchTime;
    vecldin.uop.debugInfo_enqRsTime = io_vecldin_bits_uop_debugInfo_enqRsTime;
    vecldin.uop.debugInfo_selectTime = io_vecldin_bits_uop_debugInfo_selectTime;
    vecldin.uop.debugInfo_issueTime = io_vecldin_bits_uop_debugInfo_issueTime;
    vecldin.uop.debugInfo_writebackTime = io_vecldin_bits_uop_debugInfo_writebackTime;
    vecldin.uop.debugInfo_runahead_checkpoint_id = io_vecldin_bits_uop_debugInfo_runahead_checkpoint_id;
    vecldin.uop.debugInfo_tlbFirstReqTime = io_vecldin_bits_uop_debugInfo_tlbFirstReqTime;
    vecldin.uop.debugInfo_tlbRespTime = io_vecldin_bits_uop_debugInfo_tlbRespTime;
    vecldin.uop.debug_seqNum_seqNum = io_vecldin_bits_uop_debug_seqNum_seqNum;
    vecldin.uop.debug_seqNum_uopIdx = io_vecldin_bits_uop_debug_seqNum_uopIdx;
    vecldin.uop.storeSetHit = io_vecldin_bits_uop_storeSetHit;
    vecldin.uop.waitForRobIdx_flag = io_vecldin_bits_uop_waitForRobIdx_flag;
    vecldin.uop.waitForRobIdx_value = io_vecldin_bits_uop_waitForRobIdx_value;
    vecldin.uop.loadWaitBit = io_vecldin_bits_uop_loadWaitBit;
    vecldin.uop.loadWaitStrict = io_vecldin_bits_uop_loadWaitStrict;
    vecldin.uop.ssid = io_vecldin_bits_uop_ssid;
    vecldin.uop.lqIdx_flag = io_vecldin_bits_uop_lqIdx_flag;
    vecldin.uop.lqIdx_value = io_vecldin_bits_uop_lqIdx_value;
    vecldin.uop.sqIdx_flag = io_vecldin_bits_uop_sqIdx_flag;
    vecldin.uop.sqIdx_value = io_vecldin_bits_uop_sqIdx_value;
    vecldin.uop.singleStep = io_vecldin_bits_uop_singleStep;
    vecldin.uop.replayInst = io_vecldin_bits_uop_replayInst;
    vecldin.uop.debug_fuType = io_vecldin_bits_uop_debug_fuType;
    vecldin.uop.debug_sim_trig = io_vecldin_bits_uop_debug_sim_trig;
    vecldin.uop.numLsElem = io_vecldin_bits_uop_numLsElem;
    vecldin.mBIndex = io_vecldin_bits_mBIndex;
    vecldin.elemIdx = io_vecldin_bits_elemIdx;
    vecldin.elemIdxInsideVd = io_vecldin_bits_elemIdxInsideVd;
  end
  always_comb begin
    misalign_ldin = '0;
    misalign_ldin.uop.instr = io_misalign_ldin_bits_uop_instr;
    misalign_ldin.uop.pc = io_misalign_ldin_bits_uop_pc;
    misalign_ldin.uop.foldpc = io_misalign_ldin_bits_uop_foldpc;
    misalign_ldin.uop.exceptionVec[0] = io_misalign_ldin_bits_uop_exceptionVec_0;
    misalign_ldin.uop.exceptionVec[1] = io_misalign_ldin_bits_uop_exceptionVec_1;
    misalign_ldin.uop.exceptionVec[2] = io_misalign_ldin_bits_uop_exceptionVec_2;
    misalign_ldin.uop.exceptionVec[3] = io_misalign_ldin_bits_uop_exceptionVec_3;
    misalign_ldin.uop.exceptionVec[4] = io_misalign_ldin_bits_uop_exceptionVec_4;
    misalign_ldin.uop.exceptionVec[5] = io_misalign_ldin_bits_uop_exceptionVec_5;
    misalign_ldin.uop.exceptionVec[6] = io_misalign_ldin_bits_uop_exceptionVec_6;
    misalign_ldin.uop.exceptionVec[7] = io_misalign_ldin_bits_uop_exceptionVec_7;
    misalign_ldin.uop.exceptionVec[8] = io_misalign_ldin_bits_uop_exceptionVec_8;
    misalign_ldin.uop.exceptionVec[9] = io_misalign_ldin_bits_uop_exceptionVec_9;
    misalign_ldin.uop.exceptionVec[10] = io_misalign_ldin_bits_uop_exceptionVec_10;
    misalign_ldin.uop.exceptionVec[11] = io_misalign_ldin_bits_uop_exceptionVec_11;
    misalign_ldin.uop.exceptionVec[12] = io_misalign_ldin_bits_uop_exceptionVec_12;
    misalign_ldin.uop.exceptionVec[13] = io_misalign_ldin_bits_uop_exceptionVec_13;
    misalign_ldin.uop.exceptionVec[14] = io_misalign_ldin_bits_uop_exceptionVec_14;
    misalign_ldin.uop.exceptionVec[15] = io_misalign_ldin_bits_uop_exceptionVec_15;
    misalign_ldin.uop.exceptionVec[16] = io_misalign_ldin_bits_uop_exceptionVec_16;
    misalign_ldin.uop.exceptionVec[17] = io_misalign_ldin_bits_uop_exceptionVec_17;
    misalign_ldin.uop.exceptionVec[18] = io_misalign_ldin_bits_uop_exceptionVec_18;
    misalign_ldin.uop.exceptionVec[19] = io_misalign_ldin_bits_uop_exceptionVec_19;
    misalign_ldin.uop.exceptionVec[20] = io_misalign_ldin_bits_uop_exceptionVec_20;
    misalign_ldin.uop.exceptionVec[21] = io_misalign_ldin_bits_uop_exceptionVec_21;
    misalign_ldin.uop.exceptionVec[22] = io_misalign_ldin_bits_uop_exceptionVec_22;
    misalign_ldin.uop.exceptionVec[23] = io_misalign_ldin_bits_uop_exceptionVec_23;
    misalign_ldin.uop.isFetchMalAddr = io_misalign_ldin_bits_uop_isFetchMalAddr;
    misalign_ldin.uop.hasException = io_misalign_ldin_bits_uop_hasException;
    misalign_ldin.uop.trigger = io_misalign_ldin_bits_uop_trigger;
    misalign_ldin.uop.preDecodeInfo_valid = io_misalign_ldin_bits_uop_preDecodeInfo_valid;
    misalign_ldin.uop.preDecodeInfo_isRVC = io_misalign_ldin_bits_uop_preDecodeInfo_isRVC;
    misalign_ldin.uop.preDecodeInfo_brType = io_misalign_ldin_bits_uop_preDecodeInfo_brType;
    misalign_ldin.uop.preDecodeInfo_isCall = io_misalign_ldin_bits_uop_preDecodeInfo_isCall;
    misalign_ldin.uop.preDecodeInfo_isRet = io_misalign_ldin_bits_uop_preDecodeInfo_isRet;
    misalign_ldin.uop.pred_taken = io_misalign_ldin_bits_uop_pred_taken;
    misalign_ldin.uop.crossPageIPFFix = io_misalign_ldin_bits_uop_crossPageIPFFix;
    misalign_ldin.uop.ftqPtr_flag = io_misalign_ldin_bits_uop_ftqPtr_flag;
    misalign_ldin.uop.ftqPtr_value = io_misalign_ldin_bits_uop_ftqPtr_value;
    misalign_ldin.uop.ftqOffset = io_misalign_ldin_bits_uop_ftqOffset;
    misalign_ldin.uop.satpFlushFirstFetchFault = io_misalign_ldin_bits_uop_satpFlushFirstFetchFault;
    misalign_ldin.uop.srcType_0 = io_misalign_ldin_bits_uop_srcType_0;
    misalign_ldin.uop.srcType_1 = io_misalign_ldin_bits_uop_srcType_1;
    misalign_ldin.uop.srcType_2 = io_misalign_ldin_bits_uop_srcType_2;
    misalign_ldin.uop.srcType_3 = io_misalign_ldin_bits_uop_srcType_3;
    misalign_ldin.uop.srcType_4 = io_misalign_ldin_bits_uop_srcType_4;
    misalign_ldin.uop.ldest = io_misalign_ldin_bits_uop_ldest;
    misalign_ldin.uop.fuType = io_misalign_ldin_bits_uop_fuType;
    misalign_ldin.uop.fuOpType = io_misalign_ldin_bits_uop_fuOpType;
    misalign_ldin.uop.rfWen = io_misalign_ldin_bits_uop_rfWen;
    misalign_ldin.uop.fpWen = io_misalign_ldin_bits_uop_fpWen;
    misalign_ldin.uop.vecWen = io_misalign_ldin_bits_uop_vecWen;
    misalign_ldin.uop.v0Wen = io_misalign_ldin_bits_uop_v0Wen;
    misalign_ldin.uop.vlWen = io_misalign_ldin_bits_uop_vlWen;
    misalign_ldin.uop.isXSTrap = io_misalign_ldin_bits_uop_isXSTrap;
    misalign_ldin.uop.waitForward = io_misalign_ldin_bits_uop_waitForward;
    misalign_ldin.uop.blockBackward = io_misalign_ldin_bits_uop_blockBackward;
    misalign_ldin.uop.flushPipe = io_misalign_ldin_bits_uop_flushPipe;
    misalign_ldin.uop.canRobCompress = io_misalign_ldin_bits_uop_canRobCompress;
    misalign_ldin.uop.selImm = io_misalign_ldin_bits_uop_selImm;
    misalign_ldin.uop.imm = io_misalign_ldin_bits_uop_imm;
    misalign_ldin.uop.fpu_typeTagOut = io_misalign_ldin_bits_uop_fpu_typeTagOut;
    misalign_ldin.uop.fpu_wflags = io_misalign_ldin_bits_uop_fpu_wflags;
    misalign_ldin.uop.fpu_typ = io_misalign_ldin_bits_uop_fpu_typ;
    misalign_ldin.uop.fpu_fmt = io_misalign_ldin_bits_uop_fpu_fmt;
    misalign_ldin.uop.fpu_rm = io_misalign_ldin_bits_uop_fpu_rm;
    misalign_ldin.uop.vpu_vill = io_misalign_ldin_bits_uop_vpu_vill;
    misalign_ldin.uop.vpu_vma = io_misalign_ldin_bits_uop_vpu_vma;
    misalign_ldin.uop.vpu_vta = io_misalign_ldin_bits_uop_vpu_vta;
    misalign_ldin.uop.vpu_vsew = io_misalign_ldin_bits_uop_vpu_vsew;
    misalign_ldin.uop.vpu_vlmul = io_misalign_ldin_bits_uop_vpu_vlmul;
    misalign_ldin.uop.vpu_specVill = io_misalign_ldin_bits_uop_vpu_specVill;
    misalign_ldin.uop.vpu_specVma = io_misalign_ldin_bits_uop_vpu_specVma;
    misalign_ldin.uop.vpu_specVta = io_misalign_ldin_bits_uop_vpu_specVta;
    misalign_ldin.uop.vpu_specVsew = io_misalign_ldin_bits_uop_vpu_specVsew;
    misalign_ldin.uop.vpu_specVlmul = io_misalign_ldin_bits_uop_vpu_specVlmul;
    misalign_ldin.uop.vpu_vm = io_misalign_ldin_bits_uop_vpu_vm;
    misalign_ldin.uop.vpu_vstart = io_misalign_ldin_bits_uop_vpu_vstart;
    misalign_ldin.uop.vpu_frm = io_misalign_ldin_bits_uop_vpu_frm;
    misalign_ldin.uop.vpu_fpu_isFpToVecInst = io_misalign_ldin_bits_uop_vpu_fpu_isFpToVecInst;
    misalign_ldin.uop.vpu_fpu_isFP32Instr = io_misalign_ldin_bits_uop_vpu_fpu_isFP32Instr;
    misalign_ldin.uop.vpu_fpu_isFP64Instr = io_misalign_ldin_bits_uop_vpu_fpu_isFP64Instr;
    misalign_ldin.uop.vpu_fpu_isReduction = io_misalign_ldin_bits_uop_vpu_fpu_isReduction;
    misalign_ldin.uop.vpu_fpu_isFoldTo1_2 = io_misalign_ldin_bits_uop_vpu_fpu_isFoldTo1_2;
    misalign_ldin.uop.vpu_fpu_isFoldTo1_4 = io_misalign_ldin_bits_uop_vpu_fpu_isFoldTo1_4;
    misalign_ldin.uop.vpu_fpu_isFoldTo1_8 = io_misalign_ldin_bits_uop_vpu_fpu_isFoldTo1_8;
    misalign_ldin.uop.vpu_vxrm = io_misalign_ldin_bits_uop_vpu_vxrm;
    misalign_ldin.uop.vpu_vuopIdx = io_misalign_ldin_bits_uop_vpu_vuopIdx;
    misalign_ldin.uop.vpu_lastUop = io_misalign_ldin_bits_uop_vpu_lastUop;
    misalign_ldin.uop.vpu_vmask = io_misalign_ldin_bits_uop_vpu_vmask;
    misalign_ldin.uop.vpu_vl = io_misalign_ldin_bits_uop_vpu_vl;
    misalign_ldin.uop.vpu_nf = io_misalign_ldin_bits_uop_vpu_nf;
    misalign_ldin.uop.vpu_veew = io_misalign_ldin_bits_uop_vpu_veew;
    misalign_ldin.uop.vpu_isReverse = io_misalign_ldin_bits_uop_vpu_isReverse;
    misalign_ldin.uop.vpu_isExt = io_misalign_ldin_bits_uop_vpu_isExt;
    misalign_ldin.uop.vpu_isNarrow = io_misalign_ldin_bits_uop_vpu_isNarrow;
    misalign_ldin.uop.vpu_isDstMask = io_misalign_ldin_bits_uop_vpu_isDstMask;
    misalign_ldin.uop.vpu_isOpMask = io_misalign_ldin_bits_uop_vpu_isOpMask;
    misalign_ldin.uop.vpu_isMove = io_misalign_ldin_bits_uop_vpu_isMove;
    misalign_ldin.uop.vpu_isDependOldVd = io_misalign_ldin_bits_uop_vpu_isDependOldVd;
    misalign_ldin.uop.vpu_isWritePartVd = io_misalign_ldin_bits_uop_vpu_isWritePartVd;
    misalign_ldin.uop.vpu_isVleff = io_misalign_ldin_bits_uop_vpu_isVleff;
    misalign_ldin.uop.vlsInstr = io_misalign_ldin_bits_uop_vlsInstr;
    misalign_ldin.uop.wfflags = io_misalign_ldin_bits_uop_wfflags;
    misalign_ldin.uop.isMove = io_misalign_ldin_bits_uop_isMove;
    misalign_ldin.uop.isDropAmocasSta = io_misalign_ldin_bits_uop_isDropAmocasSta;
    misalign_ldin.uop.uopIdx = io_misalign_ldin_bits_uop_uopIdx;
    misalign_ldin.uop.isVset = io_misalign_ldin_bits_uop_isVset;
    misalign_ldin.uop.firstUop = io_misalign_ldin_bits_uop_firstUop;
    misalign_ldin.uop.lastUop = io_misalign_ldin_bits_uop_lastUop;
    misalign_ldin.uop.numUops = io_misalign_ldin_bits_uop_numUops;
    misalign_ldin.uop.numWB = io_misalign_ldin_bits_uop_numWB;
    misalign_ldin.uop.commitType = io_misalign_ldin_bits_uop_commitType;
    misalign_ldin.uop.srcState_0 = io_misalign_ldin_bits_uop_srcState_0;
    misalign_ldin.uop.srcState_1 = io_misalign_ldin_bits_uop_srcState_1;
    misalign_ldin.uop.srcState_2 = io_misalign_ldin_bits_uop_srcState_2;
    misalign_ldin.uop.srcState_3 = io_misalign_ldin_bits_uop_srcState_3;
    misalign_ldin.uop.srcState_4 = io_misalign_ldin_bits_uop_srcState_4;
    misalign_ldin.uop.srcLoadDependency_0_0 = io_misalign_ldin_bits_uop_srcLoadDependency_0_0;
    misalign_ldin.uop.srcLoadDependency_0_1 = io_misalign_ldin_bits_uop_srcLoadDependency_0_1;
    misalign_ldin.uop.srcLoadDependency_0_2 = io_misalign_ldin_bits_uop_srcLoadDependency_0_2;
    misalign_ldin.uop.srcLoadDependency_1_0 = io_misalign_ldin_bits_uop_srcLoadDependency_1_0;
    misalign_ldin.uop.srcLoadDependency_1_1 = io_misalign_ldin_bits_uop_srcLoadDependency_1_1;
    misalign_ldin.uop.srcLoadDependency_1_2 = io_misalign_ldin_bits_uop_srcLoadDependency_1_2;
    misalign_ldin.uop.srcLoadDependency_2_0 = io_misalign_ldin_bits_uop_srcLoadDependency_2_0;
    misalign_ldin.uop.srcLoadDependency_2_1 = io_misalign_ldin_bits_uop_srcLoadDependency_2_1;
    misalign_ldin.uop.srcLoadDependency_2_2 = io_misalign_ldin_bits_uop_srcLoadDependency_2_2;
    misalign_ldin.uop.srcLoadDependency_3_0 = io_misalign_ldin_bits_uop_srcLoadDependency_3_0;
    misalign_ldin.uop.srcLoadDependency_3_1 = io_misalign_ldin_bits_uop_srcLoadDependency_3_1;
    misalign_ldin.uop.srcLoadDependency_3_2 = io_misalign_ldin_bits_uop_srcLoadDependency_3_2;
    misalign_ldin.uop.srcLoadDependency_4_0 = io_misalign_ldin_bits_uop_srcLoadDependency_4_0;
    misalign_ldin.uop.srcLoadDependency_4_1 = io_misalign_ldin_bits_uop_srcLoadDependency_4_1;
    misalign_ldin.uop.srcLoadDependency_4_2 = io_misalign_ldin_bits_uop_srcLoadDependency_4_2;
    misalign_ldin.uop.psrc_0 = io_misalign_ldin_bits_uop_psrc_0;
    misalign_ldin.uop.psrc_1 = io_misalign_ldin_bits_uop_psrc_1;
    misalign_ldin.uop.psrc_2 = io_misalign_ldin_bits_uop_psrc_2;
    misalign_ldin.uop.psrc_3 = io_misalign_ldin_bits_uop_psrc_3;
    misalign_ldin.uop.psrc_4 = io_misalign_ldin_bits_uop_psrc_4;
    misalign_ldin.uop.pdest = io_misalign_ldin_bits_uop_pdest;
    misalign_ldin.uop.useRegCache_0 = io_misalign_ldin_bits_uop_useRegCache_0;
    misalign_ldin.uop.useRegCache_1 = io_misalign_ldin_bits_uop_useRegCache_1;
    misalign_ldin.uop.regCacheIdx_0 = io_misalign_ldin_bits_uop_regCacheIdx_0;
    misalign_ldin.uop.regCacheIdx_1 = io_misalign_ldin_bits_uop_regCacheIdx_1;
    misalign_ldin.uop.robIdx_flag = io_misalign_ldin_bits_uop_robIdx_flag;
    misalign_ldin.uop.robIdx_value = io_misalign_ldin_bits_uop_robIdx_value;
    misalign_ldin.uop.instrSize = io_misalign_ldin_bits_uop_instrSize;
    misalign_ldin.uop.dirtyFs = io_misalign_ldin_bits_uop_dirtyFs;
    misalign_ldin.uop.dirtyVs = io_misalign_ldin_bits_uop_dirtyVs;
    misalign_ldin.uop.traceBlockInPipe_itype = io_misalign_ldin_bits_uop_traceBlockInPipe_itype;
    misalign_ldin.uop.traceBlockInPipe_iretire = io_misalign_ldin_bits_uop_traceBlockInPipe_iretire;
    misalign_ldin.uop.traceBlockInPipe_ilastsize = io_misalign_ldin_bits_uop_traceBlockInPipe_ilastsize;
    misalign_ldin.uop.eliminatedMove = io_misalign_ldin_bits_uop_eliminatedMove;
    misalign_ldin.uop.snapshot = io_misalign_ldin_bits_uop_snapshot;
    misalign_ldin.uop.debugInfo_eliminatedMove = io_misalign_ldin_bits_uop_debugInfo_eliminatedMove;
    misalign_ldin.uop.debugInfo_renameTime = io_misalign_ldin_bits_uop_debugInfo_renameTime;
    misalign_ldin.uop.debugInfo_dispatchTime = io_misalign_ldin_bits_uop_debugInfo_dispatchTime;
    misalign_ldin.uop.debugInfo_enqRsTime = io_misalign_ldin_bits_uop_debugInfo_enqRsTime;
    misalign_ldin.uop.debugInfo_selectTime = io_misalign_ldin_bits_uop_debugInfo_selectTime;
    misalign_ldin.uop.debugInfo_issueTime = io_misalign_ldin_bits_uop_debugInfo_issueTime;
    misalign_ldin.uop.debugInfo_writebackTime = io_misalign_ldin_bits_uop_debugInfo_writebackTime;
    misalign_ldin.uop.debugInfo_runahead_checkpoint_id = io_misalign_ldin_bits_uop_debugInfo_runahead_checkpoint_id;
    misalign_ldin.uop.debugInfo_tlbFirstReqTime = io_misalign_ldin_bits_uop_debugInfo_tlbFirstReqTime;
    misalign_ldin.uop.debugInfo_tlbRespTime = io_misalign_ldin_bits_uop_debugInfo_tlbRespTime;
    misalign_ldin.uop.debug_seqNum_seqNum = io_misalign_ldin_bits_uop_debug_seqNum_seqNum;
    misalign_ldin.uop.debug_seqNum_uopIdx = io_misalign_ldin_bits_uop_debug_seqNum_uopIdx;
    misalign_ldin.uop.storeSetHit = io_misalign_ldin_bits_uop_storeSetHit;
    misalign_ldin.uop.waitForRobIdx_flag = io_misalign_ldin_bits_uop_waitForRobIdx_flag;
    misalign_ldin.uop.waitForRobIdx_value = io_misalign_ldin_bits_uop_waitForRobIdx_value;
    misalign_ldin.uop.loadWaitBit = io_misalign_ldin_bits_uop_loadWaitBit;
    misalign_ldin.uop.loadWaitStrict = io_misalign_ldin_bits_uop_loadWaitStrict;
    misalign_ldin.uop.ssid = io_misalign_ldin_bits_uop_ssid;
    misalign_ldin.uop.lqIdx_flag = io_misalign_ldin_bits_uop_lqIdx_flag;
    misalign_ldin.uop.lqIdx_value = io_misalign_ldin_bits_uop_lqIdx_value;
    misalign_ldin.uop.sqIdx_flag = io_misalign_ldin_bits_uop_sqIdx_flag;
    misalign_ldin.uop.sqIdx_value = io_misalign_ldin_bits_uop_sqIdx_value;
    misalign_ldin.uop.singleStep = io_misalign_ldin_bits_uop_singleStep;
    misalign_ldin.uop.replayInst = io_misalign_ldin_bits_uop_replayInst;
    misalign_ldin.uop.debug_fuType = io_misalign_ldin_bits_uop_debug_fuType;
    misalign_ldin.uop.debug_sim_trig = io_misalign_ldin_bits_uop_debug_sim_trig;
    misalign_ldin.uop.numLsElem = io_misalign_ldin_bits_uop_numLsElem;
    misalign_ldin.vaddr = io_misalign_ldin_bits_vaddr;
    misalign_ldin.fullva = io_misalign_ldin_bits_fullva;
    misalign_ldin.vaNeedExt = io_misalign_ldin_bits_vaNeedExt;
    misalign_ldin.paddr = io_misalign_ldin_bits_paddr;
    misalign_ldin.gpaddr = io_misalign_ldin_bits_gpaddr;
    misalign_ldin.mask = io_misalign_ldin_bits_mask;
    misalign_ldin.nc = io_misalign_ldin_bits_nc;
    misalign_ldin.mmio = io_misalign_ldin_bits_mmio;
    misalign_ldin.memBackTypeMM = io_misalign_ldin_bits_memBackTypeMM;
    misalign_ldin.isForVSnonLeafPTE = io_misalign_ldin_bits_isForVSnonLeafPTE;
    misalign_ldin.isvec = io_misalign_ldin_bits_isvec;
    misalign_ldin.is128bit = io_misalign_ldin_bits_is128bit;
    misalign_ldin.vecActive = io_misalign_ldin_bits_vecActive;
    misalign_ldin.mshrid = io_misalign_ldin_bits_mshrid;
    misalign_ldin.schedIndex = io_misalign_ldin_bits_schedIndex;
    misalign_ldin.isFinalSplit = io_misalign_ldin_bits_isFinalSplit;
    misalign_ldin.misalignNeedWakeUp = io_misalign_ldin_bits_misalignNeedWakeUp;
  end
  always_comb begin
    replay = '0;
    replay.uop.instr = io_replay_bits_uop_instr;
    replay.uop.pc = io_replay_bits_uop_pc;
    replay.uop.foldpc = io_replay_bits_uop_foldpc;
    replay.uop.exceptionVec[0] = io_replay_bits_uop_exceptionVec_0;
    replay.uop.exceptionVec[1] = io_replay_bits_uop_exceptionVec_1;
    replay.uop.exceptionVec[2] = io_replay_bits_uop_exceptionVec_2;
    replay.uop.exceptionVec[3] = io_replay_bits_uop_exceptionVec_3;
    replay.uop.exceptionVec[5] = io_replay_bits_uop_exceptionVec_5;
    replay.uop.exceptionVec[6] = io_replay_bits_uop_exceptionVec_6;
    replay.uop.exceptionVec[7] = io_replay_bits_uop_exceptionVec_7;
    replay.uop.exceptionVec[8] = io_replay_bits_uop_exceptionVec_8;
    replay.uop.exceptionVec[9] = io_replay_bits_uop_exceptionVec_9;
    replay.uop.exceptionVec[10] = io_replay_bits_uop_exceptionVec_10;
    replay.uop.exceptionVec[11] = io_replay_bits_uop_exceptionVec_11;
    replay.uop.exceptionVec[12] = io_replay_bits_uop_exceptionVec_12;
    replay.uop.exceptionVec[13] = io_replay_bits_uop_exceptionVec_13;
    replay.uop.exceptionVec[14] = io_replay_bits_uop_exceptionVec_14;
    replay.uop.exceptionVec[15] = io_replay_bits_uop_exceptionVec_15;
    replay.uop.exceptionVec[16] = io_replay_bits_uop_exceptionVec_16;
    replay.uop.exceptionVec[17] = io_replay_bits_uop_exceptionVec_17;
    replay.uop.exceptionVec[18] = io_replay_bits_uop_exceptionVec_18;
    replay.uop.exceptionVec[19] = io_replay_bits_uop_exceptionVec_19;
    replay.uop.exceptionVec[20] = io_replay_bits_uop_exceptionVec_20;
    replay.uop.exceptionVec[21] = io_replay_bits_uop_exceptionVec_21;
    replay.uop.exceptionVec[22] = io_replay_bits_uop_exceptionVec_22;
    replay.uop.exceptionVec[23] = io_replay_bits_uop_exceptionVec_23;
    replay.uop.isFetchMalAddr = io_replay_bits_uop_isFetchMalAddr;
    replay.uop.hasException = io_replay_bits_uop_hasException;
    replay.uop.trigger = io_replay_bits_uop_trigger;
    replay.uop.preDecodeInfo_valid = io_replay_bits_uop_preDecodeInfo_valid;
    replay.uop.preDecodeInfo_isRVC = io_replay_bits_uop_preDecodeInfo_isRVC;
    replay.uop.preDecodeInfo_brType = io_replay_bits_uop_preDecodeInfo_brType;
    replay.uop.preDecodeInfo_isCall = io_replay_bits_uop_preDecodeInfo_isCall;
    replay.uop.preDecodeInfo_isRet = io_replay_bits_uop_preDecodeInfo_isRet;
    replay.uop.pred_taken = io_replay_bits_uop_pred_taken;
    replay.uop.crossPageIPFFix = io_replay_bits_uop_crossPageIPFFix;
    replay.uop.ftqPtr_flag = io_replay_bits_uop_ftqPtr_flag;
    replay.uop.ftqPtr_value = io_replay_bits_uop_ftqPtr_value;
    replay.uop.ftqOffset = io_replay_bits_uop_ftqOffset;
    replay.uop.satpFlushFirstFetchFault = io_replay_bits_uop_satpFlushFirstFetchFault;
    replay.uop.srcType_0 = io_replay_bits_uop_srcType_0;
    replay.uop.srcType_1 = io_replay_bits_uop_srcType_1;
    replay.uop.srcType_2 = io_replay_bits_uop_srcType_2;
    replay.uop.srcType_3 = io_replay_bits_uop_srcType_3;
    replay.uop.srcType_4 = io_replay_bits_uop_srcType_4;
    replay.uop.ldest = io_replay_bits_uop_ldest;
    replay.uop.fuType = io_replay_bits_uop_fuType;
    replay.uop.fuOpType = io_replay_bits_uop_fuOpType;
    replay.uop.rfWen = io_replay_bits_uop_rfWen;
    replay.uop.fpWen = io_replay_bits_uop_fpWen;
    replay.uop.vecWen = io_replay_bits_uop_vecWen;
    replay.uop.v0Wen = io_replay_bits_uop_v0Wen;
    replay.uop.vlWen = io_replay_bits_uop_vlWen;
    replay.uop.isXSTrap = io_replay_bits_uop_isXSTrap;
    replay.uop.waitForward = io_replay_bits_uop_waitForward;
    replay.uop.blockBackward = io_replay_bits_uop_blockBackward;
    replay.uop.canRobCompress = io_replay_bits_uop_canRobCompress;
    replay.uop.selImm = io_replay_bits_uop_selImm;
    replay.uop.imm = io_replay_bits_uop_imm;
    replay.uop.fpu_typeTagOut = io_replay_bits_uop_fpu_typeTagOut;
    replay.uop.fpu_wflags = io_replay_bits_uop_fpu_wflags;
    replay.uop.fpu_typ = io_replay_bits_uop_fpu_typ;
    replay.uop.fpu_fmt = io_replay_bits_uop_fpu_fmt;
    replay.uop.fpu_rm = io_replay_bits_uop_fpu_rm;
    replay.uop.vpu_vill = io_replay_bits_uop_vpu_vill;
    replay.uop.vpu_vma = io_replay_bits_uop_vpu_vma;
    replay.uop.vpu_vta = io_replay_bits_uop_vpu_vta;
    replay.uop.vpu_vsew = io_replay_bits_uop_vpu_vsew;
    replay.uop.vpu_vlmul = io_replay_bits_uop_vpu_vlmul;
    replay.uop.vpu_specVill = io_replay_bits_uop_vpu_specVill;
    replay.uop.vpu_specVma = io_replay_bits_uop_vpu_specVma;
    replay.uop.vpu_specVta = io_replay_bits_uop_vpu_specVta;
    replay.uop.vpu_specVsew = io_replay_bits_uop_vpu_specVsew;
    replay.uop.vpu_specVlmul = io_replay_bits_uop_vpu_specVlmul;
    replay.uop.vpu_vm = io_replay_bits_uop_vpu_vm;
    replay.uop.vpu_vstart = io_replay_bits_uop_vpu_vstart;
    replay.uop.vpu_frm = io_replay_bits_uop_vpu_frm;
    replay.uop.vpu_fpu_isFpToVecInst = io_replay_bits_uop_vpu_fpu_isFpToVecInst;
    replay.uop.vpu_fpu_isFP32Instr = io_replay_bits_uop_vpu_fpu_isFP32Instr;
    replay.uop.vpu_fpu_isFP64Instr = io_replay_bits_uop_vpu_fpu_isFP64Instr;
    replay.uop.vpu_fpu_isReduction = io_replay_bits_uop_vpu_fpu_isReduction;
    replay.uop.vpu_fpu_isFoldTo1_2 = io_replay_bits_uop_vpu_fpu_isFoldTo1_2;
    replay.uop.vpu_fpu_isFoldTo1_4 = io_replay_bits_uop_vpu_fpu_isFoldTo1_4;
    replay.uop.vpu_fpu_isFoldTo1_8 = io_replay_bits_uop_vpu_fpu_isFoldTo1_8;
    replay.uop.vpu_vxrm = io_replay_bits_uop_vpu_vxrm;
    replay.uop.vpu_vuopIdx = io_replay_bits_uop_vpu_vuopIdx;
    replay.uop.vpu_lastUop = io_replay_bits_uop_vpu_lastUop;
    replay.uop.vpu_vmask = io_replay_bits_uop_vpu_vmask;
    replay.uop.vpu_vl = io_replay_bits_uop_vpu_vl;
    replay.uop.vpu_nf = io_replay_bits_uop_vpu_nf;
    replay.uop.vpu_veew = io_replay_bits_uop_vpu_veew;
    replay.uop.vpu_isReverse = io_replay_bits_uop_vpu_isReverse;
    replay.uop.vpu_isExt = io_replay_bits_uop_vpu_isExt;
    replay.uop.vpu_isNarrow = io_replay_bits_uop_vpu_isNarrow;
    replay.uop.vpu_isDstMask = io_replay_bits_uop_vpu_isDstMask;
    replay.uop.vpu_isOpMask = io_replay_bits_uop_vpu_isOpMask;
    replay.uop.vpu_isMove = io_replay_bits_uop_vpu_isMove;
    replay.uop.vpu_isDependOldVd = io_replay_bits_uop_vpu_isDependOldVd;
    replay.uop.vpu_isWritePartVd = io_replay_bits_uop_vpu_isWritePartVd;
    replay.uop.vpu_isVleff = io_replay_bits_uop_vpu_isVleff;
    replay.uop.vlsInstr = io_replay_bits_uop_vlsInstr;
    replay.uop.wfflags = io_replay_bits_uop_wfflags;
    replay.uop.isMove = io_replay_bits_uop_isMove;
    replay.uop.isDropAmocasSta = io_replay_bits_uop_isDropAmocasSta;
    replay.uop.uopIdx = io_replay_bits_uop_uopIdx;
    replay.uop.isVset = io_replay_bits_uop_isVset;
    replay.uop.firstUop = io_replay_bits_uop_firstUop;
    replay.uop.lastUop = io_replay_bits_uop_lastUop;
    replay.uop.numUops = io_replay_bits_uop_numUops;
    replay.uop.numWB = io_replay_bits_uop_numWB;
    replay.uop.commitType = io_replay_bits_uop_commitType;
    replay.uop.srcState_0 = io_replay_bits_uop_srcState_0;
    replay.uop.srcState_1 = io_replay_bits_uop_srcState_1;
    replay.uop.srcState_2 = io_replay_bits_uop_srcState_2;
    replay.uop.srcState_3 = io_replay_bits_uop_srcState_3;
    replay.uop.srcState_4 = io_replay_bits_uop_srcState_4;
    replay.uop.srcLoadDependency_0_0 = io_replay_bits_uop_srcLoadDependency_0_0;
    replay.uop.srcLoadDependency_0_1 = io_replay_bits_uop_srcLoadDependency_0_1;
    replay.uop.srcLoadDependency_0_2 = io_replay_bits_uop_srcLoadDependency_0_2;
    replay.uop.srcLoadDependency_1_0 = io_replay_bits_uop_srcLoadDependency_1_0;
    replay.uop.srcLoadDependency_1_1 = io_replay_bits_uop_srcLoadDependency_1_1;
    replay.uop.srcLoadDependency_1_2 = io_replay_bits_uop_srcLoadDependency_1_2;
    replay.uop.srcLoadDependency_2_0 = io_replay_bits_uop_srcLoadDependency_2_0;
    replay.uop.srcLoadDependency_2_1 = io_replay_bits_uop_srcLoadDependency_2_1;
    replay.uop.srcLoadDependency_2_2 = io_replay_bits_uop_srcLoadDependency_2_2;
    replay.uop.srcLoadDependency_3_0 = io_replay_bits_uop_srcLoadDependency_3_0;
    replay.uop.srcLoadDependency_3_1 = io_replay_bits_uop_srcLoadDependency_3_1;
    replay.uop.srcLoadDependency_3_2 = io_replay_bits_uop_srcLoadDependency_3_2;
    replay.uop.srcLoadDependency_4_0 = io_replay_bits_uop_srcLoadDependency_4_0;
    replay.uop.srcLoadDependency_4_1 = io_replay_bits_uop_srcLoadDependency_4_1;
    replay.uop.srcLoadDependency_4_2 = io_replay_bits_uop_srcLoadDependency_4_2;
    replay.uop.psrc_0 = io_replay_bits_uop_psrc_0;
    replay.uop.psrc_1 = io_replay_bits_uop_psrc_1;
    replay.uop.psrc_2 = io_replay_bits_uop_psrc_2;
    replay.uop.psrc_3 = io_replay_bits_uop_psrc_3;
    replay.uop.psrc_4 = io_replay_bits_uop_psrc_4;
    replay.uop.pdest = io_replay_bits_uop_pdest;
    replay.uop.useRegCache_0 = io_replay_bits_uop_useRegCache_0;
    replay.uop.useRegCache_1 = io_replay_bits_uop_useRegCache_1;
    replay.uop.regCacheIdx_0 = io_replay_bits_uop_regCacheIdx_0;
    replay.uop.regCacheIdx_1 = io_replay_bits_uop_regCacheIdx_1;
    replay.uop.robIdx_flag = io_replay_bits_uop_robIdx_flag;
    replay.uop.robIdx_value = io_replay_bits_uop_robIdx_value;
    replay.uop.instrSize = io_replay_bits_uop_instrSize;
    replay.uop.dirtyFs = io_replay_bits_uop_dirtyFs;
    replay.uop.dirtyVs = io_replay_bits_uop_dirtyVs;
    replay.uop.traceBlockInPipe_itype = io_replay_bits_uop_traceBlockInPipe_itype;
    replay.uop.traceBlockInPipe_iretire = io_replay_bits_uop_traceBlockInPipe_iretire;
    replay.uop.traceBlockInPipe_ilastsize = io_replay_bits_uop_traceBlockInPipe_ilastsize;
    replay.uop.eliminatedMove = io_replay_bits_uop_eliminatedMove;
    replay.uop.snapshot = io_replay_bits_uop_snapshot;
    replay.uop.debugInfo_eliminatedMove = io_replay_bits_uop_debugInfo_eliminatedMove;
    replay.uop.debugInfo_renameTime = io_replay_bits_uop_debugInfo_renameTime;
    replay.uop.debugInfo_dispatchTime = io_replay_bits_uop_debugInfo_dispatchTime;
    replay.uop.debugInfo_enqRsTime = io_replay_bits_uop_debugInfo_enqRsTime;
    replay.uop.debugInfo_selectTime = io_replay_bits_uop_debugInfo_selectTime;
    replay.uop.debugInfo_issueTime = io_replay_bits_uop_debugInfo_issueTime;
    replay.uop.debugInfo_writebackTime = io_replay_bits_uop_debugInfo_writebackTime;
    replay.uop.debugInfo_runahead_checkpoint_id = io_replay_bits_uop_debugInfo_runahead_checkpoint_id;
    replay.uop.debugInfo_tlbFirstReqTime = io_replay_bits_uop_debugInfo_tlbFirstReqTime;
    replay.uop.debugInfo_tlbRespTime = io_replay_bits_uop_debugInfo_tlbRespTime;
    replay.uop.debug_seqNum_seqNum = io_replay_bits_uop_debug_seqNum_seqNum;
    replay.uop.debug_seqNum_uopIdx = io_replay_bits_uop_debug_seqNum_uopIdx;
    replay.uop.storeSetHit = io_replay_bits_uop_storeSetHit;
    replay.uop.waitForRobIdx_flag = io_replay_bits_uop_waitForRobIdx_flag;
    replay.uop.waitForRobIdx_value = io_replay_bits_uop_waitForRobIdx_value;
    replay.uop.loadWaitBit = io_replay_bits_uop_loadWaitBit;
    replay.uop.ssid = io_replay_bits_uop_ssid;
    replay.uop.lqIdx_flag = io_replay_bits_uop_lqIdx_flag;
    replay.uop.lqIdx_value = io_replay_bits_uop_lqIdx_value;
    replay.uop.sqIdx_flag = io_replay_bits_uop_sqIdx_flag;
    replay.uop.sqIdx_value = io_replay_bits_uop_sqIdx_value;
    replay.uop.singleStep = io_replay_bits_uop_singleStep;
    replay.uop.debug_fuType = io_replay_bits_uop_debug_fuType;
    replay.uop.debug_sim_trig = io_replay_bits_uop_debug_sim_trig;
    replay.uop.numLsElem = io_replay_bits_uop_numLsElem;
    replay.vaddr = io_replay_bits_vaddr;
    replay.mask = io_replay_bits_mask;
    replay.isvec = io_replay_bits_isvec;
    replay.is128bit = io_replay_bits_is128bit;
    replay.elemIdx = io_replay_bits_elemIdx;
    replay.alignedType = io_replay_bits_alignedType;
    replay.mbIndex = io_replay_bits_mbIndex;
    replay.reg_offset = io_replay_bits_reg_offset;
    replay.elemIdxInsideVd = io_replay_bits_elemIdxInsideVd;
    replay.vecActive = io_replay_bits_vecActive;
    replay.mshrid = io_replay_bits_mshrid;
    replay.forward_tlDchannel = io_replay_bits_forward_tlDchannel;
    replay.schedIndex = io_replay_bits_schedIndex;
  end
  always_comb begin
    fast_rep_in = '0;
    fast_rep_in.uop.instr = io_fast_rep_in_bits_uop_instr;
    fast_rep_in.uop.pc = io_fast_rep_in_bits_uop_pc;
    fast_rep_in.uop.foldpc = io_fast_rep_in_bits_uop_foldpc;
    fast_rep_in.uop.exceptionVec[0] = io_fast_rep_in_bits_uop_exceptionVec_0;
    fast_rep_in.uop.exceptionVec[1] = io_fast_rep_in_bits_uop_exceptionVec_1;
    fast_rep_in.uop.exceptionVec[2] = io_fast_rep_in_bits_uop_exceptionVec_2;
    fast_rep_in.uop.exceptionVec[3] = io_fast_rep_in_bits_uop_exceptionVec_3;
    fast_rep_in.uop.exceptionVec[4] = io_fast_rep_in_bits_uop_exceptionVec_4;
    fast_rep_in.uop.exceptionVec[5] = io_fast_rep_in_bits_uop_exceptionVec_5;
    fast_rep_in.uop.exceptionVec[6] = io_fast_rep_in_bits_uop_exceptionVec_6;
    fast_rep_in.uop.exceptionVec[7] = io_fast_rep_in_bits_uop_exceptionVec_7;
    fast_rep_in.uop.exceptionVec[8] = io_fast_rep_in_bits_uop_exceptionVec_8;
    fast_rep_in.uop.exceptionVec[9] = io_fast_rep_in_bits_uop_exceptionVec_9;
    fast_rep_in.uop.exceptionVec[10] = io_fast_rep_in_bits_uop_exceptionVec_10;
    fast_rep_in.uop.exceptionVec[11] = io_fast_rep_in_bits_uop_exceptionVec_11;
    fast_rep_in.uop.exceptionVec[12] = io_fast_rep_in_bits_uop_exceptionVec_12;
    fast_rep_in.uop.exceptionVec[13] = io_fast_rep_in_bits_uop_exceptionVec_13;
    fast_rep_in.uop.exceptionVec[14] = io_fast_rep_in_bits_uop_exceptionVec_14;
    fast_rep_in.uop.exceptionVec[15] = io_fast_rep_in_bits_uop_exceptionVec_15;
    fast_rep_in.uop.exceptionVec[16] = io_fast_rep_in_bits_uop_exceptionVec_16;
    fast_rep_in.uop.exceptionVec[17] = io_fast_rep_in_bits_uop_exceptionVec_17;
    fast_rep_in.uop.exceptionVec[18] = io_fast_rep_in_bits_uop_exceptionVec_18;
    fast_rep_in.uop.exceptionVec[19] = io_fast_rep_in_bits_uop_exceptionVec_19;
    fast_rep_in.uop.exceptionVec[20] = io_fast_rep_in_bits_uop_exceptionVec_20;
    fast_rep_in.uop.exceptionVec[21] = io_fast_rep_in_bits_uop_exceptionVec_21;
    fast_rep_in.uop.exceptionVec[22] = io_fast_rep_in_bits_uop_exceptionVec_22;
    fast_rep_in.uop.exceptionVec[23] = io_fast_rep_in_bits_uop_exceptionVec_23;
    fast_rep_in.uop.isFetchMalAddr = io_fast_rep_in_bits_uop_isFetchMalAddr;
    fast_rep_in.uop.hasException = io_fast_rep_in_bits_uop_hasException;
    fast_rep_in.uop.trigger = io_fast_rep_in_bits_uop_trigger;
    fast_rep_in.uop.preDecodeInfo_valid = io_fast_rep_in_bits_uop_preDecodeInfo_valid;
    fast_rep_in.uop.preDecodeInfo_isRVC = io_fast_rep_in_bits_uop_preDecodeInfo_isRVC;
    fast_rep_in.uop.preDecodeInfo_brType = io_fast_rep_in_bits_uop_preDecodeInfo_brType;
    fast_rep_in.uop.preDecodeInfo_isCall = io_fast_rep_in_bits_uop_preDecodeInfo_isCall;
    fast_rep_in.uop.preDecodeInfo_isRet = io_fast_rep_in_bits_uop_preDecodeInfo_isRet;
    fast_rep_in.uop.pred_taken = io_fast_rep_in_bits_uop_pred_taken;
    fast_rep_in.uop.crossPageIPFFix = io_fast_rep_in_bits_uop_crossPageIPFFix;
    fast_rep_in.uop.ftqPtr_flag = io_fast_rep_in_bits_uop_ftqPtr_flag;
    fast_rep_in.uop.ftqPtr_value = io_fast_rep_in_bits_uop_ftqPtr_value;
    fast_rep_in.uop.ftqOffset = io_fast_rep_in_bits_uop_ftqOffset;
    fast_rep_in.uop.satpFlushFirstFetchFault = io_fast_rep_in_bits_uop_satpFlushFirstFetchFault;
    fast_rep_in.uop.srcType_0 = io_fast_rep_in_bits_uop_srcType_0;
    fast_rep_in.uop.srcType_1 = io_fast_rep_in_bits_uop_srcType_1;
    fast_rep_in.uop.srcType_2 = io_fast_rep_in_bits_uop_srcType_2;
    fast_rep_in.uop.srcType_3 = io_fast_rep_in_bits_uop_srcType_3;
    fast_rep_in.uop.srcType_4 = io_fast_rep_in_bits_uop_srcType_4;
    fast_rep_in.uop.ldest = io_fast_rep_in_bits_uop_ldest;
    fast_rep_in.uop.fuType = io_fast_rep_in_bits_uop_fuType;
    fast_rep_in.uop.fuOpType = io_fast_rep_in_bits_uop_fuOpType;
    fast_rep_in.uop.rfWen = io_fast_rep_in_bits_uop_rfWen;
    fast_rep_in.uop.fpWen = io_fast_rep_in_bits_uop_fpWen;
    fast_rep_in.uop.vecWen = io_fast_rep_in_bits_uop_vecWen;
    fast_rep_in.uop.v0Wen = io_fast_rep_in_bits_uop_v0Wen;
    fast_rep_in.uop.vlWen = io_fast_rep_in_bits_uop_vlWen;
    fast_rep_in.uop.isXSTrap = io_fast_rep_in_bits_uop_isXSTrap;
    fast_rep_in.uop.waitForward = io_fast_rep_in_bits_uop_waitForward;
    fast_rep_in.uop.blockBackward = io_fast_rep_in_bits_uop_blockBackward;
    fast_rep_in.uop.canRobCompress = io_fast_rep_in_bits_uop_canRobCompress;
    fast_rep_in.uop.selImm = io_fast_rep_in_bits_uop_selImm;
    fast_rep_in.uop.imm = io_fast_rep_in_bits_uop_imm;
    fast_rep_in.uop.fpu_typeTagOut = io_fast_rep_in_bits_uop_fpu_typeTagOut;
    fast_rep_in.uop.fpu_wflags = io_fast_rep_in_bits_uop_fpu_wflags;
    fast_rep_in.uop.fpu_typ = io_fast_rep_in_bits_uop_fpu_typ;
    fast_rep_in.uop.fpu_fmt = io_fast_rep_in_bits_uop_fpu_fmt;
    fast_rep_in.uop.fpu_rm = io_fast_rep_in_bits_uop_fpu_rm;
    fast_rep_in.uop.vpu_vill = io_fast_rep_in_bits_uop_vpu_vill;
    fast_rep_in.uop.vpu_vma = io_fast_rep_in_bits_uop_vpu_vma;
    fast_rep_in.uop.vpu_vta = io_fast_rep_in_bits_uop_vpu_vta;
    fast_rep_in.uop.vpu_vsew = io_fast_rep_in_bits_uop_vpu_vsew;
    fast_rep_in.uop.vpu_vlmul = io_fast_rep_in_bits_uop_vpu_vlmul;
    fast_rep_in.uop.vpu_specVill = io_fast_rep_in_bits_uop_vpu_specVill;
    fast_rep_in.uop.vpu_specVma = io_fast_rep_in_bits_uop_vpu_specVma;
    fast_rep_in.uop.vpu_specVta = io_fast_rep_in_bits_uop_vpu_specVta;
    fast_rep_in.uop.vpu_specVsew = io_fast_rep_in_bits_uop_vpu_specVsew;
    fast_rep_in.uop.vpu_specVlmul = io_fast_rep_in_bits_uop_vpu_specVlmul;
    fast_rep_in.uop.vpu_vm = io_fast_rep_in_bits_uop_vpu_vm;
    fast_rep_in.uop.vpu_vstart = io_fast_rep_in_bits_uop_vpu_vstart;
    fast_rep_in.uop.vpu_frm = io_fast_rep_in_bits_uop_vpu_frm;
    fast_rep_in.uop.vpu_fpu_isFpToVecInst = io_fast_rep_in_bits_uop_vpu_fpu_isFpToVecInst;
    fast_rep_in.uop.vpu_fpu_isFP32Instr = io_fast_rep_in_bits_uop_vpu_fpu_isFP32Instr;
    fast_rep_in.uop.vpu_fpu_isFP64Instr = io_fast_rep_in_bits_uop_vpu_fpu_isFP64Instr;
    fast_rep_in.uop.vpu_fpu_isReduction = io_fast_rep_in_bits_uop_vpu_fpu_isReduction;
    fast_rep_in.uop.vpu_fpu_isFoldTo1_2 = io_fast_rep_in_bits_uop_vpu_fpu_isFoldTo1_2;
    fast_rep_in.uop.vpu_fpu_isFoldTo1_4 = io_fast_rep_in_bits_uop_vpu_fpu_isFoldTo1_4;
    fast_rep_in.uop.vpu_fpu_isFoldTo1_8 = io_fast_rep_in_bits_uop_vpu_fpu_isFoldTo1_8;
    fast_rep_in.uop.vpu_vxrm = io_fast_rep_in_bits_uop_vpu_vxrm;
    fast_rep_in.uop.vpu_vuopIdx = io_fast_rep_in_bits_uop_vpu_vuopIdx;
    fast_rep_in.uop.vpu_lastUop = io_fast_rep_in_bits_uop_vpu_lastUop;
    fast_rep_in.uop.vpu_vmask = io_fast_rep_in_bits_uop_vpu_vmask;
    fast_rep_in.uop.vpu_vl = io_fast_rep_in_bits_uop_vpu_vl;
    fast_rep_in.uop.vpu_nf = io_fast_rep_in_bits_uop_vpu_nf;
    fast_rep_in.uop.vpu_veew = io_fast_rep_in_bits_uop_vpu_veew;
    fast_rep_in.uop.vpu_isReverse = io_fast_rep_in_bits_uop_vpu_isReverse;
    fast_rep_in.uop.vpu_isExt = io_fast_rep_in_bits_uop_vpu_isExt;
    fast_rep_in.uop.vpu_isNarrow = io_fast_rep_in_bits_uop_vpu_isNarrow;
    fast_rep_in.uop.vpu_isDstMask = io_fast_rep_in_bits_uop_vpu_isDstMask;
    fast_rep_in.uop.vpu_isOpMask = io_fast_rep_in_bits_uop_vpu_isOpMask;
    fast_rep_in.uop.vpu_isMove = io_fast_rep_in_bits_uop_vpu_isMove;
    fast_rep_in.uop.vpu_isDependOldVd = io_fast_rep_in_bits_uop_vpu_isDependOldVd;
    fast_rep_in.uop.vpu_isWritePartVd = io_fast_rep_in_bits_uop_vpu_isWritePartVd;
    fast_rep_in.uop.vpu_isVleff = io_fast_rep_in_bits_uop_vpu_isVleff;
    fast_rep_in.uop.vlsInstr = io_fast_rep_in_bits_uop_vlsInstr;
    fast_rep_in.uop.wfflags = io_fast_rep_in_bits_uop_wfflags;
    fast_rep_in.uop.isMove = io_fast_rep_in_bits_uop_isMove;
    fast_rep_in.uop.isDropAmocasSta = io_fast_rep_in_bits_uop_isDropAmocasSta;
    fast_rep_in.uop.uopIdx = io_fast_rep_in_bits_uop_uopIdx;
    fast_rep_in.uop.isVset = io_fast_rep_in_bits_uop_isVset;
    fast_rep_in.uop.firstUop = io_fast_rep_in_bits_uop_firstUop;
    fast_rep_in.uop.lastUop = io_fast_rep_in_bits_uop_lastUop;
    fast_rep_in.uop.numUops = io_fast_rep_in_bits_uop_numUops;
    fast_rep_in.uop.numWB = io_fast_rep_in_bits_uop_numWB;
    fast_rep_in.uop.commitType = io_fast_rep_in_bits_uop_commitType;
    fast_rep_in.uop.srcState_0 = io_fast_rep_in_bits_uop_srcState_0;
    fast_rep_in.uop.srcState_1 = io_fast_rep_in_bits_uop_srcState_1;
    fast_rep_in.uop.srcState_2 = io_fast_rep_in_bits_uop_srcState_2;
    fast_rep_in.uop.srcState_3 = io_fast_rep_in_bits_uop_srcState_3;
    fast_rep_in.uop.srcState_4 = io_fast_rep_in_bits_uop_srcState_4;
    fast_rep_in.uop.srcLoadDependency_0_0 = io_fast_rep_in_bits_uop_srcLoadDependency_0_0;
    fast_rep_in.uop.srcLoadDependency_0_1 = io_fast_rep_in_bits_uop_srcLoadDependency_0_1;
    fast_rep_in.uop.srcLoadDependency_0_2 = io_fast_rep_in_bits_uop_srcLoadDependency_0_2;
    fast_rep_in.uop.srcLoadDependency_1_0 = io_fast_rep_in_bits_uop_srcLoadDependency_1_0;
    fast_rep_in.uop.srcLoadDependency_1_1 = io_fast_rep_in_bits_uop_srcLoadDependency_1_1;
    fast_rep_in.uop.srcLoadDependency_1_2 = io_fast_rep_in_bits_uop_srcLoadDependency_1_2;
    fast_rep_in.uop.srcLoadDependency_2_0 = io_fast_rep_in_bits_uop_srcLoadDependency_2_0;
    fast_rep_in.uop.srcLoadDependency_2_1 = io_fast_rep_in_bits_uop_srcLoadDependency_2_1;
    fast_rep_in.uop.srcLoadDependency_2_2 = io_fast_rep_in_bits_uop_srcLoadDependency_2_2;
    fast_rep_in.uop.srcLoadDependency_3_0 = io_fast_rep_in_bits_uop_srcLoadDependency_3_0;
    fast_rep_in.uop.srcLoadDependency_3_1 = io_fast_rep_in_bits_uop_srcLoadDependency_3_1;
    fast_rep_in.uop.srcLoadDependency_3_2 = io_fast_rep_in_bits_uop_srcLoadDependency_3_2;
    fast_rep_in.uop.srcLoadDependency_4_0 = io_fast_rep_in_bits_uop_srcLoadDependency_4_0;
    fast_rep_in.uop.srcLoadDependency_4_1 = io_fast_rep_in_bits_uop_srcLoadDependency_4_1;
    fast_rep_in.uop.srcLoadDependency_4_2 = io_fast_rep_in_bits_uop_srcLoadDependency_4_2;
    fast_rep_in.uop.psrc_0 = io_fast_rep_in_bits_uop_psrc_0;
    fast_rep_in.uop.psrc_1 = io_fast_rep_in_bits_uop_psrc_1;
    fast_rep_in.uop.psrc_2 = io_fast_rep_in_bits_uop_psrc_2;
    fast_rep_in.uop.psrc_3 = io_fast_rep_in_bits_uop_psrc_3;
    fast_rep_in.uop.psrc_4 = io_fast_rep_in_bits_uop_psrc_4;
    fast_rep_in.uop.pdest = io_fast_rep_in_bits_uop_pdest;
    fast_rep_in.uop.useRegCache_0 = io_fast_rep_in_bits_uop_useRegCache_0;
    fast_rep_in.uop.useRegCache_1 = io_fast_rep_in_bits_uop_useRegCache_1;
    fast_rep_in.uop.regCacheIdx_0 = io_fast_rep_in_bits_uop_regCacheIdx_0;
    fast_rep_in.uop.regCacheIdx_1 = io_fast_rep_in_bits_uop_regCacheIdx_1;
    fast_rep_in.uop.robIdx_flag = io_fast_rep_in_bits_uop_robIdx_flag;
    fast_rep_in.uop.robIdx_value = io_fast_rep_in_bits_uop_robIdx_value;
    fast_rep_in.uop.instrSize = io_fast_rep_in_bits_uop_instrSize;
    fast_rep_in.uop.dirtyFs = io_fast_rep_in_bits_uop_dirtyFs;
    fast_rep_in.uop.dirtyVs = io_fast_rep_in_bits_uop_dirtyVs;
    fast_rep_in.uop.traceBlockInPipe_itype = io_fast_rep_in_bits_uop_traceBlockInPipe_itype;
    fast_rep_in.uop.traceBlockInPipe_iretire = io_fast_rep_in_bits_uop_traceBlockInPipe_iretire;
    fast_rep_in.uop.traceBlockInPipe_ilastsize = io_fast_rep_in_bits_uop_traceBlockInPipe_ilastsize;
    fast_rep_in.uop.eliminatedMove = io_fast_rep_in_bits_uop_eliminatedMove;
    fast_rep_in.uop.snapshot = io_fast_rep_in_bits_uop_snapshot;
    fast_rep_in.uop.debugInfo_eliminatedMove = io_fast_rep_in_bits_uop_debugInfo_eliminatedMove;
    fast_rep_in.uop.debugInfo_renameTime = io_fast_rep_in_bits_uop_debugInfo_renameTime;
    fast_rep_in.uop.debugInfo_dispatchTime = io_fast_rep_in_bits_uop_debugInfo_dispatchTime;
    fast_rep_in.uop.debugInfo_enqRsTime = io_fast_rep_in_bits_uop_debugInfo_enqRsTime;
    fast_rep_in.uop.debugInfo_selectTime = io_fast_rep_in_bits_uop_debugInfo_selectTime;
    fast_rep_in.uop.debugInfo_issueTime = io_fast_rep_in_bits_uop_debugInfo_issueTime;
    fast_rep_in.uop.debugInfo_writebackTime = io_fast_rep_in_bits_uop_debugInfo_writebackTime;
    fast_rep_in.uop.debugInfo_runahead_checkpoint_id = io_fast_rep_in_bits_uop_debugInfo_runahead_checkpoint_id;
    fast_rep_in.uop.debugInfo_tlbFirstReqTime = io_fast_rep_in_bits_uop_debugInfo_tlbFirstReqTime;
    fast_rep_in.uop.debugInfo_tlbRespTime = io_fast_rep_in_bits_uop_debugInfo_tlbRespTime;
    fast_rep_in.uop.debug_seqNum_seqNum = io_fast_rep_in_bits_uop_debug_seqNum_seqNum;
    fast_rep_in.uop.debug_seqNum_uopIdx = io_fast_rep_in_bits_uop_debug_seqNum_uopIdx;
    fast_rep_in.uop.storeSetHit = io_fast_rep_in_bits_uop_storeSetHit;
    fast_rep_in.uop.waitForRobIdx_flag = io_fast_rep_in_bits_uop_waitForRobIdx_flag;
    fast_rep_in.uop.waitForRobIdx_value = io_fast_rep_in_bits_uop_waitForRobIdx_value;
    fast_rep_in.uop.loadWaitBit = io_fast_rep_in_bits_uop_loadWaitBit;
    fast_rep_in.uop.loadWaitStrict = io_fast_rep_in_bits_uop_loadWaitStrict;
    fast_rep_in.uop.ssid = io_fast_rep_in_bits_uop_ssid;
    fast_rep_in.uop.lqIdx_flag = io_fast_rep_in_bits_uop_lqIdx_flag;
    fast_rep_in.uop.lqIdx_value = io_fast_rep_in_bits_uop_lqIdx_value;
    fast_rep_in.uop.sqIdx_flag = io_fast_rep_in_bits_uop_sqIdx_flag;
    fast_rep_in.uop.sqIdx_value = io_fast_rep_in_bits_uop_sqIdx_value;
    fast_rep_in.uop.singleStep = io_fast_rep_in_bits_uop_singleStep;
    fast_rep_in.uop.replayInst = io_fast_rep_in_bits_uop_replayInst;
    fast_rep_in.uop.debug_fuType = io_fast_rep_in_bits_uop_debug_fuType;
    fast_rep_in.uop.debug_sim_trig = io_fast_rep_in_bits_uop_debug_sim_trig;
    fast_rep_in.uop.numLsElem = io_fast_rep_in_bits_uop_numLsElem;
    fast_rep_in.vaddr = io_fast_rep_in_bits_vaddr;
    fast_rep_in.paddr = io_fast_rep_in_bits_paddr;
    fast_rep_in.mask = io_fast_rep_in_bits_mask;
    fast_rep_in.data = io_fast_rep_in_bits_data;
    fast_rep_in.isvec = io_fast_rep_in_bits_isvec;
    fast_rep_in.is128bit = io_fast_rep_in_bits_is128bit;
    fast_rep_in.elemIdx = io_fast_rep_in_bits_elemIdx;
    fast_rep_in.alignedType = io_fast_rep_in_bits_alignedType;
    fast_rep_in.mbIndex = io_fast_rep_in_bits_mbIndex;
    fast_rep_in.reg_offset = io_fast_rep_in_bits_reg_offset;
    fast_rep_in.elemIdxInsideVd = io_fast_rep_in_bits_elemIdxInsideVd;
    fast_rep_in.vecActive = io_fast_rep_in_bits_vecActive;
    fast_rep_in.isLoadReplay = io_fast_rep_in_bits_isLoadReplay;
    fast_rep_in.hasROBEntry = io_fast_rep_in_bits_hasROBEntry;
    fast_rep_in.lateKill = io_fast_rep_in_bits_lateKill;
    fast_rep_in.schedIndex = io_fast_rep_in_bits_schedIndex;
    fast_rep_in.isFrmMisAlignBuf = io_fast_rep_in_bits_isFrmMisAlignBuf;
    fast_rep_in.rep_info_mshr_id = io_fast_rep_in_bits_rep_info_mshr_id;
  end
  always_comb begin
    lsq_nc_ldin = '0;
    lsq_nc_ldin.uop.instr = io_lsq_nc_ldin_bits_uop_instr;
    lsq_nc_ldin.uop.pc = io_lsq_nc_ldin_bits_uop_pc;
    lsq_nc_ldin.uop.foldpc = io_lsq_nc_ldin_bits_uop_foldpc;
    lsq_nc_ldin.uop.exceptionVec[0] = io_lsq_nc_ldin_bits_uop_exceptionVec_0;
    lsq_nc_ldin.uop.exceptionVec[1] = io_lsq_nc_ldin_bits_uop_exceptionVec_1;
    lsq_nc_ldin.uop.exceptionVec[2] = io_lsq_nc_ldin_bits_uop_exceptionVec_2;
    lsq_nc_ldin.uop.exceptionVec[3] = io_lsq_nc_ldin_bits_uop_exceptionVec_3;
    lsq_nc_ldin.uop.exceptionVec[4] = io_lsq_nc_ldin_bits_uop_exceptionVec_4;
    lsq_nc_ldin.uop.exceptionVec[5] = io_lsq_nc_ldin_bits_uop_exceptionVec_5;
    lsq_nc_ldin.uop.exceptionVec[6] = io_lsq_nc_ldin_bits_uop_exceptionVec_6;
    lsq_nc_ldin.uop.exceptionVec[7] = io_lsq_nc_ldin_bits_uop_exceptionVec_7;
    lsq_nc_ldin.uop.exceptionVec[8] = io_lsq_nc_ldin_bits_uop_exceptionVec_8;
    lsq_nc_ldin.uop.exceptionVec[9] = io_lsq_nc_ldin_bits_uop_exceptionVec_9;
    lsq_nc_ldin.uop.exceptionVec[10] = io_lsq_nc_ldin_bits_uop_exceptionVec_10;
    lsq_nc_ldin.uop.exceptionVec[11] = io_lsq_nc_ldin_bits_uop_exceptionVec_11;
    lsq_nc_ldin.uop.exceptionVec[12] = io_lsq_nc_ldin_bits_uop_exceptionVec_12;
    lsq_nc_ldin.uop.exceptionVec[13] = io_lsq_nc_ldin_bits_uop_exceptionVec_13;
    lsq_nc_ldin.uop.exceptionVec[14] = io_lsq_nc_ldin_bits_uop_exceptionVec_14;
    lsq_nc_ldin.uop.exceptionVec[15] = io_lsq_nc_ldin_bits_uop_exceptionVec_15;
    lsq_nc_ldin.uop.exceptionVec[16] = io_lsq_nc_ldin_bits_uop_exceptionVec_16;
    lsq_nc_ldin.uop.exceptionVec[17] = io_lsq_nc_ldin_bits_uop_exceptionVec_17;
    lsq_nc_ldin.uop.exceptionVec[18] = io_lsq_nc_ldin_bits_uop_exceptionVec_18;
    lsq_nc_ldin.uop.exceptionVec[19] = io_lsq_nc_ldin_bits_uop_exceptionVec_19;
    lsq_nc_ldin.uop.exceptionVec[20] = io_lsq_nc_ldin_bits_uop_exceptionVec_20;
    lsq_nc_ldin.uop.exceptionVec[21] = io_lsq_nc_ldin_bits_uop_exceptionVec_21;
    lsq_nc_ldin.uop.exceptionVec[22] = io_lsq_nc_ldin_bits_uop_exceptionVec_22;
    lsq_nc_ldin.uop.exceptionVec[23] = io_lsq_nc_ldin_bits_uop_exceptionVec_23;
    lsq_nc_ldin.uop.isFetchMalAddr = io_lsq_nc_ldin_bits_uop_isFetchMalAddr;
    lsq_nc_ldin.uop.hasException = io_lsq_nc_ldin_bits_uop_hasException;
    lsq_nc_ldin.uop.trigger = io_lsq_nc_ldin_bits_uop_trigger;
    lsq_nc_ldin.uop.preDecodeInfo_valid = io_lsq_nc_ldin_bits_uop_preDecodeInfo_valid;
    lsq_nc_ldin.uop.preDecodeInfo_isRVC = io_lsq_nc_ldin_bits_uop_preDecodeInfo_isRVC;
    lsq_nc_ldin.uop.preDecodeInfo_brType = io_lsq_nc_ldin_bits_uop_preDecodeInfo_brType;
    lsq_nc_ldin.uop.preDecodeInfo_isCall = io_lsq_nc_ldin_bits_uop_preDecodeInfo_isCall;
    lsq_nc_ldin.uop.preDecodeInfo_isRet = io_lsq_nc_ldin_bits_uop_preDecodeInfo_isRet;
    lsq_nc_ldin.uop.pred_taken = io_lsq_nc_ldin_bits_uop_pred_taken;
    lsq_nc_ldin.uop.crossPageIPFFix = io_lsq_nc_ldin_bits_uop_crossPageIPFFix;
    lsq_nc_ldin.uop.ftqPtr_flag = io_lsq_nc_ldin_bits_uop_ftqPtr_flag;
    lsq_nc_ldin.uop.ftqPtr_value = io_lsq_nc_ldin_bits_uop_ftqPtr_value;
    lsq_nc_ldin.uop.ftqOffset = io_lsq_nc_ldin_bits_uop_ftqOffset;
    lsq_nc_ldin.uop.satpFlushFirstFetchFault = io_lsq_nc_ldin_bits_uop_satpFlushFirstFetchFault;
    lsq_nc_ldin.uop.srcType_0 = io_lsq_nc_ldin_bits_uop_srcType_0;
    lsq_nc_ldin.uop.srcType_1 = io_lsq_nc_ldin_bits_uop_srcType_1;
    lsq_nc_ldin.uop.srcType_2 = io_lsq_nc_ldin_bits_uop_srcType_2;
    lsq_nc_ldin.uop.srcType_3 = io_lsq_nc_ldin_bits_uop_srcType_3;
    lsq_nc_ldin.uop.srcType_4 = io_lsq_nc_ldin_bits_uop_srcType_4;
    lsq_nc_ldin.uop.ldest = io_lsq_nc_ldin_bits_uop_ldest;
    lsq_nc_ldin.uop.fuType = io_lsq_nc_ldin_bits_uop_fuType;
    lsq_nc_ldin.uop.fuOpType = io_lsq_nc_ldin_bits_uop_fuOpType;
    lsq_nc_ldin.uop.rfWen = io_lsq_nc_ldin_bits_uop_rfWen;
    lsq_nc_ldin.uop.fpWen = io_lsq_nc_ldin_bits_uop_fpWen;
    lsq_nc_ldin.uop.vecWen = io_lsq_nc_ldin_bits_uop_vecWen;
    lsq_nc_ldin.uop.v0Wen = io_lsq_nc_ldin_bits_uop_v0Wen;
    lsq_nc_ldin.uop.vlWen = io_lsq_nc_ldin_bits_uop_vlWen;
    lsq_nc_ldin.uop.isXSTrap = io_lsq_nc_ldin_bits_uop_isXSTrap;
    lsq_nc_ldin.uop.waitForward = io_lsq_nc_ldin_bits_uop_waitForward;
    lsq_nc_ldin.uop.blockBackward = io_lsq_nc_ldin_bits_uop_blockBackward;
    lsq_nc_ldin.uop.flushPipe = io_lsq_nc_ldin_bits_uop_flushPipe;
    lsq_nc_ldin.uop.canRobCompress = io_lsq_nc_ldin_bits_uop_canRobCompress;
    lsq_nc_ldin.uop.selImm = io_lsq_nc_ldin_bits_uop_selImm;
    lsq_nc_ldin.uop.imm = io_lsq_nc_ldin_bits_uop_imm;
    lsq_nc_ldin.uop.fpu_typeTagOut = io_lsq_nc_ldin_bits_uop_fpu_typeTagOut;
    lsq_nc_ldin.uop.fpu_wflags = io_lsq_nc_ldin_bits_uop_fpu_wflags;
    lsq_nc_ldin.uop.fpu_typ = io_lsq_nc_ldin_bits_uop_fpu_typ;
    lsq_nc_ldin.uop.fpu_fmt = io_lsq_nc_ldin_bits_uop_fpu_fmt;
    lsq_nc_ldin.uop.fpu_rm = io_lsq_nc_ldin_bits_uop_fpu_rm;
    lsq_nc_ldin.uop.vpu_vill = io_lsq_nc_ldin_bits_uop_vpu_vill;
    lsq_nc_ldin.uop.vpu_vma = io_lsq_nc_ldin_bits_uop_vpu_vma;
    lsq_nc_ldin.uop.vpu_vta = io_lsq_nc_ldin_bits_uop_vpu_vta;
    lsq_nc_ldin.uop.vpu_vsew = io_lsq_nc_ldin_bits_uop_vpu_vsew;
    lsq_nc_ldin.uop.vpu_vlmul = io_lsq_nc_ldin_bits_uop_vpu_vlmul;
    lsq_nc_ldin.uop.vpu_specVill = io_lsq_nc_ldin_bits_uop_vpu_specVill;
    lsq_nc_ldin.uop.vpu_specVma = io_lsq_nc_ldin_bits_uop_vpu_specVma;
    lsq_nc_ldin.uop.vpu_specVta = io_lsq_nc_ldin_bits_uop_vpu_specVta;
    lsq_nc_ldin.uop.vpu_specVsew = io_lsq_nc_ldin_bits_uop_vpu_specVsew;
    lsq_nc_ldin.uop.vpu_specVlmul = io_lsq_nc_ldin_bits_uop_vpu_specVlmul;
    lsq_nc_ldin.uop.vpu_vm = io_lsq_nc_ldin_bits_uop_vpu_vm;
    lsq_nc_ldin.uop.vpu_vstart = io_lsq_nc_ldin_bits_uop_vpu_vstart;
    lsq_nc_ldin.uop.vpu_frm = io_lsq_nc_ldin_bits_uop_vpu_frm;
    lsq_nc_ldin.uop.vpu_fpu_isFpToVecInst = io_lsq_nc_ldin_bits_uop_vpu_fpu_isFpToVecInst;
    lsq_nc_ldin.uop.vpu_fpu_isFP32Instr = io_lsq_nc_ldin_bits_uop_vpu_fpu_isFP32Instr;
    lsq_nc_ldin.uop.vpu_fpu_isFP64Instr = io_lsq_nc_ldin_bits_uop_vpu_fpu_isFP64Instr;
    lsq_nc_ldin.uop.vpu_fpu_isReduction = io_lsq_nc_ldin_bits_uop_vpu_fpu_isReduction;
    lsq_nc_ldin.uop.vpu_fpu_isFoldTo1_2 = io_lsq_nc_ldin_bits_uop_vpu_fpu_isFoldTo1_2;
    lsq_nc_ldin.uop.vpu_fpu_isFoldTo1_4 = io_lsq_nc_ldin_bits_uop_vpu_fpu_isFoldTo1_4;
    lsq_nc_ldin.uop.vpu_fpu_isFoldTo1_8 = io_lsq_nc_ldin_bits_uop_vpu_fpu_isFoldTo1_8;
    lsq_nc_ldin.uop.vpu_vxrm = io_lsq_nc_ldin_bits_uop_vpu_vxrm;
    lsq_nc_ldin.uop.vpu_vuopIdx = io_lsq_nc_ldin_bits_uop_vpu_vuopIdx;
    lsq_nc_ldin.uop.vpu_lastUop = io_lsq_nc_ldin_bits_uop_vpu_lastUop;
    lsq_nc_ldin.uop.vpu_vmask = io_lsq_nc_ldin_bits_uop_vpu_vmask;
    lsq_nc_ldin.uop.vpu_vl = io_lsq_nc_ldin_bits_uop_vpu_vl;
    lsq_nc_ldin.uop.vpu_nf = io_lsq_nc_ldin_bits_uop_vpu_nf;
    lsq_nc_ldin.uop.vpu_veew = io_lsq_nc_ldin_bits_uop_vpu_veew;
    lsq_nc_ldin.uop.vpu_isReverse = io_lsq_nc_ldin_bits_uop_vpu_isReverse;
    lsq_nc_ldin.uop.vpu_isExt = io_lsq_nc_ldin_bits_uop_vpu_isExt;
    lsq_nc_ldin.uop.vpu_isNarrow = io_lsq_nc_ldin_bits_uop_vpu_isNarrow;
    lsq_nc_ldin.uop.vpu_isDstMask = io_lsq_nc_ldin_bits_uop_vpu_isDstMask;
    lsq_nc_ldin.uop.vpu_isOpMask = io_lsq_nc_ldin_bits_uop_vpu_isOpMask;
    lsq_nc_ldin.uop.vpu_isMove = io_lsq_nc_ldin_bits_uop_vpu_isMove;
    lsq_nc_ldin.uop.vpu_isDependOldVd = io_lsq_nc_ldin_bits_uop_vpu_isDependOldVd;
    lsq_nc_ldin.uop.vpu_isWritePartVd = io_lsq_nc_ldin_bits_uop_vpu_isWritePartVd;
    lsq_nc_ldin.uop.vpu_isVleff = io_lsq_nc_ldin_bits_uop_vpu_isVleff;
    lsq_nc_ldin.uop.vlsInstr = io_lsq_nc_ldin_bits_uop_vlsInstr;
    lsq_nc_ldin.uop.wfflags = io_lsq_nc_ldin_bits_uop_wfflags;
    lsq_nc_ldin.uop.isMove = io_lsq_nc_ldin_bits_uop_isMove;
    lsq_nc_ldin.uop.isDropAmocasSta = io_lsq_nc_ldin_bits_uop_isDropAmocasSta;
    lsq_nc_ldin.uop.uopIdx = io_lsq_nc_ldin_bits_uop_uopIdx;
    lsq_nc_ldin.uop.isVset = io_lsq_nc_ldin_bits_uop_isVset;
    lsq_nc_ldin.uop.firstUop = io_lsq_nc_ldin_bits_uop_firstUop;
    lsq_nc_ldin.uop.lastUop = io_lsq_nc_ldin_bits_uop_lastUop;
    lsq_nc_ldin.uop.numUops = io_lsq_nc_ldin_bits_uop_numUops;
    lsq_nc_ldin.uop.numWB = io_lsq_nc_ldin_bits_uop_numWB;
    lsq_nc_ldin.uop.commitType = io_lsq_nc_ldin_bits_uop_commitType;
    lsq_nc_ldin.uop.srcState_0 = io_lsq_nc_ldin_bits_uop_srcState_0;
    lsq_nc_ldin.uop.srcState_1 = io_lsq_nc_ldin_bits_uop_srcState_1;
    lsq_nc_ldin.uop.srcState_2 = io_lsq_nc_ldin_bits_uop_srcState_2;
    lsq_nc_ldin.uop.srcState_3 = io_lsq_nc_ldin_bits_uop_srcState_3;
    lsq_nc_ldin.uop.srcState_4 = io_lsq_nc_ldin_bits_uop_srcState_4;
    lsq_nc_ldin.uop.srcLoadDependency_0_0 = io_lsq_nc_ldin_bits_uop_srcLoadDependency_0_0;
    lsq_nc_ldin.uop.srcLoadDependency_0_1 = io_lsq_nc_ldin_bits_uop_srcLoadDependency_0_1;
    lsq_nc_ldin.uop.srcLoadDependency_0_2 = io_lsq_nc_ldin_bits_uop_srcLoadDependency_0_2;
    lsq_nc_ldin.uop.srcLoadDependency_1_0 = io_lsq_nc_ldin_bits_uop_srcLoadDependency_1_0;
    lsq_nc_ldin.uop.srcLoadDependency_1_1 = io_lsq_nc_ldin_bits_uop_srcLoadDependency_1_1;
    lsq_nc_ldin.uop.srcLoadDependency_1_2 = io_lsq_nc_ldin_bits_uop_srcLoadDependency_1_2;
    lsq_nc_ldin.uop.srcLoadDependency_2_0 = io_lsq_nc_ldin_bits_uop_srcLoadDependency_2_0;
    lsq_nc_ldin.uop.srcLoadDependency_2_1 = io_lsq_nc_ldin_bits_uop_srcLoadDependency_2_1;
    lsq_nc_ldin.uop.srcLoadDependency_2_2 = io_lsq_nc_ldin_bits_uop_srcLoadDependency_2_2;
    lsq_nc_ldin.uop.srcLoadDependency_3_0 = io_lsq_nc_ldin_bits_uop_srcLoadDependency_3_0;
    lsq_nc_ldin.uop.srcLoadDependency_3_1 = io_lsq_nc_ldin_bits_uop_srcLoadDependency_3_1;
    lsq_nc_ldin.uop.srcLoadDependency_3_2 = io_lsq_nc_ldin_bits_uop_srcLoadDependency_3_2;
    lsq_nc_ldin.uop.srcLoadDependency_4_0 = io_lsq_nc_ldin_bits_uop_srcLoadDependency_4_0;
    lsq_nc_ldin.uop.srcLoadDependency_4_1 = io_lsq_nc_ldin_bits_uop_srcLoadDependency_4_1;
    lsq_nc_ldin.uop.srcLoadDependency_4_2 = io_lsq_nc_ldin_bits_uop_srcLoadDependency_4_2;
    lsq_nc_ldin.uop.psrc_0 = io_lsq_nc_ldin_bits_uop_psrc_0;
    lsq_nc_ldin.uop.psrc_1 = io_lsq_nc_ldin_bits_uop_psrc_1;
    lsq_nc_ldin.uop.psrc_2 = io_lsq_nc_ldin_bits_uop_psrc_2;
    lsq_nc_ldin.uop.psrc_3 = io_lsq_nc_ldin_bits_uop_psrc_3;
    lsq_nc_ldin.uop.psrc_4 = io_lsq_nc_ldin_bits_uop_psrc_4;
    lsq_nc_ldin.uop.pdest = io_lsq_nc_ldin_bits_uop_pdest;
    lsq_nc_ldin.uop.useRegCache_0 = io_lsq_nc_ldin_bits_uop_useRegCache_0;
    lsq_nc_ldin.uop.useRegCache_1 = io_lsq_nc_ldin_bits_uop_useRegCache_1;
    lsq_nc_ldin.uop.regCacheIdx_0 = io_lsq_nc_ldin_bits_uop_regCacheIdx_0;
    lsq_nc_ldin.uop.regCacheIdx_1 = io_lsq_nc_ldin_bits_uop_regCacheIdx_1;
    lsq_nc_ldin.uop.robIdx_flag = io_lsq_nc_ldin_bits_uop_robIdx_flag;
    lsq_nc_ldin.uop.robIdx_value = io_lsq_nc_ldin_bits_uop_robIdx_value;
    lsq_nc_ldin.uop.instrSize = io_lsq_nc_ldin_bits_uop_instrSize;
    lsq_nc_ldin.uop.dirtyFs = io_lsq_nc_ldin_bits_uop_dirtyFs;
    lsq_nc_ldin.uop.dirtyVs = io_lsq_nc_ldin_bits_uop_dirtyVs;
    lsq_nc_ldin.uop.traceBlockInPipe_itype = io_lsq_nc_ldin_bits_uop_traceBlockInPipe_itype;
    lsq_nc_ldin.uop.traceBlockInPipe_iretire = io_lsq_nc_ldin_bits_uop_traceBlockInPipe_iretire;
    lsq_nc_ldin.uop.traceBlockInPipe_ilastsize = io_lsq_nc_ldin_bits_uop_traceBlockInPipe_ilastsize;
    lsq_nc_ldin.uop.eliminatedMove = io_lsq_nc_ldin_bits_uop_eliminatedMove;
    lsq_nc_ldin.uop.snapshot = io_lsq_nc_ldin_bits_uop_snapshot;
    lsq_nc_ldin.uop.debugInfo_eliminatedMove = io_lsq_nc_ldin_bits_uop_debugInfo_eliminatedMove;
    lsq_nc_ldin.uop.debugInfo_renameTime = io_lsq_nc_ldin_bits_uop_debugInfo_renameTime;
    lsq_nc_ldin.uop.debugInfo_dispatchTime = io_lsq_nc_ldin_bits_uop_debugInfo_dispatchTime;
    lsq_nc_ldin.uop.debugInfo_enqRsTime = io_lsq_nc_ldin_bits_uop_debugInfo_enqRsTime;
    lsq_nc_ldin.uop.debugInfo_selectTime = io_lsq_nc_ldin_bits_uop_debugInfo_selectTime;
    lsq_nc_ldin.uop.debugInfo_issueTime = io_lsq_nc_ldin_bits_uop_debugInfo_issueTime;
    lsq_nc_ldin.uop.debugInfo_writebackTime = io_lsq_nc_ldin_bits_uop_debugInfo_writebackTime;
    lsq_nc_ldin.uop.debugInfo_runahead_checkpoint_id = io_lsq_nc_ldin_bits_uop_debugInfo_runahead_checkpoint_id;
    lsq_nc_ldin.uop.debugInfo_tlbFirstReqTime = io_lsq_nc_ldin_bits_uop_debugInfo_tlbFirstReqTime;
    lsq_nc_ldin.uop.debugInfo_tlbRespTime = io_lsq_nc_ldin_bits_uop_debugInfo_tlbRespTime;
    lsq_nc_ldin.uop.debug_seqNum_seqNum = io_lsq_nc_ldin_bits_uop_debug_seqNum_seqNum;
    lsq_nc_ldin.uop.debug_seqNum_uopIdx = io_lsq_nc_ldin_bits_uop_debug_seqNum_uopIdx;
    lsq_nc_ldin.uop.storeSetHit = io_lsq_nc_ldin_bits_uop_storeSetHit;
    lsq_nc_ldin.uop.waitForRobIdx_flag = io_lsq_nc_ldin_bits_uop_waitForRobIdx_flag;
    lsq_nc_ldin.uop.waitForRobIdx_value = io_lsq_nc_ldin_bits_uop_waitForRobIdx_value;
    lsq_nc_ldin.uop.loadWaitBit = io_lsq_nc_ldin_bits_uop_loadWaitBit;
    lsq_nc_ldin.uop.loadWaitStrict = io_lsq_nc_ldin_bits_uop_loadWaitStrict;
    lsq_nc_ldin.uop.ssid = io_lsq_nc_ldin_bits_uop_ssid;
    lsq_nc_ldin.uop.lqIdx_flag = io_lsq_nc_ldin_bits_uop_lqIdx_flag;
    lsq_nc_ldin.uop.lqIdx_value = io_lsq_nc_ldin_bits_uop_lqIdx_value;
    lsq_nc_ldin.uop.sqIdx_flag = io_lsq_nc_ldin_bits_uop_sqIdx_flag;
    lsq_nc_ldin.uop.sqIdx_value = io_lsq_nc_ldin_bits_uop_sqIdx_value;
    lsq_nc_ldin.uop.singleStep = io_lsq_nc_ldin_bits_uop_singleStep;
    lsq_nc_ldin.uop.replayInst = io_lsq_nc_ldin_bits_uop_replayInst;
    lsq_nc_ldin.uop.debug_fuType = io_lsq_nc_ldin_bits_uop_debug_fuType;
    lsq_nc_ldin.uop.debug_sim_trig = io_lsq_nc_ldin_bits_uop_debug_sim_trig;
    lsq_nc_ldin.uop.numLsElem = io_lsq_nc_ldin_bits_uop_numLsElem;
    lsq_nc_ldin.vaddr = io_lsq_nc_ldin_bits_vaddr;
    lsq_nc_ldin.paddr = io_lsq_nc_ldin_bits_paddr;
    lsq_nc_ldin.data = io_lsq_nc_ldin_bits_data;
    lsq_nc_ldin.isvec = io_lsq_nc_ldin_bits_isvec;
    lsq_nc_ldin.is128bit = io_lsq_nc_ldin_bits_is128bit;
    lsq_nc_ldin.vecActive = io_lsq_nc_ldin_bits_vecActive;
    lsq_nc_ldin.schedIndex = io_lsq_nc_ldin_bits_schedIndex;
  end
  always_comb begin
    lsq_uncache = '0;
    lsq_uncache.uop.instr = io_lsq_uncache_bits_uop_instr;
    lsq_uncache.uop.pc = io_lsq_uncache_bits_uop_pc;
    lsq_uncache.uop.foldpc = io_lsq_uncache_bits_uop_foldpc;
    lsq_uncache.uop.exceptionVec[0] = io_lsq_uncache_bits_uop_exceptionVec_0;
    lsq_uncache.uop.exceptionVec[1] = io_lsq_uncache_bits_uop_exceptionVec_1;
    lsq_uncache.uop.exceptionVec[2] = io_lsq_uncache_bits_uop_exceptionVec_2;
    lsq_uncache.uop.exceptionVec[3] = io_lsq_uncache_bits_uop_exceptionVec_3;
    lsq_uncache.uop.exceptionVec[4] = io_lsq_uncache_bits_uop_exceptionVec_4;
    lsq_uncache.uop.exceptionVec[5] = io_lsq_uncache_bits_uop_exceptionVec_5;
    lsq_uncache.uop.exceptionVec[6] = io_lsq_uncache_bits_uop_exceptionVec_6;
    lsq_uncache.uop.exceptionVec[7] = io_lsq_uncache_bits_uop_exceptionVec_7;
    lsq_uncache.uop.exceptionVec[8] = io_lsq_uncache_bits_uop_exceptionVec_8;
    lsq_uncache.uop.exceptionVec[9] = io_lsq_uncache_bits_uop_exceptionVec_9;
    lsq_uncache.uop.exceptionVec[10] = io_lsq_uncache_bits_uop_exceptionVec_10;
    lsq_uncache.uop.exceptionVec[11] = io_lsq_uncache_bits_uop_exceptionVec_11;
    lsq_uncache.uop.exceptionVec[12] = io_lsq_uncache_bits_uop_exceptionVec_12;
    lsq_uncache.uop.exceptionVec[13] = io_lsq_uncache_bits_uop_exceptionVec_13;
    lsq_uncache.uop.exceptionVec[14] = io_lsq_uncache_bits_uop_exceptionVec_14;
    lsq_uncache.uop.exceptionVec[15] = io_lsq_uncache_bits_uop_exceptionVec_15;
    lsq_uncache.uop.exceptionVec[16] = io_lsq_uncache_bits_uop_exceptionVec_16;
    lsq_uncache.uop.exceptionVec[17] = io_lsq_uncache_bits_uop_exceptionVec_17;
    lsq_uncache.uop.exceptionVec[18] = io_lsq_uncache_bits_uop_exceptionVec_18;
    lsq_uncache.uop.exceptionVec[19] = io_lsq_uncache_bits_uop_exceptionVec_19;
    lsq_uncache.uop.exceptionVec[20] = io_lsq_uncache_bits_uop_exceptionVec_20;
    lsq_uncache.uop.exceptionVec[21] = io_lsq_uncache_bits_uop_exceptionVec_21;
    lsq_uncache.uop.exceptionVec[22] = io_lsq_uncache_bits_uop_exceptionVec_22;
    lsq_uncache.uop.exceptionVec[23] = io_lsq_uncache_bits_uop_exceptionVec_23;
    lsq_uncache.uop.isFetchMalAddr = io_lsq_uncache_bits_uop_isFetchMalAddr;
    lsq_uncache.uop.hasException = io_lsq_uncache_bits_uop_hasException;
    lsq_uncache.uop.trigger = io_lsq_uncache_bits_uop_trigger;
    lsq_uncache.uop.preDecodeInfo_valid = io_lsq_uncache_bits_uop_preDecodeInfo_valid;
    lsq_uncache.uop.preDecodeInfo_isRVC = io_lsq_uncache_bits_uop_preDecodeInfo_isRVC;
    lsq_uncache.uop.preDecodeInfo_brType = io_lsq_uncache_bits_uop_preDecodeInfo_brType;
    lsq_uncache.uop.preDecodeInfo_isCall = io_lsq_uncache_bits_uop_preDecodeInfo_isCall;
    lsq_uncache.uop.preDecodeInfo_isRet = io_lsq_uncache_bits_uop_preDecodeInfo_isRet;
    lsq_uncache.uop.pred_taken = io_lsq_uncache_bits_uop_pred_taken;
    lsq_uncache.uop.crossPageIPFFix = io_lsq_uncache_bits_uop_crossPageIPFFix;
    lsq_uncache.uop.ftqPtr_flag = io_lsq_uncache_bits_uop_ftqPtr_flag;
    lsq_uncache.uop.ftqPtr_value = io_lsq_uncache_bits_uop_ftqPtr_value;
    lsq_uncache.uop.ftqOffset = io_lsq_uncache_bits_uop_ftqOffset;
    lsq_uncache.uop.satpFlushFirstFetchFault = io_lsq_uncache_bits_uop_satpFlushFirstFetchFault;
    lsq_uncache.uop.srcType_0 = io_lsq_uncache_bits_uop_srcType_0;
    lsq_uncache.uop.srcType_1 = io_lsq_uncache_bits_uop_srcType_1;
    lsq_uncache.uop.srcType_2 = io_lsq_uncache_bits_uop_srcType_2;
    lsq_uncache.uop.srcType_3 = io_lsq_uncache_bits_uop_srcType_3;
    lsq_uncache.uop.srcType_4 = io_lsq_uncache_bits_uop_srcType_4;
    lsq_uncache.uop.ldest = io_lsq_uncache_bits_uop_ldest;
    lsq_uncache.uop.fuType = io_lsq_uncache_bits_uop_fuType;
    lsq_uncache.uop.fuOpType = io_lsq_uncache_bits_uop_fuOpType;
    lsq_uncache.uop.rfWen = io_lsq_uncache_bits_uop_rfWen;
    lsq_uncache.uop.fpWen = io_lsq_uncache_bits_uop_fpWen;
    lsq_uncache.uop.vecWen = io_lsq_uncache_bits_uop_vecWen;
    lsq_uncache.uop.v0Wen = io_lsq_uncache_bits_uop_v0Wen;
    lsq_uncache.uop.vlWen = io_lsq_uncache_bits_uop_vlWen;
    lsq_uncache.uop.isXSTrap = io_lsq_uncache_bits_uop_isXSTrap;
    lsq_uncache.uop.waitForward = io_lsq_uncache_bits_uop_waitForward;
    lsq_uncache.uop.blockBackward = io_lsq_uncache_bits_uop_blockBackward;
    lsq_uncache.uop.flushPipe = io_lsq_uncache_bits_uop_flushPipe;
    lsq_uncache.uop.canRobCompress = io_lsq_uncache_bits_uop_canRobCompress;
    lsq_uncache.uop.selImm = io_lsq_uncache_bits_uop_selImm;
    lsq_uncache.uop.imm = io_lsq_uncache_bits_uop_imm;
    lsq_uncache.uop.fpu_typeTagOut = io_lsq_uncache_bits_uop_fpu_typeTagOut;
    lsq_uncache.uop.fpu_wflags = io_lsq_uncache_bits_uop_fpu_wflags;
    lsq_uncache.uop.fpu_typ = io_lsq_uncache_bits_uop_fpu_typ;
    lsq_uncache.uop.fpu_fmt = io_lsq_uncache_bits_uop_fpu_fmt;
    lsq_uncache.uop.fpu_rm = io_lsq_uncache_bits_uop_fpu_rm;
    lsq_uncache.uop.vpu_vill = io_lsq_uncache_bits_uop_vpu_vill;
    lsq_uncache.uop.vpu_vma = io_lsq_uncache_bits_uop_vpu_vma;
    lsq_uncache.uop.vpu_vta = io_lsq_uncache_bits_uop_vpu_vta;
    lsq_uncache.uop.vpu_vsew = io_lsq_uncache_bits_uop_vpu_vsew;
    lsq_uncache.uop.vpu_vlmul = io_lsq_uncache_bits_uop_vpu_vlmul;
    lsq_uncache.uop.vpu_specVill = io_lsq_uncache_bits_uop_vpu_specVill;
    lsq_uncache.uop.vpu_specVma = io_lsq_uncache_bits_uop_vpu_specVma;
    lsq_uncache.uop.vpu_specVta = io_lsq_uncache_bits_uop_vpu_specVta;
    lsq_uncache.uop.vpu_specVsew = io_lsq_uncache_bits_uop_vpu_specVsew;
    lsq_uncache.uop.vpu_specVlmul = io_lsq_uncache_bits_uop_vpu_specVlmul;
    lsq_uncache.uop.vpu_vm = io_lsq_uncache_bits_uop_vpu_vm;
    lsq_uncache.uop.vpu_vstart = io_lsq_uncache_bits_uop_vpu_vstart;
    lsq_uncache.uop.vpu_frm = io_lsq_uncache_bits_uop_vpu_frm;
    lsq_uncache.uop.vpu_fpu_isFpToVecInst = io_lsq_uncache_bits_uop_vpu_fpu_isFpToVecInst;
    lsq_uncache.uop.vpu_fpu_isFP32Instr = io_lsq_uncache_bits_uop_vpu_fpu_isFP32Instr;
    lsq_uncache.uop.vpu_fpu_isFP64Instr = io_lsq_uncache_bits_uop_vpu_fpu_isFP64Instr;
    lsq_uncache.uop.vpu_fpu_isReduction = io_lsq_uncache_bits_uop_vpu_fpu_isReduction;
    lsq_uncache.uop.vpu_fpu_isFoldTo1_2 = io_lsq_uncache_bits_uop_vpu_fpu_isFoldTo1_2;
    lsq_uncache.uop.vpu_fpu_isFoldTo1_4 = io_lsq_uncache_bits_uop_vpu_fpu_isFoldTo1_4;
    lsq_uncache.uop.vpu_fpu_isFoldTo1_8 = io_lsq_uncache_bits_uop_vpu_fpu_isFoldTo1_8;
    lsq_uncache.uop.vpu_vxrm = io_lsq_uncache_bits_uop_vpu_vxrm;
    lsq_uncache.uop.vpu_vuopIdx = io_lsq_uncache_bits_uop_vpu_vuopIdx;
    lsq_uncache.uop.vpu_lastUop = io_lsq_uncache_bits_uop_vpu_lastUop;
    lsq_uncache.uop.vpu_vmask = io_lsq_uncache_bits_uop_vpu_vmask;
    lsq_uncache.uop.vpu_vl = io_lsq_uncache_bits_uop_vpu_vl;
    lsq_uncache.uop.vpu_nf = io_lsq_uncache_bits_uop_vpu_nf;
    lsq_uncache.uop.vpu_veew = io_lsq_uncache_bits_uop_vpu_veew;
    lsq_uncache.uop.vpu_isReverse = io_lsq_uncache_bits_uop_vpu_isReverse;
    lsq_uncache.uop.vpu_isExt = io_lsq_uncache_bits_uop_vpu_isExt;
    lsq_uncache.uop.vpu_isNarrow = io_lsq_uncache_bits_uop_vpu_isNarrow;
    lsq_uncache.uop.vpu_isDstMask = io_lsq_uncache_bits_uop_vpu_isDstMask;
    lsq_uncache.uop.vpu_isOpMask = io_lsq_uncache_bits_uop_vpu_isOpMask;
    lsq_uncache.uop.vpu_isMove = io_lsq_uncache_bits_uop_vpu_isMove;
    lsq_uncache.uop.vpu_isDependOldVd = io_lsq_uncache_bits_uop_vpu_isDependOldVd;
    lsq_uncache.uop.vpu_isWritePartVd = io_lsq_uncache_bits_uop_vpu_isWritePartVd;
    lsq_uncache.uop.vpu_isVleff = io_lsq_uncache_bits_uop_vpu_isVleff;
    lsq_uncache.uop.vlsInstr = io_lsq_uncache_bits_uop_vlsInstr;
    lsq_uncache.uop.wfflags = io_lsq_uncache_bits_uop_wfflags;
    lsq_uncache.uop.isMove = io_lsq_uncache_bits_uop_isMove;
    lsq_uncache.uop.isDropAmocasSta = io_lsq_uncache_bits_uop_isDropAmocasSta;
    lsq_uncache.uop.uopIdx = io_lsq_uncache_bits_uop_uopIdx;
    lsq_uncache.uop.isVset = io_lsq_uncache_bits_uop_isVset;
    lsq_uncache.uop.firstUop = io_lsq_uncache_bits_uop_firstUop;
    lsq_uncache.uop.lastUop = io_lsq_uncache_bits_uop_lastUop;
    lsq_uncache.uop.numUops = io_lsq_uncache_bits_uop_numUops;
    lsq_uncache.uop.numWB = io_lsq_uncache_bits_uop_numWB;
    lsq_uncache.uop.commitType = io_lsq_uncache_bits_uop_commitType;
    lsq_uncache.uop.srcState_0 = io_lsq_uncache_bits_uop_srcState_0;
    lsq_uncache.uop.srcState_1 = io_lsq_uncache_bits_uop_srcState_1;
    lsq_uncache.uop.srcState_2 = io_lsq_uncache_bits_uop_srcState_2;
    lsq_uncache.uop.srcState_3 = io_lsq_uncache_bits_uop_srcState_3;
    lsq_uncache.uop.srcState_4 = io_lsq_uncache_bits_uop_srcState_4;
    lsq_uncache.uop.srcLoadDependency_0_0 = io_lsq_uncache_bits_uop_srcLoadDependency_0_0;
    lsq_uncache.uop.srcLoadDependency_0_1 = io_lsq_uncache_bits_uop_srcLoadDependency_0_1;
    lsq_uncache.uop.srcLoadDependency_0_2 = io_lsq_uncache_bits_uop_srcLoadDependency_0_2;
    lsq_uncache.uop.srcLoadDependency_1_0 = io_lsq_uncache_bits_uop_srcLoadDependency_1_0;
    lsq_uncache.uop.srcLoadDependency_1_1 = io_lsq_uncache_bits_uop_srcLoadDependency_1_1;
    lsq_uncache.uop.srcLoadDependency_1_2 = io_lsq_uncache_bits_uop_srcLoadDependency_1_2;
    lsq_uncache.uop.srcLoadDependency_2_0 = io_lsq_uncache_bits_uop_srcLoadDependency_2_0;
    lsq_uncache.uop.srcLoadDependency_2_1 = io_lsq_uncache_bits_uop_srcLoadDependency_2_1;
    lsq_uncache.uop.srcLoadDependency_2_2 = io_lsq_uncache_bits_uop_srcLoadDependency_2_2;
    lsq_uncache.uop.srcLoadDependency_3_0 = io_lsq_uncache_bits_uop_srcLoadDependency_3_0;
    lsq_uncache.uop.srcLoadDependency_3_1 = io_lsq_uncache_bits_uop_srcLoadDependency_3_1;
    lsq_uncache.uop.srcLoadDependency_3_2 = io_lsq_uncache_bits_uop_srcLoadDependency_3_2;
    lsq_uncache.uop.srcLoadDependency_4_0 = io_lsq_uncache_bits_uop_srcLoadDependency_4_0;
    lsq_uncache.uop.srcLoadDependency_4_1 = io_lsq_uncache_bits_uop_srcLoadDependency_4_1;
    lsq_uncache.uop.srcLoadDependency_4_2 = io_lsq_uncache_bits_uop_srcLoadDependency_4_2;
    lsq_uncache.uop.psrc_0 = io_lsq_uncache_bits_uop_psrc_0;
    lsq_uncache.uop.psrc_1 = io_lsq_uncache_bits_uop_psrc_1;
    lsq_uncache.uop.psrc_2 = io_lsq_uncache_bits_uop_psrc_2;
    lsq_uncache.uop.psrc_3 = io_lsq_uncache_bits_uop_psrc_3;
    lsq_uncache.uop.psrc_4 = io_lsq_uncache_bits_uop_psrc_4;
    lsq_uncache.uop.pdest = io_lsq_uncache_bits_uop_pdest;
    lsq_uncache.uop.useRegCache_0 = io_lsq_uncache_bits_uop_useRegCache_0;
    lsq_uncache.uop.useRegCache_1 = io_lsq_uncache_bits_uop_useRegCache_1;
    lsq_uncache.uop.regCacheIdx_0 = io_lsq_uncache_bits_uop_regCacheIdx_0;
    lsq_uncache.uop.regCacheIdx_1 = io_lsq_uncache_bits_uop_regCacheIdx_1;
    lsq_uncache.uop.robIdx_flag = io_lsq_uncache_bits_uop_robIdx_flag;
    lsq_uncache.uop.robIdx_value = io_lsq_uncache_bits_uop_robIdx_value;
    lsq_uncache.uop.instrSize = io_lsq_uncache_bits_uop_instrSize;
    lsq_uncache.uop.dirtyFs = io_lsq_uncache_bits_uop_dirtyFs;
    lsq_uncache.uop.dirtyVs = io_lsq_uncache_bits_uop_dirtyVs;
    lsq_uncache.uop.traceBlockInPipe_itype = io_lsq_uncache_bits_uop_traceBlockInPipe_itype;
    lsq_uncache.uop.traceBlockInPipe_iretire = io_lsq_uncache_bits_uop_traceBlockInPipe_iretire;
    lsq_uncache.uop.traceBlockInPipe_ilastsize = io_lsq_uncache_bits_uop_traceBlockInPipe_ilastsize;
    lsq_uncache.uop.eliminatedMove = io_lsq_uncache_bits_uop_eliminatedMove;
    lsq_uncache.uop.snapshot = io_lsq_uncache_bits_uop_snapshot;
    lsq_uncache.uop.debugInfo_eliminatedMove = io_lsq_uncache_bits_uop_debugInfo_eliminatedMove;
    lsq_uncache.uop.debugInfo_renameTime = io_lsq_uncache_bits_uop_debugInfo_renameTime;
    lsq_uncache.uop.debugInfo_dispatchTime = io_lsq_uncache_bits_uop_debugInfo_dispatchTime;
    lsq_uncache.uop.debugInfo_enqRsTime = io_lsq_uncache_bits_uop_debugInfo_enqRsTime;
    lsq_uncache.uop.debugInfo_selectTime = io_lsq_uncache_bits_uop_debugInfo_selectTime;
    lsq_uncache.uop.debugInfo_issueTime = io_lsq_uncache_bits_uop_debugInfo_issueTime;
    lsq_uncache.uop.debugInfo_writebackTime = io_lsq_uncache_bits_uop_debugInfo_writebackTime;
    lsq_uncache.uop.debugInfo_runahead_checkpoint_id = io_lsq_uncache_bits_uop_debugInfo_runahead_checkpoint_id;
    lsq_uncache.uop.debugInfo_tlbFirstReqTime = io_lsq_uncache_bits_uop_debugInfo_tlbFirstReqTime;
    lsq_uncache.uop.debugInfo_tlbRespTime = io_lsq_uncache_bits_uop_debugInfo_tlbRespTime;
    lsq_uncache.uop.debug_seqNum_seqNum = io_lsq_uncache_bits_uop_debug_seqNum_seqNum;
    lsq_uncache.uop.debug_seqNum_uopIdx = io_lsq_uncache_bits_uop_debug_seqNum_uopIdx;
    lsq_uncache.uop.storeSetHit = io_lsq_uncache_bits_uop_storeSetHit;
    lsq_uncache.uop.waitForRobIdx_flag = io_lsq_uncache_bits_uop_waitForRobIdx_flag;
    lsq_uncache.uop.waitForRobIdx_value = io_lsq_uncache_bits_uop_waitForRobIdx_value;
    lsq_uncache.uop.loadWaitBit = io_lsq_uncache_bits_uop_loadWaitBit;
    lsq_uncache.uop.loadWaitStrict = io_lsq_uncache_bits_uop_loadWaitStrict;
    lsq_uncache.uop.ssid = io_lsq_uncache_bits_uop_ssid;
    lsq_uncache.uop.lqIdx_flag = io_lsq_uncache_bits_uop_lqIdx_flag;
    lsq_uncache.uop.lqIdx_value = io_lsq_uncache_bits_uop_lqIdx_value;
    lsq_uncache.uop.sqIdx_flag = io_lsq_uncache_bits_uop_sqIdx_flag;
    lsq_uncache.uop.sqIdx_value = io_lsq_uncache_bits_uop_sqIdx_value;
    lsq_uncache.uop.singleStep = io_lsq_uncache_bits_uop_singleStep;
    lsq_uncache.uop.replayInst = io_lsq_uncache_bits_uop_replayInst;
    lsq_uncache.uop.debug_fuType = io_lsq_uncache_bits_uop_debug_fuType;
    lsq_uncache.uop.debug_sim_trig = io_lsq_uncache_bits_uop_debug_sim_trig;
    lsq_uncache.uop.numLsElem = io_lsq_uncache_bits_uop_numLsElem;
    lsq_uncache.debug_isMMIO = io_lsq_uncache_bits_debug_isMMIO;
    lsq_uncache.debug_paddr = io_lsq_uncache_bits_debug_paddr;
    lsq_uncache.debug_vaddr = io_lsq_uncache_bits_debug_vaddr;
  end
  always_comb begin
    prefetch_req = '0;
    prefetch_req.paddr = io_prefetch_req_bits_paddr;
    prefetch_req.alias_ = io_prefetch_req_bits_alias;
    prefetch_req.confidence = io_prefetch_req_bits_confidence;
    prefetch_req.is_store = io_prefetch_req_bits_is_store;
    prefetch_req.pf_source_value = io_prefetch_req_bits_pf_source_value;
  end
  always_comb begin
    tlb_resp = '0;
    tlb_resp.paddr[0] = io_tlb_resp_bits_paddr_0;
    tlb_resp.paddr[1] = io_tlb_resp_bits_paddr_1;
    tlb_resp.gpaddr_0 = io_tlb_resp_bits_gpaddr_0;
    tlb_resp.fullva = io_tlb_resp_bits_fullva;
    tlb_resp.pbmt_0 = io_tlb_resp_bits_pbmt_0;
    tlb_resp.miss = io_tlb_resp_bits_miss;
    tlb_resp.isForVSnonLeafPTE = io_tlb_resp_bits_isForVSnonLeafPTE;
    tlb_resp.excp_0_vaNeedExt = io_tlb_resp_bits_excp_0_vaNeedExt;
    tlb_resp.excp_0_isHyper = io_tlb_resp_bits_excp_0_isHyper;
    tlb_resp.excp_0_gpf_ld = io_tlb_resp_bits_excp_0_gpf_ld;
    tlb_resp.excp_0_pf_ld = io_tlb_resp_bits_excp_0_pf_ld;
    tlb_resp.excp_0_af_ld = io_tlb_resp_bits_excp_0_af_ld;
    tlb_resp.ptwBack = io_tlb_resp_bits_ptwBack;
  end
  always_comb begin
    trigger_csr = '0;
    trigger_csr.tdataVec_0_matchType = io_fromCsrTrigger_tdataVec_0_matchType;
    trigger_csr.tdataVec_0_select = io_fromCsrTrigger_tdataVec_0_select;
    trigger_csr.tdataVec_0_timing = io_fromCsrTrigger_tdataVec_0_timing;
    trigger_csr.tdataVec_0_action = io_fromCsrTrigger_tdataVec_0_action;
    trigger_csr.tdataVec_0_chain = io_fromCsrTrigger_tdataVec_0_chain;
    trigger_csr.tdataVec_0_load = io_fromCsrTrigger_tdataVec_0_load;
    trigger_csr.tdataVec_0_tdata2 = io_fromCsrTrigger_tdataVec_0_tdata2;
    trigger_csr.tdataVec_1_matchType = io_fromCsrTrigger_tdataVec_1_matchType;
    trigger_csr.tdataVec_1_select = io_fromCsrTrigger_tdataVec_1_select;
    trigger_csr.tdataVec_1_timing = io_fromCsrTrigger_tdataVec_1_timing;
    trigger_csr.tdataVec_1_action = io_fromCsrTrigger_tdataVec_1_action;
    trigger_csr.tdataVec_1_chain = io_fromCsrTrigger_tdataVec_1_chain;
    trigger_csr.tdataVec_1_load = io_fromCsrTrigger_tdataVec_1_load;
    trigger_csr.tdataVec_1_tdata2 = io_fromCsrTrigger_tdataVec_1_tdata2;
    trigger_csr.tdataVec_2_matchType = io_fromCsrTrigger_tdataVec_2_matchType;
    trigger_csr.tdataVec_2_select = io_fromCsrTrigger_tdataVec_2_select;
    trigger_csr.tdataVec_2_timing = io_fromCsrTrigger_tdataVec_2_timing;
    trigger_csr.tdataVec_2_action = io_fromCsrTrigger_tdataVec_2_action;
    trigger_csr.tdataVec_2_chain = io_fromCsrTrigger_tdataVec_2_chain;
    trigger_csr.tdataVec_2_load = io_fromCsrTrigger_tdataVec_2_load;
    trigger_csr.tdataVec_2_tdata2 = io_fromCsrTrigger_tdataVec_2_tdata2;
    trigger_csr.tdataVec_3_matchType = io_fromCsrTrigger_tdataVec_3_matchType;
    trigger_csr.tdataVec_3_select = io_fromCsrTrigger_tdataVec_3_select;
    trigger_csr.tdataVec_3_timing = io_fromCsrTrigger_tdataVec_3_timing;
    trigger_csr.tdataVec_3_action = io_fromCsrTrigger_tdataVec_3_action;
    trigger_csr.tdataVec_3_chain = io_fromCsrTrigger_tdataVec_3_chain;
    trigger_csr.tdataVec_3_load = io_fromCsrTrigger_tdataVec_3_load;
    trigger_csr.tdataVec_3_tdata2 = io_fromCsrTrigger_tdataVec_3_tdata2;
    trigger_csr.tEnableVec_0 = io_fromCsrTrigger_tEnableVec_0;
    trigger_csr.tEnableVec_1 = io_fromCsrTrigger_tEnableVec_1;
    trigger_csr.tEnableVec_2 = io_fromCsrTrigger_tEnableVec_2;
    trigger_csr.tEnableVec_3 = io_fromCsrTrigger_tEnableVec_3;
    trigger_csr.debugMode = io_fromCsrTrigger_debugMode;
    trigger_csr.triggerCanRaiseBpExp = io_fromCsrTrigger_triggerCanRaiseBpExp;
  end
  always_comb begin
    stld_nuke_query_0 = '0;
    stld_nuke_query_0.valid = io_stld_nuke_query_0_valid;
    stld_nuke_query_0.bits_robIdx_flag = io_stld_nuke_query_0_bits_robIdx_flag;
    stld_nuke_query_0.bits_robIdx_value = io_stld_nuke_query_0_bits_robIdx_value;
    stld_nuke_query_0.bits_paddr = io_stld_nuke_query_0_bits_paddr;
    stld_nuke_query_0.bits_mask = io_stld_nuke_query_0_bits_mask;
    stld_nuke_query_0.bits_matchType = io_stld_nuke_query_0_bits_matchType;
  end
  always_comb begin
    stld_nuke_query_1 = '0;
    stld_nuke_query_1.valid = io_stld_nuke_query_1_valid;
    stld_nuke_query_1.bits_robIdx_flag = io_stld_nuke_query_1_bits_robIdx_flag;
    stld_nuke_query_1.bits_robIdx_value = io_stld_nuke_query_1_bits_robIdx_value;
    stld_nuke_query_1.bits_paddr = io_stld_nuke_query_1_bits_paddr;
    stld_nuke_query_1.bits_mask = io_stld_nuke_query_1_bits_mask;
    stld_nuke_query_1.bits_matchType = io_stld_nuke_query_1_bits_matchType;
  end
  always_comb begin
    pmp = '0;
    pmp.ld = io_pmp_ld;
    pmp.st = io_pmp_st;
    pmp.instr = io_pmp_instr;
    pmp.mmio = io_pmp_mmio;
  end
  always_comb begin
    dcache_resp = '0;
    dcache_resp.data = io_dcache_resp_bits_data;
    dcache_resp.miss = io_dcache_resp_bits_miss;
    dcache_resp.mshr_id = io_dcache_resp_bits_mshr_id;
    dcache_resp.meta_prefetch = io_dcache_resp_bits_meta_prefetch;
    dcache_resp.handled = io_dcache_resp_bits_handled;
    dcache_resp.tl_error_delayed_tl_denied = io_dcache_resp_bits_tl_error_delayed_tl_denied;
    dcache_resp.tl_error_delayed_tl_corrupt = io_dcache_resp_bits_tl_error_delayed_tl_corrupt;
  end
  always_comb begin
    sbuffer_resp = '0;
    sbuffer_resp.forwardMask[0] = io_sbuffer_forwardMask_0;
    sbuffer_resp.forwardMask[1] = io_sbuffer_forwardMask_1;
    sbuffer_resp.forwardMask[2] = io_sbuffer_forwardMask_2;
    sbuffer_resp.forwardMask[3] = io_sbuffer_forwardMask_3;
    sbuffer_resp.forwardMask[4] = io_sbuffer_forwardMask_4;
    sbuffer_resp.forwardMask[5] = io_sbuffer_forwardMask_5;
    sbuffer_resp.forwardMask[6] = io_sbuffer_forwardMask_6;
    sbuffer_resp.forwardMask[7] = io_sbuffer_forwardMask_7;
    sbuffer_resp.forwardMask[8] = io_sbuffer_forwardMask_8;
    sbuffer_resp.forwardMask[9] = io_sbuffer_forwardMask_9;
    sbuffer_resp.forwardMask[10] = io_sbuffer_forwardMask_10;
    sbuffer_resp.forwardMask[11] = io_sbuffer_forwardMask_11;
    sbuffer_resp.forwardMask[12] = io_sbuffer_forwardMask_12;
    sbuffer_resp.forwardMask[13] = io_sbuffer_forwardMask_13;
    sbuffer_resp.forwardMask[14] = io_sbuffer_forwardMask_14;
    sbuffer_resp.forwardMask[15] = io_sbuffer_forwardMask_15;
    sbuffer_resp.forwardData[0] = io_sbuffer_forwardData_0;
    sbuffer_resp.forwardData[1] = io_sbuffer_forwardData_1;
    sbuffer_resp.forwardData[2] = io_sbuffer_forwardData_2;
    sbuffer_resp.forwardData[3] = io_sbuffer_forwardData_3;
    sbuffer_resp.forwardData[4] = io_sbuffer_forwardData_4;
    sbuffer_resp.forwardData[5] = io_sbuffer_forwardData_5;
    sbuffer_resp.forwardData[6] = io_sbuffer_forwardData_6;
    sbuffer_resp.forwardData[7] = io_sbuffer_forwardData_7;
    sbuffer_resp.forwardData[8] = io_sbuffer_forwardData_8;
    sbuffer_resp.forwardData[9] = io_sbuffer_forwardData_9;
    sbuffer_resp.forwardData[10] = io_sbuffer_forwardData_10;
    sbuffer_resp.forwardData[11] = io_sbuffer_forwardData_11;
    sbuffer_resp.forwardData[12] = io_sbuffer_forwardData_12;
    sbuffer_resp.forwardData[13] = io_sbuffer_forwardData_13;
    sbuffer_resp.forwardData[14] = io_sbuffer_forwardData_14;
    sbuffer_resp.forwardData[15] = io_sbuffer_forwardData_15;
    sbuffer_resp.matchInvalid = io_sbuffer_matchInvalid;
  end
  always_comb begin
    ubuffer_resp = '0;
    ubuffer_resp.forwardMask[0] = io_ubuffer_forwardMask_0;
    ubuffer_resp.forwardMask[1] = io_ubuffer_forwardMask_1;
    ubuffer_resp.forwardMask[2] = io_ubuffer_forwardMask_2;
    ubuffer_resp.forwardMask[3] = io_ubuffer_forwardMask_3;
    ubuffer_resp.forwardMask[4] = io_ubuffer_forwardMask_4;
    ubuffer_resp.forwardMask[5] = io_ubuffer_forwardMask_5;
    ubuffer_resp.forwardMask[6] = io_ubuffer_forwardMask_6;
    ubuffer_resp.forwardMask[7] = io_ubuffer_forwardMask_7;
    ubuffer_resp.forwardMask[8] = io_ubuffer_forwardMask_8;
    ubuffer_resp.forwardMask[9] = io_ubuffer_forwardMask_9;
    ubuffer_resp.forwardMask[10] = io_ubuffer_forwardMask_10;
    ubuffer_resp.forwardMask[11] = io_ubuffer_forwardMask_11;
    ubuffer_resp.forwardMask[12] = io_ubuffer_forwardMask_12;
    ubuffer_resp.forwardMask[13] = io_ubuffer_forwardMask_13;
    ubuffer_resp.forwardMask[14] = io_ubuffer_forwardMask_14;
    ubuffer_resp.forwardMask[15] = io_ubuffer_forwardMask_15;
    ubuffer_resp.forwardData[0] = io_ubuffer_forwardData_0;
    ubuffer_resp.forwardData[1] = io_ubuffer_forwardData_1;
    ubuffer_resp.forwardData[2] = io_ubuffer_forwardData_2;
    ubuffer_resp.forwardData[3] = io_ubuffer_forwardData_3;
    ubuffer_resp.forwardData[4] = io_ubuffer_forwardData_4;
    ubuffer_resp.forwardData[5] = io_ubuffer_forwardData_5;
    ubuffer_resp.forwardData[6] = io_ubuffer_forwardData_6;
    ubuffer_resp.forwardData[7] = io_ubuffer_forwardData_7;
    ubuffer_resp.forwardData[8] = io_ubuffer_forwardData_8;
    ubuffer_resp.forwardData[9] = io_ubuffer_forwardData_9;
    ubuffer_resp.forwardData[10] = io_ubuffer_forwardData_10;
    ubuffer_resp.forwardData[11] = io_ubuffer_forwardData_11;
    ubuffer_resp.forwardData[12] = io_ubuffer_forwardData_12;
    ubuffer_resp.forwardData[13] = io_ubuffer_forwardData_13;
    ubuffer_resp.forwardData[14] = io_ubuffer_forwardData_14;
    ubuffer_resp.forwardData[15] = io_ubuffer_forwardData_15;
    ubuffer_resp.matchInvalid = io_ubuffer_matchInvalid;
  end
  always_comb begin
    lsq_fwd_resp = '0;
    lsq_fwd_resp.forwardMask[0] = io_lsq_forward_forwardMask_0;
    lsq_fwd_resp.forwardMask[1] = io_lsq_forward_forwardMask_1;
    lsq_fwd_resp.forwardMask[2] = io_lsq_forward_forwardMask_2;
    lsq_fwd_resp.forwardMask[3] = io_lsq_forward_forwardMask_3;
    lsq_fwd_resp.forwardMask[4] = io_lsq_forward_forwardMask_4;
    lsq_fwd_resp.forwardMask[5] = io_lsq_forward_forwardMask_5;
    lsq_fwd_resp.forwardMask[6] = io_lsq_forward_forwardMask_6;
    lsq_fwd_resp.forwardMask[7] = io_lsq_forward_forwardMask_7;
    lsq_fwd_resp.forwardMask[8] = io_lsq_forward_forwardMask_8;
    lsq_fwd_resp.forwardMask[9] = io_lsq_forward_forwardMask_9;
    lsq_fwd_resp.forwardMask[10] = io_lsq_forward_forwardMask_10;
    lsq_fwd_resp.forwardMask[11] = io_lsq_forward_forwardMask_11;
    lsq_fwd_resp.forwardMask[12] = io_lsq_forward_forwardMask_12;
    lsq_fwd_resp.forwardMask[13] = io_lsq_forward_forwardMask_13;
    lsq_fwd_resp.forwardMask[14] = io_lsq_forward_forwardMask_14;
    lsq_fwd_resp.forwardMask[15] = io_lsq_forward_forwardMask_15;
    lsq_fwd_resp.forwardData[0] = io_lsq_forward_forwardData_0;
    lsq_fwd_resp.forwardData[1] = io_lsq_forward_forwardData_1;
    lsq_fwd_resp.forwardData[2] = io_lsq_forward_forwardData_2;
    lsq_fwd_resp.forwardData[3] = io_lsq_forward_forwardData_3;
    lsq_fwd_resp.forwardData[4] = io_lsq_forward_forwardData_4;
    lsq_fwd_resp.forwardData[5] = io_lsq_forward_forwardData_5;
    lsq_fwd_resp.forwardData[6] = io_lsq_forward_forwardData_6;
    lsq_fwd_resp.forwardData[7] = io_lsq_forward_forwardData_7;
    lsq_fwd_resp.forwardData[8] = io_lsq_forward_forwardData_8;
    lsq_fwd_resp.forwardData[9] = io_lsq_forward_forwardData_9;
    lsq_fwd_resp.forwardData[10] = io_lsq_forward_forwardData_10;
    lsq_fwd_resp.forwardData[11] = io_lsq_forward_forwardData_11;
    lsq_fwd_resp.forwardData[12] = io_lsq_forward_forwardData_12;
    lsq_fwd_resp.forwardData[13] = io_lsq_forward_forwardData_13;
    lsq_fwd_resp.forwardData[14] = io_lsq_forward_forwardData_14;
    lsq_fwd_resp.forwardData[15] = io_lsq_forward_forwardData_15;
    lsq_fwd_resp.dataInvalid = io_lsq_forward_dataInvalid;
    lsq_fwd_resp.matchInvalid = io_lsq_forward_matchInvalid;
    lsq_fwd_resp.addrInvalid = io_lsq_forward_addrInvalid;
    lsq_fwd_resp.dataInvalidSqIdx_flag = io_lsq_forward_dataInvalidSqIdx_flag;
    lsq_fwd_resp.dataInvalidSqIdx_value = io_lsq_forward_dataInvalidSqIdx_value;
    lsq_fwd_resp.addrInvalidSqIdx_flag = io_lsq_forward_addrInvalidSqIdx_flag;
    lsq_fwd_resp.addrInvalidSqIdx_value = io_lsq_forward_addrInvalidSqIdx_value;
  end
  always_comb begin
    tl_d_channel = '0;
    tl_d_channel.valid = io_tl_d_channel_valid;
    tl_d_channel.data = io_tl_d_channel_data;
    tl_d_channel.mshrid = io_tl_d_channel_mshrid;
    tl_d_channel.last = io_tl_d_channel_last;
    tl_d_channel.denied = io_tl_d_channel_denied;
    tl_d_channel.corrupt = io_tl_d_channel_corrupt;
  end
  always_comb begin
    mshr_fwd_resp = '0;
    mshr_fwd_resp.forward_mshr = io_forward_mshr_forward_mshr;
    mshr_fwd_resp.forwardData[0] = io_forward_mshr_forwardData_0;
    mshr_fwd_resp.forwardData[1] = io_forward_mshr_forwardData_1;
    mshr_fwd_resp.forwardData[2] = io_forward_mshr_forwardData_2;
    mshr_fwd_resp.forwardData[3] = io_forward_mshr_forwardData_3;
    mshr_fwd_resp.forwardData[4] = io_forward_mshr_forwardData_4;
    mshr_fwd_resp.forwardData[5] = io_forward_mshr_forwardData_5;
    mshr_fwd_resp.forwardData[6] = io_forward_mshr_forwardData_6;
    mshr_fwd_resp.forwardData[7] = io_forward_mshr_forwardData_7;
    mshr_fwd_resp.forwardData[8] = io_forward_mshr_forwardData_8;
    mshr_fwd_resp.forwardData[9] = io_forward_mshr_forwardData_9;
    mshr_fwd_resp.forwardData[10] = io_forward_mshr_forwardData_10;
    mshr_fwd_resp.forwardData[11] = io_forward_mshr_forwardData_11;
    mshr_fwd_resp.forwardData[12] = io_forward_mshr_forwardData_12;
    mshr_fwd_resp.forwardData[13] = io_forward_mshr_forwardData_13;
    mshr_fwd_resp.forwardData[14] = io_forward_mshr_forwardData_14;
    mshr_fwd_resp.forwardData[15] = io_forward_mshr_forwardData_15;
    mshr_fwd_resp.forward_result_valid = io_forward_mshr_forward_result_valid;
    mshr_fwd_resp.denied = io_forward_mshr_denied;
    mshr_fwd_resp.corrupt = io_forward_mshr_corrupt;
  end
  always_comb begin
    tlb_hint = '0;
    tlb_hint.id = io_tlb_hint_id;
    tlb_hint.full = io_tlb_hint_full;
  end
  always_comb begin
    ld_raw_data = '0;
    ld_raw_data.lqData = io_lsq_ld_raw_data_lqData;
    ld_raw_data.uop.fuOpType = io_lsq_ld_raw_data_uop_fuOpType;
    ld_raw_data.uop.fpWen = io_lsq_ld_raw_data_uop_fpWen;
    ld_raw_data.addrOffset = io_lsq_ld_raw_data_addrOffset;
  end
  always_comb begin
    robDeqIdx = '0;
    robDeqIdx.flag = io_robDeqIdx_flag;
    robDeqIdx.value = io_robDeqIdx_value;
  end
  always_comb begin
    redirect = '0;
    redirect.robIdx_flag = io_redirect_bits_robIdx_flag;
    redirect.robIdx_value = io_redirect_bits_robIdx_value;
    redirect.level = io_redirect_bits_level;
  end
  always_comb begin
    csrCtrl = '0;
    csrCtrl.ldld_vio_check_enable = io_csrCtrl_ldld_vio_check_enable;
    csrCtrl.hd_misalign_ld_enable = io_csrCtrl_hd_misalign_ld_enable;
  end
  assign io_tlb_req_bits_vaddr = tlb_req.vaddr;
  assign io_tlb_req_bits_fullva = tlb_req.fullva;
  assign io_tlb_req_bits_checkfullva = tlb_req.checkfullva;
  assign io_tlb_req_bits_cmd = tlb_req.cmd;
  assign io_tlb_req_bits_hyperinst = tlb_req.hyperinst;
  assign io_tlb_req_bits_hlvx = tlb_req.hlvx;
  assign io_tlb_req_bits_kill = tlb_req.kill;
  assign io_tlb_req_bits_isPrefetch = tlb_req.isPrefetch;
  assign io_tlb_req_bits_no_translate = tlb_req.no_translate;
  assign io_tlb_req_bits_pmp_addr = tlb_req.pmp_addr;
  assign io_tlb_req_bits_frm_mabuf = tlb_req.frm_mabuf;
  assign io_tlb_req_bits_debug_robIdx_flag = tlb_req.debug_robIdx_flag;
  assign io_tlb_req_bits_debug_robIdx_value = tlb_req.debug_robIdx_value;
  assign io_tlb_req_bits_debug_isFirstIssue = tlb_req.debug_isFirstIssue;
  assign io_dcache_req_bits_cmd = dcache_req.cmd;
  assign io_dcache_req_bits_vaddr = dcache_req.vaddr;
  assign io_dcache_req_bits_vaddr_dup = dcache_req.vaddr_dup;
  assign io_dcache_req_bits_instrtype = dcache_req.instrtype;
  assign io_dcache_req_bits_isFirstIssue = dcache_req.isFirstIssue;
  assign io_dcache_req_bits_lqIdx_flag = dcache_req.lqIdx_flag;
  assign io_dcache_req_bits_lqIdx_value = dcache_req.lqIdx_value;
  assign io_sbuffer_vaddr = sbuffer_req.vaddr;
  assign io_sbuffer_paddr = sbuffer_req.paddr;
  assign io_sbuffer_valid = sbuffer_req.valid;
  assign io_ubuffer_vaddr = ubuffer_req.vaddr;
  assign io_ubuffer_paddr = ubuffer_req.paddr;
  assign io_ubuffer_valid = ubuffer_req.valid;
  assign io_lsq_forward_vaddr = lsq_fwd_req.vaddr;
  assign io_lsq_forward_paddr = lsq_fwd_req.paddr;
  assign io_lsq_forward_mask = lsq_fwd_req.mask;
  assign io_lsq_forward_uop_waitForRobIdx_flag = lsq_fwd_req.uop.waitForRobIdx_flag;
  assign io_lsq_forward_uop_waitForRobIdx_value = lsq_fwd_req.uop.waitForRobIdx_value;
  assign io_lsq_forward_uop_loadWaitBit = lsq_fwd_req.uop.loadWaitBit;
  assign io_lsq_forward_uop_loadWaitStrict = lsq_fwd_req.uop.loadWaitStrict;
  assign io_lsq_forward_uop_sqIdx_flag = lsq_fwd_req.uop.sqIdx_flag;
  assign io_lsq_forward_uop_sqIdx_value = lsq_fwd_req.uop.sqIdx_value;
  assign io_lsq_forward_valid = lsq_fwd_req.valid;
  assign io_lsq_forward_sqIdx_flag = lsq_fwd_req.sqIdx_flag;
  assign io_lsq_forward_sqIdxMask = lsq_fwd_req.sqIdxMask;
  assign io_forward_mshr_valid = mshr_fwd_req.valid;
  assign io_forward_mshr_mshrid = mshr_fwd_req.mshrid;
  assign io_forward_mshr_paddr = mshr_fwd_req.paddr;
  assign io_lsq_stld_nuke_query_req_bits_uop_preDecodeInfo_isRVC = stld_nuke_req.uop.preDecodeInfo_isRVC;
  assign io_lsq_stld_nuke_query_req_bits_uop_ftqPtr_flag = stld_nuke_req.uop.ftqPtr_flag;
  assign io_lsq_stld_nuke_query_req_bits_uop_ftqPtr_value = stld_nuke_req.uop.ftqPtr_value;
  assign io_lsq_stld_nuke_query_req_bits_uop_ftqOffset = stld_nuke_req.uop.ftqOffset;
  assign io_lsq_stld_nuke_query_req_bits_uop_robIdx_flag = stld_nuke_req.uop.robIdx_flag;
  assign io_lsq_stld_nuke_query_req_bits_uop_robIdx_value = stld_nuke_req.uop.robIdx_value;
  assign io_lsq_stld_nuke_query_req_bits_uop_debugInfo_runahead_checkpoint_id = stld_nuke_req.uop.debugInfo_runahead_checkpoint_id;
  assign io_lsq_stld_nuke_query_req_bits_uop_sqIdx_flag = stld_nuke_req.uop.sqIdx_flag;
  assign io_lsq_stld_nuke_query_req_bits_uop_sqIdx_value = stld_nuke_req.uop.sqIdx_value;
  assign io_lsq_stld_nuke_query_req_bits_mask = stld_nuke_req.mask;
  assign io_lsq_stld_nuke_query_req_bits_paddr = stld_nuke_req.paddr;
  assign io_lsq_stld_nuke_query_req_bits_data_valid = stld_nuke_req.data_valid;
  assign io_lsq_ldld_nuke_query_req_bits_uop_robIdx_flag = ldld_nuke_req.uop.robIdx_flag;
  assign io_lsq_ldld_nuke_query_req_bits_uop_robIdx_value = ldld_nuke_req.uop.robIdx_value;
  assign io_lsq_ldld_nuke_query_req_bits_uop_lqIdx_flag = ldld_nuke_req.uop.lqIdx_flag;
  assign io_lsq_ldld_nuke_query_req_bits_uop_lqIdx_value = ldld_nuke_req.uop.lqIdx_value;
  assign io_lsq_ldld_nuke_query_req_bits_paddr = ldld_nuke_req.paddr;
  assign io_lsq_ldld_nuke_query_req_bits_data_valid = ldld_nuke_req.data_valid;
  assign io_lsq_ldld_nuke_query_req_bits_is_nc = ldld_nuke_req.is_nc;
  assign io_prefetch_train_bits_uop_robIdx_flag = prefetch_train.uop.robIdx_flag;
  assign io_prefetch_train_bits_uop_robIdx_value = prefetch_train.uop.robIdx_value;
  assign io_prefetch_train_bits_vaddr = prefetch_train.vaddr;
  assign io_prefetch_train_bits_paddr = prefetch_train.paddr;
  assign io_prefetch_train_bits_miss = prefetch_train.miss;
  assign io_prefetch_train_bits_isFirstIssue = prefetch_train.isFirstIssue;
  assign io_prefetch_train_bits_meta_prefetch = prefetch_train.meta_prefetch;
  assign io_prefetch_train_l1_bits_uop_robIdx_flag = prefetch_train_l1.uop.robIdx_flag;
  assign io_prefetch_train_l1_bits_uop_robIdx_value = prefetch_train_l1.uop.robIdx_value;
  assign io_prefetch_train_l1_bits_vaddr = prefetch_train_l1.vaddr;
  assign io_prefetch_train_l1_bits_miss = prefetch_train_l1.miss;
  assign io_prefetch_train_l1_bits_isFirstIssue = prefetch_train_l1.isFirstIssue;
  assign io_prefetch_train_l1_bits_meta_prefetch = prefetch_train_l1.meta_prefetch;
  assign io_ifetchPrefetch_bits_vaddr = ifetchPrefetch.vaddr;
  assign io_wakeup_bits_instr = wakeup.instr;
  assign io_wakeup_bits_pc = wakeup.pc;
  assign io_wakeup_bits_foldpc = wakeup.foldpc;
  assign io_wakeup_bits_exceptionVec_0 = wakeup.exceptionVec[0];
  assign io_wakeup_bits_exceptionVec_1 = wakeup.exceptionVec[1];
  assign io_wakeup_bits_exceptionVec_2 = wakeup.exceptionVec[2];
  assign io_wakeup_bits_exceptionVec_3 = wakeup.exceptionVec[3];
  assign io_wakeup_bits_exceptionVec_4 = wakeup.exceptionVec[4];
  assign io_wakeup_bits_exceptionVec_5 = wakeup.exceptionVec[5];
  assign io_wakeup_bits_exceptionVec_6 = wakeup.exceptionVec[6];
  assign io_wakeup_bits_exceptionVec_7 = wakeup.exceptionVec[7];
  assign io_wakeup_bits_exceptionVec_8 = wakeup.exceptionVec[8];
  assign io_wakeup_bits_exceptionVec_9 = wakeup.exceptionVec[9];
  assign io_wakeup_bits_exceptionVec_10 = wakeup.exceptionVec[10];
  assign io_wakeup_bits_exceptionVec_11 = wakeup.exceptionVec[11];
  assign io_wakeup_bits_exceptionVec_12 = wakeup.exceptionVec[12];
  assign io_wakeup_bits_exceptionVec_13 = wakeup.exceptionVec[13];
  assign io_wakeup_bits_exceptionVec_14 = wakeup.exceptionVec[14];
  assign io_wakeup_bits_exceptionVec_15 = wakeup.exceptionVec[15];
  assign io_wakeup_bits_exceptionVec_16 = wakeup.exceptionVec[16];
  assign io_wakeup_bits_exceptionVec_17 = wakeup.exceptionVec[17];
  assign io_wakeup_bits_exceptionVec_18 = wakeup.exceptionVec[18];
  assign io_wakeup_bits_exceptionVec_19 = wakeup.exceptionVec[19];
  assign io_wakeup_bits_exceptionVec_20 = wakeup.exceptionVec[20];
  assign io_wakeup_bits_exceptionVec_21 = wakeup.exceptionVec[21];
  assign io_wakeup_bits_exceptionVec_22 = wakeup.exceptionVec[22];
  assign io_wakeup_bits_exceptionVec_23 = wakeup.exceptionVec[23];
  assign io_wakeup_bits_isFetchMalAddr = wakeup.isFetchMalAddr;
  assign io_wakeup_bits_hasException = wakeup.hasException;
  assign io_wakeup_bits_trigger = wakeup.trigger;
  assign io_wakeup_bits_preDecodeInfo_valid = wakeup.preDecodeInfo_valid;
  assign io_wakeup_bits_preDecodeInfo_isRVC = wakeup.preDecodeInfo_isRVC;
  assign io_wakeup_bits_preDecodeInfo_brType = wakeup.preDecodeInfo_brType;
  assign io_wakeup_bits_preDecodeInfo_isCall = wakeup.preDecodeInfo_isCall;
  assign io_wakeup_bits_preDecodeInfo_isRet = wakeup.preDecodeInfo_isRet;
  assign io_wakeup_bits_pred_taken = wakeup.pred_taken;
  assign io_wakeup_bits_crossPageIPFFix = wakeup.crossPageIPFFix;
  assign io_wakeup_bits_ftqPtr_flag = wakeup.ftqPtr_flag;
  assign io_wakeup_bits_ftqPtr_value = wakeup.ftqPtr_value;
  assign io_wakeup_bits_ftqOffset = wakeup.ftqOffset;
  assign io_wakeup_bits_satpFlushFirstFetchFault = wakeup.satpFlushFirstFetchFault;
  assign io_wakeup_bits_srcType_0 = wakeup.srcType_0;
  assign io_wakeup_bits_srcType_1 = wakeup.srcType_1;
  assign io_wakeup_bits_srcType_2 = wakeup.srcType_2;
  assign io_wakeup_bits_srcType_3 = wakeup.srcType_3;
  assign io_wakeup_bits_srcType_4 = wakeup.srcType_4;
  assign io_wakeup_bits_ldest = wakeup.ldest;
  assign io_wakeup_bits_fuType = wakeup.fuType;
  assign io_wakeup_bits_fuOpType = wakeup.fuOpType;
  assign io_wakeup_bits_rfWen = wakeup.rfWen;
  assign io_wakeup_bits_fpWen = wakeup.fpWen;
  assign io_wakeup_bits_vecWen = wakeup.vecWen;
  assign io_wakeup_bits_v0Wen = wakeup.v0Wen;
  assign io_wakeup_bits_vlWen = wakeup.vlWen;
  assign io_wakeup_bits_isXSTrap = wakeup.isXSTrap;
  assign io_wakeup_bits_waitForward = wakeup.waitForward;
  assign io_wakeup_bits_blockBackward = wakeup.blockBackward;
  assign io_wakeup_bits_flushPipe = wakeup.flushPipe;
  assign io_wakeup_bits_canRobCompress = wakeup.canRobCompress;
  assign io_wakeup_bits_selImm = wakeup.selImm;
  assign io_wakeup_bits_imm = wakeup.imm;
  assign io_wakeup_bits_fpu_typeTagOut = wakeup.fpu_typeTagOut;
  assign io_wakeup_bits_fpu_wflags = wakeup.fpu_wflags;
  assign io_wakeup_bits_fpu_typ = wakeup.fpu_typ;
  assign io_wakeup_bits_fpu_fmt = wakeup.fpu_fmt;
  assign io_wakeup_bits_fpu_rm = wakeup.fpu_rm;
  assign io_wakeup_bits_vpu_vill = wakeup.vpu_vill;
  assign io_wakeup_bits_vpu_vma = wakeup.vpu_vma;
  assign io_wakeup_bits_vpu_vta = wakeup.vpu_vta;
  assign io_wakeup_bits_vpu_vsew = wakeup.vpu_vsew;
  assign io_wakeup_bits_vpu_vlmul = wakeup.vpu_vlmul;
  assign io_wakeup_bits_vpu_specVill = wakeup.vpu_specVill;
  assign io_wakeup_bits_vpu_specVma = wakeup.vpu_specVma;
  assign io_wakeup_bits_vpu_specVta = wakeup.vpu_specVta;
  assign io_wakeup_bits_vpu_specVsew = wakeup.vpu_specVsew;
  assign io_wakeup_bits_vpu_specVlmul = wakeup.vpu_specVlmul;
  assign io_wakeup_bits_vpu_vm = wakeup.vpu_vm;
  assign io_wakeup_bits_vpu_vstart = wakeup.vpu_vstart;
  assign io_wakeup_bits_vpu_frm = wakeup.vpu_frm;
  assign io_wakeup_bits_vpu_fpu_isFpToVecInst = wakeup.vpu_fpu_isFpToVecInst;
  assign io_wakeup_bits_vpu_fpu_isFP32Instr = wakeup.vpu_fpu_isFP32Instr;
  assign io_wakeup_bits_vpu_fpu_isFP64Instr = wakeup.vpu_fpu_isFP64Instr;
  assign io_wakeup_bits_vpu_fpu_isReduction = wakeup.vpu_fpu_isReduction;
  assign io_wakeup_bits_vpu_fpu_isFoldTo1_2 = wakeup.vpu_fpu_isFoldTo1_2;
  assign io_wakeup_bits_vpu_fpu_isFoldTo1_4 = wakeup.vpu_fpu_isFoldTo1_4;
  assign io_wakeup_bits_vpu_fpu_isFoldTo1_8 = wakeup.vpu_fpu_isFoldTo1_8;
  assign io_wakeup_bits_vpu_vxrm = wakeup.vpu_vxrm;
  assign io_wakeup_bits_vpu_vuopIdx = wakeup.vpu_vuopIdx;
  assign io_wakeup_bits_vpu_lastUop = wakeup.vpu_lastUop;
  assign io_wakeup_bits_vpu_vmask = wakeup.vpu_vmask;
  assign io_wakeup_bits_vpu_vl = wakeup.vpu_vl;
  assign io_wakeup_bits_vpu_nf = wakeup.vpu_nf;
  assign io_wakeup_bits_vpu_veew = wakeup.vpu_veew;
  assign io_wakeup_bits_vpu_isReverse = wakeup.vpu_isReverse;
  assign io_wakeup_bits_vpu_isExt = wakeup.vpu_isExt;
  assign io_wakeup_bits_vpu_isNarrow = wakeup.vpu_isNarrow;
  assign io_wakeup_bits_vpu_isDstMask = wakeup.vpu_isDstMask;
  assign io_wakeup_bits_vpu_isOpMask = wakeup.vpu_isOpMask;
  assign io_wakeup_bits_vpu_isMove = wakeup.vpu_isMove;
  assign io_wakeup_bits_vpu_isDependOldVd = wakeup.vpu_isDependOldVd;
  assign io_wakeup_bits_vpu_isWritePartVd = wakeup.vpu_isWritePartVd;
  assign io_wakeup_bits_vpu_isVleff = wakeup.vpu_isVleff;
  assign io_wakeup_bits_vlsInstr = wakeup.vlsInstr;
  assign io_wakeup_bits_wfflags = wakeup.wfflags;
  assign io_wakeup_bits_isMove = wakeup.isMove;
  assign io_wakeup_bits_isDropAmocasSta = wakeup.isDropAmocasSta;
  assign io_wakeup_bits_uopIdx = wakeup.uopIdx;
  assign io_wakeup_bits_isVset = wakeup.isVset;
  assign io_wakeup_bits_firstUop = wakeup.firstUop;
  assign io_wakeup_bits_lastUop = wakeup.lastUop;
  assign io_wakeup_bits_numUops = wakeup.numUops;
  assign io_wakeup_bits_numWB = wakeup.numWB;
  assign io_wakeup_bits_commitType = wakeup.commitType;
  assign io_wakeup_bits_srcState_0 = wakeup.srcState_0;
  assign io_wakeup_bits_srcState_1 = wakeup.srcState_1;
  assign io_wakeup_bits_srcState_2 = wakeup.srcState_2;
  assign io_wakeup_bits_srcState_3 = wakeup.srcState_3;
  assign io_wakeup_bits_srcState_4 = wakeup.srcState_4;
  assign io_wakeup_bits_srcLoadDependency_0_0 = wakeup.srcLoadDependency_0_0;
  assign io_wakeup_bits_srcLoadDependency_0_1 = wakeup.srcLoadDependency_0_1;
  assign io_wakeup_bits_srcLoadDependency_0_2 = wakeup.srcLoadDependency_0_2;
  assign io_wakeup_bits_srcLoadDependency_1_0 = wakeup.srcLoadDependency_1_0;
  assign io_wakeup_bits_srcLoadDependency_1_1 = wakeup.srcLoadDependency_1_1;
  assign io_wakeup_bits_srcLoadDependency_1_2 = wakeup.srcLoadDependency_1_2;
  assign io_wakeup_bits_srcLoadDependency_2_0 = wakeup.srcLoadDependency_2_0;
  assign io_wakeup_bits_srcLoadDependency_2_1 = wakeup.srcLoadDependency_2_1;
  assign io_wakeup_bits_srcLoadDependency_2_2 = wakeup.srcLoadDependency_2_2;
  assign io_wakeup_bits_srcLoadDependency_3_0 = wakeup.srcLoadDependency_3_0;
  assign io_wakeup_bits_srcLoadDependency_3_1 = wakeup.srcLoadDependency_3_1;
  assign io_wakeup_bits_srcLoadDependency_3_2 = wakeup.srcLoadDependency_3_2;
  assign io_wakeup_bits_srcLoadDependency_4_0 = wakeup.srcLoadDependency_4_0;
  assign io_wakeup_bits_srcLoadDependency_4_1 = wakeup.srcLoadDependency_4_1;
  assign io_wakeup_bits_srcLoadDependency_4_2 = wakeup.srcLoadDependency_4_2;
  assign io_wakeup_bits_psrc_0 = wakeup.psrc_0;
  assign io_wakeup_bits_psrc_1 = wakeup.psrc_1;
  assign io_wakeup_bits_psrc_2 = wakeup.psrc_2;
  assign io_wakeup_bits_psrc_3 = wakeup.psrc_3;
  assign io_wakeup_bits_psrc_4 = wakeup.psrc_4;
  assign io_wakeup_bits_pdest = wakeup.pdest;
  assign io_wakeup_bits_useRegCache_0 = wakeup.useRegCache_0;
  assign io_wakeup_bits_useRegCache_1 = wakeup.useRegCache_1;
  assign io_wakeup_bits_regCacheIdx_0 = wakeup.regCacheIdx_0;
  assign io_wakeup_bits_regCacheIdx_1 = wakeup.regCacheIdx_1;
  assign io_wakeup_bits_robIdx_flag = wakeup.robIdx_flag;
  assign io_wakeup_bits_robIdx_value = wakeup.robIdx_value;
  assign io_wakeup_bits_instrSize = wakeup.instrSize;
  assign io_wakeup_bits_dirtyFs = wakeup.dirtyFs;
  assign io_wakeup_bits_dirtyVs = wakeup.dirtyVs;
  assign io_wakeup_bits_traceBlockInPipe_itype = wakeup.traceBlockInPipe_itype;
  assign io_wakeup_bits_traceBlockInPipe_iretire = wakeup.traceBlockInPipe_iretire;
  assign io_wakeup_bits_traceBlockInPipe_ilastsize = wakeup.traceBlockInPipe_ilastsize;
  assign io_wakeup_bits_eliminatedMove = wakeup.eliminatedMove;
  assign io_wakeup_bits_snapshot = wakeup.snapshot;
  assign io_wakeup_bits_debugInfo_eliminatedMove = wakeup.debugInfo_eliminatedMove;
  assign io_wakeup_bits_debugInfo_renameTime = wakeup.debugInfo_renameTime;
  assign io_wakeup_bits_debugInfo_dispatchTime = wakeup.debugInfo_dispatchTime;
  assign io_wakeup_bits_debugInfo_enqRsTime = wakeup.debugInfo_enqRsTime;
  assign io_wakeup_bits_debugInfo_selectTime = wakeup.debugInfo_selectTime;
  assign io_wakeup_bits_debugInfo_issueTime = wakeup.debugInfo_issueTime;
  assign io_wakeup_bits_debugInfo_writebackTime = wakeup.debugInfo_writebackTime;
  assign io_wakeup_bits_debugInfo_runahead_checkpoint_id = wakeup.debugInfo_runahead_checkpoint_id;
  assign io_wakeup_bits_debugInfo_tlbFirstReqTime = wakeup.debugInfo_tlbFirstReqTime;
  assign io_wakeup_bits_debugInfo_tlbRespTime = wakeup.debugInfo_tlbRespTime;
  assign io_wakeup_bits_debug_seqNum_seqNum = wakeup.debug_seqNum_seqNum;
  assign io_wakeup_bits_debug_seqNum_uopIdx = wakeup.debug_seqNum_uopIdx;
  assign io_wakeup_bits_storeSetHit = wakeup.storeSetHit;
  assign io_wakeup_bits_waitForRobIdx_flag = wakeup.waitForRobIdx_flag;
  assign io_wakeup_bits_waitForRobIdx_value = wakeup.waitForRobIdx_value;
  assign io_wakeup_bits_loadWaitBit = wakeup.loadWaitBit;
  assign io_wakeup_bits_loadWaitStrict = wakeup.loadWaitStrict;
  assign io_wakeup_bits_ssid = wakeup.ssid;
  assign io_wakeup_bits_lqIdx_flag = wakeup.lqIdx_flag;
  assign io_wakeup_bits_lqIdx_value = wakeup.lqIdx_value;
  assign io_wakeup_bits_sqIdx_flag = wakeup.sqIdx_flag;
  assign io_wakeup_bits_sqIdx_value = wakeup.sqIdx_value;
  assign io_wakeup_bits_singleStep = wakeup.singleStep;
  assign io_wakeup_bits_replayInst = wakeup.replayInst;
  assign io_wakeup_bits_debug_fuType = wakeup.debug_fuType;
  assign io_wakeup_bits_debug_sim_trig = wakeup.debug_sim_trig;
  assign io_wakeup_bits_numLsElem = wakeup.numLsElem;
  assign io_ldout_bits_uop_exceptionVec_3 = ldout.uop.exceptionVec[3];
  assign io_ldout_bits_uop_exceptionVec_4 = ldout.uop.exceptionVec[4];
  assign io_ldout_bits_uop_exceptionVec_5 = ldout.uop.exceptionVec[5];
  assign io_ldout_bits_uop_exceptionVec_13 = ldout.uop.exceptionVec[13];
  assign io_ldout_bits_uop_exceptionVec_19 = ldout.uop.exceptionVec[19];
  assign io_ldout_bits_uop_exceptionVec_21 = ldout.uop.exceptionVec[21];
  assign io_ldout_bits_uop_trigger = ldout.uop.trigger;
  assign io_ldout_bits_uop_preDecodeInfo_valid = ldout.uop.preDecodeInfo_valid;
  assign io_ldout_bits_uop_preDecodeInfo_isRVC = ldout.uop.preDecodeInfo_isRVC;
  assign io_ldout_bits_uop_preDecodeInfo_brType = ldout.uop.preDecodeInfo_brType;
  assign io_ldout_bits_uop_preDecodeInfo_isCall = ldout.uop.preDecodeInfo_isCall;
  assign io_ldout_bits_uop_preDecodeInfo_isRet = ldout.uop.preDecodeInfo_isRet;
  assign io_ldout_bits_uop_rfWen = ldout.uop.rfWen;
  assign io_ldout_bits_uop_fpWen = ldout.uop.fpWen;
  assign io_ldout_bits_uop_flushPipe = ldout.uop.flushPipe;
  assign io_ldout_bits_uop_pdest = ldout.uop.pdest;
  assign io_ldout_bits_uop_robIdx_flag = ldout.uop.robIdx_flag;
  assign io_ldout_bits_uop_robIdx_value = ldout.uop.robIdx_value;
  assign io_ldout_bits_uop_debugInfo_eliminatedMove = ldout.uop.debugInfo_eliminatedMove;
  assign io_ldout_bits_uop_debugInfo_renameTime = ldout.uop.debugInfo_renameTime;
  assign io_ldout_bits_uop_debugInfo_dispatchTime = ldout.uop.debugInfo_dispatchTime;
  assign io_ldout_bits_uop_debugInfo_enqRsTime = ldout.uop.debugInfo_enqRsTime;
  assign io_ldout_bits_uop_debugInfo_selectTime = ldout.uop.debugInfo_selectTime;
  assign io_ldout_bits_uop_debugInfo_issueTime = ldout.uop.debugInfo_issueTime;
  assign io_ldout_bits_uop_debugInfo_writebackTime = ldout.uop.debugInfo_writebackTime;
  assign io_ldout_bits_uop_debugInfo_runahead_checkpoint_id = ldout.uop.debugInfo_runahead_checkpoint_id;
  assign io_ldout_bits_uop_debugInfo_tlbFirstReqTime = ldout.uop.debugInfo_tlbFirstReqTime;
  assign io_ldout_bits_uop_debugInfo_tlbRespTime = ldout.uop.debugInfo_tlbRespTime;
  assign io_ldout_bits_uop_debug_seqNum_seqNum = ldout.uop.debug_seqNum_seqNum;
  assign io_ldout_bits_uop_debug_seqNum_uopIdx = ldout.uop.debug_seqNum_uopIdx;
  assign io_ldout_bits_uop_lqIdx_flag = ldout.uop.lqIdx_flag;
  assign io_ldout_bits_uop_lqIdx_value = ldout.uop.lqIdx_value;
  assign io_ldout_bits_uop_replayInst = ldout.uop.replayInst;
  assign io_ldout_bits_data = ldout.data;
  assign io_ldout_bits_debug_isMMIO = ldout.debug_isMMIO;
  assign io_ldout_bits_debug_isNCIO = ldout.debug_isNCIO;
  assign io_ldout_bits_debug_isPerfCnt = ldout.debug_isPerfCnt;
  assign io_ldout_bits_debug_paddr = ldout.debug_paddr;
  assign io_ldout_bits_debug_vaddr = ldout.debug_vaddr;
  assign io_vecldout_bits_mBIndex = vecldout.mBIndex;
  assign io_vecldout_bits_trigger = vecldout.trigger;
  assign io_vecldout_bits_exceptionVec_3 = vecldout.exceptionVec[3];
  assign io_vecldout_bits_exceptionVec_4 = vecldout.exceptionVec[4];
  assign io_vecldout_bits_exceptionVec_5 = vecldout.exceptionVec[5];
  assign io_vecldout_bits_exceptionVec_13 = vecldout.exceptionVec[13];
  assign io_vecldout_bits_exceptionVec_19 = vecldout.exceptionVec[19];
  assign io_vecldout_bits_exceptionVec_21 = vecldout.exceptionVec[21];
  assign io_vecldout_bits_hasException = vecldout.hasException;
  assign io_vecldout_bits_vaddr = vecldout.vaddr;
  assign io_vecldout_bits_vaNeedExt = vecldout.vaNeedExt;
  assign io_vecldout_bits_gpaddr = vecldout.gpaddr;
  assign io_vecldout_bits_isForVSnonLeafPTE = vecldout.isForVSnonLeafPTE;
  assign io_vecldout_bits_vstart = vecldout.vstart;
  assign io_vecldout_bits_vecTriggerMask = vecldout.vecTriggerMask;
  assign io_vecldout_bits_elemIdx = vecldout.elemIdx;
  assign io_vecldout_bits_mask = vecldout.mask;
  assign io_vecldout_bits_alignedType = vecldout.alignedType;
  assign io_vecldout_bits_reg_offset = vecldout.reg_offset;
  assign io_vecldout_bits_elemIdxInsideVd = vecldout.elemIdxInsideVd;
  assign io_vecldout_bits_vecdata = vecldout.vecdata;
  assign io_lsq_ldin_bits_uop_instr = lsq_ldin.uop.instr;
  assign io_lsq_ldin_bits_uop_pc = lsq_ldin.uop.pc;
  assign io_lsq_ldin_bits_uop_foldpc = lsq_ldin.uop.foldpc;
  assign io_lsq_ldin_bits_uop_exceptionVec_0 = lsq_ldin.uop.exceptionVec[0];
  assign io_lsq_ldin_bits_uop_exceptionVec_1 = lsq_ldin.uop.exceptionVec[1];
  assign io_lsq_ldin_bits_uop_exceptionVec_2 = lsq_ldin.uop.exceptionVec[2];
  assign io_lsq_ldin_bits_uop_exceptionVec_3 = lsq_ldin.uop.exceptionVec[3];
  assign io_lsq_ldin_bits_uop_exceptionVec_4 = lsq_ldin.uop.exceptionVec[4];
  assign io_lsq_ldin_bits_uop_exceptionVec_5 = lsq_ldin.uop.exceptionVec[5];
  assign io_lsq_ldin_bits_uop_exceptionVec_6 = lsq_ldin.uop.exceptionVec[6];
  assign io_lsq_ldin_bits_uop_exceptionVec_7 = lsq_ldin.uop.exceptionVec[7];
  assign io_lsq_ldin_bits_uop_exceptionVec_8 = lsq_ldin.uop.exceptionVec[8];
  assign io_lsq_ldin_bits_uop_exceptionVec_9 = lsq_ldin.uop.exceptionVec[9];
  assign io_lsq_ldin_bits_uop_exceptionVec_10 = lsq_ldin.uop.exceptionVec[10];
  assign io_lsq_ldin_bits_uop_exceptionVec_11 = lsq_ldin.uop.exceptionVec[11];
  assign io_lsq_ldin_bits_uop_exceptionVec_12 = lsq_ldin.uop.exceptionVec[12];
  assign io_lsq_ldin_bits_uop_exceptionVec_13 = lsq_ldin.uop.exceptionVec[13];
  assign io_lsq_ldin_bits_uop_exceptionVec_14 = lsq_ldin.uop.exceptionVec[14];
  assign io_lsq_ldin_bits_uop_exceptionVec_15 = lsq_ldin.uop.exceptionVec[15];
  assign io_lsq_ldin_bits_uop_exceptionVec_16 = lsq_ldin.uop.exceptionVec[16];
  assign io_lsq_ldin_bits_uop_exceptionVec_17 = lsq_ldin.uop.exceptionVec[17];
  assign io_lsq_ldin_bits_uop_exceptionVec_18 = lsq_ldin.uop.exceptionVec[18];
  assign io_lsq_ldin_bits_uop_exceptionVec_19 = lsq_ldin.uop.exceptionVec[19];
  assign io_lsq_ldin_bits_uop_exceptionVec_20 = lsq_ldin.uop.exceptionVec[20];
  assign io_lsq_ldin_bits_uop_exceptionVec_21 = lsq_ldin.uop.exceptionVec[21];
  assign io_lsq_ldin_bits_uop_exceptionVec_22 = lsq_ldin.uop.exceptionVec[22];
  assign io_lsq_ldin_bits_uop_exceptionVec_23 = lsq_ldin.uop.exceptionVec[23];
  assign io_lsq_ldin_bits_uop_isFetchMalAddr = lsq_ldin.uop.isFetchMalAddr;
  assign io_lsq_ldin_bits_uop_hasException = lsq_ldin.uop.hasException;
  assign io_lsq_ldin_bits_uop_trigger = lsq_ldin.uop.trigger;
  assign io_lsq_ldin_bits_uop_preDecodeInfo_valid = lsq_ldin.uop.preDecodeInfo_valid;
  assign io_lsq_ldin_bits_uop_preDecodeInfo_isRVC = lsq_ldin.uop.preDecodeInfo_isRVC;
  assign io_lsq_ldin_bits_uop_preDecodeInfo_brType = lsq_ldin.uop.preDecodeInfo_brType;
  assign io_lsq_ldin_bits_uop_preDecodeInfo_isCall = lsq_ldin.uop.preDecodeInfo_isCall;
  assign io_lsq_ldin_bits_uop_preDecodeInfo_isRet = lsq_ldin.uop.preDecodeInfo_isRet;
  assign io_lsq_ldin_bits_uop_pred_taken = lsq_ldin.uop.pred_taken;
  assign io_lsq_ldin_bits_uop_crossPageIPFFix = lsq_ldin.uop.crossPageIPFFix;
  assign io_lsq_ldin_bits_uop_ftqPtr_flag = lsq_ldin.uop.ftqPtr_flag;
  assign io_lsq_ldin_bits_uop_ftqPtr_value = lsq_ldin.uop.ftqPtr_value;
  assign io_lsq_ldin_bits_uop_ftqOffset = lsq_ldin.uop.ftqOffset;
  assign io_lsq_ldin_bits_uop_satpFlushFirstFetchFault = lsq_ldin.uop.satpFlushFirstFetchFault;
  assign io_lsq_ldin_bits_uop_srcType_0 = lsq_ldin.uop.srcType_0;
  assign io_lsq_ldin_bits_uop_srcType_1 = lsq_ldin.uop.srcType_1;
  assign io_lsq_ldin_bits_uop_srcType_2 = lsq_ldin.uop.srcType_2;
  assign io_lsq_ldin_bits_uop_srcType_3 = lsq_ldin.uop.srcType_3;
  assign io_lsq_ldin_bits_uop_srcType_4 = lsq_ldin.uop.srcType_4;
  assign io_lsq_ldin_bits_uop_ldest = lsq_ldin.uop.ldest;
  assign io_lsq_ldin_bits_uop_fuType = lsq_ldin.uop.fuType;
  assign io_lsq_ldin_bits_uop_fuOpType = lsq_ldin.uop.fuOpType;
  assign io_lsq_ldin_bits_uop_rfWen = lsq_ldin.uop.rfWen;
  assign io_lsq_ldin_bits_uop_fpWen = lsq_ldin.uop.fpWen;
  assign io_lsq_ldin_bits_uop_vecWen = lsq_ldin.uop.vecWen;
  assign io_lsq_ldin_bits_uop_v0Wen = lsq_ldin.uop.v0Wen;
  assign io_lsq_ldin_bits_uop_vlWen = lsq_ldin.uop.vlWen;
  assign io_lsq_ldin_bits_uop_isXSTrap = lsq_ldin.uop.isXSTrap;
  assign io_lsq_ldin_bits_uop_waitForward = lsq_ldin.uop.waitForward;
  assign io_lsq_ldin_bits_uop_blockBackward = lsq_ldin.uop.blockBackward;
  assign io_lsq_ldin_bits_uop_canRobCompress = lsq_ldin.uop.canRobCompress;
  assign io_lsq_ldin_bits_uop_selImm = lsq_ldin.uop.selImm;
  assign io_lsq_ldin_bits_uop_imm = lsq_ldin.uop.imm;
  assign io_lsq_ldin_bits_uop_fpu_typeTagOut = lsq_ldin.uop.fpu_typeTagOut;
  assign io_lsq_ldin_bits_uop_fpu_wflags = lsq_ldin.uop.fpu_wflags;
  assign io_lsq_ldin_bits_uop_fpu_typ = lsq_ldin.uop.fpu_typ;
  assign io_lsq_ldin_bits_uop_fpu_fmt = lsq_ldin.uop.fpu_fmt;
  assign io_lsq_ldin_bits_uop_fpu_rm = lsq_ldin.uop.fpu_rm;
  assign io_lsq_ldin_bits_uop_vpu_vill = lsq_ldin.uop.vpu_vill;
  assign io_lsq_ldin_bits_uop_vpu_vma = lsq_ldin.uop.vpu_vma;
  assign io_lsq_ldin_bits_uop_vpu_vta = lsq_ldin.uop.vpu_vta;
  assign io_lsq_ldin_bits_uop_vpu_vsew = lsq_ldin.uop.vpu_vsew;
  assign io_lsq_ldin_bits_uop_vpu_vlmul = lsq_ldin.uop.vpu_vlmul;
  assign io_lsq_ldin_bits_uop_vpu_specVill = lsq_ldin.uop.vpu_specVill;
  assign io_lsq_ldin_bits_uop_vpu_specVma = lsq_ldin.uop.vpu_specVma;
  assign io_lsq_ldin_bits_uop_vpu_specVta = lsq_ldin.uop.vpu_specVta;
  assign io_lsq_ldin_bits_uop_vpu_specVsew = lsq_ldin.uop.vpu_specVsew;
  assign io_lsq_ldin_bits_uop_vpu_specVlmul = lsq_ldin.uop.vpu_specVlmul;
  assign io_lsq_ldin_bits_uop_vpu_vm = lsq_ldin.uop.vpu_vm;
  assign io_lsq_ldin_bits_uop_vpu_vstart = lsq_ldin.uop.vpu_vstart;
  assign io_lsq_ldin_bits_uop_vpu_frm = lsq_ldin.uop.vpu_frm;
  assign io_lsq_ldin_bits_uop_vpu_fpu_isFpToVecInst = lsq_ldin.uop.vpu_fpu_isFpToVecInst;
  assign io_lsq_ldin_bits_uop_vpu_fpu_isFP32Instr = lsq_ldin.uop.vpu_fpu_isFP32Instr;
  assign io_lsq_ldin_bits_uop_vpu_fpu_isFP64Instr = lsq_ldin.uop.vpu_fpu_isFP64Instr;
  assign io_lsq_ldin_bits_uop_vpu_fpu_isReduction = lsq_ldin.uop.vpu_fpu_isReduction;
  assign io_lsq_ldin_bits_uop_vpu_fpu_isFoldTo1_2 = lsq_ldin.uop.vpu_fpu_isFoldTo1_2;
  assign io_lsq_ldin_bits_uop_vpu_fpu_isFoldTo1_4 = lsq_ldin.uop.vpu_fpu_isFoldTo1_4;
  assign io_lsq_ldin_bits_uop_vpu_fpu_isFoldTo1_8 = lsq_ldin.uop.vpu_fpu_isFoldTo1_8;
  assign io_lsq_ldin_bits_uop_vpu_vxrm = lsq_ldin.uop.vpu_vxrm;
  assign io_lsq_ldin_bits_uop_vpu_vuopIdx = lsq_ldin.uop.vpu_vuopIdx;
  assign io_lsq_ldin_bits_uop_vpu_lastUop = lsq_ldin.uop.vpu_lastUop;
  assign io_lsq_ldin_bits_uop_vpu_vmask = lsq_ldin.uop.vpu_vmask;
  assign io_lsq_ldin_bits_uop_vpu_vl = lsq_ldin.uop.vpu_vl;
  assign io_lsq_ldin_bits_uop_vpu_nf = lsq_ldin.uop.vpu_nf;
  assign io_lsq_ldin_bits_uop_vpu_veew = lsq_ldin.uop.vpu_veew;
  assign io_lsq_ldin_bits_uop_vpu_isReverse = lsq_ldin.uop.vpu_isReverse;
  assign io_lsq_ldin_bits_uop_vpu_isExt = lsq_ldin.uop.vpu_isExt;
  assign io_lsq_ldin_bits_uop_vpu_isNarrow = lsq_ldin.uop.vpu_isNarrow;
  assign io_lsq_ldin_bits_uop_vpu_isDstMask = lsq_ldin.uop.vpu_isDstMask;
  assign io_lsq_ldin_bits_uop_vpu_isOpMask = lsq_ldin.uop.vpu_isOpMask;
  assign io_lsq_ldin_bits_uop_vpu_isMove = lsq_ldin.uop.vpu_isMove;
  assign io_lsq_ldin_bits_uop_vpu_isDependOldVd = lsq_ldin.uop.vpu_isDependOldVd;
  assign io_lsq_ldin_bits_uop_vpu_isWritePartVd = lsq_ldin.uop.vpu_isWritePartVd;
  assign io_lsq_ldin_bits_uop_vpu_isVleff = lsq_ldin.uop.vpu_isVleff;
  assign io_lsq_ldin_bits_uop_vlsInstr = lsq_ldin.uop.vlsInstr;
  assign io_lsq_ldin_bits_uop_wfflags = lsq_ldin.uop.wfflags;
  assign io_lsq_ldin_bits_uop_isMove = lsq_ldin.uop.isMove;
  assign io_lsq_ldin_bits_uop_isDropAmocasSta = lsq_ldin.uop.isDropAmocasSta;
  assign io_lsq_ldin_bits_uop_uopIdx = lsq_ldin.uop.uopIdx;
  assign io_lsq_ldin_bits_uop_isVset = lsq_ldin.uop.isVset;
  assign io_lsq_ldin_bits_uop_firstUop = lsq_ldin.uop.firstUop;
  assign io_lsq_ldin_bits_uop_lastUop = lsq_ldin.uop.lastUop;
  assign io_lsq_ldin_bits_uop_numUops = lsq_ldin.uop.numUops;
  assign io_lsq_ldin_bits_uop_numWB = lsq_ldin.uop.numWB;
  assign io_lsq_ldin_bits_uop_commitType = lsq_ldin.uop.commitType;
  assign io_lsq_ldin_bits_uop_srcState_0 = lsq_ldin.uop.srcState_0;
  assign io_lsq_ldin_bits_uop_srcState_1 = lsq_ldin.uop.srcState_1;
  assign io_lsq_ldin_bits_uop_srcState_2 = lsq_ldin.uop.srcState_2;
  assign io_lsq_ldin_bits_uop_srcState_3 = lsq_ldin.uop.srcState_3;
  assign io_lsq_ldin_bits_uop_srcState_4 = lsq_ldin.uop.srcState_4;
  assign io_lsq_ldin_bits_uop_srcLoadDependency_0_0 = lsq_ldin.uop.srcLoadDependency_0_0;
  assign io_lsq_ldin_bits_uop_srcLoadDependency_0_1 = lsq_ldin.uop.srcLoadDependency_0_1;
  assign io_lsq_ldin_bits_uop_srcLoadDependency_0_2 = lsq_ldin.uop.srcLoadDependency_0_2;
  assign io_lsq_ldin_bits_uop_srcLoadDependency_1_0 = lsq_ldin.uop.srcLoadDependency_1_0;
  assign io_lsq_ldin_bits_uop_srcLoadDependency_1_1 = lsq_ldin.uop.srcLoadDependency_1_1;
  assign io_lsq_ldin_bits_uop_srcLoadDependency_1_2 = lsq_ldin.uop.srcLoadDependency_1_2;
  assign io_lsq_ldin_bits_uop_srcLoadDependency_2_0 = lsq_ldin.uop.srcLoadDependency_2_0;
  assign io_lsq_ldin_bits_uop_srcLoadDependency_2_1 = lsq_ldin.uop.srcLoadDependency_2_1;
  assign io_lsq_ldin_bits_uop_srcLoadDependency_2_2 = lsq_ldin.uop.srcLoadDependency_2_2;
  assign io_lsq_ldin_bits_uop_srcLoadDependency_3_0 = lsq_ldin.uop.srcLoadDependency_3_0;
  assign io_lsq_ldin_bits_uop_srcLoadDependency_3_1 = lsq_ldin.uop.srcLoadDependency_3_1;
  assign io_lsq_ldin_bits_uop_srcLoadDependency_3_2 = lsq_ldin.uop.srcLoadDependency_3_2;
  assign io_lsq_ldin_bits_uop_srcLoadDependency_4_0 = lsq_ldin.uop.srcLoadDependency_4_0;
  assign io_lsq_ldin_bits_uop_srcLoadDependency_4_1 = lsq_ldin.uop.srcLoadDependency_4_1;
  assign io_lsq_ldin_bits_uop_srcLoadDependency_4_2 = lsq_ldin.uop.srcLoadDependency_4_2;
  assign io_lsq_ldin_bits_uop_psrc_0 = lsq_ldin.uop.psrc_0;
  assign io_lsq_ldin_bits_uop_psrc_1 = lsq_ldin.uop.psrc_1;
  assign io_lsq_ldin_bits_uop_psrc_2 = lsq_ldin.uop.psrc_2;
  assign io_lsq_ldin_bits_uop_psrc_3 = lsq_ldin.uop.psrc_3;
  assign io_lsq_ldin_bits_uop_psrc_4 = lsq_ldin.uop.psrc_4;
  assign io_lsq_ldin_bits_uop_pdest = lsq_ldin.uop.pdest;
  assign io_lsq_ldin_bits_uop_useRegCache_0 = lsq_ldin.uop.useRegCache_0;
  assign io_lsq_ldin_bits_uop_useRegCache_1 = lsq_ldin.uop.useRegCache_1;
  assign io_lsq_ldin_bits_uop_regCacheIdx_0 = lsq_ldin.uop.regCacheIdx_0;
  assign io_lsq_ldin_bits_uop_regCacheIdx_1 = lsq_ldin.uop.regCacheIdx_1;
  assign io_lsq_ldin_bits_uop_robIdx_flag = lsq_ldin.uop.robIdx_flag;
  assign io_lsq_ldin_bits_uop_robIdx_value = lsq_ldin.uop.robIdx_value;
  assign io_lsq_ldin_bits_uop_instrSize = lsq_ldin.uop.instrSize;
  assign io_lsq_ldin_bits_uop_dirtyFs = lsq_ldin.uop.dirtyFs;
  assign io_lsq_ldin_bits_uop_dirtyVs = lsq_ldin.uop.dirtyVs;
  assign io_lsq_ldin_bits_uop_traceBlockInPipe_itype = lsq_ldin.uop.traceBlockInPipe_itype;
  assign io_lsq_ldin_bits_uop_traceBlockInPipe_iretire = lsq_ldin.uop.traceBlockInPipe_iretire;
  assign io_lsq_ldin_bits_uop_traceBlockInPipe_ilastsize = lsq_ldin.uop.traceBlockInPipe_ilastsize;
  assign io_lsq_ldin_bits_uop_eliminatedMove = lsq_ldin.uop.eliminatedMove;
  assign io_lsq_ldin_bits_uop_snapshot = lsq_ldin.uop.snapshot;
  assign io_lsq_ldin_bits_uop_debugInfo_eliminatedMove = lsq_ldin.uop.debugInfo_eliminatedMove;
  assign io_lsq_ldin_bits_uop_debugInfo_renameTime = lsq_ldin.uop.debugInfo_renameTime;
  assign io_lsq_ldin_bits_uop_debugInfo_dispatchTime = lsq_ldin.uop.debugInfo_dispatchTime;
  assign io_lsq_ldin_bits_uop_debugInfo_enqRsTime = lsq_ldin.uop.debugInfo_enqRsTime;
  assign io_lsq_ldin_bits_uop_debugInfo_selectTime = lsq_ldin.uop.debugInfo_selectTime;
  assign io_lsq_ldin_bits_uop_debugInfo_issueTime = lsq_ldin.uop.debugInfo_issueTime;
  assign io_lsq_ldin_bits_uop_debugInfo_writebackTime = lsq_ldin.uop.debugInfo_writebackTime;
  assign io_lsq_ldin_bits_uop_debugInfo_runahead_checkpoint_id = lsq_ldin.uop.debugInfo_runahead_checkpoint_id;
  assign io_lsq_ldin_bits_uop_debugInfo_tlbFirstReqTime = lsq_ldin.uop.debugInfo_tlbFirstReqTime;
  assign io_lsq_ldin_bits_uop_debugInfo_tlbRespTime = lsq_ldin.uop.debugInfo_tlbRespTime;
  assign io_lsq_ldin_bits_uop_debug_seqNum_seqNum = lsq_ldin.uop.debug_seqNum_seqNum;
  assign io_lsq_ldin_bits_uop_debug_seqNum_uopIdx = lsq_ldin.uop.debug_seqNum_uopIdx;
  assign io_lsq_ldin_bits_uop_storeSetHit = lsq_ldin.uop.storeSetHit;
  assign io_lsq_ldin_bits_uop_waitForRobIdx_flag = lsq_ldin.uop.waitForRobIdx_flag;
  assign io_lsq_ldin_bits_uop_waitForRobIdx_value = lsq_ldin.uop.waitForRobIdx_value;
  assign io_lsq_ldin_bits_uop_loadWaitBit = lsq_ldin.uop.loadWaitBit;
  assign io_lsq_ldin_bits_uop_loadWaitStrict = lsq_ldin.uop.loadWaitStrict;
  assign io_lsq_ldin_bits_uop_ssid = lsq_ldin.uop.ssid;
  assign io_lsq_ldin_bits_uop_lqIdx_flag = lsq_ldin.uop.lqIdx_flag;
  assign io_lsq_ldin_bits_uop_lqIdx_value = lsq_ldin.uop.lqIdx_value;
  assign io_lsq_ldin_bits_uop_sqIdx_flag = lsq_ldin.uop.sqIdx_flag;
  assign io_lsq_ldin_bits_uop_sqIdx_value = lsq_ldin.uop.sqIdx_value;
  assign io_lsq_ldin_bits_uop_singleStep = lsq_ldin.uop.singleStep;
  assign io_lsq_ldin_bits_uop_debug_fuType = lsq_ldin.uop.debug_fuType;
  assign io_lsq_ldin_bits_uop_debug_sim_trig = lsq_ldin.uop.debug_sim_trig;
  assign io_lsq_ldin_bits_uop_numLsElem = lsq_ldin.uop.numLsElem;
  assign io_lsq_ldin_bits_vaddr = lsq_ldin.vaddr;
  assign io_lsq_ldin_bits_fullva = lsq_ldin.fullva;
  assign io_lsq_ldin_bits_vaNeedExt = lsq_ldin.vaNeedExt;
  assign io_lsq_ldin_bits_paddr = lsq_ldin.paddr;
  assign io_lsq_ldin_bits_gpaddr = lsq_ldin.gpaddr;
  assign io_lsq_ldin_bits_mask = lsq_ldin.mask;
  assign io_lsq_ldin_bits_nc = lsq_ldin.nc;
  assign io_lsq_ldin_bits_mmio = lsq_ldin.mmio;
  assign io_lsq_ldin_bits_memBackTypeMM = lsq_ldin.memBackTypeMM;
  assign io_lsq_ldin_bits_isHyper = lsq_ldin.isHyper;
  assign io_lsq_ldin_bits_isForVSnonLeafPTE = lsq_ldin.isForVSnonLeafPTE;
  assign io_lsq_ldin_bits_isvec = lsq_ldin.isvec;
  assign io_lsq_ldin_bits_is128bit = lsq_ldin.is128bit;
  assign io_lsq_ldin_bits_elemIdx = lsq_ldin.elemIdx;
  assign io_lsq_ldin_bits_alignedType = lsq_ldin.alignedType;
  assign io_lsq_ldin_bits_mbIndex = lsq_ldin.mbIndex;
  assign io_lsq_ldin_bits_reg_offset = lsq_ldin.reg_offset;
  assign io_lsq_ldin_bits_elemIdxInsideVd = lsq_ldin.elemIdxInsideVd;
  assign io_lsq_ldin_bits_vecActive = lsq_ldin.vecActive;
  assign io_lsq_ldin_bits_isLoadReplay = lsq_ldin.isLoadReplay;
  assign io_lsq_ldin_bits_handledByMSHR = lsq_ldin.handledByMSHR;
  assign io_lsq_ldin_bits_schedIndex = lsq_ldin.schedIndex;
  assign io_lsq_ldin_bits_updateAddrValid = lsq_ldin.updateAddrValid;
  assign io_lsq_ldin_bits_rep_info_mshr_id = lsq_ldin.rep_info_mshr_id;
  assign io_lsq_ldin_bits_rep_info_full_fwd = lsq_ldin.rep_info_full_fwd;
  assign io_lsq_ldin_bits_rep_info_data_inv_sq_idx_flag = lsq_ldin.rep_info_data_inv_sq_idx_flag;
  assign io_lsq_ldin_bits_rep_info_data_inv_sq_idx_value = lsq_ldin.rep_info_data_inv_sq_idx_value;
  assign io_lsq_ldin_bits_rep_info_addr_inv_sq_idx_flag = lsq_ldin.rep_info_addr_inv_sq_idx_flag;
  assign io_lsq_ldin_bits_rep_info_addr_inv_sq_idx_value = lsq_ldin.rep_info_addr_inv_sq_idx_value;
  assign io_lsq_ldin_bits_rep_info_last_beat = lsq_ldin.rep_info_last_beat;
  assign io_lsq_ldin_bits_rep_info_cause_0 = lsq_ldin.rep_info_cause[0];
  assign io_lsq_ldin_bits_rep_info_cause_1 = lsq_ldin.rep_info_cause[1];
  assign io_lsq_ldin_bits_rep_info_cause_2 = lsq_ldin.rep_info_cause[2];
  assign io_lsq_ldin_bits_rep_info_cause_3 = lsq_ldin.rep_info_cause[3];
  assign io_lsq_ldin_bits_rep_info_cause_4 = lsq_ldin.rep_info_cause[4];
  assign io_lsq_ldin_bits_rep_info_cause_5 = lsq_ldin.rep_info_cause[5];
  assign io_lsq_ldin_bits_rep_info_cause_6 = lsq_ldin.rep_info_cause[6];
  assign io_lsq_ldin_bits_rep_info_cause_7 = lsq_ldin.rep_info_cause[7];
  assign io_lsq_ldin_bits_rep_info_cause_8 = lsq_ldin.rep_info_cause[8];
  assign io_lsq_ldin_bits_rep_info_cause_9 = lsq_ldin.rep_info_cause[9];
  assign io_lsq_ldin_bits_rep_info_cause_10 = lsq_ldin.rep_info_cause[10];
  assign io_lsq_ldin_bits_rep_info_tlb_id = lsq_ldin.rep_info_tlb_id;
  assign io_lsq_ldin_bits_rep_info_tlb_full = lsq_ldin.rep_info_tlb_full;
  assign io_lsq_ldin_bits_nc_with_data = lsq_ldin.nc_with_data;
  assign io_fast_rep_out_bits_uop_instr = fast_rep_out.uop.instr;
  assign io_fast_rep_out_bits_uop_pc = fast_rep_out.uop.pc;
  assign io_fast_rep_out_bits_uop_foldpc = fast_rep_out.uop.foldpc;
  assign io_fast_rep_out_bits_uop_exceptionVec_0 = fast_rep_out.uop.exceptionVec[0];
  assign io_fast_rep_out_bits_uop_exceptionVec_1 = fast_rep_out.uop.exceptionVec[1];
  assign io_fast_rep_out_bits_uop_exceptionVec_2 = fast_rep_out.uop.exceptionVec[2];
  assign io_fast_rep_out_bits_uop_exceptionVec_3 = fast_rep_out.uop.exceptionVec[3];
  assign io_fast_rep_out_bits_uop_exceptionVec_4 = fast_rep_out.uop.exceptionVec[4];
  assign io_fast_rep_out_bits_uop_exceptionVec_5 = fast_rep_out.uop.exceptionVec[5];
  assign io_fast_rep_out_bits_uop_exceptionVec_6 = fast_rep_out.uop.exceptionVec[6];
  assign io_fast_rep_out_bits_uop_exceptionVec_7 = fast_rep_out.uop.exceptionVec[7];
  assign io_fast_rep_out_bits_uop_exceptionVec_8 = fast_rep_out.uop.exceptionVec[8];
  assign io_fast_rep_out_bits_uop_exceptionVec_9 = fast_rep_out.uop.exceptionVec[9];
  assign io_fast_rep_out_bits_uop_exceptionVec_10 = fast_rep_out.uop.exceptionVec[10];
  assign io_fast_rep_out_bits_uop_exceptionVec_11 = fast_rep_out.uop.exceptionVec[11];
  assign io_fast_rep_out_bits_uop_exceptionVec_12 = fast_rep_out.uop.exceptionVec[12];
  assign io_fast_rep_out_bits_uop_exceptionVec_13 = fast_rep_out.uop.exceptionVec[13];
  assign io_fast_rep_out_bits_uop_exceptionVec_14 = fast_rep_out.uop.exceptionVec[14];
  assign io_fast_rep_out_bits_uop_exceptionVec_15 = fast_rep_out.uop.exceptionVec[15];
  assign io_fast_rep_out_bits_uop_exceptionVec_16 = fast_rep_out.uop.exceptionVec[16];
  assign io_fast_rep_out_bits_uop_exceptionVec_17 = fast_rep_out.uop.exceptionVec[17];
  assign io_fast_rep_out_bits_uop_exceptionVec_18 = fast_rep_out.uop.exceptionVec[18];
  assign io_fast_rep_out_bits_uop_exceptionVec_19 = fast_rep_out.uop.exceptionVec[19];
  assign io_fast_rep_out_bits_uop_exceptionVec_20 = fast_rep_out.uop.exceptionVec[20];
  assign io_fast_rep_out_bits_uop_exceptionVec_21 = fast_rep_out.uop.exceptionVec[21];
  assign io_fast_rep_out_bits_uop_exceptionVec_22 = fast_rep_out.uop.exceptionVec[22];
  assign io_fast_rep_out_bits_uop_exceptionVec_23 = fast_rep_out.uop.exceptionVec[23];
  assign io_fast_rep_out_bits_uop_isFetchMalAddr = fast_rep_out.uop.isFetchMalAddr;
  assign io_fast_rep_out_bits_uop_hasException = fast_rep_out.uop.hasException;
  assign io_fast_rep_out_bits_uop_trigger = fast_rep_out.uop.trigger;
  assign io_fast_rep_out_bits_uop_preDecodeInfo_valid = fast_rep_out.uop.preDecodeInfo_valid;
  assign io_fast_rep_out_bits_uop_preDecodeInfo_isRVC = fast_rep_out.uop.preDecodeInfo_isRVC;
  assign io_fast_rep_out_bits_uop_preDecodeInfo_brType = fast_rep_out.uop.preDecodeInfo_brType;
  assign io_fast_rep_out_bits_uop_preDecodeInfo_isCall = fast_rep_out.uop.preDecodeInfo_isCall;
  assign io_fast_rep_out_bits_uop_preDecodeInfo_isRet = fast_rep_out.uop.preDecodeInfo_isRet;
  assign io_fast_rep_out_bits_uop_pred_taken = fast_rep_out.uop.pred_taken;
  assign io_fast_rep_out_bits_uop_crossPageIPFFix = fast_rep_out.uop.crossPageIPFFix;
  assign io_fast_rep_out_bits_uop_ftqPtr_flag = fast_rep_out.uop.ftqPtr_flag;
  assign io_fast_rep_out_bits_uop_ftqPtr_value = fast_rep_out.uop.ftqPtr_value;
  assign io_fast_rep_out_bits_uop_ftqOffset = fast_rep_out.uop.ftqOffset;
  assign io_fast_rep_out_bits_uop_satpFlushFirstFetchFault = fast_rep_out.uop.satpFlushFirstFetchFault;
  assign io_fast_rep_out_bits_uop_srcType_0 = fast_rep_out.uop.srcType_0;
  assign io_fast_rep_out_bits_uop_srcType_1 = fast_rep_out.uop.srcType_1;
  assign io_fast_rep_out_bits_uop_srcType_2 = fast_rep_out.uop.srcType_2;
  assign io_fast_rep_out_bits_uop_srcType_3 = fast_rep_out.uop.srcType_3;
  assign io_fast_rep_out_bits_uop_srcType_4 = fast_rep_out.uop.srcType_4;
  assign io_fast_rep_out_bits_uop_ldest = fast_rep_out.uop.ldest;
  assign io_fast_rep_out_bits_uop_fuType = fast_rep_out.uop.fuType;
  assign io_fast_rep_out_bits_uop_fuOpType = fast_rep_out.uop.fuOpType;
  assign io_fast_rep_out_bits_uop_rfWen = fast_rep_out.uop.rfWen;
  assign io_fast_rep_out_bits_uop_fpWen = fast_rep_out.uop.fpWen;
  assign io_fast_rep_out_bits_uop_vecWen = fast_rep_out.uop.vecWen;
  assign io_fast_rep_out_bits_uop_v0Wen = fast_rep_out.uop.v0Wen;
  assign io_fast_rep_out_bits_uop_vlWen = fast_rep_out.uop.vlWen;
  assign io_fast_rep_out_bits_uop_isXSTrap = fast_rep_out.uop.isXSTrap;
  assign io_fast_rep_out_bits_uop_waitForward = fast_rep_out.uop.waitForward;
  assign io_fast_rep_out_bits_uop_blockBackward = fast_rep_out.uop.blockBackward;
  assign io_fast_rep_out_bits_uop_canRobCompress = fast_rep_out.uop.canRobCompress;
  assign io_fast_rep_out_bits_uop_selImm = fast_rep_out.uop.selImm;
  assign io_fast_rep_out_bits_uop_imm = fast_rep_out.uop.imm;
  assign io_fast_rep_out_bits_uop_fpu_typeTagOut = fast_rep_out.uop.fpu_typeTagOut;
  assign io_fast_rep_out_bits_uop_fpu_wflags = fast_rep_out.uop.fpu_wflags;
  assign io_fast_rep_out_bits_uop_fpu_typ = fast_rep_out.uop.fpu_typ;
  assign io_fast_rep_out_bits_uop_fpu_fmt = fast_rep_out.uop.fpu_fmt;
  assign io_fast_rep_out_bits_uop_fpu_rm = fast_rep_out.uop.fpu_rm;
  assign io_fast_rep_out_bits_uop_vpu_vill = fast_rep_out.uop.vpu_vill;
  assign io_fast_rep_out_bits_uop_vpu_vma = fast_rep_out.uop.vpu_vma;
  assign io_fast_rep_out_bits_uop_vpu_vta = fast_rep_out.uop.vpu_vta;
  assign io_fast_rep_out_bits_uop_vpu_vsew = fast_rep_out.uop.vpu_vsew;
  assign io_fast_rep_out_bits_uop_vpu_vlmul = fast_rep_out.uop.vpu_vlmul;
  assign io_fast_rep_out_bits_uop_vpu_specVill = fast_rep_out.uop.vpu_specVill;
  assign io_fast_rep_out_bits_uop_vpu_specVma = fast_rep_out.uop.vpu_specVma;
  assign io_fast_rep_out_bits_uop_vpu_specVta = fast_rep_out.uop.vpu_specVta;
  assign io_fast_rep_out_bits_uop_vpu_specVsew = fast_rep_out.uop.vpu_specVsew;
  assign io_fast_rep_out_bits_uop_vpu_specVlmul = fast_rep_out.uop.vpu_specVlmul;
  assign io_fast_rep_out_bits_uop_vpu_vm = fast_rep_out.uop.vpu_vm;
  assign io_fast_rep_out_bits_uop_vpu_vstart = fast_rep_out.uop.vpu_vstart;
  assign io_fast_rep_out_bits_uop_vpu_frm = fast_rep_out.uop.vpu_frm;
  assign io_fast_rep_out_bits_uop_vpu_fpu_isFpToVecInst = fast_rep_out.uop.vpu_fpu_isFpToVecInst;
  assign io_fast_rep_out_bits_uop_vpu_fpu_isFP32Instr = fast_rep_out.uop.vpu_fpu_isFP32Instr;
  assign io_fast_rep_out_bits_uop_vpu_fpu_isFP64Instr = fast_rep_out.uop.vpu_fpu_isFP64Instr;
  assign io_fast_rep_out_bits_uop_vpu_fpu_isReduction = fast_rep_out.uop.vpu_fpu_isReduction;
  assign io_fast_rep_out_bits_uop_vpu_fpu_isFoldTo1_2 = fast_rep_out.uop.vpu_fpu_isFoldTo1_2;
  assign io_fast_rep_out_bits_uop_vpu_fpu_isFoldTo1_4 = fast_rep_out.uop.vpu_fpu_isFoldTo1_4;
  assign io_fast_rep_out_bits_uop_vpu_fpu_isFoldTo1_8 = fast_rep_out.uop.vpu_fpu_isFoldTo1_8;
  assign io_fast_rep_out_bits_uop_vpu_vxrm = fast_rep_out.uop.vpu_vxrm;
  assign io_fast_rep_out_bits_uop_vpu_vuopIdx = fast_rep_out.uop.vpu_vuopIdx;
  assign io_fast_rep_out_bits_uop_vpu_lastUop = fast_rep_out.uop.vpu_lastUop;
  assign io_fast_rep_out_bits_uop_vpu_vmask = fast_rep_out.uop.vpu_vmask;
  assign io_fast_rep_out_bits_uop_vpu_vl = fast_rep_out.uop.vpu_vl;
  assign io_fast_rep_out_bits_uop_vpu_nf = fast_rep_out.uop.vpu_nf;
  assign io_fast_rep_out_bits_uop_vpu_veew = fast_rep_out.uop.vpu_veew;
  assign io_fast_rep_out_bits_uop_vpu_isReverse = fast_rep_out.uop.vpu_isReverse;
  assign io_fast_rep_out_bits_uop_vpu_isExt = fast_rep_out.uop.vpu_isExt;
  assign io_fast_rep_out_bits_uop_vpu_isNarrow = fast_rep_out.uop.vpu_isNarrow;
  assign io_fast_rep_out_bits_uop_vpu_isDstMask = fast_rep_out.uop.vpu_isDstMask;
  assign io_fast_rep_out_bits_uop_vpu_isOpMask = fast_rep_out.uop.vpu_isOpMask;
  assign io_fast_rep_out_bits_uop_vpu_isMove = fast_rep_out.uop.vpu_isMove;
  assign io_fast_rep_out_bits_uop_vpu_isDependOldVd = fast_rep_out.uop.vpu_isDependOldVd;
  assign io_fast_rep_out_bits_uop_vpu_isWritePartVd = fast_rep_out.uop.vpu_isWritePartVd;
  assign io_fast_rep_out_bits_uop_vpu_isVleff = fast_rep_out.uop.vpu_isVleff;
  assign io_fast_rep_out_bits_uop_vlsInstr = fast_rep_out.uop.vlsInstr;
  assign io_fast_rep_out_bits_uop_wfflags = fast_rep_out.uop.wfflags;
  assign io_fast_rep_out_bits_uop_isMove = fast_rep_out.uop.isMove;
  assign io_fast_rep_out_bits_uop_isDropAmocasSta = fast_rep_out.uop.isDropAmocasSta;
  assign io_fast_rep_out_bits_uop_uopIdx = fast_rep_out.uop.uopIdx;
  assign io_fast_rep_out_bits_uop_isVset = fast_rep_out.uop.isVset;
  assign io_fast_rep_out_bits_uop_firstUop = fast_rep_out.uop.firstUop;
  assign io_fast_rep_out_bits_uop_lastUop = fast_rep_out.uop.lastUop;
  assign io_fast_rep_out_bits_uop_numUops = fast_rep_out.uop.numUops;
  assign io_fast_rep_out_bits_uop_numWB = fast_rep_out.uop.numWB;
  assign io_fast_rep_out_bits_uop_commitType = fast_rep_out.uop.commitType;
  assign io_fast_rep_out_bits_uop_srcState_0 = fast_rep_out.uop.srcState_0;
  assign io_fast_rep_out_bits_uop_srcState_1 = fast_rep_out.uop.srcState_1;
  assign io_fast_rep_out_bits_uop_srcState_2 = fast_rep_out.uop.srcState_2;
  assign io_fast_rep_out_bits_uop_srcState_3 = fast_rep_out.uop.srcState_3;
  assign io_fast_rep_out_bits_uop_srcState_4 = fast_rep_out.uop.srcState_4;
  assign io_fast_rep_out_bits_uop_srcLoadDependency_0_0 = fast_rep_out.uop.srcLoadDependency_0_0;
  assign io_fast_rep_out_bits_uop_srcLoadDependency_0_1 = fast_rep_out.uop.srcLoadDependency_0_1;
  assign io_fast_rep_out_bits_uop_srcLoadDependency_0_2 = fast_rep_out.uop.srcLoadDependency_0_2;
  assign io_fast_rep_out_bits_uop_srcLoadDependency_1_0 = fast_rep_out.uop.srcLoadDependency_1_0;
  assign io_fast_rep_out_bits_uop_srcLoadDependency_1_1 = fast_rep_out.uop.srcLoadDependency_1_1;
  assign io_fast_rep_out_bits_uop_srcLoadDependency_1_2 = fast_rep_out.uop.srcLoadDependency_1_2;
  assign io_fast_rep_out_bits_uop_srcLoadDependency_2_0 = fast_rep_out.uop.srcLoadDependency_2_0;
  assign io_fast_rep_out_bits_uop_srcLoadDependency_2_1 = fast_rep_out.uop.srcLoadDependency_2_1;
  assign io_fast_rep_out_bits_uop_srcLoadDependency_2_2 = fast_rep_out.uop.srcLoadDependency_2_2;
  assign io_fast_rep_out_bits_uop_srcLoadDependency_3_0 = fast_rep_out.uop.srcLoadDependency_3_0;
  assign io_fast_rep_out_bits_uop_srcLoadDependency_3_1 = fast_rep_out.uop.srcLoadDependency_3_1;
  assign io_fast_rep_out_bits_uop_srcLoadDependency_3_2 = fast_rep_out.uop.srcLoadDependency_3_2;
  assign io_fast_rep_out_bits_uop_srcLoadDependency_4_0 = fast_rep_out.uop.srcLoadDependency_4_0;
  assign io_fast_rep_out_bits_uop_srcLoadDependency_4_1 = fast_rep_out.uop.srcLoadDependency_4_1;
  assign io_fast_rep_out_bits_uop_srcLoadDependency_4_2 = fast_rep_out.uop.srcLoadDependency_4_2;
  assign io_fast_rep_out_bits_uop_psrc_0 = fast_rep_out.uop.psrc_0;
  assign io_fast_rep_out_bits_uop_psrc_1 = fast_rep_out.uop.psrc_1;
  assign io_fast_rep_out_bits_uop_psrc_2 = fast_rep_out.uop.psrc_2;
  assign io_fast_rep_out_bits_uop_psrc_3 = fast_rep_out.uop.psrc_3;
  assign io_fast_rep_out_bits_uop_psrc_4 = fast_rep_out.uop.psrc_4;
  assign io_fast_rep_out_bits_uop_pdest = fast_rep_out.uop.pdest;
  assign io_fast_rep_out_bits_uop_useRegCache_0 = fast_rep_out.uop.useRegCache_0;
  assign io_fast_rep_out_bits_uop_useRegCache_1 = fast_rep_out.uop.useRegCache_1;
  assign io_fast_rep_out_bits_uop_regCacheIdx_0 = fast_rep_out.uop.regCacheIdx_0;
  assign io_fast_rep_out_bits_uop_regCacheIdx_1 = fast_rep_out.uop.regCacheIdx_1;
  assign io_fast_rep_out_bits_uop_robIdx_flag = fast_rep_out.uop.robIdx_flag;
  assign io_fast_rep_out_bits_uop_robIdx_value = fast_rep_out.uop.robIdx_value;
  assign io_fast_rep_out_bits_uop_instrSize = fast_rep_out.uop.instrSize;
  assign io_fast_rep_out_bits_uop_dirtyFs = fast_rep_out.uop.dirtyFs;
  assign io_fast_rep_out_bits_uop_dirtyVs = fast_rep_out.uop.dirtyVs;
  assign io_fast_rep_out_bits_uop_traceBlockInPipe_itype = fast_rep_out.uop.traceBlockInPipe_itype;
  assign io_fast_rep_out_bits_uop_traceBlockInPipe_iretire = fast_rep_out.uop.traceBlockInPipe_iretire;
  assign io_fast_rep_out_bits_uop_traceBlockInPipe_ilastsize = fast_rep_out.uop.traceBlockInPipe_ilastsize;
  assign io_fast_rep_out_bits_uop_eliminatedMove = fast_rep_out.uop.eliminatedMove;
  assign io_fast_rep_out_bits_uop_snapshot = fast_rep_out.uop.snapshot;
  assign io_fast_rep_out_bits_uop_debugInfo_eliminatedMove = fast_rep_out.uop.debugInfo_eliminatedMove;
  assign io_fast_rep_out_bits_uop_debugInfo_renameTime = fast_rep_out.uop.debugInfo_renameTime;
  assign io_fast_rep_out_bits_uop_debugInfo_dispatchTime = fast_rep_out.uop.debugInfo_dispatchTime;
  assign io_fast_rep_out_bits_uop_debugInfo_enqRsTime = fast_rep_out.uop.debugInfo_enqRsTime;
  assign io_fast_rep_out_bits_uop_debugInfo_selectTime = fast_rep_out.uop.debugInfo_selectTime;
  assign io_fast_rep_out_bits_uop_debugInfo_issueTime = fast_rep_out.uop.debugInfo_issueTime;
  assign io_fast_rep_out_bits_uop_debugInfo_writebackTime = fast_rep_out.uop.debugInfo_writebackTime;
  assign io_fast_rep_out_bits_uop_debugInfo_runahead_checkpoint_id = fast_rep_out.uop.debugInfo_runahead_checkpoint_id;
  assign io_fast_rep_out_bits_uop_debugInfo_tlbFirstReqTime = fast_rep_out.uop.debugInfo_tlbFirstReqTime;
  assign io_fast_rep_out_bits_uop_debugInfo_tlbRespTime = fast_rep_out.uop.debugInfo_tlbRespTime;
  assign io_fast_rep_out_bits_uop_debug_seqNum_seqNum = fast_rep_out.uop.debug_seqNum_seqNum;
  assign io_fast_rep_out_bits_uop_debug_seqNum_uopIdx = fast_rep_out.uop.debug_seqNum_uopIdx;
  assign io_fast_rep_out_bits_uop_storeSetHit = fast_rep_out.uop.storeSetHit;
  assign io_fast_rep_out_bits_uop_waitForRobIdx_flag = fast_rep_out.uop.waitForRobIdx_flag;
  assign io_fast_rep_out_bits_uop_waitForRobIdx_value = fast_rep_out.uop.waitForRobIdx_value;
  assign io_fast_rep_out_bits_uop_loadWaitBit = fast_rep_out.uop.loadWaitBit;
  assign io_fast_rep_out_bits_uop_loadWaitStrict = fast_rep_out.uop.loadWaitStrict;
  assign io_fast_rep_out_bits_uop_ssid = fast_rep_out.uop.ssid;
  assign io_fast_rep_out_bits_uop_lqIdx_flag = fast_rep_out.uop.lqIdx_flag;
  assign io_fast_rep_out_bits_uop_lqIdx_value = fast_rep_out.uop.lqIdx_value;
  assign io_fast_rep_out_bits_uop_sqIdx_flag = fast_rep_out.uop.sqIdx_flag;
  assign io_fast_rep_out_bits_uop_sqIdx_value = fast_rep_out.uop.sqIdx_value;
  assign io_fast_rep_out_bits_uop_singleStep = fast_rep_out.uop.singleStep;
  assign io_fast_rep_out_bits_uop_replayInst = fast_rep_out.uop.replayInst;
  assign io_fast_rep_out_bits_uop_debug_fuType = fast_rep_out.uop.debug_fuType;
  assign io_fast_rep_out_bits_uop_debug_sim_trig = fast_rep_out.uop.debug_sim_trig;
  assign io_fast_rep_out_bits_uop_numLsElem = fast_rep_out.uop.numLsElem;
  assign io_fast_rep_out_bits_vaddr = fast_rep_out.vaddr;
  assign io_fast_rep_out_bits_paddr = fast_rep_out.paddr;
  assign io_fast_rep_out_bits_mask = fast_rep_out.mask;
  assign io_fast_rep_out_bits_data = fast_rep_out.data;
  assign io_fast_rep_out_bits_isvec = fast_rep_out.isvec;
  assign io_fast_rep_out_bits_is128bit = fast_rep_out.is128bit;
  assign io_fast_rep_out_bits_elemIdx = fast_rep_out.elemIdx;
  assign io_fast_rep_out_bits_alignedType = fast_rep_out.alignedType;
  assign io_fast_rep_out_bits_mbIndex = fast_rep_out.mbIndex;
  assign io_fast_rep_out_bits_reg_offset = fast_rep_out.reg_offset;
  assign io_fast_rep_out_bits_elemIdxInsideVd = fast_rep_out.elemIdxInsideVd;
  assign io_fast_rep_out_bits_vecActive = fast_rep_out.vecActive;
  assign io_fast_rep_out_bits_isLoadReplay = fast_rep_out.isLoadReplay;
  assign io_fast_rep_out_bits_hasROBEntry = fast_rep_out.hasROBEntry;
  assign io_fast_rep_out_bits_lateKill = fast_rep_out.lateKill;
  assign io_fast_rep_out_bits_schedIndex = fast_rep_out.schedIndex;
  assign io_fast_rep_out_bits_isFrmMisAlignBuf = fast_rep_out.isFrmMisAlignBuf;
  assign io_fast_rep_out_bits_rep_info_mshr_id = fast_rep_out.rep_info_mshr_id;
  assign io_misalign_enq_req_bits_uop_instr = misalign_enq.uop.instr;
  assign io_misalign_enq_req_bits_uop_pc = misalign_enq.uop.pc;
  assign io_misalign_enq_req_bits_uop_foldpc = misalign_enq.uop.foldpc;
  assign io_misalign_enq_req_bits_uop_exceptionVec_0 = misalign_enq.uop.exceptionVec[0];
  assign io_misalign_enq_req_bits_uop_exceptionVec_1 = misalign_enq.uop.exceptionVec[1];
  assign io_misalign_enq_req_bits_uop_exceptionVec_2 = misalign_enq.uop.exceptionVec[2];
  assign io_misalign_enq_req_bits_uop_exceptionVec_3 = misalign_enq.uop.exceptionVec[3];
  assign io_misalign_enq_req_bits_uop_exceptionVec_5 = misalign_enq.uop.exceptionVec[5];
  assign io_misalign_enq_req_bits_uop_exceptionVec_6 = misalign_enq.uop.exceptionVec[6];
  assign io_misalign_enq_req_bits_uop_exceptionVec_7 = misalign_enq.uop.exceptionVec[7];
  assign io_misalign_enq_req_bits_uop_exceptionVec_8 = misalign_enq.uop.exceptionVec[8];
  assign io_misalign_enq_req_bits_uop_exceptionVec_9 = misalign_enq.uop.exceptionVec[9];
  assign io_misalign_enq_req_bits_uop_exceptionVec_10 = misalign_enq.uop.exceptionVec[10];
  assign io_misalign_enq_req_bits_uop_exceptionVec_11 = misalign_enq.uop.exceptionVec[11];
  assign io_misalign_enq_req_bits_uop_exceptionVec_12 = misalign_enq.uop.exceptionVec[12];
  assign io_misalign_enq_req_bits_uop_exceptionVec_13 = misalign_enq.uop.exceptionVec[13];
  assign io_misalign_enq_req_bits_uop_exceptionVec_14 = misalign_enq.uop.exceptionVec[14];
  assign io_misalign_enq_req_bits_uop_exceptionVec_15 = misalign_enq.uop.exceptionVec[15];
  assign io_misalign_enq_req_bits_uop_exceptionVec_16 = misalign_enq.uop.exceptionVec[16];
  assign io_misalign_enq_req_bits_uop_exceptionVec_17 = misalign_enq.uop.exceptionVec[17];
  assign io_misalign_enq_req_bits_uop_exceptionVec_18 = misalign_enq.uop.exceptionVec[18];
  assign io_misalign_enq_req_bits_uop_exceptionVec_19 = misalign_enq.uop.exceptionVec[19];
  assign io_misalign_enq_req_bits_uop_exceptionVec_20 = misalign_enq.uop.exceptionVec[20];
  assign io_misalign_enq_req_bits_uop_exceptionVec_21 = misalign_enq.uop.exceptionVec[21];
  assign io_misalign_enq_req_bits_uop_exceptionVec_22 = misalign_enq.uop.exceptionVec[22];
  assign io_misalign_enq_req_bits_uop_exceptionVec_23 = misalign_enq.uop.exceptionVec[23];
  assign io_misalign_enq_req_bits_uop_isFetchMalAddr = misalign_enq.uop.isFetchMalAddr;
  assign io_misalign_enq_req_bits_uop_hasException = misalign_enq.uop.hasException;
  assign io_misalign_enq_req_bits_uop_trigger = misalign_enq.uop.trigger;
  assign io_misalign_enq_req_bits_uop_preDecodeInfo_valid = misalign_enq.uop.preDecodeInfo_valid;
  assign io_misalign_enq_req_bits_uop_preDecodeInfo_isRVC = misalign_enq.uop.preDecodeInfo_isRVC;
  assign io_misalign_enq_req_bits_uop_preDecodeInfo_brType = misalign_enq.uop.preDecodeInfo_brType;
  assign io_misalign_enq_req_bits_uop_preDecodeInfo_isCall = misalign_enq.uop.preDecodeInfo_isCall;
  assign io_misalign_enq_req_bits_uop_preDecodeInfo_isRet = misalign_enq.uop.preDecodeInfo_isRet;
  assign io_misalign_enq_req_bits_uop_pred_taken = misalign_enq.uop.pred_taken;
  assign io_misalign_enq_req_bits_uop_crossPageIPFFix = misalign_enq.uop.crossPageIPFFix;
  assign io_misalign_enq_req_bits_uop_ftqPtr_flag = misalign_enq.uop.ftqPtr_flag;
  assign io_misalign_enq_req_bits_uop_ftqPtr_value = misalign_enq.uop.ftqPtr_value;
  assign io_misalign_enq_req_bits_uop_ftqOffset = misalign_enq.uop.ftqOffset;
  assign io_misalign_enq_req_bits_uop_satpFlushFirstFetchFault = misalign_enq.uop.satpFlushFirstFetchFault;
  assign io_misalign_enq_req_bits_uop_srcType_0 = misalign_enq.uop.srcType_0;
  assign io_misalign_enq_req_bits_uop_srcType_1 = misalign_enq.uop.srcType_1;
  assign io_misalign_enq_req_bits_uop_srcType_2 = misalign_enq.uop.srcType_2;
  assign io_misalign_enq_req_bits_uop_srcType_3 = misalign_enq.uop.srcType_3;
  assign io_misalign_enq_req_bits_uop_srcType_4 = misalign_enq.uop.srcType_4;
  assign io_misalign_enq_req_bits_uop_ldest = misalign_enq.uop.ldest;
  assign io_misalign_enq_req_bits_uop_fuType = misalign_enq.uop.fuType;
  assign io_misalign_enq_req_bits_uop_fuOpType = misalign_enq.uop.fuOpType;
  assign io_misalign_enq_req_bits_uop_rfWen = misalign_enq.uop.rfWen;
  assign io_misalign_enq_req_bits_uop_fpWen = misalign_enq.uop.fpWen;
  assign io_misalign_enq_req_bits_uop_vecWen = misalign_enq.uop.vecWen;
  assign io_misalign_enq_req_bits_uop_v0Wen = misalign_enq.uop.v0Wen;
  assign io_misalign_enq_req_bits_uop_vlWen = misalign_enq.uop.vlWen;
  assign io_misalign_enq_req_bits_uop_isXSTrap = misalign_enq.uop.isXSTrap;
  assign io_misalign_enq_req_bits_uop_waitForward = misalign_enq.uop.waitForward;
  assign io_misalign_enq_req_bits_uop_blockBackward = misalign_enq.uop.blockBackward;
  assign io_misalign_enq_req_bits_uop_canRobCompress = misalign_enq.uop.canRobCompress;
  assign io_misalign_enq_req_bits_uop_selImm = misalign_enq.uop.selImm;
  assign io_misalign_enq_req_bits_uop_imm = misalign_enq.uop.imm;
  assign io_misalign_enq_req_bits_uop_fpu_typeTagOut = misalign_enq.uop.fpu_typeTagOut;
  assign io_misalign_enq_req_bits_uop_fpu_wflags = misalign_enq.uop.fpu_wflags;
  assign io_misalign_enq_req_bits_uop_fpu_typ = misalign_enq.uop.fpu_typ;
  assign io_misalign_enq_req_bits_uop_fpu_fmt = misalign_enq.uop.fpu_fmt;
  assign io_misalign_enq_req_bits_uop_fpu_rm = misalign_enq.uop.fpu_rm;
  assign io_misalign_enq_req_bits_uop_vpu_vill = misalign_enq.uop.vpu_vill;
  assign io_misalign_enq_req_bits_uop_vpu_vma = misalign_enq.uop.vpu_vma;
  assign io_misalign_enq_req_bits_uop_vpu_vta = misalign_enq.uop.vpu_vta;
  assign io_misalign_enq_req_bits_uop_vpu_vsew = misalign_enq.uop.vpu_vsew;
  assign io_misalign_enq_req_bits_uop_vpu_vlmul = misalign_enq.uop.vpu_vlmul;
  assign io_misalign_enq_req_bits_uop_vpu_specVill = misalign_enq.uop.vpu_specVill;
  assign io_misalign_enq_req_bits_uop_vpu_specVma = misalign_enq.uop.vpu_specVma;
  assign io_misalign_enq_req_bits_uop_vpu_specVta = misalign_enq.uop.vpu_specVta;
  assign io_misalign_enq_req_bits_uop_vpu_specVsew = misalign_enq.uop.vpu_specVsew;
  assign io_misalign_enq_req_bits_uop_vpu_specVlmul = misalign_enq.uop.vpu_specVlmul;
  assign io_misalign_enq_req_bits_uop_vpu_vm = misalign_enq.uop.vpu_vm;
  assign io_misalign_enq_req_bits_uop_vpu_vstart = misalign_enq.uop.vpu_vstart;
  assign io_misalign_enq_req_bits_uop_vpu_frm = misalign_enq.uop.vpu_frm;
  assign io_misalign_enq_req_bits_uop_vpu_fpu_isFpToVecInst = misalign_enq.uop.vpu_fpu_isFpToVecInst;
  assign io_misalign_enq_req_bits_uop_vpu_fpu_isFP32Instr = misalign_enq.uop.vpu_fpu_isFP32Instr;
  assign io_misalign_enq_req_bits_uop_vpu_fpu_isFP64Instr = misalign_enq.uop.vpu_fpu_isFP64Instr;
  assign io_misalign_enq_req_bits_uop_vpu_fpu_isReduction = misalign_enq.uop.vpu_fpu_isReduction;
  assign io_misalign_enq_req_bits_uop_vpu_fpu_isFoldTo1_2 = misalign_enq.uop.vpu_fpu_isFoldTo1_2;
  assign io_misalign_enq_req_bits_uop_vpu_fpu_isFoldTo1_4 = misalign_enq.uop.vpu_fpu_isFoldTo1_4;
  assign io_misalign_enq_req_bits_uop_vpu_fpu_isFoldTo1_8 = misalign_enq.uop.vpu_fpu_isFoldTo1_8;
  assign io_misalign_enq_req_bits_uop_vpu_vxrm = misalign_enq.uop.vpu_vxrm;
  assign io_misalign_enq_req_bits_uop_vpu_vuopIdx = misalign_enq.uop.vpu_vuopIdx;
  assign io_misalign_enq_req_bits_uop_vpu_lastUop = misalign_enq.uop.vpu_lastUop;
  assign io_misalign_enq_req_bits_uop_vpu_vmask = misalign_enq.uop.vpu_vmask;
  assign io_misalign_enq_req_bits_uop_vpu_vl = misalign_enq.uop.vpu_vl;
  assign io_misalign_enq_req_bits_uop_vpu_nf = misalign_enq.uop.vpu_nf;
  assign io_misalign_enq_req_bits_uop_vpu_veew = misalign_enq.uop.vpu_veew;
  assign io_misalign_enq_req_bits_uop_vpu_isReverse = misalign_enq.uop.vpu_isReverse;
  assign io_misalign_enq_req_bits_uop_vpu_isExt = misalign_enq.uop.vpu_isExt;
  assign io_misalign_enq_req_bits_uop_vpu_isNarrow = misalign_enq.uop.vpu_isNarrow;
  assign io_misalign_enq_req_bits_uop_vpu_isDstMask = misalign_enq.uop.vpu_isDstMask;
  assign io_misalign_enq_req_bits_uop_vpu_isOpMask = misalign_enq.uop.vpu_isOpMask;
  assign io_misalign_enq_req_bits_uop_vpu_isMove = misalign_enq.uop.vpu_isMove;
  assign io_misalign_enq_req_bits_uop_vpu_isDependOldVd = misalign_enq.uop.vpu_isDependOldVd;
  assign io_misalign_enq_req_bits_uop_vpu_isWritePartVd = misalign_enq.uop.vpu_isWritePartVd;
  assign io_misalign_enq_req_bits_uop_vpu_isVleff = misalign_enq.uop.vpu_isVleff;
  assign io_misalign_enq_req_bits_uop_vlsInstr = misalign_enq.uop.vlsInstr;
  assign io_misalign_enq_req_bits_uop_wfflags = misalign_enq.uop.wfflags;
  assign io_misalign_enq_req_bits_uop_isMove = misalign_enq.uop.isMove;
  assign io_misalign_enq_req_bits_uop_isDropAmocasSta = misalign_enq.uop.isDropAmocasSta;
  assign io_misalign_enq_req_bits_uop_uopIdx = misalign_enq.uop.uopIdx;
  assign io_misalign_enq_req_bits_uop_isVset = misalign_enq.uop.isVset;
  assign io_misalign_enq_req_bits_uop_firstUop = misalign_enq.uop.firstUop;
  assign io_misalign_enq_req_bits_uop_lastUop = misalign_enq.uop.lastUop;
  assign io_misalign_enq_req_bits_uop_numUops = misalign_enq.uop.numUops;
  assign io_misalign_enq_req_bits_uop_numWB = misalign_enq.uop.numWB;
  assign io_misalign_enq_req_bits_uop_commitType = misalign_enq.uop.commitType;
  assign io_misalign_enq_req_bits_uop_srcState_0 = misalign_enq.uop.srcState_0;
  assign io_misalign_enq_req_bits_uop_srcState_1 = misalign_enq.uop.srcState_1;
  assign io_misalign_enq_req_bits_uop_srcState_2 = misalign_enq.uop.srcState_2;
  assign io_misalign_enq_req_bits_uop_srcState_3 = misalign_enq.uop.srcState_3;
  assign io_misalign_enq_req_bits_uop_srcState_4 = misalign_enq.uop.srcState_4;
  assign io_misalign_enq_req_bits_uop_srcLoadDependency_0_0 = misalign_enq.uop.srcLoadDependency_0_0;
  assign io_misalign_enq_req_bits_uop_srcLoadDependency_0_1 = misalign_enq.uop.srcLoadDependency_0_1;
  assign io_misalign_enq_req_bits_uop_srcLoadDependency_0_2 = misalign_enq.uop.srcLoadDependency_0_2;
  assign io_misalign_enq_req_bits_uop_srcLoadDependency_1_0 = misalign_enq.uop.srcLoadDependency_1_0;
  assign io_misalign_enq_req_bits_uop_srcLoadDependency_1_1 = misalign_enq.uop.srcLoadDependency_1_1;
  assign io_misalign_enq_req_bits_uop_srcLoadDependency_1_2 = misalign_enq.uop.srcLoadDependency_1_2;
  assign io_misalign_enq_req_bits_uop_srcLoadDependency_2_0 = misalign_enq.uop.srcLoadDependency_2_0;
  assign io_misalign_enq_req_bits_uop_srcLoadDependency_2_1 = misalign_enq.uop.srcLoadDependency_2_1;
  assign io_misalign_enq_req_bits_uop_srcLoadDependency_2_2 = misalign_enq.uop.srcLoadDependency_2_2;
  assign io_misalign_enq_req_bits_uop_srcLoadDependency_3_0 = misalign_enq.uop.srcLoadDependency_3_0;
  assign io_misalign_enq_req_bits_uop_srcLoadDependency_3_1 = misalign_enq.uop.srcLoadDependency_3_1;
  assign io_misalign_enq_req_bits_uop_srcLoadDependency_3_2 = misalign_enq.uop.srcLoadDependency_3_2;
  assign io_misalign_enq_req_bits_uop_srcLoadDependency_4_0 = misalign_enq.uop.srcLoadDependency_4_0;
  assign io_misalign_enq_req_bits_uop_srcLoadDependency_4_1 = misalign_enq.uop.srcLoadDependency_4_1;
  assign io_misalign_enq_req_bits_uop_srcLoadDependency_4_2 = misalign_enq.uop.srcLoadDependency_4_2;
  assign io_misalign_enq_req_bits_uop_psrc_0 = misalign_enq.uop.psrc_0;
  assign io_misalign_enq_req_bits_uop_psrc_1 = misalign_enq.uop.psrc_1;
  assign io_misalign_enq_req_bits_uop_psrc_2 = misalign_enq.uop.psrc_2;
  assign io_misalign_enq_req_bits_uop_psrc_3 = misalign_enq.uop.psrc_3;
  assign io_misalign_enq_req_bits_uop_psrc_4 = misalign_enq.uop.psrc_4;
  assign io_misalign_enq_req_bits_uop_pdest = misalign_enq.uop.pdest;
  assign io_misalign_enq_req_bits_uop_useRegCache_0 = misalign_enq.uop.useRegCache_0;
  assign io_misalign_enq_req_bits_uop_useRegCache_1 = misalign_enq.uop.useRegCache_1;
  assign io_misalign_enq_req_bits_uop_regCacheIdx_0 = misalign_enq.uop.regCacheIdx_0;
  assign io_misalign_enq_req_bits_uop_regCacheIdx_1 = misalign_enq.uop.regCacheIdx_1;
  assign io_misalign_enq_req_bits_uop_robIdx_flag = misalign_enq.uop.robIdx_flag;
  assign io_misalign_enq_req_bits_uop_robIdx_value = misalign_enq.uop.robIdx_value;
  assign io_misalign_enq_req_bits_uop_instrSize = misalign_enq.uop.instrSize;
  assign io_misalign_enq_req_bits_uop_dirtyFs = misalign_enq.uop.dirtyFs;
  assign io_misalign_enq_req_bits_uop_dirtyVs = misalign_enq.uop.dirtyVs;
  assign io_misalign_enq_req_bits_uop_traceBlockInPipe_itype = misalign_enq.uop.traceBlockInPipe_itype;
  assign io_misalign_enq_req_bits_uop_traceBlockInPipe_iretire = misalign_enq.uop.traceBlockInPipe_iretire;
  assign io_misalign_enq_req_bits_uop_traceBlockInPipe_ilastsize = misalign_enq.uop.traceBlockInPipe_ilastsize;
  assign io_misalign_enq_req_bits_uop_eliminatedMove = misalign_enq.uop.eliminatedMove;
  assign io_misalign_enq_req_bits_uop_snapshot = misalign_enq.uop.snapshot;
  assign io_misalign_enq_req_bits_uop_debugInfo_eliminatedMove = misalign_enq.uop.debugInfo_eliminatedMove;
  assign io_misalign_enq_req_bits_uop_debugInfo_renameTime = misalign_enq.uop.debugInfo_renameTime;
  assign io_misalign_enq_req_bits_uop_debugInfo_dispatchTime = misalign_enq.uop.debugInfo_dispatchTime;
  assign io_misalign_enq_req_bits_uop_debugInfo_enqRsTime = misalign_enq.uop.debugInfo_enqRsTime;
  assign io_misalign_enq_req_bits_uop_debugInfo_selectTime = misalign_enq.uop.debugInfo_selectTime;
  assign io_misalign_enq_req_bits_uop_debugInfo_issueTime = misalign_enq.uop.debugInfo_issueTime;
  assign io_misalign_enq_req_bits_uop_debugInfo_writebackTime = misalign_enq.uop.debugInfo_writebackTime;
  assign io_misalign_enq_req_bits_uop_debugInfo_runahead_checkpoint_id = misalign_enq.uop.debugInfo_runahead_checkpoint_id;
  assign io_misalign_enq_req_bits_uop_debugInfo_tlbFirstReqTime = misalign_enq.uop.debugInfo_tlbFirstReqTime;
  assign io_misalign_enq_req_bits_uop_debugInfo_tlbRespTime = misalign_enq.uop.debugInfo_tlbRespTime;
  assign io_misalign_enq_req_bits_uop_debug_seqNum_seqNum = misalign_enq.uop.debug_seqNum_seqNum;
  assign io_misalign_enq_req_bits_uop_debug_seqNum_uopIdx = misalign_enq.uop.debug_seqNum_uopIdx;
  assign io_misalign_enq_req_bits_uop_storeSetHit = misalign_enq.uop.storeSetHit;
  assign io_misalign_enq_req_bits_uop_waitForRobIdx_flag = misalign_enq.uop.waitForRobIdx_flag;
  assign io_misalign_enq_req_bits_uop_waitForRobIdx_value = misalign_enq.uop.waitForRobIdx_value;
  assign io_misalign_enq_req_bits_uop_loadWaitBit = misalign_enq.uop.loadWaitBit;
  assign io_misalign_enq_req_bits_uop_loadWaitStrict = misalign_enq.uop.loadWaitStrict;
  assign io_misalign_enq_req_bits_uop_ssid = misalign_enq.uop.ssid;
  assign io_misalign_enq_req_bits_uop_lqIdx_flag = misalign_enq.uop.lqIdx_flag;
  assign io_misalign_enq_req_bits_uop_lqIdx_value = misalign_enq.uop.lqIdx_value;
  assign io_misalign_enq_req_bits_uop_sqIdx_flag = misalign_enq.uop.sqIdx_flag;
  assign io_misalign_enq_req_bits_uop_sqIdx_value = misalign_enq.uop.sqIdx_value;
  assign io_misalign_enq_req_bits_uop_singleStep = misalign_enq.uop.singleStep;
  assign io_misalign_enq_req_bits_uop_replayInst = misalign_enq.uop.replayInst;
  assign io_misalign_enq_req_bits_uop_debug_fuType = misalign_enq.uop.debug_fuType;
  assign io_misalign_enq_req_bits_uop_debug_sim_trig = misalign_enq.uop.debug_sim_trig;
  assign io_misalign_enq_req_bits_uop_numLsElem = misalign_enq.uop.numLsElem;
  assign io_misalign_enq_req_bits_vaddr = misalign_enq.vaddr;
  assign io_misalign_enq_req_bits_fullva = misalign_enq.fullva;
  assign io_misalign_enq_req_bits_vaNeedExt = misalign_enq.vaNeedExt;
  assign io_misalign_enq_req_bits_paddr = misalign_enq.paddr;
  assign io_misalign_enq_req_bits_gpaddr = misalign_enq.gpaddr;
  assign io_misalign_enq_req_bits_mask = misalign_enq.mask;
  assign io_misalign_enq_req_bits_isForVSnonLeafPTE = misalign_enq.isForVSnonLeafPTE;
  assign io_misalign_enq_req_bits_isvec = misalign_enq.isvec;
  assign io_misalign_enq_req_bits_elemIdx = misalign_enq.elemIdx;
  assign io_misalign_enq_req_bits_alignedType = misalign_enq.alignedType;
  assign io_misalign_enq_req_bits_mbIndex = misalign_enq.mbIndex;
  assign io_misalign_enq_req_bits_elemIdxInsideVd = misalign_enq.elemIdxInsideVd;
  assign io_misalign_enq_req_bits_vecTriggerMask = misalign_enq.vecTriggerMask;
  assign io_misalign_ldout_bits_uop_exceptionVec_3 = misalign_ldout.uop.exceptionVec[3];
  assign io_misalign_ldout_bits_uop_exceptionVec_4 = misalign_ldout.uop.exceptionVec[4];
  assign io_misalign_ldout_bits_uop_exceptionVec_5 = misalign_ldout.uop.exceptionVec[5];
  assign io_misalign_ldout_bits_uop_exceptionVec_13 = misalign_ldout.uop.exceptionVec[13];
  assign io_misalign_ldout_bits_uop_exceptionVec_19 = misalign_ldout.uop.exceptionVec[19];
  assign io_misalign_ldout_bits_uop_exceptionVec_21 = misalign_ldout.uop.exceptionVec[21];
  assign io_misalign_ldout_bits_uop_trigger = misalign_ldout.uop.trigger;
  assign io_misalign_ldout_bits_uop_robIdx_flag = misalign_ldout.uop.robIdx_flag;
  assign io_misalign_ldout_bits_uop_robIdx_value = misalign_ldout.uop.robIdx_value;
  assign io_misalign_ldout_bits_vaddr = misalign_ldout.vaddr;
  assign io_misalign_ldout_bits_fullva = misalign_ldout.fullva;
  assign io_misalign_ldout_bits_vaNeedExt = misalign_ldout.vaNeedExt;
  assign io_misalign_ldout_bits_paddr = misalign_ldout.paddr;
  assign io_misalign_ldout_bits_gpaddr = misalign_ldout.gpaddr;
  assign io_misalign_ldout_bits_data = misalign_ldout.data;
  assign io_misalign_ldout_bits_nc = misalign_ldout.nc;
  assign io_misalign_ldout_bits_mmio = misalign_ldout.mmio;
  assign io_misalign_ldout_bits_memBackTypeMM = misalign_ldout.memBackTypeMM;
  assign io_misalign_ldout_bits_isForVSnonLeafPTE = misalign_ldout.isForVSnonLeafPTE;
  assign io_misalign_ldout_bits_vecActive = misalign_ldout.vecActive;
  assign io_misalign_ldout_bits_misalignNeedWakeUp = misalign_ldout.misalignNeedWakeUp;
  assign io_misalign_ldout_bits_rep_info_cause_0 = misalign_ldout.rep_info_cause[0];
  assign io_misalign_ldout_bits_rep_info_cause_1 = misalign_ldout.rep_info_cause[1];
  assign io_misalign_ldout_bits_rep_info_cause_2 = misalign_ldout.rep_info_cause[2];
  assign io_misalign_ldout_bits_rep_info_cause_3 = misalign_ldout.rep_info_cause[3];
  assign io_misalign_ldout_bits_rep_info_cause_4 = misalign_ldout.rep_info_cause[4];
  assign io_misalign_ldout_bits_rep_info_cause_5 = misalign_ldout.rep_info_cause[5];
  assign io_misalign_ldout_bits_rep_info_cause_6 = misalign_ldout.rep_info_cause[6];
  assign io_misalign_ldout_bits_rep_info_cause_7 = misalign_ldout.rep_info_cause[7];
  assign io_misalign_ldout_bits_rep_info_cause_8 = misalign_ldout.rep_info_cause[8];
  assign io_misalign_ldout_bits_rep_info_cause_9 = misalign_ldout.rep_info_cause[9];
  assign io_misalign_ldout_bits_rep_info_cause_10 = misalign_ldout.rep_info_cause[10];
  assign io_feedback_slow_bits_robIdx_flag = feedback_slow.robIdx_flag;
  assign io_feedback_slow_bits_robIdx_value = feedback_slow.robIdx_value;
  assign io_feedback_slow_bits_flushState = feedback_slow.flushState;
  assign io_feedback_slow_bits_sqIdx_flag = feedback_slow.sqIdx_flag;
  assign io_feedback_slow_bits_sqIdx_value = feedback_slow.sqIdx_value;
  assign io_feedback_slow_bits_lqIdx_flag = feedback_slow.lqIdx_flag;
  assign io_feedback_slow_bits_lqIdx_value = feedback_slow.lqIdx_value;
  assign io_rollback_bits_isRVC = rollback.isRVC;
  assign io_rollback_bits_robIdx_flag = rollback.robIdx_flag;
  assign io_rollback_bits_robIdx_value = rollback.robIdx_value;
  assign io_rollback_bits_ftqIdx_flag = rollback.ftqIdx_flag;
  assign io_rollback_bits_ftqIdx_value = rollback.ftqIdx_value;
  assign io_rollback_bits_ftqOffset = rollback.ftqOffset;
  assign io_rollback_bits_level = rollback.level;
  assign io_rollback_bits_debug_runahead_checkpoint_id = rollback.debug_runahead_checkpoint_id;
  assign io_lsTopdownInfo_s1_robIdx = lsTopdownInfo.s1_robIdx;
  assign io_lsTopdownInfo_s1_vaddr_valid = lsTopdownInfo.s1_vaddr_valid;
  assign io_lsTopdownInfo_s1_vaddr_bits = lsTopdownInfo.s1_vaddr_bits;
  assign io_lsTopdownInfo_s2_robIdx = lsTopdownInfo.s2_robIdx;
  assign io_lsTopdownInfo_s2_paddr_valid = lsTopdownInfo.s2_paddr_valid;
  assign io_lsTopdownInfo_s2_paddr_bits = lsTopdownInfo.s2_paddr_bits;

  xs_LoadUnit_core u_core (
    .clock (clock),
    .reset (reset),
    .ldin (ldin),
    .vecldin (vecldin),
    .misalign_ldin (misalign_ldin),
    .replay (replay),
    .fast_rep_in (fast_rep_in),
    .lsq_nc_ldin (lsq_nc_ldin),
    .lsq_uncache (lsq_uncache),
    .prefetch_req (prefetch_req),
    .tlb_resp (tlb_resp),
    .trigger_csr (trigger_csr),
    .stld_nuke_query_0 (stld_nuke_query_0),
    .stld_nuke_query_1 (stld_nuke_query_1),
    .pmp (pmp),
    .dcache_resp (dcache_resp),
    .sbuffer_resp (sbuffer_resp),
    .ubuffer_resp (ubuffer_resp),
    .lsq_fwd_resp (lsq_fwd_resp),
    .tl_d_channel (tl_d_channel),
    .mshr_fwd_resp (mshr_fwd_resp),
    .tlb_hint (tlb_hint),
    .ld_raw_data (ld_raw_data),
    .robDeqIdx (robDeqIdx),
    .redirect (redirect),
    .csrCtrl (csrCtrl),
    .tlb_req (tlb_req),
    .dcache_req (dcache_req),
    .sbuffer_req (sbuffer_req),
    .ubuffer_req (ubuffer_req),
    .lsq_fwd_req (lsq_fwd_req),
    .mshr_fwd_req (mshr_fwd_req),
    .stld_nuke_req (stld_nuke_req),
    .ldld_nuke_req (ldld_nuke_req),
    .prefetch_train (prefetch_train),
    .prefetch_train_l1 (prefetch_train_l1),
    .ifetchPrefetch (ifetchPrefetch),
    .wakeup (wakeup),
    .ldout (ldout),
    .vecldout (vecldout),
    .lsq_ldin (lsq_ldin),
    .fast_rep_out (fast_rep_out),
    .misalign_enq (misalign_enq),
    .misalign_ldout (misalign_ldout),
    .feedback_slow (feedback_slow),
    .rollback (rollback),
    .lsTopdownInfo (lsTopdownInfo),
    .redirect_valid (io_redirect_valid),
    .ldin_ready (io_ldin_ready),
    .ldin_valid (io_ldin_valid),
    .ldout_ready (io_ldout_ready),
    .ldout_valid (io_ldout_valid),
    .vecldin_ready (io_vecldin_ready),
    .vecldin_valid (io_vecldin_valid),
    .vecldout_valid (io_vecldout_valid),
    .misalign_ldin_ready (io_misalign_ldin_ready),
    .misalign_ldin_valid (io_misalign_ldin_valid),
    .misalign_ldout_valid (io_misalign_ldout_valid),
    .tlb_req_valid (io_tlb_req_valid),
    .tlb_req_kill (io_tlb_req_kill),
    .tlb_resp_valid (io_tlb_resp_valid),
    .dcache_req_ready (io_dcache_req_ready),
    .dcache_req_valid (io_dcache_req_valid),
    .dcache_resp_valid (io_dcache_resp_valid),
    .dcache_s1_kill_data_read (io_dcache_s1_kill_data_read),
    .dcache_s1_kill (io_dcache_s1_kill),
    .dcache_s2_kill (io_dcache_s2_kill),
    .dcache_is128Req (io_dcache_is128Req),
    .dcache_pf_source (io_dcache_pf_source),
    .dcache_s1_paddr_dup_lsu (io_dcache_s1_paddr_dup_lsu),
    .dcache_s1_paddr_dup_dcache (io_dcache_s1_paddr_dup_dcache),
    .dcache_s2_bank_conflict (io_dcache_s2_bank_conflict),
    .dcache_s2_mq_nack (io_dcache_s2_mq_nack),
    .lsq_ldin_valid (io_lsq_ldin_valid),
    .lsq_uncache_ready (io_lsq_uncache_ready),
    .lsq_uncache_valid (io_lsq_uncache_valid),
    .lsq_nc_ldin_ready (io_lsq_nc_ldin_ready),
    .lsq_nc_ldin_valid (io_lsq_nc_ldin_valid),
    .lsq_stld_nuke_query_req_ready (io_lsq_stld_nuke_query_req_ready),
    .lsq_stld_nuke_query_req_valid (io_lsq_stld_nuke_query_req_valid),
    .lsq_stld_nuke_query_revoke (io_lsq_stld_nuke_query_revoke),
    .lsq_ldld_nuke_query_req_ready (io_lsq_ldld_nuke_query_req_ready),
    .lsq_ldld_nuke_query_req_valid (io_lsq_ldld_nuke_query_req_valid),
    .lsq_ldld_nuke_query_resp_valid (io_lsq_ldld_nuke_query_resp_valid),
    .lsq_ldld_nuke_query_resp_bits_rep_frm_fetch (io_lsq_ldld_nuke_query_resp_bits_rep_frm_fetch),
    .lsq_ldld_nuke_query_revoke (io_lsq_ldld_nuke_query_revoke),
    .prefetch_train_valid (io_prefetch_train_valid),
    .prefetch_train_l1_valid (io_prefetch_train_l1_valid),
    .s1_prefetch_spec (io_s1_prefetch_spec),
    .s2_prefetch_spec (io_s2_prefetch_spec),
    .s1_prefetch_spec_l1 (io_s1_prefetch_spec_l1),
    .s2_prefetch_spec_l1 (io_s2_prefetch_spec_l1),
    .prefetch_req_valid (io_prefetch_req_valid),
    .canAcceptLowConfPrefetch (io_canAcceptLowConfPrefetch),
    .canAcceptHighConfPrefetch (io_canAcceptHighConfPrefetch),
    .ifetchPrefetch_valid (io_ifetchPrefetch_valid),
    .wakeup_valid (io_wakeup_valid),
    .feedback_slow_valid (io_feedback_slow_valid),
    .ldCancel_ld2Cancel (io_ldCancel_ld2Cancel),
    .replay_ready (io_replay_ready),
    .replay_valid (io_replay_valid),
    .s2_ptr_chasing (io_s2_ptr_chasing),
    .fast_rep_in_valid (io_fast_rep_in_valid),
    .fast_rep_out_valid (io_fast_rep_out_valid),
    .misalign_enq_req_ready (io_misalign_enq_req_ready),
    .misalign_enq_req_valid (io_misalign_enq_req_valid),
    .rollback_valid (io_rollback_valid),
    .perf_0_value (io_perf_0_value),
    .perf_1_value (io_perf_1_value),
    .perf_2_value (io_perf_2_value),
    .perf_3_value (io_perf_3_value),
    .perf_4_value (io_perf_4_value),
    .perf_5_value (io_perf_5_value),
    .perf_6_value (io_perf_6_value),
    .perf_7_value (io_perf_7_value),
    .perf_8_value (io_perf_8_value)
  );

endmodule
// END GENERATED(wrapper)
