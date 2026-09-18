// =============================================================================
// DelayReg —— 带使能与同步复位的载荷打拍链（xs_DelayReg_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   延迟级数 STAGES = 3；载荷宽度 = 322 位，分 36 个字段；
//   golden 模块体 = 966 个 reg 位（3 级 × 322 位），同步复位 / 带使能 / 无子模块；
//   端口 75 个 = clock + reset + 36 个 i_* + 36 个 o_* + enable。
//   （enable 排在**最后**，不是跟 clock/reset 一起——Chisel 里它是 Delayer 基类
//     在主 Bundle 之后单独 IO 出来的一根，端口序照抄 golden。）
//   载荷字段：valid=1b, skip=1b, isRVC=1b, rfwen=1b, fpwen=1b …共 36 个字段，明细见端口表。
//   使用者：DiffInstrCommit（提交事件，8 条提交道各一份）。
//   级数的出处：src/main/scala/xiangshan/backend/rob/Rob.scala:1543 delay = 3
//   —— 全族级数从 1 到 4 不等，那是**每个 DifftestBundle 在调用点各自选的
//      delay= 参数**，不是某个变体漏做了什么，不要去"补齐"。
//
// 结构：golden 同名端口表 -> 打包成一根 322 位扁平载荷 -> 设参例化
//   xs_DelayReg_core（核体见 xs_DelayReg_core.sv，打拍/复位/使能语义与不变式
//   都在那里讲）-> 拆包回 golden 的 o_* 端口。本层只做拼包/拆包。
//   PORT_BITS_IN/OUT 用 $bits(golden 端口拼接) 算出来传给核：任何一个端口的位宽
//   抄错，拼接总位数就变，time 0 直接 $fatal（见 verif/ut/DelayReg 的 negtest）。
// 自动生成：verif/ut/DelayReg/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module DelayReg(
  input         clock,
  input         reset,
  input         i_valid,
  input         i_skip,
  input         i_isRVC,
  input         i_rfwen,
  input         i_fpwen,
  input         i_vecwen,
  input         i_v0wen,
  input  [8:0]  i_wpdest,
  input  [7:0]  i_wdest,
  input  [8:0]  i_otherwpdest_0,
  input  [8:0]  i_otherwpdest_1,
  input  [8:0]  i_otherwpdest_2,
  input  [8:0]  i_otherwpdest_3,
  input  [8:0]  i_otherwpdest_4,
  input  [8:0]  i_otherwpdest_5,
  input  [8:0]  i_otherwpdest_6,
  input  [8:0]  i_otherwpdest_7,
  input  [8:0]  i_otherwpdest_8,
  input  [8:0]  i_otherwpdest_9,
  input  [8:0]  i_otherwpdest_10,
  input  [8:0]  i_otherwpdest_11,
  input  [8:0]  i_otherwpdest_12,
  input  [8:0]  i_otherwpdest_13,
  input  [8:0]  i_otherwpdest_14,
  input  [8:0]  i_otherwpdest_15,
  input  [63:0] i_pc,
  input  [31:0] i_instr,
  input  [9:0]  i_robIdx,
  input  [6:0]  i_lqIdx,
  input  [6:0]  i_sqIdx,
  input         i_isLoad,
  input         i_isStore,
  input  [7:0]  i_nFused,
  input  [7:0]  i_special,
  input  [7:0]  i_coreid,
  input  [7:0]  i_index,
  output        o_valid,
  output        o_skip,
  output        o_isRVC,
  output        o_rfwen,
  output        o_fpwen,
  output        o_vecwen,
  output        o_v0wen,
  output [8:0]  o_wpdest,
  output [7:0]  o_wdest,
  output [8:0]  o_otherwpdest_0,
  output [8:0]  o_otherwpdest_1,
  output [8:0]  o_otherwpdest_2,
  output [8:0]  o_otherwpdest_3,
  output [8:0]  o_otherwpdest_4,
  output [8:0]  o_otherwpdest_5,
  output [8:0]  o_otherwpdest_6,
  output [8:0]  o_otherwpdest_7,
  output [8:0]  o_otherwpdest_8,
  output [8:0]  o_otherwpdest_9,
  output [8:0]  o_otherwpdest_10,
  output [8:0]  o_otherwpdest_11,
  output [8:0]  o_otherwpdest_12,
  output [8:0]  o_otherwpdest_13,
  output [8:0]  o_otherwpdest_14,
  output [8:0]  o_otherwpdest_15,
  output [63:0] o_pc,
  output [31:0] o_instr,
  output [9:0]  o_robIdx,
  output [6:0]  o_lqIdx,
  output [6:0]  o_sqIdx,
  output        o_isLoad,
  output        o_isStore,
  output [7:0]  o_nFused,
  output [7:0]  o_special,
  output [7:0]  o_coreid,
  output [7:0]  o_index,
  input         enable
);

  localparam int unsigned STAGES          = 3;
  localparam int unsigned GOLDEN_REG_BITS = 966;   // golden 里 reg 位数总和
  localparam int unsigned PAYLOAD_W       = GOLDEN_REG_BITS / STAGES;

  // 端口表事实：golden 全部 i_* / o_* 端口拼起来各有多少位（$bits 只认端口声明）
  localparam int unsigned PORT_BITS_IN = $bits(
    {i_valid, i_skip, i_isRVC, i_rfwen, i_fpwen, i_vecwen, i_v0wen, i_wpdest, i_wdest,
     i_otherwpdest_0, i_otherwpdest_1, i_otherwpdest_2, i_otherwpdest_3, i_otherwpdest_4,
     i_otherwpdest_5, i_otherwpdest_6, i_otherwpdest_7, i_otherwpdest_8, i_otherwpdest_9,
     i_otherwpdest_10, i_otherwpdest_11, i_otherwpdest_12, i_otherwpdest_13,
     i_otherwpdest_14, i_otherwpdest_15, i_pc, i_instr, i_robIdx, i_lqIdx, i_sqIdx,
     i_isLoad, i_isStore, i_nFused, i_special, i_coreid, i_index});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {o_valid, o_skip, o_isRVC, o_rfwen, o_fpwen, o_vecwen, o_v0wen, o_wpdest, o_wdest,
     o_otherwpdest_0, o_otherwpdest_1, o_otherwpdest_2, o_otherwpdest_3, o_otherwpdest_4,
     o_otherwpdest_5, o_otherwpdest_6, o_otherwpdest_7, o_otherwpdest_8, o_otherwpdest_9,
     o_otherwpdest_10, o_otherwpdest_11, o_otherwpdest_12, o_otherwpdest_13,
     o_otherwpdest_14, o_otherwpdest_15, o_pc, o_instr, o_robIdx, o_lqIdx, o_sqIdx,
     o_isLoad, o_isStore, o_nFused, o_special, o_coreid, o_index});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  // 打包次序 = golden 端口声明顺序，先声明的在高位。
  assign payload_in =
    {i_valid, i_skip, i_isRVC, i_rfwen, i_fpwen, i_vecwen, i_v0wen, i_wpdest, i_wdest,
     i_otherwpdest_0, i_otherwpdest_1, i_otherwpdest_2, i_otherwpdest_3, i_otherwpdest_4,
     i_otherwpdest_5, i_otherwpdest_6, i_otherwpdest_7, i_otherwpdest_8, i_otherwpdest_9,
     i_otherwpdest_10, i_otherwpdest_11, i_otherwpdest_12, i_otherwpdest_13,
     i_otherwpdest_14, i_otherwpdest_15, i_pc, i_instr, i_robIdx, i_lqIdx, i_sqIdx,
     i_isLoad, i_isStore, i_nFused, i_special, i_coreid, i_index};

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
    {o_valid, o_skip, o_isRVC, o_rfwen, o_fpwen, o_vecwen, o_v0wen, o_wpdest, o_wdest,
     o_otherwpdest_0, o_otherwpdest_1, o_otherwpdest_2, o_otherwpdest_3, o_otherwpdest_4,
     o_otherwpdest_5, o_otherwpdest_6, o_otherwpdest_7, o_otherwpdest_8, o_otherwpdest_9,
     o_otherwpdest_10, o_otherwpdest_11, o_otherwpdest_12, o_otherwpdest_13,
     o_otherwpdest_14, o_otherwpdest_15, o_pc, o_instr, o_robIdx, o_lqIdx, o_sqIdx,
     o_isLoad, o_isStore, o_nFused, o_special, o_coreid, o_index} = payload_out;

endmodule
