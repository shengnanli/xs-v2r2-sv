// =============================================================================
// DelayNWithValid_3 —— 带 valid 使能的 2 级打拍链（xs_DelayNWithValid_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   载荷 WIDTH = 48 位，分 1 个字段；数据级数 STAGES = 2；
//   valid 链保留 2 个寄存器；
//   golden 模块体 = 98 个 reg 位 = 2 个 valid 位（异步复位）
//     + 2 级 × 48 位数据（无复位），无子模块；
//   端口 6 个 = clock + reset + io_in_valid + 1 入 + 2 出。
//   载荷字段：io_in_bits=48b。
//   使用者：MemBlock —— 48 位物理地址打两拍，带 out_valid。
//
// 家族形状：V = STAGES = 2：golden **有** io_out_valid，整条 valid 链都被读到，
//   一级都没被消，所以 reset 端口在。
//
// 结构：golden 同名端口表 -> 打包成一根 48 位扁平载荷 -> 设参例化
//   xs_DelayNWithValid_core（使能与复位语义、不变式都在 xs_DelayNWithValid_core.sv
//   里讲）-> 拆包回 golden 的 io_out_bits_* 端口。本层只做拼包/拆包。
//   PAYLOAD_W / GOLDEN_REG_BITS 是两条**各自独立**从 golden 抽出来的事实
//   （前者来自端口表求和，后者来自 reg 声明），核里的守恒等式
//   VALID_CHAIN + STAGES*PAYLOAD_W == GOLDEN_REG_BITS 把两者对上；
//   PORT_BITS_IN/OUT 再用 $bits(golden 端口拼接) 把端口表本身对一遍。
//   任何一处抄错，time 0 直接 $fatal。
// 自动生成：verif/ut/DelayNWithValid/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module DelayNWithValid_3(
  input         clock,
  input         reset,
  input  [47:0] io_in_bits,
  input         io_in_valid,
  output [47:0] io_out_bits,
  output        io_out_valid
);

  localparam int unsigned STAGES          = 2;   // 数据级数 n
  localparam int unsigned VALID_CHAIN     = 2;   // 保留下来的 valid 寄存器个数
  localparam int unsigned PAYLOAD_W       = 48;  // golden 端口表求和
  localparam int unsigned GOLDEN_REG_BITS = 98;   // golden reg 声明求和（含 valid 链）

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
    .reset   (reset),
    .in_valid(io_in_valid),
    .d_in    (payload_in),
    .d_out   (payload_out),
    .out_valid(io_out_valid)
  );

  assign
    {io_out_bits} = payload_out;

endmodule
