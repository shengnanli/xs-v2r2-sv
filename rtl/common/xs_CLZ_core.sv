// =============================================================================
// xs_CLZ_core —— 前导零计数（CLZ 家族的参数化核）
//
// 从最高位往下找第一个 1，输出它前面有几个 0。香山用它做浮点数规格化
// （FCVT / FMA 的尾数左移量）与各种优先级编码。
//
// 两个参数就定死了一个变体：
//   WIDTH     输入位数
//   SCAN_LOW  **最低被扫描的位**；golden 根本不看比它更低的位
// 输出位宽 OUT_W 不是自由的：NONE = WIDTH - SCAN_LOW 是"扫描范围内一个 1 都没有"
// 时的输出，OUT_W 恰好是装下 NONE 所需的位数，一位不多一位不少。
//
// ★SCAN_LOW 是本家族唯一有语义后果的参数，不是排版差异★
//
//   SCAN_LOW = 0（CLZ_6/_7/_9/_11/_28/_29/_30/_31，8 个变体）
//       扫到第 0 位。全零输入 -> WIDTH。教科书意义上的 CLZ。
//
//   SCAN_LOW = 1（**只有 CLZ 本体**，WIDTH=64 / OUT_W=6）
//       io_in[0] 根本没有被读。全零输入 -> 63，**不是 64**；
//       也就是说"64 位全零"和"只有最低位是 1"这两件事输出**相同**。
//       来源是 Chisel 的 `PriorityEncoder`：它用 `PriorityMux` 展开，
//       最后一个候选索引是**无条件兜底**分支，不带自己的条件判断。
//       于是输出只需要 log2(64)=6 位（装得下 0..63），装不下 64 ——
//       端口宽度本身就是这件事的痕迹。
//       ★这是 golden 的真实行为。本工程要求 bug-for-bug 一致，照抄，不"修正"。★
//       调用方（FCVT 的 64 位规格化）要么保证输入非零，要么本来就不区分这两种情况；
//       无论哪种，都不是这一层该替它决定的事。
//
// elaborate 期不变式（见下面 initial）：
//   OUT_W == 装下 NONE 所需位数 —— 端口宽度与扫描范围必须自洽。WIDTH / SCAN_LOW /
//   OUT_W 是三条**各自独立**从 golden 抽出来的事实（前两条来自模块体引用到的位，
//   第三条来自端口表），抄错任何一条这条等式立刻不成立。
//   PORT_BITS_IN / PORT_BITS_OUT 由薄文件用 $bits(golden 端口) 传进来再对一遍。
// =============================================================================
module xs_CLZ_core #(
  parameter int unsigned WIDTH         = 8,       // golden io_in 位宽
  parameter int unsigned SCAN_LOW      = 0,       // 最低被扫描的位（本家族只有 0 / 1）
  parameter int unsigned OUT_W         = 4,       // golden io_out 位宽
  parameter int unsigned PORT_BITS_IN  = WIDTH,   // = $bits(golden io_in)
  parameter int unsigned PORT_BITS_OUT = OUT_W    // = $bits(golden io_out)
)(
  input  logic [WIDTH-1:0] d_in,
  output logic [OUT_W-1:0] cnt
);

  // 扫描范围内一个 1 都没有时的输出值
  localparam int unsigned NONE = WIDTH - SCAN_LOW;

  initial begin
    if (WIDTH == 0)
      $fatal(1, "xs_CLZ_core: WIDTH=0 不合法");
    if (SCAN_LOW >= WIDTH)
      $fatal(1, "xs_CLZ_core: SCAN_LOW=%0d 必须小于 WIDTH=%0d —— 否则没有位可扫",
             SCAN_LOW, WIDTH);
    if (OUT_W != $clog2(NONE + 1))
      $fatal(1, "xs_CLZ_core: OUT_W=%0d != 装下 NONE=%0d 所需的 %0d 位（WIDTH/SCAN_LOW/OUT_W 抄错）",
             OUT_W, NONE, $clog2(NONE + 1));
    if (PORT_BITS_IN != WIDTH)
      $fatal(1, "xs_CLZ_core: golden io_in 共 %0d 位 != WIDTH=%0d（端口位宽抄错）",
             PORT_BITS_IN, WIDTH);
    if (PORT_BITS_OUT != OUT_W)
      $fatal(1, "xs_CLZ_core: golden io_out 共 %0d 位 != OUT_W=%0d（端口位宽抄错）",
             PORT_BITS_OUT, OUT_W);
  end

  // 从 SCAN_LOW 往上扫，**后写的覆盖先写的** —— 于是最终留下的是最高的那个 1，
  // 正是"前导零"要的优先级。写成升序循环而不是降序 + break，是因为这样
  // 一眼能看出优先级方向（最后一次赋值赢 = 高位赢），不必在脑子里跑 break。
  always_comb begin
    cnt = OUT_W'(NONE);                       // 兜底：扫描范围内没有 1
    for (int unsigned i = SCAN_LOW; i < WIDTH; i++)
      if (d_in[i]) cnt = OUT_W'(WIDTH - 1 - i);
  end

endmodule
