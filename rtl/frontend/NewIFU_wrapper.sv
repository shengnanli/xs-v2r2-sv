// 自动生成：scripts/gen_newifu.py —— 勿手改
module NewIFU(
  input  clock,
  input  reset,
  output io_ftqInter_fromFtq_req_ready,
  input  io_ftqInter_fromFtq_req_valid,
  input  [49:0] io_ftqInter_fromFtq_req_bits_startAddr,
  input  [49:0] io_ftqInter_fromFtq_req_bits_nextlineStart,
  input  [49:0] io_ftqInter_fromFtq_req_bits_nextStartAddr,
  input  io_ftqInter_fromFtq_req_bits_ftqIdx_flag,
  input  [5:0] io_ftqInter_fromFtq_req_bits_ftqIdx_value,
  input  io_ftqInter_fromFtq_req_bits_ftqOffset_valid,
  input  [3:0] io_ftqInter_fromFtq_req_bits_ftqOffset_bits,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_0,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_1,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_2,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_3,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_4,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_5,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_6,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_7,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_8,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_9,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_10,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_11,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_12,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_13,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_14,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_15,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_16,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_17,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_18,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_19,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_20,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_21,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_22,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_23,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_24,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_25,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_26,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_27,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_28,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_29,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_30,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_31,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_32,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_33,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_34,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_35,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_36,
  input  io_ftqInter_fromFtq_req_bits_topdown_info_reasons_37,
  input  io_ftqInter_fromFtq_redirect_valid,
  input  io_ftqInter_fromFtq_redirect_bits_ftqIdx_flag,
  input  [5:0] io_ftqInter_fromFtq_redirect_bits_ftqIdx_value,
  input  [3:0] io_ftqInter_fromFtq_redirect_bits_ftqOffset,
  input  io_ftqInter_fromFtq_redirect_bits_level,
  input  io_ftqInter_fromFtq_topdown_redirect_valid,
  input  io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_pd_isRet,
  input  io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_br_hit,
  input  io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_jr_hit,
  input  io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_sc_hit,
  input  io_ftqInter_fromFtq_topdown_redirect_bits_debugIsCtrl,
  input  io_ftqInter_fromFtq_topdown_redirect_bits_debugIsMemVio,
  input  io_ftqInter_fromFtq_flushFromBpu_s2_valid,
  input  io_ftqInter_fromFtq_flushFromBpu_s2_bits_flag,
  input  [5:0] io_ftqInter_fromFtq_flushFromBpu_s2_bits_value,
  input  io_ftqInter_fromFtq_flushFromBpu_s3_valid,
  input  io_ftqInter_fromFtq_flushFromBpu_s3_bits_flag,
  input  [5:0] io_ftqInter_fromFtq_flushFromBpu_s3_bits_value,
  output io_ftqInter_toFtq_pdWb_valid,
  output [49:0] io_ftqInter_toFtq_pdWb_bits_pc_0,
  output [49:0] io_ftqInter_toFtq_pdWb_bits_pc_1,
  output [49:0] io_ftqInter_toFtq_pdWb_bits_pc_2,
  output [49:0] io_ftqInter_toFtq_pdWb_bits_pc_3,
  output [49:0] io_ftqInter_toFtq_pdWb_bits_pc_4,
  output [49:0] io_ftqInter_toFtq_pdWb_bits_pc_5,
  output [49:0] io_ftqInter_toFtq_pdWb_bits_pc_6,
  output [49:0] io_ftqInter_toFtq_pdWb_bits_pc_7,
  output [49:0] io_ftqInter_toFtq_pdWb_bits_pc_8,
  output [49:0] io_ftqInter_toFtq_pdWb_bits_pc_9,
  output [49:0] io_ftqInter_toFtq_pdWb_bits_pc_10,
  output [49:0] io_ftqInter_toFtq_pdWb_bits_pc_11,
  output [49:0] io_ftqInter_toFtq_pdWb_bits_pc_12,
  output [49:0] io_ftqInter_toFtq_pdWb_bits_pc_13,
  output [49:0] io_ftqInter_toFtq_pdWb_bits_pc_14,
  output [49:0] io_ftqInter_toFtq_pdWb_bits_pc_15,
  output io_ftqInter_toFtq_pdWb_bits_pd_0_valid,
  output io_ftqInter_toFtq_pdWb_bits_pd_0_isRVC,
  output [1:0] io_ftqInter_toFtq_pdWb_bits_pd_0_brType,
  output io_ftqInter_toFtq_pdWb_bits_pd_0_isCall,
  output io_ftqInter_toFtq_pdWb_bits_pd_0_isRet,
  output io_ftqInter_toFtq_pdWb_bits_pd_1_valid,
  output io_ftqInter_toFtq_pdWb_bits_pd_1_isRVC,
  output [1:0] io_ftqInter_toFtq_pdWb_bits_pd_1_brType,
  output io_ftqInter_toFtq_pdWb_bits_pd_1_isCall,
  output io_ftqInter_toFtq_pdWb_bits_pd_1_isRet,
  output io_ftqInter_toFtq_pdWb_bits_pd_2_valid,
  output io_ftqInter_toFtq_pdWb_bits_pd_2_isRVC,
  output [1:0] io_ftqInter_toFtq_pdWb_bits_pd_2_brType,
  output io_ftqInter_toFtq_pdWb_bits_pd_2_isCall,
  output io_ftqInter_toFtq_pdWb_bits_pd_2_isRet,
  output io_ftqInter_toFtq_pdWb_bits_pd_3_valid,
  output io_ftqInter_toFtq_pdWb_bits_pd_3_isRVC,
  output [1:0] io_ftqInter_toFtq_pdWb_bits_pd_3_brType,
  output io_ftqInter_toFtq_pdWb_bits_pd_3_isCall,
  output io_ftqInter_toFtq_pdWb_bits_pd_3_isRet,
  output io_ftqInter_toFtq_pdWb_bits_pd_4_valid,
  output io_ftqInter_toFtq_pdWb_bits_pd_4_isRVC,
  output [1:0] io_ftqInter_toFtq_pdWb_bits_pd_4_brType,
  output io_ftqInter_toFtq_pdWb_bits_pd_4_isCall,
  output io_ftqInter_toFtq_pdWb_bits_pd_4_isRet,
  output io_ftqInter_toFtq_pdWb_bits_pd_5_valid,
  output io_ftqInter_toFtq_pdWb_bits_pd_5_isRVC,
  output [1:0] io_ftqInter_toFtq_pdWb_bits_pd_5_brType,
  output io_ftqInter_toFtq_pdWb_bits_pd_5_isCall,
  output io_ftqInter_toFtq_pdWb_bits_pd_5_isRet,
  output io_ftqInter_toFtq_pdWb_bits_pd_6_valid,
  output io_ftqInter_toFtq_pdWb_bits_pd_6_isRVC,
  output [1:0] io_ftqInter_toFtq_pdWb_bits_pd_6_brType,
  output io_ftqInter_toFtq_pdWb_bits_pd_6_isCall,
  output io_ftqInter_toFtq_pdWb_bits_pd_6_isRet,
  output io_ftqInter_toFtq_pdWb_bits_pd_7_valid,
  output io_ftqInter_toFtq_pdWb_bits_pd_7_isRVC,
  output [1:0] io_ftqInter_toFtq_pdWb_bits_pd_7_brType,
  output io_ftqInter_toFtq_pdWb_bits_pd_7_isCall,
  output io_ftqInter_toFtq_pdWb_bits_pd_7_isRet,
  output io_ftqInter_toFtq_pdWb_bits_pd_8_valid,
  output io_ftqInter_toFtq_pdWb_bits_pd_8_isRVC,
  output [1:0] io_ftqInter_toFtq_pdWb_bits_pd_8_brType,
  output io_ftqInter_toFtq_pdWb_bits_pd_8_isCall,
  output io_ftqInter_toFtq_pdWb_bits_pd_8_isRet,
  output io_ftqInter_toFtq_pdWb_bits_pd_9_valid,
  output io_ftqInter_toFtq_pdWb_bits_pd_9_isRVC,
  output [1:0] io_ftqInter_toFtq_pdWb_bits_pd_9_brType,
  output io_ftqInter_toFtq_pdWb_bits_pd_9_isCall,
  output io_ftqInter_toFtq_pdWb_bits_pd_9_isRet,
  output io_ftqInter_toFtq_pdWb_bits_pd_10_valid,
  output io_ftqInter_toFtq_pdWb_bits_pd_10_isRVC,
  output [1:0] io_ftqInter_toFtq_pdWb_bits_pd_10_brType,
  output io_ftqInter_toFtq_pdWb_bits_pd_10_isCall,
  output io_ftqInter_toFtq_pdWb_bits_pd_10_isRet,
  output io_ftqInter_toFtq_pdWb_bits_pd_11_valid,
  output io_ftqInter_toFtq_pdWb_bits_pd_11_isRVC,
  output [1:0] io_ftqInter_toFtq_pdWb_bits_pd_11_brType,
  output io_ftqInter_toFtq_pdWb_bits_pd_11_isCall,
  output io_ftqInter_toFtq_pdWb_bits_pd_11_isRet,
  output io_ftqInter_toFtq_pdWb_bits_pd_12_valid,
  output io_ftqInter_toFtq_pdWb_bits_pd_12_isRVC,
  output [1:0] io_ftqInter_toFtq_pdWb_bits_pd_12_brType,
  output io_ftqInter_toFtq_pdWb_bits_pd_12_isCall,
  output io_ftqInter_toFtq_pdWb_bits_pd_12_isRet,
  output io_ftqInter_toFtq_pdWb_bits_pd_13_valid,
  output io_ftqInter_toFtq_pdWb_bits_pd_13_isRVC,
  output [1:0] io_ftqInter_toFtq_pdWb_bits_pd_13_brType,
  output io_ftqInter_toFtq_pdWb_bits_pd_13_isCall,
  output io_ftqInter_toFtq_pdWb_bits_pd_13_isRet,
  output io_ftqInter_toFtq_pdWb_bits_pd_14_valid,
  output io_ftqInter_toFtq_pdWb_bits_pd_14_isRVC,
  output [1:0] io_ftqInter_toFtq_pdWb_bits_pd_14_brType,
  output io_ftqInter_toFtq_pdWb_bits_pd_14_isCall,
  output io_ftqInter_toFtq_pdWb_bits_pd_14_isRet,
  output io_ftqInter_toFtq_pdWb_bits_pd_15_valid,
  output io_ftqInter_toFtq_pdWb_bits_pd_15_isRVC,
  output [1:0] io_ftqInter_toFtq_pdWb_bits_pd_15_brType,
  output io_ftqInter_toFtq_pdWb_bits_pd_15_isCall,
  output io_ftqInter_toFtq_pdWb_bits_pd_15_isRet,
  output io_ftqInter_toFtq_pdWb_bits_ftqIdx_flag,
  output [5:0] io_ftqInter_toFtq_pdWb_bits_ftqIdx_value,
  output io_ftqInter_toFtq_pdWb_bits_misOffset_valid,
  output [3:0] io_ftqInter_toFtq_pdWb_bits_misOffset_bits,
  output io_ftqInter_toFtq_pdWb_bits_cfiOffset_valid,
  output [49:0] io_ftqInter_toFtq_pdWb_bits_target,
  output [49:0] io_ftqInter_toFtq_pdWb_bits_jalTarget,
  output io_ftqInter_toFtq_pdWb_bits_instrRange_0,
  output io_ftqInter_toFtq_pdWb_bits_instrRange_1,
  output io_ftqInter_toFtq_pdWb_bits_instrRange_2,
  output io_ftqInter_toFtq_pdWb_bits_instrRange_3,
  output io_ftqInter_toFtq_pdWb_bits_instrRange_4,
  output io_ftqInter_toFtq_pdWb_bits_instrRange_5,
  output io_ftqInter_toFtq_pdWb_bits_instrRange_6,
  output io_ftqInter_toFtq_pdWb_bits_instrRange_7,
  output io_ftqInter_toFtq_pdWb_bits_instrRange_8,
  output io_ftqInter_toFtq_pdWb_bits_instrRange_9,
  output io_ftqInter_toFtq_pdWb_bits_instrRange_10,
  output io_ftqInter_toFtq_pdWb_bits_instrRange_11,
  output io_ftqInter_toFtq_pdWb_bits_instrRange_12,
  output io_ftqInter_toFtq_pdWb_bits_instrRange_13,
  output io_ftqInter_toFtq_pdWb_bits_instrRange_14,
  output io_ftqInter_toFtq_pdWb_bits_instrRange_15,
  input  io_icacheInter_icacheReady,
  input  io_icacheInter_resp_valid,
  input  io_icacheInter_resp_bits_doubleline,
  input  [49:0] io_icacheInter_resp_bits_vaddr_0,
  input  [49:0] io_icacheInter_resp_bits_vaddr_1,
  input  [511:0] io_icacheInter_resp_bits_data,
  input  [47:0] io_icacheInter_resp_bits_paddr_0,
  input  [1:0] io_icacheInter_resp_bits_exception_0,
  input  [1:0] io_icacheInter_resp_bits_exception_1,
  input  io_icacheInter_resp_bits_pmp_mmio_0,
  input  io_icacheInter_resp_bits_pmp_mmio_1,
  input  [1:0] io_icacheInter_resp_bits_itlb_pbmt_0,
  input  [1:0] io_icacheInter_resp_bits_itlb_pbmt_1,
  input  io_icacheInter_resp_bits_backendException,
  input  [55:0] io_icacheInter_resp_bits_gpaddr,
  input  io_icacheInter_resp_bits_isForVSnonLeafPTE,
  input  io_icacheInter_topdownIcacheMiss,
  input  io_icacheInter_topdownItlbMiss,
  output io_icacheStop,
  input  io_icachePerfInfo_only_0_hit,
  input  io_icachePerfInfo_only_0_miss,
  input  io_icachePerfInfo_hit_0_hit_1,
  input  io_icachePerfInfo_hit_0_miss_1,
  input  io_icachePerfInfo_miss_0_hit_1,
  input  io_icachePerfInfo_miss_0_miss_1,
  input  io_icachePerfInfo_hit_0_except_1,
  input  io_icachePerfInfo_miss_0_except_1,
  input  io_icachePerfInfo_except_0,
  input  io_icachePerfInfo_bank_hit_0,
  input  io_icachePerfInfo_bank_hit_1,
  input  io_icachePerfInfo_hit,
  input  io_toIbuffer_ready,
  output io_toIbuffer_valid,
  output [31:0] io_toIbuffer_bits_instrs_0,
  output [31:0] io_toIbuffer_bits_instrs_1,
  output [31:0] io_toIbuffer_bits_instrs_2,
  output [31:0] io_toIbuffer_bits_instrs_3,
  output [31:0] io_toIbuffer_bits_instrs_4,
  output [31:0] io_toIbuffer_bits_instrs_5,
  output [31:0] io_toIbuffer_bits_instrs_6,
  output [31:0] io_toIbuffer_bits_instrs_7,
  output [31:0] io_toIbuffer_bits_instrs_8,
  output [31:0] io_toIbuffer_bits_instrs_9,
  output [31:0] io_toIbuffer_bits_instrs_10,
  output [31:0] io_toIbuffer_bits_instrs_11,
  output [31:0] io_toIbuffer_bits_instrs_12,
  output [31:0] io_toIbuffer_bits_instrs_13,
  output [31:0] io_toIbuffer_bits_instrs_14,
  output [31:0] io_toIbuffer_bits_instrs_15,
  output [15:0] io_toIbuffer_bits_valid,
  output [15:0] io_toIbuffer_bits_enqEnable,
  output io_toIbuffer_bits_pd_0_isRVC,
  output [1:0] io_toIbuffer_bits_pd_0_brType,
  output io_toIbuffer_bits_pd_1_isRVC,
  output [1:0] io_toIbuffer_bits_pd_1_brType,
  output io_toIbuffer_bits_pd_2_isRVC,
  output [1:0] io_toIbuffer_bits_pd_2_brType,
  output io_toIbuffer_bits_pd_3_isRVC,
  output [1:0] io_toIbuffer_bits_pd_3_brType,
  output io_toIbuffer_bits_pd_4_isRVC,
  output [1:0] io_toIbuffer_bits_pd_4_brType,
  output io_toIbuffer_bits_pd_5_isRVC,
  output [1:0] io_toIbuffer_bits_pd_5_brType,
  output io_toIbuffer_bits_pd_6_isRVC,
  output [1:0] io_toIbuffer_bits_pd_6_brType,
  output io_toIbuffer_bits_pd_7_isRVC,
  output [1:0] io_toIbuffer_bits_pd_7_brType,
  output io_toIbuffer_bits_pd_8_isRVC,
  output [1:0] io_toIbuffer_bits_pd_8_brType,
  output io_toIbuffer_bits_pd_9_isRVC,
  output [1:0] io_toIbuffer_bits_pd_9_brType,
  output io_toIbuffer_bits_pd_10_isRVC,
  output [1:0] io_toIbuffer_bits_pd_10_brType,
  output io_toIbuffer_bits_pd_11_isRVC,
  output [1:0] io_toIbuffer_bits_pd_11_brType,
  output io_toIbuffer_bits_pd_12_isRVC,
  output [1:0] io_toIbuffer_bits_pd_12_brType,
  output io_toIbuffer_bits_pd_13_isRVC,
  output [1:0] io_toIbuffer_bits_pd_13_brType,
  output io_toIbuffer_bits_pd_14_isRVC,
  output [1:0] io_toIbuffer_bits_pd_14_brType,
  output io_toIbuffer_bits_pd_15_isRVC,
  output [1:0] io_toIbuffer_bits_pd_15_brType,
  output [9:0] io_toIbuffer_bits_foldpc_0,
  output [9:0] io_toIbuffer_bits_foldpc_1,
  output [9:0] io_toIbuffer_bits_foldpc_2,
  output [9:0] io_toIbuffer_bits_foldpc_3,
  output [9:0] io_toIbuffer_bits_foldpc_4,
  output [9:0] io_toIbuffer_bits_foldpc_5,
  output [9:0] io_toIbuffer_bits_foldpc_6,
  output [9:0] io_toIbuffer_bits_foldpc_7,
  output [9:0] io_toIbuffer_bits_foldpc_8,
  output [9:0] io_toIbuffer_bits_foldpc_9,
  output [9:0] io_toIbuffer_bits_foldpc_10,
  output [9:0] io_toIbuffer_bits_foldpc_11,
  output [9:0] io_toIbuffer_bits_foldpc_12,
  output [9:0] io_toIbuffer_bits_foldpc_13,
  output [9:0] io_toIbuffer_bits_foldpc_14,
  output [9:0] io_toIbuffer_bits_foldpc_15,
  output io_toIbuffer_bits_ftqOffset_0_valid,
  output io_toIbuffer_bits_ftqOffset_1_valid,
  output io_toIbuffer_bits_ftqOffset_2_valid,
  output io_toIbuffer_bits_ftqOffset_3_valid,
  output io_toIbuffer_bits_ftqOffset_4_valid,
  output io_toIbuffer_bits_ftqOffset_5_valid,
  output io_toIbuffer_bits_ftqOffset_6_valid,
  output io_toIbuffer_bits_ftqOffset_7_valid,
  output io_toIbuffer_bits_ftqOffset_8_valid,
  output io_toIbuffer_bits_ftqOffset_9_valid,
  output io_toIbuffer_bits_ftqOffset_10_valid,
  output io_toIbuffer_bits_ftqOffset_11_valid,
  output io_toIbuffer_bits_ftqOffset_12_valid,
  output io_toIbuffer_bits_ftqOffset_13_valid,
  output io_toIbuffer_bits_ftqOffset_14_valid,
  output io_toIbuffer_bits_ftqOffset_15_valid,
  output io_toIbuffer_bits_backendException_0,
  output [1:0] io_toIbuffer_bits_exceptionType_0,
  output [1:0] io_toIbuffer_bits_exceptionType_1,
  output [1:0] io_toIbuffer_bits_exceptionType_2,
  output [1:0] io_toIbuffer_bits_exceptionType_3,
  output [1:0] io_toIbuffer_bits_exceptionType_4,
  output [1:0] io_toIbuffer_bits_exceptionType_5,
  output [1:0] io_toIbuffer_bits_exceptionType_6,
  output [1:0] io_toIbuffer_bits_exceptionType_7,
  output [1:0] io_toIbuffer_bits_exceptionType_8,
  output [1:0] io_toIbuffer_bits_exceptionType_9,
  output [1:0] io_toIbuffer_bits_exceptionType_10,
  output [1:0] io_toIbuffer_bits_exceptionType_11,
  output [1:0] io_toIbuffer_bits_exceptionType_12,
  output [1:0] io_toIbuffer_bits_exceptionType_13,
  output [1:0] io_toIbuffer_bits_exceptionType_14,
  output [1:0] io_toIbuffer_bits_exceptionType_15,
  output io_toIbuffer_bits_crossPageIPFFix_0,
  output io_toIbuffer_bits_crossPageIPFFix_1,
  output io_toIbuffer_bits_crossPageIPFFix_2,
  output io_toIbuffer_bits_crossPageIPFFix_3,
  output io_toIbuffer_bits_crossPageIPFFix_4,
  output io_toIbuffer_bits_crossPageIPFFix_5,
  output io_toIbuffer_bits_crossPageIPFFix_6,
  output io_toIbuffer_bits_crossPageIPFFix_7,
  output io_toIbuffer_bits_crossPageIPFFix_8,
  output io_toIbuffer_bits_crossPageIPFFix_9,
  output io_toIbuffer_bits_crossPageIPFFix_10,
  output io_toIbuffer_bits_crossPageIPFFix_11,
  output io_toIbuffer_bits_crossPageIPFFix_12,
  output io_toIbuffer_bits_crossPageIPFFix_13,
  output io_toIbuffer_bits_crossPageIPFFix_14,
  output io_toIbuffer_bits_crossPageIPFFix_15,
  output io_toIbuffer_bits_illegalInstr_0,
  output io_toIbuffer_bits_illegalInstr_1,
  output io_toIbuffer_bits_illegalInstr_2,
  output io_toIbuffer_bits_illegalInstr_3,
  output io_toIbuffer_bits_illegalInstr_4,
  output io_toIbuffer_bits_illegalInstr_5,
  output io_toIbuffer_bits_illegalInstr_6,
  output io_toIbuffer_bits_illegalInstr_7,
  output io_toIbuffer_bits_illegalInstr_8,
  output io_toIbuffer_bits_illegalInstr_9,
  output io_toIbuffer_bits_illegalInstr_10,
  output io_toIbuffer_bits_illegalInstr_11,
  output io_toIbuffer_bits_illegalInstr_12,
  output io_toIbuffer_bits_illegalInstr_13,
  output io_toIbuffer_bits_illegalInstr_14,
  output io_toIbuffer_bits_illegalInstr_15,
  output [3:0] io_toIbuffer_bits_triggered_0,
  output [3:0] io_toIbuffer_bits_triggered_1,
  output [3:0] io_toIbuffer_bits_triggered_2,
  output [3:0] io_toIbuffer_bits_triggered_3,
  output [3:0] io_toIbuffer_bits_triggered_4,
  output [3:0] io_toIbuffer_bits_triggered_5,
  output [3:0] io_toIbuffer_bits_triggered_6,
  output [3:0] io_toIbuffer_bits_triggered_7,
  output [3:0] io_toIbuffer_bits_triggered_8,
  output [3:0] io_toIbuffer_bits_triggered_9,
  output [3:0] io_toIbuffer_bits_triggered_10,
  output [3:0] io_toIbuffer_bits_triggered_11,
  output [3:0] io_toIbuffer_bits_triggered_12,
  output [3:0] io_toIbuffer_bits_triggered_13,
  output [3:0] io_toIbuffer_bits_triggered_14,
  output [3:0] io_toIbuffer_bits_triggered_15,
  output io_toIbuffer_bits_isLastInFtqEntry_0,
  output io_toIbuffer_bits_isLastInFtqEntry_1,
  output io_toIbuffer_bits_isLastInFtqEntry_2,
  output io_toIbuffer_bits_isLastInFtqEntry_3,
  output io_toIbuffer_bits_isLastInFtqEntry_4,
  output io_toIbuffer_bits_isLastInFtqEntry_5,
  output io_toIbuffer_bits_isLastInFtqEntry_6,
  output io_toIbuffer_bits_isLastInFtqEntry_7,
  output io_toIbuffer_bits_isLastInFtqEntry_8,
  output io_toIbuffer_bits_isLastInFtqEntry_9,
  output io_toIbuffer_bits_isLastInFtqEntry_10,
  output io_toIbuffer_bits_isLastInFtqEntry_11,
  output io_toIbuffer_bits_isLastInFtqEntry_12,
  output io_toIbuffer_bits_isLastInFtqEntry_13,
  output io_toIbuffer_bits_isLastInFtqEntry_14,
  output io_toIbuffer_bits_isLastInFtqEntry_15,
  output [49:0] io_toIbuffer_bits_pc_0,
  output [49:0] io_toIbuffer_bits_pc_1,
  output [49:0] io_toIbuffer_bits_pc_2,
  output [49:0] io_toIbuffer_bits_pc_3,
  output [49:0] io_toIbuffer_bits_pc_4,
  output [49:0] io_toIbuffer_bits_pc_5,
  output [49:0] io_toIbuffer_bits_pc_6,
  output [49:0] io_toIbuffer_bits_pc_7,
  output [49:0] io_toIbuffer_bits_pc_8,
  output [49:0] io_toIbuffer_bits_pc_9,
  output [49:0] io_toIbuffer_bits_pc_10,
  output [49:0] io_toIbuffer_bits_pc_11,
  output [49:0] io_toIbuffer_bits_pc_12,
  output [49:0] io_toIbuffer_bits_pc_13,
  output [49:0] io_toIbuffer_bits_pc_14,
  output [49:0] io_toIbuffer_bits_pc_15,
  output io_toIbuffer_bits_ftqPtr_flag,
  output [5:0] io_toIbuffer_bits_ftqPtr_value,
  output io_toIbuffer_bits_topdown_info_reasons_0,
  output io_toIbuffer_bits_topdown_info_reasons_1,
  output io_toIbuffer_bits_topdown_info_reasons_2,
  output io_toIbuffer_bits_topdown_info_reasons_3,
  output io_toIbuffer_bits_topdown_info_reasons_4,
  output io_toIbuffer_bits_topdown_info_reasons_5,
  output io_toIbuffer_bits_topdown_info_reasons_6,
  output io_toIbuffer_bits_topdown_info_reasons_7,
  output io_toIbuffer_bits_topdown_info_reasons_8,
  output io_toIbuffer_bits_topdown_info_reasons_9,
  output io_toIbuffer_bits_topdown_info_reasons_10,
  output io_toIbuffer_bits_topdown_info_reasons_11,
  output io_toIbuffer_bits_topdown_info_reasons_12,
  output io_toIbuffer_bits_topdown_info_reasons_13,
  output io_toIbuffer_bits_topdown_info_reasons_14,
  output io_toIbuffer_bits_topdown_info_reasons_15,
  output io_toIbuffer_bits_topdown_info_reasons_16,
  output io_toIbuffer_bits_topdown_info_reasons_17,
  output io_toIbuffer_bits_topdown_info_reasons_18,
  output io_toIbuffer_bits_topdown_info_reasons_19,
  output io_toIbuffer_bits_topdown_info_reasons_20,
  output io_toIbuffer_bits_topdown_info_reasons_21,
  output io_toIbuffer_bits_topdown_info_reasons_22,
  output io_toIbuffer_bits_topdown_info_reasons_23,
  output io_toIbuffer_bits_topdown_info_reasons_24,
  output io_toIbuffer_bits_topdown_info_reasons_25,
  output io_toIbuffer_bits_topdown_info_reasons_26,
  output io_toIbuffer_bits_topdown_info_reasons_27,
  output io_toIbuffer_bits_topdown_info_reasons_28,
  output io_toIbuffer_bits_topdown_info_reasons_29,
  output io_toIbuffer_bits_topdown_info_reasons_30,
  output io_toIbuffer_bits_topdown_info_reasons_31,
  output io_toIbuffer_bits_topdown_info_reasons_32,
  output io_toIbuffer_bits_topdown_info_reasons_33,
  output io_toIbuffer_bits_topdown_info_reasons_34,
  output io_toIbuffer_bits_topdown_info_reasons_35,
  output io_toIbuffer_bits_topdown_info_reasons_36,
  output io_toIbuffer_bits_topdown_info_reasons_37,
  output io_toBackend_gpaddrMem_wen,
  output [5:0] io_toBackend_gpaddrMem_waddr,
  output [55:0] io_toBackend_gpaddrMem_wdata_gpaddr,
  output io_toBackend_gpaddrMem_wdata_isForVSnonLeafPTE,
  input  io_uncacheInter_fromUncache_valid,
  input  [31:0] io_uncacheInter_fromUncache_bits_data,
  input  io_uncacheInter_fromUncache_bits_corrupt,
  input  io_uncacheInter_toUncache_ready,
  output io_uncacheInter_toUncache_valid,
  output [47:0] io_uncacheInter_toUncache_bits_addr,
  input  io_frontendTrigger_tUpdate_valid,
  input  [1:0] io_frontendTrigger_tUpdate_bits_addr,
  input  [1:0] io_frontendTrigger_tUpdate_bits_tdata_matchType,
  input  io_frontendTrigger_tUpdate_bits_tdata_select,
  input  [3:0] io_frontendTrigger_tUpdate_bits_tdata_action,
  input  io_frontendTrigger_tUpdate_bits_tdata_chain,
  input  [63:0] io_frontendTrigger_tUpdate_bits_tdata_tdata2,
  input  io_frontendTrigger_tEnableVec_0,
  input  io_frontendTrigger_tEnableVec_1,
  input  io_frontendTrigger_tEnableVec_2,
  input  io_frontendTrigger_tEnableVec_3,
  input  io_frontendTrigger_debugMode,
  input  io_frontendTrigger_triggerCanRaiseBpExp,
  input  io_rob_commits_0_valid,
  input  io_rob_commits_0_bits_ftqIdx_flag,
  input  [5:0] io_rob_commits_0_bits_ftqIdx_value,
  input  [3:0] io_rob_commits_0_bits_ftqOffset,
  input  io_rob_commits_1_valid,
  input  io_rob_commits_1_bits_ftqIdx_flag,
  input  [5:0] io_rob_commits_1_bits_ftqIdx_value,
  input  [3:0] io_rob_commits_1_bits_ftqOffset,
  input  io_rob_commits_2_valid,
  input  io_rob_commits_2_bits_ftqIdx_flag,
  input  [5:0] io_rob_commits_2_bits_ftqIdx_value,
  input  [3:0] io_rob_commits_2_bits_ftqOffset,
  input  io_rob_commits_3_valid,
  input  io_rob_commits_3_bits_ftqIdx_flag,
  input  [5:0] io_rob_commits_3_bits_ftqIdx_value,
  input  [3:0] io_rob_commits_3_bits_ftqOffset,
  input  io_rob_commits_4_valid,
  input  io_rob_commits_4_bits_ftqIdx_flag,
  input  [5:0] io_rob_commits_4_bits_ftqIdx_value,
  input  [3:0] io_rob_commits_4_bits_ftqOffset,
  input  io_rob_commits_5_valid,
  input  io_rob_commits_5_bits_ftqIdx_flag,
  input  [5:0] io_rob_commits_5_bits_ftqIdx_value,
  input  [3:0] io_rob_commits_5_bits_ftqOffset,
  input  io_rob_commits_6_valid,
  input  io_rob_commits_6_bits_ftqIdx_flag,
  input  [5:0] io_rob_commits_6_bits_ftqIdx_value,
  input  [3:0] io_rob_commits_6_bits_ftqOffset,
  input  io_rob_commits_7_valid,
  input  io_rob_commits_7_bits_ftqIdx_flag,
  input  [5:0] io_rob_commits_7_bits_ftqIdx_value,
  input  [3:0] io_rob_commits_7_bits_ftqOffset,
  input  io_iTLBInter_req_ready,
  output io_iTLBInter_req_valid,
  output [49:0] io_iTLBInter_req_bits_vaddr,
  output io_iTLBInter_resp_ready,
  input  io_iTLBInter_resp_valid,
  input  [47:0] io_iTLBInter_resp_bits_paddr_0,
  input  [63:0] io_iTLBInter_resp_bits_gpaddr_0,
  input  [1:0] io_iTLBInter_resp_bits_pbmt_0,
  input  io_iTLBInter_resp_bits_miss,
  input  io_iTLBInter_resp_bits_isForVSnonLeafPTE,
  input  io_iTLBInter_resp_bits_excp_0_gpf_instr,
  input  io_iTLBInter_resp_bits_excp_0_pf_instr,
  input  io_iTLBInter_resp_bits_excp_0_af_instr,
  output [47:0] io_pmp_req_bits_addr,
  input  io_pmp_resp_instr,
  input  io_pmp_resp_mmio,
  output io_mmioCommitRead_mmioFtqPtr_flag,
  output [5:0] io_mmioCommitRead_mmioFtqPtr_value,
  input  io_mmioCommitRead_mmioLastCommit,
  input  io_csr_fsIsOff,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value,
  output [5:0] io_perf_2_value,
  output [5:0] io_perf_3_value,
  output [5:0] io_perf_4_value,
  output [5:0] io_perf_5_value,
  output [5:0] io_perf_6_value,
  output [5:0] io_perf_7_value,
  output [5:0] io_perf_8_value,
  output [5:0] io_perf_9_value,
  output [5:0] io_perf_10_value,
  output [5:0] io_perf_11_value,
  output [5:0] io_perf_12_value
);
  import xs_newifu_pkg::*;
  ftq_req_t ftq_req;
  assign ftq_req.startAddr     = io_ftqInter_fromFtq_req_bits_startAddr;
  assign ftq_req.nextlineStart = io_ftqInter_fromFtq_req_bits_nextlineStart;
  assign ftq_req.nextStartAddr = io_ftqInter_fromFtq_req_bits_nextStartAddr;
  assign ftq_req.ftqIdx_flag   = io_ftqInter_fromFtq_req_bits_ftqIdx_flag;
  assign ftq_req.ftqIdx_value  = io_ftqInter_fromFtq_req_bits_ftqIdx_value;
  assign ftq_req.ftqOffset_valid = io_ftqInter_fromFtq_req_bits_ftqOffset_valid;
  assign ftq_req.ftqOffset_bits  = io_ftqInter_fromFtq_req_bits_ftqOffset_bits;
  wire [37:0] ftq_req_topdown_reasons = {
    io_ftqInter_fromFtq_req_bits_topdown_info_reasons_37, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_36, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_35, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_34, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_33, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_32, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_31, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_30, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_29, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_28, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_27, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_26, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_25, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_24, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_23, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_22, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_21, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_20, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_19, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_18, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_17, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_16, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_15, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_14, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_13, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_12, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_11, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_10, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_9, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_8, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_7, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_6, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_5, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_4, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_3, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_2, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_1, io_ftqInter_fromFtq_req_bits_topdown_info_reasons_0};
  wire [7:0] rob_commit_valid = {io_rob_commits_7_valid, io_rob_commits_6_valid,
    io_rob_commits_5_valid, io_rob_commits_4_valid, io_rob_commits_3_valid,
    io_rob_commits_2_valid, io_rob_commits_1_valid, io_rob_commits_0_valid};
  pd_info_t [15:0] c_pdWb_pd, c_ibuffer_pd;
  wire [15:0][49:0] c_pdWb_pc, c_ibuffer_pc;
  wire [15:0][31:0] c_ibuffer_instrs;
  wire [15:0][9:0]  c_ibuffer_foldpc;
  wire [15:0][1:0]  c_ibuffer_exceptionType;
  wire [15:0][3:0]  c_ibuffer_triggered;
  wire [15:0]       c_pdWb_instrRange, c_ibuffer_valid_vec, c_ibuffer_enqEnable;
  wire [15:0]       c_ibuffer_ftqOffset_valid, c_ibuffer_backendException;
  wire [15:0]       c_ibuffer_crossPageIPFFix, c_ibuffer_illegalInstr, c_ibuffer_isLastInFtqEntry;
  wire [37:0]       c_ibuffer_topdown_reasons;
  wire [12:0][5:0]  c_perf_value;
  xs_NewIFU_core u_core (
    .clock(clock), .reset(reset),
    .ftq_req_ready(io_ftqInter_fromFtq_req_ready), .ftq_req_valid(io_ftqInter_fromFtq_req_valid),
    .ftq_req(ftq_req), .ftq_req_topdown_reasons(ftq_req_topdown_reasons),
    .ftq_redirect_valid(io_ftqInter_fromFtq_redirect_valid),
    .ftq_redirect_ftqIdx_flag(io_ftqInter_fromFtq_redirect_bits_ftqIdx_flag),
    .ftq_redirect_ftqIdx_value(io_ftqInter_fromFtq_redirect_bits_ftqIdx_value),
    .ftq_redirect_ftqOffset(io_ftqInter_fromFtq_redirect_bits_ftqOffset),
    .ftq_redirect_level(io_ftqInter_fromFtq_redirect_bits_level),
    .ftq_topdown_redirect_valid(io_ftqInter_fromFtq_topdown_redirect_valid),
    .ftq_topdown_redirect_debugIsCtrl(io_ftqInter_fromFtq_topdown_redirect_bits_debugIsCtrl),
    .ftq_topdown_redirect_debugIsMemVio(io_ftqInter_fromFtq_topdown_redirect_bits_debugIsMemVio),
    .ftq_topdown_redirect_cfi_pd_isRet(io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_pd_isRet),
    .ftq_topdown_redirect_cfi_br_hit(io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_br_hit),
    .ftq_topdown_redirect_cfi_jr_hit(io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_jr_hit),
    .ftq_topdown_redirect_cfi_sc_hit(io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_sc_hit),
    .bpu_flush_s2_valid(io_ftqInter_fromFtq_flushFromBpu_s2_valid),
    .bpu_flush_s2_flag(io_ftqInter_fromFtq_flushFromBpu_s2_bits_flag),
    .bpu_flush_s2_value(io_ftqInter_fromFtq_flushFromBpu_s2_bits_value),
    .bpu_flush_s3_valid(io_ftqInter_fromFtq_flushFromBpu_s3_valid),
    .bpu_flush_s3_flag(io_ftqInter_fromFtq_flushFromBpu_s3_bits_flag),
    .bpu_flush_s3_value(io_ftqInter_fromFtq_flushFromBpu_s3_bits_value),
    .pdWb_valid(io_ftqInter_toFtq_pdWb_valid),
    .pdWb_pc(c_pdWb_pc), .pdWb_pd(c_pdWb_pd),
    .pdWb_ftqIdx_flag(io_ftqInter_toFtq_pdWb_bits_ftqIdx_flag),
    .pdWb_ftqIdx_value(io_ftqInter_toFtq_pdWb_bits_ftqIdx_value),
    .pdWb_misOffset_valid(io_ftqInter_toFtq_pdWb_bits_misOffset_valid),
    .pdWb_misOffset_bits(io_ftqInter_toFtq_pdWb_bits_misOffset_bits),
    .pdWb_cfiOffset_valid(io_ftqInter_toFtq_pdWb_bits_cfiOffset_valid),
    .pdWb_target(io_ftqInter_toFtq_pdWb_bits_target),
    .pdWb_jalTarget(io_ftqInter_toFtq_pdWb_bits_jalTarget),
    .pdWb_instrRange(c_pdWb_instrRange),
    .icache_ready(io_icacheInter_icacheReady), .icache_resp_valid(io_icacheInter_resp_valid),
    .icache_resp_doubleline(io_icacheInter_resp_bits_doubleline),
    .icache_resp_vaddr_0(io_icacheInter_resp_bits_vaddr_0),
    .icache_resp_vaddr_1(io_icacheInter_resp_bits_vaddr_1),
    .icache_resp_data(io_icacheInter_resp_bits_data),
    .icache_resp_paddr_0(io_icacheInter_resp_bits_paddr_0),
    .icache_resp_exception_0(io_icacheInter_resp_bits_exception_0),
    .icache_resp_exception_1(io_icacheInter_resp_bits_exception_1),
    .icache_resp_pmp_mmio_0(io_icacheInter_resp_bits_pmp_mmio_0),
    .icache_resp_pmp_mmio_1(io_icacheInter_resp_bits_pmp_mmio_1),
    .icache_resp_itlb_pbmt_0(io_icacheInter_resp_bits_itlb_pbmt_0),
    .icache_resp_itlb_pbmt_1(io_icacheInter_resp_bits_itlb_pbmt_1),
    .icache_resp_backendException(io_icacheInter_resp_bits_backendException),
    .icache_resp_gpaddr(io_icacheInter_resp_bits_gpaddr),
    .icache_resp_isForVSnonLeafPTE(io_icacheInter_resp_bits_isForVSnonLeafPTE),
    .icache_topdownIcacheMiss(io_icacheInter_topdownIcacheMiss),
    .icache_topdownItlbMiss(io_icacheInter_topdownItlbMiss),
    .icacheStop(io_icacheStop),
    .perf_only_0_hit(io_icachePerfInfo_only_0_hit), .perf_only_0_miss(io_icachePerfInfo_only_0_miss),
    .perf_hit_0_hit_1(io_icachePerfInfo_hit_0_hit_1), .perf_hit_0_miss_1(io_icachePerfInfo_hit_0_miss_1),
    .perf_miss_0_hit_1(io_icachePerfInfo_miss_0_hit_1), .perf_miss_0_miss_1(io_icachePerfInfo_miss_0_miss_1),
    .perf_hit_0_except_1(io_icachePerfInfo_hit_0_except_1), .perf_miss_0_except_1(io_icachePerfInfo_miss_0_except_1),
    .perf_except_0(io_icachePerfInfo_except_0),
    .perf_bank_hit_0(io_icachePerfInfo_bank_hit_0), .perf_bank_hit_1(io_icachePerfInfo_bank_hit_1),
    .perf_hit(io_icachePerfInfo_hit),
    .ibuffer_ready(io_toIbuffer_ready), .ibuffer_valid(io_toIbuffer_valid),
    .ibuffer_instrs(c_ibuffer_instrs), .ibuffer_valid_vec(io_toIbuffer_bits_valid),
    .ibuffer_enqEnable(c_ibuffer_enqEnable), .ibuffer_pd(c_ibuffer_pd),
    .ibuffer_foldpc(c_ibuffer_foldpc), .ibuffer_ftqOffset_valid(c_ibuffer_ftqOffset_valid),
    .ibuffer_backendException(c_ibuffer_backendException),
    .ibuffer_exceptionType(c_ibuffer_exceptionType),
    .ibuffer_crossPageIPFFix(c_ibuffer_crossPageIPFFix),
    .ibuffer_illegalInstr(c_ibuffer_illegalInstr),
    .ibuffer_triggered(c_ibuffer_triggered),
    .ibuffer_isLastInFtqEntry(c_ibuffer_isLastInFtqEntry),
    .ibuffer_pc(c_ibuffer_pc),
    .ibuffer_ftqPtr_flag(io_toIbuffer_bits_ftqPtr_flag),
    .ibuffer_ftqPtr_value(io_toIbuffer_bits_ftqPtr_value),
    .ibuffer_topdown_reasons(c_ibuffer_topdown_reasons),
    .toBackend_gpaddrMem_wen(io_toBackend_gpaddrMem_wen),
    .toBackend_gpaddrMem_waddr(io_toBackend_gpaddrMem_waddr),
    .toBackend_gpaddrMem_wdata_gpaddr(io_toBackend_gpaddrMem_wdata_gpaddr),
    .toBackend_gpaddrMem_wdata_isForVSnonLeafPTE(io_toBackend_gpaddrMem_wdata_isForVSnonLeafPTE),
    .uncache_resp_valid(io_uncacheInter_fromUncache_valid),
    .uncache_resp_data(io_uncacheInter_fromUncache_bits_data),
    .uncache_resp_corrupt(io_uncacheInter_fromUncache_bits_corrupt),
    .uncache_req_ready(io_uncacheInter_toUncache_ready),
    .uncache_req_valid(io_uncacheInter_toUncache_valid),
    .uncache_req_addr(io_uncacheInter_toUncache_bits_addr),
    .itlb_req_ready(io_iTLBInter_req_ready), .itlb_req_valid(io_iTLBInter_req_valid),
    .itlb_req_vaddr(io_iTLBInter_req_bits_vaddr), .itlb_resp_ready(io_iTLBInter_resp_ready),
    .itlb_resp_valid(io_iTLBInter_resp_valid), .itlb_resp_paddr_0(io_iTLBInter_resp_bits_paddr_0),
    .itlb_resp_gpaddr_0(io_iTLBInter_resp_bits_gpaddr_0), .itlb_resp_pbmt_0(io_iTLBInter_resp_bits_pbmt_0),
    .itlb_resp_miss(io_iTLBInter_resp_bits_miss),
    .itlb_resp_isForVSnonLeafPTE(io_iTLBInter_resp_bits_isForVSnonLeafPTE),
    .itlb_resp_gpf_instr(io_iTLBInter_resp_bits_excp_0_gpf_instr),
    .itlb_resp_pf_instr(io_iTLBInter_resp_bits_excp_0_pf_instr),
    .itlb_resp_af_instr(io_iTLBInter_resp_bits_excp_0_af_instr),
    .pmp_req_addr(io_pmp_req_bits_addr), .pmp_resp_instr(io_pmp_resp_instr), .pmp_resp_mmio(io_pmp_resp_mmio),
    .mmioCommitRead_mmioFtqPtr_flag(io_mmioCommitRead_mmioFtqPtr_flag),
    .mmioCommitRead_mmioFtqPtr_value(io_mmioCommitRead_mmioFtqPtr_value),
    .mmioCommitRead_mmioLastCommit(io_mmioCommitRead_mmioLastCommit),
    .ft_tUpdate_valid(io_frontendTrigger_tUpdate_valid),
    .ft_tUpdate_addr(io_frontendTrigger_tUpdate_bits_addr),
    .ft_tUpdate_matchType(io_frontendTrigger_tUpdate_bits_tdata_matchType),
    .ft_tUpdate_select(io_frontendTrigger_tUpdate_bits_tdata_select),
    .ft_tUpdate_action(io_frontendTrigger_tUpdate_bits_tdata_action),
    .ft_tUpdate_chain(io_frontendTrigger_tUpdate_bits_tdata_chain),
    .ft_tUpdate_tdata2(io_frontendTrigger_tUpdate_bits_tdata_tdata2),
    .ft_tEnableVec({io_frontendTrigger_tEnableVec_3, io_frontendTrigger_tEnableVec_2, io_frontendTrigger_tEnableVec_1, io_frontendTrigger_tEnableVec_0}),
    .ft_debugMode(io_frontendTrigger_debugMode),
    .ft_triggerCanRaiseBpExp(io_frontendTrigger_triggerCanRaiseBpExp),
    .rob_commit_valid(rob_commit_valid),
    .rob_commit_0_ftqIdx_flag(io_rob_commits_0_bits_ftqIdx_flag), .rob_commit_0_ftqIdx_value(io_rob_commits_0_bits_ftqIdx_value), .rob_commit_0_ftqOffset(io_rob_commits_0_bits_ftqOffset),
    .rob_commit_1_ftqIdx_flag(io_rob_commits_1_bits_ftqIdx_flag), .rob_commit_1_ftqIdx_value(io_rob_commits_1_bits_ftqIdx_value), .rob_commit_1_ftqOffset(io_rob_commits_1_bits_ftqOffset),
    .rob_commit_2_ftqIdx_flag(io_rob_commits_2_bits_ftqIdx_flag), .rob_commit_2_ftqIdx_value(io_rob_commits_2_bits_ftqIdx_value), .rob_commit_2_ftqOffset(io_rob_commits_2_bits_ftqOffset),
    .rob_commit_3_ftqIdx_flag(io_rob_commits_3_bits_ftqIdx_flag), .rob_commit_3_ftqIdx_value(io_rob_commits_3_bits_ftqIdx_value), .rob_commit_3_ftqOffset(io_rob_commits_3_bits_ftqOffset),
    .rob_commit_4_ftqIdx_flag(io_rob_commits_4_bits_ftqIdx_flag), .rob_commit_4_ftqIdx_value(io_rob_commits_4_bits_ftqIdx_value), .rob_commit_4_ftqOffset(io_rob_commits_4_bits_ftqOffset),
    .rob_commit_5_ftqIdx_flag(io_rob_commits_5_bits_ftqIdx_flag), .rob_commit_5_ftqIdx_value(io_rob_commits_5_bits_ftqIdx_value), .rob_commit_5_ftqOffset(io_rob_commits_5_bits_ftqOffset),
    .rob_commit_6_ftqIdx_flag(io_rob_commits_6_bits_ftqIdx_flag), .rob_commit_6_ftqIdx_value(io_rob_commits_6_bits_ftqIdx_value), .rob_commit_6_ftqOffset(io_rob_commits_6_bits_ftqOffset),
    .rob_commit_7_ftqIdx_flag(io_rob_commits_7_bits_ftqIdx_flag), .rob_commit_7_ftqIdx_value(io_rob_commits_7_bits_ftqIdx_value), .rob_commit_7_ftqOffset(io_rob_commits_7_bits_ftqOffset),
    .csr_fsIsOff(io_csr_fsIsOff),
    .perf_value(c_perf_value)
  );
  assign io_ftqInter_toFtq_pdWb_bits_pc_0 = c_pdWb_pc[0];
  assign io_ftqInter_toFtq_pdWb_bits_pc_1 = c_pdWb_pc[1];
  assign io_ftqInter_toFtq_pdWb_bits_pc_2 = c_pdWb_pc[2];
  assign io_ftqInter_toFtq_pdWb_bits_pc_3 = c_pdWb_pc[3];
  assign io_ftqInter_toFtq_pdWb_bits_pc_4 = c_pdWb_pc[4];
  assign io_ftqInter_toFtq_pdWb_bits_pc_5 = c_pdWb_pc[5];
  assign io_ftqInter_toFtq_pdWb_bits_pc_6 = c_pdWb_pc[6];
  assign io_ftqInter_toFtq_pdWb_bits_pc_7 = c_pdWb_pc[7];
  assign io_ftqInter_toFtq_pdWb_bits_pc_8 = c_pdWb_pc[8];
  assign io_ftqInter_toFtq_pdWb_bits_pc_9 = c_pdWb_pc[9];
  assign io_ftqInter_toFtq_pdWb_bits_pc_10 = c_pdWb_pc[10];
  assign io_ftqInter_toFtq_pdWb_bits_pc_11 = c_pdWb_pc[11];
  assign io_ftqInter_toFtq_pdWb_bits_pc_12 = c_pdWb_pc[12];
  assign io_ftqInter_toFtq_pdWb_bits_pc_13 = c_pdWb_pc[13];
  assign io_ftqInter_toFtq_pdWb_bits_pc_14 = c_pdWb_pc[14];
  assign io_ftqInter_toFtq_pdWb_bits_pc_15 = c_pdWb_pc[15];
  assign io_ftqInter_toFtq_pdWb_bits_pd_0_valid  = c_pdWb_pd[0].valid;
  assign io_ftqInter_toFtq_pdWb_bits_pd_0_isRVC  = c_pdWb_pd[0].isRVC;
  assign io_ftqInter_toFtq_pdWb_bits_pd_0_brType = c_pdWb_pd[0].brType;
  assign io_ftqInter_toFtq_pdWb_bits_pd_0_isCall = c_pdWb_pd[0].isCall;
  assign io_ftqInter_toFtq_pdWb_bits_pd_0_isRet  = c_pdWb_pd[0].isRet;
  assign io_ftqInter_toFtq_pdWb_bits_pd_1_valid  = c_pdWb_pd[1].valid;
  assign io_ftqInter_toFtq_pdWb_bits_pd_1_isRVC  = c_pdWb_pd[1].isRVC;
  assign io_ftqInter_toFtq_pdWb_bits_pd_1_brType = c_pdWb_pd[1].brType;
  assign io_ftqInter_toFtq_pdWb_bits_pd_1_isCall = c_pdWb_pd[1].isCall;
  assign io_ftqInter_toFtq_pdWb_bits_pd_1_isRet  = c_pdWb_pd[1].isRet;
  assign io_ftqInter_toFtq_pdWb_bits_pd_2_valid  = c_pdWb_pd[2].valid;
  assign io_ftqInter_toFtq_pdWb_bits_pd_2_isRVC  = c_pdWb_pd[2].isRVC;
  assign io_ftqInter_toFtq_pdWb_bits_pd_2_brType = c_pdWb_pd[2].brType;
  assign io_ftqInter_toFtq_pdWb_bits_pd_2_isCall = c_pdWb_pd[2].isCall;
  assign io_ftqInter_toFtq_pdWb_bits_pd_2_isRet  = c_pdWb_pd[2].isRet;
  assign io_ftqInter_toFtq_pdWb_bits_pd_3_valid  = c_pdWb_pd[3].valid;
  assign io_ftqInter_toFtq_pdWb_bits_pd_3_isRVC  = c_pdWb_pd[3].isRVC;
  assign io_ftqInter_toFtq_pdWb_bits_pd_3_brType = c_pdWb_pd[3].brType;
  assign io_ftqInter_toFtq_pdWb_bits_pd_3_isCall = c_pdWb_pd[3].isCall;
  assign io_ftqInter_toFtq_pdWb_bits_pd_3_isRet  = c_pdWb_pd[3].isRet;
  assign io_ftqInter_toFtq_pdWb_bits_pd_4_valid  = c_pdWb_pd[4].valid;
  assign io_ftqInter_toFtq_pdWb_bits_pd_4_isRVC  = c_pdWb_pd[4].isRVC;
  assign io_ftqInter_toFtq_pdWb_bits_pd_4_brType = c_pdWb_pd[4].brType;
  assign io_ftqInter_toFtq_pdWb_bits_pd_4_isCall = c_pdWb_pd[4].isCall;
  assign io_ftqInter_toFtq_pdWb_bits_pd_4_isRet  = c_pdWb_pd[4].isRet;
  assign io_ftqInter_toFtq_pdWb_bits_pd_5_valid  = c_pdWb_pd[5].valid;
  assign io_ftqInter_toFtq_pdWb_bits_pd_5_isRVC  = c_pdWb_pd[5].isRVC;
  assign io_ftqInter_toFtq_pdWb_bits_pd_5_brType = c_pdWb_pd[5].brType;
  assign io_ftqInter_toFtq_pdWb_bits_pd_5_isCall = c_pdWb_pd[5].isCall;
  assign io_ftqInter_toFtq_pdWb_bits_pd_5_isRet  = c_pdWb_pd[5].isRet;
  assign io_ftqInter_toFtq_pdWb_bits_pd_6_valid  = c_pdWb_pd[6].valid;
  assign io_ftqInter_toFtq_pdWb_bits_pd_6_isRVC  = c_pdWb_pd[6].isRVC;
  assign io_ftqInter_toFtq_pdWb_bits_pd_6_brType = c_pdWb_pd[6].brType;
  assign io_ftqInter_toFtq_pdWb_bits_pd_6_isCall = c_pdWb_pd[6].isCall;
  assign io_ftqInter_toFtq_pdWb_bits_pd_6_isRet  = c_pdWb_pd[6].isRet;
  assign io_ftqInter_toFtq_pdWb_bits_pd_7_valid  = c_pdWb_pd[7].valid;
  assign io_ftqInter_toFtq_pdWb_bits_pd_7_isRVC  = c_pdWb_pd[7].isRVC;
  assign io_ftqInter_toFtq_pdWb_bits_pd_7_brType = c_pdWb_pd[7].brType;
  assign io_ftqInter_toFtq_pdWb_bits_pd_7_isCall = c_pdWb_pd[7].isCall;
  assign io_ftqInter_toFtq_pdWb_bits_pd_7_isRet  = c_pdWb_pd[7].isRet;
  assign io_ftqInter_toFtq_pdWb_bits_pd_8_valid  = c_pdWb_pd[8].valid;
  assign io_ftqInter_toFtq_pdWb_bits_pd_8_isRVC  = c_pdWb_pd[8].isRVC;
  assign io_ftqInter_toFtq_pdWb_bits_pd_8_brType = c_pdWb_pd[8].brType;
  assign io_ftqInter_toFtq_pdWb_bits_pd_8_isCall = c_pdWb_pd[8].isCall;
  assign io_ftqInter_toFtq_pdWb_bits_pd_8_isRet  = c_pdWb_pd[8].isRet;
  assign io_ftqInter_toFtq_pdWb_bits_pd_9_valid  = c_pdWb_pd[9].valid;
  assign io_ftqInter_toFtq_pdWb_bits_pd_9_isRVC  = c_pdWb_pd[9].isRVC;
  assign io_ftqInter_toFtq_pdWb_bits_pd_9_brType = c_pdWb_pd[9].brType;
  assign io_ftqInter_toFtq_pdWb_bits_pd_9_isCall = c_pdWb_pd[9].isCall;
  assign io_ftqInter_toFtq_pdWb_bits_pd_9_isRet  = c_pdWb_pd[9].isRet;
  assign io_ftqInter_toFtq_pdWb_bits_pd_10_valid  = c_pdWb_pd[10].valid;
  assign io_ftqInter_toFtq_pdWb_bits_pd_10_isRVC  = c_pdWb_pd[10].isRVC;
  assign io_ftqInter_toFtq_pdWb_bits_pd_10_brType = c_pdWb_pd[10].brType;
  assign io_ftqInter_toFtq_pdWb_bits_pd_10_isCall = c_pdWb_pd[10].isCall;
  assign io_ftqInter_toFtq_pdWb_bits_pd_10_isRet  = c_pdWb_pd[10].isRet;
  assign io_ftqInter_toFtq_pdWb_bits_pd_11_valid  = c_pdWb_pd[11].valid;
  assign io_ftqInter_toFtq_pdWb_bits_pd_11_isRVC  = c_pdWb_pd[11].isRVC;
  assign io_ftqInter_toFtq_pdWb_bits_pd_11_brType = c_pdWb_pd[11].brType;
  assign io_ftqInter_toFtq_pdWb_bits_pd_11_isCall = c_pdWb_pd[11].isCall;
  assign io_ftqInter_toFtq_pdWb_bits_pd_11_isRet  = c_pdWb_pd[11].isRet;
  assign io_ftqInter_toFtq_pdWb_bits_pd_12_valid  = c_pdWb_pd[12].valid;
  assign io_ftqInter_toFtq_pdWb_bits_pd_12_isRVC  = c_pdWb_pd[12].isRVC;
  assign io_ftqInter_toFtq_pdWb_bits_pd_12_brType = c_pdWb_pd[12].brType;
  assign io_ftqInter_toFtq_pdWb_bits_pd_12_isCall = c_pdWb_pd[12].isCall;
  assign io_ftqInter_toFtq_pdWb_bits_pd_12_isRet  = c_pdWb_pd[12].isRet;
  assign io_ftqInter_toFtq_pdWb_bits_pd_13_valid  = c_pdWb_pd[13].valid;
  assign io_ftqInter_toFtq_pdWb_bits_pd_13_isRVC  = c_pdWb_pd[13].isRVC;
  assign io_ftqInter_toFtq_pdWb_bits_pd_13_brType = c_pdWb_pd[13].brType;
  assign io_ftqInter_toFtq_pdWb_bits_pd_13_isCall = c_pdWb_pd[13].isCall;
  assign io_ftqInter_toFtq_pdWb_bits_pd_13_isRet  = c_pdWb_pd[13].isRet;
  assign io_ftqInter_toFtq_pdWb_bits_pd_14_valid  = c_pdWb_pd[14].valid;
  assign io_ftqInter_toFtq_pdWb_bits_pd_14_isRVC  = c_pdWb_pd[14].isRVC;
  assign io_ftqInter_toFtq_pdWb_bits_pd_14_brType = c_pdWb_pd[14].brType;
  assign io_ftqInter_toFtq_pdWb_bits_pd_14_isCall = c_pdWb_pd[14].isCall;
  assign io_ftqInter_toFtq_pdWb_bits_pd_14_isRet  = c_pdWb_pd[14].isRet;
  assign io_ftqInter_toFtq_pdWb_bits_pd_15_valid  = c_pdWb_pd[15].valid;
  assign io_ftqInter_toFtq_pdWb_bits_pd_15_isRVC  = c_pdWb_pd[15].isRVC;
  assign io_ftqInter_toFtq_pdWb_bits_pd_15_brType = c_pdWb_pd[15].brType;
  assign io_ftqInter_toFtq_pdWb_bits_pd_15_isCall = c_pdWb_pd[15].isCall;
  assign io_ftqInter_toFtq_pdWb_bits_pd_15_isRet  = c_pdWb_pd[15].isRet;
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_0 = c_pdWb_instrRange[0];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_1 = c_pdWb_instrRange[1];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_2 = c_pdWb_instrRange[2];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_3 = c_pdWb_instrRange[3];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_4 = c_pdWb_instrRange[4];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_5 = c_pdWb_instrRange[5];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_6 = c_pdWb_instrRange[6];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_7 = c_pdWb_instrRange[7];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_8 = c_pdWb_instrRange[8];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_9 = c_pdWb_instrRange[9];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_10 = c_pdWb_instrRange[10];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_11 = c_pdWb_instrRange[11];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_12 = c_pdWb_instrRange[12];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_13 = c_pdWb_instrRange[13];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_14 = c_pdWb_instrRange[14];
  assign io_ftqInter_toFtq_pdWb_bits_instrRange_15 = c_pdWb_instrRange[15];
  assign io_toIbuffer_bits_instrs_0 = c_ibuffer_instrs[0];
  assign io_toIbuffer_bits_instrs_1 = c_ibuffer_instrs[1];
  assign io_toIbuffer_bits_instrs_2 = c_ibuffer_instrs[2];
  assign io_toIbuffer_bits_instrs_3 = c_ibuffer_instrs[3];
  assign io_toIbuffer_bits_instrs_4 = c_ibuffer_instrs[4];
  assign io_toIbuffer_bits_instrs_5 = c_ibuffer_instrs[5];
  assign io_toIbuffer_bits_instrs_6 = c_ibuffer_instrs[6];
  assign io_toIbuffer_bits_instrs_7 = c_ibuffer_instrs[7];
  assign io_toIbuffer_bits_instrs_8 = c_ibuffer_instrs[8];
  assign io_toIbuffer_bits_instrs_9 = c_ibuffer_instrs[9];
  assign io_toIbuffer_bits_instrs_10 = c_ibuffer_instrs[10];
  assign io_toIbuffer_bits_instrs_11 = c_ibuffer_instrs[11];
  assign io_toIbuffer_bits_instrs_12 = c_ibuffer_instrs[12];
  assign io_toIbuffer_bits_instrs_13 = c_ibuffer_instrs[13];
  assign io_toIbuffer_bits_instrs_14 = c_ibuffer_instrs[14];
  assign io_toIbuffer_bits_instrs_15 = c_ibuffer_instrs[15];
  assign io_toIbuffer_bits_enqEnable = c_ibuffer_enqEnable;
  assign io_toIbuffer_bits_pd_0_isRVC  = c_ibuffer_pd[0].isRVC;
  assign io_toIbuffer_bits_pd_0_brType = c_ibuffer_pd[0].brType;
  assign io_toIbuffer_bits_pd_1_isRVC  = c_ibuffer_pd[1].isRVC;
  assign io_toIbuffer_bits_pd_1_brType = c_ibuffer_pd[1].brType;
  assign io_toIbuffer_bits_pd_2_isRVC  = c_ibuffer_pd[2].isRVC;
  assign io_toIbuffer_bits_pd_2_brType = c_ibuffer_pd[2].brType;
  assign io_toIbuffer_bits_pd_3_isRVC  = c_ibuffer_pd[3].isRVC;
  assign io_toIbuffer_bits_pd_3_brType = c_ibuffer_pd[3].brType;
  assign io_toIbuffer_bits_pd_4_isRVC  = c_ibuffer_pd[4].isRVC;
  assign io_toIbuffer_bits_pd_4_brType = c_ibuffer_pd[4].brType;
  assign io_toIbuffer_bits_pd_5_isRVC  = c_ibuffer_pd[5].isRVC;
  assign io_toIbuffer_bits_pd_5_brType = c_ibuffer_pd[5].brType;
  assign io_toIbuffer_bits_pd_6_isRVC  = c_ibuffer_pd[6].isRVC;
  assign io_toIbuffer_bits_pd_6_brType = c_ibuffer_pd[6].brType;
  assign io_toIbuffer_bits_pd_7_isRVC  = c_ibuffer_pd[7].isRVC;
  assign io_toIbuffer_bits_pd_7_brType = c_ibuffer_pd[7].brType;
  assign io_toIbuffer_bits_pd_8_isRVC  = c_ibuffer_pd[8].isRVC;
  assign io_toIbuffer_bits_pd_8_brType = c_ibuffer_pd[8].brType;
  assign io_toIbuffer_bits_pd_9_isRVC  = c_ibuffer_pd[9].isRVC;
  assign io_toIbuffer_bits_pd_9_brType = c_ibuffer_pd[9].brType;
  assign io_toIbuffer_bits_pd_10_isRVC  = c_ibuffer_pd[10].isRVC;
  assign io_toIbuffer_bits_pd_10_brType = c_ibuffer_pd[10].brType;
  assign io_toIbuffer_bits_pd_11_isRVC  = c_ibuffer_pd[11].isRVC;
  assign io_toIbuffer_bits_pd_11_brType = c_ibuffer_pd[11].brType;
  assign io_toIbuffer_bits_pd_12_isRVC  = c_ibuffer_pd[12].isRVC;
  assign io_toIbuffer_bits_pd_12_brType = c_ibuffer_pd[12].brType;
  assign io_toIbuffer_bits_pd_13_isRVC  = c_ibuffer_pd[13].isRVC;
  assign io_toIbuffer_bits_pd_13_brType = c_ibuffer_pd[13].brType;
  assign io_toIbuffer_bits_pd_14_isRVC  = c_ibuffer_pd[14].isRVC;
  assign io_toIbuffer_bits_pd_14_brType = c_ibuffer_pd[14].brType;
  assign io_toIbuffer_bits_pd_15_isRVC  = c_ibuffer_pd[15].isRVC;
  assign io_toIbuffer_bits_pd_15_brType = c_ibuffer_pd[15].brType;
  assign io_toIbuffer_bits_foldpc_0 = c_ibuffer_foldpc[0];
  assign io_toIbuffer_bits_ftqOffset_0_valid = c_ibuffer_ftqOffset_valid[0];
  assign io_toIbuffer_bits_exceptionType_0 = c_ibuffer_exceptionType[0];
  assign io_toIbuffer_bits_crossPageIPFFix_0 = c_ibuffer_crossPageIPFFix[0];
  assign io_toIbuffer_bits_illegalInstr_0 = c_ibuffer_illegalInstr[0];
  assign io_toIbuffer_bits_triggered_0 = c_ibuffer_triggered[0];
  assign io_toIbuffer_bits_isLastInFtqEntry_0 = c_ibuffer_isLastInFtqEntry[0];
  assign io_toIbuffer_bits_pc_0 = c_ibuffer_pc[0];
  assign io_toIbuffer_bits_foldpc_1 = c_ibuffer_foldpc[1];
  assign io_toIbuffer_bits_ftqOffset_1_valid = c_ibuffer_ftqOffset_valid[1];
  assign io_toIbuffer_bits_exceptionType_1 = c_ibuffer_exceptionType[1];
  assign io_toIbuffer_bits_crossPageIPFFix_1 = c_ibuffer_crossPageIPFFix[1];
  assign io_toIbuffer_bits_illegalInstr_1 = c_ibuffer_illegalInstr[1];
  assign io_toIbuffer_bits_triggered_1 = c_ibuffer_triggered[1];
  assign io_toIbuffer_bits_isLastInFtqEntry_1 = c_ibuffer_isLastInFtqEntry[1];
  assign io_toIbuffer_bits_pc_1 = c_ibuffer_pc[1];
  assign io_toIbuffer_bits_foldpc_2 = c_ibuffer_foldpc[2];
  assign io_toIbuffer_bits_ftqOffset_2_valid = c_ibuffer_ftqOffset_valid[2];
  assign io_toIbuffer_bits_exceptionType_2 = c_ibuffer_exceptionType[2];
  assign io_toIbuffer_bits_crossPageIPFFix_2 = c_ibuffer_crossPageIPFFix[2];
  assign io_toIbuffer_bits_illegalInstr_2 = c_ibuffer_illegalInstr[2];
  assign io_toIbuffer_bits_triggered_2 = c_ibuffer_triggered[2];
  assign io_toIbuffer_bits_isLastInFtqEntry_2 = c_ibuffer_isLastInFtqEntry[2];
  assign io_toIbuffer_bits_pc_2 = c_ibuffer_pc[2];
  assign io_toIbuffer_bits_foldpc_3 = c_ibuffer_foldpc[3];
  assign io_toIbuffer_bits_ftqOffset_3_valid = c_ibuffer_ftqOffset_valid[3];
  assign io_toIbuffer_bits_exceptionType_3 = c_ibuffer_exceptionType[3];
  assign io_toIbuffer_bits_crossPageIPFFix_3 = c_ibuffer_crossPageIPFFix[3];
  assign io_toIbuffer_bits_illegalInstr_3 = c_ibuffer_illegalInstr[3];
  assign io_toIbuffer_bits_triggered_3 = c_ibuffer_triggered[3];
  assign io_toIbuffer_bits_isLastInFtqEntry_3 = c_ibuffer_isLastInFtqEntry[3];
  assign io_toIbuffer_bits_pc_3 = c_ibuffer_pc[3];
  assign io_toIbuffer_bits_foldpc_4 = c_ibuffer_foldpc[4];
  assign io_toIbuffer_bits_ftqOffset_4_valid = c_ibuffer_ftqOffset_valid[4];
  assign io_toIbuffer_bits_exceptionType_4 = c_ibuffer_exceptionType[4];
  assign io_toIbuffer_bits_crossPageIPFFix_4 = c_ibuffer_crossPageIPFFix[4];
  assign io_toIbuffer_bits_illegalInstr_4 = c_ibuffer_illegalInstr[4];
  assign io_toIbuffer_bits_triggered_4 = c_ibuffer_triggered[4];
  assign io_toIbuffer_bits_isLastInFtqEntry_4 = c_ibuffer_isLastInFtqEntry[4];
  assign io_toIbuffer_bits_pc_4 = c_ibuffer_pc[4];
  assign io_toIbuffer_bits_foldpc_5 = c_ibuffer_foldpc[5];
  assign io_toIbuffer_bits_ftqOffset_5_valid = c_ibuffer_ftqOffset_valid[5];
  assign io_toIbuffer_bits_exceptionType_5 = c_ibuffer_exceptionType[5];
  assign io_toIbuffer_bits_crossPageIPFFix_5 = c_ibuffer_crossPageIPFFix[5];
  assign io_toIbuffer_bits_illegalInstr_5 = c_ibuffer_illegalInstr[5];
  assign io_toIbuffer_bits_triggered_5 = c_ibuffer_triggered[5];
  assign io_toIbuffer_bits_isLastInFtqEntry_5 = c_ibuffer_isLastInFtqEntry[5];
  assign io_toIbuffer_bits_pc_5 = c_ibuffer_pc[5];
  assign io_toIbuffer_bits_foldpc_6 = c_ibuffer_foldpc[6];
  assign io_toIbuffer_bits_ftqOffset_6_valid = c_ibuffer_ftqOffset_valid[6];
  assign io_toIbuffer_bits_exceptionType_6 = c_ibuffer_exceptionType[6];
  assign io_toIbuffer_bits_crossPageIPFFix_6 = c_ibuffer_crossPageIPFFix[6];
  assign io_toIbuffer_bits_illegalInstr_6 = c_ibuffer_illegalInstr[6];
  assign io_toIbuffer_bits_triggered_6 = c_ibuffer_triggered[6];
  assign io_toIbuffer_bits_isLastInFtqEntry_6 = c_ibuffer_isLastInFtqEntry[6];
  assign io_toIbuffer_bits_pc_6 = c_ibuffer_pc[6];
  assign io_toIbuffer_bits_foldpc_7 = c_ibuffer_foldpc[7];
  assign io_toIbuffer_bits_ftqOffset_7_valid = c_ibuffer_ftqOffset_valid[7];
  assign io_toIbuffer_bits_exceptionType_7 = c_ibuffer_exceptionType[7];
  assign io_toIbuffer_bits_crossPageIPFFix_7 = c_ibuffer_crossPageIPFFix[7];
  assign io_toIbuffer_bits_illegalInstr_7 = c_ibuffer_illegalInstr[7];
  assign io_toIbuffer_bits_triggered_7 = c_ibuffer_triggered[7];
  assign io_toIbuffer_bits_isLastInFtqEntry_7 = c_ibuffer_isLastInFtqEntry[7];
  assign io_toIbuffer_bits_pc_7 = c_ibuffer_pc[7];
  assign io_toIbuffer_bits_foldpc_8 = c_ibuffer_foldpc[8];
  assign io_toIbuffer_bits_ftqOffset_8_valid = c_ibuffer_ftqOffset_valid[8];
  assign io_toIbuffer_bits_exceptionType_8 = c_ibuffer_exceptionType[8];
  assign io_toIbuffer_bits_crossPageIPFFix_8 = c_ibuffer_crossPageIPFFix[8];
  assign io_toIbuffer_bits_illegalInstr_8 = c_ibuffer_illegalInstr[8];
  assign io_toIbuffer_bits_triggered_8 = c_ibuffer_triggered[8];
  assign io_toIbuffer_bits_isLastInFtqEntry_8 = c_ibuffer_isLastInFtqEntry[8];
  assign io_toIbuffer_bits_pc_8 = c_ibuffer_pc[8];
  assign io_toIbuffer_bits_foldpc_9 = c_ibuffer_foldpc[9];
  assign io_toIbuffer_bits_ftqOffset_9_valid = c_ibuffer_ftqOffset_valid[9];
  assign io_toIbuffer_bits_exceptionType_9 = c_ibuffer_exceptionType[9];
  assign io_toIbuffer_bits_crossPageIPFFix_9 = c_ibuffer_crossPageIPFFix[9];
  assign io_toIbuffer_bits_illegalInstr_9 = c_ibuffer_illegalInstr[9];
  assign io_toIbuffer_bits_triggered_9 = c_ibuffer_triggered[9];
  assign io_toIbuffer_bits_isLastInFtqEntry_9 = c_ibuffer_isLastInFtqEntry[9];
  assign io_toIbuffer_bits_pc_9 = c_ibuffer_pc[9];
  assign io_toIbuffer_bits_foldpc_10 = c_ibuffer_foldpc[10];
  assign io_toIbuffer_bits_ftqOffset_10_valid = c_ibuffer_ftqOffset_valid[10];
  assign io_toIbuffer_bits_exceptionType_10 = c_ibuffer_exceptionType[10];
  assign io_toIbuffer_bits_crossPageIPFFix_10 = c_ibuffer_crossPageIPFFix[10];
  assign io_toIbuffer_bits_illegalInstr_10 = c_ibuffer_illegalInstr[10];
  assign io_toIbuffer_bits_triggered_10 = c_ibuffer_triggered[10];
  assign io_toIbuffer_bits_isLastInFtqEntry_10 = c_ibuffer_isLastInFtqEntry[10];
  assign io_toIbuffer_bits_pc_10 = c_ibuffer_pc[10];
  assign io_toIbuffer_bits_foldpc_11 = c_ibuffer_foldpc[11];
  assign io_toIbuffer_bits_ftqOffset_11_valid = c_ibuffer_ftqOffset_valid[11];
  assign io_toIbuffer_bits_exceptionType_11 = c_ibuffer_exceptionType[11];
  assign io_toIbuffer_bits_crossPageIPFFix_11 = c_ibuffer_crossPageIPFFix[11];
  assign io_toIbuffer_bits_illegalInstr_11 = c_ibuffer_illegalInstr[11];
  assign io_toIbuffer_bits_triggered_11 = c_ibuffer_triggered[11];
  assign io_toIbuffer_bits_isLastInFtqEntry_11 = c_ibuffer_isLastInFtqEntry[11];
  assign io_toIbuffer_bits_pc_11 = c_ibuffer_pc[11];
  assign io_toIbuffer_bits_foldpc_12 = c_ibuffer_foldpc[12];
  assign io_toIbuffer_bits_ftqOffset_12_valid = c_ibuffer_ftqOffset_valid[12];
  assign io_toIbuffer_bits_exceptionType_12 = c_ibuffer_exceptionType[12];
  assign io_toIbuffer_bits_crossPageIPFFix_12 = c_ibuffer_crossPageIPFFix[12];
  assign io_toIbuffer_bits_illegalInstr_12 = c_ibuffer_illegalInstr[12];
  assign io_toIbuffer_bits_triggered_12 = c_ibuffer_triggered[12];
  assign io_toIbuffer_bits_isLastInFtqEntry_12 = c_ibuffer_isLastInFtqEntry[12];
  assign io_toIbuffer_bits_pc_12 = c_ibuffer_pc[12];
  assign io_toIbuffer_bits_foldpc_13 = c_ibuffer_foldpc[13];
  assign io_toIbuffer_bits_ftqOffset_13_valid = c_ibuffer_ftqOffset_valid[13];
  assign io_toIbuffer_bits_exceptionType_13 = c_ibuffer_exceptionType[13];
  assign io_toIbuffer_bits_crossPageIPFFix_13 = c_ibuffer_crossPageIPFFix[13];
  assign io_toIbuffer_bits_illegalInstr_13 = c_ibuffer_illegalInstr[13];
  assign io_toIbuffer_bits_triggered_13 = c_ibuffer_triggered[13];
  assign io_toIbuffer_bits_isLastInFtqEntry_13 = c_ibuffer_isLastInFtqEntry[13];
  assign io_toIbuffer_bits_pc_13 = c_ibuffer_pc[13];
  assign io_toIbuffer_bits_foldpc_14 = c_ibuffer_foldpc[14];
  assign io_toIbuffer_bits_ftqOffset_14_valid = c_ibuffer_ftqOffset_valid[14];
  assign io_toIbuffer_bits_exceptionType_14 = c_ibuffer_exceptionType[14];
  assign io_toIbuffer_bits_crossPageIPFFix_14 = c_ibuffer_crossPageIPFFix[14];
  assign io_toIbuffer_bits_illegalInstr_14 = c_ibuffer_illegalInstr[14];
  assign io_toIbuffer_bits_triggered_14 = c_ibuffer_triggered[14];
  assign io_toIbuffer_bits_isLastInFtqEntry_14 = c_ibuffer_isLastInFtqEntry[14];
  assign io_toIbuffer_bits_pc_14 = c_ibuffer_pc[14];
  assign io_toIbuffer_bits_foldpc_15 = c_ibuffer_foldpc[15];
  assign io_toIbuffer_bits_ftqOffset_15_valid = c_ibuffer_ftqOffset_valid[15];
  assign io_toIbuffer_bits_exceptionType_15 = c_ibuffer_exceptionType[15];
  assign io_toIbuffer_bits_crossPageIPFFix_15 = c_ibuffer_crossPageIPFFix[15];
  assign io_toIbuffer_bits_illegalInstr_15 = c_ibuffer_illegalInstr[15];
  assign io_toIbuffer_bits_triggered_15 = c_ibuffer_triggered[15];
  assign io_toIbuffer_bits_isLastInFtqEntry_15 = c_ibuffer_isLastInFtqEntry[15];
  assign io_toIbuffer_bits_pc_15 = c_ibuffer_pc[15];
  assign io_toIbuffer_bits_backendException_0 = c_ibuffer_backendException[0];
  assign io_toIbuffer_bits_topdown_info_reasons_0 = c_ibuffer_topdown_reasons[0];
  assign io_toIbuffer_bits_topdown_info_reasons_1 = c_ibuffer_topdown_reasons[1];
  assign io_toIbuffer_bits_topdown_info_reasons_2 = c_ibuffer_topdown_reasons[2];
  assign io_toIbuffer_bits_topdown_info_reasons_3 = c_ibuffer_topdown_reasons[3];
  assign io_toIbuffer_bits_topdown_info_reasons_4 = c_ibuffer_topdown_reasons[4];
  assign io_toIbuffer_bits_topdown_info_reasons_5 = c_ibuffer_topdown_reasons[5];
  assign io_toIbuffer_bits_topdown_info_reasons_6 = c_ibuffer_topdown_reasons[6];
  assign io_toIbuffer_bits_topdown_info_reasons_7 = c_ibuffer_topdown_reasons[7];
  assign io_toIbuffer_bits_topdown_info_reasons_8 = c_ibuffer_topdown_reasons[8];
  assign io_toIbuffer_bits_topdown_info_reasons_9 = c_ibuffer_topdown_reasons[9];
  assign io_toIbuffer_bits_topdown_info_reasons_10 = c_ibuffer_topdown_reasons[10];
  assign io_toIbuffer_bits_topdown_info_reasons_11 = c_ibuffer_topdown_reasons[11];
  assign io_toIbuffer_bits_topdown_info_reasons_12 = c_ibuffer_topdown_reasons[12];
  assign io_toIbuffer_bits_topdown_info_reasons_13 = c_ibuffer_topdown_reasons[13];
  assign io_toIbuffer_bits_topdown_info_reasons_14 = c_ibuffer_topdown_reasons[14];
  assign io_toIbuffer_bits_topdown_info_reasons_15 = c_ibuffer_topdown_reasons[15];
  assign io_toIbuffer_bits_topdown_info_reasons_16 = c_ibuffer_topdown_reasons[16];
  assign io_toIbuffer_bits_topdown_info_reasons_17 = c_ibuffer_topdown_reasons[17];
  assign io_toIbuffer_bits_topdown_info_reasons_18 = c_ibuffer_topdown_reasons[18];
  assign io_toIbuffer_bits_topdown_info_reasons_19 = c_ibuffer_topdown_reasons[19];
  assign io_toIbuffer_bits_topdown_info_reasons_20 = c_ibuffer_topdown_reasons[20];
  assign io_toIbuffer_bits_topdown_info_reasons_21 = c_ibuffer_topdown_reasons[21];
  assign io_toIbuffer_bits_topdown_info_reasons_22 = c_ibuffer_topdown_reasons[22];
  assign io_toIbuffer_bits_topdown_info_reasons_23 = c_ibuffer_topdown_reasons[23];
  assign io_toIbuffer_bits_topdown_info_reasons_24 = c_ibuffer_topdown_reasons[24];
  assign io_toIbuffer_bits_topdown_info_reasons_25 = c_ibuffer_topdown_reasons[25];
  assign io_toIbuffer_bits_topdown_info_reasons_26 = c_ibuffer_topdown_reasons[26];
  assign io_toIbuffer_bits_topdown_info_reasons_27 = c_ibuffer_topdown_reasons[27];
  assign io_toIbuffer_bits_topdown_info_reasons_28 = c_ibuffer_topdown_reasons[28];
  assign io_toIbuffer_bits_topdown_info_reasons_29 = c_ibuffer_topdown_reasons[29];
  assign io_toIbuffer_bits_topdown_info_reasons_30 = c_ibuffer_topdown_reasons[30];
  assign io_toIbuffer_bits_topdown_info_reasons_31 = c_ibuffer_topdown_reasons[31];
  assign io_toIbuffer_bits_topdown_info_reasons_32 = c_ibuffer_topdown_reasons[32];
  assign io_toIbuffer_bits_topdown_info_reasons_33 = c_ibuffer_topdown_reasons[33];
  assign io_toIbuffer_bits_topdown_info_reasons_34 = c_ibuffer_topdown_reasons[34];
  assign io_toIbuffer_bits_topdown_info_reasons_35 = c_ibuffer_topdown_reasons[35];
  assign io_toIbuffer_bits_topdown_info_reasons_36 = c_ibuffer_topdown_reasons[36];
  assign io_toIbuffer_bits_topdown_info_reasons_37 = c_ibuffer_topdown_reasons[37];
  assign io_perf_0_value = c_perf_value[0];
  assign io_perf_1_value = c_perf_value[1];
  assign io_perf_2_value = c_perf_value[2];
  assign io_perf_3_value = c_perf_value[3];
  assign io_perf_4_value = c_perf_value[4];
  assign io_perf_5_value = c_perf_value[5];
  assign io_perf_6_value = c_perf_value[6];
  assign io_perf_7_value = c_perf_value[7];
  assign io_perf_8_value = c_perf_value[8];
  assign io_perf_9_value = c_perf_value[9];
  assign io_perf_10_value = c_perf_value[10];
  assign io_perf_11_value = c_perf_value[11];
  assign io_perf_12_value = c_perf_value[12];
endmodule
