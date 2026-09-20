// =============================================================================
// PipeWithFlush_7 —— 带冲刷的 2 级发射流水（xs_PipeWithFlush_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读）：
//   载荷 WIDTH = 55 位，分 7 个字段；流水级数 STAGES = 2；
//   golden 模块体 = 112 个 reg 位 = 2 级 × (1 个 valid + 55 位载荷)，无子模块；
//   端口 23 个。
//   载荷布局（薄文件按这个顺序拼包，核按这个顺序拆）：
//     高位 -> 低位 = 普通字段 5 个 = 46 位 | robIdx{flag,value} 9 位
//   使用者：后端发射流水 —— 2 级，redirect + og0Fail 冲刷。
//
// 家族形状：STAGES=2：第 2..2 级带冲刷，每级一根专属的 og0Fail。
//   没有 loadDependency，故没有 ldCancel 那一路。
//
// 结构：golden 同名端口表 -> 按核的约定拼成一根 55 位扁平载荷 -> 设参例化
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

module PipeWithFlush_7(
  input         clock,
  input         reset,
  input         io_flush_redirect_valid,
  input         io_flush_redirect_bits_robIdx_flag,
  input  [7:0]  io_flush_redirect_bits_robIdx_value,
  input         io_flush_redirect_bits_level,
  input         io_flush_og0Fail,
  input         io_enq_valid,
  input  [34:0] io_enq_bits_fuType,
  input         io_enq_bits_robIdx_flag,
  input  [7:0]  io_enq_bits_robIdx_value,
  input  [7:0]  io_enq_bits_pdest,
  input         io_enq_bits_fpWen,
  input         io_enq_bits_vecWen,
  input         io_enq_bits_v0Wen,
  output        io_deq_valid,
  output [34:0] io_deq_bits_fuType,
  output        io_deq_bits_robIdx_flag,
  output [7:0]  io_deq_bits_robIdx_value,
  output [7:0]  io_deq_bits_pdest,
  output        io_deq_bits_fpWen,
  output        io_deq_bits_vecWen,
  output        io_deq_bits_v0Wen
);

  localparam int unsigned STAGES          = 2;   // 流水级数 N
  localparam int unsigned PAYLOAD_W       = 55;  // golden 端口表求和
  localparam int unsigned GOLDEN_REG_BITS = 112;   // golden reg 声明求和（含 valid 链）
  localparam int unsigned HAS_ROBIDX      = 1;   // 载荷里有没有 robIdx
  localparam int unsigned LD_CNT          = 0;   // loadDependency 路数
  localparam int unsigned LD_W            = 2;   // 每路位宽

  // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
  localparam int unsigned PORT_BITS_IN = $bits(
    {io_enq_bits_fuType, io_enq_bits_pdest, io_enq_bits_fpWen, io_enq_bits_vecWen,
     io_enq_bits_v0Wen, io_enq_bits_robIdx_flag, io_enq_bits_robIdx_value});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {io_deq_bits_fuType, io_deq_bits_pdest, io_deq_bits_fpWen, io_deq_bits_vecWen,
     io_deq_bits_v0Wen, io_deq_bits_robIdx_flag, io_deq_bits_robIdx_value});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  assign payload_in =
    {io_enq_bits_fuType, io_enq_bits_pdest, io_enq_bits_fpWen, io_enq_bits_vecWen,
     io_enq_bits_v0Wen, io_enq_bits_robIdx_flag, io_enq_bits_robIdx_value};

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
    // 本变体没有 loadDependency，也就没有 ldCancel 那一路；
    // 核的这个输入是 1 位占位（SV 不允许零宽端口），接常 0。
    .flush_ldcancel       (1'b0),
    // 位 k-2 给第 k 级：bit0=og0Fail 管第 2 级，依次类推
    .flush_ogfail         ({io_flush_og0Fail}),
    .enq_valid(io_enq_valid),
    .enq_bits (payload_in),
    .deq_valid(io_deq_valid),
    .deq_bits (payload_out)
  );

  assign
    {io_deq_bits_fuType, io_deq_bits_pdest, io_deq_bits_fpWen, io_deq_bits_vecWen,
     io_deq_bits_v0Wen, io_deq_bits_robIdx_flag, io_deq_bits_robIdx_value} = payload_out;

endmodule
