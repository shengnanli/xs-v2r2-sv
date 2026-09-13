// =============================================================================
// xs_DeMultiplexer_core —— 按 ready 优先级分发的一入多出解复用器（DeMultiplexer 家族的核）
//
// 位置：ICacheMissUnit 的两处分发点。一路 miss 请求要投给若干个空闲 MSHR 之一：
//       DeMultiplexer   把取指 miss 投给 4 个取指 MSHR；
//       DeMultiplexer_1 把预取 miss 投给 10 个预取 MSHR，并额外输出选中的下标。
//
// 语义（对应 Chisel 的 DeMultiplexer，lowest-index-wins、纯组合）：
//   载荷**广播**给所有出口，出口之间只靠 valid 区分；
//   out_valid[k] = 没有比 k 更靠前的出口 ready（= 已经被它接走），且上游 in_valid；
//                  注意 out_valid[0] = in_valid，与任何 ready 无关；
//   in_ready     = 任意一个出口 ready；
//   chosen       = 第一个 ready 的出口下标；一个都不 ready 时给最后一个下标
//                  （golden 三元链的兜底分支，照抄不改）。
//   本核无状态、无时钟。
//
// 注意这里的优先级链是按 **ready** 排的（谁先空闲谁接），与
// xs_FixedPriorityArbiter_core 按 valid 排正好是对偶关系。
//
// elaborate 期不变式：见下面 initial。
// =============================================================================
module xs_DeMultiplexer_core #(
  parameter int unsigned WIDTH   = 1,      // 广播载荷位宽
  parameter int unsigned NUM_OUT = 2,      // 出口数
  parameter int unsigned CHOSEN_W = 1,     // chosen 端口位宽（无 chosen 端口时不使用）
  // ---- 由薄文件从 golden 端口表算出来，只用于自检 ----
  parameter int unsigned PORT_BITS_IN   = WIDTH,  // = $bits({io_in_bits_*})
  parameter int unsigned PORT_BITS_OUT0 = WIDTH,  // = $bits({io_out_0_bits_*})
  parameter bit          HAS_CHOSEN     = 1'b0,
  parameter int unsigned GOLDEN_PORTS   = 0,      // golden 端口总数
  parameter int unsigned GOLDEN_FIELDS  = 1       // 载荷字段数（每个出口各一份）
)(
  input  logic                     in_valid,
  output logic                     in_ready,
  input  logic [WIDTH-1:0]         in_bits,
  input  logic [NUM_OUT-1:0]       out_ready,   // 位 NUM_OUT-1 = 第 0 个出口
  output logic [NUM_OUT-1:0]       out_valid,
  output logic [NUM_OUT*WIDTH-1:0] out_bits,    // 与 out_ready 同序
  output logic [CHOSEN_W-1:0]      chosen
);

  initial begin
    if (NUM_OUT < 2 || WIDTH == 0)
      $fatal(1, "xs_DeMultiplexer_core: NUM_OUT=%0d WIDTH=%0d 不合法", NUM_OUT, WIDTH);
    if (PORT_BITS_IN != WIDTH || PORT_BITS_OUT0 != WIDTH)
      $fatal(1, "xs_DeMultiplexer_core: golden 载荷位宽 in=%0d out0=%0d != WIDTH=%0d（位宽抄错）",
             PORT_BITS_IN, PORT_BITS_OUT0, WIDTH);
    if (HAS_CHOSEN && CHOSEN_W != $clog2(NUM_OUT))
      $fatal(1, "xs_DeMultiplexer_core: chosen 端口 %0d 位 != clog2(NUM_OUT=%0d)=%0d（出口数抄错）",
             CHOSEN_W, NUM_OUT, $clog2(NUM_OUT));
    // golden 端口数恒等式：in 的 ready/valid 2 根 + in 载荷字段 + 每个出口
    // (ready+valid+载荷字段) + 可选 chosen。出口数或字段数抄错立刻不成立。
    if (GOLDEN_PORTS != 2 + GOLDEN_FIELDS + NUM_OUT * (2 + GOLDEN_FIELDS) + int'(HAS_CHOSEN))
      $fatal(1, "xs_DeMultiplexer_core: golden 端口数 %0d != 2+%0d+%0d*(2+%0d)+%0d（出口数或字段数抄错）",
             GOLDEN_PORTS, GOLDEN_FIELDS, NUM_OUT, GOLDEN_FIELDS, int'(HAS_CHOSEN));
  end

  // taken_before[k] = 有比第 k 个出口更靠前的出口已经 ready（会先把请求接走）
  logic [NUM_OUT-1:0] taken_before;
  always_comb begin
    taken_before[NUM_OUT-1] = 1'b0;                    // 第 0 个出口前面没人
    for (int unsigned k = NUM_OUT - 1; k > 0; k--)
      taken_before[k-1] = taken_before[k] | out_ready[k];
  end

  assign in_ready  = |out_ready;
  assign out_valid = ~taken_before & {NUM_OUT{in_valid}};

  // 载荷广播：每个出口都拿到同一份 in_bits
  for (genvar k = 0; k < NUM_OUT; k++) begin : g_bcast
    assign out_bits[k * WIDTH +: WIDTH] = in_bits;
  end

  // chosen：第一个 ready 的出口下标；从低位扫到高位，后写覆盖先写，
  // 初值 = 最后一个出口的下标（golden 三元链的兜底分支）。
  always_comb begin
    chosen = CHOSEN_W'(NUM_OUT - 1);
    for (int unsigned k = 1; k < NUM_OUT; k++)
      if (out_ready[k])
        chosen = CHOSEN_W'(NUM_OUT - 1 - k);
  end

endmodule
