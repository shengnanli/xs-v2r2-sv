// =============================================================================
// PipeWithFlush_10 —— 带冲刷的 1 级发射流水（xs_PipeWithFlush_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读）：
//   载荷 WIDTH = 18 位，分 4 个字段；流水级数 STAGES = 1；
//   golden 模块体 = 19 个 reg 位 = 1 级 × (1 个 valid + 18 位载荷)，无子模块；
//   端口 12 个。
//   载荷布局（薄文件按这个顺序拼包，核按这个顺序拆）：
//     高位 -> 低位 = 普通字段 2 个 = 9 位 | robIdx{flag,value} 9 位
//   使用者：后端发射流水 —— 1 级，无冲刷。
//
// 家族形状：STAGES=1：**没有任何 flush 端口** —— 不是被裁剪了，是第 1 级本来就不冲刷
//   （判据要读的条目还在组合输入上，没落进寄存器）。
//
// 结构：golden 同名端口表 -> 按核的约定拼成一根 18 位扁平载荷 -> 设参例化
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

module PipeWithFlush_10(
  input        clock,
  input        reset,
  input        io_enq_valid,
  input        io_enq_bits_robIdx_flag,
  input  [7:0] io_enq_bits_robIdx_value,
  input  [7:0] io_enq_bits_pdest,
  input        io_enq_bits_fpWen,
  output       io_deq_valid,
  output       io_deq_bits_robIdx_flag,
  output [7:0] io_deq_bits_robIdx_value,
  output [7:0] io_deq_bits_pdest,
  output       io_deq_bits_fpWen
);

  localparam int unsigned STAGES          = 1;   // 流水级数 N
  localparam int unsigned PAYLOAD_W       = 18;  // golden 端口表求和
  localparam int unsigned GOLDEN_REG_BITS = 19;   // golden reg 声明求和（含 valid 链）
  localparam int unsigned HAS_ROBIDX      = 1;   // 载荷里有没有 robIdx
  localparam int unsigned LD_CNT          = 0;   // loadDependency 路数
  localparam int unsigned LD_W            = 2;   // 每路位宽

  // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
  localparam int unsigned PORT_BITS_IN = $bits(
    {io_enq_bits_pdest, io_enq_bits_fpWen, io_enq_bits_robIdx_flag,
     io_enq_bits_robIdx_value});
  localparam int unsigned PORT_BITS_OUT = $bits(
    {io_deq_bits_pdest, io_deq_bits_fpWen, io_deq_bits_robIdx_flag,
     io_deq_bits_robIdx_value});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  assign payload_in =
    {io_enq_bits_pdest, io_enq_bits_fpWen, io_enq_bits_robIdx_flag,
     io_enq_bits_robIdx_value};

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
    // golden 没有任何 io_flush_* 端口（STAGES=1，第 1 级不冲刷），
    // 核在这个参数下也不会读它们 —— 一律接常 0，不凭空补 golden 没有的输入。
    .flush_redirect_valid (1'b0),
    .flush_redirect_level (1'b0),
    .flush_redirect_robidx(9'b0),
    .flush_ldcancel       (1'b0),
    .flush_ogfail         (1'b0),
    .enq_valid(io_enq_valid),
    .enq_bits (payload_in),
    .deq_valid(io_deq_valid),
    .deq_bits (payload_out)
  );

  assign
    {io_deq_bits_pdest, io_deq_bits_fpWen, io_deq_bits_robIdx_flag,
     io_deq_bits_robIdx_value} = payload_out;

endmodule
