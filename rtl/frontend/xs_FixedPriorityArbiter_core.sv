// =============================================================================
// xs_FixedPriorityArbiter_core —— 固定优先级仲裁器（ICache 侧 Arbiter 家族的核）
//
// 位置：ICache 的两处汇流点。ICacheMainPipe / IPrefetchPipe 各用一个 2 入口版本
//       把两路 miss 请求并成一路（Arbiter2_ICacheMissReq）；ICacheMissUnit 用一个
//       5 入口版本把 4 个取指 MSHR + 1 个预取通路的 Acquire 并成一路
//       （Arbiter5_MSHRAcquire）。
//
// 语义（对应 Chisel 的 Arbiter，lowest-index-wins、无锁定、纯组合）：
//   out_valid   = 任意一路 valid；
//   in_ready[k] = 没有比 k 更高优先级的一路在请求，且下游 out_ready；
//                 注意 in_ready[0] = out_ready，与是否有人请求无关；
//   out_bits    = 优先级最高的那一路的载荷；**一路都没有请求时给最后一路的载荷**
//                 （golden 三元链的最后一个 else 分支，照抄不改：out_valid=0 时
//                  载荷本来就无意义，但逐位等价要求这个"垃圾值"也一致）。
//   本核无状态、无时钟。
//
// 载荷怎么进来：变体薄文件把每一路的全部 bits 字段按输出端口顺序 MSB 优先拼成
//   一根 WIDTH 位载荷，再把 NUM_IN 路按"优先级从高到低"MSB 优先拼成 in_bits。
//   Arbiter5 的 acquire_source 字段是个特例：golden 里前 4 路**没有 source 端口**，
//   仲裁器直接替它们填常量 0..3，只有第 5 路用自己的端口值。这不是本核的事，
//   由薄文件在拼载荷时把常量填进去 —— 核看到的仍是"每路一根等宽载荷"。
//
// elaborate 期不变式：见下面 initial。
// =============================================================================
module xs_FixedPriorityArbiter_core #(
  parameter int unsigned WIDTH  = 1,   // 单路载荷位宽
  parameter int unsigned NUM_IN = 2,   // 入口数
  // ---- 由薄文件从 golden 端口表算出来，只用于自检 ----
  parameter int unsigned PORT_BITS_OUT     = WIDTH,  // = $bits({全部 io_out_bits_*})
  parameter int unsigned PORT_BITS_LAST_IN = WIDTH,  // = $bits({最后一路的 bits 端口})+常量位
  parameter int unsigned GOLDEN_PORTS      = 0,      // golden 端口总数
  parameter int unsigned GOLDEN_BITS_PORTS = 0       // golden 里 *_bits_* 端口的个数
)(
  input  logic [NUM_IN-1:0]         in_valid,   // 位 NUM_IN-1 = 第 0 路（优先级最高）
  output logic [NUM_IN-1:0]         in_ready,
  input  logic [NUM_IN*WIDTH-1:0]   in_bits,    // 与 in_valid 同序：高位段配高位 valid
  input  logic                      out_ready,
  output logic                      out_valid,
  output logic [WIDTH-1:0]          out_bits
);

  initial begin
    if (NUM_IN < 2 || WIDTH == 0)
      $fatal(1, "xs_FixedPriorityArbiter_core: NUM_IN=%0d WIDTH=%0d 不合法", NUM_IN, WIDTH);
    if (PORT_BITS_OUT != WIDTH)
      $fatal(1, "xs_FixedPriorityArbiter_core: golden 输出载荷 %0d 位 != WIDTH=%0d（位宽抄错）",
             PORT_BITS_OUT, WIDTH);
    if (PORT_BITS_LAST_IN != WIDTH)
      $fatal(1, "xs_FixedPriorityArbiter_core: golden 末路载荷 %0d 位 != WIDTH=%0d（位宽抄错）",
             PORT_BITS_LAST_IN, WIDTH);
    // golden 端口数恒等式：每路 ready+valid 共 2 根，加 out_ready/out_valid 两根，
    // 再加所有 *_bits_* 载荷端口。入口数抄错这条立刻不成立。
    if (GOLDEN_PORTS != 2 * NUM_IN + 2 + GOLDEN_BITS_PORTS)
      $fatal(1, "xs_FixedPriorityArbiter_core: golden 端口数 %0d != 2*%0d + 2 + %0d（入口数抄错）",
             GOLDEN_PORTS, NUM_IN, GOLDEN_BITS_PORTS);
  end

  // higher_req[k] = 有比第 k 路优先级更高的一路在请求
  logic [NUM_IN-1:0] higher_req;
  always_comb begin
    higher_req[NUM_IN-1] = 1'b0;                       // 第 0 路上面没人
    for (int unsigned k = NUM_IN - 1; k > 0; k--)
      higher_req[k-1] = higher_req[k] | in_valid[k];
  end

  assign in_ready  = ~higher_req & {NUM_IN{out_ready}};
  assign out_valid = |in_valid;

  // 载荷优先级选择：从低位（优先级低）扫到高位，后写覆盖先写。
  // 初值取最低位那一路 = golden 三元链的兜底分支。
  always_comb begin
    out_bits = in_bits[0 +: WIDTH];
    for (int unsigned k = 1; k < NUM_IN; k++)
      if (in_valid[k])
        out_bits = in_bits[k * WIDTH +: WIDTH];
  end

endmodule
