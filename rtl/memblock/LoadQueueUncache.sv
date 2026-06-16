// =============================================================================
//  LoadQueueUncache —— load 队列的不可缓存/MMIO 请求管理单元
// -----------------------------------------------------------------------------
//  设计意图来源：xiangshan/mem/lsqueue/LoadQueueUncache.scala。
//
//  本单元不直接保存 load 数据，而是管理 4 个 UncacheEntry 槽：
//    * LoadUnit S3 的 3 路请求先按 ROB 年龄排序，下一拍过滤 redirect/exception/replay；
//    * freelist 为可入队请求分配槽，分配失败的最老请求触发 rollback，让前端重取重做；
//    * 每个槽内部负责“等 ROB 头、发 Uncache、等响应、写回”的状态机；
//    * 顶层只做槽和外部 UncacheWordIO 之间的路由：MMIO 优先，NC 走 RR 仲裁；
//    * 写回侧 MMIO 固定到 UncacheWBPort=2，NC 按 NCWBPorts={1,2} 分两组返回。
//
//  UncacheEntry/FreeList/RRArbiter/PipelineReg 均复用 golden 子模块。可读重写的边界
//  是顶层控制和路由；这些子模块的内部数据/状态逻辑在 UT/FM 两侧共用同一份 RTL。
// =============================================================================
module xs_LoadQueueUncache_core
  import loadqueueuncache_pkg::*;
(
`include "loadqueueuncache_ports.svh"
);

  typedef struct packed {
    logic                  valid;
    logic [ENTRY_IDX_W-1:0] idx;
  } lqu_entry_sel_t;

  typedef enum logic {
    NC_REM_EVEN = 1'b0,
    NC_REM_ODD  = 1'b1
  } lqu_nc_rem_e;

  // ===========================================================================
  //  §0  端口聚合与子模块互联信号
  // ===========================================================================
  lqu_req_t       req_in        [LOAD_PIPE_W];
  logic           req_in_valid  [LOAD_PIPE_W];
  lqu_req_t       sorted_req    [LOAD_PIPE_W];
  logic           sorted_valid  [LOAD_PIPE_W];
  lqu_req_t       s2_req        [LOAD_PIPE_W];
  logic           s1_valid      [LOAD_PIPE_W];
  logic           s2_valid_q    [LOAD_PIPE_W];
  logic           s2_enqueue    [LOAD_PIPE_W];
  logic           s2_enq_accept [LOAD_PIPE_W];
  logic [1:0]     s2_alloc_slot [LOAD_PIPE_W];

  logic           rob_mmio_q [LOAD_PIPE_W];
  logic [7:0]     rob_uop_rob_value_q [LOAD_PIPE_W];

  lqu_req_t       entry_req_bits [ENTRY_NUM];
  logic           entry_req_valid[ENTRY_NUM];
  logic           entry_flush    [ENTRY_NUM];
  logic           entry_mmio_select[ENTRY_NUM];
  logic           entry_slave_valid[ENTRY_NUM];
  logic [1:0]     entry_slave_id [ENTRY_NUM];

  logic           entry_unc_valid[ENTRY_NUM];
  logic           entry_unc_req_ready[ENTRY_NUM];
  lqu_unc_req_t   entry_unc_req  [ENTRY_NUM];
  logic           entry_id_valid [ENTRY_NUM];
  logic           entry_resp_valid[ENTRY_NUM];

  logic           entry_mmio_ready[ENTRY_NUM];
  logic           entry_mmio_valid[ENTRY_NUM];
  lqu_mmio_out_t  entry_mmio_out[ENTRY_NUM];
  lqu_raw_t       entry_raw[ENTRY_NUM];

  logic           entry_nc_ready [ENTRY_NUM];
  logic           entry_nc_valid [ENTRY_NUM];
  lqu_nc_out_t    entry_nc_out[ENTRY_NUM];

  logic           entry_exception_valid[ENTRY_NUM];
  lqu_exception_t entry_exception[ENTRY_NUM];
  logic           exception_valid_sel;
  lqu_exception_t exception_sel;

  logic [1:0]     free_alloc_slot[LOAD_PIPE_W];
  logic [2:0]     free_can_allocate;
  logic [2:0]     free_valid_count;
  logic           free_empty;
  logic [ENTRY_NUM-1:0] free_mask;

  logic           nc_req_valid[ENTRY_NUM];
  logic           nc_req_ready[ENTRY_NUM];
  lqu_unc_req_t   nc_req_bits[ENTRY_NUM];
  logic           nc_arb_valid;
  logic           nc_arb_ready;
  lqu_unc_req_t   nc_arb_bits;

  logic           unc_pipe_in_ready;
  logic           unc_pipe_in_valid;
  lqu_unc_req_t   unc_pipe_in_bits;

  logic           mmio_pipe_in_ready;
  logic           mmio_pipe_in_valid;
  lqu_mmio_out_t  mmio_pipe_in_bits;
  lqu_raw_t       mmio_raw_sel;
  lqu_raw_t       mmio_raw_q;

  logic           nc_pipe_empty_ready, nc_pipe_empty_valid;
  logic           nc_pipe_even_ready,  nc_pipe_even_valid;
  logic           nc_pipe_odd_ready,   nc_pipe_odd_valid;
  lqu_nc_out_t    nc_pipe_empty_bits, nc_pipe_even_bits, nc_pipe_odd_bits;

  lqu_redirect_t  redirect_d1, redirect_d2;
  logic           rollback_valid_d;
  lqu_redirect_t  rollback_bits_d;

`include "loadqueueuncache_connect.svh"

  // 子模块例化。端口连接机械生成，所有行为控制信号在下方分节驱动。
`include "loadqueueuncache_subinst.svh"

  // ===========================================================================
  //  §1  Enqueue：S1 排序，S2 过滤并用 freelist 分配槽
  // ===========================================================================
  always_comb begin
    logic swap01, swap12, swap_final;
    lqu_req_t tmp0_req [2];
    logic     tmp0_valid [2];
    lqu_req_t tmp1_req;
    logic     tmp1_valid;

    // HwSort(DataWithPtr(... robIdx)) 的固定网络：0/1 先排，较新者再和 2 排，
    // 最后两个较老候选再排。ROB 指针比较在“异 flag 同 value”时不是严格全序，
    // 所以不能替换成多轮 bubble sort，否则会把第二次比较的结果交换回去。
    swap01 = req_in_valid[0] & req_in_valid[1]
           & rob_is_before(req_robidx(req_in[1]), req_robidx(req_in[0]));
    tmp0_req[0]   = swap01 ? req_in[1]       : req_in[0];
    tmp0_valid[0] = swap01 ? req_in_valid[1] : req_in_valid[0];
    tmp0_req[1]   = swap01 ? req_in[0]       : req_in[1];
    tmp0_valid[1] = swap01 ? req_in_valid[0] : req_in_valid[1];

    swap12 = tmp0_valid[1] & req_in_valid[2]
           & rob_is_before(req_robidx(req_in[2]), req_robidx(tmp0_req[1]));
    tmp1_req      = swap12 ? req_in[2]       : tmp0_req[1];
    tmp1_valid    = swap12 ? req_in_valid[2] : tmp0_valid[1];
    sorted_req[2] = swap12 ? tmp0_req[1]     : req_in[2];
    sorted_valid[2] = swap12 ? tmp0_valid[1] : req_in_valid[2];

    swap_final = tmp0_valid[0] & tmp1_valid
               & rob_is_before(req_robidx(tmp1_req), req_robidx(tmp0_req[0]));
    sorted_req[0]   = swap_final ? tmp1_req      : tmp0_req[0];
    sorted_valid[0] = swap_final ? tmp1_valid    : tmp0_valid[0];
    sorted_req[1]   = swap_final ? tmp0_req[0]   : tmp1_req;
    sorted_valid[1] = swap_final ? tmp0_valid[0] : tmp1_valid;
  end

  always_ff @(posedge clock) begin
    for (int i = 0; i < LOAD_PIPE_W; i++) begin
      s1_valid[i] <= sorted_valid[i];
      rob_mmio_q[i] <= sorted_valid[i] & sorted_req[i].mmio;
      if (sorted_valid[i])
        rob_uop_rob_value_q[i] <= sorted_req[i].uop_robIdx_value;
      if (sorted_valid[i])
        s2_req[i] <= sorted_req[i];
    end

    redirect_d1.valid <= io_redirect_valid;
    if (io_redirect_valid) begin
      redirect_d1.robIdx.flag  <= io_redirect_bits_robIdx_flag;
      redirect_d1.robIdx.value <= io_redirect_bits_robIdx_value;
      redirect_d1.level        <= io_redirect_bits_level;
      redirect_d1.isRVC        <= 1'b0;
      redirect_d1.ftq_flag     <= 1'b0;
      redirect_d1.ftq_value    <= '0;
      redirect_d1.ftqOffset    <= '0;
    end
    redirect_d2.valid <= redirect_d1.valid;
    if (redirect_d1.valid) begin
      redirect_d2.robIdx.flag  <= redirect_d1.robIdx.flag;
      redirect_d2.robIdx.value <= redirect_d1.robIdx.value;
      redirect_d2.level        <= redirect_d1.level;
      redirect_d2.isRVC        <= 1'b0;
      redirect_d2.ftq_flag     <= 1'b0;
      redirect_d2.ftq_value    <= '0;
      redirect_d2.ftqOffset    <= '0;
    end
  end

  always_comb begin
    for (int i = 0; i < LOAD_PIPE_W; i++) begin
      s2_valid_q[i] =
        s1_valid[i]
        & ~rob_need_flush(s2_req[i].uop_robIdx_flag, s2_req[i].uop_robIdx_value,
                          redirect_d1.valid, redirect_d1.robIdx.flag,
                          redirect_d1.robIdx.value, redirect_d1.level)
        & ~rob_need_flush(s2_req[i].uop_robIdx_flag, s2_req[i].uop_robIdx_value,
                          io_redirect_valid, io_redirect_bits_robIdx_flag,
                          io_redirect_bits_robIdx_value, io_redirect_bits_level);

      // 只有真正需要走 Uncache 的 load 才占槽；已有异常或需要 replay 的 load 由主流水处理。
      s2_enqueue[i] = s2_valid_q[i]
                    & ~has_load_exception(s2_req[i])
                    & ~need_replay(s2_req[i])
                    & (s2_req[i].mmio | s2_req[i].nc);
    end
  end

  always_comb begin
    logic [1:0] offset;
    for (int i = 0; i < LOAD_PIPE_W; i++) begin
      offset = 2'd0;
      for (int j = 0; j < i; j++)
        offset += {1'b0, s2_enqueue[j]};
      s2_enq_accept[i] = s2_enqueue[i] & alloc_can_by_offset(free_can_allocate, offset);
      s2_alloc_slot[i] = alloc_slot_by_offset(free_alloc_slot[0], free_alloc_slot[1],
                                              free_alloc_slot[2], offset);
    end
  end

  always_comb begin
    for (int e = 0; e < ENTRY_NUM; e++) begin
      entry_req_valid[e] = 1'b0;
      // golden 对 entry req payload 的黑盒输入不按 valid 清零：默认暴露 lane0，
      // lane1/lane2 命中该槽时再覆盖。这个三元链保留 X offset 的收敛语义。
      entry_req_bits[e]  =
        (s2_enq_accept[2] & (s2_alloc_slot[2] == ENTRY_IDX_W'(e))) ? s2_req[2] :
        (s2_enq_accept[1] & (s2_alloc_slot[1] == ENTRY_IDX_W'(e))) ? s2_req[1] :
                                                                       s2_req[0];
      for (int w = 0; w < LOAD_PIPE_W; w++) begin
        entry_req_valid[e] |= s2_enq_accept[w] & (s2_alloc_slot[w] == ENTRY_IDX_W'(e));
      end
    end
  end

  // ===========================================================================
  //  §2  Uncache Transaction：MMIO 优先，NC 由 RRArbiter 轮转
  // ===========================================================================
  logic           any_mmio_selected;
  logic [ENTRY_IDX_W-1:0] mmio_idx;
  lqu_unc_req_t  mmio_req_bits;
  logic          mmio_req_valid;

  always_comb begin
    any_mmio_selected = 1'b0;
    mmio_idx          = '0;
    mmio_req_bits     = zero_unc_req();
    mmio_req_valid    = 1'b0;

    // Scala entries.foreach 中后面的 entry 会覆盖前面的 mmioReq，因此最高下标优先。
    for (int e = 0; e < ENTRY_NUM; e++) begin
      if (entry_mmio_select[e]) begin
        any_mmio_selected = 1'b1;
        mmio_idx          = ENTRY_IDX_W'(e);
        mmio_req_bits     = entry_unc_req[e];
        mmio_req_valid    = entry_unc_valid[e];
      end
    end

    for (int e = 0; e < ENTRY_NUM; e++) begin
      nc_req_valid[e] = ~entry_mmio_select[e] & entry_unc_valid[e];
      nc_req_bits[e]  = entry_unc_req[e];
      entry_unc_req_ready[e] = entry_mmio_select[e] ? (any_mmio_selected & unc_pipe_in_ready)
                                                    : nc_req_ready[e];
    end

    nc_arb_ready      = ~any_mmio_selected & unc_pipe_in_ready;
    unc_pipe_in_valid = any_mmio_selected ? mmio_req_valid : nc_arb_valid;
    unc_pipe_in_bits  = any_mmio_selected ? mmio_req_bits  : nc_arb_bits;
    unc_pipe_in_bits.cmd  = 5'h0;  // LoadQueueUncache 只发 load Get，entry 内也固定 M_XRD。
    unc_pipe_in_bits.data = 64'h0;
    unc_pipe_in_bits.id   = any_mmio_selected ? {5'b0, mmio_idx} : nc_arb_bits.id;
  end

  // idResp 用 mid 回送给发起该请求的 entry；resp 用 entry 保存的 slaveId/sid 匹配。
  always_comb begin
    for (int e = 0; e < ENTRY_NUM; e++) begin
      entry_id_valid[e]   = io_uncache_idResp_valid
                          & (io_uncache_idResp_bits_mid == {5'b0, ENTRY_IDX_W'(e)});
      entry_resp_valid[e] = io_uncache_resp_valid
                          & entry_slave_valid[e]
                          & (entry_slave_id[e] == io_uncache_resp_bits_id);
    end
  end

  // ===========================================================================
  //  §3  Writeback：MMIO 固定端口 2，NC 按 NCWBPorts={1,2} 分奇偶组
  // ===========================================================================
  lqu_entry_sel_t        mmio_wb_sel;
  logic                  mmio_wb_fire;
  lqu_nc_rem_e           nc_rem_even, nc_rem_odd;

  always_comb begin
    mmio_wb_sel          = '0;
    mmio_pipe_in_bits    = zero_mmio_out();
    mmio_raw_sel         = '0;

    for (int e = 0; e < ENTRY_NUM; e++) begin
      entry_mmio_ready[e] = entry_mmio_select[e] & mmio_pipe_in_ready;
      if (entry_mmio_select[e]) begin
        mmio_wb_sel.valid = entry_mmio_valid[e];
        mmio_wb_sel.idx   = ENTRY_IDX_W'(e);
        mmio_pipe_in_bits = entry_mmio_out[e];
        mmio_raw_sel      = entry_raw[e];
      end
    end
    mmio_pipe_in_valid = mmio_wb_sel.valid;
    mmio_wb_fire       = mmio_pipe_in_valid & mmio_pipe_in_ready;
  end

  always_ff @(posedge clock) begin
    if (mmio_wb_fire)
      mmio_raw_q <= mmio_raw_sel;
  end

  function automatic logic [ENTRY_IDX_W-1:0] pick_pair(input logic v0, input logic v1,
                                                       input logic [ENTRY_IDX_W-1:0] i0,
                                                       input logic [ENTRY_IDX_W-1:0] i1);
    return v0 ? i0 : i1;
  endfunction

  logic rem0_has_nc, rem1_has_nc;
  logic [ENTRY_IDX_W-1:0] rem0_idx, rem1_idx;
  logic rem0_not_mmio, rem1_not_mmio;

  always_comb begin
    nc_pipe_empty_valid = 1'b0;
    nc_pipe_empty_bits  = zero_nc_out();

    // SubVec.getMaskRem(ncOutValidVec, 2) 把 entry0/2 送到 ncOut(1)，
    // entry1/3 送到 ncOut(2)。这里按 PriorityEncoderWithFlag 展开，不用
    // array[可能为X的idx]，否则 valid 中的 X 会把 freelist 释放路径污染掉。
    nc_rem_even  = NC_REM_EVEN;
    nc_rem_odd   = NC_REM_ODD;
    rem0_has_nc  = entry_nc_valid[0] | entry_nc_valid[2];
    rem1_has_nc  = entry_nc_valid[1] | entry_nc_valid[3];
    rem0_idx     = pick_pair(entry_nc_valid[0], entry_nc_valid[2], 2'd0, 2'd2);
    rem1_idx     = pick_pair(entry_nc_valid[1], entry_nc_valid[3], 2'd1, 2'd3);
    rem0_not_mmio = entry_nc_valid[0] ? ~entry_mmio_select[0] : ~entry_mmio_select[2];
    rem1_not_mmio = entry_nc_valid[1] ? ~entry_mmio_select[1] : ~entry_mmio_select[3];

    nc_pipe_even_valid = rem0_has_nc & rem0_not_mmio;
    nc_pipe_even_bits  = entry_nc_valid[0] ? entry_nc_out[0] : entry_nc_out[2];
    nc_pipe_odd_valid  = rem1_has_nc & rem1_not_mmio;
    nc_pipe_odd_bits   = entry_nc_valid[1] ? entry_nc_out[1] : entry_nc_out[3];

    entry_nc_ready[0] = ~entry_mmio_select[0] & rem0_has_nc & (rem0_idx == 2'd0) & nc_pipe_even_ready;
    entry_nc_ready[1] = ~entry_mmio_select[1] & rem1_has_nc & (rem1_idx == 2'd1) & nc_pipe_odd_ready;
    entry_nc_ready[2] = ~entry_mmio_select[2] & rem0_has_nc & (rem0_idx == 2'd2) & nc_pipe_even_ready;
    entry_nc_ready[3] = ~entry_mmio_select[3] & rem1_has_nc & (rem1_idx == 2'd3) & nc_pipe_odd_ready;
  end

  // ===========================================================================
  //  §4  Deallocate 与异常汇聚
  // ===========================================================================
  always_comb begin
    for (int e = 0; e < ENTRY_NUM; e++) begin
      free_mask[e] =
        (known_one(entry_mmio_select[e]) & known_one(entry_mmio_valid[e]) & known_one(entry_mmio_ready[e]))
        | (known_one(entry_nc_valid[e]) & known_one(entry_nc_ready[e]))
        | known_one(entry_flush[e]);
    end
  end

  always_comb begin
    exception_valid_sel = 1'b0;
    // golden 的 ParallelPriorityMux 在全 invalid 时仍暴露最后一路 payload。有效位仍为 0，
    // 但 UT 逐位比较全部输出，因此这里保留同样的默认可见值。
    exception_sel = entry_exception[3];

    // ParallelPriorityMux：低下标 entry 更老，异常上报取第一路 valid。
    for (int e = ENTRY_NUM-1; e >= 0; e--) begin
      if (entry_exception_valid[e]) begin
        exception_valid_sel = 1'b1;
        exception_sel = entry_exception[e];
      end
    end
  end

  assign io_exception_valid = exception_valid_sel;
  assign io_exception_bits_uop_exceptionVec_3  = exception_sel.uop_exceptionVec_3;
  assign io_exception_bits_uop_exceptionVec_4  = exception_sel.uop_exceptionVec_4;
  assign io_exception_bits_uop_exceptionVec_5  = exception_sel.uop_exceptionVec_5;
  assign io_exception_bits_uop_exceptionVec_13 = exception_sel.uop_exceptionVec_13;
  assign io_exception_bits_uop_exceptionVec_19 = exception_sel.uop_exceptionVec_19;
  assign io_exception_bits_uop_exceptionVec_21 = exception_sel.uop_exceptionVec_21;
  assign io_exception_bits_uop_uopIdx          = exception_sel.uop_uopIdx;
  assign io_exception_bits_uop_robIdx_flag     = exception_sel.uop_robIdx_flag;
  assign io_exception_bits_uop_robIdx_value    = exception_sel.uop_robIdx_value;
  assign io_exception_bits_fullva              = exception_sel.fullva;
  assign io_exception_bits_gpaddr              = exception_sel.gpaddr;
  assign io_exception_bits_isHyper             = exception_sel.isHyper;
  assign io_exception_bits_isForVSnonLeafPTE   = exception_sel.isForVSnonLeafPTE;

  // ===========================================================================
  //  §5  Rollback：槽满时选择最老失败请求，延迟一拍向前端发 redirect
  // ===========================================================================
  logic req_need_check[LOAD_PIPE_W];
  logic oldest_onehot[LOAD_PIPE_W];
  lqu_redirect_t oldest_redirect;

  always_comb begin
    for (int i = 0; i < LOAD_PIPE_W; i++)
      req_need_check[i] = s2_enqueue[i] & ~s2_enq_accept[i];

    for (int i = 0; i < LOAD_PIPE_W; i++) begin
      oldest_onehot[i] = req_need_check[i];
      for (int j = 0; j < LOAD_PIPE_W; j++) begin
        if (j < i)
          oldest_onehot[i] &= ~req_need_check[j]
                            | rob_is_after(req_robidx(s2_req[j]), req_robidx(s2_req[i]));
        else if (j > i)
          oldest_onehot[i] &= ~req_need_check[j]
                            | ~rob_is_after(req_robidx(s2_req[i]), req_robidx(s2_req[j]));
      end
    end

    oldest_redirect = '0;
    for (int i = 0; i < LOAD_PIPE_W; i++) begin
      if (oldest_onehot[i]) begin
        // Chisel Mux1H 对 payload 是逐位 OR；即使 ROB 环形边界让多个候选同时
        // 满足 onehot 条件，也要保留这个 OR 语义。
        oldest_redirect.valid        |= req_need_check[i];
        oldest_redirect.isRVC        |= s2_req[i].uop_preDecodeInfo_isRVC;
        oldest_redirect.robIdx.flag  |= s2_req[i].uop_robIdx_flag;
        oldest_redirect.robIdx.value |= s2_req[i].uop_robIdx_value;
        oldest_redirect.ftq_flag     |= s2_req[i].uop_ftqPtr_flag;
        oldest_redirect.ftq_value    |= s2_req[i].uop_ftqPtr_value;
        oldest_redirect.ftqOffset    |= s2_req[i].uop_ftqOffset;
        oldest_redirect.level        |= 1'b1; // RedirectLevel.flush
      end
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      rollback_valid_d <= 1'b0;
    end else begin
      rollback_valid_d <= oldest_redirect.valid
        & ~rob_need_flush(oldest_redirect.robIdx.flag, oldest_redirect.robIdx.value,
                          io_redirect_valid, io_redirect_bits_robIdx_flag,
                          io_redirect_bits_robIdx_value, io_redirect_bits_level)
        & ~rob_need_flush(oldest_redirect.robIdx.flag, oldest_redirect.robIdx.value,
                          redirect_d1.valid, redirect_d1.robIdx.flag,
                          redirect_d1.robIdx.value, redirect_d1.level)
        & ~rob_need_flush(oldest_redirect.robIdx.flag, oldest_redirect.robIdx.value,
                          redirect_d2.valid, redirect_d2.robIdx.flag,
                          redirect_d2.robIdx.value, redirect_d2.level);
    end
  end

  always_ff @(posedge clock) begin
    if (oldest_redirect.valid)
      rollback_bits_d <= oldest_redirect;
  end

  assign io_rollback_valid = rollback_valid_d;
  assign io_rollback_bits_isRVC = rollback_bits_d.isRVC;
  assign io_rollback_bits_robIdx_flag = rollback_bits_d.robIdx.flag;
  assign io_rollback_bits_robIdx_value = rollback_bits_d.robIdx.value;
  assign io_rollback_bits_ftqIdx_flag = rollback_bits_d.ftq_flag;
  assign io_rollback_bits_ftqIdx_value = rollback_bits_d.ftq_value;
  assign io_rollback_bits_ftqOffset = rollback_bits_d.ftqOffset;
  assign io_rollback_bits_level = rollback_bits_d.level;

endmodule
