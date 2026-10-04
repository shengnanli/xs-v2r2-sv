// Slice_2.sv —— CoupledL2（tl2chi）L2 第 2 个 slice（sliceId = 2）
//
// 薄 wrapper：逻辑全在 rtl/uncore/Slice.sv 的 xs_Slice_core（文件头讲清 slice 的数据流）。本变体与
// Slice 的差别只有：给 TXREQ 的 sliceId = 2；目录 / 数据阵列 / MBIST 分发用 Directory_2 /
// DataStorage_2 / L2Slice_2 这一组单态化（它们只差 MBIST 编号与 SRAM 宏实例）；MBIST bore 数组
// 位宽 6（目录路 5、数据阵列路 6）。golden Slice_2.sv 10,261 行，规模与 Slice 相同。
// 本文件由 scripts/gen_l2_slice.py 整份生成（勿手改）；生成时核对四个 golden 变体只差上述维度。
//
// 本文件导航：
//   L531 §W1 核 <-> 目录（dir_*）/ 数据阵列（ds_*）的接口线
//   L1143 §W2 MBIST 分发线：mbistPl 的两路下行（路 0 -> 目录，路 1 -> 数据阵列）
//   L1167 §W3 可读核（本变体 SLICE_ID = 2）：除目录 / 数据阵列 / MBIST 分发外的全部 child 与本层逻辑
//   L2203 §W4 目录（tag / meta / 替换状态），本变体 = Directory_2
//   L2877 §W5 数据阵列，本变体 = DataStorage_2
//   L2930 §W6 MBIST 分发（L2Slice_2）：顶层 bore -> 目录（路 0）/ 数据阵列（路 1）

// BEGIN GENERATED(Slice_2) —— scripts/gen_l2_slice.py
module Slice_2(
  input            clock,
  input            reset,
  output           io_in_a_ready,
  input            io_in_a_valid,
  input  [3:0]     io_in_a_bits_opcode,
  input  [2:0]     io_in_a_bits_param,
  input  [2:0]     io_in_a_bits_size,
  input  [6:0]     io_in_a_bits_source,
  input  [47:0]    io_in_a_bits_address,
  input  [4:0]     io_in_a_bits_user_reqSource,
  input  [1:0]     io_in_a_bits_user_alias,
  input  [43:0]    io_in_a_bits_user_vaddr,
  input            io_in_a_bits_user_needHint,
  input            io_in_a_bits_echo_isKeyword,
  input            io_in_a_bits_corrupt,
  input            io_in_b_ready,
  output           io_in_b_valid,
  output [2:0]     io_in_b_bits_opcode,
  output [1:0]     io_in_b_bits_param,
  output [47:0]    io_in_b_bits_address,
  output [255:0]   io_in_b_bits_data,
  output           io_in_c_ready,
  input            io_in_c_valid,
  input  [2:0]     io_in_c_bits_opcode,
  input  [2:0]     io_in_c_bits_param,
  input  [2:0]     io_in_c_bits_size,
  input  [6:0]     io_in_c_bits_source,
  input  [47:0]    io_in_c_bits_address,
  input  [255:0]   io_in_c_bits_data,
  input            io_in_c_bits_corrupt,
  input            io_in_d_ready,
  output           io_in_d_valid,
  output [3:0]     io_in_d_bits_opcode,
  output [1:0]     io_in_d_bits_param,
  output [6:0]     io_in_d_bits_source,
  output [7:0]     io_in_d_bits_sink,
  output           io_in_d_bits_denied,
  output           io_in_d_bits_echo_isKeyword,
  output [255:0]   io_in_d_bits_data,
  output           io_in_d_bits_corrupt,
  input            io_in_e_valid,
  input  [7:0]     io_in_e_bits_sink,
  input            io_l1Hint_ready,
  output           io_l1Hint_valid,
  output [31:0]    io_l1Hint_bits_sourceId,
  output           io_l1Hint_bits_isKeyword,
  input            io_prefetch_train_ready,
  output           io_prefetch_train_valid,
  output [32:0]    io_prefetch_train_bits_tag,
  output [8:0]     io_prefetch_train_bits_set,
  output           io_prefetch_train_bits_needT,
  output [6:0]     io_prefetch_train_bits_source,
  output [43:0]    io_prefetch_train_bits_vaddr,
  output           io_prefetch_train_bits_hit,
  output           io_prefetch_train_bits_prefetched,
  output [2:0]     io_prefetch_train_bits_pfsource,
  output [4:0]     io_prefetch_train_bits_reqsource,
  output           io_prefetch_req_ready,
  input            io_prefetch_req_valid,
  input  [32:0]    io_prefetch_req_bits_tag,
  input  [8:0]     io_prefetch_req_bits_set,
  input  [43:0]    io_prefetch_req_bits_vaddr,
  input            io_prefetch_req_bits_needT,
  input  [6:0]     io_prefetch_req_bits_source,
  input  [4:0]     io_prefetch_req_bits_pfSource,
  input            io_prefetch_resp_ready,
  output           io_prefetch_resp_valid,
  output [32:0]    io_prefetch_resp_bits_tag,
  output [8:0]     io_prefetch_resp_bits_set,
  output [43:0]    io_prefetch_resp_bits_vaddr,
  output [4:0]     io_prefetch_resp_bits_pfSource,
  output           io_dirResult_valid,
  output           io_dirResult_bits_hit,
  output           io_dirResult_bits_meta_prefetch,
  output [2:0]     io_dirResult_bits_meta_prefetchSrc,
  output [2:0]     io_dirResult_bits_replacerInfo_channel,
  output [4:0]     io_dirResult_bits_replacerInfo_reqSource,
  output           io_hitPfInMSHR_valid,
  output [2:0]     io_hitPfInMSHR_bits,
  output           io_pfSent_valid,
  output [4:0]     io_pfSent_bits,
  output           io_pfLateInMSHR_valid,
  output [4:0]     io_pfLateInMSHR_bits,
  output           io_error_valid,
  output           io_error_bits_valid,
  output [45:0]    io_error_bits_address,
  output           io_l2Miss,
  output           io_msStatus_0_valid,
  output [2:0]     io_msStatus_0_bits_channel,
  output [8:0]     io_msStatus_0_bits_set,
  output [30:0]    io_msStatus_0_bits_reqTag,
  output           io_msStatus_0_bits_is_miss,
  output           io_msStatus_0_bits_is_prefetch,
  output           io_msStatus_1_valid,
  output [2:0]     io_msStatus_1_bits_channel,
  output [8:0]     io_msStatus_1_bits_set,
  output [30:0]    io_msStatus_1_bits_reqTag,
  output           io_msStatus_1_bits_is_miss,
  output           io_msStatus_1_bits_is_prefetch,
  output           io_msStatus_2_valid,
  output [2:0]     io_msStatus_2_bits_channel,
  output [8:0]     io_msStatus_2_bits_set,
  output [30:0]    io_msStatus_2_bits_reqTag,
  output           io_msStatus_2_bits_is_miss,
  output           io_msStatus_2_bits_is_prefetch,
  output           io_msStatus_3_valid,
  output [2:0]     io_msStatus_3_bits_channel,
  output [8:0]     io_msStatus_3_bits_set,
  output [30:0]    io_msStatus_3_bits_reqTag,
  output           io_msStatus_3_bits_is_miss,
  output           io_msStatus_3_bits_is_prefetch,
  output           io_msStatus_4_valid,
  output [2:0]     io_msStatus_4_bits_channel,
  output [8:0]     io_msStatus_4_bits_set,
  output [30:0]    io_msStatus_4_bits_reqTag,
  output           io_msStatus_4_bits_is_miss,
  output           io_msStatus_4_bits_is_prefetch,
  output           io_msStatus_5_valid,
  output [2:0]     io_msStatus_5_bits_channel,
  output [8:0]     io_msStatus_5_bits_set,
  output [30:0]    io_msStatus_5_bits_reqTag,
  output           io_msStatus_5_bits_is_miss,
  output           io_msStatus_5_bits_is_prefetch,
  output           io_msStatus_6_valid,
  output [2:0]     io_msStatus_6_bits_channel,
  output [8:0]     io_msStatus_6_bits_set,
  output [30:0]    io_msStatus_6_bits_reqTag,
  output           io_msStatus_6_bits_is_miss,
  output           io_msStatus_6_bits_is_prefetch,
  output           io_msStatus_7_valid,
  output [2:0]     io_msStatus_7_bits_channel,
  output [8:0]     io_msStatus_7_bits_set,
  output [30:0]    io_msStatus_7_bits_reqTag,
  output           io_msStatus_7_bits_is_miss,
  output           io_msStatus_7_bits_is_prefetch,
  output           io_msStatus_8_valid,
  output [2:0]     io_msStatus_8_bits_channel,
  output [8:0]     io_msStatus_8_bits_set,
  output [30:0]    io_msStatus_8_bits_reqTag,
  output           io_msStatus_8_bits_is_miss,
  output           io_msStatus_8_bits_is_prefetch,
  output           io_msStatus_9_valid,
  output [2:0]     io_msStatus_9_bits_channel,
  output [8:0]     io_msStatus_9_bits_set,
  output [30:0]    io_msStatus_9_bits_reqTag,
  output           io_msStatus_9_bits_is_miss,
  output           io_msStatus_9_bits_is_prefetch,
  output           io_msStatus_10_valid,
  output [2:0]     io_msStatus_10_bits_channel,
  output [8:0]     io_msStatus_10_bits_set,
  output [30:0]    io_msStatus_10_bits_reqTag,
  output           io_msStatus_10_bits_is_miss,
  output           io_msStatus_10_bits_is_prefetch,
  output           io_msStatus_11_valid,
  output [2:0]     io_msStatus_11_bits_channel,
  output [8:0]     io_msStatus_11_bits_set,
  output [30:0]    io_msStatus_11_bits_reqTag,
  output           io_msStatus_11_bits_is_miss,
  output           io_msStatus_11_bits_is_prefetch,
  output           io_msStatus_12_valid,
  output [2:0]     io_msStatus_12_bits_channel,
  output [8:0]     io_msStatus_12_bits_set,
  output [30:0]    io_msStatus_12_bits_reqTag,
  output           io_msStatus_12_bits_is_miss,
  output           io_msStatus_12_bits_is_prefetch,
  output           io_msStatus_13_valid,
  output [2:0]     io_msStatus_13_bits_channel,
  output [8:0]     io_msStatus_13_bits_set,
  output [30:0]    io_msStatus_13_bits_reqTag,
  output           io_msStatus_13_bits_is_miss,
  output           io_msStatus_13_bits_is_prefetch,
  output           io_msStatus_14_valid,
  output [2:0]     io_msStatus_14_bits_channel,
  output [8:0]     io_msStatus_14_bits_set,
  output [30:0]    io_msStatus_14_bits_reqTag,
  output           io_msStatus_14_bits_is_miss,
  output           io_msStatus_14_bits_is_prefetch,
  output           io_msStatus_15_valid,
  output [2:0]     io_msStatus_15_bits_channel,
  output [8:0]     io_msStatus_15_bits_set,
  output [30:0]    io_msStatus_15_bits_reqTag,
  output           io_msStatus_15_bits_is_miss,
  output           io_msStatus_15_bits_is_prefetch,
  output           io_msAlloc_0_valid,
  output [2:0]     io_msAlloc_0_bits_channel,
  output           io_msAlloc_0_bits_is_miss,
  output           io_msAlloc_0_bits_is_prefetch,
  output           io_msAlloc_1_valid,
  output [2:0]     io_msAlloc_1_bits_channel,
  output           io_msAlloc_1_bits_is_miss,
  output           io_msAlloc_1_bits_is_prefetch,
  output           io_msAlloc_2_valid,
  output [2:0]     io_msAlloc_2_bits_channel,
  output           io_msAlloc_2_bits_is_miss,
  output           io_msAlloc_2_bits_is_prefetch,
  output           io_msAlloc_3_valid,
  output [2:0]     io_msAlloc_3_bits_channel,
  output           io_msAlloc_3_bits_is_miss,
  output           io_msAlloc_3_bits_is_prefetch,
  output           io_msAlloc_4_valid,
  output [2:0]     io_msAlloc_4_bits_channel,
  output           io_msAlloc_4_bits_is_miss,
  output           io_msAlloc_4_bits_is_prefetch,
  output           io_msAlloc_5_valid,
  output [2:0]     io_msAlloc_5_bits_channel,
  output           io_msAlloc_5_bits_is_miss,
  output           io_msAlloc_5_bits_is_prefetch,
  output           io_msAlloc_6_valid,
  output [2:0]     io_msAlloc_6_bits_channel,
  output           io_msAlloc_6_bits_is_miss,
  output           io_msAlloc_6_bits_is_prefetch,
  output           io_msAlloc_7_valid,
  output [2:0]     io_msAlloc_7_bits_channel,
  output           io_msAlloc_7_bits_is_miss,
  output           io_msAlloc_7_bits_is_prefetch,
  output           io_msAlloc_8_valid,
  output [2:0]     io_msAlloc_8_bits_channel,
  output           io_msAlloc_8_bits_is_miss,
  output           io_msAlloc_8_bits_is_prefetch,
  output           io_msAlloc_9_valid,
  output [2:0]     io_msAlloc_9_bits_channel,
  output           io_msAlloc_9_bits_is_miss,
  output           io_msAlloc_9_bits_is_prefetch,
  output           io_msAlloc_10_valid,
  output [2:0]     io_msAlloc_10_bits_channel,
  output           io_msAlloc_10_bits_is_miss,
  output           io_msAlloc_10_bits_is_prefetch,
  output           io_msAlloc_11_valid,
  output [2:0]     io_msAlloc_11_bits_channel,
  output           io_msAlloc_11_bits_is_miss,
  output           io_msAlloc_11_bits_is_prefetch,
  output           io_msAlloc_12_valid,
  output [2:0]     io_msAlloc_12_bits_channel,
  output           io_msAlloc_12_bits_is_miss,
  output           io_msAlloc_12_bits_is_prefetch,
  output           io_msAlloc_13_valid,
  output [2:0]     io_msAlloc_13_bits_channel,
  output           io_msAlloc_13_bits_is_miss,
  output           io_msAlloc_13_bits_is_prefetch,
  output           io_msAlloc_14_valid,
  output [2:0]     io_msAlloc_14_bits_channel,
  output           io_msAlloc_14_bits_is_miss,
  output           io_msAlloc_14_bits_is_prefetch,
  output           io_msAlloc_15_valid,
  output [2:0]     io_msAlloc_15_bits_channel,
  output           io_msAlloc_15_bits_is_miss,
  output           io_msAlloc_15_bits_is_prefetch,
  input            io_out_tx_req_ready,
  output           io_out_tx_req_valid,
  output [3:0]     io_out_tx_req_bits_qos,
  output [11:0]    io_out_tx_req_bits_txnID,
  output [10:0]    io_out_tx_req_bits_returnNID,
  output           io_out_tx_req_bits_stashNIDValid,
  output [11:0]    io_out_tx_req_bits_returnTxnID,
  output [6:0]     io_out_tx_req_bits_opcode,
  output [47:0]    io_out_tx_req_bits_addr,
  output           io_out_tx_req_bits_ns,
  output           io_out_tx_req_bits_likelyshared,
  output           io_out_tx_req_bits_allowRetry,
  output [1:0]     io_out_tx_req_bits_order,
  output [3:0]     io_out_tx_req_bits_pCrdType,
  output           io_out_tx_req_bits_memAttr_allocate,
  output           io_out_tx_req_bits_memAttr_cacheable,
  output           io_out_tx_req_bits_memAttr_device,
  output           io_out_tx_req_bits_memAttr_ewa,
  output           io_out_tx_req_bits_snpAttr,
  output [7:0]     io_out_tx_req_bits_lpIDWithPadding,
  output           io_out_tx_req_bits_snoopMe,
  output           io_out_tx_req_bits_expCompAck,
  output [1:0]     io_out_tx_req_bits_tagOp,
  output           io_out_tx_req_bits_traceTag,
  output           io_out_tx_req_bits_mpam_perfMonGroup,
  output [8:0]     io_out_tx_req_bits_mpam_partID,
  output           io_out_tx_req_bits_mpam_mpamNS,
  output [3:0]     io_out_tx_req_bits_rsvdc,
  input            io_out_tx_rsp_ready,
  output           io_out_tx_rsp_valid,
  output [3:0]     io_out_tx_rsp_bits_qos,
  output [10:0]    io_out_tx_rsp_bits_tgtID,
  output [11:0]    io_out_tx_rsp_bits_txnID,
  output [4:0]     io_out_tx_rsp_bits_opcode,
  output [1:0]     io_out_tx_rsp_bits_respErr,
  output [2:0]     io_out_tx_rsp_bits_resp,
  output [2:0]     io_out_tx_rsp_bits_fwdState,
  output [2:0]     io_out_tx_rsp_bits_cBusy,
  output [11:0]    io_out_tx_rsp_bits_dbID,
  output [3:0]     io_out_tx_rsp_bits_pCrdType,
  output [1:0]     io_out_tx_rsp_bits_tagOp,
  output           io_out_tx_rsp_bits_traceTag,
  input            io_out_tx_dat_ready,
  output           io_out_tx_dat_valid,
  output [10:0]    io_out_tx_dat_bits_tgtID,
  output [11:0]    io_out_tx_dat_bits_txnID,
  output [10:0]    io_out_tx_dat_bits_homeNID,
  output [3:0]     io_out_tx_dat_bits_opcode,
  output [1:0]     io_out_tx_dat_bits_respErr,
  output [2:0]     io_out_tx_dat_bits_resp,
  output [3:0]     io_out_tx_dat_bits_dataSource,
  output [11:0]    io_out_tx_dat_bits_dbID,
  output [1:0]     io_out_tx_dat_bits_ccID,
  output [1:0]     io_out_tx_dat_bits_dataID,
  output           io_out_tx_dat_bits_traceTag,
  output [31:0]    io_out_tx_dat_bits_be,
  output [255:0]   io_out_tx_dat_bits_data,
  output [31:0]    io_out_tx_dat_bits_dataCheck,
  output [3:0]     io_out_tx_dat_bits_poison,
  input            io_out_rx_rsp_valid,
  input  [10:0]    io_out_rx_rsp_bits_srcID,
  input  [11:0]    io_out_rx_rsp_bits_txnID,
  input  [4:0]     io_out_rx_rsp_bits_opcode,
  input  [1:0]     io_out_rx_rsp_bits_respErr,
  input  [2:0]     io_out_rx_rsp_bits_resp,
  input  [11:0]    io_out_rx_rsp_bits_dbID,
  input  [3:0]     io_out_rx_rsp_bits_pCrdType,
  input            io_out_rx_rsp_bits_traceTag,
  input            io_out_rx_dat_valid,
  input  [11:0]    io_out_rx_dat_bits_txnID,
  input  [10:0]    io_out_rx_dat_bits_homeNID,
  input  [3:0]     io_out_rx_dat_bits_opcode,
  input  [1:0]     io_out_rx_dat_bits_respErr,
  input  [2:0]     io_out_rx_dat_bits_resp,
  input  [11:0]    io_out_rx_dat_bits_dbID,
  input  [1:0]     io_out_rx_dat_bits_dataID,
  input            io_out_rx_dat_bits_traceTag,
  input  [255:0]   io_out_rx_dat_bits_data,
  input  [31:0]    io_out_rx_dat_bits_dataCheck,
  input  [3:0]     io_out_rx_dat_bits_poison,
  output           io_out_rx_snp_ready,
  input            io_out_rx_snp_valid,
  input  [3:0]     io_out_rx_snp_bits_qos,
  input  [10:0]    io_out_rx_snp_bits_srcID,
  input  [11:0]    io_out_rx_snp_bits_txnID,
  input  [10:0]    io_out_rx_snp_bits_fwdNID,
  input  [11:0]    io_out_rx_snp_bits_fwdTxnID,
  input  [4:0]     io_out_rx_snp_bits_opcode,
  input  [44:0]    io_out_rx_snp_bits_addr,
  input            io_out_rx_snp_bits_ns,
  input            io_out_rx_snp_bits_doNotGoToSD,
  input            io_out_rx_snp_bits_retToSrc,
  input            io_out_rx_snp_bits_traceTag,
  input            io_out_rx_snp_bits_mpam_perfMonGroup,
  input  [8:0]     io_out_rx_snp_bits_mpam_partID,
  input            io_out_rx_snp_bits_mpam_mpamNS,
  output           io_pCrd_0_query_valid,
  output [3:0]     io_pCrd_0_query_bits_pCrdType,
  output [10:0]    io_pCrd_0_query_bits_srcID,
  input            io_pCrd_0_grant,
  output           io_pCrd_1_query_valid,
  output [3:0]     io_pCrd_1_query_bits_pCrdType,
  output [10:0]    io_pCrd_1_query_bits_srcID,
  input            io_pCrd_1_grant,
  output           io_pCrd_2_query_valid,
  output [3:0]     io_pCrd_2_query_bits_pCrdType,
  output [10:0]    io_pCrd_2_query_bits_srcID,
  input            io_pCrd_2_grant,
  output           io_pCrd_3_query_valid,
  output [3:0]     io_pCrd_3_query_bits_pCrdType,
  output [10:0]    io_pCrd_3_query_bits_srcID,
  input            io_pCrd_3_grant,
  output           io_pCrd_4_query_valid,
  output [3:0]     io_pCrd_4_query_bits_pCrdType,
  output [10:0]    io_pCrd_4_query_bits_srcID,
  input            io_pCrd_4_grant,
  output           io_pCrd_5_query_valid,
  output [3:0]     io_pCrd_5_query_bits_pCrdType,
  output [10:0]    io_pCrd_5_query_bits_srcID,
  input            io_pCrd_5_grant,
  output           io_pCrd_6_query_valid,
  output [3:0]     io_pCrd_6_query_bits_pCrdType,
  output [10:0]    io_pCrd_6_query_bits_srcID,
  input            io_pCrd_6_grant,
  output           io_pCrd_7_query_valid,
  output [3:0]     io_pCrd_7_query_bits_pCrdType,
  output [10:0]    io_pCrd_7_query_bits_srcID,
  input            io_pCrd_7_grant,
  output           io_pCrd_8_query_valid,
  output [3:0]     io_pCrd_8_query_bits_pCrdType,
  output [10:0]    io_pCrd_8_query_bits_srcID,
  input            io_pCrd_8_grant,
  output           io_pCrd_9_query_valid,
  output [3:0]     io_pCrd_9_query_bits_pCrdType,
  output [10:0]    io_pCrd_9_query_bits_srcID,
  input            io_pCrd_9_grant,
  output           io_pCrd_10_query_valid,
  output [3:0]     io_pCrd_10_query_bits_pCrdType,
  output [10:0]    io_pCrd_10_query_bits_srcID,
  input            io_pCrd_10_grant,
  output           io_pCrd_11_query_valid,
  output [3:0]     io_pCrd_11_query_bits_pCrdType,
  output [10:0]    io_pCrd_11_query_bits_srcID,
  input            io_pCrd_11_grant,
  output           io_pCrd_12_query_valid,
  output [3:0]     io_pCrd_12_query_bits_pCrdType,
  output [10:0]    io_pCrd_12_query_bits_srcID,
  input            io_pCrd_12_grant,
  output           io_pCrd_13_query_valid,
  output [3:0]     io_pCrd_13_query_bits_pCrdType,
  output [10:0]    io_pCrd_13_query_bits_srcID,
  input            io_pCrd_13_grant,
  output           io_pCrd_14_query_valid,
  output [3:0]     io_pCrd_14_query_bits_pCrdType,
  output [10:0]    io_pCrd_14_query_bits_srcID,
  input            io_pCrd_14_grant,
  output           io_pCrd_15_query_valid,
  output [3:0]     io_pCrd_15_query_bits_pCrdType,
  output [10:0]    io_pCrd_15_query_bits_srcID,
  input            io_pCrd_15_grant,
  output [5:0]     io_perf_0_value,
  output [5:0]     io_perf_1_value,
  output [5:0]     io_perf_3_value,
  output [5:0]     io_perf_4_value,
  output [5:0]     io_perf_5_value,
  output [5:0]     io_perf_6_value,
  output [5:0]     io_perf_7_value,
  output [5:0]     io_perf_8_value,
  output [5:0]     io_perf_9_value,
  output [5:0]     io_perf_10_value,
  output [5:0]     io_perf_11_value,
  output [5:0]     io_perf_12_value,
  output [5:0]     io_perf_13_value,
  output [5:0]     io_perf_14_value,
  output [5:0]     io_perf_15_value,
  output [5:0]     io_perf_16_value,
  input            sigFromSrams_bore_ram_hold,
  input            sigFromSrams_bore_ram_bypass,
  input            sigFromSrams_bore_ram_bp_clken,
  input            sigFromSrams_bore_ram_aux_clk,
  input            sigFromSrams_bore_ram_aux_ckbp,
  input            sigFromSrams_bore_ram_mcp_hold,
  input            sigFromSrams_bore_cgen,
  input            sigFromSrams_bore_1_ram_hold,
  input            sigFromSrams_bore_1_ram_bypass,
  input            sigFromSrams_bore_1_ram_bp_clken,
  input            sigFromSrams_bore_1_ram_aux_clk,
  input            sigFromSrams_bore_1_ram_aux_ckbp,
  input            sigFromSrams_bore_1_ram_mcp_hold,
  input            sigFromSrams_bore_1_cgen,
  input            sigFromSrams_bore_2_ram_hold,
  input            sigFromSrams_bore_2_ram_bypass,
  input            sigFromSrams_bore_2_ram_bp_clken,
  input            sigFromSrams_bore_2_ram_aux_clk,
  input            sigFromSrams_bore_2_ram_aux_ckbp,
  input            sigFromSrams_bore_2_ram_mcp_hold,
  input            sigFromSrams_bore_2_cgen,
  input            sigFromSrams_bore_3_ram_hold,
  input            sigFromSrams_bore_3_ram_bypass,
  input            sigFromSrams_bore_3_ram_bp_clken,
  input            sigFromSrams_bore_3_ram_aux_clk,
  input            sigFromSrams_bore_3_ram_aux_ckbp,
  input            sigFromSrams_bore_3_ram_mcp_hold,
  input            sigFromSrams_bore_3_cgen,
  input            sigFromSrams_bore_4_ram_hold,
  input            sigFromSrams_bore_4_ram_bypass,
  input            sigFromSrams_bore_4_ram_bp_clken,
  input            sigFromSrams_bore_4_ram_aux_clk,
  input            sigFromSrams_bore_4_ram_aux_ckbp,
  input            sigFromSrams_bore_4_ram_mcp_hold,
  input            sigFromSrams_bore_4_cgen,
  input            sigFromSrams_bore_5_ram_hold,
  input            sigFromSrams_bore_5_ram_bypass,
  input            sigFromSrams_bore_5_ram_bp_clken,
  input            sigFromSrams_bore_5_ram_aux_clk,
  input            sigFromSrams_bore_5_ram_aux_ckbp,
  input            sigFromSrams_bore_5_ram_mcp_hold,
  input            sigFromSrams_bore_5_cgen,
  input            sigFromSrams_bore_6_ram_hold,
  input            sigFromSrams_bore_6_ram_bypass,
  input            sigFromSrams_bore_6_ram_bp_clken,
  input            sigFromSrams_bore_6_ram_aux_clk,
  input            sigFromSrams_bore_6_ram_aux_ckbp,
  input            sigFromSrams_bore_6_ram_mcp_hold,
  input            sigFromSrams_bore_6_cgen,
  input            sigFromSrams_bore_7_ram_hold,
  input            sigFromSrams_bore_7_ram_bypass,
  input            sigFromSrams_bore_7_ram_bp_clken,
  input            sigFromSrams_bore_7_ram_aux_clk,
  input            sigFromSrams_bore_7_ram_aux_ckbp,
  input            sigFromSrams_bore_7_ram_mcp_hold,
  input            sigFromSrams_bore_7_cgen,
  input            sigFromSrams_bore_8_ram_hold,
  input            sigFromSrams_bore_8_ram_bypass,
  input            sigFromSrams_bore_8_ram_bp_clken,
  input            sigFromSrams_bore_8_ram_aux_clk,
  input            sigFromSrams_bore_8_ram_aux_ckbp,
  input            sigFromSrams_bore_8_ram_mcp_hold,
  input            sigFromSrams_bore_8_cgen,
  input            sigFromSrams_bore_9_ram_hold,
  input            sigFromSrams_bore_9_ram_bypass,
  input            sigFromSrams_bore_9_ram_bp_clken,
  input            sigFromSrams_bore_9_ram_aux_clk,
  input            sigFromSrams_bore_9_ram_aux_ckbp,
  input            sigFromSrams_bore_9_ram_mcp_hold,
  input            sigFromSrams_bore_9_cgen,
  input            sigFromSrams_bore_10_ram_hold,
  input            sigFromSrams_bore_10_ram_bypass,
  input            sigFromSrams_bore_10_ram_bp_clken,
  input            sigFromSrams_bore_10_ram_aux_clk,
  input            sigFromSrams_bore_10_ram_aux_ckbp,
  input            sigFromSrams_bore_10_ram_mcp_hold,
  input            sigFromSrams_bore_10_cgen,
  input  [5:0]     boreChildrenBd_bore_array,
  input            boreChildrenBd_bore_all,
  input            boreChildrenBd_bore_req,
  output           boreChildrenBd_bore_ack,
  input            boreChildrenBd_bore_writeen,
  input  [7:0]     boreChildrenBd_bore_be,
  input  [12:0]    boreChildrenBd_bore_addr,
  input  [136:0]   boreChildrenBd_bore_indata,
  input            boreChildrenBd_bore_readen,
  input  [12:0]    boreChildrenBd_bore_addr_rd,
  output [136:0]   boreChildrenBd_bore_outdata
);
  // §W1 核 <-> 目录（dir_*）/ 数据阵列（ds_*）的接口线
  logic           dir_read_ready;
  logic           dir_read_valid;
  logic [30:0]    dir_read_bits_tag;
  logic [8:0]     dir_read_bits_set;
  logic [7:0]     dir_read_bits_wayMask;
  logic [2:0]     dir_read_bits_replacerInfo_channel;
  logic [2:0]     dir_read_bits_replacerInfo_opcode;
  logic [4:0]     dir_read_bits_replacerInfo_reqSource;
  logic           dir_read_bits_replacerInfo_refill_prefetch;
  logic           dir_read_bits_refill;
  logic [7:0]     dir_read_bits_mshrId;
  logic           dir_read_bits_cmoAll;
  logic [2:0]     dir_read_bits_cmoWay;
  logic           dir_resp_valid;
  logic           dir_resp_bits_hit;
  logic [30:0]    dir_resp_bits_tag;
  logic [8:0]     dir_resp_bits_set;
  logic [2:0]     dir_resp_bits_way;
  logic           dir_resp_bits_meta_dirty;
  logic [1:0]     dir_resp_bits_meta_state;
  logic           dir_resp_bits_meta_clients;
  logic [1:0]     dir_resp_bits_meta_alias;
  logic           dir_resp_bits_meta_prefetch;
  logic [2:0]     dir_resp_bits_meta_prefetchSrc;
  logic           dir_resp_bits_meta_accessed;
  logic           dir_resp_bits_meta_tagErr;
  logic           dir_resp_bits_meta_dataErr;
  logic           dir_resp_bits_error;
  logic           dir_metaWReq_valid;
  logic [8:0]     dir_metaWReq_bits_set;
  logic [7:0]     dir_metaWReq_bits_wayOH;
  logic           dir_metaWReq_bits_wmeta_dirty;
  logic [1:0]     dir_metaWReq_bits_wmeta_state;
  logic           dir_metaWReq_bits_wmeta_clients;
  logic [1:0]     dir_metaWReq_bits_wmeta_alias;
  logic           dir_metaWReq_bits_wmeta_prefetch;
  logic [2:0]     dir_metaWReq_bits_wmeta_prefetchSrc;
  logic           dir_metaWReq_bits_wmeta_accessed;
  logic           dir_metaWReq_bits_wmeta_tagErr;
  logic           dir_metaWReq_bits_wmeta_dataErr;
  logic           dir_tagWReq_valid;
  logic [8:0]     dir_tagWReq_bits_set;
  logic [2:0]     dir_tagWReq_bits_way;
  logic [30:0]    dir_tagWReq_bits_wtag;
  logic           dir_replResp_valid;
  logic [30:0]    dir_replResp_bits_tag;
  logic [2:0]     dir_replResp_bits_way;
  logic           dir_replResp_bits_meta_dirty;
  logic [1:0]     dir_replResp_bits_meta_state;
  logic           dir_replResp_bits_meta_clients;
  logic [1:0]     dir_replResp_bits_meta_alias;
  logic           dir_replResp_bits_meta_prefetch;
  logic [2:0]     dir_replResp_bits_meta_prefetchSrc;
  logic           dir_replResp_bits_meta_accessed;
  logic           dir_replResp_bits_meta_tagErr;
  logic           dir_replResp_bits_meta_dataErr;
  logic [7:0]     dir_replResp_bits_mshrId;
  logic           dir_replResp_bits_retry;
  logic           dir_replResp_bits_error;
  logic           dir_msInfo_0_valid;
  logic [2:0]     dir_msInfo_0_bits_channel;
  logic [8:0]     dir_msInfo_0_bits_set;
  logic [2:0]     dir_msInfo_0_bits_way;
  logic [30:0]    dir_msInfo_0_bits_reqTag;
  logic           dir_msInfo_0_bits_willFree;
  logic           dir_msInfo_0_bits_aliasTask;
  logic           dir_msInfo_0_bits_needRelease;
  logic           dir_msInfo_0_bits_blockRefill;
  logic           dir_msInfo_0_bits_meta_dirty;
  logic [1:0]     dir_msInfo_0_bits_meta_state;
  logic           dir_msInfo_0_bits_meta_clients;
  logic [1:0]     dir_msInfo_0_bits_meta_alias;
  logic           dir_msInfo_0_bits_meta_prefetch;
  logic [2:0]     dir_msInfo_0_bits_meta_prefetchSrc;
  logic           dir_msInfo_0_bits_meta_accessed;
  logic           dir_msInfo_0_bits_meta_tagErr;
  logic           dir_msInfo_0_bits_meta_dataErr;
  logic [30:0]    dir_msInfo_0_bits_metaTag;
  logic           dir_msInfo_0_bits_dirHit;
  logic           dir_msInfo_0_bits_isAcqOrPrefetch;
  logic           dir_msInfo_0_bits_isPrefetch;
  logic [2:0]     dir_msInfo_0_bits_param;
  logic           dir_msInfo_0_bits_mergeA;
  logic           dir_msInfo_0_bits_w_grantfirst;
  logic           dir_msInfo_0_bits_s_release;
  logic           dir_msInfo_0_bits_s_refill;
  logic           dir_msInfo_0_bits_s_cmoresp;
  logic           dir_msInfo_0_bits_s_cmometaw;
  logic           dir_msInfo_0_bits_w_releaseack;
  logic           dir_msInfo_0_bits_w_replResp;
  logic           dir_msInfo_0_bits_w_rprobeacklast;
  logic           dir_msInfo_0_bits_replaceData;
  logic           dir_msInfo_0_bits_releaseToClean;
  logic           dir_msInfo_1_valid;
  logic [2:0]     dir_msInfo_1_bits_channel;
  logic [8:0]     dir_msInfo_1_bits_set;
  logic [2:0]     dir_msInfo_1_bits_way;
  logic [30:0]    dir_msInfo_1_bits_reqTag;
  logic           dir_msInfo_1_bits_willFree;
  logic           dir_msInfo_1_bits_aliasTask;
  logic           dir_msInfo_1_bits_needRelease;
  logic           dir_msInfo_1_bits_blockRefill;
  logic           dir_msInfo_1_bits_meta_dirty;
  logic [1:0]     dir_msInfo_1_bits_meta_state;
  logic           dir_msInfo_1_bits_meta_clients;
  logic [1:0]     dir_msInfo_1_bits_meta_alias;
  logic           dir_msInfo_1_bits_meta_prefetch;
  logic [2:0]     dir_msInfo_1_bits_meta_prefetchSrc;
  logic           dir_msInfo_1_bits_meta_accessed;
  logic           dir_msInfo_1_bits_meta_tagErr;
  logic           dir_msInfo_1_bits_meta_dataErr;
  logic [30:0]    dir_msInfo_1_bits_metaTag;
  logic           dir_msInfo_1_bits_dirHit;
  logic           dir_msInfo_1_bits_isAcqOrPrefetch;
  logic           dir_msInfo_1_bits_isPrefetch;
  logic [2:0]     dir_msInfo_1_bits_param;
  logic           dir_msInfo_1_bits_mergeA;
  logic           dir_msInfo_1_bits_w_grantfirst;
  logic           dir_msInfo_1_bits_s_release;
  logic           dir_msInfo_1_bits_s_refill;
  logic           dir_msInfo_1_bits_s_cmoresp;
  logic           dir_msInfo_1_bits_s_cmometaw;
  logic           dir_msInfo_1_bits_w_releaseack;
  logic           dir_msInfo_1_bits_w_replResp;
  logic           dir_msInfo_1_bits_w_rprobeacklast;
  logic           dir_msInfo_1_bits_replaceData;
  logic           dir_msInfo_1_bits_releaseToClean;
  logic           dir_msInfo_2_valid;
  logic [2:0]     dir_msInfo_2_bits_channel;
  logic [8:0]     dir_msInfo_2_bits_set;
  logic [2:0]     dir_msInfo_2_bits_way;
  logic [30:0]    dir_msInfo_2_bits_reqTag;
  logic           dir_msInfo_2_bits_willFree;
  logic           dir_msInfo_2_bits_aliasTask;
  logic           dir_msInfo_2_bits_needRelease;
  logic           dir_msInfo_2_bits_blockRefill;
  logic           dir_msInfo_2_bits_meta_dirty;
  logic [1:0]     dir_msInfo_2_bits_meta_state;
  logic           dir_msInfo_2_bits_meta_clients;
  logic [1:0]     dir_msInfo_2_bits_meta_alias;
  logic           dir_msInfo_2_bits_meta_prefetch;
  logic [2:0]     dir_msInfo_2_bits_meta_prefetchSrc;
  logic           dir_msInfo_2_bits_meta_accessed;
  logic           dir_msInfo_2_bits_meta_tagErr;
  logic           dir_msInfo_2_bits_meta_dataErr;
  logic [30:0]    dir_msInfo_2_bits_metaTag;
  logic           dir_msInfo_2_bits_dirHit;
  logic           dir_msInfo_2_bits_isAcqOrPrefetch;
  logic           dir_msInfo_2_bits_isPrefetch;
  logic [2:0]     dir_msInfo_2_bits_param;
  logic           dir_msInfo_2_bits_mergeA;
  logic           dir_msInfo_2_bits_w_grantfirst;
  logic           dir_msInfo_2_bits_s_release;
  logic           dir_msInfo_2_bits_s_refill;
  logic           dir_msInfo_2_bits_s_cmoresp;
  logic           dir_msInfo_2_bits_s_cmometaw;
  logic           dir_msInfo_2_bits_w_releaseack;
  logic           dir_msInfo_2_bits_w_replResp;
  logic           dir_msInfo_2_bits_w_rprobeacklast;
  logic           dir_msInfo_2_bits_replaceData;
  logic           dir_msInfo_2_bits_releaseToClean;
  logic           dir_msInfo_3_valid;
  logic [2:0]     dir_msInfo_3_bits_channel;
  logic [8:0]     dir_msInfo_3_bits_set;
  logic [2:0]     dir_msInfo_3_bits_way;
  logic [30:0]    dir_msInfo_3_bits_reqTag;
  logic           dir_msInfo_3_bits_willFree;
  logic           dir_msInfo_3_bits_aliasTask;
  logic           dir_msInfo_3_bits_needRelease;
  logic           dir_msInfo_3_bits_blockRefill;
  logic           dir_msInfo_3_bits_meta_dirty;
  logic [1:0]     dir_msInfo_3_bits_meta_state;
  logic           dir_msInfo_3_bits_meta_clients;
  logic [1:0]     dir_msInfo_3_bits_meta_alias;
  logic           dir_msInfo_3_bits_meta_prefetch;
  logic [2:0]     dir_msInfo_3_bits_meta_prefetchSrc;
  logic           dir_msInfo_3_bits_meta_accessed;
  logic           dir_msInfo_3_bits_meta_tagErr;
  logic           dir_msInfo_3_bits_meta_dataErr;
  logic [30:0]    dir_msInfo_3_bits_metaTag;
  logic           dir_msInfo_3_bits_dirHit;
  logic           dir_msInfo_3_bits_isAcqOrPrefetch;
  logic           dir_msInfo_3_bits_isPrefetch;
  logic [2:0]     dir_msInfo_3_bits_param;
  logic           dir_msInfo_3_bits_mergeA;
  logic           dir_msInfo_3_bits_w_grantfirst;
  logic           dir_msInfo_3_bits_s_release;
  logic           dir_msInfo_3_bits_s_refill;
  logic           dir_msInfo_3_bits_s_cmoresp;
  logic           dir_msInfo_3_bits_s_cmometaw;
  logic           dir_msInfo_3_bits_w_releaseack;
  logic           dir_msInfo_3_bits_w_replResp;
  logic           dir_msInfo_3_bits_w_rprobeacklast;
  logic           dir_msInfo_3_bits_replaceData;
  logic           dir_msInfo_3_bits_releaseToClean;
  logic           dir_msInfo_4_valid;
  logic [2:0]     dir_msInfo_4_bits_channel;
  logic [8:0]     dir_msInfo_4_bits_set;
  logic [2:0]     dir_msInfo_4_bits_way;
  logic [30:0]    dir_msInfo_4_bits_reqTag;
  logic           dir_msInfo_4_bits_willFree;
  logic           dir_msInfo_4_bits_aliasTask;
  logic           dir_msInfo_4_bits_needRelease;
  logic           dir_msInfo_4_bits_blockRefill;
  logic           dir_msInfo_4_bits_meta_dirty;
  logic [1:0]     dir_msInfo_4_bits_meta_state;
  logic           dir_msInfo_4_bits_meta_clients;
  logic [1:0]     dir_msInfo_4_bits_meta_alias;
  logic           dir_msInfo_4_bits_meta_prefetch;
  logic [2:0]     dir_msInfo_4_bits_meta_prefetchSrc;
  logic           dir_msInfo_4_bits_meta_accessed;
  logic           dir_msInfo_4_bits_meta_tagErr;
  logic           dir_msInfo_4_bits_meta_dataErr;
  logic [30:0]    dir_msInfo_4_bits_metaTag;
  logic           dir_msInfo_4_bits_dirHit;
  logic           dir_msInfo_4_bits_isAcqOrPrefetch;
  logic           dir_msInfo_4_bits_isPrefetch;
  logic [2:0]     dir_msInfo_4_bits_param;
  logic           dir_msInfo_4_bits_mergeA;
  logic           dir_msInfo_4_bits_w_grantfirst;
  logic           dir_msInfo_4_bits_s_release;
  logic           dir_msInfo_4_bits_s_refill;
  logic           dir_msInfo_4_bits_s_cmoresp;
  logic           dir_msInfo_4_bits_s_cmometaw;
  logic           dir_msInfo_4_bits_w_releaseack;
  logic           dir_msInfo_4_bits_w_replResp;
  logic           dir_msInfo_4_bits_w_rprobeacklast;
  logic           dir_msInfo_4_bits_replaceData;
  logic           dir_msInfo_4_bits_releaseToClean;
  logic           dir_msInfo_5_valid;
  logic [2:0]     dir_msInfo_5_bits_channel;
  logic [8:0]     dir_msInfo_5_bits_set;
  logic [2:0]     dir_msInfo_5_bits_way;
  logic [30:0]    dir_msInfo_5_bits_reqTag;
  logic           dir_msInfo_5_bits_willFree;
  logic           dir_msInfo_5_bits_aliasTask;
  logic           dir_msInfo_5_bits_needRelease;
  logic           dir_msInfo_5_bits_blockRefill;
  logic           dir_msInfo_5_bits_meta_dirty;
  logic [1:0]     dir_msInfo_5_bits_meta_state;
  logic           dir_msInfo_5_bits_meta_clients;
  logic [1:0]     dir_msInfo_5_bits_meta_alias;
  logic           dir_msInfo_5_bits_meta_prefetch;
  logic [2:0]     dir_msInfo_5_bits_meta_prefetchSrc;
  logic           dir_msInfo_5_bits_meta_accessed;
  logic           dir_msInfo_5_bits_meta_tagErr;
  logic           dir_msInfo_5_bits_meta_dataErr;
  logic [30:0]    dir_msInfo_5_bits_metaTag;
  logic           dir_msInfo_5_bits_dirHit;
  logic           dir_msInfo_5_bits_isAcqOrPrefetch;
  logic           dir_msInfo_5_bits_isPrefetch;
  logic [2:0]     dir_msInfo_5_bits_param;
  logic           dir_msInfo_5_bits_mergeA;
  logic           dir_msInfo_5_bits_w_grantfirst;
  logic           dir_msInfo_5_bits_s_release;
  logic           dir_msInfo_5_bits_s_refill;
  logic           dir_msInfo_5_bits_s_cmoresp;
  logic           dir_msInfo_5_bits_s_cmometaw;
  logic           dir_msInfo_5_bits_w_releaseack;
  logic           dir_msInfo_5_bits_w_replResp;
  logic           dir_msInfo_5_bits_w_rprobeacklast;
  logic           dir_msInfo_5_bits_replaceData;
  logic           dir_msInfo_5_bits_releaseToClean;
  logic           dir_msInfo_6_valid;
  logic [2:0]     dir_msInfo_6_bits_channel;
  logic [8:0]     dir_msInfo_6_bits_set;
  logic [2:0]     dir_msInfo_6_bits_way;
  logic [30:0]    dir_msInfo_6_bits_reqTag;
  logic           dir_msInfo_6_bits_willFree;
  logic           dir_msInfo_6_bits_aliasTask;
  logic           dir_msInfo_6_bits_needRelease;
  logic           dir_msInfo_6_bits_blockRefill;
  logic           dir_msInfo_6_bits_meta_dirty;
  logic [1:0]     dir_msInfo_6_bits_meta_state;
  logic           dir_msInfo_6_bits_meta_clients;
  logic [1:0]     dir_msInfo_6_bits_meta_alias;
  logic           dir_msInfo_6_bits_meta_prefetch;
  logic [2:0]     dir_msInfo_6_bits_meta_prefetchSrc;
  logic           dir_msInfo_6_bits_meta_accessed;
  logic           dir_msInfo_6_bits_meta_tagErr;
  logic           dir_msInfo_6_bits_meta_dataErr;
  logic [30:0]    dir_msInfo_6_bits_metaTag;
  logic           dir_msInfo_6_bits_dirHit;
  logic           dir_msInfo_6_bits_isAcqOrPrefetch;
  logic           dir_msInfo_6_bits_isPrefetch;
  logic [2:0]     dir_msInfo_6_bits_param;
  logic           dir_msInfo_6_bits_mergeA;
  logic           dir_msInfo_6_bits_w_grantfirst;
  logic           dir_msInfo_6_bits_s_release;
  logic           dir_msInfo_6_bits_s_refill;
  logic           dir_msInfo_6_bits_s_cmoresp;
  logic           dir_msInfo_6_bits_s_cmometaw;
  logic           dir_msInfo_6_bits_w_releaseack;
  logic           dir_msInfo_6_bits_w_replResp;
  logic           dir_msInfo_6_bits_w_rprobeacklast;
  logic           dir_msInfo_6_bits_replaceData;
  logic           dir_msInfo_6_bits_releaseToClean;
  logic           dir_msInfo_7_valid;
  logic [2:0]     dir_msInfo_7_bits_channel;
  logic [8:0]     dir_msInfo_7_bits_set;
  logic [2:0]     dir_msInfo_7_bits_way;
  logic [30:0]    dir_msInfo_7_bits_reqTag;
  logic           dir_msInfo_7_bits_willFree;
  logic           dir_msInfo_7_bits_aliasTask;
  logic           dir_msInfo_7_bits_needRelease;
  logic           dir_msInfo_7_bits_blockRefill;
  logic           dir_msInfo_7_bits_meta_dirty;
  logic [1:0]     dir_msInfo_7_bits_meta_state;
  logic           dir_msInfo_7_bits_meta_clients;
  logic [1:0]     dir_msInfo_7_bits_meta_alias;
  logic           dir_msInfo_7_bits_meta_prefetch;
  logic [2:0]     dir_msInfo_7_bits_meta_prefetchSrc;
  logic           dir_msInfo_7_bits_meta_accessed;
  logic           dir_msInfo_7_bits_meta_tagErr;
  logic           dir_msInfo_7_bits_meta_dataErr;
  logic [30:0]    dir_msInfo_7_bits_metaTag;
  logic           dir_msInfo_7_bits_dirHit;
  logic           dir_msInfo_7_bits_isAcqOrPrefetch;
  logic           dir_msInfo_7_bits_isPrefetch;
  logic [2:0]     dir_msInfo_7_bits_param;
  logic           dir_msInfo_7_bits_mergeA;
  logic           dir_msInfo_7_bits_w_grantfirst;
  logic           dir_msInfo_7_bits_s_release;
  logic           dir_msInfo_7_bits_s_refill;
  logic           dir_msInfo_7_bits_s_cmoresp;
  logic           dir_msInfo_7_bits_s_cmometaw;
  logic           dir_msInfo_7_bits_w_releaseack;
  logic           dir_msInfo_7_bits_w_replResp;
  logic           dir_msInfo_7_bits_w_rprobeacklast;
  logic           dir_msInfo_7_bits_replaceData;
  logic           dir_msInfo_7_bits_releaseToClean;
  logic           dir_msInfo_8_valid;
  logic [2:0]     dir_msInfo_8_bits_channel;
  logic [8:0]     dir_msInfo_8_bits_set;
  logic [2:0]     dir_msInfo_8_bits_way;
  logic [30:0]    dir_msInfo_8_bits_reqTag;
  logic           dir_msInfo_8_bits_willFree;
  logic           dir_msInfo_8_bits_aliasTask;
  logic           dir_msInfo_8_bits_needRelease;
  logic           dir_msInfo_8_bits_blockRefill;
  logic           dir_msInfo_8_bits_meta_dirty;
  logic [1:0]     dir_msInfo_8_bits_meta_state;
  logic           dir_msInfo_8_bits_meta_clients;
  logic [1:0]     dir_msInfo_8_bits_meta_alias;
  logic           dir_msInfo_8_bits_meta_prefetch;
  logic [2:0]     dir_msInfo_8_bits_meta_prefetchSrc;
  logic           dir_msInfo_8_bits_meta_accessed;
  logic           dir_msInfo_8_bits_meta_tagErr;
  logic           dir_msInfo_8_bits_meta_dataErr;
  logic [30:0]    dir_msInfo_8_bits_metaTag;
  logic           dir_msInfo_8_bits_dirHit;
  logic           dir_msInfo_8_bits_isAcqOrPrefetch;
  logic           dir_msInfo_8_bits_isPrefetch;
  logic [2:0]     dir_msInfo_8_bits_param;
  logic           dir_msInfo_8_bits_mergeA;
  logic           dir_msInfo_8_bits_w_grantfirst;
  logic           dir_msInfo_8_bits_s_release;
  logic           dir_msInfo_8_bits_s_refill;
  logic           dir_msInfo_8_bits_s_cmoresp;
  logic           dir_msInfo_8_bits_s_cmometaw;
  logic           dir_msInfo_8_bits_w_releaseack;
  logic           dir_msInfo_8_bits_w_replResp;
  logic           dir_msInfo_8_bits_w_rprobeacklast;
  logic           dir_msInfo_8_bits_replaceData;
  logic           dir_msInfo_8_bits_releaseToClean;
  logic           dir_msInfo_9_valid;
  logic [2:0]     dir_msInfo_9_bits_channel;
  logic [8:0]     dir_msInfo_9_bits_set;
  logic [2:0]     dir_msInfo_9_bits_way;
  logic [30:0]    dir_msInfo_9_bits_reqTag;
  logic           dir_msInfo_9_bits_willFree;
  logic           dir_msInfo_9_bits_aliasTask;
  logic           dir_msInfo_9_bits_needRelease;
  logic           dir_msInfo_9_bits_blockRefill;
  logic           dir_msInfo_9_bits_meta_dirty;
  logic [1:0]     dir_msInfo_9_bits_meta_state;
  logic           dir_msInfo_9_bits_meta_clients;
  logic [1:0]     dir_msInfo_9_bits_meta_alias;
  logic           dir_msInfo_9_bits_meta_prefetch;
  logic [2:0]     dir_msInfo_9_bits_meta_prefetchSrc;
  logic           dir_msInfo_9_bits_meta_accessed;
  logic           dir_msInfo_9_bits_meta_tagErr;
  logic           dir_msInfo_9_bits_meta_dataErr;
  logic [30:0]    dir_msInfo_9_bits_metaTag;
  logic           dir_msInfo_9_bits_dirHit;
  logic           dir_msInfo_9_bits_isAcqOrPrefetch;
  logic           dir_msInfo_9_bits_isPrefetch;
  logic [2:0]     dir_msInfo_9_bits_param;
  logic           dir_msInfo_9_bits_mergeA;
  logic           dir_msInfo_9_bits_w_grantfirst;
  logic           dir_msInfo_9_bits_s_release;
  logic           dir_msInfo_9_bits_s_refill;
  logic           dir_msInfo_9_bits_s_cmoresp;
  logic           dir_msInfo_9_bits_s_cmometaw;
  logic           dir_msInfo_9_bits_w_releaseack;
  logic           dir_msInfo_9_bits_w_replResp;
  logic           dir_msInfo_9_bits_w_rprobeacklast;
  logic           dir_msInfo_9_bits_replaceData;
  logic           dir_msInfo_9_bits_releaseToClean;
  logic           dir_msInfo_10_valid;
  logic [2:0]     dir_msInfo_10_bits_channel;
  logic [8:0]     dir_msInfo_10_bits_set;
  logic [2:0]     dir_msInfo_10_bits_way;
  logic [30:0]    dir_msInfo_10_bits_reqTag;
  logic           dir_msInfo_10_bits_willFree;
  logic           dir_msInfo_10_bits_aliasTask;
  logic           dir_msInfo_10_bits_needRelease;
  logic           dir_msInfo_10_bits_blockRefill;
  logic           dir_msInfo_10_bits_meta_dirty;
  logic [1:0]     dir_msInfo_10_bits_meta_state;
  logic           dir_msInfo_10_bits_meta_clients;
  logic [1:0]     dir_msInfo_10_bits_meta_alias;
  logic           dir_msInfo_10_bits_meta_prefetch;
  logic [2:0]     dir_msInfo_10_bits_meta_prefetchSrc;
  logic           dir_msInfo_10_bits_meta_accessed;
  logic           dir_msInfo_10_bits_meta_tagErr;
  logic           dir_msInfo_10_bits_meta_dataErr;
  logic [30:0]    dir_msInfo_10_bits_metaTag;
  logic           dir_msInfo_10_bits_dirHit;
  logic           dir_msInfo_10_bits_isAcqOrPrefetch;
  logic           dir_msInfo_10_bits_isPrefetch;
  logic [2:0]     dir_msInfo_10_bits_param;
  logic           dir_msInfo_10_bits_mergeA;
  logic           dir_msInfo_10_bits_w_grantfirst;
  logic           dir_msInfo_10_bits_s_release;
  logic           dir_msInfo_10_bits_s_refill;
  logic           dir_msInfo_10_bits_s_cmoresp;
  logic           dir_msInfo_10_bits_s_cmometaw;
  logic           dir_msInfo_10_bits_w_releaseack;
  logic           dir_msInfo_10_bits_w_replResp;
  logic           dir_msInfo_10_bits_w_rprobeacklast;
  logic           dir_msInfo_10_bits_replaceData;
  logic           dir_msInfo_10_bits_releaseToClean;
  logic           dir_msInfo_11_valid;
  logic [2:0]     dir_msInfo_11_bits_channel;
  logic [8:0]     dir_msInfo_11_bits_set;
  logic [2:0]     dir_msInfo_11_bits_way;
  logic [30:0]    dir_msInfo_11_bits_reqTag;
  logic           dir_msInfo_11_bits_willFree;
  logic           dir_msInfo_11_bits_aliasTask;
  logic           dir_msInfo_11_bits_needRelease;
  logic           dir_msInfo_11_bits_blockRefill;
  logic           dir_msInfo_11_bits_meta_dirty;
  logic [1:0]     dir_msInfo_11_bits_meta_state;
  logic           dir_msInfo_11_bits_meta_clients;
  logic [1:0]     dir_msInfo_11_bits_meta_alias;
  logic           dir_msInfo_11_bits_meta_prefetch;
  logic [2:0]     dir_msInfo_11_bits_meta_prefetchSrc;
  logic           dir_msInfo_11_bits_meta_accessed;
  logic           dir_msInfo_11_bits_meta_tagErr;
  logic           dir_msInfo_11_bits_meta_dataErr;
  logic [30:0]    dir_msInfo_11_bits_metaTag;
  logic           dir_msInfo_11_bits_dirHit;
  logic           dir_msInfo_11_bits_isAcqOrPrefetch;
  logic           dir_msInfo_11_bits_isPrefetch;
  logic [2:0]     dir_msInfo_11_bits_param;
  logic           dir_msInfo_11_bits_mergeA;
  logic           dir_msInfo_11_bits_w_grantfirst;
  logic           dir_msInfo_11_bits_s_release;
  logic           dir_msInfo_11_bits_s_refill;
  logic           dir_msInfo_11_bits_s_cmoresp;
  logic           dir_msInfo_11_bits_s_cmometaw;
  logic           dir_msInfo_11_bits_w_releaseack;
  logic           dir_msInfo_11_bits_w_replResp;
  logic           dir_msInfo_11_bits_w_rprobeacklast;
  logic           dir_msInfo_11_bits_replaceData;
  logic           dir_msInfo_11_bits_releaseToClean;
  logic           dir_msInfo_12_valid;
  logic [2:0]     dir_msInfo_12_bits_channel;
  logic [8:0]     dir_msInfo_12_bits_set;
  logic [2:0]     dir_msInfo_12_bits_way;
  logic [30:0]    dir_msInfo_12_bits_reqTag;
  logic           dir_msInfo_12_bits_willFree;
  logic           dir_msInfo_12_bits_aliasTask;
  logic           dir_msInfo_12_bits_needRelease;
  logic           dir_msInfo_12_bits_blockRefill;
  logic           dir_msInfo_12_bits_meta_dirty;
  logic [1:0]     dir_msInfo_12_bits_meta_state;
  logic           dir_msInfo_12_bits_meta_clients;
  logic [1:0]     dir_msInfo_12_bits_meta_alias;
  logic           dir_msInfo_12_bits_meta_prefetch;
  logic [2:0]     dir_msInfo_12_bits_meta_prefetchSrc;
  logic           dir_msInfo_12_bits_meta_accessed;
  logic           dir_msInfo_12_bits_meta_tagErr;
  logic           dir_msInfo_12_bits_meta_dataErr;
  logic [30:0]    dir_msInfo_12_bits_metaTag;
  logic           dir_msInfo_12_bits_dirHit;
  logic           dir_msInfo_12_bits_isAcqOrPrefetch;
  logic           dir_msInfo_12_bits_isPrefetch;
  logic [2:0]     dir_msInfo_12_bits_param;
  logic           dir_msInfo_12_bits_mergeA;
  logic           dir_msInfo_12_bits_w_grantfirst;
  logic           dir_msInfo_12_bits_s_release;
  logic           dir_msInfo_12_bits_s_refill;
  logic           dir_msInfo_12_bits_s_cmoresp;
  logic           dir_msInfo_12_bits_s_cmometaw;
  logic           dir_msInfo_12_bits_w_releaseack;
  logic           dir_msInfo_12_bits_w_replResp;
  logic           dir_msInfo_12_bits_w_rprobeacklast;
  logic           dir_msInfo_12_bits_replaceData;
  logic           dir_msInfo_12_bits_releaseToClean;
  logic           dir_msInfo_13_valid;
  logic [2:0]     dir_msInfo_13_bits_channel;
  logic [8:0]     dir_msInfo_13_bits_set;
  logic [2:0]     dir_msInfo_13_bits_way;
  logic [30:0]    dir_msInfo_13_bits_reqTag;
  logic           dir_msInfo_13_bits_willFree;
  logic           dir_msInfo_13_bits_aliasTask;
  logic           dir_msInfo_13_bits_needRelease;
  logic           dir_msInfo_13_bits_blockRefill;
  logic           dir_msInfo_13_bits_meta_dirty;
  logic [1:0]     dir_msInfo_13_bits_meta_state;
  logic           dir_msInfo_13_bits_meta_clients;
  logic [1:0]     dir_msInfo_13_bits_meta_alias;
  logic           dir_msInfo_13_bits_meta_prefetch;
  logic [2:0]     dir_msInfo_13_bits_meta_prefetchSrc;
  logic           dir_msInfo_13_bits_meta_accessed;
  logic           dir_msInfo_13_bits_meta_tagErr;
  logic           dir_msInfo_13_bits_meta_dataErr;
  logic [30:0]    dir_msInfo_13_bits_metaTag;
  logic           dir_msInfo_13_bits_dirHit;
  logic           dir_msInfo_13_bits_isAcqOrPrefetch;
  logic           dir_msInfo_13_bits_isPrefetch;
  logic [2:0]     dir_msInfo_13_bits_param;
  logic           dir_msInfo_13_bits_mergeA;
  logic           dir_msInfo_13_bits_w_grantfirst;
  logic           dir_msInfo_13_bits_s_release;
  logic           dir_msInfo_13_bits_s_refill;
  logic           dir_msInfo_13_bits_s_cmoresp;
  logic           dir_msInfo_13_bits_s_cmometaw;
  logic           dir_msInfo_13_bits_w_releaseack;
  logic           dir_msInfo_13_bits_w_replResp;
  logic           dir_msInfo_13_bits_w_rprobeacklast;
  logic           dir_msInfo_13_bits_replaceData;
  logic           dir_msInfo_13_bits_releaseToClean;
  logic           dir_msInfo_14_valid;
  logic [2:0]     dir_msInfo_14_bits_channel;
  logic [8:0]     dir_msInfo_14_bits_set;
  logic [2:0]     dir_msInfo_14_bits_way;
  logic [30:0]    dir_msInfo_14_bits_reqTag;
  logic           dir_msInfo_14_bits_willFree;
  logic           dir_msInfo_14_bits_aliasTask;
  logic           dir_msInfo_14_bits_needRelease;
  logic           dir_msInfo_14_bits_blockRefill;
  logic           dir_msInfo_14_bits_meta_dirty;
  logic [1:0]     dir_msInfo_14_bits_meta_state;
  logic           dir_msInfo_14_bits_meta_clients;
  logic [1:0]     dir_msInfo_14_bits_meta_alias;
  logic           dir_msInfo_14_bits_meta_prefetch;
  logic [2:0]     dir_msInfo_14_bits_meta_prefetchSrc;
  logic           dir_msInfo_14_bits_meta_accessed;
  logic           dir_msInfo_14_bits_meta_tagErr;
  logic           dir_msInfo_14_bits_meta_dataErr;
  logic [30:0]    dir_msInfo_14_bits_metaTag;
  logic           dir_msInfo_14_bits_dirHit;
  logic           dir_msInfo_14_bits_isAcqOrPrefetch;
  logic           dir_msInfo_14_bits_isPrefetch;
  logic [2:0]     dir_msInfo_14_bits_param;
  logic           dir_msInfo_14_bits_mergeA;
  logic           dir_msInfo_14_bits_w_grantfirst;
  logic           dir_msInfo_14_bits_s_release;
  logic           dir_msInfo_14_bits_s_refill;
  logic           dir_msInfo_14_bits_s_cmoresp;
  logic           dir_msInfo_14_bits_s_cmometaw;
  logic           dir_msInfo_14_bits_w_releaseack;
  logic           dir_msInfo_14_bits_w_replResp;
  logic           dir_msInfo_14_bits_w_rprobeacklast;
  logic           dir_msInfo_14_bits_replaceData;
  logic           dir_msInfo_14_bits_releaseToClean;
  logic           dir_msInfo_15_valid;
  logic [2:0]     dir_msInfo_15_bits_channel;
  logic [8:0]     dir_msInfo_15_bits_set;
  logic [2:0]     dir_msInfo_15_bits_way;
  logic [30:0]    dir_msInfo_15_bits_reqTag;
  logic           dir_msInfo_15_bits_willFree;
  logic           dir_msInfo_15_bits_aliasTask;
  logic           dir_msInfo_15_bits_needRelease;
  logic           dir_msInfo_15_bits_blockRefill;
  logic           dir_msInfo_15_bits_meta_dirty;
  logic [1:0]     dir_msInfo_15_bits_meta_state;
  logic           dir_msInfo_15_bits_meta_clients;
  logic [1:0]     dir_msInfo_15_bits_meta_alias;
  logic           dir_msInfo_15_bits_meta_prefetch;
  logic [2:0]     dir_msInfo_15_bits_meta_prefetchSrc;
  logic           dir_msInfo_15_bits_meta_accessed;
  logic           dir_msInfo_15_bits_meta_tagErr;
  logic           dir_msInfo_15_bits_meta_dataErr;
  logic [30:0]    dir_msInfo_15_bits_metaTag;
  logic           dir_msInfo_15_bits_dirHit;
  logic           dir_msInfo_15_bits_isAcqOrPrefetch;
  logic           dir_msInfo_15_bits_isPrefetch;
  logic [2:0]     dir_msInfo_15_bits_param;
  logic           dir_msInfo_15_bits_mergeA;
  logic           dir_msInfo_15_bits_w_grantfirst;
  logic           dir_msInfo_15_bits_s_release;
  logic           dir_msInfo_15_bits_s_refill;
  logic           dir_msInfo_15_bits_s_cmoresp;
  logic           dir_msInfo_15_bits_s_cmometaw;
  logic           dir_msInfo_15_bits_w_releaseack;
  logic           dir_msInfo_15_bits_w_replResp;
  logic           dir_msInfo_15_bits_w_rprobeacklast;
  logic           dir_msInfo_15_bits_replaceData;
  logic           dir_msInfo_15_bits_releaseToClean;
  logic           ds_en;
  logic           ds_error;
  logic           ds_req_valid;
  logic [2:0]     ds_req_bits_way;
  logic [8:0]     ds_req_bits_set;
  logic           ds_req_bits_wen;
  logic [511:0]   ds_rdata_data;
  logic [511:0]   ds_wdata_data;
  // §W2 MBIST 分发线：mbistPl 的两路下行（路 0 -> 目录，路 1 -> 数据阵列）
  logic [4:0]     mbist_dir_array;
  logic           mbist_dir_all;
  logic           mbist_dir_req;
  logic           mbist_dir_ack;
  logic           mbist_dir_writeen;
  logic [7:0]     mbist_dir_be;
  logic [9:0]     mbist_dir_addr;
  logic [103:0]   mbist_dir_indata;
  logic           mbist_dir_readen;
  logic [9:0]     mbist_dir_addr_rd;
  logic [103:0]   mbist_dir_outdata;
  logic [5:0]     mbist_ds_array;
  logic           mbist_ds_all;
  logic           mbist_ds_req;
  logic           mbist_ds_ack;
  logic           mbist_ds_writeen;
  logic           mbist_ds_be;
  logic [12:0]    mbist_ds_addr;
  logic [136:0]   mbist_ds_indata;
  logic           mbist_ds_readen;
  logic [12:0]    mbist_ds_addr_rd;
  logic [136:0]   mbist_ds_outdata;

  // §W3 可读核（本变体 SLICE_ID = 2）：除目录 / 数据阵列 / MBIST 分发外的全部 child 与本层逻辑
  xs_Slice_core #(.SLICE_ID(2'd2)) u_core (
    .clock                                      (clock),
    .reset                                      (reset),
    .io_in_a_ready                              (io_in_a_ready),
    .io_in_a_valid                              (io_in_a_valid),
    .io_in_a_bits_opcode                        (io_in_a_bits_opcode),
    .io_in_a_bits_param                         (io_in_a_bits_param),
    .io_in_a_bits_size                          (io_in_a_bits_size),
    .io_in_a_bits_source                        (io_in_a_bits_source),
    .io_in_a_bits_address                       (io_in_a_bits_address),
    .io_in_a_bits_user_reqSource                (io_in_a_bits_user_reqSource),
    .io_in_a_bits_user_alias                    (io_in_a_bits_user_alias),
    .io_in_a_bits_user_vaddr                    (io_in_a_bits_user_vaddr),
    .io_in_a_bits_user_needHint                 (io_in_a_bits_user_needHint),
    .io_in_a_bits_echo_isKeyword                (io_in_a_bits_echo_isKeyword),
    .io_in_a_bits_corrupt                       (io_in_a_bits_corrupt),
    .io_in_b_ready                              (io_in_b_ready),
    .io_in_b_valid                              (io_in_b_valid),
    .io_in_b_bits_opcode                        (io_in_b_bits_opcode),
    .io_in_b_bits_param                         (io_in_b_bits_param),
    .io_in_b_bits_address                       (io_in_b_bits_address),
    .io_in_b_bits_data                          (io_in_b_bits_data),
    .io_in_c_ready                              (io_in_c_ready),
    .io_in_c_valid                              (io_in_c_valid),
    .io_in_c_bits_opcode                        (io_in_c_bits_opcode),
    .io_in_c_bits_param                         (io_in_c_bits_param),
    .io_in_c_bits_size                          (io_in_c_bits_size),
    .io_in_c_bits_source                        (io_in_c_bits_source),
    .io_in_c_bits_address                       (io_in_c_bits_address),
    .io_in_c_bits_data                          (io_in_c_bits_data),
    .io_in_c_bits_corrupt                       (io_in_c_bits_corrupt),
    .io_in_d_ready                              (io_in_d_ready),
    .io_in_d_valid                              (io_in_d_valid),
    .io_in_d_bits_opcode                        (io_in_d_bits_opcode),
    .io_in_d_bits_param                         (io_in_d_bits_param),
    .io_in_d_bits_source                        (io_in_d_bits_source),
    .io_in_d_bits_sink                          (io_in_d_bits_sink),
    .io_in_d_bits_denied                        (io_in_d_bits_denied),
    .io_in_d_bits_echo_isKeyword                (io_in_d_bits_echo_isKeyword),
    .io_in_d_bits_data                          (io_in_d_bits_data),
    .io_in_d_bits_corrupt                       (io_in_d_bits_corrupt),
    .io_in_e_valid                              (io_in_e_valid),
    .io_in_e_bits_sink                          (io_in_e_bits_sink),
    .io_l1Hint_ready                            (io_l1Hint_ready),
    .io_l1Hint_valid                            (io_l1Hint_valid),
    .io_l1Hint_bits_sourceId                    (io_l1Hint_bits_sourceId),
    .io_l1Hint_bits_isKeyword                   (io_l1Hint_bits_isKeyword),
    .io_prefetch_train_ready                    (io_prefetch_train_ready),
    .io_prefetch_train_valid                    (io_prefetch_train_valid),
    .io_prefetch_train_bits_tag                 (io_prefetch_train_bits_tag),
    .io_prefetch_train_bits_set                 (io_prefetch_train_bits_set),
    .io_prefetch_train_bits_needT               (io_prefetch_train_bits_needT),
    .io_prefetch_train_bits_source              (io_prefetch_train_bits_source),
    .io_prefetch_train_bits_vaddr               (io_prefetch_train_bits_vaddr),
    .io_prefetch_train_bits_hit                 (io_prefetch_train_bits_hit),
    .io_prefetch_train_bits_prefetched          (io_prefetch_train_bits_prefetched),
    .io_prefetch_train_bits_pfsource            (io_prefetch_train_bits_pfsource),
    .io_prefetch_train_bits_reqsource           (io_prefetch_train_bits_reqsource),
    .io_prefetch_req_ready                      (io_prefetch_req_ready),
    .io_prefetch_req_valid                      (io_prefetch_req_valid),
    .io_prefetch_req_bits_tag                   (io_prefetch_req_bits_tag),
    .io_prefetch_req_bits_set                   (io_prefetch_req_bits_set),
    .io_prefetch_req_bits_vaddr                 (io_prefetch_req_bits_vaddr),
    .io_prefetch_req_bits_needT                 (io_prefetch_req_bits_needT),
    .io_prefetch_req_bits_source                (io_prefetch_req_bits_source),
    .io_prefetch_req_bits_pfSource              (io_prefetch_req_bits_pfSource),
    .io_prefetch_resp_ready                     (io_prefetch_resp_ready),
    .io_prefetch_resp_valid                     (io_prefetch_resp_valid),
    .io_prefetch_resp_bits_tag                  (io_prefetch_resp_bits_tag),
    .io_prefetch_resp_bits_set                  (io_prefetch_resp_bits_set),
    .io_prefetch_resp_bits_vaddr                (io_prefetch_resp_bits_vaddr),
    .io_prefetch_resp_bits_pfSource             (io_prefetch_resp_bits_pfSource),
    .io_dirResult_valid                         (io_dirResult_valid),
    .io_dirResult_bits_hit                      (io_dirResult_bits_hit),
    .io_dirResult_bits_meta_prefetch            (io_dirResult_bits_meta_prefetch),
    .io_dirResult_bits_meta_prefetchSrc         (io_dirResult_bits_meta_prefetchSrc),
    .io_hitPfInMSHR_valid                       (io_hitPfInMSHR_valid),
    .io_hitPfInMSHR_bits                        (io_hitPfInMSHR_bits),
    .io_pfSent_valid                            (io_pfSent_valid),
    .io_pfSent_bits                             (io_pfSent_bits),
    .io_pfLateInMSHR_valid                      (io_pfLateInMSHR_valid),
    .io_pfLateInMSHR_bits                       (io_pfLateInMSHR_bits),
    .io_error_valid                             (io_error_valid),
    .io_error_bits_valid                        (io_error_bits_valid),
    .io_error_bits_address                      (io_error_bits_address),
    .io_l2Miss                                  (io_l2Miss),
    .io_msStatus_0_valid                        (io_msStatus_0_valid),
    .io_msStatus_0_bits_channel                 (io_msStatus_0_bits_channel),
    .io_msStatus_0_bits_set                     (io_msStatus_0_bits_set),
    .io_msStatus_0_bits_reqTag                  (io_msStatus_0_bits_reqTag),
    .io_msStatus_0_bits_is_miss                 (io_msStatus_0_bits_is_miss),
    .io_msStatus_0_bits_is_prefetch             (io_msStatus_0_bits_is_prefetch),
    .io_msStatus_1_valid                        (io_msStatus_1_valid),
    .io_msStatus_1_bits_channel                 (io_msStatus_1_bits_channel),
    .io_msStatus_1_bits_set                     (io_msStatus_1_bits_set),
    .io_msStatus_1_bits_reqTag                  (io_msStatus_1_bits_reqTag),
    .io_msStatus_1_bits_is_miss                 (io_msStatus_1_bits_is_miss),
    .io_msStatus_1_bits_is_prefetch             (io_msStatus_1_bits_is_prefetch),
    .io_msStatus_2_valid                        (io_msStatus_2_valid),
    .io_msStatus_2_bits_channel                 (io_msStatus_2_bits_channel),
    .io_msStatus_2_bits_set                     (io_msStatus_2_bits_set),
    .io_msStatus_2_bits_reqTag                  (io_msStatus_2_bits_reqTag),
    .io_msStatus_2_bits_is_miss                 (io_msStatus_2_bits_is_miss),
    .io_msStatus_2_bits_is_prefetch             (io_msStatus_2_bits_is_prefetch),
    .io_msStatus_3_valid                        (io_msStatus_3_valid),
    .io_msStatus_3_bits_channel                 (io_msStatus_3_bits_channel),
    .io_msStatus_3_bits_set                     (io_msStatus_3_bits_set),
    .io_msStatus_3_bits_reqTag                  (io_msStatus_3_bits_reqTag),
    .io_msStatus_3_bits_is_miss                 (io_msStatus_3_bits_is_miss),
    .io_msStatus_3_bits_is_prefetch             (io_msStatus_3_bits_is_prefetch),
    .io_msStatus_4_valid                        (io_msStatus_4_valid),
    .io_msStatus_4_bits_channel                 (io_msStatus_4_bits_channel),
    .io_msStatus_4_bits_set                     (io_msStatus_4_bits_set),
    .io_msStatus_4_bits_reqTag                  (io_msStatus_4_bits_reqTag),
    .io_msStatus_4_bits_is_miss                 (io_msStatus_4_bits_is_miss),
    .io_msStatus_4_bits_is_prefetch             (io_msStatus_4_bits_is_prefetch),
    .io_msStatus_5_valid                        (io_msStatus_5_valid),
    .io_msStatus_5_bits_channel                 (io_msStatus_5_bits_channel),
    .io_msStatus_5_bits_set                     (io_msStatus_5_bits_set),
    .io_msStatus_5_bits_reqTag                  (io_msStatus_5_bits_reqTag),
    .io_msStatus_5_bits_is_miss                 (io_msStatus_5_bits_is_miss),
    .io_msStatus_5_bits_is_prefetch             (io_msStatus_5_bits_is_prefetch),
    .io_msStatus_6_valid                        (io_msStatus_6_valid),
    .io_msStatus_6_bits_channel                 (io_msStatus_6_bits_channel),
    .io_msStatus_6_bits_set                     (io_msStatus_6_bits_set),
    .io_msStatus_6_bits_reqTag                  (io_msStatus_6_bits_reqTag),
    .io_msStatus_6_bits_is_miss                 (io_msStatus_6_bits_is_miss),
    .io_msStatus_6_bits_is_prefetch             (io_msStatus_6_bits_is_prefetch),
    .io_msStatus_7_valid                        (io_msStatus_7_valid),
    .io_msStatus_7_bits_channel                 (io_msStatus_7_bits_channel),
    .io_msStatus_7_bits_set                     (io_msStatus_7_bits_set),
    .io_msStatus_7_bits_reqTag                  (io_msStatus_7_bits_reqTag),
    .io_msStatus_7_bits_is_miss                 (io_msStatus_7_bits_is_miss),
    .io_msStatus_7_bits_is_prefetch             (io_msStatus_7_bits_is_prefetch),
    .io_msStatus_8_valid                        (io_msStatus_8_valid),
    .io_msStatus_8_bits_channel                 (io_msStatus_8_bits_channel),
    .io_msStatus_8_bits_set                     (io_msStatus_8_bits_set),
    .io_msStatus_8_bits_reqTag                  (io_msStatus_8_bits_reqTag),
    .io_msStatus_8_bits_is_miss                 (io_msStatus_8_bits_is_miss),
    .io_msStatus_8_bits_is_prefetch             (io_msStatus_8_bits_is_prefetch),
    .io_msStatus_9_valid                        (io_msStatus_9_valid),
    .io_msStatus_9_bits_channel                 (io_msStatus_9_bits_channel),
    .io_msStatus_9_bits_set                     (io_msStatus_9_bits_set),
    .io_msStatus_9_bits_reqTag                  (io_msStatus_9_bits_reqTag),
    .io_msStatus_9_bits_is_miss                 (io_msStatus_9_bits_is_miss),
    .io_msStatus_9_bits_is_prefetch             (io_msStatus_9_bits_is_prefetch),
    .io_msStatus_10_valid                       (io_msStatus_10_valid),
    .io_msStatus_10_bits_channel                (io_msStatus_10_bits_channel),
    .io_msStatus_10_bits_set                    (io_msStatus_10_bits_set),
    .io_msStatus_10_bits_reqTag                 (io_msStatus_10_bits_reqTag),
    .io_msStatus_10_bits_is_miss                (io_msStatus_10_bits_is_miss),
    .io_msStatus_10_bits_is_prefetch            (io_msStatus_10_bits_is_prefetch),
    .io_msStatus_11_valid                       (io_msStatus_11_valid),
    .io_msStatus_11_bits_channel                (io_msStatus_11_bits_channel),
    .io_msStatus_11_bits_set                    (io_msStatus_11_bits_set),
    .io_msStatus_11_bits_reqTag                 (io_msStatus_11_bits_reqTag),
    .io_msStatus_11_bits_is_miss                (io_msStatus_11_bits_is_miss),
    .io_msStatus_11_bits_is_prefetch            (io_msStatus_11_bits_is_prefetch),
    .io_msStatus_12_valid                       (io_msStatus_12_valid),
    .io_msStatus_12_bits_channel                (io_msStatus_12_bits_channel),
    .io_msStatus_12_bits_set                    (io_msStatus_12_bits_set),
    .io_msStatus_12_bits_reqTag                 (io_msStatus_12_bits_reqTag),
    .io_msStatus_12_bits_is_miss                (io_msStatus_12_bits_is_miss),
    .io_msStatus_12_bits_is_prefetch            (io_msStatus_12_bits_is_prefetch),
    .io_msStatus_13_valid                       (io_msStatus_13_valid),
    .io_msStatus_13_bits_channel                (io_msStatus_13_bits_channel),
    .io_msStatus_13_bits_set                    (io_msStatus_13_bits_set),
    .io_msStatus_13_bits_reqTag                 (io_msStatus_13_bits_reqTag),
    .io_msStatus_13_bits_is_miss                (io_msStatus_13_bits_is_miss),
    .io_msStatus_13_bits_is_prefetch            (io_msStatus_13_bits_is_prefetch),
    .io_msStatus_14_valid                       (io_msStatus_14_valid),
    .io_msStatus_14_bits_channel                (io_msStatus_14_bits_channel),
    .io_msStatus_14_bits_set                    (io_msStatus_14_bits_set),
    .io_msStatus_14_bits_reqTag                 (io_msStatus_14_bits_reqTag),
    .io_msStatus_14_bits_is_miss                (io_msStatus_14_bits_is_miss),
    .io_msStatus_14_bits_is_prefetch            (io_msStatus_14_bits_is_prefetch),
    .io_msStatus_15_valid                       (io_msStatus_15_valid),
    .io_msStatus_15_bits_channel                (io_msStatus_15_bits_channel),
    .io_msStatus_15_bits_set                    (io_msStatus_15_bits_set),
    .io_msStatus_15_bits_reqTag                 (io_msStatus_15_bits_reqTag),
    .io_msStatus_15_bits_is_miss                (io_msStatus_15_bits_is_miss),
    .io_msStatus_15_bits_is_prefetch            (io_msStatus_15_bits_is_prefetch),
    .io_msAlloc_0_valid                         (io_msAlloc_0_valid),
    .io_msAlloc_0_bits_channel                  (io_msAlloc_0_bits_channel),
    .io_msAlloc_0_bits_is_miss                  (io_msAlloc_0_bits_is_miss),
    .io_msAlloc_0_bits_is_prefetch              (io_msAlloc_0_bits_is_prefetch),
    .io_msAlloc_1_valid                         (io_msAlloc_1_valid),
    .io_msAlloc_1_bits_channel                  (io_msAlloc_1_bits_channel),
    .io_msAlloc_1_bits_is_miss                  (io_msAlloc_1_bits_is_miss),
    .io_msAlloc_1_bits_is_prefetch              (io_msAlloc_1_bits_is_prefetch),
    .io_msAlloc_2_valid                         (io_msAlloc_2_valid),
    .io_msAlloc_2_bits_channel                  (io_msAlloc_2_bits_channel),
    .io_msAlloc_2_bits_is_miss                  (io_msAlloc_2_bits_is_miss),
    .io_msAlloc_2_bits_is_prefetch              (io_msAlloc_2_bits_is_prefetch),
    .io_msAlloc_3_valid                         (io_msAlloc_3_valid),
    .io_msAlloc_3_bits_channel                  (io_msAlloc_3_bits_channel),
    .io_msAlloc_3_bits_is_miss                  (io_msAlloc_3_bits_is_miss),
    .io_msAlloc_3_bits_is_prefetch              (io_msAlloc_3_bits_is_prefetch),
    .io_msAlloc_4_valid                         (io_msAlloc_4_valid),
    .io_msAlloc_4_bits_channel                  (io_msAlloc_4_bits_channel),
    .io_msAlloc_4_bits_is_miss                  (io_msAlloc_4_bits_is_miss),
    .io_msAlloc_4_bits_is_prefetch              (io_msAlloc_4_bits_is_prefetch),
    .io_msAlloc_5_valid                         (io_msAlloc_5_valid),
    .io_msAlloc_5_bits_channel                  (io_msAlloc_5_bits_channel),
    .io_msAlloc_5_bits_is_miss                  (io_msAlloc_5_bits_is_miss),
    .io_msAlloc_5_bits_is_prefetch              (io_msAlloc_5_bits_is_prefetch),
    .io_msAlloc_6_valid                         (io_msAlloc_6_valid),
    .io_msAlloc_6_bits_channel                  (io_msAlloc_6_bits_channel),
    .io_msAlloc_6_bits_is_miss                  (io_msAlloc_6_bits_is_miss),
    .io_msAlloc_6_bits_is_prefetch              (io_msAlloc_6_bits_is_prefetch),
    .io_msAlloc_7_valid                         (io_msAlloc_7_valid),
    .io_msAlloc_7_bits_channel                  (io_msAlloc_7_bits_channel),
    .io_msAlloc_7_bits_is_miss                  (io_msAlloc_7_bits_is_miss),
    .io_msAlloc_7_bits_is_prefetch              (io_msAlloc_7_bits_is_prefetch),
    .io_msAlloc_8_valid                         (io_msAlloc_8_valid),
    .io_msAlloc_8_bits_channel                  (io_msAlloc_8_bits_channel),
    .io_msAlloc_8_bits_is_miss                  (io_msAlloc_8_bits_is_miss),
    .io_msAlloc_8_bits_is_prefetch              (io_msAlloc_8_bits_is_prefetch),
    .io_msAlloc_9_valid                         (io_msAlloc_9_valid),
    .io_msAlloc_9_bits_channel                  (io_msAlloc_9_bits_channel),
    .io_msAlloc_9_bits_is_miss                  (io_msAlloc_9_bits_is_miss),
    .io_msAlloc_9_bits_is_prefetch              (io_msAlloc_9_bits_is_prefetch),
    .io_msAlloc_10_valid                        (io_msAlloc_10_valid),
    .io_msAlloc_10_bits_channel                 (io_msAlloc_10_bits_channel),
    .io_msAlloc_10_bits_is_miss                 (io_msAlloc_10_bits_is_miss),
    .io_msAlloc_10_bits_is_prefetch             (io_msAlloc_10_bits_is_prefetch),
    .io_msAlloc_11_valid                        (io_msAlloc_11_valid),
    .io_msAlloc_11_bits_channel                 (io_msAlloc_11_bits_channel),
    .io_msAlloc_11_bits_is_miss                 (io_msAlloc_11_bits_is_miss),
    .io_msAlloc_11_bits_is_prefetch             (io_msAlloc_11_bits_is_prefetch),
    .io_msAlloc_12_valid                        (io_msAlloc_12_valid),
    .io_msAlloc_12_bits_channel                 (io_msAlloc_12_bits_channel),
    .io_msAlloc_12_bits_is_miss                 (io_msAlloc_12_bits_is_miss),
    .io_msAlloc_12_bits_is_prefetch             (io_msAlloc_12_bits_is_prefetch),
    .io_msAlloc_13_valid                        (io_msAlloc_13_valid),
    .io_msAlloc_13_bits_channel                 (io_msAlloc_13_bits_channel),
    .io_msAlloc_13_bits_is_miss                 (io_msAlloc_13_bits_is_miss),
    .io_msAlloc_13_bits_is_prefetch             (io_msAlloc_13_bits_is_prefetch),
    .io_msAlloc_14_valid                        (io_msAlloc_14_valid),
    .io_msAlloc_14_bits_channel                 (io_msAlloc_14_bits_channel),
    .io_msAlloc_14_bits_is_miss                 (io_msAlloc_14_bits_is_miss),
    .io_msAlloc_14_bits_is_prefetch             (io_msAlloc_14_bits_is_prefetch),
    .io_msAlloc_15_valid                        (io_msAlloc_15_valid),
    .io_msAlloc_15_bits_channel                 (io_msAlloc_15_bits_channel),
    .io_msAlloc_15_bits_is_miss                 (io_msAlloc_15_bits_is_miss),
    .io_msAlloc_15_bits_is_prefetch             (io_msAlloc_15_bits_is_prefetch),
    .io_out_tx_req_ready                        (io_out_tx_req_ready),
    .io_out_tx_req_valid                        (io_out_tx_req_valid),
    .io_out_tx_req_bits_qos                     (io_out_tx_req_bits_qos),
    .io_out_tx_req_bits_txnID                   (io_out_tx_req_bits_txnID),
    .io_out_tx_req_bits_returnNID               (io_out_tx_req_bits_returnNID),
    .io_out_tx_req_bits_stashNIDValid           (io_out_tx_req_bits_stashNIDValid),
    .io_out_tx_req_bits_returnTxnID             (io_out_tx_req_bits_returnTxnID),
    .io_out_tx_req_bits_opcode                  (io_out_tx_req_bits_opcode),
    .io_out_tx_req_bits_addr                    (io_out_tx_req_bits_addr),
    .io_out_tx_req_bits_ns                      (io_out_tx_req_bits_ns),
    .io_out_tx_req_bits_likelyshared            (io_out_tx_req_bits_likelyshared),
    .io_out_tx_req_bits_allowRetry              (io_out_tx_req_bits_allowRetry),
    .io_out_tx_req_bits_order                   (io_out_tx_req_bits_order),
    .io_out_tx_req_bits_pCrdType                (io_out_tx_req_bits_pCrdType),
    .io_out_tx_req_bits_memAttr_allocate        (io_out_tx_req_bits_memAttr_allocate),
    .io_out_tx_req_bits_memAttr_cacheable       (io_out_tx_req_bits_memAttr_cacheable),
    .io_out_tx_req_bits_memAttr_device          (io_out_tx_req_bits_memAttr_device),
    .io_out_tx_req_bits_memAttr_ewa             (io_out_tx_req_bits_memAttr_ewa),
    .io_out_tx_req_bits_snpAttr                 (io_out_tx_req_bits_snpAttr),
    .io_out_tx_req_bits_lpIDWithPadding         (io_out_tx_req_bits_lpIDWithPadding),
    .io_out_tx_req_bits_snoopMe                 (io_out_tx_req_bits_snoopMe),
    .io_out_tx_req_bits_expCompAck              (io_out_tx_req_bits_expCompAck),
    .io_out_tx_req_bits_tagOp                   (io_out_tx_req_bits_tagOp),
    .io_out_tx_req_bits_traceTag                (io_out_tx_req_bits_traceTag),
    .io_out_tx_req_bits_mpam_perfMonGroup       (io_out_tx_req_bits_mpam_perfMonGroup),
    .io_out_tx_req_bits_mpam_partID             (io_out_tx_req_bits_mpam_partID),
    .io_out_tx_req_bits_mpam_mpamNS             (io_out_tx_req_bits_mpam_mpamNS),
    .io_out_tx_req_bits_rsvdc                   (io_out_tx_req_bits_rsvdc),
    .io_out_tx_rsp_ready                        (io_out_tx_rsp_ready),
    .io_out_tx_rsp_valid                        (io_out_tx_rsp_valid),
    .io_out_tx_rsp_bits_qos                     (io_out_tx_rsp_bits_qos),
    .io_out_tx_rsp_bits_tgtID                   (io_out_tx_rsp_bits_tgtID),
    .io_out_tx_rsp_bits_txnID                   (io_out_tx_rsp_bits_txnID),
    .io_out_tx_rsp_bits_opcode                  (io_out_tx_rsp_bits_opcode),
    .io_out_tx_rsp_bits_respErr                 (io_out_tx_rsp_bits_respErr),
    .io_out_tx_rsp_bits_resp                    (io_out_tx_rsp_bits_resp),
    .io_out_tx_rsp_bits_fwdState                (io_out_tx_rsp_bits_fwdState),
    .io_out_tx_rsp_bits_cBusy                   (io_out_tx_rsp_bits_cBusy),
    .io_out_tx_rsp_bits_dbID                    (io_out_tx_rsp_bits_dbID),
    .io_out_tx_rsp_bits_pCrdType                (io_out_tx_rsp_bits_pCrdType),
    .io_out_tx_rsp_bits_tagOp                   (io_out_tx_rsp_bits_tagOp),
    .io_out_tx_rsp_bits_traceTag                (io_out_tx_rsp_bits_traceTag),
    .io_out_tx_dat_ready                        (io_out_tx_dat_ready),
    .io_out_tx_dat_valid                        (io_out_tx_dat_valid),
    .io_out_tx_dat_bits_tgtID                   (io_out_tx_dat_bits_tgtID),
    .io_out_tx_dat_bits_txnID                   (io_out_tx_dat_bits_txnID),
    .io_out_tx_dat_bits_homeNID                 (io_out_tx_dat_bits_homeNID),
    .io_out_tx_dat_bits_opcode                  (io_out_tx_dat_bits_opcode),
    .io_out_tx_dat_bits_respErr                 (io_out_tx_dat_bits_respErr),
    .io_out_tx_dat_bits_resp                    (io_out_tx_dat_bits_resp),
    .io_out_tx_dat_bits_dataSource              (io_out_tx_dat_bits_dataSource),
    .io_out_tx_dat_bits_dbID                    (io_out_tx_dat_bits_dbID),
    .io_out_tx_dat_bits_ccID                    (io_out_tx_dat_bits_ccID),
    .io_out_tx_dat_bits_dataID                  (io_out_tx_dat_bits_dataID),
    .io_out_tx_dat_bits_traceTag                (io_out_tx_dat_bits_traceTag),
    .io_out_tx_dat_bits_be                      (io_out_tx_dat_bits_be),
    .io_out_tx_dat_bits_data                    (io_out_tx_dat_bits_data),
    .io_out_tx_dat_bits_dataCheck               (io_out_tx_dat_bits_dataCheck),
    .io_out_tx_dat_bits_poison                  (io_out_tx_dat_bits_poison),
    .io_out_rx_rsp_valid                        (io_out_rx_rsp_valid),
    .io_out_rx_rsp_bits_srcID                   (io_out_rx_rsp_bits_srcID),
    .io_out_rx_rsp_bits_txnID                   (io_out_rx_rsp_bits_txnID),
    .io_out_rx_rsp_bits_opcode                  (io_out_rx_rsp_bits_opcode),
    .io_out_rx_rsp_bits_respErr                 (io_out_rx_rsp_bits_respErr),
    .io_out_rx_rsp_bits_resp                    (io_out_rx_rsp_bits_resp),
    .io_out_rx_rsp_bits_dbID                    (io_out_rx_rsp_bits_dbID),
    .io_out_rx_rsp_bits_pCrdType                (io_out_rx_rsp_bits_pCrdType),
    .io_out_rx_rsp_bits_traceTag                (io_out_rx_rsp_bits_traceTag),
    .io_out_rx_dat_valid                        (io_out_rx_dat_valid),
    .io_out_rx_dat_bits_txnID                   (io_out_rx_dat_bits_txnID),
    .io_out_rx_dat_bits_homeNID                 (io_out_rx_dat_bits_homeNID),
    .io_out_rx_dat_bits_opcode                  (io_out_rx_dat_bits_opcode),
    .io_out_rx_dat_bits_respErr                 (io_out_rx_dat_bits_respErr),
    .io_out_rx_dat_bits_resp                    (io_out_rx_dat_bits_resp),
    .io_out_rx_dat_bits_dbID                    (io_out_rx_dat_bits_dbID),
    .io_out_rx_dat_bits_dataID                  (io_out_rx_dat_bits_dataID),
    .io_out_rx_dat_bits_traceTag                (io_out_rx_dat_bits_traceTag),
    .io_out_rx_dat_bits_data                    (io_out_rx_dat_bits_data),
    .io_out_rx_dat_bits_dataCheck               (io_out_rx_dat_bits_dataCheck),
    .io_out_rx_dat_bits_poison                  (io_out_rx_dat_bits_poison),
    .io_out_rx_snp_ready                        (io_out_rx_snp_ready),
    .io_out_rx_snp_valid                        (io_out_rx_snp_valid),
    .io_out_rx_snp_bits_qos                     (io_out_rx_snp_bits_qos),
    .io_out_rx_snp_bits_srcID                   (io_out_rx_snp_bits_srcID),
    .io_out_rx_snp_bits_txnID                   (io_out_rx_snp_bits_txnID),
    .io_out_rx_snp_bits_fwdNID                  (io_out_rx_snp_bits_fwdNID),
    .io_out_rx_snp_bits_fwdTxnID                (io_out_rx_snp_bits_fwdTxnID),
    .io_out_rx_snp_bits_opcode                  (io_out_rx_snp_bits_opcode),
    .io_out_rx_snp_bits_addr                    (io_out_rx_snp_bits_addr),
    .io_out_rx_snp_bits_ns                      (io_out_rx_snp_bits_ns),
    .io_out_rx_snp_bits_doNotGoToSD             (io_out_rx_snp_bits_doNotGoToSD),
    .io_out_rx_snp_bits_retToSrc                (io_out_rx_snp_bits_retToSrc),
    .io_out_rx_snp_bits_traceTag                (io_out_rx_snp_bits_traceTag),
    .io_out_rx_snp_bits_mpam_perfMonGroup       (io_out_rx_snp_bits_mpam_perfMonGroup),
    .io_out_rx_snp_bits_mpam_partID             (io_out_rx_snp_bits_mpam_partID),
    .io_out_rx_snp_bits_mpam_mpamNS             (io_out_rx_snp_bits_mpam_mpamNS),
    .io_pCrd_0_query_valid                      (io_pCrd_0_query_valid),
    .io_pCrd_0_query_bits_pCrdType              (io_pCrd_0_query_bits_pCrdType),
    .io_pCrd_0_query_bits_srcID                 (io_pCrd_0_query_bits_srcID),
    .io_pCrd_0_grant                            (io_pCrd_0_grant),
    .io_pCrd_1_query_valid                      (io_pCrd_1_query_valid),
    .io_pCrd_1_query_bits_pCrdType              (io_pCrd_1_query_bits_pCrdType),
    .io_pCrd_1_query_bits_srcID                 (io_pCrd_1_query_bits_srcID),
    .io_pCrd_1_grant                            (io_pCrd_1_grant),
    .io_pCrd_2_query_valid                      (io_pCrd_2_query_valid),
    .io_pCrd_2_query_bits_pCrdType              (io_pCrd_2_query_bits_pCrdType),
    .io_pCrd_2_query_bits_srcID                 (io_pCrd_2_query_bits_srcID),
    .io_pCrd_2_grant                            (io_pCrd_2_grant),
    .io_pCrd_3_query_valid                      (io_pCrd_3_query_valid),
    .io_pCrd_3_query_bits_pCrdType              (io_pCrd_3_query_bits_pCrdType),
    .io_pCrd_3_query_bits_srcID                 (io_pCrd_3_query_bits_srcID),
    .io_pCrd_3_grant                            (io_pCrd_3_grant),
    .io_pCrd_4_query_valid                      (io_pCrd_4_query_valid),
    .io_pCrd_4_query_bits_pCrdType              (io_pCrd_4_query_bits_pCrdType),
    .io_pCrd_4_query_bits_srcID                 (io_pCrd_4_query_bits_srcID),
    .io_pCrd_4_grant                            (io_pCrd_4_grant),
    .io_pCrd_5_query_valid                      (io_pCrd_5_query_valid),
    .io_pCrd_5_query_bits_pCrdType              (io_pCrd_5_query_bits_pCrdType),
    .io_pCrd_5_query_bits_srcID                 (io_pCrd_5_query_bits_srcID),
    .io_pCrd_5_grant                            (io_pCrd_5_grant),
    .io_pCrd_6_query_valid                      (io_pCrd_6_query_valid),
    .io_pCrd_6_query_bits_pCrdType              (io_pCrd_6_query_bits_pCrdType),
    .io_pCrd_6_query_bits_srcID                 (io_pCrd_6_query_bits_srcID),
    .io_pCrd_6_grant                            (io_pCrd_6_grant),
    .io_pCrd_7_query_valid                      (io_pCrd_7_query_valid),
    .io_pCrd_7_query_bits_pCrdType              (io_pCrd_7_query_bits_pCrdType),
    .io_pCrd_7_query_bits_srcID                 (io_pCrd_7_query_bits_srcID),
    .io_pCrd_7_grant                            (io_pCrd_7_grant),
    .io_pCrd_8_query_valid                      (io_pCrd_8_query_valid),
    .io_pCrd_8_query_bits_pCrdType              (io_pCrd_8_query_bits_pCrdType),
    .io_pCrd_8_query_bits_srcID                 (io_pCrd_8_query_bits_srcID),
    .io_pCrd_8_grant                            (io_pCrd_8_grant),
    .io_pCrd_9_query_valid                      (io_pCrd_9_query_valid),
    .io_pCrd_9_query_bits_pCrdType              (io_pCrd_9_query_bits_pCrdType),
    .io_pCrd_9_query_bits_srcID                 (io_pCrd_9_query_bits_srcID),
    .io_pCrd_9_grant                            (io_pCrd_9_grant),
    .io_pCrd_10_query_valid                     (io_pCrd_10_query_valid),
    .io_pCrd_10_query_bits_pCrdType             (io_pCrd_10_query_bits_pCrdType),
    .io_pCrd_10_query_bits_srcID                (io_pCrd_10_query_bits_srcID),
    .io_pCrd_10_grant                           (io_pCrd_10_grant),
    .io_pCrd_11_query_valid                     (io_pCrd_11_query_valid),
    .io_pCrd_11_query_bits_pCrdType             (io_pCrd_11_query_bits_pCrdType),
    .io_pCrd_11_query_bits_srcID                (io_pCrd_11_query_bits_srcID),
    .io_pCrd_11_grant                           (io_pCrd_11_grant),
    .io_pCrd_12_query_valid                     (io_pCrd_12_query_valid),
    .io_pCrd_12_query_bits_pCrdType             (io_pCrd_12_query_bits_pCrdType),
    .io_pCrd_12_query_bits_srcID                (io_pCrd_12_query_bits_srcID),
    .io_pCrd_12_grant                           (io_pCrd_12_grant),
    .io_pCrd_13_query_valid                     (io_pCrd_13_query_valid),
    .io_pCrd_13_query_bits_pCrdType             (io_pCrd_13_query_bits_pCrdType),
    .io_pCrd_13_query_bits_srcID                (io_pCrd_13_query_bits_srcID),
    .io_pCrd_13_grant                           (io_pCrd_13_grant),
    .io_pCrd_14_query_valid                     (io_pCrd_14_query_valid),
    .io_pCrd_14_query_bits_pCrdType             (io_pCrd_14_query_bits_pCrdType),
    .io_pCrd_14_query_bits_srcID                (io_pCrd_14_query_bits_srcID),
    .io_pCrd_14_grant                           (io_pCrd_14_grant),
    .io_pCrd_15_query_valid                     (io_pCrd_15_query_valid),
    .io_pCrd_15_query_bits_pCrdType             (io_pCrd_15_query_bits_pCrdType),
    .io_pCrd_15_query_bits_srcID                (io_pCrd_15_query_bits_srcID),
    .io_pCrd_15_grant                           (io_pCrd_15_grant),
    .io_perf_0_value                            (io_perf_0_value),
    .io_perf_1_value                            (io_perf_1_value),
    .io_perf_3_value                            (io_perf_3_value),
    .io_perf_4_value                            (io_perf_4_value),
    .io_perf_5_value                            (io_perf_5_value),
    .io_perf_6_value                            (io_perf_6_value),
    .io_perf_7_value                            (io_perf_7_value),
    .io_perf_8_value                            (io_perf_8_value),
    .io_perf_9_value                            (io_perf_9_value),
    .io_perf_10_value                           (io_perf_10_value),
    .io_perf_11_value                           (io_perf_11_value),
    .io_perf_12_value                           (io_perf_12_value),
    .io_perf_13_value                           (io_perf_13_value),
    .io_perf_14_value                           (io_perf_14_value),
    .io_perf_15_value                           (io_perf_15_value),
    .io_perf_16_value                           (io_perf_16_value),
    .dir_read_ready                             (dir_read_ready),
    .dir_read_valid                             (dir_read_valid),
    .dir_read_bits_tag                          (dir_read_bits_tag),
    .dir_read_bits_set                          (dir_read_bits_set),
    .dir_read_bits_wayMask                      (dir_read_bits_wayMask),
    .dir_read_bits_replacerInfo_channel         (dir_read_bits_replacerInfo_channel),
    .dir_read_bits_replacerInfo_opcode          (dir_read_bits_replacerInfo_opcode),
    .dir_read_bits_replacerInfo_reqSource       (dir_read_bits_replacerInfo_reqSource),
    .dir_read_bits_replacerInfo_refill_prefetch (dir_read_bits_replacerInfo_refill_prefetch),
    .dir_read_bits_refill                       (dir_read_bits_refill),
    .dir_read_bits_mshrId                       (dir_read_bits_mshrId),
    .dir_read_bits_cmoAll                       (dir_read_bits_cmoAll),
    .dir_read_bits_cmoWay                       (dir_read_bits_cmoWay),
    .dir_resp_valid                             (dir_resp_valid),
    .dir_resp_bits_hit                          (dir_resp_bits_hit),
    .dir_resp_bits_tag                          (dir_resp_bits_tag),
    .dir_resp_bits_set                          (dir_resp_bits_set),
    .dir_resp_bits_way                          (dir_resp_bits_way),
    .dir_resp_bits_meta_dirty                   (dir_resp_bits_meta_dirty),
    .dir_resp_bits_meta_state                   (dir_resp_bits_meta_state),
    .dir_resp_bits_meta_clients                 (dir_resp_bits_meta_clients),
    .dir_resp_bits_meta_alias                   (dir_resp_bits_meta_alias),
    .dir_resp_bits_meta_prefetch                (dir_resp_bits_meta_prefetch),
    .dir_resp_bits_meta_prefetchSrc             (dir_resp_bits_meta_prefetchSrc),
    .dir_resp_bits_meta_accessed                (dir_resp_bits_meta_accessed),
    .dir_resp_bits_meta_tagErr                  (dir_resp_bits_meta_tagErr),
    .dir_resp_bits_meta_dataErr                 (dir_resp_bits_meta_dataErr),
    .dir_resp_bits_error                        (dir_resp_bits_error),
    .dir_metaWReq_valid                         (dir_metaWReq_valid),
    .dir_metaWReq_bits_set                      (dir_metaWReq_bits_set),
    .dir_metaWReq_bits_wayOH                    (dir_metaWReq_bits_wayOH),
    .dir_metaWReq_bits_wmeta_dirty              (dir_metaWReq_bits_wmeta_dirty),
    .dir_metaWReq_bits_wmeta_state              (dir_metaWReq_bits_wmeta_state),
    .dir_metaWReq_bits_wmeta_clients            (dir_metaWReq_bits_wmeta_clients),
    .dir_metaWReq_bits_wmeta_alias              (dir_metaWReq_bits_wmeta_alias),
    .dir_metaWReq_bits_wmeta_prefetch           (dir_metaWReq_bits_wmeta_prefetch),
    .dir_metaWReq_bits_wmeta_prefetchSrc        (dir_metaWReq_bits_wmeta_prefetchSrc),
    .dir_metaWReq_bits_wmeta_accessed           (dir_metaWReq_bits_wmeta_accessed),
    .dir_metaWReq_bits_wmeta_tagErr             (dir_metaWReq_bits_wmeta_tagErr),
    .dir_metaWReq_bits_wmeta_dataErr            (dir_metaWReq_bits_wmeta_dataErr),
    .dir_tagWReq_valid                          (dir_tagWReq_valid),
    .dir_tagWReq_bits_set                       (dir_tagWReq_bits_set),
    .dir_tagWReq_bits_way                       (dir_tagWReq_bits_way),
    .dir_tagWReq_bits_wtag                      (dir_tagWReq_bits_wtag),
    .dir_replResp_valid                         (dir_replResp_valid),
    .dir_replResp_bits_tag                      (dir_replResp_bits_tag),
    .dir_replResp_bits_way                      (dir_replResp_bits_way),
    .dir_replResp_bits_meta_dirty               (dir_replResp_bits_meta_dirty),
    .dir_replResp_bits_meta_state               (dir_replResp_bits_meta_state),
    .dir_replResp_bits_meta_clients             (dir_replResp_bits_meta_clients),
    .dir_replResp_bits_meta_alias               (dir_replResp_bits_meta_alias),
    .dir_replResp_bits_meta_prefetch            (dir_replResp_bits_meta_prefetch),
    .dir_replResp_bits_meta_prefetchSrc         (dir_replResp_bits_meta_prefetchSrc),
    .dir_replResp_bits_meta_accessed            (dir_replResp_bits_meta_accessed),
    .dir_replResp_bits_meta_tagErr              (dir_replResp_bits_meta_tagErr),
    .dir_replResp_bits_meta_dataErr             (dir_replResp_bits_meta_dataErr),
    .dir_replResp_bits_mshrId                   (dir_replResp_bits_mshrId),
    .dir_replResp_bits_retry                    (dir_replResp_bits_retry),
    .dir_replResp_bits_error                    (dir_replResp_bits_error),
    .dir_msInfo_0_valid                         (dir_msInfo_0_valid),
    .dir_msInfo_0_bits_channel                  (dir_msInfo_0_bits_channel),
    .dir_msInfo_0_bits_set                      (dir_msInfo_0_bits_set),
    .dir_msInfo_0_bits_way                      (dir_msInfo_0_bits_way),
    .dir_msInfo_0_bits_reqTag                   (dir_msInfo_0_bits_reqTag),
    .dir_msInfo_0_bits_willFree                 (dir_msInfo_0_bits_willFree),
    .dir_msInfo_0_bits_aliasTask                (dir_msInfo_0_bits_aliasTask),
    .dir_msInfo_0_bits_needRelease              (dir_msInfo_0_bits_needRelease),
    .dir_msInfo_0_bits_blockRefill              (dir_msInfo_0_bits_blockRefill),
    .dir_msInfo_0_bits_meta_dirty               (dir_msInfo_0_bits_meta_dirty),
    .dir_msInfo_0_bits_meta_state               (dir_msInfo_0_bits_meta_state),
    .dir_msInfo_0_bits_meta_clients             (dir_msInfo_0_bits_meta_clients),
    .dir_msInfo_0_bits_meta_alias               (dir_msInfo_0_bits_meta_alias),
    .dir_msInfo_0_bits_meta_prefetch            (dir_msInfo_0_bits_meta_prefetch),
    .dir_msInfo_0_bits_meta_prefetchSrc         (dir_msInfo_0_bits_meta_prefetchSrc),
    .dir_msInfo_0_bits_meta_accessed            (dir_msInfo_0_bits_meta_accessed),
    .dir_msInfo_0_bits_meta_tagErr              (dir_msInfo_0_bits_meta_tagErr),
    .dir_msInfo_0_bits_meta_dataErr             (dir_msInfo_0_bits_meta_dataErr),
    .dir_msInfo_0_bits_metaTag                  (dir_msInfo_0_bits_metaTag),
    .dir_msInfo_0_bits_dirHit                   (dir_msInfo_0_bits_dirHit),
    .dir_msInfo_0_bits_isAcqOrPrefetch          (dir_msInfo_0_bits_isAcqOrPrefetch),
    .dir_msInfo_0_bits_isPrefetch               (dir_msInfo_0_bits_isPrefetch),
    .dir_msInfo_0_bits_param                    (dir_msInfo_0_bits_param),
    .dir_msInfo_0_bits_mergeA                   (dir_msInfo_0_bits_mergeA),
    .dir_msInfo_0_bits_w_grantfirst             (dir_msInfo_0_bits_w_grantfirst),
    .dir_msInfo_0_bits_s_release                (dir_msInfo_0_bits_s_release),
    .dir_msInfo_0_bits_s_refill                 (dir_msInfo_0_bits_s_refill),
    .dir_msInfo_0_bits_s_cmoresp                (dir_msInfo_0_bits_s_cmoresp),
    .dir_msInfo_0_bits_s_cmometaw               (dir_msInfo_0_bits_s_cmometaw),
    .dir_msInfo_0_bits_w_releaseack             (dir_msInfo_0_bits_w_releaseack),
    .dir_msInfo_0_bits_w_replResp               (dir_msInfo_0_bits_w_replResp),
    .dir_msInfo_0_bits_w_rprobeacklast          (dir_msInfo_0_bits_w_rprobeacklast),
    .dir_msInfo_0_bits_replaceData              (dir_msInfo_0_bits_replaceData),
    .dir_msInfo_0_bits_releaseToClean           (dir_msInfo_0_bits_releaseToClean),
    .dir_msInfo_1_valid                         (dir_msInfo_1_valid),
    .dir_msInfo_1_bits_channel                  (dir_msInfo_1_bits_channel),
    .dir_msInfo_1_bits_set                      (dir_msInfo_1_bits_set),
    .dir_msInfo_1_bits_way                      (dir_msInfo_1_bits_way),
    .dir_msInfo_1_bits_reqTag                   (dir_msInfo_1_bits_reqTag),
    .dir_msInfo_1_bits_willFree                 (dir_msInfo_1_bits_willFree),
    .dir_msInfo_1_bits_aliasTask                (dir_msInfo_1_bits_aliasTask),
    .dir_msInfo_1_bits_needRelease              (dir_msInfo_1_bits_needRelease),
    .dir_msInfo_1_bits_blockRefill              (dir_msInfo_1_bits_blockRefill),
    .dir_msInfo_1_bits_meta_dirty               (dir_msInfo_1_bits_meta_dirty),
    .dir_msInfo_1_bits_meta_state               (dir_msInfo_1_bits_meta_state),
    .dir_msInfo_1_bits_meta_clients             (dir_msInfo_1_bits_meta_clients),
    .dir_msInfo_1_bits_meta_alias               (dir_msInfo_1_bits_meta_alias),
    .dir_msInfo_1_bits_meta_prefetch            (dir_msInfo_1_bits_meta_prefetch),
    .dir_msInfo_1_bits_meta_prefetchSrc         (dir_msInfo_1_bits_meta_prefetchSrc),
    .dir_msInfo_1_bits_meta_accessed            (dir_msInfo_1_bits_meta_accessed),
    .dir_msInfo_1_bits_meta_tagErr              (dir_msInfo_1_bits_meta_tagErr),
    .dir_msInfo_1_bits_meta_dataErr             (dir_msInfo_1_bits_meta_dataErr),
    .dir_msInfo_1_bits_metaTag                  (dir_msInfo_1_bits_metaTag),
    .dir_msInfo_1_bits_dirHit                   (dir_msInfo_1_bits_dirHit),
    .dir_msInfo_1_bits_isAcqOrPrefetch          (dir_msInfo_1_bits_isAcqOrPrefetch),
    .dir_msInfo_1_bits_isPrefetch               (dir_msInfo_1_bits_isPrefetch),
    .dir_msInfo_1_bits_param                    (dir_msInfo_1_bits_param),
    .dir_msInfo_1_bits_mergeA                   (dir_msInfo_1_bits_mergeA),
    .dir_msInfo_1_bits_w_grantfirst             (dir_msInfo_1_bits_w_grantfirst),
    .dir_msInfo_1_bits_s_release                (dir_msInfo_1_bits_s_release),
    .dir_msInfo_1_bits_s_refill                 (dir_msInfo_1_bits_s_refill),
    .dir_msInfo_1_bits_s_cmoresp                (dir_msInfo_1_bits_s_cmoresp),
    .dir_msInfo_1_bits_s_cmometaw               (dir_msInfo_1_bits_s_cmometaw),
    .dir_msInfo_1_bits_w_releaseack             (dir_msInfo_1_bits_w_releaseack),
    .dir_msInfo_1_bits_w_replResp               (dir_msInfo_1_bits_w_replResp),
    .dir_msInfo_1_bits_w_rprobeacklast          (dir_msInfo_1_bits_w_rprobeacklast),
    .dir_msInfo_1_bits_replaceData              (dir_msInfo_1_bits_replaceData),
    .dir_msInfo_1_bits_releaseToClean           (dir_msInfo_1_bits_releaseToClean),
    .dir_msInfo_2_valid                         (dir_msInfo_2_valid),
    .dir_msInfo_2_bits_channel                  (dir_msInfo_2_bits_channel),
    .dir_msInfo_2_bits_set                      (dir_msInfo_2_bits_set),
    .dir_msInfo_2_bits_way                      (dir_msInfo_2_bits_way),
    .dir_msInfo_2_bits_reqTag                   (dir_msInfo_2_bits_reqTag),
    .dir_msInfo_2_bits_willFree                 (dir_msInfo_2_bits_willFree),
    .dir_msInfo_2_bits_aliasTask                (dir_msInfo_2_bits_aliasTask),
    .dir_msInfo_2_bits_needRelease              (dir_msInfo_2_bits_needRelease),
    .dir_msInfo_2_bits_blockRefill              (dir_msInfo_2_bits_blockRefill),
    .dir_msInfo_2_bits_meta_dirty               (dir_msInfo_2_bits_meta_dirty),
    .dir_msInfo_2_bits_meta_state               (dir_msInfo_2_bits_meta_state),
    .dir_msInfo_2_bits_meta_clients             (dir_msInfo_2_bits_meta_clients),
    .dir_msInfo_2_bits_meta_alias               (dir_msInfo_2_bits_meta_alias),
    .dir_msInfo_2_bits_meta_prefetch            (dir_msInfo_2_bits_meta_prefetch),
    .dir_msInfo_2_bits_meta_prefetchSrc         (dir_msInfo_2_bits_meta_prefetchSrc),
    .dir_msInfo_2_bits_meta_accessed            (dir_msInfo_2_bits_meta_accessed),
    .dir_msInfo_2_bits_meta_tagErr              (dir_msInfo_2_bits_meta_tagErr),
    .dir_msInfo_2_bits_meta_dataErr             (dir_msInfo_2_bits_meta_dataErr),
    .dir_msInfo_2_bits_metaTag                  (dir_msInfo_2_bits_metaTag),
    .dir_msInfo_2_bits_dirHit                   (dir_msInfo_2_bits_dirHit),
    .dir_msInfo_2_bits_isAcqOrPrefetch          (dir_msInfo_2_bits_isAcqOrPrefetch),
    .dir_msInfo_2_bits_isPrefetch               (dir_msInfo_2_bits_isPrefetch),
    .dir_msInfo_2_bits_param                    (dir_msInfo_2_bits_param),
    .dir_msInfo_2_bits_mergeA                   (dir_msInfo_2_bits_mergeA),
    .dir_msInfo_2_bits_w_grantfirst             (dir_msInfo_2_bits_w_grantfirst),
    .dir_msInfo_2_bits_s_release                (dir_msInfo_2_bits_s_release),
    .dir_msInfo_2_bits_s_refill                 (dir_msInfo_2_bits_s_refill),
    .dir_msInfo_2_bits_s_cmoresp                (dir_msInfo_2_bits_s_cmoresp),
    .dir_msInfo_2_bits_s_cmometaw               (dir_msInfo_2_bits_s_cmometaw),
    .dir_msInfo_2_bits_w_releaseack             (dir_msInfo_2_bits_w_releaseack),
    .dir_msInfo_2_bits_w_replResp               (dir_msInfo_2_bits_w_replResp),
    .dir_msInfo_2_bits_w_rprobeacklast          (dir_msInfo_2_bits_w_rprobeacklast),
    .dir_msInfo_2_bits_replaceData              (dir_msInfo_2_bits_replaceData),
    .dir_msInfo_2_bits_releaseToClean           (dir_msInfo_2_bits_releaseToClean),
    .dir_msInfo_3_valid                         (dir_msInfo_3_valid),
    .dir_msInfo_3_bits_channel                  (dir_msInfo_3_bits_channel),
    .dir_msInfo_3_bits_set                      (dir_msInfo_3_bits_set),
    .dir_msInfo_3_bits_way                      (dir_msInfo_3_bits_way),
    .dir_msInfo_3_bits_reqTag                   (dir_msInfo_3_bits_reqTag),
    .dir_msInfo_3_bits_willFree                 (dir_msInfo_3_bits_willFree),
    .dir_msInfo_3_bits_aliasTask                (dir_msInfo_3_bits_aliasTask),
    .dir_msInfo_3_bits_needRelease              (dir_msInfo_3_bits_needRelease),
    .dir_msInfo_3_bits_blockRefill              (dir_msInfo_3_bits_blockRefill),
    .dir_msInfo_3_bits_meta_dirty               (dir_msInfo_3_bits_meta_dirty),
    .dir_msInfo_3_bits_meta_state               (dir_msInfo_3_bits_meta_state),
    .dir_msInfo_3_bits_meta_clients             (dir_msInfo_3_bits_meta_clients),
    .dir_msInfo_3_bits_meta_alias               (dir_msInfo_3_bits_meta_alias),
    .dir_msInfo_3_bits_meta_prefetch            (dir_msInfo_3_bits_meta_prefetch),
    .dir_msInfo_3_bits_meta_prefetchSrc         (dir_msInfo_3_bits_meta_prefetchSrc),
    .dir_msInfo_3_bits_meta_accessed            (dir_msInfo_3_bits_meta_accessed),
    .dir_msInfo_3_bits_meta_tagErr              (dir_msInfo_3_bits_meta_tagErr),
    .dir_msInfo_3_bits_meta_dataErr             (dir_msInfo_3_bits_meta_dataErr),
    .dir_msInfo_3_bits_metaTag                  (dir_msInfo_3_bits_metaTag),
    .dir_msInfo_3_bits_dirHit                   (dir_msInfo_3_bits_dirHit),
    .dir_msInfo_3_bits_isAcqOrPrefetch          (dir_msInfo_3_bits_isAcqOrPrefetch),
    .dir_msInfo_3_bits_isPrefetch               (dir_msInfo_3_bits_isPrefetch),
    .dir_msInfo_3_bits_param                    (dir_msInfo_3_bits_param),
    .dir_msInfo_3_bits_mergeA                   (dir_msInfo_3_bits_mergeA),
    .dir_msInfo_3_bits_w_grantfirst             (dir_msInfo_3_bits_w_grantfirst),
    .dir_msInfo_3_bits_s_release                (dir_msInfo_3_bits_s_release),
    .dir_msInfo_3_bits_s_refill                 (dir_msInfo_3_bits_s_refill),
    .dir_msInfo_3_bits_s_cmoresp                (dir_msInfo_3_bits_s_cmoresp),
    .dir_msInfo_3_bits_s_cmometaw               (dir_msInfo_3_bits_s_cmometaw),
    .dir_msInfo_3_bits_w_releaseack             (dir_msInfo_3_bits_w_releaseack),
    .dir_msInfo_3_bits_w_replResp               (dir_msInfo_3_bits_w_replResp),
    .dir_msInfo_3_bits_w_rprobeacklast          (dir_msInfo_3_bits_w_rprobeacklast),
    .dir_msInfo_3_bits_replaceData              (dir_msInfo_3_bits_replaceData),
    .dir_msInfo_3_bits_releaseToClean           (dir_msInfo_3_bits_releaseToClean),
    .dir_msInfo_4_valid                         (dir_msInfo_4_valid),
    .dir_msInfo_4_bits_channel                  (dir_msInfo_4_bits_channel),
    .dir_msInfo_4_bits_set                      (dir_msInfo_4_bits_set),
    .dir_msInfo_4_bits_way                      (dir_msInfo_4_bits_way),
    .dir_msInfo_4_bits_reqTag                   (dir_msInfo_4_bits_reqTag),
    .dir_msInfo_4_bits_willFree                 (dir_msInfo_4_bits_willFree),
    .dir_msInfo_4_bits_aliasTask                (dir_msInfo_4_bits_aliasTask),
    .dir_msInfo_4_bits_needRelease              (dir_msInfo_4_bits_needRelease),
    .dir_msInfo_4_bits_blockRefill              (dir_msInfo_4_bits_blockRefill),
    .dir_msInfo_4_bits_meta_dirty               (dir_msInfo_4_bits_meta_dirty),
    .dir_msInfo_4_bits_meta_state               (dir_msInfo_4_bits_meta_state),
    .dir_msInfo_4_bits_meta_clients             (dir_msInfo_4_bits_meta_clients),
    .dir_msInfo_4_bits_meta_alias               (dir_msInfo_4_bits_meta_alias),
    .dir_msInfo_4_bits_meta_prefetch            (dir_msInfo_4_bits_meta_prefetch),
    .dir_msInfo_4_bits_meta_prefetchSrc         (dir_msInfo_4_bits_meta_prefetchSrc),
    .dir_msInfo_4_bits_meta_accessed            (dir_msInfo_4_bits_meta_accessed),
    .dir_msInfo_4_bits_meta_tagErr              (dir_msInfo_4_bits_meta_tagErr),
    .dir_msInfo_4_bits_meta_dataErr             (dir_msInfo_4_bits_meta_dataErr),
    .dir_msInfo_4_bits_metaTag                  (dir_msInfo_4_bits_metaTag),
    .dir_msInfo_4_bits_dirHit                   (dir_msInfo_4_bits_dirHit),
    .dir_msInfo_4_bits_isAcqOrPrefetch          (dir_msInfo_4_bits_isAcqOrPrefetch),
    .dir_msInfo_4_bits_isPrefetch               (dir_msInfo_4_bits_isPrefetch),
    .dir_msInfo_4_bits_param                    (dir_msInfo_4_bits_param),
    .dir_msInfo_4_bits_mergeA                   (dir_msInfo_4_bits_mergeA),
    .dir_msInfo_4_bits_w_grantfirst             (dir_msInfo_4_bits_w_grantfirst),
    .dir_msInfo_4_bits_s_release                (dir_msInfo_4_bits_s_release),
    .dir_msInfo_4_bits_s_refill                 (dir_msInfo_4_bits_s_refill),
    .dir_msInfo_4_bits_s_cmoresp                (dir_msInfo_4_bits_s_cmoresp),
    .dir_msInfo_4_bits_s_cmometaw               (dir_msInfo_4_bits_s_cmometaw),
    .dir_msInfo_4_bits_w_releaseack             (dir_msInfo_4_bits_w_releaseack),
    .dir_msInfo_4_bits_w_replResp               (dir_msInfo_4_bits_w_replResp),
    .dir_msInfo_4_bits_w_rprobeacklast          (dir_msInfo_4_bits_w_rprobeacklast),
    .dir_msInfo_4_bits_replaceData              (dir_msInfo_4_bits_replaceData),
    .dir_msInfo_4_bits_releaseToClean           (dir_msInfo_4_bits_releaseToClean),
    .dir_msInfo_5_valid                         (dir_msInfo_5_valid),
    .dir_msInfo_5_bits_channel                  (dir_msInfo_5_bits_channel),
    .dir_msInfo_5_bits_set                      (dir_msInfo_5_bits_set),
    .dir_msInfo_5_bits_way                      (dir_msInfo_5_bits_way),
    .dir_msInfo_5_bits_reqTag                   (dir_msInfo_5_bits_reqTag),
    .dir_msInfo_5_bits_willFree                 (dir_msInfo_5_bits_willFree),
    .dir_msInfo_5_bits_aliasTask                (dir_msInfo_5_bits_aliasTask),
    .dir_msInfo_5_bits_needRelease              (dir_msInfo_5_bits_needRelease),
    .dir_msInfo_5_bits_blockRefill              (dir_msInfo_5_bits_blockRefill),
    .dir_msInfo_5_bits_meta_dirty               (dir_msInfo_5_bits_meta_dirty),
    .dir_msInfo_5_bits_meta_state               (dir_msInfo_5_bits_meta_state),
    .dir_msInfo_5_bits_meta_clients             (dir_msInfo_5_bits_meta_clients),
    .dir_msInfo_5_bits_meta_alias               (dir_msInfo_5_bits_meta_alias),
    .dir_msInfo_5_bits_meta_prefetch            (dir_msInfo_5_bits_meta_prefetch),
    .dir_msInfo_5_bits_meta_prefetchSrc         (dir_msInfo_5_bits_meta_prefetchSrc),
    .dir_msInfo_5_bits_meta_accessed            (dir_msInfo_5_bits_meta_accessed),
    .dir_msInfo_5_bits_meta_tagErr              (dir_msInfo_5_bits_meta_tagErr),
    .dir_msInfo_5_bits_meta_dataErr             (dir_msInfo_5_bits_meta_dataErr),
    .dir_msInfo_5_bits_metaTag                  (dir_msInfo_5_bits_metaTag),
    .dir_msInfo_5_bits_dirHit                   (dir_msInfo_5_bits_dirHit),
    .dir_msInfo_5_bits_isAcqOrPrefetch          (dir_msInfo_5_bits_isAcqOrPrefetch),
    .dir_msInfo_5_bits_isPrefetch               (dir_msInfo_5_bits_isPrefetch),
    .dir_msInfo_5_bits_param                    (dir_msInfo_5_bits_param),
    .dir_msInfo_5_bits_mergeA                   (dir_msInfo_5_bits_mergeA),
    .dir_msInfo_5_bits_w_grantfirst             (dir_msInfo_5_bits_w_grantfirst),
    .dir_msInfo_5_bits_s_release                (dir_msInfo_5_bits_s_release),
    .dir_msInfo_5_bits_s_refill                 (dir_msInfo_5_bits_s_refill),
    .dir_msInfo_5_bits_s_cmoresp                (dir_msInfo_5_bits_s_cmoresp),
    .dir_msInfo_5_bits_s_cmometaw               (dir_msInfo_5_bits_s_cmometaw),
    .dir_msInfo_5_bits_w_releaseack             (dir_msInfo_5_bits_w_releaseack),
    .dir_msInfo_5_bits_w_replResp               (dir_msInfo_5_bits_w_replResp),
    .dir_msInfo_5_bits_w_rprobeacklast          (dir_msInfo_5_bits_w_rprobeacklast),
    .dir_msInfo_5_bits_replaceData              (dir_msInfo_5_bits_replaceData),
    .dir_msInfo_5_bits_releaseToClean           (dir_msInfo_5_bits_releaseToClean),
    .dir_msInfo_6_valid                         (dir_msInfo_6_valid),
    .dir_msInfo_6_bits_channel                  (dir_msInfo_6_bits_channel),
    .dir_msInfo_6_bits_set                      (dir_msInfo_6_bits_set),
    .dir_msInfo_6_bits_way                      (dir_msInfo_6_bits_way),
    .dir_msInfo_6_bits_reqTag                   (dir_msInfo_6_bits_reqTag),
    .dir_msInfo_6_bits_willFree                 (dir_msInfo_6_bits_willFree),
    .dir_msInfo_6_bits_aliasTask                (dir_msInfo_6_bits_aliasTask),
    .dir_msInfo_6_bits_needRelease              (dir_msInfo_6_bits_needRelease),
    .dir_msInfo_6_bits_blockRefill              (dir_msInfo_6_bits_blockRefill),
    .dir_msInfo_6_bits_meta_dirty               (dir_msInfo_6_bits_meta_dirty),
    .dir_msInfo_6_bits_meta_state               (dir_msInfo_6_bits_meta_state),
    .dir_msInfo_6_bits_meta_clients             (dir_msInfo_6_bits_meta_clients),
    .dir_msInfo_6_bits_meta_alias               (dir_msInfo_6_bits_meta_alias),
    .dir_msInfo_6_bits_meta_prefetch            (dir_msInfo_6_bits_meta_prefetch),
    .dir_msInfo_6_bits_meta_prefetchSrc         (dir_msInfo_6_bits_meta_prefetchSrc),
    .dir_msInfo_6_bits_meta_accessed            (dir_msInfo_6_bits_meta_accessed),
    .dir_msInfo_6_bits_meta_tagErr              (dir_msInfo_6_bits_meta_tagErr),
    .dir_msInfo_6_bits_meta_dataErr             (dir_msInfo_6_bits_meta_dataErr),
    .dir_msInfo_6_bits_metaTag                  (dir_msInfo_6_bits_metaTag),
    .dir_msInfo_6_bits_dirHit                   (dir_msInfo_6_bits_dirHit),
    .dir_msInfo_6_bits_isAcqOrPrefetch          (dir_msInfo_6_bits_isAcqOrPrefetch),
    .dir_msInfo_6_bits_isPrefetch               (dir_msInfo_6_bits_isPrefetch),
    .dir_msInfo_6_bits_param                    (dir_msInfo_6_bits_param),
    .dir_msInfo_6_bits_mergeA                   (dir_msInfo_6_bits_mergeA),
    .dir_msInfo_6_bits_w_grantfirst             (dir_msInfo_6_bits_w_grantfirst),
    .dir_msInfo_6_bits_s_release                (dir_msInfo_6_bits_s_release),
    .dir_msInfo_6_bits_s_refill                 (dir_msInfo_6_bits_s_refill),
    .dir_msInfo_6_bits_s_cmoresp                (dir_msInfo_6_bits_s_cmoresp),
    .dir_msInfo_6_bits_s_cmometaw               (dir_msInfo_6_bits_s_cmometaw),
    .dir_msInfo_6_bits_w_releaseack             (dir_msInfo_6_bits_w_releaseack),
    .dir_msInfo_6_bits_w_replResp               (dir_msInfo_6_bits_w_replResp),
    .dir_msInfo_6_bits_w_rprobeacklast          (dir_msInfo_6_bits_w_rprobeacklast),
    .dir_msInfo_6_bits_replaceData              (dir_msInfo_6_bits_replaceData),
    .dir_msInfo_6_bits_releaseToClean           (dir_msInfo_6_bits_releaseToClean),
    .dir_msInfo_7_valid                         (dir_msInfo_7_valid),
    .dir_msInfo_7_bits_channel                  (dir_msInfo_7_bits_channel),
    .dir_msInfo_7_bits_set                      (dir_msInfo_7_bits_set),
    .dir_msInfo_7_bits_way                      (dir_msInfo_7_bits_way),
    .dir_msInfo_7_bits_reqTag                   (dir_msInfo_7_bits_reqTag),
    .dir_msInfo_7_bits_willFree                 (dir_msInfo_7_bits_willFree),
    .dir_msInfo_7_bits_aliasTask                (dir_msInfo_7_bits_aliasTask),
    .dir_msInfo_7_bits_needRelease              (dir_msInfo_7_bits_needRelease),
    .dir_msInfo_7_bits_blockRefill              (dir_msInfo_7_bits_blockRefill),
    .dir_msInfo_7_bits_meta_dirty               (dir_msInfo_7_bits_meta_dirty),
    .dir_msInfo_7_bits_meta_state               (dir_msInfo_7_bits_meta_state),
    .dir_msInfo_7_bits_meta_clients             (dir_msInfo_7_bits_meta_clients),
    .dir_msInfo_7_bits_meta_alias               (dir_msInfo_7_bits_meta_alias),
    .dir_msInfo_7_bits_meta_prefetch            (dir_msInfo_7_bits_meta_prefetch),
    .dir_msInfo_7_bits_meta_prefetchSrc         (dir_msInfo_7_bits_meta_prefetchSrc),
    .dir_msInfo_7_bits_meta_accessed            (dir_msInfo_7_bits_meta_accessed),
    .dir_msInfo_7_bits_meta_tagErr              (dir_msInfo_7_bits_meta_tagErr),
    .dir_msInfo_7_bits_meta_dataErr             (dir_msInfo_7_bits_meta_dataErr),
    .dir_msInfo_7_bits_metaTag                  (dir_msInfo_7_bits_metaTag),
    .dir_msInfo_7_bits_dirHit                   (dir_msInfo_7_bits_dirHit),
    .dir_msInfo_7_bits_isAcqOrPrefetch          (dir_msInfo_7_bits_isAcqOrPrefetch),
    .dir_msInfo_7_bits_isPrefetch               (dir_msInfo_7_bits_isPrefetch),
    .dir_msInfo_7_bits_param                    (dir_msInfo_7_bits_param),
    .dir_msInfo_7_bits_mergeA                   (dir_msInfo_7_bits_mergeA),
    .dir_msInfo_7_bits_w_grantfirst             (dir_msInfo_7_bits_w_grantfirst),
    .dir_msInfo_7_bits_s_release                (dir_msInfo_7_bits_s_release),
    .dir_msInfo_7_bits_s_refill                 (dir_msInfo_7_bits_s_refill),
    .dir_msInfo_7_bits_s_cmoresp                (dir_msInfo_7_bits_s_cmoresp),
    .dir_msInfo_7_bits_s_cmometaw               (dir_msInfo_7_bits_s_cmometaw),
    .dir_msInfo_7_bits_w_releaseack             (dir_msInfo_7_bits_w_releaseack),
    .dir_msInfo_7_bits_w_replResp               (dir_msInfo_7_bits_w_replResp),
    .dir_msInfo_7_bits_w_rprobeacklast          (dir_msInfo_7_bits_w_rprobeacklast),
    .dir_msInfo_7_bits_replaceData              (dir_msInfo_7_bits_replaceData),
    .dir_msInfo_7_bits_releaseToClean           (dir_msInfo_7_bits_releaseToClean),
    .dir_msInfo_8_valid                         (dir_msInfo_8_valid),
    .dir_msInfo_8_bits_channel                  (dir_msInfo_8_bits_channel),
    .dir_msInfo_8_bits_set                      (dir_msInfo_8_bits_set),
    .dir_msInfo_8_bits_way                      (dir_msInfo_8_bits_way),
    .dir_msInfo_8_bits_reqTag                   (dir_msInfo_8_bits_reqTag),
    .dir_msInfo_8_bits_willFree                 (dir_msInfo_8_bits_willFree),
    .dir_msInfo_8_bits_aliasTask                (dir_msInfo_8_bits_aliasTask),
    .dir_msInfo_8_bits_needRelease              (dir_msInfo_8_bits_needRelease),
    .dir_msInfo_8_bits_blockRefill              (dir_msInfo_8_bits_blockRefill),
    .dir_msInfo_8_bits_meta_dirty               (dir_msInfo_8_bits_meta_dirty),
    .dir_msInfo_8_bits_meta_state               (dir_msInfo_8_bits_meta_state),
    .dir_msInfo_8_bits_meta_clients             (dir_msInfo_8_bits_meta_clients),
    .dir_msInfo_8_bits_meta_alias               (dir_msInfo_8_bits_meta_alias),
    .dir_msInfo_8_bits_meta_prefetch            (dir_msInfo_8_bits_meta_prefetch),
    .dir_msInfo_8_bits_meta_prefetchSrc         (dir_msInfo_8_bits_meta_prefetchSrc),
    .dir_msInfo_8_bits_meta_accessed            (dir_msInfo_8_bits_meta_accessed),
    .dir_msInfo_8_bits_meta_tagErr              (dir_msInfo_8_bits_meta_tagErr),
    .dir_msInfo_8_bits_meta_dataErr             (dir_msInfo_8_bits_meta_dataErr),
    .dir_msInfo_8_bits_metaTag                  (dir_msInfo_8_bits_metaTag),
    .dir_msInfo_8_bits_dirHit                   (dir_msInfo_8_bits_dirHit),
    .dir_msInfo_8_bits_isAcqOrPrefetch          (dir_msInfo_8_bits_isAcqOrPrefetch),
    .dir_msInfo_8_bits_isPrefetch               (dir_msInfo_8_bits_isPrefetch),
    .dir_msInfo_8_bits_param                    (dir_msInfo_8_bits_param),
    .dir_msInfo_8_bits_mergeA                   (dir_msInfo_8_bits_mergeA),
    .dir_msInfo_8_bits_w_grantfirst             (dir_msInfo_8_bits_w_grantfirst),
    .dir_msInfo_8_bits_s_release                (dir_msInfo_8_bits_s_release),
    .dir_msInfo_8_bits_s_refill                 (dir_msInfo_8_bits_s_refill),
    .dir_msInfo_8_bits_s_cmoresp                (dir_msInfo_8_bits_s_cmoresp),
    .dir_msInfo_8_bits_s_cmometaw               (dir_msInfo_8_bits_s_cmometaw),
    .dir_msInfo_8_bits_w_releaseack             (dir_msInfo_8_bits_w_releaseack),
    .dir_msInfo_8_bits_w_replResp               (dir_msInfo_8_bits_w_replResp),
    .dir_msInfo_8_bits_w_rprobeacklast          (dir_msInfo_8_bits_w_rprobeacklast),
    .dir_msInfo_8_bits_replaceData              (dir_msInfo_8_bits_replaceData),
    .dir_msInfo_8_bits_releaseToClean           (dir_msInfo_8_bits_releaseToClean),
    .dir_msInfo_9_valid                         (dir_msInfo_9_valid),
    .dir_msInfo_9_bits_channel                  (dir_msInfo_9_bits_channel),
    .dir_msInfo_9_bits_set                      (dir_msInfo_9_bits_set),
    .dir_msInfo_9_bits_way                      (dir_msInfo_9_bits_way),
    .dir_msInfo_9_bits_reqTag                   (dir_msInfo_9_bits_reqTag),
    .dir_msInfo_9_bits_willFree                 (dir_msInfo_9_bits_willFree),
    .dir_msInfo_9_bits_aliasTask                (dir_msInfo_9_bits_aliasTask),
    .dir_msInfo_9_bits_needRelease              (dir_msInfo_9_bits_needRelease),
    .dir_msInfo_9_bits_blockRefill              (dir_msInfo_9_bits_blockRefill),
    .dir_msInfo_9_bits_meta_dirty               (dir_msInfo_9_bits_meta_dirty),
    .dir_msInfo_9_bits_meta_state               (dir_msInfo_9_bits_meta_state),
    .dir_msInfo_9_bits_meta_clients             (dir_msInfo_9_bits_meta_clients),
    .dir_msInfo_9_bits_meta_alias               (dir_msInfo_9_bits_meta_alias),
    .dir_msInfo_9_bits_meta_prefetch            (dir_msInfo_9_bits_meta_prefetch),
    .dir_msInfo_9_bits_meta_prefetchSrc         (dir_msInfo_9_bits_meta_prefetchSrc),
    .dir_msInfo_9_bits_meta_accessed            (dir_msInfo_9_bits_meta_accessed),
    .dir_msInfo_9_bits_meta_tagErr              (dir_msInfo_9_bits_meta_tagErr),
    .dir_msInfo_9_bits_meta_dataErr             (dir_msInfo_9_bits_meta_dataErr),
    .dir_msInfo_9_bits_metaTag                  (dir_msInfo_9_bits_metaTag),
    .dir_msInfo_9_bits_dirHit                   (dir_msInfo_9_bits_dirHit),
    .dir_msInfo_9_bits_isAcqOrPrefetch          (dir_msInfo_9_bits_isAcqOrPrefetch),
    .dir_msInfo_9_bits_isPrefetch               (dir_msInfo_9_bits_isPrefetch),
    .dir_msInfo_9_bits_param                    (dir_msInfo_9_bits_param),
    .dir_msInfo_9_bits_mergeA                   (dir_msInfo_9_bits_mergeA),
    .dir_msInfo_9_bits_w_grantfirst             (dir_msInfo_9_bits_w_grantfirst),
    .dir_msInfo_9_bits_s_release                (dir_msInfo_9_bits_s_release),
    .dir_msInfo_9_bits_s_refill                 (dir_msInfo_9_bits_s_refill),
    .dir_msInfo_9_bits_s_cmoresp                (dir_msInfo_9_bits_s_cmoresp),
    .dir_msInfo_9_bits_s_cmometaw               (dir_msInfo_9_bits_s_cmometaw),
    .dir_msInfo_9_bits_w_releaseack             (dir_msInfo_9_bits_w_releaseack),
    .dir_msInfo_9_bits_w_replResp               (dir_msInfo_9_bits_w_replResp),
    .dir_msInfo_9_bits_w_rprobeacklast          (dir_msInfo_9_bits_w_rprobeacklast),
    .dir_msInfo_9_bits_replaceData              (dir_msInfo_9_bits_replaceData),
    .dir_msInfo_9_bits_releaseToClean           (dir_msInfo_9_bits_releaseToClean),
    .dir_msInfo_10_valid                        (dir_msInfo_10_valid),
    .dir_msInfo_10_bits_channel                 (dir_msInfo_10_bits_channel),
    .dir_msInfo_10_bits_set                     (dir_msInfo_10_bits_set),
    .dir_msInfo_10_bits_way                     (dir_msInfo_10_bits_way),
    .dir_msInfo_10_bits_reqTag                  (dir_msInfo_10_bits_reqTag),
    .dir_msInfo_10_bits_willFree                (dir_msInfo_10_bits_willFree),
    .dir_msInfo_10_bits_aliasTask               (dir_msInfo_10_bits_aliasTask),
    .dir_msInfo_10_bits_needRelease             (dir_msInfo_10_bits_needRelease),
    .dir_msInfo_10_bits_blockRefill             (dir_msInfo_10_bits_blockRefill),
    .dir_msInfo_10_bits_meta_dirty              (dir_msInfo_10_bits_meta_dirty),
    .dir_msInfo_10_bits_meta_state              (dir_msInfo_10_bits_meta_state),
    .dir_msInfo_10_bits_meta_clients            (dir_msInfo_10_bits_meta_clients),
    .dir_msInfo_10_bits_meta_alias              (dir_msInfo_10_bits_meta_alias),
    .dir_msInfo_10_bits_meta_prefetch           (dir_msInfo_10_bits_meta_prefetch),
    .dir_msInfo_10_bits_meta_prefetchSrc        (dir_msInfo_10_bits_meta_prefetchSrc),
    .dir_msInfo_10_bits_meta_accessed           (dir_msInfo_10_bits_meta_accessed),
    .dir_msInfo_10_bits_meta_tagErr             (dir_msInfo_10_bits_meta_tagErr),
    .dir_msInfo_10_bits_meta_dataErr            (dir_msInfo_10_bits_meta_dataErr),
    .dir_msInfo_10_bits_metaTag                 (dir_msInfo_10_bits_metaTag),
    .dir_msInfo_10_bits_dirHit                  (dir_msInfo_10_bits_dirHit),
    .dir_msInfo_10_bits_isAcqOrPrefetch         (dir_msInfo_10_bits_isAcqOrPrefetch),
    .dir_msInfo_10_bits_isPrefetch              (dir_msInfo_10_bits_isPrefetch),
    .dir_msInfo_10_bits_param                   (dir_msInfo_10_bits_param),
    .dir_msInfo_10_bits_mergeA                  (dir_msInfo_10_bits_mergeA),
    .dir_msInfo_10_bits_w_grantfirst            (dir_msInfo_10_bits_w_grantfirst),
    .dir_msInfo_10_bits_s_release               (dir_msInfo_10_bits_s_release),
    .dir_msInfo_10_bits_s_refill                (dir_msInfo_10_bits_s_refill),
    .dir_msInfo_10_bits_s_cmoresp               (dir_msInfo_10_bits_s_cmoresp),
    .dir_msInfo_10_bits_s_cmometaw              (dir_msInfo_10_bits_s_cmometaw),
    .dir_msInfo_10_bits_w_releaseack            (dir_msInfo_10_bits_w_releaseack),
    .dir_msInfo_10_bits_w_replResp              (dir_msInfo_10_bits_w_replResp),
    .dir_msInfo_10_bits_w_rprobeacklast         (dir_msInfo_10_bits_w_rprobeacklast),
    .dir_msInfo_10_bits_replaceData             (dir_msInfo_10_bits_replaceData),
    .dir_msInfo_10_bits_releaseToClean          (dir_msInfo_10_bits_releaseToClean),
    .dir_msInfo_11_valid                        (dir_msInfo_11_valid),
    .dir_msInfo_11_bits_channel                 (dir_msInfo_11_bits_channel),
    .dir_msInfo_11_bits_set                     (dir_msInfo_11_bits_set),
    .dir_msInfo_11_bits_way                     (dir_msInfo_11_bits_way),
    .dir_msInfo_11_bits_reqTag                  (dir_msInfo_11_bits_reqTag),
    .dir_msInfo_11_bits_willFree                (dir_msInfo_11_bits_willFree),
    .dir_msInfo_11_bits_aliasTask               (dir_msInfo_11_bits_aliasTask),
    .dir_msInfo_11_bits_needRelease             (dir_msInfo_11_bits_needRelease),
    .dir_msInfo_11_bits_blockRefill             (dir_msInfo_11_bits_blockRefill),
    .dir_msInfo_11_bits_meta_dirty              (dir_msInfo_11_bits_meta_dirty),
    .dir_msInfo_11_bits_meta_state              (dir_msInfo_11_bits_meta_state),
    .dir_msInfo_11_bits_meta_clients            (dir_msInfo_11_bits_meta_clients),
    .dir_msInfo_11_bits_meta_alias              (dir_msInfo_11_bits_meta_alias),
    .dir_msInfo_11_bits_meta_prefetch           (dir_msInfo_11_bits_meta_prefetch),
    .dir_msInfo_11_bits_meta_prefetchSrc        (dir_msInfo_11_bits_meta_prefetchSrc),
    .dir_msInfo_11_bits_meta_accessed           (dir_msInfo_11_bits_meta_accessed),
    .dir_msInfo_11_bits_meta_tagErr             (dir_msInfo_11_bits_meta_tagErr),
    .dir_msInfo_11_bits_meta_dataErr            (dir_msInfo_11_bits_meta_dataErr),
    .dir_msInfo_11_bits_metaTag                 (dir_msInfo_11_bits_metaTag),
    .dir_msInfo_11_bits_dirHit                  (dir_msInfo_11_bits_dirHit),
    .dir_msInfo_11_bits_isAcqOrPrefetch         (dir_msInfo_11_bits_isAcqOrPrefetch),
    .dir_msInfo_11_bits_isPrefetch              (dir_msInfo_11_bits_isPrefetch),
    .dir_msInfo_11_bits_param                   (dir_msInfo_11_bits_param),
    .dir_msInfo_11_bits_mergeA                  (dir_msInfo_11_bits_mergeA),
    .dir_msInfo_11_bits_w_grantfirst            (dir_msInfo_11_bits_w_grantfirst),
    .dir_msInfo_11_bits_s_release               (dir_msInfo_11_bits_s_release),
    .dir_msInfo_11_bits_s_refill                (dir_msInfo_11_bits_s_refill),
    .dir_msInfo_11_bits_s_cmoresp               (dir_msInfo_11_bits_s_cmoresp),
    .dir_msInfo_11_bits_s_cmometaw              (dir_msInfo_11_bits_s_cmometaw),
    .dir_msInfo_11_bits_w_releaseack            (dir_msInfo_11_bits_w_releaseack),
    .dir_msInfo_11_bits_w_replResp              (dir_msInfo_11_bits_w_replResp),
    .dir_msInfo_11_bits_w_rprobeacklast         (dir_msInfo_11_bits_w_rprobeacklast),
    .dir_msInfo_11_bits_replaceData             (dir_msInfo_11_bits_replaceData),
    .dir_msInfo_11_bits_releaseToClean          (dir_msInfo_11_bits_releaseToClean),
    .dir_msInfo_12_valid                        (dir_msInfo_12_valid),
    .dir_msInfo_12_bits_channel                 (dir_msInfo_12_bits_channel),
    .dir_msInfo_12_bits_set                     (dir_msInfo_12_bits_set),
    .dir_msInfo_12_bits_way                     (dir_msInfo_12_bits_way),
    .dir_msInfo_12_bits_reqTag                  (dir_msInfo_12_bits_reqTag),
    .dir_msInfo_12_bits_willFree                (dir_msInfo_12_bits_willFree),
    .dir_msInfo_12_bits_aliasTask               (dir_msInfo_12_bits_aliasTask),
    .dir_msInfo_12_bits_needRelease             (dir_msInfo_12_bits_needRelease),
    .dir_msInfo_12_bits_blockRefill             (dir_msInfo_12_bits_blockRefill),
    .dir_msInfo_12_bits_meta_dirty              (dir_msInfo_12_bits_meta_dirty),
    .dir_msInfo_12_bits_meta_state              (dir_msInfo_12_bits_meta_state),
    .dir_msInfo_12_bits_meta_clients            (dir_msInfo_12_bits_meta_clients),
    .dir_msInfo_12_bits_meta_alias              (dir_msInfo_12_bits_meta_alias),
    .dir_msInfo_12_bits_meta_prefetch           (dir_msInfo_12_bits_meta_prefetch),
    .dir_msInfo_12_bits_meta_prefetchSrc        (dir_msInfo_12_bits_meta_prefetchSrc),
    .dir_msInfo_12_bits_meta_accessed           (dir_msInfo_12_bits_meta_accessed),
    .dir_msInfo_12_bits_meta_tagErr             (dir_msInfo_12_bits_meta_tagErr),
    .dir_msInfo_12_bits_meta_dataErr            (dir_msInfo_12_bits_meta_dataErr),
    .dir_msInfo_12_bits_metaTag                 (dir_msInfo_12_bits_metaTag),
    .dir_msInfo_12_bits_dirHit                  (dir_msInfo_12_bits_dirHit),
    .dir_msInfo_12_bits_isAcqOrPrefetch         (dir_msInfo_12_bits_isAcqOrPrefetch),
    .dir_msInfo_12_bits_isPrefetch              (dir_msInfo_12_bits_isPrefetch),
    .dir_msInfo_12_bits_param                   (dir_msInfo_12_bits_param),
    .dir_msInfo_12_bits_mergeA                  (dir_msInfo_12_bits_mergeA),
    .dir_msInfo_12_bits_w_grantfirst            (dir_msInfo_12_bits_w_grantfirst),
    .dir_msInfo_12_bits_s_release               (dir_msInfo_12_bits_s_release),
    .dir_msInfo_12_bits_s_refill                (dir_msInfo_12_bits_s_refill),
    .dir_msInfo_12_bits_s_cmoresp               (dir_msInfo_12_bits_s_cmoresp),
    .dir_msInfo_12_bits_s_cmometaw              (dir_msInfo_12_bits_s_cmometaw),
    .dir_msInfo_12_bits_w_releaseack            (dir_msInfo_12_bits_w_releaseack),
    .dir_msInfo_12_bits_w_replResp              (dir_msInfo_12_bits_w_replResp),
    .dir_msInfo_12_bits_w_rprobeacklast         (dir_msInfo_12_bits_w_rprobeacklast),
    .dir_msInfo_12_bits_replaceData             (dir_msInfo_12_bits_replaceData),
    .dir_msInfo_12_bits_releaseToClean          (dir_msInfo_12_bits_releaseToClean),
    .dir_msInfo_13_valid                        (dir_msInfo_13_valid),
    .dir_msInfo_13_bits_channel                 (dir_msInfo_13_bits_channel),
    .dir_msInfo_13_bits_set                     (dir_msInfo_13_bits_set),
    .dir_msInfo_13_bits_way                     (dir_msInfo_13_bits_way),
    .dir_msInfo_13_bits_reqTag                  (dir_msInfo_13_bits_reqTag),
    .dir_msInfo_13_bits_willFree                (dir_msInfo_13_bits_willFree),
    .dir_msInfo_13_bits_aliasTask               (dir_msInfo_13_bits_aliasTask),
    .dir_msInfo_13_bits_needRelease             (dir_msInfo_13_bits_needRelease),
    .dir_msInfo_13_bits_blockRefill             (dir_msInfo_13_bits_blockRefill),
    .dir_msInfo_13_bits_meta_dirty              (dir_msInfo_13_bits_meta_dirty),
    .dir_msInfo_13_bits_meta_state              (dir_msInfo_13_bits_meta_state),
    .dir_msInfo_13_bits_meta_clients            (dir_msInfo_13_bits_meta_clients),
    .dir_msInfo_13_bits_meta_alias              (dir_msInfo_13_bits_meta_alias),
    .dir_msInfo_13_bits_meta_prefetch           (dir_msInfo_13_bits_meta_prefetch),
    .dir_msInfo_13_bits_meta_prefetchSrc        (dir_msInfo_13_bits_meta_prefetchSrc),
    .dir_msInfo_13_bits_meta_accessed           (dir_msInfo_13_bits_meta_accessed),
    .dir_msInfo_13_bits_meta_tagErr             (dir_msInfo_13_bits_meta_tagErr),
    .dir_msInfo_13_bits_meta_dataErr            (dir_msInfo_13_bits_meta_dataErr),
    .dir_msInfo_13_bits_metaTag                 (dir_msInfo_13_bits_metaTag),
    .dir_msInfo_13_bits_dirHit                  (dir_msInfo_13_bits_dirHit),
    .dir_msInfo_13_bits_isAcqOrPrefetch         (dir_msInfo_13_bits_isAcqOrPrefetch),
    .dir_msInfo_13_bits_isPrefetch              (dir_msInfo_13_bits_isPrefetch),
    .dir_msInfo_13_bits_param                   (dir_msInfo_13_bits_param),
    .dir_msInfo_13_bits_mergeA                  (dir_msInfo_13_bits_mergeA),
    .dir_msInfo_13_bits_w_grantfirst            (dir_msInfo_13_bits_w_grantfirst),
    .dir_msInfo_13_bits_s_release               (dir_msInfo_13_bits_s_release),
    .dir_msInfo_13_bits_s_refill                (dir_msInfo_13_bits_s_refill),
    .dir_msInfo_13_bits_s_cmoresp               (dir_msInfo_13_bits_s_cmoresp),
    .dir_msInfo_13_bits_s_cmometaw              (dir_msInfo_13_bits_s_cmometaw),
    .dir_msInfo_13_bits_w_releaseack            (dir_msInfo_13_bits_w_releaseack),
    .dir_msInfo_13_bits_w_replResp              (dir_msInfo_13_bits_w_replResp),
    .dir_msInfo_13_bits_w_rprobeacklast         (dir_msInfo_13_bits_w_rprobeacklast),
    .dir_msInfo_13_bits_replaceData             (dir_msInfo_13_bits_replaceData),
    .dir_msInfo_13_bits_releaseToClean          (dir_msInfo_13_bits_releaseToClean),
    .dir_msInfo_14_valid                        (dir_msInfo_14_valid),
    .dir_msInfo_14_bits_channel                 (dir_msInfo_14_bits_channel),
    .dir_msInfo_14_bits_set                     (dir_msInfo_14_bits_set),
    .dir_msInfo_14_bits_way                     (dir_msInfo_14_bits_way),
    .dir_msInfo_14_bits_reqTag                  (dir_msInfo_14_bits_reqTag),
    .dir_msInfo_14_bits_willFree                (dir_msInfo_14_bits_willFree),
    .dir_msInfo_14_bits_aliasTask               (dir_msInfo_14_bits_aliasTask),
    .dir_msInfo_14_bits_needRelease             (dir_msInfo_14_bits_needRelease),
    .dir_msInfo_14_bits_blockRefill             (dir_msInfo_14_bits_blockRefill),
    .dir_msInfo_14_bits_meta_dirty              (dir_msInfo_14_bits_meta_dirty),
    .dir_msInfo_14_bits_meta_state              (dir_msInfo_14_bits_meta_state),
    .dir_msInfo_14_bits_meta_clients            (dir_msInfo_14_bits_meta_clients),
    .dir_msInfo_14_bits_meta_alias              (dir_msInfo_14_bits_meta_alias),
    .dir_msInfo_14_bits_meta_prefetch           (dir_msInfo_14_bits_meta_prefetch),
    .dir_msInfo_14_bits_meta_prefetchSrc        (dir_msInfo_14_bits_meta_prefetchSrc),
    .dir_msInfo_14_bits_meta_accessed           (dir_msInfo_14_bits_meta_accessed),
    .dir_msInfo_14_bits_meta_tagErr             (dir_msInfo_14_bits_meta_tagErr),
    .dir_msInfo_14_bits_meta_dataErr            (dir_msInfo_14_bits_meta_dataErr),
    .dir_msInfo_14_bits_metaTag                 (dir_msInfo_14_bits_metaTag),
    .dir_msInfo_14_bits_dirHit                  (dir_msInfo_14_bits_dirHit),
    .dir_msInfo_14_bits_isAcqOrPrefetch         (dir_msInfo_14_bits_isAcqOrPrefetch),
    .dir_msInfo_14_bits_isPrefetch              (dir_msInfo_14_bits_isPrefetch),
    .dir_msInfo_14_bits_param                   (dir_msInfo_14_bits_param),
    .dir_msInfo_14_bits_mergeA                  (dir_msInfo_14_bits_mergeA),
    .dir_msInfo_14_bits_w_grantfirst            (dir_msInfo_14_bits_w_grantfirst),
    .dir_msInfo_14_bits_s_release               (dir_msInfo_14_bits_s_release),
    .dir_msInfo_14_bits_s_refill                (dir_msInfo_14_bits_s_refill),
    .dir_msInfo_14_bits_s_cmoresp               (dir_msInfo_14_bits_s_cmoresp),
    .dir_msInfo_14_bits_s_cmometaw              (dir_msInfo_14_bits_s_cmometaw),
    .dir_msInfo_14_bits_w_releaseack            (dir_msInfo_14_bits_w_releaseack),
    .dir_msInfo_14_bits_w_replResp              (dir_msInfo_14_bits_w_replResp),
    .dir_msInfo_14_bits_w_rprobeacklast         (dir_msInfo_14_bits_w_rprobeacklast),
    .dir_msInfo_14_bits_replaceData             (dir_msInfo_14_bits_replaceData),
    .dir_msInfo_14_bits_releaseToClean          (dir_msInfo_14_bits_releaseToClean),
    .dir_msInfo_15_valid                        (dir_msInfo_15_valid),
    .dir_msInfo_15_bits_channel                 (dir_msInfo_15_bits_channel),
    .dir_msInfo_15_bits_set                     (dir_msInfo_15_bits_set),
    .dir_msInfo_15_bits_way                     (dir_msInfo_15_bits_way),
    .dir_msInfo_15_bits_reqTag                  (dir_msInfo_15_bits_reqTag),
    .dir_msInfo_15_bits_willFree                (dir_msInfo_15_bits_willFree),
    .dir_msInfo_15_bits_aliasTask               (dir_msInfo_15_bits_aliasTask),
    .dir_msInfo_15_bits_needRelease             (dir_msInfo_15_bits_needRelease),
    .dir_msInfo_15_bits_blockRefill             (dir_msInfo_15_bits_blockRefill),
    .dir_msInfo_15_bits_meta_dirty              (dir_msInfo_15_bits_meta_dirty),
    .dir_msInfo_15_bits_meta_state              (dir_msInfo_15_bits_meta_state),
    .dir_msInfo_15_bits_meta_clients            (dir_msInfo_15_bits_meta_clients),
    .dir_msInfo_15_bits_meta_alias              (dir_msInfo_15_bits_meta_alias),
    .dir_msInfo_15_bits_meta_prefetch           (dir_msInfo_15_bits_meta_prefetch),
    .dir_msInfo_15_bits_meta_prefetchSrc        (dir_msInfo_15_bits_meta_prefetchSrc),
    .dir_msInfo_15_bits_meta_accessed           (dir_msInfo_15_bits_meta_accessed),
    .dir_msInfo_15_bits_meta_tagErr             (dir_msInfo_15_bits_meta_tagErr),
    .dir_msInfo_15_bits_meta_dataErr            (dir_msInfo_15_bits_meta_dataErr),
    .dir_msInfo_15_bits_metaTag                 (dir_msInfo_15_bits_metaTag),
    .dir_msInfo_15_bits_dirHit                  (dir_msInfo_15_bits_dirHit),
    .dir_msInfo_15_bits_isAcqOrPrefetch         (dir_msInfo_15_bits_isAcqOrPrefetch),
    .dir_msInfo_15_bits_isPrefetch              (dir_msInfo_15_bits_isPrefetch),
    .dir_msInfo_15_bits_param                   (dir_msInfo_15_bits_param),
    .dir_msInfo_15_bits_mergeA                  (dir_msInfo_15_bits_mergeA),
    .dir_msInfo_15_bits_w_grantfirst            (dir_msInfo_15_bits_w_grantfirst),
    .dir_msInfo_15_bits_s_release               (dir_msInfo_15_bits_s_release),
    .dir_msInfo_15_bits_s_refill                (dir_msInfo_15_bits_s_refill),
    .dir_msInfo_15_bits_s_cmoresp               (dir_msInfo_15_bits_s_cmoresp),
    .dir_msInfo_15_bits_s_cmometaw              (dir_msInfo_15_bits_s_cmometaw),
    .dir_msInfo_15_bits_w_releaseack            (dir_msInfo_15_bits_w_releaseack),
    .dir_msInfo_15_bits_w_replResp              (dir_msInfo_15_bits_w_replResp),
    .dir_msInfo_15_bits_w_rprobeacklast         (dir_msInfo_15_bits_w_rprobeacklast),
    .dir_msInfo_15_bits_replaceData             (dir_msInfo_15_bits_replaceData),
    .dir_msInfo_15_bits_releaseToClean          (dir_msInfo_15_bits_releaseToClean),
    .ds_en                                      (ds_en),
    .ds_error                                   (ds_error),
    .ds_req_valid                               (ds_req_valid),
    .ds_req_bits_way                            (ds_req_bits_way),
    .ds_req_bits_set                            (ds_req_bits_set),
    .ds_req_bits_wen                            (ds_req_bits_wen),
    .ds_rdata_data                              (ds_rdata_data),
    .ds_wdata_data                              (ds_wdata_data)
  );

  // §W4 目录（tag / meta / 替换状态），本变体 = Directory_2
  Directory_2 directory (
    .clock                                     (clock),
    .reset                                     (reset),
    .io_read_ready                             (dir_read_ready),
    .io_read_valid                             (dir_read_valid),
    .io_read_bits_tag                          (dir_read_bits_tag),
    .io_read_bits_set                          (dir_read_bits_set),
    .io_read_bits_wayMask                      (dir_read_bits_wayMask),
    .io_read_bits_replacerInfo_channel         (dir_read_bits_replacerInfo_channel),
    .io_read_bits_replacerInfo_opcode          (dir_read_bits_replacerInfo_opcode),
    .io_read_bits_replacerInfo_reqSource       (dir_read_bits_replacerInfo_reqSource),
    .io_read_bits_replacerInfo_refill_prefetch (dir_read_bits_replacerInfo_refill_prefetch),
    .io_read_bits_refill                       (dir_read_bits_refill),
    .io_read_bits_mshrId                       (dir_read_bits_mshrId),
    .io_read_bits_cmoAll                       (dir_read_bits_cmoAll),
    .io_read_bits_cmoWay                       (dir_read_bits_cmoWay),
    .io_resp_valid                             (dir_resp_valid),
    .io_resp_bits_hit                          (dir_resp_bits_hit),
    .io_resp_bits_tag                          (dir_resp_bits_tag),
    .io_resp_bits_set                          (dir_resp_bits_set),
    .io_resp_bits_way                          (dir_resp_bits_way),
    .io_resp_bits_meta_dirty                   (dir_resp_bits_meta_dirty),
    .io_resp_bits_meta_state                   (dir_resp_bits_meta_state),
    .io_resp_bits_meta_clients                 (dir_resp_bits_meta_clients),
    .io_resp_bits_meta_alias                   (dir_resp_bits_meta_alias),
    .io_resp_bits_meta_prefetch                (dir_resp_bits_meta_prefetch),
    .io_resp_bits_meta_prefetchSrc             (dir_resp_bits_meta_prefetchSrc),
    .io_resp_bits_meta_accessed                (dir_resp_bits_meta_accessed),
    .io_resp_bits_meta_tagErr                  (dir_resp_bits_meta_tagErr),
    .io_resp_bits_meta_dataErr                 (dir_resp_bits_meta_dataErr),
    .io_resp_bits_error                        (dir_resp_bits_error),
    .io_resp_bits_replacerInfo_channel         (io_dirResult_bits_replacerInfo_channel),
    .io_resp_bits_replacerInfo_opcode          (),
    .io_resp_bits_replacerInfo_reqSource       (io_dirResult_bits_replacerInfo_reqSource),
    .io_resp_bits_replacerInfo_refill_prefetch (),
    .io_metaWReq_valid                         (dir_metaWReq_valid),
    .io_metaWReq_bits_set                      (dir_metaWReq_bits_set),
    .io_metaWReq_bits_wayOH                    (dir_metaWReq_bits_wayOH),
    .io_metaWReq_bits_wmeta_dirty              (dir_metaWReq_bits_wmeta_dirty),
    .io_metaWReq_bits_wmeta_state              (dir_metaWReq_bits_wmeta_state),
    .io_metaWReq_bits_wmeta_clients            (dir_metaWReq_bits_wmeta_clients),
    .io_metaWReq_bits_wmeta_alias              (dir_metaWReq_bits_wmeta_alias),
    .io_metaWReq_bits_wmeta_prefetch           (dir_metaWReq_bits_wmeta_prefetch),
    .io_metaWReq_bits_wmeta_prefetchSrc        (dir_metaWReq_bits_wmeta_prefetchSrc),
    .io_metaWReq_bits_wmeta_accessed           (dir_metaWReq_bits_wmeta_accessed),
    .io_metaWReq_bits_wmeta_tagErr             (dir_metaWReq_bits_wmeta_tagErr),
    .io_metaWReq_bits_wmeta_dataErr            (dir_metaWReq_bits_wmeta_dataErr),
    .io_tagWReq_valid                          (dir_tagWReq_valid),
    .io_tagWReq_bits_set                       (dir_tagWReq_bits_set),
    .io_tagWReq_bits_way                       (dir_tagWReq_bits_way),
    .io_tagWReq_bits_wtag                      (dir_tagWReq_bits_wtag),
    .io_replResp_valid                         (dir_replResp_valid),
    .io_replResp_bits_tag                      (dir_replResp_bits_tag),
    .io_replResp_bits_set                      (),
    .io_replResp_bits_way                      (dir_replResp_bits_way),
    .io_replResp_bits_meta_dirty               (dir_replResp_bits_meta_dirty),
    .io_replResp_bits_meta_state               (dir_replResp_bits_meta_state),
    .io_replResp_bits_meta_clients             (dir_replResp_bits_meta_clients),
    .io_replResp_bits_meta_alias               (dir_replResp_bits_meta_alias),
    .io_replResp_bits_meta_prefetch            (dir_replResp_bits_meta_prefetch),
    .io_replResp_bits_meta_prefetchSrc         (dir_replResp_bits_meta_prefetchSrc),
    .io_replResp_bits_meta_accessed            (dir_replResp_bits_meta_accessed),
    .io_replResp_bits_meta_tagErr              (dir_replResp_bits_meta_tagErr),
    .io_replResp_bits_meta_dataErr             (dir_replResp_bits_meta_dataErr),
    .io_replResp_bits_mshrId                   (dir_replResp_bits_mshrId),
    .io_replResp_bits_retry                    (dir_replResp_bits_retry),
    .io_replResp_bits_error                    (dir_replResp_bits_error),
    .io_msInfo_0_valid                         (dir_msInfo_0_valid),
    .io_msInfo_0_bits_channel                  (dir_msInfo_0_bits_channel),
    .io_msInfo_0_bits_set                      (dir_msInfo_0_bits_set),
    .io_msInfo_0_bits_way                      (dir_msInfo_0_bits_way),
    .io_msInfo_0_bits_reqTag                   (dir_msInfo_0_bits_reqTag),
    .io_msInfo_0_bits_willFree                 (dir_msInfo_0_bits_willFree),
    .io_msInfo_0_bits_aliasTask                (dir_msInfo_0_bits_aliasTask),
    .io_msInfo_0_bits_needRelease              (dir_msInfo_0_bits_needRelease),
    .io_msInfo_0_bits_blockRefill              (dir_msInfo_0_bits_blockRefill),
    .io_msInfo_0_bits_meta_dirty               (dir_msInfo_0_bits_meta_dirty),
    .io_msInfo_0_bits_meta_state               (dir_msInfo_0_bits_meta_state),
    .io_msInfo_0_bits_meta_clients             (dir_msInfo_0_bits_meta_clients),
    .io_msInfo_0_bits_meta_alias               (dir_msInfo_0_bits_meta_alias),
    .io_msInfo_0_bits_meta_prefetch            (dir_msInfo_0_bits_meta_prefetch),
    .io_msInfo_0_bits_meta_prefetchSrc         (dir_msInfo_0_bits_meta_prefetchSrc),
    .io_msInfo_0_bits_meta_accessed            (dir_msInfo_0_bits_meta_accessed),
    .io_msInfo_0_bits_meta_tagErr              (dir_msInfo_0_bits_meta_tagErr),
    .io_msInfo_0_bits_meta_dataErr             (dir_msInfo_0_bits_meta_dataErr),
    .io_msInfo_0_bits_metaTag                  (dir_msInfo_0_bits_metaTag),
    .io_msInfo_0_bits_dirHit                   (dir_msInfo_0_bits_dirHit),
    .io_msInfo_0_bits_isAcqOrPrefetch          (dir_msInfo_0_bits_isAcqOrPrefetch),
    .io_msInfo_0_bits_isPrefetch               (dir_msInfo_0_bits_isPrefetch),
    .io_msInfo_0_bits_param                    (dir_msInfo_0_bits_param),
    .io_msInfo_0_bits_mergeA                   (dir_msInfo_0_bits_mergeA),
    .io_msInfo_0_bits_w_grantfirst             (dir_msInfo_0_bits_w_grantfirst),
    .io_msInfo_0_bits_s_release                (dir_msInfo_0_bits_s_release),
    .io_msInfo_0_bits_s_refill                 (dir_msInfo_0_bits_s_refill),
    .io_msInfo_0_bits_s_cmoresp                (dir_msInfo_0_bits_s_cmoresp),
    .io_msInfo_0_bits_s_cmometaw               (dir_msInfo_0_bits_s_cmometaw),
    .io_msInfo_0_bits_w_releaseack             (dir_msInfo_0_bits_w_releaseack),
    .io_msInfo_0_bits_w_replResp               (dir_msInfo_0_bits_w_replResp),
    .io_msInfo_0_bits_w_rprobeacklast          (dir_msInfo_0_bits_w_rprobeacklast),
    .io_msInfo_0_bits_replaceData              (dir_msInfo_0_bits_replaceData),
    .io_msInfo_0_bits_releaseToClean           (dir_msInfo_0_bits_releaseToClean),
    .io_msInfo_1_valid                         (dir_msInfo_1_valid),
    .io_msInfo_1_bits_channel                  (dir_msInfo_1_bits_channel),
    .io_msInfo_1_bits_set                      (dir_msInfo_1_bits_set),
    .io_msInfo_1_bits_way                      (dir_msInfo_1_bits_way),
    .io_msInfo_1_bits_reqTag                   (dir_msInfo_1_bits_reqTag),
    .io_msInfo_1_bits_willFree                 (dir_msInfo_1_bits_willFree),
    .io_msInfo_1_bits_aliasTask                (dir_msInfo_1_bits_aliasTask),
    .io_msInfo_1_bits_needRelease              (dir_msInfo_1_bits_needRelease),
    .io_msInfo_1_bits_blockRefill              (dir_msInfo_1_bits_blockRefill),
    .io_msInfo_1_bits_meta_dirty               (dir_msInfo_1_bits_meta_dirty),
    .io_msInfo_1_bits_meta_state               (dir_msInfo_1_bits_meta_state),
    .io_msInfo_1_bits_meta_clients             (dir_msInfo_1_bits_meta_clients),
    .io_msInfo_1_bits_meta_alias               (dir_msInfo_1_bits_meta_alias),
    .io_msInfo_1_bits_meta_prefetch            (dir_msInfo_1_bits_meta_prefetch),
    .io_msInfo_1_bits_meta_prefetchSrc         (dir_msInfo_1_bits_meta_prefetchSrc),
    .io_msInfo_1_bits_meta_accessed            (dir_msInfo_1_bits_meta_accessed),
    .io_msInfo_1_bits_meta_tagErr              (dir_msInfo_1_bits_meta_tagErr),
    .io_msInfo_1_bits_meta_dataErr             (dir_msInfo_1_bits_meta_dataErr),
    .io_msInfo_1_bits_metaTag                  (dir_msInfo_1_bits_metaTag),
    .io_msInfo_1_bits_dirHit                   (dir_msInfo_1_bits_dirHit),
    .io_msInfo_1_bits_isAcqOrPrefetch          (dir_msInfo_1_bits_isAcqOrPrefetch),
    .io_msInfo_1_bits_isPrefetch               (dir_msInfo_1_bits_isPrefetch),
    .io_msInfo_1_bits_param                    (dir_msInfo_1_bits_param),
    .io_msInfo_1_bits_mergeA                   (dir_msInfo_1_bits_mergeA),
    .io_msInfo_1_bits_w_grantfirst             (dir_msInfo_1_bits_w_grantfirst),
    .io_msInfo_1_bits_s_release                (dir_msInfo_1_bits_s_release),
    .io_msInfo_1_bits_s_refill                 (dir_msInfo_1_bits_s_refill),
    .io_msInfo_1_bits_s_cmoresp                (dir_msInfo_1_bits_s_cmoresp),
    .io_msInfo_1_bits_s_cmometaw               (dir_msInfo_1_bits_s_cmometaw),
    .io_msInfo_1_bits_w_releaseack             (dir_msInfo_1_bits_w_releaseack),
    .io_msInfo_1_bits_w_replResp               (dir_msInfo_1_bits_w_replResp),
    .io_msInfo_1_bits_w_rprobeacklast          (dir_msInfo_1_bits_w_rprobeacklast),
    .io_msInfo_1_bits_replaceData              (dir_msInfo_1_bits_replaceData),
    .io_msInfo_1_bits_releaseToClean           (dir_msInfo_1_bits_releaseToClean),
    .io_msInfo_2_valid                         (dir_msInfo_2_valid),
    .io_msInfo_2_bits_channel                  (dir_msInfo_2_bits_channel),
    .io_msInfo_2_bits_set                      (dir_msInfo_2_bits_set),
    .io_msInfo_2_bits_way                      (dir_msInfo_2_bits_way),
    .io_msInfo_2_bits_reqTag                   (dir_msInfo_2_bits_reqTag),
    .io_msInfo_2_bits_willFree                 (dir_msInfo_2_bits_willFree),
    .io_msInfo_2_bits_aliasTask                (dir_msInfo_2_bits_aliasTask),
    .io_msInfo_2_bits_needRelease              (dir_msInfo_2_bits_needRelease),
    .io_msInfo_2_bits_blockRefill              (dir_msInfo_2_bits_blockRefill),
    .io_msInfo_2_bits_meta_dirty               (dir_msInfo_2_bits_meta_dirty),
    .io_msInfo_2_bits_meta_state               (dir_msInfo_2_bits_meta_state),
    .io_msInfo_2_bits_meta_clients             (dir_msInfo_2_bits_meta_clients),
    .io_msInfo_2_bits_meta_alias               (dir_msInfo_2_bits_meta_alias),
    .io_msInfo_2_bits_meta_prefetch            (dir_msInfo_2_bits_meta_prefetch),
    .io_msInfo_2_bits_meta_prefetchSrc         (dir_msInfo_2_bits_meta_prefetchSrc),
    .io_msInfo_2_bits_meta_accessed            (dir_msInfo_2_bits_meta_accessed),
    .io_msInfo_2_bits_meta_tagErr              (dir_msInfo_2_bits_meta_tagErr),
    .io_msInfo_2_bits_meta_dataErr             (dir_msInfo_2_bits_meta_dataErr),
    .io_msInfo_2_bits_metaTag                  (dir_msInfo_2_bits_metaTag),
    .io_msInfo_2_bits_dirHit                   (dir_msInfo_2_bits_dirHit),
    .io_msInfo_2_bits_isAcqOrPrefetch          (dir_msInfo_2_bits_isAcqOrPrefetch),
    .io_msInfo_2_bits_isPrefetch               (dir_msInfo_2_bits_isPrefetch),
    .io_msInfo_2_bits_param                    (dir_msInfo_2_bits_param),
    .io_msInfo_2_bits_mergeA                   (dir_msInfo_2_bits_mergeA),
    .io_msInfo_2_bits_w_grantfirst             (dir_msInfo_2_bits_w_grantfirst),
    .io_msInfo_2_bits_s_release                (dir_msInfo_2_bits_s_release),
    .io_msInfo_2_bits_s_refill                 (dir_msInfo_2_bits_s_refill),
    .io_msInfo_2_bits_s_cmoresp                (dir_msInfo_2_bits_s_cmoresp),
    .io_msInfo_2_bits_s_cmometaw               (dir_msInfo_2_bits_s_cmometaw),
    .io_msInfo_2_bits_w_releaseack             (dir_msInfo_2_bits_w_releaseack),
    .io_msInfo_2_bits_w_replResp               (dir_msInfo_2_bits_w_replResp),
    .io_msInfo_2_bits_w_rprobeacklast          (dir_msInfo_2_bits_w_rprobeacklast),
    .io_msInfo_2_bits_replaceData              (dir_msInfo_2_bits_replaceData),
    .io_msInfo_2_bits_releaseToClean           (dir_msInfo_2_bits_releaseToClean),
    .io_msInfo_3_valid                         (dir_msInfo_3_valid),
    .io_msInfo_3_bits_channel                  (dir_msInfo_3_bits_channel),
    .io_msInfo_3_bits_set                      (dir_msInfo_3_bits_set),
    .io_msInfo_3_bits_way                      (dir_msInfo_3_bits_way),
    .io_msInfo_3_bits_reqTag                   (dir_msInfo_3_bits_reqTag),
    .io_msInfo_3_bits_willFree                 (dir_msInfo_3_bits_willFree),
    .io_msInfo_3_bits_aliasTask                (dir_msInfo_3_bits_aliasTask),
    .io_msInfo_3_bits_needRelease              (dir_msInfo_3_bits_needRelease),
    .io_msInfo_3_bits_blockRefill              (dir_msInfo_3_bits_blockRefill),
    .io_msInfo_3_bits_meta_dirty               (dir_msInfo_3_bits_meta_dirty),
    .io_msInfo_3_bits_meta_state               (dir_msInfo_3_bits_meta_state),
    .io_msInfo_3_bits_meta_clients             (dir_msInfo_3_bits_meta_clients),
    .io_msInfo_3_bits_meta_alias               (dir_msInfo_3_bits_meta_alias),
    .io_msInfo_3_bits_meta_prefetch            (dir_msInfo_3_bits_meta_prefetch),
    .io_msInfo_3_bits_meta_prefetchSrc         (dir_msInfo_3_bits_meta_prefetchSrc),
    .io_msInfo_3_bits_meta_accessed            (dir_msInfo_3_bits_meta_accessed),
    .io_msInfo_3_bits_meta_tagErr              (dir_msInfo_3_bits_meta_tagErr),
    .io_msInfo_3_bits_meta_dataErr             (dir_msInfo_3_bits_meta_dataErr),
    .io_msInfo_3_bits_metaTag                  (dir_msInfo_3_bits_metaTag),
    .io_msInfo_3_bits_dirHit                   (dir_msInfo_3_bits_dirHit),
    .io_msInfo_3_bits_isAcqOrPrefetch          (dir_msInfo_3_bits_isAcqOrPrefetch),
    .io_msInfo_3_bits_isPrefetch               (dir_msInfo_3_bits_isPrefetch),
    .io_msInfo_3_bits_param                    (dir_msInfo_3_bits_param),
    .io_msInfo_3_bits_mergeA                   (dir_msInfo_3_bits_mergeA),
    .io_msInfo_3_bits_w_grantfirst             (dir_msInfo_3_bits_w_grantfirst),
    .io_msInfo_3_bits_s_release                (dir_msInfo_3_bits_s_release),
    .io_msInfo_3_bits_s_refill                 (dir_msInfo_3_bits_s_refill),
    .io_msInfo_3_bits_s_cmoresp                (dir_msInfo_3_bits_s_cmoresp),
    .io_msInfo_3_bits_s_cmometaw               (dir_msInfo_3_bits_s_cmometaw),
    .io_msInfo_3_bits_w_releaseack             (dir_msInfo_3_bits_w_releaseack),
    .io_msInfo_3_bits_w_replResp               (dir_msInfo_3_bits_w_replResp),
    .io_msInfo_3_bits_w_rprobeacklast          (dir_msInfo_3_bits_w_rprobeacklast),
    .io_msInfo_3_bits_replaceData              (dir_msInfo_3_bits_replaceData),
    .io_msInfo_3_bits_releaseToClean           (dir_msInfo_3_bits_releaseToClean),
    .io_msInfo_4_valid                         (dir_msInfo_4_valid),
    .io_msInfo_4_bits_channel                  (dir_msInfo_4_bits_channel),
    .io_msInfo_4_bits_set                      (dir_msInfo_4_bits_set),
    .io_msInfo_4_bits_way                      (dir_msInfo_4_bits_way),
    .io_msInfo_4_bits_reqTag                   (dir_msInfo_4_bits_reqTag),
    .io_msInfo_4_bits_willFree                 (dir_msInfo_4_bits_willFree),
    .io_msInfo_4_bits_aliasTask                (dir_msInfo_4_bits_aliasTask),
    .io_msInfo_4_bits_needRelease              (dir_msInfo_4_bits_needRelease),
    .io_msInfo_4_bits_blockRefill              (dir_msInfo_4_bits_blockRefill),
    .io_msInfo_4_bits_meta_dirty               (dir_msInfo_4_bits_meta_dirty),
    .io_msInfo_4_bits_meta_state               (dir_msInfo_4_bits_meta_state),
    .io_msInfo_4_bits_meta_clients             (dir_msInfo_4_bits_meta_clients),
    .io_msInfo_4_bits_meta_alias               (dir_msInfo_4_bits_meta_alias),
    .io_msInfo_4_bits_meta_prefetch            (dir_msInfo_4_bits_meta_prefetch),
    .io_msInfo_4_bits_meta_prefetchSrc         (dir_msInfo_4_bits_meta_prefetchSrc),
    .io_msInfo_4_bits_meta_accessed            (dir_msInfo_4_bits_meta_accessed),
    .io_msInfo_4_bits_meta_tagErr              (dir_msInfo_4_bits_meta_tagErr),
    .io_msInfo_4_bits_meta_dataErr             (dir_msInfo_4_bits_meta_dataErr),
    .io_msInfo_4_bits_metaTag                  (dir_msInfo_4_bits_metaTag),
    .io_msInfo_4_bits_dirHit                   (dir_msInfo_4_bits_dirHit),
    .io_msInfo_4_bits_isAcqOrPrefetch          (dir_msInfo_4_bits_isAcqOrPrefetch),
    .io_msInfo_4_bits_isPrefetch               (dir_msInfo_4_bits_isPrefetch),
    .io_msInfo_4_bits_param                    (dir_msInfo_4_bits_param),
    .io_msInfo_4_bits_mergeA                   (dir_msInfo_4_bits_mergeA),
    .io_msInfo_4_bits_w_grantfirst             (dir_msInfo_4_bits_w_grantfirst),
    .io_msInfo_4_bits_s_release                (dir_msInfo_4_bits_s_release),
    .io_msInfo_4_bits_s_refill                 (dir_msInfo_4_bits_s_refill),
    .io_msInfo_4_bits_s_cmoresp                (dir_msInfo_4_bits_s_cmoresp),
    .io_msInfo_4_bits_s_cmometaw               (dir_msInfo_4_bits_s_cmometaw),
    .io_msInfo_4_bits_w_releaseack             (dir_msInfo_4_bits_w_releaseack),
    .io_msInfo_4_bits_w_replResp               (dir_msInfo_4_bits_w_replResp),
    .io_msInfo_4_bits_w_rprobeacklast          (dir_msInfo_4_bits_w_rprobeacklast),
    .io_msInfo_4_bits_replaceData              (dir_msInfo_4_bits_replaceData),
    .io_msInfo_4_bits_releaseToClean           (dir_msInfo_4_bits_releaseToClean),
    .io_msInfo_5_valid                         (dir_msInfo_5_valid),
    .io_msInfo_5_bits_channel                  (dir_msInfo_5_bits_channel),
    .io_msInfo_5_bits_set                      (dir_msInfo_5_bits_set),
    .io_msInfo_5_bits_way                      (dir_msInfo_5_bits_way),
    .io_msInfo_5_bits_reqTag                   (dir_msInfo_5_bits_reqTag),
    .io_msInfo_5_bits_willFree                 (dir_msInfo_5_bits_willFree),
    .io_msInfo_5_bits_aliasTask                (dir_msInfo_5_bits_aliasTask),
    .io_msInfo_5_bits_needRelease              (dir_msInfo_5_bits_needRelease),
    .io_msInfo_5_bits_blockRefill              (dir_msInfo_5_bits_blockRefill),
    .io_msInfo_5_bits_meta_dirty               (dir_msInfo_5_bits_meta_dirty),
    .io_msInfo_5_bits_meta_state               (dir_msInfo_5_bits_meta_state),
    .io_msInfo_5_bits_meta_clients             (dir_msInfo_5_bits_meta_clients),
    .io_msInfo_5_bits_meta_alias               (dir_msInfo_5_bits_meta_alias),
    .io_msInfo_5_bits_meta_prefetch            (dir_msInfo_5_bits_meta_prefetch),
    .io_msInfo_5_bits_meta_prefetchSrc         (dir_msInfo_5_bits_meta_prefetchSrc),
    .io_msInfo_5_bits_meta_accessed            (dir_msInfo_5_bits_meta_accessed),
    .io_msInfo_5_bits_meta_tagErr              (dir_msInfo_5_bits_meta_tagErr),
    .io_msInfo_5_bits_meta_dataErr             (dir_msInfo_5_bits_meta_dataErr),
    .io_msInfo_5_bits_metaTag                  (dir_msInfo_5_bits_metaTag),
    .io_msInfo_5_bits_dirHit                   (dir_msInfo_5_bits_dirHit),
    .io_msInfo_5_bits_isAcqOrPrefetch          (dir_msInfo_5_bits_isAcqOrPrefetch),
    .io_msInfo_5_bits_isPrefetch               (dir_msInfo_5_bits_isPrefetch),
    .io_msInfo_5_bits_param                    (dir_msInfo_5_bits_param),
    .io_msInfo_5_bits_mergeA                   (dir_msInfo_5_bits_mergeA),
    .io_msInfo_5_bits_w_grantfirst             (dir_msInfo_5_bits_w_grantfirst),
    .io_msInfo_5_bits_s_release                (dir_msInfo_5_bits_s_release),
    .io_msInfo_5_bits_s_refill                 (dir_msInfo_5_bits_s_refill),
    .io_msInfo_5_bits_s_cmoresp                (dir_msInfo_5_bits_s_cmoresp),
    .io_msInfo_5_bits_s_cmometaw               (dir_msInfo_5_bits_s_cmometaw),
    .io_msInfo_5_bits_w_releaseack             (dir_msInfo_5_bits_w_releaseack),
    .io_msInfo_5_bits_w_replResp               (dir_msInfo_5_bits_w_replResp),
    .io_msInfo_5_bits_w_rprobeacklast          (dir_msInfo_5_bits_w_rprobeacklast),
    .io_msInfo_5_bits_replaceData              (dir_msInfo_5_bits_replaceData),
    .io_msInfo_5_bits_releaseToClean           (dir_msInfo_5_bits_releaseToClean),
    .io_msInfo_6_valid                         (dir_msInfo_6_valid),
    .io_msInfo_6_bits_channel                  (dir_msInfo_6_bits_channel),
    .io_msInfo_6_bits_set                      (dir_msInfo_6_bits_set),
    .io_msInfo_6_bits_way                      (dir_msInfo_6_bits_way),
    .io_msInfo_6_bits_reqTag                   (dir_msInfo_6_bits_reqTag),
    .io_msInfo_6_bits_willFree                 (dir_msInfo_6_bits_willFree),
    .io_msInfo_6_bits_aliasTask                (dir_msInfo_6_bits_aliasTask),
    .io_msInfo_6_bits_needRelease              (dir_msInfo_6_bits_needRelease),
    .io_msInfo_6_bits_blockRefill              (dir_msInfo_6_bits_blockRefill),
    .io_msInfo_6_bits_meta_dirty               (dir_msInfo_6_bits_meta_dirty),
    .io_msInfo_6_bits_meta_state               (dir_msInfo_6_bits_meta_state),
    .io_msInfo_6_bits_meta_clients             (dir_msInfo_6_bits_meta_clients),
    .io_msInfo_6_bits_meta_alias               (dir_msInfo_6_bits_meta_alias),
    .io_msInfo_6_bits_meta_prefetch            (dir_msInfo_6_bits_meta_prefetch),
    .io_msInfo_6_bits_meta_prefetchSrc         (dir_msInfo_6_bits_meta_prefetchSrc),
    .io_msInfo_6_bits_meta_accessed            (dir_msInfo_6_bits_meta_accessed),
    .io_msInfo_6_bits_meta_tagErr              (dir_msInfo_6_bits_meta_tagErr),
    .io_msInfo_6_bits_meta_dataErr             (dir_msInfo_6_bits_meta_dataErr),
    .io_msInfo_6_bits_metaTag                  (dir_msInfo_6_bits_metaTag),
    .io_msInfo_6_bits_dirHit                   (dir_msInfo_6_bits_dirHit),
    .io_msInfo_6_bits_isAcqOrPrefetch          (dir_msInfo_6_bits_isAcqOrPrefetch),
    .io_msInfo_6_bits_isPrefetch               (dir_msInfo_6_bits_isPrefetch),
    .io_msInfo_6_bits_param                    (dir_msInfo_6_bits_param),
    .io_msInfo_6_bits_mergeA                   (dir_msInfo_6_bits_mergeA),
    .io_msInfo_6_bits_w_grantfirst             (dir_msInfo_6_bits_w_grantfirst),
    .io_msInfo_6_bits_s_release                (dir_msInfo_6_bits_s_release),
    .io_msInfo_6_bits_s_refill                 (dir_msInfo_6_bits_s_refill),
    .io_msInfo_6_bits_s_cmoresp                (dir_msInfo_6_bits_s_cmoresp),
    .io_msInfo_6_bits_s_cmometaw               (dir_msInfo_6_bits_s_cmometaw),
    .io_msInfo_6_bits_w_releaseack             (dir_msInfo_6_bits_w_releaseack),
    .io_msInfo_6_bits_w_replResp               (dir_msInfo_6_bits_w_replResp),
    .io_msInfo_6_bits_w_rprobeacklast          (dir_msInfo_6_bits_w_rprobeacklast),
    .io_msInfo_6_bits_replaceData              (dir_msInfo_6_bits_replaceData),
    .io_msInfo_6_bits_releaseToClean           (dir_msInfo_6_bits_releaseToClean),
    .io_msInfo_7_valid                         (dir_msInfo_7_valid),
    .io_msInfo_7_bits_channel                  (dir_msInfo_7_bits_channel),
    .io_msInfo_7_bits_set                      (dir_msInfo_7_bits_set),
    .io_msInfo_7_bits_way                      (dir_msInfo_7_bits_way),
    .io_msInfo_7_bits_reqTag                   (dir_msInfo_7_bits_reqTag),
    .io_msInfo_7_bits_willFree                 (dir_msInfo_7_bits_willFree),
    .io_msInfo_7_bits_aliasTask                (dir_msInfo_7_bits_aliasTask),
    .io_msInfo_7_bits_needRelease              (dir_msInfo_7_bits_needRelease),
    .io_msInfo_7_bits_blockRefill              (dir_msInfo_7_bits_blockRefill),
    .io_msInfo_7_bits_meta_dirty               (dir_msInfo_7_bits_meta_dirty),
    .io_msInfo_7_bits_meta_state               (dir_msInfo_7_bits_meta_state),
    .io_msInfo_7_bits_meta_clients             (dir_msInfo_7_bits_meta_clients),
    .io_msInfo_7_bits_meta_alias               (dir_msInfo_7_bits_meta_alias),
    .io_msInfo_7_bits_meta_prefetch            (dir_msInfo_7_bits_meta_prefetch),
    .io_msInfo_7_bits_meta_prefetchSrc         (dir_msInfo_7_bits_meta_prefetchSrc),
    .io_msInfo_7_bits_meta_accessed            (dir_msInfo_7_bits_meta_accessed),
    .io_msInfo_7_bits_meta_tagErr              (dir_msInfo_7_bits_meta_tagErr),
    .io_msInfo_7_bits_meta_dataErr             (dir_msInfo_7_bits_meta_dataErr),
    .io_msInfo_7_bits_metaTag                  (dir_msInfo_7_bits_metaTag),
    .io_msInfo_7_bits_dirHit                   (dir_msInfo_7_bits_dirHit),
    .io_msInfo_7_bits_isAcqOrPrefetch          (dir_msInfo_7_bits_isAcqOrPrefetch),
    .io_msInfo_7_bits_isPrefetch               (dir_msInfo_7_bits_isPrefetch),
    .io_msInfo_7_bits_param                    (dir_msInfo_7_bits_param),
    .io_msInfo_7_bits_mergeA                   (dir_msInfo_7_bits_mergeA),
    .io_msInfo_7_bits_w_grantfirst             (dir_msInfo_7_bits_w_grantfirst),
    .io_msInfo_7_bits_s_release                (dir_msInfo_7_bits_s_release),
    .io_msInfo_7_bits_s_refill                 (dir_msInfo_7_bits_s_refill),
    .io_msInfo_7_bits_s_cmoresp                (dir_msInfo_7_bits_s_cmoresp),
    .io_msInfo_7_bits_s_cmometaw               (dir_msInfo_7_bits_s_cmometaw),
    .io_msInfo_7_bits_w_releaseack             (dir_msInfo_7_bits_w_releaseack),
    .io_msInfo_7_bits_w_replResp               (dir_msInfo_7_bits_w_replResp),
    .io_msInfo_7_bits_w_rprobeacklast          (dir_msInfo_7_bits_w_rprobeacklast),
    .io_msInfo_7_bits_replaceData              (dir_msInfo_7_bits_replaceData),
    .io_msInfo_7_bits_releaseToClean           (dir_msInfo_7_bits_releaseToClean),
    .io_msInfo_8_valid                         (dir_msInfo_8_valid),
    .io_msInfo_8_bits_channel                  (dir_msInfo_8_bits_channel),
    .io_msInfo_8_bits_set                      (dir_msInfo_8_bits_set),
    .io_msInfo_8_bits_way                      (dir_msInfo_8_bits_way),
    .io_msInfo_8_bits_reqTag                   (dir_msInfo_8_bits_reqTag),
    .io_msInfo_8_bits_willFree                 (dir_msInfo_8_bits_willFree),
    .io_msInfo_8_bits_aliasTask                (dir_msInfo_8_bits_aliasTask),
    .io_msInfo_8_bits_needRelease              (dir_msInfo_8_bits_needRelease),
    .io_msInfo_8_bits_blockRefill              (dir_msInfo_8_bits_blockRefill),
    .io_msInfo_8_bits_meta_dirty               (dir_msInfo_8_bits_meta_dirty),
    .io_msInfo_8_bits_meta_state               (dir_msInfo_8_bits_meta_state),
    .io_msInfo_8_bits_meta_clients             (dir_msInfo_8_bits_meta_clients),
    .io_msInfo_8_bits_meta_alias               (dir_msInfo_8_bits_meta_alias),
    .io_msInfo_8_bits_meta_prefetch            (dir_msInfo_8_bits_meta_prefetch),
    .io_msInfo_8_bits_meta_prefetchSrc         (dir_msInfo_8_bits_meta_prefetchSrc),
    .io_msInfo_8_bits_meta_accessed            (dir_msInfo_8_bits_meta_accessed),
    .io_msInfo_8_bits_meta_tagErr              (dir_msInfo_8_bits_meta_tagErr),
    .io_msInfo_8_bits_meta_dataErr             (dir_msInfo_8_bits_meta_dataErr),
    .io_msInfo_8_bits_metaTag                  (dir_msInfo_8_bits_metaTag),
    .io_msInfo_8_bits_dirHit                   (dir_msInfo_8_bits_dirHit),
    .io_msInfo_8_bits_isAcqOrPrefetch          (dir_msInfo_8_bits_isAcqOrPrefetch),
    .io_msInfo_8_bits_isPrefetch               (dir_msInfo_8_bits_isPrefetch),
    .io_msInfo_8_bits_param                    (dir_msInfo_8_bits_param),
    .io_msInfo_8_bits_mergeA                   (dir_msInfo_8_bits_mergeA),
    .io_msInfo_8_bits_w_grantfirst             (dir_msInfo_8_bits_w_grantfirst),
    .io_msInfo_8_bits_s_release                (dir_msInfo_8_bits_s_release),
    .io_msInfo_8_bits_s_refill                 (dir_msInfo_8_bits_s_refill),
    .io_msInfo_8_bits_s_cmoresp                (dir_msInfo_8_bits_s_cmoresp),
    .io_msInfo_8_bits_s_cmometaw               (dir_msInfo_8_bits_s_cmometaw),
    .io_msInfo_8_bits_w_releaseack             (dir_msInfo_8_bits_w_releaseack),
    .io_msInfo_8_bits_w_replResp               (dir_msInfo_8_bits_w_replResp),
    .io_msInfo_8_bits_w_rprobeacklast          (dir_msInfo_8_bits_w_rprobeacklast),
    .io_msInfo_8_bits_replaceData              (dir_msInfo_8_bits_replaceData),
    .io_msInfo_8_bits_releaseToClean           (dir_msInfo_8_bits_releaseToClean),
    .io_msInfo_9_valid                         (dir_msInfo_9_valid),
    .io_msInfo_9_bits_channel                  (dir_msInfo_9_bits_channel),
    .io_msInfo_9_bits_set                      (dir_msInfo_9_bits_set),
    .io_msInfo_9_bits_way                      (dir_msInfo_9_bits_way),
    .io_msInfo_9_bits_reqTag                   (dir_msInfo_9_bits_reqTag),
    .io_msInfo_9_bits_willFree                 (dir_msInfo_9_bits_willFree),
    .io_msInfo_9_bits_aliasTask                (dir_msInfo_9_bits_aliasTask),
    .io_msInfo_9_bits_needRelease              (dir_msInfo_9_bits_needRelease),
    .io_msInfo_9_bits_blockRefill              (dir_msInfo_9_bits_blockRefill),
    .io_msInfo_9_bits_meta_dirty               (dir_msInfo_9_bits_meta_dirty),
    .io_msInfo_9_bits_meta_state               (dir_msInfo_9_bits_meta_state),
    .io_msInfo_9_bits_meta_clients             (dir_msInfo_9_bits_meta_clients),
    .io_msInfo_9_bits_meta_alias               (dir_msInfo_9_bits_meta_alias),
    .io_msInfo_9_bits_meta_prefetch            (dir_msInfo_9_bits_meta_prefetch),
    .io_msInfo_9_bits_meta_prefetchSrc         (dir_msInfo_9_bits_meta_prefetchSrc),
    .io_msInfo_9_bits_meta_accessed            (dir_msInfo_9_bits_meta_accessed),
    .io_msInfo_9_bits_meta_tagErr              (dir_msInfo_9_bits_meta_tagErr),
    .io_msInfo_9_bits_meta_dataErr             (dir_msInfo_9_bits_meta_dataErr),
    .io_msInfo_9_bits_metaTag                  (dir_msInfo_9_bits_metaTag),
    .io_msInfo_9_bits_dirHit                   (dir_msInfo_9_bits_dirHit),
    .io_msInfo_9_bits_isAcqOrPrefetch          (dir_msInfo_9_bits_isAcqOrPrefetch),
    .io_msInfo_9_bits_isPrefetch               (dir_msInfo_9_bits_isPrefetch),
    .io_msInfo_9_bits_param                    (dir_msInfo_9_bits_param),
    .io_msInfo_9_bits_mergeA                   (dir_msInfo_9_bits_mergeA),
    .io_msInfo_9_bits_w_grantfirst             (dir_msInfo_9_bits_w_grantfirst),
    .io_msInfo_9_bits_s_release                (dir_msInfo_9_bits_s_release),
    .io_msInfo_9_bits_s_refill                 (dir_msInfo_9_bits_s_refill),
    .io_msInfo_9_bits_s_cmoresp                (dir_msInfo_9_bits_s_cmoresp),
    .io_msInfo_9_bits_s_cmometaw               (dir_msInfo_9_bits_s_cmometaw),
    .io_msInfo_9_bits_w_releaseack             (dir_msInfo_9_bits_w_releaseack),
    .io_msInfo_9_bits_w_replResp               (dir_msInfo_9_bits_w_replResp),
    .io_msInfo_9_bits_w_rprobeacklast          (dir_msInfo_9_bits_w_rprobeacklast),
    .io_msInfo_9_bits_replaceData              (dir_msInfo_9_bits_replaceData),
    .io_msInfo_9_bits_releaseToClean           (dir_msInfo_9_bits_releaseToClean),
    .io_msInfo_10_valid                        (dir_msInfo_10_valid),
    .io_msInfo_10_bits_channel                 (dir_msInfo_10_bits_channel),
    .io_msInfo_10_bits_set                     (dir_msInfo_10_bits_set),
    .io_msInfo_10_bits_way                     (dir_msInfo_10_bits_way),
    .io_msInfo_10_bits_reqTag                  (dir_msInfo_10_bits_reqTag),
    .io_msInfo_10_bits_willFree                (dir_msInfo_10_bits_willFree),
    .io_msInfo_10_bits_aliasTask               (dir_msInfo_10_bits_aliasTask),
    .io_msInfo_10_bits_needRelease             (dir_msInfo_10_bits_needRelease),
    .io_msInfo_10_bits_blockRefill             (dir_msInfo_10_bits_blockRefill),
    .io_msInfo_10_bits_meta_dirty              (dir_msInfo_10_bits_meta_dirty),
    .io_msInfo_10_bits_meta_state              (dir_msInfo_10_bits_meta_state),
    .io_msInfo_10_bits_meta_clients            (dir_msInfo_10_bits_meta_clients),
    .io_msInfo_10_bits_meta_alias              (dir_msInfo_10_bits_meta_alias),
    .io_msInfo_10_bits_meta_prefetch           (dir_msInfo_10_bits_meta_prefetch),
    .io_msInfo_10_bits_meta_prefetchSrc        (dir_msInfo_10_bits_meta_prefetchSrc),
    .io_msInfo_10_bits_meta_accessed           (dir_msInfo_10_bits_meta_accessed),
    .io_msInfo_10_bits_meta_tagErr             (dir_msInfo_10_bits_meta_tagErr),
    .io_msInfo_10_bits_meta_dataErr            (dir_msInfo_10_bits_meta_dataErr),
    .io_msInfo_10_bits_metaTag                 (dir_msInfo_10_bits_metaTag),
    .io_msInfo_10_bits_dirHit                  (dir_msInfo_10_bits_dirHit),
    .io_msInfo_10_bits_isAcqOrPrefetch         (dir_msInfo_10_bits_isAcqOrPrefetch),
    .io_msInfo_10_bits_isPrefetch              (dir_msInfo_10_bits_isPrefetch),
    .io_msInfo_10_bits_param                   (dir_msInfo_10_bits_param),
    .io_msInfo_10_bits_mergeA                  (dir_msInfo_10_bits_mergeA),
    .io_msInfo_10_bits_w_grantfirst            (dir_msInfo_10_bits_w_grantfirst),
    .io_msInfo_10_bits_s_release               (dir_msInfo_10_bits_s_release),
    .io_msInfo_10_bits_s_refill                (dir_msInfo_10_bits_s_refill),
    .io_msInfo_10_bits_s_cmoresp               (dir_msInfo_10_bits_s_cmoresp),
    .io_msInfo_10_bits_s_cmometaw              (dir_msInfo_10_bits_s_cmometaw),
    .io_msInfo_10_bits_w_releaseack            (dir_msInfo_10_bits_w_releaseack),
    .io_msInfo_10_bits_w_replResp              (dir_msInfo_10_bits_w_replResp),
    .io_msInfo_10_bits_w_rprobeacklast         (dir_msInfo_10_bits_w_rprobeacklast),
    .io_msInfo_10_bits_replaceData             (dir_msInfo_10_bits_replaceData),
    .io_msInfo_10_bits_releaseToClean          (dir_msInfo_10_bits_releaseToClean),
    .io_msInfo_11_valid                        (dir_msInfo_11_valid),
    .io_msInfo_11_bits_channel                 (dir_msInfo_11_bits_channel),
    .io_msInfo_11_bits_set                     (dir_msInfo_11_bits_set),
    .io_msInfo_11_bits_way                     (dir_msInfo_11_bits_way),
    .io_msInfo_11_bits_reqTag                  (dir_msInfo_11_bits_reqTag),
    .io_msInfo_11_bits_willFree                (dir_msInfo_11_bits_willFree),
    .io_msInfo_11_bits_aliasTask               (dir_msInfo_11_bits_aliasTask),
    .io_msInfo_11_bits_needRelease             (dir_msInfo_11_bits_needRelease),
    .io_msInfo_11_bits_blockRefill             (dir_msInfo_11_bits_blockRefill),
    .io_msInfo_11_bits_meta_dirty              (dir_msInfo_11_bits_meta_dirty),
    .io_msInfo_11_bits_meta_state              (dir_msInfo_11_bits_meta_state),
    .io_msInfo_11_bits_meta_clients            (dir_msInfo_11_bits_meta_clients),
    .io_msInfo_11_bits_meta_alias              (dir_msInfo_11_bits_meta_alias),
    .io_msInfo_11_bits_meta_prefetch           (dir_msInfo_11_bits_meta_prefetch),
    .io_msInfo_11_bits_meta_prefetchSrc        (dir_msInfo_11_bits_meta_prefetchSrc),
    .io_msInfo_11_bits_meta_accessed           (dir_msInfo_11_bits_meta_accessed),
    .io_msInfo_11_bits_meta_tagErr             (dir_msInfo_11_bits_meta_tagErr),
    .io_msInfo_11_bits_meta_dataErr            (dir_msInfo_11_bits_meta_dataErr),
    .io_msInfo_11_bits_metaTag                 (dir_msInfo_11_bits_metaTag),
    .io_msInfo_11_bits_dirHit                  (dir_msInfo_11_bits_dirHit),
    .io_msInfo_11_bits_isAcqOrPrefetch         (dir_msInfo_11_bits_isAcqOrPrefetch),
    .io_msInfo_11_bits_isPrefetch              (dir_msInfo_11_bits_isPrefetch),
    .io_msInfo_11_bits_param                   (dir_msInfo_11_bits_param),
    .io_msInfo_11_bits_mergeA                  (dir_msInfo_11_bits_mergeA),
    .io_msInfo_11_bits_w_grantfirst            (dir_msInfo_11_bits_w_grantfirst),
    .io_msInfo_11_bits_s_release               (dir_msInfo_11_bits_s_release),
    .io_msInfo_11_bits_s_refill                (dir_msInfo_11_bits_s_refill),
    .io_msInfo_11_bits_s_cmoresp               (dir_msInfo_11_bits_s_cmoresp),
    .io_msInfo_11_bits_s_cmometaw              (dir_msInfo_11_bits_s_cmometaw),
    .io_msInfo_11_bits_w_releaseack            (dir_msInfo_11_bits_w_releaseack),
    .io_msInfo_11_bits_w_replResp              (dir_msInfo_11_bits_w_replResp),
    .io_msInfo_11_bits_w_rprobeacklast         (dir_msInfo_11_bits_w_rprobeacklast),
    .io_msInfo_11_bits_replaceData             (dir_msInfo_11_bits_replaceData),
    .io_msInfo_11_bits_releaseToClean          (dir_msInfo_11_bits_releaseToClean),
    .io_msInfo_12_valid                        (dir_msInfo_12_valid),
    .io_msInfo_12_bits_channel                 (dir_msInfo_12_bits_channel),
    .io_msInfo_12_bits_set                     (dir_msInfo_12_bits_set),
    .io_msInfo_12_bits_way                     (dir_msInfo_12_bits_way),
    .io_msInfo_12_bits_reqTag                  (dir_msInfo_12_bits_reqTag),
    .io_msInfo_12_bits_willFree                (dir_msInfo_12_bits_willFree),
    .io_msInfo_12_bits_aliasTask               (dir_msInfo_12_bits_aliasTask),
    .io_msInfo_12_bits_needRelease             (dir_msInfo_12_bits_needRelease),
    .io_msInfo_12_bits_blockRefill             (dir_msInfo_12_bits_blockRefill),
    .io_msInfo_12_bits_meta_dirty              (dir_msInfo_12_bits_meta_dirty),
    .io_msInfo_12_bits_meta_state              (dir_msInfo_12_bits_meta_state),
    .io_msInfo_12_bits_meta_clients            (dir_msInfo_12_bits_meta_clients),
    .io_msInfo_12_bits_meta_alias              (dir_msInfo_12_bits_meta_alias),
    .io_msInfo_12_bits_meta_prefetch           (dir_msInfo_12_bits_meta_prefetch),
    .io_msInfo_12_bits_meta_prefetchSrc        (dir_msInfo_12_bits_meta_prefetchSrc),
    .io_msInfo_12_bits_meta_accessed           (dir_msInfo_12_bits_meta_accessed),
    .io_msInfo_12_bits_meta_tagErr             (dir_msInfo_12_bits_meta_tagErr),
    .io_msInfo_12_bits_meta_dataErr            (dir_msInfo_12_bits_meta_dataErr),
    .io_msInfo_12_bits_metaTag                 (dir_msInfo_12_bits_metaTag),
    .io_msInfo_12_bits_dirHit                  (dir_msInfo_12_bits_dirHit),
    .io_msInfo_12_bits_isAcqOrPrefetch         (dir_msInfo_12_bits_isAcqOrPrefetch),
    .io_msInfo_12_bits_isPrefetch              (dir_msInfo_12_bits_isPrefetch),
    .io_msInfo_12_bits_param                   (dir_msInfo_12_bits_param),
    .io_msInfo_12_bits_mergeA                  (dir_msInfo_12_bits_mergeA),
    .io_msInfo_12_bits_w_grantfirst            (dir_msInfo_12_bits_w_grantfirst),
    .io_msInfo_12_bits_s_release               (dir_msInfo_12_bits_s_release),
    .io_msInfo_12_bits_s_refill                (dir_msInfo_12_bits_s_refill),
    .io_msInfo_12_bits_s_cmoresp               (dir_msInfo_12_bits_s_cmoresp),
    .io_msInfo_12_bits_s_cmometaw              (dir_msInfo_12_bits_s_cmometaw),
    .io_msInfo_12_bits_w_releaseack            (dir_msInfo_12_bits_w_releaseack),
    .io_msInfo_12_bits_w_replResp              (dir_msInfo_12_bits_w_replResp),
    .io_msInfo_12_bits_w_rprobeacklast         (dir_msInfo_12_bits_w_rprobeacklast),
    .io_msInfo_12_bits_replaceData             (dir_msInfo_12_bits_replaceData),
    .io_msInfo_12_bits_releaseToClean          (dir_msInfo_12_bits_releaseToClean),
    .io_msInfo_13_valid                        (dir_msInfo_13_valid),
    .io_msInfo_13_bits_channel                 (dir_msInfo_13_bits_channel),
    .io_msInfo_13_bits_set                     (dir_msInfo_13_bits_set),
    .io_msInfo_13_bits_way                     (dir_msInfo_13_bits_way),
    .io_msInfo_13_bits_reqTag                  (dir_msInfo_13_bits_reqTag),
    .io_msInfo_13_bits_willFree                (dir_msInfo_13_bits_willFree),
    .io_msInfo_13_bits_aliasTask               (dir_msInfo_13_bits_aliasTask),
    .io_msInfo_13_bits_needRelease             (dir_msInfo_13_bits_needRelease),
    .io_msInfo_13_bits_blockRefill             (dir_msInfo_13_bits_blockRefill),
    .io_msInfo_13_bits_meta_dirty              (dir_msInfo_13_bits_meta_dirty),
    .io_msInfo_13_bits_meta_state              (dir_msInfo_13_bits_meta_state),
    .io_msInfo_13_bits_meta_clients            (dir_msInfo_13_bits_meta_clients),
    .io_msInfo_13_bits_meta_alias              (dir_msInfo_13_bits_meta_alias),
    .io_msInfo_13_bits_meta_prefetch           (dir_msInfo_13_bits_meta_prefetch),
    .io_msInfo_13_bits_meta_prefetchSrc        (dir_msInfo_13_bits_meta_prefetchSrc),
    .io_msInfo_13_bits_meta_accessed           (dir_msInfo_13_bits_meta_accessed),
    .io_msInfo_13_bits_meta_tagErr             (dir_msInfo_13_bits_meta_tagErr),
    .io_msInfo_13_bits_meta_dataErr            (dir_msInfo_13_bits_meta_dataErr),
    .io_msInfo_13_bits_metaTag                 (dir_msInfo_13_bits_metaTag),
    .io_msInfo_13_bits_dirHit                  (dir_msInfo_13_bits_dirHit),
    .io_msInfo_13_bits_isAcqOrPrefetch         (dir_msInfo_13_bits_isAcqOrPrefetch),
    .io_msInfo_13_bits_isPrefetch              (dir_msInfo_13_bits_isPrefetch),
    .io_msInfo_13_bits_param                   (dir_msInfo_13_bits_param),
    .io_msInfo_13_bits_mergeA                  (dir_msInfo_13_bits_mergeA),
    .io_msInfo_13_bits_w_grantfirst            (dir_msInfo_13_bits_w_grantfirst),
    .io_msInfo_13_bits_s_release               (dir_msInfo_13_bits_s_release),
    .io_msInfo_13_bits_s_refill                (dir_msInfo_13_bits_s_refill),
    .io_msInfo_13_bits_s_cmoresp               (dir_msInfo_13_bits_s_cmoresp),
    .io_msInfo_13_bits_s_cmometaw              (dir_msInfo_13_bits_s_cmometaw),
    .io_msInfo_13_bits_w_releaseack            (dir_msInfo_13_bits_w_releaseack),
    .io_msInfo_13_bits_w_replResp              (dir_msInfo_13_bits_w_replResp),
    .io_msInfo_13_bits_w_rprobeacklast         (dir_msInfo_13_bits_w_rprobeacklast),
    .io_msInfo_13_bits_replaceData             (dir_msInfo_13_bits_replaceData),
    .io_msInfo_13_bits_releaseToClean          (dir_msInfo_13_bits_releaseToClean),
    .io_msInfo_14_valid                        (dir_msInfo_14_valid),
    .io_msInfo_14_bits_channel                 (dir_msInfo_14_bits_channel),
    .io_msInfo_14_bits_set                     (dir_msInfo_14_bits_set),
    .io_msInfo_14_bits_way                     (dir_msInfo_14_bits_way),
    .io_msInfo_14_bits_reqTag                  (dir_msInfo_14_bits_reqTag),
    .io_msInfo_14_bits_willFree                (dir_msInfo_14_bits_willFree),
    .io_msInfo_14_bits_aliasTask               (dir_msInfo_14_bits_aliasTask),
    .io_msInfo_14_bits_needRelease             (dir_msInfo_14_bits_needRelease),
    .io_msInfo_14_bits_blockRefill             (dir_msInfo_14_bits_blockRefill),
    .io_msInfo_14_bits_meta_dirty              (dir_msInfo_14_bits_meta_dirty),
    .io_msInfo_14_bits_meta_state              (dir_msInfo_14_bits_meta_state),
    .io_msInfo_14_bits_meta_clients            (dir_msInfo_14_bits_meta_clients),
    .io_msInfo_14_bits_meta_alias              (dir_msInfo_14_bits_meta_alias),
    .io_msInfo_14_bits_meta_prefetch           (dir_msInfo_14_bits_meta_prefetch),
    .io_msInfo_14_bits_meta_prefetchSrc        (dir_msInfo_14_bits_meta_prefetchSrc),
    .io_msInfo_14_bits_meta_accessed           (dir_msInfo_14_bits_meta_accessed),
    .io_msInfo_14_bits_meta_tagErr             (dir_msInfo_14_bits_meta_tagErr),
    .io_msInfo_14_bits_meta_dataErr            (dir_msInfo_14_bits_meta_dataErr),
    .io_msInfo_14_bits_metaTag                 (dir_msInfo_14_bits_metaTag),
    .io_msInfo_14_bits_dirHit                  (dir_msInfo_14_bits_dirHit),
    .io_msInfo_14_bits_isAcqOrPrefetch         (dir_msInfo_14_bits_isAcqOrPrefetch),
    .io_msInfo_14_bits_isPrefetch              (dir_msInfo_14_bits_isPrefetch),
    .io_msInfo_14_bits_param                   (dir_msInfo_14_bits_param),
    .io_msInfo_14_bits_mergeA                  (dir_msInfo_14_bits_mergeA),
    .io_msInfo_14_bits_w_grantfirst            (dir_msInfo_14_bits_w_grantfirst),
    .io_msInfo_14_bits_s_release               (dir_msInfo_14_bits_s_release),
    .io_msInfo_14_bits_s_refill                (dir_msInfo_14_bits_s_refill),
    .io_msInfo_14_bits_s_cmoresp               (dir_msInfo_14_bits_s_cmoresp),
    .io_msInfo_14_bits_s_cmometaw              (dir_msInfo_14_bits_s_cmometaw),
    .io_msInfo_14_bits_w_releaseack            (dir_msInfo_14_bits_w_releaseack),
    .io_msInfo_14_bits_w_replResp              (dir_msInfo_14_bits_w_replResp),
    .io_msInfo_14_bits_w_rprobeacklast         (dir_msInfo_14_bits_w_rprobeacklast),
    .io_msInfo_14_bits_replaceData             (dir_msInfo_14_bits_replaceData),
    .io_msInfo_14_bits_releaseToClean          (dir_msInfo_14_bits_releaseToClean),
    .io_msInfo_15_valid                        (dir_msInfo_15_valid),
    .io_msInfo_15_bits_channel                 (dir_msInfo_15_bits_channel),
    .io_msInfo_15_bits_set                     (dir_msInfo_15_bits_set),
    .io_msInfo_15_bits_way                     (dir_msInfo_15_bits_way),
    .io_msInfo_15_bits_reqTag                  (dir_msInfo_15_bits_reqTag),
    .io_msInfo_15_bits_willFree                (dir_msInfo_15_bits_willFree),
    .io_msInfo_15_bits_aliasTask               (dir_msInfo_15_bits_aliasTask),
    .io_msInfo_15_bits_needRelease             (dir_msInfo_15_bits_needRelease),
    .io_msInfo_15_bits_blockRefill             (dir_msInfo_15_bits_blockRefill),
    .io_msInfo_15_bits_meta_dirty              (dir_msInfo_15_bits_meta_dirty),
    .io_msInfo_15_bits_meta_state              (dir_msInfo_15_bits_meta_state),
    .io_msInfo_15_bits_meta_clients            (dir_msInfo_15_bits_meta_clients),
    .io_msInfo_15_bits_meta_alias              (dir_msInfo_15_bits_meta_alias),
    .io_msInfo_15_bits_meta_prefetch           (dir_msInfo_15_bits_meta_prefetch),
    .io_msInfo_15_bits_meta_prefetchSrc        (dir_msInfo_15_bits_meta_prefetchSrc),
    .io_msInfo_15_bits_meta_accessed           (dir_msInfo_15_bits_meta_accessed),
    .io_msInfo_15_bits_meta_tagErr             (dir_msInfo_15_bits_meta_tagErr),
    .io_msInfo_15_bits_meta_dataErr            (dir_msInfo_15_bits_meta_dataErr),
    .io_msInfo_15_bits_metaTag                 (dir_msInfo_15_bits_metaTag),
    .io_msInfo_15_bits_dirHit                  (dir_msInfo_15_bits_dirHit),
    .io_msInfo_15_bits_isAcqOrPrefetch         (dir_msInfo_15_bits_isAcqOrPrefetch),
    .io_msInfo_15_bits_isPrefetch              (dir_msInfo_15_bits_isPrefetch),
    .io_msInfo_15_bits_param                   (dir_msInfo_15_bits_param),
    .io_msInfo_15_bits_mergeA                  (dir_msInfo_15_bits_mergeA),
    .io_msInfo_15_bits_w_grantfirst            (dir_msInfo_15_bits_w_grantfirst),
    .io_msInfo_15_bits_s_release               (dir_msInfo_15_bits_s_release),
    .io_msInfo_15_bits_s_refill                (dir_msInfo_15_bits_s_refill),
    .io_msInfo_15_bits_s_cmoresp               (dir_msInfo_15_bits_s_cmoresp),
    .io_msInfo_15_bits_s_cmometaw              (dir_msInfo_15_bits_s_cmometaw),
    .io_msInfo_15_bits_w_releaseack            (dir_msInfo_15_bits_w_releaseack),
    .io_msInfo_15_bits_w_replResp              (dir_msInfo_15_bits_w_replResp),
    .io_msInfo_15_bits_w_rprobeacklast         (dir_msInfo_15_bits_w_rprobeacklast),
    .io_msInfo_15_bits_replaceData             (dir_msInfo_15_bits_replaceData),
    .io_msInfo_15_bits_releaseToClean          (dir_msInfo_15_bits_releaseToClean),
    .boreChildrenBd_bore_array                 (mbist_dir_array),
    .boreChildrenBd_bore_all                   (mbist_dir_all),
    .boreChildrenBd_bore_req                   (mbist_dir_req),
    .boreChildrenBd_bore_ack                   (mbist_dir_ack),
    .boreChildrenBd_bore_writeen               (mbist_dir_writeen),
    .boreChildrenBd_bore_be                    (mbist_dir_be),
    .boreChildrenBd_bore_addr                  (mbist_dir_addr),
    .boreChildrenBd_bore_indata                (mbist_dir_indata),
    .boreChildrenBd_bore_readen                (mbist_dir_readen),
    .boreChildrenBd_bore_addr_rd               (mbist_dir_addr_rd),
    .boreChildrenBd_bore_outdata               (mbist_dir_outdata),
    .sigFromSrams_bore_ram_hold                (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass              (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken            (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk             (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp            (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold            (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen                    (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold              (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass            (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken          (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk           (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp          (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold          (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                  (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold              (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass            (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken          (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk           (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp          (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold          (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                  (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold              (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass            (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken          (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk           (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp          (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold          (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                  (sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold              (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass            (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken          (sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk           (sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp          (sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold          (sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                  (sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold              (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass            (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken          (sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk           (sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp          (sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold          (sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen                  (sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold              (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass            (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken          (sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk           (sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp          (sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold          (sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen                  (sigFromSrams_bore_6_cgen)
  );

  // §W5 数据阵列，本变体 = DataStorage_2
  DataStorage_2 dataStorage (
    .clock                            (clock),
    .reset                            (reset),
    .io_en                            (ds_en),
    .io_error                         (ds_error),
    .io_req_valid                     (ds_req_valid),
    .io_req_bits_way                  (ds_req_bits_way),
    .io_req_bits_set                  (ds_req_bits_set),
    .io_req_bits_wen                  (ds_req_bits_wen),
    .io_rdata_data                    (ds_rdata_data),
    .io_wdata_data                    (ds_wdata_data),
    .boreChildrenBd_bore_array        (mbist_ds_array),
    .boreChildrenBd_bore_all          (mbist_ds_all),
    .boreChildrenBd_bore_req          (mbist_ds_req),
    .boreChildrenBd_bore_ack          (mbist_ds_ack),
    .boreChildrenBd_bore_writeen      (mbist_ds_writeen),
    .boreChildrenBd_bore_be           (mbist_ds_be),
    .boreChildrenBd_bore_addr         (mbist_ds_addr),
    .boreChildrenBd_bore_indata       (mbist_ds_indata),
    .boreChildrenBd_bore_readen       (mbist_ds_readen),
    .boreChildrenBd_bore_addr_rd      (mbist_ds_addr_rd),
    .boreChildrenBd_bore_outdata      (mbist_ds_outdata),
    .sigFromSrams_bore_ram_hold       (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_ram_bypass     (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken   (sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk    (sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp   (sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold   (sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_cgen           (sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_1_ram_hold     (sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_1_ram_bypass   (sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk  (sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen         (sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_2_ram_hold     (sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_2_ram_bypass   (sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk  (sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen         (sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_3_ram_hold     (sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_3_ram_bypass   (sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk  (sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen         (sigFromSrams_bore_10_cgen)
  );

  // §W6 MBIST 分发（L2Slice_2）：顶层 bore -> 目录（路 0）/ 数据阵列（路 1）
  L2Slice_2 mbistPl (
    .clock                    (clock),
    .reset                    (reset),
    .mbist_array              (boreChildrenBd_bore_array),
    .mbist_all                (boreChildrenBd_bore_all),
    .mbist_req                (boreChildrenBd_bore_req),
    .mbist_ack                (boreChildrenBd_bore_ack),
    .mbist_writeen            (boreChildrenBd_bore_writeen),
    .mbist_be                 (boreChildrenBd_bore_be),
    .mbist_addr               (boreChildrenBd_bore_addr),
    .mbist_indata             (boreChildrenBd_bore_indata),
    .mbist_readen             (boreChildrenBd_bore_readen),
    .mbist_addr_rd            (boreChildrenBd_bore_addr_rd),
    .mbist_outdata            (boreChildrenBd_bore_outdata),
    .toNextPipeline_0_array   (mbist_dir_array),
    .toNextPipeline_0_all     (mbist_dir_all),
    .toNextPipeline_0_req     (mbist_dir_req),
    .toNextPipeline_0_ack     (mbist_dir_ack),
    .toNextPipeline_0_writeen (mbist_dir_writeen),
    .toNextPipeline_0_be      (mbist_dir_be),
    .toNextPipeline_0_addr    (mbist_dir_addr),
    .toNextPipeline_0_indata  (mbist_dir_indata),
    .toNextPipeline_0_readen  (mbist_dir_readen),
    .toNextPipeline_0_addr_rd (mbist_dir_addr_rd),
    .toNextPipeline_0_outdata (mbist_dir_outdata),
    .toNextPipeline_1_array   (mbist_ds_array),
    .toNextPipeline_1_all     (mbist_ds_all),
    .toNextPipeline_1_req     (mbist_ds_req),
    .toNextPipeline_1_ack     (mbist_ds_ack),
    .toNextPipeline_1_writeen (mbist_ds_writeen),
    .toNextPipeline_1_be      (mbist_ds_be),
    .toNextPipeline_1_addr    (mbist_ds_addr),
    .toNextPipeline_1_indata  (mbist_ds_indata),
    .toNextPipeline_1_readen  (mbist_ds_readen),
    .toNextPipeline_1_addr_rd (mbist_ds_addr_rd),
    .toNextPipeline_1_outdata (mbist_ds_outdata)
  );
endmodule
// END GENERATED(Slice_2)
