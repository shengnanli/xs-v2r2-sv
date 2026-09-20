// =============================================================================
// DelayN_333 —— 固定级数的载荷打拍链（xs_DelayN_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   延迟级数 STAGES = 2；载荷宽度 = 14 位，分 5 个字段；
//   golden 模块体 = 28 个 reg 位（2 级 × 14 位），无复位 / 无使能 / 无子模块；
//   端口 11 个 = clock + 5 个 io_in_* + 5 个 io_out_*。
//   载荷字段：l2_pf_master_en=1b, l2_pf_recv_en=1b, l2_pbop_en=1b, l2_vbop_en=1b, l2_pf_delay_latency=10b。
//   使用者：MemBlock —— 14 位控制包打两拍。
//
// 结构：golden 同名端口表 -> 打包成一根 14 位扁平载荷 -> 设参例化
//   xs_DelayN_core（核体见 xs_DelayN_core.sv，打拍语义与不变式都在那里讲）
//   -> 拆包回 golden 的 io_out_* 端口。本层只做拼包/拆包。
//   PORT_BITS_IN/OUT 用 $bits(golden 端口拼接) 算出来传给核：任何一个端口的位宽
//   抄错，拼接总位数就变，time 0 直接 $fatal（本轮已发生 3 次位宽静默错事故）。
// 自动生成：verif/ut/DelayN/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module DelayN_333(
  input        clock,
  input        io_in_l2_pf_master_en,
  input        io_in_l2_pf_recv_en,
  input        io_in_l2_pbop_en,
  input        io_in_l2_vbop_en,
  input  [9:0] io_in_l2_pf_delay_latency,
  output       io_out_l2_pf_master_en,
  output       io_out_l2_pf_recv_en,
  output       io_out_l2_pbop_en,
  output       io_out_l2_vbop_en,
  output [9:0] io_out_l2_pf_delay_latency
);

  localparam int unsigned STAGES          = 2;
  localparam int unsigned GOLDEN_REG_BITS = 28;   // golden 里 reg 位数总和
  localparam int unsigned PAYLOAD_W       = GOLDEN_REG_BITS / STAGES;

  // 端口表事实：golden 全部输入 / 输出端口拼起来各有多少位（$bits 只认端口声明）
  localparam int unsigned PORT_BITS_IN = $bits(
    {io_in_l2_pf_master_en, io_in_l2_pf_recv_en, io_in_l2_pbop_en, io_in_l2_vbop_en,
     io_in_l2_pf_delay_latency});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {io_out_l2_pf_master_en, io_out_l2_pf_recv_en, io_out_l2_pbop_en, io_out_l2_vbop_en,
     io_out_l2_pf_delay_latency});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  assign payload_in =
    {io_in_l2_pf_master_en, io_in_l2_pf_recv_en, io_in_l2_pbop_en, io_in_l2_vbop_en,
     io_in_l2_pf_delay_latency};

  xs_DelayN_core #(
    .WIDTH          (PAYLOAD_W),
    .STAGES         (STAGES),
    .GOLDEN_REG_BITS(GOLDEN_REG_BITS),
    .PORT_BITS_IN   (PORT_BITS_IN),
    .PORT_BITS_OUT  (PORT_BITS_OUT),
    .GOLDEN_HAS_CLOCK(1)
  ) u_core (
    .clock(clock),
    .d_in (payload_in),
    .d_out(payload_out)
  );

  assign
    {io_out_l2_pf_master_en, io_out_l2_pf_recv_en, io_out_l2_pbop_en, io_out_l2_vbop_en,
     io_out_l2_pf_delay_latency} = payload_out;

endmodule
