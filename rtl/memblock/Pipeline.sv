// =============================================================================
//  Pipeline —— L1PrefetchReq 一拍流水缓冲（可读重写核 xs_Pipeline_core）
// -----------------------------------------------------------------------------
//  设计意图来源：xiangshan.mem.MemCommon.scala 中 AddPipelineReg / utility.Pipeline
//  风格的 Decoupled 流水寄存语义。golden 在本实例上落成 Queue1_L1PrefetchReq。
//
//  本模块用于在 L1 prefetch 请求路径中插入一个可反压的寄存点：
//    * 上游 in.fire 时采样完整 L1PrefetchReq；
//    * 下游 out.ready 允许已缓存请求离开；
//    * 当寄存点为空时 in.ready=1，当满且下游 ready 时允许同拍出入。
//
//  Queue1_L1PrefetchReq 是共享黑盒叶子，核心只表达请求 bundle 与 Decoupled 边界。
// =============================================================================
module xs_Pipeline_core
  import pipeline_pkg::*;
(
  input         clock,
  input         reset,
  output        io_in_ready,
  input         io_in_valid,
  input  [47:0] io_in_bits_paddr,
  input  [1:0]  io_in_bits_alias,
  input         io_in_bits_confidence,
  input         io_in_bits_is_store,
  input  [2:0]  io_in_bits_pf_source_value,
  input         io_out_ready,
  output        io_out_valid,
  output [47:0] io_out_bits_paddr,
  output [1:0]  io_out_bits_alias,
  output        io_out_bits_confidence,
  output        io_out_bits_is_store,
  output [2:0]  io_out_bits_pf_source_value
);

  typedef enum logic [0:0] {
    PF_BOUNDARY_IN  = 1'b0,
    PF_BOUNDARY_OUT = 1'b1
  } prefetch_boundary_e;

  typedef struct packed {
    logic ready;
    logic valid;
  } stream_handshake_t;

  function automatic logic stream_fire(input stream_handshake_t hs);
    return hs.ready & hs.valid;
  endfunction

  function automatic logic is_output_boundary(input prefetch_boundary_e boundary);
    return boundary == PF_BOUNDARY_OUT;
  endfunction

  // ---------------------------------------------------------------------------
  //  请求 payload 聚合：Pipeline 只搬运请求，不修改预取来源/置信度等语义字段。
  // ---------------------------------------------------------------------------
  l1_prefetch_req_t prefetch_in;
  l1_prefetch_req_t prefetch_out;

  always_comb begin
    prefetch_in.paddr = io_in_bits_paddr;
    prefetch_in.addr_alias = io_in_bits_alias;
    prefetch_in.confidence = io_in_bits_confidence;
    prefetch_in.is_store = io_in_bits_is_store;
    prefetch_in.pf_source_value = io_in_bits_pf_source_value;
  end

  // ---------------------------------------------------------------------------
  //  Decoupled 边界视图：入口和出口都用 ready/valid/fire 描述，方便读者
  //  对照“入队采样、出队释放”的流水寄存语义。
  // ---------------------------------------------------------------------------
  stream_handshake_t boundary_hs [PIPELINE_BOUNDARIES];
  logic [PIPELINE_BOUNDARIES-1:0] boundary_fire;

  assign boundary_hs[PF_BOUNDARY_IN].ready = io_in_ready;
  assign boundary_hs[PF_BOUNDARY_IN].valid = io_in_valid;
  assign boundary_hs[PF_BOUNDARY_OUT].ready = io_out_ready;
  assign boundary_hs[PF_BOUNDARY_OUT].valid = io_out_valid;

  for (genvar boundary = 0; boundary < PIPELINE_BOUNDARIES; boundary++) begin : g_boundary
    assign boundary_fire[boundary] = stream_fire(boundary_hs[boundary]);
  end

  wire output_side_active =
    is_output_boundary(PF_BOUNDARY_OUT) & boundary_fire[PF_BOUNDARY_OUT];

  Queue1_L1PrefetchReq prefetch_stage (
    .clock                       (clock),
    .reset                       (reset),
    .io_enq_ready                (io_in_ready),
    .io_enq_valid                (io_in_valid),
    .io_enq_bits_paddr           (prefetch_in.paddr),
    .io_enq_bits_alias           (prefetch_in.addr_alias),
    .io_enq_bits_confidence      (prefetch_in.confidence),
    .io_enq_bits_is_store        (prefetch_in.is_store),
    .io_enq_bits_pf_source_value (prefetch_in.pf_source_value),
    .io_deq_ready                (io_out_ready),
    .io_deq_valid                (io_out_valid),
    .io_deq_bits_paddr           (prefetch_out.paddr),
    .io_deq_bits_alias           (prefetch_out.addr_alias),
    .io_deq_bits_confidence      (prefetch_out.confidence),
    .io_deq_bits_is_store        (prefetch_out.is_store),
    .io_deq_bits_pf_source_value (prefetch_out.pf_source_value)
  );

  assign io_out_bits_paddr = prefetch_out.paddr;
  assign io_out_bits_alias = prefetch_out.addr_alias;
  assign io_out_bits_confidence = prefetch_out.confidence;
  assign io_out_bits_is_store = prefetch_out.is_store;
  assign io_out_bits_pf_source_value = prefetch_out.pf_source_value;

  // 说明性握手视图的保留点；不反馈到功能路径。
  wire unused_boundary_view = output_side_active;

endmodule
