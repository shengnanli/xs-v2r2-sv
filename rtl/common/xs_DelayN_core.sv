// =============================================================================
// xs_DelayN_core —— 固定级数的载荷打拍链（DelayN 家族的参数化核）
//
// 对应 Chisel: utility.DelayN(x, n)。它把一个任意 Bundle 原样延迟 n 拍，
// 不带 valid、不带使能、不带复位——纯粹是 n 级移位寄存器。香山用它给
// 跨模块的"慢信号"（CSR 拷贝、分支预测器使能位、TLB 的 satp/priv 快照、
// 前端/访存的自定义 CSR 打包）做时序打拍，切断长走线的组合路径。
//
// 为什么整个家族只需要这一个核：firtool 把每个实参组合单态化成一个模块，
// 于是 golden 里出现一串 DelayN_<n>，彼此只差**载荷位宽**与**级数**，
// 逻辑一模一样（逐条 REG_k <= REG_{k-1}，输出取最后一级）。这里把载荷压成
// 一根扁平向量，位宽与级数进参数，变体薄文件只做端口拼包/拆包。
//
// 复位语义照搬 golden：寄存器**无复位**，上电为 X，要等载荷灌满 STAGES 拍
// 才有定值。上层若在意上电值，必须自己屏蔽。
//
// elaborate 期不变式（见下面 initial）：
//   WIDTH * STAGES == GOLDEN_REG_BITS —— GOLDEN_REG_BITS 是从 golden 变体里
//   数出来的 reg 位数总和；载荷宽度或级数抄错，等式立刻不成立。
//   GOLDEN_HAS_CLOCK == (STAGES > 0) —— 0 级变体（DelayN_225）在 golden 里
//   连 clock 端口都没有（firtool 把纯直连的时钟消掉了）。这条把「级数」与
//   「端口表上有没有时钟」绑在一起：STAGES 抄成 0 而 golden 有时钟、或者反过来，
//   time 0 就炸，不用指望随机激励恰好打到差那一拍。
//   PORT_BITS_IN / PORT_BITS_OUT 由薄文件用 $bits(golden 端口拼接) 传进来，
//   必须都等于 WIDTH —— 任何一个端口的位宽抄错（本轮已发生过 3 次这类事故），
//   拼接总位数就变了，time 0 直接 $fatal，不必指望随机激励打到那一位。
// =============================================================================
module xs_DelayN_core #(
  parameter int unsigned WIDTH           = 1,          // 载荷位宽（打平后的总位数）
  parameter int unsigned STAGES          = 1,          // 延迟级数 n
  parameter int unsigned GOLDEN_REG_BITS = WIDTH * STAGES,  // golden 里 reg 位数总和
  parameter int unsigned PORT_BITS_IN    = WIDTH,      // = $bits({golden io_in_* 全部端口})
  parameter int unsigned PORT_BITS_OUT   = WIDTH,      // = $bits({golden io_out_* 全部端口})
  parameter bit          GOLDEN_HAS_CLOCK = 1'b1       // golden 端口表上有没有 clock
)(
  input  logic             clock,   // STAGES==0 时本口不被使用（golden 也没有这个口）
  input  logic [WIDTH-1:0] d_in,
  output logic [WIDTH-1:0] d_out
);

  initial begin
    if (GOLDEN_HAS_CLOCK != (STAGES > 0))
      $fatal(1, "xs_DelayN_core: STAGES=%0d 与 golden 端口表有无 clock(%0d) 不相容",
             STAGES, GOLDEN_HAS_CLOCK);
    if (WIDTH * STAGES != GOLDEN_REG_BITS)
      $fatal(1, "xs_DelayN_core: WIDTH=%0d * STAGES=%0d = %0d != golden reg 位数总和 %0d（参数抄错）",
             WIDTH, STAGES, WIDTH * STAGES, GOLDEN_REG_BITS);
    if (PORT_BITS_IN != WIDTH)
      $fatal(1, "xs_DelayN_core: golden io_in_* 端口共 %0d 位 != WIDTH=%0d（端口位宽抄错）",
             PORT_BITS_IN, WIDTH);
    if (PORT_BITS_OUT != WIDTH)
      $fatal(1, "xs_DelayN_core: golden io_out_* 端口共 %0d 位 != WIDTH=%0d（端口位宽抄错）",
             PORT_BITS_OUT, WIDTH);
  end

  // 打拍链：stage[0] 收输入，stage[k] 收上一级；无复位，与 golden 的 reg 一致。
  // STAGES==0 是 utility.DelayN(x, 0) 的退化情形：一根线直通，没有寄存器也没有时钟。
  // golden 里确有这种变体（DelayN_225），所以这里必须有这条分支——**不是补全对称**，
  // 而是照抄 golden 的确有形态。
  generate
    if (STAGES == 0) begin : g_bypass
      assign d_out = d_in;
    end else begin : g_chain
      logic [WIDTH-1:0] stage [STAGES];

      always_ff @(posedge clock) begin
        stage[0] <= d_in;
        for (int unsigned s = 1; s < STAGES; s++)
          stage[s] <= stage[s-1];
      end

      assign d_out = stage[STAGES-1];
    end
  endgenerate

endmodule
