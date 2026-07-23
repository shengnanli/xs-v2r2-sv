// 手写(从 CtrlBlock.scala 设计意图重写,非 golden 转写)。round6 补:剩余小 glue。
// ============================================================================
// 本文件汇总 inst.svh 子模块引脚还会引用、但前面 glue 文件尚未产出的「核内具名信号」:
//   (1) CSR 控制位打一拍：送 decode/rename/dispatch 的 singleStep/fusion/wfi 使能。
//   (2) loadReplay 打一拍：访存违例(load 重放)重定向请求锁存,送 redirectGen。
//   (3) instrAddrTransType 打一拍：CSR 地址翻译模式(satp mode)锁存,送 redirectGen。
//   (4) loadRedirectPcRead：loadReplay 的 cfiUpdate pc/target = pcMem 读口0 + ftqOffset。
//   (5) fusion 覆盖：融合译码命中时覆盖送 rename 的 fuType/fuOpType(5 lane)。
//   (6) 别名：x15(=decode flush)、loadRedirectPcFtqOffset、oldestExuRedirect 别名说明。
// 全部可读 + 中文注释;X 铁律:三元 mux。依赖的子模块输出网见 ctrlblock_decls.svh。
// ============================================================================

  // ==========================================================================
  // (1) CSR 控制位打一拍(RegNext 顶层 io_csrCtrl_*)
  //     singleStep 同时送 rename / dispatch;fusion_enable / wfi_enable / singlestep 送 decode。
  // --------------------------------------------------------------------------
  reg renameSingleStepR;     // -> rename.io.singleStep
  reg dispatchSingleStepR;   // -> dispatch.io.singleStep
  reg decodeCsrSinglestepR;  // -> decode.io.csrCtrl.singlestep
  reg decodeCsrFusionEnR;    // -> decode.io.csrCtrl.fusion_enable
  reg decodeCsrWfiEnR;       // -> decode.io.csrCtrl.wfi_enable
  // golden rename_io_singleStep_last_REG / dispatch_io_singleStep_last_REG 在异步复位块;
  // decode 侧 csrCtrl 三个打拍寄存器无复位(每拍无条件写)。拆两块对齐 golden 复位域。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      renameSingleStepR   <= 1'b0;
      dispatchSingleStepR <= 1'b0;
    end else begin
      renameSingleStepR   <= io_csrCtrl_singlestep;
      dispatchSingleStepR <= io_csrCtrl_singlestep;
    end
  end
  always_ff @(posedge clock) begin
    decodeCsrSinglestepR <= io_csrCtrl_singlestep;
    decodeCsrFusionEnR   <= io_csrCtrl_fusion_enable;
    decodeCsrWfiEnR      <= io_csrCtrl_wfi_enable;
  end

  // ==========================================================================
  // (2) loadReplay 打一拍:来自访存(LoadUnit)的违例重放重定向请求,锁存一拍后送 redirectGen。
  //     valid = RegNext(io.fromMem.violation.valid);bits = RegEnable(violation.bits, valid)。
  // --------------------------------------------------------------------------
  reg        loadReplayValidR;
  reg        loadReplayRobFlag;
  reg [7:0]  loadReplayRobValue;
  reg        loadReplayFtqFlag;
  reg [5:0]  loadReplayFtqValue;
  reg [3:0]  loadReplayFtqOffset;
  reg        loadReplayLevel;
  // loadRedirectPcFtqOffset:违例 pc 在 ftq 内的字节偏移(ftqOffset*2 再按 RVC/常规补偏移)。
  reg [5:0]  loadRedirectPcFtqOffset;
  // golden loadReplay_valid_last_REG 在异步复位块;bits 无复位 RegEnable。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) loadReplayValidR <= 1'b0;
    else       loadReplayValidR <= io_fromMem_violation_valid;
  end
  always_ff @(posedge clock) begin
    if (io_fromMem_violation_valid) begin
      loadReplayRobFlag   <= io_fromMem_violation_bits_robIdx_flag;
      loadReplayRobValue  <= io_fromMem_violation_bits_robIdx_value;
      loadReplayFtqFlag   <= io_fromMem_violation_bits_ftqIdx_flag;
      loadReplayFtqValue  <= io_fromMem_violation_bits_ftqIdx_value;
      loadReplayFtqOffset <= io_fromMem_violation_bits_ftqOffset;
      loadReplayLevel     <= io_fromMem_violation_bits_level;
      // ftqOffset<<1 + (flushItself? 0 : isRVC? 2 : 4)
      loadRedirectPcFtqOffset <=
          6'({1'b0, io_fromMem_violation_bits_ftqOffset, 1'b0}
             + {3'b0, (io_fromMem_violation_bits_level ? 3'h0
                       : io_fromMem_violation_bits_isRVC ? 3'h2 : 3'h4)});
    end
  end

  // ==========================================================================
  // (3) instrAddrTransType 打一拍:CSR 的取指地址翻译模式(satp/vsatp mode),送 redirectGen。
  // --------------------------------------------------------------------------
  reg instrTransBareR, instrTransSv39R, instrTransSv39x4R, instrTransSv48R, instrTransSv48x4R;
  always_ff @(posedge clock) begin
    instrTransBareR   <= io_fromCSR_instrAddrTransType_bare;
    instrTransSv39R   <= io_fromCSR_instrAddrTransType_sv39;
    instrTransSv39x4R <= io_fromCSR_instrAddrTransType_sv39x4;
    instrTransSv48R   <= io_fromCSR_instrAddrTransType_sv48;
    instrTransSv48x4R <= io_fromCSR_instrAddrTransType_sv48x4;
  end

  // ==========================================================================
  // (4) loadRedirectPcRead:loadReplay 的 cfiUpdate.pc / target = pcMem 读口0(redirect 口)
  //     的 startAddr + loadRedirectPcFtqOffset。送 redirectGen.io.loadReplay.bits.cfiUpdate.*。
  // --------------------------------------------------------------------------
  wire [49:0] loadRedirectPcRead =
      50'(_pcMem_io_rdata_0_startAddr + {44'h0, loadRedirectPcFtqOffset});

  // ==========================================================================
  // (5) fusion 覆盖:decodePipeRename 输出 -> rename 输入,融合命中时覆盖 fuType/fuOpType。
  //     fuType:融合时取「已融合」特殊码 35'h80,否则透传 pipeRename.out.fuType。
  //     fuOpType:融合时取融合译码给的 opType,否则透传 pipeRename.out.fuOpType。
  //     5 lane(0..4);lane5 无融合直接透传(由 inst.svh 直连)。
  // --------------------------------------------------------------------------
  wire [34:0] renameInFuType   [0:4];
  wire [8:0]  renameInFuOpType [0:4];
  // lane 0
  assign renameInFuType[0]   = (_fusionDecoder_io_out_0_valid & _fusionDecoder_io_out_0_bits_fuType_valid)
                               ? 35'h80 : _decodePipeRenameModule_io_out_bits_fuType;
  assign renameInFuOpType[0] = (_fusionDecoder_io_out_0_valid & _fusionDecoder_io_out_0_bits_fuOpType_valid)
                               ? _fusionDecoder_io_out_0_bits_fuOpType_bits : _decodePipeRenameModule_io_out_bits_fuOpType;
  // lane 1
  assign renameInFuType[1]   = (_fusionDecoder_io_out_1_valid & _fusionDecoder_io_out_1_bits_fuType_valid)
                               ? 35'h80 : _decodePipeRenameModule_1_io_out_bits_fuType;
  assign renameInFuOpType[1] = (_fusionDecoder_io_out_1_valid & _fusionDecoder_io_out_1_bits_fuOpType_valid)
                               ? _fusionDecoder_io_out_1_bits_fuOpType_bits : _decodePipeRenameModule_1_io_out_bits_fuOpType;
  // lane 2
  assign renameInFuType[2]   = (_fusionDecoder_io_out_2_valid & _fusionDecoder_io_out_2_bits_fuType_valid)
                               ? 35'h80 : _decodePipeRenameModule_2_io_out_bits_fuType;
  assign renameInFuOpType[2] = (_fusionDecoder_io_out_2_valid & _fusionDecoder_io_out_2_bits_fuOpType_valid)
                               ? _fusionDecoder_io_out_2_bits_fuOpType_bits : _decodePipeRenameModule_2_io_out_bits_fuOpType;
  // lane 3
  assign renameInFuType[3]   = (_fusionDecoder_io_out_3_valid & _fusionDecoder_io_out_3_bits_fuType_valid)
                               ? 35'h80 : _decodePipeRenameModule_3_io_out_bits_fuType;
  assign renameInFuOpType[3] = (_fusionDecoder_io_out_3_valid & _fusionDecoder_io_out_3_bits_fuOpType_valid)
                               ? _fusionDecoder_io_out_3_bits_fuOpType_bits : _decodePipeRenameModule_3_io_out_bits_fuOpType;
  // lane 4
  assign renameInFuType[4]   = (_fusionDecoder_io_out_4_valid & _fusionDecoder_io_out_4_bits_fuType_valid)
                               ? 35'h80 : _decodePipeRenameModule_4_io_out_bits_fuType;
  assign renameInFuOpType[4] = (_fusionDecoder_io_out_4_valid & _fusionDecoder_io_out_4_bits_fuOpType_valid)
                               ? _fusionDecoder_io_out_4_bits_fuOpType_bits : _decodePipeRenameModule_4_io_out_bits_fuOpType;

  // ==========================================================================
  // (6) 杂项别名
  // --------------------------------------------------------------------------
  // decode/dispatch 的 flush(redirect)输入:本拍重定向有效或仍有 pending 重定向。
  // 等价 golden x15 = io_redirect_valid_0 | s2_s4_pendingRedirectValid。
  wire decodeFlush = s1_s3_redirect_valid | s2_s4_pendingRedirectValid;

  // ==========================================================================
  // (7) fusion 触发反馈:送回 decode.io.fusion[k] = fusionDecoder.out[k].valid & 该 lane 真前进。
  //     「真前进」decodeFusionAdv[k] = renamePipeDispatch.in[k].ready & rename.out[k].valid。
  //     5 lane(0..4)。inst.svh 把 decode.io.fusion_k 连 fusionDecoder.out_k.valid & decodeFusionAdv[k]。
  // --------------------------------------------------------------------------
  wire decodeFusionAdv [0:4];
  assign decodeFusionAdv[0] = _renamePipeDispatch_io_in_0_ready & _rename_io_out_0_valid;
  assign decodeFusionAdv[1] = _renamePipeDispatch_io_in_1_ready & _rename_io_out_1_valid;
  assign decodeFusionAdv[2] = _renamePipeDispatch_io_in_2_ready & _rename_io_out_2_valid;
  assign decodeFusionAdv[3] = _renamePipeDispatch_io_in_3_ready & _rename_io_out_3_valid;
  assign decodeFusionAdv[4] = _renamePipeDispatch_io_in_4_ready & _rename_io_out_4_valid;

  // ==========================================================================
  // (8) snpt.snptLastEnq:送 snapshot 的「最近入队」槽 head robIdx(= enqPtr-1 槽的 head)。
  //     核内 snptHeadFlag/Value[] 已聚合各槽 head,snptIdx1 = enqPtr-1(logic.svh 块4)。
  // --------------------------------------------------------------------------
  wire       snptLastEnqHeadFlag  = snptHeadFlag[snptIdx1];
  wire [7:0] snptLastEnqHeadValue = snptHeadValue[snptIdx1];

  // ==========================================================================
  // (9) genSnapshot:本拍是否要生成新快照 = 任一 rename 输出 lane「真前进且带 snapshot 标记」。
  //     lane 0..4:decodeFusionAdv[k] & rename.out[k].snapshot;
  //     lane 5(无融合):renamePipeDispatch.in[5].ready & rename.out[5].valid & rename.out[5].snapshot。
  //     OR 归约后送 snpt.io.enq / rat.io.snpt.snptEnq。
  // --------------------------------------------------------------------------
  wire [ctrlblock_pkg::RenameWidth-1:0] genSnapshotVec;
  assign genSnapshotVec[0] = decodeFusionAdv[0] & _rename_io_out_0_bits_snapshot;
  assign genSnapshotVec[1] = decodeFusionAdv[1] & _rename_io_out_1_bits_snapshot;
  assign genSnapshotVec[2] = decodeFusionAdv[2] & _rename_io_out_2_bits_snapshot;
  assign genSnapshotVec[3] = decodeFusionAdv[3] & _rename_io_out_3_bits_snapshot;
  assign genSnapshotVec[4] = decodeFusionAdv[4] & _rename_io_out_4_bits_snapshot;
  assign genSnapshotVec[5] = _renamePipeDispatch_io_in_5_ready & _rename_io_out_5_valid
                           & _rename_io_out_5_bits_snapshot;
  wire genSnapshot = |genSnapshotVec;

  // ==========================================================================
  // (10) 融合指令 commitType 条件(cond1/2/3,5 对相邻 decode-pipe lane)
  //      送 rename.io.in[k].commitType:当 fusionDecoder.out[k] 命中时,根据本 lane 与
  //      下一 lane 的 ftqPtr/ftqOffset 关系给出融合 commitType 编码(见 pkg FUSE_COMMIT_*)。
  //      对每对相邻 lane k(本=decodePipeRename_k,下=decodePipeRename_{k+1}):
  //        sameFtq  = (本.ftqPtr_value == 下.ftqPtr_value)
  //        offDiff  = 下.ftqOffset - 本.ftqOffset
  //        cond1 = sameFtq & offDiff==1   -> commitType 4(同 ftq,差 1)
  //        cond2 = sameFtq & offDiff==2   -> commitType 5(同 ftq,差 2)
  //        cond3 = ~sameFtq & 下.ftqOffset==0 -> commitType {2'h3,~cond3}=6,否则 7
  //      inst.svh 用 cond1/2/3[k] 拼 commitType 三元 mux(见 fusionDecoder/rename 连线)。
  //      lane 索引:k=0 用 (pipe0,pipe1),k=1 用 (pipe1,pipe2)...k=4 用 (pipe4,pipe5)。
  // --------------------------------------------------------------------------
  wire        fuseSameFtq [0:4];
  wire [3:0]  fuseOffDiff [0:4];
  wire        fuseCond1   [0:4];
  wire        fuseCond2   [0:4];
  wire        fuseCond3   [0:4];
  // lane 0:(decodePipeRenameModule, decodePipeRenameModule_1)
  assign fuseSameFtq[0] = (_decodePipeRenameModule_io_out_bits_ftqPtr_value
                           == _decodePipeRenameModule_1_io_out_bits_ftqPtr_value);
  assign fuseOffDiff[0] = 4'(_decodePipeRenameModule_1_io_out_bits_ftqOffset
                             - _decodePipeRenameModule_io_out_bits_ftqOffset);
  assign fuseCond1[0]   = fuseSameFtq[0] & (fuseOffDiff[0] == 4'h1);
  assign fuseCond2[0]   = fuseSameFtq[0] & (fuseOffDiff[0] == 4'h2);
  assign fuseCond3[0]   = ~fuseSameFtq[0] & (_decodePipeRenameModule_1_io_out_bits_ftqOffset == 4'h0);
  // lane 1:(decodePipeRenameModule_1, decodePipeRenameModule_2)
  assign fuseSameFtq[1] = (_decodePipeRenameModule_1_io_out_bits_ftqPtr_value
                           == _decodePipeRenameModule_2_io_out_bits_ftqPtr_value);
  assign fuseOffDiff[1] = 4'(_decodePipeRenameModule_2_io_out_bits_ftqOffset
                             - _decodePipeRenameModule_1_io_out_bits_ftqOffset);
  assign fuseCond1[1]   = fuseSameFtq[1] & (fuseOffDiff[1] == 4'h1);
  assign fuseCond2[1]   = fuseSameFtq[1] & (fuseOffDiff[1] == 4'h2);
  assign fuseCond3[1]   = ~fuseSameFtq[1] & (_decodePipeRenameModule_2_io_out_bits_ftqOffset == 4'h0);
  // lane 2:(decodePipeRenameModule_2, decodePipeRenameModule_3)
  assign fuseSameFtq[2] = (_decodePipeRenameModule_2_io_out_bits_ftqPtr_value
                           == _decodePipeRenameModule_3_io_out_bits_ftqPtr_value);
  assign fuseOffDiff[2] = 4'(_decodePipeRenameModule_3_io_out_bits_ftqOffset
                             - _decodePipeRenameModule_2_io_out_bits_ftqOffset);
  assign fuseCond1[2]   = fuseSameFtq[2] & (fuseOffDiff[2] == 4'h1);
  assign fuseCond2[2]   = fuseSameFtq[2] & (fuseOffDiff[2] == 4'h2);
  assign fuseCond3[2]   = ~fuseSameFtq[2] & (_decodePipeRenameModule_3_io_out_bits_ftqOffset == 4'h0);
  // lane 3:(decodePipeRenameModule_3, decodePipeRenameModule_4)
  assign fuseSameFtq[3] = (_decodePipeRenameModule_3_io_out_bits_ftqPtr_value
                           == _decodePipeRenameModule_4_io_out_bits_ftqPtr_value);
  assign fuseOffDiff[3] = 4'(_decodePipeRenameModule_4_io_out_bits_ftqOffset
                             - _decodePipeRenameModule_3_io_out_bits_ftqOffset);
  assign fuseCond1[3]   = fuseSameFtq[3] & (fuseOffDiff[3] == 4'h1);
  assign fuseCond2[3]   = fuseSameFtq[3] & (fuseOffDiff[3] == 4'h2);
  assign fuseCond3[3]   = ~fuseSameFtq[3] & (_decodePipeRenameModule_4_io_out_bits_ftqOffset == 4'h0);
  // lane 4:(decodePipeRenameModule_4, decodePipeRenameModule_5)
  assign fuseSameFtq[4] = (_decodePipeRenameModule_4_io_out_bits_ftqPtr_value
                           == _decodePipeRenameModule_5_io_out_bits_ftqPtr_value);
  assign fuseOffDiff[4] = 4'(_decodePipeRenameModule_5_io_out_bits_ftqOffset
                             - _decodePipeRenameModule_4_io_out_bits_ftqOffset);
  assign fuseCond1[4]   = fuseSameFtq[4] & (fuseOffDiff[4] == 4'h1);
  assign fuseCond2[4]   = fuseSameFtq[4] & (fuseOffDiff[4] == 4'h2);
  assign fuseCond3[4]   = ~fuseSameFtq[4] & (_decodePipeRenameModule_5_io_out_bits_ftqOffset == 4'h0);

  // ==========================================================================
  // (11) memPredPcRead 偏移打一拍:送 redirectGen.io.memPredPcRead.data 的
  //      ftqOffset 分量(锁存 io.fromMem.violation.bits.stFtqOffset)。
  //      redirectGen 端 data = pcMem.rdata[1].startAddr + {memPredPcOffsetR, 1'b0}。
  // --------------------------------------------------------------------------
  // golden redirectGen_io_memPredPcRead_data_r 是 RegEnable(enable=violation_valid,无复位),
  // 不是无条件 RegNext。加使能对齐 golden。
  reg [3:0] memPredPcOffsetR;
  always_ff @(posedge clock) begin
    if (io_fromMem_violation_valid)
      memPredPcOffsetR <= io_fromMem_violation_bits_stFtqOffset;
  end
