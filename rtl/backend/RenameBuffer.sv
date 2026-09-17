// =============================================================================
// RenameBuffer.sv —— 重命名缓冲 RAB(Rename Buffer / rob.Rab)
// 设计源：XiangShan src/main/scala/xiangshan/backend/rob/Rab.scala
//         （class RenameBuffer(size)，内部例化 rename.SnapshotGenerator）
// golden 对照：G1-canonical/golden-rtl/RenameBuffer.sv（40993 行，153 端口：69 输入 / 84 输出）
// 配置：KunminghuV2Config —— RabSize=256 / RenameWidth=6 / RabCommitWidth=6
//      （全部从 golden 实测：renameBuffer_0..255 共 256 项；io_req_0..5 共 6 路；
//        io_commits_commitValid_0..5 共 6 路，故 RabCommitWidth=6）
//
// ★ 它是什么 ★
// Rename 级每分配一个物理寄存器，就往这里存一条 (ldest, pdest, 各类 wen, isMove)。
// 它是**架构寄存器映射表(arch RAT)的写入源**：Rob 提交到第几条，就从这里按序
// 吐出多少条给 arch RAT；分支猜错要回滚时，反过来按序**倒着走(walk)**，
// 把 arch RAT 还原。所以它是一个 256 项的循环队列，一头进(rename)、
// 两个读口(提交口 deqPtr / 回滚口 walkPtr)。
//
// ★ 三个状态 ★
//   s_idle(0)         正常：按 commitSize 从 deqPtr 往外吐提交条目
//   s_special_walk(1) 「边提交边回滚」：重定向发生但**没有可用快照**时，
//                     先把已攒下的 commitSize 一次性转成 specialWalkSize，
//                     用**提交指针**deqPtr 把它们当 walk 吐出去（isCommit 与
//                     isWalk 同时为 1，下游据此既写 arch RAT 又回收物理寄存器）。
//   s_walk(2)         真正的回滚：walkPtr 从快照(或 deqPtr)起，按 walkSize 往回走。
//
// ★ 五个不显然的机制 ★
//  1. 「三组指针，三种形态」(§2/§5)：enqPtr 是 6 份 value + **1 份 flag**；
//     deqPtr 是 6 份 value + **6 份 flag**；walkPtr 只有 1 份(flag+value)。
//     照 Chisel 字面「每个指针都是完整 CircularQueuePtr」写会凭空多 5 个寄存器。
//     根因见下面「多份 vs 一份」。
//  2. 「deqPtr 有个 one-hot 影子寄存器」(§5/§6)：deqPtrOH 是 256 位独立寄存器，
//     复位值 256'h1，靠循环左移推进。提交读口**用的是它**，不是 deqPtr.value。
//     两者恒等（golden 有条 XSError 断言它们同步），但**是两个寄存器**，
//     合并掉就让 golden 少一个 FM 比对点。★不许合并★
//     诚实记一笔：这条**UT 验不出来**（两侧都从复位值出发，永远同步；实测换成
//     索引读，20k 拍 errors=0，见 verif/ut/RenameBuffer/mutants.py 的头注释）。
//     守住它的是 FM，不是 UT。
//  3. 「回滚读口用二进制指针、提交读口用 one-hot」(§6)：同一个 256 项表，
//     两个读口的选择信号形态**不一样**，这是 golden 的真实形状，不是笔误。
//  4. 「入队分配指针是前缀和查表」(§2)：第 w 路要写的表项 =
//     enqPtrVec[ popcount(realNeedAlloc[0..w-1]) ]。查表是 8 项的，
//     下标 6/7 越界 —— golden 的越界语义是**取第 0 项**（见 §2 的实测证据）。
//  5. 「写端口优先级是倒着的」(§10)：同一个表项被多路请求同时命中时，
//     golden 的 if/else-if 链从 req[5] 开始，即**高编号路优先**。
//     实际上 allocatePtrVec[w] = enqPtr + popcount(realNeedAlloc[0..w-1])，
//     两路都真要占格时指针不可能相等 ⇒ 冲突不存在，优先级怎么排都一样
//     （实测：反过来排，20k 拍 errors=0）。照抄只为与 golden 同构。
//     本核写成 w 升序的非 else 覆盖写，末位 w=5 生效，与 golden 同义。
//
// ★ 「多份 vs 一份」：同一个模块里有三种答案（★本轮最容易翻车的一条★）★
//   Chisel 三处都写 `RegInit(VecInit.tabulate(N)(idx => RenameBufferPtr(false, idx)))`，
//   golden 实测：
//     - enqPtrVec：6 个 value，**只有 1 个 flag**（enqPtrVec_0_flag）。
//       其余 5 个 flag 没有读者（io.enqPtrVec 这个输出端口整个被 firtool 消掉了），
//       被消。
//     - deqPtrVec：6 个 value **加 6 个 flag**。flag 保住是因为 Chisel 末尾有
//       `dontTouch(deqPtrVec)`（golden 里留下 data_0_probe 这类悬空线为证）。
//     - walkPtr：就 1 个（flag+value），Chisel 本来就只有一个。
//   照字面写会多 5 个寄存器，UT/elaborate/portlint 一个都不响，只有 FM 会报。
//
// ★ golden 里被 firtool 消掉的东西（照 golden，不照 Chisel）★
//   - io.enqPtrVec 输出端口（6×9 位）：父模块没接，端口连同驱动一起消失。
//   - enqPtrOH 寄存器（Chisel 有，256 位）：它只驱动自己的次态，无其它读者 → 消。
//     （deqPtrOH 有读者 commitCandidates，所以留下了。）
//   - currentVdIdx 寄存器：只写不读 → 消。
//   - vecLoadExcp 的 bits(isStrided/isVlm)：只有 valid 有读者 → 只剩 valid。
//   - RenameBufferEntry.robIdx：本配置下 io.commits.robIdx 不存在 → 256 项都没有。
//
// ★ 复位域（golden 三个 always 块逐个分类，实测）★
//   golden 23086-23099：`ifndef SYNTHESIS 的断言块（两条 XSError），不参与判定。
//   golden 23136-23223：always @(posedge clock or posedge reset) —— **异步复位**。
//     复位值★不是全 0★：enqPtrVec/deqPtrVec 的 value 是 0,1,2,3,4,5；
//     deqPtrOH = 256'h1；allowEnqueue/allowEnqueueForDispatch 的打拍寄存器 = 1。
//   golden 23251-38653：always @(posedge clock) —— **完全不复位**：
//     256 项缓冲表(×8 字段)、walkPtr、vecLoadExcp_valid、
//     以及 toVecExcpMod 的 6×(valid + lreg + preg) 打拍寄存器。
//     照抄成带复位是真 bug。
//
// ★ 更新优先级（同一状态多源写，golden 实测）★
//   state      ：redirect > (s_special_walk 且 specialWalkEndNext) > (s_walk 且
//                walkEndNextCycle) > 保持
//   walkSize   ：redirect(清 0) > walkSizeNxt
//   commitSize ：redirect 且 !useSnpt(清 0) > commitSizeNxt
//   vecLoadExcp：redirect 且 useSnpt(**保持**) > redirect 且 !useSnpt(收) >
//                s_special_walk 末拍(清 0) > 保持
//   缓冲表项   ：req[5] > req[4] > … > req[0]（见上面第 5 条）
//   enqPtr     ：(s_walk→s_idle 时) 跟 walkPtrNext > enqPtr + enqCount
//   deqPtr     ：无条件 = deqPtr + deqPtrSteps（steps 在 s_walk 时为 0）
// =============================================================================

package renamebuffer_pkg;

  // ---- 规模常量。全部从 G1 golden 实测，右侧注明实测出处 ----
  localparam int RAB_SIZE  = 256;  // golden 的 renameBuffer_0..255
  localparam int RENAME_W  = 6;    // golden 的 io_req_0..5
  localparam int COMMIT_W  = 6;    // golden 的 io_commits_commitValid_0..5
  localparam int PTR_W     = 8;    // log2Ceil(256) —— golden 的 reg [7:0] walkPtr_value
  localparam int SIZE_W    = 8;    // log2Up(256)  —— golden 的 reg [7:0] commitSize
  localparam int CNT_W     = 3;    // log2Up(6)+1  —— golden 的 wire [2:0] walkCount
  localparam int LDEST_W   = 6;    // golden 的 io_req_0_bits_ldest [5:0]
  localparam int PDEST_W   = 8;    // golden 的 io_req_0_bits_pdest [7:0]
  localparam int SNPT_NUM  = 4;    // golden 的 io_snpt_flushVec_0..3
  // toVecExcpMod 的 preg 端口只有 7 位，而缓冲里的 pdest 是 8 位：
  // golden 把打拍寄存器留成 8 位，**输出时截低 7 位**（见 wrapper）。
  localparam int VEXCP_PREG_W = 7; // golden 的 output [6:0] io_toVecExcpMod_..._bits_preg

  // 循环队列指针：flag 表示绕了奇数圈。整体 9 位，加法的进位自然落到 flag。
  typedef struct packed {
    logic                flag;
    logic [PTR_W-1:0]    value;
  } rab_ptr_t;

  // 一条重命名映射（= Chisel 的 RabCommitInfo）。字段顺序与 golden 的
  // renameBuffer_N_info_* 声明顺序一致，便于与 golden 对读。
  typedef struct packed {
    logic [LDEST_W-1:0] ldest;
    logic [PDEST_W-1:0] pdest;
    logic               rfWen;
    logic               fpWen;
    logic               vecWen;
    logic               v0Wen;
    logic               vlWen;
    logic               isMove;
  } rab_info_t;

  localparam int INFO_W = $bits(rab_info_t);

  // 一路 rename 请求。golden 只用到 DynInst 的这 9 根线。
  typedef struct packed {
    logic      valid;
    rab_info_t info;
  } rab_req_t;

  // 状态机。编码即 golden 的 state 取值（Chisel `Enum(3)` 顺序）。
  typedef enum logic [1:0] {
    S_IDLE         = 2'd0,
    S_SPECIAL_WALK = 2'd1,
    S_WALK         = 2'd2
  } rab_state_e;

endpackage

// -----------------------------------------------------------------------------
// 可读核
// -----------------------------------------------------------------------------
module xs_RenameBuffer_core
  import renamebuffer_pkg::*;
(
  input  logic       clock,
  input  logic       reset,                 // 异步、高有效（golden: posedge reset）

  input  logic       redirect_valid,        // 本拍有重定向（分支猜错 / 异常）

  // ---- rename 侧：每拍最多 RENAME_W 条新映射 ----
  input  rab_req_t   req [RENAME_W],

  // ---- Rob 侧：本拍又攒了多少条待提交 / 待回滚 ----
  input  logic [SIZE_W-1:0] rob_commit_size,
  input  logic [SIZE_W-1:0] rob_walk_size,
  input  logic              rob_walk_end,          // Rob 的 walk 已经走完
  input  logic              rob_vec_load_excp_valid,

  // ---- 快照端口（SnapshotGenerator 的控制线由本模块转发）----
  input  logic       snpt_enq,
  input  logic       snpt_deq,
  input  logic       snpt_use,               // 本次重定向有可用快照
  input  logic [1:0] snpt_select,            // 用第几号快照
  input  logic [SNPT_NUM-1:0] snpt_flush_vec,

  // ---- 输出 ----
  output logic       can_enq,                // rename 可以往本队列写
  output logic       can_enq_for_dispatch,   // 更保守的水位（留两拍余量）
  output logic       commits_is_commit,
  output logic [COMMIT_W-1:0] commits_commit_valid,
  output logic       commits_is_walk,
  output logic [COMMIT_W-1:0] commits_walk_valid,
  output rab_info_t  commits_info [COMMIT_W],
  output logic       status_walk_end,
  output logic       status_commit_end,
  // 向量访存异常模块要的 (lreg → preg) 映射，打一拍送出
  output logic                      vec_excp_valid [COMMIT_W],
  output logic [LDEST_W-1:0]        vec_excp_lreg  [COMMIT_W],
  output logic [VEXCP_PREG_W-1:0]   vec_excp_preg  [COMMIT_W],

  // 送给内嵌 SnapshotGenerator 的入队数据 = 当前 enqPtr（见 wrapper 里的例化）
  output rab_ptr_t   snapshot_enq_data,
  input  rab_ptr_t   snapshots [SNPT_NUM]
);

  // ===========================================================================
  // §1 状态寄存器
  // ===========================================================================
  // ---- 异步复位域（golden 23136-23223）----
  logic                 enq_ptr_flag_q;                 // ★只有 head 有 flag★（文件头）
  logic [PTR_W-1:0]     enq_ptr_value_q [RENAME_W];     // 复位值 0,1,2,3,4,5
  logic                 deq_ptr_flag_q  [COMMIT_W];     // ★6 份 flag 都在★（dontTouch）
  logic [PTR_W-1:0]     deq_ptr_value_q [COMMIT_W];     // 复位值 0,1,2,3,4,5
  logic [RAB_SIZE-1:0]  deq_ptr_oh_q;                   // 复位值 256'h1，≠0
  rab_state_e           state_q;
  logic                 rob_walk_end_q;
  logic [SIZE_W-1:0]    commit_size_q;                  // 已攒下、待吐给 arch RAT 的条数
  logic [SIZE_W-1:0]    walk_size_q;                    // 待回滚条数
  logic [SIZE_W-1:0]    special_walk_size_q;            // 「边提交边回滚」剩余条数
  logic                 allow_enq_q;                    // ★复位值 1★
  logic                 allow_enq_dispatch_q;           // ★复位值 1★

  // ---- 无复位域（golden 23251-38653）----
  rab_info_t            buffer_q [RAB_SIZE];            // 256 项映射表
  rab_ptr_t             walk_ptr_q;
  logic                 vec_load_excp_valid_q;
  logic                 vec_excp_valid_q [COMMIT_W];
  logic [LDEST_W-1:0]   vec_excp_lreg_q  [COMMIT_W];
  logic [PDEST_W-1:0]   vec_excp_preg_q  [COMMIT_W];    // 8 位，输出时截到 7 位

  // 打包成 rab_ptr_t 方便做 9 位加法（进位落到 flag）。
  rab_ptr_t enq_ptr, deq_ptr;
  assign enq_ptr = '{flag: enq_ptr_flag_q,    value: enq_ptr_value_q[0]};
  assign deq_ptr = '{flag: deq_ptr_flag_q[0], value: deq_ptr_value_q[0]};

  // ===========================================================================
  // §2 入队：哪几路真要占表项，各占哪一格
  // ===========================================================================
  // 只有会写某个寄存器堆的指令才需要留映射（纯分支/store 不占）。
  logic [RENAME_W-1:0] real_need_alloc;
  always_comb
    for (int w = 0; w < RENAME_W; w++)
      real_need_alloc[w] = req[w].valid
                         & (req[w].info.rfWen  | req[w].info.fpWen | req[w].info.vecWen
                          | req[w].info.v0Wen  | req[w].info.vlWen);

  logic [CNT_W-1:0] enq_count;                  // 本拍占几格
  always_comb begin
    enq_count = '0;
    for (int w = 0; w < RENAME_W; w++) enq_count += CNT_W'(real_need_alloc[w]);
  end

  // 第 w 路要写的表项 = enqPtrVec[ 前面几路里有几路要占 ]。
  // ★越界语义★：golden 把这张表展成 8 项（wire [7:0][7:0] _GEN_112），
  //   下标 0..5 是 enqPtrVec_0..5_value，**下标 6、7 都填 enqPtrVec_0_value**
  //   —— firtool 对 Vec 越界读填的是「第 0 项」，不是回绕、也不是 0。
  //   这两格实际不可达（前缀和最大 5），照抄只为与 golden 逐位同构。
  logic [PTR_W-1:0] enq_ptr_lookup [8];
  always_comb begin
    for (int k = 0; k < 8; k++) enq_ptr_lookup[k] = enq_ptr_value_q[0];   // 越界默认项
    for (int k = 0; k < RENAME_W; k++) enq_ptr_lookup[k] = enq_ptr_value_q[k];
  end

  logic [CNT_W-1:0] alloc_sel [RENAME_W];       // 前缀和，3 位，取值 0..5
  logic [PTR_W-1:0] alloc_ptr [RENAME_W];
  always_comb begin
    for (int w = 0; w < RENAME_W; w++) begin
      alloc_sel[w] = '0;
      for (int k = 0; k < w; k++) alloc_sel[w] += CNT_W'(real_need_alloc[k]);
      alloc_ptr[w] = enq_ptr_lookup[alloc_sel[w]];
    end
  end

  // ===========================================================================
  // §3 提交 / 回滚的条数
  // ===========================================================================
  // commitNum / walkNum：本拍 6 路里最高的那根有效线的编号 +1（PriorityMux）。
  // golden 把「commitValid(0) 为 0 就算 0」这一层放在**使用处**，这里照抄这个分工。
  logic [CNT_W-1:0] commit_num, walk_num;
  always_comb begin
    commit_num = CNT_W'(1);
    walk_num   = CNT_W'(1);
    for (int i = 1; i < COMMIT_W; i++) begin
      if (commits_commit_valid[i]) commit_num = CNT_W'(i + 1);
      if (commits_walk_valid[i])   walk_num   = CNT_W'(i + 1);
    end
  end

  logic [CNT_W-1:0] commit_count, walk_count, special_walk_count;
  assign commit_count       = (commits_is_commit & ~commits_is_walk   & commits_commit_valid[0])
                            ? commit_num : '0;
  assign walk_count         = (commits_is_walk   & ~commits_is_commit & commits_walk_valid[0])
                            ? walk_num   : '0;
  assign special_walk_count = (commits_is_commit &  commits_is_walk   & commits_walk_valid[0])
                            ? walk_num   : '0;

  logic [SIZE_W-1:0] commit_size_nxt, walk_size_nxt, special_walk_size_nxt;
  assign commit_size_nxt = SIZE_W'(SIZE_W'(commit_size_q + rob_commit_size)
                                   - SIZE_W'(commit_count));
  assign walk_size_nxt   = SIZE_W'(SIZE_W'(walk_size_q + rob_walk_size)
                                   - SIZE_W'(walk_count));
  // 重定向且**没有快照**时，攒下的待提交条目整批转成「边提交边回滚」的量。
  assign special_walk_size_nxt =
      SIZE_W'(SIZE_W'(special_walk_size_q
                      + ((redirect_valid & ~snpt_use) ? commit_size_nxt : SIZE_W'(0)))
              - SIZE_W'(special_walk_count));

  // ===========================================================================
  // §4 状态机
  // ===========================================================================
  logic walk_end_next, commit_end_next, special_walk_end_next, walk_end_next_cycle;
  assign walk_end_next         = (walk_size_nxt   == '0);
  assign commit_end_next       = (commit_size_nxt == '0);
  assign special_walk_end_next = (special_walk_size_q <= SIZE_W'(COMMIT_W));
  // robWalkEndReg 一旦置上，walkSize 只减不增，于是「剩下不超过一拍的量」就是末拍。
  assign walk_end_next_cycle   = (rob_walk_end_q | (rob_walk_end & (rob_walk_size == '0)))
                               & (walk_size_q <= SIZE_W'(COMMIT_W));

  // ★2'b11 这个「不可达状态」的行为必须照 golden★
  // golden 写的是 `(|state) ? (state==1 ? … : state==2&&… ? 0 : state) : 0`：
  // 判据是 **state≠0**，不是「枚举穷尽」。于是 state=2'b11 时 golden 走进
  // (|state) 分支、两个 elsif 都不成立 ⇒ **保持 2'b11**。
  // 本核第一版把最后一路写成 `else state_next = S_IDLE`（"剩下的都当 idle"），
  // 在 2'b11 上就与 golden 分道扬镳。这条 UT 永远打不到（state 三个合法值之外
  // 进不去），是 FM 抓出来的 —— 见 verif/ut/RenameBuffer/mutants.py 头注释里
  // 「UT 零判别力」那一族的实例。所以 s_idle 单列一路，末路是**保持**。
  rab_state_e state_next;
  always_comb begin
    if      (redirect_valid)            state_next = snpt_use ? S_WALK : S_SPECIAL_WALK;
    else if (state_q == S_IDLE)         state_next = S_IDLE;
    else if (state_q == S_SPECIAL_WALK) state_next = special_walk_end_next ? S_WALK : state_q;
    else if (state_q == S_WALK)         state_next = walk_end_next_cycle   ? S_IDLE : state_q;
    else                                state_next = state_q;   // ★2'b11：保持★
  end

  // ===========================================================================
  // §5 三组指针的下一拍值
  // ===========================================================================
  // ---- walkPtr：四选一的优先链（顺序即 Chisel MuxCase 的顺序）----
  rab_ptr_t walk_ptr_next, deq_ptr_next, enq_ptr_next;
  rab_ptr_t deq_ptr_vec_next [COMMIT_W];

  always_comb begin
    if      (state_q == S_IDLE         && state_next == S_WALK)
      walk_ptr_next = snapshots[snpt_select];              // 有快照：一步到位
    else if (state_q == S_SPECIAL_WALK && state_next == S_WALK)
      walk_ptr_next = deq_ptr_vec_next[0];                 // 无快照：接着提交指针走
    else if (state_q == S_WALK && snpt_use && redirect_valid)
      walk_ptr_next = snapshots[snpt_select];              // walk 中又来一次重定向
    else if (state_q == S_WALK)
      walk_ptr_next = rab_ptr_t'((PTR_W+1)'(walk_ptr_q) + (PTR_W+1)'(walk_count));
    else
      walk_ptr_next = walk_ptr_q;
  end

  // ---- deqPtr：s_idle 时按提交量走，s_special_walk 时按 specialWalk 量走，
  //      s_walk 时不动。golden 是 Mux1H（两项按位或），照抄。----
  logic [CNT_W-1:0] deq_ptr_steps;
  assign deq_ptr_steps = ((state_q == S_IDLE)         ? commit_count       : '0)
                       | ((state_q == S_SPECIAL_WALK) ? special_walk_count : '0);

  assign deq_ptr_next = rab_ptr_t'((PTR_W+1)'(deq_ptr) + (PTR_W+1)'(deq_ptr_steps));
  always_comb
    for (int i = 0; i < COMMIT_W; i++)
      deq_ptr_vec_next[i] = rab_ptr_t'((PTR_W+1)'(deq_ptr_next) + (PTR_W+1)'(i));

  // ---- enqPtr：回滚结束那一拍要把队尾拉回 walkPtr，否则按入队量前进 ----
  assign enq_ptr_next = (state_q == S_WALK && state_next == S_IDLE)
                      ? walk_ptr_next
                      : rab_ptr_t'((PTR_W+1)'(enq_ptr) + (PTR_W+1)'(enq_count));

  // ---- deqPtrOH：deqPtr 的 one-hot 影子寄存器，循环左移推进 ----
  // ★越界语义★：golden 的表是 8 项（wire [7:0][255:0] _GEN_110），下标 0..6 是
  //   左移 0..6，**下标 7 是左移 0**（越界 → 取第 0 项）。步数最大 6，第 7 格不可达。
  // s=0 单列出来：写成通式会出现 `oh >> 256`（右移量等于位宽），SV 规定结果为 0
  // 因而恰好也对，但那是踩在边界规则上，不同工具（尤其 FM 的 read_sverilog）
  // 不值得赌 —— 常量下标本来就能一眼写清。
  logic [RAB_SIZE-1:0] deq_ptr_oh_rot [8];
  always_comb begin
    deq_ptr_oh_rot[0] = deq_ptr_oh_q;
    for (int s = 1; s < 7; s++)
      deq_ptr_oh_rot[s] = (deq_ptr_oh_q << s) | (deq_ptr_oh_q >> (RAB_SIZE - s));
    deq_ptr_oh_rot[7] = deq_ptr_oh_q;                      // 越界默认项
  end

  // ===========================================================================
  // §6 两个读口
  // ===========================================================================
  // 提交口：用 one-hot 影子寄存器 deqPtrOH 做 Mux1H。
  // ★不能换成 buffer_q[deq_ptr.value+i]★ —— deqPtrOH 在 golden 里是一个**独立的
  //   256 位寄存器**（Chisel 里 deqPtr 与 deqPtrOH 并存，靠一条 XSError 断言二者同步），
  //   合并掉就等于让 golden 少一个 FM 比对点。
  //   诚实记一笔：这条**仿真验不出来**。两侧都从复位值出发（deqPtrOH=256'h1、
  //   deqPtr=0）同步推进，恒等；verif/ut/RenameBuffer/mutants.py 的头注释里有实测
  //   （换成索引读，20k 拍 errors=0）。守住它的是 FM，不是 UT。
  logic [INFO_W-1:0] commit_cand_bits [COMMIT_W];
  rab_info_t         commit_cand      [COMMIT_W];
  always_comb begin
    for (int i = 0; i < COMMIT_W; i++) begin
      commit_cand_bits[i] = '0;
      for (int j = 0; j < RAB_SIZE; j++)
        commit_cand_bits[i] |= {INFO_W{deq_ptr_oh_q[j]}}
                             & INFO_W'(buffer_q[(j + i) & (RAB_SIZE-1)]);
      commit_cand[i] = rab_info_t'(commit_cand_bits[i]);
    end
  end

  // 回滚口：直接用二进制指针索引（golden 展成 256 路 walkPtr_value==j 的 one-hot，
  // 那组比较是完备且互斥的，与索引读同义）。索引位宽 8 = log2(256)，精确匹配。
  rab_info_t walk_cand [COMMIT_W];
  always_comb
    for (int i = 0; i < COMMIT_W; i++)
      walk_cand[i] = buffer_q[PTR_W'(walk_ptr_q.value + PTR_W'(i))];

  // ===========================================================================
  // §7 输出：提交/回滚接口与流控
  // ===========================================================================
  assign commits_is_commit = (state_q == S_IDLE) | (state_q == S_SPECIAL_WALK);
  assign commits_is_walk   = (state_q == S_WALK) | (state_q == S_SPECIAL_WALK);

  always_comb
    for (int i = 0; i < COMMIT_W; i++) begin
      commits_commit_valid[i] = ((state_q == S_IDLE)         & (commit_size_q       > SIZE_W'(i)))
                              | ((state_q == S_SPECIAL_WALK) & (special_walk_size_q > SIZE_W'(i)));
      commits_walk_valid[i]   = ((state_q == S_WALK)         & (walk_size_q         > SIZE_W'(i)))
                              | ((state_q == S_SPECIAL_WALK) & (special_walk_size_q > SIZE_W'(i)));
      // s_special_walk 走的是**提交指针**，所以它和 s_idle 共用提交读口。
      commits_info[i] = commits_is_commit ? commit_cand[i] : walk_cand[i];
    end

  assign status_walk_end   = walk_end_next;
  assign status_commit_end = commit_end_next;

  // 占用量 distanceBetween(enqPtr, deqPtr)。
  // 同 flag：8 位相减后零扩展（golden 就是 8 位减法，不是 9 位）。
  // 异 flag：9 位里算 (enq - 256) - deq；模 512 下与 enq + 256 - deq 等价。
  logic [PTR_W:0] num_valid_entries;
  assign num_valid_entries =
      (enq_ptr_flag_q == deq_ptr_flag_q[0])
        ? {1'b0, PTR_W'(enq_ptr_value_q[0] - deq_ptr_value_q[0])}
        : (PTR_W+1)'((PTR_W+1)'((PTR_W+1)'(enq_ptr_value_q[0]) - (PTR_W+1)'(RAB_SIZE))
                     - (PTR_W+1)'(deq_ptr_value_q[0]));

  logic [PTR_W:0] occupancy_next;      // 本拍入队后的占用量
  assign occupancy_next = (PTR_W+1)'(num_valid_entries + (PTR_W+1)'(enq_count));

  // canEnq 走一级打拍（Chisel 的 GatedValidRegNext，复位值 1）。
  assign can_enq              = allow_enq_q          & (state_q == S_IDLE);
  assign can_enq_for_dispatch = allow_enq_dispatch_q & (state_q == S_IDLE);

  // ===========================================================================
  // §8 向量访存异常映射（s_special_walk 期间把提交条目再抄一份给 VecExcpMod）
  // ===========================================================================
  logic vec_excp_fire [COMMIT_W];
  always_comb
    for (int i = 0; i < COMMIT_W; i++)
      vec_excp_fire[i] = (state_q == S_SPECIAL_WALK)
                       & vec_load_excp_valid_q & commits_commit_valid[i];

  always_comb
    for (int i = 0; i < COMMIT_W; i++) begin
      vec_excp_valid[i] = vec_excp_valid_q[i];
      vec_excp_lreg[i]  = vec_excp_lreg_q[i];
      vec_excp_preg[i]  = vec_excp_preg_q[i][VEXCP_PREG_W-1:0];   // ★8 位存、7 位出★
    end

  // 送给内嵌 SnapshotGenerator 的快照数据 = 当前队尾指针。
  assign snapshot_enq_data = enq_ptr;

  // ===========================================================================
  // §9 主时序块 —— 异步复位域（golden 唯一的 posedge reset 块）
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      enq_ptr_flag_q <= 1'b0;
      for (int i = 0; i < RENAME_W; i++) enq_ptr_value_q[i] <= PTR_W'(i);  // ★0,1,..,5★
      for (int i = 0; i < COMMIT_W; i++) begin
        deq_ptr_flag_q[i]  <= 1'b0;
        deq_ptr_value_q[i] <= PTR_W'(i);                                   // ★0,1,..,5★
      end
      deq_ptr_oh_q         <= {{(RAB_SIZE-1){1'b0}}, 1'b1};                // ★256'h1★
      state_q              <= S_IDLE;
      rob_walk_end_q       <= 1'b0;
      commit_size_q        <= '0;
      walk_size_q          <= '0;
      special_walk_size_q  <= '0;
      allow_enq_q          <= 1'b1;                                        // ★复位值 1★
      allow_enq_dispatch_q <= 1'b1;                                        // ★复位值 1★
    end else begin
      // ---- 队尾指针：6 份 value 各自 = enqPtrNext + i，只有 head 有 flag ----
      enq_ptr_flag_q <= enq_ptr_next.flag;
      for (int i = 0; i < RENAME_W; i++)
        enq_ptr_value_q[i] <= PTR_W'(enq_ptr_next.value + PTR_W'(i));

      // ---- 队头指针：6 份 value + 6 份 flag（flag 是 dontTouch 保下来的）----
      for (int i = 0; i < COMMIT_W; i++) begin
        deq_ptr_flag_q[i]  <= deq_ptr_vec_next[i].flag;
        deq_ptr_value_q[i] <= deq_ptr_vec_next[i].value;
      end
      deq_ptr_oh_q <= deq_ptr_oh_rot[deq_ptr_steps];

      // ---- 状态与三个计数 ----
      if (redirect_valid) begin
        state_q     <= snpt_use ? S_WALK : S_SPECIAL_WALK;
        walk_size_q <= '0;
      end else begin
        state_q     <= state_next;
        walk_size_q <= walk_size_nxt;
      end
      rob_walk_end_q <= ~redirect_valid & (rob_walk_end | rob_walk_end_q);
      commit_size_q  <= (redirect_valid & ~snpt_use) ? SIZE_W'(0) : commit_size_nxt;
      special_walk_size_q <= special_walk_size_nxt;

      // ---- 水位打拍。阈值实测：size-RenameWidth=250、size-2*RenameWidth=244 ----
      allow_enq_q          <= (occupancy_next < (PTR_W+1)'(RAB_SIZE - RENAME_W + 1));
      allow_enq_dispatch_q <= (occupancy_next < (PTR_W+1)'(RAB_SIZE - 2*RENAME_W + 1));
    end
  end

  // ===========================================================================
  // §10 无复位域（golden 第三个 always 块，没有 reset 臂）
  // ===========================================================================
  always_ff @(posedge clock) begin
    // ---- 回滚指针 ----
    walk_ptr_q <= walk_ptr_next;

    // ---- 256 项缓冲表。★写端口优先级：w 升序覆盖写 ⇒ 末位 req[5] 胜★
    //      与 golden 的 if(req5) else if(req4) … else if(req0) 链同义（见文件头第 5 条）。
    for (int w = 0; w < RENAME_W; w++)
      if (real_need_alloc[w]) buffer_q[alloc_ptr[w]] <= req[w].info;

    // ---- 向量访存异常标志 ----
    // 优先级：redirect 且 useSnpt → **保持**（golden 的空 then 分支）；
    //         redirect 且 !useSnpt → 收 Rob 的值；否则 s_special_walk 末拍清 0。
    if (redirect_valid) begin
      if (~snpt_use) vec_load_excp_valid_q <= rob_vec_load_excp_valid;
    end else begin
      vec_load_excp_valid_q <=
          ~((state_q == S_SPECIAL_WALK) & special_walk_end_next) & vec_load_excp_valid_q;
    end

    // ---- 送 VecExcpMod 的映射打一拍（valid 无条件打拍，数据带使能）----
    for (int i = 0; i < COMMIT_W; i++) begin
      vec_excp_valid_q[i] <= vec_excp_fire[i];
      if (vec_excp_fire[i]) begin
        vec_excp_lreg_q[i] <= commits_info[i].ldest;
        vec_excp_preg_q[i] <= commits_info[i].pdest;
      end
    end
  end

  // ===========================================================================
  // §11 设计不变量（仅仿真；与 golden 的两条 XSError 同义）
  // ===========================================================================
  // FM 与 UT 两侧都带 +define+SYNTHESIS，本块不参与任何判定。
`ifndef SYNTHESIS
  always @(posedge clock) begin
    if (~reset && ((RAB_SIZE'(1) << deq_ptr_value_q[0]) != deq_ptr_oh_q))
      $fwrite(32'h80000002, "RenameBuffer: deqPtr and its one-hot shadow diverged\n");
    // isBefore(enqPtr, deqPtr) && !isFull(enqPtr, deqPtr) —— 队尾跑到队头后面了
    if (~reset
        && ((enq_ptr_flag_q ^ deq_ptr_flag_q[0]
             ^ (enq_ptr_value_q[0] < deq_ptr_value_q[0]))
            && !((enq_ptr_flag_q != deq_ptr_flag_q[0])
                 && (enq_ptr_value_q[0] == deq_ptr_value_q[0]))))
      $fwrite(32'h80000002, "RenameBuffer: deqPtr is older than enqPtr\n");
  end
`endif

endmodule

// BEGIN GENERATED(renamebuffer-wrapper)
// 本区由 scripts/gen_renamebuffer.py 从 G1 golden 的端口表生成，请勿手改。
// -----------------------------------------------------------------------------
// golden 同名 wrapper：端口逐位与 G1 golden 同名同序；内部只做
//   (1) 展平信号 ↔ 可读核 struct 的打包/拆包；
//   (2) 例化子模块 SnapshotGenerator（实例名与 golden 一致）。
// -----------------------------------------------------------------------------
module RenameBuffer (
  input        clock,
  input        reset,
  input        io_redirect_valid,
  input        io_req_0_valid,
  input  [5:0] io_req_0_bits_ldest,
  input        io_req_0_bits_rfWen,
  input        io_req_0_bits_fpWen,
  input        io_req_0_bits_vecWen,
  input        io_req_0_bits_v0Wen,
  input        io_req_0_bits_vlWen,
  input        io_req_0_bits_isMove,
  input  [7:0] io_req_0_bits_pdest,
  input        io_req_1_valid,
  input  [5:0] io_req_1_bits_ldest,
  input        io_req_1_bits_rfWen,
  input        io_req_1_bits_fpWen,
  input        io_req_1_bits_vecWen,
  input        io_req_1_bits_v0Wen,
  input        io_req_1_bits_vlWen,
  input        io_req_1_bits_isMove,
  input  [7:0] io_req_1_bits_pdest,
  input        io_req_2_valid,
  input  [5:0] io_req_2_bits_ldest,
  input        io_req_2_bits_rfWen,
  input        io_req_2_bits_fpWen,
  input        io_req_2_bits_vecWen,
  input        io_req_2_bits_v0Wen,
  input        io_req_2_bits_vlWen,
  input        io_req_2_bits_isMove,
  input  [7:0] io_req_2_bits_pdest,
  input        io_req_3_valid,
  input  [5:0] io_req_3_bits_ldest,
  input        io_req_3_bits_rfWen,
  input        io_req_3_bits_fpWen,
  input        io_req_3_bits_vecWen,
  input        io_req_3_bits_v0Wen,
  input        io_req_3_bits_vlWen,
  input        io_req_3_bits_isMove,
  input  [7:0] io_req_3_bits_pdest,
  input        io_req_4_valid,
  input  [5:0] io_req_4_bits_ldest,
  input        io_req_4_bits_rfWen,
  input        io_req_4_bits_fpWen,
  input        io_req_4_bits_vecWen,
  input        io_req_4_bits_v0Wen,
  input        io_req_4_bits_vlWen,
  input        io_req_4_bits_isMove,
  input  [7:0] io_req_4_bits_pdest,
  input        io_req_5_valid,
  input  [5:0] io_req_5_bits_ldest,
  input        io_req_5_bits_rfWen,
  input        io_req_5_bits_fpWen,
  input        io_req_5_bits_vecWen,
  input        io_req_5_bits_v0Wen,
  input        io_req_5_bits_vlWen,
  input        io_req_5_bits_isMove,
  input  [7:0] io_req_5_bits_pdest,
  input  [7:0] io_fromRob_walkSize,
  input        io_fromRob_walkEnd,
  input  [7:0] io_fromRob_commitSize,
  input        io_fromRob_vecLoadExcp_valid,
  input        io_snpt_snptEnq,
  input        io_snpt_snptDeq,
  input        io_snpt_useSnpt,
  input  [1:0] io_snpt_snptSelect,
  input        io_snpt_flushVec_0,
  input        io_snpt_flushVec_1,
  input        io_snpt_flushVec_2,
  input        io_snpt_flushVec_3,
  output       io_canEnq,
  output       io_canEnqForDispatch,
  output       io_commits_isCommit,
  output       io_commits_commitValid_0,
  output       io_commits_commitValid_1,
  output       io_commits_commitValid_2,
  output       io_commits_commitValid_3,
  output       io_commits_commitValid_4,
  output       io_commits_commitValid_5,
  output       io_commits_isWalk,
  output       io_commits_walkValid_0,
  output       io_commits_walkValid_1,
  output       io_commits_walkValid_2,
  output       io_commits_walkValid_3,
  output       io_commits_walkValid_4,
  output       io_commits_walkValid_5,
  output [5:0] io_commits_info_0_ldest,
  output [7:0] io_commits_info_0_pdest,
  output       io_commits_info_0_rfWen,
  output       io_commits_info_0_fpWen,
  output       io_commits_info_0_vecWen,
  output       io_commits_info_0_v0Wen,
  output       io_commits_info_0_vlWen,
  output       io_commits_info_0_isMove,
  output [5:0] io_commits_info_1_ldest,
  output [7:0] io_commits_info_1_pdest,
  output       io_commits_info_1_rfWen,
  output       io_commits_info_1_fpWen,
  output       io_commits_info_1_vecWen,
  output       io_commits_info_1_v0Wen,
  output       io_commits_info_1_vlWen,
  output       io_commits_info_1_isMove,
  output [5:0] io_commits_info_2_ldest,
  output [7:0] io_commits_info_2_pdest,
  output       io_commits_info_2_rfWen,
  output       io_commits_info_2_fpWen,
  output       io_commits_info_2_vecWen,
  output       io_commits_info_2_v0Wen,
  output       io_commits_info_2_vlWen,
  output       io_commits_info_2_isMove,
  output [5:0] io_commits_info_3_ldest,
  output [7:0] io_commits_info_3_pdest,
  output       io_commits_info_3_rfWen,
  output       io_commits_info_3_fpWen,
  output       io_commits_info_3_vecWen,
  output       io_commits_info_3_v0Wen,
  output       io_commits_info_3_vlWen,
  output       io_commits_info_3_isMove,
  output [5:0] io_commits_info_4_ldest,
  output [7:0] io_commits_info_4_pdest,
  output       io_commits_info_4_rfWen,
  output       io_commits_info_4_fpWen,
  output       io_commits_info_4_vecWen,
  output       io_commits_info_4_v0Wen,
  output       io_commits_info_4_vlWen,
  output       io_commits_info_4_isMove,
  output [5:0] io_commits_info_5_ldest,
  output [7:0] io_commits_info_5_pdest,
  output       io_commits_info_5_rfWen,
  output       io_commits_info_5_fpWen,
  output       io_commits_info_5_vecWen,
  output       io_commits_info_5_v0Wen,
  output       io_commits_info_5_vlWen,
  output       io_commits_info_5_isMove,
  output       io_status_walkEnd,
  output       io_status_commitEnd,
  output       io_toVecExcpMod_logicPhyRegMap_0_valid,
  output [5:0] io_toVecExcpMod_logicPhyRegMap_0_bits_lreg,
  output [6:0] io_toVecExcpMod_logicPhyRegMap_0_bits_preg,
  output       io_toVecExcpMod_logicPhyRegMap_1_valid,
  output [5:0] io_toVecExcpMod_logicPhyRegMap_1_bits_lreg,
  output [6:0] io_toVecExcpMod_logicPhyRegMap_1_bits_preg,
  output       io_toVecExcpMod_logicPhyRegMap_2_valid,
  output [5:0] io_toVecExcpMod_logicPhyRegMap_2_bits_lreg,
  output [6:0] io_toVecExcpMod_logicPhyRegMap_2_bits_preg,
  output       io_toVecExcpMod_logicPhyRegMap_3_valid,
  output [5:0] io_toVecExcpMod_logicPhyRegMap_3_bits_lreg,
  output [6:0] io_toVecExcpMod_logicPhyRegMap_3_bits_preg,
  output       io_toVecExcpMod_logicPhyRegMap_4_valid,
  output [5:0] io_toVecExcpMod_logicPhyRegMap_4_bits_lreg,
  output [6:0] io_toVecExcpMod_logicPhyRegMap_4_bits_preg,
  output       io_toVecExcpMod_logicPhyRegMap_5_valid,
  output [5:0] io_toVecExcpMod_logicPhyRegMap_5_bits_lreg,
  output [6:0] io_toVecExcpMod_logicPhyRegMap_5_bits_preg
);

  import renamebuffer_pkg::*;

  // ---- 可读核侧的结构化信号 ----
  rab_req_t  core_req          [RENAME_W];
  rab_info_t core_commits_info [COMMIT_W];
  logic [COMMIT_W-1:0] core_commit_valid;
  logic [COMMIT_W-1:0] core_walk_valid;
  logic                    core_vec_excp_valid [COMMIT_W];
  logic [LDEST_W-1:0]      core_vec_excp_lreg  [COMMIT_W];
  logic [VEXCP_PREG_W-1:0] core_vec_excp_preg  [COMMIT_W];
  rab_ptr_t  core_snapshot_enq_data;
  rab_ptr_t  core_snapshots [SNPT_NUM];
  logic               snapshot_flag  [SNPT_NUM];
  logic [PTR_W-1:0]   snapshot_value [SNPT_NUM];

  // ---- rename 请求：展平信号 → struct ----
  assign core_req[0].valid       = io_req_0_valid;
  assign core_req[0].info.ldest  = io_req_0_bits_ldest;
  assign core_req[0].info.pdest  = io_req_0_bits_pdest;
  assign core_req[0].info.rfWen  = io_req_0_bits_rfWen;
  assign core_req[0].info.fpWen  = io_req_0_bits_fpWen;
  assign core_req[0].info.vecWen = io_req_0_bits_vecWen;
  assign core_req[0].info.v0Wen  = io_req_0_bits_v0Wen;
  assign core_req[0].info.vlWen  = io_req_0_bits_vlWen;
  assign core_req[0].info.isMove = io_req_0_bits_isMove;
  assign core_req[1].valid       = io_req_1_valid;
  assign core_req[1].info.ldest  = io_req_1_bits_ldest;
  assign core_req[1].info.pdest  = io_req_1_bits_pdest;
  assign core_req[1].info.rfWen  = io_req_1_bits_rfWen;
  assign core_req[1].info.fpWen  = io_req_1_bits_fpWen;
  assign core_req[1].info.vecWen = io_req_1_bits_vecWen;
  assign core_req[1].info.v0Wen  = io_req_1_bits_v0Wen;
  assign core_req[1].info.vlWen  = io_req_1_bits_vlWen;
  assign core_req[1].info.isMove = io_req_1_bits_isMove;
  assign core_req[2].valid       = io_req_2_valid;
  assign core_req[2].info.ldest  = io_req_2_bits_ldest;
  assign core_req[2].info.pdest  = io_req_2_bits_pdest;
  assign core_req[2].info.rfWen  = io_req_2_bits_rfWen;
  assign core_req[2].info.fpWen  = io_req_2_bits_fpWen;
  assign core_req[2].info.vecWen = io_req_2_bits_vecWen;
  assign core_req[2].info.v0Wen  = io_req_2_bits_v0Wen;
  assign core_req[2].info.vlWen  = io_req_2_bits_vlWen;
  assign core_req[2].info.isMove = io_req_2_bits_isMove;
  assign core_req[3].valid       = io_req_3_valid;
  assign core_req[3].info.ldest  = io_req_3_bits_ldest;
  assign core_req[3].info.pdest  = io_req_3_bits_pdest;
  assign core_req[3].info.rfWen  = io_req_3_bits_rfWen;
  assign core_req[3].info.fpWen  = io_req_3_bits_fpWen;
  assign core_req[3].info.vecWen = io_req_3_bits_vecWen;
  assign core_req[3].info.v0Wen  = io_req_3_bits_v0Wen;
  assign core_req[3].info.vlWen  = io_req_3_bits_vlWen;
  assign core_req[3].info.isMove = io_req_3_bits_isMove;
  assign core_req[4].valid       = io_req_4_valid;
  assign core_req[4].info.ldest  = io_req_4_bits_ldest;
  assign core_req[4].info.pdest  = io_req_4_bits_pdest;
  assign core_req[4].info.rfWen  = io_req_4_bits_rfWen;
  assign core_req[4].info.fpWen  = io_req_4_bits_fpWen;
  assign core_req[4].info.vecWen = io_req_4_bits_vecWen;
  assign core_req[4].info.v0Wen  = io_req_4_bits_v0Wen;
  assign core_req[4].info.vlWen  = io_req_4_bits_vlWen;
  assign core_req[4].info.isMove = io_req_4_bits_isMove;
  assign core_req[5].valid       = io_req_5_valid;
  assign core_req[5].info.ldest  = io_req_5_bits_ldest;
  assign core_req[5].info.pdest  = io_req_5_bits_pdest;
  assign core_req[5].info.rfWen  = io_req_5_bits_rfWen;
  assign core_req[5].info.fpWen  = io_req_5_bits_fpWen;
  assign core_req[5].info.vecWen = io_req_5_bits_vecWen;
  assign core_req[5].info.v0Wen  = io_req_5_bits_v0Wen;
  assign core_req[5].info.vlWen  = io_req_5_bits_vlWen;
  assign core_req[5].info.isMove = io_req_5_bits_isMove;

  // ---- 子模块：4 槽快照队列（实例名与 golden 一致，便于 FM 对层次）----
  SnapshotGenerator walkPtrSnapshots_snapshotGen (
    .clock                (clock),
    .reset                (reset),
    .io_enq               (io_snpt_snptEnq),
    .io_enqData_flag      (core_snapshot_enq_data.flag),
    .io_enqData_value     (core_snapshot_enq_data.value),
    .io_deq               (io_snpt_snptDeq),
    .io_redirect          (io_redirect_valid),
    .io_flushVec_0        (io_snpt_flushVec_0),
    .io_flushVec_1        (io_snpt_flushVec_1),
    .io_flushVec_2        (io_snpt_flushVec_2),
    .io_flushVec_3        (io_snpt_flushVec_3),
    .io_snapshots_0_flag  (snapshot_flag[0]),
    .io_snapshots_0_value (snapshot_value[0]),
    .io_snapshots_1_flag  (snapshot_flag[1]),
    .io_snapshots_1_value (snapshot_value[1]),
    .io_snapshots_2_flag  (snapshot_flag[2]),
    .io_snapshots_2_value (snapshot_value[2]),
    .io_snapshots_3_flag  (snapshot_flag[3]),
    .io_snapshots_3_value (snapshot_value[3])
  );

  always_comb
    for (int i = 0; i < SNPT_NUM; i++)
      core_snapshots[i] = '{flag: snapshot_flag[i], value: snapshot_value[i]};

  // ---- 可读核 ----
  xs_RenameBuffer_core u_core (
    .clock                   (clock),
    .reset                   (reset),
    .redirect_valid          (io_redirect_valid),
    .req                     (core_req),
    .rob_commit_size         (io_fromRob_commitSize),
    .rob_walk_size           (io_fromRob_walkSize),
    .rob_walk_end            (io_fromRob_walkEnd),
    .rob_vec_load_excp_valid (io_fromRob_vecLoadExcp_valid),
    .snpt_enq                (io_snpt_snptEnq),
    .snpt_deq                (io_snpt_snptDeq),
    .snpt_use                (io_snpt_useSnpt),
    .snpt_select             (io_snpt_snptSelect),
    .snpt_flush_vec          ({io_snpt_flushVec_3, io_snpt_flushVec_2,
                               io_snpt_flushVec_1, io_snpt_flushVec_0}),
    .can_enq                 (io_canEnq),
    .can_enq_for_dispatch    (io_canEnqForDispatch),
    .commits_is_commit       (io_commits_isCommit),
    .commits_commit_valid    (core_commit_valid),
    .commits_is_walk         (io_commits_isWalk),
    .commits_walk_valid      (core_walk_valid),
    .commits_info            (core_commits_info),
    .status_walk_end         (io_status_walkEnd),
    .status_commit_end       (io_status_commitEnd),
    .vec_excp_valid          (core_vec_excp_valid),
    .vec_excp_lreg           (core_vec_excp_lreg),
    .vec_excp_preg           (core_vec_excp_preg),
    .snapshot_enq_data       (core_snapshot_enq_data),
    .snapshots               (core_snapshots)
  );

  // ---- 输出：struct → 展平信号 ----
  assign io_commits_commitValid_0 = core_commit_valid[0];
  assign io_commits_commitValid_1 = core_commit_valid[1];
  assign io_commits_commitValid_2 = core_commit_valid[2];
  assign io_commits_commitValid_3 = core_commit_valid[3];
  assign io_commits_commitValid_4 = core_commit_valid[4];
  assign io_commits_commitValid_5 = core_commit_valid[5];
  assign io_commits_walkValid_0   = core_walk_valid[0];
  assign io_commits_walkValid_1   = core_walk_valid[1];
  assign io_commits_walkValid_2   = core_walk_valid[2];
  assign io_commits_walkValid_3   = core_walk_valid[3];
  assign io_commits_walkValid_4   = core_walk_valid[4];
  assign io_commits_walkValid_5   = core_walk_valid[5];
  assign io_commits_info_0_ldest  = core_commits_info[0].ldest;
  assign io_commits_info_0_pdest  = core_commits_info[0].pdest;
  assign io_commits_info_0_rfWen  = core_commits_info[0].rfWen;
  assign io_commits_info_0_fpWen  = core_commits_info[0].fpWen;
  assign io_commits_info_0_vecWen = core_commits_info[0].vecWen;
  assign io_commits_info_0_v0Wen  = core_commits_info[0].v0Wen;
  assign io_commits_info_0_vlWen  = core_commits_info[0].vlWen;
  assign io_commits_info_0_isMove = core_commits_info[0].isMove;
  assign io_commits_info_1_ldest  = core_commits_info[1].ldest;
  assign io_commits_info_1_pdest  = core_commits_info[1].pdest;
  assign io_commits_info_1_rfWen  = core_commits_info[1].rfWen;
  assign io_commits_info_1_fpWen  = core_commits_info[1].fpWen;
  assign io_commits_info_1_vecWen = core_commits_info[1].vecWen;
  assign io_commits_info_1_v0Wen  = core_commits_info[1].v0Wen;
  assign io_commits_info_1_vlWen  = core_commits_info[1].vlWen;
  assign io_commits_info_1_isMove = core_commits_info[1].isMove;
  assign io_commits_info_2_ldest  = core_commits_info[2].ldest;
  assign io_commits_info_2_pdest  = core_commits_info[2].pdest;
  assign io_commits_info_2_rfWen  = core_commits_info[2].rfWen;
  assign io_commits_info_2_fpWen  = core_commits_info[2].fpWen;
  assign io_commits_info_2_vecWen = core_commits_info[2].vecWen;
  assign io_commits_info_2_v0Wen  = core_commits_info[2].v0Wen;
  assign io_commits_info_2_vlWen  = core_commits_info[2].vlWen;
  assign io_commits_info_2_isMove = core_commits_info[2].isMove;
  assign io_commits_info_3_ldest  = core_commits_info[3].ldest;
  assign io_commits_info_3_pdest  = core_commits_info[3].pdest;
  assign io_commits_info_3_rfWen  = core_commits_info[3].rfWen;
  assign io_commits_info_3_fpWen  = core_commits_info[3].fpWen;
  assign io_commits_info_3_vecWen = core_commits_info[3].vecWen;
  assign io_commits_info_3_v0Wen  = core_commits_info[3].v0Wen;
  assign io_commits_info_3_vlWen  = core_commits_info[3].vlWen;
  assign io_commits_info_3_isMove = core_commits_info[3].isMove;
  assign io_commits_info_4_ldest  = core_commits_info[4].ldest;
  assign io_commits_info_4_pdest  = core_commits_info[4].pdest;
  assign io_commits_info_4_rfWen  = core_commits_info[4].rfWen;
  assign io_commits_info_4_fpWen  = core_commits_info[4].fpWen;
  assign io_commits_info_4_vecWen = core_commits_info[4].vecWen;
  assign io_commits_info_4_v0Wen  = core_commits_info[4].v0Wen;
  assign io_commits_info_4_vlWen  = core_commits_info[4].vlWen;
  assign io_commits_info_4_isMove = core_commits_info[4].isMove;
  assign io_commits_info_5_ldest  = core_commits_info[5].ldest;
  assign io_commits_info_5_pdest  = core_commits_info[5].pdest;
  assign io_commits_info_5_rfWen  = core_commits_info[5].rfWen;
  assign io_commits_info_5_fpWen  = core_commits_info[5].fpWen;
  assign io_commits_info_5_vecWen = core_commits_info[5].vecWen;
  assign io_commits_info_5_v0Wen  = core_commits_info[5].v0Wen;
  assign io_commits_info_5_vlWen  = core_commits_info[5].vlWen;
  assign io_commits_info_5_isMove = core_commits_info[5].isMove;
  assign io_toVecExcpMod_logicPhyRegMap_0_valid     = core_vec_excp_valid[0];
  assign io_toVecExcpMod_logicPhyRegMap_0_bits_lreg = core_vec_excp_lreg[0];
  assign io_toVecExcpMod_logicPhyRegMap_0_bits_preg = core_vec_excp_preg[0];
  assign io_toVecExcpMod_logicPhyRegMap_1_valid     = core_vec_excp_valid[1];
  assign io_toVecExcpMod_logicPhyRegMap_1_bits_lreg = core_vec_excp_lreg[1];
  assign io_toVecExcpMod_logicPhyRegMap_1_bits_preg = core_vec_excp_preg[1];
  assign io_toVecExcpMod_logicPhyRegMap_2_valid     = core_vec_excp_valid[2];
  assign io_toVecExcpMod_logicPhyRegMap_2_bits_lreg = core_vec_excp_lreg[2];
  assign io_toVecExcpMod_logicPhyRegMap_2_bits_preg = core_vec_excp_preg[2];
  assign io_toVecExcpMod_logicPhyRegMap_3_valid     = core_vec_excp_valid[3];
  assign io_toVecExcpMod_logicPhyRegMap_3_bits_lreg = core_vec_excp_lreg[3];
  assign io_toVecExcpMod_logicPhyRegMap_3_bits_preg = core_vec_excp_preg[3];
  assign io_toVecExcpMod_logicPhyRegMap_4_valid     = core_vec_excp_valid[4];
  assign io_toVecExcpMod_logicPhyRegMap_4_bits_lreg = core_vec_excp_lreg[4];
  assign io_toVecExcpMod_logicPhyRegMap_4_bits_preg = core_vec_excp_preg[4];
  assign io_toVecExcpMod_logicPhyRegMap_5_valid     = core_vec_excp_valid[5];
  assign io_toVecExcpMod_logicPhyRegMap_5_bits_lreg = core_vec_excp_lreg[5];
  assign io_toVecExcpMod_logicPhyRegMap_5_bits_preg = core_vec_excp_preg[5];

endmodule
// END GENERATED
