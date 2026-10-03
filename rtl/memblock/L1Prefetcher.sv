// L1Prefetcher.sv —— 访存块的 L1 硬件预取器顶层（stride + stream 两路训练，汇到多级预取过滤队列）
//
// 位置：MemBlock 里的 L1 预取器（mem/prefetch/L1PrefetchComponent.scala:846 class L1Prefetcher）。
//   本层只做"接线 + 两处二选一 + 两个出口门控"，真正的逻辑全在 5 个子模块里（均已独立签核）：
//
//     load 流（io_ld_in_0..2）  ──► stream_train_filter（TrainFilter_1）──► stream_bit_vec_array（StreamBitVectorArray）─┐
//                                                                                    ▲ stream_lookup（stride 查 stream）   │
//     load 训练（stride_train_0..2）─► stride_train_filter（TrainFilter）──► stride_meta_array（StrideMetaArray）────────┤
//                                                                                                                       ▼
//                                                    pf_queue_filter（MutiLevelPrefetchFilter）：L1 / L2·L3 两级预取请求
//                                                    去重、过 TLB/PMP，最后吐出 io_l1_req（给 DCache）与 io_l2_req（给 L2）
//
//   两路训练滤波器各自把 3 个 load 口的训练样本去重排队；stream 表跟踪"连续区域"，stride 表跟踪
//   "固定步长"，两者各自产生 L1 与 L2/L3 两级预取请求。stride 表在产生请求前先查 stream 表
//   （stream_lookup_req），避免两路对同一区域重复预取。
//
// 本层自己的逻辑（Scala 原样）：
//   1. 训练样本门控：每个 load 口的 valid 与 io_enable 相与再进训练滤波器（预取器关掉时不训练）。
//   2. 两级请求的二选一："stream 优先于 stride"——stream 表本拍有请求就用 stream 的，否则用 stride 的；
//      请求 valid = 两者之或。请求里的 source 字段在 firtool 里已折成常量：
//        source = {2'b01, stream_valid}：stream 来源 = 3（L1_HW_PREFETCH_STREAM），stride 来源 = 2；
//        L2/L3 请求的 sink：stream 用自己的，stride 恒为 1（SINK_L2）。
//   3. 出口门控：io_l1_req.valid / io_l2_req.valid 要求 io_enable & pf_ctrl_enable；
//      pf_ctrl_enable=0 时 l1_req.ready 恒 1（让过滤队列照常流动、请求被丢弃）；
//      L2 请求还要地址落在物理内存范围 PmemRanges = [0x8000_0000, 0x800_0000_0000) 内。
//   golden 里没有 l3_req / l2PfqBusy / flush / dynamic_depth 端口：本配置下它们恒常量或无读者，被 firtool 删掉。
// golden 377 行 / 72 端口；5 个子模块两侧白盒（ref 读 golden，impl 读本仓重写件）。

module L1Prefetcher (
  input  logic        clock,
  input  logic        reset,
  input  logic        io_ld_in_0_valid,
  input  logic        io_ld_in_0_bits_uop_robIdx_flag,
  input  logic [7:0]  io_ld_in_0_bits_uop_robIdx_value,
  input  logic [49:0] io_ld_in_0_bits_vaddr,
  input  logic        io_ld_in_0_bits_miss,
  input  logic [2:0]  io_ld_in_0_bits_meta_prefetch,
  input  logic        io_ld_in_1_valid,
  input  logic        io_ld_in_1_bits_uop_robIdx_flag,
  input  logic [7:0]  io_ld_in_1_bits_uop_robIdx_value,
  input  logic [49:0] io_ld_in_1_bits_vaddr,
  input  logic        io_ld_in_1_bits_miss,
  input  logic [2:0]  io_ld_in_1_bits_meta_prefetch,
  input  logic        io_ld_in_2_valid,
  input  logic        io_ld_in_2_bits_uop_robIdx_flag,
  input  logic [7:0]  io_ld_in_2_bits_uop_robIdx_value,
  input  logic [49:0] io_ld_in_2_bits_vaddr,
  input  logic        io_ld_in_2_bits_miss,
  input  logic [2:0]  io_ld_in_2_bits_meta_prefetch,
  output logic        io_tlb_req_req_valid,
  output logic [49:0] io_tlb_req_req_bits_vaddr,
  output logic [63:0] io_tlb_req_req_bits_fullva,
  output logic        io_tlb_req_req_bits_checkfullva,
  output logic [2:0]  io_tlb_req_req_bits_cmd,
  output logic        io_tlb_req_req_bits_hyperinst,
  output logic        io_tlb_req_req_bits_hlvx,
  output logic        io_tlb_req_req_bits_kill,
  output logic        io_tlb_req_req_bits_isPrefetch,
  output logic        io_tlb_req_req_bits_no_translate,
  output logic [47:0] io_tlb_req_req_bits_pmp_addr,
  output logic        io_tlb_req_req_bits_frm_mabuf,
  output logic        io_tlb_req_req_bits_debug_robIdx_flag,
  output logic [7:0]  io_tlb_req_req_bits_debug_robIdx_value,
  output logic        io_tlb_req_req_bits_debug_isFirstIssue,
  input  logic        io_tlb_req_resp_valid,
  input  logic [47:0] io_tlb_req_resp_bits_paddr_0,
  input  logic [1:0]  io_tlb_req_resp_bits_pbmt_0,
  input  logic        io_tlb_req_resp_bits_miss,
  input  logic        io_tlb_req_resp_bits_excp_0_gpf_ld,
  input  logic        io_tlb_req_resp_bits_excp_0_pf_ld,
  input  logic        io_tlb_req_resp_bits_excp_0_af_ld,
  input  logic        io_pmp_resp_ld,
  input  logic        io_pmp_resp_mmio,
  input  logic        io_l1_req_ready,
  output logic        io_l1_req_valid,
  output logic [47:0] io_l1_req_bits_paddr,
  output logic [1:0]  io_l1_req_bits_alias,
  output logic        io_l1_req_bits_confidence,
  output logic        io_l1_req_bits_is_store,
  output logic [2:0]  io_l1_req_bits_pf_source_value,
  output logic        io_l2_req_valid,
  output logic [47:0] io_l2_req_bits_addr,
  output logic [4:0]  io_l2_req_bits_source,
  input  logic        io_enable,
  input  logic        pf_ctrl_enable,
  input  logic        pf_ctrl_confidence,
  input  logic        stride_train_0_valid,
  input  logic [49:0] stride_train_0_bits_uop_pc,
  input  logic        stride_train_0_bits_uop_robIdx_flag,
  input  logic [7:0]  stride_train_0_bits_uop_robIdx_value,
  input  logic [49:0] stride_train_0_bits_vaddr,
  input  logic        stride_train_1_valid,
  input  logic [49:0] stride_train_1_bits_uop_pc,
  input  logic        stride_train_1_bits_uop_robIdx_flag,
  input  logic [7:0]  stride_train_1_bits_uop_robIdx_value,
  input  logic [49:0] stride_train_1_bits_vaddr,
  input  logic        stride_train_2_valid,
  input  logic [49:0] stride_train_2_bits_uop_pc,
  input  logic        stride_train_2_bits_uop_robIdx_flag,
  input  logic [7:0]  stride_train_2_bits_uop_robIdx_value,
  input  logic [49:0] stride_train_2_bits_vaddr
);

  localparam logic [2:0]  SRC_STRIDE = 3'd2;              // L1_HW_PREFETCH_STRIDE
  localparam logic [2:0]  SRC_STREAM = 3'd3;              // L1_HW_PREFETCH_STREAM
  localparam logic [1:0]  SINK_L2    = 2'b01;
  localparam logic [47:0] PMEM_BASE  = 48'h0000_8000_0000; // PmemRanges：[2 GiB, 8 TiB)
  localparam logic [47:0] PMEM_TOP   = 48'h0800_0000_0000;

  // ===========================================================================
  // 1. stride 训练：stride_train_* → stride_train_filter → stride_meta_array
  // ===========================================================================
  logic        stride_train_req_valid, stride_train_req_ready;
  logic [49:0] stride_train_req_vaddr, stride_train_req_pc;

  TrainFilter stride_train_filter (
    .clock                            (clock),
    .reset                            (reset),
    .io_enable                        (io_enable),
    .io_ld_in_0_valid                 (stride_train_0_valid & io_enable),
    .io_ld_in_0_bits_uop_pc           (stride_train_0_bits_uop_pc),
    .io_ld_in_0_bits_uop_robIdx_flag  (stride_train_0_bits_uop_robIdx_flag),
    .io_ld_in_0_bits_uop_robIdx_value (stride_train_0_bits_uop_robIdx_value),
    .io_ld_in_0_bits_vaddr            (stride_train_0_bits_vaddr),
    .io_ld_in_1_valid                 (stride_train_1_valid & io_enable),
    .io_ld_in_1_bits_uop_pc           (stride_train_1_bits_uop_pc),
    .io_ld_in_1_bits_uop_robIdx_flag  (stride_train_1_bits_uop_robIdx_flag),
    .io_ld_in_1_bits_uop_robIdx_value (stride_train_1_bits_uop_robIdx_value),
    .io_ld_in_1_bits_vaddr            (stride_train_1_bits_vaddr),
    .io_ld_in_2_valid                 (stride_train_2_valid & io_enable),
    .io_ld_in_2_bits_uop_pc           (stride_train_2_bits_uop_pc),
    .io_ld_in_2_bits_uop_robIdx_flag  (stride_train_2_bits_uop_robIdx_flag),
    .io_ld_in_2_bits_uop_robIdx_value (stride_train_2_bits_uop_robIdx_value),
    .io_ld_in_2_bits_vaddr            (stride_train_2_bits_vaddr),
    .io_train_req_ready               (stride_train_req_ready),
    .io_train_req_valid               (stride_train_req_valid),
    .io_train_req_bits_vaddr          (stride_train_req_vaddr),
    .io_train_req_bits_pc             (stride_train_req_pc)
  );

  // stride 表产生的两级预取请求 + 对 stream 表的查询
  logic        stride_l1_valid, stride_l2l3_valid;
  logic [39:0] stride_l1_region, stride_l2l3_region;
  logic [15:0] stride_l1_bit_vec, stride_l2l3_bit_vec;
  logic        stream_lookup_valid;
  logic [49:0] stream_lookup_vaddr;

  StrideMetaArray stride_meta_array (
    .clock                              (clock),
    .reset                              (reset),
    .io_train_req_ready                 (stride_train_req_ready),
    .io_train_req_valid                 (stride_train_req_valid),
    .io_train_req_bits_vaddr            (stride_train_req_vaddr),
    .io_train_req_bits_pc               (stride_train_req_pc),
    .io_l1_prefetch_req_valid           (stride_l1_valid),
    .io_l1_prefetch_req_bits_region     (stride_l1_region),
    .io_l1_prefetch_req_bits_bit_vec    (stride_l1_bit_vec),
    .io_l2_l3_prefetch_req_valid        (stride_l2l3_valid),
    .io_l2_l3_prefetch_req_bits_region  (stride_l2l3_region),
    .io_l2_l3_prefetch_req_bits_bit_vec (stride_l2l3_bit_vec),
    .io_stream_lookup_req_valid         (stream_lookup_valid),
    .io_stream_lookup_req_bits_vaddr    (stream_lookup_vaddr)
  );

  // ===========================================================================
  // 2. stream 训练：io_ld_in_* → stream_train_filter → stream_bit_vec_array
  // ===========================================================================
  logic        stream_train_req_valid, stream_train_req_ready;
  logic [49:0] stream_train_req_vaddr;
  logic        stream_train_req_miss, stream_train_req_pf_hit_stream;

  TrainFilter_1 stream_train_filter (
    .clock                            (clock),
    .reset                            (reset),
    .io_enable                        (io_enable),
    .io_ld_in_0_valid                 (io_ld_in_0_valid & io_enable),
    .io_ld_in_0_bits_uop_robIdx_flag  (io_ld_in_0_bits_uop_robIdx_flag),
    .io_ld_in_0_bits_uop_robIdx_value (io_ld_in_0_bits_uop_robIdx_value),
    .io_ld_in_0_bits_vaddr            (io_ld_in_0_bits_vaddr),
    .io_ld_in_0_bits_miss             (io_ld_in_0_bits_miss),
    .io_ld_in_0_bits_meta_prefetch    (io_ld_in_0_bits_meta_prefetch),
    .io_ld_in_1_valid                 (io_ld_in_1_valid & io_enable),
    .io_ld_in_1_bits_uop_robIdx_flag  (io_ld_in_1_bits_uop_robIdx_flag),
    .io_ld_in_1_bits_uop_robIdx_value (io_ld_in_1_bits_uop_robIdx_value),
    .io_ld_in_1_bits_vaddr            (io_ld_in_1_bits_vaddr),
    .io_ld_in_1_bits_miss             (io_ld_in_1_bits_miss),
    .io_ld_in_1_bits_meta_prefetch    (io_ld_in_1_bits_meta_prefetch),
    .io_ld_in_2_valid                 (io_ld_in_2_valid & io_enable),
    .io_ld_in_2_bits_uop_robIdx_flag  (io_ld_in_2_bits_uop_robIdx_flag),
    .io_ld_in_2_bits_uop_robIdx_value (io_ld_in_2_bits_uop_robIdx_value),
    .io_ld_in_2_bits_vaddr            (io_ld_in_2_bits_vaddr),
    .io_ld_in_2_bits_miss             (io_ld_in_2_bits_miss),
    .io_ld_in_2_bits_meta_prefetch    (io_ld_in_2_bits_meta_prefetch),
    .io_train_req_ready               (stream_train_req_ready),
    .io_train_req_valid               (stream_train_req_valid),
    .io_train_req_bits_vaddr          (stream_train_req_vaddr),
    .io_train_req_bits_miss           (stream_train_req_miss),
    .io_train_req_bits_pfHitStream    (stream_train_req_pf_hit_stream)
  );

  // stream 表产生的两级预取请求；stream_lookup_resp 在本配置下 stride 表不读（golden 同样悬空）
  logic        stream_l1_valid, stream_l2l3_valid;
  logic [39:0] stream_l1_region, stream_l2l3_region;
  logic [15:0] stream_l1_bit_vec, stream_l2l3_bit_vec;
  logic [1:0]  stream_l2l3_sink;
  logic        stream_lookup_resp_unused;

  StreamBitVectorArray stream_bit_vec_array (
    .clock                              (clock),
    .reset                              (reset),
    .io_enable                          (io_enable),
    .io_train_req_ready                 (stream_train_req_ready),
    .io_train_req_valid                 (stream_train_req_valid),
    .io_train_req_bits_vaddr            (stream_train_req_vaddr),
    .io_train_req_bits_miss             (stream_train_req_miss),
    .io_train_req_bits_pfHitStream      (stream_train_req_pf_hit_stream),
    .io_l1_prefetch_req_valid           (stream_l1_valid),
    .io_l1_prefetch_req_bits_region     (stream_l1_region),
    .io_l1_prefetch_req_bits_bit_vec    (stream_l1_bit_vec),
    .io_l2_l3_prefetch_req_valid        (stream_l2l3_valid),
    .io_l2_l3_prefetch_req_bits_region  (stream_l2l3_region),
    .io_l2_l3_prefetch_req_bits_bit_vec (stream_l2l3_bit_vec),
    .io_l2_l3_prefetch_req_bits_sink    (stream_l2l3_sink),
    .io_stream_lookup_req_valid         (stream_lookup_valid),
    .io_stream_lookup_req_bits_vaddr    (stream_lookup_vaddr),
    .io_stream_lookup_resp              (stream_lookup_resp_unused)
  );

  // ===========================================================================
  // 3. 两级请求二选一：stream 优先于 stride
  // ===========================================================================
  logic        pf_l1_valid, pf_l2l3_valid;
  logic [39:0] pf_l1_region, pf_l2l3_region;
  logic [15:0] pf_l1_bit_vec, pf_l2l3_bit_vec;
  logic [2:0]  pf_l1_source, pf_l2l3_source;
  logic [1:0]  pf_l2l3_sink;

  assign pf_l1_valid     = stream_l1_valid | stride_l1_valid;
  assign pf_l1_region    = stream_l1_valid ? stream_l1_region  : stride_l1_region;
  assign pf_l1_bit_vec   = stream_l1_valid ? stream_l1_bit_vec : stride_l1_bit_vec;
  assign pf_l1_source    = stream_l1_valid ? SRC_STREAM        : SRC_STRIDE;

  assign pf_l2l3_valid   = stream_l2l3_valid | stride_l2l3_valid;
  assign pf_l2l3_region  = stream_l2l3_valid ? stream_l2l3_region  : stride_l2l3_region;
  assign pf_l2l3_bit_vec = stream_l2l3_valid ? stream_l2l3_bit_vec : stride_l2l3_bit_vec;
  assign pf_l2l3_sink    = stream_l2l3_valid ? stream_l2l3_sink    : SINK_L2;
  assign pf_l2l3_source  = stream_l2l3_valid ? SRC_STREAM          : SRC_STRIDE;

  // ===========================================================================
  // 4. 多级预取过滤队列（去重 / TLB / PMP），以及两个出口门控
  // ===========================================================================
  logic        filter_l1_req_valid;
  logic        filter_l2_pf_valid;
  logic [47:0] filter_l2_pf_addr;

  MutiLevelPrefetchFilter pf_queue_filter (
    .clock                                   (clock),
    .reset                                   (reset),
    .io_enable                               (io_enable),
    .io_l1_prefetch_req_valid                (pf_l1_valid),
    .io_l1_prefetch_req_bits_region          (pf_l1_region),
    .io_l1_prefetch_req_bits_bit_vec         (pf_l1_bit_vec),
    .io_l1_prefetch_req_bits_source_value    (pf_l1_source),
    .io_l2_l3_prefetch_req_valid             (pf_l2l3_valid),
    .io_l2_l3_prefetch_req_bits_region       (pf_l2l3_region),
    .io_l2_l3_prefetch_req_bits_bit_vec      (pf_l2l3_bit_vec),
    .io_l2_l3_prefetch_req_bits_sink         (pf_l2l3_sink),
    .io_l2_l3_prefetch_req_bits_source_value (pf_l2l3_source),
    .io_tlb_req_req_valid                    (io_tlb_req_req_valid),
    .io_tlb_req_req_bits_vaddr               (io_tlb_req_req_bits_vaddr),
    .io_tlb_req_req_bits_fullva              (io_tlb_req_req_bits_fullva),
    .io_tlb_req_req_bits_checkfullva         (io_tlb_req_req_bits_checkfullva),
    .io_tlb_req_req_bits_cmd                 (io_tlb_req_req_bits_cmd),
    .io_tlb_req_req_bits_hyperinst           (io_tlb_req_req_bits_hyperinst),
    .io_tlb_req_req_bits_hlvx                (io_tlb_req_req_bits_hlvx),
    .io_tlb_req_req_bits_kill                (io_tlb_req_req_bits_kill),
    .io_tlb_req_req_bits_isPrefetch          (io_tlb_req_req_bits_isPrefetch),
    .io_tlb_req_req_bits_no_translate        (io_tlb_req_req_bits_no_translate),
    .io_tlb_req_req_bits_pmp_addr            (io_tlb_req_req_bits_pmp_addr),
    .io_tlb_req_req_bits_frm_mabuf           (io_tlb_req_req_bits_frm_mabuf),
    .io_tlb_req_req_bits_debug_robIdx_flag   (io_tlb_req_req_bits_debug_robIdx_flag),
    .io_tlb_req_req_bits_debug_robIdx_value  (io_tlb_req_req_bits_debug_robIdx_value),
    .io_tlb_req_req_bits_debug_isFirstIssue  (io_tlb_req_req_bits_debug_isFirstIssue),
    .io_tlb_req_resp_valid                   (io_tlb_req_resp_valid),
    .io_tlb_req_resp_bits_paddr_0            (io_tlb_req_resp_bits_paddr_0),
    .io_tlb_req_resp_bits_pbmt_0             (io_tlb_req_resp_bits_pbmt_0),
    .io_tlb_req_resp_bits_miss               (io_tlb_req_resp_bits_miss),
    .io_tlb_req_resp_bits_excp_0_gpf_ld      (io_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_tlb_req_resp_bits_excp_0_pf_ld       (io_tlb_req_resp_bits_excp_0_pf_ld),
    .io_tlb_req_resp_bits_excp_0_af_ld       (io_tlb_req_resp_bits_excp_0_af_ld),
    .io_pmp_resp_ld                          (io_pmp_resp_ld),
    .io_pmp_resp_mmio                        (io_pmp_resp_mmio),
    // 预取关掉（pf_ctrl_enable=0）时假装 DCache 永远接收，让过滤队列照常流动、请求被丢弃
    .io_l1_req_ready                         (~pf_ctrl_enable | io_l1_req_ready),
    .io_l1_req_valid                         (filter_l1_req_valid),
    .io_l1_req_bits_paddr                    (io_l1_req_bits_paddr),
    .io_l1_req_bits_alias                    (io_l1_req_bits_alias),
    .io_l1_req_bits_confidence               (io_l1_req_bits_confidence),
    .io_l1_req_bits_is_store                 (io_l1_req_bits_is_store),
    .io_l1_req_bits_pf_source_value          (io_l1_req_bits_pf_source_value),
    .io_l2_pf_addr_valid                     (filter_l2_pf_valid),
    .io_l2_pf_addr_bits_addr                 (filter_l2_pf_addr),
    .io_l2_pf_addr_bits_source               (io_l2_req_bits_source),
    .io_confidence                           (pf_ctrl_confidence)
  );

  // L2 请求只发往物理内存范围（PmemRanges.cover）
  logic l2_in_pmem;
  assign l2_in_pmem = (filter_l2_pf_addr >= PMEM_BASE) & (filter_l2_pf_addr < PMEM_TOP);

  assign io_l1_req_valid     = filter_l1_req_valid & io_enable & pf_ctrl_enable;
  assign io_l2_req_valid     = filter_l2_pf_valid & l2_in_pmem & io_enable & pf_ctrl_enable;
  assign io_l2_req_bits_addr = filter_l2_pf_addr;

endmodule
