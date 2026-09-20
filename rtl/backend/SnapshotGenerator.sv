// =============================================================================
// SnapshotGenerator.sv —— 重命名快照队列（4 个快照槽的环形队列）+ ★家族共享核★
// 设计源：XiangShan src/main/scala/xiangshan/backend/rename/Snapshot.scala
//         （class SnapshotGenerator[T], 被 Rab.scala 以 enqPtr 为 dataType 例化）
// golden 对照：G1-canonical/golden-rtl/SnapshotGenerator.sv（283 行，21 端口，真叶子）
// ★家族★ golden 里共 11 个单态化实例（SnapshotGenerator 与 _1/_2/_3/_4/_5/_6/
//   _7/_11/_12/_14）。实测（逐个 diff，去掉 payload 行后的控制逻辑逐字节比对）：
//   **11 份的控制核完全相同** —— 深度恒为 4、指针恒为 flag+2 位、flushVec 恒为 4 位，
//   连 §4 那个退化表达式的形状都一样。变的只有两处：
//     (1) 被快照的 payload 位宽（下表 DATA_W）；
//     (2) _14 额外把 enqPtr/deqPtr/valids 透出到端口（其余 10 个被 firtool 消掉了）。
//   所以本核把 payload 当**不透明的 DATA_W 位数据**（核只做搬运，不看内容），
//   各变体只写一层薄 wrapper 做端口展平。核体只此一份，见各变体文件头的指路。
//
//   变体      DATA_W  payload 形状（实测自 golden 端口表）
//   -------   ------  --------------------------------------------------
//   (base)       9    {flag, value[7:0]}            RenameBufferPtr, RabSize=256
//   _1           7    {flag, value[5:0]}
//   _2           8    {illegal, vma, vta, vsew[1:0], vlmul[2:0]}   VType
//   _3           9    Vec(1) of {flag, value[7:0]}
//   _4         256    Vec(32) of UInt(8)
//   _5         272    Vec(34) of UInt(8)
//   _6         376    Vec(47) of UInt(8)
//   _7           8    Vec(1) of UInt(8)
//   _11          8    {flag, value[6:0]}
//   _12          6    {flag, value[4:0]}
//   _14         60    Vec(6) of {flag,value[7:0]} ++ Vec(6) of Bool   (+ptr/valids 输出)
//
// 配置：KunminghuV2Config —— RenameSnapshotNum=4；本例化的数据 = RenameBufferPtr
//      （flag 1 位 + value 8 位，RabSize=256）。两者都从 golden 端口表实测。
//
// ★ 它是什么 ★
// 前端每遇到一个「可能要回滚到这里」的点（分支等），就让 rename 级把当前的
// RenameBuffer 入队指针存一份快照；分支解析确认无误就出队（丢弃），
// 猜错就靠 io_snapshots[snptSelect] 把指针一步拉回去，省掉逐条 walk。
// 本模块只管这 4 个槽的环形队列 + 失效（flush）后的指针修复。
//
// ★ 三个不显然的机制 ★
//  1. 满则丢弃，不反压：enq 在队满时被直接忽略（没有 ready 线）。
//     快照是**优化**不是正确性要求，丢了大不了退化成逐条 walk。
//  2. flushVec 可以一次作废任意子集的槽（不只是队头/队尾）。
//     作废后队列出现「空洞」，于是要重算 enqPtr —— 这就是 newEnqPtr 那段：
//     从 deqPtr 起往后找第一个「本身就无效 / 或这拍被 flush」的槽当新的队尾。
//  3. redirect 一到，enq 与 deq 两条路**同时**关掉（见 enq_fire / deq_fire 都
//     带 ~io_redirect），但 flushVec 那条路**照常生效** —— 回滚当拍就要把
//     作废的槽清掉。
//
// ★ Chisel 与 golden 不一致处（以 golden 为准）★
//  (a) Chisel 的 newEnqPtrQualified 尾部写的是
//        newEnqPtrCandidate.tail.zip(newEnqPtrCandidate.drop(1))
//      —— `.tail` 与 `.drop(1)` 是**同一个列表**，所以 `thiz` 与 `last` 恒等，
//      表达式退化成 valids(p) && (!valids(p) || flush(p)) = valids(p) && flush(p)。
//      golden 逐字保留了这个退化形式（_GEN_10 & (~_GEN_10 | _GEN_8[...])）。
//      本核照抄该形式（见 §4 的 qualified[1]/[2]），**不做代数化简**：
//      值恒等不等于可证等价，化简只会给 FM 添麻烦，读者也就看不到这个事实了。
//      注意 candidate[0] 那一项形状**不同**（是 !valids | flush），不是笔误。
//  (b) Chisel 的 io 还有 enqPtr / deqPtr / valids 三组输出端口，**本变体**的 golden
//      端口表里一个都没有 —— 父模块 Rab 只用了 io.snapshots，firtool（-O=release）
//      把没有读者的输出端口连同它的驱动一起消掉了。以 golden 端口表为准。
//      ★但家族里 SnapshotGenerator_14 的 golden 把这 8 根全留着★（它的父模块读了），
//      所以本核**无条件**把它们透出；不需要的 wrapper 直接悬空不接。
//      这不是给本变体加逻辑：snptEnqPtr/snptDeqPtr/snptValids 本来就在，
//      悬空的子模块输出端口不构成比较点（实测 base 的 FM 仍是 unread 0）。
//
// ★ 复位域（golden 两个 always 块逐个分类，实测）★
//   golden 178-222：always @(posedge clock or posedge reset) —— **异步复位**，
//     snptEnqPtr / snptDeqPtr / snptValids[4] 全部复位为 0（本模块复位值全是 0）。
//   golden 142-160：always @(posedge clock) —— **完全不复位**，
//     4 个快照槽 snapshots[i]（flag+value）只在 enq 命中本槽时写。
//     上电值随机（golden 的 `ifdef ENABLE_INITIAL_REG_ 给随机初值）。
//     照抄成「带复位」是真 bug：会凭空多 4×9=36 个复位比对点。
// =============================================================================

package snapshotgenerator_pkg;

  // ---- 规模常量。全部从 G1 golden 实测，右侧注明实测出处 ----
  localparam int SNPT_NUM   = 4;  // golden 的 io_snapshots_0..3 / snptValids_0..3
  localparam int SNPT_PTR_W = 2;  // golden 的 reg [1:0] snptEnqPtr_value
  localparam int DATA_VAL_W = 8;  // golden 的 input [7:0] io_enqData_value

  // 被快照的数据 = RenameBufferPtr（环形队列指针：flag 表示绕了奇数圈）。
  typedef struct packed {
    logic                  flag;
    logic [DATA_VAL_W-1:0] value;
  } rab_ptr_t;

  // 本模块自己的 4 项环形队列指针。
  typedef struct packed {
    logic                    flag;
    logic [SNPT_PTR_W-1:0]   value;
  } snpt_ptr_t;

endpackage

// -----------------------------------------------------------------------------
// 可读核
// -----------------------------------------------------------------------------
module xs_SnapshotGenerator_core
  import snapshotgenerator_pkg::*;
#(
  // 被快照数据的位宽。核**不解释** payload 的内部结构，只按位搬运，
  // 所以 11 个变体（9/7/8/9/256/272/376/8/8/6/60 位）共用同一份核。
  // 默认值 = base 变体的 RenameBufferPtr 宽度，各变体 wrapper 显式覆盖。
  parameter int DATA_W = $bits(rab_ptr_t)
) (
  input  logic     clock,
  input  logic     reset,        // 异步、高有效（golden: posedge reset）

  input  logic     enq,          // 请求存一份快照
  input  logic [DATA_W-1:0] enq_data,  // 要存的 payload（不透明）
  input  logic     deq,          // 队头快照作废（分支已确认）
  input  logic     redirect,     // 本拍有重定向：enq/deq 双双失效
  input  logic [SNPT_NUM-1:0] flush_vec,  // 按槽作废（可以是任意子集）

  output logic [DATA_W-1:0] snapshots [SNPT_NUM],  // 4 个槽的当前内容（无条件透出）

  // ↓ 只有 SnapshotGenerator_14 的 golden 端口表留着这三组；其余 10 个变体的
  //   wrapper 不接（firtool 在那些变体上把它们消掉了）。见文件头 (b)。
  output snpt_ptr_t           enq_ptr,
  output snpt_ptr_t           deq_ptr,
  output logic [SNPT_NUM-1:0] valids
);

  // ---------------------------------------------------------------------------
  // §1 状态寄存器
  // ---------------------------------------------------------------------------
  logic [DATA_W-1:0]    snapshots_q [SNPT_NUM];  // ★不复位★（见文件头复位域）
  snpt_ptr_t            snpt_enq_ptr_q;          // 异步复位 → 0
  snpt_ptr_t            snpt_deq_ptr_q;          // 异步复位 → 0
  logic [SNPT_NUM-1:0]  snpt_valids_q;           // 异步复位 → 0

  // ---------------------------------------------------------------------------
  // §2 队列状态与入/出队使能
  // ---------------------------------------------------------------------------
  // CircularQueuePtr 的惯例：value 相同而 flag 不同 = 满；两者都相同 = 空。
  logic full, empty;
  assign full  = (snpt_enq_ptr_q.flag != snpt_deq_ptr_q.flag)
               & (snpt_enq_ptr_q.value == snpt_deq_ptr_q.value);
  assign empty = (snpt_enq_ptr_q == snpt_deq_ptr_q);

  // 满则静默丢弃（无 ready 反压）；redirect 当拍两条路都关。
  logic enq_fire, deq_fire;
  assign enq_fire = ~redirect & ~full & enq;
  assign deq_fire = ~redirect & deq;

  // 本拍写哪个槽（one-hot）。golden 的 _GEN_0.._GEN_3。
  logic [SNPT_NUM-1:0] enq_sel;
  always_comb begin
    for (int i = 0; i < SNPT_NUM; i++)
      enq_sel[i] = enq_fire & (snpt_enq_ptr_q.value == SNPT_PTR_W'(i));
  end

  // ---------------------------------------------------------------------------
  // §3 指针自增
  // ---------------------------------------------------------------------------
  // flag 与 value 拼成一个 (1+2) 位数直接加 1：进位自然落到 flag 上。
  snpt_ptr_t enq_ptr_plus1, deq_ptr_plus1;
  assign enq_ptr_plus1 = snpt_ptr_t'((SNPT_PTR_W+1)'(snpt_enq_ptr_q) + (SNPT_PTR_W+1)'(1));
  assign deq_ptr_plus1 = snpt_ptr_t'((SNPT_PTR_W+1)'(snpt_deq_ptr_q) + (SNPT_PTR_W+1)'(1));

  // ---------------------------------------------------------------------------
  // §4 flush 之后重算队尾指针
  // ---------------------------------------------------------------------------
  // 有任何一个**当前有效**的槽被 flush，就要重算 enqPtr：从 deqPtr 开始往后扫，
  // 找第一个「合格」的位置当新队尾。
  logic any_flush_hits_valid;
  assign any_flush_hits_valid = |(flush_vec & snpt_valids_q);

  snpt_ptr_t cand [SNPT_NUM];          // deqPtr + 0 / +1 / +2 / +3
  always_comb begin
    for (int k = 0; k < SNPT_NUM; k++)
      cand[k] = snpt_ptr_t'((SNPT_PTR_W+1)'(snpt_deq_ptr_q) + (SNPT_PTR_W+1)'(k));
  end

  // ★ 形状不对称是 golden 的真实形状，不是笔误 ★（文件头 (a)）：
  //   k=0：「本来就无效 或 这拍被 flush」；
  //   k=1,2：Chisel 的 zip 写错成同一个列表，退化成「有效 且 被 flush」，
  //          这里保留 valids & (~valids | flush) 的原形，不化简。
  //   k=3 没有 qualified —— 它是 MuxCase 的默认项（都不合格就用最后一个）。
  logic qualified [SNPT_NUM-1];
  always_comb begin
    qualified[0] = ~snpt_valids_q[cand[0].value] | flush_vec[cand[0].value];
    for (int k = 1; k < SNPT_NUM-1; k++)
      qualified[k] = snpt_valids_q[cand[k].value]
                   & (~snpt_valids_q[cand[k].value] | flush_vec[cand[k].value]);
  end

  snpt_ptr_t new_enq_ptr;
  always_comb begin
    new_enq_ptr = cand[SNPT_NUM-1];                 // MuxCase 默认项
    for (int k = SNPT_NUM-2; k >= 0; k--)           // 倒着覆盖 = 低下标优先
      if (qualified[k]) new_enq_ptr = cand[k];
  end

  // ---------------------------------------------------------------------------
  // §5 主时序块 —— 异步复位域（golden 唯一的 posedge reset 块）
  // ---------------------------------------------------------------------------
  // 更新优先级（golden 实测，逐条对过）：
  //   enqPtr : flush 重算 > 入队自增 > 保持       （flush 优先级更高）
  //   deqPtr : 出队自增 > 保持                    （与 flush 无关，各写各的）
  //   valids : 清（flush 或 本拍出队指到本槽） > 置（本拍入队写本槽） > 保持
  //            —— golden 写成 ~(clr) & (set | q)，清在最外层，所以清赢。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      snpt_enq_ptr_q <= '0;
      snpt_deq_ptr_q <= '0;
      snpt_valids_q  <= '0;
    end else begin
      if (any_flush_hits_valid)      snpt_enq_ptr_q <= new_enq_ptr;
      else if (enq_fire)             snpt_enq_ptr_q <= enq_ptr_plus1;

      if (deq_fire)                  snpt_deq_ptr_q <= deq_ptr_plus1;

      for (int i = 0; i < SNPT_NUM; i++)
        snpt_valids_q[i] <=
            ~(flush_vec[i] | (deq_fire & (snpt_deq_ptr_q.value == SNPT_PTR_W'(i))))
          & (enq_sel[i] | snpt_valids_q[i]);
    end
  end

  // ---------------------------------------------------------------------------
  // §6 快照存储 —— ★无复位域★（golden 第二个 always 块没有 reset 臂）
  // ---------------------------------------------------------------------------
  // 只在「本拍入队且队尾指到本槽」时写。槽的内容在无效时是陈旧值，
  // 由 snptValids / 上游的 snptSelect 保证不会被读到。
  always_ff @(posedge clock) begin
    for (int i = 0; i < SNPT_NUM; i++)
      if (enq_sel[i]) snapshots_q[i] <= enq_data;
  end

  // ---------------------------------------------------------------------------
  // §7 输出
  // ---------------------------------------------------------------------------
  always_comb begin
    for (int i = 0; i < SNPT_NUM; i++) snapshots[i] = snapshots_q[i];
  end

  // 队列自身的状态。只有 _14 的 wrapper 接它们，其余变体悬空（见文件头 (b)）。
  assign enq_ptr = snpt_enq_ptr_q;
  assign deq_ptr = snpt_deq_ptr_q;
  assign valids  = snpt_valids_q;

  // ---------------------------------------------------------------------------
  // §8 设计不变量（仅仿真；与 golden 的 XSError 同义）
  // ---------------------------------------------------------------------------
  // golden 132-140 的 `ifndef SYNTHESIS 断言：空队列出队。
  // FM 与 UT 两侧都带 +define+SYNTHESIS，本块不参与任何判定。
`ifndef SYNTHESIS
  always @(posedge clock)
    if (~reset && deq_fire && empty)
      $fwrite(32'h80000002, "SnapshotGenerator: dequeue from empty snapshot queue\n");
`endif

endmodule

// -----------------------------------------------------------------------------
// golden 同名 wrapper：端口逐位与 G1 golden 同名同序，内部展平到可读核
// -----------------------------------------------------------------------------
module SnapshotGenerator (
  input        clock,
  input        reset,
  input        io_enq,
  input        io_enqData_flag,
  input  [7:0] io_enqData_value,
  input        io_deq,
  input        io_redirect,
  input        io_flushVec_0,
  input        io_flushVec_1,
  input        io_flushVec_2,
  input        io_flushVec_3,
  output       io_snapshots_0_flag,
  output [7:0] io_snapshots_0_value,
  output       io_snapshots_1_flag,
  output [7:0] io_snapshots_1_value,
  output       io_snapshots_2_flag,
  output [7:0] io_snapshots_2_value,
  output       io_snapshots_3_flag,
  output [7:0] io_snapshots_3_value
);

  // payload = RenameBufferPtr（rab_ptr_t），打平成 9 位总线交给核。
  localparam int DW = $bits(snapshotgenerator_pkg::rab_ptr_t);   // = 9

  snapshotgenerator_pkg::rab_ptr_t core_enq_data;
  logic [DW-1:0] core_snapshots [snapshotgenerator_pkg::SNPT_NUM];

  assign core_enq_data.flag  = io_enqData_flag;
  assign core_enq_data.value = io_enqData_value;

  xs_SnapshotGenerator_core #(.DATA_W(DW)) u_core (
    .clock     (clock),
    .reset     (reset),
    .enq       (io_enq),
    .enq_data  (core_enq_data),
    .deq       (io_deq),
    .redirect  (io_redirect),
    .flush_vec ({io_flushVec_3, io_flushVec_2, io_flushVec_1, io_flushVec_0}),
    .snapshots (core_snapshots),
    .enq_ptr   (),   // 本变体 golden 没有这三组端口（文件头 (b)）
    .deq_ptr   (),
    .valids    ()
  );

  // 打平的反向：rab_ptr_t 是 {flag, value}，flag 在高位。
  assign io_snapshots_0_flag  = core_snapshots[0][DW-1];
  assign io_snapshots_0_value = core_snapshots[0][DW-2:0];
  assign io_snapshots_1_flag  = core_snapshots[1][DW-1];
  assign io_snapshots_1_value = core_snapshots[1][DW-2:0];
  assign io_snapshots_2_flag  = core_snapshots[2][DW-1];
  assign io_snapshots_2_value = core_snapshots[2][DW-2:0];
  assign io_snapshots_3_flag  = core_snapshots[3][DW-1];
  assign io_snapshots_3_value = core_snapshots[3][DW-2:0];

endmodule
