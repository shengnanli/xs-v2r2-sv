// =============================================================================
// Arbiter4_PrefetchReq —— L2 预取器各来源的预取请求进 pftQueue 前的汇流
//
// 在哪一层：CoupledL2 的 Prefetcher（coupledL2/prefetch/Prefetcher.scala
//   `pftQueueEnqArb = Module(new Arbiter(new PrefetchReq, SRC_NUM))`，SRC_NUM = 4）。
//   四路固定分配：0 = PrefetchReceiver（L1 发来的 SMS/stream 等预取），1 = VBOP，2 = PBOP，3 = TP。
//   本配置没有 TP 预取器，第 3 路 valid 与载荷在 Scala 里被默认赋成 0。
// 语义：Chisel Arbiter —— 固定优先级、编号小者优先、纯组合；一路都没请求时出口给第 3 路的载荷（全 0）。
// ★端口面被 firtool 削过★（golden 25 个端口，Chisel 端口数恒等式需要 29 个）：
//   · pftQueue 入口恒 ready：io_out_ready 与 io_in_0_ready 被删；核的 out_ready 接 1'b1；
//   · 第 3 路的 ready/valid 及全部载荷端口被删：valid 填 0、载荷填 0；
//   · 第 0 路没有 vaddr/needT/source 端口（Receiver 不填），载荷里填 0；
//   · VBOP/PBOP 的 pfSource 在各自模块里是常量（8 / 9），端口被删，载荷里填常量，
//     所以 golden 写成 `pfSource = v0 ? p0 : v1 ? 8 : v2 ? 9 : 0`。
// 结构：golden 端口 -> 拼成 4 路等宽载荷 -> 共享核 xs_FixedPriorityArbiter_core（rtl/frontend，已签核）-> 拆回端口。
// golden 对照：G1-canonical/golden-rtl/Arbiter4_PrefetchReq.sv（143 行 / 25 端口）
// =============================================================================
module Arbiter4_PrefetchReq (
  input  logic io_in_0_valid,
  input  logic [32:0] io_in_0_bits_tag,
  input  logic [8:0] io_in_0_bits_set,
  input  logic [4:0] io_in_0_bits_pfSource,
  output logic io_in_1_ready,
  input  logic io_in_1_valid,
  input  logic [32:0] io_in_1_bits_tag,
  input  logic [8:0] io_in_1_bits_set,
  input  logic [43:0] io_in_1_bits_vaddr,
  input  logic io_in_1_bits_needT,
  input  logic [6:0] io_in_1_bits_source,
  output logic io_in_2_ready,
  input  logic io_in_2_valid,
  input  logic [32:0] io_in_2_bits_tag,
  input  logic [8:0] io_in_2_bits_set,
  input  logic [43:0] io_in_2_bits_vaddr,
  input  logic io_in_2_bits_needT,
  input  logic [6:0] io_in_2_bits_source,
  output logic io_out_valid,
  output logic [32:0] io_out_bits_tag,
  output logic [8:0] io_out_bits_set,
  output logic [43:0] io_out_bits_vaddr,
  output logic io_out_bits_needT,
  output logic [6:0] io_out_bits_source,
  output logic [4:0] io_out_bits_pfSource
);

  localparam int unsigned NUM_IN = 4;
  localparam int unsigned WIDTH  = 99;   // 每路载荷：tag(33) + set(9) + vaddr(44) + needT(1) + source(7) + pfSource(5)

  // ---------------------------------------------------------------------------
  // 1. 入口拼接：位 NUM_IN-1 = 第 0 路（优先级最高），与核的 in_valid 位序一致；
  //    每路载荷按 io_out_bits_* 的端口顺序 MSB 优先拼，缺端口的字段在原位置填常量
  // ---------------------------------------------------------------------------
  logic [NUM_IN-1:0]       in_valid_vec;
  logic [NUM_IN-1:0]       in_ready_vec;
  logic [NUM_IN*WIDTH-1:0] in_bits_flat;
  logic [WIDTH-1:0]        out_bits_flat;

  assign in_valid_vec = {io_in_0_valid, io_in_1_valid, io_in_2_valid, 1'b0                      /* 第 3 路（TP 预取器）未配置：恒不请求 */};
  assign in_bits_flat = {
    {io_in_0_bits_tag,
     io_in_0_bits_set,
     44'h0                     /* 第 0 路（L1 下发的预取）不带此字段 */,
     1'b0                     /* 第 0 路（L1 下发的预取）不带此字段 */,
     7'h0                     /* 第 0 路（L1 下发的预取）不带此字段 */,
     io_in_0_bits_pfSource},
    {io_in_1_bits_tag,
     io_in_1_bits_set,
     io_in_1_bits_vaddr,
     io_in_1_bits_needT,
     io_in_1_bits_source,
     5'd8                      /* MemReqSource.Prefetch2L2BOP（VBOP） */},
    {io_in_2_bits_tag,
     io_in_2_bits_set,
     io_in_2_bits_vaddr,
     io_in_2_bits_needT,
     io_in_2_bits_source,
     5'd9                      /* MemReqSource.Prefetch2L2PBOP */},
    {33'h0,
     9'h0,
     44'h0,
     1'b0,
     7'h0,
     5'h0}
  };

  // ---------------------------------------------------------------------------
  // 2. 仲裁核（固定优先级，纯组合；语义见 xs_FixedPriorityArbiter_core 文件头）
  // ---------------------------------------------------------------------------
  xs_FixedPriorityArbiter_core #(
    .WIDTH            (WIDTH),
    .NUM_IN           (NUM_IN),
    .PORT_BITS_OUT    ($bits({io_out_bits_tag, io_out_bits_set, io_out_bits_vaddr, io_out_bits_needT, io_out_bits_source, io_out_bits_pfSource})),
    .PORT_BITS_LAST_IN($bits({33'h0, 9'h0, 44'h0, 1'b0, 7'h0, 5'h0})  /* 第 3 路没有任何端口，载荷全是常量 0 */),
    .GOLDEN_PORTS     (25 + 4  /* 现存端口 + 删掉的 io_in_0_ready、io_out_ready、io_in_3_ready、io_in_3_valid */),
    .GOLDEN_BITS_PORTS(19)
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
  assign {io_out_bits_tag,
          io_out_bits_set,
          io_out_bits_vaddr,
          io_out_bits_needT,
          io_out_bits_source,
          io_out_bits_pfSource} = out_bits_flat;
endmodule
