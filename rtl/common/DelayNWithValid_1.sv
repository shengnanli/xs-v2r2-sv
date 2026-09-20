// =============================================================================
// DelayNWithValid_1 —— 带 valid 使能的 2 级打拍链（xs_DelayNWithValid_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   载荷 WIDTH = 60 位，分 19 个字段；数据级数 STAGES = 2；
//   valid 链保留 1 个寄存器；
//   golden 模块体 = 121 个 reg 位 = 1 个 valid 位（异步复位）
//     + 2 级 × 60 位数据（无复位），无子模块；
//   端口 41 个 = clock + reset + io_in_valid + 19 入 + 19 出。
//   载荷字段：isCall=1b, isRet=1b, isJalr=1b, valid=1b, brSlots_0_offset=4b …共 19 个字段，明细见端口表。
//   使用者：FTB —— FTBEntry（分支槽 / 尾槽 / 预取地址 / strong_bias）打两拍。
//
// 家族形状：V = STAGES-1 = 1：golden **没有** io_out_valid，valid 链最后一级没人读、
//   被 firtool 消掉；剩下的 1 级还要给数据级当使能，所以留着。
//
// 结构：golden 同名端口表 -> 打包成一根 60 位扁平载荷 -> 设参例化
//   xs_DelayNWithValid_core（使能与复位语义、不变式都在 xs_DelayNWithValid_core.sv
//   里讲）-> 拆包回 golden 的 io_out_bits_* 端口。本层只做拼包/拆包。
//   PAYLOAD_W / GOLDEN_REG_BITS 是两条**各自独立**从 golden 抽出来的事实
//   （前者来自端口表求和，后者来自 reg 声明），核里的守恒等式
//   VALID_CHAIN + STAGES*PAYLOAD_W == GOLDEN_REG_BITS 把两者对上；
//   PORT_BITS_IN/OUT 再用 $bits(golden 端口拼接) 把端口表本身对一遍。
//   任何一处抄错，time 0 直接 $fatal。
// 自动生成：verif/ut/DelayNWithValid/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module DelayNWithValid_1(
  input         clock,
  input         reset,
  input         io_in_bits_isCall,
  input         io_in_bits_isRet,
  input         io_in_bits_isJalr,
  input         io_in_bits_valid,
  input  [3:0]  io_in_bits_brSlots_0_offset,
  input         io_in_bits_brSlots_0_sharing,
  input         io_in_bits_brSlots_0_valid,
  input  [11:0] io_in_bits_brSlots_0_lower,
  input  [1:0]  io_in_bits_brSlots_0_tarStat,
  input  [3:0]  io_in_bits_tailSlot_offset,
  input         io_in_bits_tailSlot_sharing,
  input         io_in_bits_tailSlot_valid,
  input  [19:0] io_in_bits_tailSlot_lower,
  input  [1:0]  io_in_bits_tailSlot_tarStat,
  input  [3:0]  io_in_bits_pftAddr,
  input         io_in_bits_carry,
  input         io_in_bits_last_may_be_rvi_call,
  input         io_in_bits_strong_bias_0,
  input         io_in_bits_strong_bias_1,
  input         io_in_valid,
  output        io_out_bits_isCall,
  output        io_out_bits_isRet,
  output        io_out_bits_isJalr,
  output        io_out_bits_valid,
  output [3:0]  io_out_bits_brSlots_0_offset,
  output        io_out_bits_brSlots_0_sharing,
  output        io_out_bits_brSlots_0_valid,
  output [11:0] io_out_bits_brSlots_0_lower,
  output [1:0]  io_out_bits_brSlots_0_tarStat,
  output [3:0]  io_out_bits_tailSlot_offset,
  output        io_out_bits_tailSlot_sharing,
  output        io_out_bits_tailSlot_valid,
  output [19:0] io_out_bits_tailSlot_lower,
  output [1:0]  io_out_bits_tailSlot_tarStat,
  output [3:0]  io_out_bits_pftAddr,
  output        io_out_bits_carry,
  output        io_out_bits_last_may_be_rvi_call,
  output        io_out_bits_strong_bias_0,
  output        io_out_bits_strong_bias_1
);

  localparam int unsigned STAGES          = 2;   // 数据级数 n
  localparam int unsigned VALID_CHAIN     = 1;   // 保留下来的 valid 寄存器个数
  localparam int unsigned PAYLOAD_W       = 60;  // golden 端口表求和
  localparam int unsigned GOLDEN_REG_BITS = 121;   // golden reg 声明求和（含 valid 链）

  // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
  localparam int unsigned PORT_BITS_IN = $bits(
    {io_in_bits_isCall, io_in_bits_isRet, io_in_bits_isJalr, io_in_bits_valid,
     io_in_bits_brSlots_0_offset, io_in_bits_brSlots_0_sharing,
     io_in_bits_brSlots_0_valid, io_in_bits_brSlots_0_lower, io_in_bits_brSlots_0_tarStat,
     io_in_bits_tailSlot_offset, io_in_bits_tailSlot_sharing, io_in_bits_tailSlot_valid,
     io_in_bits_tailSlot_lower, io_in_bits_tailSlot_tarStat, io_in_bits_pftAddr,
     io_in_bits_carry, io_in_bits_last_may_be_rvi_call, io_in_bits_strong_bias_0,
     io_in_bits_strong_bias_1});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {io_out_bits_isCall, io_out_bits_isRet, io_out_bits_isJalr, io_out_bits_valid,
     io_out_bits_brSlots_0_offset, io_out_bits_brSlots_0_sharing,
     io_out_bits_brSlots_0_valid, io_out_bits_brSlots_0_lower,
     io_out_bits_brSlots_0_tarStat, io_out_bits_tailSlot_offset,
     io_out_bits_tailSlot_sharing, io_out_bits_tailSlot_valid, io_out_bits_tailSlot_lower,
     io_out_bits_tailSlot_tarStat, io_out_bits_pftAddr, io_out_bits_carry,
     io_out_bits_last_may_be_rvi_call, io_out_bits_strong_bias_0,
     io_out_bits_strong_bias_1});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  assign payload_in =
    {io_in_bits_isCall, io_in_bits_isRet, io_in_bits_isJalr, io_in_bits_valid,
     io_in_bits_brSlots_0_offset, io_in_bits_brSlots_0_sharing,
     io_in_bits_brSlots_0_valid, io_in_bits_brSlots_0_lower, io_in_bits_brSlots_0_tarStat,
     io_in_bits_tailSlot_offset, io_in_bits_tailSlot_sharing, io_in_bits_tailSlot_valid,
     io_in_bits_tailSlot_lower, io_in_bits_tailSlot_tarStat, io_in_bits_pftAddr,
     io_in_bits_carry, io_in_bits_last_may_be_rvi_call, io_in_bits_strong_bias_0,
     io_in_bits_strong_bias_1};

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
    // 本变体的 golden 没有 io_out_valid 端口，核的 out_valid 悬空 ——
    // 照抄 golden 的端口表，不凭空补一个 golden 没有的输出。
    .out_valid()
  );

  assign
    {io_out_bits_isCall, io_out_bits_isRet, io_out_bits_isJalr, io_out_bits_valid,
     io_out_bits_brSlots_0_offset, io_out_bits_brSlots_0_sharing,
     io_out_bits_brSlots_0_valid, io_out_bits_brSlots_0_lower,
     io_out_bits_brSlots_0_tarStat, io_out_bits_tailSlot_offset,
     io_out_bits_tailSlot_sharing, io_out_bits_tailSlot_valid, io_out_bits_tailSlot_lower,
     io_out_bits_tailSlot_tarStat, io_out_bits_pftAddr, io_out_bits_carry,
     io_out_bits_last_may_be_rvi_call, io_out_bits_strong_bias_0,
     io_out_bits_strong_bias_1} = payload_out;

endmodule
