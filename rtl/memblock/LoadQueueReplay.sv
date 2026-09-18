// =============================================================================
//  LoadQueueReplay.sv —— load 重放调度器（G1/kunminghu-v2）
// -----------------------------------------------------------------------------
//  LoadUnit 是流水化的：一条 load 走 s0(发射)→s1(TLB/读 SQ forward)→s2(dcache 命中
//  判定/forward 合并)→s3(写回)。load 经常走不完：TLB miss、dcache miss、要 forward
//  的 store 数据还没写、bank 冲突、RAR/RAW 检查队列满、st-ld 重叠(nuke)……这时
//  LoadUnit 的 s3 把它「踢」到本队列（io.enq，3 路），等 block 条件解除后再选回
//  LoadUnit 重跑（io.replay，3 路）。
//
//  所以本模块 = **带 cause 优先级 + 年龄仲裁的重放调度器**，72 条 entry，非环形，
//  空闲槽由外部 FreeList 管理。
//
//    LoadUnit s3 ──io.enq(3)──▶ [72 entry] ──io.replay(3)──▶ LoadUnit s0
//                                  ▲   ▲   ▲   ▲
//         StoreQueue 就绪向量/指针 ─┘   │   │   └─ TLB hint（tlb miss 回填）
//         DCache D-channel / L2 hint ───┘   └───── RAR/RAW 满标志、robDeqPtr
//    取消源只有 Redirect（清 allocated 并喂回 freelist）。
//
//  ── 文件结构（单文件规范）────────────────────────────────────────────────
//    package loadqueuereplay_pkg   本模块私有类型/参数/纯函数
//    module  xs_LoadQueueReplay_core   可读核（struct 数组 + genvar + enum）
//    module  LoadQueueReplay           wrapper：端口与 golden 逐位同名的扁平 io_*
//
//  机械派生区（uop 字段表 / wrapper 端口表 / wrapper 连线 / topdown 归约树）由
//  scripts/gen_lqreplay.py 从 G1 golden 生成，标在 BEGIN/END GENERATED 之间。
// =============================================================================
// 本文件导航（共 4338 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L24    LoadUnit 是流水化的：一条 load 走 s0(发射)→s1(TLB/读 SQ forward)→s2(dcache 命
//   L468   §0  每 entry 的状态寄存器 + 子模块
//   L581   §1  入队判定
//   L583   needEnqueue : 有效 & 未被 redirect 刷 & 确需重放
//   L637   §2  blocking 解除条件
//   L639   ⚠ 关键微架构语义：Scala 用一串 `when(cause(i)(C_x)){ blocking(i) := ... }`
//   L738   §3  s0 选择
//   L740   选择优先级
//   L855   §4  s1 / s2 流水 + replay_req 组装
//   L857   s1：s0 选出的 one-hot(72) 转 7 位下标，按 s0_can_go 打一拍
//   L1020  §5  entry 寄存器统一更新
//   L1022  优先级
//   L1166  §5-comb  入队各字段的「下一拍值 + 写使能」
//   L1168  ⚠ 多口命中同一 entry 的陷阱：Scala 为每个字段独立生成优先级 mux
//   L1242  §6  topdown
//   L1244  在所有 allocated 且 debug_vaddr == robHeadVaddr 的 entry 里，按 robIdx 归
//   L1423  §7  perf
//   L1488  wrapper：端口与 golden LoadQueueReplay 逐位同名，内部把扁平 io_* 打包给可读核
//

package loadqueuereplay_pkg;

  // ---- 规模/宽度参数（KunminghuV2Config，与 G1 golden 一致）------------------
  localparam int LQ_REPLAY_SIZE = 72;          // LoadQueueReplaySize
  localparam int LD_PIPE_W      = 3;           // LoadPipelineWidth
  localparam int VEC_PIPE_W     = 2;           // VecLoadPipelineWidth
  localparam int ST_PIPE_W      = 2;           // StorePipelineWidth
  localparam int SQ_SIZE        = 56;          // StoreQueueSize（st*ReadyVec 宽度）
  localparam int N_CAUSES       = 11;          // LoadReplayCauses.allCauses

  localparam int LQ_IDX_W       = 7;           // log2Up(72)：LqPtr.value / schedIndex 宽度
  // 运行期 7 位下标的「纯值读」走 128 深折叠视图（见核 §0），故这里要 2^7。
  localparam int LQ_SLOTS       = 1 << LQ_IDX_W;  // 128
  localparam int SQ_IDX_W       = 6;           // SqPtr.value
  localparam int ROB_IDX_W      = 8;           // RobPtr.value
  localparam int VADDR_BITS     = 50;
  localparam int MSHR_ID_W      = 4;           // I/O 端口宽度（mshr_id / tl_d_mshrid / sourceId）
  localparam int TLB_ID_W       = 4;           // I/O 端口宽度（tlb_id / tlb_hint id）
  // ★per-entry 存储寄存器宽度 = 5：Chisel 按 log2Up(nMissEntries+1)=log2Up(17)=5 分配，
  //  而驱动源是 4 位端口零扩展。bit[4] 恒 0，但 golden 在 `==` 比较里**读**它（是个
  //  compare point）。impl 若只存 4 位，golden 的 bit[4] 就成了 unmatched compare_ref。
  localparam int MSHR_ST_W      = 5;
  localparam int TLB_ST_W       = 5;
  localparam int UOP_IDX_W      = 7;

  localparam int REM_SIZE       = LQ_REPLAY_SIZE / LD_PIPE_W;   // 24：每个 AgeDetector 管的条目数
  localparam int REM_IDX_W      = 5;           // log2Up(24)
  localparam int SCHED_IDX_W    = LQ_IDX_W;

  localparam int OLDEST_STRIDE  = 4;           // 程序序年龄选择的窗口（<= load 流水级数）

  // replay 冷却：连续重放同一口超阈值则强制冷却，避免某一口饿死其他口
  localparam int COLD_DOWN_W    = 4;
  localparam logic [COLD_DOWN_W-1:0] COLD_DOWN_THRESHOLD = 4'd12;

  // ---- 11 种 replay cause（编码值即优先级，低编码 = 高优先；★勿改顺序，Scala 源里
  //      有醒目警告：改了可能死锁★）------------------------------------------
  //  C_MA  : st-ld 违例重执行检查（mem ambiguous：地址未定的 store 排在前面）
  //  C_TM  : tlb miss，等 tlb_hint 回填
  //  C_FF  : store→load forward 数据未就绪，等 store data 写入
  //  C_DR  : dcache replay（资源回压，下拍即可重试）
  //  C_DM  : dcache miss，等 MSHR / D-channel refill
  //  C_WF  : way predictor 预测失败（下拍即可重试）
  //  C_BC  : dcache bank conflict（下拍即可重试）
  //  C_RAR : RAR 队列拒绝（满或年龄不够）
  //  C_RAW : RAW 队列拒绝
  //  C_NK  : st-ld nuke 违例（确定的 store-load 重叠，需重执行）
  //  C_MF  : misalign 相关重放；★G1 的解除条件是「robIdx 追上 robDeqPtr」★（见核 §2）
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

  // isAfter(a,b)：a 在程序序上晚于 b。与 HasCircularQueuePtrHelper 一致：
  //   differentFlag ^ (a.value > b.value)
  function automatic logic lq_is_after(input lq_ptr_t a, input lq_ptr_t b);
    return (a.flag ^ b.flag) ^ (a.value > b.value);
  endfunction
  function automatic logic sq_is_after(input sq_ptr_t a, input sq_ptr_t b);
    return (a.flag ^ b.flag) ^ (a.value > b.value);
  endfunction
  function automatic logic rob_is_after(input rob_ptr_t a, input rob_ptr_t b);
    return (a.flag ^ b.flag) ^ (a.value > b.value);
  endfunction

  // robIdx.needFlush(redirect)：被 redirect 冲刷
  //   = redirect.valid & ( (level & 同一条 rob 项) | isAfter(rob, redirect.rob) )
  function automatic logic rob_need_flush(
      input logic rf, input logic [ROB_IDX_W-1:0] rv,
      input logic redV, input logic redF, input logic [ROB_IDX_W-1:0] redRv,
      input logic redLvl);
    logic isAfter, sameRob;
    isAfter = (rf ^ redF) ^ (rv > redRv);
    sameRob = (rf == redF) & (rv == redRv);
    return redV & ((redLvl & sameRob) | isAfter);
  endfunction

  // UIntToOH：7 位下标 → 72 位 one-hot
  function automatic logic [LQ_REPLAY_SIZE-1:0] idx_to_oh(input logic [LQ_IDX_W-1:0] idx);
    logic [LQ_REPLAY_SIZE-1:0] r;
    r = '0;
    if (idx < LQ_REPLAY_SIZE) r[idx] = 1'b1;
    return r;
  endfunction

  // PriorityEncoderOH：最低置位的 one-hot（rem 内 24 位）
  function automatic logic [REM_SIZE-1:0] prio_oh(input logic [REM_SIZE-1:0] v);
    logic [REM_SIZE-1:0] r;
    logic                found;
    r = '0; found = 1'b0;
    for (int k = 0; k < REM_SIZE; k++)
      if (v[k] & ~found) begin r[k] = 1'b1; found = 1'b1; end
    return r;
  endfunction

  // BEGIN GENERATED(uop_fields)
  // golden 逐 entry 存的 exceptionVec 位集合（1=存）。本配置存 bit 0,1,2,3,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23。
  localparam logic [23:0] EXC_KEEP = 24'b111111111111111111101111;

  // ---- 逐 entry 整包存的 uop payload（golden uop_N_<field> 寄存器全集）----
  typedef struct packed {
    logic [31:0]   instr                           ;
    logic [49:0]   pc                              ;
    logic [9:0]    foldpc                          ;
    logic          isFetchMalAddr                  ;
    logic          hasException                    ;
    logic [3:0]    trigger                         ;
    logic          preDecodeInfo_valid             ;
    logic          preDecodeInfo_isRVC             ;
    logic [1:0]    preDecodeInfo_brType            ;
    logic          preDecodeInfo_isCall            ;
    logic          preDecodeInfo_isRet             ;
    logic          pred_taken                      ;
    logic          crossPageIPFFix                 ;
    logic          ftqPtr_flag                     ;
    logic [5:0]    ftqPtr_value                    ;
    logic [3:0]    ftqOffset                       ;
    logic          satpFlushFirstFetchFault        ;
    logic [3:0]    srcType_0                       ;
    logic [3:0]    srcType_1                       ;
    logic [3:0]    srcType_2                       ;
    logic [3:0]    srcType_3                       ;
    logic [3:0]    srcType_4                       ;
    logic [5:0]    ldest                           ;
    logic [34:0]   fuType                          ;
    logic [8:0]    fuOpType                        ;
    logic          rfWen                           ;
    logic          fpWen                           ;
    logic          vecWen                          ;
    logic          v0Wen                           ;
    logic          vlWen                           ;
    logic          isXSTrap                        ;
    logic          waitForward                     ;
    logic          blockBackward                   ;
    logic          canRobCompress                  ;
    logic [3:0]    selImm                          ;
    logic [31:0]   imm                             ;
    logic [1:0]    fpu_typeTagOut                  ;
    logic          fpu_wflags                      ;
    logic [1:0]    fpu_typ                         ;
    logic [1:0]    fpu_fmt                         ;
    logic [2:0]    fpu_rm                          ;
    logic          vpu_vill                        ;
    logic          vpu_vma                         ;
    logic          vpu_vta                         ;
    logic [1:0]    vpu_vsew                        ;
    logic [2:0]    vpu_vlmul                       ;
    logic          vpu_specVill                    ;
    logic          vpu_specVma                     ;
    logic          vpu_specVta                     ;
    logic [1:0]    vpu_specVsew                    ;
    logic [2:0]    vpu_specVlmul                   ;
    logic          vpu_vm                          ;
    logic [7:0]    vpu_vstart                      ;
    logic [2:0]    vpu_frm                         ;
    logic          vpu_fpu_isFpToVecInst           ;
    logic          vpu_fpu_isFP32Instr             ;
    logic          vpu_fpu_isFP64Instr             ;
    logic          vpu_fpu_isReduction             ;
    logic          vpu_fpu_isFoldTo1_2             ;
    logic          vpu_fpu_isFoldTo1_4             ;
    logic          vpu_fpu_isFoldTo1_8             ;
    logic [1:0]    vpu_vxrm                        ;
    logic [6:0]    vpu_vuopIdx                     ;
    logic          vpu_lastUop                     ;
    logic [127:0]  vpu_vmask                       ;
    logic [7:0]    vpu_vl                          ;
    logic [2:0]    vpu_nf                          ;
    logic [1:0]    vpu_veew                        ;
    logic          vpu_isReverse                   ;
    logic          vpu_isExt                       ;
    logic          vpu_isNarrow                    ;
    logic          vpu_isDstMask                   ;
    logic          vpu_isOpMask                    ;
    logic          vpu_isMove                      ;
    logic          vpu_isDependOldVd               ;
    logic          vpu_isWritePartVd               ;
    logic          vpu_isVleff                     ;
    logic          vlsInstr                        ;
    logic          wfflags                         ;
    logic          isMove                          ;
    logic          isDropAmocasSta                 ;
    logic [6:0]    uopIdx                          ;
    logic          isVset                          ;
    logic          firstUop                        ;
    logic          lastUop                         ;
    logic [6:0]    numUops                         ;
    logic [6:0]    numWB                           ;
    logic [2:0]    commitType                      ;
    logic          srcState_0                      ;
    logic          srcState_1                      ;
    logic          srcState_2                      ;
    logic          srcState_3                      ;
    logic          srcState_4                      ;
    logic [1:0]    srcLoadDependency_0_0           ;
    logic [1:0]    srcLoadDependency_0_1           ;
    logic [1:0]    srcLoadDependency_0_2           ;
    logic [1:0]    srcLoadDependency_1_0           ;
    logic [1:0]    srcLoadDependency_1_1           ;
    logic [1:0]    srcLoadDependency_1_2           ;
    logic [1:0]    srcLoadDependency_2_0           ;
    logic [1:0]    srcLoadDependency_2_1           ;
    logic [1:0]    srcLoadDependency_2_2           ;
    logic [1:0]    srcLoadDependency_3_0           ;
    logic [1:0]    srcLoadDependency_3_1           ;
    logic [1:0]    srcLoadDependency_3_2           ;
    logic [1:0]    srcLoadDependency_4_0           ;
    logic [1:0]    srcLoadDependency_4_1           ;
    logic [1:0]    srcLoadDependency_4_2           ;
    logic [7:0]    psrc_0                          ;
    logic [7:0]    psrc_1                          ;
    logic [7:0]    psrc_2                          ;
    logic [7:0]    psrc_3                          ;
    logic [7:0]    psrc_4                          ;
    logic [7:0]    pdest                           ;
    logic          useRegCache_0                   ;
    logic          useRegCache_1                   ;
    logic [4:0]    regCacheIdx_0                   ;
    logic [4:0]    regCacheIdx_1                   ;
    logic          robIdx_flag                     ;
    logic [7:0]    robIdx_value                    ;
    logic [2:0]    instrSize                       ;
    logic          dirtyFs                         ;
    logic          dirtyVs                         ;
    logic [3:0]    traceBlockInPipe_itype          ;
    logic [3:0]    traceBlockInPipe_iretire        ;
    logic          traceBlockInPipe_ilastsize      ;
    logic          eliminatedMove                  ;
    logic          snapshot                        ;
    logic          debugInfo_eliminatedMove        ;
    logic [63:0]   debugInfo_renameTime            ;
    logic [63:0]   debugInfo_dispatchTime          ;
    logic [63:0]   debugInfo_enqRsTime             ;
    logic [63:0]   debugInfo_selectTime            ;
    logic [63:0]   debugInfo_issueTime             ;
    logic [63:0]   debugInfo_writebackTime         ;
    logic [63:0]   debugInfo_runahead_checkpoint_id;
    logic [63:0]   debugInfo_tlbFirstReqTime       ;
    logic [63:0]   debugInfo_tlbRespTime           ;
    logic [55:0]   debug_seqNum_seqNum             ;
    logic [7:0]    debug_seqNum_uopIdx             ;
    logic          storeSetHit                     ;
    logic          waitForRobIdx_flag              ;
    logic [7:0]    waitForRobIdx_value             ;
    logic          loadWaitBit                     ;
    logic [4:0]    ssid                            ;
    logic          lqIdx_flag                      ;
    logic [6:0]    lqIdx_value                     ;
    logic          sqIdx_flag                      ;
    logic [5:0]    sqIdx_value                     ;
    logic          singleStep                      ;
    logic [34:0]   debug_fuType                    ;
    logic          debug_sim_trig                  ;
    logic [4:0]    numLsElem                       ;
  } lqr_uop_pay_t;

  // ---- 入队/重放口上的完整 uop bundle ----
  typedef struct packed {
    // 位号 = 架构异常号，与 golden uop_N_exceptionVec_<b> 逐位同号。
    logic [23:0]   exceptionVec;
    logic          loadWaitStrict                  ;   // 仅入队用，golden 不逐 entry 存、也不从重放口出
    lqr_uop_pay_t  p;
  } lqr_uop_t;
  // END GENERATED

  // ---- 向量重放信息：golden 逐 entry 存的 9 个字段 ----------------------------
  typedef struct packed {
    logic        isvec;
    logic        is128bit;
    logic [7:0]  elemIdx;
    logic [2:0]  alignedType;
    logic [3:0]  mbIndex;
    logic [7:0]  elemIdxInsideVd;
    logic [3:0]  reg_offset;
    logic        vecActive;
    logic [15:0] mask;
  } lqr_vec_t;

  // ---- topdown 归约节点 -------------------------------------------------------
  //  golden: ParallelOperation(zip(lq_match_vec, uop_wrapper), combine) —— **平衡二叉树**
  //  归约（按 size/2 递归切分，不是左结合 fold；平局时两者结果不同）。
  //  combine(a,b) = { v: a.v|b.v,
  //                   uop: (a.v & b.v) ? (isAfter(a.rob, b.rob) ? b : a)
  //                                    : (a.v ? a : (b.v ? b : a)) }
  //  归约只需携带 winner 的 robIdx（比较用）与 lqIdx.value（最终用来 index cause 阵列）。
  typedef struct packed {
    logic                 v;
    logic                 robF;
    logic [ROB_IDX_W-1:0] robV;
    logic [LQ_IDX_W-1:0]  lqV;
  } td_node_t;

  function automatic td_node_t td_merge(input td_node_t a, input td_node_t b);
    logic isAfter;
    isAfter = (a.robF ^ b.robF) ^ (a.robV > b.robV);
    td_merge.v = a.v | b.v;
    if (a.v & b.v) td_merge = isAfter ? '{v:1'b1, robF:b.robF, robV:b.robV, lqV:b.lqV}
                                      : '{v:1'b1, robF:a.robF, robV:a.robV, lqV:a.lqV};
    else if (a.v)  td_merge = '{v:1'b1, robF:a.robF, robV:a.robV, lqV:a.lqV};
    else if (b.v)  td_merge = '{v:1'b1, robF:b.robF, robV:b.robV, lqV:b.lqV};
    else           td_merge = '{v:1'b0, robF:a.robF, robV:a.robV, lqV:a.lqV};
  endfunction

endpackage


// =============================================================================
//  可读核
// =============================================================================
module xs_LoadQueueReplay_core
  import loadqueuereplay_pkg::*;
(
  input  logic clock,
  input  logic reset,

  // 控制：redirect（误预测/异常重定向，取消队列内被刷的 entry）
  input  logic     redirect_valid,
  input  rob_ptr_t redirect_robIdx,
  input  logic     redirect_level,

  // 向量反馈（2 路）：merge buffer 提交/刷新。★本模块解码出来后从不使用★（见 §6）
  input  logic     [VEC_PIPE_W-1:0]                vecFb_valid,
  input  rob_ptr_t [VEC_PIPE_W-1:0]                vecFb_robIdx,
  input  logic     [VEC_PIPE_W-1:0][UOP_IDX_W-1:0] vecFb_uopIdx,
  input  logic     [VEC_PIPE_W-1:0]                vecFb_isCommit,  // feedback_0
  input  logic     [VEC_PIPE_W-1:0]                vecFb_isFlush,   // feedback_1

  // 入队：来自 LoadUnit s3（3 路）
  input  logic     [LD_PIPE_W-1:0]                  enq_valid,
  input  lqr_uop_t [LD_PIPE_W-1:0]                  enq_uop,
  input  lqr_vec_t [LD_PIPE_W-1:0]                  enq_vec,
  input  logic     [LD_PIPE_W-1:0][VADDR_BITS-1:0]  enq_vaddr,
  input  logic     [LD_PIPE_W-1:0]                  enq_isLoadReplay,
  input  logic     [LD_PIPE_W-1:0]                  enq_handledByMSHR,
  input  logic     [LD_PIPE_W-1:0][SCHED_IDX_W-1:0] enq_schedIndex,
  // rep_info：本次重放的原因与附带信息
  input  logic     [LD_PIPE_W-1:0][N_CAUSES-1:0]    enq_cause,
  input  logic     [LD_PIPE_W-1:0][MSHR_ID_W-1:0]   enq_mshr_id,
  input  logic     [LD_PIPE_W-1:0]                  enq_full_fwd,
  input  sq_ptr_t  [LD_PIPE_W-1:0]                  enq_data_inv_sq_idx,
  input  sq_ptr_t  [LD_PIPE_W-1:0]                  enq_addr_inv_sq_idx,
  input  logic     [LD_PIPE_W-1:0]                  enq_last_beat,
  input  logic     [LD_PIPE_W-1:0][TLB_ID_W-1:0]    enq_tlb_id,
  input  logic     [LD_PIPE_W-1:0]                  enq_tlb_full,

  // 来自 STA s1：store 地址执行（解除 C_MA）
  input  logic    [ST_PIPE_W-1:0] staIn_valid,
  input  sq_ptr_t [ST_PIPE_W-1:0] staIn_sqIdx,
  input  logic    [ST_PIPE_W-1:0] staIn_miss,
  // 来自 STD s1：store 数据执行（解除 C_FF）
  input  logic    [ST_PIPE_W-1:0] stdIn_valid,
  input  sq_ptr_t [ST_PIPE_W-1:0] stdIn_sqIdx,

  // 来自 StoreQueue：地址/数据就绪指针 + 就绪向量
  input  sq_ptr_t            stAddrReadySqPtr,
  input  logic [SQ_SIZE-1:0] stAddrReadyVec,
  input  sq_ptr_t            stDataReadySqPtr,
  input  logic [SQ_SIZE-1:0] stDataReadyVec,

  // dcache D-channel refill（唤醒 C_DM）
  input  logic                 tl_d_valid,
  input  logic [MSHR_ID_W-1:0] tl_d_mshrid,

  // 各队列/资源状态
  input  logic     sqEmpty,
  input  lq_ptr_t  ldWbPtr,
  input  rob_ptr_t robDeqPtr,     // ★G1 新增：C_MF 的解除条件用它
  input  logic     rarFull,
  input  logic     rawFull,

  // L2 hint：提前唤醒 dcache miss 的 load
  input  logic                 l2_hint_valid,
  input  logic [MSHR_ID_W-1:0] l2_hint_sourceId,
  input  logic                 l2_hint_isKeyword,

  // tlb hint：tlb miss 回填唤醒
  input  logic                tlb_hint_valid,
  input  logic [TLB_ID_W-1:0] tlb_hint_id,
  input  logic                tlb_hint_replay_all,

  // debug topdown（纯可视化，无功能副作用）
  input  logic                  dtd_robHeadVaddr_valid,
  input  logic [VADDR_BITS-1:0] dtd_robHeadVaddr_bits,
  input  logic                  dtd_robHeadMissInDTlb,
  output logic                  dtd_robHeadTlbReplay,
  output logic                  dtd_robHeadTlbMiss,
  output logic                  dtd_robHeadLoadVio,
  output logic                  dtd_robHeadLoadMSHR,

  // 重放发射（3 路 Decoupled）→ 回 LoadUnit
  output logic     [LD_PIPE_W-1:0]                  replay_valid,
  input  logic     [LD_PIPE_W-1:0]                  replay_ready,
  output lqr_uop_t [LD_PIPE_W-1:0]                  replay_uop,
  output logic     [LD_PIPE_W-1:0][VADDR_BITS-1:0]  replay_vaddr,
  output lqr_vec_t [LD_PIPE_W-1:0]                  replay_vec,
  output logic     [LD_PIPE_W-1:0][MSHR_ID_W-1:0]   replay_mshrid,
  output logic     [LD_PIPE_W-1:0]                  replay_forward_tlDchannel,
  output logic     [LD_PIPE_W-1:0][SCHED_IDX_W-1:0] replay_schedIndex,

  output logic lqFull,          // freelist 空
  output logic replayAllocate,  // ★G1 新增：队列里还有任何 allocated entry

  output logic [5:0] perf_value [13]
);

  // ===========================================================================
  //  §0  每 entry 的状态寄存器 + 子模块
  // ===========================================================================
  typedef struct packed {
    logic allocated;    // 已分配
    logic scheduled;    // 已被选入重放流水（避免重复选）
    logic blocking;     // block 条件未解除（不可重放）
    logic strict;       // C_MA 严格序（loadWaitStrict）
  } entry_ctrl_t;

  // ★阵列按真实深度 72 声明，不补 padding 到 128★：golden 只有 72 条 entry 寄存器；
  //  impl 若声明 128 条，多出的 56 条只在 reset 清 0、运行期永不写读 → FM 判 impl-only
  //  cone-dead 死寄存器（上一轮实测约 4144 点 unread_impl）。
  entry_ctrl_t              ent            [LQ_REPLAY_SIZE];
  logic [N_CAUSES-1:0]      cause          [LQ_REPLAY_SIZE];
  lqr_uop_t                 uop            [LQ_REPLAY_SIZE];
  lqr_vec_t                 vecReplay      [LQ_REPLAY_SIZE];
  sq_ptr_t                  blockSqIdx     [LQ_REPLAY_SIZE];
  logic [MSHR_ST_W-1:0]     missMSHRId     [LQ_REPLAY_SIZE];
  logic [TLB_ST_W-1:0]      tlbHintId      [LQ_REPLAY_SIZE];
  logic                     dataInLastBeat [LQ_REPLAY_SIZE];
  logic [VADDR_BITS-1:0]    debug_vaddr    [LQ_REPLAY_SIZE];

  // ---- 越界折叠读视图 -------------------------------------------------------
  //  golden 用 7 位下标对 Vec(72) 做纯值读取时，firtool 生成 **128 项读表**，
  //  高 56 项（72..127）填的是**条目 0**。运行期下标的纯值读一律走 *R 视图。
  //  （CONVENTIONS 记过：G1 的越界语义是「填第 0 项」，不是回绕；而且同一模块里不同
  //   信号的越界语义可能不同 —— 这里逐个对着 golden 读表核过。）
  lqr_uop_t             uopR        [LQ_SLOTS];
  lqr_vec_t             vecReplayR  [LQ_SLOTS];
  logic [N_CAUSES-1:0]  causeR      [LQ_SLOTS];
  logic [MSHR_ST_W-1:0] missMSHRIdR [LQ_SLOTS];
  always_comb
    for (int k = 0; k < LQ_SLOTS; k++) begin
      uopR[k]        = (k >= LQ_REPLAY_SIZE) ? uop[0]        : uop[k];
      vecReplayR[k]  = (k >= LQ_REPLAY_SIZE) ? vecReplay[0]  : vecReplay[k];
      causeR[k]      = (k >= LQ_REPLAY_SIZE) ? cause[0]      : cause[k];
      missMSHRIdR[k] = (k >= LQ_REPLAY_SIZE) ? missMSHRId[0] : missMSHRId[k];
    end

  // 派生位向量（把 struct 字段摊成 72 位总线，便于做 mask 运算）
  logic [LQ_REPLAY_SIZE-1:0] allocated_v, scheduled_v, blocking_v, dataInLastBeat_v;
  genvar gi;
  generate
    for (gi = 0; gi < LQ_REPLAY_SIZE; gi++) begin : g_statvec
      assign allocated_v[gi]      = ent[gi].allocated;
      assign scheduled_v[gi]      = ent[gi].scheduled;
      assign blocking_v[gi]       = ent[gi].blocking;
      assign dataInLastBeat_v[gi] = dataInLastBeat[gi];
    end
  endgenerate

  assign replayAllocate = |allocated_v;   // ★G1 新增输出

  logic [LQ_REPLAY_SIZE-1:0] freeMaskVec;   // 本拍释放回 freelist 的槽

  // 子模块互联网
  logic [REM_SIZE-1:0]    age_enq [LD_PIPE_W][LD_PIPE_W];  // [rport][enq port]
  logic [REM_SIZE-1:0]    age_deq [LD_PIPE_W];
  logic [REM_SIZE-1:0]    age_ready [LD_PIPE_W];
  logic [REM_SIZE-1:0]    age_out [LD_PIPE_W];
  logic [SCHED_IDX_W-1:0] freeAllocSlot [LD_PIPE_W];
  logic [LD_PIPE_W-1:0]   freeCanAllocate;
  logic                   freeEmpty;
  logic [LD_PIPE_W-1:0]   freeDoAllocate;
  logic [LD_PIPE_W-1:0]                   va_ren, va_wen;
  logic [LD_PIPE_W-1:0][LQ_IDX_W-1:0]     va_raddr, va_waddr;
  logic [LD_PIPE_W-1:0][VADDR_BITS-1:0]   va_rdata, va_wdata;

  // 子模块（黑盒，与 golden 共用同一份定义；UT/FM 两侧相同）
  //  LqVAddrModule : 72 entry 虚地址存储（3 读 3 写）。存外部省寄存器。
  //  FreeList_5    : 空闲槽分配器（72 槽，3 路分配 / 整条 free mask 释放）。
  //  AgeDetector_38: 入队先后年龄矩阵（24 entry、3 enq 口）。3 路重放各一个，
  //                  第 r 个负责 rem=r（即 i%3==r）的 24 条 entry。
  LqVAddrModule vaddrModule (
    .clock (clock), .reset (reset),
    .io_ren_0   (va_ren[0]),   .io_ren_1   (va_ren[1]),   .io_ren_2   (va_ren[2]),
    .io_raddr_0 (va_raddr[0]), .io_raddr_1 (va_raddr[1]), .io_raddr_2 (va_raddr[2]),
    .io_rdata_0 (va_rdata[0]), .io_rdata_1 (va_rdata[1]), .io_rdata_2 (va_rdata[2]),
    .io_wen_0   (va_wen[0]),   .io_wen_1   (va_wen[1]),   .io_wen_2   (va_wen[2]),
    .io_waddr_0 (va_waddr[0]), .io_waddr_1 (va_waddr[1]), .io_waddr_2 (va_waddr[2]),
    .io_wdata_0 (va_wdata[0]), .io_wdata_1 (va_wdata[1]), .io_wdata_2 (va_wdata[2])
  );
  FreeList_5 freeList (
    .clock (clock), .reset (reset),
    .io_allocateSlot_0 (freeAllocSlot[0]),
    .io_allocateSlot_1 (freeAllocSlot[1]),
    .io_allocateSlot_2 (freeAllocSlot[2]),
    .io_canAllocate_0  (freeCanAllocate[0]),
    .io_canAllocate_1  (freeCanAllocate[1]),
    .io_canAllocate_2  (freeCanAllocate[2]),
    .io_doAllocate_0   (freeDoAllocate[0]),
    .io_doAllocate_1   (freeDoAllocate[1]),
    .io_doAllocate_2   (freeDoAllocate[2]),
    .io_free           (freeMaskVec),
    .io_empty          (freeEmpty)
  );
  AgeDetector_38 ageOldest_age (
    .clock (clock), .reset (reset),
    .io_enq_0 (age_enq[0][0]), .io_enq_1 (age_enq[0][1]), .io_enq_2 (age_enq[0][2]),
    .io_deq   (age_deq[0]),    .io_ready (age_ready[0]),  .io_out   (age_out[0])
  );
  AgeDetector_38 ageOldest_age_1 (
    .clock (clock), .reset (reset),
    .io_enq_0 (age_enq[1][0]), .io_enq_1 (age_enq[1][1]), .io_enq_2 (age_enq[1][2]),
    .io_deq   (age_deq[1]),    .io_ready (age_ready[1]),  .io_out   (age_out[1])
  );
  AgeDetector_38 ageOldest_age_2 (
    .clock (clock), .reset (reset),
    .io_enq_0 (age_enq[2][0]), .io_enq_1 (age_enq[2][1]), .io_enq_2 (age_enq[2][2]),
    .io_deq   (age_deq[2]),    .io_ready (age_ready[2]),  .io_out   (age_out[2])
  );

  // ===========================================================================
  //  §1  入队判定
  // ===========================================================================
  //  needEnqueue : 有效 & 未被 redirect 刷 & 确需重放
  //  canFree     : 本来是 isLoadReplay 回流，但不再需要重放 → 释放
  //  newEnqueue  : needEnqueue 且不是 isLoadReplay（首次进队，要分配新槽）
  //
  //  ★G0→G1 的差异之一★：G0 的 needEnqueue 还 AND 了 `~hasExceptions`
  //  （hasExceptions = LduCfg 选出的异常位 orR & ~tlbMiss）。G1 把这一层判断挪到了
  //  上游，于是 io_enq_*_bits_tlbMiss 与 io_enq_*_bits_uop_exceptionVec_4 两组端口
  //  一起消失。这里照 G1 写，**不要**把 G0 的异常门控补回来。
  logic [LD_PIPE_W-1:0] canEnqueue, cancelEnq, needReplay;
  logic [LD_PIPE_W-1:0] loadReplay, needEnqueue, newEnqueue, canFreeVec;
  generate
    for (gi = 0; gi < LD_PIPE_W; gi++) begin : g_enqjudge
      assign canEnqueue[gi]  = enq_valid[gi];
      assign cancelEnq[gi]   = rob_need_flush(enq_uop[gi].p.robIdx_flag, enq_uop[gi].p.robIdx_value,
                                 redirect_valid, redirect_robIdx.flag,
                                 redirect_robIdx.value, redirect_level);
      assign needReplay[gi]  = |enq_cause[gi];
      assign loadReplay[gi]  = enq_isLoadReplay[gi];
      assign needEnqueue[gi] = canEnqueue[gi] & ~cancelEnq[gi] & needReplay[gi];
      assign newEnqueue[gi]  = needEnqueue[gi] & ~enq_isLoadReplay[gi];
      assign canFreeVec[gi]  = canEnqueue[gi] & loadReplay[gi] & ~needReplay[gi];
    end
  endgenerate

  // freelist 分配下标：isLoadReplay 复用原 schedIndex，否则取 freelist 的第 offset 个空槽，
  //  offset = 排在前面的几路里 newEnqueue 的个数。
  logic [SCHED_IDX_W-1:0]    enqIndex   [LD_PIPE_W];
  logic [LQ_REPLAY_SIZE-1:0] enqIndexOH [LD_PIPE_W];
  // 显式 3 选 1，不用动态下标：offset 的类型上界(3)大于数组深度(3)时 Formality 会报
  //  FMR_ELAB-147（它不传播范围保护）。
  function automatic logic [SCHED_IDX_W-1:0] pick_slot(
      input logic [SCHED_IDX_W-1:0] s0, input logic [SCHED_IDX_W-1:0] s1,
      input logic [SCHED_IDX_W-1:0] s2, input logic [1:0] off);
    unique case (off)
      2'd0:    pick_slot = s0;
      2'd1:    pick_slot = s1;
      default: pick_slot = s2;
    endcase
  endfunction
  always_comb begin
    for (int w = 0; w < LD_PIPE_W; w++) begin
      logic [1:0] offset;
      offset = '0;
      for (int k = 0; k < LD_PIPE_W; k++) if (k < w) offset += newEnqueue[k];
      enqIndex[w]       = enq_isLoadReplay[w] ? enq_schedIndex[w]
                        : pick_slot(freeAllocSlot[0], freeAllocSlot[1], freeAllocSlot[2], offset);
      enqIndexOH[w]     = idx_to_oh(enqIndex[w]);
      freeDoAllocate[w] = needEnqueue[w] & ~enq_isLoadReplay[w];
    end
  end

  assign lqFull = freeEmpty;

  // ===========================================================================
  //  §2  blocking 解除条件
  // ===========================================================================
  //  ⚠ 关键微架构语义：Scala 用一串 `when(cause(i)(C_x)){ blocking(i) := ... }`
  //  顺序覆盖同一个寄存器，源码顺序 C_MA→C_TM→C_FF→C_DM→C_RAR→C_RAW→C_MF。
  //  「后写覆盖前写」⇒ 生成的 RTL 是一个**优先级 mux**：编码最高的活跃 cause 说了算。
  //  有效优先级（高→低）：C_MF(10) > C_RAW(8) > C_RAR(7) > C_DM(4) > C_FF(2)
  //                       > C_TM(1) > C_MA(0)。
  //  ★这与「任一 cause 解除即清」不同——必须用 priority，不能用 OR。★
  //  最外层再 AND `~hintWake`：L2 hint 命中则无条件清 blocking（优先级最高）。
  //  C_DR/C_WF/C_BC/C_NK 没有解除分支——它们入队时 blocking 就置 0，下拍即可重放。

  // 按 sqIdx 读 StoreQueue 就绪向量。SQ_SIZE=56 不是 2 的幂，6 位下标可能取到 56..63。
  //  golden 把读端口展开成 64 深读表，越界项（56..63）填**第 0 项**。照抄：
  //  越界返回 0 会让 C_FF/C_MA 的解除晚一拍，造成整条选择流水的相位差。
  function automatic logic sq_vec_read(input logic [SQ_SIZE-1:0] vec, input logic [SQ_IDX_W-1:0] idx);
    logic r;
    r = vec[0];
    for (int k = 0; k < SQ_SIZE; k++) if (idx == k[SQ_IDX_W-1:0]) r = vec[k];
    return r;
  endfunction

  logic [LQ_REPLAY_SIZE-1:0] staInSame, stdInSame, addrNotBlock, dataNotBlock;
  logic [LQ_REPLAY_SIZE-1:0] storeAddrValid, storeDataValid;
  always_comb begin
    for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin
      logic sa, sd;
      sa = 1'b0; sd = 1'b0;
      for (int w = 0; w < ST_PIPE_W; w++) begin
        if (staIn_valid[w] & ~staIn_miss[w] & (blockSqIdx[i] == staIn_sqIdx[w])) sa = 1'b1;
        if (stdIn_valid[w] & (blockSqIdx[i] == stdIn_sqIdx[w]))                  sd = 1'b1;
      end
      staInSame[i]    = sa;
      stdInSame[i]    = sd;
      dataNotBlock[i] = sq_is_after(stDataReadySqPtr, blockSqIdx[i])
                      | sq_vec_read(stDataReadyVec, blockSqIdx[i].value) | sqEmpty;
      addrNotBlock[i] = sq_is_after(stAddrReadySqPtr, blockSqIdx[i])
                      | (~ent[i].strict & sq_vec_read(stAddrReadyVec, blockSqIdx[i].value)) | sqEmpty;
      storeAddrValid[i] = addrNotBlock[i] | staInSame[i];
      storeDataValid[i] = dataNotBlock[i] | stdInSame[i];
    end
  end

  // L2 hint 唤醒 mask（C_DM 且 mshrId 命中 hint 的 sourceId）
  logic [LQ_REPLAY_SIZE-1:0] loadHintWakeMask;
  always_comb
    for (int i = 0; i < LQ_REPLAY_SIZE; i++)
      loadHintWakeMask[i] = ent[i].allocated & ~ent[i].scheduled & cause[i][C_DM]
                          & ent[i].blocking & (missMSHRId[i] == {1'b0, l2_hint_sourceId})
                          & l2_hint_valid;

  // 不入队时下一拍的 blocking 值。
  //  各 cause 的解除条件就地展开成 clr_*：不写成 function 是因为它们要读 entry 数组与
  //  多个模块端口——Formality 对「函数引用非局部信号」报 FMR_VLOG-091 并升级为
  //  elaboration error。就地展开既可读又能过 FM。
  logic [LQ_REPLAY_SIZE-1:0] blkNext;
  always_comb begin
    for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin
      logic b;
      logic clr_MF, clr_RAW, clr_RAR, clr_DM, clr_FF, clr_TM, clr_MA;
      rob_ptr_t entRob;
      entRob  = '{flag: uop[i].p.robIdx_flag, value: uop[i].p.robIdx_value};
      // ★G0→G1 的差异之二★：C_MF 的解除条件整条换了。
      //   G0: ~loadMisalignFull & (misalignAllowSpec | 本项不晚于 ldWbPtr)
      //   G1: 本项的 robIdx **追上 ROB 队头**（即不再晚于 robDeqPtr）才解除。
      //   两个 misalign 端口随之消失、robDeqPtr 端口随之出现。
      clr_MF  = ~rob_is_after(entRob, robDeqPtr);
      clr_RAW = ~rawFull | ~sq_is_after('{flag: uop[i].p.sqIdx_flag, value: uop[i].p.sqIdx_value},
                                        stAddrReadySqPtr);
      clr_RAR = ~rarFull | ~lq_is_after('{flag: uop[i].p.lqIdx_flag, value: uop[i].p.lqIdx_value},
                                        ldWbPtr);
      clr_DM  = tl_d_valid & ({1'b0, tl_d_mshrid} == missMSHRId[i]);
      clr_FF  = ent[i].allocated & storeDataValid[i];
      clr_TM  = tlb_hint_valid & (tlb_hint_replay_all | ({1'b0, tlb_hint_id} == tlbHintId[i]));
      clr_MA  = cause[i][C_MA] & ent[i].allocated & storeAddrValid[i];

      if      (cause[i][C_MF])  b = ~clr_MF  & ent[i].blocking;
      else if (cause[i][C_RAW]) b = ~clr_RAW & ent[i].blocking;
      else if (cause[i][C_RAR]) b = ~clr_RAR & ent[i].blocking;
      else if (cause[i][C_DM])  b = ~clr_DM  & ent[i].blocking;
      else if (cause[i][C_FF])  b = ~clr_FF  & ent[i].blocking;
      else if (cause[i][C_TM])  b = ~clr_TM  & ent[i].blocking;
      else                      b = ~clr_MA  & ent[i].blocking;   // 默认含 C_MA
      blkNext[i] = ~loadHintWakeMask[i] & b;
    end
  end

  // ★G0→G1 的差异之四★：入队侧 C_DM 的 blocking 初值多了一项「**上一拍**的
  //  D-channel 响应也算命中」。golden 为此打了一拍 tl_d_channel。
  //  ★golden 给每个 enq 口各打了一份（blocking_REG/_1、_2/_3、_4/_5，三对同源寄存器
  //   逐位恒等）——这里必须也声明三份。合并成一份在仿真里永远看不出来（值一直相同），
  //   但 FM 会把这一份配给 0 号口，另外两份 globally unmatched，下游跟着成片失配。★
  logic                 tl_d_valid_q  [LD_PIPE_W];
  logic [MSHR_ID_W-1:0] tl_d_mshrid_q [LD_PIPE_W];
  // 无复位寄存器（golden 里这几个在不带 reset 的 always 块中）。
  always_ff @(posedge clock)
    for (int w = 0; w < LD_PIPE_W; w++) begin
      tl_d_valid_q[w]  <= tl_d_valid;
      tl_d_mshrid_q[w] <= tl_d_mshrid;
    end

  // ===========================================================================
  //  §3  s0 选择
  // ===========================================================================
  //  选择优先级（Scala 注释）：
  //    1. L2 hint 唤醒的 load（最高）
  //    2. 高优先 cause（C_DM dcache miss / C_FF forward fail）
  //    3. 低优先 cause（其余）
  //  每个优先级内再按年龄选最老：程序序 oldest（issOldest）优先于入队序 oldest
  //  （ageOldest，AgeDetector 输出）。
  //
  //  rem 交织：72 条 entry 按 i%3 分成 3 组，每组 24 条由一个 AgeDetector 负责。
  //  第 r 路重放只在 rem=r 组里选。
  logic [LQ_REPLAY_SIZE-1:0] hintSelMask;
  logic [LQ_REPLAY_SIZE-1:0] higherPriMask, lowerPriMask, normalSelMask;
  always_comb begin
    for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin
      logic hintBeat;
      // keyword=1 选「数据在最后一拍」的，否则选「不在最后一拍」的
      hintBeat = l2_hint_isKeyword ? dataInLastBeat_v[i] : ~dataInLastBeat_v[i];
      hintSelMask[i]   = loadHintWakeMask[i] & hintBeat;
      higherPriMask[i] = ent[i].allocated & ~ent[i].scheduled & ~ent[i].blocking
                       & (cause[i][C_DM] | cause[i][C_FF]);
      lowerPriMask[i]  = ent[i].allocated & ~ent[i].scheduled & ~ent[i].blocking
                       & ~(cause[i][C_DM] | cause[i][C_FF]);
    end
    normalSelMask = higherPriMask | lowerPriMask | hintSelMask;
  end

  // 本拍 newEnqueue 的 entry 掩码（喂给 AgeDetector 的 enq）
  logic [LQ_REPLAY_SIZE-1:0] loadEnqFireMask [LD_PIPE_W];
  always_comb
    for (int w = 0; w < LD_PIPE_W; w++)
      loadEnqFireMask[w] = newEnqueue[w] ? enqIndexOH[w] : '0;

  // free mask 打一拍（上拍释放的槽从年龄矩阵移除）。★golden 该寄存器复位为 0。★
  logic [LQ_REPLAY_SIZE-1:0] loadFreeSelMask_q;
  always_ff @(posedge clock or posedge reset)
    if (reset) loadFreeSelMask_q <= '0;
    else       loadFreeSelMask_q <= freeMaskVec;

  // 把 72 位总线按 rem 拆成 3×24（rem r 取 bit k*3+r）
  always_comb begin
    for (int r = 0; r < LD_PIPE_W; r++) begin
      logic [REM_SIZE-1:0] hintRem, higherRem, lowerRem;
      logic hintAny, higherAny;
      for (int k = 0; k < REM_SIZE; k++) begin
        int idx;
        idx = k * LD_PIPE_W + r;
        for (int w = 0; w < LD_PIPE_W; w++) age_enq[r][w][k] = loadEnqFireMask[w][idx];
        age_deq[r][k] = loadFreeSelMask_q[idx];
        hintRem[k]    = hintSelMask[idx];
        higherRem[k]  = higherPriMask[idx];
        lowerRem[k]   = lowerPriMask[idx];
      end
      hintAny      = |hintRem;
      higherAny    = |higherRem;
      age_ready[r] = hintAny ? hintRem : (higherAny ? higherRem : lowerRem);
    end
  end

  // ---- 程序序 oldest 匹配（issOldest）----
  //  oldestPtrExt(j) = ldWbPtr + j，j = 0..OLDEST_STRIDE-1。
  //  rem 内：若有 j==0 的匹配（最老），就只取这些；否则取 j>=1 的匹配的并。
  lq_ptr_t oldestPtrExt [OLDEST_STRIDE];
  always_comb
    for (int j = 0; j < OLDEST_STRIDE; j++)
      oldestPtrExt[j] = '{flag:  (({1'b0, ldWbPtr.value} + j) >= LQ_REPLAY_SIZE)
                                 ? ~ldWbPtr.flag : ldWbPtr.flag,
                          value: (ldWbPtr.value + j[LQ_IDX_W-1:0]) % LQ_REPLAY_SIZE};

  logic [REM_SIZE-1:0] remOldestSelVec     [LD_PIPE_W];
  logic [REM_SIZE-1:0] remOldestHintSelVec [LD_PIPE_W];
  always_comb begin
    for (int r = 0; r < LD_PIPE_W; r++) begin
      logic [REM_SIZE-1:0] oldset, olderOr, hintRem;
      logic anyOldset;
      for (int k = 0; k < REM_SIZE; k++) begin
        int idx;
        logic m0, mOlder;
        lq_ptr_t entLq;
        idx    = k * LD_PIPE_W + r;
        entLq  = '{flag: uop[idx].p.lqIdx_flag, value: uop[idx].p.lqIdx_value};
        m0     = normalSelMask[idx] & (entLq == oldestPtrExt[0]);
        mOlder = 1'b0;
        for (int j = 1; j < OLDEST_STRIDE; j++)
          if (normalSelMask[idx] & (entLq == oldestPtrExt[j])) mOlder = 1'b1;
        oldset[k]  = m0;
        olderOr[k] = mOlder;
        hintRem[k] = hintSelMask[idx];
      end
      anyOldset = |oldset;
      for (int k = 0; k < REM_SIZE; k++)
        remOldestSelVec[r][k] = anyOldset ? oldset[k] : olderOr[k];
      remOldestHintSelVec[r] = remOldestSelVec[r] & hintRem;
    end
  end

  // 每路 s0 选择：合并 issOldest（程序序）与 ageOldest（入队序）
  logic [LQ_REPLAY_SIZE-1:0] s0_oldestSel_bits [LD_PIPE_W];
  logic [LD_PIPE_W-1:0]      s0_oldestSel_valid;
  always_comb begin
    for (int r = 0; r < LD_PIPE_W; r++) begin
      logic [REM_SIZE-1:0] issIndexOH, ageIndexOH, oldestSelRem;
      logic l2HintFirst, issOldestValid, ageValid;
      l2HintFirst    = l2_hint_valid & (|remOldestHintSelVec[r]);
      issOldestValid = l2HintFirst | (|remOldestSelVec[r]);
      ageIndexOH     = age_out[r];
      ageValid       = |age_out[r];
      issIndexOH     = l2HintFirst ? prio_oh(remOldestHintSelVec[r]) : prio_oh(remOldestSelVec[r]);
      oldestSelRem   = issOldestValid ? issIndexOH : ageIndexOH;
      s0_oldestSel_bits[r] = '0;
      for (int k = 0; k < REM_SIZE; k++)
        s0_oldestSel_bits[r][k * LD_PIPE_W + r] = oldestSelRem[k];
      s0_oldestSel_valid[r] = ageValid | issOldestValid;
    end
  end

  // ===========================================================================
  //  §4  s1 / s2 流水 + replay_req 组装
  // ===========================================================================
  //  s1：s0 选出的 one-hot(72) 转 7 位下标，按 s0_can_go 打一拍。命中则置 scheduled。
  //  s2：再打一拍，读出 vaddr/uop/cause 组装成 replay_req 发回 LoadUnit；被 redirect
  //      刷则取消。还有「冷却」：连续重放同一口超阈值就强制冷却，避免饿死其他口。
  function automatic logic [LQ_IDX_W-1:0] oh72_to_idx(input logic [LQ_REPLAY_SIZE-1:0] oh);
    logic [LQ_IDX_W-1:0] r;
    r = '0;
    for (int k = 0; k < LQ_REPLAY_SIZE; k++) if (oh[k]) r = r | k[LQ_IDX_W-1:0];
    return r;
  endfunction

  logic [LD_PIPE_W-1:0]               s1_oldestSel_valid_q, s2_oldestSel_valid_q;
  logic [LD_PIPE_W-1:0][LQ_IDX_W-1:0] s1_oldestSel_bits_q, s2_oldestSel_bits_q;
  logic [LD_PIPE_W-1:0]               s1_can_go, s2_cancelReplay;
  logic [COLD_DOWN_W-1:0]             coldCounter [LD_PIPE_W];

  // s2 锁存的 replay payload
  lqr_uop_t             s2_uop_q   [LD_PIPE_W];
  lqr_vec_t             s2_vec_q   [LD_PIPE_W];
  logic [MSHR_ST_W-1:0] s2_mshr_q  [LD_PIPE_W];
  logic [N_CAUSES-1:0]  s2_cause_q [LD_PIPE_W];

  // redirect 打一拍：cancel 判定要拿**当前拍和上一拍**的 redirect 各判一次。
  // ★golden 为此打了 6 份同源副本：s0_can_go_REG{,_1,_2}（喂 s0_can_go 那条锥）
  //  与 s1_cancel_REG{,_1,_2}（喂 s1_cancel 那条锥），每路各一份，六份逐位恒等。
  //  可读核**必须照样声明 6 份**：合并成 1 份在仿真里永远看不出来（值一直相同），
  //  但 FM 只会把这 1 份配给其中一个 golden 副本，另外 5 份 globally unmatched，
  //  而未配对的比较点是自由割点 —— 它不只是自己不被证，还会让下游整条锥跟着失配。
  //  ★本轮实测：先按「合并成一份」写，FM match 报 55 个 unmatched（5 副本 ×11 位），
  //   全在 reference 侧、impl 侧 0 个。这就是 CONVENTIONS「一份都不许少」的原样复现。★
  typedef struct packed {
    logic     valid;
    rob_ptr_t robIdx;
    logic     level;
  } redirect_q_t;
  redirect_q_t red_q_s0 [LD_PIPE_W];   // golden s0_can_go_REG{,_1,_2}
  redirect_q_t red_q_s1 [LD_PIPE_W];   // golden s1_cancel_REG{,_1,_2}
  always_ff @(posedge clock)
    for (int i = 0; i < LD_PIPE_W; i++) begin
      red_q_s0[i] <= '{valid: redirect_valid, robIdx: redirect_robIdx, level: redirect_level};
      red_q_s1[i] <= '{valid: redirect_valid, robIdx: redirect_robIdx, level: redirect_level};
    end

  logic [LD_PIPE_W-1:0] replay_fire;
  assign replay_fire = replay_valid & replay_ready;

  // ★golden 直接读 uopR[s1_bits]，**不带 s1_oldestSel_valid 门控**。
  //  加一层 `valid ? uopR[bits] : uop[0]` 会把 s1_oldestSel_valid_q 引进
  //  s0_can_go / scheduled / s1_oldestSel 的次态锥，与 golden 分叉。★
  //  s0 与 s1 两条锥各算一次「s1 项被刷」，用**各自那份**打拍寄存器（见上）。
  //  两者函数相同、值也相同，但结构上是 golden 的两套，不合并。
  logic [LD_PIPE_W-1:0] s0_cancel, s1_cancel;
  always_comb begin
    for (int i = 0; i < LD_PIPE_W; i++) begin
      lqr_uop_t u;
      logic fnow, f_s0, f_s1;
      u    = uopR[s1_oldestSel_bits_q[i]];
      fnow = rob_need_flush(u.p.robIdx_flag, u.p.robIdx_value, redirect_valid,
                            redirect_robIdx.flag, redirect_robIdx.value, redirect_level);
      f_s0 = rob_need_flush(u.p.robIdx_flag, u.p.robIdx_value, red_q_s0[i].valid,
                            red_q_s0[i].robIdx.flag, red_q_s0[i].robIdx.value, red_q_s0[i].level);
      f_s1 = rob_need_flush(u.p.robIdx_flag, u.p.robIdx_value, red_q_s1[i].valid,
                            red_q_s1[i].robIdx.flag, red_q_s1[i].robIdx.value, red_q_s1[i].level);
      s0_cancel[i] = fnow | f_s0;
      s1_cancel[i] = fnow | f_s1;
    end
  end

  logic [LD_PIPE_W-1:0] s0_can_go;
  always_comb begin
    for (int i = 0; i < LD_PIPE_W; i++) begin
      logic canFire;
      canFire      = coldCounter[i] < COLD_DOWN_THRESHOLD;   // replayCanFire
      s1_can_go[i] = (canFire & (~s2_oldestSel_valid_q[i] | replay_fire[i])) | s2_cancelReplay[i];
      s0_can_go[i] = s1_can_go[i] | s0_cancel[i];
    end
  end

  always_comb
    for (int i = 0; i < LD_PIPE_W; i++) begin
      va_ren[i]   = s1_oldestSel_valid_q[i] & s1_can_go[i];
      va_raddr[i] = s1_oldestSel_bits_q[i];
    end

  // ★golden 只复位 s1_oldestSel_valid_r；s1_oldestSel_bits_r 无复位。★
  always_ff @(posedge clock or posedge reset) begin
    if (reset) s1_oldestSel_valid_q <= '0;
    else
      for (int i = 0; i < LD_PIPE_W; i++)
        if (s0_can_go[i]) s1_oldestSel_valid_q[i] <= s0_oldestSel_valid[i];
  end
  always_ff @(posedge clock)
    for (int i = 0; i < LD_PIPE_W; i++)
      if (s0_can_go[i]) s1_oldestSel_bits_q[i] <= oh72_to_idx(s0_oldestSel_bits[i]);

  // ★同样只复位 s2_oldestSel_valid_r；bits 与全部 payload 无复位。★
  always_ff @(posedge clock or posedge reset) begin
    if (reset) s2_oldestSel_valid_q <= '0;
    else
      // ★不在 always_ff 体内声明组合临时量：FM 前端会把每路迭代各推成一个死寄存器。★
      for (int i = 0; i < LD_PIPE_W; i++)
        if (s1_can_go[i] | replay_fire[i])
          s2_oldestSel_valid_q[i] <= s1_can_go[i] ? (s1_oldestSel_valid_q[i] & ~s1_cancel[i]) : 1'b0;
  end

  // s2 读源在 always_comb 里算好（同上：always_ff 里不放 struct 临时量）
  lqr_uop_t s2_uop_in [LD_PIPE_W];
  lqr_vec_t s2_vec_in [LD_PIPE_W];
  always_comb
    for (int i = 0; i < LD_PIPE_W; i++) begin
      s2_uop_in[i] = uopR[s1_oldestSel_bits_q[i]];
      s2_vec_in[i] = vecReplayR[s1_oldestSel_bits_q[i]];
    end

  always_ff @(posedge clock)
    for (int i = 0; i < LD_PIPE_W; i++)
      if (s1_can_go[i]) begin
        s2_oldestSel_bits_q[i] <= s1_oldestSel_bits_q[i];
        // exceptionVec 逐位按 EXC_KEEP 存；lqr_uop_pay_t 整包存；loadWaitStrict 不驱动
        for (int b = 0; b < 24; b++)
          if (EXC_KEEP[b]) s2_uop_q[i].exceptionVec[b] <= s2_uop_in[i].exceptionVec[b];
        s2_uop_q[i].p  <= s2_uop_in[i].p;
        s2_vec_q[i]    <= s2_vec_in[i];
        s2_mshr_q[i]   <= missMSHRIdR[s1_oldestSel_bits_q[i]];
        s2_cause_q[i]  <= causeR[s1_oldestSel_bits_q[i]];
      end

  always_comb
    for (int i = 0; i < LD_PIPE_W; i++)
      s2_cancelReplay[i] = rob_need_flush(s2_uop_q[i].p.robIdx_flag, s2_uop_q[i].p.robIdx_value,
                             redirect_valid, redirect_robIdx.flag,
                             redirect_robIdx.value, redirect_level);

  // ---- replay_req 组装 ----
  //  ★G1 的 replay uop 是**纯直通**：176 个字段全部 = s2_replayUop_<f>，没有任何
  //   出口改写（G0 曾把 exceptionVec[5] 钉 0）。照 G1 写。★
  always_comb
    for (int i = 0; i < LD_PIPE_W; i++) begin
      replay_valid[i]                = s2_oldestSel_valid_q[i];
      replay_uop[i].exceptionVec     = s2_uop_q[i].exceptionVec;
      replay_uop[i].p                = s2_uop_q[i].p;
      // replay_uop[i].loadWaitStrict 不驱动：golden 的重放口没有这个字段
      replay_vec[i]                  = s2_vec_q[i];
      replay_vaddr[i]                = va_rdata[i];
      replay_mshrid[i]               = s2_mshr_q[i][MSHR_ID_W-1:0];  // bit[4] 恒 0
      replay_forward_tlDchannel[i]   = s2_cause_q[i][C_DM];
      replay_schedIndex[i]           = s2_oldestSel_bits_q[i];
    end

  // ---- 冷却计数器 ----
  //  本拍 fire 且上拍也 fire（连发同一口）→ +1；否则若已在冷却区 → 继续 +1（到溢出
  //  回绕清 0）；否则清 0。
  logic [LD_PIPE_W-1:0] lastReplay_q;
  always_ff @(posedge clock) lastReplay_q <= replay_fire;   // 无复位（同 golden）
  always_ff @(posedge clock or posedge reset) begin
    if (reset) for (int i = 0; i < LD_PIPE_W; i++) coldCounter[i] <= '0;
    else for (int i = 0; i < LD_PIPE_W; i++) begin
      if (lastReplay_q[i] & replay_fire[i])           coldCounter[i] <= coldCounter[i] + 1'b1;
      else if (coldCounter[i] >= COLD_DOWN_THRESHOLD) coldCounter[i] <= coldCounter[i] + 1'b1;
      else                                            coldCounter[i] <= '0;
    end
  end

  // ===========================================================================
  //  §5  entry 寄存器统一更新
  // ===========================================================================
  //  优先级（与 Scala 的 when 顺序一致，后写覆盖前写）：
  //   (2) blocking 取 §2 的解除结果
  //   (3) s0 选中 → scheduled := 1
  //   (4) 入队写入 → allocated/scheduled/blocking/cause/uop/...
  //   (5) isLoadReplay 回流且不再需重放 → allocated := 0 并释放；否则 scheduled := 0
  //   (6) redirect 取消 → allocated := 0 并释放（最高优先）
  logic [LQ_REPLAY_SIZE-1:0] s0_setScheduled;
  always_comb begin
    s0_setScheduled = '0;
    for (int r = 0; r < LD_PIPE_W; r++)
      if (s0_can_go[r] & s0_oldestSel_valid[r]) s0_setScheduled |= s0_oldestSel_bits[r];
  end

  always_comb
    for (int w = 0; w < LD_PIPE_W; w++) begin
      va_wen[w]   = needEnqueue[w];   // isLoadReplay 也照样重写
      va_waddr[w] = enqIndex[w];
      va_wdata[w] = enq_vaddr[w];
    end

  // needCancel：被 redirect 刷掉的 allocated entry
  //  vecLdCancel/vecLdCommit：golden 也算了，但**算完从不使用**——vec flush 不清本队列。
  //  照抄（不补、不删）。
  logic [LQ_REPLAY_SIZE-1:0] needCancel, vecLdCancel, vecLdCommit;
  always_comb
    for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin
      logic vc, vm;
      rob_ptr_t entRob;
      entRob        = '{flag: uop[i].p.robIdx_flag, value: uop[i].p.robIdx_value};
      needCancel[i] = ent[i].allocated
                    & rob_need_flush(entRob.flag, entRob.value, redirect_valid,
                                     redirect_robIdx.flag, redirect_robIdx.value, redirect_level);
      vc = 1'b0; vm = 1'b0;
      for (int j = 0; j < VEC_PIPE_W; j++) begin
        if (ent[i].allocated & vecFb_valid[j] & vecFb_isFlush[j]
            & (entRob == vecFb_robIdx[j]) & (uop[i].p.uopIdx == vecFb_uopIdx[j])) vc = 1'b1;
        if (ent[i].allocated & vecFb_valid[j] & vecFb_isCommit[j]
            & (entRob == vecFb_robIdx[j]) & (uop[i].p.uopIdx == vecFb_uopIdx[j])) vm = 1'b1;
      end
      vecLdCancel[i] = vc;
      vecLdCommit[i] = vm;
    end

  // ---- uop / vecReplay / blockSqIdx：golden 为**无复位**寄存器 ----
  //  必须和下面 reset 门控的块分开：否则复位期间的入队写会被吞掉，与 golden 分叉。
  //  ★不能写成 `always_ff @(posedge clock or posedge reset)` 而块首不是 if(reset)——
  //   FM 阅读器 FMR_VLOG-144 会拒绝，impl 直接 elaborate 不了。★
  logic     entry_ne_v   [LQ_REPLAY_SIZE];
  lqr_uop_t entry_ne_uop [LQ_REPLAY_SIZE];
  lqr_vec_t entry_ne_vec [LQ_REPLAY_SIZE];
  logic     entry_bsq_v  [LQ_REPLAY_SIZE];
  sq_ptr_t  entry_bsq    [LQ_REPLAY_SIZE];
  always_comb
    for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin
      entry_ne_v[i] = 1'b0; entry_ne_uop[i] = '0; entry_ne_vec[i] = '0;
      entry_bsq_v[i] = 1'b0; entry_bsq[i] = '0;
      for (int w = 0; w < LD_PIPE_W; w++)
        if (needEnqueue[w] & (enqIndex[w] == i[SCHED_IDX_W-1:0])) begin
          entry_ne_v[i]   = 1'b1;
          entry_ne_uop[i] = enq_uop[w];
          entry_ne_vec[i] = enq_vec[w];
          if (enq_cause[w][C_MA]) begin entry_bsq_v[i] = 1'b1; entry_bsq[i] = enq_addr_inv_sq_idx[w]; end
          if (enq_cause[w][C_FF]) begin entry_bsq_v[i] = 1'b1; entry_bsq[i] = enq_data_inv_sq_idx[w]; end
        end
    end

  always_ff @(posedge clock)
    for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin
      if (entry_ne_v[i]) begin
        // ★G0→G1 的差异之六★：入队时 **把 exceptionVec 清 0**，而不是存入队值。
        //  G0 是 `uop_N_exceptionVec_K <= io_enq_W_bits_uop_exceptionVec_K`（直存）；
        //  G1 是 `<= ~C & (C ? io_enq_W_… : 保持)`，其中 C = 「本口写的就是第 i 条」——
        //  这个式子在 C=1 时恒为 0，C=0 时保持旧值，所以**只要本口写这条 entry，
        //  这些位就是 0**，入队端口上的值一次也进不去。
        //  （对应的 Chisel 改动应与差异之三同源：异常处理移到了上游，重放项不再
        //   携带旧的异常向量。）入队端口 io_enq_*_uop_exceptionVec_* 因此在 golden 里
        //   也只是挂在一个永远选不中的 mux 支路上 —— 端口留着，值到不了寄存器。
        //  ★这一条 G1 golden 的具名 wire / 寄存器根都看不出来（全在 _GEN_ 里），
        //   是 UT 逐拍比对抓出来的。★
        for (int b = 0; b < 24; b++)
          if (EXC_KEEP[b]) uop[i].exceptionVec[b] <= 1'b0;
        uop[i].p     <= entry_ne_uop[i].p;
        // uop[i].loadWaitStrict 不驱动：golden 不逐 entry 存它（入队算完 strict 就丢）
        vecReplay[i] <= entry_ne_vec[i];
      end
      if (entry_bsq_v[i]) blockSqIdx[i] <= entry_bsq[i];
    end

  // §5-comb 的结果（声明须在下面 always_ff 之前）
  logic                  entry_wr_hasNE         [LQ_REPLAY_SIZE];
  logic [N_CAUSES-1:0]   entry_wr_cause         [LQ_REPLAY_SIZE];
  logic [VADDR_BITS-1:0] entry_wr_vaddr         [LQ_REPLAY_SIZE];
  logic                  entry_wr_dilb          [LQ_REPLAY_SIZE];
  logic                  entry_wr_blk           [LQ_REPLAY_SIZE];
  logic                  entry_wr_strict        [LQ_REPLAY_SIZE];
  logic                  entry_wr_hasMSHR       [LQ_REPLAY_SIZE];
  logic [MSHR_ST_W-1:0]  entry_wr_mshr          [LQ_REPLAY_SIZE];
  logic                  entry_wr_hasTLB        [LQ_REPLAY_SIZE];
  logic [TLB_ST_W-1:0]   entry_wr_tlb           [LQ_REPLAY_SIZE];
  logic                  entry_wr_alloc_touched [LQ_REPLAY_SIZE];
  logic                  entry_wr_alloc_n       [LQ_REPLAY_SIZE];
  logic                  entry_wr_sched_clr     [LQ_REPLAY_SIZE];

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      // allocated/scheduled/blocking/strict/cause/missMSHRId/tlbHintId/dataInLastBeat/
      // debug_vaddr 都是 RegInit(0)，逐条清零（深度就是真实的 72，没有 padding 死槽）。
      for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin
        ent[i].allocated  <= 1'b0;
        ent[i].scheduled  <= 1'b0;
        ent[i].blocking   <= 1'b0;
        ent[i].strict     <= 1'b0;
        cause[i]          <= '0;
        missMSHRId[i]     <= '0;
        tlbHintId[i]      <= '0;
        dataInLastBeat[i] <= 1'b0;
        debug_vaddr[i]    <= '0;
      end
    end else begin
      for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin
        ent[i].blocking <= blkNext[i];                       // (2)
        if (s0_setScheduled[i]) ent[i].scheduled <= 1'b1;    // (3)
      end
      for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin         // (4)
        if (entry_wr_hasNE[i]) begin
          cause[i]          <= entry_wr_cause[i];
          debug_vaddr[i]    <= entry_wr_vaddr[i];
          dataInLastBeat[i] <= entry_wr_dilb[i];
          ent[i].blocking   <= entry_wr_blk[i];
          ent[i].strict     <= entry_wr_strict[i];
        end
        if (entry_wr_hasMSHR[i]) missMSHRId[i] <= entry_wr_mshr[i];
        if (entry_wr_hasTLB[i])  tlbHintId[i]  <= entry_wr_tlb[i];
      end
      for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin         // (4b)/(5)
        if (entry_wr_alloc_touched[i]) ent[i].allocated <= entry_wr_alloc_n[i];
        if (entry_wr_sched_clr[i])     ent[i].scheduled <= 1'b0;
      end
      for (int i = 0; i < LQ_REPLAY_SIZE; i++)               // (6) 最高优先
        if (needCancel[i]) ent[i].allocated <= 1'b0;
    end
  end

  // ---------------------------------------------------------------------------
  //  §5-comb  入队各字段的「下一拍值 + 写使能」
  // ---------------------------------------------------------------------------
  //  ⚠ 多口命中同一 entry 的陷阱：Scala 为每个字段独立生成优先级 mux（口 2 > 口 1 > 口 0，
  //   即 zipWithIndex 的后写覆盖），而**各字段的写门控并不相同**：
  //     · allocated/scheduled/uop/vec/cause/debug_vaddr/dataInLastBeat/blocking/strict
  //       门控 = needEnqueue[w]
  //     · missMSHRId 门控 = needEnqueue[w] & handledByMSHR[w]
  //     · tlbHintId  门控 = needEnqueue[w] & cause[w][C_TM]
  //   若把所有字段塞进同一个「按口 last-wins」循环，高编号口的"保持"会把低编号口对
  //   **它本不写的字段**的写覆盖掉。故逐字段按各自门控求最高优先口。
  always_comb begin
    for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin
      entry_wr_hasNE[i] = 1'b0; entry_wr_hasMSHR[i] = 1'b0; entry_wr_hasTLB[i] = 1'b0;
      entry_wr_cause[i] = '0;   entry_wr_vaddr[i]   = '0;   entry_wr_dilb[i]   = 1'b0;
      entry_wr_blk[i]   = 1'b0; entry_wr_strict[i]  = 1'b0;
      entry_wr_mshr[i]  = '0;   entry_wr_tlb[i]     = '0;
      entry_wr_alloc_touched[i] = 1'b0;
      entry_wr_alloc_n[i]       = 1'bx;
      entry_wr_sched_clr[i]     = 1'b0;
      for (int w = 0; w < LD_PIPE_W; w++) begin
        logic hit;
        logic [N_CAUSES-1:0] cw;
        hit = needEnqueue[w] & (enqIndex[w] == i[SCHED_IDX_W-1:0]);
        cw  = enq_cause[w];
        if (hit) begin
          entry_wr_hasNE[i] = 1'b1;
          entry_wr_cause[i] = cw;
          entry_wr_vaddr[i] = enq_vaddr[w];
          entry_wr_dilb[i]  = enq_last_beat[w];
          // blocking 初值：默认 1；C_BC/C_NK/C_DR/C_WF 下拍即可重放 → 0；C_TM/C_DM 特判
          entry_wr_blk[i] = 1'b1;
          if (cw[C_BC] | cw[C_NK] | cw[C_DR] | cw[C_WF]) entry_wr_blk[i] = 1'b0;
          if (cw[C_TM])
            entry_wr_blk[i] = ~enq_tlb_full[w]
                            & ~(tlb_hint_valid & ((tlb_hint_id == enq_tlb_id[w]) | tlb_hint_replay_all));
          // ★G1：除了本拍的 D-channel，还要看**上一拍**的（tl_d_*_q，逐口各一份）★
          if (cw[C_DM] & enq_handledByMSHR[w])
            entry_wr_blk[i] = ~enq_full_fwd[w]
                            & ~(tl_d_valid      & (tl_d_mshrid      == enq_mshr_id[w]))
                            & ~(tl_d_valid_q[w] & (tl_d_mshrid_q[w] == enq_mshr_id[w]));
          entry_wr_strict[i] = cw[C_MA] ? enq_uop[w].loadWaitStrict : 1'b0;
          if (enq_handledByMSHR[w]) begin
            entry_wr_hasMSHR[i] = 1'b1; entry_wr_mshr[i] = {1'b0, enq_mshr_id[w]};
          end
          if (cw[C_TM]) begin
            entry_wr_hasTLB[i] = 1'b1;  entry_wr_tlb[i]  = {1'b0, enq_tlb_id[w]};
          end
          entry_wr_alloc_n[i] = 1'b1; entry_wr_alloc_touched[i] = 1'b1;
          entry_wr_sched_clr[i] = 1'b1;
        end
        // isLoadReplay 回流。⚠ Scala 把「入队置位」与「回流释放」放在**同一个**
        //  for((enq,w)) 循环体里（入队在前、回流在后），真实先后是
        //  w=0:{enq,replay}, w=1:{enq,replay}, … 绝不能拆成「先所有 enq 再所有 replay」，
        //  否则低口的 replay-free 会误覆盖高口的 enq-set。
        if (enq_valid[w] & enq_isLoadReplay[w] & (enq_schedIndex[w] == i[SCHED_IDX_W-1:0])) begin
          if (~needReplay[w]) begin
            entry_wr_alloc_n[i] = 1'b0; entry_wr_alloc_touched[i] = 1'b1;
          end else begin
            entry_wr_sched_clr[i] = 1'b1;
          end
        end
      end
    end
  end

  // ---- freeMaskVec：本拍释放回 freelist 的槽 ----
  always_comb begin
    freeMaskVec = '0;
    for (int i = 0; i < LQ_REPLAY_SIZE; i++)
      if (needCancel[i]) freeMaskVec[i] = 1'b1;
    for (int w = 0; w < LD_PIPE_W; w++)
      if (enq_valid[w] & enq_isLoadReplay[w] & ~needReplay[w])
        freeMaskVec[enq_schedIndex[w]] = 1'b1;
  end

  // ===========================================================================
  //  §6  topdown（纯调试可视化）
  // ===========================================================================
  //  在所有 allocated 且 debug_vaddr == robHeadVaddr 的 entry 里，按 robIdx 归约出
  //  程序序最老者，用它的 cause 点亮各 topdown 信号。
  //  ★三处易错（上一轮都踩过）：(a) 比较键是 robIdx 不是 lqIdx；(b) 最终用
  //   winner.lqIdx.value 去 index cause 阵列，不是用 entry 下标；(c) 归约树是
  //   ParallelOperation 的平衡树，不是左结合 fold（平局时结果不同）。★
  logic [LQ_REPLAY_SIZE-1:0] lqMatchVec;
  always_comb
    for (int i = 0; i < LQ_REPLAY_SIZE; i++)
      lqMatchVec[i] = ent[i].allocated & (debug_vaddr[i] == dtd_robHeadVaddr_bits);

  td_node_t td_leaf [LQ_REPLAY_SIZE];
  always_comb
    for (int i = 0; i < LQ_REPLAY_SIZE; i++)
      td_leaf[i] = '{v:    lqMatchVec[i],
                     robF: uop[i].p.robIdx_flag,
                     robV: uop[i].p.robIdx_value,
                     lqV:  uop[i].p.lqIdx_value};

  td_node_t td_n [143];   // 72 叶 + 71 次 merge，根 = td_n[142]
  always_comb begin
    // BEGIN GENERATED(td_tree)
    // 平衡树共 143 个节点（72 叶 + 71 次 merge），根 = td_n[142]
    td_n[0] = td_leaf[0];
    td_n[1] = td_leaf[1];
    td_n[2] = td_merge(td_n[0], td_n[1]);
    td_n[3] = td_leaf[2];
    td_n[4] = td_leaf[3];
    td_n[5] = td_merge(td_n[3], td_n[4]);
    td_n[6] = td_merge(td_n[2], td_n[5]);
    td_n[7] = td_leaf[4];
    td_n[8] = td_leaf[5];
    td_n[9] = td_merge(td_n[7], td_n[8]);
    td_n[10] = td_leaf[6];
    td_n[11] = td_leaf[7];
    td_n[12] = td_leaf[8];
    td_n[13] = td_merge(td_n[11], td_n[12]);
    td_n[14] = td_merge(td_n[10], td_n[13]);
    td_n[15] = td_merge(td_n[9], td_n[14]);
    td_n[16] = td_merge(td_n[6], td_n[15]);
    td_n[17] = td_leaf[9];
    td_n[18] = td_leaf[10];
    td_n[19] = td_merge(td_n[17], td_n[18]);
    td_n[20] = td_leaf[11];
    td_n[21] = td_leaf[12];
    td_n[22] = td_merge(td_n[20], td_n[21]);
    td_n[23] = td_merge(td_n[19], td_n[22]);
    td_n[24] = td_leaf[13];
    td_n[25] = td_leaf[14];
    td_n[26] = td_merge(td_n[24], td_n[25]);
    td_n[27] = td_leaf[15];
    td_n[28] = td_leaf[16];
    td_n[29] = td_leaf[17];
    td_n[30] = td_merge(td_n[28], td_n[29]);
    td_n[31] = td_merge(td_n[27], td_n[30]);
    td_n[32] = td_merge(td_n[26], td_n[31]);
    td_n[33] = td_merge(td_n[23], td_n[32]);
    td_n[34] = td_merge(td_n[16], td_n[33]);
    td_n[35] = td_leaf[18];
    td_n[36] = td_leaf[19];
    td_n[37] = td_merge(td_n[35], td_n[36]);
    td_n[38] = td_leaf[20];
    td_n[39] = td_leaf[21];
    td_n[40] = td_merge(td_n[38], td_n[39]);
    td_n[41] = td_merge(td_n[37], td_n[40]);
    td_n[42] = td_leaf[22];
    td_n[43] = td_leaf[23];
    td_n[44] = td_merge(td_n[42], td_n[43]);
    td_n[45] = td_leaf[24];
    td_n[46] = td_leaf[25];
    td_n[47] = td_leaf[26];
    td_n[48] = td_merge(td_n[46], td_n[47]);
    td_n[49] = td_merge(td_n[45], td_n[48]);
    td_n[50] = td_merge(td_n[44], td_n[49]);
    td_n[51] = td_merge(td_n[41], td_n[50]);
    td_n[52] = td_leaf[27];
    td_n[53] = td_leaf[28];
    td_n[54] = td_merge(td_n[52], td_n[53]);
    td_n[55] = td_leaf[29];
    td_n[56] = td_leaf[30];
    td_n[57] = td_merge(td_n[55], td_n[56]);
    td_n[58] = td_merge(td_n[54], td_n[57]);
    td_n[59] = td_leaf[31];
    td_n[60] = td_leaf[32];
    td_n[61] = td_merge(td_n[59], td_n[60]);
    td_n[62] = td_leaf[33];
    td_n[63] = td_leaf[34];
    td_n[64] = td_leaf[35];
    td_n[65] = td_merge(td_n[63], td_n[64]);
    td_n[66] = td_merge(td_n[62], td_n[65]);
    td_n[67] = td_merge(td_n[61], td_n[66]);
    td_n[68] = td_merge(td_n[58], td_n[67]);
    td_n[69] = td_merge(td_n[51], td_n[68]);
    td_n[70] = td_merge(td_n[34], td_n[69]);
    td_n[71] = td_leaf[36];
    td_n[72] = td_leaf[37];
    td_n[73] = td_merge(td_n[71], td_n[72]);
    td_n[74] = td_leaf[38];
    td_n[75] = td_leaf[39];
    td_n[76] = td_merge(td_n[74], td_n[75]);
    td_n[77] = td_merge(td_n[73], td_n[76]);
    td_n[78] = td_leaf[40];
    td_n[79] = td_leaf[41];
    td_n[80] = td_merge(td_n[78], td_n[79]);
    td_n[81] = td_leaf[42];
    td_n[82] = td_leaf[43];
    td_n[83] = td_leaf[44];
    td_n[84] = td_merge(td_n[82], td_n[83]);
    td_n[85] = td_merge(td_n[81], td_n[84]);
    td_n[86] = td_merge(td_n[80], td_n[85]);
    td_n[87] = td_merge(td_n[77], td_n[86]);
    td_n[88] = td_leaf[45];
    td_n[89] = td_leaf[46];
    td_n[90] = td_merge(td_n[88], td_n[89]);
    td_n[91] = td_leaf[47];
    td_n[92] = td_leaf[48];
    td_n[93] = td_merge(td_n[91], td_n[92]);
    td_n[94] = td_merge(td_n[90], td_n[93]);
    td_n[95] = td_leaf[49];
    td_n[96] = td_leaf[50];
    td_n[97] = td_merge(td_n[95], td_n[96]);
    td_n[98] = td_leaf[51];
    td_n[99] = td_leaf[52];
    td_n[100] = td_leaf[53];
    td_n[101] = td_merge(td_n[99], td_n[100]);
    td_n[102] = td_merge(td_n[98], td_n[101]);
    td_n[103] = td_merge(td_n[97], td_n[102]);
    td_n[104] = td_merge(td_n[94], td_n[103]);
    td_n[105] = td_merge(td_n[87], td_n[104]);
    td_n[106] = td_leaf[54];
    td_n[107] = td_leaf[55];
    td_n[108] = td_merge(td_n[106], td_n[107]);
    td_n[109] = td_leaf[56];
    td_n[110] = td_leaf[57];
    td_n[111] = td_merge(td_n[109], td_n[110]);
    td_n[112] = td_merge(td_n[108], td_n[111]);
    td_n[113] = td_leaf[58];
    td_n[114] = td_leaf[59];
    td_n[115] = td_merge(td_n[113], td_n[114]);
    td_n[116] = td_leaf[60];
    td_n[117] = td_leaf[61];
    td_n[118] = td_leaf[62];
    td_n[119] = td_merge(td_n[117], td_n[118]);
    td_n[120] = td_merge(td_n[116], td_n[119]);
    td_n[121] = td_merge(td_n[115], td_n[120]);
    td_n[122] = td_merge(td_n[112], td_n[121]);
    td_n[123] = td_leaf[63];
    td_n[124] = td_leaf[64];
    td_n[125] = td_merge(td_n[123], td_n[124]);
    td_n[126] = td_leaf[65];
    td_n[127] = td_leaf[66];
    td_n[128] = td_merge(td_n[126], td_n[127]);
    td_n[129] = td_merge(td_n[125], td_n[128]);
    td_n[130] = td_leaf[67];
    td_n[131] = td_leaf[68];
    td_n[132] = td_merge(td_n[130], td_n[131]);
    td_n[133] = td_leaf[69];
    td_n[134] = td_leaf[70];
    td_n[135] = td_leaf[71];
    td_n[136] = td_merge(td_n[134], td_n[135]);
    td_n[137] = td_merge(td_n[133], td_n[136]);
    td_n[138] = td_merge(td_n[132], td_n[137]);
    td_n[139] = td_merge(td_n[129], td_n[138]);
    td_n[140] = td_merge(td_n[122], td_n[139]);
    td_n[141] = td_merge(td_n[105], td_n[140]);
    td_n[142] = td_merge(td_n[70], td_n[141]);
    // END GENERATED
  end

  wire                lq_match   = td_n[142].v & dtd_robHeadVaddr_valid;
  wire [N_CAUSES-1:0] matchCause = causeR[td_n[142].lqV];

  wire rob_head_tlb_miss = lq_match & matchCause[C_TM];
  assign dtd_robHeadTlbReplay = rob_head_tlb_miss & ~dtd_robHeadMissInDTlb;
  assign dtd_robHeadTlbMiss   = rob_head_tlb_miss &  dtd_robHeadMissInDTlb;
  assign dtd_robHeadLoadVio   = (lq_match & matchCause[C_NK]) | (lq_match & matchCause[C_MA]);
  // ★golden 的 robHeadLoadMSHR 取的是 cause(C_DR)，**不是 C_DM**（名字误导）。★
  assign dtd_robHeadLoadMSHR  = lq_match & matchCause[C_DR];

  // ===========================================================================
  //  §7  perf（13 项，各经两级寄存后零扩展到 6 位）
  // ===========================================================================
  logic [LD_PIPE_W-1:0] newEnqFire;
  always_comb
    for (int w = 0; w < LD_PIPE_W; w++)
      newEnqFire[w] = enq_valid[w] & ~enq_isLoadReplay[w];

  function automatic logic [1:0] cnt_cause(input logic [LD_PIPE_W-1:0] fire,
                                           input logic [LD_PIPE_W-1:0] hasc);
    logic [1:0] n;
    n = '0;
    for (int w = 0; w < LD_PIPE_W; w++) if (fire[w] & hasc[w]) n += 1'b1;
    return n;
  endfunction
  // 第二个形参用 replay_cause_e 而不是 int：传进来的就是 cause 枚举，
  //  用 int 会触发 FM 的 FMR_VLOG-057「无符号赋给有符号」警告 ×9。
  function automatic logic [LD_PIPE_W-1:0] cause_bits(
      input logic [LD_PIPE_W-1:0][N_CAUSES-1:0] cv, input replay_cause_e c);
    logic [LD_PIPE_W-1:0] r;
    for (int w = 0; w < LD_PIPE_W; w++) r[w] = cv[w][c];
    return r;
  endfunction

  logic [1:0] perfNext [13];
  logic       perfFullNext;
  always_comb begin
    perfNext[0]  = cnt_cause(newEnqFire, '1);                          // enq
    perfNext[1]  = replay_fire[0] + replay_fire[1] + replay_fire[2];   // deq
    perfNext[2]  = (replay_valid[0] & ~replay_ready[0]) + (replay_valid[1] & ~replay_ready[1])
                 + (replay_valid[2] & ~replay_ready[2]);               // deq_block
    perfFullNext = lqFull;                                             // replay_full（perf_3）
    perfNext[4]  = cnt_cause(newEnqFire, cause_bits(enq_cause, C_RAR));
    perfNext[5]  = cnt_cause(newEnqFire, cause_bits(enq_cause, C_RAW));
    perfNext[6]  = cnt_cause(newEnqFire, cause_bits(enq_cause, C_NK));
    perfNext[7]  = cnt_cause(newEnqFire, cause_bits(enq_cause, C_MA));
    perfNext[8]  = cnt_cause(newEnqFire, cause_bits(enq_cause, C_TM));
    perfNext[9]  = cnt_cause(newEnqFire, cause_bits(enq_cause, C_BC));
    perfNext[10] = cnt_cause(newEnqFire, cause_bits(enq_cause, C_DR));
    perfNext[11] = cnt_cause(newEnqFire, cause_bits(enq_cause, C_FF));
    perfNext[12] = cnt_cause(newEnqFire, cause_bits(enq_cause, C_DM));
    perfNext[3]  = '0;   // 占位：perf_3 走单独的 1 位 perfFull 流水
  end

  logic [1:0] perfReg0 [13], perfReg1 [13];
  logic       perfFull0, perfFull1;
  always_ff @(posedge clock) begin
    // index 3 是 replay_full，golden 的 io_perf_3_value_REG 只有 1 位；这里也用 1 位
    //  perfFull0/1，不寄 perfReg0/1[3]（否则那 2 位全死 → unread_impl）。
    for (int k = 0; k < 13; k++)
      if (k != 3) begin
        perfReg0[k] <= perfNext[k];
        perfReg1[k] <= perfReg0[k];
      end
    perfFull0 <= perfFullNext;
    perfFull1 <= perfFull0;
  end
  always_comb begin
    for (int k = 0; k < 13; k++) perf_value[k] = {4'b0, perfReg1[k]};
    perf_value[3] = {5'b0, perfFull1};
  end

endmodule


// =============================================================================
//  wrapper：端口与 golden LoadQueueReplay 逐位同名，内部把扁平 io_* 打包给可读核。
//  端口表与连线全部由 scripts/gen_lqreplay.py 从 G1 golden 生成。
// =============================================================================
module LoadQueueReplay
  import loadqueuereplay_pkg::*;
(
  // BEGIN GENERATED(wrapper_ports)
  input            clock,
  input            reset,
  input            io_redirect_valid,
  input            io_redirect_bits_robIdx_flag,
  input  [7:0]     io_redirect_bits_robIdx_value,
  input            io_redirect_bits_level,
  input            io_vecFeedback_0_valid,
  input            io_vecFeedback_0_bits_robidx_flag,
  input  [7:0]     io_vecFeedback_0_bits_robidx_value,
  input  [6:0]     io_vecFeedback_0_bits_uopidx,
  input            io_vecFeedback_0_bits_feedback_0,
  input            io_vecFeedback_0_bits_feedback_1,
  input            io_vecFeedback_1_valid,
  input            io_vecFeedback_1_bits_robidx_flag,
  input  [7:0]     io_vecFeedback_1_bits_robidx_value,
  input  [6:0]     io_vecFeedback_1_bits_uopidx,
  input            io_vecFeedback_1_bits_feedback_0,
  input            io_vecFeedback_1_bits_feedback_1,
  input            io_enq_0_valid,
  input  [31:0]    io_enq_0_bits_uop_instr,
  input  [49:0]    io_enq_0_bits_uop_pc,
  input  [9:0]     io_enq_0_bits_uop_foldpc,
  input            io_enq_0_bits_uop_exceptionVec_0,
  input            io_enq_0_bits_uop_exceptionVec_1,
  input            io_enq_0_bits_uop_exceptionVec_2,
  input            io_enq_0_bits_uop_exceptionVec_3,
  input            io_enq_0_bits_uop_exceptionVec_5,
  input            io_enq_0_bits_uop_exceptionVec_6,
  input            io_enq_0_bits_uop_exceptionVec_7,
  input            io_enq_0_bits_uop_exceptionVec_8,
  input            io_enq_0_bits_uop_exceptionVec_9,
  input            io_enq_0_bits_uop_exceptionVec_10,
  input            io_enq_0_bits_uop_exceptionVec_11,
  input            io_enq_0_bits_uop_exceptionVec_12,
  input            io_enq_0_bits_uop_exceptionVec_13,
  input            io_enq_0_bits_uop_exceptionVec_14,
  input            io_enq_0_bits_uop_exceptionVec_15,
  input            io_enq_0_bits_uop_exceptionVec_16,
  input            io_enq_0_bits_uop_exceptionVec_17,
  input            io_enq_0_bits_uop_exceptionVec_18,
  input            io_enq_0_bits_uop_exceptionVec_19,
  input            io_enq_0_bits_uop_exceptionVec_20,
  input            io_enq_0_bits_uop_exceptionVec_21,
  input            io_enq_0_bits_uop_exceptionVec_22,
  input            io_enq_0_bits_uop_exceptionVec_23,
  input            io_enq_0_bits_uop_isFetchMalAddr,
  input            io_enq_0_bits_uop_hasException,
  input  [3:0]     io_enq_0_bits_uop_trigger,
  input            io_enq_0_bits_uop_preDecodeInfo_valid,
  input            io_enq_0_bits_uop_preDecodeInfo_isRVC,
  input  [1:0]     io_enq_0_bits_uop_preDecodeInfo_brType,
  input            io_enq_0_bits_uop_preDecodeInfo_isCall,
  input            io_enq_0_bits_uop_preDecodeInfo_isRet,
  input            io_enq_0_bits_uop_pred_taken,
  input            io_enq_0_bits_uop_crossPageIPFFix,
  input            io_enq_0_bits_uop_ftqPtr_flag,
  input  [5:0]     io_enq_0_bits_uop_ftqPtr_value,
  input  [3:0]     io_enq_0_bits_uop_ftqOffset,
  input            io_enq_0_bits_uop_satpFlushFirstFetchFault,
  input  [3:0]     io_enq_0_bits_uop_srcType_0,
  input  [3:0]     io_enq_0_bits_uop_srcType_1,
  input  [3:0]     io_enq_0_bits_uop_srcType_2,
  input  [3:0]     io_enq_0_bits_uop_srcType_3,
  input  [3:0]     io_enq_0_bits_uop_srcType_4,
  input  [5:0]     io_enq_0_bits_uop_ldest,
  input  [34:0]    io_enq_0_bits_uop_fuType,
  input  [8:0]     io_enq_0_bits_uop_fuOpType,
  input            io_enq_0_bits_uop_rfWen,
  input            io_enq_0_bits_uop_fpWen,
  input            io_enq_0_bits_uop_vecWen,
  input            io_enq_0_bits_uop_v0Wen,
  input            io_enq_0_bits_uop_vlWen,
  input            io_enq_0_bits_uop_isXSTrap,
  input            io_enq_0_bits_uop_waitForward,
  input            io_enq_0_bits_uop_blockBackward,
  input            io_enq_0_bits_uop_canRobCompress,
  input  [3:0]     io_enq_0_bits_uop_selImm,
  input  [31:0]    io_enq_0_bits_uop_imm,
  input  [1:0]     io_enq_0_bits_uop_fpu_typeTagOut,
  input            io_enq_0_bits_uop_fpu_wflags,
  input  [1:0]     io_enq_0_bits_uop_fpu_typ,
  input  [1:0]     io_enq_0_bits_uop_fpu_fmt,
  input  [2:0]     io_enq_0_bits_uop_fpu_rm,
  input            io_enq_0_bits_uop_vpu_vill,
  input            io_enq_0_bits_uop_vpu_vma,
  input            io_enq_0_bits_uop_vpu_vta,
  input  [1:0]     io_enq_0_bits_uop_vpu_vsew,
  input  [2:0]     io_enq_0_bits_uop_vpu_vlmul,
  input            io_enq_0_bits_uop_vpu_specVill,
  input            io_enq_0_bits_uop_vpu_specVma,
  input            io_enq_0_bits_uop_vpu_specVta,
  input  [1:0]     io_enq_0_bits_uop_vpu_specVsew,
  input  [2:0]     io_enq_0_bits_uop_vpu_specVlmul,
  input            io_enq_0_bits_uop_vpu_vm,
  input  [7:0]     io_enq_0_bits_uop_vpu_vstart,
  input  [2:0]     io_enq_0_bits_uop_vpu_frm,
  input            io_enq_0_bits_uop_vpu_fpu_isFpToVecInst,
  input            io_enq_0_bits_uop_vpu_fpu_isFP32Instr,
  input            io_enq_0_bits_uop_vpu_fpu_isFP64Instr,
  input            io_enq_0_bits_uop_vpu_fpu_isReduction,
  input            io_enq_0_bits_uop_vpu_fpu_isFoldTo1_2,
  input            io_enq_0_bits_uop_vpu_fpu_isFoldTo1_4,
  input            io_enq_0_bits_uop_vpu_fpu_isFoldTo1_8,
  input  [1:0]     io_enq_0_bits_uop_vpu_vxrm,
  input  [6:0]     io_enq_0_bits_uop_vpu_vuopIdx,
  input            io_enq_0_bits_uop_vpu_lastUop,
  input  [127:0]   io_enq_0_bits_uop_vpu_vmask,
  input  [7:0]     io_enq_0_bits_uop_vpu_vl,
  input  [2:0]     io_enq_0_bits_uop_vpu_nf,
  input  [1:0]     io_enq_0_bits_uop_vpu_veew,
  input            io_enq_0_bits_uop_vpu_isReverse,
  input            io_enq_0_bits_uop_vpu_isExt,
  input            io_enq_0_bits_uop_vpu_isNarrow,
  input            io_enq_0_bits_uop_vpu_isDstMask,
  input            io_enq_0_bits_uop_vpu_isOpMask,
  input            io_enq_0_bits_uop_vpu_isMove,
  input            io_enq_0_bits_uop_vpu_isDependOldVd,
  input            io_enq_0_bits_uop_vpu_isWritePartVd,
  input            io_enq_0_bits_uop_vpu_isVleff,
  input            io_enq_0_bits_uop_vlsInstr,
  input            io_enq_0_bits_uop_wfflags,
  input            io_enq_0_bits_uop_isMove,
  input            io_enq_0_bits_uop_isDropAmocasSta,
  input  [6:0]     io_enq_0_bits_uop_uopIdx,
  input            io_enq_0_bits_uop_isVset,
  input            io_enq_0_bits_uop_firstUop,
  input            io_enq_0_bits_uop_lastUop,
  input  [6:0]     io_enq_0_bits_uop_numUops,
  input  [6:0]     io_enq_0_bits_uop_numWB,
  input  [2:0]     io_enq_0_bits_uop_commitType,
  input            io_enq_0_bits_uop_srcState_0,
  input            io_enq_0_bits_uop_srcState_1,
  input            io_enq_0_bits_uop_srcState_2,
  input            io_enq_0_bits_uop_srcState_3,
  input            io_enq_0_bits_uop_srcState_4,
  input  [1:0]     io_enq_0_bits_uop_srcLoadDependency_0_0,
  input  [1:0]     io_enq_0_bits_uop_srcLoadDependency_0_1,
  input  [1:0]     io_enq_0_bits_uop_srcLoadDependency_0_2,
  input  [1:0]     io_enq_0_bits_uop_srcLoadDependency_1_0,
  input  [1:0]     io_enq_0_bits_uop_srcLoadDependency_1_1,
  input  [1:0]     io_enq_0_bits_uop_srcLoadDependency_1_2,
  input  [1:0]     io_enq_0_bits_uop_srcLoadDependency_2_0,
  input  [1:0]     io_enq_0_bits_uop_srcLoadDependency_2_1,
  input  [1:0]     io_enq_0_bits_uop_srcLoadDependency_2_2,
  input  [1:0]     io_enq_0_bits_uop_srcLoadDependency_3_0,
  input  [1:0]     io_enq_0_bits_uop_srcLoadDependency_3_1,
  input  [1:0]     io_enq_0_bits_uop_srcLoadDependency_3_2,
  input  [1:0]     io_enq_0_bits_uop_srcLoadDependency_4_0,
  input  [1:0]     io_enq_0_bits_uop_srcLoadDependency_4_1,
  input  [1:0]     io_enq_0_bits_uop_srcLoadDependency_4_2,
  input  [7:0]     io_enq_0_bits_uop_psrc_0,
  input  [7:0]     io_enq_0_bits_uop_psrc_1,
  input  [7:0]     io_enq_0_bits_uop_psrc_2,
  input  [7:0]     io_enq_0_bits_uop_psrc_3,
  input  [7:0]     io_enq_0_bits_uop_psrc_4,
  input  [7:0]     io_enq_0_bits_uop_pdest,
  input            io_enq_0_bits_uop_useRegCache_0,
  input            io_enq_0_bits_uop_useRegCache_1,
  input  [4:0]     io_enq_0_bits_uop_regCacheIdx_0,
  input  [4:0]     io_enq_0_bits_uop_regCacheIdx_1,
  input            io_enq_0_bits_uop_robIdx_flag,
  input  [7:0]     io_enq_0_bits_uop_robIdx_value,
  input  [2:0]     io_enq_0_bits_uop_instrSize,
  input            io_enq_0_bits_uop_dirtyFs,
  input            io_enq_0_bits_uop_dirtyVs,
  input  [3:0]     io_enq_0_bits_uop_traceBlockInPipe_itype,
  input  [3:0]     io_enq_0_bits_uop_traceBlockInPipe_iretire,
  input            io_enq_0_bits_uop_traceBlockInPipe_ilastsize,
  input            io_enq_0_bits_uop_eliminatedMove,
  input            io_enq_0_bits_uop_snapshot,
  input            io_enq_0_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]    io_enq_0_bits_uop_debugInfo_renameTime,
  input  [63:0]    io_enq_0_bits_uop_debugInfo_dispatchTime,
  input  [63:0]    io_enq_0_bits_uop_debugInfo_enqRsTime,
  input  [63:0]    io_enq_0_bits_uop_debugInfo_selectTime,
  input  [63:0]    io_enq_0_bits_uop_debugInfo_issueTime,
  input  [63:0]    io_enq_0_bits_uop_debugInfo_writebackTime,
  input  [63:0]    io_enq_0_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]    io_enq_0_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]    io_enq_0_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]    io_enq_0_bits_uop_debug_seqNum_seqNum,
  input  [7:0]     io_enq_0_bits_uop_debug_seqNum_uopIdx,
  input            io_enq_0_bits_uop_storeSetHit,
  input            io_enq_0_bits_uop_waitForRobIdx_flag,
  input  [7:0]     io_enq_0_bits_uop_waitForRobIdx_value,
  input            io_enq_0_bits_uop_loadWaitBit,
  input            io_enq_0_bits_uop_loadWaitStrict,
  input  [4:0]     io_enq_0_bits_uop_ssid,
  input            io_enq_0_bits_uop_lqIdx_flag,
  input  [6:0]     io_enq_0_bits_uop_lqIdx_value,
  input            io_enq_0_bits_uop_sqIdx_flag,
  input  [5:0]     io_enq_0_bits_uop_sqIdx_value,
  input            io_enq_0_bits_uop_singleStep,
  input  [34:0]    io_enq_0_bits_uop_debug_fuType,
  input            io_enq_0_bits_uop_debug_sim_trig,
  input  [4:0]     io_enq_0_bits_uop_numLsElem,
  input  [49:0]    io_enq_0_bits_vaddr,
  input  [15:0]    io_enq_0_bits_mask,
  input            io_enq_0_bits_isvec,
  input            io_enq_0_bits_is128bit,
  input  [7:0]     io_enq_0_bits_elemIdx,
  input  [2:0]     io_enq_0_bits_alignedType,
  input  [3:0]     io_enq_0_bits_mbIndex,
  input  [3:0]     io_enq_0_bits_reg_offset,
  input  [7:0]     io_enq_0_bits_elemIdxInsideVd,
  input            io_enq_0_bits_vecActive,
  input            io_enq_0_bits_isLoadReplay,
  input            io_enq_0_bits_handledByMSHR,
  input  [6:0]     io_enq_0_bits_schedIndex,
  input  [3:0]     io_enq_0_bits_rep_info_mshr_id,
  input            io_enq_0_bits_rep_info_full_fwd,
  input            io_enq_0_bits_rep_info_data_inv_sq_idx_flag,
  input  [5:0]     io_enq_0_bits_rep_info_data_inv_sq_idx_value,
  input            io_enq_0_bits_rep_info_addr_inv_sq_idx_flag,
  input  [5:0]     io_enq_0_bits_rep_info_addr_inv_sq_idx_value,
  input            io_enq_0_bits_rep_info_last_beat,
  input            io_enq_0_bits_rep_info_cause_0,
  input            io_enq_0_bits_rep_info_cause_1,
  input            io_enq_0_bits_rep_info_cause_2,
  input            io_enq_0_bits_rep_info_cause_3,
  input            io_enq_0_bits_rep_info_cause_4,
  input            io_enq_0_bits_rep_info_cause_5,
  input            io_enq_0_bits_rep_info_cause_6,
  input            io_enq_0_bits_rep_info_cause_7,
  input            io_enq_0_bits_rep_info_cause_8,
  input            io_enq_0_bits_rep_info_cause_9,
  input            io_enq_0_bits_rep_info_cause_10,
  input  [3:0]     io_enq_0_bits_rep_info_tlb_id,
  input            io_enq_0_bits_rep_info_tlb_full,
  input            io_enq_1_valid,
  input  [31:0]    io_enq_1_bits_uop_instr,
  input  [49:0]    io_enq_1_bits_uop_pc,
  input  [9:0]     io_enq_1_bits_uop_foldpc,
  input            io_enq_1_bits_uop_exceptionVec_0,
  input            io_enq_1_bits_uop_exceptionVec_1,
  input            io_enq_1_bits_uop_exceptionVec_2,
  input            io_enq_1_bits_uop_exceptionVec_3,
  input            io_enq_1_bits_uop_exceptionVec_5,
  input            io_enq_1_bits_uop_exceptionVec_6,
  input            io_enq_1_bits_uop_exceptionVec_7,
  input            io_enq_1_bits_uop_exceptionVec_8,
  input            io_enq_1_bits_uop_exceptionVec_9,
  input            io_enq_1_bits_uop_exceptionVec_10,
  input            io_enq_1_bits_uop_exceptionVec_11,
  input            io_enq_1_bits_uop_exceptionVec_12,
  input            io_enq_1_bits_uop_exceptionVec_13,
  input            io_enq_1_bits_uop_exceptionVec_14,
  input            io_enq_1_bits_uop_exceptionVec_15,
  input            io_enq_1_bits_uop_exceptionVec_16,
  input            io_enq_1_bits_uop_exceptionVec_17,
  input            io_enq_1_bits_uop_exceptionVec_18,
  input            io_enq_1_bits_uop_exceptionVec_19,
  input            io_enq_1_bits_uop_exceptionVec_20,
  input            io_enq_1_bits_uop_exceptionVec_21,
  input            io_enq_1_bits_uop_exceptionVec_22,
  input            io_enq_1_bits_uop_exceptionVec_23,
  input            io_enq_1_bits_uop_isFetchMalAddr,
  input            io_enq_1_bits_uop_hasException,
  input  [3:0]     io_enq_1_bits_uop_trigger,
  input            io_enq_1_bits_uop_preDecodeInfo_valid,
  input            io_enq_1_bits_uop_preDecodeInfo_isRVC,
  input  [1:0]     io_enq_1_bits_uop_preDecodeInfo_brType,
  input            io_enq_1_bits_uop_preDecodeInfo_isCall,
  input            io_enq_1_bits_uop_preDecodeInfo_isRet,
  input            io_enq_1_bits_uop_pred_taken,
  input            io_enq_1_bits_uop_crossPageIPFFix,
  input            io_enq_1_bits_uop_ftqPtr_flag,
  input  [5:0]     io_enq_1_bits_uop_ftqPtr_value,
  input  [3:0]     io_enq_1_bits_uop_ftqOffset,
  input            io_enq_1_bits_uop_satpFlushFirstFetchFault,
  input  [3:0]     io_enq_1_bits_uop_srcType_0,
  input  [3:0]     io_enq_1_bits_uop_srcType_1,
  input  [3:0]     io_enq_1_bits_uop_srcType_2,
  input  [3:0]     io_enq_1_bits_uop_srcType_3,
  input  [3:0]     io_enq_1_bits_uop_srcType_4,
  input  [5:0]     io_enq_1_bits_uop_ldest,
  input  [34:0]    io_enq_1_bits_uop_fuType,
  input  [8:0]     io_enq_1_bits_uop_fuOpType,
  input            io_enq_1_bits_uop_rfWen,
  input            io_enq_1_bits_uop_fpWen,
  input            io_enq_1_bits_uop_vecWen,
  input            io_enq_1_bits_uop_v0Wen,
  input            io_enq_1_bits_uop_vlWen,
  input            io_enq_1_bits_uop_isXSTrap,
  input            io_enq_1_bits_uop_waitForward,
  input            io_enq_1_bits_uop_blockBackward,
  input            io_enq_1_bits_uop_canRobCompress,
  input  [3:0]     io_enq_1_bits_uop_selImm,
  input  [31:0]    io_enq_1_bits_uop_imm,
  input  [1:0]     io_enq_1_bits_uop_fpu_typeTagOut,
  input            io_enq_1_bits_uop_fpu_wflags,
  input  [1:0]     io_enq_1_bits_uop_fpu_typ,
  input  [1:0]     io_enq_1_bits_uop_fpu_fmt,
  input  [2:0]     io_enq_1_bits_uop_fpu_rm,
  input            io_enq_1_bits_uop_vpu_vill,
  input            io_enq_1_bits_uop_vpu_vma,
  input            io_enq_1_bits_uop_vpu_vta,
  input  [1:0]     io_enq_1_bits_uop_vpu_vsew,
  input  [2:0]     io_enq_1_bits_uop_vpu_vlmul,
  input            io_enq_1_bits_uop_vpu_specVill,
  input            io_enq_1_bits_uop_vpu_specVma,
  input            io_enq_1_bits_uop_vpu_specVta,
  input  [1:0]     io_enq_1_bits_uop_vpu_specVsew,
  input  [2:0]     io_enq_1_bits_uop_vpu_specVlmul,
  input            io_enq_1_bits_uop_vpu_vm,
  input  [7:0]     io_enq_1_bits_uop_vpu_vstart,
  input  [2:0]     io_enq_1_bits_uop_vpu_frm,
  input            io_enq_1_bits_uop_vpu_fpu_isFpToVecInst,
  input            io_enq_1_bits_uop_vpu_fpu_isFP32Instr,
  input            io_enq_1_bits_uop_vpu_fpu_isFP64Instr,
  input            io_enq_1_bits_uop_vpu_fpu_isReduction,
  input            io_enq_1_bits_uop_vpu_fpu_isFoldTo1_2,
  input            io_enq_1_bits_uop_vpu_fpu_isFoldTo1_4,
  input            io_enq_1_bits_uop_vpu_fpu_isFoldTo1_8,
  input  [1:0]     io_enq_1_bits_uop_vpu_vxrm,
  input  [6:0]     io_enq_1_bits_uop_vpu_vuopIdx,
  input            io_enq_1_bits_uop_vpu_lastUop,
  input  [127:0]   io_enq_1_bits_uop_vpu_vmask,
  input  [7:0]     io_enq_1_bits_uop_vpu_vl,
  input  [2:0]     io_enq_1_bits_uop_vpu_nf,
  input  [1:0]     io_enq_1_bits_uop_vpu_veew,
  input            io_enq_1_bits_uop_vpu_isReverse,
  input            io_enq_1_bits_uop_vpu_isExt,
  input            io_enq_1_bits_uop_vpu_isNarrow,
  input            io_enq_1_bits_uop_vpu_isDstMask,
  input            io_enq_1_bits_uop_vpu_isOpMask,
  input            io_enq_1_bits_uop_vpu_isMove,
  input            io_enq_1_bits_uop_vpu_isDependOldVd,
  input            io_enq_1_bits_uop_vpu_isWritePartVd,
  input            io_enq_1_bits_uop_vpu_isVleff,
  input            io_enq_1_bits_uop_vlsInstr,
  input            io_enq_1_bits_uop_wfflags,
  input            io_enq_1_bits_uop_isMove,
  input            io_enq_1_bits_uop_isDropAmocasSta,
  input  [6:0]     io_enq_1_bits_uop_uopIdx,
  input            io_enq_1_bits_uop_isVset,
  input            io_enq_1_bits_uop_firstUop,
  input            io_enq_1_bits_uop_lastUop,
  input  [6:0]     io_enq_1_bits_uop_numUops,
  input  [6:0]     io_enq_1_bits_uop_numWB,
  input  [2:0]     io_enq_1_bits_uop_commitType,
  input            io_enq_1_bits_uop_srcState_0,
  input            io_enq_1_bits_uop_srcState_1,
  input            io_enq_1_bits_uop_srcState_2,
  input            io_enq_1_bits_uop_srcState_3,
  input            io_enq_1_bits_uop_srcState_4,
  input  [1:0]     io_enq_1_bits_uop_srcLoadDependency_0_0,
  input  [1:0]     io_enq_1_bits_uop_srcLoadDependency_0_1,
  input  [1:0]     io_enq_1_bits_uop_srcLoadDependency_0_2,
  input  [1:0]     io_enq_1_bits_uop_srcLoadDependency_1_0,
  input  [1:0]     io_enq_1_bits_uop_srcLoadDependency_1_1,
  input  [1:0]     io_enq_1_bits_uop_srcLoadDependency_1_2,
  input  [1:0]     io_enq_1_bits_uop_srcLoadDependency_2_0,
  input  [1:0]     io_enq_1_bits_uop_srcLoadDependency_2_1,
  input  [1:0]     io_enq_1_bits_uop_srcLoadDependency_2_2,
  input  [1:0]     io_enq_1_bits_uop_srcLoadDependency_3_0,
  input  [1:0]     io_enq_1_bits_uop_srcLoadDependency_3_1,
  input  [1:0]     io_enq_1_bits_uop_srcLoadDependency_3_2,
  input  [1:0]     io_enq_1_bits_uop_srcLoadDependency_4_0,
  input  [1:0]     io_enq_1_bits_uop_srcLoadDependency_4_1,
  input  [1:0]     io_enq_1_bits_uop_srcLoadDependency_4_2,
  input  [7:0]     io_enq_1_bits_uop_psrc_0,
  input  [7:0]     io_enq_1_bits_uop_psrc_1,
  input  [7:0]     io_enq_1_bits_uop_psrc_2,
  input  [7:0]     io_enq_1_bits_uop_psrc_3,
  input  [7:0]     io_enq_1_bits_uop_psrc_4,
  input  [7:0]     io_enq_1_bits_uop_pdest,
  input            io_enq_1_bits_uop_useRegCache_0,
  input            io_enq_1_bits_uop_useRegCache_1,
  input  [4:0]     io_enq_1_bits_uop_regCacheIdx_0,
  input  [4:0]     io_enq_1_bits_uop_regCacheIdx_1,
  input            io_enq_1_bits_uop_robIdx_flag,
  input  [7:0]     io_enq_1_bits_uop_robIdx_value,
  input  [2:0]     io_enq_1_bits_uop_instrSize,
  input            io_enq_1_bits_uop_dirtyFs,
  input            io_enq_1_bits_uop_dirtyVs,
  input  [3:0]     io_enq_1_bits_uop_traceBlockInPipe_itype,
  input  [3:0]     io_enq_1_bits_uop_traceBlockInPipe_iretire,
  input            io_enq_1_bits_uop_traceBlockInPipe_ilastsize,
  input            io_enq_1_bits_uop_eliminatedMove,
  input            io_enq_1_bits_uop_snapshot,
  input            io_enq_1_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]    io_enq_1_bits_uop_debugInfo_renameTime,
  input  [63:0]    io_enq_1_bits_uop_debugInfo_dispatchTime,
  input  [63:0]    io_enq_1_bits_uop_debugInfo_enqRsTime,
  input  [63:0]    io_enq_1_bits_uop_debugInfo_selectTime,
  input  [63:0]    io_enq_1_bits_uop_debugInfo_issueTime,
  input  [63:0]    io_enq_1_bits_uop_debugInfo_writebackTime,
  input  [63:0]    io_enq_1_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]    io_enq_1_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]    io_enq_1_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]    io_enq_1_bits_uop_debug_seqNum_seqNum,
  input  [7:0]     io_enq_1_bits_uop_debug_seqNum_uopIdx,
  input            io_enq_1_bits_uop_storeSetHit,
  input            io_enq_1_bits_uop_waitForRobIdx_flag,
  input  [7:0]     io_enq_1_bits_uop_waitForRobIdx_value,
  input            io_enq_1_bits_uop_loadWaitBit,
  input            io_enq_1_bits_uop_loadWaitStrict,
  input  [4:0]     io_enq_1_bits_uop_ssid,
  input            io_enq_1_bits_uop_lqIdx_flag,
  input  [6:0]     io_enq_1_bits_uop_lqIdx_value,
  input            io_enq_1_bits_uop_sqIdx_flag,
  input  [5:0]     io_enq_1_bits_uop_sqIdx_value,
  input            io_enq_1_bits_uop_singleStep,
  input  [34:0]    io_enq_1_bits_uop_debug_fuType,
  input            io_enq_1_bits_uop_debug_sim_trig,
  input  [4:0]     io_enq_1_bits_uop_numLsElem,
  input  [49:0]    io_enq_1_bits_vaddr,
  input  [15:0]    io_enq_1_bits_mask,
  input            io_enq_1_bits_isvec,
  input            io_enq_1_bits_is128bit,
  input  [7:0]     io_enq_1_bits_elemIdx,
  input  [2:0]     io_enq_1_bits_alignedType,
  input  [3:0]     io_enq_1_bits_mbIndex,
  input  [3:0]     io_enq_1_bits_reg_offset,
  input  [7:0]     io_enq_1_bits_elemIdxInsideVd,
  input            io_enq_1_bits_vecActive,
  input            io_enq_1_bits_isLoadReplay,
  input            io_enq_1_bits_handledByMSHR,
  input  [6:0]     io_enq_1_bits_schedIndex,
  input  [3:0]     io_enq_1_bits_rep_info_mshr_id,
  input            io_enq_1_bits_rep_info_full_fwd,
  input            io_enq_1_bits_rep_info_data_inv_sq_idx_flag,
  input  [5:0]     io_enq_1_bits_rep_info_data_inv_sq_idx_value,
  input            io_enq_1_bits_rep_info_addr_inv_sq_idx_flag,
  input  [5:0]     io_enq_1_bits_rep_info_addr_inv_sq_idx_value,
  input            io_enq_1_bits_rep_info_last_beat,
  input            io_enq_1_bits_rep_info_cause_0,
  input            io_enq_1_bits_rep_info_cause_1,
  input            io_enq_1_bits_rep_info_cause_2,
  input            io_enq_1_bits_rep_info_cause_3,
  input            io_enq_1_bits_rep_info_cause_4,
  input            io_enq_1_bits_rep_info_cause_5,
  input            io_enq_1_bits_rep_info_cause_6,
  input            io_enq_1_bits_rep_info_cause_7,
  input            io_enq_1_bits_rep_info_cause_8,
  input            io_enq_1_bits_rep_info_cause_9,
  input            io_enq_1_bits_rep_info_cause_10,
  input  [3:0]     io_enq_1_bits_rep_info_tlb_id,
  input            io_enq_1_bits_rep_info_tlb_full,
  input            io_enq_2_valid,
  input  [31:0]    io_enq_2_bits_uop_instr,
  input  [49:0]    io_enq_2_bits_uop_pc,
  input  [9:0]     io_enq_2_bits_uop_foldpc,
  input            io_enq_2_bits_uop_exceptionVec_0,
  input            io_enq_2_bits_uop_exceptionVec_1,
  input            io_enq_2_bits_uop_exceptionVec_2,
  input            io_enq_2_bits_uop_exceptionVec_3,
  input            io_enq_2_bits_uop_exceptionVec_5,
  input            io_enq_2_bits_uop_exceptionVec_6,
  input            io_enq_2_bits_uop_exceptionVec_7,
  input            io_enq_2_bits_uop_exceptionVec_8,
  input            io_enq_2_bits_uop_exceptionVec_9,
  input            io_enq_2_bits_uop_exceptionVec_10,
  input            io_enq_2_bits_uop_exceptionVec_11,
  input            io_enq_2_bits_uop_exceptionVec_12,
  input            io_enq_2_bits_uop_exceptionVec_13,
  input            io_enq_2_bits_uop_exceptionVec_14,
  input            io_enq_2_bits_uop_exceptionVec_15,
  input            io_enq_2_bits_uop_exceptionVec_16,
  input            io_enq_2_bits_uop_exceptionVec_17,
  input            io_enq_2_bits_uop_exceptionVec_18,
  input            io_enq_2_bits_uop_exceptionVec_19,
  input            io_enq_2_bits_uop_exceptionVec_20,
  input            io_enq_2_bits_uop_exceptionVec_21,
  input            io_enq_2_bits_uop_exceptionVec_22,
  input            io_enq_2_bits_uop_exceptionVec_23,
  input            io_enq_2_bits_uop_isFetchMalAddr,
  input            io_enq_2_bits_uop_hasException,
  input  [3:0]     io_enq_2_bits_uop_trigger,
  input            io_enq_2_bits_uop_preDecodeInfo_valid,
  input            io_enq_2_bits_uop_preDecodeInfo_isRVC,
  input  [1:0]     io_enq_2_bits_uop_preDecodeInfo_brType,
  input            io_enq_2_bits_uop_preDecodeInfo_isCall,
  input            io_enq_2_bits_uop_preDecodeInfo_isRet,
  input            io_enq_2_bits_uop_pred_taken,
  input            io_enq_2_bits_uop_crossPageIPFFix,
  input            io_enq_2_bits_uop_ftqPtr_flag,
  input  [5:0]     io_enq_2_bits_uop_ftqPtr_value,
  input  [3:0]     io_enq_2_bits_uop_ftqOffset,
  input            io_enq_2_bits_uop_satpFlushFirstFetchFault,
  input  [3:0]     io_enq_2_bits_uop_srcType_0,
  input  [3:0]     io_enq_2_bits_uop_srcType_1,
  input  [3:0]     io_enq_2_bits_uop_srcType_2,
  input  [3:0]     io_enq_2_bits_uop_srcType_3,
  input  [3:0]     io_enq_2_bits_uop_srcType_4,
  input  [5:0]     io_enq_2_bits_uop_ldest,
  input  [34:0]    io_enq_2_bits_uop_fuType,
  input  [8:0]     io_enq_2_bits_uop_fuOpType,
  input            io_enq_2_bits_uop_rfWen,
  input            io_enq_2_bits_uop_fpWen,
  input            io_enq_2_bits_uop_vecWen,
  input            io_enq_2_bits_uop_v0Wen,
  input            io_enq_2_bits_uop_vlWen,
  input            io_enq_2_bits_uop_isXSTrap,
  input            io_enq_2_bits_uop_waitForward,
  input            io_enq_2_bits_uop_blockBackward,
  input            io_enq_2_bits_uop_canRobCompress,
  input  [3:0]     io_enq_2_bits_uop_selImm,
  input  [31:0]    io_enq_2_bits_uop_imm,
  input  [1:0]     io_enq_2_bits_uop_fpu_typeTagOut,
  input            io_enq_2_bits_uop_fpu_wflags,
  input  [1:0]     io_enq_2_bits_uop_fpu_typ,
  input  [1:0]     io_enq_2_bits_uop_fpu_fmt,
  input  [2:0]     io_enq_2_bits_uop_fpu_rm,
  input            io_enq_2_bits_uop_vpu_vill,
  input            io_enq_2_bits_uop_vpu_vma,
  input            io_enq_2_bits_uop_vpu_vta,
  input  [1:0]     io_enq_2_bits_uop_vpu_vsew,
  input  [2:0]     io_enq_2_bits_uop_vpu_vlmul,
  input            io_enq_2_bits_uop_vpu_specVill,
  input            io_enq_2_bits_uop_vpu_specVma,
  input            io_enq_2_bits_uop_vpu_specVta,
  input  [1:0]     io_enq_2_bits_uop_vpu_specVsew,
  input  [2:0]     io_enq_2_bits_uop_vpu_specVlmul,
  input            io_enq_2_bits_uop_vpu_vm,
  input  [7:0]     io_enq_2_bits_uop_vpu_vstart,
  input  [2:0]     io_enq_2_bits_uop_vpu_frm,
  input            io_enq_2_bits_uop_vpu_fpu_isFpToVecInst,
  input            io_enq_2_bits_uop_vpu_fpu_isFP32Instr,
  input            io_enq_2_bits_uop_vpu_fpu_isFP64Instr,
  input            io_enq_2_bits_uop_vpu_fpu_isReduction,
  input            io_enq_2_bits_uop_vpu_fpu_isFoldTo1_2,
  input            io_enq_2_bits_uop_vpu_fpu_isFoldTo1_4,
  input            io_enq_2_bits_uop_vpu_fpu_isFoldTo1_8,
  input  [1:0]     io_enq_2_bits_uop_vpu_vxrm,
  input  [6:0]     io_enq_2_bits_uop_vpu_vuopIdx,
  input            io_enq_2_bits_uop_vpu_lastUop,
  input  [127:0]   io_enq_2_bits_uop_vpu_vmask,
  input  [7:0]     io_enq_2_bits_uop_vpu_vl,
  input  [2:0]     io_enq_2_bits_uop_vpu_nf,
  input  [1:0]     io_enq_2_bits_uop_vpu_veew,
  input            io_enq_2_bits_uop_vpu_isReverse,
  input            io_enq_2_bits_uop_vpu_isExt,
  input            io_enq_2_bits_uop_vpu_isNarrow,
  input            io_enq_2_bits_uop_vpu_isDstMask,
  input            io_enq_2_bits_uop_vpu_isOpMask,
  input            io_enq_2_bits_uop_vpu_isMove,
  input            io_enq_2_bits_uop_vpu_isDependOldVd,
  input            io_enq_2_bits_uop_vpu_isWritePartVd,
  input            io_enq_2_bits_uop_vpu_isVleff,
  input            io_enq_2_bits_uop_vlsInstr,
  input            io_enq_2_bits_uop_wfflags,
  input            io_enq_2_bits_uop_isMove,
  input            io_enq_2_bits_uop_isDropAmocasSta,
  input  [6:0]     io_enq_2_bits_uop_uopIdx,
  input            io_enq_2_bits_uop_isVset,
  input            io_enq_2_bits_uop_firstUop,
  input            io_enq_2_bits_uop_lastUop,
  input  [6:0]     io_enq_2_bits_uop_numUops,
  input  [6:0]     io_enq_2_bits_uop_numWB,
  input  [2:0]     io_enq_2_bits_uop_commitType,
  input            io_enq_2_bits_uop_srcState_0,
  input            io_enq_2_bits_uop_srcState_1,
  input            io_enq_2_bits_uop_srcState_2,
  input            io_enq_2_bits_uop_srcState_3,
  input            io_enq_2_bits_uop_srcState_4,
  input  [1:0]     io_enq_2_bits_uop_srcLoadDependency_0_0,
  input  [1:0]     io_enq_2_bits_uop_srcLoadDependency_0_1,
  input  [1:0]     io_enq_2_bits_uop_srcLoadDependency_0_2,
  input  [1:0]     io_enq_2_bits_uop_srcLoadDependency_1_0,
  input  [1:0]     io_enq_2_bits_uop_srcLoadDependency_1_1,
  input  [1:0]     io_enq_2_bits_uop_srcLoadDependency_1_2,
  input  [1:0]     io_enq_2_bits_uop_srcLoadDependency_2_0,
  input  [1:0]     io_enq_2_bits_uop_srcLoadDependency_2_1,
  input  [1:0]     io_enq_2_bits_uop_srcLoadDependency_2_2,
  input  [1:0]     io_enq_2_bits_uop_srcLoadDependency_3_0,
  input  [1:0]     io_enq_2_bits_uop_srcLoadDependency_3_1,
  input  [1:0]     io_enq_2_bits_uop_srcLoadDependency_3_2,
  input  [1:0]     io_enq_2_bits_uop_srcLoadDependency_4_0,
  input  [1:0]     io_enq_2_bits_uop_srcLoadDependency_4_1,
  input  [1:0]     io_enq_2_bits_uop_srcLoadDependency_4_2,
  input  [7:0]     io_enq_2_bits_uop_psrc_0,
  input  [7:0]     io_enq_2_bits_uop_psrc_1,
  input  [7:0]     io_enq_2_bits_uop_psrc_2,
  input  [7:0]     io_enq_2_bits_uop_psrc_3,
  input  [7:0]     io_enq_2_bits_uop_psrc_4,
  input  [7:0]     io_enq_2_bits_uop_pdest,
  input            io_enq_2_bits_uop_useRegCache_0,
  input            io_enq_2_bits_uop_useRegCache_1,
  input  [4:0]     io_enq_2_bits_uop_regCacheIdx_0,
  input  [4:0]     io_enq_2_bits_uop_regCacheIdx_1,
  input            io_enq_2_bits_uop_robIdx_flag,
  input  [7:0]     io_enq_2_bits_uop_robIdx_value,
  input  [2:0]     io_enq_2_bits_uop_instrSize,
  input            io_enq_2_bits_uop_dirtyFs,
  input            io_enq_2_bits_uop_dirtyVs,
  input  [3:0]     io_enq_2_bits_uop_traceBlockInPipe_itype,
  input  [3:0]     io_enq_2_bits_uop_traceBlockInPipe_iretire,
  input            io_enq_2_bits_uop_traceBlockInPipe_ilastsize,
  input            io_enq_2_bits_uop_eliminatedMove,
  input            io_enq_2_bits_uop_snapshot,
  input            io_enq_2_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]    io_enq_2_bits_uop_debugInfo_renameTime,
  input  [63:0]    io_enq_2_bits_uop_debugInfo_dispatchTime,
  input  [63:0]    io_enq_2_bits_uop_debugInfo_enqRsTime,
  input  [63:0]    io_enq_2_bits_uop_debugInfo_selectTime,
  input  [63:0]    io_enq_2_bits_uop_debugInfo_issueTime,
  input  [63:0]    io_enq_2_bits_uop_debugInfo_writebackTime,
  input  [63:0]    io_enq_2_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]    io_enq_2_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]    io_enq_2_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]    io_enq_2_bits_uop_debug_seqNum_seqNum,
  input  [7:0]     io_enq_2_bits_uop_debug_seqNum_uopIdx,
  input            io_enq_2_bits_uop_storeSetHit,
  input            io_enq_2_bits_uop_waitForRobIdx_flag,
  input  [7:0]     io_enq_2_bits_uop_waitForRobIdx_value,
  input            io_enq_2_bits_uop_loadWaitBit,
  input            io_enq_2_bits_uop_loadWaitStrict,
  input  [4:0]     io_enq_2_bits_uop_ssid,
  input            io_enq_2_bits_uop_lqIdx_flag,
  input  [6:0]     io_enq_2_bits_uop_lqIdx_value,
  input            io_enq_2_bits_uop_sqIdx_flag,
  input  [5:0]     io_enq_2_bits_uop_sqIdx_value,
  input            io_enq_2_bits_uop_singleStep,
  input  [34:0]    io_enq_2_bits_uop_debug_fuType,
  input            io_enq_2_bits_uop_debug_sim_trig,
  input  [4:0]     io_enq_2_bits_uop_numLsElem,
  input  [49:0]    io_enq_2_bits_vaddr,
  input  [15:0]    io_enq_2_bits_mask,
  input            io_enq_2_bits_isvec,
  input            io_enq_2_bits_is128bit,
  input  [7:0]     io_enq_2_bits_elemIdx,
  input  [2:0]     io_enq_2_bits_alignedType,
  input  [3:0]     io_enq_2_bits_mbIndex,
  input  [3:0]     io_enq_2_bits_reg_offset,
  input  [7:0]     io_enq_2_bits_elemIdxInsideVd,
  input            io_enq_2_bits_vecActive,
  input            io_enq_2_bits_isLoadReplay,
  input            io_enq_2_bits_handledByMSHR,
  input  [6:0]     io_enq_2_bits_schedIndex,
  input  [3:0]     io_enq_2_bits_rep_info_mshr_id,
  input            io_enq_2_bits_rep_info_full_fwd,
  input            io_enq_2_bits_rep_info_data_inv_sq_idx_flag,
  input  [5:0]     io_enq_2_bits_rep_info_data_inv_sq_idx_value,
  input            io_enq_2_bits_rep_info_addr_inv_sq_idx_flag,
  input  [5:0]     io_enq_2_bits_rep_info_addr_inv_sq_idx_value,
  input            io_enq_2_bits_rep_info_last_beat,
  input            io_enq_2_bits_rep_info_cause_0,
  input            io_enq_2_bits_rep_info_cause_1,
  input            io_enq_2_bits_rep_info_cause_2,
  input            io_enq_2_bits_rep_info_cause_3,
  input            io_enq_2_bits_rep_info_cause_4,
  input            io_enq_2_bits_rep_info_cause_5,
  input            io_enq_2_bits_rep_info_cause_6,
  input            io_enq_2_bits_rep_info_cause_7,
  input            io_enq_2_bits_rep_info_cause_8,
  input            io_enq_2_bits_rep_info_cause_9,
  input            io_enq_2_bits_rep_info_cause_10,
  input  [3:0]     io_enq_2_bits_rep_info_tlb_id,
  input            io_enq_2_bits_rep_info_tlb_full,
  input            io_storeAddrIn_0_valid,
  input            io_storeAddrIn_0_bits_uop_sqIdx_flag,
  input  [5:0]     io_storeAddrIn_0_bits_uop_sqIdx_value,
  input            io_storeAddrIn_0_bits_miss,
  input            io_storeAddrIn_1_valid,
  input            io_storeAddrIn_1_bits_uop_sqIdx_flag,
  input  [5:0]     io_storeAddrIn_1_bits_uop_sqIdx_value,
  input            io_storeAddrIn_1_bits_miss,
  input            io_storeDataIn_0_valid,
  input            io_storeDataIn_0_bits_uop_sqIdx_flag,
  input  [5:0]     io_storeDataIn_0_bits_uop_sqIdx_value,
  input            io_storeDataIn_1_valid,
  input            io_storeDataIn_1_bits_uop_sqIdx_flag,
  input  [5:0]     io_storeDataIn_1_bits_uop_sqIdx_value,
  input            io_replay_0_ready,
  output           io_replay_0_valid,
  output [31:0]    io_replay_0_bits_uop_instr,
  output [49:0]    io_replay_0_bits_uop_pc,
  output [9:0]     io_replay_0_bits_uop_foldpc,
  output           io_replay_0_bits_uop_exceptionVec_0,
  output           io_replay_0_bits_uop_exceptionVec_1,
  output           io_replay_0_bits_uop_exceptionVec_2,
  output           io_replay_0_bits_uop_exceptionVec_3,
  output           io_replay_0_bits_uop_exceptionVec_5,
  output           io_replay_0_bits_uop_exceptionVec_6,
  output           io_replay_0_bits_uop_exceptionVec_7,
  output           io_replay_0_bits_uop_exceptionVec_8,
  output           io_replay_0_bits_uop_exceptionVec_9,
  output           io_replay_0_bits_uop_exceptionVec_10,
  output           io_replay_0_bits_uop_exceptionVec_11,
  output           io_replay_0_bits_uop_exceptionVec_12,
  output           io_replay_0_bits_uop_exceptionVec_13,
  output           io_replay_0_bits_uop_exceptionVec_14,
  output           io_replay_0_bits_uop_exceptionVec_15,
  output           io_replay_0_bits_uop_exceptionVec_16,
  output           io_replay_0_bits_uop_exceptionVec_17,
  output           io_replay_0_bits_uop_exceptionVec_18,
  output           io_replay_0_bits_uop_exceptionVec_19,
  output           io_replay_0_bits_uop_exceptionVec_20,
  output           io_replay_0_bits_uop_exceptionVec_21,
  output           io_replay_0_bits_uop_exceptionVec_22,
  output           io_replay_0_bits_uop_exceptionVec_23,
  output           io_replay_0_bits_uop_isFetchMalAddr,
  output           io_replay_0_bits_uop_hasException,
  output [3:0]     io_replay_0_bits_uop_trigger,
  output           io_replay_0_bits_uop_preDecodeInfo_valid,
  output           io_replay_0_bits_uop_preDecodeInfo_isRVC,
  output [1:0]     io_replay_0_bits_uop_preDecodeInfo_brType,
  output           io_replay_0_bits_uop_preDecodeInfo_isCall,
  output           io_replay_0_bits_uop_preDecodeInfo_isRet,
  output           io_replay_0_bits_uop_pred_taken,
  output           io_replay_0_bits_uop_crossPageIPFFix,
  output           io_replay_0_bits_uop_ftqPtr_flag,
  output [5:0]     io_replay_0_bits_uop_ftqPtr_value,
  output [3:0]     io_replay_0_bits_uop_ftqOffset,
  output           io_replay_0_bits_uop_satpFlushFirstFetchFault,
  output [3:0]     io_replay_0_bits_uop_srcType_0,
  output [3:0]     io_replay_0_bits_uop_srcType_1,
  output [3:0]     io_replay_0_bits_uop_srcType_2,
  output [3:0]     io_replay_0_bits_uop_srcType_3,
  output [3:0]     io_replay_0_bits_uop_srcType_4,
  output [5:0]     io_replay_0_bits_uop_ldest,
  output [34:0]    io_replay_0_bits_uop_fuType,
  output [8:0]     io_replay_0_bits_uop_fuOpType,
  output           io_replay_0_bits_uop_rfWen,
  output           io_replay_0_bits_uop_fpWen,
  output           io_replay_0_bits_uop_vecWen,
  output           io_replay_0_bits_uop_v0Wen,
  output           io_replay_0_bits_uop_vlWen,
  output           io_replay_0_bits_uop_isXSTrap,
  output           io_replay_0_bits_uop_waitForward,
  output           io_replay_0_bits_uop_blockBackward,
  output           io_replay_0_bits_uop_canRobCompress,
  output [3:0]     io_replay_0_bits_uop_selImm,
  output [31:0]    io_replay_0_bits_uop_imm,
  output [1:0]     io_replay_0_bits_uop_fpu_typeTagOut,
  output           io_replay_0_bits_uop_fpu_wflags,
  output [1:0]     io_replay_0_bits_uop_fpu_typ,
  output [1:0]     io_replay_0_bits_uop_fpu_fmt,
  output [2:0]     io_replay_0_bits_uop_fpu_rm,
  output           io_replay_0_bits_uop_vpu_vill,
  output           io_replay_0_bits_uop_vpu_vma,
  output           io_replay_0_bits_uop_vpu_vta,
  output [1:0]     io_replay_0_bits_uop_vpu_vsew,
  output [2:0]     io_replay_0_bits_uop_vpu_vlmul,
  output           io_replay_0_bits_uop_vpu_specVill,
  output           io_replay_0_bits_uop_vpu_specVma,
  output           io_replay_0_bits_uop_vpu_specVta,
  output [1:0]     io_replay_0_bits_uop_vpu_specVsew,
  output [2:0]     io_replay_0_bits_uop_vpu_specVlmul,
  output           io_replay_0_bits_uop_vpu_vm,
  output [7:0]     io_replay_0_bits_uop_vpu_vstart,
  output [2:0]     io_replay_0_bits_uop_vpu_frm,
  output           io_replay_0_bits_uop_vpu_fpu_isFpToVecInst,
  output           io_replay_0_bits_uop_vpu_fpu_isFP32Instr,
  output           io_replay_0_bits_uop_vpu_fpu_isFP64Instr,
  output           io_replay_0_bits_uop_vpu_fpu_isReduction,
  output           io_replay_0_bits_uop_vpu_fpu_isFoldTo1_2,
  output           io_replay_0_bits_uop_vpu_fpu_isFoldTo1_4,
  output           io_replay_0_bits_uop_vpu_fpu_isFoldTo1_8,
  output [1:0]     io_replay_0_bits_uop_vpu_vxrm,
  output [6:0]     io_replay_0_bits_uop_vpu_vuopIdx,
  output           io_replay_0_bits_uop_vpu_lastUop,
  output [127:0]   io_replay_0_bits_uop_vpu_vmask,
  output [7:0]     io_replay_0_bits_uop_vpu_vl,
  output [2:0]     io_replay_0_bits_uop_vpu_nf,
  output [1:0]     io_replay_0_bits_uop_vpu_veew,
  output           io_replay_0_bits_uop_vpu_isReverse,
  output           io_replay_0_bits_uop_vpu_isExt,
  output           io_replay_0_bits_uop_vpu_isNarrow,
  output           io_replay_0_bits_uop_vpu_isDstMask,
  output           io_replay_0_bits_uop_vpu_isOpMask,
  output           io_replay_0_bits_uop_vpu_isMove,
  output           io_replay_0_bits_uop_vpu_isDependOldVd,
  output           io_replay_0_bits_uop_vpu_isWritePartVd,
  output           io_replay_0_bits_uop_vpu_isVleff,
  output           io_replay_0_bits_uop_vlsInstr,
  output           io_replay_0_bits_uop_wfflags,
  output           io_replay_0_bits_uop_isMove,
  output           io_replay_0_bits_uop_isDropAmocasSta,
  output [6:0]     io_replay_0_bits_uop_uopIdx,
  output           io_replay_0_bits_uop_isVset,
  output           io_replay_0_bits_uop_firstUop,
  output           io_replay_0_bits_uop_lastUop,
  output [6:0]     io_replay_0_bits_uop_numUops,
  output [6:0]     io_replay_0_bits_uop_numWB,
  output [2:0]     io_replay_0_bits_uop_commitType,
  output           io_replay_0_bits_uop_srcState_0,
  output           io_replay_0_bits_uop_srcState_1,
  output           io_replay_0_bits_uop_srcState_2,
  output           io_replay_0_bits_uop_srcState_3,
  output           io_replay_0_bits_uop_srcState_4,
  output [1:0]     io_replay_0_bits_uop_srcLoadDependency_0_0,
  output [1:0]     io_replay_0_bits_uop_srcLoadDependency_0_1,
  output [1:0]     io_replay_0_bits_uop_srcLoadDependency_0_2,
  output [1:0]     io_replay_0_bits_uop_srcLoadDependency_1_0,
  output [1:0]     io_replay_0_bits_uop_srcLoadDependency_1_1,
  output [1:0]     io_replay_0_bits_uop_srcLoadDependency_1_2,
  output [1:0]     io_replay_0_bits_uop_srcLoadDependency_2_0,
  output [1:0]     io_replay_0_bits_uop_srcLoadDependency_2_1,
  output [1:0]     io_replay_0_bits_uop_srcLoadDependency_2_2,
  output [1:0]     io_replay_0_bits_uop_srcLoadDependency_3_0,
  output [1:0]     io_replay_0_bits_uop_srcLoadDependency_3_1,
  output [1:0]     io_replay_0_bits_uop_srcLoadDependency_3_2,
  output [1:0]     io_replay_0_bits_uop_srcLoadDependency_4_0,
  output [1:0]     io_replay_0_bits_uop_srcLoadDependency_4_1,
  output [1:0]     io_replay_0_bits_uop_srcLoadDependency_4_2,
  output [7:0]     io_replay_0_bits_uop_psrc_0,
  output [7:0]     io_replay_0_bits_uop_psrc_1,
  output [7:0]     io_replay_0_bits_uop_psrc_2,
  output [7:0]     io_replay_0_bits_uop_psrc_3,
  output [7:0]     io_replay_0_bits_uop_psrc_4,
  output [7:0]     io_replay_0_bits_uop_pdest,
  output           io_replay_0_bits_uop_useRegCache_0,
  output           io_replay_0_bits_uop_useRegCache_1,
  output [4:0]     io_replay_0_bits_uop_regCacheIdx_0,
  output [4:0]     io_replay_0_bits_uop_regCacheIdx_1,
  output           io_replay_0_bits_uop_robIdx_flag,
  output [7:0]     io_replay_0_bits_uop_robIdx_value,
  output [2:0]     io_replay_0_bits_uop_instrSize,
  output           io_replay_0_bits_uop_dirtyFs,
  output           io_replay_0_bits_uop_dirtyVs,
  output [3:0]     io_replay_0_bits_uop_traceBlockInPipe_itype,
  output [3:0]     io_replay_0_bits_uop_traceBlockInPipe_iretire,
  output           io_replay_0_bits_uop_traceBlockInPipe_ilastsize,
  output           io_replay_0_bits_uop_eliminatedMove,
  output           io_replay_0_bits_uop_snapshot,
  output           io_replay_0_bits_uop_debugInfo_eliminatedMove,
  output [63:0]    io_replay_0_bits_uop_debugInfo_renameTime,
  output [63:0]    io_replay_0_bits_uop_debugInfo_dispatchTime,
  output [63:0]    io_replay_0_bits_uop_debugInfo_enqRsTime,
  output [63:0]    io_replay_0_bits_uop_debugInfo_selectTime,
  output [63:0]    io_replay_0_bits_uop_debugInfo_issueTime,
  output [63:0]    io_replay_0_bits_uop_debugInfo_writebackTime,
  output [63:0]    io_replay_0_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]    io_replay_0_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]    io_replay_0_bits_uop_debugInfo_tlbRespTime,
  output [55:0]    io_replay_0_bits_uop_debug_seqNum_seqNum,
  output [7:0]     io_replay_0_bits_uop_debug_seqNum_uopIdx,
  output           io_replay_0_bits_uop_storeSetHit,
  output           io_replay_0_bits_uop_waitForRobIdx_flag,
  output [7:0]     io_replay_0_bits_uop_waitForRobIdx_value,
  output           io_replay_0_bits_uop_loadWaitBit,
  output [4:0]     io_replay_0_bits_uop_ssid,
  output           io_replay_0_bits_uop_lqIdx_flag,
  output [6:0]     io_replay_0_bits_uop_lqIdx_value,
  output           io_replay_0_bits_uop_sqIdx_flag,
  output [5:0]     io_replay_0_bits_uop_sqIdx_value,
  output           io_replay_0_bits_uop_singleStep,
  output [34:0]    io_replay_0_bits_uop_debug_fuType,
  output           io_replay_0_bits_uop_debug_sim_trig,
  output [4:0]     io_replay_0_bits_uop_numLsElem,
  output [49:0]    io_replay_0_bits_vaddr,
  output [15:0]    io_replay_0_bits_mask,
  output           io_replay_0_bits_isvec,
  output           io_replay_0_bits_is128bit,
  output [7:0]     io_replay_0_bits_elemIdx,
  output [2:0]     io_replay_0_bits_alignedType,
  output [3:0]     io_replay_0_bits_mbIndex,
  output [3:0]     io_replay_0_bits_reg_offset,
  output [7:0]     io_replay_0_bits_elemIdxInsideVd,
  output           io_replay_0_bits_vecActive,
  output [3:0]     io_replay_0_bits_mshrid,
  output           io_replay_0_bits_forward_tlDchannel,
  output [6:0]     io_replay_0_bits_schedIndex,
  input            io_replay_1_ready,
  output           io_replay_1_valid,
  output [31:0]    io_replay_1_bits_uop_instr,
  output [49:0]    io_replay_1_bits_uop_pc,
  output [9:0]     io_replay_1_bits_uop_foldpc,
  output           io_replay_1_bits_uop_exceptionVec_0,
  output           io_replay_1_bits_uop_exceptionVec_1,
  output           io_replay_1_bits_uop_exceptionVec_2,
  output           io_replay_1_bits_uop_exceptionVec_3,
  output           io_replay_1_bits_uop_exceptionVec_5,
  output           io_replay_1_bits_uop_exceptionVec_6,
  output           io_replay_1_bits_uop_exceptionVec_7,
  output           io_replay_1_bits_uop_exceptionVec_8,
  output           io_replay_1_bits_uop_exceptionVec_9,
  output           io_replay_1_bits_uop_exceptionVec_10,
  output           io_replay_1_bits_uop_exceptionVec_11,
  output           io_replay_1_bits_uop_exceptionVec_12,
  output           io_replay_1_bits_uop_exceptionVec_13,
  output           io_replay_1_bits_uop_exceptionVec_14,
  output           io_replay_1_bits_uop_exceptionVec_15,
  output           io_replay_1_bits_uop_exceptionVec_16,
  output           io_replay_1_bits_uop_exceptionVec_17,
  output           io_replay_1_bits_uop_exceptionVec_18,
  output           io_replay_1_bits_uop_exceptionVec_19,
  output           io_replay_1_bits_uop_exceptionVec_20,
  output           io_replay_1_bits_uop_exceptionVec_21,
  output           io_replay_1_bits_uop_exceptionVec_22,
  output           io_replay_1_bits_uop_exceptionVec_23,
  output           io_replay_1_bits_uop_isFetchMalAddr,
  output           io_replay_1_bits_uop_hasException,
  output [3:0]     io_replay_1_bits_uop_trigger,
  output           io_replay_1_bits_uop_preDecodeInfo_valid,
  output           io_replay_1_bits_uop_preDecodeInfo_isRVC,
  output [1:0]     io_replay_1_bits_uop_preDecodeInfo_brType,
  output           io_replay_1_bits_uop_preDecodeInfo_isCall,
  output           io_replay_1_bits_uop_preDecodeInfo_isRet,
  output           io_replay_1_bits_uop_pred_taken,
  output           io_replay_1_bits_uop_crossPageIPFFix,
  output           io_replay_1_bits_uop_ftqPtr_flag,
  output [5:0]     io_replay_1_bits_uop_ftqPtr_value,
  output [3:0]     io_replay_1_bits_uop_ftqOffset,
  output           io_replay_1_bits_uop_satpFlushFirstFetchFault,
  output [3:0]     io_replay_1_bits_uop_srcType_0,
  output [3:0]     io_replay_1_bits_uop_srcType_1,
  output [3:0]     io_replay_1_bits_uop_srcType_2,
  output [3:0]     io_replay_1_bits_uop_srcType_3,
  output [3:0]     io_replay_1_bits_uop_srcType_4,
  output [5:0]     io_replay_1_bits_uop_ldest,
  output [34:0]    io_replay_1_bits_uop_fuType,
  output [8:0]     io_replay_1_bits_uop_fuOpType,
  output           io_replay_1_bits_uop_rfWen,
  output           io_replay_1_bits_uop_fpWen,
  output           io_replay_1_bits_uop_vecWen,
  output           io_replay_1_bits_uop_v0Wen,
  output           io_replay_1_bits_uop_vlWen,
  output           io_replay_1_bits_uop_isXSTrap,
  output           io_replay_1_bits_uop_waitForward,
  output           io_replay_1_bits_uop_blockBackward,
  output           io_replay_1_bits_uop_canRobCompress,
  output [3:0]     io_replay_1_bits_uop_selImm,
  output [31:0]    io_replay_1_bits_uop_imm,
  output [1:0]     io_replay_1_bits_uop_fpu_typeTagOut,
  output           io_replay_1_bits_uop_fpu_wflags,
  output [1:0]     io_replay_1_bits_uop_fpu_typ,
  output [1:0]     io_replay_1_bits_uop_fpu_fmt,
  output [2:0]     io_replay_1_bits_uop_fpu_rm,
  output           io_replay_1_bits_uop_vpu_vill,
  output           io_replay_1_bits_uop_vpu_vma,
  output           io_replay_1_bits_uop_vpu_vta,
  output [1:0]     io_replay_1_bits_uop_vpu_vsew,
  output [2:0]     io_replay_1_bits_uop_vpu_vlmul,
  output           io_replay_1_bits_uop_vpu_specVill,
  output           io_replay_1_bits_uop_vpu_specVma,
  output           io_replay_1_bits_uop_vpu_specVta,
  output [1:0]     io_replay_1_bits_uop_vpu_specVsew,
  output [2:0]     io_replay_1_bits_uop_vpu_specVlmul,
  output           io_replay_1_bits_uop_vpu_vm,
  output [7:0]     io_replay_1_bits_uop_vpu_vstart,
  output [2:0]     io_replay_1_bits_uop_vpu_frm,
  output           io_replay_1_bits_uop_vpu_fpu_isFpToVecInst,
  output           io_replay_1_bits_uop_vpu_fpu_isFP32Instr,
  output           io_replay_1_bits_uop_vpu_fpu_isFP64Instr,
  output           io_replay_1_bits_uop_vpu_fpu_isReduction,
  output           io_replay_1_bits_uop_vpu_fpu_isFoldTo1_2,
  output           io_replay_1_bits_uop_vpu_fpu_isFoldTo1_4,
  output           io_replay_1_bits_uop_vpu_fpu_isFoldTo1_8,
  output [1:0]     io_replay_1_bits_uop_vpu_vxrm,
  output [6:0]     io_replay_1_bits_uop_vpu_vuopIdx,
  output           io_replay_1_bits_uop_vpu_lastUop,
  output [127:0]   io_replay_1_bits_uop_vpu_vmask,
  output [7:0]     io_replay_1_bits_uop_vpu_vl,
  output [2:0]     io_replay_1_bits_uop_vpu_nf,
  output [1:0]     io_replay_1_bits_uop_vpu_veew,
  output           io_replay_1_bits_uop_vpu_isReverse,
  output           io_replay_1_bits_uop_vpu_isExt,
  output           io_replay_1_bits_uop_vpu_isNarrow,
  output           io_replay_1_bits_uop_vpu_isDstMask,
  output           io_replay_1_bits_uop_vpu_isOpMask,
  output           io_replay_1_bits_uop_vpu_isMove,
  output           io_replay_1_bits_uop_vpu_isDependOldVd,
  output           io_replay_1_bits_uop_vpu_isWritePartVd,
  output           io_replay_1_bits_uop_vpu_isVleff,
  output           io_replay_1_bits_uop_vlsInstr,
  output           io_replay_1_bits_uop_wfflags,
  output           io_replay_1_bits_uop_isMove,
  output           io_replay_1_bits_uop_isDropAmocasSta,
  output [6:0]     io_replay_1_bits_uop_uopIdx,
  output           io_replay_1_bits_uop_isVset,
  output           io_replay_1_bits_uop_firstUop,
  output           io_replay_1_bits_uop_lastUop,
  output [6:0]     io_replay_1_bits_uop_numUops,
  output [6:0]     io_replay_1_bits_uop_numWB,
  output [2:0]     io_replay_1_bits_uop_commitType,
  output           io_replay_1_bits_uop_srcState_0,
  output           io_replay_1_bits_uop_srcState_1,
  output           io_replay_1_bits_uop_srcState_2,
  output           io_replay_1_bits_uop_srcState_3,
  output           io_replay_1_bits_uop_srcState_4,
  output [1:0]     io_replay_1_bits_uop_srcLoadDependency_0_0,
  output [1:0]     io_replay_1_bits_uop_srcLoadDependency_0_1,
  output [1:0]     io_replay_1_bits_uop_srcLoadDependency_0_2,
  output [1:0]     io_replay_1_bits_uop_srcLoadDependency_1_0,
  output [1:0]     io_replay_1_bits_uop_srcLoadDependency_1_1,
  output [1:0]     io_replay_1_bits_uop_srcLoadDependency_1_2,
  output [1:0]     io_replay_1_bits_uop_srcLoadDependency_2_0,
  output [1:0]     io_replay_1_bits_uop_srcLoadDependency_2_1,
  output [1:0]     io_replay_1_bits_uop_srcLoadDependency_2_2,
  output [1:0]     io_replay_1_bits_uop_srcLoadDependency_3_0,
  output [1:0]     io_replay_1_bits_uop_srcLoadDependency_3_1,
  output [1:0]     io_replay_1_bits_uop_srcLoadDependency_3_2,
  output [1:0]     io_replay_1_bits_uop_srcLoadDependency_4_0,
  output [1:0]     io_replay_1_bits_uop_srcLoadDependency_4_1,
  output [1:0]     io_replay_1_bits_uop_srcLoadDependency_4_2,
  output [7:0]     io_replay_1_bits_uop_psrc_0,
  output [7:0]     io_replay_1_bits_uop_psrc_1,
  output [7:0]     io_replay_1_bits_uop_psrc_2,
  output [7:0]     io_replay_1_bits_uop_psrc_3,
  output [7:0]     io_replay_1_bits_uop_psrc_4,
  output [7:0]     io_replay_1_bits_uop_pdest,
  output           io_replay_1_bits_uop_useRegCache_0,
  output           io_replay_1_bits_uop_useRegCache_1,
  output [4:0]     io_replay_1_bits_uop_regCacheIdx_0,
  output [4:0]     io_replay_1_bits_uop_regCacheIdx_1,
  output           io_replay_1_bits_uop_robIdx_flag,
  output [7:0]     io_replay_1_bits_uop_robIdx_value,
  output [2:0]     io_replay_1_bits_uop_instrSize,
  output           io_replay_1_bits_uop_dirtyFs,
  output           io_replay_1_bits_uop_dirtyVs,
  output [3:0]     io_replay_1_bits_uop_traceBlockInPipe_itype,
  output [3:0]     io_replay_1_bits_uop_traceBlockInPipe_iretire,
  output           io_replay_1_bits_uop_traceBlockInPipe_ilastsize,
  output           io_replay_1_bits_uop_eliminatedMove,
  output           io_replay_1_bits_uop_snapshot,
  output           io_replay_1_bits_uop_debugInfo_eliminatedMove,
  output [63:0]    io_replay_1_bits_uop_debugInfo_renameTime,
  output [63:0]    io_replay_1_bits_uop_debugInfo_dispatchTime,
  output [63:0]    io_replay_1_bits_uop_debugInfo_enqRsTime,
  output [63:0]    io_replay_1_bits_uop_debugInfo_selectTime,
  output [63:0]    io_replay_1_bits_uop_debugInfo_issueTime,
  output [63:0]    io_replay_1_bits_uop_debugInfo_writebackTime,
  output [63:0]    io_replay_1_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]    io_replay_1_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]    io_replay_1_bits_uop_debugInfo_tlbRespTime,
  output [55:0]    io_replay_1_bits_uop_debug_seqNum_seqNum,
  output [7:0]     io_replay_1_bits_uop_debug_seqNum_uopIdx,
  output           io_replay_1_bits_uop_storeSetHit,
  output           io_replay_1_bits_uop_waitForRobIdx_flag,
  output [7:0]     io_replay_1_bits_uop_waitForRobIdx_value,
  output           io_replay_1_bits_uop_loadWaitBit,
  output [4:0]     io_replay_1_bits_uop_ssid,
  output           io_replay_1_bits_uop_lqIdx_flag,
  output [6:0]     io_replay_1_bits_uop_lqIdx_value,
  output           io_replay_1_bits_uop_sqIdx_flag,
  output [5:0]     io_replay_1_bits_uop_sqIdx_value,
  output           io_replay_1_bits_uop_singleStep,
  output [34:0]    io_replay_1_bits_uop_debug_fuType,
  output           io_replay_1_bits_uop_debug_sim_trig,
  output [4:0]     io_replay_1_bits_uop_numLsElem,
  output [49:0]    io_replay_1_bits_vaddr,
  output [15:0]    io_replay_1_bits_mask,
  output           io_replay_1_bits_isvec,
  output           io_replay_1_bits_is128bit,
  output [7:0]     io_replay_1_bits_elemIdx,
  output [2:0]     io_replay_1_bits_alignedType,
  output [3:0]     io_replay_1_bits_mbIndex,
  output [3:0]     io_replay_1_bits_reg_offset,
  output [7:0]     io_replay_1_bits_elemIdxInsideVd,
  output           io_replay_1_bits_vecActive,
  output [3:0]     io_replay_1_bits_mshrid,
  output           io_replay_1_bits_forward_tlDchannel,
  output [6:0]     io_replay_1_bits_schedIndex,
  input            io_replay_2_ready,
  output           io_replay_2_valid,
  output [31:0]    io_replay_2_bits_uop_instr,
  output [49:0]    io_replay_2_bits_uop_pc,
  output [9:0]     io_replay_2_bits_uop_foldpc,
  output           io_replay_2_bits_uop_exceptionVec_0,
  output           io_replay_2_bits_uop_exceptionVec_1,
  output           io_replay_2_bits_uop_exceptionVec_2,
  output           io_replay_2_bits_uop_exceptionVec_3,
  output           io_replay_2_bits_uop_exceptionVec_5,
  output           io_replay_2_bits_uop_exceptionVec_6,
  output           io_replay_2_bits_uop_exceptionVec_7,
  output           io_replay_2_bits_uop_exceptionVec_8,
  output           io_replay_2_bits_uop_exceptionVec_9,
  output           io_replay_2_bits_uop_exceptionVec_10,
  output           io_replay_2_bits_uop_exceptionVec_11,
  output           io_replay_2_bits_uop_exceptionVec_12,
  output           io_replay_2_bits_uop_exceptionVec_13,
  output           io_replay_2_bits_uop_exceptionVec_14,
  output           io_replay_2_bits_uop_exceptionVec_15,
  output           io_replay_2_bits_uop_exceptionVec_16,
  output           io_replay_2_bits_uop_exceptionVec_17,
  output           io_replay_2_bits_uop_exceptionVec_18,
  output           io_replay_2_bits_uop_exceptionVec_19,
  output           io_replay_2_bits_uop_exceptionVec_20,
  output           io_replay_2_bits_uop_exceptionVec_21,
  output           io_replay_2_bits_uop_exceptionVec_22,
  output           io_replay_2_bits_uop_exceptionVec_23,
  output           io_replay_2_bits_uop_isFetchMalAddr,
  output           io_replay_2_bits_uop_hasException,
  output [3:0]     io_replay_2_bits_uop_trigger,
  output           io_replay_2_bits_uop_preDecodeInfo_valid,
  output           io_replay_2_bits_uop_preDecodeInfo_isRVC,
  output [1:0]     io_replay_2_bits_uop_preDecodeInfo_brType,
  output           io_replay_2_bits_uop_preDecodeInfo_isCall,
  output           io_replay_2_bits_uop_preDecodeInfo_isRet,
  output           io_replay_2_bits_uop_pred_taken,
  output           io_replay_2_bits_uop_crossPageIPFFix,
  output           io_replay_2_bits_uop_ftqPtr_flag,
  output [5:0]     io_replay_2_bits_uop_ftqPtr_value,
  output [3:0]     io_replay_2_bits_uop_ftqOffset,
  output           io_replay_2_bits_uop_satpFlushFirstFetchFault,
  output [3:0]     io_replay_2_bits_uop_srcType_0,
  output [3:0]     io_replay_2_bits_uop_srcType_1,
  output [3:0]     io_replay_2_bits_uop_srcType_2,
  output [3:0]     io_replay_2_bits_uop_srcType_3,
  output [3:0]     io_replay_2_bits_uop_srcType_4,
  output [5:0]     io_replay_2_bits_uop_ldest,
  output [34:0]    io_replay_2_bits_uop_fuType,
  output [8:0]     io_replay_2_bits_uop_fuOpType,
  output           io_replay_2_bits_uop_rfWen,
  output           io_replay_2_bits_uop_fpWen,
  output           io_replay_2_bits_uop_vecWen,
  output           io_replay_2_bits_uop_v0Wen,
  output           io_replay_2_bits_uop_vlWen,
  output           io_replay_2_bits_uop_isXSTrap,
  output           io_replay_2_bits_uop_waitForward,
  output           io_replay_2_bits_uop_blockBackward,
  output           io_replay_2_bits_uop_canRobCompress,
  output [3:0]     io_replay_2_bits_uop_selImm,
  output [31:0]    io_replay_2_bits_uop_imm,
  output [1:0]     io_replay_2_bits_uop_fpu_typeTagOut,
  output           io_replay_2_bits_uop_fpu_wflags,
  output [1:0]     io_replay_2_bits_uop_fpu_typ,
  output [1:0]     io_replay_2_bits_uop_fpu_fmt,
  output [2:0]     io_replay_2_bits_uop_fpu_rm,
  output           io_replay_2_bits_uop_vpu_vill,
  output           io_replay_2_bits_uop_vpu_vma,
  output           io_replay_2_bits_uop_vpu_vta,
  output [1:0]     io_replay_2_bits_uop_vpu_vsew,
  output [2:0]     io_replay_2_bits_uop_vpu_vlmul,
  output           io_replay_2_bits_uop_vpu_specVill,
  output           io_replay_2_bits_uop_vpu_specVma,
  output           io_replay_2_bits_uop_vpu_specVta,
  output [1:0]     io_replay_2_bits_uop_vpu_specVsew,
  output [2:0]     io_replay_2_bits_uop_vpu_specVlmul,
  output           io_replay_2_bits_uop_vpu_vm,
  output [7:0]     io_replay_2_bits_uop_vpu_vstart,
  output [2:0]     io_replay_2_bits_uop_vpu_frm,
  output           io_replay_2_bits_uop_vpu_fpu_isFpToVecInst,
  output           io_replay_2_bits_uop_vpu_fpu_isFP32Instr,
  output           io_replay_2_bits_uop_vpu_fpu_isFP64Instr,
  output           io_replay_2_bits_uop_vpu_fpu_isReduction,
  output           io_replay_2_bits_uop_vpu_fpu_isFoldTo1_2,
  output           io_replay_2_bits_uop_vpu_fpu_isFoldTo1_4,
  output           io_replay_2_bits_uop_vpu_fpu_isFoldTo1_8,
  output [1:0]     io_replay_2_bits_uop_vpu_vxrm,
  output [6:0]     io_replay_2_bits_uop_vpu_vuopIdx,
  output           io_replay_2_bits_uop_vpu_lastUop,
  output [127:0]   io_replay_2_bits_uop_vpu_vmask,
  output [7:0]     io_replay_2_bits_uop_vpu_vl,
  output [2:0]     io_replay_2_bits_uop_vpu_nf,
  output [1:0]     io_replay_2_bits_uop_vpu_veew,
  output           io_replay_2_bits_uop_vpu_isReverse,
  output           io_replay_2_bits_uop_vpu_isExt,
  output           io_replay_2_bits_uop_vpu_isNarrow,
  output           io_replay_2_bits_uop_vpu_isDstMask,
  output           io_replay_2_bits_uop_vpu_isOpMask,
  output           io_replay_2_bits_uop_vpu_isMove,
  output           io_replay_2_bits_uop_vpu_isDependOldVd,
  output           io_replay_2_bits_uop_vpu_isWritePartVd,
  output           io_replay_2_bits_uop_vpu_isVleff,
  output           io_replay_2_bits_uop_vlsInstr,
  output           io_replay_2_bits_uop_wfflags,
  output           io_replay_2_bits_uop_isMove,
  output           io_replay_2_bits_uop_isDropAmocasSta,
  output [6:0]     io_replay_2_bits_uop_uopIdx,
  output           io_replay_2_bits_uop_isVset,
  output           io_replay_2_bits_uop_firstUop,
  output           io_replay_2_bits_uop_lastUop,
  output [6:0]     io_replay_2_bits_uop_numUops,
  output [6:0]     io_replay_2_bits_uop_numWB,
  output [2:0]     io_replay_2_bits_uop_commitType,
  output           io_replay_2_bits_uop_srcState_0,
  output           io_replay_2_bits_uop_srcState_1,
  output           io_replay_2_bits_uop_srcState_2,
  output           io_replay_2_bits_uop_srcState_3,
  output           io_replay_2_bits_uop_srcState_4,
  output [1:0]     io_replay_2_bits_uop_srcLoadDependency_0_0,
  output [1:0]     io_replay_2_bits_uop_srcLoadDependency_0_1,
  output [1:0]     io_replay_2_bits_uop_srcLoadDependency_0_2,
  output [1:0]     io_replay_2_bits_uop_srcLoadDependency_1_0,
  output [1:0]     io_replay_2_bits_uop_srcLoadDependency_1_1,
  output [1:0]     io_replay_2_bits_uop_srcLoadDependency_1_2,
  output [1:0]     io_replay_2_bits_uop_srcLoadDependency_2_0,
  output [1:0]     io_replay_2_bits_uop_srcLoadDependency_2_1,
  output [1:0]     io_replay_2_bits_uop_srcLoadDependency_2_2,
  output [1:0]     io_replay_2_bits_uop_srcLoadDependency_3_0,
  output [1:0]     io_replay_2_bits_uop_srcLoadDependency_3_1,
  output [1:0]     io_replay_2_bits_uop_srcLoadDependency_3_2,
  output [1:0]     io_replay_2_bits_uop_srcLoadDependency_4_0,
  output [1:0]     io_replay_2_bits_uop_srcLoadDependency_4_1,
  output [1:0]     io_replay_2_bits_uop_srcLoadDependency_4_2,
  output [7:0]     io_replay_2_bits_uop_psrc_0,
  output [7:0]     io_replay_2_bits_uop_psrc_1,
  output [7:0]     io_replay_2_bits_uop_psrc_2,
  output [7:0]     io_replay_2_bits_uop_psrc_3,
  output [7:0]     io_replay_2_bits_uop_psrc_4,
  output [7:0]     io_replay_2_bits_uop_pdest,
  output           io_replay_2_bits_uop_useRegCache_0,
  output           io_replay_2_bits_uop_useRegCache_1,
  output [4:0]     io_replay_2_bits_uop_regCacheIdx_0,
  output [4:0]     io_replay_2_bits_uop_regCacheIdx_1,
  output           io_replay_2_bits_uop_robIdx_flag,
  output [7:0]     io_replay_2_bits_uop_robIdx_value,
  output [2:0]     io_replay_2_bits_uop_instrSize,
  output           io_replay_2_bits_uop_dirtyFs,
  output           io_replay_2_bits_uop_dirtyVs,
  output [3:0]     io_replay_2_bits_uop_traceBlockInPipe_itype,
  output [3:0]     io_replay_2_bits_uop_traceBlockInPipe_iretire,
  output           io_replay_2_bits_uop_traceBlockInPipe_ilastsize,
  output           io_replay_2_bits_uop_eliminatedMove,
  output           io_replay_2_bits_uop_snapshot,
  output           io_replay_2_bits_uop_debugInfo_eliminatedMove,
  output [63:0]    io_replay_2_bits_uop_debugInfo_renameTime,
  output [63:0]    io_replay_2_bits_uop_debugInfo_dispatchTime,
  output [63:0]    io_replay_2_bits_uop_debugInfo_enqRsTime,
  output [63:0]    io_replay_2_bits_uop_debugInfo_selectTime,
  output [63:0]    io_replay_2_bits_uop_debugInfo_issueTime,
  output [63:0]    io_replay_2_bits_uop_debugInfo_writebackTime,
  output [63:0]    io_replay_2_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]    io_replay_2_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]    io_replay_2_bits_uop_debugInfo_tlbRespTime,
  output [55:0]    io_replay_2_bits_uop_debug_seqNum_seqNum,
  output [7:0]     io_replay_2_bits_uop_debug_seqNum_uopIdx,
  output           io_replay_2_bits_uop_storeSetHit,
  output           io_replay_2_bits_uop_waitForRobIdx_flag,
  output [7:0]     io_replay_2_bits_uop_waitForRobIdx_value,
  output           io_replay_2_bits_uop_loadWaitBit,
  output [4:0]     io_replay_2_bits_uop_ssid,
  output           io_replay_2_bits_uop_lqIdx_flag,
  output [6:0]     io_replay_2_bits_uop_lqIdx_value,
  output           io_replay_2_bits_uop_sqIdx_flag,
  output [5:0]     io_replay_2_bits_uop_sqIdx_value,
  output           io_replay_2_bits_uop_singleStep,
  output [34:0]    io_replay_2_bits_uop_debug_fuType,
  output           io_replay_2_bits_uop_debug_sim_trig,
  output [4:0]     io_replay_2_bits_uop_numLsElem,
  output [49:0]    io_replay_2_bits_vaddr,
  output [15:0]    io_replay_2_bits_mask,
  output           io_replay_2_bits_isvec,
  output           io_replay_2_bits_is128bit,
  output [7:0]     io_replay_2_bits_elemIdx,
  output [2:0]     io_replay_2_bits_alignedType,
  output [3:0]     io_replay_2_bits_mbIndex,
  output [3:0]     io_replay_2_bits_reg_offset,
  output [7:0]     io_replay_2_bits_elemIdxInsideVd,
  output           io_replay_2_bits_vecActive,
  output [3:0]     io_replay_2_bits_mshrid,
  output           io_replay_2_bits_forward_tlDchannel,
  output [6:0]     io_replay_2_bits_schedIndex,
  input            io_tl_d_channel_valid,
  input  [3:0]     io_tl_d_channel_mshrid,
  input            io_stAddrReadySqPtr_flag,
  input  [5:0]     io_stAddrReadySqPtr_value,
  input            io_stAddrReadyVec_0,
  input            io_stAddrReadyVec_1,
  input            io_stAddrReadyVec_2,
  input            io_stAddrReadyVec_3,
  input            io_stAddrReadyVec_4,
  input            io_stAddrReadyVec_5,
  input            io_stAddrReadyVec_6,
  input            io_stAddrReadyVec_7,
  input            io_stAddrReadyVec_8,
  input            io_stAddrReadyVec_9,
  input            io_stAddrReadyVec_10,
  input            io_stAddrReadyVec_11,
  input            io_stAddrReadyVec_12,
  input            io_stAddrReadyVec_13,
  input            io_stAddrReadyVec_14,
  input            io_stAddrReadyVec_15,
  input            io_stAddrReadyVec_16,
  input            io_stAddrReadyVec_17,
  input            io_stAddrReadyVec_18,
  input            io_stAddrReadyVec_19,
  input            io_stAddrReadyVec_20,
  input            io_stAddrReadyVec_21,
  input            io_stAddrReadyVec_22,
  input            io_stAddrReadyVec_23,
  input            io_stAddrReadyVec_24,
  input            io_stAddrReadyVec_25,
  input            io_stAddrReadyVec_26,
  input            io_stAddrReadyVec_27,
  input            io_stAddrReadyVec_28,
  input            io_stAddrReadyVec_29,
  input            io_stAddrReadyVec_30,
  input            io_stAddrReadyVec_31,
  input            io_stAddrReadyVec_32,
  input            io_stAddrReadyVec_33,
  input            io_stAddrReadyVec_34,
  input            io_stAddrReadyVec_35,
  input            io_stAddrReadyVec_36,
  input            io_stAddrReadyVec_37,
  input            io_stAddrReadyVec_38,
  input            io_stAddrReadyVec_39,
  input            io_stAddrReadyVec_40,
  input            io_stAddrReadyVec_41,
  input            io_stAddrReadyVec_42,
  input            io_stAddrReadyVec_43,
  input            io_stAddrReadyVec_44,
  input            io_stAddrReadyVec_45,
  input            io_stAddrReadyVec_46,
  input            io_stAddrReadyVec_47,
  input            io_stAddrReadyVec_48,
  input            io_stAddrReadyVec_49,
  input            io_stAddrReadyVec_50,
  input            io_stAddrReadyVec_51,
  input            io_stAddrReadyVec_52,
  input            io_stAddrReadyVec_53,
  input            io_stAddrReadyVec_54,
  input            io_stAddrReadyVec_55,
  input            io_stDataReadySqPtr_flag,
  input  [5:0]     io_stDataReadySqPtr_value,
  input            io_stDataReadyVec_0,
  input            io_stDataReadyVec_1,
  input            io_stDataReadyVec_2,
  input            io_stDataReadyVec_3,
  input            io_stDataReadyVec_4,
  input            io_stDataReadyVec_5,
  input            io_stDataReadyVec_6,
  input            io_stDataReadyVec_7,
  input            io_stDataReadyVec_8,
  input            io_stDataReadyVec_9,
  input            io_stDataReadyVec_10,
  input            io_stDataReadyVec_11,
  input            io_stDataReadyVec_12,
  input            io_stDataReadyVec_13,
  input            io_stDataReadyVec_14,
  input            io_stDataReadyVec_15,
  input            io_stDataReadyVec_16,
  input            io_stDataReadyVec_17,
  input            io_stDataReadyVec_18,
  input            io_stDataReadyVec_19,
  input            io_stDataReadyVec_20,
  input            io_stDataReadyVec_21,
  input            io_stDataReadyVec_22,
  input            io_stDataReadyVec_23,
  input            io_stDataReadyVec_24,
  input            io_stDataReadyVec_25,
  input            io_stDataReadyVec_26,
  input            io_stDataReadyVec_27,
  input            io_stDataReadyVec_28,
  input            io_stDataReadyVec_29,
  input            io_stDataReadyVec_30,
  input            io_stDataReadyVec_31,
  input            io_stDataReadyVec_32,
  input            io_stDataReadyVec_33,
  input            io_stDataReadyVec_34,
  input            io_stDataReadyVec_35,
  input            io_stDataReadyVec_36,
  input            io_stDataReadyVec_37,
  input            io_stDataReadyVec_38,
  input            io_stDataReadyVec_39,
  input            io_stDataReadyVec_40,
  input            io_stDataReadyVec_41,
  input            io_stDataReadyVec_42,
  input            io_stDataReadyVec_43,
  input            io_stDataReadyVec_44,
  input            io_stDataReadyVec_45,
  input            io_stDataReadyVec_46,
  input            io_stDataReadyVec_47,
  input            io_stDataReadyVec_48,
  input            io_stDataReadyVec_49,
  input            io_stDataReadyVec_50,
  input            io_stDataReadyVec_51,
  input            io_stDataReadyVec_52,
  input            io_stDataReadyVec_53,
  input            io_stDataReadyVec_54,
  input            io_stDataReadyVec_55,
  input            io_sqEmpty,
  output           io_lqFull,
  input            io_ldWbPtr_flag,
  input  [6:0]     io_ldWbPtr_value,
  input            io_robDeqPtr_flag,
  input  [7:0]     io_robDeqPtr_value,
  input            io_rarFull,
  input            io_rawFull,
  input            io_l2_hint_valid,
  input  [3:0]     io_l2_hint_bits_sourceId,
  input            io_l2_hint_bits_isKeyword,
  input            io_tlb_hint_resp_valid,
  input  [3:0]     io_tlb_hint_resp_bits_id,
  input            io_tlb_hint_resp_bits_replay_all,
  input            io_debugTopDown_robHeadVaddr_valid,
  input  [49:0]    io_debugTopDown_robHeadVaddr_bits,
  output           io_debugTopDown_robHeadTlbReplay,
  output           io_debugTopDown_robHeadTlbMiss,
  output           io_debugTopDown_robHeadLoadVio,
  output           io_debugTopDown_robHeadLoadMSHR,
  input            io_debugTopDown_robHeadMissInDTlb,
  output           io_replayAllocate,
  output [5:0]     io_perf_0_value,
  output [5:0]     io_perf_1_value,
  output [5:0]     io_perf_2_value,
  output [5:0]     io_perf_3_value,
  output [5:0]     io_perf_4_value,
  output [5:0]     io_perf_5_value,
  output [5:0]     io_perf_6_value,
  output [5:0]     io_perf_7_value,
  output [5:0]     io_perf_8_value,
  output [5:0]     io_perf_9_value,
  output [5:0]     io_perf_10_value,
  output [5:0]     io_perf_11_value,
  output [5:0]     io_perf_12_value
  // END GENERATED
);

  // BEGIN GENERATED(wrapper_body)
  // ---- 核侧信号（struct/数组）----
  logic     [LD_PIPE_W-1:0]                        enq_valid;
  lqr_uop_t [LD_PIPE_W-1:0]                        enq_uop;
  lqr_vec_t [LD_PIPE_W-1:0]                        enq_vec;
  logic     [LD_PIPE_W-1:0][VADDR_BITS-1:0]        enq_vaddr;
  logic     [LD_PIPE_W-1:0]                        enq_isLoadReplay;
  logic     [LD_PIPE_W-1:0]                        enq_handledByMSHR;
  logic     [LD_PIPE_W-1:0][SCHED_IDX_W-1:0]       enq_schedIndex;
  logic     [LD_PIPE_W-1:0][N_CAUSES-1:0]          enq_cause;
  logic     [LD_PIPE_W-1:0][MSHR_ID_W-1:0]         enq_mshr_id;
  logic     [LD_PIPE_W-1:0]                        enq_full_fwd;
  sq_ptr_t  [LD_PIPE_W-1:0]                        enq_data_inv_sq_idx;
  sq_ptr_t  [LD_PIPE_W-1:0]                        enq_addr_inv_sq_idx;
  logic     [LD_PIPE_W-1:0]                        enq_last_beat;
  logic     [LD_PIPE_W-1:0][TLB_ID_W-1:0]          enq_tlb_id;
  logic     [LD_PIPE_W-1:0]                        enq_tlb_full;
  logic     [LD_PIPE_W-1:0]                        replay_valid, replay_ready;
  lqr_uop_t [LD_PIPE_W-1:0]                        replay_uop;
  lqr_vec_t [LD_PIPE_W-1:0]                        replay_vec;
  logic     [LD_PIPE_W-1:0][VADDR_BITS-1:0]        replay_vaddr;
  logic     [LD_PIPE_W-1:0][MSHR_ID_W-1:0]         replay_mshrid;
  logic     [LD_PIPE_W-1:0]                        replay_forward_tlDchannel;
  logic     [LD_PIPE_W-1:0][SCHED_IDX_W-1:0]       replay_schedIndex;
  logic     [VEC_PIPE_W-1:0]                       vecFb_valid;
  rob_ptr_t [VEC_PIPE_W-1:0]                       vecFb_robIdx;
  logic     [VEC_PIPE_W-1:0][UOP_IDX_W-1:0]        vecFb_uopIdx;
  logic     [VEC_PIPE_W-1:0]                       vecFb_isCommit, vecFb_isFlush;
  logic     [ST_PIPE_W-1:0]                        staIn_valid, staIn_miss, stdIn_valid;
  sq_ptr_t  [ST_PIPE_W-1:0]                        staIn_sqIdx, stdIn_sqIdx;
  sq_ptr_t                                         stAddrReadySqPtr, stDataReadySqPtr;
  logic     [SQ_SIZE-1:0]                          stAddrReadyVec, stDataReadyVec;
  lq_ptr_t                                         ldWbPtr;
  rob_ptr_t                                        robDeqPtr;
  rob_ptr_t                                        redirect_robIdx;
  logic     [5:0]                                  perf_value [13];
  logic redirect_valid, redirect_level, tl_d_valid, sqEmpty, lqFull;
  logic [MSHR_ID_W-1:0] tl_d_mshrid, l2_hint_sourceId;
  logic rarFull, rawFull, l2_hint_valid, l2_hint_isKeyword;
  logic tlb_hint_valid, tlb_hint_replay_all;
  logic [TLB_ID_W-1:0] tlb_hint_id;
  logic dtd_robHeadVaddr_valid, dtd_robHeadMissInDTlb;
  logic [VADDR_BITS-1:0] dtd_robHeadVaddr_bits;
  logic dtd_robHeadTlbReplay, dtd_robHeadTlbMiss, dtd_robHeadLoadVio, dtd_robHeadLoadMSHR;
  logic replayAllocate;

  // golden 在本配置里没有 exceptionVec bit 4 的入队端口（firtool 已消）。
  // 钉 0 只为仿真不传 X：核里这几位从不被存、也从不被读，FM 前端直接剪除。
  assign enq_uop[0].exceptionVec[4] = 1'b0;
  assign enq_uop[1].exceptionVec[4] = 1'b0;
  assign enq_uop[2].exceptionVec[4] = 1'b0;

  // ---- 输入打包：golden 扁平端口 -> 核 struct/数组 ----
  assign redirect_valid = io_redirect_valid;
  assign redirect_robIdx.flag = io_redirect_bits_robIdx_flag;
  assign redirect_robIdx.value = io_redirect_bits_robIdx_value;
  assign redirect_level = io_redirect_bits_level;
  assign vecFb_valid[0] = io_vecFeedback_0_valid;
  assign vecFb_robIdx[0].flag = io_vecFeedback_0_bits_robidx_flag;
  assign vecFb_robIdx[0].value = io_vecFeedback_0_bits_robidx_value;
  assign vecFb_uopIdx[0] = io_vecFeedback_0_bits_uopidx;
  assign vecFb_isCommit[0] = io_vecFeedback_0_bits_feedback_0;
  assign vecFb_isFlush[0] = io_vecFeedback_0_bits_feedback_1;
  assign vecFb_valid[1] = io_vecFeedback_1_valid;
  assign vecFb_robIdx[1].flag = io_vecFeedback_1_bits_robidx_flag;
  assign vecFb_robIdx[1].value = io_vecFeedback_1_bits_robidx_value;
  assign vecFb_uopIdx[1] = io_vecFeedback_1_bits_uopidx;
  assign vecFb_isCommit[1] = io_vecFeedback_1_bits_feedback_0;
  assign vecFb_isFlush[1] = io_vecFeedback_1_bits_feedback_1;
  assign enq_valid[0] = io_enq_0_valid;
  assign enq_uop[0].p.instr = io_enq_0_bits_uop_instr;
  assign enq_uop[0].p.pc = io_enq_0_bits_uop_pc;
  assign enq_uop[0].p.foldpc = io_enq_0_bits_uop_foldpc;
  assign enq_uop[0].exceptionVec[0] = io_enq_0_bits_uop_exceptionVec_0;
  assign enq_uop[0].exceptionVec[1] = io_enq_0_bits_uop_exceptionVec_1;
  assign enq_uop[0].exceptionVec[2] = io_enq_0_bits_uop_exceptionVec_2;
  assign enq_uop[0].exceptionVec[3] = io_enq_0_bits_uop_exceptionVec_3;
  assign enq_uop[0].exceptionVec[5] = io_enq_0_bits_uop_exceptionVec_5;
  assign enq_uop[0].exceptionVec[6] = io_enq_0_bits_uop_exceptionVec_6;
  assign enq_uop[0].exceptionVec[7] = io_enq_0_bits_uop_exceptionVec_7;
  assign enq_uop[0].exceptionVec[8] = io_enq_0_bits_uop_exceptionVec_8;
  assign enq_uop[0].exceptionVec[9] = io_enq_0_bits_uop_exceptionVec_9;
  assign enq_uop[0].exceptionVec[10] = io_enq_0_bits_uop_exceptionVec_10;
  assign enq_uop[0].exceptionVec[11] = io_enq_0_bits_uop_exceptionVec_11;
  assign enq_uop[0].exceptionVec[12] = io_enq_0_bits_uop_exceptionVec_12;
  assign enq_uop[0].exceptionVec[13] = io_enq_0_bits_uop_exceptionVec_13;
  assign enq_uop[0].exceptionVec[14] = io_enq_0_bits_uop_exceptionVec_14;
  assign enq_uop[0].exceptionVec[15] = io_enq_0_bits_uop_exceptionVec_15;
  assign enq_uop[0].exceptionVec[16] = io_enq_0_bits_uop_exceptionVec_16;
  assign enq_uop[0].exceptionVec[17] = io_enq_0_bits_uop_exceptionVec_17;
  assign enq_uop[0].exceptionVec[18] = io_enq_0_bits_uop_exceptionVec_18;
  assign enq_uop[0].exceptionVec[19] = io_enq_0_bits_uop_exceptionVec_19;
  assign enq_uop[0].exceptionVec[20] = io_enq_0_bits_uop_exceptionVec_20;
  assign enq_uop[0].exceptionVec[21] = io_enq_0_bits_uop_exceptionVec_21;
  assign enq_uop[0].exceptionVec[22] = io_enq_0_bits_uop_exceptionVec_22;
  assign enq_uop[0].exceptionVec[23] = io_enq_0_bits_uop_exceptionVec_23;
  assign enq_uop[0].p.isFetchMalAddr = io_enq_0_bits_uop_isFetchMalAddr;
  assign enq_uop[0].p.hasException = io_enq_0_bits_uop_hasException;
  assign enq_uop[0].p.trigger = io_enq_0_bits_uop_trigger;
  assign enq_uop[0].p.preDecodeInfo_valid = io_enq_0_bits_uop_preDecodeInfo_valid;
  assign enq_uop[0].p.preDecodeInfo_isRVC = io_enq_0_bits_uop_preDecodeInfo_isRVC;
  assign enq_uop[0].p.preDecodeInfo_brType = io_enq_0_bits_uop_preDecodeInfo_brType;
  assign enq_uop[0].p.preDecodeInfo_isCall = io_enq_0_bits_uop_preDecodeInfo_isCall;
  assign enq_uop[0].p.preDecodeInfo_isRet = io_enq_0_bits_uop_preDecodeInfo_isRet;
  assign enq_uop[0].p.pred_taken = io_enq_0_bits_uop_pred_taken;
  assign enq_uop[0].p.crossPageIPFFix = io_enq_0_bits_uop_crossPageIPFFix;
  assign enq_uop[0].p.ftqPtr_flag = io_enq_0_bits_uop_ftqPtr_flag;
  assign enq_uop[0].p.ftqPtr_value = io_enq_0_bits_uop_ftqPtr_value;
  assign enq_uop[0].p.ftqOffset = io_enq_0_bits_uop_ftqOffset;
  assign enq_uop[0].p.satpFlushFirstFetchFault = io_enq_0_bits_uop_satpFlushFirstFetchFault;
  assign enq_uop[0].p.srcType_0 = io_enq_0_bits_uop_srcType_0;
  assign enq_uop[0].p.srcType_1 = io_enq_0_bits_uop_srcType_1;
  assign enq_uop[0].p.srcType_2 = io_enq_0_bits_uop_srcType_2;
  assign enq_uop[0].p.srcType_3 = io_enq_0_bits_uop_srcType_3;
  assign enq_uop[0].p.srcType_4 = io_enq_0_bits_uop_srcType_4;
  assign enq_uop[0].p.ldest = io_enq_0_bits_uop_ldest;
  assign enq_uop[0].p.fuType = io_enq_0_bits_uop_fuType;
  assign enq_uop[0].p.fuOpType = io_enq_0_bits_uop_fuOpType;
  assign enq_uop[0].p.rfWen = io_enq_0_bits_uop_rfWen;
  assign enq_uop[0].p.fpWen = io_enq_0_bits_uop_fpWen;
  assign enq_uop[0].p.vecWen = io_enq_0_bits_uop_vecWen;
  assign enq_uop[0].p.v0Wen = io_enq_0_bits_uop_v0Wen;
  assign enq_uop[0].p.vlWen = io_enq_0_bits_uop_vlWen;
  assign enq_uop[0].p.isXSTrap = io_enq_0_bits_uop_isXSTrap;
  assign enq_uop[0].p.waitForward = io_enq_0_bits_uop_waitForward;
  assign enq_uop[0].p.blockBackward = io_enq_0_bits_uop_blockBackward;
  assign enq_uop[0].p.canRobCompress = io_enq_0_bits_uop_canRobCompress;
  assign enq_uop[0].p.selImm = io_enq_0_bits_uop_selImm;
  assign enq_uop[0].p.imm = io_enq_0_bits_uop_imm;
  assign enq_uop[0].p.fpu_typeTagOut = io_enq_0_bits_uop_fpu_typeTagOut;
  assign enq_uop[0].p.fpu_wflags = io_enq_0_bits_uop_fpu_wflags;
  assign enq_uop[0].p.fpu_typ = io_enq_0_bits_uop_fpu_typ;
  assign enq_uop[0].p.fpu_fmt = io_enq_0_bits_uop_fpu_fmt;
  assign enq_uop[0].p.fpu_rm = io_enq_0_bits_uop_fpu_rm;
  assign enq_uop[0].p.vpu_vill = io_enq_0_bits_uop_vpu_vill;
  assign enq_uop[0].p.vpu_vma = io_enq_0_bits_uop_vpu_vma;
  assign enq_uop[0].p.vpu_vta = io_enq_0_bits_uop_vpu_vta;
  assign enq_uop[0].p.vpu_vsew = io_enq_0_bits_uop_vpu_vsew;
  assign enq_uop[0].p.vpu_vlmul = io_enq_0_bits_uop_vpu_vlmul;
  assign enq_uop[0].p.vpu_specVill = io_enq_0_bits_uop_vpu_specVill;
  assign enq_uop[0].p.vpu_specVma = io_enq_0_bits_uop_vpu_specVma;
  assign enq_uop[0].p.vpu_specVta = io_enq_0_bits_uop_vpu_specVta;
  assign enq_uop[0].p.vpu_specVsew = io_enq_0_bits_uop_vpu_specVsew;
  assign enq_uop[0].p.vpu_specVlmul = io_enq_0_bits_uop_vpu_specVlmul;
  assign enq_uop[0].p.vpu_vm = io_enq_0_bits_uop_vpu_vm;
  assign enq_uop[0].p.vpu_vstart = io_enq_0_bits_uop_vpu_vstart;
  assign enq_uop[0].p.vpu_frm = io_enq_0_bits_uop_vpu_frm;
  assign enq_uop[0].p.vpu_fpu_isFpToVecInst = io_enq_0_bits_uop_vpu_fpu_isFpToVecInst;
  assign enq_uop[0].p.vpu_fpu_isFP32Instr = io_enq_0_bits_uop_vpu_fpu_isFP32Instr;
  assign enq_uop[0].p.vpu_fpu_isFP64Instr = io_enq_0_bits_uop_vpu_fpu_isFP64Instr;
  assign enq_uop[0].p.vpu_fpu_isReduction = io_enq_0_bits_uop_vpu_fpu_isReduction;
  assign enq_uop[0].p.vpu_fpu_isFoldTo1_2 = io_enq_0_bits_uop_vpu_fpu_isFoldTo1_2;
  assign enq_uop[0].p.vpu_fpu_isFoldTo1_4 = io_enq_0_bits_uop_vpu_fpu_isFoldTo1_4;
  assign enq_uop[0].p.vpu_fpu_isFoldTo1_8 = io_enq_0_bits_uop_vpu_fpu_isFoldTo1_8;
  assign enq_uop[0].p.vpu_vxrm = io_enq_0_bits_uop_vpu_vxrm;
  assign enq_uop[0].p.vpu_vuopIdx = io_enq_0_bits_uop_vpu_vuopIdx;
  assign enq_uop[0].p.vpu_lastUop = io_enq_0_bits_uop_vpu_lastUop;
  assign enq_uop[0].p.vpu_vmask = io_enq_0_bits_uop_vpu_vmask;
  assign enq_uop[0].p.vpu_vl = io_enq_0_bits_uop_vpu_vl;
  assign enq_uop[0].p.vpu_nf = io_enq_0_bits_uop_vpu_nf;
  assign enq_uop[0].p.vpu_veew = io_enq_0_bits_uop_vpu_veew;
  assign enq_uop[0].p.vpu_isReverse = io_enq_0_bits_uop_vpu_isReverse;
  assign enq_uop[0].p.vpu_isExt = io_enq_0_bits_uop_vpu_isExt;
  assign enq_uop[0].p.vpu_isNarrow = io_enq_0_bits_uop_vpu_isNarrow;
  assign enq_uop[0].p.vpu_isDstMask = io_enq_0_bits_uop_vpu_isDstMask;
  assign enq_uop[0].p.vpu_isOpMask = io_enq_0_bits_uop_vpu_isOpMask;
  assign enq_uop[0].p.vpu_isMove = io_enq_0_bits_uop_vpu_isMove;
  assign enq_uop[0].p.vpu_isDependOldVd = io_enq_0_bits_uop_vpu_isDependOldVd;
  assign enq_uop[0].p.vpu_isWritePartVd = io_enq_0_bits_uop_vpu_isWritePartVd;
  assign enq_uop[0].p.vpu_isVleff = io_enq_0_bits_uop_vpu_isVleff;
  assign enq_uop[0].p.vlsInstr = io_enq_0_bits_uop_vlsInstr;
  assign enq_uop[0].p.wfflags = io_enq_0_bits_uop_wfflags;
  assign enq_uop[0].p.isMove = io_enq_0_bits_uop_isMove;
  assign enq_uop[0].p.isDropAmocasSta = io_enq_0_bits_uop_isDropAmocasSta;
  assign enq_uop[0].p.uopIdx = io_enq_0_bits_uop_uopIdx;
  assign enq_uop[0].p.isVset = io_enq_0_bits_uop_isVset;
  assign enq_uop[0].p.firstUop = io_enq_0_bits_uop_firstUop;
  assign enq_uop[0].p.lastUop = io_enq_0_bits_uop_lastUop;
  assign enq_uop[0].p.numUops = io_enq_0_bits_uop_numUops;
  assign enq_uop[0].p.numWB = io_enq_0_bits_uop_numWB;
  assign enq_uop[0].p.commitType = io_enq_0_bits_uop_commitType;
  assign enq_uop[0].p.srcState_0 = io_enq_0_bits_uop_srcState_0;
  assign enq_uop[0].p.srcState_1 = io_enq_0_bits_uop_srcState_1;
  assign enq_uop[0].p.srcState_2 = io_enq_0_bits_uop_srcState_2;
  assign enq_uop[0].p.srcState_3 = io_enq_0_bits_uop_srcState_3;
  assign enq_uop[0].p.srcState_4 = io_enq_0_bits_uop_srcState_4;
  assign enq_uop[0].p.srcLoadDependency_0_0 = io_enq_0_bits_uop_srcLoadDependency_0_0;
  assign enq_uop[0].p.srcLoadDependency_0_1 = io_enq_0_bits_uop_srcLoadDependency_0_1;
  assign enq_uop[0].p.srcLoadDependency_0_2 = io_enq_0_bits_uop_srcLoadDependency_0_2;
  assign enq_uop[0].p.srcLoadDependency_1_0 = io_enq_0_bits_uop_srcLoadDependency_1_0;
  assign enq_uop[0].p.srcLoadDependency_1_1 = io_enq_0_bits_uop_srcLoadDependency_1_1;
  assign enq_uop[0].p.srcLoadDependency_1_2 = io_enq_0_bits_uop_srcLoadDependency_1_2;
  assign enq_uop[0].p.srcLoadDependency_2_0 = io_enq_0_bits_uop_srcLoadDependency_2_0;
  assign enq_uop[0].p.srcLoadDependency_2_1 = io_enq_0_bits_uop_srcLoadDependency_2_1;
  assign enq_uop[0].p.srcLoadDependency_2_2 = io_enq_0_bits_uop_srcLoadDependency_2_2;
  assign enq_uop[0].p.srcLoadDependency_3_0 = io_enq_0_bits_uop_srcLoadDependency_3_0;
  assign enq_uop[0].p.srcLoadDependency_3_1 = io_enq_0_bits_uop_srcLoadDependency_3_1;
  assign enq_uop[0].p.srcLoadDependency_3_2 = io_enq_0_bits_uop_srcLoadDependency_3_2;
  assign enq_uop[0].p.srcLoadDependency_4_0 = io_enq_0_bits_uop_srcLoadDependency_4_0;
  assign enq_uop[0].p.srcLoadDependency_4_1 = io_enq_0_bits_uop_srcLoadDependency_4_1;
  assign enq_uop[0].p.srcLoadDependency_4_2 = io_enq_0_bits_uop_srcLoadDependency_4_2;
  assign enq_uop[0].p.psrc_0 = io_enq_0_bits_uop_psrc_0;
  assign enq_uop[0].p.psrc_1 = io_enq_0_bits_uop_psrc_1;
  assign enq_uop[0].p.psrc_2 = io_enq_0_bits_uop_psrc_2;
  assign enq_uop[0].p.psrc_3 = io_enq_0_bits_uop_psrc_3;
  assign enq_uop[0].p.psrc_4 = io_enq_0_bits_uop_psrc_4;
  assign enq_uop[0].p.pdest = io_enq_0_bits_uop_pdest;
  assign enq_uop[0].p.useRegCache_0 = io_enq_0_bits_uop_useRegCache_0;
  assign enq_uop[0].p.useRegCache_1 = io_enq_0_bits_uop_useRegCache_1;
  assign enq_uop[0].p.regCacheIdx_0 = io_enq_0_bits_uop_regCacheIdx_0;
  assign enq_uop[0].p.regCacheIdx_1 = io_enq_0_bits_uop_regCacheIdx_1;
  assign enq_uop[0].p.robIdx_flag = io_enq_0_bits_uop_robIdx_flag;
  assign enq_uop[0].p.robIdx_value = io_enq_0_bits_uop_robIdx_value;
  assign enq_uop[0].p.instrSize = io_enq_0_bits_uop_instrSize;
  assign enq_uop[0].p.dirtyFs = io_enq_0_bits_uop_dirtyFs;
  assign enq_uop[0].p.dirtyVs = io_enq_0_bits_uop_dirtyVs;
  assign enq_uop[0].p.traceBlockInPipe_itype = io_enq_0_bits_uop_traceBlockInPipe_itype;
  assign enq_uop[0].p.traceBlockInPipe_iretire = io_enq_0_bits_uop_traceBlockInPipe_iretire;
  assign enq_uop[0].p.traceBlockInPipe_ilastsize = io_enq_0_bits_uop_traceBlockInPipe_ilastsize;
  assign enq_uop[0].p.eliminatedMove = io_enq_0_bits_uop_eliminatedMove;
  assign enq_uop[0].p.snapshot = io_enq_0_bits_uop_snapshot;
  assign enq_uop[0].p.debugInfo_eliminatedMove = io_enq_0_bits_uop_debugInfo_eliminatedMove;
  assign enq_uop[0].p.debugInfo_renameTime = io_enq_0_bits_uop_debugInfo_renameTime;
  assign enq_uop[0].p.debugInfo_dispatchTime = io_enq_0_bits_uop_debugInfo_dispatchTime;
  assign enq_uop[0].p.debugInfo_enqRsTime = io_enq_0_bits_uop_debugInfo_enqRsTime;
  assign enq_uop[0].p.debugInfo_selectTime = io_enq_0_bits_uop_debugInfo_selectTime;
  assign enq_uop[0].p.debugInfo_issueTime = io_enq_0_bits_uop_debugInfo_issueTime;
  assign enq_uop[0].p.debugInfo_writebackTime = io_enq_0_bits_uop_debugInfo_writebackTime;
  assign enq_uop[0].p.debugInfo_runahead_checkpoint_id = io_enq_0_bits_uop_debugInfo_runahead_checkpoint_id;
  assign enq_uop[0].p.debugInfo_tlbFirstReqTime = io_enq_0_bits_uop_debugInfo_tlbFirstReqTime;
  assign enq_uop[0].p.debugInfo_tlbRespTime = io_enq_0_bits_uop_debugInfo_tlbRespTime;
  assign enq_uop[0].p.debug_seqNum_seqNum = io_enq_0_bits_uop_debug_seqNum_seqNum;
  assign enq_uop[0].p.debug_seqNum_uopIdx = io_enq_0_bits_uop_debug_seqNum_uopIdx;
  assign enq_uop[0].p.storeSetHit = io_enq_0_bits_uop_storeSetHit;
  assign enq_uop[0].p.waitForRobIdx_flag = io_enq_0_bits_uop_waitForRobIdx_flag;
  assign enq_uop[0].p.waitForRobIdx_value = io_enq_0_bits_uop_waitForRobIdx_value;
  assign enq_uop[0].p.loadWaitBit = io_enq_0_bits_uop_loadWaitBit;
  assign enq_uop[0].loadWaitStrict = io_enq_0_bits_uop_loadWaitStrict;
  assign enq_uop[0].p.ssid = io_enq_0_bits_uop_ssid;
  assign enq_uop[0].p.lqIdx_flag = io_enq_0_bits_uop_lqIdx_flag;
  assign enq_uop[0].p.lqIdx_value = io_enq_0_bits_uop_lqIdx_value;
  assign enq_uop[0].p.sqIdx_flag = io_enq_0_bits_uop_sqIdx_flag;
  assign enq_uop[0].p.sqIdx_value = io_enq_0_bits_uop_sqIdx_value;
  assign enq_uop[0].p.singleStep = io_enq_0_bits_uop_singleStep;
  assign enq_uop[0].p.debug_fuType = io_enq_0_bits_uop_debug_fuType;
  assign enq_uop[0].p.debug_sim_trig = io_enq_0_bits_uop_debug_sim_trig;
  assign enq_uop[0].p.numLsElem = io_enq_0_bits_uop_numLsElem;
  assign enq_vaddr[0] = io_enq_0_bits_vaddr;
  assign enq_vec[0].mask = io_enq_0_bits_mask;
  assign enq_vec[0].isvec = io_enq_0_bits_isvec;
  assign enq_vec[0].is128bit = io_enq_0_bits_is128bit;
  assign enq_vec[0].elemIdx = io_enq_0_bits_elemIdx;
  assign enq_vec[0].alignedType = io_enq_0_bits_alignedType;
  assign enq_vec[0].mbIndex = io_enq_0_bits_mbIndex;
  assign enq_vec[0].reg_offset = io_enq_0_bits_reg_offset;
  assign enq_vec[0].elemIdxInsideVd = io_enq_0_bits_elemIdxInsideVd;
  assign enq_vec[0].vecActive = io_enq_0_bits_vecActive;
  assign enq_isLoadReplay[0] = io_enq_0_bits_isLoadReplay;
  assign enq_handledByMSHR[0] = io_enq_0_bits_handledByMSHR;
  assign enq_schedIndex[0] = io_enq_0_bits_schedIndex;
  assign enq_mshr_id[0] = io_enq_0_bits_rep_info_mshr_id;
  assign enq_full_fwd[0] = io_enq_0_bits_rep_info_full_fwd;
  assign enq_data_inv_sq_idx[0].flag = io_enq_0_bits_rep_info_data_inv_sq_idx_flag;
  assign enq_data_inv_sq_idx[0].value = io_enq_0_bits_rep_info_data_inv_sq_idx_value;
  assign enq_addr_inv_sq_idx[0].flag = io_enq_0_bits_rep_info_addr_inv_sq_idx_flag;
  assign enq_addr_inv_sq_idx[0].value = io_enq_0_bits_rep_info_addr_inv_sq_idx_value;
  assign enq_last_beat[0] = io_enq_0_bits_rep_info_last_beat;
  assign enq_cause[0][0] = io_enq_0_bits_rep_info_cause_0;
  assign enq_cause[0][1] = io_enq_0_bits_rep_info_cause_1;
  assign enq_cause[0][2] = io_enq_0_bits_rep_info_cause_2;
  assign enq_cause[0][3] = io_enq_0_bits_rep_info_cause_3;
  assign enq_cause[0][4] = io_enq_0_bits_rep_info_cause_4;
  assign enq_cause[0][5] = io_enq_0_bits_rep_info_cause_5;
  assign enq_cause[0][6] = io_enq_0_bits_rep_info_cause_6;
  assign enq_cause[0][7] = io_enq_0_bits_rep_info_cause_7;
  assign enq_cause[0][8] = io_enq_0_bits_rep_info_cause_8;
  assign enq_cause[0][9] = io_enq_0_bits_rep_info_cause_9;
  assign enq_cause[0][10] = io_enq_0_bits_rep_info_cause_10;
  assign enq_tlb_id[0] = io_enq_0_bits_rep_info_tlb_id;
  assign enq_tlb_full[0] = io_enq_0_bits_rep_info_tlb_full;
  assign enq_valid[1] = io_enq_1_valid;
  assign enq_uop[1].p.instr = io_enq_1_bits_uop_instr;
  assign enq_uop[1].p.pc = io_enq_1_bits_uop_pc;
  assign enq_uop[1].p.foldpc = io_enq_1_bits_uop_foldpc;
  assign enq_uop[1].exceptionVec[0] = io_enq_1_bits_uop_exceptionVec_0;
  assign enq_uop[1].exceptionVec[1] = io_enq_1_bits_uop_exceptionVec_1;
  assign enq_uop[1].exceptionVec[2] = io_enq_1_bits_uop_exceptionVec_2;
  assign enq_uop[1].exceptionVec[3] = io_enq_1_bits_uop_exceptionVec_3;
  assign enq_uop[1].exceptionVec[5] = io_enq_1_bits_uop_exceptionVec_5;
  assign enq_uop[1].exceptionVec[6] = io_enq_1_bits_uop_exceptionVec_6;
  assign enq_uop[1].exceptionVec[7] = io_enq_1_bits_uop_exceptionVec_7;
  assign enq_uop[1].exceptionVec[8] = io_enq_1_bits_uop_exceptionVec_8;
  assign enq_uop[1].exceptionVec[9] = io_enq_1_bits_uop_exceptionVec_9;
  assign enq_uop[1].exceptionVec[10] = io_enq_1_bits_uop_exceptionVec_10;
  assign enq_uop[1].exceptionVec[11] = io_enq_1_bits_uop_exceptionVec_11;
  assign enq_uop[1].exceptionVec[12] = io_enq_1_bits_uop_exceptionVec_12;
  assign enq_uop[1].exceptionVec[13] = io_enq_1_bits_uop_exceptionVec_13;
  assign enq_uop[1].exceptionVec[14] = io_enq_1_bits_uop_exceptionVec_14;
  assign enq_uop[1].exceptionVec[15] = io_enq_1_bits_uop_exceptionVec_15;
  assign enq_uop[1].exceptionVec[16] = io_enq_1_bits_uop_exceptionVec_16;
  assign enq_uop[1].exceptionVec[17] = io_enq_1_bits_uop_exceptionVec_17;
  assign enq_uop[1].exceptionVec[18] = io_enq_1_bits_uop_exceptionVec_18;
  assign enq_uop[1].exceptionVec[19] = io_enq_1_bits_uop_exceptionVec_19;
  assign enq_uop[1].exceptionVec[20] = io_enq_1_bits_uop_exceptionVec_20;
  assign enq_uop[1].exceptionVec[21] = io_enq_1_bits_uop_exceptionVec_21;
  assign enq_uop[1].exceptionVec[22] = io_enq_1_bits_uop_exceptionVec_22;
  assign enq_uop[1].exceptionVec[23] = io_enq_1_bits_uop_exceptionVec_23;
  assign enq_uop[1].p.isFetchMalAddr = io_enq_1_bits_uop_isFetchMalAddr;
  assign enq_uop[1].p.hasException = io_enq_1_bits_uop_hasException;
  assign enq_uop[1].p.trigger = io_enq_1_bits_uop_trigger;
  assign enq_uop[1].p.preDecodeInfo_valid = io_enq_1_bits_uop_preDecodeInfo_valid;
  assign enq_uop[1].p.preDecodeInfo_isRVC = io_enq_1_bits_uop_preDecodeInfo_isRVC;
  assign enq_uop[1].p.preDecodeInfo_brType = io_enq_1_bits_uop_preDecodeInfo_brType;
  assign enq_uop[1].p.preDecodeInfo_isCall = io_enq_1_bits_uop_preDecodeInfo_isCall;
  assign enq_uop[1].p.preDecodeInfo_isRet = io_enq_1_bits_uop_preDecodeInfo_isRet;
  assign enq_uop[1].p.pred_taken = io_enq_1_bits_uop_pred_taken;
  assign enq_uop[1].p.crossPageIPFFix = io_enq_1_bits_uop_crossPageIPFFix;
  assign enq_uop[1].p.ftqPtr_flag = io_enq_1_bits_uop_ftqPtr_flag;
  assign enq_uop[1].p.ftqPtr_value = io_enq_1_bits_uop_ftqPtr_value;
  assign enq_uop[1].p.ftqOffset = io_enq_1_bits_uop_ftqOffset;
  assign enq_uop[1].p.satpFlushFirstFetchFault = io_enq_1_bits_uop_satpFlushFirstFetchFault;
  assign enq_uop[1].p.srcType_0 = io_enq_1_bits_uop_srcType_0;
  assign enq_uop[1].p.srcType_1 = io_enq_1_bits_uop_srcType_1;
  assign enq_uop[1].p.srcType_2 = io_enq_1_bits_uop_srcType_2;
  assign enq_uop[1].p.srcType_3 = io_enq_1_bits_uop_srcType_3;
  assign enq_uop[1].p.srcType_4 = io_enq_1_bits_uop_srcType_4;
  assign enq_uop[1].p.ldest = io_enq_1_bits_uop_ldest;
  assign enq_uop[1].p.fuType = io_enq_1_bits_uop_fuType;
  assign enq_uop[1].p.fuOpType = io_enq_1_bits_uop_fuOpType;
  assign enq_uop[1].p.rfWen = io_enq_1_bits_uop_rfWen;
  assign enq_uop[1].p.fpWen = io_enq_1_bits_uop_fpWen;
  assign enq_uop[1].p.vecWen = io_enq_1_bits_uop_vecWen;
  assign enq_uop[1].p.v0Wen = io_enq_1_bits_uop_v0Wen;
  assign enq_uop[1].p.vlWen = io_enq_1_bits_uop_vlWen;
  assign enq_uop[1].p.isXSTrap = io_enq_1_bits_uop_isXSTrap;
  assign enq_uop[1].p.waitForward = io_enq_1_bits_uop_waitForward;
  assign enq_uop[1].p.blockBackward = io_enq_1_bits_uop_blockBackward;
  assign enq_uop[1].p.canRobCompress = io_enq_1_bits_uop_canRobCompress;
  assign enq_uop[1].p.selImm = io_enq_1_bits_uop_selImm;
  assign enq_uop[1].p.imm = io_enq_1_bits_uop_imm;
  assign enq_uop[1].p.fpu_typeTagOut = io_enq_1_bits_uop_fpu_typeTagOut;
  assign enq_uop[1].p.fpu_wflags = io_enq_1_bits_uop_fpu_wflags;
  assign enq_uop[1].p.fpu_typ = io_enq_1_bits_uop_fpu_typ;
  assign enq_uop[1].p.fpu_fmt = io_enq_1_bits_uop_fpu_fmt;
  assign enq_uop[1].p.fpu_rm = io_enq_1_bits_uop_fpu_rm;
  assign enq_uop[1].p.vpu_vill = io_enq_1_bits_uop_vpu_vill;
  assign enq_uop[1].p.vpu_vma = io_enq_1_bits_uop_vpu_vma;
  assign enq_uop[1].p.vpu_vta = io_enq_1_bits_uop_vpu_vta;
  assign enq_uop[1].p.vpu_vsew = io_enq_1_bits_uop_vpu_vsew;
  assign enq_uop[1].p.vpu_vlmul = io_enq_1_bits_uop_vpu_vlmul;
  assign enq_uop[1].p.vpu_specVill = io_enq_1_bits_uop_vpu_specVill;
  assign enq_uop[1].p.vpu_specVma = io_enq_1_bits_uop_vpu_specVma;
  assign enq_uop[1].p.vpu_specVta = io_enq_1_bits_uop_vpu_specVta;
  assign enq_uop[1].p.vpu_specVsew = io_enq_1_bits_uop_vpu_specVsew;
  assign enq_uop[1].p.vpu_specVlmul = io_enq_1_bits_uop_vpu_specVlmul;
  assign enq_uop[1].p.vpu_vm = io_enq_1_bits_uop_vpu_vm;
  assign enq_uop[1].p.vpu_vstart = io_enq_1_bits_uop_vpu_vstart;
  assign enq_uop[1].p.vpu_frm = io_enq_1_bits_uop_vpu_frm;
  assign enq_uop[1].p.vpu_fpu_isFpToVecInst = io_enq_1_bits_uop_vpu_fpu_isFpToVecInst;
  assign enq_uop[1].p.vpu_fpu_isFP32Instr = io_enq_1_bits_uop_vpu_fpu_isFP32Instr;
  assign enq_uop[1].p.vpu_fpu_isFP64Instr = io_enq_1_bits_uop_vpu_fpu_isFP64Instr;
  assign enq_uop[1].p.vpu_fpu_isReduction = io_enq_1_bits_uop_vpu_fpu_isReduction;
  assign enq_uop[1].p.vpu_fpu_isFoldTo1_2 = io_enq_1_bits_uop_vpu_fpu_isFoldTo1_2;
  assign enq_uop[1].p.vpu_fpu_isFoldTo1_4 = io_enq_1_bits_uop_vpu_fpu_isFoldTo1_4;
  assign enq_uop[1].p.vpu_fpu_isFoldTo1_8 = io_enq_1_bits_uop_vpu_fpu_isFoldTo1_8;
  assign enq_uop[1].p.vpu_vxrm = io_enq_1_bits_uop_vpu_vxrm;
  assign enq_uop[1].p.vpu_vuopIdx = io_enq_1_bits_uop_vpu_vuopIdx;
  assign enq_uop[1].p.vpu_lastUop = io_enq_1_bits_uop_vpu_lastUop;
  assign enq_uop[1].p.vpu_vmask = io_enq_1_bits_uop_vpu_vmask;
  assign enq_uop[1].p.vpu_vl = io_enq_1_bits_uop_vpu_vl;
  assign enq_uop[1].p.vpu_nf = io_enq_1_bits_uop_vpu_nf;
  assign enq_uop[1].p.vpu_veew = io_enq_1_bits_uop_vpu_veew;
  assign enq_uop[1].p.vpu_isReverse = io_enq_1_bits_uop_vpu_isReverse;
  assign enq_uop[1].p.vpu_isExt = io_enq_1_bits_uop_vpu_isExt;
  assign enq_uop[1].p.vpu_isNarrow = io_enq_1_bits_uop_vpu_isNarrow;
  assign enq_uop[1].p.vpu_isDstMask = io_enq_1_bits_uop_vpu_isDstMask;
  assign enq_uop[1].p.vpu_isOpMask = io_enq_1_bits_uop_vpu_isOpMask;
  assign enq_uop[1].p.vpu_isMove = io_enq_1_bits_uop_vpu_isMove;
  assign enq_uop[1].p.vpu_isDependOldVd = io_enq_1_bits_uop_vpu_isDependOldVd;
  assign enq_uop[1].p.vpu_isWritePartVd = io_enq_1_bits_uop_vpu_isWritePartVd;
  assign enq_uop[1].p.vpu_isVleff = io_enq_1_bits_uop_vpu_isVleff;
  assign enq_uop[1].p.vlsInstr = io_enq_1_bits_uop_vlsInstr;
  assign enq_uop[1].p.wfflags = io_enq_1_bits_uop_wfflags;
  assign enq_uop[1].p.isMove = io_enq_1_bits_uop_isMove;
  assign enq_uop[1].p.isDropAmocasSta = io_enq_1_bits_uop_isDropAmocasSta;
  assign enq_uop[1].p.uopIdx = io_enq_1_bits_uop_uopIdx;
  assign enq_uop[1].p.isVset = io_enq_1_bits_uop_isVset;
  assign enq_uop[1].p.firstUop = io_enq_1_bits_uop_firstUop;
  assign enq_uop[1].p.lastUop = io_enq_1_bits_uop_lastUop;
  assign enq_uop[1].p.numUops = io_enq_1_bits_uop_numUops;
  assign enq_uop[1].p.numWB = io_enq_1_bits_uop_numWB;
  assign enq_uop[1].p.commitType = io_enq_1_bits_uop_commitType;
  assign enq_uop[1].p.srcState_0 = io_enq_1_bits_uop_srcState_0;
  assign enq_uop[1].p.srcState_1 = io_enq_1_bits_uop_srcState_1;
  assign enq_uop[1].p.srcState_2 = io_enq_1_bits_uop_srcState_2;
  assign enq_uop[1].p.srcState_3 = io_enq_1_bits_uop_srcState_3;
  assign enq_uop[1].p.srcState_4 = io_enq_1_bits_uop_srcState_4;
  assign enq_uop[1].p.srcLoadDependency_0_0 = io_enq_1_bits_uop_srcLoadDependency_0_0;
  assign enq_uop[1].p.srcLoadDependency_0_1 = io_enq_1_bits_uop_srcLoadDependency_0_1;
  assign enq_uop[1].p.srcLoadDependency_0_2 = io_enq_1_bits_uop_srcLoadDependency_0_2;
  assign enq_uop[1].p.srcLoadDependency_1_0 = io_enq_1_bits_uop_srcLoadDependency_1_0;
  assign enq_uop[1].p.srcLoadDependency_1_1 = io_enq_1_bits_uop_srcLoadDependency_1_1;
  assign enq_uop[1].p.srcLoadDependency_1_2 = io_enq_1_bits_uop_srcLoadDependency_1_2;
  assign enq_uop[1].p.srcLoadDependency_2_0 = io_enq_1_bits_uop_srcLoadDependency_2_0;
  assign enq_uop[1].p.srcLoadDependency_2_1 = io_enq_1_bits_uop_srcLoadDependency_2_1;
  assign enq_uop[1].p.srcLoadDependency_2_2 = io_enq_1_bits_uop_srcLoadDependency_2_2;
  assign enq_uop[1].p.srcLoadDependency_3_0 = io_enq_1_bits_uop_srcLoadDependency_3_0;
  assign enq_uop[1].p.srcLoadDependency_3_1 = io_enq_1_bits_uop_srcLoadDependency_3_1;
  assign enq_uop[1].p.srcLoadDependency_3_2 = io_enq_1_bits_uop_srcLoadDependency_3_2;
  assign enq_uop[1].p.srcLoadDependency_4_0 = io_enq_1_bits_uop_srcLoadDependency_4_0;
  assign enq_uop[1].p.srcLoadDependency_4_1 = io_enq_1_bits_uop_srcLoadDependency_4_1;
  assign enq_uop[1].p.srcLoadDependency_4_2 = io_enq_1_bits_uop_srcLoadDependency_4_2;
  assign enq_uop[1].p.psrc_0 = io_enq_1_bits_uop_psrc_0;
  assign enq_uop[1].p.psrc_1 = io_enq_1_bits_uop_psrc_1;
  assign enq_uop[1].p.psrc_2 = io_enq_1_bits_uop_psrc_2;
  assign enq_uop[1].p.psrc_3 = io_enq_1_bits_uop_psrc_3;
  assign enq_uop[1].p.psrc_4 = io_enq_1_bits_uop_psrc_4;
  assign enq_uop[1].p.pdest = io_enq_1_bits_uop_pdest;
  assign enq_uop[1].p.useRegCache_0 = io_enq_1_bits_uop_useRegCache_0;
  assign enq_uop[1].p.useRegCache_1 = io_enq_1_bits_uop_useRegCache_1;
  assign enq_uop[1].p.regCacheIdx_0 = io_enq_1_bits_uop_regCacheIdx_0;
  assign enq_uop[1].p.regCacheIdx_1 = io_enq_1_bits_uop_regCacheIdx_1;
  assign enq_uop[1].p.robIdx_flag = io_enq_1_bits_uop_robIdx_flag;
  assign enq_uop[1].p.robIdx_value = io_enq_1_bits_uop_robIdx_value;
  assign enq_uop[1].p.instrSize = io_enq_1_bits_uop_instrSize;
  assign enq_uop[1].p.dirtyFs = io_enq_1_bits_uop_dirtyFs;
  assign enq_uop[1].p.dirtyVs = io_enq_1_bits_uop_dirtyVs;
  assign enq_uop[1].p.traceBlockInPipe_itype = io_enq_1_bits_uop_traceBlockInPipe_itype;
  assign enq_uop[1].p.traceBlockInPipe_iretire = io_enq_1_bits_uop_traceBlockInPipe_iretire;
  assign enq_uop[1].p.traceBlockInPipe_ilastsize = io_enq_1_bits_uop_traceBlockInPipe_ilastsize;
  assign enq_uop[1].p.eliminatedMove = io_enq_1_bits_uop_eliminatedMove;
  assign enq_uop[1].p.snapshot = io_enq_1_bits_uop_snapshot;
  assign enq_uop[1].p.debugInfo_eliminatedMove = io_enq_1_bits_uop_debugInfo_eliminatedMove;
  assign enq_uop[1].p.debugInfo_renameTime = io_enq_1_bits_uop_debugInfo_renameTime;
  assign enq_uop[1].p.debugInfo_dispatchTime = io_enq_1_bits_uop_debugInfo_dispatchTime;
  assign enq_uop[1].p.debugInfo_enqRsTime = io_enq_1_bits_uop_debugInfo_enqRsTime;
  assign enq_uop[1].p.debugInfo_selectTime = io_enq_1_bits_uop_debugInfo_selectTime;
  assign enq_uop[1].p.debugInfo_issueTime = io_enq_1_bits_uop_debugInfo_issueTime;
  assign enq_uop[1].p.debugInfo_writebackTime = io_enq_1_bits_uop_debugInfo_writebackTime;
  assign enq_uop[1].p.debugInfo_runahead_checkpoint_id = io_enq_1_bits_uop_debugInfo_runahead_checkpoint_id;
  assign enq_uop[1].p.debugInfo_tlbFirstReqTime = io_enq_1_bits_uop_debugInfo_tlbFirstReqTime;
  assign enq_uop[1].p.debugInfo_tlbRespTime = io_enq_1_bits_uop_debugInfo_tlbRespTime;
  assign enq_uop[1].p.debug_seqNum_seqNum = io_enq_1_bits_uop_debug_seqNum_seqNum;
  assign enq_uop[1].p.debug_seqNum_uopIdx = io_enq_1_bits_uop_debug_seqNum_uopIdx;
  assign enq_uop[1].p.storeSetHit = io_enq_1_bits_uop_storeSetHit;
  assign enq_uop[1].p.waitForRobIdx_flag = io_enq_1_bits_uop_waitForRobIdx_flag;
  assign enq_uop[1].p.waitForRobIdx_value = io_enq_1_bits_uop_waitForRobIdx_value;
  assign enq_uop[1].p.loadWaitBit = io_enq_1_bits_uop_loadWaitBit;
  assign enq_uop[1].loadWaitStrict = io_enq_1_bits_uop_loadWaitStrict;
  assign enq_uop[1].p.ssid = io_enq_1_bits_uop_ssid;
  assign enq_uop[1].p.lqIdx_flag = io_enq_1_bits_uop_lqIdx_flag;
  assign enq_uop[1].p.lqIdx_value = io_enq_1_bits_uop_lqIdx_value;
  assign enq_uop[1].p.sqIdx_flag = io_enq_1_bits_uop_sqIdx_flag;
  assign enq_uop[1].p.sqIdx_value = io_enq_1_bits_uop_sqIdx_value;
  assign enq_uop[1].p.singleStep = io_enq_1_bits_uop_singleStep;
  assign enq_uop[1].p.debug_fuType = io_enq_1_bits_uop_debug_fuType;
  assign enq_uop[1].p.debug_sim_trig = io_enq_1_bits_uop_debug_sim_trig;
  assign enq_uop[1].p.numLsElem = io_enq_1_bits_uop_numLsElem;
  assign enq_vaddr[1] = io_enq_1_bits_vaddr;
  assign enq_vec[1].mask = io_enq_1_bits_mask;
  assign enq_vec[1].isvec = io_enq_1_bits_isvec;
  assign enq_vec[1].is128bit = io_enq_1_bits_is128bit;
  assign enq_vec[1].elemIdx = io_enq_1_bits_elemIdx;
  assign enq_vec[1].alignedType = io_enq_1_bits_alignedType;
  assign enq_vec[1].mbIndex = io_enq_1_bits_mbIndex;
  assign enq_vec[1].reg_offset = io_enq_1_bits_reg_offset;
  assign enq_vec[1].elemIdxInsideVd = io_enq_1_bits_elemIdxInsideVd;
  assign enq_vec[1].vecActive = io_enq_1_bits_vecActive;
  assign enq_isLoadReplay[1] = io_enq_1_bits_isLoadReplay;
  assign enq_handledByMSHR[1] = io_enq_1_bits_handledByMSHR;
  assign enq_schedIndex[1] = io_enq_1_bits_schedIndex;
  assign enq_mshr_id[1] = io_enq_1_bits_rep_info_mshr_id;
  assign enq_full_fwd[1] = io_enq_1_bits_rep_info_full_fwd;
  assign enq_data_inv_sq_idx[1].flag = io_enq_1_bits_rep_info_data_inv_sq_idx_flag;
  assign enq_data_inv_sq_idx[1].value = io_enq_1_bits_rep_info_data_inv_sq_idx_value;
  assign enq_addr_inv_sq_idx[1].flag = io_enq_1_bits_rep_info_addr_inv_sq_idx_flag;
  assign enq_addr_inv_sq_idx[1].value = io_enq_1_bits_rep_info_addr_inv_sq_idx_value;
  assign enq_last_beat[1] = io_enq_1_bits_rep_info_last_beat;
  assign enq_cause[1][0] = io_enq_1_bits_rep_info_cause_0;
  assign enq_cause[1][1] = io_enq_1_bits_rep_info_cause_1;
  assign enq_cause[1][2] = io_enq_1_bits_rep_info_cause_2;
  assign enq_cause[1][3] = io_enq_1_bits_rep_info_cause_3;
  assign enq_cause[1][4] = io_enq_1_bits_rep_info_cause_4;
  assign enq_cause[1][5] = io_enq_1_bits_rep_info_cause_5;
  assign enq_cause[1][6] = io_enq_1_bits_rep_info_cause_6;
  assign enq_cause[1][7] = io_enq_1_bits_rep_info_cause_7;
  assign enq_cause[1][8] = io_enq_1_bits_rep_info_cause_8;
  assign enq_cause[1][9] = io_enq_1_bits_rep_info_cause_9;
  assign enq_cause[1][10] = io_enq_1_bits_rep_info_cause_10;
  assign enq_tlb_id[1] = io_enq_1_bits_rep_info_tlb_id;
  assign enq_tlb_full[1] = io_enq_1_bits_rep_info_tlb_full;
  assign enq_valid[2] = io_enq_2_valid;
  assign enq_uop[2].p.instr = io_enq_2_bits_uop_instr;
  assign enq_uop[2].p.pc = io_enq_2_bits_uop_pc;
  assign enq_uop[2].p.foldpc = io_enq_2_bits_uop_foldpc;
  assign enq_uop[2].exceptionVec[0] = io_enq_2_bits_uop_exceptionVec_0;
  assign enq_uop[2].exceptionVec[1] = io_enq_2_bits_uop_exceptionVec_1;
  assign enq_uop[2].exceptionVec[2] = io_enq_2_bits_uop_exceptionVec_2;
  assign enq_uop[2].exceptionVec[3] = io_enq_2_bits_uop_exceptionVec_3;
  assign enq_uop[2].exceptionVec[5] = io_enq_2_bits_uop_exceptionVec_5;
  assign enq_uop[2].exceptionVec[6] = io_enq_2_bits_uop_exceptionVec_6;
  assign enq_uop[2].exceptionVec[7] = io_enq_2_bits_uop_exceptionVec_7;
  assign enq_uop[2].exceptionVec[8] = io_enq_2_bits_uop_exceptionVec_8;
  assign enq_uop[2].exceptionVec[9] = io_enq_2_bits_uop_exceptionVec_9;
  assign enq_uop[2].exceptionVec[10] = io_enq_2_bits_uop_exceptionVec_10;
  assign enq_uop[2].exceptionVec[11] = io_enq_2_bits_uop_exceptionVec_11;
  assign enq_uop[2].exceptionVec[12] = io_enq_2_bits_uop_exceptionVec_12;
  assign enq_uop[2].exceptionVec[13] = io_enq_2_bits_uop_exceptionVec_13;
  assign enq_uop[2].exceptionVec[14] = io_enq_2_bits_uop_exceptionVec_14;
  assign enq_uop[2].exceptionVec[15] = io_enq_2_bits_uop_exceptionVec_15;
  assign enq_uop[2].exceptionVec[16] = io_enq_2_bits_uop_exceptionVec_16;
  assign enq_uop[2].exceptionVec[17] = io_enq_2_bits_uop_exceptionVec_17;
  assign enq_uop[2].exceptionVec[18] = io_enq_2_bits_uop_exceptionVec_18;
  assign enq_uop[2].exceptionVec[19] = io_enq_2_bits_uop_exceptionVec_19;
  assign enq_uop[2].exceptionVec[20] = io_enq_2_bits_uop_exceptionVec_20;
  assign enq_uop[2].exceptionVec[21] = io_enq_2_bits_uop_exceptionVec_21;
  assign enq_uop[2].exceptionVec[22] = io_enq_2_bits_uop_exceptionVec_22;
  assign enq_uop[2].exceptionVec[23] = io_enq_2_bits_uop_exceptionVec_23;
  assign enq_uop[2].p.isFetchMalAddr = io_enq_2_bits_uop_isFetchMalAddr;
  assign enq_uop[2].p.hasException = io_enq_2_bits_uop_hasException;
  assign enq_uop[2].p.trigger = io_enq_2_bits_uop_trigger;
  assign enq_uop[2].p.preDecodeInfo_valid = io_enq_2_bits_uop_preDecodeInfo_valid;
  assign enq_uop[2].p.preDecodeInfo_isRVC = io_enq_2_bits_uop_preDecodeInfo_isRVC;
  assign enq_uop[2].p.preDecodeInfo_brType = io_enq_2_bits_uop_preDecodeInfo_brType;
  assign enq_uop[2].p.preDecodeInfo_isCall = io_enq_2_bits_uop_preDecodeInfo_isCall;
  assign enq_uop[2].p.preDecodeInfo_isRet = io_enq_2_bits_uop_preDecodeInfo_isRet;
  assign enq_uop[2].p.pred_taken = io_enq_2_bits_uop_pred_taken;
  assign enq_uop[2].p.crossPageIPFFix = io_enq_2_bits_uop_crossPageIPFFix;
  assign enq_uop[2].p.ftqPtr_flag = io_enq_2_bits_uop_ftqPtr_flag;
  assign enq_uop[2].p.ftqPtr_value = io_enq_2_bits_uop_ftqPtr_value;
  assign enq_uop[2].p.ftqOffset = io_enq_2_bits_uop_ftqOffset;
  assign enq_uop[2].p.satpFlushFirstFetchFault = io_enq_2_bits_uop_satpFlushFirstFetchFault;
  assign enq_uop[2].p.srcType_0 = io_enq_2_bits_uop_srcType_0;
  assign enq_uop[2].p.srcType_1 = io_enq_2_bits_uop_srcType_1;
  assign enq_uop[2].p.srcType_2 = io_enq_2_bits_uop_srcType_2;
  assign enq_uop[2].p.srcType_3 = io_enq_2_bits_uop_srcType_3;
  assign enq_uop[2].p.srcType_4 = io_enq_2_bits_uop_srcType_4;
  assign enq_uop[2].p.ldest = io_enq_2_bits_uop_ldest;
  assign enq_uop[2].p.fuType = io_enq_2_bits_uop_fuType;
  assign enq_uop[2].p.fuOpType = io_enq_2_bits_uop_fuOpType;
  assign enq_uop[2].p.rfWen = io_enq_2_bits_uop_rfWen;
  assign enq_uop[2].p.fpWen = io_enq_2_bits_uop_fpWen;
  assign enq_uop[2].p.vecWen = io_enq_2_bits_uop_vecWen;
  assign enq_uop[2].p.v0Wen = io_enq_2_bits_uop_v0Wen;
  assign enq_uop[2].p.vlWen = io_enq_2_bits_uop_vlWen;
  assign enq_uop[2].p.isXSTrap = io_enq_2_bits_uop_isXSTrap;
  assign enq_uop[2].p.waitForward = io_enq_2_bits_uop_waitForward;
  assign enq_uop[2].p.blockBackward = io_enq_2_bits_uop_blockBackward;
  assign enq_uop[2].p.canRobCompress = io_enq_2_bits_uop_canRobCompress;
  assign enq_uop[2].p.selImm = io_enq_2_bits_uop_selImm;
  assign enq_uop[2].p.imm = io_enq_2_bits_uop_imm;
  assign enq_uop[2].p.fpu_typeTagOut = io_enq_2_bits_uop_fpu_typeTagOut;
  assign enq_uop[2].p.fpu_wflags = io_enq_2_bits_uop_fpu_wflags;
  assign enq_uop[2].p.fpu_typ = io_enq_2_bits_uop_fpu_typ;
  assign enq_uop[2].p.fpu_fmt = io_enq_2_bits_uop_fpu_fmt;
  assign enq_uop[2].p.fpu_rm = io_enq_2_bits_uop_fpu_rm;
  assign enq_uop[2].p.vpu_vill = io_enq_2_bits_uop_vpu_vill;
  assign enq_uop[2].p.vpu_vma = io_enq_2_bits_uop_vpu_vma;
  assign enq_uop[2].p.vpu_vta = io_enq_2_bits_uop_vpu_vta;
  assign enq_uop[2].p.vpu_vsew = io_enq_2_bits_uop_vpu_vsew;
  assign enq_uop[2].p.vpu_vlmul = io_enq_2_bits_uop_vpu_vlmul;
  assign enq_uop[2].p.vpu_specVill = io_enq_2_bits_uop_vpu_specVill;
  assign enq_uop[2].p.vpu_specVma = io_enq_2_bits_uop_vpu_specVma;
  assign enq_uop[2].p.vpu_specVta = io_enq_2_bits_uop_vpu_specVta;
  assign enq_uop[2].p.vpu_specVsew = io_enq_2_bits_uop_vpu_specVsew;
  assign enq_uop[2].p.vpu_specVlmul = io_enq_2_bits_uop_vpu_specVlmul;
  assign enq_uop[2].p.vpu_vm = io_enq_2_bits_uop_vpu_vm;
  assign enq_uop[2].p.vpu_vstart = io_enq_2_bits_uop_vpu_vstart;
  assign enq_uop[2].p.vpu_frm = io_enq_2_bits_uop_vpu_frm;
  assign enq_uop[2].p.vpu_fpu_isFpToVecInst = io_enq_2_bits_uop_vpu_fpu_isFpToVecInst;
  assign enq_uop[2].p.vpu_fpu_isFP32Instr = io_enq_2_bits_uop_vpu_fpu_isFP32Instr;
  assign enq_uop[2].p.vpu_fpu_isFP64Instr = io_enq_2_bits_uop_vpu_fpu_isFP64Instr;
  assign enq_uop[2].p.vpu_fpu_isReduction = io_enq_2_bits_uop_vpu_fpu_isReduction;
  assign enq_uop[2].p.vpu_fpu_isFoldTo1_2 = io_enq_2_bits_uop_vpu_fpu_isFoldTo1_2;
  assign enq_uop[2].p.vpu_fpu_isFoldTo1_4 = io_enq_2_bits_uop_vpu_fpu_isFoldTo1_4;
  assign enq_uop[2].p.vpu_fpu_isFoldTo1_8 = io_enq_2_bits_uop_vpu_fpu_isFoldTo1_8;
  assign enq_uop[2].p.vpu_vxrm = io_enq_2_bits_uop_vpu_vxrm;
  assign enq_uop[2].p.vpu_vuopIdx = io_enq_2_bits_uop_vpu_vuopIdx;
  assign enq_uop[2].p.vpu_lastUop = io_enq_2_bits_uop_vpu_lastUop;
  assign enq_uop[2].p.vpu_vmask = io_enq_2_bits_uop_vpu_vmask;
  assign enq_uop[2].p.vpu_vl = io_enq_2_bits_uop_vpu_vl;
  assign enq_uop[2].p.vpu_nf = io_enq_2_bits_uop_vpu_nf;
  assign enq_uop[2].p.vpu_veew = io_enq_2_bits_uop_vpu_veew;
  assign enq_uop[2].p.vpu_isReverse = io_enq_2_bits_uop_vpu_isReverse;
  assign enq_uop[2].p.vpu_isExt = io_enq_2_bits_uop_vpu_isExt;
  assign enq_uop[2].p.vpu_isNarrow = io_enq_2_bits_uop_vpu_isNarrow;
  assign enq_uop[2].p.vpu_isDstMask = io_enq_2_bits_uop_vpu_isDstMask;
  assign enq_uop[2].p.vpu_isOpMask = io_enq_2_bits_uop_vpu_isOpMask;
  assign enq_uop[2].p.vpu_isMove = io_enq_2_bits_uop_vpu_isMove;
  assign enq_uop[2].p.vpu_isDependOldVd = io_enq_2_bits_uop_vpu_isDependOldVd;
  assign enq_uop[2].p.vpu_isWritePartVd = io_enq_2_bits_uop_vpu_isWritePartVd;
  assign enq_uop[2].p.vpu_isVleff = io_enq_2_bits_uop_vpu_isVleff;
  assign enq_uop[2].p.vlsInstr = io_enq_2_bits_uop_vlsInstr;
  assign enq_uop[2].p.wfflags = io_enq_2_bits_uop_wfflags;
  assign enq_uop[2].p.isMove = io_enq_2_bits_uop_isMove;
  assign enq_uop[2].p.isDropAmocasSta = io_enq_2_bits_uop_isDropAmocasSta;
  assign enq_uop[2].p.uopIdx = io_enq_2_bits_uop_uopIdx;
  assign enq_uop[2].p.isVset = io_enq_2_bits_uop_isVset;
  assign enq_uop[2].p.firstUop = io_enq_2_bits_uop_firstUop;
  assign enq_uop[2].p.lastUop = io_enq_2_bits_uop_lastUop;
  assign enq_uop[2].p.numUops = io_enq_2_bits_uop_numUops;
  assign enq_uop[2].p.numWB = io_enq_2_bits_uop_numWB;
  assign enq_uop[2].p.commitType = io_enq_2_bits_uop_commitType;
  assign enq_uop[2].p.srcState_0 = io_enq_2_bits_uop_srcState_0;
  assign enq_uop[2].p.srcState_1 = io_enq_2_bits_uop_srcState_1;
  assign enq_uop[2].p.srcState_2 = io_enq_2_bits_uop_srcState_2;
  assign enq_uop[2].p.srcState_3 = io_enq_2_bits_uop_srcState_3;
  assign enq_uop[2].p.srcState_4 = io_enq_2_bits_uop_srcState_4;
  assign enq_uop[2].p.srcLoadDependency_0_0 = io_enq_2_bits_uop_srcLoadDependency_0_0;
  assign enq_uop[2].p.srcLoadDependency_0_1 = io_enq_2_bits_uop_srcLoadDependency_0_1;
  assign enq_uop[2].p.srcLoadDependency_0_2 = io_enq_2_bits_uop_srcLoadDependency_0_2;
  assign enq_uop[2].p.srcLoadDependency_1_0 = io_enq_2_bits_uop_srcLoadDependency_1_0;
  assign enq_uop[2].p.srcLoadDependency_1_1 = io_enq_2_bits_uop_srcLoadDependency_1_1;
  assign enq_uop[2].p.srcLoadDependency_1_2 = io_enq_2_bits_uop_srcLoadDependency_1_2;
  assign enq_uop[2].p.srcLoadDependency_2_0 = io_enq_2_bits_uop_srcLoadDependency_2_0;
  assign enq_uop[2].p.srcLoadDependency_2_1 = io_enq_2_bits_uop_srcLoadDependency_2_1;
  assign enq_uop[2].p.srcLoadDependency_2_2 = io_enq_2_bits_uop_srcLoadDependency_2_2;
  assign enq_uop[2].p.srcLoadDependency_3_0 = io_enq_2_bits_uop_srcLoadDependency_3_0;
  assign enq_uop[2].p.srcLoadDependency_3_1 = io_enq_2_bits_uop_srcLoadDependency_3_1;
  assign enq_uop[2].p.srcLoadDependency_3_2 = io_enq_2_bits_uop_srcLoadDependency_3_2;
  assign enq_uop[2].p.srcLoadDependency_4_0 = io_enq_2_bits_uop_srcLoadDependency_4_0;
  assign enq_uop[2].p.srcLoadDependency_4_1 = io_enq_2_bits_uop_srcLoadDependency_4_1;
  assign enq_uop[2].p.srcLoadDependency_4_2 = io_enq_2_bits_uop_srcLoadDependency_4_2;
  assign enq_uop[2].p.psrc_0 = io_enq_2_bits_uop_psrc_0;
  assign enq_uop[2].p.psrc_1 = io_enq_2_bits_uop_psrc_1;
  assign enq_uop[2].p.psrc_2 = io_enq_2_bits_uop_psrc_2;
  assign enq_uop[2].p.psrc_3 = io_enq_2_bits_uop_psrc_3;
  assign enq_uop[2].p.psrc_4 = io_enq_2_bits_uop_psrc_4;
  assign enq_uop[2].p.pdest = io_enq_2_bits_uop_pdest;
  assign enq_uop[2].p.useRegCache_0 = io_enq_2_bits_uop_useRegCache_0;
  assign enq_uop[2].p.useRegCache_1 = io_enq_2_bits_uop_useRegCache_1;
  assign enq_uop[2].p.regCacheIdx_0 = io_enq_2_bits_uop_regCacheIdx_0;
  assign enq_uop[2].p.regCacheIdx_1 = io_enq_2_bits_uop_regCacheIdx_1;
  assign enq_uop[2].p.robIdx_flag = io_enq_2_bits_uop_robIdx_flag;
  assign enq_uop[2].p.robIdx_value = io_enq_2_bits_uop_robIdx_value;
  assign enq_uop[2].p.instrSize = io_enq_2_bits_uop_instrSize;
  assign enq_uop[2].p.dirtyFs = io_enq_2_bits_uop_dirtyFs;
  assign enq_uop[2].p.dirtyVs = io_enq_2_bits_uop_dirtyVs;
  assign enq_uop[2].p.traceBlockInPipe_itype = io_enq_2_bits_uop_traceBlockInPipe_itype;
  assign enq_uop[2].p.traceBlockInPipe_iretire = io_enq_2_bits_uop_traceBlockInPipe_iretire;
  assign enq_uop[2].p.traceBlockInPipe_ilastsize = io_enq_2_bits_uop_traceBlockInPipe_ilastsize;
  assign enq_uop[2].p.eliminatedMove = io_enq_2_bits_uop_eliminatedMove;
  assign enq_uop[2].p.snapshot = io_enq_2_bits_uop_snapshot;
  assign enq_uop[2].p.debugInfo_eliminatedMove = io_enq_2_bits_uop_debugInfo_eliminatedMove;
  assign enq_uop[2].p.debugInfo_renameTime = io_enq_2_bits_uop_debugInfo_renameTime;
  assign enq_uop[2].p.debugInfo_dispatchTime = io_enq_2_bits_uop_debugInfo_dispatchTime;
  assign enq_uop[2].p.debugInfo_enqRsTime = io_enq_2_bits_uop_debugInfo_enqRsTime;
  assign enq_uop[2].p.debugInfo_selectTime = io_enq_2_bits_uop_debugInfo_selectTime;
  assign enq_uop[2].p.debugInfo_issueTime = io_enq_2_bits_uop_debugInfo_issueTime;
  assign enq_uop[2].p.debugInfo_writebackTime = io_enq_2_bits_uop_debugInfo_writebackTime;
  assign enq_uop[2].p.debugInfo_runahead_checkpoint_id = io_enq_2_bits_uop_debugInfo_runahead_checkpoint_id;
  assign enq_uop[2].p.debugInfo_tlbFirstReqTime = io_enq_2_bits_uop_debugInfo_tlbFirstReqTime;
  assign enq_uop[2].p.debugInfo_tlbRespTime = io_enq_2_bits_uop_debugInfo_tlbRespTime;
  assign enq_uop[2].p.debug_seqNum_seqNum = io_enq_2_bits_uop_debug_seqNum_seqNum;
  assign enq_uop[2].p.debug_seqNum_uopIdx = io_enq_2_bits_uop_debug_seqNum_uopIdx;
  assign enq_uop[2].p.storeSetHit = io_enq_2_bits_uop_storeSetHit;
  assign enq_uop[2].p.waitForRobIdx_flag = io_enq_2_bits_uop_waitForRobIdx_flag;
  assign enq_uop[2].p.waitForRobIdx_value = io_enq_2_bits_uop_waitForRobIdx_value;
  assign enq_uop[2].p.loadWaitBit = io_enq_2_bits_uop_loadWaitBit;
  assign enq_uop[2].loadWaitStrict = io_enq_2_bits_uop_loadWaitStrict;
  assign enq_uop[2].p.ssid = io_enq_2_bits_uop_ssid;
  assign enq_uop[2].p.lqIdx_flag = io_enq_2_bits_uop_lqIdx_flag;
  assign enq_uop[2].p.lqIdx_value = io_enq_2_bits_uop_lqIdx_value;
  assign enq_uop[2].p.sqIdx_flag = io_enq_2_bits_uop_sqIdx_flag;
  assign enq_uop[2].p.sqIdx_value = io_enq_2_bits_uop_sqIdx_value;
  assign enq_uop[2].p.singleStep = io_enq_2_bits_uop_singleStep;
  assign enq_uop[2].p.debug_fuType = io_enq_2_bits_uop_debug_fuType;
  assign enq_uop[2].p.debug_sim_trig = io_enq_2_bits_uop_debug_sim_trig;
  assign enq_uop[2].p.numLsElem = io_enq_2_bits_uop_numLsElem;
  assign enq_vaddr[2] = io_enq_2_bits_vaddr;
  assign enq_vec[2].mask = io_enq_2_bits_mask;
  assign enq_vec[2].isvec = io_enq_2_bits_isvec;
  assign enq_vec[2].is128bit = io_enq_2_bits_is128bit;
  assign enq_vec[2].elemIdx = io_enq_2_bits_elemIdx;
  assign enq_vec[2].alignedType = io_enq_2_bits_alignedType;
  assign enq_vec[2].mbIndex = io_enq_2_bits_mbIndex;
  assign enq_vec[2].reg_offset = io_enq_2_bits_reg_offset;
  assign enq_vec[2].elemIdxInsideVd = io_enq_2_bits_elemIdxInsideVd;
  assign enq_vec[2].vecActive = io_enq_2_bits_vecActive;
  assign enq_isLoadReplay[2] = io_enq_2_bits_isLoadReplay;
  assign enq_handledByMSHR[2] = io_enq_2_bits_handledByMSHR;
  assign enq_schedIndex[2] = io_enq_2_bits_schedIndex;
  assign enq_mshr_id[2] = io_enq_2_bits_rep_info_mshr_id;
  assign enq_full_fwd[2] = io_enq_2_bits_rep_info_full_fwd;
  assign enq_data_inv_sq_idx[2].flag = io_enq_2_bits_rep_info_data_inv_sq_idx_flag;
  assign enq_data_inv_sq_idx[2].value = io_enq_2_bits_rep_info_data_inv_sq_idx_value;
  assign enq_addr_inv_sq_idx[2].flag = io_enq_2_bits_rep_info_addr_inv_sq_idx_flag;
  assign enq_addr_inv_sq_idx[2].value = io_enq_2_bits_rep_info_addr_inv_sq_idx_value;
  assign enq_last_beat[2] = io_enq_2_bits_rep_info_last_beat;
  assign enq_cause[2][0] = io_enq_2_bits_rep_info_cause_0;
  assign enq_cause[2][1] = io_enq_2_bits_rep_info_cause_1;
  assign enq_cause[2][2] = io_enq_2_bits_rep_info_cause_2;
  assign enq_cause[2][3] = io_enq_2_bits_rep_info_cause_3;
  assign enq_cause[2][4] = io_enq_2_bits_rep_info_cause_4;
  assign enq_cause[2][5] = io_enq_2_bits_rep_info_cause_5;
  assign enq_cause[2][6] = io_enq_2_bits_rep_info_cause_6;
  assign enq_cause[2][7] = io_enq_2_bits_rep_info_cause_7;
  assign enq_cause[2][8] = io_enq_2_bits_rep_info_cause_8;
  assign enq_cause[2][9] = io_enq_2_bits_rep_info_cause_9;
  assign enq_cause[2][10] = io_enq_2_bits_rep_info_cause_10;
  assign enq_tlb_id[2] = io_enq_2_bits_rep_info_tlb_id;
  assign enq_tlb_full[2] = io_enq_2_bits_rep_info_tlb_full;
  assign staIn_valid[0] = io_storeAddrIn_0_valid;
  assign staIn_sqIdx[0].flag = io_storeAddrIn_0_bits_uop_sqIdx_flag;
  assign staIn_sqIdx[0].value = io_storeAddrIn_0_bits_uop_sqIdx_value;
  assign staIn_miss[0] = io_storeAddrIn_0_bits_miss;
  assign staIn_valid[1] = io_storeAddrIn_1_valid;
  assign staIn_sqIdx[1].flag = io_storeAddrIn_1_bits_uop_sqIdx_flag;
  assign staIn_sqIdx[1].value = io_storeAddrIn_1_bits_uop_sqIdx_value;
  assign staIn_miss[1] = io_storeAddrIn_1_bits_miss;
  assign stdIn_valid[0] = io_storeDataIn_0_valid;
  assign stdIn_sqIdx[0].flag = io_storeDataIn_0_bits_uop_sqIdx_flag;
  assign stdIn_sqIdx[0].value = io_storeDataIn_0_bits_uop_sqIdx_value;
  assign stdIn_valid[1] = io_storeDataIn_1_valid;
  assign stdIn_sqIdx[1].flag = io_storeDataIn_1_bits_uop_sqIdx_flag;
  assign stdIn_sqIdx[1].value = io_storeDataIn_1_bits_uop_sqIdx_value;
  assign replay_ready[0] = io_replay_0_ready;
  assign replay_ready[1] = io_replay_1_ready;
  assign replay_ready[2] = io_replay_2_ready;
  assign tl_d_valid = io_tl_d_channel_valid;
  assign tl_d_mshrid = io_tl_d_channel_mshrid;
  assign stAddrReadySqPtr.flag = io_stAddrReadySqPtr_flag;
  assign stAddrReadySqPtr.value = io_stAddrReadySqPtr_value;
  assign stAddrReadyVec[0] = io_stAddrReadyVec_0;
  assign stAddrReadyVec[1] = io_stAddrReadyVec_1;
  assign stAddrReadyVec[2] = io_stAddrReadyVec_2;
  assign stAddrReadyVec[3] = io_stAddrReadyVec_3;
  assign stAddrReadyVec[4] = io_stAddrReadyVec_4;
  assign stAddrReadyVec[5] = io_stAddrReadyVec_5;
  assign stAddrReadyVec[6] = io_stAddrReadyVec_6;
  assign stAddrReadyVec[7] = io_stAddrReadyVec_7;
  assign stAddrReadyVec[8] = io_stAddrReadyVec_8;
  assign stAddrReadyVec[9] = io_stAddrReadyVec_9;
  assign stAddrReadyVec[10] = io_stAddrReadyVec_10;
  assign stAddrReadyVec[11] = io_stAddrReadyVec_11;
  assign stAddrReadyVec[12] = io_stAddrReadyVec_12;
  assign stAddrReadyVec[13] = io_stAddrReadyVec_13;
  assign stAddrReadyVec[14] = io_stAddrReadyVec_14;
  assign stAddrReadyVec[15] = io_stAddrReadyVec_15;
  assign stAddrReadyVec[16] = io_stAddrReadyVec_16;
  assign stAddrReadyVec[17] = io_stAddrReadyVec_17;
  assign stAddrReadyVec[18] = io_stAddrReadyVec_18;
  assign stAddrReadyVec[19] = io_stAddrReadyVec_19;
  assign stAddrReadyVec[20] = io_stAddrReadyVec_20;
  assign stAddrReadyVec[21] = io_stAddrReadyVec_21;
  assign stAddrReadyVec[22] = io_stAddrReadyVec_22;
  assign stAddrReadyVec[23] = io_stAddrReadyVec_23;
  assign stAddrReadyVec[24] = io_stAddrReadyVec_24;
  assign stAddrReadyVec[25] = io_stAddrReadyVec_25;
  assign stAddrReadyVec[26] = io_stAddrReadyVec_26;
  assign stAddrReadyVec[27] = io_stAddrReadyVec_27;
  assign stAddrReadyVec[28] = io_stAddrReadyVec_28;
  assign stAddrReadyVec[29] = io_stAddrReadyVec_29;
  assign stAddrReadyVec[30] = io_stAddrReadyVec_30;
  assign stAddrReadyVec[31] = io_stAddrReadyVec_31;
  assign stAddrReadyVec[32] = io_stAddrReadyVec_32;
  assign stAddrReadyVec[33] = io_stAddrReadyVec_33;
  assign stAddrReadyVec[34] = io_stAddrReadyVec_34;
  assign stAddrReadyVec[35] = io_stAddrReadyVec_35;
  assign stAddrReadyVec[36] = io_stAddrReadyVec_36;
  assign stAddrReadyVec[37] = io_stAddrReadyVec_37;
  assign stAddrReadyVec[38] = io_stAddrReadyVec_38;
  assign stAddrReadyVec[39] = io_stAddrReadyVec_39;
  assign stAddrReadyVec[40] = io_stAddrReadyVec_40;
  assign stAddrReadyVec[41] = io_stAddrReadyVec_41;
  assign stAddrReadyVec[42] = io_stAddrReadyVec_42;
  assign stAddrReadyVec[43] = io_stAddrReadyVec_43;
  assign stAddrReadyVec[44] = io_stAddrReadyVec_44;
  assign stAddrReadyVec[45] = io_stAddrReadyVec_45;
  assign stAddrReadyVec[46] = io_stAddrReadyVec_46;
  assign stAddrReadyVec[47] = io_stAddrReadyVec_47;
  assign stAddrReadyVec[48] = io_stAddrReadyVec_48;
  assign stAddrReadyVec[49] = io_stAddrReadyVec_49;
  assign stAddrReadyVec[50] = io_stAddrReadyVec_50;
  assign stAddrReadyVec[51] = io_stAddrReadyVec_51;
  assign stAddrReadyVec[52] = io_stAddrReadyVec_52;
  assign stAddrReadyVec[53] = io_stAddrReadyVec_53;
  assign stAddrReadyVec[54] = io_stAddrReadyVec_54;
  assign stAddrReadyVec[55] = io_stAddrReadyVec_55;
  assign stDataReadySqPtr.flag = io_stDataReadySqPtr_flag;
  assign stDataReadySqPtr.value = io_stDataReadySqPtr_value;
  assign stDataReadyVec[0] = io_stDataReadyVec_0;
  assign stDataReadyVec[1] = io_stDataReadyVec_1;
  assign stDataReadyVec[2] = io_stDataReadyVec_2;
  assign stDataReadyVec[3] = io_stDataReadyVec_3;
  assign stDataReadyVec[4] = io_stDataReadyVec_4;
  assign stDataReadyVec[5] = io_stDataReadyVec_5;
  assign stDataReadyVec[6] = io_stDataReadyVec_6;
  assign stDataReadyVec[7] = io_stDataReadyVec_7;
  assign stDataReadyVec[8] = io_stDataReadyVec_8;
  assign stDataReadyVec[9] = io_stDataReadyVec_9;
  assign stDataReadyVec[10] = io_stDataReadyVec_10;
  assign stDataReadyVec[11] = io_stDataReadyVec_11;
  assign stDataReadyVec[12] = io_stDataReadyVec_12;
  assign stDataReadyVec[13] = io_stDataReadyVec_13;
  assign stDataReadyVec[14] = io_stDataReadyVec_14;
  assign stDataReadyVec[15] = io_stDataReadyVec_15;
  assign stDataReadyVec[16] = io_stDataReadyVec_16;
  assign stDataReadyVec[17] = io_stDataReadyVec_17;
  assign stDataReadyVec[18] = io_stDataReadyVec_18;
  assign stDataReadyVec[19] = io_stDataReadyVec_19;
  assign stDataReadyVec[20] = io_stDataReadyVec_20;
  assign stDataReadyVec[21] = io_stDataReadyVec_21;
  assign stDataReadyVec[22] = io_stDataReadyVec_22;
  assign stDataReadyVec[23] = io_stDataReadyVec_23;
  assign stDataReadyVec[24] = io_stDataReadyVec_24;
  assign stDataReadyVec[25] = io_stDataReadyVec_25;
  assign stDataReadyVec[26] = io_stDataReadyVec_26;
  assign stDataReadyVec[27] = io_stDataReadyVec_27;
  assign stDataReadyVec[28] = io_stDataReadyVec_28;
  assign stDataReadyVec[29] = io_stDataReadyVec_29;
  assign stDataReadyVec[30] = io_stDataReadyVec_30;
  assign stDataReadyVec[31] = io_stDataReadyVec_31;
  assign stDataReadyVec[32] = io_stDataReadyVec_32;
  assign stDataReadyVec[33] = io_stDataReadyVec_33;
  assign stDataReadyVec[34] = io_stDataReadyVec_34;
  assign stDataReadyVec[35] = io_stDataReadyVec_35;
  assign stDataReadyVec[36] = io_stDataReadyVec_36;
  assign stDataReadyVec[37] = io_stDataReadyVec_37;
  assign stDataReadyVec[38] = io_stDataReadyVec_38;
  assign stDataReadyVec[39] = io_stDataReadyVec_39;
  assign stDataReadyVec[40] = io_stDataReadyVec_40;
  assign stDataReadyVec[41] = io_stDataReadyVec_41;
  assign stDataReadyVec[42] = io_stDataReadyVec_42;
  assign stDataReadyVec[43] = io_stDataReadyVec_43;
  assign stDataReadyVec[44] = io_stDataReadyVec_44;
  assign stDataReadyVec[45] = io_stDataReadyVec_45;
  assign stDataReadyVec[46] = io_stDataReadyVec_46;
  assign stDataReadyVec[47] = io_stDataReadyVec_47;
  assign stDataReadyVec[48] = io_stDataReadyVec_48;
  assign stDataReadyVec[49] = io_stDataReadyVec_49;
  assign stDataReadyVec[50] = io_stDataReadyVec_50;
  assign stDataReadyVec[51] = io_stDataReadyVec_51;
  assign stDataReadyVec[52] = io_stDataReadyVec_52;
  assign stDataReadyVec[53] = io_stDataReadyVec_53;
  assign stDataReadyVec[54] = io_stDataReadyVec_54;
  assign stDataReadyVec[55] = io_stDataReadyVec_55;
  assign sqEmpty = io_sqEmpty;
  assign ldWbPtr.flag = io_ldWbPtr_flag;
  assign ldWbPtr.value = io_ldWbPtr_value;
  assign robDeqPtr.flag = io_robDeqPtr_flag;
  assign robDeqPtr.value = io_robDeqPtr_value;
  assign rarFull = io_rarFull;
  assign rawFull = io_rawFull;
  assign l2_hint_valid = io_l2_hint_valid;
  assign l2_hint_sourceId = io_l2_hint_bits_sourceId;
  assign l2_hint_isKeyword = io_l2_hint_bits_isKeyword;
  assign tlb_hint_valid = io_tlb_hint_resp_valid;
  assign tlb_hint_id = io_tlb_hint_resp_bits_id;
  assign tlb_hint_replay_all = io_tlb_hint_resp_bits_replay_all;
  assign dtd_robHeadVaddr_valid = io_debugTopDown_robHeadVaddr_valid;
  assign dtd_robHeadVaddr_bits = io_debugTopDown_robHeadVaddr_bits;
  assign dtd_robHeadMissInDTlb = io_debugTopDown_robHeadMissInDTlb;

  // ---- 核例化 ----
  xs_LoadQueueReplay_core u_core (.*);

  // ---- 输出拆包：核 struct/数组 -> golden 扁平端口 ----
  assign io_replay_0_valid = replay_valid[0];
  assign io_replay_0_bits_uop_instr = replay_uop[0].p.instr;
  assign io_replay_0_bits_uop_pc = replay_uop[0].p.pc;
  assign io_replay_0_bits_uop_foldpc = replay_uop[0].p.foldpc;
  assign io_replay_0_bits_uop_exceptionVec_0 = replay_uop[0].exceptionVec[0];
  assign io_replay_0_bits_uop_exceptionVec_1 = replay_uop[0].exceptionVec[1];
  assign io_replay_0_bits_uop_exceptionVec_2 = replay_uop[0].exceptionVec[2];
  assign io_replay_0_bits_uop_exceptionVec_3 = replay_uop[0].exceptionVec[3];
  assign io_replay_0_bits_uop_exceptionVec_5 = replay_uop[0].exceptionVec[5];
  assign io_replay_0_bits_uop_exceptionVec_6 = replay_uop[0].exceptionVec[6];
  assign io_replay_0_bits_uop_exceptionVec_7 = replay_uop[0].exceptionVec[7];
  assign io_replay_0_bits_uop_exceptionVec_8 = replay_uop[0].exceptionVec[8];
  assign io_replay_0_bits_uop_exceptionVec_9 = replay_uop[0].exceptionVec[9];
  assign io_replay_0_bits_uop_exceptionVec_10 = replay_uop[0].exceptionVec[10];
  assign io_replay_0_bits_uop_exceptionVec_11 = replay_uop[0].exceptionVec[11];
  assign io_replay_0_bits_uop_exceptionVec_12 = replay_uop[0].exceptionVec[12];
  assign io_replay_0_bits_uop_exceptionVec_13 = replay_uop[0].exceptionVec[13];
  assign io_replay_0_bits_uop_exceptionVec_14 = replay_uop[0].exceptionVec[14];
  assign io_replay_0_bits_uop_exceptionVec_15 = replay_uop[0].exceptionVec[15];
  assign io_replay_0_bits_uop_exceptionVec_16 = replay_uop[0].exceptionVec[16];
  assign io_replay_0_bits_uop_exceptionVec_17 = replay_uop[0].exceptionVec[17];
  assign io_replay_0_bits_uop_exceptionVec_18 = replay_uop[0].exceptionVec[18];
  assign io_replay_0_bits_uop_exceptionVec_19 = replay_uop[0].exceptionVec[19];
  assign io_replay_0_bits_uop_exceptionVec_20 = replay_uop[0].exceptionVec[20];
  assign io_replay_0_bits_uop_exceptionVec_21 = replay_uop[0].exceptionVec[21];
  assign io_replay_0_bits_uop_exceptionVec_22 = replay_uop[0].exceptionVec[22];
  assign io_replay_0_bits_uop_exceptionVec_23 = replay_uop[0].exceptionVec[23];
  assign io_replay_0_bits_uop_isFetchMalAddr = replay_uop[0].p.isFetchMalAddr;
  assign io_replay_0_bits_uop_hasException = replay_uop[0].p.hasException;
  assign io_replay_0_bits_uop_trigger = replay_uop[0].p.trigger;
  assign io_replay_0_bits_uop_preDecodeInfo_valid = replay_uop[0].p.preDecodeInfo_valid;
  assign io_replay_0_bits_uop_preDecodeInfo_isRVC = replay_uop[0].p.preDecodeInfo_isRVC;
  assign io_replay_0_bits_uop_preDecodeInfo_brType = replay_uop[0].p.preDecodeInfo_brType;
  assign io_replay_0_bits_uop_preDecodeInfo_isCall = replay_uop[0].p.preDecodeInfo_isCall;
  assign io_replay_0_bits_uop_preDecodeInfo_isRet = replay_uop[0].p.preDecodeInfo_isRet;
  assign io_replay_0_bits_uop_pred_taken = replay_uop[0].p.pred_taken;
  assign io_replay_0_bits_uop_crossPageIPFFix = replay_uop[0].p.crossPageIPFFix;
  assign io_replay_0_bits_uop_ftqPtr_flag = replay_uop[0].p.ftqPtr_flag;
  assign io_replay_0_bits_uop_ftqPtr_value = replay_uop[0].p.ftqPtr_value;
  assign io_replay_0_bits_uop_ftqOffset = replay_uop[0].p.ftqOffset;
  assign io_replay_0_bits_uop_satpFlushFirstFetchFault = replay_uop[0].p.satpFlushFirstFetchFault;
  assign io_replay_0_bits_uop_srcType_0 = replay_uop[0].p.srcType_0;
  assign io_replay_0_bits_uop_srcType_1 = replay_uop[0].p.srcType_1;
  assign io_replay_0_bits_uop_srcType_2 = replay_uop[0].p.srcType_2;
  assign io_replay_0_bits_uop_srcType_3 = replay_uop[0].p.srcType_3;
  assign io_replay_0_bits_uop_srcType_4 = replay_uop[0].p.srcType_4;
  assign io_replay_0_bits_uop_ldest = replay_uop[0].p.ldest;
  assign io_replay_0_bits_uop_fuType = replay_uop[0].p.fuType;
  assign io_replay_0_bits_uop_fuOpType = replay_uop[0].p.fuOpType;
  assign io_replay_0_bits_uop_rfWen = replay_uop[0].p.rfWen;
  assign io_replay_0_bits_uop_fpWen = replay_uop[0].p.fpWen;
  assign io_replay_0_bits_uop_vecWen = replay_uop[0].p.vecWen;
  assign io_replay_0_bits_uop_v0Wen = replay_uop[0].p.v0Wen;
  assign io_replay_0_bits_uop_vlWen = replay_uop[0].p.vlWen;
  assign io_replay_0_bits_uop_isXSTrap = replay_uop[0].p.isXSTrap;
  assign io_replay_0_bits_uop_waitForward = replay_uop[0].p.waitForward;
  assign io_replay_0_bits_uop_blockBackward = replay_uop[0].p.blockBackward;
  assign io_replay_0_bits_uop_canRobCompress = replay_uop[0].p.canRobCompress;
  assign io_replay_0_bits_uop_selImm = replay_uop[0].p.selImm;
  assign io_replay_0_bits_uop_imm = replay_uop[0].p.imm;
  assign io_replay_0_bits_uop_fpu_typeTagOut = replay_uop[0].p.fpu_typeTagOut;
  assign io_replay_0_bits_uop_fpu_wflags = replay_uop[0].p.fpu_wflags;
  assign io_replay_0_bits_uop_fpu_typ = replay_uop[0].p.fpu_typ;
  assign io_replay_0_bits_uop_fpu_fmt = replay_uop[0].p.fpu_fmt;
  assign io_replay_0_bits_uop_fpu_rm = replay_uop[0].p.fpu_rm;
  assign io_replay_0_bits_uop_vpu_vill = replay_uop[0].p.vpu_vill;
  assign io_replay_0_bits_uop_vpu_vma = replay_uop[0].p.vpu_vma;
  assign io_replay_0_bits_uop_vpu_vta = replay_uop[0].p.vpu_vta;
  assign io_replay_0_bits_uop_vpu_vsew = replay_uop[0].p.vpu_vsew;
  assign io_replay_0_bits_uop_vpu_vlmul = replay_uop[0].p.vpu_vlmul;
  assign io_replay_0_bits_uop_vpu_specVill = replay_uop[0].p.vpu_specVill;
  assign io_replay_0_bits_uop_vpu_specVma = replay_uop[0].p.vpu_specVma;
  assign io_replay_0_bits_uop_vpu_specVta = replay_uop[0].p.vpu_specVta;
  assign io_replay_0_bits_uop_vpu_specVsew = replay_uop[0].p.vpu_specVsew;
  assign io_replay_0_bits_uop_vpu_specVlmul = replay_uop[0].p.vpu_specVlmul;
  assign io_replay_0_bits_uop_vpu_vm = replay_uop[0].p.vpu_vm;
  assign io_replay_0_bits_uop_vpu_vstart = replay_uop[0].p.vpu_vstart;
  assign io_replay_0_bits_uop_vpu_frm = replay_uop[0].p.vpu_frm;
  assign io_replay_0_bits_uop_vpu_fpu_isFpToVecInst = replay_uop[0].p.vpu_fpu_isFpToVecInst;
  assign io_replay_0_bits_uop_vpu_fpu_isFP32Instr = replay_uop[0].p.vpu_fpu_isFP32Instr;
  assign io_replay_0_bits_uop_vpu_fpu_isFP64Instr = replay_uop[0].p.vpu_fpu_isFP64Instr;
  assign io_replay_0_bits_uop_vpu_fpu_isReduction = replay_uop[0].p.vpu_fpu_isReduction;
  assign io_replay_0_bits_uop_vpu_fpu_isFoldTo1_2 = replay_uop[0].p.vpu_fpu_isFoldTo1_2;
  assign io_replay_0_bits_uop_vpu_fpu_isFoldTo1_4 = replay_uop[0].p.vpu_fpu_isFoldTo1_4;
  assign io_replay_0_bits_uop_vpu_fpu_isFoldTo1_8 = replay_uop[0].p.vpu_fpu_isFoldTo1_8;
  assign io_replay_0_bits_uop_vpu_vxrm = replay_uop[0].p.vpu_vxrm;
  assign io_replay_0_bits_uop_vpu_vuopIdx = replay_uop[0].p.vpu_vuopIdx;
  assign io_replay_0_bits_uop_vpu_lastUop = replay_uop[0].p.vpu_lastUop;
  assign io_replay_0_bits_uop_vpu_vmask = replay_uop[0].p.vpu_vmask;
  assign io_replay_0_bits_uop_vpu_vl = replay_uop[0].p.vpu_vl;
  assign io_replay_0_bits_uop_vpu_nf = replay_uop[0].p.vpu_nf;
  assign io_replay_0_bits_uop_vpu_veew = replay_uop[0].p.vpu_veew;
  assign io_replay_0_bits_uop_vpu_isReverse = replay_uop[0].p.vpu_isReverse;
  assign io_replay_0_bits_uop_vpu_isExt = replay_uop[0].p.vpu_isExt;
  assign io_replay_0_bits_uop_vpu_isNarrow = replay_uop[0].p.vpu_isNarrow;
  assign io_replay_0_bits_uop_vpu_isDstMask = replay_uop[0].p.vpu_isDstMask;
  assign io_replay_0_bits_uop_vpu_isOpMask = replay_uop[0].p.vpu_isOpMask;
  assign io_replay_0_bits_uop_vpu_isMove = replay_uop[0].p.vpu_isMove;
  assign io_replay_0_bits_uop_vpu_isDependOldVd = replay_uop[0].p.vpu_isDependOldVd;
  assign io_replay_0_bits_uop_vpu_isWritePartVd = replay_uop[0].p.vpu_isWritePartVd;
  assign io_replay_0_bits_uop_vpu_isVleff = replay_uop[0].p.vpu_isVleff;
  assign io_replay_0_bits_uop_vlsInstr = replay_uop[0].p.vlsInstr;
  assign io_replay_0_bits_uop_wfflags = replay_uop[0].p.wfflags;
  assign io_replay_0_bits_uop_isMove = replay_uop[0].p.isMove;
  assign io_replay_0_bits_uop_isDropAmocasSta = replay_uop[0].p.isDropAmocasSta;
  assign io_replay_0_bits_uop_uopIdx = replay_uop[0].p.uopIdx;
  assign io_replay_0_bits_uop_isVset = replay_uop[0].p.isVset;
  assign io_replay_0_bits_uop_firstUop = replay_uop[0].p.firstUop;
  assign io_replay_0_bits_uop_lastUop = replay_uop[0].p.lastUop;
  assign io_replay_0_bits_uop_numUops = replay_uop[0].p.numUops;
  assign io_replay_0_bits_uop_numWB = replay_uop[0].p.numWB;
  assign io_replay_0_bits_uop_commitType = replay_uop[0].p.commitType;
  assign io_replay_0_bits_uop_srcState_0 = replay_uop[0].p.srcState_0;
  assign io_replay_0_bits_uop_srcState_1 = replay_uop[0].p.srcState_1;
  assign io_replay_0_bits_uop_srcState_2 = replay_uop[0].p.srcState_2;
  assign io_replay_0_bits_uop_srcState_3 = replay_uop[0].p.srcState_3;
  assign io_replay_0_bits_uop_srcState_4 = replay_uop[0].p.srcState_4;
  assign io_replay_0_bits_uop_srcLoadDependency_0_0 = replay_uop[0].p.srcLoadDependency_0_0;
  assign io_replay_0_bits_uop_srcLoadDependency_0_1 = replay_uop[0].p.srcLoadDependency_0_1;
  assign io_replay_0_bits_uop_srcLoadDependency_0_2 = replay_uop[0].p.srcLoadDependency_0_2;
  assign io_replay_0_bits_uop_srcLoadDependency_1_0 = replay_uop[0].p.srcLoadDependency_1_0;
  assign io_replay_0_bits_uop_srcLoadDependency_1_1 = replay_uop[0].p.srcLoadDependency_1_1;
  assign io_replay_0_bits_uop_srcLoadDependency_1_2 = replay_uop[0].p.srcLoadDependency_1_2;
  assign io_replay_0_bits_uop_srcLoadDependency_2_0 = replay_uop[0].p.srcLoadDependency_2_0;
  assign io_replay_0_bits_uop_srcLoadDependency_2_1 = replay_uop[0].p.srcLoadDependency_2_1;
  assign io_replay_0_bits_uop_srcLoadDependency_2_2 = replay_uop[0].p.srcLoadDependency_2_2;
  assign io_replay_0_bits_uop_srcLoadDependency_3_0 = replay_uop[0].p.srcLoadDependency_3_0;
  assign io_replay_0_bits_uop_srcLoadDependency_3_1 = replay_uop[0].p.srcLoadDependency_3_1;
  assign io_replay_0_bits_uop_srcLoadDependency_3_2 = replay_uop[0].p.srcLoadDependency_3_2;
  assign io_replay_0_bits_uop_srcLoadDependency_4_0 = replay_uop[0].p.srcLoadDependency_4_0;
  assign io_replay_0_bits_uop_srcLoadDependency_4_1 = replay_uop[0].p.srcLoadDependency_4_1;
  assign io_replay_0_bits_uop_srcLoadDependency_4_2 = replay_uop[0].p.srcLoadDependency_4_2;
  assign io_replay_0_bits_uop_psrc_0 = replay_uop[0].p.psrc_0;
  assign io_replay_0_bits_uop_psrc_1 = replay_uop[0].p.psrc_1;
  assign io_replay_0_bits_uop_psrc_2 = replay_uop[0].p.psrc_2;
  assign io_replay_0_bits_uop_psrc_3 = replay_uop[0].p.psrc_3;
  assign io_replay_0_bits_uop_psrc_4 = replay_uop[0].p.psrc_4;
  assign io_replay_0_bits_uop_pdest = replay_uop[0].p.pdest;
  assign io_replay_0_bits_uop_useRegCache_0 = replay_uop[0].p.useRegCache_0;
  assign io_replay_0_bits_uop_useRegCache_1 = replay_uop[0].p.useRegCache_1;
  assign io_replay_0_bits_uop_regCacheIdx_0 = replay_uop[0].p.regCacheIdx_0;
  assign io_replay_0_bits_uop_regCacheIdx_1 = replay_uop[0].p.regCacheIdx_1;
  assign io_replay_0_bits_uop_robIdx_flag = replay_uop[0].p.robIdx_flag;
  assign io_replay_0_bits_uop_robIdx_value = replay_uop[0].p.robIdx_value;
  assign io_replay_0_bits_uop_instrSize = replay_uop[0].p.instrSize;
  assign io_replay_0_bits_uop_dirtyFs = replay_uop[0].p.dirtyFs;
  assign io_replay_0_bits_uop_dirtyVs = replay_uop[0].p.dirtyVs;
  assign io_replay_0_bits_uop_traceBlockInPipe_itype = replay_uop[0].p.traceBlockInPipe_itype;
  assign io_replay_0_bits_uop_traceBlockInPipe_iretire = replay_uop[0].p.traceBlockInPipe_iretire;
  assign io_replay_0_bits_uop_traceBlockInPipe_ilastsize = replay_uop[0].p.traceBlockInPipe_ilastsize;
  assign io_replay_0_bits_uop_eliminatedMove = replay_uop[0].p.eliminatedMove;
  assign io_replay_0_bits_uop_snapshot = replay_uop[0].p.snapshot;
  assign io_replay_0_bits_uop_debugInfo_eliminatedMove = replay_uop[0].p.debugInfo_eliminatedMove;
  assign io_replay_0_bits_uop_debugInfo_renameTime = replay_uop[0].p.debugInfo_renameTime;
  assign io_replay_0_bits_uop_debugInfo_dispatchTime = replay_uop[0].p.debugInfo_dispatchTime;
  assign io_replay_0_bits_uop_debugInfo_enqRsTime = replay_uop[0].p.debugInfo_enqRsTime;
  assign io_replay_0_bits_uop_debugInfo_selectTime = replay_uop[0].p.debugInfo_selectTime;
  assign io_replay_0_bits_uop_debugInfo_issueTime = replay_uop[0].p.debugInfo_issueTime;
  assign io_replay_0_bits_uop_debugInfo_writebackTime = replay_uop[0].p.debugInfo_writebackTime;
  assign io_replay_0_bits_uop_debugInfo_runahead_checkpoint_id = replay_uop[0].p.debugInfo_runahead_checkpoint_id;
  assign io_replay_0_bits_uop_debugInfo_tlbFirstReqTime = replay_uop[0].p.debugInfo_tlbFirstReqTime;
  assign io_replay_0_bits_uop_debugInfo_tlbRespTime = replay_uop[0].p.debugInfo_tlbRespTime;
  assign io_replay_0_bits_uop_debug_seqNum_seqNum = replay_uop[0].p.debug_seqNum_seqNum;
  assign io_replay_0_bits_uop_debug_seqNum_uopIdx = replay_uop[0].p.debug_seqNum_uopIdx;
  assign io_replay_0_bits_uop_storeSetHit = replay_uop[0].p.storeSetHit;
  assign io_replay_0_bits_uop_waitForRobIdx_flag = replay_uop[0].p.waitForRobIdx_flag;
  assign io_replay_0_bits_uop_waitForRobIdx_value = replay_uop[0].p.waitForRobIdx_value;
  assign io_replay_0_bits_uop_loadWaitBit = replay_uop[0].p.loadWaitBit;
  assign io_replay_0_bits_uop_ssid = replay_uop[0].p.ssid;
  assign io_replay_0_bits_uop_lqIdx_flag = replay_uop[0].p.lqIdx_flag;
  assign io_replay_0_bits_uop_lqIdx_value = replay_uop[0].p.lqIdx_value;
  assign io_replay_0_bits_uop_sqIdx_flag = replay_uop[0].p.sqIdx_flag;
  assign io_replay_0_bits_uop_sqIdx_value = replay_uop[0].p.sqIdx_value;
  assign io_replay_0_bits_uop_singleStep = replay_uop[0].p.singleStep;
  assign io_replay_0_bits_uop_debug_fuType = replay_uop[0].p.debug_fuType;
  assign io_replay_0_bits_uop_debug_sim_trig = replay_uop[0].p.debug_sim_trig;
  assign io_replay_0_bits_uop_numLsElem = replay_uop[0].p.numLsElem;
  assign io_replay_0_bits_vaddr = replay_vaddr[0];
  assign io_replay_0_bits_mask = replay_vec[0].mask;
  assign io_replay_0_bits_isvec = replay_vec[0].isvec;
  assign io_replay_0_bits_is128bit = replay_vec[0].is128bit;
  assign io_replay_0_bits_elemIdx = replay_vec[0].elemIdx;
  assign io_replay_0_bits_alignedType = replay_vec[0].alignedType;
  assign io_replay_0_bits_mbIndex = replay_vec[0].mbIndex;
  assign io_replay_0_bits_reg_offset = replay_vec[0].reg_offset;
  assign io_replay_0_bits_elemIdxInsideVd = replay_vec[0].elemIdxInsideVd;
  assign io_replay_0_bits_vecActive = replay_vec[0].vecActive;
  assign io_replay_0_bits_mshrid = replay_mshrid[0];
  assign io_replay_0_bits_forward_tlDchannel = replay_forward_tlDchannel[0];
  assign io_replay_0_bits_schedIndex = replay_schedIndex[0];
  assign io_replay_1_valid = replay_valid[1];
  assign io_replay_1_bits_uop_instr = replay_uop[1].p.instr;
  assign io_replay_1_bits_uop_pc = replay_uop[1].p.pc;
  assign io_replay_1_bits_uop_foldpc = replay_uop[1].p.foldpc;
  assign io_replay_1_bits_uop_exceptionVec_0 = replay_uop[1].exceptionVec[0];
  assign io_replay_1_bits_uop_exceptionVec_1 = replay_uop[1].exceptionVec[1];
  assign io_replay_1_bits_uop_exceptionVec_2 = replay_uop[1].exceptionVec[2];
  assign io_replay_1_bits_uop_exceptionVec_3 = replay_uop[1].exceptionVec[3];
  assign io_replay_1_bits_uop_exceptionVec_5 = replay_uop[1].exceptionVec[5];
  assign io_replay_1_bits_uop_exceptionVec_6 = replay_uop[1].exceptionVec[6];
  assign io_replay_1_bits_uop_exceptionVec_7 = replay_uop[1].exceptionVec[7];
  assign io_replay_1_bits_uop_exceptionVec_8 = replay_uop[1].exceptionVec[8];
  assign io_replay_1_bits_uop_exceptionVec_9 = replay_uop[1].exceptionVec[9];
  assign io_replay_1_bits_uop_exceptionVec_10 = replay_uop[1].exceptionVec[10];
  assign io_replay_1_bits_uop_exceptionVec_11 = replay_uop[1].exceptionVec[11];
  assign io_replay_1_bits_uop_exceptionVec_12 = replay_uop[1].exceptionVec[12];
  assign io_replay_1_bits_uop_exceptionVec_13 = replay_uop[1].exceptionVec[13];
  assign io_replay_1_bits_uop_exceptionVec_14 = replay_uop[1].exceptionVec[14];
  assign io_replay_1_bits_uop_exceptionVec_15 = replay_uop[1].exceptionVec[15];
  assign io_replay_1_bits_uop_exceptionVec_16 = replay_uop[1].exceptionVec[16];
  assign io_replay_1_bits_uop_exceptionVec_17 = replay_uop[1].exceptionVec[17];
  assign io_replay_1_bits_uop_exceptionVec_18 = replay_uop[1].exceptionVec[18];
  assign io_replay_1_bits_uop_exceptionVec_19 = replay_uop[1].exceptionVec[19];
  assign io_replay_1_bits_uop_exceptionVec_20 = replay_uop[1].exceptionVec[20];
  assign io_replay_1_bits_uop_exceptionVec_21 = replay_uop[1].exceptionVec[21];
  assign io_replay_1_bits_uop_exceptionVec_22 = replay_uop[1].exceptionVec[22];
  assign io_replay_1_bits_uop_exceptionVec_23 = replay_uop[1].exceptionVec[23];
  assign io_replay_1_bits_uop_isFetchMalAddr = replay_uop[1].p.isFetchMalAddr;
  assign io_replay_1_bits_uop_hasException = replay_uop[1].p.hasException;
  assign io_replay_1_bits_uop_trigger = replay_uop[1].p.trigger;
  assign io_replay_1_bits_uop_preDecodeInfo_valid = replay_uop[1].p.preDecodeInfo_valid;
  assign io_replay_1_bits_uop_preDecodeInfo_isRVC = replay_uop[1].p.preDecodeInfo_isRVC;
  assign io_replay_1_bits_uop_preDecodeInfo_brType = replay_uop[1].p.preDecodeInfo_brType;
  assign io_replay_1_bits_uop_preDecodeInfo_isCall = replay_uop[1].p.preDecodeInfo_isCall;
  assign io_replay_1_bits_uop_preDecodeInfo_isRet = replay_uop[1].p.preDecodeInfo_isRet;
  assign io_replay_1_bits_uop_pred_taken = replay_uop[1].p.pred_taken;
  assign io_replay_1_bits_uop_crossPageIPFFix = replay_uop[1].p.crossPageIPFFix;
  assign io_replay_1_bits_uop_ftqPtr_flag = replay_uop[1].p.ftqPtr_flag;
  assign io_replay_1_bits_uop_ftqPtr_value = replay_uop[1].p.ftqPtr_value;
  assign io_replay_1_bits_uop_ftqOffset = replay_uop[1].p.ftqOffset;
  assign io_replay_1_bits_uop_satpFlushFirstFetchFault = replay_uop[1].p.satpFlushFirstFetchFault;
  assign io_replay_1_bits_uop_srcType_0 = replay_uop[1].p.srcType_0;
  assign io_replay_1_bits_uop_srcType_1 = replay_uop[1].p.srcType_1;
  assign io_replay_1_bits_uop_srcType_2 = replay_uop[1].p.srcType_2;
  assign io_replay_1_bits_uop_srcType_3 = replay_uop[1].p.srcType_3;
  assign io_replay_1_bits_uop_srcType_4 = replay_uop[1].p.srcType_4;
  assign io_replay_1_bits_uop_ldest = replay_uop[1].p.ldest;
  assign io_replay_1_bits_uop_fuType = replay_uop[1].p.fuType;
  assign io_replay_1_bits_uop_fuOpType = replay_uop[1].p.fuOpType;
  assign io_replay_1_bits_uop_rfWen = replay_uop[1].p.rfWen;
  assign io_replay_1_bits_uop_fpWen = replay_uop[1].p.fpWen;
  assign io_replay_1_bits_uop_vecWen = replay_uop[1].p.vecWen;
  assign io_replay_1_bits_uop_v0Wen = replay_uop[1].p.v0Wen;
  assign io_replay_1_bits_uop_vlWen = replay_uop[1].p.vlWen;
  assign io_replay_1_bits_uop_isXSTrap = replay_uop[1].p.isXSTrap;
  assign io_replay_1_bits_uop_waitForward = replay_uop[1].p.waitForward;
  assign io_replay_1_bits_uop_blockBackward = replay_uop[1].p.blockBackward;
  assign io_replay_1_bits_uop_canRobCompress = replay_uop[1].p.canRobCompress;
  assign io_replay_1_bits_uop_selImm = replay_uop[1].p.selImm;
  assign io_replay_1_bits_uop_imm = replay_uop[1].p.imm;
  assign io_replay_1_bits_uop_fpu_typeTagOut = replay_uop[1].p.fpu_typeTagOut;
  assign io_replay_1_bits_uop_fpu_wflags = replay_uop[1].p.fpu_wflags;
  assign io_replay_1_bits_uop_fpu_typ = replay_uop[1].p.fpu_typ;
  assign io_replay_1_bits_uop_fpu_fmt = replay_uop[1].p.fpu_fmt;
  assign io_replay_1_bits_uop_fpu_rm = replay_uop[1].p.fpu_rm;
  assign io_replay_1_bits_uop_vpu_vill = replay_uop[1].p.vpu_vill;
  assign io_replay_1_bits_uop_vpu_vma = replay_uop[1].p.vpu_vma;
  assign io_replay_1_bits_uop_vpu_vta = replay_uop[1].p.vpu_vta;
  assign io_replay_1_bits_uop_vpu_vsew = replay_uop[1].p.vpu_vsew;
  assign io_replay_1_bits_uop_vpu_vlmul = replay_uop[1].p.vpu_vlmul;
  assign io_replay_1_bits_uop_vpu_specVill = replay_uop[1].p.vpu_specVill;
  assign io_replay_1_bits_uop_vpu_specVma = replay_uop[1].p.vpu_specVma;
  assign io_replay_1_bits_uop_vpu_specVta = replay_uop[1].p.vpu_specVta;
  assign io_replay_1_bits_uop_vpu_specVsew = replay_uop[1].p.vpu_specVsew;
  assign io_replay_1_bits_uop_vpu_specVlmul = replay_uop[1].p.vpu_specVlmul;
  assign io_replay_1_bits_uop_vpu_vm = replay_uop[1].p.vpu_vm;
  assign io_replay_1_bits_uop_vpu_vstart = replay_uop[1].p.vpu_vstart;
  assign io_replay_1_bits_uop_vpu_frm = replay_uop[1].p.vpu_frm;
  assign io_replay_1_bits_uop_vpu_fpu_isFpToVecInst = replay_uop[1].p.vpu_fpu_isFpToVecInst;
  assign io_replay_1_bits_uop_vpu_fpu_isFP32Instr = replay_uop[1].p.vpu_fpu_isFP32Instr;
  assign io_replay_1_bits_uop_vpu_fpu_isFP64Instr = replay_uop[1].p.vpu_fpu_isFP64Instr;
  assign io_replay_1_bits_uop_vpu_fpu_isReduction = replay_uop[1].p.vpu_fpu_isReduction;
  assign io_replay_1_bits_uop_vpu_fpu_isFoldTo1_2 = replay_uop[1].p.vpu_fpu_isFoldTo1_2;
  assign io_replay_1_bits_uop_vpu_fpu_isFoldTo1_4 = replay_uop[1].p.vpu_fpu_isFoldTo1_4;
  assign io_replay_1_bits_uop_vpu_fpu_isFoldTo1_8 = replay_uop[1].p.vpu_fpu_isFoldTo1_8;
  assign io_replay_1_bits_uop_vpu_vxrm = replay_uop[1].p.vpu_vxrm;
  assign io_replay_1_bits_uop_vpu_vuopIdx = replay_uop[1].p.vpu_vuopIdx;
  assign io_replay_1_bits_uop_vpu_lastUop = replay_uop[1].p.vpu_lastUop;
  assign io_replay_1_bits_uop_vpu_vmask = replay_uop[1].p.vpu_vmask;
  assign io_replay_1_bits_uop_vpu_vl = replay_uop[1].p.vpu_vl;
  assign io_replay_1_bits_uop_vpu_nf = replay_uop[1].p.vpu_nf;
  assign io_replay_1_bits_uop_vpu_veew = replay_uop[1].p.vpu_veew;
  assign io_replay_1_bits_uop_vpu_isReverse = replay_uop[1].p.vpu_isReverse;
  assign io_replay_1_bits_uop_vpu_isExt = replay_uop[1].p.vpu_isExt;
  assign io_replay_1_bits_uop_vpu_isNarrow = replay_uop[1].p.vpu_isNarrow;
  assign io_replay_1_bits_uop_vpu_isDstMask = replay_uop[1].p.vpu_isDstMask;
  assign io_replay_1_bits_uop_vpu_isOpMask = replay_uop[1].p.vpu_isOpMask;
  assign io_replay_1_bits_uop_vpu_isMove = replay_uop[1].p.vpu_isMove;
  assign io_replay_1_bits_uop_vpu_isDependOldVd = replay_uop[1].p.vpu_isDependOldVd;
  assign io_replay_1_bits_uop_vpu_isWritePartVd = replay_uop[1].p.vpu_isWritePartVd;
  assign io_replay_1_bits_uop_vpu_isVleff = replay_uop[1].p.vpu_isVleff;
  assign io_replay_1_bits_uop_vlsInstr = replay_uop[1].p.vlsInstr;
  assign io_replay_1_bits_uop_wfflags = replay_uop[1].p.wfflags;
  assign io_replay_1_bits_uop_isMove = replay_uop[1].p.isMove;
  assign io_replay_1_bits_uop_isDropAmocasSta = replay_uop[1].p.isDropAmocasSta;
  assign io_replay_1_bits_uop_uopIdx = replay_uop[1].p.uopIdx;
  assign io_replay_1_bits_uop_isVset = replay_uop[1].p.isVset;
  assign io_replay_1_bits_uop_firstUop = replay_uop[1].p.firstUop;
  assign io_replay_1_bits_uop_lastUop = replay_uop[1].p.lastUop;
  assign io_replay_1_bits_uop_numUops = replay_uop[1].p.numUops;
  assign io_replay_1_bits_uop_numWB = replay_uop[1].p.numWB;
  assign io_replay_1_bits_uop_commitType = replay_uop[1].p.commitType;
  assign io_replay_1_bits_uop_srcState_0 = replay_uop[1].p.srcState_0;
  assign io_replay_1_bits_uop_srcState_1 = replay_uop[1].p.srcState_1;
  assign io_replay_1_bits_uop_srcState_2 = replay_uop[1].p.srcState_2;
  assign io_replay_1_bits_uop_srcState_3 = replay_uop[1].p.srcState_3;
  assign io_replay_1_bits_uop_srcState_4 = replay_uop[1].p.srcState_4;
  assign io_replay_1_bits_uop_srcLoadDependency_0_0 = replay_uop[1].p.srcLoadDependency_0_0;
  assign io_replay_1_bits_uop_srcLoadDependency_0_1 = replay_uop[1].p.srcLoadDependency_0_1;
  assign io_replay_1_bits_uop_srcLoadDependency_0_2 = replay_uop[1].p.srcLoadDependency_0_2;
  assign io_replay_1_bits_uop_srcLoadDependency_1_0 = replay_uop[1].p.srcLoadDependency_1_0;
  assign io_replay_1_bits_uop_srcLoadDependency_1_1 = replay_uop[1].p.srcLoadDependency_1_1;
  assign io_replay_1_bits_uop_srcLoadDependency_1_2 = replay_uop[1].p.srcLoadDependency_1_2;
  assign io_replay_1_bits_uop_srcLoadDependency_2_0 = replay_uop[1].p.srcLoadDependency_2_0;
  assign io_replay_1_bits_uop_srcLoadDependency_2_1 = replay_uop[1].p.srcLoadDependency_2_1;
  assign io_replay_1_bits_uop_srcLoadDependency_2_2 = replay_uop[1].p.srcLoadDependency_2_2;
  assign io_replay_1_bits_uop_srcLoadDependency_3_0 = replay_uop[1].p.srcLoadDependency_3_0;
  assign io_replay_1_bits_uop_srcLoadDependency_3_1 = replay_uop[1].p.srcLoadDependency_3_1;
  assign io_replay_1_bits_uop_srcLoadDependency_3_2 = replay_uop[1].p.srcLoadDependency_3_2;
  assign io_replay_1_bits_uop_srcLoadDependency_4_0 = replay_uop[1].p.srcLoadDependency_4_0;
  assign io_replay_1_bits_uop_srcLoadDependency_4_1 = replay_uop[1].p.srcLoadDependency_4_1;
  assign io_replay_1_bits_uop_srcLoadDependency_4_2 = replay_uop[1].p.srcLoadDependency_4_2;
  assign io_replay_1_bits_uop_psrc_0 = replay_uop[1].p.psrc_0;
  assign io_replay_1_bits_uop_psrc_1 = replay_uop[1].p.psrc_1;
  assign io_replay_1_bits_uop_psrc_2 = replay_uop[1].p.psrc_2;
  assign io_replay_1_bits_uop_psrc_3 = replay_uop[1].p.psrc_3;
  assign io_replay_1_bits_uop_psrc_4 = replay_uop[1].p.psrc_4;
  assign io_replay_1_bits_uop_pdest = replay_uop[1].p.pdest;
  assign io_replay_1_bits_uop_useRegCache_0 = replay_uop[1].p.useRegCache_0;
  assign io_replay_1_bits_uop_useRegCache_1 = replay_uop[1].p.useRegCache_1;
  assign io_replay_1_bits_uop_regCacheIdx_0 = replay_uop[1].p.regCacheIdx_0;
  assign io_replay_1_bits_uop_regCacheIdx_1 = replay_uop[1].p.regCacheIdx_1;
  assign io_replay_1_bits_uop_robIdx_flag = replay_uop[1].p.robIdx_flag;
  assign io_replay_1_bits_uop_robIdx_value = replay_uop[1].p.robIdx_value;
  assign io_replay_1_bits_uop_instrSize = replay_uop[1].p.instrSize;
  assign io_replay_1_bits_uop_dirtyFs = replay_uop[1].p.dirtyFs;
  assign io_replay_1_bits_uop_dirtyVs = replay_uop[1].p.dirtyVs;
  assign io_replay_1_bits_uop_traceBlockInPipe_itype = replay_uop[1].p.traceBlockInPipe_itype;
  assign io_replay_1_bits_uop_traceBlockInPipe_iretire = replay_uop[1].p.traceBlockInPipe_iretire;
  assign io_replay_1_bits_uop_traceBlockInPipe_ilastsize = replay_uop[1].p.traceBlockInPipe_ilastsize;
  assign io_replay_1_bits_uop_eliminatedMove = replay_uop[1].p.eliminatedMove;
  assign io_replay_1_bits_uop_snapshot = replay_uop[1].p.snapshot;
  assign io_replay_1_bits_uop_debugInfo_eliminatedMove = replay_uop[1].p.debugInfo_eliminatedMove;
  assign io_replay_1_bits_uop_debugInfo_renameTime = replay_uop[1].p.debugInfo_renameTime;
  assign io_replay_1_bits_uop_debugInfo_dispatchTime = replay_uop[1].p.debugInfo_dispatchTime;
  assign io_replay_1_bits_uop_debugInfo_enqRsTime = replay_uop[1].p.debugInfo_enqRsTime;
  assign io_replay_1_bits_uop_debugInfo_selectTime = replay_uop[1].p.debugInfo_selectTime;
  assign io_replay_1_bits_uop_debugInfo_issueTime = replay_uop[1].p.debugInfo_issueTime;
  assign io_replay_1_bits_uop_debugInfo_writebackTime = replay_uop[1].p.debugInfo_writebackTime;
  assign io_replay_1_bits_uop_debugInfo_runahead_checkpoint_id = replay_uop[1].p.debugInfo_runahead_checkpoint_id;
  assign io_replay_1_bits_uop_debugInfo_tlbFirstReqTime = replay_uop[1].p.debugInfo_tlbFirstReqTime;
  assign io_replay_1_bits_uop_debugInfo_tlbRespTime = replay_uop[1].p.debugInfo_tlbRespTime;
  assign io_replay_1_bits_uop_debug_seqNum_seqNum = replay_uop[1].p.debug_seqNum_seqNum;
  assign io_replay_1_bits_uop_debug_seqNum_uopIdx = replay_uop[1].p.debug_seqNum_uopIdx;
  assign io_replay_1_bits_uop_storeSetHit = replay_uop[1].p.storeSetHit;
  assign io_replay_1_bits_uop_waitForRobIdx_flag = replay_uop[1].p.waitForRobIdx_flag;
  assign io_replay_1_bits_uop_waitForRobIdx_value = replay_uop[1].p.waitForRobIdx_value;
  assign io_replay_1_bits_uop_loadWaitBit = replay_uop[1].p.loadWaitBit;
  assign io_replay_1_bits_uop_ssid = replay_uop[1].p.ssid;
  assign io_replay_1_bits_uop_lqIdx_flag = replay_uop[1].p.lqIdx_flag;
  assign io_replay_1_bits_uop_lqIdx_value = replay_uop[1].p.lqIdx_value;
  assign io_replay_1_bits_uop_sqIdx_flag = replay_uop[1].p.sqIdx_flag;
  assign io_replay_1_bits_uop_sqIdx_value = replay_uop[1].p.sqIdx_value;
  assign io_replay_1_bits_uop_singleStep = replay_uop[1].p.singleStep;
  assign io_replay_1_bits_uop_debug_fuType = replay_uop[1].p.debug_fuType;
  assign io_replay_1_bits_uop_debug_sim_trig = replay_uop[1].p.debug_sim_trig;
  assign io_replay_1_bits_uop_numLsElem = replay_uop[1].p.numLsElem;
  assign io_replay_1_bits_vaddr = replay_vaddr[1];
  assign io_replay_1_bits_mask = replay_vec[1].mask;
  assign io_replay_1_bits_isvec = replay_vec[1].isvec;
  assign io_replay_1_bits_is128bit = replay_vec[1].is128bit;
  assign io_replay_1_bits_elemIdx = replay_vec[1].elemIdx;
  assign io_replay_1_bits_alignedType = replay_vec[1].alignedType;
  assign io_replay_1_bits_mbIndex = replay_vec[1].mbIndex;
  assign io_replay_1_bits_reg_offset = replay_vec[1].reg_offset;
  assign io_replay_1_bits_elemIdxInsideVd = replay_vec[1].elemIdxInsideVd;
  assign io_replay_1_bits_vecActive = replay_vec[1].vecActive;
  assign io_replay_1_bits_mshrid = replay_mshrid[1];
  assign io_replay_1_bits_forward_tlDchannel = replay_forward_tlDchannel[1];
  assign io_replay_1_bits_schedIndex = replay_schedIndex[1];
  assign io_replay_2_valid = replay_valid[2];
  assign io_replay_2_bits_uop_instr = replay_uop[2].p.instr;
  assign io_replay_2_bits_uop_pc = replay_uop[2].p.pc;
  assign io_replay_2_bits_uop_foldpc = replay_uop[2].p.foldpc;
  assign io_replay_2_bits_uop_exceptionVec_0 = replay_uop[2].exceptionVec[0];
  assign io_replay_2_bits_uop_exceptionVec_1 = replay_uop[2].exceptionVec[1];
  assign io_replay_2_bits_uop_exceptionVec_2 = replay_uop[2].exceptionVec[2];
  assign io_replay_2_bits_uop_exceptionVec_3 = replay_uop[2].exceptionVec[3];
  assign io_replay_2_bits_uop_exceptionVec_5 = replay_uop[2].exceptionVec[5];
  assign io_replay_2_bits_uop_exceptionVec_6 = replay_uop[2].exceptionVec[6];
  assign io_replay_2_bits_uop_exceptionVec_7 = replay_uop[2].exceptionVec[7];
  assign io_replay_2_bits_uop_exceptionVec_8 = replay_uop[2].exceptionVec[8];
  assign io_replay_2_bits_uop_exceptionVec_9 = replay_uop[2].exceptionVec[9];
  assign io_replay_2_bits_uop_exceptionVec_10 = replay_uop[2].exceptionVec[10];
  assign io_replay_2_bits_uop_exceptionVec_11 = replay_uop[2].exceptionVec[11];
  assign io_replay_2_bits_uop_exceptionVec_12 = replay_uop[2].exceptionVec[12];
  assign io_replay_2_bits_uop_exceptionVec_13 = replay_uop[2].exceptionVec[13];
  assign io_replay_2_bits_uop_exceptionVec_14 = replay_uop[2].exceptionVec[14];
  assign io_replay_2_bits_uop_exceptionVec_15 = replay_uop[2].exceptionVec[15];
  assign io_replay_2_bits_uop_exceptionVec_16 = replay_uop[2].exceptionVec[16];
  assign io_replay_2_bits_uop_exceptionVec_17 = replay_uop[2].exceptionVec[17];
  assign io_replay_2_bits_uop_exceptionVec_18 = replay_uop[2].exceptionVec[18];
  assign io_replay_2_bits_uop_exceptionVec_19 = replay_uop[2].exceptionVec[19];
  assign io_replay_2_bits_uop_exceptionVec_20 = replay_uop[2].exceptionVec[20];
  assign io_replay_2_bits_uop_exceptionVec_21 = replay_uop[2].exceptionVec[21];
  assign io_replay_2_bits_uop_exceptionVec_22 = replay_uop[2].exceptionVec[22];
  assign io_replay_2_bits_uop_exceptionVec_23 = replay_uop[2].exceptionVec[23];
  assign io_replay_2_bits_uop_isFetchMalAddr = replay_uop[2].p.isFetchMalAddr;
  assign io_replay_2_bits_uop_hasException = replay_uop[2].p.hasException;
  assign io_replay_2_bits_uop_trigger = replay_uop[2].p.trigger;
  assign io_replay_2_bits_uop_preDecodeInfo_valid = replay_uop[2].p.preDecodeInfo_valid;
  assign io_replay_2_bits_uop_preDecodeInfo_isRVC = replay_uop[2].p.preDecodeInfo_isRVC;
  assign io_replay_2_bits_uop_preDecodeInfo_brType = replay_uop[2].p.preDecodeInfo_brType;
  assign io_replay_2_bits_uop_preDecodeInfo_isCall = replay_uop[2].p.preDecodeInfo_isCall;
  assign io_replay_2_bits_uop_preDecodeInfo_isRet = replay_uop[2].p.preDecodeInfo_isRet;
  assign io_replay_2_bits_uop_pred_taken = replay_uop[2].p.pred_taken;
  assign io_replay_2_bits_uop_crossPageIPFFix = replay_uop[2].p.crossPageIPFFix;
  assign io_replay_2_bits_uop_ftqPtr_flag = replay_uop[2].p.ftqPtr_flag;
  assign io_replay_2_bits_uop_ftqPtr_value = replay_uop[2].p.ftqPtr_value;
  assign io_replay_2_bits_uop_ftqOffset = replay_uop[2].p.ftqOffset;
  assign io_replay_2_bits_uop_satpFlushFirstFetchFault = replay_uop[2].p.satpFlushFirstFetchFault;
  assign io_replay_2_bits_uop_srcType_0 = replay_uop[2].p.srcType_0;
  assign io_replay_2_bits_uop_srcType_1 = replay_uop[2].p.srcType_1;
  assign io_replay_2_bits_uop_srcType_2 = replay_uop[2].p.srcType_2;
  assign io_replay_2_bits_uop_srcType_3 = replay_uop[2].p.srcType_3;
  assign io_replay_2_bits_uop_srcType_4 = replay_uop[2].p.srcType_4;
  assign io_replay_2_bits_uop_ldest = replay_uop[2].p.ldest;
  assign io_replay_2_bits_uop_fuType = replay_uop[2].p.fuType;
  assign io_replay_2_bits_uop_fuOpType = replay_uop[2].p.fuOpType;
  assign io_replay_2_bits_uop_rfWen = replay_uop[2].p.rfWen;
  assign io_replay_2_bits_uop_fpWen = replay_uop[2].p.fpWen;
  assign io_replay_2_bits_uop_vecWen = replay_uop[2].p.vecWen;
  assign io_replay_2_bits_uop_v0Wen = replay_uop[2].p.v0Wen;
  assign io_replay_2_bits_uop_vlWen = replay_uop[2].p.vlWen;
  assign io_replay_2_bits_uop_isXSTrap = replay_uop[2].p.isXSTrap;
  assign io_replay_2_bits_uop_waitForward = replay_uop[2].p.waitForward;
  assign io_replay_2_bits_uop_blockBackward = replay_uop[2].p.blockBackward;
  assign io_replay_2_bits_uop_canRobCompress = replay_uop[2].p.canRobCompress;
  assign io_replay_2_bits_uop_selImm = replay_uop[2].p.selImm;
  assign io_replay_2_bits_uop_imm = replay_uop[2].p.imm;
  assign io_replay_2_bits_uop_fpu_typeTagOut = replay_uop[2].p.fpu_typeTagOut;
  assign io_replay_2_bits_uop_fpu_wflags = replay_uop[2].p.fpu_wflags;
  assign io_replay_2_bits_uop_fpu_typ = replay_uop[2].p.fpu_typ;
  assign io_replay_2_bits_uop_fpu_fmt = replay_uop[2].p.fpu_fmt;
  assign io_replay_2_bits_uop_fpu_rm = replay_uop[2].p.fpu_rm;
  assign io_replay_2_bits_uop_vpu_vill = replay_uop[2].p.vpu_vill;
  assign io_replay_2_bits_uop_vpu_vma = replay_uop[2].p.vpu_vma;
  assign io_replay_2_bits_uop_vpu_vta = replay_uop[2].p.vpu_vta;
  assign io_replay_2_bits_uop_vpu_vsew = replay_uop[2].p.vpu_vsew;
  assign io_replay_2_bits_uop_vpu_vlmul = replay_uop[2].p.vpu_vlmul;
  assign io_replay_2_bits_uop_vpu_specVill = replay_uop[2].p.vpu_specVill;
  assign io_replay_2_bits_uop_vpu_specVma = replay_uop[2].p.vpu_specVma;
  assign io_replay_2_bits_uop_vpu_specVta = replay_uop[2].p.vpu_specVta;
  assign io_replay_2_bits_uop_vpu_specVsew = replay_uop[2].p.vpu_specVsew;
  assign io_replay_2_bits_uop_vpu_specVlmul = replay_uop[2].p.vpu_specVlmul;
  assign io_replay_2_bits_uop_vpu_vm = replay_uop[2].p.vpu_vm;
  assign io_replay_2_bits_uop_vpu_vstart = replay_uop[2].p.vpu_vstart;
  assign io_replay_2_bits_uop_vpu_frm = replay_uop[2].p.vpu_frm;
  assign io_replay_2_bits_uop_vpu_fpu_isFpToVecInst = replay_uop[2].p.vpu_fpu_isFpToVecInst;
  assign io_replay_2_bits_uop_vpu_fpu_isFP32Instr = replay_uop[2].p.vpu_fpu_isFP32Instr;
  assign io_replay_2_bits_uop_vpu_fpu_isFP64Instr = replay_uop[2].p.vpu_fpu_isFP64Instr;
  assign io_replay_2_bits_uop_vpu_fpu_isReduction = replay_uop[2].p.vpu_fpu_isReduction;
  assign io_replay_2_bits_uop_vpu_fpu_isFoldTo1_2 = replay_uop[2].p.vpu_fpu_isFoldTo1_2;
  assign io_replay_2_bits_uop_vpu_fpu_isFoldTo1_4 = replay_uop[2].p.vpu_fpu_isFoldTo1_4;
  assign io_replay_2_bits_uop_vpu_fpu_isFoldTo1_8 = replay_uop[2].p.vpu_fpu_isFoldTo1_8;
  assign io_replay_2_bits_uop_vpu_vxrm = replay_uop[2].p.vpu_vxrm;
  assign io_replay_2_bits_uop_vpu_vuopIdx = replay_uop[2].p.vpu_vuopIdx;
  assign io_replay_2_bits_uop_vpu_lastUop = replay_uop[2].p.vpu_lastUop;
  assign io_replay_2_bits_uop_vpu_vmask = replay_uop[2].p.vpu_vmask;
  assign io_replay_2_bits_uop_vpu_vl = replay_uop[2].p.vpu_vl;
  assign io_replay_2_bits_uop_vpu_nf = replay_uop[2].p.vpu_nf;
  assign io_replay_2_bits_uop_vpu_veew = replay_uop[2].p.vpu_veew;
  assign io_replay_2_bits_uop_vpu_isReverse = replay_uop[2].p.vpu_isReverse;
  assign io_replay_2_bits_uop_vpu_isExt = replay_uop[2].p.vpu_isExt;
  assign io_replay_2_bits_uop_vpu_isNarrow = replay_uop[2].p.vpu_isNarrow;
  assign io_replay_2_bits_uop_vpu_isDstMask = replay_uop[2].p.vpu_isDstMask;
  assign io_replay_2_bits_uop_vpu_isOpMask = replay_uop[2].p.vpu_isOpMask;
  assign io_replay_2_bits_uop_vpu_isMove = replay_uop[2].p.vpu_isMove;
  assign io_replay_2_bits_uop_vpu_isDependOldVd = replay_uop[2].p.vpu_isDependOldVd;
  assign io_replay_2_bits_uop_vpu_isWritePartVd = replay_uop[2].p.vpu_isWritePartVd;
  assign io_replay_2_bits_uop_vpu_isVleff = replay_uop[2].p.vpu_isVleff;
  assign io_replay_2_bits_uop_vlsInstr = replay_uop[2].p.vlsInstr;
  assign io_replay_2_bits_uop_wfflags = replay_uop[2].p.wfflags;
  assign io_replay_2_bits_uop_isMove = replay_uop[2].p.isMove;
  assign io_replay_2_bits_uop_isDropAmocasSta = replay_uop[2].p.isDropAmocasSta;
  assign io_replay_2_bits_uop_uopIdx = replay_uop[2].p.uopIdx;
  assign io_replay_2_bits_uop_isVset = replay_uop[2].p.isVset;
  assign io_replay_2_bits_uop_firstUop = replay_uop[2].p.firstUop;
  assign io_replay_2_bits_uop_lastUop = replay_uop[2].p.lastUop;
  assign io_replay_2_bits_uop_numUops = replay_uop[2].p.numUops;
  assign io_replay_2_bits_uop_numWB = replay_uop[2].p.numWB;
  assign io_replay_2_bits_uop_commitType = replay_uop[2].p.commitType;
  assign io_replay_2_bits_uop_srcState_0 = replay_uop[2].p.srcState_0;
  assign io_replay_2_bits_uop_srcState_1 = replay_uop[2].p.srcState_1;
  assign io_replay_2_bits_uop_srcState_2 = replay_uop[2].p.srcState_2;
  assign io_replay_2_bits_uop_srcState_3 = replay_uop[2].p.srcState_3;
  assign io_replay_2_bits_uop_srcState_4 = replay_uop[2].p.srcState_4;
  assign io_replay_2_bits_uop_srcLoadDependency_0_0 = replay_uop[2].p.srcLoadDependency_0_0;
  assign io_replay_2_bits_uop_srcLoadDependency_0_1 = replay_uop[2].p.srcLoadDependency_0_1;
  assign io_replay_2_bits_uop_srcLoadDependency_0_2 = replay_uop[2].p.srcLoadDependency_0_2;
  assign io_replay_2_bits_uop_srcLoadDependency_1_0 = replay_uop[2].p.srcLoadDependency_1_0;
  assign io_replay_2_bits_uop_srcLoadDependency_1_1 = replay_uop[2].p.srcLoadDependency_1_1;
  assign io_replay_2_bits_uop_srcLoadDependency_1_2 = replay_uop[2].p.srcLoadDependency_1_2;
  assign io_replay_2_bits_uop_srcLoadDependency_2_0 = replay_uop[2].p.srcLoadDependency_2_0;
  assign io_replay_2_bits_uop_srcLoadDependency_2_1 = replay_uop[2].p.srcLoadDependency_2_1;
  assign io_replay_2_bits_uop_srcLoadDependency_2_2 = replay_uop[2].p.srcLoadDependency_2_2;
  assign io_replay_2_bits_uop_srcLoadDependency_3_0 = replay_uop[2].p.srcLoadDependency_3_0;
  assign io_replay_2_bits_uop_srcLoadDependency_3_1 = replay_uop[2].p.srcLoadDependency_3_1;
  assign io_replay_2_bits_uop_srcLoadDependency_3_2 = replay_uop[2].p.srcLoadDependency_3_2;
  assign io_replay_2_bits_uop_srcLoadDependency_4_0 = replay_uop[2].p.srcLoadDependency_4_0;
  assign io_replay_2_bits_uop_srcLoadDependency_4_1 = replay_uop[2].p.srcLoadDependency_4_1;
  assign io_replay_2_bits_uop_srcLoadDependency_4_2 = replay_uop[2].p.srcLoadDependency_4_2;
  assign io_replay_2_bits_uop_psrc_0 = replay_uop[2].p.psrc_0;
  assign io_replay_2_bits_uop_psrc_1 = replay_uop[2].p.psrc_1;
  assign io_replay_2_bits_uop_psrc_2 = replay_uop[2].p.psrc_2;
  assign io_replay_2_bits_uop_psrc_3 = replay_uop[2].p.psrc_3;
  assign io_replay_2_bits_uop_psrc_4 = replay_uop[2].p.psrc_4;
  assign io_replay_2_bits_uop_pdest = replay_uop[2].p.pdest;
  assign io_replay_2_bits_uop_useRegCache_0 = replay_uop[2].p.useRegCache_0;
  assign io_replay_2_bits_uop_useRegCache_1 = replay_uop[2].p.useRegCache_1;
  assign io_replay_2_bits_uop_regCacheIdx_0 = replay_uop[2].p.regCacheIdx_0;
  assign io_replay_2_bits_uop_regCacheIdx_1 = replay_uop[2].p.regCacheIdx_1;
  assign io_replay_2_bits_uop_robIdx_flag = replay_uop[2].p.robIdx_flag;
  assign io_replay_2_bits_uop_robIdx_value = replay_uop[2].p.robIdx_value;
  assign io_replay_2_bits_uop_instrSize = replay_uop[2].p.instrSize;
  assign io_replay_2_bits_uop_dirtyFs = replay_uop[2].p.dirtyFs;
  assign io_replay_2_bits_uop_dirtyVs = replay_uop[2].p.dirtyVs;
  assign io_replay_2_bits_uop_traceBlockInPipe_itype = replay_uop[2].p.traceBlockInPipe_itype;
  assign io_replay_2_bits_uop_traceBlockInPipe_iretire = replay_uop[2].p.traceBlockInPipe_iretire;
  assign io_replay_2_bits_uop_traceBlockInPipe_ilastsize = replay_uop[2].p.traceBlockInPipe_ilastsize;
  assign io_replay_2_bits_uop_eliminatedMove = replay_uop[2].p.eliminatedMove;
  assign io_replay_2_bits_uop_snapshot = replay_uop[2].p.snapshot;
  assign io_replay_2_bits_uop_debugInfo_eliminatedMove = replay_uop[2].p.debugInfo_eliminatedMove;
  assign io_replay_2_bits_uop_debugInfo_renameTime = replay_uop[2].p.debugInfo_renameTime;
  assign io_replay_2_bits_uop_debugInfo_dispatchTime = replay_uop[2].p.debugInfo_dispatchTime;
  assign io_replay_2_bits_uop_debugInfo_enqRsTime = replay_uop[2].p.debugInfo_enqRsTime;
  assign io_replay_2_bits_uop_debugInfo_selectTime = replay_uop[2].p.debugInfo_selectTime;
  assign io_replay_2_bits_uop_debugInfo_issueTime = replay_uop[2].p.debugInfo_issueTime;
  assign io_replay_2_bits_uop_debugInfo_writebackTime = replay_uop[2].p.debugInfo_writebackTime;
  assign io_replay_2_bits_uop_debugInfo_runahead_checkpoint_id = replay_uop[2].p.debugInfo_runahead_checkpoint_id;
  assign io_replay_2_bits_uop_debugInfo_tlbFirstReqTime = replay_uop[2].p.debugInfo_tlbFirstReqTime;
  assign io_replay_2_bits_uop_debugInfo_tlbRespTime = replay_uop[2].p.debugInfo_tlbRespTime;
  assign io_replay_2_bits_uop_debug_seqNum_seqNum = replay_uop[2].p.debug_seqNum_seqNum;
  assign io_replay_2_bits_uop_debug_seqNum_uopIdx = replay_uop[2].p.debug_seqNum_uopIdx;
  assign io_replay_2_bits_uop_storeSetHit = replay_uop[2].p.storeSetHit;
  assign io_replay_2_bits_uop_waitForRobIdx_flag = replay_uop[2].p.waitForRobIdx_flag;
  assign io_replay_2_bits_uop_waitForRobIdx_value = replay_uop[2].p.waitForRobIdx_value;
  assign io_replay_2_bits_uop_loadWaitBit = replay_uop[2].p.loadWaitBit;
  assign io_replay_2_bits_uop_ssid = replay_uop[2].p.ssid;
  assign io_replay_2_bits_uop_lqIdx_flag = replay_uop[2].p.lqIdx_flag;
  assign io_replay_2_bits_uop_lqIdx_value = replay_uop[2].p.lqIdx_value;
  assign io_replay_2_bits_uop_sqIdx_flag = replay_uop[2].p.sqIdx_flag;
  assign io_replay_2_bits_uop_sqIdx_value = replay_uop[2].p.sqIdx_value;
  assign io_replay_2_bits_uop_singleStep = replay_uop[2].p.singleStep;
  assign io_replay_2_bits_uop_debug_fuType = replay_uop[2].p.debug_fuType;
  assign io_replay_2_bits_uop_debug_sim_trig = replay_uop[2].p.debug_sim_trig;
  assign io_replay_2_bits_uop_numLsElem = replay_uop[2].p.numLsElem;
  assign io_replay_2_bits_vaddr = replay_vaddr[2];
  assign io_replay_2_bits_mask = replay_vec[2].mask;
  assign io_replay_2_bits_isvec = replay_vec[2].isvec;
  assign io_replay_2_bits_is128bit = replay_vec[2].is128bit;
  assign io_replay_2_bits_elemIdx = replay_vec[2].elemIdx;
  assign io_replay_2_bits_alignedType = replay_vec[2].alignedType;
  assign io_replay_2_bits_mbIndex = replay_vec[2].mbIndex;
  assign io_replay_2_bits_reg_offset = replay_vec[2].reg_offset;
  assign io_replay_2_bits_elemIdxInsideVd = replay_vec[2].elemIdxInsideVd;
  assign io_replay_2_bits_vecActive = replay_vec[2].vecActive;
  assign io_replay_2_bits_mshrid = replay_mshrid[2];
  assign io_replay_2_bits_forward_tlDchannel = replay_forward_tlDchannel[2];
  assign io_replay_2_bits_schedIndex = replay_schedIndex[2];
  assign io_lqFull = lqFull;
  assign io_debugTopDown_robHeadTlbReplay = dtd_robHeadTlbReplay;
  assign io_debugTopDown_robHeadTlbMiss = dtd_robHeadTlbMiss;
  assign io_debugTopDown_robHeadLoadVio = dtd_robHeadLoadVio;
  assign io_debugTopDown_robHeadLoadMSHR = dtd_robHeadLoadMSHR;
  assign io_replayAllocate = replayAllocate;
  assign io_perf_0_value = perf_value[0];
  assign io_perf_1_value = perf_value[1];
  assign io_perf_2_value = perf_value[2];
  assign io_perf_3_value = perf_value[3];
  assign io_perf_4_value = perf_value[4];
  assign io_perf_5_value = perf_value[5];
  assign io_perf_6_value = perf_value[6];
  assign io_perf_7_value = perf_value[7];
  assign io_perf_8_value = perf_value[8];
  assign io_perf_9_value = perf_value[9];
  assign io_perf_10_value = perf_value[10];
  assign io_perf_11_value = perf_value[11];
  assign io_perf_12_value = perf_value[12];
  // END GENERATED

endmodule
