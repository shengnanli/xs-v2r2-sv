// =============================================================================
// SMSPrefetcher —— SMS（Spatial Memory Streaming）空间预取器总控
//
// Scala：src/main/scala/xiangshan/mem/prefetch/SMSPrefetcher.scala，class SMSPrefetcher。
// 位置：MemBlock → L1Prefetcher（本模块）→ 发往 L2 的预取地址（io_l2_req）。
//
// SMS 把访存按 1KB "区域"（16 个 64B 块）观察：一个区域活跃期间被访问过哪些块，记成 16 位位图；
// 同一条 load PC 下次在新区域里"开张"时，按学到的位图把这一片块一起预取。本模块只是装配与胶合：
//
//   train_filter（SMSTrainFilter）  3 路 load 训练口去重，每拍至多吐一条训练请求
//        │  vaddr / paddr / pc
//        ▼ （训练请求）
//   §1 s0 训练寄存器（本核）        把训练请求按区域切好：区域 tag（带 vaddr 哈希）、前/后相邻区域的 tag、
//        │                         能否跨到相邻区域、区域内块偏移、PHT 的 index/tag（取自 PC）、区域虚/实地址
//        ▼ （s0 查表请求）
//   active_gen_table（AGT）         活跃区域表：累积位图；区域被逐出时交给 PHT 学习，未命中时查 PHT
//        │  s2_evict / s2_pht_lookup
//        ▼ （逐出学习 / 未命中查询）
//   pht（PatternHistoryTable）      按 PC 哈希记"模式"，命中就产生一个区域预取请求（region + 位图）
//        │  pf_gen_req（§2：受 io_pht_en 门控）
//        ▼ （区域预取请求）
//   pf_filter（PrefetchFilter）     预取去重 + 走 TLB 翻译（io_tlb_req / io_pmp_resp）→ 逐块吐出物理地址
//        │  l2_pf_addr
//        ▼ （逐块物理地址）
//   §3 L2 请求门控（本核）           io_enable 打开且地址落在物理内存范围内才真正发给 L2
//
//   stride（StridePF）              步长预取器。本配置下 stride_en 被接 0、它的预取输出没人接，firtool
//                                   把它的全部输出端口裁掉了 —— 它只剩训练寄存器，对外不可见。照 golden 例化。
//
// 怪癖（照 golden，本配置 KunminghuV2）：
//   * AGT 与 stride 自己的预取请求（Scala 里与 PHT 的请求 Mux1H 合流）在本配置被 firtool 删光，
//     送进 pf_filter 的只剩 PHT 那一路：valid = pht.valid & io_pht_en，bits 直接取 PHT 的。
//   * s0 的区域实地址只存 paddr[47:10] 共 38 位，送给 AGT 时高位补 2 个 0 凑成 40 位区域地址。
//   * s0 的 PC 寄存器存满 50 位，但只有低 10 位送给 StridePF（而 StridePF 对外不可见）——死位，照存。
//   * 相邻区域地址在 21 位"原始区域地址"上 ±1，进位/借位出到第 22 位就表示越界、不许跨过去。
//   * 物理内存范围 = [0x8000_0000, 0x800_0000_0000)（PmemRanges），范围外的预取地址直接丢掉。
//   * Scala 的 l1_req 恒 valid=0，被 firtool 连同端口一起删掉；训练口的 miss / meta_prefetch 只喂性能计数。
//
// child（实例名同 golden，均已签核，两侧白盒）：train_filter / active_gen_table / stride / pht / pf_filter。
// 文件后半部的 golden 同名 wrapper 由 scripts/gen_sms.py 从 golden 端口表与实例连线机械生成。
//
// 本文件导航：
//   xs_SMSPrefetcher_core …… §1 s0 训练寄存器  §2 PHT 预取请求门控  §3 L2 请求门控
//   SMSPrefetcher（wrapper）… golden 端口表 / 核 / 5 个 child 的逐端口连线（scripts/gen_sms.py 生成）
// =============================================================================

module xs_SMSPrefetcher_core (
  input  logic        clock,
  input  logic        reset,
  // ---- 来自 train_filter 的训练请求 ----
  input  logic        train_valid,
  input  logic [49:0] train_vaddr,
  input  logic [47:0] train_paddr,
  input  logic [49:0] train_pc,
  // ---- s0 训练寄存器：送 AGT 查表 / StridePF ----
  output logic        s0_valid,
  output logic [49:0] s0_pc,
  output logic [10:0] s0_region_tag,
  output logic [10:0] s0_region_p1_tag,
  output logic [10:0] s0_region_m1_tag,
  output logic        s0_allow_cross_p1,
  output logic        s0_allow_cross_m1,
  output logic [12:0] s0_pht_tag,
  output logic [4:0]  s0_pht_index,
  output logic [3:0]  s0_region_offset,
  output logic [39:0] s0_region_paddr,
  output logic [39:0] s0_region_vaddr,
  // ---- PHT 预取请求 → pf_filter ----
  input  logic        pht_en,
  input  logic        pht_gen_valid,
  output logic        filter_gen_valid,
  // ---- pf_filter → L2 ----
  input  logic        enable,
  input  logic        l2_pf_valid,
  input  logic [47:0] l2_pf_addr,
  output logic        l2_req_valid
);

  // ===========================================================================
  // §1 s0 训练寄存器
  //   训练请求到来的那一拍，把地址切成"区域"视角存一拍，下一拍送 AGT 查表：
  //     原始区域地址 raw = vaddr[30:10]（21 位：区域号的低 6 位 + 3×5 位用来哈希的高位）；
  //     区域 tag = {raw 高 15 位三段 5 位异或, raw 低 6 位}（11 位）；
  //     相邻区域 = raw ± 1（22 位算，第 22 位溢出即越界，不许跨），tag 同样哈希；
  //     区域内块偏移 = vaddr[9:6]；PHT index = {pc[1]^pc[6], pc[5:2]}，PHT tag = pc[19:7]。
  //   valid 带异步复位；数据位只在训练请求有效时更新（RegEnable）。
  // ===========================================================================
  // 区域哈希 tag：输入 21 位原始区域地址
  function automatic logic [10:0] region_hash_tag(input logic [20:0] rg);
    return {rg[10:6] ^ rg[15:11] ^ rg[20:16], rg[5:0]};
  endfunction

  logic [20:0] region_raw;
  logic [21:0] region_p1;
  logic [21:0] region_m1;
  logic [37:0] region_paddr_q;   // paddr[47:10]

  assign region_raw = train_vaddr[30:10];
  assign region_p1  = {1'b0, region_raw} + 22'd1;
  assign region_m1  = {1'b0, region_raw} - 22'd1;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) s0_valid <= 1'b0;
    else       s0_valid <= train_valid;
  end

  always_ff @(posedge clock) begin
    if (train_valid) begin
      s0_pc             <= train_pc;
      s0_region_tag     <= region_hash_tag(region_raw);
      s0_region_p1_tag  <= region_hash_tag(region_p1[20:0]);
      s0_region_m1_tag  <= region_hash_tag(region_m1[20:0]);
      s0_allow_cross_p1 <= ~region_p1[21];
      s0_allow_cross_m1 <= ~region_m1[21];
      s0_pht_tag        <= train_pc[19:7];
      s0_pht_index      <= {train_pc[1] ^ train_pc[6], train_pc[5:2]};
      s0_region_offset  <= train_vaddr[9:6];
      region_paddr_q    <= train_paddr[47:10];
      s0_region_vaddr   <= train_vaddr[49:10];
    end
  end

  assign s0_region_paddr = {2'b00, region_paddr_q};

  // ===========================================================================
  // §2 PHT 预取请求门控
  //   本配置下送进 pf_filter 的只有 PHT 一路；io_pht_en 关掉时请求被吞掉（PHT 自己照常出队）。
  // ===========================================================================
  assign filter_gen_valid = pht_gen_valid & pht_en;

  // ===========================================================================
  // §3 L2 请求门控
  //   pf_filter 吐出的块地址只有在总开关 io_enable 打开、且落在物理内存范围内时才发给 L2。
  // ===========================================================================
  localparam logic [47:0] PMEM_BASE = 48'h0000_8000_0000;
  localparam logic [47:0] PMEM_END  = 48'h0800_0000_0000;

  assign l2_req_valid = l2_pf_valid & enable & (l2_pf_addr >= PMEM_BASE) & (l2_pf_addr < PMEM_END);

endmodule

// -----------------------------------------------------------------------------
// golden 同名 wrapper：端口表照抄 golden；核 + 5 个 child 的逐端口连线
// （scripts/gen_sms.py 生成，勿手改）
// -----------------------------------------------------------------------------
// BEGIN GENERATED(sms-wrapper)
module SMSPrefetcher (
  input            clock,
  input            reset,
  input            io_ld_in_0_valid,
  input  [49:0]    io_ld_in_0_bits_uop_pc,
  input            io_ld_in_0_bits_uop_robIdx_flag,
  input  [7:0]     io_ld_in_0_bits_uop_robIdx_value,
  input  [49:0]    io_ld_in_0_bits_vaddr,
  input  [47:0]    io_ld_in_0_bits_paddr,
  input            io_ld_in_0_bits_miss,
  input  [2:0]     io_ld_in_0_bits_meta_prefetch,
  input            io_ld_in_1_valid,
  input  [49:0]    io_ld_in_1_bits_uop_pc,
  input            io_ld_in_1_bits_uop_robIdx_flag,
  input  [7:0]     io_ld_in_1_bits_uop_robIdx_value,
  input  [49:0]    io_ld_in_1_bits_vaddr,
  input  [47:0]    io_ld_in_1_bits_paddr,
  input            io_ld_in_1_bits_miss,
  input  [2:0]     io_ld_in_1_bits_meta_prefetch,
  input            io_ld_in_2_valid,
  input  [49:0]    io_ld_in_2_bits_uop_pc,
  input            io_ld_in_2_bits_uop_robIdx_flag,
  input  [7:0]     io_ld_in_2_bits_uop_robIdx_value,
  input  [49:0]    io_ld_in_2_bits_vaddr,
  input  [47:0]    io_ld_in_2_bits_paddr,
  input            io_ld_in_2_bits_miss,
  input  [2:0]     io_ld_in_2_bits_meta_prefetch,
  output           io_tlb_req_req_valid,
  output [49:0]    io_tlb_req_req_bits_vaddr,
  output [63:0]    io_tlb_req_req_bits_fullva,
  output           io_tlb_req_req_bits_checkfullva,
  output [2:0]     io_tlb_req_req_bits_cmd,
  output           io_tlb_req_req_bits_hyperinst,
  output           io_tlb_req_req_bits_hlvx,
  output           io_tlb_req_req_bits_kill,
  output           io_tlb_req_req_bits_isPrefetch,
  output           io_tlb_req_req_bits_no_translate,
  output [47:0]    io_tlb_req_req_bits_pmp_addr,
  output           io_tlb_req_req_bits_frm_mabuf,
  output           io_tlb_req_req_bits_debug_robIdx_flag,
  output [7:0]     io_tlb_req_req_bits_debug_robIdx_value,
  output           io_tlb_req_req_bits_debug_isFirstIssue,
  input            io_tlb_req_resp_valid,
  input  [47:0]    io_tlb_req_resp_bits_paddr_0,
  input  [1:0]     io_tlb_req_resp_bits_pbmt_0,
  input            io_tlb_req_resp_bits_miss,
  input            io_tlb_req_resp_bits_excp_0_gpf_ld,
  input            io_tlb_req_resp_bits_excp_0_pf_ld,
  input            io_tlb_req_resp_bits_excp_0_af_ld,
  input            io_pmp_resp_ld,
  input            io_pmp_resp_mmio,
  output           io_l2_req_valid,
  output [47:0]    io_l2_req_bits_addr,
  input            io_enable,
  input            io_agt_en,
  input            io_pht_en,
  input  [3:0]     io_act_threshold,
  input  [5:0]     io_act_stride,
  input            io_dcache_evict_valid,
  input  [49:0]    io_dcache_evict_bits_vaddr,
  input  [5:0]     boreChildrenBd_bore_addr,
  input  [5:0]     boreChildrenBd_bore_addr_rd,
  input  [147:0]   boreChildrenBd_bore_wdata,
  input  [1:0]     boreChildrenBd_bore_wmask,
  input            boreChildrenBd_bore_re,
  input            boreChildrenBd_bore_we,
  output [147:0]   boreChildrenBd_bore_rdata,
  input            boreChildrenBd_bore_ack,
  input            boreChildrenBd_bore_selectedOH,
  input  [6:0]     boreChildrenBd_bore_array,
  input            sigFromSrams_bore_ram_hold,
  input            sigFromSrams_bore_ram_bypass,
  input            sigFromSrams_bore_ram_bp_clken,
  input            sigFromSrams_bore_ram_aux_clk,
  input            sigFromSrams_bore_ram_aux_ckbp,
  input            sigFromSrams_bore_ram_mcp_hold,
  input            sigFromSrams_bore_cgen
);

  // ---- child 输出线（golden `_<实例>_<端口>` 去掉前导下划线）----
  wire          pf_filter_io_l2_pf_addr_valid;
  wire [47:0]   pf_filter_io_l2_pf_addr_bits;
  wire          pht_io_pf_gen_req_valid;
  wire [10:0]   pht_io_pf_gen_req_bits_region_tag;
  wire [39:0]   pht_io_pf_gen_req_bits_region_addr;
  wire [15:0]   pht_io_pf_gen_req_bits_region_bits;
  wire          pht_io_pf_gen_req_bits_paddr_valid;
  wire          pht_io_pf_gen_req_bits_decr_mode;
  wire          active_gen_table_io_s1_sel_stride;
  wire          active_gen_table_io_s2_pht_lookup_valid;
  wire [4:0]    active_gen_table_io_s2_pht_lookup_bits_pht_index;
  wire [12:0]   active_gen_table_io_s2_pht_lookup_bits_pht_tag;
  wire [39:0]   active_gen_table_io_s2_pht_lookup_bits_region_paddr;
  wire [39:0]   active_gen_table_io_s2_pht_lookup_bits_region_vaddr;
  wire [3:0]    active_gen_table_io_s2_pht_lookup_bits_region_offset;
  wire          active_gen_table_io_s2_evict_valid;
  wire [4:0]    active_gen_table_io_s2_evict_bits_pht_index;
  wire [12:0]   active_gen_table_io_s2_evict_bits_pht_tag;
  wire [15:0]   active_gen_table_io_s2_evict_bits_region_bits;
  wire [15:0]   active_gen_table_io_s2_evict_bits_region_bit_single;
  wire [3:0]    active_gen_table_io_s2_evict_bits_region_offset;
  wire [3:0]    active_gen_table_io_s2_evict_bits_access_cnt;
  wire          active_gen_table_io_s2_evict_bits_decr_mode;
  wire          active_gen_table_io_s2_evict_bits_single_update;
  wire          active_gen_table_io_s2_evict_bits_has_been_signal_updated;
  wire          train_filter_io_train_req_valid;
  wire [49:0]   train_filter_io_train_req_bits_vaddr;
  wire [47:0]   train_filter_io_train_req_bits_paddr;
  wire [49:0]   train_filter_io_train_req_bits_pc;
  // ---- 核输出线 ----
  wire          s0_valid;
  wire [49:0]   s0_pc;
  wire [10:0]   s0_region_tag;
  wire [10:0]   s0_region_p1_tag;
  wire [10:0]   s0_region_m1_tag;
  wire          s0_allow_cross_p1;
  wire          s0_allow_cross_m1;
  wire [12:0]   s0_pht_tag;
  wire [4:0]    s0_pht_index;
  wire [3:0]    s0_region_offset;
  wire [39:0]   s0_region_paddr;
  wire [39:0]   s0_region_vaddr;
  wire          filter_gen_valid;

  xs_SMSPrefetcher_core u_core (
    .clock              (clock),
    .reset              (reset),
    .train_valid        (train_filter_io_train_req_valid),
    .train_vaddr        (train_filter_io_train_req_bits_vaddr),
    .train_paddr        (train_filter_io_train_req_bits_paddr),
    .train_pc           (train_filter_io_train_req_bits_pc),
    .s0_valid           (s0_valid),
    .s0_pc              (s0_pc),
    .s0_region_tag      (s0_region_tag),
    .s0_region_p1_tag   (s0_region_p1_tag),
    .s0_region_m1_tag   (s0_region_m1_tag),
    .s0_allow_cross_p1  (s0_allow_cross_p1),
    .s0_allow_cross_m1  (s0_allow_cross_m1),
    .s0_pht_tag         (s0_pht_tag),
    .s0_pht_index       (s0_pht_index),
    .s0_region_offset   (s0_region_offset),
    .s0_region_paddr    (s0_region_paddr),
    .s0_region_vaddr    (s0_region_vaddr),
    .pht_en             (io_pht_en),
    .pht_gen_valid      (pht_io_pf_gen_req_valid),
    .filter_gen_valid   (filter_gen_valid),
    .enable             (io_enable),
    .l2_pf_valid        (pf_filter_io_l2_pf_addr_valid),
    .l2_pf_addr         (pf_filter_io_l2_pf_addr_bits),
    .l2_req_valid       (io_l2_req_valid)
  );

  SMSTrainFilter train_filter (
    .clock                            (clock),
    .reset                            (reset),
    .io_ld_in_0_valid                 (io_ld_in_0_valid),
    .io_ld_in_0_bits_uop_pc           (io_ld_in_0_bits_uop_pc),
    .io_ld_in_0_bits_uop_robIdx_flag  (io_ld_in_0_bits_uop_robIdx_flag),
    .io_ld_in_0_bits_uop_robIdx_value (io_ld_in_0_bits_uop_robIdx_value),
    .io_ld_in_0_bits_vaddr            (io_ld_in_0_bits_vaddr),
    .io_ld_in_0_bits_paddr            (io_ld_in_0_bits_paddr),
    .io_ld_in_1_valid                 (io_ld_in_1_valid),
    .io_ld_in_1_bits_uop_pc           (io_ld_in_1_bits_uop_pc),
    .io_ld_in_1_bits_uop_robIdx_flag  (io_ld_in_1_bits_uop_robIdx_flag),
    .io_ld_in_1_bits_uop_robIdx_value (io_ld_in_1_bits_uop_robIdx_value),
    .io_ld_in_1_bits_vaddr            (io_ld_in_1_bits_vaddr),
    .io_ld_in_1_bits_paddr            (io_ld_in_1_bits_paddr),
    .io_ld_in_2_valid                 (io_ld_in_2_valid),
    .io_ld_in_2_bits_uop_pc           (io_ld_in_2_bits_uop_pc),
    .io_ld_in_2_bits_uop_robIdx_flag  (io_ld_in_2_bits_uop_robIdx_flag),
    .io_ld_in_2_bits_uop_robIdx_value (io_ld_in_2_bits_uop_robIdx_value),
    .io_ld_in_2_bits_vaddr            (io_ld_in_2_bits_vaddr),
    .io_ld_in_2_bits_paddr            (io_ld_in_2_bits_paddr),
    .io_train_req_valid               (train_filter_io_train_req_valid),
    .io_train_req_bits_vaddr          (train_filter_io_train_req_bits_vaddr),
    .io_train_req_bits_paddr          (train_filter_io_train_req_bits_paddr),
    .io_train_req_bits_pc             (train_filter_io_train_req_bits_pc)
  );

  ActiveGenerationTable active_gen_table (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_agt_en                                (io_agt_en),
    .io_s0_lookup_valid                       (s0_valid),
    .io_s0_lookup_bits_region_tag             (s0_region_tag),
    .io_s0_lookup_bits_region_p1_tag          (s0_region_p1_tag),
    .io_s0_lookup_bits_region_m1_tag          (s0_region_m1_tag),
    .io_s0_lookup_bits_region_offset          (s0_region_offset),
    .io_s0_lookup_bits_pht_index              (s0_pht_index),
    .io_s0_lookup_bits_pht_tag                (s0_pht_tag),
    .io_s0_lookup_bits_allow_cross_region_p1  (s0_allow_cross_p1),
    .io_s0_lookup_bits_allow_cross_region_m1  (s0_allow_cross_m1),
    .io_s0_lookup_bits_region_paddr           (s0_region_paddr),
    .io_s0_lookup_bits_region_vaddr           (s0_region_vaddr),
    .io_s0_dcache_evict_valid                 (io_dcache_evict_valid),
    .io_s0_dcache_evict_bits_vaddr            (io_dcache_evict_bits_vaddr),
    .io_s1_sel_stride                         (active_gen_table_io_s1_sel_stride),
    .io_s2_pht_lookup_valid                   (active_gen_table_io_s2_pht_lookup_valid),
    .io_s2_pht_lookup_bits_pht_index          (active_gen_table_io_s2_pht_lookup_bits_pht_index),
    .io_s2_pht_lookup_bits_pht_tag            (active_gen_table_io_s2_pht_lookup_bits_pht_tag),
    .io_s2_pht_lookup_bits_region_paddr       (active_gen_table_io_s2_pht_lookup_bits_region_paddr),
    .io_s2_pht_lookup_bits_region_vaddr       (active_gen_table_io_s2_pht_lookup_bits_region_vaddr),
    .io_s2_pht_lookup_bits_region_offset      (active_gen_table_io_s2_pht_lookup_bits_region_offset),
    .io_s2_evict_valid                        (active_gen_table_io_s2_evict_valid),
    .io_s2_evict_bits_pht_index               (active_gen_table_io_s2_evict_bits_pht_index),
    .io_s2_evict_bits_pht_tag                 (active_gen_table_io_s2_evict_bits_pht_tag),
    .io_s2_evict_bits_region_bits             (active_gen_table_io_s2_evict_bits_region_bits),
    .io_s2_evict_bits_region_bit_single       (active_gen_table_io_s2_evict_bits_region_bit_single),
    .io_s2_evict_bits_region_offset           (active_gen_table_io_s2_evict_bits_region_offset),
    .io_s2_evict_bits_access_cnt              (active_gen_table_io_s2_evict_bits_access_cnt),
    .io_s2_evict_bits_decr_mode               (active_gen_table_io_s2_evict_bits_decr_mode),
    .io_s2_evict_bits_single_update           (active_gen_table_io_s2_evict_bits_single_update),
    .io_s2_evict_bits_has_been_signal_updated (active_gen_table_io_s2_evict_bits_has_been_signal_updated),
    .io_act_threshold                         (io_act_threshold),
    .io_act_stride                            (io_act_stride)
  );

  StridePF stride (
    .clock                (clock),
    .reset                (reset),
    .io_s0_lookup_valid   (s0_valid),
    .io_s0_lookup_bits_pc (s0_pc[9:0]),
    .io_s1_valid          (active_gen_table_io_s1_sel_stride)
  );

  PatternHistoryTable pht (
    .clock                                      (clock),
    .reset                                      (reset),
    .io_agt_update_valid                        (active_gen_table_io_s2_evict_valid),
    .io_agt_update_bits_pht_index               (active_gen_table_io_s2_evict_bits_pht_index),
    .io_agt_update_bits_pht_tag                 (active_gen_table_io_s2_evict_bits_pht_tag),
    .io_agt_update_bits_region_bits             (active_gen_table_io_s2_evict_bits_region_bits),
    .io_agt_update_bits_region_bit_single       (active_gen_table_io_s2_evict_bits_region_bit_single),
    .io_agt_update_bits_region_offset           (active_gen_table_io_s2_evict_bits_region_offset),
    .io_agt_update_bits_access_cnt              (active_gen_table_io_s2_evict_bits_access_cnt),
    .io_agt_update_bits_decr_mode               (active_gen_table_io_s2_evict_bits_decr_mode),
    .io_agt_update_bits_single_update           (active_gen_table_io_s2_evict_bits_single_update),
    .io_agt_update_bits_has_been_signal_updated (active_gen_table_io_s2_evict_bits_has_been_signal_updated),
    .io_s2_agt_lookup_valid                     (active_gen_table_io_s2_pht_lookup_valid),
    .io_s2_agt_lookup_bits_pht_index            (active_gen_table_io_s2_pht_lookup_bits_pht_index),
    .io_s2_agt_lookup_bits_pht_tag              (active_gen_table_io_s2_pht_lookup_bits_pht_tag),
    .io_s2_agt_lookup_bits_region_paddr         (active_gen_table_io_s2_pht_lookup_bits_region_paddr),
    .io_s2_agt_lookup_bits_region_vaddr         (active_gen_table_io_s2_pht_lookup_bits_region_vaddr),
    .io_s2_agt_lookup_bits_region_offset        (active_gen_table_io_s2_pht_lookup_bits_region_offset),
    .io_pf_gen_req_valid                        (pht_io_pf_gen_req_valid),
    .io_pf_gen_req_bits_region_tag              (pht_io_pf_gen_req_bits_region_tag),
    .io_pf_gen_req_bits_region_addr             (pht_io_pf_gen_req_bits_region_addr),
    .io_pf_gen_req_bits_region_bits             (pht_io_pf_gen_req_bits_region_bits),
    .io_pf_gen_req_bits_paddr_valid             (pht_io_pf_gen_req_bits_paddr_valid),
    .io_pf_gen_req_bits_decr_mode               (pht_io_pf_gen_req_bits_decr_mode),
    .boreChildrenBd_bore_addr                   (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd                (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata                  (boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask                  (boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re                     (boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we                     (boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata                  (boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack                    (boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH             (boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array                  (boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold                 (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass               (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken             (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk              (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp             (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold             (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen                     (sigFromSrams_bore_cgen)
  );

  PrefetchFilter pf_filter (
    .clock                                  (clock),
    .reset                                  (reset),
    .io_gen_req_valid                       (filter_gen_valid),
    .io_gen_req_bits_region_tag             (pht_io_pf_gen_req_bits_region_tag),
    .io_gen_req_bits_region_addr            (pht_io_pf_gen_req_bits_region_addr),
    .io_gen_req_bits_region_bits            (pht_io_pf_gen_req_bits_region_bits),
    .io_gen_req_bits_paddr_valid            (pht_io_pf_gen_req_bits_paddr_valid),
    .io_gen_req_bits_decr_mode              (pht_io_pf_gen_req_bits_decr_mode),
    .io_tlb_req_req_valid                   (io_tlb_req_req_valid),
    .io_tlb_req_req_bits_vaddr              (io_tlb_req_req_bits_vaddr),
    .io_tlb_req_req_bits_fullva             (io_tlb_req_req_bits_fullva),
    .io_tlb_req_req_bits_checkfullva        (io_tlb_req_req_bits_checkfullva),
    .io_tlb_req_req_bits_cmd                (io_tlb_req_req_bits_cmd),
    .io_tlb_req_req_bits_hyperinst          (io_tlb_req_req_bits_hyperinst),
    .io_tlb_req_req_bits_hlvx               (io_tlb_req_req_bits_hlvx),
    .io_tlb_req_req_bits_kill               (io_tlb_req_req_bits_kill),
    .io_tlb_req_req_bits_isPrefetch         (io_tlb_req_req_bits_isPrefetch),
    .io_tlb_req_req_bits_no_translate       (io_tlb_req_req_bits_no_translate),
    .io_tlb_req_req_bits_pmp_addr           (io_tlb_req_req_bits_pmp_addr),
    .io_tlb_req_req_bits_frm_mabuf          (io_tlb_req_req_bits_frm_mabuf),
    .io_tlb_req_req_bits_debug_robIdx_flag  (io_tlb_req_req_bits_debug_robIdx_flag),
    .io_tlb_req_req_bits_debug_robIdx_value (io_tlb_req_req_bits_debug_robIdx_value),
    .io_tlb_req_req_bits_debug_isFirstIssue (io_tlb_req_req_bits_debug_isFirstIssue),
    .io_tlb_req_resp_valid                  (io_tlb_req_resp_valid),
    .io_tlb_req_resp_bits_paddr_0           (io_tlb_req_resp_bits_paddr_0),
    .io_tlb_req_resp_bits_pbmt_0            (io_tlb_req_resp_bits_pbmt_0),
    .io_tlb_req_resp_bits_miss              (io_tlb_req_resp_bits_miss),
    .io_tlb_req_resp_bits_excp_0_gpf_ld     (io_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_tlb_req_resp_bits_excp_0_pf_ld      (io_tlb_req_resp_bits_excp_0_pf_ld),
    .io_tlb_req_resp_bits_excp_0_af_ld      (io_tlb_req_resp_bits_excp_0_af_ld),
    .io_pmp_resp_ld                         (io_pmp_resp_ld),
    .io_pmp_resp_mmio                       (io_pmp_resp_mmio),
    .io_l2_pf_addr_valid                    (pf_filter_io_l2_pf_addr_valid),
    .io_l2_pf_addr_bits                     (pf_filter_io_l2_pf_addr_bits)
  );
  assign io_l2_req_bits_addr = pf_filter_io_l2_pf_addr_bits;

endmodule
// END GENERATED
