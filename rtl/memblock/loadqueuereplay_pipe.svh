// §4  s1/s2 流水 + replay_req 组装
// -----------------------------------------------------------------------------
//  s1：把 s0 选出的 one-hot(72) 转 7 位下标，按 s0_can_go 打一拍寄存（s1_oldestSel）。
//      s0_can_go = s1_can_go | s1 项被本/上拍 redirect 刷。命中则置该 entry scheduled。
//  s2：再打一拍（s2_oldestSel），读出 vaddr/uop/cause 等组装成 replay_req 发回 LoadUnit。
//      s1_can_go = (未冷却 & (s2 无效 | s2 发射成功)) | s2 被取消。
//      s2_oldestSel.valid = RegEnable(s1_can_go ? s1有效且未取消 : 0, s1_can_go|replay_fire)。
//
//  ⚠ s2_oldestSel.bits 作为下标去读 uop/cause/missMSHRId 等数组：复位/未选时该下标可能为
//    随机/X。SV 中 `array[X] 恒 X`，故所有「按 s2 下标读数组」一律用三元 mux 在 valid 时
//    才取，保证 X 收敛（这正是 LsqWrapper FM 假阳性家族的根源——golden 用展平标量 mux
//    天然收敛，而 struct 数组下标读不收敛）。

  // ---- one-hot → 下标（72→7）----
  function automatic logic [LQ_IDX_W-1:0] oh72_to_idx(input logic [LQ_REPLAY_SIZE-1:0] oh);
    logic [LQ_IDX_W-1:0] r;
    r = '0;
    for (int k = 0; k < LQ_REPLAY_SIZE; k++) if (oh[k]) r = r | k[LQ_IDX_W-1:0];
    return r;
  endfunction

  // 注：entry 寄存器阵列按真实深度 72 声明（见 §0）；运行期 7 位下标的纯值读一律走
  //  128 深越界折叠视图 *R（uopR/vecReplayR/causeR/missMSHRIdR，k>=72 回绕读 [0]，复刻
  //  golden firtool 128 项读表），静态在界。直接 arr[i] 读取仅由 i<72 循环变量索引。不封装
  //  成函数——函数读模块级数组属「非局部引用」会触发 FMR_VLOG-091；故在使用处直接 arr[i]。

  // s1/s2 寄存器
  logic [LD_PIPE_W-1:0]              s1_oldestSel_valid_q, s2_oldestSel_valid_q;
  logic [LD_PIPE_W-1:0][LQ_IDX_W-1:0] s1_oldestSel_bits_q, s2_oldestSel_bits_q;
  logic [LD_PIPE_W-1:0]              s1_can_go, s2_cancelReplay;

  // 冷却计数器（每路一个）
  logic [COLD_DOWN_W-1:0] coldCounter [LD_PIPE_W];

  // s2 锁存的 replay payload（按 s1_can_go 使能寄存，读 s1 下标处的数组）
  lqr_uop_t              s2_uop_q  [LD_PIPE_W];
  lqr_vec_t              s2_vec_q  [LD_PIPE_W];
  logic [MSHR_ST_W-1:0]  s2_mshr_q [LD_PIPE_W];   // 5 位（跟随 missMSHRIdR；输出取 [3:0]，bit[4] 恒 0 双射 golden s2_replayMSHRId[4]）
  logic [N_CAUSES-1:0]   s2_cause_q [LD_PIPE_W];

  // 组合：s0_can_go / s1 项是否被 redirect 取消
  logic redirect_valid_q;
  rob_ptr_t redirect_robIdx_q;
  logic redirect_level_q;
  always_ff @(posedge clock) begin
    redirect_valid_q  <= redirect_valid;
    redirect_robIdx_q <= redirect_robIdx;
    redirect_level_q  <= redirect_level;
  end

  // 重放发射 fire = valid & ready
  logic [LD_PIPE_W-1:0] replay_fire;
  assign replay_fire = replay_valid & replay_ready;

  // s1 项指向的 uop 的 robIdx（用于 s1_cancel 的 needFlush 判定）。
  // ★golden 直接读越界折叠视图 _GEN_3[s1_oldestSel_0_bits_r]（即 uopR[bits].robIdx），
  //   **不带 s1_oldestSel_valid 门控**。原实现用 `valid ? uopR[bits] : uop[0]` 的三元 mux
  //   在 ~valid 拍取 uop[0]，与 golden 无条件读 uopR[bits] 分叉 → 引入 s1_oldestSel_valid_q
  //   进 s0_can_go/scheduled/s1_oldestSel 次态锥（FM analyze_points 实证：coldCounter &
  //   s1_oldestSel_valid_q 出现在 impl 锥而不在 golden 锥）。去掉门控，一律走 uopR[bits]。★
  //  needFlush 用当前/上拍 redirect 各判一次（与 golden 双重 needFlush 一致）。
  logic [LD_PIPE_W-1:0] s1_cancel;
  always_comb begin
    for (int i = 0; i < LD_PIPE_W; i++) begin
      lqr_uop_t u;
      logic f1, f2;
      u = uopR[s1_oldestSel_bits_q[i]];
      f1 = rob_need_flush(u.robIdx.flag, u.robIdx.value, redirect_valid,   redirect_robIdx.flag,   redirect_robIdx.value,   redirect_level);
      f2 = rob_need_flush(u.robIdx.flag, u.robIdx.value, redirect_valid_q, redirect_robIdx_q.flag, redirect_robIdx_q.value, redirect_level_q);
      s1_cancel[i] = f1 | f2;
    end
  end

  // s1_can_go / scheduled 置位（s0→s1）
  logic [LD_PIPE_W-1:0] s0_can_go;
  always_comb begin
    for (int i = 0; i < LD_PIPE_W; i++) begin
      logic canFire, coldNow;
      canFire = coldCounter[i] < COLD_DOWN_THRESHOLD;   // replayCanFire
      coldNow = coldCounter[i] >= COLD_DOWN_THRESHOLD;  // coldDownNow（仅用于计数器更新）
      // s1_can_go：未冷却 & (s2 无效 | s2 发射) 或 s2 被取消
      s1_can_go[i] = (canFire & (~s2_oldestSel_valid_q[i] | replay_fire[i])) | s2_cancelReplay[i];
      // s0_can_go：s1 能走 或 s1 项被刷
      s0_can_go[i] = s1_can_go[i] | s1_cancel[i];
    end
  end

  // vaddr 子模块读：s1 有效且 s1_can_go
  always_comb begin
    for (int i = 0; i < LD_PIPE_W; i++) begin
      va_ren[i]   = s1_oldestSel_valid_q[i] & s1_can_go[i];
      va_raddr[i] = s1_oldestSel_bits_q[i];
    end
  end

  // s1 寄存（RegEnable, enable = s0_can_go）
  // ★golden 仅复位 s1_oldestSel_valid_r；s1_oldestSel_bits_r 无复位——原实现多复位 bits→分叉。★
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_oldestSel_valid_q <= '0;
    end else begin
      for (int i = 0; i < LD_PIPE_W; i++)
        if (s0_can_go[i]) s1_oldestSel_valid_q[i] <= s0_oldestSel_valid[i];
    end
  end
  // s1_oldestSel_bits：无复位 RegEnable(en=s0_can_go)
  always_ff @(posedge clock)
    for (int i = 0; i < LD_PIPE_W; i++)
      if (s0_can_go[i]) s1_oldestSel_bits_q[i] <= oh72_to_idx(s0_oldestSel_bits[i]);

  // s2 寄存（s1→s2）
  //  s2_oldestSel.valid = RegEnable(s1_can_go ? (s1_valid & ~s1_cancel) : 0, en=s1_can_go|replay_fire)
  //  s2_oldestSel.bits  = RegEnable(s1_bits, en=s1_can_go)
  //  payload（uop/vec/mshr/cause）= RegEnable(数组[s1_bits], en=s1_can_go)，下标读用三元 mux
  // ★golden 仅复位 s2_oldestSel_valid_r；s2_oldestSel_bits_r / s2_replayUop / s2_vecReplay /
  //   s2_mshr / s2_cause 均为**无复位** RegEnable(en=s1_can_go)——原实现把它们也在 reset 清 0，
  //   与 golden 分叉(s2_replayUop_debugInfo 等 384+ 点 fail)。此处 valid 复位，payload 无复位。★
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s2_oldestSel_valid_q <= '0;
    end else begin
      // ★不在 always_ff 体内声明 blocking 赋值的组合临时量(s1v)——FM 前端会把每路迭代推成
      //   死寄存器(s1v_reg)。直接内联 s1_oldestSel_valid_q[i]&~s1_cancel[i]。★
      for (int i = 0; i < LD_PIPE_W; i++)
        if (s1_can_go[i] | replay_fire[i])
          s2_oldestSel_valid_q[i] <= s1_can_go[i] ? (s1_oldestSel_valid_q[i] & ~s1_cancel[i]) : 1'b0;
    end
  end
  // s2 payload：无复位 RegEnable(en=s1_can_go)，与 golden 同(复位期间照常按使能更新)
  // ★golden 各 s2_replayUop/s2_vecReplay/s2_cause <= _GEN_xxxx[s1_oldestSel_bits_r] 直接按下标读，
  //   **不带 valid 门控**(bounds-folded *R 视图处理越界)。原实现用 `valid ? *R[bits] : entry0`
  //   在 ~valid 拍取 entry0 与 golden 取 [bits] 分叉→s2_replayUop/s2_vecReplay 数百点 fail。
  //   去掉 valid 门控, 一律走 *R[bits] 与 golden 逐位对齐。★
  //  s2_replayUop/s2_vecReplay 亦只寄 golden 存的位/字段（同 per-entry：exc 19 位 + 无
  //  loadWaitStrict；vec 9 字段），其余位/字段悬空(FM 剪除)，与 golden s2_replayUop 形状一致。
  //  ★s2 读源 uopR[bits]/vecReplayR[bits] 在 always_comb 里算好（s2_uop_in/s2_vec_in 数组），
  //   always_ff 直接下标读——绝不在 always_ff 体内声明 struct 临时量(automatic su/sv)，否则 FM
  //   前端每路迭代各推成死寄存器(su_reg/sv_reg…)。★
  lqr_uop_t s2_uop_in [LD_PIPE_W];
  lqr_vec_t s2_vec_in [LD_PIPE_W];
  always_comb
    for (int i = 0; i < LD_PIPE_W; i++) begin
      s2_uop_in[i] = uopR[s1_oldestSel_bits_q[i]];
      s2_vec_in[i] = vecReplayR[s1_oldestSel_bits_q[i]];
    end
  always_ff @(posedge clock) begin
    for (int i = 0; i < LD_PIPE_W; i++) begin
      if (s1_can_go[i]) begin
        s2_oldestSel_bits_q[i] <= s1_oldestSel_bits_q[i];
        for (int b = 0; b < 24; b++)
          if (EXC_KEEP[b]) s2_uop_q[i].exceptionVec[b] <= s2_uop_in[i].exceptionVec[b];
        s2_uop_q[i].preDecodeInfo_isRVC <= s2_uop_in[i].preDecodeInfo_isRVC;
        s2_uop_q[i].ftqPtr_flag         <= s2_uop_in[i].ftqPtr_flag;
        s2_uop_q[i].ftqPtr_value        <= s2_uop_in[i].ftqPtr_value;
        s2_uop_q[i].ftqOffset           <= s2_uop_in[i].ftqOffset;
        s2_uop_q[i].fuOpType            <= s2_uop_in[i].fuOpType;
        s2_uop_q[i].rfWen               <= s2_uop_in[i].rfWen;
        s2_uop_q[i].fpWen               <= s2_uop_in[i].fpWen;
        s2_uop_q[i].vpu_vstart          <= s2_uop_in[i].vpu_vstart;
        s2_uop_q[i].vpu_veew            <= s2_uop_in[i].vpu_veew;
        s2_uop_q[i].uopIdx              <= s2_uop_in[i].uopIdx;
        s2_uop_q[i].pdest               <= s2_uop_in[i].pdest;
        s2_uop_q[i].robIdx              <= s2_uop_in[i].robIdx;
        s2_uop_q[i].dbg_enqRsTime       <= s2_uop_in[i].dbg_enqRsTime;
        s2_uop_q[i].dbg_selectTime      <= s2_uop_in[i].dbg_selectTime;
        s2_uop_q[i].dbg_issueTime       <= s2_uop_in[i].dbg_issueTime;
        s2_uop_q[i].storeSetHit         <= s2_uop_in[i].storeSetHit;
        s2_uop_q[i].waitForRobIdx_flag  <= s2_uop_in[i].waitForRobIdx_flag;
        s2_uop_q[i].waitForRobIdx_value <= s2_uop_in[i].waitForRobIdx_value;
        s2_uop_q[i].loadWaitBit         <= s2_uop_in[i].loadWaitBit;
        // s2_uop_q[i].loadWaitStrict 不驱动
        s2_uop_q[i].lqIdx               <= s2_uop_in[i].lqIdx;
        s2_uop_q[i].sqIdx               <= s2_uop_in[i].sqIdx;
        s2_vec_q[i].isvec           <= s2_vec_in[i].isvec;
        s2_vec_q[i].is128bit        <= s2_vec_in[i].is128bit;
        s2_vec_q[i].elemIdx         <= s2_vec_in[i].elemIdx;
        s2_vec_q[i].alignedType     <= s2_vec_in[i].alignedType;
        s2_vec_q[i].mbIndex         <= s2_vec_in[i].mbIndex;
        s2_vec_q[i].elemIdxInsideVd <= s2_vec_in[i].elemIdxInsideVd;
        s2_vec_q[i].reg_offset      <= s2_vec_in[i].reg_offset;
        s2_vec_q[i].vecActive       <= s2_vec_in[i].vecActive;
        s2_vec_q[i].mask            <= s2_vec_in[i].mask;
        // s2_vec_q[i].{isLastElem,is_first_ele,uop_unit_stride_fof,usSecondInv} 不驱动
        s2_mshr_q[i]  <= missMSHRIdR[s1_oldestSel_bits_q[i]];
        s2_cause_q[i] <= causeR[s1_oldestSel_bits_q[i]];
      end
    end
  end

  // s2 项被 redirect 取消
  always_comb begin
    for (int i = 0; i < LD_PIPE_W; i++)
      s2_cancelReplay[i] = rob_need_flush(s2_uop_q[i].robIdx.flag, s2_uop_q[i].robIdx.value,
                             redirect_valid, redirect_robIdx.flag, redirect_robIdx.value, redirect_level);
  end

  // ---- replay_req 组装（EnableHybridUnitReplay=true：直接 3 路连出）----
  always_comb begin
    for (int i = 0; i < LD_PIPE_W; i++) begin
      lqr_uop_t u;
      u = s2_uop_q[i];
      u.exceptionVec[5] = 1'b0;   // loadAddrMisaligned 清 0（重放时不再带对齐异常）
      u.loadWaitStrict  = 1'b0;
      replay_valid[i]              = s2_oldestSel_valid_q[i];
      replay_uop[i]                = u;
      replay_vec[i]                = s2_vec_q[i];
      replay_vaddr[i]              = va_rdata[i];
      replay_mshrid[i]             = s2_mshr_q[i][MSHR_ID_W-1:0];  // 输出 4 位（bit[4] 恒 0，golden 同）
      replay_forward_tlDchannel[i] = s2_cause_q[i][C_DM];
      replay_schedIndex[i]         = s2_oldestSel_bits_q[i];
    end
  end

  // ---- 冷却计数器更新 ----
  //  lastReplay = RegNext(replay.fire)；本拍仍 fire 且上拍也 fire → +1（连发同口）
  //  否则若 coldDownNow → 继续 +1（直到溢出回绕清 0）；否则清 0。
  logic [LD_PIPE_W-1:0] lastReplay_q;
  // 无复位寄存器：仅 @(posedge clock)。★不能带 `or posedge reset` 却无 if(reset)——
  //   FM 阅读器 FMR_VLOG-144 拒绝(异步复位块首语句须为 if(reset))→impl 无法 elaborate。
  always_ff @(posedge clock) lastReplay_q <= replay_fire;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) for (int i = 0; i < LD_PIPE_W; i++) coldCounter[i] <= '0;
    else for (int i = 0; i < LD_PIPE_W; i++) begin
      if (lastReplay_q[i] & replay_fire[i])              coldCounter[i] <= coldCounter[i] + 1'b1;
      else if (coldCounter[i] >= COLD_DOWN_THRESHOLD)    coldCounter[i] <= coldCounter[i] + 1'b1;
      else                                                coldCounter[i] <= '0;
    end
  end
