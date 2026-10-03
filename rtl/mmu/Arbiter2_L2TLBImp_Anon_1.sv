// Arbiter2_L2TLBImp_Anon_1.sv —— L2TLB 的 HPTW 应答汇流 hptw_resp_arb：page cache 命中 / HPTW 走表 两路应答并成一路
//
// L2TLB.scala:138 `hptw_resp_arb = Module(new Arbiter(..., 2))`；
// 第 0 路 = page cache 命中且是 HPTW 请求（HptwRespArbCachePort），第 1 路 = HPTW 走表应答。
// 出口按 id 分发给 PTW（id == FsmReqID）或 LLPTW（其余）；L2TLB.scala:624 `out.ready := true.B`。
//
// chisel3 Arbiter（2 入口，lowest-index-wins，纯组合）；核是 rtl/frontend/xs_FixedPriorityArbiter_core.sv
// （已签核，语义讲在那里：in_ready[k] = 前面没人请求 && out_ready；一路都没请求时出口给最后一路的载荷）。
// 载荷 = 16 个字段、107 位，按 io_out_bits_* 的 golden 端口顺序 MSB 优先拼。
// ★有的入口缺字段★：上游把它接成常量，firtool 折进本模块并删掉端口；拼载荷时在原位置填常量：
//   第 0 路 resp_gaf           = 1'h0  ← PageTableCache.scala:765 `io.resp.bits.toHptw.resp.gaf := false.B`
// ★out.ready 恒 1★：golden 删了 io_out_ready / io_in_0_ready，核的 out_ready 接 1'b1，第 0 路 ready 不引出。
// 核的端口数恒等式按标准 Arbiter 接口算：golden 51 端口 + 被删的 2 根 ready = 53。
// golden 174 行 / 51 端口；本文件由 scripts/gen_arbiter_l2tlb_leaves.py 从 golden 端口表生成（勿手改）。

module Arbiter2_L2TLBImp_Anon_1 (
  // --------------------------------------------------------------------------
  // 端口表（与 golden 逐名逐宽相同，51 个）
  // --------------------------------------------------------------------------
  input  logic io_in_0_valid,
  input  logic [37:0] io_in_0_bits_resp_entry_tag,
  input  logic [13:0] io_in_0_bits_resp_entry_vmid,
  input  logic io_in_0_bits_resp_entry_n,
  input  logic [1:0] io_in_0_bits_resp_entry_pbmt,
  input  logic [37:0] io_in_0_bits_resp_entry_ppn,
  input  logic io_in_0_bits_resp_entry_perm_d,
  input  logic io_in_0_bits_resp_entry_perm_a,
  input  logic io_in_0_bits_resp_entry_perm_g,
  input  logic io_in_0_bits_resp_entry_perm_u,
  input  logic io_in_0_bits_resp_entry_perm_x,
  input  logic io_in_0_bits_resp_entry_perm_w,
  input  logic io_in_0_bits_resp_entry_perm_r,
  input  logic [1:0] io_in_0_bits_resp_entry_level,
  input  logic io_in_0_bits_resp_gpf,
  input  logic [2:0] io_in_0_bits_id,
  output logic io_in_1_ready,
  input  logic io_in_1_valid,
  input  logic [37:0] io_in_1_bits_resp_entry_tag,
  input  logic [13:0] io_in_1_bits_resp_entry_vmid,
  input  logic io_in_1_bits_resp_entry_n,
  input  logic [1:0] io_in_1_bits_resp_entry_pbmt,
  input  logic [37:0] io_in_1_bits_resp_entry_ppn,
  input  logic io_in_1_bits_resp_entry_perm_d,
  input  logic io_in_1_bits_resp_entry_perm_a,
  input  logic io_in_1_bits_resp_entry_perm_g,
  input  logic io_in_1_bits_resp_entry_perm_u,
  input  logic io_in_1_bits_resp_entry_perm_x,
  input  logic io_in_1_bits_resp_entry_perm_w,
  input  logic io_in_1_bits_resp_entry_perm_r,
  input  logic [1:0] io_in_1_bits_resp_entry_level,
  input  logic io_in_1_bits_resp_gpf,
  input  logic io_in_1_bits_resp_gaf,
  input  logic [2:0] io_in_1_bits_id,
  output logic io_out_valid,
  output logic [37:0] io_out_bits_resp_entry_tag,
  output logic [13:0] io_out_bits_resp_entry_vmid,
  output logic io_out_bits_resp_entry_n,
  output logic [1:0] io_out_bits_resp_entry_pbmt,
  output logic [37:0] io_out_bits_resp_entry_ppn,
  output logic io_out_bits_resp_entry_perm_d,
  output logic io_out_bits_resp_entry_perm_a,
  output logic io_out_bits_resp_entry_perm_g,
  output logic io_out_bits_resp_entry_perm_u,
  output logic io_out_bits_resp_entry_perm_x,
  output logic io_out_bits_resp_entry_perm_w,
  output logic io_out_bits_resp_entry_perm_r,
  output logic [1:0] io_out_bits_resp_entry_level,
  output logic io_out_bits_resp_gpf,
  output logic io_out_bits_resp_gaf,
  output logic [2:0] io_out_bits_id
);

  // --------------------------------------------------------------------------
  // 入口载荷拼接：2 路 × 107 位，位 NUM_IN-1 = 第 0 路（优先级最高）
  // --------------------------------------------------------------------------
  localparam int unsigned NUM_IN = 2;
  localparam int unsigned WIDTH  = 107;

  logic [NUM_IN-1:0]       in_valid_vec;
  logic [NUM_IN-1:0]       in_ready_vec;
  logic [NUM_IN*WIDTH-1:0] in_bits_flat;
  logic [WIDTH-1:0]        out_bits_flat;
  assign in_valid_vec = {io_in_0_valid, io_in_1_valid};
  assign in_bits_flat = {
    {io_in_0_bits_resp_entry_tag,
     io_in_0_bits_resp_entry_vmid,
     io_in_0_bits_resp_entry_n,
     io_in_0_bits_resp_entry_pbmt,
     io_in_0_bits_resp_entry_ppn,
     io_in_0_bits_resp_entry_perm_d,
     io_in_0_bits_resp_entry_perm_a,
     io_in_0_bits_resp_entry_perm_g,
     io_in_0_bits_resp_entry_perm_u,
     io_in_0_bits_resp_entry_perm_x,
     io_in_0_bits_resp_entry_perm_w,
     io_in_0_bits_resp_entry_perm_r,
     io_in_0_bits_resp_entry_level,
     io_in_0_bits_resp_gpf,
     1'h0 /* 本路无 resp_gaf 端口，常量 */,
     io_in_0_bits_id},
    {io_in_1_bits_resp_entry_tag,
     io_in_1_bits_resp_entry_vmid,
     io_in_1_bits_resp_entry_n,
     io_in_1_bits_resp_entry_pbmt,
     io_in_1_bits_resp_entry_ppn,
     io_in_1_bits_resp_entry_perm_d,
     io_in_1_bits_resp_entry_perm_a,
     io_in_1_bits_resp_entry_perm_g,
     io_in_1_bits_resp_entry_perm_u,
     io_in_1_bits_resp_entry_perm_x,
     io_in_1_bits_resp_entry_perm_w,
     io_in_1_bits_resp_entry_perm_r,
     io_in_1_bits_resp_entry_level,
     io_in_1_bits_resp_gpf,
     io_in_1_bits_resp_gaf,
     io_in_1_bits_id}
  };
  // io_in_0_ready 被 firtool 删掉（out.ready 恒 1 时它恒 1，父级不需要读）
  assign io_in_1_ready = in_ready_vec[0];

  // --------------------------------------------------------------------------
  // 核例化（xs_FixedPriorityArbiter_core，端口数恒等式在核里自检）
  // --------------------------------------------------------------------------
  xs_FixedPriorityArbiter_core #(
    .WIDTH            (WIDTH),
    .NUM_IN           (NUM_IN),
    .PORT_BITS_OUT    ($bits({io_out_bits_resp_entry_tag,
                         io_out_bits_resp_entry_vmid,
                         io_out_bits_resp_entry_n,
                         io_out_bits_resp_entry_pbmt,
                         io_out_bits_resp_entry_ppn,
                         io_out_bits_resp_entry_perm_d,
                         io_out_bits_resp_entry_perm_a,
                         io_out_bits_resp_entry_perm_g,
                         io_out_bits_resp_entry_perm_u,
                         io_out_bits_resp_entry_perm_x,
                         io_out_bits_resp_entry_perm_w,
                         io_out_bits_resp_entry_perm_r,
                         io_out_bits_resp_entry_level,
                         io_out_bits_resp_gpf,
                         io_out_bits_resp_gaf,
                         io_out_bits_id})),
    .PORT_BITS_LAST_IN($bits({io_in_1_bits_resp_entry_tag,
                         io_in_1_bits_resp_entry_vmid,
                         io_in_1_bits_resp_entry_n,
                         io_in_1_bits_resp_entry_pbmt,
                         io_in_1_bits_resp_entry_ppn,
                         io_in_1_bits_resp_entry_perm_d,
                         io_in_1_bits_resp_entry_perm_a,
                         io_in_1_bits_resp_entry_perm_g,
                         io_in_1_bits_resp_entry_perm_u,
                         io_in_1_bits_resp_entry_perm_x,
                         io_in_1_bits_resp_entry_perm_w,
                         io_in_1_bits_resp_entry_perm_r,
                         io_in_1_bits_resp_entry_level,
                         io_in_1_bits_resp_gpf,
                         io_in_1_bits_resp_gaf,
                         io_in_1_bits_id})),
    .GOLDEN_PORTS     (53),  // golden 51 + 2 根被删的 ready
    .GOLDEN_BITS_PORTS(47)
  ) u_core (
    .in_valid (in_valid_vec),
    .in_ready (in_ready_vec),
    .in_bits  (in_bits_flat),
    .out_ready(1'b1),
    .out_valid(io_out_valid),
    .out_bits (out_bits_flat)
  );

  // --------------------------------------------------------------------------
  // 出口载荷拆分
  // --------------------------------------------------------------------------
  assign {io_out_bits_resp_entry_tag,
          io_out_bits_resp_entry_vmid,
          io_out_bits_resp_entry_n,
          io_out_bits_resp_entry_pbmt,
          io_out_bits_resp_entry_ppn,
          io_out_bits_resp_entry_perm_d,
          io_out_bits_resp_entry_perm_a,
          io_out_bits_resp_entry_perm_g,
          io_out_bits_resp_entry_perm_u,
          io_out_bits_resp_entry_perm_x,
          io_out_bits_resp_entry_perm_w,
          io_out_bits_resp_entry_perm_r,
          io_out_bits_resp_entry_level,
          io_out_bits_resp_gpf,
          io_out_bits_resp_gaf,
          io_out_bits_id} = out_bits_flat;

endmodule
