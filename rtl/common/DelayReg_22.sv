// =============================================================================
// DelayReg_22 —— 带使能与同步复位的载荷打拍链（xs_DelayReg_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   延迟级数 STAGES = 3；载荷宽度 = 173 位，分 10 个字段；
//   golden 模块体 = 519 个 reg 位（3 级 × 173 位），同步复位 / 带使能 / 无子模块；
//   端口 23 个 = clock + reset + 10 个 i_* + 10 个 o_* + enable。
//   （enable 排在**最后**，不是跟 clock/reset 一起——Chisel 里它是 Delayer 基类
//     在主 Bundle 之后单独 IO 出来的一根，端口序照抄 golden。）
//   载荷字段：valid=1b, interrupt=32b, exception=32b, exceptionPC=64b, exceptionInst=32b …共 10 个字段，明细见端口表。
//   使用者：DiffArchEvent（中断/异常事件）。
//   级数的出处：src/main/scala/xiangshan/backend/fu/NewCSR/NewCSR.scala:1570 delay = 3
//   —— 全族级数从 1 到 4 不等，那是**每个 DifftestBundle 在调用点各自选的
//      delay= 参数**，不是某个变体漏做了什么，不要去"补齐"。
//
// 结构：golden 同名端口表 -> 打包成一根 173 位扁平载荷 -> 设参例化
//   xs_DelayReg_core（核体见 xs_DelayReg_core.sv，打拍/复位/使能语义与不变式
//   都在那里讲）-> 拆包回 golden 的 o_* 端口。本层只做拼包/拆包。
//   PORT_BITS_IN/OUT 用 $bits(golden 端口拼接) 算出来传给核：任何一个端口的位宽
//   抄错，拼接总位数就变，time 0 直接 $fatal（见 verif/ut/DelayReg 的 negtest）。
// 自动生成：verif/ut/DelayReg/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module DelayReg_22(
  input         clock,
  input         reset,
  input         i_valid,
  input  [31:0] i_interrupt,
  input  [31:0] i_exception,
  input  [63:0] i_exceptionPC,
  input  [31:0] i_exceptionInst,
  input         i_hasNMI,
  input         i_virtualInterruptIsHvictlInject,
  input         i_irToHS,
  input         i_irToVS,
  input  [7:0]  i_coreid,
  output        o_valid,
  output [31:0] o_interrupt,
  output [31:0] o_exception,
  output [63:0] o_exceptionPC,
  output [31:0] o_exceptionInst,
  output        o_hasNMI,
  output        o_virtualInterruptIsHvictlInject,
  output        o_irToHS,
  output        o_irToVS,
  output [7:0]  o_coreid,
  input         enable
);

  localparam int unsigned STAGES          = 3;
  localparam int unsigned GOLDEN_REG_BITS = 519;   // golden 里 reg 位数总和
  localparam int unsigned PAYLOAD_W       = GOLDEN_REG_BITS / STAGES;

  // 端口表事实：golden 全部 i_* / o_* 端口拼起来各有多少位（$bits 只认端口声明）
  localparam int unsigned PORT_BITS_IN = $bits(
    {i_valid, i_interrupt, i_exception, i_exceptionPC, i_exceptionInst, i_hasNMI,
     i_virtualInterruptIsHvictlInject, i_irToHS, i_irToVS, i_coreid});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {o_valid, o_interrupt, o_exception, o_exceptionPC, o_exceptionInst, o_hasNMI,
     o_virtualInterruptIsHvictlInject, o_irToHS, o_irToVS, o_coreid});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  // 打包次序 = golden 端口声明顺序，先声明的在高位。
  assign payload_in =
    {i_valid, i_interrupt, i_exception, i_exceptionPC, i_exceptionInst, i_hasNMI,
     i_virtualInterruptIsHvictlInject, i_irToHS, i_irToVS, i_coreid};

  xs_DelayReg_core #(
    .WIDTH          (PAYLOAD_W),
    .STAGES         (STAGES),
    .GOLDEN_REG_BITS(GOLDEN_REG_BITS),
    .PORT_BITS_IN   (PORT_BITS_IN),
    .PORT_BITS_OUT  (PORT_BITS_OUT)
  ) u_core (
    .clock (clock),
    .reset (reset),
    .enable(enable),
    .d_in  (payload_in),
    .d_out (payload_out)
  );

  // 拆包：与上面的打包次序互逆。
  assign
    {o_valid, o_interrupt, o_exception, o_exceptionPC, o_exceptionInst, o_hasNMI,
     o_virtualInterruptIsHvictlInject, o_irToHS, o_irToVS, o_coreid} = payload_out;

endmodule
