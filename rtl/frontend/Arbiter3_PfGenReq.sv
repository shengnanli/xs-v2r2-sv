// =============================================================================
// Arbiter3_PfGenReq —— SMS 预取器 s4 级三路"区域预取生成请求"的汇流
//
// 在哪一层：MemBlock 的 SMS 预取器（PatternHistoryTable 内，mem/prefetch/SMSPrefetcher.scala
//   `pf_gen_req_arb = Module(new Arbiter(new PfGenReq, 3))`）。PHT 查中一个模式后，在 s4 级最多同时产生
//   三份 PfGenReq：第 0 路 = 当前区域，第 1 路 = 向上相邻区域（incr），第 2 路 = 向下相邻区域（decr）。
// 语义：Chisel Arbiter —— 固定优先级、编号小者优先、纯组合；一路都没请求时出口给第 2 路的载荷。
// ★端口面被 firtool 削过★：
//   · 下游（pf_gen_req 队列）恒 ready，于是 io_out_ready 与 io_in_0_ready（= out_ready）都被删掉；
//     核的 out_ready 接 1'b1，in_ready 最高位（第 0 路）悬空，端口数恒等式里把这两根加回去。
//   · 第 0 路的 paddr_valid 在 Scala 里写死 true.B、三路的 decr_mode 写死 false/false/true.B，
//     这些端口都被删了；拼载荷时在原位置填常量，于是 golden 里出现
//     `paddr_valid = v0 | (v1 ? p1 : p2)`、`decr_mode = ~v0 & ~v1` 这样的式子。
//   · alias_bits 字段下游不用，整列被删，载荷里也没有它。
// 结构：golden 端口 -> 拼成 3 路等宽载荷 -> 共享核 xs_FixedPriorityArbiter_core（rtl/frontend，已签核）-> 拆回端口。
// golden 对照：G1-canonical/golden-rtl/Arbiter3_PfGenReq.sv（132 行 / 22 端口）
// =============================================================================
module Arbiter3_PfGenReq (
  input  logic io_in_0_valid,
  input  logic [10:0] io_in_0_bits_region_tag,
  input  logic [39:0] io_in_0_bits_region_addr,
  input  logic [15:0] io_in_0_bits_region_bits,
  output logic io_in_1_ready,
  input  logic io_in_1_valid,
  input  logic [10:0] io_in_1_bits_region_tag,
  input  logic [39:0] io_in_1_bits_region_addr,
  input  logic [15:0] io_in_1_bits_region_bits,
  input  logic io_in_1_bits_paddr_valid,
  output logic io_in_2_ready,
  input  logic io_in_2_valid,
  input  logic [10:0] io_in_2_bits_region_tag,
  input  logic [39:0] io_in_2_bits_region_addr,
  input  logic [15:0] io_in_2_bits_region_bits,
  input  logic io_in_2_bits_paddr_valid,
  output logic io_out_valid,
  output logic [10:0] io_out_bits_region_tag,
  output logic [39:0] io_out_bits_region_addr,
  output logic [15:0] io_out_bits_region_bits,
  output logic io_out_bits_paddr_valid,
  output logic io_out_bits_decr_mode
);

  localparam int unsigned NUM_IN = 3;
  localparam int unsigned WIDTH  = 69;   // 每路载荷：region_tag(11) + region_addr(40) + region_bits(16) + paddr_valid(1) + decr_mode(1)

  // ---------------------------------------------------------------------------
  // 1. 入口拼接：位 NUM_IN-1 = 第 0 路（优先级最高），与核的 in_valid 位序一致；
  //    每路载荷按 io_out_bits_* 的端口顺序 MSB 优先拼，缺端口的字段在原位置填常量
  // ---------------------------------------------------------------------------
  logic [NUM_IN-1:0]       in_valid_vec;
  logic [NUM_IN-1:0]       in_ready_vec;
  logic [NUM_IN*WIDTH-1:0] in_bits_flat;
  logic [WIDTH-1:0]        out_bits_flat;

  assign in_valid_vec = {io_in_0_valid, io_in_1_valid, io_in_2_valid};
  assign in_bits_flat = {
    {io_in_0_bits_region_tag,
     io_in_0_bits_region_addr,
     io_in_0_bits_region_bits,
     1'b1                      /* 当前区域：paddr 恒有效 */,
     1'b0                      /* decr_mode：只有第 2 路（向下相邻区域）为 1 */},
    {io_in_1_bits_region_tag,
     io_in_1_bits_region_addr,
     io_in_1_bits_region_bits,
     io_in_1_bits_paddr_valid,
     1'b0                      /* decr_mode：只有第 2 路（向下相邻区域）为 1 */},
    {io_in_2_bits_region_tag,
     io_in_2_bits_region_addr,
     io_in_2_bits_region_bits,
     io_in_2_bits_paddr_valid,
     1'b1                      /* decr_mode：只有第 2 路（向下相邻区域）为 1 */}
  };

  // ---------------------------------------------------------------------------
  // 2. 仲裁核（固定优先级，纯组合；语义见 xs_FixedPriorityArbiter_core 文件头）
  // ---------------------------------------------------------------------------
  xs_FixedPriorityArbiter_core #(
    .WIDTH            (WIDTH),
    .NUM_IN           (NUM_IN),
    .PORT_BITS_OUT    ($bits({io_out_bits_region_tag, io_out_bits_region_addr, io_out_bits_region_bits, io_out_bits_paddr_valid, io_out_bits_decr_mode})),
    .PORT_BITS_LAST_IN($bits({io_in_2_bits_region_tag, io_in_2_bits_region_addr, io_in_2_bits_region_bits, io_in_2_bits_paddr_valid}) + 1  /* + 常量 decr_mode */),
    .GOLDEN_PORTS     (22 + 2  /* 现存端口 + firtool 删掉的 io_in_0_ready、io_out_ready */),
    .GOLDEN_BITS_PORTS(16)
  ) u_core (
    .in_valid (in_valid_vec),
    .in_ready (in_ready_vec),
    .in_bits  (in_bits_flat),
    .out_ready(1'b1),
    .out_valid(io_out_valid),
    .out_bits (out_bits_flat)
  );

  // ---------------------------------------------------------------------------
  // 3. 出口拆分与各路 ready
  // ---------------------------------------------------------------------------
  assign io_in_1_ready = in_ready_vec[NUM_IN-1-1];
  assign io_in_2_ready = in_ready_vec[NUM_IN-1-2];
  assign {io_out_bits_region_tag,
          io_out_bits_region_addr,
          io_out_bits_region_bits,
          io_out_bits_paddr_valid,
          io_out_bits_decr_mode} = out_bits_flat;
endmodule
