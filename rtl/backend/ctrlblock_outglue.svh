// 手写(从 CtrlBlock.scala 设计意图重写,非 golden 转写)。CtrlBlock 输出侧 glue。
// ============================================================================
// 本文件汇总「子模块输出经寄存器化/计算后送顶层 io」的输出端 glue（非纯直连，
// 纯直连那批由 ctrlblock_inst.svh 机械连）。round5 在 round4（commits->FTQ）基础上补：
//   ① 性能计数器 io_perf_*（62 路 2 级打拍流水）
//   ② s2_s4_redirect_next 输出重定向流水 -> io_to{IssueBlock,DataPath,ExuBlock}.flush
//   ③ newestTarget FSM + 取目标 PC mux -> io_toDataPath...toDataPathTargetPC_*
//   ④ frontendFlushBits（rob flush 的 ftq 坐标打拍，供 toFtq.redirect 选择）
//   ⑤ commits->FTQ 提交流水（round4 已起，保留）
// 全部用 struct/genvar/function 表达可读逻辑 + 中文注释。
// X 铁律：所有 mux 用三元运算（不出现 latch / 不定态）。
// ============================================================================

  genvar gk;

  // ==========================================================================
  // ① 性能计数器 io_perf_*：每路是「子模块某 perf 输出」的 2 级打拍（打 2 拍对齐到顶层）。
  //    映射（见 golden _decode/_rename/_dispatch/_rob 的 io_perf_*_value 引脚）：
  //       io_perf[ 0.. 5] <= decode.perf[0..5]
  //       io_perf[ 6..35] <= rename.perf[0..29]
  //       io_perf[36..39] <= dispatch.perf[0..3]
  //       io_perf[40]     省略（golden 无此端口；dispatch.perf[4] 不引出）
  //       io_perf[41..44] <= dispatch.perf[5..8]
  //       io_perf[45..62] <= rob.perf[0..17]
  //    每路 6 bit 计数。stage0 收子模块输出，stage1 再打一拍后送 io。
  // --------------------------------------------------------------------------
  localparam int PerfNum = 63;   // io_perf 编号 0..62（其中 40 号缺省）

  // 子模块 perf 输出汇聚为一张「源表」：perfSrc[n] = 第 n 号 io_perf 的输入源。
  // （40 号无源，置 0；它本身也不产出 io 端口。）
  wire [5:0] perfSrc [0:PerfNum-1];
  generate
    // decode.perf[0..5] -> io_perf[0..5]
    for (gk = 0; gk < 6; gk++) begin : g_perf_dec
      assign perfSrc[gk] = _decode_io_perf_value[gk];
    end
    // rename.perf[0..29] -> io_perf[6..35]
    for (gk = 0; gk < 30; gk++) begin : g_perf_ren
      assign perfSrc[6 + gk] = _rename_io_perf_value[gk];
    end
    // dispatch.perf[0..3] -> io_perf[36..39]
    for (gk = 0; gk < 4; gk++) begin : g_perf_dis_lo
      assign perfSrc[36 + gk] = _dispatch_io_perf_value[gk];
    end
    assign perfSrc[40] = 6'h0;   // 缺省口
    // dispatch.perf[5..8] -> io_perf[41..44]
    for (gk = 0; gk < 4; gk++) begin : g_perf_dis_hi
      assign perfSrc[41 + gk] = _dispatch_io_perf_value[5 + gk];
    end
    // rob.perf[0..17] -> io_perf[45..62]
    for (gk = 0; gk < 18; gk++) begin : g_perf_rob
      assign perfSrc[45 + gk] = _rob_io_perf_value[gk];
    end
  endgenerate

  // 2 级打拍：perfStage0 = RegNext(perfSrc)，perfStage1 = RegNext(perfStage0)。
  reg [5:0] perfStage0 [0:PerfNum-1];
  reg [5:0] perfStage1 [0:PerfNum-1];
  generate
    for (gk = 0; gk < PerfNum; gk++) begin : g_perf_pipe
      always_ff @(posedge clock) begin
        perfStage0[gk] <= perfSrc[gk];
        perfStage1[gk] <= perfStage0[gk];
      end
    end
  endgenerate

  // 驱顶层 io_perf_*_value（顶层为扁平 output 端口，须逐个具名 assign；40 号无端口跳过）。
  assign io_perf_0_value  = perfStage1[0];
  assign io_perf_1_value  = perfStage1[1];
  assign io_perf_2_value  = perfStage1[2];
  assign io_perf_3_value  = perfStage1[3];
  assign io_perf_4_value  = perfStage1[4];
  assign io_perf_5_value  = perfStage1[5];
  assign io_perf_6_value  = perfStage1[6];
  assign io_perf_7_value  = perfStage1[7];
  assign io_perf_8_value  = perfStage1[8];
  assign io_perf_9_value  = perfStage1[9];
  assign io_perf_10_value = perfStage1[10];
  assign io_perf_11_value = perfStage1[11];
  assign io_perf_12_value = perfStage1[12];
  assign io_perf_13_value = perfStage1[13];
  assign io_perf_14_value = perfStage1[14];
  assign io_perf_15_value = perfStage1[15];
  assign io_perf_16_value = perfStage1[16];
  assign io_perf_17_value = perfStage1[17];
  assign io_perf_18_value = perfStage1[18];
  assign io_perf_19_value = perfStage1[19];
  assign io_perf_20_value = perfStage1[20];
  assign io_perf_21_value = perfStage1[21];
  assign io_perf_22_value = perfStage1[22];
  assign io_perf_23_value = perfStage1[23];
  assign io_perf_24_value = perfStage1[24];
  assign io_perf_25_value = perfStage1[25];
  assign io_perf_26_value = perfStage1[26];
  assign io_perf_27_value = perfStage1[27];
  assign io_perf_28_value = perfStage1[28];
  assign io_perf_29_value = perfStage1[29];
  assign io_perf_30_value = perfStage1[30];
  assign io_perf_31_value = perfStage1[31];
  assign io_perf_32_value = perfStage1[32];
  assign io_perf_33_value = perfStage1[33];
  assign io_perf_34_value = perfStage1[34];
  assign io_perf_35_value = perfStage1[35];
  assign io_perf_36_value = perfStage1[36];
  assign io_perf_37_value = perfStage1[37];
  assign io_perf_38_value = perfStage1[38];
  assign io_perf_39_value = perfStage1[39];
  // 40 号：golden 无此 io 端口（dispatch.perf[4] 不引出）
  assign io_perf_41_value = perfStage1[41];
  assign io_perf_42_value = perfStage1[42];
  assign io_perf_43_value = perfStage1[43];
  assign io_perf_44_value = perfStage1[44];
  assign io_perf_45_value = perfStage1[45];
  assign io_perf_46_value = perfStage1[46];
  assign io_perf_47_value = perfStage1[47];
  assign io_perf_48_value = perfStage1[48];
  assign io_perf_49_value = perfStage1[49];
  assign io_perf_50_value = perfStage1[50];
  assign io_perf_51_value = perfStage1[51];
  assign io_perf_52_value = perfStage1[52];
  assign io_perf_53_value = perfStage1[53];
  assign io_perf_54_value = perfStage1[54];
  assign io_perf_55_value = perfStage1[55];
  assign io_perf_56_value = perfStage1[56];
  assign io_perf_57_value = perfStage1[57];
  assign io_perf_58_value = perfStage1[58];
  assign io_perf_59_value = perfStage1[59];
  assign io_perf_60_value = perfStage1[60];
  assign io_perf_61_value = perfStage1[61];
  assign io_perf_62_value = perfStage1[62];

  // ==========================================================================
  // ④ frontendFlushBits：rob flush 时锁存的 FTQ 坐标（ftqIdx / ftqOffset），
  //    供 toFtq.redirect 在「本拍重定向来自 rob flush」时选用。
  //    源 = s1_robFlush*（核块 1 已产出的 rob flush 打拍流水），enable = s1_robFlushValid。
  // --------------------------------------------------------------------------
  reg        frontendFlushFtqFlag;
  reg [5:0]  frontendFlushFtqValue;
  reg [3:0]  frontendFlushFtqOffset;
  always_ff @(posedge clock) begin
    if (s1_robFlushValid) begin
      frontendFlushFtqFlag   <= s1_robFlushFtqFlag;
      frontendFlushFtqValue  <= s1_robFlushFtqValue;
      frontendFlushFtqOffset <= s1_robFlushFtqOff;
    end
  end

  // ==========================================================================
  // ② s2_s4_redirect_next:送各执行单元的 flush 重定向流水（输出端专用，区别于核内
  //    s2_s4_redirect 仅有 robIdx/level —— 这里还要带 ftqIdx/ftqOffset/cfiUpdate/fullTarget）。
  //    valid = RegNext(s1_s3_redirect_valid)；bits = RegEnable(选好的字段, s1_s3_redirect_valid)。
  //    bits 字段来源（与 golden 一致）：
  //      robIdx / level     <- s1_s3_redirect（核已 mux 好 rob-flush vs redirectGen）
  //      ftqIdx / ftqOffset <- rob flush 优先(s1_robFlushValid) 否则 redirectGen.stage2
  //      cfiUpdate / fullTarget <- 仅 redirectGen 路有效（rob flush 路这些位为 0）
  // --------------------------------------------------------------------------
  // 输出重定向流水寄存器（用 struct 收口，便于阅读各字段含义）。
  typedef struct packed {
    logic        robIdxFlag;
    logic [7:0]  robIdxValue;
    logic        ftqIdxFlag;
    logic [5:0]  ftqIdxValue;
    logic [3:0]  ftqOffset;
    logic        level;            // 1 = flushItself
    logic        cfiBackendIGPF;   // 后端取指 GPF 异常
    logic        cfiBackendIPF;    // 后端取指 PF  异常
    logic        cfiBackendIAF;    // 后端取指 AF  异常
    logic [63:0] fullTarget;       // 重定向完整目标地址
  } s2s4_redirect_bits_t;

  reg                  s2s4RedirectValid;     // RegNext(s1_s3_redirect_valid)
  s2s4_redirect_bits_t s2s4RedirectBits;      // RegEnable(...)

  // 本拍 s2_s4 的 bits 输入（组合选择，X 铁律：三元 mux）。
  // rob-flush 路有效时取 frontendFlush*(rob flush 锁存的 ftq 坐标)，否则取 redirectGen。
  wire        s2s4_in_ftqFlag  =
      s1_robFlushValid ? s1_robFlushFtqFlag  : _redirectGen_io_stage2Redirect_bits_ftqIdx_flag;
  wire [5:0]  s2s4_in_ftqValue =
      s1_robFlushValid ? s1_robFlushFtqValue : _redirectGen_io_stage2Redirect_bits_ftqIdx_value;
  wire [3:0]  s2s4_in_ftqOff   =
      s1_robFlushValid ? s1_robFlushFtqOff   : _redirectGen_io_stage2Redirect_bits_ftqOffset;
  // cfiUpdate / fullTarget：rob-flush 路不带这些信息（清 0），仅 redirectGen 路给值。
  wire        s2s4_in_cfiIGPF  =
      s1_robFlushValid ? 1'b0  : _redirectGen_io_stage2Redirect_bits_cfiUpdate_backendIGPF;
  wire        s2s4_in_cfiIPF   =
      s1_robFlushValid ? 1'b0  : _redirectGen_io_stage2Redirect_bits_cfiUpdate_backendIPF;
  wire        s2s4_in_cfiIAF   =
      s1_robFlushValid ? 1'b0  : _redirectGen_io_stage2Redirect_bits_cfiUpdate_backendIAF;
  wire [63:0] s2s4_in_fullTgt  =
      s1_robFlushValid ? 64'h0 : _redirectGen_io_stage2Redirect_bits_fullTarget;

  always_ff @(posedge clock) begin
    if (reset) s2s4RedirectValid <= 1'b0;
    else       s2s4RedirectValid <= s1_s3_redirect_valid;
    if (s1_s3_redirect_valid) begin
      s2s4RedirectBits.robIdxFlag     <= s1_s3_redirect_robFlag;
      s2s4RedirectBits.robIdxValue    <= s1_s3_redirect_robValue;
      s2s4RedirectBits.ftqIdxFlag     <= s2s4_in_ftqFlag;
      s2s4RedirectBits.ftqIdxValue    <= s2s4_in_ftqValue;
      s2s4RedirectBits.ftqOffset      <= s2s4_in_ftqOff;
      s2s4RedirectBits.level          <= s1_s3_redirect_level;
      s2s4RedirectBits.cfiBackendIGPF <= s2s4_in_cfiIGPF;
      s2s4RedirectBits.cfiBackendIPF  <= s2s4_in_cfiIPF;
      s2s4RedirectBits.cfiBackendIAF  <= s2s4_in_cfiIAF;
      s2s4RedirectBits.fullTarget     <= s2s4_in_fullTgt;
    end
  end

  // -- 驱 IssueBlock.flush（仅 robIdx/level）--
  assign io_toIssueBlock_flush_valid           = s2s4RedirectValid;
  assign io_toIssueBlock_flush_bits_robIdx_flag = s2s4RedirectBits.robIdxFlag;
  assign io_toIssueBlock_flush_bits_robIdx_value= s2s4RedirectBits.robIdxValue;
  assign io_toIssueBlock_flush_bits_level       = s2s4RedirectBits.level;

  // -- 驱 DataPath.flush（仅 robIdx/level）--
  assign io_toDataPath_flush_valid             = s2s4RedirectValid;
  assign io_toDataPath_flush_bits_robIdx_flag  = s2s4RedirectBits.robIdxFlag;
  assign io_toDataPath_flush_bits_robIdx_value = s2s4RedirectBits.robIdxValue;
  assign io_toDataPath_flush_bits_level        = s2s4RedirectBits.level;

  // -- 驱 ExuBlock.flush（全字段：含 ftqIdx/ftqOffset/cfiUpdate/fullTarget）--
  assign io_toExuBlock_flush_valid                    = s2s4RedirectValid;
  assign io_toExuBlock_flush_bits_robIdx_flag         = s2s4RedirectBits.robIdxFlag;
  assign io_toExuBlock_flush_bits_robIdx_value        = s2s4RedirectBits.robIdxValue;
  assign io_toExuBlock_flush_bits_ftqIdx_flag         = s2s4RedirectBits.ftqIdxFlag;
  assign io_toExuBlock_flush_bits_ftqIdx_value        = s2s4RedirectBits.ftqIdxValue;
  assign io_toExuBlock_flush_bits_ftqOffset           = s2s4RedirectBits.ftqOffset;
  assign io_toExuBlock_flush_bits_level               = s2s4RedirectBits.level;
  assign io_toExuBlock_flush_bits_cfiUpdate_backendIGPF = s2s4RedirectBits.cfiBackendIGPF;
  assign io_toExuBlock_flush_bits_cfiUpdate_backendIPF  = s2s4RedirectBits.cfiBackendIPF;
  assign io_toExuBlock_flush_bits_cfiUpdate_backendIAF  = s2s4RedirectBits.cfiBackendIAF;
  assign io_toExuBlock_flush_bits_fullTarget          = s2s4RedirectBits.fullTarget;

  // ==========================================================================
  // ③ newestTarget FSM + 取目标 PC mux:
  //    FTQ 每拍可推来「最新表项」(newest_entry)，其 target 锁存为 newestTarget，
  //    并延一拍成 newestTargetNext;DataPath 取目标 PC 时若请求的 ftqPtr 恰为最新表项，
  //    直接用 newestTargetNext(绕过 pcMem 读延迟),否则用 pcMem 读口数据。
  // --------------------------------------------------------------------------
  reg        newestEn;                 // RegNext(newest_entry.en)
  reg [49:0] newestTarget;             // RegEnable(newest_entry.target, en)
  reg [5:0]  newestPtrValue;           // RegEnable(newest_entry.ptr.value, en)
  reg [49:0] newestTargetNext;         // RegEnable(newestTarget, newestEn)
  always_ff @(posedge clock) begin
    newestEn <= io_frontend_fromFtq_newest_entry_en;
    if (io_frontend_fromFtq_newest_entry_en) begin
      newestTarget   <= io_frontend_fromFtq_newest_entry_target;
      newestPtrValue <= io_frontend_fromFtq_newest_entry_ptr_value;
    end
    if (newestEn)
      newestTargetNext <= newestTarget;
  end

  // needNewest[k] = 本拍 DataPath 请求的第 k 条 ftqPtr 是否等于最新表项指针。
  // RegNext 一拍以对齐 pcMem 读延迟。fromDataPathFtqPtr 为 3 条顶层 input（扁平）。
  reg  needNewest [0:2];
  always_ff @(posedge clock) begin
    needNewest[0] <= (io_toDataPath_pcToDataPathIO_fromDataPathFtqPtr_0_value == newestPtrValue);
    needNewest[1] <= (io_toDataPath_pcToDataPathIO_fromDataPathFtqPtr_1_value == newestPtrValue);
    needNewest[2] <= (io_toDataPath_pcToDataPathIO_fromDataPathFtqPtr_2_value == newestPtrValue);
  end

  // 取目标 PC：命中最新表项走旁路 newestTargetNext，否则走 pcMem 读口 6/7/8。
  assign io_toDataPath_pcToDataPathIO_toDataPathTargetPC_0 =
      needNewest[0] ? newestTargetNext : _pcMem_io_rdata_6_startAddr;
  assign io_toDataPath_pcToDataPathIO_toDataPathTargetPC_1 =
      needNewest[1] ? newestTargetNext : _pcMem_io_rdata_7_startAddr;
  assign io_toDataPath_pcToDataPathIO_toDataPathTargetPC_2 =
      needNewest[2] ? newestTargetNext : _pcMem_io_rdata_8_startAddr;

  // ==========================================================================
  // ⑤ 提交 -> FTQ 流水（rob.commits -> io.frontend.toFtq.rob_commits），round4 起。
  //    CommitWidth=6 槽,每槽:
  //      valid = RegNext(s1_isCommit[k])
  //              s1_isCommit[k] = commitValid[k] & isCommit & !flushOut.valid
  //      bits  = RegEnable(commits.info[k].{commitType,ftqIdx,ftqOffset}, s1_isCommit[k])
  //    FTQ 用它回收已提交表项、训练分支预测器。
  // --------------------------------------------------------------------------
  // s1_isCommit[k]:该提交槽本拍真正提交(且未被 flushOut 取消)。
  wire [ctrlblock_pkg::CommitWidth-1:0] s1_isCommit;
  generate
    for (gk = 0; gk < ctrlblock_pkg::CommitWidth; gk++) begin : g_s1commit
      assign s1_isCommit[gk] = _rob_io_commits_commitValid[gk]
                             & _rob_io_commits_isCommit
                             & ~_rob_io_flushOut_valid;
    end
  endgenerate

  // 提交 -> FTQ 流水寄存器(valid 复位 0;bits RegEnable)。
  logic        ftqCommitValid      [0:ctrlblock_pkg::CommitWidth-1];
  logic [2:0]  ftqCommitCommitType [0:ctrlblock_pkg::CommitWidth-1];
  logic        ftqCommitFtqFlag    [0:ctrlblock_pkg::CommitWidth-1];
  logic [5:0]  ftqCommitFtqValue   [0:ctrlblock_pkg::CommitWidth-1];
  logic [3:0]  ftqCommitFtqOffset  [0:ctrlblock_pkg::CommitWidth-1];
  generate
    for (gk = 0; gk < ctrlblock_pkg::CommitWidth; gk++) begin : g_ftqcommit
      always_ff @(posedge clock) begin
        if (reset) ftqCommitValid[gk] <= 1'b0;
        else       ftqCommitValid[gk] <= s1_isCommit[gk];
        if (s1_isCommit[gk]) begin
          ftqCommitCommitType[gk] <= _rob_io_commits_info_flag_commitType[gk];
          ftqCommitFtqFlag[gk]    <= _rob_io_commits_info_ftqIdx_flag[gk];
          ftqCommitFtqValue[gk]   <= _rob_io_commits_info_ftqIdx_value[gk];
          ftqCommitFtqOffset[gk]  <= _rob_io_commits_info_ftqOffset[gk];
        end
      end
    end
  endgenerate

  // ==========================================================================
  // ⑥ toFtq.redirect 链（round6 补完）:后端给 FTQ 的「重定向」输出端。
  //    本拍重定向有两个来源,二选一(rob flush 优先):
  //      ・rob flush 路:s6_flushFromRobValid（s1_robFlush 经 DelayN(4) 再打一拍）
  //      ・redirectGen 路:redirectGen.stage2Redirect（黑盒 _redirectGen_io_stage2Redirect_*）
  //    valid = s6_flushFromRobValid | stage2Redirect.valid
  //    各 bits 字段:rob-flush 路用 frontendFlushBits / cfiUpdate_r 锁存值,
  //                 否则用 redirectGen.stage2 的对应字段（X 铁律:三元 mux）。
  //
  //    s6_flushFromRobValid:= GatedValidRegNext(s5_flushFromRobValidAhead)
  //      （s5_..Ahead = DelayN(s1_robFlushValid, 4),由 inst.svh 例化的 DelayN 产出
  //        _s5_flushFromRobValidAhead_delay_io_out,核内别名 s5_flushFromRobValidAhead）。
  //    cfiUpdate_*_r:trap 目标/异常位的锁存(在 s5_flushFromRobValidAhead 拍 enable),
  //      trap 时取 csr.trapTarget,否则取 s2_robFlushPc(核块5 已有 s2_robFlushPc/s5_csrIsTrap)。
  // --------------------------------------------------------------------------
  // s6_flushFromRobValid 已在 logic.svh 块5 产出;这里只补 cfiUpdate_*_r 锁存寄存器。
  reg [63:0] toFtqCfiTargetR;     // trap? csr.trapTarget.pc : {14'h0, s2_robFlushPc}
  reg        toFtqCfiIAFR;        // trap & raiseIAF
  reg        toFtqCfiIPFR;        // trap & raiseIPF
  reg        toFtqCfiIGPFR;       // trap & raiseIGPF
  always_ff @(posedge clock) begin
    if (s5_flushFromRobValidAhead) begin
      toFtqCfiTargetR <= s5_csrIsTrap ? io_robio_csr_trapTarget_pc
                                      : {14'h0, s2_robFlushPc};
      toFtqCfiIAFR    <= s5_csrIsTrap & io_robio_csr_trapTarget_raiseIAF;
      toFtqCfiIPFR    <= s5_csrIsTrap & io_robio_csr_trapTarget_raiseIPF;
      toFtqCfiIGPFR   <= s5_csrIsTrap & io_robio_csr_trapTarget_raiseIGPF;
    end
  end

  // valid = s6_flushFromRobValid | stage2Redirect.valid（= 核内 frontend_toFtq_redirect_valid）
  assign io_frontend_toFtq_redirect_valid = frontend_toFtq_redirect_valid;
  // ftqIdx / ftqOffset:rob-flush 路用 frontendFlushBits(本文件④),否则 redirectGen.stage2。
  assign io_frontend_toFtq_redirect_bits_ftqIdx_flag =
      s6_flushFromRobValid ? frontendFlushFtqFlag
                           : _redirectGen_io_stage2Redirect_bits_ftqIdx_flag;
  assign io_frontend_toFtq_redirect_bits_ftqIdx_value =
      s6_flushFromRobValid ? frontendFlushFtqValue
                           : _redirectGen_io_stage2Redirect_bits_ftqIdx_value;
  assign io_frontend_toFtq_redirect_bits_ftqOffset =
      s6_flushFromRobValid ? frontendFlushFtqOffset
                           : _redirectGen_io_stage2Redirect_bits_ftqOffset;
  // level:rob-flush 恒为「flushItself」(1),故 OR。
  assign io_frontend_toFtq_redirect_bits_level =
      s6_flushFromRobValid | _redirectGen_io_stage2Redirect_bits_level;
  // cfiUpdate.pc:rob-flush 路无 pc(0),否则 redirectGen。
  assign io_frontend_toFtq_redirect_bits_cfiUpdate_pc =
      s6_flushFromRobValid ? 50'h0 : _redirectGen_io_stage2Redirect_bits_cfiUpdate_pc;
  // cfiUpdate.target:rob-flush 路用锁存的 trap/flush 目标(取低 50 位),否则 redirectGen。
  assign io_frontend_toFtq_redirect_bits_cfiUpdate_target =
      s6_flushFromRobValid ? toFtqCfiTargetR[49:0]
                           : _redirectGen_io_stage2Redirect_bits_cfiUpdate_target;
  // taken / isMisPred / debugIs*:rob-flush 路恒 0,否则 redirectGen。
  assign io_frontend_toFtq_redirect_bits_cfiUpdate_taken =
      ~s6_flushFromRobValid & _redirectGen_io_stage2Redirect_bits_cfiUpdate_taken;
  assign io_frontend_toFtq_redirect_bits_cfiUpdate_isMisPred =
      ~s6_flushFromRobValid & _redirectGen_io_stage2Redirect_bits_cfiUpdate_isMisPred;
  // backendIGPF/IPF/IAF:rob-flush 路用 trap 锁存位,否则 redirectGen。
  assign io_frontend_toFtq_redirect_bits_cfiUpdate_backendIGPF =
      s6_flushFromRobValid ? toFtqCfiIGPFR
                           : _redirectGen_io_stage2Redirect_bits_cfiUpdate_backendIGPF;
  assign io_frontend_toFtq_redirect_bits_cfiUpdate_backendIPF =
      s6_flushFromRobValid ? toFtqCfiIPFR
                           : _redirectGen_io_stage2Redirect_bits_cfiUpdate_backendIPF;
  assign io_frontend_toFtq_redirect_bits_cfiUpdate_backendIAF =
      s6_flushFromRobValid ? toFtqCfiIAFR
                           : _redirectGen_io_stage2Redirect_bits_cfiUpdate_backendIAF;
  assign io_frontend_toFtq_redirect_bits_debugIsCtrl =
      ~s6_flushFromRobValid & _redirectGen_io_stage2Redirect_bits_debugIsCtrl;
  assign io_frontend_toFtq_redirect_bits_debugIsMemVio =
      ~s6_flushFromRobValid & _redirectGen_io_stage2Redirect_bits_debugIsMemVio;

  // ==========================================================================
  // ⑦ toFtq.ftqIdxAhead / ftqIdxSelOH:给 FTQ 的「提前 ftqIdx」与选择 one-hot。
  //    ftqIdxAhead_0 = exu redirect 选最旧的 ftqIdx,打一拍(glue2 选最旧已产出
  //      exuOldestValid / exuOldestCand.ftqIdx_value)。有效需排除 rob-flush 抢占。
  //    ftqIdxSelOH.bits = Cat(s6, stage2oldestOH & Fill(!s6))(核块5 frontend_toFtq_ftqIdxSelOH_bits)。
  // --------------------------------------------------------------------------
  reg       ftqAheadValidR;       // RegNext(exuOldestValid)
  reg [5:0] ftqAheadValueR;       // RegEnable(exuOldestCand.ftqIdx_value, exuOldestValid)
  always_ff @(posedge clock) begin
    if (reset) ftqAheadValidR <= 1'b0;
    else       ftqAheadValidR <= exuOldestValid;
    if (exuOldestValid) ftqAheadValueR <= exuOldestCand.ftqIdx_value;
  end
  // valid:打拍有效 & 未被 rob flush 抢占(s1_robFlush 当拍 / DelayN 链上有 flush)。
  assign io_frontend_toFtq_ftqIdxAhead_0_valid =
      ftqAheadValidR & ~s1_robFlushValid & ~s5_flushFromRobValidAhead;
  assign io_frontend_toFtq_ftqIdxAhead_0_bits_value = ftqAheadValueR;
  assign io_frontend_toFtq_ftqIdxSelOH_bits         = frontend_toFtq_ftqIdxSelOH_bits;

  // 驱顶层 io（扁平 6 槽 output 端口，逐槽具名 assign）。
  assign io_frontend_toFtq_rob_commits_0_valid            = ftqCommitValid[0];
  assign io_frontend_toFtq_rob_commits_0_bits_commitType  = ftqCommitCommitType[0];
  assign io_frontend_toFtq_rob_commits_0_bits_ftqIdx_flag = ftqCommitFtqFlag[0];
  assign io_frontend_toFtq_rob_commits_0_bits_ftqIdx_value= ftqCommitFtqValue[0];
  assign io_frontend_toFtq_rob_commits_0_bits_ftqOffset   = ftqCommitFtqOffset[0];
  assign io_frontend_toFtq_rob_commits_1_valid            = ftqCommitValid[1];
  assign io_frontend_toFtq_rob_commits_1_bits_commitType  = ftqCommitCommitType[1];
  assign io_frontend_toFtq_rob_commits_1_bits_ftqIdx_flag = ftqCommitFtqFlag[1];
  assign io_frontend_toFtq_rob_commits_1_bits_ftqIdx_value= ftqCommitFtqValue[1];
  assign io_frontend_toFtq_rob_commits_1_bits_ftqOffset   = ftqCommitFtqOffset[1];
  assign io_frontend_toFtq_rob_commits_2_valid            = ftqCommitValid[2];
  assign io_frontend_toFtq_rob_commits_2_bits_commitType  = ftqCommitCommitType[2];
  assign io_frontend_toFtq_rob_commits_2_bits_ftqIdx_flag = ftqCommitFtqFlag[2];
  assign io_frontend_toFtq_rob_commits_2_bits_ftqIdx_value= ftqCommitFtqValue[2];
  assign io_frontend_toFtq_rob_commits_2_bits_ftqOffset   = ftqCommitFtqOffset[2];
  assign io_frontend_toFtq_rob_commits_3_valid            = ftqCommitValid[3];
  assign io_frontend_toFtq_rob_commits_3_bits_commitType  = ftqCommitCommitType[3];
  assign io_frontend_toFtq_rob_commits_3_bits_ftqIdx_flag = ftqCommitFtqFlag[3];
  assign io_frontend_toFtq_rob_commits_3_bits_ftqIdx_value= ftqCommitFtqValue[3];
  assign io_frontend_toFtq_rob_commits_3_bits_ftqOffset   = ftqCommitFtqOffset[3];
  assign io_frontend_toFtq_rob_commits_4_valid            = ftqCommitValid[4];
  assign io_frontend_toFtq_rob_commits_4_bits_commitType  = ftqCommitCommitType[4];
  assign io_frontend_toFtq_rob_commits_4_bits_ftqIdx_flag = ftqCommitFtqFlag[4];
  assign io_frontend_toFtq_rob_commits_4_bits_ftqIdx_value= ftqCommitFtqValue[4];
  assign io_frontend_toFtq_rob_commits_4_bits_ftqOffset   = ftqCommitFtqOffset[4];
  assign io_frontend_toFtq_rob_commits_5_valid            = ftqCommitValid[5];
  assign io_frontend_toFtq_rob_commits_5_bits_commitType  = ftqCommitCommitType[5];
  assign io_frontend_toFtq_rob_commits_5_bits_ftqIdx_flag = ftqCommitFtqFlag[5];
  assign io_frontend_toFtq_rob_commits_5_bits_ftqIdx_value= ftqCommitFtqValue[5];
  assign io_frontend_toFtq_rob_commits_5_bits_ftqOffset   = ftqCommitFtqOffset[5];
