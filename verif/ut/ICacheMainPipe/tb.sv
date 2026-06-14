// 自动生成：scripts/gen_icachemainpipe.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 120000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_dataArray_toIData_3_ready;
  logic [63:0] io_dataArray_fromIData_datas_0;
  logic [63:0] io_dataArray_fromIData_datas_1;
  logic [63:0] io_dataArray_fromIData_datas_2;
  logic [63:0] io_dataArray_fromIData_datas_3;
  logic [63:0] io_dataArray_fromIData_datas_4;
  logic [63:0] io_dataArray_fromIData_datas_5;
  logic [63:0] io_dataArray_fromIData_datas_6;
  logic [63:0] io_dataArray_fromIData_datas_7;
  logic io_dataArray_fromIData_codes_0;
  logic io_dataArray_fromIData_codes_1;
  logic io_dataArray_fromIData_codes_2;
  logic io_dataArray_fromIData_codes_3;
  logic io_dataArray_fromIData_codes_4;
  logic io_dataArray_fromIData_codes_5;
  logic io_dataArray_fromIData_codes_6;
  logic io_dataArray_fromIData_codes_7;
  logic io_wayLookupRead_valid;
  logic [7:0] io_wayLookupRead_bits_entry_vSetIdx_0;
  logic [7:0] io_wayLookupRead_bits_entry_vSetIdx_1;
  logic [3:0] io_wayLookupRead_bits_entry_waymask_0;
  logic [3:0] io_wayLookupRead_bits_entry_waymask_1;
  logic [35:0] io_wayLookupRead_bits_entry_ptag_0;
  logic [35:0] io_wayLookupRead_bits_entry_ptag_1;
  logic [1:0] io_wayLookupRead_bits_entry_itlb_exception_0;
  logic [1:0] io_wayLookupRead_bits_entry_itlb_exception_1;
  logic [1:0] io_wayLookupRead_bits_entry_itlb_pbmt_0;
  logic [1:0] io_wayLookupRead_bits_entry_itlb_pbmt_1;
  logic io_wayLookupRead_bits_entry_meta_codes_0;
  logic io_wayLookupRead_bits_entry_meta_codes_1;
  logic [55:0] io_wayLookupRead_bits_gpf_gpaddr;
  logic io_wayLookupRead_bits_gpf_isForVSnonLeafPTE;
  logic io_mshr_req_ready;
  logic io_mshr_resp_valid;
  logic [41:0] io_mshr_resp_bits_blkPaddr;
  logic [7:0] io_mshr_resp_bits_vSetIdx;
  logic [511:0] io_mshr_resp_bits_data;
  logic io_mshr_resp_bits_corrupt;
  logic io_ecc_enable;
  logic io_fetch_req_valid;
  logic [49:0] io_fetch_req_bits_pcMemRead_0_startAddr;
  logic [49:0] io_fetch_req_bits_pcMemRead_0_nextlineStart;
  logic [49:0] io_fetch_req_bits_pcMemRead_1_startAddr;
  logic [49:0] io_fetch_req_bits_pcMemRead_1_nextlineStart;
  logic [49:0] io_fetch_req_bits_pcMemRead_2_startAddr;
  logic [49:0] io_fetch_req_bits_pcMemRead_2_nextlineStart;
  logic [49:0] io_fetch_req_bits_pcMemRead_3_startAddr;
  logic [49:0] io_fetch_req_bits_pcMemRead_3_nextlineStart;
  logic [49:0] io_fetch_req_bits_pcMemRead_4_startAddr;
  logic [49:0] io_fetch_req_bits_pcMemRead_4_nextlineStart;
  logic io_fetch_req_bits_readValid_0;
  logic io_fetch_req_bits_readValid_1;
  logic io_fetch_req_bits_readValid_2;
  logic io_fetch_req_bits_readValid_3;
  logic io_fetch_req_bits_readValid_4;
  logic io_fetch_req_bits_backendException;
  logic io_flush;
  logic io_pmp_0_resp_instr;
  logic io_pmp_0_resp_mmio;
  logic io_pmp_1_resp_instr;
  logic io_pmp_1_resp_mmio;
  logic io_respStall;
  wire g_io_dataArray_toIData_0_valid;
  wire i_io_dataArray_toIData_0_valid;
  wire [7:0] g_io_dataArray_toIData_0_bits_vSetIdx_0;
  wire [7:0] i_io_dataArray_toIData_0_bits_vSetIdx_0;
  wire [7:0] g_io_dataArray_toIData_0_bits_vSetIdx_1;
  wire [7:0] i_io_dataArray_toIData_0_bits_vSetIdx_1;
  wire g_io_dataArray_toIData_0_bits_waymask_0_0;
  wire i_io_dataArray_toIData_0_bits_waymask_0_0;
  wire g_io_dataArray_toIData_0_bits_waymask_0_1;
  wire i_io_dataArray_toIData_0_bits_waymask_0_1;
  wire g_io_dataArray_toIData_0_bits_waymask_0_2;
  wire i_io_dataArray_toIData_0_bits_waymask_0_2;
  wire g_io_dataArray_toIData_0_bits_waymask_0_3;
  wire i_io_dataArray_toIData_0_bits_waymask_0_3;
  wire g_io_dataArray_toIData_0_bits_waymask_1_0;
  wire i_io_dataArray_toIData_0_bits_waymask_1_0;
  wire g_io_dataArray_toIData_0_bits_waymask_1_1;
  wire i_io_dataArray_toIData_0_bits_waymask_1_1;
  wire g_io_dataArray_toIData_0_bits_waymask_1_2;
  wire i_io_dataArray_toIData_0_bits_waymask_1_2;
  wire g_io_dataArray_toIData_0_bits_waymask_1_3;
  wire i_io_dataArray_toIData_0_bits_waymask_1_3;
  wire [5:0] g_io_dataArray_toIData_0_bits_blkOffset;
  wire [5:0] i_io_dataArray_toIData_0_bits_blkOffset;
  wire g_io_dataArray_toIData_1_valid;
  wire i_io_dataArray_toIData_1_valid;
  wire [7:0] g_io_dataArray_toIData_1_bits_vSetIdx_0;
  wire [7:0] i_io_dataArray_toIData_1_bits_vSetIdx_0;
  wire [7:0] g_io_dataArray_toIData_1_bits_vSetIdx_1;
  wire [7:0] i_io_dataArray_toIData_1_bits_vSetIdx_1;
  wire g_io_dataArray_toIData_2_valid;
  wire i_io_dataArray_toIData_2_valid;
  wire [7:0] g_io_dataArray_toIData_2_bits_vSetIdx_0;
  wire [7:0] i_io_dataArray_toIData_2_bits_vSetIdx_0;
  wire [7:0] g_io_dataArray_toIData_2_bits_vSetIdx_1;
  wire [7:0] i_io_dataArray_toIData_2_bits_vSetIdx_1;
  wire g_io_dataArray_toIData_3_valid;
  wire i_io_dataArray_toIData_3_valid;
  wire [7:0] g_io_dataArray_toIData_3_bits_vSetIdx_0;
  wire [7:0] i_io_dataArray_toIData_3_bits_vSetIdx_0;
  wire [7:0] g_io_dataArray_toIData_3_bits_vSetIdx_1;
  wire [7:0] i_io_dataArray_toIData_3_bits_vSetIdx_1;
  wire g_io_metaArrayFlush_0_valid;
  wire i_io_metaArrayFlush_0_valid;
  wire [7:0] g_io_metaArrayFlush_0_bits_virIdx;
  wire [7:0] i_io_metaArrayFlush_0_bits_virIdx;
  wire [3:0] g_io_metaArrayFlush_0_bits_waymask;
  wire [3:0] i_io_metaArrayFlush_0_bits_waymask;
  wire g_io_metaArrayFlush_1_valid;
  wire i_io_metaArrayFlush_1_valid;
  wire [7:0] g_io_metaArrayFlush_1_bits_virIdx;
  wire [7:0] i_io_metaArrayFlush_1_bits_virIdx;
  wire [3:0] g_io_metaArrayFlush_1_bits_waymask;
  wire [3:0] i_io_metaArrayFlush_1_bits_waymask;
  wire g_io_touch_0_valid;
  wire i_io_touch_0_valid;
  wire [7:0] g_io_touch_0_bits_vSetIdx;
  wire [7:0] i_io_touch_0_bits_vSetIdx;
  wire [1:0] g_io_touch_0_bits_way;
  wire [1:0] i_io_touch_0_bits_way;
  wire g_io_touch_1_valid;
  wire i_io_touch_1_valid;
  wire [7:0] g_io_touch_1_bits_vSetIdx;
  wire [7:0] i_io_touch_1_bits_vSetIdx;
  wire [1:0] g_io_touch_1_bits_way;
  wire [1:0] i_io_touch_1_bits_way;
  wire g_io_wayLookupRead_ready;
  wire i_io_wayLookupRead_ready;
  wire g_io_mshr_req_valid;
  wire i_io_mshr_req_valid;
  wire [41:0] g_io_mshr_req_bits_blkPaddr;
  wire [41:0] i_io_mshr_req_bits_blkPaddr;
  wire [7:0] g_io_mshr_req_bits_vSetIdx;
  wire [7:0] i_io_mshr_req_bits_vSetIdx;
  wire g_io_fetch_req_ready;
  wire i_io_fetch_req_ready;
  wire g_io_fetch_resp_valid;
  wire i_io_fetch_resp_valid;
  wire g_io_fetch_resp_bits_doubleline;
  wire i_io_fetch_resp_bits_doubleline;
  wire [49:0] g_io_fetch_resp_bits_vaddr_0;
  wire [49:0] i_io_fetch_resp_bits_vaddr_0;
  wire [49:0] g_io_fetch_resp_bits_vaddr_1;
  wire [49:0] i_io_fetch_resp_bits_vaddr_1;
  wire [511:0] g_io_fetch_resp_bits_data;
  wire [511:0] i_io_fetch_resp_bits_data;
  wire [47:0] g_io_fetch_resp_bits_paddr_0;
  wire [47:0] i_io_fetch_resp_bits_paddr_0;
  wire [1:0] g_io_fetch_resp_bits_exception_0;
  wire [1:0] i_io_fetch_resp_bits_exception_0;
  wire [1:0] g_io_fetch_resp_bits_exception_1;
  wire [1:0] i_io_fetch_resp_bits_exception_1;
  wire g_io_fetch_resp_bits_pmp_mmio_0;
  wire i_io_fetch_resp_bits_pmp_mmio_0;
  wire g_io_fetch_resp_bits_pmp_mmio_1;
  wire i_io_fetch_resp_bits_pmp_mmio_1;
  wire [1:0] g_io_fetch_resp_bits_itlb_pbmt_0;
  wire [1:0] i_io_fetch_resp_bits_itlb_pbmt_0;
  wire [1:0] g_io_fetch_resp_bits_itlb_pbmt_1;
  wire [1:0] i_io_fetch_resp_bits_itlb_pbmt_1;
  wire g_io_fetch_resp_bits_backendException;
  wire i_io_fetch_resp_bits_backendException;
  wire [55:0] g_io_fetch_resp_bits_gpaddr;
  wire [55:0] i_io_fetch_resp_bits_gpaddr;
  wire g_io_fetch_resp_bits_isForVSnonLeafPTE;
  wire i_io_fetch_resp_bits_isForVSnonLeafPTE;
  wire g_io_fetch_topdownIcacheMiss;
  wire i_io_fetch_topdownIcacheMiss;
  wire g_io_fetch_topdownItlbMiss;
  wire i_io_fetch_topdownItlbMiss;
  wire [47:0] g_io_pmp_0_req_bits_addr;
  wire [47:0] i_io_pmp_0_req_bits_addr;
  wire [47:0] g_io_pmp_1_req_bits_addr;
  wire [47:0] i_io_pmp_1_req_bits_addr;
  wire g_io_errors_0_valid;
  wire i_io_errors_0_valid;
  wire [47:0] g_io_errors_0_bits_paddr;
  wire [47:0] i_io_errors_0_bits_paddr;
  wire g_io_errors_0_bits_report_to_beu;
  wire i_io_errors_0_bits_report_to_beu;
  wire g_io_errors_1_valid;
  wire i_io_errors_1_valid;
  wire [47:0] g_io_errors_1_bits_paddr;
  wire [47:0] i_io_errors_1_bits_paddr;
  wire g_io_errors_1_bits_report_to_beu;
  wire i_io_errors_1_bits_report_to_beu;
  wire g_io_perfInfo_only_0_hit;
  wire i_io_perfInfo_only_0_hit;
  wire g_io_perfInfo_only_0_miss;
  wire i_io_perfInfo_only_0_miss;
  wire g_io_perfInfo_hit_0_hit_1;
  wire i_io_perfInfo_hit_0_hit_1;
  wire g_io_perfInfo_hit_0_miss_1;
  wire i_io_perfInfo_hit_0_miss_1;
  wire g_io_perfInfo_miss_0_hit_1;
  wire i_io_perfInfo_miss_0_hit_1;
  wire g_io_perfInfo_miss_0_miss_1;
  wire i_io_perfInfo_miss_0_miss_1;
  wire g_io_perfInfo_hit_0_except_1;
  wire i_io_perfInfo_hit_0_except_1;
  wire g_io_perfInfo_miss_0_except_1;
  wire i_io_perfInfo_miss_0_except_1;
  wire g_io_perfInfo_except_0;
  wire i_io_perfInfo_except_0;
  wire g_io_perfInfo_bank_hit_0;
  wire i_io_perfInfo_bank_hit_0;
  wire g_io_perfInfo_bank_hit_1;
  wire i_io_perfInfo_bank_hit_1;
  wire g_io_perfInfo_hit;
  wire i_io_perfInfo_hit;
  ICacheMainPipe    u_g (.clock(clk), .reset(rst), .io_dataArray_toIData_3_ready(io_dataArray_toIData_3_ready), .io_dataArray_fromIData_datas_0(io_dataArray_fromIData_datas_0), .io_dataArray_fromIData_datas_1(io_dataArray_fromIData_datas_1), .io_dataArray_fromIData_datas_2(io_dataArray_fromIData_datas_2), .io_dataArray_fromIData_datas_3(io_dataArray_fromIData_datas_3), .io_dataArray_fromIData_datas_4(io_dataArray_fromIData_datas_4), .io_dataArray_fromIData_datas_5(io_dataArray_fromIData_datas_5), .io_dataArray_fromIData_datas_6(io_dataArray_fromIData_datas_6), .io_dataArray_fromIData_datas_7(io_dataArray_fromIData_datas_7), .io_dataArray_fromIData_codes_0(io_dataArray_fromIData_codes_0), .io_dataArray_fromIData_codes_1(io_dataArray_fromIData_codes_1), .io_dataArray_fromIData_codes_2(io_dataArray_fromIData_codes_2), .io_dataArray_fromIData_codes_3(io_dataArray_fromIData_codes_3), .io_dataArray_fromIData_codes_4(io_dataArray_fromIData_codes_4), .io_dataArray_fromIData_codes_5(io_dataArray_fromIData_codes_5), .io_dataArray_fromIData_codes_6(io_dataArray_fromIData_codes_6), .io_dataArray_fromIData_codes_7(io_dataArray_fromIData_codes_7), .io_wayLookupRead_valid(io_wayLookupRead_valid), .io_wayLookupRead_bits_entry_vSetIdx_0(io_wayLookupRead_bits_entry_vSetIdx_0), .io_wayLookupRead_bits_entry_vSetIdx_1(io_wayLookupRead_bits_entry_vSetIdx_1), .io_wayLookupRead_bits_entry_waymask_0(io_wayLookupRead_bits_entry_waymask_0), .io_wayLookupRead_bits_entry_waymask_1(io_wayLookupRead_bits_entry_waymask_1), .io_wayLookupRead_bits_entry_ptag_0(io_wayLookupRead_bits_entry_ptag_0), .io_wayLookupRead_bits_entry_ptag_1(io_wayLookupRead_bits_entry_ptag_1), .io_wayLookupRead_bits_entry_itlb_exception_0(io_wayLookupRead_bits_entry_itlb_exception_0), .io_wayLookupRead_bits_entry_itlb_exception_1(io_wayLookupRead_bits_entry_itlb_exception_1), .io_wayLookupRead_bits_entry_itlb_pbmt_0(io_wayLookupRead_bits_entry_itlb_pbmt_0), .io_wayLookupRead_bits_entry_itlb_pbmt_1(io_wayLookupRead_bits_entry_itlb_pbmt_1), .io_wayLookupRead_bits_entry_meta_codes_0(io_wayLookupRead_bits_entry_meta_codes_0), .io_wayLookupRead_bits_entry_meta_codes_1(io_wayLookupRead_bits_entry_meta_codes_1), .io_wayLookupRead_bits_gpf_gpaddr(io_wayLookupRead_bits_gpf_gpaddr), .io_wayLookupRead_bits_gpf_isForVSnonLeafPTE(io_wayLookupRead_bits_gpf_isForVSnonLeafPTE), .io_mshr_req_ready(io_mshr_req_ready), .io_mshr_resp_valid(io_mshr_resp_valid), .io_mshr_resp_bits_blkPaddr(io_mshr_resp_bits_blkPaddr), .io_mshr_resp_bits_vSetIdx(io_mshr_resp_bits_vSetIdx), .io_mshr_resp_bits_data(io_mshr_resp_bits_data), .io_mshr_resp_bits_corrupt(io_mshr_resp_bits_corrupt), .io_ecc_enable(io_ecc_enable), .io_fetch_req_valid(io_fetch_req_valid), .io_fetch_req_bits_pcMemRead_0_startAddr(io_fetch_req_bits_pcMemRead_0_startAddr), .io_fetch_req_bits_pcMemRead_0_nextlineStart(io_fetch_req_bits_pcMemRead_0_nextlineStart), .io_fetch_req_bits_pcMemRead_1_startAddr(io_fetch_req_bits_pcMemRead_1_startAddr), .io_fetch_req_bits_pcMemRead_1_nextlineStart(io_fetch_req_bits_pcMemRead_1_nextlineStart), .io_fetch_req_bits_pcMemRead_2_startAddr(io_fetch_req_bits_pcMemRead_2_startAddr), .io_fetch_req_bits_pcMemRead_2_nextlineStart(io_fetch_req_bits_pcMemRead_2_nextlineStart), .io_fetch_req_bits_pcMemRead_3_startAddr(io_fetch_req_bits_pcMemRead_3_startAddr), .io_fetch_req_bits_pcMemRead_3_nextlineStart(io_fetch_req_bits_pcMemRead_3_nextlineStart), .io_fetch_req_bits_pcMemRead_4_startAddr(io_fetch_req_bits_pcMemRead_4_startAddr), .io_fetch_req_bits_pcMemRead_4_nextlineStart(io_fetch_req_bits_pcMemRead_4_nextlineStart), .io_fetch_req_bits_readValid_0(io_fetch_req_bits_readValid_0), .io_fetch_req_bits_readValid_1(io_fetch_req_bits_readValid_1), .io_fetch_req_bits_readValid_2(io_fetch_req_bits_readValid_2), .io_fetch_req_bits_readValid_3(io_fetch_req_bits_readValid_3), .io_fetch_req_bits_readValid_4(io_fetch_req_bits_readValid_4), .io_fetch_req_bits_backendException(io_fetch_req_bits_backendException), .io_flush(io_flush), .io_pmp_0_resp_instr(io_pmp_0_resp_instr), .io_pmp_0_resp_mmio(io_pmp_0_resp_mmio), .io_pmp_1_resp_instr(io_pmp_1_resp_instr), .io_pmp_1_resp_mmio(io_pmp_1_resp_mmio), .io_respStall(io_respStall), .io_dataArray_toIData_0_valid(g_io_dataArray_toIData_0_valid), .io_dataArray_toIData_0_bits_vSetIdx_0(g_io_dataArray_toIData_0_bits_vSetIdx_0), .io_dataArray_toIData_0_bits_vSetIdx_1(g_io_dataArray_toIData_0_bits_vSetIdx_1), .io_dataArray_toIData_0_bits_waymask_0_0(g_io_dataArray_toIData_0_bits_waymask_0_0), .io_dataArray_toIData_0_bits_waymask_0_1(g_io_dataArray_toIData_0_bits_waymask_0_1), .io_dataArray_toIData_0_bits_waymask_0_2(g_io_dataArray_toIData_0_bits_waymask_0_2), .io_dataArray_toIData_0_bits_waymask_0_3(g_io_dataArray_toIData_0_bits_waymask_0_3), .io_dataArray_toIData_0_bits_waymask_1_0(g_io_dataArray_toIData_0_bits_waymask_1_0), .io_dataArray_toIData_0_bits_waymask_1_1(g_io_dataArray_toIData_0_bits_waymask_1_1), .io_dataArray_toIData_0_bits_waymask_1_2(g_io_dataArray_toIData_0_bits_waymask_1_2), .io_dataArray_toIData_0_bits_waymask_1_3(g_io_dataArray_toIData_0_bits_waymask_1_3), .io_dataArray_toIData_0_bits_blkOffset(g_io_dataArray_toIData_0_bits_blkOffset), .io_dataArray_toIData_1_valid(g_io_dataArray_toIData_1_valid), .io_dataArray_toIData_1_bits_vSetIdx_0(g_io_dataArray_toIData_1_bits_vSetIdx_0), .io_dataArray_toIData_1_bits_vSetIdx_1(g_io_dataArray_toIData_1_bits_vSetIdx_1), .io_dataArray_toIData_2_valid(g_io_dataArray_toIData_2_valid), .io_dataArray_toIData_2_bits_vSetIdx_0(g_io_dataArray_toIData_2_bits_vSetIdx_0), .io_dataArray_toIData_2_bits_vSetIdx_1(g_io_dataArray_toIData_2_bits_vSetIdx_1), .io_dataArray_toIData_3_valid(g_io_dataArray_toIData_3_valid), .io_dataArray_toIData_3_bits_vSetIdx_0(g_io_dataArray_toIData_3_bits_vSetIdx_0), .io_dataArray_toIData_3_bits_vSetIdx_1(g_io_dataArray_toIData_3_bits_vSetIdx_1), .io_metaArrayFlush_0_valid(g_io_metaArrayFlush_0_valid), .io_metaArrayFlush_0_bits_virIdx(g_io_metaArrayFlush_0_bits_virIdx), .io_metaArrayFlush_0_bits_waymask(g_io_metaArrayFlush_0_bits_waymask), .io_metaArrayFlush_1_valid(g_io_metaArrayFlush_1_valid), .io_metaArrayFlush_1_bits_virIdx(g_io_metaArrayFlush_1_bits_virIdx), .io_metaArrayFlush_1_bits_waymask(g_io_metaArrayFlush_1_bits_waymask), .io_touch_0_valid(g_io_touch_0_valid), .io_touch_0_bits_vSetIdx(g_io_touch_0_bits_vSetIdx), .io_touch_0_bits_way(g_io_touch_0_bits_way), .io_touch_1_valid(g_io_touch_1_valid), .io_touch_1_bits_vSetIdx(g_io_touch_1_bits_vSetIdx), .io_touch_1_bits_way(g_io_touch_1_bits_way), .io_wayLookupRead_ready(g_io_wayLookupRead_ready), .io_mshr_req_valid(g_io_mshr_req_valid), .io_mshr_req_bits_blkPaddr(g_io_mshr_req_bits_blkPaddr), .io_mshr_req_bits_vSetIdx(g_io_mshr_req_bits_vSetIdx), .io_fetch_req_ready(g_io_fetch_req_ready), .io_fetch_resp_valid(g_io_fetch_resp_valid), .io_fetch_resp_bits_doubleline(g_io_fetch_resp_bits_doubleline), .io_fetch_resp_bits_vaddr_0(g_io_fetch_resp_bits_vaddr_0), .io_fetch_resp_bits_vaddr_1(g_io_fetch_resp_bits_vaddr_1), .io_fetch_resp_bits_data(g_io_fetch_resp_bits_data), .io_fetch_resp_bits_paddr_0(g_io_fetch_resp_bits_paddr_0), .io_fetch_resp_bits_exception_0(g_io_fetch_resp_bits_exception_0), .io_fetch_resp_bits_exception_1(g_io_fetch_resp_bits_exception_1), .io_fetch_resp_bits_pmp_mmio_0(g_io_fetch_resp_bits_pmp_mmio_0), .io_fetch_resp_bits_pmp_mmio_1(g_io_fetch_resp_bits_pmp_mmio_1), .io_fetch_resp_bits_itlb_pbmt_0(g_io_fetch_resp_bits_itlb_pbmt_0), .io_fetch_resp_bits_itlb_pbmt_1(g_io_fetch_resp_bits_itlb_pbmt_1), .io_fetch_resp_bits_backendException(g_io_fetch_resp_bits_backendException), .io_fetch_resp_bits_gpaddr(g_io_fetch_resp_bits_gpaddr), .io_fetch_resp_bits_isForVSnonLeafPTE(g_io_fetch_resp_bits_isForVSnonLeafPTE), .io_fetch_topdownIcacheMiss(g_io_fetch_topdownIcacheMiss), .io_fetch_topdownItlbMiss(g_io_fetch_topdownItlbMiss), .io_pmp_0_req_bits_addr(g_io_pmp_0_req_bits_addr), .io_pmp_1_req_bits_addr(g_io_pmp_1_req_bits_addr), .io_errors_0_valid(g_io_errors_0_valid), .io_errors_0_bits_paddr(g_io_errors_0_bits_paddr), .io_errors_0_bits_report_to_beu(g_io_errors_0_bits_report_to_beu), .io_errors_1_valid(g_io_errors_1_valid), .io_errors_1_bits_paddr(g_io_errors_1_bits_paddr), .io_errors_1_bits_report_to_beu(g_io_errors_1_bits_report_to_beu), .io_perfInfo_only_0_hit(g_io_perfInfo_only_0_hit), .io_perfInfo_only_0_miss(g_io_perfInfo_only_0_miss), .io_perfInfo_hit_0_hit_1(g_io_perfInfo_hit_0_hit_1), .io_perfInfo_hit_0_miss_1(g_io_perfInfo_hit_0_miss_1), .io_perfInfo_miss_0_hit_1(g_io_perfInfo_miss_0_hit_1), .io_perfInfo_miss_0_miss_1(g_io_perfInfo_miss_0_miss_1), .io_perfInfo_hit_0_except_1(g_io_perfInfo_hit_0_except_1), .io_perfInfo_miss_0_except_1(g_io_perfInfo_miss_0_except_1), .io_perfInfo_except_0(g_io_perfInfo_except_0), .io_perfInfo_bank_hit_0(g_io_perfInfo_bank_hit_0), .io_perfInfo_bank_hit_1(g_io_perfInfo_bank_hit_1), .io_perfInfo_hit(g_io_perfInfo_hit));
  ICacheMainPipe_xs u_i (.clock(clk), .reset(rst), .io_dataArray_toIData_3_ready(io_dataArray_toIData_3_ready), .io_dataArray_fromIData_datas_0(io_dataArray_fromIData_datas_0), .io_dataArray_fromIData_datas_1(io_dataArray_fromIData_datas_1), .io_dataArray_fromIData_datas_2(io_dataArray_fromIData_datas_2), .io_dataArray_fromIData_datas_3(io_dataArray_fromIData_datas_3), .io_dataArray_fromIData_datas_4(io_dataArray_fromIData_datas_4), .io_dataArray_fromIData_datas_5(io_dataArray_fromIData_datas_5), .io_dataArray_fromIData_datas_6(io_dataArray_fromIData_datas_6), .io_dataArray_fromIData_datas_7(io_dataArray_fromIData_datas_7), .io_dataArray_fromIData_codes_0(io_dataArray_fromIData_codes_0), .io_dataArray_fromIData_codes_1(io_dataArray_fromIData_codes_1), .io_dataArray_fromIData_codes_2(io_dataArray_fromIData_codes_2), .io_dataArray_fromIData_codes_3(io_dataArray_fromIData_codes_3), .io_dataArray_fromIData_codes_4(io_dataArray_fromIData_codes_4), .io_dataArray_fromIData_codes_5(io_dataArray_fromIData_codes_5), .io_dataArray_fromIData_codes_6(io_dataArray_fromIData_codes_6), .io_dataArray_fromIData_codes_7(io_dataArray_fromIData_codes_7), .io_wayLookupRead_valid(io_wayLookupRead_valid), .io_wayLookupRead_bits_entry_vSetIdx_0(io_wayLookupRead_bits_entry_vSetIdx_0), .io_wayLookupRead_bits_entry_vSetIdx_1(io_wayLookupRead_bits_entry_vSetIdx_1), .io_wayLookupRead_bits_entry_waymask_0(io_wayLookupRead_bits_entry_waymask_0), .io_wayLookupRead_bits_entry_waymask_1(io_wayLookupRead_bits_entry_waymask_1), .io_wayLookupRead_bits_entry_ptag_0(io_wayLookupRead_bits_entry_ptag_0), .io_wayLookupRead_bits_entry_ptag_1(io_wayLookupRead_bits_entry_ptag_1), .io_wayLookupRead_bits_entry_itlb_exception_0(io_wayLookupRead_bits_entry_itlb_exception_0), .io_wayLookupRead_bits_entry_itlb_exception_1(io_wayLookupRead_bits_entry_itlb_exception_1), .io_wayLookupRead_bits_entry_itlb_pbmt_0(io_wayLookupRead_bits_entry_itlb_pbmt_0), .io_wayLookupRead_bits_entry_itlb_pbmt_1(io_wayLookupRead_bits_entry_itlb_pbmt_1), .io_wayLookupRead_bits_entry_meta_codes_0(io_wayLookupRead_bits_entry_meta_codes_0), .io_wayLookupRead_bits_entry_meta_codes_1(io_wayLookupRead_bits_entry_meta_codes_1), .io_wayLookupRead_bits_gpf_gpaddr(io_wayLookupRead_bits_gpf_gpaddr), .io_wayLookupRead_bits_gpf_isForVSnonLeafPTE(io_wayLookupRead_bits_gpf_isForVSnonLeafPTE), .io_mshr_req_ready(io_mshr_req_ready), .io_mshr_resp_valid(io_mshr_resp_valid), .io_mshr_resp_bits_blkPaddr(io_mshr_resp_bits_blkPaddr), .io_mshr_resp_bits_vSetIdx(io_mshr_resp_bits_vSetIdx), .io_mshr_resp_bits_data(io_mshr_resp_bits_data), .io_mshr_resp_bits_corrupt(io_mshr_resp_bits_corrupt), .io_ecc_enable(io_ecc_enable), .io_fetch_req_valid(io_fetch_req_valid), .io_fetch_req_bits_pcMemRead_0_startAddr(io_fetch_req_bits_pcMemRead_0_startAddr), .io_fetch_req_bits_pcMemRead_0_nextlineStart(io_fetch_req_bits_pcMemRead_0_nextlineStart), .io_fetch_req_bits_pcMemRead_1_startAddr(io_fetch_req_bits_pcMemRead_1_startAddr), .io_fetch_req_bits_pcMemRead_1_nextlineStart(io_fetch_req_bits_pcMemRead_1_nextlineStart), .io_fetch_req_bits_pcMemRead_2_startAddr(io_fetch_req_bits_pcMemRead_2_startAddr), .io_fetch_req_bits_pcMemRead_2_nextlineStart(io_fetch_req_bits_pcMemRead_2_nextlineStart), .io_fetch_req_bits_pcMemRead_3_startAddr(io_fetch_req_bits_pcMemRead_3_startAddr), .io_fetch_req_bits_pcMemRead_3_nextlineStart(io_fetch_req_bits_pcMemRead_3_nextlineStart), .io_fetch_req_bits_pcMemRead_4_startAddr(io_fetch_req_bits_pcMemRead_4_startAddr), .io_fetch_req_bits_pcMemRead_4_nextlineStart(io_fetch_req_bits_pcMemRead_4_nextlineStart), .io_fetch_req_bits_readValid_0(io_fetch_req_bits_readValid_0), .io_fetch_req_bits_readValid_1(io_fetch_req_bits_readValid_1), .io_fetch_req_bits_readValid_2(io_fetch_req_bits_readValid_2), .io_fetch_req_bits_readValid_3(io_fetch_req_bits_readValid_3), .io_fetch_req_bits_readValid_4(io_fetch_req_bits_readValid_4), .io_fetch_req_bits_backendException(io_fetch_req_bits_backendException), .io_flush(io_flush), .io_pmp_0_resp_instr(io_pmp_0_resp_instr), .io_pmp_0_resp_mmio(io_pmp_0_resp_mmio), .io_pmp_1_resp_instr(io_pmp_1_resp_instr), .io_pmp_1_resp_mmio(io_pmp_1_resp_mmio), .io_respStall(io_respStall), .io_dataArray_toIData_0_valid(i_io_dataArray_toIData_0_valid), .io_dataArray_toIData_0_bits_vSetIdx_0(i_io_dataArray_toIData_0_bits_vSetIdx_0), .io_dataArray_toIData_0_bits_vSetIdx_1(i_io_dataArray_toIData_0_bits_vSetIdx_1), .io_dataArray_toIData_0_bits_waymask_0_0(i_io_dataArray_toIData_0_bits_waymask_0_0), .io_dataArray_toIData_0_bits_waymask_0_1(i_io_dataArray_toIData_0_bits_waymask_0_1), .io_dataArray_toIData_0_bits_waymask_0_2(i_io_dataArray_toIData_0_bits_waymask_0_2), .io_dataArray_toIData_0_bits_waymask_0_3(i_io_dataArray_toIData_0_bits_waymask_0_3), .io_dataArray_toIData_0_bits_waymask_1_0(i_io_dataArray_toIData_0_bits_waymask_1_0), .io_dataArray_toIData_0_bits_waymask_1_1(i_io_dataArray_toIData_0_bits_waymask_1_1), .io_dataArray_toIData_0_bits_waymask_1_2(i_io_dataArray_toIData_0_bits_waymask_1_2), .io_dataArray_toIData_0_bits_waymask_1_3(i_io_dataArray_toIData_0_bits_waymask_1_3), .io_dataArray_toIData_0_bits_blkOffset(i_io_dataArray_toIData_0_bits_blkOffset), .io_dataArray_toIData_1_valid(i_io_dataArray_toIData_1_valid), .io_dataArray_toIData_1_bits_vSetIdx_0(i_io_dataArray_toIData_1_bits_vSetIdx_0), .io_dataArray_toIData_1_bits_vSetIdx_1(i_io_dataArray_toIData_1_bits_vSetIdx_1), .io_dataArray_toIData_2_valid(i_io_dataArray_toIData_2_valid), .io_dataArray_toIData_2_bits_vSetIdx_0(i_io_dataArray_toIData_2_bits_vSetIdx_0), .io_dataArray_toIData_2_bits_vSetIdx_1(i_io_dataArray_toIData_2_bits_vSetIdx_1), .io_dataArray_toIData_3_valid(i_io_dataArray_toIData_3_valid), .io_dataArray_toIData_3_bits_vSetIdx_0(i_io_dataArray_toIData_3_bits_vSetIdx_0), .io_dataArray_toIData_3_bits_vSetIdx_1(i_io_dataArray_toIData_3_bits_vSetIdx_1), .io_metaArrayFlush_0_valid(i_io_metaArrayFlush_0_valid), .io_metaArrayFlush_0_bits_virIdx(i_io_metaArrayFlush_0_bits_virIdx), .io_metaArrayFlush_0_bits_waymask(i_io_metaArrayFlush_0_bits_waymask), .io_metaArrayFlush_1_valid(i_io_metaArrayFlush_1_valid), .io_metaArrayFlush_1_bits_virIdx(i_io_metaArrayFlush_1_bits_virIdx), .io_metaArrayFlush_1_bits_waymask(i_io_metaArrayFlush_1_bits_waymask), .io_touch_0_valid(i_io_touch_0_valid), .io_touch_0_bits_vSetIdx(i_io_touch_0_bits_vSetIdx), .io_touch_0_bits_way(i_io_touch_0_bits_way), .io_touch_1_valid(i_io_touch_1_valid), .io_touch_1_bits_vSetIdx(i_io_touch_1_bits_vSetIdx), .io_touch_1_bits_way(i_io_touch_1_bits_way), .io_wayLookupRead_ready(i_io_wayLookupRead_ready), .io_mshr_req_valid(i_io_mshr_req_valid), .io_mshr_req_bits_blkPaddr(i_io_mshr_req_bits_blkPaddr), .io_mshr_req_bits_vSetIdx(i_io_mshr_req_bits_vSetIdx), .io_fetch_req_ready(i_io_fetch_req_ready), .io_fetch_resp_valid(i_io_fetch_resp_valid), .io_fetch_resp_bits_doubleline(i_io_fetch_resp_bits_doubleline), .io_fetch_resp_bits_vaddr_0(i_io_fetch_resp_bits_vaddr_0), .io_fetch_resp_bits_vaddr_1(i_io_fetch_resp_bits_vaddr_1), .io_fetch_resp_bits_data(i_io_fetch_resp_bits_data), .io_fetch_resp_bits_paddr_0(i_io_fetch_resp_bits_paddr_0), .io_fetch_resp_bits_exception_0(i_io_fetch_resp_bits_exception_0), .io_fetch_resp_bits_exception_1(i_io_fetch_resp_bits_exception_1), .io_fetch_resp_bits_pmp_mmio_0(i_io_fetch_resp_bits_pmp_mmio_0), .io_fetch_resp_bits_pmp_mmio_1(i_io_fetch_resp_bits_pmp_mmio_1), .io_fetch_resp_bits_itlb_pbmt_0(i_io_fetch_resp_bits_itlb_pbmt_0), .io_fetch_resp_bits_itlb_pbmt_1(i_io_fetch_resp_bits_itlb_pbmt_1), .io_fetch_resp_bits_backendException(i_io_fetch_resp_bits_backendException), .io_fetch_resp_bits_gpaddr(i_io_fetch_resp_bits_gpaddr), .io_fetch_resp_bits_isForVSnonLeafPTE(i_io_fetch_resp_bits_isForVSnonLeafPTE), .io_fetch_topdownIcacheMiss(i_io_fetch_topdownIcacheMiss), .io_fetch_topdownItlbMiss(i_io_fetch_topdownItlbMiss), .io_pmp_0_req_bits_addr(i_io_pmp_0_req_bits_addr), .io_pmp_1_req_bits_addr(i_io_pmp_1_req_bits_addr), .io_errors_0_valid(i_io_errors_0_valid), .io_errors_0_bits_paddr(i_io_errors_0_bits_paddr), .io_errors_0_bits_report_to_beu(i_io_errors_0_bits_report_to_beu), .io_errors_1_valid(i_io_errors_1_valid), .io_errors_1_bits_paddr(i_io_errors_1_bits_paddr), .io_errors_1_bits_report_to_beu(i_io_errors_1_bits_report_to_beu), .io_perfInfo_only_0_hit(i_io_perfInfo_only_0_hit), .io_perfInfo_only_0_miss(i_io_perfInfo_only_0_miss), .io_perfInfo_hit_0_hit_1(i_io_perfInfo_hit_0_hit_1), .io_perfInfo_hit_0_miss_1(i_io_perfInfo_hit_0_miss_1), .io_perfInfo_miss_0_hit_1(i_io_perfInfo_miss_0_hit_1), .io_perfInfo_miss_0_miss_1(i_io_perfInfo_miss_0_miss_1), .io_perfInfo_hit_0_except_1(i_io_perfInfo_hit_0_except_1), .io_perfInfo_miss_0_except_1(i_io_perfInfo_miss_0_except_1), .io_perfInfo_except_0(i_io_perfInfo_except_0), .io_perfInfo_bank_hit_0(i_io_perfInfo_bank_hit_0), .io_perfInfo_bank_hit_1(i_io_perfInfo_bank_hit_1), .io_perfInfo_hit(i_io_perfInfo_hit));
  // 共享随机量：把 ftq pcMemRead_4 的 vSet 与 wayLookup vSetIdx 对齐
  logic [7:0] rnd_vset0, rnd_vset1;
  always @(negedge clk) begin
    if (rst) begin
      io_dataArray_toIData_3_ready <= 1'b0;
      io_wayLookupRead_valid <= 1'b0;
      io_mshr_req_ready <= 1'b0;
      io_mshr_resp_valid <= 1'b0;
      io_ecc_enable <= 1'b0;
      io_fetch_req_valid <= 1'b0;
      io_flush <= 1'b0;
      io_respStall <= 1'b0;
    end else begin
      rnd_vset0 <= 8'($urandom_range(0,3));
      rnd_vset1 <= 8'($urandom_range(0,3));
      io_dataArray_toIData_3_ready <= ($urandom_range(0,3)!=0);
      io_dataArray_fromIData_datas_0 <= 64'({$urandom(), $urandom()});
      io_dataArray_fromIData_datas_1 <= 64'({$urandom(), $urandom()});
      io_dataArray_fromIData_datas_2 <= 64'({$urandom(), $urandom()});
      io_dataArray_fromIData_datas_3 <= 64'({$urandom(), $urandom()});
      io_dataArray_fromIData_datas_4 <= 64'({$urandom(), $urandom()});
      io_dataArray_fromIData_datas_5 <= 64'({$urandom(), $urandom()});
      io_dataArray_fromIData_datas_6 <= 64'({$urandom(), $urandom()});
      io_dataArray_fromIData_datas_7 <= 64'({$urandom(), $urandom()});
      io_dataArray_fromIData_codes_0 <= 1'($urandom);
      io_dataArray_fromIData_codes_1 <= 1'($urandom);
      io_dataArray_fromIData_codes_2 <= 1'($urandom);
      io_dataArray_fromIData_codes_3 <= 1'($urandom);
      io_dataArray_fromIData_codes_4 <= 1'($urandom);
      io_dataArray_fromIData_codes_5 <= 1'($urandom);
      io_dataArray_fromIData_codes_6 <= 1'($urandom);
      io_dataArray_fromIData_codes_7 <= 1'($urandom);
      io_wayLookupRead_valid <= ($urandom_range(0,3)!=0);
      io_wayLookupRead_bits_entry_vSetIdx_0 <= rnd_vset0;
      io_wayLookupRead_bits_entry_vSetIdx_1 <= rnd_vset1;
      io_wayLookupRead_bits_entry_waymask_0 <= 4'($urandom_range(0,15));
      io_wayLookupRead_bits_entry_waymask_1 <= 4'($urandom_range(0,15));
      io_wayLookupRead_bits_entry_ptag_0 <= 36'($urandom_range(0,7));
      io_wayLookupRead_bits_entry_ptag_1 <= 36'($urandom_range(0,7));
      io_wayLookupRead_bits_entry_itlb_exception_0 <= 2'($urandom_range(0,3));
      io_wayLookupRead_bits_entry_itlb_exception_1 <= 2'($urandom_range(0,3));
      io_wayLookupRead_bits_entry_itlb_pbmt_0 <= 2'($urandom_range(0,3));
      io_wayLookupRead_bits_entry_itlb_pbmt_1 <= 2'($urandom_range(0,3));
      io_wayLookupRead_bits_entry_meta_codes_0 <= 1'($urandom);
      io_wayLookupRead_bits_entry_meta_codes_1 <= 1'($urandom);
      io_wayLookupRead_bits_gpf_gpaddr <= 56'({$urandom(), $urandom()});
      io_wayLookupRead_bits_gpf_isForVSnonLeafPTE <= 1'($urandom);
      io_mshr_req_ready <= ($urandom_range(0,1)==0);
      io_mshr_resp_valid <= ($urandom_range(0,2)==0);
      io_mshr_resp_bits_blkPaddr <= {36'($urandom_range(0,7)), 6'($urandom)};
      io_mshr_resp_bits_vSetIdx <= 8'($urandom_range(0,3));
      io_mshr_resp_bits_data <= 512'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      io_mshr_resp_bits_corrupt <= 1'($urandom);
      io_ecc_enable <= ($urandom_range(0,3)!=0);
      io_fetch_req_valid <= ($urandom_range(0,2)!=0);
      io_fetch_req_bits_pcMemRead_0_startAddr <= 50'({$urandom(), $urandom()});
      io_fetch_req_bits_pcMemRead_0_nextlineStart <= 50'({$urandom(), $urandom()});
      io_fetch_req_bits_pcMemRead_1_startAddr <= 50'({$urandom(), $urandom()});
      io_fetch_req_bits_pcMemRead_1_nextlineStart <= 50'({$urandom(), $urandom()});
      io_fetch_req_bits_pcMemRead_2_startAddr <= 50'({$urandom(), $urandom()});
      io_fetch_req_bits_pcMemRead_2_nextlineStart <= 50'({$urandom(), $urandom()});
      io_fetch_req_bits_pcMemRead_3_startAddr <= 50'({$urandom(), $urandom()});
      io_fetch_req_bits_pcMemRead_3_nextlineStart <= 50'({$urandom(), $urandom()});
      io_fetch_req_bits_pcMemRead_4_startAddr <= {36'($urandom), rnd_vset0, 6'($urandom)};
      io_fetch_req_bits_pcMemRead_4_nextlineStart <= {36'($urandom), rnd_vset1, 6'($urandom)};
      io_fetch_req_bits_readValid_0 <= 1'($urandom);
      io_fetch_req_bits_readValid_1 <= 1'($urandom);
      io_fetch_req_bits_readValid_2 <= 1'($urandom);
      io_fetch_req_bits_readValid_3 <= 1'($urandom);
      io_fetch_req_bits_readValid_4 <= 1'($urandom);
      io_fetch_req_bits_backendException <= 1'($urandom);
      io_flush <= ($urandom_range(0,31)==0);
      io_pmp_0_resp_instr <= 1'($urandom);
      io_pmp_0_resp_mmio <= 1'($urandom);
      io_pmp_1_resp_instr <= 1'($urandom);
      io_pmp_1_resp_mmio <= 1'($urandom);
      io_respStall <= ($urandom_range(0,3)==0);
    end
  end
  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (g_io_dataArray_toIData_0_valid !== i_io_dataArray_toIData_0_valid) begin errors++;
      if(errors<=40) $display("[%0t] io_dataArray_toIData_0_valid g=%h i=%h", $time, g_io_dataArray_toIData_0_valid, i_io_dataArray_toIData_0_valid); end
    if (g_io_dataArray_toIData_0_bits_vSetIdx_0 !== i_io_dataArray_toIData_0_bits_vSetIdx_0) begin errors++;
      if(errors<=40) $display("[%0t] io_dataArray_toIData_0_bits_vSetIdx_0 g=%h i=%h", $time, g_io_dataArray_toIData_0_bits_vSetIdx_0, i_io_dataArray_toIData_0_bits_vSetIdx_0); end
    if (g_io_dataArray_toIData_0_bits_vSetIdx_1 !== i_io_dataArray_toIData_0_bits_vSetIdx_1) begin errors++;
      if(errors<=40) $display("[%0t] io_dataArray_toIData_0_bits_vSetIdx_1 g=%h i=%h", $time, g_io_dataArray_toIData_0_bits_vSetIdx_1, i_io_dataArray_toIData_0_bits_vSetIdx_1); end
    if (g_io_dataArray_toIData_0_bits_waymask_0_0 !== i_io_dataArray_toIData_0_bits_waymask_0_0) begin errors++;
      if(errors<=40) $display("[%0t] io_dataArray_toIData_0_bits_waymask_0_0 g=%h i=%h", $time, g_io_dataArray_toIData_0_bits_waymask_0_0, i_io_dataArray_toIData_0_bits_waymask_0_0); end
    if (g_io_dataArray_toIData_0_bits_waymask_0_1 !== i_io_dataArray_toIData_0_bits_waymask_0_1) begin errors++;
      if(errors<=40) $display("[%0t] io_dataArray_toIData_0_bits_waymask_0_1 g=%h i=%h", $time, g_io_dataArray_toIData_0_bits_waymask_0_1, i_io_dataArray_toIData_0_bits_waymask_0_1); end
    if (g_io_dataArray_toIData_0_bits_waymask_0_2 !== i_io_dataArray_toIData_0_bits_waymask_0_2) begin errors++;
      if(errors<=40) $display("[%0t] io_dataArray_toIData_0_bits_waymask_0_2 g=%h i=%h", $time, g_io_dataArray_toIData_0_bits_waymask_0_2, i_io_dataArray_toIData_0_bits_waymask_0_2); end
    if (g_io_dataArray_toIData_0_bits_waymask_0_3 !== i_io_dataArray_toIData_0_bits_waymask_0_3) begin errors++;
      if(errors<=40) $display("[%0t] io_dataArray_toIData_0_bits_waymask_0_3 g=%h i=%h", $time, g_io_dataArray_toIData_0_bits_waymask_0_3, i_io_dataArray_toIData_0_bits_waymask_0_3); end
    if (g_io_dataArray_toIData_0_bits_waymask_1_0 !== i_io_dataArray_toIData_0_bits_waymask_1_0) begin errors++;
      if(errors<=40) $display("[%0t] io_dataArray_toIData_0_bits_waymask_1_0 g=%h i=%h", $time, g_io_dataArray_toIData_0_bits_waymask_1_0, i_io_dataArray_toIData_0_bits_waymask_1_0); end
    if (g_io_dataArray_toIData_0_bits_waymask_1_1 !== i_io_dataArray_toIData_0_bits_waymask_1_1) begin errors++;
      if(errors<=40) $display("[%0t] io_dataArray_toIData_0_bits_waymask_1_1 g=%h i=%h", $time, g_io_dataArray_toIData_0_bits_waymask_1_1, i_io_dataArray_toIData_0_bits_waymask_1_1); end
    if (g_io_dataArray_toIData_0_bits_waymask_1_2 !== i_io_dataArray_toIData_0_bits_waymask_1_2) begin errors++;
      if(errors<=40) $display("[%0t] io_dataArray_toIData_0_bits_waymask_1_2 g=%h i=%h", $time, g_io_dataArray_toIData_0_bits_waymask_1_2, i_io_dataArray_toIData_0_bits_waymask_1_2); end
    if (g_io_dataArray_toIData_0_bits_waymask_1_3 !== i_io_dataArray_toIData_0_bits_waymask_1_3) begin errors++;
      if(errors<=40) $display("[%0t] io_dataArray_toIData_0_bits_waymask_1_3 g=%h i=%h", $time, g_io_dataArray_toIData_0_bits_waymask_1_3, i_io_dataArray_toIData_0_bits_waymask_1_3); end
    if (g_io_dataArray_toIData_0_bits_blkOffset !== i_io_dataArray_toIData_0_bits_blkOffset) begin errors++;
      if(errors<=40) $display("[%0t] io_dataArray_toIData_0_bits_blkOffset g=%h i=%h", $time, g_io_dataArray_toIData_0_bits_blkOffset, i_io_dataArray_toIData_0_bits_blkOffset); end
    if (g_io_dataArray_toIData_1_valid !== i_io_dataArray_toIData_1_valid) begin errors++;
      if(errors<=40) $display("[%0t] io_dataArray_toIData_1_valid g=%h i=%h", $time, g_io_dataArray_toIData_1_valid, i_io_dataArray_toIData_1_valid); end
    if (g_io_dataArray_toIData_1_bits_vSetIdx_0 !== i_io_dataArray_toIData_1_bits_vSetIdx_0) begin errors++;
      if(errors<=40) $display("[%0t] io_dataArray_toIData_1_bits_vSetIdx_0 g=%h i=%h", $time, g_io_dataArray_toIData_1_bits_vSetIdx_0, i_io_dataArray_toIData_1_bits_vSetIdx_0); end
    if (g_io_dataArray_toIData_1_bits_vSetIdx_1 !== i_io_dataArray_toIData_1_bits_vSetIdx_1) begin errors++;
      if(errors<=40) $display("[%0t] io_dataArray_toIData_1_bits_vSetIdx_1 g=%h i=%h", $time, g_io_dataArray_toIData_1_bits_vSetIdx_1, i_io_dataArray_toIData_1_bits_vSetIdx_1); end
    if (g_io_dataArray_toIData_2_valid !== i_io_dataArray_toIData_2_valid) begin errors++;
      if(errors<=40) $display("[%0t] io_dataArray_toIData_2_valid g=%h i=%h", $time, g_io_dataArray_toIData_2_valid, i_io_dataArray_toIData_2_valid); end
    if (g_io_dataArray_toIData_2_bits_vSetIdx_0 !== i_io_dataArray_toIData_2_bits_vSetIdx_0) begin errors++;
      if(errors<=40) $display("[%0t] io_dataArray_toIData_2_bits_vSetIdx_0 g=%h i=%h", $time, g_io_dataArray_toIData_2_bits_vSetIdx_0, i_io_dataArray_toIData_2_bits_vSetIdx_0); end
    if (g_io_dataArray_toIData_2_bits_vSetIdx_1 !== i_io_dataArray_toIData_2_bits_vSetIdx_1) begin errors++;
      if(errors<=40) $display("[%0t] io_dataArray_toIData_2_bits_vSetIdx_1 g=%h i=%h", $time, g_io_dataArray_toIData_2_bits_vSetIdx_1, i_io_dataArray_toIData_2_bits_vSetIdx_1); end
    if (g_io_dataArray_toIData_3_valid !== i_io_dataArray_toIData_3_valid) begin errors++;
      if(errors<=40) $display("[%0t] io_dataArray_toIData_3_valid g=%h i=%h", $time, g_io_dataArray_toIData_3_valid, i_io_dataArray_toIData_3_valid); end
    if (g_io_dataArray_toIData_3_bits_vSetIdx_0 !== i_io_dataArray_toIData_3_bits_vSetIdx_0) begin errors++;
      if(errors<=40) $display("[%0t] io_dataArray_toIData_3_bits_vSetIdx_0 g=%h i=%h", $time, g_io_dataArray_toIData_3_bits_vSetIdx_0, i_io_dataArray_toIData_3_bits_vSetIdx_0); end
    if (g_io_dataArray_toIData_3_bits_vSetIdx_1 !== i_io_dataArray_toIData_3_bits_vSetIdx_1) begin errors++;
      if(errors<=40) $display("[%0t] io_dataArray_toIData_3_bits_vSetIdx_1 g=%h i=%h", $time, g_io_dataArray_toIData_3_bits_vSetIdx_1, i_io_dataArray_toIData_3_bits_vSetIdx_1); end
    if (g_io_metaArrayFlush_0_valid !== i_io_metaArrayFlush_0_valid) begin errors++;
      if(errors<=40) $display("[%0t] io_metaArrayFlush_0_valid g=%h i=%h", $time, g_io_metaArrayFlush_0_valid, i_io_metaArrayFlush_0_valid); end
    if (g_io_metaArrayFlush_0_bits_virIdx !== i_io_metaArrayFlush_0_bits_virIdx) begin errors++;
      if(errors<=40) $display("[%0t] io_metaArrayFlush_0_bits_virIdx g=%h i=%h", $time, g_io_metaArrayFlush_0_bits_virIdx, i_io_metaArrayFlush_0_bits_virIdx); end
    if (g_io_metaArrayFlush_0_bits_waymask !== i_io_metaArrayFlush_0_bits_waymask) begin errors++;
      if(errors<=40) $display("[%0t] io_metaArrayFlush_0_bits_waymask g=%h i=%h", $time, g_io_metaArrayFlush_0_bits_waymask, i_io_metaArrayFlush_0_bits_waymask); end
    if (g_io_metaArrayFlush_1_valid !== i_io_metaArrayFlush_1_valid) begin errors++;
      if(errors<=40) $display("[%0t] io_metaArrayFlush_1_valid g=%h i=%h", $time, g_io_metaArrayFlush_1_valid, i_io_metaArrayFlush_1_valid); end
    if (g_io_metaArrayFlush_1_bits_virIdx !== i_io_metaArrayFlush_1_bits_virIdx) begin errors++;
      if(errors<=40) $display("[%0t] io_metaArrayFlush_1_bits_virIdx g=%h i=%h", $time, g_io_metaArrayFlush_1_bits_virIdx, i_io_metaArrayFlush_1_bits_virIdx); end
    if (g_io_metaArrayFlush_1_bits_waymask !== i_io_metaArrayFlush_1_bits_waymask) begin errors++;
      if(errors<=40) $display("[%0t] io_metaArrayFlush_1_bits_waymask g=%h i=%h", $time, g_io_metaArrayFlush_1_bits_waymask, i_io_metaArrayFlush_1_bits_waymask); end
    if (g_io_touch_0_valid !== i_io_touch_0_valid) begin errors++;
      if(errors<=40) $display("[%0t] io_touch_0_valid g=%h i=%h", $time, g_io_touch_0_valid, i_io_touch_0_valid); end
    if (g_io_touch_0_bits_vSetIdx !== i_io_touch_0_bits_vSetIdx) begin errors++;
      if(errors<=40) $display("[%0t] io_touch_0_bits_vSetIdx g=%h i=%h", $time, g_io_touch_0_bits_vSetIdx, i_io_touch_0_bits_vSetIdx); end
    if (g_io_touch_0_bits_way !== i_io_touch_0_bits_way) begin errors++;
      if(errors<=40) $display("[%0t] io_touch_0_bits_way g=%h i=%h", $time, g_io_touch_0_bits_way, i_io_touch_0_bits_way); end
    if (g_io_touch_1_valid !== i_io_touch_1_valid) begin errors++;
      if(errors<=40) $display("[%0t] io_touch_1_valid g=%h i=%h", $time, g_io_touch_1_valid, i_io_touch_1_valid); end
    if (g_io_touch_1_bits_vSetIdx !== i_io_touch_1_bits_vSetIdx) begin errors++;
      if(errors<=40) $display("[%0t] io_touch_1_bits_vSetIdx g=%h i=%h", $time, g_io_touch_1_bits_vSetIdx, i_io_touch_1_bits_vSetIdx); end
    if (g_io_touch_1_bits_way !== i_io_touch_1_bits_way) begin errors++;
      if(errors<=40) $display("[%0t] io_touch_1_bits_way g=%h i=%h", $time, g_io_touch_1_bits_way, i_io_touch_1_bits_way); end
    if (g_io_wayLookupRead_ready !== i_io_wayLookupRead_ready) begin errors++;
      if(errors<=40) $display("[%0t] io_wayLookupRead_ready g=%h i=%h", $time, g_io_wayLookupRead_ready, i_io_wayLookupRead_ready); end
    if (g_io_mshr_req_valid !== i_io_mshr_req_valid) begin errors++;
      if(errors<=40) $display("[%0t] io_mshr_req_valid g=%h i=%h", $time, g_io_mshr_req_valid, i_io_mshr_req_valid); end
    if (g_io_mshr_req_bits_blkPaddr !== i_io_mshr_req_bits_blkPaddr) begin errors++;
      if(errors<=40) $display("[%0t] io_mshr_req_bits_blkPaddr g=%h i=%h", $time, g_io_mshr_req_bits_blkPaddr, i_io_mshr_req_bits_blkPaddr); end
    if (g_io_mshr_req_bits_vSetIdx !== i_io_mshr_req_bits_vSetIdx) begin errors++;
      if(errors<=40) $display("[%0t] io_mshr_req_bits_vSetIdx g=%h i=%h", $time, g_io_mshr_req_bits_vSetIdx, i_io_mshr_req_bits_vSetIdx); end
    if (g_io_fetch_req_ready !== i_io_fetch_req_ready) begin errors++;
      if(errors<=40) $display("[%0t] io_fetch_req_ready g=%h i=%h", $time, g_io_fetch_req_ready, i_io_fetch_req_ready); end
    if (g_io_fetch_resp_valid !== i_io_fetch_resp_valid) begin errors++;
      if(errors<=40) $display("[%0t] io_fetch_resp_valid g=%h i=%h", $time, g_io_fetch_resp_valid, i_io_fetch_resp_valid); end
    if (g_io_fetch_resp_bits_doubleline !== i_io_fetch_resp_bits_doubleline) begin errors++;
      if(errors<=40) $display("[%0t] io_fetch_resp_bits_doubleline g=%h i=%h", $time, g_io_fetch_resp_bits_doubleline, i_io_fetch_resp_bits_doubleline); end
    if (g_io_fetch_resp_bits_vaddr_0 !== i_io_fetch_resp_bits_vaddr_0) begin errors++;
      if(errors<=40) $display("[%0t] io_fetch_resp_bits_vaddr_0 g=%h i=%h", $time, g_io_fetch_resp_bits_vaddr_0, i_io_fetch_resp_bits_vaddr_0); end
    if (g_io_fetch_resp_bits_vaddr_1 !== i_io_fetch_resp_bits_vaddr_1) begin errors++;
      if(errors<=40) $display("[%0t] io_fetch_resp_bits_vaddr_1 g=%h i=%h", $time, g_io_fetch_resp_bits_vaddr_1, i_io_fetch_resp_bits_vaddr_1); end
    if (g_io_fetch_resp_bits_data !== i_io_fetch_resp_bits_data) begin errors++;
      if(errors<=40) $display("[%0t] io_fetch_resp_bits_data g=%h i=%h", $time, g_io_fetch_resp_bits_data, i_io_fetch_resp_bits_data); end
    if (g_io_fetch_resp_bits_paddr_0 !== i_io_fetch_resp_bits_paddr_0) begin errors++;
      if(errors<=40) $display("[%0t] io_fetch_resp_bits_paddr_0 g=%h i=%h", $time, g_io_fetch_resp_bits_paddr_0, i_io_fetch_resp_bits_paddr_0); end
    if (g_io_fetch_resp_bits_exception_0 !== i_io_fetch_resp_bits_exception_0) begin errors++;
      if(errors<=40) $display("[%0t] io_fetch_resp_bits_exception_0 g=%h i=%h", $time, g_io_fetch_resp_bits_exception_0, i_io_fetch_resp_bits_exception_0); end
    if (g_io_fetch_resp_bits_exception_1 !== i_io_fetch_resp_bits_exception_1) begin errors++;
      if(errors<=40) $display("[%0t] io_fetch_resp_bits_exception_1 g=%h i=%h", $time, g_io_fetch_resp_bits_exception_1, i_io_fetch_resp_bits_exception_1); end
    if (g_io_fetch_resp_bits_pmp_mmio_0 !== i_io_fetch_resp_bits_pmp_mmio_0) begin errors++;
      if(errors<=40) $display("[%0t] io_fetch_resp_bits_pmp_mmio_0 g=%h i=%h", $time, g_io_fetch_resp_bits_pmp_mmio_0, i_io_fetch_resp_bits_pmp_mmio_0); end
    if (g_io_fetch_resp_bits_pmp_mmio_1 !== i_io_fetch_resp_bits_pmp_mmio_1) begin errors++;
      if(errors<=40) $display("[%0t] io_fetch_resp_bits_pmp_mmio_1 g=%h i=%h", $time, g_io_fetch_resp_bits_pmp_mmio_1, i_io_fetch_resp_bits_pmp_mmio_1); end
    if (g_io_fetch_resp_bits_itlb_pbmt_0 !== i_io_fetch_resp_bits_itlb_pbmt_0) begin errors++;
      if(errors<=40) $display("[%0t] io_fetch_resp_bits_itlb_pbmt_0 g=%h i=%h", $time, g_io_fetch_resp_bits_itlb_pbmt_0, i_io_fetch_resp_bits_itlb_pbmt_0); end
    if (g_io_fetch_resp_bits_itlb_pbmt_1 !== i_io_fetch_resp_bits_itlb_pbmt_1) begin errors++;
      if(errors<=40) $display("[%0t] io_fetch_resp_bits_itlb_pbmt_1 g=%h i=%h", $time, g_io_fetch_resp_bits_itlb_pbmt_1, i_io_fetch_resp_bits_itlb_pbmt_1); end
    if (g_io_fetch_resp_bits_backendException !== i_io_fetch_resp_bits_backendException) begin errors++;
      if(errors<=40) $display("[%0t] io_fetch_resp_bits_backendException g=%h i=%h", $time, g_io_fetch_resp_bits_backendException, i_io_fetch_resp_bits_backendException); end
    if (g_io_fetch_resp_bits_gpaddr !== i_io_fetch_resp_bits_gpaddr) begin errors++;
      if(errors<=40) $display("[%0t] io_fetch_resp_bits_gpaddr g=%h i=%h", $time, g_io_fetch_resp_bits_gpaddr, i_io_fetch_resp_bits_gpaddr); end
    if (g_io_fetch_resp_bits_isForVSnonLeafPTE !== i_io_fetch_resp_bits_isForVSnonLeafPTE) begin errors++;
      if(errors<=40) $display("[%0t] io_fetch_resp_bits_isForVSnonLeafPTE g=%h i=%h", $time, g_io_fetch_resp_bits_isForVSnonLeafPTE, i_io_fetch_resp_bits_isForVSnonLeafPTE); end
    if (g_io_fetch_topdownIcacheMiss !== i_io_fetch_topdownIcacheMiss) begin errors++;
      if(errors<=40) $display("[%0t] io_fetch_topdownIcacheMiss g=%h i=%h", $time, g_io_fetch_topdownIcacheMiss, i_io_fetch_topdownIcacheMiss); end
    if (g_io_fetch_topdownItlbMiss !== i_io_fetch_topdownItlbMiss) begin errors++;
      if(errors<=40) $display("[%0t] io_fetch_topdownItlbMiss g=%h i=%h", $time, g_io_fetch_topdownItlbMiss, i_io_fetch_topdownItlbMiss); end
    if (g_io_pmp_0_req_bits_addr !== i_io_pmp_0_req_bits_addr) begin errors++;
      if(errors<=40) $display("[%0t] io_pmp_0_req_bits_addr g=%h i=%h", $time, g_io_pmp_0_req_bits_addr, i_io_pmp_0_req_bits_addr); end
    if (g_io_pmp_1_req_bits_addr !== i_io_pmp_1_req_bits_addr) begin errors++;
      if(errors<=40) $display("[%0t] io_pmp_1_req_bits_addr g=%h i=%h", $time, g_io_pmp_1_req_bits_addr, i_io_pmp_1_req_bits_addr); end
    if (g_io_errors_0_valid !== i_io_errors_0_valid) begin errors++;
      if(errors<=40) $display("[%0t] io_errors_0_valid g=%h i=%h", $time, g_io_errors_0_valid, i_io_errors_0_valid); end
    if (g_io_errors_0_bits_paddr !== i_io_errors_0_bits_paddr) begin errors++;
      if(errors<=40) $display("[%0t] io_errors_0_bits_paddr g=%h i=%h", $time, g_io_errors_0_bits_paddr, i_io_errors_0_bits_paddr); end
    if (g_io_errors_0_bits_report_to_beu !== i_io_errors_0_bits_report_to_beu) begin errors++;
      if(errors<=40) $display("[%0t] io_errors_0_bits_report_to_beu g=%h i=%h", $time, g_io_errors_0_bits_report_to_beu, i_io_errors_0_bits_report_to_beu); end
    if (g_io_errors_1_valid !== i_io_errors_1_valid) begin errors++;
      if(errors<=40) $display("[%0t] io_errors_1_valid g=%h i=%h", $time, g_io_errors_1_valid, i_io_errors_1_valid); end
    if (g_io_errors_1_bits_paddr !== i_io_errors_1_bits_paddr) begin errors++;
      if(errors<=40) $display("[%0t] io_errors_1_bits_paddr g=%h i=%h", $time, g_io_errors_1_bits_paddr, i_io_errors_1_bits_paddr); end
    if (g_io_errors_1_bits_report_to_beu !== i_io_errors_1_bits_report_to_beu) begin errors++;
      if(errors<=40) $display("[%0t] io_errors_1_bits_report_to_beu g=%h i=%h", $time, g_io_errors_1_bits_report_to_beu, i_io_errors_1_bits_report_to_beu); end
    if (g_io_perfInfo_only_0_hit !== i_io_perfInfo_only_0_hit) begin errors++;
      if(errors<=40) $display("[%0t] io_perfInfo_only_0_hit g=%h i=%h", $time, g_io_perfInfo_only_0_hit, i_io_perfInfo_only_0_hit); end
    if (g_io_perfInfo_only_0_miss !== i_io_perfInfo_only_0_miss) begin errors++;
      if(errors<=40) $display("[%0t] io_perfInfo_only_0_miss g=%h i=%h", $time, g_io_perfInfo_only_0_miss, i_io_perfInfo_only_0_miss); end
    if (g_io_perfInfo_hit_0_hit_1 !== i_io_perfInfo_hit_0_hit_1) begin errors++;
      if(errors<=40) $display("[%0t] io_perfInfo_hit_0_hit_1 g=%h i=%h", $time, g_io_perfInfo_hit_0_hit_1, i_io_perfInfo_hit_0_hit_1); end
    if (g_io_perfInfo_hit_0_miss_1 !== i_io_perfInfo_hit_0_miss_1) begin errors++;
      if(errors<=40) $display("[%0t] io_perfInfo_hit_0_miss_1 g=%h i=%h", $time, g_io_perfInfo_hit_0_miss_1, i_io_perfInfo_hit_0_miss_1); end
    if (g_io_perfInfo_miss_0_hit_1 !== i_io_perfInfo_miss_0_hit_1) begin errors++;
      if(errors<=40) $display("[%0t] io_perfInfo_miss_0_hit_1 g=%h i=%h", $time, g_io_perfInfo_miss_0_hit_1, i_io_perfInfo_miss_0_hit_1); end
    if (g_io_perfInfo_miss_0_miss_1 !== i_io_perfInfo_miss_0_miss_1) begin errors++;
      if(errors<=40) $display("[%0t] io_perfInfo_miss_0_miss_1 g=%h i=%h", $time, g_io_perfInfo_miss_0_miss_1, i_io_perfInfo_miss_0_miss_1); end
    if (g_io_perfInfo_hit_0_except_1 !== i_io_perfInfo_hit_0_except_1) begin errors++;
      if(errors<=40) $display("[%0t] io_perfInfo_hit_0_except_1 g=%h i=%h", $time, g_io_perfInfo_hit_0_except_1, i_io_perfInfo_hit_0_except_1); end
    if (g_io_perfInfo_miss_0_except_1 !== i_io_perfInfo_miss_0_except_1) begin errors++;
      if(errors<=40) $display("[%0t] io_perfInfo_miss_0_except_1 g=%h i=%h", $time, g_io_perfInfo_miss_0_except_1, i_io_perfInfo_miss_0_except_1); end
    if (g_io_perfInfo_except_0 !== i_io_perfInfo_except_0) begin errors++;
      if(errors<=40) $display("[%0t] io_perfInfo_except_0 g=%h i=%h", $time, g_io_perfInfo_except_0, i_io_perfInfo_except_0); end
    if (g_io_perfInfo_bank_hit_0 !== i_io_perfInfo_bank_hit_0) begin errors++;
      if(errors<=40) $display("[%0t] io_perfInfo_bank_hit_0 g=%h i=%h", $time, g_io_perfInfo_bank_hit_0, i_io_perfInfo_bank_hit_0); end
    if (g_io_perfInfo_bank_hit_1 !== i_io_perfInfo_bank_hit_1) begin errors++;
      if(errors<=40) $display("[%0t] io_perfInfo_bank_hit_1 g=%h i=%h", $time, g_io_perfInfo_bank_hit_1, i_io_perfInfo_bank_hit_1); end
    if (g_io_perfInfo_hit !== i_io_perfInfo_hit) begin errors++;
      if(errors<=40) $display("[%0t] io_perfInfo_hit g=%h i=%h", $time, g_io_perfInfo_hit, i_io_perfInfo_hit); end
  end
  initial begin
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
