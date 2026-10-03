// Arbiter3_bitmapReqBundle.sv —— L2TLB 的 bitmap 检查请求汇流 bitmap_arb：PTW / LLPTW / HPTW 三路并成一路送 Bitmap
//
// L2TLB.scala:488 `bitmap_arb = Module(new Arbiter(new bitmapReqBundle(), 3))`；
// 第 0 路 = PTW，第 1 路 = LLPTW（内部先 RR 仲裁 llptwsize 个条目），第 2 路 = HPTW。
//
// chisel3 Arbiter（3 入口，lowest-index-wins，纯组合）；核是 rtl/frontend/xs_FixedPriorityArbiter_core.sv
// （已签核，语义讲在那里：in_ready[k] = 前面没人请求 && out_ready；一路都没请求时出口给最后一路的载荷）。
// 载荷 = 8 个字段、87 位，按 io_out_bits_* 的 golden 端口顺序 MSB 优先拼。
// ★有的入口缺字段★：上游把它接成常量，firtool 折进本模块并删掉端口；拼载荷时在原位置填常量：
//   第 0 路 id                 = 3'h6  ← PageTableWalker.scala:284 `id := FsmReqID.U`（FsmReqID = llptwsize = 6）
//   第 0 路 way_info           = 4'h0  ← PageTableWalker.scala:287 `way_info := DontCare`（firtool 取 0）
//   第 0 路 hptw_bypassed      = 1'h0  ← PageTableWalker.scala:288 `hptw_bypassed := false.B`
//   第 1 路 level              = 2'h0  ← PageTableWalker.scala:1102 `level := 0.U`
//   第 1 路 hptw_bypassed      = 1'h0  ← PageTableWalker.scala:1104 取自 LLPTW 内部 bitmap_arb 出口，其各入口恒 false，firtool 跨模块传播成常量 0
//   第 2 路 id                 = 3'h7  ← PageTableWalker.scala:1292 `id := HptwReqId.U`（HptwReqId = llptwsize+1 = 7）
//   第 2 路 s2xlate            = 2'h2  ← PageTableWalker.scala:1298 `s2xlate := onlyStage2`（= 2）
// golden 148 行 / 33 端口；本文件由 scripts/gen_arbiter_l2tlb_leaves.py 从 golden 端口表生成（勿手改）。

module Arbiter3_bitmapReqBundle (
  // --------------------------------------------------------------------------
  // 端口表（与 golden 逐名逐宽相同，33 个）
  // --------------------------------------------------------------------------
  output logic io_in_0_ready,
  input  logic io_in_0_valid,
  input  logic [35:0] io_in_0_bits_bmppn,
  input  logic [37:0] io_in_0_bits_vpn,
  input  logic [1:0] io_in_0_bits_level,
  input  logic [1:0] io_in_0_bits_s2xlate,
  input  logic io_in_0_bits_n,
  output logic io_in_1_ready,
  input  logic io_in_1_valid,
  input  logic [35:0] io_in_1_bits_bmppn,
  input  logic [2:0] io_in_1_bits_id,
  input  logic [37:0] io_in_1_bits_vpn,
  input  logic [3:0] io_in_1_bits_way_info,
  input  logic [1:0] io_in_1_bits_s2xlate,
  input  logic io_in_1_bits_n,
  output logic io_in_2_ready,
  input  logic io_in_2_valid,
  input  logic [35:0] io_in_2_bits_bmppn,
  input  logic [37:0] io_in_2_bits_vpn,
  input  logic [1:0] io_in_2_bits_level,
  input  logic [3:0] io_in_2_bits_way_info,
  input  logic io_in_2_bits_hptw_bypassed,
  input  logic io_in_2_bits_n,
  input  logic io_out_ready,
  output logic io_out_valid,
  output logic [35:0] io_out_bits_bmppn,
  output logic [2:0] io_out_bits_id,
  output logic [37:0] io_out_bits_vpn,
  output logic [1:0] io_out_bits_level,
  output logic [3:0] io_out_bits_way_info,
  output logic io_out_bits_hptw_bypassed,
  output logic [1:0] io_out_bits_s2xlate,
  output logic io_out_bits_n
);

  // --------------------------------------------------------------------------
  // 入口载荷拼接：3 路 × 87 位，位 NUM_IN-1 = 第 0 路（优先级最高）
  // --------------------------------------------------------------------------
  localparam int unsigned NUM_IN = 3;
  localparam int unsigned WIDTH  = 87;

  logic [NUM_IN-1:0]       in_valid_vec;
  logic [NUM_IN-1:0]       in_ready_vec;
  logic [NUM_IN*WIDTH-1:0] in_bits_flat;
  logic [WIDTH-1:0]        out_bits_flat;
  assign in_valid_vec = {io_in_0_valid, io_in_1_valid, io_in_2_valid};
  assign in_bits_flat = {
    {io_in_0_bits_bmppn,
     3'h6 /* 本路无 id 端口，常量 */,
     io_in_0_bits_vpn,
     io_in_0_bits_level,
     4'h0 /* 本路无 way_info 端口，常量 */,
     1'h0 /* 本路无 hptw_bypassed 端口，常量 */,
     io_in_0_bits_s2xlate,
     io_in_0_bits_n},
    {io_in_1_bits_bmppn,
     io_in_1_bits_id,
     io_in_1_bits_vpn,
     2'h0 /* 本路无 level 端口，常量 */,
     io_in_1_bits_way_info,
     1'h0 /* 本路无 hptw_bypassed 端口，常量 */,
     io_in_1_bits_s2xlate,
     io_in_1_bits_n},
    {io_in_2_bits_bmppn,
     3'h7 /* 本路无 id 端口，常量 */,
     io_in_2_bits_vpn,
     io_in_2_bits_level,
     io_in_2_bits_way_info,
     io_in_2_bits_hptw_bypassed,
     2'h2 /* 本路无 s2xlate 端口，常量 */,
     io_in_2_bits_n}
  };
  assign io_in_0_ready = in_ready_vec[2];
  assign io_in_1_ready = in_ready_vec[1];
  assign io_in_2_ready = in_ready_vec[0];

  // --------------------------------------------------------------------------
  // 核例化（xs_FixedPriorityArbiter_core，端口数恒等式在核里自检）
  // --------------------------------------------------------------------------
  xs_FixedPriorityArbiter_core #(
    .WIDTH            (WIDTH),
    .NUM_IN           (NUM_IN),
    .PORT_BITS_OUT    ($bits({io_out_bits_bmppn,
                         io_out_bits_id,
                         io_out_bits_vpn,
                         io_out_bits_level,
                         io_out_bits_way_info,
                         io_out_bits_hptw_bypassed,
                         io_out_bits_s2xlate,
                         io_out_bits_n})),
    .PORT_BITS_LAST_IN($bits({io_in_2_bits_bmppn,
                         3'h7 /* 本路无 id 端口，常量 */,
                         io_in_2_bits_vpn,
                         io_in_2_bits_level,
                         io_in_2_bits_way_info,
                         io_in_2_bits_hptw_bypassed,
                         2'h2 /* 本路无 s2xlate 端口，常量 */,
                         io_in_2_bits_n})),
    .GOLDEN_PORTS     (33),  // golden 33
    .GOLDEN_BITS_PORTS(25)
  ) u_core (
    .in_valid (in_valid_vec),
    .in_ready (in_ready_vec),
    .in_bits  (in_bits_flat),
    .out_ready(io_out_ready),
    .out_valid(io_out_valid),
    .out_bits (out_bits_flat)
  );

  // --------------------------------------------------------------------------
  // 出口载荷拆分
  // --------------------------------------------------------------------------
  assign {io_out_bits_bmppn,
          io_out_bits_id,
          io_out_bits_vpn,
          io_out_bits_level,
          io_out_bits_way_info,
          io_out_bits_hptw_bypassed,
          io_out_bits_s2xlate,
          io_out_bits_n} = out_bits_flat;

endmodule
