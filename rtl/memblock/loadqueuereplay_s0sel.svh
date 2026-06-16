// §3  s0 选择：选出每路（3 路）一个可重放的 oldest entry（one-hot）
// -----------------------------------------------------------------------------
//  选择优先级（Scala 注释）：
//    1. L2 hint 唤醒的 load（最高）
//    2. 高优先 cause（C_DM dcache miss / C_FF forward fail）
//    3. 低优先 cause（其余）
//  在每个优先级内再按年龄选最老：程序序 oldest（issOldest）优先于入队序 oldest
//  （ageOldest，AgeDetector 输出）。
//
//  rem 交织：72 entry 按 i%LD_PIPE_W 分成 3 组，每组 24 个由一个 AgeDetector 负责。
//  entry i 归 rem=(i%3) 组，组内序号 = i/3。第 r 路重放只在 rem=r 组里选。

  // ---- 候选 mask（72 位）----
  logic [LQ_REPLAY_SIZE-1:0] hintSelMask;          // hint 唤醒且按 keyword 选 beat
  logic [LQ_REPLAY_SIZE-1:0] higherPriMask, lowerPriMask;  // 高/低优先可重放
  logic [LQ_REPLAY_SIZE-1:0] normalSelMask;        // = higher | lower | hint

  // dataInLastBeat 寄存器位向量
  logic [LQ_REPLAY_SIZE-1:0] dataInLastBeat_v;
  generate
    for (gi = 0; gi < LQ_REPLAY_SIZE; gi++)
      assign dataInLastBeat_v[gi] = dataInLastBeat[gi];
  endgenerate

  always_comb begin
    // hint 选择：keyword=1 选「数据在最后一拍」的，否则选「不在最后一拍」的
    for (int i = 0; i < LQ_REPLAY_SIZE; i++) begin
      logic hintBeat;
      hintBeat = l2_hint_isKeyword ? dataInLastBeat_v[i] : ~dataInLastBeat_v[i];
      hintSelMask[i]   = loadHintWakeMask[i] & hintBeat;
      higherPriMask[i] = ent[i].allocated & ~ent[i].scheduled & ~ent[i].blocking
                       & (cause[i][C_DM] | cause[i][C_FF]);
      lowerPriMask[i]  = ent[i].allocated & ~ent[i].scheduled & ~ent[i].blocking
                       & ~(cause[i][C_DM] | cause[i][C_FF]);
    end
    normalSelMask = higherPriMask | lowerPriMask | hintSelMask;
  end

  // 入队 fire mask（72 位）：本拍 newEnqueue 的 entry，按其 enqIndexOH 标记。
  //  每路 w 的贡献：newEnqueue[w] ? enqIndexOH[w] : 0。三路或起来。
  logic [LQ_REPLAY_SIZE-1:0] loadEnqFireMask [LD_PIPE_W];
  always_comb begin
    for (int w = 0; w < LD_PIPE_W; w++)
      loadEnqFireMask[w] = newEnqueue[w] ? enqIndexOH[w] : '0;
  end

  // free mask 打一拍（用于 AgeDetector 的 deq，即「上拍释放的槽」从年龄矩阵移除）
  logic [LQ_REPLAY_SIZE-1:0] loadFreeSelMask_q;
  always_ff @(posedge clock) loadFreeSelMask_q <= freeMaskVec;

  // ---- 把 72 位总线按 rem 拆成 3×24（rem r 取 bit i*3+r）----
  //  age_enq[r][w] = 第 w 个 enq 口在 rem=r 组内的 24 位 fire 向量
  //  age_deq[r]    = rem=r 组内的 free 向量
  //  age_ready[r]  = rem=r 组内的「priority replay sel」（hint>higher>lower）
  always_comb begin
    for (int r = 0; r < LD_PIPE_W; r++) begin
      logic [REM_SIZE-1:0] hintRem, higherRem, lowerRem;
      logic hintAny, higherAny;
      for (int k = 0; k < REM_SIZE; k++) begin
        int idx;
        idx = k*LD_PIPE_W + r;
        for (int w = 0; w < LD_PIPE_W; w++) age_enq[r][w][k] = loadEnqFireMask[w][idx];
        age_deq[r][k]  = loadFreeSelMask_q[idx];
        hintRem[k]   = hintSelMask[idx];
        higherRem[k] = higherPriMask[idx];
        lowerRem[k]  = lowerPriMask[idx];
      end
      // priority replay sel：hint 有解→hint；否则 higher 有解→higher；否则 lower
      hintAny   = |hintRem;
      higherAny = |higherRem;
      age_ready[r] = hintAny ? hintRem : (higherAny ? higherRem : lowerRem);
    end
  end

  // ---- 程序序 oldest 匹配（issOldest）----
  //  oldestPtrExt(j) = ldWbPtr + j（j=0..OLDEST_STRIDE-1）。
  //  matchMask(i)(j) = normalSelMask(i) & uop(i).lqIdx == oldestPtrExt(j)。
  //  rem 内：先看 j==0（最老）匹配项 oldsetMatch；否则取 j>=1 的 olderMatch 合并。
  //  s0_remOldestSelVec(rem)(i_in_rem) =
  //     ParallelORR(rem 内任意 oldsetMatch) ? 该项的 oldsetMatch : olderMatch 的 OR。
  lq_ptr_t oldestPtrExt [OLDEST_STRIDE];
  always_comb
    for (int j = 0; j < OLDEST_STRIDE; j++)
      oldestPtrExt[j] = '{flag: (({1'b0, ldWbPtr.value} + j) >= LQ_REPLAY_SIZE) ? ~ldWbPtr.flag : ldWbPtr.flag,
                          value: (ldWbPtr.value + j[LQ_IDX_W-1:0]) % LQ_REPLAY_SIZE};

  // rem 内的 oldest/older 匹配（24 位）与最终 issOldest 选择向量
  logic [REM_SIZE-1:0] remOldsetMatch [LD_PIPE_W];   // j==0 匹配
  logic [REM_SIZE-1:0] remOldestSelVec [LD_PIPE_W];  // 最终程序序选择向量
  logic [REM_SIZE-1:0] remOldestHintSelVec [LD_PIPE_W];
  always_comb begin
    for (int r = 0; r < LD_PIPE_W; r++) begin
      logic [REM_SIZE-1:0] oldset, olderOr, hintRem;
      logic anyOldset;
      for (int k = 0; k < REM_SIZE; k++) begin
        int idx;
        logic m0, mOlder;
        idx = k*LD_PIPE_W + r;
        // j==0 匹配
        m0 = normalSelMask[idx] & (uop[idx].lqIdx == oldestPtrExt[0]);
        // j>=1 匹配（任一）
        mOlder = 1'b0;
        for (int j = 1; j < OLDEST_STRIDE; j++)
          if (normalSelMask[idx] & (uop[idx].lqIdx == oldestPtrExt[j])) mOlder = 1'b1;
        oldset[k]  = m0;
        olderOr[k] = mOlder;
        hintRem[k] = hintSelMask[idx];
      end
      anyOldset = |oldset;
      for (int k = 0; k < REM_SIZE; k++)
        remOldestSelVec[r][k] = anyOldset ? oldset[k] : olderOr[k];
      remOldsetMatch[r] = oldset;
      remOldestHintSelVec[r] = remOldestSelVec[r] & hintRem;
    end
  end

  // ---- 每路 s0 选择：合并 issOldest（程序序）与 ageOldest（入队序）----
  //  l2HintFirst   : l2_hint 有效且 rem 内有 hint 命中 → 走 hint 的 PriorityEncoderOH
  //  issOldestValid: l2HintFirst 或 rem 内 normalSel 有程序序匹配
  //  oldestSel(rem内) = issOldestValid ? issOldestIndexOH : ageOldestIndexOH
  //  s0_oldestSel.valid = ageOldest.valid | issOldestValid
  //  最终 72 位 OH：把 rem 内 24 位散回 i = k*3 + rport
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
      // 散回 72 位
      s0_oldestSel_bits[r] = '0;
      for (int k = 0; k < REM_SIZE; k++)
        s0_oldestSel_bits[r][k*LD_PIPE_W + r] = oldestSelRem[k];
      s0_oldestSel_valid[r] = ageValid | issOldestValid;
    end
  end
