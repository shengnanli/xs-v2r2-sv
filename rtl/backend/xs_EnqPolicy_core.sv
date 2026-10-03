// =============================================================================
// xs_EnqPolicy_core.sv —— 发射队列「入队策略」：从空槽里给两个入队口各挑一个槽
// -----------------------------------------------------------------------------
// 位置：每个 Entries<变体> 里例化两份（simp 段一份、comp 段一份），golden 实例名
//   simpEntryEnqPolicy / compEntryEnqPolicy（见 Entries.scala）。每拍 enq 段要把
//   至多 numEnq(=2) 条 uop 搬进 simp/comp 段，本模块决定「搬进哪两个空槽」。
//
// 输入：io_canEnq[W-1:0] —— 第 k 位 = 第 k 个槽现在是空的、可以接收。
// 输出：两组 Valid(one-hot)：
//   口 0：最低位的空槽（从下往上数第 1 个）；valid = 至少 1 个空槽
//   口 1：最高位的空槽（从上往下数第 1 个）；valid = 至少 2 个空槽
//   两口一个从低端取、一个从高端取，所以只要空槽 >= 2 就必然是两个不同的槽，
//   不需要互相屏蔽 —— 这正是 Chisel `SelectOne("circ", …)` 的用意：
//     getNthOH(1) = 正向第 1 个；getNthOH(2) = 反向第 1 个（CircSelectOne 里
//     第 n 个选择按奇偶交替取正向/反向，n=2 是反向的第 1 个）。
//   ★口 1 的 valid 是「至少 2 个」，不是「至少 1 个」★（OnesMoreThan(bits, 2)）：
//     只有 1 个空槽时口 1 的 bits 仍指向那个槽（最高位 = 最低位），但 valid=0。
//     这里照写：bits 与 valid 各自独立计算，不拿 valid 去门控 bits。
//
// 设计源：src/main/scala/xiangshan/backend/issue/EnqPolicy.scala
//         utility/src/main/scala/utility/BitUtils.scala（CircSelectOne / NaiveSelectOne）
// golden 对照：EnqPolicy（W=22）/ EnqPolicy_8（W=16）/ EnqPolicy_14（W=14）/ EnqPolicy_18（W=8），
//   四者逻辑相同、只差位宽（W = numEntries - numEnq）。
//   ★为什么 W 不是 simp/comp 段的真实大小★：EnqPolicyIO 的宽度恒为
//   numEntries-numEnq，两份例化都用这个宽度，高位由父级喂 0 —— 对「最低位优先」
//   无影响，对「最高位优先」也无影响（喂 0 的位永远不会被选中）。本模块只管 W 位。
//
// 本核纯组合、无寄存器。
// =============================================================================
module xs_EnqPolicy_core #(
  parameter int W = 8        // 槽位数（= numEntries - numEnq）
) (
  input  logic [W-1:0] can_enq,      // 第 k 位 = 第 k 个槽空
  output logic         sel0_valid,   // 口 0：有空槽
  output logic [W-1:0] sel0_oh,      // 口 0：最低位的空槽（one-hot，无空槽时全 0）
  output logic         sel1_valid,   // 口 1：至少两个空槽
  output logic [W-1:0] sel1_oh       // 口 1：最高位的空槽（one-hot，无空槽时全 0）
);

  // ---------------------------------------------------------------------------
  // §1 口 0：从低往高找第一个 1。
  //   第 k 位被选中 ⟺ can_enq[k] 且它下面没有 1。
  // ---------------------------------------------------------------------------
  always_comb begin
    logic seen;
    seen    = 1'b0;
    sel0_oh = '0;
    for (int k = 0; k < W; k++) begin
      sel0_oh[k] = can_enq[k] & ~seen;
      seen       = seen | can_enq[k];
    end
  end

  assign sel0_valid = |can_enq;

  // ---------------------------------------------------------------------------
  // §2 口 1：从高往低找第一个 1（与口 0 对称）。
  //   第 k 位被选中 ⟺ can_enq[k] 且它上面没有 1。
  // ---------------------------------------------------------------------------
  always_comb begin
    logic seen;
    seen    = 1'b0;
    sel1_oh = '0;
    for (int k = W - 1; k >= 0; k--) begin
      sel1_oh[k] = can_enq[k] & ~seen;
      seen       = seen | can_enq[k];
    end
  end

  // ---------------------------------------------------------------------------
  // §3 口 1 的 valid：空槽至少两个。
  //   等价于「存在某个 1，它上面还有 1」—— 逐位累加「下面见过 1」，
  //   再遇到 1 就说明至少两个。不用 $countones，读起来就是定义本身。
  // ---------------------------------------------------------------------------
  always_comb begin
    logic seen;
    seen       = 1'b0;
    sel1_valid = 1'b0;
    for (int k = 0; k < W; k++) begin
      sel1_valid = sel1_valid | (can_enq[k] & seen);
      seen       = seen | can_enq[k];
    end
  end

endmodule
