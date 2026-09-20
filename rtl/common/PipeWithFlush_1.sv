// =============================================================================
// PipeWithFlush_1 —— 带冲刷的 2 级发射流水（xs_PipeWithFlush_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读）：
//   载荷 WIDTH = 59 位，分 8 个字段；流水级数 STAGES = 2；
//   golden 模块体 = 120 个 reg 位 = 2 级 × (1 个 valid + 59 位载荷)，无子模块；
//   端口 28 个。
//   载荷布局（薄文件按这个顺序拼包，核按这个顺序拆）：
//     高位 -> 低位 = 普通字段 3 个 = 44 位 | robIdx{flag,value} 9 位 | loadDependency 3 路 × 2 位（j=0 在最低位）
//   使用者：后端发射流水 —— 2 级，**家族里唯一带 loadDependency 老化与 ldCancel 冲刷的变体**。
//
// 家族形状：STAGES=2：第 2..2 级带冲刷，每级一根专属的 og0Fail。
//   另有 3 路 ldCancel × loadDependency 冲刷，且 loadDependency
//   每前移一级左移一位（老化）—— 全家族只有本变体有这一路。
//
// 结构：golden 同名端口表 -> 按核的约定拼成一根 59 位扁平载荷 -> 设参例化
//   xs_PipeWithFlush_core（冲刷判据、环形 robIdx 比较、loadDependency 老化都在
//   xs_PipeWithFlush_core.sv 里讲）-> 拆包回 golden 的 io_deq_bits_* 端口。
//   本层只做拼包/拆包与 flush 端口改名。
//   PAYLOAD_W 与 GOLDEN_REG_BITS 是两条**各自独立**从 golden 抽出来的事实
//   （前者来自端口表求和，后者来自 reg 声明），核里的
//   STAGES*(1+PAYLOAD_W) == GOLDEN_REG_BITS 把两者对上；
//   PORT_BITS_IN/OUT 再用 $bits(golden 端口拼接) 把端口表本身对一遍。
//   任何一处抄错，time 0 直接 $fatal。
// 自动生成：verif/ut/PipeWithFlush/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module PipeWithFlush_1(
  input         clock,
  input         reset,
  input         io_flush_redirect_valid,
  input         io_flush_redirect_bits_robIdx_flag,
  input  [7:0]  io_flush_redirect_bits_robIdx_value,
  input         io_flush_redirect_bits_level,
  input         io_flush_ldCancel_0_ld2Cancel,
  input         io_flush_ldCancel_1_ld2Cancel,
  input         io_flush_ldCancel_2_ld2Cancel,
  input         io_flush_og0Fail,
  input         io_enq_valid,
  input  [34:0] io_enq_bits_fuType,
  input         io_enq_bits_robIdx_flag,
  input  [7:0]  io_enq_bits_robIdx_value,
  input  [7:0]  io_enq_bits_pdest,
  input         io_enq_bits_rfWen,
  input  [1:0]  io_enq_bits_loadDependency_0,
  input  [1:0]  io_enq_bits_loadDependency_1,
  input  [1:0]  io_enq_bits_loadDependency_2,
  output        io_deq_valid,
  output [34:0] io_deq_bits_fuType,
  output        io_deq_bits_robIdx_flag,
  output [7:0]  io_deq_bits_robIdx_value,
  output [7:0]  io_deq_bits_pdest,
  output        io_deq_bits_rfWen,
  output [1:0]  io_deq_bits_loadDependency_0,
  output [1:0]  io_deq_bits_loadDependency_1,
  output [1:0]  io_deq_bits_loadDependency_2
);

  localparam int unsigned STAGES          = 2;   // 流水级数 N
  localparam int unsigned PAYLOAD_W       = 59;  // golden 端口表求和
  localparam int unsigned GOLDEN_REG_BITS = 120;   // golden reg 声明求和（含 valid 链）
  localparam int unsigned HAS_ROBIDX      = 1;   // 载荷里有没有 robIdx
  localparam int unsigned LD_CNT          = 3;   // loadDependency 路数
  localparam int unsigned LD_W            = 2;   // 每路位宽

  // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
  localparam int unsigned PORT_BITS_IN = $bits(
    {io_enq_bits_fuType, io_enq_bits_pdest, io_enq_bits_rfWen, io_enq_bits_robIdx_flag,
     io_enq_bits_robIdx_value, io_enq_bits_loadDependency_2, io_enq_bits_loadDependency_1,
     io_enq_bits_loadDependency_0});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {io_deq_bits_fuType, io_deq_bits_pdest, io_deq_bits_rfWen, io_deq_bits_robIdx_flag,
     io_deq_bits_robIdx_value, io_deq_bits_loadDependency_2, io_deq_bits_loadDependency_1,
     io_deq_bits_loadDependency_0});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  assign payload_in =
    {io_enq_bits_fuType, io_enq_bits_pdest, io_enq_bits_rfWen, io_enq_bits_robIdx_flag,
     io_enq_bits_robIdx_value, io_enq_bits_loadDependency_2, io_enq_bits_loadDependency_1,
     io_enq_bits_loadDependency_0};

  xs_PipeWithFlush_core #(
    .WIDTH          (PAYLOAD_W),
    .STAGES         (STAGES),
    .HAS_ROBIDX     (HAS_ROBIDX),
    .LD_CNT         (LD_CNT),
    .LD_W           (LD_W),
    .GOLDEN_REG_BITS(GOLDEN_REG_BITS),
    .PORT_BITS_IN   (PORT_BITS_IN),
    .PORT_BITS_OUT  (PORT_BITS_OUT)
  ) u_core (
    .clock(clock),
    .reset(reset),
    .flush_redirect_valid (io_flush_redirect_valid),
    .flush_redirect_level (io_flush_redirect_bits_level),
    .flush_redirect_robidx({io_flush_redirect_bits_robIdx_flag, io_flush_redirect_bits_robIdx_value}),
    .flush_ldcancel       ({io_flush_ldCancel_2_ld2Cancel, io_flush_ldCancel_1_ld2Cancel, io_flush_ldCancel_0_ld2Cancel}),
    // 位 k-2 给第 k 级：bit0=og0Fail 管第 2 级，依次类推
    .flush_ogfail         ({io_flush_og0Fail}),
    .enq_valid(io_enq_valid),
    .enq_bits (payload_in),
    .deq_valid(io_deq_valid),
    .deq_bits (payload_out)
  );

  assign
    {io_deq_bits_fuType, io_deq_bits_pdest, io_deq_bits_rfWen, io_deq_bits_robIdx_flag,
     io_deq_bits_robIdx_value, io_deq_bits_loadDependency_2, io_deq_bits_loadDependency_1,
     io_deq_bits_loadDependency_0} = payload_out;

endmodule
