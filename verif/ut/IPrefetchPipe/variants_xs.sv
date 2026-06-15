// =============================================================================
// IPrefetchPipe（wrapper）—— golden 同名扁平端口 ↔ xs_IPrefetchPipe 的数组/struct 端口
//
// 本层是「机械的端口适配层」：把可读核 xs_IPrefetchPipe 的 [PORT_NUM] 数组 / meta_way_t /
// way_lookup_entry_t / way_lookup_gpf_t 等聚合端口，拆/打包成 golden firtool 输出的扁平
// io_*_0/_1 标量端口。仅做信号搬运，无任何逻辑，故允许平铺。供 FM 等价比对与 ST 替换。
// =============================================================================
module IPrefetchPipe_xs
  import xs_iprefetch_pkg::*;
(
  input  clock,
  input  reset,
  input  io_csr_pf_enable,
  input  io_flush,
  output io_req_ready,
  input  io_req_valid,
  input  [49:0] io_req_bits_startAddr,
  input  [49:0] io_req_bits_nextlineStart,
  input  io_req_bits_ftqIdx_flag,
  input  [5:0] io_req_bits_ftqIdx_value,
  input  io_req_bits_isSoftPrefetch,
  input  [1:0] io_req_bits_backendException,
  input  io_flushFromBpu_s2_valid,
  input  io_flushFromBpu_s2_bits_flag,
  input  [5:0] io_flushFromBpu_s2_bits_value,
  input  io_flushFromBpu_s3_valid,
  input  io_flushFromBpu_s3_bits_flag,
  input  [5:0] io_flushFromBpu_s3_bits_value,
  output io_itlb_0_req_valid,
  output [49:0] io_itlb_0_req_bits_vaddr,
  input  [47:0] io_itlb_0_resp_bits_paddr_0,
  input  [63:0] io_itlb_0_resp_bits_gpaddr_0,
  input  [1:0] io_itlb_0_resp_bits_pbmt_0,
  input  io_itlb_0_resp_bits_miss,
  input  io_itlb_0_resp_bits_isForVSnonLeafPTE,
  input  io_itlb_0_resp_bits_excp_0_gpf_instr,
  input  io_itlb_0_resp_bits_excp_0_pf_instr,
  input  io_itlb_0_resp_bits_excp_0_af_instr,
  output io_itlb_1_req_valid,
  output [49:0] io_itlb_1_req_bits_vaddr,
  input  [47:0] io_itlb_1_resp_bits_paddr_0,
  input  [63:0] io_itlb_1_resp_bits_gpaddr_0,
  input  [1:0] io_itlb_1_resp_bits_pbmt_0,
  input  io_itlb_1_resp_bits_miss,
  input  io_itlb_1_resp_bits_isForVSnonLeafPTE,
  input  io_itlb_1_resp_bits_excp_0_gpf_instr,
  input  io_itlb_1_resp_bits_excp_0_pf_instr,
  input  io_itlb_1_resp_bits_excp_0_af_instr,
  output io_itlbFlushPipe,
  output [47:0] io_pmp_0_req_bits_addr,
  input  io_pmp_0_resp_instr,
  input  io_pmp_0_resp_mmio,
  output [47:0] io_pmp_1_req_bits_addr,
  input  io_pmp_1_resp_instr,
  input  io_pmp_1_resp_mmio,
  input  io_metaRead_toIMeta_ready,
  output io_metaRead_toIMeta_valid,
  output [7:0] io_metaRead_toIMeta_bits_vSetIdx_0,
  output [7:0] io_metaRead_toIMeta_bits_vSetIdx_1,
  output io_metaRead_toIMeta_bits_isDoubleLine,
  input  [35:0] io_metaRead_fromIMeta_metas_0_0_tag,
  input  [35:0] io_metaRead_fromIMeta_metas_0_1_tag,
  input  [35:0] io_metaRead_fromIMeta_metas_0_2_tag,
  input  [35:0] io_metaRead_fromIMeta_metas_0_3_tag,
  input  [35:0] io_metaRead_fromIMeta_metas_1_0_tag,
  input  [35:0] io_metaRead_fromIMeta_metas_1_1_tag,
  input  [35:0] io_metaRead_fromIMeta_metas_1_2_tag,
  input  [35:0] io_metaRead_fromIMeta_metas_1_3_tag,
  input  io_metaRead_fromIMeta_codes_0_0,
  input  io_metaRead_fromIMeta_codes_0_1,
  input  io_metaRead_fromIMeta_codes_0_2,
  input  io_metaRead_fromIMeta_codes_0_3,
  input  io_metaRead_fromIMeta_codes_1_0,
  input  io_metaRead_fromIMeta_codes_1_1,
  input  io_metaRead_fromIMeta_codes_1_2,
  input  io_metaRead_fromIMeta_codes_1_3,
  input  io_metaRead_fromIMeta_entryValid_0_0,
  input  io_metaRead_fromIMeta_entryValid_0_1,
  input  io_metaRead_fromIMeta_entryValid_0_2,
  input  io_metaRead_fromIMeta_entryValid_0_3,
  input  io_metaRead_fromIMeta_entryValid_1_0,
  input  io_metaRead_fromIMeta_entryValid_1_1,
  input  io_metaRead_fromIMeta_entryValid_1_2,
  input  io_metaRead_fromIMeta_entryValid_1_3,
  input  io_MSHRReq_ready,
  output io_MSHRReq_valid,
  output [41:0] io_MSHRReq_bits_blkPaddr,
  output [7:0] io_MSHRReq_bits_vSetIdx,
  input  io_MSHRResp_valid,
  input  [41:0] io_MSHRResp_bits_blkPaddr,
  input  [7:0] io_MSHRResp_bits_vSetIdx,
  input  [3:0] io_MSHRResp_bits_waymask,
  input  io_MSHRResp_bits_corrupt,
  input  io_wayLookupWrite_ready,
  output io_wayLookupWrite_valid,
  output [7:0] io_wayLookupWrite_bits_entry_vSetIdx_0,
  output [7:0] io_wayLookupWrite_bits_entry_vSetIdx_1,
  output [3:0] io_wayLookupWrite_bits_entry_waymask_0,
  output [3:0] io_wayLookupWrite_bits_entry_waymask_1,
  output [35:0] io_wayLookupWrite_bits_entry_ptag_0,
  output [35:0] io_wayLookupWrite_bits_entry_ptag_1,
  output [1:0] io_wayLookupWrite_bits_entry_itlb_exception_0,
  output [1:0] io_wayLookupWrite_bits_entry_itlb_exception_1,
  output [1:0] io_wayLookupWrite_bits_entry_itlb_pbmt_0,
  output [1:0] io_wayLookupWrite_bits_entry_itlb_pbmt_1,
  output io_wayLookupWrite_bits_entry_meta_codes_0,
  output io_wayLookupWrite_bits_entry_meta_codes_1,
  output [55:0] io_wayLookupWrite_bits_gpf_gpaddr,
  output io_wayLookupWrite_bits_gpf_isForVSnonLeafPTE
);
  // ---- flat → 数组（输入侧）----
  logic [xs_iprefetch_pkg::PADDR_W-1:0] itlb_paddr   [xs_iprefetch_pkg::PORT_NUM];
  logic [63:0]                          itlb_gpaddr  [xs_iprefetch_pkg::PORT_NUM];
  logic [xs_iprefetch_pkg::PBMT_W-1:0]  itlb_pbmt    [xs_iprefetch_pkg::PORT_NUM];
  logic                                 itlb_miss    [xs_iprefetch_pkg::PORT_NUM];
  logic                                 itlb_isForVS [xs_iprefetch_pkg::PORT_NUM];
  logic                                 itlb_gpf     [xs_iprefetch_pkg::PORT_NUM];
  logic                                 itlb_pf      [xs_iprefetch_pkg::PORT_NUM];
  logic                                 itlb_af      [xs_iprefetch_pkg::PORT_NUM];
  assign itlb_paddr[0]   = io_itlb_0_resp_bits_paddr_0;          assign itlb_paddr[1]   = io_itlb_1_resp_bits_paddr_0;
  assign itlb_gpaddr[0]  = io_itlb_0_resp_bits_gpaddr_0;         assign itlb_gpaddr[1]  = io_itlb_1_resp_bits_gpaddr_0;
  assign itlb_pbmt[0]    = io_itlb_0_resp_bits_pbmt_0;           assign itlb_pbmt[1]    = io_itlb_1_resp_bits_pbmt_0;
  assign itlb_miss[0]    = io_itlb_0_resp_bits_miss;             assign itlb_miss[1]    = io_itlb_1_resp_bits_miss;
  assign itlb_isForVS[0] = io_itlb_0_resp_bits_isForVSnonLeafPTE;assign itlb_isForVS[1] = io_itlb_1_resp_bits_isForVSnonLeafPTE;
  assign itlb_gpf[0]     = io_itlb_0_resp_bits_excp_0_gpf_instr; assign itlb_gpf[1]     = io_itlb_1_resp_bits_excp_0_gpf_instr;
  assign itlb_pf[0]      = io_itlb_0_resp_bits_excp_0_pf_instr;  assign itlb_pf[1]      = io_itlb_1_resp_bits_excp_0_pf_instr;
  assign itlb_af[0]      = io_itlb_0_resp_bits_excp_0_af_instr;  assign itlb_af[1]      = io_itlb_1_resp_bits_excp_0_af_instr;

  logic pmp_instr [xs_iprefetch_pkg::PORT_NUM];
  logic pmp_mmio  [xs_iprefetch_pkg::PORT_NUM];
  assign pmp_instr[0] = io_pmp_0_resp_instr;  assign pmp_instr[1] = io_pmp_1_resp_instr;
  assign pmp_mmio[0]  = io_pmp_0_resp_mmio;   assign pmp_mmio[1]  = io_pmp_1_resp_mmio;

  // meta SRAM 返回：[port][way] 的 tag/code/entry_valid 打包进 meta_way_t
  xs_iprefetch_pkg::meta_way_t meta [xs_iprefetch_pkg::PORT_NUM][xs_iprefetch_pkg::N_WAYS];
  assign meta[0][0] = '{tag: io_metaRead_fromIMeta_metas_0_0_tag, code: io_metaRead_fromIMeta_codes_0_0, entry_valid: io_metaRead_fromIMeta_entryValid_0_0};
  assign meta[0][1] = '{tag: io_metaRead_fromIMeta_metas_0_1_tag, code: io_metaRead_fromIMeta_codes_0_1, entry_valid: io_metaRead_fromIMeta_entryValid_0_1};
  assign meta[0][2] = '{tag: io_metaRead_fromIMeta_metas_0_2_tag, code: io_metaRead_fromIMeta_codes_0_2, entry_valid: io_metaRead_fromIMeta_entryValid_0_2};
  assign meta[0][3] = '{tag: io_metaRead_fromIMeta_metas_0_3_tag, code: io_metaRead_fromIMeta_codes_0_3, entry_valid: io_metaRead_fromIMeta_entryValid_0_3};
  assign meta[1][0] = '{tag: io_metaRead_fromIMeta_metas_1_0_tag, code: io_metaRead_fromIMeta_codes_1_0, entry_valid: io_metaRead_fromIMeta_entryValid_1_0};
  assign meta[1][1] = '{tag: io_metaRead_fromIMeta_metas_1_1_tag, code: io_metaRead_fromIMeta_codes_1_1, entry_valid: io_metaRead_fromIMeta_entryValid_1_1};
  assign meta[1][2] = '{tag: io_metaRead_fromIMeta_metas_1_2_tag, code: io_metaRead_fromIMeta_codes_1_2, entry_valid: io_metaRead_fromIMeta_entryValid_1_2};
  assign meta[1][3] = '{tag: io_metaRead_fromIMeta_metas_1_3_tag, code: io_metaRead_fromIMeta_codes_1_3, entry_valid: io_metaRead_fromIMeta_entryValid_1_3};

  // ---- 输出侧数组 / struct ----
  logic                                 itlb_req_valid [xs_iprefetch_pkg::PORT_NUM];
  logic [xs_iprefetch_pkg::VADDR_W-1:0] itlb_req_vaddr [xs_iprefetch_pkg::PORT_NUM];
  logic [xs_iprefetch_pkg::PADDR_W-1:0] pmp_addr       [xs_iprefetch_pkg::PORT_NUM];
  logic [xs_iprefetch_pkg::IDX_W-1:0]   meta_vSetIdx   [xs_iprefetch_pkg::PORT_NUM];
  xs_iprefetch_pkg::way_lookup_entry_t  wl_entry;
  xs_iprefetch_pkg::way_lookup_gpf_t    wl_gpf;

  xs_IPrefetchPipe u_core (
    .clock(clock), .reset(reset),
    .io_csr_pf_enable(io_csr_pf_enable), .io_flush(io_flush),
    .io_req_valid(io_req_valid), .io_req_ready(io_req_ready),
    .io_req_bits_startAddr(io_req_bits_startAddr),
    .io_req_bits_nextlineStart(io_req_bits_nextlineStart),
    .io_req_bits_ftqIdx_flag(io_req_bits_ftqIdx_flag),
    .io_req_bits_ftqIdx_value(io_req_bits_ftqIdx_value),
    .io_req_bits_isSoftPrefetch(io_req_bits_isSoftPrefetch),
    .io_req_bits_backendException(io_req_bits_backendException),
    .io_flushFromBpu_s2_valid(io_flushFromBpu_s2_valid),
    .io_flushFromBpu_s2_bits_flag(io_flushFromBpu_s2_bits_flag),
    .io_flushFromBpu_s2_bits_value(io_flushFromBpu_s2_bits_value),
    .io_flushFromBpu_s3_valid(io_flushFromBpu_s3_valid),
    .io_flushFromBpu_s3_bits_flag(io_flushFromBpu_s3_bits_flag),
    .io_flushFromBpu_s3_bits_value(io_flushFromBpu_s3_bits_value),
    .io_itlb_req_valid(itlb_req_valid),
    .io_itlb_req_bits_vaddr(itlb_req_vaddr),
    .io_itlb_resp_bits_paddr(itlb_paddr),
    .io_itlb_resp_bits_gpaddr(itlb_gpaddr),
    .io_itlb_resp_bits_pbmt(itlb_pbmt),
    .io_itlb_resp_bits_miss(itlb_miss),
    .io_itlb_resp_bits_isForVSnonLeafPTE(itlb_isForVS),
    .io_itlb_resp_bits_excp_gpf(itlb_gpf),
    .io_itlb_resp_bits_excp_pf(itlb_pf),
    .io_itlb_resp_bits_excp_af(itlb_af),
    .io_itlbFlushPipe(io_itlbFlushPipe),
    .io_pmp_req_bits_addr(pmp_addr),
    .io_pmp_resp_instr(pmp_instr),
    .io_pmp_resp_mmio(pmp_mmio),
    .io_metaRead_toIMeta_ready(io_metaRead_toIMeta_ready),
    .io_metaRead_toIMeta_valid(io_metaRead_toIMeta_valid),
    .io_metaRead_toIMeta_bits_vSetIdx(meta_vSetIdx),
    .io_metaRead_toIMeta_bits_isDoubleLine(io_metaRead_toIMeta_bits_isDoubleLine),
    .io_metaRead_fromIMeta(meta),
    .io_MSHRReq_ready(io_MSHRReq_ready),
    .io_MSHRReq_valid(io_MSHRReq_valid),
    .io_MSHRReq_bits_blkPaddr(io_MSHRReq_bits_blkPaddr),
    .io_MSHRReq_bits_vSetIdx(io_MSHRReq_bits_vSetIdx),
    .io_MSHRResp_valid(io_MSHRResp_valid),
    .io_MSHRResp_bits_blkPaddr(io_MSHRResp_bits_blkPaddr),
    .io_MSHRResp_bits_vSetIdx(io_MSHRResp_bits_vSetIdx),
    .io_MSHRResp_bits_waymask(io_MSHRResp_bits_waymask),
    .io_MSHRResp_bits_corrupt(io_MSHRResp_bits_corrupt),
    .io_wayLookupWrite_ready(io_wayLookupWrite_ready),
    .io_wayLookupWrite_valid(io_wayLookupWrite_valid),
    .io_wayLookupWrite_bits_entry(wl_entry),
    .io_wayLookupWrite_bits_gpf(wl_gpf)
  );

  // ---- 数组 / struct → flat（输出侧）----
  assign io_itlb_0_req_valid      = itlb_req_valid[0];
  assign io_itlb_1_req_valid      = itlb_req_valid[1];
  assign io_itlb_0_req_bits_vaddr = itlb_req_vaddr[0];
  assign io_itlb_1_req_bits_vaddr = itlb_req_vaddr[1];
  assign io_pmp_0_req_bits_addr   = pmp_addr[0];
  assign io_pmp_1_req_bits_addr   = pmp_addr[1];
  assign io_metaRead_toIMeta_bits_vSetIdx_0 = meta_vSetIdx[0];
  assign io_metaRead_toIMeta_bits_vSetIdx_1 = meta_vSetIdx[1];

  assign io_wayLookupWrite_bits_entry_vSetIdx_0        = wl_entry.port[0].vSetIdx;
  assign io_wayLookupWrite_bits_entry_vSetIdx_1        = wl_entry.port[1].vSetIdx;
  assign io_wayLookupWrite_bits_entry_waymask_0        = wl_entry.port[0].waymask;
  assign io_wayLookupWrite_bits_entry_waymask_1        = wl_entry.port[1].waymask;
  assign io_wayLookupWrite_bits_entry_ptag_0           = wl_entry.port[0].ptag;
  assign io_wayLookupWrite_bits_entry_ptag_1           = wl_entry.port[1].ptag;
  assign io_wayLookupWrite_bits_entry_itlb_exception_0 = wl_entry.port[0].itlb_exception;
  assign io_wayLookupWrite_bits_entry_itlb_exception_1 = wl_entry.port[1].itlb_exception;
  assign io_wayLookupWrite_bits_entry_itlb_pbmt_0      = wl_entry.port[0].itlb_pbmt;
  assign io_wayLookupWrite_bits_entry_itlb_pbmt_1      = wl_entry.port[1].itlb_pbmt;
  assign io_wayLookupWrite_bits_entry_meta_codes_0     = wl_entry.port[0].meta_codes;
  assign io_wayLookupWrite_bits_entry_meta_codes_1     = wl_entry.port[1].meta_codes;
  assign io_wayLookupWrite_bits_gpf_gpaddr             = wl_gpf.gpaddr;
  assign io_wayLookupWrite_bits_gpf_isForVSnonLeafPTE  = wl_gpf.isForVSnonLeafPTE;
endmodule
