// =============================================================================
// DelayNWithValid —— 带 valid 使能的两级打拍链（xs_DelayNWithValid_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   载荷 WIDTH = 50 位，分 1 个字段；级数固定 2 级；
//   golden 模块体 = 1 个异步复位的 valid 寄存器 + 100 个无复位数据 reg 位
//     （2 级 × 50 位），无子模块；
//   端口 5 个 = clock + reset + io_in_valid + 1 入 + 1 出。
//   载荷字段：io_in_bits=50b。
//   使用者：FTB —— 预测目标地址沿预测流水打两拍。
//
// 结构：golden 同名端口表 -> 打包成一根 50 位扁平载荷 -> 设参例化
//   xs_DelayNWithValid_core（使能与复位语义、不变式都在 xs_DelayNWithValid_core.sv
//   里讲）-> 拆包回 golden 的 io_out_bits_* 端口。本层只做拼包/拆包。
//   PORT_BITS_IN/OUT 用 $bits(golden 端口拼接) 算出来传给核：端口位宽抄错 time 0 $fatal。
// 自动生成：verif/ut/DelayNWithValid/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module DelayNWithValid(
  input         clock,
  input         reset,
  input  [49:0] io_in_bits,
  input         io_in_valid,
  output [49:0] io_out_bits
);

  localparam int unsigned GOLDEN_DATA_REG_BITS = 100;  // golden 两级数据 reg 位数
  localparam int unsigned PAYLOAD_W            = GOLDEN_DATA_REG_BITS / 2;

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
    .WIDTH               (PAYLOAD_W),
    .GOLDEN_DATA_REG_BITS(GOLDEN_DATA_REG_BITS),
    .PORT_BITS_IN        (PORT_BITS_IN),
    .PORT_BITS_OUT       (PORT_BITS_OUT)
  ) u_core (
    .clock   (clock),
    .reset   (reset),
    .in_valid(io_in_valid),
    .d_in    (payload_in),
    .d_out   (payload_out)
  );

  assign
    {io_out_bits} = payload_out;

endmodule
