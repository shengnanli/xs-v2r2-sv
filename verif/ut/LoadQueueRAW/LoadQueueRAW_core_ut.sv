// =============================================================================
//  xs_LoadQueueRAW_core —— store→load 违例 (nuke) 检测队列（可读重写）
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel，非 firtool golden）：
//      src/main/scala/xiangshan/mem/lsqueue/LoadQueueRAW.scala
//      src/main/scala/xiangshan/mem/lsqueue/LoadQueueData.scala (CAM 数据模块)
//      src/main/scala/xiangshan/mem/lsqueue/FreeList.scala       (空闲槽 freelist)
//
//  ── 功能概览 ──
//   维护「已发射、未提交、且其前方仍有地址未就绪 store」的 load 记录表。store 拿到
//   地址写回时，对全表做 paddr+mask CAM 匹配，命中且 load 更年轻 → store→load 违例，
//   选最老的违例 load 产生 rollback。详见 loadqueueraw_pkg.sv 文件头。
//
//  ── 层次化组合（镜像 golden，供 FM 分层配对）──
//    · freeList     : FreeList_4       实例 —— 空闲条目环形 freelist（分配/回收/preAlloc）
//    · paddrModule  : LqPAddrModule_1  实例 —— 每条目 24 位 partial paddr CAM（1 拍延迟写）
//    · maskModule   : LqMaskModule     实例 —— 每条目 16 位字节 mask  CAM（1 拍延迟写）
//   顶层核只保留控制/年龄比较/最老选择流水/rollback/perf 等 glue（与 golden 顶层对应）。
//
//  ── 本核分节 ──
//    A. 端口聚合（扁平 golden 端口 ↔ 数组）
//    B. 入队判定 needEnqueue
//    C. freelist 实例（FreeList_4）+ 分配索引/ready
//    D. enqueue 写 entry / 写 CAM
//    E. dequeue / revoke（计算 free 掩码喂 freelist）
//    F. 违例检测流水（CAM 输出 × entryNeedCheck → 两段最老选择）
//    G. store fire / ftq 的 3 拍延迟
//    H. rollback 输出 / lqFull / perf
// =============================================================================
module xs_LoadQueueRAW_core_ut
  import loadqueueraw_pkg::*;
(
  input  logic clock,
  input  logic reset,

  // ---- 控制：全局 redirect（冲刷）----
  input  logic              io_redirect_valid,
  input  logic              io_redirect_bits_robIdx_flag,
  input  logic [ROB_W-1:0]  io_redirect_bits_robIdx_value,
  input  logic              io_redirect_bits_level,

  // ---- 违例查询 / 入队（LoadPipelineWidth=3）----
  output logic              io_query_0_req_ready,
  input  logic              io_query_0_req_valid,
  input  logic              io_query_0_req_bits_uop_preDecodeInfo_isRVC,
  input  logic              io_query_0_req_bits_uop_ftqPtr_flag,
  input  logic [FTQ_W-1:0]  io_query_0_req_bits_uop_ftqPtr_value,
  input  logic [FTQOFF_W-1:0] io_query_0_req_bits_uop_ftqOffset,
  input  logic              io_query_0_req_bits_uop_robIdx_flag,
  input  logic [ROB_W-1:0]  io_query_0_req_bits_uop_robIdx_value,
  input  logic              io_query_0_req_bits_uop_sqIdx_flag,
  input  logic [SQ_W-1:0]   io_query_0_req_bits_uop_sqIdx_value,
  input  logic [MASK_BITS-1:0] io_query_0_req_bits_mask,
  input  logic [PADDR_BITS-1:0] io_query_0_req_bits_paddr,
  input  logic              io_query_0_req_bits_data_valid,
  input  logic              io_query_0_revoke,

  output logic              io_query_1_req_ready,
  input  logic              io_query_1_req_valid,
  input  logic              io_query_1_req_bits_uop_preDecodeInfo_isRVC,
  input  logic              io_query_1_req_bits_uop_ftqPtr_flag,
  input  logic [FTQ_W-1:0]  io_query_1_req_bits_uop_ftqPtr_value,
  input  logic [FTQOFF_W-1:0] io_query_1_req_bits_uop_ftqOffset,
  input  logic              io_query_1_req_bits_uop_robIdx_flag,
  input  logic [ROB_W-1:0]  io_query_1_req_bits_uop_robIdx_value,
  input  logic              io_query_1_req_bits_uop_sqIdx_flag,
  input  logic [SQ_W-1:0]   io_query_1_req_bits_uop_sqIdx_value,
  input  logic [MASK_BITS-1:0] io_query_1_req_bits_mask,
  input  logic [PADDR_BITS-1:0] io_query_1_req_bits_paddr,
  input  logic              io_query_1_req_bits_data_valid,
  input  logic              io_query_1_revoke,

  output logic              io_query_2_req_ready,
  input  logic              io_query_2_req_valid,
  input  logic              io_query_2_req_bits_uop_preDecodeInfo_isRVC,
  input  logic              io_query_2_req_bits_uop_ftqPtr_flag,
  input  logic [FTQ_W-1:0]  io_query_2_req_bits_uop_ftqPtr_value,
  input  logic [FTQOFF_W-1:0] io_query_2_req_bits_uop_ftqOffset,
  input  logic              io_query_2_req_bits_uop_robIdx_flag,
  input  logic [ROB_W-1:0]  io_query_2_req_bits_uop_robIdx_value,
  input  logic              io_query_2_req_bits_uop_sqIdx_flag,
  input  logic [SQ_W-1:0]   io_query_2_req_bits_uop_sqIdx_value,
  input  logic [MASK_BITS-1:0] io_query_2_req_bits_mask,
  input  logic [PADDR_BITS-1:0] io_query_2_req_bits_paddr,
  input  logic              io_query_2_req_bits_data_valid,
  input  logic              io_query_2_revoke,

  // ---- store 写回（StorePipelineWidth=2）----
  input  logic              io_storeIn_0_valid,
  input  logic [FTQ_W-1:0]  io_storeIn_0_bits_uop_ftqPtr_value,
  input  logic [FTQOFF_W-1:0] io_storeIn_0_bits_uop_ftqOffset,
  input  logic              io_storeIn_0_bits_uop_robIdx_flag,
  input  logic [ROB_W-1:0]  io_storeIn_0_bits_uop_robIdx_value,
  input  logic [PADDR_BITS-1:0] io_storeIn_0_bits_paddr,
  input  logic [MASK_BITS-1:0] io_storeIn_0_bits_mask,
  input  logic              io_storeIn_0_bits_wlineflag,
  input  logic              io_storeIn_0_bits_miss,

  input  logic              io_storeIn_1_valid,
  input  logic [FTQ_W-1:0]  io_storeIn_1_bits_uop_ftqPtr_value,
  input  logic [FTQOFF_W-1:0] io_storeIn_1_bits_uop_ftqOffset,
  input  logic              io_storeIn_1_bits_uop_robIdx_flag,
  input  logic [ROB_W-1:0]  io_storeIn_1_bits_uop_robIdx_value,
  input  logic [PADDR_BITS-1:0] io_storeIn_1_bits_paddr,
  input  logic [MASK_BITS-1:0] io_storeIn_1_bits_mask,
  input  logic              io_storeIn_1_bits_wlineflag,
  input  logic              io_storeIn_1_bits_miss,

  // ---- rollback 输出 ----
  output logic              io_rollback_0_valid,
  output logic              io_rollback_0_bits_isRVC,
  output logic              io_rollback_0_bits_robIdx_flag,
  output logic [ROB_W-1:0]  io_rollback_0_bits_robIdx_value,
  output logic              io_rollback_0_bits_ftqIdx_flag,
  output logic [FTQ_W-1:0]  io_rollback_0_bits_ftqIdx_value,
  output logic [FTQOFF_W-1:0] io_rollback_0_bits_ftqOffset,
  output logic [FTQ_W-1:0]  io_rollback_0_bits_stFtqIdx_value,
  output logic [FTQOFF_W-1:0] io_rollback_0_bits_stFtqOffset,

  output logic              io_rollback_1_valid,
  output logic              io_rollback_1_bits_isRVC,
  output logic              io_rollback_1_bits_robIdx_flag,
  output logic [ROB_W-1:0]  io_rollback_1_bits_robIdx_value,
  output logic              io_rollback_1_bits_ftqIdx_flag,
  output logic [FTQ_W-1:0]  io_rollback_1_bits_ftqIdx_value,
  output logic [FTQOFF_W-1:0] io_rollback_1_bits_ftqOffset,
  output logic [FTQ_W-1:0]  io_rollback_1_bits_stFtqIdx_value,
  output logic [FTQOFF_W-1:0] io_rollback_1_bits_stFtqOffset,

  // ---- store 地址就绪指针 ----
  input  logic              io_stAddrReadySqPtr_flag,
  input  logic [SQ_W-1:0]   io_stAddrReadySqPtr_value,
  input  logic              io_stIssuePtr_flag,
  input  logic [SQ_W-1:0]   io_stIssuePtr_value,

  output logic              io_lqFull,

  // ---- perf（入队数 / rollback 数，经 2 拍寄存器）----
  output logic [5:0]        io_perf_0_value,
  output logic [5:0]        io_perf_1_value
);

  // ===========================================================================
  //  A. 端口聚合
  // ===========================================================================
  logic                  q_req_valid   [LD_W];
  logic                  q_req_isRVC   [LD_W];
  logic                  q_ftqPtr_flag [LD_W];
  logic [FTQ_W-1:0]      q_ftqPtr_val  [LD_W];
  logic [FTQOFF_W-1:0]   q_ftqOffset   [LD_W];
  logic                  q_robIdx_flag [LD_W];
  logic [ROB_W-1:0]      q_robIdx_val  [LD_W];
  logic                  q_sqIdx_flag  [LD_W];
  logic [SQ_W-1:0]       q_sqIdx_val   [LD_W];
  logic [MASK_BITS-1:0]  q_mask        [LD_W];
  logic [PADDR_BITS-1:0] q_paddr       [LD_W];
  logic                  q_data_valid  [LD_W];
  logic                  q_revoke      [LD_W];
  logic                  q_req_ready   [LD_W];

  always_comb begin
    q_req_valid[0]=io_query_0_req_valid; q_req_isRVC[0]=io_query_0_req_bits_uop_preDecodeInfo_isRVC;
    q_ftqPtr_flag[0]=io_query_0_req_bits_uop_ftqPtr_flag; q_ftqPtr_val[0]=io_query_0_req_bits_uop_ftqPtr_value;
    q_ftqOffset[0]=io_query_0_req_bits_uop_ftqOffset; q_robIdx_flag[0]=io_query_0_req_bits_uop_robIdx_flag;
    q_robIdx_val[0]=io_query_0_req_bits_uop_robIdx_value; q_sqIdx_flag[0]=io_query_0_req_bits_uop_sqIdx_flag;
    q_sqIdx_val[0]=io_query_0_req_bits_uop_sqIdx_value; q_mask[0]=io_query_0_req_bits_mask;
    q_paddr[0]=io_query_0_req_bits_paddr; q_data_valid[0]=io_query_0_req_bits_data_valid; q_revoke[0]=io_query_0_revoke;

    q_req_valid[1]=io_query_1_req_valid; q_req_isRVC[1]=io_query_1_req_bits_uop_preDecodeInfo_isRVC;
    q_ftqPtr_flag[1]=io_query_1_req_bits_uop_ftqPtr_flag; q_ftqPtr_val[1]=io_query_1_req_bits_uop_ftqPtr_value;
    q_ftqOffset[1]=io_query_1_req_bits_uop_ftqOffset; q_robIdx_flag[1]=io_query_1_req_bits_uop_robIdx_flag;
    q_robIdx_val[1]=io_query_1_req_bits_uop_robIdx_value; q_sqIdx_flag[1]=io_query_1_req_bits_uop_sqIdx_flag;
    q_sqIdx_val[1]=io_query_1_req_bits_uop_sqIdx_value; q_mask[1]=io_query_1_req_bits_mask;
    q_paddr[1]=io_query_1_req_bits_paddr; q_data_valid[1]=io_query_1_req_bits_data_valid; q_revoke[1]=io_query_1_revoke;

    q_req_valid[2]=io_query_2_req_valid; q_req_isRVC[2]=io_query_2_req_bits_uop_preDecodeInfo_isRVC;
    q_ftqPtr_flag[2]=io_query_2_req_bits_uop_ftqPtr_flag; q_ftqPtr_val[2]=io_query_2_req_bits_uop_ftqPtr_value;
    q_ftqOffset[2]=io_query_2_req_bits_uop_ftqOffset; q_robIdx_flag[2]=io_query_2_req_bits_uop_robIdx_flag;
    q_robIdx_val[2]=io_query_2_req_bits_uop_robIdx_value; q_sqIdx_flag[2]=io_query_2_req_bits_uop_sqIdx_flag;
    q_sqIdx_val[2]=io_query_2_req_bits_uop_sqIdx_value; q_mask[2]=io_query_2_req_bits_mask;
    q_paddr[2]=io_query_2_req_bits_paddr; q_data_valid[2]=io_query_2_req_bits_data_valid; q_revoke[2]=io_query_2_revoke;
  end
  assign io_query_0_req_ready = q_req_ready[0];
  assign io_query_1_req_ready = q_req_ready[1];
  assign io_query_2_req_ready = q_req_ready[2];

  logic                  st_valid      [ST_W];
  logic [FTQ_W-1:0]      st_ftqPtr_val [ST_W];
  logic [FTQOFF_W-1:0]   st_ftqOffset  [ST_W];
  logic                  st_robIdx_flag[ST_W];
  logic [ROB_W-1:0]      st_robIdx_val [ST_W];
  logic [PADDR_BITS-1:0] st_paddr      [ST_W];
  logic [MASK_BITS-1:0]  st_mask       [ST_W];
  logic                  st_wlineflag  [ST_W];
  logic                  st_miss       [ST_W];
  always_comb begin
    st_valid[0]=io_storeIn_0_valid; st_ftqPtr_val[0]=io_storeIn_0_bits_uop_ftqPtr_value;
    st_ftqOffset[0]=io_storeIn_0_bits_uop_ftqOffset; st_robIdx_flag[0]=io_storeIn_0_bits_uop_robIdx_flag;
    st_robIdx_val[0]=io_storeIn_0_bits_uop_robIdx_value; st_paddr[0]=io_storeIn_0_bits_paddr;
    st_mask[0]=io_storeIn_0_bits_mask; st_wlineflag[0]=io_storeIn_0_bits_wlineflag; st_miss[0]=io_storeIn_0_bits_miss;
    st_valid[1]=io_storeIn_1_valid; st_ftqPtr_val[1]=io_storeIn_1_bits_uop_ftqPtr_value;
    st_ftqOffset[1]=io_storeIn_1_bits_uop_ftqOffset; st_robIdx_flag[1]=io_storeIn_1_bits_uop_robIdx_flag;
    st_robIdx_val[1]=io_storeIn_1_bits_uop_robIdx_value; st_paddr[1]=io_storeIn_1_bits_paddr;
    st_mask[1]=io_storeIn_1_bits_mask; st_wlineflag[1]=io_storeIn_1_bits_wlineflag; st_miss[1]=io_storeIn_1_bits_miss;
  end

  // ===========================================================================
  //  队列状态寄存器（entry payload；CAM 数据已移入 paddrModule / maskModule 实例）
  // ===========================================================================
  // 条目 payload：拆成逐字段数组（对应 golden 逐字段扁平寄存器 uop_N_<field>，
  //   便于 FM 逐字段配对；等价于 loadqueueraw_pkg::ld_uop_t 各域）。
  logic                 allocated       [RAW_SIZE];
  logic                 datavalid       [RAW_SIZE];
  logic                 entry_isRVC     [RAW_SIZE]; // uop_N_preDecodeInfo_isRVC
  logic                 entry_ftqFlag   [RAW_SIZE]; // uop_N_ftqPtr_flag
  logic [FTQ_W-1:0]     entry_ftqPtr    [RAW_SIZE]; // uop_N_ftqPtr_value
  logic [FTQOFF_W-1:0]  entry_ftqOffset [RAW_SIZE]; // uop_N_ftqOffset
  logic                 entry_robFlag   [RAW_SIZE]; // uop_N_robIdx_flag
  logic [ROB_W-1:0]     entry_robIdx    [RAW_SIZE]; // uop_N_robIdx_value
  logic                 entry_sqFlag    [RAW_SIZE]; // uop_N_sqIdx_flag
  logic [SQ_W-1:0]      entry_sqIdx     [RAW_SIZE]; // uop_N_sqIdx_value

  // ===========================================================================
  //  B. 入队判定 needEnqueue
  // ===========================================================================
  logic all_addr_check;
  assign all_addr_check = (io_stIssuePtr_flag  == io_stAddrReadySqPtr_flag) &&
                          (io_stIssuePtr_value == io_stAddrReadySqPtr_value);

  logic has_addr_inv_store [LD_W];
  logic cancel_enqueue     [LD_W];
  logic need_enqueue       [LD_W];
  always_comb begin
    for (int w = 0; w < LD_W; w++) begin
      has_addr_inv_store[w] = !all_addr_check &&
          sq_is_before(io_stAddrReadySqPtr_flag, io_stAddrReadySqPtr_value,
                       q_sqIdx_flag[w], q_sqIdx_val[w]);
      cancel_enqueue[w] = rob_need_flush(io_redirect_valid, io_redirect_bits_level,
                       q_robIdx_flag[w], q_robIdx_val[w],
                       io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value);
      need_enqueue[w] = q_req_valid[w] && has_addr_inv_store[w] && !cancel_enqueue[w];
    end
  end

  // ===========================================================================
  //  C. freelist 实例（FreeList_4）+ 分配索引 / ready
  //     enqueue index off = PopCount(needEnqueue.take(w))；范围 0..2。
  // ===========================================================================
  logic [1:0]       enq_off      [LD_W];
  always_comb
    for (int w = 0; w < LD_W; w++) begin
      logic [1:0] off;
      off = 2'd0;
      for (int k = 0; k < LD_W; k++) if (k < w && need_enqueue[k]) off = off + 2'd1;
      enq_off[w] = off;
    end

  // FreeList_4 的 preAlloc 输出（分配槽 / 是否可分配）
  logic [IDX_W-1:0] fl_allocateSlot [LD_W];  // io_allocateSlot_0..2
  logic             fl_canAllocate  [LD_W];  // io_canAllocate_0..2
  logic             fl_empty;

  // enq_off 选取表：off∈0..2，声明 4 深让 2 位索引静态在界（第 4 项回落 lane0，
  //   镜像 golden `_GEN_34/_GEN_35 = {slot0, slot2, slot1, slot0}`，恒不越界）。
  logic [IDX_W-1:0] fl_slot_sel [4];
  logic             fl_can_sel  [4];
  always_comb begin
    fl_slot_sel[0] = fl_allocateSlot[0]; fl_slot_sel[1] = fl_allocateSlot[1];
    fl_slot_sel[2] = fl_allocateSlot[2]; fl_slot_sel[3] = fl_allocateSlot[0];
    fl_can_sel[0]  = fl_canAllocate[0];  fl_can_sel[1]  = fl_canAllocate[1];
    fl_can_sel[2]  = fl_canAllocate[2];  fl_can_sel[3]  = fl_canAllocate[0];
  end

  logic             accepted   [LD_W];
  logic [IDX_W-1:0] enq_index  [LD_W];
  always_comb begin
    for (int w = 0; w < LD_W; w++) begin
      enq_index[w]   = fl_slot_sel[enq_off[w]];
      q_req_ready[w] = need_enqueue[w] ? fl_can_sel[enq_off[w]] : 1'b1;
      accepted[w]    = need_enqueue[w] && q_req_ready[w];
    end
  end

  // 释放掩码（喂 freelist io_free；见 E 节）
  logic [RAW_SIZE-1:0] free_bits;

  FreeList_4_xs freeList (
    .clock             (clock),
    .reset             (reset),
    .io_allocateSlot_0 (fl_allocateSlot[0]),
    .io_allocateSlot_1 (fl_allocateSlot[1]),
    .io_allocateSlot_2 (fl_allocateSlot[2]),
    .io_canAllocate_0  (fl_canAllocate[0]),
    .io_canAllocate_1  (fl_canAllocate[1]),
    .io_canAllocate_2  (fl_canAllocate[2]),
    .io_doAllocate_0   (accepted[0]),
    .io_doAllocate_1   (accepted[1]),
    .io_doAllocate_2   (accepted[2]),
    .io_free           (free_bits),
    .io_validCount     (/* unused */),
    .io_empty          (fl_empty)
  );

  // ===========================================================================
  //  D. enqueue（写 entry payload + 写 CAM）
  // ===========================================================================
  // paddr / mask CAM 写口（与 golden 一致：wen=acceptedVec，waddr=allocateSlot[off]，
  //   wdata=paddr[27:4] / mask，均组合，CAM 内部 1 拍延迟落地）。
  logic             cam_wen   [LD_W];
  logic [IDX_W-1:0] cam_waddr [LD_W];
  logic [PPA_W-1:0] cam_pdata [LD_W];
  logic [MASK_BITS-1:0] cam_mdata [LD_W];
  always_comb
    for (int w = 0; w < LD_W; w++) begin
      cam_wen[w]   = accepted[w];
      cam_waddr[w] = enq_index[w];
      cam_pdata[w] = gen_partial_paddr(q_paddr[w]);
      cam_mdata[w] = q_mask[w];
    end

  // ===========================================================================
  //  E. dequeue / revoke 释放（计算 free_bits 喂 freelist）
  // ===========================================================================
  logic free_mask [RAW_SIZE];
  logic             last_can_accept [LD_W];
  logic [IDX_W-1:0] last_alloc_index[LD_W];
  always_comb begin
    for (int i = 0; i < RAW_SIZE; i++) begin
      logic deq_not_block, need_cancel;
      deq_not_block = all_addr_check ? 1'b1 :
          !sq_is_before(io_stAddrReadySqPtr_flag, io_stAddrReadySqPtr_value,
                        entry_sqFlag[i], entry_sqIdx[i]);
      need_cancel = rob_need_flush(io_redirect_valid, io_redirect_bits_level,
                        entry_robFlag[i], entry_robIdx[i],
                        io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value);
      free_mask[i] = allocated[i] && (deq_not_block || need_cancel);
    end
    for (int w = 0; w < LD_W; w++) begin
      logic revoke_valid;
      revoke_valid = q_revoke[w] && last_can_accept[w];
      if (allocated[last_alloc_index[w]] && revoke_valid)
        free_mask[last_alloc_index[w]] = 1'b1;
    end
  end
  always_comb for (int i = 0; i < RAW_SIZE; i++) free_bits[i] = free_mask[i];

  // ===========================================================================
  //  F. 违例检测流水
  // ===========================================================================
  // s0: store paddr/mask 锁存。
  //   ★paddr 只存**被 CAM 读的 partial 切片 [27:4]**(PADDR_OFFSET +: PPA_W)。golden
  //   violationMdata_0/1_r 存满 48 位但只读 [27:4] → 高 20 位[47:28]+低 4 位[3:0] 恒不读
  //   =golden-only cone-dead 冗余。本核只存读到的 24 位(bit 下标 27..4 与 golden 同位, 便于
  //   FM 逐位配对)→ impl clean(0 死位); golden 多余位判 ref-unread → PASS_DEAD_REF。
  //   (与 LoadQueueRAR 的 release2Cycle_paddr[47:6] 收窄同法。)
  localparam int PPA_HI = PADDR_OFFSET + PPA_W - 1;   // = 27
  logic [PPA_HI:PADDR_OFFSET] st_paddr_r [ST_W];       // [27:4] 只存被读切片
  logic [MASK_BITS-1:0]       st_mask_r  [ST_W];

  // CAM 匹配输出（组合读，来自 paddrModule / maskModule 实例）
  logic [RAW_SIZE-1:0] paddr_mmask [ST_W];
  logic [RAW_SIZE-1:0] mask_mmask  [ST_W];

  LqPAddrModule_1_xs paddrModule (
    .clock                   (clock),
    .reset                   (reset),
    .io_wen_0                (cam_wen[0]),
    .io_wen_1                (cam_wen[1]),
    .io_wen_2                (cam_wen[2]),
    .io_waddr_0              (cam_waddr[0]),
    .io_waddr_1              (cam_waddr[1]),
    .io_waddr_2              (cam_waddr[2]),
    .io_wdata_0              (cam_pdata[0]),
    .io_wdata_1              (cam_pdata[1]),
    .io_wdata_2              (cam_pdata[2]),
    .io_violationMdata_0     (st_paddr_r[0]),
    .io_violationMdata_1     (st_paddr_r[1]),
    .io_violationCheckLine_0 (io_storeIn_0_bits_wlineflag),
    .io_violationCheckLine_1 (io_storeIn_1_bits_wlineflag),
    .io_violationMmask_0_0(paddr_mmask[0][0]),   .io_violationMmask_0_1(paddr_mmask[0][1]),
    .io_violationMmask_0_2(paddr_mmask[0][2]),   .io_violationMmask_0_3(paddr_mmask[0][3]),
    .io_violationMmask_0_4(paddr_mmask[0][4]),   .io_violationMmask_0_5(paddr_mmask[0][5]),
    .io_violationMmask_0_6(paddr_mmask[0][6]),   .io_violationMmask_0_7(paddr_mmask[0][7]),
    .io_violationMmask_0_8(paddr_mmask[0][8]),   .io_violationMmask_0_9(paddr_mmask[0][9]),
    .io_violationMmask_0_10(paddr_mmask[0][10]), .io_violationMmask_0_11(paddr_mmask[0][11]),
    .io_violationMmask_0_12(paddr_mmask[0][12]), .io_violationMmask_0_13(paddr_mmask[0][13]),
    .io_violationMmask_0_14(paddr_mmask[0][14]), .io_violationMmask_0_15(paddr_mmask[0][15]),
    .io_violationMmask_0_16(paddr_mmask[0][16]), .io_violationMmask_0_17(paddr_mmask[0][17]),
    .io_violationMmask_0_18(paddr_mmask[0][18]), .io_violationMmask_0_19(paddr_mmask[0][19]),
    .io_violationMmask_0_20(paddr_mmask[0][20]), .io_violationMmask_0_21(paddr_mmask[0][21]),
    .io_violationMmask_0_22(paddr_mmask[0][22]), .io_violationMmask_0_23(paddr_mmask[0][23]),
    .io_violationMmask_0_24(paddr_mmask[0][24]), .io_violationMmask_0_25(paddr_mmask[0][25]),
    .io_violationMmask_0_26(paddr_mmask[0][26]), .io_violationMmask_0_27(paddr_mmask[0][27]),
    .io_violationMmask_0_28(paddr_mmask[0][28]), .io_violationMmask_0_29(paddr_mmask[0][29]),
    .io_violationMmask_0_30(paddr_mmask[0][30]), .io_violationMmask_0_31(paddr_mmask[0][31]),
    .io_violationMmask_1_0(paddr_mmask[1][0]),   .io_violationMmask_1_1(paddr_mmask[1][1]),
    .io_violationMmask_1_2(paddr_mmask[1][2]),   .io_violationMmask_1_3(paddr_mmask[1][3]),
    .io_violationMmask_1_4(paddr_mmask[1][4]),   .io_violationMmask_1_5(paddr_mmask[1][5]),
    .io_violationMmask_1_6(paddr_mmask[1][6]),   .io_violationMmask_1_7(paddr_mmask[1][7]),
    .io_violationMmask_1_8(paddr_mmask[1][8]),   .io_violationMmask_1_9(paddr_mmask[1][9]),
    .io_violationMmask_1_10(paddr_mmask[1][10]), .io_violationMmask_1_11(paddr_mmask[1][11]),
    .io_violationMmask_1_12(paddr_mmask[1][12]), .io_violationMmask_1_13(paddr_mmask[1][13]),
    .io_violationMmask_1_14(paddr_mmask[1][14]), .io_violationMmask_1_15(paddr_mmask[1][15]),
    .io_violationMmask_1_16(paddr_mmask[1][16]), .io_violationMmask_1_17(paddr_mmask[1][17]),
    .io_violationMmask_1_18(paddr_mmask[1][18]), .io_violationMmask_1_19(paddr_mmask[1][19]),
    .io_violationMmask_1_20(paddr_mmask[1][20]), .io_violationMmask_1_21(paddr_mmask[1][21]),
    .io_violationMmask_1_22(paddr_mmask[1][22]), .io_violationMmask_1_23(paddr_mmask[1][23]),
    .io_violationMmask_1_24(paddr_mmask[1][24]), .io_violationMmask_1_25(paddr_mmask[1][25]),
    .io_violationMmask_1_26(paddr_mmask[1][26]), .io_violationMmask_1_27(paddr_mmask[1][27]),
    .io_violationMmask_1_28(paddr_mmask[1][28]), .io_violationMmask_1_29(paddr_mmask[1][29]),
    .io_violationMmask_1_30(paddr_mmask[1][30]), .io_violationMmask_1_31(paddr_mmask[1][31])
  );

  LqMaskModule_xs maskModule (
    .clock                   (clock),
    .reset                   (reset),
    .io_wen_0                (cam_wen[0]),
    .io_wen_1                (cam_wen[1]),
    .io_wen_2                (cam_wen[2]),
    .io_waddr_0              (cam_waddr[0]),
    .io_waddr_1              (cam_waddr[1]),
    .io_waddr_2              (cam_waddr[2]),
    .io_wdata_0              (cam_mdata[0]),
    .io_wdata_1              (cam_mdata[1]),
    .io_wdata_2              (cam_mdata[2]),
    .io_violationMdata_0     (st_mask_r[0]),
    .io_violationMdata_1     (st_mask_r[1]),
    .io_violationMmask_0_0(mask_mmask[0][0]),   .io_violationMmask_0_1(mask_mmask[0][1]),
    .io_violationMmask_0_2(mask_mmask[0][2]),   .io_violationMmask_0_3(mask_mmask[0][3]),
    .io_violationMmask_0_4(mask_mmask[0][4]),   .io_violationMmask_0_5(mask_mmask[0][5]),
    .io_violationMmask_0_6(mask_mmask[0][6]),   .io_violationMmask_0_7(mask_mmask[0][7]),
    .io_violationMmask_0_8(mask_mmask[0][8]),   .io_violationMmask_0_9(mask_mmask[0][9]),
    .io_violationMmask_0_10(mask_mmask[0][10]), .io_violationMmask_0_11(mask_mmask[0][11]),
    .io_violationMmask_0_12(mask_mmask[0][12]), .io_violationMmask_0_13(mask_mmask[0][13]),
    .io_violationMmask_0_14(mask_mmask[0][14]), .io_violationMmask_0_15(mask_mmask[0][15]),
    .io_violationMmask_0_16(mask_mmask[0][16]), .io_violationMmask_0_17(mask_mmask[0][17]),
    .io_violationMmask_0_18(mask_mmask[0][18]), .io_violationMmask_0_19(mask_mmask[0][19]),
    .io_violationMmask_0_20(mask_mmask[0][20]), .io_violationMmask_0_21(mask_mmask[0][21]),
    .io_violationMmask_0_22(mask_mmask[0][22]), .io_violationMmask_0_23(mask_mmask[0][23]),
    .io_violationMmask_0_24(mask_mmask[0][24]), .io_violationMmask_0_25(mask_mmask[0][25]),
    .io_violationMmask_0_26(mask_mmask[0][26]), .io_violationMmask_0_27(mask_mmask[0][27]),
    .io_violationMmask_0_28(mask_mmask[0][28]), .io_violationMmask_0_29(mask_mmask[0][29]),
    .io_violationMmask_0_30(mask_mmask[0][30]), .io_violationMmask_0_31(mask_mmask[0][31]),
    .io_violationMmask_1_0(mask_mmask[1][0]),   .io_violationMmask_1_1(mask_mmask[1][1]),
    .io_violationMmask_1_2(mask_mmask[1][2]),   .io_violationMmask_1_3(mask_mmask[1][3]),
    .io_violationMmask_1_4(mask_mmask[1][4]),   .io_violationMmask_1_5(mask_mmask[1][5]),
    .io_violationMmask_1_6(mask_mmask[1][6]),   .io_violationMmask_1_7(mask_mmask[1][7]),
    .io_violationMmask_1_8(mask_mmask[1][8]),   .io_violationMmask_1_9(mask_mmask[1][9]),
    .io_violationMmask_1_10(mask_mmask[1][10]), .io_violationMmask_1_11(mask_mmask[1][11]),
    .io_violationMmask_1_12(mask_mmask[1][12]), .io_violationMmask_1_13(mask_mmask[1][13]),
    .io_violationMmask_1_14(mask_mmask[1][14]), .io_violationMmask_1_15(mask_mmask[1][15]),
    .io_violationMmask_1_16(mask_mmask[1][16]), .io_violationMmask_1_17(mask_mmask[1][17]),
    .io_violationMmask_1_18(mask_mmask[1][18]), .io_violationMmask_1_19(mask_mmask[1][19]),
    .io_violationMmask_1_20(mask_mmask[1][20]), .io_violationMmask_1_21(mask_mmask[1][21]),
    .io_violationMmask_1_22(mask_mmask[1][22]), .io_violationMmask_1_23(mask_mmask[1][23]),
    .io_violationMmask_1_24(mask_mmask[1][24]), .io_violationMmask_1_25(mask_mmask[1][25]),
    .io_violationMmask_1_26(mask_mmask[1][26]), .io_violationMmask_1_27(mask_mmask[1][27]),
    .io_violationMmask_1_28(mask_mmask[1][28]), .io_violationMmask_1_29(mask_mmask[1][29]),
    .io_violationMmask_1_30(mask_mmask[1][30]), .io_violationMmask_1_31(mask_mmask[1][31])
  );

  // s1: entryNeedCheck 打一拍（allocated & storeValid & load younger & datavalid & !flush）
  logic entry_need_check      [ST_W][RAW_SIZE];  // 寄存器（reset 块寄存）
  // next-state 组合信号（把 younger/nf 逻辑放这里, 别放 always_ff 里当 blocking 临时量）
  logic entry_need_check_next [ST_W][RAW_SIZE];
  always_comb
    for (int i = 0; i < ST_W; i++)
      for (int j = 0; j < RAW_SIZE; j++) begin
        logic younger, nf;
        younger = rob_is_after(entry_robFlag[j], entry_robIdx[j],
                     st_robIdx_flag[i], st_robIdx_val[i]);
        nf = rob_need_flush(io_redirect_valid, io_redirect_bits_level,
                     entry_robFlag[j], entry_robIdx[j],
                     io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value);
        entry_need_check_next[i][j] =
            allocated[j] && st_valid[i] && younger && datavalid[j] && !nf;
      end

  // 违例向量 = CAM 命中 & entryNeedCheck（组合）
  logic lq_violation_sel [ST_W][RAW_SIZE];
  always_comb
    for (int i = 0; i < ST_W; i++)
      for (int j = 0; j < RAW_SIZE; j++)
        lq_violation_sel[i][j] = paddr_mmask[i][j] && mask_mmask[i][j] && entry_need_check[i][j];

  // redirect 打一拍：golden 在流水各级各自寄存一份 RegNext(redirect)（值恒等，同 io_redirect）。
  //   为与 golden 层次逐点双射（clean SUCCEEDED），本核也逐级复制：
  //     s1_redir_*[p][g]  ↔ golden detectedRollback_lqSelect_select_REG_{4p+g}_*（s2 组合 flush_prev）
  //     s2_redir_*[p]     ↔ golden detectedRollback_lqSelect_REG(_1)_*         （最终输出 flush）
  logic             s1_redir_valid [ST_W][N_GROUP];
  logic             s1_redir_level [ST_W][N_GROUP];
  logic             s1_redir_robf  [ST_W][N_GROUP];
  logic [ROB_W-1:0] s1_redir_robv  [ST_W][N_GROUP];
  logic             s2_redir_valid [ST_W];
  logic             s2_redir_level [ST_W];
  logic             s2_redir_robf  [ST_W];
  logic [ROB_W-1:0] s2_redir_robv  [ST_W];

  // ---- 最老选择：**平衡二叉归约树**（严格镜像 golden，非顺序 fold）----
  //  golden 组内 8 条按 (0,1)(2,3)→[0..3] 与 (4,5)(6,7)→[4..7] 再合并的**平衡树**归约,
  //  每层 pick 更老者(robIdx 更小/更早)。顺序 fold 与平衡树在「多条 robIdx 相等」的
  //  非法态下选择不同 entry → FM 判 s1/s2 数据寄存器 not-equivalent。故照 golden 树形。
  //
  //  候选 = {valid, robIdx(flag+value), 载荷(isRVC/ftqFlag/ftqPtr/ftqOffset)}。
  typedef struct packed {
    logic                 v;
    logic                 flag;   // robIdx.flag
    logic [ROB_W-1:0]     rob;    // robIdx.value
    logic                 isRVC;
    logic                 ftqf;   // ftqPtr.flag
    logic [FTQ_W-1:0]     ftqp;   // ftqPtr.value
    logic [FTQOFF_W-1:0]  ftqo;   // ftqOffset
  } sel_cand_t;

  // pairwise 取更老者（镜像 golden oldest：两 valid 时选更老，单 valid 选有效者）。
  //   sel_right = golden `_oldest_T ? (_oldest_T_1 ? R : L) : (_oldest_T_4 ? L : R)`
  //   _oldest_T   = L.v & R.v; _oldest_T_1 = isAfter(L,R)(=L 更年轻); _oldest_T_4 = L.v & ~R.v
  function automatic sel_cand_t pick_older(input sel_cand_t l, input sel_cand_t r);
    logic sel_r;  // 1 = 选 r
    if (l.v && r.v) sel_r = rob_is_after(l.flag, l.rob, r.flag, r.rob); // L 更年轻→选 R(更老)
    else if (l.v && !r.v) sel_r = 1'b0;
    else sel_r = 1'b1;
    return sel_r ? r : l;
  endfunction

  // 组内 8 条的原始候选（叶子）——**每条目一个组合信号**（不用读模块信号的 function，
  //   否则 FMR_VLOG-091 被 FM 升级为错误。pick_older 是纯函数只用入参，合法）。
  sel_cand_t leaf [ST_W][RAW_SIZE];
  always_comb
    for (int i = 0; i < ST_W; i++)
      for (int idx = 0; idx < RAW_SIZE; idx++) begin
        leaf[i][idx].v     = lq_violation_sel[i][idx];
        leaf[i][idx].flag  = entry_robFlag[idx];
        leaf[i][idx].rob   = entry_robIdx[idx];
        leaf[i][idx].isRVC = entry_isRVC[idx];
        leaf[i][idx].ftqf  = entry_ftqFlag[idx];
        leaf[i][idx].ftqp  = entry_ftqPtr[idx];
        leaf[i][idx].ftqo  = entry_ftqOffset[idx];
      end

  // stage1 组合：每组 8 条按平衡树选最老
  logic                 grp_valid [ST_W][N_GROUP];
  logic [ROB_W-1:0]     grp_rob   [ST_W][N_GROUP];
  logic                 grp_flag  [ST_W][N_GROUP];
  logic                 grp_isRVC [ST_W][N_GROUP];
  logic                 grp_ftqf  [ST_W][N_GROUP];
  logic [FTQ_W-1:0]     grp_ftqp  [ST_W][N_GROUP];
  logic [FTQOFF_W-1:0]  grp_ftqo  [ST_W][N_GROUP];
  always_comb begin
    for (int i = 0; i < ST_W; i++)
      for (int g = 0; g < N_GROUP; g++) begin
        int b;
        sel_cand_t ll, lr, rl, rr, res_l, res_r, grp;
        b = g*GROUP_SIZE;
        // (0,1)(2,3)→左半[0..3]，(4,5)(6,7)→右半[4..7]，再合并
        ll    = pick_older(leaf[i][b+0], leaf[i][b+1]);
        lr    = pick_older(leaf[i][b+2], leaf[i][b+3]);
        res_l = pick_older(ll, lr);
        rl    = pick_older(leaf[i][b+4], leaf[i][b+5]);
        rr    = pick_older(leaf[i][b+6], leaf[i][b+7]);
        res_r = pick_older(rl, rr);
        grp   = pick_older(res_l, res_r);
        grp_valid[i][g]=grp.v;   grp_rob[i][g]=grp.rob;  grp_flag[i][g]=grp.flag;
        grp_isRVC[i][g]=grp.isRVC; grp_ftqf[i][g]=grp.ftqf;
        grp_ftqp[i][g]=grp.ftqp; grp_ftqo[i][g]=grp.ftqo;
      end
  end

  // stage1 寄存器
  logic                 s1_valid [ST_W][N_GROUP];
  logic [ROB_W-1:0]     s1_rob   [ST_W][N_GROUP];
  logic                 s1_flag  [ST_W][N_GROUP];
  logic                 s1_isRVC [ST_W][N_GROUP];
  logic                 s1_ftqf  [ST_W][N_GROUP];
  logic [FTQ_W-1:0]     s1_ftqp  [ST_W][N_GROUP];
  logic [FTQOFF_W-1:0]  s1_ftqo  [ST_W][N_GROUP];

  // stage2 组合：4 组候选选最老——**平衡二叉树** (0,1)(2,3)→合并（镜像 golden）。
  //   每组候选 valid = s1_valid & ~flush_now(本拍 redirect) & ~flush_prev(该级寄存的
  //   redirect 副本 s1_redir_*)——golden `select_G_1`。比较键用未冲刷的 s1_rob/s1_flag。
  logic                 fin_valid [ST_W];
  logic [ROB_W-1:0]     fin_rob   [ST_W];
  logic                 fin_flag  [ST_W];
  logic                 fin_isRVC [ST_W];
  logic                 fin_ftqf  [ST_W];
  logic [FTQ_W-1:0]     fin_ftqp  [ST_W];
  logic [FTQOFF_W-1:0]  fin_ftqo  [ST_W];
  always_comb begin
    for (int i = 0; i < ST_W; i++) begin
      sel_cand_t gc [N_GROUP];   // 4 组的 flush-gated 候选
      sel_cand_t res_l, res_r, fin;
      for (int g = 0; g < N_GROUP; g++) begin
        logic flush_now, flush_prev;
        flush_now  = rob_need_flush(io_redirect_valid, io_redirect_bits_level,
                        s1_flag[i][g], s1_rob[i][g],
                        io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value);
        flush_prev = rob_need_flush(s1_redir_valid[i][g], s1_redir_level[i][g],
                        s1_flag[i][g], s1_rob[i][g], s1_redir_robf[i][g], s1_redir_robv[i][g]);
        gc[g].v     = s1_valid[i][g] && !flush_now && !flush_prev;
        gc[g].flag  = s1_flag[i][g];
        gc[g].rob   = s1_rob[i][g];
        gc[g].isRVC = s1_isRVC[i][g];
        gc[g].ftqf  = s1_ftqf[i][g];
        gc[g].ftqp  = s1_ftqp[i][g];
        gc[g].ftqo  = s1_ftqo[i][g];
      end
      res_l = pick_older(gc[0], gc[1]);
      res_r = pick_older(gc[2], gc[3]);
      fin   = pick_older(res_l, res_r);
      fin_valid[i]=fin.v;   fin_rob[i]=fin.rob;  fin_flag[i]=fin.flag;
      fin_isRVC[i]=fin.isRVC; fin_ftqf[i]=fin.ftqf; fin_ftqp[i]=fin.ftqp; fin_ftqo[i]=fin.ftqo;
    end
  end

  // stage2 寄存器（最终最老违例 load）
  logic                 s2_valid [ST_W];
  logic [ROB_W-1:0]     s2_rob   [ST_W];
  logic                 s2_flag  [ST_W];
  logic                 s2_isRVC [ST_W];
  logic                 s2_ftqf  [ST_W];
  logic [FTQ_W-1:0]     s2_ftqp  [ST_W];
  logic [FTQOFF_W-1:0]  s2_ftqo  [ST_W];

  // 基例：最终 valid && !needFlush(RegNext(redirect))（用 s2 级寄存的 redirect 副本）
  logic lq_violation [ST_W];
  always_comb
    for (int i = 0; i < ST_W; i++) begin
      logic flush_prev;
      flush_prev = rob_need_flush(s2_redir_valid[i], s2_redir_level[i],
                      s2_flag[i], s2_rob[i], s2_redir_robf[i], s2_redir_robv[i]);
      lq_violation[i] = s2_valid[i] && !flush_prev;
    end

  // ===========================================================================
  //  G. store fire / ftq 3 拍延迟（镜像 golden：每 store 端口 3 个 DelayN 子模块实例）
  // ===========================================================================
  logic             st_fire_dly_out [ST_W]; // DelayN_298(store.valid&!miss, 3)
  logic [FTQ_W-1:0] st_ftqp_dly_out [ST_W]; // DelayNWithValid_148(store ftqPtr.value)
  logic [FTQOFF_W-1:0] st_ftqo_dly_out [ST_W]; // DelayNWithValid_149(store ftqOffset)
  logic             st_fire_in [ST_W];
  always_comb for (int i = 0; i < ST_W; i++) st_fire_in[i] = st_valid[i] && !st_miss[i];

  DelayN_298_xs rollbackLqWb_0_valid_delay (
    .clock (clock), .io_in (st_fire_in[0]), .io_out (st_fire_dly_out[0]));
  DelayNWithValid_148_xs stFtqIdx_0_pipMod (
    .clock (clock), .reset (reset),
    .io_in_bits_value (st_ftqPtr_val[0]), .io_in_valid (st_valid[0]),
    .io_out_bits_value (st_ftqp_dly_out[0]));
  DelayNWithValid_149_xs stFtqOffset_0_pipMod (
    .clock (clock), .reset (reset),
    .io_in_bits (st_ftqOffset[0]), .io_in_valid (st_valid[0]),
    .io_out_bits (st_ftqo_dly_out[0]));

  DelayN_298_xs rollbackLqWb_1_valid_delay (
    .clock (clock), .io_in (st_fire_in[1]), .io_out (st_fire_dly_out[1]));
  DelayNWithValid_148_xs stFtqIdx_1_pipMod (
    .clock (clock), .reset (reset),
    .io_in_bits_value (st_ftqPtr_val[1]), .io_in_valid (st_valid[1]),
    .io_out_bits_value (st_ftqp_dly_out[1]));
  DelayNWithValid_149_xs stFtqOffset_1_pipMod (
    .clock (clock), .reset (reset),
    .io_in_bits (st_ftqOffset[1]), .io_in_valid (st_valid[1]),
    .io_out_bits (st_ftqo_dly_out[1]));

  // ===========================================================================
  //  H. rollback / lqFull / perf
  // ===========================================================================
  logic             rb_valid [ST_W];
  always_comb for (int i = 0; i < ST_W; i++) rb_valid[i] = lq_violation[i] && st_fire_dly_out[i];

  assign io_rollback_0_valid              = rb_valid[0];
  assign io_rollback_0_bits_isRVC         = s2_isRVC[0];
  assign io_rollback_0_bits_robIdx_flag   = s2_flag[0];
  assign io_rollback_0_bits_robIdx_value  = s2_rob[0];
  assign io_rollback_0_bits_ftqIdx_flag   = s2_ftqf[0];
  assign io_rollback_0_bits_ftqIdx_value  = s2_ftqp[0];
  assign io_rollback_0_bits_ftqOffset     = s2_ftqo[0];
  assign io_rollback_0_bits_stFtqIdx_value= st_ftqp_dly_out[0];
  assign io_rollback_0_bits_stFtqOffset   = st_ftqo_dly_out[0];

  assign io_rollback_1_valid              = rb_valid[1];
  assign io_rollback_1_bits_isRVC         = s2_isRVC[1];
  assign io_rollback_1_bits_robIdx_flag   = s2_flag[1];
  assign io_rollback_1_bits_robIdx_value  = s2_rob[1];
  assign io_rollback_1_bits_ftqIdx_flag   = s2_ftqf[1];
  assign io_rollback_1_bits_ftqIdx_value  = s2_ftqp[1];
  assign io_rollback_1_bits_ftqOffset     = s2_ftqo[1];
  assign io_rollback_1_bits_stFtqIdx_value= st_ftqp_dly_out[1];
  assign io_rollback_1_bits_stFtqOffset   = st_ftqo_dly_out[1];

  assign io_lqFull = fl_empty;

  logic [1:0] perf0_d, perf0_dd;
  logic       perf1_d, perf1_dd;
  logic [1:0] enq_cnt;
  logic       rb_any;
  always_comb begin
    enq_cnt = 2'(q_req_valid[0] && q_req_ready[0]) +
              2'(q_req_valid[1] && q_req_ready[1]) +
              2'(q_req_valid[2] && q_req_ready[2]);
    rb_any  = rb_valid[0] | rb_valid[1];
  end
  assign io_perf_0_value = 6'(perf0_dd);
  assign io_perf_1_value = 6'(perf1_dd);

  // ===========================================================================
  //  时序逻辑 —— **两个 always 块**（严格镜像 golden firtool 输出）
  // -----------------------------------------------------------------------------
  //  golden 把寄存器分成两组，用**两个独立 always 块**表达：
  //    (1) always @(posedge clock or posedge reset)：仅带 reset 的架构状态——
  //        allocated / datavalid / entryNeedCheck_r / selValidNext_last_REG(=s2_valid)
  //        / lastCanAccept_r / lastAllocIndex_*。
  //    (2) always @(posedge clock)（**无 reset 敏感**）：所有 enable-only 寄存器——
  //        entry payload(uop 各域) / 违例 store 锁存(violationMdata_r) / s1 组寄存器 +
  //        s1/s2 数据 + redirect 各级副本 + perf。
  //
  //  ★关键(FM 等价铁律)：enable-only 寄存器**必须放进不含 reset 的 always 块**。
  //  若把它们放进 `@(posedge clock or posedge reset)` 的 else 分支里(即使 reset 分支
  //  不赋值它们)，综合/FM 前端仍会把 `reset` 引入其 next-state cone(reset 时保持)——
  //  与 golden 的纯 `@(posedge clock)` 版本 cone 不一致 → FM 判 1530 个顶层 glue
  //  寄存器 not-equivalent(analyze_points: "reset exists in impl cone but not ref")。
  //  拆成两块后, enable-only 寄存器 cone 无 reset, 与 golden 逐点等价。
  // ===========================================================================
  // ---- 块 (1)：带 reset 的架构状态（与 golden reset 集合逐一对应）----
  always_ff @(posedge clock or posedge reset) begin
    int ii;
    if (reset) begin
      for (ii = 0; ii < RAW_SIZE; ii++) begin
        allocated[ii] <= 1'b0;
        datavalid[ii] <= 1'b0;
      end
      for (ii = 0; ii < ST_W; ii++)
        for (int j = 0; j < RAW_SIZE; j++)
          entry_need_check[ii][j] <= 1'b0;
      for (ii = 0; ii < ST_W; ii++) s2_valid[ii] <= 1'b0;
      for (ii = 0; ii < LD_W; ii++) begin
        last_can_accept[ii]  <= 1'b0;
        last_alloc_index[ii] <= '0;
      end
    end else begin
      // allocated / datavalid：enqueue 置位 + dequeue/revoke 清位
      for (ii = 0; ii < LD_W; ii++)
        if (accepted[ii]) begin
          allocated[enq_index[ii]] <= 1'b1;
          datavalid[enq_index[ii]] <= q_data_valid[ii];
        end
      for (ii = 0; ii < RAW_SIZE; ii++)
        if (free_mask[ii]) allocated[ii] <= 1'b0;

      // revoke 记录上一拍
      for (ii = 0; ii < LD_W; ii++) begin
        last_can_accept[ii]  <= accepted[ii];
        last_alloc_index[ii] <= enq_index[ii];
      end

      // entryNeedCheck_r（每 store 端口 × 每条目）+ s2_valid（selValidNext_last_REG）
      //   next-state 用组合信号 entry_need_check_next（下方 always_comb），避免在 always_ff
      //   内用 blocking 临时量 younger/nf（否则被 FM 推成死寄存器 → impl-only unread）。
      for (ii = 0; ii < ST_W; ii++) begin
        for (int j = 0; j < RAW_SIZE; j++)
          entry_need_check[ii][j] <= entry_need_check_next[ii][j];
        s2_valid[ii] <= fin_valid[ii];
      end
    end
  end

  // ---- 块 (2)：enable-only 寄存器（**无 reset**，纯 posedge clock，镜像 golden）----
  always_ff @(posedge clock) begin
    int ii;
    // enqueue 写条目 payload（uop 各域，enable-only 无 reset）
    for (ii = 0; ii < LD_W; ii++)
      if (accepted[ii]) begin
        entry_robFlag[enq_index[ii]]   <= q_robIdx_flag[ii];
        entry_robIdx[enq_index[ii]]    <= q_robIdx_val[ii];
        entry_sqFlag[enq_index[ii]]    <= q_sqIdx_flag[ii];
        entry_sqIdx[enq_index[ii]]     <= q_sqIdx_val[ii];
        entry_isRVC[enq_index[ii]]     <= q_req_isRVC[ii];
        entry_ftqFlag[enq_index[ii]]   <= q_ftqPtr_flag[ii];
        entry_ftqPtr[enq_index[ii]]    <= q_ftqPtr_val[ii];
        entry_ftqOffset[enq_index[ii]] <= q_ftqOffset[ii];
      end

    // 违例流水寄存器（每 store 端口，enable-only 无 reset）
    for (ii = 0; ii < ST_W; ii++) begin
      // store paddr/mask 锁存（golden violationMdata_r，仅 storeIn.valid 门控）
      if (st_valid[ii]) begin
        st_paddr_r[ii] <= st_paddr[ii][PPA_HI:PADDR_OFFSET];   // 只锁存被 CAM 读的 [27:4]
        st_mask_r[ii]  <= st_mask[ii];
      end
      // s1 组寄存器 + 该级 RegNext(redirect) 副本（golden select_REG_{4p+g}）
      for (int g = 0; g < N_GROUP; g++) begin
        s1_valid[ii][g] <= grp_valid[ii][g];
        if (grp_valid[ii][g]) begin
          s1_rob[ii][g]  <= grp_rob[ii][g];
          s1_flag[ii][g] <= grp_flag[ii][g];
          s1_isRVC[ii][g]<= grp_isRVC[ii][g];
          s1_ftqf[ii][g] <= grp_ftqf[ii][g];
          s1_ftqp[ii][g] <= grp_ftqp[ii][g];
          s1_ftqo[ii][g] <= grp_ftqo[ii][g];
        end
        s1_redir_valid[ii][g] <= io_redirect_valid;
        s1_redir_level[ii][g] <= io_redirect_bits_level;
        s1_redir_robf[ii][g]  <= io_redirect_bits_robIdx_flag;
        s1_redir_robv[ii][g]  <= io_redirect_bits_robIdx_value;
      end
      // s2 数据（最终最老违例 load）+ 该级 RegNext(redirect) 副本（golden lqSelect_REG(_1)）
      if (fin_valid[ii]) begin
        s2_rob[ii]  <= fin_rob[ii];
        s2_flag[ii] <= fin_flag[ii];
        s2_isRVC[ii]<= fin_isRVC[ii];
        s2_ftqf[ii] <= fin_ftqf[ii];
        s2_ftqp[ii] <= fin_ftqp[ii];
        s2_ftqo[ii] <= fin_ftqo[ii];
      end
      s2_redir_valid[ii] <= io_redirect_valid;
      s2_redir_level[ii] <= io_redirect_bits_level;
      s2_redir_robf[ii]  <= io_redirect_bits_robIdx_flag;
      s2_redir_robv[ii]  <= io_redirect_bits_robIdx_value;
    end

    // perf（golden 无 reset：RegNext 链）
    perf0_d <= enq_cnt; perf0_dd <= perf0_d;
    perf1_d <= rb_any;  perf1_dd <= perf1_d;
  end

endmodule
