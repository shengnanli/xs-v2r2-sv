// =====================================================================
// xs_RenameBuffer_core —— 重命名缓冲(Rename Buffer, Rab) 可读重写
// ---------------------------------------------------------------------
// 功能定位(后端 Rename 与 ROB 之间)：
//   一个 RabSize=256 项的【环形队列】，把「rename 入队映射」与「ROB 按序提交回收」解耦。
//   每条 needWriteRf 的指令入队时记下 (ldest, pdest, 各写使能)；ROB 提交时按提交数从队头
//   弹出，把这些映射经 io.commits 交给 RenameTable 的 archWrite，从而把"被覆盖的旧物理号"
//   交还 freelist 回收。redirect 时通过 walk 把投机映射回滚。
//
// 三种工作态(state)：
//   S_IDLE         正常：入队 + 按 commitSize 出队提交(io.commits.isCommit)。
//   S_WALK         回滚回放：从快照点/过渡点用 walkPtr 逐拍把投机映射写回 RAT.specTable
//                  (io.commits.isWalk)，直到 walkPtr 追上 enqPtr。
//   S_SPECIAL_WALK 无快照回滚的过渡态：本拍既是 commit 又是 walk，用 deqPtr 把"已提交但
//                  还没真正写进 archRAT 的 commitSize"走完，再进入 S_WALK。
//
// 关键计数(都做"压缩"——每拍最多处理 RabCommitWidth=6 项)：
//   commitSize / walkSize / specialWalkSize  : 各自"待处理累计数"(寄存器)。
//   commitNum  / walkNum                      : 由 commitValid/walkValid 压缩得到的本拍实际处理数。
//   commitCount/ walkCount / specialWalkCount : 视当前态选出的有效推进步数(驱动指针前进)。
//
// 指针(CircularQueuePtr {flag,value})：
//   enqPtr  入队头(enqPtrVec 是连续 6 个)；deqPtr  出队头(commit 用)；
//   walkPtr 回滚指针；diffPtr difftest 真值读指针；vcfg 指针仅用于内部(本配置已被优化)。
//   deqPtr 同时维护一份 256 位 one-hot(deqPtrOH)，对应 golden 的同名寄存器(便于 FM 配平)。
//
// 子模块：SnapshotGenerator(对 enqPtr 打快照，redirect+useSnpt 时供 walkPtr 跳转)，当黑盒。
// 比对见 golden/chisel-rtl/RenameBuffer.sv。文档见 docs/backend/RenameBuffer.md。
// =====================================================================
module xs_RenameBuffer_core
  import renamebuffer_pkg::*;
(
  input  logic                       clock,
  input  logic                       reset,

  input  logic                       io_redirect_valid,

  // rename 入队请求(RenameWidth=6 口)
  input  rab_req_t                   io_req            [RENAME_WIDTH],

  // 来自 ROB 的提交/回滚指示
  input  logic [PTR_W-1:0]           io_fromRob_walkSize,
  input  logic                       io_fromRob_walkEnd,
  input  logic [PTR_W-1:0]           io_fromRob_commitSize,
  input  logic                       io_fromRob_vecLoadExcp_valid,

  // 快照端口(转发给 SnapshotGenerator 黑盒)
  input  logic                       io_snpt_snptEnq,
  input  logic                       io_snpt_snptDeq,
  input  logic                       io_snpt_useSnpt,
  input  logic [SNAP_SEL_W-1:0]      io_snpt_snptSelect,
  input  logic [SNAPSHOT_NUM-1:0]    io_snpt_flushVec,

  // 出队/入队状态输出(io_enqPtrVec 在本配置无消费者，已被 golden 优化掉，不暴露)
  output logic                       io_canEnq,
  output logic                       io_canEnqForDispatch,

  // 提交/回滚通道(RabCommitWidth=6 口)
  output logic                       io_commits_isCommit,
  output logic                       io_commits_isWalk,
  output logic [COMMIT_WIDTH-1:0]    io_commits_commitValid,
  output logic [COMMIT_WIDTH-1:0]    io_commits_walkValid,
  output rab_info_t                  io_commits_info   [COMMIT_WIDTH],

  // 队列空满状态
  output logic                       io_status_walkEnd,
  output logic                       io_status_commitEnd,

  // 送 VecExcpDataMergeModule 的 (lreg,preg) 映射(仅 special_walk + vecLoadExcp 时有效)
  output logic                       io_toVecExcpMod_valid [COMMIT_WIDTH],
  output logic [LDEST_W-1:0]         io_toVecExcpMod_lreg  [COMMIT_WIDTH],
  output logic [VEC_PREG_W-1:0]      io_toVecExcpMod_preg  [COMMIT_WIDTH],

  // difftest 真值提交流(无旁路，直接读队列)
  output logic                       io_diffCommits_commitValid [NUM_DIFF],
  output rab_info_t                  io_diffCommits_info        [NUM_DIFF]
);

  // =====================================================================
  // 0. 环形队列存储 + 指针寄存器
  // =====================================================================
  rab_info_t  rename_buffer [RAB_SIZE];   // 256 项映射存储

  rab_ptr_t   enq_ptr;                     // 入队头(= enqPtrVec[0])
  // golden 把 enqPtrVec[1..5] 也做成真寄存器(每拍 = enqPtrNext + k)，入队口按
  // "前序占位数"直接查这组寄存器。这里 1:1 镜像(值域仅 value，flag 只在 [0] 有)，
  // 供 allocate_ptr 查表使用，与 golden 状态编码一致(FM 可配平)。
  // enqPtrVec_5：低 2 位恒 == enqPtrVec_1[1:0](+5 ≡ +1 mod 4)，查表用后者代表，故本寄存器
  //   只存高 6 位 [7:2]，消 enqPtrVec_5_value[1] impl-only 死位(golden 侧同值位由 dup-merge
  //   合并到 enqPtrVec_1，无 golden-only 残留)。
  logic [PTR_W-1:0] enqPtrVec_1_value, enqPtrVec_2_value, enqPtrVec_3_value,
                    enqPtrVec_4_value;
  logic [PTR_W-1:2] enqPtrVec_5_value;
  rab_ptr_t   deq_ptr;                     // 出队头(commit)
  logic [RAB_SIZE-1:0] deq_ptr_oh;         // deq_ptr 的 256 位 one-hot(与 golden 同名 reg 对齐)
  rab_ptr_t   walk_ptr;                    // 回滚回放指针
  // diffPtr：golden 存 {flag,value} 但只用 value 作环形索引，flag 是自环死位(无扇出)。
  // 这里只保留 value(8 位环形回绕加法)，与 golden diffPtr_value 逐位相等；golden 侧
  // diffPtr_flag 因输出只读 value 成 golden-only cone-dead(可读 impl 正确省略)。
  logic [PTR_W-1:0] diff_ptr_value;         // difftest 读指针(仅 value)

  rab_state_e state;
  logic       rob_walk_end_reg;            // 锁存 fromRob.walkEnd(redirect 拍清除)
  logic       vec_load_excp_valid;         // 锁存 vecLoadExcp.valid(special_walk 期间)

  logic [PTR_W-1:0] commit_size;           // 待提交累计数
  logic [PTR_W-1:0] walk_size;             // 待回滚累计数
  logic [PTR_W-1:0] special_walk_size;     // 待特殊回滚累计数

  // allowEnqueue：根据队列占用预判下拍能否入队，打一拍输出(GatedValidRegNext)。
  logic       allow_enqueue_reg;
  logic       allow_enqueue_dispatch_reg;

  // =====================================================================
  // 1. 入队计数：realNeedAlloc / enqCount
  //    只有真正写寄存器堆的指令才占位；enqCount 为本拍占位总数。
  // =====================================================================
  logic [RENAME_WIDTH-1:0] need_alloc_vec;
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++)
      need_alloc_vec[i] = real_need_alloc(io_req[i]);

  logic [3:0] enq_count;
  always_comb begin
    enq_count = '0;
    for (int i = 0; i < RENAME_WIDTH; i++)
      enq_count += 4'(need_alloc_vec[i]);
  end

  // =====================================================================
  // 2. commit / walk 的"压缩"计数
  //    commitValid/walkValid 由各自 size 与当前态共同决定(见第 4 节)，
  //    commitNum/walkNum 再从 valid 位向量压缩出"本拍处理几条"。
  // =====================================================================
  // 从 valid 位向量压缩出处理条数：最高位有效则 6，依次类推；都无效则 0(但仅在 [0] 有效时计)。
  function automatic logic [2:0] compress_num(input logic [COMMIT_WIDTH-1:0] v);
    if      (v[5]) return 3'd6;
    else if (v[4]) return 3'd5;
    else if (v[3]) return 3'd4;
    else if (v[2]) return 3'd3;
    else if (v[1]) return 3'd2;
    else           return 3'd1;
  endfunction

  logic [2:0] commit_num, walk_num;
  always_comb begin
    commit_num = io_commits_commitValid[0] ? compress_num(io_commits_commitValid) : 3'd0;
    walk_num   = io_commits_walkValid[0]   ? compress_num(io_commits_walkValid)   : 3'd0;
  end

  // 视当前态选出真正驱动指针/size 的推进步数：
  //   commitCount      : 纯 commit(isCommit & !isWalk) 时 = commitNum，否则 0
  //   walkCount        : 纯 walk  (isWalk & !isCommit) 时 = walkNum，否则 0
  //   specialWalkCount : 既 commit 又 walk(special_walk) 时 = walkNum，否则 0
  logic [2:0] commit_count, walk_count, special_walk_count;
  always_comb begin
    commit_count       = (io_commits_isCommit & ~io_commits_isWalk) ? commit_num : 3'd0;
    walk_count         = (io_commits_isWalk & ~io_commits_isCommit) ? walk_num   : 3'd0;
    special_walk_count = (io_commits_isCommit &  io_commits_isWalk) ? walk_num   : 3'd0;
  end

  // =====================================================================
  // 3. size 的下一拍值(累加 fromRob 新增、减去本拍处理数)
  // =====================================================================
  logic [PTR_W-1:0] commit_size_nxt, walk_size_nxt, special_walk_size_nxt;
  logic [PTR_W-1:0] new_special_walk_size;
  always_comb begin
    commit_size_nxt = commit_size + io_fromRob_commitSize - PTR_W'(commit_count);
    walk_size_nxt   = walk_size   + io_fromRob_walkSize   - PTR_W'(walk_count);
    // 无快照 redirect 时，把"刚算出的待提交数"整体转给 special_walk 去走。
    new_special_walk_size = (io_redirect_valid & ~io_snpt_useSnpt) ? commit_size_nxt : '0;
    special_walk_size_nxt = special_walk_size + new_special_walk_size
                            - PTR_W'(special_walk_count);
  end

  // =====================================================================
  // 4. commit/walk 输出(io.commits)
  //    isCommit : idle 或 special_walk;  isWalk : walk 或 special_walk。
  //    commitValid[i] : idle 下 i<commitSize，或 special_walk 下 i<specialWalkSize。
  //    walkValid[i]   : walk 下 i<walkSize， 或 special_walk 下 i<specialWalkSize。
  //    info[i] : commit/special_walk 用 deqPtr 候选；walk 用 walkPtr 候选(见第 5 节)。
  // =====================================================================
  logic use_commit_ptr;   // 选 deqPtr 候选(commit 或 special_walk) vs walkPtr 候选
  always_comb begin
    io_commits_isCommit = (state == S_IDLE) | (state == S_SPECIAL_WALK);
    io_commits_isWalk   = (state == S_WALK) | (state == S_SPECIAL_WALK);
    use_commit_ptr      = (state == S_IDLE) | (state == S_SPECIAL_WALK);
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
      io_commits_commitValid[i] =
        ((state == S_IDLE)         && (PTR_W'(i) < commit_size)) ||
        ((state == S_SPECIAL_WALK) && (PTR_W'(i) < special_walk_size));
      io_commits_walkValid[i] =
        ((state == S_WALK)         && (PTR_W'(i) < walk_size)) ||
        ((state == S_SPECIAL_WALK) && (PTR_W'(i) < special_walk_size));
    end
  end

  // =====================================================================
  // 5. 候选条目读取(commit / walk / diff)
  //    环形队列直接按 (ptr+i)%RAB_SIZE 索引(value 恒在合法范围 → 不会产生 X 索引)。
  // =====================================================================
  rab_info_t commit_candidates [COMMIT_WIDTH];  // 从 deq_ptr 起 6 项
  rab_info_t walk_candidates   [COMMIT_WIDTH];  // 从 walk_ptr 起 6 项

  // commit 候选与 golden 一致：用【寄存的】deqPtrOH 及其循环左移 1..5 位版本做
  // AND-OR one-hot 选择(golden: commitCandidates_i = OR_j deqPtrOH[j-i] & buffer[j])。
  // 不用二进制 deq_ptr 索引——那与"寄存 one-hot 选择"仅在 one-hot 不变式下等价，
  // FM 无法跨拍证明；镜像 golden 的读法保证 bug-for-bug 一致且可配平。
  logic [RAB_SIZE-1:0] deq_oh_sel [COMMIT_WIDTH];
  always_comb begin
    deq_oh_sel[0] = deq_ptr_oh;
    for (int i = 1; i < COMMIT_WIDTH; i++)
      deq_oh_sel[i] = (deq_ptr_oh << i) | (deq_ptr_oh >> (RAB_SIZE - i));
  end

  always_comb
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
      commit_candidates[i] = '0;
      for (int j = 0; j < RAB_SIZE; j++)
        commit_candidates[i] |= deq_oh_sel[i][j] ? rename_buffer[j] : '0;
      walk_candidates[i]   = rename_buffer[PTR_W'(walk_ptr.value + PTR_W'(i))];
    end

  always_comb
    for (int i = 0; i < COMMIT_WIDTH; i++)
      io_commits_info[i] = use_commit_ptr ? commit_candidates[i] : walk_candidates[i];

  // =====================================================================
  // 6. 快照子模块(黑盒)：对 enqPtr 打快照，redirect+useSnpt 时给出回滚目标点
  // =====================================================================
  rab_ptr_t snapshots [SNAPSHOT_NUM];

  SnapshotGenerator walkPtrSnapshots_snapshotGen (
    .clock           (clock),
    .reset           (reset),
    .io_enq          (io_snpt_snptEnq),
    .io_enqData_flag (enq_ptr.flag),
    .io_enqData_value(enq_ptr.value),
    .io_deq          (io_snpt_snptDeq),
    .io_redirect     (io_redirect_valid),
    .io_flushVec_0   (io_snpt_flushVec[0]),
    .io_flushVec_1   (io_snpt_flushVec[1]),
    .io_flushVec_2   (io_snpt_flushVec[2]),
    .io_flushVec_3   (io_snpt_flushVec[3]),
    .io_snapshots_0_flag (snapshots[0].flag), .io_snapshots_0_value(snapshots[0].value),
    .io_snapshots_1_flag (snapshots[1].flag), .io_snapshots_1_value(snapshots[1].value),
    .io_snapshots_2_flag (snapshots[2].flag), .io_snapshots_2_value(snapshots[2].value),
    .io_snapshots_3_flag (snapshots[3].flag), .io_snapshots_3_value(snapshots[3].value)
  );

  // =====================================================================
  // 7. 状态机：下一态 stateNext
  //    redirect 拍：useSnpt → S_WALK，否则 → S_SPECIAL_WALK。
  //    否则：special_walk 在 specialWalkSize<=6 时转 S_WALK；
  //          walk 在 (robWalkEnd 或本拍 walkEnd&walkSize=0) 且 walkSize<=6 时转 S_IDLE。
  // =====================================================================
  logic       rob_walk_end;             // io.fromRob.walkEnd || robWalkEndReg
  logic       special_walk_end_next;    // specialWalkSize <= RabCommitWidth(=6)
  logic       walk_end_next_cycle;      // 本拍即为最后一拍 walk
  rab_state_e state_next;
  always_comb begin
    rob_walk_end          = io_fromRob_walkEnd | rob_walk_end_reg;
    special_walk_end_next = special_walk_size < PTR_W'(COMMIT_WIDTH + 1); // < 7  ⟺ <= 6
    walk_end_next_cycle   = (rob_walk_end_reg | (io_fromRob_walkEnd & io_fromRob_walkSize == '0))
                            & (walk_size < PTR_W'(COMMIT_WIDTH + 1));

    state_next = state; // 默认保持
    if (io_redirect_valid) begin
      state_next = io_snpt_useSnpt ? S_WALK : S_SPECIAL_WALK;
    end else begin
      unique case (state)
        S_IDLE:         state_next = S_IDLE;
        S_SPECIAL_WALK: if (special_walk_end_next) state_next = S_WALK;
        S_WALK:         if (walk_end_next_cycle)   state_next = S_IDLE;
        default:        state_next = state;
      endcase
    end
  end

  // =====================================================================
  // 8. 指针的下一拍值
  // =====================================================================
  // CircularQueuePtr 加法：{flag,value} 视为 (PTR_W+1) 位累加，溢出翻 flag。
  function automatic rab_ptr_t ptr_add(input rab_ptr_t p, input logic [PTR_W:0] inc);
    logic [PTR_W:0] sum;
    rab_ptr_t       o;
    sum     = {p.flag, p.value} + inc;
    o.flag  = sum[PTR_W];
    o.value = sum[PTR_W-1:0];
    return o;
  endfunction

  // ---- walkPtr：MuxCase(优先级自上而下) ----
  //   idle→walk(快照回滚)            : 跳到所选快照
  //   special_walk→walk             : 跳到 deqPtrNext.head(过渡走完后的队头)
  //   walk 中再次 redirect&useSnpt   : 重新跳到所选快照
  //   walk 普通推进                  : walkPtr + walkCount
  rab_ptr_t deq_ptr_next;     // 见下方 deqPtr 计算(special_walk→walk 用其 head)
  rab_ptr_t walk_ptr_next;
  always_comb begin
    if      ((state == S_IDLE)         && (state_next == S_WALK)) walk_ptr_next = snapshots[io_snpt_snptSelect];
    else if ((state == S_SPECIAL_WALK) && (state_next == S_WALK)) walk_ptr_next = deq_ptr_next;
    else if ((state == S_WALK) && io_snpt_useSnpt && io_redirect_valid) walk_ptr_next = snapshots[io_snpt_snptSelect];
    else if  (state == S_WALK)                                    walk_ptr_next = ptr_add(walk_ptr, {6'h0, walk_count});
    else                                                          walk_ptr_next = walk_ptr;
  end

  // ---- deqPtr：idle 走 commitCount，special_walk 走 specialWalkCount，其余不动 ----
  logic [2:0] deq_ptr_steps;
  always_comb begin
    unique case (state)
      S_IDLE:         deq_ptr_steps = commit_count;
      S_SPECIAL_WALK: deq_ptr_steps = special_walk_count;
      default:        deq_ptr_steps = 3'd0;
    endcase
  end
  always_comb deq_ptr_next = ptr_add(deq_ptr, {6'h0, deq_ptr_steps});

  // deqPtr 的 one-hot 跟随：左循环移位 deq_ptr_steps 步(对应 CircularShift)。
  logic [RAB_SIZE-1:0] deq_ptr_oh_next;
  always_comb begin
    deq_ptr_oh_next = deq_ptr_oh; // steps==0
    for (int s = 1; s <= COMMIT_WIDTH; s++)
      if (deq_ptr_steps == 3'(s))
        deq_ptr_oh_next = (deq_ptr_oh << s) | (deq_ptr_oh >> (RAB_SIZE - s));
  end

  // ---- enqPtr：walk 结束(walk→idle)时跳回 walkPtrNext，否则 + enqCount ----
  rab_ptr_t enq_ptr_next;
  always_comb begin
    if ((state == S_WALK) && (state_next == S_IDLE))
      enq_ptr_next = walk_ptr_next;
    else
      enq_ptr_next = ptr_add(enq_ptr, {5'h0, enq_count});
  end

  // ---- diffPtr：按 fromRob.commitSize 前进(difftest 真值流) ----
  logic [PTR_W-1:0] diff_ptr_value_next;
  always_comb diff_ptr_value_next = PTR_W'(diff_ptr_value + io_fromRob_commitSize);

  // =====================================================================
  // 9. 入队写：每口写到 enqPtrVec[前序占位数] 指向的表项
  //    allocatePtr[i] = enqPtr.value + (前 i 口里 realNeedAlloc 的个数)
  // =====================================================================
  // 与 golden 一致：按"前序占位数"查【寄存的】enqPtrVec 表(index 6/7 不可达，
  // golden 表里回落到 enqPtrVec_0，照搬)。不用 enq_ptr+prior 加法——那依赖
  // enqPtrVec_k == enqPtr+k 不变式，FM 无法跨拍证明。
  logic [7:0][PTR_W-1:0] enq_vec_tbl;
  always_comb begin
    // +4/+5 不改低位：vec_4[0]≡vec_0[0]、vec_5[1:0]≡vec_1[1:0](D 与复位值均相同)。
    // golden 侧 dup-register merge 把这几位寄存器合并；这里读同值的代表寄存器位，使本侧
    // 冗余位无消费者被 FM 前端剪成 unread(与 golden 合并后的比对点集合一致)——若改读整宽，
    // golden 合并后本侧却单独保留该位 → unmatched impl compare point 引发级联 FAILED，实测验证。
    enq_vec_tbl[0] = enq_ptr.value;
    enq_vec_tbl[1] = enqPtrVec_1_value;
    enq_vec_tbl[2] = enqPtrVec_2_value;
    enq_vec_tbl[3] = enqPtrVec_3_value;
    enq_vec_tbl[4] = {enqPtrVec_4_value[PTR_W-1:1], enq_ptr.value[0]};
    enq_vec_tbl[5] = {enqPtrVec_5_value, enqPtrVec_1_value[1:0]};
    enq_vec_tbl[6] = enq_ptr.value;
    enq_vec_tbl[7] = enq_ptr.value;
  end

  logic [PTR_W-1:0] allocate_ptr [RENAME_WIDTH];
  always_comb
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      logic [2:0] prior;
      prior = '0;
      for (int j = 0; j < i; j++) prior += 3'(need_alloc_vec[j]);
      allocate_ptr[i] = enq_vec_tbl[prior];
    end

  // =====================================================================
  // 10. 队列空满 / canEnq
  //     numValidEntries = enqPtr - deqPtr(环形距离)；与 enqCount 之和过阈值则不许入队。
  // =====================================================================
  // 注意与 golden 对齐：同 flag 时先做【8 位】减法再零扩展(借位不进 bit8)；
  // 异 flag 时是真正的 9 位运算(enqVal - 256 - deqVal)。
  logic [PTR_W:0] num_valid_entries;
  always_comb begin
    if (enq_ptr.flag == deq_ptr.flag)
      num_valid_entries = {1'h0, PTR_W'(enq_ptr.value - deq_ptr.value)};
    else
      num_valid_entries = ({1'h0, enq_ptr.value} - 9'(RAB_SIZE)) - {1'h0, deq_ptr.value};
  end
  logic [PTR_W:0] num_after_enq;
  always_comb num_after_enq = num_valid_entries + {5'h0, enq_count};

  always_comb begin
    io_canEnq            = allow_enqueue_reg          & (state == S_IDLE);
    io_canEnqForDispatch = allow_enqueue_dispatch_reg & (state == S_IDLE);
  end

  // =====================================================================
  // 11. 状态输出
  // =====================================================================
  always_comb begin
    io_status_walkEnd   = (walk_size_nxt == '0);
    io_status_commitEnd = (commit_size_nxt == '0);
  end

  // =====================================================================
  // 12. difftest 真值提交流(无旁路：直接按 diffPtr+i 读队列)
  // =====================================================================
  always_comb
    for (int i = 0; i < NUM_DIFF; i++) begin
      io_diffCommits_commitValid[i] = (9'(i) < {1'h0, io_fromRob_commitSize});
      io_diffCommits_info[i]        = rename_buffer[PTR_W'(diff_ptr_value + PTR_W'(i))];
    end

  // =====================================================================
  // 13. 时序更新
  // =====================================================================
  // ---- 13a. 带异步复位的主寄存器 ----
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      enq_ptr <= '{flag:1'b0, value:'0};
      enqPtrVec_1_value <= PTR_W'(1);
      enqPtrVec_2_value <= PTR_W'(2);
      enqPtrVec_3_value <= PTR_W'(3);
      enqPtrVec_4_value <= PTR_W'(4);
      enqPtrVec_5_value <= 6'(PTR_W'(5) >> 2);   // 5[7:2] = 1
      deq_ptr <= '{flag:1'b0, value:'0};
      deq_ptr_oh <= {{(RAB_SIZE-1){1'b0}}, 1'b1};
      diff_ptr_value <= '0;
      state <= S_IDLE;
      rob_walk_end_reg <= 1'b0;
      commit_size <= '0;
      walk_size   <= '0;
      special_walk_size <= '0;
      allow_enqueue_reg          <= 1'b1;
      allow_enqueue_dispatch_reg <= 1'b1;
    end else begin
      enq_ptr    <= enq_ptr_next;
      enqPtrVec_1_value <= PTR_W'(enq_ptr_next.value + PTR_W'(1));
      enqPtrVec_2_value <= PTR_W'(enq_ptr_next.value + PTR_W'(2));
      enqPtrVec_3_value <= PTR_W'(enq_ptr_next.value + PTR_W'(3));
      enqPtrVec_4_value <= PTR_W'(enq_ptr_next.value + PTR_W'(4));
      enqPtrVec_5_value <= PTR_W'(enq_ptr_next.value + PTR_W'(5)) >> 2;
      deq_ptr    <= deq_ptr_next;
      deq_ptr_oh <= deq_ptr_oh_next;
      diff_ptr_value <= diff_ptr_value_next;

      state <= state_next;

      // robWalkEndReg：redirect 清零；否则锁存 fromRob.walkEnd。
      rob_walk_end_reg <= ~io_redirect_valid & (io_fromRob_walkEnd | rob_walk_end_reg);

      // commitSize：无快照 redirect 清零(已转给 special_walk)，否则取下一值。
      commit_size <= (io_redirect_valid & ~io_snpt_useSnpt) ? '0 : commit_size_nxt;
      // walkSize：redirect 清零，否则取下一值。
      walk_size   <= io_redirect_valid ? '0 : walk_size_nxt;
      special_walk_size <= special_walk_size_nxt;

      // allowEnqueue 阈值：numValidEntries+enqCount <= RAB_SIZE-RenameWidth(=250 ⟺ <251)
      //                    及 <= RAB_SIZE-2*RenameWidth(=244 ⟺ <245)。
      allow_enqueue_reg          <= num_after_enq < 9'(RAB_SIZE - RENAME_WIDTH + 1);
      allow_enqueue_dispatch_reg <= num_after_enq < 9'(RAB_SIZE - 2*RENAME_WIDTH + 1);
    end
  end

  // ---- 13b. walkPtr：无复位寄存器，仅在四种触发下更新(对应 golden 的条件赋值) ----
  always_ff @(posedge clock) begin
    if      ((state == S_IDLE)         && (state_next == S_WALK)) walk_ptr <= snapshots[io_snpt_snptSelect];
    else if ((state == S_SPECIAL_WALK) && (state_next == S_WALK)) walk_ptr <= deq_ptr_next;
    else if ((state == S_WALK) && io_snpt_useSnpt && io_redirect_valid) walk_ptr <= snapshots[io_snpt_snptSelect];
    else if  (state == S_WALK)                                    walk_ptr <= ptr_add(walk_ptr, {6'h0, walk_count});
  end

  // ---- 13c. 队列写入：每个有效入队口写到 allocatePtr 指向的表项 ----
  always_ff @(posedge clock) begin
    for (int i = 0; i < RENAME_WIDTH; i++)
      if (need_alloc_vec[i])
        rename_buffer[allocate_ptr[i]] <= req_to_info(io_req[i]);
  end

  // =====================================================================
  // 14. toVecExcpMod：special_walk 且 vecLoadExcp 有效时，把提交的 (ldest,pdest)
  //     打一拍送向量异常合并模块(无复位寄存器)。
  // =====================================================================
  logic [COMMIT_WIDTH-1:0] vec_excp_fire;
  always_comb
    for (int i = 0; i < COMMIT_WIDTH; i++)
      vec_excp_fire[i] = (state == S_SPECIAL_WALK) & vec_load_excp_valid & io_commits_commitValid[i];

  always_ff @(posedge clock) begin
    // vecLoadExcp.valid 锁存：无快照 redirect 拍载入；special_walk 走完(转 walk)时清零；否则保持。
    if (io_redirect_valid) begin
      if (!io_snpt_useSnpt) vec_load_excp_valid <= io_fromRob_vecLoadExcp_valid;
    end else begin
      vec_load_excp_valid <=
        ((state == S_IDLE) | ~((state == S_SPECIAL_WALK) & special_walk_end_next))
        & vec_load_excp_valid;
    end

    for (int i = 0; i < COMMIT_WIDTH; i++) begin
      io_toVecExcpMod_valid[i] <= vec_excp_fire[i];
      if (vec_excp_fire[i]) begin
        io_toVecExcpMod_lreg[i] <= io_commits_info[i].ldest;
        io_toVecExcpMod_preg[i] <= io_commits_info[i].pdest[VEC_PREG_W-1:0];
      end
    end
  end

endmodule
