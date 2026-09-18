// =============================================================================
// DelayReg_26 —— 带使能与同步复位的载荷打拍链（xs_DelayReg_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   延迟级数 STAGES = 2；载荷宽度 = 325 位，分 13 个字段；
//   golden 模块体 = 650 个 reg 位（2 级 × 325 位），同步复位 / 带使能 / 无子模块；
//   端口 29 个 = clock + reset + 13 个 i_* + 13 个 o_* + enable。
//   （enable 排在**最后**，不是跟 clock/reset 一起——Chisel 里它是 Delayer 基类
//     在主 Bundle 之后单独 IO 出来的一根，端口序照抄 golden。）
//   载荷字段：valid=1b, addr=64b, data=64b, highData=64b, mask=16b …共 13 个字段，明细见端口表。
//   使用者：DiffStoreEvent（store 事件，golden 里例化 3 次）。
//   级数的出处：src/main/scala/xiangshan/mem/sbuffer/Sbuffer.scala:920/945 delay = 2
//   —— 全族级数从 1 到 4 不等，那是**每个 DifftestBundle 在调用点各自选的
//      delay= 参数**，不是某个变体漏做了什么，不要去"补齐"。
//
// 结构：golden 同名端口表 -> 打包成一根 325 位扁平载荷 -> 设参例化
//   xs_DelayReg_core（核体见 xs_DelayReg_core.sv，打拍/复位/使能语义与不变式
//   都在那里讲）-> 拆包回 golden 的 o_* 端口。本层只做拼包/拆包。
//   PORT_BITS_IN/OUT 用 $bits(golden 端口拼接) 算出来传给核：任何一个端口的位宽
//   抄错，拼接总位数就变，time 0 直接 $fatal（见 verif/ut/DelayReg 的 negtest）。
// 自动生成：verif/ut/DelayReg/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module DelayReg_26(
  input         clock,
  input         reset,
  input         i_valid,
  input  [63:0] i_addr,
  input  [63:0] i_data,
  input  [63:0] i_highData,
  input  [15:0] i_mask,
  input         i_wLine,
  input         i_vecNeedSplit,
  input  [7:0]  i_eew,
  input  [15:0] i_offset,
  input  [63:0] i_pc,
  input  [9:0]  i_robidx,
  input  [7:0]  i_coreid,
  input  [7:0]  i_index,
  output        o_valid,
  output [63:0] o_addr,
  output [63:0] o_data,
  output [63:0] o_highData,
  output [15:0] o_mask,
  output        o_wLine,
  output        o_vecNeedSplit,
  output [7:0]  o_eew,
  output [15:0] o_offset,
  output [63:0] o_pc,
  output [9:0]  o_robidx,
  output [7:0]  o_coreid,
  output [7:0]  o_index,
  input         enable
);

  localparam int unsigned STAGES          = 2;
  localparam int unsigned GOLDEN_REG_BITS = 650;   // golden 里 reg 位数总和
  localparam int unsigned PAYLOAD_W       = GOLDEN_REG_BITS / STAGES;

  // 端口表事实：golden 全部 i_* / o_* 端口拼起来各有多少位（$bits 只认端口声明）
  localparam int unsigned PORT_BITS_IN = $bits(
    {i_valid, i_addr, i_data, i_highData, i_mask, i_wLine, i_vecNeedSplit, i_eew,
     i_offset, i_pc, i_robidx, i_coreid, i_index});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {o_valid, o_addr, o_data, o_highData, o_mask, o_wLine, o_vecNeedSplit, o_eew,
     o_offset, o_pc, o_robidx, o_coreid, o_index});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  // 打包次序 = golden 端口声明顺序，先声明的在高位。
  assign payload_in =
    {i_valid, i_addr, i_data, i_highData, i_mask, i_wLine, i_vecNeedSplit, i_eew,
     i_offset, i_pc, i_robidx, i_coreid, i_index};

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
    {o_valid, o_addr, o_data, o_highData, o_mask, o_wLine, o_vecNeedSplit, o_eew,
     o_offset, o_pc, o_robidx, o_coreid, o_index} = payload_out;

endmodule
