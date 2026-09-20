// =============================================================================
// DelayN_225 —— 固定级数的载荷打拍链（xs_DelayN_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   延迟级数 STAGES = 0；载荷宽度 = 1 位，分 1 个字段；
//   golden 模块体 = 0 个 reg 位（0 级 —— golden 模块体里一个 reg 也没有，输出直连输入），无复位 / 无使能 / 无子模块；
//   端口 2 个 = 1 个 io_in_* + 1 个 io_out_*。
//   载荷字段：io_in=1b。
//   使用者：LqPAddrModule —— ★0 级退化变体★：DelayN(x, 0) 就是一根直连线，golden 里连 clock 端口都没有。
//
// 结构：golden 同名端口表 -> 打包成一根 1 位扁平载荷 -> 设参例化
//   xs_DelayN_core（核体见 xs_DelayN_core.sv，打拍语义与不变式都在那里讲）
//   -> 拆包回 golden 的 io_out_* 端口。本层只做拼包/拆包。
//   PORT_BITS_IN/OUT 用 $bits(golden 端口拼接) 算出来传给核：任何一个端口的位宽
//   抄错，拼接总位数就变，time 0 直接 $fatal（本轮已发生 3 次位宽静默错事故）。
// 自动生成：verif/ut/DelayN/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module DelayN_225(
  input  io_in,
  output io_out
);

  localparam int unsigned STAGES          = 0;
  localparam int unsigned GOLDEN_REG_BITS = 0;   // golden 里 reg 位数总和
  localparam int unsigned PAYLOAD_W       = 1;   // 0 级：无 reg 可除，载荷位宽直接写，由下面 $bits 核对

  // 端口表事实：golden 全部输入 / 输出端口拼起来各有多少位（$bits 只认端口声明）
  localparam int unsigned PORT_BITS_IN = $bits(
    {io_in});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {io_out});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  assign payload_in =
    {io_in};

  xs_DelayN_core #(
    .WIDTH          (PAYLOAD_W),
    .STAGES         (STAGES),
    .GOLDEN_REG_BITS(GOLDEN_REG_BITS),
    .PORT_BITS_IN   (PORT_BITS_IN),
    .PORT_BITS_OUT  (PORT_BITS_OUT),
    .GOLDEN_HAS_CLOCK(0)
  ) u_core (
    .clock(1'b0),
    .d_in (payload_in),
    .d_out(payload_out)
  );

  assign
    {io_out} = payload_out;

endmodule
