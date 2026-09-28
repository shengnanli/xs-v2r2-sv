// xs_NewAgeDetector_core.sv —— 发射队列「入队条目区」的最老可发射选择器（家族共享参数化核）
// =============================================================================
// 对应 Chisel: xiangshan.backend.issue.NewAgeDetector
//   (src/main/scala/xiangshan/backend/issue/NewAgeDetector.scala)
// ★与 xs_AgeDetector_core（AgeDetector 家族）的区别★：
//   AgeDetector 的 enq 是"每个入队口一份 one-hot 位图"，要在同拍多口进队时按口号
//   排先后；NewAgeDetector 的 enq 是"每个**条目**一位"（Vec(numEntries, Bool)）——
//   发射队列里只有入队条目区（enqEntry，条目数 = 入队口数 = 2）用它：第 i 号入队口
//   只会写第 i 号入队条目，所以"条目 i 进队"就是"口 i 进队"，不需要位图。
//
// 位置：每个 IssueQueue* 内部一个，服务 numEnq 个入队条目。IssueQueue 把"这些入队
//   条目里哪些现在能发射"（canIssue，每个发射口一份）交给它，它挑出**入队最早**
//   的那一个，结果 out 是 one-hot（没有候选时全 0）。
//
// 核心机制 —— 上三角年龄矩阵：
//   age(i)(j) = "条目 i 比条目 j 先进队"。读取一律经 get_age：
//       get_age(i,j) = i<j ? age(i)(j) : i==j ? 1 : !age(j)(i)
//   所以只有严格上三角存成寄存器（N*(N-1)/2 个），对角线是常量 1。
//
//   次态（只对 i<j，Chisel when 链，优先级从上到下）：
//     (1) 条目 j 进队              → 1  （不管 i 同拍进没进队：同拍时口号小的 i 算更老）
//     (2) 否则条目 i 进队          → 0  （新来的 i 比老条目 j 晚）
//     (3) 否则                     → 保持
//   寄存器只在 (enq(i) | enq(j)) 时更新，所以第 (3) 条在使能下不可达 ——
//   照 Chisel 原样写出来，不合并。
//
// 选择：out(d)(i) = canIssue(d)(i) & ∀j: (get_age(i,j) | !canIssue(d)(j))
//
// 复位域：全部 age 寄存器 RegInit(false.B)，golden 是
//   `always @(posedge clock or posedge reset)` 异步复位清 0；本家族没有不复位寄存器。
//
// 家族成员（从 G1 golden 端口表量得）：
//   模块              条目 N   发射口   age 寄存器
//   NewAgeDetector       2       2          1       （2 个发射口的 IQ）
//   NewAgeDetector_6     2       1          1       （1 个发射口的 IQ）
// =============================================================================
module xs_NewAgeDetector_core #(
  parameter int NUM_ENTRIES = 2,   // 条目数（= 入队口数，每条目一位 enq）
  parameter int NUM_DEQ     = 2    // 发射口数（每口一份 canIssue / out）
) (
  input  logic                   clock,
  input  logic                   reset,
  input  logic [NUM_ENTRIES-1:0] io_enq,                 // 第 i 位 = 条目 i 本拍进队
  input  logic [NUM_ENTRIES-1:0] io_canIssue [NUM_DEQ],  // 每个发射口的候选位图
  output logic [NUM_ENTRIES-1:0] io_out      [NUM_DEQ]   // 每个发射口选中的最老条目（one-hot）
);

  // ---------------------------------------------------------------------------
  // §1 年龄矩阵：只存严格上三角，按行紧凑放进 age[NUM_AGE]
  // ---------------------------------------------------------------------------
  localparam int NUM_AGE = NUM_ENTRIES * (NUM_ENTRIES - 1) / 2;

  // 严格上三角 (row<col) 的紧凑下标：第 row 行起点 = row*N - row*(row+1)/2。
  // 只吃 int 形参、不读模块级信号（Formality FMR_VLOG-091 只禁后者）。
  function automatic int age_idx(input int row, input int col);
    return row * NUM_ENTRIES - row * (row + 1) / 2 + (col - row - 1);
  endfunction

  logic age [NUM_AGE];

  // ageFull[i][j] = Chisel 的 get_age(i,j)：完整 N×N 的"条目 i 不晚于条目 j"。
  // 刻意写成矩阵而不是读 age 的 function（FMR_VLOG-091，见 xs_AgeDetector_core）。
  logic ageFull [NUM_ENTRIES][NUM_ENTRIES];
  always_comb
    for (int i = 0; i < NUM_ENTRIES; i++)
      for (int j = 0; j < NUM_ENTRIES; j++)
        if (i < j)       ageFull[i][j] = age[age_idx(i, j)];
        else if (i == j) ageFull[i][j] = 1'b1;   // 条目永远不晚于自己（golden 里是常量）
        else             ageFull[i][j] = ~age[age_idx(j, i)];

  // ---------------------------------------------------------------------------
  // §2 次态（只算严格上三角）：j 进队 → 1；否则 i 进队 → 0；否则保持
  // ---------------------------------------------------------------------------
  logic ageNext [NUM_AGE];
  always_comb
    for (int i = 0; i < NUM_ENTRIES; i++)
      for (int j = i + 1; j < NUM_ENTRIES; j++)
        if (io_enq[j])      ageNext[age_idx(i, j)] = 1'b1;           // (1) j 新来，i 更老
        else if (io_enq[i]) ageNext[age_idx(i, j)] = 1'b0;           // (2) i 新来，i 更晚
        else                ageNext[age_idx(i, j)] = ageFull[i][j];  // (3) 保持

  // ---------------------------------------------------------------------------
  // §3 输出：每个发射口在候选里挑"不比任何其他候选晚"的那一个
  // ---------------------------------------------------------------------------
  always_comb
    for (int d = 0; d < NUM_DEQ; d++)
      for (int i = 0; i < NUM_ENTRIES; i++) begin
        logic oldest;
        oldest = 1'b1;
        for (int j = 0; j < NUM_ENTRIES; j++)
          oldest &= ageFull[i][j] | ~io_canIssue[d][j];
        io_out[d][i] = oldest & io_canIssue[d][i];
      end

  // ---------------------------------------------------------------------------
  // §4 时序：只在 i 或 j 本拍进队时更新（Chisel 的 Mux 写回 = 时钟使能），异步复位清 0
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset)
    if (reset) begin
      for (int k = 0; k < NUM_AGE; k++) age[k] <= 1'b0;
    end else begin
      for (int i = 0; i < NUM_ENTRIES; i++)
        for (int j = i + 1; j < NUM_ENTRIES; j++)
          if (io_enq[i] | io_enq[j]) age[age_idx(i, j)] <= ageNext[age_idx(i, j)];
    end

endmodule
