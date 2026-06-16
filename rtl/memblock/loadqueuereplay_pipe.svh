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

  // 注：entry 数组按 LQ_SLOTS=128 声明（见 §0），7 位下标恒在界，直接 arr[idx] 读取
  //  即可（最可读，且不触发 Formality out-of-bound elab 误报）。不封装成函数——函数读
  //  模块级数组属「非局部引用」会触发 FMR_VLOG-091；故在使用处直接 arr[idx]。

  // s1/s2 寄存器
  logic [LD_PIPE_W-1:0]              s1_oldestSel_valid_q, s2_oldestSel_valid_q;
  logic [LD_PIPE_W-1:0][LQ_IDX_W-1:0] s1_oldestSel_bits_q, s2_oldestSel_bits_q;
  logic [LD_PIPE_W-1:0]              s1_can_go, s2_cancelReplay;

  // 冷却计数器（每路一个）
  logic [COLD_DOWN_W-1:0] coldCounter [LD_PIPE_W];

  // s2 锁存的 replay payload（按 s1_can_go 使能寄存，读 s1 下标处的数组）
  lqr_uop_t              s2_uop_q  [LD_PIPE_W];
  lqr_vec_t              s2_vec_q  [LD_PIPE_W];
  logic [MSHR_ID_W-1:0]  s2_mshr_q [LD_PIPE_W];
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

  // s1 项指向的 uop（用三元 mux 让 X 收敛：仅 valid 时取，否则取 entry0）
  //  needFlush 用当前/上拍 redirect 各判一次（与 golden 双重 needFlush 一致）
  logic [LD_PIPE_W-1:0] s1_cancel;
  always_comb begin
    for (int i = 0; i < LD_PIPE_W; i++) begin
      lqr_uop_t u;
      logic f1, f2;
      u = s1_oldestSel_valid_q[i] ? uop[s1_oldestSel_bits_q[i]] : uop[0];
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
  always_ff @(posedge clock) begin
    if (reset) begin
      s1_oldestSel_valid_q <= '0;
      for (int i = 0; i < LD_PIPE_W; i++) s1_oldestSel_bits_q[i] <= '0;
    end else begin
      for (int i = 0; i < LD_PIPE_W; i++) begin
        if (s0_can_go[i]) begin
          s1_oldestSel_valid_q[i] <= s0_oldestSel_valid[i];
          s1_oldestSel_bits_q[i]  <= oh72_to_idx(s0_oldestSel_bits[i]);
        end
      end
    end
  end

  // s2 寄存（s1→s2）
  //  s2_oldestSel.valid = RegEnable(s1_can_go ? (s1_valid & ~s1_cancel) : 0, en=s1_can_go|replay_fire)
  //  s2_oldestSel.bits  = RegEnable(s1_bits, en=s1_can_go)
  //  payload（uop/vec/mshr/cause）= RegEnable(数组[s1_bits], en=s1_can_go)，下标读用三元 mux
  always_ff @(posedge clock) begin
    if (reset) begin
      s2_oldestSel_valid_q <= '0;
      for (int i = 0; i < LD_PIPE_W; i++) begin
        s2_oldestSel_bits_q[i] <= '0;
        s2_uop_q[i]   <= '0;
        s2_vec_q[i]   <= '0;
        s2_mshr_q[i]  <= '0;
        s2_cause_q[i] <= '0;
      end
    end else begin
      for (int i = 0; i < LD_PIPE_W; i++) begin
        logic s1v;
        s1v = s1_oldestSel_valid_q[i] & ~s1_cancel[i];
        if (s1_can_go[i] | replay_fire[i])
          s2_oldestSel_valid_q[i] <= s1_can_go[i] ? s1v : 1'b0;
        if (s1_can_go[i]) begin
          s2_oldestSel_bits_q[i] <= s1_oldestSel_bits_q[i];
          s2_uop_q[i]   <= s1_oldestSel_valid_q[i] ? uop[s1_oldestSel_bits_q[i]]  : uop[0];
          s2_vec_q[i]   <= s1_oldestSel_valid_q[i] ? vecReplay[s1_oldestSel_bits_q[i]]  : vecReplay[0];
          s2_mshr_q[i]  <= s1_oldestSel_valid_q[i] ? missMSHRId[s1_oldestSel_bits_q[i]] : missMSHRId[0];
          s2_cause_q[i] <= s1_oldestSel_valid_q[i] ? cause[s1_oldestSel_bits_q[i]]: cause[0];
        end
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
      replay_mshrid[i]             = s2_mshr_q[i];
      replay_forward_tlDchannel[i] = s2_cause_q[i][C_DM];
      replay_schedIndex[i]         = s2_oldestSel_bits_q[i];
    end
  end

  // ---- 冷却计数器更新 ----
  //  lastReplay = RegNext(replay.fire)；本拍仍 fire 且上拍也 fire → +1（连发同口）
  //  否则若 coldDownNow → 继续 +1（直到溢出回绕清 0）；否则清 0。
  logic [LD_PIPE_W-1:0] lastReplay_q;
  always_ff @(posedge clock) lastReplay_q <= replay_fire;
  always_ff @(posedge clock) begin
    if (reset) for (int i = 0; i < LD_PIPE_W; i++) coldCounter[i] <= '0;
    else for (int i = 0; i < LD_PIPE_W; i++) begin
      if (lastReplay_q[i] & replay_fire[i])              coldCounter[i] <= coldCounter[i] + 1'b1;
      else if (coldCounter[i] >= COLD_DOWN_THRESHOLD)    coldCounter[i] <= coldCounter[i] + 1'b1;
      else                                                coldCounter[i] <= '0;
    end
  end
