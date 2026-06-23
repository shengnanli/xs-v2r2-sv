// 自动生成占位 / 手写:scripts/gen_ctrlblock.py 后续接管。
// ----------------------------------------------------------------------------
// 可读核内部网声明:① 子模块(golden 黑盒)输出网,供 glue 消费;② glue 产出的
// 具名驱动信号(送回子模块输入引脚,经 ctrlblock_inst.svh 的 rewrite 机械连线)。
// 命名约定:黑盒输出沿用 golden 例化点的 net 名(下划线前缀 _inst_io_*),
// glue 具名信号用可读名(s1_robFlushRedirect_* 等)。
// 本文件只放「6 块 glue」实际用到的信号,其余子模块直通端口在 inst.svh 直接连顶层 io。
// ============================================================================

  // ===== 子模块黑盒输出(glue 消费)=====
  // -- Rob --
  logic        _rob_io_flushOut_valid;
  logic        _rob_io_flushOut_bits_ftqIdx_flag;
  logic [5:0]  _rob_io_flushOut_bits_ftqIdx_value;
  logic [3:0]  _rob_io_flushOut_bits_ftqOffset;
  logic        _rob_io_flushOut_bits_isRVC;
  logic        _rob_io_flushOut_bits_robIdx_flag;
  logic [7:0]  _rob_io_flushOut_bits_robIdx_value;
  logic        _rob_io_flushOut_bits_level;       // 1=flushItself
  logic        _rob_io_exception_valid;
  logic        _rob_io_commits_isCommit;
  logic [5:0]  _rob_io_commits_commitValid;       // {commitValid_5..0}
  logic [5:0]  _rob_io_commits_robIdx_flag;
  logic [7:0]  _rob_io_commits_robIdx_value_0;
  logic [7:0]  _rob_io_commits_robIdx_value_1;
  logic [7:0]  _rob_io_commits_robIdx_value_2;
  logic [7:0]  _rob_io_commits_robIdx_value_3;
  logic [7:0]  _rob_io_commits_robIdx_value_4;
  logic [7:0]  _rob_io_commits_robIdx_value_5;

  // -- RedirectGenerator --
  logic        _redirectGen_io_stage2Redirect_valid;
  logic        _redirectGen_io_stage2Redirect_bits_robIdx_flag;
  logic [7:0]  _redirectGen_io_stage2Redirect_bits_robIdx_value;
  logic        _redirectGen_io_stage2Redirect_bits_ftqIdx_flag;
  logic [5:0]  _redirectGen_io_stage2Redirect_bits_ftqIdx_value;
  logic [3:0]  _redirectGen_io_stage2Redirect_bits_ftqOffset;
  logic        _redirectGen_io_stage2Redirect_bits_level;
  logic [1:0]  _redirectGen_io_stage2oldestOH;   // golden 输出 [1:0](2 路 one-hot)
  // stage2Redirect 的 cfiUpdate / fullTarget(送 frontend.toFtq.redirect / toExuBlock.flush）
  logic [49:0] _redirectGen_io_stage2Redirect_bits_cfiUpdate_pc;
  logic [49:0] _redirectGen_io_stage2Redirect_bits_cfiUpdate_target;
  logic        _redirectGen_io_stage2Redirect_bits_cfiUpdate_taken;
  logic        _redirectGen_io_stage2Redirect_bits_cfiUpdate_isMisPred;
  logic        _redirectGen_io_stage2Redirect_bits_cfiUpdate_backendIGPF;
  logic        _redirectGen_io_stage2Redirect_bits_cfiUpdate_backendIPF;
  logic        _redirectGen_io_stage2Redirect_bits_cfiUpdate_backendIAF;
  logic        _redirectGen_io_stage2Redirect_bits_debugIsCtrl;
  logic        _redirectGen_io_stage2Redirect_bits_debugIsMemVio;
  logic [63:0] _redirectGen_io_stage2Redirect_bits_fullTarget;

  // -- pcMem 读数据(startAddr)--
  logic [49:0] _pcMem_io_rdata_0_startAddr;   // redirect 口(loadReplay pc)
  logic [49:0] _pcMem_io_rdata_1_startAddr;   // memPred 口
  logic [49:0] _pcMem_io_rdata_2_startAddr;   // robFlush 口
  // pcMem 读口 6/7/8:DataPath 取目标 PC 口(每条流水一条 fromDataPathFtqPtr 对应一个读口）
  logic [49:0] _pcMem_io_rdata_6_startAddr;
  logic [49:0] _pcMem_io_rdata_7_startAddr;
  logic [49:0] _pcMem_io_rdata_8_startAddr;

  // -- 译码就绪(DecodeStage 输入握手 ready 反馈)--
  logic [5:0]  _decode_io_in_ready;            // {in_5..0}.ready

  // -- Snapshot 生成器输出 --
  logic [3:0]  _snpt_io_valids;
  logic        _snpt_io_deqPtr_flag;
  logic [1:0]  _snpt_io_deqPtr_value;
  logic        _snpt_io_enqPtr_flag;
  logic [1:0]  _snpt_io_enqPtr_value;
  // 各快照槽 head robIdx(robIdx_0)+ isCFI 向量,用于 useSnpt/snptSelect/flushVec
  logic        _snpt_io_snapshots_0_robIdx_head_flag;
  logic [7:0]  _snpt_io_snapshots_0_robIdx_head_value;
  logic        _snpt_io_snapshots_1_robIdx_head_flag;
  logic [7:0]  _snpt_io_snapshots_1_robIdx_head_value;
  logic        _snpt_io_snapshots_2_robIdx_head_flag;
  logic [7:0]  _snpt_io_snapshots_2_robIdx_head_value;
  logic        _snpt_io_snapshots_3_robIdx_head_flag;
  logic [7:0]  _snpt_io_snapshots_3_robIdx_head_value;
  // 每槽 6 路 robIdx + isCFI(flushVec 计算需要全 RenameWidth)
  logic [5:0]  _snpt_io_snapshots_0_isCFI;
  logic [5:0]  _snpt_io_snapshots_1_isCFI;
  logic [5:0]  _snpt_io_snapshots_2_isCFI;
  logic [5:0]  _snpt_io_snapshots_3_isCFI;
  logic        _snpt_io_snapshots_0_robIdx_flag  [0:5];
  logic [7:0]  _snpt_io_snapshots_0_robIdx_value [0:5];
  logic        _snpt_io_snapshots_1_robIdx_flag  [0:5];
  logic [7:0]  _snpt_io_snapshots_1_robIdx_value [0:5];
  logic        _snpt_io_snapshots_2_robIdx_flag  [0:5];
  logic [7:0]  _snpt_io_snapshots_2_robIdx_value [0:5];
  logic        _snpt_io_snapshots_3_robIdx_flag  [0:5];
  logic [7:0]  _snpt_io_snapshots_3_robIdx_value [0:5];

  // -- Rob commits.info(commits->FTQ 提交流水 outglue 用,每槽 commitType/ftqIdx/ftqOffset)--
  logic [2:0]  _rob_io_commits_info_flag_commitType  [0:ctrlblock_pkg::CommitWidth-1];
  logic        _rob_io_commits_info_ftqIdx_flag      [0:ctrlblock_pkg::CommitWidth-1];
  logic [5:0]  _rob_io_commits_info_ftqIdx_value     [0:ctrlblock_pkg::CommitWidth-1];
  logic [3:0]  _rob_io_commits_info_ftqOffset        [0:ctrlblock_pkg::CommitWidth-1];

  // -- decode / decodePipeRename 黑盒输出(散余 glue2:mdpFlodPcVec / foldpc 用)--
  logic        _decode_io_out_0_valid;
  logic        _decode_io_out_1_valid;
  logic        _decodePipeRenameModule_io_in_ready;     // decodePipeRenameModule(路0)in.ready
  logic        _decodePipeRenameModule_1_io_in_ready;   // decodePipeRenameModule_1(路1)in.ready
  logic [9:0]  _decodePipeRenameModule_io_out_bits_foldpc;
  logic [9:0]  _decodePipeRenameModule_1_io_out_bits_foldpc;

  // -- 融合译码(FusionDecoder)输出 + decodePipeRename 的 fuType/fuOpType（glue3 fusion 覆盖用）。
  //    融合触发时把 fuType 覆盖为特殊「已融合」码(35'h80)、fuOpType 取融合给出的码,送 rename。
  //    5 条 lane(0..4;lane5 无融合)。这些 net 由 inst.svh 例化 fusionDecoder/pipeRename 时绑定。
  logic        _fusionDecoder_io_out_0_valid, _fusionDecoder_io_out_1_valid;
  logic        _fusionDecoder_io_out_2_valid, _fusionDecoder_io_out_3_valid;
  logic        _fusionDecoder_io_out_4_valid;
  logic        _fusionDecoder_io_out_0_bits_fuType_valid, _fusionDecoder_io_out_1_bits_fuType_valid;
  logic        _fusionDecoder_io_out_2_bits_fuType_valid, _fusionDecoder_io_out_3_bits_fuType_valid;
  logic        _fusionDecoder_io_out_4_bits_fuType_valid;
  logic        _fusionDecoder_io_out_0_bits_fuOpType_valid, _fusionDecoder_io_out_1_bits_fuOpType_valid;
  logic        _fusionDecoder_io_out_2_bits_fuOpType_valid, _fusionDecoder_io_out_3_bits_fuOpType_valid;
  logic        _fusionDecoder_io_out_4_bits_fuOpType_valid;
  logic [8:0]  _fusionDecoder_io_out_0_bits_fuOpType_bits, _fusionDecoder_io_out_1_bits_fuOpType_bits;
  logic [8:0]  _fusionDecoder_io_out_2_bits_fuOpType_bits, _fusionDecoder_io_out_3_bits_fuOpType_bits;
  logic [8:0]  _fusionDecoder_io_out_4_bits_fuOpType_bits;
  logic [34:0] _decodePipeRenameModule_io_out_bits_fuType,   _decodePipeRenameModule_1_io_out_bits_fuType;
  logic [34:0] _decodePipeRenameModule_2_io_out_bits_fuType, _decodePipeRenameModule_3_io_out_bits_fuType;
  logic [34:0] _decodePipeRenameModule_4_io_out_bits_fuType;
  logic [8:0]  _decodePipeRenameModule_io_out_bits_fuOpType,   _decodePipeRenameModule_1_io_out_bits_fuOpType;
  logic [8:0]  _decodePipeRenameModule_2_io_out_bits_fuOpType, _decodePipeRenameModule_3_io_out_bits_fuOpType;
  logic [8:0]  _decodePipeRenameModule_4_io_out_bits_fuOpType;

  // -- 融合 commitType 条件用(glue3 (10)):6 路 decodePipeRename 输出的 ftqPtr_value/ftqOffset --
  logic [5:0]  _decodePipeRenameModule_io_out_bits_ftqPtr_value,   _decodePipeRenameModule_1_io_out_bits_ftqPtr_value;
  logic [5:0]  _decodePipeRenameModule_2_io_out_bits_ftqPtr_value, _decodePipeRenameModule_3_io_out_bits_ftqPtr_value;
  logic [5:0]  _decodePipeRenameModule_4_io_out_bits_ftqPtr_value, _decodePipeRenameModule_5_io_out_bits_ftqPtr_value;
  logic [3:0]  _decodePipeRenameModule_io_out_bits_ftqOffset,   _decodePipeRenameModule_1_io_out_bits_ftqOffset;
  logic [3:0]  _decodePipeRenameModule_2_io_out_bits_ftqOffset, _decodePipeRenameModule_3_io_out_bits_ftqOffset;
  logic [3:0]  _decodePipeRenameModule_4_io_out_bits_ftqOffset, _decodePipeRenameModule_5_io_out_bits_ftqOffset;

  // -- decode/fusion 入口 valid(glue4 驱动,inst.svh 引脚引用;声明须先于 inst)--
  wire        decodeInValid   [0:ctrlblock_pkg::DecodeWidth-1];  // -> DecodeStage.io_in_k_valid
  wire [23:0] fusionDecExcVec [0:ctrlblock_pkg::DecodeWidth-1];  // decode 输出 k 的异常向量聚合
  wire        fusionInValid   [0:ctrlblock_pkg::DecodeWidth-1];  // -> FusionDecoder.io_in_k_valid

  // -- fusion 触发反馈用(glue3 (7)):renamePipeDispatch.in[k].ready / rename.out[k].valid --
  logic _renamePipeDispatch_io_in_0_ready, _renamePipeDispatch_io_in_1_ready;
  logic _renamePipeDispatch_io_in_2_ready, _renamePipeDispatch_io_in_3_ready;
  logic _renamePipeDispatch_io_in_4_ready;
  logic _rename_io_out_0_valid, _rename_io_out_1_valid, _rename_io_out_2_valid;
  logic _rename_io_out_3_valid, _rename_io_out_4_valid, _rename_io_out_5_valid;
  logic _renamePipeDispatch_io_in_5_ready;
  // -- genSnapshot 用(glue3 (9)):rename.out[k].snapshot --
  logic _rename_io_out_0_bits_snapshot, _rename_io_out_1_bits_snapshot, _rename_io_out_2_bits_snapshot;
  logic _rename_io_out_3_bits_snapshot, _rename_io_out_4_bits_snapshot, _rename_io_out_5_bits_snapshot;

  // -- 子模块性能计数输出（io_perf 流水的源；inst.svh 把各 perf_<n>_value 黑盒引脚
  //    连到这些数组元素，outglue 再 2 级打拍送顶层 io_perf_*）--
  logic [5:0]  _decode_io_perf_value   [0:5];    // DecodeStage  perf[0..5]
  logic [5:0]  _rename_io_perf_value   [0:29];   // Rename       perf[0..29]
  logic [5:0]  _dispatch_io_perf_value [0:8];    // NewDispatch  perf[0..8]（4 号不引出）
  logic [5:0]  _rob_io_perf_value      [0:17];   // Rob          perf[0..17]

  // -- DelayN 链输出 --
  logic        _s5_flushFromRobValidAhead_delay_io_out; // DelayN(s1robFlush.valid,4)
  logic        _s5_csrIsTrap_delay_io_out;               // DelayN(rob.exception.valid,4)
  // 注:io.robio.csr.trapTarget.{pc,raiseIAF/IPF/IGPF} 为顶层 input 端口(见 ports.svh),
  //     不在此声明;pc 为 64 位,flushTarget 取低 VAddrBits 位。
