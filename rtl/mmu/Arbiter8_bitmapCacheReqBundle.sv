// Arbiter8_bitmapCacheReqBundle.sv —— Bitmap 检查单元查 bitmap cache 的 8 选 1 请求仲裁器
//                                    （xs_FixedPriorityArbiter_core 家族的一个变体）
//
// 位置：L2TLB 的 Bitmap（cache/mmu/BitmapCheck.scala:161
//   `cache_req_arb = Module(new Arbiter(new bitmapCacheReqBundle(), llptwsize + 2))`）。
//   Bitmap 有 8 个表项（llptwsize=6，+2），处于"要查 bitmap cache"状态的表项各发一路请求，
//   本仲裁器按固定优先级（下标小的赢）挑一个送 BitmapCache；载荷 = {order, tag}：
//   tag = 表项的 ppn，order = 表项下标 i（Scala `bits.order := i.U`，常量，firtool 折进本模块）。
// 语义：chisel3 Arbiter，lowest-index-wins、无锁定、纯组合（核见 rtl/frontend/xs_FixedPriorityArbiter_core.sv）。
//
// 本变体的参数与规模（按 G1 golden 现读）：
//   入口数 NUM_IN = 8；golden 148 行 / 20 端口；纯组合，无寄存器、无子模块。
//   ★少了 9 根 ready、多了 1 根 chosen★：Bitmap 自己用 io_chosen 和父级的 cache.req.ready 判握手，
//     本模块的 io_in_*_ready 没人读、被 firtool 删掉；io_out_ready 只驱动这些 ready，也随之被删。
//     核的 out_ready 因此接常量 1（不影响任何现存输出），in_ready 悬空。
//   ★io_chosen 当作载荷的一个字段★：chosen 就是胜出路的下标，和 order 一样是"每路一个常量"，
//     所以把 3 位下标 k 拼进第 k 路的载荷，让核按同一条优先级链选出来 —— 一路都没请求时核给
//     第 7 路的载荷，chosen=7、order=7，正是 golden 三元链最后的兜底分支（{2'h3, ~valid6} 等）。
//   载荷 WIDTH = order 8 + tag 36 + chosen 3 = 47 位。
//   端口数恒等式（核里自检）：20 现存 + 9 根被删的 ready − 1 根 chosen（不是 bits 端口）
//     = 28 = 2×8 + 2 + 10（bits 端口：8 路 tag + 出口 order/tag）。

module Arbiter8_bitmapCacheReqBundle (
  input  logic        io_in_0_valid,
  input  logic [35:0] io_in_0_bits_tag,
  input  logic        io_in_1_valid,
  input  logic [35:0] io_in_1_bits_tag,
  input  logic        io_in_2_valid,
  input  logic [35:0] io_in_2_bits_tag,
  input  logic        io_in_3_valid,
  input  logic [35:0] io_in_3_bits_tag,
  input  logic        io_in_4_valid,
  input  logic [35:0] io_in_4_bits_tag,
  input  logic        io_in_5_valid,
  input  logic [35:0] io_in_5_bits_tag,
  input  logic        io_in_6_valid,
  input  logic [35:0] io_in_6_bits_tag,
  input  logic        io_in_7_valid,
  input  logic [35:0] io_in_7_bits_tag,
  output logic        io_out_valid,
  output logic [7:0]  io_out_bits_order,
  output logic [35:0] io_out_bits_tag,
  output logic [2:0]  io_chosen
);

  typedef struct packed {
    logic [7:0]  order;    // 表项下标（bitmapCacheReqBundle.order，宽 llptwsize+2）
    logic [35:0] tag;      // 表项的 ppn
    logic [2:0]  chosen;   // 同一个下标，给 io_chosen
  } cache_req_t;

  localparam int unsigned NUM_IN = 8;
  localparam int unsigned WIDTH  = $bits(cache_req_t);   // 47

  logic [NUM_IN-1:0][35:0] lane_tag;
  logic [NUM_IN-1:0]       lane_valid;

  assign lane_tag   = {io_in_7_bits_tag, io_in_6_bits_tag, io_in_5_bits_tag, io_in_4_bits_tag,
                       io_in_3_bits_tag, io_in_2_bits_tag, io_in_1_bits_tag, io_in_0_bits_tag};
  assign lane_valid = {io_in_7_valid, io_in_6_valid, io_in_5_valid, io_in_4_valid,
                       io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid};

  // ---- 核的约定：位 NUM_IN-1（最高段）= 第 0 路（优先级最高）----
  logic [NUM_IN-1:0]       core_valid;
  logic [NUM_IN-1:0]       core_ready_unused;   // golden 无 in_ready 端口
  logic [NUM_IN*WIDTH-1:0] core_bits;
  cache_req_t              out_req;

  for (genvar k = 0; k < NUM_IN; k++) begin : g_lane
    cache_req_t lane;
    assign lane.order  = 8'(k);
    assign lane.tag    = lane_tag[k];
    assign lane.chosen = 3'(k);
    assign core_valid[NUM_IN-1-k]                 = lane_valid[k];
    assign core_bits[(NUM_IN-1-k)*WIDTH +: WIDTH] = lane;
  end

  xs_FixedPriorityArbiter_core #(
    .WIDTH            (WIDTH),
    .NUM_IN           (NUM_IN),
    .PORT_BITS_OUT    ($bits({io_out_bits_order, io_out_bits_tag, io_chosen})),
    .PORT_BITS_LAST_IN($bits({8'h7, io_in_7_bits_tag, 3'h7})),
    .GOLDEN_PORTS     (20 + 9 - 1),
    .GOLDEN_BITS_PORTS(10)
  ) u_core (
    .in_valid (core_valid),
    .in_ready (core_ready_unused),
    .in_bits  (core_bits),
    .out_ready(1'b1),
    .out_valid(io_out_valid),
    .out_bits (out_req)
  );

  assign io_out_bits_order = out_req.order;
  assign io_out_bits_tag   = out_req.tag;
  assign io_chosen         = out_req.chosen;

endmodule
