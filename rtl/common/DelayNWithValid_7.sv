// =============================================================================
// DelayNWithValid_7 —— 带 valid 使能的 0 级打拍链（xs_DelayNWithValid_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   载荷 WIDTH = 16 位，分 1 个字段；数据级数 STAGES = 0；
//   valid 链保留 0 个寄存器；
//   golden 模块体 = 0 个 reg（纯连线），无子模块；
//   端口 2 个 = 1 入 + 1 出。
//   载荷字段：io_in_bits=16b。
//   使用者：LqPAddrModule —— n=0 直通。
//
// 家族形状：STAGES=0：退化成一根直通线。golden 连 clock / reset / io_in_valid
//   三个端口都没有 —— 没有寄存器就没有时钟域，Chisel 那边要的是 0 级延迟。
//
// 结构：golden 同名端口表 -> 打包成一根 16 位扁平载荷 -> 设参例化
//   xs_DelayNWithValid_core（使能与复位语义、不变式都在 xs_DelayNWithValid_core.sv
//   里讲）-> 拆包回 golden 的 io_out_bits_* 端口。本层只做拼包/拆包。
//   PAYLOAD_W / GOLDEN_REG_BITS 是两条**各自独立**从 golden 抽出来的事实
//   （前者来自端口表求和，后者来自 reg 声明），核里的守恒等式
//   VALID_CHAIN + STAGES*PAYLOAD_W == GOLDEN_REG_BITS 把两者对上；
//   PORT_BITS_IN/OUT 再用 $bits(golden 端口拼接) 把端口表本身对一遍。
//   任何一处抄错，time 0 直接 $fatal。
// 自动生成：verif/ut/DelayNWithValid/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module DelayNWithValid_7(
  input  [15:0] io_in_bits,
  output [15:0] io_out_bits
);

  localparam int unsigned STAGES          = 0;   // 数据级数 n
  localparam int unsigned VALID_CHAIN     = 0;   // 保留下来的 valid 寄存器个数
  localparam int unsigned PAYLOAD_W       = 16;  // golden 端口表求和
  localparam int unsigned GOLDEN_REG_BITS = 0;   // golden reg 声明求和（含 valid 链）

  // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
  localparam int unsigned PORT_BITS_IN = $bits(
    {io_in_bits});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {io_out_bits});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  assign payload_in =
    {io_in_bits};

  xs_DelayNWithValid_core #(
    .WIDTH          (PAYLOAD_W),
    .STAGES         (STAGES),
    .VALID_CHAIN    (VALID_CHAIN),
    .GOLDEN_REG_BITS(GOLDEN_REG_BITS),
    .PORT_BITS_IN   (PORT_BITS_IN),
    .PORT_BITS_OUT  (PORT_BITS_OUT)
  ) u_core (
    // golden 无 clock 端口：STAGES=0，没有寄存器就没有时钟域
    .clock   (1'b0),
    // golden 无 reset 端口：valid 链长 0，没有可复位的东西
    .reset   (1'b0),
    // golden 无 io_in_valid 端口：STAGES=0，没有使能可言
    .in_valid(1'b0),
    .d_in    (payload_in),
    .d_out   (payload_out),
    // 本变体的 golden 没有 io_out_valid 端口，核的 out_valid 悬空 ——
    // 照抄 golden 的端口表，不凭空补一个 golden 没有的输出。
    .out_valid()
  );

  assign
    {io_out_bits} = payload_out;

endmodule
