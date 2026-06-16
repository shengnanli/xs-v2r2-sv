// 可读核 xs_LoadQueueReplay_core 的端口表（struct/数组聚合，由 wrapper 拆扁平 io_*）
// 由 LoadQueueReplay.sv include。
  input  logic clock,
  input  logic reset,

  // 控制：redirect（误预测/异常重定向，取消队列内被刷的 entry）
  input  logic     redirect_valid,
  input  rob_ptr_t redirect_robIdx,
  input  logic     redirect_level,

  // 向量反馈（VecLoadPipelineWidth=2 路）：merge buffer 提交/刷新，释放对应 entry
  input  logic     [VEC_PIPE_W-1:0]            vecFb_valid,
  input  rob_ptr_t [VEC_PIPE_W-1:0]            vecFb_robIdx,
  input  logic     [VEC_PIPE_W-1:0][UOP_IDX_W-1:0] vecFb_uopIdx,
  input  logic     [VEC_PIPE_W-1:0]            vecFb_isCommit,  // feedback_0
  input  logic     [VEC_PIPE_W-1:0]            vecFb_isFlush,   // feedback_1

  // 入队：来自 LoadUnit s3（LoadPipelineWidth=3 路）
  input  logic        [LD_PIPE_W-1:0]            enq_valid,
  input  lqr_uop_t    [LD_PIPE_W-1:0]            enq_uop,
  input  lqr_vec_t    [LD_PIPE_W-1:0]            enq_vec,
  input  logic        [LD_PIPE_W-1:0][VADDR_BITS-1:0] enq_vaddr,
  input  logic        [LD_PIPE_W-1:0]            enq_tlbMiss,
  input  logic        [LD_PIPE_W-1:0]            enq_isLoadReplay,
  input  logic        [LD_PIPE_W-1:0]            enq_handledByMSHR,
  input  logic        [LD_PIPE_W-1:0][SCHED_IDX_W-1:0] enq_schedIndex,
  // rep_info：本次重放原因与附带信息
  input  logic        [LD_PIPE_W-1:0][N_CAUSES-1:0] enq_cause,
  input  logic        [LD_PIPE_W-1:0][MSHR_ID_W-1:0] enq_mshr_id,
  input  logic        [LD_PIPE_W-1:0]            enq_full_fwd,
  input  sq_ptr_t     [LD_PIPE_W-1:0]            enq_data_inv_sq_idx,
  input  sq_ptr_t     [LD_PIPE_W-1:0]            enq_addr_inv_sq_idx,
  input  logic        [LD_PIPE_W-1:0]            enq_last_beat,
  input  logic        [LD_PIPE_W-1:0][TLB_ID_W-1:0] enq_tlb_id,
  input  logic        [LD_PIPE_W-1:0]            enq_tlb_full,

  // 来自 STA s1：store 地址执行（用于解除 C_MA blocking）
  input  logic     [ST_PIPE_W-1:0]            staIn_valid,
  input  sq_ptr_t  [ST_PIPE_W-1:0]            staIn_sqIdx,
  input  logic     [ST_PIPE_W-1:0]            staIn_miss,
  // 来自 STD s1：store 数据执行（用于解除 C_FF blocking）
  input  logic     [ST_PIPE_W-1:0]            stdIn_valid,
  input  sq_ptr_t  [ST_PIPE_W-1:0]            stdIn_sqIdx,

  // 来自 StoreQueue：地址/数据就绪指针 + 就绪向量
  input  sq_ptr_t                 stAddrReadySqPtr,
  input  logic [SQ_SIZE-1:0]      stAddrReadyVec,
  input  sq_ptr_t                 stDataReadySqPtr,
  input  logic [SQ_SIZE-1:0]      stDataReadyVec,

  // dcache D-channel forward（C_DM 唤醒）
  input  logic                 tl_d_valid,
  input  logic [MSHR_ID_W-1:0] tl_d_mshrid,

  // 各队列/资源状态
  input  logic     sqEmpty,
  input  lq_ptr_t  ldWbPtr,
  input  logic     rarFull,
  input  logic     rawFull,
  input  logic     loadMisalignFull,
  input  logic     misalignAllowSpec,

  // L2 hint：提前唤醒 dcache miss 的 load
  input  logic                 l2_hint_valid,
  input  logic [MSHR_ID_W-1:0] l2_hint_sourceId,
  input  logic                 l2_hint_isKeyword,

  // tlb hint：tlb miss 回填唤醒
  input  logic                 tlb_hint_valid,
  input  logic [TLB_ID_W-1:0]  tlb_hint_id,
  input  logic                 tlb_hint_replay_all,

  // debug topdown
  input  logic                  dtd_robHeadVaddr_valid,
  input  logic [VADDR_BITS-1:0] dtd_robHeadVaddr_bits,
  input  logic                  dtd_robHeadMissInDTlb,
  output logic                  dtd_robHeadTlbReplay,
  output logic                  dtd_robHeadTlbMiss,
  output logic                  dtd_robHeadLoadVio,
  output logic                  dtd_robHeadLoadMSHR,

  // 重放发射（LoadPipelineWidth=3 路 Decoupled）→ 回 LoadUnit
  output logic        [LD_PIPE_W-1:0]            replay_valid,
  input  logic        [LD_PIPE_W-1:0]            replay_ready,
  output lqr_uop_t    [LD_PIPE_W-1:0]            replay_uop,
  output logic        [LD_PIPE_W-1:0][VADDR_BITS-1:0] replay_vaddr,
  output lqr_vec_t    [LD_PIPE_W-1:0]            replay_vec,
  output logic        [LD_PIPE_W-1:0][MSHR_ID_W-1:0] replay_mshrid,
  output logic        [LD_PIPE_W-1:0]            replay_forward_tlDchannel,
  output logic        [LD_PIPE_W-1:0][SCHED_IDX_W-1:0] replay_schedIndex,

  // 队列满
  output logic     lqFull,

  // perf（13 项，每项 6 位计数）
  output logic [5:0] perf_value [13]
