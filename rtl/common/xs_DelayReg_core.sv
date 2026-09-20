// =============================================================================
// xs_DelayReg_core —— 带使能与同步复位的载荷打拍链（DelayReg 家族的参数化核）
//
// 对应 Chisel: difftest.util.Delayer 里的 private class DelayReg（difftest 子仓
// src/main/scala/util/Delayer.scala:28）：
//     var r = WireInit(i)
//     for (_ <- 0 until n_cycles) { r = RegEnable(r, 0.U.asTypeOf(gen), enable) }
//     o := r
// 即：n_cycles 级 RegEnable 链，复位值 0，使能是全局一根 enable。
//
// ★它是什么★ difftest 的"对齐用"延迟线。DUT 侧的观测事件（提交、store、
// 寄存器堆快照、异常事件…）产生的拍号与参考模型消费的拍号不一致，GatewayEndpoint
// 就给每个 DifftestBundle 按各自的 delay= 参数打若干拍再送出去。
// **它不是流水线握手**：没有 ready、没有 valid 反压，enable 拉低就整条链原地冻结。
//
// ★为什么整个家族只需要这一个核（这是量出来的，不是假定的）★
// 对 G1 的 11 份 golden 做过一次"完全重建"实验：只用 (字段表, 级数) 两个事实
// 重新生成模块体，与 golden 逐行比对（去掉 firtool 的随机初值段、归一空白）——
// **11/11 完全一致**。也就是说这些文件里除了字段表与级数**没有任何别的内容**：
// 复位臂覆盖全部寄存器、复位值全 0、移位链严格 r_1<=i / r_k<=r_{k-1}、
// 输出一律取最后一级、端口序一律 clock,reset,i_*,o_*,enable。
// 行数从 176 到 3430（20 倍）纯粹是"字段数 × 级数"的差异。
//
// ★复位语义照搬 golden，三条都不许动★
//   (1) **同步**复位：always @(posedge clock)，reset 在 if 里，不是敏感表里。
//       写成 `posedge clock or posedge reset` 是换了时钟域，FM 会当场失配。
//   (2) 复位**优先于**使能：golden 是 if (reset) ... else if (enable) ...，
//       所以 enable=0 时复位照样生效。反过来写（使能优先）是真 bug。
//   (3) 复位覆盖**每一级**，不是只清最后一级或只清第一级。
//   两者都不成立时（无复位且无使能）整条链保持——这就是"冻结"。
//
// elaborate 期不变式（见下面 initial）：
//   WIDTH * STAGES == GOLDEN_REG_BITS —— GOLDEN_REG_BITS 是从 golden 变体里
//   数出来的 reg 位数总和；载荷宽度或级数抄错，等式立刻不成立。
//   PORT_BITS_IN / PORT_BITS_OUT 由薄文件用 $bits(golden 端口拼接) 传进来，
//   必须都等于 WIDTH —— 任何一个端口的位宽抄错，拼接总位数就变了，
//   time 0 直接 $fatal，不必指望随机激励恰好打到那一位。
//   （这三条不变式与 xs_DelayN_core 同源；那边是本轮 3 次位宽静默错事故的产物。）
// =============================================================================
module xs_DelayReg_core #(
  parameter int unsigned WIDTH           = 1,          // 载荷位宽（打平后的总位数）
  parameter int unsigned STAGES          = 1,          // 延迟级数 n_cycles
  parameter int unsigned GOLDEN_REG_BITS = WIDTH * STAGES,  // golden 里 reg 位数总和
  parameter int unsigned PORT_BITS_IN    = WIDTH,      // = $bits({golden i_* 全部端口})
  parameter int unsigned PORT_BITS_OUT   = WIDTH       // = $bits({golden o_* 全部端口})
)(
  input  logic             clock,
  input  logic             reset,   // 同步、高有效；优先于 enable
  input  logic             enable,  // 拉低 = 整条链冻结
  input  logic [WIDTH-1:0] d_in,
  output logic [WIDTH-1:0] d_out
);

  initial begin
    if (STAGES == 0)
      $fatal(1, "xs_DelayReg_core: STAGES=0 —— Delayer 在 n_cycles==0 时根本不例化模块（见 Delayer.scala 的 apply），golden 里没有 0 级变体");
    if (WIDTH * STAGES != GOLDEN_REG_BITS)
      $fatal(1, "xs_DelayReg_core: WIDTH=%0d * STAGES=%0d = %0d != golden reg 位数总和 %0d（参数抄错）",
             WIDTH, STAGES, WIDTH * STAGES, GOLDEN_REG_BITS);
    if (PORT_BITS_IN != WIDTH)
      $fatal(1, "xs_DelayReg_core: golden i_* 端口共 %0d 位 != WIDTH=%0d（端口位宽抄错）",
             PORT_BITS_IN, WIDTH);
    if (PORT_BITS_OUT != WIDTH)
      $fatal(1, "xs_DelayReg_core: golden o_* 端口共 %0d 位 != WIDTH=%0d（端口位宽抄错）",
             PORT_BITS_OUT, WIDTH);
  end

  // 打拍链：stage[0] 收输入，stage[k] 收上一级。
  // golden 的 reg 名是 r_1..r_STAGES（1 起编号），这里是 stage[0..STAGES-1]，
  // 即 stage[k] 对应 golden 的 r_(k+1)。
  logic [WIDTH-1:0] stage [STAGES];

  always_ff @(posedge clock) begin
    if (reset) begin
      // ★每一级都清★（golden 的复位臂逐个寄存器列全，一个不落）
      for (int unsigned s = 0; s < STAGES; s++)
        stage[s] <= '0;
    end
    else if (enable) begin
      stage[0] <= d_in;
      for (int unsigned s = 1; s < STAGES; s++)
        stage[s] <= stage[s-1];
    end
    // 两者都不成立：保持（golden 没有 else 臂）
  end

  assign d_out = stage[STAGES-1];

endmodule
