// 自动生成：scripts/gen_iprefetchpipe.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 80000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_csr_pf_enable;
  logic io_flush;
  logic io_req_valid;
  logic [49:0] io_req_bits_startAddr;
  logic [49:0] io_req_bits_nextlineStart;
  logic io_req_bits_ftqIdx_flag;
  logic [5:0] io_req_bits_ftqIdx_value;
  logic io_req_bits_isSoftPrefetch;
  logic [1:0] io_req_bits_backendException;
  logic io_flushFromBpu_s2_valid;
  logic io_flushFromBpu_s2_bits_flag;
  logic [5:0] io_flushFromBpu_s2_bits_value;
  logic io_flushFromBpu_s3_valid;
  logic io_flushFromBpu_s3_bits_flag;
  logic [5:0] io_flushFromBpu_s3_bits_value;
  logic [47:0] io_itlb_0_resp_bits_paddr_0;
  logic [63:0] io_itlb_0_resp_bits_gpaddr_0;
  logic [1:0] io_itlb_0_resp_bits_pbmt_0;
  logic io_itlb_0_resp_bits_miss;
  logic io_itlb_0_resp_bits_isForVSnonLeafPTE;
  logic io_itlb_0_resp_bits_excp_0_gpf_instr;
  logic io_itlb_0_resp_bits_excp_0_pf_instr;
  logic io_itlb_0_resp_bits_excp_0_af_instr;
  logic [47:0] io_itlb_1_resp_bits_paddr_0;
  logic [63:0] io_itlb_1_resp_bits_gpaddr_0;
  logic [1:0] io_itlb_1_resp_bits_pbmt_0;
  logic io_itlb_1_resp_bits_miss;
  logic io_itlb_1_resp_bits_isForVSnonLeafPTE;
  logic io_itlb_1_resp_bits_excp_0_gpf_instr;
  logic io_itlb_1_resp_bits_excp_0_pf_instr;
  logic io_itlb_1_resp_bits_excp_0_af_instr;
  logic io_pmp_0_resp_instr;
  logic io_pmp_0_resp_mmio;
  logic io_pmp_1_resp_instr;
  logic io_pmp_1_resp_mmio;
  logic io_metaRead_toIMeta_ready;
  logic [35:0] io_metaRead_fromIMeta_metas_0_0_tag;
  logic [35:0] io_metaRead_fromIMeta_metas_0_1_tag;
  logic [35:0] io_metaRead_fromIMeta_metas_0_2_tag;
  logic [35:0] io_metaRead_fromIMeta_metas_0_3_tag;
  logic [35:0] io_metaRead_fromIMeta_metas_1_0_tag;
  logic [35:0] io_metaRead_fromIMeta_metas_1_1_tag;
  logic [35:0] io_metaRead_fromIMeta_metas_1_2_tag;
  logic [35:0] io_metaRead_fromIMeta_metas_1_3_tag;
  logic io_metaRead_fromIMeta_codes_0_0;
  logic io_metaRead_fromIMeta_codes_0_1;
  logic io_metaRead_fromIMeta_codes_0_2;
  logic io_metaRead_fromIMeta_codes_0_3;
  logic io_metaRead_fromIMeta_codes_1_0;
  logic io_metaRead_fromIMeta_codes_1_1;
  logic io_metaRead_fromIMeta_codes_1_2;
  logic io_metaRead_fromIMeta_codes_1_3;
  logic io_metaRead_fromIMeta_entryValid_0_0;
  logic io_metaRead_fromIMeta_entryValid_0_1;
  logic io_metaRead_fromIMeta_entryValid_0_2;
  logic io_metaRead_fromIMeta_entryValid_0_3;
  logic io_metaRead_fromIMeta_entryValid_1_0;
  logic io_metaRead_fromIMeta_entryValid_1_1;
  logic io_metaRead_fromIMeta_entryValid_1_2;
  logic io_metaRead_fromIMeta_entryValid_1_3;
  logic io_MSHRReq_ready;
  logic io_MSHRResp_valid;
  logic [41:0] io_MSHRResp_bits_blkPaddr;
  logic [7:0] io_MSHRResp_bits_vSetIdx;
  logic [3:0] io_MSHRResp_bits_waymask;
  logic io_MSHRResp_bits_corrupt;
  logic io_wayLookupWrite_ready;
  wire g_io_req_ready;
  wire i_io_req_ready;
  wire g_io_itlb_0_req_valid;
  wire i_io_itlb_0_req_valid;
  wire [49:0] g_io_itlb_0_req_bits_vaddr;
  wire [49:0] i_io_itlb_0_req_bits_vaddr;
  wire g_io_itlb_1_req_valid;
  wire i_io_itlb_1_req_valid;
  wire [49:0] g_io_itlb_1_req_bits_vaddr;
  wire [49:0] i_io_itlb_1_req_bits_vaddr;
  wire g_io_itlbFlushPipe;
  wire i_io_itlbFlushPipe;
  wire [47:0] g_io_pmp_0_req_bits_addr;
  wire [47:0] i_io_pmp_0_req_bits_addr;
  wire [47:0] g_io_pmp_1_req_bits_addr;
  wire [47:0] i_io_pmp_1_req_bits_addr;
  wire g_io_metaRead_toIMeta_valid;
  wire i_io_metaRead_toIMeta_valid;
  wire [7:0] g_io_metaRead_toIMeta_bits_vSetIdx_0;
  wire [7:0] i_io_metaRead_toIMeta_bits_vSetIdx_0;
  wire [7:0] g_io_metaRead_toIMeta_bits_vSetIdx_1;
  wire [7:0] i_io_metaRead_toIMeta_bits_vSetIdx_1;
  wire g_io_metaRead_toIMeta_bits_isDoubleLine;
  wire i_io_metaRead_toIMeta_bits_isDoubleLine;
  wire g_io_MSHRReq_valid;
  wire i_io_MSHRReq_valid;
  wire [41:0] g_io_MSHRReq_bits_blkPaddr;
  wire [41:0] i_io_MSHRReq_bits_blkPaddr;
  wire [7:0] g_io_MSHRReq_bits_vSetIdx;
  wire [7:0] i_io_MSHRReq_bits_vSetIdx;
  wire g_io_wayLookupWrite_valid;
  wire i_io_wayLookupWrite_valid;
  wire [7:0] g_io_wayLookupWrite_bits_entry_vSetIdx_0;
  wire [7:0] i_io_wayLookupWrite_bits_entry_vSetIdx_0;
  wire [7:0] g_io_wayLookupWrite_bits_entry_vSetIdx_1;
  wire [7:0] i_io_wayLookupWrite_bits_entry_vSetIdx_1;
  wire [3:0] g_io_wayLookupWrite_bits_entry_waymask_0;
  wire [3:0] i_io_wayLookupWrite_bits_entry_waymask_0;
  wire [3:0] g_io_wayLookupWrite_bits_entry_waymask_1;
  wire [3:0] i_io_wayLookupWrite_bits_entry_waymask_1;
  wire [35:0] g_io_wayLookupWrite_bits_entry_ptag_0;
  wire [35:0] i_io_wayLookupWrite_bits_entry_ptag_0;
  wire [35:0] g_io_wayLookupWrite_bits_entry_ptag_1;
  wire [35:0] i_io_wayLookupWrite_bits_entry_ptag_1;
  wire [1:0] g_io_wayLookupWrite_bits_entry_itlb_exception_0;
  wire [1:0] i_io_wayLookupWrite_bits_entry_itlb_exception_0;
  wire [1:0] g_io_wayLookupWrite_bits_entry_itlb_exception_1;
  wire [1:0] i_io_wayLookupWrite_bits_entry_itlb_exception_1;
  wire [1:0] g_io_wayLookupWrite_bits_entry_itlb_pbmt_0;
  wire [1:0] i_io_wayLookupWrite_bits_entry_itlb_pbmt_0;
  wire [1:0] g_io_wayLookupWrite_bits_entry_itlb_pbmt_1;
  wire [1:0] i_io_wayLookupWrite_bits_entry_itlb_pbmt_1;
  wire g_io_wayLookupWrite_bits_entry_meta_codes_0;
  wire i_io_wayLookupWrite_bits_entry_meta_codes_0;
  wire g_io_wayLookupWrite_bits_entry_meta_codes_1;
  wire i_io_wayLookupWrite_bits_entry_meta_codes_1;
  wire [55:0] g_io_wayLookupWrite_bits_gpf_gpaddr;
  wire [55:0] i_io_wayLookupWrite_bits_gpf_gpaddr;
  wire g_io_wayLookupWrite_bits_gpf_isForVSnonLeafPTE;
  wire i_io_wayLookupWrite_bits_gpf_isForVSnonLeafPTE;
  IPrefetchPipe    u_g (.clock(clk), .reset(rst), .io_csr_pf_enable(io_csr_pf_enable), .io_flush(io_flush), .io_req_valid(io_req_valid), .io_req_bits_startAddr(io_req_bits_startAddr), .io_req_bits_nextlineStart(io_req_bits_nextlineStart), .io_req_bits_ftqIdx_flag(io_req_bits_ftqIdx_flag), .io_req_bits_ftqIdx_value(io_req_bits_ftqIdx_value), .io_req_bits_isSoftPrefetch(io_req_bits_isSoftPrefetch), .io_req_bits_backendException(io_req_bits_backendException), .io_flushFromBpu_s2_valid(io_flushFromBpu_s2_valid), .io_flushFromBpu_s2_bits_flag(io_flushFromBpu_s2_bits_flag), .io_flushFromBpu_s2_bits_value(io_flushFromBpu_s2_bits_value), .io_flushFromBpu_s3_valid(io_flushFromBpu_s3_valid), .io_flushFromBpu_s3_bits_flag(io_flushFromBpu_s3_bits_flag), .io_flushFromBpu_s3_bits_value(io_flushFromBpu_s3_bits_value), .io_itlb_0_resp_bits_paddr_0(io_itlb_0_resp_bits_paddr_0), .io_itlb_0_resp_bits_gpaddr_0(io_itlb_0_resp_bits_gpaddr_0), .io_itlb_0_resp_bits_pbmt_0(io_itlb_0_resp_bits_pbmt_0), .io_itlb_0_resp_bits_miss(io_itlb_0_resp_bits_miss), .io_itlb_0_resp_bits_isForVSnonLeafPTE(io_itlb_0_resp_bits_isForVSnonLeafPTE), .io_itlb_0_resp_bits_excp_0_gpf_instr(io_itlb_0_resp_bits_excp_0_gpf_instr), .io_itlb_0_resp_bits_excp_0_pf_instr(io_itlb_0_resp_bits_excp_0_pf_instr), .io_itlb_0_resp_bits_excp_0_af_instr(io_itlb_0_resp_bits_excp_0_af_instr), .io_itlb_1_resp_bits_paddr_0(io_itlb_1_resp_bits_paddr_0), .io_itlb_1_resp_bits_gpaddr_0(io_itlb_1_resp_bits_gpaddr_0), .io_itlb_1_resp_bits_pbmt_0(io_itlb_1_resp_bits_pbmt_0), .io_itlb_1_resp_bits_miss(io_itlb_1_resp_bits_miss), .io_itlb_1_resp_bits_isForVSnonLeafPTE(io_itlb_1_resp_bits_isForVSnonLeafPTE), .io_itlb_1_resp_bits_excp_0_gpf_instr(io_itlb_1_resp_bits_excp_0_gpf_instr), .io_itlb_1_resp_bits_excp_0_pf_instr(io_itlb_1_resp_bits_excp_0_pf_instr), .io_itlb_1_resp_bits_excp_0_af_instr(io_itlb_1_resp_bits_excp_0_af_instr), .io_pmp_0_resp_instr(io_pmp_0_resp_instr), .io_pmp_0_resp_mmio(io_pmp_0_resp_mmio), .io_pmp_1_resp_instr(io_pmp_1_resp_instr), .io_pmp_1_resp_mmio(io_pmp_1_resp_mmio), .io_metaRead_toIMeta_ready(io_metaRead_toIMeta_ready), .io_metaRead_fromIMeta_metas_0_0_tag(io_metaRead_fromIMeta_metas_0_0_tag), .io_metaRead_fromIMeta_metas_0_1_tag(io_metaRead_fromIMeta_metas_0_1_tag), .io_metaRead_fromIMeta_metas_0_2_tag(io_metaRead_fromIMeta_metas_0_2_tag), .io_metaRead_fromIMeta_metas_0_3_tag(io_metaRead_fromIMeta_metas_0_3_tag), .io_metaRead_fromIMeta_metas_1_0_tag(io_metaRead_fromIMeta_metas_1_0_tag), .io_metaRead_fromIMeta_metas_1_1_tag(io_metaRead_fromIMeta_metas_1_1_tag), .io_metaRead_fromIMeta_metas_1_2_tag(io_metaRead_fromIMeta_metas_1_2_tag), .io_metaRead_fromIMeta_metas_1_3_tag(io_metaRead_fromIMeta_metas_1_3_tag), .io_metaRead_fromIMeta_codes_0_0(io_metaRead_fromIMeta_codes_0_0), .io_metaRead_fromIMeta_codes_0_1(io_metaRead_fromIMeta_codes_0_1), .io_metaRead_fromIMeta_codes_0_2(io_metaRead_fromIMeta_codes_0_2), .io_metaRead_fromIMeta_codes_0_3(io_metaRead_fromIMeta_codes_0_3), .io_metaRead_fromIMeta_codes_1_0(io_metaRead_fromIMeta_codes_1_0), .io_metaRead_fromIMeta_codes_1_1(io_metaRead_fromIMeta_codes_1_1), .io_metaRead_fromIMeta_codes_1_2(io_metaRead_fromIMeta_codes_1_2), .io_metaRead_fromIMeta_codes_1_3(io_metaRead_fromIMeta_codes_1_3), .io_metaRead_fromIMeta_entryValid_0_0(io_metaRead_fromIMeta_entryValid_0_0), .io_metaRead_fromIMeta_entryValid_0_1(io_metaRead_fromIMeta_entryValid_0_1), .io_metaRead_fromIMeta_entryValid_0_2(io_metaRead_fromIMeta_entryValid_0_2), .io_metaRead_fromIMeta_entryValid_0_3(io_metaRead_fromIMeta_entryValid_0_3), .io_metaRead_fromIMeta_entryValid_1_0(io_metaRead_fromIMeta_entryValid_1_0), .io_metaRead_fromIMeta_entryValid_1_1(io_metaRead_fromIMeta_entryValid_1_1), .io_metaRead_fromIMeta_entryValid_1_2(io_metaRead_fromIMeta_entryValid_1_2), .io_metaRead_fromIMeta_entryValid_1_3(io_metaRead_fromIMeta_entryValid_1_3), .io_MSHRReq_ready(io_MSHRReq_ready), .io_MSHRResp_valid(io_MSHRResp_valid), .io_MSHRResp_bits_blkPaddr(io_MSHRResp_bits_blkPaddr), .io_MSHRResp_bits_vSetIdx(io_MSHRResp_bits_vSetIdx), .io_MSHRResp_bits_waymask(io_MSHRResp_bits_waymask), .io_MSHRResp_bits_corrupt(io_MSHRResp_bits_corrupt), .io_wayLookupWrite_ready(io_wayLookupWrite_ready), .io_req_ready(g_io_req_ready), .io_itlb_0_req_valid(g_io_itlb_0_req_valid), .io_itlb_0_req_bits_vaddr(g_io_itlb_0_req_bits_vaddr), .io_itlb_1_req_valid(g_io_itlb_1_req_valid), .io_itlb_1_req_bits_vaddr(g_io_itlb_1_req_bits_vaddr), .io_itlbFlushPipe(g_io_itlbFlushPipe), .io_pmp_0_req_bits_addr(g_io_pmp_0_req_bits_addr), .io_pmp_1_req_bits_addr(g_io_pmp_1_req_bits_addr), .io_metaRead_toIMeta_valid(g_io_metaRead_toIMeta_valid), .io_metaRead_toIMeta_bits_vSetIdx_0(g_io_metaRead_toIMeta_bits_vSetIdx_0), .io_metaRead_toIMeta_bits_vSetIdx_1(g_io_metaRead_toIMeta_bits_vSetIdx_1), .io_metaRead_toIMeta_bits_isDoubleLine(g_io_metaRead_toIMeta_bits_isDoubleLine), .io_MSHRReq_valid(g_io_MSHRReq_valid), .io_MSHRReq_bits_blkPaddr(g_io_MSHRReq_bits_blkPaddr), .io_MSHRReq_bits_vSetIdx(g_io_MSHRReq_bits_vSetIdx), .io_wayLookupWrite_valid(g_io_wayLookupWrite_valid), .io_wayLookupWrite_bits_entry_vSetIdx_0(g_io_wayLookupWrite_bits_entry_vSetIdx_0), .io_wayLookupWrite_bits_entry_vSetIdx_1(g_io_wayLookupWrite_bits_entry_vSetIdx_1), .io_wayLookupWrite_bits_entry_waymask_0(g_io_wayLookupWrite_bits_entry_waymask_0), .io_wayLookupWrite_bits_entry_waymask_1(g_io_wayLookupWrite_bits_entry_waymask_1), .io_wayLookupWrite_bits_entry_ptag_0(g_io_wayLookupWrite_bits_entry_ptag_0), .io_wayLookupWrite_bits_entry_ptag_1(g_io_wayLookupWrite_bits_entry_ptag_1), .io_wayLookupWrite_bits_entry_itlb_exception_0(g_io_wayLookupWrite_bits_entry_itlb_exception_0), .io_wayLookupWrite_bits_entry_itlb_exception_1(g_io_wayLookupWrite_bits_entry_itlb_exception_1), .io_wayLookupWrite_bits_entry_itlb_pbmt_0(g_io_wayLookupWrite_bits_entry_itlb_pbmt_0), .io_wayLookupWrite_bits_entry_itlb_pbmt_1(g_io_wayLookupWrite_bits_entry_itlb_pbmt_1), .io_wayLookupWrite_bits_entry_meta_codes_0(g_io_wayLookupWrite_bits_entry_meta_codes_0), .io_wayLookupWrite_bits_entry_meta_codes_1(g_io_wayLookupWrite_bits_entry_meta_codes_1), .io_wayLookupWrite_bits_gpf_gpaddr(g_io_wayLookupWrite_bits_gpf_gpaddr), .io_wayLookupWrite_bits_gpf_isForVSnonLeafPTE(g_io_wayLookupWrite_bits_gpf_isForVSnonLeafPTE));
  IPrefetchPipe_xs u_i (.clock(clk), .reset(rst), .io_csr_pf_enable(io_csr_pf_enable), .io_flush(io_flush), .io_req_valid(io_req_valid), .io_req_bits_startAddr(io_req_bits_startAddr), .io_req_bits_nextlineStart(io_req_bits_nextlineStart), .io_req_bits_ftqIdx_flag(io_req_bits_ftqIdx_flag), .io_req_bits_ftqIdx_value(io_req_bits_ftqIdx_value), .io_req_bits_isSoftPrefetch(io_req_bits_isSoftPrefetch), .io_req_bits_backendException(io_req_bits_backendException), .io_flushFromBpu_s2_valid(io_flushFromBpu_s2_valid), .io_flushFromBpu_s2_bits_flag(io_flushFromBpu_s2_bits_flag), .io_flushFromBpu_s2_bits_value(io_flushFromBpu_s2_bits_value), .io_flushFromBpu_s3_valid(io_flushFromBpu_s3_valid), .io_flushFromBpu_s3_bits_flag(io_flushFromBpu_s3_bits_flag), .io_flushFromBpu_s3_bits_value(io_flushFromBpu_s3_bits_value), .io_itlb_0_resp_bits_paddr_0(io_itlb_0_resp_bits_paddr_0), .io_itlb_0_resp_bits_gpaddr_0(io_itlb_0_resp_bits_gpaddr_0), .io_itlb_0_resp_bits_pbmt_0(io_itlb_0_resp_bits_pbmt_0), .io_itlb_0_resp_bits_miss(io_itlb_0_resp_bits_miss), .io_itlb_0_resp_bits_isForVSnonLeafPTE(io_itlb_0_resp_bits_isForVSnonLeafPTE), .io_itlb_0_resp_bits_excp_0_gpf_instr(io_itlb_0_resp_bits_excp_0_gpf_instr), .io_itlb_0_resp_bits_excp_0_pf_instr(io_itlb_0_resp_bits_excp_0_pf_instr), .io_itlb_0_resp_bits_excp_0_af_instr(io_itlb_0_resp_bits_excp_0_af_instr), .io_itlb_1_resp_bits_paddr_0(io_itlb_1_resp_bits_paddr_0), .io_itlb_1_resp_bits_gpaddr_0(io_itlb_1_resp_bits_gpaddr_0), .io_itlb_1_resp_bits_pbmt_0(io_itlb_1_resp_bits_pbmt_0), .io_itlb_1_resp_bits_miss(io_itlb_1_resp_bits_miss), .io_itlb_1_resp_bits_isForVSnonLeafPTE(io_itlb_1_resp_bits_isForVSnonLeafPTE), .io_itlb_1_resp_bits_excp_0_gpf_instr(io_itlb_1_resp_bits_excp_0_gpf_instr), .io_itlb_1_resp_bits_excp_0_pf_instr(io_itlb_1_resp_bits_excp_0_pf_instr), .io_itlb_1_resp_bits_excp_0_af_instr(io_itlb_1_resp_bits_excp_0_af_instr), .io_pmp_0_resp_instr(io_pmp_0_resp_instr), .io_pmp_0_resp_mmio(io_pmp_0_resp_mmio), .io_pmp_1_resp_instr(io_pmp_1_resp_instr), .io_pmp_1_resp_mmio(io_pmp_1_resp_mmio), .io_metaRead_toIMeta_ready(io_metaRead_toIMeta_ready), .io_metaRead_fromIMeta_metas_0_0_tag(io_metaRead_fromIMeta_metas_0_0_tag), .io_metaRead_fromIMeta_metas_0_1_tag(io_metaRead_fromIMeta_metas_0_1_tag), .io_metaRead_fromIMeta_metas_0_2_tag(io_metaRead_fromIMeta_metas_0_2_tag), .io_metaRead_fromIMeta_metas_0_3_tag(io_metaRead_fromIMeta_metas_0_3_tag), .io_metaRead_fromIMeta_metas_1_0_tag(io_metaRead_fromIMeta_metas_1_0_tag), .io_metaRead_fromIMeta_metas_1_1_tag(io_metaRead_fromIMeta_metas_1_1_tag), .io_metaRead_fromIMeta_metas_1_2_tag(io_metaRead_fromIMeta_metas_1_2_tag), .io_metaRead_fromIMeta_metas_1_3_tag(io_metaRead_fromIMeta_metas_1_3_tag), .io_metaRead_fromIMeta_codes_0_0(io_metaRead_fromIMeta_codes_0_0), .io_metaRead_fromIMeta_codes_0_1(io_metaRead_fromIMeta_codes_0_1), .io_metaRead_fromIMeta_codes_0_2(io_metaRead_fromIMeta_codes_0_2), .io_metaRead_fromIMeta_codes_0_3(io_metaRead_fromIMeta_codes_0_3), .io_metaRead_fromIMeta_codes_1_0(io_metaRead_fromIMeta_codes_1_0), .io_metaRead_fromIMeta_codes_1_1(io_metaRead_fromIMeta_codes_1_1), .io_metaRead_fromIMeta_codes_1_2(io_metaRead_fromIMeta_codes_1_2), .io_metaRead_fromIMeta_codes_1_3(io_metaRead_fromIMeta_codes_1_3), .io_metaRead_fromIMeta_entryValid_0_0(io_metaRead_fromIMeta_entryValid_0_0), .io_metaRead_fromIMeta_entryValid_0_1(io_metaRead_fromIMeta_entryValid_0_1), .io_metaRead_fromIMeta_entryValid_0_2(io_metaRead_fromIMeta_entryValid_0_2), .io_metaRead_fromIMeta_entryValid_0_3(io_metaRead_fromIMeta_entryValid_0_3), .io_metaRead_fromIMeta_entryValid_1_0(io_metaRead_fromIMeta_entryValid_1_0), .io_metaRead_fromIMeta_entryValid_1_1(io_metaRead_fromIMeta_entryValid_1_1), .io_metaRead_fromIMeta_entryValid_1_2(io_metaRead_fromIMeta_entryValid_1_2), .io_metaRead_fromIMeta_entryValid_1_3(io_metaRead_fromIMeta_entryValid_1_3), .io_MSHRReq_ready(io_MSHRReq_ready), .io_MSHRResp_valid(io_MSHRResp_valid), .io_MSHRResp_bits_blkPaddr(io_MSHRResp_bits_blkPaddr), .io_MSHRResp_bits_vSetIdx(io_MSHRResp_bits_vSetIdx), .io_MSHRResp_bits_waymask(io_MSHRResp_bits_waymask), .io_MSHRResp_bits_corrupt(io_MSHRResp_bits_corrupt), .io_wayLookupWrite_ready(io_wayLookupWrite_ready), .io_req_ready(i_io_req_ready), .io_itlb_0_req_valid(i_io_itlb_0_req_valid), .io_itlb_0_req_bits_vaddr(i_io_itlb_0_req_bits_vaddr), .io_itlb_1_req_valid(i_io_itlb_1_req_valid), .io_itlb_1_req_bits_vaddr(i_io_itlb_1_req_bits_vaddr), .io_itlbFlushPipe(i_io_itlbFlushPipe), .io_pmp_0_req_bits_addr(i_io_pmp_0_req_bits_addr), .io_pmp_1_req_bits_addr(i_io_pmp_1_req_bits_addr), .io_metaRead_toIMeta_valid(i_io_metaRead_toIMeta_valid), .io_metaRead_toIMeta_bits_vSetIdx_0(i_io_metaRead_toIMeta_bits_vSetIdx_0), .io_metaRead_toIMeta_bits_vSetIdx_1(i_io_metaRead_toIMeta_bits_vSetIdx_1), .io_metaRead_toIMeta_bits_isDoubleLine(i_io_metaRead_toIMeta_bits_isDoubleLine), .io_MSHRReq_valid(i_io_MSHRReq_valid), .io_MSHRReq_bits_blkPaddr(i_io_MSHRReq_bits_blkPaddr), .io_MSHRReq_bits_vSetIdx(i_io_MSHRReq_bits_vSetIdx), .io_wayLookupWrite_valid(i_io_wayLookupWrite_valid), .io_wayLookupWrite_bits_entry_vSetIdx_0(i_io_wayLookupWrite_bits_entry_vSetIdx_0), .io_wayLookupWrite_bits_entry_vSetIdx_1(i_io_wayLookupWrite_bits_entry_vSetIdx_1), .io_wayLookupWrite_bits_entry_waymask_0(i_io_wayLookupWrite_bits_entry_waymask_0), .io_wayLookupWrite_bits_entry_waymask_1(i_io_wayLookupWrite_bits_entry_waymask_1), .io_wayLookupWrite_bits_entry_ptag_0(i_io_wayLookupWrite_bits_entry_ptag_0), .io_wayLookupWrite_bits_entry_ptag_1(i_io_wayLookupWrite_bits_entry_ptag_1), .io_wayLookupWrite_bits_entry_itlb_exception_0(i_io_wayLookupWrite_bits_entry_itlb_exception_0), .io_wayLookupWrite_bits_entry_itlb_exception_1(i_io_wayLookupWrite_bits_entry_itlb_exception_1), .io_wayLookupWrite_bits_entry_itlb_pbmt_0(i_io_wayLookupWrite_bits_entry_itlb_pbmt_0), .io_wayLookupWrite_bits_entry_itlb_pbmt_1(i_io_wayLookupWrite_bits_entry_itlb_pbmt_1), .io_wayLookupWrite_bits_entry_meta_codes_0(i_io_wayLookupWrite_bits_entry_meta_codes_0), .io_wayLookupWrite_bits_entry_meta_codes_1(i_io_wayLookupWrite_bits_entry_meta_codes_1), .io_wayLookupWrite_bits_gpf_gpaddr(i_io_wayLookupWrite_bits_gpf_gpaddr), .io_wayLookupWrite_bits_gpf_isForVSnonLeafPTE(i_io_wayLookupWrite_bits_gpf_isForVSnonLeafPTE));
  always @(negedge clk) begin
    if (rst) begin
      io_req_valid <= 1'b0;
      io_flush <= 1'b0;
      io_MSHRResp_valid <= 1'b0;
      io_flushFromBpu_s2_valid <= 1'b0;
      io_flushFromBpu_s3_valid <= 1'b0;
    end else begin
      io_csr_pf_enable <= ($urandom_range(0,3)!=0);
      io_flush <= ($urandom_range(0,31)==0);
      io_req_valid <= ($urandom_range(0,2)!=0);
      io_req_bits_ftqIdx_flag <= $urandom_range(0,1);
      io_req_bits_isSoftPrefetch <= $urandom_range(0,1);
      io_req_bits_backendException <= 2'($urandom_range(0,3));
      io_flushFromBpu_s2_valid <= ($urandom_range(0,15)==0);
      io_flushFromBpu_s2_bits_flag <= $urandom_range(0,1);
      io_flushFromBpu_s2_bits_value <= 6'($urandom);
      io_flushFromBpu_s3_valid <= ($urandom_range(0,15)==0);
      io_flushFromBpu_s3_bits_flag <= $urandom_range(0,1);
      io_flushFromBpu_s3_bits_value <= 6'($urandom);
      io_itlb_0_resp_bits_paddr_0 <= {36'($urandom_range(0,7)), 12'($urandom)};
      io_itlb_0_resp_bits_gpaddr_0 <= 64'({$urandom(), $urandom()});
      io_itlb_0_resp_bits_pbmt_0 <= 2'($urandom_range(0,3));
      io_itlb_0_resp_bits_miss <= ($urandom_range(0,2)==0);
      io_itlb_0_resp_bits_isForVSnonLeafPTE <= $urandom_range(0,1);
      io_itlb_1_resp_bits_paddr_0 <= {36'($urandom_range(0,7)), 12'($urandom)};
      io_itlb_1_resp_bits_gpaddr_0 <= 64'({$urandom(), $urandom()});
      io_itlb_1_resp_bits_pbmt_0 <= 2'($urandom_range(0,3));
      io_itlb_1_resp_bits_miss <= ($urandom_range(0,2)==0);
      io_itlb_1_resp_bits_isForVSnonLeafPTE <= $urandom_range(0,1);
      io_pmp_0_resp_instr <= $urandom_range(0,1);
      io_pmp_0_resp_mmio <= $urandom_range(0,1);
      io_pmp_1_resp_instr <= $urandom_range(0,1);
      io_pmp_1_resp_mmio <= $urandom_range(0,1);
      io_metaRead_toIMeta_ready <= ($urandom_range(0,2)!=0);
      io_metaRead_fromIMeta_metas_0_0_tag <= 36'($urandom_range(0,7));
      io_metaRead_fromIMeta_metas_0_1_tag <= 36'($urandom_range(0,7));
      io_metaRead_fromIMeta_metas_0_2_tag <= 36'($urandom_range(0,7));
      io_metaRead_fromIMeta_metas_0_3_tag <= 36'($urandom_range(0,7));
      io_metaRead_fromIMeta_metas_1_0_tag <= 36'($urandom_range(0,7));
      io_metaRead_fromIMeta_metas_1_1_tag <= 36'($urandom_range(0,7));
      io_metaRead_fromIMeta_metas_1_2_tag <= 36'($urandom_range(0,7));
      io_metaRead_fromIMeta_metas_1_3_tag <= 36'($urandom_range(0,7));
      io_metaRead_fromIMeta_codes_0_0 <= $urandom_range(0,1);
      io_metaRead_fromIMeta_codes_0_1 <= $urandom_range(0,1);
      io_metaRead_fromIMeta_codes_0_2 <= $urandom_range(0,1);
      io_metaRead_fromIMeta_codes_0_3 <= $urandom_range(0,1);
      io_metaRead_fromIMeta_codes_1_0 <= $urandom_range(0,1);
      io_metaRead_fromIMeta_codes_1_1 <= $urandom_range(0,1);
      io_metaRead_fromIMeta_codes_1_2 <= $urandom_range(0,1);
      io_metaRead_fromIMeta_codes_1_3 <= $urandom_range(0,1);
      io_metaRead_fromIMeta_entryValid_0_0 <= $urandom_range(0,1);
      io_metaRead_fromIMeta_entryValid_0_1 <= $urandom_range(0,1);
      io_metaRead_fromIMeta_entryValid_0_2 <= $urandom_range(0,1);
      io_metaRead_fromIMeta_entryValid_0_3 <= $urandom_range(0,1);
      io_metaRead_fromIMeta_entryValid_1_0 <= $urandom_range(0,1);
      io_metaRead_fromIMeta_entryValid_1_1 <= $urandom_range(0,1);
      io_metaRead_fromIMeta_entryValid_1_2 <= $urandom_range(0,1);
      io_metaRead_fromIMeta_entryValid_1_3 <= $urandom_range(0,1);
      io_MSHRReq_ready <= ($urandom_range(0,2)!=0);
      io_MSHRResp_valid <= ($urandom_range(0,3)==0);
      io_MSHRResp_bits_blkPaddr <= {36'($urandom_range(0,7)), 6'($urandom)};
      io_MSHRResp_bits_vSetIdx <= 8'($urandom_range(0,15));
      io_MSHRResp_bits_waymask <= 4'($urandom_range(0,15));
      io_MSHRResp_bits_corrupt <= $urandom_range(0,1);
      io_wayLookupWrite_ready <= ($urandom_range(0,2)!=0);
      io_req_bits_startAddr <= {44'($urandom_range(0,7)), 6'($urandom)};
      io_req_bits_nextlineStart <= {44'($urandom_range(0,7)), 6'($urandom)};
      io_req_bits_ftqIdx_value <= 6'($urandom);
      begin int oh; oh = $urandom_range(0,3);
        io_itlb_0_resp_bits_excp_0_pf_instr  <= (oh==1);
        io_itlb_0_resp_bits_excp_0_gpf_instr <= (oh==2);
        io_itlb_0_resp_bits_excp_0_af_instr  <= (oh==3); end
      begin int oh; oh = $urandom_range(0,3);
        io_itlb_1_resp_bits_excp_0_pf_instr  <= (oh==1);
        io_itlb_1_resp_bits_excp_0_gpf_instr <= (oh==2);
        io_itlb_1_resp_bits_excp_0_af_instr  <= (oh==3); end
    end
  end
  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (g_io_req_ready !== i_io_req_ready) begin errors++;
      if(errors<=40) $display("[%0t] io_req_ready g=%h i=%h", $time, g_io_req_ready, i_io_req_ready); end
    if (g_io_itlb_0_req_valid !== i_io_itlb_0_req_valid) begin errors++;
      if(errors<=40) $display("[%0t] io_itlb_0_req_valid g=%h i=%h", $time, g_io_itlb_0_req_valid, i_io_itlb_0_req_valid); end
    if (g_io_itlb_0_req_bits_vaddr !== i_io_itlb_0_req_bits_vaddr) begin errors++;
      if(errors<=40) $display("[%0t] io_itlb_0_req_bits_vaddr g=%h i=%h", $time, g_io_itlb_0_req_bits_vaddr, i_io_itlb_0_req_bits_vaddr); end
    if (g_io_itlb_1_req_valid !== i_io_itlb_1_req_valid) begin errors++;
      if(errors<=40) $display("[%0t] io_itlb_1_req_valid g=%h i=%h", $time, g_io_itlb_1_req_valid, i_io_itlb_1_req_valid); end
    if (g_io_itlb_1_req_bits_vaddr !== i_io_itlb_1_req_bits_vaddr) begin errors++;
      if(errors<=40) $display("[%0t] io_itlb_1_req_bits_vaddr g=%h i=%h", $time, g_io_itlb_1_req_bits_vaddr, i_io_itlb_1_req_bits_vaddr); end
    if (g_io_itlbFlushPipe !== i_io_itlbFlushPipe) begin errors++;
      if(errors<=40) $display("[%0t] io_itlbFlushPipe g=%h i=%h", $time, g_io_itlbFlushPipe, i_io_itlbFlushPipe); end
    if (g_io_pmp_0_req_bits_addr !== i_io_pmp_0_req_bits_addr) begin errors++;
      if(errors<=40) $display("[%0t] io_pmp_0_req_bits_addr g=%h i=%h", $time, g_io_pmp_0_req_bits_addr, i_io_pmp_0_req_bits_addr); end
    if (g_io_pmp_1_req_bits_addr !== i_io_pmp_1_req_bits_addr) begin errors++;
      if(errors<=40) $display("[%0t] io_pmp_1_req_bits_addr g=%h i=%h", $time, g_io_pmp_1_req_bits_addr, i_io_pmp_1_req_bits_addr); end
    if (g_io_metaRead_toIMeta_valid !== i_io_metaRead_toIMeta_valid) begin errors++;
      if(errors<=40) $display("[%0t] io_metaRead_toIMeta_valid g=%h i=%h", $time, g_io_metaRead_toIMeta_valid, i_io_metaRead_toIMeta_valid); end
    if (g_io_metaRead_toIMeta_bits_vSetIdx_0 !== i_io_metaRead_toIMeta_bits_vSetIdx_0) begin errors++;
      if(errors<=40) $display("[%0t] io_metaRead_toIMeta_bits_vSetIdx_0 g=%h i=%h", $time, g_io_metaRead_toIMeta_bits_vSetIdx_0, i_io_metaRead_toIMeta_bits_vSetIdx_0); end
    if (g_io_metaRead_toIMeta_bits_vSetIdx_1 !== i_io_metaRead_toIMeta_bits_vSetIdx_1) begin errors++;
      if(errors<=40) $display("[%0t] io_metaRead_toIMeta_bits_vSetIdx_1 g=%h i=%h", $time, g_io_metaRead_toIMeta_bits_vSetIdx_1, i_io_metaRead_toIMeta_bits_vSetIdx_1); end
    if (g_io_metaRead_toIMeta_bits_isDoubleLine !== i_io_metaRead_toIMeta_bits_isDoubleLine) begin errors++;
      if(errors<=40) $display("[%0t] io_metaRead_toIMeta_bits_isDoubleLine g=%h i=%h", $time, g_io_metaRead_toIMeta_bits_isDoubleLine, i_io_metaRead_toIMeta_bits_isDoubleLine); end
    if (g_io_MSHRReq_valid !== i_io_MSHRReq_valid) begin errors++;
      if(errors<=40) $display("[%0t] io_MSHRReq_valid g=%h i=%h", $time, g_io_MSHRReq_valid, i_io_MSHRReq_valid); end
    if (g_io_MSHRReq_bits_blkPaddr !== i_io_MSHRReq_bits_blkPaddr) begin errors++;
      if(errors<=40) $display("[%0t] io_MSHRReq_bits_blkPaddr g=%h i=%h", $time, g_io_MSHRReq_bits_blkPaddr, i_io_MSHRReq_bits_blkPaddr); end
    if (g_io_MSHRReq_bits_vSetIdx !== i_io_MSHRReq_bits_vSetIdx) begin errors++;
      if(errors<=40) $display("[%0t] io_MSHRReq_bits_vSetIdx g=%h i=%h", $time, g_io_MSHRReq_bits_vSetIdx, i_io_MSHRReq_bits_vSetIdx); end
    if (g_io_wayLookupWrite_valid !== i_io_wayLookupWrite_valid) begin errors++;
      if(errors<=40) $display("[%0t] io_wayLookupWrite_valid g=%h i=%h", $time, g_io_wayLookupWrite_valid, i_io_wayLookupWrite_valid); end
    if (g_io_wayLookupWrite_bits_entry_vSetIdx_0 !== i_io_wayLookupWrite_bits_entry_vSetIdx_0) begin errors++;
      if(errors<=40) $display("[%0t] io_wayLookupWrite_bits_entry_vSetIdx_0 g=%h i=%h", $time, g_io_wayLookupWrite_bits_entry_vSetIdx_0, i_io_wayLookupWrite_bits_entry_vSetIdx_0); end
    if (g_io_wayLookupWrite_bits_entry_vSetIdx_1 !== i_io_wayLookupWrite_bits_entry_vSetIdx_1) begin errors++;
      if(errors<=40) $display("[%0t] io_wayLookupWrite_bits_entry_vSetIdx_1 g=%h i=%h", $time, g_io_wayLookupWrite_bits_entry_vSetIdx_1, i_io_wayLookupWrite_bits_entry_vSetIdx_1); end
    if (g_io_wayLookupWrite_bits_entry_waymask_0 !== i_io_wayLookupWrite_bits_entry_waymask_0) begin errors++;
      if(errors<=40) $display("[%0t] io_wayLookupWrite_bits_entry_waymask_0 g=%h i=%h", $time, g_io_wayLookupWrite_bits_entry_waymask_0, i_io_wayLookupWrite_bits_entry_waymask_0); end
    if (g_io_wayLookupWrite_bits_entry_waymask_1 !== i_io_wayLookupWrite_bits_entry_waymask_1) begin errors++;
      if(errors<=40) $display("[%0t] io_wayLookupWrite_bits_entry_waymask_1 g=%h i=%h", $time, g_io_wayLookupWrite_bits_entry_waymask_1, i_io_wayLookupWrite_bits_entry_waymask_1); end
    if (g_io_wayLookupWrite_bits_entry_ptag_0 !== i_io_wayLookupWrite_bits_entry_ptag_0) begin errors++;
      if(errors<=40) $display("[%0t] io_wayLookupWrite_bits_entry_ptag_0 g=%h i=%h", $time, g_io_wayLookupWrite_bits_entry_ptag_0, i_io_wayLookupWrite_bits_entry_ptag_0); end
    if (g_io_wayLookupWrite_bits_entry_ptag_1 !== i_io_wayLookupWrite_bits_entry_ptag_1) begin errors++;
      if(errors<=40) $display("[%0t] io_wayLookupWrite_bits_entry_ptag_1 g=%h i=%h", $time, g_io_wayLookupWrite_bits_entry_ptag_1, i_io_wayLookupWrite_bits_entry_ptag_1); end
    if (g_io_wayLookupWrite_bits_entry_itlb_exception_0 !== i_io_wayLookupWrite_bits_entry_itlb_exception_0) begin errors++;
      if(errors<=40) $display("[%0t] io_wayLookupWrite_bits_entry_itlb_exception_0 g=%h i=%h", $time, g_io_wayLookupWrite_bits_entry_itlb_exception_0, i_io_wayLookupWrite_bits_entry_itlb_exception_0); end
    if (g_io_wayLookupWrite_bits_entry_itlb_exception_1 !== i_io_wayLookupWrite_bits_entry_itlb_exception_1) begin errors++;
      if(errors<=40) $display("[%0t] io_wayLookupWrite_bits_entry_itlb_exception_1 g=%h i=%h", $time, g_io_wayLookupWrite_bits_entry_itlb_exception_1, i_io_wayLookupWrite_bits_entry_itlb_exception_1); end
    if (g_io_wayLookupWrite_bits_entry_itlb_pbmt_0 !== i_io_wayLookupWrite_bits_entry_itlb_pbmt_0) begin errors++;
      if(errors<=40) $display("[%0t] io_wayLookupWrite_bits_entry_itlb_pbmt_0 g=%h i=%h", $time, g_io_wayLookupWrite_bits_entry_itlb_pbmt_0, i_io_wayLookupWrite_bits_entry_itlb_pbmt_0); end
    if (g_io_wayLookupWrite_bits_entry_itlb_pbmt_1 !== i_io_wayLookupWrite_bits_entry_itlb_pbmt_1) begin errors++;
      if(errors<=40) $display("[%0t] io_wayLookupWrite_bits_entry_itlb_pbmt_1 g=%h i=%h", $time, g_io_wayLookupWrite_bits_entry_itlb_pbmt_1, i_io_wayLookupWrite_bits_entry_itlb_pbmt_1); end
    if (g_io_wayLookupWrite_bits_entry_meta_codes_0 !== i_io_wayLookupWrite_bits_entry_meta_codes_0) begin errors++;
      if(errors<=40) $display("[%0t] io_wayLookupWrite_bits_entry_meta_codes_0 g=%h i=%h", $time, g_io_wayLookupWrite_bits_entry_meta_codes_0, i_io_wayLookupWrite_bits_entry_meta_codes_0); end
    if (g_io_wayLookupWrite_bits_entry_meta_codes_1 !== i_io_wayLookupWrite_bits_entry_meta_codes_1) begin errors++;
      if(errors<=40) $display("[%0t] io_wayLookupWrite_bits_entry_meta_codes_1 g=%h i=%h", $time, g_io_wayLookupWrite_bits_entry_meta_codes_1, i_io_wayLookupWrite_bits_entry_meta_codes_1); end
    if (g_io_wayLookupWrite_bits_gpf_gpaddr !== i_io_wayLookupWrite_bits_gpf_gpaddr) begin errors++;
      if(errors<=40) $display("[%0t] io_wayLookupWrite_bits_gpf_gpaddr g=%h i=%h", $time, g_io_wayLookupWrite_bits_gpf_gpaddr, i_io_wayLookupWrite_bits_gpf_gpaddr); end
    if (g_io_wayLookupWrite_bits_gpf_isForVSnonLeafPTE !== i_io_wayLookupWrite_bits_gpf_isForVSnonLeafPTE) begin errors++;
      if(errors<=40) $display("[%0t] io_wayLookupWrite_bits_gpf_isForVSnonLeafPTE g=%h i=%h", $time, g_io_wayLookupWrite_bits_gpf_isForVSnonLeafPTE, i_io_wayLookupWrite_bits_gpf_isForVSnonLeafPTE); end
  end
  initial begin
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
