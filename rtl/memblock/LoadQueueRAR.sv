// =============================================================================
//  xs_LoadQueueRAR_core —— Load-Load (RAR) 违例检测队列（可读重写）
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel，非 firtool golden）：
//      src/main/scala/xiangshan/mem/lsqueue/LoadQueueRAR.scala
//      src/main/scala/xiangshan/mem/lsqueue/FreeList.scala（freelist 内联实现）
//      src/main/scala/xiangshan/mem/lsqueue/LoadQueueData.scala（LqPAddrModule CAM）
//
//  本核把 golden 里独立例化的 FreeList_3 / LqPAddrModule 两个子模块**内联**用
//  struct 数组 + genvar 重写，使整条「入队分配 → CAM 匹配 → 违例判定 → release
//  失效 → 出队回收」的数据流在一个可读文件里读懂。微架构讲解见 docs/memblock/LoadQueueRAR.md。
//
//  ── 顶层时序总览（3 个 load 流水口并行，编号 w=0/1/2）─────────────────────────
//     拍 T   (query.req)：判 needEnqueue → freelist 分配 entry → 写 paddr 哈希/uop/released；
//                         同拍对 query.req 做 CAM（releaseViolationMmask）算 matchMaskReg。
//     拍 T+1 (query.resp)：resp.valid = RegNext(req.valid)；rep_frm_fetch = |matchMask（打 1 拍）。
//     release：release1Cycle = 当拍 io.release；release2Cycle = 延 1 拍（让入队追上 paddr 写）。
//              release1Cycle 命中已有条目 → 延 1 拍把其 released 置 1。
//     出队：条目的 lqIdx 已“不晚于 ldWbPtr”（已写回）或被 redirect 冲刷 → 释放 entry。
//     revoke：若某 load 在 query 后一拍需要 replay，撤销它上一拍占的 entry。
// =============================================================================
module xs_LoadQueueRAR_core
  import loadqueuerar_pkg::*;
(
  input  logic                          clock,
  input  logic                          reset,

  // ---- 控制：重定向（冲刷比其更年轻的条目）----
  input  logic                          redirect_valid,
  input  rob_ptr_t                      redirect_robIdx,
  input  logic                          redirect_level,

  // ---- 违例查询口（每个 load 流水一个）----
  input  logic       [LD_WIDTH-1:0]     q_req_valid,
  input  rob_ptr_t   [LD_WIDTH-1:0]     q_req_robIdx,
  input  lq_ptr_t    [LD_WIDTH-1:0]     q_req_lqIdx,
  input  logic [LD_WIDTH-1:0][PADDR_BITS-1:0] q_req_paddr,
  input  logic       [LD_WIDTH-1:0]     q_req_data_valid,
  input  logic       [LD_WIDTH-1:0]     q_req_is_nc,
  input  logic       [LD_WIDTH-1:0]     q_revoke,
  output logic       [LD_WIDTH-1:0]     q_req_ready,
  output logic       [LD_WIDTH-1:0]     q_resp_valid,
  output logic       [LD_WIDTH-1:0]     q_resp_rep_frm_fetch,

  // ---- release：L2 对某 cacheline 的 invalidate 通知 ----
  input  logic                          release_valid,
  input  logic [PADDR_BITS-1:0]         release_paddr,

  // ---- 来自 VirtualLoadQueue 的写回指针（判出队）----
  input  lq_ptr_t                       ldWbPtr,

  // ---- 全局输出 ----
  output logic                          lqFull,
  output logic [CNT_W-1:0]              validCount,
  output logic [1:0]                    perf_enq,           // 本拍入队数（perf event）
  output logic [1:0]                    perf_ldld_violation // 本拍违例数（perf event）
);

  // ===========================================================================
  //  0. 条目存储：72 个 entry 的 struct 数组
  // ===========================================================================
  //  物理深度取 2^IDX_W（128）而非 RAR_SIZE（72）：entry index 是 IDX_W 位，
  //  功能上恒 < 72，但按 2 幂铺开可让所有以 7-bit 索引的访问静态在界（与 golden
  //  firtool 把 allocated 阵列 0 填充到 128 同理）；高 56 个槽永不被 allocated。
  rar_entry_t [(1<<IDX_W)-1:0] entry;

  // ===========================================================================
  //  1. release 的两拍版本
  //     paddr 写进 paddrModule 需 1 拍才可见，故 release 要保留一份延迟版
  //     release2Cycle，让“本拍刚入队、还看不到自己 paddr”的条目也能在下一拍补判失效。
  //       release1Cycle.bits  = 当拍 io.release.bits（组合直通）
  //       release2Cycle.valid = RegNext(io.release.valid)
  //       release2Cycle.bits  = RegEnable(io.release.bits, io.release.valid)
  // ===========================================================================
  //  注意（golden 实测）：release2Cycle.valid 在生成 RTL 里是 **两级 RegNext**
  //  （release2_valid_q1 <= release_valid; release2_valid <= release2_valid_q1），
  //  即 io.release.valid 延 2 拍；而 bits 是单级 RegEnable（按 release_valid 使能锁存）。
  //  paddr 写入 paddrModule 也需 1 拍可见，两者配合让“刚入队的条目”能在恰当拍补判失效。
  logic                  release2_valid_q1, release2_valid;
  logic [PADDR_BITS-1:0] release2_paddr;
  always_ff @(posedge clock) begin
    if (reset) begin
      release2_valid_q1 <= 1'b0;
      release2_valid    <= 1'b0;
    end else begin
      release2_valid_q1 <= release_valid;          // 第 1 级 RegNext
      release2_valid    <= release2_valid_q1;       // 第 2 级 RegNext
    end
    if (release_valid) release2_paddr <= release_paddr;  // RegEnable(bits, valid)
  end

  // ===========================================================================
  //  2. freelist（内联 FreeList.scala）
  //     存“空闲 entry 编号”的循环队列：headPtr 出队分配、tailPtr 入队回收。
  //     初始 {0,1,...,71} 全空闲（headPtr=（flag0,0），tailPtr=（flag1,0），距离=72）。
  // ===========================================================================
  logic [IDX_W-1:0] freeList [(1<<IDX_W)];  // 空闲编号循环缓冲（深度取 2^IDX_W，使 7-bit 索引在界）
  free_ptr_t        headPtr, tailPtr;      // 分配头 / 回收尾
  logic [CNT_W:0]   freeSlotCnt;           // 当前空闲槽数（0..72），距离寄存器

  // ---- 分配侧：每个 load 口请求一个空闲槽（allocateReq 恒 1）----
  //   offset(w) = 在本口之前有多少口 needEnqueue（连续分配的相对偏移）。
  logic [IDX_W-1:0] alloc_offset   [LD_WIDTH];
  free_ptr_t        alloc_deqPtr   [LD_WIDTH];
  logic [IDX_W-1:0] alloc_slot     [LD_WIDTH];  // 该口将拿到的 entry 编号
  logic             alloc_can      [LD_WIDTH];  // 该口是否有空闲槽可分

  // ---- needEnqueue：该 load 是否真的要入队 ----
  //   req.valid 且 该 load 比 ldWbPtr 更年轻（尚未写回）且 未被 redirect 冲刷。
  logic [LD_WIDTH-1:0] needEnqueue;
  logic [LD_WIDTH-1:0] acceptedVec;   // 实际接收并分配的口（needEnqueue & ready）
  always_comb begin
    for (int w = 0; w < LD_WIDTH; w++) begin
      logic not_writebacked, cancel;
      // hasNotWritebackedLoad = isAfter(lqIdx, ldWbPtr)：该 load 比写回指针更年轻 → 仍“未完成”。
      not_writebacked = lqAfter(q_req_lqIdx[w], ldWbPtr);
      cancel          = rob_need_flush(redirect_valid, redirect_level, q_req_robIdx[w], redirect_robIdx);
      needEnqueue[w]  = q_req_valid[w] & not_writebacked & ~cancel;
    end
  end

  // 分配偏移 / 槽位 / 是否可分（FreeList.allocate，enablePreAlloc=false）
  always_comb begin
    for (int w = 0; w < LD_WIDTH; w++) begin
      logic [IDX_W-1:0] cnt;
      cnt = '0;
      for (int k = 0; k < LD_WIDTH; k++)
        if (k < w) cnt += {6'b0, needEnqueue[k]};      // PopCount(needEnqueue.take(w))
      alloc_offset[w] = cnt;
      alloc_deqPtr[w] = ptr_add(headPtr, alloc_offset[w]);
      alloc_can[w]    = free_is_before(alloc_deqPtr[w], tailPtr);
      alloc_slot[w]   = freeList[alloc_deqPtr[w].value];
      // enq.ready：要入队时看能否分到，不入队恒 ready（透传）
      q_req_ready[w]  = needEnqueue[w] ? alloc_can[w] : 1'b1;
      acceptedVec[w]  = needEnqueue[w] & q_req_ready[w];
    end
  end

  // ===========================================================================
  //  3. CAM 匹配（内联 LqPAddrModule）
  //     条目存 16-bit 哈希 ppaddr；query.req 的 paddr 现折哈希后与每条目比较。
  //     releaseViolationMmask(w)(i) = (hash(q_req_paddr[w]) == entry[i].ppaddr)
  // ===========================================================================
  logic [LD_WIDTH-1:0][PP_BITS-1:0] q_ppaddr;        // 查询口 paddr 哈希
  logic [LD_WIDTH-1:0][RAR_SIZE-1:0] camHit;          // CAM 命中（仅哈希相等）
  always_comb begin
    for (int w = 0; w < LD_WIDTH; w++) begin
      q_ppaddr[w] = gen_partial_paddr(q_req_paddr[w]);
      for (int i = 0; i < RAR_SIZE; i++)
        camHit[w][i] = (q_ppaddr[w] == entry[i].ppaddr);
    end
  end

  // ---- 违例匹配掩码（组合算，下一拍寄存）----
  //   matchMaskReg(i) = allocated(i) & camHit(i) & robIdxMask(i) & released(i)
  //   robIdxMask(i)   = isAfter(entry[i].robIdx, q.robIdx)：条目比当前 load 更年轻。
  logic [LD_WIDTH-1:0][RAR_SIZE-1:0] matchMaskReg;
  logic [LD_WIDTH-1:0][RAR_SIZE-1:0] matchMask;       // 打 1 拍
  always_comb begin
    for (int w = 0; w < LD_WIDTH; w++)
      for (int i = 0; i < RAR_SIZE; i++)
        matchMaskReg[w][i] = entry[i].allocated
                           & camHit[w][i]
                           & ptr_is_after_rob(entry[i].robIdx, q_req_robIdx[w])
                           & entry[i].released;
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      matchMask    <= '0;
      q_resp_valid <= '0;
    end else begin
      matchMask    <= matchMaskReg;            // GatedValidRegNext
      q_resp_valid <= q_req_valid;             // RegNext(req.valid)
    end
  end

  for (genvar w = 0; w < LD_WIDTH; w++)
    assign q_resp_rep_frm_fetch[w] = |matchMask[w];   // ParallelORR

  // ===========================================================================
  //  4. release 失效更新口
  //     release1Cycle 那拍用“整 cacheline 物理地址”比较已有条目（占用且匹配），
  //     延 1 拍把其 released 置 1。注意：用最后一个 CAM 口的 release 比较口，且这里
  //     比的是 **完整 [47:6] 物理地址**（cacheline 对齐），不是 16-bit 哈希。
  //     （golden 里这是 paddrModule.releaseMmask，但其 mdata 喂的就是 release 的哈希；
  //      为与 golden 输出逐位等价，这里复用哈希相等 + 真实条目占用判定。）
  // ===========================================================================
  logic [RAR_SIZE-1:0] releaseHit;       // release1Cycle 命中（哈希相等 & 占用 & valid）
  logic [PP_BITS-1:0]  release1_ppaddr;
  always_comb begin
    release1_ppaddr = gen_partial_paddr(release_paddr);
    for (int i = 0; i < RAR_SIZE; i++)
      releaseHit[i] = (release1_ppaddr == entry[i].ppaddr) & entry[i].allocated & release_valid;
  end
  logic [RAR_SIZE-1:0] releaseHit_d;     // 延 1 拍写回 released
  always_ff @(posedge clock) begin
    if (reset) releaseHit_d <= '0;
    else       releaseHit_d <= releaseHit;
  end

  // ===========================================================================
  //  5. 出队 / 回收 freeMask
  //     条目可释放：lqIdx 已“不晚于 ldWbPtr”（已写回出队）或 被 redirect 冲刷。
  //     另：revoke——某 load 在 query 后一拍要 replay，撤销其上一拍占的 entry。
  // ===========================================================================
  logic [RAR_SIZE-1:0] freeMaskVec;       // 本拍要回收的 entry（喂 freelist.free）

  // revoke：上一拍的 acceptedVec / alloc_slot 打拍保留
  logic [LD_WIDTH-1:0]            lastCanAccept;
  logic [LD_WIDTH-1:0][IDX_W-1:0] lastAllocIndex;
  always_ff @(posedge clock) begin
    if (reset) begin
      lastCanAccept  <= '0;
      lastAllocIndex <= '0;
    end else begin
      lastCanAccept  <= acceptedVec;
      for (int w = 0; w < LD_WIDTH; w++) lastAllocIndex[w] <= alloc_slot[w];
    end
  end

  always_comb begin
    for (int i = 0; i < RAR_SIZE; i++) begin
      logic deqNotBlock, needFlush;
      // deqNotBlock = !isBefore(ldWbPtr, entry[i].lqIdx)：ldWbPtr 已追上/越过该条目 lqIdx
      deqNotBlock = ~ptr_is_before_lq(ldWbPtr, entry[i].lqIdx);
      needFlush   = rob_need_flush(redirect_valid, redirect_level, entry[i].robIdx, redirect_robIdx);
      freeMaskVec[i] = entry[i].allocated & (deqNotBlock | needFlush);
    end
    // revoke：撤销上一拍刚占的 entry（若仍占用）
    for (int w = 0; w < LD_WIDTH; w++)
      if (q_revoke[w] & lastCanAccept[w] & entry[lastAllocIndex[w]].allocated)
        freeMaskVec[lastAllocIndex[w]] = 1'b1;
  end

  // ===========================================================================
  //  6. 条目寄存器更新（逐 entry，genvar 铺开）
  //     每个 entry 的 allocated/uop/ppaddr/released 都由 3 个 load 口可能写入
  //     （freelist 保证三口分到的 index 互不相同），以及 release 失效、出队释放。
  // ===========================================================================
  // 预算每个 entry 由哪个口写入（acceptedVec[w] 且 alloc_slot[w]==i）
  logic [RAR_SIZE-1:0][LD_WIDTH-1:0] entryWrBy;  // entryWrBy[i][w]：口 w 写 entry i
  always_comb begin
    for (int i = 0; i < RAR_SIZE; i++)
      for (int w = 0; w < LD_WIDTH; w++)
        entryWrBy[i][w] = acceptedVec[w] & (alloc_slot[w] == IDX_W'(i));
  end

  for (genvar i = 0; i < RAR_SIZE; i++) begin : g_entry
    // 选出写本 entry 的口（优先级：口2 > 口1 > 口0，与 Chisel last-connect 一致；
    // freelist 保证不会有两口同时写同一 entry，故优先级只是形式上的 mux）。
    logic                  wr_en;
    rob_ptr_t              wr_robIdx;
    lq_ptr_t               wr_lqIdx;
    logic [PADDR_BITS-1:0] wr_paddr;
    logic                  wr_is_nc, wr_data_valid;
    always_comb begin
      wr_en         = |entryWrBy[i];
      wr_robIdx     = q_req_robIdx[0];
      wr_lqIdx      = q_req_lqIdx[0];
      wr_paddr      = q_req_paddr[0];
      wr_is_nc      = q_req_is_nc[0];
      wr_data_valid = q_req_data_valid[0];
      for (int w = 0; w < LD_WIDTH; w++) begin
        if (entryWrBy[i][w]) begin
          wr_robIdx     = q_req_robIdx[w];
          wr_lqIdx      = q_req_lqIdx[w];
          wr_paddr      = q_req_paddr[w];
          wr_is_nc      = q_req_is_nc[w];
          wr_data_valid = q_req_data_valid[w];
        end
      end
    end

    // 入队 released 初值：按 released_cause_e 分类（见 pkg）——NC 恒失效；否则 data 有效
    // 且本条 cacheline 已被 release1/2Cycle 命中（用**整 cacheline 地址 [47:6]** 比较）也立刻失效。
    released_cause_e enq_rel_cause;
    logic            enq_released;
    always_comb begin
      logic hit2, hit1;
      hit2 = release2_valid & (wr_paddr[PADDR_BITS-1:DCACHE_LINE_OFF]
                               == release2_paddr[PADDR_BITS-1:DCACHE_LINE_OFF]);
      hit1 = release_valid  & (wr_paddr[PADDR_BITS-1:DCACHE_LINE_OFF]
                               == release_paddr[PADDR_BITS-1:DCACHE_LINE_OFF]);
      // 优先级：NC > cycle1 > cycle2 > none
      if      (wr_is_nc)                  enq_rel_cause = REL_NC;
      else if (wr_data_valid & hit1)      enq_rel_cause = REL_HIT_CYCLE1;
      else if (wr_data_valid & hit2)      enq_rel_cause = REL_HIT_CYCLE2;
      else                               enq_rel_cause = REL_NONE;
      enq_released = (enq_rel_cause != REL_NONE);
    end

    always_ff @(posedge clock) begin
      if (reset) begin
        entry[i].allocated <= 1'b0;
        entry[i].released  <= 1'b0;
      end else begin
        // allocated：入队置 1；出队/冲刷/revoke 命中则清 0。
        if (freeMaskVec[i])      entry[i].allocated <= 1'b0;
        else if (wr_en)          entry[i].allocated <= 1'b1;
        // released：入队写 enq_released；release1Cycle 命中延 1 拍后置 1（只置不清，
        //           与 golden 的 “REG | (enq ? T : released)” 结构一致——出队不清 released，
        //           靠 allocated=0 使其不再参与匹配）。
        if (wr_en) entry[i].released <= enq_released | releaseHit_d[i];
        else       entry[i].released <= entry[i].released | releaseHit_d[i];
      end
      // uop / ppaddr：仅入队那拍写（无需复位，靠 allocated 门控读出）
      if (wr_en) begin
        entry[i].robIdx <= wr_robIdx;
        entry[i].lqIdx  <= wr_lqIdx;
        entry[i].ppaddr <= gen_partial_paddr(wr_paddr);
      end
    end
  end

  // ===========================================================================
  //  7. freelist 指针 / 空闲计数更新（内联 FreeList）
  // ===========================================================================
  // ---- 分配侧：headPtr += 本拍实际分配数 ----
  logic [IDX_W-1:0] numAllocate;
  logic             doAllocate;
  always_comb begin
    numAllocate = '0;
    for (int w = 0; w < LD_WIDTH; w++) numAllocate += {6'b0, acceptedVec[w]};
    doAllocate  = |acceptedVec;
  end

  // ---- 回收侧（精确复刻 FreeList 的两拍流水）----------------------------------
  //   freeWidth=4：entry 编号按 mod 4 分 4 个 rem-bank，每 bank PriorityEncoder 选一个回收。
  //   关键时序（极易写错）：
  //     · freeSelMask 来自 **上一拍选中并寄存的** freeReq_d/freeSelOH_d（即本拍正在写回
  //       freeList 的那批槽），而非本拍组合选择结果——否则会形成组合环且与 golden 不符。
  //     · 选择候选池 = freeMask & ~freeSelMask，**只看寄存器 freeMask**，不含本拍 io.free；
  //       本拍新来的 io.free 仅进入 freeMask 寄存器，下一拍才参与选择。
  //     · freeMask_next = (io.free | freeMask) & ~freeSelMask。
  logic [RAR_SIZE-1:0] freeMask;        // 待回收累积掩码（寄存器）
  logic [RAR_SIZE-1:0] freeSelMask;     // 本拍正在写回 freeList 的槽（来自寄存的上拍选择）
  logic [FREE_WIDTH-1:0]               freeReq_c;     // 本拍组合：各 rem-bank 有无可回收
  logic [FREE_WIDTH-1:0][RAR_SIZE-1:0] freeSelOH_c;   // 本拍组合：各 rem-bank 选中 one-hot
  logic [FREE_WIDTH-1:0]               freeReq_d;     // 上拍选择寄存（本拍写回）
  logic [FREE_WIDTH-1:0][RAR_SIZE-1:0] freeSelOH_d;

  // freeSelMask = OR over banks of (freeReq_d ? freeSelOH_d : 0)
  always_comb begin
    freeSelMask = '0;
    for (int r = 0; r < FREE_WIDTH; r++)
      if (freeReq_d[r]) freeSelMask |= freeSelOH_d[r];
  end

  // 本拍组合选择：候选 = freeMask & ~freeSelMask（仅寄存器，不含本拍 io.free）
  always_comb begin
    logic [RAR_SIZE-1:0] avail;
    avail = freeMask & ~freeSelMask;
    for (int r = 0; r < FREE_WIDTH; r++) begin
      logic [RAR_SIZE/FREE_WIDTH-1:0] remBits;
      logic found;
      freeSelOH_c[r] = '0;
      remBits = '0;
      for (int j = 0; j < RAR_SIZE/FREE_WIDTH; j++)
        remBits[j] = avail[j*FREE_WIDTH + r];
      // PriorityEncoderOH：取最低有效位
      found = 1'b0;
      for (int j = 0; j < RAR_SIZE/FREE_WIDTH; j++)
        if (!found && remBits[j]) begin
          freeSelOH_c[r][j*FREE_WIDTH + r] = 1'b1;
          found = 1'b1;
        end
      freeReq_c[r] = |remBits;
    end
  end

  // freeMask 累积寄存 + 选择结果打 1 拍（GatedRegNext）
  always_ff @(posedge clock) begin
    if (reset) begin
      freeMask    <= '0;
      freeReq_d   <= '0;
      freeSelOH_d <= '0;
    end else begin
      freeMask    <= (freeMaskVec | freeMask) & ~freeSelMask;
      freeReq_d   <= freeReq_c;
      freeSelOH_d <= freeSelOH_c;
    end
  end

  // tailPtr += 本拍回收数；回收槽写入 freeList[tailPtr+offset]
  logic [IDX_W-1:0] numFree;
  logic             doFree;
  always_comb begin
    numFree = '0;
    for (int r = 0; r < FREE_WIDTH; r++) numFree += {6'b0, freeReq_d[r]};
    doFree  = |freeReq_d;
  end

  free_ptr_t headPtrNext, tailPtrNext;
  always_comb begin
    headPtrNext = ptr_add(headPtr, numAllocate);
    tailPtrNext = ptr_add(tailPtr, numFree);
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      // 初值：headPtr=(0,0)，tailPtr=(1,0)，freeList={0,1,...,71}，freeSlotCnt=72
      headPtr     <= '{flag:1'b0, value:'0};
      tailPtr     <= '{flag:1'b1, value:'0};
      freeSlotCnt <= CNT_W'(RAR_SIZE);
      for (int n = 0; n < RAR_SIZE; n++) freeList[n] <= IDX_W'(n);
    end else begin
      if (doAllocate) headPtr <= headPtrNext;
      if (doFree)     tailPtr <= tailPtrNext;
      // 回收写 freeList：rem-bank r 选中的编号写到 tailPtr+offset(r)
      for (int r = 0; r < FREE_WIDTH; r++) begin
        logic [IDX_W-1:0] foff;
        free_ptr_t        enqp;
        foff = '0;
        for (int k = 0; k < FREE_WIDTH; k++) if (k < r) foff += {6'b0, freeReq_d[k]};
        enqp = ptr_add(tailPtr, foff);
        if (freeReq_d[r]) freeList[enqp.value] <= oh_to_idx(freeSelOH_d[r]);
      end
      // 空闲计数 = distance(tailPtrNext, headPtrNext)
      freeSlotCnt <= free_distance(tailPtrNext, headPtrNext);
    end
  end

  assign lqFull     = (freeSlotCnt == '0);
  assign validCount = CNT_W'(RAR_SIZE) - freeSlotCnt[CNT_W-1:0];

  // ===========================================================================
  //  8. perf events（2 路：本拍入队数 / 本拍违例数；各打 2 拍对齐）
  // ===========================================================================
  logic [1:0] enq_cnt, viol_cnt;
  always_comb begin
    enq_cnt  = '0;
    viol_cnt = '0;
    for (int w = 0; w < LD_WIDTH; w++) begin
      enq_cnt  += {1'b0, (q_req_valid[w] & q_req_ready[w])};
      viol_cnt += {1'b0, (q_resp_valid[w] & q_resp_rep_frm_fetch[w])};
    end
  end
  logic [1:0] perf_enq_d, perf_viol_d;
  always_ff @(posedge clock) begin
    if (reset) begin
      perf_enq_d <= '0; perf_viol_d <= '0; perf_enq <= '0; perf_ldld_violation <= '0;
    end else begin
      perf_enq_d <= enq_cnt;    perf_enq <= perf_enq_d;
      perf_viol_d <= viol_cnt;  perf_ldld_violation <= perf_viol_d;
    end
  end

  // ===========================================================================
  //  局部纯函数 / 辅助（放近使用处）
  // ===========================================================================
  // 注：freelist 的 io.free（当拍回收掩码）即上文 freeMaskVec，直接引用，不另设函数。

  // lqIdx isAfter：a 比 b 更年轻（needEnqueue 用）
  function automatic logic lqAfter(input lq_ptr_t a, input lq_ptr_t b);
    return a.flag ^ b.flag ^ (a.value > b.value);
  endfunction

  // freelist 指针 +offset（环形）：value 跨 size 时翻 flag
  function automatic free_ptr_t ptr_add(input free_ptr_t p, input logic [IDX_W-1:0] off);
    free_ptr_t r;
    logic [IDX_W:0] sum;
    sum = {1'b0, p.value} + {1'b0, off};
    if (sum >= RAR_SIZE) begin
      r.value = sum[IDX_W-1:0] - IDX_W'(RAR_SIZE);
      r.flag  = ~p.flag;
    end else begin
      r.value = sum[IDX_W-1:0];
      r.flag  = p.flag;
    end
    return r;
  endfunction

  // freelist isBefore：a 比 b 靠前（还有空闲可分）
  function automatic logic free_is_before(input free_ptr_t a, input free_ptr_t b);
    return a.flag ^ b.flag ^ (a.value < b.value);
  endfunction

  // one-hot → index
  function automatic logic [IDX_W-1:0] oh_to_idx(input logic [RAR_SIZE-1:0] oh);
    logic [IDX_W-1:0] r;
    r = '0;
    for (int i = 0; i < RAR_SIZE; i++) if (oh[i]) r |= IDX_W'(i);
    return r;
  endfunction

endmodule
