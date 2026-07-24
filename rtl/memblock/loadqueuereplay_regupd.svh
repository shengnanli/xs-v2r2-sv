// §5  entry 寄存器统一更新
// -----------------------------------------------------------------------------
//  优先级（与 Scala 的 when 顺序一致，后写覆盖前写）：
//   1) 默认保持
//   2) blocking 清除（§2 的 blkClear，含 hint 唤醒）
//   3) s0→s1 选中 → scheduled := 1（s0_can_go & s0_oldestSel.valid & 命中该 entry）
//   4) 入队写入（needEnqueue & ready）→ allocated/scheduled/blocking/cause/uop/...
//   5) isLoadReplay 回流且不再需重放 → allocated:=0,free；否则 scheduled:=0
//   6) vec 取消 / redirect 取消 → allocated:=0,free（最高优先，在 §6）
//
//  本节用一个 entry 数组的 always_ff，逐 entry 求 next 值。

  // s0 选中标记（72 位）：任一路 s0_can_go & s0_oldestSel.valid & one-hot 命中 i
  logic [LQ_REPLAY_SIZE-1:0] s0_setScheduled;
  always_comb begin
    s0_setScheduled = '0;
    for (int r = 0; r < LD_PIPE_W; r++)
      if (s0_can_go[r] & s0_oldestSel_valid[r])
        s0_setScheduled |= s0_oldestSel_bits[r];
  end


  // ---- vaddr 写：needEnqueue 的口写入其 enqIndex ----
  always_comb begin
    for (int w = 0; w < LD_PIPE_W; w++) begin
      va_wen[w]   = newEnqueue[w] | (needEnqueue[w] & enq_isLoadReplay[w]);
      // golden: vaddrModule.io.wen(w) := needEnqueue(w)（无论是否 isLoadReplay 都重写）
      va_wen[w]   = needEnqueue[w];
      va_waddr[w] = enqIndex[w];
      va_wdata[w] = enq_vaddr[w];
    end
  end

  // ---- needCancel：被 redirect 刷的 allocated entry（§6 用，这里先算）----
  logic [LQ_REPLAY_SIZE-1:0] needCancel, vecLdCancel, vecLdCommit;
  always_comb begin
    for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin
      logic vc, vm;
      needCancel[i] = ent[i].allocated &
        rob_need_flush(uop[i].robIdx.flag, uop[i].robIdx.value,
                       redirect_valid, redirect_robIdx.flag, redirect_robIdx.value, redirect_level);
      // 向量取消/提交：merge buffer flush/commit 命中本 entry 的 robIdx+uopIdx
      vc = 1'b0; vm = 1'b0;
      for (int j = 0; j < VEC_PIPE_W; j++) begin
        if (ent[i].allocated & vecFb_valid[j] & vecFb_isFlush[j]
            & (uop[i].robIdx == vecFb_robIdx[j]) & (uop[i].uopIdx == vecFb_uopIdx[j])) vc = 1'b1;
        if (ent[i].allocated & vecFb_valid[j] & vecFb_isCommit[j]
            & (uop[i].robIdx == vecFb_robIdx[j]) & (uop[i].uopIdx == vecFb_uopIdx[j])) vm = 1'b1;
      end
      vecLdCancel[i] = vc;
      vecLdCommit[i] = vm;
    end
  end

  // ---- entry 寄存器更新 ----
  // ---- uop/vecReplay：golden 为**无复位**寄存器（写在独立无复位 always 块），必须
  //      与下面 reset 门控的块分开——否则复位期间的 enqueue 写会被吞掉，与 golden 分叉
  //      （StoreQueue 同型问题，FM analyze_points 实证 reset 只出现在 impl 锥）。
  //      选口逻辑与 (4) 完全一致：needEnqueue & enqIndex 命中，高口覆盖。
  logic     entry_ne_v   [LQ_REPLAY_SIZE];
  lqr_uop_t entry_ne_uop [LQ_REPLAY_SIZE];
  lqr_vec_t entry_ne_vec [LQ_REPLAY_SIZE];
  logic     entry_bsq_v  [LQ_REPLAY_SIZE];   // blockSqIdx 亦为无复位寄存器（C_MA/C_FF 门控）
  sq_ptr_t  entry_bsq    [LQ_REPLAY_SIZE];
  always_comb
    for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin
      entry_ne_v[i] = 1'b0; entry_ne_uop[i] = '0; entry_ne_vec[i] = '0;
      entry_bsq_v[i] = 1'b0; entry_bsq[i] = '0;
      for (int w = 0; w < LD_PIPE_W; w++)
        if (needEnqueue[w] & (enqIndex[w] == i[SCHED_IDX_W-1:0])) begin
          entry_ne_v[i]   = 1'b1;
          entry_ne_uop[i] = enq_uop[w];   // full 结构（存储时只寄 golden 存的那些位/字段，见下 always_ff）
          entry_ne_vec[i] = enq_vec[w];
          if (enq_cause[w][C_MA]) begin entry_bsq_v[i] = 1'b1; entry_bsq[i] = enq_addr_inv_sq_idx[w]; end
          if (enq_cause[w][C_FF]) begin entry_bsq_v[i] = 1'b1; entry_bsq[i] = enq_data_inv_sq_idx[w]; end
        end
    end
  // uop/vecReplay/blockSqIdx 为**无复位**寄存器(golden 无复位)：仅 @(posedge clock)。
  // ★不能带 `or posedge reset` 却无 if(reset)首语句——FMR_VLOG-144 拒绝→impl 无法 elaborate
  //   (FM 判 impl top set 失败, 整个 LQR FM 一直无效)。★
  // ★★per-entry uop/vecReplay 只寄 **golden 存的那些位/字段**，其余位/字段**不驱动**
  //   （悬空 net → FM 前端剪除，不计 unread_impl；sim 中为 X 但从不读→无功能影响）。这样：
  //    - exceptionVec 只寄 19 个 golden 存的 bit（丢 {3,4,5,13,21}），且 bit 名/位与 golden
  //      uop_N_exceptionVec_K 逐位对齐(auto-match 直接配对，无需 remap pin)；
  //    - loadWaitStrict 不寄（golden 用它在入队算 strict_N 后即丢）；
  //    - vecReplay 只寄 golden 存的 9 字段，丢 {isLastElem,is_first_ele,uop_unit_stride_fof,
  //      usSecondInv}。★★
  //  EXC_KEEP（pkg 定义）= golden 逐 entry 存的 exceptionVec bit 集合（1=存）。
  always_ff @(posedge clock)
    for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin
      if (entry_ne_v[i]) begin
        // exceptionVec：逐位仅寄 golden 存的位（其余位悬空）
        for (int b = 0; b < 24; b++)
          if (EXC_KEEP[b]) uop[i].exceptionVec[b] <= entry_ne_uop[i].exceptionVec[b];
        // 其余 golden 存的标量/向量字段照常寄（不含 loadWaitStrict）
        uop[i].preDecodeInfo_isRVC <= entry_ne_uop[i].preDecodeInfo_isRVC;
        uop[i].ftqPtr_flag         <= entry_ne_uop[i].ftqPtr_flag;
        uop[i].ftqPtr_value        <= entry_ne_uop[i].ftqPtr_value;
        uop[i].ftqOffset           <= entry_ne_uop[i].ftqOffset;
        uop[i].fuOpType            <= entry_ne_uop[i].fuOpType;
        uop[i].rfWen               <= entry_ne_uop[i].rfWen;
        uop[i].fpWen               <= entry_ne_uop[i].fpWen;
        uop[i].vpu_vstart          <= entry_ne_uop[i].vpu_vstart;
        uop[i].vpu_veew            <= entry_ne_uop[i].vpu_veew;
        uop[i].uopIdx              <= entry_ne_uop[i].uopIdx;
        uop[i].pdest               <= entry_ne_uop[i].pdest;
        uop[i].robIdx              <= entry_ne_uop[i].robIdx;
        uop[i].dbg_enqRsTime       <= entry_ne_uop[i].dbg_enqRsTime;
        uop[i].dbg_selectTime      <= entry_ne_uop[i].dbg_selectTime;
        uop[i].dbg_issueTime       <= entry_ne_uop[i].dbg_issueTime;
        uop[i].storeSetHit         <= entry_ne_uop[i].storeSetHit;
        uop[i].waitForRobIdx_flag  <= entry_ne_uop[i].waitForRobIdx_flag;
        uop[i].waitForRobIdx_value <= entry_ne_uop[i].waitForRobIdx_value;
        uop[i].loadWaitBit         <= entry_ne_uop[i].loadWaitBit;
        // uop[i].loadWaitStrict 不驱动（golden 不逐 entry 存）
        uop[i].lqIdx               <= entry_ne_uop[i].lqIdx;
        uop[i].sqIdx               <= entry_ne_uop[i].sqIdx;
        // vecReplay：只寄 golden 存的 9 字段（其余 4 字段悬空）
        vecReplay[i].isvec           <= entry_ne_vec[i].isvec;
        vecReplay[i].is128bit        <= entry_ne_vec[i].is128bit;
        vecReplay[i].elemIdx         <= entry_ne_vec[i].elemIdx;
        vecReplay[i].alignedType     <= entry_ne_vec[i].alignedType;
        vecReplay[i].mbIndex         <= entry_ne_vec[i].mbIndex;
        vecReplay[i].elemIdxInsideVd <= entry_ne_vec[i].elemIdxInsideVd;
        vecReplay[i].reg_offset      <= entry_ne_vec[i].reg_offset;
        vecReplay[i].vecActive       <= entry_ne_vec[i].vecActive;
        vecReplay[i].mask            <= entry_ne_vec[i].mask;
        // vecReplay[i].{isLastElem,is_first_ele,uop_unit_stride_fof,usSecondInv} 不驱动
      end
      if (entry_bsq_v[i]) blockSqIdx[i] <= entry_bsq[i];
    end

  // §4-comb 的组合结果信号（声明须在下方 always_ff 读之前；驱动 always_comb 见文件末）。
  logic                  entry_wr_hasNE   [LQ_REPLAY_SIZE];
  logic [N_CAUSES-1:0]   entry_wr_cause   [LQ_REPLAY_SIZE];
  logic [VADDR_BITS-1:0] entry_wr_vaddr   [LQ_REPLAY_SIZE];
  logic                  entry_wr_dilb    [LQ_REPLAY_SIZE];
  logic                  entry_wr_blk     [LQ_REPLAY_SIZE];
  logic                  entry_wr_strict  [LQ_REPLAY_SIZE];
  logic                  entry_wr_hasMSHR [LQ_REPLAY_SIZE];
  logic [MSHR_ST_W-1:0]  entry_wr_mshr    [LQ_REPLAY_SIZE];   // 5 位存储值（4 位端口零扩展）
  logic                  entry_wr_hasTLB  [LQ_REPLAY_SIZE];
  logic [TLB_ST_W-1:0]   entry_wr_tlb     [LQ_REPLAY_SIZE];   // 5 位存储值（4 位端口零扩展）
  logic                  entry_wr_alloc_touched [LQ_REPLAY_SIZE];
  logic                  entry_wr_alloc_n       [LQ_REPLAY_SIZE];
  logic                  entry_wr_sched_clr     [LQ_REPLAY_SIZE];

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      // 与 Scala 一致：allocated/scheduled/blocking/strict/cause + missMSHRId/tlbHintId/
      // dataInLastBeat 都是 RegInit(0)，复位清零（否则未写过的 entry 被重放时读出 X）。
      //  循环到真实深度 LQ_REPLAY_SIZE=72（与 golden 逐条 entry 寄存器一一对应，无 padding 死槽）。
      for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin
        ent[i].allocated <= 1'b0;
        ent[i].scheduled <= 1'b0;
        ent[i].blocking  <= 1'b0;
        ent[i].strict    <= 1'b0;
        cause[i]         <= '0;
        missMSHRId[i]    <= '0;
        tlbHintId[i]     <= '0;
        dataInLastBeat[i]<= 1'b0;
        debug_vaddr[i]   <= '0;   // golden debug_vaddr_N <= 50'h0（原实现漏复位→全 72 项与 golden 分叉）
      end
    end else begin
      for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin
        // (2) blocking 默认取 §2 的优先级解除结果 blkNext（不入队时的下一拍值）
        ent[i].blocking <= blkNext[i];
        // (3) s0 选中 → scheduled
        if (s0_setScheduled[i]) ent[i].scheduled <= 1'b1;
      end

      // (4) 入队写入 —— 各字段的「下一拍值 + 写使能」在 §4-comb 的 always_comb 里算好
      //     （见下方 entry_wr_* 组合信号）。这里 always_ff 只做纯寄存器写，绝不在 always_ff
      //     体内声明 blocking 赋值的组合临时量——否则 FM 前端会把每个 generate/循环迭代的
      //     临时量各推成一个死寄存器（nUop_reg72/nCause_reg72/hit_reg… 数千 unread_impl 伪影）。
      for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin
        if (entry_wr_hasNE[i]) begin
          cause[i]          <= entry_wr_cause[i];
          debug_vaddr[i]    <= entry_wr_vaddr[i];
          dataInLastBeat[i] <= entry_wr_dilb[i];
          ent[i].blocking   <= entry_wr_blk[i];
          ent[i].strict     <= entry_wr_strict[i];
        end
        if (entry_wr_hasMSHR[i]) missMSHRId[i] <= entry_wr_mshr[i];   // 否则保持旧值
        if (entry_wr_hasTLB[i])  tlbHintId[i]  <= entry_wr_tlb[i];
        // blockSqIdx 移至上方无复位块（golden 无复位寄存器）
      end

      // (4b) allocated/scheduled 的逐口交错更新（写使能/次态在 §4-comb 算好）。
      for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin
        if (entry_wr_alloc_touched[i]) ent[i].allocated <= entry_wr_alloc_n[i];
        // scheduled：step(3) 已可能置 1；这里若被 enqueue/replay 触及则清 0（后写覆盖）
        if (entry_wr_sched_clr[i])     ent[i].scheduled <= 1'b0;
      end

      // (6) redirect / vec 取消（最高优先：覆盖以上对 allocated 的写）
      for (int i = 0; i < LQ_REPLAY_SIZE; i++)
        if (needCancel[i]) ent[i].allocated <= 1'b0;
    end
  end

  // ---------------------------------------------------------------------------
  //  §4-comb  入队字段的「下一拍值 + 写使能」组合计算（从 always_ff 移出，消死寄存器伪影）
  // ---------------------------------------------------------------------------
  //  ⚠ 关键陷阱（多口命中同一 entry）：isLoadReplay 的 schedIndex 由上游驱动，理论上
  //   不同口不会撞同一个 index，但**逐字段的写使能门控不同**，Scala 为每个字段独立生成
  //   优先级 mux（口 2 > 口 1 > 口 0，即 zipWithIndex 的「后写覆盖」），且各字段的
  //   「该口是否写本字段」门控也不同：
  //     - allocated/scheduled/uop/vec/cause/debug_vaddr/dataInLastBeat/blocking/strict
  //       : 门控 = needEnqueue[w]
  //     - missMSHRId : 门控 = needEnqueue[w] & handledByMSHR[w]（仅 MSHR 处理过才更新）
  //     - tlbHintId  : 门控 = needEnqueue[w] & cause[w][C_TM]
  //   若把所有字段塞进同一个「按口 last-wins」循环，会让高编号口的「保持(keep)」误把
  //   低编号口对**它本不写的字段**（如 missMSHRId 在 hb=0 时）的写覆盖掉 → 读出旧值不一致。
  //   故这里逐 entry、逐字段按各自门控求最高优先级口（口 2→1→0）。
  //  （entry_wr_* 信号声明已上移至 always_ff 之前。）
  always_comb begin
    for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin
      // 普通/条件字段（口升序扫描，命中即覆盖=高口赢）
      entry_wr_hasNE[i]   = 1'b0; entry_wr_hasMSHR[i] = 1'b0; entry_wr_hasTLB[i] = 1'b0;
      entry_wr_cause[i]='0; entry_wr_vaddr[i]='0; entry_wr_dilb[i]=1'b0;
      entry_wr_blk[i]=1'b0; entry_wr_strict[i]=1'b0; entry_wr_mshr[i]='0; entry_wr_tlb[i]='0;
      // allocated/scheduled 的逐口交错（enqueue 与 isLoadReplay 回流同一循环体，后写覆盖）
      entry_wr_alloc_touched[i] = 1'b0;
      entry_wr_alloc_n[i]       = 1'bx;
      entry_wr_sched_clr[i]     = 1'b0;
      for (int w = 0; w < LD_PIPE_W; w++) begin
        logic hit;
        logic [N_CAUSES-1:0] cw;
        hit = needEnqueue[w] & (enqIndex[w] == i[SCHED_IDX_W-1:0]);
        cw  = enq_cause[w];
        if (hit) begin
          entry_wr_hasNE[i]  = 1'b1;
          entry_wr_cause[i]  = cw;
          entry_wr_vaddr[i]  = enq_vaddr[w];
          entry_wr_dilb[i]   = enq_last_beat[w];
          // blocking 初值：默认 1；BC/NK/DR/WF 下拍即可重放→0；C_TM/C_DM 特判
          entry_wr_blk[i] = 1'b1;
          if (cw[C_BC] | cw[C_NK] | cw[C_DR] | cw[C_WF]) entry_wr_blk[i] = 1'b0;
          if (cw[C_TM])
            entry_wr_blk[i] = ~enq_tlb_full[w]
                 & ~(tlb_hint_valid & ((tlb_hint_id == enq_tlb_id[w]) | tlb_hint_replay_all));
          if (cw[C_DM] & enq_handledByMSHR[w])
            entry_wr_blk[i] = ~enq_full_fwd[w] & ~(tl_d_valid & (tl_d_mshrid == enq_mshr_id[w]));
          entry_wr_strict[i] = cw[C_MA] ? enq_uop[w].loadWaitStrict : 1'b0;
          // missMSHRId（门控=needEnqueue & handledByMSHR）；4 位端口零扩展到 5 位存储（golden {1'h0,..}）
          if (enq_handledByMSHR[w]) begin entry_wr_hasMSHR[i] = 1'b1; entry_wr_mshr[i] = {1'b0, enq_mshr_id[w]}; end
          // tlbHintId（门控=needEnqueue & C_TM）；4 位端口零扩展到 5 位存储
          if (cw[C_TM])             begin entry_wr_hasTLB[i]  = 1'b1; entry_wr_tlb[i]  = {1'b0, enq_tlb_id[w]}; end
          // allocated:=1, scheduled:=0
          entry_wr_alloc_n[i] = 1'b1; entry_wr_alloc_touched[i] = 1'b1;
          entry_wr_sched_clr[i] = 1'b1;
        end
        // isLoadReplay 回流（valid 且 isLoadReplay 且命中 schedIndex i）
        //  ⚠ Scala 把 enqueue 置位与 isLoadReplay 回流放同一个 for((enq,w)) 循环体（enqueue
        //   在前、replay 在后），故真实先后是 w=0:{enq,replay}, w=1:{enq,replay}, …（后写覆盖）。
        //   绝不能拆成「先所有 enqueue 再所有 replay」——否则低口 replay-free 误覆盖高口 enqueue-set。
        if (enq_valid[w] & enq_isLoadReplay[w] & (enq_schedIndex[w] == i[SCHED_IDX_W-1:0])) begin
          if (~needReplay[w] | hasExceptions[w]) begin
            entry_wr_alloc_n[i] = 1'b0; entry_wr_alloc_touched[i] = 1'b1;   // 释放
          end else begin
            entry_wr_sched_clr[i] = 1'b1;                                    // 仅清 scheduled
          end
        end
      end
    end
  end

  // ---- freeMaskVec：本拍要释放回 freelist 的槽 ----
  //  redirect 取消 | isLoadReplay 回流且不再需重放。
  always_comb begin
    freeMaskVec = '0;
    for (int i = 0; i < LQ_REPLAY_SIZE; i++)
      if (needCancel[i]) freeMaskVec[i] = 1'b1;
    for (int w = 0; w < LD_PIPE_W; w++)
      if (enq_valid[w] & enq_isLoadReplay[w] & (~needReplay[w] | hasExceptions[w]))
        freeMaskVec[enq_schedIndex[w]] = 1'b1;
  end
