// 手写(从 CtrlBlock.scala 设计意图重写,非 golden 转写)。round4 散余 glue。
// ============================================================================
// CtrlBlock 散余 glue(与 decode/rename/memCtrl/redirectGen 黑盒强耦合的小逻辑):
//   (1) exuRedirect 选最旧:从 4 路携带 redirect 的写回(wbData[1/3/5/7])里筛出
//       「未被更老 redirect({s1_s3,s2_s4})冲掉」的有效项,做 4 路两两比较选最旧
//       (oldestOneHot),按 one-hot 选字段并打一拍 -> redirectGen.io.oldestExuRedirect。
//   (2) mdpFlodPcVec:内存依赖预测(MDP)折叠 PC 的有效拍 + foldpc 数据源选择,
//       送 memCtrl.io.mdpFoldPcVec*。
//   (3) decode 输入 foldpc 位变换:decode.io.in[k].bits.foldpc 在 decodeBuf 有效时取
//       buffer 内 foldpc,否则取 frontend cfVec foldpc(decode-buffer FSM 的 bits 分量)。
//
// 可读化:候选写回收进 exu_redir_cand_t struct;oldest 选择用纯函数 ptr 比较 + one-hot;
// 选字段用 one-hot 掩码或(等价 MuxOH);打拍用 RegEnable(整 struct)。
// 依赖核内已有信号:s1_s3_redirect_*(=io_redirect_*)、s2_s4_redirect_*、
//   wbInValid(块3 装包)、decodeBufValid(块2)。
// ============================================================================

  // ==========================================================================
  // (1) exuRedirect 选最旧
  // --------------------------------------------------------------------------
  // 候选 4 路固定取自 wbData 下标 {1,3,5,7}(jmp/brh 域写回口,携带 cfiUpdate)。
  // 每路「有效」= wbData[j].valid && redirect.valid && 该 redirect 真要改流
  //   (isMisPred | backendIGPF | backendIPF | backendIAF)
  //   && 未被更老 redirect 冲掉(needFlush 对 {s1_s3, s2_s4} 两级都为假)。
  // 注:needFlush 用本核 ctrlblock_pkg::rob_need_flush;redirect 自带的 robIdx 即
  //     该写回所属指令的 robIdx(redirect.bits.robIdx)。
  // ==========================================================================
  // 候选 4 路固定取自 wbData 下标 {1,3,5,7}(jmp/brh 域写回口,携带 cfiUpdate)。

  // decode.io.in[k].bits.foldpc(由 (3) 段计算,(2) 段提前引用,故前置声明)。
  wire [9:0] decodeInFoldpc [0:ctrlblock_pkg::DecodeWidth-1];

  // 携带 redirect 的写回候选(每路要选进 oldest 的全字段)。
  typedef struct packed {
    logic        robIdx_flag;
    logic [7:0]  robIdx_value;
    logic        ftqIdx_flag;
    logic [5:0]  ftqIdx_value;
    logic [3:0]  ftqOffset;
    logic        level;
    logic [49:0] cfiUpdate_pc;
    logic [49:0] cfiUpdate_target;
    logic        cfiUpdate_taken;
    logic        cfiUpdate_isMisPred;
    logic        cfiUpdate_backendIGPF;
    logic        cfiUpdate_backendIPF;
    logic        cfiUpdate_backendIAF;
    logic [63:0] fullTarget;
    logic        debugIsCtrl;
  } exu_redir_cand_t;

  exu_redir_cand_t exuRedirCand [0:3];
  logic            exuRedirValid [0:3];   // 该候选有效(已过滤被老 redirect 杀)

  // 装包:wbData[1/3/5/7].bits.redirect.bits.* -> exuRedirCand[c]。
  always_comb begin
    exuRedirCand[0] = '{
      robIdx_flag:           io_fromWB_wbData_1_bits_redirect_bits_robIdx_flag,
      robIdx_value:          io_fromWB_wbData_1_bits_redirect_bits_robIdx_value,
      ftqIdx_flag:           io_fromWB_wbData_1_bits_redirect_bits_ftqIdx_flag,
      ftqIdx_value:          io_fromWB_wbData_1_bits_redirect_bits_ftqIdx_value,
      ftqOffset:             io_fromWB_wbData_1_bits_redirect_bits_ftqOffset,
      level:                 io_fromWB_wbData_1_bits_redirect_bits_level,
      cfiUpdate_pc:          io_fromWB_wbData_1_bits_redirect_bits_cfiUpdate_pc,
      cfiUpdate_target:      io_fromWB_wbData_1_bits_redirect_bits_cfiUpdate_target,
      cfiUpdate_taken:       io_fromWB_wbData_1_bits_redirect_bits_cfiUpdate_taken,
      cfiUpdate_isMisPred:   io_fromWB_wbData_1_bits_redirect_bits_cfiUpdate_isMisPred,
      cfiUpdate_backendIGPF: io_fromWB_wbData_1_bits_redirect_bits_cfiUpdate_backendIGPF,
      cfiUpdate_backendIPF:  io_fromWB_wbData_1_bits_redirect_bits_cfiUpdate_backendIPF,
      cfiUpdate_backendIAF:  io_fromWB_wbData_1_bits_redirect_bits_cfiUpdate_backendIAF,
      fullTarget:            io_fromWB_wbData_1_bits_redirect_bits_fullTarget,
      debugIsCtrl:           1'b0 };
    exuRedirCand[1] = '{
      robIdx_flag:           io_fromWB_wbData_3_bits_redirect_bits_robIdx_flag,
      robIdx_value:          io_fromWB_wbData_3_bits_redirect_bits_robIdx_value,
      ftqIdx_flag:           io_fromWB_wbData_3_bits_redirect_bits_ftqIdx_flag,
      ftqIdx_value:          io_fromWB_wbData_3_bits_redirect_bits_ftqIdx_value,
      ftqOffset:             io_fromWB_wbData_3_bits_redirect_bits_ftqOffset,
      level:                 io_fromWB_wbData_3_bits_redirect_bits_level,
      cfiUpdate_pc:          io_fromWB_wbData_3_bits_redirect_bits_cfiUpdate_pc,
      cfiUpdate_target:      io_fromWB_wbData_3_bits_redirect_bits_cfiUpdate_target,
      cfiUpdate_taken:       io_fromWB_wbData_3_bits_redirect_bits_cfiUpdate_taken,
      cfiUpdate_isMisPred:   io_fromWB_wbData_3_bits_redirect_bits_cfiUpdate_isMisPred,
      cfiUpdate_backendIGPF: io_fromWB_wbData_3_bits_redirect_bits_cfiUpdate_backendIGPF,
      cfiUpdate_backendIPF:  io_fromWB_wbData_3_bits_redirect_bits_cfiUpdate_backendIPF,
      cfiUpdate_backendIAF:  io_fromWB_wbData_3_bits_redirect_bits_cfiUpdate_backendIAF,
      fullTarget:            io_fromWB_wbData_3_bits_redirect_bits_fullTarget,
      debugIsCtrl:           1'b0 };
    exuRedirCand[2] = '{
      robIdx_flag:           io_fromWB_wbData_5_bits_redirect_bits_robIdx_flag,
      robIdx_value:          io_fromWB_wbData_5_bits_redirect_bits_robIdx_value,
      ftqIdx_flag:           io_fromWB_wbData_5_bits_redirect_bits_ftqIdx_flag,
      ftqIdx_value:          io_fromWB_wbData_5_bits_redirect_bits_ftqIdx_value,
      ftqOffset:             io_fromWB_wbData_5_bits_redirect_bits_ftqOffset,
      level:                 io_fromWB_wbData_5_bits_redirect_bits_level,
      cfiUpdate_pc:          io_fromWB_wbData_5_bits_redirect_bits_cfiUpdate_pc,
      cfiUpdate_target:      io_fromWB_wbData_5_bits_redirect_bits_cfiUpdate_target,
      cfiUpdate_taken:       io_fromWB_wbData_5_bits_redirect_bits_cfiUpdate_taken,
      cfiUpdate_isMisPred:   io_fromWB_wbData_5_bits_redirect_bits_cfiUpdate_isMisPred,
      cfiUpdate_backendIGPF: io_fromWB_wbData_5_bits_redirect_bits_cfiUpdate_backendIGPF,
      cfiUpdate_backendIPF:  io_fromWB_wbData_5_bits_redirect_bits_cfiUpdate_backendIPF,
      cfiUpdate_backendIAF:  io_fromWB_wbData_5_bits_redirect_bits_cfiUpdate_backendIAF,
      fullTarget:            io_fromWB_wbData_5_bits_redirect_bits_fullTarget,
      debugIsCtrl:           1'b0 };
    exuRedirCand[3] = '{
      robIdx_flag:           io_fromWB_wbData_7_bits_redirect_bits_robIdx_flag,
      robIdx_value:          io_fromWB_wbData_7_bits_redirect_bits_robIdx_value,
      ftqIdx_flag:           io_fromWB_wbData_7_bits_redirect_bits_ftqIdx_flag,
      ftqIdx_value:          io_fromWB_wbData_7_bits_redirect_bits_ftqIdx_value,
      ftqOffset:             io_fromWB_wbData_7_bits_redirect_bits_ftqOffset,
      level:                 io_fromWB_wbData_7_bits_redirect_bits_level,
      cfiUpdate_pc:          io_fromWB_wbData_7_bits_redirect_bits_cfiUpdate_pc,
      cfiUpdate_target:      io_fromWB_wbData_7_bits_redirect_bits_cfiUpdate_target,
      cfiUpdate_taken:       io_fromWB_wbData_7_bits_redirect_bits_cfiUpdate_taken,
      cfiUpdate_isMisPred:   io_fromWB_wbData_7_bits_redirect_bits_cfiUpdate_isMisPred,
      cfiUpdate_backendIGPF: io_fromWB_wbData_7_bits_redirect_bits_cfiUpdate_backendIGPF,
      cfiUpdate_backendIPF:  io_fromWB_wbData_7_bits_redirect_bits_cfiUpdate_backendIPF,
      cfiUpdate_backendIAF:  io_fromWB_wbData_7_bits_redirect_bits_cfiUpdate_backendIAF,
      fullTarget:            io_fromWB_wbData_7_bits_redirect_bits_fullTarget,
      debugIsCtrl:           1'b0 };
  end

  // 候选有效:写回有效 && redirect 有效 && 真要改流 && 未被 {s1_s3,s2_s4} 杀。
  // 写回有效/redirect 各路:wbData[j].valid 与 redirect.valid 都是顶层端口。
  wire exuRedirRawValid [0:3];
  assign exuRedirRawValid[0] = io_fromWB_wbData_1_valid & io_fromWB_wbData_1_bits_redirect_valid;
  assign exuRedirRawValid[1] = io_fromWB_wbData_3_valid & io_fromWB_wbData_3_bits_redirect_valid;
  assign exuRedirRawValid[2] = io_fromWB_wbData_5_valid & io_fromWB_wbData_5_bits_redirect_valid;
  assign exuRedirRawValid[3] = io_fromWB_wbData_7_valid & io_fromWB_wbData_7_bits_redirect_valid;

  // 该 redirect 是否真要改流(任一改流原因置位)
  function automatic logic redir_changes_flow(input exu_redir_cand_t c);
    redir_changes_flow = c.cfiUpdate_isMisPred | c.cfiUpdate_backendIGPF
                       | c.cfiUpdate_backendIPF | c.cfiUpdate_backendIAF;
  endfunction

  // ★ 关键(round7):被老 redirect 杀的比较,「this」必须用该写回口 **自身的 robIdx**
  //   (io_fromWB_wbData_N_bits_robIdx_*),不是 redirect payload 的 robIdx
  //   (wbData_N_bits_redirect_bits_robIdx)。golden exuRedirects_N_valid 的
  //   _exuRedirects_out_valid_flushItself_T_5 取的是 {wbData_1_bits_robIdx_*},
  //   differentFlag/compare 也用 wbData_1_bits_robIdx vs redirect 输出 robIdx。
  //   旧版误用 redirect payload robIdx,导致杀条件错 → oldestExuRedirectValid 整拍翻
  //   (UT 探针 t=214000 抓到 oldestExuRedirValid g=0 i=1,为整 CtrlBlock 链当前最早分叉)。
  wire        wbRedirRobFlag  [0:3];
  wire [7:0]  wbRedirRobValue [0:3];
  assign wbRedirRobFlag[0]  = io_fromWB_wbData_1_bits_robIdx_flag;
  assign wbRedirRobValue[0] = io_fromWB_wbData_1_bits_robIdx_value;
  assign wbRedirRobFlag[1]  = io_fromWB_wbData_3_bits_robIdx_flag;
  assign wbRedirRobValue[1] = io_fromWB_wbData_3_bits_robIdx_value;
  assign wbRedirRobFlag[2]  = io_fromWB_wbData_5_bits_robIdx_flag;
  assign wbRedirRobValue[2] = io_fromWB_wbData_5_bits_robIdx_value;
  assign wbRedirRobFlag[3]  = io_fromWB_wbData_7_bits_robIdx_flag;
  assign wbRedirRobValue[3] = io_fromWB_wbData_7_bits_robIdx_value;

  generate
    for (gj = 0; gj < 4; gj++) begin : g_exuredir_valid
      // 未被 s1_s3、s2_s4 两级更老 redirect 冲掉(needFlush 都为假)。
      // this = 写回口自身 robIdx;redir = s1_s3 / s2_s4 redirect。
      wire killed_by_s1s3 = ctrlblock_pkg::rob_need_flush(
          wbRedirRobValue[gj], wbRedirRobFlag[gj],
          s1_s3_redirect_valid, s1_s3_redirect_robValue, s1_s3_redirect_robFlag,
          s1_s3_redirect_flushItself);
      wire killed_by_s2s4 = ctrlblock_pkg::rob_need_flush(
          wbRedirRobValue[gj], wbRedirRobFlag[gj],
          s2_s4_redirect_valid, s2_s4_redirect_robValue, s2_s4_redirect_robFlag,
          s2_s4_redirect_level);
      assign exuRedirValid[gj] = exuRedirRawValid[gj]
                               & redir_changes_flow(exuRedirCand[gj])
                               & ~killed_by_s1s3 & ~killed_by_s2s4;
    end
  endgenerate

  // oldest 选择(round7 priority-case + cand_older 基线;round8 复核仍最优)。
  // ── round8 实测记录(供下一轮)──
  // 在 robIdx 非全序(2+ 候选 robIdx 成环)时,golden 严格 onehot(&compareVec)「无人当选」
  // exuOldestValid=0,本 priority-case 仍选最低号 → 个别拍 g=0 i=1(EDUMP/EROOT 224000)。
  // round8 已修 snptValids X 馈入(见 glue4 C 段),并验证此分叉拍核 4 路候选 robIdx 与
  // golden compareVec 输入「逐位对齐」(EROOT:core cand c0=15f c1=100 c2=00c c3=199 == golden)。
  // 但严格复刻 golden resultOnehot 后整体仍大回退(232→798/seed1),说明分叉根因在 *其它拍*
  // 喂给 exuRedirCand 的 wbData payload 与 golden 不一致(priority-case 恰好掩盖),
  // 须先把 wbData_{1,3,5,7}.redirect.bits 全程对齐再回头收 onehot。故保留 priority-case 基线。
  // ── compareVec 直接从顶层 wbData redirect-payload 端口算(绕开 exuRedirCand struct)──
  // golden compareVec_i_j 第一操作数 = wbData 下标更小者(cand 号小)。
  // 位式:flag_lo ^ flag_hi ^ (value_lo > value_hi)。
  wire cv_1_0 = io_fromWB_wbData_1_bits_redirect_bits_robIdx_flag
              ^ io_fromWB_wbData_3_bits_redirect_bits_robIdx_flag
              ^ (io_fromWB_wbData_1_bits_redirect_bits_robIdx_value
                 > io_fromWB_wbData_3_bits_redirect_bits_robIdx_value);
  wire cv_2_0 = io_fromWB_wbData_1_bits_redirect_bits_robIdx_flag
              ^ io_fromWB_wbData_5_bits_redirect_bits_robIdx_flag
              ^ (io_fromWB_wbData_1_bits_redirect_bits_robIdx_value
                 > io_fromWB_wbData_5_bits_redirect_bits_robIdx_value);
  wire cv_2_1 = io_fromWB_wbData_3_bits_redirect_bits_robIdx_flag
              ^ io_fromWB_wbData_5_bits_redirect_bits_robIdx_flag
              ^ (io_fromWB_wbData_3_bits_redirect_bits_robIdx_value
                 > io_fromWB_wbData_5_bits_redirect_bits_robIdx_value);
  wire cv_3_0 = io_fromWB_wbData_1_bits_redirect_bits_robIdx_flag
              ^ io_fromWB_wbData_7_bits_redirect_bits_robIdx_flag
              ^ (io_fromWB_wbData_1_bits_redirect_bits_robIdx_value
                 > io_fromWB_wbData_7_bits_redirect_bits_robIdx_value);
  wire cv_3_1 = io_fromWB_wbData_3_bits_redirect_bits_robIdx_flag
              ^ io_fromWB_wbData_7_bits_redirect_bits_robIdx_flag
              ^ (io_fromWB_wbData_3_bits_redirect_bits_robIdx_value
                 > io_fromWB_wbData_7_bits_redirect_bits_robIdx_value);
  wire cv_3_2 = io_fromWB_wbData_5_bits_redirect_bits_robIdx_flag
              ^ io_fromWB_wbData_7_bits_redirect_bits_robIdx_flag
              ^ (io_fromWB_wbData_5_bits_redirect_bits_robIdx_value
                 > io_fromWB_wbData_7_bits_redirect_bits_robIdx_value);

  // 严格复刻 golden resultOnehot(robIdx 成环→无人当选 exuOldestValid=0)。
  logic [3:0] exuOldestOH;
  assign exuOldestOH[0] = exuRedirValid[0]
                        & (~exuRedirValid[1] | ~cv_1_0)
                        & (~exuRedirValid[2] | ~cv_2_0)
                        & (~exuRedirValid[3] | ~cv_3_0);
  assign exuOldestOH[1] = (~exuRedirValid[0] | cv_1_0)
                        & exuRedirValid[1]
                        & (~exuRedirValid[2] | ~cv_2_1)
                        & (~exuRedirValid[3] | ~cv_3_1);
  assign exuOldestOH[2] = (~exuRedirValid[0] | cv_2_0)
                        & (~exuRedirValid[1] | cv_2_1)
                        & exuRedirValid[2]
                        & (~exuRedirValid[3] | ~cv_3_2);
  assign exuOldestOH[3] = (~exuRedirValid[0] | cv_3_0)
                        & (~exuRedirValid[1] | cv_3_1)
                        & (~exuRedirValid[2] | cv_3_2)
                        & exuRedirValid[3];
  wire exuOldestValid = |exuOldestOH;

  // one-hot 选最旧候选(MuxOH:用 case 选,X 铁律下的安全选择)。
  exu_redir_cand_t exuOldestCand;
  always_comb begin
    unique case (exuOldestOH)
      4'b0001: exuOldestCand = exuRedirCand[0];
      4'b0010: exuOldestCand = exuRedirCand[1];
      4'b0100: exuOldestCand = exuRedirCand[2];
      4'b1000: exuOldestCand = exuRedirCand[3];
      default: exuOldestCand = '0;
    endcase
  end

  // RegEnable 打一拍(valid 复位 0;bits 在选中拍打):送 redirectGen.io.oldestExuRedirect。
  // ── cluster B(FM glue-partition 收口):组合 next 值严格复刻 golden if(_T_636) 块各字段 ──
  //   golden 各字段(见 golden line 16219..16338):
  //     robIdx/ftqIdx/ftqOffset/level/pc/target/taken/isMisPred/fullTarget = masked-OR 四路
  //       (onehot_i ? wbData_i.X : 0),onehot = {(&T_36),(&T_28),(&T_19),(&T_9)} = exuOldestOH;
  //     backendIGPF/IPF/IAF = 仅候选3((&T_36)=exuOldestOH[3]) & wbData_7.X(与选中候选无关);
  //     debugIsCtrl = OR 四 onehot = exuOldestValid(此块 en 下恒 1)。
  //   passing 字段(robIdx/ftqIdx/ftqOffset/level/target/taken/fullTarget)沿用 exuOldestCand
  //   (case-mux,FM 已证与 golden masked-OR 等价);仅对之前 failing 的
  //   cfiUpdate_pc/isMisPred/backendIGPF/IPF/IAF 显式复刻 golden 形态。
  //   ★单次整体寄存(oldestExuRedirectBits <= Next),不用「整struct再逐字段覆盖」(避免 FM 对
  //     同一 always_ff 内 whole-struct NBA + 部分字段 NBA 的 last-write 语义建模歧义)。
  logic            oldestExuRedirectValid;          // -> redirectGen.io_oldestExuRedirect_valid
  exu_redir_cand_t oldestExuRedirectBits;           // -> redirectGen.io_oldestExuRedirect_bits_*
  logic            oldestExuRedirectIsCSR;          // -> redirectGen.io_oldestExuRedirectIsCSR
  exu_redir_cand_t oldestExuRedirectNext;
  always_comb begin
    oldestExuRedirectNext = exuOldestCand;          // passing 字段(选中候选)先全取
    oldestExuRedirectNext.debugIsCtrl = 1'b1;        // = exuOldestValid(en 下恒 1)
    oldestExuRedirectNext.cfiUpdate_pc =
        (exuOldestOH[0] ? io_fromWB_wbData_1_bits_redirect_bits_cfiUpdate_pc : 50'h0)
      | (exuOldestOH[1] ? io_fromWB_wbData_3_bits_redirect_bits_cfiUpdate_pc : 50'h0)
      | (exuOldestOH[2] ? io_fromWB_wbData_5_bits_redirect_bits_cfiUpdate_pc : 50'h0)
      | (exuOldestOH[3] ? io_fromWB_wbData_7_bits_redirect_bits_cfiUpdate_pc : 50'h0);
    oldestExuRedirectNext.cfiUpdate_isMisPred =
        exuOldestOH[0] & io_fromWB_wbData_1_bits_redirect_bits_cfiUpdate_isMisPred
      | exuOldestOH[1] & io_fromWB_wbData_3_bits_redirect_bits_cfiUpdate_isMisPred
      | exuOldestOH[2] & io_fromWB_wbData_5_bits_redirect_bits_cfiUpdate_isMisPred
      | exuOldestOH[3] & io_fromWB_wbData_7_bits_redirect_bits_cfiUpdate_isMisPred;
    oldestExuRedirectNext.cfiUpdate_backendIGPF =
        exuOldestOH[3] & io_fromWB_wbData_7_bits_redirect_bits_cfiUpdate_backendIGPF;
    oldestExuRedirectNext.cfiUpdate_backendIPF =
        exuOldestOH[3] & io_fromWB_wbData_7_bits_redirect_bits_cfiUpdate_backendIPF;
    oldestExuRedirectNext.cfiUpdate_backendIAF =
        exuOldestOH[3] & io_fromWB_wbData_7_bits_redirect_bits_cfiUpdate_backendIAF;
  end
  // cluster F: oldestExuRedirect **valid** 异步复位对齐 golden
  //   redirectGen_io_oldestExuRedirect_valid_last_REG(block 10429);bits/IsCSR 留无复位
  //   对齐 golden oldestExuRedirect_bits_r_*/IsCSR_r(block 14400)。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) oldestExuRedirectValid <= 1'b0;
    else       oldestExuRedirectValid <= exuOldestValid;
  end
  always_ff @(posedge clock) begin
    if (exuOldestValid) begin
      oldestExuRedirectBits  <= oldestExuRedirectNext;
      // ★ round7:IsCSR = ~T9&~T19&~T28&T36 = 选中候选3(wbData_7,CSR)= oldestOneHot==4'b1000。
      oldestExuRedirectIsCSR <= (exuOldestOH == 4'b1000);
    end
  end

  // ==========================================================================
  // (2) mdpFlodPcVec:MDP 折叠 PC 有效拍 + foldpc 数据源
  // --------------------------------------------------------------------------
  //   vld[k]      = decodePipeRenameModule[k].in.ready && decode.out[k].valid
  //   vldLast[k]  = GatedValidRegNext(vld[k])  —— 上一拍补位(覆盖打拍边界)
  //   foldpc[k]   = vld[k] ? decode.in[k].bits.foldpc : decodePipeRenameModule[k].out.bits.foldpc
  // 送 memCtrl.io.mdpFoldPcVecVld_k = vld[k] | vldLast[k];io.mdpFlodPcVec_k = foldpc[k]。
  // 输入网由 inst.svh 绑定(decodePipeRename ready/out、decode out valid)。
  // ==========================================================================
  wire mdpVld [0:1];
  assign mdpVld[0] = _decodePipeRenameModule_io_in_ready   & _decode_io_out_0_valid;
  assign mdpVld[1] = _decodePipeRenameModule_1_io_in_ready & _decode_io_out_1_valid;
  reg  mdpVldLast [0:1];
  // cluster F: golden mdpFlodPcVecVld_0/1_last_REG 在**异步复位块**(golden line 10429/10522)
  //   → 异步复位对齐(同步复位会 failing)。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      mdpVldLast[0] <= 1'b0;
      mdpVldLast[1] <= 1'b0;
    end else begin
      mdpVldLast[0] <= mdpVld[0];
      mdpVldLast[1] <= mdpVld[1];
    end
  end
  wire        mdpFoldPcVecVld [0:1];
  wire [9:0]  mdpFoldPcVec    [0:1];
  assign mdpFoldPcVecVld[0] = mdpVld[0] | mdpVldLast[0];
  assign mdpFoldPcVecVld[1] = mdpVld[1] | mdpVldLast[1];
  // foldpc 源:有效拍取 decode.in[k].foldpc(下面 (3) 算),否则取 pipe.out.foldpc。
  assign mdpFoldPcVec[0] = mdpVld[0] ? decodeInFoldpc[0] : _decodePipeRenameModule_io_out_bits_foldpc;
  assign mdpFoldPcVec[1] = mdpVld[1] ? decodeInFoldpc[1] : _decodePipeRenameModule_1_io_out_bits_foldpc;

  // ==========================================================================
  // (3) decode 输入 foldpc 选择(取 decode-buffer bits 的 foldpc 分量)
  // --------------------------------------------------------------------------
  //   decodeInFoldpc[k] = decodeBufValid[k] ? decodeBufBits[k].foldpc : cfVec[k].foldpc
  // ==========================================================================
  //   golden(CtrlBlock.sv:9424-9427):
  //     _decode_io_in_k_bits_T_foldpc = decodeBufValid_k ? decodeBufBits_k_foldpc
  //                                                       : io_frontend_cfVec_k_bits_foldpc
  //   golden 只有 **一份** foldpc 寄存器 decodeBufBits_k_foldpc(块 always@14400,无 reset,
  //   随 buffer 移位由 _GEN_44/_GEN_78 8 深数组按 (acceptNum+k) 索引更新,idx 6/7 折回
  //   src[0]),同时供 decode.io_in_k.foldpc 与 mdpFlodPcVec_k。
  //   本核 decodeBufBits[k].foldpc 正是这一份(logic.svh 块2b 的 buf_shift_bits 移位,
  //   buf_shift_bits default=src[0] 精确复刻 _GEN_44/_GEN_78 idx6/7 wrap;已 FM 通过)。
  //   ⇒ 直接引用 decodeBufBits[k].foldpc,不另建冗余 decodeBufFoldpc 寄存器
  //     (旧版另存一份且带 hold-ternary + idx>=6 归零 → 与 golden _GEN_44 wrap-to-src[0]
  //      在 acceptNum 边界位级不一致,是 20 个 foldpc failing 的根因)。
  generate
    for (gj = 0; gj < ctrlblock_pkg::DecodeWidth; gj++) begin : g_decinfoldpc
      assign decodeInFoldpc[gj] = decodeBufValid[gj] ? decodeBufBits[gj].foldpc
                                                     : cfVecBits[gj].foldpc;
    end
  endgenerate
