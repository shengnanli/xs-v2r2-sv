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
  always_ff @(posedge clock) begin
    if (reset) begin
      // 与 Scala 一致：allocated/scheduled/blocking/strict/cause + missMSHRId/tlbHintId/
      // dataInLastBeat 都是 RegInit(0)，复位清零（否则未写过的 entry 被重放时读出 X）。
      //  循环到 LQ_SLOTS（含 77..127 padding 槽）一并清 0，保证任何下标读出都不为 X。
      for (int i = 0; i < LQ_SLOTS; i++) begin
        ent[i].allocated <= 1'b0;
        ent[i].scheduled <= 1'b0;
        ent[i].blocking  <= 1'b0;
        ent[i].strict    <= 1'b0;
        cause[i]         <= '0;
        missMSHRId[i]    <= '0;
        tlbHintId[i]     <= '0;
        dataInLastBeat[i]<= 1'b0;
      end
    end else begin
      for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin
        // (2) blocking 默认取 §2 的优先级解除结果 blkNext（不入队时的下一拍值）
        ent[i].blocking <= blkNext[i];
        // (3) s0 选中 → scheduled
        if (s0_setScheduled[i]) ent[i].scheduled <= 1'b1;
      end

      // (4) 入队写入。
      //  ⚠ 关键陷阱（多口命中同一 entry）：isLoadReplay 的 schedIndex 由上游驱动，理论上
      //   不同口不会撞同一个 index，但**逐字段的写使能门控不同**，Scala 为每个字段独立生成
      //   优先级 mux（口 2 > 口 1 > 口 0，即 zipWithIndex 的「后写覆盖」），且各字段的
      //   「该口是否写本字段」门控也不同：
      //     - allocated/scheduled/uop/vec/cause/debug_vaddr/dataInLastBeat/blocking/strict
      //       : 门控 = needEnqueue[w]
      //     - missMSHRId : 门控 = needEnqueue[w] & handledByMSHR[w]（仅 MSHR 处理过才更新）
      //     - tlbHintId  : 门控 = needEnqueue[w] & cause[w][C_TM]
      //     - blockSqIdx : C_MA 写 addr_inv、C_FF 写 data_inv（两次独立 when，C_FF 后写赢）
      //   若把所有字段塞进同一个「按口 last-wins」循环，会让高编号口的「保持(keep)」误把
      //   低编号口对**它本不写的字段**（如 missMSHRId 在 hb=0 时）的写覆盖掉 → 读出旧值不一致。
      //   故这里逐 entry、逐字段按各自门控求最高优先级口（口 2→1→0）。
      //  实现说明：用「按口 w=0..2 升序扫描、命中即覆盖」的方式选最高优先级口（口 2 最高，
      //   后写覆盖前写），每个字段用各自的命中门控独立判断「本口是否写本字段」（不写则不
      //   覆盖，避免 keep 误清）。全程只用循环变量 w（受 LD_PIPE_W 约束）索引输入数组，
      //   不用动态 int 下标索引（对 Formality 友好，避免 out-of-bound elab 误报）。
      for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin
        // 各字段的「下一拍值 + 是否被写」累积量（按口扫描，命中即覆盖）
        logic                  hasNE;                  // 本 entry 被某口 enqueue
        logic [N_CAUSES-1:0]   nCause;
        lqr_uop_t              nUop;
        lqr_vec_t              nVec;
        logic [VADDR_BITS-1:0] nVaddr;
        logic                  nDilb, nBlk, nStrict;
        logic                  hasMSHR;  logic [MSHR_ID_W-1:0] nMshr;
        logic                  hasTLB;   logic [TLB_ID_W-1:0]  nTlb;
        logic                  hasBSQ;   sq_ptr_t              nBsq;
        hasNE = 1'b0; hasMSHR = 1'b0; hasTLB = 1'b0; hasBSQ = 1'b0;
        nCause='0; nUop='0; nVec='0; nVaddr='0; nDilb=1'b0; nBlk=1'b0; nStrict=1'b0;
        nMshr='0; nTlb='0; nBsq='0;
        for (int w = 0; w < LD_PIPE_W; w++) begin
          logic hit;
          logic [N_CAUSES-1:0] cw;
          hit = needEnqueue[w] & (enqIndex[w] == i[SCHED_IDX_W-1:0]);
          cw  = enq_cause[w];
          if (hit) begin
            // ---- enqueue 写的「普通字段」（门控=needEnqueue），高口覆盖 ----
            hasNE  = 1'b1;
            nCause = cw;
            nUop   = enq_uop[w];
            nVec   = enq_vec[w];
            nVaddr = enq_vaddr[w];
            nDilb  = enq_last_beat[w];
            // blocking 初值：默认 1；BC/NK/DR/WF 下拍即可重放→0；C_TM/C_DM 特判
            nBlk = 1'b1;
            if (cw[C_BC] | cw[C_NK] | cw[C_DR] | cw[C_WF]) nBlk = 1'b0;
            if (cw[C_TM])
              nBlk = ~enq_tlb_full[w]
                   & ~(tlb_hint_valid & ((tlb_hint_id == enq_tlb_id[w]) | tlb_hint_replay_all));
            if (cw[C_DM] & enq_handledByMSHR[w])
              nBlk = ~enq_full_fwd[w] & ~(tl_d_valid & (tl_d_mshrid == enq_mshr_id[w]));
            nStrict = cw[C_MA] ? enq_uop[w].loadWaitStrict : 1'b0;
            // ---- missMSHRId（门控=needEnqueue & handledByMSHR）----
            if (enq_handledByMSHR[w]) begin hasMSHR = 1'b1; nMshr = enq_mshr_id[w]; end
            // ---- tlbHintId（门控=needEnqueue & C_TM）----
            if (cw[C_TM])           begin hasTLB  = 1'b1; nTlb  = enq_tlb_id[w]; end
            // ---- blockSqIdx（口内 C_FF 后写覆盖 C_MA；跨口高口覆盖）----
            if (cw[C_MA]) begin hasBSQ = 1'b1; nBsq = enq_addr_inv_sq_idx[w]; end
            if (cw[C_FF]) begin hasBSQ = 1'b1; nBsq = enq_data_inv_sq_idx[w]; end
          end
        end
        // 注：allocated/scheduled 与 isLoadReplay 回流逐口交错，统一在下方 (4b) 处理。
        if (hasNE) begin
          uop[i]            <= nUop;
          vecReplay[i]      <= nVec;
          cause[i]          <= nCause;
          debug_vaddr[i]    <= nVaddr;
          dataInLastBeat[i] <= nDilb;
          ent[i].blocking   <= nBlk;
          ent[i].strict     <= nStrict;
        end
        if (hasMSHR) missMSHRId[i] <= nMshr;   // 否则保持旧值
        if (hasTLB)  tlbHintId[i]  <= nTlb;
        if (hasBSQ)  blockSqIdx[i] <= nBsq;
      end

      // (4b) allocated/scheduled 的逐口交错更新。
      //  ⚠ Scala 把「enqueue 置位」与「isLoadReplay 回流释放/清 scheduled」放在**同一个**
      //   `for((enq,w))` 循环体内（enqueue 在前、isLoadReplay 在后），故真实先后是：
      //     w=0:{enq, replay}, w=1:{enq, replay}, w=2:{enq, replay}（后写覆盖前写）。
      //   绝不能拆成「先所有 enqueue，再所有 replay」——那会让低编号口的 replay-free 错误地
      //   覆盖高编号口的 enqueue-set（本例：口2 enqueue 置某 entry=1，口1 replay-free 同
      //   entry，正确结果应是口2 的 set 赢=1；若先 set 后 free 则错成 0）。
      //   这里对每 entry 按 w=0..2 顺序施加 set/clear，自然实现「同 entry 后写赢」。
      for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin
        logic alloc_n, sched_set0;
        logic alloc_touched, sched_touched0;
        alloc_touched = 1'b0; sched_touched0 = 1'b0;
        alloc_n = 1'bx; sched_set0 = 1'b0;
        for (int w = 0; w < LD_PIPE_W; w++) begin
          // enqueue 置位（needEnqueue 且命中 i）
          if (needEnqueue[w] & (enqIndex[w] == i[SCHED_IDX_W-1:0])) begin
            alloc_n = 1'b1; alloc_touched = 1'b1;   // allocated:=1
            sched_set0 = 1'b1; sched_touched0 = 1'b1; // scheduled:=0
          end
          // isLoadReplay 回流（valid 且 isLoadReplay 且命中 schedIndex i）
          if (enq_valid[w] & enq_isLoadReplay[w] & (enq_schedIndex[w] == i[SCHED_IDX_W-1:0])) begin
            if (~needReplay[w] | hasExceptions[w]) begin
              alloc_n = 1'b0; alloc_touched = 1'b1;     // 释放
            end else begin
              sched_set0 = 1'b1; sched_touched0 = 1'b1; // 仅清 scheduled
            end
          end
        end
        if (alloc_touched)  ent[i].allocated <= alloc_n;
        // scheduled：step(3) 已可能置 1；这里若被 enqueue/replay 触及则清 0（后写覆盖）
        if (sched_touched0) ent[i].scheduled <= 1'b0;
      end

      // (6) redirect / vec 取消（最高优先：覆盖以上对 allocated 的写）
      for (int i = 0; i < LQ_REPLAY_SIZE; i++)
        if (needCancel[i]) ent[i].allocated <= 1'b0;
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
