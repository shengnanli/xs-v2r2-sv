// Arbiter5_L2TlbWithHptwIdBundle.sv —— L2TLB 进 page cache 的请求汇流 arb2：HPTW / PTW / MissQueue / TLB / Prefetch 五路并成一路
//
// L2TLB.scala:132 `arb2 = Module(new Arbiter(new L2TlbWithHptwIdBundle, 5))`；端口号见 L2TLB.scala:177-181：
// 第 0 路 = HPTW 请求，第 1 路 = PTW 转 LLPTW，第 2 路 = MissQueue 回灌，第 3 路 = TLB（arb1 出口），
// 第 4 路 = Prefetch。出口接 page cache 的 req（L2TLB.scala:252 `out.ready := cache.io.req.ready`）。
//
// chisel3 Arbiter（5 入口，lowest-index-wins，纯组合）；核是 rtl/frontend/xs_FixedPriorityArbiter_core.sv
// （已签核，语义讲在那里：in_ready[k] = 前面没人请求 && out_ready；一路都没请求时出口给最后一路的载荷）。
// 载荷 = 5 个字段、46 位，按 io_out_bits_* 的 golden 端口顺序 MSB 优先拼。
// ★有的入口缺字段★：上游把它接成常量，firtool 折进本模块并删掉端口；拼载荷时在原位置填常量：
//   第 0 路 req_info_s2xlate   = 2'h2  ← L2TLB.scala:227 `s2xlate := onlyStage2`（= 2）
//   第 0 路 isHptwReq          = 1'h1  ← L2TLB.scala:229 `isHptwReq := true.B`
//   第 1 路 isHptwReq          = 1'h0  ← L2TLB.scala:207 `isHptwReq := false.B`
//   第 1 路 hptwId             = 3'h0  ← L2TLB.scala:209 `hptwId := DontCare`（firtool 取 0）
//   第 3 路 isHptwReq          = 1'h0  ← L2TLB.scala:217 `isHptwReq := false.B`
//   第 3 路 hptwId             = 3'h0  ← L2TLB.scala:219 `hptwId := DontCare`（firtool 取 0）
//   第 4 路 req_info_source    = 2'h2  ← L2TlbPrefetch.scala `source := prefetchID.U`（prefetchID = PtwWidth = 2）
//   第 4 路 isHptwReq          = 1'h0  ← L2TlbPrefetch.scala `isHptwReq := false.B`
//   第 4 路 hptwId             = 3'h0  ← L2TlbPrefetch.scala `hptwId := DontCare`（firtool 取 0）
// ★io_chosen★：父级读它，核不出，本文件按 Chisel 定义另算（第一个 valid 的下标；都不 valid 时 = 4）。
// 核的端口数恒等式按标准 Arbiter 接口算：golden 34 端口 - io_chosen = 33。
// golden 170 行 / 34 端口；本文件由 scripts/gen_arbiter_l2tlb_leaves.py 从 golden 端口表生成（勿手改）。

module Arbiter5_L2TlbWithHptwIdBundle (
  // --------------------------------------------------------------------------
  // 端口表（与 golden 逐名逐宽相同，34 个）
  // --------------------------------------------------------------------------
  output logic io_in_0_ready,
  input  logic io_in_0_valid,
  input  logic [37:0] io_in_0_bits_req_info_vpn,
  input  logic [1:0] io_in_0_bits_req_info_source,
  input  logic [2:0] io_in_0_bits_hptwId,
  output logic io_in_1_ready,
  input  logic io_in_1_valid,
  input  logic [37:0] io_in_1_bits_req_info_vpn,
  input  logic [1:0] io_in_1_bits_req_info_s2xlate,
  input  logic [1:0] io_in_1_bits_req_info_source,
  output logic io_in_2_ready,
  input  logic io_in_2_valid,
  input  logic [37:0] io_in_2_bits_req_info_vpn,
  input  logic [1:0] io_in_2_bits_req_info_s2xlate,
  input  logic [1:0] io_in_2_bits_req_info_source,
  input  logic io_in_2_bits_isHptwReq,
  input  logic [2:0] io_in_2_bits_hptwId,
  output logic io_in_3_ready,
  input  logic io_in_3_valid,
  input  logic [37:0] io_in_3_bits_req_info_vpn,
  input  logic [1:0] io_in_3_bits_req_info_s2xlate,
  input  logic [1:0] io_in_3_bits_req_info_source,
  output logic io_in_4_ready,
  input  logic io_in_4_valid,
  input  logic [37:0] io_in_4_bits_req_info_vpn,
  input  logic [1:0] io_in_4_bits_req_info_s2xlate,
  input  logic io_out_ready,
  output logic io_out_valid,
  output logic [37:0] io_out_bits_req_info_vpn,
  output logic [1:0] io_out_bits_req_info_s2xlate,
  output logic [1:0] io_out_bits_req_info_source,
  output logic io_out_bits_isHptwReq,
  output logic [2:0] io_out_bits_hptwId,
  output logic [2:0] io_chosen
);

  // --------------------------------------------------------------------------
  // 入口载荷拼接：5 路 × 46 位，位 NUM_IN-1 = 第 0 路（优先级最高）
  // --------------------------------------------------------------------------
  localparam int unsigned NUM_IN = 5;
  localparam int unsigned WIDTH  = 46;

  logic [NUM_IN-1:0]       in_valid_vec;
  logic [NUM_IN-1:0]       in_ready_vec;
  logic [NUM_IN*WIDTH-1:0] in_bits_flat;
  logic [WIDTH-1:0]        out_bits_flat;
  assign in_valid_vec = {io_in_0_valid, io_in_1_valid, io_in_2_valid, io_in_3_valid, io_in_4_valid};
  assign in_bits_flat = {
    {io_in_0_bits_req_info_vpn,
     2'h2 /* 本路无 req_info_s2xlate 端口，常量 */,
     io_in_0_bits_req_info_source,
     1'h1 /* 本路无 isHptwReq 端口，常量 */,
     io_in_0_bits_hptwId},
    {io_in_1_bits_req_info_vpn,
     io_in_1_bits_req_info_s2xlate,
     io_in_1_bits_req_info_source,
     1'h0 /* 本路无 isHptwReq 端口，常量 */,
     3'h0 /* 本路无 hptwId 端口，常量 */},
    {io_in_2_bits_req_info_vpn,
     io_in_2_bits_req_info_s2xlate,
     io_in_2_bits_req_info_source,
     io_in_2_bits_isHptwReq,
     io_in_2_bits_hptwId},
    {io_in_3_bits_req_info_vpn,
     io_in_3_bits_req_info_s2xlate,
     io_in_3_bits_req_info_source,
     1'h0 /* 本路无 isHptwReq 端口，常量 */,
     3'h0 /* 本路无 hptwId 端口，常量 */},
    {io_in_4_bits_req_info_vpn,
     io_in_4_bits_req_info_s2xlate,
     2'h2 /* 本路无 req_info_source 端口，常量 */,
     1'h0 /* 本路无 isHptwReq 端口，常量 */,
     3'h0 /* 本路无 hptwId 端口，常量 */}
  };
  assign io_in_0_ready = in_ready_vec[4];
  assign io_in_1_ready = in_ready_vec[3];
  assign io_in_2_ready = in_ready_vec[2];
  assign io_in_3_ready = in_ready_vec[1];
  assign io_in_4_ready = in_ready_vec[0];

  // --------------------------------------------------------------------------
  // 核例化（xs_FixedPriorityArbiter_core，端口数恒等式在核里自检）
  // --------------------------------------------------------------------------
  xs_FixedPriorityArbiter_core #(
    .WIDTH            (WIDTH),
    .NUM_IN           (NUM_IN),
    .PORT_BITS_OUT    ($bits({io_out_bits_req_info_vpn,
                         io_out_bits_req_info_s2xlate,
                         io_out_bits_req_info_source,
                         io_out_bits_isHptwReq,
                         io_out_bits_hptwId})),
    .PORT_BITS_LAST_IN($bits({io_in_4_bits_req_info_vpn,
                         io_in_4_bits_req_info_s2xlate,
                         2'h2 /* 本路无 req_info_source 端口，常量 */,
                         1'h0 /* 本路无 isHptwReq 端口，常量 */,
                         3'h0 /* 本路无 hptwId 端口，常量 */})),
    .GOLDEN_PORTS     (33),  // golden 34 - io_chosen
    .GOLDEN_BITS_PORTS(21)
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
  assign {io_out_bits_req_info_vpn,
          io_out_bits_req_info_s2xlate,
          io_out_bits_req_info_source,
          io_out_bits_isHptwReq,
          io_out_bits_hptwId} = out_bits_flat;

  // --------------------------------------------------------------------------
  // io_chosen：被选中那一路的下标（Chisel：从最后一路往前覆盖，第一个 valid 胜出）
  // --------------------------------------------------------------------------
  always_comb begin
    io_chosen = 3'(NUM_IN - 1);
    for (int k = NUM_IN - 2; k >= 0; k--)
      if (in_valid_vec[NUM_IN - 1 - k]) io_chosen = 3'(k);
  end

endmodule
