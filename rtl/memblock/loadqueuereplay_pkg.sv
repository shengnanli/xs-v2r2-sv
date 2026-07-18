// =============================================================================
//  loadqueuereplay_pkg —— LoadQueueReplay（load 重放调度器）类型/常量/纯函数包
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/mem/lsqueue/LoadQueueReplay.scala
//
//  LoadQueueReplay 保存所有「在 LoadUnit 流水中因各种原因 block、需要重新发射」的
//  load。每条被 block 的 load 在 LoadUnit s3 入队到这里，按 (replay cause 优先级 +
//  程序序年龄) 重新选出并经 s0/s1/s2 三级流水发射回 LoadUnit 重跑。
//
//  本包集中：
//    - 队列规模/流水宽度等参数（LoadQueueReplaySize=72, LoadPipelineWidth=3, ...）
//    - 11 种 replay cause 的编码（enum，优先级即编码值，低=高优先）
//    - replay 指针（LqPtr/SqPtr/RobPtr）的 {flag,value} struct 及环形比较纯函数
//    - 入队 uop 元数据 / 向量重放信息 struct
// =============================================================================
package loadqueuereplay_pkg;

  // ---- 规模/宽度参数（昆明湖 V2R2 配置，与 golden 一致）-----------------------
  localparam int LQ_REPLAY_SIZE = 72;          // LoadQueueReplaySize
  localparam int LD_PIPE_W      = 3;           // LoadPipelineWidth
  localparam int VEC_PIPE_W     = 2;           // VecLoadPipelineWidth
  localparam int ST_PIPE_W      = 2;           // StorePipelineWidth
  localparam int SQ_SIZE        = 56;          // StoreQueueSize（stAddrReadyVec 宽度）
  localparam int N_CAUSES       = 11;          // LoadReplayCauses.allCauses

  localparam int LQ_IDX_W       = 7;           // log2Up(72) 的指针 value 宽度（LqPtr）
  // entry 阵列按 2^LQ_IDX_W=128 声明（实际只用 0..71）：让 7 位下标静态在界，消除
  //  Formality FMR_ELAB-147「非 2 幂数组动态下标越界」误报（与 golden firtool 把
  //  阵列 0 填充到 128 同理）；77..127 这些 padding 槽永不分配（复位清 0）。
  localparam int LQ_SLOTS       = 1 << LQ_IDX_W;  // 128
  localparam int SQ_IDX_W       = 6;           // SqPtr value 宽度
  localparam int ROB_IDX_W      = 8;           // RobPtr value 宽度
  localparam int VADDR_BITS     = 50;          // 虚地址宽度
  localparam int MSHR_ID_W      = 4;           // log2Up(nMissEntries+1)
  localparam int TLB_ID_W       = 4;           // log2Up(loadfiltersize+1)
  localparam int UOP_IDX_W      = 7;           // uopIdx 宽度

  // 每个 AgeDetector 处理的 entry 数 = LQ_REPLAY_SIZE / LD_PIPE_W = 24
  localparam int REM_SIZE       = LQ_REPLAY_SIZE / LD_PIPE_W;   // 24
  localparam int REM_IDX_W      = 5;           // log2Up(24)

  // sched index 输出宽度（log2Up(72+1)=7）
  localparam int SCHED_IDX_W    = LQ_IDX_W;

  // 年龄选择步长（必须 <= load 流水级数）
  localparam int OLDEST_STRIDE  = 4;

  // replay 冷却：连续重放同一口超过阈值则强制冷却 ColdDownCycles 拍
  localparam int COLD_DOWN_W    = 4;           // log2Up(16)
  localparam logic [COLD_DOWN_W-1:0] COLD_DOWN_THRESHOLD = 4'd12;

  // ---- 11 种 replay cause（优先级 = 编码值，低编码 = 高优先；勿改顺序！）---------
  //  C_MA  : st-ld 违例重执行检查（mem ambiguous，地址未定 store 在前）
  //  C_TM  : tlb miss，等 tlb_hint 回填
  //  C_FF  : store-to-load forward 数据未就绪，等 store data 写入
  //  C_DR  : dcache replay（mshr 等资源回压，可下拍重试）
  //  C_DM  : dcache miss，等 mshr/D-channel refill
  //  C_WF  : way predictor 预测失败（可下拍重试）
  //  C_BC  : dcache bank conflict（可下拍重试）
  //  C_RAR : RAR 队列拒绝（满或年龄不够），等 RAR 有空位
  //  C_RAW : RAW 队列拒绝，等 RAW 有空位 / store 地址就绪
  //  C_NK  : st-ld nuke 违例（确定的 store-load 重叠，需重执行）
  //  C_MF  : misalignBuffer 满（非对齐 load 暂存缓冲满）
  typedef enum logic [3:0] {
    C_MA  = 4'd0,
    C_TM  = 4'd1,
    C_FF  = 4'd2,
    C_DR  = 4'd3,
    C_DM  = 4'd4,
    C_WF  = 4'd5,
    C_BC  = 4'd6,
    C_RAR = 4'd7,
    C_RAW = 4'd8,
    C_NK  = 4'd9,
    C_MF  = 4'd10
  } replay_cause_e;

  // ---- 环形队列指针（{flag,value}，flag 是绕环标志）---------------------------
  typedef struct packed { logic flag; logic [LQ_IDX_W-1:0]  value; } lq_ptr_t;
  typedef struct packed { logic flag; logic [SQ_IDX_W-1:0]  value; } sq_ptr_t;
  typedef struct packed { logic flag; logic [ROB_IDX_W-1:0] value; } rob_ptr_t;

  // isAfter(a, b)：a 在程序序上晚于 b（环形：flag 不同则取反比较）
  //  与 HasCircularQueuePtrHelper.isAfter 一致：differentFlag ^ (a.value > b.value)
  function automatic logic lq_is_after(input lq_ptr_t a, input lq_ptr_t b);
    return (a.flag ^ b.flag) ^ (a.value > b.value);
  endfunction
  function automatic logic sq_is_after(input sq_ptr_t a, input sq_ptr_t b);
    return (a.flag ^ b.flag) ^ (a.value > b.value);
  endfunction

  // robIdx.needFlush(redirect)：被 redirect 刷掉
  //   needFlush = redirect.valid & ( (level & sameRob) | isAfter(rob, redirect.rob) )
  //   isAfter = differentFlag ^ (value > redirect.value)
  function automatic logic rob_need_flush(
      input logic rf, input logic [ROB_IDX_W-1:0] rv,
      input logic redV, input logic redF, input logic [ROB_IDX_W-1:0] redV2,
      input logic redLvl);
    logic isAfter, sameRob;
    isAfter = (rf ^ redF) ^ (rv > redV2);
    sameRob = (rf == redF) & (rv == redV2);
    return redV & ((redLvl & sameRob) | isAfter);
  endfunction

  // UIntToOH：把 7 位下标转 one-hot（72 位）
  function automatic logic [LQ_REPLAY_SIZE-1:0] idx_to_oh(input logic [LQ_IDX_W-1:0] idx);
    logic [LQ_REPLAY_SIZE-1:0] r;
    r = '0;
    if (idx < LQ_REPLAY_SIZE) r[idx] = 1'b1;
    return r;
  endfunction

  // PriorityEncoderOH：返回最低置位的 one-hot（24 位，per-rem 用）
  function automatic logic [REM_SIZE-1:0] prio_oh(input logic [REM_SIZE-1:0] v);
    logic [REM_SIZE-1:0] r;
    logic                found;
    r = '0; found = 1'b0;
    for (int k = 0; k < REM_SIZE; k++)
      if (v[k] & ~found) begin r[k] = 1'b1; found = 1'b1; end
    return r;
  endfunction

  // one-hot(24) → 5 位下标（rem 内位置）
  function automatic logic [REM_IDX_W-1:0] oh_to_idx_rem(input logic [REM_SIZE-1:0] oh);
    logic [REM_IDX_W-1:0] r;
    r = '0;
    for (int k = 0; k < REM_SIZE; k++) if (oh[k]) r = r | k[REM_IDX_W-1:0];
    return r;
  endfunction

  // ---- 入队 uop 元数据（每 entry 保存重放时回填 LoadUnit 所需的字段）------------
  //  golden 已裁剪 difftest/部分 backend 字段；这里保留输出 replay_req 需要的全部。
  typedef struct packed {
    logic [23:0]          exceptionVec;   // 24 位异常向量（按 bit 选择）
    logic                 preDecodeInfo_isRVC;
    logic                 ftqPtr_flag;
    logic [5:0]           ftqPtr_value;
    logic [3:0]           ftqOffset;
    logic [8:0]           fuOpType;
    logic                 rfWen;
    logic                 fpWen;
    logic [7:0]           vpu_vstart;
    logic [1:0]           vpu_veew;
    logic [UOP_IDX_W-1:0] uopIdx;
    logic [7:0]           pdest;
    rob_ptr_t             robIdx;
    logic [63:0]          dbg_enqRsTime;
    logic [63:0]          dbg_selectTime;
    logic [63:0]          dbg_issueTime;
    logic                 storeSetHit;
    logic                 waitForRobIdx_flag;
    logic [7:0]           waitForRobIdx_value;
    logic                 loadWaitBit;
    logic                 loadWaitStrict;
    lq_ptr_t              lqIdx;
    sq_ptr_t              sqIdx;
  } lqr_uop_t;

  // ---- 向量重放信息（重放时回填的 vec 相关字段）-------------------------------
  typedef struct packed {
    logic        isvec;
    logic        isLastElem;
    logic        is128bit;
    logic        uop_unit_stride_fof;
    logic        usSecondInv;
    logic [7:0]  elemIdx;
    logic [2:0]  alignedType;
    logic [3:0]  mbIndex;
    logic [7:0]  elemIdxInsideVd;
    logic [3:0]  reg_offset;
    logic        vecActive;
    logic        is_first_ele;
    logic [15:0] mask;
  } lqr_vec_t;

  // ---- topdown 归约 payload（robHead 最老命中项）-------------------------------
  //  golden ParallelOperation(zip(lq_match_vec, uop_wrapper))：两两归约，
  //   combine(a,b) = { v: a.v|b.v,
  //                    uop: (a.v & b.v) ? (isAfter(a.rob,b.rob)? b : a)
  //                                     : (a.v ? a : (b.v ? b : a)) }
  //   最终取 winner.uop.lqIdx.value 去 index cause 阵列。
  //  归约只需携带 winner 的 robIdx(比较用) 与 lqIdx.value(最终 index cause 用)。
  typedef struct packed {
    logic                 v;       // 该子树有命中
    logic                 robF;    // winner robIdx.flag
    logic [ROB_IDX_W-1:0] robV;    // winner robIdx.value
    logic [LQ_IDX_W-1:0]  lqV;     // winner lqIdx.value（最终 index cause）
  } td_node_t;

  // combine：与 golden Mux 结构逐位一致
  function automatic td_node_t td_merge(input td_node_t a, input td_node_t b);
    logic isAfter;   // a 的 robIdx 是否比 b 更新（更 after）
    isAfter = (a.robF ^ b.robF) ^ (a.robV > b.robV);
    td_merge.v = a.v | b.v;
    if (a.v & b.v) td_merge = isAfter ? '{v:1'b1, robF:b.robF, robV:b.robV, lqV:b.lqV}
                                      : '{v:1'b1, robF:a.robF, robV:a.robV, lqV:a.lqV};
    else if (a.v)  td_merge = '{v:1'b1, robF:a.robF, robV:a.robV, lqV:a.lqV};
    else if (b.v)  td_merge = '{v:1'b1, robF:b.robF, robV:b.robV, lqV:b.lqV};
    else           td_merge = '{v:1'b0, robF:a.robF, robV:a.robV, lqV:a.lqV};
  endfunction

endpackage
