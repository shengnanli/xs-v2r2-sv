// =============================================================================
// AgeDetector_38 —— LoadQueueReplay 的「最老可重放条目」选择器（24 项 × 3 入队口）
//
// 对应 Chisel: xiangshan.mem.AgeDetector（LoadQueueReplay.scala:93，注意这是
// LoadQueueReplay 私有的那一个，**不是** backend/issue/AgeDetector.scala 里
// 同名的发射队列版本 —— 那一版端口是 enq/canIssue/out，语义也不同）。
// golden 家族里 AgeDetector / _1 / _8 / _9 / _12 / _13 / _15 / _19 / _21 都是
// 发射队列版本，只有 _38 是本版本，所以本文件不设家族参数化核。
//
// 用途：LoadQueueReplay 把 72 个重放条目按 load 流水线口分成 3 组、每组 24 项，
// 每组配一个本模块。它在"本拍可以重放"的候选里挑出**入队最早**的那一个。
//
// 端口（numEntries=24, numEnq=3, regOut=true）：
//   io_enq_0/1/2  每个入队口的 one-hot 位图：本拍该口往哪个条目写入（至多 1 位）
//   io_deq        本拍被释放/冲刷掉的条目位图（Chisel 里叫 deq，实参是 freeSel）
//   io_ready      本拍有资格重放的条目位图
//   io_out        选中的最老条目 one-hot（若没有候选则全 0）
//
// 核心机制 —— 年龄矩阵：
//   age[i][j] = "条目 i 比条目 j 先进队"。只存上三角（含对角线），下三角取反：
//     get_age(i,j) = i<=j ? age[i][j] : !age[j][i]
//   对角线 age[i][i] 被复用成"条目 i 当前有效"（进队置 1、出队清 0），
//   所以 thisValid(i) = age[i][i] | 本拍 i 进队。
//   次态按四条互斥规则（优先级从上到下，来自 Chisel 的 when/elsewhen 链）：
//     (1) 条目 i 本拍出队      → age[i][j] = 0        （整行清掉）
//     (2) 条目 j 本拍出队      → age[i][j] = thisValid(i) （整列置成 i 的有效位）
//     (3) 条目 i 本拍进队      → age[i][j] = !age[j][j] && !(j 从更靠前的口进队)
//     (4) 否则保持
//   规则 (3) 决定了**同拍多口进队时谁算更老：口号小的更老**。
//   （isEnqueued(j,k) 只看前 k 个口；k=0 恒为 false，所以 0 号口进来的条目
//     不会被任何同拍条目判为"更早"。）
//
// 选择：out[i] = ready[i] & ∀j≠i: (!ready[j] | get_age(i,j))
//   即 i 有资格，且对每个同样有资格的 j，i 都不比 j 晚。out 是组合输出
//   （regOut=true 只表示用**当前**的 age 寄存器而不是次态 nextAge 去选）。
//
// 复位域：300 个 age 寄存器（上三角 24+23+...+1）全部 RegInit(false.B)，
// golden 是 `always @(posedge clock or posedge reset)` 并在 reset 分支里全清 0。
// 本模块**没有**不复位寄存器（与同批的 FreeList_5 / LqVAddrModule 不同）。
// =============================================================================
package agedetector38_pkg;

  localparam int NUM_ENTRIES = 24;  // 每组条目数 = LoadQueueReplaySize / LoadPipelineWidth
  localparam int NUM_ENQ     = 3;   // 入队口数 = LoadPipelineWidth
  // 只有上三角（含对角线）真的存成寄存器：24+23+...+1 = 300，与 golden 的
  // 300 个 age_i_j 寄存器逐个对应。Chisel 声明了整个 24×24 方阵，下三角从不
  // 被读（get_age 对 i>j 走 !age[j][i]），firtool 把它们 DCE 掉了。
  localparam int NUM_AGE     = NUM_ENTRIES * (NUM_ENTRIES + 1) / 2;  // 300

endpackage

// -----------------------------------------------------------------------------
// xs_AgeDetector_38_core —— 可读核
// -----------------------------------------------------------------------------
module xs_AgeDetector_38_core
  import agedetector38_pkg::*;
(
  input  logic                   clock,
  input  logic                   reset,
  input  logic [NUM_ENTRIES-1:0] io_enq [NUM_ENQ], // 各入队口的 one-hot 写位图
  input  logic [NUM_ENTRIES-1:0] io_deq,           // 本拍被释放的条目
  input  logic [NUM_ENTRIES-1:0] io_ready,         // 本拍有资格重放的条目
  output logic [NUM_ENTRIES-1:0] io_out            // 选中的最老条目 one-hot
);

  // ===========================================================================
  // 1. 年龄矩阵（只存上三角，含对角线）
  // ===========================================================================
  // 上三角按行紧凑存放：第 row 行起点 = row*N - row*(row-1)/2，行内偏移 col-row。
  // 只接受 row <= col。
  function automatic int age_idx(input int row, input int col);
    return row * NUM_ENTRIES - row * (row - 1) / 2 + (col - row);
  endfunction

  logic age [NUM_AGE];

  // ageFull[i][j]：完整 24×24 的"条目 i 不晚于条目 j"矩阵（即 Chisel 的 get_age）。
  //   i <= j 直接取寄存器；i > j 取对称位的反。对角线 ageFull[i][i] = age[i][i]，
  //   也就是被复用成"条目 i 当前有效"的那一位。
  // ★ 这里刻意**不写成 function**：函数体若读模块级的 age，Formality 报
  //   FMR_VLOG-091（Using non-local variable 'age' in task/function），并在
  //   set_top 处直接失败（FM-262 → FM-156）；本仓 CONVENTIONS 也早有同一条告诫
  //   （generate/function 捕获模块级信号，仿真会返 X）。age_idx 只吃 int 参数、
  //   不碰模块信号，可以留作函数。
  logic ageFull [NUM_ENTRIES][NUM_ENTRIES];
  always_comb
    for (int i = 0; i < NUM_ENTRIES; i++)
      for (int j = 0; j < NUM_ENTRIES; j++)
        ageFull[i][j] = (i <= j) ? age[age_idx(i, j)] : ~age[age_idx(j, i)];

  // ===========================================================================
  // 2. 每个条目的进队/出队/有效
  // ===========================================================================
  // isEnqueued(i)：条目 i 本拍从任一口进队，且没有同拍被释放。
  logic [NUM_ENTRIES-1:0] isEnqueued;
  // enqFromLowerPorts[i][k]：条目 i 本拍从 0..k-1 号口中的某一个进队（k=0 恒为 0），
  // 且没有同拍被释放 —— 对应 Chisel 的 isEnqueued(i, k)。
  // 它就是规则 (3) 里"j 从更靠前的口进队"的判据。
  logic enqFromLowerPorts [NUM_ENTRIES][NUM_ENQ];
  // thisValid(i)：条目 i 在次态里是否有效 = 已有效 或 本拍进队
  logic [NUM_ENTRIES-1:0] thisValid;

  always_comb begin
    for (int i = 0; i < NUM_ENTRIES; i++) begin
      logic anyEnq;
      anyEnq = 1'b0;
      for (int k = 0; k < NUM_ENQ; k++) anyEnq |= io_enq[k][i];
      isEnqueued[i] = anyEnq & ~io_deq[i];
      thisValid[i]  = ageFull[i][i] | isEnqueued[i];

      for (int k = 0; k < NUM_ENQ; k++) begin
        logic lower;
        lower = 1'b0;
        for (int q = 0; q < k; q++) lower |= io_enq[q][i];
        // k=0 时循环体不执行 ⇒ 恒 0，对应 Chisel 的 `case 0 => false.B`
        enqFromLowerPorts[i][k] = lower & ~io_deq[i];
      end
    end
  end

  // ===========================================================================
  // 3. 次态
  // ===========================================================================
  // 只对真的存了寄存器的上三角算次态（下三角在 golden 里也不存在）。
  logic nextAge [NUM_AGE];
  always_comb
    for (int i = 0; i < NUM_ENTRIES; i++)
      for (int j = i; j < NUM_ENTRIES; j++) begin
        logic beatenByEarlierPort;
        // ParallelMux(sel = 本条目 i 从哪个口进来, result = j 是否从更靠前的口进来)。
        // enq 是 one-hot，所以"或"等价于选择。
        beatenByEarlierPort = 1'b0;
        for (int k = 0; k < NUM_ENQ; k++)
          beatenByEarlierPort |= io_enq[k][i] & enqFromLowerPorts[j][k];

        if (io_deq[i])      nextAge[age_idx(i, j)] = 1'b0;          // (1) i 出队：整行清 0
        else if (io_deq[j]) nextAge[age_idx(i, j)] = thisValid[i];  // (2) j 出队：整列 = i 的有效位
        else if (isEnqueued[i])                                     // (3) i 进队
          nextAge[age_idx(i, j)] = ~ageFull[j][j] & ~beatenByEarlierPort;
        else                nextAge[age_idx(i, j)] = ageFull[i][j];  // (4) 保持
      end

  // ===========================================================================
  // 4. 输出：在 ready 的条目里挑不比任何其他 ready 条目晚的那个
  // ===========================================================================
  always_comb
    for (int i = 0; i < NUM_ENTRIES; i++) begin
      logic oldest;
      oldest = 1'b1;
      for (int j = 0; j < NUM_ENTRIES; j++)
        if (i != j) oldest &= ~io_ready[j] | ageFull[i][j];
      io_out[i] = io_ready[i] & oldest;
    end

  // ===========================================================================
  // 5. 时序：上三角（含对角线）逐位更新，异步复位清 0
  // ===========================================================================
  always_ff @(posedge clock or posedge reset)
    if (reset) begin
      for (int k = 0; k < NUM_AGE; k++) age[k] <= 1'b0;
    end else begin
      for (int k = 0; k < NUM_AGE; k++) age[k] <= nextAge[k];
    end

endmodule

// -----------------------------------------------------------------------------
// golden 同名 wrapper —— 端口与 G1 golden 逐位对齐
// -----------------------------------------------------------------------------
module AgeDetector_38(
  input         clock,
  input         reset,
  input  [23:0] io_enq_0,
  input  [23:0] io_enq_1,
  input  [23:0] io_enq_2,
  input  [23:0] io_deq,
  input  [23:0] io_ready,
  output [23:0] io_out
);
  logic [23:0] enq [3];
  assign enq[0] = io_enq_0;
  assign enq[1] = io_enq_1;
  assign enq[2] = io_enq_2;

  xs_AgeDetector_38_core u_core (
    .clock    (clock),
    .reset    (reset),
    .io_enq   (enq),
    .io_deq   (io_deq),
    .io_ready (io_ready),
    .io_out   (io_out)
  );
endmodule
