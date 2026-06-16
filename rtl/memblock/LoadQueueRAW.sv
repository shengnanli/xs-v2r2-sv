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
//  ── 本核分节（与 Scala 一一对应）──
//    A. 端口聚合（扁平 golden 端口 ↔ 数组）
//    B. 入队判定 needEnqueue
//    C. freelist（分配/释放空闲条目索引，enablePreAlloc）
//    D. enqueue（写 entry）
//    E. dequeue / revoke（释放条目）
//    F. 违例检测流水（每 store 端口：CAM → entryNeedCheck → 两段最老选择）
//    G. store fire / ftq 的 3 拍延迟
//    H. rollback 输出 / lqFull / perf
// =============================================================================
module xs_LoadQueueRAW_core
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
  //  队列状态寄存器
  // ===========================================================================
  ld_uop_t              entry      [RAW_SIZE];
  logic                 allocated  [RAW_SIZE];
  logic                 datavalid  [RAW_SIZE];
  logic [PPA_W-1:0]     ppaddr     [RAW_SIZE];
  logic [MASK_BITS-1:0] emask      [RAW_SIZE];

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
  //  C. freelist（FreeList.scala: size=32, allocWidth=3, freeWidth=4, preAlloc）
  // ===========================================================================
  localparam int PTR_W = IDX_W + 1; // {flag,value}=6 位

  logic [IDX_W-1:0] free_list [RAW_SIZE];
  logic [PTR_W-1:0] head_ptr, tail_ptr;
  logic [IDX_W:0]   free_slot_cnt;

  // 环形 isBefore：a 在 b 之前（严格小于，CircularQueuePtr 语义）
  function automatic logic ptr_is_before(input logic [PTR_W-1:0] a, input logic [PTR_W-1:0] b);
    // a < b = (a.flag ^ b.flag) ^ (a.value < b.value)
    return (a[PTR_W-1] ^ b[PTR_W-1]) ^ (a[IDX_W-1:0] < b[IDX_W-1:0]);
  endfunction
  // 环形 distanceBetween(enq, deq)：有效条数（这里用于 freeSlotCnt = 空闲槽数）
  function automatic logic [IDX_W:0] ptr_distance(input logic [PTR_W-1:0] enq, input logic [PTR_W-1:0] deq);
    if (enq[PTR_W-1] == deq[PTR_W-1])
      return {1'b0, enq[IDX_W-1:0]} - {1'b0, deq[IDX_W-1:0]};
    else
      return (IDX_W+1)'(RAW_SIZE) - {1'b0, deq[IDX_W-1:0]} + {1'b0, enq[IDX_W-1:0]};
  endfunction

  // --- 分配 ---
  logic             do_allocate   [LD_W];
  logic [1:0]       num_allocate;
  logic             do_alloc_any;
  logic [PTR_W-1:0] head_ptr_next;
  always_comb begin
    num_allocate = 2'(do_allocate[0]) + 2'(do_allocate[1]) + 2'(do_allocate[2]);
    do_alloc_any = do_allocate[0] | do_allocate[1] | do_allocate[2];
    head_ptr_next = head_ptr + PTR_W'(num_allocate);
  end

  // preAlloc 组合：deqPtr_w = headPtr + numAllocate + w，下一拍寄存
  logic             can_alloc_d   [LD_W];
  logic [IDX_W-1:0] alloc_slot_d  [LD_W];
  always_comb begin
    for (int w = 0; w < LD_W; w++) begin
      logic [PTR_W-1:0] deq_ptr;
      deq_ptr = head_ptr + PTR_W'(num_allocate) + PTR_W'(w);
      can_alloc_d[w]  = ptr_is_before(deq_ptr, tail_ptr);
      alloc_slot_d[w] = free_list[deq_ptr[IDX_W-1:0]];
    end
  end
  // preAlloc 寄存器输出（声明 4 深，索引用 2 位 off=PopCount(needEnqueue.take(w))
  //   范围 0..2，永不到 3；4 深仅为让 2 位索引在静态分析里始终在界内）
  logic             can_allocate_r [4];
  logic [IDX_W-1:0] allocate_slot_r[4];

  // ===========================================================================
  //  D. enqueue
  // ===========================================================================
  logic             accepted   [LD_W];
  logic [IDX_W-1:0] enq_index  [LD_W];
  always_comb begin
    for (int w = 0; w < LD_W; w++) begin
      logic [1:0] off;
      off = 2'd0;
      for (int k = 0; k < LD_W; k++)
        if (k < w && need_enqueue[k]) off = off + 2'd1;
      enq_index[w]   = allocate_slot_r[off];
      q_req_ready[w] = need_enqueue[w] ? can_allocate_r[off] : 1'b1;
      accepted[w]    = need_enqueue[w] && q_req_ready[w];
      do_allocate[w] = accepted[w];
    end
  end

  // ===========================================================================
  //  E. dequeue / revoke 释放
  // ===========================================================================
  logic free_mask [RAW_SIZE];
  logic             last_can_accept [LD_W];
  logic [IDX_W-1:0] last_alloc_index[LD_W];
  always_comb begin
    for (int i = 0; i < RAW_SIZE; i++) begin
      logic deq_not_block, need_cancel;
      deq_not_block = all_addr_check ? 1'b1 :
          !sq_is_before(io_stAddrReadySqPtr_flag, io_stAddrReadySqPtr_value,
                        entry[i].sqFlag, entry[i].sqIdx);
      need_cancel = rob_need_flush(io_redirect_valid, io_redirect_bits_level,
                        entry[i].robFlag, entry[i].robIdx,
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
  logic [RAW_SIZE-1:0] free_bits;
  always_comb for (int i = 0; i < RAW_SIZE; i++) free_bits[i] = free_mask[i];

  // ---- freelist 释放选择（freeWidth=4 lane 优先编码）----
  logic [RAW_SIZE-1:0] pend_free_mask;
  logic [RAW_SIZE-1:0] free_sel_mask;
  logic [RAW_SIZE-1:0] free_sel_oh32  [4]; // 各 lane 选中的 32 位 one-hot
  logic [7:0]          rem_free_mask  [4];
  logic [3:0]          free_req_d;
  always_comb begin
    logic [RAW_SIZE-1:0] avail;
    free_sel_mask = '0;
    for (int rem = 0; rem < 4; rem++) begin
      logic [7:0] lane_oh;
      avail = (free_bits | pend_free_mask) & ~free_sel_mask;
      for (int i = 0; i < RAW_SIZE/4; i++) rem_free_mask[rem][i] = avail[4*i+rem];
      lane_oh = rem_free_mask[rem] & (~rem_free_mask[rem] + 8'd1); // 最低位独热
      free_sel_oh32[rem] = '0;
      for (int i = 0; i < RAW_SIZE/4; i++) free_sel_oh32[rem][4*i+rem] = lane_oh[i];
      free_sel_mask = free_sel_mask | free_sel_oh32[rem];
      free_req_d[rem] = |rem_free_mask[rem];
    end
  end
  // 寄存释放请求与选中槽索引（GatedRegNext）
  logic [3:0]       free_req_r;
  logic [IDX_W-1:0] free_slot_idx_r [4]; // OHToUInt(freeSlotOH)

  // OHToUInt：32 位 one-hot → 5 位索引
  function automatic logic [IDX_W-1:0] oh_to_idx(input logic [RAW_SIZE-1:0] oh);
    logic [IDX_W-1:0] r;
    r = '0;
    for (int b = 0; b < RAW_SIZE; b++) if (oh[b]) r = IDX_W'(b);
    return r;
  endfunction

  // ===========================================================================
  //  F. 违例检测流水
  // ===========================================================================
  // s0: store 地址/mask 锁存 + CAM 匹配
  logic [PPA_W-1:0]     st_ppa_r   [ST_W];
  logic [MASK_BITS-1:0] st_mask_r  [ST_W];
  logic                 entry_need_check [ST_W][RAW_SIZE];
  logic                 addr_mask_match  [ST_W][RAW_SIZE];
  always_comb begin
    for (int i = 0; i < ST_W; i++)
      for (int j = 0; j < RAW_SIZE; j++) begin
        logic ph, mh;
        ph = paddr_cam_hit(st_ppa_r[i], ppaddr[j], st_wlineflag[i]);
        mh = mask_cam_hit (st_mask_r[i], emask[j]);
        addr_mask_match[i][j] = ph & mh;
      end
  end

  // s1: 违例向量
  logic lq_violation_sel [ST_W][RAW_SIZE];
  always_comb
    for (int i = 0; i < ST_W; i++)
      for (int j = 0; j < RAW_SIZE; j++)
        lq_violation_sel[i][j] = addr_mask_match[i][j] && entry_need_check[i][j];

  // redirect 打一拍
  logic             redirect_valid_r, redirect_level_r, redirect_robf_r;
  logic [ROB_W-1:0] redirect_robv_r;

  // 最老选择纯函数：选更老者，1=选右(rhs)
  function automatic logic pick_older_sel(
      input logic vl, input logic [ROB_W-1:0] rl, input logic fl,
      input logic vr, input logic [ROB_W-1:0] rr, input logic fr);
    if (vl && vr) return rob_is_after(fl, rl, fr, rr);
    else if (vl && !vr) return 1'b0;
    else return 1'b1;
  endfunction

  // stage1 组合：每组 8 条选最老
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
        logic accv, accf, acci, accqf;
        logic [ROB_W-1:0] accr;
        logic [FTQ_W-1:0] accp;
        logic [FTQOFF_W-1:0] acco;
        accv=1'b0; accr='0; accf=1'b0; acci=1'b0; accqf=1'b0; accp='0; acco='0;
        for (int k = 0; k < GROUP_SIZE; k++) begin
          int idx; logic cand_v, sel;
          idx = g*GROUP_SIZE + k;
          cand_v = lq_violation_sel[i][idx];
          sel = pick_older_sel(accv, accr, accf, cand_v, entry[idx].robIdx, entry[idx].robFlag);
          if (sel) begin
            accv=cand_v; accr=entry[idx].robIdx; accf=entry[idx].robFlag;
            acci=entry[idx].isRVC; accqf=entry[idx].ftqFlag;
            accp=entry[idx].ftqPtr; acco=entry[idx].ftqOffset;
          end
        end
        grp_valid[i][g]=accv; grp_rob[i][g]=accr; grp_flag[i][g]=accf;
        grp_isRVC[i][g]=acci; grp_ftqf[i][g]=accqf; grp_ftqp[i][g]=accp; grp_ftqo[i][g]=acco;
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

  // stage2 组合：4 组候选选最老（扣掉被本拍/上拍 redirect 冲刷的组候选）
  logic                 fin_valid [ST_W];
  logic [ROB_W-1:0]     fin_rob   [ST_W];
  logic                 fin_flag  [ST_W];
  logic                 fin_isRVC [ST_W];
  logic                 fin_ftqf  [ST_W];
  logic [FTQ_W-1:0]     fin_ftqp  [ST_W];
  logic [FTQOFF_W-1:0]  fin_ftqo  [ST_W];
  always_comb begin
    for (int i = 0; i < ST_W; i++) begin
      logic accv, accf, acci, accqf;
      logic [ROB_W-1:0] accr;
      logic [FTQ_W-1:0] accp;
      logic [FTQOFF_W-1:0] acco;
      accv=1'b0; accr='0; accf=1'b0; acci=1'b0; accqf=1'b0; accp='0; acco='0;
      for (int g = 0; g < N_GROUP; g++) begin
        logic cand_v, sel, flush_now, flush_prev;
        flush_now  = rob_need_flush(io_redirect_valid, io_redirect_bits_level,
                        s1_flag[i][g], s1_rob[i][g],
                        io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value);
        flush_prev = rob_need_flush(redirect_valid_r, redirect_level_r,
                        s1_flag[i][g], s1_rob[i][g], redirect_robf_r, redirect_robv_r);
        cand_v = s1_valid[i][g] && !flush_now && !flush_prev;
        sel = pick_older_sel(accv, accr, accf, cand_v, s1_rob[i][g], s1_flag[i][g]);
        if (sel) begin
          accv=cand_v; accr=s1_rob[i][g]; accf=s1_flag[i][g];
          acci=s1_isRVC[i][g]; accqf=s1_ftqf[i][g]; accp=s1_ftqp[i][g]; acco=s1_ftqo[i][g];
        end
      end
      fin_valid[i]=accv; fin_rob[i]=accr; fin_flag[i]=accf;
      fin_isRVC[i]=acci; fin_ftqf[i]=accqf; fin_ftqp[i]=accp; fin_ftqo[i]=acco;
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

  // 基例：最终 valid && !needFlush(RegNext(redirect))
  logic lq_violation [ST_W];
  always_comb
    for (int i = 0; i < ST_W; i++) begin
      logic flush_prev;
      flush_prev = rob_need_flush(redirect_valid_r, redirect_level_r,
                      s2_flag[i], s2_rob[i], redirect_robf_r, redirect_robv_r);
      lq_violation[i] = s2_valid[i] && !flush_prev;
    end

  // ===========================================================================
  //  G. store fire / ftq 3 拍延迟
  // ===========================================================================
  logic [2:0]          st_fire_dly [ST_W]; // DelayN(store.valid&!miss, 3)
  logic [2:0]          st_vld_dly  [ST_W]; // store.valid 链（gate DelayNWithValid）
  logic [FTQ_W-1:0]    st_ftqp_dly [ST_W][3];
  logic [FTQOFF_W-1:0] st_ftqo_dly [ST_W][3];

  // ===========================================================================
  //  H. rollback / lqFull / perf
  // ===========================================================================
  logic             rb_valid [ST_W];
  always_comb for (int i = 0; i < ST_W; i++) rb_valid[i] = lq_violation[i] && st_fire_dly[i][2];

  assign io_rollback_0_valid              = rb_valid[0];
  assign io_rollback_0_bits_isRVC         = s2_isRVC[0];
  assign io_rollback_0_bits_robIdx_flag   = s2_flag[0];
  assign io_rollback_0_bits_robIdx_value  = s2_rob[0];
  assign io_rollback_0_bits_ftqIdx_flag   = s2_ftqf[0];
  assign io_rollback_0_bits_ftqIdx_value  = s2_ftqp[0];
  assign io_rollback_0_bits_ftqOffset     = s2_ftqo[0];
  assign io_rollback_0_bits_stFtqIdx_value= st_ftqp_dly[0][2];
  assign io_rollback_0_bits_stFtqOffset   = st_ftqo_dly[0][2];

  assign io_rollback_1_valid              = rb_valid[1];
  assign io_rollback_1_bits_isRVC         = s2_isRVC[1];
  assign io_rollback_1_bits_robIdx_flag   = s2_flag[1];
  assign io_rollback_1_bits_robIdx_value  = s2_rob[1];
  assign io_rollback_1_bits_ftqIdx_flag   = s2_ftqf[1];
  assign io_rollback_1_bits_ftqIdx_value  = s2_ftqp[1];
  assign io_rollback_1_bits_ftqOffset     = s2_ftqo[1];
  assign io_rollback_1_bits_stFtqIdx_value= st_ftqp_dly[1][2];
  assign io_rollback_1_bits_stFtqOffset   = st_ftqo_dly[1][2];

  assign io_lqFull = (free_slot_cnt == '0);

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
  //  时序逻辑
  // ===========================================================================
  logic [2:0]       num_free;
  logic             do_free;
  logic [PTR_W-1:0] tail_ptr_next;
  always_comb begin
    num_free = 3'(free_req_r[0]) + 3'(free_req_r[1]) + 3'(free_req_r[2]) + 3'(free_req_r[3]);
    do_free  = |free_req_r;
    tail_ptr_next = tail_ptr + PTR_W'(num_free);
  end

  integer ii;
  always_ff @(posedge clock) begin
    if (reset) begin
      head_ptr <= '0;
      tail_ptr <= {1'b1, {IDX_W{1'b0}}};
      free_slot_cnt <= (IDX_W+1)'(RAW_SIZE);
      pend_free_mask <= '0;
      free_req_r <= '0;
      for (ii = 0; ii < RAW_SIZE; ii++) begin
        allocated[ii] <= 1'b0;
        datavalid[ii] <= 1'b0;
        free_list[ii] <= IDX_W'(ii);
      end
      for (ii = 0; ii < LD_W; ii++) begin
        last_can_accept[ii] <= 1'b0;
        can_allocate_r[ii]  <= 1'b0;
        allocate_slot_r[ii] <= '0;
        last_alloc_index[ii]<= '0;
      end
      redirect_valid_r <= 1'b0; redirect_level_r <= 1'b0;
      redirect_robf_r <= 1'b0; redirect_robv_r <= '0;
      perf0_d <= '0; perf0_dd <= '0; perf1_d <= 1'b0; perf1_dd <= 1'b0;
      for (ii = 0; ii < ST_W; ii++) begin
        st_fire_dly[ii] <= '0; st_vld_dly[ii] <= '0;
      end
      for (ii = 0; ii < 4; ii++) free_slot_idx_r[ii] <= '0;
    end else begin
      // ---- freelist 分配预寄存 ----
      for (ii = 0; ii < LD_W; ii++) begin
        can_allocate_r[ii]  <= can_alloc_d[ii];
        allocate_slot_r[ii] <= alloc_slot_d[ii];
      end
      if (do_alloc_any) head_ptr <= head_ptr_next;

      // ---- freelist 释放 ----
      pend_free_mask <= (free_bits | pend_free_mask) & ~free_sel_mask;
      free_req_r <= free_req_d;
      for (ii = 0; ii < 4; ii++) free_slot_idx_r[ii] <= oh_to_idx(free_sel_oh32[ii]);
      begin
        logic [1:0]       foff;
        logic [PTR_W-1:0] enq_ptr;
        foff = 2'd0;
        for (ii = 0; ii < 4; ii++)
          if (free_req_r[ii]) begin
            enq_ptr = tail_ptr + PTR_W'(foff);
            free_list[enq_ptr[IDX_W-1:0]] <= free_slot_idx_r[ii];
            foff = foff + 2'd1;
          end
      end
      if (do_free) tail_ptr <= tail_ptr_next;

      // ---- 空闲计数：distanceBetween(tailPtrNext, headPtrNext) ----
      free_slot_cnt <= ptr_distance(tail_ptr_next, head_ptr_next);

      // ---- redirect 打一拍 ----
      redirect_valid_r <= io_redirect_valid;
      redirect_level_r <= io_redirect_bits_level;
      redirect_robf_r  <= io_redirect_bits_robIdx_flag;
      redirect_robv_r  <= io_redirect_bits_robIdx_value;

      // ---- enqueue 写条目 ----
      for (ii = 0; ii < LD_W; ii++)
        if (accepted[ii]) begin
          allocated[enq_index[ii]] <= 1'b1;
          datavalid[enq_index[ii]] <= q_data_valid[ii];
          ppaddr[enq_index[ii]]    <= gen_partial_paddr(q_paddr[ii]);
          emask[enq_index[ii]]     <= q_mask[ii];
          entry[enq_index[ii]].robFlag     <= q_robIdx_flag[ii];
          entry[enq_index[ii]].robIdx    <= q_robIdx_val[ii];
          entry[enq_index[ii]].sqFlag    <= q_sqIdx_flag[ii];
          entry[enq_index[ii]].sqIdx     <= q_sqIdx_val[ii];
          entry[enq_index[ii]].isRVC     <= q_req_isRVC[ii];
          entry[enq_index[ii]].ftqFlag   <= q_ftqPtr_flag[ii];
          entry[enq_index[ii]].ftqPtr    <= q_ftqPtr_val[ii];
          entry[enq_index[ii]].ftqOffset <= q_ftqOffset[ii];
        end

      // ---- dequeue / revoke 清 allocated ----
      for (ii = 0; ii < RAW_SIZE; ii++)
        if (free_mask[ii]) allocated[ii] <= 1'b0;

      // ---- revoke 记录上一拍 ----
      for (ii = 0; ii < LD_W; ii++) begin
        last_can_accept[ii]  <= accepted[ii];
        last_alloc_index[ii] <= enq_index[ii];
      end

      // ---- 违例流水寄存器（每 store 端口）----
      for (ii = 0; ii < ST_W; ii++) begin
        if (st_valid[ii]) begin
          st_ppa_r[ii]  <= gen_partial_paddr(st_paddr[ii]);
          st_mask_r[ii] <= st_mask[ii];
        end
        for (int j = 0; j < RAW_SIZE; j++) begin
          logic younger, nf;
          younger = rob_is_after(entry[j].robFlag, entry[j].robIdx,
                       st_robIdx_flag[ii], st_robIdx_val[ii]);
          nf = rob_need_flush(io_redirect_valid, io_redirect_bits_level,
                       entry[j].robFlag, entry[j].robIdx,
                       io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value);
          entry_need_check[ii][j] <= allocated[j] && st_valid[ii] && younger && datavalid[j] && !nf;
        end
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
        end
        s2_valid[ii] <= fin_valid[ii];
        if (fin_valid[ii]) begin
          s2_rob[ii]  <= fin_rob[ii];
          s2_flag[ii] <= fin_flag[ii];
          s2_isRVC[ii]<= fin_isRVC[ii];
          s2_ftqf[ii] <= fin_ftqf[ii];
          s2_ftqp[ii] <= fin_ftqp[ii];
          s2_ftqo[ii] <= fin_ftqo[ii];
        end
        st_fire_dly[ii] <= {st_fire_dly[ii][1:0], st_valid[ii] && !st_miss[ii]};
        st_vld_dly[ii]  <= {st_vld_dly[ii][1:0], st_valid[ii]};
        if (st_valid[ii]) begin
          st_ftqp_dly[ii][0] <= st_ftqPtr_val[ii];
          st_ftqo_dly[ii][0] <= st_ftqOffset[ii];
        end
        if (st_vld_dly[ii][0]) begin
          st_ftqp_dly[ii][1] <= st_ftqp_dly[ii][0];
          st_ftqo_dly[ii][1] <= st_ftqo_dly[ii][0];
        end
        if (st_vld_dly[ii][1]) begin
          st_ftqp_dly[ii][2] <= st_ftqp_dly[ii][1];
          st_ftqo_dly[ii][2] <= st_ftqo_dly[ii][1];
        end
      end

      // ---- perf ----
      perf0_d <= enq_cnt; perf0_dd <= perf0_d;
      perf1_d <= rb_any;  perf1_dd <= perf1_d;
    end
  end

endmodule
