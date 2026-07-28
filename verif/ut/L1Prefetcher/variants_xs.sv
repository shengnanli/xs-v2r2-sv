// 自动生成：scripts/gen_l1prefetcher.py —— 勿手改
module L1Prefetcher_xs (
  input  clock,
  input  reset,
  input  io_ld_in_0_valid,
  input  io_ld_in_0_bits_uop_robIdx_flag,
  input  [7:0] io_ld_in_0_bits_uop_robIdx_value,
  input  [49:0] io_ld_in_0_bits_vaddr,
  input  io_ld_in_0_bits_miss,
  input  [2:0] io_ld_in_0_bits_meta_prefetch,
  input  io_ld_in_1_valid,
  input  io_ld_in_1_bits_uop_robIdx_flag,
  input  [7:0] io_ld_in_1_bits_uop_robIdx_value,
  input  [49:0] io_ld_in_1_bits_vaddr,
  input  io_ld_in_1_bits_miss,
  input  [2:0] io_ld_in_1_bits_meta_prefetch,
  input  io_ld_in_2_valid,
  input  io_ld_in_2_bits_uop_robIdx_flag,
  input  [7:0] io_ld_in_2_bits_uop_robIdx_value,
  input  [49:0] io_ld_in_2_bits_vaddr,
  input  io_ld_in_2_bits_miss,
  input  [2:0] io_ld_in_2_bits_meta_prefetch,
  output io_tlb_req_req_valid,
  output [49:0] io_tlb_req_req_bits_vaddr,
  output [63:0] io_tlb_req_req_bits_fullva,
  output io_tlb_req_req_bits_checkfullva,
  output [2:0] io_tlb_req_req_bits_cmd,
  output io_tlb_req_req_bits_hyperinst,
  output io_tlb_req_req_bits_hlvx,
  output io_tlb_req_req_bits_kill,
  output io_tlb_req_req_bits_isPrefetch,
  output io_tlb_req_req_bits_no_translate,
  output [47:0] io_tlb_req_req_bits_pmp_addr,
  output io_tlb_req_req_bits_debug_robIdx_flag,
  output [7:0] io_tlb_req_req_bits_debug_robIdx_value,
  output io_tlb_req_req_bits_debug_isFirstIssue,
  input  io_tlb_req_resp_valid,
  input  [47:0] io_tlb_req_resp_bits_paddr_0,
  input  [1:0] io_tlb_req_resp_bits_pbmt_0,
  input  io_tlb_req_resp_bits_miss,
  input  io_tlb_req_resp_bits_excp_0_gpf_ld,
  input  io_tlb_req_resp_bits_excp_0_pf_ld,
  input  io_tlb_req_resp_bits_excp_0_af_ld,
  input  io_pmp_resp_ld,
  input  io_pmp_resp_mmio,
  input  io_l1_req_ready,
  output io_l1_req_valid,
  output [47:0] io_l1_req_bits_paddr,
  output [1:0] io_l1_req_bits_alias,
  output io_l1_req_bits_confidence,
  output io_l1_req_bits_is_store,
  output [2:0] io_l1_req_bits_pf_source_value,
  output io_l2_req_valid,
  output [47:0] io_l2_req_bits_addr,
  output [4:0] io_l2_req_bits_source,
  input  io_enable,
  input  pf_ctrl_enable,
  input  pf_ctrl_confidence,
  input  stride_train_0_valid,
  input  [49:0] stride_train_0_bits_uop_pc,
  input  stride_train_0_bits_uop_robIdx_flag,
  input  [7:0] stride_train_0_bits_uop_robIdx_value,
  input  [49:0] stride_train_0_bits_vaddr,
  input  stride_train_1_valid,
  input  [49:0] stride_train_1_bits_uop_pc,
  input  stride_train_1_bits_uop_robIdx_flag,
  input  [7:0] stride_train_1_bits_uop_robIdx_value,
  input  [49:0] stride_train_1_bits_vaddr,
  input  stride_train_2_valid,
  input  [49:0] stride_train_2_bits_uop_pc,
  input  stride_train_2_bits_uop_robIdx_flag,
  input  [7:0] stride_train_2_bits_uop_robIdx_value,
  input  [49:0] stride_train_2_bits_vaddr
);

  // ---- 子预取器 ↔ 核的 net ----
  wire        stride_g0_valid, stride_g1_valid, stride_g2_valid;
  wire        stream_g0_valid, stream_g1_valid, stream_g2_valid;
  // stride 训练过滤 → stride 元数据表
  wire        stf_req_valid; wire [49:0] stf_req_vaddr; wire [49:0] stf_req_pc;
  wire        sma_req_ready;
  // stride 元数据表 → 核
  wire        sma_l1_valid; wire [39:0] sma_l1_region; wire [15:0] sma_l1_bit_vec;
  wire        sma_l2_valid; wire [39:0] sma_l2_region; wire [15:0] sma_l2_bit_vec;
  wire        sma_stream_lookup_valid; wire [49:0] sma_stream_lookup_vaddr;
  // stream 训练过滤 → stream 位向量表
  wire        smtf_req_valid; wire [49:0] smtf_req_vaddr; wire smtf_req_miss; wire smtf_req_pfHitStream;
  wire        sbva_req_ready;
  // stream 位向量表 → 核
  wire        sbva_l1_valid; wire [39:0] sbva_l1_region; wire [15:0] sbva_l1_bit_vec;
  wire        sbva_l2_valid; wire [39:0] sbva_l2_region; wire [15:0] sbva_l2_bit_vec; wire [1:0] sbva_l2_sink;
  wire        sbva_stream_lookup_resp;   // _probe (unused)
  // 合并后 → pf_queue_filter
  wire        pf_l1_valid; wire [39:0] pf_l1_region; wire [15:0] pf_l1_bit_vec; wire [2:0] pf_l1_source_value;
  wire        pf_l2_valid; wire [39:0] pf_l2_region; wire [15:0] pf_l2_bit_vec; wire [1:0] pf_l2_sink; wire [2:0] pf_l2_source_value;
  wire        pf_l1_req_ready;
  // pf_queue_filter → 核
  wire        pf_tlb_req_valid; wire pf_l1_out_valid;
  wire        pf_l2_addr_valid; wire [47:0] pf_l2_addr_bits;

  // ==== 可读核 glue ====
  xs_L1Prefetcher_core u_core (
    .io_enable(io_enable), .pf_ctrl_enable(pf_ctrl_enable),
    .stride_train_0_valid(stride_train_0_valid), .stride_train_1_valid(stride_train_1_valid),
    .stride_train_2_valid(stride_train_2_valid),
    .io_ld_in_0_valid(io_ld_in_0_valid), .io_ld_in_1_valid(io_ld_in_1_valid), .io_ld_in_2_valid(io_ld_in_2_valid),
    .stride_g0_valid(stride_g0_valid), .stride_g1_valid(stride_g1_valid), .stride_g2_valid(stride_g2_valid),
    .stream_g0_valid(stream_g0_valid), .stream_g1_valid(stream_g1_valid), .stream_g2_valid(stream_g2_valid),
    .stream_l1_valid(sbva_l1_valid), .stream_l1_region(sbva_l1_region), .stream_l1_bit_vec(sbva_l1_bit_vec),
    .stream_l2_valid(sbva_l2_valid), .stream_l2_region(sbva_l2_region), .stream_l2_bit_vec(sbva_l2_bit_vec),
    .stream_l2_sink(sbva_l2_sink),
    .stride_l1_valid(sma_l1_valid), .stride_l1_region(sma_l1_region), .stride_l1_bit_vec(sma_l1_bit_vec),
    .stride_l2_valid(sma_l2_valid), .stride_l2_region(sma_l2_region), .stride_l2_bit_vec(sma_l2_bit_vec),
    .pf_l1_valid(pf_l1_valid), .pf_l1_region(pf_l1_region), .pf_l1_bit_vec(pf_l1_bit_vec),
    .pf_l1_source_value(pf_l1_source_value),
    .pf_l2_valid(pf_l2_valid), .pf_l2_region(pf_l2_region), .pf_l2_bit_vec(pf_l2_bit_vec),
    .pf_l2_sink(pf_l2_sink), .pf_l2_source_value(pf_l2_source_value),
    .io_l1_req_ready(io_l1_req_ready), .pf_l1_req_ready(pf_l1_req_ready),
    .pf_tlb_req_valid(pf_tlb_req_valid), .pf_l1_out_valid(pf_l1_out_valid),
    .pf_l2_addr_valid(pf_l2_addr_valid), .pf_l2_addr_bits(pf_l2_addr_bits),
    .io_tlb_req_req_valid(io_tlb_req_req_valid), .io_l1_req_valid(io_l1_req_valid),
    .io_l2_req_valid(io_l2_req_valid), .io_l2_req_bits_addr(io_l2_req_bits_addr)
  );

  // ==== golden 子预取器（两侧同源 elaborate）====
  TrainFilter stride_train_filter (
    .clock(clock), .reset(reset), .io_enable(io_enable),
    .io_ld_in_0_valid(stride_g0_valid), .io_ld_in_0_bits_uop_pc(stride_train_0_bits_uop_pc),
    .io_ld_in_0_bits_uop_robIdx_flag(stride_train_0_bits_uop_robIdx_flag),
    .io_ld_in_0_bits_uop_robIdx_value(stride_train_0_bits_uop_robIdx_value),
    .io_ld_in_0_bits_vaddr(stride_train_0_bits_vaddr),
    .io_ld_in_1_valid(stride_g1_valid), .io_ld_in_1_bits_uop_pc(stride_train_1_bits_uop_pc),
    .io_ld_in_1_bits_uop_robIdx_flag(stride_train_1_bits_uop_robIdx_flag),
    .io_ld_in_1_bits_uop_robIdx_value(stride_train_1_bits_uop_robIdx_value),
    .io_ld_in_1_bits_vaddr(stride_train_1_bits_vaddr),
    .io_ld_in_2_valid(stride_g2_valid), .io_ld_in_2_bits_uop_pc(stride_train_2_bits_uop_pc),
    .io_ld_in_2_bits_uop_robIdx_flag(stride_train_2_bits_uop_robIdx_flag),
    .io_ld_in_2_bits_uop_robIdx_value(stride_train_2_bits_uop_robIdx_value),
    .io_ld_in_2_bits_vaddr(stride_train_2_bits_vaddr),
    .io_train_req_ready(sma_req_ready), .io_train_req_valid(stf_req_valid),
    .io_train_req_bits_vaddr(stf_req_vaddr), .io_train_req_bits_pc(stf_req_pc)
  );
  StrideMetaArray stride_meta_array (
    .clock(clock), .reset(reset),
    .io_train_req_ready(sma_req_ready), .io_train_req_valid(stf_req_valid),
    .io_train_req_bits_vaddr(stf_req_vaddr), .io_train_req_bits_pc(stf_req_pc),
    .io_l1_prefetch_req_valid(sma_l1_valid), .io_l1_prefetch_req_bits_region(sma_l1_region),
    .io_l1_prefetch_req_bits_bit_vec(sma_l1_bit_vec),
    .io_l2_l3_prefetch_req_valid(sma_l2_valid), .io_l2_l3_prefetch_req_bits_region(sma_l2_region),
    .io_l2_l3_prefetch_req_bits_bit_vec(sma_l2_bit_vec),
    .io_stream_lookup_req_valid(sma_stream_lookup_valid), .io_stream_lookup_req_bits_vaddr(sma_stream_lookup_vaddr)
  );
  TrainFilter_1 stream_train_filter (
    .clock(clock), .reset(reset), .io_enable(io_enable),
    .io_ld_in_0_valid(stream_g0_valid), .io_ld_in_0_bits_uop_robIdx_flag(io_ld_in_0_bits_uop_robIdx_flag),
    .io_ld_in_0_bits_uop_robIdx_value(io_ld_in_0_bits_uop_robIdx_value),
    .io_ld_in_0_bits_vaddr(io_ld_in_0_bits_vaddr), .io_ld_in_0_bits_miss(io_ld_in_0_bits_miss),
    .io_ld_in_0_bits_meta_prefetch(io_ld_in_0_bits_meta_prefetch),
    .io_ld_in_1_valid(stream_g1_valid), .io_ld_in_1_bits_uop_robIdx_flag(io_ld_in_1_bits_uop_robIdx_flag),
    .io_ld_in_1_bits_uop_robIdx_value(io_ld_in_1_bits_uop_robIdx_value),
    .io_ld_in_1_bits_vaddr(io_ld_in_1_bits_vaddr), .io_ld_in_1_bits_miss(io_ld_in_1_bits_miss),
    .io_ld_in_1_bits_meta_prefetch(io_ld_in_1_bits_meta_prefetch),
    .io_ld_in_2_valid(stream_g2_valid), .io_ld_in_2_bits_uop_robIdx_flag(io_ld_in_2_bits_uop_robIdx_flag),
    .io_ld_in_2_bits_uop_robIdx_value(io_ld_in_2_bits_uop_robIdx_value),
    .io_ld_in_2_bits_vaddr(io_ld_in_2_bits_vaddr), .io_ld_in_2_bits_miss(io_ld_in_2_bits_miss),
    .io_ld_in_2_bits_meta_prefetch(io_ld_in_2_bits_meta_prefetch),
    .io_train_req_ready(sbva_req_ready), .io_train_req_valid(smtf_req_valid),
    .io_train_req_bits_vaddr(smtf_req_vaddr), .io_train_req_bits_miss(smtf_req_miss),
    .io_train_req_bits_pfHitStream(smtf_req_pfHitStream)
  );
  StreamBitVectorArray stream_bit_vec_array (
    .clock(clock), .reset(reset), .io_enable(io_enable),
    .io_train_req_ready(sbva_req_ready), .io_train_req_valid(smtf_req_valid),
    .io_train_req_bits_vaddr(smtf_req_vaddr), .io_train_req_bits_miss(smtf_req_miss),
    .io_train_req_bits_pfHitStream(smtf_req_pfHitStream),
    .io_l1_prefetch_req_valid(sbva_l1_valid), .io_l1_prefetch_req_bits_region(sbva_l1_region),
    .io_l1_prefetch_req_bits_bit_vec(sbva_l1_bit_vec),
    .io_l2_l3_prefetch_req_valid(sbva_l2_valid), .io_l2_l3_prefetch_req_bits_region(sbva_l2_region),
    .io_l2_l3_prefetch_req_bits_bit_vec(sbva_l2_bit_vec), .io_l2_l3_prefetch_req_bits_sink(sbva_l2_sink),
    .io_stream_lookup_req_valid(sma_stream_lookup_valid), .io_stream_lookup_req_bits_vaddr(sma_stream_lookup_vaddr),
    .io_stream_lookup_resp(sbva_stream_lookup_resp)
  );
  MutiLevelPrefetchFilter pf_queue_filter (
    .clock(clock), .reset(reset), .io_enable(io_enable),
    .io_l1_prefetch_req_valid(pf_l1_valid), .io_l1_prefetch_req_bits_region(pf_l1_region),
    .io_l1_prefetch_req_bits_bit_vec(pf_l1_bit_vec), .io_l1_prefetch_req_bits_source_value(pf_l1_source_value),
    .io_l2_l3_prefetch_req_valid(pf_l2_valid), .io_l2_l3_prefetch_req_bits_region(pf_l2_region),
    .io_l2_l3_prefetch_req_bits_bit_vec(pf_l2_bit_vec), .io_l2_l3_prefetch_req_bits_sink(pf_l2_sink),
    .io_l2_l3_prefetch_req_bits_source_value(pf_l2_source_value),
    .io_tlb_req_req_valid(pf_tlb_req_valid), .io_tlb_req_req_bits_vaddr(io_tlb_req_req_bits_vaddr),
    .io_tlb_req_req_bits_fullva(io_tlb_req_req_bits_fullva),
    .io_tlb_req_req_bits_checkfullva(io_tlb_req_req_bits_checkfullva),
    .io_tlb_req_req_bits_cmd(io_tlb_req_req_bits_cmd), .io_tlb_req_req_bits_hyperinst(io_tlb_req_req_bits_hyperinst),
    .io_tlb_req_req_bits_hlvx(io_tlb_req_req_bits_hlvx), .io_tlb_req_req_bits_kill(io_tlb_req_req_bits_kill),
    .io_tlb_req_req_bits_isPrefetch(io_tlb_req_req_bits_isPrefetch),
    .io_tlb_req_req_bits_no_translate(io_tlb_req_req_bits_no_translate),
    .io_tlb_req_req_bits_pmp_addr(io_tlb_req_req_bits_pmp_addr),
    .io_tlb_req_req_bits_debug_robIdx_flag(io_tlb_req_req_bits_debug_robIdx_flag),
    .io_tlb_req_req_bits_debug_robIdx_value(io_tlb_req_req_bits_debug_robIdx_value),
    .io_tlb_req_req_bits_debug_isFirstIssue(io_tlb_req_req_bits_debug_isFirstIssue),
    .io_tlb_req_resp_valid(io_tlb_req_resp_valid), .io_tlb_req_resp_bits_paddr_0(io_tlb_req_resp_bits_paddr_0),
    .io_tlb_req_resp_bits_pbmt_0(io_tlb_req_resp_bits_pbmt_0), .io_tlb_req_resp_bits_miss(io_tlb_req_resp_bits_miss),
    .io_tlb_req_resp_bits_excp_0_gpf_ld(io_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_tlb_req_resp_bits_excp_0_pf_ld(io_tlb_req_resp_bits_excp_0_pf_ld),
    .io_tlb_req_resp_bits_excp_0_af_ld(io_tlb_req_resp_bits_excp_0_af_ld),
    .io_pmp_resp_ld(io_pmp_resp_ld), .io_pmp_resp_mmio(io_pmp_resp_mmio),
    .io_l1_req_ready(pf_l1_req_ready), .io_l1_req_valid(pf_l1_out_valid),
    .io_l1_req_bits_paddr(io_l1_req_bits_paddr), .io_l1_req_bits_alias(io_l1_req_bits_alias),
    .io_l1_req_bits_confidence(io_l1_req_bits_confidence), .io_l1_req_bits_is_store(io_l1_req_bits_is_store),
    .io_l1_req_bits_pf_source_value(io_l1_req_bits_pf_source_value),
    .io_l2_pf_addr_valid(pf_l2_addr_valid), .io_l2_pf_addr_bits_addr(pf_l2_addr_bits),
    .io_l2_pf_addr_bits_source(io_l2_req_bits_source), .io_confidence(pf_ctrl_confidence)
  );

endmodule
