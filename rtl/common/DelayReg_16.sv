// =============================================================================
// DelayReg_16 —— 带使能与同步复位的载荷打拍链（xs_DelayReg_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   延迟级数 STAGES = 2；载荷宽度 = 256 位，分 32 个字段；
//   golden 模块体 = 512 个 reg 位（2 级 × 256 位），同步复位 / 带使能 / 无子模块；
//   端口 67 个 = clock + reset + 32 个 i_* + 32 个 o_* + enable。
//   （enable 排在**最后**，不是跟 clock/reset 一起——Chisel 里它是 Delayer 基类
//     在主 Bundle 之后单独 IO 出来的一根，端口序照抄 golden。）
//   载荷字段：value_0=8b, value_1=8b, value_2=8b, value_3=8b, value_4=8b …共 32 个字段，明细见端口表。
//   使用者：重命名表快照 32 项 × 8 位（Int 与 Fp 两张表位宽相同，firtool 去重后共用一个模块，golden 里例化 2 次）。
//   级数的出处：src/main/scala/xiangshan/backend/rename/RenameTable.scala:251/283 delay = 2
//   —— 全族级数从 1 到 4 不等，那是**每个 DifftestBundle 在调用点各自选的
//      delay= 参数**，不是某个变体漏做了什么，不要去"补齐"。
//
// 结构：golden 同名端口表 -> 打包成一根 256 位扁平载荷 -> 设参例化
//   xs_DelayReg_core（核体见 xs_DelayReg_core.sv，打拍/复位/使能语义与不变式
//   都在那里讲）-> 拆包回 golden 的 o_* 端口。本层只做拼包/拆包。
//   PORT_BITS_IN/OUT 用 $bits(golden 端口拼接) 算出来传给核：任何一个端口的位宽
//   抄错，拼接总位数就变，time 0 直接 $fatal（见 verif/ut/DelayReg 的 negtest）。
// 自动生成：verif/ut/DelayReg/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module DelayReg_16(
  input        clock,
  input        reset,
  input  [7:0] i_value_0,
  input  [7:0] i_value_1,
  input  [7:0] i_value_2,
  input  [7:0] i_value_3,
  input  [7:0] i_value_4,
  input  [7:0] i_value_5,
  input  [7:0] i_value_6,
  input  [7:0] i_value_7,
  input  [7:0] i_value_8,
  input  [7:0] i_value_9,
  input  [7:0] i_value_10,
  input  [7:0] i_value_11,
  input  [7:0] i_value_12,
  input  [7:0] i_value_13,
  input  [7:0] i_value_14,
  input  [7:0] i_value_15,
  input  [7:0] i_value_16,
  input  [7:0] i_value_17,
  input  [7:0] i_value_18,
  input  [7:0] i_value_19,
  input  [7:0] i_value_20,
  input  [7:0] i_value_21,
  input  [7:0] i_value_22,
  input  [7:0] i_value_23,
  input  [7:0] i_value_24,
  input  [7:0] i_value_25,
  input  [7:0] i_value_26,
  input  [7:0] i_value_27,
  input  [7:0] i_value_28,
  input  [7:0] i_value_29,
  input  [7:0] i_value_30,
  input  [7:0] i_value_31,
  output [7:0] o_value_0,
  output [7:0] o_value_1,
  output [7:0] o_value_2,
  output [7:0] o_value_3,
  output [7:0] o_value_4,
  output [7:0] o_value_5,
  output [7:0] o_value_6,
  output [7:0] o_value_7,
  output [7:0] o_value_8,
  output [7:0] o_value_9,
  output [7:0] o_value_10,
  output [7:0] o_value_11,
  output [7:0] o_value_12,
  output [7:0] o_value_13,
  output [7:0] o_value_14,
  output [7:0] o_value_15,
  output [7:0] o_value_16,
  output [7:0] o_value_17,
  output [7:0] o_value_18,
  output [7:0] o_value_19,
  output [7:0] o_value_20,
  output [7:0] o_value_21,
  output [7:0] o_value_22,
  output [7:0] o_value_23,
  output [7:0] o_value_24,
  output [7:0] o_value_25,
  output [7:0] o_value_26,
  output [7:0] o_value_27,
  output [7:0] o_value_28,
  output [7:0] o_value_29,
  output [7:0] o_value_30,
  output [7:0] o_value_31,
  input        enable
);

  localparam int unsigned STAGES          = 2;
  localparam int unsigned GOLDEN_REG_BITS = 512;   // golden 里 reg 位数总和
  localparam int unsigned PAYLOAD_W       = GOLDEN_REG_BITS / STAGES;

  // 端口表事实：golden 全部 i_* / o_* 端口拼起来各有多少位（$bits 只认端口声明）
  localparam int unsigned PORT_BITS_IN = $bits(
    {i_value_0, i_value_1, i_value_2, i_value_3, i_value_4, i_value_5, i_value_6,
     i_value_7, i_value_8, i_value_9, i_value_10, i_value_11, i_value_12, i_value_13,
     i_value_14, i_value_15, i_value_16, i_value_17, i_value_18, i_value_19, i_value_20,
     i_value_21, i_value_22, i_value_23, i_value_24, i_value_25, i_value_26, i_value_27,
     i_value_28, i_value_29, i_value_30, i_value_31});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {o_value_0, o_value_1, o_value_2, o_value_3, o_value_4, o_value_5, o_value_6,
     o_value_7, o_value_8, o_value_9, o_value_10, o_value_11, o_value_12, o_value_13,
     o_value_14, o_value_15, o_value_16, o_value_17, o_value_18, o_value_19, o_value_20,
     o_value_21, o_value_22, o_value_23, o_value_24, o_value_25, o_value_26, o_value_27,
     o_value_28, o_value_29, o_value_30, o_value_31});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  // 打包次序 = golden 端口声明顺序，先声明的在高位。
  assign payload_in =
    {i_value_0, i_value_1, i_value_2, i_value_3, i_value_4, i_value_5, i_value_6,
     i_value_7, i_value_8, i_value_9, i_value_10, i_value_11, i_value_12, i_value_13,
     i_value_14, i_value_15, i_value_16, i_value_17, i_value_18, i_value_19, i_value_20,
     i_value_21, i_value_22, i_value_23, i_value_24, i_value_25, i_value_26, i_value_27,
     i_value_28, i_value_29, i_value_30, i_value_31};

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
    {o_value_0, o_value_1, o_value_2, o_value_3, o_value_4, o_value_5, o_value_6,
     o_value_7, o_value_8, o_value_9, o_value_10, o_value_11, o_value_12, o_value_13,
     o_value_14, o_value_15, o_value_16, o_value_17, o_value_18, o_value_19, o_value_20,
     o_value_21, o_value_22, o_value_23, o_value_24, o_value_25, o_value_26, o_value_27,
     o_value_28, o_value_29, o_value_30, o_value_31} = payload_out;

endmodule
