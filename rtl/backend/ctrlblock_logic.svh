// 手写(从 CtrlBlock.scala 设计意图重写,非 golden 转写):scripts/gen_ctrlblock.py 后续接管机械部分。
// ============================================================================
// CtrlBlock 顶层 glue 可读重写(6 块)。索引/拍号沿用 Scala 注释:
//   T0: rob.flushOut / s0_robFlushRedirect
//   T1: s1_robFlushRedirect(GatedValidRegNext + RegEnable)
//   ...
//   T5: ctrlBlock.trapTarget;  T6: frontend.toFtq.stage2Redirect
// 子模块(Rob/RedirectGenerator/pcMem/Snapshot/DecodeStage/DelayN...)golden 黑盒,
// 输出网见 ctrlblock_decls.svh,本文件只写「顶层控制平面」逻辑。
// 类型/函数见 ctrlblock_pkg.sv(redirect_level_e / ptr_gt / rob_need_flush)。
// ============================================================================

  genvar gi;

  // ==========================================================================
  // 块 1:重定向流水 s0 -> s5
  // --------------------------------------------------------------------------
  //   s0_robFlushRedirect  = rob.io.flushOut(组合)
  //   s1_robFlushRedirect  = { GatedValidRegNext(valid), RegEnable(bits) }
  //   s1_robFlushPc        = pcMem[robFlush].startAddr + (RegEnable(ftqOffset)<<1)
  //   s3_redirectGen       = redirectGen.io.stage2Redirect
  //   s1_s3_redirect       = Mux(s1robFlush.valid, s1robFlush, s3_redirectGen)
  //   s2_s4_redirect       = RegNextWithEnable(s1_s3_redirect)
  //   s3_s5_redirect       = RegNextWithEnable(s2_s4_redirect)
  // ==========================================================================

  // -- s0:组合直取 rob flushOut --
  wire                  s0_robFlushValid    = _rob_io_flushOut_valid;
  wire [5:0]            s0_robFlushFtqValue = _rob_io_flushOut_bits_ftqIdx_value;
  wire [3:0]            s0_robFlushFtqOff   = _rob_io_flushOut_bits_ftqOffset;

  // -- s1:打一拍(valid 用 GatedValidRegNext=复位 0 的 RegNext;bits 用 RegEnable)--
  reg                   s1_robFlushValid;
  reg                   s1_robFlushRobFlag;
  reg  [7:0]            s1_robFlushRobValue;
  reg                   s1_robFlushLevel;       // 1=flushItself
  reg                   s1_robFlushIsRVC;
  reg                   s1_robFlushFtqFlag;
  reg  [5:0]            s1_robFlushFtqValue;
  reg  [3:0]            s1_robFlushFtqOff;
  always_ff @(posedge clock) begin
    if (reset) s1_robFlushValid <= 1'b0;
    else       s1_robFlushValid <= s0_robFlushValid;
    if (s0_robFlushValid) begin
      s1_robFlushRobFlag  <= _rob_io_flushOut_bits_robIdx_flag;
      s1_robFlushRobValue <= _rob_io_flushOut_bits_robIdx_value;
      s1_robFlushLevel    <= _rob_io_flushOut_bits_level;
      s1_robFlushIsRVC    <= _rob_io_flushOut_bits_isRVC;
      s1_robFlushFtqFlag  <= _rob_io_flushOut_bits_ftqIdx_flag;
      s1_robFlushFtqValue <= _rob_io_flushOut_bits_ftqIdx_value;
      s1_robFlushFtqOff   <= s0_robFlushFtqOff;
    end
  end

  // s1_robFlushPc:robFlush 读口 pcMem 数据 + (ftqOffset<<instOffsetBits)
  wire [ctrlblock_pkg::VAddrBits-1:0] s1_robFlushPc =
      _pcMem_io_rdata_2_startAddr +
      ({{(ctrlblock_pkg::VAddrBits-5){1'b0}}, s1_robFlushFtqOff} << ctrlblock_pkg::InstOffsetBits);

  // -- s1_s3_redirect:rob flush 优先,否则 redirectGen.stage2(X 铁律:三元 mux)--
  wire                  s1_s3_redirect_valid =
      s1_robFlushValid ? s1_robFlushValid : _redirectGen_io_stage2Redirect_valid;
  wire                  s1_s3_redirect_robFlag =
      s1_robFlushValid ? s1_robFlushRobFlag : _redirectGen_io_stage2Redirect_bits_robIdx_flag;
  wire [7:0]            s1_s3_redirect_robValue =
      s1_robFlushValid ? s1_robFlushRobValue : _redirectGen_io_stage2Redirect_bits_robIdx_value;
  wire                  s1_s3_redirect_level =
      s1_robFlushValid ? s1_robFlushLevel : _redirectGen_io_stage2Redirect_bits_level;
  wire                  s1_s3_redirect_ftqFlag =
      s1_robFlushValid ? s1_robFlushFtqFlag : _redirectGen_io_stage2Redirect_bits_ftqIdx_flag;
  wire [5:0]            s1_s3_redirect_ftqValue =
      s1_robFlushValid ? s1_robFlushFtqValue : _redirectGen_io_stage2Redirect_bits_ftqIdx_value;
  wire                  s1_s3_redirect_flushItself = s1_s3_redirect_level; // level==1

  // -- s2_s4 pending:s1_s3 有效置 1;io.frontend.toFtq.redirect 打一拍有效清 0 --
  reg                   s2_s4_pendingRedirectValid;
  reg                   frontendRedirectValidReg; // GatedValidRegNext(io.frontend.toFtq.redirect.valid)
  always_ff @(posedge clock) begin
    if (reset) frontendRedirectValidReg <= 1'b0;
    else       frontendRedirectValidReg <= frontend_toFtq_redirect_valid;
    if (reset)
      s2_s4_pendingRedirectValid <= 1'b0;
    else if (s1_s3_redirect_valid)
      s2_s4_pendingRedirectValid <= 1'b1;
    else if (frontendRedirectValidReg)
      s2_s4_pendingRedirectValid <= 1'b0;
  end

  // -- s2_s4_redirect = RegNextWithEnable(s1_s3_redirect):valid 复位 0,bits 在 valid 时打拍 --
  reg                   s2_s4_redirect_valid;
  reg                   s2_s4_redirect_robFlag;
  reg  [7:0]            s2_s4_redirect_robValue;
  reg                   s2_s4_redirect_level;
  always_ff @(posedge clock) begin
    if (reset) s2_s4_redirect_valid <= 1'b0;
    else       s2_s4_redirect_valid <= s1_s3_redirect_valid;
    if (s1_s3_redirect_valid) begin
      s2_s4_redirect_robFlag  <= s1_s3_redirect_robFlag;
      s2_s4_redirect_robValue <= s1_s3_redirect_robValue;
      s2_s4_redirect_level    <= s1_s3_redirect_level;
    end
  end

  // -- s3_s5_redirect = RegNextWithEnable(s2_s4_redirect)--
  reg                   s3_s5_redirect_valid;
  reg                   s3_s5_redirect_robFlag;
  reg  [7:0]            s3_s5_redirect_robValue;
  reg                   s3_s5_redirect_level;
  always_ff @(posedge clock) begin
    if (reset) s3_s5_redirect_valid <= 1'b0;
    else       s3_s5_redirect_valid <= s2_s4_redirect_valid;
    if (s2_s4_redirect_valid) begin
      s3_s5_redirect_robFlag  <= s2_s4_redirect_robFlag;
      s3_s5_redirect_robValue <= s2_s4_redirect_robValue;
      s3_s5_redirect_level    <= s2_s4_redirect_level;
    end
  end

  // ==========================================================================
  // 块 3:写回打拍 / 压缩(needFlush 杀掉被老 redirect 冲掉的写回)
  // --------------------------------------------------------------------------
  // delayedNotFlushedWriteBack[i].valid =
  //     GatedValidRegNext(wbData[i].valid && !killedByOlder)
  //   killedByOlder = wb.robIdx.needFlush({s1_s3, s2_s4})  (写回 valid 用两级 redirect)
  // delayedWriteBack[i].valid = GatedValidRegNext(wbData[i].valid)
  // writebackNums:对每路非 std 写回,统计同 robIdx 且都未被 {s1_s3,s2_s4,s3_s5} 冲掉的路数。
  // 这里写「killedByOlder 判定」与「打拍 valid」;同 robIdx 压缩计数与 bits 打拍逻辑量大,
  // 在 inst.svh 机械展开(本块给出判定函数化的 valid 流水)。
  // ==========================================================================
  // 每路写回的 killedByOlder(两级 redirect:s1_s3 + s2_s4)
  // wbData 路数 WbNum=27。robIdx 来自顶层 io_fromWB_wbData_<i>_bits_robIdx_*。
  // 注:本核仅声明判定信号;详细 bits 打拍在 inst.svh 连子模块前完成。
  // 注:WbNum=27 路写回中,有 robIdx 暴露到顶层的为 0..24 共 25 路(std fu 不暴露)。
  localparam int WbRobNum = 25;
  logic [WbRobNum-1:0] wbKilledByOlder;     // needFlush(s1_s3,s2_s4)
  logic [WbRobNum-1:0] wbKilledByOlder3;    // needFlush(s1_s3,s2_s4,s3_s5)
  generate
    for (gi = 0; gi < WbRobNum; gi++) begin : g_wbkill
      // wb robIdx 由 inst.svh 收口为数组 wbRobFlag/wbRobValue(顶层端口聚合)
      assign wbKilledByOlder[gi] =
          ctrlblock_pkg::rob_need_flush(wbRobValue[gi], wbRobFlag[gi],
              s1_s3_redirect_valid, s1_s3_redirect_robValue, s1_s3_redirect_robFlag,
              s1_s3_redirect_flushItself) ||
          ctrlblock_pkg::rob_need_flush(wbRobValue[gi], wbRobFlag[gi],
              s2_s4_redirect_valid, s2_s4_redirect_robValue, s2_s4_redirect_robFlag,
              s2_s4_redirect_level);
      assign wbKilledByOlder3[gi] =
          wbKilledByOlder[gi] ||
          ctrlblock_pkg::rob_need_flush(wbRobValue[gi], wbRobFlag[gi],
              s3_s5_redirect_valid, s3_s5_redirect_robValue, s3_s5_redirect_robFlag,
              s3_s5_redirect_level);
    end
  endgenerate

  // ==========================================================================
  // 块 4:快照选择(genSnapshot / snpt.enq-deq / useSnpt / snptSelect / flushVec)
  // --------------------------------------------------------------------------
  //   genSnapshot = OR( rename.out[i].fire && rename.out[i].snapshot )
  //   snpt.deq    = valids[deqPtr] && rob.commits.isCommit &&
  //                 OR( commitValid[c] && commitRobIdx[c]==snapshots[deqPtr].head )
  //   useSnpt     = OR over slots: valids[s] && ( (redir>snptHead && value!=) ||
  //                                   (!flushItself && redir==snptHead) )
  //   snptSelect  = MuxCase 选最近一个满足条件的槽(enqPtr-1, enqPtr-2, ...)
  //   flushVec[s] = s1_s3_redirect.valid && AND_over_renamewidth( shouldFlush | !isCFI )
  // ==========================================================================
  // genSnapshot 由 rename.out fire&snapshot 聚合,在 inst.svh 收口为 genSnapshot
  // (rename 黑盒输出);此处给出快照选择与 flush 判定。
  wire [ctrlblock_pkg::RenameSnapshotNum-1:0] snptValids = _snpt_io_valids;

  // 各槽 head robIdx
  logic        snptHeadFlag  [0:ctrlblock_pkg::RenameSnapshotNum-1];
  logic [7:0]  snptHeadValue [0:ctrlblock_pkg::RenameSnapshotNum-1];
  always_comb begin
    snptHeadFlag[0]  = _snpt_io_snapshots_0_robIdx_head_flag;
    snptHeadValue[0] = _snpt_io_snapshots_0_robIdx_head_value;
    snptHeadFlag[1]  = _snpt_io_snapshots_1_robIdx_head_flag;
    snptHeadValue[1] = _snpt_io_snapshots_1_robIdx_head_value;
    snptHeadFlag[2]  = _snpt_io_snapshots_2_robIdx_head_flag;
    snptHeadValue[2] = _snpt_io_snapshots_2_robIdx_head_value;
    snptHeadFlag[3]  = _snpt_io_snapshots_3_robIdx_head_flag;
    snptHeadValue[3] = _snpt_io_snapshots_3_robIdx_head_value;
  end

  // useSnpt:对每槽判断 redirectRobidx 是否落在该槽 head 之后(或同条且非 flushItself)
  wire                  redir_neq_head [0:ctrlblock_pkg::RenameSnapshotNum-1];
  wire                  snptMatch      [0:ctrlblock_pkg::RenameSnapshotNum-1];
  generate
    for (gi = 0; gi < ctrlblock_pkg::RenameSnapshotNum; gi++) begin : g_usesnpt
      // redir > head 且 value 不同  ||  (!flushItself && redir==head)
      assign redir_neq_head[gi] = (s1_s3_redirect_robValue != snptHeadValue[gi]);
      assign snptMatch[gi] = snptValids[gi] && (
          ( ctrlblock_pkg::ptr_gt(s1_s3_redirect_robFlag, s1_s3_redirect_robValue,
                                  snptHeadFlag[gi], snptHeadValue[gi])
            && redir_neq_head[gi] ) ||
          ( !s1_s3_redirect_flushItself
            && (s1_s3_redirect_robFlag == snptHeadFlag[gi])
            && (s1_s3_redirect_robValue == snptHeadValue[gi]) ) );
    end
  endgenerate
  wire                  useSnpt = |{snptMatch[3], snptMatch[2], snptMatch[1], snptMatch[0]};

  // snptSelect:MuxCase 按 (enqPtr-1, -2, -3, -4) 的环形槽序选第一个 snptMatch 的槽号。
  // priority case 实现优先级(X 铁律:优先级仲裁用 priority case)。
  wire [1:0]            snptIdx1 = _snpt_io_enqPtr_value - 2'd1;
  wire [1:0]            snptIdx2 = _snpt_io_enqPtr_value - 2'd2;
  wire [1:0]            snptIdx3 = _snpt_io_enqPtr_value - 2'd3;
  wire [1:0]            snptIdx4 = _snpt_io_enqPtr_value;          // enqPtr-4 模 4 == enqPtr
  reg  [1:0]            snptSelect;
  always_comb begin
    priority case (1'b1)
      snptMatch[snptIdx1]: snptSelect = snptIdx1;
      snptMatch[snptIdx2]: snptSelect = snptIdx2;
      snptMatch[snptIdx3]: snptSelect = snptIdx3;
      snptMatch[snptIdx4]: snptSelect = snptIdx4;
      default:             snptSelect = 2'd0;
    endcase
  end

  // flushVec[s]:整槽是否被本次 redirect 冲掉。
  //   per-uop「shouldFlush[k]」= robIdx[k] >= redirect.robIdx(环形比较):
  //       shouldFlush[k] = (flag[k] ^ redir.flag ^ (value[k] >= redir.value))
  //                        | (value[k] == redir.value)
  //   ★ 关键(round9 修):golden 用「前缀 OR」——第 k 条 uop 的冲刷判据是
  //     「0..k 条里有任一 shouldFlush」而非仅第 k 条自身;即一旦快照内某较早(或同位)
  //     uop 应被冲,其后所有 uop 都视为被冲。整槽 = AND_k( prefixOr(shouldFlush[0..k]) | ~isCFI[k] )。
  //     原实现漏了前缀 OR(只用 shouldFlush[k] 自身),导致个别拍 flushVec 偏差 -> 快照
  //     valids/enqPtr 偏 1 拍 -> rabCommits.isWalk 偏 1 拍 -> stallReason 透传瞬态。
  // 纯函数(redir flag/value 显式入参,不读非局部信号 -> 避免 FMR_VLOG-091)。
  function automatic logic should_flush_uop(
      input logic s_flag, input logic [7:0] s_value,
      input logic r_flag, input logic [7:0] r_value);
    logic ge;   // robIdx[k] >= redir.robIdx(环形 >=)
    ge = (s_flag ^ r_flag ^ (s_value >= r_value));
    should_flush_uop = ge | (s_value == r_value);
  endfunction

  // 单槽整体冲刷:6 条 uop 做前缀 OR(prefix),再与 ~isCFI 逐位或后整槽 AND。
  function automatic logic slot_flush(
      input logic        f0, input logic [7:0] v0, input logic c0,
      input logic        f1, input logic [7:0] v1, input logic c1,
      input logic        f2, input logic [7:0] v2, input logic c2,
      input logic        f3, input logic [7:0] v3, input logic c3,
      input logic        f4, input logic [7:0] v4, input logic c4,
      input logic        f5, input logic [7:0] v5, input logic c5,
      input logic        r_flag, input logic [7:0] r_value);  // redir robIdx
    logic sf0, sf1, sf2, sf3, sf4, sf5;       // 各 uop 自身 shouldFlush
    logic p0, p1, p2, p3, p4, p5;             // 前缀 OR:p[k] = OR(sf[0..k])
    sf0 = should_flush_uop(f0, v0, r_flag, r_value);  sf1 = should_flush_uop(f1, v1, r_flag, r_value);
    sf2 = should_flush_uop(f2, v2, r_flag, r_value);  sf3 = should_flush_uop(f3, v3, r_flag, r_value);
    sf4 = should_flush_uop(f4, v4, r_flag, r_value);  sf5 = should_flush_uop(f5, v5, r_flag, r_value);
    p0 = sf0;          p1 = p0 | sf1;  p2 = p1 | sf2;
    p3 = p2 | sf3;     p4 = p3 | sf4;  p5 = p4 | sf5;
    slot_flush = (p0 | ~c0) & (p1 | ~c1) & (p2 | ~c2)
               & (p3 | ~c3) & (p4 | ~c4) & (p5 | ~c5);
  endfunction

  // 每槽:redirect 有效 && slot_flush(该槽 6 条 uop 的 robIdx/isCFI)。
  logic [ctrlblock_pkg::RenameSnapshotNum-1:0] flushVec;
  always_comb begin
    flushVec = '0;
    flushVec[0] = s1_s3_redirect_valid & slot_flush(
      _snpt_io_snapshots_0_robIdx_flag[0], _snpt_io_snapshots_0_robIdx_value[0], _snpt_io_snapshots_0_isCFI[0],
      _snpt_io_snapshots_0_robIdx_flag[1], _snpt_io_snapshots_0_robIdx_value[1], _snpt_io_snapshots_0_isCFI[1],
      _snpt_io_snapshots_0_robIdx_flag[2], _snpt_io_snapshots_0_robIdx_value[2], _snpt_io_snapshots_0_isCFI[2],
      _snpt_io_snapshots_0_robIdx_flag[3], _snpt_io_snapshots_0_robIdx_value[3], _snpt_io_snapshots_0_isCFI[3],
      _snpt_io_snapshots_0_robIdx_flag[4], _snpt_io_snapshots_0_robIdx_value[4], _snpt_io_snapshots_0_isCFI[4],
      _snpt_io_snapshots_0_robIdx_flag[5], _snpt_io_snapshots_0_robIdx_value[5], _snpt_io_snapshots_0_isCFI[5],
      s1_s3_redirect_robFlag, s1_s3_redirect_robValue);
    flushVec[1] = s1_s3_redirect_valid & slot_flush(
      _snpt_io_snapshots_1_robIdx_flag[0], _snpt_io_snapshots_1_robIdx_value[0], _snpt_io_snapshots_1_isCFI[0],
      _snpt_io_snapshots_1_robIdx_flag[1], _snpt_io_snapshots_1_robIdx_value[1], _snpt_io_snapshots_1_isCFI[1],
      _snpt_io_snapshots_1_robIdx_flag[2], _snpt_io_snapshots_1_robIdx_value[2], _snpt_io_snapshots_1_isCFI[2],
      _snpt_io_snapshots_1_robIdx_flag[3], _snpt_io_snapshots_1_robIdx_value[3], _snpt_io_snapshots_1_isCFI[3],
      _snpt_io_snapshots_1_robIdx_flag[4], _snpt_io_snapshots_1_robIdx_value[4], _snpt_io_snapshots_1_isCFI[4],
      _snpt_io_snapshots_1_robIdx_flag[5], _snpt_io_snapshots_1_robIdx_value[5], _snpt_io_snapshots_1_isCFI[5],
      s1_s3_redirect_robFlag, s1_s3_redirect_robValue);
    flushVec[2] = s1_s3_redirect_valid & slot_flush(
      _snpt_io_snapshots_2_robIdx_flag[0], _snpt_io_snapshots_2_robIdx_value[0], _snpt_io_snapshots_2_isCFI[0],
      _snpt_io_snapshots_2_robIdx_flag[1], _snpt_io_snapshots_2_robIdx_value[1], _snpt_io_snapshots_2_isCFI[1],
      _snpt_io_snapshots_2_robIdx_flag[2], _snpt_io_snapshots_2_robIdx_value[2], _snpt_io_snapshots_2_isCFI[2],
      _snpt_io_snapshots_2_robIdx_flag[3], _snpt_io_snapshots_2_robIdx_value[3], _snpt_io_snapshots_2_isCFI[3],
      _snpt_io_snapshots_2_robIdx_flag[4], _snpt_io_snapshots_2_robIdx_value[4], _snpt_io_snapshots_2_isCFI[4],
      _snpt_io_snapshots_2_robIdx_flag[5], _snpt_io_snapshots_2_robIdx_value[5], _snpt_io_snapshots_2_isCFI[5],
      s1_s3_redirect_robFlag, s1_s3_redirect_robValue);
    flushVec[3] = s1_s3_redirect_valid & slot_flush(
      _snpt_io_snapshots_3_robIdx_flag[0], _snpt_io_snapshots_3_robIdx_value[0], _snpt_io_snapshots_3_isCFI[0],
      _snpt_io_snapshots_3_robIdx_flag[1], _snpt_io_snapshots_3_robIdx_value[1], _snpt_io_snapshots_3_isCFI[1],
      _snpt_io_snapshots_3_robIdx_flag[2], _snpt_io_snapshots_3_robIdx_value[2], _snpt_io_snapshots_3_isCFI[2],
      _snpt_io_snapshots_3_robIdx_flag[3], _snpt_io_snapshots_3_robIdx_value[3], _snpt_io_snapshots_3_isCFI[3],
      _snpt_io_snapshots_3_robIdx_flag[4], _snpt_io_snapshots_3_robIdx_value[4], _snpt_io_snapshots_3_isCFI[4],
      _snpt_io_snapshots_3_robIdx_flag[5], _snpt_io_snapshots_3_robIdx_value[5], _snpt_io_snapshots_3_isCFI[5],
      s1_s3_redirect_robFlag, s1_s3_redirect_robValue);
  end
  // flushVecNext = GatedValidRegNext(flushVec & valids)
  reg [ctrlblock_pkg::RenameSnapshotNum-1:0] flushVecNext;
  always_ff @(posedge clock) begin
    if (reset) flushVecNext <= '0;
    else       flushVecNext <= flushVec & snptValids;
  end

  // snpt.deq:valids[deqPtr] && rob.commits.isCommit && 任一提交 robIdx == 该槽 head
  reg                   snptHeadDeqFlag;
  reg  [7:0]            snptHeadDeqValue;
  always_comb begin
    case (_snpt_io_deqPtr_value)
      2'd0:    begin snptHeadDeqFlag = snptHeadFlag[0]; snptHeadDeqValue = snptHeadValue[0]; end
      2'd1:    begin snptHeadDeqFlag = snptHeadFlag[1]; snptHeadDeqValue = snptHeadValue[1]; end
      2'd2:    begin snptHeadDeqFlag = snptHeadFlag[2]; snptHeadDeqValue = snptHeadValue[2]; end
      default: begin snptHeadDeqFlag = snptHeadFlag[3]; snptHeadDeqValue = snptHeadValue[3]; end
    endcase
  end
  reg                   snptDeqValidSel;
  always_comb begin
    case (_snpt_io_deqPtr_value)
      2'd0:    snptDeqValidSel = snptValids[0];
      2'd1:    snptDeqValidSel = snptValids[1];
      2'd2:    snptDeqValidSel = snptValids[2];
      default: snptDeqValidSel = snptValids[3];
    endcase
  end
  wire                  commitMatchHead =
      (_rob_io_commits_commitValid[0] && (_rob_io_commits_robIdx_value_0 == snptHeadDeqValue) && (_rob_io_commits_robIdx_flag[0] == snptHeadDeqFlag)) ||
      (_rob_io_commits_commitValid[1] && (_rob_io_commits_robIdx_value_1 == snptHeadDeqValue) && (_rob_io_commits_robIdx_flag[1] == snptHeadDeqFlag)) ||
      (_rob_io_commits_commitValid[2] && (_rob_io_commits_robIdx_value_2 == snptHeadDeqValue) && (_rob_io_commits_robIdx_flag[2] == snptHeadDeqFlag)) ||
      (_rob_io_commits_commitValid[3] && (_rob_io_commits_robIdx_value_3 == snptHeadDeqValue) && (_rob_io_commits_robIdx_flag[3] == snptHeadDeqFlag)) ||
      (_rob_io_commits_commitValid[4] && (_rob_io_commits_robIdx_value_4 == snptHeadDeqValue) && (_rob_io_commits_robIdx_flag[4] == snptHeadDeqFlag)) ||
      (_rob_io_commits_commitValid[5] && (_rob_io_commits_robIdx_value_5 == snptHeadDeqValue) && (_rob_io_commits_robIdx_flag[5] == snptHeadDeqFlag));
  wire                  snptDeq = snptDeqValidSel && _rob_io_commits_isCommit && commitMatchHead;

  // ==========================================================================
  // 块 5:frontend flush 路由
  // --------------------------------------------------------------------------
  //   s5_flushFromRobValidAhead = DelayN(s1_robFlush.valid, 4)
  //   s6_flushFromRobValid      = GatedValidRegNext(s5_ahead)
  //   redirect.valid            = s6_flushFromRobValid || s3_redirectGen.valid
  //   redirect.bits             = Mux(s6, frontendFlushBits, s3_redirectGen.bits)
  //   ftqIdxSelOH.bits          = Cat(s6, stage2oldestOH & Fill(!s6))
  //   trap target               = Mux(s5_csrIsTrap, csr.trapTarget.pc, s2_robFlushPc)
  // ==========================================================================
  wire                  s5_flushFromRobValidAhead = _s5_flushFromRobValidAhead_delay_io_out;
  reg                   s6_flushFromRobValid;
  always_ff @(posedge clock) begin
    if (reset) s6_flushFromRobValid <= 1'b0;
    else       s6_flushFromRobValid <= s5_flushFromRobValidAhead;
  end
  // frontendFlushBits = RegEnable(s1_robFlush.bits, s1_robFlush.valid)
  reg                   feFlushRobFlag;
  reg  [7:0]            feFlushRobValue;
  reg                   feFlushFtqFlag;
  reg  [5:0]            feFlushFtqValue;
  always_ff @(posedge clock) begin
    if (s1_robFlushValid) begin
      feFlushRobFlag  <= s1_robFlushRobFlag;
      feFlushRobValue <= s1_robFlushRobValue;
      feFlushFtqFlag  <= s1_robFlushFtqFlag;
      feFlushFtqValue <= s1_robFlushFtqValue;
    end
  end

  // s2_robFlushPc = RegEnable( flushItself ? s1pc : s1pc + (isRVC?2:4), s1robFlush.valid )
  wire [ctrlblock_pkg::VAddrBits-1:0] s1_robFlushPcNext =
      s1_robFlushLevel ? s1_robFlushPc
                       : s1_robFlushPc + (s1_robFlushIsRVC ? {{(ctrlblock_pkg::VAddrBits-2){1'b0}}, 2'd2}
                                                           : {{(ctrlblock_pkg::VAddrBits-3){1'b0}}, 3'd4});
  reg  [ctrlblock_pkg::VAddrBits-1:0] s2_robFlushPc;
  always_ff @(posedge clock) begin
    if (s1_robFlushValid) s2_robFlushPc <= s1_robFlushPcNext;
  end

  // s5_csrIsTrap = DelayN(rob.exception.valid, 4);trap target 选择
  wire                  s5_csrIsTrap = _s5_csrIsTrap_delay_io_out;
  wire [ctrlblock_pkg::VAddrBits-1:0] flushTarget =
      s5_csrIsTrap ? io_robio_csr_trapTarget_pc[ctrlblock_pkg::VAddrBits-1:0] : s2_robFlushPc;
  wire                  s5_trapIAF  = s5_csrIsTrap ? io_robio_csr_trapTarget_raiseIAF  : 1'b0;
  wire                  s5_trapIPF  = s5_csrIsTrap ? io_robio_csr_trapTarget_raiseIPF  : 1'b0;
  wire                  s5_trapIGPF = s5_csrIsTrap ? io_robio_csr_trapTarget_raiseIGPF : 1'b0;

  // frontend.toFtq.redirect.valid / ftqIdxSelOH(送顶层 io)
  assign frontend_toFtq_redirect_valid = s6_flushFromRobValid | _redirectGen_io_stage2Redirect_valid;
  // 注:本配置 ftqIdxSelOH.valid 未在顶层暴露(golden 仅有 bits 端口),故只驱动 bits。
  // Cat(s6, stage2oldestOH & Fill(NumRedirect+1, !s6))  —— NumRedirect+1=2 路低位 + 1 位高位
  assign frontend_toFtq_ftqIdxSelOH_bits =
      { s6_flushFromRobValid,
        _redirectGen_io_stage2oldestOH[1:0] & {2{~s6_flushFromRobValid}} };

  // ==========================================================================
  // 块 2:decode buffer FSM
  // --------------------------------------------------------------------------
  //   decodeBufValid[6] / decodeBufBits[6](StaticInst,这里只跟踪 valid 与计数,
  //   bits 的搬移在 inst.svh 与 decode 输入连线处完成)。
  //   decodeBufNotAccept[i] = decodeBufValid[i] && !decode.in[i].ready
  //   decodeBufAcceptNum     = 第一个 notAccept 的下标(否则 DecodeWidth)
  //   decodeFromFrontendNotAccept[i] = decodeBufValid[0] || (cfVec[i].valid && !ready)
  //   decodeFromFrontendAcceptNum    = 第一个 notAccept 的下标
  //   decode.redirect = s1_s3_redirect.valid || s2_s4_pendingRedirectValid
  // ==========================================================================
  wire                  decodeRedirect = s1_s3_redirect_valid | s2_s4_pendingRedirectValid;

  reg  [ctrlblock_pkg::DecodeWidth-1:0] decodeBufValid;

  // notAccept 向量
  wire [ctrlblock_pkg::DecodeWidth-1:0] decodeBufNotAccept;
  wire [ctrlblock_pkg::DecodeWidth-1:0] decodeFromFrontendNotAccept;
  generate
    for (gi = 0; gi < ctrlblock_pkg::DecodeWidth; gi++) begin : g_notaccept
      assign decodeBufNotAccept[gi]          = decodeBufValid[gi] & ~_decode_io_in_ready[gi];
      assign decodeFromFrontendNotAccept[gi] = decodeBufValid[0] |
                                               (frontend_cfVec_valid[gi] & ~_decode_io_in_ready[gi]);
    end
  endgenerate

  // PriorityMuxDefault:返回第一个为 1 的下标,全 0 则 DecodeWidth。
  function automatic logic [2:0] first_set_idx(input logic [ctrlblock_pkg::DecodeWidth-1:0] v);
    first_set_idx = ctrlblock_pkg::DecodeWidth[2:0];
    for (int k = ctrlblock_pkg::DecodeWidth-1; k >= 0; k--)
      if (v[k]) first_set_idx = k[2:0];
  endfunction
  wire [2:0]            decodeBufAcceptNum          = first_set_idx(decodeBufNotAccept);
  wire [2:0]            decodeFromFrontendAcceptNum = first_set_idx(decodeFromFrontendNotAccept);

  // decodeBufValid 状态机(移位 + 接收计数);bits 搬移在 inst.svh 处理。
  // 每条:① redirect 或本条是最后一个被接收的 -> 0
  //       ② buf 内有效且 drop(i) 还有 notAccept -> (acceptNum>W-1-i)?0:buf[i+acceptNum]
  //       ③ buf[0] 空且 frontend drop(i) 还有 notAccept -> (feNum>W-1-i)?0:cfVec[i+feNum].valid
  // 用 priority case 表达三分支优先级(X 铁律)。
  wire [ctrlblock_pkg::DecodeWidth-1:0] bufNotAcceptDropOr;  // |drop(i)
  wire [ctrlblock_pkg::DecodeWidth-1:0] feNotAcceptDropOr;
  generate
    for (gi = 0; gi < ctrlblock_pkg::DecodeWidth; gi++) begin : g_dropor
      assign bufNotAcceptDropOr[gi] = |(decodeBufNotAccept >> gi);
      assign feNotAcceptDropOr[gi]  = |(decodeFromFrontendNotAccept >> gi);
    end
  endgenerate

  // 计算「移位源」:buf[i+acceptNum] / cfVec[i+feNum].valid。索引可能越界,用三元 mux 收口。
  // bufv 是 packed [W-1:0],变量位选不触发 ELAB-147(packed 选位静态在界);
  // 越界(idx>=W)取 0,用三元保留。
  function automatic logic buf_shift_src(
      input logic [ctrlblock_pkg::DecodeWidth-1:0] bufv,
      input logic [2:0] i, input logic [2:0] num);
    logic [2:0] idx;
    idx = i + num;
    buf_shift_src = (idx < ctrlblock_pkg::DecodeWidth[2:0]) ? bufv[idx] : 1'b0;
  endfunction

  integer di;
  always_ff @(posedge clock) begin
    if (reset) begin
      decodeBufValid <= '0;
    end else begin
      for (di = 0; di < ctrlblock_pkg::DecodeWidth; di = di + 1) begin
        // 分支判定(优先级:清零 > buf 移位 > frontend 接收;否则保持)
        if (decodeRedirect ||
            (decodeBufValid[0] && decodeBufValid[di] && _decode_io_in_ready[di]
             && ~(|(decodeBufNotAccept >> di)))) begin
          decodeBufValid[di] <= 1'b0;
        end else if (decodeBufValid[di] && bufNotAcceptDropOr[di]) begin
          decodeBufValid[di] <=
            (decodeBufAcceptNum > (ctrlblock_pkg::DecodeWidth[2:0] - 3'd1 - di[2:0])) ? 1'b0
              : buf_shift_src(decodeBufValid, di[2:0], decodeBufAcceptNum);
        end else if (!decodeBufValid[0] && feNotAcceptDropOr[di]) begin
          decodeBufValid[di] <=
            (decodeFromFrontendAcceptNum > (ctrlblock_pkg::DecodeWidth[2:0] - 3'd1 - di[2:0])) ? 1'b0
              : buf_shift_src(frontend_cfVec_valid, di[2:0], decodeFromFrontendAcceptNum);
        end
      end
    end
  end

  // --------------------------------------------------------------------------
  // 块 2b:decode buffer payload(decodeBufBits)移位状态机
  // --------------------------------------------------------------------------
  //   payload 与 decodeBufValid 用同一套「接收计数 + 左移」规则,只是搬移的是整条
  //   CtrlFlow(decode_buf_bits_t)而非 1 bit valid。两条移位路径:
  //     ① 从 buffer 内部左移(bufHeadHasNotAccept:buffer 头有效且仍有 notAccept):
  //          decodeBufBits[i] <= decodeBufBits[(i+decodeBufAcceptNum) 取低 3 位]
  //        (lane-wrap 表:idx 0..5→lane idx,6/7→lane0;由 buf_shift_bits 实现)
  //     ② 从 frontend 装载(frontendLoadFromFE:buffer 头空且 frontend 有 notAccept):
  //          decodeBufBits[i] <= cfVecBits[(i+decodeFromFrontendAcceptNum) 取低 3 位]
  //        其中 frontend 不提供的异常位(exceptionVec 除 1/2/12/20 外)在装载时清 0。
  //     ③ 二者皆否:保持(buffer 内字段不变)。
  //   注:isFetchMalAddr 的 frontend 源是 cfVec.backendException。
  //   X 铁律:索引越界用「取低 3 位 + 三元 mux」收口,不产生 X。
  //   (搬移/装载用块 2 的 per-lane 条件 bufNotAcceptDropOr[i]/feNotAcceptDropOr[i],见下方 always。)

  // 把一条 frontend cfVec 装进 decode_buf_bits_t(frontend 不提供的异常位置 0)。
  // isFetchMalAddr 取自 cfVec.backendException;preDecodeInfo/pred 取自 cfVec.pd_*/pred_*。
  function automatic ctrlblock_pkg::decode_buf_bits_t pack_cfvec(
      input logic [31:0] instr,  input logic [9:0] foldpc,
      input logic exc1, input logic exc2, input logic exc12, input logic exc20,
      input logic backendException, input logic [3:0] trigger,
      input logic pdIsRVC, input logic [1:0] pdBrType, input logic predTaken,
      input logic crossPageIPFFix, input logic ftqFlag, input logic [5:0] ftqValue,
      input logic [3:0] ftqOffset, input logic isLastInFtqEntry);
    ctrlblock_pkg::decode_buf_bits_t b;
    b = '0;                       // 默认全 0(frontend 不提供的异常位/位 3,22 即 0)
    b.instr               = instr;
    b.foldpc              = foldpc;
    b.exceptionVec[1]     = exc1;
    b.exceptionVec[2]     = exc2;
    b.exceptionVec[12]    = exc12;
    b.exceptionVec[20]    = exc20;
    b.isFetchMalAddr      = backendException;
    b.trigger             = trigger;
    b.preDecodeInfo_isRVC = pdIsRVC;
    b.preDecodeInfo_brType= pdBrType;
    b.pred_taken          = predTaken;
    b.crossPageIPFFix     = crossPageIPFFix;
    b.ftqPtr_flag         = ftqFlag;
    b.ftqPtr_value        = ftqValue;
    b.ftqOffset           = ftqOffset;
    b.isLastInFtqEntry    = isLastInFtqEntry;
    pack_cfvec = b;
  endfunction

  // 把每条 frontend cfVec 装进 decode_buf_bits_t(frontend 缺的异常位置 0)。
  ctrlblock_pkg::decode_buf_bits_t cfVecBits [0:ctrlblock_pkg::DecodeWidth-1];
  assign cfVecBits[0] = pack_cfvec(
      io_frontend_cfVec_0_bits_instr, io_frontend_cfVec_0_bits_foldpc,
      io_frontend_cfVec_0_bits_exceptionVec_1, io_frontend_cfVec_0_bits_exceptionVec_2,
      io_frontend_cfVec_0_bits_exceptionVec_12, io_frontend_cfVec_0_bits_exceptionVec_20,
      io_frontend_cfVec_0_bits_backendException, io_frontend_cfVec_0_bits_trigger,
      io_frontend_cfVec_0_bits_pd_isRVC, io_frontend_cfVec_0_bits_pd_brType,
      io_frontend_cfVec_0_bits_pred_taken, io_frontend_cfVec_0_bits_crossPageIPFFix,
      io_frontend_cfVec_0_bits_ftqPtr_flag, io_frontend_cfVec_0_bits_ftqPtr_value,
      io_frontend_cfVec_0_bits_ftqOffset, io_frontend_cfVec_0_bits_isLastInFtqEntry);
  assign cfVecBits[1] = pack_cfvec(
      io_frontend_cfVec_1_bits_instr, io_frontend_cfVec_1_bits_foldpc,
      io_frontend_cfVec_1_bits_exceptionVec_1, io_frontend_cfVec_1_bits_exceptionVec_2,
      io_frontend_cfVec_1_bits_exceptionVec_12, io_frontend_cfVec_1_bits_exceptionVec_20,
      io_frontend_cfVec_1_bits_backendException, io_frontend_cfVec_1_bits_trigger,
      io_frontend_cfVec_1_bits_pd_isRVC, io_frontend_cfVec_1_bits_pd_brType,
      io_frontend_cfVec_1_bits_pred_taken, io_frontend_cfVec_1_bits_crossPageIPFFix,
      io_frontend_cfVec_1_bits_ftqPtr_flag, io_frontend_cfVec_1_bits_ftqPtr_value,
      io_frontend_cfVec_1_bits_ftqOffset, io_frontend_cfVec_1_bits_isLastInFtqEntry);
  assign cfVecBits[2] = pack_cfvec(
      io_frontend_cfVec_2_bits_instr, io_frontend_cfVec_2_bits_foldpc,
      io_frontend_cfVec_2_bits_exceptionVec_1, io_frontend_cfVec_2_bits_exceptionVec_2,
      io_frontend_cfVec_2_bits_exceptionVec_12, io_frontend_cfVec_2_bits_exceptionVec_20,
      io_frontend_cfVec_2_bits_backendException, io_frontend_cfVec_2_bits_trigger,
      io_frontend_cfVec_2_bits_pd_isRVC, io_frontend_cfVec_2_bits_pd_brType,
      io_frontend_cfVec_2_bits_pred_taken, io_frontend_cfVec_2_bits_crossPageIPFFix,
      io_frontend_cfVec_2_bits_ftqPtr_flag, io_frontend_cfVec_2_bits_ftqPtr_value,
      io_frontend_cfVec_2_bits_ftqOffset, io_frontend_cfVec_2_bits_isLastInFtqEntry);
  assign cfVecBits[3] = pack_cfvec(
      io_frontend_cfVec_3_bits_instr, io_frontend_cfVec_3_bits_foldpc,
      io_frontend_cfVec_3_bits_exceptionVec_1, io_frontend_cfVec_3_bits_exceptionVec_2,
      io_frontend_cfVec_3_bits_exceptionVec_12, io_frontend_cfVec_3_bits_exceptionVec_20,
      io_frontend_cfVec_3_bits_backendException, io_frontend_cfVec_3_bits_trigger,
      io_frontend_cfVec_3_bits_pd_isRVC, io_frontend_cfVec_3_bits_pd_brType,
      io_frontend_cfVec_3_bits_pred_taken, io_frontend_cfVec_3_bits_crossPageIPFFix,
      io_frontend_cfVec_3_bits_ftqPtr_flag, io_frontend_cfVec_3_bits_ftqPtr_value,
      io_frontend_cfVec_3_bits_ftqOffset, io_frontend_cfVec_3_bits_isLastInFtqEntry);
  assign cfVecBits[4] = pack_cfvec(
      io_frontend_cfVec_4_bits_instr, io_frontend_cfVec_4_bits_foldpc,
      io_frontend_cfVec_4_bits_exceptionVec_1, io_frontend_cfVec_4_bits_exceptionVec_2,
      io_frontend_cfVec_4_bits_exceptionVec_12, io_frontend_cfVec_4_bits_exceptionVec_20,
      io_frontend_cfVec_4_bits_backendException, io_frontend_cfVec_4_bits_trigger,
      io_frontend_cfVec_4_bits_pd_isRVC, io_frontend_cfVec_4_bits_pd_brType,
      io_frontend_cfVec_4_bits_pred_taken, io_frontend_cfVec_4_bits_crossPageIPFFix,
      io_frontend_cfVec_4_bits_ftqPtr_flag, io_frontend_cfVec_4_bits_ftqPtr_value,
      io_frontend_cfVec_4_bits_ftqOffset, io_frontend_cfVec_4_bits_isLastInFtqEntry);
  assign cfVecBits[5] = pack_cfvec(
      io_frontend_cfVec_5_bits_instr, io_frontend_cfVec_5_bits_foldpc,
      io_frontend_cfVec_5_bits_exceptionVec_1, io_frontend_cfVec_5_bits_exceptionVec_2,
      io_frontend_cfVec_5_bits_exceptionVec_12, io_frontend_cfVec_5_bits_exceptionVec_20,
      io_frontend_cfVec_5_bits_backendException, io_frontend_cfVec_5_bits_trigger,
      io_frontend_cfVec_5_bits_pd_isRVC, io_frontend_cfVec_5_bits_pd_brType,
      io_frontend_cfVec_5_bits_pred_taken, io_frontend_cfVec_5_bits_crossPageIPFFix,
      io_frontend_cfVec_5_bits_ftqPtr_flag, io_frontend_cfVec_5_bits_ftqPtr_value,
      io_frontend_cfVec_5_bits_ftqOffset, io_frontend_cfVec_5_bits_isLastInFtqEntry);

  // payload 寄存器(供 inst.svh 的 decode 输入连线引用)
  ctrlblock_pkg::decode_buf_bits_t decodeBufBits [0:ctrlblock_pkg::DecodeWidth-1];

  // 移位源选择:从 src 数组取「(i+num) 取低 3 位」lane(6/7 折回 lane0,越界 lane 取 0 项)。
  // idx = i+num,越界(>=DecodeWidth)取 src[0]。用显式 case 选源(非变量索引),
  // 避免 FMR_ELAB-147「索引可能越界」(变量 array[idx] 在 idx 3-bit/src 6 深时静态判越界)。
  function automatic ctrlblock_pkg::decode_buf_bits_t buf_shift_bits(
      input ctrlblock_pkg::decode_buf_bits_t src [0:ctrlblock_pkg::DecodeWidth-1],
      input logic [2:0] i, input logic [2:0] num);
    logic [2:0] idx;
    idx = 3'((i + num));                 // golden 用 3-bit 索引(自然取低 3 位)
    unique case (idx)
      3'd0:    buf_shift_bits = src[0];
      3'd1:    buf_shift_bits = src[1];
      3'd2:    buf_shift_bits = src[2];
      3'd3:    buf_shift_bits = src[3];
      3'd4:    buf_shift_bits = src[4];
      3'd5:    buf_shift_bits = src[5];
      default: buf_shift_bits = src[0];   // idx>=6 越界:取 src[0](同 golden)
    endcase
  endfunction

  integer dbi;
  always_ff @(posedge clock) begin
    // 注:golden 此状态机无 reset 分支(payload 随 valid 失效自然无意义),与之一致。
    // ★ 关键:bits 的搬移/装载条件必须是「逐 lane」的(与 valid FSM 块 2 同),不能用
    //   全局的 bufHeadHasNotAccept/frontendLoadFromFE。golden 每条 decodeBufBits_i 的
    //   if(_GEN_{shift_i})/(_GEN_{load_i}) 用的是 per-lane 条件:
    //     shift_i = decodeBufValid[i] & |decodeBufNotAccept[W-1:i]   (= bufNotAcceptDropOr[i])
    //     load_i  = ~decodeBufValid[0] & |decodeFromFrontendNotAccept[W-1:i] (= feNotAcceptDropOr[i])
    //   旧版用全局条件会把搬移/装载结果写进本应保持的高 lane(如 lane4/5),导致 stale
    //   instr 残留 → 影响 DecodeStage 的 complexNum/ready。UT round7 探针在 t=174000
    //   抓到 decodeBufBits_4/5_instr 分叉(此为整条 CtrlBlock 第一处分叉)。
    for (dbi = 0; dbi < ctrlblock_pkg::DecodeWidth; dbi = dbi + 1) begin
      if (decodeBufValid[dbi] && bufNotAcceptDropOr[dbi]) begin
        // ① buffer 内左移(本 lane 有效且 [i..] 仍有 notAccept):从 (i+acceptNum) lane 搬来
        decodeBufBits[dbi] <= buf_shift_bits(decodeBufBits, dbi[2:0], decodeBufAcceptNum);
      end else if (!decodeBufValid[0] && feNotAcceptDropOr[dbi]) begin
        // ② 从 frontend 装载(buffer 头空且 [i..] frontend 仍有 notAccept):
        //    frontend 提供的字段从 cfVec 取;buffer 比 frontend 多出的异常位(exceptionVec
        //    除 1/2/12/20 外)由 pack_cfvec 已置 0,整条覆盖即等价 golden「present 装载+其余清 0」。
        decodeBufBits[dbi] <= buf_shift_bits(cfVecBits, dbi[2:0], decodeFromFrontendAcceptNum);
      end
      // ③ 二者皆否:保持(buffer 内字段不变,buffer-only 异常位保持旧值)。
    end
  end

  // io.frontend.canAccept = !decodeBufValid(0) || !cfVec(0).valid
  assign frontend_canAccept = ~decodeBufValid[0] | ~frontend_cfVec_valid[0];
