// =============================================================================
// DelayN —— 固定级数的载荷打拍链（xs_DelayN_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   延迟级数 STAGES = 1；载荷宽度 = 5 位，分 5 个字段；
//   golden 模块体 = 5 个 reg 位（1 级 × 5 位），无复位 / 无使能 / 无子模块；
//   端口 11 个 = clock + 5 个 io_in_* + 5 个 io_out_*。
//   载荷字段：ubtb_enable=1b, btb_enable=1b, tage_enable=1b, sc_enable=1b, ras_enable=1b。
//   使用者：Predictor / Composer —— 分支预测各子预测器的使能位打一拍。
//
// 结构：golden 同名端口表 -> 打包成一根 5 位扁平载荷 -> 设参例化
//   xs_DelayN_core（核体见 xs_DelayN_core.sv，打拍语义与不变式都在那里讲）
//   -> 拆包回 golden 的 io_out_* 端口。本层只做拼包/拆包。
//   PORT_BITS_IN/OUT 用 $bits(golden 端口拼接) 算出来传给核：任何一个端口的位宽
//   抄错，拼接总位数就变，time 0 直接 $fatal（本轮已发生 3 次位宽静默错事故）。
// 自动生成：verif/ut/DelayN/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module DelayN(
  input  clock,
  input  io_in_ubtb_enable,
  input  io_in_btb_enable,
  input  io_in_tage_enable,
  input  io_in_sc_enable,
  input  io_in_ras_enable,
  output io_out_ubtb_enable,
  output io_out_btb_enable,
  output io_out_tage_enable,
  output io_out_sc_enable,
  output io_out_ras_enable
);

  localparam int unsigned STAGES          = 1;
  localparam int unsigned GOLDEN_REG_BITS = 5;   // golden 里 reg 位数总和
  localparam int unsigned PAYLOAD_W       = GOLDEN_REG_BITS / STAGES;

  // 端口表事实：golden 全部输入 / 输出端口拼起来各有多少位（$bits 只认端口声明）
  localparam int unsigned PORT_BITS_IN = $bits(
    {io_in_ubtb_enable, io_in_btb_enable, io_in_tage_enable, io_in_sc_enable,
     io_in_ras_enable});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {io_out_ubtb_enable, io_out_btb_enable, io_out_tage_enable, io_out_sc_enable,
     io_out_ras_enable});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  assign payload_in =
    {io_in_ubtb_enable, io_in_btb_enable, io_in_tage_enable, io_in_sc_enable,
     io_in_ras_enable};

  xs_DelayN_core #(
    .WIDTH          (PAYLOAD_W),
    .STAGES         (STAGES),
    .GOLDEN_REG_BITS(GOLDEN_REG_BITS),
    .PORT_BITS_IN   (PORT_BITS_IN),
    .PORT_BITS_OUT  (PORT_BITS_OUT)
  ) u_core (
    .clock(clock),
    .d_in (payload_in),
    .d_out(payload_out)
  );

  assign
    {io_out_ubtb_enable, io_out_btb_enable, io_out_tage_enable, io_out_sc_enable,
     io_out_ras_enable} = payload_out;

endmodule
