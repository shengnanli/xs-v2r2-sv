// 自动生成:scripts/gen_slice.py —— 勿手改(顶层 glue 为从 Scala 意图的可读重写)

// 18 子模块类型黑盒 stub(空体,所有 output 驱 0)。
// 注:UT/FM 默认用 golden 子模块真定义(-f 闭包);本 stub 仅备快速 elaborate。

module DataStorage(
  input  clock,
  input  reset,
  input  io_en,
  output  io_error,
  input  io_req_valid,
  input  [2:0] io_req_bits_way,
  input  [8:0] io_req_bits_set,
  input  io_req_bits_wen,
  output  [511:0] io_rdata_data,
  input  [511:0] io_wdata_data,
  input  [4:0] boreChildrenBd_bore_array,
  input  boreChildrenBd_bore_all,
  input  boreChildrenBd_bore_req,
  output  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_writeen,
  input  boreChildrenBd_bore_be,
  input  [12:0] boreChildrenBd_bore_addr,
  input  [68:0] boreChildrenBd_bore_indata,
  input  boreChildrenBd_bore_readen,
  input  [12:0] boreChildrenBd_bore_addr_rd,
  output  [68:0] boreChildrenBd_bore_outdata,
  input  sigFromSrams_bore_ram_hold,
  input  sigFromSrams_bore_ram_bypass,
  input  sigFromSrams_bore_ram_bp_clken,
  input  sigFromSrams_bore_ram_aux_clk,
  input  sigFromSrams_bore_ram_aux_ckbp,
  input  sigFromSrams_bore_ram_mcp_hold,
  input  sigFromSrams_bore_cgen,
  input  sigFromSrams_bore_1_ram_hold,
  input  sigFromSrams_bore_1_ram_bypass,
  input  sigFromSrams_bore_1_ram_bp_clken,
  input  sigFromSrams_bore_1_ram_aux_clk,
  input  sigFromSrams_bore_1_ram_aux_ckbp,
  input  sigFromSrams_bore_1_ram_mcp_hold,
  input  sigFromSrams_bore_1_cgen,
  input  sigFromSrams_bore_2_ram_hold,
  input  sigFromSrams_bore_2_ram_bypass,
  input  sigFromSrams_bore_2_ram_bp_clken,
  input  sigFromSrams_bore_2_ram_aux_clk,
  input  sigFromSrams_bore_2_ram_aux_ckbp,
  input  sigFromSrams_bore_2_ram_mcp_hold,
  input  sigFromSrams_bore_2_cgen,
  input  sigFromSrams_bore_3_ram_hold,
  input  sigFromSrams_bore_3_ram_bypass,
  input  sigFromSrams_bore_3_ram_bp_clken,
  input  sigFromSrams_bore_3_ram_aux_clk,
  input  sigFromSrams_bore_3_ram_aux_ckbp,
  input  sigFromSrams_bore_3_ram_mcp_hold,
  input  sigFromSrams_bore_3_cgen,
  input  sigFromSrams_bore_4_ram_hold,
  input  sigFromSrams_bore_4_ram_bypass,
  input  sigFromSrams_bore_4_ram_bp_clken,
  input  sigFromSrams_bore_4_ram_aux_clk,
  input  sigFromSrams_bore_4_ram_aux_ckbp,
  input  sigFromSrams_bore_4_ram_mcp_hold,
  input  sigFromSrams_bore_4_cgen,
  input  sigFromSrams_bore_5_ram_hold,
  input  sigFromSrams_bore_5_ram_bypass,
  input  sigFromSrams_bore_5_ram_bp_clken,
  input  sigFromSrams_bore_5_ram_aux_clk,
  input  sigFromSrams_bore_5_ram_aux_ckbp,
  input  sigFromSrams_bore_5_ram_mcp_hold,
  input  sigFromSrams_bore_5_cgen,
  input  sigFromSrams_bore_6_ram_hold,
  input  sigFromSrams_bore_6_ram_bypass,
  input  sigFromSrams_bore_6_ram_bp_clken,
  input  sigFromSrams_bore_6_ram_aux_clk,
  input  sigFromSrams_bore_6_ram_aux_ckbp,
  input  sigFromSrams_bore_6_ram_mcp_hold,
  input  sigFromSrams_bore_6_cgen,
  input  sigFromSrams_bore_7_ram_hold,
  input  sigFromSrams_bore_7_ram_bypass,
  input  sigFromSrams_bore_7_ram_bp_clken,
  input  sigFromSrams_bore_7_ram_aux_clk,
  input  sigFromSrams_bore_7_ram_aux_ckbp,
  input  sigFromSrams_bore_7_ram_mcp_hold,
  input  sigFromSrams_bore_7_cgen
);
  assign io_error = '0;
  assign io_rdata_data = '0;
  assign boreChildrenBd_bore_ack = '0;
  assign boreChildrenBd_bore_outdata = '0;
endmodule

module Directory(
  input  clock,
  input  reset,
  output  io_read_ready,
  input  io_read_valid,
  input  [30:0] io_read_bits_tag,
  input  [8:0] io_read_bits_set,
  input  [7:0] io_read_bits_wayMask,
  input  [2:0] io_read_bits_replacerInfo_channel,
  input  [2:0] io_read_bits_replacerInfo_opcode,
  input  [4:0] io_read_bits_replacerInfo_reqSource,
  input  io_read_bits_replacerInfo_refill_prefetch,
  input  io_read_bits_refill,
  input  [7:0] io_read_bits_mshrId,
  input  io_read_bits_cmoAll,
  input  [2:0] io_read_bits_cmoWay,
  output  io_resp_valid,
  output  io_resp_bits_hit,
  output  [30:0] io_resp_bits_tag,
  output  [8:0] io_resp_bits_set,
  output  [2:0] io_resp_bits_way,
  output  io_resp_bits_meta_dirty,
  output  [1:0] io_resp_bits_meta_state,
  output  io_resp_bits_meta_clients,
  output  [1:0] io_resp_bits_meta_alias,
  output  io_resp_bits_meta_prefetch,
  output  [2:0] io_resp_bits_meta_prefetchSrc,
  output  io_resp_bits_meta_accessed,
  output  io_resp_bits_meta_tagErr,
  output  io_resp_bits_meta_dataErr,
  output  io_resp_bits_error,
  output  [2:0] io_resp_bits_replacerInfo_channel,
  output  [2:0] io_resp_bits_replacerInfo_opcode,
  output  [4:0] io_resp_bits_replacerInfo_reqSource,
  output  io_resp_bits_replacerInfo_refill_prefetch,
  input  io_metaWReq_valid,
  input  [8:0] io_metaWReq_bits_set,
  input  [7:0] io_metaWReq_bits_wayOH,
  input  io_metaWReq_bits_wmeta_dirty,
  input  [1:0] io_metaWReq_bits_wmeta_state,
  input  io_metaWReq_bits_wmeta_clients,
  input  [1:0] io_metaWReq_bits_wmeta_alias,
  input  io_metaWReq_bits_wmeta_prefetch,
  input  [2:0] io_metaWReq_bits_wmeta_prefetchSrc,
  input  io_metaWReq_bits_wmeta_accessed,
  input  io_metaWReq_bits_wmeta_tagErr,
  input  io_metaWReq_bits_wmeta_dataErr,
  input  io_tagWReq_valid,
  input  [8:0] io_tagWReq_bits_set,
  input  [2:0] io_tagWReq_bits_way,
  input  [30:0] io_tagWReq_bits_wtag,
  output  io_replResp_valid,
  output  [30:0] io_replResp_bits_tag,
  output  [8:0] io_replResp_bits_set,
  output  [2:0] io_replResp_bits_way,
  output  io_replResp_bits_meta_dirty,
  output  [1:0] io_replResp_bits_meta_state,
  output  io_replResp_bits_meta_clients,
  output  [1:0] io_replResp_bits_meta_alias,
  output  io_replResp_bits_meta_prefetch,
  output  [2:0] io_replResp_bits_meta_prefetchSrc,
  output  io_replResp_bits_meta_accessed,
  output  io_replResp_bits_meta_tagErr,
  output  io_replResp_bits_meta_dataErr,
  output  [7:0] io_replResp_bits_mshrId,
  output  io_replResp_bits_retry,
  input  io_msInfo_0_valid,
  input  [2:0] io_msInfo_0_bits_channel,
  input  [8:0] io_msInfo_0_bits_set,
  input  [2:0] io_msInfo_0_bits_way,
  input  [30:0] io_msInfo_0_bits_reqTag,
  input  io_msInfo_0_bits_willFree,
  input  io_msInfo_0_bits_aliasTask,
  input  io_msInfo_0_bits_needRelease,
  input  io_msInfo_0_bits_blockRefill,
  input  io_msInfo_0_bits_meta_dirty,
  input  [1:0] io_msInfo_0_bits_meta_state,
  input  io_msInfo_0_bits_meta_clients,
  input  [1:0] io_msInfo_0_bits_meta_alias,
  input  io_msInfo_0_bits_meta_prefetch,
  input  [2:0] io_msInfo_0_bits_meta_prefetchSrc,
  input  io_msInfo_0_bits_meta_accessed,
  input  io_msInfo_0_bits_meta_tagErr,
  input  io_msInfo_0_bits_meta_dataErr,
  input  [30:0] io_msInfo_0_bits_metaTag,
  input  io_msInfo_0_bits_dirHit,
  input  io_msInfo_0_bits_isAcqOrPrefetch,
  input  io_msInfo_0_bits_isPrefetch,
  input  [2:0] io_msInfo_0_bits_param,
  input  io_msInfo_0_bits_mergeA,
  input  io_msInfo_0_bits_w_grantfirst,
  input  io_msInfo_0_bits_s_release,
  input  io_msInfo_0_bits_s_refill,
  input  io_msInfo_0_bits_s_cmoresp,
  input  io_msInfo_0_bits_s_cmometaw,
  input  io_msInfo_0_bits_w_releaseack,
  input  io_msInfo_0_bits_w_replResp,
  input  io_msInfo_0_bits_w_rprobeacklast,
  input  io_msInfo_0_bits_replaceData,
  input  io_msInfo_0_bits_releaseToClean,
  input  io_msInfo_1_valid,
  input  [2:0] io_msInfo_1_bits_channel,
  input  [8:0] io_msInfo_1_bits_set,
  input  [2:0] io_msInfo_1_bits_way,
  input  [30:0] io_msInfo_1_bits_reqTag,
  input  io_msInfo_1_bits_willFree,
  input  io_msInfo_1_bits_aliasTask,
  input  io_msInfo_1_bits_needRelease,
  input  io_msInfo_1_bits_blockRefill,
  input  io_msInfo_1_bits_meta_dirty,
  input  [1:0] io_msInfo_1_bits_meta_state,
  input  io_msInfo_1_bits_meta_clients,
  input  [1:0] io_msInfo_1_bits_meta_alias,
  input  io_msInfo_1_bits_meta_prefetch,
  input  [2:0] io_msInfo_1_bits_meta_prefetchSrc,
  input  io_msInfo_1_bits_meta_accessed,
  input  io_msInfo_1_bits_meta_tagErr,
  input  io_msInfo_1_bits_meta_dataErr,
  input  [30:0] io_msInfo_1_bits_metaTag,
  input  io_msInfo_1_bits_dirHit,
  input  io_msInfo_1_bits_isAcqOrPrefetch,
  input  io_msInfo_1_bits_isPrefetch,
  input  [2:0] io_msInfo_1_bits_param,
  input  io_msInfo_1_bits_mergeA,
  input  io_msInfo_1_bits_w_grantfirst,
  input  io_msInfo_1_bits_s_release,
  input  io_msInfo_1_bits_s_refill,
  input  io_msInfo_1_bits_s_cmoresp,
  input  io_msInfo_1_bits_s_cmometaw,
  input  io_msInfo_1_bits_w_releaseack,
  input  io_msInfo_1_bits_w_replResp,
  input  io_msInfo_1_bits_w_rprobeacklast,
  input  io_msInfo_1_bits_replaceData,
  input  io_msInfo_1_bits_releaseToClean,
  input  io_msInfo_2_valid,
  input  [2:0] io_msInfo_2_bits_channel,
  input  [8:0] io_msInfo_2_bits_set,
  input  [2:0] io_msInfo_2_bits_way,
  input  [30:0] io_msInfo_2_bits_reqTag,
  input  io_msInfo_2_bits_willFree,
  input  io_msInfo_2_bits_aliasTask,
  input  io_msInfo_2_bits_needRelease,
  input  io_msInfo_2_bits_blockRefill,
  input  io_msInfo_2_bits_meta_dirty,
  input  [1:0] io_msInfo_2_bits_meta_state,
  input  io_msInfo_2_bits_meta_clients,
  input  [1:0] io_msInfo_2_bits_meta_alias,
  input  io_msInfo_2_bits_meta_prefetch,
  input  [2:0] io_msInfo_2_bits_meta_prefetchSrc,
  input  io_msInfo_2_bits_meta_accessed,
  input  io_msInfo_2_bits_meta_tagErr,
  input  io_msInfo_2_bits_meta_dataErr,
  input  [30:0] io_msInfo_2_bits_metaTag,
  input  io_msInfo_2_bits_dirHit,
  input  io_msInfo_2_bits_isAcqOrPrefetch,
  input  io_msInfo_2_bits_isPrefetch,
  input  [2:0] io_msInfo_2_bits_param,
  input  io_msInfo_2_bits_mergeA,
  input  io_msInfo_2_bits_w_grantfirst,
  input  io_msInfo_2_bits_s_release,
  input  io_msInfo_2_bits_s_refill,
  input  io_msInfo_2_bits_s_cmoresp,
  input  io_msInfo_2_bits_s_cmometaw,
  input  io_msInfo_2_bits_w_releaseack,
  input  io_msInfo_2_bits_w_replResp,
  input  io_msInfo_2_bits_w_rprobeacklast,
  input  io_msInfo_2_bits_replaceData,
  input  io_msInfo_2_bits_releaseToClean,
  input  io_msInfo_3_valid,
  input  [2:0] io_msInfo_3_bits_channel,
  input  [8:0] io_msInfo_3_bits_set,
  input  [2:0] io_msInfo_3_bits_way,
  input  [30:0] io_msInfo_3_bits_reqTag,
  input  io_msInfo_3_bits_willFree,
  input  io_msInfo_3_bits_aliasTask,
  input  io_msInfo_3_bits_needRelease,
  input  io_msInfo_3_bits_blockRefill,
  input  io_msInfo_3_bits_meta_dirty,
  input  [1:0] io_msInfo_3_bits_meta_state,
  input  io_msInfo_3_bits_meta_clients,
  input  [1:0] io_msInfo_3_bits_meta_alias,
  input  io_msInfo_3_bits_meta_prefetch,
  input  [2:0] io_msInfo_3_bits_meta_prefetchSrc,
  input  io_msInfo_3_bits_meta_accessed,
  input  io_msInfo_3_bits_meta_tagErr,
  input  io_msInfo_3_bits_meta_dataErr,
  input  [30:0] io_msInfo_3_bits_metaTag,
  input  io_msInfo_3_bits_dirHit,
  input  io_msInfo_3_bits_isAcqOrPrefetch,
  input  io_msInfo_3_bits_isPrefetch,
  input  [2:0] io_msInfo_3_bits_param,
  input  io_msInfo_3_bits_mergeA,
  input  io_msInfo_3_bits_w_grantfirst,
  input  io_msInfo_3_bits_s_release,
  input  io_msInfo_3_bits_s_refill,
  input  io_msInfo_3_bits_s_cmoresp,
  input  io_msInfo_3_bits_s_cmometaw,
  input  io_msInfo_3_bits_w_releaseack,
  input  io_msInfo_3_bits_w_replResp,
  input  io_msInfo_3_bits_w_rprobeacklast,
  input  io_msInfo_3_bits_replaceData,
  input  io_msInfo_3_bits_releaseToClean,
  input  io_msInfo_4_valid,
  input  [2:0] io_msInfo_4_bits_channel,
  input  [8:0] io_msInfo_4_bits_set,
  input  [2:0] io_msInfo_4_bits_way,
  input  [30:0] io_msInfo_4_bits_reqTag,
  input  io_msInfo_4_bits_willFree,
  input  io_msInfo_4_bits_aliasTask,
  input  io_msInfo_4_bits_needRelease,
  input  io_msInfo_4_bits_blockRefill,
  input  io_msInfo_4_bits_meta_dirty,
  input  [1:0] io_msInfo_4_bits_meta_state,
  input  io_msInfo_4_bits_meta_clients,
  input  [1:0] io_msInfo_4_bits_meta_alias,
  input  io_msInfo_4_bits_meta_prefetch,
  input  [2:0] io_msInfo_4_bits_meta_prefetchSrc,
  input  io_msInfo_4_bits_meta_accessed,
  input  io_msInfo_4_bits_meta_tagErr,
  input  io_msInfo_4_bits_meta_dataErr,
  input  [30:0] io_msInfo_4_bits_metaTag,
  input  io_msInfo_4_bits_dirHit,
  input  io_msInfo_4_bits_isAcqOrPrefetch,
  input  io_msInfo_4_bits_isPrefetch,
  input  [2:0] io_msInfo_4_bits_param,
  input  io_msInfo_4_bits_mergeA,
  input  io_msInfo_4_bits_w_grantfirst,
  input  io_msInfo_4_bits_s_release,
  input  io_msInfo_4_bits_s_refill,
  input  io_msInfo_4_bits_s_cmoresp,
  input  io_msInfo_4_bits_s_cmometaw,
  input  io_msInfo_4_bits_w_releaseack,
  input  io_msInfo_4_bits_w_replResp,
  input  io_msInfo_4_bits_w_rprobeacklast,
  input  io_msInfo_4_bits_replaceData,
  input  io_msInfo_4_bits_releaseToClean,
  input  io_msInfo_5_valid,
  input  [2:0] io_msInfo_5_bits_channel,
  input  [8:0] io_msInfo_5_bits_set,
  input  [2:0] io_msInfo_5_bits_way,
  input  [30:0] io_msInfo_5_bits_reqTag,
  input  io_msInfo_5_bits_willFree,
  input  io_msInfo_5_bits_aliasTask,
  input  io_msInfo_5_bits_needRelease,
  input  io_msInfo_5_bits_blockRefill,
  input  io_msInfo_5_bits_meta_dirty,
  input  [1:0] io_msInfo_5_bits_meta_state,
  input  io_msInfo_5_bits_meta_clients,
  input  [1:0] io_msInfo_5_bits_meta_alias,
  input  io_msInfo_5_bits_meta_prefetch,
  input  [2:0] io_msInfo_5_bits_meta_prefetchSrc,
  input  io_msInfo_5_bits_meta_accessed,
  input  io_msInfo_5_bits_meta_tagErr,
  input  io_msInfo_5_bits_meta_dataErr,
  input  [30:0] io_msInfo_5_bits_metaTag,
  input  io_msInfo_5_bits_dirHit,
  input  io_msInfo_5_bits_isAcqOrPrefetch,
  input  io_msInfo_5_bits_isPrefetch,
  input  [2:0] io_msInfo_5_bits_param,
  input  io_msInfo_5_bits_mergeA,
  input  io_msInfo_5_bits_w_grantfirst,
  input  io_msInfo_5_bits_s_release,
  input  io_msInfo_5_bits_s_refill,
  input  io_msInfo_5_bits_s_cmoresp,
  input  io_msInfo_5_bits_s_cmometaw,
  input  io_msInfo_5_bits_w_releaseack,
  input  io_msInfo_5_bits_w_replResp,
  input  io_msInfo_5_bits_w_rprobeacklast,
  input  io_msInfo_5_bits_replaceData,
  input  io_msInfo_5_bits_releaseToClean,
  input  io_msInfo_6_valid,
  input  [2:0] io_msInfo_6_bits_channel,
  input  [8:0] io_msInfo_6_bits_set,
  input  [2:0] io_msInfo_6_bits_way,
  input  [30:0] io_msInfo_6_bits_reqTag,
  input  io_msInfo_6_bits_willFree,
  input  io_msInfo_6_bits_aliasTask,
  input  io_msInfo_6_bits_needRelease,
  input  io_msInfo_6_bits_blockRefill,
  input  io_msInfo_6_bits_meta_dirty,
  input  [1:0] io_msInfo_6_bits_meta_state,
  input  io_msInfo_6_bits_meta_clients,
  input  [1:0] io_msInfo_6_bits_meta_alias,
  input  io_msInfo_6_bits_meta_prefetch,
  input  [2:0] io_msInfo_6_bits_meta_prefetchSrc,
  input  io_msInfo_6_bits_meta_accessed,
  input  io_msInfo_6_bits_meta_tagErr,
  input  io_msInfo_6_bits_meta_dataErr,
  input  [30:0] io_msInfo_6_bits_metaTag,
  input  io_msInfo_6_bits_dirHit,
  input  io_msInfo_6_bits_isAcqOrPrefetch,
  input  io_msInfo_6_bits_isPrefetch,
  input  [2:0] io_msInfo_6_bits_param,
  input  io_msInfo_6_bits_mergeA,
  input  io_msInfo_6_bits_w_grantfirst,
  input  io_msInfo_6_bits_s_release,
  input  io_msInfo_6_bits_s_refill,
  input  io_msInfo_6_bits_s_cmoresp,
  input  io_msInfo_6_bits_s_cmometaw,
  input  io_msInfo_6_bits_w_releaseack,
  input  io_msInfo_6_bits_w_replResp,
  input  io_msInfo_6_bits_w_rprobeacklast,
  input  io_msInfo_6_bits_replaceData,
  input  io_msInfo_6_bits_releaseToClean,
  input  io_msInfo_7_valid,
  input  [2:0] io_msInfo_7_bits_channel,
  input  [8:0] io_msInfo_7_bits_set,
  input  [2:0] io_msInfo_7_bits_way,
  input  [30:0] io_msInfo_7_bits_reqTag,
  input  io_msInfo_7_bits_willFree,
  input  io_msInfo_7_bits_aliasTask,
  input  io_msInfo_7_bits_needRelease,
  input  io_msInfo_7_bits_blockRefill,
  input  io_msInfo_7_bits_meta_dirty,
  input  [1:0] io_msInfo_7_bits_meta_state,
  input  io_msInfo_7_bits_meta_clients,
  input  [1:0] io_msInfo_7_bits_meta_alias,
  input  io_msInfo_7_bits_meta_prefetch,
  input  [2:0] io_msInfo_7_bits_meta_prefetchSrc,
  input  io_msInfo_7_bits_meta_accessed,
  input  io_msInfo_7_bits_meta_tagErr,
  input  io_msInfo_7_bits_meta_dataErr,
  input  [30:0] io_msInfo_7_bits_metaTag,
  input  io_msInfo_7_bits_dirHit,
  input  io_msInfo_7_bits_isAcqOrPrefetch,
  input  io_msInfo_7_bits_isPrefetch,
  input  [2:0] io_msInfo_7_bits_param,
  input  io_msInfo_7_bits_mergeA,
  input  io_msInfo_7_bits_w_grantfirst,
  input  io_msInfo_7_bits_s_release,
  input  io_msInfo_7_bits_s_refill,
  input  io_msInfo_7_bits_s_cmoresp,
  input  io_msInfo_7_bits_s_cmometaw,
  input  io_msInfo_7_bits_w_releaseack,
  input  io_msInfo_7_bits_w_replResp,
  input  io_msInfo_7_bits_w_rprobeacklast,
  input  io_msInfo_7_bits_replaceData,
  input  io_msInfo_7_bits_releaseToClean,
  input  io_msInfo_8_valid,
  input  [2:0] io_msInfo_8_bits_channel,
  input  [8:0] io_msInfo_8_bits_set,
  input  [2:0] io_msInfo_8_bits_way,
  input  [30:0] io_msInfo_8_bits_reqTag,
  input  io_msInfo_8_bits_willFree,
  input  io_msInfo_8_bits_aliasTask,
  input  io_msInfo_8_bits_needRelease,
  input  io_msInfo_8_bits_blockRefill,
  input  io_msInfo_8_bits_meta_dirty,
  input  [1:0] io_msInfo_8_bits_meta_state,
  input  io_msInfo_8_bits_meta_clients,
  input  [1:0] io_msInfo_8_bits_meta_alias,
  input  io_msInfo_8_bits_meta_prefetch,
  input  [2:0] io_msInfo_8_bits_meta_prefetchSrc,
  input  io_msInfo_8_bits_meta_accessed,
  input  io_msInfo_8_bits_meta_tagErr,
  input  io_msInfo_8_bits_meta_dataErr,
  input  [30:0] io_msInfo_8_bits_metaTag,
  input  io_msInfo_8_bits_dirHit,
  input  io_msInfo_8_bits_isAcqOrPrefetch,
  input  io_msInfo_8_bits_isPrefetch,
  input  [2:0] io_msInfo_8_bits_param,
  input  io_msInfo_8_bits_mergeA,
  input  io_msInfo_8_bits_w_grantfirst,
  input  io_msInfo_8_bits_s_release,
  input  io_msInfo_8_bits_s_refill,
  input  io_msInfo_8_bits_s_cmoresp,
  input  io_msInfo_8_bits_s_cmometaw,
  input  io_msInfo_8_bits_w_releaseack,
  input  io_msInfo_8_bits_w_replResp,
  input  io_msInfo_8_bits_w_rprobeacklast,
  input  io_msInfo_8_bits_replaceData,
  input  io_msInfo_8_bits_releaseToClean,
  input  io_msInfo_9_valid,
  input  [2:0] io_msInfo_9_bits_channel,
  input  [8:0] io_msInfo_9_bits_set,
  input  [2:0] io_msInfo_9_bits_way,
  input  [30:0] io_msInfo_9_bits_reqTag,
  input  io_msInfo_9_bits_willFree,
  input  io_msInfo_9_bits_aliasTask,
  input  io_msInfo_9_bits_needRelease,
  input  io_msInfo_9_bits_blockRefill,
  input  io_msInfo_9_bits_meta_dirty,
  input  [1:0] io_msInfo_9_bits_meta_state,
  input  io_msInfo_9_bits_meta_clients,
  input  [1:0] io_msInfo_9_bits_meta_alias,
  input  io_msInfo_9_bits_meta_prefetch,
  input  [2:0] io_msInfo_9_bits_meta_prefetchSrc,
  input  io_msInfo_9_bits_meta_accessed,
  input  io_msInfo_9_bits_meta_tagErr,
  input  io_msInfo_9_bits_meta_dataErr,
  input  [30:0] io_msInfo_9_bits_metaTag,
  input  io_msInfo_9_bits_dirHit,
  input  io_msInfo_9_bits_isAcqOrPrefetch,
  input  io_msInfo_9_bits_isPrefetch,
  input  [2:0] io_msInfo_9_bits_param,
  input  io_msInfo_9_bits_mergeA,
  input  io_msInfo_9_bits_w_grantfirst,
  input  io_msInfo_9_bits_s_release,
  input  io_msInfo_9_bits_s_refill,
  input  io_msInfo_9_bits_s_cmoresp,
  input  io_msInfo_9_bits_s_cmometaw,
  input  io_msInfo_9_bits_w_releaseack,
  input  io_msInfo_9_bits_w_replResp,
  input  io_msInfo_9_bits_w_rprobeacklast,
  input  io_msInfo_9_bits_replaceData,
  input  io_msInfo_9_bits_releaseToClean,
  input  io_msInfo_10_valid,
  input  [2:0] io_msInfo_10_bits_channel,
  input  [8:0] io_msInfo_10_bits_set,
  input  [2:0] io_msInfo_10_bits_way,
  input  [30:0] io_msInfo_10_bits_reqTag,
  input  io_msInfo_10_bits_willFree,
  input  io_msInfo_10_bits_aliasTask,
  input  io_msInfo_10_bits_needRelease,
  input  io_msInfo_10_bits_blockRefill,
  input  io_msInfo_10_bits_meta_dirty,
  input  [1:0] io_msInfo_10_bits_meta_state,
  input  io_msInfo_10_bits_meta_clients,
  input  [1:0] io_msInfo_10_bits_meta_alias,
  input  io_msInfo_10_bits_meta_prefetch,
  input  [2:0] io_msInfo_10_bits_meta_prefetchSrc,
  input  io_msInfo_10_bits_meta_accessed,
  input  io_msInfo_10_bits_meta_tagErr,
  input  io_msInfo_10_bits_meta_dataErr,
  input  [30:0] io_msInfo_10_bits_metaTag,
  input  io_msInfo_10_bits_dirHit,
  input  io_msInfo_10_bits_isAcqOrPrefetch,
  input  io_msInfo_10_bits_isPrefetch,
  input  [2:0] io_msInfo_10_bits_param,
  input  io_msInfo_10_bits_mergeA,
  input  io_msInfo_10_bits_w_grantfirst,
  input  io_msInfo_10_bits_s_release,
  input  io_msInfo_10_bits_s_refill,
  input  io_msInfo_10_bits_s_cmoresp,
  input  io_msInfo_10_bits_s_cmometaw,
  input  io_msInfo_10_bits_w_releaseack,
  input  io_msInfo_10_bits_w_replResp,
  input  io_msInfo_10_bits_w_rprobeacklast,
  input  io_msInfo_10_bits_replaceData,
  input  io_msInfo_10_bits_releaseToClean,
  input  io_msInfo_11_valid,
  input  [2:0] io_msInfo_11_bits_channel,
  input  [8:0] io_msInfo_11_bits_set,
  input  [2:0] io_msInfo_11_bits_way,
  input  [30:0] io_msInfo_11_bits_reqTag,
  input  io_msInfo_11_bits_willFree,
  input  io_msInfo_11_bits_aliasTask,
  input  io_msInfo_11_bits_needRelease,
  input  io_msInfo_11_bits_blockRefill,
  input  io_msInfo_11_bits_meta_dirty,
  input  [1:0] io_msInfo_11_bits_meta_state,
  input  io_msInfo_11_bits_meta_clients,
  input  [1:0] io_msInfo_11_bits_meta_alias,
  input  io_msInfo_11_bits_meta_prefetch,
  input  [2:0] io_msInfo_11_bits_meta_prefetchSrc,
  input  io_msInfo_11_bits_meta_accessed,
  input  io_msInfo_11_bits_meta_tagErr,
  input  io_msInfo_11_bits_meta_dataErr,
  input  [30:0] io_msInfo_11_bits_metaTag,
  input  io_msInfo_11_bits_dirHit,
  input  io_msInfo_11_bits_isAcqOrPrefetch,
  input  io_msInfo_11_bits_isPrefetch,
  input  [2:0] io_msInfo_11_bits_param,
  input  io_msInfo_11_bits_mergeA,
  input  io_msInfo_11_bits_w_grantfirst,
  input  io_msInfo_11_bits_s_release,
  input  io_msInfo_11_bits_s_refill,
  input  io_msInfo_11_bits_s_cmoresp,
  input  io_msInfo_11_bits_s_cmometaw,
  input  io_msInfo_11_bits_w_releaseack,
  input  io_msInfo_11_bits_w_replResp,
  input  io_msInfo_11_bits_w_rprobeacklast,
  input  io_msInfo_11_bits_replaceData,
  input  io_msInfo_11_bits_releaseToClean,
  input  io_msInfo_12_valid,
  input  [2:0] io_msInfo_12_bits_channel,
  input  [8:0] io_msInfo_12_bits_set,
  input  [2:0] io_msInfo_12_bits_way,
  input  [30:0] io_msInfo_12_bits_reqTag,
  input  io_msInfo_12_bits_willFree,
  input  io_msInfo_12_bits_aliasTask,
  input  io_msInfo_12_bits_needRelease,
  input  io_msInfo_12_bits_blockRefill,
  input  io_msInfo_12_bits_meta_dirty,
  input  [1:0] io_msInfo_12_bits_meta_state,
  input  io_msInfo_12_bits_meta_clients,
  input  [1:0] io_msInfo_12_bits_meta_alias,
  input  io_msInfo_12_bits_meta_prefetch,
  input  [2:0] io_msInfo_12_bits_meta_prefetchSrc,
  input  io_msInfo_12_bits_meta_accessed,
  input  io_msInfo_12_bits_meta_tagErr,
  input  io_msInfo_12_bits_meta_dataErr,
  input  [30:0] io_msInfo_12_bits_metaTag,
  input  io_msInfo_12_bits_dirHit,
  input  io_msInfo_12_bits_isAcqOrPrefetch,
  input  io_msInfo_12_bits_isPrefetch,
  input  [2:0] io_msInfo_12_bits_param,
  input  io_msInfo_12_bits_mergeA,
  input  io_msInfo_12_bits_w_grantfirst,
  input  io_msInfo_12_bits_s_release,
  input  io_msInfo_12_bits_s_refill,
  input  io_msInfo_12_bits_s_cmoresp,
  input  io_msInfo_12_bits_s_cmometaw,
  input  io_msInfo_12_bits_w_releaseack,
  input  io_msInfo_12_bits_w_replResp,
  input  io_msInfo_12_bits_w_rprobeacklast,
  input  io_msInfo_12_bits_replaceData,
  input  io_msInfo_12_bits_releaseToClean,
  input  io_msInfo_13_valid,
  input  [2:0] io_msInfo_13_bits_channel,
  input  [8:0] io_msInfo_13_bits_set,
  input  [2:0] io_msInfo_13_bits_way,
  input  [30:0] io_msInfo_13_bits_reqTag,
  input  io_msInfo_13_bits_willFree,
  input  io_msInfo_13_bits_aliasTask,
  input  io_msInfo_13_bits_needRelease,
  input  io_msInfo_13_bits_blockRefill,
  input  io_msInfo_13_bits_meta_dirty,
  input  [1:0] io_msInfo_13_bits_meta_state,
  input  io_msInfo_13_bits_meta_clients,
  input  [1:0] io_msInfo_13_bits_meta_alias,
  input  io_msInfo_13_bits_meta_prefetch,
  input  [2:0] io_msInfo_13_bits_meta_prefetchSrc,
  input  io_msInfo_13_bits_meta_accessed,
  input  io_msInfo_13_bits_meta_tagErr,
  input  io_msInfo_13_bits_meta_dataErr,
  input  [30:0] io_msInfo_13_bits_metaTag,
  input  io_msInfo_13_bits_dirHit,
  input  io_msInfo_13_bits_isAcqOrPrefetch,
  input  io_msInfo_13_bits_isPrefetch,
  input  [2:0] io_msInfo_13_bits_param,
  input  io_msInfo_13_bits_mergeA,
  input  io_msInfo_13_bits_w_grantfirst,
  input  io_msInfo_13_bits_s_release,
  input  io_msInfo_13_bits_s_refill,
  input  io_msInfo_13_bits_s_cmoresp,
  input  io_msInfo_13_bits_s_cmometaw,
  input  io_msInfo_13_bits_w_releaseack,
  input  io_msInfo_13_bits_w_replResp,
  input  io_msInfo_13_bits_w_rprobeacklast,
  input  io_msInfo_13_bits_replaceData,
  input  io_msInfo_13_bits_releaseToClean,
  input  io_msInfo_14_valid,
  input  [2:0] io_msInfo_14_bits_channel,
  input  [8:0] io_msInfo_14_bits_set,
  input  [2:0] io_msInfo_14_bits_way,
  input  [30:0] io_msInfo_14_bits_reqTag,
  input  io_msInfo_14_bits_willFree,
  input  io_msInfo_14_bits_aliasTask,
  input  io_msInfo_14_bits_needRelease,
  input  io_msInfo_14_bits_blockRefill,
  input  io_msInfo_14_bits_meta_dirty,
  input  [1:0] io_msInfo_14_bits_meta_state,
  input  io_msInfo_14_bits_meta_clients,
  input  [1:0] io_msInfo_14_bits_meta_alias,
  input  io_msInfo_14_bits_meta_prefetch,
  input  [2:0] io_msInfo_14_bits_meta_prefetchSrc,
  input  io_msInfo_14_bits_meta_accessed,
  input  io_msInfo_14_bits_meta_tagErr,
  input  io_msInfo_14_bits_meta_dataErr,
  input  [30:0] io_msInfo_14_bits_metaTag,
  input  io_msInfo_14_bits_dirHit,
  input  io_msInfo_14_bits_isAcqOrPrefetch,
  input  io_msInfo_14_bits_isPrefetch,
  input  [2:0] io_msInfo_14_bits_param,
  input  io_msInfo_14_bits_mergeA,
  input  io_msInfo_14_bits_w_grantfirst,
  input  io_msInfo_14_bits_s_release,
  input  io_msInfo_14_bits_s_refill,
  input  io_msInfo_14_bits_s_cmoresp,
  input  io_msInfo_14_bits_s_cmometaw,
  input  io_msInfo_14_bits_w_releaseack,
  input  io_msInfo_14_bits_w_replResp,
  input  io_msInfo_14_bits_w_rprobeacklast,
  input  io_msInfo_14_bits_replaceData,
  input  io_msInfo_14_bits_releaseToClean,
  input  io_msInfo_15_valid,
  input  [2:0] io_msInfo_15_bits_channel,
  input  [8:0] io_msInfo_15_bits_set,
  input  [2:0] io_msInfo_15_bits_way,
  input  [30:0] io_msInfo_15_bits_reqTag,
  input  io_msInfo_15_bits_willFree,
  input  io_msInfo_15_bits_aliasTask,
  input  io_msInfo_15_bits_needRelease,
  input  io_msInfo_15_bits_blockRefill,
  input  io_msInfo_15_bits_meta_dirty,
  input  [1:0] io_msInfo_15_bits_meta_state,
  input  io_msInfo_15_bits_meta_clients,
  input  [1:0] io_msInfo_15_bits_meta_alias,
  input  io_msInfo_15_bits_meta_prefetch,
  input  [2:0] io_msInfo_15_bits_meta_prefetchSrc,
  input  io_msInfo_15_bits_meta_accessed,
  input  io_msInfo_15_bits_meta_tagErr,
  input  io_msInfo_15_bits_meta_dataErr,
  input  [30:0] io_msInfo_15_bits_metaTag,
  input  io_msInfo_15_bits_dirHit,
  input  io_msInfo_15_bits_isAcqOrPrefetch,
  input  io_msInfo_15_bits_isPrefetch,
  input  [2:0] io_msInfo_15_bits_param,
  input  io_msInfo_15_bits_mergeA,
  input  io_msInfo_15_bits_w_grantfirst,
  input  io_msInfo_15_bits_s_release,
  input  io_msInfo_15_bits_s_refill,
  input  io_msInfo_15_bits_s_cmoresp,
  input  io_msInfo_15_bits_s_cmometaw,
  input  io_msInfo_15_bits_w_releaseack,
  input  io_msInfo_15_bits_w_replResp,
  input  io_msInfo_15_bits_w_rprobeacklast,
  input  io_msInfo_15_bits_replaceData,
  input  io_msInfo_15_bits_releaseToClean,
  input  [3:0] boreChildrenBd_bore_array,
  input  boreChildrenBd_bore_all,
  input  boreChildrenBd_bore_req,
  output  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_writeen,
  input  [7:0] boreChildrenBd_bore_be,
  input  [9:0] boreChildrenBd_bore_addr,
  input  [103:0] boreChildrenBd_bore_indata,
  input  boreChildrenBd_bore_readen,
  input  [9:0] boreChildrenBd_bore_addr_rd,
  output  [103:0] boreChildrenBd_bore_outdata,
  input  sigFromSrams_bore_ram_hold,
  input  sigFromSrams_bore_ram_bypass,
  input  sigFromSrams_bore_ram_bp_clken,
  input  sigFromSrams_bore_ram_aux_clk,
  input  sigFromSrams_bore_ram_aux_ckbp,
  input  sigFromSrams_bore_ram_mcp_hold,
  input  sigFromSrams_bore_cgen,
  input  sigFromSrams_bore_1_ram_hold,
  input  sigFromSrams_bore_1_ram_bypass,
  input  sigFromSrams_bore_1_ram_bp_clken,
  input  sigFromSrams_bore_1_ram_aux_clk,
  input  sigFromSrams_bore_1_ram_aux_ckbp,
  input  sigFromSrams_bore_1_ram_mcp_hold,
  input  sigFromSrams_bore_1_cgen,
  input  sigFromSrams_bore_2_ram_hold,
  input  sigFromSrams_bore_2_ram_bypass,
  input  sigFromSrams_bore_2_ram_bp_clken,
  input  sigFromSrams_bore_2_ram_aux_clk,
  input  sigFromSrams_bore_2_ram_aux_ckbp,
  input  sigFromSrams_bore_2_ram_mcp_hold,
  input  sigFromSrams_bore_2_cgen,
  input  sigFromSrams_bore_3_ram_hold,
  input  sigFromSrams_bore_3_ram_bypass,
  input  sigFromSrams_bore_3_ram_bp_clken,
  input  sigFromSrams_bore_3_ram_aux_clk,
  input  sigFromSrams_bore_3_ram_aux_ckbp,
  input  sigFromSrams_bore_3_ram_mcp_hold,
  input  sigFromSrams_bore_3_cgen,
  input  sigFromSrams_bore_4_ram_hold,
  input  sigFromSrams_bore_4_ram_bypass,
  input  sigFromSrams_bore_4_ram_bp_clken,
  input  sigFromSrams_bore_4_ram_aux_clk,
  input  sigFromSrams_bore_4_ram_aux_ckbp,
  input  sigFromSrams_bore_4_ram_mcp_hold,
  input  sigFromSrams_bore_4_cgen,
  input  sigFromSrams_bore_5_ram_hold,
  input  sigFromSrams_bore_5_ram_bypass,
  input  sigFromSrams_bore_5_ram_bp_clken,
  input  sigFromSrams_bore_5_ram_aux_clk,
  input  sigFromSrams_bore_5_ram_aux_ckbp,
  input  sigFromSrams_bore_5_ram_mcp_hold,
  input  sigFromSrams_bore_5_cgen,
  input  sigFromSrams_bore_6_ram_hold,
  input  sigFromSrams_bore_6_ram_bypass,
  input  sigFromSrams_bore_6_ram_bp_clken,
  input  sigFromSrams_bore_6_ram_aux_clk,
  input  sigFromSrams_bore_6_ram_aux_ckbp,
  input  sigFromSrams_bore_6_ram_mcp_hold,
  input  sigFromSrams_bore_6_cgen
);
  assign io_read_ready = '0;
  assign io_resp_valid = '0;
  assign io_resp_bits_hit = '0;
  assign io_resp_bits_tag = '0;
  assign io_resp_bits_set = '0;
  assign io_resp_bits_way = '0;
  assign io_resp_bits_meta_dirty = '0;
  assign io_resp_bits_meta_state = '0;
  assign io_resp_bits_meta_clients = '0;
  assign io_resp_bits_meta_alias = '0;
  assign io_resp_bits_meta_prefetch = '0;
  assign io_resp_bits_meta_prefetchSrc = '0;
  assign io_resp_bits_meta_accessed = '0;
  assign io_resp_bits_meta_tagErr = '0;
  assign io_resp_bits_meta_dataErr = '0;
  assign io_resp_bits_error = '0;
  assign io_resp_bits_replacerInfo_channel = '0;
  assign io_resp_bits_replacerInfo_opcode = '0;
  assign io_resp_bits_replacerInfo_reqSource = '0;
  assign io_resp_bits_replacerInfo_refill_prefetch = '0;
  assign io_replResp_valid = '0;
  assign io_replResp_bits_tag = '0;
  assign io_replResp_bits_set = '0;
  assign io_replResp_bits_way = '0;
  assign io_replResp_bits_meta_dirty = '0;
  assign io_replResp_bits_meta_state = '0;
  assign io_replResp_bits_meta_clients = '0;
  assign io_replResp_bits_meta_alias = '0;
  assign io_replResp_bits_meta_prefetch = '0;
  assign io_replResp_bits_meta_prefetchSrc = '0;
  assign io_replResp_bits_meta_accessed = '0;
  assign io_replResp_bits_meta_tagErr = '0;
  assign io_replResp_bits_meta_dataErr = '0;
  assign io_replResp_bits_mshrId = '0;
  assign io_replResp_bits_retry = '0;
  assign boreChildrenBd_bore_ack = '0;
  assign boreChildrenBd_bore_outdata = '0;
endmodule

module GrantBuffer(
  input  clock,
  input  reset,
  input  io_d_task_valid,
  input  [2:0] io_d_task_bits_task_channel,
  input  [2:0] io_d_task_bits_task_txChannel,
  input  [8:0] io_d_task_bits_task_set,
  input  [30:0] io_d_task_bits_task_tag,
  input  [5:0] io_d_task_bits_task_off,
  input  [1:0] io_d_task_bits_task_alias,
  input  [43:0] io_d_task_bits_task_vaddr,
  input  io_d_task_bits_task_isKeyword,
  input  [3:0] io_d_task_bits_task_opcode,
  input  [2:0] io_d_task_bits_task_param,
  input  [2:0] io_d_task_bits_task_size,
  input  [6:0] io_d_task_bits_task_sourceId,
  input  [1:0] io_d_task_bits_task_bufIdx,
  input  io_d_task_bits_task_needProbeAckData,
  input  io_d_task_bits_task_denied,
  input  io_d_task_bits_task_corrupt,
  input  io_d_task_bits_task_mshrTask,
  input  [7:0] io_d_task_bits_task_mshrId,
  input  io_d_task_bits_task_aliasTask,
  input  io_d_task_bits_task_useProbeData,
  input  io_d_task_bits_task_mshrRetry,
  input  io_d_task_bits_task_readProbeDataDown,
  input  io_d_task_bits_task_fromL2pft,
  input  io_d_task_bits_task_needHint,
  input  io_d_task_bits_task_dirty,
  input  [2:0] io_d_task_bits_task_way,
  input  io_d_task_bits_task_meta_dirty,
  input  [1:0] io_d_task_bits_task_meta_state,
  input  io_d_task_bits_task_meta_clients,
  input  [1:0] io_d_task_bits_task_meta_alias,
  input  io_d_task_bits_task_meta_prefetch,
  input  [2:0] io_d_task_bits_task_meta_prefetchSrc,
  input  io_d_task_bits_task_meta_accessed,
  input  io_d_task_bits_task_meta_tagErr,
  input  io_d_task_bits_task_meta_dataErr,
  input  io_d_task_bits_task_metaWen,
  input  io_d_task_bits_task_tagWen,
  input  io_d_task_bits_task_dsWen,
  input  [7:0] io_d_task_bits_task_wayMask,
  input  io_d_task_bits_task_replTask,
  input  io_d_task_bits_task_cmoTask,
  input  io_d_task_bits_task_cmoAll,
  input  [4:0] io_d_task_bits_task_reqSource,
  input  io_d_task_bits_task_mergeA,
  input  [5:0] io_d_task_bits_task_aMergeTask_off,
  input  [1:0] io_d_task_bits_task_aMergeTask_alias,
  input  [43:0] io_d_task_bits_task_aMergeTask_vaddr,
  input  io_d_task_bits_task_aMergeTask_isKeyword,
  input  [2:0] io_d_task_bits_task_aMergeTask_opcode,
  input  [2:0] io_d_task_bits_task_aMergeTask_param,
  input  [6:0] io_d_task_bits_task_aMergeTask_sourceId,
  input  io_d_task_bits_task_aMergeTask_meta_dirty,
  input  [1:0] io_d_task_bits_task_aMergeTask_meta_state,
  input  io_d_task_bits_task_aMergeTask_meta_clients,
  input  [1:0] io_d_task_bits_task_aMergeTask_meta_alias,
  input  io_d_task_bits_task_aMergeTask_meta_prefetch,
  input  [2:0] io_d_task_bits_task_aMergeTask_meta_prefetchSrc,
  input  io_d_task_bits_task_aMergeTask_meta_accessed,
  input  io_d_task_bits_task_aMergeTask_meta_tagErr,
  input  io_d_task_bits_task_aMergeTask_meta_dataErr,
  input  io_d_task_bits_task_snpHitRelease,
  input  io_d_task_bits_task_snpHitReleaseToInval,
  input  io_d_task_bits_task_snpHitReleaseToClean,
  input  io_d_task_bits_task_snpHitReleaseWithData,
  input  [7:0] io_d_task_bits_task_snpHitReleaseIdx,
  input  io_d_task_bits_task_snpHitReleaseMeta_dirty,
  input  [1:0] io_d_task_bits_task_snpHitReleaseMeta_state,
  input  io_d_task_bits_task_snpHitReleaseMeta_clients,
  input  [1:0] io_d_task_bits_task_snpHitReleaseMeta_alias,
  input  io_d_task_bits_task_snpHitReleaseMeta_prefetch,
  input  [2:0] io_d_task_bits_task_snpHitReleaseMeta_prefetchSrc,
  input  io_d_task_bits_task_snpHitReleaseMeta_accessed,
  input  io_d_task_bits_task_snpHitReleaseMeta_tagErr,
  input  io_d_task_bits_task_snpHitReleaseMeta_dataErr,
  input  [10:0] io_d_task_bits_task_tgtID,
  input  [10:0] io_d_task_bits_task_srcID,
  input  [11:0] io_d_task_bits_task_txnID,
  input  [10:0] io_d_task_bits_task_homeNID,
  input  [11:0] io_d_task_bits_task_dbID,
  input  [10:0] io_d_task_bits_task_fwdNID,
  input  [11:0] io_d_task_bits_task_fwdTxnID,
  input  [6:0] io_d_task_bits_task_chiOpcode,
  input  [2:0] io_d_task_bits_task_resp,
  input  [2:0] io_d_task_bits_task_fwdState,
  input  [3:0] io_d_task_bits_task_pCrdType,
  input  io_d_task_bits_task_retToSrc,
  input  io_d_task_bits_task_likelyshared,
  input  io_d_task_bits_task_expCompAck,
  input  io_d_task_bits_task_allowRetry,
  input  io_d_task_bits_task_memAttr_allocate,
  input  io_d_task_bits_task_memAttr_cacheable,
  input  io_d_task_bits_task_memAttr_device,
  input  io_d_task_bits_task_memAttr_ewa,
  input  io_d_task_bits_task_traceTag,
  input  io_d_task_bits_task_dataCheckErr,
  input  [511:0] io_d_task_bits_data_data,
  input  io_d_ready,
  output  io_d_valid,
  output  [3:0] io_d_bits_opcode,
  output  [1:0] io_d_bits_param,
  output  [6:0] io_d_bits_source,
  output  [7:0] io_d_bits_sink,
  output  io_d_bits_denied,
  output  io_d_bits_echo_isKeyword,
  output  [255:0] io_d_bits_data,
  output  io_d_bits_corrupt,
  input  io_e_valid,
  input  [7:0] io_e_bits_sink,
  input  [30:0] io_fromReqArb_status_s1_tags_1,
  input  [8:0] io_fromReqArb_status_s1_sets_1,
  input  io_pipeStatusVec_1_valid,
  input  [2:0] io_pipeStatusVec_1_bits_channel,
  input  io_pipeStatusVec_2_valid,
  input  [2:0] io_pipeStatusVec_2_bits_channel,
  input  io_pipeStatusVec_3_valid,
  input  [2:0] io_pipeStatusVec_3_bits_channel,
  input  io_pipeStatusVec_4_valid,
  input  [2:0] io_pipeStatusVec_4_bits_channel,
  output  io_toReqArb_blockSinkReqEntrance_blockA_s1,
  output  io_toReqArb_blockSinkReqEntrance_blockB_s1,
  output  io_toReqArb_blockSinkReqEntrance_blockC_s1,
  output  io_toReqArb_blockMSHRReqEntrance,
  input  io_prefetchResp_ready,
  output  io_prefetchResp_valid,
  output  [32:0] io_prefetchResp_bits_tag,
  output  [8:0] io_prefetchResp_bits_set,
  output  [43:0] io_prefetchResp_bits_vaddr,
  output  [4:0] io_prefetchResp_bits_pfSource,
  output  io_grantStatus_0_valid,
  output  [8:0] io_grantStatus_0_set,
  output  [30:0] io_grantStatus_0_tag,
  output  io_grantStatus_1_valid,
  output  [8:0] io_grantStatus_1_set,
  output  [30:0] io_grantStatus_1_tag,
  output  io_grantStatus_2_valid,
  output  [8:0] io_grantStatus_2_set,
  output  [30:0] io_grantStatus_2_tag,
  output  io_grantStatus_3_valid,
  output  [8:0] io_grantStatus_3_set,
  output  [30:0] io_grantStatus_3_tag,
  output  io_grantStatus_4_valid,
  output  [8:0] io_grantStatus_4_set,
  output  [30:0] io_grantStatus_4_tag,
  output  io_grantStatus_5_valid,
  output  [8:0] io_grantStatus_5_set,
  output  [30:0] io_grantStatus_5_tag,
  output  io_grantStatus_6_valid,
  output  [8:0] io_grantStatus_6_set,
  output  [30:0] io_grantStatus_6_tag,
  output  io_grantStatus_7_valid,
  output  [8:0] io_grantStatus_7_set,
  output  [30:0] io_grantStatus_7_tag,
  output  io_grantStatus_8_valid,
  output  [8:0] io_grantStatus_8_set,
  output  [30:0] io_grantStatus_8_tag,
  output  io_grantStatus_9_valid,
  output  [8:0] io_grantStatus_9_set,
  output  [30:0] io_grantStatus_9_tag,
  output  io_grantStatus_10_valid,
  output  [8:0] io_grantStatus_10_set,
  output  [30:0] io_grantStatus_10_tag,
  output  io_grantStatus_11_valid,
  output  [8:0] io_grantStatus_11_set,
  output  [30:0] io_grantStatus_11_tag,
  output  io_grantStatus_12_valid,
  output  [8:0] io_grantStatus_12_set,
  output  [30:0] io_grantStatus_12_tag,
  output  io_grantStatus_13_valid,
  output  [8:0] io_grantStatus_13_set,
  output  [30:0] io_grantStatus_13_tag,
  output  io_grantStatus_14_valid,
  output  [8:0] io_grantStatus_14_set,
  output  [30:0] io_grantStatus_14_tag,
  output  io_grantStatus_15_valid,
  output  [8:0] io_grantStatus_15_set,
  output  [30:0] io_grantStatus_15_tag
);
  assign io_d_valid = '0;
  assign io_d_bits_opcode = '0;
  assign io_d_bits_param = '0;
  assign io_d_bits_source = '0;
  assign io_d_bits_sink = '0;
  assign io_d_bits_denied = '0;
  assign io_d_bits_echo_isKeyword = '0;
  assign io_d_bits_data = '0;
  assign io_d_bits_corrupt = '0;
  assign io_toReqArb_blockSinkReqEntrance_blockA_s1 = '0;
  assign io_toReqArb_blockSinkReqEntrance_blockB_s1 = '0;
  assign io_toReqArb_blockSinkReqEntrance_blockC_s1 = '0;
  assign io_toReqArb_blockMSHRReqEntrance = '0;
  assign io_prefetchResp_valid = '0;
  assign io_prefetchResp_bits_tag = '0;
  assign io_prefetchResp_bits_set = '0;
  assign io_prefetchResp_bits_vaddr = '0;
  assign io_prefetchResp_bits_pfSource = '0;
  assign io_grantStatus_0_valid = '0;
  assign io_grantStatus_0_set = '0;
  assign io_grantStatus_0_tag = '0;
  assign io_grantStatus_1_valid = '0;
  assign io_grantStatus_1_set = '0;
  assign io_grantStatus_1_tag = '0;
  assign io_grantStatus_2_valid = '0;
  assign io_grantStatus_2_set = '0;
  assign io_grantStatus_2_tag = '0;
  assign io_grantStatus_3_valid = '0;
  assign io_grantStatus_3_set = '0;
  assign io_grantStatus_3_tag = '0;
  assign io_grantStatus_4_valid = '0;
  assign io_grantStatus_4_set = '0;
  assign io_grantStatus_4_tag = '0;
  assign io_grantStatus_5_valid = '0;
  assign io_grantStatus_5_set = '0;
  assign io_grantStatus_5_tag = '0;
  assign io_grantStatus_6_valid = '0;
  assign io_grantStatus_6_set = '0;
  assign io_grantStatus_6_tag = '0;
  assign io_grantStatus_7_valid = '0;
  assign io_grantStatus_7_set = '0;
  assign io_grantStatus_7_tag = '0;
  assign io_grantStatus_8_valid = '0;
  assign io_grantStatus_8_set = '0;
  assign io_grantStatus_8_tag = '0;
  assign io_grantStatus_9_valid = '0;
  assign io_grantStatus_9_set = '0;
  assign io_grantStatus_9_tag = '0;
  assign io_grantStatus_10_valid = '0;
  assign io_grantStatus_10_set = '0;
  assign io_grantStatus_10_tag = '0;
  assign io_grantStatus_11_valid = '0;
  assign io_grantStatus_11_set = '0;
  assign io_grantStatus_11_tag = '0;
  assign io_grantStatus_12_valid = '0;
  assign io_grantStatus_12_set = '0;
  assign io_grantStatus_12_tag = '0;
  assign io_grantStatus_13_valid = '0;
  assign io_grantStatus_13_set = '0;
  assign io_grantStatus_13_tag = '0;
  assign io_grantStatus_14_valid = '0;
  assign io_grantStatus_14_set = '0;
  assign io_grantStatus_14_tag = '0;
  assign io_grantStatus_15_valid = '0;
  assign io_grantStatus_15_set = '0;
  assign io_grantStatus_15_tag = '0;
endmodule

module L2Slice(
  input  clock,
  input  reset,
  input  [4:0] mbist_array,
  input  mbist_all,
  input  mbist_req,
  output  mbist_ack,
  input  mbist_writeen,
  input  [7:0] mbist_be,
  input  [12:0] mbist_addr,
  input  [103:0] mbist_indata,
  input  mbist_readen,
  input  [12:0] mbist_addr_rd,
  output  [103:0] mbist_outdata,
  output  [3:0] toNextPipeline_0_array,
  output  toNextPipeline_0_all,
  output  toNextPipeline_0_req,
  input  toNextPipeline_0_ack,
  output  toNextPipeline_0_writeen,
  output  [7:0] toNextPipeline_0_be,
  output  [9:0] toNextPipeline_0_addr,
  output  [103:0] toNextPipeline_0_indata,
  output  toNextPipeline_0_readen,
  output  [9:0] toNextPipeline_0_addr_rd,
  input  [103:0] toNextPipeline_0_outdata,
  output  [4:0] toNextPipeline_1_array,
  output  toNextPipeline_1_all,
  output  toNextPipeline_1_req,
  input  toNextPipeline_1_ack,
  output  toNextPipeline_1_writeen,
  output  toNextPipeline_1_be,
  output  [12:0] toNextPipeline_1_addr,
  output  [68:0] toNextPipeline_1_indata,
  output  toNextPipeline_1_readen,
  output  [12:0] toNextPipeline_1_addr_rd,
  input  [68:0] toNextPipeline_1_outdata
);
  assign mbist_ack = '0;
  assign mbist_outdata = '0;
  assign toNextPipeline_0_array = '0;
  assign toNextPipeline_0_all = '0;
  assign toNextPipeline_0_req = '0;
  assign toNextPipeline_0_writeen = '0;
  assign toNextPipeline_0_be = '0;
  assign toNextPipeline_0_addr = '0;
  assign toNextPipeline_0_indata = '0;
  assign toNextPipeline_0_readen = '0;
  assign toNextPipeline_0_addr_rd = '0;
  assign toNextPipeline_1_array = '0;
  assign toNextPipeline_1_all = '0;
  assign toNextPipeline_1_req = '0;
  assign toNextPipeline_1_writeen = '0;
  assign toNextPipeline_1_be = '0;
  assign toNextPipeline_1_addr = '0;
  assign toNextPipeline_1_indata = '0;
  assign toNextPipeline_1_readen = '0;
  assign toNextPipeline_1_addr_rd = '0;
endmodule

module MSHRBuffer(
  input  clock,
  input  reset,
  input  io_r_valid,
  input  [7:0] io_r_bits_id,
  output  [511:0] io_resp_data_data,
  input  io_w_0_valid,
  input  [7:0] io_w_0_bits_id,
  input  [511:0] io_w_0_bits_data_data,
  input  [1:0] io_w_0_bits_beatMask,
  input  io_w_1_valid,
  input  [7:0] io_w_1_bits_id,
  input  [511:0] io_w_1_bits_data_data
);
  assign io_resp_data_data = '0;
endmodule

module MSHRBuffer_1(
  input  clock,
  input  reset,
  input  io_r_valid,
  input  [7:0] io_r_bits_id,
  output  [511:0] io_resp_data_data,
  input  io_w_0_valid,
  input  [7:0] io_w_0_bits_id,
  input  [511:0] io_w_0_bits_data_data,
  input  io_w_1_valid,
  input  [7:0] io_w_1_bits_id,
  input  [511:0] io_w_1_bits_data_data,
  input  io_w_2_valid,
  input  [7:0] io_w_2_bits_id,
  input  [511:0] io_w_2_bits_data_data
);
  assign io_resp_data_data = '0;
endmodule

module MSHRCtl(
  input  clock,
  input  reset,
  output  io_toReqArb_blockA_s1,
  output  io_toReqArb_blockB_s1,
  input  io_fromMainPipe_mshr_alloc_s3_valid,
  input  io_fromMainPipe_mshr_alloc_s3_bits_dirResult_hit,
  input  [30:0] io_fromMainPipe_mshr_alloc_s3_bits_dirResult_tag,
  input  [8:0] io_fromMainPipe_mshr_alloc_s3_bits_dirResult_set,
  input  [2:0] io_fromMainPipe_mshr_alloc_s3_bits_dirResult_way,
  input  io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dirty,
  input  [1:0] io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_state,
  input  io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_clients,
  input  [1:0] io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_alias,
  input  io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetch,
  input  [2:0] io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc,
  input  io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_accessed,
  input  io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_tagErr,
  input  io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dataErr,
  input  io_fromMainPipe_mshr_alloc_s3_bits_dirResult_error,
  input  io_fromMainPipe_mshr_alloc_s3_bits_state_s_acquire,
  input  io_fromMainPipe_mshr_alloc_s3_bits_state_s_rprobe,
  input  io_fromMainPipe_mshr_alloc_s3_bits_state_s_pprobe,
  input  io_fromMainPipe_mshr_alloc_s3_bits_state_s_release,
  input  io_fromMainPipe_mshr_alloc_s3_bits_state_s_probeack,
  input  io_fromMainPipe_mshr_alloc_s3_bits_state_s_refill,
  input  io_fromMainPipe_mshr_alloc_s3_bits_state_s_cmoresp,
  input  io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeackfirst,
  input  io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeacklast,
  input  io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeackfirst,
  input  io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeacklast,
  input  io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantfirst,
  input  io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantlast,
  input  io_fromMainPipe_mshr_alloc_s3_bits_state_w_grant,
  input  io_fromMainPipe_mshr_alloc_s3_bits_state_w_releaseack,
  input  io_fromMainPipe_mshr_alloc_s3_bits_state_w_replResp,
  input  io_fromMainPipe_mshr_alloc_s3_bits_state_s_rcompack,
  input  io_fromMainPipe_mshr_alloc_s3_bits_state_s_dct,
  input  [2:0] io_fromMainPipe_mshr_alloc_s3_bits_task_channel,
  input  [8:0] io_fromMainPipe_mshr_alloc_s3_bits_task_set,
  input  [30:0] io_fromMainPipe_mshr_alloc_s3_bits_task_tag,
  input  [5:0] io_fromMainPipe_mshr_alloc_s3_bits_task_off,
  input  [1:0] io_fromMainPipe_mshr_alloc_s3_bits_task_alias,
  input  io_fromMainPipe_mshr_alloc_s3_bits_task_isKeyword,
  input  [3:0] io_fromMainPipe_mshr_alloc_s3_bits_task_opcode,
  input  [2:0] io_fromMainPipe_mshr_alloc_s3_bits_task_param,
  input  [6:0] io_fromMainPipe_mshr_alloc_s3_bits_task_sourceId,
  input  io_fromMainPipe_mshr_alloc_s3_bits_task_aliasTask,
  input  io_fromMainPipe_mshr_alloc_s3_bits_task_fromL2pft,
  input  [4:0] io_fromMainPipe_mshr_alloc_s3_bits_task_reqSource,
  input  io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitRelease,
  input  io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToInval,
  input  io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToClean,
  input  io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseWithData,
  input  [7:0] io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseIdx,
  input  io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty,
  input  [1:0] io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state,
  input  io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients,
  input  [1:0] io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias,
  input  io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch,
  input  [2:0] io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc,
  input  io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed,
  input  io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr,
  input  io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr,
  input  [10:0] io_fromMainPipe_mshr_alloc_s3_bits_task_srcID,
  input  [11:0] io_fromMainPipe_mshr_alloc_s3_bits_task_txnID,
  input  [10:0] io_fromMainPipe_mshr_alloc_s3_bits_task_fwdNID,
  input  [11:0] io_fromMainPipe_mshr_alloc_s3_bits_task_fwdTxnID,
  input  [6:0] io_fromMainPipe_mshr_alloc_s3_bits_task_chiOpcode,
  input  io_fromMainPipe_mshr_alloc_s3_bits_task_retToSrc,
  input  io_fromMainPipe_mshr_alloc_s3_bits_task_traceTag,
  output  [7:0] io_toMainPipe_mshr_alloc_ptr,
  input  io_mshrTask_ready,
  output  io_mshrTask_valid,
  output  [2:0] io_mshrTask_bits_channel,
  output  [2:0] io_mshrTask_bits_txChannel,
  output  [8:0] io_mshrTask_bits_set,
  output  [30:0] io_mshrTask_bits_tag,
  output  [5:0] io_mshrTask_bits_off,
  output  [1:0] io_mshrTask_bits_alias,
  output  io_mshrTask_bits_isKeyword,
  output  [3:0] io_mshrTask_bits_opcode,
  output  [2:0] io_mshrTask_bits_param,
  output  [2:0] io_mshrTask_bits_size,
  output  [6:0] io_mshrTask_bits_sourceId,
  output  io_mshrTask_bits_denied,
  output  io_mshrTask_bits_corrupt,
  output  io_mshrTask_bits_mshrTask,
  output  [7:0] io_mshrTask_bits_mshrId,
  output  io_mshrTask_bits_aliasTask,
  output  io_mshrTask_bits_useProbeData,
  output  io_mshrTask_bits_mshrRetry,
  output  io_mshrTask_bits_readProbeDataDown,
  output  io_mshrTask_bits_fromL2pft,
  output  io_mshrTask_bits_dirty,
  output  [2:0] io_mshrTask_bits_way,
  output  io_mshrTask_bits_meta_dirty,
  output  [1:0] io_mshrTask_bits_meta_state,
  output  io_mshrTask_bits_meta_clients,
  output  [1:0] io_mshrTask_bits_meta_alias,
  output  io_mshrTask_bits_meta_prefetch,
  output  [2:0] io_mshrTask_bits_meta_prefetchSrc,
  output  io_mshrTask_bits_meta_accessed,
  output  io_mshrTask_bits_meta_tagErr,
  output  io_mshrTask_bits_meta_dataErr,
  output  io_mshrTask_bits_metaWen,
  output  io_mshrTask_bits_tagWen,
  output  io_mshrTask_bits_dsWen,
  output  io_mshrTask_bits_replTask,
  output  io_mshrTask_bits_cmoTask,
  output  [4:0] io_mshrTask_bits_reqSource,
  output  io_mshrTask_bits_mergeA,
  output  [5:0] io_mshrTask_bits_aMergeTask_off,
  output  [1:0] io_mshrTask_bits_aMergeTask_alias,
  output  [43:0] io_mshrTask_bits_aMergeTask_vaddr,
  output  io_mshrTask_bits_aMergeTask_isKeyword,
  output  [2:0] io_mshrTask_bits_aMergeTask_opcode,
  output  [2:0] io_mshrTask_bits_aMergeTask_param,
  output  [6:0] io_mshrTask_bits_aMergeTask_sourceId,
  output  io_mshrTask_bits_aMergeTask_meta_dirty,
  output  [1:0] io_mshrTask_bits_aMergeTask_meta_state,
  output  io_mshrTask_bits_aMergeTask_meta_clients,
  output  [1:0] io_mshrTask_bits_aMergeTask_meta_alias,
  output  io_mshrTask_bits_aMergeTask_meta_accessed,
  output  io_mshrTask_bits_snpHitRelease,
  output  io_mshrTask_bits_snpHitReleaseToInval,
  output  io_mshrTask_bits_snpHitReleaseToClean,
  output  io_mshrTask_bits_snpHitReleaseWithData,
  output  [7:0] io_mshrTask_bits_snpHitReleaseIdx,
  output  io_mshrTask_bits_snpHitReleaseMeta_dirty,
  output  [1:0] io_mshrTask_bits_snpHitReleaseMeta_state,
  output  io_mshrTask_bits_snpHitReleaseMeta_clients,
  output  [1:0] io_mshrTask_bits_snpHitReleaseMeta_alias,
  output  io_mshrTask_bits_snpHitReleaseMeta_prefetch,
  output  [2:0] io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc,
  output  io_mshrTask_bits_snpHitReleaseMeta_accessed,
  output  io_mshrTask_bits_snpHitReleaseMeta_tagErr,
  output  io_mshrTask_bits_snpHitReleaseMeta_dataErr,
  output  [10:0] io_mshrTask_bits_tgtID,
  output  [11:0] io_mshrTask_bits_txnID,
  output  [10:0] io_mshrTask_bits_homeNID,
  output  [11:0] io_mshrTask_bits_dbID,
  output  [6:0] io_mshrTask_bits_chiOpcode,
  output  [2:0] io_mshrTask_bits_resp,
  output  [2:0] io_mshrTask_bits_fwdState,
  output  io_mshrTask_bits_retToSrc,
  output  io_mshrTask_bits_likelyshared,
  output  io_mshrTask_bits_expCompAck,
  output  io_mshrTask_bits_allowRetry,
  output  io_mshrTask_bits_memAttr_allocate,
  output  io_mshrTask_bits_memAttr_cacheable,
  output  io_mshrTask_bits_memAttr_ewa,
  output  io_mshrTask_bits_traceTag,
  output  io_mshrTask_bits_dataCheckErr,
  input  io_pipeStatusVec_0_valid,
  input  io_pipeStatusVec_1_valid,
  input  io_toTXREQ_ready,
  output  io_toTXREQ_valid,
  output  [3:0] io_toTXREQ_bits_qos,
  output  [10:0] io_toTXREQ_bits_tgtID,
  output  [11:0] io_toTXREQ_bits_txnID,
  output  [6:0] io_toTXREQ_bits_opcode,
  output  [2:0] io_toTXREQ_bits_size,
  output  [47:0] io_toTXREQ_bits_addr,
  output  io_toTXREQ_bits_likelyshared,
  output  io_toTXREQ_bits_allowRetry,
  output  [3:0] io_toTXREQ_bits_pCrdType,
  output  io_toTXREQ_bits_memAttr_allocate,
  output  io_toTXREQ_bits_memAttr_cacheable,
  output  io_toTXREQ_bits_memAttr_ewa,
  output  io_toTXREQ_bits_snpAttr,
  output  io_toTXREQ_bits_expCompAck,
  input  io_toTXRSP_ready,
  output  io_toTXRSP_valid,
  output  [10:0] io_toTXRSP_bits_tgtID,
  output  [11:0] io_toTXRSP_bits_txnID,
  output  [4:0] io_toTXRSP_bits_opcode,
  output  io_toTXRSP_bits_traceTag,
  input  io_toSourceB_ready,
  output  io_toSourceB_valid,
  output  [2:0] io_toSourceB_bits_opcode,
  output  [1:0] io_toSourceB_bits_param,
  output  [47:0] io_toSourceB_bits_address,
  output  [255:0] io_toSourceB_bits_data,
  input  io_grantStatus_0_valid,
  input  [8:0] io_grantStatus_0_set,
  input  [30:0] io_grantStatus_0_tag,
  input  io_grantStatus_1_valid,
  input  [8:0] io_grantStatus_1_set,
  input  [30:0] io_grantStatus_1_tag,
  input  io_grantStatus_2_valid,
  input  [8:0] io_grantStatus_2_set,
  input  [30:0] io_grantStatus_2_tag,
  input  io_grantStatus_3_valid,
  input  [8:0] io_grantStatus_3_set,
  input  [30:0] io_grantStatus_3_tag,
  input  io_grantStatus_4_valid,
  input  [8:0] io_grantStatus_4_set,
  input  [30:0] io_grantStatus_4_tag,
  input  io_grantStatus_5_valid,
  input  [8:0] io_grantStatus_5_set,
  input  [30:0] io_grantStatus_5_tag,
  input  io_grantStatus_6_valid,
  input  [8:0] io_grantStatus_6_set,
  input  [30:0] io_grantStatus_6_tag,
  input  io_grantStatus_7_valid,
  input  [8:0] io_grantStatus_7_set,
  input  [30:0] io_grantStatus_7_tag,
  input  io_grantStatus_8_valid,
  input  [8:0] io_grantStatus_8_set,
  input  [30:0] io_grantStatus_8_tag,
  input  io_grantStatus_9_valid,
  input  [8:0] io_grantStatus_9_set,
  input  [30:0] io_grantStatus_9_tag,
  input  io_grantStatus_10_valid,
  input  [8:0] io_grantStatus_10_set,
  input  [30:0] io_grantStatus_10_tag,
  input  io_grantStatus_11_valid,
  input  [8:0] io_grantStatus_11_set,
  input  [30:0] io_grantStatus_11_tag,
  input  io_grantStatus_12_valid,
  input  [8:0] io_grantStatus_12_set,
  input  [30:0] io_grantStatus_12_tag,
  input  io_grantStatus_13_valid,
  input  [8:0] io_grantStatus_13_set,
  input  [30:0] io_grantStatus_13_tag,
  input  io_grantStatus_14_valid,
  input  [8:0] io_grantStatus_14_set,
  input  [30:0] io_grantStatus_14_tag,
  input  io_grantStatus_15_valid,
  input  [8:0] io_grantStatus_15_set,
  input  [30:0] io_grantStatus_15_tag,
  input  io_resps_sinkC_valid,
  input  [8:0] io_resps_sinkC_set,
  input  [30:0] io_resps_sinkC_tag,
  input  [2:0] io_resps_sinkC_respInfo_opcode,
  input  [2:0] io_resps_sinkC_respInfo_param,
  input  io_resps_sinkC_respInfo_last,
  input  io_resps_sinkC_respInfo_denied,
  input  io_resps_sinkC_respInfo_corrupt,
  input  io_resps_rxrsp_valid,
  input  [7:0] io_resps_rxrsp_mshrId,
  input  [6:0] io_resps_rxrsp_respInfo_chiOpcode,
  input  [10:0] io_resps_rxrsp_respInfo_srcID,
  input  [11:0] io_resps_rxrsp_respInfo_dbID,
  input  [2:0] io_resps_rxrsp_respInfo_resp,
  input  [3:0] io_resps_rxrsp_respInfo_pCrdType,
  input  [1:0] io_resps_rxrsp_respInfo_respErr,
  input  io_resps_rxrsp_respInfo_traceTag,
  input  io_resps_rxdat_valid,
  input  [7:0] io_resps_rxdat_mshrId,
  input  io_resps_rxdat_respInfo_last,
  input  io_resps_rxdat_respInfo_corrupt,
  input  [6:0] io_resps_rxdat_respInfo_chiOpcode,
  input  [10:0] io_resps_rxdat_respInfo_homeNID,
  input  [11:0] io_resps_rxdat_respInfo_dbID,
  input  [2:0] io_resps_rxdat_respInfo_resp,
  input  [1:0] io_resps_rxdat_respInfo_respErr,
  input  io_resps_rxdat_respInfo_traceTag,
  input  io_resps_rxdat_respInfo_dataCheckErr,
  output  [7:0] io_releaseBufWriteId,
  input  [8:0] io_nestedwb_set,
  input  [30:0] io_nestedwb_tag,
  input  io_nestedwb_c_set_dirty,
  input  io_nestedwb_c_set_tip,
  input  io_nestedwb_b_inv_dirty,
  input  io_nestedwb_b_toB,
  input  io_nestedwb_b_toN,
  input  io_nestedwb_b_toClean,
  output  io_nestedwbDataId_valid,
  output  [7:0] io_nestedwbDataId_bits,
  output  io_msInfo_0_valid,
  output  [2:0] io_msInfo_0_bits_channel,
  output  [8:0] io_msInfo_0_bits_set,
  output  [2:0] io_msInfo_0_bits_way,
  output  [30:0] io_msInfo_0_bits_reqTag,
  output  io_msInfo_0_bits_willFree,
  output  io_msInfo_0_bits_aliasTask,
  output  io_msInfo_0_bits_needRelease,
  output  io_msInfo_0_bits_blockRefill,
  output  io_msInfo_0_bits_meta_dirty,
  output  [1:0] io_msInfo_0_bits_meta_state,
  output  io_msInfo_0_bits_meta_clients,
  output  [1:0] io_msInfo_0_bits_meta_alias,
  output  io_msInfo_0_bits_meta_prefetch,
  output  [2:0] io_msInfo_0_bits_meta_prefetchSrc,
  output  io_msInfo_0_bits_meta_accessed,
  output  io_msInfo_0_bits_meta_tagErr,
  output  io_msInfo_0_bits_meta_dataErr,
  output  [30:0] io_msInfo_0_bits_metaTag,
  output  io_msInfo_0_bits_dirHit,
  output  io_msInfo_0_bits_isAcqOrPrefetch,
  output  io_msInfo_0_bits_isPrefetch,
  output  [2:0] io_msInfo_0_bits_param,
  output  io_msInfo_0_bits_mergeA,
  output  io_msInfo_0_bits_w_grantfirst,
  output  io_msInfo_0_bits_s_release,
  output  io_msInfo_0_bits_s_refill,
  output  io_msInfo_0_bits_s_cmoresp,
  output  io_msInfo_0_bits_s_cmometaw,
  output  io_msInfo_0_bits_w_releaseack,
  output  io_msInfo_0_bits_w_replResp,
  output  io_msInfo_0_bits_w_rprobeacklast,
  output  io_msInfo_0_bits_replaceData,
  output  io_msInfo_0_bits_releaseToClean,
  output  io_msInfo_1_valid,
  output  [2:0] io_msInfo_1_bits_channel,
  output  [8:0] io_msInfo_1_bits_set,
  output  [2:0] io_msInfo_1_bits_way,
  output  [30:0] io_msInfo_1_bits_reqTag,
  output  io_msInfo_1_bits_willFree,
  output  io_msInfo_1_bits_aliasTask,
  output  io_msInfo_1_bits_needRelease,
  output  io_msInfo_1_bits_blockRefill,
  output  io_msInfo_1_bits_meta_dirty,
  output  [1:0] io_msInfo_1_bits_meta_state,
  output  io_msInfo_1_bits_meta_clients,
  output  [1:0] io_msInfo_1_bits_meta_alias,
  output  io_msInfo_1_bits_meta_prefetch,
  output  [2:0] io_msInfo_1_bits_meta_prefetchSrc,
  output  io_msInfo_1_bits_meta_accessed,
  output  io_msInfo_1_bits_meta_tagErr,
  output  io_msInfo_1_bits_meta_dataErr,
  output  [30:0] io_msInfo_1_bits_metaTag,
  output  io_msInfo_1_bits_dirHit,
  output  io_msInfo_1_bits_isAcqOrPrefetch,
  output  io_msInfo_1_bits_isPrefetch,
  output  [2:0] io_msInfo_1_bits_param,
  output  io_msInfo_1_bits_mergeA,
  output  io_msInfo_1_bits_w_grantfirst,
  output  io_msInfo_1_bits_s_release,
  output  io_msInfo_1_bits_s_refill,
  output  io_msInfo_1_bits_s_cmoresp,
  output  io_msInfo_1_bits_s_cmometaw,
  output  io_msInfo_1_bits_w_releaseack,
  output  io_msInfo_1_bits_w_replResp,
  output  io_msInfo_1_bits_w_rprobeacklast,
  output  io_msInfo_1_bits_replaceData,
  output  io_msInfo_1_bits_releaseToClean,
  output  io_msInfo_2_valid,
  output  [2:0] io_msInfo_2_bits_channel,
  output  [8:0] io_msInfo_2_bits_set,
  output  [2:0] io_msInfo_2_bits_way,
  output  [30:0] io_msInfo_2_bits_reqTag,
  output  io_msInfo_2_bits_willFree,
  output  io_msInfo_2_bits_aliasTask,
  output  io_msInfo_2_bits_needRelease,
  output  io_msInfo_2_bits_blockRefill,
  output  io_msInfo_2_bits_meta_dirty,
  output  [1:0] io_msInfo_2_bits_meta_state,
  output  io_msInfo_2_bits_meta_clients,
  output  [1:0] io_msInfo_2_bits_meta_alias,
  output  io_msInfo_2_bits_meta_prefetch,
  output  [2:0] io_msInfo_2_bits_meta_prefetchSrc,
  output  io_msInfo_2_bits_meta_accessed,
  output  io_msInfo_2_bits_meta_tagErr,
  output  io_msInfo_2_bits_meta_dataErr,
  output  [30:0] io_msInfo_2_bits_metaTag,
  output  io_msInfo_2_bits_dirHit,
  output  io_msInfo_2_bits_isAcqOrPrefetch,
  output  io_msInfo_2_bits_isPrefetch,
  output  [2:0] io_msInfo_2_bits_param,
  output  io_msInfo_2_bits_mergeA,
  output  io_msInfo_2_bits_w_grantfirst,
  output  io_msInfo_2_bits_s_release,
  output  io_msInfo_2_bits_s_refill,
  output  io_msInfo_2_bits_s_cmoresp,
  output  io_msInfo_2_bits_s_cmometaw,
  output  io_msInfo_2_bits_w_releaseack,
  output  io_msInfo_2_bits_w_replResp,
  output  io_msInfo_2_bits_w_rprobeacklast,
  output  io_msInfo_2_bits_replaceData,
  output  io_msInfo_2_bits_releaseToClean,
  output  io_msInfo_3_valid,
  output  [2:0] io_msInfo_3_bits_channel,
  output  [8:0] io_msInfo_3_bits_set,
  output  [2:0] io_msInfo_3_bits_way,
  output  [30:0] io_msInfo_3_bits_reqTag,
  output  io_msInfo_3_bits_willFree,
  output  io_msInfo_3_bits_aliasTask,
  output  io_msInfo_3_bits_needRelease,
  output  io_msInfo_3_bits_blockRefill,
  output  io_msInfo_3_bits_meta_dirty,
  output  [1:0] io_msInfo_3_bits_meta_state,
  output  io_msInfo_3_bits_meta_clients,
  output  [1:0] io_msInfo_3_bits_meta_alias,
  output  io_msInfo_3_bits_meta_prefetch,
  output  [2:0] io_msInfo_3_bits_meta_prefetchSrc,
  output  io_msInfo_3_bits_meta_accessed,
  output  io_msInfo_3_bits_meta_tagErr,
  output  io_msInfo_3_bits_meta_dataErr,
  output  [30:0] io_msInfo_3_bits_metaTag,
  output  io_msInfo_3_bits_dirHit,
  output  io_msInfo_3_bits_isAcqOrPrefetch,
  output  io_msInfo_3_bits_isPrefetch,
  output  [2:0] io_msInfo_3_bits_param,
  output  io_msInfo_3_bits_mergeA,
  output  io_msInfo_3_bits_w_grantfirst,
  output  io_msInfo_3_bits_s_release,
  output  io_msInfo_3_bits_s_refill,
  output  io_msInfo_3_bits_s_cmoresp,
  output  io_msInfo_3_bits_s_cmometaw,
  output  io_msInfo_3_bits_w_releaseack,
  output  io_msInfo_3_bits_w_replResp,
  output  io_msInfo_3_bits_w_rprobeacklast,
  output  io_msInfo_3_bits_replaceData,
  output  io_msInfo_3_bits_releaseToClean,
  output  io_msInfo_4_valid,
  output  [2:0] io_msInfo_4_bits_channel,
  output  [8:0] io_msInfo_4_bits_set,
  output  [2:0] io_msInfo_4_bits_way,
  output  [30:0] io_msInfo_4_bits_reqTag,
  output  io_msInfo_4_bits_willFree,
  output  io_msInfo_4_bits_aliasTask,
  output  io_msInfo_4_bits_needRelease,
  output  io_msInfo_4_bits_blockRefill,
  output  io_msInfo_4_bits_meta_dirty,
  output  [1:0] io_msInfo_4_bits_meta_state,
  output  io_msInfo_4_bits_meta_clients,
  output  [1:0] io_msInfo_4_bits_meta_alias,
  output  io_msInfo_4_bits_meta_prefetch,
  output  [2:0] io_msInfo_4_bits_meta_prefetchSrc,
  output  io_msInfo_4_bits_meta_accessed,
  output  io_msInfo_4_bits_meta_tagErr,
  output  io_msInfo_4_bits_meta_dataErr,
  output  [30:0] io_msInfo_4_bits_metaTag,
  output  io_msInfo_4_bits_dirHit,
  output  io_msInfo_4_bits_isAcqOrPrefetch,
  output  io_msInfo_4_bits_isPrefetch,
  output  [2:0] io_msInfo_4_bits_param,
  output  io_msInfo_4_bits_mergeA,
  output  io_msInfo_4_bits_w_grantfirst,
  output  io_msInfo_4_bits_s_release,
  output  io_msInfo_4_bits_s_refill,
  output  io_msInfo_4_bits_s_cmoresp,
  output  io_msInfo_4_bits_s_cmometaw,
  output  io_msInfo_4_bits_w_releaseack,
  output  io_msInfo_4_bits_w_replResp,
  output  io_msInfo_4_bits_w_rprobeacklast,
  output  io_msInfo_4_bits_replaceData,
  output  io_msInfo_4_bits_releaseToClean,
  output  io_msInfo_5_valid,
  output  [2:0] io_msInfo_5_bits_channel,
  output  [8:0] io_msInfo_5_bits_set,
  output  [2:0] io_msInfo_5_bits_way,
  output  [30:0] io_msInfo_5_bits_reqTag,
  output  io_msInfo_5_bits_willFree,
  output  io_msInfo_5_bits_aliasTask,
  output  io_msInfo_5_bits_needRelease,
  output  io_msInfo_5_bits_blockRefill,
  output  io_msInfo_5_bits_meta_dirty,
  output  [1:0] io_msInfo_5_bits_meta_state,
  output  io_msInfo_5_bits_meta_clients,
  output  [1:0] io_msInfo_5_bits_meta_alias,
  output  io_msInfo_5_bits_meta_prefetch,
  output  [2:0] io_msInfo_5_bits_meta_prefetchSrc,
  output  io_msInfo_5_bits_meta_accessed,
  output  io_msInfo_5_bits_meta_tagErr,
  output  io_msInfo_5_bits_meta_dataErr,
  output  [30:0] io_msInfo_5_bits_metaTag,
  output  io_msInfo_5_bits_dirHit,
  output  io_msInfo_5_bits_isAcqOrPrefetch,
  output  io_msInfo_5_bits_isPrefetch,
  output  [2:0] io_msInfo_5_bits_param,
  output  io_msInfo_5_bits_mergeA,
  output  io_msInfo_5_bits_w_grantfirst,
  output  io_msInfo_5_bits_s_release,
  output  io_msInfo_5_bits_s_refill,
  output  io_msInfo_5_bits_s_cmoresp,
  output  io_msInfo_5_bits_s_cmometaw,
  output  io_msInfo_5_bits_w_releaseack,
  output  io_msInfo_5_bits_w_replResp,
  output  io_msInfo_5_bits_w_rprobeacklast,
  output  io_msInfo_5_bits_replaceData,
  output  io_msInfo_5_bits_releaseToClean,
  output  io_msInfo_6_valid,
  output  [2:0] io_msInfo_6_bits_channel,
  output  [8:0] io_msInfo_6_bits_set,
  output  [2:0] io_msInfo_6_bits_way,
  output  [30:0] io_msInfo_6_bits_reqTag,
  output  io_msInfo_6_bits_willFree,
  output  io_msInfo_6_bits_aliasTask,
  output  io_msInfo_6_bits_needRelease,
  output  io_msInfo_6_bits_blockRefill,
  output  io_msInfo_6_bits_meta_dirty,
  output  [1:0] io_msInfo_6_bits_meta_state,
  output  io_msInfo_6_bits_meta_clients,
  output  [1:0] io_msInfo_6_bits_meta_alias,
  output  io_msInfo_6_bits_meta_prefetch,
  output  [2:0] io_msInfo_6_bits_meta_prefetchSrc,
  output  io_msInfo_6_bits_meta_accessed,
  output  io_msInfo_6_bits_meta_tagErr,
  output  io_msInfo_6_bits_meta_dataErr,
  output  [30:0] io_msInfo_6_bits_metaTag,
  output  io_msInfo_6_bits_dirHit,
  output  io_msInfo_6_bits_isAcqOrPrefetch,
  output  io_msInfo_6_bits_isPrefetch,
  output  [2:0] io_msInfo_6_bits_param,
  output  io_msInfo_6_bits_mergeA,
  output  io_msInfo_6_bits_w_grantfirst,
  output  io_msInfo_6_bits_s_release,
  output  io_msInfo_6_bits_s_refill,
  output  io_msInfo_6_bits_s_cmoresp,
  output  io_msInfo_6_bits_s_cmometaw,
  output  io_msInfo_6_bits_w_releaseack,
  output  io_msInfo_6_bits_w_replResp,
  output  io_msInfo_6_bits_w_rprobeacklast,
  output  io_msInfo_6_bits_replaceData,
  output  io_msInfo_6_bits_releaseToClean,
  output  io_msInfo_7_valid,
  output  [2:0] io_msInfo_7_bits_channel,
  output  [8:0] io_msInfo_7_bits_set,
  output  [2:0] io_msInfo_7_bits_way,
  output  [30:0] io_msInfo_7_bits_reqTag,
  output  io_msInfo_7_bits_willFree,
  output  io_msInfo_7_bits_aliasTask,
  output  io_msInfo_7_bits_needRelease,
  output  io_msInfo_7_bits_blockRefill,
  output  io_msInfo_7_bits_meta_dirty,
  output  [1:0] io_msInfo_7_bits_meta_state,
  output  io_msInfo_7_bits_meta_clients,
  output  [1:0] io_msInfo_7_bits_meta_alias,
  output  io_msInfo_7_bits_meta_prefetch,
  output  [2:0] io_msInfo_7_bits_meta_prefetchSrc,
  output  io_msInfo_7_bits_meta_accessed,
  output  io_msInfo_7_bits_meta_tagErr,
  output  io_msInfo_7_bits_meta_dataErr,
  output  [30:0] io_msInfo_7_bits_metaTag,
  output  io_msInfo_7_bits_dirHit,
  output  io_msInfo_7_bits_isAcqOrPrefetch,
  output  io_msInfo_7_bits_isPrefetch,
  output  [2:0] io_msInfo_7_bits_param,
  output  io_msInfo_7_bits_mergeA,
  output  io_msInfo_7_bits_w_grantfirst,
  output  io_msInfo_7_bits_s_release,
  output  io_msInfo_7_bits_s_refill,
  output  io_msInfo_7_bits_s_cmoresp,
  output  io_msInfo_7_bits_s_cmometaw,
  output  io_msInfo_7_bits_w_releaseack,
  output  io_msInfo_7_bits_w_replResp,
  output  io_msInfo_7_bits_w_rprobeacklast,
  output  io_msInfo_7_bits_replaceData,
  output  io_msInfo_7_bits_releaseToClean,
  output  io_msInfo_8_valid,
  output  [2:0] io_msInfo_8_bits_channel,
  output  [8:0] io_msInfo_8_bits_set,
  output  [2:0] io_msInfo_8_bits_way,
  output  [30:0] io_msInfo_8_bits_reqTag,
  output  io_msInfo_8_bits_willFree,
  output  io_msInfo_8_bits_aliasTask,
  output  io_msInfo_8_bits_needRelease,
  output  io_msInfo_8_bits_blockRefill,
  output  io_msInfo_8_bits_meta_dirty,
  output  [1:0] io_msInfo_8_bits_meta_state,
  output  io_msInfo_8_bits_meta_clients,
  output  [1:0] io_msInfo_8_bits_meta_alias,
  output  io_msInfo_8_bits_meta_prefetch,
  output  [2:0] io_msInfo_8_bits_meta_prefetchSrc,
  output  io_msInfo_8_bits_meta_accessed,
  output  io_msInfo_8_bits_meta_tagErr,
  output  io_msInfo_8_bits_meta_dataErr,
  output  [30:0] io_msInfo_8_bits_metaTag,
  output  io_msInfo_8_bits_dirHit,
  output  io_msInfo_8_bits_isAcqOrPrefetch,
  output  io_msInfo_8_bits_isPrefetch,
  output  [2:0] io_msInfo_8_bits_param,
  output  io_msInfo_8_bits_mergeA,
  output  io_msInfo_8_bits_w_grantfirst,
  output  io_msInfo_8_bits_s_release,
  output  io_msInfo_8_bits_s_refill,
  output  io_msInfo_8_bits_s_cmoresp,
  output  io_msInfo_8_bits_s_cmometaw,
  output  io_msInfo_8_bits_w_releaseack,
  output  io_msInfo_8_bits_w_replResp,
  output  io_msInfo_8_bits_w_rprobeacklast,
  output  io_msInfo_8_bits_replaceData,
  output  io_msInfo_8_bits_releaseToClean,
  output  io_msInfo_9_valid,
  output  [2:0] io_msInfo_9_bits_channel,
  output  [8:0] io_msInfo_9_bits_set,
  output  [2:0] io_msInfo_9_bits_way,
  output  [30:0] io_msInfo_9_bits_reqTag,
  output  io_msInfo_9_bits_willFree,
  output  io_msInfo_9_bits_aliasTask,
  output  io_msInfo_9_bits_needRelease,
  output  io_msInfo_9_bits_blockRefill,
  output  io_msInfo_9_bits_meta_dirty,
  output  [1:0] io_msInfo_9_bits_meta_state,
  output  io_msInfo_9_bits_meta_clients,
  output  [1:0] io_msInfo_9_bits_meta_alias,
  output  io_msInfo_9_bits_meta_prefetch,
  output  [2:0] io_msInfo_9_bits_meta_prefetchSrc,
  output  io_msInfo_9_bits_meta_accessed,
  output  io_msInfo_9_bits_meta_tagErr,
  output  io_msInfo_9_bits_meta_dataErr,
  output  [30:0] io_msInfo_9_bits_metaTag,
  output  io_msInfo_9_bits_dirHit,
  output  io_msInfo_9_bits_isAcqOrPrefetch,
  output  io_msInfo_9_bits_isPrefetch,
  output  [2:0] io_msInfo_9_bits_param,
  output  io_msInfo_9_bits_mergeA,
  output  io_msInfo_9_bits_w_grantfirst,
  output  io_msInfo_9_bits_s_release,
  output  io_msInfo_9_bits_s_refill,
  output  io_msInfo_9_bits_s_cmoresp,
  output  io_msInfo_9_bits_s_cmometaw,
  output  io_msInfo_9_bits_w_releaseack,
  output  io_msInfo_9_bits_w_replResp,
  output  io_msInfo_9_bits_w_rprobeacklast,
  output  io_msInfo_9_bits_replaceData,
  output  io_msInfo_9_bits_releaseToClean,
  output  io_msInfo_10_valid,
  output  [2:0] io_msInfo_10_bits_channel,
  output  [8:0] io_msInfo_10_bits_set,
  output  [2:0] io_msInfo_10_bits_way,
  output  [30:0] io_msInfo_10_bits_reqTag,
  output  io_msInfo_10_bits_willFree,
  output  io_msInfo_10_bits_aliasTask,
  output  io_msInfo_10_bits_needRelease,
  output  io_msInfo_10_bits_blockRefill,
  output  io_msInfo_10_bits_meta_dirty,
  output  [1:0] io_msInfo_10_bits_meta_state,
  output  io_msInfo_10_bits_meta_clients,
  output  [1:0] io_msInfo_10_bits_meta_alias,
  output  io_msInfo_10_bits_meta_prefetch,
  output  [2:0] io_msInfo_10_bits_meta_prefetchSrc,
  output  io_msInfo_10_bits_meta_accessed,
  output  io_msInfo_10_bits_meta_tagErr,
  output  io_msInfo_10_bits_meta_dataErr,
  output  [30:0] io_msInfo_10_bits_metaTag,
  output  io_msInfo_10_bits_dirHit,
  output  io_msInfo_10_bits_isAcqOrPrefetch,
  output  io_msInfo_10_bits_isPrefetch,
  output  [2:0] io_msInfo_10_bits_param,
  output  io_msInfo_10_bits_mergeA,
  output  io_msInfo_10_bits_w_grantfirst,
  output  io_msInfo_10_bits_s_release,
  output  io_msInfo_10_bits_s_refill,
  output  io_msInfo_10_bits_s_cmoresp,
  output  io_msInfo_10_bits_s_cmometaw,
  output  io_msInfo_10_bits_w_releaseack,
  output  io_msInfo_10_bits_w_replResp,
  output  io_msInfo_10_bits_w_rprobeacklast,
  output  io_msInfo_10_bits_replaceData,
  output  io_msInfo_10_bits_releaseToClean,
  output  io_msInfo_11_valid,
  output  [2:0] io_msInfo_11_bits_channel,
  output  [8:0] io_msInfo_11_bits_set,
  output  [2:0] io_msInfo_11_bits_way,
  output  [30:0] io_msInfo_11_bits_reqTag,
  output  io_msInfo_11_bits_willFree,
  output  io_msInfo_11_bits_aliasTask,
  output  io_msInfo_11_bits_needRelease,
  output  io_msInfo_11_bits_blockRefill,
  output  io_msInfo_11_bits_meta_dirty,
  output  [1:0] io_msInfo_11_bits_meta_state,
  output  io_msInfo_11_bits_meta_clients,
  output  [1:0] io_msInfo_11_bits_meta_alias,
  output  io_msInfo_11_bits_meta_prefetch,
  output  [2:0] io_msInfo_11_bits_meta_prefetchSrc,
  output  io_msInfo_11_bits_meta_accessed,
  output  io_msInfo_11_bits_meta_tagErr,
  output  io_msInfo_11_bits_meta_dataErr,
  output  [30:0] io_msInfo_11_bits_metaTag,
  output  io_msInfo_11_bits_dirHit,
  output  io_msInfo_11_bits_isAcqOrPrefetch,
  output  io_msInfo_11_bits_isPrefetch,
  output  [2:0] io_msInfo_11_bits_param,
  output  io_msInfo_11_bits_mergeA,
  output  io_msInfo_11_bits_w_grantfirst,
  output  io_msInfo_11_bits_s_release,
  output  io_msInfo_11_bits_s_refill,
  output  io_msInfo_11_bits_s_cmoresp,
  output  io_msInfo_11_bits_s_cmometaw,
  output  io_msInfo_11_bits_w_releaseack,
  output  io_msInfo_11_bits_w_replResp,
  output  io_msInfo_11_bits_w_rprobeacklast,
  output  io_msInfo_11_bits_replaceData,
  output  io_msInfo_11_bits_releaseToClean,
  output  io_msInfo_12_valid,
  output  [2:0] io_msInfo_12_bits_channel,
  output  [8:0] io_msInfo_12_bits_set,
  output  [2:0] io_msInfo_12_bits_way,
  output  [30:0] io_msInfo_12_bits_reqTag,
  output  io_msInfo_12_bits_willFree,
  output  io_msInfo_12_bits_aliasTask,
  output  io_msInfo_12_bits_needRelease,
  output  io_msInfo_12_bits_blockRefill,
  output  io_msInfo_12_bits_meta_dirty,
  output  [1:0] io_msInfo_12_bits_meta_state,
  output  io_msInfo_12_bits_meta_clients,
  output  [1:0] io_msInfo_12_bits_meta_alias,
  output  io_msInfo_12_bits_meta_prefetch,
  output  [2:0] io_msInfo_12_bits_meta_prefetchSrc,
  output  io_msInfo_12_bits_meta_accessed,
  output  io_msInfo_12_bits_meta_tagErr,
  output  io_msInfo_12_bits_meta_dataErr,
  output  [30:0] io_msInfo_12_bits_metaTag,
  output  io_msInfo_12_bits_dirHit,
  output  io_msInfo_12_bits_isAcqOrPrefetch,
  output  io_msInfo_12_bits_isPrefetch,
  output  [2:0] io_msInfo_12_bits_param,
  output  io_msInfo_12_bits_mergeA,
  output  io_msInfo_12_bits_w_grantfirst,
  output  io_msInfo_12_bits_s_release,
  output  io_msInfo_12_bits_s_refill,
  output  io_msInfo_12_bits_s_cmoresp,
  output  io_msInfo_12_bits_s_cmometaw,
  output  io_msInfo_12_bits_w_releaseack,
  output  io_msInfo_12_bits_w_replResp,
  output  io_msInfo_12_bits_w_rprobeacklast,
  output  io_msInfo_12_bits_replaceData,
  output  io_msInfo_12_bits_releaseToClean,
  output  io_msInfo_13_valid,
  output  [2:0] io_msInfo_13_bits_channel,
  output  [8:0] io_msInfo_13_bits_set,
  output  [2:0] io_msInfo_13_bits_way,
  output  [30:0] io_msInfo_13_bits_reqTag,
  output  io_msInfo_13_bits_willFree,
  output  io_msInfo_13_bits_aliasTask,
  output  io_msInfo_13_bits_needRelease,
  output  io_msInfo_13_bits_blockRefill,
  output  io_msInfo_13_bits_meta_dirty,
  output  [1:0] io_msInfo_13_bits_meta_state,
  output  io_msInfo_13_bits_meta_clients,
  output  [1:0] io_msInfo_13_bits_meta_alias,
  output  io_msInfo_13_bits_meta_prefetch,
  output  [2:0] io_msInfo_13_bits_meta_prefetchSrc,
  output  io_msInfo_13_bits_meta_accessed,
  output  io_msInfo_13_bits_meta_tagErr,
  output  io_msInfo_13_bits_meta_dataErr,
  output  [30:0] io_msInfo_13_bits_metaTag,
  output  io_msInfo_13_bits_dirHit,
  output  io_msInfo_13_bits_isAcqOrPrefetch,
  output  io_msInfo_13_bits_isPrefetch,
  output  [2:0] io_msInfo_13_bits_param,
  output  io_msInfo_13_bits_mergeA,
  output  io_msInfo_13_bits_w_grantfirst,
  output  io_msInfo_13_bits_s_release,
  output  io_msInfo_13_bits_s_refill,
  output  io_msInfo_13_bits_s_cmoresp,
  output  io_msInfo_13_bits_s_cmometaw,
  output  io_msInfo_13_bits_w_releaseack,
  output  io_msInfo_13_bits_w_replResp,
  output  io_msInfo_13_bits_w_rprobeacklast,
  output  io_msInfo_13_bits_replaceData,
  output  io_msInfo_13_bits_releaseToClean,
  output  io_msInfo_14_valid,
  output  [2:0] io_msInfo_14_bits_channel,
  output  [8:0] io_msInfo_14_bits_set,
  output  [2:0] io_msInfo_14_bits_way,
  output  [30:0] io_msInfo_14_bits_reqTag,
  output  io_msInfo_14_bits_willFree,
  output  io_msInfo_14_bits_aliasTask,
  output  io_msInfo_14_bits_needRelease,
  output  io_msInfo_14_bits_blockRefill,
  output  io_msInfo_14_bits_meta_dirty,
  output  [1:0] io_msInfo_14_bits_meta_state,
  output  io_msInfo_14_bits_meta_clients,
  output  [1:0] io_msInfo_14_bits_meta_alias,
  output  io_msInfo_14_bits_meta_prefetch,
  output  [2:0] io_msInfo_14_bits_meta_prefetchSrc,
  output  io_msInfo_14_bits_meta_accessed,
  output  io_msInfo_14_bits_meta_tagErr,
  output  io_msInfo_14_bits_meta_dataErr,
  output  [30:0] io_msInfo_14_bits_metaTag,
  output  io_msInfo_14_bits_dirHit,
  output  io_msInfo_14_bits_isAcqOrPrefetch,
  output  io_msInfo_14_bits_isPrefetch,
  output  [2:0] io_msInfo_14_bits_param,
  output  io_msInfo_14_bits_mergeA,
  output  io_msInfo_14_bits_w_grantfirst,
  output  io_msInfo_14_bits_s_release,
  output  io_msInfo_14_bits_s_refill,
  output  io_msInfo_14_bits_s_cmoresp,
  output  io_msInfo_14_bits_s_cmometaw,
  output  io_msInfo_14_bits_w_releaseack,
  output  io_msInfo_14_bits_w_replResp,
  output  io_msInfo_14_bits_w_rprobeacklast,
  output  io_msInfo_14_bits_replaceData,
  output  io_msInfo_14_bits_releaseToClean,
  output  io_msInfo_15_valid,
  output  [2:0] io_msInfo_15_bits_channel,
  output  [8:0] io_msInfo_15_bits_set,
  output  [2:0] io_msInfo_15_bits_way,
  output  [30:0] io_msInfo_15_bits_reqTag,
  output  io_msInfo_15_bits_willFree,
  output  io_msInfo_15_bits_aliasTask,
  output  io_msInfo_15_bits_needRelease,
  output  io_msInfo_15_bits_blockRefill,
  output  io_msInfo_15_bits_meta_dirty,
  output  [1:0] io_msInfo_15_bits_meta_state,
  output  io_msInfo_15_bits_meta_clients,
  output  [1:0] io_msInfo_15_bits_meta_alias,
  output  io_msInfo_15_bits_meta_prefetch,
  output  [2:0] io_msInfo_15_bits_meta_prefetchSrc,
  output  io_msInfo_15_bits_meta_accessed,
  output  io_msInfo_15_bits_meta_tagErr,
  output  io_msInfo_15_bits_meta_dataErr,
  output  [30:0] io_msInfo_15_bits_metaTag,
  output  io_msInfo_15_bits_dirHit,
  output  io_msInfo_15_bits_isAcqOrPrefetch,
  output  io_msInfo_15_bits_isPrefetch,
  output  [2:0] io_msInfo_15_bits_param,
  output  io_msInfo_15_bits_mergeA,
  output  io_msInfo_15_bits_w_grantfirst,
  output  io_msInfo_15_bits_s_release,
  output  io_msInfo_15_bits_s_refill,
  output  io_msInfo_15_bits_s_cmoresp,
  output  io_msInfo_15_bits_s_cmometaw,
  output  io_msInfo_15_bits_w_releaseack,
  output  io_msInfo_15_bits_w_replResp,
  output  io_msInfo_15_bits_w_rprobeacklast,
  output  io_msInfo_15_bits_replaceData,
  output  io_msInfo_15_bits_releaseToClean,
  input  io_aMergeTask_valid,
  input  [7:0] io_aMergeTask_bits_id,
  input  [5:0] io_aMergeTask_bits_task_off,
  input  [1:0] io_aMergeTask_bits_task_alias,
  input  [43:0] io_aMergeTask_bits_task_vaddr,
  input  io_aMergeTask_bits_task_isKeyword,
  input  [3:0] io_aMergeTask_bits_task_opcode,
  input  [2:0] io_aMergeTask_bits_task_param,
  input  [6:0] io_aMergeTask_bits_task_sourceId,
  input  io_replResp_valid,
  input  [30:0] io_replResp_bits_tag,
  input  [2:0] io_replResp_bits_way,
  input  io_replResp_bits_meta_dirty,
  input  [1:0] io_replResp_bits_meta_state,
  input  io_replResp_bits_meta_clients,
  input  [1:0] io_replResp_bits_meta_alias,
  input  io_replResp_bits_meta_prefetch,
  input  [2:0] io_replResp_bits_meta_prefetchSrc,
  input  io_replResp_bits_meta_accessed,
  input  io_replResp_bits_meta_tagErr,
  input  io_replResp_bits_meta_dataErr,
  input  [7:0] io_replResp_bits_mshrId,
  input  io_replResp_bits_retry,
  output  io_msStatus_0_valid,
  output  [2:0] io_msStatus_0_bits_channel,
  output  [8:0] io_msStatus_0_bits_set,
  output  [30:0] io_msStatus_0_bits_reqTag,
  output  io_msStatus_0_bits_is_miss,
  output  io_msStatus_0_bits_is_prefetch,
  output  io_msStatus_1_valid,
  output  [2:0] io_msStatus_1_bits_channel,
  output  [8:0] io_msStatus_1_bits_set,
  output  [30:0] io_msStatus_1_bits_reqTag,
  output  io_msStatus_1_bits_is_miss,
  output  io_msStatus_1_bits_is_prefetch,
  output  io_msStatus_2_valid,
  output  [2:0] io_msStatus_2_bits_channel,
  output  [8:0] io_msStatus_2_bits_set,
  output  [30:0] io_msStatus_2_bits_reqTag,
  output  io_msStatus_2_bits_is_miss,
  output  io_msStatus_2_bits_is_prefetch,
  output  io_msStatus_3_valid,
  output  [2:0] io_msStatus_3_bits_channel,
  output  [8:0] io_msStatus_3_bits_set,
  output  [30:0] io_msStatus_3_bits_reqTag,
  output  io_msStatus_3_bits_is_miss,
  output  io_msStatus_3_bits_is_prefetch,
  output  io_msStatus_4_valid,
  output  [2:0] io_msStatus_4_bits_channel,
  output  [8:0] io_msStatus_4_bits_set,
  output  [30:0] io_msStatus_4_bits_reqTag,
  output  io_msStatus_4_bits_is_miss,
  output  io_msStatus_4_bits_is_prefetch,
  output  io_msStatus_5_valid,
  output  [2:0] io_msStatus_5_bits_channel,
  output  [8:0] io_msStatus_5_bits_set,
  output  [30:0] io_msStatus_5_bits_reqTag,
  output  io_msStatus_5_bits_is_miss,
  output  io_msStatus_5_bits_is_prefetch,
  output  io_msStatus_6_valid,
  output  [2:0] io_msStatus_6_bits_channel,
  output  [8:0] io_msStatus_6_bits_set,
  output  [30:0] io_msStatus_6_bits_reqTag,
  output  io_msStatus_6_bits_is_miss,
  output  io_msStatus_6_bits_is_prefetch,
  output  io_msStatus_7_valid,
  output  [2:0] io_msStatus_7_bits_channel,
  output  [8:0] io_msStatus_7_bits_set,
  output  [30:0] io_msStatus_7_bits_reqTag,
  output  io_msStatus_7_bits_is_miss,
  output  io_msStatus_7_bits_is_prefetch,
  output  io_msStatus_8_valid,
  output  [2:0] io_msStatus_8_bits_channel,
  output  [8:0] io_msStatus_8_bits_set,
  output  [30:0] io_msStatus_8_bits_reqTag,
  output  io_msStatus_8_bits_is_miss,
  output  io_msStatus_8_bits_is_prefetch,
  output  io_msStatus_9_valid,
  output  [2:0] io_msStatus_9_bits_channel,
  output  [8:0] io_msStatus_9_bits_set,
  output  [30:0] io_msStatus_9_bits_reqTag,
  output  io_msStatus_9_bits_is_miss,
  output  io_msStatus_9_bits_is_prefetch,
  output  io_msStatus_10_valid,
  output  [2:0] io_msStatus_10_bits_channel,
  output  [8:0] io_msStatus_10_bits_set,
  output  [30:0] io_msStatus_10_bits_reqTag,
  output  io_msStatus_10_bits_is_miss,
  output  io_msStatus_10_bits_is_prefetch,
  output  io_msStatus_11_valid,
  output  [2:0] io_msStatus_11_bits_channel,
  output  [8:0] io_msStatus_11_bits_set,
  output  [30:0] io_msStatus_11_bits_reqTag,
  output  io_msStatus_11_bits_is_miss,
  output  io_msStatus_11_bits_is_prefetch,
  output  io_msStatus_12_valid,
  output  [2:0] io_msStatus_12_bits_channel,
  output  [8:0] io_msStatus_12_bits_set,
  output  [30:0] io_msStatus_12_bits_reqTag,
  output  io_msStatus_12_bits_is_miss,
  output  io_msStatus_12_bits_is_prefetch,
  output  io_msStatus_13_valid,
  output  [2:0] io_msStatus_13_bits_channel,
  output  [8:0] io_msStatus_13_bits_set,
  output  [30:0] io_msStatus_13_bits_reqTag,
  output  io_msStatus_13_bits_is_miss,
  output  io_msStatus_13_bits_is_prefetch,
  output  io_msStatus_14_valid,
  output  [2:0] io_msStatus_14_bits_channel,
  output  [8:0] io_msStatus_14_bits_set,
  output  [30:0] io_msStatus_14_bits_reqTag,
  output  io_msStatus_14_bits_is_miss,
  output  io_msStatus_14_bits_is_prefetch,
  output  io_msStatus_15_valid,
  output  [2:0] io_msStatus_15_bits_channel,
  output  [8:0] io_msStatus_15_bits_set,
  output  [30:0] io_msStatus_15_bits_reqTag,
  output  io_msStatus_15_bits_is_miss,
  output  io_msStatus_15_bits_is_prefetch,
  output  io_pCrd_0_query_valid,
  output  [3:0] io_pCrd_0_query_bits_pCrdType,
  output  [10:0] io_pCrd_0_query_bits_srcID,
  input  io_pCrd_0_grant,
  output  io_pCrd_1_query_valid,
  output  [3:0] io_pCrd_1_query_bits_pCrdType,
  output  [10:0] io_pCrd_1_query_bits_srcID,
  input  io_pCrd_1_grant,
  output  io_pCrd_2_query_valid,
  output  [3:0] io_pCrd_2_query_bits_pCrdType,
  output  [10:0] io_pCrd_2_query_bits_srcID,
  input  io_pCrd_2_grant,
  output  io_pCrd_3_query_valid,
  output  [3:0] io_pCrd_3_query_bits_pCrdType,
  output  [10:0] io_pCrd_3_query_bits_srcID,
  input  io_pCrd_3_grant,
  output  io_pCrd_4_query_valid,
  output  [3:0] io_pCrd_4_query_bits_pCrdType,
  output  [10:0] io_pCrd_4_query_bits_srcID,
  input  io_pCrd_4_grant,
  output  io_pCrd_5_query_valid,
  output  [3:0] io_pCrd_5_query_bits_pCrdType,
  output  [10:0] io_pCrd_5_query_bits_srcID,
  input  io_pCrd_5_grant,
  output  io_pCrd_6_query_valid,
  output  [3:0] io_pCrd_6_query_bits_pCrdType,
  output  [10:0] io_pCrd_6_query_bits_srcID,
  input  io_pCrd_6_grant,
  output  io_pCrd_7_query_valid,
  output  [3:0] io_pCrd_7_query_bits_pCrdType,
  output  [10:0] io_pCrd_7_query_bits_srcID,
  input  io_pCrd_7_grant,
  output  io_pCrd_8_query_valid,
  output  [3:0] io_pCrd_8_query_bits_pCrdType,
  output  [10:0] io_pCrd_8_query_bits_srcID,
  input  io_pCrd_8_grant,
  output  io_pCrd_9_query_valid,
  output  [3:0] io_pCrd_9_query_bits_pCrdType,
  output  [10:0] io_pCrd_9_query_bits_srcID,
  input  io_pCrd_9_grant,
  output  io_pCrd_10_query_valid,
  output  [3:0] io_pCrd_10_query_bits_pCrdType,
  output  [10:0] io_pCrd_10_query_bits_srcID,
  input  io_pCrd_10_grant,
  output  io_pCrd_11_query_valid,
  output  [3:0] io_pCrd_11_query_bits_pCrdType,
  output  [10:0] io_pCrd_11_query_bits_srcID,
  input  io_pCrd_11_grant,
  output  io_pCrd_12_query_valid,
  output  [3:0] io_pCrd_12_query_bits_pCrdType,
  output  [10:0] io_pCrd_12_query_bits_srcID,
  input  io_pCrd_12_grant,
  output  io_pCrd_13_query_valid,
  output  [3:0] io_pCrd_13_query_bits_pCrdType,
  output  [10:0] io_pCrd_13_query_bits_srcID,
  input  io_pCrd_13_grant,
  output  io_pCrd_14_query_valid,
  output  [3:0] io_pCrd_14_query_bits_pCrdType,
  output  [10:0] io_pCrd_14_query_bits_srcID,
  input  io_pCrd_14_grant,
  output  io_pCrd_15_query_valid,
  output  [3:0] io_pCrd_15_query_bits_pCrdType,
  output  [10:0] io_pCrd_15_query_bits_srcID,
  input  io_pCrd_15_grant,
  output  io_l2Miss,
  output  [5:0] io_perf_0_value,
  output  [5:0] io_perf_1_value,
  output  [5:0] io_perf_3_value
);
  assign io_toReqArb_blockA_s1 = '0;
  assign io_toReqArb_blockB_s1 = '0;
  assign io_toMainPipe_mshr_alloc_ptr = '0;
  assign io_mshrTask_valid = '0;
  assign io_mshrTask_bits_channel = '0;
  assign io_mshrTask_bits_txChannel = '0;
  assign io_mshrTask_bits_set = '0;
  assign io_mshrTask_bits_tag = '0;
  assign io_mshrTask_bits_off = '0;
  assign io_mshrTask_bits_alias = '0;
  assign io_mshrTask_bits_isKeyword = '0;
  assign io_mshrTask_bits_opcode = '0;
  assign io_mshrTask_bits_param = '0;
  assign io_mshrTask_bits_size = '0;
  assign io_mshrTask_bits_sourceId = '0;
  assign io_mshrTask_bits_denied = '0;
  assign io_mshrTask_bits_corrupt = '0;
  assign io_mshrTask_bits_mshrTask = '0;
  assign io_mshrTask_bits_mshrId = '0;
  assign io_mshrTask_bits_aliasTask = '0;
  assign io_mshrTask_bits_useProbeData = '0;
  assign io_mshrTask_bits_mshrRetry = '0;
  assign io_mshrTask_bits_readProbeDataDown = '0;
  assign io_mshrTask_bits_fromL2pft = '0;
  assign io_mshrTask_bits_dirty = '0;
  assign io_mshrTask_bits_way = '0;
  assign io_mshrTask_bits_meta_dirty = '0;
  assign io_mshrTask_bits_meta_state = '0;
  assign io_mshrTask_bits_meta_clients = '0;
  assign io_mshrTask_bits_meta_alias = '0;
  assign io_mshrTask_bits_meta_prefetch = '0;
  assign io_mshrTask_bits_meta_prefetchSrc = '0;
  assign io_mshrTask_bits_meta_accessed = '0;
  assign io_mshrTask_bits_meta_tagErr = '0;
  assign io_mshrTask_bits_meta_dataErr = '0;
  assign io_mshrTask_bits_metaWen = '0;
  assign io_mshrTask_bits_tagWen = '0;
  assign io_mshrTask_bits_dsWen = '0;
  assign io_mshrTask_bits_replTask = '0;
  assign io_mshrTask_bits_cmoTask = '0;
  assign io_mshrTask_bits_reqSource = '0;
  assign io_mshrTask_bits_mergeA = '0;
  assign io_mshrTask_bits_aMergeTask_off = '0;
  assign io_mshrTask_bits_aMergeTask_alias = '0;
  assign io_mshrTask_bits_aMergeTask_vaddr = '0;
  assign io_mshrTask_bits_aMergeTask_isKeyword = '0;
  assign io_mshrTask_bits_aMergeTask_opcode = '0;
  assign io_mshrTask_bits_aMergeTask_param = '0;
  assign io_mshrTask_bits_aMergeTask_sourceId = '0;
  assign io_mshrTask_bits_aMergeTask_meta_dirty = '0;
  assign io_mshrTask_bits_aMergeTask_meta_state = '0;
  assign io_mshrTask_bits_aMergeTask_meta_clients = '0;
  assign io_mshrTask_bits_aMergeTask_meta_alias = '0;
  assign io_mshrTask_bits_aMergeTask_meta_accessed = '0;
  assign io_mshrTask_bits_snpHitRelease = '0;
  assign io_mshrTask_bits_snpHitReleaseToInval = '0;
  assign io_mshrTask_bits_snpHitReleaseToClean = '0;
  assign io_mshrTask_bits_snpHitReleaseWithData = '0;
  assign io_mshrTask_bits_snpHitReleaseIdx = '0;
  assign io_mshrTask_bits_snpHitReleaseMeta_dirty = '0;
  assign io_mshrTask_bits_snpHitReleaseMeta_state = '0;
  assign io_mshrTask_bits_snpHitReleaseMeta_clients = '0;
  assign io_mshrTask_bits_snpHitReleaseMeta_alias = '0;
  assign io_mshrTask_bits_snpHitReleaseMeta_prefetch = '0;
  assign io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc = '0;
  assign io_mshrTask_bits_snpHitReleaseMeta_accessed = '0;
  assign io_mshrTask_bits_snpHitReleaseMeta_tagErr = '0;
  assign io_mshrTask_bits_snpHitReleaseMeta_dataErr = '0;
  assign io_mshrTask_bits_tgtID = '0;
  assign io_mshrTask_bits_txnID = '0;
  assign io_mshrTask_bits_homeNID = '0;
  assign io_mshrTask_bits_dbID = '0;
  assign io_mshrTask_bits_chiOpcode = '0;
  assign io_mshrTask_bits_resp = '0;
  assign io_mshrTask_bits_fwdState = '0;
  assign io_mshrTask_bits_retToSrc = '0;
  assign io_mshrTask_bits_likelyshared = '0;
  assign io_mshrTask_bits_expCompAck = '0;
  assign io_mshrTask_bits_allowRetry = '0;
  assign io_mshrTask_bits_memAttr_allocate = '0;
  assign io_mshrTask_bits_memAttr_cacheable = '0;
  assign io_mshrTask_bits_memAttr_ewa = '0;
  assign io_mshrTask_bits_traceTag = '0;
  assign io_mshrTask_bits_dataCheckErr = '0;
  assign io_toTXREQ_valid = '0;
  assign io_toTXREQ_bits_qos = '0;
  assign io_toTXREQ_bits_tgtID = '0;
  assign io_toTXREQ_bits_txnID = '0;
  assign io_toTXREQ_bits_opcode = '0;
  assign io_toTXREQ_bits_size = '0;
  assign io_toTXREQ_bits_addr = '0;
  assign io_toTXREQ_bits_likelyshared = '0;
  assign io_toTXREQ_bits_allowRetry = '0;
  assign io_toTXREQ_bits_pCrdType = '0;
  assign io_toTXREQ_bits_memAttr_allocate = '0;
  assign io_toTXREQ_bits_memAttr_cacheable = '0;
  assign io_toTXREQ_bits_memAttr_ewa = '0;
  assign io_toTXREQ_bits_snpAttr = '0;
  assign io_toTXREQ_bits_expCompAck = '0;
  assign io_toTXRSP_valid = '0;
  assign io_toTXRSP_bits_tgtID = '0;
  assign io_toTXRSP_bits_txnID = '0;
  assign io_toTXRSP_bits_opcode = '0;
  assign io_toTXRSP_bits_traceTag = '0;
  assign io_toSourceB_valid = '0;
  assign io_toSourceB_bits_opcode = '0;
  assign io_toSourceB_bits_param = '0;
  assign io_toSourceB_bits_address = '0;
  assign io_toSourceB_bits_data = '0;
  assign io_releaseBufWriteId = '0;
  assign io_nestedwbDataId_valid = '0;
  assign io_nestedwbDataId_bits = '0;
  assign io_msInfo_0_valid = '0;
  assign io_msInfo_0_bits_channel = '0;
  assign io_msInfo_0_bits_set = '0;
  assign io_msInfo_0_bits_way = '0;
  assign io_msInfo_0_bits_reqTag = '0;
  assign io_msInfo_0_bits_willFree = '0;
  assign io_msInfo_0_bits_aliasTask = '0;
  assign io_msInfo_0_bits_needRelease = '0;
  assign io_msInfo_0_bits_blockRefill = '0;
  assign io_msInfo_0_bits_meta_dirty = '0;
  assign io_msInfo_0_bits_meta_state = '0;
  assign io_msInfo_0_bits_meta_clients = '0;
  assign io_msInfo_0_bits_meta_alias = '0;
  assign io_msInfo_0_bits_meta_prefetch = '0;
  assign io_msInfo_0_bits_meta_prefetchSrc = '0;
  assign io_msInfo_0_bits_meta_accessed = '0;
  assign io_msInfo_0_bits_meta_tagErr = '0;
  assign io_msInfo_0_bits_meta_dataErr = '0;
  assign io_msInfo_0_bits_metaTag = '0;
  assign io_msInfo_0_bits_dirHit = '0;
  assign io_msInfo_0_bits_isAcqOrPrefetch = '0;
  assign io_msInfo_0_bits_isPrefetch = '0;
  assign io_msInfo_0_bits_param = '0;
  assign io_msInfo_0_bits_mergeA = '0;
  assign io_msInfo_0_bits_w_grantfirst = '0;
  assign io_msInfo_0_bits_s_release = '0;
  assign io_msInfo_0_bits_s_refill = '0;
  assign io_msInfo_0_bits_s_cmoresp = '0;
  assign io_msInfo_0_bits_s_cmometaw = '0;
  assign io_msInfo_0_bits_w_releaseack = '0;
  assign io_msInfo_0_bits_w_replResp = '0;
  assign io_msInfo_0_bits_w_rprobeacklast = '0;
  assign io_msInfo_0_bits_replaceData = '0;
  assign io_msInfo_0_bits_releaseToClean = '0;
  assign io_msInfo_1_valid = '0;
  assign io_msInfo_1_bits_channel = '0;
  assign io_msInfo_1_bits_set = '0;
  assign io_msInfo_1_bits_way = '0;
  assign io_msInfo_1_bits_reqTag = '0;
  assign io_msInfo_1_bits_willFree = '0;
  assign io_msInfo_1_bits_aliasTask = '0;
  assign io_msInfo_1_bits_needRelease = '0;
  assign io_msInfo_1_bits_blockRefill = '0;
  assign io_msInfo_1_bits_meta_dirty = '0;
  assign io_msInfo_1_bits_meta_state = '0;
  assign io_msInfo_1_bits_meta_clients = '0;
  assign io_msInfo_1_bits_meta_alias = '0;
  assign io_msInfo_1_bits_meta_prefetch = '0;
  assign io_msInfo_1_bits_meta_prefetchSrc = '0;
  assign io_msInfo_1_bits_meta_accessed = '0;
  assign io_msInfo_1_bits_meta_tagErr = '0;
  assign io_msInfo_1_bits_meta_dataErr = '0;
  assign io_msInfo_1_bits_metaTag = '0;
  assign io_msInfo_1_bits_dirHit = '0;
  assign io_msInfo_1_bits_isAcqOrPrefetch = '0;
  assign io_msInfo_1_bits_isPrefetch = '0;
  assign io_msInfo_1_bits_param = '0;
  assign io_msInfo_1_bits_mergeA = '0;
  assign io_msInfo_1_bits_w_grantfirst = '0;
  assign io_msInfo_1_bits_s_release = '0;
  assign io_msInfo_1_bits_s_refill = '0;
  assign io_msInfo_1_bits_s_cmoresp = '0;
  assign io_msInfo_1_bits_s_cmometaw = '0;
  assign io_msInfo_1_bits_w_releaseack = '0;
  assign io_msInfo_1_bits_w_replResp = '0;
  assign io_msInfo_1_bits_w_rprobeacklast = '0;
  assign io_msInfo_1_bits_replaceData = '0;
  assign io_msInfo_1_bits_releaseToClean = '0;
  assign io_msInfo_2_valid = '0;
  assign io_msInfo_2_bits_channel = '0;
  assign io_msInfo_2_bits_set = '0;
  assign io_msInfo_2_bits_way = '0;
  assign io_msInfo_2_bits_reqTag = '0;
  assign io_msInfo_2_bits_willFree = '0;
  assign io_msInfo_2_bits_aliasTask = '0;
  assign io_msInfo_2_bits_needRelease = '0;
  assign io_msInfo_2_bits_blockRefill = '0;
  assign io_msInfo_2_bits_meta_dirty = '0;
  assign io_msInfo_2_bits_meta_state = '0;
  assign io_msInfo_2_bits_meta_clients = '0;
  assign io_msInfo_2_bits_meta_alias = '0;
  assign io_msInfo_2_bits_meta_prefetch = '0;
  assign io_msInfo_2_bits_meta_prefetchSrc = '0;
  assign io_msInfo_2_bits_meta_accessed = '0;
  assign io_msInfo_2_bits_meta_tagErr = '0;
  assign io_msInfo_2_bits_meta_dataErr = '0;
  assign io_msInfo_2_bits_metaTag = '0;
  assign io_msInfo_2_bits_dirHit = '0;
  assign io_msInfo_2_bits_isAcqOrPrefetch = '0;
  assign io_msInfo_2_bits_isPrefetch = '0;
  assign io_msInfo_2_bits_param = '0;
  assign io_msInfo_2_bits_mergeA = '0;
  assign io_msInfo_2_bits_w_grantfirst = '0;
  assign io_msInfo_2_bits_s_release = '0;
  assign io_msInfo_2_bits_s_refill = '0;
  assign io_msInfo_2_bits_s_cmoresp = '0;
  assign io_msInfo_2_bits_s_cmometaw = '0;
  assign io_msInfo_2_bits_w_releaseack = '0;
  assign io_msInfo_2_bits_w_replResp = '0;
  assign io_msInfo_2_bits_w_rprobeacklast = '0;
  assign io_msInfo_2_bits_replaceData = '0;
  assign io_msInfo_2_bits_releaseToClean = '0;
  assign io_msInfo_3_valid = '0;
  assign io_msInfo_3_bits_channel = '0;
  assign io_msInfo_3_bits_set = '0;
  assign io_msInfo_3_bits_way = '0;
  assign io_msInfo_3_bits_reqTag = '0;
  assign io_msInfo_3_bits_willFree = '0;
  assign io_msInfo_3_bits_aliasTask = '0;
  assign io_msInfo_3_bits_needRelease = '0;
  assign io_msInfo_3_bits_blockRefill = '0;
  assign io_msInfo_3_bits_meta_dirty = '0;
  assign io_msInfo_3_bits_meta_state = '0;
  assign io_msInfo_3_bits_meta_clients = '0;
  assign io_msInfo_3_bits_meta_alias = '0;
  assign io_msInfo_3_bits_meta_prefetch = '0;
  assign io_msInfo_3_bits_meta_prefetchSrc = '0;
  assign io_msInfo_3_bits_meta_accessed = '0;
  assign io_msInfo_3_bits_meta_tagErr = '0;
  assign io_msInfo_3_bits_meta_dataErr = '0;
  assign io_msInfo_3_bits_metaTag = '0;
  assign io_msInfo_3_bits_dirHit = '0;
  assign io_msInfo_3_bits_isAcqOrPrefetch = '0;
  assign io_msInfo_3_bits_isPrefetch = '0;
  assign io_msInfo_3_bits_param = '0;
  assign io_msInfo_3_bits_mergeA = '0;
  assign io_msInfo_3_bits_w_grantfirst = '0;
  assign io_msInfo_3_bits_s_release = '0;
  assign io_msInfo_3_bits_s_refill = '0;
  assign io_msInfo_3_bits_s_cmoresp = '0;
  assign io_msInfo_3_bits_s_cmometaw = '0;
  assign io_msInfo_3_bits_w_releaseack = '0;
  assign io_msInfo_3_bits_w_replResp = '0;
  assign io_msInfo_3_bits_w_rprobeacklast = '0;
  assign io_msInfo_3_bits_replaceData = '0;
  assign io_msInfo_3_bits_releaseToClean = '0;
  assign io_msInfo_4_valid = '0;
  assign io_msInfo_4_bits_channel = '0;
  assign io_msInfo_4_bits_set = '0;
  assign io_msInfo_4_bits_way = '0;
  assign io_msInfo_4_bits_reqTag = '0;
  assign io_msInfo_4_bits_willFree = '0;
  assign io_msInfo_4_bits_aliasTask = '0;
  assign io_msInfo_4_bits_needRelease = '0;
  assign io_msInfo_4_bits_blockRefill = '0;
  assign io_msInfo_4_bits_meta_dirty = '0;
  assign io_msInfo_4_bits_meta_state = '0;
  assign io_msInfo_4_bits_meta_clients = '0;
  assign io_msInfo_4_bits_meta_alias = '0;
  assign io_msInfo_4_bits_meta_prefetch = '0;
  assign io_msInfo_4_bits_meta_prefetchSrc = '0;
  assign io_msInfo_4_bits_meta_accessed = '0;
  assign io_msInfo_4_bits_meta_tagErr = '0;
  assign io_msInfo_4_bits_meta_dataErr = '0;
  assign io_msInfo_4_bits_metaTag = '0;
  assign io_msInfo_4_bits_dirHit = '0;
  assign io_msInfo_4_bits_isAcqOrPrefetch = '0;
  assign io_msInfo_4_bits_isPrefetch = '0;
  assign io_msInfo_4_bits_param = '0;
  assign io_msInfo_4_bits_mergeA = '0;
  assign io_msInfo_4_bits_w_grantfirst = '0;
  assign io_msInfo_4_bits_s_release = '0;
  assign io_msInfo_4_bits_s_refill = '0;
  assign io_msInfo_4_bits_s_cmoresp = '0;
  assign io_msInfo_4_bits_s_cmometaw = '0;
  assign io_msInfo_4_bits_w_releaseack = '0;
  assign io_msInfo_4_bits_w_replResp = '0;
  assign io_msInfo_4_bits_w_rprobeacklast = '0;
  assign io_msInfo_4_bits_replaceData = '0;
  assign io_msInfo_4_bits_releaseToClean = '0;
  assign io_msInfo_5_valid = '0;
  assign io_msInfo_5_bits_channel = '0;
  assign io_msInfo_5_bits_set = '0;
  assign io_msInfo_5_bits_way = '0;
  assign io_msInfo_5_bits_reqTag = '0;
  assign io_msInfo_5_bits_willFree = '0;
  assign io_msInfo_5_bits_aliasTask = '0;
  assign io_msInfo_5_bits_needRelease = '0;
  assign io_msInfo_5_bits_blockRefill = '0;
  assign io_msInfo_5_bits_meta_dirty = '0;
  assign io_msInfo_5_bits_meta_state = '0;
  assign io_msInfo_5_bits_meta_clients = '0;
  assign io_msInfo_5_bits_meta_alias = '0;
  assign io_msInfo_5_bits_meta_prefetch = '0;
  assign io_msInfo_5_bits_meta_prefetchSrc = '0;
  assign io_msInfo_5_bits_meta_accessed = '0;
  assign io_msInfo_5_bits_meta_tagErr = '0;
  assign io_msInfo_5_bits_meta_dataErr = '0;
  assign io_msInfo_5_bits_metaTag = '0;
  assign io_msInfo_5_bits_dirHit = '0;
  assign io_msInfo_5_bits_isAcqOrPrefetch = '0;
  assign io_msInfo_5_bits_isPrefetch = '0;
  assign io_msInfo_5_bits_param = '0;
  assign io_msInfo_5_bits_mergeA = '0;
  assign io_msInfo_5_bits_w_grantfirst = '0;
  assign io_msInfo_5_bits_s_release = '0;
  assign io_msInfo_5_bits_s_refill = '0;
  assign io_msInfo_5_bits_s_cmoresp = '0;
  assign io_msInfo_5_bits_s_cmometaw = '0;
  assign io_msInfo_5_bits_w_releaseack = '0;
  assign io_msInfo_5_bits_w_replResp = '0;
  assign io_msInfo_5_bits_w_rprobeacklast = '0;
  assign io_msInfo_5_bits_replaceData = '0;
  assign io_msInfo_5_bits_releaseToClean = '0;
  assign io_msInfo_6_valid = '0;
  assign io_msInfo_6_bits_channel = '0;
  assign io_msInfo_6_bits_set = '0;
  assign io_msInfo_6_bits_way = '0;
  assign io_msInfo_6_bits_reqTag = '0;
  assign io_msInfo_6_bits_willFree = '0;
  assign io_msInfo_6_bits_aliasTask = '0;
  assign io_msInfo_6_bits_needRelease = '0;
  assign io_msInfo_6_bits_blockRefill = '0;
  assign io_msInfo_6_bits_meta_dirty = '0;
  assign io_msInfo_6_bits_meta_state = '0;
  assign io_msInfo_6_bits_meta_clients = '0;
  assign io_msInfo_6_bits_meta_alias = '0;
  assign io_msInfo_6_bits_meta_prefetch = '0;
  assign io_msInfo_6_bits_meta_prefetchSrc = '0;
  assign io_msInfo_6_bits_meta_accessed = '0;
  assign io_msInfo_6_bits_meta_tagErr = '0;
  assign io_msInfo_6_bits_meta_dataErr = '0;
  assign io_msInfo_6_bits_metaTag = '0;
  assign io_msInfo_6_bits_dirHit = '0;
  assign io_msInfo_6_bits_isAcqOrPrefetch = '0;
  assign io_msInfo_6_bits_isPrefetch = '0;
  assign io_msInfo_6_bits_param = '0;
  assign io_msInfo_6_bits_mergeA = '0;
  assign io_msInfo_6_bits_w_grantfirst = '0;
  assign io_msInfo_6_bits_s_release = '0;
  assign io_msInfo_6_bits_s_refill = '0;
  assign io_msInfo_6_bits_s_cmoresp = '0;
  assign io_msInfo_6_bits_s_cmometaw = '0;
  assign io_msInfo_6_bits_w_releaseack = '0;
  assign io_msInfo_6_bits_w_replResp = '0;
  assign io_msInfo_6_bits_w_rprobeacklast = '0;
  assign io_msInfo_6_bits_replaceData = '0;
  assign io_msInfo_6_bits_releaseToClean = '0;
  assign io_msInfo_7_valid = '0;
  assign io_msInfo_7_bits_channel = '0;
  assign io_msInfo_7_bits_set = '0;
  assign io_msInfo_7_bits_way = '0;
  assign io_msInfo_7_bits_reqTag = '0;
  assign io_msInfo_7_bits_willFree = '0;
  assign io_msInfo_7_bits_aliasTask = '0;
  assign io_msInfo_7_bits_needRelease = '0;
  assign io_msInfo_7_bits_blockRefill = '0;
  assign io_msInfo_7_bits_meta_dirty = '0;
  assign io_msInfo_7_bits_meta_state = '0;
  assign io_msInfo_7_bits_meta_clients = '0;
  assign io_msInfo_7_bits_meta_alias = '0;
  assign io_msInfo_7_bits_meta_prefetch = '0;
  assign io_msInfo_7_bits_meta_prefetchSrc = '0;
  assign io_msInfo_7_bits_meta_accessed = '0;
  assign io_msInfo_7_bits_meta_tagErr = '0;
  assign io_msInfo_7_bits_meta_dataErr = '0;
  assign io_msInfo_7_bits_metaTag = '0;
  assign io_msInfo_7_bits_dirHit = '0;
  assign io_msInfo_7_bits_isAcqOrPrefetch = '0;
  assign io_msInfo_7_bits_isPrefetch = '0;
  assign io_msInfo_7_bits_param = '0;
  assign io_msInfo_7_bits_mergeA = '0;
  assign io_msInfo_7_bits_w_grantfirst = '0;
  assign io_msInfo_7_bits_s_release = '0;
  assign io_msInfo_7_bits_s_refill = '0;
  assign io_msInfo_7_bits_s_cmoresp = '0;
  assign io_msInfo_7_bits_s_cmometaw = '0;
  assign io_msInfo_7_bits_w_releaseack = '0;
  assign io_msInfo_7_bits_w_replResp = '0;
  assign io_msInfo_7_bits_w_rprobeacklast = '0;
  assign io_msInfo_7_bits_replaceData = '0;
  assign io_msInfo_7_bits_releaseToClean = '0;
  assign io_msInfo_8_valid = '0;
  assign io_msInfo_8_bits_channel = '0;
  assign io_msInfo_8_bits_set = '0;
  assign io_msInfo_8_bits_way = '0;
  assign io_msInfo_8_bits_reqTag = '0;
  assign io_msInfo_8_bits_willFree = '0;
  assign io_msInfo_8_bits_aliasTask = '0;
  assign io_msInfo_8_bits_needRelease = '0;
  assign io_msInfo_8_bits_blockRefill = '0;
  assign io_msInfo_8_bits_meta_dirty = '0;
  assign io_msInfo_8_bits_meta_state = '0;
  assign io_msInfo_8_bits_meta_clients = '0;
  assign io_msInfo_8_bits_meta_alias = '0;
  assign io_msInfo_8_bits_meta_prefetch = '0;
  assign io_msInfo_8_bits_meta_prefetchSrc = '0;
  assign io_msInfo_8_bits_meta_accessed = '0;
  assign io_msInfo_8_bits_meta_tagErr = '0;
  assign io_msInfo_8_bits_meta_dataErr = '0;
  assign io_msInfo_8_bits_metaTag = '0;
  assign io_msInfo_8_bits_dirHit = '0;
  assign io_msInfo_8_bits_isAcqOrPrefetch = '0;
  assign io_msInfo_8_bits_isPrefetch = '0;
  assign io_msInfo_8_bits_param = '0;
  assign io_msInfo_8_bits_mergeA = '0;
  assign io_msInfo_8_bits_w_grantfirst = '0;
  assign io_msInfo_8_bits_s_release = '0;
  assign io_msInfo_8_bits_s_refill = '0;
  assign io_msInfo_8_bits_s_cmoresp = '0;
  assign io_msInfo_8_bits_s_cmometaw = '0;
  assign io_msInfo_8_bits_w_releaseack = '0;
  assign io_msInfo_8_bits_w_replResp = '0;
  assign io_msInfo_8_bits_w_rprobeacklast = '0;
  assign io_msInfo_8_bits_replaceData = '0;
  assign io_msInfo_8_bits_releaseToClean = '0;
  assign io_msInfo_9_valid = '0;
  assign io_msInfo_9_bits_channel = '0;
  assign io_msInfo_9_bits_set = '0;
  assign io_msInfo_9_bits_way = '0;
  assign io_msInfo_9_bits_reqTag = '0;
  assign io_msInfo_9_bits_willFree = '0;
  assign io_msInfo_9_bits_aliasTask = '0;
  assign io_msInfo_9_bits_needRelease = '0;
  assign io_msInfo_9_bits_blockRefill = '0;
  assign io_msInfo_9_bits_meta_dirty = '0;
  assign io_msInfo_9_bits_meta_state = '0;
  assign io_msInfo_9_bits_meta_clients = '0;
  assign io_msInfo_9_bits_meta_alias = '0;
  assign io_msInfo_9_bits_meta_prefetch = '0;
  assign io_msInfo_9_bits_meta_prefetchSrc = '0;
  assign io_msInfo_9_bits_meta_accessed = '0;
  assign io_msInfo_9_bits_meta_tagErr = '0;
  assign io_msInfo_9_bits_meta_dataErr = '0;
  assign io_msInfo_9_bits_metaTag = '0;
  assign io_msInfo_9_bits_dirHit = '0;
  assign io_msInfo_9_bits_isAcqOrPrefetch = '0;
  assign io_msInfo_9_bits_isPrefetch = '0;
  assign io_msInfo_9_bits_param = '0;
  assign io_msInfo_9_bits_mergeA = '0;
  assign io_msInfo_9_bits_w_grantfirst = '0;
  assign io_msInfo_9_bits_s_release = '0;
  assign io_msInfo_9_bits_s_refill = '0;
  assign io_msInfo_9_bits_s_cmoresp = '0;
  assign io_msInfo_9_bits_s_cmometaw = '0;
  assign io_msInfo_9_bits_w_releaseack = '0;
  assign io_msInfo_9_bits_w_replResp = '0;
  assign io_msInfo_9_bits_w_rprobeacklast = '0;
  assign io_msInfo_9_bits_replaceData = '0;
  assign io_msInfo_9_bits_releaseToClean = '0;
  assign io_msInfo_10_valid = '0;
  assign io_msInfo_10_bits_channel = '0;
  assign io_msInfo_10_bits_set = '0;
  assign io_msInfo_10_bits_way = '0;
  assign io_msInfo_10_bits_reqTag = '0;
  assign io_msInfo_10_bits_willFree = '0;
  assign io_msInfo_10_bits_aliasTask = '0;
  assign io_msInfo_10_bits_needRelease = '0;
  assign io_msInfo_10_bits_blockRefill = '0;
  assign io_msInfo_10_bits_meta_dirty = '0;
  assign io_msInfo_10_bits_meta_state = '0;
  assign io_msInfo_10_bits_meta_clients = '0;
  assign io_msInfo_10_bits_meta_alias = '0;
  assign io_msInfo_10_bits_meta_prefetch = '0;
  assign io_msInfo_10_bits_meta_prefetchSrc = '0;
  assign io_msInfo_10_bits_meta_accessed = '0;
  assign io_msInfo_10_bits_meta_tagErr = '0;
  assign io_msInfo_10_bits_meta_dataErr = '0;
  assign io_msInfo_10_bits_metaTag = '0;
  assign io_msInfo_10_bits_dirHit = '0;
  assign io_msInfo_10_bits_isAcqOrPrefetch = '0;
  assign io_msInfo_10_bits_isPrefetch = '0;
  assign io_msInfo_10_bits_param = '0;
  assign io_msInfo_10_bits_mergeA = '0;
  assign io_msInfo_10_bits_w_grantfirst = '0;
  assign io_msInfo_10_bits_s_release = '0;
  assign io_msInfo_10_bits_s_refill = '0;
  assign io_msInfo_10_bits_s_cmoresp = '0;
  assign io_msInfo_10_bits_s_cmometaw = '0;
  assign io_msInfo_10_bits_w_releaseack = '0;
  assign io_msInfo_10_bits_w_replResp = '0;
  assign io_msInfo_10_bits_w_rprobeacklast = '0;
  assign io_msInfo_10_bits_replaceData = '0;
  assign io_msInfo_10_bits_releaseToClean = '0;
  assign io_msInfo_11_valid = '0;
  assign io_msInfo_11_bits_channel = '0;
  assign io_msInfo_11_bits_set = '0;
  assign io_msInfo_11_bits_way = '0;
  assign io_msInfo_11_bits_reqTag = '0;
  assign io_msInfo_11_bits_willFree = '0;
  assign io_msInfo_11_bits_aliasTask = '0;
  assign io_msInfo_11_bits_needRelease = '0;
  assign io_msInfo_11_bits_blockRefill = '0;
  assign io_msInfo_11_bits_meta_dirty = '0;
  assign io_msInfo_11_bits_meta_state = '0;
  assign io_msInfo_11_bits_meta_clients = '0;
  assign io_msInfo_11_bits_meta_alias = '0;
  assign io_msInfo_11_bits_meta_prefetch = '0;
  assign io_msInfo_11_bits_meta_prefetchSrc = '0;
  assign io_msInfo_11_bits_meta_accessed = '0;
  assign io_msInfo_11_bits_meta_tagErr = '0;
  assign io_msInfo_11_bits_meta_dataErr = '0;
  assign io_msInfo_11_bits_metaTag = '0;
  assign io_msInfo_11_bits_dirHit = '0;
  assign io_msInfo_11_bits_isAcqOrPrefetch = '0;
  assign io_msInfo_11_bits_isPrefetch = '0;
  assign io_msInfo_11_bits_param = '0;
  assign io_msInfo_11_bits_mergeA = '0;
  assign io_msInfo_11_bits_w_grantfirst = '0;
  assign io_msInfo_11_bits_s_release = '0;
  assign io_msInfo_11_bits_s_refill = '0;
  assign io_msInfo_11_bits_s_cmoresp = '0;
  assign io_msInfo_11_bits_s_cmometaw = '0;
  assign io_msInfo_11_bits_w_releaseack = '0;
  assign io_msInfo_11_bits_w_replResp = '0;
  assign io_msInfo_11_bits_w_rprobeacklast = '0;
  assign io_msInfo_11_bits_replaceData = '0;
  assign io_msInfo_11_bits_releaseToClean = '0;
  assign io_msInfo_12_valid = '0;
  assign io_msInfo_12_bits_channel = '0;
  assign io_msInfo_12_bits_set = '0;
  assign io_msInfo_12_bits_way = '0;
  assign io_msInfo_12_bits_reqTag = '0;
  assign io_msInfo_12_bits_willFree = '0;
  assign io_msInfo_12_bits_aliasTask = '0;
  assign io_msInfo_12_bits_needRelease = '0;
  assign io_msInfo_12_bits_blockRefill = '0;
  assign io_msInfo_12_bits_meta_dirty = '0;
  assign io_msInfo_12_bits_meta_state = '0;
  assign io_msInfo_12_bits_meta_clients = '0;
  assign io_msInfo_12_bits_meta_alias = '0;
  assign io_msInfo_12_bits_meta_prefetch = '0;
  assign io_msInfo_12_bits_meta_prefetchSrc = '0;
  assign io_msInfo_12_bits_meta_accessed = '0;
  assign io_msInfo_12_bits_meta_tagErr = '0;
  assign io_msInfo_12_bits_meta_dataErr = '0;
  assign io_msInfo_12_bits_metaTag = '0;
  assign io_msInfo_12_bits_dirHit = '0;
  assign io_msInfo_12_bits_isAcqOrPrefetch = '0;
  assign io_msInfo_12_bits_isPrefetch = '0;
  assign io_msInfo_12_bits_param = '0;
  assign io_msInfo_12_bits_mergeA = '0;
  assign io_msInfo_12_bits_w_grantfirst = '0;
  assign io_msInfo_12_bits_s_release = '0;
  assign io_msInfo_12_bits_s_refill = '0;
  assign io_msInfo_12_bits_s_cmoresp = '0;
  assign io_msInfo_12_bits_s_cmometaw = '0;
  assign io_msInfo_12_bits_w_releaseack = '0;
  assign io_msInfo_12_bits_w_replResp = '0;
  assign io_msInfo_12_bits_w_rprobeacklast = '0;
  assign io_msInfo_12_bits_replaceData = '0;
  assign io_msInfo_12_bits_releaseToClean = '0;
  assign io_msInfo_13_valid = '0;
  assign io_msInfo_13_bits_channel = '0;
  assign io_msInfo_13_bits_set = '0;
  assign io_msInfo_13_bits_way = '0;
  assign io_msInfo_13_bits_reqTag = '0;
  assign io_msInfo_13_bits_willFree = '0;
  assign io_msInfo_13_bits_aliasTask = '0;
  assign io_msInfo_13_bits_needRelease = '0;
  assign io_msInfo_13_bits_blockRefill = '0;
  assign io_msInfo_13_bits_meta_dirty = '0;
  assign io_msInfo_13_bits_meta_state = '0;
  assign io_msInfo_13_bits_meta_clients = '0;
  assign io_msInfo_13_bits_meta_alias = '0;
  assign io_msInfo_13_bits_meta_prefetch = '0;
  assign io_msInfo_13_bits_meta_prefetchSrc = '0;
  assign io_msInfo_13_bits_meta_accessed = '0;
  assign io_msInfo_13_bits_meta_tagErr = '0;
  assign io_msInfo_13_bits_meta_dataErr = '0;
  assign io_msInfo_13_bits_metaTag = '0;
  assign io_msInfo_13_bits_dirHit = '0;
  assign io_msInfo_13_bits_isAcqOrPrefetch = '0;
  assign io_msInfo_13_bits_isPrefetch = '0;
  assign io_msInfo_13_bits_param = '0;
  assign io_msInfo_13_bits_mergeA = '0;
  assign io_msInfo_13_bits_w_grantfirst = '0;
  assign io_msInfo_13_bits_s_release = '0;
  assign io_msInfo_13_bits_s_refill = '0;
  assign io_msInfo_13_bits_s_cmoresp = '0;
  assign io_msInfo_13_bits_s_cmometaw = '0;
  assign io_msInfo_13_bits_w_releaseack = '0;
  assign io_msInfo_13_bits_w_replResp = '0;
  assign io_msInfo_13_bits_w_rprobeacklast = '0;
  assign io_msInfo_13_bits_replaceData = '0;
  assign io_msInfo_13_bits_releaseToClean = '0;
  assign io_msInfo_14_valid = '0;
  assign io_msInfo_14_bits_channel = '0;
  assign io_msInfo_14_bits_set = '0;
  assign io_msInfo_14_bits_way = '0;
  assign io_msInfo_14_bits_reqTag = '0;
  assign io_msInfo_14_bits_willFree = '0;
  assign io_msInfo_14_bits_aliasTask = '0;
  assign io_msInfo_14_bits_needRelease = '0;
  assign io_msInfo_14_bits_blockRefill = '0;
  assign io_msInfo_14_bits_meta_dirty = '0;
  assign io_msInfo_14_bits_meta_state = '0;
  assign io_msInfo_14_bits_meta_clients = '0;
  assign io_msInfo_14_bits_meta_alias = '0;
  assign io_msInfo_14_bits_meta_prefetch = '0;
  assign io_msInfo_14_bits_meta_prefetchSrc = '0;
  assign io_msInfo_14_bits_meta_accessed = '0;
  assign io_msInfo_14_bits_meta_tagErr = '0;
  assign io_msInfo_14_bits_meta_dataErr = '0;
  assign io_msInfo_14_bits_metaTag = '0;
  assign io_msInfo_14_bits_dirHit = '0;
  assign io_msInfo_14_bits_isAcqOrPrefetch = '0;
  assign io_msInfo_14_bits_isPrefetch = '0;
  assign io_msInfo_14_bits_param = '0;
  assign io_msInfo_14_bits_mergeA = '0;
  assign io_msInfo_14_bits_w_grantfirst = '0;
  assign io_msInfo_14_bits_s_release = '0;
  assign io_msInfo_14_bits_s_refill = '0;
  assign io_msInfo_14_bits_s_cmoresp = '0;
  assign io_msInfo_14_bits_s_cmometaw = '0;
  assign io_msInfo_14_bits_w_releaseack = '0;
  assign io_msInfo_14_bits_w_replResp = '0;
  assign io_msInfo_14_bits_w_rprobeacklast = '0;
  assign io_msInfo_14_bits_replaceData = '0;
  assign io_msInfo_14_bits_releaseToClean = '0;
  assign io_msInfo_15_valid = '0;
  assign io_msInfo_15_bits_channel = '0;
  assign io_msInfo_15_bits_set = '0;
  assign io_msInfo_15_bits_way = '0;
  assign io_msInfo_15_bits_reqTag = '0;
  assign io_msInfo_15_bits_willFree = '0;
  assign io_msInfo_15_bits_aliasTask = '0;
  assign io_msInfo_15_bits_needRelease = '0;
  assign io_msInfo_15_bits_blockRefill = '0;
  assign io_msInfo_15_bits_meta_dirty = '0;
  assign io_msInfo_15_bits_meta_state = '0;
  assign io_msInfo_15_bits_meta_clients = '0;
  assign io_msInfo_15_bits_meta_alias = '0;
  assign io_msInfo_15_bits_meta_prefetch = '0;
  assign io_msInfo_15_bits_meta_prefetchSrc = '0;
  assign io_msInfo_15_bits_meta_accessed = '0;
  assign io_msInfo_15_bits_meta_tagErr = '0;
  assign io_msInfo_15_bits_meta_dataErr = '0;
  assign io_msInfo_15_bits_metaTag = '0;
  assign io_msInfo_15_bits_dirHit = '0;
  assign io_msInfo_15_bits_isAcqOrPrefetch = '0;
  assign io_msInfo_15_bits_isPrefetch = '0;
  assign io_msInfo_15_bits_param = '0;
  assign io_msInfo_15_bits_mergeA = '0;
  assign io_msInfo_15_bits_w_grantfirst = '0;
  assign io_msInfo_15_bits_s_release = '0;
  assign io_msInfo_15_bits_s_refill = '0;
  assign io_msInfo_15_bits_s_cmoresp = '0;
  assign io_msInfo_15_bits_s_cmometaw = '0;
  assign io_msInfo_15_bits_w_releaseack = '0;
  assign io_msInfo_15_bits_w_replResp = '0;
  assign io_msInfo_15_bits_w_rprobeacklast = '0;
  assign io_msInfo_15_bits_replaceData = '0;
  assign io_msInfo_15_bits_releaseToClean = '0;
  assign io_msStatus_0_valid = '0;
  assign io_msStatus_0_bits_channel = '0;
  assign io_msStatus_0_bits_set = '0;
  assign io_msStatus_0_bits_reqTag = '0;
  assign io_msStatus_0_bits_is_miss = '0;
  assign io_msStatus_0_bits_is_prefetch = '0;
  assign io_msStatus_1_valid = '0;
  assign io_msStatus_1_bits_channel = '0;
  assign io_msStatus_1_bits_set = '0;
  assign io_msStatus_1_bits_reqTag = '0;
  assign io_msStatus_1_bits_is_miss = '0;
  assign io_msStatus_1_bits_is_prefetch = '0;
  assign io_msStatus_2_valid = '0;
  assign io_msStatus_2_bits_channel = '0;
  assign io_msStatus_2_bits_set = '0;
  assign io_msStatus_2_bits_reqTag = '0;
  assign io_msStatus_2_bits_is_miss = '0;
  assign io_msStatus_2_bits_is_prefetch = '0;
  assign io_msStatus_3_valid = '0;
  assign io_msStatus_3_bits_channel = '0;
  assign io_msStatus_3_bits_set = '0;
  assign io_msStatus_3_bits_reqTag = '0;
  assign io_msStatus_3_bits_is_miss = '0;
  assign io_msStatus_3_bits_is_prefetch = '0;
  assign io_msStatus_4_valid = '0;
  assign io_msStatus_4_bits_channel = '0;
  assign io_msStatus_4_bits_set = '0;
  assign io_msStatus_4_bits_reqTag = '0;
  assign io_msStatus_4_bits_is_miss = '0;
  assign io_msStatus_4_bits_is_prefetch = '0;
  assign io_msStatus_5_valid = '0;
  assign io_msStatus_5_bits_channel = '0;
  assign io_msStatus_5_bits_set = '0;
  assign io_msStatus_5_bits_reqTag = '0;
  assign io_msStatus_5_bits_is_miss = '0;
  assign io_msStatus_5_bits_is_prefetch = '0;
  assign io_msStatus_6_valid = '0;
  assign io_msStatus_6_bits_channel = '0;
  assign io_msStatus_6_bits_set = '0;
  assign io_msStatus_6_bits_reqTag = '0;
  assign io_msStatus_6_bits_is_miss = '0;
  assign io_msStatus_6_bits_is_prefetch = '0;
  assign io_msStatus_7_valid = '0;
  assign io_msStatus_7_bits_channel = '0;
  assign io_msStatus_7_bits_set = '0;
  assign io_msStatus_7_bits_reqTag = '0;
  assign io_msStatus_7_bits_is_miss = '0;
  assign io_msStatus_7_bits_is_prefetch = '0;
  assign io_msStatus_8_valid = '0;
  assign io_msStatus_8_bits_channel = '0;
  assign io_msStatus_8_bits_set = '0;
  assign io_msStatus_8_bits_reqTag = '0;
  assign io_msStatus_8_bits_is_miss = '0;
  assign io_msStatus_8_bits_is_prefetch = '0;
  assign io_msStatus_9_valid = '0;
  assign io_msStatus_9_bits_channel = '0;
  assign io_msStatus_9_bits_set = '0;
  assign io_msStatus_9_bits_reqTag = '0;
  assign io_msStatus_9_bits_is_miss = '0;
  assign io_msStatus_9_bits_is_prefetch = '0;
  assign io_msStatus_10_valid = '0;
  assign io_msStatus_10_bits_channel = '0;
  assign io_msStatus_10_bits_set = '0;
  assign io_msStatus_10_bits_reqTag = '0;
  assign io_msStatus_10_bits_is_miss = '0;
  assign io_msStatus_10_bits_is_prefetch = '0;
  assign io_msStatus_11_valid = '0;
  assign io_msStatus_11_bits_channel = '0;
  assign io_msStatus_11_bits_set = '0;
  assign io_msStatus_11_bits_reqTag = '0;
  assign io_msStatus_11_bits_is_miss = '0;
  assign io_msStatus_11_bits_is_prefetch = '0;
  assign io_msStatus_12_valid = '0;
  assign io_msStatus_12_bits_channel = '0;
  assign io_msStatus_12_bits_set = '0;
  assign io_msStatus_12_bits_reqTag = '0;
  assign io_msStatus_12_bits_is_miss = '0;
  assign io_msStatus_12_bits_is_prefetch = '0;
  assign io_msStatus_13_valid = '0;
  assign io_msStatus_13_bits_channel = '0;
  assign io_msStatus_13_bits_set = '0;
  assign io_msStatus_13_bits_reqTag = '0;
  assign io_msStatus_13_bits_is_miss = '0;
  assign io_msStatus_13_bits_is_prefetch = '0;
  assign io_msStatus_14_valid = '0;
  assign io_msStatus_14_bits_channel = '0;
  assign io_msStatus_14_bits_set = '0;
  assign io_msStatus_14_bits_reqTag = '0;
  assign io_msStatus_14_bits_is_miss = '0;
  assign io_msStatus_14_bits_is_prefetch = '0;
  assign io_msStatus_15_valid = '0;
  assign io_msStatus_15_bits_channel = '0;
  assign io_msStatus_15_bits_set = '0;
  assign io_msStatus_15_bits_reqTag = '0;
  assign io_msStatus_15_bits_is_miss = '0;
  assign io_msStatus_15_bits_is_prefetch = '0;
  assign io_pCrd_0_query_valid = '0;
  assign io_pCrd_0_query_bits_pCrdType = '0;
  assign io_pCrd_0_query_bits_srcID = '0;
  assign io_pCrd_1_query_valid = '0;
  assign io_pCrd_1_query_bits_pCrdType = '0;
  assign io_pCrd_1_query_bits_srcID = '0;
  assign io_pCrd_2_query_valid = '0;
  assign io_pCrd_2_query_bits_pCrdType = '0;
  assign io_pCrd_2_query_bits_srcID = '0;
  assign io_pCrd_3_query_valid = '0;
  assign io_pCrd_3_query_bits_pCrdType = '0;
  assign io_pCrd_3_query_bits_srcID = '0;
  assign io_pCrd_4_query_valid = '0;
  assign io_pCrd_4_query_bits_pCrdType = '0;
  assign io_pCrd_4_query_bits_srcID = '0;
  assign io_pCrd_5_query_valid = '0;
  assign io_pCrd_5_query_bits_pCrdType = '0;
  assign io_pCrd_5_query_bits_srcID = '0;
  assign io_pCrd_6_query_valid = '0;
  assign io_pCrd_6_query_bits_pCrdType = '0;
  assign io_pCrd_6_query_bits_srcID = '0;
  assign io_pCrd_7_query_valid = '0;
  assign io_pCrd_7_query_bits_pCrdType = '0;
  assign io_pCrd_7_query_bits_srcID = '0;
  assign io_pCrd_8_query_valid = '0;
  assign io_pCrd_8_query_bits_pCrdType = '0;
  assign io_pCrd_8_query_bits_srcID = '0;
  assign io_pCrd_9_query_valid = '0;
  assign io_pCrd_9_query_bits_pCrdType = '0;
  assign io_pCrd_9_query_bits_srcID = '0;
  assign io_pCrd_10_query_valid = '0;
  assign io_pCrd_10_query_bits_pCrdType = '0;
  assign io_pCrd_10_query_bits_srcID = '0;
  assign io_pCrd_11_query_valid = '0;
  assign io_pCrd_11_query_bits_pCrdType = '0;
  assign io_pCrd_11_query_bits_srcID = '0;
  assign io_pCrd_12_query_valid = '0;
  assign io_pCrd_12_query_bits_pCrdType = '0;
  assign io_pCrd_12_query_bits_srcID = '0;
  assign io_pCrd_13_query_valid = '0;
  assign io_pCrd_13_query_bits_pCrdType = '0;
  assign io_pCrd_13_query_bits_srcID = '0;
  assign io_pCrd_14_query_valid = '0;
  assign io_pCrd_14_query_bits_pCrdType = '0;
  assign io_pCrd_14_query_bits_srcID = '0;
  assign io_pCrd_15_query_valid = '0;
  assign io_pCrd_15_query_bits_pCrdType = '0;
  assign io_pCrd_15_query_bits_srcID = '0;
  assign io_l2Miss = '0;
  assign io_perf_0_value = '0;
  assign io_perf_1_value = '0;
  assign io_perf_3_value = '0;
endmodule

module MainPipe_1(
  input  clock,
  input  reset,
  input  io_taskFromArb_s2_valid,
  input  [2:0] io_taskFromArb_s2_bits_channel,
  input  [2:0] io_taskFromArb_s2_bits_txChannel,
  input  [8:0] io_taskFromArb_s2_bits_set,
  input  [30:0] io_taskFromArb_s2_bits_tag,
  input  [5:0] io_taskFromArb_s2_bits_off,
  input  [1:0] io_taskFromArb_s2_bits_alias,
  input  [43:0] io_taskFromArb_s2_bits_vaddr,
  input  io_taskFromArb_s2_bits_isKeyword,
  input  [3:0] io_taskFromArb_s2_bits_opcode,
  input  [2:0] io_taskFromArb_s2_bits_param,
  input  [2:0] io_taskFromArb_s2_bits_size,
  input  [6:0] io_taskFromArb_s2_bits_sourceId,
  input  [1:0] io_taskFromArb_s2_bits_bufIdx,
  input  io_taskFromArb_s2_bits_needProbeAckData,
  input  io_taskFromArb_s2_bits_denied,
  input  io_taskFromArb_s2_bits_corrupt,
  input  io_taskFromArb_s2_bits_mshrTask,
  input  [7:0] io_taskFromArb_s2_bits_mshrId,
  input  io_taskFromArb_s2_bits_aliasTask,
  input  io_taskFromArb_s2_bits_useProbeData,
  input  io_taskFromArb_s2_bits_mshrRetry,
  input  io_taskFromArb_s2_bits_readProbeDataDown,
  input  io_taskFromArb_s2_bits_fromL2pft,
  input  io_taskFromArb_s2_bits_needHint,
  input  io_taskFromArb_s2_bits_dirty,
  input  [2:0] io_taskFromArb_s2_bits_way,
  input  io_taskFromArb_s2_bits_meta_dirty,
  input  [1:0] io_taskFromArb_s2_bits_meta_state,
  input  io_taskFromArb_s2_bits_meta_clients,
  input  [1:0] io_taskFromArb_s2_bits_meta_alias,
  input  io_taskFromArb_s2_bits_meta_prefetch,
  input  [2:0] io_taskFromArb_s2_bits_meta_prefetchSrc,
  input  io_taskFromArb_s2_bits_meta_accessed,
  input  io_taskFromArb_s2_bits_meta_tagErr,
  input  io_taskFromArb_s2_bits_meta_dataErr,
  input  io_taskFromArb_s2_bits_metaWen,
  input  io_taskFromArb_s2_bits_tagWen,
  input  io_taskFromArb_s2_bits_dsWen,
  input  [7:0] io_taskFromArb_s2_bits_wayMask,
  input  io_taskFromArb_s2_bits_replTask,
  input  io_taskFromArb_s2_bits_cmoTask,
  input  io_taskFromArb_s2_bits_cmoAll,
  input  [4:0] io_taskFromArb_s2_bits_reqSource,
  input  io_taskFromArb_s2_bits_mergeA,
  input  [5:0] io_taskFromArb_s2_bits_aMergeTask_off,
  input  [1:0] io_taskFromArb_s2_bits_aMergeTask_alias,
  input  [43:0] io_taskFromArb_s2_bits_aMergeTask_vaddr,
  input  io_taskFromArb_s2_bits_aMergeTask_isKeyword,
  input  [2:0] io_taskFromArb_s2_bits_aMergeTask_opcode,
  input  [2:0] io_taskFromArb_s2_bits_aMergeTask_param,
  input  [6:0] io_taskFromArb_s2_bits_aMergeTask_sourceId,
  input  io_taskFromArb_s2_bits_aMergeTask_meta_dirty,
  input  [1:0] io_taskFromArb_s2_bits_aMergeTask_meta_state,
  input  io_taskFromArb_s2_bits_aMergeTask_meta_clients,
  input  [1:0] io_taskFromArb_s2_bits_aMergeTask_meta_alias,
  input  io_taskFromArb_s2_bits_aMergeTask_meta_prefetch,
  input  [2:0] io_taskFromArb_s2_bits_aMergeTask_meta_prefetchSrc,
  input  io_taskFromArb_s2_bits_aMergeTask_meta_accessed,
  input  io_taskFromArb_s2_bits_aMergeTask_meta_tagErr,
  input  io_taskFromArb_s2_bits_aMergeTask_meta_dataErr,
  input  io_taskFromArb_s2_bits_snpHitRelease,
  input  io_taskFromArb_s2_bits_snpHitReleaseToInval,
  input  io_taskFromArb_s2_bits_snpHitReleaseToClean,
  input  io_taskFromArb_s2_bits_snpHitReleaseWithData,
  input  [7:0] io_taskFromArb_s2_bits_snpHitReleaseIdx,
  input  io_taskFromArb_s2_bits_snpHitReleaseMeta_dirty,
  input  [1:0] io_taskFromArb_s2_bits_snpHitReleaseMeta_state,
  input  io_taskFromArb_s2_bits_snpHitReleaseMeta_clients,
  input  [1:0] io_taskFromArb_s2_bits_snpHitReleaseMeta_alias,
  input  io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetch,
  input  [2:0] io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetchSrc,
  input  io_taskFromArb_s2_bits_snpHitReleaseMeta_accessed,
  input  io_taskFromArb_s2_bits_snpHitReleaseMeta_tagErr,
  input  io_taskFromArb_s2_bits_snpHitReleaseMeta_dataErr,
  input  [10:0] io_taskFromArb_s2_bits_tgtID,
  input  [10:0] io_taskFromArb_s2_bits_srcID,
  input  [11:0] io_taskFromArb_s2_bits_txnID,
  input  [10:0] io_taskFromArb_s2_bits_homeNID,
  input  [11:0] io_taskFromArb_s2_bits_dbID,
  input  [10:0] io_taskFromArb_s2_bits_fwdNID,
  input  [11:0] io_taskFromArb_s2_bits_fwdTxnID,
  input  [6:0] io_taskFromArb_s2_bits_chiOpcode,
  input  [2:0] io_taskFromArb_s2_bits_resp,
  input  [2:0] io_taskFromArb_s2_bits_fwdState,
  input  [3:0] io_taskFromArb_s2_bits_pCrdType,
  input  io_taskFromArb_s2_bits_retToSrc,
  input  io_taskFromArb_s2_bits_likelyshared,
  input  io_taskFromArb_s2_bits_expCompAck,
  input  io_taskFromArb_s2_bits_allowRetry,
  input  io_taskFromArb_s2_bits_memAttr_allocate,
  input  io_taskFromArb_s2_bits_memAttr_cacheable,
  input  io_taskFromArb_s2_bits_memAttr_device,
  input  io_taskFromArb_s2_bits_memAttr_ewa,
  input  io_taskFromArb_s2_bits_traceTag,
  input  io_taskFromArb_s2_bits_dataCheckErr,
  input  io_taskInfo_s1_valid,
  input  [2:0] io_taskInfo_s1_bits_channel,
  input  io_taskInfo_s1_bits_isKeyword,
  input  [3:0] io_taskInfo_s1_bits_opcode,
  input  [6:0] io_taskInfo_s1_bits_sourceId,
  input  io_taskInfo_s1_bits_mshrTask,
  input  io_taskInfo_s1_bits_mergeA,
  input  io_taskInfo_s1_bits_aMergeTask_isKeyword,
  input  [2:0] io_taskInfo_s1_bits_aMergeTask_opcode,
  input  [6:0] io_taskInfo_s1_bits_aMergeTask_sourceId,
  input  [30:0] io_fromReqArb_status_s1_tags_1,
  input  [8:0] io_fromReqArb_status_s1_sets_0,
  input  [8:0] io_fromReqArb_status_s1_sets_1,
  input  [8:0] io_fromReqArb_status_s1_sets_2,
  input  [8:0] io_fromReqArb_status_s1_sets_3,
  output  io_toReqArb_blockG_s1,
  output  io_toReqArb_blockB_s1,
  output  io_toReqArb_blockC_s1,
  output  io_toReqBuf_0,
  output  io_toReqBuf_1,
  output  io_status_vec_toD_0_valid,
  output  [2:0] io_status_vec_toD_0_bits_channel,
  output  io_status_vec_toD_1_valid,
  output  [2:0] io_status_vec_toD_1_bits_channel,
  output  io_status_vec_toD_2_valid,
  output  [2:0] io_status_vec_toD_2_bits_channel,
  output  io_status_vec_toTX_0_valid,
  output  [2:0] io_status_vec_toTX_0_bits_channel,
  output  [2:0] io_status_vec_toTX_0_bits_txChannel,
  output  io_status_vec_toTX_0_bits_mshrTask,
  output  io_status_vec_toTX_1_valid,
  output  [2:0] io_status_vec_toTX_1_bits_channel,
  output  [2:0] io_status_vec_toTX_1_bits_txChannel,
  output  io_status_vec_toTX_1_bits_mshrTask,
  output  io_status_vec_toTX_2_valid,
  output  [2:0] io_status_vec_toTX_2_bits_channel,
  output  [2:0] io_status_vec_toTX_2_bits_txChannel,
  output  io_status_vec_toTX_2_bits_mshrTask,
  input  io_dirResp_s3_hit,
  input  [30:0] io_dirResp_s3_tag,
  input  [8:0] io_dirResp_s3_set,
  input  [2:0] io_dirResp_s3_way,
  input  io_dirResp_s3_meta_dirty,
  input  [1:0] io_dirResp_s3_meta_state,
  input  io_dirResp_s3_meta_clients,
  input  [1:0] io_dirResp_s3_meta_alias,
  input  io_dirResp_s3_meta_prefetch,
  input  [2:0] io_dirResp_s3_meta_prefetchSrc,
  input  io_dirResp_s3_meta_accessed,
  input  io_dirResp_s3_meta_tagErr,
  input  io_dirResp_s3_meta_dataErr,
  input  io_dirResp_s3_error,
  input  io_replResp_valid,
  input  [2:0] io_replResp_bits_way,
  input  [1:0] io_replResp_bits_meta_state,
  input  io_replResp_bits_retry,
  output  io_toMSHRCtl_mshr_alloc_s3_valid,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_hit,
  output  [30:0] io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_tag,
  output  [8:0] io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_set,
  output  [2:0] io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_way,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dirty,
  output  [1:0] io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_state,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_clients,
  output  [1:0] io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_alias,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetch,
  output  [2:0] io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_accessed,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_tagErr,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dataErr,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_error,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_state_s_acquire,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rprobe,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_state_s_pprobe,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_state_s_release,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_state_s_probeack,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_state_s_refill,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_state_s_cmoresp,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeackfirst,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeacklast,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeackfirst,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeacklast,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantfirst,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantlast,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grant,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_state_w_releaseack,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_state_w_replResp,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rcompack,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_state_s_dct,
  output  [2:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_channel,
  output  [8:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_set,
  output  [30:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_tag,
  output  [5:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_off,
  output  [1:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_alias,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_task_isKeyword,
  output  [3:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_opcode,
  output  [2:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_param,
  output  [6:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_sourceId,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_task_aliasTask,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_task_fromL2pft,
  output  [4:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_reqSource,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitRelease,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToInval,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToClean,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseWithData,
  output  [7:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseIdx,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty,
  output  [1:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients,
  output  [1:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch,
  output  [2:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr,
  output  [10:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_srcID,
  output  [11:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_txnID,
  output  [10:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdNID,
  output  [11:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdTxnID,
  output  [6:0] io_toMSHRCtl_mshr_alloc_s3_bits_task_chiOpcode,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_task_retToSrc,
  output  io_toMSHRCtl_mshr_alloc_s3_bits_task_traceTag,
  input  [7:0] io_fromMSHRCtl_mshr_alloc_ptr,
  input  [255:0] io_bufResp_data_0,
  input  [255:0] io_bufResp_data_1,
  input  [511:0] io_refillBufResp_s3_bits_data,
  input  io_releaseBufResp_s3_valid,
  input  [511:0] io_releaseBufResp_s3_bits_data,
  output  io_toDS_en_s3,
  output  io_toDS_req_s3_valid,
  output  [2:0] io_toDS_req_s3_bits_way,
  output  [8:0] io_toDS_req_s3_bits_set,
  output  io_toDS_req_s3_bits_wen,
  input  [511:0] io_toDS_rdata_s5_data,
  output  [511:0] io_toDS_wdata_s3_data,
  input  io_toDS_error_s5,
  output  io_toSourceD_valid,
  output  [2:0] io_toSourceD_bits_task_channel,
  output  [2:0] io_toSourceD_bits_task_txChannel,
  output  [8:0] io_toSourceD_bits_task_set,
  output  [30:0] io_toSourceD_bits_task_tag,
  output  [5:0] io_toSourceD_bits_task_off,
  output  [1:0] io_toSourceD_bits_task_alias,
  output  [43:0] io_toSourceD_bits_task_vaddr,
  output  io_toSourceD_bits_task_isKeyword,
  output  [3:0] io_toSourceD_bits_task_opcode,
  output  [2:0] io_toSourceD_bits_task_param,
  output  [2:0] io_toSourceD_bits_task_size,
  output  [6:0] io_toSourceD_bits_task_sourceId,
  output  [1:0] io_toSourceD_bits_task_bufIdx,
  output  io_toSourceD_bits_task_needProbeAckData,
  output  io_toSourceD_bits_task_denied,
  output  io_toSourceD_bits_task_corrupt,
  output  io_toSourceD_bits_task_mshrTask,
  output  [7:0] io_toSourceD_bits_task_mshrId,
  output  io_toSourceD_bits_task_aliasTask,
  output  io_toSourceD_bits_task_useProbeData,
  output  io_toSourceD_bits_task_mshrRetry,
  output  io_toSourceD_bits_task_readProbeDataDown,
  output  io_toSourceD_bits_task_fromL2pft,
  output  io_toSourceD_bits_task_needHint,
  output  io_toSourceD_bits_task_dirty,
  output  [2:0] io_toSourceD_bits_task_way,
  output  io_toSourceD_bits_task_meta_dirty,
  output  [1:0] io_toSourceD_bits_task_meta_state,
  output  io_toSourceD_bits_task_meta_clients,
  output  [1:0] io_toSourceD_bits_task_meta_alias,
  output  io_toSourceD_bits_task_meta_prefetch,
  output  [2:0] io_toSourceD_bits_task_meta_prefetchSrc,
  output  io_toSourceD_bits_task_meta_accessed,
  output  io_toSourceD_bits_task_meta_tagErr,
  output  io_toSourceD_bits_task_meta_dataErr,
  output  io_toSourceD_bits_task_metaWen,
  output  io_toSourceD_bits_task_tagWen,
  output  io_toSourceD_bits_task_dsWen,
  output  [7:0] io_toSourceD_bits_task_wayMask,
  output  io_toSourceD_bits_task_replTask,
  output  io_toSourceD_bits_task_cmoTask,
  output  io_toSourceD_bits_task_cmoAll,
  output  [4:0] io_toSourceD_bits_task_reqSource,
  output  io_toSourceD_bits_task_mergeA,
  output  [5:0] io_toSourceD_bits_task_aMergeTask_off,
  output  [1:0] io_toSourceD_bits_task_aMergeTask_alias,
  output  [43:0] io_toSourceD_bits_task_aMergeTask_vaddr,
  output  io_toSourceD_bits_task_aMergeTask_isKeyword,
  output  [2:0] io_toSourceD_bits_task_aMergeTask_opcode,
  output  [2:0] io_toSourceD_bits_task_aMergeTask_param,
  output  [6:0] io_toSourceD_bits_task_aMergeTask_sourceId,
  output  io_toSourceD_bits_task_aMergeTask_meta_dirty,
  output  [1:0] io_toSourceD_bits_task_aMergeTask_meta_state,
  output  io_toSourceD_bits_task_aMergeTask_meta_clients,
  output  [1:0] io_toSourceD_bits_task_aMergeTask_meta_alias,
  output  io_toSourceD_bits_task_aMergeTask_meta_prefetch,
  output  [2:0] io_toSourceD_bits_task_aMergeTask_meta_prefetchSrc,
  output  io_toSourceD_bits_task_aMergeTask_meta_accessed,
  output  io_toSourceD_bits_task_aMergeTask_meta_tagErr,
  output  io_toSourceD_bits_task_aMergeTask_meta_dataErr,
  output  io_toSourceD_bits_task_snpHitRelease,
  output  io_toSourceD_bits_task_snpHitReleaseToInval,
  output  io_toSourceD_bits_task_snpHitReleaseToClean,
  output  io_toSourceD_bits_task_snpHitReleaseWithData,
  output  [7:0] io_toSourceD_bits_task_snpHitReleaseIdx,
  output  io_toSourceD_bits_task_snpHitReleaseMeta_dirty,
  output  [1:0] io_toSourceD_bits_task_snpHitReleaseMeta_state,
  output  io_toSourceD_bits_task_snpHitReleaseMeta_clients,
  output  [1:0] io_toSourceD_bits_task_snpHitReleaseMeta_alias,
  output  io_toSourceD_bits_task_snpHitReleaseMeta_prefetch,
  output  [2:0] io_toSourceD_bits_task_snpHitReleaseMeta_prefetchSrc,
  output  io_toSourceD_bits_task_snpHitReleaseMeta_accessed,
  output  io_toSourceD_bits_task_snpHitReleaseMeta_tagErr,
  output  io_toSourceD_bits_task_snpHitReleaseMeta_dataErr,
  output  [10:0] io_toSourceD_bits_task_tgtID,
  output  [10:0] io_toSourceD_bits_task_srcID,
  output  [11:0] io_toSourceD_bits_task_txnID,
  output  [10:0] io_toSourceD_bits_task_homeNID,
  output  [11:0] io_toSourceD_bits_task_dbID,
  output  [10:0] io_toSourceD_bits_task_fwdNID,
  output  [11:0] io_toSourceD_bits_task_fwdTxnID,
  output  [6:0] io_toSourceD_bits_task_chiOpcode,
  output  [2:0] io_toSourceD_bits_task_resp,
  output  [2:0] io_toSourceD_bits_task_fwdState,
  output  [3:0] io_toSourceD_bits_task_pCrdType,
  output  io_toSourceD_bits_task_retToSrc,
  output  io_toSourceD_bits_task_likelyshared,
  output  io_toSourceD_bits_task_expCompAck,
  output  io_toSourceD_bits_task_allowRetry,
  output  io_toSourceD_bits_task_memAttr_allocate,
  output  io_toSourceD_bits_task_memAttr_cacheable,
  output  io_toSourceD_bits_task_memAttr_device,
  output  io_toSourceD_bits_task_memAttr_ewa,
  output  io_toSourceD_bits_task_traceTag,
  output  io_toSourceD_bits_task_dataCheckErr,
  output  [511:0] io_toSourceD_bits_data_data,
  output  io_toTXREQ_valid,
  output  [10:0] io_toTXREQ_bits_tgtID,
  output  [10:0] io_toTXREQ_bits_srcID,
  output  [11:0] io_toTXREQ_bits_txnID,
  output  [6:0] io_toTXREQ_bits_opcode,
  output  [47:0] io_toTXREQ_bits_addr,
  output  io_toTXREQ_bits_likelyshared,
  output  io_toTXREQ_bits_allowRetry,
  output  [3:0] io_toTXREQ_bits_pCrdType,
  output  io_toTXREQ_bits_memAttr_allocate,
  output  io_toTXREQ_bits_memAttr_cacheable,
  output  io_toTXREQ_bits_memAttr_device,
  output  io_toTXREQ_bits_memAttr_ewa,
  output  io_toTXREQ_bits_expCompAck,
  output  io_toTXRSP_valid,
  output  [2:0] io_toTXRSP_bits_txChannel,
  output  io_toTXRSP_bits_denied,
  output  [10:0] io_toTXRSP_bits_tgtID,
  output  [10:0] io_toTXRSP_bits_srcID,
  output  [11:0] io_toTXRSP_bits_txnID,
  output  [11:0] io_toTXRSP_bits_dbID,
  output  [6:0] io_toTXRSP_bits_chiOpcode,
  output  [2:0] io_toTXRSP_bits_resp,
  output  [2:0] io_toTXRSP_bits_fwdState,
  output  [3:0] io_toTXRSP_bits_pCrdType,
  output  io_toTXRSP_bits_traceTag,
  input  io_toTXDAT_ready,
  output  io_toTXDAT_valid,
  output  [2:0] io_toTXDAT_bits_task_channel,
  output  [2:0] io_toTXDAT_bits_task_txChannel,
  output  [8:0] io_toTXDAT_bits_task_set,
  output  [30:0] io_toTXDAT_bits_task_tag,
  output  [5:0] io_toTXDAT_bits_task_off,
  output  [1:0] io_toTXDAT_bits_task_alias,
  output  [43:0] io_toTXDAT_bits_task_vaddr,
  output  io_toTXDAT_bits_task_isKeyword,
  output  [3:0] io_toTXDAT_bits_task_opcode,
  output  [2:0] io_toTXDAT_bits_task_param,
  output  [2:0] io_toTXDAT_bits_task_size,
  output  [6:0] io_toTXDAT_bits_task_sourceId,
  output  [1:0] io_toTXDAT_bits_task_bufIdx,
  output  io_toTXDAT_bits_task_needProbeAckData,
  output  io_toTXDAT_bits_task_denied,
  output  io_toTXDAT_bits_task_corrupt,
  output  io_toTXDAT_bits_task_mshrTask,
  output  [7:0] io_toTXDAT_bits_task_mshrId,
  output  io_toTXDAT_bits_task_aliasTask,
  output  io_toTXDAT_bits_task_useProbeData,
  output  io_toTXDAT_bits_task_mshrRetry,
  output  io_toTXDAT_bits_task_readProbeDataDown,
  output  io_toTXDAT_bits_task_fromL2pft,
  output  io_toTXDAT_bits_task_needHint,
  output  io_toTXDAT_bits_task_dirty,
  output  [2:0] io_toTXDAT_bits_task_way,
  output  io_toTXDAT_bits_task_meta_dirty,
  output  [1:0] io_toTXDAT_bits_task_meta_state,
  output  io_toTXDAT_bits_task_meta_clients,
  output  [1:0] io_toTXDAT_bits_task_meta_alias,
  output  io_toTXDAT_bits_task_meta_prefetch,
  output  [2:0] io_toTXDAT_bits_task_meta_prefetchSrc,
  output  io_toTXDAT_bits_task_meta_accessed,
  output  io_toTXDAT_bits_task_meta_tagErr,
  output  io_toTXDAT_bits_task_meta_dataErr,
  output  io_toTXDAT_bits_task_metaWen,
  output  io_toTXDAT_bits_task_tagWen,
  output  io_toTXDAT_bits_task_dsWen,
  output  [7:0] io_toTXDAT_bits_task_wayMask,
  output  io_toTXDAT_bits_task_replTask,
  output  io_toTXDAT_bits_task_cmoTask,
  output  io_toTXDAT_bits_task_cmoAll,
  output  [4:0] io_toTXDAT_bits_task_reqSource,
  output  io_toTXDAT_bits_task_mergeA,
  output  [5:0] io_toTXDAT_bits_task_aMergeTask_off,
  output  [1:0] io_toTXDAT_bits_task_aMergeTask_alias,
  output  [43:0] io_toTXDAT_bits_task_aMergeTask_vaddr,
  output  io_toTXDAT_bits_task_aMergeTask_isKeyword,
  output  [2:0] io_toTXDAT_bits_task_aMergeTask_opcode,
  output  [2:0] io_toTXDAT_bits_task_aMergeTask_param,
  output  [6:0] io_toTXDAT_bits_task_aMergeTask_sourceId,
  output  io_toTXDAT_bits_task_aMergeTask_meta_dirty,
  output  [1:0] io_toTXDAT_bits_task_aMergeTask_meta_state,
  output  io_toTXDAT_bits_task_aMergeTask_meta_clients,
  output  [1:0] io_toTXDAT_bits_task_aMergeTask_meta_alias,
  output  io_toTXDAT_bits_task_aMergeTask_meta_prefetch,
  output  [2:0] io_toTXDAT_bits_task_aMergeTask_meta_prefetchSrc,
  output  io_toTXDAT_bits_task_aMergeTask_meta_accessed,
  output  io_toTXDAT_bits_task_aMergeTask_meta_tagErr,
  output  io_toTXDAT_bits_task_aMergeTask_meta_dataErr,
  output  io_toTXDAT_bits_task_snpHitRelease,
  output  io_toTXDAT_bits_task_snpHitReleaseToInval,
  output  io_toTXDAT_bits_task_snpHitReleaseToClean,
  output  io_toTXDAT_bits_task_snpHitReleaseWithData,
  output  [7:0] io_toTXDAT_bits_task_snpHitReleaseIdx,
  output  io_toTXDAT_bits_task_snpHitReleaseMeta_dirty,
  output  [1:0] io_toTXDAT_bits_task_snpHitReleaseMeta_state,
  output  io_toTXDAT_bits_task_snpHitReleaseMeta_clients,
  output  [1:0] io_toTXDAT_bits_task_snpHitReleaseMeta_alias,
  output  io_toTXDAT_bits_task_snpHitReleaseMeta_prefetch,
  output  [2:0] io_toTXDAT_bits_task_snpHitReleaseMeta_prefetchSrc,
  output  io_toTXDAT_bits_task_snpHitReleaseMeta_accessed,
  output  io_toTXDAT_bits_task_snpHitReleaseMeta_tagErr,
  output  io_toTXDAT_bits_task_snpHitReleaseMeta_dataErr,
  output  [10:0] io_toTXDAT_bits_task_tgtID,
  output  [10:0] io_toTXDAT_bits_task_srcID,
  output  [11:0] io_toTXDAT_bits_task_txnID,
  output  [10:0] io_toTXDAT_bits_task_homeNID,
  output  [11:0] io_toTXDAT_bits_task_dbID,
  output  [10:0] io_toTXDAT_bits_task_fwdNID,
  output  [11:0] io_toTXDAT_bits_task_fwdTxnID,
  output  [6:0] io_toTXDAT_bits_task_chiOpcode,
  output  [2:0] io_toTXDAT_bits_task_resp,
  output  [2:0] io_toTXDAT_bits_task_fwdState,
  output  [3:0] io_toTXDAT_bits_task_pCrdType,
  output  io_toTXDAT_bits_task_retToSrc,
  output  io_toTXDAT_bits_task_likelyshared,
  output  io_toTXDAT_bits_task_expCompAck,
  output  io_toTXDAT_bits_task_allowRetry,
  output  io_toTXDAT_bits_task_memAttr_allocate,
  output  io_toTXDAT_bits_task_memAttr_cacheable,
  output  io_toTXDAT_bits_task_memAttr_device,
  output  io_toTXDAT_bits_task_memAttr_ewa,
  output  io_toTXDAT_bits_task_traceTag,
  output  io_toTXDAT_bits_task_dataCheckErr,
  output  [511:0] io_toTXDAT_bits_data_data,
  output  io_metaWReq_valid,
  output  [8:0] io_metaWReq_bits_set,
  output  [7:0] io_metaWReq_bits_wayOH,
  output  io_metaWReq_bits_wmeta_dirty,
  output  [1:0] io_metaWReq_bits_wmeta_state,
  output  io_metaWReq_bits_wmeta_clients,
  output  [1:0] io_metaWReq_bits_wmeta_alias,
  output  io_metaWReq_bits_wmeta_prefetch,
  output  [2:0] io_metaWReq_bits_wmeta_prefetchSrc,
  output  io_metaWReq_bits_wmeta_accessed,
  output  io_metaWReq_bits_wmeta_tagErr,
  output  io_metaWReq_bits_wmeta_dataErr,
  output  io_tagWReq_valid,
  output  [8:0] io_tagWReq_bits_set,
  output  [2:0] io_tagWReq_bits_way,
  output  [30:0] io_tagWReq_bits_wtag,
  output  io_releaseBufWrite_valid,
  output  [7:0] io_releaseBufWrite_bits_id,
  output  [511:0] io_releaseBufWrite_bits_data_data,
  output  [8:0] io_nestedwb_set,
  output  [30:0] io_nestedwb_tag,
  output  io_nestedwb_c_set_dirty,
  output  io_nestedwb_c_set_tip,
  output  io_nestedwb_b_inv_dirty,
  output  io_nestedwb_b_toB,
  output  io_nestedwb_b_toN,
  output  io_nestedwb_b_toClean,
  output  [511:0] io_nestedwbData_data,
  input  io_l1Hint_ready,
  output  io_l1Hint_valid,
  output  [31:0] io_l1Hint_bits_sourceId,
  output  io_l1Hint_bits_isKeyword,
  input  io_prefetchTrain_ready,
  output  io_prefetchTrain_valid,
  output  [32:0] io_prefetchTrain_bits_tag,
  output  [8:0] io_prefetchTrain_bits_set,
  output  io_prefetchTrain_bits_needT,
  output  [6:0] io_prefetchTrain_bits_source,
  output  [43:0] io_prefetchTrain_bits_vaddr,
  output  io_prefetchTrain_bits_hit,
  output  io_prefetchTrain_bits_prefetched,
  output  [2:0] io_prefetchTrain_bits_pfsource,
  output  [4:0] io_prefetchTrain_bits_reqsource,
  output  io_error_valid,
  output  io_error_bits_valid,
  output  [45:0] io_error_bits_address,
  output  [5:0] io_perf_0_value,
  output  [5:0] io_perf_1_value,
  output  [5:0] io_perf_2_value,
  output  [5:0] io_perf_3_value,
  output  [5:0] io_perf_4_value,
  output  [5:0] io_perf_5_value,
  output  [5:0] io_perf_6_value,
  output  [5:0] io_perf_7_value
);
  assign io_toReqArb_blockG_s1 = '0;
  assign io_toReqArb_blockB_s1 = '0;
  assign io_toReqArb_blockC_s1 = '0;
  assign io_toReqBuf_0 = '0;
  assign io_toReqBuf_1 = '0;
  assign io_status_vec_toD_0_valid = '0;
  assign io_status_vec_toD_0_bits_channel = '0;
  assign io_status_vec_toD_1_valid = '0;
  assign io_status_vec_toD_1_bits_channel = '0;
  assign io_status_vec_toD_2_valid = '0;
  assign io_status_vec_toD_2_bits_channel = '0;
  assign io_status_vec_toTX_0_valid = '0;
  assign io_status_vec_toTX_0_bits_channel = '0;
  assign io_status_vec_toTX_0_bits_txChannel = '0;
  assign io_status_vec_toTX_0_bits_mshrTask = '0;
  assign io_status_vec_toTX_1_valid = '0;
  assign io_status_vec_toTX_1_bits_channel = '0;
  assign io_status_vec_toTX_1_bits_txChannel = '0;
  assign io_status_vec_toTX_1_bits_mshrTask = '0;
  assign io_status_vec_toTX_2_valid = '0;
  assign io_status_vec_toTX_2_bits_channel = '0;
  assign io_status_vec_toTX_2_bits_txChannel = '0;
  assign io_status_vec_toTX_2_bits_mshrTask = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_valid = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_hit = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_tag = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_set = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_way = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dirty = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_state = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_clients = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_alias = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetch = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_accessed = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_tagErr = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dataErr = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_error = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_acquire = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rprobe = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_pprobe = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_release = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_probeack = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_refill = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_cmoresp = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeackfirst = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeacklast = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeackfirst = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeacklast = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantfirst = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantlast = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grant = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_releaseack = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_replResp = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rcompack = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_dct = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_channel = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_set = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_tag = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_off = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_alias = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_isKeyword = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_opcode = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_param = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_sourceId = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_aliasTask = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_fromL2pft = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_reqSource = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitRelease = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToInval = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToClean = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseWithData = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseIdx = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_srcID = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_txnID = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdNID = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdTxnID = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_chiOpcode = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_retToSrc = '0;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_traceTag = '0;
  assign io_toDS_en_s3 = '0;
  assign io_toDS_req_s3_valid = '0;
  assign io_toDS_req_s3_bits_way = '0;
  assign io_toDS_req_s3_bits_set = '0;
  assign io_toDS_req_s3_bits_wen = '0;
  assign io_toDS_wdata_s3_data = '0;
  assign io_toSourceD_valid = '0;
  assign io_toSourceD_bits_task_channel = '0;
  assign io_toSourceD_bits_task_txChannel = '0;
  assign io_toSourceD_bits_task_set = '0;
  assign io_toSourceD_bits_task_tag = '0;
  assign io_toSourceD_bits_task_off = '0;
  assign io_toSourceD_bits_task_alias = '0;
  assign io_toSourceD_bits_task_vaddr = '0;
  assign io_toSourceD_bits_task_isKeyword = '0;
  assign io_toSourceD_bits_task_opcode = '0;
  assign io_toSourceD_bits_task_param = '0;
  assign io_toSourceD_bits_task_size = '0;
  assign io_toSourceD_bits_task_sourceId = '0;
  assign io_toSourceD_bits_task_bufIdx = '0;
  assign io_toSourceD_bits_task_needProbeAckData = '0;
  assign io_toSourceD_bits_task_denied = '0;
  assign io_toSourceD_bits_task_corrupt = '0;
  assign io_toSourceD_bits_task_mshrTask = '0;
  assign io_toSourceD_bits_task_mshrId = '0;
  assign io_toSourceD_bits_task_aliasTask = '0;
  assign io_toSourceD_bits_task_useProbeData = '0;
  assign io_toSourceD_bits_task_mshrRetry = '0;
  assign io_toSourceD_bits_task_readProbeDataDown = '0;
  assign io_toSourceD_bits_task_fromL2pft = '0;
  assign io_toSourceD_bits_task_needHint = '0;
  assign io_toSourceD_bits_task_dirty = '0;
  assign io_toSourceD_bits_task_way = '0;
  assign io_toSourceD_bits_task_meta_dirty = '0;
  assign io_toSourceD_bits_task_meta_state = '0;
  assign io_toSourceD_bits_task_meta_clients = '0;
  assign io_toSourceD_bits_task_meta_alias = '0;
  assign io_toSourceD_bits_task_meta_prefetch = '0;
  assign io_toSourceD_bits_task_meta_prefetchSrc = '0;
  assign io_toSourceD_bits_task_meta_accessed = '0;
  assign io_toSourceD_bits_task_meta_tagErr = '0;
  assign io_toSourceD_bits_task_meta_dataErr = '0;
  assign io_toSourceD_bits_task_metaWen = '0;
  assign io_toSourceD_bits_task_tagWen = '0;
  assign io_toSourceD_bits_task_dsWen = '0;
  assign io_toSourceD_bits_task_wayMask = '0;
  assign io_toSourceD_bits_task_replTask = '0;
  assign io_toSourceD_bits_task_cmoTask = '0;
  assign io_toSourceD_bits_task_cmoAll = '0;
  assign io_toSourceD_bits_task_reqSource = '0;
  assign io_toSourceD_bits_task_mergeA = '0;
  assign io_toSourceD_bits_task_aMergeTask_off = '0;
  assign io_toSourceD_bits_task_aMergeTask_alias = '0;
  assign io_toSourceD_bits_task_aMergeTask_vaddr = '0;
  assign io_toSourceD_bits_task_aMergeTask_isKeyword = '0;
  assign io_toSourceD_bits_task_aMergeTask_opcode = '0;
  assign io_toSourceD_bits_task_aMergeTask_param = '0;
  assign io_toSourceD_bits_task_aMergeTask_sourceId = '0;
  assign io_toSourceD_bits_task_aMergeTask_meta_dirty = '0;
  assign io_toSourceD_bits_task_aMergeTask_meta_state = '0;
  assign io_toSourceD_bits_task_aMergeTask_meta_clients = '0;
  assign io_toSourceD_bits_task_aMergeTask_meta_alias = '0;
  assign io_toSourceD_bits_task_aMergeTask_meta_prefetch = '0;
  assign io_toSourceD_bits_task_aMergeTask_meta_prefetchSrc = '0;
  assign io_toSourceD_bits_task_aMergeTask_meta_accessed = '0;
  assign io_toSourceD_bits_task_aMergeTask_meta_tagErr = '0;
  assign io_toSourceD_bits_task_aMergeTask_meta_dataErr = '0;
  assign io_toSourceD_bits_task_snpHitRelease = '0;
  assign io_toSourceD_bits_task_snpHitReleaseToInval = '0;
  assign io_toSourceD_bits_task_snpHitReleaseToClean = '0;
  assign io_toSourceD_bits_task_snpHitReleaseWithData = '0;
  assign io_toSourceD_bits_task_snpHitReleaseIdx = '0;
  assign io_toSourceD_bits_task_snpHitReleaseMeta_dirty = '0;
  assign io_toSourceD_bits_task_snpHitReleaseMeta_state = '0;
  assign io_toSourceD_bits_task_snpHitReleaseMeta_clients = '0;
  assign io_toSourceD_bits_task_snpHitReleaseMeta_alias = '0;
  assign io_toSourceD_bits_task_snpHitReleaseMeta_prefetch = '0;
  assign io_toSourceD_bits_task_snpHitReleaseMeta_prefetchSrc = '0;
  assign io_toSourceD_bits_task_snpHitReleaseMeta_accessed = '0;
  assign io_toSourceD_bits_task_snpHitReleaseMeta_tagErr = '0;
  assign io_toSourceD_bits_task_snpHitReleaseMeta_dataErr = '0;
  assign io_toSourceD_bits_task_tgtID = '0;
  assign io_toSourceD_bits_task_srcID = '0;
  assign io_toSourceD_bits_task_txnID = '0;
  assign io_toSourceD_bits_task_homeNID = '0;
  assign io_toSourceD_bits_task_dbID = '0;
  assign io_toSourceD_bits_task_fwdNID = '0;
  assign io_toSourceD_bits_task_fwdTxnID = '0;
  assign io_toSourceD_bits_task_chiOpcode = '0;
  assign io_toSourceD_bits_task_resp = '0;
  assign io_toSourceD_bits_task_fwdState = '0;
  assign io_toSourceD_bits_task_pCrdType = '0;
  assign io_toSourceD_bits_task_retToSrc = '0;
  assign io_toSourceD_bits_task_likelyshared = '0;
  assign io_toSourceD_bits_task_expCompAck = '0;
  assign io_toSourceD_bits_task_allowRetry = '0;
  assign io_toSourceD_bits_task_memAttr_allocate = '0;
  assign io_toSourceD_bits_task_memAttr_cacheable = '0;
  assign io_toSourceD_bits_task_memAttr_device = '0;
  assign io_toSourceD_bits_task_memAttr_ewa = '0;
  assign io_toSourceD_bits_task_traceTag = '0;
  assign io_toSourceD_bits_task_dataCheckErr = '0;
  assign io_toSourceD_bits_data_data = '0;
  assign io_toTXREQ_valid = '0;
  assign io_toTXREQ_bits_tgtID = '0;
  assign io_toTXREQ_bits_srcID = '0;
  assign io_toTXREQ_bits_txnID = '0;
  assign io_toTXREQ_bits_opcode = '0;
  assign io_toTXREQ_bits_addr = '0;
  assign io_toTXREQ_bits_likelyshared = '0;
  assign io_toTXREQ_bits_allowRetry = '0;
  assign io_toTXREQ_bits_pCrdType = '0;
  assign io_toTXREQ_bits_memAttr_allocate = '0;
  assign io_toTXREQ_bits_memAttr_cacheable = '0;
  assign io_toTXREQ_bits_memAttr_device = '0;
  assign io_toTXREQ_bits_memAttr_ewa = '0;
  assign io_toTXREQ_bits_expCompAck = '0;
  assign io_toTXRSP_valid = '0;
  assign io_toTXRSP_bits_txChannel = '0;
  assign io_toTXRSP_bits_denied = '0;
  assign io_toTXRSP_bits_tgtID = '0;
  assign io_toTXRSP_bits_srcID = '0;
  assign io_toTXRSP_bits_txnID = '0;
  assign io_toTXRSP_bits_dbID = '0;
  assign io_toTXRSP_bits_chiOpcode = '0;
  assign io_toTXRSP_bits_resp = '0;
  assign io_toTXRSP_bits_fwdState = '0;
  assign io_toTXRSP_bits_pCrdType = '0;
  assign io_toTXRSP_bits_traceTag = '0;
  assign io_toTXDAT_valid = '0;
  assign io_toTXDAT_bits_task_channel = '0;
  assign io_toTXDAT_bits_task_txChannel = '0;
  assign io_toTXDAT_bits_task_set = '0;
  assign io_toTXDAT_bits_task_tag = '0;
  assign io_toTXDAT_bits_task_off = '0;
  assign io_toTXDAT_bits_task_alias = '0;
  assign io_toTXDAT_bits_task_vaddr = '0;
  assign io_toTXDAT_bits_task_isKeyword = '0;
  assign io_toTXDAT_bits_task_opcode = '0;
  assign io_toTXDAT_bits_task_param = '0;
  assign io_toTXDAT_bits_task_size = '0;
  assign io_toTXDAT_bits_task_sourceId = '0;
  assign io_toTXDAT_bits_task_bufIdx = '0;
  assign io_toTXDAT_bits_task_needProbeAckData = '0;
  assign io_toTXDAT_bits_task_denied = '0;
  assign io_toTXDAT_bits_task_corrupt = '0;
  assign io_toTXDAT_bits_task_mshrTask = '0;
  assign io_toTXDAT_bits_task_mshrId = '0;
  assign io_toTXDAT_bits_task_aliasTask = '0;
  assign io_toTXDAT_bits_task_useProbeData = '0;
  assign io_toTXDAT_bits_task_mshrRetry = '0;
  assign io_toTXDAT_bits_task_readProbeDataDown = '0;
  assign io_toTXDAT_bits_task_fromL2pft = '0;
  assign io_toTXDAT_bits_task_needHint = '0;
  assign io_toTXDAT_bits_task_dirty = '0;
  assign io_toTXDAT_bits_task_way = '0;
  assign io_toTXDAT_bits_task_meta_dirty = '0;
  assign io_toTXDAT_bits_task_meta_state = '0;
  assign io_toTXDAT_bits_task_meta_clients = '0;
  assign io_toTXDAT_bits_task_meta_alias = '0;
  assign io_toTXDAT_bits_task_meta_prefetch = '0;
  assign io_toTXDAT_bits_task_meta_prefetchSrc = '0;
  assign io_toTXDAT_bits_task_meta_accessed = '0;
  assign io_toTXDAT_bits_task_meta_tagErr = '0;
  assign io_toTXDAT_bits_task_meta_dataErr = '0;
  assign io_toTXDAT_bits_task_metaWen = '0;
  assign io_toTXDAT_bits_task_tagWen = '0;
  assign io_toTXDAT_bits_task_dsWen = '0;
  assign io_toTXDAT_bits_task_wayMask = '0;
  assign io_toTXDAT_bits_task_replTask = '0;
  assign io_toTXDAT_bits_task_cmoTask = '0;
  assign io_toTXDAT_bits_task_cmoAll = '0;
  assign io_toTXDAT_bits_task_reqSource = '0;
  assign io_toTXDAT_bits_task_mergeA = '0;
  assign io_toTXDAT_bits_task_aMergeTask_off = '0;
  assign io_toTXDAT_bits_task_aMergeTask_alias = '0;
  assign io_toTXDAT_bits_task_aMergeTask_vaddr = '0;
  assign io_toTXDAT_bits_task_aMergeTask_isKeyword = '0;
  assign io_toTXDAT_bits_task_aMergeTask_opcode = '0;
  assign io_toTXDAT_bits_task_aMergeTask_param = '0;
  assign io_toTXDAT_bits_task_aMergeTask_sourceId = '0;
  assign io_toTXDAT_bits_task_aMergeTask_meta_dirty = '0;
  assign io_toTXDAT_bits_task_aMergeTask_meta_state = '0;
  assign io_toTXDAT_bits_task_aMergeTask_meta_clients = '0;
  assign io_toTXDAT_bits_task_aMergeTask_meta_alias = '0;
  assign io_toTXDAT_bits_task_aMergeTask_meta_prefetch = '0;
  assign io_toTXDAT_bits_task_aMergeTask_meta_prefetchSrc = '0;
  assign io_toTXDAT_bits_task_aMergeTask_meta_accessed = '0;
  assign io_toTXDAT_bits_task_aMergeTask_meta_tagErr = '0;
  assign io_toTXDAT_bits_task_aMergeTask_meta_dataErr = '0;
  assign io_toTXDAT_bits_task_snpHitRelease = '0;
  assign io_toTXDAT_bits_task_snpHitReleaseToInval = '0;
  assign io_toTXDAT_bits_task_snpHitReleaseToClean = '0;
  assign io_toTXDAT_bits_task_snpHitReleaseWithData = '0;
  assign io_toTXDAT_bits_task_snpHitReleaseIdx = '0;
  assign io_toTXDAT_bits_task_snpHitReleaseMeta_dirty = '0;
  assign io_toTXDAT_bits_task_snpHitReleaseMeta_state = '0;
  assign io_toTXDAT_bits_task_snpHitReleaseMeta_clients = '0;
  assign io_toTXDAT_bits_task_snpHitReleaseMeta_alias = '0;
  assign io_toTXDAT_bits_task_snpHitReleaseMeta_prefetch = '0;
  assign io_toTXDAT_bits_task_snpHitReleaseMeta_prefetchSrc = '0;
  assign io_toTXDAT_bits_task_snpHitReleaseMeta_accessed = '0;
  assign io_toTXDAT_bits_task_snpHitReleaseMeta_tagErr = '0;
  assign io_toTXDAT_bits_task_snpHitReleaseMeta_dataErr = '0;
  assign io_toTXDAT_bits_task_tgtID = '0;
  assign io_toTXDAT_bits_task_srcID = '0;
  assign io_toTXDAT_bits_task_txnID = '0;
  assign io_toTXDAT_bits_task_homeNID = '0;
  assign io_toTXDAT_bits_task_dbID = '0;
  assign io_toTXDAT_bits_task_fwdNID = '0;
  assign io_toTXDAT_bits_task_fwdTxnID = '0;
  assign io_toTXDAT_bits_task_chiOpcode = '0;
  assign io_toTXDAT_bits_task_resp = '0;
  assign io_toTXDAT_bits_task_fwdState = '0;
  assign io_toTXDAT_bits_task_pCrdType = '0;
  assign io_toTXDAT_bits_task_retToSrc = '0;
  assign io_toTXDAT_bits_task_likelyshared = '0;
  assign io_toTXDAT_bits_task_expCompAck = '0;
  assign io_toTXDAT_bits_task_allowRetry = '0;
  assign io_toTXDAT_bits_task_memAttr_allocate = '0;
  assign io_toTXDAT_bits_task_memAttr_cacheable = '0;
  assign io_toTXDAT_bits_task_memAttr_device = '0;
  assign io_toTXDAT_bits_task_memAttr_ewa = '0;
  assign io_toTXDAT_bits_task_traceTag = '0;
  assign io_toTXDAT_bits_task_dataCheckErr = '0;
  assign io_toTXDAT_bits_data_data = '0;
  assign io_metaWReq_valid = '0;
  assign io_metaWReq_bits_set = '0;
  assign io_metaWReq_bits_wayOH = '0;
  assign io_metaWReq_bits_wmeta_dirty = '0;
  assign io_metaWReq_bits_wmeta_state = '0;
  assign io_metaWReq_bits_wmeta_clients = '0;
  assign io_metaWReq_bits_wmeta_alias = '0;
  assign io_metaWReq_bits_wmeta_prefetch = '0;
  assign io_metaWReq_bits_wmeta_prefetchSrc = '0;
  assign io_metaWReq_bits_wmeta_accessed = '0;
  assign io_metaWReq_bits_wmeta_tagErr = '0;
  assign io_metaWReq_bits_wmeta_dataErr = '0;
  assign io_tagWReq_valid = '0;
  assign io_tagWReq_bits_set = '0;
  assign io_tagWReq_bits_way = '0;
  assign io_tagWReq_bits_wtag = '0;
  assign io_releaseBufWrite_valid = '0;
  assign io_releaseBufWrite_bits_id = '0;
  assign io_releaseBufWrite_bits_data_data = '0;
  assign io_nestedwb_set = '0;
  assign io_nestedwb_tag = '0;
  assign io_nestedwb_c_set_dirty = '0;
  assign io_nestedwb_c_set_tip = '0;
  assign io_nestedwb_b_inv_dirty = '0;
  assign io_nestedwb_b_toB = '0;
  assign io_nestedwb_b_toN = '0;
  assign io_nestedwb_b_toClean = '0;
  assign io_nestedwbData_data = '0;
  assign io_l1Hint_valid = '0;
  assign io_l1Hint_bits_sourceId = '0;
  assign io_l1Hint_bits_isKeyword = '0;
  assign io_prefetchTrain_valid = '0;
  assign io_prefetchTrain_bits_tag = '0;
  assign io_prefetchTrain_bits_set = '0;
  assign io_prefetchTrain_bits_needT = '0;
  assign io_prefetchTrain_bits_source = '0;
  assign io_prefetchTrain_bits_vaddr = '0;
  assign io_prefetchTrain_bits_hit = '0;
  assign io_prefetchTrain_bits_prefetched = '0;
  assign io_prefetchTrain_bits_pfsource = '0;
  assign io_prefetchTrain_bits_reqsource = '0;
  assign io_error_valid = '0;
  assign io_error_bits_valid = '0;
  assign io_error_bits_address = '0;
  assign io_perf_0_value = '0;
  assign io_perf_1_value = '0;
  assign io_perf_2_value = '0;
  assign io_perf_3_value = '0;
  assign io_perf_4_value = '0;
  assign io_perf_5_value = '0;
  assign io_perf_6_value = '0;
  assign io_perf_7_value = '0;
endmodule

module RXDAT(
  input  clock,
  input  reset,
  input  io_out_valid,
  input  [11:0] io_out_bits_txnID,
  input  [10:0] io_out_bits_homeNID,
  input  [3:0] io_out_bits_opcode,
  input  [1:0] io_out_bits_respErr,
  input  [2:0] io_out_bits_resp,
  input  [11:0] io_out_bits_dbID,
  input  [1:0] io_out_bits_dataID,
  input  io_out_bits_traceTag,
  input  [255:0] io_out_bits_data,
  input  [31:0] io_out_bits_dataCheck,
  input  [3:0] io_out_bits_poison,
  output  io_in_valid,
  output  [7:0] io_in_mshrId,
  output  io_in_respInfo_last,
  output  io_in_respInfo_corrupt,
  output  [6:0] io_in_respInfo_chiOpcode,
  output  [10:0] io_in_respInfo_homeNID,
  output  [11:0] io_in_respInfo_dbID,
  output  [2:0] io_in_respInfo_resp,
  output  [1:0] io_in_respInfo_respErr,
  output  io_in_respInfo_traceTag,
  output  io_in_respInfo_dataCheckErr,
  output  io_refillBufWrite_valid,
  output  [7:0] io_refillBufWrite_bits_id,
  output  [511:0] io_refillBufWrite_bits_data_data,
  output  [1:0] io_refillBufWrite_bits_beatMask
);
  assign io_in_valid = '0;
  assign io_in_mshrId = '0;
  assign io_in_respInfo_last = '0;
  assign io_in_respInfo_corrupt = '0;
  assign io_in_respInfo_chiOpcode = '0;
  assign io_in_respInfo_homeNID = '0;
  assign io_in_respInfo_dbID = '0;
  assign io_in_respInfo_resp = '0;
  assign io_in_respInfo_respErr = '0;
  assign io_in_respInfo_traceTag = '0;
  assign io_in_respInfo_dataCheckErr = '0;
  assign io_refillBufWrite_valid = '0;
  assign io_refillBufWrite_bits_id = '0;
  assign io_refillBufWrite_bits_data_data = '0;
  assign io_refillBufWrite_bits_beatMask = '0;
endmodule

module RXRSP(
  input  io_out_valid,
  input  [10:0] io_out_bits_srcID,
  input  [11:0] io_out_bits_txnID,
  input  [4:0] io_out_bits_opcode,
  input  [1:0] io_out_bits_respErr,
  input  [2:0] io_out_bits_resp,
  input  [11:0] io_out_bits_dbID,
  input  [3:0] io_out_bits_pCrdType,
  input  io_out_bits_traceTag,
  output  io_in_valid,
  output  [7:0] io_in_mshrId,
  output  [6:0] io_in_respInfo_chiOpcode,
  output  [10:0] io_in_respInfo_srcID,
  output  [11:0] io_in_respInfo_dbID,
  output  [2:0] io_in_respInfo_resp,
  output  [3:0] io_in_respInfo_pCrdType,
  output  [1:0] io_in_respInfo_respErr,
  output  io_in_respInfo_traceTag
);
  assign io_in_valid = '0;
  assign io_in_mshrId = '0;
  assign io_in_respInfo_chiOpcode = '0;
  assign io_in_respInfo_srcID = '0;
  assign io_in_respInfo_dbID = '0;
  assign io_in_respInfo_resp = '0;
  assign io_in_respInfo_pCrdType = '0;
  assign io_in_respInfo_respErr = '0;
  assign io_in_respInfo_traceTag = '0;
endmodule

module RXSNP(
  input  clock,
  input  reset,
  output  io_rxsnp_ready,
  input  io_rxsnp_valid,
  input  [3:0] io_rxsnp_bits_qos,
  input  [10:0] io_rxsnp_bits_srcID,
  input  [11:0] io_rxsnp_bits_txnID,
  input  [10:0] io_rxsnp_bits_fwdNID,
  input  [11:0] io_rxsnp_bits_fwdTxnID,
  input  [4:0] io_rxsnp_bits_opcode,
  input  [44:0] io_rxsnp_bits_addr,
  input  io_rxsnp_bits_ns,
  input  io_rxsnp_bits_doNotGoToSD,
  input  io_rxsnp_bits_retToSrc,
  input  io_rxsnp_bits_traceTag,
  input  io_rxsnp_bits_mpam_perfMonGroup,
  input  [8:0] io_rxsnp_bits_mpam_partID,
  input  io_rxsnp_bits_mpam_mpamNS,
  input  io_task_ready,
  output  io_task_valid,
  output  [8:0] io_task_bits_set,
  output  [30:0] io_task_bits_tag,
  output  [5:0] io_task_bits_off,
  output  io_task_bits_snpHitRelease,
  output  io_task_bits_snpHitReleaseToInval,
  output  io_task_bits_snpHitReleaseToClean,
  output  io_task_bits_snpHitReleaseWithData,
  output  [7:0] io_task_bits_snpHitReleaseIdx,
  output  io_task_bits_snpHitReleaseMeta_dirty,
  output  [1:0] io_task_bits_snpHitReleaseMeta_state,
  output  io_task_bits_snpHitReleaseMeta_clients,
  output  [1:0] io_task_bits_snpHitReleaseMeta_alias,
  output  io_task_bits_snpHitReleaseMeta_prefetch,
  output  [2:0] io_task_bits_snpHitReleaseMeta_prefetchSrc,
  output  io_task_bits_snpHitReleaseMeta_accessed,
  output  io_task_bits_snpHitReleaseMeta_tagErr,
  output  io_task_bits_snpHitReleaseMeta_dataErr,
  output  [10:0] io_task_bits_srcID,
  output  [11:0] io_task_bits_txnID,
  output  [10:0] io_task_bits_fwdNID,
  output  [11:0] io_task_bits_fwdTxnID,
  output  [6:0] io_task_bits_chiOpcode,
  output  io_task_bits_retToSrc,
  output  io_task_bits_traceTag,
  input  io_msInfo_0_valid,
  input  [8:0] io_msInfo_0_bits_set,
  input  [30:0] io_msInfo_0_bits_reqTag,
  input  io_msInfo_0_bits_willFree,
  input  io_msInfo_0_bits_aliasTask,
  input  io_msInfo_0_bits_blockRefill,
  input  io_msInfo_0_bits_meta_dirty,
  input  [1:0] io_msInfo_0_bits_meta_state,
  input  io_msInfo_0_bits_meta_clients,
  input  [1:0] io_msInfo_0_bits_meta_alias,
  input  io_msInfo_0_bits_meta_prefetch,
  input  [2:0] io_msInfo_0_bits_meta_prefetchSrc,
  input  io_msInfo_0_bits_meta_accessed,
  input  io_msInfo_0_bits_meta_tagErr,
  input  io_msInfo_0_bits_meta_dataErr,
  input  [30:0] io_msInfo_0_bits_metaTag,
  input  io_msInfo_0_bits_dirHit,
  input  io_msInfo_0_bits_w_grantfirst,
  input  io_msInfo_0_bits_s_release,
  input  io_msInfo_0_bits_s_cmoresp,
  input  io_msInfo_0_bits_s_cmometaw,
  input  io_msInfo_0_bits_w_releaseack,
  input  io_msInfo_0_bits_w_replResp,
  input  io_msInfo_0_bits_w_rprobeacklast,
  input  io_msInfo_0_bits_replaceData,
  input  io_msInfo_0_bits_releaseToClean,
  input  io_msInfo_1_valid,
  input  [8:0] io_msInfo_1_bits_set,
  input  [30:0] io_msInfo_1_bits_reqTag,
  input  io_msInfo_1_bits_willFree,
  input  io_msInfo_1_bits_aliasTask,
  input  io_msInfo_1_bits_blockRefill,
  input  io_msInfo_1_bits_meta_dirty,
  input  [1:0] io_msInfo_1_bits_meta_state,
  input  io_msInfo_1_bits_meta_clients,
  input  [1:0] io_msInfo_1_bits_meta_alias,
  input  io_msInfo_1_bits_meta_prefetch,
  input  [2:0] io_msInfo_1_bits_meta_prefetchSrc,
  input  io_msInfo_1_bits_meta_accessed,
  input  io_msInfo_1_bits_meta_tagErr,
  input  io_msInfo_1_bits_meta_dataErr,
  input  [30:0] io_msInfo_1_bits_metaTag,
  input  io_msInfo_1_bits_dirHit,
  input  io_msInfo_1_bits_w_grantfirst,
  input  io_msInfo_1_bits_s_release,
  input  io_msInfo_1_bits_s_cmoresp,
  input  io_msInfo_1_bits_s_cmometaw,
  input  io_msInfo_1_bits_w_releaseack,
  input  io_msInfo_1_bits_w_replResp,
  input  io_msInfo_1_bits_w_rprobeacklast,
  input  io_msInfo_1_bits_replaceData,
  input  io_msInfo_1_bits_releaseToClean,
  input  io_msInfo_2_valid,
  input  [8:0] io_msInfo_2_bits_set,
  input  [30:0] io_msInfo_2_bits_reqTag,
  input  io_msInfo_2_bits_willFree,
  input  io_msInfo_2_bits_aliasTask,
  input  io_msInfo_2_bits_blockRefill,
  input  io_msInfo_2_bits_meta_dirty,
  input  [1:0] io_msInfo_2_bits_meta_state,
  input  io_msInfo_2_bits_meta_clients,
  input  [1:0] io_msInfo_2_bits_meta_alias,
  input  io_msInfo_2_bits_meta_prefetch,
  input  [2:0] io_msInfo_2_bits_meta_prefetchSrc,
  input  io_msInfo_2_bits_meta_accessed,
  input  io_msInfo_2_bits_meta_tagErr,
  input  io_msInfo_2_bits_meta_dataErr,
  input  [30:0] io_msInfo_2_bits_metaTag,
  input  io_msInfo_2_bits_dirHit,
  input  io_msInfo_2_bits_w_grantfirst,
  input  io_msInfo_2_bits_s_release,
  input  io_msInfo_2_bits_s_cmoresp,
  input  io_msInfo_2_bits_s_cmometaw,
  input  io_msInfo_2_bits_w_releaseack,
  input  io_msInfo_2_bits_w_replResp,
  input  io_msInfo_2_bits_w_rprobeacklast,
  input  io_msInfo_2_bits_replaceData,
  input  io_msInfo_2_bits_releaseToClean,
  input  io_msInfo_3_valid,
  input  [8:0] io_msInfo_3_bits_set,
  input  [30:0] io_msInfo_3_bits_reqTag,
  input  io_msInfo_3_bits_willFree,
  input  io_msInfo_3_bits_aliasTask,
  input  io_msInfo_3_bits_blockRefill,
  input  io_msInfo_3_bits_meta_dirty,
  input  [1:0] io_msInfo_3_bits_meta_state,
  input  io_msInfo_3_bits_meta_clients,
  input  [1:0] io_msInfo_3_bits_meta_alias,
  input  io_msInfo_3_bits_meta_prefetch,
  input  [2:0] io_msInfo_3_bits_meta_prefetchSrc,
  input  io_msInfo_3_bits_meta_accessed,
  input  io_msInfo_3_bits_meta_tagErr,
  input  io_msInfo_3_bits_meta_dataErr,
  input  [30:0] io_msInfo_3_bits_metaTag,
  input  io_msInfo_3_bits_dirHit,
  input  io_msInfo_3_bits_w_grantfirst,
  input  io_msInfo_3_bits_s_release,
  input  io_msInfo_3_bits_s_cmoresp,
  input  io_msInfo_3_bits_s_cmometaw,
  input  io_msInfo_3_bits_w_releaseack,
  input  io_msInfo_3_bits_w_replResp,
  input  io_msInfo_3_bits_w_rprobeacklast,
  input  io_msInfo_3_bits_replaceData,
  input  io_msInfo_3_bits_releaseToClean,
  input  io_msInfo_4_valid,
  input  [8:0] io_msInfo_4_bits_set,
  input  [30:0] io_msInfo_4_bits_reqTag,
  input  io_msInfo_4_bits_willFree,
  input  io_msInfo_4_bits_aliasTask,
  input  io_msInfo_4_bits_blockRefill,
  input  io_msInfo_4_bits_meta_dirty,
  input  [1:0] io_msInfo_4_bits_meta_state,
  input  io_msInfo_4_bits_meta_clients,
  input  [1:0] io_msInfo_4_bits_meta_alias,
  input  io_msInfo_4_bits_meta_prefetch,
  input  [2:0] io_msInfo_4_bits_meta_prefetchSrc,
  input  io_msInfo_4_bits_meta_accessed,
  input  io_msInfo_4_bits_meta_tagErr,
  input  io_msInfo_4_bits_meta_dataErr,
  input  [30:0] io_msInfo_4_bits_metaTag,
  input  io_msInfo_4_bits_dirHit,
  input  io_msInfo_4_bits_w_grantfirst,
  input  io_msInfo_4_bits_s_release,
  input  io_msInfo_4_bits_s_cmoresp,
  input  io_msInfo_4_bits_s_cmometaw,
  input  io_msInfo_4_bits_w_releaseack,
  input  io_msInfo_4_bits_w_replResp,
  input  io_msInfo_4_bits_w_rprobeacklast,
  input  io_msInfo_4_bits_replaceData,
  input  io_msInfo_4_bits_releaseToClean,
  input  io_msInfo_5_valid,
  input  [8:0] io_msInfo_5_bits_set,
  input  [30:0] io_msInfo_5_bits_reqTag,
  input  io_msInfo_5_bits_willFree,
  input  io_msInfo_5_bits_aliasTask,
  input  io_msInfo_5_bits_blockRefill,
  input  io_msInfo_5_bits_meta_dirty,
  input  [1:0] io_msInfo_5_bits_meta_state,
  input  io_msInfo_5_bits_meta_clients,
  input  [1:0] io_msInfo_5_bits_meta_alias,
  input  io_msInfo_5_bits_meta_prefetch,
  input  [2:0] io_msInfo_5_bits_meta_prefetchSrc,
  input  io_msInfo_5_bits_meta_accessed,
  input  io_msInfo_5_bits_meta_tagErr,
  input  io_msInfo_5_bits_meta_dataErr,
  input  [30:0] io_msInfo_5_bits_metaTag,
  input  io_msInfo_5_bits_dirHit,
  input  io_msInfo_5_bits_w_grantfirst,
  input  io_msInfo_5_bits_s_release,
  input  io_msInfo_5_bits_s_cmoresp,
  input  io_msInfo_5_bits_s_cmometaw,
  input  io_msInfo_5_bits_w_releaseack,
  input  io_msInfo_5_bits_w_replResp,
  input  io_msInfo_5_bits_w_rprobeacklast,
  input  io_msInfo_5_bits_replaceData,
  input  io_msInfo_5_bits_releaseToClean,
  input  io_msInfo_6_valid,
  input  [8:0] io_msInfo_6_bits_set,
  input  [30:0] io_msInfo_6_bits_reqTag,
  input  io_msInfo_6_bits_willFree,
  input  io_msInfo_6_bits_aliasTask,
  input  io_msInfo_6_bits_blockRefill,
  input  io_msInfo_6_bits_meta_dirty,
  input  [1:0] io_msInfo_6_bits_meta_state,
  input  io_msInfo_6_bits_meta_clients,
  input  [1:0] io_msInfo_6_bits_meta_alias,
  input  io_msInfo_6_bits_meta_prefetch,
  input  [2:0] io_msInfo_6_bits_meta_prefetchSrc,
  input  io_msInfo_6_bits_meta_accessed,
  input  io_msInfo_6_bits_meta_tagErr,
  input  io_msInfo_6_bits_meta_dataErr,
  input  [30:0] io_msInfo_6_bits_metaTag,
  input  io_msInfo_6_bits_dirHit,
  input  io_msInfo_6_bits_w_grantfirst,
  input  io_msInfo_6_bits_s_release,
  input  io_msInfo_6_bits_s_cmoresp,
  input  io_msInfo_6_bits_s_cmometaw,
  input  io_msInfo_6_bits_w_releaseack,
  input  io_msInfo_6_bits_w_replResp,
  input  io_msInfo_6_bits_w_rprobeacklast,
  input  io_msInfo_6_bits_replaceData,
  input  io_msInfo_6_bits_releaseToClean,
  input  io_msInfo_7_valid,
  input  [8:0] io_msInfo_7_bits_set,
  input  [30:0] io_msInfo_7_bits_reqTag,
  input  io_msInfo_7_bits_willFree,
  input  io_msInfo_7_bits_aliasTask,
  input  io_msInfo_7_bits_blockRefill,
  input  io_msInfo_7_bits_meta_dirty,
  input  [1:0] io_msInfo_7_bits_meta_state,
  input  io_msInfo_7_bits_meta_clients,
  input  [1:0] io_msInfo_7_bits_meta_alias,
  input  io_msInfo_7_bits_meta_prefetch,
  input  [2:0] io_msInfo_7_bits_meta_prefetchSrc,
  input  io_msInfo_7_bits_meta_accessed,
  input  io_msInfo_7_bits_meta_tagErr,
  input  io_msInfo_7_bits_meta_dataErr,
  input  [30:0] io_msInfo_7_bits_metaTag,
  input  io_msInfo_7_bits_dirHit,
  input  io_msInfo_7_bits_w_grantfirst,
  input  io_msInfo_7_bits_s_release,
  input  io_msInfo_7_bits_s_cmoresp,
  input  io_msInfo_7_bits_s_cmometaw,
  input  io_msInfo_7_bits_w_releaseack,
  input  io_msInfo_7_bits_w_replResp,
  input  io_msInfo_7_bits_w_rprobeacklast,
  input  io_msInfo_7_bits_replaceData,
  input  io_msInfo_7_bits_releaseToClean,
  input  io_msInfo_8_valid,
  input  [8:0] io_msInfo_8_bits_set,
  input  [30:0] io_msInfo_8_bits_reqTag,
  input  io_msInfo_8_bits_willFree,
  input  io_msInfo_8_bits_aliasTask,
  input  io_msInfo_8_bits_blockRefill,
  input  io_msInfo_8_bits_meta_dirty,
  input  [1:0] io_msInfo_8_bits_meta_state,
  input  io_msInfo_8_bits_meta_clients,
  input  [1:0] io_msInfo_8_bits_meta_alias,
  input  io_msInfo_8_bits_meta_prefetch,
  input  [2:0] io_msInfo_8_bits_meta_prefetchSrc,
  input  io_msInfo_8_bits_meta_accessed,
  input  io_msInfo_8_bits_meta_tagErr,
  input  io_msInfo_8_bits_meta_dataErr,
  input  [30:0] io_msInfo_8_bits_metaTag,
  input  io_msInfo_8_bits_dirHit,
  input  io_msInfo_8_bits_w_grantfirst,
  input  io_msInfo_8_bits_s_release,
  input  io_msInfo_8_bits_s_cmoresp,
  input  io_msInfo_8_bits_s_cmometaw,
  input  io_msInfo_8_bits_w_releaseack,
  input  io_msInfo_8_bits_w_replResp,
  input  io_msInfo_8_bits_w_rprobeacklast,
  input  io_msInfo_8_bits_replaceData,
  input  io_msInfo_8_bits_releaseToClean,
  input  io_msInfo_9_valid,
  input  [8:0] io_msInfo_9_bits_set,
  input  [30:0] io_msInfo_9_bits_reqTag,
  input  io_msInfo_9_bits_willFree,
  input  io_msInfo_9_bits_aliasTask,
  input  io_msInfo_9_bits_blockRefill,
  input  io_msInfo_9_bits_meta_dirty,
  input  [1:0] io_msInfo_9_bits_meta_state,
  input  io_msInfo_9_bits_meta_clients,
  input  [1:0] io_msInfo_9_bits_meta_alias,
  input  io_msInfo_9_bits_meta_prefetch,
  input  [2:0] io_msInfo_9_bits_meta_prefetchSrc,
  input  io_msInfo_9_bits_meta_accessed,
  input  io_msInfo_9_bits_meta_tagErr,
  input  io_msInfo_9_bits_meta_dataErr,
  input  [30:0] io_msInfo_9_bits_metaTag,
  input  io_msInfo_9_bits_dirHit,
  input  io_msInfo_9_bits_w_grantfirst,
  input  io_msInfo_9_bits_s_release,
  input  io_msInfo_9_bits_s_cmoresp,
  input  io_msInfo_9_bits_s_cmometaw,
  input  io_msInfo_9_bits_w_releaseack,
  input  io_msInfo_9_bits_w_replResp,
  input  io_msInfo_9_bits_w_rprobeacklast,
  input  io_msInfo_9_bits_replaceData,
  input  io_msInfo_9_bits_releaseToClean,
  input  io_msInfo_10_valid,
  input  [8:0] io_msInfo_10_bits_set,
  input  [30:0] io_msInfo_10_bits_reqTag,
  input  io_msInfo_10_bits_willFree,
  input  io_msInfo_10_bits_aliasTask,
  input  io_msInfo_10_bits_blockRefill,
  input  io_msInfo_10_bits_meta_dirty,
  input  [1:0] io_msInfo_10_bits_meta_state,
  input  io_msInfo_10_bits_meta_clients,
  input  [1:0] io_msInfo_10_bits_meta_alias,
  input  io_msInfo_10_bits_meta_prefetch,
  input  [2:0] io_msInfo_10_bits_meta_prefetchSrc,
  input  io_msInfo_10_bits_meta_accessed,
  input  io_msInfo_10_bits_meta_tagErr,
  input  io_msInfo_10_bits_meta_dataErr,
  input  [30:0] io_msInfo_10_bits_metaTag,
  input  io_msInfo_10_bits_dirHit,
  input  io_msInfo_10_bits_w_grantfirst,
  input  io_msInfo_10_bits_s_release,
  input  io_msInfo_10_bits_s_cmoresp,
  input  io_msInfo_10_bits_s_cmometaw,
  input  io_msInfo_10_bits_w_releaseack,
  input  io_msInfo_10_bits_w_replResp,
  input  io_msInfo_10_bits_w_rprobeacklast,
  input  io_msInfo_10_bits_replaceData,
  input  io_msInfo_10_bits_releaseToClean,
  input  io_msInfo_11_valid,
  input  [8:0] io_msInfo_11_bits_set,
  input  [30:0] io_msInfo_11_bits_reqTag,
  input  io_msInfo_11_bits_willFree,
  input  io_msInfo_11_bits_aliasTask,
  input  io_msInfo_11_bits_blockRefill,
  input  io_msInfo_11_bits_meta_dirty,
  input  [1:0] io_msInfo_11_bits_meta_state,
  input  io_msInfo_11_bits_meta_clients,
  input  [1:0] io_msInfo_11_bits_meta_alias,
  input  io_msInfo_11_bits_meta_prefetch,
  input  [2:0] io_msInfo_11_bits_meta_prefetchSrc,
  input  io_msInfo_11_bits_meta_accessed,
  input  io_msInfo_11_bits_meta_tagErr,
  input  io_msInfo_11_bits_meta_dataErr,
  input  [30:0] io_msInfo_11_bits_metaTag,
  input  io_msInfo_11_bits_dirHit,
  input  io_msInfo_11_bits_w_grantfirst,
  input  io_msInfo_11_bits_s_release,
  input  io_msInfo_11_bits_s_cmoresp,
  input  io_msInfo_11_bits_s_cmometaw,
  input  io_msInfo_11_bits_w_releaseack,
  input  io_msInfo_11_bits_w_replResp,
  input  io_msInfo_11_bits_w_rprobeacklast,
  input  io_msInfo_11_bits_replaceData,
  input  io_msInfo_11_bits_releaseToClean,
  input  io_msInfo_12_valid,
  input  [8:0] io_msInfo_12_bits_set,
  input  [30:0] io_msInfo_12_bits_reqTag,
  input  io_msInfo_12_bits_willFree,
  input  io_msInfo_12_bits_aliasTask,
  input  io_msInfo_12_bits_blockRefill,
  input  io_msInfo_12_bits_meta_dirty,
  input  [1:0] io_msInfo_12_bits_meta_state,
  input  io_msInfo_12_bits_meta_clients,
  input  [1:0] io_msInfo_12_bits_meta_alias,
  input  io_msInfo_12_bits_meta_prefetch,
  input  [2:0] io_msInfo_12_bits_meta_prefetchSrc,
  input  io_msInfo_12_bits_meta_accessed,
  input  io_msInfo_12_bits_meta_tagErr,
  input  io_msInfo_12_bits_meta_dataErr,
  input  [30:0] io_msInfo_12_bits_metaTag,
  input  io_msInfo_12_bits_dirHit,
  input  io_msInfo_12_bits_w_grantfirst,
  input  io_msInfo_12_bits_s_release,
  input  io_msInfo_12_bits_s_cmoresp,
  input  io_msInfo_12_bits_s_cmometaw,
  input  io_msInfo_12_bits_w_releaseack,
  input  io_msInfo_12_bits_w_replResp,
  input  io_msInfo_12_bits_w_rprobeacklast,
  input  io_msInfo_12_bits_replaceData,
  input  io_msInfo_12_bits_releaseToClean,
  input  io_msInfo_13_valid,
  input  [8:0] io_msInfo_13_bits_set,
  input  [30:0] io_msInfo_13_bits_reqTag,
  input  io_msInfo_13_bits_willFree,
  input  io_msInfo_13_bits_aliasTask,
  input  io_msInfo_13_bits_blockRefill,
  input  io_msInfo_13_bits_meta_dirty,
  input  [1:0] io_msInfo_13_bits_meta_state,
  input  io_msInfo_13_bits_meta_clients,
  input  [1:0] io_msInfo_13_bits_meta_alias,
  input  io_msInfo_13_bits_meta_prefetch,
  input  [2:0] io_msInfo_13_bits_meta_prefetchSrc,
  input  io_msInfo_13_bits_meta_accessed,
  input  io_msInfo_13_bits_meta_tagErr,
  input  io_msInfo_13_bits_meta_dataErr,
  input  [30:0] io_msInfo_13_bits_metaTag,
  input  io_msInfo_13_bits_dirHit,
  input  io_msInfo_13_bits_w_grantfirst,
  input  io_msInfo_13_bits_s_release,
  input  io_msInfo_13_bits_s_cmoresp,
  input  io_msInfo_13_bits_s_cmometaw,
  input  io_msInfo_13_bits_w_releaseack,
  input  io_msInfo_13_bits_w_replResp,
  input  io_msInfo_13_bits_w_rprobeacklast,
  input  io_msInfo_13_bits_replaceData,
  input  io_msInfo_13_bits_releaseToClean,
  input  io_msInfo_14_valid,
  input  [8:0] io_msInfo_14_bits_set,
  input  [30:0] io_msInfo_14_bits_reqTag,
  input  io_msInfo_14_bits_willFree,
  input  io_msInfo_14_bits_aliasTask,
  input  io_msInfo_14_bits_blockRefill,
  input  io_msInfo_14_bits_meta_dirty,
  input  [1:0] io_msInfo_14_bits_meta_state,
  input  io_msInfo_14_bits_meta_clients,
  input  [1:0] io_msInfo_14_bits_meta_alias,
  input  io_msInfo_14_bits_meta_prefetch,
  input  [2:0] io_msInfo_14_bits_meta_prefetchSrc,
  input  io_msInfo_14_bits_meta_accessed,
  input  io_msInfo_14_bits_meta_tagErr,
  input  io_msInfo_14_bits_meta_dataErr,
  input  [30:0] io_msInfo_14_bits_metaTag,
  input  io_msInfo_14_bits_dirHit,
  input  io_msInfo_14_bits_w_grantfirst,
  input  io_msInfo_14_bits_s_release,
  input  io_msInfo_14_bits_s_cmoresp,
  input  io_msInfo_14_bits_s_cmometaw,
  input  io_msInfo_14_bits_w_releaseack,
  input  io_msInfo_14_bits_w_replResp,
  input  io_msInfo_14_bits_w_rprobeacklast,
  input  io_msInfo_14_bits_replaceData,
  input  io_msInfo_14_bits_releaseToClean,
  input  io_msInfo_15_valid,
  input  [8:0] io_msInfo_15_bits_set,
  input  [30:0] io_msInfo_15_bits_reqTag,
  input  io_msInfo_15_bits_willFree,
  input  io_msInfo_15_bits_aliasTask,
  input  io_msInfo_15_bits_blockRefill,
  input  io_msInfo_15_bits_meta_dirty,
  input  [1:0] io_msInfo_15_bits_meta_state,
  input  io_msInfo_15_bits_meta_clients,
  input  [1:0] io_msInfo_15_bits_meta_alias,
  input  io_msInfo_15_bits_meta_prefetch,
  input  [2:0] io_msInfo_15_bits_meta_prefetchSrc,
  input  io_msInfo_15_bits_meta_accessed,
  input  io_msInfo_15_bits_meta_tagErr,
  input  io_msInfo_15_bits_meta_dataErr,
  input  [30:0] io_msInfo_15_bits_metaTag,
  input  io_msInfo_15_bits_dirHit,
  input  io_msInfo_15_bits_w_grantfirst,
  input  io_msInfo_15_bits_s_release,
  input  io_msInfo_15_bits_s_cmoresp,
  input  io_msInfo_15_bits_s_cmometaw,
  input  io_msInfo_15_bits_w_releaseack,
  input  io_msInfo_15_bits_w_replResp,
  input  io_msInfo_15_bits_w_rprobeacklast,
  input  io_msInfo_15_bits_replaceData,
  input  io_msInfo_15_bits_releaseToClean
);
  assign io_rxsnp_ready = '0;
  assign io_task_valid = '0;
  assign io_task_bits_set = '0;
  assign io_task_bits_tag = '0;
  assign io_task_bits_off = '0;
  assign io_task_bits_snpHitRelease = '0;
  assign io_task_bits_snpHitReleaseToInval = '0;
  assign io_task_bits_snpHitReleaseToClean = '0;
  assign io_task_bits_snpHitReleaseWithData = '0;
  assign io_task_bits_snpHitReleaseIdx = '0;
  assign io_task_bits_snpHitReleaseMeta_dirty = '0;
  assign io_task_bits_snpHitReleaseMeta_state = '0;
  assign io_task_bits_snpHitReleaseMeta_clients = '0;
  assign io_task_bits_snpHitReleaseMeta_alias = '0;
  assign io_task_bits_snpHitReleaseMeta_prefetch = '0;
  assign io_task_bits_snpHitReleaseMeta_prefetchSrc = '0;
  assign io_task_bits_snpHitReleaseMeta_accessed = '0;
  assign io_task_bits_snpHitReleaseMeta_tagErr = '0;
  assign io_task_bits_snpHitReleaseMeta_dataErr = '0;
  assign io_task_bits_srcID = '0;
  assign io_task_bits_txnID = '0;
  assign io_task_bits_fwdNID = '0;
  assign io_task_bits_fwdTxnID = '0;
  assign io_task_bits_chiOpcode = '0;
  assign io_task_bits_retToSrc = '0;
  assign io_task_bits_traceTag = '0;
endmodule

module RequestArb(
  input  clock,
  input  reset,
  output  io_sinkA_ready,
  input  io_sinkA_valid,
  input  [2:0] io_sinkA_bits_channel,
  input  [2:0] io_sinkA_bits_txChannel,
  input  [8:0] io_sinkA_bits_set,
  input  [30:0] io_sinkA_bits_tag,
  input  [5:0] io_sinkA_bits_off,
  input  [1:0] io_sinkA_bits_alias,
  input  [43:0] io_sinkA_bits_vaddr,
  input  io_sinkA_bits_isKeyword,
  input  [3:0] io_sinkA_bits_opcode,
  input  [2:0] io_sinkA_bits_param,
  input  [2:0] io_sinkA_bits_size,
  input  [6:0] io_sinkA_bits_sourceId,
  input  [1:0] io_sinkA_bits_bufIdx,
  input  io_sinkA_bits_needProbeAckData,
  input  io_sinkA_bits_denied,
  input  io_sinkA_bits_corrupt,
  input  io_sinkA_bits_mshrTask,
  input  [7:0] io_sinkA_bits_mshrId,
  input  io_sinkA_bits_aliasTask,
  input  io_sinkA_bits_useProbeData,
  input  io_sinkA_bits_mshrRetry,
  input  io_sinkA_bits_readProbeDataDown,
  input  io_sinkA_bits_fromL2pft,
  input  io_sinkA_bits_needHint,
  input  io_sinkA_bits_dirty,
  input  [2:0] io_sinkA_bits_way,
  input  io_sinkA_bits_meta_dirty,
  input  [1:0] io_sinkA_bits_meta_state,
  input  io_sinkA_bits_meta_clients,
  input  [1:0] io_sinkA_bits_meta_alias,
  input  io_sinkA_bits_meta_prefetch,
  input  [2:0] io_sinkA_bits_meta_prefetchSrc,
  input  io_sinkA_bits_meta_accessed,
  input  io_sinkA_bits_meta_tagErr,
  input  io_sinkA_bits_meta_dataErr,
  input  io_sinkA_bits_metaWen,
  input  io_sinkA_bits_tagWen,
  input  io_sinkA_bits_dsWen,
  input  [7:0] io_sinkA_bits_wayMask,
  input  io_sinkA_bits_replTask,
  input  io_sinkA_bits_cmoTask,
  input  io_sinkA_bits_cmoAll,
  input  [4:0] io_sinkA_bits_reqSource,
  input  io_sinkA_bits_mergeA,
  input  [5:0] io_sinkA_bits_aMergeTask_off,
  input  [1:0] io_sinkA_bits_aMergeTask_alias,
  input  [43:0] io_sinkA_bits_aMergeTask_vaddr,
  input  io_sinkA_bits_aMergeTask_isKeyword,
  input  [2:0] io_sinkA_bits_aMergeTask_opcode,
  input  [2:0] io_sinkA_bits_aMergeTask_param,
  input  [6:0] io_sinkA_bits_aMergeTask_sourceId,
  input  io_sinkA_bits_aMergeTask_meta_dirty,
  input  [1:0] io_sinkA_bits_aMergeTask_meta_state,
  input  io_sinkA_bits_aMergeTask_meta_clients,
  input  [1:0] io_sinkA_bits_aMergeTask_meta_alias,
  input  io_sinkA_bits_aMergeTask_meta_prefetch,
  input  [2:0] io_sinkA_bits_aMergeTask_meta_prefetchSrc,
  input  io_sinkA_bits_aMergeTask_meta_accessed,
  input  io_sinkA_bits_aMergeTask_meta_tagErr,
  input  io_sinkA_bits_aMergeTask_meta_dataErr,
  input  io_sinkA_bits_snpHitRelease,
  input  io_sinkA_bits_snpHitReleaseToInval,
  input  io_sinkA_bits_snpHitReleaseToClean,
  input  io_sinkA_bits_snpHitReleaseWithData,
  input  [7:0] io_sinkA_bits_snpHitReleaseIdx,
  input  io_sinkA_bits_snpHitReleaseMeta_dirty,
  input  [1:0] io_sinkA_bits_snpHitReleaseMeta_state,
  input  io_sinkA_bits_snpHitReleaseMeta_clients,
  input  [1:0] io_sinkA_bits_snpHitReleaseMeta_alias,
  input  io_sinkA_bits_snpHitReleaseMeta_prefetch,
  input  [2:0] io_sinkA_bits_snpHitReleaseMeta_prefetchSrc,
  input  io_sinkA_bits_snpHitReleaseMeta_accessed,
  input  io_sinkA_bits_snpHitReleaseMeta_tagErr,
  input  io_sinkA_bits_snpHitReleaseMeta_dataErr,
  input  [10:0] io_sinkA_bits_tgtID,
  input  [10:0] io_sinkA_bits_srcID,
  input  [11:0] io_sinkA_bits_txnID,
  input  [10:0] io_sinkA_bits_homeNID,
  input  [11:0] io_sinkA_bits_dbID,
  input  [10:0] io_sinkA_bits_fwdNID,
  input  [11:0] io_sinkA_bits_fwdTxnID,
  input  [6:0] io_sinkA_bits_chiOpcode,
  input  [2:0] io_sinkA_bits_resp,
  input  [2:0] io_sinkA_bits_fwdState,
  input  [3:0] io_sinkA_bits_pCrdType,
  input  io_sinkA_bits_retToSrc,
  input  io_sinkA_bits_likelyshared,
  input  io_sinkA_bits_expCompAck,
  input  io_sinkA_bits_allowRetry,
  input  io_sinkA_bits_memAttr_allocate,
  input  io_sinkA_bits_memAttr_cacheable,
  input  io_sinkA_bits_memAttr_device,
  input  io_sinkA_bits_memAttr_ewa,
  input  io_sinkA_bits_traceTag,
  input  io_sinkA_bits_dataCheckErr,
  input  [30:0] io_ATag,
  input  [8:0] io_ASet,
  output  io_s1Entrance_valid,
  output  [8:0] io_s1Entrance_bits_set,
  output  io_sinkB_ready,
  input  io_sinkB_valid,
  input  [2:0] io_sinkB_bits_channel,
  input  [2:0] io_sinkB_bits_txChannel,
  input  [8:0] io_sinkB_bits_set,
  input  [30:0] io_sinkB_bits_tag,
  input  [5:0] io_sinkB_bits_off,
  input  [1:0] io_sinkB_bits_alias,
  input  [43:0] io_sinkB_bits_vaddr,
  input  io_sinkB_bits_isKeyword,
  input  [3:0] io_sinkB_bits_opcode,
  input  [2:0] io_sinkB_bits_param,
  input  [2:0] io_sinkB_bits_size,
  input  [6:0] io_sinkB_bits_sourceId,
  input  [1:0] io_sinkB_bits_bufIdx,
  input  io_sinkB_bits_needProbeAckData,
  input  io_sinkB_bits_denied,
  input  io_sinkB_bits_corrupt,
  input  io_sinkB_bits_mshrTask,
  input  [7:0] io_sinkB_bits_mshrId,
  input  io_sinkB_bits_aliasTask,
  input  io_sinkB_bits_useProbeData,
  input  io_sinkB_bits_mshrRetry,
  input  io_sinkB_bits_readProbeDataDown,
  input  io_sinkB_bits_fromL2pft,
  input  io_sinkB_bits_needHint,
  input  io_sinkB_bits_dirty,
  input  [2:0] io_sinkB_bits_way,
  input  io_sinkB_bits_meta_dirty,
  input  [1:0] io_sinkB_bits_meta_state,
  input  io_sinkB_bits_meta_clients,
  input  [1:0] io_sinkB_bits_meta_alias,
  input  io_sinkB_bits_meta_prefetch,
  input  [2:0] io_sinkB_bits_meta_prefetchSrc,
  input  io_sinkB_bits_meta_accessed,
  input  io_sinkB_bits_meta_tagErr,
  input  io_sinkB_bits_meta_dataErr,
  input  io_sinkB_bits_metaWen,
  input  io_sinkB_bits_tagWen,
  input  io_sinkB_bits_dsWen,
  input  [7:0] io_sinkB_bits_wayMask,
  input  io_sinkB_bits_replTask,
  input  io_sinkB_bits_cmoTask,
  input  io_sinkB_bits_cmoAll,
  input  [4:0] io_sinkB_bits_reqSource,
  input  io_sinkB_bits_mergeA,
  input  [5:0] io_sinkB_bits_aMergeTask_off,
  input  [1:0] io_sinkB_bits_aMergeTask_alias,
  input  [43:0] io_sinkB_bits_aMergeTask_vaddr,
  input  io_sinkB_bits_aMergeTask_isKeyword,
  input  [2:0] io_sinkB_bits_aMergeTask_opcode,
  input  [2:0] io_sinkB_bits_aMergeTask_param,
  input  [6:0] io_sinkB_bits_aMergeTask_sourceId,
  input  io_sinkB_bits_aMergeTask_meta_dirty,
  input  [1:0] io_sinkB_bits_aMergeTask_meta_state,
  input  io_sinkB_bits_aMergeTask_meta_clients,
  input  [1:0] io_sinkB_bits_aMergeTask_meta_alias,
  input  io_sinkB_bits_aMergeTask_meta_prefetch,
  input  [2:0] io_sinkB_bits_aMergeTask_meta_prefetchSrc,
  input  io_sinkB_bits_aMergeTask_meta_accessed,
  input  io_sinkB_bits_aMergeTask_meta_tagErr,
  input  io_sinkB_bits_aMergeTask_meta_dataErr,
  input  io_sinkB_bits_snpHitRelease,
  input  io_sinkB_bits_snpHitReleaseToInval,
  input  io_sinkB_bits_snpHitReleaseToClean,
  input  io_sinkB_bits_snpHitReleaseWithData,
  input  [7:0] io_sinkB_bits_snpHitReleaseIdx,
  input  io_sinkB_bits_snpHitReleaseMeta_dirty,
  input  [1:0] io_sinkB_bits_snpHitReleaseMeta_state,
  input  io_sinkB_bits_snpHitReleaseMeta_clients,
  input  [1:0] io_sinkB_bits_snpHitReleaseMeta_alias,
  input  io_sinkB_bits_snpHitReleaseMeta_prefetch,
  input  [2:0] io_sinkB_bits_snpHitReleaseMeta_prefetchSrc,
  input  io_sinkB_bits_snpHitReleaseMeta_accessed,
  input  io_sinkB_bits_snpHitReleaseMeta_tagErr,
  input  io_sinkB_bits_snpHitReleaseMeta_dataErr,
  input  [10:0] io_sinkB_bits_tgtID,
  input  [10:0] io_sinkB_bits_srcID,
  input  [11:0] io_sinkB_bits_txnID,
  input  [10:0] io_sinkB_bits_homeNID,
  input  [11:0] io_sinkB_bits_dbID,
  input  [10:0] io_sinkB_bits_fwdNID,
  input  [11:0] io_sinkB_bits_fwdTxnID,
  input  [6:0] io_sinkB_bits_chiOpcode,
  input  [2:0] io_sinkB_bits_resp,
  input  [2:0] io_sinkB_bits_fwdState,
  input  [3:0] io_sinkB_bits_pCrdType,
  input  io_sinkB_bits_retToSrc,
  input  io_sinkB_bits_likelyshared,
  input  io_sinkB_bits_expCompAck,
  input  io_sinkB_bits_allowRetry,
  input  io_sinkB_bits_memAttr_allocate,
  input  io_sinkB_bits_memAttr_cacheable,
  input  io_sinkB_bits_memAttr_device,
  input  io_sinkB_bits_memAttr_ewa,
  input  io_sinkB_bits_traceTag,
  input  io_sinkB_bits_dataCheckErr,
  output  io_sinkC_ready,
  input  io_sinkC_valid,
  input  [2:0] io_sinkC_bits_channel,
  input  [2:0] io_sinkC_bits_txChannel,
  input  [8:0] io_sinkC_bits_set,
  input  [30:0] io_sinkC_bits_tag,
  input  [5:0] io_sinkC_bits_off,
  input  [1:0] io_sinkC_bits_alias,
  input  [43:0] io_sinkC_bits_vaddr,
  input  io_sinkC_bits_isKeyword,
  input  [3:0] io_sinkC_bits_opcode,
  input  [2:0] io_sinkC_bits_param,
  input  [2:0] io_sinkC_bits_size,
  input  [6:0] io_sinkC_bits_sourceId,
  input  [1:0] io_sinkC_bits_bufIdx,
  input  io_sinkC_bits_needProbeAckData,
  input  io_sinkC_bits_denied,
  input  io_sinkC_bits_corrupt,
  input  io_sinkC_bits_mshrTask,
  input  [7:0] io_sinkC_bits_mshrId,
  input  io_sinkC_bits_aliasTask,
  input  io_sinkC_bits_useProbeData,
  input  io_sinkC_bits_mshrRetry,
  input  io_sinkC_bits_readProbeDataDown,
  input  io_sinkC_bits_fromL2pft,
  input  io_sinkC_bits_needHint,
  input  io_sinkC_bits_dirty,
  input  [2:0] io_sinkC_bits_way,
  input  io_sinkC_bits_meta_dirty,
  input  [1:0] io_sinkC_bits_meta_state,
  input  io_sinkC_bits_meta_clients,
  input  [1:0] io_sinkC_bits_meta_alias,
  input  io_sinkC_bits_meta_prefetch,
  input  [2:0] io_sinkC_bits_meta_prefetchSrc,
  input  io_sinkC_bits_meta_accessed,
  input  io_sinkC_bits_meta_tagErr,
  input  io_sinkC_bits_meta_dataErr,
  input  io_sinkC_bits_metaWen,
  input  io_sinkC_bits_tagWen,
  input  io_sinkC_bits_dsWen,
  input  [7:0] io_sinkC_bits_wayMask,
  input  io_sinkC_bits_replTask,
  input  io_sinkC_bits_cmoTask,
  input  io_sinkC_bits_cmoAll,
  input  [4:0] io_sinkC_bits_reqSource,
  input  io_sinkC_bits_mergeA,
  input  [5:0] io_sinkC_bits_aMergeTask_off,
  input  [1:0] io_sinkC_bits_aMergeTask_alias,
  input  [43:0] io_sinkC_bits_aMergeTask_vaddr,
  input  io_sinkC_bits_aMergeTask_isKeyword,
  input  [2:0] io_sinkC_bits_aMergeTask_opcode,
  input  [2:0] io_sinkC_bits_aMergeTask_param,
  input  [6:0] io_sinkC_bits_aMergeTask_sourceId,
  input  io_sinkC_bits_aMergeTask_meta_dirty,
  input  [1:0] io_sinkC_bits_aMergeTask_meta_state,
  input  io_sinkC_bits_aMergeTask_meta_clients,
  input  [1:0] io_sinkC_bits_aMergeTask_meta_alias,
  input  io_sinkC_bits_aMergeTask_meta_prefetch,
  input  [2:0] io_sinkC_bits_aMergeTask_meta_prefetchSrc,
  input  io_sinkC_bits_aMergeTask_meta_accessed,
  input  io_sinkC_bits_aMergeTask_meta_tagErr,
  input  io_sinkC_bits_aMergeTask_meta_dataErr,
  input  io_sinkC_bits_snpHitRelease,
  input  io_sinkC_bits_snpHitReleaseToInval,
  input  io_sinkC_bits_snpHitReleaseToClean,
  input  io_sinkC_bits_snpHitReleaseWithData,
  input  [7:0] io_sinkC_bits_snpHitReleaseIdx,
  input  io_sinkC_bits_snpHitReleaseMeta_dirty,
  input  [1:0] io_sinkC_bits_snpHitReleaseMeta_state,
  input  io_sinkC_bits_snpHitReleaseMeta_clients,
  input  [1:0] io_sinkC_bits_snpHitReleaseMeta_alias,
  input  io_sinkC_bits_snpHitReleaseMeta_prefetch,
  input  [2:0] io_sinkC_bits_snpHitReleaseMeta_prefetchSrc,
  input  io_sinkC_bits_snpHitReleaseMeta_accessed,
  input  io_sinkC_bits_snpHitReleaseMeta_tagErr,
  input  io_sinkC_bits_snpHitReleaseMeta_dataErr,
  input  [10:0] io_sinkC_bits_tgtID,
  input  [10:0] io_sinkC_bits_srcID,
  input  [11:0] io_sinkC_bits_txnID,
  input  [10:0] io_sinkC_bits_homeNID,
  input  [11:0] io_sinkC_bits_dbID,
  input  [10:0] io_sinkC_bits_fwdNID,
  input  [11:0] io_sinkC_bits_fwdTxnID,
  input  [6:0] io_sinkC_bits_chiOpcode,
  input  [2:0] io_sinkC_bits_resp,
  input  [2:0] io_sinkC_bits_fwdState,
  input  [3:0] io_sinkC_bits_pCrdType,
  input  io_sinkC_bits_retToSrc,
  input  io_sinkC_bits_likelyshared,
  input  io_sinkC_bits_expCompAck,
  input  io_sinkC_bits_allowRetry,
  input  io_sinkC_bits_memAttr_allocate,
  input  io_sinkC_bits_memAttr_cacheable,
  input  io_sinkC_bits_memAttr_device,
  input  io_sinkC_bits_memAttr_ewa,
  input  io_sinkC_bits_traceTag,
  input  io_sinkC_bits_dataCheckErr,
  output  io_mshrTask_ready,
  input  io_mshrTask_valid,
  input  [2:0] io_mshrTask_bits_channel,
  input  [2:0] io_mshrTask_bits_txChannel,
  input  [8:0] io_mshrTask_bits_set,
  input  [30:0] io_mshrTask_bits_tag,
  input  [5:0] io_mshrTask_bits_off,
  input  [1:0] io_mshrTask_bits_alias,
  input  [43:0] io_mshrTask_bits_vaddr,
  input  io_mshrTask_bits_isKeyword,
  input  [3:0] io_mshrTask_bits_opcode,
  input  [2:0] io_mshrTask_bits_param,
  input  [2:0] io_mshrTask_bits_size,
  input  [6:0] io_mshrTask_bits_sourceId,
  input  [1:0] io_mshrTask_bits_bufIdx,
  input  io_mshrTask_bits_needProbeAckData,
  input  io_mshrTask_bits_denied,
  input  io_mshrTask_bits_corrupt,
  input  io_mshrTask_bits_mshrTask,
  input  [7:0] io_mshrTask_bits_mshrId,
  input  io_mshrTask_bits_aliasTask,
  input  io_mshrTask_bits_useProbeData,
  input  io_mshrTask_bits_mshrRetry,
  input  io_mshrTask_bits_readProbeDataDown,
  input  io_mshrTask_bits_fromL2pft,
  input  io_mshrTask_bits_needHint,
  input  io_mshrTask_bits_dirty,
  input  [2:0] io_mshrTask_bits_way,
  input  io_mshrTask_bits_meta_dirty,
  input  [1:0] io_mshrTask_bits_meta_state,
  input  io_mshrTask_bits_meta_clients,
  input  [1:0] io_mshrTask_bits_meta_alias,
  input  io_mshrTask_bits_meta_prefetch,
  input  [2:0] io_mshrTask_bits_meta_prefetchSrc,
  input  io_mshrTask_bits_meta_accessed,
  input  io_mshrTask_bits_meta_tagErr,
  input  io_mshrTask_bits_meta_dataErr,
  input  io_mshrTask_bits_metaWen,
  input  io_mshrTask_bits_tagWen,
  input  io_mshrTask_bits_dsWen,
  input  [7:0] io_mshrTask_bits_wayMask,
  input  io_mshrTask_bits_replTask,
  input  io_mshrTask_bits_cmoTask,
  input  io_mshrTask_bits_cmoAll,
  input  [4:0] io_mshrTask_bits_reqSource,
  input  io_mshrTask_bits_mergeA,
  input  [5:0] io_mshrTask_bits_aMergeTask_off,
  input  [1:0] io_mshrTask_bits_aMergeTask_alias,
  input  [43:0] io_mshrTask_bits_aMergeTask_vaddr,
  input  io_mshrTask_bits_aMergeTask_isKeyword,
  input  [2:0] io_mshrTask_bits_aMergeTask_opcode,
  input  [2:0] io_mshrTask_bits_aMergeTask_param,
  input  [6:0] io_mshrTask_bits_aMergeTask_sourceId,
  input  io_mshrTask_bits_aMergeTask_meta_dirty,
  input  [1:0] io_mshrTask_bits_aMergeTask_meta_state,
  input  io_mshrTask_bits_aMergeTask_meta_clients,
  input  [1:0] io_mshrTask_bits_aMergeTask_meta_alias,
  input  io_mshrTask_bits_aMergeTask_meta_prefetch,
  input  [2:0] io_mshrTask_bits_aMergeTask_meta_prefetchSrc,
  input  io_mshrTask_bits_aMergeTask_meta_accessed,
  input  io_mshrTask_bits_aMergeTask_meta_tagErr,
  input  io_mshrTask_bits_aMergeTask_meta_dataErr,
  input  io_mshrTask_bits_snpHitRelease,
  input  io_mshrTask_bits_snpHitReleaseToInval,
  input  io_mshrTask_bits_snpHitReleaseToClean,
  input  io_mshrTask_bits_snpHitReleaseWithData,
  input  [7:0] io_mshrTask_bits_snpHitReleaseIdx,
  input  io_mshrTask_bits_snpHitReleaseMeta_dirty,
  input  [1:0] io_mshrTask_bits_snpHitReleaseMeta_state,
  input  io_mshrTask_bits_snpHitReleaseMeta_clients,
  input  [1:0] io_mshrTask_bits_snpHitReleaseMeta_alias,
  input  io_mshrTask_bits_snpHitReleaseMeta_prefetch,
  input  [2:0] io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc,
  input  io_mshrTask_bits_snpHitReleaseMeta_accessed,
  input  io_mshrTask_bits_snpHitReleaseMeta_tagErr,
  input  io_mshrTask_bits_snpHitReleaseMeta_dataErr,
  input  [10:0] io_mshrTask_bits_tgtID,
  input  [10:0] io_mshrTask_bits_srcID,
  input  [11:0] io_mshrTask_bits_txnID,
  input  [10:0] io_mshrTask_bits_homeNID,
  input  [11:0] io_mshrTask_bits_dbID,
  input  [10:0] io_mshrTask_bits_fwdNID,
  input  [11:0] io_mshrTask_bits_fwdTxnID,
  input  [6:0] io_mshrTask_bits_chiOpcode,
  input  [2:0] io_mshrTask_bits_resp,
  input  [2:0] io_mshrTask_bits_fwdState,
  input  [3:0] io_mshrTask_bits_pCrdType,
  input  io_mshrTask_bits_retToSrc,
  input  io_mshrTask_bits_likelyshared,
  input  io_mshrTask_bits_expCompAck,
  input  io_mshrTask_bits_allowRetry,
  input  io_mshrTask_bits_memAttr_allocate,
  input  io_mshrTask_bits_memAttr_cacheable,
  input  io_mshrTask_bits_memAttr_device,
  input  io_mshrTask_bits_memAttr_ewa,
  input  io_mshrTask_bits_traceTag,
  input  io_mshrTask_bits_dataCheckErr,
  input  io_dirRead_s1_ready,
  output  io_dirRead_s1_valid,
  output  [30:0] io_dirRead_s1_bits_tag,
  output  [8:0] io_dirRead_s1_bits_set,
  output  [7:0] io_dirRead_s1_bits_wayMask,
  output  [2:0] io_dirRead_s1_bits_replacerInfo_channel,
  output  [2:0] io_dirRead_s1_bits_replacerInfo_opcode,
  output  [4:0] io_dirRead_s1_bits_replacerInfo_reqSource,
  output  io_dirRead_s1_bits_replacerInfo_refill_prefetch,
  output  io_dirRead_s1_bits_refill,
  output  [7:0] io_dirRead_s1_bits_mshrId,
  output  io_dirRead_s1_bits_cmoAll,
  output  [2:0] io_dirRead_s1_bits_cmoWay,
  output  io_taskToPipe_s2_valid,
  output  [2:0] io_taskToPipe_s2_bits_channel,
  output  [2:0] io_taskToPipe_s2_bits_txChannel,
  output  [8:0] io_taskToPipe_s2_bits_set,
  output  [30:0] io_taskToPipe_s2_bits_tag,
  output  [5:0] io_taskToPipe_s2_bits_off,
  output  [1:0] io_taskToPipe_s2_bits_alias,
  output  [43:0] io_taskToPipe_s2_bits_vaddr,
  output  io_taskToPipe_s2_bits_isKeyword,
  output  [3:0] io_taskToPipe_s2_bits_opcode,
  output  [2:0] io_taskToPipe_s2_bits_param,
  output  [2:0] io_taskToPipe_s2_bits_size,
  output  [6:0] io_taskToPipe_s2_bits_sourceId,
  output  [1:0] io_taskToPipe_s2_bits_bufIdx,
  output  io_taskToPipe_s2_bits_needProbeAckData,
  output  io_taskToPipe_s2_bits_denied,
  output  io_taskToPipe_s2_bits_corrupt,
  output  io_taskToPipe_s2_bits_mshrTask,
  output  [7:0] io_taskToPipe_s2_bits_mshrId,
  output  io_taskToPipe_s2_bits_aliasTask,
  output  io_taskToPipe_s2_bits_useProbeData,
  output  io_taskToPipe_s2_bits_mshrRetry,
  output  io_taskToPipe_s2_bits_readProbeDataDown,
  output  io_taskToPipe_s2_bits_fromL2pft,
  output  io_taskToPipe_s2_bits_needHint,
  output  io_taskToPipe_s2_bits_dirty,
  output  [2:0] io_taskToPipe_s2_bits_way,
  output  io_taskToPipe_s2_bits_meta_dirty,
  output  [1:0] io_taskToPipe_s2_bits_meta_state,
  output  io_taskToPipe_s2_bits_meta_clients,
  output  [1:0] io_taskToPipe_s2_bits_meta_alias,
  output  io_taskToPipe_s2_bits_meta_prefetch,
  output  [2:0] io_taskToPipe_s2_bits_meta_prefetchSrc,
  output  io_taskToPipe_s2_bits_meta_accessed,
  output  io_taskToPipe_s2_bits_meta_tagErr,
  output  io_taskToPipe_s2_bits_meta_dataErr,
  output  io_taskToPipe_s2_bits_metaWen,
  output  io_taskToPipe_s2_bits_tagWen,
  output  io_taskToPipe_s2_bits_dsWen,
  output  [7:0] io_taskToPipe_s2_bits_wayMask,
  output  io_taskToPipe_s2_bits_replTask,
  output  io_taskToPipe_s2_bits_cmoTask,
  output  io_taskToPipe_s2_bits_cmoAll,
  output  [4:0] io_taskToPipe_s2_bits_reqSource,
  output  io_taskToPipe_s2_bits_mergeA,
  output  [5:0] io_taskToPipe_s2_bits_aMergeTask_off,
  output  [1:0] io_taskToPipe_s2_bits_aMergeTask_alias,
  output  [43:0] io_taskToPipe_s2_bits_aMergeTask_vaddr,
  output  io_taskToPipe_s2_bits_aMergeTask_isKeyword,
  output  [2:0] io_taskToPipe_s2_bits_aMergeTask_opcode,
  output  [2:0] io_taskToPipe_s2_bits_aMergeTask_param,
  output  [6:0] io_taskToPipe_s2_bits_aMergeTask_sourceId,
  output  io_taskToPipe_s2_bits_aMergeTask_meta_dirty,
  output  [1:0] io_taskToPipe_s2_bits_aMergeTask_meta_state,
  output  io_taskToPipe_s2_bits_aMergeTask_meta_clients,
  output  [1:0] io_taskToPipe_s2_bits_aMergeTask_meta_alias,
  output  io_taskToPipe_s2_bits_aMergeTask_meta_prefetch,
  output  [2:0] io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc,
  output  io_taskToPipe_s2_bits_aMergeTask_meta_accessed,
  output  io_taskToPipe_s2_bits_aMergeTask_meta_tagErr,
  output  io_taskToPipe_s2_bits_aMergeTask_meta_dataErr,
  output  io_taskToPipe_s2_bits_snpHitRelease,
  output  io_taskToPipe_s2_bits_snpHitReleaseToInval,
  output  io_taskToPipe_s2_bits_snpHitReleaseToClean,
  output  io_taskToPipe_s2_bits_snpHitReleaseWithData,
  output  [7:0] io_taskToPipe_s2_bits_snpHitReleaseIdx,
  output  io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty,
  output  [1:0] io_taskToPipe_s2_bits_snpHitReleaseMeta_state,
  output  io_taskToPipe_s2_bits_snpHitReleaseMeta_clients,
  output  [1:0] io_taskToPipe_s2_bits_snpHitReleaseMeta_alias,
  output  io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch,
  output  [2:0] io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc,
  output  io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed,
  output  io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr,
  output  io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr,
  output  [10:0] io_taskToPipe_s2_bits_tgtID,
  output  [10:0] io_taskToPipe_s2_bits_srcID,
  output  [11:0] io_taskToPipe_s2_bits_txnID,
  output  [10:0] io_taskToPipe_s2_bits_homeNID,
  output  [11:0] io_taskToPipe_s2_bits_dbID,
  output  [10:0] io_taskToPipe_s2_bits_fwdNID,
  output  [11:0] io_taskToPipe_s2_bits_fwdTxnID,
  output  [6:0] io_taskToPipe_s2_bits_chiOpcode,
  output  [2:0] io_taskToPipe_s2_bits_resp,
  output  [2:0] io_taskToPipe_s2_bits_fwdState,
  output  [3:0] io_taskToPipe_s2_bits_pCrdType,
  output  io_taskToPipe_s2_bits_retToSrc,
  output  io_taskToPipe_s2_bits_likelyshared,
  output  io_taskToPipe_s2_bits_expCompAck,
  output  io_taskToPipe_s2_bits_allowRetry,
  output  io_taskToPipe_s2_bits_memAttr_allocate,
  output  io_taskToPipe_s2_bits_memAttr_cacheable,
  output  io_taskToPipe_s2_bits_memAttr_device,
  output  io_taskToPipe_s2_bits_memAttr_ewa,
  output  io_taskToPipe_s2_bits_traceTag,
  output  io_taskToPipe_s2_bits_dataCheckErr,
  output  io_taskInfo_s1_valid,
  output  [2:0] io_taskInfo_s1_bits_channel,
  output  [2:0] io_taskInfo_s1_bits_txChannel,
  output  [8:0] io_taskInfo_s1_bits_set,
  output  [30:0] io_taskInfo_s1_bits_tag,
  output  [5:0] io_taskInfo_s1_bits_off,
  output  [1:0] io_taskInfo_s1_bits_alias,
  output  [43:0] io_taskInfo_s1_bits_vaddr,
  output  io_taskInfo_s1_bits_isKeyword,
  output  [3:0] io_taskInfo_s1_bits_opcode,
  output  [2:0] io_taskInfo_s1_bits_param,
  output  [2:0] io_taskInfo_s1_bits_size,
  output  [6:0] io_taskInfo_s1_bits_sourceId,
  output  [1:0] io_taskInfo_s1_bits_bufIdx,
  output  io_taskInfo_s1_bits_needProbeAckData,
  output  io_taskInfo_s1_bits_denied,
  output  io_taskInfo_s1_bits_corrupt,
  output  io_taskInfo_s1_bits_mshrTask,
  output  [7:0] io_taskInfo_s1_bits_mshrId,
  output  io_taskInfo_s1_bits_aliasTask,
  output  io_taskInfo_s1_bits_useProbeData,
  output  io_taskInfo_s1_bits_mshrRetry,
  output  io_taskInfo_s1_bits_readProbeDataDown,
  output  io_taskInfo_s1_bits_fromL2pft,
  output  io_taskInfo_s1_bits_needHint,
  output  io_taskInfo_s1_bits_dirty,
  output  [2:0] io_taskInfo_s1_bits_way,
  output  io_taskInfo_s1_bits_meta_dirty,
  output  [1:0] io_taskInfo_s1_bits_meta_state,
  output  io_taskInfo_s1_bits_meta_clients,
  output  [1:0] io_taskInfo_s1_bits_meta_alias,
  output  io_taskInfo_s1_bits_meta_prefetch,
  output  [2:0] io_taskInfo_s1_bits_meta_prefetchSrc,
  output  io_taskInfo_s1_bits_meta_accessed,
  output  io_taskInfo_s1_bits_meta_tagErr,
  output  io_taskInfo_s1_bits_meta_dataErr,
  output  io_taskInfo_s1_bits_metaWen,
  output  io_taskInfo_s1_bits_tagWen,
  output  io_taskInfo_s1_bits_dsWen,
  output  [7:0] io_taskInfo_s1_bits_wayMask,
  output  io_taskInfo_s1_bits_replTask,
  output  io_taskInfo_s1_bits_cmoTask,
  output  io_taskInfo_s1_bits_cmoAll,
  output  [4:0] io_taskInfo_s1_bits_reqSource,
  output  io_taskInfo_s1_bits_mergeA,
  output  [5:0] io_taskInfo_s1_bits_aMergeTask_off,
  output  [1:0] io_taskInfo_s1_bits_aMergeTask_alias,
  output  [43:0] io_taskInfo_s1_bits_aMergeTask_vaddr,
  output  io_taskInfo_s1_bits_aMergeTask_isKeyword,
  output  [2:0] io_taskInfo_s1_bits_aMergeTask_opcode,
  output  [2:0] io_taskInfo_s1_bits_aMergeTask_param,
  output  [6:0] io_taskInfo_s1_bits_aMergeTask_sourceId,
  output  io_taskInfo_s1_bits_aMergeTask_meta_dirty,
  output  [1:0] io_taskInfo_s1_bits_aMergeTask_meta_state,
  output  io_taskInfo_s1_bits_aMergeTask_meta_clients,
  output  [1:0] io_taskInfo_s1_bits_aMergeTask_meta_alias,
  output  io_taskInfo_s1_bits_aMergeTask_meta_prefetch,
  output  [2:0] io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc,
  output  io_taskInfo_s1_bits_aMergeTask_meta_accessed,
  output  io_taskInfo_s1_bits_aMergeTask_meta_tagErr,
  output  io_taskInfo_s1_bits_aMergeTask_meta_dataErr,
  output  io_taskInfo_s1_bits_snpHitRelease,
  output  io_taskInfo_s1_bits_snpHitReleaseToInval,
  output  io_taskInfo_s1_bits_snpHitReleaseToClean,
  output  io_taskInfo_s1_bits_snpHitReleaseWithData,
  output  [7:0] io_taskInfo_s1_bits_snpHitReleaseIdx,
  output  io_taskInfo_s1_bits_snpHitReleaseMeta_dirty,
  output  [1:0] io_taskInfo_s1_bits_snpHitReleaseMeta_state,
  output  io_taskInfo_s1_bits_snpHitReleaseMeta_clients,
  output  [1:0] io_taskInfo_s1_bits_snpHitReleaseMeta_alias,
  output  io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch,
  output  [2:0] io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc,
  output  io_taskInfo_s1_bits_snpHitReleaseMeta_accessed,
  output  io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr,
  output  io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr,
  output  [10:0] io_taskInfo_s1_bits_tgtID,
  output  [10:0] io_taskInfo_s1_bits_srcID,
  output  [11:0] io_taskInfo_s1_bits_txnID,
  output  [10:0] io_taskInfo_s1_bits_homeNID,
  output  [11:0] io_taskInfo_s1_bits_dbID,
  output  [10:0] io_taskInfo_s1_bits_fwdNID,
  output  [11:0] io_taskInfo_s1_bits_fwdTxnID,
  output  [6:0] io_taskInfo_s1_bits_chiOpcode,
  output  [2:0] io_taskInfo_s1_bits_resp,
  output  [2:0] io_taskInfo_s1_bits_fwdState,
  output  [3:0] io_taskInfo_s1_bits_pCrdType,
  output  io_taskInfo_s1_bits_retToSrc,
  output  io_taskInfo_s1_bits_likelyshared,
  output  io_taskInfo_s1_bits_expCompAck,
  output  io_taskInfo_s1_bits_allowRetry,
  output  io_taskInfo_s1_bits_memAttr_allocate,
  output  io_taskInfo_s1_bits_memAttr_cacheable,
  output  io_taskInfo_s1_bits_memAttr_device,
  output  io_taskInfo_s1_bits_memAttr_ewa,
  output  io_taskInfo_s1_bits_traceTag,
  output  io_taskInfo_s1_bits_dataCheckErr,
  output  io_refillBufRead_s2_valid,
  output  [7:0] io_refillBufRead_s2_bits_id,
  output  io_releaseBufRead_s2_valid,
  output  [7:0] io_releaseBufRead_s2_bits_id,
  output  [30:0] io_status_s1_tags_0,
  output  [30:0] io_status_s1_tags_1,
  output  [30:0] io_status_s1_tags_2,
  output  [30:0] io_status_s1_tags_3,
  output  [8:0] io_status_s1_sets_0,
  output  [8:0] io_status_s1_sets_1,
  output  [8:0] io_status_s1_sets_2,
  output  [8:0] io_status_s1_sets_3,
  output  io_status_vec_0_valid,
  output  [2:0] io_status_vec_0_bits_channel,
  output  io_status_vec_1_valid,
  output  [2:0] io_status_vec_1_bits_channel,
  output  io_status_vec_toTX_0_valid,
  output  [2:0] io_status_vec_toTX_0_bits_channel,
  output  [2:0] io_status_vec_toTX_0_bits_txChannel,
  output  io_status_vec_toTX_0_bits_mshrTask,
  output  io_status_vec_toTX_1_valid,
  output  [2:0] io_status_vec_toTX_1_bits_channel,
  output  [2:0] io_status_vec_toTX_1_bits_txChannel,
  output  io_status_vec_toTX_1_bits_mshrTask,
  input  io_fromMSHRCtl_blockG_s1,
  input  io_fromMSHRCtl_blockA_s1,
  input  io_fromMSHRCtl_blockB_s1,
  input  io_fromMSHRCtl_blockC_s1,
  input  io_fromMainPipe_blockG_s1,
  input  io_fromMainPipe_blockA_s1,
  input  io_fromMainPipe_blockB_s1,
  input  io_fromMainPipe_blockC_s1,
  input  io_fromGrantBuffer_blockSinkReqEntrance_blockG_s1,
  input  io_fromGrantBuffer_blockSinkReqEntrance_blockA_s1,
  input  io_fromGrantBuffer_blockSinkReqEntrance_blockB_s1,
  input  io_fromGrantBuffer_blockSinkReqEntrance_blockC_s1,
  input  io_fromGrantBuffer_blockMSHRReqEntrance,
  input  io_fromTXDAT_blockMSHRReqEntrance,
  input  io_fromTXDAT_blockSinkBReqEntrance,
  input  io_fromTXRSP_blockMSHRReqEntrance,
  input  io_fromTXRSP_blockSinkBReqEntrance,
  input  io_fromTXREQ_blockMSHRReqEntrance,
  input  io_msInfo_0_valid,
  input  [2:0] io_msInfo_0_bits_channel,
  input  [8:0] io_msInfo_0_bits_set,
  input  [2:0] io_msInfo_0_bits_way,
  input  [30:0] io_msInfo_0_bits_reqTag,
  input  io_msInfo_0_bits_willFree,
  input  io_msInfo_0_bits_aliasTask,
  input  io_msInfo_0_bits_needRelease,
  input  io_msInfo_0_bits_blockRefill,
  input  io_msInfo_0_bits_meta_dirty,
  input  [1:0] io_msInfo_0_bits_meta_state,
  input  io_msInfo_0_bits_meta_clients,
  input  [1:0] io_msInfo_0_bits_meta_alias,
  input  io_msInfo_0_bits_meta_prefetch,
  input  [2:0] io_msInfo_0_bits_meta_prefetchSrc,
  input  io_msInfo_0_bits_meta_accessed,
  input  io_msInfo_0_bits_meta_tagErr,
  input  io_msInfo_0_bits_meta_dataErr,
  input  [30:0] io_msInfo_0_bits_metaTag,
  input  io_msInfo_0_bits_dirHit,
  input  io_msInfo_0_bits_isAcqOrPrefetch,
  input  io_msInfo_0_bits_isPrefetch,
  input  [2:0] io_msInfo_0_bits_param,
  input  io_msInfo_0_bits_mergeA,
  input  io_msInfo_0_bits_w_grantfirst,
  input  io_msInfo_0_bits_s_release,
  input  io_msInfo_0_bits_s_refill,
  input  io_msInfo_0_bits_s_cmoresp,
  input  io_msInfo_0_bits_s_cmometaw,
  input  io_msInfo_0_bits_w_releaseack,
  input  io_msInfo_0_bits_w_replResp,
  input  io_msInfo_0_bits_w_rprobeacklast,
  input  io_msInfo_0_bits_replaceData,
  input  io_msInfo_0_bits_releaseToClean,
  input  io_msInfo_1_valid,
  input  [2:0] io_msInfo_1_bits_channel,
  input  [8:0] io_msInfo_1_bits_set,
  input  [2:0] io_msInfo_1_bits_way,
  input  [30:0] io_msInfo_1_bits_reqTag,
  input  io_msInfo_1_bits_willFree,
  input  io_msInfo_1_bits_aliasTask,
  input  io_msInfo_1_bits_needRelease,
  input  io_msInfo_1_bits_blockRefill,
  input  io_msInfo_1_bits_meta_dirty,
  input  [1:0] io_msInfo_1_bits_meta_state,
  input  io_msInfo_1_bits_meta_clients,
  input  [1:0] io_msInfo_1_bits_meta_alias,
  input  io_msInfo_1_bits_meta_prefetch,
  input  [2:0] io_msInfo_1_bits_meta_prefetchSrc,
  input  io_msInfo_1_bits_meta_accessed,
  input  io_msInfo_1_bits_meta_tagErr,
  input  io_msInfo_1_bits_meta_dataErr,
  input  [30:0] io_msInfo_1_bits_metaTag,
  input  io_msInfo_1_bits_dirHit,
  input  io_msInfo_1_bits_isAcqOrPrefetch,
  input  io_msInfo_1_bits_isPrefetch,
  input  [2:0] io_msInfo_1_bits_param,
  input  io_msInfo_1_bits_mergeA,
  input  io_msInfo_1_bits_w_grantfirst,
  input  io_msInfo_1_bits_s_release,
  input  io_msInfo_1_bits_s_refill,
  input  io_msInfo_1_bits_s_cmoresp,
  input  io_msInfo_1_bits_s_cmometaw,
  input  io_msInfo_1_bits_w_releaseack,
  input  io_msInfo_1_bits_w_replResp,
  input  io_msInfo_1_bits_w_rprobeacklast,
  input  io_msInfo_1_bits_replaceData,
  input  io_msInfo_1_bits_releaseToClean,
  input  io_msInfo_2_valid,
  input  [2:0] io_msInfo_2_bits_channel,
  input  [8:0] io_msInfo_2_bits_set,
  input  [2:0] io_msInfo_2_bits_way,
  input  [30:0] io_msInfo_2_bits_reqTag,
  input  io_msInfo_2_bits_willFree,
  input  io_msInfo_2_bits_aliasTask,
  input  io_msInfo_2_bits_needRelease,
  input  io_msInfo_2_bits_blockRefill,
  input  io_msInfo_2_bits_meta_dirty,
  input  [1:0] io_msInfo_2_bits_meta_state,
  input  io_msInfo_2_bits_meta_clients,
  input  [1:0] io_msInfo_2_bits_meta_alias,
  input  io_msInfo_2_bits_meta_prefetch,
  input  [2:0] io_msInfo_2_bits_meta_prefetchSrc,
  input  io_msInfo_2_bits_meta_accessed,
  input  io_msInfo_2_bits_meta_tagErr,
  input  io_msInfo_2_bits_meta_dataErr,
  input  [30:0] io_msInfo_2_bits_metaTag,
  input  io_msInfo_2_bits_dirHit,
  input  io_msInfo_2_bits_isAcqOrPrefetch,
  input  io_msInfo_2_bits_isPrefetch,
  input  [2:0] io_msInfo_2_bits_param,
  input  io_msInfo_2_bits_mergeA,
  input  io_msInfo_2_bits_w_grantfirst,
  input  io_msInfo_2_bits_s_release,
  input  io_msInfo_2_bits_s_refill,
  input  io_msInfo_2_bits_s_cmoresp,
  input  io_msInfo_2_bits_s_cmometaw,
  input  io_msInfo_2_bits_w_releaseack,
  input  io_msInfo_2_bits_w_replResp,
  input  io_msInfo_2_bits_w_rprobeacklast,
  input  io_msInfo_2_bits_replaceData,
  input  io_msInfo_2_bits_releaseToClean,
  input  io_msInfo_3_valid,
  input  [2:0] io_msInfo_3_bits_channel,
  input  [8:0] io_msInfo_3_bits_set,
  input  [2:0] io_msInfo_3_bits_way,
  input  [30:0] io_msInfo_3_bits_reqTag,
  input  io_msInfo_3_bits_willFree,
  input  io_msInfo_3_bits_aliasTask,
  input  io_msInfo_3_bits_needRelease,
  input  io_msInfo_3_bits_blockRefill,
  input  io_msInfo_3_bits_meta_dirty,
  input  [1:0] io_msInfo_3_bits_meta_state,
  input  io_msInfo_3_bits_meta_clients,
  input  [1:0] io_msInfo_3_bits_meta_alias,
  input  io_msInfo_3_bits_meta_prefetch,
  input  [2:0] io_msInfo_3_bits_meta_prefetchSrc,
  input  io_msInfo_3_bits_meta_accessed,
  input  io_msInfo_3_bits_meta_tagErr,
  input  io_msInfo_3_bits_meta_dataErr,
  input  [30:0] io_msInfo_3_bits_metaTag,
  input  io_msInfo_3_bits_dirHit,
  input  io_msInfo_3_bits_isAcqOrPrefetch,
  input  io_msInfo_3_bits_isPrefetch,
  input  [2:0] io_msInfo_3_bits_param,
  input  io_msInfo_3_bits_mergeA,
  input  io_msInfo_3_bits_w_grantfirst,
  input  io_msInfo_3_bits_s_release,
  input  io_msInfo_3_bits_s_refill,
  input  io_msInfo_3_bits_s_cmoresp,
  input  io_msInfo_3_bits_s_cmometaw,
  input  io_msInfo_3_bits_w_releaseack,
  input  io_msInfo_3_bits_w_replResp,
  input  io_msInfo_3_bits_w_rprobeacklast,
  input  io_msInfo_3_bits_replaceData,
  input  io_msInfo_3_bits_releaseToClean,
  input  io_msInfo_4_valid,
  input  [2:0] io_msInfo_4_bits_channel,
  input  [8:0] io_msInfo_4_bits_set,
  input  [2:0] io_msInfo_4_bits_way,
  input  [30:0] io_msInfo_4_bits_reqTag,
  input  io_msInfo_4_bits_willFree,
  input  io_msInfo_4_bits_aliasTask,
  input  io_msInfo_4_bits_needRelease,
  input  io_msInfo_4_bits_blockRefill,
  input  io_msInfo_4_bits_meta_dirty,
  input  [1:0] io_msInfo_4_bits_meta_state,
  input  io_msInfo_4_bits_meta_clients,
  input  [1:0] io_msInfo_4_bits_meta_alias,
  input  io_msInfo_4_bits_meta_prefetch,
  input  [2:0] io_msInfo_4_bits_meta_prefetchSrc,
  input  io_msInfo_4_bits_meta_accessed,
  input  io_msInfo_4_bits_meta_tagErr,
  input  io_msInfo_4_bits_meta_dataErr,
  input  [30:0] io_msInfo_4_bits_metaTag,
  input  io_msInfo_4_bits_dirHit,
  input  io_msInfo_4_bits_isAcqOrPrefetch,
  input  io_msInfo_4_bits_isPrefetch,
  input  [2:0] io_msInfo_4_bits_param,
  input  io_msInfo_4_bits_mergeA,
  input  io_msInfo_4_bits_w_grantfirst,
  input  io_msInfo_4_bits_s_release,
  input  io_msInfo_4_bits_s_refill,
  input  io_msInfo_4_bits_s_cmoresp,
  input  io_msInfo_4_bits_s_cmometaw,
  input  io_msInfo_4_bits_w_releaseack,
  input  io_msInfo_4_bits_w_replResp,
  input  io_msInfo_4_bits_w_rprobeacklast,
  input  io_msInfo_4_bits_replaceData,
  input  io_msInfo_4_bits_releaseToClean,
  input  io_msInfo_5_valid,
  input  [2:0] io_msInfo_5_bits_channel,
  input  [8:0] io_msInfo_5_bits_set,
  input  [2:0] io_msInfo_5_bits_way,
  input  [30:0] io_msInfo_5_bits_reqTag,
  input  io_msInfo_5_bits_willFree,
  input  io_msInfo_5_bits_aliasTask,
  input  io_msInfo_5_bits_needRelease,
  input  io_msInfo_5_bits_blockRefill,
  input  io_msInfo_5_bits_meta_dirty,
  input  [1:0] io_msInfo_5_bits_meta_state,
  input  io_msInfo_5_bits_meta_clients,
  input  [1:0] io_msInfo_5_bits_meta_alias,
  input  io_msInfo_5_bits_meta_prefetch,
  input  [2:0] io_msInfo_5_bits_meta_prefetchSrc,
  input  io_msInfo_5_bits_meta_accessed,
  input  io_msInfo_5_bits_meta_tagErr,
  input  io_msInfo_5_bits_meta_dataErr,
  input  [30:0] io_msInfo_5_bits_metaTag,
  input  io_msInfo_5_bits_dirHit,
  input  io_msInfo_5_bits_isAcqOrPrefetch,
  input  io_msInfo_5_bits_isPrefetch,
  input  [2:0] io_msInfo_5_bits_param,
  input  io_msInfo_5_bits_mergeA,
  input  io_msInfo_5_bits_w_grantfirst,
  input  io_msInfo_5_bits_s_release,
  input  io_msInfo_5_bits_s_refill,
  input  io_msInfo_5_bits_s_cmoresp,
  input  io_msInfo_5_bits_s_cmometaw,
  input  io_msInfo_5_bits_w_releaseack,
  input  io_msInfo_5_bits_w_replResp,
  input  io_msInfo_5_bits_w_rprobeacklast,
  input  io_msInfo_5_bits_replaceData,
  input  io_msInfo_5_bits_releaseToClean,
  input  io_msInfo_6_valid,
  input  [2:0] io_msInfo_6_bits_channel,
  input  [8:0] io_msInfo_6_bits_set,
  input  [2:0] io_msInfo_6_bits_way,
  input  [30:0] io_msInfo_6_bits_reqTag,
  input  io_msInfo_6_bits_willFree,
  input  io_msInfo_6_bits_aliasTask,
  input  io_msInfo_6_bits_needRelease,
  input  io_msInfo_6_bits_blockRefill,
  input  io_msInfo_6_bits_meta_dirty,
  input  [1:0] io_msInfo_6_bits_meta_state,
  input  io_msInfo_6_bits_meta_clients,
  input  [1:0] io_msInfo_6_bits_meta_alias,
  input  io_msInfo_6_bits_meta_prefetch,
  input  [2:0] io_msInfo_6_bits_meta_prefetchSrc,
  input  io_msInfo_6_bits_meta_accessed,
  input  io_msInfo_6_bits_meta_tagErr,
  input  io_msInfo_6_bits_meta_dataErr,
  input  [30:0] io_msInfo_6_bits_metaTag,
  input  io_msInfo_6_bits_dirHit,
  input  io_msInfo_6_bits_isAcqOrPrefetch,
  input  io_msInfo_6_bits_isPrefetch,
  input  [2:0] io_msInfo_6_bits_param,
  input  io_msInfo_6_bits_mergeA,
  input  io_msInfo_6_bits_w_grantfirst,
  input  io_msInfo_6_bits_s_release,
  input  io_msInfo_6_bits_s_refill,
  input  io_msInfo_6_bits_s_cmoresp,
  input  io_msInfo_6_bits_s_cmometaw,
  input  io_msInfo_6_bits_w_releaseack,
  input  io_msInfo_6_bits_w_replResp,
  input  io_msInfo_6_bits_w_rprobeacklast,
  input  io_msInfo_6_bits_replaceData,
  input  io_msInfo_6_bits_releaseToClean,
  input  io_msInfo_7_valid,
  input  [2:0] io_msInfo_7_bits_channel,
  input  [8:0] io_msInfo_7_bits_set,
  input  [2:0] io_msInfo_7_bits_way,
  input  [30:0] io_msInfo_7_bits_reqTag,
  input  io_msInfo_7_bits_willFree,
  input  io_msInfo_7_bits_aliasTask,
  input  io_msInfo_7_bits_needRelease,
  input  io_msInfo_7_bits_blockRefill,
  input  io_msInfo_7_bits_meta_dirty,
  input  [1:0] io_msInfo_7_bits_meta_state,
  input  io_msInfo_7_bits_meta_clients,
  input  [1:0] io_msInfo_7_bits_meta_alias,
  input  io_msInfo_7_bits_meta_prefetch,
  input  [2:0] io_msInfo_7_bits_meta_prefetchSrc,
  input  io_msInfo_7_bits_meta_accessed,
  input  io_msInfo_7_bits_meta_tagErr,
  input  io_msInfo_7_bits_meta_dataErr,
  input  [30:0] io_msInfo_7_bits_metaTag,
  input  io_msInfo_7_bits_dirHit,
  input  io_msInfo_7_bits_isAcqOrPrefetch,
  input  io_msInfo_7_bits_isPrefetch,
  input  [2:0] io_msInfo_7_bits_param,
  input  io_msInfo_7_bits_mergeA,
  input  io_msInfo_7_bits_w_grantfirst,
  input  io_msInfo_7_bits_s_release,
  input  io_msInfo_7_bits_s_refill,
  input  io_msInfo_7_bits_s_cmoresp,
  input  io_msInfo_7_bits_s_cmometaw,
  input  io_msInfo_7_bits_w_releaseack,
  input  io_msInfo_7_bits_w_replResp,
  input  io_msInfo_7_bits_w_rprobeacklast,
  input  io_msInfo_7_bits_replaceData,
  input  io_msInfo_7_bits_releaseToClean,
  input  io_msInfo_8_valid,
  input  [2:0] io_msInfo_8_bits_channel,
  input  [8:0] io_msInfo_8_bits_set,
  input  [2:0] io_msInfo_8_bits_way,
  input  [30:0] io_msInfo_8_bits_reqTag,
  input  io_msInfo_8_bits_willFree,
  input  io_msInfo_8_bits_aliasTask,
  input  io_msInfo_8_bits_needRelease,
  input  io_msInfo_8_bits_blockRefill,
  input  io_msInfo_8_bits_meta_dirty,
  input  [1:0] io_msInfo_8_bits_meta_state,
  input  io_msInfo_8_bits_meta_clients,
  input  [1:0] io_msInfo_8_bits_meta_alias,
  input  io_msInfo_8_bits_meta_prefetch,
  input  [2:0] io_msInfo_8_bits_meta_prefetchSrc,
  input  io_msInfo_8_bits_meta_accessed,
  input  io_msInfo_8_bits_meta_tagErr,
  input  io_msInfo_8_bits_meta_dataErr,
  input  [30:0] io_msInfo_8_bits_metaTag,
  input  io_msInfo_8_bits_dirHit,
  input  io_msInfo_8_bits_isAcqOrPrefetch,
  input  io_msInfo_8_bits_isPrefetch,
  input  [2:0] io_msInfo_8_bits_param,
  input  io_msInfo_8_bits_mergeA,
  input  io_msInfo_8_bits_w_grantfirst,
  input  io_msInfo_8_bits_s_release,
  input  io_msInfo_8_bits_s_refill,
  input  io_msInfo_8_bits_s_cmoresp,
  input  io_msInfo_8_bits_s_cmometaw,
  input  io_msInfo_8_bits_w_releaseack,
  input  io_msInfo_8_bits_w_replResp,
  input  io_msInfo_8_bits_w_rprobeacklast,
  input  io_msInfo_8_bits_replaceData,
  input  io_msInfo_8_bits_releaseToClean,
  input  io_msInfo_9_valid,
  input  [2:0] io_msInfo_9_bits_channel,
  input  [8:0] io_msInfo_9_bits_set,
  input  [2:0] io_msInfo_9_bits_way,
  input  [30:0] io_msInfo_9_bits_reqTag,
  input  io_msInfo_9_bits_willFree,
  input  io_msInfo_9_bits_aliasTask,
  input  io_msInfo_9_bits_needRelease,
  input  io_msInfo_9_bits_blockRefill,
  input  io_msInfo_9_bits_meta_dirty,
  input  [1:0] io_msInfo_9_bits_meta_state,
  input  io_msInfo_9_bits_meta_clients,
  input  [1:0] io_msInfo_9_bits_meta_alias,
  input  io_msInfo_9_bits_meta_prefetch,
  input  [2:0] io_msInfo_9_bits_meta_prefetchSrc,
  input  io_msInfo_9_bits_meta_accessed,
  input  io_msInfo_9_bits_meta_tagErr,
  input  io_msInfo_9_bits_meta_dataErr,
  input  [30:0] io_msInfo_9_bits_metaTag,
  input  io_msInfo_9_bits_dirHit,
  input  io_msInfo_9_bits_isAcqOrPrefetch,
  input  io_msInfo_9_bits_isPrefetch,
  input  [2:0] io_msInfo_9_bits_param,
  input  io_msInfo_9_bits_mergeA,
  input  io_msInfo_9_bits_w_grantfirst,
  input  io_msInfo_9_bits_s_release,
  input  io_msInfo_9_bits_s_refill,
  input  io_msInfo_9_bits_s_cmoresp,
  input  io_msInfo_9_bits_s_cmometaw,
  input  io_msInfo_9_bits_w_releaseack,
  input  io_msInfo_9_bits_w_replResp,
  input  io_msInfo_9_bits_w_rprobeacklast,
  input  io_msInfo_9_bits_replaceData,
  input  io_msInfo_9_bits_releaseToClean,
  input  io_msInfo_10_valid,
  input  [2:0] io_msInfo_10_bits_channel,
  input  [8:0] io_msInfo_10_bits_set,
  input  [2:0] io_msInfo_10_bits_way,
  input  [30:0] io_msInfo_10_bits_reqTag,
  input  io_msInfo_10_bits_willFree,
  input  io_msInfo_10_bits_aliasTask,
  input  io_msInfo_10_bits_needRelease,
  input  io_msInfo_10_bits_blockRefill,
  input  io_msInfo_10_bits_meta_dirty,
  input  [1:0] io_msInfo_10_bits_meta_state,
  input  io_msInfo_10_bits_meta_clients,
  input  [1:0] io_msInfo_10_bits_meta_alias,
  input  io_msInfo_10_bits_meta_prefetch,
  input  [2:0] io_msInfo_10_bits_meta_prefetchSrc,
  input  io_msInfo_10_bits_meta_accessed,
  input  io_msInfo_10_bits_meta_tagErr,
  input  io_msInfo_10_bits_meta_dataErr,
  input  [30:0] io_msInfo_10_bits_metaTag,
  input  io_msInfo_10_bits_dirHit,
  input  io_msInfo_10_bits_isAcqOrPrefetch,
  input  io_msInfo_10_bits_isPrefetch,
  input  [2:0] io_msInfo_10_bits_param,
  input  io_msInfo_10_bits_mergeA,
  input  io_msInfo_10_bits_w_grantfirst,
  input  io_msInfo_10_bits_s_release,
  input  io_msInfo_10_bits_s_refill,
  input  io_msInfo_10_bits_s_cmoresp,
  input  io_msInfo_10_bits_s_cmometaw,
  input  io_msInfo_10_bits_w_releaseack,
  input  io_msInfo_10_bits_w_replResp,
  input  io_msInfo_10_bits_w_rprobeacklast,
  input  io_msInfo_10_bits_replaceData,
  input  io_msInfo_10_bits_releaseToClean,
  input  io_msInfo_11_valid,
  input  [2:0] io_msInfo_11_bits_channel,
  input  [8:0] io_msInfo_11_bits_set,
  input  [2:0] io_msInfo_11_bits_way,
  input  [30:0] io_msInfo_11_bits_reqTag,
  input  io_msInfo_11_bits_willFree,
  input  io_msInfo_11_bits_aliasTask,
  input  io_msInfo_11_bits_needRelease,
  input  io_msInfo_11_bits_blockRefill,
  input  io_msInfo_11_bits_meta_dirty,
  input  [1:0] io_msInfo_11_bits_meta_state,
  input  io_msInfo_11_bits_meta_clients,
  input  [1:0] io_msInfo_11_bits_meta_alias,
  input  io_msInfo_11_bits_meta_prefetch,
  input  [2:0] io_msInfo_11_bits_meta_prefetchSrc,
  input  io_msInfo_11_bits_meta_accessed,
  input  io_msInfo_11_bits_meta_tagErr,
  input  io_msInfo_11_bits_meta_dataErr,
  input  [30:0] io_msInfo_11_bits_metaTag,
  input  io_msInfo_11_bits_dirHit,
  input  io_msInfo_11_bits_isAcqOrPrefetch,
  input  io_msInfo_11_bits_isPrefetch,
  input  [2:0] io_msInfo_11_bits_param,
  input  io_msInfo_11_bits_mergeA,
  input  io_msInfo_11_bits_w_grantfirst,
  input  io_msInfo_11_bits_s_release,
  input  io_msInfo_11_bits_s_refill,
  input  io_msInfo_11_bits_s_cmoresp,
  input  io_msInfo_11_bits_s_cmometaw,
  input  io_msInfo_11_bits_w_releaseack,
  input  io_msInfo_11_bits_w_replResp,
  input  io_msInfo_11_bits_w_rprobeacklast,
  input  io_msInfo_11_bits_replaceData,
  input  io_msInfo_11_bits_releaseToClean,
  input  io_msInfo_12_valid,
  input  [2:0] io_msInfo_12_bits_channel,
  input  [8:0] io_msInfo_12_bits_set,
  input  [2:0] io_msInfo_12_bits_way,
  input  [30:0] io_msInfo_12_bits_reqTag,
  input  io_msInfo_12_bits_willFree,
  input  io_msInfo_12_bits_aliasTask,
  input  io_msInfo_12_bits_needRelease,
  input  io_msInfo_12_bits_blockRefill,
  input  io_msInfo_12_bits_meta_dirty,
  input  [1:0] io_msInfo_12_bits_meta_state,
  input  io_msInfo_12_bits_meta_clients,
  input  [1:0] io_msInfo_12_bits_meta_alias,
  input  io_msInfo_12_bits_meta_prefetch,
  input  [2:0] io_msInfo_12_bits_meta_prefetchSrc,
  input  io_msInfo_12_bits_meta_accessed,
  input  io_msInfo_12_bits_meta_tagErr,
  input  io_msInfo_12_bits_meta_dataErr,
  input  [30:0] io_msInfo_12_bits_metaTag,
  input  io_msInfo_12_bits_dirHit,
  input  io_msInfo_12_bits_isAcqOrPrefetch,
  input  io_msInfo_12_bits_isPrefetch,
  input  [2:0] io_msInfo_12_bits_param,
  input  io_msInfo_12_bits_mergeA,
  input  io_msInfo_12_bits_w_grantfirst,
  input  io_msInfo_12_bits_s_release,
  input  io_msInfo_12_bits_s_refill,
  input  io_msInfo_12_bits_s_cmoresp,
  input  io_msInfo_12_bits_s_cmometaw,
  input  io_msInfo_12_bits_w_releaseack,
  input  io_msInfo_12_bits_w_replResp,
  input  io_msInfo_12_bits_w_rprobeacklast,
  input  io_msInfo_12_bits_replaceData,
  input  io_msInfo_12_bits_releaseToClean,
  input  io_msInfo_13_valid,
  input  [2:0] io_msInfo_13_bits_channel,
  input  [8:0] io_msInfo_13_bits_set,
  input  [2:0] io_msInfo_13_bits_way,
  input  [30:0] io_msInfo_13_bits_reqTag,
  input  io_msInfo_13_bits_willFree,
  input  io_msInfo_13_bits_aliasTask,
  input  io_msInfo_13_bits_needRelease,
  input  io_msInfo_13_bits_blockRefill,
  input  io_msInfo_13_bits_meta_dirty,
  input  [1:0] io_msInfo_13_bits_meta_state,
  input  io_msInfo_13_bits_meta_clients,
  input  [1:0] io_msInfo_13_bits_meta_alias,
  input  io_msInfo_13_bits_meta_prefetch,
  input  [2:0] io_msInfo_13_bits_meta_prefetchSrc,
  input  io_msInfo_13_bits_meta_accessed,
  input  io_msInfo_13_bits_meta_tagErr,
  input  io_msInfo_13_bits_meta_dataErr,
  input  [30:0] io_msInfo_13_bits_metaTag,
  input  io_msInfo_13_bits_dirHit,
  input  io_msInfo_13_bits_isAcqOrPrefetch,
  input  io_msInfo_13_bits_isPrefetch,
  input  [2:0] io_msInfo_13_bits_param,
  input  io_msInfo_13_bits_mergeA,
  input  io_msInfo_13_bits_w_grantfirst,
  input  io_msInfo_13_bits_s_release,
  input  io_msInfo_13_bits_s_refill,
  input  io_msInfo_13_bits_s_cmoresp,
  input  io_msInfo_13_bits_s_cmometaw,
  input  io_msInfo_13_bits_w_releaseack,
  input  io_msInfo_13_bits_w_replResp,
  input  io_msInfo_13_bits_w_rprobeacklast,
  input  io_msInfo_13_bits_replaceData,
  input  io_msInfo_13_bits_releaseToClean,
  input  io_msInfo_14_valid,
  input  [2:0] io_msInfo_14_bits_channel,
  input  [8:0] io_msInfo_14_bits_set,
  input  [2:0] io_msInfo_14_bits_way,
  input  [30:0] io_msInfo_14_bits_reqTag,
  input  io_msInfo_14_bits_willFree,
  input  io_msInfo_14_bits_aliasTask,
  input  io_msInfo_14_bits_needRelease,
  input  io_msInfo_14_bits_blockRefill,
  input  io_msInfo_14_bits_meta_dirty,
  input  [1:0] io_msInfo_14_bits_meta_state,
  input  io_msInfo_14_bits_meta_clients,
  input  [1:0] io_msInfo_14_bits_meta_alias,
  input  io_msInfo_14_bits_meta_prefetch,
  input  [2:0] io_msInfo_14_bits_meta_prefetchSrc,
  input  io_msInfo_14_bits_meta_accessed,
  input  io_msInfo_14_bits_meta_tagErr,
  input  io_msInfo_14_bits_meta_dataErr,
  input  [30:0] io_msInfo_14_bits_metaTag,
  input  io_msInfo_14_bits_dirHit,
  input  io_msInfo_14_bits_isAcqOrPrefetch,
  input  io_msInfo_14_bits_isPrefetch,
  input  [2:0] io_msInfo_14_bits_param,
  input  io_msInfo_14_bits_mergeA,
  input  io_msInfo_14_bits_w_grantfirst,
  input  io_msInfo_14_bits_s_release,
  input  io_msInfo_14_bits_s_refill,
  input  io_msInfo_14_bits_s_cmoresp,
  input  io_msInfo_14_bits_s_cmometaw,
  input  io_msInfo_14_bits_w_releaseack,
  input  io_msInfo_14_bits_w_replResp,
  input  io_msInfo_14_bits_w_rprobeacklast,
  input  io_msInfo_14_bits_replaceData,
  input  io_msInfo_14_bits_releaseToClean,
  input  io_msInfo_15_valid,
  input  [2:0] io_msInfo_15_bits_channel,
  input  [8:0] io_msInfo_15_bits_set,
  input  [2:0] io_msInfo_15_bits_way,
  input  [30:0] io_msInfo_15_bits_reqTag,
  input  io_msInfo_15_bits_willFree,
  input  io_msInfo_15_bits_aliasTask,
  input  io_msInfo_15_bits_needRelease,
  input  io_msInfo_15_bits_blockRefill,
  input  io_msInfo_15_bits_meta_dirty,
  input  [1:0] io_msInfo_15_bits_meta_state,
  input  io_msInfo_15_bits_meta_clients,
  input  [1:0] io_msInfo_15_bits_meta_alias,
  input  io_msInfo_15_bits_meta_prefetch,
  input  [2:0] io_msInfo_15_bits_meta_prefetchSrc,
  input  io_msInfo_15_bits_meta_accessed,
  input  io_msInfo_15_bits_meta_tagErr,
  input  io_msInfo_15_bits_meta_dataErr,
  input  [30:0] io_msInfo_15_bits_metaTag,
  input  io_msInfo_15_bits_dirHit,
  input  io_msInfo_15_bits_isAcqOrPrefetch,
  input  io_msInfo_15_bits_isPrefetch,
  input  [2:0] io_msInfo_15_bits_param,
  input  io_msInfo_15_bits_mergeA,
  input  io_msInfo_15_bits_w_grantfirst,
  input  io_msInfo_15_bits_s_release,
  input  io_msInfo_15_bits_s_refill,
  input  io_msInfo_15_bits_s_cmoresp,
  input  io_msInfo_15_bits_s_cmometaw,
  input  io_msInfo_15_bits_w_releaseack,
  input  io_msInfo_15_bits_w_replResp,
  input  io_msInfo_15_bits_w_rprobeacklast,
  input  io_msInfo_15_bits_replaceData,
  input  io_msInfo_15_bits_releaseToClean
);
  assign io_sinkA_ready = '0;
  assign io_s1Entrance_valid = '0;
  assign io_s1Entrance_bits_set = '0;
  assign io_sinkB_ready = '0;
  assign io_sinkC_ready = '0;
  assign io_mshrTask_ready = '0;
  assign io_dirRead_s1_valid = '0;
  assign io_dirRead_s1_bits_tag = '0;
  assign io_dirRead_s1_bits_set = '0;
  assign io_dirRead_s1_bits_wayMask = '0;
  assign io_dirRead_s1_bits_replacerInfo_channel = '0;
  assign io_dirRead_s1_bits_replacerInfo_opcode = '0;
  assign io_dirRead_s1_bits_replacerInfo_reqSource = '0;
  assign io_dirRead_s1_bits_replacerInfo_refill_prefetch = '0;
  assign io_dirRead_s1_bits_refill = '0;
  assign io_dirRead_s1_bits_mshrId = '0;
  assign io_dirRead_s1_bits_cmoAll = '0;
  assign io_dirRead_s1_bits_cmoWay = '0;
  assign io_taskToPipe_s2_valid = '0;
  assign io_taskToPipe_s2_bits_channel = '0;
  assign io_taskToPipe_s2_bits_txChannel = '0;
  assign io_taskToPipe_s2_bits_set = '0;
  assign io_taskToPipe_s2_bits_tag = '0;
  assign io_taskToPipe_s2_bits_off = '0;
  assign io_taskToPipe_s2_bits_alias = '0;
  assign io_taskToPipe_s2_bits_vaddr = '0;
  assign io_taskToPipe_s2_bits_isKeyword = '0;
  assign io_taskToPipe_s2_bits_opcode = '0;
  assign io_taskToPipe_s2_bits_param = '0;
  assign io_taskToPipe_s2_bits_size = '0;
  assign io_taskToPipe_s2_bits_sourceId = '0;
  assign io_taskToPipe_s2_bits_bufIdx = '0;
  assign io_taskToPipe_s2_bits_needProbeAckData = '0;
  assign io_taskToPipe_s2_bits_denied = '0;
  assign io_taskToPipe_s2_bits_corrupt = '0;
  assign io_taskToPipe_s2_bits_mshrTask = '0;
  assign io_taskToPipe_s2_bits_mshrId = '0;
  assign io_taskToPipe_s2_bits_aliasTask = '0;
  assign io_taskToPipe_s2_bits_useProbeData = '0;
  assign io_taskToPipe_s2_bits_mshrRetry = '0;
  assign io_taskToPipe_s2_bits_readProbeDataDown = '0;
  assign io_taskToPipe_s2_bits_fromL2pft = '0;
  assign io_taskToPipe_s2_bits_needHint = '0;
  assign io_taskToPipe_s2_bits_dirty = '0;
  assign io_taskToPipe_s2_bits_way = '0;
  assign io_taskToPipe_s2_bits_meta_dirty = '0;
  assign io_taskToPipe_s2_bits_meta_state = '0;
  assign io_taskToPipe_s2_bits_meta_clients = '0;
  assign io_taskToPipe_s2_bits_meta_alias = '0;
  assign io_taskToPipe_s2_bits_meta_prefetch = '0;
  assign io_taskToPipe_s2_bits_meta_prefetchSrc = '0;
  assign io_taskToPipe_s2_bits_meta_accessed = '0;
  assign io_taskToPipe_s2_bits_meta_tagErr = '0;
  assign io_taskToPipe_s2_bits_meta_dataErr = '0;
  assign io_taskToPipe_s2_bits_metaWen = '0;
  assign io_taskToPipe_s2_bits_tagWen = '0;
  assign io_taskToPipe_s2_bits_dsWen = '0;
  assign io_taskToPipe_s2_bits_wayMask = '0;
  assign io_taskToPipe_s2_bits_replTask = '0;
  assign io_taskToPipe_s2_bits_cmoTask = '0;
  assign io_taskToPipe_s2_bits_cmoAll = '0;
  assign io_taskToPipe_s2_bits_reqSource = '0;
  assign io_taskToPipe_s2_bits_mergeA = '0;
  assign io_taskToPipe_s2_bits_aMergeTask_off = '0;
  assign io_taskToPipe_s2_bits_aMergeTask_alias = '0;
  assign io_taskToPipe_s2_bits_aMergeTask_vaddr = '0;
  assign io_taskToPipe_s2_bits_aMergeTask_isKeyword = '0;
  assign io_taskToPipe_s2_bits_aMergeTask_opcode = '0;
  assign io_taskToPipe_s2_bits_aMergeTask_param = '0;
  assign io_taskToPipe_s2_bits_aMergeTask_sourceId = '0;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_dirty = '0;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_state = '0;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_clients = '0;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_alias = '0;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_prefetch = '0;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc = '0;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_accessed = '0;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_tagErr = '0;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_dataErr = '0;
  assign io_taskToPipe_s2_bits_snpHitRelease = '0;
  assign io_taskToPipe_s2_bits_snpHitReleaseToInval = '0;
  assign io_taskToPipe_s2_bits_snpHitReleaseToClean = '0;
  assign io_taskToPipe_s2_bits_snpHitReleaseWithData = '0;
  assign io_taskToPipe_s2_bits_snpHitReleaseIdx = '0;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty = '0;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_state = '0;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_clients = '0;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_alias = '0;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch = '0;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc = '0;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed = '0;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr = '0;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr = '0;
  assign io_taskToPipe_s2_bits_tgtID = '0;
  assign io_taskToPipe_s2_bits_srcID = '0;
  assign io_taskToPipe_s2_bits_txnID = '0;
  assign io_taskToPipe_s2_bits_homeNID = '0;
  assign io_taskToPipe_s2_bits_dbID = '0;
  assign io_taskToPipe_s2_bits_fwdNID = '0;
  assign io_taskToPipe_s2_bits_fwdTxnID = '0;
  assign io_taskToPipe_s2_bits_chiOpcode = '0;
  assign io_taskToPipe_s2_bits_resp = '0;
  assign io_taskToPipe_s2_bits_fwdState = '0;
  assign io_taskToPipe_s2_bits_pCrdType = '0;
  assign io_taskToPipe_s2_bits_retToSrc = '0;
  assign io_taskToPipe_s2_bits_likelyshared = '0;
  assign io_taskToPipe_s2_bits_expCompAck = '0;
  assign io_taskToPipe_s2_bits_allowRetry = '0;
  assign io_taskToPipe_s2_bits_memAttr_allocate = '0;
  assign io_taskToPipe_s2_bits_memAttr_cacheable = '0;
  assign io_taskToPipe_s2_bits_memAttr_device = '0;
  assign io_taskToPipe_s2_bits_memAttr_ewa = '0;
  assign io_taskToPipe_s2_bits_traceTag = '0;
  assign io_taskToPipe_s2_bits_dataCheckErr = '0;
  assign io_taskInfo_s1_valid = '0;
  assign io_taskInfo_s1_bits_channel = '0;
  assign io_taskInfo_s1_bits_txChannel = '0;
  assign io_taskInfo_s1_bits_set = '0;
  assign io_taskInfo_s1_bits_tag = '0;
  assign io_taskInfo_s1_bits_off = '0;
  assign io_taskInfo_s1_bits_alias = '0;
  assign io_taskInfo_s1_bits_vaddr = '0;
  assign io_taskInfo_s1_bits_isKeyword = '0;
  assign io_taskInfo_s1_bits_opcode = '0;
  assign io_taskInfo_s1_bits_param = '0;
  assign io_taskInfo_s1_bits_size = '0;
  assign io_taskInfo_s1_bits_sourceId = '0;
  assign io_taskInfo_s1_bits_bufIdx = '0;
  assign io_taskInfo_s1_bits_needProbeAckData = '0;
  assign io_taskInfo_s1_bits_denied = '0;
  assign io_taskInfo_s1_bits_corrupt = '0;
  assign io_taskInfo_s1_bits_mshrTask = '0;
  assign io_taskInfo_s1_bits_mshrId = '0;
  assign io_taskInfo_s1_bits_aliasTask = '0;
  assign io_taskInfo_s1_bits_useProbeData = '0;
  assign io_taskInfo_s1_bits_mshrRetry = '0;
  assign io_taskInfo_s1_bits_readProbeDataDown = '0;
  assign io_taskInfo_s1_bits_fromL2pft = '0;
  assign io_taskInfo_s1_bits_needHint = '0;
  assign io_taskInfo_s1_bits_dirty = '0;
  assign io_taskInfo_s1_bits_way = '0;
  assign io_taskInfo_s1_bits_meta_dirty = '0;
  assign io_taskInfo_s1_bits_meta_state = '0;
  assign io_taskInfo_s1_bits_meta_clients = '0;
  assign io_taskInfo_s1_bits_meta_alias = '0;
  assign io_taskInfo_s1_bits_meta_prefetch = '0;
  assign io_taskInfo_s1_bits_meta_prefetchSrc = '0;
  assign io_taskInfo_s1_bits_meta_accessed = '0;
  assign io_taskInfo_s1_bits_meta_tagErr = '0;
  assign io_taskInfo_s1_bits_meta_dataErr = '0;
  assign io_taskInfo_s1_bits_metaWen = '0;
  assign io_taskInfo_s1_bits_tagWen = '0;
  assign io_taskInfo_s1_bits_dsWen = '0;
  assign io_taskInfo_s1_bits_wayMask = '0;
  assign io_taskInfo_s1_bits_replTask = '0;
  assign io_taskInfo_s1_bits_cmoTask = '0;
  assign io_taskInfo_s1_bits_cmoAll = '0;
  assign io_taskInfo_s1_bits_reqSource = '0;
  assign io_taskInfo_s1_bits_mergeA = '0;
  assign io_taskInfo_s1_bits_aMergeTask_off = '0;
  assign io_taskInfo_s1_bits_aMergeTask_alias = '0;
  assign io_taskInfo_s1_bits_aMergeTask_vaddr = '0;
  assign io_taskInfo_s1_bits_aMergeTask_isKeyword = '0;
  assign io_taskInfo_s1_bits_aMergeTask_opcode = '0;
  assign io_taskInfo_s1_bits_aMergeTask_param = '0;
  assign io_taskInfo_s1_bits_aMergeTask_sourceId = '0;
  assign io_taskInfo_s1_bits_aMergeTask_meta_dirty = '0;
  assign io_taskInfo_s1_bits_aMergeTask_meta_state = '0;
  assign io_taskInfo_s1_bits_aMergeTask_meta_clients = '0;
  assign io_taskInfo_s1_bits_aMergeTask_meta_alias = '0;
  assign io_taskInfo_s1_bits_aMergeTask_meta_prefetch = '0;
  assign io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc = '0;
  assign io_taskInfo_s1_bits_aMergeTask_meta_accessed = '0;
  assign io_taskInfo_s1_bits_aMergeTask_meta_tagErr = '0;
  assign io_taskInfo_s1_bits_aMergeTask_meta_dataErr = '0;
  assign io_taskInfo_s1_bits_snpHitRelease = '0;
  assign io_taskInfo_s1_bits_snpHitReleaseToInval = '0;
  assign io_taskInfo_s1_bits_snpHitReleaseToClean = '0;
  assign io_taskInfo_s1_bits_snpHitReleaseWithData = '0;
  assign io_taskInfo_s1_bits_snpHitReleaseIdx = '0;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_dirty = '0;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_state = '0;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_clients = '0;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_alias = '0;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch = '0;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc = '0;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_accessed = '0;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr = '0;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr = '0;
  assign io_taskInfo_s1_bits_tgtID = '0;
  assign io_taskInfo_s1_bits_srcID = '0;
  assign io_taskInfo_s1_bits_txnID = '0;
  assign io_taskInfo_s1_bits_homeNID = '0;
  assign io_taskInfo_s1_bits_dbID = '0;
  assign io_taskInfo_s1_bits_fwdNID = '0;
  assign io_taskInfo_s1_bits_fwdTxnID = '0;
  assign io_taskInfo_s1_bits_chiOpcode = '0;
  assign io_taskInfo_s1_bits_resp = '0;
  assign io_taskInfo_s1_bits_fwdState = '0;
  assign io_taskInfo_s1_bits_pCrdType = '0;
  assign io_taskInfo_s1_bits_retToSrc = '0;
  assign io_taskInfo_s1_bits_likelyshared = '0;
  assign io_taskInfo_s1_bits_expCompAck = '0;
  assign io_taskInfo_s1_bits_allowRetry = '0;
  assign io_taskInfo_s1_bits_memAttr_allocate = '0;
  assign io_taskInfo_s1_bits_memAttr_cacheable = '0;
  assign io_taskInfo_s1_bits_memAttr_device = '0;
  assign io_taskInfo_s1_bits_memAttr_ewa = '0;
  assign io_taskInfo_s1_bits_traceTag = '0;
  assign io_taskInfo_s1_bits_dataCheckErr = '0;
  assign io_refillBufRead_s2_valid = '0;
  assign io_refillBufRead_s2_bits_id = '0;
  assign io_releaseBufRead_s2_valid = '0;
  assign io_releaseBufRead_s2_bits_id = '0;
  assign io_status_s1_tags_0 = '0;
  assign io_status_s1_tags_1 = '0;
  assign io_status_s1_tags_2 = '0;
  assign io_status_s1_tags_3 = '0;
  assign io_status_s1_sets_0 = '0;
  assign io_status_s1_sets_1 = '0;
  assign io_status_s1_sets_2 = '0;
  assign io_status_s1_sets_3 = '0;
  assign io_status_vec_0_valid = '0;
  assign io_status_vec_0_bits_channel = '0;
  assign io_status_vec_1_valid = '0;
  assign io_status_vec_1_bits_channel = '0;
  assign io_status_vec_toTX_0_valid = '0;
  assign io_status_vec_toTX_0_bits_channel = '0;
  assign io_status_vec_toTX_0_bits_txChannel = '0;
  assign io_status_vec_toTX_0_bits_mshrTask = '0;
  assign io_status_vec_toTX_1_valid = '0;
  assign io_status_vec_toTX_1_bits_channel = '0;
  assign io_status_vec_toTX_1_bits_txChannel = '0;
  assign io_status_vec_toTX_1_bits_mshrTask = '0;
endmodule

module RequestBuffer(
  input  clock,
  input  reset,
  output  io_in_ready,
  input  io_in_valid,
  input  [8:0] io_in_bits_set,
  input  [30:0] io_in_bits_tag,
  input  [5:0] io_in_bits_off,
  input  [1:0] io_in_bits_alias,
  input  [43:0] io_in_bits_vaddr,
  input  io_in_bits_isKeyword,
  input  [3:0] io_in_bits_opcode,
  input  [2:0] io_in_bits_param,
  input  [2:0] io_in_bits_size,
  input  [6:0] io_in_bits_sourceId,
  input  io_in_bits_corrupt,
  input  io_in_bits_fromL2pft,
  input  io_in_bits_needHint,
  input  [4:0] io_in_bits_reqSource,
  input  io_out_ready,
  output  io_out_valid,
  output  [2:0] io_out_bits_channel,
  output  [2:0] io_out_bits_txChannel,
  output  [8:0] io_out_bits_set,
  output  [30:0] io_out_bits_tag,
  output  [5:0] io_out_bits_off,
  output  [1:0] io_out_bits_alias,
  output  [43:0] io_out_bits_vaddr,
  output  io_out_bits_isKeyword,
  output  [3:0] io_out_bits_opcode,
  output  [2:0] io_out_bits_param,
  output  [2:0] io_out_bits_size,
  output  [6:0] io_out_bits_sourceId,
  output  [1:0] io_out_bits_bufIdx,
  output  io_out_bits_needProbeAckData,
  output  io_out_bits_denied,
  output  io_out_bits_corrupt,
  output  io_out_bits_mshrTask,
  output  [7:0] io_out_bits_mshrId,
  output  io_out_bits_aliasTask,
  output  io_out_bits_useProbeData,
  output  io_out_bits_mshrRetry,
  output  io_out_bits_readProbeDataDown,
  output  io_out_bits_fromL2pft,
  output  io_out_bits_needHint,
  output  io_out_bits_dirty,
  output  [2:0] io_out_bits_way,
  output  io_out_bits_meta_dirty,
  output  [1:0] io_out_bits_meta_state,
  output  io_out_bits_meta_clients,
  output  [1:0] io_out_bits_meta_alias,
  output  io_out_bits_meta_prefetch,
  output  [2:0] io_out_bits_meta_prefetchSrc,
  output  io_out_bits_meta_accessed,
  output  io_out_bits_meta_tagErr,
  output  io_out_bits_meta_dataErr,
  output  io_out_bits_metaWen,
  output  io_out_bits_tagWen,
  output  io_out_bits_dsWen,
  output  io_out_bits_replTask,
  output  io_out_bits_cmoTask,
  output  io_out_bits_cmoAll,
  output  [4:0] io_out_bits_reqSource,
  output  io_out_bits_mergeA,
  output  [5:0] io_out_bits_aMergeTask_off,
  output  [1:0] io_out_bits_aMergeTask_alias,
  output  [43:0] io_out_bits_aMergeTask_vaddr,
  output  io_out_bits_aMergeTask_isKeyword,
  output  [2:0] io_out_bits_aMergeTask_opcode,
  output  [2:0] io_out_bits_aMergeTask_param,
  output  [6:0] io_out_bits_aMergeTask_sourceId,
  output  io_out_bits_aMergeTask_meta_dirty,
  output  [1:0] io_out_bits_aMergeTask_meta_state,
  output  io_out_bits_aMergeTask_meta_clients,
  output  [1:0] io_out_bits_aMergeTask_meta_alias,
  output  io_out_bits_aMergeTask_meta_prefetch,
  output  [2:0] io_out_bits_aMergeTask_meta_prefetchSrc,
  output  io_out_bits_aMergeTask_meta_accessed,
  output  io_out_bits_aMergeTask_meta_tagErr,
  output  io_out_bits_aMergeTask_meta_dataErr,
  output  io_out_bits_snpHitRelease,
  output  io_out_bits_snpHitReleaseToInval,
  output  io_out_bits_snpHitReleaseToClean,
  output  io_out_bits_snpHitReleaseWithData,
  output  [7:0] io_out_bits_snpHitReleaseIdx,
  output  io_out_bits_snpHitReleaseMeta_dirty,
  output  [1:0] io_out_bits_snpHitReleaseMeta_state,
  output  io_out_bits_snpHitReleaseMeta_clients,
  output  [1:0] io_out_bits_snpHitReleaseMeta_alias,
  output  io_out_bits_snpHitReleaseMeta_prefetch,
  output  [2:0] io_out_bits_snpHitReleaseMeta_prefetchSrc,
  output  io_out_bits_snpHitReleaseMeta_accessed,
  output  io_out_bits_snpHitReleaseMeta_tagErr,
  output  io_out_bits_snpHitReleaseMeta_dataErr,
  output  [10:0] io_out_bits_tgtID,
  output  [10:0] io_out_bits_srcID,
  output  [11:0] io_out_bits_txnID,
  output  [10:0] io_out_bits_homeNID,
  output  [11:0] io_out_bits_dbID,
  output  [10:0] io_out_bits_fwdNID,
  output  [11:0] io_out_bits_fwdTxnID,
  output  [6:0] io_out_bits_chiOpcode,
  output  [2:0] io_out_bits_resp,
  output  [2:0] io_out_bits_fwdState,
  output  [3:0] io_out_bits_pCrdType,
  output  io_out_bits_retToSrc,
  output  io_out_bits_likelyshared,
  output  io_out_bits_expCompAck,
  output  io_out_bits_allowRetry,
  output  io_out_bits_memAttr_allocate,
  output  io_out_bits_memAttr_cacheable,
  output  io_out_bits_memAttr_device,
  output  io_out_bits_memAttr_ewa,
  output  io_out_bits_traceTag,
  output  io_out_bits_dataCheckErr,
  input  io_mshrInfo_0_valid,
  input  [2:0] io_mshrInfo_0_bits_channel,
  input  [8:0] io_mshrInfo_0_bits_set,
  input  [30:0] io_mshrInfo_0_bits_reqTag,
  input  io_mshrInfo_0_bits_willFree,
  input  io_mshrInfo_0_bits_needRelease,
  input  [30:0] io_mshrInfo_0_bits_metaTag,
  input  io_mshrInfo_0_bits_dirHit,
  input  io_mshrInfo_0_bits_isAcqOrPrefetch,
  input  io_mshrInfo_0_bits_isPrefetch,
  input  [2:0] io_mshrInfo_0_bits_param,
  input  io_mshrInfo_0_bits_mergeA,
  input  io_mshrInfo_0_bits_s_refill,
  input  io_mshrInfo_1_valid,
  input  [2:0] io_mshrInfo_1_bits_channel,
  input  [8:0] io_mshrInfo_1_bits_set,
  input  [30:0] io_mshrInfo_1_bits_reqTag,
  input  io_mshrInfo_1_bits_willFree,
  input  io_mshrInfo_1_bits_needRelease,
  input  [30:0] io_mshrInfo_1_bits_metaTag,
  input  io_mshrInfo_1_bits_dirHit,
  input  io_mshrInfo_1_bits_isAcqOrPrefetch,
  input  io_mshrInfo_1_bits_isPrefetch,
  input  [2:0] io_mshrInfo_1_bits_param,
  input  io_mshrInfo_1_bits_mergeA,
  input  io_mshrInfo_1_bits_s_refill,
  input  io_mshrInfo_2_valid,
  input  [2:0] io_mshrInfo_2_bits_channel,
  input  [8:0] io_mshrInfo_2_bits_set,
  input  [30:0] io_mshrInfo_2_bits_reqTag,
  input  io_mshrInfo_2_bits_willFree,
  input  io_mshrInfo_2_bits_needRelease,
  input  [30:0] io_mshrInfo_2_bits_metaTag,
  input  io_mshrInfo_2_bits_dirHit,
  input  io_mshrInfo_2_bits_isAcqOrPrefetch,
  input  io_mshrInfo_2_bits_isPrefetch,
  input  [2:0] io_mshrInfo_2_bits_param,
  input  io_mshrInfo_2_bits_mergeA,
  input  io_mshrInfo_2_bits_s_refill,
  input  io_mshrInfo_3_valid,
  input  [2:0] io_mshrInfo_3_bits_channel,
  input  [8:0] io_mshrInfo_3_bits_set,
  input  [30:0] io_mshrInfo_3_bits_reqTag,
  input  io_mshrInfo_3_bits_willFree,
  input  io_mshrInfo_3_bits_needRelease,
  input  [30:0] io_mshrInfo_3_bits_metaTag,
  input  io_mshrInfo_3_bits_dirHit,
  input  io_mshrInfo_3_bits_isAcqOrPrefetch,
  input  io_mshrInfo_3_bits_isPrefetch,
  input  [2:0] io_mshrInfo_3_bits_param,
  input  io_mshrInfo_3_bits_mergeA,
  input  io_mshrInfo_3_bits_s_refill,
  input  io_mshrInfo_4_valid,
  input  [2:0] io_mshrInfo_4_bits_channel,
  input  [8:0] io_mshrInfo_4_bits_set,
  input  [30:0] io_mshrInfo_4_bits_reqTag,
  input  io_mshrInfo_4_bits_willFree,
  input  io_mshrInfo_4_bits_needRelease,
  input  [30:0] io_mshrInfo_4_bits_metaTag,
  input  io_mshrInfo_4_bits_dirHit,
  input  io_mshrInfo_4_bits_isAcqOrPrefetch,
  input  io_mshrInfo_4_bits_isPrefetch,
  input  [2:0] io_mshrInfo_4_bits_param,
  input  io_mshrInfo_4_bits_mergeA,
  input  io_mshrInfo_4_bits_s_refill,
  input  io_mshrInfo_5_valid,
  input  [2:0] io_mshrInfo_5_bits_channel,
  input  [8:0] io_mshrInfo_5_bits_set,
  input  [30:0] io_mshrInfo_5_bits_reqTag,
  input  io_mshrInfo_5_bits_willFree,
  input  io_mshrInfo_5_bits_needRelease,
  input  [30:0] io_mshrInfo_5_bits_metaTag,
  input  io_mshrInfo_5_bits_dirHit,
  input  io_mshrInfo_5_bits_isAcqOrPrefetch,
  input  io_mshrInfo_5_bits_isPrefetch,
  input  [2:0] io_mshrInfo_5_bits_param,
  input  io_mshrInfo_5_bits_mergeA,
  input  io_mshrInfo_5_bits_s_refill,
  input  io_mshrInfo_6_valid,
  input  [2:0] io_mshrInfo_6_bits_channel,
  input  [8:0] io_mshrInfo_6_bits_set,
  input  [30:0] io_mshrInfo_6_bits_reqTag,
  input  io_mshrInfo_6_bits_willFree,
  input  io_mshrInfo_6_bits_needRelease,
  input  [30:0] io_mshrInfo_6_bits_metaTag,
  input  io_mshrInfo_6_bits_dirHit,
  input  io_mshrInfo_6_bits_isAcqOrPrefetch,
  input  io_mshrInfo_6_bits_isPrefetch,
  input  [2:0] io_mshrInfo_6_bits_param,
  input  io_mshrInfo_6_bits_mergeA,
  input  io_mshrInfo_6_bits_s_refill,
  input  io_mshrInfo_7_valid,
  input  [2:0] io_mshrInfo_7_bits_channel,
  input  [8:0] io_mshrInfo_7_bits_set,
  input  [30:0] io_mshrInfo_7_bits_reqTag,
  input  io_mshrInfo_7_bits_willFree,
  input  io_mshrInfo_7_bits_needRelease,
  input  [30:0] io_mshrInfo_7_bits_metaTag,
  input  io_mshrInfo_7_bits_dirHit,
  input  io_mshrInfo_7_bits_isAcqOrPrefetch,
  input  io_mshrInfo_7_bits_isPrefetch,
  input  [2:0] io_mshrInfo_7_bits_param,
  input  io_mshrInfo_7_bits_mergeA,
  input  io_mshrInfo_7_bits_s_refill,
  input  io_mshrInfo_8_valid,
  input  [2:0] io_mshrInfo_8_bits_channel,
  input  [8:0] io_mshrInfo_8_bits_set,
  input  [30:0] io_mshrInfo_8_bits_reqTag,
  input  io_mshrInfo_8_bits_willFree,
  input  io_mshrInfo_8_bits_needRelease,
  input  [30:0] io_mshrInfo_8_bits_metaTag,
  input  io_mshrInfo_8_bits_dirHit,
  input  io_mshrInfo_8_bits_isAcqOrPrefetch,
  input  io_mshrInfo_8_bits_isPrefetch,
  input  [2:0] io_mshrInfo_8_bits_param,
  input  io_mshrInfo_8_bits_mergeA,
  input  io_mshrInfo_8_bits_s_refill,
  input  io_mshrInfo_9_valid,
  input  [2:0] io_mshrInfo_9_bits_channel,
  input  [8:0] io_mshrInfo_9_bits_set,
  input  [30:0] io_mshrInfo_9_bits_reqTag,
  input  io_mshrInfo_9_bits_willFree,
  input  io_mshrInfo_9_bits_needRelease,
  input  [30:0] io_mshrInfo_9_bits_metaTag,
  input  io_mshrInfo_9_bits_dirHit,
  input  io_mshrInfo_9_bits_isAcqOrPrefetch,
  input  io_mshrInfo_9_bits_isPrefetch,
  input  [2:0] io_mshrInfo_9_bits_param,
  input  io_mshrInfo_9_bits_mergeA,
  input  io_mshrInfo_9_bits_s_refill,
  input  io_mshrInfo_10_valid,
  input  [2:0] io_mshrInfo_10_bits_channel,
  input  [8:0] io_mshrInfo_10_bits_set,
  input  [30:0] io_mshrInfo_10_bits_reqTag,
  input  io_mshrInfo_10_bits_willFree,
  input  io_mshrInfo_10_bits_needRelease,
  input  [30:0] io_mshrInfo_10_bits_metaTag,
  input  io_mshrInfo_10_bits_dirHit,
  input  io_mshrInfo_10_bits_isAcqOrPrefetch,
  input  io_mshrInfo_10_bits_isPrefetch,
  input  [2:0] io_mshrInfo_10_bits_param,
  input  io_mshrInfo_10_bits_mergeA,
  input  io_mshrInfo_10_bits_s_refill,
  input  io_mshrInfo_11_valid,
  input  [2:0] io_mshrInfo_11_bits_channel,
  input  [8:0] io_mshrInfo_11_bits_set,
  input  [30:0] io_mshrInfo_11_bits_reqTag,
  input  io_mshrInfo_11_bits_willFree,
  input  io_mshrInfo_11_bits_needRelease,
  input  [30:0] io_mshrInfo_11_bits_metaTag,
  input  io_mshrInfo_11_bits_dirHit,
  input  io_mshrInfo_11_bits_isAcqOrPrefetch,
  input  io_mshrInfo_11_bits_isPrefetch,
  input  [2:0] io_mshrInfo_11_bits_param,
  input  io_mshrInfo_11_bits_mergeA,
  input  io_mshrInfo_11_bits_s_refill,
  input  io_mshrInfo_12_valid,
  input  [2:0] io_mshrInfo_12_bits_channel,
  input  [8:0] io_mshrInfo_12_bits_set,
  input  [30:0] io_mshrInfo_12_bits_reqTag,
  input  io_mshrInfo_12_bits_willFree,
  input  io_mshrInfo_12_bits_needRelease,
  input  [30:0] io_mshrInfo_12_bits_metaTag,
  input  io_mshrInfo_12_bits_dirHit,
  input  io_mshrInfo_12_bits_isAcqOrPrefetch,
  input  io_mshrInfo_12_bits_isPrefetch,
  input  [2:0] io_mshrInfo_12_bits_param,
  input  io_mshrInfo_12_bits_mergeA,
  input  io_mshrInfo_12_bits_s_refill,
  input  io_mshrInfo_13_valid,
  input  [2:0] io_mshrInfo_13_bits_channel,
  input  [8:0] io_mshrInfo_13_bits_set,
  input  [30:0] io_mshrInfo_13_bits_reqTag,
  input  io_mshrInfo_13_bits_willFree,
  input  io_mshrInfo_13_bits_needRelease,
  input  [30:0] io_mshrInfo_13_bits_metaTag,
  input  io_mshrInfo_13_bits_dirHit,
  input  io_mshrInfo_13_bits_isAcqOrPrefetch,
  input  io_mshrInfo_13_bits_isPrefetch,
  input  [2:0] io_mshrInfo_13_bits_param,
  input  io_mshrInfo_13_bits_mergeA,
  input  io_mshrInfo_13_bits_s_refill,
  input  io_mshrInfo_14_valid,
  input  [2:0] io_mshrInfo_14_bits_channel,
  input  [8:0] io_mshrInfo_14_bits_set,
  input  [30:0] io_mshrInfo_14_bits_reqTag,
  input  io_mshrInfo_14_bits_willFree,
  input  io_mshrInfo_14_bits_needRelease,
  input  [30:0] io_mshrInfo_14_bits_metaTag,
  input  io_mshrInfo_14_bits_dirHit,
  input  io_mshrInfo_14_bits_isAcqOrPrefetch,
  input  io_mshrInfo_14_bits_isPrefetch,
  input  [2:0] io_mshrInfo_14_bits_param,
  input  io_mshrInfo_14_bits_mergeA,
  input  io_mshrInfo_14_bits_s_refill,
  input  io_mshrInfo_15_valid,
  input  [2:0] io_mshrInfo_15_bits_channel,
  input  [8:0] io_mshrInfo_15_bits_set,
  input  [30:0] io_mshrInfo_15_bits_reqTag,
  input  io_mshrInfo_15_bits_willFree,
  input  io_mshrInfo_15_bits_needRelease,
  input  [30:0] io_mshrInfo_15_bits_metaTag,
  input  io_mshrInfo_15_bits_dirHit,
  input  io_mshrInfo_15_bits_isAcqOrPrefetch,
  input  io_mshrInfo_15_bits_isPrefetch,
  input  [2:0] io_mshrInfo_15_bits_param,
  input  io_mshrInfo_15_bits_mergeA,
  input  io_mshrInfo_15_bits_s_refill,
  output  io_aMergeTask_valid,
  output  [7:0] io_aMergeTask_bits_id,
  output  [5:0] io_aMergeTask_bits_task_off,
  output  [1:0] io_aMergeTask_bits_task_alias,
  output  [43:0] io_aMergeTask_bits_task_vaddr,
  output  io_aMergeTask_bits_task_isKeyword,
  output  [3:0] io_aMergeTask_bits_task_opcode,
  output  [2:0] io_aMergeTask_bits_task_param,
  output  [6:0] io_aMergeTask_bits_task_sourceId,
  input  io_mainPipeBlock_0,
  input  io_mainPipeBlock_1,
  input  io_taskFromArb_s2_valid,
  input  [2:0] io_taskFromArb_s2_bits_channel,
  input  [8:0] io_taskFromArb_s2_bits_set,
  input  io_taskFromArb_s2_bits_mshrTask,
  output  [30:0] io_ATag,
  output  [8:0] io_ASet,
  input  io_s1Entrance_valid,
  input  [8:0] io_s1Entrance_bits_set,
  output  io_hasLatePF,
  output  io_hasMergeA
);
  assign io_in_ready = '0;
  assign io_out_valid = '0;
  assign io_out_bits_channel = '0;
  assign io_out_bits_txChannel = '0;
  assign io_out_bits_set = '0;
  assign io_out_bits_tag = '0;
  assign io_out_bits_off = '0;
  assign io_out_bits_alias = '0;
  assign io_out_bits_vaddr = '0;
  assign io_out_bits_isKeyword = '0;
  assign io_out_bits_opcode = '0;
  assign io_out_bits_param = '0;
  assign io_out_bits_size = '0;
  assign io_out_bits_sourceId = '0;
  assign io_out_bits_bufIdx = '0;
  assign io_out_bits_needProbeAckData = '0;
  assign io_out_bits_denied = '0;
  assign io_out_bits_corrupt = '0;
  assign io_out_bits_mshrTask = '0;
  assign io_out_bits_mshrId = '0;
  assign io_out_bits_aliasTask = '0;
  assign io_out_bits_useProbeData = '0;
  assign io_out_bits_mshrRetry = '0;
  assign io_out_bits_readProbeDataDown = '0;
  assign io_out_bits_fromL2pft = '0;
  assign io_out_bits_needHint = '0;
  assign io_out_bits_dirty = '0;
  assign io_out_bits_way = '0;
  assign io_out_bits_meta_dirty = '0;
  assign io_out_bits_meta_state = '0;
  assign io_out_bits_meta_clients = '0;
  assign io_out_bits_meta_alias = '0;
  assign io_out_bits_meta_prefetch = '0;
  assign io_out_bits_meta_prefetchSrc = '0;
  assign io_out_bits_meta_accessed = '0;
  assign io_out_bits_meta_tagErr = '0;
  assign io_out_bits_meta_dataErr = '0;
  assign io_out_bits_metaWen = '0;
  assign io_out_bits_tagWen = '0;
  assign io_out_bits_dsWen = '0;
  assign io_out_bits_replTask = '0;
  assign io_out_bits_cmoTask = '0;
  assign io_out_bits_cmoAll = '0;
  assign io_out_bits_reqSource = '0;
  assign io_out_bits_mergeA = '0;
  assign io_out_bits_aMergeTask_off = '0;
  assign io_out_bits_aMergeTask_alias = '0;
  assign io_out_bits_aMergeTask_vaddr = '0;
  assign io_out_bits_aMergeTask_isKeyword = '0;
  assign io_out_bits_aMergeTask_opcode = '0;
  assign io_out_bits_aMergeTask_param = '0;
  assign io_out_bits_aMergeTask_sourceId = '0;
  assign io_out_bits_aMergeTask_meta_dirty = '0;
  assign io_out_bits_aMergeTask_meta_state = '0;
  assign io_out_bits_aMergeTask_meta_clients = '0;
  assign io_out_bits_aMergeTask_meta_alias = '0;
  assign io_out_bits_aMergeTask_meta_prefetch = '0;
  assign io_out_bits_aMergeTask_meta_prefetchSrc = '0;
  assign io_out_bits_aMergeTask_meta_accessed = '0;
  assign io_out_bits_aMergeTask_meta_tagErr = '0;
  assign io_out_bits_aMergeTask_meta_dataErr = '0;
  assign io_out_bits_snpHitRelease = '0;
  assign io_out_bits_snpHitReleaseToInval = '0;
  assign io_out_bits_snpHitReleaseToClean = '0;
  assign io_out_bits_snpHitReleaseWithData = '0;
  assign io_out_bits_snpHitReleaseIdx = '0;
  assign io_out_bits_snpHitReleaseMeta_dirty = '0;
  assign io_out_bits_snpHitReleaseMeta_state = '0;
  assign io_out_bits_snpHitReleaseMeta_clients = '0;
  assign io_out_bits_snpHitReleaseMeta_alias = '0;
  assign io_out_bits_snpHitReleaseMeta_prefetch = '0;
  assign io_out_bits_snpHitReleaseMeta_prefetchSrc = '0;
  assign io_out_bits_snpHitReleaseMeta_accessed = '0;
  assign io_out_bits_snpHitReleaseMeta_tagErr = '0;
  assign io_out_bits_snpHitReleaseMeta_dataErr = '0;
  assign io_out_bits_tgtID = '0;
  assign io_out_bits_srcID = '0;
  assign io_out_bits_txnID = '0;
  assign io_out_bits_homeNID = '0;
  assign io_out_bits_dbID = '0;
  assign io_out_bits_fwdNID = '0;
  assign io_out_bits_fwdTxnID = '0;
  assign io_out_bits_chiOpcode = '0;
  assign io_out_bits_resp = '0;
  assign io_out_bits_fwdState = '0;
  assign io_out_bits_pCrdType = '0;
  assign io_out_bits_retToSrc = '0;
  assign io_out_bits_likelyshared = '0;
  assign io_out_bits_expCompAck = '0;
  assign io_out_bits_allowRetry = '0;
  assign io_out_bits_memAttr_allocate = '0;
  assign io_out_bits_memAttr_cacheable = '0;
  assign io_out_bits_memAttr_device = '0;
  assign io_out_bits_memAttr_ewa = '0;
  assign io_out_bits_traceTag = '0;
  assign io_out_bits_dataCheckErr = '0;
  assign io_aMergeTask_valid = '0;
  assign io_aMergeTask_bits_id = '0;
  assign io_aMergeTask_bits_task_off = '0;
  assign io_aMergeTask_bits_task_alias = '0;
  assign io_aMergeTask_bits_task_vaddr = '0;
  assign io_aMergeTask_bits_task_isKeyword = '0;
  assign io_aMergeTask_bits_task_opcode = '0;
  assign io_aMergeTask_bits_task_param = '0;
  assign io_aMergeTask_bits_task_sourceId = '0;
  assign io_ATag = '0;
  assign io_ASet = '0;
  assign io_hasLatePF = '0;
  assign io_hasMergeA = '0;
endmodule

module SinkA(
  input  clock,
  input  reset,
  output  io_a_ready,
  input  io_a_valid,
  input  [3:0] io_a_bits_opcode,
  input  [2:0] io_a_bits_param,
  input  [2:0] io_a_bits_size,
  input  [6:0] io_a_bits_source,
  input  [47:0] io_a_bits_address,
  input  [4:0] io_a_bits_user_reqSource,
  input  [1:0] io_a_bits_user_alias,
  input  [43:0] io_a_bits_user_vaddr,
  input  io_a_bits_user_needHint,
  input  io_a_bits_echo_isKeyword,
  input  io_a_bits_corrupt,
  output  io_prefetchReq_ready,
  input  io_prefetchReq_valid,
  input  [32:0] io_prefetchReq_bits_tag,
  input  [8:0] io_prefetchReq_bits_set,
  input  [43:0] io_prefetchReq_bits_vaddr,
  input  io_prefetchReq_bits_needT,
  input  [6:0] io_prefetchReq_bits_source,
  input  [4:0] io_prefetchReq_bits_pfSource,
  input  io_task_ready,
  output  io_task_valid,
  output  [8:0] io_task_bits_set,
  output  [30:0] io_task_bits_tag,
  output  [5:0] io_task_bits_off,
  output  [1:0] io_task_bits_alias,
  output  [43:0] io_task_bits_vaddr,
  output  io_task_bits_isKeyword,
  output  [3:0] io_task_bits_opcode,
  output  [2:0] io_task_bits_param,
  output  [2:0] io_task_bits_size,
  output  [6:0] io_task_bits_sourceId,
  output  io_task_bits_corrupt,
  output  io_task_bits_fromL2pft,
  output  io_task_bits_needHint,
  output  [4:0] io_task_bits_reqSource
);
  assign io_a_ready = '0;
  assign io_prefetchReq_ready = '0;
  assign io_task_valid = '0;
  assign io_task_bits_set = '0;
  assign io_task_bits_tag = '0;
  assign io_task_bits_off = '0;
  assign io_task_bits_alias = '0;
  assign io_task_bits_vaddr = '0;
  assign io_task_bits_isKeyword = '0;
  assign io_task_bits_opcode = '0;
  assign io_task_bits_param = '0;
  assign io_task_bits_size = '0;
  assign io_task_bits_sourceId = '0;
  assign io_task_bits_corrupt = '0;
  assign io_task_bits_fromL2pft = '0;
  assign io_task_bits_needHint = '0;
  assign io_task_bits_reqSource = '0;
endmodule

module SinkC(
  input  clock,
  input  reset,
  output  io_c_ready,
  input  io_c_valid,
  input  [2:0] io_c_bits_opcode,
  input  [2:0] io_c_bits_param,
  input  [2:0] io_c_bits_size,
  input  [6:0] io_c_bits_source,
  input  [47:0] io_c_bits_address,
  input  [255:0] io_c_bits_data,
  input  io_c_bits_corrupt,
  input  io_task_ready,
  output  io_task_valid,
  output  [2:0] io_task_bits_channel,
  output  [2:0] io_task_bits_txChannel,
  output  [8:0] io_task_bits_set,
  output  [30:0] io_task_bits_tag,
  output  [5:0] io_task_bits_off,
  output  [1:0] io_task_bits_alias,
  output  [43:0] io_task_bits_vaddr,
  output  io_task_bits_isKeyword,
  output  [3:0] io_task_bits_opcode,
  output  [2:0] io_task_bits_param,
  output  [2:0] io_task_bits_size,
  output  [6:0] io_task_bits_sourceId,
  output  [1:0] io_task_bits_bufIdx,
  output  io_task_bits_needProbeAckData,
  output  io_task_bits_denied,
  output  io_task_bits_corrupt,
  output  io_task_bits_mshrTask,
  output  [7:0] io_task_bits_mshrId,
  output  io_task_bits_aliasTask,
  output  io_task_bits_useProbeData,
  output  io_task_bits_mshrRetry,
  output  io_task_bits_readProbeDataDown,
  output  io_task_bits_fromL2pft,
  output  io_task_bits_needHint,
  output  io_task_bits_dirty,
  output  [2:0] io_task_bits_way,
  output  io_task_bits_meta_dirty,
  output  [1:0] io_task_bits_meta_state,
  output  io_task_bits_meta_clients,
  output  [1:0] io_task_bits_meta_alias,
  output  io_task_bits_meta_prefetch,
  output  [2:0] io_task_bits_meta_prefetchSrc,
  output  io_task_bits_meta_accessed,
  output  io_task_bits_meta_tagErr,
  output  io_task_bits_meta_dataErr,
  output  io_task_bits_metaWen,
  output  io_task_bits_tagWen,
  output  io_task_bits_dsWen,
  output  [7:0] io_task_bits_wayMask,
  output  io_task_bits_replTask,
  output  io_task_bits_cmoTask,
  output  io_task_bits_cmoAll,
  output  [4:0] io_task_bits_reqSource,
  output  io_task_bits_mergeA,
  output  [5:0] io_task_bits_aMergeTask_off,
  output  [1:0] io_task_bits_aMergeTask_alias,
  output  [43:0] io_task_bits_aMergeTask_vaddr,
  output  io_task_bits_aMergeTask_isKeyword,
  output  [2:0] io_task_bits_aMergeTask_opcode,
  output  [2:0] io_task_bits_aMergeTask_param,
  output  [6:0] io_task_bits_aMergeTask_sourceId,
  output  io_task_bits_aMergeTask_meta_dirty,
  output  [1:0] io_task_bits_aMergeTask_meta_state,
  output  io_task_bits_aMergeTask_meta_clients,
  output  [1:0] io_task_bits_aMergeTask_meta_alias,
  output  io_task_bits_aMergeTask_meta_prefetch,
  output  [2:0] io_task_bits_aMergeTask_meta_prefetchSrc,
  output  io_task_bits_aMergeTask_meta_accessed,
  output  io_task_bits_aMergeTask_meta_tagErr,
  output  io_task_bits_aMergeTask_meta_dataErr,
  output  io_task_bits_snpHitRelease,
  output  io_task_bits_snpHitReleaseToInval,
  output  io_task_bits_snpHitReleaseToClean,
  output  io_task_bits_snpHitReleaseWithData,
  output  [7:0] io_task_bits_snpHitReleaseIdx,
  output  io_task_bits_snpHitReleaseMeta_dirty,
  output  [1:0] io_task_bits_snpHitReleaseMeta_state,
  output  io_task_bits_snpHitReleaseMeta_clients,
  output  [1:0] io_task_bits_snpHitReleaseMeta_alias,
  output  io_task_bits_snpHitReleaseMeta_prefetch,
  output  [2:0] io_task_bits_snpHitReleaseMeta_prefetchSrc,
  output  io_task_bits_snpHitReleaseMeta_accessed,
  output  io_task_bits_snpHitReleaseMeta_tagErr,
  output  io_task_bits_snpHitReleaseMeta_dataErr,
  output  [10:0] io_task_bits_tgtID,
  output  [10:0] io_task_bits_srcID,
  output  [11:0] io_task_bits_txnID,
  output  [10:0] io_task_bits_homeNID,
  output  [11:0] io_task_bits_dbID,
  output  [10:0] io_task_bits_fwdNID,
  output  [11:0] io_task_bits_fwdTxnID,
  output  [6:0] io_task_bits_chiOpcode,
  output  [2:0] io_task_bits_resp,
  output  [2:0] io_task_bits_fwdState,
  output  [3:0] io_task_bits_pCrdType,
  output  io_task_bits_retToSrc,
  output  io_task_bits_likelyshared,
  output  io_task_bits_expCompAck,
  output  io_task_bits_allowRetry,
  output  io_task_bits_memAttr_allocate,
  output  io_task_bits_memAttr_cacheable,
  output  io_task_bits_memAttr_device,
  output  io_task_bits_memAttr_ewa,
  output  io_task_bits_traceTag,
  output  io_task_bits_dataCheckErr,
  output  io_resp_valid,
  output  [8:0] io_resp_set,
  output  [30:0] io_resp_tag,
  output  [2:0] io_resp_respInfo_opcode,
  output  [2:0] io_resp_respInfo_param,
  output  io_resp_respInfo_last,
  output  io_resp_respInfo_denied,
  output  io_resp_respInfo_corrupt,
  output  io_releaseBufWrite_valid,
  output  [511:0] io_releaseBufWrite_bits_data_data,
  output  [255:0] io_bufResp_data_0,
  output  [255:0] io_bufResp_data_1,
  output  io_refillBufWrite_valid,
  output  [7:0] io_refillBufWrite_bits_id,
  output  [511:0] io_refillBufWrite_bits_data_data,
  input  io_msInfo_0_valid,
  input  [8:0] io_msInfo_0_bits_set,
  input  [30:0] io_msInfo_0_bits_reqTag,
  input  io_msInfo_0_bits_blockRefill,
  input  io_msInfo_1_valid,
  input  [8:0] io_msInfo_1_bits_set,
  input  [30:0] io_msInfo_1_bits_reqTag,
  input  io_msInfo_1_bits_blockRefill,
  input  io_msInfo_2_valid,
  input  [8:0] io_msInfo_2_bits_set,
  input  [30:0] io_msInfo_2_bits_reqTag,
  input  io_msInfo_2_bits_blockRefill,
  input  io_msInfo_3_valid,
  input  [8:0] io_msInfo_3_bits_set,
  input  [30:0] io_msInfo_3_bits_reqTag,
  input  io_msInfo_3_bits_blockRefill,
  input  io_msInfo_4_valid,
  input  [8:0] io_msInfo_4_bits_set,
  input  [30:0] io_msInfo_4_bits_reqTag,
  input  io_msInfo_4_bits_blockRefill,
  input  io_msInfo_5_valid,
  input  [8:0] io_msInfo_5_bits_set,
  input  [30:0] io_msInfo_5_bits_reqTag,
  input  io_msInfo_5_bits_blockRefill,
  input  io_msInfo_6_valid,
  input  [8:0] io_msInfo_6_bits_set,
  input  [30:0] io_msInfo_6_bits_reqTag,
  input  io_msInfo_6_bits_blockRefill,
  input  io_msInfo_7_valid,
  input  [8:0] io_msInfo_7_bits_set,
  input  [30:0] io_msInfo_7_bits_reqTag,
  input  io_msInfo_7_bits_blockRefill,
  input  io_msInfo_8_valid,
  input  [8:0] io_msInfo_8_bits_set,
  input  [30:0] io_msInfo_8_bits_reqTag,
  input  io_msInfo_8_bits_blockRefill,
  input  io_msInfo_9_valid,
  input  [8:0] io_msInfo_9_bits_set,
  input  [30:0] io_msInfo_9_bits_reqTag,
  input  io_msInfo_9_bits_blockRefill,
  input  io_msInfo_10_valid,
  input  [8:0] io_msInfo_10_bits_set,
  input  [30:0] io_msInfo_10_bits_reqTag,
  input  io_msInfo_10_bits_blockRefill,
  input  io_msInfo_11_valid,
  input  [8:0] io_msInfo_11_bits_set,
  input  [30:0] io_msInfo_11_bits_reqTag,
  input  io_msInfo_11_bits_blockRefill,
  input  io_msInfo_12_valid,
  input  [8:0] io_msInfo_12_bits_set,
  input  [30:0] io_msInfo_12_bits_reqTag,
  input  io_msInfo_12_bits_blockRefill,
  input  io_msInfo_13_valid,
  input  [8:0] io_msInfo_13_bits_set,
  input  [30:0] io_msInfo_13_bits_reqTag,
  input  io_msInfo_13_bits_blockRefill,
  input  io_msInfo_14_valid,
  input  [8:0] io_msInfo_14_bits_set,
  input  [30:0] io_msInfo_14_bits_reqTag,
  input  io_msInfo_14_bits_blockRefill,
  input  io_msInfo_15_valid,
  input  [8:0] io_msInfo_15_bits_set,
  input  [30:0] io_msInfo_15_bits_reqTag,
  input  io_msInfo_15_bits_blockRefill
);
  assign io_c_ready = '0;
  assign io_task_valid = '0;
  assign io_task_bits_channel = '0;
  assign io_task_bits_txChannel = '0;
  assign io_task_bits_set = '0;
  assign io_task_bits_tag = '0;
  assign io_task_bits_off = '0;
  assign io_task_bits_alias = '0;
  assign io_task_bits_vaddr = '0;
  assign io_task_bits_isKeyword = '0;
  assign io_task_bits_opcode = '0;
  assign io_task_bits_param = '0;
  assign io_task_bits_size = '0;
  assign io_task_bits_sourceId = '0;
  assign io_task_bits_bufIdx = '0;
  assign io_task_bits_needProbeAckData = '0;
  assign io_task_bits_denied = '0;
  assign io_task_bits_corrupt = '0;
  assign io_task_bits_mshrTask = '0;
  assign io_task_bits_mshrId = '0;
  assign io_task_bits_aliasTask = '0;
  assign io_task_bits_useProbeData = '0;
  assign io_task_bits_mshrRetry = '0;
  assign io_task_bits_readProbeDataDown = '0;
  assign io_task_bits_fromL2pft = '0;
  assign io_task_bits_needHint = '0;
  assign io_task_bits_dirty = '0;
  assign io_task_bits_way = '0;
  assign io_task_bits_meta_dirty = '0;
  assign io_task_bits_meta_state = '0;
  assign io_task_bits_meta_clients = '0;
  assign io_task_bits_meta_alias = '0;
  assign io_task_bits_meta_prefetch = '0;
  assign io_task_bits_meta_prefetchSrc = '0;
  assign io_task_bits_meta_accessed = '0;
  assign io_task_bits_meta_tagErr = '0;
  assign io_task_bits_meta_dataErr = '0;
  assign io_task_bits_metaWen = '0;
  assign io_task_bits_tagWen = '0;
  assign io_task_bits_dsWen = '0;
  assign io_task_bits_wayMask = '0;
  assign io_task_bits_replTask = '0;
  assign io_task_bits_cmoTask = '0;
  assign io_task_bits_cmoAll = '0;
  assign io_task_bits_reqSource = '0;
  assign io_task_bits_mergeA = '0;
  assign io_task_bits_aMergeTask_off = '0;
  assign io_task_bits_aMergeTask_alias = '0;
  assign io_task_bits_aMergeTask_vaddr = '0;
  assign io_task_bits_aMergeTask_isKeyword = '0;
  assign io_task_bits_aMergeTask_opcode = '0;
  assign io_task_bits_aMergeTask_param = '0;
  assign io_task_bits_aMergeTask_sourceId = '0;
  assign io_task_bits_aMergeTask_meta_dirty = '0;
  assign io_task_bits_aMergeTask_meta_state = '0;
  assign io_task_bits_aMergeTask_meta_clients = '0;
  assign io_task_bits_aMergeTask_meta_alias = '0;
  assign io_task_bits_aMergeTask_meta_prefetch = '0;
  assign io_task_bits_aMergeTask_meta_prefetchSrc = '0;
  assign io_task_bits_aMergeTask_meta_accessed = '0;
  assign io_task_bits_aMergeTask_meta_tagErr = '0;
  assign io_task_bits_aMergeTask_meta_dataErr = '0;
  assign io_task_bits_snpHitRelease = '0;
  assign io_task_bits_snpHitReleaseToInval = '0;
  assign io_task_bits_snpHitReleaseToClean = '0;
  assign io_task_bits_snpHitReleaseWithData = '0;
  assign io_task_bits_snpHitReleaseIdx = '0;
  assign io_task_bits_snpHitReleaseMeta_dirty = '0;
  assign io_task_bits_snpHitReleaseMeta_state = '0;
  assign io_task_bits_snpHitReleaseMeta_clients = '0;
  assign io_task_bits_snpHitReleaseMeta_alias = '0;
  assign io_task_bits_snpHitReleaseMeta_prefetch = '0;
  assign io_task_bits_snpHitReleaseMeta_prefetchSrc = '0;
  assign io_task_bits_snpHitReleaseMeta_accessed = '0;
  assign io_task_bits_snpHitReleaseMeta_tagErr = '0;
  assign io_task_bits_snpHitReleaseMeta_dataErr = '0;
  assign io_task_bits_tgtID = '0;
  assign io_task_bits_srcID = '0;
  assign io_task_bits_txnID = '0;
  assign io_task_bits_homeNID = '0;
  assign io_task_bits_dbID = '0;
  assign io_task_bits_fwdNID = '0;
  assign io_task_bits_fwdTxnID = '0;
  assign io_task_bits_chiOpcode = '0;
  assign io_task_bits_resp = '0;
  assign io_task_bits_fwdState = '0;
  assign io_task_bits_pCrdType = '0;
  assign io_task_bits_retToSrc = '0;
  assign io_task_bits_likelyshared = '0;
  assign io_task_bits_expCompAck = '0;
  assign io_task_bits_allowRetry = '0;
  assign io_task_bits_memAttr_allocate = '0;
  assign io_task_bits_memAttr_cacheable = '0;
  assign io_task_bits_memAttr_device = '0;
  assign io_task_bits_memAttr_ewa = '0;
  assign io_task_bits_traceTag = '0;
  assign io_task_bits_dataCheckErr = '0;
  assign io_resp_valid = '0;
  assign io_resp_set = '0;
  assign io_resp_tag = '0;
  assign io_resp_respInfo_opcode = '0;
  assign io_resp_respInfo_param = '0;
  assign io_resp_respInfo_last = '0;
  assign io_resp_respInfo_denied = '0;
  assign io_resp_respInfo_corrupt = '0;
  assign io_releaseBufWrite_valid = '0;
  assign io_releaseBufWrite_bits_data_data = '0;
  assign io_bufResp_data_0 = '0;
  assign io_bufResp_data_1 = '0;
  assign io_refillBufWrite_valid = '0;
  assign io_refillBufWrite_bits_id = '0;
  assign io_refillBufWrite_bits_data_data = '0;
endmodule

module TXDAT(
  input  clock,
  input  reset,
  output  io_in_ready,
  input  io_in_valid,
  input  [2:0] io_in_bits_task_channel,
  input  [2:0] io_in_bits_task_txChannel,
  input  [8:0] io_in_bits_task_set,
  input  [30:0] io_in_bits_task_tag,
  input  [5:0] io_in_bits_task_off,
  input  [1:0] io_in_bits_task_alias,
  input  [43:0] io_in_bits_task_vaddr,
  input  io_in_bits_task_isKeyword,
  input  [3:0] io_in_bits_task_opcode,
  input  [2:0] io_in_bits_task_param,
  input  [2:0] io_in_bits_task_size,
  input  [6:0] io_in_bits_task_sourceId,
  input  [1:0] io_in_bits_task_bufIdx,
  input  io_in_bits_task_needProbeAckData,
  input  io_in_bits_task_denied,
  input  io_in_bits_task_corrupt,
  input  io_in_bits_task_mshrTask,
  input  [7:0] io_in_bits_task_mshrId,
  input  io_in_bits_task_aliasTask,
  input  io_in_bits_task_useProbeData,
  input  io_in_bits_task_mshrRetry,
  input  io_in_bits_task_readProbeDataDown,
  input  io_in_bits_task_fromL2pft,
  input  io_in_bits_task_needHint,
  input  io_in_bits_task_dirty,
  input  [2:0] io_in_bits_task_way,
  input  io_in_bits_task_meta_dirty,
  input  [1:0] io_in_bits_task_meta_state,
  input  io_in_bits_task_meta_clients,
  input  [1:0] io_in_bits_task_meta_alias,
  input  io_in_bits_task_meta_prefetch,
  input  [2:0] io_in_bits_task_meta_prefetchSrc,
  input  io_in_bits_task_meta_accessed,
  input  io_in_bits_task_meta_tagErr,
  input  io_in_bits_task_meta_dataErr,
  input  io_in_bits_task_metaWen,
  input  io_in_bits_task_tagWen,
  input  io_in_bits_task_dsWen,
  input  [7:0] io_in_bits_task_wayMask,
  input  io_in_bits_task_replTask,
  input  io_in_bits_task_cmoTask,
  input  io_in_bits_task_cmoAll,
  input  [4:0] io_in_bits_task_reqSource,
  input  io_in_bits_task_mergeA,
  input  [5:0] io_in_bits_task_aMergeTask_off,
  input  [1:0] io_in_bits_task_aMergeTask_alias,
  input  [43:0] io_in_bits_task_aMergeTask_vaddr,
  input  io_in_bits_task_aMergeTask_isKeyword,
  input  [2:0] io_in_bits_task_aMergeTask_opcode,
  input  [2:0] io_in_bits_task_aMergeTask_param,
  input  [6:0] io_in_bits_task_aMergeTask_sourceId,
  input  io_in_bits_task_aMergeTask_meta_dirty,
  input  [1:0] io_in_bits_task_aMergeTask_meta_state,
  input  io_in_bits_task_aMergeTask_meta_clients,
  input  [1:0] io_in_bits_task_aMergeTask_meta_alias,
  input  io_in_bits_task_aMergeTask_meta_prefetch,
  input  [2:0] io_in_bits_task_aMergeTask_meta_prefetchSrc,
  input  io_in_bits_task_aMergeTask_meta_accessed,
  input  io_in_bits_task_aMergeTask_meta_tagErr,
  input  io_in_bits_task_aMergeTask_meta_dataErr,
  input  io_in_bits_task_snpHitRelease,
  input  io_in_bits_task_snpHitReleaseToInval,
  input  io_in_bits_task_snpHitReleaseToClean,
  input  io_in_bits_task_snpHitReleaseWithData,
  input  [7:0] io_in_bits_task_snpHitReleaseIdx,
  input  io_in_bits_task_snpHitReleaseMeta_dirty,
  input  [1:0] io_in_bits_task_snpHitReleaseMeta_state,
  input  io_in_bits_task_snpHitReleaseMeta_clients,
  input  [1:0] io_in_bits_task_snpHitReleaseMeta_alias,
  input  io_in_bits_task_snpHitReleaseMeta_prefetch,
  input  [2:0] io_in_bits_task_snpHitReleaseMeta_prefetchSrc,
  input  io_in_bits_task_snpHitReleaseMeta_accessed,
  input  io_in_bits_task_snpHitReleaseMeta_tagErr,
  input  io_in_bits_task_snpHitReleaseMeta_dataErr,
  input  [10:0] io_in_bits_task_tgtID,
  input  [10:0] io_in_bits_task_srcID,
  input  [11:0] io_in_bits_task_txnID,
  input  [10:0] io_in_bits_task_homeNID,
  input  [11:0] io_in_bits_task_dbID,
  input  [10:0] io_in_bits_task_fwdNID,
  input  [11:0] io_in_bits_task_fwdTxnID,
  input  [6:0] io_in_bits_task_chiOpcode,
  input  [2:0] io_in_bits_task_resp,
  input  [2:0] io_in_bits_task_fwdState,
  input  [3:0] io_in_bits_task_pCrdType,
  input  io_in_bits_task_retToSrc,
  input  io_in_bits_task_likelyshared,
  input  io_in_bits_task_expCompAck,
  input  io_in_bits_task_allowRetry,
  input  io_in_bits_task_memAttr_allocate,
  input  io_in_bits_task_memAttr_cacheable,
  input  io_in_bits_task_memAttr_device,
  input  io_in_bits_task_memAttr_ewa,
  input  io_in_bits_task_traceTag,
  input  io_in_bits_task_dataCheckErr,
  input  [511:0] io_in_bits_data_data,
  input  io_out_ready,
  output  io_out_valid,
  output  [10:0] io_out_bits_tgtID,
  output  [11:0] io_out_bits_txnID,
  output  [10:0] io_out_bits_homeNID,
  output  [3:0] io_out_bits_opcode,
  output  [1:0] io_out_bits_respErr,
  output  [2:0] io_out_bits_resp,
  output  [3:0] io_out_bits_dataSource,
  output  [11:0] io_out_bits_dbID,
  output  [1:0] io_out_bits_ccID,
  output  [1:0] io_out_bits_dataID,
  output  io_out_bits_traceTag,
  output  [31:0] io_out_bits_be,
  output  [255:0] io_out_bits_data,
  output  [31:0] io_out_bits_dataCheck,
  output  [3:0] io_out_bits_poison,
  input  io_pipeStatusVec_1_valid,
  input  [2:0] io_pipeStatusVec_1_bits_channel,
  input  [2:0] io_pipeStatusVec_1_bits_txChannel,
  input  io_pipeStatusVec_1_bits_mshrTask,
  input  io_pipeStatusVec_2_valid,
  input  [2:0] io_pipeStatusVec_2_bits_channel,
  input  [2:0] io_pipeStatusVec_2_bits_txChannel,
  input  io_pipeStatusVec_2_bits_mshrTask,
  input  io_pipeStatusVec_3_valid,
  input  [2:0] io_pipeStatusVec_3_bits_channel,
  input  [2:0] io_pipeStatusVec_3_bits_txChannel,
  input  io_pipeStatusVec_3_bits_mshrTask,
  input  io_pipeStatusVec_4_valid,
  input  [2:0] io_pipeStatusVec_4_bits_channel,
  input  [2:0] io_pipeStatusVec_4_bits_txChannel,
  input  io_pipeStatusVec_4_bits_mshrTask,
  output  io_toReqArb_blockMSHRReqEntrance,
  output  io_toReqArb_blockSinkBReqEntrance
);
  assign io_in_ready = '0;
  assign io_out_valid = '0;
  assign io_out_bits_tgtID = '0;
  assign io_out_bits_txnID = '0;
  assign io_out_bits_homeNID = '0;
  assign io_out_bits_opcode = '0;
  assign io_out_bits_respErr = '0;
  assign io_out_bits_resp = '0;
  assign io_out_bits_dataSource = '0;
  assign io_out_bits_dbID = '0;
  assign io_out_bits_ccID = '0;
  assign io_out_bits_dataID = '0;
  assign io_out_bits_traceTag = '0;
  assign io_out_bits_be = '0;
  assign io_out_bits_data = '0;
  assign io_out_bits_dataCheck = '0;
  assign io_out_bits_poison = '0;
  assign io_toReqArb_blockMSHRReqEntrance = '0;
  assign io_toReqArb_blockSinkBReqEntrance = '0;
endmodule

module TXREQ(
  input  clock,
  input  reset,
  input  io_pipeReq_valid,
  input  [10:0] io_pipeReq_bits_tgtID,
  input  [10:0] io_pipeReq_bits_srcID,
  input  [11:0] io_pipeReq_bits_txnID,
  input  [6:0] io_pipeReq_bits_opcode,
  input  [47:0] io_pipeReq_bits_addr,
  input  io_pipeReq_bits_likelyshared,
  input  io_pipeReq_bits_allowRetry,
  input  [3:0] io_pipeReq_bits_pCrdType,
  input  io_pipeReq_bits_memAttr_allocate,
  input  io_pipeReq_bits_memAttr_cacheable,
  input  io_pipeReq_bits_memAttr_device,
  input  io_pipeReq_bits_memAttr_ewa,
  input  io_pipeReq_bits_expCompAck,
  output  io_mshrReq_ready,
  input  io_mshrReq_valid,
  input  [3:0] io_mshrReq_bits_qos,
  input  [10:0] io_mshrReq_bits_tgtID,
  input  [11:0] io_mshrReq_bits_txnID,
  input  [6:0] io_mshrReq_bits_opcode,
  input  [2:0] io_mshrReq_bits_size,
  input  [47:0] io_mshrReq_bits_addr,
  input  io_mshrReq_bits_likelyshared,
  input  io_mshrReq_bits_allowRetry,
  input  [3:0] io_mshrReq_bits_pCrdType,
  input  io_mshrReq_bits_memAttr_allocate,
  input  io_mshrReq_bits_memAttr_cacheable,
  input  io_mshrReq_bits_memAttr_ewa,
  input  io_mshrReq_bits_snpAttr,
  input  io_mshrReq_bits_expCompAck,
  input  io_out_ready,
  output  io_out_valid,
  output  [3:0] io_out_bits_qos,
  output  [11:0] io_out_bits_txnID,
  output  [10:0] io_out_bits_returnNID,
  output  io_out_bits_stashNIDValid,
  output  [11:0] io_out_bits_returnTxnID,
  output  [6:0] io_out_bits_opcode,
  output  [47:0] io_out_bits_addr,
  output  io_out_bits_ns,
  output  io_out_bits_likelyshared,
  output  io_out_bits_allowRetry,
  output  [1:0] io_out_bits_order,
  output  [3:0] io_out_bits_pCrdType,
  output  io_out_bits_memAttr_allocate,
  output  io_out_bits_memAttr_cacheable,
  output  io_out_bits_memAttr_device,
  output  io_out_bits_memAttr_ewa,
  output  io_out_bits_snpAttr,
  output  [7:0] io_out_bits_lpIDWithPadding,
  output  io_out_bits_snoopMe,
  output  io_out_bits_expCompAck,
  output  [1:0] io_out_bits_tagOp,
  output  io_out_bits_traceTag,
  output  io_out_bits_mpam_perfMonGroup,
  output  [8:0] io_out_bits_mpam_partID,
  output  io_out_bits_mpam_mpamNS,
  output  [3:0] io_out_bits_rsvdc,
  input  io_pipeStatusVec_1_valid,
  input  [2:0] io_pipeStatusVec_1_bits_txChannel,
  input  io_pipeStatusVec_1_bits_mshrTask,
  input  io_pipeStatusVec_2_valid,
  input  [2:0] io_pipeStatusVec_2_bits_txChannel,
  input  io_pipeStatusVec_2_bits_mshrTask,
  input  io_pipeStatusVec_3_valid,
  input  [2:0] io_pipeStatusVec_3_bits_txChannel,
  input  io_pipeStatusVec_3_bits_mshrTask,
  input  io_pipeStatusVec_4_valid,
  input  [2:0] io_pipeStatusVec_4_bits_txChannel,
  input  io_pipeStatusVec_4_bits_mshrTask,
  output  io_toReqArb_blockMSHRReqEntrance,
  input  [1:0] io_sliceId
);
  assign io_mshrReq_ready = '0;
  assign io_out_valid = '0;
  assign io_out_bits_qos = '0;
  assign io_out_bits_txnID = '0;
  assign io_out_bits_returnNID = '0;
  assign io_out_bits_stashNIDValid = '0;
  assign io_out_bits_returnTxnID = '0;
  assign io_out_bits_opcode = '0;
  assign io_out_bits_addr = '0;
  assign io_out_bits_ns = '0;
  assign io_out_bits_likelyshared = '0;
  assign io_out_bits_allowRetry = '0;
  assign io_out_bits_order = '0;
  assign io_out_bits_pCrdType = '0;
  assign io_out_bits_memAttr_allocate = '0;
  assign io_out_bits_memAttr_cacheable = '0;
  assign io_out_bits_memAttr_device = '0;
  assign io_out_bits_memAttr_ewa = '0;
  assign io_out_bits_snpAttr = '0;
  assign io_out_bits_lpIDWithPadding = '0;
  assign io_out_bits_snoopMe = '0;
  assign io_out_bits_expCompAck = '0;
  assign io_out_bits_tagOp = '0;
  assign io_out_bits_traceTag = '0;
  assign io_out_bits_mpam_perfMonGroup = '0;
  assign io_out_bits_mpam_partID = '0;
  assign io_out_bits_mpam_mpamNS = '0;
  assign io_out_bits_rsvdc = '0;
  assign io_toReqArb_blockMSHRReqEntrance = '0;
endmodule

module TXRSP(
  input  clock,
  input  reset,
  input  io_pipeRsp_valid,
  input  [2:0] io_pipeRsp_bits_txChannel,
  input  io_pipeRsp_bits_denied,
  input  [10:0] io_pipeRsp_bits_tgtID,
  input  [10:0] io_pipeRsp_bits_srcID,
  input  [11:0] io_pipeRsp_bits_txnID,
  input  [11:0] io_pipeRsp_bits_dbID,
  input  [6:0] io_pipeRsp_bits_chiOpcode,
  input  [2:0] io_pipeRsp_bits_resp,
  input  [2:0] io_pipeRsp_bits_fwdState,
  input  [3:0] io_pipeRsp_bits_pCrdType,
  input  io_pipeRsp_bits_traceTag,
  output  io_mshrRsp_ready,
  input  io_mshrRsp_valid,
  input  [10:0] io_mshrRsp_bits_tgtID,
  input  [11:0] io_mshrRsp_bits_txnID,
  input  [4:0] io_mshrRsp_bits_opcode,
  input  io_mshrRsp_bits_traceTag,
  input  io_out_ready,
  output  io_out_valid,
  output  [3:0] io_out_bits_qos,
  output  [10:0] io_out_bits_tgtID,
  output  [11:0] io_out_bits_txnID,
  output  [4:0] io_out_bits_opcode,
  output  [1:0] io_out_bits_respErr,
  output  [2:0] io_out_bits_resp,
  output  [2:0] io_out_bits_fwdState,
  output  [2:0] io_out_bits_cBusy,
  output  [11:0] io_out_bits_dbID,
  output  [3:0] io_out_bits_pCrdType,
  output  [1:0] io_out_bits_tagOp,
  output  io_out_bits_traceTag,
  input  io_pipeStatusVec_1_valid,
  input  [2:0] io_pipeStatusVec_1_bits_channel,
  input  [2:0] io_pipeStatusVec_1_bits_txChannel,
  input  io_pipeStatusVec_1_bits_mshrTask,
  input  io_pipeStatusVec_2_valid,
  input  [2:0] io_pipeStatusVec_2_bits_channel,
  input  [2:0] io_pipeStatusVec_2_bits_txChannel,
  input  io_pipeStatusVec_2_bits_mshrTask,
  input  io_pipeStatusVec_3_valid,
  input  [2:0] io_pipeStatusVec_3_bits_channel,
  input  [2:0] io_pipeStatusVec_3_bits_txChannel,
  input  io_pipeStatusVec_3_bits_mshrTask,
  input  io_pipeStatusVec_4_valid,
  input  [2:0] io_pipeStatusVec_4_bits_channel,
  input  [2:0] io_pipeStatusVec_4_bits_txChannel,
  input  io_pipeStatusVec_4_bits_mshrTask,
  output  io_toReqArb_blockMSHRReqEntrance,
  output  io_toReqArb_blockSinkBReqEntrance
);
  assign io_mshrRsp_ready = '0;
  assign io_out_valid = '0;
  assign io_out_bits_qos = '0;
  assign io_out_bits_tgtID = '0;
  assign io_out_bits_txnID = '0;
  assign io_out_bits_opcode = '0;
  assign io_out_bits_respErr = '0;
  assign io_out_bits_resp = '0;
  assign io_out_bits_fwdState = '0;
  assign io_out_bits_cBusy = '0;
  assign io_out_bits_dbID = '0;
  assign io_out_bits_pCrdType = '0;
  assign io_out_bits_tagOp = '0;
  assign io_out_bits_traceTag = '0;
  assign io_toReqArb_blockMSHRReqEntrance = '0;
  assign io_toReqArb_blockSinkBReqEntrance = '0;
endmodule

