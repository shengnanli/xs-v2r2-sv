// =============================================================================
// ICacheMainPipe_xs —— UT 用变体（与 wrapper 同，仅模块名改为 ICacheMainPipe_xs）
//
// 纯机械的端口适配层：把 firtool 风格的展平标量端口打包成可读核的 struct/数组，
// 再把可读核输出拆回展平端口。允许平铺，不含逻辑（除直连组合）。
//
// 说明：
//  · data SRAM 有 partWayNum(=4) 个读端口。golden 中 toIData_1/2/3 只输出 valid+vSetIdx，
//    且这些 vSetIdx 直接取自各自 pcMemRead_i——不经流水，故在 wrapper 里就地驱动；
//    可读核只负责 toIData_0（带 waymask/blkOffset）的 bits 与全部端口的 valid。
//  · wayLookupRead 用 {entry, gpf} 结构（与 WayLookup 模块输出一致）。
// =============================================================================
module ICacheMainPipe_xs
  import xs_icache_mainpipe_pkg::*;
(
  input          clock,
  input          reset,
  // data SRAM read ports
  output         io_dataArray_toIData_0_valid,
  output [7:0]   io_dataArray_toIData_0_bits_vSetIdx_0,
  output [7:0]   io_dataArray_toIData_0_bits_vSetIdx_1,
  output         io_dataArray_toIData_0_bits_waymask_0_0,
  output         io_dataArray_toIData_0_bits_waymask_0_1,
  output         io_dataArray_toIData_0_bits_waymask_0_2,
  output         io_dataArray_toIData_0_bits_waymask_0_3,
  output         io_dataArray_toIData_0_bits_waymask_1_0,
  output         io_dataArray_toIData_0_bits_waymask_1_1,
  output         io_dataArray_toIData_0_bits_waymask_1_2,
  output         io_dataArray_toIData_0_bits_waymask_1_3,
  output [5:0]   io_dataArray_toIData_0_bits_blkOffset,
  output         io_dataArray_toIData_1_valid,
  output [7:0]   io_dataArray_toIData_1_bits_vSetIdx_0,
  output [7:0]   io_dataArray_toIData_1_bits_vSetIdx_1,
  output         io_dataArray_toIData_2_valid,
  output [7:0]   io_dataArray_toIData_2_bits_vSetIdx_0,
  output [7:0]   io_dataArray_toIData_2_bits_vSetIdx_1,
  input          io_dataArray_toIData_3_ready,
  output         io_dataArray_toIData_3_valid,
  output [7:0]   io_dataArray_toIData_3_bits_vSetIdx_0,
  output [7:0]   io_dataArray_toIData_3_bits_vSetIdx_1,
  input  [63:0]  io_dataArray_fromIData_datas_0,
  input  [63:0]  io_dataArray_fromIData_datas_1,
  input  [63:0]  io_dataArray_fromIData_datas_2,
  input  [63:0]  io_dataArray_fromIData_datas_3,
  input  [63:0]  io_dataArray_fromIData_datas_4,
  input  [63:0]  io_dataArray_fromIData_datas_5,
  input  [63:0]  io_dataArray_fromIData_datas_6,
  input  [63:0]  io_dataArray_fromIData_datas_7,
  input          io_dataArray_fromIData_codes_0,
  input          io_dataArray_fromIData_codes_1,
  input          io_dataArray_fromIData_codes_2,
  input          io_dataArray_fromIData_codes_3,
  input          io_dataArray_fromIData_codes_4,
  input          io_dataArray_fromIData_codes_5,
  input          io_dataArray_fromIData_codes_6,
  input          io_dataArray_fromIData_codes_7,
  // metaArray flush
  output         io_metaArrayFlush_0_valid,
  output [7:0]   io_metaArrayFlush_0_bits_virIdx,
  output [3:0]   io_metaArrayFlush_0_bits_waymask,
  output         io_metaArrayFlush_1_valid,
  output [7:0]   io_metaArrayFlush_1_bits_virIdx,
  output [3:0]   io_metaArrayFlush_1_bits_waymask,
  // touch
  output         io_touch_0_valid,
  output [7:0]   io_touch_0_bits_vSetIdx,
  output [1:0]   io_touch_0_bits_way,
  output         io_touch_1_valid,
  output [7:0]   io_touch_1_bits_vSetIdx,
  output [1:0]   io_touch_1_bits_way,
  // wayLookup read
  output         io_wayLookupRead_ready,
  input          io_wayLookupRead_valid,
  input  [7:0]   io_wayLookupRead_bits_entry_vSetIdx_0,
  input  [7:0]   io_wayLookupRead_bits_entry_vSetIdx_1,
  input  [3:0]   io_wayLookupRead_bits_entry_waymask_0,
  input  [3:0]   io_wayLookupRead_bits_entry_waymask_1,
  input  [35:0]  io_wayLookupRead_bits_entry_ptag_0,
  input  [35:0]  io_wayLookupRead_bits_entry_ptag_1,
  input  [1:0]   io_wayLookupRead_bits_entry_itlb_exception_0,
  input  [1:0]   io_wayLookupRead_bits_entry_itlb_exception_1,
  input  [1:0]   io_wayLookupRead_bits_entry_itlb_pbmt_0,
  input  [1:0]   io_wayLookupRead_bits_entry_itlb_pbmt_1,
  input          io_wayLookupRead_bits_entry_meta_codes_0,
  input          io_wayLookupRead_bits_entry_meta_codes_1,
  input  [55:0]  io_wayLookupRead_bits_gpf_gpaddr,
  input          io_wayLookupRead_bits_gpf_isForVSnonLeafPTE,
  // MSHR
  input          io_mshr_req_ready,
  output         io_mshr_req_valid,
  output [41:0]  io_mshr_req_bits_blkPaddr,
  output [7:0]   io_mshr_req_bits_vSetIdx,
  input          io_mshr_resp_valid,
  input  [41:0]  io_mshr_resp_bits_blkPaddr,
  input  [7:0]   io_mshr_resp_bits_vSetIdx,
  input  [511:0] io_mshr_resp_bits_data,
  input          io_mshr_resp_bits_corrupt,
  input          io_ecc_enable,
  // FTQ
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
  // IFU resp
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
  input          io_flush,
  // PMP
  output [47:0]  io_pmp_0_req_bits_addr,
  input          io_pmp_0_resp_instr,
  input          io_pmp_0_resp_mmio,
  output [47:0]  io_pmp_1_req_bits_addr,
  input          io_pmp_1_resp_instr,
  input          io_pmp_1_resp_mmio,
  input          io_respStall,
  // errors
  output         io_errors_0_valid,
  output [47:0]  io_errors_0_bits_paddr,
  output         io_errors_0_bits_report_to_beu,
  output         io_errors_1_valid,
  output [47:0]  io_errors_1_bits_paddr,
  output         io_errors_1_bits_report_to_beu,
  // perf
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
  output         io_perfInfo_hit
);

  // ---- flat → struct（FTQ pcMemRead 数组 / readValid）----
  ftq_pc_read_t [N_FTQ_PORT-1:0] pcMemRead;
  logic [N_FTQ_PORT-1:0]         readValid;
  assign pcMemRead[0].startAddr     = io_fetch_req_bits_pcMemRead_0_startAddr;
  assign pcMemRead[0].nextlineStart = io_fetch_req_bits_pcMemRead_0_nextlineStart;
  assign pcMemRead[1].startAddr     = io_fetch_req_bits_pcMemRead_1_startAddr;
  assign pcMemRead[1].nextlineStart = io_fetch_req_bits_pcMemRead_1_nextlineStart;
  assign pcMemRead[2].startAddr     = io_fetch_req_bits_pcMemRead_2_startAddr;
  assign pcMemRead[2].nextlineStart = io_fetch_req_bits_pcMemRead_2_nextlineStart;
  assign pcMemRead[3].startAddr     = io_fetch_req_bits_pcMemRead_3_startAddr;
  assign pcMemRead[3].nextlineStart = io_fetch_req_bits_pcMemRead_3_nextlineStart;
  assign pcMemRead[4].startAddr     = io_fetch_req_bits_pcMemRead_4_startAddr;
  assign pcMemRead[4].nextlineStart = io_fetch_req_bits_pcMemRead_4_nextlineStart;
  assign readValid = {io_fetch_req_bits_readValid_4, io_fetch_req_bits_readValid_3,
                      io_fetch_req_bits_readValid_2, io_fetch_req_bits_readValid_1,
                      io_fetch_req_bits_readValid_0};

  // ---- flat → struct（wayLookup）----
  way_lookup_entry_t wl_entry;
  way_lookup_gpf_t   wl_gpf;
  assign wl_entry.port[0].vSetIdx        = io_wayLookupRead_bits_entry_vSetIdx_0;
  assign wl_entry.port[0].waymask        = io_wayLookupRead_bits_entry_waymask_0;
  assign wl_entry.port[0].ptag           = io_wayLookupRead_bits_entry_ptag_0;
  assign wl_entry.port[0].itlb_exception = io_wayLookupRead_bits_entry_itlb_exception_0;
  assign wl_entry.port[0].itlb_pbmt      = io_wayLookupRead_bits_entry_itlb_pbmt_0;
  assign wl_entry.port[0].meta_codes     = io_wayLookupRead_bits_entry_meta_codes_0;
  assign wl_entry.port[1].vSetIdx        = io_wayLookupRead_bits_entry_vSetIdx_1;
  assign wl_entry.port[1].waymask        = io_wayLookupRead_bits_entry_waymask_1;
  assign wl_entry.port[1].ptag           = io_wayLookupRead_bits_entry_ptag_1;
  assign wl_entry.port[1].itlb_exception = io_wayLookupRead_bits_entry_itlb_exception_1;
  assign wl_entry.port[1].itlb_pbmt      = io_wayLookupRead_bits_entry_itlb_pbmt_1;
  assign wl_entry.port[1].meta_codes     = io_wayLookupRead_bits_entry_meta_codes_1;
  assign wl_gpf.gpaddr            = io_wayLookupRead_bits_gpf_gpaddr;
  assign wl_gpf.isForVSnonLeafPTE = io_wayLookupRead_bits_gpf_isForVSnonLeafPTE;

  // ---- flat → array（data SRAM 回读）----
  logic [7:0][63:0] fromData_datas;
  logic [7:0]       fromData_codes;
  assign fromData_datas = {io_dataArray_fromIData_datas_7, io_dataArray_fromIData_datas_6,
                           io_dataArray_fromIData_datas_5, io_dataArray_fromIData_datas_4,
                           io_dataArray_fromIData_datas_3, io_dataArray_fromIData_datas_2,
                           io_dataArray_fromIData_datas_1, io_dataArray_fromIData_datas_0};
  assign fromData_codes = {io_dataArray_fromIData_codes_7, io_dataArray_fromIData_codes_6,
                           io_dataArray_fromIData_codes_5, io_dataArray_fromIData_codes_4,
                           io_dataArray_fromIData_codes_3, io_dataArray_fromIData_codes_2,
                           io_dataArray_fromIData_codes_1, io_dataArray_fromIData_codes_0};

  logic [1:0][47:0] pmp_req_addr;
  logic [1:0]       pmp_resp_instr;
  logic [1:0]       pmp_resp_mmio;
  assign pmp_resp_instr = {io_pmp_1_resp_instr, io_pmp_0_resp_instr};
  assign pmp_resp_mmio  = {io_pmp_1_resp_mmio,  io_pmp_0_resp_mmio};

  // ---- core 输出 struct/array ----
  logic [3:0]            toData_valid;
  data_sram_req_t        toData_bits;
  logic [1:0]            metaFlush_valid;
  meta_flush_t [1:0]     metaFlush_bits;
  logic [1:0]            touch_valid;
  touch_t [1:0]          touch_bits;
  ifu_resp_t             fetch_resp_bits;
  logic [1:0]            errors_valid;
  l1_error_t [1:0]       errors_bits;
  perf_info_t            perfInfo;

  xs_ICacheMainPipe u_core (
    .clock(clock), .reset(reset),
    .toData_valid(toData_valid), .toData_bits(toData_bits),
    .toData_last_ready(io_dataArray_toIData_3_ready),
    .fromData_datas(fromData_datas), .fromData_codes(fromData_codes),
    .metaFlush_valid(metaFlush_valid), .metaFlush_bits(metaFlush_bits),
    .touch_valid(touch_valid), .touch_bits(touch_bits),
    .wayLookup_ready(io_wayLookupRead_ready), .wayLookup_valid(io_wayLookupRead_valid),
    .wayLookup_entry(wl_entry), .wayLookup_gpf(wl_gpf),
    .mshr_req_ready(io_mshr_req_ready), .mshr_req_valid(io_mshr_req_valid),
    .mshr_req_blkPaddr(io_mshr_req_bits_blkPaddr), .mshr_req_vSetIdx(io_mshr_req_bits_vSetIdx),
    .mshr_resp_valid(io_mshr_resp_valid), .mshr_resp_blkPaddr(io_mshr_resp_bits_blkPaddr),
    .mshr_resp_vSetIdx(io_mshr_resp_bits_vSetIdx), .mshr_resp_data(io_mshr_resp_bits_data),
    .mshr_resp_corrupt(io_mshr_resp_bits_corrupt),
    .ecc_enable(io_ecc_enable),
    .fetch_req_ready(io_fetch_req_ready), .fetch_req_valid(io_fetch_req_valid),
    .fetch_req_pcMemRead(pcMemRead), .fetch_req_readValid(readValid),
    .fetch_req_backendException(io_fetch_req_bits_backendException),
    .fetch_resp_valid(io_fetch_resp_valid), .fetch_resp_bits(fetch_resp_bits),
    .fetch_topdownIcacheMiss(io_fetch_topdownIcacheMiss),
    .fetch_topdownItlbMiss(io_fetch_topdownItlbMiss),
    .io_flush(io_flush),
    .pmp_req_addr(pmp_req_addr), .pmp_resp_instr(pmp_resp_instr), .pmp_resp_mmio(pmp_resp_mmio),
    .io_respStall(io_respStall),
    .errors_valid(errors_valid), .errors_bits(errors_bits),
    .perfInfo(perfInfo)
  );

  // ---- struct/array → flat（data SRAM 读请求）----
  // toIData_0 带完整 bits；toIData_1/2/3 只输出 valid + vSetIdx（直接来自各 pcMemRead_i）。
  assign io_dataArray_toIData_0_valid = toData_valid[0];
  assign io_dataArray_toIData_0_bits_vSetIdx_0 = toData_bits.vSetIdx[0];
  assign io_dataArray_toIData_0_bits_vSetIdx_1 = toData_bits.vSetIdx[1];
  assign io_dataArray_toIData_0_bits_waymask_0_0 = toData_bits.waymask[0][0];
  assign io_dataArray_toIData_0_bits_waymask_0_1 = toData_bits.waymask[0][1];
  assign io_dataArray_toIData_0_bits_waymask_0_2 = toData_bits.waymask[0][2];
  assign io_dataArray_toIData_0_bits_waymask_0_3 = toData_bits.waymask[0][3];
  assign io_dataArray_toIData_0_bits_waymask_1_0 = toData_bits.waymask[1][0];
  assign io_dataArray_toIData_0_bits_waymask_1_1 = toData_bits.waymask[1][1];
  assign io_dataArray_toIData_0_bits_waymask_1_2 = toData_bits.waymask[1][2];
  assign io_dataArray_toIData_0_bits_waymask_1_3 = toData_bits.waymask[1][3];
  assign io_dataArray_toIData_0_bits_blkOffset = toData_bits.blkOffset;
  assign io_dataArray_toIData_1_valid = readValid[1];
  assign io_dataArray_toIData_1_bits_vSetIdx_0 = pcMemRead[1].startAddr[13:6];
  assign io_dataArray_toIData_1_bits_vSetIdx_1 = pcMemRead[1].nextlineStart[13:6];
  assign io_dataArray_toIData_2_valid = readValid[2];
  assign io_dataArray_toIData_2_bits_vSetIdx_0 = pcMemRead[2].startAddr[13:6];
  assign io_dataArray_toIData_2_bits_vSetIdx_1 = pcMemRead[2].nextlineStart[13:6];
  assign io_dataArray_toIData_3_valid = readValid[3];
  assign io_dataArray_toIData_3_bits_vSetIdx_0 = pcMemRead[3].startAddr[13:6];
  assign io_dataArray_toIData_3_bits_vSetIdx_1 = pcMemRead[3].nextlineStart[13:6];

  // ---- metaArray flush ----
  assign io_metaArrayFlush_0_valid        = metaFlush_valid[0];
  assign io_metaArrayFlush_0_bits_virIdx  = metaFlush_bits[0].virIdx;
  assign io_metaArrayFlush_0_bits_waymask = metaFlush_bits[0].waymask;
  assign io_metaArrayFlush_1_valid        = metaFlush_valid[1];
  assign io_metaArrayFlush_1_bits_virIdx  = metaFlush_bits[1].virIdx;
  assign io_metaArrayFlush_1_bits_waymask = metaFlush_bits[1].waymask;

  // ---- touch ----
  assign io_touch_0_valid        = touch_valid[0];
  assign io_touch_0_bits_vSetIdx = touch_bits[0].vSetIdx;
  assign io_touch_0_bits_way     = touch_bits[0].way;
  assign io_touch_1_valid        = touch_valid[1];
  assign io_touch_1_bits_vSetIdx = touch_bits[1].vSetIdx;
  assign io_touch_1_bits_way     = touch_bits[1].way;

  // ---- PMP ----
  assign io_pmp_0_req_bits_addr = pmp_req_addr[0];
  assign io_pmp_1_req_bits_addr = pmp_req_addr[1];

  // ---- IFU resp ----
  assign io_fetch_resp_bits_doubleline       = fetch_resp_bits.doubleline;
  assign io_fetch_resp_bits_vaddr_0          = fetch_resp_bits.vaddr[0];
  assign io_fetch_resp_bits_vaddr_1          = fetch_resp_bits.vaddr[1];
  assign io_fetch_resp_bits_data             = fetch_resp_bits.data;
  assign io_fetch_resp_bits_paddr_0          = fetch_resp_bits.paddr[0];
  assign io_fetch_resp_bits_exception_0      = fetch_resp_bits.exception[0];
  assign io_fetch_resp_bits_exception_1      = fetch_resp_bits.exception[1];
  assign io_fetch_resp_bits_pmp_mmio_0       = fetch_resp_bits.pmp_mmio[0];
  assign io_fetch_resp_bits_pmp_mmio_1       = fetch_resp_bits.pmp_mmio[1];
  assign io_fetch_resp_bits_itlb_pbmt_0      = fetch_resp_bits.itlb_pbmt[0];
  assign io_fetch_resp_bits_itlb_pbmt_1      = fetch_resp_bits.itlb_pbmt[1];
  assign io_fetch_resp_bits_backendException = fetch_resp_bits.backendException;
  assign io_fetch_resp_bits_gpaddr           = fetch_resp_bits.gpaddr;
  assign io_fetch_resp_bits_isForVSnonLeafPTE= fetch_resp_bits.isForVSnonLeafPTE;

  // ---- errors ----
  assign io_errors_0_valid              = errors_valid[0];
  assign io_errors_0_bits_paddr         = errors_bits[0].paddr;
  assign io_errors_0_bits_report_to_beu = errors_bits[0].report_to_beu;
  assign io_errors_1_valid              = errors_valid[1];
  assign io_errors_1_bits_paddr         = errors_bits[1].paddr;
  assign io_errors_1_bits_report_to_beu = errors_bits[1].report_to_beu;

  // ---- perf ----
  assign io_perfInfo_only_0_hit      = perfInfo.only_0_hit;
  assign io_perfInfo_only_0_miss     = perfInfo.only_0_miss;
  assign io_perfInfo_hit_0_hit_1     = perfInfo.hit_0_hit_1;
  assign io_perfInfo_hit_0_miss_1    = perfInfo.hit_0_miss_1;
  assign io_perfInfo_miss_0_hit_1    = perfInfo.miss_0_hit_1;
  assign io_perfInfo_miss_0_miss_1   = perfInfo.miss_0_miss_1;
  assign io_perfInfo_hit_0_except_1  = perfInfo.hit_0_except_1;
  assign io_perfInfo_miss_0_except_1 = perfInfo.miss_0_except_1;
  assign io_perfInfo_except_0        = perfInfo.except_0;
  assign io_perfInfo_bank_hit_0      = perfInfo.bank_hit[0];
  assign io_perfInfo_bank_hit_1      = perfInfo.bank_hit[1];
  assign io_perfInfo_hit             = perfInfo.hit;

endmodule
