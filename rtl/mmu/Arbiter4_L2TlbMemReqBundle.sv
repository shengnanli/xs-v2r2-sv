// Arbiter4_L2TlbMemReqBundle.sv —— L2TLB 的访存请求汇流 mem_arb：PTW / LLPTW / HPTW / Bitmap 四路并成一路发 TileLink A
//
// L2TLB.scala:403 `mem_arb = Module(new Arbiter(new L2TlbMemReqBundle(), 4))`（HasBitmapCheck）；
// 第 0 路 = PTW，第 1 路 = LLPTW，第 2 路 = HPTW，第 3 路 = Bitmap；
// 出口 id 当 TileLink source 用（L2TLB.scala:436-442）。
//
// chisel3 Arbiter（4 入口，lowest-index-wins，纯组合）；核是 rtl/frontend/xs_FixedPriorityArbiter_core.sv
// （已签核，语义讲在那里：in_ready[k] = 前面没人请求 && out_ready；一路都没请求时出口给最后一路的载荷）。
// 载荷 = 3 个字段、53 位，按 io_out_bits_* 的 golden 端口顺序 MSB 优先拼。
// ★有的入口缺字段★：上游把它接成常量，firtool 折进本模块并删掉端口；拼载荷时在原位置填常量：
//   第 0 路 id                 = 4'h6  ← PageTableWalker.scala:295 `mem.req.bits.id := FsmReqID.U`（= 6）
//   第 0 路 hptw_bypassed      = 1'h0  ← PageTableWalker.scala:296 `hptw_bypassed := false.B`
//   第 1 路 hptw_bypassed      = 1'h0  ← PageTableWalker.scala:1085 `hptw_bypassed := false.B`
//   第 2 路 id                 = 4'h7  ← PageTableWalker.scala:1304 `id := HptwReqId.U`（= 7）
//   第 3 路 hptw_bypassed      = 1'h0  ← BitmapCheck.scala:351 `hptw_bypassed := false.B`
// golden 130 行 / 20 端口；本文件由 scripts/gen_arbiter_l2tlb_leaves.py 从 golden 端口表生成（勿手改）。

module Arbiter4_L2TlbMemReqBundle (
  // --------------------------------------------------------------------------
  // 端口表（与 golden 逐名逐宽相同，20 个）
  // --------------------------------------------------------------------------
  output logic io_in_0_ready,
  input  logic io_in_0_valid,
  input  logic [47:0] io_in_0_bits_addr,
  output logic io_in_1_ready,
  input  logic io_in_1_valid,
  input  logic [47:0] io_in_1_bits_addr,
  input  logic [3:0] io_in_1_bits_id,
  output logic io_in_2_ready,
  input  logic io_in_2_valid,
  input  logic [47:0] io_in_2_bits_addr,
  input  logic io_in_2_bits_hptw_bypassed,
  output logic io_in_3_ready,
  input  logic io_in_3_valid,
  input  logic [47:0] io_in_3_bits_addr,
  input  logic [3:0] io_in_3_bits_id,
  input  logic io_out_ready,
  output logic io_out_valid,
  output logic [47:0] io_out_bits_addr,
  output logic [3:0] io_out_bits_id,
  output logic io_out_bits_hptw_bypassed
);

  // --------------------------------------------------------------------------
  // 入口载荷拼接：4 路 × 53 位，位 NUM_IN-1 = 第 0 路（优先级最高）
  // --------------------------------------------------------------------------
  localparam int unsigned NUM_IN = 4;
  localparam int unsigned WIDTH  = 53;

  logic [NUM_IN-1:0]       in_valid_vec;
  logic [NUM_IN-1:0]       in_ready_vec;
  logic [NUM_IN*WIDTH-1:0] in_bits_flat;
  logic [WIDTH-1:0]        out_bits_flat;
  assign in_valid_vec = {io_in_0_valid, io_in_1_valid, io_in_2_valid, io_in_3_valid};
  assign in_bits_flat = {
    {io_in_0_bits_addr,
     4'h6 /* 本路无 id 端口，常量 */,
     1'h0 /* 本路无 hptw_bypassed 端口，常量 */},
    {io_in_1_bits_addr,
     io_in_1_bits_id,
     1'h0 /* 本路无 hptw_bypassed 端口，常量 */},
    {io_in_2_bits_addr,
     4'h7 /* 本路无 id 端口，常量 */,
     io_in_2_bits_hptw_bypassed},
    {io_in_3_bits_addr,
     io_in_3_bits_id,
     1'h0 /* 本路无 hptw_bypassed 端口，常量 */}
  };
  assign io_in_0_ready = in_ready_vec[3];
  assign io_in_1_ready = in_ready_vec[2];
  assign io_in_2_ready = in_ready_vec[1];
  assign io_in_3_ready = in_ready_vec[0];

  // --------------------------------------------------------------------------
  // 核例化（xs_FixedPriorityArbiter_core，端口数恒等式在核里自检）
  // --------------------------------------------------------------------------
  xs_FixedPriorityArbiter_core #(
    .WIDTH            (WIDTH),
    .NUM_IN           (NUM_IN),
    .PORT_BITS_OUT    ($bits({io_out_bits_addr,
                         io_out_bits_id,
                         io_out_bits_hptw_bypassed})),
    .PORT_BITS_LAST_IN($bits({io_in_3_bits_addr,
                         io_in_3_bits_id,
                         1'h0 /* 本路无 hptw_bypassed 端口，常量 */})),
    .GOLDEN_PORTS     (20),  // golden 20
    .GOLDEN_BITS_PORTS(10)
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
  assign {io_out_bits_addr,
          io_out_bits_id,
          io_out_bits_hptw_bypassed} = out_bits_flat;

endmodule
