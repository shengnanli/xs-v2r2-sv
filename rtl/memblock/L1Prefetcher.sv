// =============================================================================
// xs_L1Prefetcher_core —— L1 数据预取器顶层装配 glue（可读重写）
//
// 对应 Chisel: src/main/scala/xiangshan/mem/prefetch/L1PrefetchComponent.scala
//   class L1Prefetcher（SMS/Stream/Stride 三类 L1 预取的顶层组合）
//
// L1Prefetcher = 纯组合装配壳（golden 0 个寄存器）。它例化 5 个子预取器：
//   - stride_train_filter (TrainFilter)   : stride 训练输入过滤
//   - stride_meta_array   (StrideMetaArray): stride 预取元数据表
//   - stream_train_filter (TrainFilter_1) : stream 训练输入过滤
//   - stream_bit_vec_array(StreamBitVectorArray): stream 位向量预取表
//   - pf_queue_filter     (MutiLevelPrefetchFilter): 多级预取请求过滤 + TLB/PMP + 发射
//   子预取器均为纯逻辑（两侧同源 elaborate，非黑盒）。
//
// 本核 = 顶层 glue（子预取器在外层 wrapper 里例化 golden）：
//   1. 训练输入按 io_enable 门控（train_i.valid & io_enable）；
//   2. stream/stride 两路 L1/L2L3 预取请求二选一（stream 优先）喂 pf_queue_filter，
//      source_value = {2'h1, stream 选中}；
//   3. pf_queue_filter 的 l1_req_ready = ~pf_ctrl_enable | io_l1_req_ready；
//   4. 输出门控：
//        io_l1_req_valid = pf_l1_valid & io_enable & pf_ctrl_enable；
//        io_l2_req_valid = pf_l2_valid & (|addr[47:31]) & addr<0x80000000000 & io_enable & pf_ctrl_enable；
//      （L2 预取只发非低 2GB 且 < 8TB 的地址）。
// =============================================================================
module xs_L1Prefetcher_core (
  // ---- 全局 ----
  input  logic        io_enable,
  input  logic        pf_ctrl_enable,

  // ---- 训练输入门控（stride/stream 各 3 端口的 valid & enable）----
  input  logic        stride_train_0_valid,
  input  logic        stride_train_1_valid,
  input  logic        stride_train_2_valid,
  input  logic        io_ld_in_0_valid,
  input  logic        io_ld_in_1_valid,
  input  logic        io_ld_in_2_valid,
  output logic        stride_g0_valid,
  output logic        stride_g1_valid,
  output logic        stride_g2_valid,
  output logic        stream_g0_valid,
  output logic        stream_g1_valid,
  output logic        stream_g2_valid,

  // ---- stream_bit_vec_array 的 L1/L2L3 预取请求（→ pf_queue_filter 输入）----
  input  logic        stream_l1_valid,
  input  logic [39:0] stream_l1_region,
  input  logic [15:0] stream_l1_bit_vec,
  input  logic        stream_l2_valid,
  input  logic [39:0] stream_l2_region,
  input  logic [15:0] stream_l2_bit_vec,
  input  logic [1:0]  stream_l2_sink,
  // ---- stride_meta_array 的 L1/L2L3 预取请求 ----
  input  logic        stride_l1_valid,
  input  logic [39:0] stride_l1_region,
  input  logic [15:0] stride_l1_bit_vec,
  input  logic        stride_l2_valid,
  input  logic [39:0] stride_l2_region,
  input  logic [15:0] stride_l2_bit_vec,

  // ---- 合并后喂 pf_queue_filter 的 L1/L2L3 预取请求 ----
  output logic        pf_l1_valid,
  output logic [39:0] pf_l1_region,
  output logic [15:0] pf_l1_bit_vec,
  output logic [2:0]  pf_l1_source_value,
  output logic        pf_l2_valid,
  output logic [39:0] pf_l2_region,
  output logic [15:0] pf_l2_bit_vec,
  output logic [1:0]  pf_l2_sink,
  output logic [2:0]  pf_l2_source_value,

  // ---- pf_queue_filter 的 l1_req 背压 ----
  input  logic        io_l1_req_ready,
  output logic        pf_l1_req_ready,

  // ---- pf_queue_filter 的输出（→ 顶层门控）----
  input  logic        pf_tlb_req_valid,
  input  logic        pf_l1_out_valid,
  input  logic        pf_l2_addr_valid,
  input  logic [47:0] pf_l2_addr_bits,

  // ---- 顶层输出 ----
  output logic        io_tlb_req_req_valid,
  output logic        io_l1_req_valid,
  output logic        io_l2_req_valid,
  output logic [47:0] io_l2_req_bits_addr
);

  // ---- 训练输入门控 ----
  assign stride_g0_valid = stride_train_0_valid & io_enable;
  assign stride_g1_valid = stride_train_1_valid & io_enable;
  assign stride_g2_valid = stride_train_2_valid & io_enable;
  assign stream_g0_valid = io_ld_in_0_valid & io_enable;
  assign stream_g1_valid = io_ld_in_1_valid & io_enable;
  assign stream_g2_valid = io_ld_in_2_valid & io_enable;

  // ---- L1 预取请求二选一（stream 优先）----
  assign pf_l1_valid        = stream_l1_valid | stride_l1_valid;
  assign pf_l1_region       = stream_l1_valid ? stream_l1_region  : stride_l1_region;
  assign pf_l1_bit_vec      = stream_l1_valid ? stream_l1_bit_vec : stride_l1_bit_vec;
  assign pf_l1_source_value = {2'h1, stream_l1_valid};

  // ---- L2/L3 预取请求二选一（stream 优先；sink stream 选中用 stream_sink 否则 2'h1）----
  assign pf_l2_valid        = stream_l2_valid | stride_l2_valid;
  assign pf_l2_region       = stream_l2_valid ? stream_l2_region  : stride_l2_region;
  assign pf_l2_bit_vec      = stream_l2_valid ? stream_l2_bit_vec : stride_l2_bit_vec;
  assign pf_l2_sink         = stream_l2_valid ? stream_l2_sink    : 2'h1;
  assign pf_l2_source_value = {2'h1, stream_l2_valid};

  // ---- pf_queue_filter 的 l1_req_ready ----
  assign pf_l1_req_ready = ~pf_ctrl_enable | io_l1_req_ready;

  // ---- 顶层输出门控 ----
  assign io_tlb_req_req_valid = pf_tlb_req_valid;
  assign io_l1_req_valid      = pf_l1_out_valid & io_enable & pf_ctrl_enable;
  // L2 预取地址范围检查：非低 2GB(addr[47:31]!=0) 且 < 8TB(0x80000000000)
  assign io_l2_req_valid = pf_l2_addr_valid
                         & (|pf_l2_addr_bits[47:31])
                         & (pf_l2_addr_bits < 48'h80000000000)
                         & io_enable & pf_ctrl_enable;
  assign io_l2_req_bits_addr = pf_l2_addr_bits;

endmodule
