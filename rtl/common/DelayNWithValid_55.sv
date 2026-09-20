// =============================================================================
// DelayNWithValid_55 —— 带 valid 使能的 1 级打拍链（xs_DelayNWithValid_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   载荷 WIDTH = 24 位，分 1 个字段；数据级数 STAGES = 1；
//   valid 链保留 0 个寄存器；
//   golden 模块体 = 24 个 reg 位 = 0 个 valid 位（异步复位）
//     + 1 级 × 24 位数据（无复位），无子模块；
//   端口 4 个 = clock + io_in_valid + 1 入 + 1 出。
//   载荷字段：io_in_bits=24b。
//   使用者：LqPAddrModule_1 —— 24 位地址高位打一拍。
//
// 家族形状：STAGES=1 且 valid 链长 0：golden 有 clock 和 io_in_valid，**没有 reset**。
//   valid 链唯一的那一级只有 io_out_valid 会读，而本变体没有这个端口，
//   于是整条链被 firtool 消光，连带 reset 端口一起消失。
//
// 结构：golden 同名端口表 -> 打包成一根 24 位扁平载荷 -> 设参例化
//   xs_DelayNWithValid_core（使能与复位语义、不变式都在 xs_DelayNWithValid_core.sv
//   里讲）-> 拆包回 golden 的 io_out_bits_* 端口。本层只做拼包/拆包。
//   PAYLOAD_W / GOLDEN_REG_BITS 是两条**各自独立**从 golden 抽出来的事实
//   （前者来自端口表求和，后者来自 reg 声明），核里的守恒等式
//   VALID_CHAIN + STAGES*PAYLOAD_W == GOLDEN_REG_BITS 把两者对上；
//   PORT_BITS_IN/OUT 再用 $bits(golden 端口拼接) 把端口表本身对一遍。
//   任何一处抄错，time 0 直接 $fatal。
// 自动生成：verif/ut/DelayNWithValid/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module DelayNWithValid_55(
  input         clock,
  input  [23:0] io_in_bits,
  input         io_in_valid,
  output [23:0] io_out_bits
);

  localparam int unsigned STAGES          = 1;   // 数据级数 n
  localparam int unsigned VALID_CHAIN     = 0;   // 保留下来的 valid 寄存器个数
  localparam int unsigned PAYLOAD_W       = 24;  // golden 端口表求和
  localparam int unsigned GOLDEN_REG_BITS = 24;   // golden reg 声明求和（含 valid 链）

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
    .clock   (clock),
    // golden 无 reset 端口：valid 链长 0，没有可复位的东西
    .reset   (1'b0),
    .in_valid(io_in_valid),
    .d_in    (payload_in),
    .d_out   (payload_out),
    // 本变体的 golden 没有 io_out_valid 端口，核的 out_valid 悬空 ——
    // 照抄 golden 的端口表，不凭空补一个 golden 没有的输出。
    .out_valid()
  );

  assign
    {io_out_bits} = payload_out;

endmodule
