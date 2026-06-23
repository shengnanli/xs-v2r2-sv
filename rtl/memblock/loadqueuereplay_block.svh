// §2  blocking 解除条件 → 计算「不入队时」下一拍 blocking 值 blkNext[i]
// -----------------------------------------------------------------------------
//  ⚠ 关键微架构语义（易错）：Scala 用一串 `when(cause(i)(C_x)){ blocking(i):=... }`
//  顺序覆盖同一个 blocking 寄存器，源码顺序 C_MA→C_TM→C_FF→C_DM→C_RAR→C_RAW→C_MF。
//  「后写覆盖前写」→ 生成 RTL 是一个**优先级 mux**：最高编码的活跃 cause 决定 blocking！
//  有效优先级（高→低）：C_MF(10) > C_RAW(8) > C_RAR(7) > C_DM(4) > C_FF(2) > C_TM(1) > C_MA(0)。
//  即：若 entry 同时挂多个 cause，只有**最高编码**那个的解除条件被检查（其余被覆盖）。
//  这与「任一 cause 解除即清」不同——务必用 priority，不能用 OR。
//
//  每个分支形如 `~(解除条件) & blocking`：解除条件满足→下拍 blocking=0，否则保持。
//  最外层再 AND `~hintWake`：L2 hint 唤醒命中则无条件清 blocking（最高优先）。
//
//  C_DR/C_WF/C_BC/C_NK 无解除分支（它们在入队时就已置 blocking=0，下拍即可重放）。

  // 按 sqIdx 读 StoreQueue 就绪向量（SQ_SIZE=56 非 2 的幂，6 位下标可能 56..63 越界）。
  //  ⚠ golden 把读端口展开成 64 深 _GEN：idx∈[0,55] 取真值，idx∈[56,63]（越界）**取 vec[0]**
  //  （chisel Vec(56) 在 idx>=56 时硬件回绕到 0 号元素的具体实现）。务必复刻此越界语义：
  //  越界返回 0 会让 C_FF/C_MA 的 blocking 解除晚一拍（当 blockSqIdx.value∈[56,63] 时），
  //  造成 replay 选择整拍相位差→顶层 io_replay_* 失配（实测 seed1 失配源头）。
  //  循环展开仍对 Formality 友好（消除非 2 幂动态下标 out-of-bound elab 误报）。
  function automatic logic sq_vec_read(input logic [SQ_SIZE-1:0] vec, input logic [SQ_IDX_W-1:0] idx);
    logic r;
    r = vec[0];   // 默认（含越界 idx>=SQ_SIZE）= vec[0]，与 golden _GEN/_GEN_0 越界回绕一致
    for (int k = 0; k < SQ_SIZE; k++) if (idx == k[SQ_IDX_W-1:0]) r = vec[k];
    return r;
  endfunction

  // store 地址/数据就绪向量（供 C_MA/C_FF 解除判定）
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
      staInSame[i] = sa;
      stdInSame[i] = sd;
      dataNotBlock[i] = sq_is_after(stDataReadySqPtr, blockSqIdx[i])
                        | sq_vec_read(stDataReadyVec, blockSqIdx[i].value) | sqEmpty;
      addrNotBlock[i] = sq_is_after(stAddrReadySqPtr, blockSqIdx[i])
                        | (~ent[i].strict & sq_vec_read(stAddrReadyVec, blockSqIdx[i].value)) | sqEmpty;
      // golden storeAddrValidVec = addrNotBlock | staInSame；storeDataValidVec 同理
      storeAddrValid[i] = addrNotBlock[i] | staInSame[i];
      storeDataValid[i] = dataNotBlock[i] | stdInSame[i];
    end
  end

  // L2 hint 唤醒 mask（C_DM 且 mshrId 匹配 hint sourceId）
  logic [LQ_REPLAY_SIZE-1:0] loadHintWakeMask;
  always_comb
    for (int i = 0; i < LQ_REPLAY_SIZE; i++)
      loadHintWakeMask[i] = ent[i].allocated & ~ent[i].scheduled & cause[i][C_DM]
                          & ent[i].blocking & (missMSHRId[i] == l2_hint_sourceId) & l2_hint_valid;

  // 下一拍 blocking 值（priority 高→低；最外层 ~hintWake 无条件清）。
  //  各 cause 的「解除条件」（满足则下拍 blocking=0）就地展开为局部变量 clr_*：
  //   - 不用 function 是因为这些条件需读 entry 数组与多个模块端口（非局部变量），
  //     Formality 读 RTL 时对「函数内引用非局部变量」会报 FMR_VLOG-091 并升级为
  //     elaboration error；就地展开既可读又对 FM 友好。
  logic [LQ_REPLAY_SIZE-1:0] blkNext;
  always_comb begin
    for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin
      logic b;
      logic clr_MF, clr_RAW, clr_RAR, clr_DM, clr_FF, clr_TM, clr_MA;
      // C_MF：misalign buffer 不满 且（允许投机 或 不晚于 ldWbPtr）
      clr_MF  = ~loadMisalignFull & (misalignAllowSpec | ~lq_is_after(uop[i].lqIdx, ldWbPtr));
      // C_RAW：RAW 队列不满 或 store 地址已就绪（sqIdx 不晚于 stAddrReadySqPtr）
      clr_RAW = ~rawFull | ~sq_is_after(uop[i].sqIdx, stAddrReadySqPtr);
      // C_RAR：RAR 队列不满 或 不晚于 ldWbPtr
      clr_RAR = ~rarFull | ~lq_is_after(uop[i].lqIdx, ldWbPtr);
      // C_DM：D-channel refill 命中本 entry 的 mshr id
      clr_DM  = tl_d_valid & (tl_d_mshrid == missMSHRId[i]);
      // C_FF：store data 已就绪
      clr_FF  = ent[i].allocated & storeDataValid[i];
      // C_TM：tlb hint 回填（全量重放 或 命中本 entry 的 tlb id）
      clr_TM  = tlb_hint_valid & (tlb_hint_replay_all | (tlb_hint_id == tlbHintId[i]));
      // C_MA：store 地址已就绪
      clr_MA  = cause[i][C_MA] & ent[i].allocated & storeAddrValid[i];

      if      (cause[i][C_MF])  b = ~clr_MF  & ent[i].blocking;
      else if (cause[i][C_RAW]) b = ~clr_RAW & ent[i].blocking;
      else if (cause[i][C_RAR]) b = ~clr_RAR & ent[i].blocking;
      else if (cause[i][C_DM])  b = ~clr_DM  & ent[i].blocking;
      else if (cause[i][C_FF])  b = ~clr_FF  & ent[i].blocking;
      else if (cause[i][C_TM])  b = ~clr_TM  & ent[i].blocking;
      else                      b = ~clr_MA  & ent[i].blocking;  // 默认含 C_MA
      blkNext[i] = ~loadHintWakeMask[i] & b;
    end
  end
