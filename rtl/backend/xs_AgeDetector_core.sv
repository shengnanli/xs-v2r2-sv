// xs_AgeDetector_core.sv —— 发射队列「最老可发射条目」选择器（家族共享参数化核）
// =============================================================================
// 对应 Chisel: xiangshan.backend.issue.AgeDetector
//   (src/main/scala/xiangshan/backend/issue/AgeDetector.scala)
// ★注意与 rtl/memblock/AgeDetector_38.sv 区分★：那一个是 LoadQueueReplay 私有的
//   同名类（端口 enq/deq/ready，矩阵对角线被复用成"条目有效"），**不是本家族**。
//   本家族端口是 enq/canIssue/out，没有 deq，对角线是常量 1（见 §1）。
//
// 位置：每个发射队列（IssueQueue*）内部一个。发射队列每拍把"哪些条目现在可以发射"
//   （canIssue，每个发射口一份）交给它，它在这些候选里挑出**入队最早**的那一个，
//   结果 out 是 one-hot（没有候选时全 0），直接当发射选择信号用。
//
// 核心机制 —— 年龄矩阵：
//   age(i)(j) = "条目 i 比条目 j 先进队"。Chisel 声明了整个 N×N 方阵，但读取一律
//   经 get_age：
//       get_age(i,j) = i<j ? age(i)(j) : i==j ? true : !age(j)(i)
//   于是**只有严格上三角被读**，下三角与对角线的寄存器无人读、被 firtool 整片消掉。
//   本核照此只存 N*(N-1)/2 个寄存器（见 NUM_AGE），对角线写成常量 1'b1 ——
//   这不是化简，是照抄 golden：golden 里 age_i_i 一个都不存在。
//
//   次态（只对 i<j，Chisel 的 when 链，优先级从上到下）：
//     (1) i 与 j 同拍都进队 → !ParallelMux(sel=i 从哪个口进, result=j 是否从更靠前的口进)
//         —— 即"口号小的算更老"：j 从更靠前的口进来时 age(i)(j)=0。
//     (2) 只有 i 进队       → 0   （新来的 i 比所有老条目都晚）
//     (3) 只有 j 进队       → 1   （i 早于新来的 j）
//     (4) 否则              → 保持
//   而寄存器只在 (isEnq(i) | isEnq(j)) 时才更新（Chisel 的 Mux 写回，展平成时钟使能），
//   所以第 (4) 条在使能下不可达 —— 照抄它，不许合并：FM 不做可达性分析。
//
// 选择：out(d)(i) = canIssue(d)(i) & ∀j: (get_age(i,j) | !canIssue(d)(j))
//   j==i 那一项因 get_age(i,i)=1 恒真，与 golden 里被折掉的那一位对应。
//   每个发射口 d 各算一份，彼此只差 canIssue 输入。
//
// 复位域：全部 NUM_AGE 个寄存器 RegInit(false.B)，golden 是
//   `always @(posedge clock or posedge reset)` 在 reset 臂里逐个清 0。
//   本家族**没有**不复位寄存器（9 个变体逐个数过 golden 的 reset 臂，数目 = 寄存器数）。
//
// 家族成员（参数从 G1 golden 端口表与寄存器数机械量得，不是从 Chisel 推的）：
//   模块            条目 N   入队口   发射口   age 寄存器 = N*(N-1)/2
//   AgeDetector        6       2        4          15
//   AgeDetector_1     16       2        2         120
//   AgeDetector_8      2       2        4           1
//   AgeDetector_9     14       2        2          91
//   AgeDetector_12     2       2        3           1
//   AgeDetector_13    14       2        1          91
//   AgeDetector_15    12       2        2          66
//   AgeDetector_19     6       2        1          15
//   AgeDetector_21    12       2        1          66
//   入队口全家族都是 2，所以 ParallelMux 在 golden 里塌成 ~(enq_1(i) & enq_0(j))；
//   本核仍按 numEnq 一般式写（与 Chisel 同形），numEnq=2 时展开即得该式。
// =============================================================================
module xs_AgeDetector_core #(
  parameter int NUM_ENTRIES = 6,   // 队列条目数
  parameter int NUM_ENQ     = 2,   // 入队口数（口号越小越"老"）
  parameter int NUM_DEQ     = 4    // 发射口数（每口一份 canIssue / out）
) (
  input  logic                   clock,
  input  logic                   reset,
  input  logic [NUM_ENTRIES-1:0] io_enq      [NUM_ENQ],  // 每口的 one-hot 入队位图
  input  logic [NUM_ENTRIES-1:0] io_canIssue [NUM_DEQ],  // 每个发射口的候选位图
  output logic [NUM_ENTRIES-1:0] io_out      [NUM_DEQ]   // 每个发射口选中的最老条目
);

  // ===========================================================================
  // 1. 年龄矩阵（只存严格上三角；对角线是常量，下三角取对称位的反）
  // ===========================================================================
  localparam int NUM_AGE = NUM_ENTRIES * (NUM_ENTRIES - 1) / 2;

  // 严格上三角按行紧凑存放：第 row 行起点 = row*N - row*(row+1)/2，行内偏移 col-row-1。
  // 只接受 row < col（对角线不存）。只吃 int 参数、不读模块级信号 —— Formality 的
  // FMR_VLOG-091 只禁后者，所以这个可以留作 function。
  function automatic int age_idx(input int row, input int col);
    return row * NUM_ENTRIES - row * (row + 1) / 2 + (col - row - 1);
  endfunction

  logic age [NUM_AGE];

  // ageFull[i][j] = Chisel 的 get_age(i,j)：完整 N×N 的"条目 i 不晚于条目 j"矩阵。
  // ★ 刻意**不写成 function**：函数体读模块级的 age 会触发 Formality 的
  //   FMR_VLOG-091（Using non-local variable），set_top 直接失败（FM-262 -> FM-156）；
  //   本家族的 AgeDetector_38 就是栽在这条上才改成矩阵的。
  logic ageFull [NUM_ENTRIES][NUM_ENTRIES];
  always_comb
    for (int i = 0; i < NUM_ENTRIES; i++)
      for (int j = 0; j < NUM_ENTRIES; j++)
        if (i < j)       ageFull[i][j] = age[age_idx(i, j)];
        else if (i == j) ageFull[i][j] = 1'b1;   // 条目永远不晚于自己（golden 里是常量）
        else             ageFull[i][j] = ~age[age_idx(j, i)];

  // ===========================================================================
  // 2. 入队判据
  // ===========================================================================
  // isEnq[i]           ：条目 i 本拍从任一口进队
  // enqFromLowerPorts  ：条目 i 本拍从 0..k-1 号口中的某一个进队（k=0 恒 0），
  //                      对应 Chisel 的 isEnqNport(i, k)（`case 0 => false.B`）。
  logic [NUM_ENTRIES-1:0] isEnq;
  logic enqFromLowerPorts [NUM_ENTRIES][NUM_ENQ];

  always_comb
    for (int i = 0; i < NUM_ENTRIES; i++) begin
      logic anyEnq, lower;
      anyEnq = 1'b0;
      for (int k = 0; k < NUM_ENQ; k++) anyEnq |= io_enq[k][i];
      isEnq[i] = anyEnq;

      for (int k = 0; k < NUM_ENQ; k++) begin
        lower = 1'b0;
        for (int q = 0; q < k; q++) lower |= io_enq[q][i];
        enqFromLowerPorts[i][k] = lower;
      end
    end

  // ===========================================================================
  // 3. 次态（只算真的存了寄存器的严格上三角）
  // ===========================================================================
  logic nextAge [NUM_AGE];
  always_comb
    for (int i = 0; i < NUM_ENTRIES; i++)
      for (int j = i + 1; j < NUM_ENTRIES; j++) begin
        logic beatenByEarlierPort;
        // ParallelMux(sel = i 从哪个口进来, result = j 是否从更靠前的口进来)。
        // enq 按 Chisel 的断言是 one-hot，所以"或"等价于选择。
        beatenByEarlierPort = 1'b0;
        for (int k = 0; k < NUM_ENQ; k++)
          beatenByEarlierPort |= io_enq[k][i] & enqFromLowerPorts[j][k];

        if (isEnq[i] & isEnq[j]) nextAge[age_idx(i, j)] = ~beatenByEarlierPort;  // (1)
        else if (isEnq[i])       nextAge[age_idx(i, j)] = 1'b0;                  // (2)
        else if (isEnq[j])       nextAge[age_idx(i, j)] = 1'b1;                  // (3)
        else                     nextAge[age_idx(i, j)] = ageFull[i][j];         // (4) 保持
      end

  // ===========================================================================
  // 4. 输出：在 canIssue 的条目里挑不比任何其他候选晚的那个（每个发射口一份）
  // ===========================================================================
  always_comb
    for (int d = 0; d < NUM_DEQ; d++)
      for (int i = 0; i < NUM_ENTRIES; i++) begin
        logic oldest;
        oldest = 1'b1;
        for (int j = 0; j < NUM_ENTRIES; j++)
          oldest &= ageFull[i][j] | ~io_canIssue[d][j];
        io_out[d][i] = oldest & io_canIssue[d][i];
      end

  // ===========================================================================
  // 5. 时序：只在 i 或 j 本拍进队时更新（Chisel 的 Mux 写回 = 时钟使能），异步复位清 0
  // ===========================================================================
  always_ff @(posedge clock or posedge reset)
    if (reset) begin
      for (int k = 0; k < NUM_AGE; k++) age[k] <= 1'b0;
    end else begin
      for (int i = 0; i < NUM_ENTRIES; i++)
        for (int j = i + 1; j < NUM_ENTRIES; j++)
          if (isEnq[i] | isEnq[j]) age[age_idx(i, j)] <= nextAge[age_idx(i, j)];
    end

endmodule
