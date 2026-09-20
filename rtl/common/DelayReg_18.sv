// =============================================================================
// DelayReg_18 —— 带使能与同步复位的载荷打拍链（xs_DelayReg_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   延迟级数 STAGES = 2；载荷宽度 = 576 位，分 64 个字段；
//   golden 模块体 = 1152 个 reg 位（2 级 × 576 位），同步复位 / 带使能 / 无子模块；
//   端口 131 个 = clock + reset + 64 个 i_* + 64 个 o_* + enable。
//   （enable 排在**最后**，不是跟 clock/reset 一起——Chisel 里它是 Delayer 基类
//     在主 Bundle 之后单独 IO 出来的一根，端口序照抄 golden。）
//   载荷字段：value_0=9b, value_1=9b, value_2=9b, value_3=9b, value_4=9b …共 64 个字段，明细见端口表。
//   使用者：重命名表快照 64 项 × 9 位（向量表）。
//   级数的出处：src/main/scala/xiangshan/backend/rename/RenameTable.scala:312 delay = 2
//   —— 全族级数从 1 到 4 不等，那是**每个 DifftestBundle 在调用点各自选的
//      delay= 参数**，不是某个变体漏做了什么，不要去"补齐"。
//
// 结构：golden 同名端口表 -> 打包成一根 576 位扁平载荷 -> 设参例化
//   xs_DelayReg_core（核体见 xs_DelayReg_core.sv，打拍/复位/使能语义与不变式
//   都在那里讲）-> 拆包回 golden 的 o_* 端口。本层只做拼包/拆包。
//   PORT_BITS_IN/OUT 用 $bits(golden 端口拼接) 算出来传给核：任何一个端口的位宽
//   抄错，拼接总位数就变，time 0 直接 $fatal（见 verif/ut/DelayReg 的 negtest）。
// 自动生成：verif/ut/DelayReg/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module DelayReg_18(
  input        clock,
  input        reset,
  input  [8:0] i_value_0,
  input  [8:0] i_value_1,
  input  [8:0] i_value_2,
  input  [8:0] i_value_3,
  input  [8:0] i_value_4,
  input  [8:0] i_value_5,
  input  [8:0] i_value_6,
  input  [8:0] i_value_7,
  input  [8:0] i_value_8,
  input  [8:0] i_value_9,
  input  [8:0] i_value_10,
  input  [8:0] i_value_11,
  input  [8:0] i_value_12,
  input  [8:0] i_value_13,
  input  [8:0] i_value_14,
  input  [8:0] i_value_15,
  input  [8:0] i_value_16,
  input  [8:0] i_value_17,
  input  [8:0] i_value_18,
  input  [8:0] i_value_19,
  input  [8:0] i_value_20,
  input  [8:0] i_value_21,
  input  [8:0] i_value_22,
  input  [8:0] i_value_23,
  input  [8:0] i_value_24,
  input  [8:0] i_value_25,
  input  [8:0] i_value_26,
  input  [8:0] i_value_27,
  input  [8:0] i_value_28,
  input  [8:0] i_value_29,
  input  [8:0] i_value_30,
  input  [8:0] i_value_31,
  input  [8:0] i_value_32,
  input  [8:0] i_value_33,
  input  [8:0] i_value_34,
  input  [8:0] i_value_35,
  input  [8:0] i_value_36,
  input  [8:0] i_value_37,
  input  [8:0] i_value_38,
  input  [8:0] i_value_39,
  input  [8:0] i_value_40,
  input  [8:0] i_value_41,
  input  [8:0] i_value_42,
  input  [8:0] i_value_43,
  input  [8:0] i_value_44,
  input  [8:0] i_value_45,
  input  [8:0] i_value_46,
  input  [8:0] i_value_47,
  input  [8:0] i_value_48,
  input  [8:0] i_value_49,
  input  [8:0] i_value_50,
  input  [8:0] i_value_51,
  input  [8:0] i_value_52,
  input  [8:0] i_value_53,
  input  [8:0] i_value_54,
  input  [8:0] i_value_55,
  input  [8:0] i_value_56,
  input  [8:0] i_value_57,
  input  [8:0] i_value_58,
  input  [8:0] i_value_59,
  input  [8:0] i_value_60,
  input  [8:0] i_value_61,
  input  [8:0] i_value_62,
  input  [8:0] i_value_63,
  output [8:0] o_value_0,
  output [8:0] o_value_1,
  output [8:0] o_value_2,
  output [8:0] o_value_3,
  output [8:0] o_value_4,
  output [8:0] o_value_5,
  output [8:0] o_value_6,
  output [8:0] o_value_7,
  output [8:0] o_value_8,
  output [8:0] o_value_9,
  output [8:0] o_value_10,
  output [8:0] o_value_11,
  output [8:0] o_value_12,
  output [8:0] o_value_13,
  output [8:0] o_value_14,
  output [8:0] o_value_15,
  output [8:0] o_value_16,
  output [8:0] o_value_17,
  output [8:0] o_value_18,
  output [8:0] o_value_19,
  output [8:0] o_value_20,
  output [8:0] o_value_21,
  output [8:0] o_value_22,
  output [8:0] o_value_23,
  output [8:0] o_value_24,
  output [8:0] o_value_25,
  output [8:0] o_value_26,
  output [8:0] o_value_27,
  output [8:0] o_value_28,
  output [8:0] o_value_29,
  output [8:0] o_value_30,
  output [8:0] o_value_31,
  output [8:0] o_value_32,
  output [8:0] o_value_33,
  output [8:0] o_value_34,
  output [8:0] o_value_35,
  output [8:0] o_value_36,
  output [8:0] o_value_37,
  output [8:0] o_value_38,
  output [8:0] o_value_39,
  output [8:0] o_value_40,
  output [8:0] o_value_41,
  output [8:0] o_value_42,
  output [8:0] o_value_43,
  output [8:0] o_value_44,
  output [8:0] o_value_45,
  output [8:0] o_value_46,
  output [8:0] o_value_47,
  output [8:0] o_value_48,
  output [8:0] o_value_49,
  output [8:0] o_value_50,
  output [8:0] o_value_51,
  output [8:0] o_value_52,
  output [8:0] o_value_53,
  output [8:0] o_value_54,
  output [8:0] o_value_55,
  output [8:0] o_value_56,
  output [8:0] o_value_57,
  output [8:0] o_value_58,
  output [8:0] o_value_59,
  output [8:0] o_value_60,
  output [8:0] o_value_61,
  output [8:0] o_value_62,
  output [8:0] o_value_63,
  input        enable
);

  localparam int unsigned STAGES          = 2;
  localparam int unsigned GOLDEN_REG_BITS = 1152;   // golden 里 reg 位数总和
  localparam int unsigned PAYLOAD_W       = GOLDEN_REG_BITS / STAGES;

  // 端口表事实：golden 全部 i_* / o_* 端口拼起来各有多少位（$bits 只认端口声明）
  localparam int unsigned PORT_BITS_IN = $bits(
    {i_value_0, i_value_1, i_value_2, i_value_3, i_value_4, i_value_5, i_value_6,
     i_value_7, i_value_8, i_value_9, i_value_10, i_value_11, i_value_12, i_value_13,
     i_value_14, i_value_15, i_value_16, i_value_17, i_value_18, i_value_19, i_value_20,
     i_value_21, i_value_22, i_value_23, i_value_24, i_value_25, i_value_26, i_value_27,
     i_value_28, i_value_29, i_value_30, i_value_31, i_value_32, i_value_33, i_value_34,
     i_value_35, i_value_36, i_value_37, i_value_38, i_value_39, i_value_40, i_value_41,
     i_value_42, i_value_43, i_value_44, i_value_45, i_value_46, i_value_47, i_value_48,
     i_value_49, i_value_50, i_value_51, i_value_52, i_value_53, i_value_54, i_value_55,
     i_value_56, i_value_57, i_value_58, i_value_59, i_value_60, i_value_61, i_value_62,
     i_value_63});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {o_value_0, o_value_1, o_value_2, o_value_3, o_value_4, o_value_5, o_value_6,
     o_value_7, o_value_8, o_value_9, o_value_10, o_value_11, o_value_12, o_value_13,
     o_value_14, o_value_15, o_value_16, o_value_17, o_value_18, o_value_19, o_value_20,
     o_value_21, o_value_22, o_value_23, o_value_24, o_value_25, o_value_26, o_value_27,
     o_value_28, o_value_29, o_value_30, o_value_31, o_value_32, o_value_33, o_value_34,
     o_value_35, o_value_36, o_value_37, o_value_38, o_value_39, o_value_40, o_value_41,
     o_value_42, o_value_43, o_value_44, o_value_45, o_value_46, o_value_47, o_value_48,
     o_value_49, o_value_50, o_value_51, o_value_52, o_value_53, o_value_54, o_value_55,
     o_value_56, o_value_57, o_value_58, o_value_59, o_value_60, o_value_61, o_value_62,
     o_value_63});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  // 打包次序 = golden 端口声明顺序，先声明的在高位。
  assign payload_in =
    {i_value_0, i_value_1, i_value_2, i_value_3, i_value_4, i_value_5, i_value_6,
     i_value_7, i_value_8, i_value_9, i_value_10, i_value_11, i_value_12, i_value_13,
     i_value_14, i_value_15, i_value_16, i_value_17, i_value_18, i_value_19, i_value_20,
     i_value_21, i_value_22, i_value_23, i_value_24, i_value_25, i_value_26, i_value_27,
     i_value_28, i_value_29, i_value_30, i_value_31, i_value_32, i_value_33, i_value_34,
     i_value_35, i_value_36, i_value_37, i_value_38, i_value_39, i_value_40, i_value_41,
     i_value_42, i_value_43, i_value_44, i_value_45, i_value_46, i_value_47, i_value_48,
     i_value_49, i_value_50, i_value_51, i_value_52, i_value_53, i_value_54, i_value_55,
     i_value_56, i_value_57, i_value_58, i_value_59, i_value_60, i_value_61, i_value_62,
     i_value_63};

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
     o_value_28, o_value_29, o_value_30, o_value_31, o_value_32, o_value_33, o_value_34,
     o_value_35, o_value_36, o_value_37, o_value_38, o_value_39, o_value_40, o_value_41,
     o_value_42, o_value_43, o_value_44, o_value_45, o_value_46, o_value_47, o_value_48,
     o_value_49, o_value_50, o_value_51, o_value_52, o_value_53, o_value_54, o_value_55,
     o_value_56, o_value_57, o_value_58, o_value_59, o_value_60, o_value_61, o_value_62,
     o_value_63} = payload_out;

endmodule
