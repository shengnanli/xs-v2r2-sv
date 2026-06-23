// =====================================================================
// ctrlblock_outglue2.svh —— round7（UT 收敛）补：之前漏驱的 57 个顶层输出端口。
// 这些端口对应 golden CtrlBlock 末尾的 assign 段：rob/rat/trace 子模块输出经
// 直通或寄存器化后送顶层。round6 只声明了子模块输出网（故 elaborate 不报 IWNF），
// 但没把它们接到顶层 io —— UT 双例化逐拍比对发现 impl 侧这些端口悬空（i=z）。
// 全部从 Scala 设计意图 / golden 末段语义重写，net 均为核内已具名信号，无 _GEN_/_T_。
// =====================================================================

  // ---- ① WFI 请求：rob 直出，广播给 frontend 与 mem ----
  assign io_frontend_wfi_wfiReq = _rob_io_wfi_wfiReq;
  assign io_toMem_wfi_wfiReq    = _rob_io_wfi_wfiReq;

  // ---- ② robio 提交 VType / 异常 / 性能 直通 + 单拍寄存 ----
  assign io_robio_commitVType_vtype_valid       = _rob_io_toDecode_commitVType_vtype_valid;
  assign io_robio_commitVType_vtype_bits_illegal= _rob_io_toDecode_commitVType_vtype_bits_illegal;
  assign io_robio_commitVType_vtype_bits_vlmul  = _rob_io_toDecode_commitVType_vtype_bits_vlmul;
  assign io_robio_commitVType_vtype_bits_vma    = _rob_io_toDecode_commitVType_vtype_bits_vma;
  assign io_robio_commitVType_vtype_bits_vsew   = _rob_io_toDecode_commitVType_vtype_bits_vsew;
  assign io_robio_commitVType_vtype_bits_vta    = _rob_io_toDecode_commitVType_vtype_bits_vta;
  assign io_robio_commitVType_hasVsetvl         = _rob_io_toDecode_commitVType_hasVsetvl;
  assign io_robio_exception_valid               = _rob_io_exception_valid;

  // robio.exception.bits.pc = pcMem[robFlush 读口].startAddr + (s1 打拍的 ftqOffset << 1)。
  // s1_robFlushFtqOff = RegEnable(flushOut.ftqOffset, flushOut.valid)，等价 golden s1_robFlushPc_r。
  assign io_robio_exception_bits_pc =
      50'(_pcMem_io_rdata_2_startAddr + {45'h0, s1_robFlushFtqOff, 1'h0});

  // retiredInstr：rob 计数单拍寄存。
  reg [6:0] robioRetiredInstrReg;
  always_ff @(posedge clock) robioRetiredInstrReg <= _rob_io_csr_perfinfo_retiredInstr;
  assign io_robio_csr_perfinfo_retiredInstr = robioRetiredInstrReg;

  // ---- ③ io_error_0：rob error 双拍寄存 ----
  reg errorReg0, errorReg1;
  always_ff @(posedge clock) begin
    errorReg0 <= _rob_io_error_0;
    errorReg1 <= errorReg0;
  end
  assign io_error_0 = errorReg1;

  // ---- ④ frontend.cfVec.ready：能否再接收一束 frontend 译码 ----
  // gate x15 = 本拍重定向有效 | 仍有 pending 重定向（与 decodeFlush 同义）。
  // ready[0] = cfVec[0].valid & ~decodeBufValid[0] & ~x15;
  // ready[k] = ready[0] 的条件 & cfVec[k].valid（链式，整束按序接收）。
  wire cfVecReadyGate = (io_redirect_valid | s2_s4_pendingRedirectValid);
  wire cfVecReadyBase = io_frontend_cfVec_0_valid & ~decodeBufValid[0] & ~cfVecReadyGate;
  assign io_frontend_cfVec_0_ready = cfVecReadyBase;
  assign io_frontend_cfVec_1_ready = cfVecReadyBase & io_frontend_cfVec_1_valid;
  assign io_frontend_cfVec_2_ready = cfVecReadyBase & io_frontend_cfVec_2_valid;
  assign io_frontend_cfVec_3_ready = cfVecReadyBase & io_frontend_cfVec_3_valid;
  assign io_frontend_cfVec_4_ready = cfVecReadyBase & io_frontend_cfVec_4_valid;
  assign io_frontend_cfVec_5_ready = cfVecReadyBase & io_frontend_cfVec_5_valid;

  // ---- ⑤ toFtq.rob_commits 槽 6/7（FTQ 提交接口 8 宽，核 CommitWidth=6 的环只覆盖 0..5）----
  // 与 0..5 同套：valid = RegNext(s1_isCommit_k)，bits = RegEnable(commits.info_k, s1_isCommit_k)。
  wire s1_isCommit_6 = _rob_io_commits_commitValid_6 & _rob_io_commits_isCommit & ~_rob_io_flushOut_valid;
  wire s1_isCommit_7 = _rob_io_commits_commitValid_7 & _rob_io_commits_isCommit & ~_rob_io_flushOut_valid;
  reg        ftqCommit6Valid, ftqCommit7Valid;
  reg [2:0]  ftqCommit6Type,  ftqCommit7Type;
  reg        ftqCommit6FtqFlag, ftqCommit7FtqFlag;
  reg [5:0]  ftqCommit6FtqValue,ftqCommit7FtqValue;
  reg [3:0]  ftqCommit6FtqOff,  ftqCommit7FtqOff;
  always_ff @(posedge clock) begin
    if (reset) begin ftqCommit6Valid <= 1'b0; ftqCommit7Valid <= 1'b0; end
    else       begin ftqCommit6Valid <= s1_isCommit_6; ftqCommit7Valid <= s1_isCommit_7; end
    if (s1_isCommit_6) begin
      ftqCommit6Type     <= _rob_io_commits_info_6_commitType;
      ftqCommit6FtqFlag  <= _rob_io_commits_info_6_ftqIdx_flag;
      ftqCommit6FtqValue <= _rob_io_commits_info_6_ftqIdx_value;
      ftqCommit6FtqOff   <= _rob_io_commits_info_6_ftqOffset;
    end
    if (s1_isCommit_7) begin
      ftqCommit7Type     <= _rob_io_commits_info_7_commitType;
      ftqCommit7FtqFlag  <= _rob_io_commits_info_7_ftqIdx_flag;
      ftqCommit7FtqValue <= _rob_io_commits_info_7_ftqIdx_value;
      ftqCommit7FtqOff   <= _rob_io_commits_info_7_ftqOffset;
    end
  end
  assign io_frontend_toFtq_rob_commits_6_valid            = ftqCommit6Valid;
  assign io_frontend_toFtq_rob_commits_6_bits_commitType  = ftqCommit6Type;
  assign io_frontend_toFtq_rob_commits_6_bits_ftqIdx_flag = ftqCommit6FtqFlag;
  assign io_frontend_toFtq_rob_commits_6_bits_ftqIdx_value= ftqCommit6FtqValue;
  assign io_frontend_toFtq_rob_commits_6_bits_ftqOffset   = ftqCommit6FtqOff;
  assign io_frontend_toFtq_rob_commits_7_valid            = ftqCommit7Valid;
  assign io_frontend_toFtq_rob_commits_7_bits_commitType  = ftqCommit7Type;
  assign io_frontend_toFtq_rob_commits_7_bits_ftqIdx_flag = ftqCommit7FtqFlag;
  assign io_frontend_toFtq_rob_commits_7_bits_ftqIdx_value= ftqCommit7FtqValue;
  assign io_frontend_toFtq_rob_commits_7_bits_ftqOffset   = ftqCommit7FtqOff;

  // ---- ⑥ toVecExcpMod.ratOldPest：RAB 提交时把 rat 旧 pdest 打两拍送出 ----
  // 触发 = rabCommits.isCommit & isWalk & commitValid[k] & {vec,v0}Wen；
  // valid 输出 = RegNext(触发)（即触发本身已是一级 reg，再过 _valid_REG 一级）；
  // bits 输出 = RegEnable(rat.old_pdest[k], 触发)。这里 2 级与 golden 一致。
  wire rabCommitWalk = _rob_io_rabCommits_isCommit & _rob_io_rabCommits_isWalk;
  // 各 lane 触发条件（vec / v0 各一套）
  wire vecTrig [0:5];
  wire v0Trig  [0:5];
  assign vecTrig[0] = rabCommitWalk & _rob_io_rabCommits_commitValid_0 & _rob_io_rabCommits_info_0_vecWen;
  assign vecTrig[1] = rabCommitWalk & _rob_io_rabCommits_commitValid_1 & _rob_io_rabCommits_info_1_vecWen;
  assign vecTrig[2] = rabCommitWalk & _rob_io_rabCommits_commitValid_2 & _rob_io_rabCommits_info_2_vecWen;
  assign vecTrig[3] = rabCommitWalk & _rob_io_rabCommits_commitValid_3 & _rob_io_rabCommits_info_3_vecWen;
  assign vecTrig[4] = rabCommitWalk & _rob_io_rabCommits_commitValid_4 & _rob_io_rabCommits_info_4_vecWen;
  assign vecTrig[5] = rabCommitWalk & _rob_io_rabCommits_commitValid_5 & _rob_io_rabCommits_info_5_vecWen;
  assign v0Trig[0]  = rabCommitWalk & _rob_io_rabCommits_commitValid_0 & _rob_io_rabCommits_info_0_v0Wen;
  assign v0Trig[1]  = rabCommitWalk & _rob_io_rabCommits_commitValid_1 & _rob_io_rabCommits_info_1_v0Wen;
  assign v0Trig[2]  = rabCommitWalk & _rob_io_rabCommits_commitValid_2 & _rob_io_rabCommits_info_2_v0Wen;
  assign v0Trig[3]  = rabCommitWalk & _rob_io_rabCommits_commitValid_3 & _rob_io_rabCommits_info_3_v0Wen;
  assign v0Trig[4]  = rabCommitWalk & _rob_io_rabCommits_commitValid_4 & _rob_io_rabCommits_info_4_v0Wen;
  assign v0Trig[5]  = rabCommitWalk & _rob_io_rabCommits_commitValid_5 & _rob_io_rabCommits_info_5_v0Wen;
  // rat 旧 pdest 源（vec / v0），收成数组便于 genvar
  wire [7:0] ratVecPdest [0:5];
  wire [7:0] ratV0Pdest  [0:5];
  assign ratVecPdest[0]=_rat_io_vec_old_pdest_0; assign ratVecPdest[1]=_rat_io_vec_old_pdest_1;
  assign ratVecPdest[2]=_rat_io_vec_old_pdest_2; assign ratVecPdest[3]=_rat_io_vec_old_pdest_3;
  assign ratVecPdest[4]=_rat_io_vec_old_pdest_4; assign ratVecPdest[5]=_rat_io_vec_old_pdest_5;
  assign ratV0Pdest[0]=_rat_io_v0_old_pdest_0;   assign ratV0Pdest[1]=_rat_io_v0_old_pdest_1;
  assign ratV0Pdest[2]=_rat_io_v0_old_pdest_2;   assign ratV0Pdest[3]=_rat_io_v0_old_pdest_3;
  assign ratV0Pdest[4]=_rat_io_v0_old_pdest_4;   assign ratV0Pdest[5]=_rat_io_v0_old_pdest_5;
  // 寄存器阵列：valid 两级（vecValidReg=RegNext(trig)，输出 _validReg=RegNext(vecValidReg)），
  // bits 一级 RegEnable(en=vecValidReg)（与 golden：bits 在 vecValid 高时更新）。
  reg vecValidReg [0:5], vecValidOut [0:5];
  reg v0ValidReg  [0:5], v0ValidOut  [0:5];
  reg [6:0] vecBitsReg [0:5];
  reg [6:0] v0BitsReg  [0:5];
  genvar gv;
  generate
    for (gv = 0; gv < 6; gv = gv + 1) begin : g_ratoldpest
      always_ff @(posedge clock) begin
        vecValidReg[gv] <= vecTrig[gv];
        vecValidOut[gv] <= vecValidReg[gv];
        if (vecValidReg[gv]) vecBitsReg[gv] <= ratVecPdest[gv][6:0];
        v0ValidReg[gv]  <= v0Trig[gv];
        v0ValidOut[gv]  <= v0ValidReg[gv];
        if (v0ValidReg[gv])  v0BitsReg[gv]  <= ratV0Pdest[gv][6:0];
      end
    end
  endgenerate
  assign io_toVecExcpMod_ratOldPest_vecOldVdPdest_0_valid = vecValidOut[0];
  assign io_toVecExcpMod_ratOldPest_vecOldVdPdest_0_bits  = vecBitsReg[0];
  assign io_toVecExcpMod_ratOldPest_vecOldVdPdest_1_valid = vecValidOut[1];
  assign io_toVecExcpMod_ratOldPest_vecOldVdPdest_1_bits  = vecBitsReg[1];
  assign io_toVecExcpMod_ratOldPest_vecOldVdPdest_2_valid = vecValidOut[2];
  assign io_toVecExcpMod_ratOldPest_vecOldVdPdest_2_bits  = vecBitsReg[2];
  assign io_toVecExcpMod_ratOldPest_vecOldVdPdest_3_valid = vecValidOut[3];
  assign io_toVecExcpMod_ratOldPest_vecOldVdPdest_3_bits  = vecBitsReg[3];
  assign io_toVecExcpMod_ratOldPest_vecOldVdPdest_4_valid = vecValidOut[4];
  assign io_toVecExcpMod_ratOldPest_vecOldVdPdest_4_bits  = vecBitsReg[4];
  assign io_toVecExcpMod_ratOldPest_vecOldVdPdest_5_valid = vecValidOut[5];
  assign io_toVecExcpMod_ratOldPest_vecOldVdPdest_5_bits  = vecBitsReg[5];
  assign io_toVecExcpMod_ratOldPest_v0OldVdPdest_0_valid  = v0ValidOut[0];
  assign io_toVecExcpMod_ratOldPest_v0OldVdPdest_0_bits   = v0BitsReg[0];
  assign io_toVecExcpMod_ratOldPest_v0OldVdPdest_1_valid  = v0ValidOut[1];
  assign io_toVecExcpMod_ratOldPest_v0OldVdPdest_1_bits   = v0BitsReg[1];
  assign io_toVecExcpMod_ratOldPest_v0OldVdPdest_2_valid  = v0ValidOut[2];
  assign io_toVecExcpMod_ratOldPest_v0OldVdPdest_2_bits   = v0BitsReg[2];
  assign io_toVecExcpMod_ratOldPest_v0OldVdPdest_3_valid  = v0ValidOut[3];
  assign io_toVecExcpMod_ratOldPest_v0OldVdPdest_3_bits   = v0BitsReg[3];
  assign io_toVecExcpMod_ratOldPest_v0OldVdPdest_4_valid  = v0ValidOut[4];
  assign io_toVecExcpMod_ratOldPest_v0OldVdPdest_4_bits   = v0BitsReg[4];
  assign io_toVecExcpMod_ratOldPest_v0OldVdPdest_5_valid  = v0ValidOut[5];
  assign io_toVecExcpMod_ratOldPest_v0OldVdPdest_5_bits   = v0BitsReg[5];

  // ---- ⑦ traceCoreInterface.toEncoder：trace 子模块 itype + CSR trace 状态 ----
  wire [3:0] traceItype0 = _trace_io_out_toEncoder_blocks_0_bits_tracePipe_itype;
  assign io_traceCoreInterface_toEncoder_groups_0_bits_itype = traceItype0;
  // priv：itype ∈ {1,2,3}（trap/intr 类）取 lastPriv，否则 currentPriv。
  assign io_traceCoreInterface_toEncoder_priv =
      (traceItype0 == 4'h1 || traceItype0 == 4'h2 || traceItype0 == 4'h3)
        ? io_fromCSR_traceCSR_lastPriv : io_fromCSR_traceCSR_currentPriv;
  assign io_traceCoreInterface_toEncoder_trap_cause = io_fromCSR_traceCSR_cause;
  assign io_traceCoreInterface_toEncoder_trap_tval  = io_fromCSR_traceCSR_tval;
