// =============================================================================
// DelayReg_25 —— 带使能与同步复位的载荷打拍链（xs_DelayReg_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   延迟级数 STAGES = 1；载荷宽度 = 657 位，分 69 个字段；
//   golden 模块体 = 657 个 reg 位（1 级 × 657 位），同步复位 / 带使能 / 无子模块；
//   端口 141 个 = clock + reset + 69 个 i_* + 69 个 o_* + enable。
//   （enable 排在**最后**，不是跟 clock/reset 一起——Chisel 里它是 Delayer 基类
//     在主 Bundle 之后单独 IO 出来的一根，端口序照抄 golden。）
//   载荷字段：valid=1b, addr=64b, data_0=8b, data_1=8b, data_2=8b …共 69 个字段，明细见端口表。
//   使用者：DiffSbufferEvent（sbuffer 整行 64 字节）。
//   级数的出处：src/main/scala/xiangshan/mem/sbuffer/Sbuffer.scala:769 delay = 1
//   —— 全族级数从 1 到 4 不等，那是**每个 DifftestBundle 在调用点各自选的
//      delay= 参数**，不是某个变体漏做了什么，不要去"补齐"。
//
// 结构：golden 同名端口表 -> 打包成一根 657 位扁平载荷 -> 设参例化
//   xs_DelayReg_core（核体见 xs_DelayReg_core.sv，打拍/复位/使能语义与不变式
//   都在那里讲）-> 拆包回 golden 的 o_* 端口。本层只做拼包/拆包。
//   PORT_BITS_IN/OUT 用 $bits(golden 端口拼接) 算出来传给核：任何一个端口的位宽
//   抄错，拼接总位数就变，time 0 直接 $fatal（见 verif/ut/DelayReg 的 negtest）。
// 自动生成：verif/ut/DelayReg/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module DelayReg_25(
  input         clock,
  input         reset,
  input         i_valid,
  input  [63:0] i_addr,
  input  [7:0]  i_data_0,
  input  [7:0]  i_data_1,
  input  [7:0]  i_data_2,
  input  [7:0]  i_data_3,
  input  [7:0]  i_data_4,
  input  [7:0]  i_data_5,
  input  [7:0]  i_data_6,
  input  [7:0]  i_data_7,
  input  [7:0]  i_data_8,
  input  [7:0]  i_data_9,
  input  [7:0]  i_data_10,
  input  [7:0]  i_data_11,
  input  [7:0]  i_data_12,
  input  [7:0]  i_data_13,
  input  [7:0]  i_data_14,
  input  [7:0]  i_data_15,
  input  [7:0]  i_data_16,
  input  [7:0]  i_data_17,
  input  [7:0]  i_data_18,
  input  [7:0]  i_data_19,
  input  [7:0]  i_data_20,
  input  [7:0]  i_data_21,
  input  [7:0]  i_data_22,
  input  [7:0]  i_data_23,
  input  [7:0]  i_data_24,
  input  [7:0]  i_data_25,
  input  [7:0]  i_data_26,
  input  [7:0]  i_data_27,
  input  [7:0]  i_data_28,
  input  [7:0]  i_data_29,
  input  [7:0]  i_data_30,
  input  [7:0]  i_data_31,
  input  [7:0]  i_data_32,
  input  [7:0]  i_data_33,
  input  [7:0]  i_data_34,
  input  [7:0]  i_data_35,
  input  [7:0]  i_data_36,
  input  [7:0]  i_data_37,
  input  [7:0]  i_data_38,
  input  [7:0]  i_data_39,
  input  [7:0]  i_data_40,
  input  [7:0]  i_data_41,
  input  [7:0]  i_data_42,
  input  [7:0]  i_data_43,
  input  [7:0]  i_data_44,
  input  [7:0]  i_data_45,
  input  [7:0]  i_data_46,
  input  [7:0]  i_data_47,
  input  [7:0]  i_data_48,
  input  [7:0]  i_data_49,
  input  [7:0]  i_data_50,
  input  [7:0]  i_data_51,
  input  [7:0]  i_data_52,
  input  [7:0]  i_data_53,
  input  [7:0]  i_data_54,
  input  [7:0]  i_data_55,
  input  [7:0]  i_data_56,
  input  [7:0]  i_data_57,
  input  [7:0]  i_data_58,
  input  [7:0]  i_data_59,
  input  [7:0]  i_data_60,
  input  [7:0]  i_data_61,
  input  [7:0]  i_data_62,
  input  [7:0]  i_data_63,
  input  [63:0] i_mask,
  input  [7:0]  i_coreid,
  input  [7:0]  i_index,
  output        o_valid,
  output [63:0] o_addr,
  output [7:0]  o_data_0,
  output [7:0]  o_data_1,
  output [7:0]  o_data_2,
  output [7:0]  o_data_3,
  output [7:0]  o_data_4,
  output [7:0]  o_data_5,
  output [7:0]  o_data_6,
  output [7:0]  o_data_7,
  output [7:0]  o_data_8,
  output [7:0]  o_data_9,
  output [7:0]  o_data_10,
  output [7:0]  o_data_11,
  output [7:0]  o_data_12,
  output [7:0]  o_data_13,
  output [7:0]  o_data_14,
  output [7:0]  o_data_15,
  output [7:0]  o_data_16,
  output [7:0]  o_data_17,
  output [7:0]  o_data_18,
  output [7:0]  o_data_19,
  output [7:0]  o_data_20,
  output [7:0]  o_data_21,
  output [7:0]  o_data_22,
  output [7:0]  o_data_23,
  output [7:0]  o_data_24,
  output [7:0]  o_data_25,
  output [7:0]  o_data_26,
  output [7:0]  o_data_27,
  output [7:0]  o_data_28,
  output [7:0]  o_data_29,
  output [7:0]  o_data_30,
  output [7:0]  o_data_31,
  output [7:0]  o_data_32,
  output [7:0]  o_data_33,
  output [7:0]  o_data_34,
  output [7:0]  o_data_35,
  output [7:0]  o_data_36,
  output [7:0]  o_data_37,
  output [7:0]  o_data_38,
  output [7:0]  o_data_39,
  output [7:0]  o_data_40,
  output [7:0]  o_data_41,
  output [7:0]  o_data_42,
  output [7:0]  o_data_43,
  output [7:0]  o_data_44,
  output [7:0]  o_data_45,
  output [7:0]  o_data_46,
  output [7:0]  o_data_47,
  output [7:0]  o_data_48,
  output [7:0]  o_data_49,
  output [7:0]  o_data_50,
  output [7:0]  o_data_51,
  output [7:0]  o_data_52,
  output [7:0]  o_data_53,
  output [7:0]  o_data_54,
  output [7:0]  o_data_55,
  output [7:0]  o_data_56,
  output [7:0]  o_data_57,
  output [7:0]  o_data_58,
  output [7:0]  o_data_59,
  output [7:0]  o_data_60,
  output [7:0]  o_data_61,
  output [7:0]  o_data_62,
  output [7:0]  o_data_63,
  output [63:0] o_mask,
  output [7:0]  o_coreid,
  output [7:0]  o_index,
  input         enable
);

  localparam int unsigned STAGES          = 1;
  localparam int unsigned GOLDEN_REG_BITS = 657;   // golden 里 reg 位数总和
  localparam int unsigned PAYLOAD_W       = GOLDEN_REG_BITS / STAGES;

  // 端口表事实：golden 全部 i_* / o_* 端口拼起来各有多少位（$bits 只认端口声明）
  localparam int unsigned PORT_BITS_IN = $bits(
    {i_valid, i_addr, i_data_0, i_data_1, i_data_2, i_data_3, i_data_4, i_data_5,
     i_data_6, i_data_7, i_data_8, i_data_9, i_data_10, i_data_11, i_data_12, i_data_13,
     i_data_14, i_data_15, i_data_16, i_data_17, i_data_18, i_data_19, i_data_20,
     i_data_21, i_data_22, i_data_23, i_data_24, i_data_25, i_data_26, i_data_27,
     i_data_28, i_data_29, i_data_30, i_data_31, i_data_32, i_data_33, i_data_34,
     i_data_35, i_data_36, i_data_37, i_data_38, i_data_39, i_data_40, i_data_41,
     i_data_42, i_data_43, i_data_44, i_data_45, i_data_46, i_data_47, i_data_48,
     i_data_49, i_data_50, i_data_51, i_data_52, i_data_53, i_data_54, i_data_55,
     i_data_56, i_data_57, i_data_58, i_data_59, i_data_60, i_data_61, i_data_62,
     i_data_63, i_mask, i_coreid, i_index});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {o_valid, o_addr, o_data_0, o_data_1, o_data_2, o_data_3, o_data_4, o_data_5,
     o_data_6, o_data_7, o_data_8, o_data_9, o_data_10, o_data_11, o_data_12, o_data_13,
     o_data_14, o_data_15, o_data_16, o_data_17, o_data_18, o_data_19, o_data_20,
     o_data_21, o_data_22, o_data_23, o_data_24, o_data_25, o_data_26, o_data_27,
     o_data_28, o_data_29, o_data_30, o_data_31, o_data_32, o_data_33, o_data_34,
     o_data_35, o_data_36, o_data_37, o_data_38, o_data_39, o_data_40, o_data_41,
     o_data_42, o_data_43, o_data_44, o_data_45, o_data_46, o_data_47, o_data_48,
     o_data_49, o_data_50, o_data_51, o_data_52, o_data_53, o_data_54, o_data_55,
     o_data_56, o_data_57, o_data_58, o_data_59, o_data_60, o_data_61, o_data_62,
     o_data_63, o_mask, o_coreid, o_index});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  // 打包次序 = golden 端口声明顺序，先声明的在高位。
  assign payload_in =
    {i_valid, i_addr, i_data_0, i_data_1, i_data_2, i_data_3, i_data_4, i_data_5,
     i_data_6, i_data_7, i_data_8, i_data_9, i_data_10, i_data_11, i_data_12, i_data_13,
     i_data_14, i_data_15, i_data_16, i_data_17, i_data_18, i_data_19, i_data_20,
     i_data_21, i_data_22, i_data_23, i_data_24, i_data_25, i_data_26, i_data_27,
     i_data_28, i_data_29, i_data_30, i_data_31, i_data_32, i_data_33, i_data_34,
     i_data_35, i_data_36, i_data_37, i_data_38, i_data_39, i_data_40, i_data_41,
     i_data_42, i_data_43, i_data_44, i_data_45, i_data_46, i_data_47, i_data_48,
     i_data_49, i_data_50, i_data_51, i_data_52, i_data_53, i_data_54, i_data_55,
     i_data_56, i_data_57, i_data_58, i_data_59, i_data_60, i_data_61, i_data_62,
     i_data_63, i_mask, i_coreid, i_index};

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
    {o_valid, o_addr, o_data_0, o_data_1, o_data_2, o_data_3, o_data_4, o_data_5,
     o_data_6, o_data_7, o_data_8, o_data_9, o_data_10, o_data_11, o_data_12, o_data_13,
     o_data_14, o_data_15, o_data_16, o_data_17, o_data_18, o_data_19, o_data_20,
     o_data_21, o_data_22, o_data_23, o_data_24, o_data_25, o_data_26, o_data_27,
     o_data_28, o_data_29, o_data_30, o_data_31, o_data_32, o_data_33, o_data_34,
     o_data_35, o_data_36, o_data_37, o_data_38, o_data_39, o_data_40, o_data_41,
     o_data_42, o_data_43, o_data_44, o_data_45, o_data_46, o_data_47, o_data_48,
     o_data_49, o_data_50, o_data_51, o_data_52, o_data_53, o_data_54, o_data_55,
     o_data_56, o_data_57, o_data_58, o_data_59, o_data_60, o_data_61, o_data_62,
     o_data_63, o_mask, o_coreid, o_index} = payload_out;

endmodule
