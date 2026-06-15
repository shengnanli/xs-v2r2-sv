// =============================================================================
// xs_ICache_core —— 香山 V2R2（昆明湖）ICache 顶层（指令缓存）
//
// 对应 Chisel: xiangshan.frontend.icache.ICacheImp（ICache.scala）
//
// 【它在前端的位置】
//   BPU 预测 → FTQ 给取指地址 → 本模块（ICache）把指令从 L1 取回交给 IFU。
//   ICache = 4 路组相联、双 bank、行宽 64B 的 L1 指令缓存。它本身**只是把若干功能单元
//   接到一起 + 做几处仲裁**，真正的流水/查表/refill 逻辑都在子模块里：
//
//                 ┌──────────────── ICache 顶层（本模块）────────────────┐
//      FTQ.prefetch ─▶│ IPrefetchPipe ─meta读─▶ MetaArray              │
//      SoftPrefetch ─▶│   (s0/s1/s2)   └─miss─▶ MissUnit(MSHR) ─acquire▶│─▶ L2/TileLink
//                     │       └─命中信息─▶ WayLookup(FIFO) ─┐           │
//      FTQ.fetch ────▶│ ICacheMainPipe ◀──命中信息──────────┘           │─▶ IFU.resp
//      (IFU 取指)     │   (s0/s1/s2) ─data读─▶ DataArray                │
//                     │       └─miss─▶ MissUnit ─refill─▶ Meta/DataArray│
//      CtrlUnit(TL) ─▶│ ICacheCtrlUnit ─inject写/读─▶ Meta/DataArray    │
//                     │ ICacheReplacer（PLRU 选 victim way）            │
//                     └─────────────────────────────────────────────────┘
//
// 【核心数据流：prefetch 与 mainpipe 经 WayLookup 解耦】
//   ICache 把「查 meta 定位在哪一路（way）」和「读 data 取指令」拆成两条流水：
//     · IPrefetchPipe 提前把每个取指块查表（ITLB 翻译 + 读 MetaArray 比 tag），算出
//       waymask/ptag/例外，写进 WayLookup（一个小 FIFO）；miss 的块顺手向 MissUnit 发预取。
//     · ICacheMainPipe 真正取指时从 WayLookup 读出这块的 waymask，直接拿 way 去读 DataArray，
//       不必自己再查一遍 meta。WayLookup 把两条流水**时间上解耦**：prefetch 跑在前面填 FIFO，
//       mainpipe 在后面消费，互不阻塞。
//   refill 回填（MissUnit 完成）时还会 io_update 就地修正 WayLookup 里在途条目的命中路。
//
// 【顶层真正承担的逻辑（本文件的可读性重点）——只有四块】
//   1. 软件预取仲裁（softPrefetch FSM）：3 个软件预取口 + FTQ 硬件预取口，仲裁后送一个
//      IPrefetchPipe。软件预取请求需锁存（prefetcher 没空时黏住），且让位于…见下。
//   2. 错误上报寄存器（io_error）：把 MainPipe 两个 port 的 ECC/总线错误打一拍上报给 BEU。
//   3. Meta/Data array 读写仲裁：CtrlUnit「注入」（诊断/可靠性测试写特定 way）优先级最高，
//      否则正常 refill 写 / prefetch 读。一个布尔 inject 选所有读写口的源。
//   4. 子模块互联 + MBIST/SRAM 物理 sideband 透传到 Meta/DataArray。
//
// 【可读性重写要点（相对 firtool golden）】
//   · 8 个子模块（MainPipe/Prefetch/MissUnit/WayLookup/Meta/DataArray/Replacer/CtrlUnit）
//     **维持 golden 同名直接例化**（它们已各自验证过），本文件只重写顶层互联与仲裁；
//   · 仲裁/路由用具名中间信号 + 注释讲「谁优先、为什么」，消除 _GEN_n 临时名；
//   · 软件预取 3 选 1 用优先级数组表达；
//   · MBIST/sigFromSrams 物理 sideband（占端口数 ~70%）是纯透传，单独分节、连续连接，
//     不污染功能逻辑阅读。
//
// 【端口说明】
//   为使 wrapper 成为零逻辑透传、并让 Formality 按签名对齐，本核的端口与 golden 完全同名
//   同序同宽（含 auto_*/sigFromSrams_*/boreChildrenBd_* 全部 sideband）。可读性体现在
//   **模块体**：分节、具名信号、结构化注释。
// =============================================================================

package xs_icache_pkg;
  // ---- 容量/位宽参数（KunminghuV2 ICache）----
  localparam int unsigned N_WAYS    = 4;   // 4 路组相联 → waymask 宽 4
  localparam int unsigned N_BANKS   = 2;   // 双 bank（一次取指最多跨 2 条 cacheline）
  localparam int unsigned IDX_W     = 8;   // vSetIdx 宽（256 组）
  localparam int unsigned TAG_W     = 36;  // 物理 tag 宽 = paddr[47:12]
  localparam int unsigned VADDR_W   = 50;  // VAddrBits
  localparam int unsigned PADDR_W   = 48;  // PAddrBits
  localparam int unsigned BLK_PA_W  = 42;  // blkPaddr 宽 = paddr[47:6]
  localparam int unsigned N_SOFTPF  = 3;   // 软件预取口数（io_softPrefetch_0/1/2）
endpackage

module xs_ICache_core
  import xs_icache_pkg::*;
(
  input          clock,
  input          reset,
  // ---- CtrlUnit TileLink（诊断/ECC 注入控制口）----
  output         auto_ctrlUnitOpt_in_a_ready,
  input          auto_ctrlUnitOpt_in_a_valid,
  input  [3:0]   auto_ctrlUnitOpt_in_a_bits_opcode,
  input  [1:0]   auto_ctrlUnitOpt_in_a_bits_size,
  input  [2:0]   auto_ctrlUnitOpt_in_a_bits_source,
  input  [29:0]  auto_ctrlUnitOpt_in_a_bits_address,
  input  [7:0]   auto_ctrlUnitOpt_in_a_bits_mask,
  input  [63:0]  auto_ctrlUnitOpt_in_a_bits_data,
  input          auto_ctrlUnitOpt_in_d_ready,
  output         auto_ctrlUnitOpt_in_d_valid,
  output [3:0]   auto_ctrlUnitOpt_in_d_bits_opcode,
  output [1:0]   auto_ctrlUnitOpt_in_d_bits_size,
  output [2:0]   auto_ctrlUnitOpt_in_d_bits_source,
  output [63:0]  auto_ctrlUnitOpt_in_d_bits_data,
  // ---- MissUnit 的 L2/TileLink client 口（acquire/grant）----
  input          auto_client_out_a_ready,
  output         auto_client_out_a_valid,
  output [3:0]   auto_client_out_a_bits_source,
  output [47:0]  auto_client_out_a_bits_address,
  input          auto_client_out_d_valid,
  input  [3:0]   auto_client_out_d_bits_opcode,
  input  [2:0]   auto_client_out_d_bits_size,
  input  [3:0]   auto_client_out_d_bits_source,
  input  [255:0] auto_client_out_d_bits_data,
  input          auto_client_out_d_bits_corrupt,
  // ---- IFU 取指请求/响应（MainPipe）----
  output         io_fetch_req_ready,
  input          io_fetch_req_valid,
  input  [49:0]  io_fetch_req_bits_pcMemRead_0_startAddr,
  input  [49:0]  io_fetch_req_bits_pcMemRead_0_nextlineStart,
  input  [49:0]  io_fetch_req_bits_pcMemRead_1_startAddr,
  input  [49:0]  io_fetch_req_bits_pcMemRead_1_nextlineStart,
  input  [49:0]  io_fetch_req_bits_pcMemRead_2_startAddr,
  input  [49:0]  io_fetch_req_bits_pcMemRead_2_nextlineStart,
  input  [49:0]  io_fetch_req_bits_pcMemRead_3_startAddr,
  input  [49:0]  io_fetch_req_bits_pcMemRead_3_nextlineStart,
  input  [49:0]  io_fetch_req_bits_pcMemRead_4_startAddr,
  input  [49:0]  io_fetch_req_bits_pcMemRead_4_nextlineStart,
  input          io_fetch_req_bits_readValid_0,
  input          io_fetch_req_bits_readValid_1,
  input          io_fetch_req_bits_readValid_2,
  input          io_fetch_req_bits_readValid_3,
  input          io_fetch_req_bits_readValid_4,
  input          io_fetch_req_bits_backendException,
  output         io_fetch_resp_valid,
  output         io_fetch_resp_bits_doubleline,
  output [49:0]  io_fetch_resp_bits_vaddr_0,
  output [49:0]  io_fetch_resp_bits_vaddr_1,
  output [511:0] io_fetch_resp_bits_data,
  output [47:0]  io_fetch_resp_bits_paddr_0,
  output [1:0]   io_fetch_resp_bits_exception_0,
  output [1:0]   io_fetch_resp_bits_exception_1,
  output         io_fetch_resp_bits_pmp_mmio_0,
  output         io_fetch_resp_bits_pmp_mmio_1,
  output [1:0]   io_fetch_resp_bits_itlb_pbmt_0,
  output [1:0]   io_fetch_resp_bits_itlb_pbmt_1,
  output         io_fetch_resp_bits_backendException,
  output [55:0]  io_fetch_resp_bits_gpaddr,
  output         io_fetch_resp_bits_isForVSnonLeafPTE,
  output         io_fetch_topdownIcacheMiss,
  output         io_fetch_topdownItlbMiss,
  // ---- FTQ 硬件预取请求口（Prefetch）----
  output         io_ftqPrefetch_req_ready,
  input          io_ftqPrefetch_req_valid,
  input  [49:0]  io_ftqPrefetch_req_bits_startAddr,
  input  [49:0]  io_ftqPrefetch_req_bits_nextlineStart,
  input          io_ftqPrefetch_req_bits_ftqIdx_flag,
  input  [5:0]   io_ftqPrefetch_req_bits_ftqIdx_value,
  input          io_ftqPrefetch_flushFromBpu_s2_valid,
  input          io_ftqPrefetch_flushFromBpu_s2_bits_flag,
  input  [5:0]   io_ftqPrefetch_flushFromBpu_s2_bits_value,
  input          io_ftqPrefetch_flushFromBpu_s3_valid,
  input          io_ftqPrefetch_flushFromBpu_s3_bits_flag,
  input  [5:0]   io_ftqPrefetch_flushFromBpu_s3_bits_value,
  input  [1:0]   io_ftqPrefetch_backendException,
  // ---- 软件预取口（prefetch.i 指令；3 个并行口）----
  input          io_softPrefetch_0_valid,
  input  [49:0]  io_softPrefetch_0_bits_vaddr,
  input          io_softPrefetch_1_valid,
  input  [49:0]  io_softPrefetch_1_bits_vaddr,
  input          io_softPrefetch_2_valid,
  input  [49:0]  io_softPrefetch_2_bits_vaddr,
  input          io_stop,
  output         io_toIFU,
  // ---- PMP 检查口：pmp_0/1 给 MainPipe，pmp_2/3 给 Prefetch ----
  output [47:0]  io_pmp_0_req_bits_addr,
  input          io_pmp_0_resp_instr,
  input          io_pmp_0_resp_mmio,
  output [47:0]  io_pmp_1_req_bits_addr,
  input          io_pmp_1_resp_instr,
  input          io_pmp_1_resp_mmio,
  output [47:0]  io_pmp_2_req_bits_addr,
  input          io_pmp_2_resp_instr,
  input          io_pmp_2_resp_mmio,
  output [47:0]  io_pmp_3_req_bits_addr,
  input          io_pmp_3_resp_instr,
  input          io_pmp_3_resp_mmio,
  // ---- ITLB 翻译口（2 个，给 Prefetch 的两条 cacheline）----
  output         io_itlb_0_req_valid,
  output [49:0]  io_itlb_0_req_bits_vaddr,
  input  [47:0]  io_itlb_0_resp_bits_paddr_0,
  input  [63:0]  io_itlb_0_resp_bits_gpaddr_0,
  input  [1:0]   io_itlb_0_resp_bits_pbmt_0,
  input          io_itlb_0_resp_bits_miss,
  input          io_itlb_0_resp_bits_isForVSnonLeafPTE,
  input          io_itlb_0_resp_bits_excp_0_gpf_instr,
  input          io_itlb_0_resp_bits_excp_0_pf_instr,
  input          io_itlb_0_resp_bits_excp_0_af_instr,
  output         io_itlb_1_req_valid,
  output [49:0]  io_itlb_1_req_bits_vaddr,
  input  [47:0]  io_itlb_1_resp_bits_paddr_0,
  input  [63:0]  io_itlb_1_resp_bits_gpaddr_0,
  input  [1:0]   io_itlb_1_resp_bits_pbmt_0,
  input          io_itlb_1_resp_bits_miss,
  input          io_itlb_1_resp_bits_isForVSnonLeafPTE,
  input          io_itlb_1_resp_bits_excp_0_gpf_instr,
  input          io_itlb_1_resp_bits_excp_0_pf_instr,
  input          io_itlb_1_resp_bits_excp_0_af_instr,
  output         io_itlbFlushPipe,
  // ---- 错误上报给 BEU ----
  output         io_error_valid,
  output [47:0]  io_error_bits_paddr,
  output         io_error_bits_report_to_beu,
  // ---- 杂项控制 ----
  input          io_csr_pf_enable,
  input          io_fencei,
  input          io_flush,
  input          io_wfi_wfiReq,
  output         io_wfi_wfiSafe,
  // ---- 性能计数 ----
  output         io_perfInfo_only_0_hit,
  output         io_perfInfo_only_0_miss,
  output         io_perfInfo_hit_0_hit_1,
  output         io_perfInfo_hit_0_miss_1,
  output         io_perfInfo_miss_0_hit_1,
  output         io_perfInfo_miss_0_miss_1,
  output         io_perfInfo_hit_0_except_1,
  output         io_perfInfo_miss_0_except_1,
  output         io_perfInfo_except_0,
  output         io_perfInfo_bank_hit_0,
  output         io_perfInfo_bank_hit_1,
  output         io_perfInfo_hit,
  // ===========================================================================
  // 以下 boreChildrenBd_*（MBIST 串）与 sigFromSrams_*（SRAM 物理控制）均为
  // **纯透传 sideband**：本顶层不产生也不消费，只把它们路由到 Meta/DataArray 内的
  // SRAM 宏。功能阅读可整体跳过本区。映射关系见文件末尾「SRAM/MBIST sideband 透传」节。
  //   · boreChildrenBd_bore     → MetaArray 的 1 个 MBIST 串
  //   · boreChildrenBd_bore_1..4→ DataArray 的 4 个 MBIST 串（4 路 data way 各 1）
  //   · sigFromSrams_bore_0..3   → MetaArray 的 4 个 SRAM 物理控制
  //   · sigFromSrams_bore_4..35  → DataArray 的 32 个 SRAM 物理控制
  // ===========================================================================
  input  [1:0]   boreChildrenBd_bore_array,
  input          boreChildrenBd_bore_all,
  input          boreChildrenBd_bore_req,
  output         boreChildrenBd_bore_ack,
  input          boreChildrenBd_bore_writeen,
  input  [1:0]   boreChildrenBd_bore_be,
  input  [7:0]   boreChildrenBd_bore_addr,
  input  [73:0]  boreChildrenBd_bore_indata,
  input          boreChildrenBd_bore_readen,
  input  [7:0]   boreChildrenBd_bore_addr_rd,
  output [73:0]  boreChildrenBd_bore_outdata,
  input  [3:0]   boreChildrenBd_bore_1_array,
  input          boreChildrenBd_bore_1_all,
  input          boreChildrenBd_bore_1_req,
  output         boreChildrenBd_bore_1_ack,
  input          boreChildrenBd_bore_1_writeen,
  input          boreChildrenBd_bore_1_be,
  input  [8:0]   boreChildrenBd_bore_1_addr,
  input  [65:0]  boreChildrenBd_bore_1_indata,
  input          boreChildrenBd_bore_1_readen,
  input  [8:0]   boreChildrenBd_bore_1_addr_rd,
  output [65:0]  boreChildrenBd_bore_1_outdata,
  input  [4:0]   boreChildrenBd_bore_2_array,
  input          boreChildrenBd_bore_2_all,
  input          boreChildrenBd_bore_2_req,
  output         boreChildrenBd_bore_2_ack,
  input          boreChildrenBd_bore_2_writeen,
  input          boreChildrenBd_bore_2_be,
  input  [8:0]   boreChildrenBd_bore_2_addr,
  input  [65:0]  boreChildrenBd_bore_2_indata,
  input          boreChildrenBd_bore_2_readen,
  input  [8:0]   boreChildrenBd_bore_2_addr_rd,
  output [65:0]  boreChildrenBd_bore_2_outdata,
  input  [4:0]   boreChildrenBd_bore_3_array,
  input          boreChildrenBd_bore_3_all,
  input          boreChildrenBd_bore_3_req,
  output         boreChildrenBd_bore_3_ack,
  input          boreChildrenBd_bore_3_writeen,
  input          boreChildrenBd_bore_3_be,
  input  [8:0]   boreChildrenBd_bore_3_addr,
  input  [65:0]  boreChildrenBd_bore_3_indata,
  input          boreChildrenBd_bore_3_readen,
  input  [8:0]   boreChildrenBd_bore_3_addr_rd,
  output [65:0]  boreChildrenBd_bore_3_outdata,
  input  [5:0]   boreChildrenBd_bore_4_array,
  input          boreChildrenBd_bore_4_all,
  input          boreChildrenBd_bore_4_req,
  output         boreChildrenBd_bore_4_ack,
  input          boreChildrenBd_bore_4_writeen,
  input          boreChildrenBd_bore_4_be,
  input  [8:0]   boreChildrenBd_bore_4_addr,
  input  [65:0]  boreChildrenBd_bore_4_indata,
  input          boreChildrenBd_bore_4_readen,
  input  [8:0]   boreChildrenBd_bore_4_addr_rd,
  output [65:0]  boreChildrenBd_bore_4_outdata,
  // sigFromSrams_bore_0..35（每串 7 信号）：0..3=MetaArray，4..35=DataArray
  input          sigFromSrams_bore_ram_hold,
  input          sigFromSrams_bore_ram_bypass,
  input          sigFromSrams_bore_ram_bp_clken,
  input          sigFromSrams_bore_ram_aux_clk,
  input          sigFromSrams_bore_ram_aux_ckbp,
  input          sigFromSrams_bore_ram_mcp_hold,
  input          sigFromSrams_bore_cgen,
  input          sigFromSrams_bore_1_ram_hold,
  input          sigFromSrams_bore_1_ram_bypass,
  input          sigFromSrams_bore_1_ram_bp_clken,
  input          sigFromSrams_bore_1_ram_aux_clk,
  input          sigFromSrams_bore_1_ram_aux_ckbp,
  input          sigFromSrams_bore_1_ram_mcp_hold,
  input          sigFromSrams_bore_1_cgen,
  input          sigFromSrams_bore_2_ram_hold,
  input          sigFromSrams_bore_2_ram_bypass,
  input          sigFromSrams_bore_2_ram_bp_clken,
  input          sigFromSrams_bore_2_ram_aux_clk,
  input          sigFromSrams_bore_2_ram_aux_ckbp,
  input          sigFromSrams_bore_2_ram_mcp_hold,
  input          sigFromSrams_bore_2_cgen,
  input          sigFromSrams_bore_3_ram_hold,
  input          sigFromSrams_bore_3_ram_bypass,
  input          sigFromSrams_bore_3_ram_bp_clken,
  input          sigFromSrams_bore_3_ram_aux_clk,
  input          sigFromSrams_bore_3_ram_aux_ckbp,
  input          sigFromSrams_bore_3_ram_mcp_hold,
  input          sigFromSrams_bore_3_cgen,
  input          sigFromSrams_bore_4_ram_hold,
  input          sigFromSrams_bore_4_ram_bypass,
  input          sigFromSrams_bore_4_ram_bp_clken,
  input          sigFromSrams_bore_4_ram_aux_clk,
  input          sigFromSrams_bore_4_ram_aux_ckbp,
  input          sigFromSrams_bore_4_ram_mcp_hold,
  input          sigFromSrams_bore_4_cgen,
  input          sigFromSrams_bore_5_ram_hold,
  input          sigFromSrams_bore_5_ram_bypass,
  input          sigFromSrams_bore_5_ram_bp_clken,
  input          sigFromSrams_bore_5_ram_aux_clk,
  input          sigFromSrams_bore_5_ram_aux_ckbp,
  input          sigFromSrams_bore_5_ram_mcp_hold,
  input          sigFromSrams_bore_5_cgen,
  input          sigFromSrams_bore_6_ram_hold,
  input          sigFromSrams_bore_6_ram_bypass,
  input          sigFromSrams_bore_6_ram_bp_clken,
  input          sigFromSrams_bore_6_ram_aux_clk,
  input          sigFromSrams_bore_6_ram_aux_ckbp,
  input          sigFromSrams_bore_6_ram_mcp_hold,
  input          sigFromSrams_bore_6_cgen,
  input          sigFromSrams_bore_7_ram_hold,
  input          sigFromSrams_bore_7_ram_bypass,
  input          sigFromSrams_bore_7_ram_bp_clken,
  input          sigFromSrams_bore_7_ram_aux_clk,
  input          sigFromSrams_bore_7_ram_aux_ckbp,
  input          sigFromSrams_bore_7_ram_mcp_hold,
  input          sigFromSrams_bore_7_cgen,
  input          sigFromSrams_bore_8_ram_hold,
  input          sigFromSrams_bore_8_ram_bypass,
  input          sigFromSrams_bore_8_ram_bp_clken,
  input          sigFromSrams_bore_8_ram_aux_clk,
  input          sigFromSrams_bore_8_ram_aux_ckbp,
  input          sigFromSrams_bore_8_ram_mcp_hold,
  input          sigFromSrams_bore_8_cgen,
  input          sigFromSrams_bore_9_ram_hold,
  input          sigFromSrams_bore_9_ram_bypass,
  input          sigFromSrams_bore_9_ram_bp_clken,
  input          sigFromSrams_bore_9_ram_aux_clk,
  input          sigFromSrams_bore_9_ram_aux_ckbp,
  input          sigFromSrams_bore_9_ram_mcp_hold,
  input          sigFromSrams_bore_9_cgen,
  input          sigFromSrams_bore_10_ram_hold,
  input          sigFromSrams_bore_10_ram_bypass,
  input          sigFromSrams_bore_10_ram_bp_clken,
  input          sigFromSrams_bore_10_ram_aux_clk,
  input          sigFromSrams_bore_10_ram_aux_ckbp,
  input          sigFromSrams_bore_10_ram_mcp_hold,
  input          sigFromSrams_bore_10_cgen,
  input          sigFromSrams_bore_11_ram_hold,
  input          sigFromSrams_bore_11_ram_bypass,
  input          sigFromSrams_bore_11_ram_bp_clken,
  input          sigFromSrams_bore_11_ram_aux_clk,
  input          sigFromSrams_bore_11_ram_aux_ckbp,
  input          sigFromSrams_bore_11_ram_mcp_hold,
  input          sigFromSrams_bore_11_cgen,
  input          sigFromSrams_bore_12_ram_hold,
  input          sigFromSrams_bore_12_ram_bypass,
  input          sigFromSrams_bore_12_ram_bp_clken,
  input          sigFromSrams_bore_12_ram_aux_clk,
  input          sigFromSrams_bore_12_ram_aux_ckbp,
  input          sigFromSrams_bore_12_ram_mcp_hold,
  input          sigFromSrams_bore_12_cgen,
  input          sigFromSrams_bore_13_ram_hold,
  input          sigFromSrams_bore_13_ram_bypass,
  input          sigFromSrams_bore_13_ram_bp_clken,
  input          sigFromSrams_bore_13_ram_aux_clk,
  input          sigFromSrams_bore_13_ram_aux_ckbp,
  input          sigFromSrams_bore_13_ram_mcp_hold,
  input          sigFromSrams_bore_13_cgen,
  input          sigFromSrams_bore_14_ram_hold,
  input          sigFromSrams_bore_14_ram_bypass,
  input          sigFromSrams_bore_14_ram_bp_clken,
  input          sigFromSrams_bore_14_ram_aux_clk,
  input          sigFromSrams_bore_14_ram_aux_ckbp,
  input          sigFromSrams_bore_14_ram_mcp_hold,
  input          sigFromSrams_bore_14_cgen,
  input          sigFromSrams_bore_15_ram_hold,
  input          sigFromSrams_bore_15_ram_bypass,
  input          sigFromSrams_bore_15_ram_bp_clken,
  input          sigFromSrams_bore_15_ram_aux_clk,
  input          sigFromSrams_bore_15_ram_aux_ckbp,
  input          sigFromSrams_bore_15_ram_mcp_hold,
  input          sigFromSrams_bore_15_cgen,
  input          sigFromSrams_bore_16_ram_hold,
  input          sigFromSrams_bore_16_ram_bypass,
  input          sigFromSrams_bore_16_ram_bp_clken,
  input          sigFromSrams_bore_16_ram_aux_clk,
  input          sigFromSrams_bore_16_ram_aux_ckbp,
  input          sigFromSrams_bore_16_ram_mcp_hold,
  input          sigFromSrams_bore_16_cgen,
  input          sigFromSrams_bore_17_ram_hold,
  input          sigFromSrams_bore_17_ram_bypass,
  input          sigFromSrams_bore_17_ram_bp_clken,
  input          sigFromSrams_bore_17_ram_aux_clk,
  input          sigFromSrams_bore_17_ram_aux_ckbp,
  input          sigFromSrams_bore_17_ram_mcp_hold,
  input          sigFromSrams_bore_17_cgen,
  input          sigFromSrams_bore_18_ram_hold,
  input          sigFromSrams_bore_18_ram_bypass,
  input          sigFromSrams_bore_18_ram_bp_clken,
  input          sigFromSrams_bore_18_ram_aux_clk,
  input          sigFromSrams_bore_18_ram_aux_ckbp,
  input          sigFromSrams_bore_18_ram_mcp_hold,
  input          sigFromSrams_bore_18_cgen,
  input          sigFromSrams_bore_19_ram_hold,
  input          sigFromSrams_bore_19_ram_bypass,
  input          sigFromSrams_bore_19_ram_bp_clken,
  input          sigFromSrams_bore_19_ram_aux_clk,
  input          sigFromSrams_bore_19_ram_aux_ckbp,
  input          sigFromSrams_bore_19_ram_mcp_hold,
  input          sigFromSrams_bore_19_cgen,
  input          sigFromSrams_bore_20_ram_hold,
  input          sigFromSrams_bore_20_ram_bypass,
  input          sigFromSrams_bore_20_ram_bp_clken,
  input          sigFromSrams_bore_20_ram_aux_clk,
  input          sigFromSrams_bore_20_ram_aux_ckbp,
  input          sigFromSrams_bore_20_ram_mcp_hold,
  input          sigFromSrams_bore_20_cgen,
  input          sigFromSrams_bore_21_ram_hold,
  input          sigFromSrams_bore_21_ram_bypass,
  input          sigFromSrams_bore_21_ram_bp_clken,
  input          sigFromSrams_bore_21_ram_aux_clk,
  input          sigFromSrams_bore_21_ram_aux_ckbp,
  input          sigFromSrams_bore_21_ram_mcp_hold,
  input          sigFromSrams_bore_21_cgen,
  input          sigFromSrams_bore_22_ram_hold,
  input          sigFromSrams_bore_22_ram_bypass,
  input          sigFromSrams_bore_22_ram_bp_clken,
  input          sigFromSrams_bore_22_ram_aux_clk,
  input          sigFromSrams_bore_22_ram_aux_ckbp,
  input          sigFromSrams_bore_22_ram_mcp_hold,
  input          sigFromSrams_bore_22_cgen,
  input          sigFromSrams_bore_23_ram_hold,
  input          sigFromSrams_bore_23_ram_bypass,
  input          sigFromSrams_bore_23_ram_bp_clken,
  input          sigFromSrams_bore_23_ram_aux_clk,
  input          sigFromSrams_bore_23_ram_aux_ckbp,
  input          sigFromSrams_bore_23_ram_mcp_hold,
  input          sigFromSrams_bore_23_cgen,
  input          sigFromSrams_bore_24_ram_hold,
  input          sigFromSrams_bore_24_ram_bypass,
  input          sigFromSrams_bore_24_ram_bp_clken,
  input          sigFromSrams_bore_24_ram_aux_clk,
  input          sigFromSrams_bore_24_ram_aux_ckbp,
  input          sigFromSrams_bore_24_ram_mcp_hold,
  input          sigFromSrams_bore_24_cgen,
  input          sigFromSrams_bore_25_ram_hold,
  input          sigFromSrams_bore_25_ram_bypass,
  input          sigFromSrams_bore_25_ram_bp_clken,
  input          sigFromSrams_bore_25_ram_aux_clk,
  input          sigFromSrams_bore_25_ram_aux_ckbp,
  input          sigFromSrams_bore_25_ram_mcp_hold,
  input          sigFromSrams_bore_25_cgen,
  input          sigFromSrams_bore_26_ram_hold,
  input          sigFromSrams_bore_26_ram_bypass,
  input          sigFromSrams_bore_26_ram_bp_clken,
  input          sigFromSrams_bore_26_ram_aux_clk,
  input          sigFromSrams_bore_26_ram_aux_ckbp,
  input          sigFromSrams_bore_26_ram_mcp_hold,
  input          sigFromSrams_bore_26_cgen,
  input          sigFromSrams_bore_27_ram_hold,
  input          sigFromSrams_bore_27_ram_bypass,
  input          sigFromSrams_bore_27_ram_bp_clken,
  input          sigFromSrams_bore_27_ram_aux_clk,
  input          sigFromSrams_bore_27_ram_aux_ckbp,
  input          sigFromSrams_bore_27_ram_mcp_hold,
  input          sigFromSrams_bore_27_cgen,
  input          sigFromSrams_bore_28_ram_hold,
  input          sigFromSrams_bore_28_ram_bypass,
  input          sigFromSrams_bore_28_ram_bp_clken,
  input          sigFromSrams_bore_28_ram_aux_clk,
  input          sigFromSrams_bore_28_ram_aux_ckbp,
  input          sigFromSrams_bore_28_ram_mcp_hold,
  input          sigFromSrams_bore_28_cgen,
  input          sigFromSrams_bore_29_ram_hold,
  input          sigFromSrams_bore_29_ram_bypass,
  input          sigFromSrams_bore_29_ram_bp_clken,
  input          sigFromSrams_bore_29_ram_aux_clk,
  input          sigFromSrams_bore_29_ram_aux_ckbp,
  input          sigFromSrams_bore_29_ram_mcp_hold,
  input          sigFromSrams_bore_29_cgen,
  input          sigFromSrams_bore_30_ram_hold,
  input          sigFromSrams_bore_30_ram_bypass,
  input          sigFromSrams_bore_30_ram_bp_clken,
  input          sigFromSrams_bore_30_ram_aux_clk,
  input          sigFromSrams_bore_30_ram_aux_ckbp,
  input          sigFromSrams_bore_30_ram_mcp_hold,
  input          sigFromSrams_bore_30_cgen,
  input          sigFromSrams_bore_31_ram_hold,
  input          sigFromSrams_bore_31_ram_bypass,
  input          sigFromSrams_bore_31_ram_bp_clken,
  input          sigFromSrams_bore_31_ram_aux_clk,
  input          sigFromSrams_bore_31_ram_aux_ckbp,
  input          sigFromSrams_bore_31_ram_mcp_hold,
  input          sigFromSrams_bore_31_cgen,
  input          sigFromSrams_bore_32_ram_hold,
  input          sigFromSrams_bore_32_ram_bypass,
  input          sigFromSrams_bore_32_ram_bp_clken,
  input          sigFromSrams_bore_32_ram_aux_clk,
  input          sigFromSrams_bore_32_ram_aux_ckbp,
  input          sigFromSrams_bore_32_ram_mcp_hold,
  input          sigFromSrams_bore_32_cgen,
  input          sigFromSrams_bore_33_ram_hold,
  input          sigFromSrams_bore_33_ram_bypass,
  input          sigFromSrams_bore_33_ram_bp_clken,
  input          sigFromSrams_bore_33_ram_aux_clk,
  input          sigFromSrams_bore_33_ram_aux_ckbp,
  input          sigFromSrams_bore_33_ram_mcp_hold,
  input          sigFromSrams_bore_33_cgen,
  input          sigFromSrams_bore_34_ram_hold,
  input          sigFromSrams_bore_34_ram_bypass,
  input          sigFromSrams_bore_34_ram_bp_clken,
  input          sigFromSrams_bore_34_ram_aux_clk,
  input          sigFromSrams_bore_34_ram_aux_ckbp,
  input          sigFromSrams_bore_34_ram_mcp_hold,
  input          sigFromSrams_bore_34_cgen,
  input          sigFromSrams_bore_35_ram_hold,
  input          sigFromSrams_bore_35_ram_bypass,
  input          sigFromSrams_bore_35_ram_bp_clken,
  input          sigFromSrams_bore_35_ram_aux_clk,
  input          sigFromSrams_bore_35_ram_aux_ckbp,
  input          sigFromSrams_bore_35_ram_mcp_hold,
  input          sigFromSrams_bore_35_cgen
);

  // ===========================================================================
  // 子模块输出线网（按子模块分组命名，沿用 golden 信号名便于交叉对照）
  // ===========================================================================
  // ---- WayLookup（命中信息 FIFO）----
  wire        wl_read_valid;
  wire [7:0]  wl_read_vSetIdx_0,  wl_read_vSetIdx_1;
  wire [3:0]  wl_read_waymask_0,  wl_read_waymask_1;
  wire [35:0] wl_read_ptag_0,     wl_read_ptag_1;
  wire [1:0]  wl_read_itlb_exception_0, wl_read_itlb_exception_1;
  wire [1:0]  wl_read_itlb_pbmt_0,      wl_read_itlb_pbmt_1;
  wire        wl_read_meta_codes_0,     wl_read_meta_codes_1;
  wire [55:0] wl_read_gpf_gpaddr;
  wire        wl_read_gpf_isForVSnonLeafPTE;
  wire        wl_write_ready;

  // ---- IPrefetchPipe ----
  wire        pf_req_ready;
  wire        pf_metaRead_valid;
  wire [7:0]  pf_metaRead_vSetIdx_0, pf_metaRead_vSetIdx_1;
  wire        pf_metaRead_isDoubleLine;
  wire        pf_mshr_valid;
  wire [41:0] pf_mshr_blkPaddr;
  wire [7:0]  pf_mshr_vSetIdx;
  wire        pf_wlw_valid;
  wire [7:0]  pf_wlw_vSetIdx_0, pf_wlw_vSetIdx_1;
  wire [3:0]  pf_wlw_waymask_0, pf_wlw_waymask_1;
  wire [35:0] pf_wlw_ptag_0,    pf_wlw_ptag_1;
  wire [1:0]  pf_wlw_itlb_exception_0, pf_wlw_itlb_exception_1;
  wire [1:0]  pf_wlw_itlb_pbmt_0,      pf_wlw_itlb_pbmt_1;
  wire        pf_wlw_meta_codes_0,     pf_wlw_meta_codes_1;
  wire [55:0] pf_wlw_gpf_gpaddr;
  wire        pf_wlw_gpf_isForVSnonLeafPTE;

  // ---- ICacheReplacer（PLRU 选 victim way）----
  wire [1:0]  rpl_victim_way;

  // ---- ICacheMissUnit（MSHR / refill）----
  wire        mu_fetch_req_ready;
  wire        mu_fetch_resp_valid;
  wire [41:0] mu_fetch_resp_blkPaddr;
  wire [7:0]  mu_fetch_resp_vSetIdx;
  wire [3:0]  mu_fetch_resp_waymask;
  wire [511:0] mu_fetch_resp_data;
  wire        mu_fetch_resp_corrupt;
  wire        mu_prefetch_req_ready;
  wire        mu_meta_write_valid;
  wire [7:0]  mu_meta_write_virIdx;
  wire [35:0] mu_meta_write_phyTag;
  wire [3:0]  mu_meta_write_waymask;
  wire        mu_meta_write_bankIdx;
  wire        mu_data_write_valid;
  wire [7:0]  mu_data_write_virIdx;
  wire [511:0] mu_data_write_data;
  wire [3:0]  mu_data_write_waymask;
  wire        mu_victim_valid;
  wire [7:0]  mu_victim_vSetIdx;

  // ---- ICacheMainPipe ----
  wire        mp_iData_0_valid;
  wire [7:0]  mp_iData_0_vSetIdx_0, mp_iData_0_vSetIdx_1;
  wire        mp_iData_0_waymask_0_0, mp_iData_0_waymask_0_1, mp_iData_0_waymask_0_2, mp_iData_0_waymask_0_3;
  wire        mp_iData_0_waymask_1_0, mp_iData_0_waymask_1_1, mp_iData_0_waymask_1_2, mp_iData_0_waymask_1_3;
  wire [5:0]  mp_iData_0_blkOffset;
  wire        mp_iData_1_valid;
  wire [7:0]  mp_iData_1_vSetIdx_0, mp_iData_1_vSetIdx_1;
  wire        mp_iData_2_valid;
  wire [7:0]  mp_iData_2_vSetIdx_0, mp_iData_2_vSetIdx_1;
  wire        mp_iData_3_valid;
  wire [7:0]  mp_iData_3_vSetIdx_0, mp_iData_3_vSetIdx_1;
  wire        mp_metaFlush_0_valid, mp_metaFlush_1_valid;
  wire [7:0]  mp_metaFlush_0_virIdx, mp_metaFlush_1_virIdx;
  wire [3:0]  mp_metaFlush_0_waymask, mp_metaFlush_1_waymask;
  wire        mp_touch_0_valid, mp_touch_1_valid;
  wire [7:0]  mp_touch_0_vSetIdx, mp_touch_1_vSetIdx;
  wire [1:0]  mp_touch_0_way, mp_touch_1_way;
  wire        mp_wayLookupRead_ready;
  wire        mp_mshr_req_valid;
  wire [41:0] mp_mshr_req_blkPaddr;
  wire [7:0]  mp_mshr_req_vSetIdx;
  wire        mp_fetch_req_ready;
  wire        mp_errors_0_valid, mp_errors_1_valid;
  wire [47:0] mp_errors_0_paddr,  mp_errors_1_paddr;
  wire        mp_errors_0_report_to_beu, mp_errors_1_report_to_beu;

  // ---- ICacheDataArray ----
  wire        da_read_3_ready;
  wire [63:0] da_resp_datas_0, da_resp_datas_1, da_resp_datas_2, da_resp_datas_3;
  wire [63:0] da_resp_datas_4, da_resp_datas_5, da_resp_datas_6, da_resp_datas_7;
  wire        da_resp_codes_0, da_resp_codes_1, da_resp_codes_2, da_resp_codes_3;
  wire        da_resp_codes_4, da_resp_codes_5, da_resp_codes_6, da_resp_codes_7;

  // ---- ICacheMetaArray ----
  wire        ma_read_ready;
  wire [35:0] ma_resp_metas_0_0_tag, ma_resp_metas_0_1_tag, ma_resp_metas_0_2_tag, ma_resp_metas_0_3_tag;
  wire [35:0] ma_resp_metas_1_0_tag, ma_resp_metas_1_1_tag, ma_resp_metas_1_2_tag, ma_resp_metas_1_3_tag;
  wire        ma_resp_codes_0_0, ma_resp_codes_0_1, ma_resp_codes_0_2, ma_resp_codes_0_3;
  wire        ma_resp_codes_1_0, ma_resp_codes_1_1, ma_resp_codes_1_2, ma_resp_codes_1_3;
  wire        ma_resp_entryValid_0_0, ma_resp_entryValid_0_1, ma_resp_entryValid_0_2, ma_resp_entryValid_0_3;
  wire        ma_resp_entryValid_1_0, ma_resp_entryValid_1_1, ma_resp_entryValid_1_2, ma_resp_entryValid_1_3;

  // ---- ICacheCtrlUnit（诊断注入控制）----
  wire        cu_ecc_enable;
  wire        cu_injecting;     // 关键仲裁信号：CtrlUnit 正在注入 → 抢占 meta/data 读写口
  wire        cu_metaRead_valid;
  wire [7:0]  cu_metaRead_vSetIdx_0, cu_metaRead_vSetIdx_1;
  wire        cu_metaWrite_valid;
  wire [7:0]  cu_metaWrite_virIdx;
  wire [35:0] cu_metaWrite_phyTag;
  wire [3:0]  cu_metaWrite_waymask;
  wire        cu_metaWrite_bankIdx;
  wire        cu_dataWrite_valid;
  wire [7:0]  cu_dataWrite_virIdx;
  wire [3:0]  cu_dataWrite_waymask;

  // ===========================================================================
  // 【逻辑 1】软件预取仲裁（softPrefetch FSM）
  //   - 软件预取（prefetch.i 指令，3 个并行口 io_softPrefetch_0/1/2）需要锁存：
  //     prefetcher 当拍未必空闲，所以把软预取请求黏在寄存器里直到被 prefetcher 接收。
  //   - 优先级：软件预取一旦锁存（softPrefetchValid=1），就**抢占** prefetcher 的 req 口，
  //     FTQ 硬件预取此时让位（io_ftqPrefetch_req_ready = pf_req_ready & ~softPrefetchValid）。
  //   - 3 个软预取口按 0>1>2 优先级三选一取 vaddr；下一行地址 = vaddr + 64B。
  // ===========================================================================
  reg         softPrefetchValid;
  reg  [49:0] softPrefetch_startAddr;
  reg  [49:0] softPrefetch_nextlineStart;
  reg         softPrefetch_isSoftPrefetch;

  // 有任一软预取口请求
  wire        soft_pf_req = io_softPrefetch_0_valid | io_softPrefetch_1_valid | io_softPrefetch_2_valid;
  // 本拍 prefetcher 真正接收了一个请求（软或硬）
  wire        pf_req_valid = softPrefetchValid | io_ftqPrefetch_req_valid;
  wire        pf_req_fire  = pf_req_ready & pf_req_valid;
  // 3 选 1 软预取 vaddr（优先级 0>1>2）
  wire [49:0] soft_pf_vaddr =
      io_softPrefetch_0_valid ? io_softPrefetch_0_bits_vaddr :
      io_softPrefetch_1_valid ? io_softPrefetch_1_bits_vaddr :
      io_softPrefetch_2_valid ? io_softPrefetch_2_bits_vaddr : 50'h0;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      softPrefetchValid          <= 1'b0;
      softPrefetch_startAddr     <= 50'h0;
      softPrefetch_nextlineStart <= 50'h0;
      softPrefetch_isSoftPrefetch<= 1'b0;
    end else begin
      // valid：来新软预取就置 1；被 prefetcher 接收（pf_req_fire）则清。新请求优先于清除。
      softPrefetchValid           <= soft_pf_req | (~pf_req_fire & softPrefetchValid);
      if (soft_pf_req) begin
        softPrefetch_startAddr     <= soft_pf_vaddr;
        softPrefetch_nextlineStart <= soft_pf_vaddr + 50'h40;  // 下一条 cacheline 起始（+64B）
      end
      // isSoftPrefetch 一旦置位保持（标记当前在途请求来自软件预取）
      softPrefetch_isSoftPrefetch <= soft_pf_req | softPrefetch_isSoftPrefetch;
    end
  end

  // ===========================================================================
  // 【逻辑 2】错误上报寄存器（io_error → BEU）
  //   MainPipe 两个 port 可能报 ECC / 总线错误。port0 优先；打一拍后从 io_error 输出。
  // ===========================================================================
  wire        errors_valid = mp_errors_0_valid | mp_errors_1_valid;
  reg  [47:0] error_paddr_r;
  reg         error_report_to_beu_r;
  reg         error_valid_r;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      error_paddr_r         <= 48'h0;
      error_report_to_beu_r <= 1'b0;
      error_valid_r         <= 1'b0;
    end else begin
      if (errors_valid) begin
        error_paddr_r         <= mp_errors_0_valid ? mp_errors_0_paddr         : mp_errors_1_paddr;
        error_report_to_beu_r <= mp_errors_0_valid ? mp_errors_0_report_to_beu : mp_errors_1_report_to_beu;
      end
      error_valid_r <= errors_valid;
    end
  end

  assign io_error_valid          = error_valid_r;
  assign io_error_bits_paddr     = error_paddr_r;
  assign io_error_bits_report_to_beu = error_report_to_beu_r;

  // ===========================================================================
  // 【逻辑 3】Meta/Data array 读写仲裁（CtrlUnit 注入 vs 正常 refill/prefetch）
  //   cu_injecting=1 时，CtrlUnit 抢占 meta/data array 的读写口（用于诊断/ECC 注入测试）；
  //   否则：meta 写 = MissUnit refill；meta 读 = Prefetch；data 写 = MissUnit refill。
  //   注入写恒带 poison=1（写入坏 ECC 以测试纠错路径）；注入 data 写数据恒 0。
  // ===========================================================================
  // meta 写源选择（注入 / refill）
  wire        meta_write_valid   = cu_injecting ? cu_metaWrite_valid   : mu_meta_write_valid;
  wire [7:0]  meta_write_virIdx  = cu_injecting ? cu_metaWrite_virIdx  : mu_meta_write_virIdx;
  wire [35:0] meta_write_phyTag  = cu_injecting ? cu_metaWrite_phyTag  : mu_meta_write_phyTag;
  wire [3:0]  meta_write_waymask = cu_injecting ? cu_metaWrite_waymask : mu_meta_write_waymask;
  wire        meta_write_bankIdx = cu_injecting ? cu_metaWrite_bankIdx : mu_meta_write_bankIdx;
  // meta 读源选择（注入 / prefetch）
  wire        meta_read_valid    = cu_injecting ? cu_metaRead_valid       : pf_metaRead_valid;
  wire [7:0]  meta_read_vSetIdx_0= cu_injecting ? cu_metaRead_vSetIdx_0   : pf_metaRead_vSetIdx_0;
  wire [7:0]  meta_read_vSetIdx_1= cu_injecting ? cu_metaRead_vSetIdx_1   : pf_metaRead_vSetIdx_1;
  // 注入读只查单行；正常 prefetch 读由 doubleline 决定是否读 bank1
  wire        meta_read_isDoubleLine = ~cu_injecting & pf_metaRead_isDoubleLine;
  // meta 写有效（注入写 valid 或 refill 写 valid）—— golden 的 `_probe`
  wire        meta_array_write_valid = cu_injecting ? cu_metaWrite_valid : mu_meta_write_valid;
  // CtrlUnit 的 metaRead.ready / metaWrite.ready / dataWrite.ready：注入态下由 array ready 决定
  wire        cu_metaRead_ready  = cu_injecting & ma_read_ready;
  // data 写源选择（注入 / refill）
  wire        data_write_valid   = cu_injecting ? cu_dataWrite_valid   : mu_data_write_valid;
  wire [7:0]  data_write_virIdx  = cu_injecting ? cu_dataWrite_virIdx  : mu_data_write_virIdx;
  wire [511:0] data_write_data   = cu_injecting ? 512'h0              : mu_data_write_data;
  wire [3:0]  data_write_waymask = cu_injecting ? cu_dataWrite_waymask : mu_data_write_waymask;
  // prefetch 的 metaRead.toIMeta.ready：非注入态下由 array ready 决定
  wire        pf_metaRead_ready  = ~cu_injecting & ma_read_ready;

  // ===========================================================================
  // 【逻辑 4】顶层输出汇聚
  // ===========================================================================
  assign io_fetch_req_ready      = mp_fetch_req_ready;
  assign io_toIFU                = mp_fetch_req_ready;
  // FTQ 硬件预取 ready：prefetcher 空闲 **且** 没有软预取在抢占
  assign io_ftqPrefetch_req_ready = pf_req_ready & ~softPrefetchValid;

  // ===========================================================================
  // 子模块例化（golden 同名黑盒：已各自验证，本顶层不重写）
  // ===========================================================================

  // ---- ICacheCtrlUnit：经独立 TileLink 口接收诊断命令，注入态抢占 meta/data 口 ----
  ICacheCtrlUnit ctrlUnitOpt (
    .clock                          (clock),
    .reset                          (reset),
    .auto_in_a_ready                (auto_ctrlUnitOpt_in_a_ready),
    .auto_in_a_valid                (auto_ctrlUnitOpt_in_a_valid),
    .auto_in_a_bits_opcode          (auto_ctrlUnitOpt_in_a_bits_opcode),
    .auto_in_a_bits_size            (auto_ctrlUnitOpt_in_a_bits_size),
    .auto_in_a_bits_source          (auto_ctrlUnitOpt_in_a_bits_source),
    .auto_in_a_bits_address         (auto_ctrlUnitOpt_in_a_bits_address),
    .auto_in_a_bits_mask            (auto_ctrlUnitOpt_in_a_bits_mask),
    .auto_in_a_bits_data            (auto_ctrlUnitOpt_in_a_bits_data),
    .auto_in_d_ready                (auto_ctrlUnitOpt_in_d_ready),
    .auto_in_d_valid                (auto_ctrlUnitOpt_in_d_valid),
    .auto_in_d_bits_opcode          (auto_ctrlUnitOpt_in_d_bits_opcode),
    .auto_in_d_bits_size            (auto_ctrlUnitOpt_in_d_bits_size),
    .auto_in_d_bits_source          (auto_ctrlUnitOpt_in_d_bits_source),
    .auto_in_d_bits_data            (auto_ctrlUnitOpt_in_d_bits_data),
    .io_ecc_enable                  (cu_ecc_enable),
    .io_injecting                   (cu_injecting),
    .io_metaRead_ready              (cu_metaRead_ready),
    .io_metaRead_valid              (cu_metaRead_valid),
    .io_metaRead_bits_vSetIdx_0     (cu_metaRead_vSetIdx_0),
    .io_metaRead_bits_vSetIdx_1     (cu_metaRead_vSetIdx_1),
    .io_metaReadResp_metas_0_0_tag  (ma_resp_metas_0_0_tag),
    .io_metaReadResp_metas_0_1_tag  (ma_resp_metas_0_1_tag),
    .io_metaReadResp_metas_0_2_tag  (ma_resp_metas_0_2_tag),
    .io_metaReadResp_metas_0_3_tag  (ma_resp_metas_0_3_tag),
    .io_metaReadResp_entryValid_0_0 (ma_resp_entryValid_0_0),
    .io_metaReadResp_entryValid_0_1 (ma_resp_entryValid_0_1),
    .io_metaReadResp_entryValid_0_2 (ma_resp_entryValid_0_2),
    .io_metaReadResp_entryValid_0_3 (ma_resp_entryValid_0_3),
    .io_metaWrite_ready             (cu_injecting),
    .io_metaWrite_valid             (cu_metaWrite_valid),
    .io_metaWrite_bits_virIdx       (cu_metaWrite_virIdx),
    .io_metaWrite_bits_phyTag       (cu_metaWrite_phyTag),
    .io_metaWrite_bits_waymask      (cu_metaWrite_waymask),
    .io_metaWrite_bits_bankIdx      (cu_metaWrite_bankIdx),
    .io_dataWrite_ready             (cu_injecting),
    .io_dataWrite_valid             (cu_dataWrite_valid),
    .io_dataWrite_bits_virIdx       (cu_dataWrite_virIdx),
    .io_dataWrite_bits_waymask      (cu_dataWrite_waymask)
  );

  // ---- ICacheMetaArray：4 路 tag/valid SRAM + ECC；写=注入或refill，读=注入或prefetch ----
  ICacheMetaArray metaArray (
    .clock                            (clock),
    .reset                            (reset),
    .io_write_valid                   (meta_array_write_valid),
    .io_write_bits_virIdx             (meta_write_virIdx),
    .io_write_bits_phyTag             (meta_write_phyTag),
    .io_write_bits_waymask            (meta_write_waymask),
    .io_write_bits_bankIdx            (meta_write_bankIdx),
    .io_write_bits_poison             (cu_injecting),
    .io_read_ready                    (ma_read_ready),
    .io_read_valid                    (meta_read_valid),
    .io_read_bits_vSetIdx_0           (meta_read_vSetIdx_0),
    .io_read_bits_vSetIdx_1           (meta_read_vSetIdx_1),
    .io_read_bits_isDoubleLine        (meta_read_isDoubleLine),
    .io_readResp_metas_0_0_tag        (ma_resp_metas_0_0_tag),
    .io_readResp_metas_0_1_tag        (ma_resp_metas_0_1_tag),
    .io_readResp_metas_0_2_tag        (ma_resp_metas_0_2_tag),
    .io_readResp_metas_0_3_tag        (ma_resp_metas_0_3_tag),
    .io_readResp_metas_1_0_tag        (ma_resp_metas_1_0_tag),
    .io_readResp_metas_1_1_tag        (ma_resp_metas_1_1_tag),
    .io_readResp_metas_1_2_tag        (ma_resp_metas_1_2_tag),
    .io_readResp_metas_1_3_tag        (ma_resp_metas_1_3_tag),
    .io_readResp_codes_0_0            (ma_resp_codes_0_0),
    .io_readResp_codes_0_1            (ma_resp_codes_0_1),
    .io_readResp_codes_0_2            (ma_resp_codes_0_2),
    .io_readResp_codes_0_3            (ma_resp_codes_0_3),
    .io_readResp_codes_1_0            (ma_resp_codes_1_0),
    .io_readResp_codes_1_1            (ma_resp_codes_1_1),
    .io_readResp_codes_1_2            (ma_resp_codes_1_2),
    .io_readResp_codes_1_3            (ma_resp_codes_1_3),
    .io_readResp_entryValid_0_0       (ma_resp_entryValid_0_0),
    .io_readResp_entryValid_0_1       (ma_resp_entryValid_0_1),
    .io_readResp_entryValid_0_2       (ma_resp_entryValid_0_2),
    .io_readResp_entryValid_0_3       (ma_resp_entryValid_0_3),
    .io_readResp_entryValid_1_0       (ma_resp_entryValid_1_0),
    .io_readResp_entryValid_1_1       (ma_resp_entryValid_1_1),
    .io_readResp_entryValid_1_2       (ma_resp_entryValid_1_2),
    .io_readResp_entryValid_1_3       (ma_resp_entryValid_1_3),
    // MainPipe 取数据/命中后冲刷某路（如 fencei/重填覆盖）
    .io_flush_0_valid                 (mp_metaFlush_0_valid),
    .io_flush_0_bits_virIdx           (mp_metaFlush_0_virIdx),
    .io_flush_0_bits_waymask          (mp_metaFlush_0_waymask),
    .io_flush_1_valid                 (mp_metaFlush_1_valid),
    .io_flush_1_bits_virIdx           (mp_metaFlush_1_virIdx),
    .io_flush_1_bits_waymask          (mp_metaFlush_1_waymask),
    .io_flushAll                      (io_fencei),
    // MBIST 串（1 个）+ SRAM 物理控制（4 个 = sigFromSrams_bore_0..3）
    .boreChildrenBd_bore_array        (boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all          (boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req          (boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack          (boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen      (boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be           (boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr         (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata       (boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen       (boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd      (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata      (boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold       (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass     (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken   (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk    (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp   (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold   (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen           (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold     (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass   (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk  (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen         (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold     (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass   (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk  (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen         (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold     (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass   (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk  (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen         (sigFromSrams_bore_3_cgen)
  );

  // ---- ICacheDataArray：4路×2bank data SRAM + ECC；写=注入或refill，读由MainPipe发起 ----
  //   注意 boreChildrenBd 映射：DataArray 内部命名 bore..bore_3（4 路 MBIST 串），
  //   顶层对应 boreChildrenBd_bore_1..4；sigFromSrams 顶层 _4.._35 → DataArray 内 _0.._31。
  ICacheDataArray dataArray (
    .clock                             (clock),
    .reset                             (reset),
    .io_write_valid                    (data_write_valid),
    .io_write_bits_virIdx              (data_write_virIdx),
    .io_write_bits_data                (data_write_data),
    .io_write_bits_waymask             (data_write_waymask),
    .io_write_bits_poison              (cu_injecting),
    .io_read_0_valid                   (mp_iData_0_valid),
    .io_read_0_bits_vSetIdx_0          (mp_iData_0_vSetIdx_0),
    .io_read_0_bits_vSetIdx_1          (mp_iData_0_vSetIdx_1),
    .io_read_0_bits_waymask_0_0        (mp_iData_0_waymask_0_0),
    .io_read_0_bits_waymask_0_1        (mp_iData_0_waymask_0_1),
    .io_read_0_bits_waymask_0_2        (mp_iData_0_waymask_0_2),
    .io_read_0_bits_waymask_0_3        (mp_iData_0_waymask_0_3),
    .io_read_0_bits_waymask_1_0        (mp_iData_0_waymask_1_0),
    .io_read_0_bits_waymask_1_1        (mp_iData_0_waymask_1_1),
    .io_read_0_bits_waymask_1_2        (mp_iData_0_waymask_1_2),
    .io_read_0_bits_waymask_1_3        (mp_iData_0_waymask_1_3),
    .io_read_0_bits_blkOffset          (mp_iData_0_blkOffset),
    .io_read_1_valid                   (mp_iData_1_valid),
    .io_read_1_bits_vSetIdx_0          (mp_iData_1_vSetIdx_0),
    .io_read_1_bits_vSetIdx_1          (mp_iData_1_vSetIdx_1),
    .io_read_2_valid                   (mp_iData_2_valid),
    .io_read_2_bits_vSetIdx_0          (mp_iData_2_vSetIdx_0),
    .io_read_2_bits_vSetIdx_1          (mp_iData_2_vSetIdx_1),
    .io_read_3_ready                   (da_read_3_ready),
    .io_read_3_valid                   (mp_iData_3_valid),
    .io_read_3_bits_vSetIdx_0          (mp_iData_3_vSetIdx_0),
    .io_read_3_bits_vSetIdx_1          (mp_iData_3_vSetIdx_1),
    .io_readResp_datas_0               (da_resp_datas_0),
    .io_readResp_datas_1               (da_resp_datas_1),
    .io_readResp_datas_2               (da_resp_datas_2),
    .io_readResp_datas_3               (da_resp_datas_3),
    .io_readResp_datas_4               (da_resp_datas_4),
    .io_readResp_datas_5               (da_resp_datas_5),
    .io_readResp_datas_6               (da_resp_datas_6),
    .io_readResp_datas_7               (da_resp_datas_7),
    .io_readResp_codes_0               (da_resp_codes_0),
    .io_readResp_codes_1               (da_resp_codes_1),
    .io_readResp_codes_2               (da_resp_codes_2),
    .io_readResp_codes_3               (da_resp_codes_3),
    .io_readResp_codes_4               (da_resp_codes_4),
    .io_readResp_codes_5               (da_resp_codes_5),
    .io_readResp_codes_6               (da_resp_codes_6),
    .io_readResp_codes_7               (da_resp_codes_7),
    // DataArray 4 个 MBIST 串 ← 顶层 boreChildrenBd_bore_1..4
    .boreChildrenBd_bore_array         (boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_all           (boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_req           (boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_ack           (boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_writeen       (boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_be            (boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_addr          (boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_indata        (boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_readen        (boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_addr_rd       (boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_outdata       (boreChildrenBd_bore_1_outdata),
    .boreChildrenBd_bore_1_array       (boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_1_all         (boreChildrenBd_bore_2_all),
    .boreChildrenBd_bore_1_req         (boreChildrenBd_bore_2_req),
    .boreChildrenBd_bore_1_ack         (boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_1_writeen     (boreChildrenBd_bore_2_writeen),
    .boreChildrenBd_bore_1_be          (boreChildrenBd_bore_2_be),
    .boreChildrenBd_bore_1_addr        (boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_1_indata      (boreChildrenBd_bore_2_indata),
    .boreChildrenBd_bore_1_readen      (boreChildrenBd_bore_2_readen),
    .boreChildrenBd_bore_1_addr_rd     (boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_1_outdata     (boreChildrenBd_bore_2_outdata),
    .boreChildrenBd_bore_2_array       (boreChildrenBd_bore_3_array),
    .boreChildrenBd_bore_2_all         (boreChildrenBd_bore_3_all),
    .boreChildrenBd_bore_2_req         (boreChildrenBd_bore_3_req),
    .boreChildrenBd_bore_2_ack         (boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_2_writeen     (boreChildrenBd_bore_3_writeen),
    .boreChildrenBd_bore_2_be          (boreChildrenBd_bore_3_be),
    .boreChildrenBd_bore_2_addr        (boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_2_indata      (boreChildrenBd_bore_3_indata),
    .boreChildrenBd_bore_2_readen      (boreChildrenBd_bore_3_readen),
    .boreChildrenBd_bore_2_addr_rd     (boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_2_outdata     (boreChildrenBd_bore_3_outdata),
    .boreChildrenBd_bore_3_array       (boreChildrenBd_bore_4_array),
    .boreChildrenBd_bore_3_all         (boreChildrenBd_bore_4_all),
    .boreChildrenBd_bore_3_req         (boreChildrenBd_bore_4_req),
    .boreChildrenBd_bore_3_ack         (boreChildrenBd_bore_4_ack),
    .boreChildrenBd_bore_3_writeen     (boreChildrenBd_bore_4_writeen),
    .boreChildrenBd_bore_3_be          (boreChildrenBd_bore_4_be),
    .boreChildrenBd_bore_3_addr        (boreChildrenBd_bore_4_addr),
    .boreChildrenBd_bore_3_indata      (boreChildrenBd_bore_4_indata),
    .boreChildrenBd_bore_3_readen      (boreChildrenBd_bore_4_readen),
    .boreChildrenBd_bore_3_addr_rd     (boreChildrenBd_bore_4_addr_rd),
    .boreChildrenBd_bore_3_outdata     (boreChildrenBd_bore_4_outdata),
    .sigFromSrams_bore_ram_hold        (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_ram_bypass      (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken    (sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk     (sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp    (sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold    (sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_cgen            (sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_1_ram_hold      (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_1_ram_bypass    (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken  (sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk   (sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp  (sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold  (sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen          (sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_2_ram_hold      (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_2_ram_bypass    (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken  (sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk   (sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp  (sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold  (sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen          (sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_3_ram_hold      (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_3_ram_bypass    (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken  (sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk   (sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp  (sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold  (sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen          (sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_4_ram_hold      (sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_4_ram_bypass    (sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken  (sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk   (sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp  (sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold  (sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen          (sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_5_ram_hold      (sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_5_ram_bypass    (sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken  (sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk   (sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp  (sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold  (sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen          (sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_6_ram_hold      (sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_6_ram_bypass    (sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken  (sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk   (sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp  (sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold  (sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen          (sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_7_ram_hold      (sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_7_ram_bypass    (sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken  (sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk   (sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp  (sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold  (sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen          (sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_8_ram_hold      (sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_8_ram_bypass    (sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken  (sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk   (sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp  (sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold  (sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen          (sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_9_ram_hold      (sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_9_ram_bypass    (sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken  (sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk   (sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp  (sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold  (sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen          (sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_10_ram_hold     (sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_10_ram_bypass   (sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken (sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk  (sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp (sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold (sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen         (sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_11_ram_hold     (sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_11_ram_bypass   (sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken (sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk  (sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp (sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold (sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen         (sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_12_ram_hold     (sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_12_ram_bypass   (sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken (sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk  (sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp (sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold (sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen         (sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_13_ram_hold     (sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_13_ram_bypass   (sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken (sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk  (sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp (sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold (sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen         (sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_14_ram_hold     (sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_14_ram_bypass   (sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken (sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk  (sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp (sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold (sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen         (sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_15_ram_hold     (sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_15_ram_bypass   (sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken (sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk  (sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp (sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold (sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen         (sigFromSrams_bore_19_cgen),
    .sigFromSrams_bore_16_ram_hold     (sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_16_ram_bypass   (sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken (sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk  (sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp (sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold (sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen         (sigFromSrams_bore_20_cgen),
    .sigFromSrams_bore_17_ram_hold     (sigFromSrams_bore_21_ram_hold),
    .sigFromSrams_bore_17_ram_bypass   (sigFromSrams_bore_21_ram_bypass),
    .sigFromSrams_bore_17_ram_bp_clken (sigFromSrams_bore_21_ram_bp_clken),
    .sigFromSrams_bore_17_ram_aux_clk  (sigFromSrams_bore_21_ram_aux_clk),
    .sigFromSrams_bore_17_ram_aux_ckbp (sigFromSrams_bore_21_ram_aux_ckbp),
    .sigFromSrams_bore_17_ram_mcp_hold (sigFromSrams_bore_21_ram_mcp_hold),
    .sigFromSrams_bore_17_cgen         (sigFromSrams_bore_21_cgen),
    .sigFromSrams_bore_18_ram_hold     (sigFromSrams_bore_22_ram_hold),
    .sigFromSrams_bore_18_ram_bypass   (sigFromSrams_bore_22_ram_bypass),
    .sigFromSrams_bore_18_ram_bp_clken (sigFromSrams_bore_22_ram_bp_clken),
    .sigFromSrams_bore_18_ram_aux_clk  (sigFromSrams_bore_22_ram_aux_clk),
    .sigFromSrams_bore_18_ram_aux_ckbp (sigFromSrams_bore_22_ram_aux_ckbp),
    .sigFromSrams_bore_18_ram_mcp_hold (sigFromSrams_bore_22_ram_mcp_hold),
    .sigFromSrams_bore_18_cgen         (sigFromSrams_bore_22_cgen),
    .sigFromSrams_bore_19_ram_hold     (sigFromSrams_bore_23_ram_hold),
    .sigFromSrams_bore_19_ram_bypass   (sigFromSrams_bore_23_ram_bypass),
    .sigFromSrams_bore_19_ram_bp_clken (sigFromSrams_bore_23_ram_bp_clken),
    .sigFromSrams_bore_19_ram_aux_clk  (sigFromSrams_bore_23_ram_aux_clk),
    .sigFromSrams_bore_19_ram_aux_ckbp (sigFromSrams_bore_23_ram_aux_ckbp),
    .sigFromSrams_bore_19_ram_mcp_hold (sigFromSrams_bore_23_ram_mcp_hold),
    .sigFromSrams_bore_19_cgen         (sigFromSrams_bore_23_cgen),
    .sigFromSrams_bore_20_ram_hold     (sigFromSrams_bore_24_ram_hold),
    .sigFromSrams_bore_20_ram_bypass   (sigFromSrams_bore_24_ram_bypass),
    .sigFromSrams_bore_20_ram_bp_clken (sigFromSrams_bore_24_ram_bp_clken),
    .sigFromSrams_bore_20_ram_aux_clk  (sigFromSrams_bore_24_ram_aux_clk),
    .sigFromSrams_bore_20_ram_aux_ckbp (sigFromSrams_bore_24_ram_aux_ckbp),
    .sigFromSrams_bore_20_ram_mcp_hold (sigFromSrams_bore_24_ram_mcp_hold),
    .sigFromSrams_bore_20_cgen         (sigFromSrams_bore_24_cgen),
    .sigFromSrams_bore_21_ram_hold     (sigFromSrams_bore_25_ram_hold),
    .sigFromSrams_bore_21_ram_bypass   (sigFromSrams_bore_25_ram_bypass),
    .sigFromSrams_bore_21_ram_bp_clken (sigFromSrams_bore_25_ram_bp_clken),
    .sigFromSrams_bore_21_ram_aux_clk  (sigFromSrams_bore_25_ram_aux_clk),
    .sigFromSrams_bore_21_ram_aux_ckbp (sigFromSrams_bore_25_ram_aux_ckbp),
    .sigFromSrams_bore_21_ram_mcp_hold (sigFromSrams_bore_25_ram_mcp_hold),
    .sigFromSrams_bore_21_cgen         (sigFromSrams_bore_25_cgen),
    .sigFromSrams_bore_22_ram_hold     (sigFromSrams_bore_26_ram_hold),
    .sigFromSrams_bore_22_ram_bypass   (sigFromSrams_bore_26_ram_bypass),
    .sigFromSrams_bore_22_ram_bp_clken (sigFromSrams_bore_26_ram_bp_clken),
    .sigFromSrams_bore_22_ram_aux_clk  (sigFromSrams_bore_26_ram_aux_clk),
    .sigFromSrams_bore_22_ram_aux_ckbp (sigFromSrams_bore_26_ram_aux_ckbp),
    .sigFromSrams_bore_22_ram_mcp_hold (sigFromSrams_bore_26_ram_mcp_hold),
    .sigFromSrams_bore_22_cgen         (sigFromSrams_bore_26_cgen),
    .sigFromSrams_bore_23_ram_hold     (sigFromSrams_bore_27_ram_hold),
    .sigFromSrams_bore_23_ram_bypass   (sigFromSrams_bore_27_ram_bypass),
    .sigFromSrams_bore_23_ram_bp_clken (sigFromSrams_bore_27_ram_bp_clken),
    .sigFromSrams_bore_23_ram_aux_clk  (sigFromSrams_bore_27_ram_aux_clk),
    .sigFromSrams_bore_23_ram_aux_ckbp (sigFromSrams_bore_27_ram_aux_ckbp),
    .sigFromSrams_bore_23_ram_mcp_hold (sigFromSrams_bore_27_ram_mcp_hold),
    .sigFromSrams_bore_23_cgen         (sigFromSrams_bore_27_cgen),
    .sigFromSrams_bore_24_ram_hold     (sigFromSrams_bore_28_ram_hold),
    .sigFromSrams_bore_24_ram_bypass   (sigFromSrams_bore_28_ram_bypass),
    .sigFromSrams_bore_24_ram_bp_clken (sigFromSrams_bore_28_ram_bp_clken),
    .sigFromSrams_bore_24_ram_aux_clk  (sigFromSrams_bore_28_ram_aux_clk),
    .sigFromSrams_bore_24_ram_aux_ckbp (sigFromSrams_bore_28_ram_aux_ckbp),
    .sigFromSrams_bore_24_ram_mcp_hold (sigFromSrams_bore_28_ram_mcp_hold),
    .sigFromSrams_bore_24_cgen         (sigFromSrams_bore_28_cgen),
    .sigFromSrams_bore_25_ram_hold     (sigFromSrams_bore_29_ram_hold),
    .sigFromSrams_bore_25_ram_bypass   (sigFromSrams_bore_29_ram_bypass),
    .sigFromSrams_bore_25_ram_bp_clken (sigFromSrams_bore_29_ram_bp_clken),
    .sigFromSrams_bore_25_ram_aux_clk  (sigFromSrams_bore_29_ram_aux_clk),
    .sigFromSrams_bore_25_ram_aux_ckbp (sigFromSrams_bore_29_ram_aux_ckbp),
    .sigFromSrams_bore_25_ram_mcp_hold (sigFromSrams_bore_29_ram_mcp_hold),
    .sigFromSrams_bore_25_cgen         (sigFromSrams_bore_29_cgen),
    .sigFromSrams_bore_26_ram_hold     (sigFromSrams_bore_30_ram_hold),
    .sigFromSrams_bore_26_ram_bypass   (sigFromSrams_bore_30_ram_bypass),
    .sigFromSrams_bore_26_ram_bp_clken (sigFromSrams_bore_30_ram_bp_clken),
    .sigFromSrams_bore_26_ram_aux_clk  (sigFromSrams_bore_30_ram_aux_clk),
    .sigFromSrams_bore_26_ram_aux_ckbp (sigFromSrams_bore_30_ram_aux_ckbp),
    .sigFromSrams_bore_26_ram_mcp_hold (sigFromSrams_bore_30_ram_mcp_hold),
    .sigFromSrams_bore_26_cgen         (sigFromSrams_bore_30_cgen),
    .sigFromSrams_bore_27_ram_hold     (sigFromSrams_bore_31_ram_hold),
    .sigFromSrams_bore_27_ram_bypass   (sigFromSrams_bore_31_ram_bypass),
    .sigFromSrams_bore_27_ram_bp_clken (sigFromSrams_bore_31_ram_bp_clken),
    .sigFromSrams_bore_27_ram_aux_clk  (sigFromSrams_bore_31_ram_aux_clk),
    .sigFromSrams_bore_27_ram_aux_ckbp (sigFromSrams_bore_31_ram_aux_ckbp),
    .sigFromSrams_bore_27_ram_mcp_hold (sigFromSrams_bore_31_ram_mcp_hold),
    .sigFromSrams_bore_27_cgen         (sigFromSrams_bore_31_cgen),
    .sigFromSrams_bore_28_ram_hold     (sigFromSrams_bore_32_ram_hold),
    .sigFromSrams_bore_28_ram_bypass   (sigFromSrams_bore_32_ram_bypass),
    .sigFromSrams_bore_28_ram_bp_clken (sigFromSrams_bore_32_ram_bp_clken),
    .sigFromSrams_bore_28_ram_aux_clk  (sigFromSrams_bore_32_ram_aux_clk),
    .sigFromSrams_bore_28_ram_aux_ckbp (sigFromSrams_bore_32_ram_aux_ckbp),
    .sigFromSrams_bore_28_ram_mcp_hold (sigFromSrams_bore_32_ram_mcp_hold),
    .sigFromSrams_bore_28_cgen         (sigFromSrams_bore_32_cgen),
    .sigFromSrams_bore_29_ram_hold     (sigFromSrams_bore_33_ram_hold),
    .sigFromSrams_bore_29_ram_bypass   (sigFromSrams_bore_33_ram_bypass),
    .sigFromSrams_bore_29_ram_bp_clken (sigFromSrams_bore_33_ram_bp_clken),
    .sigFromSrams_bore_29_ram_aux_clk  (sigFromSrams_bore_33_ram_aux_clk),
    .sigFromSrams_bore_29_ram_aux_ckbp (sigFromSrams_bore_33_ram_aux_ckbp),
    .sigFromSrams_bore_29_ram_mcp_hold (sigFromSrams_bore_33_ram_mcp_hold),
    .sigFromSrams_bore_29_cgen         (sigFromSrams_bore_33_cgen),
    .sigFromSrams_bore_30_ram_hold     (sigFromSrams_bore_34_ram_hold),
    .sigFromSrams_bore_30_ram_bypass   (sigFromSrams_bore_34_ram_bypass),
    .sigFromSrams_bore_30_ram_bp_clken (sigFromSrams_bore_34_ram_bp_clken),
    .sigFromSrams_bore_30_ram_aux_clk  (sigFromSrams_bore_34_ram_aux_clk),
    .sigFromSrams_bore_30_ram_aux_ckbp (sigFromSrams_bore_34_ram_aux_ckbp),
    .sigFromSrams_bore_30_ram_mcp_hold (sigFromSrams_bore_34_ram_mcp_hold),
    .sigFromSrams_bore_30_cgen         (sigFromSrams_bore_34_cgen),
    .sigFromSrams_bore_31_ram_hold     (sigFromSrams_bore_35_ram_hold),
    .sigFromSrams_bore_31_ram_bypass   (sigFromSrams_bore_35_ram_bypass),
    .sigFromSrams_bore_31_ram_bp_clken (sigFromSrams_bore_35_ram_bp_clken),
    .sigFromSrams_bore_31_ram_aux_clk  (sigFromSrams_bore_35_ram_aux_clk),
    .sigFromSrams_bore_31_ram_aux_ckbp (sigFromSrams_bore_35_ram_aux_ckbp),
    .sigFromSrams_bore_31_ram_mcp_hold (sigFromSrams_bore_35_ram_mcp_hold),
    .sigFromSrams_bore_31_cgen         (sigFromSrams_bore_35_cgen)
  );

  // ---- ICacheMainPipe：IFU 取指主流水（s0/s1/s2）；从 WayLookup 读命中信息，读 DataArray 取指 ----
  ICacheMainPipe mainPipe (
    .clock                                        (clock),
    .reset                                        (reset),
    .io_dataArray_toIData_0_valid                 (mp_iData_0_valid),
    .io_dataArray_toIData_0_bits_vSetIdx_0        (mp_iData_0_vSetIdx_0),
    .io_dataArray_toIData_0_bits_vSetIdx_1        (mp_iData_0_vSetIdx_1),
    .io_dataArray_toIData_0_bits_waymask_0_0      (mp_iData_0_waymask_0_0),
    .io_dataArray_toIData_0_bits_waymask_0_1      (mp_iData_0_waymask_0_1),
    .io_dataArray_toIData_0_bits_waymask_0_2      (mp_iData_0_waymask_0_2),
    .io_dataArray_toIData_0_bits_waymask_0_3      (mp_iData_0_waymask_0_3),
    .io_dataArray_toIData_0_bits_waymask_1_0      (mp_iData_0_waymask_1_0),
    .io_dataArray_toIData_0_bits_waymask_1_1      (mp_iData_0_waymask_1_1),
    .io_dataArray_toIData_0_bits_waymask_1_2      (mp_iData_0_waymask_1_2),
    .io_dataArray_toIData_0_bits_waymask_1_3      (mp_iData_0_waymask_1_3),
    .io_dataArray_toIData_0_bits_blkOffset        (mp_iData_0_blkOffset),
    .io_dataArray_toIData_1_valid                 (mp_iData_1_valid),
    .io_dataArray_toIData_1_bits_vSetIdx_0        (mp_iData_1_vSetIdx_0),
    .io_dataArray_toIData_1_bits_vSetIdx_1        (mp_iData_1_vSetIdx_1),
    .io_dataArray_toIData_2_valid                 (mp_iData_2_valid),
    .io_dataArray_toIData_2_bits_vSetIdx_0        (mp_iData_2_vSetIdx_0),
    .io_dataArray_toIData_2_bits_vSetIdx_1        (mp_iData_2_vSetIdx_1),
    .io_dataArray_toIData_3_ready                 (da_read_3_ready),
    .io_dataArray_toIData_3_valid                 (mp_iData_3_valid),
    .io_dataArray_toIData_3_bits_vSetIdx_0        (mp_iData_3_vSetIdx_0),
    .io_dataArray_toIData_3_bits_vSetIdx_1        (mp_iData_3_vSetIdx_1),
    .io_dataArray_fromIData_datas_0               (da_resp_datas_0),
    .io_dataArray_fromIData_datas_1               (da_resp_datas_1),
    .io_dataArray_fromIData_datas_2               (da_resp_datas_2),
    .io_dataArray_fromIData_datas_3               (da_resp_datas_3),
    .io_dataArray_fromIData_datas_4               (da_resp_datas_4),
    .io_dataArray_fromIData_datas_5               (da_resp_datas_5),
    .io_dataArray_fromIData_datas_6               (da_resp_datas_6),
    .io_dataArray_fromIData_datas_7               (da_resp_datas_7),
    .io_dataArray_fromIData_codes_0               (da_resp_codes_0),
    .io_dataArray_fromIData_codes_1               (da_resp_codes_1),
    .io_dataArray_fromIData_codes_2               (da_resp_codes_2),
    .io_dataArray_fromIData_codes_3               (da_resp_codes_3),
    .io_dataArray_fromIData_codes_4               (da_resp_codes_4),
    .io_dataArray_fromIData_codes_5               (da_resp_codes_5),
    .io_dataArray_fromIData_codes_6               (da_resp_codes_6),
    .io_dataArray_fromIData_codes_7               (da_resp_codes_7),
    .io_metaArrayFlush_0_valid                    (mp_metaFlush_0_valid),
    .io_metaArrayFlush_0_bits_virIdx              (mp_metaFlush_0_virIdx),
    .io_metaArrayFlush_0_bits_waymask             (mp_metaFlush_0_waymask),
    .io_metaArrayFlush_1_valid                    (mp_metaFlush_1_valid),
    .io_metaArrayFlush_1_bits_virIdx              (mp_metaFlush_1_virIdx),
    .io_metaArrayFlush_1_bits_waymask             (mp_metaFlush_1_waymask),
    .io_touch_0_valid                             (mp_touch_0_valid),
    .io_touch_0_bits_vSetIdx                      (mp_touch_0_vSetIdx),
    .io_touch_0_bits_way                          (mp_touch_0_way),
    .io_touch_1_valid                             (mp_touch_1_valid),
    .io_touch_1_bits_vSetIdx                      (mp_touch_1_vSetIdx),
    .io_touch_1_bits_way                          (mp_touch_1_way),
    .io_wayLookupRead_ready                       (mp_wayLookupRead_ready),
    .io_wayLookupRead_valid                       (wl_read_valid),
    .io_wayLookupRead_bits_entry_vSetIdx_0        (wl_read_vSetIdx_0),
    .io_wayLookupRead_bits_entry_vSetIdx_1        (wl_read_vSetIdx_1),
    .io_wayLookupRead_bits_entry_waymask_0        (wl_read_waymask_0),
    .io_wayLookupRead_bits_entry_waymask_1        (wl_read_waymask_1),
    .io_wayLookupRead_bits_entry_ptag_0           (wl_read_ptag_0),
    .io_wayLookupRead_bits_entry_ptag_1           (wl_read_ptag_1),
    .io_wayLookupRead_bits_entry_itlb_exception_0 (wl_read_itlb_exception_0),
    .io_wayLookupRead_bits_entry_itlb_exception_1 (wl_read_itlb_exception_1),
    .io_wayLookupRead_bits_entry_itlb_pbmt_0      (wl_read_itlb_pbmt_0),
    .io_wayLookupRead_bits_entry_itlb_pbmt_1      (wl_read_itlb_pbmt_1),
    .io_wayLookupRead_bits_entry_meta_codes_0     (wl_read_meta_codes_0),
    .io_wayLookupRead_bits_entry_meta_codes_1     (wl_read_meta_codes_1),
    .io_wayLookupRead_bits_gpf_gpaddr             (wl_read_gpf_gpaddr),
    .io_wayLookupRead_bits_gpf_isForVSnonLeafPTE  (wl_read_gpf_isForVSnonLeafPTE),
    .io_mshr_req_ready                            (mu_fetch_req_ready),
    .io_mshr_req_valid                            (mp_mshr_req_valid),
    .io_mshr_req_bits_blkPaddr                    (mp_mshr_req_blkPaddr),
    .io_mshr_req_bits_vSetIdx                     (mp_mshr_req_vSetIdx),
    .io_mshr_resp_valid                           (mu_fetch_resp_valid),
    .io_mshr_resp_bits_blkPaddr                   (mu_fetch_resp_blkPaddr),
    .io_mshr_resp_bits_vSetIdx                    (mu_fetch_resp_vSetIdx),
    .io_mshr_resp_bits_data                       (mu_fetch_resp_data),
    .io_mshr_resp_bits_corrupt                    (mu_fetch_resp_corrupt),
    .io_ecc_enable                                (cu_ecc_enable),
    .io_fetch_req_ready                           (mp_fetch_req_ready),
    .io_fetch_req_valid                           (io_fetch_req_valid),
    .io_fetch_req_bits_pcMemRead_0_startAddr      (io_fetch_req_bits_pcMemRead_0_startAddr),
    .io_fetch_req_bits_pcMemRead_0_nextlineStart  (io_fetch_req_bits_pcMemRead_0_nextlineStart),
    .io_fetch_req_bits_pcMemRead_1_startAddr      (io_fetch_req_bits_pcMemRead_1_startAddr),
    .io_fetch_req_bits_pcMemRead_1_nextlineStart  (io_fetch_req_bits_pcMemRead_1_nextlineStart),
    .io_fetch_req_bits_pcMemRead_2_startAddr      (io_fetch_req_bits_pcMemRead_2_startAddr),
    .io_fetch_req_bits_pcMemRead_2_nextlineStart  (io_fetch_req_bits_pcMemRead_2_nextlineStart),
    .io_fetch_req_bits_pcMemRead_3_startAddr      (io_fetch_req_bits_pcMemRead_3_startAddr),
    .io_fetch_req_bits_pcMemRead_3_nextlineStart  (io_fetch_req_bits_pcMemRead_3_nextlineStart),
    .io_fetch_req_bits_pcMemRead_4_startAddr      (io_fetch_req_bits_pcMemRead_4_startAddr),
    .io_fetch_req_bits_pcMemRead_4_nextlineStart  (io_fetch_req_bits_pcMemRead_4_nextlineStart),
    .io_fetch_req_bits_readValid_0                (io_fetch_req_bits_readValid_0),
    .io_fetch_req_bits_readValid_1                (io_fetch_req_bits_readValid_1),
    .io_fetch_req_bits_readValid_2                (io_fetch_req_bits_readValid_2),
    .io_fetch_req_bits_readValid_3                (io_fetch_req_bits_readValid_3),
    .io_fetch_req_bits_readValid_4                (io_fetch_req_bits_readValid_4),
    .io_fetch_req_bits_backendException           (io_fetch_req_bits_backendException),
    .io_fetch_resp_valid                          (io_fetch_resp_valid),
    .io_fetch_resp_bits_doubleline                (io_fetch_resp_bits_doubleline),
    .io_fetch_resp_bits_vaddr_0                   (io_fetch_resp_bits_vaddr_0),
    .io_fetch_resp_bits_vaddr_1                   (io_fetch_resp_bits_vaddr_1),
    .io_fetch_resp_bits_data                      (io_fetch_resp_bits_data),
    .io_fetch_resp_bits_paddr_0                   (io_fetch_resp_bits_paddr_0),
    .io_fetch_resp_bits_exception_0               (io_fetch_resp_bits_exception_0),
    .io_fetch_resp_bits_exception_1               (io_fetch_resp_bits_exception_1),
    .io_fetch_resp_bits_pmp_mmio_0                (io_fetch_resp_bits_pmp_mmio_0),
    .io_fetch_resp_bits_pmp_mmio_1                (io_fetch_resp_bits_pmp_mmio_1),
    .io_fetch_resp_bits_itlb_pbmt_0               (io_fetch_resp_bits_itlb_pbmt_0),
    .io_fetch_resp_bits_itlb_pbmt_1               (io_fetch_resp_bits_itlb_pbmt_1),
    .io_fetch_resp_bits_backendException          (io_fetch_resp_bits_backendException),
    .io_fetch_resp_bits_gpaddr                    (io_fetch_resp_bits_gpaddr),
    .io_fetch_resp_bits_isForVSnonLeafPTE         (io_fetch_resp_bits_isForVSnonLeafPTE),
    .io_fetch_topdownIcacheMiss                   (io_fetch_topdownIcacheMiss),
    .io_fetch_topdownItlbMiss                     (io_fetch_topdownItlbMiss),
    .io_flush                                     (io_flush),
    .io_pmp_0_req_bits_addr                       (io_pmp_0_req_bits_addr),
    .io_pmp_0_resp_instr                          (io_pmp_0_resp_instr),
    .io_pmp_0_resp_mmio                           (io_pmp_0_resp_mmio),
    .io_pmp_1_req_bits_addr                       (io_pmp_1_req_bits_addr),
    .io_pmp_1_resp_instr                          (io_pmp_1_resp_instr),
    .io_pmp_1_resp_mmio                           (io_pmp_1_resp_mmio),
    .io_respStall                                 (io_stop),
    .io_errors_0_valid                            (mp_errors_0_valid),
    .io_errors_0_bits_paddr                       (mp_errors_0_paddr),
    .io_errors_0_bits_report_to_beu              (mp_errors_0_report_to_beu),
    .io_errors_1_valid                            (mp_errors_1_valid),
    .io_errors_1_bits_paddr                       (mp_errors_1_paddr),
    .io_errors_1_bits_report_to_beu              (mp_errors_1_report_to_beu),
    .io_perfInfo_only_0_hit                       (io_perfInfo_only_0_hit),
    .io_perfInfo_only_0_miss                      (io_perfInfo_only_0_miss),
    .io_perfInfo_hit_0_hit_1                      (io_perfInfo_hit_0_hit_1),
    .io_perfInfo_hit_0_miss_1                     (io_perfInfo_hit_0_miss_1),
    .io_perfInfo_miss_0_hit_1                     (io_perfInfo_miss_0_hit_1),
    .io_perfInfo_miss_0_miss_1                    (io_perfInfo_miss_0_miss_1),
    .io_perfInfo_hit_0_except_1                   (io_perfInfo_hit_0_except_1),
    .io_perfInfo_miss_0_except_1                  (io_perfInfo_miss_0_except_1),
    .io_perfInfo_except_0                         (io_perfInfo_except_0),
    .io_perfInfo_bank_hit_0                       (io_perfInfo_bank_hit_0),
    .io_perfInfo_bank_hit_1                       (io_perfInfo_bank_hit_1),
    .io_perfInfo_hit                              (io_perfInfo_hit)
  );

  // ---- ICacheMissUnit：MSHR；接 MainPipe(取指 miss) 与 Prefetch(预取 miss)，向 L2 取行回填 ----
  ICacheMissUnit missUnit (
    .clock                         (clock),
    .reset                         (reset),
    .io_fencei                     (io_fencei),
    .io_flush                      (io_flush),
    .io_wfi_wfiReq                 (io_wfi_wfiReq),
    .io_wfi_wfiSafe                (io_wfi_wfiSafe),
    .io_fetch_req_ready            (mu_fetch_req_ready),
    .io_fetch_req_valid            (mp_mshr_req_valid),
    .io_fetch_req_bits_blkPaddr    (mp_mshr_req_blkPaddr),
    .io_fetch_req_bits_vSetIdx     (mp_mshr_req_vSetIdx),
    .io_fetch_resp_valid           (mu_fetch_resp_valid),
    .io_fetch_resp_bits_blkPaddr   (mu_fetch_resp_blkPaddr),
    .io_fetch_resp_bits_vSetIdx    (mu_fetch_resp_vSetIdx),
    .io_fetch_resp_bits_waymask    (mu_fetch_resp_waymask),
    .io_fetch_resp_bits_data       (mu_fetch_resp_data),
    .io_fetch_resp_bits_corrupt    (mu_fetch_resp_corrupt),
    .io_prefetch_req_ready         (mu_prefetch_req_ready),
    .io_prefetch_req_valid         (pf_mshr_valid),
    .io_prefetch_req_bits_blkPaddr (pf_mshr_blkPaddr),
    .io_prefetch_req_bits_vSetIdx  (pf_mshr_vSetIdx),
    .io_meta_write_valid           (mu_meta_write_valid),
    .io_meta_write_bits_virIdx     (mu_meta_write_virIdx),
    .io_meta_write_bits_phyTag     (mu_meta_write_phyTag),
    .io_meta_write_bits_waymask    (mu_meta_write_waymask),
    .io_meta_write_bits_bankIdx    (mu_meta_write_bankIdx),
    .io_data_write_valid           (mu_data_write_valid),
    .io_data_write_bits_virIdx     (mu_data_write_virIdx),
    .io_data_write_bits_data       (mu_data_write_data),
    .io_data_write_bits_waymask    (mu_data_write_waymask),
    .io_victim_vSetIdx_valid       (mu_victim_valid),
    .io_victim_vSetIdx_bits        (mu_victim_vSetIdx),
    .io_victim_way                 (rpl_victim_way),
    .io_mem_acquire_ready          (auto_client_out_a_ready),
    .io_mem_acquire_valid          (auto_client_out_a_valid),
    .io_mem_acquire_bits_source    (auto_client_out_a_bits_source),
    .io_mem_acquire_bits_address   (auto_client_out_a_bits_address),
    .io_mem_grant_valid            (auto_client_out_d_valid),
    .io_mem_grant_bits_opcode      (auto_client_out_d_bits_opcode),
    .io_mem_grant_bits_size        (auto_client_out_d_bits_size),
    .io_mem_grant_bits_source      (auto_client_out_d_bits_source),
    .io_mem_grant_bits_data        (auto_client_out_d_bits_data),
    .io_mem_grant_bits_corrupt     (auto_client_out_d_bits_corrupt)
  );

  // ---- ICacheReplacer：PLRU；touch（命中/重填）更新，victim_vSetIdx 查询给出 victim_way ----
  ICacheReplacer replacer (
    .clock                   (clock),
    .reset                   (reset),
    .io_touch_0_valid        (mp_touch_0_valid),
    .io_touch_0_bits_vSetIdx (mp_touch_0_vSetIdx),
    .io_touch_0_bits_way     (mp_touch_0_way),
    .io_touch_1_valid        (mp_touch_1_valid),
    .io_touch_1_bits_vSetIdx (mp_touch_1_vSetIdx),
    .io_touch_1_bits_way     (mp_touch_1_way),
    .io_victim_vSetIdx_valid (mu_victim_valid),
    .io_victim_vSetIdx_bits  (mu_victim_vSetIdx),
    .io_victim_way           (rpl_victim_way)
  );

  // ---- IPrefetchPipe：预取流水；req 经软预取/FTQ 仲裁；读 MetaArray，miss 向 MissUnit 发预取 ----
  IPrefetchPipe prefetcher (
    .clock                                         (clock),
    .reset                                         (reset),
    .io_csr_pf_enable                              (io_csr_pf_enable),
    .io_flush                                      (io_flush),
    .io_req_ready                                  (pf_req_ready),
    .io_req_valid                                  (pf_req_valid),
    // 软预取抢占：valid 时取锁存的软预取地址，否则取 FTQ 地址
    .io_req_bits_startAddr                         (softPrefetchValid ? softPrefetch_startAddr     : io_ftqPrefetch_req_bits_startAddr),
    .io_req_bits_nextlineStart                     (softPrefetchValid ? softPrefetch_nextlineStart : io_ftqPrefetch_req_bits_nextlineStart),
    .io_req_bits_ftqIdx_flag                       (~softPrefetchValid & io_ftqPrefetch_req_bits_ftqIdx_flag),
    .io_req_bits_ftqIdx_value                      (softPrefetchValid ? 6'h0 : io_ftqPrefetch_req_bits_ftqIdx_value),
    .io_req_bits_isSoftPrefetch                    (softPrefetchValid & softPrefetch_isSoftPrefetch),
    .io_req_bits_backendException                  (io_ftqPrefetch_backendException),
    .io_flushFromBpu_s2_valid                      (io_ftqPrefetch_flushFromBpu_s2_valid),
    .io_flushFromBpu_s2_bits_flag                  (io_ftqPrefetch_flushFromBpu_s2_bits_flag),
    .io_flushFromBpu_s2_bits_value                 (io_ftqPrefetch_flushFromBpu_s2_bits_value),
    .io_flushFromBpu_s3_valid                      (io_ftqPrefetch_flushFromBpu_s3_valid),
    .io_flushFromBpu_s3_bits_flag                  (io_ftqPrefetch_flushFromBpu_s3_bits_flag),
    .io_flushFromBpu_s3_bits_value                 (io_ftqPrefetch_flushFromBpu_s3_bits_value),
    .io_itlb_0_req_valid                           (io_itlb_0_req_valid),
    .io_itlb_0_req_bits_vaddr                      (io_itlb_0_req_bits_vaddr),
    .io_itlb_0_resp_bits_paddr_0                   (io_itlb_0_resp_bits_paddr_0),
    .io_itlb_0_resp_bits_gpaddr_0                  (io_itlb_0_resp_bits_gpaddr_0),
    .io_itlb_0_resp_bits_pbmt_0                    (io_itlb_0_resp_bits_pbmt_0),
    .io_itlb_0_resp_bits_miss                      (io_itlb_0_resp_bits_miss),
    .io_itlb_0_resp_bits_isForVSnonLeafPTE         (io_itlb_0_resp_bits_isForVSnonLeafPTE),
    .io_itlb_0_resp_bits_excp_0_gpf_instr          (io_itlb_0_resp_bits_excp_0_gpf_instr),
    .io_itlb_0_resp_bits_excp_0_pf_instr           (io_itlb_0_resp_bits_excp_0_pf_instr),
    .io_itlb_0_resp_bits_excp_0_af_instr           (io_itlb_0_resp_bits_excp_0_af_instr),
    .io_itlb_1_req_valid                           (io_itlb_1_req_valid),
    .io_itlb_1_req_bits_vaddr                      (io_itlb_1_req_bits_vaddr),
    .io_itlb_1_resp_bits_paddr_0                   (io_itlb_1_resp_bits_paddr_0),
    .io_itlb_1_resp_bits_gpaddr_0                  (io_itlb_1_resp_bits_gpaddr_0),
    .io_itlb_1_resp_bits_pbmt_0                    (io_itlb_1_resp_bits_pbmt_0),
    .io_itlb_1_resp_bits_miss                      (io_itlb_1_resp_bits_miss),
    .io_itlb_1_resp_bits_isForVSnonLeafPTE         (io_itlb_1_resp_bits_isForVSnonLeafPTE),
    .io_itlb_1_resp_bits_excp_0_gpf_instr          (io_itlb_1_resp_bits_excp_0_gpf_instr),
    .io_itlb_1_resp_bits_excp_0_pf_instr           (io_itlb_1_resp_bits_excp_0_pf_instr),
    .io_itlb_1_resp_bits_excp_0_af_instr           (io_itlb_1_resp_bits_excp_0_af_instr),
    .io_itlbFlushPipe                              (io_itlbFlushPipe),
    // 注意：prefetcher 用 pmp_2/3（mainPipe 用 pmp_0/1）
    .io_pmp_0_req_bits_addr                        (io_pmp_2_req_bits_addr),
    .io_pmp_0_resp_instr                           (io_pmp_2_resp_instr),
    .io_pmp_0_resp_mmio                            (io_pmp_2_resp_mmio),
    .io_pmp_1_req_bits_addr                        (io_pmp_3_req_bits_addr),
    .io_pmp_1_resp_instr                           (io_pmp_3_resp_instr),
    .io_pmp_1_resp_mmio                            (io_pmp_3_resp_mmio),
    .io_metaRead_toIMeta_ready                     (pf_metaRead_ready),
    .io_metaRead_toIMeta_valid                     (pf_metaRead_valid),
    .io_metaRead_toIMeta_bits_vSetIdx_0            (pf_metaRead_vSetIdx_0),
    .io_metaRead_toIMeta_bits_vSetIdx_1            (pf_metaRead_vSetIdx_1),
    .io_metaRead_toIMeta_bits_isDoubleLine         (pf_metaRead_isDoubleLine),
    .io_metaRead_fromIMeta_metas_0_0_tag           (ma_resp_metas_0_0_tag),
    .io_metaRead_fromIMeta_metas_0_1_tag           (ma_resp_metas_0_1_tag),
    .io_metaRead_fromIMeta_metas_0_2_tag           (ma_resp_metas_0_2_tag),
    .io_metaRead_fromIMeta_metas_0_3_tag           (ma_resp_metas_0_3_tag),
    .io_metaRead_fromIMeta_metas_1_0_tag           (ma_resp_metas_1_0_tag),
    .io_metaRead_fromIMeta_metas_1_1_tag           (ma_resp_metas_1_1_tag),
    .io_metaRead_fromIMeta_metas_1_2_tag           (ma_resp_metas_1_2_tag),
    .io_metaRead_fromIMeta_metas_1_3_tag           (ma_resp_metas_1_3_tag),
    .io_metaRead_fromIMeta_codes_0_0               (ma_resp_codes_0_0),
    .io_metaRead_fromIMeta_codes_0_1               (ma_resp_codes_0_1),
    .io_metaRead_fromIMeta_codes_0_2               (ma_resp_codes_0_2),
    .io_metaRead_fromIMeta_codes_0_3               (ma_resp_codes_0_3),
    .io_metaRead_fromIMeta_codes_1_0               (ma_resp_codes_1_0),
    .io_metaRead_fromIMeta_codes_1_1               (ma_resp_codes_1_1),
    .io_metaRead_fromIMeta_codes_1_2               (ma_resp_codes_1_2),
    .io_metaRead_fromIMeta_codes_1_3               (ma_resp_codes_1_3),
    .io_metaRead_fromIMeta_entryValid_0_0          (ma_resp_entryValid_0_0),
    .io_metaRead_fromIMeta_entryValid_0_1          (ma_resp_entryValid_0_1),
    .io_metaRead_fromIMeta_entryValid_0_2          (ma_resp_entryValid_0_2),
    .io_metaRead_fromIMeta_entryValid_0_3          (ma_resp_entryValid_0_3),
    .io_metaRead_fromIMeta_entryValid_1_0          (ma_resp_entryValid_1_0),
    .io_metaRead_fromIMeta_entryValid_1_1          (ma_resp_entryValid_1_1),
    .io_metaRead_fromIMeta_entryValid_1_2          (ma_resp_entryValid_1_2),
    .io_metaRead_fromIMeta_entryValid_1_3          (ma_resp_entryValid_1_3),
    .io_MSHRReq_ready                              (mu_prefetch_req_ready),
    .io_MSHRReq_valid                              (pf_mshr_valid),
    .io_MSHRReq_bits_blkPaddr                      (pf_mshr_blkPaddr),
    .io_MSHRReq_bits_vSetIdx                       (pf_mshr_vSetIdx),
    .io_MSHRResp_valid                             (mu_fetch_resp_valid),
    .io_MSHRResp_bits_blkPaddr                     (mu_fetch_resp_blkPaddr),
    .io_MSHRResp_bits_vSetIdx                      (mu_fetch_resp_vSetIdx),
    .io_MSHRResp_bits_waymask                      (mu_fetch_resp_waymask),
    .io_MSHRResp_bits_corrupt                      (mu_fetch_resp_corrupt),
    .io_wayLookupWrite_ready                       (wl_write_ready),
    .io_wayLookupWrite_valid                       (pf_wlw_valid),
    .io_wayLookupWrite_bits_entry_vSetIdx_0        (pf_wlw_vSetIdx_0),
    .io_wayLookupWrite_bits_entry_vSetIdx_1        (pf_wlw_vSetIdx_1),
    .io_wayLookupWrite_bits_entry_waymask_0        (pf_wlw_waymask_0),
    .io_wayLookupWrite_bits_entry_waymask_1        (pf_wlw_waymask_1),
    .io_wayLookupWrite_bits_entry_ptag_0           (pf_wlw_ptag_0),
    .io_wayLookupWrite_bits_entry_ptag_1           (pf_wlw_ptag_1),
    .io_wayLookupWrite_bits_entry_itlb_exception_0 (pf_wlw_itlb_exception_0),
    .io_wayLookupWrite_bits_entry_itlb_exception_1 (pf_wlw_itlb_exception_1),
    .io_wayLookupWrite_bits_entry_itlb_pbmt_0      (pf_wlw_itlb_pbmt_0),
    .io_wayLookupWrite_bits_entry_itlb_pbmt_1      (pf_wlw_itlb_pbmt_1),
    .io_wayLookupWrite_bits_entry_meta_codes_0     (pf_wlw_meta_codes_0),
    .io_wayLookupWrite_bits_entry_meta_codes_1     (pf_wlw_meta_codes_1),
    .io_wayLookupWrite_bits_gpf_gpaddr             (pf_wlw_gpf_gpaddr),
    .io_wayLookupWrite_bits_gpf_isForVSnonLeafPTE  (pf_wlw_gpf_isForVSnonLeafPTE)
  );

  // ---- WayLookup：命中信息 FIFO；prefetch 写入，mainpipe 读出，refill(update) 就地修正命中路 ----
  WayLookup wayLookup (
    .clock                                (clock),
    .reset                                (reset),
    .io_flush                             (io_flush),
    .io_read_ready                        (mp_wayLookupRead_ready),
    .io_read_valid                        (wl_read_valid),
    .io_read_bits_entry_vSetIdx_0         (wl_read_vSetIdx_0),
    .io_read_bits_entry_vSetIdx_1         (wl_read_vSetIdx_1),
    .io_read_bits_entry_waymask_0         (wl_read_waymask_0),
    .io_read_bits_entry_waymask_1         (wl_read_waymask_1),
    .io_read_bits_entry_ptag_0            (wl_read_ptag_0),
    .io_read_bits_entry_ptag_1            (wl_read_ptag_1),
    .io_read_bits_entry_itlb_exception_0  (wl_read_itlb_exception_0),
    .io_read_bits_entry_itlb_exception_1  (wl_read_itlb_exception_1),
    .io_read_bits_entry_itlb_pbmt_0       (wl_read_itlb_pbmt_0),
    .io_read_bits_entry_itlb_pbmt_1       (wl_read_itlb_pbmt_1),
    .io_read_bits_entry_meta_codes_0      (wl_read_meta_codes_0),
    .io_read_bits_entry_meta_codes_1      (wl_read_meta_codes_1),
    .io_read_bits_gpf_gpaddr              (wl_read_gpf_gpaddr),
    .io_read_bits_gpf_isForVSnonLeafPTE   (wl_read_gpf_isForVSnonLeafPTE),
    .io_write_ready                       (wl_write_ready),
    .io_write_valid                       (pf_wlw_valid),
    .io_write_bits_entry_vSetIdx_0        (pf_wlw_vSetIdx_0),
    .io_write_bits_entry_vSetIdx_1        (pf_wlw_vSetIdx_1),
    .io_write_bits_entry_waymask_0        (pf_wlw_waymask_0),
    .io_write_bits_entry_waymask_1        (pf_wlw_waymask_1),
    .io_write_bits_entry_ptag_0           (pf_wlw_ptag_0),
    .io_write_bits_entry_ptag_1           (pf_wlw_ptag_1),
    .io_write_bits_entry_itlb_exception_0 (pf_wlw_itlb_exception_0),
    .io_write_bits_entry_itlb_exception_1 (pf_wlw_itlb_exception_1),
    .io_write_bits_entry_itlb_pbmt_0      (pf_wlw_itlb_pbmt_0),
    .io_write_bits_entry_itlb_pbmt_1      (pf_wlw_itlb_pbmt_1),
    .io_write_bits_entry_meta_codes_0     (pf_wlw_meta_codes_0),
    .io_write_bits_entry_meta_codes_1     (pf_wlw_meta_codes_1),
    .io_write_bits_gpf_gpaddr             (pf_wlw_gpf_gpaddr),
    .io_write_bits_gpf_isForVSnonLeafPTE  (pf_wlw_gpf_isForVSnonLeafPTE),
    .io_update_valid                      (mu_fetch_resp_valid),
    .io_update_bits_blkPaddr              (mu_fetch_resp_blkPaddr),
    .io_update_bits_vSetIdx               (mu_fetch_resp_vSetIdx),
    .io_update_bits_waymask               (mu_fetch_resp_waymask),
    .io_update_bits_corrupt               (mu_fetch_resp_corrupt)
  );

endmodule
