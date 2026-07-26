// =============================================================================
//  storequeue_vec.svh —— §14 向量异常标志 + vecMbCommit + exceptionBuffer 输入驱动
// =============================================================================

  // ---- vecExceptionFlag：记录「一条向量 store 出现异常」直到其 lastFlow 提交 ----
  //  （信号在核 §0 前向声明，这里只更新）
  // vecCommit(i)：某 entry 收到向量反馈（isCommit||isFlush = feedback_0|feedback_1），
  //   robIdx/uopIdx 匹配且 allocated → 置 vecMbCommit。
  logic [SQ_SIZE-1:0] vecCommit;
  // 两路 vecFeedback 收进局部
  wire vfb0_cf = io_vecFeedback_0_bits_feedback_0 | io_vecFeedback_0_bits_feedback_1;
  wire vfb1_cf = io_vecFeedback_1_bits_feedback_0 | io_vecFeedback_1_bits_feedback_1;
  always_comb begin
    for (int i = 0; i < SQ_SIZE; i++) begin
      logic h0, h1;
      h0 = io_vecFeedback_0_valid & vfb0_cf
           & (uop[i].robIdx_flag == io_vecFeedback_0_bits_robidx_flag)
           & (uop[i].robIdx_value == io_vecFeedback_0_bits_robidx_value)
           & (uop[i].uopIdx == io_vecFeedback_0_bits_uopidx) & ent[i].allocated;
      h1 = io_vecFeedback_1_valid & vfb1_cf
           & (uop[i].robIdx_flag == io_vecFeedback_1_bits_robidx_flag)
           & (uop[i].robIdx_value == io_vecFeedback_1_bits_robidx_value)
           & (uop[i].uopIdx == io_vecFeedback_1_bits_uopidx) & ent[i].allocated;
      vecCommit[i] = h0 | h1;
    end
  end

  // vecCommitHasException：出队时某向量 entry 有异常且 dataBuffer fire（两口）
  wire vecExcV0 = entR[dp0].isVec & entR[dp0].hasException & db_enq0_fire;
  wire vecExcV1 = entR[dp1].isVec & entR[dp1].hasException & db_enq1_fire;
  wire vecCommitHasExceptionValidOR = vecExcV0 | vecExcV1;
  // 选最后一个有异常的 uop（ParallelPosteriorityMux：优先高 index）
  wire selExc1 = vecExcV1;
  wire [ROB_IDX_W-1:0] vecExcSelRobV = selExc1 ? uopR[dp1].robIdx_value : uopR[dp0].robIdx_value;
  wire                 vecExcSelRobF = selExc1 ? uopR[dp1].robIdx_flag  : uopR[dp0].robIdx_flag;

  // lastFlow 判定（robidx 相等/不等/仅口 0 提交三种情形）
  wire robidxEQ = db_enq0_fire & db_enq1_fire
                  & (uopR[dp0].robIdx_flag == uopR[dp1].robIdx_flag)
                  & (uopR[dp0].robIdx_value == uopR[dp1].robIdx_value);
  wire robidxNE = db_enq0_fire & db_enq1_fire
                  & ((uopR[dp0].robIdx_flag != uopR[dp1].robIdx_flag)
                     | (uopR[dp0].robIdx_value != uopR[dp1].robIdx_value));
  wire onlyCommit0 = db_enq0_fire & ~db_enq1_fire;
  wire vecLastFlow0 = entR[dp0].vecLastFlow;
  wire vecLastFlow1 = entR[dp1].vecLastFlow;
  wire vecCommitLastFlow =
        (robidxEQ & vecLastFlow1 & ~firstSplit)
      | (robidxNE & ((vecExcV1 & vecLastFlow1) | ~vecExcV1))
      | (onlyCommit0 & vecLastFlow0);

  // vecExceptionFlagCancel：lastFlow 提交且 robidx 命中当前 flag → 清标志
  wire vecExcCancel0 = vecLastFlow0 & (uopR[dp0].robIdx_flag == vecExceptionFlag_robIdx_flag)
                       & (uopR[dp0].robIdx_value == vecExceptionFlag_robIdx_value)
                       & db_enq0_fire & ~firstSplit;
  wire vecExcCancel1 = vecLastFlow1 & (uopR[dp1].robIdx_flag == vecExceptionFlag_robIdx_flag)
                       & (uopR[dp1].robIdx_value == vecExceptionFlag_robIdx_value)
                       & db_enq1_fire & ~firstSplit;
  wire vecExceptionFlagCancel = vecExcCancel0 | vecExcCancel1;

  // golden：valid / robIdx_flag / robIdx_value **均异步复位到 0**（reg block 行 50704-50706），
  //   更新 = set(_GEN_2428) ? sel : (cancel 清 0 / 否则 hold)。此前 impl 漏了 robIdx 的复位
  //   与 cancel 清 0（golden else 支：flag<=~cancel&flag，value<=cancel?0:value），使 golden
  //   的 robIdx 锥含 reset 而 impl 锥没有（"ref 锥有、impl 锥没有" 失配根因）。1:1 复刻。
  wire vecExcSet    = ~vecExceptionFlag_valid & vecCommitHasExceptionValidOR & ~vecCommitLastFlow;
  wire vecExcCancel = vecExceptionFlag_valid & vecExceptionFlagCancel;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      vecExceptionFlag_valid        <= 1'b0;
      vecExceptionFlag_robIdx_flag  <= 1'b0;
      vecExceptionFlag_robIdx_value <= '0;
    end else begin
      vecExceptionFlag_valid <= vecExcSet | (~vecExcCancel & vecExceptionFlag_valid);
      if (vecExcSet) begin
        vecExceptionFlag_robIdx_flag  <= vecExcSelRobF;
        vecExceptionFlag_robIdx_value <= vecExcSelRobV;
      end else begin
        vecExceptionFlag_robIdx_flag  <= ~vecExcCancel & vecExceptionFlag_robIdx_flag;
        if (vecExcCancel) vecExceptionFlag_robIdx_value <= '0;
      end
    end
  end

  // ---------------------------------------------------------------------------
  //  exceptionBuffer 输入驱动（7 路），对应 subinst 引用的 eb_in_<k>_*
  //   0/1：storeAddrIn s1（非 miss、非向量、有 Sta 异常）
  //   2/3：storeAddrIn s2（storeAddrInFireReg & hasException & !isvec；exc(3)=af）
  //   4/5：vecFeedback FLUSH（feedback_0）
  //   6  ：mmioStout.fire → uncacheUop
  // ---------------------------------------------------------------------------
  // Sta 异常向量 orR（exc bits 3/6/7/15/19/23 是 Sta 相关）
  wire sta0_excOrr = io_storeAddrIn_0_bits_uop_exceptionVec_3 | io_storeAddrIn_0_bits_uop_exceptionVec_6
                   | io_storeAddrIn_0_bits_uop_exceptionVec_7 | io_storeAddrIn_0_bits_uop_exceptionVec_15
                   | io_storeAddrIn_0_bits_uop_exceptionVec_19| io_storeAddrIn_0_bits_uop_exceptionVec_23;
  wire sta1_excOrr = io_storeAddrIn_1_bits_uop_exceptionVec_3 | io_storeAddrIn_1_bits_uop_exceptionVec_6
                   | io_storeAddrIn_1_bits_uop_exceptionVec_7 | io_storeAddrIn_1_bits_uop_exceptionVec_15
                   | io_storeAddrIn_1_bits_uop_exceptionVec_19| io_storeAddrIn_1_bits_uop_exceptionVec_23;

  // uncacheUop uopIdx（port 6 用）
  logic [UOP_IDX_W-1:0] uncUop_uopIdx;
  always_ff @(posedge clock) if (mmioIdleGo_q & (mmioState == MMIO_IDLE)) uncUop_uopIdx <= uopR[deqPtr].uopIdx;

  // ---- port 0 ----
  assign eb_in_0_valid = io_storeAddrIn_0_valid & ~io_storeAddrIn_0_bits_miss & ~io_storeAddrIn_0_bits_isvec;
  assign eb_in_0_bits_uop_exceptionVec_3  = io_storeAddrIn_0_bits_uop_exceptionVec_3;
  assign eb_in_0_bits_uop_exceptionVec_6  = io_storeAddrIn_0_bits_uop_exceptionVec_6;
  assign eb_in_0_bits_uop_exceptionVec_7  = io_storeAddrIn_0_bits_uop_exceptionVec_7;
  assign eb_in_0_bits_uop_exceptionVec_15 = io_storeAddrIn_0_bits_uop_exceptionVec_15;
  assign eb_in_0_bits_uop_exceptionVec_19 = io_storeAddrIn_0_bits_uop_exceptionVec_19;
  assign eb_in_0_bits_uop_exceptionVec_23 = io_storeAddrIn_0_bits_uop_exceptionVec_23;
  assign eb_in_0_bits_uop_uopIdx       = io_storeAddrIn_0_bits_uop_uopIdx;
  assign eb_in_0_bits_uop_robIdx_flag  = io_storeAddrIn_0_bits_uop_robIdx_flag;
  assign eb_in_0_bits_uop_robIdx_value = io_storeAddrIn_0_bits_uop_robIdx_value;
  assign eb_in_0_bits_fullva           = io_storeAddrIn_0_bits_fullva;
  assign eb_in_0_bits_vaNeedExt        = io_storeAddrIn_0_bits_vaNeedExt;
  assign eb_in_0_bits_gpaddr           = io_storeAddrIn_0_bits_gpaddr;
  assign eb_in_0_bits_isHyper          = io_storeAddrIn_0_bits_isHyper;
  assign eb_in_0_bits_isForVSnonLeafPTE= io_storeAddrIn_0_bits_isForVSnonLeafPTE;
  // ---- port 1 ----
  assign eb_in_1_valid = io_storeAddrIn_1_valid & ~io_storeAddrIn_1_bits_miss & ~io_storeAddrIn_1_bits_isvec;
  assign eb_in_1_bits_uop_exceptionVec_3  = io_storeAddrIn_1_bits_uop_exceptionVec_3;
  assign eb_in_1_bits_uop_exceptionVec_6  = io_storeAddrIn_1_bits_uop_exceptionVec_6;
  assign eb_in_1_bits_uop_exceptionVec_7  = io_storeAddrIn_1_bits_uop_exceptionVec_7;
  assign eb_in_1_bits_uop_exceptionVec_15 = io_storeAddrIn_1_bits_uop_exceptionVec_15;
  assign eb_in_1_bits_uop_exceptionVec_19 = io_storeAddrIn_1_bits_uop_exceptionVec_19;
  assign eb_in_1_bits_uop_exceptionVec_23 = io_storeAddrIn_1_bits_uop_exceptionVec_23;
  assign eb_in_1_bits_uop_uopIdx       = io_storeAddrIn_1_bits_uop_uopIdx;
  assign eb_in_1_bits_uop_robIdx_flag  = io_storeAddrIn_1_bits_uop_robIdx_flag;
  assign eb_in_1_bits_uop_robIdx_value = io_storeAddrIn_1_bits_uop_robIdx_value;
  assign eb_in_1_bits_fullva           = io_storeAddrIn_1_bits_fullva;
  assign eb_in_1_bits_vaNeedExt        = io_storeAddrIn_1_bits_vaNeedExt;
  assign eb_in_1_bits_gpaddr           = io_storeAddrIn_1_bits_gpaddr;
  assign eb_in_1_bits_isHyper          = io_storeAddrIn_1_bits_isHyper;
  assign eb_in_1_bits_isForVSnonLeafPTE= io_storeAddrIn_1_bits_isForVSnonLeafPTE;

  // ---- port 2/3：storeAddrIn s2（storeAddrInFireReg & hasException & !isvec）----
  //   bits := storeAddrInRe；storeAccessFault(=exceptionVec_7) := af；其余 Sta 异常位
  //   3/6/15/19/23 与 robIdx/uopIdx/fullva/gpaddr 等从 Re 透传。全部用 sta?_reFire 选通
  //   （sta?_reFire == storeAddrInFireReg，已含 updateAddrValid 门控）。
  assign eb_in_2_valid = sta0_reFire & io_storeAddrInRe_0_hasException & ~io_storeAddrInRe_0_isvec;
  assign eb_in_2_bits_uop_exceptionVec_3  = sta0_reFire & io_storeAddrInRe_0_uop_exceptionVec_3;
  assign eb_in_2_bits_uop_exceptionVec_6  = sta0_reFire & io_storeAddrInRe_0_uop_exceptionVec_6;
  assign eb_in_2_bits_uop_exceptionVec_7  = sta0_reFire & io_storeAddrInRe_0_af;
  assign eb_in_2_bits_uop_exceptionVec_15 = sta0_reFire & io_storeAddrInRe_0_uop_exceptionVec_15;
  assign eb_in_2_bits_uop_exceptionVec_19 = sta0_reFire & io_storeAddrInRe_0_uop_exceptionVec_19;
  assign eb_in_2_bits_uop_exceptionVec_23 = sta0_reFire & io_storeAddrInRe_0_uop_exceptionVec_23;
  assign eb_in_2_bits_uop_uopIdx       = sta0_reFire ? io_storeAddrInRe_0_uop_uopIdx : 7'h0;
  assign eb_in_2_bits_uop_robIdx_flag  = sta0_reFire & io_storeAddrInRe_0_uop_robIdx_flag;
  assign eb_in_2_bits_uop_robIdx_value = sta0_reFire ? io_storeAddrInRe_0_uop_robIdx_value : 8'h0;
  assign eb_in_2_bits_fullva           = sta0_reFire ? io_storeAddrInRe_0_fullva : 64'h0;
  assign eb_in_2_bits_vaNeedExt        = sta0_reFire & io_storeAddrInRe_0_vaNeedExt;
  assign eb_in_2_bits_gpaddr           = sta0_reFire ? io_storeAddrInRe_0_gpaddr : 64'h0;
  assign eb_in_2_bits_isHyper          = sta0_reFire & io_storeAddrInRe_0_isHyper;
  assign eb_in_2_bits_isForVSnonLeafPTE= sta0_reFire & io_storeAddrInRe_0_isForVSnonLeafPTE;
  assign eb_in_3_valid = sta1_reFire & io_storeAddrInRe_1_hasException & ~io_storeAddrInRe_1_isvec;
  assign eb_in_3_bits_uop_exceptionVec_3  = sta1_reFire & io_storeAddrInRe_1_uop_exceptionVec_3;
  assign eb_in_3_bits_uop_exceptionVec_6  = sta1_reFire & io_storeAddrInRe_1_uop_exceptionVec_6;
  assign eb_in_3_bits_uop_exceptionVec_7  = sta1_reFire & io_storeAddrInRe_1_af;
  assign eb_in_3_bits_uop_exceptionVec_15 = sta1_reFire & io_storeAddrInRe_1_uop_exceptionVec_15;
  assign eb_in_3_bits_uop_exceptionVec_19 = sta1_reFire & io_storeAddrInRe_1_uop_exceptionVec_19;
  assign eb_in_3_bits_uop_exceptionVec_23 = sta1_reFire & io_storeAddrInRe_1_uop_exceptionVec_23;
  assign eb_in_3_bits_uop_uopIdx       = sta1_reFire ? io_storeAddrInRe_1_uop_uopIdx : 7'h0;
  assign eb_in_3_bits_uop_robIdx_flag  = sta1_reFire & io_storeAddrInRe_1_uop_robIdx_flag;
  assign eb_in_3_bits_uop_robIdx_value = sta1_reFire ? io_storeAddrInRe_1_uop_robIdx_value : 8'h0;
  assign eb_in_3_bits_fullva           = sta1_reFire ? io_storeAddrInRe_1_fullva : 64'h0;
  assign eb_in_3_bits_vaNeedExt        = sta1_reFire & io_storeAddrInRe_1_vaNeedExt;
  assign eb_in_3_bits_gpaddr           = sta1_reFire ? io_storeAddrInRe_1_gpaddr : 64'h0;
  assign eb_in_3_bits_isHyper          = sta1_reFire & io_storeAddrInRe_1_isHyper;
  assign eb_in_3_bits_isForVSnonLeafPTE= sta1_reFire & io_storeAddrInRe_1_isForVSnonLeafPTE;

  // ---- port 4/5：向量反馈 FLUSH（feedback_0）----
  assign eb_in_4_valid = io_vecFeedback_0_valid & io_vecFeedback_0_bits_feedback_0;
  assign eb_in_4_bits_uop_exceptionVec_3  = io_vecFeedback_0_bits_exceptionVec_3;
  assign eb_in_4_bits_uop_exceptionVec_6  = io_vecFeedback_0_bits_exceptionVec_6;
  assign eb_in_4_bits_uop_exceptionVec_7  = io_vecFeedback_0_bits_exceptionVec_7;
  assign eb_in_4_bits_uop_exceptionVec_15 = io_vecFeedback_0_bits_exceptionVec_15;
  assign eb_in_4_bits_uop_exceptionVec_19 = io_vecFeedback_0_bits_exceptionVec_19;
  assign eb_in_4_bits_uop_exceptionVec_23 = io_vecFeedback_0_bits_exceptionVec_23;
  assign eb_in_4_bits_uop_uopIdx       = io_vecFeedback_0_bits_uopidx;
  assign eb_in_4_bits_uop_robIdx_flag  = io_vecFeedback_0_bits_robidx_flag;
  assign eb_in_4_bits_uop_robIdx_value = io_vecFeedback_0_bits_robidx_value;
  assign eb_in_4_bits_fullva           = io_vecFeedback_0_bits_vaddr;
  assign eb_in_4_bits_vaNeedExt        = io_vecFeedback_0_bits_vaNeedExt;
  assign eb_in_4_bits_gpaddr           = {14'h0, io_vecFeedback_0_bits_gpaddr};
  assign eb_in_4_bits_isForVSnonLeafPTE= io_vecFeedback_0_bits_isForVSnonLeafPTE;
  assign eb_in_5_valid = io_vecFeedback_1_valid & io_vecFeedback_1_bits_feedback_0;
  assign eb_in_5_bits_uop_exceptionVec_3  = io_vecFeedback_1_bits_exceptionVec_3;
  assign eb_in_5_bits_uop_exceptionVec_6  = io_vecFeedback_1_bits_exceptionVec_6;
  assign eb_in_5_bits_uop_exceptionVec_7  = io_vecFeedback_1_bits_exceptionVec_7;
  assign eb_in_5_bits_uop_exceptionVec_15 = io_vecFeedback_1_bits_exceptionVec_15;
  assign eb_in_5_bits_uop_exceptionVec_19 = io_vecFeedback_1_bits_exceptionVec_19;
  assign eb_in_5_bits_uop_exceptionVec_23 = io_vecFeedback_1_bits_exceptionVec_23;
  assign eb_in_5_bits_uop_uopIdx       = io_vecFeedback_1_bits_uopidx;
  assign eb_in_5_bits_uop_robIdx_flag  = io_vecFeedback_1_bits_robidx_flag;
  assign eb_in_5_bits_uop_robIdx_value = io_vecFeedback_1_bits_robidx_value;
  assign eb_in_5_bits_fullva           = io_vecFeedback_1_bits_vaddr;
  assign eb_in_5_bits_vaNeedExt        = io_vecFeedback_1_bits_vaNeedExt;
  assign eb_in_5_bits_gpaddr           = {14'h0, io_vecFeedback_1_bits_gpaddr};
  assign eb_in_5_bits_isForVSnonLeafPTE= io_vecFeedback_1_bits_isForVSnonLeafPTE;

  // ---- port 6：mmioStout.fire → uncacheUop（fullva = vaddrModule.rdata(0)）----
  assign eb_in_6_valid = mmioStout_fire;
  assign eb_in_6_bits_uop_exceptionVec_19 = uncUop_excHwErr;
  assign eb_in_6_bits_uop_uopIdx       = uncUop_uopIdx;
  assign eb_in_6_bits_uop_robIdx_flag  = uncUop_robF;
  assign eb_in_6_bits_uop_robIdx_value = uncUop_robV;
  assign eb_in_6_bits_fullva           = {14'h0, va_rdata[0]};
