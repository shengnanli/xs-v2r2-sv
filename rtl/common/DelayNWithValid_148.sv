// =============================================================================
// DelayNWithValid_148 —— 带 valid 使能的 3 级打拍链（xs_DelayNWithValid_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   载荷 WIDTH = 7 位，分 2 个字段；数据级数 STAGES = 3；
//   valid 链保留 2 个寄存器；
//   golden 模块体 = 23 个 reg 位 = 2 个 valid 位（异步复位）
//     + 3 级 × 7 位数据（无复位），无子模块；
//   端口 7 个 = clock + reset + io_in_valid + 2 入 + 2 出。
//   载荷字段：flag=1b, value=6b。
//   使用者：LoadQueueRAW —— {flag,value} 队列指针打三拍。
//
// 家族形状：V = STAGES-1 = 2：golden **没有** io_out_valid，valid 链最后一级没人读、
//   被 firtool 消掉；剩下的 2 级还要给数据级当使能，所以留着。
//
// 结构：golden 同名端口表 -> 打包成一根 7 位扁平载荷 -> 设参例化
//   xs_DelayNWithValid_core（使能与复位语义、不变式都在 xs_DelayNWithValid_core.sv
//   里讲）-> 拆包回 golden 的 io_out_bits_* 端口。本层只做拼包/拆包。
//   PAYLOAD_W / GOLDEN_REG_BITS 是两条**各自独立**从 golden 抽出来的事实
//   （前者来自端口表求和，后者来自 reg 声明），核里的守恒等式
//   VALID_CHAIN + STAGES*PAYLOAD_W == GOLDEN_REG_BITS 把两者对上；
//   PORT_BITS_IN/OUT 再用 $bits(golden 端口拼接) 把端口表本身对一遍。
//   任何一处抄错，time 0 直接 $fatal。
// 自动生成：verif/ut/DelayNWithValid/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module DelayNWithValid_148(
  input        clock,
  input        reset,
  input        io_in_bits_flag,
  input  [5:0] io_in_bits_value,
  input        io_in_valid,
  output       io_out_bits_flag,
  output [5:0] io_out_bits_value
);

  localparam int unsigned STAGES          = 3;   // 数据级数 n
  localparam int unsigned VALID_CHAIN     = 2;   // 保留下来的 valid 寄存器个数
  localparam int unsigned PAYLOAD_W       = 7;  // golden 端口表求和
  localparam int unsigned GOLDEN_REG_BITS = 23;   // golden reg 声明求和（含 valid 链）

  // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
  localparam int unsigned PORT_BITS_IN = $bits(
    {io_in_bits_flag, io_in_bits_value});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {io_out_bits_flag, io_out_bits_value});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  assign payload_in =
    {io_in_bits_flag, io_in_bits_value};

  xs_DelayNWithValid_core #(
    .WIDTH          (PAYLOAD_W),
    .STAGES         (STAGES),
    .VALID_CHAIN    (VALID_CHAIN),
    .GOLDEN_REG_BITS(GOLDEN_REG_BITS),
    .PORT_BITS_IN   (PORT_BITS_IN),
    .PORT_BITS_OUT  (PORT_BITS_OUT)
  ) u_core (
    .clock   (clock),
    .reset   (reset),
    .in_valid(io_in_valid),
    .d_in    (payload_in),
    .d_out   (payload_out),
    // 本变体的 golden 没有 io_out_valid 端口，核的 out_valid 悬空 ——
    // 照抄 golden 的端口表，不凭空补一个 golden 没有的输出。
    .out_valid()
  );

  assign
    {io_out_bits_flag, io_out_bits_value} = payload_out;

endmodule
