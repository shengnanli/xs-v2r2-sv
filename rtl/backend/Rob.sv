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
  output logic                       o_intrEnable,             // 中断使能(本拍)

  // ---- enq / 队列状态 ----
  output logic                       o_enq_canAccept,
  output logic                       o_enq_canAcceptForDispatch,
  output logic                       o_robFull,
  output logic                       o_headNotReady,
  output logic                       o_cpu_halt,
  output logic                       o_wfiReq,
  output logic [PTR_W:0]             o_numValidEntries
);

  // =====================================================================
  // 0. 主存储 + 状态寄存器
  // =====================================================================
  rob_entry_t  rob_entries [ROB_SIZE];   // 160 条目状态
  rob_state_e  state;
  assign o_state = state;

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
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic [2:0] prior;
      prior = '0;
      for (int j = 0; j < i; j++) prior += 3'(enqForPtr[j]);
      allocate_ptr[i] = enq_ptr_vec[prior];
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
  function automatic logic [4:0] sum_wb_for(input int idx);
    logic [4:0] s;
    s = '0;
    for (int p = 0; p < NUM_EXU_WB; p++)
      if (wb_valid[p] & (wb_robidx[p] == PTR_W'(idx)))
        s += wb_num[p];
    return s;
  endfunction
  function automatic logic any_std_wb_for(input int idx);
    logic r;
    r = 1'b0;
    for (int p = 0; p < NUM_EXU_WB; p++)
      if (wb_is_std[p] & wb_valid[p] & (wb_robidx[p] == PTR_W'(idx))) r = 1'b1;
    return r;
  endfunction
  function automatic logic [4:0] or_fflags_for(input int idx);
    logic [4:0] r;
    r = '0;
    for (int p = 0; p < NUM_EXU_WB; p++)
      if (wb_fflags_valid[p] & wb_valid[p] & (wb_robidx[p] == PTR_W'(idx))) r |= wb_fflags[p];
    return r;
  endfunction
  function automatic logic or_vxsat_for(input int idx);
    logic r;
    r = 1'b0;
    for (int p = 0; p < NUM_EXU_WB; p++)
      if (wb_vxsat_valid[p] & wb_vxsat[p] & wb_valid[p] & (wb_robidx[p] == PTR_W'(idx))) r = 1'b1;
    return r;
  endfunction
  function automatic logic any_branch_taken_for(input int idx);
    logic r;
    r = 1'b0;
    for (int p = 0; p < NUM_EXU_WB; p++)
      if (wb_branch_taken[p] & wb_valid[p] & (wb_robidx[p] == PTR_W'(idx))) r = 1'b1;
    return r;
  endfunction
  function automatic logic any_excp_flush_for(input int idx);
    logic r;
    r = 1'b0;
    for (int p = 0; p < NUM_WB; p++)
      if (excp_wb_valid[p] & excp_wb_need_flush[p] & (excp_wb_robidx[p] == PTR_W'(idx))) r = 1'b1;
    return r;
  endfunction

  // 入队命中: 该 robIdx 被哪个口的 firstUop 占用。
  function automatic logic [RENAME_WIDTH-1:0] enq_inst_hit(input int idx);
    logic [RENAME_WIDTH-1:0] h;
    for (int i = 0; i < RENAME_WIDTH; i++)
      h[i] = canEnqueue[i] & (allocate_ptr[i].value == PTR_W'(idx));
    return h;
  endfunction
  // 该 robIdx 上「真正写寄存器堆」的 uop 数(本拍各口里 robIdx 匹配 & needWriteRf)。
  function automatic logic [UOP_CNT_W-1:0] real_dest_enq_num(input int idx);
    logic [UOP_CNT_W-1:0] s;
    s = '0;
    for (int i = 0; i < RENAME_WIDTH; i++)
      if (enq_valid[i] & o_enq_canAccept & enq_need_write_rf[i] & (enq_robidx_value[i] == PTR_W'(idx)))
        s += UOP_CNT_W'(1);
    return s;
  endfunction

  // =====================================================================
  // 5. robDeqGroup 行读更新: 把「行内 8 条 + 下一行 8 条」按 writeback/enq 更新后
  //    存进 robDeqGroup(本可读核简化: 直接用 rob_entries 当前值经 connect 装入,
  //    writeback 的当拍合并在 rob_entries 的下一拍值里体现)。
  //    注: golden 用 robBanksRdataThisLineUpdate 做「读出后即时合并 wb」, 这里
  //    用 connect_commit_entry(下一拍 entry) 表达同一语义。
  // =====================================================================
  rob_entry_t rob_entries_next [ROB_SIZE];
  always_comb begin
    for (int i = 0; i < ROB_SIZE; i++) begin
      rob_entry_t e;
      logic [RENAME_WIDTH-1:0] ihit;
      logic                    is_first_enq;
      logic [4:0]              wbc;
      logic                    nf_wb;
      e   = rob_entries[i];
      ihit = enq_inst_hit(i);
      is_first_enq = ~rob_entries[i].valid & (|ihit);
      wbc   = sum_wb_for(i);
      nf_wb = any_excp_flush_for(i);

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
        if (any_std_wb_for(i)) e.std_writebacked = 1'b1;
      end

      // ---- realDestSize ----
      if (is_first_enq)
        e.real_dest_size = real_dest_enq_num(i);
      else if (rob_entries[i].valid & (|enq_inst_hit(i)))
        e.real_dest_size = rob_entries[i].real_dest_size + real_dest_enq_num(i);

      // ---- fflags / vxsat ----
      if (is_first_enq) e.fflags = '0;
      else              e.fflags = rob_entries[i].fflags | or_fflags_for(i);
      if (is_first_enq) e.vxsat = 1'b0;
      else              e.vxsat = rob_entries[i].vxsat | or_vxsat_for(i);

      // ---- trace itype: 分支 taken → Taken(=3) ----
      if (rob_entries[i].valid & is_branch_type(rob_entries[i].itype) & any_branch_taken_for(i))
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
        e.interrupt_safe= enq_allow_interrupt_hit(i);
      end
      rob_entries_next[i] = e;
    end
  end

  // 分支类型判定(itype: 4=NoBranch/NotTaken 之外的 branch code)。
  function automatic logic is_branch_type(input logic [ITYPE_W-1:0] t);
    // 香山 Itype: branch 类(Taken=3, NotTaken=4 也算 branch);此处保留与 golden 同义。
    return (t >= 4'd3) & (t <= 4'd6);
  endfunction
  // 入队该条目 interrupt_safe: 命中口的 allow_interrupt。
  function automatic logic enq_allow_interrupt_hit(input int idx);
    logic r;
    logic [RENAME_WIDTH-1:0] h;
    r = 1'b0;
    h = enq_inst_hit(idx);
    for (int k = RENAME_WIDTH-1; k >= 0; k--)
      if (h[k]) r = enq_allow_interrupt[k];
    return r;
  endfunction

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
        csum = prefix_realdest_commit(i);
      if (o_commits_isWalk & (shouldWalkVec[i] | donotNeedWalk[i]))
        wsum = prefix_realdest_walk(i);
    end
    o_rab_commitSize = csum;
    o_rab_walkSize   = wsum;
  end
  function automatic logic [UOP_CNT_W:0] prefix_realdest_commit(input int upto);
    logic [UOP_CNT_W:0] s;
    s = '0;
    for (int i = 0; i <= upto; i++)
      s += hasCommitted[i] ? '0 : {1'b0, robDeqGroup[i].real_dest_size};
    return s;
  endfunction
  function automatic logic [UOP_CNT_W:0] prefix_realdest_walk(input int upto);
    logic [UOP_CNT_W:0] s;
    s = '0;
    for (int i = 0; i <= upto; i++)
      s += donotNeedWalk[i] ? '0 : {1'b0, robDeqGroup[i].real_dest_size};
    return s;
  endfunction

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
  function automatic rob_ptr_t ptr_add(input rob_ptr_t p, input logic [PTR_W:0] inc);
    logic [PTR_W:0] raw;
    rob_ptr_t o;
    raw = {p.flag, p.value} + inc;
    // value 需对 RobSize 取模(非 2 的幂), 这里按 golden 的环形语义处理。
    if (raw[PTR_W-1:0] >= PTR_W'(ROB_SIZE)) begin
      o.value = raw[PTR_W-1:0] - PTR_W'(ROB_SIZE);
      o.flag  = ~p.flag;
    end else begin
      o.value = raw[PTR_W-1:0];
      o.flag  = p.flag;
    end
    return o;
  endfunction

  // 环形指针减 1(XiangShan CircularQueuePtr `- 1`, 对齐 golden lastWalkPtr_flipped):
  //   new_value = value + (RobSize-1); 若 >= RobSize 则 -RobSize 且 flag 不翻转,
  //   否则(value==0)结果 value=RobSize-1 且 flag 翻转(借位绕到上一圈)。
  function automatic rob_ptr_t ptr_sub1(input rob_ptr_t p);
    logic [PTR_W:0] nv, dv;
    rob_ptr_t o;
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
      for (int i = 0; i < ROB_SIZE; i++) rob_entries[i] <= '0;
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
      for (int i = 0; i < ROB_SIZE; i++) begin
        logic commitCond, enqOH, needFlushRange;
        commitCond = o_commits_isCommit & commit_hit(i);
        enqOH      = |enq_inst_hit(i);
        needFlushRange = redirectValidReg & in_flush_range(i);
        // 先落第 4/5 节算好的状态字段
        rob_entries[i] <= rob_entries_next[i];
        // valid 单独按优先级覆盖
        if (commitCond)
          rob_entries[i].valid <= 1'b0;
        else if (enqOH & ~io_redirect_valid)
          rob_entries[i].valid <= 1'b1;
        else if (needFlushRange)
          rob_entries[i].valid <= 1'b0;
        else
          rob_entries[i].valid <= rob_entries[i].valid;
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
  function automatic logic commit_hit(input int idx);
    logic r;
    r = 1'b0;
    for (int i = 0; i < COMMIT_WIDTH; i++)
      if (o_commits_commitValid[i] & (deq_ptr_vec[i].value == PTR_W'(idx))) r = 1'b1;
    return r;
  endfunction

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
  function automatic logic in_flush_range(input int idx);
    logic inrange;
    if (redirectEnd > redirectBegin)
      inrange = (PTR_W'(idx) > redirectBegin) & (PTR_W'(idx) < redirectEnd);
    else
      inrange = (PTR_W'(idx) > redirectBegin) | (PTR_W'(idx) < redirectEnd);
    return inrange | redirectAll;
  endfunction

  // exception.valid 打一拍。
  logic exceptionValidReg;
  always_ff @(posedge clock or posedge reset)
    if (reset) exceptionValidReg <= 1'b0;
    else       exceptionValidReg <= exceptionHappen;
  assign o_exception_valid = exceptionValidReg;

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

endmodule
