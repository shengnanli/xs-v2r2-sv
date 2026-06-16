// =============================================================================
//  storequeue_regupd.svh —— §UNI 统一寄存器更新（ent[]/uop[]/多根指针）
//   Chisel 同源里这些更新分散在多个 when 块，后写覆盖前写。这里在一个 always_ff 里
//   按相同的源顺序优先级合并：enq → addr 写回 → addr 写回 s2 → data 写回 → mask
//   → commit → deq 清除 → mmio/nc/cbo completed → vecMbCommit → needCancel 取消。
//   （注：data/mask/addr 的「存储」在黑盒子模块；这里只更新控制状态位与 uop 元数据。）
// =============================================================================

  always_ff @(posedge clock) begin
    if (reset) begin
      // 所有 entry 状态位都是 RegInit(false)：复位清 0（含 memBackTypeMM/nc/mmio 等，
      // 否则 uncache 路读未分配 entry 的 memBackTypeMM 会是 X）。
      for (int i = 0; i < SQ_SIZE; i++) ent[i] <= '0;
    end else begin
      // ---- (0) 出队推进：清 allocated/completed（必须在 enq 之前，使同拍 enq 覆盖
      //          deq-clear——与 Scala 源 when 顺序一致：deq(L353) 在 enq(L404) 之前）----
      if (readyDeqVec[0]) begin
        ent[deqPtrExt[0].value].allocated <= 1'b0;
        ent[deqPtrExt[0].value].completed <= 1'b0;
      end
      if (readyDeqVec[0] & readyDeqVec[1]) begin
        ent[deqPtrExt[1].value].allocated <= 1'b0;
        ent[deqPtrExt[1].value].completed <= 1'b0;
      end

      // ---- (1) dispatch 入队（§4 组合好的 entryEnq）----
      for (int i = 0; i < SQ_SIZE; i++) begin
        if (entryEnq[i]) begin
          ent[i].allocated   <= 1'b1;
          ent[i].completed   <= 1'b0;
          ent[i].datavalid   <= 1'b0;
          ent[i].addrvalid   <= 1'b0;
          ent[i].unaligned   <= 1'b0;
          ent[i].cross16Byte <= 1'b0;
          ent[i].committed   <= 1'b0;
          ent[i].pending     <= 1'b0;
          ent[i].prefetch    <= 1'b0;
          ent[i].nc          <= 1'b0;
          ent[i].mmio        <= 1'b0;
          ent[i].isVec       <= entryEnqIsVec[i];
          ent[i].vecMbCommit <= 1'b0;
          ent[i].hasException<= 1'b0;
          ent[i].waitStoreS2 <= 1'b1;
          ent[i].vecLastFlow <= entryEnqLastFlow[i];
          uop[i]             <= entryEnqUop[i];
        end
      end

      // ---- (2)(3) StoreUnit 写回地址：s1(storeAddrIn) + s2(storeAddrInFireReg)
      //   ⚠ 必须**按端口交错**：port0_s1 → port0_s2 → port1_s1 → port1_s2，与 Scala
      //   `for(i){ s1; s2 }` 的展开顺序一致。否则当同一拍 port1_s1 和 port0_s2 写同一
      //   entry 的 addrvalid 时优先级会反，导致 addrvalid 残留（store miss 未清）。
      // -- port 0 s1 --
      if (sta0_fire & io_storeAddrIn_0_bits_updateAddrValid) begin
        ent[io_storeAddrIn_0_bits_uop_sqIdx_value].addrvalid <= ~io_storeAddrIn_0_bits_miss;
        ent[io_storeAddrIn_0_bits_uop_sqIdx_value].nc        <= io_storeAddrIn_0_bits_nc;
      end
      if (sta0_fire & ~io_storeAddrIn_0_bits_isFrmMisAlignBuf) begin
        ent[io_storeAddrIn_0_bits_uop_sqIdx_value].unaligned   <= io_storeAddrIn_0_bits_isMisalign;
        ent[io_storeAddrIn_0_bits_uop_sqIdx_value].cross16Byte <= io_storeAddrIn_0_bits_isMisalign & ~io_storeAddrIn_0_bits_misalignWith16Byte;
      end
      if (sta0_fire) begin
        uop[io_storeAddrIn_0_bits_uop_sqIdx_value].robIdx_flag   <= io_storeAddrIn_0_bits_uop_robIdx_flag;
        uop[io_storeAddrIn_0_bits_uop_sqIdx_value].robIdx_value  <= io_storeAddrIn_0_bits_uop_robIdx_value;
        uop[io_storeAddrIn_0_bits_uop_sqIdx_value].uopIdx        <= io_storeAddrIn_0_bits_uop_uopIdx;
        uop[io_storeAddrIn_0_bits_uop_sqIdx_value].fuOpType      <= io_storeAddrIn_0_bits_uop_fuOpType;
        uop[io_storeAddrIn_0_bits_uop_sqIdx_value].trigger       <= io_storeAddrIn_0_bits_uop_trigger;
        uop[io_storeAddrIn_0_bits_uop_sqIdx_value].dbg_enqRsTime <= io_storeAddrIn_0_bits_uop_debugInfo_enqRsTime;
        uop[io_storeAddrIn_0_bits_uop_sqIdx_value].dbg_selectTime<= io_storeAddrIn_0_bits_uop_debugInfo_selectTime;
        uop[io_storeAddrIn_0_bits_uop_sqIdx_value].dbg_issueTime <= io_storeAddrIn_0_bits_uop_debugInfo_issueTime;
      end
      // -- port 0 s2 --
      if (sta0_reFire) begin
        ent[sta0_wbIdxReg_q].pending       <= io_storeAddrInRe_0_mmio;
        ent[sta0_wbIdxReg_q].mmio          <= io_storeAddrInRe_0_mmio;
        ent[sta0_wbIdxReg_q].memBackTypeMM <= io_storeAddrInRe_0_memBackTypeMM;
        ent[sta0_wbIdxReg_q].hasException  <= io_storeAddrInRe_0_hasException;
        ent[sta0_wbIdxReg_q].addrvalid     <= ent[sta0_wbIdxReg_q].addrvalid | io_storeAddrInRe_0_hasException;
        ent[sta0_wbIdxReg_q].waitStoreS2   <= 1'b0;
        // 注：本配置 EnableAtCommitMissTrigger=false，prefetch 不由 miss 驱动（golden 无该寄存器）。
      end
      // -- port 1 s1 --
      if (sta1_fire & io_storeAddrIn_1_bits_updateAddrValid) begin
        ent[io_storeAddrIn_1_bits_uop_sqIdx_value].addrvalid <= ~io_storeAddrIn_1_bits_miss;
        ent[io_storeAddrIn_1_bits_uop_sqIdx_value].nc        <= io_storeAddrIn_1_bits_nc;
      end
      if (sta1_fire & ~io_storeAddrIn_1_bits_isFrmMisAlignBuf) begin
        ent[io_storeAddrIn_1_bits_uop_sqIdx_value].unaligned   <= io_storeAddrIn_1_bits_isMisalign;
        ent[io_storeAddrIn_1_bits_uop_sqIdx_value].cross16Byte <= io_storeAddrIn_1_bits_isMisalign & ~io_storeAddrIn_1_bits_misalignWith16Byte;
      end
      if (sta1_fire) begin
        uop[io_storeAddrIn_1_bits_uop_sqIdx_value].robIdx_flag   <= io_storeAddrIn_1_bits_uop_robIdx_flag;
        uop[io_storeAddrIn_1_bits_uop_sqIdx_value].robIdx_value  <= io_storeAddrIn_1_bits_uop_robIdx_value;
        uop[io_storeAddrIn_1_bits_uop_sqIdx_value].uopIdx        <= io_storeAddrIn_1_bits_uop_uopIdx;
        uop[io_storeAddrIn_1_bits_uop_sqIdx_value].fuOpType      <= io_storeAddrIn_1_bits_uop_fuOpType;
        uop[io_storeAddrIn_1_bits_uop_sqIdx_value].trigger       <= io_storeAddrIn_1_bits_uop_trigger;
        uop[io_storeAddrIn_1_bits_uop_sqIdx_value].dbg_enqRsTime <= io_storeAddrIn_1_bits_uop_debugInfo_enqRsTime;
        uop[io_storeAddrIn_1_bits_uop_sqIdx_value].dbg_selectTime<= io_storeAddrIn_1_bits_uop_debugInfo_selectTime;
        uop[io_storeAddrIn_1_bits_uop_sqIdx_value].dbg_issueTime <= io_storeAddrIn_1_bits_uop_debugInfo_issueTime;
      end
      // -- port 1 s2 --
      if (sta1_reFire) begin
        ent[sta1_wbIdxReg_q].pending       <= io_storeAddrInRe_1_mmio;
        ent[sta1_wbIdxReg_q].mmio          <= io_storeAddrInRe_1_mmio;
        ent[sta1_wbIdxReg_q].memBackTypeMM <= io_storeAddrInRe_1_memBackTypeMM;
        ent[sta1_wbIdxReg_q].hasException  <= io_storeAddrInRe_1_hasException;
        ent[sta1_wbIdxReg_q].addrvalid     <= ent[sta1_wbIdxReg_q].addrvalid | io_storeAddrInRe_1_hasException;
        ent[sta1_wbIdxReg_q].waitStoreS2   <= 1'b0;
      end

      // ---- (4) StoreData 写回数据 s1：置 datavalid（RegNext(fire) & allocated）----
      if (std0_fireReg_q & ent[std0_wbIdxReg_q].allocated) ent[std0_wbIdxReg_q].datavalid <= 1'b1;
      if (std1_fireReg_q & ent[std1_wbIdxReg_q].allocated) ent[std1_wbIdxReg_q].datavalid <= 1'b1;

      // ---- (5) ROB 提交：置 committed ----
      for (int i = 0; i < COMMIT_W; i++) begin
        if (commitEntPtr_committed[i]) ent[commitPtrIdx[i]].committed <= 1'b1;
        // nc & hasException & isCommit → completed（提前出队，不进 Sbuffer）
        if (commitEntPtr_committed[i] & ent[commitPtrIdx[i]].nc & ent[commitPtrIdx[i]].hasException)
          ent[commitPtrIdx[i]].completed <= 1'b1;
      end

      // ---- (7) 出队动作完成 → 置 completed ----
      // mmio 写回 ROB / vec mmio：completed(deqPtr)
      if (mmioStout_fire | vecmmioStout_fire) ent[deqPtr].completed <= 1'b1;
      // nc 完成：completed(ncPtr)
      if (ncDeqTrig) ent[ncPtr[SQ_IDX_W-1:0]].completed <= 1'b1;
      // Sbuffer fire 且需 deq：completed(sqPtr)
      if (sbuffer0_fire & db_deq_0_bits_sqNeedDeq) ent[db_deq_0_bits_sqPtr_value].completed <= 1'b1;
      if (sbuffer1_fire & db_deq_1_bits_sqNeedDeq) ent[db_deq_1_bits_sqPtr_value].completed <= 1'b1;
      // mmioDoReq：清 pending(deqPtr)
      if (mmioDoReq) ent[deqPtr].pending <= 1'b0;

      // ---- (8) 向量 vecMbCommit：vecCommit 命中 / 跨页同 uop ----
      for (int i = 0; i < SQ_SIZE; i++) begin
        if (vecCommit[i]) ent[i].vecMbCommit <= 1'b1;
      end
      if (io_maControl_toStoreQueue_withSameUop
          & (ent[rdataPtrExt[0].value].addrvalid & ent[rdataPtrExt[0].value].datavalid))
        ent[rdataPtrExt[0].value].vecMbCommit <= 1'b1;

      // ---- (9) redirect 取消：清 allocated/completed（最高优先级，最后写）----
      for (int i = 0; i < SQ_SIZE; i++) begin
        if (needCancel[i]) begin
          ent[i].allocated <= 1'b0;
          ent[i].completed <= 1'b0;
        end
      end
    end
  end

  // ===========================================================================
  //  多根指针更新（独立 always_ff，不与 ent/uop 冲突）
  // ===========================================================================
  // enqPtr：2 拍后 redirect 回滚 redirectCancelCount，否则 +enqNumber。
  //   与 golden 逐位一致的环形指针算术：先在 9 位里算 value+delta，再用「减 56、
  //   按符号决定是否回卷 + flag 翻转」收敛。回滚 delta = (56 - cancelCount)（8 位回卷，
  //   故 cancelCount 可大于 56 也能正确 mod；这是随机 UT 对齐 golden 的关键）。
  always_ff @(posedge clock) begin
    if (reset) begin
      for (int j = 0; j < ENQ_W; j++) enqPtrExt[j] <= '{flag:1'b0, value:j[SQ_IDX_W-1:0]};
    end else if (lastlastCycleRedirect_q) begin
      // 回滚：delta = 56 - redirectCancelCount（8 位回卷）；flag = rev ^ ~oldflag
      for (int j = 0; j < ENQ_W; j++) begin
        logic [7:0] delta; logic [8:0] nv; logic [9:0] diff; logic rev;
        delta = 8'h38 - redirectCancelCount_q;
        nv    = {3'b0, enqPtrExt[j].value} + {1'b0, delta};
        diff  = {1'b0, nv} - 10'h38;
        rev   = ~diff[9];
        enqPtrExt[j].value <= rev ? diff[5:0] : nv[5:0];
        enqPtrExt[j].flag  <= rev ^ ~enqPtrExt[j].flag;
      end
    end else begin
      // 正常 +enqNumber：flag = rev ^ oldflag
      for (int j = 0; j < ENQ_W; j++) begin
        logic [8:0] nv; logic [9:0] diff; logic rev;
        nv    = {3'b0, enqPtrExt[j].value} + {1'b0, enqNumber};
        diff  = {1'b0, nv} - 10'h38;
        rev   = ~diff[9];
        enqPtrExt[j].value <= rev ? diff[5:0] : nv[5:0];
        enqPtrExt[j].flag  <= rev ^ enqPtrExt[j].flag;
      end
    end
  end
  // rdataPtr / deqPtr
  always_ff @(posedge clock) begin
    if (reset) begin
      for (int j = 0; j < ENSB_W; j++) begin
        rdataPtrExt[j] <= '{flag:1'b0, value:j[SQ_IDX_W-1:0]};
        deqPtrExt[j]   <= '{flag:1'b0, value:j[SQ_IDX_W-1:0]};
      end
    end else begin
      for (int j = 0; j < ENSB_W; j++) begin
        rdataPtrExt[j] <= rdataPtrExtNext[j];
        deqPtrExt[j]   <= deqPtrExtNext[j];
      end
    end
  end
  // cmtPtr：+commitCount
  always_ff @(posedge clock) begin
    if (reset) for (int j = 0; j < COMMIT_W; j++) cmtPtrExt[j] <= '{flag:1'b0, value:j[SQ_IDX_W-1:0]};
    else       for (int j = 0; j < COMMIT_W; j++) cmtPtrExt[j] <= sqptr_add(cmtPtrExt[j], {3'b0, commitCount});
  end
