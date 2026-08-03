// =====================================================================
// xs_Rob_core —— 重排序缓冲(Rob) 可读重写 [控制核心]
// ---------------------------------------------------------------------
// 角色: 香山 V2R2 后端「按序提交」核心。详细微架构见 docs/backend/Rob.md。
//
// 本可读核实现 ROB 的「控制逻辑」, 把以下部件作为 golden 黑盒例化驱动:
//   RobEnqPtrWrapper      enqPtr 生成(入队头, redirect 回卷)
//   NewRobDeqPtrWrapper   deqPtr 生成(出队头, 按提交/异常/中断推进)
//   ExceptionGen          异常聚合(选出最老带异常条目, 输出 exceptionDataRead)
//   SnapshotGenerator_3   walkPtr 快照
//   RenameBuffer(rab)     重命名映射回收(commit/walk 的 size 驱动)
//   VTypeBuffer           vtype 重排序
//   DelayReg/DummyDPICWrapper/dt_160x1  difftest 探针(空 sink 黑盒)
//
// 可读核负责的中心控制(对应 Scala RobImp body):
//   1) enqueue: dispatch 入队, 置 valid/uopNum/realDestSize/interrupt_safe 等;
//   2) 8-bank 行读: robBanks 按 deqPtr/walkPtr 所在行读出 robDeqGroup;
//   3) writeback: 各 FU 写回递减 uopNum / 置 std / 累计 fflags|vxsat / needFlush;
//   4) commit: 队头条目 commit_v&commit_w 且不被更老者阻塞时按序退休;
//   5) 异常/中断/flushPipe 优先级 → flushOut 精确重定向;
//   6) walk: redirect 后逐拍回滚投机条目到 redirect 边界;
//   7) 指针/计数/size: enqPtr/deqPtr/walkPtr 推进, commitSize/walkSize 给 rab。
//
// 状态机仅两态(s_idle / s_walk); redirect 优先级最高, 直接进 walk。
// =====================================================================
module xs_Rob_core
  import rob_pkg::*;
(
  input  logic                       clock,
  input  logic                       reset,

  // ---- redirect(误预测/异常重定向, 优先级最高) ----
  input  logic                       io_redirect_valid,
  input  logic                       io_redirect_bits_robIdx_flag,
  input  logic [PTR_W-1:0]           io_redirect_bits_robIdx_value,
  input  logic                       io_redirect_bits_level,        // 1=flushItself(含自身)

  // ---- enqueue(来自 dispatch 的 RenameWidth 口) ----
  input  logic [RENAME_WIDTH-1:0]    enq_valid,        // req.valid
  input  logic [RENAME_WIDTH-1:0]    enq_first_uop,    // req.bits.firstUop
  input  logic [RENAME_WIDTH-1:0]    enq_need_write_rf,// req.bits.needWriteRf
  input  logic [RENAME_WIDTH-1:0]    enq_write_std,    // FuType.isStore
  input  logic [RENAME_WIDTH-1:0]    enq_block_backward,
  input  logic [RENAME_WIDTH-1:0]    enq_wait_forward,
  input  logic [RENAME_WIDTH-1:0]    enq_is_wfi,
  input  logic [RENAME_WIDTH-1:0]    enq_has_exception,
  input  logic [RENAME_WIDTH-1:0]    enq_trigger_dmode,
  input  logic [RENAME_WIDTH-1:0]    enq_allow_interrupt, // 非 ld/st/fence/csr/vset
  input  logic [UOP_CNT_W-1:0]       enq_num_wb   [RENAME_WIDTH], // numWB
  input  logic [PTR_W-1:0]           enq_robidx_value [RENAME_WIDTH],
  // 入队静态信息(connectEnq), 每口一份
  input  rob_entry_t                 enq_info     [RENAME_WIDTH],

  // ---- writeback: 普通 exu 写回(递减 uopNum) ----
  input  logic [NUM_EXU_WB-1:0]      wb_valid,
  input  logic [PTR_W-1:0]           wb_robidx   [NUM_EXU_WB],
  input  logic [4:0]                 wb_num      [NUM_EXU_WB], // 该口本拍写回的 uop 个数
  input  logic [NUM_EXU_WB-1:0]      wb_is_std,               // std 写回口
  input  logic [NUM_EXU_WB-1:0]      wb_fflags_valid,
  input  logic [4:0]                 wb_fflags   [NUM_EXU_WB],
  input  logic [NUM_EXU_WB-1:0]      wb_vxsat_valid,
  input  logic [NUM_EXU_WB-1:0]      wb_vxsat,
  input  logic [NUM_EXU_WB-1:0]      wb_branch_taken,
  // 异常写回(置 needFlush): 一组独立端口
  input  logic [NUM_WB-1:0]          excp_wb_valid,
  input  logic [PTR_W-1:0]           excp_wb_robidx [NUM_WB],
  input  logic [NUM_WB-1:0]          excp_wb_need_flush,

  // ---- 来自各黑盒的关键信号 ----
  // exceptionGen 输出(异常聚合最老条目)
  input  logic                       eg_valid,
  input  logic                       eg_robidx_flag,
  input  logic [PTR_W-1:0]           eg_robidx_value,
  input  logic                       eg_is_exception,  // exceptionVec.orR|singleStep|dmode
  input  logic                       eg_flush_pipe,
  input  logic                       eg_replay_inst,
  input  logic                       eg_is_vls,
  input  logic                       eg_is_enq_excp,
  input  logic                       eg_is_vset,
  // deqPtrGen/enqPtrGen 输出(指针)
  input  rob_ptr_t                   deq_ptr_vec    [COMMIT_WIDTH],
  input  rob_ptr_t                   deq_ptr_next0,
  input  rob_ptr_t                   enq_ptr_vec    [RENAME_WIDTH],
  // walkPtr 快照读出(redirect+useSnpt 时跳转目标行头)
  input  rob_ptr_t                   snap_ptr0,

  // ---- CSR / 外部控制 ----
  input  logic                       io_csr_intrBitSet,
  input  logic                       io_csr_wfiEvent,
  input  logic                       io_csr_criticalErrorState,
  input  logic                       io_snpt_useSnpt,
  input  logic                       io_wfi_enable,
  input  logic                       io_wfi_safeFromMem,
  input  logic                       io_wfi_safeFromFrontend,
  input  logic                       io_fromVecExcpMod_busy,
  input  logic                       io_trace_blockCommit,
  input  logic                       rab_can_enq,
  input  logic                       rab_status_commit_end,
  input  logic                       rab_status_walk_end,
  input  logic                       vtype_status_walk_end,
  // 误预测写回(任一 branch/jmp 写回带 isMisPred & redirect.valid & wb.valid)。
  // 实际在 Backend 顶层由 redirectWBs 聚合, 经 wrapper 喂入。
  input  logic                       io_misPredWb,

  // ---- misPred 性能计数(io_perf_16)所需的 3 个分支 exu 写回 redirect ----
  //   golden misPred_probe = 2*(wb1_redir + wb3_redir + wb5_redir), 对应 exuWriteback
  //   端口 1/3/5 的 (valid & bits.redirect.valid)。wrapper 由 flat 端口忠实重建后喂入。
  input  logic                       io_wb1_redir,   // io_exuWriteback_1_valid & _1_bits_redirect_valid
  input  logic                       io_wb3_redir,   // io_exuWriteback_3_valid & _3_bits_redirect_valid
  input  logic                       io_wb5_redir,   // io_exuWriteback_5_valid & _5_bits_redirect_valid

  // ====================================================================
  // [csr/debug 组新增] C_DEEP csr(9)+debug(6) 端口所需输入
  //   (owner rob-csr-debug; 见 docs/backend/rob_csr_debug_ports.tsv)
  // ====================================================================
  // ---- csr: vstart 来自 ExceptionGen 黑盒(异常时 CSR 需回写 vstart) ----
  input  logic                       io_eg_vstartEn,   // exceptionGen.io_state_bits_vstartEn
  input  logic [63:0]                io_eg_vstart,     // exceptionGen.io_state_bits_vstart
  input  logic                       io_vstartIsZero,  // io.vstartIsZero(CSR 现 vstart 是否为 0)

  // ---- debug: 每条目 debug 信息的入队/更新输入 ----
  input  logic [34:0]                enq_fuType   [RENAME_WIDTH], // 各口 uop.fuType(入队写 debug_microOp)
  input  logic                       io_debugHeadLsIssue,         // 队头 ls 是否已发射(topdown)
  // lsTopdownInfo 3 口(load/store 拓扑 topdown 反馈, 按 robIdx 更新对应条目)
  input  logic [PTR_W-1:0]           io_lsTopdown_s1_robIdx [3],
  input  logic [2:0]                 io_lsTopdown_s1_valid,       // 3 口 s1_vaddr_valid
  input  logic [49:0]                io_lsTopdown_s1_bits   [3],
  input  logic [PTR_W-1:0]           io_lsTopdown_s2_robIdx [3],
  input  logic [2:0]                 io_lsTopdown_s2_valid,       // 3 口 s2_paddr_valid
  input  logic [47:0]                io_lsTopdown_s2_bits   [3],

  // ====================================================================
  // [vec 异常组新增] exceptionGen 输出(向量 state 子集, 供 toVecExcpMod.excpInfo 打包)
  //   golden: _exceptionGen_io_state_bits_{vstart[6:0],vsew,veew,vlmul,nf,isStrided,
  //           isIndexed,isWhole,isVlm,vstartEn,isVecLoad,isEnqExcp}
  //   (wrapper 侧直连 ExceptionGen 子模块; vstart 源宽 [63:0] 由 wrapper 切 [6:0])
  // ====================================================================
  input  logic [6:0]                 eg_state_vstart,
  input  logic [1:0]                 eg_state_vsew,
  input  logic [1:0]                 eg_state_veew,
  input  logic [2:0]                 eg_state_vlmul,
  input  logic [2:0]                 eg_state_nf,
  input  logic                       eg_state_isStrided,
  input  logic                       eg_state_isIndexed,
  input  logic                       eg_state_isWhole,
  input  logic                       eg_state_isVlm,
  input  logic                       eg_state_vstartEn,
  input  logic                       eg_state_isVecLoad,
  input  logic                       eg_state_isEnqExcp,

  // ---- 输出: 提交/walk 决策 ----
  output rob_state_e                 o_state,          // 当前态(供 deqPtrGen / 外部)
  output logic                       o_commits_isCommit,
  output logic                       o_commits_isWalk,
  output logic [COMMIT_WIDTH-1:0]    o_commits_commitValid,
  output logic [COMMIT_WIDTH-1:0]    o_commits_walkValid,
  output rob_commit_entry_t          o_commit_info  [COMMIT_WIDTH], // = robDeqGroup(deq) 或 (walk)
  output rob_ptr_t                   o_commits_robIdx [COMMIT_WIDTH],

  // 送 deqPtrGen 的 per-bank 提交条目状态
  output logic [COMMIT_WIDTH-1:0]    o_deq_commit_v,
  output logic [COMMIT_WIDTH-1:0]    o_deq_commit_w,
  output logic                       o_intrBitSetReg,
  output logic                       o_hasNoSpecExec,
  output logic                       o_allowOnlyOneCommit,
  output logic                       o_blockCommit,
  output logic [COMMIT_WIDTH-1:0]    o_hasCommitted,
  output logic                       o_allCommitted,

  // 送 enqPtrGen
  output logic                       o_allowEnqueue,
  output logic                       o_hasBlockBackward,
  output logic [RENAME_WIDTH-1:0]    o_enq_for_ptr,    // req.valid & firstUop

  // 送 exceptionGen
  output logic                       o_eg_flush,       // = flushOut.valid

  // 送 rab / vtypeBuffer
  output logic [UOP_CNT_W:0]         o_rab_commitSize,
  output logic [UOP_CNT_W:0]         o_rab_walkSize,
  output logic                       o_rab_walkEnd,

  // ---- 精确重定向 / 异常 ----
  output logic                       o_flushOut_valid,
  output logic                       o_flushOut_robIdx_flag,
  output logic [PTR_W-1:0]           o_flushOut_robIdx_value,
  output logic                       o_flushOut_level,
  output logic                       o_flushOut_isRVC,
  output logic [FTQ_PTR_W-1:0]       o_flushOut_ftqIdx_value,
  output logic                       o_flushOut_ftqIdx_flag,
  output logic [FTQ_OFFSET_W-1:0]    o_flushOut_ftqOffset,
  output logic                       o_exception_valid,        // RegNext(exceptionHappen)
  output logic                       o_exceptionHappen,        // 本拍异常发生(wrapper B_SHALLOW r_3_*/*_r latch 门控)
  output logic                       o_deqHasException,        // 队头本拍带异常(wrapper isFetchMalAddr_r 源)
  output logic                       o_intrEnable,             // 中断使能(本拍)

  // ---- enq / 队列状态 ----
  output logic                       o_enq_canAccept,
  output logic                       o_enq_canAcceptForDispatch,
  output logic                       o_robFull,
  output logic                       o_headNotReady,
  output logic                       o_cpu_halt,
  output logic                       o_wfiReq,
  output logic [PTR_W:0]             o_numValidEntries,

  // ---- 性能计数(18 路, 均 [5:0], 两拍 RegNext 后零扩展)----
  //   对齐 golden io_perf_N_value = {pad, RegNext(RegNext(src_N))}。详见 §13。
  output logic [5:0]                 o_perf_0_value,
  output logic [5:0]                 o_perf_1_value,
  output logic [5:0]                 o_perf_2_value,
  output logic [5:0]                 o_perf_3_value,
  output logic [5:0]                 o_perf_4_value,
  output logic [5:0]                 o_perf_5_value,
  output logic [5:0]                 o_perf_6_value,
  output logic [5:0]                 o_perf_7_value,
  output logic [5:0]                 o_perf_8_value,
  output logic [5:0]                 o_perf_9_value,
  output logic [5:0]                 o_perf_10_value,
  output logic [5:0]                 o_perf_11_value,
  output logic [5:0]                 o_perf_12_value,
  output logic [5:0]                 o_perf_13_value,
  output logic [5:0]                 o_perf_14_value,
  output logic [5:0]                 o_perf_15_value,
  output logic [5:0]                 o_perf_16_value,
  output logic [5:0]                 o_perf_17_value,

  // ---- trace 提交信息(8 块, 组合读 robDeqGroup 的 trace 字段 + 异常覆盖)----
  //   对齐 golden io_trace_traceCommitInfo_blocks_N_{valid,bits_*}。详见 §14。
  output logic [COMMIT_WIDTH-1:0]    o_trace_valid,
  output logic [FTQ_PTR_W-1:0]       o_trace_ftqIdx_value [COMMIT_WIDTH],
  output logic [FTQ_OFFSET_W-1:0]    o_trace_ftqOffset    [COMMIT_WIDTH],
  output logic [ITYPE_W-1:0]         o_trace_itype        [COMMIT_WIDTH],
  output logic [IRETIRE_W-1:0]       o_trace_iretire      [COMMIT_WIDTH],
  output logic [COMMIT_WIDTH-1:0]    o_trace_ilastsize,

  // ====================================================================
  // [csr/debug 组新增] C_DEEP csr(9)+debug(6) 输出端口
  // ====================================================================
  // ---- csr(9): 提交时向 CSR 回写的浮点/向量状态与退休计数 ----
  output logic                       o_csr_fflags_valid,
  output logic [4:0]                 o_csr_fflags_bits,
  output logic                       o_csr_vxsat_valid,
  output logic                       o_csr_vxsat_bits,
  output logic                       o_csr_vstart_valid,
  output logic [63:0]                o_csr_vstart_bits,
  output logic                       o_csr_dirty_fs,
  output logic                       o_csr_dirty_vs,
  output logic [6:0]                 o_csr_perfinfo_retiredInstr,
  // ---- debug(6): 队头(deqPtr)调试/topdown 信息 ----
  output logic [34:0]                o_debugRobHead_fuType,
  output logic                       o_debugTopDown_robHeadLsIssue,
  output logic                       o_debugTopDown_robHeadVaddr_valid,
  output logic [49:0]                o_debugTopDown_robHeadVaddr_bits,
  output logic                       o_debugTopDown_robHeadPaddr_valid,
  output logic [47:0]                o_debugTopDown_robHeadPaddr_bits,

  // ====================================================================
  // [vec 异常组新增] toVecExcpMod.excpInfo(向量异常合并模块接口, 10 口)
  //   golden vecExcpInfo_{valid,bits_*} 寄存器打包, 见 rob_vec_exception_ports.tsv。
  // ====================================================================
  output logic                       o_toVecExcpMod_excpInfo_valid,
  output logic [6:0]                 o_toVecExcpMod_excpInfo_bits_vstart,
  output logic [1:0]                 o_toVecExcpMod_excpInfo_bits_vsew,
  output logic [1:0]                 o_toVecExcpMod_excpInfo_bits_veew,
  output logic [2:0]                 o_toVecExcpMod_excpInfo_bits_vlmul,
  output logic [2:0]                 o_toVecExcpMod_excpInfo_bits_nf,
  output logic                       o_toVecExcpMod_excpInfo_bits_isStride,
  output logic                       o_toVecExcpMod_excpInfo_bits_isIndexed,
  output logic                       o_toVecExcpMod_excpInfo_bits_isWhole,
  output logic                       o_toVecExcpMod_excpInfo_bits_isVlm,

  // ====================================================================
  // [lsq deep 组新增] 组合全存储读 / 状态导出(供 rob_lsq_deep_outputs 消费)
  //   (owner rob-lsq-deep; 见 docs/backend/rob_lsq_deep_ports.tsv)
  // ====================================================================
  output logic [COMMIT_WIDTH-1:0]    o_deq_entry_vls,     // rob_entries[deq_ptr_vec[N].value].vls
  output logic                       o_deq_entry_valid_0, // rob_entries[deqValIdx[0]].valid
  output logic                       o_deq_entry_mmio_0,  // rob_entries[deqValIdx[0]].mmio
  output logic                       o_deqHasFlushed      // deqHasFlushed
);

  // =====================================================================
  // 0. 主存储 + 状态寄存器
  // =====================================================================
  // 存储阵列 = ROB_SIZE=160 条目(对齐 golden robEntries_0..159, 无 padding)。
  //  之前扩到 256(2 的幂)是为让 8 位 robIdx 下标静态在界(消 FMR_ELAB-147),
  //  但 96 死项 × 25 字段 = 2592 impl-only 寄存器拖慢 FM match。改回 160 后:
  //   - 写入: 写路径是「按 entry 并行更新」循环 for(i<ROB_SIZE), 天然仅写 0..159;
  //           enq 命中判定用 allocate_ptr[i].value==idx(idx<ROB_SIZE), 无 ≥160 写。
  //   - 读取: 指针值下标(deqPtr/deqPtrVec/walkPtr.value)全来自 mod-160 环形指针
  //           (NewRobDeqPtrWrapper/ptr_add 均以 160 取模), 架构上恒 <160。为让
  //           FM 8 位下标静态在界, 仍用 256 宽组合读向量(§13/§15/§7 debug), 但
  //           160..255 位填「不可达/X」而非正常 entry 数据, 且下标经 index_in_range
  //           guard(≥160→'x)。见本文件 index_in_range() 与各读向量注释。
  //  ★invalid index(≥160)是否影响输出: 否。deqPtr/walkPtr.value 由 golden mod-160
  //   环形指针产生(commitDeqPtrAll 减 10'hA0=160), 恒 <160, ≥160 分支运行期不可达。
  //   golden 自身对 ≥160 下标(_GEN_2611 等 256 宽 wire 的 [160:255] 位)填 entry-0
  //   值(firtool 越界 Vec 访问的默认 lowering), 同样不可达故无 RTL gap。★
  // =====================================================================
  // ★SoA (codex 0101 阶段1 canary + 阶段2 G1)★ commit-state / lifecycle /
  //  control / status field-family 从原 packed struct 数组 rob_entries[160]
  //  拆出为语义命名 unpacked arrays, 令 FM 按名(rob_<field>_reg[N])直接配对
  //  golden robEntries_N_<field>, 免去逐位 set_user_match 强配(=Rob FM 收敛墙:
  //  packed 数组 FM 无法 cone-reduce+签名匹配 golden per-field scalar)。
  //  SoA G1 family = 12 字段(lifecycle/control/status):
  //    canary(阶段1, 已证 A/B co-sim): valid(1b) / uop_num(7b) / std_writebacked(1b)
  //      = commit_v/commit_w 直接驱动(pCommit cone 读扇出最高): commit_v = valid;
  //        commit_w = (uop_num==0) & std_writebacked。
  //    G1 扩展(阶段2, 本 patch): need_flush(1b) / interrupt_safe(1b) / mmio(1b) /
  //      is_rvc(1b) / is_vset(1b) / is_hls(1b) / real_dest_size(7b) /
  //      instr_size(3b) / commit_type(3b)。
  //  语义 bit-exact 复刻旧 packed 版(见 §4/§12 reset/write-enable/priority):
  //  每字段 reset 0 + 下一拍取 rob_entries_next[i].<field>(与 packed 版
  //  rob_entries[i]<=rob_entries_next[i] 同源逐字), valid 另按 commit>enq>flush>hold。
  //  非-G1 字段(vls/fflags/vxsat/rf_wen/fp_wen/wflags/dirty_vs/ftq_*/trace)仍走
  //  packed struct(rob_entries_nf, 仅寄存这些字段)。
  //  rob_entries[i] 现为组合重建视图(0 flip-flop): 把 SoA family 覆盖到 nf 上,
  //  供全核读路径(next-state/robDeqGroup/lsq-deep)透明复用。
  //  旧全-packed 版整体保留于 Rob_packed_ref.sv 作同分支 A/B co-sim 参考。
  // ---- SoA G1 family 寄存器(12 字段, 每字段 160 深, 名字直接对齐 golden) ----
  //  canary 3 字段(commit-state):
  logic                 rob_valid          [ROB_SIZE]; // = golden robEntries_N_valid
  logic [UOP_CNT_W-1:0] rob_uop_num        [ROB_SIZE]; // = golden robEntries_N_uopNum
  logic                 rob_std_wb         [ROB_SIZE]; // = golden robEntries_N_stdWritebacked
  //  G1 扩展 9 字段(lifecycle/control/status):
  logic                 rob_needflush      [ROB_SIZE]; // = golden robEntries_N_needFlush
  logic                 rob_interrupt_safe [ROB_SIZE]; // = golden robEntries_N_interrupt_safe
  logic                 rob_mmio           [ROB_SIZE]; // = golden robEntries_N_mmio
  logic                 rob_is_rvc         [ROB_SIZE]; // = golden robEntries_N_isRVC
  logic                 rob_is_vset        [ROB_SIZE]; // = golden robEntries_N_isVset
  logic                 rob_is_hls         [ROB_SIZE]; // = golden robEntries_N_isHls
  logic [UOP_CNT_W-1:0] rob_real_dest_size [ROB_SIZE]; // = golden robEntries_N_realDestSize
  logic [INSTR_SIZE_W-1:0] rob_instr_size  [ROB_SIZE]; // = golden robEntries_N_instrSize
  logic [2:0]           rob_commit_type    [ROB_SIZE]; // = golden robEntries_N_commitType
  // ---- SoA G2 family (codex 0104 阶段2, pointers/indices, 3 字段, 每字段 160 深)----
  //  ftqIdx/ftqOffset 组: 取指队列指针(异常/重定向/trace 用), 从原 packed
  //  rob_entries[i].{ftq_idx_flag,ftq_idx_value,ftq_offset} 拆为语义命名 unpacked
  //  arrays, 令 FM 按名(rob_ftq_flag_reg[N]/rob_ftq_value_reg[N]/rob_ftq_offset_reg[N])
  //  直接配对 golden robEntries_N_ftqIdx_flag / _ftqIdx_value / _ftqOffset(免逐位
  //  set_user_match)。语义 bit-exact 复刻旧 packed 版(见 §4/§12 reset/write/priority)。
  logic                    rob_ftq_flag   [ROB_SIZE]; // = golden robEntries_N_ftqIdx_flag
  logic [FTQ_PTR_W-1:0]    rob_ftq_value  [ROB_SIZE]; // = golden robEntries_N_ftqIdx_value
  logic [FTQ_OFFSET_W-1:0] rob_ftq_offset [ROB_SIZE]; // = golden robEntries_N_ftqOffset
  // ---- 非-family packed 存储(G1/G2 family 位不寄存, 见 §12 always_ff)。 ----
  rob_entry_t  rob_entries_nf [ROB_SIZE];
  // ---- rob_entries 组合重建视图: nf + SoA G1 family(全核读用, 0 flip-flop) ----
  rob_entry_t  rob_entries    [ROB_SIZE];
  always_comb
    for (int i = 0; i < ROB_SIZE; i++) begin
      rob_entries[i]                 = rob_entries_nf[i];
      rob_entries[i].valid           = rob_valid[i];
      rob_entries[i].uop_num         = rob_uop_num[i];
      rob_entries[i].std_writebacked = rob_std_wb[i];
      rob_entries[i].need_flush      = rob_needflush[i];
      rob_entries[i].interrupt_safe  = rob_interrupt_safe[i];
      rob_entries[i].mmio            = rob_mmio[i];
      rob_entries[i].is_rvc          = rob_is_rvc[i];
      rob_entries[i].is_vset         = rob_is_vset[i];
      rob_entries[i].is_hls          = rob_is_hls[i];
      rob_entries[i].real_dest_size  = rob_real_dest_size[i];
      rob_entries[i].instr_size      = rob_instr_size[i];
      rob_entries[i].commit_type     = rob_commit_type[i];
      // G2 pointers/indices family 覆盖到 nf 上
      rob_entries[i].ftq_idx_flag    = rob_ftq_flag[i];
      rob_entries[i].ftq_idx_value   = rob_ftq_value[i];
      rob_entries[i].ftq_offset      = rob_ftq_offset[i];
    end
  // FM 下标空间: 组合读向量宽度用 2 的幂 256, 让 8 位 robIdx 下标静态在界
  //  (消 FMR_ELAB-147)。这些是 wire(0 寄存器), 不同于上面 ROB_SIZE 宽的寄存器阵列。
  //  160..255 位统一填「不可达/X」(见各读向量), 且下标经 index_in_range guard。
  localparam int IDX_SPACE = 256;
  rob_state_e  state;
  assign o_state = state;

  // ---- 集中越界 guard: robIdx 是否落在合法 entry 范围 [0, ROB_SIZE-1] ----
  //  唯一判据; 用于读向量 mux 下标(≥160 时返回 'x, 不 clamp/wrap/取 entry-0)。
  //  写路径无需 guard(写循环本身 for i<ROB_SIZE 已限界)。
  function automatic logic index_in_range(input logic [PTR_W-1:0] idx);
    return idx < PTR_W'(ROB_SIZE);
  endfunction

  // 入队特殊态(blockBackward/waitForward): 阻塞后续派遣直到清空。
  logic hasBlockBackward, hasWaitForward, hasWFI;
  logic deqHasFlushed;
  logic intrBitSetReg;            // RegNext(io.csr.intrBitSet)
  assign o_hasBlockBackward = hasBlockBackward;
  assign o_hasNoSpecExec    = hasWaitForward;
  assign o_intrBitSetReg    = intrBitSetReg;

  // hasCommitted/donotNeedWalk: 同一行内已提交/无需walk的标记(跨拍累计)。
  logic [COMMIT_WIDTH-1:0] hasCommitted, donotNeedWalk;
  assign o_hasCommitted = hasCommitted;

  // =====================================================================
  // 1. enqueue: 入队判定 + 写条目
  //    canEnqueue[i] = req.valid & firstUop & canAccept。
  //    allocatePtrVec[i] = enqPtrVec[ 前 i 口里有效 firstUop 个数 ]。
  // =====================================================================
  logic [RENAME_WIDTH-1:0] canEnqueue;
  logic [RENAME_WIDTH-1:0] enqForPtr;     // req.valid & firstUop(给 enqPtrGen / 计数)
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++)
      enqForPtr[i] = enq_valid[i] & enq_first_uop[i];
  assign o_enq_for_ptr = enqForPtr;

  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++)
      canEnqueue[i] = enq_valid[i] & enq_first_uop[i] & o_enq_canAccept;

  // allocatePtrVec[i]: 选第 (前序有效 firstUop 数) 个 enqPtrVec。
  rob_ptr_t allocate_ptr [RENAME_WIDTH];
  // enq_ptr_vec 8 宽(2 的幂)padded 视图: prior 是 3 位(0..7), 直接索引 8 宽消越界
  //  (FMR_ELAB-147); 6/7 项填 0, prior 架构 <= i < RENAME_WIDTH 故不被读, 行为等价。
  rob_ptr_t enqPtrVec8 [8];
  always_comb begin
    for (int k = 0; k < 8; k++) enqPtrVec8[k] = '0;
    for (int k = 0; k < RENAME_WIDTH; k++) enqPtrVec8[k] = enq_ptr_vec[k];
  end
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic [2:0] prior;
      prior = '0;
      for (int j = 0; j < i; j++) prior += 3'(enqForPtr[j]);
      allocate_ptr[i] = enqPtrVec8[prior];
    end

  // dispatchNum: 本拍真正入队的指令数(给 allowEnqueue 计数)。
  logic [3:0] dispatchNum;
  always_comb begin
    dispatchNum = '0;
    if (o_enq_canAccept)
      for (int i = 0; i < RENAME_WIDTH; i++)
        dispatchNum += 4'(enqForPtr[i]);
  end

  // =====================================================================
  // 2. canAccept: 队列未满 & 无 blockBackward & rab/vtype 可入 & 向量异常模块空闲
  // =====================================================================
  logic allowEnqueue, allowEnqueueForDispatch;
  assign o_allowEnqueue = allowEnqueue;
  always_comb begin
    o_enq_canAccept            = allowEnqueue            & ~hasBlockBackward & rab_can_enq & ~io_fromVecExcpMod_busy;
    o_enq_canAcceptForDispatch = allowEnqueueForDispatch & ~hasBlockBackward & rab_can_enq & ~io_fromVecExcpMod_busy;
  end
  assign o_robFull = ~allowEnqueue;

  // =====================================================================
  // 3. 8-bank 行读流水(对齐 golden Rob.scala 205-263 的 robBanksRdata / robDeqGroup)
  //    robBanks(b) = 所有 robIdx%8==b 的条目(每 bank 20 条); 用「寄存的 one-hot 行
  //    读地址 robBanksRaddrThisLine」做 Mux1H 行读, NextLine 用 bank 左移一位读下一行。
  //    读出后即时合并本拍 writeback/enq(needUpdate), 再经 connectCommitEntry 落进
  //    寄存器 robDeqGroup。allCommitted 时 robDeqGroup 直接取 NextLine(下一行读)。
  // =====================================================================
  rob_ptr_t deqPtr, walkPtr_head;
  assign deqPtr = deq_ptr_vec[0];

  // 行读地址(one-hot, ENTRY_PER_BANK 宽), 寄存器。复位 = 行 0(bit0=1)。
  logic [ENTRY_PER_BANK-1:0] robBanksRaddrThisLine;
  logic [ENTRY_PER_BANK-1:0] robBanksRaddrNextLine;  // 组合(FSM, 见 §12)

  // 行号(高位): 由当前 one-hot 行读地址译码; this/next 行的 robIdx。
  function automatic logic [PTR_W-1:0] onehot_to_row(input logic [ENTRY_PER_BANK-1:0] oh);
    logic [PTR_W-1:0] r;
    r = '0;
    for (int e = 0; e < ENTRY_PER_BANK; e++) if (oh[e]) r = PTR_W'(e);
    return r;
  endfunction
  logic [PTR_W-1:0] highDeqPtrThisLine, highDeqPtrNextLine;
  always_comb begin
    highDeqPtrThisLine = onehot_to_row(robBanksRaddrThisLine);
    highDeqPtrNextLine = (highDeqPtrThisLine == PTR_W'(ENTRY_PER_BANK-1))
                       ? '0 : (highDeqPtrThisLine + PTR_W'(1));
  end
  // 各 bank 在 this/next 行的 robIdx = row*8 + bank。
  logic [PTR_W-1:0] robIdxThisLine [COMMIT_WIDTH];
  logic [PTR_W-1:0] robIdxNextLine [COMMIT_WIDTH];
  always_comb
    for (int b = 0; b < BANK_NUM; b++) begin
      robIdxThisLine[b] = {highDeqPtrThisLine[PTR_W-1-BANK_SEL_W:0], BANK_SEL_W'(b)};
      robIdxNextLine[b] = {highDeqPtrNextLine[PTR_W-1-BANK_SEL_W:0], BANK_SEL_W'(b)};
    end

  // robDeqGroup: 寄存的当前行 8 个 bank 提交条目(对齐 golden 的 Reg)。
  rob_commit_entry_t robDeqGroup [COMMIT_WIDTH];

  // =====================================================================
  // 4. writeback → 条目状态更新的「下一拍值」(组合算, 时序在第 12 节落寄存器)
  //    对每条 robEntries(i):
      //   needFlush:  excp_wb 命中且置 needFlush;
      //   uopNum:     命中普通 wb 时减 wbNum;
      //   std:        命中 std wb 置 1;
      //   fflags/vxsat: 累计或;
      //   trace itype: 分支 taken 改 Taken;
      //   enq:         首次入队置 uopNum=numWB, std=(isStore?0:1), realDestSize 等。
  // =====================================================================
  // 每条目: 本拍是否被某入队口命中(robIdx 匹配 & 有效 firstUop)。
  // ★FMR-strict (codex 0103 修3)★ 原先这些是 `function automatic f(idx)` 读模块级
  //  wb_*/enq_*/excp_* 数组 → FM 报 FMR_VLOG-091(function 读 non-local net)。语义上
  //  纯只读(不写 non-local)故无真 sim/synth 风险, 但 strict 门禁要求 0 FMR-091, 且
  //  filter 掩盖非诚实。∴改为模块级 always_comb 预算数组(procedural module code 读
  //  模块信号合法, 不触发 FMR-091), 表达式与原 function 逐字一致, 0 语义变化。
  //  下标空间用 ROB_SIZE(与旧 f(i) 调用域 i∈[0,ROB_SIZE) 相同)。
  logic [4:0]              sum_wb_for_arr        [ROB_SIZE];
  logic                    any_std_wb_for_arr    [ROB_SIZE];
  logic [4:0]              or_fflags_for_arr     [ROB_SIZE];
  logic                    or_vxsat_for_arr      [ROB_SIZE];
  logic                    any_branch_taken_arr  [ROB_SIZE];
  logic                    any_excp_flush_arr    [ROB_SIZE];
  logic [RENAME_WIDTH-1:0] enq_inst_hit_arr      [ROB_SIZE];
  logic [UOP_CNT_W-1:0]    real_dest_enq_num_arr [ROB_SIZE];
  // 前置声明(被后文 always_ff/always_comb 引用, 其 always_comb 赋值在各自定义点):
  logic                    commit_hit_arr             [ROB_SIZE];
  logic                    in_flush_range_arr         [ROB_SIZE];
  logic                    enq_allow_interrupt_hit_arr [ROB_SIZE];
  logic [UOP_CNT_W:0]      prefix_realdest_commit_arr [COMMIT_WIDTH];
  logic [UOP_CNT_W:0]      prefix_realdest_walk_arr   [COMMIT_WIDTH];
  logic [34:0]             enq_fuType_hit_arr         [ROB_SIZE];
  always_comb
    for (int idx = 0; idx < ROB_SIZE; idx++) begin
      // sum_wb_for
      sum_wb_for_arr[idx] = '0;
      for (int p = 0; p < NUM_EXU_WB; p++)
        if (wb_valid[p] & (wb_robidx[p] == PTR_W'(idx)))
          sum_wb_for_arr[idx] += wb_num[p];
      // any_std_wb_for
      any_std_wb_for_arr[idx] = 1'b0;
      for (int p = 0; p < NUM_EXU_WB; p++)
        if (wb_is_std[p] & wb_valid[p] & (wb_robidx[p] == PTR_W'(idx))) any_std_wb_for_arr[idx] = 1'b1;
      // or_fflags_for
      or_fflags_for_arr[idx] = '0;
      for (int p = 0; p < NUM_EXU_WB; p++)
        if (wb_fflags_valid[p] & wb_valid[p] & (wb_robidx[p] == PTR_W'(idx))) or_fflags_for_arr[idx] |= wb_fflags[p];
      // or_vxsat_for
      or_vxsat_for_arr[idx] = 1'b0;
      for (int p = 0; p < NUM_EXU_WB; p++)
        if (wb_vxsat_valid[p] & wb_vxsat[p] & wb_valid[p] & (wb_robidx[p] == PTR_W'(idx))) or_vxsat_for_arr[idx] = 1'b1;
      // any_branch_taken_for
      any_branch_taken_arr[idx] = 1'b0;
      for (int p = 0; p < NUM_EXU_WB; p++)
        if (wb_branch_taken[p] & wb_valid[p] & (wb_robidx[p] == PTR_W'(idx))) any_branch_taken_arr[idx] = 1'b1;
      // any_excp_flush_for
      any_excp_flush_arr[idx] = 1'b0;
      for (int p = 0; p < NUM_WB; p++)
        if (excp_wb_valid[p] & excp_wb_need_flush[p] & (excp_wb_robidx[p] == PTR_W'(idx))) any_excp_flush_arr[idx] = 1'b1;
      // enq_inst_hit: 该 robIdx 被哪个口的 firstUop 占用。
      for (int i = 0; i < RENAME_WIDTH; i++)
        enq_inst_hit_arr[idx][i] = canEnqueue[i] & (allocate_ptr[i].value == PTR_W'(idx));
      // real_dest_enq_num: 该 robIdx 上「真正写寄存器堆」的 uop 数。
      real_dest_enq_num_arr[idx] = '0;
      for (int i = 0; i < RENAME_WIDTH; i++)
        if (enq_valid[i] & o_enq_canAccept & enq_need_write_rf[i] & (enq_robidx_value[i] == PTR_W'(idx)))
          real_dest_enq_num_arr[idx] += UOP_CNT_W'(1);
    end

  // =====================================================================
  // 5. robDeqGroup 行读更新: 把「行内 8 条 + 下一行 8 条」按 writeback/enq 更新后
  //    存进 robDeqGroup(本可读核简化: 直接用 rob_entries 当前值经 connect 装入,
  //    writeback 的当拍合并在 rob_entries 的下一拍值里体现)。
  //    注: golden 用 robBanksRdataThisLineUpdate 做「读出后即时合并 wb」, 这里
  //    用 connect_commit_entry(下一拍 entry) 表达同一语义。
  // =====================================================================
  // rob_entries_next 是纯组合(always_comb)下一拍值, 非寄存器(0 flip-flop, 不计入
  //  impl reg)。宽度用 IDX_SPACE=256 让 8 位行读下标 robIdxThisLine[b] 静态在界
  //  (消 FMR_ELAB-147); 160..255 项填不可达 'x(下方 §3 行读下标恒 row*8+bank<160)。
  rob_entry_t rob_entries_next [IDX_SPACE];
  always_comb begin
    // 160..255 死项: 不可达组合默认 'x(非正常 entry 数据; 行读下标恒 <160 不选中)。
    for (int i = ROB_SIZE; i < IDX_SPACE; i++) rob_entries_next[i] = 'x;
    for (int i = 0; i < ROB_SIZE; i++) begin
      rob_entry_t e;
      logic [RENAME_WIDTH-1:0] ihit;
      logic                    is_first_enq;
      logic [4:0]              wbc;
      logic                    nf_wb;
      e   = rob_entries[i];
      ihit = enq_inst_hit_arr[i];
      is_first_enq = ~rob_entries[i].valid & (|ihit);
      wbc   = sum_wb_for_arr[i];
      nf_wb = any_excp_flush_arr[i];

      // ---- valid ----
      // commit 清, enq 置(redirect 拍不入队), redirect flush 清。
      // (commit/flush 的具体条件在第 12 节时序里和 commit 决策一起处理。)

      // ---- needFlush ----
      if (rob_entries[i].valid)
        e.need_flush = rob_entries[i].need_flush | nf_wb;

      // ---- uopNum / stdWritebacked ----
      if (rob_entries[i].valid & (rob_entries[i].need_flush | nf_wb)) begin
        e.uop_num         = rob_entries[i].uop_num - wbc;
        e.std_writebacked = 1'b1;
      end else if (~rob_entries[i].valid & (|ihit)) begin
        // enq: 取命中口的 numWB; isStore 则 std 待回。
        logic [UOP_CNT_W-1:0] nwb;
        logic                 wstd;
        nwb  = '0; wstd = 1'b0;
        for (int k = RENAME_WIDTH-1; k >= 0; k--)
          if (ihit[k]) begin nwb = enq_num_wb[k]; wstd = enq_write_std[k]; end
        e.uop_num         = nwb;
        e.std_writebacked = ~wstd;
      end else if (rob_entries[i].valid) begin
        e.uop_num = rob_entries[i].uop_num - wbc;
        if (any_std_wb_for_arr[i]) e.std_writebacked = 1'b1;
      end

      // ---- realDestSize ----
      if (is_first_enq)
        e.real_dest_size = real_dest_enq_num_arr[i];
      else if (rob_entries[i].valid & (|enq_inst_hit_arr[i]))
        e.real_dest_size = rob_entries[i].real_dest_size + real_dest_enq_num_arr[i];

      // ---- fflags / vxsat ----
      if (is_first_enq) e.fflags = '0;
      else              e.fflags = rob_entries[i].fflags | or_fflags_for_arr[i];
      if (is_first_enq) e.vxsat = 1'b0;
      else              e.vxsat = rob_entries[i].vxsat | or_vxsat_for_arr[i];

      // ---- trace itype: 分支 taken → Taken(=3) ----
      if (rob_entries[i].valid & is_branch_type(rob_entries[i].itype) & any_branch_taken_arr[i])
        e.itype = 4'd3;

      // ---- 入队静态信息 + 状态初值(首次入队覆盖) ----
      if (is_first_enq) begin
        rob_entry_t s;
        s = '0;
        for (int k = RENAME_WIDTH-1; k >= 0; k--)
          if (ihit[k]) s = enq_info[k];
        e.rf_wen        = s.rf_wen;
        e.fp_wen        = s.fp_wen;
        e.wflags        = s.wflags;
        e.dirty_vs      = s.dirty_vs;
        e.commit_type   = s.commit_type;
        e.is_rvc        = s.is_rvc;
        e.is_vset       = s.is_vset;
        e.is_hls        = s.is_hls;
        e.instr_size    = s.instr_size;
        e.ftq_idx_value = s.ftq_idx_value;
        e.ftq_idx_flag  = s.ftq_idx_flag;
        e.ftq_offset    = s.ftq_offset;
        e.itype         = s.itype;
        e.iretire       = s.iretire;
        e.ilastsize     = s.ilastsize;
        e.need_flush    = s.need_flush;          // hasException||flushPipe
        e.mmio          = 1'b0;                  // 入队清, 之后由 lsq.mmio 置
        e.vls           = s.vls;
        e.interrupt_safe= enq_allow_interrupt_hit_arr[i];
      end
      rob_entries_next[i] = e;
    end
  end

  // ---- SoA family 下一拍(组合): uop_num/std_wb 直取 rob_entries_next(与 packed
  //  版 §12 落 rob_entries[i]<=rob_entries_next[i] 同源); valid 的下一拍在 §12
  //  always_ff 里按 commit/enq/flush 优先级单独覆盖(与 packed 版逐字一致)。 ----
  logic [UOP_CNT_W-1:0] rob_uop_num_next [ROB_SIZE];
  logic                 rob_std_wb_next  [ROB_SIZE];
  always_comb
    for (int i = 0; i < ROB_SIZE; i++) begin
      rob_uop_num_next[i] = rob_entries_next[i].uop_num;
      rob_std_wb_next[i]  = rob_entries_next[i].std_writebacked;
    end

  // ---- SoA G2 family 下一拍(组合): ftq flag/value/offset 直取 rob_entries_next
  //  (与 packed 版 §12 落 rob_entries[i]<=rob_entries_next[i] 同源; enq 命中口写入
  //  s.ftq_*, 非命中/非 enq 保持, 见 §4 next-state 逐字复刻 golden)。 ----
  logic                    rob_ftq_flag_next   [ROB_SIZE];
  logic [FTQ_PTR_W-1:0]    rob_ftq_value_next  [ROB_SIZE];
  logic [FTQ_OFFSET_W-1:0] rob_ftq_offset_next [ROB_SIZE];
  always_comb
    for (int i = 0; i < ROB_SIZE; i++) begin
      rob_ftq_flag_next[i]   = rob_entries_next[i].ftq_idx_flag;
      rob_ftq_value_next[i]  = rob_entries_next[i].ftq_idx_value;
      rob_ftq_offset_next[i] = rob_entries_next[i].ftq_offset;
    end

  // 分支类型判定(itype: 4=NoBranch/NotTaken 之外的 branch code)。
  function automatic logic is_branch_type(input logic [ITYPE_W-1:0] t);
    // 香山 Itype: branch 类(Taken=3, NotTaken=4 也算 branch);此处保留与 golden 同义。
    return (t >= 4'd3) & (t <= 4'd6);
  endfunction
  // 入队该条目 interrupt_safe: 命中口的 allow_interrupt。
  // ★FMR-strict (修3)★ 原读模块级 enq_allow_interrupt/enq_inst_hit → 改 always_comb 数组。
  // (声明前置于 §4 helper-array 块, 因 §4 next-state always_comb 之前引用。)
  always_comb
    for (int idx = 0; idx < ROB_SIZE; idx++) begin
      enq_allow_interrupt_hit_arr[idx] = 1'b0;
      for (int k = RENAME_WIDTH-1; k >= 0; k--)
        if (enq_inst_hit_arr[idx][k]) enq_allow_interrupt_hit_arr[idx] = enq_allow_interrupt[k];
    end

  // 行读 + 即时合并(needUpdate): this/next 行各 8 bank 的「读出已合并本拍 wb/enq」条目。
  // rob_entries_next[idx] 即 golden 的 needUpdate(读出后合并)语义, 故直接索引即可。
  rob_entry_t robBanksRdataThisLineUpdate [COMMIT_WIDTH];
  rob_entry_t robBanksRdataNextLineUpdate [COMMIT_WIDTH];
  always_comb
    for (int b = 0; b < BANK_NUM; b++) begin
      robBanksRdataThisLineUpdate[b] = rob_entries_next[robIdxThisLine[b]];
      robBanksRdataNextLineUpdate[b] = rob_entries_next[robIdxNextLine[b]];
    end

  // robDeqGroup 的下一拍值: 每拍取 thisLineUpdate; allCommitted 时取 nextLineUpdate。
  rob_commit_entry_t robDeqGroup_next [COMMIT_WIDTH];
  always_comb
    for (int b = 0; b < BANK_NUM; b++)
      robDeqGroup_next[b] = o_allCommitted
                          ? connect_commit_entry(robBanksRdataNextLineUpdate[b])
                          : connect_commit_entry(robBanksRdataThisLineUpdate[b]);

  // 每个提交槽 i 取所在 bank 的 robDeqGroup(golden: deqPtrVec(i)/walkPtrVec(i) 的低 3 位)。
  rob_commit_entry_t commitInfo [COMMIT_WIDTH];
  rob_commit_entry_t walkInfo   [COMMIT_WIDTH];
  always_comb
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
      commitInfo[i] = robDeqGroup[deq_ptr_vec[i].value[BANK_ADDR_W-1:0]];
      walkInfo[i]   = robDeqGroup[walkPtrVec[i].value[BANK_ADDR_W-1:0]];
    end

  // 每提交槽在全存储 rob_entries 里的下标(deq_ptr_vec[i].value 架构 < ROB_SIZE, 由
  //  golden mod-160 环形指针保证)。index_in_range guard: ≥160 时下标取 'x(不可达,
  //  ≠clamp/wrap/取 entry-0)——喂 256 宽读向量的 'x 顶部, 读出 'x。运行期 ≥160 不发生。
  logic [PTR_W-1:0] deqValIdx [COMMIT_WIDTH];
  always_comb
    for (int i = 0; i < COMMIT_WIDTH; i++)
      deqValIdx[i] = index_in_range(deq_ptr_vec[i].value) ? deq_ptr_vec[i].value : 'x;

  always_comb
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
      o_commit_info[i]    = (state == S_IDLE) ? commitInfo[i] : walkInfo[i];
      o_commits_robIdx[i] = deq_ptr_vec[i];
    end

  // per-bank commit_v / commit_w(给 deqPtrGen)。
  always_comb
    for (int b = 0; b < BANK_NUM; b++) begin
      o_deq_commit_v[b] = robDeqGroup[b].commit_v;
      o_deq_commit_w[b] = robDeqGroup[b].commit_w;
    end

  // =====================================================================
  // 6. 异常 / 中断 / flushPipe 判定(队头) —— 精确异常优先级核心
  //    deqPtrEntry = robDeqGroup(bank0 对应 deqPtr)。
  //    intrEnable : 中断挂起 & 无 waitForward & 队头 interrupt_safe & 未已刷。
  //    deqHasException : 队头 needFlush 命中 exceptionGen 且确为异常。
  //    优先级: 中断 > 异常 > flushPipe/replay(由 flushOut.level 与 commit 阻塞体现)。
  // =====================================================================
  rob_commit_entry_t deqPtrEntry;
  always_comb deqPtrEntry = robDeqGroup[deqPtr.value[BANK_ADDR_W-1:0]];
  logic deqPtrEntryValid;
  assign deqPtrEntryValid = deqPtrEntry.commit_v;

  logic deqHitEG, deqNeedFlush, deqNeedFlushAndHitEG;
  always_comb begin
    deqHitEG             = eg_valid & (eg_robidx_value == deqPtr.value) & (eg_robidx_flag == deqPtr.flag);
    deqNeedFlush         = deqPtrEntry.need_flush & deqPtrEntry.commit_v & deqPtrEntry.commit_w;
    deqNeedFlushAndHitEG = deqNeedFlush & deqHitEG;
  end

  logic intrEnable;
  always_comb intrEnable = intrBitSetReg & ~hasWaitForward & deqPtrEntry.interrupt_safe & ~deqHasFlushed;
  assign o_intrEnable = intrEnable;

  logic deqHasException, deqHasFlushPipe, deqHasReplayInst, deqIsVlsException;
  // vls 路 2 拍门控(golden Rob.scala 578-584):
  //   deqHasException 在 vls 时需 RegNext(RegNext(deqPtrEntry.commit_w)) 才置;
  //   deqVlsCanCommit = RegNext(RegNext(deqIsVlsException && commit_w)) && rab.commitEnd。
  logic commit_w_d1, commit_w_d2;        // RegNext / RegNext(RegNext)(deqPtrEntry.commit_w)
  logic vlsExcCommitw_d1, vlsExcCommitw_d2; // RegNext^2(deqIsVlsException & commit_w)
  logic deqVlsCanCommit;
  logic vlsCommitwGate;                  // (!isVls || RegNext(RegNext(commit_w)))
  always_comb vlsCommitwGate = ~deqPtrEntry.is_vls | commit_w_d2;
  always_comb deqVlsCanCommit = vlsExcCommitw_d2 & rab_status_commit_end;
  always_comb begin
    deqHasException  = deqNeedFlushAndHitEG & eg_is_exception  & vlsCommitwGate;
    deqHasFlushPipe  = deqNeedFlushAndHitEG & eg_flush_pipe & ~deqHasException & vlsCommitwGate;
    deqHasReplayInst = deqNeedFlushAndHitEG & eg_replay_inst;
    deqIsVlsException= deqHasException & deqPtrEntry.is_vls & ~eg_is_enq_excp;
  end
  logic isFlushPipe;
  always_comb isFlushPipe = deqPtrEntry.commit_w & (deqHasFlushPipe | deqHasReplayInst);

  // lastCycleFlush: 上拍 flushOut.valid(本拍封锁 commit/redirect)。
  logic lastCycleFlush;

  // flushOut.valid: idle & 队头有效 & (中断|异常|flushPipe) & 未刚刷。
  always_comb begin
    o_flushOut_valid = (state == S_IDLE) & deqPtrEntryValid
                     & (intrEnable | (deqHasException & (~deqIsVlsException | deqVlsCanCommit)) | isFlushPipe)
                     & ~lastCycleFlush;
    o_flushOut_robIdx_flag  = deqPtr.flag;
    o_flushOut_robIdx_value = deqPtr.value;
    o_flushOut_isRVC        = deqPtrEntry.is_rvc;
    o_flushOut_ftqIdx_value = deqPtrEntry.ftq_idx_value;
    o_flushOut_ftqIdx_flag  = deqPtrEntry.ftq_idx_flag;
    o_flushOut_ftqOffset    = deqPtrEntry.ftq_offset;
    // level: replay/中断/异常 → flush(含自身, level=1); 否则 flushAfter(level=0)。
    // (对齐 golden io_flushOut_bits_level = deqHasReplayInst|intrEnable|deqHasException)
    o_flushOut_level        = deqHasReplayInst | intrEnable | deqHasException;
  end
  assign o_eg_flush = o_flushOut_valid;

  // exceptionHappen → exception.valid 打一拍。
  logic exceptionHappen;
  always_comb exceptionHappen = (state == S_IDLE) & deqPtrEntryValid
                              & (intrEnable | (deqHasException & (~deqIsVlsException | deqVlsCanCommit)))
                              & ~lastCycleFlush;

  // =====================================================================
  // 7. commit 决策(idle 态)
  //    blockCommit: 误预测窗口/刚刷/WFI/redirect/队头需刷未刷/critical 等任一→停提交。
  //    commitValidThisLine[i]: 该槽可提交 = commit_v & commit_w & 不被阻塞 & 不被更老阻塞。
  // =====================================================================
  logic blockCommit;
  logic misPredBlock, deqFlushBlock;
  always_comb begin
    blockCommit = misPredBlock | lastCycleFlush | hasWFI | io_redirect_valid
                | (deqNeedFlush & ~deqHasFlushed) | deqFlushBlock
                | io_csr_criticalErrorState | io_trace_blockCommit;
  end
  assign o_blockCommit = blockCommit;

  always_comb begin
    o_commits_isWalk   = (state == S_WALK);
    o_commits_isCommit = (state == S_IDLE) & ~blockCommit;
  end

  // allowOnlyOneCommit: 队头组里有 needFlush 的有效条目, 或中断挂起 → 每拍只提交一条。
  logic allowOnlyOneCommit;
  always_comb begin
    logic any_flush_entry;
    any_flush_entry = 1'b0;
    for (int b = 0; b < BANK_NUM; b++)
      any_flush_entry |= robDeqGroup[b].commit_v & robDeqGroup[b].need_flush;
    allowOnlyOneCommit = any_flush_entry | intrBitSetReg;
  end
  assign o_allowOnlyOneCommit = allowOnlyOneCommit;

  // commit_block[i]: 该槽未写回且未提交(更老者会阻塞更新者)。
  logic [COMMIT_WIDTH-1:0] commitValidThisLine;
  always_comb begin
    logic [COMMIT_WIDTH-1:0] commit_block;
    for (int i = 0; i < COMMIT_WIDTH; i++)
      commit_block[i] = ~robDeqGroup[i].commit_w & ~hasCommitted[i];
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
      logic isBlocked, isBlockedByOlder;
      isBlocked = intrEnable | (deqNeedFlush & ~deqHasFlushed);
      if (i == 0) isBlockedByOlder = 1'b0;
      else begin
        logic blk, only_older_all_committed;
        // blk: 本槽或任一更老槽未就绪(commit_block[0..i]);
        // only: allowOnlyOneCommit 且更老槽(0..i-1)未全部已提交 → 阻塞。
        blk = 1'b0;
        for (int j = 0; j <= i; j++) blk |= commit_block[j];
        only_older_all_committed = 1'b1;
        for (int j = 0; j < i; j++) only_older_all_committed &= hasCommitted[j];
        isBlockedByOlder = blk | (allowOnlyOneCommit & ~only_older_all_committed);
      end
      commitValidThisLine[i] = robDeqGroup[i].commit_v & robDeqGroup[i].commit_w
                             & ~isBlocked & ~isBlockedByOlder & ~hasCommitted[i];
    end
  end

  // io.commits.commitValid: 用 PriorityMux 把 commitValidThisLine 右移对齐(连续提交)。
  always_comb begin
    o_commits_commitValid = '0;
    for (int i = COMMIT_WIDTH-1; i >= 0; i--)
      if (commitValidThisLine[i])
        o_commits_commitValid = COMMIT_WIDTH'(commitValidThisLine >> i);
  end

  // allCommitted: isCommit 且本行最后一槽也提交了。
  always_comb o_allCommitted = o_commits_isCommit & commitValidThisLine[COMMIT_WIDTH-1];

  // =====================================================================
  // 8. walk 决策(walk 态)
  //    shouldWalkVec: walk 态且未到 redirect 边界且非 donotNeedWalk。
  //    walkValid[i] = shouldWalkVec[i]。
  // =====================================================================
  logic [COMMIT_WIDTH-1:0] shouldWalkVec;
  // walkingPtrVec/lastWalkPtr 在第 12 节维护; 这里给出 walkValid。
  always_comb o_commits_walkValid = shouldWalkVec;

  // =====================================================================
  // 9. rab 的 commitSize / walkSize(回收映射数)
  //    commitSizeSum: 本拍提交各槽 realDestSize 之和(已提交的计 0);
  //    walkSizeSum:   本拍 walk 各槽 realDestSize 之和(donotNeedWalk 计 0)。
  // =====================================================================
  always_comb begin
    logic [UOP_CNT_W:0] csum, wsum;
    csum = '0; wsum = '0;
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
      // 累计到「最高一个有效槽」: 用前缀和的优先选择(commit 用 commitValid|hasCommitted)。
      if (o_commits_isCommit & (commitValidThisLine[i] | hasCommitted[i]))
        csum = prefix_realdest_commit_arr[i];
      if (o_commits_isWalk & (shouldWalkVec[i] | donotNeedWalk[i]))
        wsum = prefix_realdest_walk_arr[i];
    end
    o_rab_commitSize = csum;
    o_rab_walkSize   = wsum;
  end
  // ★FMR-strict (修3)★ prefix 和读模块级 hasCommitted/donotNeedWalk/robDeqGroup →
  //  改 always_comb 数组(索引 upto∈[0,COMMIT_WIDTH))。表达式逐字一致。
  // (prefix_realdest_*_arr 声明前置于 §4 helper-array 块。)
  always_comb
    for (int upto = 0; upto < COMMIT_WIDTH; upto++) begin
      prefix_realdest_commit_arr[upto] = '0;
      prefix_realdest_walk_arr[upto]   = '0;
      for (int i = 0; i <= upto; i++) begin
        prefix_realdest_commit_arr[upto] += hasCommitted[i]  ? '0 : {1'b0, robDeqGroup[i].real_dest_size};
        prefix_realdest_walk_arr[upto]   += donotNeedWalk[i] ? '0 : {1'b0, robDeqGroup[i].real_dest_size};
      end
    end

  // walkFinished / walkEnd 在第 12 节随 walkPtrTrue 维护。
  logic walkFinished;
  always_comb o_rab_walkEnd = (state == S_WALK) & walkFinished;

  // =====================================================================
  // 10. 队列占用 / allowEnqueue 阈值
  //     numValidEntries = enqPtr - deqPtr(环形距离)。
  // =====================================================================
  rob_ptr_t enqPtr;
  assign enqPtr = enq_ptr_vec[0];
  logic [PTR_W:0] numValidEntries;
  always_comb begin
    if (enqPtr.flag == deqPtr.flag)
      numValidEntries = {1'b0, PTR_W'(enqPtr.value - deqPtr.value)};
    else
      numValidEntries = (PTR_W+1)'(ROB_SIZE) - {1'b0, deqPtr.value} + {1'b0, enqPtr.value};
  end
  assign o_numValidEntries = numValidEntries;

  // headNotReady: 队头有效但未写回(commit_v & !commit_w)。
  always_comb o_headNotReady = robDeqGroup[deqPtr.value[BANK_SEL_W-1:0]].commit_v
                             & ~robDeqGroup[deqPtr.value[BANK_SEL_W-1:0]].commit_w;

  // =====================================================================
  // 11. WFI / cpu_halt
  //     清除条件(golden): RegNext(RegNext(wfiEvent)) | flushOut.valid | timeout。
  //     timeout: 20 位计数器, hasWFI 时 +1, 退出 WFI(下降沿)清零, 全 1 即超时。
  // =====================================================================
  logic wfiSafe;
  always_comb wfiSafe = io_wfi_safeFromMem & io_wfi_safeFromFrontend;
  assign o_wfiReq   = hasWFI;
  assign o_cpu_halt = hasWFI & wfiSafe;

  // wfiEvent 打两拍 + 20 位 timeout 计数(对齐 golden Rob.scala 411-422)。
  logic wfiEvent_d1, wfiEvent_d2;
  logic [19:0] wfi_cycles;
  logic        hasWFI_d1;
  logic        wfi_timeout;
  always_comb wfi_timeout = &wfi_cycles;
  // wfiClr 在主时序里用 (wfiEvent_d2 | flushOut | timeout) 计算。

  // =====================================================================
  // 12. 时序更新
  // =====================================================================
  // ---- 12a. donotNeedWalk 用的 walkPtrLowBits / lastWalkPtr / walk 指针族 ----
  rob_ptr_t walkPtrVec [COMMIT_WIDTH];   // 8 路 walk 指针(连续)
  rob_ptr_t walkingPtrVec [COMMIT_WIDTH];// RegNext(walkPtrVec)
  rob_ptr_t walkPtrTrue, lastWalkPtr;
  logic [BANK_ADDR_W-1:0] walkPtrLowBits;
  logic redirectValidReg;

  // 环形指针加法。
  // ★FMR-strict (修3)★ 用纯三元表达式【单路径 return】消 FMR_ELAB-118(FM 对含
  //  if/else 分支+逐字段 struct 赋值的 function 会保守报 "may not return a value";
  //  无分支的单 return struct-literal 令 FM 见确定返回值)。语义逐字不变:
  //   wrap = (raw.value >= RobSize); value 取模 RobSize; flag 在 wrap 时翻转。
  function automatic rob_ptr_t ptr_add(input rob_ptr_t p, input logic [PTR_W:0] inc);
    logic [PTR_W:0]   raw;
    logic             wrap;
    raw  = {p.flag, p.value} + inc;
    wrap = (raw[PTR_W-1:0] >= PTR_W'(ROB_SIZE));
    return '{value: (wrap ? (raw[PTR_W-1:0] - PTR_W'(ROB_SIZE)) : raw[PTR_W-1:0]),
             flag:  (wrap ? ~p.flag : p.flag)};
  endfunction

  // 环形指针减 1(XiangShan CircularQueuePtr `- 1`, 对齐 golden lastWalkPtr_flipped):
  //   new_value = value + (RobSize-1); 若 >= RobSize 则 -RobSize 且 flag 不翻转,
  //   否则(value==0)结果 value=RobSize-1 且 flag 翻转(借位绕到上一圈)。
  function automatic rob_ptr_t ptr_sub1(input rob_ptr_t p);
    logic [PTR_W:0] nv, dv;
    rob_ptr_t o;
    o = '0;   // FM 静态分析要求确定返回值(FMR_ELAB-118)
    nv = {1'b0, p.value} + (PTR_W+1)'(ROB_SIZE-1);
    dv = nv - (PTR_W+1)'(ROB_SIZE);
    if (nv >= (PTR_W+1)'(ROB_SIZE)) begin
      o.value = dv[PTR_W-1:0];
      o.flag  = p.flag;          // value>=1: 不翻转
    end else begin
      o.value = nv[PTR_W-1:0];   // = RobSize-1
      o.flag  = ~p.flag;         // value==0: 借位翻转
    end
    return o;
  endfunction

  // shouldWalkVec(组合, 依赖 walkingPtrVec/lastWalkPtr/donotNeedWalk)。
  always_comb begin
    if (io_redirect_valid | redirectValidReg)
      shouldWalkVec = '0;
    else if (state == S_WALK)
      for (int i = 0; i < COMMIT_WIDTH; i++)
        shouldWalkVec[i] = ptr_le(walkingPtrVec[i], lastWalkPtr) & ~donotNeedWalk[i];
    else
      shouldWalkVec = '0;
  end
  // 环形指针严格大于(XiangShan CircularQueuePtr 比较):
  //   a > b  ==  (a.flag ^ b.flag) ^ (a.value > b.value)
  // (flag 不同表示绕回一圈, 比较结果取反; 用 {flag,value} 直接比较是错的。)
  function automatic logic ptr_gt(input rob_ptr_t a, input rob_ptr_t b);
    return (a.flag ^ b.flag) ^ (a.value > b.value);
  endfunction
  // 环形「<=」比较 = ~(a > b)。
  function automatic logic ptr_le(input rob_ptr_t a, input rob_ptr_t b);
    return ~ptr_gt(a, b);
  endfunction

  // walkFinished = walkPtrTrue > lastWalkPtr(环形严格大于)。
  always_comb walkFinished = ptr_gt(walkPtrTrue, lastWalkPtr);

  // walkPtr_head = walkPtrVec_next[0] 的行头(给行读)。下一拍 walk 指针计算:
  rob_ptr_t walkPtrVec_next [COMMIT_WIDTH];
  rob_ptr_t walkPtrTrue_next;
  rob_ptr_t snapHead, deqNextHead;
  always_comb begin
    // 行头 = 低 BANK_ADDR_W 位清零。
    snapHead.flag    = snap_ptr0.flag;
    snapHead.value   = {snap_ptr0.value[PTR_W-1:BANK_ADDR_W], {BANK_ADDR_W{1'b0}}};
    deqNextHead.flag = deq_ptr_next0.flag;
    deqNextHead.value= {deq_ptr_next0.value[PTR_W-1:BANK_ADDR_W], {BANK_ADDR_W{1'b0}}};
  end
  always_comb begin
    rob_ptr_t base;
    if (io_redirect_valid)
      base = io_snpt_useSnpt ? snapHead : deqNextHead;
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
      if (io_redirect_valid)
        walkPtrVec_next[i] = ptr_add(base, PTR_W'(i));
      else if ((state == S_WALK) & ~walkFinished)
        walkPtrVec_next[i] = ptr_add(walkPtrVec[i], (PTR_W+1)'(COMMIT_WIDTH));
      else
        walkPtrVec_next[i] = walkPtrVec[i];
    end
    if (io_redirect_valid)
      walkPtrTrue_next = io_snpt_useSnpt ? snap_ptr0 : deq_ptr_next0;
    else if ((state == S_WALK) & ~walkFinished)
      walkPtrTrue_next = walkPtrVec_next[0];
    else
      walkPtrTrue_next = walkPtrTrue;
  end
  always_comb walkPtr_head = walkPtrVec_next[0];

  // ---- 行读地址 FSM(golden Rob.scala 244-253): robBanksRaddrNextLine ----
  //   redirect: 跳到 walkPtrHead 所在行(one-hot);
  //   allCommitted 或 walk 未到换行边界: 行号 +1(one-hot 左移, 到顶回 1);
  //   walk 到换行边界: 跳到 deqPtr 所在行;
  //   否则保持。
  // (walkPtrVec[0] + CommitWidth) > lastWalkPtr —— 用环形指针加法 + 环形大于。
  logic changeBankAddrToDeqPtr;
  always_comb changeBankAddrToDeqPtr =
      ptr_gt(ptr_add(walkPtrVec[0], (PTR_W+1)'(COMMIT_WIDTH)), lastWalkPtr);

  function automatic logic [ENTRY_PER_BANK-1:0] row_to_onehot(input logic [PTR_W-1:0] row);
    logic [ENTRY_PER_BANK-1:0] oh;
    oh = '0;
    for (int e = 0; e < ENTRY_PER_BANK; e++) if (PTR_W'(e) == row) oh[e] = 1'b1;
    return oh;
  endfunction
  logic [PTR_W-1:0] walkHeadRow, deqPtrRow;
  always_comb begin
    walkHeadRow = walkPtr_head.value[PTR_W-1:BANK_ADDR_W];
    deqPtrRow   = deqPtr.value[PTR_W-1:BANK_ADDR_W];
  end
  always_comb begin
    if (io_redirect_valid)
      robBanksRaddrNextLine = row_to_onehot(walkHeadRow);
    else if (o_allCommitted | (o_commits_isWalk & ~changeBankAddrToDeqPtr))
      robBanksRaddrNextLine = robBanksRaddrThisLine[ENTRY_PER_BANK-1]
                            ? {{(ENTRY_PER_BANK-1){1'b0}}, 1'b1}      // 到顶回行 0
                            : (robBanksRaddrThisLine << 1);
    else if (o_commits_isWalk & changeBankAddrToDeqPtr)
      robBanksRaddrNextLine = row_to_onehot(deqPtrRow);
    else
      robBanksRaddrNextLine = robBanksRaddrThisLine;
  end

  // ---- 12b. 主时序 ----
  rob_state_e state_next;
  always_comb begin
    if (io_redirect_valid | redirectValidReg)
      state_next = S_WALK;
    else if ((state == S_WALK) & walkFinished & rab_status_walk_end & vtype_status_walk_end)
      state_next = S_IDLE;
    else
      state_next = state;
  end

  // misPred/deqFlush 阻塞计数器。
  logic [2:0] misPredBlockCounter, deqFlushBlockCounter;
  logic misPredWb;
  // 误预测写回: 由 wrapper 从 golden redirectWBs 聚合后经 io_misPredWb 喂入。
  always_comb misPredWb = io_misPredWb;
  assign misPredBlock = misPredBlockCounter[0];
  assign deqFlushBlock = deqFlushBlockCounter[0];

  // deqHitRedirectReg: redirect 命中队头(打 1~2 拍)。
  logic deqHitRedirectReg, deqHitRedirect_d1, deqHitRedirect_d2;
  always_comb deqHitRedirectReg = deqHitRedirect_d1 | deqHitRedirect_d2;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      state <= S_IDLE;
      // ★SoA G1 family★ 12 字段复位 0(与 packed 版 rob_entries[i]<='0 逐位一致)。
      //  nf 逐字段复位仅剩非-G1 位(G1 位 valid/uop_num/std_writebacked/need_flush/
      //  interrupt_safe/mmio/is_rvc/is_vset/is_hls/real_dest_size/instr_size/
      //  commit_type 在 nf 里全程无驱动=DCE, 免 constant-0 死 flop 伪影)。
      for (int i = 0; i < ROB_SIZE; i++) begin
        // SoA G1 family(canary 3 + 扩展 9), 各 reset 0:
        rob_valid[i]          <= 1'b0;
        rob_uop_num[i]        <= '0;
        rob_std_wb[i]         <= 1'b0;
        rob_needflush[i]      <= 1'b0;
        rob_interrupt_safe[i] <= 1'b0;
        rob_mmio[i]           <= 1'b0;
        rob_is_rvc[i]         <= 1'b0;
        rob_is_vset[i]        <= 1'b0;
        rob_is_hls[i]         <= 1'b0;
        rob_real_dest_size[i] <= '0;
        rob_instr_size[i]     <= '0;
        rob_commit_type[i]    <= '0;
        // G2 pointers/indices family reset(与 packed 版 rob_entries[i]<='0 逐位一致)
        rob_ftq_flag[i]   <= 1'b0;
        rob_ftq_value[i]  <= '0;
        rob_ftq_offset[i] <= '0;
        // 非-G1/G2 packed nf 字段:
        rob_entries_nf[i].vls            <= 1'b0;
        rob_entries_nf[i].fflags         <= '0;
        rob_entries_nf[i].vxsat          <= 1'b0;
        rob_entries_nf[i].rf_wen         <= 1'b0;
        rob_entries_nf[i].fp_wen         <= 1'b0;
        rob_entries_nf[i].wflags         <= 1'b0;
        rob_entries_nf[i].dirty_vs       <= 1'b0;
        // ftq_idx_value/ftq_idx_flag/ftq_offset 现为 G2 SoA family, 不寄存于 nf
        rob_entries_nf[i].itype          <= '0;
        rob_entries_nf[i].iretire        <= '0;
        rob_entries_nf[i].ilastsize      <= '0;
      end
      hasBlockBackward <= 1'b0;
      hasWaitForward   <= 1'b0;
      hasWFI           <= 1'b0;
      wfiEvent_d1      <= 1'b0;
      wfiEvent_d2      <= 1'b0;
      hasWFI_d1        <= 1'b0;
      wfi_cycles       <= '0;
      deqHasFlushed    <= 1'b0;
      intrBitSetReg    <= 1'b0;
      allowEnqueue     <= 1'b1;
      allowEnqueueForDispatch <= 1'b1;
      hasCommitted     <= '0;
      donotNeedWalk    <= '0;
      lastCycleFlush   <= 1'b0;
      redirectValidReg <= 1'b0;
      misPredBlockCounter  <= '0;
      deqFlushBlockCounter <= '0;
      deqHitRedirect_d1 <= 1'b0;
      deqHitRedirect_d2 <= 1'b0;
      walkPtrTrue  <= '0;
      lastWalkPtr  <= '0;
      walkPtrLowBits <= '0;
      robBanksRaddrThisLine <= {{(ENTRY_PER_BANK-1){1'b0}}, 1'b1}; // 行 0
      for (int b = 0; b < COMMIT_WIDTH; b++) robDeqGroup[b] <= '0;
      for (int i = 0; i < COMMIT_WIDTH; i++) begin
        walkPtrVec[i]    <= '0;
        walkingPtrVec[i] <= '0;
      end
    end else begin
      state            <= state_next;
      intrBitSetReg    <= io_csr_intrBitSet;
      lastCycleFlush   <= o_flushOut_valid;
      redirectValidReg <= io_redirect_valid;

      // ---- 行读地址 / robDeqGroup 寄存器流水(§3) ----
      robBanksRaddrThisLine <= robBanksRaddrNextLine;
      for (int b = 0; b < COMMIT_WIDTH; b++) robDeqGroup[b] <= robDeqGroup_next[b];

      // ---- robEntries 状态(写回/累计) + valid(commit/enq/flush) ----
      // ★SoA G1 family★ 非-G1 字段落 rob_entries_nf(逐字段, 不寄存 G1 位=免
      //  impl-only 死寄存器伪影); G1 12 字段落各自 SoA 数组:
      //   uop_num/std_wb <= 专用 next 数组(与 packed 版 rob_entries[i]<=next 同源);
      //   need_flush/interrupt_safe/mmio/is_rvc/is_vset/is_hls/real_dest_size/
      //     instr_size/commit_type <= rob_entries_next[i].<field>(与 packed 版
      //     rob_entries[i]<=rob_entries_next[i] 的对应位 100% 同源同拍);
      //   valid <= commit/enq/flush 优先级覆盖(与 packed 版逐字一致, hold 读 SoA)。
      for (int i = 0; i < ROB_SIZE; i++) begin
        logic commitCond, enqOH, needFlushRange;
        commitCond = o_commits_isCommit & commit_hit_arr[i];
        enqOH      = |enq_inst_hit_arr[i];
        needFlushRange = redirectValidReg & in_flush_range_arr[i];
        // 非-G1: 逐字段落 nf(G1 位不寄存)
        rob_entries_nf[i].vls             <= rob_entries_next[i].vls;
        rob_entries_nf[i].fflags          <= rob_entries_next[i].fflags;
        rob_entries_nf[i].vxsat           <= rob_entries_next[i].vxsat;
        rob_entries_nf[i].rf_wen          <= rob_entries_next[i].rf_wen;
        rob_entries_nf[i].fp_wen          <= rob_entries_next[i].fp_wen;
        rob_entries_nf[i].wflags          <= rob_entries_next[i].wflags;
        rob_entries_nf[i].dirty_vs        <= rob_entries_next[i].dirty_vs;
        // ftq_idx_value/ftq_idx_flag/ftq_offset 现为 G2 SoA family, 落各自数组(见下)
        rob_entries_nf[i].itype           <= rob_entries_next[i].itype;
        rob_entries_nf[i].iretire         <= rob_entries_next[i].iretire;
        rob_entries_nf[i].ilastsize       <= rob_entries_next[i].ilastsize;
        // G1 uop_num / std_writebacked (专用 next 数组)
        rob_uop_num[i] <= rob_uop_num_next[i];
        rob_std_wb[i]  <= rob_std_wb_next[i];
        // G1 扩展 9 字段 <= rob_entries_next[i].<field> (与 packed 版同源同拍)
        rob_needflush[i]      <= rob_entries_next[i].need_flush;
        rob_interrupt_safe[i] <= rob_entries_next[i].interrupt_safe;
        rob_mmio[i]           <= rob_entries_next[i].mmio;
        rob_is_rvc[i]         <= rob_entries_next[i].is_rvc;
        rob_is_vset[i]        <= rob_entries_next[i].is_vset;
        rob_is_hls[i]         <= rob_entries_next[i].is_hls;
        rob_real_dest_size[i] <= rob_entries_next[i].real_dest_size;
        rob_instr_size[i]     <= rob_entries_next[i].instr_size;
        rob_commit_type[i]    <= rob_entries_next[i].commit_type;
        // G2 family ftq flag / value / offset(与 packed 版 rob_entries[i]<=next 同源)
        rob_ftq_flag[i]   <= rob_ftq_flag_next[i];
        rob_ftq_value[i]  <= rob_ftq_value_next[i];
        rob_ftq_offset[i] <= rob_ftq_offset_next[i];
        // G1/G2 valid: 按优先级覆盖(commit 清 > enq 置 > flush 清 > hold)
        if (commitCond)
          rob_valid[i] <= 1'b0;
        else if (enqOH & ~io_redirect_valid)
          rob_valid[i] <= 1'b1;
        else if (needFlushRange)
          rob_valid[i] <= 1'b0;
        else
          rob_valid[i] <= rob_valid[i];
      end

      // ---- hasBlockBackward / hasWaitForward ----
      if (enqPtr == deqPtr) hasBlockBackward <= 1'b0; // isEmpty
      else begin
        logic setBB;
        setBB = 1'b0;
        for (int i = 0; i < RENAME_WIDTH; i++)
          if (enq_valid[i] & enq_block_backward[i] & o_enq_canAccept) setBB = 1'b1;
        if (setBB) hasBlockBackward <= 1'b1;
      end
      begin
        logic setWF;
        setWF = 1'b0;
        for (int i = 0; i < RENAME_WIDTH; i++)
          if (canEnqueue[i] & enq_wait_forward[i]) setWF = 1'b1;
        if (|o_commits_walkValid | |o_commits_commitValid) hasWaitForward <= 1'b0;
        else if (setWF) hasWaitForward <= 1'b1;
      end

      // ---- WFI ----
      // golden 顺序(Rob.scala 414-468): 先按 clr(wfiEvent2/flush/timeout)清,
      // 再按 enqueue 置, 最后 !wfi_enable 强制清(优先级最高)。
      begin
        logic setWFI, clrWFI;
        setWFI = 1'b0;
        for (int i = 0; i < RENAME_WIDTH; i++)
          if (canEnqueue[i] & enq_is_wfi[i] & ~enq_has_exception[i] & ~enq_trigger_dmode[i]) setWFI = 1'b1;
        clrWFI = wfiEvent_d2 | o_flushOut_valid | wfi_timeout;
        if (clrWFI)              hasWFI <= 1'b0;
        else if (setWFI)         hasWFI <= 1'b1;
        if (~io_wfi_enable)      hasWFI <= 1'b0;  // 末尾覆盖, 同 golden when(!wfi_enable)
      end

      // ---- wfiEvent 两拍 / timeout 计数 ----
      wfiEvent_d1 <= io_csr_wfiEvent;
      wfiEvent_d2 <= wfiEvent_d1;
      hasWFI_d1   <= hasWFI;
      if (hasWFI)                      wfi_cycles <= wfi_cycles + 20'd1;
      else if (~hasWFI & hasWFI_d1)    wfi_cycles <= '0;

      // ---- deqHasFlushed ----
      if (o_commits_isCommit & o_commits_commitValid[0])
        deqHasFlushed <= 1'b0;
      else if (deqNeedFlush & o_flushOut_valid & ~o_flushOut_level)
        deqHasFlushed <= 1'b1;

      // ---- allowEnqueue 阈值 ----
      allowEnqueue            <= (numValidEntries + {5'b0, dispatchNum}) <= (PTR_W+1)'(ROB_SIZE - RENAME_WIDTH);
      allowEnqueueForDispatch <= (numValidEntries + {5'b0, dispatchNum}) <= (PTR_W+1)'(ROB_SIZE - 2*RENAME_WIDTH);

      // ---- hasCommitted ----
      if (o_allCommitted) hasCommitted <= '0;
      else if (o_commits_isCommit)
        for (int i = 0; i < COMMIT_WIDTH; i++)
          hasCommitted[i] <= commitValidThisLine[i] | hasCommitted[i];

      // ---- walk 指针族 ----
      for (int i = 0; i < COMMIT_WIDTH; i++) begin
        walkPtrVec[i]    <= walkPtrVec_next[i];
        walkingPtrVec[i] <= walkPtrVec[i];
      end
      walkPtrTrue <= walkPtrTrue_next;
      if (io_redirect_valid) begin
        lastWalkPtr <= io_redirect_bits_level
                     ? ptr_sub1('{flag:io_redirect_bits_robIdx_flag, value:io_redirect_bits_robIdx_value})
                     : '{flag:io_redirect_bits_robIdx_flag, value:io_redirect_bits_robIdx_value};
        walkPtrLowBits <= io_snpt_useSnpt ? snap_ptr0.value[BANK_ADDR_W-1:0]
                                          : deq_ptr_next0.value[BANK_ADDR_W-1:0];
      end

      // ---- donotNeedWalk(redirect 后第 2 拍按 lowBits 置) ----
      if (io_redirect_valid)
        donotNeedWalk <= '1;
      else if (redirectValidReg)
        for (int i = 0; i < COMMIT_WIDTH; i++)
          donotNeedWalk[i] <= (BANK_ADDR_W'(i) < walkPtrLowBits);
      else
        donotNeedWalk <= '0;

      // ---- 阻塞计数器 ----
      misPredBlockCounter  <= misPredWb ? 3'b111 : (misPredBlockCounter >> 1);
      if (deqNeedFlush & deqHitRedirectReg) deqFlushBlockCounter <= 3'b111;
      else deqFlushBlockCounter <= deqFlushBlockCounter >> 1;
      deqHitRedirect_d1 <= io_redirect_valid & (io_redirect_bits_robIdx_value == deqPtr.value);
      deqHitRedirect_d2 <= deqHitRedirect_d1;
    end
  end

  // commit 命中(deqPtrVec 任一槽匹配 i 且 commitValid)。
  // ★FMR-strict (修3)★ commit_hit 读模块级 o_commits_commitValid/deq_ptr_vec → 数组。
  // (commit_hit_arr 声明前置于 §4 helper-array 块, 因本 always_comb 之前的 always_ff
  //  已引用之 —— SV 变量须先声明后用。)
  always_comb
    for (int idx = 0; idx < ROB_SIZE; idx++) begin
      commit_hit_arr[idx] = 1'b0;
      for (int i = 0; i < COMMIT_WIDTH; i++)
        if (o_commits_commitValid[i] & (deq_ptr_vec[i].value == PTR_W'(idx))) commit_hit_arr[idx] = 1'b1;
    end

  // redirect flush 范围(redirectBegin..redirectEnd 环形区间内)。
  logic [PTR_W-1:0] redirectBegin, redirectEnd;
  logic redirectAll;
  always_ff @(posedge clock) begin
    if (io_redirect_valid) begin
      redirectBegin <= io_redirect_bits_level ? (io_redirect_bits_robIdx_value - PTR_W'(1))
                                              : io_redirect_bits_robIdx_value;
      redirectEnd   <= enqPtr.value;
      redirectAll   <= io_redirect_bits_level & (io_redirect_bits_robIdx_value == enqPtr.value)
                     & (io_redirect_bits_robIdx_flag ^ enqPtr.flag);
    end
  end
  // ★FMR-strict (修3)★ in_flush_range 读模块级 redirectBegin/End/All → 数组。
  // (in_flush_range_arr 声明前置于 §4 helper-array 块。)
  always_comb
    for (int idx = 0; idx < ROB_SIZE; idx++) begin
      logic inrange;
      if (redirectEnd > redirectBegin)
        inrange = (PTR_W'(idx) > redirectBegin) & (PTR_W'(idx) < redirectEnd);
      else
        inrange = (PTR_W'(idx) > redirectBegin) | (PTR_W'(idx) < redirectEnd);
      in_flush_range_arr[idx] = inrange | redirectAll;
    end

  // exception.valid 打一拍。
  logic exceptionValidReg;
  always_ff @(posedge clock or posedge reset)
    if (reset) exceptionValidReg <= 1'b0;
    else       exceptionValidReg <= exceptionHappen;
  assign o_exception_valid = exceptionValidReg;
  assign o_exceptionHappen = exceptionHappen;
  assign o_deqHasException = deqHasException;

  // vls 异常 2 拍门控寄存器(对齐 golden Rob.scala 578/584 的 RegNext(RegNext(...)))。
  always_ff @(posedge clock or posedge reset)
    if (reset) begin
      commit_w_d1 <= 1'b0; commit_w_d2 <= 1'b0;
      vlsExcCommitw_d1 <= 1'b0; vlsExcCommitw_d2 <= 1'b0;
    end else begin
      commit_w_d1 <= deqPtrEntry.commit_w;
      commit_w_d2 <= commit_w_d1;
      vlsExcCommitw_d1 <= deqIsVlsException & deqPtrEntry.commit_w;
      vlsExcCommitw_d2 <= vlsExcCommitw_d1;
    end

  // =====================================================================
  // 13. 性能计数(io_perf_0..17) —— 忠实复刻 golden 2 拍打拍性能计数树。
  //     golden: io_perf_N_value = {pad, io_perf_N_value_REG_1}
  //             io_perf_N_value_REG_1 <= io_perf_N_value_REG      (第 2 拍)
  //             io_perf_N_value_REG   <= <src_N>                  (第 1 拍)
  //     本核直接产出 [5:0] 端口 = 2 拍 RegNext 后的零扩展, 与 golden 逐位一致。
  //
  //     统一简称:
  //       isCommit  = o_commits_isCommit           (= golden io_commits_isCommit_0)
  //       cv[i]     = o_commits_commitValid[i]      (= golden io_commits_commitValid_i_0)
  //       flushV    = o_flushOut_valid              (= golden io_flushOut_valid_0)
  //       isWalk    = (state == S_WALK)             (= golden state)
  //       numVE     = numValidEntries[7:0]          (= golden numValidEntries_probe)
  // =====================================================================
  localparam logic [7:0] NVE_Q1 = 8'h29;   // 1/4 * 160 + 1 = 41
  localparam logic [7:0] NVE_HALF_LO = 8'h28; // 40
  localparam logic [7:0] NVE_HALF_HI = 8'h51; // 81
  localparam logic [7:0] NVE_50 = 8'h50;      // 80  (exHalf 阈值 >)
  localparam logic [7:0] NVE_Q3_LO = 8'h79;   // 121 (exHalf 且 < 121)
  localparam logic [7:0] NVE_Q3 = 8'h78;      // 120 (> 120 = 3/4 满)

  logic [7:0] numVE8;
  always_comb numVE8 = numValidEntries[7:0];

  // —— 分类向量(本拍组合, 对齐 golden commitLoadVec/BranchVec/StoreVec) ——
  logic [COMMIT_WIDTH-1:0] commitLoadVec, commitBranchVec, commitStoreVec, fuseVec;
  always_comb
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
      commitLoadVec[i]   = o_commits_commitValid[i] & (commitInfo[i].commit_type == 3'h2);
      commitBranchVec[i] = o_commits_commitValid[i] & (commitInfo[i].commit_type == 3'h1);
      commitStoreVec[i]  = o_commits_commitValid[i] & (commitInfo[i].commit_type == 3'h3);
      fuseVec[i]         = o_commits_commitValid[i] &  commitInfo[i].commit_type[2];
    end

  // —— 打拍寄存器族(golden: RegEnable(..., isCommit) + RegNext(isCommit)) ——
  logic                    isCommitReg_last;          // RegNext(isCommit)
  logic [COMMIT_WIDTH-1:0] perfLoad_r, perfBranch_r, perfStore_r;  // RegEnable(vec, isCommit)
  logic [COMMIT_WIDTH-1:0] fuse_r;                    // RegEnable(fuseVec, isCommit)
  logic [9:0]              trueCommitCnt_r;           // RegEnable(sum instrSize, isCommit)
  logic                    isInterrupt_r;             // RegEnable(intrEnable, exceptionHappen) —— 供 trace itype 覆盖

  // —— 组合中间量 ——
  // popcount 帮助函数(8 位 one-per-bank 求和, 结果 [3:0])。
  function automatic logic [3:0] pc8(input logic [COMMIT_WIDTH-1:0] v);
    logic [3:0] s;
    s = '0;
    for (int i = 0; i < COMMIT_WIDTH; i++) s += 4'(v[i]);
    return s;
  endfunction

  // trueCommitCnt: 本拍提交各槽 instrSize 之和(commit 时)。
  logic [9:0] trueCommitCnt_next;
  always_comb begin
    trueCommitCnt_next = '0;
    for (int i = 0; i < COMMIT_WIDTH; i++)
      if (o_commits_commitValid[i])
        trueCommitCnt_next += 10'(commitInfo[i].instr_size);
  end

  // fuseCommitCnt(第 2 级组合读, golden fuseCommitCnt = popcount(fuse_r)):
  logic [3:0] fuseCommitCnt;
  always_comb fuseCommitCnt = pc8(fuse_r);

  // retireCounter(golden): isCommitReg_last ? trueCommitCnt_r + fuseCommitCnt : 0。
  logic [10:0] retireCounter;
  always_comb retireCounter = isCommitReg_last
                            ? (11'({1'b0, trueCommitCnt_r}) + 11'({7'h0, fuseCommitCnt}))
                            : 11'h0;

  // perfEvents_4 = commit 时提交条数(popcount cv)。
  logic [3:0] commitCnt;
  always_comb commitCnt = o_commits_isCommit ? pc8(o_commits_commitValid) : 4'h0;

  // walk 条数(state 时 popcount shouldWalkVec)。
  logic [3:0] walkCnt;
  always_comb walkCnt = (state == S_WALK) ? pc8(shouldWalkVec) : 4'h0;

  // misPred_probe(golden 有 bug: 计数被翻倍 = 2 * sum(wb1/3/5 redir))。
  logic [2:0] misPred;
  always_comb begin
    logic [1:0] mp;
    mp = 2'({1'b0, io_wb1_redir}) + 2'({1'b0, io_wb3_redir}) + 2'({1'b0, io_wb5_redir});
    misPred = 3'({1'b0, mp}) + 3'({1'b0, mp});   // = 2*mp, 逐位对齐 golden misPred_probe
  end

  // —— 第 1 级源(src_N) ——
  logic pe0_src, pe1_src, pe2_src, pe3_src, pe11_src, pe12_src, pe13_src, pe14_src, pe15_src, pe17_src;
  always_comb begin
    pe0_src  = o_flushOut_valid & intrEnable;                 // 中断刷
    pe1_src  = o_flushOut_valid & deqHasException;            // 异常刷
    pe2_src  = o_flushOut_valid & isFlushPipe;                // flushPipe
    pe3_src  = pe2_src & deqHasReplayInst;                    // replay
    pe11_src = (state == S_WALK);                             // walk cycle
    pe12_src = numVE8 <  NVE_Q1;
    pe13_src = (numVE8 > NVE_HALF_LO) & (numVE8 < NVE_HALF_HI);
    pe14_src = (numVE8 > NVE_50) & (numVE8 < NVE_Q3_LO);
    pe15_src = numVE8 >  NVE_Q3;
    pe17_src = o_flushOut_valid;
  end

  // —— 2 拍寄存器: <src> -> REG -> REG_1 (=端口值前身) ——
  // 位宽随 golden: 0/1/2/3/11..17=1b; 4/6/7/8/9/10=4b; 5=11b; 16=3b。
  logic       p0r,p0r1, p1r,p1r1, p2r,p2r1, p3r,p3r1;
  logic [3:0] p4r,p4r1, p6r,p6r1, p7r,p7r1, p8r,p8r1, p9r,p9r1, p10r,p10r1;
  logic [10:0] p5r,p5r1;
  logic       p11r,p11r1, p12r,p12r1, p13r,p13r1, p14r,p14r1, p15r,p15r1;
  logic [2:0] p16r,p16r1;
  logic       p17r,p17r1;

  always_ff @(posedge clock) begin
    // 第 1 拍
    p0r  <= pe0_src;  p1r  <= pe1_src;  p2r  <= pe2_src;  p3r  <= pe3_src;
    p4r  <= commitCnt;
    p5r  <= retireCounter;
    p6r  <= isCommitReg_last ? fuseCommitCnt : 4'h0;
    p7r  <= isCommitReg_last ? pc8(perfLoad_r)   : 4'h0;
    p8r  <= isCommitReg_last ? pc8(perfBranch_r) : 4'h0;
    p9r  <= isCommitReg_last ? pc8(perfStore_r)  : 4'h0;
    p10r <= walkCnt;
    p11r <= pe11_src; p12r <= pe12_src; p13r <= pe13_src; p14r <= pe14_src; p15r <= pe15_src;
    p16r <= misPred;
    p17r <= pe17_src;
    // 第 2 拍
    p0r1<=p0r; p1r1<=p1r; p2r1<=p2r; p3r1<=p3r; p4r1<=p4r; p5r1<=p5r; p6r1<=p6r;
    p7r1<=p7r; p8r1<=p8r; p9r1<=p9r; p10r1<=p10r; p11r1<=p11r; p12r1<=p12r;
    p13r1<=p13r; p14r1<=p14r; p15r1<=p15r; p16r1<=p16r; p17r1<=p17r;
  end

  // —— 端口零扩展(逐位对齐 golden assign io_perf_N_value = {pad, REG_1}) ——
  always_comb begin
    o_perf_0_value  = {5'h0, p0r1};
    o_perf_1_value  = {5'h0, p1r1};
    o_perf_2_value  = {5'h0, p2r1};
    o_perf_3_value  = {5'h0, p3r1};
    o_perf_4_value  = {2'h0, p4r1};
    o_perf_5_value  = p5r1[5:0];
    o_perf_6_value  = {2'h0, p6r1};
    o_perf_7_value  = {2'h0, p7r1};
    o_perf_8_value  = {2'h0, p8r1};
    o_perf_9_value  = {2'h0, p9r1};
    o_perf_10_value = {2'h0, p10r1};
    o_perf_11_value = {5'h0, p11r1};
    o_perf_12_value = {5'h0, p12r1};
    o_perf_13_value = {5'h0, p13r1};
    o_perf_14_value = {5'h0, p14r1};
    o_perf_15_value = {5'h0, p15r1};
    o_perf_16_value = {3'h0, p16r1};
    o_perf_17_value = {5'h0, p17r1};
  end

  // RegEnable(vec, isCommit) 族 + RegNext(isCommit) + trueCommitCnt。
  always_ff @(posedge clock or posedge reset)
    if (reset) begin
      isCommitReg_last <= 1'b0;
      perfLoad_r <= '0; perfBranch_r <= '0; perfStore_r <= '0; fuse_r <= '0;
      trueCommitCnt_r <= '0;
    end else begin
      isCommitReg_last <= o_commits_isCommit;
      if (o_commits_isCommit) begin
        perfLoad_r      <= commitLoadVec;
        perfBranch_r    <= commitBranchVec;
        perfStore_r     <= commitStoreVec;
        fuse_r          <= fuseVec;
        trueCommitCnt_r <= trueCommitCnt_next;
      end
    end

  // isInterrupt_r = RegEnable(intrEnable, exceptionHappen)(golden 同门控)。
  always_ff @(posedge clock or posedge reset)
    if (reset)                 isInterrupt_r <= 1'b0;
    else if (exceptionHappen)  isInterrupt_r <= intrEnable;

  // =====================================================================
  // 14. trace 提交信息(io_trace_traceCommitInfo_blocks_0..7) —— 纯组合。
  //     golden 直接从 robDeqGroup(经 deqPtr 各槽的 bank 低 3 位读)取 trace 字段,
  //     block0 的 itype/iretire 在 exception 拍(io_exception_valid_REG)被覆盖。
  //       block0.valid  = io_exception_valid_REG | (isCommit & cv[0])
  //       blockN.valid  =                          (isCommit & cv[N])   (N>=1)
  //       ftqIdx/Offset = commitInfo[N].ftq_idx_value / ftq_offset
  //       itype[0]      = exValidReg ? {2'h0, isInterrupt_r?2'h2:2'h1} : commitInfo[0].itype
  //       itype[N>=1]   =                                                 commitInfo[N].itype
  //       iretire[0]    = exValidReg ? 4'h0 : commitInfo[0].iretire
  //       iretire[N>=1] =                     commitInfo[N].iretire
  //       ilastsize[N]  = commitInfo[N].ilastsize
  // =====================================================================
  always_comb begin
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
      o_trace_valid[i]        = o_commits_isCommit & o_commits_commitValid[i];
      o_trace_ftqIdx_value[i] = commitInfo[i].ftq_idx_value;
      o_trace_ftqOffset[i]    = commitInfo[i].ftq_offset;
      o_trace_itype[i]        = commitInfo[i].itype;
      o_trace_iretire[i]      = commitInfo[i].iretire;
      o_trace_ilastsize[i]    = commitInfo[i].ilastsize;
    end
    // block0 异常覆盖(io_exception_valid_REG = exceptionValidReg)。
    o_trace_valid[0]   = exceptionValidReg | (o_commits_isCommit & o_commits_commitValid[0]);
    o_trace_itype[0]   = exceptionValidReg
                       ? {2'h0, (isInterrupt_r ? 2'h2 : 2'h1)}
                       : commitInfo[0].itype;
    o_trace_iretire[0] = exceptionValidReg ? 4'h0 : commitInfo[0].iretire;
  end


  // =====================================================================
  // 13. [csr/debug 组] C_DEEP csr(9) + debug(6) = 15 端口
  //     owner rob-csr-debug; 忠实复刻 golden Rob.sv 220815-220851 的输出形成。
  //     依赖核内既有: robDeqGroup / rob_entries / deqPtr / deq_ptr_vec /
  //                   o_commits_isCommit / o_commits_commitValid /
  //                   exceptionHappen / deqHasException。
  // =====================================================================

  // ---- 13.0 每提交槽的 per-bank 提交条目视图(commit 路)------------------
  //   golden commitInfo_N = robDeqGroup[ deqPtr_N.value[2:0] ](commit 路读)。
  //   核内 commitInfo[] 已按此定义(§5), 直接复用(FM read_sverilog 不支持
  //   函数返回值域选 func(n).field FMR_VLOG-481, 故用数组 commitInfo[n].field)。

  // ---- 13.1 fflags: valid = RegNext(fflags_valid); bits = latch(选中槽 fflags) ----
  //   wflags_N   = commitValid_N & robDeqGroup[N].wflags     (golden _GEN_19)
  //   fflags_val = isCommit & |wflags                        (golden 21666)
  //   bits 数据  = robEntries[deqPtr_N.value].fflags          (golden _GEN_2621)
  // IDX_SPACE(256, 2 的幂)宽全存储读向量(0 寄存器 wire; 消 8 位下标越界 FMR_ELAB-147)。
  //  160..255 位填不可达 'x(≠entry-0/0); 下标 deqValIdx 经 index_in_range guard。
  logic [4:0]   robFflagsVec [IDX_SPACE];
  logic [IDX_SPACE-1:0] robVxsatVec;
  always_comb begin
    robVxsatVec = 'x;
    for (int i = 0; i < IDX_SPACE; i++) robFflagsVec[i] = 'x;
    for (int i = 0; i < ROB_SIZE; i++) begin
      robFflagsVec[i] = rob_entries[i].fflags;
      robVxsatVec[i]  = rob_entries[i].vxsat;
    end
  end
  logic [COMMIT_WIDTH-1:0] wflagsSel;
  logic                    fflags_valid_c;
  logic [4:0]              fflags_bits_c;
  always_comb begin
    fflags_bits_c = '0;
    for (int n = 0; n < COMMIT_WIDTH; n++) begin
      wflagsSel[n] = o_commits_commitValid[n] & commitInfo[n].wflags;
      if (wflagsSel[n])
        fflags_bits_c |= robFflagsVec[deqValIdx[n]];
    end
    fflags_valid_c = o_commits_isCommit & (|wflagsSel);
  end

  // ---- 13.2 vxsat: valid = RegNext(vxsat_valid); bits = latch(vxsat_bits) ----
  //   vxsat_bits = |(commitValid_N & robEntries[deqPtr_N.value].vxsat)  (golden _GEN_2625)
  //   vxsat_valid= isCommit & vxsat_bits
  logic vxsat_bits_c, vxsat_valid_c;
  always_comb begin
    vxsat_bits_c = 1'b0;
    for (int n = 0; n < COMMIT_WIDTH; n++)
      vxsat_bits_c |= o_commits_commitValid[n] & robVxsatVec[deqValIdx[n]];
    vxsat_valid_c = o_commits_isCommit & vxsat_bits_c;
  end

  // ---- 13.3 dirty_fs / dirty_vs: RegNext(isCommit & |(commitValid & 槽 dirty*)) ----
  //   dirty_fs 用 robDeqGroup[N].dirty_fs (=fp_wen|wflags, golden _GEN_8548)
  //   dirty_vs 用 robDeqGroup[N].dirty_vs (golden _GEN_25)
  logic dirty_fs_c, dirty_vs_c;
  always_comb begin
    logic anyFs, anyVs;
    anyFs = 1'b0; anyVs = 1'b0;
    for (int n = 0; n < COMMIT_WIDTH; n++) begin
      anyFs |= o_commits_commitValid[n] & commitInfo[n].dirty_fs;
      anyVs |= o_commits_commitValid[n] & commitInfo[n].dirty_vs;
    end
    dirty_fs_c = o_commits_isCommit & anyFs;
    dirty_vs_c = o_commits_isCommit & anyVs;
  end

  // ---- 13.4 vstart: 异常发生时取 exceptionGen 的 vstart, 否则 dirty_vs&~vstartIsZero ----
  //   _io_csr_vstart_bits_T = exceptionHappen & deqHasException     (golden 80231)
  //   valid_next = T ? egVstartEn : dirty_vs & ~vstartIsZero        (golden 181499)
  //   bits_next  = T ? egVstart   : 0                               (golden 181503)
  logic        vstartExcp;
  logic        vstart_valid_next;
  logic [63:0] vstart_bits_next;
  always_comb begin
    vstartExcp        = exceptionHappen & deqHasException;
    vstart_valid_next = vstartExcp ? io_eg_vstartEn : (dirty_vs_c & ~io_vstartIsZero);
    vstart_bits_next  = vstartExcp ? io_eg_vstart   : 64'h0;
  end

  // ---- 13.5 retiredInstr: RegNext 链 ----
  //   trueCommitCnt_r_csr = RegNext( Σ commitValid_N ? robDeqGroup[N].instr_size : 0 )
  //   fuseCommitCnt_r_N = RegNext( commitValid_N & robDeqGroup[N].commit_type[2] )
  //   isCommitReg_last_csr  = RegNext(isCommit)
  //   retiredInstr = isCommitReg_last_csr ? (trueCommitCnt_r_csr + Σ fuseCommitCnt_r_csr)[6:0] : 0
  logic [9:0]              trueCommitCnt_r_csr;
  logic [COMMIT_WIDTH-1:0] fuseCommitCnt_r_csr;
  logic                    isCommitReg_last_csr;
  logic [9:0]              trueCommitCnt_c;      // 组合下一拍值
  logic [COMMIT_WIDTH-1:0] fuseCommitCnt_c;
  always_comb begin
    trueCommitCnt_c = '0;
    for (int n = 0; n < COMMIT_WIDTH; n++) begin
      fuseCommitCnt_c[n] = o_commits_commitValid[n] & commitInfo[n].commit_type[2];
      if (o_commits_commitValid[n])
        trueCommitCnt_c += 10'({7'h0, commitInfo[n].instr_size});
    end
  end
  logic [3:0] fuseCommitCntSum;
  always_comb begin
    fuseCommitCntSum = '0;
    for (int n = 0; n < COMMIT_WIDTH; n++)
      fuseCommitCntSum += 4'(fuseCommitCnt_r_csr[n]);
  end
  logic [10:0] retireCounter_c;
  always_comb
    retireCounter_c = isCommitReg_last_csr
                    ? 11'({1'h0, trueCommitCnt_r_csr} + {7'h0, fuseCommitCntSum})
                    : 11'h0;

  // ---- csr 输出寄存器 ----
  //   *_last_REG 每拍更新(仅 reset 清 0); *_bits_r 数据 latch(仅 valid 时更新, 否则保持)。
  logic       fflags_valid_r, vxsat_valid_r, vstart_valid_r, dirty_fs_r, dirty_vs_r;
  logic [4:0] fflags_bits_r;
  logic       vxsat_bits_r;
  logic [63:0] vstart_bits_r;
  always_ff @(posedge clock or posedge reset)
    if (reset) begin
      fflags_valid_r   <= 1'b0;
      vxsat_valid_r    <= 1'b0;
      vstart_valid_r   <= 1'b0;
      dirty_fs_r       <= 1'b0;
      dirty_vs_r       <= 1'b0;
      fflags_bits_r    <= '0;
      vxsat_bits_r     <= 1'b0;
      vstart_bits_r    <= '0;
      trueCommitCnt_r_csr  <= '0;
      fuseCommitCnt_r_csr  <= '0;
      isCommitReg_last_csr <= 1'b0;
    end else begin
      fflags_valid_r  <= fflags_valid_c;
      vxsat_valid_r   <= vxsat_valid_c;
      vstart_valid_r  <= vstart_valid_next;
      dirty_fs_r      <= dirty_fs_c;
      dirty_vs_r      <= dirty_vs_c;
      vstart_bits_r   <= vstart_bits_next;
      if (fflags_valid_c) fflags_bits_r <= fflags_bits_c;  // golden: if(fflags_valid) latch
      if (vxsat_valid_c)  vxsat_bits_r  <= vxsat_bits_c;   // golden: if(vxsat_valid)  latch
      trueCommitCnt_r_csr  <= trueCommitCnt_c;
      fuseCommitCnt_r_csr  <= fuseCommitCnt_c;
      isCommitReg_last_csr <= o_commits_isCommit;
    end

  assign o_csr_fflags_valid          = fflags_valid_r;
  assign o_csr_fflags_bits           = fflags_bits_r;
  assign o_csr_vxsat_valid           = vxsat_valid_r;
  assign o_csr_vxsat_bits            = vxsat_bits_r;
  assign o_csr_vstart_valid          = vstart_valid_r;
  assign o_csr_vstart_bits           = vstart_bits_r;
  assign o_csr_dirty_fs              = dirty_fs_r;
  assign o_csr_dirty_vs              = dirty_vs_r;
  assign o_csr_perfinfo_retiredInstr = retireCounter_c[6:0];

  // =====================================================================
  // 13.6 debug(6): 队头 fuType / lsIssue / lsTopdown vaddr/paddr
  // =====================================================================

  // ---- debug_microOp fuType: 每条目寄存, 入队时按口优先级(5..0)写入 ----
  logic [34:0] debug_fuType [ROB_SIZE];
  // ---- debug_lsIssued: 每条目寄存(累计队头 lsIssue, 入队清) ----
  logic        debug_lsIssued [ROB_SIZE];
  // ---- debug_lsTopdownInfo: 每条目寄存 s1 vaddr / s2 paddr ----
  logic        debug_s1_valid [ROB_SIZE];
  logic [49:0] debug_s1_bits  [ROB_SIZE];
  logic        debug_s2_valid [ROB_SIZE];
  logic [47:0] debug_s2_bits  [ROB_SIZE];

  // lsTopdown 端口对某条目的命中(port 2>1>0 优先; 忠实 golden 更新链)。
  //   valid_next = OR_p(port_p_valid & robIdx==i) | (~enqHit(i) & valid[i])
  //   bits_next  = 最高优先命中口的 bits; 若无命中口且 enqHit(i) → 0; 否则保持。
  logic [ROB_SIZE-1:0] enqHitAny;
  always_comb
    for (int i = 0; i < ROB_SIZE; i++)
      enqHitAny[i] = |enq_inst_hit_arr[i];

  logic        debug_s1_valid_n [ROB_SIZE];
  logic [49:0] debug_s1_bits_n  [ROB_SIZE];
  logic        debug_s2_valid_n [ROB_SIZE];
  logic [47:0] debug_s2_bits_n  [ROB_SIZE];
  always_comb
    for (int i = 0; i < ROB_SIZE; i++) begin
      logic [2:0] s1hit, s2hit;   // 3 口对本条目命中(port p)
      // s1 (vaddr)
      for (int p = 0; p < 3; p++)
        s1hit[p] = io_lsTopdown_s1_valid[p] & (io_lsTopdown_s1_robIdx[p] == PTR_W'(i));
      debug_s1_valid_n[i] = (|s1hit) | (~enqHitAny[i] & debug_s1_valid[i]);
      if      (s1hit[2]) debug_s1_bits_n[i] = io_lsTopdown_s1_bits[2];
      else if (s1hit[1]) debug_s1_bits_n[i] = io_lsTopdown_s1_bits[1];
      else if (s1hit[0]) debug_s1_bits_n[i] = io_lsTopdown_s1_bits[0];
      else if (enqHitAny[i]) debug_s1_bits_n[i] = 50'h0;
      else               debug_s1_bits_n[i] = debug_s1_bits[i];
      // s2 (paddr)
      for (int p = 0; p < 3; p++)
        s2hit[p] = io_lsTopdown_s2_valid[p] & (io_lsTopdown_s2_robIdx[p] == PTR_W'(i));
      debug_s2_valid_n[i] = (|s2hit) | (~enqHitAny[i] & debug_s2_valid[i]);
      if      (s2hit[2]) debug_s2_bits_n[i] = io_lsTopdown_s2_bits[2];
      else if (s2hit[1]) debug_s2_bits_n[i] = io_lsTopdown_s2_bits[1];
      else if (s2hit[0]) debug_s2_bits_n[i] = io_lsTopdown_s2_bits[0];
      else if (enqHitAny[i]) debug_s2_bits_n[i] = 48'h0;
      else               debug_s2_bits_n[i] = debug_s2_bits[i];
    end

  // 入队各口写 fuType 的优先级: golden 顺序 port5>4>3>2>1>0(高口优先, 与 enq_info 同)。
  // ★FMR-strict (修3)★ enq_fuType_hit 读模块级 enq_fuType/enq_inst_hit → 数组。
  // (enq_fuType_hit_arr 声明前置于 §4 helper-array 块。)
  always_comb
    for (int idx = 0; idx < ROB_SIZE; idx++) begin
      enq_fuType_hit_arr[idx] = '0;
      for (int k = RENAME_WIDTH-1; k >= 0; k--)
        if (enq_inst_hit_arr[idx][k]) enq_fuType_hit_arr[idx] = enq_fuType[k];
    end

  always_ff @(posedge clock or posedge reset)
    if (reset) begin
      for (int i = 0; i < ROB_SIZE; i++) begin
        debug_fuType[i]   <= '0;
        debug_lsIssued[i] <= 1'b0;
        debug_s1_valid[i] <= 1'b0;
        debug_s1_bits[i]  <= '0;
        debug_s2_valid[i] <= 1'b0;
        debug_s2_bits[i]  <= '0;
      end
    end else begin
      for (int i = 0; i < ROB_SIZE; i++) begin
        // fuType: 入队命中时写(其余保持); 高口优先。
        if (enqHitAny[i]) debug_fuType[i] <= enq_fuType_hit_arr[i];
        // lsIssued: (队头且 headLsIssue) 置; 入队清; 否则保持。
        //   golden 197626: io_debugHeadLsIssue & (i==head) | (~enqHit(i) & lsIssued[i])
        debug_lsIssued[i] <= (io_debugHeadLsIssue & (deqPtr.value == PTR_W'(i)))
                           | (~enqHitAny[i] & debug_lsIssued[i]);
        // lsTopdown s1/s2
        debug_s1_valid[i] <= debug_s1_valid_n[i];
        debug_s1_bits[i]  <= debug_s1_bits_n[i];
        debug_s2_valid[i] <= debug_s2_valid_n[i];
        debug_s2_bits[i]  <= debug_s2_bits_n[i];
      end
    end

  // ---- debug 输出(队头 deqPtr.value 读出)----
  //   robHeadLsIssue: golden io_debugTopDown_toDispatch_robHeadLsIssue = debug_lsIssue[deqV],
  //   其中 debug_lsIssue[k] = (deqV==k)? io_debugHeadLsIssue : debug_lsIssued[k]
  //   (golden 15303-15311)。deqV==k 处 ⇒ 恒选 io_debugHeadLsIssue ⇒ 输出 = io_debugHeadLsIssue。
  //   debug_lsIssued[] 仍需维护(golden 状态), 供 FM 逐位对齐(其它下标读出用)。
  // 队头下标(deqPtr.value 由 golden mod-160 环形指针保证恒 < ROB_SIZE)。index_in_range
  //  guard: ≥160 时取 'x(不可达; ≠clamp/wrap/取 entry-0)。运行期 ≥160 不发生。
  logic [PTR_W-1:0] deqHeadIdx;
  assign deqHeadIdx = index_in_range(deqPtr.value) ? deqPtr.value : 'x;
  // IDX_SPACE(256, 2 的幂)宽全存储读向量(0 寄存器 wire; 消 8 位下标越界 FMR_ELAB-147)。
  //  160..255 位填不可达 'x(≠entry-0/0), 下标经 guard, 运行期恒读 <160 有效项。
  logic [34:0]  dbgFuTypeVec [IDX_SPACE];
  logic [IDX_SPACE-1:0] dbgS1ValidVec, dbgS2ValidVec;
  logic [49:0]  dbgS1BitsVec [IDX_SPACE];
  logic [47:0]  dbgS2BitsVec [IDX_SPACE];
  always_comb begin
    dbgS1ValidVec = 'x; dbgS2ValidVec = 'x;
    for (int i = 0; i < IDX_SPACE; i++) begin
      dbgFuTypeVec[i] = 'x; dbgS1BitsVec[i] = 'x; dbgS2BitsVec[i] = 'x;
    end
    for (int i = 0; i < ROB_SIZE; i++) begin
      dbgFuTypeVec[i]  = debug_fuType[i];
      dbgS1ValidVec[i] = debug_s1_valid[i];
      dbgS1BitsVec[i]  = debug_s1_bits[i];
      dbgS2ValidVec[i] = debug_s2_valid[i];
      dbgS2BitsVec[i]  = debug_s2_bits[i];
    end
  end
  assign o_debugRobHead_fuType             = dbgFuTypeVec[deqHeadIdx];
  assign o_debugTopDown_robHeadLsIssue     = io_debugHeadLsIssue; // = debug_lsIssue[deqV], deqV==head
  assign o_debugTopDown_robHeadVaddr_valid = dbgS1ValidVec[deqHeadIdx];
  assign o_debugTopDown_robHeadVaddr_bits  = dbgS1BitsVec[deqHeadIdx];
  assign o_debugTopDown_robHeadPaddr_valid = dbgS2ValidVec[deqHeadIdx];
  assign o_debugTopDown_robHeadPaddr_bits  = dbgS2BitsVec[deqHeadIdx];


  // =====================================================================
  // 8. toVecExcpMod.excpInfo —— 向量异常合并模块接口(10 口)
  //    向量 load/store 触发异常时, 把发生处的向量上下文(vstart/vsew/veew/vlmul/nf
  //    + strided/indexed/whole/vlm 访存类型)锁存并送 VecExcpMod, 用于把整条向量
  //    指令跨 uop 的部分异常合并成一次精确异常。忠实复刻 golden(bug-for-bug):
  //      - bits_* 组: 仅在 exceptionHappen 拍锁存 ExceptionGen 的 io_state 向量域,
  //                   无 reset(golden Rob.sv L126207-126216, always@posedge clock)。
  //      - valid 组: 每拍无条件更新(reset→0), 表达式含 vstartEn & isVecLoad & ~isEnqExcp
  //                   (golden L193414-193416 / reset L187934)。
  //    输出全为寄存器直通(golden L220832-220841)。见 rob_vec_exception_ports.tsv。
  // =====================================================================
  logic       vecExcpInfo_valid;
  logic [6:0] vecExcpInfo_bits_vstart;
  logic [1:0] vecExcpInfo_bits_vsew;
  logic [1:0] vecExcpInfo_bits_veew;
  logic [2:0] vecExcpInfo_bits_vlmul;
  logic [2:0] vecExcpInfo_bits_nf;
  logic       vecExcpInfo_bits_isStride;
  logic       vecExcpInfo_bits_isIndexed;
  logic       vecExcpInfo_bits_isWhole;
  logic       vecExcpInfo_bits_isVlm;

  // valid: 有 reset, 每拍无条件更新(golden always@(posedge clock or posedge reset))。
  always_ff @(posedge clock or posedge reset)
    if (reset)
      vecExcpInfo_valid <= 1'b0;
    else
      vecExcpInfo_valid <= exceptionHappen & ~intrEnable
                         & eg_state_vstartEn & eg_state_isVecLoad & ~eg_state_isEnqExcp;

  // bits: 仅 exceptionHappen 拍锁存 ExceptionGen 向量 state(golden 无 reset)。
  always_ff @(posedge clock)
    if (exceptionHappen) begin
      vecExcpInfo_bits_vstart    <= eg_state_vstart;    // golden 取 _..._vstart[6:0]
      vecExcpInfo_bits_vsew      <= eg_state_vsew;
      vecExcpInfo_bits_veew      <= eg_state_veew;
      vecExcpInfo_bits_vlmul     <= eg_state_vlmul;
      vecExcpInfo_bits_nf        <= eg_state_nf;
      vecExcpInfo_bits_isStride  <= eg_state_isStrided;
      vecExcpInfo_bits_isIndexed <= eg_state_isIndexed;
      vecExcpInfo_bits_isWhole   <= eg_state_isWhole;
      vecExcpInfo_bits_isVlm     <= eg_state_isVlm;
    end

  assign o_toVecExcpMod_excpInfo_valid          = vecExcpInfo_valid;
  assign o_toVecExcpMod_excpInfo_bits_vstart    = vecExcpInfo_bits_vstart;
  assign o_toVecExcpMod_excpInfo_bits_vsew      = vecExcpInfo_bits_vsew;
  assign o_toVecExcpMod_excpInfo_bits_veew      = vecExcpInfo_bits_veew;
  assign o_toVecExcpMod_excpInfo_bits_vlmul     = vecExcpInfo_bits_vlmul;
  assign o_toVecExcpMod_excpInfo_bits_nf        = vecExcpInfo_bits_nf;
  assign o_toVecExcpMod_excpInfo_bits_isStride  = vecExcpInfo_bits_isStride;
  assign o_toVecExcpMod_excpInfo_bits_isIndexed = vecExcpInfo_bits_isIndexed;
  assign o_toVecExcpMod_excpInfo_bits_isWhole   = vecExcpInfo_bits_isWhole;
  assign o_toVecExcpMod_excpInfo_bits_isVlm     = vecExcpInfo_bits_isVlm;


  // =====================================================================
  // 15. [lsq deep 组] 组合全存储读 / 状态导出(供 rob_lsq_deep_outputs 消费)
  //     owner rob-lsq-deep; golden 用组合读 rob_entries[deqPtr_N.value](非寄存
  //     robDeqGroup), 故必须由本核直取整存储导出。见 docs/backend/rob_lsq_deep_ports.tsv。
  //       o_deq_entry_vls[N]   = rob_entries[deq_ptr_vec[N].value].vls   (golden _GEN_8225)
  //       o_deq_entry_valid_0  = rob_entries[deqValIdx[0]].valid (golden _GEN_2611)
  //       o_deq_entry_mmio_0   = rob_entries[deqValIdx[0]].mmio  (golden _GEN_2622)
  //       o_deqHasFlushed      = deqHasFlushed(核内既有状态)
  // =====================================================================
  //   FM 全存储读: 用 IDX_SPACE(256, 2 的幂)宽 packed 向量索引(替直接数组下标, 0 寄存器
  //   wire), 使 8 位下标恒在界(消 FMR_ELAB-147); 160..255 位填不可达 'x(≠entry-0/0),
  //   下标 deqValIdx 经 index_in_range guard, 恒读 <160 有效项。
  logic [IDX_SPACE-1:0] robVlsVec, robValidVec, robMmioVec;
  always_comb begin
    robVlsVec   = 'x; robValidVec = 'x; robMmioVec = 'x;
    for (int i = 0; i < ROB_SIZE; i++) begin
      robVlsVec[i]   = rob_entries[i].vls;
      robValidVec[i] = rob_entries[i].valid;
      robMmioVec[i]  = rob_entries[i].mmio;
    end
  end
  always_comb
    for (int i = 0; i < COMMIT_WIDTH; i++)
      o_deq_entry_vls[i] = robVlsVec[deqValIdx[i]];
  assign o_deq_entry_valid_0 = robValidVec[deqValIdx[0]];
  assign o_deq_entry_mmio_0  = robMmioVec[deqValIdx[0]];
  assign o_deqHasFlushed     = deqHasFlushed;

endmodule
